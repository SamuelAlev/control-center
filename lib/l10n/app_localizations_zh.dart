// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get succeeded => '成功';

  @override
  String agentRunRetryLabel(int number, String time) {
    return '重试 #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return '启动中 · $time';
  }

  @override
  String get agentActivityFollowingLive => '正在跟随实时活动';

  @override
  String get agentActivityJumpToLatest => '跳到最新';

  @override
  String get agentActivityLoadFailed => '无法加载此次运行的活动';

  @override
  String get agentActivityNotRecorded => '此次运行没有记录活动';

  @override
  String get agentActivityNotRecordedHint => '在启用活动捕获之前结束的运行没有时间线。';

  @override
  String get agentActivityRunUnavailable => '此次运行已不可用';

  @override
  String agentActivitySubagentOf(String agent) {
    return '$agent 的子智能体';
  }

  @override
  String get agentActivityUnsupported => '所连接的服务器不支持活动捕获';

  @override
  String get agentActivityUnsupportedHint => '重启应用以获取最新的服务器构建。';

  @override
  String get agentActivityWaiting => '等待活动…';

  @override
  String get created => '创建时间';

  @override
  String get dictationStart => '开始听写';

  @override
  String get dictationListening => '正在聆听…';

  @override
  String get dictationUnavailable => '听写需要服务器主机上安装语音模型。请在语音设置中配置。';

  @override
  String get dictationFailedToStart => '无法开始听写';

  @override
  String get dictationHoldToTalkTitle => '按住说话';

  @override
  String get dictationHoldToTalkDescription =>
      '按住麦克风按钮或快捷键进行听写，松开即停止。关闭此选项时，按一次开始，再按一次停止。';

  @override
  String get focusConversation => '聚焦会话';

  @override
  String get ideAgentActivity => '智能体活动';

  @override
  String get keybindingPushToTalk => '按住说话';

  @override
  String get keybindingPushToTalkDescription => '在消息输入框中按住或切换语音听写';

  @override
  String get agentPermissions => '智能体权限';

  @override
  String get agentPermissionsSettingsDescription =>
      '决定智能体哪些事可自主完成、哪些须先询问、哪些绝不可做——可按工作区、智能体或空间设置。';

  @override
  String get agentPermissionsMatrixDescription =>
      '为每类效果设置决定。规则逐级覆盖：空间覆盖智能体，智能体覆盖工作区，工作区覆盖模式预设。最具体的规则优先。';

  @override
  String get guardrailLoading => '正在加载规则…';

  @override
  String get guardrailRulesLoadFailed => '无法加载权限规则。';

  @override
  String get guardrailScopeWorkspace => '工作区';

  @override
  String get guardrailScopeAgent => '智能体';

  @override
  String get guardrailScopeSpace => '空间';

  @override
  String get guardrailSelectAgent => '选择智能体';

  @override
  String get guardrailSelectSpace => '选择空间';

  @override
  String get guardrailNoAgents => '此工作区还没有智能体。';

  @override
  String get guardrailNoSpaces => '此工作区还没有空间。';

  @override
  String get guardrailClassFileDelete => '删除文件';

  @override
  String get guardrailClassFileWriteOutsideWorktree => '写入工作树之外';

  @override
  String get guardrailClassGitCommit => '创建提交';

  @override
  String get guardrailClassGitPush => '推送到远程仓库';

  @override
  String get guardrailClassPrCreate => '打开 pull request';

  @override
  String get guardrailClassPrPublish => '发布评审或合并';

  @override
  String get guardrailClassVendorSyncWrite => '写入外部跟踪器';

  @override
  String get guardrailClassNetworkEgress => '访问网络';

  @override
  String get guardrailClassSecretAccess => '读取密钥';

  @override
  String get guardrailClassPackageInstall => '安装软件包';

  @override
  String get guardrailClassProcessSpawn => '运行进程';

  @override
  String get guardrailClassWorkspaceMutation => '更改工作区结构';

  @override
  String get guardrailClassEnclosureControl => '操控隔离舱（机台）';

  @override
  String get navRigs => '机台';

  @override
  String get rigsUnsupportedServer => '此服务器无法托管任何 rig 表面。请检查您要使用的机器是否满足主机要求。';

  @override
  String get rigSurfaceComputer => '电脑';

  @override
  String get rigSurfaceBrowser => '浏览器';

  @override
  String get rigSurfaceAndroid => 'Android';

  @override
  String get rigSurfaceIosSimulator => 'iOS 模拟器';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return '一次性 $engine，与你的机器相互隔离。再打开一个引擎即可并排比较同一页面。';
  }

  @override
  String get rigPhaseReady => '就绪';

  @override
  String get rigPhaseStarting => '启动中';

  @override
  String get rigPhaseParked => '已停驻';

  @override
  String get rigPhaseClosing => '关闭中';

  @override
  String get rigPhaseClosed => '已关闭';

  @override
  String get rigPhaseFailed => '失败';

  @override
  String get rigPhaseUnknown => '未知';

  @override
  String get rigNotAccelerated => '模拟运行';

  @override
  String get rigAudioListen => '收听机器音频';

  @override
  String get rigAudioMute => '将机器静音';

  @override
  String get rigYouHaveControl => '你已获得控制权';

  @override
  String get rigBackendAvailable => '可用';

  @override
  String get rigBackendUnavailable => '不可用';

  @override
  String get rigEgressNotEnforced => '此后端上网络未被隔离——它自行管理网络连接。';

  @override
  String get rigStartMachine => '启动机器';

  @override
  String get rigStartHint =>
      '启动一个由你和你的智能体在此会话中共享的一次性 VM。关闭时它会被销毁，其中的任何内容都不会触及你的电脑。';

  @override
  String get rigStartAndroidHint => '连接到服务器上已在运行的 Android 模拟器。网络访问未隔离。';

  @override
  String get rigStartIosHint =>
      '在 macOS 服务器上创建一个用完即弃的 iOS 模拟器。测试环境关闭时会将其删除；网络访问未隔离。';

  @override
  String get rigTechnicalDetails => '技术详情';

  @override
  String get rigStopMachine => '停止机器';

  @override
  String get rigHomeButton => '主屏幕';

  @override
  String get rigRotateClockwise => '顺时针旋转';

  @override
  String get rigRotateCounterclockwise => '逆时针旋转';

  @override
  String get rigTakeScreenshot => '截取屏幕';

  @override
  String get rigScreenshotSaved => '截图已保存';

  @override
  String rigScreenshotSaveFailed(String error) {
    return '无法保存截图：$error';
  }

  @override
  String get rigSurfaceUnavailable => '此服务器无法承载这类机器。';

  @override
  String get rigTabNeedsConversation =>
      '请先打开一个会话——机器归属于某个会话，这样你和你的智能体看到的是同一块屏幕。';

  @override
  String get ideMenuSectionTools => '工具';

  @override
  String get ideMenuSectionMachines => '机器';

  @override
  String get ideMenuSectionReopen => '重新打开';

  @override
  String get ideMenuSearchHint => '搜索';

  @override
  String get ideMenuNoMatches => '无匹配项';

  @override
  String get rigMenuComputer => '电脑';

  @override
  String get rigMenuBrowser => '浏览器';

  @override
  String get rigMenuAndroid => 'Android';

  @override
  String get rigMenuIosSimulator => 'iOS 模拟器';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return '关闭 $name？';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      '机器会在后台继续运行——随时可从侧栏重新打开。若想立即释放其内存，请改为关机。';

  @override
  String get ideCloseKeepBodyShell =>
      '命令会在后台继续运行——随时可从侧栏重新打开 shell。若想立即停止其当前工作，请改为结束。';

  @override
  String get ideCloseKeepBodyAgent =>
      '智能体会继续在后台工作——随时可从侧栏重新打开会话。若想立即结束运行，请改为停止。';

  @override
  String get ideCloseKeepRunning => '保持运行';

  @override
  String get ideCloseShutDownMachine => '关机';

  @override
  String get ideCloseEndShell => '结束 shell';

  @override
  String get ideCloseStopAgent => '停止智能体';

  @override
  String get rigsSettingsSubtitle => '此服务器可启动的系统、所需的基础镜像，以及当前运行的机器';

  @override
  String get rigsCapabilitiesTitle => '此服务器';

  @override
  String get rigInstallIosAutomation => '安装 iOS 自动化桥接器';

  @override
  String get rigInstallingIosAutomation => '正在安装 iOS 自动化桥接器…';

  @override
  String get rigIosAutomationInstalled => 'iOS 自动化桥接器已安装';

  @override
  String get rigsImagesTitle => '基础镜像';

  @override
  String get rigsImagesHint =>
      '每台机台都从这些只读镜像之一启动。每个会话写入一次性覆盖层，因此一台机台绝不会改变下一台的初始状态。';

  @override
  String get rigsRunningTitle => '当前运行';

  @override
  String get rigsNoneRunning => '没有机器在运行。';

  @override
  String get rigsCustomImagesTitle => '自定义镜像（此工作区）';

  @override
  String get rigsCustomImagesHint =>
      '将终端（VM）或浏览器（VM）指向你自己的镜像——在默认镜像上补充项目所需的工具，或使用 registry 中的任何兼容镜像。新机器会使用它；运行中的机器保持原样。镜像需要提供什么，请参阅机台指南。';

  @override
  String get rigsCustomTerminalImageLabel => '终端（VM）镜像';

  @override
  String get rigsCustomBrowserImageLabel => '浏览器（VM）镜像';

  @override
  String get rigsCustomImagePlaceholder =>
      '例如 ghcr.io/acme/dev-shell:1.2——留空使用默认镜像';

  @override
  String get rigsCustomImageInvalid =>
      '请输入形如 repo/name:tag 的 registry 引用。不允许本地路径和压缩包。';

  @override
  String get rigsCustomImageSaved => '已保存。新机器将从此镜像启动；运行中的机器保持原样。';

  @override
  String get rigsEgressTitle => '浏览器出站访问（此工作区）';

  @override
  String get rigsEgressHint =>
      '隔离浏览器可额外访问的主机——每行一条：精确主机（api.example.com）或子域通配符（*.example.com）。无论怎样设置，产品站点始终允许访问。新机器会使用此列表；运行中的机器保持启动时的配置。';

  @override
  String rigsEgressInvalid(String host) {
    return '“$host”不是有效的主机条目。';
  }

  @override
  String get rigsEgressSaved => '已保存。新的浏览器机器将允许这些主机；运行中的机器保持原样。';

  @override
  String get rigImageInstalled => '已安装';

  @override
  String get rigImageNotDownloaded => '未下载';

  @override
  String get rigImageNotPublished => '未发布';

  @override
  String get rigImageNotPublishedHint => '尚未为此发布镜像，因此没有可下载的内容。导入兼容的磁盘镜像即可启用。';

  @override
  String get rigImageDownload => '下载';

  @override
  String get rigImageDownloading => '正在下载…';

  @override
  String get rigImageImport => '导入';

  @override
  String get rigImageImportMessage =>
      '服务器文件系统上 qcow2 磁盘镜像的路径。它会被复制到镜像存储中，因此之后可以移动原文件。';

  @override
  String get rigConnectingStream => '正在连接机台';

  @override
  String get rigStreamNotAllowed => '你没有此机台的访问权限。';

  @override
  String get rigStreamNotRunning => '此机台已不再运行。';

  @override
  String get rigStreamNeedsFfmpeg => '实时画面需要此主机上安装 ffmpeg。请安装 ffmpeg 后重新打开标签页。';

  @override
  String get rigStreamEnded => '实时画面已结束。';

  @override
  String get rigStreamFailed => '无法打开实时画面。';

  @override
  String get rigStreamDisconnected => '未连接到服务器。';

  @override
  String rigDropSendingOne(String name) {
    return '正在将“$name”复制到机器…';
  }

  @override
  String rigDropSendingMany(int count) {
    return '正在将 $count 个文件复制到机器…';
  }

  @override
  String get rigTerminalDropSending => '正在复制到机器…';

  @override
  String get rigTerminalPasteImage => '粘贴的图片已保存到机器中';

  @override
  String get rigPortsTitle => '已转发的端口';

  @override
  String get rigPortsTooltip => '此机器内打开的端口';

  @override
  String get rigPortsEmpty => '还没有程序在监听。在终端里启动一个服务器——3000 端口上的开发服务器就会显示在这里。';

  @override
  String get rigPortsAdd => '添加端口';

  @override
  String get rigPortsAddHint => '要转发的客户机端口（例如 3000）';

  @override
  String get rigPortsAutoForward => '自动转发端口';

  @override
  String get rigPortsCopyUrl => '复制本地 URL';

  @override
  String rigPortsCopiedUrl(String url) {
    return '已复制 $url';
  }

  @override
  String get rigPortsStopForward => '停止转发';

  @override
  String get rigPortsExposeLan => '在局域网共享';

  @override
  String get rigPortsLanPrivate => '仅本机';

  @override
  String get rigPortsLanShared => '已联网';

  @override
  String get rigPortsSetDomain => '设置浏览器域名（.test）';

  @override
  String get rigPortsDomainHint => '浏览器（VM）使用的域名，例如 myapp.test——仅在其中可访问，主机上不可';

  @override
  String get rigPortsProcessUnknown => '未知进程';

  @override
  String get rigPortsInactive => '未监听';

  @override
  String get rigPortsTooltipHost => '此终端中打开的端口';

  @override
  String get rigPortsEmptyHost => '此终端中还没有进程在监听。启动服务器后会出现在这里。';

  @override
  String get rigPortsAddHintHost => '要映射的端口（例如 5173）';

  @override
  String get rigPortsLocalPortHint => '本地端口（可选）';

  @override
  String rigPortsDestDesktop(int port) {
    return 'localhost:$port';
  }

  @override
  String rigPortsDestBrowser(int port) {
    return 'localhost:$port（浏览器虚拟机）';
  }

  @override
  String get rigPortsDestBrowserUnreachable => '浏览器（虚拟机）未连接';

  @override
  String rigPortsDestAndroid(int port) {
    return 'localhost:$port（Android）';
  }

  @override
  String get rigPortsDestAndroidUnreachable => 'Android 未连接';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还有 $count 个基础镜像待下载',
      one: '还有 1 个基础镜像待下载',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => '允许';

  @override
  String get guardrailDecisionPrompt => '先询问';

  @override
  String get guardrailDecisionDeny => '拒绝';

  @override
  String get guardrailSourceThisScope => '此范围';

  @override
  String get guardrailSourceDefault => '内置默认值';

  @override
  String get guardrailSourcePreset => '模式预设';

  @override
  String get guardrailSourceInherited => '继承';

  @override
  String get guardrailClearToInherited => '恢复为继承值';

  @override
  String get guardrailWhatIf => '预演';

  @override
  String get guardrailWhatIfDescription => '用智能体实际遵循的同一套逻辑，看看当前规则会如何裁决某个操作。';

  @override
  String get guardrailProbeActionLabel => '操作';

  @override
  String get guardrailProbeCommandLabel => '命令（可选）';

  @override
  String get guardrailProbeCommandHint => '例如 git push origin main';

  @override
  String get guardrailProbeAgentLabel => '智能体（可选）';

  @override
  String get guardrailProbeSpaceLabel => '空间（可选）';

  @override
  String get guardrailProbeNone => '无';

  @override
  String get guardrailProbeModeLabel => '模式';

  @override
  String get guardrailProbeResult => '结果';

  @override
  String get guardrailProbeSource => '来源：';

  @override
  String get guardrailAdapterMatrix => '规则的执行位置';

  @override
  String get guardrailAdapterMatrixDescription =>
      '如实参考：各类效果在各智能体运行器上实际被拦截的位置。这里记录的是现状而非保证——运行器在带外执行的效果无法被拦截。';

  @override
  String get guardrailEffectColumn => '效果';

  @override
  String get guardrailAdapterHarness => '内置运行器';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => '沙盒底线';

  @override
  String get guardrailEnforcementPolicyGate => '策略门禁';

  @override
  String get guardrailEnforcementSandbox => '仅沙盒';

  @override
  String get guardrailEnforcementNone => '无法强制执行';

  @override
  String get guardrailEnforcementPolicyGateHelp => '权限决定会在效果执行前检查，并可将其阻止。';

  @override
  String get guardrailEnforcementSandboxHelp => '仅由沙盒约束；不会查询权限规则。';

  @override
  String get guardrailEnforcementNoneHelp => '该决定仅供参考——无法在此拦截。';

  @override
  String get obsStatCost => '成本';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount 已委托';
  }

  @override
  String get obsStatDuration => '时长';

  @override
  String get obsStatTokens => 'Token';

  @override
  String get obsStatTools => '工具';

  @override
  String get openAgentActivity => '打开活动';

  @override
  String get orgChart => '组织架构图';

  @override
  String get orgChartEmpty => '还没有智能体';

  @override
  String get navCalendar => '日历';

  @override
  String get serverConnection => '服务器连接';

  @override
  String get serverModeLocal => '在此应用中运行';

  @override
  String get serverModeLocalDescription =>
      'Control Center 在这台机器上运行自己的服务器，你的数据保存在本地。';

  @override
  String get serverModeRemote => '连接到远程实例';

  @override
  String get serverModeRemoteDescription =>
      '连接到在别处运行的 Control Center 服务器。你的数据保存在那台服务器上。';

  @override
  String get serverRemoteUrl => '服务器 URL';

  @override
  String get serverRemoteDeviceId => '设备 ID';

  @override
  String get serverRemotePairingKey => '配对密钥';

  @override
  String get serverRemotePairingKeyHint => '粘贴来自远程服务器的配对密钥';

  @override
  String get serverSetupInviteCode => '邀请码';

  @override
  String get serverSetupInviteCodeHint => '粘贴一次性邀请码（留空则使用配对密钥）';

  @override
  String get serverDiscoveryTooltip => '查找你网络中的服务器';

  @override
  String get serverDiscoveryTitle => '你网络中的服务器';

  @override
  String get serverDiscoverySearching => '正在搜索服务器…';

  @override
  String get serverDiscoveryEmpty => '未找到服务器。请确认服务器正在运行且此设备可以访问它，然后重新搜索。';

  @override
  String get serverDiscoveryRefresh => '重新搜索';

  @override
  String get serverListActive => '使用中';

  @override
  String get serverListSwitch => '切换';

  @override
  String get serverListAddTitle => '添加服务器';

  @override
  String get serverListRemoveActiveHint => '请先切换到其他服务器，再移除此服务器。';

  @override
  String get serverSwitchFailedTitle => '无法切换服务器';

  @override
  String get serverListInsecureBadge => '不安全';

  @override
  String get connectionPathLocal => '本地';

  @override
  String get connectionPathLan => '局域网';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => '正在关闭';

  @override
  String get shutdownSubtitle => '正在关闭本地服务器';

  @override
  String get shutdownServiceApprovals => '审批';

  @override
  String get shutdownServiceBackgroundJobs => '后台任务';

  @override
  String get shutdownServiceScheduler => '任务调度器';

  @override
  String get shutdownServiceCalendar => '日历同步';

  @override
  String get shutdownServiceWeather => '天气';

  @override
  String get shutdownServiceSoundscape => '声景';

  @override
  String get shutdownServiceMeetings => '会议';

  @override
  String get shutdownServiceVoiceModels => '语音模型';

  @override
  String get shutdownServiceNetworking => '网络';

  @override
  String get shutdownServicePresence => '在线状态';

  @override
  String get shutdownServiceDataSync => '数据同步';

  @override
  String get shutdownServiceDeviceRelay => '设备中继';

  @override
  String get shutdownServiceMcpConnections => 'MCP 连接';

  @override
  String get shutdownServiceCodeEditors => '代码编辑器';

  @override
  String get serverSharingTitle => '共享此服务器';

  @override
  String get serverSharingDescription =>
      '让其他设备也能访问此服务器。除非开启下方的隧道，否则不会公开暴露任何内容。配对邀请会自动嵌入服务器当前地址——请在工作区设置中创建。';

  @override
  String get serverSharingUnavailable => '此服务器上不提供共享控制。';

  @override
  String get serverSharingMdnsLabel => '局域网发现';

  @override
  String get serverSharingMdnsOn => '正在本地网络内通告此服务器（mDNS）';

  @override
  String get serverSharingMdnsOff => '未在本地网络内通告（mDNS）';

  @override
  String get serverSharingTunnelLabel => '隧道';

  @override
  String get serverSharingTunnelHelper => '开启隧道后即可从互联网访问此服务器。公开暴露需主动选择，默认关闭。';

  @override
  String get serverSharingProviderOff => '关闭';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => '公网 URL';

  @override
  String get serverSharingTunnelStarting => '正在启动隧道…';

  @override
  String serverSharingTunnelError(String error) {
    return '隧道错误：$error';
  }

  @override
  String get serverSharingTunnelUpNoUrl => '隧道已建立。请通过你配置的 DNS 主机名访问。';

  @override
  String get serverSharingRelayLabel => '中继';

  @override
  String serverSharingRelayUsage(String amount) {
    return '本月已中继：$amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return '活动中继会话数：$count';
  }

  @override
  String get serverSharingUpdateFailedTitle => '无法更新共享设置';

  @override
  String get pairNewClient => '配对新客户端';

  @override
  String get pairClientNameHint => '为此客户端起个名字（例如：工作笔记本）';

  @override
  String get pairClientTypeWeb => '网页浏览器';

  @override
  String get pairClientTypeDesktop => '桌面应用';

  @override
  String get pairClientTypePhone => '手机';

  @override
  String get pairAction => '配对';

  @override
  String get revoke => '吊销';

  @override
  String get pairCredentialsIntro => '使用这些信息连接新客户端，或在新客户端中打开链接。';

  @override
  String get pairLinkLabel => '链接';

  @override
  String get pairScanQr => '用手机相机扫描此二维码即可配对。';

  @override
  String get pairServerUnreachableTitle => '无法访问';

  @override
  String get pairServerUnreachable =>
      '其他设备无法直接访问此服务器，因此新客户端无法连接。请设置服务器的公网 URL 以配对更多客户端。';

  @override
  String get serverSetupTitle => 'Control Center 应如何运行？';

  @override
  String get serverSetupSubtitle =>
      'Control Center 需要一个掌管你数据的服务器。可以在此应用内运行一个，或连接到在别处运行的实例。';

  @override
  String get serverSetupRunLocal => '在此应用中运行';

  @override
  String get serverSetupConnect => '连接';

  @override
  String get serverSetupInvalidUrl => '请输入有效的 ws:// 或 wss:// 服务器 URL。';

  @override
  String get serverSetupCouldNotConnect => '无法连接';

  @override
  String get serverSetupErrorUnreachable =>
      '无法访问该服务器。请确认它正在运行，且此设备可以访问（相同网络或中继）。';

  @override
  String get serverSetupErrorIdentityMismatch =>
      '服务器身份与此设备保存的不一致。如果服务器曾重装或重置，请移除已保存的服务器并重新配对。';

  @override
  String get serverSetupErrorAuthRejected =>
      '服务器拒绝了此设备。请确认配对密钥和设备 ID 与服务器颁发的一致。';

  @override
  String get serverSetupErrorInviteRejected => '邀请码无效或已过期。请重新获取。';

  @override
  String get serverSetupErrorGeneric => '连接时出现问题。展开下方的技术详情了解更多信息。';

  @override
  String get serverSetupErrorDetails => '技术详情';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还有 $count 个',
      one: '还有 1 个',
    );
    return '$_temp0';
  }

  @override
  String get calendarAllDayGutter => '全天';

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个活动',
      one: '1 个活动',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => '折叠全天活动';

  @override
  String get calendarExpandAllDay => '展开全天活动';

  @override
  String get calendarViewMonth => '月';

  @override
  String get calendarViewWeek => '周';

  @override
  String get calendarViewAgenda => '议程';

  @override
  String get calendarConnectGoogle => '连接 Google 日历';

  @override
  String get calendarConnectDescription => '同步你的 Google 日历，在此查看活动并在会议开始前收到提醒。';

  @override
  String get calendarDisconnect => '断开连接';

  @override
  String get calendarReconnect => '重新连接';

  @override
  String get calendarEmptyNoEvents => '此时间范围内没有活动';

  @override
  String get calendarStartRecording => '开始录制';

  @override
  String get calendarStartRecordingAndLink => '开始录制并关联';

  @override
  String get calendarJoinMeet => '加入会议';

  @override
  String get calendarFromCalendar => '来自日历';

  @override
  String get calendarLinkedMeeting => '已关联的会议';

  @override
  String get calendarToday => '今天';

  @override
  String get calendarAllDay => '全天';

  @override
  String calendarWeekNumber(int number) {
    return '第 $number 周';
  }

  @override
  String get calendarPreviousPeriod => '上一时段';

  @override
  String get calendarNextPeriod => '下一时段';

  @override
  String calendarLastSynced(String time) {
    return '已同步 $time';
  }

  @override
  String get calendarNeverSynced => '尚未同步';

  @override
  String get calendarSyncing => '正在同步…';

  @override
  String get calendarViewDay => '日';

  @override
  String get calendarShow => '显示';

  @override
  String get calendarHide => '隐藏';

  @override
  String get calendarRsvpGoing => '是否参加？';

  @override
  String get calendarRsvpYes => '参加';

  @override
  String get calendarRsvpNo => '不参加';

  @override
  String get calendarRsvpMaybe => '待定';

  @override
  String get calendarRsvpFailed => '无法更新你的回复';

  @override
  String get calendarAddAccount => '添加日历账户';

  @override
  String get calendarSettingsTitle => 'Google 日历';

  @override
  String get calendarSettingsDescription =>
      '连接 Google 账户，将活动同步到此工作区。这些日历在这里属于你。';

  @override
  String get calendarConnecting => '正在连接…';

  @override
  String get calendarSyncNow => '立即同步';

  @override
  String get calendarNoWorkspace => '选择一个工作区以查看其日历';

  @override
  String get calendarConnectError => '无法连接 Google 日历';

  @override
  String get calendarClientIdLabel => '客户端 ID';

  @override
  String get calendarClientSecretLabel => '客户端密钥';

  @override
  String get calendarConnectCredsHint =>
      '输入你项目的 Google OAuth 设备码客户端 ID 和密钥。连接与同步由服务器执行——你的浏览器绝不会持有令牌。';

  @override
  String get calendarConnectApproveInstruction => '在任意设备上打开验证页面，登录并输入此验证码：';

  @override
  String get calendarConnectOpenPage => '打开验证页面';

  @override
  String get calendarConnectWaiting => '等待批准…';

  @override
  String get calendarConnectDenied => '授权被拒绝。请重试。';

  @override
  String get calendarConnectExpired => '验证码已过期。请重试。';

  @override
  String get notificationMeetingStartsSoon => '会议即将开始';

  @override
  String get notifyMeetingStartsSoon => '日历会议即将开始时';

  @override
  String get notificationCalendarAuthExpiredTitle => '日历已断开连接';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return '重新连接 $email 以恢复同步';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail => '重新连接你的日历以恢复同步';

  @override
  String get notifyCalendarAuthExpired => '日历账户需要重新连接时';

  @override
  String get notificationRigStatusChanged => '隔离舱动态';

  @override
  String get notifyRigStatusChanged => '隔离舱被接管、回收或故障时';

  @override
  String get notificationRigTakenOver => '隔离舱被接管';

  @override
  String get notificationRigTakenOverBody => '有人正在操控机器；智能体只能旁观，无法操作。';

  @override
  String get notificationRigReleased => '隔离舱控制权已释放';

  @override
  String get notificationRigReleasedBody => '智能体已重新掌控机器。';

  @override
  String get notificationRigReclaimed => '隔离舱已回收';

  @override
  String get notificationRigReclaimedBodyIdle => '由于闲置，机器已关闭以释放内存。';

  @override
  String get notificationRigReclaimedBodyTtl => '已达时限，机器已关闭。';

  @override
  String get notificationRigFailed => '隔离舱故障';

  @override
  String get notificationRigFailedBody => '其下的 hypervisor 已终止。重新打开机器以继续。';

  @override
  String get calendarAlertLeadTime => '提醒提前量';

  @override
  String get calendarAlertLeadTimeSubtitle => '会议开始前多久提醒你';

  @override
  String calendarConnectedAs(String email) {
    return '已连接为 $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count 位参会者';
  }

  @override
  String get calendarEventLabel => '活动';

  @override
  String get calendarRecurring => '重复活动';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => '组织者';

  @override
  String get calendarYou => '你';

  @override
  String get calendarShowFewer => '显示更少';

  @override
  String get calendarRsvpAwaiting => '待回复';

  @override
  String calendarParticipantsCount(int count) {
    return '$count 位参与者';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return '查看全部 $count 位参与者';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count 人参加';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count 人不参加';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count 人待定';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count 人待回复';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count 分钟';
  }

  @override
  String get openInEditorPrompt => '用哪个编辑器打开？';

  @override
  String get ideNotInstalled => '未安装';

  @override
  String openInIde(String editor) {
    return '在 $editor 中打开';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return '无法打开 $editor：$error';
  }

  @override
  String get profileSearchHint => '搜索 pull request…';

  @override
  String get stopAgentRun => '停止运行';

  @override
  String get stopAgentRunConfirm => '停止此次运行？进行中的工作将会丢失。';

  @override
  String get inProgress => '进行中';

  @override
  String get drafts => '草稿';

  @override
  String get sortOldest => '最旧';

  @override
  String get sortLargest => '最大';

  @override
  String get prFilterTooltip => '筛选';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个筛选条件生效',
      one: '1 个筛选条件生效',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => '添加筛选条件…';

  @override
  String get prFilterFieldHint => '筛选…';

  @override
  String get prFilterCategoryStatus => '状态';

  @override
  String get prFilterCategoryAuthor => '作者';

  @override
  String get prFilterCategoryReviewer => '评审者';

  @override
  String get prFilterCategoryContent => '内容';

  @override
  String get prFilterCategoryRepoOwner => '仓库所有者';

  @override
  String get prFilterCategoryRepoName => '仓库名称';

  @override
  String get prFilterCategoryOpenedDate => '创建日期';

  @override
  String get prFilterCategoryUpdatedDate => '更新日期';

  @override
  String get prFilterQuickToReview => '易于评审';

  @override
  String get prFilterClearAll => '清除筛选';

  @override
  String prFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个 pull request',
      one: '1 个 pull request',
    );
    return '$_temp0';
  }

  @override
  String prFilterHiddenOptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个选项与任何 pull request 都不匹配',
      one: '1 个选项与任何 pull request 都不匹配',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => '标题或正文包含…';

  @override
  String get prFilterNoOptions => '无匹配选项';

  @override
  String get prFilterChipIs => '是';

  @override
  String get prFilterChipIsAnyOf => '属于以下任一';

  @override
  String get prFilterChipContains => '包含';

  @override
  String get prFilterChipSince => '自';

  @override
  String get prFilterAddFilterButton => '添加筛选条件';

  @override
  String prFilterClearCategory(String category) {
    return '清除 $category 筛选';
  }

  @override
  String get prFilterCurrentUser => '当前用户';

  @override
  String get prStatusDraft => '草稿';

  @override
  String get prStatusOpen => '打开';

  @override
  String get prStatusInReview => '评审中';

  @override
  String get prStatusChangesRequested => '已请求变更';

  @override
  String get prStatusApproved => '已批准';

  @override
  String get prStatusMerged => '已合并';

  @override
  String get prStatusClosed => '已关闭';

  @override
  String get prDateWindowDay => '1 天前';

  @override
  String get prDateWindowThreeDays => '3 天前';

  @override
  String get prDateWindowWeek => '1 周前';

  @override
  String get prDateWindowMonth => '1 个月前';

  @override
  String get prDateWindowThreeMonths => '3 个月前';

  @override
  String get prDateWindowSixMonths => '6 个月前';

  @override
  String get prDateWindowYear => '1 年前';

  @override
  String get prDisplayOptions => '显示选项';

  @override
  String get prDisplayGrouping => '分组';

  @override
  String get prDisplayOrdering => '排序';

  @override
  String get prDisplayShowDrafts => '显示草稿';

  @override
  String get prDisplayMergedWindow => '合并时间范围';

  @override
  String get prDisplayMergedWindowDay => '过去一天';

  @override
  String get prDisplayMergedWindowWeek => '过去一周';

  @override
  String get prDisplayMergedWindowMonth => '过去一个月';

  @override
  String get prDisplayProperties => '显示属性';

  @override
  String get prGroupingRepository => '仓库';

  @override
  String get prGroupingAuthor => '作者';

  @override
  String get prGroupingStatus => '状态';

  @override
  String get prGroupingNone => '不分组';

  @override
  String get prPropertyRepository => '仓库';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => '分支';

  @override
  String get prPropertyUpdated => '更新时间';

  @override
  String get prPropertyAuthor => '作者';

  @override
  String get prPropertyChecks => '检查';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => '评论';

  @override
  String get keybindingOpenFilterMenu => '打开筛选菜单';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      '打开 pull request 筛选菜单';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已选 $count 项',
      one: '已选 1 项',
    );
    return '$_temp0';
  }

  @override
  String get summary => '摘要';

  @override
  String get kbMove => '移动';

  @override
  String get kbTabs => '标签页';

  @override
  String get kbSearch => '搜索';

  @override
  String get kbViewed => '已查看';

  @override
  String get kbCollapse => '折叠';

  @override
  String get appearance => '外观';

  @override
  String get appearanceSettingsDescription => '主题、语言与排版。';

  @override
  String get notificationsSettingsDescription => '选择哪些智能体与工作区事件会通知你。';

  @override
  String get advanced => '高级';

  @override
  String get accounts => '账户';

  @override
  String get mcpServers => 'MCP 服务器';

  @override
  String get mcpServersSettingsDescription => '内置 MCP 服务器与外部 MCP 服务器。';

  @override
  String get remoteControlAndDevices => '远程控制与设备';

  @override
  String get remoteControlAndDevicesSettingsDescription => '配对手机并配置远程控制服务器。';

  @override
  String get voiceAndMeetingsSettingsDescription => '此服务器托管的语音与说话人分离模型。';

  @override
  String get needsSetupLabel => '需要设置';

  @override
  String get collapseSidebar => '收起侧栏';

  @override
  String get expandSidebar => '展开侧栏';

  @override
  String get filterSpacesHint => '筛选空间';

  @override
  String noSpacesMatch(String query) {
    return '没有匹配“$query”的空间';
  }

  @override
  String get privacy => '隐私';

  @override
  String get sendDiffContentTitle => '向 AI 适配器发送 diff 内容';

  @override
  String get diffSharingOnSubtitle => '原始 diff 行会包含在智能体提示词中，以便更深入地评审。';

  @override
  String get diffSharingOffSubtitle =>
      '智能体只使用结构化元数据（文件路径、行号、PR 描述）；任何原始代码都不会离开应用。';

  @override
  String get errorReportingTitle => '分享崩溃报告';

  @override
  String get errorReportingOnSubtitle => '发送崩溃、错误与性能诊断数据以帮助修复问题（仅发布版本）。';

  @override
  String get errorReportingOffSubtitle => '诊断已关闭。不会发送任何崩溃或错误报告。';

  @override
  String get onboardingDiagnosticsTitle => '帮助改进 Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      '发送崩溃、错误与性能诊断数据，帮助我们更快修复问题（仅发布版本）。你可以随时在“设置 → 隐私”中更改。';

  @override
  String get blocked => '已阻塞';

  @override
  String get idle => '空闲';

  @override
  String get noRunsYet => '暂无运行';

  @override
  String get copyPath => '复制路径';

  @override
  String get copyRelativePath => '复制相对路径';

  @override
  String get nameRequired => '必须填写名称';

  @override
  String get import => '导入';

  @override
  String get noMatchingAgents => '没有符合筛选条件的智能体';

  @override
  String watchVideoOn(String provider) {
    return '在 $provider 上观看视频';
  }

  @override
  String get branchTemplate => '分支名模板';

  @override
  String get branchTemplateDescription => '在独立工作树中启动工单时，所创建分支的命名模式。';

  @override
  String branchTemplatePreview(String example) {
    return '示例：$example';
  }

  @override
  String get deletePipelineRun => '删除流水线运行';

  @override
  String deletePipelineRunConfirm(String template) {
    return '删除“$template”的此次运行？此操作无法撤销。';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return '删除流水线运行时出错：$error';
  }

  @override
  String get deleteTicket => '删除工单';

  @override
  String deleteTicketConfirm(String title) {
    return '删除“$title”？此操作无法撤销。';
  }

  @override
  String errorDeletingTicket(String error) {
    return '删除工单时出错：$error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return '删除“$name”？磁盘上的关联仓库不受影响。';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return '删除工作区时出错：$error';
  }

  @override
  String get indexCode => '索引代码';

  @override
  String get indexNoGrammars => '未安装代码语法';

  @override
  String get indexFailed => '索引失败';

  @override
  String indexedSymbolsCount(int count) {
    return '已索引 $count 个符号';
  }

  @override
  String get nodeConfigAdvanced => '高级';

  @override
  String get nodeConfigReducer => '合并器';

  @override
  String get nodeConfigReducerHelp => '当此输出键已有值时如何合并';

  @override
  String get nodeConfigTimeoutMs => '超时（毫秒）';

  @override
  String get nodeConfigRetryAttempts => '重试次数';

  @override
  String get nodeConfigContinueOnFail => '此步骤失败时继续';

  @override
  String get nodeConfigTeamId => '团队 ID';

  @override
  String get nodeConfigDispatchMode => '调度模式';

  @override
  String get nodeConfigOutputSchema => '输出 schema（JSON）';

  @override
  String get nodeConfigOutputSchemaHelp => '步骤输出必须满足的 JSON Schema';

  @override
  String get diffLineDisplay => 'Diff 中的长行';

  @override
  String get diffLineDisplayDescription => '长行自动换行或水平滚动';

  @override
  String get diffLineWrap => '自动换行';

  @override
  String get diffLineScroll => '水平滚动';

  @override
  String get actions => '操作';

  @override
  String get activate => '启用';

  @override
  String get activity => '活动';

  @override
  String get activityLabel => '活动';

  @override
  String get activitySearchHint => '搜索活动';

  @override
  String get activityNoMatches => '没有符合筛选条件的活动';

  @override
  String activityPageRange(int start, int end, int total) {
    return '第 $start–$end 条，共 $total 条';
  }

  @override
  String get activityPreviousPage => '上一页';

  @override
  String get activityNextPage => '下一页';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => '清除筛选';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return '国家/地区 $country';
  }

  @override
  String get activitySavedWorkspaceLogo => '保存了工作区徽标';

  @override
  String activityVerbCreated(String target) {
    return '创建了$target';
  }

  @override
  String activityVerbUpdated(String target) {
    return '更新了$target';
  }

  @override
  String activityVerbDeleted(String target) {
    return '删除了$target';
  }

  @override
  String activityVerbAdded(String target) {
    return '添加了$target';
  }

  @override
  String activityVerbRemoved(String target) {
    return '移除了$target';
  }

  @override
  String activityVerbInvited(String target) {
    return '邀请了$target';
  }

  @override
  String activityVerbChanged(String target) {
    return '更改了$target';
  }

  @override
  String activityVerbStarted(String target) {
    return '启动了$target';
  }

  @override
  String activityVerbStopped(String target) {
    return '停止了$target';
  }

  @override
  String activityVerbWrote(String target) {
    return '写入了$target';
  }

  @override
  String get activityTargetAgent => '智能体';

  @override
  String get activityTargetTicket => '工单';

  @override
  String get activityTargetWorkspace => '工作区';

  @override
  String get activityTargetRepository => '仓库';

  @override
  String get activityTargetMember => '成员';

  @override
  String get activityTargetInvite => '邀请';

  @override
  String get activityTargetSpace => '空间';

  @override
  String get activityTargetMessage => '消息';

  @override
  String get activityTargetCache => '缓存';

  @override
  String get activityTargetFile => '文件';

  @override
  String get activityTargetPipeline => '流水线';

  @override
  String get activityTargetTemplate => '模板';

  @override
  String get activityTargetProvider => '提供商';

  @override
  String get activityTargetModel => '模型';

  @override
  String get activityTargetSkill => '技能';

  @override
  String get activityTargetTodo => '待办';

  @override
  String get activityTargetMeeting => '会议';

  @override
  String get activityTargetProject => '项目';

  @override
  String get activityTargetTeam => '团队';

  @override
  String get activityTargetDevice => '设备';

  @override
  String get activityTargetPreference => '偏好设置';

  @override
  String get activityTargetBudget => '预算';

  @override
  String activityVerbApproved(String target) {
    return '批准了$target';
  }

  @override
  String activityVerbArchived(String target) {
    return '归档了$target';
  }

  @override
  String activityVerbAssigned(String target) {
    return '分配了$target';
  }

  @override
  String activityVerbBackedUp(String target) {
    return '备份了$target';
  }

  @override
  String activityVerbCancelled(String target) {
    return '取消了$target';
  }

  @override
  String activityVerbCleared(String target) {
    return '清除了$target';
  }

  @override
  String activityVerbClosed(String target) {
    return '关闭了$target';
  }

  @override
  String activityVerbCommitted(String target) {
    return '提交了$target';
  }

  @override
  String activityVerbCompacted(String target) {
    return '压缩了$target';
  }

  @override
  String activityVerbCompleted(String target) {
    return '完成了$target';
  }

  @override
  String activityVerbConnected(String target) {
    return '连接了$target';
  }

  @override
  String activityVerbContinued(String target) {
    return '继续了$target';
  }

  @override
  String activityVerbDisconnected(String target) {
    return '断开了$target';
  }

  @override
  String activityVerbDispatched(String target) {
    return '调度了$target';
  }

  @override
  String activityVerbDrained(String target) {
    return '清空了$target';
  }

  @override
  String activityVerbEnrolled(String target) {
    return '登记了$target';
  }

  @override
  String activityVerbEstimated(String target) {
    return '估算了$target';
  }

  @override
  String activityVerbImported(String target) {
    return '导入了$target';
  }

  @override
  String activityVerbInstalled(String target) {
    return '安装了$target';
  }

  @override
  String activityVerbKilled(String target) {
    return '终止了$target';
  }

  @override
  String activityVerbMarked(String target) {
    return '标记了$target';
  }

  @override
  String activityVerbMerged(String target) {
    return '合并了$target';
  }

  @override
  String activityVerbOpened(String target) {
    return '打开了$target';
  }

  @override
  String activityVerbPaused(String target) {
    return '暂停了$target';
  }

  @override
  String activityVerbPolled(String target) {
    return '轮询了$target';
  }

  @override
  String activityVerbPrepared(String target) {
    return '准备了$target';
  }

  @override
  String activityVerbProcessed(String target) {
    return '处理了$target';
  }

  @override
  String activityVerbPublished(String target) {
    return '发布了$target';
  }

  @override
  String activityVerbRefined(String target) {
    return '优化了$target';
  }

  @override
  String activityVerbRefreshed(String target) {
    return '刷新了$target';
  }

  @override
  String activityVerbRegistered(String target) {
    return '注册了$target';
  }

  @override
  String activityVerbRenamed(String target) {
    return '重命名了$target';
  }

  @override
  String activityVerbReordered(String target) {
    return '重新排序了$target';
  }

  @override
  String activityVerbResponded(String target) {
    return '回复了$target';
  }

  @override
  String activityVerbRestored(String target) {
    return '还原了$target';
  }

  @override
  String activityVerbResumed(String target) {
    return '恢复了$target';
  }

  @override
  String activityVerbRetried(String target) {
    return '重试了$target';
  }

  @override
  String activityVerbReverted(String target) {
    return '回退了$target';
  }

  @override
  String activityVerbReviewed(String target) {
    return '评审了$target';
  }

  @override
  String activityVerbRan(String target) {
    return '运行了$target';
  }

  @override
  String activityVerbSelected(String target) {
    return '选择了$target';
  }

  @override
  String activityVerbSent(String target) {
    return '发送了$target';
  }

  @override
  String activityVerbStaged(String target) {
    return '暂存了$target';
  }

  @override
  String activityVerbSteered(String target) {
    return '引导了$target';
  }

  @override
  String activityVerbSubmitted(String target) {
    return '提交了$target';
  }

  @override
  String activityVerbSynced(String target) {
    return '同步了$target';
  }

  @override
  String activityVerbToggled(String target) {
    return '切换了$target';
  }

  @override
  String activityVerbUninstalled(String target) {
    return '卸载了$target';
  }

  @override
  String activityVerbUnstaged(String target) {
    return '取消暂存了$target';
  }

  @override
  String get activityTargetActionPolicy => '操作策略';

  @override
  String get activityTargetGoalRun => '目标运行';

  @override
  String get activityTargetRunLog => '运行日志';

  @override
  String get activityTargetWorkingMemory => '工作记忆';

  @override
  String get activityTargetRoutingPolicy => '路由策略';

  @override
  String get activityTargetAutonomy => '自主权限';

  @override
  String get activityTargetCalendar => '日历';

  @override
  String get activityTargetChecker => '检查器';

  @override
  String get activityTargetEditor => '编辑器';

  @override
  String get activityTargetConfirmation => '确认';

  @override
  String get activityTargetTunnel => '隧道';

  @override
  String get activityTargetConversation => '会话';

  @override
  String get activityTargetCredentials => '凭据';

  @override
  String get activityTargetDictation => '听写';

  @override
  String get activityTargetAgentRun => '智能体运行';

  @override
  String get activityTargetEvalSuite => '评测套件';

  @override
  String get activityTargetWorker => '工作进程';

  @override
  String get activityTargetWorktree => '工作树';

  @override
  String get activityTargetMcpServer => 'MCP 服务器';

  @override
  String get activityTargetMemoryAccessGrant => '记忆访问授权';

  @override
  String get activityTargetMemoryDomain => '记忆域';

  @override
  String get activityTargetMemoryFact => '记忆事实';

  @override
  String get activityTargetMemoryPolicy => '记忆策略';

  @override
  String get activityTargetFeed => '订阅源';

  @override
  String get activityTargetNote => '笔记';

  @override
  String get activityTargetOrchestration => '编排';

  @override
  String get activityTargetPipelineRun => '流水线运行';

  @override
  String get activityTargetPipelineTrigger => '流水线触发器';

  @override
  String get activityTargetPlan => '计划';

  @override
  String get activityTargetPlaybook => '剧本';

  @override
  String get activityTargetPullRequest => 'pull request';

  @override
  String get activityTargetReview => '评审';

  @override
  String get activityTargetProcess => '进程';

  @override
  String get activityTargetProviderPolicy => '提供商策略';

  @override
  String get activityTargetReaction => '表情回应';

  @override
  String get activityTargetReviewSpace => '评审空间';

  @override
  String get activityTargetReviewStudio => '评审工作室';

  @override
  String get activityTargetServerData => '服务器数据';

  @override
  String get activityTargetSoundscape => '声景';

  @override
  String get activityTargetSession => '会话';

  @override
  String get activityTargetTerminal => '终端';

  @override
  String get activityTargetTicketLink => '工单链接';

  @override
  String get activityTargetTicketSync => '工单同步';

  @override
  String get activityTargetProfile => '个人资料';

  @override
  String get activityTargetVoiceProfile => '语音配置';

  @override
  String get activityTargetWeather => '天气预报';

  @override
  String get activityTargetWorkProduct => '工作成果';

  @override
  String get activityChangedMemberRole => '更改了成员角色';

  @override
  String get activityChangedMemberRepoAccess => '更改了成员的仓库访问权限';

  @override
  String get activityUpdatedGitHubToken => '更新了 GitHub 令牌';

  @override
  String get activityRefreshedWeather => '刷新了天气预报';

  @override
  String get activitySetWeatherLocation => '设置了天气位置';

  @override
  String get activityClearedWeatherLocation => '清除了天气位置';

  @override
  String get activityMarkedAllArticlesRead => '将所有文章标为已读';

  @override
  String get activityMarkedArticleRead => '将一篇文章标为已读';

  @override
  String get activityUpdatedSavedArticle => '更新了一篇收藏的文章';

  @override
  String get activityTookOverSession => '接管了会话';

  @override
  String get activityHandedBackSession => '交还了会话';

  @override
  String get activityCommittedAndPushed => '已提交并推送';

  @override
  String get activityBackedUpServer => '备份了服务器数据';

  @override
  String get activityMarkedSpaceRead => '将空间标为已读';

  @override
  String get activityRespondedToInvitation => '回复了活动邀请';

  @override
  String get activityStartedCalendarConnect => '启动了日历连接';

  @override
  String get activityDisconnectedCalendar => '断开了日历连接';

  @override
  String get activityMarkedFileViewed => '将文件标为已查看';

  @override
  String get activityRespondedToApproval => '回复了审批请求';

  @override
  String get activityChangedTunnel => '更改了隧道设置';

  @override
  String get activitySentMessageToAgent => '向智能体发送了消息';

  @override
  String get activityOpenedReviewSpace => '打开了评审空间';

  @override
  String get activityOpenedStandingConversation => '打开了常驻会话';

  @override
  String get activityStartedRecording => '开始了录制';

  @override
  String get activityStoppedRecording => '停止了录制';

  @override
  String get activityToggledMcpServer => '切换了 MCP 服务器';

  @override
  String get activityUpdatedMcpToken => '更新了 MCP 令牌';

  @override
  String get activitySavedApiKey => '保存了 API 密钥';

  @override
  String get activityRemovedProviderCredential => '移除了提供商凭据';

  @override
  String get activityUpdatedLinkedRepos => '更新了关联的仓库';

  @override
  String get activityUnlinkedRepo => '取消关联了一个仓库';

  @override
  String get activityUpdatedActionItem => '更新了一项行动项';

  @override
  String adRulesCount(int count) {
    return '$count 条广告规则';
  }

  @override
  String get adapter => '适配器';

  @override
  String get adapterLabel => '适配器';

  @override
  String get adapters => '适配器';

  @override
  String get adaptersAutoDetected => '自动检测到本机可用的智能体运行器。安装缺失的 CLI 工具即可启用更多运行器。';

  @override
  String get add => '添加';

  @override
  String get addAComment => '添加评论';

  @override
  String get addAReaction => '添加回应';

  @override
  String get addASuggestion => '添加建议';

  @override
  String get addAgents => '添加智能体';

  @override
  String get addEmoji => '添加表情';

  @override
  String get addFeed => '添加订阅源';

  @override
  String get addressBarHint => '输入网址';

  @override
  String get addFromFile => '从文件添加';

  @override
  String get addGif => '添加 GIF';

  @override
  String get addGithubRepoPrompt => '添加至少一个 GitHub 仓库后才能查看 pull request';

  @override
  String get addLocalCheckoutDescription => '添加一个本地检出，让此工作区开始以它为目标。';

  @override
  String get addRepository => '添加仓库';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '添加 $count 个仓库',
      one: '添加仓库',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro => '浏览运行服务器的机器上的文件夹，选择要注册的 git 检出。';

  @override
  String get selectThisFolder => '选择此文件夹';

  @override
  String get deselectThisFolder => '取消选择此文件夹';

  @override
  String get goUp => '上一级';

  @override
  String get noSubfoldersHere => '此处没有子文件夹';

  @override
  String get notAGitRepository => '此文件夹不是 git 仓库。';

  @override
  String get addToken => '添加令牌';

  @override
  String get addWorkspace => '添加工作区';

  @override
  String get addWorkspaceEllipsis => '添加工作区…';

  @override
  String get added => '已添加';

  @override
  String get addingEllipsis => '正在添加…';

  @override
  String get advancedLabel => '高级';

  @override
  String get agent => '智能体';

  @override
  String agentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个智能体',
      one: '1 个智能体',
    );
    return '$_temp0';
  }

  @override
  String get agentMdPath => 'Agent MD 路径';

  @override
  String get agentName => '智能体名称';

  @override
  String get agentTitle => '智能体标题';

  @override
  String get agentUpdated => '智能体已更新。';

  @override
  String get agents => '智能体';

  @override
  String get agentsMentionSection => '智能体';

  @override
  String get usersMentionSection => '人员';

  @override
  String get ticketsMentionSection => '工单';

  @override
  String get pullRequestsMentionSection => 'Pull requests';

  @override
  String get meetingsMentionSection => '会议';

  @override
  String get entityRefTicketFallback => '工单';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => '会议';

  @override
  String get aiReview => 'AI 评审';

  @override
  String get all => '全部';

  @override
  String get allAgentsAlreadyInSpace => '所有智能体都已在此空间中。';

  @override
  String get allCommits => '所有提交';

  @override
  String get allSources => '所有来源';

  @override
  String get allow => '允许';

  @override
  String get allowGitPush => '允许 git push';

  @override
  String get allowGithubApi => '允许调用 GitHub API';

  @override
  String get allowNetwork => '允许常规网络访问';

  @override
  String get apiKeys => 'API 密钥';

  @override
  String get appFont => '应用字体';

  @override
  String get appLogLevelDebugDescription => '添加详细跟踪信息——供开发使用。';

  @override
  String get appLogLevelDebugLabel => '调试';

  @override
  String get appLogLevelErrorDescription => '仅意外错误与异常。';

  @override
  String get appLogLevelErrorLabel => '错误';

  @override
  String get appLogLevelInfoDescription => '添加生命周期与状态消息。';

  @override
  String get appLogLevelInfoLabel => '信息';

  @override
  String get appLogLevelNoneDescription => '完全不输出控制台信息。';

  @override
  String get appLogLevelNoneLabel => '无';

  @override
  String get appLogLevelVerboseDescription => '全部输出。极其嘈杂——仅用于调试。';

  @override
  String get appLogLevelVerboseLabel => '详细';

  @override
  String get appLogLevelWarningDescription => '添加警告与可恢复的问题。';

  @override
  String get appLogLevelWarningLabel => '警告';

  @override
  String get appearanceLanguage => '外观与语言';

  @override
  String get apply => '应用';

  @override
  String get approve => '批准';

  @override
  String get agentApprovalRequired => '需要审批';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还有 $count 个待处理',
      one: '还有 1 个待处理',
    );
    return '$_temp0';
  }

  @override
  String get approved => '已批准';

  @override
  String get articleNoun => '文章';

  @override
  String get articlesSubscribed => '来自你所有订阅源的文章。';

  @override
  String get askAi => '询问 AI';

  @override
  String get askAiReviewDescription => '让 AI 评审此 PR';

  @override
  String get assignees => '受理人';

  @override
  String get attachImage => '附加图片';

  @override
  String get attachedAgents => '附加的智能体';

  @override
  String get audioInput => '音频输入';

  @override
  String get audioOutput => '音频输出';

  @override
  String get authenticationToken => '身份验证令牌';

  @override
  String authoredByLabel(String role) {
    return '作者：$role';
  }

  @override
  String get autoRecommended => '自动（推荐）';

  @override
  String get available => '可用';

  @override
  String get awaitingYourReview => '等待你评审';

  @override
  String get back => '返回';

  @override
  String get backLabel => '返回';

  @override
  String get backend => '后端';

  @override
  String get blockAdsTrackers => '拦截广告、跟踪器与 Cookie 横幅';

  @override
  String get blocking => '阻塞';

  @override
  String get bookmarkLabel => '书签';

  @override
  String get briefDescription => '简短描述';

  @override
  String get bugLabel => 'BUG';

  @override
  String get bundledDefaultsNeverUpdated => '内置默认值——从不更新';

  @override
  String get cancel => '取消';

  @override
  String get cancelEdit => '取消编辑';

  @override
  String get categoryCreation => '创建';

  @override
  String get categoryEditing => '编辑';

  @override
  String get categoryNavigation => '导航';

  @override
  String get categorySystem => '系统';

  @override
  String get categoryView => '分类视图';

  @override
  String get change => '更改';

  @override
  String get changesRequested => '已请求变更';

  @override
  String get spacesMentionSection => '空间';

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get checking => '正在检查';

  @override
  String get checkingEllipsis => '正在检查…';

  @override
  String get chooseAppFont => '选择应用字体';

  @override
  String get chooseCodeFont => '选择代码字体';

  @override
  String get chooseRunner => '选择你的智能体运行器。';

  @override
  String get clear => '清除';

  @override
  String get clickToRetry => '点击重试';

  @override
  String get close => '关闭';

  @override
  String get closeEsc => '关闭（Esc）';

  @override
  String get closeReader => '关闭阅读器';

  @override
  String get closed => '已关闭';

  @override
  String get codeFont => '代码字体';

  @override
  String get codeFontLigatures => '代码字体连字';

  @override
  String get codeFontLigaturesDescription =>
      '在代码和 diff 中将编程连字（=>、!=、->）渲染为组合字形';

  @override
  String get collapse => '折叠';

  @override
  String get commandPalette => '命令面板';

  @override
  String get commandPaletteOrgMembers => '组织成员';

  @override
  String get commandPaletteBrowseTeam => '浏览团队';

  @override
  String get commandPaletteBrowseTeamDesc => '查看所有组织成员';

  @override
  String get compactDone => '会话已压缩。较早的历史已并入摘要。';

  @override
  String get compactNothing => '暂无可压缩的内容。会话还不长。';

  @override
  String get compactBusy => '智能体仍在工作。请在本轮结束后再压缩。';

  @override
  String get compactUnavailable => '此服务器不支持压缩。';

  @override
  String get commandsMentionSection => '命令';

  @override
  String get comment => '评论';

  @override
  String get commentOnThisFile => '对此文件发表评论';

  @override
  String get commented => '已评论';

  @override
  String get commits => '提交';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return '正在显示 $total 个提交中最新的 $loaded 个';
  }

  @override
  String get prCloneProgressCloningTitle => '正在克隆仓库';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return '此 PR 变更了 $fileCount 个文件，超出 GitHub API 的限制。正在本地克隆仓库…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      '此 PR 超出 GitHub API 的文件数限制。正在本地克隆仓库…';

  @override
  String get prCloneProgressFetchingTitle => '正在获取 PR 引用';

  @override
  String get prCloneProgressFetchingSubtitle => '正在获取基础分支与 PR head 引用…';

  @override
  String get prCloneProgressComputingTitle => '正在计算 diff';

  @override
  String get prCloneProgressComputingSubtitle => '正在本地运行 git diff…';

  @override
  String get prCloneProgressErrorTitle => '加载 diff 失败';

  @override
  String get prCloneProgressErrorSubtitle => '克隆或计算 diff 时出错。请尝试刷新。';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return '仍在处理… 已用时 $elapsed';
  }

  @override
  String confidenceLabel(int percent) {
    return '置信度：$percent%';
  }

  @override
  String get configureAgentIdentities => '配置智能体身份、提示词与技能，并查看运行。';

  @override
  String get configureDefaultRunners => '配置新空间与标题生成所用的适配器和模型。';

  @override
  String get configuredLabel => '已配置。';

  @override
  String get confirmedBy => '确认人';

  @override
  String get consensus => '共识';

  @override
  String get contentHint => '要记住的内容';

  @override
  String get contentLabel => '内容';

  @override
  String get contentMarkdown => '内容（Markdown）';

  @override
  String get contextWindowSize => '上下文窗口大小';

  @override
  String modelContextChip(String size) {
    return '模型 · $size';
  }

  @override
  String get continueLabel => '继续';

  @override
  String get conversationMode => '模式';

  @override
  String cookieRulesCount(int count) {
    return '$count 条 Cookie 规则';
  }

  @override
  String get copied => '已复制！';

  @override
  String get copy => '复制';

  @override
  String get copyAddress => '复制地址';

  @override
  String get copyBaseBranchTooltip => '复制基础分支名';

  @override
  String get copyHeadBranchTooltip => '复制 head 分支名';

  @override
  String couldNotListDevices(String error) {
    return '无法列出设备：$error';
  }

  @override
  String get create => '创建';

  @override
  String get createOrSelectWorkspace => '先创建或选择一个工作区，再添加仓库。';

  @override
  String get createPullRequest => '创建 pull request';

  @override
  String get createdByMe => '我创建的';

  @override
  String createdLabel(String date) {
    return '创建时间：$date';
  }

  @override
  String get currentParticipants => '当前参与者';

  @override
  String get customCapabilitiesDescription => '自定义能力描述';

  @override
  String get customSystemPrompt => '此智能体的自定义系统提示词……';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天前',
      one: '1 天前',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => '停用';

  @override
  String get defaultCapabilities => '默认能力 · 新空间';

  @override
  String get defaultChat => '默认聊天';

  @override
  String get defaultRunners => '默认运行器';

  @override
  String get delete => '删除';

  @override
  String get deleteAgent => '删除智能体';

  @override
  String deleteAgentConfirm(String name) {
    return '删除“$name”？此操作无法撤销。';
  }

  @override
  String get deleteSpace => '删除空间';

  @override
  String deleteConfirmName(String name) {
    return '删除“$name”？';
  }

  @override
  String get archiveConversation => '归档会话';

  @override
  String get deleteFact => '删除事实';

  @override
  String get deleteFeedBody => '这会移除该订阅源及其所有缓存文章。来自此订阅源的收藏文章也会一并移除。';

  @override
  String deleteFeedConfirm(String name) {
    return '删除“$name”？';
  }

  @override
  String get deletePolicy => '删除策略';

  @override
  String get deletePolicyConfirm => '删除此策略？此操作无法撤销。';

  @override
  String deleteTopicConfirm(String topic) {
    return '删除“$topic”？此操作无法撤销。';
  }

  @override
  String get deleteWorkspace => '删除工作区';

  @override
  String get deny => '拒绝';

  @override
  String get detailsLabel => '详情';

  @override
  String get descriptionLabel => '描述';

  @override
  String detectedBackend(String label) {
    return '检测到：$label';
  }

  @override
  String get detectedRunners => '检测到的运行器';

  @override
  String get detectingAdapters => '正在检测适配器…';

  @override
  String get detectingInputDevices => '正在检测输入设备…';

  @override
  String detectionFailed(String error) {
    return '检测失败：$error';
  }

  @override
  String get disabled => '已禁用';

  @override
  String get discover => '发现';

  @override
  String get dismissed => '已忽略';

  @override
  String get domainHint => '例如 api-performance';

  @override
  String get domainLabel => '域';

  @override
  String get download => '下载';

  @override
  String get downloadingLabel => '正在下载';

  @override
  String downloadingModel(int pct) {
    return '正在下载模型… $pct%';
  }

  @override
  String get draft => '草稿';

  @override
  String get draftLabel => '草稿';

  @override
  String get edit => '编辑';

  @override
  String get edited => '已编辑';

  @override
  String get editMessage => '编辑消息';

  @override
  String get revertToThere => '还原到那里';

  @override
  String get sendAsNewMessage => '作为新消息发送';

  @override
  String get editMessageChoiceBody =>
      '还原会隐藏这条消息之后的内容，并回退代理的文件。你可以撤销。作为新消息发送则保持对话不变。';

  @override
  String get deleteMessage => '删除消息';

  @override
  String get deleteMessageConfirm => '删除此消息？此操作无法撤销。';

  @override
  String get messageDeleted => '消息已删除';

  @override
  String get searchInConversation => '在会话中搜索';

  @override
  String get searchMessagesHint => '搜索消息…';

  @override
  String get noMessagesFound => '未找到消息';

  @override
  String get editFact => '编辑事实';

  @override
  String get editPolicy => '编辑策略';

  @override
  String get editSuggestedCodeHint => '编辑建议代码…';

  @override
  String get editSuggestion => '编辑建议';

  @override
  String get egArchitect => '例如 architect';

  @override
  String get egControlCenter => '例如 control-center';

  @override
  String get egPlatform => '例如 Platform';

  @override
  String get egSamuelAlev => '例如 SamuelAlev';

  @override
  String get egSoftwareArchitect => '例如 Software Architect';

  @override
  String get egTheVerge => '例如 The Verge';

  @override
  String get egTokenLimit => '例如 128000';

  @override
  String embeddingInstallFailed(String error) {
    return '安装失败：$error';
  }

  @override
  String get embeddingInstalled => '本地嵌入模型已安装。混合搜索已启用。';

  @override
  String get embeddingModel => '嵌入模型（ONNX）';

  @override
  String get embeddingNotInstalled => '未安装。启用前搜索仅使用关键词。';

  @override
  String get embeddingRedownloadBody => '现有模型文件将被删除并重新下载。下载完成前语义搜索不可用。';

  @override
  String get embeddingRemoveBody => '重新安装前语义搜索将保持禁用。你可以随时再次安装。';

  @override
  String get speakerDiarization => '说话人分离';

  @override
  String get diarizationModel => '说话人分离模型';

  @override
  String get diarizationInstalled => '已安装——在会议转写中标出各说话人';

  @override
  String get diarizationNotInstalled => '未安装——会议中不会区分说话人';

  @override
  String diarizationInstallFailed(String error) {
    return '安装失败：$error';
  }

  @override
  String get redownloadDiarizationModel => '重新下载说话人分离模型';

  @override
  String get diarizationRedownloadBody => '这会移除当前的说话人分离模型并重新下载。';

  @override
  String get removeDiarizationModel => '移除说话人分离模型';

  @override
  String get diarizationRemoveBody => '这会删除设备上的说话人分离模型。已生成的会议转写不受影响。';

  @override
  String get enableNotifications => '启用通知';

  @override
  String get enableSandboxing => '启用沙盒';

  @override
  String get enabled => '已启用';

  @override
  String errorCreatingAgent(String error) {
    return '创建智能体时出错：$error';
  }

  @override
  String errorDeletingAgent(String error) {
    return '删除智能体时出错：$error';
  }

  @override
  String errorWithDetail(String error) {
    return '错误：$error';
  }

  @override
  String get expand => '展开';

  @override
  String extractingModel(int pct) {
    return '正在解压模型… $pct%';
  }

  @override
  String get fact => '事实';

  @override
  String factCount(int count) {
    return '$count 个事实';
  }

  @override
  String factCountPlural(int count) {
    return '$count 个事实';
  }

  @override
  String get facts => '事实';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount 个事实 · $policyCount 条策略';
  }

  @override
  String get failed => '失败';

  @override
  String failedToDispatch(String error) {
    return '调度失败：$error';
  }

  @override
  String get failedToLoad => '加载失败';

  @override
  String failedToLoadAgents(String error) {
    return '加载智能体失败：$error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return '加载订阅源失败：$error';
  }

  @override
  String get failedToLoadGifs => '加载 GIF 失败';

  @override
  String failedToLoadLogs(String error) {
    return '加载日志失败：$error';
  }

  @override
  String get failedToLoadRepos => '加载仓库失败';

  @override
  String get failedToLoadWorkspaces => '加载工作区失败';

  @override
  String failedToStartAiReview(String error) {
    return '启动 AI 评审失败：$error';
  }

  @override
  String get failedToStartMicTest => '启动麦克风测试失败。';

  @override
  String failedToSubmitReview(String error) {
    return '提交评审失败：$error';
  }

  @override
  String failedToUpload(String name, String error) {
    return '上传 $name 失败：$error';
  }

  @override
  String failedWithError(String error) {
    return '失败：$error';
  }

  @override
  String get failure => '失败';

  @override
  String get feedAlreadyExists => '此 URL 的订阅源已存在。';

  @override
  String get feedUrlExample => '例如 https://example.com/feed.xml';

  @override
  String get feedUrlLabel => '订阅源 URL';

  @override
  String feedsCount(int count) {
    return '订阅源（$count）';
  }

  @override
  String get filesChanged => '文件变更';

  @override
  String filesCount(int count) {
    return '$count 个文件';
  }

  @override
  String get filesMentionSection => '文件';

  @override
  String get filterAgents => '筛选智能体…';

  @override
  String get filterFilesHint => '筛选文件…';

  @override
  String get filterLists => '筛选列表';

  @override
  String get filterSkillsPlaceholder => '筛选技能…';

  @override
  String get finish => '完成';

  @override
  String get fix => '修复';

  @override
  String get forward => '前进';

  @override
  String get gatesGithubPatPush => '对 GitHub PAT 注入进行门控。智能体推送时必需。';

  @override
  String get general => '通用';

  @override
  String get githubLink => 'GitHub 链接';

  @override
  String get claudeStatusFetchFailed => '无法访问 status.claude.com';

  @override
  String get claudeStatusOpenInBrowser => '打开 status.claude.com';

  @override
  String get githubStatusFetchFailed => '无法访问 githubstatus.com';

  @override
  String get githubDegradedTitle => 'GitHub 报告出现问题';

  @override
  String githubDegradedStatusLine(String status) {
    return 'GitHub 状态：$status。';
  }

  @override
  String githubDegradedBody(String status) {
    return 'GitHub 状态：$status。恢复前 pull request 数据可能过期或不完整。';
  }

  @override
  String get githubStatusOpenInBrowser => '打开 githubstatus.com';

  @override
  String get githubStatusRefresh => '刷新';

  @override
  String githubStatusUpdated(String time) {
    return '已更新 $time';
  }

  @override
  String get kimiStatusFetchFailed => '无法访问 status.moonshot.cn';

  @override
  String get kimiStatusOpenInBrowser => '打开 status.moonshot.cn';

  @override
  String get openaiStatusFetchFailed => '无法访问 status.openai.com';

  @override
  String get openaiStatusOpenInBrowser => '打开 status.openai.com';

  @override
  String get serviceStatusMaintenance => '维护';

  @override
  String get serviceStatusMajorIssues => '严重故障';

  @override
  String get serviceStatusMinorIssues => '轻微故障';

  @override
  String get serviceStatusOperational => '正常运行';

  @override
  String get serviceStatusOutage => '服务中断';

  @override
  String get serviceStatusTitle => '服务状态';

  @override
  String get serviceStatusUnknown => '未知';

  @override
  String lastChecked(String time) {
    return '已检查 $time';
  }

  @override
  String get lastCheckedRecently => '刚刚检查过';

  @override
  String get giveYourWorkAHome => '给你的工作安个家。';

  @override
  String get goBack => '后退';

  @override
  String get goForward => '前进';

  @override
  String get googleFonts => 'Google 字体';

  @override
  String get high => '高';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小时前',
      one: '1 小时前',
    );
    return '$_temp0';
  }

  @override
  String get images => '图片';

  @override
  String get inactive => '非活跃';

  @override
  String get install => '安装';

  @override
  String get installRequired => '需要安装';

  @override
  String installedVersion(String version) {
    return '已安装 $version';
  }

  @override
  String get invite => '邀请';

  @override
  String get inviteAgent => '邀请智能体';

  @override
  String get isolateAgentExecution => '隔离智能体执行。';

  @override
  String get justNow => '刚刚';

  @override
  String get keepSandboxing => '保留沙盒';

  @override
  String get keybindingAddARepositoryDescription => '添加仓库';

  @override
  String get keybindingAddRepository => '添加仓库';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      '收藏或取消收藏所选文章';

  @override
  String get keybindingCommandPalette => '命令面板';

  @override
  String get keybindingCreateANewAgentDescription => '创建新智能体';

  @override
  String get keybindingCreateANewWorkspaceDescription => '创建新工作区';

  @override
  String get keybindingFocusSearch => '聚焦搜索';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      '聚焦 pull request 搜索框';

  @override
  String get keybindingNewAgent => '新建智能体';

  @override
  String get keybindingNewWorkspace => '新建工作区';

  @override
  String get keybindingNextArticle => '下一篇文章';

  @override
  String get keybindingNextSpace => '下一个空间';

  @override
  String get keybindingNextWorkspace => '下一个工作区';

  @override
  String get keybindingOpenArticle => '打开文章';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      '打开或关闭侧栏中的工作区切换弹窗';

  @override
  String get keybindingOpenPr => '打开 PR';

  @override
  String get keybindingOpenSettings => '打开设置';

  @override
  String get keybindingOpenTheApplicationSettingsDescription => '打开应用设置';

  @override
  String get keybindingOpenTheCommandPaletteDescription => '打开命令面板';

  @override
  String get keybindingOpenTheSelectedArticleDescription => '打开所选文章';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      '打开所选 pull request';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription => '打开所选工作区';

  @override
  String get keybindingOpenWorkspace => '打开工作区';

  @override
  String get keybindingPreviousArticle => '上一篇文章';

  @override
  String get keybindingPreviousSpace => '上一个空间';

  @override
  String get keybindingPreviousWorkspace => '上一个工作区';

  @override
  String get keybindingRefresh => '刷新';

  @override
  String get keybindingRefreshAllFeedsDescription => '刷新所有订阅源';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      '刷新 pull request 列表';

  @override
  String get keybindingRescanForAdaptersDescription => '重新扫描适配器';

  @override
  String get keybindingSelectTheNextArticleDescription => '选择下一篇文章';

  @override
  String get keybindingSelectTheNextSpaceDescription => '选择下一个空间';

  @override
  String get keybindingSelectThePreviousArticleDescription => '选择上一篇文章';

  @override
  String get keybindingSelectThePreviousSpaceDescription => '选择上一个空间';

  @override
  String get keybindingSendMessage => '发送消息';

  @override
  String get keybindingSendTheCurrentMessageDescription => '发送当前消息';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      '在浅色与深色模式之间切换';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription => '切换到第八个工作区';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription => '切换到第五个工作区';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription => '切换到第一个工作区';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription => '切换到第四个工作区';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription => '切换到下一个工作区';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription => '切换到第九个工作区';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription => '切换到上一个工作区';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription => '切换到第二个工作区';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription => '切换到第七个工作区';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription => '切换到第六个工作区';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription => '切换到第三个工作区';

  @override
  String get keybindingToggleBookmark => '切换书签';

  @override
  String get keybindingToggleTheme => '切换主题';

  @override
  String get keybindingToggleWorkspaceSwitcher => '切换工作区切换器';

  @override
  String get keybindingWorkspace1 => '工作区 1';

  @override
  String get keybindingWorkspace2 => '工作区 2';

  @override
  String get keybindingWorkspace3 => '工作区 3';

  @override
  String get keybindingWorkspace4 => '工作区 4';

  @override
  String get keybindingWorkspace5 => '工作区 5';

  @override
  String get keybindingWorkspace6 => '工作区 6';

  @override
  String get keybindingWorkspace7 => '工作区 7';

  @override
  String get keybindingWorkspace8 => '工作区 8';

  @override
  String get keybindingWorkspace9 => '工作区 9';

  @override
  String get keybindings => '快捷键';

  @override
  String get keybindingsDescription => '所有键盘快捷键。快捷键是固定的，无法重新分配。';

  @override
  String get killRunning => '终止运行';

  @override
  String get languageSystem => '系统';

  @override
  String get leaveACommentEllipsis => '发表评论…';

  @override
  String get legendLabel => '图例';

  @override
  String get lessLabel => '更少';

  @override
  String get letsPluginTools => '来接入你的工具吧。';

  @override
  String get level => '级别';

  @override
  String get loadingAgents => '正在加载智能体…';

  @override
  String get loadingModels => '正在加载模型…';

  @override
  String get loadingProviders => '正在加载提供商…';

  @override
  String get logLevel => '日志级别';

  @override
  String get logs => '日志';

  @override
  String get low => '低';

  @override
  String get maintenance => '维护';

  @override
  String get manageParticipants => '管理参与者';

  @override
  String get manageWorkspaces => '管理工作区';

  @override
  String get reorderWorkspace => '重新排序工作区';

  @override
  String get matchOsAppearance => '跟随系统外观，或选择固定模式。';

  @override
  String get mcpAuthToken => 'MCP 身份验证令牌';

  @override
  String get mcpNotAvailableOnServer => '所连接的服务器不支持 MCP 服务器控制。';

  @override
  String get modelManagedOnServer => '此模型运行在服务器主机上，并在那里管理。';

  @override
  String get mcpServer => 'MCP 服务器';

  @override
  String get medium => '中';

  @override
  String get memoryDataHint => '智能体工作时，事实与策略会出现在这里。';

  @override
  String get memoryLabel => '记忆';

  @override
  String get merge => '合并';

  @override
  String get merged => '已合并';

  @override
  String get messagePlaceholder => '消息…（@ 提及，/ 命令）';

  @override
  String get navConversations => '空间';

  @override
  String get microphonePermissionDenied => '麦克风权限被拒绝。';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟前',
      one: '1 分钟前',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => '模型';

  @override
  String get modified => '已修改';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个月前',
      one: '1 个月前',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => '更多';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => '名称';

  @override
  String get nameAndTitleRequired => '必须填写名称和标题。';

  @override
  String get nameAndUrlRequired => '必须填写名称和 URL';

  @override
  String get nameLabel => '名称';

  @override
  String nativeSandboxAvailable(String platform) {
    return '$platform 上可用原生沙盒。';
  }

  @override
  String get nativeSandboxNeedsInstall => '需要安装原生沙盒';

  @override
  String get navObservability => '可观测性';

  @override
  String get navSettings => '设置';

  @override
  String networkBlockCount(int count) {
    return '$count 条网络拦截规则';
  }

  @override
  String get neutral => '中立';

  @override
  String get newCommitsPushed => '有新提交推送——点击重新加载 diff';

  @override
  String get newFact => '新事实';

  @override
  String get newPolicy => '新策略';

  @override
  String get newsfeed => '新闻流';

  @override
  String get newsfeedLabel => '新闻流';

  @override
  String get newsfeedSettingsDescription => '管理你的订阅源与阅读器偏好。';

  @override
  String get newsfeedSettingsTitle => '新闻流设置';

  @override
  String get nextMatch => '下一个匹配（↵）';

  @override
  String get noActiveWorkspace => '未选择活动工作区或仓库。';

  @override
  String get noActiveWorkspaceCreate => '无活动工作区';

  @override
  String get noActiveWorkspaceGithub => '没有包含 GitHub 仓库的活动工作区。';

  @override
  String get noAgents => '暂无智能体';

  @override
  String get noArticlesYet => '暂无文章';

  @override
  String get noArticlesYetBody => '你订阅源中的文章会出现在这里。';

  @override
  String get noExecutionLogsYet => '暂无执行日志';

  @override
  String get noFacts => '暂无事实';

  @override
  String get noFeedsYet => '暂无订阅源';

  @override
  String get noFileAnchor => '无文件锚点——无法发表行内评论。';

  @override
  String get noFileChangesInScope => '此范围内没有文件变更';

  @override
  String get noGifsFound => '未找到 GIF';

  @override
  String get noInputDevicesDetected => '未检测到输入设备——将使用系统默认设备。';

  @override
  String get noMatchingFiles => '没有匹配的文件';

  @override
  String get noMatchingGoogleFonts => '没有匹配的 Google 字体。';

  @override
  String get noMemoryData => '暂无记忆数据';

  @override
  String get noMessagesYet => '暂无消息';

  @override
  String get noModelsAdvertised => '此适配器未提供任何模型。';

  @override
  String get noOpenPullRequests => '没有打开的 pull request';

  @override
  String get noPolicies => '暂无策略';

  @override
  String get noReposInWorkspaceYet => '此工作区还没有仓库';

  @override
  String get noRunnersDetected => '尚未检测到运行器。刷新即可重新扫描。';

  @override
  String get noSavedArticles => '暂无收藏文章';

  @override
  String get noSavedArticlesBody => '你收藏的文章会出现在这里。';

  @override
  String noShortcutsMatch(String query) {
    return '没有匹配“$query”的快捷键';
  }

  @override
  String get noSystemFonts => '未检测到系统字体。';

  @override
  String get noTokenSet => '未设置令牌——访问不受限制。';

  @override
  String get noWorkingMemory => '暂无工作记忆笔记。';

  @override
  String get noneAllRoles => '无（所有角色）';

  @override
  String get notAvailable => '不可用';

  @override
  String get notConfiguredLabel => '未配置。';

  @override
  String get notFoundLabel => '未找到';

  @override
  String get notes => '笔记';

  @override
  String get notificationAgentFinished => '智能体已完成';

  @override
  String get notificationPrMentioned => '在 pull request 中被提及';

  @override
  String get notificationNewMessages => '新消息';

  @override
  String get notificationPrMerged => 'PR 已合并';

  @override
  String get notificationPrPublished => 'PR 已发布';

  @override
  String get notificationReviewRequested => '请求评审';

  @override
  String get notifications => '通知';

  @override
  String get notifyAgentRunCompleted => '智能体完成运行时通知。';

  @override
  String get notifyPrMentioned => '你在 pull request 中被提及时通知。';

  @override
  String get notifyNewMessages => '其他空间有新的智能体消息时通知。';

  @override
  String get notifyPrMerged => 'pull request 合并时通知。';

  @override
  String get notifyPrPublished => '智能体发布 pull request 时通知。';

  @override
  String get notifyReviewRequested => 'pull request 请求你评审时通知。';

  @override
  String get notificationReviewStale => '评审已过期';

  @override
  String get notifyReviewStale => '你已评审过的 pull request 有新提交时';

  @override
  String get notificationPrMergeReadiness => '可合并';

  @override
  String get notifyPrMergeReadiness => '你创建的 pull request 变为可合并或不再可合并时通知。';

  @override
  String get notificationPrReviewDecision => '评审决定';

  @override
  String get notifyPrReviewDecision => '评审者批准、请求变更或批准被驳回时通知。';

  @override
  String get notificationPrChecksStatus => '检查';

  @override
  String get notifyPrChecksStatus => '你创建的 pull request 上 CI 失败及恢复时通知。';

  @override
  String get notificationPrThreadActivity => '评审讨论串';

  @override
  String get notifyPrThreadActivity => '你所在的讨论串有人回复或被解决时通知。';

  @override
  String get notificationPrReadyToMerge => '可合并';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '$prTitle 已具备合并所需的全部条件。';
  }

  @override
  String get notificationPrMergeBlocked => '不再可合并';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '$prTitle 与基础分支存在冲突。';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '$prTitle 落后于基础分支。';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '$prTitle 正在等待必需的评审。';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return '一位评审者对 $prTitle 请求了变更。';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return '$prTitle 上的检查未通过。';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '$prTitle 已无法合并。';
  }

  @override
  String get notificationPrApproved => 'Pull request 已获批准';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '$login 批准了 $prTitle';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '$prTitle 已获批准';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还有 $count 位评审者待响应',
      one: '还有 1 位评审者待响应',
      zero: '没有待响应的评审者',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => '已请求变更';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '$login 对 $prTitle 请求了变更';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return '$prTitle 被请求变更';
  }

  @override
  String get notificationPrReviewDismissed => '批准被驳回';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '$prTitle 需要重新评审。';
  }

  @override
  String get notificationPrChecksFailed => '检查未通过';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '$checkName 在 $prTitle 上失败';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return '$prTitle 上的检查未通过';
  }

  @override
  String get notificationPrChecksRecovered => '检查已通过';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '$prTitle 恢复正常了。';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '$login 在 $location 中提到了你';
  }

  @override
  String get notificationPrThreadReplied => '新回复';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '$login 在 $location 中回复了';
  }

  @override
  String get notificationPrThreadResolved => '讨论串已解决';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return '你在 $location 中的讨论串已解决。';
  }

  @override
  String get notificationGroupAgents => '智能体';

  @override
  String get notificationGroupPullRequests => 'Pull requests';

  @override
  String get notificationGroupMessages => '消息';

  @override
  String get notificationGroupTickets => '工单';

  @override
  String get notificationGroupCalendar => '日历';

  @override
  String get notificationGroupMachines => '机器';

  @override
  String get notificationsMutedRepos => '已静音的仓库';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已静音 $count 个仓库',
      one: '已静音 1 个仓库',
      zero: '未静音任何仓库',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => '静音此仓库';

  @override
  String get onboardingLinuxDescription =>
      'Control Center 可以使用 Linux 容器来隔离智能体执行。';

  @override
  String get onboardingMacosDescription =>
      'Control Center 在 macOS 上使用原生沙盒来隔离智能体执行。';

  @override
  String get onboardingUnsupportedDescription => '此平台不支持沙盒。智能体执行将不进行隔离。';

  @override
  String get openArticlesInApp => '在应用内打开文章';

  @override
  String get openInBrowser => '在浏览器中打开';

  @override
  String get openedInYourBrowser => '已在浏览器中打开。';

  @override
  String get openLabel => '打开';

  @override
  String get openOnGithub => '在 GitHub 上打开';

  @override
  String get openStatus => '打开';

  @override
  String get optionalPersonaDescription => '可选的角色设定描述';

  @override
  String get otherLabel => '其他';

  @override
  String get ownerOrganization => '所有者 / 组织';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => '已通过';

  @override
  String get pasteValueHere => '在此粘贴值';

  @override
  String get persona => '角色设定';

  @override
  String get policies => '策略';

  @override
  String get policiesHint => '智能体提升事实后，策略会出现在这里。';

  @override
  String get policy => '策略';

  @override
  String get popular => '热门';

  @override
  String get port => '端口';

  @override
  String get postingEllipsis => '正在发布…';

  @override
  String get prCommits => '提交';

  @override
  String get prMergedBody => '一个 pull request 已合并';

  @override
  String get prMoreActions => '更多操作';

  @override
  String get prTitle => 'PR 标题';

  @override
  String get reviewCommentHint => '直接点击批准即可；想加点料的话，也可以留下评论或回应…';

  @override
  String get nothingToPreview => '无可预览内容';

  @override
  String get previousMatch => '上一个匹配（⇧↵）';

  @override
  String get priorityReviewsDescription => '优先评审与仓库概览。';

  @override
  String get prsCreated => '已创建 PR';

  @override
  String get prsMerged => '已合并 PR';

  @override
  String get publishToGithub => '发布到 GitHub';

  @override
  String get published => '已发布';

  @override
  String get pullRequestApproved => 'Pull request 已获批准';

  @override
  String get pullRequests => 'Pull requests';

  @override
  String get questionLabel => '问题';

  @override
  String get queued => '排队中';

  @override
  String get react => '回应';

  @override
  String get readPrsIssuesMetadata => '允许智能体读取 PR、issue 与仓库元数据。';

  @override
  String get readerPreferences => '阅读器偏好';

  @override
  String get reasoningEffort => '推理力度';

  @override
  String get recommendLabel => '推荐';

  @override
  String recordingFromDevice(String device) {
    return '正在从 $device 录制。';
  }

  @override
  String get redownload => '重新下载';

  @override
  String get redownloadEmbeddingModel => '重新下载嵌入模型？';

  @override
  String get redownloadVoiceModel => '重新下载语音模型？';

  @override
  String get refinePlan => '完善计划';

  @override
  String get refresh => '刷新';

  @override
  String get refreshAll => '全部刷新';

  @override
  String get refreshAllFeeds => '刷新所有订阅源';

  @override
  String get reject => '拒绝';

  @override
  String get rejected => '已拒绝';

  @override
  String get reload => '重新加载';

  @override
  String get remove => '移除';

  @override
  String get removeBookmark => '移除书签';

  @override
  String get removeEmbeddingModel => '移除嵌入模型？';

  @override
  String get removeLogo => '移除徽标';

  @override
  String get removeRepoFromWorkspace => '从此工作区移除仓库？';

  @override
  String get removeVoiceModel => '移除语音模型？';

  @override
  String get removed => '已移除';

  @override
  String get renamed => '已重命名';

  @override
  String get reopen => '重新打开';

  @override
  String get resolve => '解决';

  @override
  String get replyEllipsis => '回复…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name 将从此工作区移除。磁盘上的本地文件不受影响。';
  }

  @override
  String repoAccessNoticeBody(String repos) {
    return '服务器的 GitHub 凭据无法访问 $repos。如果仓库属于某个组织，请在该组织安装 GitHub App，或连接具有访问权限的令牌。';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 个仓库无法访问',
      one: '有 1 个仓库无法访问',
    );
    return '$_temp0';
  }

  @override
  String get repoAccessNoticeSuspendedTitle => 'GitHub App 安装已被暂停';

  @override
  String repoAccessNoticeSuspendedBody(String repos) {
    return '正在显示 $repos 的上次已知数据。请在 GitHub 上恢复安装，或连接具有访问权限的令牌。';
  }

  @override
  String get repoNoAccessBadge => '无访问权限';

  @override
  String get reportsTo => '汇报对象';

  @override
  String reposCount(int count) {
    return '仓库（$count）';
  }

  @override
  String get reposDescription => '此工作区指向的本地检出。';

  @override
  String get repositories => '仓库';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个仓库',
      one: '1 个仓库',
    );
    return '无法添加 $_temp0：$error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已添加 $count 个仓库',
      one: '仓库已添加',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => '仓库设置';

  @override
  String get repositoryName => '仓库名称';

  @override
  String get requestChanges => '请求变更';

  @override
  String get requested => '已请求';

  @override
  String get requestedChanges => '已请求变更';

  @override
  String requiredRoleLabel(String role) {
    return '所需角色：$role';
  }

  @override
  String get requiredRoleOptional => '所需角色（可选）';

  @override
  String get requirements => '需求';

  @override
  String get reset => '重置';

  @override
  String get resolved => '已解决';

  @override
  String get enclosedTerminalTitle => '隔离终端';

  @override
  String get enclosedTerminalStart => '打开 shell';

  @override
  String get enclosedTerminalStartHint =>
      '此 shell 运行在此会话的一次性 VM 内。它在你打开时启动，而非应用启动时。';

  @override
  String get terminalStreamReconnecting => '流已中断——正在重新连接…';

  @override
  String get terminalStreamError => '流错误：';

  @override
  String get terminalShellExited => 'shell 已退出';

  @override
  String get restartShell => '重启 shell';

  @override
  String get retry => '重试';

  @override
  String get review => '评审';

  @override
  String get reviewedByMe => '我评审过的';

  @override
  String get reviewers => '评审者';

  @override
  String get roleLabel => '角色';

  @override
  String get ruleHint => '策略规则（支持 Markdown）';

  @override
  String get ruleLabel => '规则';

  @override
  String get runCompleted => '运行已完成';

  @override
  String get running => '运行中';

  @override
  String get runningLabel => '运行中';

  @override
  String get runs => '运行';

  @override
  String get runsLabel => '运行';

  @override
  String get sandboxBackendNativeLabel => '原生沙盒';

  @override
  String get sandboxBackendMicrovmLabel => '封闭虚拟机';

  @override
  String get sandboxBackendNoneLabel => '无隔离';

  @override
  String get sandboxLinuxInstall =>
      'Linux/WSL2 上的原生沙箱使用 bubblewrap。安装命令：\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'macOS 上已内置原生沙箱，使用 Apple Seatbelt（`sandbox-exec`）。无需安装。';

  @override
  String get sandboxPermissions => '沙箱权限';

  @override
  String get sandboxUnsupported => '此平台尚不支持原生沙箱，将回退到「无隔离」。';

  @override
  String get sandboxingDisabledDescription => '智能体将在宿主机上直接运行并拥有完整环境 — 不推荐。';

  @override
  String sandboxingEnabledDescription(String backend) {
    return '所有智能体调用均经由 $backend。';
  }

  @override
  String get save => '保存';

  @override
  String get saveChanges => '保存更改';

  @override
  String get adapterArguments => '额外参数';

  @override
  String get adapterArgumentsHint => '附加 CLI 标志（例如 --yolo）';

  @override
  String get addVariable => '添加变量';

  @override
  String get environmentVariables => '环境变量';

  @override
  String get environmentVariablesDescription =>
      '传递给此适配器的自定义环境变量（例如 API 密钥）。存储在钥匙串中。';

  @override
  String get variableKey => '键';

  @override
  String get variableValue => '值';

  @override
  String get savingEllipsis => '正在保存…';

  @override
  String get scopeDiffToCommits => '将 diff 限定到提交 — 按住 Shift 单击可选择范围';

  @override
  String get noPrsMatchSearch => '没有匹配的 pull request';

  @override
  String get searchFactsHint => '搜索事实...';

  @override
  String get searchFonts => '搜索字体…';

  @override
  String get searchGifs => '搜索 GIF';

  @override
  String get searchGifsHint => '搜索 GIF...';

  @override
  String get searchInDiffHint => '在 diff 中搜索…';

  @override
  String get searchOrTypeModel => '搜索或输入模型名称…';

  @override
  String get searchPlaceholder => '搜索…';

  @override
  String get searchShortcuts => '搜索快捷键…';

  @override
  String get shortcutUnavailableInBrowser => '在浏览器中不可用';

  @override
  String get searching => '正在搜索…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 秒前',
      one: '1 秒前',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => '选择适配器';

  @override
  String get selectAdapterFirst => '请先选择适配器';

  @override
  String get selectAgentToReportTo => '选择要汇报的智能体…';

  @override
  String get selectAnAgent => '选择智能体';

  @override
  String get selectConversation => '选择对话';

  @override
  String get selectLabel => '选择';

  @override
  String get selectRunner => '选择运行器';

  @override
  String get semanticSearch => '语义搜索';

  @override
  String get send => '发送';

  @override
  String get sendFirstMessage => '发送第一条消息';

  @override
  String get sendMessage => '发送消息';

  @override
  String sentFindingsToAgent(int count) {
    return '已将 $count 条发现发送给智能体。';
  }

  @override
  String setGithubLinkDescription(String name) {
    return '设置 $name 的 GitHub 所有者和仓库名称。用于解析 markdown 内容中的 PR 和议题引用（例如 #123）。';
  }

  @override
  String get setLabel => '设置';

  @override
  String get setToken => '设置令牌';

  @override
  String get settingsLabel => '设置';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageDescription => '选择应用语言。';

  @override
  String get shortTask => '短任务';

  @override
  String get showNativeNotifications => '为事件显示系统通知。';

  @override
  String get showSuperseded => '显示已替代';

  @override
  String get signedIn => '已登录。';

  @override
  String signedInAs(String username) {
    return '已以 $username 身份登录。';
  }

  @override
  String get skillNameRequired => '技能名称为必填项。';

  @override
  String skillSaved(String name) {
    return '技能“$name”已保存。';
  }

  @override
  String get skillsSourcesTab => '来源';

  @override
  String get skillSourcesDisclaimer =>
      '技能从你添加的 GitHub 仓库安装。仓库元数据不可信——杀毒扫描才是真正的安全信号。';

  @override
  String get skillSourcesEmpty => '暂无技能仓库';

  @override
  String get skillSourcesEmptyHint => '添加 GitHub 仓库以浏览其中的技能。';

  @override
  String get skillSourceAdd => '添加仓库';

  @override
  String get skillSourceAddTitle => '添加技能仓库';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      '请输入 GitHub 仓库 URL（https://github.com/owner/repo）。';

  @override
  String skillSourceAdded(String repo) {
    return '已添加仓库 $repo。';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return '仓库 $repo 已添加。';
  }

  @override
  String skillSourceRemoved(String repo) {
    return '已移除仓库 $repo。';
  }

  @override
  String get skillSourceRemove => '移除';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return '移除 $repo？';
  }

  @override
  String get skillSourceRemoveConfirmBody => '已安装的技能仍会保留。仅移除仓库目录。';

  @override
  String get skillSourceNoSkills => '此仓库中未找到技能（技能是包含 SKILL.md 的目录）。';

  @override
  String get skillSourceRefresh => '刷新';

  @override
  String get skillSourceInstalledBadge => '已安装';

  @override
  String get skillSourceUpdateBadge => '有可用更新';

  @override
  String get skillSourceSlugTaken => '名称已被占用';

  @override
  String skillSourceFilesCount(num count) {
    return '$count 个文件';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => '此技能没有 README。';

  @override
  String get skillSourceNoMatches => '没有符合筛选条件的技能。';

  @override
  String get skillUpdateAction => '更新';

  @override
  String get skillUninstallAction => '卸载';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return '卸载“$slug”？';
  }

  @override
  String skillUninstalled(String slug) {
    return '技能“$slug”已卸载。';
  }

  @override
  String get skillFindingLine => '行';

  @override
  String get skillInstallAnywayOverride => '我了解风险，仍要安装';

  @override
  String skillInstalled(String slug) {
    return '技能“$slug”已安装。';
  }

  @override
  String get skillPreviewCapabilities => '能力';

  @override
  String get skillPreviewFindings => '发现项';

  @override
  String get skillPreviewGuardedActions => '受保护操作';

  @override
  String get skillPreviewLlmReviewed => '已由 LLM 审核';

  @override
  String get skillPreviewNoCapabilities => '未声明能力。';

  @override
  String get skillPreviewNoFindings => '无发现项。';

  @override
  String get skillPreviewScanning => '正在扫描技能…';

  @override
  String get skillPreviewVerdictLabel => '扫描结论';

  @override
  String get skillPreviewVerdictPass => '通过';

  @override
  String get skillPreviewVerdictQuarantine => '已隔离';

  @override
  String get skillPreviewVerdictWarn => '警告';

  @override
  String get skillQuarantineWarning =>
      '此技能已被扫描器隔离。安装后会在本机运行代码。仅在信任来源并已审阅扫描结果时继续。';

  @override
  String skillDetachedFromAgents(String agents) {
    return '已隔离并从智能体分离：$agents';
  }

  @override
  String get skillNotScanned => '未扫描';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => '手动';

  @override
  String get skillOriginRegistry => '注册中心';

  @override
  String get skillOriginRuntimeLocal => '运行时本地';

  @override
  String get skillRulesStale => '扫描已过期';

  @override
  String get skillSaveAnywayOverride => '我了解风险 — 仍要保存';

  @override
  String get skillSaveBlockedBody => '内容在写入前已被拦截。';

  @override
  String get skillSaveBlockedTitle => '保存被扫描门禁拦截';

  @override
  String get skillScanAction => '扫描';

  @override
  String get skillScanAll => '全部扫描';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass 通过 · $warn 警告 · $quarantine 已隔离';
  }

  @override
  String get skillStateDrifted => '安装后已修改';

  @override
  String get skillStateUnmanaged => '未托管';

  @override
  String get skillSeverityBlocked => '已拦截';

  @override
  String get skillSeverityWarn => '警告';

  @override
  String get skillsInstalledTab => '已安装';

  @override
  String get skills => '技能';

  @override
  String get skipAcceptRisk => '跳过 — 我接受风险';

  @override
  String get skipForNow => '暂时跳过';

  @override
  String get skipSandboxing => '跳过沙箱';

  @override
  String get skipSandboxingDialogContent => '确定要跳过沙箱吗？这将允许智能体在无隔离的情况下在系统上执行代码。';

  @override
  String get somethingWentWrong => '出了点问题';

  @override
  String sourceCount(int count) {
    return '$count 个来源';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count 个来源';
  }

  @override
  String get sourceFacts => '来源信息：';

  @override
  String get splitDiff => '并排差异对比';

  @override
  String get startLabel => '开始';

  @override
  String get startOnAppLaunch => '随应用启动';

  @override
  String get statusLabel => '状态';

  @override
  String get onboardingStepConnect => '连接';

  @override
  String get onboardingStepWorkspace => '工作区';

  @override
  String get onboardingStepSandbox => '沙箱';

  @override
  String get onboardingStepAdapter => '适配器';

  @override
  String get onboardingStepVoice => '语音';

  @override
  String get stop => '停止';

  @override
  String get stopped => '已停止';

  @override
  String get strictIdentityCheck => '严格身份校验';

  @override
  String get success => '成功';

  @override
  String get successLabel => '成功';

  @override
  String get suggestAChange => '建议更改';

  @override
  String get suggestion => '建议';

  @override
  String get suggestLabel => '建议';

  @override
  String get superseded => '已替代';

  @override
  String get synced => '已同步';

  @override
  String get systemDefault => '系统默认';

  @override
  String get systemFonts => '系统字体';

  @override
  String get systemPrompt => '系统提示词';

  @override
  String get systemPromptLabel => '系统提示词';

  @override
  String get talkToControlCenter => '与 Control Center 对话。';

  @override
  String get taskMentionSection => '任务';

  @override
  String get testLabel => '测试';

  @override
  String get theme => '主题';

  @override
  String get themeDark => '深色';

  @override
  String get themeLight => '浅色';

  @override
  String get themeSystem => '系统';

  @override
  String get thisCannotBeUndone => '此操作无法撤销。';

  @override
  String get ticketLabel => '工单';

  @override
  String get titleLabel => '标题';

  @override
  String get todayLabel => '今天';

  @override
  String get toggleTheme => '切换主题';

  @override
  String get tokenConfigured => '已配置 — 客户端必须出示此令牌。';

  @override
  String get topic => '主题';

  @override
  String get topicHint => '例如 Tech Stack、Design System';

  @override
  String get totalRuns => '总运行次数';

  @override
  String trackingParamsCount(int count) {
    return '$count 个跟踪参数';
  }

  @override
  String get typeCommandOrSearch => '输入命令或搜索…';

  @override
  String get typography => '字体排印';

  @override
  String get unavailable => '不可用';

  @override
  String get unifiedDiff => '统一 diff';

  @override
  String get unknownAuthor => '未知';

  @override
  String get unnamedAgent => '未命名智能体';

  @override
  String get updateKey => '更新密钥';

  @override
  String get updateLabel => '更新';

  @override
  String get updateToken => '更新令牌';

  @override
  String updatedDaysAgo(int count) {
    return '$count 天前更新';
  }

  @override
  String updatedHoursAgo(int count) {
    return '$count 小时前更新';
  }

  @override
  String get updatedJustNow => '刚刚更新';

  @override
  String updatedMinutesAgo(int count) {
    return '$count 分钟前更新';
  }

  @override
  String get useSandbox => '使用沙箱';

  @override
  String get useWorkspaceDefault => '使用工作区默认值';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      '留空则使用应用默认 User-Agent。部分网站会拦截非浏览器 User-Agent。';

  @override
  String get usingSystemDefaultMicrophone => '正在使用系统默认麦克风。';

  @override
  String get viewLabel => '查看';

  @override
  String get viewLogs => '查看日志';

  @override
  String voiceInstallFailed(String error) {
    return '安装失败：$error';
  }

  @override
  String get voiceModelNotInstalled => '未安装。需一次性下载约 200 MB；之后完全在设备上运行。';

  @override
  String get voiceModelNotInstalledLabel => '未安装语音模型。';

  @override
  String get voiceRedownloadBody =>
      '现有模型文件将被删除，并重新下载约 200 MB 的压缩包。下载完成前语音转写不可用。';

  @override
  String get voiceRemoveBody => '语音转写将被禁用，直至你重新安装。可随时再次安装。';

  @override
  String get voiceTranscription => '语音转写';

  @override
  String get weakIsolationDescription => '弱隔离 - 仅命名空间边界，无内核边界。';

  @override
  String get whenOffNoDefaultRoute => '关闭时，沙箱启动时没有默认路由。';

  @override
  String get whenOffServerStaysStopped => '关闭时，服务器将保持停止，直至你启动它。';

  @override
  String get speechModel => '语音模型';

  @override
  String get speechModelHint => '用于会议转写和编辑器麦克风。';

  @override
  String get voiceModelInstalled => '已安装。为会议转写和编辑器麦克风按钮提供支持。';

  @override
  String get meetingMicSilentWarning => '你的麦克风可能已静音 — 其他人在说话，但麦克风没有收到任何声音。';

  @override
  String get meetingSummaryPrivacyNotice =>
      '录音和转写仅保存在本机。摘要由智能体撰写，若使用云端模型，转写内容和笔记会发送给该提供商。';

  @override
  String get meetingTemplates => '会议笔记模板';

  @override
  String get meetingTemplatesHint => '为某类会议定制 AI 摘要。当前模板会应用于新建和重新生成的摘要。';

  @override
  String get meetingTemplateActive => '当前模板';

  @override
  String get meetingTemplateAdd => '添加模板';

  @override
  String get meetingTemplateNewTitle => '新建模板';

  @override
  String get meetingTemplateEditTitle => '编辑模板';

  @override
  String get meetingTemplateNameLabel => '名称';

  @override
  String get meetingTemplateNameHint => '例如：冲刺评审';

  @override
  String get meetingTemplateInstructionsLabel => '说明';

  @override
  String get meetingTemplateInstructionsHint => 'AI 应如何组织并突出这些笔记？';

  @override
  String get workingMemory => '工作记忆';

  @override
  String get workspaceName => '工作区名称';

  @override
  String get workspaceScopedSkills => '附加到智能体的工作区范围技能文件。';

  @override
  String get workspaces => '工作区';

  @override
  String get writePrivateNotes => '写下私人笔记、观察、计划……';

  @override
  String get writeSkillContent => '在此编写技能内容（Markdown）…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 年前',
      one: '1 年前',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => '昨天';

  @override
  String get focusModeStart => '开始专注时段';

  @override
  String get focusModeConfigTitle => '开始专注时段';

  @override
  String get focusModeGoalLabel => '目标';

  @override
  String get focusModeGoalHint => '你在做什么？';

  @override
  String get focusModeDurationLabel => '时长';

  @override
  String get focusModeBlockNotifications => '屏蔽通知';

  @override
  String get focusModeStartButton => '开始';

  @override
  String get focusModeFloat => '最小化到栏';

  @override
  String get focusModeActiveTooltip => '专注模式进行中 — 点按结束';

  @override
  String get dismiss => '忽略';

  @override
  String get acceptAndResolve => '接受并解决';

  @override
  String reviewFatigueWarning(int minutes) {
    return '你已连续审查 $minutes 分钟 — 研究表明超过 60 分钟后审查质量可能下降。建议休息一下。';
  }

  @override
  String get notificationSound => '通知声音';

  @override
  String get notificationSoundDescription => '显示通知时播放的声音。';

  @override
  String get notificationSoundNone => '无';

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
  String get notificationSoundMigrosSoft => 'Migros（柔和）';

  @override
  String get notificationSoundMigrosHard => 'Migros（强烈）';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => '测试';

  @override
  String get notificationVolume => '音量';

  @override
  String noPrsByUserInWorkspace(String login) {
    return '此工作区没有 @$login 的 PR';
  }

  @override
  String get usersLabel => '用户';

  @override
  String get mergePullRequest => '合并 pull request';

  @override
  String get forceMergePullRequest => '强制合并 pull request';

  @override
  String get closePullRequest => '关闭 pull request';

  @override
  String get closePullRequestConfirm => '确定要关闭此 pull request 吗？';

  @override
  String get stackedPullRequests => '堆叠的 pull request';

  @override
  String partOfStack(int position, int total) {
    return '属于堆叠（第 $position 个，共 $total 个）';
  }

  @override
  String get createStack => '创建堆叠';

  @override
  String get createStackDialogTitle => '创建 pull request 堆叠';

  @override
  String createStackDialogBody(int count) {
    return '这 $count 个 pull request 将自下而上堆叠：';
  }

  @override
  String get createStackInvalidSelection => '请从同一仓库至少选择两个 pull request 以创建堆叠';

  @override
  String get createStackNotAChain =>
      '所选 pull request 未形成链路：每个 pull request 的基准分支必须是上一个的 head 分支';

  @override
  String get createStackAlreadyStacked => '所选 pull request 中已有一个或多个位于堆叠中';

  @override
  String get stackCreated => '已创建堆叠';

  @override
  String get stackCreationFailed => '无法创建堆叠';

  @override
  String get squashAndMerge => '压缩并合并';

  @override
  String get createMergeCommit => '创建合并提交';

  @override
  String get rebaseAndMerge => '变基并合并';

  @override
  String get commitTitle => '提交标题';

  @override
  String get commitDescription => '提交说明';

  @override
  String get pullRequestMerged => '已合并 pull request';

  @override
  String get pullRequestClosed => '已关闭 pull request';

  @override
  String failedToMergePr(String error) {
    return '合并失败：$error';
  }

  @override
  String failedToClosePr(String error) {
    return '关闭失败：$error';
  }

  @override
  String get markReadyForReview => '可供审阅';

  @override
  String get markReadyForReviewConfirm =>
      '此 pull request 将退出草稿。将通知审阅者，必需检查开始作为合并门槛，监视就绪 pull request 的自动化也会运行。';

  @override
  String get convertToDraft => '转为草稿';

  @override
  String get convertToDraftConfirm =>
      '此 pull request 将重新变为草稿。待处理的审阅请求将被取消，在再次标记为可审阅之前无法合并。';

  @override
  String get pullRequestMarkedReady => '已将 pull request 标记为可审阅';

  @override
  String get pullRequestConvertedToDraft => '已将 pull request 转为草稿';

  @override
  String failedToMarkPrReady(String error) {
    return '标记为可审阅失败：$error';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return '转为草稿失败：$error';
  }

  @override
  String get checksFailing => '检查未通过';

  @override
  String get reviewsPending => '部分审阅待完成';

  @override
  String get mergeConflictsWithBase => '此分支存在必须解决的冲突';

  @override
  String get branchOutOfDateWithBase => '此分支落后于基准分支';

  @override
  String get mergeBlockedByBranchProtection => '分支保护阻止了此次合并';

  @override
  String get confirm => '确认';

  @override
  String get trustedSitesSectionTitle => '受信任站点';

  @override
  String get trustedSitesEmpty => '暂无受信任站点。添加域名即可对其停用拦截。';

  @override
  String get addTrustedSite => '添加受信任站点';

  @override
  String get removeTrustedSite => '移除';

  @override
  String get disableBlockingForThisSite => '对此站点停用拦截';

  @override
  String get enableBlockingForThisSite => '对此站点启用拦截';

  @override
  String get enterDomainHint => '例如 example.com';

  @override
  String get invalidDomain => '请输入有效域名（例如 example.com）';

  @override
  String get pageLoadTimedOut => '页面加载超时。请重新加载或在浏览器中打开。';

  @override
  String get pipelinesScreenTitle => '流水线';

  @override
  String get pipelinesScreenSubtitle => '声明式多步骤智能体工作流';

  @override
  String get pipelinesRunPipeline => '运行流水线';

  @override
  String get pipelineRunLauncherTitle => '运行流水线';

  @override
  String get pipelineRunSubtitle => '选择一条流水线并填写输入，即可开始运行。';

  @override
  String get pipelineRunNoInputsBadge => '无输入';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个输入',
      one: '1 个输入',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => '此流水线无需输入。';

  @override
  String get pipelineRunSubmit => '运行流水线';

  @override
  String get pipelineRunCouldNotStart => '无法开始运行。';

  @override
  String pipelineRunStarted(String name) {
    return '已开始运行 $name';
  }

  @override
  String get pipelineRunEmptyTitle => '暂无可以运行的流水线';

  @override
  String get pipelineRunEmptyHint => '启用一条流水线，并在其编辑器中打开手动运行，即可在此启动。';

  @override
  String get pipelineRunManageTemplates => '管理流水线';

  @override
  String get pipelineRunSettingsTitle => '手动运行';

  @override
  String get pipelineRunSettingsAllow => '允许手动运行';

  @override
  String get pipelineRunSettingsAllowHelp => '在运行页显示此流水线，以便手动启动。';

  @override
  String get pipelineRunSettingsConcurrencyTitle => '并发';

  @override
  String get pipelineRunSettingsMaxParallel => '最大并行运行数';

  @override
  String get pipelineRunSettingsMaxParallelHelp => '留空表示不限制。超出的运行会排队，有空位后再启动。';

  @override
  String get pipelineRunSettingsMaxParallelHint => '不限制';

  @override
  String get pipelineRunSettingsMaxParallelInvalid => '请输入大于等于 1 的整数，或留空表示不限制。';

  @override
  String get pipelineRunSettingsInputsTitle => '输入';

  @override
  String get pipelineRunSettingsAddInput => '添加输入';

  @override
  String get pipelineRunSettingsNoInputs => '暂无输入。';

  @override
  String get pipelineInputEditTitle => '输入字段';

  @override
  String get pipelineInputKeyLabel => '键';

  @override
  String get pipelineInputKeyHelp => '值存储所用的状态键（例如 repo_full_name）。';

  @override
  String get pipelineInputLabelLabel => '标签';

  @override
  String get pipelineInputTypeLabel => '类型';

  @override
  String get pipelineInputOptionsLabel => '选项（逗号分隔）';

  @override
  String get pipelineInputDefaultLabel => '默认值';

  @override
  String get pipelineInputPlaceholderLabel => '占位符';

  @override
  String get pipelineInputHelpLabel => '帮助文本';

  @override
  String get pipelineInputRequiredLabel => '必填';

  @override
  String get pipelineInputTypeText => '文本';

  @override
  String get pipelineInputTypeMultiline => '多行文本';

  @override
  String get pipelineInputTypeNumber => '数字';

  @override
  String get pipelineInputTypeBoolean => '开关';

  @override
  String get pipelineInputTypeSelect => '下拉选择';

  @override
  String get pipelinesEmpty => '暂无流水线运行记录';

  @override
  String get pipelinesEmptyHint => '点击「运行流水线」即可开始。';

  @override
  String get pipelinesNoSteps => '暂无步骤记录';

  @override
  String get pipelinesNoActiveWorkspace => '选择工作区以查看其流水线';

  @override
  String pipelinesLoadError(String error) {
    return '加载流水线失败：$error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return '启动流水线失败：$error';
  }

  @override
  String get pipelineStatusPending => '等待中';

  @override
  String get pipelineStatusQueued => '排队中';

  @override
  String get pipelineStatusRunning => '运行中';

  @override
  String get pipelineStatusSuspended => '已挂起';

  @override
  String get pipelineStatusCompleted => '已完成';

  @override
  String get pipelineStatusFailed => '失败';

  @override
  String get pipelineStatusCancelled => '已取消';

  @override
  String get pipelineStatusSkipped => '已跳过';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed/$total 个步骤';
  }

  @override
  String get pipelineWaterfallTimeline => '时间线';

  @override
  String pipelineWaterfallActive(String duration) {
    return '进行中 $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return '空闲 $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip => '未计入进行中总时长：运行已停止，或在步骤之间等待。';

  @override
  String get pipelineStepStarted => '开始';

  @override
  String get pipelineStepFinished => '结束';

  @override
  String get pipelineStepDurationLabel => '时长';

  @override
  String get pipelineStepBranch => '分支';

  @override
  String get pipelineStepViewConversation => '查看对话';

  @override
  String get pipelineStepError => '错误';

  @override
  String get pipelineStepInput => '输入';

  @override
  String get pipelineStepOutput => '输出';

  @override
  String get pipelineStepNotExecuted => '尚未执行';

  @override
  String pipelineRunFailedAtStep(String step) {
    return '失败于 $step';
  }

  @override
  String get pipelineRunTriggerManual => '手动';

  @override
  String get pipelineStepSkippedReason => '已跳过';

  @override
  String get pipelineStepPriorAttempts => '先前尝试';

  @override
  String get pipelineStepAttemptLabel => '尝试';

  @override
  String pipelineStepAttemptN(int number) {
    return '第 $number 次尝试';
  }

  @override
  String get pipelineStepAttemptInterrupted => '已中断';

  @override
  String get pipelineRunColumnPipeline => '流水线';

  @override
  String get pipelineRunColumnDuration => '时长';

  @override
  String get pipelineRunQueueNext => '下一个';

  @override
  String pipelineRunQueuePosition(int position) {
    return '队列第 $position 位';
  }

  @override
  String get pipelineRunColumnStarted => '开始时间';

  @override
  String get pipelineRunHistory => '运行历史';

  @override
  String get pipelineRunHistoryEmpty => '暂无其他运行';

  @override
  String pipelineRunRerunAgo(String time) {
    return '重新运行 $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return '第 $number 次尝试';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return '首次开始 $time';
  }

  @override
  String get pipelineRunFilterAll => '全部';

  @override
  String get pipelineRunFilterEmpty => '没有符合此筛选的运行';

  @override
  String get relativeJustNow => '刚刚';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟前',
      one: '1 分钟前',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小时前',
      one: '1 小时前',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天前',
      one: '1 天前',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => '团队';

  @override
  String get teamsAddTeam => '添加团队';

  @override
  String get teamsLoadError => '无法加载团队';

  @override
  String get teamsEmptyTitle => '暂无团队';

  @override
  String get teamsEmptyDescription => '将智能体编入团队，分配给团队的工作会先交给负责人，再由其分派。';

  @override
  String get teamCreateTitle => '新建团队';

  @override
  String get teamEditTitle => '编辑团队';

  @override
  String get teamNameLabel => '团队名称';

  @override
  String get teamNameHint => '例如 Frontend';

  @override
  String get teamDescriptionLabel => '描述';

  @override
  String get teamDescriptionHint => '该团队负责的事项';

  @override
  String get teamLeaderLabel => '负责人';

  @override
  String get teamLeaderHelp => '接收分配给团队的工作，并分派给最合适成员的协调者。';

  @override
  String get teamNoLeader => '无负责人';

  @override
  String get teamInstructionsLabel => '运作说明';

  @override
  String get teamInstructionsHelp => '会追加到负责人简报中 — 团队约定、升级规则、语气。';

  @override
  String get teamInstructionsHint => '可选';

  @override
  String get teamSaved => '团队已保存';

  @override
  String get teamMembersError => '无法加载成员';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 名成员',
      one: '1 名成员',
      zero: '暂无成员',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => '添加成员';

  @override
  String get teamAddMemberTitle => '添加成员';

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
  String get teamNoAgentsToAdd => '所有智能体都已在此团队中。';

  @override
  String get teamRemoveMember => '从团队中移除';

  @override
  String get teamLeaderBadge => '负责人';

  @override
  String get teamUnknownAgent => '未知智能体';

  @override
  String get teamMembersEmpty => '暂无成员';

  @override
  String get teamMembersEmptyDescription => '添加智能体，以便负责人可以委派任务。';

  @override
  String get teamSelectPrompt => '选择团队';

  @override
  String get teamSelectPromptDescription => '从列表中选择团队，或新建一个。';

  @override
  String get teamDeleteTitle => '删除团队？';

  @override
  String teamDeleteBody(String name) {
    return '$name 将被删除。其中的智能体不受影响。';
  }

  @override
  String get teamHasLeaderTooltip => '已有负责人';

  @override
  String get pipelineTemplatesNav => '流水线模板';

  @override
  String get pipelineTemplatesTitle => '流水线模板';

  @override
  String get pipelineTemplatesSubtitle => '用于编排智能体流水线的拖放编辑器。';

  @override
  String get pipelineTemplatesNew => '新建模板';

  @override
  String get pipelineTemplatesEmpty => '暂无流水线模板。创建一个以开始使用。';

  @override
  String get pipelineTemplateBuiltInBadge => '内置';

  @override
  String get pipelineTemplateDeleteConfirmTitle => '删除模板？';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return '删除流水线模板 $name？此操作无法撤销。';
  }

  @override
  String get pipelineTemplateEditorSubtitle => '从侧边栏将节点类型拖到画布上，再将它们连线。';

  @override
  String get unsavedChanges => '未保存的更改';

  @override
  String get nodeLibraryTitle => '节点库';

  @override
  String get nodeLibraryHint => '将任意条目拖到画布上即可添加节点。';

  @override
  String get editorEmptyCanvas => '从库中拖入节点以开始。';

  @override
  String get pipelineWhenThisHappens => '当发生以下情况';

  @override
  String get pipelineDoThis => '执行此操作';

  @override
  String get pipelineAddStep => '添加步骤';

  @override
  String get pipelineTidyUp => '整理布局';

  @override
  String get pipelineEditorHint => '拖动步骤以排列 · 拖动控制点以连接';

  @override
  String get pipelineRemoveConnection => '移除连接';

  @override
  String get pipelineDragToConnect => '拖动以连接';

  @override
  String get pipelineNewDefaultName => '新建流水线';

  @override
  String get nodeCategoryTriggers => '触发器';

  @override
  String get triggerEventWebhook => 'Webhook';

  @override
  String get pipelineAddTrigger => '添加触发器';

  @override
  String get pipelineOnEvent => '按事件';

  @override
  String get nodeConfigTitle => '节点配置';

  @override
  String get nodeConfigKind => '类型';

  @override
  String get nodeConfigLabel => '标签';

  @override
  String get nodeConfigAgent => '智能体';

  @override
  String get nodeConfigAgentHint => '选择智能体…';

  @override
  String get nodeConfigInputKeys => '输入键（逗号分隔）';

  @override
  String get nodeConfigInputKeysHelp => '此节点消费的状态键。用于在提示词中替换占位符。';

  @override
  String get nodeConfigRepos => '要克隆的仓库';

  @override
  String get nodeConfigReposHelp =>
      '此节点开始对话时会克隆并建立代码索引的仓库。选择全部仓库则会克隆所有仓库（默认行为）。';

  @override
  String get nodeConfigRepoBranchHint => '分支（默认）';

  @override
  String get nodeConfigRepoBranchHelp =>
      '每次检出从此分支切出。留空则使用仓库自身的默认分支 — 工作树仍会有自己的分支，智能体提交的内容不会落到该分支上。';

  @override
  String nodeConfigReposDynamic(String entries) {
    return '保留的动态条目：$entries';
  }

  @override
  String get nodeConfigCreateConversation => '在其中打开对话';

  @override
  String get nodeConfigCreateConversationHelp =>
      '后续有多个智能体节点时请关闭——每个节点会打开自己的命名流。后续只有一个智能体节点时请开启，以免房间旁出现未命名对话。';

  @override
  String get nodeConfigConversationTitle => '对话名称';

  @override
  String get nodeConfigConversationTitleHelp =>
      '给下游智能体节点相同名称，两者就会在同一条流中工作。默认为节点标签。';

  @override
  String get nodeConfigSpaceName => '空间名称';

  @override
  String get nodeConfigSpaceNameHelp => '此节点打开的房间名称。支持与提示相同的状态占位符。留空则使用节点标签。';

  @override
  String get nodeConfigSpaceNameHint => '评审 pr_number';

  @override
  String get nodeConfigStreamTitle => '对话名称';

  @override
  String get nodeConfigStreamTitleHelp =>
      '此节点的智能体在房间内工作所用的命名流。支持与提示相同的状态占位符。留空则本轮进入房间的常驻对话，扇出会在其中交错各智能体。';

  @override
  String get nodeConfigConversationTitleHint => '架构分析';

  @override
  String get nodeConfigOutputKey => '输出键';

  @override
  String get nodeConfigPrompt => '提示模板';

  @override
  String get nodeConfigPromptHelp => '使用双花括号占位符，在运行时从状态中取值。';

  @override
  String get nodeConfigScript => 'Bash 脚本';

  @override
  String get nodeConfigScriptHelp =>
      '通过 bash -c 运行。已设置 GITHUB_TOKEN。执行前会替换占位符。';

  @override
  String get nodeConfigRouteKeys => '路由键';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return '来自 $source 的路由键';
  }

  @override
  String get conditionSectionTitle => '条件';

  @override
  String get conditionMode => '模式';

  @override
  String get conditionModeFilesAny => '文件存在 — 任一';

  @override
  String get conditionModeFilesAll => '文件存在 — 全部';

  @override
  String get conditionModeComparison => '比较';

  @override
  String get conditionModeSwitch => '分支';

  @override
  String get conditionFilePaths => '文件路径';

  @override
  String get conditionFilePathsAnyHelp => '每行一条路径，相对于基准目录。任一存在即路由为真。';

  @override
  String get conditionFilePathsAllHelp => '每行一条路径，相对于基准目录。全部存在才路由为真。';

  @override
  String get conditionBaseKey => '基准目录键';

  @override
  String get conditionBaseKeyHelp => '存放解析路径所用目录的状态键（默认为 repo_local_path）。';

  @override
  String get conditionRecursive => '搜索子目录';

  @override
  String get conditionNegate => '取反：缺失时路由为真';

  @override
  String get conditionLeft => '左值';

  @override
  String get conditionOperator => '运算符';

  @override
  String get conditionRight => '右值';

  @override
  String get conditionSwitchKey => '按状态键分支';

  @override
  String get conditionCases => '分支（逗号分隔）';

  @override
  String get conditionCasesHelp => '按顺序与该值匹配的路由键。';

  @override
  String get conditionDefaultCase => '默认分支';

  @override
  String get triggerManualHelp => '显示在运行页，可手动启动。';

  @override
  String get triggerKindSchedule => '按计划';

  @override
  String get triggerScheduleExprLabel => '计划（cron 或 every:seconds）';

  @override
  String get triggerTimezoneLabel => '时区（可选）';

  @override
  String get triggerCatchUpLabel => '错过运行时';

  @override
  String get triggerCatchUpRunOnce => '运行一次';

  @override
  String get triggerCatchUpSkip => '跳过';

  @override
  String get syncHealthTitle => '同步健康状况';

  @override
  String get syncHealthNoConfigs => '暂无同步连接';

  @override
  String get syncHealthNeverSynced => '从未同步';

  @override
  String get syncOutcomeOk => '已同步';

  @override
  String get syncOutcomeFailed => '失败';

  @override
  String get syncOutcomeSkipped => '已跳过';

  @override
  String syncHealthFailedStreak(int count) {
    return '连续失败 $count 次';
  }

  @override
  String get triggerWebhookHelp =>
      '会生成带签名的 webhook URL。外部系统向其发送 POST 请求即可启动此流水线。';

  @override
  String get triggerWebhookPathLabel => 'Webhook 路径';

  @override
  String get triggerMatchStatusLabel => '仅当状态为';

  @override
  String get triggerSummaryNone => '无触发器';

  @override
  String triggerEverySeconds(int seconds) {
    return '每 $seconds 秒';
  }

  @override
  String get triggerEventManual => '手动运行';

  @override
  String get triggerEventSchedule => '定时';

  @override
  String get triggerEventPrStatusChanged => 'PR 状态已更改';

  @override
  String get triggerEventExternalPr => '外部 PR 已打开';

  @override
  String get triggerEventPrPublished => 'PR 已发布';

  @override
  String get triggerEventPrMerged => 'PR 已合并';

  @override
  String get triggerEventRepoAdded => '仓库已添加';

  @override
  String get triggerEventCodeGraphWatch => '文件变更';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个变更文件',
      one: '1 个变更文件',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '+$count 个';
  }

  @override
  String get pipelineRunCauseRescan => '磁盘上有变更';

  @override
  String get pipelineRunCauseInitial => '此检出的首次索引';

  @override
  String get triggerEventMessageReceived => '收到消息';

  @override
  String get triggerEventTicketCompleted => '工单已完成';

  @override
  String get triggerEventTicketFailed => '工单失败';

  @override
  String get triggerEventTicketCancelled => '工单已取消';

  @override
  String get triggerEventBudgetCrossed => '已超过预算阈值';

  @override
  String get nodeLibrarySearchHint => '搜索节点';

  @override
  String get nodeLibraryNoMatches => '无匹配节点';

  @override
  String get nodeCategoryFlow => '流程与逻辑';

  @override
  String get nodeCategoryPr => 'PR 审查';

  @override
  String get nodeCategoryAgents => '智能体';

  @override
  String get nodeCategoryMessaging => '消息';

  @override
  String get nodeCategoryCode => '代码';

  @override
  String get triggerDisabledTag => '关闭';

  @override
  String get pipelineInputTypeRepo => '仓库';

  @override
  String get pipelineRunNoRepos => '此工作区尚无仓库。';

  @override
  String get allowTicketingApi => '允许工单 API 调用';

  @override
  String get ticketingApiKey => '工单 API 密钥';

  @override
  String get ticketingApiKeySubtitle => '将工单服务商的 API 密钥注入沙箱。';

  @override
  String get ticketingProvider => '工单服务商';

  @override
  String get connectGitHubAndTicketing =>
      '连接代码托管平台，以便 Control Center 读取你的 pull request、议题和审查。也可选连接工单服务商。凭据保存在你的服务器上，不会保存在本机。';

  @override
  String get triggerEventTicketAssigned => '工单已分配';

  @override
  String get triggerEventTicketCreated => '工单已创建';

  @override
  String get triggerEventTicketStatusChanged => '工单状态已更改';

  @override
  String get triggerEventMeetingRecordingStopped => '会议录制已停止';

  @override
  String get triggerEventSkillUpdated => '技能已更新';

  @override
  String get triggerEventSpaceDeleted => '空间已删除';

  @override
  String get triggerExternalPrHelp => '在代码托管平台上打开的拉取请求，不是从 Control Center 打开的。';

  @override
  String get triggerPrPublishedHelp => '从 Control Center 或由智能体打开的拉取请求。';

  @override
  String get triggerPrStatusChangedHelp => '已合并、关闭、打开、重新打开或批准。可在检查器中按状态筛选。';

  @override
  String get triggerPrMergedHelp => '仅在拉取请求合并时触发，关闭或重新打开时不会。';

  @override
  String get triggerRepoAddedHelp => '将仓库关联到此工作区。';

  @override
  String get triggerCodeGraphWatchHelp => '已关联仓库中的文件在磁盘上发生变化。';

  @override
  String get triggerMessageReceivedHelp => '空间中收到新消息。';

  @override
  String get triggerTicketCreatedHelp => '在此工作区中创建工单。';

  @override
  String get triggerTicketStatusChangedHelp => '工单在状态之间切换。';

  @override
  String get triggerTicketCompletedHelp => '工单成功完成。';

  @override
  String get triggerTicketFailedHelp => '智能体运行失败，工单被标记为失败。';

  @override
  String get triggerTicketCancelledHelp => '工单被取消，不会继续。';

  @override
  String get triggerBudgetCrossedHelp => '工作区或智能体的支出上限被突破。';

  @override
  String get triggerTicketAssignedHelp => '工单被分配给人员、智能体或团队。';

  @override
  String get triggerMeetingRecordingStoppedHelp => '会议录音结束。';

  @override
  String get triggerSkillUpdatedHelp => '技能被安装或更新。';

  @override
  String get triggerSpaceDeletedHelp => '对话空间被删除。';

  @override
  String get navTickets => '工单';

  @override
  String get ticketsTitle => '工单';

  @override
  String get newTicket => '新建工单';

  @override
  String get noTicketsYet => '暂无工单';

  @override
  String get addCollaborator => '添加协作者';

  @override
  String get noCollaborators => '暂无协作者';

  @override
  String get linkedPullRequests => '关联的 pull request';

  @override
  String get noLinkedPullRequests => '暂无关联的 pull request';

  @override
  String get stopAgent => '停止智能体';

  @override
  String get ticketProperties => '属性';

  @override
  String get ticketTabIssue => 'Issue';

  @override
  String get ticketSelectPrompt => '选择工单以查看详情';

  @override
  String get unassigned => '未分配';

  @override
  String get ticketStatusBacklog => '待办池';

  @override
  String get ticketStatusOpen => '待办';

  @override
  String get ticketStatusInProgress => '进行中';

  @override
  String get ticketStatusInReview => '审核中';

  @override
  String get ticketStatusDone => '已完成';

  @override
  String get ticketStatusBlocked => '已阻塞';

  @override
  String get ticketStatusFailed => '失败';

  @override
  String get ticketStatusCancelled => '已取消';

  @override
  String get notificationTicketAssigned => '工单已分配';

  @override
  String get notificationTicketStatusChanged => '工单状态已更改';

  @override
  String get priority => '优先级';

  @override
  String get status => '状态';

  @override
  String get assignee => '负责人';

  @override
  String get labels => '标签';

  @override
  String get noLabelsYet => '暂无标签';

  @override
  String get clearLabels => '清除标签';

  @override
  String get pipelineStepAgentActivity => '智能体活动';

  @override
  String get runStatusCompleted => '已完成';

  @override
  String get runStatusQueued => '排队中';

  @override
  String get ticketDescription => '描述';

  @override
  String get ticketPriorityNone => '无';

  @override
  String get ticketPriorityUrgent => '紧急';

  @override
  String get ticketPriorityHigh => '高';

  @override
  String get ticketPriorityMedium => '中';

  @override
  String get ticketPriorityLow => '低';

  @override
  String get ticketViewList => '列表';

  @override
  String get ticketViewBoard => '看板';

  @override
  String get ticketTitlePlaceholder => 'Issue 标题';

  @override
  String get ticketDescriptionPlaceholder => '添加描述…';

  @override
  String get createMore => '继续创建';

  @override
  String selectedCount(int count) {
    return '已选择 $count 项';
  }

  @override
  String get clearSelection => '清除选择';

  @override
  String get bulkDeleteTitle => '删除工单';

  @override
  String bulkDeleteMessage(int count) {
    return '删除选中的 $count 个工单？此操作无法撤销。';
  }

  @override
  String get assignTo => '分配给…';

  @override
  String get sectionMembers => '成员';

  @override
  String get sectionAgents => '智能体';

  @override
  String get sidebarGroupWorkspace => '工作区';

  @override
  String get notificationsTitle => '通知';

  @override
  String get notificationsTooltip => '通知';

  @override
  String get notificationsEmpty => '暂无新通知';

  @override
  String notificationsUnreadCount(int count) {
    return '$count 条未读';
  }

  @override
  String get notificationsMarkRead => '标为已读';

  @override
  String get notificationsMarkUnread => '标为未读';

  @override
  String get notificationsEntryActions => '通知操作';

  @override
  String get markAllRead => '全部标为已读';

  @override
  String get teamsNav => '团队';

  @override
  String get noWorkspace => '无工作区';

  @override
  String get selectWorkspace => '选择工作区';

  @override
  String get navMemory => '记忆';

  @override
  String get memoryTabFacts => '事实';

  @override
  String get memoryTabPolicies => '策略';

  @override
  String get memoryGraphShowFacts => '显示事实';

  @override
  String get memoryGraphHideFacts => '隐藏事实';

  @override
  String get memoryGraphExpandAll => '展开全部事实';

  @override
  String get memoryGraphCollapseAll => '折叠全部事实';

  @override
  String get memoryTabGraph => '知识图谱';

  @override
  String get memoryNoWorkspace => '选择工作区以查看其记忆。';

  @override
  String get searchArticles => '搜索文章';

  @override
  String get filterAll => '全部';

  @override
  String get filterUnread => '未读';

  @override
  String get filterSaved => '已保存';

  @override
  String get saveArticle => '保存文章';

  @override
  String get removeFromSaved => '从已保存中移除';

  @override
  String get filterBySource => '按来源筛选';

  @override
  String get viewAsList => '列表视图';

  @override
  String get viewAsGrid => '网格视图';

  @override
  String get noMatchingArticles => '没有匹配的文章';

  @override
  String get noMatchingArticlesBody => '试试其他搜索词或来源筛选。';

  @override
  String get allCaughtUp => '已全部看完';

  @override
  String get allCaughtUpBody => '暂无未读文章，稍后再来看看。';

  @override
  String get openArticlesInAppDescription => '在内置阅读器中打开链接，而不是默认浏览器。';

  @override
  String get blockAdsTrackersDescription => '从阅读器中打开的文章里去除广告、跟踪器和 Cookie 横幅。';

  @override
  String get agentQuestionHeader => '需要你回答的问题';

  @override
  String get agentQuestionAnsweredLabel => '已回答';

  @override
  String get agentQuestionFreeformHint => '输入你的回答…';

  @override
  String agentQuestionProgress(int index, int count) {
    return '问题 $index / $count';
  }

  @override
  String get agentQuestionSkip => '跳过';

  @override
  String get agentQuestionSkippedLabel => '已跳过';

  @override
  String get agentQuestionFreeformOptionHint => '用你自己的话描述…';

  @override
  String get reviewRequested => '已请求评审';

  @override
  String get connectGitHubHint =>
      '登录 GitHub，或在「设置 → 工作区 → 个人资料与身份 → 代码托管」中添加令牌';

  @override
  String get connectGitHubToLoadPrs => '连接 GitHub 以加载 pull request';

  @override
  String get noRepositoriesConfigured => '未配置仓库';

  @override
  String openedAgo(String age) {
    return '打开于 $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author 打开了此 pull request';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个提交',
      one: '1 个提交',
    );
    return '$author 打开了此 pull request，包含 $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor 请求 $reviewers 进行评审';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor 取消了对 $reviewers 的评审请求';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor 请求 $requested 审阅，并移除了对 $removed 的审阅请求';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '标签',
      one: '标签',
    );
    return '$actor 添加了 $labels $_temp0';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '标签',
      one: '标签',
    );
    return '$actor 移除了 $labels $_temp0';
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
      other: '标签',
      one: '标签',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: '标签',
      one: '标签',
    );
    return '$actor 添加了 $added $_temp0，并移除了 $removed $_temp1';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author 提交了';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个提交',
      one: '1 个提交',
    );
    return '$author 推送了 $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author 批准了这些更改';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author 请求更改';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条代码评论',
      one: '1 条代码评论',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author 进行了审阅';
  }

  @override
  String get prTimelineSomeone => '某人';

  @override
  String get prTimelineBotBadge => '机器人';

  @override
  String updatedAgo(String age) {
    return '更新于 $age';
  }

  @override
  String get checksPassing => '检查已通过';

  @override
  String get checksRunning => '检查运行中';

  @override
  String get needsYourReview => '需要你审阅';

  @override
  String get checks => '检查';

  @override
  String get noReviewersAssigned => '未指定审阅者';

  @override
  String get noAssignees => '未指定负责人';

  @override
  String get loadingEllipsis => '加载中…';

  @override
  String get loadingChecks => '正在加载检查…';

  @override
  String get noChecksYet => '尚未运行检查';

  @override
  String get noChangesToReview => '没有要审查的更改';

  @override
  String checksFailingCount(int count) {
    return '$count 项失败';
  }

  @override
  String get showMore => '显示更多';

  @override
  String get showLess => '收起';

  @override
  String get backToPullRequests => '返回 pull requests';

  @override
  String get pullRequestNotFound => '未找到 pull request';

  @override
  String get pullRequestNotFoundBody => '可能已合并、关闭或被移动。';

  @override
  String get couldntLoadPullRequest => '无法加载此 pull request';

  @override
  String get showDetails => '显示详情';

  @override
  String get noDescriptionProvided => '未提供描述。';

  @override
  String get factsHint => '智能体学习后，事实将显示在此处。';

  @override
  String get noFactsMatch => '没有与搜索匹配的事实';

  @override
  String get memoryLoadError => '无法加载记忆';

  @override
  String get sortRecent => '最近';

  @override
  String get sortConfidence => '置信度';

  @override
  String get confidenceTooltip => '智能体对此事实为真的把握程度，范围 0% 到 100%。';

  @override
  String get supersededTooltip => '更新的事实已替换此项。';

  @override
  String get domain => '领域';

  @override
  String get fitToView => '适应视图';

  @override
  String get project => '项目';

  @override
  String get newProject => '新建项目';

  @override
  String get editProject => '编辑项目';

  @override
  String get deleteProject => '删除项目';

  @override
  String get noProject => '无项目';

  @override
  String get allTickets => '全部工单';

  @override
  String get projectNamePlaceholder => '项目名称';

  @override
  String get projectDescriptionPlaceholder => '描述（可选）';

  @override
  String get projectColorLabel => '颜色';

  @override
  String get noProjectsYet => '暂无项目';

  @override
  String get projectTicketsEmpty => '此项目暂无工单';

  @override
  String get createProject => '创建项目';

  @override
  String projectProgress(int done, int total) {
    return '$done / $total 已完成';
  }

  @override
  String deleteProjectConfirm(String name) {
    return '删除“$name”？其工单将保留并从项目中移除。';
  }

  @override
  String get projectStatusActive => '进行中';

  @override
  String get projectStatusCompleted => '已完成';

  @override
  String get projectStatusArchived => '已归档';

  @override
  String get markProjectCompleted => '标记为已完成';

  @override
  String get markProjectActive => '标记为进行中';

  @override
  String get archiveProject => '归档';

  @override
  String get restoreProject => '恢复';

  @override
  String get relations => '关联';

  @override
  String get relateTo => '关联到';

  @override
  String get relationSubIssueOf => '子工单属于…';

  @override
  String get relationParentOf => '父工单为…';

  @override
  String get relationBlockedBy => '被阻塞于…';

  @override
  String get relationBlocking => '阻塞…';

  @override
  String get relationRelatedTo => '关联到…';

  @override
  String get relationDuplicateOf => '重复于…';

  @override
  String get relationGroupParent => '父工单';

  @override
  String get relationGroupSubIssues => '子工单';

  @override
  String get relationGroupBlockedBy => '被阻塞';

  @override
  String get relationGroupBlocking => '阻塞';

  @override
  String get relationGroupRelated => '关联';

  @override
  String get relationGroupDuplicateOf => '重复于';

  @override
  String get relationGroupDuplicatedBy => '被重复';

  @override
  String get copyId => '复制 ID';

  @override
  String get ticketIdCopied => '已复制工单 ID';

  @override
  String get searchTicketsHint => '搜索工单…';

  @override
  String get noMatchingTickets => '没有匹配的工单';

  @override
  String get clearAll => '全部清除';

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs 个 PR',
      one: '1 个 PR',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos 个仓库',
      one: '1 个仓库',
    );
    return '$_temp0 待你审核，涉及 $_temp1';
  }

  @override
  String get manageWorkspacesSubtitle => '重命名工作区并更改其标识 — 在左侧选择一项进行编辑。';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个工作区',
      one: '1 个工作区',
      zero: '暂无工作区',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos 个仓库',
      one: '1 个仓库',
      zero: '暂无仓库',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents 个智能体',
      one: '1 个智能体',
      zero: '0 个智能体',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => '身份';

  @override
  String get uploadImage => '上传图片';

  @override
  String get failedToSaveLogo => '未能保存徽标图片。请确认应用可以读取所选文件。';

  @override
  String get workspaceLogoHint => 'PNG、JPG 或 GIF，最大 2 MB。否则将使用工作区首字母。';

  @override
  String get workspaceNameFieldHelp => '显示在切换器、面包屑和每个界面中。';

  @override
  String get dangerZone => '危险区域';

  @override
  String get deleteThisWorkspace => '删除此工作区';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return '将永久删除 $name 及其仓库连接、智能体和记忆。此操作无法撤销。';
  }

  @override
  String get discard => '丢弃';

  @override
  String discardChangesQuestion(String name) {
    return '丢弃对 $name 的未保存更改？';
  }

  @override
  String get workspaceUpdated => '工作区已更新';

  @override
  String get editTitle => '编辑标题';

  @override
  String get editDescription => '编辑描述';

  @override
  String get addDescription => '添加描述';

  @override
  String get prTitlePlaceholder => '标题';

  @override
  String get prBodyPlaceholder => '填写描述';

  @override
  String get write => '撰写';

  @override
  String get overview => '概览';

  @override
  String get noFilesChanged => '没有文件变更';

  @override
  String get diff => 'Diff';

  @override
  String get preview => '预览';

  @override
  String get imageDiffBefore => '更改前';

  @override
  String get imageDiffAfter => '更改后';

  @override
  String get imageDiffModeTwoUp => '并排';

  @override
  String get imageDiffModeSwipe => '滑动';

  @override
  String get imageDiffModeDifference => '差异';

  @override
  String imageDiffChangedPercent(String percent) {
    return '已更改 $percent%';
  }

  @override
  String get imageDiffPictures => '图片';

  @override
  String get imageDiffSource => '源码';

  @override
  String get imageDiffDeleted => '已删除';

  @override
  String get imageDiffAdded => '已添加';

  @override
  String imageDiffDimensions(int width, int height) {
    return '宽: ${width}px | 高: ${height}px';
  }

  @override
  String get outdated => '过时';

  @override
  String get outdatedComments => '过时评论';

  @override
  String outdatedCountLabel(int count) {
    return '$count 条过时';
  }

  @override
  String get prTemplateLabel => '模板';

  @override
  String get prTemplateDefault => '默认';

  @override
  String get addReviewers => '添加审阅者';

  @override
  String get addAssignees => '添加经办人';

  @override
  String get searchUsers => '搜索人员…';

  @override
  String get searchReviewers => '搜索人员和团队…';

  @override
  String get usersSectionLabel => '人员';

  @override
  String get userStatusBusy => '忙碌';

  @override
  String get teamsSectionLabel => '团队';

  @override
  String get suggestedReviewers => '建议的审阅者';

  @override
  String get noMatchingUsers => '没有匹配的人员';

  @override
  String get noMatchingReviewers => '没有匹配项';

  @override
  String get requiredByCodeOwners => '代码所有者要求';

  @override
  String reviewedOnBehalfOf(String login) {
    return '通过 $login';
  }

  @override
  String get team => '团队';

  @override
  String get markdownBold => '粗体';

  @override
  String get markdownItalic => '斜体';

  @override
  String get markdownHeading => '标题';

  @override
  String get markdownBulletList => '无序列表';

  @override
  String get markdownChecklist => '清单';

  @override
  String get markdownCode => '代码';

  @override
  String get markdownLink => '链接';

  @override
  String get markdownQuote => '引用';

  @override
  String get markdownSupported => '支持 Markdown';

  @override
  String get markdownAttachImages => '点击添加图片';

  @override
  String failedToUpdateTitle(String error) {
    return '无法更新标题：$error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return '无法更新描述：$error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return '无法更新审阅者：$error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return '无法更新经办人：$error';
  }

  @override
  String get discardChangesConfirm => '放弃更改？';

  @override
  String get newPr => '新建 PR';

  @override
  String get openPullRequest => '打开 pull request';

  @override
  String get composePrSubtitle => '从你已推送的分支开始 — 不涉及智能体或工单';

  @override
  String get createAsDraft => '创建为草稿';

  @override
  String get composePrNoRepo => '未选择 GitHub 仓库';

  @override
  String get composePrNoRepoHint => '选择已关联 GitHub 仓库的工作区以打开 pull request。';

  @override
  String get composePrPickBranches => '选择 base 和 compare 分支以预览变更。';

  @override
  String get composePrNothingToCompare => '这些分支之间没有变更。';

  @override
  String get repository => '仓库';

  @override
  String get baseBranchLabel => 'Base';

  @override
  String get compareBranchLabel => 'Compare';

  @override
  String get selectBranch => '选择分支';

  @override
  String get navMeetings => '会议';

  @override
  String get meetingsNoWorkspace => '选择工作区以查看会议。';

  @override
  String get meetingsEmpty => '暂无会议';

  @override
  String get meetingsEmptyHint => '录制你的第一场会议 — 音频留在本机，智能体会整理成笔记、决策和待办。';

  @override
  String get meetingNotesHint => '随手记下要点 — 会后由智能体扩写。';

  @override
  String get meetingSpeakerMe => '我';

  @override
  String get meetingStatusRecording => '录制中';

  @override
  String get meetingStatusProcessing => '处理中';

  @override
  String get meetingStatusDone => '已完成';

  @override
  String get meetingStatusFailed => '失败';

  @override
  String get meetingsSubtitle => '在本机采集并转写，再由智能体生成摘要。';

  @override
  String get meetingsRecordMeeting => '录制会议';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 场正在处理',
      one: '1 场正在处理',
    );
    return '$_temp0';
  }

  @override
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 场会议',
      one: '1 场会议',
      zero: '暂无会议',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => '未完成待办';

  @override
  String get meetingsLedgerDecisions => '决策';

  @override
  String get meetingsLiveOpen => '打开录制';

  @override
  String get meetingTemplateShort => '模板';

  @override
  String get meetingsStatThisWeek => '本周';

  @override
  String get meetingsStatRecorded => '已录制';

  @override
  String get meetingsFilterAll => '全部';

  @override
  String get meetingsFilterDone => '已完成';

  @override
  String get meetingsFilterProcessing => '处理中';

  @override
  String get meetingsSearchHint => '按标题、人物、应用筛选…';

  @override
  String get meetingsBucketToday => '今天';

  @override
  String get meetingsBucketYesterday => '昨天';

  @override
  String get meetingsBucketEarlierThisWeek => '本周早些时候';

  @override
  String get meetingsBucketLastWeek => '上周';

  @override
  String get meetingsBucketOlder => '更早';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 项决策',
      one: '1 项决策',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total 项待办';
  }

  @override
  String get meetingsEnhancedPill => '已增强';

  @override
  String get meetingsTranscribing => '正在转写并生成摘要…';

  @override
  String get meetingsOpenAction => '打开';

  @override
  String get meetingsStopProcessing => '停止';

  @override
  String get meetingsStillTranscribing => '仍在转写 — 完成后将显示摘要。';

  @override
  String get meetingsNoMatch => '没有匹配的会议';

  @override
  String get meetingsNoMatchHint => '试试其他筛选或搜索词。';

  @override
  String get meetingBackAllMeetings => '全部会议';

  @override
  String get meetingReRunSummary => '重新生成摘要';

  @override
  String get meetingExport => '导出';

  @override
  String get meetingAugmentingBanner => '正在根据转写稿补充笔记 — 提取决策和待办事项…';

  @override
  String get meetingTabNotes => '笔记';

  @override
  String get meetingTabTranscript => '转写';

  @override
  String get meetingTabActionItems => '待办事项';

  @override
  String get meetingTabDecisions => '决策';

  @override
  String get meetingNotesEnhancedToggle => '增强';

  @override
  String get meetingNotesYoursToggle => '你的笔记';

  @override
  String get meetingEnhancedByAgent => '由智能体增强 · 来自转写';

  @override
  String get meetingEnhancedPending => '智能体仍在处理此摘要。';

  @override
  String get meetingNotesEmpty => '暂无增强笔记。';

  @override
  String get meetingNotesSavedLocally => '已保存到本地';

  @override
  String get meetingNotesSaving => '正在保存…';

  @override
  String get meetingViewFullTranscript => '查看完整转录';

  @override
  String get meetingTranscriptSearchHint => '搜索转录…';

  @override
  String get meetingSpeakerEveryone => '所有人';

  @override
  String get meetingSpeakerOthers => '其他人';

  @override
  String get meetingTranscriptEmpty => '暂无转录。';

  @override
  String get meetingActionItemsEmpty => '尚未提取待办事项。';

  @override
  String get meetingActionItemFrom => '来自本次会议';

  @override
  String get meetingCreateTicket => '创建工单';

  @override
  String meetingTicketCreated(String key) {
    return '已创建并派发工单 $key。';
  }

  @override
  String get meetingTicketFailed => '无法创建工单。';

  @override
  String get meetingDecisionsEmpty => '尚未记录决策。';

  @override
  String get meetingEditTitle => '编辑标题';

  @override
  String get meetingTitleLabel => '标题';

  @override
  String get meetingAddActionItem => '添加待办事项';

  @override
  String get meetingEditActionItem => '编辑待办事项';

  @override
  String get meetingDeleteActionItem => '删除待办事项';

  @override
  String get meetingActionItemContentLabel => '待办事项';

  @override
  String get meetingActionItemContentHint => '需要做什么？';

  @override
  String get meetingActionItemOwnerLabel => '负责人';

  @override
  String get meetingActionItemOwnerHint => '由谁负责？（可选）';

  @override
  String get meetingAddDecision => '添加决策';

  @override
  String get meetingEditDecision => '编辑决策';

  @override
  String get meetingDeleteDecision => '删除决策';

  @override
  String get meetingDecisionContentLabel => '决策';

  @override
  String get meetingDecisionContentHint => '决定了什么？';

  @override
  String get meetingReRunStarted => '正在根据转录重新生成摘要…';

  @override
  String get meetingReRunNoTranscript => '暂无转录可供摘要。';

  @override
  String get meetingExportCopied => '已将笔记以 Markdown 复制到剪贴板。';

  @override
  String get meetingExportSaved => '会议已导出。';

  @override
  String meetingExportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String get meetingExportNothing => '暂无可导出内容。';

  @override
  String get meetingPlaybackPlay => '播放';

  @override
  String get meetingPlaybackPause => '暂停';

  @override
  String get meetingPlaybackUnavailable => '此设备不支持音频播放。';

  @override
  String get meetingDetectedTitle => '检测到会议';

  @override
  String meetingDetectedSubtitle(String label) {
    return '似乎正在进行“$label”。要录制吗？';
  }

  @override
  String get meetingDetectedSubtitleGeneric => '似乎正在开会。要录制吗？';

  @override
  String get meetingDetectedRecord => '录制';

  @override
  String get meetingDetectedDismiss => '忽略';

  @override
  String get meetingAutoStopTitle => '这次会议似乎已结束。要停止录制吗？';

  @override
  String get meetingAutoStopStop => '停止';

  @override
  String get meetingAutoStopKeep => '继续录制';

  @override
  String get meetingAutoDetect => '自动检测会议';

  @override
  String get meetingAutoDetectDescription => '监控日历和会议应用，在会议开始时提示录制。';

  @override
  String get meetingsRecordingCrumb => '正在录制…';

  @override
  String get meetingRecordTitleHint => '会议标题';

  @override
  String get meetingRecordTappingLabel => '正在采集：';

  @override
  String get meetingRecordMic => '麦克风';

  @override
  String get meetingRecordSystemAudio => '系统音频';

  @override
  String get meetingRecordPause => '暂停';

  @override
  String get meetingRecordResume => '继续';

  @override
  String get meetingRecordStop => '停止并总结';

  @override
  String get meetingRecordYourNotes => '你的笔记';

  @override
  String get meetingRecordNotesPlaceholder => '边听边记。几句碎片即可 — 停止后，智能体会结合转录展开。';

  @override
  String get meetingRecordLiveTranscript => '实时转录';

  @override
  String get meetingRecordDecoding => '正在本机解码';

  @override
  String get meetingRecordListening => '正在聆听… 一两秒内会显示语音，并标记为你 / 其他人。';

  @override
  String get meetingRecordPausedHint => '已暂停 — 恢复前将忽略音频。';

  @override
  String get meetingRecordNotActive => '没有正在进行的录制。';

  @override
  String get meetingHudRecording => '录制中';

  @override
  String get meetingHudPaused => '已暂停';

  @override
  String get meetingHudOpen => '打开';

  @override
  String get meetingHudStop => '停止';

  @override
  String get meetingToolbarPopOut => '弹出';

  @override
  String get meetingToolbarHoldToStop => '按住停止录制';

  @override
  String get meetingToolbarSemanticLabel => '会议录制工具栏';

  @override
  String get orchestrate => '编排';

  @override
  String get orchestrationUnavailable => '编排不可用';

  @override
  String get orchestrationApprove => '批准计划';

  @override
  String get orchestrationReject => '拒绝';

  @override
  String get orchestrationCancel => '取消编排';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count 个角色 — $hires 名新聘';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count 个子工单';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return '预估费用：\$$amount';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total 个子工单已完成';
  }

  @override
  String get orchestrationStatusProposed => '已提议';

  @override
  String get orchestrationStatusApproved => '已批准';

  @override
  String get orchestrationStatusExecuting => '执行中';

  @override
  String get orchestrationStatusSynthesizing => '汇总中';

  @override
  String get orchestrationStatusCompleted => '已完成';

  @override
  String get orchestrationStatusFailed => '失败';

  @override
  String get orchestrationStatusCancelled => '已取消';

  @override
  String get messageFailed => '运行失败';

  @override
  String get turnLimitReached => '已达轮次上限 — 回复以继续';

  @override
  String get retried => '已重试';

  @override
  String replyingTo(String name) {
    return '正在回复 $name';
  }

  @override
  String get silenceTimeoutLabel => '静默超时（分钟）';

  @override
  String get silenceTimeoutHint => '例如 15 — 超过此时长无输出则终止运行';

  @override
  String get capabilityJsonMode => 'JSON 模式';

  @override
  String get capabilityModelSelection => '模型选择';

  @override
  String get transcriptThinking => '思考中…';

  @override
  String transcriptThoughtFor(String duration) {
    return '思考了 $duration';
  }

  @override
  String get transcriptStatusMakingEdits => '正在编辑…';

  @override
  String get transcriptStatusReadingFiles => '正在读取文件…';

  @override
  String get transcriptStatusSearching => '正在搜索代码库…';

  @override
  String get transcriptStatusRunningCommands => '正在运行命令…';

  @override
  String get transcriptStatusResponding => '正在回复…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return '正在运行 $tool…';
  }

  @override
  String get transcriptInput => '输入';

  @override
  String get transcriptOutput => '输出';

  @override
  String get transcriptErrorLabel => '错误';

  @override
  String get transcriptSandboxBlocked => '沙盒已阻止一项操作';

  @override
  String transcriptShowFullOutput(int kb) {
    return '显示完整输出（+$kb KB）';
  }

  @override
  String transcriptShowAllLines(int count) {
    return '显示全部 $count 行';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return '正在显示前 $count 行';
  }

  @override
  String get transcriptGrepNoMatches => '无匹配项';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches 个匹配',
      one: '1 个匹配',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files 个文件',
      one: '1 个文件',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return '人物 $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => '重命名发言人';

  @override
  String get meetingRenameSpeakerTitle => '重命名发言人';

  @override
  String get meetingSpeakerNameLabel => '名称';

  @override
  String get meetingSpeakerSuggestFromCalendar => '来自本次会议的受邀者';

  @override
  String get meetingRenameSpeakerApplyAll => '应用到该发言人的所有片段';

  @override
  String get meetingRenameSpeakerScopeHint => '关闭后，仅重命名所选行。';

  @override
  String get meetingLinkEvent => '关联日程';

  @override
  String get meetingChangeEvent => '更换日程';

  @override
  String get meetingLinkEventTitle => '关联日历日程';

  @override
  String get meetingLinkEventSearchHint => '搜索日程';

  @override
  String get meetingLinkEventEmpty => '附近没有日历日程';

  @override
  String get meetingUnlinkEvent => '取消关联';

  @override
  String get calendarLinkExistingMeeting => '关联到现有会议';

  @override
  String get calendarLinkMeetingTitle => '关联会议';

  @override
  String get calendarLinkMeetingSearchHint => '搜索会议';

  @override
  String get calendarLinkMeetingEmpty => '没有可关联的会议';

  @override
  String get meetingRenameSpeakerFailed => '无法重命名发言人';

  @override
  String get calendarLinkUpdateFailed => '无法更新日历关联';

  @override
  String get rename => '重命名';

  @override
  String get notNow => '暂不';

  @override
  String get meetingSaveVoiceProfileTitle => '保存声纹档案？';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return '保存 $name 的声纹后，可在之后的会议中自动识别。';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return '已保存 $name 的声纹档案';
  }

  @override
  String get meetingVoiceProfileSaveFailed => '无法保存声纹档案';

  @override
  String get voiceProfilesSection => '声纹档案';

  @override
  String get voiceProfilesDescription => '已保存的声音会在之后的会议中自动识别。';

  @override
  String get voiceProfilesEmpty => '暂无已保存的声音。在会议转写中为发言人命名，然后选择“保存声纹档案”。';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个样本',
      one: '1 个样本',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => '重命名声纹档案';

  @override
  String get deleteVoiceProfileTitle => '删除声纹档案？';

  @override
  String deleteVoiceProfileBody(String name) {
    return '停止识别 $name？将删除其已保存的声纹。过去会议中已应用的名称会保留。';
  }

  @override
  String get connectedLabel => '已连接';

  @override
  String get ideTabGeneral => '常规';

  @override
  String get ideTabExplorer => '资源管理器';

  @override
  String get ideTabSourceControl => '源代码管理';

  @override
  String get generalSectionTodos => '待办';

  @override
  String get generalSectionGoals => '目标';

  @override
  String get goalRunStatusActive => '进行中';

  @override
  String get goalRunStatusPaused => '已暂停';

  @override
  String get goalRunStatusCompleted => '已完成';

  @override
  String get goalRunStatusFailed => '失败';

  @override
  String get goalRunStatusCancelled => '已取消';

  @override
  String get goalRunStatusBudgetExhausted => '预算已用尽';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return '运行 $run/$max · $cost/$cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return '运行 $run · $cost/$cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return '截止 $deadline';
  }

  @override
  String get goalRunPause => '暂停目标';

  @override
  String get goalRunResume => '继续目标';

  @override
  String goalRunResumeRaise(String cap) {
    return '继续 · 将上限提至 $cap';
  }

  @override
  String get goalRunStop => '停止目标';

  @override
  String get generalSectionAgents => '智能体';

  @override
  String get generalSectionTerminals => '终端';

  @override
  String get generalTodosEmpty => '暂无待办';

  @override
  String get generalAgentsEmpty => '没有正在运行的智能体';

  @override
  String get generalTerminalsEmpty => '没有打开的终端';

  @override
  String get generalSectionBrowsers => '浏览器';

  @override
  String get generalSectionComputers => '计算机';

  @override
  String get generalBrowsersEmpty => '没有打开的浏览器';

  @override
  String get generalComputersEmpty => '没有打开的计算机';

  @override
  String get generalSectionPhones => '手机';

  @override
  String get generalPhonesEmpty => '没有打开的手机';

  @override
  String get pauseAgent => '暂停智能体';

  @override
  String get resumeAgent => '继续智能体';

  @override
  String get agentCannotPause => '此智能体无法暂停，请改为停止。';

  @override
  String get goalClear => '清除目标';

  @override
  String get undoLabelGoalClear => '清除目标';

  @override
  String get todoStatusPending => '未开始';

  @override
  String get todoStatusInProgress => '进行中';

  @override
  String get todoStatusCompleted => '已完成';

  @override
  String get reorderTodo => '调整待办顺序';

  @override
  String get focusTerminal => '聚焦终端';

  @override
  String get focusMachine => '聚焦机器';

  @override
  String get focusBrowser => '聚焦浏览器';

  @override
  String get todoEditorTitle => '编辑待办';

  @override
  String get todoEditorHint => '每行一项。用 - [ ] 表示未开始，- [~] 表示进行中，- [x] 表示已完成。';

  @override
  String get todoNeedsText => '请在命令后添加文本';

  @override
  String get todoNotFound => '未找到匹配的待办';

  @override
  String get todoCleared => '已清空待办列表';

  @override
  String get todoNothingToCopy => '没有可复制的内容';

  @override
  String todoAdded(String content) {
    return '已添加“$content”';
  }

  @override
  String todoStarted(String content) {
    return '已开始“$content”';
  }

  @override
  String todoCompleted(String content) {
    return '已完成“$content”';
  }

  @override
  String todoRemoved(String content) {
    return '已移除“$content”';
  }

  @override
  String todoCopied(int count) {
    return '已复制 $count 项';
  }

  @override
  String todoImported(int count) {
    return '已导入 $count 项';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return '未知待办命令“$name”';
  }

  @override
  String get terminal => '终端';

  @override
  String get ideCloseTab => '关闭标签页';

  @override
  String get ideSplitEditor => '拆分编辑器';

  @override
  String get ideSplitRight => '向右拆分';

  @override
  String get ideSplitDown => '向下拆分';

  @override
  String get ideSplitLeft => '向左拆分';

  @override
  String get ideSplitUp => '向上拆分';

  @override
  String get ideCloseGroup => '关闭组';

  @override
  String get ideCloseOthers => '关闭其他';

  @override
  String get ideCloseToRight => '关闭右侧';

  @override
  String get ideCloseSaved => '关闭已保存';

  @override
  String get ideCloseAll => '全部关闭';

  @override
  String get ideSplit => '拆分';

  @override
  String get ideToggleSidebar => '切换侧边栏';

  @override
  String get ideNewTab => '打开编辑器';

  @override
  String get ideNewTabMenu => '新建标签页';

  @override
  String get ideReviewCode => '审查代码';

  @override
  String ideReviewCodeInRepo(String repo) {
    return '审查代码 ($repo)';
  }

  @override
  String get ideRevertConfirmTitle => '还原更改';

  @override
  String get ideRevertUntracked => '未跟踪的文件无法还原';

  @override
  String get ideRevertFailed => '无法还原这些文件。对话工作树可能不可用。';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个文件',
      one: '1 个文件',
    );
    return '$_temp0 无法还原（未跟踪）。';
  }

  @override
  String get ideSearchMatchCase => '区分大小写';

  @override
  String get ideSearchWholeWord => '全字匹配';

  @override
  String get ideSearchRegex => '正则表达式';

  @override
  String get ideSearchFilters => '搜索筛选';

  @override
  String get ideSearchFilesToInclude => '要包含的文件';

  @override
  String get ideSearchFilesToExclude => '要排除的文件';

  @override
  String get ideNoOpenTabs => '没有打开的标签页 — 使用 + 打开';

  @override
  String get ideBrowserAddressHint => '输入地址或搜索';

  @override
  String get ideSimpleWebBrowser => '简易网页浏览器';

  @override
  String get ideWebBrowser => '网页浏览器';

  @override
  String get ideBrowserEnterUrl => '在地址栏输入 URL 以开始浏览';

  @override
  String get ideCodeServer => '编辑器';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return '是否将更改保存到 $fileName？';
  }

  @override
  String get ideUnsavedChangesBody => '若不保存，更改将丢失。';

  @override
  String get ideDontSave => '不保存';

  @override
  String get editorAutoSave => '自动保存';

  @override
  String get editorAutoSaveDescription => '在内嵌编辑器中自动保存更改。';

  @override
  String get editorAutoSaveOff => '关闭';

  @override
  String get editorAutoSaveAfterDelay => '延迟后';

  @override
  String get editorAutoSaveOnFocusChange => '焦点变化时';

  @override
  String get ideCodeServerUnavailable => '此服务器上没有可用的 code-server';

  @override
  String get ideCodeServerUnavailableHint =>
      '在服务器主机上安装 code-server（coder/code-server），然后重新打开编辑器。';

  @override
  String get ideCodeServerInstalling => '正在准备编辑器…';

  @override
  String get ideCodeServerOpenInBrowser => '在浏览器中打开编辑器';

  @override
  String get ideCodeServerError => '无法打开编辑器';

  @override
  String get paneSuspendedCaption => '已挂起以节省资源 — 获得焦点时会重新加载';

  @override
  String get ideFolderLoadFailed => '无法加载此文件夹';

  @override
  String get ideFileSearchFailed => '无法搜索文件';

  @override
  String get ideSearchInFiles => '在文件中搜索';

  @override
  String get ideNoContentMatches => '无匹配项';

  @override
  String get ideSourceControlCreatePr => '创建 pull request';

  @override
  String ideSourceControlViewPr(int number) {
    return '查看 pull request #$number';
  }

  @override
  String get ideSourceControlNoChanges => '无更改';

  @override
  String get noReposInConversation => '此对话中没有仓库';

  @override
  String get ideSourceControlNoSpace => '打开对话以查看其更改';

  @override
  String get ideFileLoading => '正在加载…';

  @override
  String get ideFileBinary => '二进制文件';

  @override
  String get mcpExternalServers => '外部 MCP 服务器';

  @override
  String get mcpExternalServersDescription =>
      '连接到外部 MCP 服务器（GitHub、Sentry、Postgres、浏览器自动化）。已为 Claude、Cursor、VS Code 及其他工具配置的服务器会自动发现。';

  @override
  String get mcpApprovalMode => '工具批准';

  @override
  String get mcpApprovalModeDescription => '哪些工具操作可无需确认即运行。读取始终允许；更高层级会提示。';

  @override
  String get mcpApprovalAlwaysAsk => '始终询问';

  @override
  String get mcpApprovalWrite => '自动批准写入';

  @override
  String get mcpApprovalYolo => '全部自动批准';

  @override
  String get mcpNoExternalServers => '未发现外部 MCP 服务器。';

  @override
  String get mcpAuthorize => '授权';

  @override
  String get mcpReconnect => '重新连接';

  @override
  String get mcpExternalConnectionsNote =>
      '外部 MCP 服务器运行在智能体服务器上（桌面端与网页端共用）。授权 OAuth 服务器仅在桌面端可用。';

  @override
  String get mcpStatusConnected => '已连接';

  @override
  String get mcpStatusConnecting => '正在连接…';

  @override
  String get mcpStatusNeedsAuth => '需要授权';

  @override
  String get mcpStatusFailed => '失败';

  @override
  String get mcpStatusCircuitOpen => '已暂停';

  @override
  String get mcpStatusDisabled => '已禁用';

  @override
  String get providersAndModels => '提供商与模型';

  @override
  String get providersAndModelsDescription =>
      '列出内置智能体可用的全部提供商——设置 API 密钥或通过浏览器登录，查看各已连接提供商的模型与定价，并管理此工作区可使用的提供商。';

  @override
  String get syncNow => '立即同步';

  @override
  String syncNowResult(int applied, int failed) {
    return '同步完成 — 已应用 $applied，失败 $failed';
  }

  @override
  String syncNowFailed(String error) {
    return '同步失败：$error';
  }

  @override
  String get denied => '已拒绝';

  @override
  String get allowed => '已允许';

  @override
  String allowProviderSemantic(String provider) {
    return '允许 $provider';
  }

  @override
  String enabledViaEnv(String key) {
    return '通过 $key 启用';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output / 百万';
  }

  @override
  String contextTokens(String tokens) {
    return '$tokens 上下文';
  }

  @override
  String get usageAndCost => '用量与费用';

  @override
  String get usageAndCostDescription => '过去 7 天各智能体的支出，基于观察到的运行费用。';

  @override
  String get noUsageYet => '尚无用量记录。';

  @override
  String get spentThisWeek => '本周已花费';

  @override
  String get subscriptionUsage => '订阅用量';

  @override
  String get subscriptionUsageUnavailable => '不可用';

  @override
  String get subscriptionUsageExhausted => '配额已用尽';

  @override
  String get subscriptionUsageSignInRequired => '请重新登录';

  @override
  String get subscriptionUsageSignInExpired => '登录已过期，将在下次运行时续期';

  @override
  String get subscriptionUsagePartiallyAvailable => '部分可用';

  @override
  String resetsIn(String duration) {
    return '$duration 后重置';
  }

  @override
  String get feedbackHelpful => '这很有帮助';

  @override
  String get feedbackNotHelpful => '这没有帮助';

  @override
  String get modeChat => '聊天';

  @override
  String get modePlan => '规划';

  @override
  String get modeReview => '审查';

  @override
  String get modeOrchestrate => '编排';

  @override
  String get editorTheme => '编辑器主题';

  @override
  String get editorThemeDescription => '导入 VS Code 颜色主题，使内嵌差异视图和编辑器与你的 IDE 一致。';

  @override
  String get editorThemePasteHint => '粘贴 VS Code 颜色主题 JSON 文件的内容';

  @override
  String get editorThemeImported => '主题已导入';

  @override
  String get editorThemeInvalid => '这不像是有效的 VS Code 主题';

  @override
  String get importTheme => '导入主题';

  @override
  String get clearTheme => '清除主题';

  @override
  String get openInDiffViewer => '在差异查看器中打开';

  @override
  String get shellCommand => '命令';

  @override
  String get shellOutput => '输出';

  @override
  String get revertToHere => '还原到此处';

  @override
  String get revertConfirmBody => '隐藏此点之后的消息，并将智能体的文件更改回退到此轮？你可以撤销此操作。';

  @override
  String get revert => '还原';

  @override
  String get revertedToHere => '已还原到此处';

  @override
  String get nothingToRevert => '没有可还原的内容';

  @override
  String get undoRevert => '撤销还原';

  @override
  String get revertUndone => '已撤销还原';

  @override
  String get systemBehavior => '系统行为';

  @override
  String get keepAwakeTitle => '智能体运行时保持电脑唤醒';

  @override
  String get keepAwakeOnSubtitle => '智能体工作时电脑不会休眠';

  @override
  String get keepAwakeOffSubtitle => '即使智能体正在工作，电脑仍可能休眠';

  @override
  String get syncEngineSectionTitle => '同步引擎';

  @override
  String get syncEngineDescription =>
      '工单、消息和笔记通过小增量实时更新，而非完整快照。关闭开关会将该存储回退到完整快照模式 — 需重新加载应用后生效。';

  @override
  String get syncEngineTicketsTitle => '工单';

  @override
  String get syncEngineMessagingTitle => '消息';

  @override
  String get syncEngineNotesTitle => '笔记';

  @override
  String get syncEngineOnSubtitle => '实时增量同步已启用';

  @override
  String get syncEngineOffSubtitle => '使用完整快照同步';

  @override
  String get spaces => '空间';

  @override
  String get spacesHomeDescription => '从列表中选择空间，或新建一个。';

  @override
  String get noSpacesYet => '还没有空间';

  @override
  String get newSpace => '新建空间';

  @override
  String get spaceName => '空间名称';

  @override
  String get spaceReposHint => '要包含的仓库';

  @override
  String get ideSourceControl => '源代码管理';

  @override
  String get stagedChanges => '已暂存的更改';

  @override
  String get changes => '更改';

  @override
  String get stageFile => '暂存';

  @override
  String get unstageFile => '取消暂存';

  @override
  String get stageAll => '暂存所有更改';

  @override
  String get unstageAll => '全部取消暂存';

  @override
  String get stageChangesToCommit => '暂存要提交的更改';

  @override
  String get syncToPrHead => '拉取最新 PR 提交';

  @override
  String get syncedToPrHead => '已同步到最新 PR 提交';

  @override
  String get syncPrHeadDirty => '同步前请先提交或丢弃更改';

  @override
  String get syncPrHeadFailed => '无法同步到 PR 最新提交';

  @override
  String get spaceLabel => '空间';

  @override
  String get keybindingNewSpace => '新建空间';

  @override
  String get keybindingCreateANewSpaceDescription => '创建新空间';

  @override
  String get jumpToLatest => '跳到最新';

  @override
  String get streaming => '流式输出';

  @override
  String get newMessages => '新';

  @override
  String get copyLink => '复制链接';

  @override
  String get linkCopied => '链接已复制';

  @override
  String get agentResponding => '智能体正在回复';

  @override
  String get agentFinished => '智能体已完成';

  @override
  String get harnessConnectProviderForModels => '连接提供商以查看模型。';

  @override
  String get providerSignOut => '退出登录';

  @override
  String get providerWaitingForDeviceCode => '等待你在浏览器中确认代码…';

  @override
  String get providerDeviceCodeHint => '请确认此代码与浏览器中显示的一致，然后批准。';

  @override
  String get providerPlanUsageLoading => '正在检查套餐用量…';

  @override
  String get providerPlanUsageUnavailable => '此套餐未返回用量信息。';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return '移除 $provider API 密钥？';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return '已存储的密钥将被删除且无法再次显示。使用 $provider 模型的智能体将停止工作，直到你粘贴新密钥。';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return '移除 $provider？';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return '该提供商及其已存储密钥将被删除。固定使用其模型的智能体将停止工作。';
  }

  @override
  String get providerApiKeyHint => '粘贴 API 密钥';

  @override
  String get providerApiKeyStoredHint => '粘贴另一个 API 密钥以添加';

  @override
  String get providerAddAnotherAccount => '添加其他账号';

  @override
  String get providerActiveBadge => '使用中';

  @override
  String get providerOauthAccountFallback => 'OAuth 账号';

  @override
  String get providerApiKeyFallback => 'API 密钥';

  @override
  String get providerRemoveCredentialConfirmTitle => '移除此凭据？';

  @override
  String get providerSignOutAccountConfirmTitle => '退出此账号？';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return '使用 $provider 的智能体会回退到其其他密钥和账号。若均已移除，将停止工作直到你再添加一个。';
  }

  @override
  String get providerBaseUrlHint => '基础 URL（可选）';

  @override
  String get addProvider => '添加提供商';

  @override
  String get noCustomProviders => '暂无自定义提供商。';

  @override
  String get providerNameLabel => '名称';

  @override
  String get apiTypeLabel => 'API 类型';

  @override
  String get providerBaseUrlLabel => '基础 URL';

  @override
  String get providerApiKeyOptionalHint => 'API 密钥（可选）';

  @override
  String get dialectOpenAiCompatible => 'OpenAI 兼容';

  @override
  String get dialectAnthropicCompatible => 'Anthropic 兼容';

  @override
  String get removeProviderTooltip => '移除提供商';

  @override
  String get providerLogInWithBrowser => '通过浏览器登录';

  @override
  String providerLoginDialogTitle(String provider) {
    return '登录 $provider';
  }

  @override
  String get providerLabel => '提供商';

  @override
  String get selectProviderToLogin => '选择要登录的提供商';

  @override
  String providerLoginFailed(String error) {
    return '登录失败：$error';
  }

  @override
  String get providerWaitingForBrowser => '等待你在浏览器中授权…';

  @override
  String get providerPasteCodeHint => '或粘贴浏览器中的代码';

  @override
  String get providerCompleteLogin => '完成';

  @override
  String get providerConnectedApiKey => '已通过 API 密钥连接';

  @override
  String get providerConnectedOauth => '已连接';

  @override
  String providerConnectedAccount(String account) {
    return '已连接 · $account';
  }

  @override
  String get providerLocalReady => '本地 · 已就绪';

  @override
  String get providerNotConnected => '未连接';

  @override
  String get preparingWorkspace => '正在准备工作区…';

  @override
  String provisioningRunningSetupScript(String repo) {
    return '正在运行 $repo 的设置脚本…';
  }

  @override
  String get repoScriptsTitle => '脚本';

  @override
  String get repoScriptsTooltip => '配置生命周期脚本';

  @override
  String get repoScriptsSetupLabel => '设置脚本';

  @override
  String get repoScriptsSetupHelp =>
      '在空间的工作树创建后立即运行 — 安装依赖、生成文件。失败会将空间标记为失败；重试会再次运行。';

  @override
  String get repoScriptsArchiveLabel => '归档脚本';

  @override
  String get repoScriptsArchiveHelp => '在删除空间的工作树前运行 — 清理工作树外的资源。失败不会阻止删除。';

  @override
  String get repoScriptsEnvHelp =>
      '从工作树通过 bash 运行，并设置 CC_WORKSPACE_PATH（工作树）、CC_ROOT_PATH（仓库根目录）、CC_SPACE_ID、CC_SPACE_NAME 和 CC_REPO_NAME。';

  @override
  String get repoScriptsSetupPlaceholder => '例如 pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      '例如 docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => '最近运行';

  @override
  String get repoScriptsNoRuns => '暂无运行记录';

  @override
  String get repoScriptsSaved => '脚本已保存';

  @override
  String get repoScriptsRunKindSetup => '设置';

  @override
  String get repoScriptsRunKindArchive => '归档';

  @override
  String get repoScriptsRunStatusRunning => '运行中';

  @override
  String get repoScriptsRunStatusSucceeded => '已成功';

  @override
  String get repoScriptsRunStatusFailed => '失败';

  @override
  String get repoScriptsRunStatusTimedOut => '已超时';

  @override
  String repoScriptsExitCode(int code) {
    return '退出码 $code';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return '正在克隆 $repo…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return '正在检出 $repo 中的 pull request…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return '正在设置智能体 $agent…';
  }

  @override
  String get workspacePrepFailed => '工作区设置失败';

  @override
  String get workspacePrepStopped => '工作区设置已停止';

  @override
  String get stopWorkspacePrep => '停止准备';

  @override
  String get stopWorkspacePrepTooltip => '停止准备此工作区';

  @override
  String get stopWorkspacePrepConfirm => '停止准备此工作区？正在进行的克隆将被丢弃 — 你可以从此处重新开始。';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count 条消息将在就绪后发送';
  }

  @override
  String get membersNav => '成员';

  @override
  String get membersSettingsDescription => '可访问此工作区的人员：名册、邀请和审计记录';

  @override
  String get memberRosterLabel => '成员名册';

  @override
  String get memberRepoAccessAction => '仓库访问';

  @override
  String memberRepoAccessTitle(String name) {
    return '$name 的仓库访问';
  }

  @override
  String get roleOwner => '所有者';

  @override
  String get roleAdmin => '管理员';

  @override
  String get roleMember => '成员';

  @override
  String get roleViewer => '查看者';

  @override
  String get roleGuest => '访客';

  @override
  String get removeMemberTitle => '移除成员';

  @override
  String removeMemberConfirm(String name) {
    return '将 $name 从此工作区移除？其将立即失去访问权限。';
  }

  @override
  String get transferOwnershipAction => '转让所有权';

  @override
  String get transferOwnershipTitle => '转让所有权';

  @override
  String transferOwnershipConfirm(String name) {
    return '将 $name 设为此工作区的所有者？你将成为管理员。只有所有者可以删除工作区或更改其他管理员的角色。';
  }

  @override
  String get transferOwnershipCta => '转让';

  @override
  String get auditTrailLabel => '授权审计追踪';

  @override
  String get auditTrailDescription => '记录每一次允许与拒绝，并以哈希链连接，修改或删除均可被检测。';

  @override
  String get auditVerifyChain => '验证链';

  @override
  String auditChainIntact(int count) {
    return '链完整 — 已验证 $count 条';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return '链在条目 $seq 处断裂：$reason';
  }

  @override
  String get auditEmpty => '尚无决策记录。';

  @override
  String get auditDenied => '已拒绝';

  @override
  String get auditAllowed => '已允许';

  @override
  String auditOnBehalfOf(String user) {
    return '代表 $user';
  }

  @override
  String get policyTemplatesLabel => '策略模板';

  @override
  String get policyTemplatesDescription => '应用起始姿态，或在工作区之间转移。';

  @override
  String get policyTemplateStrict => '严格';

  @override
  String get policyTemplateBalanced => '均衡';

  @override
  String get policyTemplatePermissive => '宽松';

  @override
  String get policyTemplateApply => '应用';

  @override
  String policyTemplateApplied(int count) {
    return '已应用 $count 条规则';
  }

  @override
  String get policyExport => '复制策略';

  @override
  String get policyExported => '策略已复制到剪贴板';

  @override
  String get policyImport => '粘贴策略';

  @override
  String policyImported(int count) {
    return '已导入 $count 条规则';
  }

  @override
  String get approveAndRemember => '批准 8 小时';

  @override
  String get approveAndRememberTooltip => '批准此操作，并在此空间 8 小时内不再询问类似操作。到期后自动失效。';

  @override
  String get unknownUserLabel => '未知用户';

  @override
  String get inviteMember => '邀请成员';

  @override
  String get inviteRepoAccessHeader => '仓库访问';

  @override
  String get inviteRepoAccessExplainer => '仅勾选的仓库会按所选权限与受邀者共享，其余保持隐藏。';

  @override
  String get grantLevelRead => '读取';

  @override
  String get grantLevelReview => '审阅';

  @override
  String get grantLevelWrite => '写入';

  @override
  String get inviteExpiryLabel => '有效期';

  @override
  String get expiryOneDay => '1 天';

  @override
  String get expirySevenDays => '7 天';

  @override
  String get expiryThirtyDays => '30 天';

  @override
  String get createInviteAction => '创建邀请';

  @override
  String get inviteOneTimeCodeLabel => '一次性代码';

  @override
  String get inviteCodeShownOnce => '此代码仅显示一次——请立即复制。';

  @override
  String get inviteLinkLabel => '邀请链接';

  @override
  String get inviteRedeemHint => '将代码分享给被邀请人，他们凭此代码在你的服务器 URL 上兑换。';

  @override
  String get inviteScanQr => '或扫码兑换';

  @override
  String get inviteLoopbackWarningTitle => '邀请指向本地地址';

  @override
  String get inviteLoopbackWarningBody =>
      '其他机器上的协作者将无法访问此服务器。请启动隧道（设置 → 集成 → 共享此服务器）或绑定到你的网络，以便外部用户连接。';

  @override
  String get inviteStatusOpen => '未使用';

  @override
  String get inviteStatusUsed => '已使用';

  @override
  String get inviteStatusRevoked => '已吊销';

  @override
  String get inviteStatusExpired => '已过期';

  @override
  String inviteCreatedTime(String time) {
    return '创建于 $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return '将于 $date 过期';
  }

  @override
  String get noActivityYet => '暂无动态';

  @override
  String get couldNotLoadMembers => '无法加载成员';

  @override
  String get couldNotLoadInvites => '无法加载邀请';

  @override
  String get couldNotLoadActivity => '无法加载动态';

  @override
  String get yourDevices => '你的设备';

  @override
  String get yourDevicesDescription => '已与此服务器上你的账户配对的客户端。';

  @override
  String get noOwnDevices => '尚无设备与你的账户配对';

  @override
  String get renameDeviceTitle => '重命名设备';

  @override
  String get revokeDeviceTitle => '吊销设备';

  @override
  String revokeDeviceConfirm(String label) {
    return '吊销 $label？它会立即断开连接，并且无法再访问此服务器。';
  }

  @override
  String devicePairedTime(String time) {
    return '配对于 $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return '最后出现于 $time';
  }

  @override
  String get deviceNeverSeen => '从未连接';

  @override
  String get profileSectionLabel => '个人资料';

  @override
  String get profileSectionDescription =>
      '你在此工作区对同事和 git 提交作者信息中的显示方式。空字段继承账户的姓名和电子邮件。';

  @override
  String get displayNameLabel => '显示名称';

  @override
  String get emailLabel => '邮箱';

  @override
  String get gitAuthorNameLabel => 'Git 作者姓名';

  @override
  String get gitAuthorEmailLabel => 'Git 作者邮箱';

  @override
  String get profileSaved => '个人资料已保存';

  @override
  String get presenceOnline => '在线';

  @override
  String get presenceIdle => '空闲';

  @override
  String get presenceTyping => '正在输入…';

  @override
  String get presenceAgentThinking => '思考中';

  @override
  String get presenceAgentRunning => '运行中';

  @override
  String get presenceAgentBlocked => '已阻塞';

  @override
  String get presenceAgentDone => '已完成';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status（$cost）';
  }

  @override
  String get presenceRailLabel => '在线成员';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => '开启免打扰';

  @override
  String get dndTooltipOff => '关闭免打扰';

  @override
  String get startPresenting => '开始演示';

  @override
  String get stopPresenting => '停止演示';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name 正在演示';
  }

  @override
  String get spotlightLeave => '离开';

  @override
  String typingIndicator(String name) {
    return '$name 正在输入…';
  }

  @override
  String get ideTabNotes => '备注';

  @override
  String get ideSidebarAllViews => '所有视图';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return '所有视图（已隐藏 $count 个）';
  }

  @override
  String get ideSidebarPinView => '固定到侧边栏';

  @override
  String get ideSidebarUnpinView => '从侧边栏取消固定';

  @override
  String get notesEmptyHint => '为之后接手此对话的人添加备注…';

  @override
  String get notesEditTooltip => '编辑备注';

  @override
  String notesUpdatedBy(String name, String time) {
    return '由 $name 更新 · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name 正在编辑';
  }

  @override
  String get notesSaveFailed => '无法保存备注';

  @override
  String get reactionAddTooltip => '添加表情回应';

  @override
  String reactionToggleTooltip(String emoji) {
    return '以 $emoji 回应';
  }

  @override
  String get autonomyDialLabel => '自主程度';

  @override
  String get autonomyProposeOnly => '仅提议';

  @override
  String get autonomyActWithApproval => '批准后行动';

  @override
  String get autonomyActFreely => '自由行动';

  @override
  String get autonomyDefaultOption => '默认';

  @override
  String get checkerLabel => '检查者';

  @override
  String get checkerNone => '无';

  @override
  String get checkerCaption => '检查者会审查其他智能体已完成的运行。';

  @override
  String get takeoverTooltip => '接管工作树';

  @override
  String get takeoverBannerSelf => '你已接管此对话的工作树';

  @override
  String takeoverBannerOther(String name) {
    return '$name 已接管此对话的工作树';
  }

  @override
  String get handBackButton => '交还';

  @override
  String get handBackDialogTitle => '交还工作树';

  @override
  String get handBackDialogNoteHint => '给智能体的备注（可选）…';

  @override
  String takeoverFailed(String message) {
    return '无法接管：$message';
  }

  @override
  String handBackFailed(String message) {
    return '无法交还：$message';
  }

  @override
  String get planStudioTitle => 'Plan Studio';

  @override
  String get plansTitle => '计划';

  @override
  String get plansSubtitle => '进行中的计划、计划文档与剧本';

  @override
  String get plansActiveSection => '进行中的计划';

  @override
  String get plansDocumentsSection => '计划文档';

  @override
  String get plansPlaybooksSection => '剧本';

  @override
  String get plansNoActive => '暂无进行中的计划。';

  @override
  String get plansNoDocuments => '暂无计划文档。';

  @override
  String get plansNoPlaybooks => '暂无剧本。';

  @override
  String get planNotFound => '未找到计划。';

  @override
  String get planOpenInStudio => '打开';

  @override
  String get planNodeTitle => '标题';

  @override
  String get planNodeDescription => '描述';

  @override
  String get planNodeDescriptionHint => '此步骤应做什么…';

  @override
  String get planNodeApplyDescription => '应用';

  @override
  String get planNodeRole => '角色';

  @override
  String get planNodeDependencies => '依赖于';

  @override
  String get planNodeDependenciesHint => '添加依赖';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个依赖',
      one: '1 个依赖',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies => '无依赖，计划一开始即会运行';

  @override
  String get planNodeOutputSchema => '输出结构（JSON）';

  @override
  String get planNodeEstimate => '预估';

  @override
  String get planNodeProvenance => '来源';

  @override
  String get planNodeAlreadyExecuted => '已执行——在此编辑会使计划从此处分叉。';

  @override
  String get planNewNodeTitle => '新建步骤';

  @override
  String get planEstimateNoHistory => '暂无历史记录';

  @override
  String get planEstimateBlastUnknown => '影响范围：未知';

  @override
  String get planEstimatePartial => '部分';

  @override
  String get planEstimateAction => '预估';

  @override
  String planEstimateDuration(String range) {
    return '时长 $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return '影响范围：$files 个文件、$symbols 个符号';
  }

  @override
  String get planApprove => '批准计划';

  @override
  String get planApproveSelectedNodes => '批准所选';

  @override
  String get planReject => '拒绝';

  @override
  String get planCancel => '取消运行';

  @override
  String get planContinueNode => '继续节点';

  @override
  String get planTotalNotEstimated => '尚未预估';

  @override
  String get planBudgetExceeded => '已超预算';

  @override
  String planBudgetCeiling(String amount) {
    return '预算 ≤ \$$amount';
  }

  @override
  String get planVersionsTitle => '版本';

  @override
  String get planNoRevisions => '暂无修订。';

  @override
  String get planDiffIdentical => '无变化。';

  @override
  String get planDiffGoalChanged => '目标已变更';

  @override
  String get planDiffBudgetChanged => '预算已变更';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return '从 v$fromRev 到 v$toRev 的变化';
  }

  @override
  String planDiffAdded(String node) {
    return '已添加 $node';
  }

  @override
  String planDiffRemoved(String node) {
    return '已移除 $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return '已更改 $node：$fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return '已添加边：$edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return '已移除边：$edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return '已添加角色：$role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return '已移除角色：$role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return '已重新分配角色：$role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return '计划已重新规划：你批准的是 v$approved，现在是 v$current。请先查看差异再让它继续。';
  }

  @override
  String planLiveActualCost(String amount) {
    return '实际费用：\$$amount';
  }

  @override
  String get planPlaybookRun => '运行';

  @override
  String get planPlaybookDelete => '删除剧本';

  @override
  String get planPlaybookProposed => '已提出计划——请在 Plan Studio 中批准。';

  @override
  String get planPlaybookAnchorTicket => '锚定工单';

  @override
  String get planPlaybookPickTicket => '选择一个工单…';

  @override
  String get planPlaybookProposeRun => '提出计划';

  @override
  String get planPlaybookRepoHint => '仓库 id';

  @override
  String get planPlaybookAgentHint => '智能体 id';

  @override
  String planPlaybookRunTitle(String name) {
    return '运行 $name';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count 个参数';
  }

  @override
  String get recentLabel => '最近';

  @override
  String get cheatSheetTitle => '键盘快捷键';

  @override
  String get cheatSheetGlobal => '全局';

  @override
  String get cheatSheetThisScreen => '当前屏幕';

  @override
  String get cheatSheetReservedInBrowser => '浏览器保留';

  @override
  String get keybindingCheatSheet => '键盘快捷键';

  @override
  String get keybindingShowKeyboardShortcutsDescription => '显示当前屏幕的键盘快捷键速查表';

  @override
  String get runPlaybookLabel => '运行剧本';

  @override
  String get playbooksLabel => '剧本';

  @override
  String get keybindingUndo => '撤销';

  @override
  String get keybindingRedo => '重做';

  @override
  String get keybindingUndoLastActionDescription => '撤销上一个可撤销的操作';

  @override
  String get keybindingRedoLastActionDescription => '重做上一个被撤销的操作';

  @override
  String get undone => '已撤销';

  @override
  String get redone => '已重做';

  @override
  String get undoFailed => '无法撤销';

  @override
  String get undoLabelTicketEdit => '工单编辑';

  @override
  String get undoLabelMessageEdit => '消息编辑';

  @override
  String get undoLabelTodoStatus => '待办状态';

  @override
  String get inboxTitle => '收件箱';

  @override
  String get inboxReview => '审阅';

  @override
  String get inboxOpen => '打开';

  @override
  String get inboxAllCaughtUp => '全部处理完毕';

  @override
  String get inboxGitHubDownTitle => 'GitHub 可能出现了故障';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub 报告的状态为 $status，因此此列表中可能缺少某些 pull request，它们并非真的已处理完毕。';
  }

  @override
  String get inboxGitHubIdentityTitle => '无法确认你的 GitHub 账户';

  @override
  String get inboxGitHubIdentityBody =>
      '收件箱按你在 GitHub 上的身份排序。在该信息加载完成之前，即使有 pull request 在等你，收件箱也会保持为空。';

  @override
  String get inboxSeverityBlocking => '阻塞';

  @override
  String get inboxSeverityWaiting => '等待中';

  @override
  String get inboxSeverityInfo => '信息';

  @override
  String get inboxSyncFailed => '同步失败';

  @override
  String get inboxNeedsYourAttention => '需要你处理';

  @override
  String get inboxSectionNeedsYourReview => '等待你审阅';

  @override
  String get inboxSectionReturnedToYou => '已退回给你';

  @override
  String get inboxSectionApproved => '已批准';

  @override
  String get inboxSectionDrafts => '草稿';

  @override
  String get inboxSectionWaitingForReviewers => '等待审阅者';

  @override
  String get inboxSectionMergingAndMerged => '正在合并与最近已合并';

  @override
  String get inboxSectionWaitingForAuthor => '等待作者';

  @override
  String get inboxColumnTitle => '标题';

  @override
  String get inboxColumnChanges => '变更';

  @override
  String get inboxColumnUpdated => '更新时间';

  @override
  String get inboxReviewApproved => '已批准';

  @override
  String get inboxReviewChangesRequested => '已请求修改';

  @override
  String get inboxHeroSubtitle => '所有与你相关的 pull request，按下一步动作排序。';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个 pull request 需要你审阅',
      one: '1 个 pull request 需要你审阅',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个已退回给你',
      one: '1 个已退回给你',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted => '该更改未保存，已回滚';

  @override
  String get offlinePendingLabel => '待同步';

  @override
  String get offlineSyncingLabel => '同步中';

  @override
  String get copyLinkLabel => '复制此页面的链接';

  @override
  String get agentsSectionLabel => '智能体';

  @override
  String get fleetWorkersTitle => '工作节点';

  @override
  String get fleetWorkersSubtitle => '可用于运行作业的机器';

  @override
  String get fleetJobsTitle => '作业';

  @override
  String get fleetJobsSubtitle => '分发到整个机群的工作';

  @override
  String get fleetNoWorkers =>
      '暂无工作节点——在另一台机器上运行 `cc_worker --server <url>` 即可加入机群。';

  @override
  String get fleetNoJobs => '暂无作业。';

  @override
  String get fleetError => '无法加载机群';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个核心',
      one: '1 个核心',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return '心跳 $time';
  }

  @override
  String get fleetNoHeartbeat => '尚无心跳';

  @override
  String fleetLastErrorLabel(String error) {
    return '上次错误：$error';
  }

  @override
  String get fleetDrain => '排空';

  @override
  String get fleetResume => '恢复';

  @override
  String get fleetRevoke => '吊销';

  @override
  String get fleetRemove => '移除';

  @override
  String get fleetRevokeTitle => '吊销工作节点？';

  @override
  String fleetRevokeBody(String name) {
    return '吊销 $name？其会话将结束，正在运行的作业会被重新分配。';
  }

  @override
  String get fleetRemoveTitle => '移除工作节点？';

  @override
  String fleetRemoveBody(String name) {
    return '从机群中移除 $name？这将删除其记录。';
  }

  @override
  String get fleetActionFailed => '操作失败';

  @override
  String get fleetJobUnassigned => '未分配';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max 次尝试';
  }

  @override
  String get fleetPlacementReasons => '放置决策';

  @override
  String get fleetNoPlacements => '暂无放置决策。';

  @override
  String get fleetStatusOnline => '在线';

  @override
  String get fleetStatusDraining => '排空中';

  @override
  String get fleetStatusOffline => '离线';

  @override
  String get fleetStatusIncompatible => '不兼容';

  @override
  String get fleetStatusRevoked => '已吊销';

  @override
  String get fleetJobStatusQueued => '排队中';

  @override
  String get fleetJobStatusRunning => '运行中';

  @override
  String get fleetJobStatusSucceeded => '已成功';

  @override
  String get fleetJobStatusFailed => '已失败';

  @override
  String get fleetJobStatusCancelled => '已取消';

  @override
  String get evalsNoSuites => '暂无评估套件。';

  @override
  String get evalsError => '无法加载评估';

  @override
  String get evalsStarterBadge => '入门';

  @override
  String evalsDefaultBatch(int count) {
    return '默认批量 $count';
  }

  @override
  String get evalsRecentRuns => '最近运行';

  @override
  String get evalsNoRuns => '暂无运行。';

  @override
  String get evalsPassRate => '通过率';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return '由 $who 触发';
  }

  @override
  String evalsRunFinished(String rate) {
    return '评估已完成——$rate 通过';
  }

  @override
  String get evalsRunFailed => '无法运行该套件';

  @override
  String get evalsRun => '运行';

  @override
  String get evalsStatusQueued => '排队中';

  @override
  String get evalsStatusRunning => '运行中';

  @override
  String get evalsStatusPassed => '已通过';

  @override
  String get evalsStatusFailed => '已失败';

  @override
  String get bannerMeetingJoin => '加入';

  @override
  String get bannerMeetingRecordAndLink => '录制并链接';

  @override
  String get bannerCalendarReconnect => '重新连接';

  @override
  String get bannerView => '查看';

  @override
  String get soundscapeTitle => '声景';

  @override
  String get soundscapePlay => '播放';

  @override
  String get soundscapePause => '暂停';

  @override
  String get soundscapeMoodLabel => '氛围';

  @override
  String get soundscapeMoodFocus => '专注';

  @override
  String get soundscapeMoodRelax => '放松';

  @override
  String get soundscapeMoodSleep => '睡眠';

  @override
  String get soundscapeMoodRise => '上升';

  @override
  String get soundscapeVolumeLabel => '音量';

  @override
  String get soundscapeTuneLabel => '调音';

  @override
  String get soundscapeTuneMellow => '柔和';

  @override
  String get soundscapeTuneBright => '明亮';

  @override
  String get soundscapeTuneEnergetic => '活力';

  @override
  String get soundscapeTuneSpacy => '空灵';

  @override
  String get soundscapeTuneResetHint => '双击以重置';

  @override
  String get soundscapeSceneLabel => '正在播放';

  @override
  String get soundscapeSceneLoading => '正在调节氛围…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees°C';
  }

  @override
  String get soundscapeLocationLabel => '位置';

  @override
  String get soundscapeLocationDetecting => '正在检测位置…';

  @override
  String get soundscapeLocationAutoNote => '位置来自此设备。';

  @override
  String get soundscapeRefreshWeather => '刷新天气';

  @override
  String get soundscapeAutoStartLabel => '随专注模式启动';

  @override
  String get soundscapeAutoStartDescription => '开始专注会话时自动播放声景。';

  @override
  String get soundscapeReturnToApp => '返回应用';

  @override
  String get soundscapePopOut => '弹出播放器';

  @override
  String get discussion => '讨论';

  @override
  String get chat => '聊天';

  @override
  String get saving => '保存中…';

  @override
  String get saved => '已保存';

  @override
  String get saveFailed => '无法保存';

  @override
  String get commitAndPush => '提交并推送';

  @override
  String get commit => '提交';

  @override
  String get commitAmend => '提交（修正）';

  @override
  String get commitAndSync => '提交并同步';

  @override
  String get scmSyncChanges => '同步更改';

  @override
  String get scmPublishBranch => '发布分支';

  @override
  String get scmSyncFailed => '同步失败';

  @override
  String get scmSyncDirty => '同步前请提交或放弃更改';

  @override
  String get scmSynced => '已同步';

  @override
  String get scmPushRefused => '推送被拒绝';

  @override
  String get scmPulledPushRefused => '已拉取，但推送被拒绝';

  @override
  String get scmPushRefusedHint => '远程或钩子拒绝了这次更新';

  @override
  String get scmSelectBranch => '选择要检出的分支';

  @override
  String get scmCreateBranch => '创建新分支…';

  @override
  String get scmCreateBranchFrom => '从所选提交创建新分支…';

  @override
  String get scmCheckoutDetached => '分离头指针检出…';

  @override
  String get scmBranchName => '分支名称';

  @override
  String get scmCreateBranchTitle => '创建分支';

  @override
  String scmFromRef(String ref) {
    return '从 ⁨$ref⁩';
  }

  @override
  String get scmCheckoutFailed => '无法切换分支';

  @override
  String get scmCheckoutDirty => '切换分支前请提交或放弃更改';

  @override
  String scmSwitchedToBranch(String branch) {
    return '已切换到 ⁨$branch⁩';
  }

  @override
  String scmDetachedAt(String ref) {
    return '已分离到 ⁨$ref⁩';
  }

  @override
  String get scmDetachedHead => '分离的 HEAD';

  @override
  String get scmNoBranches => '没有匹配的分支';

  @override
  String get scmBranches => '分支';

  @override
  String get scmRemoteBranches => '远程分支';

  @override
  String get scmTags => '标签';

  @override
  String get scmPickStartPoint => '选择起点';

  @override
  String get scmSwitchBranch => '切换分支';

  @override
  String get scmPullConflictTitle => '拉取会产生冲突';

  @override
  String scmPullConflictBody(int count, String branch) {
    return '把 $count 个提交拉到 ⁨$branch⁩ 会和这份工作副本里的改动冲突。';
  }

  @override
  String get scmAskAi => '让 AI 处理';

  @override
  String scmResolveConflictPrompt(String branch, String repo, int count) {
    return '请拉取 ⁨$repo⁩ 里的 ⁨$branch⁩。它比上游落后 $count 个提交，拉取会和本地改动冲突。请解决冲突并完成拉取。';
  }

  @override
  String commitMessageOnBranch(String shortcut, String branch) {
    return '消息（$shortcut 提交到“$branch”）';
  }

  @override
  String get committed => '已提交';

  @override
  String get commitAmended => '提交已修正';

  @override
  String get commitFailed => '提交失败';

  @override
  String get moreCommitActions => '更多提交操作';

  @override
  String get sourceControl => '源代码管理';

  @override
  String fixFindingTitle(String location) {
    return '修复：$location';
  }

  @override
  String get openInEditor => '在编辑器中打开';

  @override
  String get regexTesterTitle => '测试正则表达式';

  @override
  String get regexTesterHint => '输入示例';

  @override
  String get regexMatch => '匹配';

  @override
  String get regexNoMatch => '无匹配';

  @override
  String get regexInvalidPattern => '无效模式';

  @override
  String get symbolLookupNone => '索引或此拉取请求中没有定义';

  @override
  String get symbolLookupInDiff => '在此拉取请求中找到';

  @override
  String get symbolLookupFromBase => '来自基础检出 — 此 PR 的工作树尚未建立索引';

  @override
  String get symbolImplementations => '实现';

  @override
  String symbolCallersCount(int count) {
    return '$count 个调用方';
  }

  @override
  String get commitMessageHint => '提交信息';

  @override
  String get pushedToPr => '已推送到 PR';

  @override
  String get pushFailed => '推送失败';

  @override
  String get reviewFindings => '发现项';

  @override
  String get treeLabel => '目录树';

  @override
  String get toggleFileTree => '显示或隐藏文件树';

  @override
  String get diffViewSettings => '差异视图设置';

  @override
  String get splitViewLabel => '分栏';

  @override
  String get unifiedViewLabel => '统一';

  @override
  String get wrapLines => '自动换行';

  @override
  String get shiftClickSelectRange => '按住 Shift 点击以选择范围';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个文件',
      one: '1 个文件',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc 行代码';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return '小型 PR——$files，审阅约需 $minutes 分钟';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return '中型 PR——$files，需预留约 $minutes 分钟审阅';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return '大型 PR——$files，建议审阅前拆分';
  }

  @override
  String get searchInFiles => '在文件中搜索';

  @override
  String get showFileList => '显示文件列表';

  @override
  String get searchInFilesHintField => '在文件中搜索…';

  @override
  String get searchInFilesHint => '在整个 pull request 的文件中搜索';

  @override
  String get searchInWholeRepo => '在整个仓库中搜索';

  @override
  String get searchInThisPullRequest => '在此 pull request 中搜索';

  @override
  String get searchNoResults => '未找到结果';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个结果',
      one: '1 个结果',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files 个文件',
      one: '1 个文件',
    );
    return '$_temp0，位于 $_temp1';
  }

  @override
  String get discardChangesTitle => '放弃更改？';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个文件',
      one: '1 个文件',
    );
    return '要将 $_temp0 放弃至 HEAD？此操作无法撤销。';
  }

  @override
  String get discardAll => '全部放弃';

  @override
  String get discardFailed => '放弃更改失败';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个文件',
      one: '1 个文件',
    );
    return '已放弃 $_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted 个文件',
      one: '1 个文件',
    );
    return '已放弃 $_temp0；跳过 $skipped 个（未跟踪）';
  }

  @override
  String get prWorktreeUnavailable => '工作区未就绪';

  @override
  String get prWorktreeUnavailableHint =>
      '准备 pull request 文件失败。请重新打开该 pull request 重试。';

  @override
  String get timestampRelativeLabel => '相对时间';

  @override
  String get timestampRawLabel => '时间戳';

  @override
  String get copyTimestamp => '复制时间戳';

  @override
  String get copiedTimestamp => '已复制时间戳';

  @override
  String get previewDeployment => '预览部署';

  @override
  String previewDeploymentTab(String site) {
    return '预览：$site';
  }

  @override
  String get askForReview => '请求审阅…';

  @override
  String get closePrsConfirmTitle => '关闭 pull request？';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '要关闭 $count 个 pull request 吗？',
      one: '要关闭 1 个 pull request 吗？',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已关闭 $count 个 pull request',
      one: '已关闭 1 个 pull request',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已指派 $count 个 pull request',
      one: '已指派 1 个 pull request',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已在 $count 个 pull request 上请求审阅',
      one: '已在 1 个 pull request 上请求审阅',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 项操作失败',
      one: '1 项操作失败',
    );
    return '$_temp0';
  }

  @override
  String get diagram => '图表';

  @override
  String get diagramViewSource => '查看源码';

  @override
  String get diagramHideSource => '隐藏源码';

  @override
  String diagramPreviewUnavailable(String reason) {
    return '图表预览不可用（$reason）';
  }

  @override
  String get planUnavailable => '计划不可用';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个步骤',
      one: '1 个步骤',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => '批准并运行';

  @override
  String get planStatusDraft => '草稿';

  @override
  String get planStatusProposed => '已提出';

  @override
  String get planStatusApproved => '计划已批准';

  @override
  String get planStatusRejected => '计划已拒绝';

  @override
  String get planStatusSuperseded => '计划已被取代';

  @override
  String planRevisionLabel(int revision) {
    return '修订 $revision';
  }

  @override
  String get adapterEnforcementTitle => '此适配器强制执行的内容';

  @override
  String get enforcementFiltersToolSurface => '由 Control Center 选择工具';

  @override
  String get enforcementInterceptsToolCalls => '每次调用在运行前都会被把关';

  @override
  String get enforcementObservesCompletionContract => '运行必须交付其成果物';

  @override
  String get enforcementNativeToolsInterceptable => '运行器自带的工具可见';

  @override
  String get enforcementInProcessToolsSandboxed => '进程内工具受沙箱约束';

  @override
  String get enforcementYes => '是';

  @override
  String get enforcementNo => '否';

  @override
  String get adapterEnforcementCaveats => '注意事项';

  @override
  String get enforcementSummaryModesEnforced => '模式已强制执行';

  @override
  String get enforcementSummaryModesNotEnforced => '模式未强制执行';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 项注意事项',
      one: '1 项注意事项',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      '只读模式并非结构性保障：Control Center 无法移除此运行器自带的工具。';

  @override
  String get caveatToolCallsNotIntercepted =>
      '没有运行前把关：只有 MCP 工具调用会经过 Control Center。';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      '运行器自带的文件和 shell 工具完全不经过 Control Center；OS 沙箱是它们之下唯一的底线。';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      '进程内文件工具在沙箱之外运行，因此工具面就是唯一的文件系统边界。';

  @override
  String get caveatCompletionContractUnobservable =>
      '对于结束时未产出成果物的运行，Control Center 无法提醒或将其判定为失败。';

  @override
  String get modeDegraded => '已降级';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return '$adapter 上的 $mode 模式仅依赖沙箱；智能体自带的文件工具不会被拦截。';
  }

  @override
  String get artifactUnavailable => '制品不可用';

  @override
  String artifactRevisionLabel(int count) {
    return '$count 个修订';
  }

  @override
  String get artifactShowMore => '显示更多';

  @override
  String get artifactShowLess => '收起';

  @override
  String get artifactCopy => '复制';

  @override
  String get artifactCopied => '已复制制品';

  @override
  String get artifactsTabLabel => '制品';

  @override
  String get artifactsEmptyTitle => '暂无制品';

  @override
  String get artifactsEmptyBody => '当智能体在此发布表格、图表或示意图时，它会显示在此列表中。';

  @override
  String get artifactRevisionPickerLabel => '修订';

  @override
  String get artifactRestoreRevision => '恢复此修订';

  @override
  String get artifactOpenInTab => '在标签页中打开';

  @override
  String get artifactTitleFallback => '制品';

  @override
  String get providerGenerationLabel => '生成默认值';

  @override
  String get providerGenerationHint =>
      '将字段留空即可使用端点自身的默认值。模型会公布自己的输出上限和采样参数配方；以其他值提供服务可能会降低其效果。';

  @override
  String get providerMaxTokensLabel => '最大输出 token 数';

  @override
  String get addModel => '添加模型';

  @override
  String get modelListTitle => '模型列表';

  @override
  String get railProvidersGroup => '提供商';

  @override
  String get railCustomProvidersGroup => '自定义提供商';

  @override
  String get editModelSettings => '编辑模型设置';

  @override
  String get modelIdLabel => '模型 ID';

  @override
  String get modelIdImmutableHint => '端点所服务的 id；列出后即固定。';

  @override
  String get contextWindowLabel => '上下文窗口';

  @override
  String get inputTypesLabel => '输入类型';

  @override
  String get outputTypesLabel => '输出类型';

  @override
  String get modalityText => '文本';

  @override
  String get modalityImage => '图像';

  @override
  String get modalityAudio => '音频';

  @override
  String get modalityVideo => '视频';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => '重置为自动';

  @override
  String get modelOverrideEdited => '已编辑';

  @override
  String get manualModelBadge => '手动添加';

  @override
  String get modelIdRequired => '请输入模型 id。';

  @override
  String get modelTokensInvalid => '请输入正整数 token 数。';

  @override
  String get removeModelAction => '移除模型';

  @override
  String removeModelConfirmTitle(String model) {
    return '移除 $model？';
  }

  @override
  String get removeModelConfirmBody => '该模型会从列表中移除，固定使用它的智能体会停止工作。提供商不受影响。';

  @override
  String get addModelProviderTitle => '添加模型提供商';

  @override
  String get addModelProviderDescription => '配置自定义 API 端点及其模型。';

  @override
  String get modelListEmptyHint => '尚未配置模型。添加模型后即可在聊天中使用。';

  @override
  String get addProviderModelsHint => '端点应答后会实时拉取模型列表。仅当端点无法自行列出模型时才需手动添加。';

  @override
  String get providerTemperatureLabel => '温度';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => '生成默认值已保存';

  @override
  String get providerGenerationInvalid =>
      '请检查数值：最大输出 token 数和 top-k 必须为正数，温度 0–2，top-p 0–1。';

  @override
  String get providerGenerationOverridden => '已覆盖';

  @override
  String get branchNotPushed => '未推送';

  @override
  String branchNotOnRemote(String branch) {
    return '“$branch”仅存在于当前对话';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub 从未见过此分支，因此 pull request 暂时无法使用它。发布会推送工作树中已有的提交——未提交的更改保持原样。';

  @override
  String get publishBranch => '发布分支';

  @override
  String branchPublished(String branch) {
    return '已将“$branch”发布到 origin';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return '分支已发布。$count 项未提交的更改未包含在内。';
  }

  @override
  String get composePrLoadingBranches => '正在从 GitHub 加载分支…';

  @override
  String get composePrBranchesFailed =>
      '无法从 GitHub 加载分支。请手动输入分支名称，或检查 GitHub 连接。';

  @override
  String get composePrSubtitleFromSpace => '使用当前对话的分支——如果 GitHub 尚未见过该分支，请先发布';

  @override
  String get obsTabInsights => '洞察';

  @override
  String get obsTabLive => '实时';

  @override
  String get obsTabQuality => '质量';

  @override
  String get obsTabUsage => '用量';

  @override
  String get obsUsageTotalTokens => '总 token 数';

  @override
  String get obsUsagePeakTokens => '峰值 token 数';

  @override
  String get obsUsageLongestSession => '最长会话';

  @override
  String get obsUsageCurrentStreak => '当前连续天数';

  @override
  String get obsUsageLongestStreak => '最长连续天数';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天',
      one: '1 天',
      zero: '0 天',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'Token 活动';

  @override
  String get obsUsageActivityModeLabel => 'Token 活动模式';

  @override
  String get obsUsageModeDaily => '每日';

  @override
  String get obsUsageModeWeekly => '每周';

  @override
  String get obsUsageModeCumulative => '累计';

  @override
  String get obsUsageTimeRange => '时间范围';

  @override
  String get obsUsageTrendTitle => '每日 token 趋势';

  @override
  String get obsUsageModelUsage => '模型用量';

  @override
  String get obsUsageTokensLabel => 'token';

  @override
  String get obsUsageNoActivity => '尚无 token 使用记录';

  @override
  String get obsUsageOtherModels => '其他';

  @override
  String obsUsageCellReadout(String date, String tokens) {
    return '$date · $tokens token';
  }

  @override
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  ) {
    return '从 $start 到 $end 的 token 活动。$activeDays 个活跃日。最繁忙的一天 $peak token。';
  }

  @override
  String get obsScreenSubtitle => '智能体实时控制、成本归因、配额与质量信号';

  @override
  String get obsRangeLast24h => '过去 24 小时';

  @override
  String get obsRangeLast7d => '过去 7 天';

  @override
  String get obsRangeLast30d => '过去 30 天';

  @override
  String get obsRangeAll => '全部时间';

  @override
  String get obsAddFilter => '添加筛选';

  @override
  String get obsFilterAgent => '智能体';

  @override
  String get obsFilterModel => '模型';

  @override
  String get obsFilterStatus => '状态';

  @override
  String get obsFilterRole => '角色';

  @override
  String get obsKpiTotalRuns => '总运行数';

  @override
  String get obsKpiTotalCost => '总成本';

  @override
  String get obsKpiErrorRate => '错误率';

  @override
  String get obsKpiCacheRate => '缓存率';

  @override
  String get obsKpiTokensPerSec => 'token/秒';

  @override
  String get obsKpiAvgLatency => '平均延迟';

  @override
  String get obsKpiTtft => '首 token 时间';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '较上一周期 $delta';
  }

  @override
  String get obsChartActivity => '活动';

  @override
  String get obsChartCost => '成本随时间变化';

  @override
  String get obsLegendRuns => '运行';

  @override
  String get obsLegendErrors => '错误';

  @override
  String get obsAgentsTitle => '智能体';

  @override
  String obsShowAllAgents(int count) {
    return '显示全部 $count 个智能体';
  }

  @override
  String get obsShowFewerAgents => '显示较少';

  @override
  String get obsRunsTitle => '运行';

  @override
  String get obsNoRunsInRange => '该范围内没有运行';

  @override
  String get obsColTime => '时间';

  @override
  String get obsColAgent => '智能体';

  @override
  String get obsColStatus => '状态';

  @override
  String get obsColModel => '模型';

  @override
  String get obsColDuration => '时长';

  @override
  String get obsColTokens => 'Token';

  @override
  String get obsColCost => '成本';

  @override
  String get obsColErrors => '错误';

  @override
  String get obsColRuns => '运行';

  @override
  String get obsColAvgLatency => '平均延迟';

  @override
  String get obsColLastActive => '最后活跃';

  @override
  String get obsStatusPending => '等待中';

  @override
  String get obsStatusRunning => '运行中';

  @override
  String get obsStatusCompleted => '已完成';

  @override
  String get obsStatusError => '错误';

  @override
  String get obsRosterLoadError => '无法加载智能体名册。';

  @override
  String get obsRosterEmpty => '暂无智能体';

  @override
  String get obsRosterEmptyDescription =>
      '派发一个智能体，它会实时出现在这里——状态、当前工具、token、成本。';

  @override
  String get obsKillAgent => '终止智能体';

  @override
  String get obsRosterTokensLabel => 'tok';

  @override
  String get obsCostByRoleTitle => '按角色的成本';

  @override
  String get obsCostByRoleSubtitle => '此工作区的支出分布，按智能体角色划分';

  @override
  String get obsRoleMain => '主智能体';

  @override
  String get obsRoleSubagents => '子智能体';

  @override
  String get obsRoleAdvisor => '顾问';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return '主智能体：$main · 子智能体：$sub · 顾问：$advisor';
  }

  @override
  String get obsTotal => '总计';

  @override
  String get obsTokenModelTitle => 'Token 构成（5 个维度）';

  @override
  String get obsTokenModelSubtitle => '此工作区消耗的所有 token，按维度划分';

  @override
  String get obsAxisInput => '输入';

  @override
  String get obsAxisOutput => '输出';

  @override
  String get obsAxisReasoning => '推理';

  @override
  String get obsAxisCacheRead => '缓存读取';

  @override
  String get obsAxisCacheWrite => '缓存写入';

  @override
  String get obsTotalTokens => '总 token 数';

  @override
  String get obsCacheDiscountNote => '缓存读取的 token 按折扣计费，因此成本远低于同量的新输入。';

  @override
  String get obsByModelTitle => '按模型';

  @override
  String get obsByModelSubtitle => '各模型的 token 与成本用量';

  @override
  String get obsNoModelUsage => '尚无模型用量记录。';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次运行',
      one: '1 次运行',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => '单次运行';

  @override
  String get obsPerRunSubtitle => '单次运行的典型 token 成本';

  @override
  String get obsMedianRunTokens => '运行 token 中位数';

  @override
  String get obsMedianRunTokensSub => '所有运行的中位值';

  @override
  String get obsRunsInWorkspace => '在此工作区中';

  @override
  String get obsCostShare => '成本占比';

  @override
  String get obsQuotaConfiguredLimits => '已配置的限额';

  @override
  String get obsQuotaConfiguredLimitsSubtitle => '对照你所设上限的用量，状态最差的排前面。';

  @override
  String get obsQuotaAddLimit => '添加限额';

  @override
  String get obsQuotaNoLimits => '尚未配置配额限额——添加一个即可对照上限跟踪用量。';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return '移除 $title 限额';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return '$duration 后重置 · $status';
  }

  @override
  String get obsQuotaUsageWindows => '用量窗口';

  @override
  String get obsQuotaUsageWindowsSubtitle => '所有提供商的观测用量，未应用上限。';

  @override
  String get obsQuotaNoUsage => '尚无用量记录。';

  @override
  String get obsQuotaTokensUsed => '已用 token';

  @override
  String get obsQuotaRequests => '请求数';

  @override
  String get obsQuotaUnitTokens => 'token';

  @override
  String get obsQuotaUnitRequests => '请求';

  @override
  String get obsQuotaUnitCost => '成本';

  @override
  String get obsQuotaAddLimitTitle => '添加配额限额';

  @override
  String get obsQuotaProviderLabel => '提供商';

  @override
  String get obsQuotaWindowLabel => '窗口';

  @override
  String get obsQuotaUnitLabel => '单位';

  @override
  String obsQuotaLimitLabel(String unit) {
    return '限额（$unit）';
  }

  @override
  String get obsQuotaCentsHint => '以美分计（500 = \$5.00）。';

  @override
  String get obsQuotaStatusOk => '正常';

  @override
  String get obsQuotaStatusWarning => '警告';

  @override
  String get obsQuotaStatusExhausted => '已耗尽';

  @override
  String get obsQuotaStatusUnknown => '未知';

  @override
  String get obsGoalNoActiveTitle => '没有进行中的目标';

  @override
  String get obsGoalNoActiveBody =>
      '设定目标可为智能体提供一个方向和可选的 token 预算。随着运行完成，预算使用量会不断累积；当预算接近耗尽时，智能体会收到收尾提醒。';

  @override
  String get obsGoalSetGoal => '设定目标';

  @override
  String get obsGoalTokenBudget => 'Token 预算';

  @override
  String obsGoalTokensLeft(String tokens) {
    return '剩余 $tokens';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens（未设预算）';
  }

  @override
  String get obsGoalTokensUsed => '已用 token';

  @override
  String get obsGoalElapsed => '已用时间';

  @override
  String get obsGoalWrapUp => '收尾';

  @override
  String get obsGoalClear => '清除目标';

  @override
  String get obsGoalFallbackTitle => '目标';

  @override
  String get obsGoalSubtitle => '目标模式预算';

  @override
  String get obsGoalStatusActive => '进行中';

  @override
  String get obsGoalStatusPaused => '已暂停';

  @override
  String get obsGoalStatusBudgetLimited => '受预算限制';

  @override
  String get obsGoalStatusComplete => '已完成';

  @override
  String get obsGoalStatusDropped => '已放弃';

  @override
  String get obsGoalObjectiveLabel => '目标描述';

  @override
  String get obsGoalBudgetLabel => 'Token 预算（可选）';

  @override
  String get obsGoalSetAction => '设定目标';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => '成功率';

  @override
  String get obsBenchmarkPassed => '已通过';

  @override
  String get obsBenchmarkFailed => '已失败';

  @override
  String get obsBenchmarkErrors => '错误';

  @override
  String get obsBenchmarkSpend => '花费';

  @override
  String get obsBenchmarkCostPerTask => '每任务成本';

  @override
  String get obsBenchmarkTrials => '试验';

  @override
  String get obsBenchmarkNoTrials => '尚无可评分的运行。';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还有 $count 项',
      one: '还有 1 项',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => '通过';

  @override
  String get obsBenchmarkTrialFail => '失败';

  @override
  String get obsBenchmarkTrialError => '错误';

  @override
  String get obsBenchmarkTrialRunning => '运行中';

  @override
  String get obsBenchmarkReward => '奖励';

  @override
  String get obsBenchmarkReport => '报告';

  @override
  String get obsBenchmarkCopyMarkdown => '复制 markdown';

  @override
  String get obsBenchmarkCopied => '报告已复制到剪贴板';

  @override
  String get obsBehaviorCaption =>
      '这些是从你自己的消息中解析出的挫败感信号——用于了解对话健康度，而不是给智能体打分。本地计算；不会有任何数据离开此设备。';

  @override
  String get obsBehaviorMessagesAnalyzed => '已分析消息数';

  @override
  String get obsBehaviorTotalSignals => '信号总数';

  @override
  String get obsBehaviorYelling => '吼叫';

  @override
  String get obsBehaviorProfanity => '脏话';

  @override
  String get obsBehaviorAnguish => '痛苦';

  @override
  String get obsBehaviorNegation => '否定';

  @override
  String get obsBehaviorRepetition => '重复';

  @override
  String get obsBehaviorBlame => '指责';

  @override
  String get obsBehaviorConversationsTitle => '挫败感最强的对话';

  @override
  String get obsBehaviorConversationsSubtitle => '按你消息中的信号密度排序。';

  @override
  String get obsBehaviorNoSignals => '未检测到挫败感信号——一切顺利。';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '已分析 $count 条消息';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count 个信号';
  }

  @override
  String get obsAgentStatusIdle => '空闲';

  @override
  String get obsAgentStatusParked => '已停驻';

  @override
  String get obsAgentStatusAborted => '已中止';

  @override
  String get obsAgentKindSub => '子';

  @override
  String get noChecksOnCommit => '此提交没有运行任何检查。';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '运行中——$count 个作业',
      one: '运行中——1 个作业',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '所有检查已通过——$count 个作业',
      one: '所有检查已通过——1 个作业',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已完成——$count 个作业',
      one: '已完成——1 个作业',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total 个作业',
      one: '1 个作业',
    );
    return '$_temp0中有 $failed 个失败';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个作业',
      one: '1 个作业',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return '矩阵：$jobId';
  }

  @override
  String get jobLogsPending => '作业完成后日志会显示在这里。';

  @override
  String get jobLogsUnavailable => '此作业的日志不可用。';

  @override
  String get noLogsForStep => '未捕获到此步骤的日志。';

  @override
  String get jobLogsTruncated => '日志已截断——显示最近的输出。';

  @override
  String get fullLog => '完整日志';

  @override
  String get copyLogs => '复制日志';

  @override
  String get resizeGraph => '拖动以调整图表大小';

  @override
  String workflowRunStartedAgo(String time) {
    return '开始于 $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return '完成于 $time';
  }

  @override
  String get chatBridgesTitle => '聊天桥接';

  @override
  String chatProviderDescription(String provider, String command) {
    return '在 $provider 中提及机器人即可让智能体接手事务，或使用 $command 提交工单。';
  }

  @override
  String chatConnectProvider(String provider) {
    return '连接 $provider';
  }

  @override
  String get chatDisconnectProvider => '断开连接';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$teamName 中的 $botName';
  }

  @override
  String get chatStateLive => '已连接';

  @override
  String get chatStateConnecting => '连接中…';

  @override
  String get chatStateError => '连接错误';

  @override
  String get chatNotConnected => '未连接';

  @override
  String chatStreamingUnavailable(String provider) {
    return '此 $provider 应用未开启实时流式传输——回复会作为一条消息送达。';
  }

  @override
  String chatAdminOnly(String provider) {
    return '只有管理员才能为此工作区连接 $provider。';
  }

  @override
  String chatConnectHint(String provider) {
    return '创建一个 $provider 应用，然后在此粘贴其凭据。Control Center 会主动连接 $provider，因此此服务器无需公共地址。';
  }

  @override
  String chatOpenConsole(String provider) {
    return '打开 $provider 控制台';
  }

  @override
  String get chatOpenSetupGuide => '设置指南';

  @override
  String get chatFieldBotToken => '机器人 token';

  @override
  String get chatFieldAppToken => '应用级 token';

  @override
  String get chatFieldConfigRefreshToken => '应用配置 token';

  @override
  String chatFieldOptional(String label) {
    return '$label（可选）';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return '关联我的 $provider 账户';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return '关联你的 $provider 账户后，你在那里发送的消息会归属到你名下。';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return '已关联到 $externalUserId';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return '关联你的 $provider 账户';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return '在 $provider 中向机器人发送此命令。它只能使用一次，15 分钟后过期。';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return '你的 $provider 账户已关联——你在那里发送的消息会归属到你名下。';
  }

  @override
  String get chatLinkedAccounts => '已关联账户';

  @override
  String chatNoLinkedAccounts(String provider) {
    return '尚无人关联 $provider 账户。';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个已关联账户',
      one: '1 个已关联账户',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · 按邮箱匹配';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · 通过代码关联';
  }

  @override
  String get chatUnlink => '取消关联';

  @override
  String get chatCustomizeBot => '自定义机器人';

  @override
  String get chatCustomizeBotDescription => '重命名机器人、修改其自我介绍，或重命名斜杠命令。';

  @override
  String get chatCustomizeBotUnavailable =>
      'Control Center 需要应用配置 token 才能编辑机器人。请重新连接并提供该 token。';

  @override
  String chatCreateAppTitle(String provider) {
    return '创建 $provider 应用';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center 可以为你创建 $provider 应用，并预先配置好权限和事件。你需要在 $provider 中完成最后步骤，然后在此粘贴凭据。';
  }

  @override
  String get chatCreateApp => '创建应用';

  @override
  String get chatCreateAppCta => '为我创建应用';

  @override
  String get chatAppNameLabel => '应用名称';

  @override
  String get chatBotDisplayNameLabel => '机器人名称（成员在 @ 后输入的内容）';

  @override
  String get chatDescriptionLabel => '简短描述';

  @override
  String get chatAgentDescriptionLabel => '机器人对自己能力的介绍';

  @override
  String get chatCommandLabel => '斜杠命令';

  @override
  String get chatDirectMessages => '私信';

  @override
  String chatDirectMessagesHint(String provider) {
    return '允许成员在私信中与机器人聊天。可能需要 $provider 付费套餐。';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$provider 已创建应用 $appId。';
  }

  @override
  String chatRemainingSteps(String provider) {
    return '还剩几个步骤，只能在 $provider 中完成：';
  }

  @override
  String get chatStepAppToken => '生成应用级 token';

  @override
  String get chatStepInstall => '安装应用';

  @override
  String get chatOpenAppSettings => '打开应用设置';

  @override
  String get chatContinueToCredentials => '粘贴凭据';

  @override
  String chatBotUpdated(String provider) {
    return '机器人已在 $provider 中更新。';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$provider 更改了应用权限。请重新安装应用使其生效。';
  }

  @override
  String get chatReinstallApp => '重新安装应用';

  @override
  String chatIconNotEditable(String provider) {
    return '机器人图标只能在 $provider 自身的应用设置中更改。';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return '你也可以自己在 $provider 中创建——无需 token。上述设置会随链接一并带上。';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return '在 $provider 中创建';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '浏览器中已打开 $provider，并预填了此配置。请在那里创建应用，完成这些步骤后带着 token 返回。';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider 不会报告它创建了哪个应用，因此之后需要应用配置 token 才能在此自定义机器人。';
  }

  @override
  String get chatStepCreateApp => '使用预填的配置创建应用';

  @override
  String chatStepCreateAppHint(String provider) {
    return '在 $provider 中选择一个工作区并确认。';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → 应用级 token，勾选 connections:write 权限。';

  @override
  String get chatStepInstallHint => 'Install app → 复制 bot user OAuth token。';

  @override
  String get calendarUseBuiltinApp => '使用 Control Center 的 Google 应用';

  @override
  String get calendarUseBuiltinAppHint =>
      '用你的 Google 账户授权即可。无需在 Google Cloud 中做任何设置。';

  @override
  String get calendarUseOwnClient => '使用我自己的 Google Cloud 客户端';

  @override
  String get calendarUseOwnClientHint => '输入来自你自己 Google Cloud 项目的 OAuth 客户端。';

  @override
  String get aboutTitle => '关于';

  @override
  String get aboutAppVersion => '应用版本';

  @override
  String get aboutServerVersion => '已连接的服务器';

  @override
  String get aboutRpcCatalog => 'RPC 目录';

  @override
  String get aboutServerUnknown => '未报告';

  @override
  String get serverStaleTitle => '内置服务器版本低于此应用';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return '正在运行的 cc_server 为 $serverVersion，而此应用为 $appVersion。请重启应用以加载最新内置服务器构建；在开发环境中，请在 apps/cc_server 中运行 `dart build cli` 重新构建。';
  }

  @override
  String get updateCheckButton => '检查更新';

  @override
  String get updateChecking => '正在检查更新…';

  @override
  String get updateUpToDate => '已是最新版本';

  @override
  String get updateDeferredBusy => '更新已就绪，但正在录制会议——会议结束后会再提示。';

  @override
  String get updateOpenedReleasesPage => '已在浏览器中打开发布页面。';

  @override
  String get updateCheckFailed => '检查更新失败';

  @override
  String updateAvailableVersion(String version) {
    return '版本 $version 可用。';
  }

  @override
  String get updateBannerTitle => '新版 Control Center 可用';

  @override
  String get updateBannerRefresh => '刷新';

  @override
  String get updateBlockedRecording => '会议录制期间刷新已暂停——结束后会自动重新加载。';

  @override
  String get settingsScopeYou => '你';

  @override
  String get settingsScopeWorkspace => '工作区';

  @override
  String get settingsScopeServer => '服务器';

  @override
  String get settingsProfile => '个人资料与身份';

  @override
  String get settingsYourDevices => '你的设备';

  @override
  String get settingsWorkspaceGeneral => '通用';

  @override
  String get settingsServerConnection => '连接与状态';

  @override
  String get settingsModelProviders => '模型提供商';

  @override
  String get settingsVoiceModels => '语音与会议模型';

  @override
  String get settingsDiagnostics => '诊断与隐私';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsScopeBadgeYou => '你';

  @override
  String get settingsScopeBadgeDevice => '本设备';

  @override
  String get settingsScopeBadgeWorkspace => '工作区';

  @override
  String get settingsScopeBadgeServer => '服务器';

  @override
  String get settingsProfileDescription =>
      '你在此工作区的姓名、电子邮件和 git 身份。切换工作区会切换此覆盖层；句柄、登录和设备仍在账户上。';

  @override
  String get settingsServerConnectionDescription =>
      '此客户端连接哪台服务器，以及此服务器如何共享（mDNS、隧道、中继）。';

  @override
  String get settingsAboutDescription => '构建标识与更新。';

  @override
  String get settingsDiagnosticsDescription => '此安装的隔离、索引、同步、日志与崩溃报告。';

  @override
  String get settingsWorkspaceGeneralDescription => '此工作区中所有人共享的身份、策略与约定。';

  @override
  String get settingsWorkspaceMeetingsDescription => '此工作区会议的笔记模板与已保存的声音。';

  @override
  String get settingsWorkspacePolicyLabel => '工作区策略';

  @override
  String get settingsWorkspacePolicyDescription => '适用于此工作区中的每个成员和每个智能体。';

  @override
  String get settingsSecretGlobsLabel => '敏感路径排除';

  @override
  String get settingsSecretGlobsHelp =>
      '每行一个 glob。除内置默认项外，这些路径还会在含代码的界面上对查看者和访客隐藏。';

  @override
  String get settingsReviewConcurrencyLabel => '审阅并发数';

  @override
  String get settingsReviewConcurrencyHelp => '未明确指定数量时并行派发多少个审阅者。';

  @override
  String get settingsReviewLevelLabel => '审阅级别';

  @override
  String get settingsReviewLevelHelp =>
      'AI 审阅的深入程度，以及一开始报告多少发现。任何内容都不会被丢弃——较轻的级别会把次要发现项归组，而不是直接省略。';

  @override
  String get reviewLevelLight => '轻量';

  @override
  String get reviewLevelBalanced => '均衡';

  @override
  String get reviewLevelThorough => '深入';

  @override
  String get reviewLevelLightHint => '单个审阅者。只在一开始报告真正重要的内容。';

  @override
  String get reviewLevelBalancedHint => '三个审阅者，分别负责 QA、架构与实现。';

  @override
  String get reviewLevelThoroughHint => '增加安全与性能专家，并报告所有发现。';

  @override
  String get askAiReviewAtLevel => '以其他级别审阅';

  @override
  String reviewNitpicksGroup(int count) {
    return '细枝末节（$count）';
  }

  @override
  String get reviewFindingResolve => '已修复';

  @override
  String get reviewFindingResolveHint => '将此发现项标记为已修复。它将不再计入审查。';

  @override
  String get reviewFindingDismiss => '驳回';

  @override
  String get reviewFindingDismissHint => '不是实际问题。审阅者将不再在以后的 PR 上标记此模式。';

  @override
  String get reviewFindingReopen => '重新打开';

  @override
  String get reviewFindingStatusUndoLabel => '发现项状态';

  @override
  String get reviewFindingDismissTitle => '驳回此发现项';

  @override
  String get reviewFindingDismissReasonHint => '为什么不适用？审阅者会阅读。';

  @override
  String reviewFindingStatusFailed(String error) {
    return '无法更新发现项：$error';
  }

  @override
  String get reviewStaleTitle => '此审查已过期';

  @override
  String get reviewStaleBody => '此审查运行后 pull request 又有更新。发现项可能指向已不存在的代码。';

  @override
  String reviewStaleReviewedAt(String sha) {
    return '审阅于 $sha';
  }

  @override
  String get reviewStaleRerun => '再次审阅';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return '#$prNumber 上的审查已过期';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return '$title 在上次审查后有了新提交。';
  }

  @override
  String get reviewCategorySecurity => '安全';

  @override
  String get reviewCategoryStability => '稳定性';

  @override
  String get reviewCategoryDataIntegrity => '数据完整性';

  @override
  String get reviewCategoryCorrectness => '正确性';

  @override
  String get reviewCategoryPerformance => '性能';

  @override
  String get reviewCategoryMaintainability => '可维护性';

  @override
  String get reviewEffortQuickWin => '轻松修复';

  @override
  String get reviewEffortModerate => '中等';

  @override
  String get reviewEffortHeavyLift => '大工程';

  @override
  String get reviewProposedFix => '建议的修复';

  @override
  String get reviewAiAgentPrompt => '给 AI 智能体的提示词';

  @override
  String get reviewCopyAiPrompt => '复制提示词';

  @override
  String get settingsWorkspaceAdminOnly => '只有工作区管理员才能更改这些设置。';

  @override
  String get chatMyAccountsTitle => '已关联的聊天账户';

  @override
  String get settingsServerSso => '单点登录';

  @override
  String get settingsServerSsoDescription => 'SAML 与 OpenID Connect 登录及用户预配';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription => '用户可以使用此提供商登录';

  @override
  String get ssoEnabledDescriptionOn => '此提供商的登录已启用';

  @override
  String get ssoIdpMetadataLabel => 'IdP 元数据 XML';

  @override
  String get ssoIdpMetadataHint => '粘贴 IdP 的 EntityDescriptor XML';

  @override
  String get ssoEmailAttributeLabel => '邮箱属性';

  @override
  String get ssoDisplayNameAttributeLabel => '显示名称属性';

  @override
  String get ssoGroupsAttributeLabel => '组属性';

  @override
  String get ssoIssuerLabel => '签发者 URL';

  @override
  String get ssoClientIdLabel => '客户端 ID';

  @override
  String get ssoGroupsClaimLabel => '组 claim';

  @override
  String get ssoAutoMemberLabel => '首次登录时将用户加入每个工作区';

  @override
  String get ssoAutoMemberDescription => '关闭后每个工作区都需要邀请';

  @override
  String get ssoAllowJitLabel => '首次登录时预配未知用户';

  @override
  String get ssoAllowJitDescription => '关闭后将拒绝没有现有账户的用户';

  @override
  String get ssoAllowIdpInitiatedLabel => '接受未经请求的（IdP 发起的）登录';

  @override
  String get ssoAllowIdpInitiatedDescription => '仅适用于直接启动应用的 IdP 门户';

  @override
  String get ssoWantResponseSignedLabel => '要求签名的响应信封';

  @override
  String get ssoWantResponseSignedDescription => '断言签名始终是必需的';

  @override
  String get ssoTestConnectionButton => '测试连接';

  @override
  String get ssoTestConnectionOk => '连接正常：';

  @override
  String get ssoCopySpMetadata => '复制 SP 元数据';

  @override
  String get ssoCopySpMetadataDone => 'SP 元数据已复制到剪贴板';

  @override
  String get ssoSavedToast => '单点登录设置已保存';

  @override
  String get ssoUnavailable => '此服务器未提供单点登录设置。请更新服务器二进制文件后重试。';

  @override
  String get ssoScimCardTitle => '用户预配（SCIM）';

  @override
  String get ssoScimDescription =>
      '将你身份提供商的 SCIM 连接器指向下方端点并使用 bearer token。取消预配会在数秒内吊销会话和工作区访问权限。IdP 必须能够访问此服务器（隧道或公共 URL）。';

  @override
  String get ssoScimEndpoint => 'SCIM 端点';

  @override
  String get ssoScimEndpointUnknownOrigin => '请先设置服务器的公共 URL 或启用隧道';

  @override
  String get ssoScimRegenerate => '重新生成 token';

  @override
  String get ssoScimRegenerateConfirm =>
      '生成新的 SCIM bearer token？旧 token 将立即失效。';

  @override
  String get ssoScimTokenTitle => 'Bearer token';

  @override
  String get ssoScimTokenPresent => '已配置 token';

  @override
  String get ssoScimTokenAbsent => '尚无 token——生成一个即可启用 SCIM';

  @override
  String get ssoScimTokenOnce => 'SCIM token（仅显示一次）';

  @override
  String ssoSignInWith(String provider) {
    return '使用 $provider 登录';
  }

  @override
  String get ssoProbeFailed => '无法连接该服务器进行单点登录';

  @override
  String get ssoOpensBrowser => '将打开浏览器完成登录';

  @override
  String get ssoWaitingForBrowser => '等待浏览器完成登录…';

  @override
  String get ssoBrowserOpenFailed => '无法打开浏览器进行单点登录';

  @override
  String get ssoUseManualPairing => '改用邀请码或配对密钥登录';

  @override
  String get ssoHideManualPairing => '隐藏手动配对';

  @override
  String get ssoClientIdHint => '公共（PKCE）客户端——无需密钥';

  @override
  String get ssoClientSecretLabel => '客户端密钥（可选）';

  @override
  String get ssoClientSecretHintUnset => '仅机密 IdP 客户端需要';

  @override
  String get ssoClientSecretHintSet => '已存储密钥——留空即保持不变';

  @override
  String get ssoPairingToggle => '允许手动配对（邀请码和配对密钥）';

  @override
  String get ssoPairingToggleDescription =>
      '关闭后加入将仅限单点登录——新设备通过 SSO 登录加入；现有设备继续可用';

  @override
  String get ssoPairConfirmTitle => '连接到服务器？';

  @override
  String ssoPairConfirmBody(String server) {
    return '收到了 $server 的登录凭据，但此应用并未发起登录。要连接到此服务器吗？';
  }

  @override
  String get ssoPairConfirmConnect => '连接';

  @override
  String get ssoPairConfirmCancel => '忽略';

  @override
  String get forgeConnections => '代码托管';

  @override
  String get connect => '连接';

  @override
  String get disconnect => '断开连接';

  @override
  String get notConnected => '未连接';

  @override
  String get checkingConnection => '正在检查连接…';

  @override
  String get fromEnvironment => '来自环境';

  @override
  String forgeTokenTitle(String forge) {
    return '$forge token';
  }

  @override
  String get settingsAudio => '音频';

  @override
  String get settingsAudioDescription => '麦克风、听写、会议检测与声景输出。';

  @override
  String get audioDevicesSection => '音频设备';

  @override
  String get voiceInputBehaviorSection => '听写与会议';

  @override
  String get audioOutputDeviceTitle => '输出设备';

  @override
  String get audioOutputDefaultHint => '所有应用声音通过系统默认输出播放。';

  @override
  String get audioOutputGone => '所选输出设备已断开——在你另行选择之前将使用系统默认输出。';

  @override
  String get reviewHubIntroBody => '智能体会分析差异、梳理变更区域并得出一致结论。';

  @override
  String get reviewHubAlreadyRunning => '此 pull request 已有审查正在运行';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return '自上次审查以来：$resolved 项已解决 · $added 项新增 · $open 项仍未解决';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return '上次审查于 $sha';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return '修复 $count 个发现项';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return '修复所选 $count 项';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return '对所选 $count 项评论';
  }

  @override
  String get webConnectTitle => '连接到 Control Center';

  @override
  String get webConnectSubtitle =>
      '通过 WebSocket 连接到正在运行的 cc-server。你的密钥保留在此设备上。';

  @override
  String get webConnectServerLabel => '服务器';

  @override
  String get webConnectDeviceIdLabel => '设备 ID';

  @override
  String get webConnectPairingKeyLabel => '配对密钥';

  @override
  String get webConnectPairingKeyHint => '粘贴 PSK';

  @override
  String get webConnectStayConnected => '在此设备上保持连接';

  @override
  String get webConnectStayConnectedDetail => '在此设备上保持连接（将你的密钥存储在此浏览器中）';

  @override
  String failedToCreateWorkspace(String error) {
    return '创建工作区失败：$error';
  }

  @override
  String committedRelative(String relative) {
    return '提交于 $relative';
  }

  @override
  String get selectAgents => '选择智能体';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个智能体',
      one: '1 个智能体',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => '新对话';

  @override
  String get untitledConversation => '未命名对话';

  @override
  String get conversationTitleOptionalHint => '可选——留空则由标题模型自动命名';

  @override
  String get conversationTitlesSectionTitle => '对话标题';

  @override
  String get conversationTitlesSectionCaption =>
      '选择在此工作区中自动为新对话命名的运行器。在选择适配器之前标题保持关闭，且对所有成员生效。';

  @override
  String get conversationTitlesModelLabel => '标题模型';

  @override
  String get conversationTitlesAdapterLabel => '适配器';

  @override
  String get conversationTitlesAdapterHint => '关';

  @override
  String get conversationTitlesAdapterOff => '关闭';

  @override
  String get startThread => '发起话题';

  @override
  String get deleteSpaceConfirm => '删除此空间？所有消息都将丢失。';

  @override
  String threadTabTitle(String title) {
    return '话题：$title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条回复',
      one: '1 条回复',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return '最后回复于 $time';
  }

  @override
  String signInWithProvider(String provider) {
    return '使用 $provider 登录';
  }

  @override
  String get signInAgain => '重新登录';

  @override
  String get signInNotFinished => '登录尚未返回。请在浏览器中完成后再检查。';

  @override
  String get signedOutTitle => '你已退出登录';

  @override
  String get signedOutSubtitle =>
      '你的代码托管连接已失效——token 过期，或其访问权限被吊销。其他内容没有变化：重新登录后一切都在原处。';

  @override
  String get viaServerApp => '通过此服务器的应用';

  @override
  String get ticketing => '工单系统';

  @override
  String get ticketingProviderHelp => '你的工单存放在哪里。本地模式将其保留在 Control Center 中。';

  @override
  String providerComingSoon(String provider) {
    return '$provider（即将推出）';
  }

  @override
  String get ticketProviderLocal => '本地';

  @override
  String get addKey => '添加密钥';

  @override
  String get providerApps => '提供商应用';

  @override
  String get providerAppsDescription =>
      '工作区继承此 GitHub App，除非选择其他 App 或仅使用个人访问令牌。后台工作——webhook、轮询、同步——在应用上运行，绝不用个人令牌。';

  @override
  String get providerAppId => '应用 ID';

  @override
  String get providerPrivateKey => '私钥';

  @override
  String get providerClientId => '客户端 ID';

  @override
  String get providerClientSecret => '客户端密钥';

  @override
  String get providerApiKey => 'API 密钥';

  @override
  String get providerCallbackUrl => '回调 URL';

  @override
  String get providerAppFullyConfigured => '服务器可以自身身份行事，且个人可以登录。';

  @override
  String get providerAppServerOnly => '服务器可以自身身份行事。添加客户端 ID 和密钥即可让个人登录。';

  @override
  String get providerAppSignInOnly => '个人可以登录。后台工作回退到他们的凭据。';

  @override
  String providerAppInstalledOn(String accounts) {
    return '凭据有效。安装于：$accounts';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return '在刚打开的 $provider 页面上输入此代码。它已复制到你的剪贴板。';
  }

  @override
  String get deviceCodeWaiting => '等待你在浏览器中完成操作…';

  @override
  String get copyCodeAndOpen => '复制代码并打开';

  @override
  String get couldNotOpenBrowser => '无法打开浏览器。请复制链接并自行完成登录。';

  @override
  String get contextUsage => '上下文用量';

  @override
  String get contextUsageFull => '已使用';

  @override
  String get contextUsageTokens => 'token';

  @override
  String get contextSeeMore => '查看更多';

  @override
  String get contextSegmentSystemPrompt => '系统提示词';

  @override
  String get contextSegmentRules => '规则';

  @override
  String get contextSegmentSkills => '技能';

  @override
  String get contextSegmentToolDefinitions => '工具定义';

  @override
  String get contextSegmentMcpTools => 'MCP 与动态工具';

  @override
  String get contextSegmentDeferredTools => '按需加载的工具';

  @override
  String get contextSegmentSubagents => '子智能体定义';

  @override
  String get contextSegmentMemory => '记忆';

  @override
  String get contextSegmentConversation => '对话';

  @override
  String get contextExplorerTitle => '上下文';

  @override
  String get contextExplorerEverything => '全部';

  @override
  String get contextExplorerSelectPart => '选择一个部分以查看其内容';

  @override
  String get contextExplorerUnavailable => '上下文细分不可用';

  @override
  String get contextRetry => '重试';

  @override
  String get settingsFieldOptional => '可选';

  @override
  String get settingsFilterHint => '筛选此列表';

  @override
  String get settingsValueNotAvailable => '尚不可用';

  @override
  String get settingsNoEntriesYet => '这里还没有内容';

  @override
  String get settingsChangedBadge => '已更改';

  @override
  String get ssoConnectionCardDescription => '选择人们登录此服务器的方式，然后启用该连接。';

  @override
  String get ssoUseSamlForSignIn => '使用 SAML 登录';

  @override
  String get ssoUseOidcForSignIn => '使用 OpenID Connect 登录';

  @override
  String get ssoSaveConnection => '保存连接';

  @override
  String get ssoStateLive => '已启用';

  @override
  String get ssoStateConfiguredOff => '已配置，未启用';

  @override
  String get ssoStateOnIncomplete => '已启用，不完整';

  @override
  String get ssoStateActive => '活跃';

  @override
  String get ssoStateAllowed => '允许';

  @override
  String get ssoStateNoToken => '无 token';

  @override
  String get ssoSummaryDirectorySync => '目录同步';

  @override
  String get ssoSummaryManualPairing => '手动配对';

  @override
  String get ssoNoMethodLiveNote => '尚无已启用的登录方式。在你配置并启用连接之前，新设备通过邀请码或配对密钥加入。';

  @override
  String get ssoMethodSamlBlurb =>
      '适用于支持 SAML 2.0 的身份提供商，如 Okta、Entra ID 或 Google Workspace。';

  @override
  String get ssoMethodOidcBlurb => '适用于支持 OpenID Connect 的身份提供商。通常是两者中较易设置的一个。';

  @override
  String get ssoGroupIdentityProvider => '身份提供商';

  @override
  String get ssoGroupIdentityProviderSamlDescription => '断言来自哪里，以及此服务器如何验证它们。';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      '此服务器信任哪个签发者，以及它以哪个客户端身份进行认证。';

  @override
  String get ssoSpEntityIdShortLabel => 'SP 实体 ID';

  @override
  String get ssoSpEntityIdDescription => '留空则从服务器 URL 派生。';

  @override
  String get ssoIssuerDescription => '提供该提供商发现文档的基础 URL。';

  @override
  String get ssoSecretStored => '已存储';

  @override
  String get ssoGroupHandoff => '你的身份提供商需要的内容';

  @override
  String get ssoGroupHandoffDescription => '将这些粘贴到你在提供商处创建的应用中。';

  @override
  String get ssoOriginUnknownTitle => '此服务器不知道自己的公共 URL';

  @override
  String get ssoOriginUnknownBody =>
      '登录和回调 URL 都基于它生成，因此在设置之前你的提供商无法访问此服务器。请在“服务器 → 连接”下添加公共 URL 或启用隧道。';

  @override
  String get ssoAcsUrlLabel => '断言消费服务（ACS）URL';

  @override
  String get ssoAcsUrlDescription => '你的提供商发布签名断言的地址。';

  @override
  String get ssoSpEntityIdResolvedLabel => '服务提供商实体 ID';

  @override
  String get ssoMetadataUrlLabel => 'SP 元数据 URL';

  @override
  String get ssoMetadataUrlDescription => '支持导入元数据的提供商可以改从此处获取。';

  @override
  String get ssoRedirectUriLabel => '重定向 URI';

  @override
  String get ssoRedirectUriDescription => '将此添加到你的提供商应用的允许重定向 URI 中。';

  @override
  String get ssoSignInUrlLabel => '登录 URL';

  @override
  String get ssoSignInUrlDescription => '让人们访问此地址以开始单点登录。';

  @override
  String get ssoGroupAttributeMapping => '属性映射';

  @override
  String get ssoGroupAttributeMappingDescription =>
      '每个字段由哪个 claim 承载。除非你的提供商重命名了它们，否则保留默认值。';

  @override
  String get ssoGroupAccess => '访问与角色';

  @override
  String get ssoGroupAccessDescription => '成功登录的人被允许做什么。';

  @override
  String get ssoDefaultRoleShortLabel => '默认角色';

  @override
  String get ssoDefaultRoleDescription => '授予组与下方任何映射都不匹配的人。';

  @override
  String get ssoRoleMapShortLabel => '组到角色的映射';

  @override
  String get ssoRoleMapDescription => '第一个匹配的组生效。所有者角色无法通过此方式授予。';

  @override
  String get ssoRoleMapGroupHint => '来自你提供商的组名称';

  @override
  String get ssoRoleMapAdd => '添加映射';

  @override
  String get ssoRoleMapEmpty => '暂无映射——所有人都获得默认角色。';

  @override
  String get ssoAdvancedSummary => '时钟偏差、IdP 发起的登录、签名策略';

  @override
  String get ssoClockSkewShortLabel => '时钟偏差';

  @override
  String get ssoClockSkewDescription => '断言时间戳的容忍秒数。90 适合大多数提供商。';

  @override
  String get ssoScimGenerate => '生成 token';

  @override
  String get ssoScimTokenOnceBody => '已复制到剪贴板。它仅显示一次且无法恢复，请立即粘贴到你的提供商处。';

  @override
  String get ssoPairingCardTitle => '手动配对';

  @override
  String get ssoPairingCardDescription => '进入此服务器的另一种方式：邀请码和配对密钥，供不走单点登录的设备使用。';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count/$total';
  }

  @override
  String get providersNoneConnectedNote =>
      '尚未连接任何提供商，因此内置智能体运行时没有可运行的平台。请在下方添加 API 密钥或登录某一提供商。';

  @override
  String get providersFilterHint => '筛选提供商';

  @override
  String get providersNoneMatch => '没有符合此筛选条件的内容';

  @override
  String get providerDeniedHereTitle => '在此工作区中被拒绝';

  @override
  String get providerDeniedHereBody => '即使此提供商已连接，此处的智能体也无法使用它。其他工作区不受影响。';

  @override
  String get providerNeedsSignIn => '登录以使用此提供商';

  @override
  String get providerNeedsApiKey => '添加 API 密钥以使用此提供商';

  @override
  String get providerApiKeyLabel => 'API 密钥';

  @override
  String get providerGenerationDefaults => '提供商默认值';

  @override
  String get providerNoModelsYet => '尚未报告模型。请连接提供商后同步。';

  @override
  String get providerModelsFilterHint => '筛选模型';

  @override
  String get adaptersNoneReadyNote => '未在此机器上找到目录中的任何运行器 CLI。请先安装一个，然后刷新。';

  @override
  String get adaptersFilterHint => '筛选运行器';

  @override
  String get adaptersLaunchGroup => '启动';

  @override
  String get adaptersLaunchGroupDescription =>
      '智能体启动此运行器时传递给它的内容。可以在安装 CLI 之前先设置好。';

  @override
  String get adaptersEnvNone => '未设置';

  @override
  String adaptersEnvCount(int count) {
    return '已设置 $count 项';
  }

  @override
  String get adapterArgumentsDescription => '每次启动时追加到运行器的命令行。';

  @override
  String get defaultChatDescription => '运行新对话，以及任何没有专属运行器的智能体。';

  @override
  String get shortTaskDescription => '运行标题、摘要等快速后台工作。较小的模型适合放在这里。';

  @override
  String get settingsStateFailed => '失败';

  @override
  String get providerAppsGroupServer => '以服务器身份行事';

  @override
  String get providerAppsGroupServerDescription =>
      '供继承此安装 GitHub App 的工作区使用。使用自己的 App 或 PAT 的工作区在工作区 → 常规中配置。';

  @override
  String get providerAppsGroupPrConversations => 'Pull request 对话';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      '继承工作区中开发者如何在 GitHub 上与此服务器对话。拥有自己 App 的工作区在工作区 → 常规下有自己的机器人。无需 webhook 或公开 URL——由服务器轮询。';

  @override
  String get providerAppBotLogin => '机器人登录名';

  @override
  String get providerAppBotLoginEmpty => '测试连接以解析机器人登录名。';

  @override
  String get providerAppAskOnGitHub => '在 GitHub 上提问';

  @override
  String get providerAppAskOnGitHubHint =>
      '在 pull request 评论中提及上面的机器人登录名——[bot] 后缀可省略——以请求审查或提问，在其审查话题内回复，或添加 `ai-review` 标签以请求审查。';

  @override
  String get providerAppsGroupSignIn => '为个人提供登录';

  @override
  String get providerAppsGroupSignInDescription => '让每个成员连接自己的账户并获得自己的凭据。';

  @override
  String get providerAppCapActsAsServer => '以服务器身份行事';

  @override
  String get providerAppCapSignsIn => '为个人提供登录';

  @override
  String get portLabel => '端口';

  @override
  String get mcpNoTokenWarning => '如果没有 token，任何能访问此端口的东西都可以调用所有工具。';

  @override
  String get mcpBridgedToolsLabel => '工具';

  @override
  String get guardrailFamilyFiles => '文件';

  @override
  String get guardrailFamilyGit => 'Git 与 pull request';

  @override
  String get guardrailFamilyMachine => '机器与网络';

  @override
  String get guardrailFamilyControl => '机密与工作区';

  @override
  String get guardrailScopeFieldLabel => '正在编辑以下范围的规则';

  @override
  String get guardrailScopeFieldDescription =>
      '较窄的范围优先于较宽的范围。此处设置的规则叠加在继承的规则之上。';

  @override
  String get guardrailSetHere => '已在此设置';

  @override
  String get guardrailClearAllHere => '全部清除';

  @override
  String get sandboxingCardLabel => '沙箱';

  @override
  String get sandboxingCardDescription => '智能体的工作是否与主机隔离运行，以及被隔离的智能体仍能访问什么。';

  @override
  String get sandboxBackendNoneActive => '主机，无隔离';

  @override
  String get sandboxSummaryHost => '主机';

  @override
  String get sandboxGroupIsolation => '隔离';

  @override
  String get sandboxGroupIsolationDescription => '智能体的进程和文件写入实际发生的位置。';

  @override
  String get sandboxBackendFieldDescription =>
      '自动会选择此主机支持的最强方案。固定一个可防止它在你使用期间变化。';

  @override
  String get sandboxCapabilitiesDescription =>
      '边界上打通的孔洞。每一项都是被隔离的智能体仍能对外部世界做的事情。';

  @override
  String get sandboxSummaryInForce => '生效中';

  @override
  String get rigsInstallHintLabel => '如何安装';

  @override
  String get rigsStarting => '启动中';

  @override
  String get rigsResidentMemory => '常驻内存';

  @override
  String get installedLabel => '已安装';

  @override
  String get notInstalledLabel => '未安装';

  @override
  String ssoOtherKindUnsaved(String method) {
    return '$method 有未保存的更改';
  }

  @override
  String get collapseComment => '折叠评论';

  @override
  String get expandComment => '展开评论';

  @override
  String get suggestedChange => '建议的更改';

  @override
  String get emptyComment => '空评论';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条回复',
      one: '1 条回复',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => '待提交的审查';

  @override
  String failedToResolveConversation(String error) {
    return '无法更新对话：$error';
  }

  @override
  String get addSingleComment => '添加单条评论';

  @override
  String get addToReview => '添加到审查';

  @override
  String get startAReview => '开始审查';

  @override
  String get reviewNeedsABody => '请先撰写总结或排队一条行内评论';

  @override
  String get reviewSubmitted => '审查已提交';

  @override
  String get finishYourReview => '完成你的审查';

  @override
  String get commentVerdict => '评论';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条待提交评论',
      one: '1 条待提交评论',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return '以及另外 $count 项';
  }

  @override
  String get queuedCommentHint => '此评论将在你提交审查时发出。';

  @override
  String commentOnLinesRange(int start, int end) {
    return '第 $start 行到第 $end 行';
  }

  @override
  String get claudeAccountsTitle => 'Claude Code 账户';

  @override
  String get claudeAccountsDescription =>
      '每个账户是一个独立的 Claude Code 登录。运行按以下顺序使用所附账户。';

  @override
  String get claudeAccountsEmpty => '暂无账户';

  @override
  String get claudeAccountAdd => '添加账户';

  @override
  String get claudeAccountSignIn => '登录';

  @override
  String get claudeAccountSignInAgain => '重新登录';

  @override
  String get claudeAccountSignInHint =>
      '在服务器上的终端中运行此命令。它会打开浏览器完成登录，并将凭据写入此账户的目录。';

  @override
  String get claudeAccountSignedOut => '已退出登录';

  @override
  String get claudeAccountExpired => '登录已过期';

  @override
  String claudeAccountExpiredDetail(String when) {
    return '登录已于 $when 过期。请重新登录以使用此账户。';
  }

  @override
  String get claudeAccountMakeDefault => '设为默认';

  @override
  String get claudeAccountDefault => '默认';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return '移除 $label？';
  }

  @override
  String get claudeAccountRemoveDetail => '这会使该账户退出登录并删除其在服务器上的目录。登录本身不受影响。';

  @override
  String claudeAccountStatusUnknown(String error) {
    return '无法检查此账户：$error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return '已使用 $percent%';
  }

  @override
  String get accountPoolStrategy => '轮换';

  @override
  String get accountPoolPinned => '固定';

  @override
  String get accountPoolRoundRobin => '轮转';

  @override
  String get accountPoolSerial => '逐个使用';

  @override
  String get accountPoolPinnedHint => '始终从第一个账户开始。其余账户在其失败时作为后备。';

  @override
  String get accountPoolRoundRobinHint => '将运行分散到各账户，每次派发切换到下一个。';

  @override
  String get accountPoolSerialHint => '先用尽第一个账户，再动下一个。';

  @override
  String get accountPoolMoveUp => '上移';

  @override
  String get accountPoolMoveDown => '下移';

  @override
  String get accountPoolUsingAll => '尚未单独附加——将按此顺序使用所有账户。';

  @override
  String get accountPoolInheriting => '继承工作区的账户。';

  @override
  String get accountPoolResetToWorkspace => '重置为工作区的账户';

  @override
  String accountPoolCoolingOff(String when) {
    return '配额耗尽，直到 $when';
  }

  @override
  String get accountPoolSignedOut => '已退出登录';

  @override
  String get accountPoolExpired => '登录已过期';

  @override
  String accountPoolLoadFailed(String error) {
    return '无法加载轮换：$error';
  }

  @override
  String get providerSignedInAccount => '已登录账户';

  @override
  String get agentAccountsTab => '账户';

  @override
  String get agentClaudeAccountsNoticeTitle => '多个 Claude Code 账户';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return '此运行器会以此主机上 $count 个 Claude Code 账户之一登录。请在“账户”标签页中选择其一，或在它们之间轮换。';
  }

  @override
  String get agentAccountsDescription => '此智能体的运行使用哪些账户。每个区块初始继承工作区的选择。';

  @override
  String get agentAccountsNothingToRotate => '没有可轮换的内容——请先连接第二个账户或密钥。';

  @override
  String failedToPostReply(String error) {
    return '无法发布回复：$error';
  }

  @override
  String commentOnLine(int line) {
    return '第 $line 行';
  }

  @override
  String get viewInDiff => '在差异中查看';

  @override
  String get subscriptionUsagePreviousAccount => '上一个账户';

  @override
  String get subscriptionUsageNextAccount => '下一个账户';

  @override
  String inReplyTo(String path) {
    return '回复 $path';
  }

  @override
  String get subscriptionUsageNoneReported => '此账户没有报告用量。';

  @override
  String get subscriptionUsageCredits => '额度';

  @override
  String get reviewHubStaticRule => '静态规则';

  @override
  String get reviewHubStarted => '审查已开始';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return '由确定性规则（$rule）在此 pull request 新增的某一行上发现——并非由审阅智能体发现。';
  }

  @override
  String get prReviewArtifactTab => 'PR 审查';

  @override
  String get prReviewRunning => '正在审查此 pull request…';

  @override
  String get prReviewStarting => '正在开始审查…';

  @override
  String get prReviewStartingBody => '正在准备此 pull request 的工作树。就绪后审阅者立即开始。';

  @override
  String get prReviewFailed => '审查失败。';

  @override
  String get prReviewRerunning => '正在重新审查…';

  @override
  String get prReviewNoOpenFindings => '没有未解决的发现项';

  @override
  String prReviewOpenFindings(int count) {
    return '$count 个未解决的发现项';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used/$limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return '已以机器人身份发布 $posted 条评论。跳过 $skipped 条（无文件锚点），失败 $failed 条。';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count 个发现项指向此 pull request 未更改的代码（$files）。GitHub 只接受差异上的行内评论。';
  }

  @override
  String get reviewRailReport => '报告';

  @override
  String get reviewNoFindingsTitle => '暂无审查发现项';

  @override
  String get reviewNoFindingsHint => '智能体发布发现项后，它们会显示在这里。';

  @override
  String reviewShowDismissed(int count) {
    return '显示 $count 个已驳回项';
  }

  @override
  String reviewHideDismissed(int count) {
    return '隐藏 $count 个已驳回项';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '检测到 $count 处审阅者分歧',
      one: '检测到 1 处审阅者分歧',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => '类型';

  @override
  String get reviewFilterStatus => '状态';

  @override
  String get reviewKindBug => 'Bug';

  @override
  String get reviewKindSuggestion => '建议';

  @override
  String get reviewKindRecommendation => '推荐';

  @override
  String get reviewKindQuestion => '问题';

  @override
  String get reviewKindTicket => '工单';

  @override
  String get archiveSpace => '归档空间';

  @override
  String get archivedSpaces => '已归档空间';

  @override
  String get archivedSpacesEmpty => '没有已归档空间';

  @override
  String get restoreSpace => '恢复';

  @override
  String archivedWhen(String time) {
    return '归档于 $time';
  }

  @override
  String get deleteSpacePermanently => '永久删除';

  @override
  String get renameSpace => '重命名空间';

  @override
  String get renameConversation => '重命名对话';

  @override
  String get spaceActions => '空间操作';

  @override
  String get conversationActions => '对话操作';

  @override
  String get editSpaceRepos => '编辑仓库';

  @override
  String get editSpaceReposTitle => '空间仓库';

  @override
  String get editSpaceReposWarning => '添加仓库会将其检出到此空间；移除仓库会删除其文件夹。';

  @override
  String get agentSectionIdentity => '身份';

  @override
  String get agentSectionRuntime => '运行时';

  @override
  String get agentSectionGuardrails => '护栏';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 名下属',
      one: '1 名下属',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => '筛选团队…';

  @override
  String get teamsSummaryWithLeader => '有负责人';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个团队',
      one: '1 个团队',
      zero: '没有团队',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return '删除 $name 会移除其档案、技能关联和运行历史。此操作无法撤销。';
  }

  @override
  String get resetToDefault => '重置为默认';

  @override
  String get newAgent => '新建智能体';

  @override
  String get newSkill => '新建技能';

  @override
  String get zoomIn => '放大';

  @override
  String get zoomOut => '缩小';

  @override
  String get resetZoom => '重置缩放';

  @override
  String get imageHostedOnGitHub => '托管在 GitHub 上的图片';

  @override
  String get imageOpenExternally => '图片 · 在外部打开';

  @override
  String get memoryScopeAll => '所有范围';

  @override
  String get memoryScopeWorkspace => '整个工作区';

  @override
  String get memoryScopeFilterLabel => '按范围筛选';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return '范围限于 $repo 仓库';
  }

  @override
  String get toolScreenshot => '来自智能体的截图';

  @override
  String get toolImageUnavailable => '图片不可用';

  @override
  String toolImagesUnavailable(int count) {
    return '$count 张图片不可用';
  }

  @override
  String get shakeUnavailable => '此服务器不支持抖出功能';

  @override
  String get shakeNothing => '没有可抖出的内容——最近的轮次受保护';

  @override
  String shakeDone(int tokens) {
    return '已释放约 $tokens 个 token';
  }

  @override
  String get compactionDivider => '已压缩';

  @override
  String compactionDividerCount(int count) {
    return '已压缩 · 折叠了 $count 条消息';
  }

  @override
  String get composerDropToAttach => '拖放到此处以附加';

  @override
  String get attachmentUnavailable => '附件不可用';

  @override
  String get attachmentUnavailableDetail => '此附件已不在内存中。请重新附加以预览。';

  @override
  String get attachmentPreviewFailed => '无法打开此文件';

  @override
  String get attachmentPreviewUnsupported => '此文件类型不支持预览';

  @override
  String get attachmentTooLargeToPreview => '过大，无法预览';

  @override
  String get attachmentOpenExternally => '在默认应用中打开';

  @override
  String get asideUnavailable => '需先在工作区设置中设定单次模型才能使用此功能';

  @override
  String get asideEmpty => '暂无可依据的内容';

  @override
  String get asideFailed => '无法获得回答';

  @override
  String get handoffTitle => '交接';

  @override
  String get asideTitle => '旁路提问';

  @override
  String get attachFilesOrDrop => '附加文件——或拖放到此处';

  @override
  String get guidedGoalTitle => '明确目标';

  @override
  String get guidedGoalIntro => '无人监督的智能体需要确切知道何时算完成。先回答几个问题。';

  @override
  String get guidedGoalAnswerHint => '你的回答';

  @override
  String get guidedGoalNext => '下一步';

  @override
  String get guidedGoalStart => '开始目标';

  @override
  String get guidedGoalSkip => '跳过并按原样运行';

  @override
  String guidedGoalStillMissing(String items) {
    return '仍未指定：$items';
  }

  @override
  String get conversationTreeTitle => '对话树';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个分支',
      one: '1 个分支',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => '从此处继续';

  @override
  String get conversationTreeFork => '分叉为新对话';

  @override
  String get conversationTreeCurrent => '当前分支';

  @override
  String get conversationTreeEmpty => '这里还没有内容';

  @override
  String get conversationTreeForked => '已分叉为新对话';

  @override
  String get conversationTreeSwitched => '现在从该消息继续';

  @override
  String exportSaved(String path) {
    return '已保存到 $path';
  }

  @override
  String get exportFailed => '无法写入导出文件';

  @override
  String get contextCommandNoAgent => '此对话中没有智能体，因此没有可打开的上下文窗口';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return '此对话中没有名为“$name”的智能体。可尝试：$names';
  }

  @override
  String get dumpCopied => '对话记录已复制到剪贴板';

  @override
  String get messageQueueHint => '继续输入即可排队后续修改';

  @override
  String get steerNow => '引导';

  @override
  String get steeringQueueLabel => '已排队的引导消息';

  @override
  String get steeringDeliverUnavailable => '当前没有正在运行的智能体可以接收——它将保持排队。';

  @override
  String get reorderSteeringCard => '重新排列已排队的消息';

  @override
  String get editSteeringCard => '编辑已排队的消息';

  @override
  String get deleteSteeringCard => '删除已排队的消息';

  @override
  String get steeringBadge => '已引导';

  @override
  String get settingsSandboxLabel => '沙箱';

  @override
  String get sandboxExecGrantsTitle => '可执行授权';

  @override
  String get sandboxExecGrantsSubtitle =>
      '智能体可在其工作副本（你的仓库）中运行的程序。每一项都是沙箱询问时经你批准的。';

  @override
  String get sandboxExecGrantsEmpty => '尚未记录任何决定。当智能体首次需要从其工作副本运行程序时会询问你。';

  @override
  String get sandboxExecGrantRevoke => '吊销';

  @override
  String get sandboxExecGrantAllowed => '已允许';

  @override
  String get sandboxExecGrantBlocked => '已阻止';

  @override
  String get sandboxExecGrantRevokeConfirmTitle => '吊销此决定？';

  @override
  String get sandboxExecGrantRevokeConfirmBody => '下次智能体需要从此副本运行程序时会再次询问你。';

  @override
  String get repoScriptsTest => '测试';

  @override
  String get repoScriptsTestTooltip => '在仓库的一次性克隆中运行此草稿';

  @override
  String get repoScriptsRunKindTest => '测试';

  @override
  String get demoBadgeLabel => '演示';

  @override
  String get demoFilePickerTitle => '演示文件';

  @override
  String get demoFilePickerBody => '演示中的上传是模拟的：任选一个即可附加到你的消息，不会触及磁盘。';

  @override
  String get demoFilePickerAttach => '附加';

  @override
  String get demoReadOnlySave => '演示中为只读';

  @override
  String get demoBadgeTooltip => '你正在浏览演示。数据是虚构的，智能体是按脚本运行的。';

  @override
  String get demoFirstRunTitle => '你正在使用在线演示';

  @override
  String demoFirstRunBody(int minutes) {
    return '这是运行在真实代码上的真实应用——只有数据是虚构的。智能体按脚本流式播放真实的运行，因此不会有任何内容到达模型，也不会在任何机器上运行。你的工作区仅你可用，$minutes 分钟后消失。';
  }

  @override
  String get demoFirstRunDismiss => '知道了';

  @override
  String get demoTourTitle => '先看哪里';

  @override
  String get demoTourSubtitle => '四个能展示应用实际功能的地方。';

  @override
  String get demoTourSkip => '跳过';

  @override
  String get demoTourStarRepo => '在 GitHub 上加星标';

  @override
  String get demoTourOpen => '打开';

  @override
  String get demoTourSpacesTitle => '与智能体对话';

  @override
  String get demoTourSpacesBody =>
      '在空间中发送消息并观看运行流式呈现——思考、工具调用和成本，与真实运行的渲染完全一致。';

  @override
  String get demoTourReviewTitle => '审查一个 pull request';

  @override
  String get demoTourReviewBody => '打开 #412。留下行内评论或提交审查；你的话会落在话题中并保留。';

  @override
  String get demoTourTicketsTitle => '跟进工作';

  @override
  String get demoTourTicketsBody => '工单、待办和计划都与智能体正在进行的相同对话相关联。';

  @override
  String get demoTourInboxTitle => '纵览整个运营';

  @override
  String get demoTourInboxBody => '各板块的所有提醒都汇入同一个收件箱——审查、工单、运行和会议。';

  @override
  String get demoUnavailableTitle => '演示中不可用';

  @override
  String get demoUnavailableTerminal =>
      '终端会在服务器主机上运行真实的 shell。演示完全没有执行面——这正是它可以公开开放的原因。';

  @override
  String get demoUnavailableRig =>
      'Enclosure 是由智能体驱动的一次性虚拟机。演示一台也不启动：能启动虚拟机的公共端点就算不上演示。';

  @override
  String get demoUnavailableEditor =>
      '浏览器内编辑器会针对真实检出运行 code-server 进程。演示两者都没有。';

  @override
  String get demoUnavailableFeeds => '演示读取真实的 feed，但其订阅列表是固定的。此处禁用添加或删除。';

  @override
  String get demoUnavailableForge =>
      '演示不保存任何凭据，也绝不联系 GitHub、GitLab 或 Linear。其 pull request 是固定数据，你对它们的评论存储在本地。';

  @override
  String get demoUnavailableModels =>
      '演示不调用任何模型。智能体运行是脚本回放，因此不产生成本，也不会到达任何提供商。';

  @override
  String get demoUnavailableMcp => '演示未挂载 MCP 工具面，因此外部客户端无法连接。';

  @override
  String get demoUnavailableRepos =>
      '演示不检出任何代码，也不运行 git。你看到的仓库是 pull request 背后的固定数据。';

  @override
  String get demoUnavailableSkills => '安装技能会下载并扫描代码。演示不获取任何内容。';

  @override
  String get demoUnavailableSso => '单点登录属于服务器配置。演示会改为让你以临时访客身份登录。';

  @override
  String get demoUnavailableAudio =>
      '录制和听写需要主机上的音频采集和语音模型。演示两者都没有，因此其会议只有文字记录，没有回放。';

  @override
  String get demoUnavailableServerAdmin => '这是服务器管理。演示为每位访客提供一个一次性工作区，仅此而已。';

  @override
  String get demoUnavailablePipelines =>
      '此处无法运行流水线。访客若能编写 bash 步骤并以手动或事件触发方式启动，就是在此主机上执行代码。';

  @override
  String get settingsBackupRestore => '备份与恢复';

  @override
  String get settingsBackupRestoreDescription =>
      '此服务器上所有数据库的快照，以及单个工作区的导出、导入和删除。';

  @override
  String get backupSnapshotsLabel => '安装快照';

  @override
  String get backupSnapshotsExplainer =>
      '快照会将每个数据库复制到服务器主机上带时间戳的文件夹中。恢复整个安装需要在停止服务器后把该文件夹复制回去；单个工作区可以从此处恢复。';

  @override
  String get backupNowAction => '立即备份';

  @override
  String backupSnapshotWritten(String path) {
    return '快照已写入 $path';
  }

  @override
  String get backupNoSnapshots => '暂无快照。仅在你主动请求时才会拍摄——没有任何计划任务。';

  @override
  String get backupSnapshotComplete => '完成';

  @override
  String get backupSnapshotIncomplete => '未完成';

  @override
  String get backupSnapshotIncompleteNote =>
      '清单缺失或引用了不存在的文件，因此此快照无法恢复整个安装。其中包含的工作区文件仍可逐个采用。';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个工作区',
      one: '1 个工作区',
      zero: '没有工作区',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个工作区未捕获',
      one: '1 个工作区未捕获',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => '服务器上的路径';

  @override
  String get backupRestoreAction => '恢复';

  @override
  String get backupRestoreTitle => '恢复工作区';

  @override
  String backupRestoreBody(String name) {
    return '这会用此快照中的副本替换 $name 中的所有内容。该工作区自快照以来的所有变更都会丢失，且无法撤销。';
  }

  @override
  String backupRestoreDone(String name) {
    return '已从快照恢复 $name。';
  }

  @override
  String get backupWorkspaceUnknown => '已不在此服务器上';

  @override
  String get backupWorkspaceDataLabel => '工作区数据';

  @override
  String get backupWorkspaceDataExplainer =>
      '一个工作区就是一个数据库文件，因此导出是复制该文件，而不是逐表转储。导入会用你指定的文件替换目标工作区中的所有内容。';

  @override
  String get backupExportAction => '导出';

  @override
  String backupExportDone(String path) {
    return '已导出到 $path';
  }

  @override
  String get backupExportedFileLabel => '服务器上的导出文件';

  @override
  String get backupImportAction => '导入';

  @override
  String backupImportTitle(String name) {
    return '导入到 $name';
  }

  @override
  String backupImportBody(String name) {
    return '这会用文件内容替换 $name 中的所有内容。该工作区现在持有的一切都会丢失，且无法撤销。';
  }

  @override
  String get backupImportSourceLabel => '工作区数据库文件';

  @override
  String get backupImportSourceDescription =>
      '服务器可读取的 .db 文件。路径在服务器主机上解析，而不是在此设备上。';

  @override
  String backupImportDone(String name) {
    return '已导入到 $name。';
  }

  @override
  String backupDeleteBody(String name) {
    return '$name 会从所有列表和查找中消失。其数据库文件仍留在磁盘上，备份仍会包含它，且不会自动回收空间。';
  }

  @override
  String get backupExportDescription => '在服务器上写入副本，或将其下载到此设备。';

  @override
  String get backupExportOnServerAction => '保存到服务器';

  @override
  String get backupDownloadAction => '下载';

  @override
  String backupDownloadSaved(String path) {
    return '已保存到 $path';
  }

  @override
  String get backupDownloadInBrowser => '浏览器正在下载。';

  @override
  String get backupRestoreFromDeviceLabel => '从此设备恢复';

  @override
  String get backupRestoreFromDeviceDescription =>
      '在此选择一个工作区数据库文件，Control Center 会将其上传到服务器。当服务器不是本机时，这是可行的方式。';

  @override
  String get backupUploadAction => '选择文件并上传';

  @override
  String get backupTransferUnavailable =>
      '此连接通过中继到达服务器，而中继不承载文件传输。请直接连接服务器以下载或上传备份。';

  @override
  String get backupTransferForbidden =>
      '服务器拒绝了。下载工作区需要管理员角色，恢复工作区需要所有者，整个快照需要安装运营者。';

  @override
  String get backupTransferUnsupported => '此服务器没有备份接口。';

  @override
  String get backupTransferTooLarge => '文件大于服务器接受的上限。';

  @override
  String get credentialGateWaitingTitle => '正在等待凭据';

  @override
  String credentialGateHarnessTitle(String provider) {
    return '$provider 没有凭据';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Code 已退出登录';

  @override
  String get credentialGateExpiredTitle => '你的 Claude Code 登录已过期';

  @override
  String get credentialGatePlanSpentTitle => '已达到 Claude Code 套餐上限';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent 正在等待以继续。';
  }

  @override
  String get credentialGateWaitingRun => '有一个运行正在等待以继续。';

  @override
  String get credentialGateWatching => '正在等待修复——运行会自行继续。';

  @override
  String credentialGateFreesUpAt(String time) {
    return '$time 恢复可用';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return '运行将于 $time 放弃';
  }

  @override
  String get credentialGateCheckAgain => '再次检查';

  @override
  String get credentialGateCancelRun => '取消运行';

  @override
  String get credentialGateAccountsTried => '已尝试的账户';

  @override
  String get credentialGateClaudeSignInHint =>
      '请在“设置 → 适配器 → Claude Code”中登录，或在终端中运行登录命令。运行会自行检测并继续。';

  @override
  String get credentialGateOpenSettings => '打开设置';

  @override
  String get selectModel => '选择模型';

  @override
  String get allModels => '所有模型';

  @override
  String get noModelsMatchSearch => '没有与搜索匹配的模型';

  @override
  String useCustomModelId(String id) {
    return '使用“$id”';
  }

  @override
  String get modelFree => '免费';

  @override
  String modelOutputTokens(String tokens) {
    return '输出 $tokens';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return '每 100 万 token 输入 $input / 输出 $output';
  }

  @override
  String modelEffortLevels(String levels) {
    return '推理力度：$levels';
  }

  @override
  String get modelSupportsReasoning => '支持推理力度';

  @override
  String get profileDeliveryMetrics => '交付指标';

  @override
  String profileMetricsSample(int count) {
    return '已分析 PR：$count';
  }

  @override
  String get profileMergeRate => '合并率';

  @override
  String get profileReviewCoverage => '审查覆盖率';

  @override
  String get profilePrSize => 'PR 大小';

  @override
  String get profileTimeToMerge => '合并用时';

  @override
  String get profileMergeTimeTrend => '合并时间趋势';

  @override
  String get profileWeeklyMedian => '每周中位数，对数刻度';

  @override
  String get profilePrOpeningPattern => '星期 × 小时，本地时间';

  @override
  String get profileFirstReview => '首次审查用时';

  @override
  String get profileMetricsTruncated => '百分位数基于可用拉取请求的有限样本。';

  @override
  String profileLinesChanged(String count) {
    return '$count 行';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count 分钟';
  }

  @override
  String profileDurationHours(int count) {
    return '$count 小时';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '$days天 $hours小时';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return '成员：$count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return '此工作区中没有 $team 的拉取请求';
  }

  @override
  String get profilePrStateFilterLabel => '按状态筛选拉取请求';

  @override
  String get noProfilePrsMatchSearchHint => '请尝试其他标题或拉取请求编号';

  @override
  String get rigNetworkUnrestricted => '网络不受限制';

  @override
  String get rigNetworkAllowAllHosts => '允许所有主机';

  @override
  String get rigBrowserPermissionsTitle => '网站权限';

  @override
  String get rigBrowserPermissionsTooltip => '网站权限和网络';

  @override
  String get rigBrowserPermissionEmpty => '还没有网站请求过权限';

  @override
  String rigBrowserPermissionPrompt(String origin, String permission) {
    return '$origin 想要使用$permission';
  }

  @override
  String get rigBrowserPermissionBlock => '阻止';

  @override
  String get rigBrowserPermissionCamera => '相机';

  @override
  String get rigBrowserPermissionMicrophone => '麦克风';

  @override
  String get rigBrowserPermissionNotifications => '通知';

  @override
  String get rigBrowserPermissionGeolocation => '位置';

  @override
  String get rigBrowserPermissionPersistentStorage => '持久存储';

  @override
  String get rigBrowserPermissionClipboard => '剪贴板';

  @override
  String get rigBrowserPermissionDisplayCapture => '屏幕捕获';

  @override
  String get rigBrowserPermissionMidi => 'MIDI';

  @override
  String get rigNetworkBypassTitle => '允许访问所有网络主机？';

  @override
  String get rigNetworkBypassBody =>
      '这会重启隔离环境，并丢弃其中未提交的工作。之后，访客系统在关闭前可以访问任何网络主机。';

  @override
  String get rigNetworkRestartUnrestricted => '以不受限模式重启';

  @override
  String get rigNetworkUnrestrictedBody =>
      '此隔离环境可以访问任何网络主机。关闭它并打开一个新环境，即可恢复默认限制。';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      '此 Android 模拟器已自行管理网络，因此 Control Center 无法强制执行按主机设置的允许列表。无需重启。';

  @override
  String get rigClipboardPermissionHostToRigTitle => '将剪贴板粘贴到此环境？';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'Control Center 将读取你设备的剪贴板，并将其内容发送到该环境。剪贴板内容可能包含密码或其他机密信息。';

  @override
  String get rigClipboardPermissionRigToHostTitle => '从此环境复制剪贴板？';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'Control Center 将读取该环境的剪贴板，并用其内容替换你设备的剪贴板。请将来自该环境的内容视为不可信。';

  @override
  String get rigClipboardAllowTenMinutes => '允许 10 分钟';

  @override
  String get rigClipboardAlwaysAllow => '始终允许';

  @override
  String get rigClipboardSettingsTitle => '剪贴板访问';

  @override
  String get rigClipboardSettingsHint => '选择哪些剪贴板传输可以无需询问即可运行。临时权限会在 10 分钟后过期。';

  @override
  String get rigClipboardAlwaysPasteTitle => '始终允许粘贴到环境';

  @override
  String get rigClipboardAlwaysPasteDescription => '无需询问，将此设备的剪贴板发送到任何环境。';

  @override
  String get rigClipboardAlwaysCopyTitle => '始终允许从环境复制';

  @override
  String get rigClipboardAlwaysCopyDescription => '无需询问，将任何环境中的剪贴板内容放到此设备上。';

  @override
  String get workspaceGitHubIdentity => 'GitHub 身份';

  @override
  String get workspaceGitHubIdentityDescription =>
      '此工作区后台 GitHub 工作的认证方式。继承此安装的 App、使用其他 App，或仅使用个人访问令牌。';

  @override
  String get workspaceGitHubModeInherit => '使用此安装的 GitHub App';

  @override
  String get workspaceGitHubModeApp => '使用其他 GitHub App';

  @override
  String get workspaceGitHubModePat => '仅个人访问令牌';

  @override
  String get workspaceGitHubInheritHint => '使用服务器 → 提供商应用中的 GitHub App。';

  @override
  String get workspaceGitHubAppHint => '此工作区的机器人和轮询身份。成员在「你」中通过此 App 登录。';

  @override
  String get workspaceGitHubPatLabel => '后台令牌';

  @override
  String get workspaceGitHubPatDescription => '用于此工作区的轮询和代理。不是成员的个人资料令牌。';

  @override
  String get workspaceGitHubHasPat => '已存储后台令牌。';

  @override
  String get workspaceGitHubNoPat => '未存储后台令牌。';

  @override
  String get profileOverlayHint =>
      '这些字段是你在此工作区的身份。空字段继承账户姓名和电子邮件。切换工作区会切换此覆盖层。';

  @override
  String get forgeConnectionsThisWorkspace => '登录或粘贴此工作区的令牌。';
}

/// The translations for Chinese, as used in Hong Kong (`zh_HK`).
class AppLocalizationsZhHk extends AppLocalizationsZh {
  AppLocalizationsZhHk() : super('zh_HK');

  @override
  String get guardrailClassNetworkEgress => '存取網絡';

  @override
  String get rigEgressNotEnforced => '此後端未封閉網絡 — 連線由其自行管理。';

  @override
  String get ideCloseKeepBodyMachine =>
      '機器會在背景繼續執行 — 隨時可從側邊欄重新開啟。若要立即釋放內存，請改為關機。';

  @override
  String get rigPortsExposeLan => '在區域網絡分享';

  @override
  String get rigPortsLanShared => '已在網絡上';

  @override
  String get serverDiscoveryTooltip => '尋找網絡上的伺服器';

  @override
  String get serverDiscoveryTitle => '網絡上的伺服器';

  @override
  String get shutdownServiceNetworking => '網絡';

  @override
  String get serverSharingMdnsLabel => '區域網絡探索';

  @override
  String get serverSharingMdnsOn => '正在區域網絡（mDNS）上廣播此伺服器';

  @override
  String get serverSharingMdnsOff => '未在區域網絡（mDNS）上廣播';

  @override
  String get serverSharingTunnelHelper =>
      '開啟通道後，即可從互聯網連線到此伺服器。公開曝光需自行開啟，預設為關閉。';

  @override
  String get pairCredentialsIntro => '用這些信息連接新用戶端，或在用戶端中開啟連結。';

  @override
  String get serverSetupErrorUnreachable =>
      '無法連到伺服器。請確認伺服器正在執行，且此裝置可連到它（同一網絡或經由中繼）。';

  @override
  String get serverSetupErrorGeneric => '連線時發生問題。展開下方技術詳情以取得更多信息。';

  @override
  String get notificationRigReclaimedBodyIdle => '因閒置過久，已關閉機器以釋放內存。';

  @override
  String get allowNetwork => '允許一般網絡存取';

  @override
  String get appLogLevelInfoLabel => '信息';

  @override
  String networkBlockCount(int count) {
    return '$count 個網絡封鎖';
  }

  @override
  String get ticketSelectPrompt => '選擇一張工單以查看詳細信息';

  @override
  String get showDetails => '顯示詳細信息';

  @override
  String get inviteLoopbackWarningBody =>
      '其他機器上的協作者將無法連上這部伺服器。請啟用通道（設定 → 整合 → 分享此伺服器），或繫結到你的網絡，讓外部使用者可以連線。';

  @override
  String get profileSectionDescription =>
      '你在此工作區中對隊友與 git 提交作者資訊的身分。空白欄位繼承帳戶名稱和電郵。';

  @override
  String get inboxSeverityInfo => '信息';

  @override
  String get settingsAboutDescription => '建置信息與更新。';

  @override
  String get ssoGroupHandoff => '你的身分識別供應商需要的信息';

  @override
  String get guardrailFamilyMachine => '機器與網絡';

  @override
  String get rigsResidentMemory => '常駐內存';

  @override
  String get attachmentUnavailableDetail => '此附件已不在內存中。請重新附加以預覽。';

  @override
  String get profileDeliveryMetrics => '交付指標';

  @override
  String profileMetricsSample(int count) {
    return '已分析 PR：$count';
  }

  @override
  String get profileMergeRate => '合併率';

  @override
  String get profileReviewCoverage => '審查覆蓋率';

  @override
  String get profilePrSize => 'PR 大小';

  @override
  String get profileTimeToMerge => '合併所需時間';

  @override
  String get profileFirstReview => '首次審查所需時間';

  @override
  String get profileMetricsTruncated => '百分位數是根據可用拉取請求的有限樣本計算。';

  @override
  String profileLinesChanged(String count) {
    return '$count 行';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count 分鐘';
  }

  @override
  String profileDurationHours(int count) {
    return '$count 小時';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '$days日 $hours小時';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return '成員：$count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return '此工作區沒有 $team 的拉取請求';
  }

  @override
  String get profilePrStateFilterLabel => '按狀態篩選拉取請求';

  @override
  String get noProfilePrsMatchSearchHint => '請嘗試其他標題或拉取請求編號';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get succeeded => '已成功';

  @override
  String agentRunRetryLabel(int number, String time) {
    return '重試 #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return '啟動中 · $time';
  }

  @override
  String get agentActivityFollowingLive => '正在跟隨即時活動';

  @override
  String get agentActivityJumpToLatest => '跳至最新';

  @override
  String get agentActivityLoadFailed => '無法載入此次執行的活動';

  @override
  String get agentActivityNotRecorded => '此次執行沒有記錄任何活動';

  @override
  String get agentActivityNotRecordedHint => '在啟用活動擷取前就已結束的執行沒有時間軸。';

  @override
  String get agentActivityRunUnavailable => '此次執行已無法使用';

  @override
  String agentActivitySubagentOf(String agent) {
    return '$agent 的子代理';
  }

  @override
  String get agentActivityUnsupported => '已連線的伺服器無法使用活動擷取';

  @override
  String get agentActivityUnsupportedHint => '請重新啟動應用程式，以套用最新的伺服器組建。';

  @override
  String get agentActivityWaiting => '正在等待活動…';

  @override
  String get created => '已建立';

  @override
  String get dictationStart => '開始聽寫';

  @override
  String get dictationListening => '正在聆聽…';

  @override
  String get dictationUnavailable => '聽寫需要在伺服器主機上設定語音模型。請至語音設定中設定。';

  @override
  String get dictationFailedToStart => '無法開始聽寫';

  @override
  String get dictationHoldToTalkTitle => '按住說話';

  @override
  String get dictationHoldToTalkDescription =>
      '按住麥克風按鈕或快捷鍵即可聽寫，放開即可停止。關閉時，按一下開始，再按一下停止。';

  @override
  String get focusConversation => '聚焦對話';

  @override
  String get ideAgentActivity => '代理活動';

  @override
  String get keybindingPushToTalk => '按住說話';

  @override
  String get keybindingPushToTalkDescription => '在訊息輸入區按住或切換語音聽寫';

  @override
  String get agentPermissions => '代理權限';

  @override
  String get agentPermissionsSettingsDescription =>
      '決定代理可自行執行、須先詢問，或一律禁止的操作 — 可依工作區、代理或空間設定。';

  @override
  String get agentPermissionsMatrixDescription =>
      '為每種效果設定決策。規則會層層覆寫：空間覆寫代理、代理覆寫工作區、工作區覆寫模式預設。最具體的規則優先。';

  @override
  String get guardrailLoading => '正在載入規則…';

  @override
  String get guardrailRulesLoadFailed => '無法載入權限規則。';

  @override
  String get guardrailScopeWorkspace => '工作區';

  @override
  String get guardrailScopeAgent => '代理';

  @override
  String get guardrailScopeSpace => '空間';

  @override
  String get guardrailSelectAgent => '選取代理';

  @override
  String get guardrailSelectSpace => '選取空間';

  @override
  String get guardrailNoAgents => '此工作區尚無代理。';

  @override
  String get guardrailNoSpaces => '此工作區尚無空間。';

  @override
  String get guardrailClassFileDelete => '刪除檔案';

  @override
  String get guardrailClassFileWriteOutsideWorktree => '寫入工作樹以外';

  @override
  String get guardrailClassGitCommit => '建立提交';

  @override
  String get guardrailClassGitPush => '推送到遠端';

  @override
  String get guardrailClassPrCreate => '開啟 pull request';

  @override
  String get guardrailClassPrPublish => '發佈審查或合併';

  @override
  String get guardrailClassVendorSyncWrite => '寫入外部追蹤器';

  @override
  String get guardrailClassNetworkEgress => '存取網路';

  @override
  String get guardrailClassSecretAccess => '讀取密鑰';

  @override
  String get guardrailClassPackageInstall => '安裝套件';

  @override
  String get guardrailClassProcessSpawn => '執行程序';

  @override
  String get guardrailClassWorkspaceMutation => '變更工作區結構';

  @override
  String get guardrailClassEnclosureControl => '操控 enclosure（rig）';

  @override
  String get navRigs => 'Rigs';

  @override
  String get rigsUnsupportedServer => '此伺服器無法託管任何 rig 表面。請檢查您要使用的機器是否符合主機需求。';

  @override
  String get rigSurfaceComputer => '電腦';

  @override
  String get rigSurfaceBrowser => '瀏覽器';

  @override
  String get rigSurfaceAndroid => 'Android';

  @override
  String get rigSurfaceIosSimulator => 'iOS 模擬器';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return '用完即丟的 $engine，與你的電腦隔離。再開一個引擎即可並排比較同一頁面。';
  }

  @override
  String get rigPhaseReady => '就緒';

  @override
  String get rigPhaseStarting => '啟動中';

  @override
  String get rigPhaseParked => '已停放';

  @override
  String get rigPhaseClosing => '關閉中';

  @override
  String get rigPhaseClosed => '已關閉';

  @override
  String get rigPhaseFailed => '失敗';

  @override
  String get rigPhaseUnknown => '未知';

  @override
  String get rigNotAccelerated => '模擬';

  @override
  String get rigAudioListen => '聆聽機器';

  @override
  String get rigAudioMute => '將機器靜音';

  @override
  String get rigYouHaveControl => '你有控制權';

  @override
  String get rigBackendAvailable => '可用';

  @override
  String get rigBackendUnavailable => '無法使用';

  @override
  String get rigEgressNotEnforced => '此後端未封閉網路 — 連線由其自行管理。';

  @override
  String get rigStartMachine => '啟動機器';

  @override
  String get rigStartHint => '啟動一台用完即丟的虛擬機，供你和代理在此對話共用。關閉後即銷毀，其中內容不會動到你的電腦。';

  @override
  String get rigStartAndroidHint => '連線至伺服器上已在執行的 Android 模擬器。網路存取未隔離。';

  @override
  String get rigStartIosHint =>
      '在 macOS 伺服器上建立一個用完即棄的 iOS 模擬器。測試環境關閉時會將其刪除；網路存取未隔離。';

  @override
  String get rigTechnicalDetails => '技術詳情';

  @override
  String get rigStopMachine => '停止機器';

  @override
  String get rigHomeButton => '主畫面';

  @override
  String get rigRotateClockwise => '順時針旋轉';

  @override
  String get rigRotateCounterclockwise => '逆時針旋轉';

  @override
  String get rigTakeScreenshot => '擷取螢幕';

  @override
  String get rigScreenshotSaved => '已儲存螢幕截圖';

  @override
  String rigScreenshotSaveFailed(String error) {
    return '無法儲存螢幕截圖：$error';
  }

  @override
  String get rigSurfaceUnavailable => '此伺服器無法託管這類機器。';

  @override
  String get rigTabNeedsConversation => '請先開啟對話 — 機器隸屬於單一對話，這樣你和代理才會看到同一畫面。';

  @override
  String get ideMenuSectionTools => '工具';

  @override
  String get ideMenuSectionMachines => '機器';

  @override
  String get ideMenuSectionReopen => '重新開啟';

  @override
  String get ideMenuSearchHint => '搜尋';

  @override
  String get ideMenuNoMatches => '沒有相符項目';

  @override
  String get rigMenuComputer => '電腦';

  @override
  String get rigMenuBrowser => '瀏覽器';

  @override
  String get rigMenuAndroid => 'Android';

  @override
  String get rigMenuIosSimulator => 'iOS 模擬器';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return '要關閉 $name 嗎？';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      '機器會在背景繼續執行 — 隨時可從側邊欄重新開啟。若要立即釋放記憶體，請改為關機。';

  @override
  String get ideCloseKeepBodyShell =>
      '指令會在背景繼續執行 — 隨時可從側邊欄重新開啟 Shell。若要立刻停止目前作業，請改為結束 Shell。';

  @override
  String get ideCloseKeepBodyAgent =>
      '代理會在背景繼續運作 — 隨時可從側邊欄重新開啟對話。若要立刻結束此次執行，請改為停止代理。';

  @override
  String get ideCloseKeepRunning => '繼續執行';

  @override
  String get ideCloseShutDownMachine => '關機';

  @override
  String get ideCloseEndShell => '結束 Shell';

  @override
  String get ideCloseStopAgent => '停止代理';

  @override
  String get rigsSettingsSubtitle => '此伺服器可啟動的項目、所需的基礎映像，以及目前執行中的機器';

  @override
  String get rigsCapabilitiesTitle => '此伺服器';

  @override
  String get rigInstallIosAutomation => '安裝 iOS 自動化橋接器';

  @override
  String get rigInstallingIosAutomation => '正在安裝 iOS 自動化橋接器…';

  @override
  String get rigIosAutomationInstalled => 'iOS 自動化橋接器已安裝';

  @override
  String get rigsImagesTitle => '基礎映像';

  @override
  String get rigsImagesHint =>
      '每台 Rig 都會從這些唯讀映像啟動。每個工作階段寫入用完即丟的覆疊層，因此一台 Rig 絕不會改到下一台的起始狀態。';

  @override
  String get rigsRunningTitle => '目前執行中';

  @override
  String get rigsNoneRunning => '沒有執行中的機器。';

  @override
  String get rigsCustomImagesTitle => '自訂映像（此工作區）';

  @override
  String get rigsCustomImagesHint =>
      '將 Terminal (VM) 或 Browser (VM) 指向你自己的映像 — 在預設映像上加入專案所需工具，或使用登錄庫中任何相容映像。新機器會採用它；執行中的機器維持原映像。映像須提供的內容請見 Rigs 指南。';

  @override
  String get rigsCustomTerminalImageLabel => '終端機 (VM) 映像';

  @override
  String get rigsCustomBrowserImageLabel => '瀏覽器 (VM) 映像';

  @override
  String get rigsCustomImagePlaceholder =>
      '例如 ghcr.io/acme/dev-shell:1.2 — 留空則使用預設';

  @override
  String get rigsCustomImageInvalid => '請輸入登錄庫參照，例如 repo/name:tag。不允許本機路徑與封存檔。';

  @override
  String get rigsCustomImageSaved => '已儲存。新機器會以此映像開機；執行中的機器維持原本映像。';

  @override
  String get rigsEgressTitle => '瀏覽器對外連線（此工作區）';

  @override
  String get rigsEgressHint =>
      '封閉瀏覽器可額外連到的主機 — 每行一筆：精確主機（api.example.com）或其子網域萬用字元（*.example.com）。產品網站無論設定為何都可連線。新機器會套用此清單；執行中的機器維持開機時的設定。';

  @override
  String rigsEgressInvalid(String host) {
    return '「$host」不是有效的主機項目。';
  }

  @override
  String get rigsEgressSaved => '已儲存。新的瀏覽器機器會允許這些主機；執行中的機器維持原本設定。';

  @override
  String get rigImageInstalled => '已安裝';

  @override
  String get rigImageNotDownloaded => '尚未下載';

  @override
  String get rigImageNotPublished => '尚未發布';

  @override
  String get rigImageNotPublishedHint => '尚未發布映像，因此沒有可下載的內容。請匯入相容的磁碟映像以啟用。';

  @override
  String get rigImageDownload => '下載';

  @override
  String get rigImageDownloading => '正在下載…';

  @override
  String get rigImageImport => '匯入';

  @override
  String get rigImageImportMessage =>
      '伺服器檔案系統上 qcow2 磁碟映像的路徑。系統會複製到映像存放區，之後可移動原檔。';

  @override
  String get rigConnectingStream => '正在連線至 rig';

  @override
  String get rigStreamNotAllowed => '你沒有此 rig 的存取權限。';

  @override
  String get rigStreamNotRunning => '此 rig 已不再執行。';

  @override
  String get rigStreamNeedsFfmpeg => '即時畫面需要此主機已安裝 ffmpeg。請安裝 ffmpeg 後重新開啟分頁。';

  @override
  String get rigStreamEnded => '即時畫面已結束。';

  @override
  String get rigStreamFailed => '無法開啟即時畫面。';

  @override
  String get rigStreamDisconnected => '尚未連線至伺服器。';

  @override
  String rigDropSendingOne(String name) {
    return '正在將「$name」複製到機器中…';
  }

  @override
  String rigDropSendingMany(int count) {
    return '正在將 $count 個檔案複製到機器中…';
  }

  @override
  String get rigTerminalDropSending => '正在複製到機器中…';

  @override
  String get rigTerminalPasteImage => '貼上的圖片已儲存在機器中';

  @override
  String get rigPortsTitle => '轉送的連接埠';

  @override
  String get rigPortsTooltip => '此機器內開啟的連接埠';

  @override
  String get rigPortsEmpty => '尚無任何服務在監聽。在終端機啟動伺服器 — 連接埠 3000 上的開發伺服器會顯示在這裡。';

  @override
  String get rigPortsAdd => '新增連接埠';

  @override
  String get rigPortsAddHint => '要轉送的客體連接埠（例如 3000）';

  @override
  String get rigPortsAutoForward => '自動轉送連接埠';

  @override
  String get rigPortsCopyUrl => '複製本機 URL';

  @override
  String rigPortsCopiedUrl(String url) {
    return '已複製 $url';
  }

  @override
  String get rigPortsStopForward => '停止轉送';

  @override
  String get rigPortsExposeLan => '在區域網路分享';

  @override
  String get rigPortsLanPrivate => '僅本機';

  @override
  String get rigPortsLanShared => '已在網路上';

  @override
  String get rigPortsSetDomain => '設定瀏覽器網域（.test）';

  @override
  String get rigPortsDomainHint => '瀏覽器 (VM) 的網域，例如 myapp.test — 可在該處連線，而非主機上';

  @override
  String get rigPortsProcessUnknown => '未知處理程序';

  @override
  String get rigPortsInactive => '未在監聽';

  @override
  String get rigPortsTooltipHost => '此終端機中開啟的連接埠';

  @override
  String get rigPortsEmptyHost => '此終端機中還沒有程式在監聽。啟動伺服器後會出現在這裡。';

  @override
  String get rigPortsAddHintHost => '要對應的連接埠（例如 5173）';

  @override
  String get rigPortsLocalPortHint => '本機連接埠（選填）';

  @override
  String rigPortsDestDesktop(int port) {
    return 'localhost:$port';
  }

  @override
  String rigPortsDestBrowser(int port) {
    return 'localhost:$port（瀏覽器虛擬機器）';
  }

  @override
  String get rigPortsDestBrowserUnreachable => '瀏覽器（虛擬機器）未連線';

  @override
  String rigPortsDestAndroid(int port) {
    return 'localhost:$port（Android）';
  }

  @override
  String get rigPortsDestAndroidUnreachable => 'Android 未連線';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '還有 $count 個基礎映像待下載',
      one: '還有 1 個基礎映像待下載',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => '允許';

  @override
  String get guardrailDecisionPrompt => '先詢問';

  @override
  String get guardrailDecisionDeny => '拒絕';

  @override
  String get guardrailSourceThisScope => '此範圍';

  @override
  String get guardrailSourceDefault => '內建預設';

  @override
  String get guardrailSourcePreset => '模式預設';

  @override
  String get guardrailSourceInherited => '繼承';

  @override
  String get guardrailClearToInherited => '還原為繼承';

  @override
  String get guardrailWhatIf => '會怎樣？';

  @override
  String get guardrailWhatIfDescription => '查看目前規則會如何判定某個動作，所用邏輯與代理實際執行時相同。';

  @override
  String get guardrailProbeActionLabel => '動作';

  @override
  String get guardrailProbeCommandLabel => '指令（選填）';

  @override
  String get guardrailProbeCommandHint => '例如 git push origin main';

  @override
  String get guardrailProbeAgentLabel => '代理（選填）';

  @override
  String get guardrailProbeSpaceLabel => '空間（選填）';

  @override
  String get guardrailProbeNone => '無';

  @override
  String get guardrailProbeModeLabel => '模式';

  @override
  String get guardrailProbeResult => '結果';

  @override
  String get guardrailProbeSource => '來源：';

  @override
  String get guardrailAdapterMatrix => '規則套用位置';

  @override
  String get guardrailAdapterMatrixDescription =>
      '實況說明：各代理執行器實際攔截各效果的位置。這是現況紀錄，並非保證——執行器在流程外進行的效果無法攔截。';

  @override
  String get guardrailEffectColumn => '效果';

  @override
  String get guardrailAdapterHarness => '內建執行環境';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => '沙箱下限';

  @override
  String get guardrailEnforcementPolicyGate => '政策閘門';

  @override
  String get guardrailEnforcementSandbox => '僅沙箱';

  @override
  String get guardrailEnforcementNone => '無法強制執行';

  @override
  String get guardrailEnforcementPolicyGateHelp => '效果執行前會檢查權限判定，並可加以阻擋。';

  @override
  String get guardrailEnforcementSandboxHelp => '僅由沙箱加以限制，不會套用權限規則。';

  @override
  String get guardrailEnforcementNoneHelp => '判定僅供參考，此處無法攔截。';

  @override
  String get obsStatCost => '成本';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount 委派';
  }

  @override
  String get obsStatDuration => '耗時';

  @override
  String get obsStatTokens => 'token';

  @override
  String get obsStatTools => '工具';

  @override
  String get openAgentActivity => '開啟活動';

  @override
  String get orgChart => '組織圖';

  @override
  String get orgChartEmpty => '尚無代理';

  @override
  String get navCalendar => '行事曆';

  @override
  String get serverConnection => '伺服器連線';

  @override
  String get serverModeLocal => '在此應用程式執行';

  @override
  String get serverModeLocalDescription =>
      'Control Center 會在本機執行自己的伺服器，資料也存放在本機。';

  @override
  String get serverModeRemote => '連線至遠端執行個體';

  @override
  String get serverModeRemoteDescription =>
      '連線至其他位置執行的 Control Center 伺服器。資料會存放在該伺服器上。';

  @override
  String get serverRemoteUrl => '伺服器 URL';

  @override
  String get serverRemoteDeviceId => '裝置 ID';

  @override
  String get serverRemotePairingKey => '配對金鑰';

  @override
  String get serverRemotePairingKeyHint => '貼上遠端伺服器提供的配對金鑰';

  @override
  String get serverSetupInviteCode => '邀請碼';

  @override
  String get serverSetupInviteCodeHint => '貼上一次性邀請碼（留空則改用配對金鑰）';

  @override
  String get serverDiscoveryTooltip => '尋找網路上的伺服器';

  @override
  String get serverDiscoveryTitle => '網路上的伺服器';

  @override
  String get serverDiscoverySearching => '正在搜尋伺服器…';

  @override
  String get serverDiscoveryEmpty => '找不到伺服器。請確認伺服器正在執行，且此裝置可連線到該伺服器，然後再搜尋一次。';

  @override
  String get serverDiscoveryRefresh => '再搜尋一次';

  @override
  String get serverListActive => '使用中';

  @override
  String get serverListSwitch => '切換';

  @override
  String get serverListAddTitle => '新增伺服器';

  @override
  String get serverListRemoveActiveHint => '請先切換到其他伺服器，再移除此伺服器。';

  @override
  String get serverSwitchFailedTitle => '無法切換伺服器';

  @override
  String get serverListInsecureBadge => '不安全';

  @override
  String get connectionPathLocal => '本機';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => '正在關閉';

  @override
  String get shutdownSubtitle => '正在關閉本機伺服器';

  @override
  String get shutdownServiceApprovals => '核准';

  @override
  String get shutdownServiceBackgroundJobs => '背景工作';

  @override
  String get shutdownServiceScheduler => '工作排程器';

  @override
  String get shutdownServiceCalendar => '日曆同步';

  @override
  String get shutdownServiceWeather => '天氣';

  @override
  String get shutdownServiceSoundscape => '音景';

  @override
  String get shutdownServiceMeetings => '會議';

  @override
  String get shutdownServiceVoiceModels => '語音模型';

  @override
  String get shutdownServiceNetworking => '網路';

  @override
  String get shutdownServicePresence => '線上狀態';

  @override
  String get shutdownServiceDataSync => '資料同步';

  @override
  String get shutdownServiceDeviceRelay => '裝置轉送';

  @override
  String get shutdownServiceMcpConnections => 'MCP 連線';

  @override
  String get shutdownServiceCodeEditors => '程式碼編輯器';

  @override
  String get serverSharingTitle => '分享此伺服器';

  @override
  String get serverSharingDescription =>
      '讓此伺服器可從你的其他裝置連線。除非你在下方開啟通道，否則不會對外公開。配對邀請會自動帶入伺服器目前的位址；請在工作區設定中建立。';

  @override
  String get serverSharingUnavailable => '此伺服器無法使用分享控制項。';

  @override
  String get serverSharingMdnsLabel => '區域網路探索';

  @override
  String get serverSharingMdnsOn => '正在區域網路（mDNS）上廣播此伺服器';

  @override
  String get serverSharingMdnsOff => '未在區域網路（mDNS）上廣播';

  @override
  String get serverSharingTunnelLabel => '通道';

  @override
  String get serverSharingTunnelHelper =>
      '開啟通道後，即可從網際網路連線到此伺服器。公開曝光需自行開啟，預設為關閉。';

  @override
  String get serverSharingProviderOff => '關閉';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => '公開 URL';

  @override
  String get serverSharingTunnelStarting => '正在啟動通道…';

  @override
  String serverSharingTunnelError(String error) {
    return '通道錯誤：$error';
  }

  @override
  String get serverSharingTunnelUpNoUrl => '通道已啟動。請使用你設定的 DNS 主機名稱連線。';

  @override
  String get serverSharingRelayLabel => '轉送';

  @override
  String serverSharingRelayUsage(String amount) {
    return '本月轉送量：$amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return '使用中的轉送工作階段：$count';
  }

  @override
  String get serverSharingUpdateFailedTitle => '無法更新分享設定';

  @override
  String get pairNewClient => '配對新用戶端';

  @override
  String get pairClientNameHint => '為此用戶端命名（例如：公司筆電）';

  @override
  String get pairClientTypeWeb => '網頁瀏覽器';

  @override
  String get pairClientTypeDesktop => '桌面應用程式';

  @override
  String get pairClientTypePhone => '手機';

  @override
  String get pairAction => '配對';

  @override
  String get revoke => '撤銷';

  @override
  String get pairCredentialsIntro => '用這些資訊連接新用戶端，或在用戶端中開啟連結。';

  @override
  String get pairLinkLabel => '連結';

  @override
  String get pairScanQr => '用手機相機掃描此 QR 碼即可配對。';

  @override
  String get pairServerUnreachableTitle => '無法連線';

  @override
  String get pairServerUnreachable =>
      '其他裝置無法直接連到此伺服器，因此無法連接新用戶端。請設定伺服器的公開 URL 以配對更多用戶端。';

  @override
  String get serverSetupTitle => 'Control Center 要以何種方式執行？';

  @override
  String get serverSetupSubtitle =>
      'Control Center 需要一台保管資料的伺服器。可在此應用程式內執行，或連線到其他位置的執行個體。';

  @override
  String get serverSetupRunLocal => '在此應用程式內執行';

  @override
  String get serverSetupConnect => '連線';

  @override
  String get serverSetupInvalidUrl => '請輸入有效的 ws:// 或 wss:// 伺服器 URL。';

  @override
  String get serverSetupCouldNotConnect => '無法連線';

  @override
  String get serverSetupErrorUnreachable =>
      '無法連到伺服器。請確認伺服器正在執行，且此裝置可連到它（同一網路或經由中繼）。';

  @override
  String get serverSetupErrorIdentityMismatch =>
      '伺服器身分與本裝置儲存的不相符。若伺服器已重新安裝或重設，請移除已儲存的伺服器後再重新配對。';

  @override
  String get serverSetupErrorAuthRejected =>
      '伺服器拒絕了此裝置。請確認配對金鑰與裝置 ID 與伺服器核發的相符。';

  @override
  String get serverSetupErrorInviteRejected => '邀請碼無效或已過期。請索取新的邀請碼。';

  @override
  String get serverSetupErrorGeneric => '連線時發生問題。展開下方技術詳情以取得更多資訊。';

  @override
  String get serverSetupErrorDetails => '技術詳情';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '還有 $count 個',
      one: '還有 1 個',
    );
    return '$_temp0';
  }

  @override
  String get calendarAllDayGutter => '全天';

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個活動',
      one: '1 個活動',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => '收合全天活動';

  @override
  String get calendarExpandAllDay => '展開全天活動';

  @override
  String get calendarViewMonth => '月';

  @override
  String get calendarViewWeek => '週';

  @override
  String get calendarViewAgenda => '議程';

  @override
  String get calendarConnectGoogle => '連接 Google Calendar';

  @override
  String get calendarConnectDescription =>
      '同步 Google Calendar，即可在此查看活動，並在會議開始前收到提醒。';

  @override
  String get calendarDisconnect => '中斷連線';

  @override
  String get calendarReconnect => '重新連線';

  @override
  String get calendarEmptyNoEvents => '此範圍內沒有活動';

  @override
  String get calendarStartRecording => '開始錄製';

  @override
  String get calendarStartRecordingAndLink => '開始錄製並連結';

  @override
  String get calendarJoinMeet => '加入會議';

  @override
  String get calendarFromCalendar => '來自行事曆';

  @override
  String get calendarLinkedMeeting => '已連結會議';

  @override
  String get calendarToday => '今天';

  @override
  String get calendarAllDay => '全天';

  @override
  String calendarWeekNumber(int number) {
    return '第 $number 週';
  }

  @override
  String get calendarPreviousPeriod => '上一個';

  @override
  String get calendarNextPeriod => '下一個';

  @override
  String calendarLastSynced(String time) {
    return '已同步 $time';
  }

  @override
  String get calendarNeverSynced => '尚未同步';

  @override
  String get calendarSyncing => '同步中…';

  @override
  String get calendarViewDay => '日';

  @override
  String get calendarShow => '顯示';

  @override
  String get calendarHide => '隱藏';

  @override
  String get calendarRsvpGoing => '要參加嗎？';

  @override
  String get calendarRsvpYes => '是';

  @override
  String get calendarRsvpNo => '否';

  @override
  String get calendarRsvpMaybe => '待定';

  @override
  String get calendarRsvpFailed => '無法更新你的回覆';

  @override
  String get calendarAddAccount => '新增日曆帳號';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      '連結 Google 帳號，將活動同步到此工作區。這些日曆在這裡屬於你。';

  @override
  String get calendarConnecting => '連線中…';

  @override
  String get calendarSyncNow => '立即同步';

  @override
  String get calendarNoWorkspace => '請選取工作區以檢視其日曆';

  @override
  String get calendarConnectError => '無法連線 Google Calendar';

  @override
  String get calendarClientIdLabel => '用戶端 ID';

  @override
  String get calendarClientSecretLabel => '用戶端密鑰';

  @override
  String get calendarConnectCredsHint =>
      '輸入專案的 Google OAuth 裝置代碼用戶端 ID 與密鑰。連線與同步由伺服器執行，瀏覽器不會保存權杖。';

  @override
  String get calendarConnectApproveInstruction => '在任何裝置上開啟驗證頁面，登入後輸入此代碼：';

  @override
  String get calendarConnectOpenPage => '開啟驗證頁面';

  @override
  String get calendarConnectWaiting => '等待核准中…';

  @override
  String get calendarConnectDenied => '授權遭拒，請再試一次。';

  @override
  String get calendarConnectExpired => '代碼已過期，請再試一次。';

  @override
  String get notificationMeetingStartsSoon => '會議即將開始';

  @override
  String get notifyMeetingStartsSoon => '日曆會議即將開始時';

  @override
  String get notificationCalendarAuthExpiredTitle => '日曆已中斷連線';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return '重新連線 $email 以繼續同步';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail => '重新連線日曆以繼續同步';

  @override
  String get notifyCalendarAuthExpired => '日曆帳號需要重新連線時';

  @override
  String get notificationRigStatusChanged => '機箱更新';

  @override
  String get notifyRigStatusChanged => '機箱被接管、收回或失敗時';

  @override
  String get notificationRigTakenOver => '機箱已被接管';

  @override
  String get notificationRigTakenOverBody => '有人正在操作機器；代理可觀看但無法執行動作。';

  @override
  String get notificationRigReleased => '機箱控制權已釋放';

  @override
  String get notificationRigReleasedBody => '代理已重新取得機器。';

  @override
  String get notificationRigReclaimed => '機箱已收回';

  @override
  String get notificationRigReclaimedBodyIdle => '因閒置過久，已關閉機器以釋放記憶體。';

  @override
  String get notificationRigReclaimedBodyTtl => '已達時間上限，機器已關閉。';

  @override
  String get notificationRigFailed => '機箱失敗';

  @override
  String get notificationRigFailedBody => '底層 hypervisor 已終止。請重新開啟機器以繼續。';

  @override
  String get calendarAlertLeadTime => '提醒提前時間';

  @override
  String get calendarAlertLeadTimeSubtitle => '會議開始前多久提醒你';

  @override
  String calendarConnectedAs(String email) {
    return '已連線為 $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count 位與會者';
  }

  @override
  String get calendarEventLabel => '活動';

  @override
  String get calendarRecurring => '重複活動';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => '主辦人';

  @override
  String get calendarYou => '你';

  @override
  String get calendarShowFewer => '顯示較少';

  @override
  String get calendarRsvpAwaiting => '等待中';

  @override
  String calendarParticipantsCount(int count) {
    return '$count 位參與者';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return '查看全部 $count 位參與者';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count 是';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count 否';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count 或許';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count 待回覆';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count 分鐘';
  }

  @override
  String get openInEditorPrompt => '要在哪個編輯器中開啟？';

  @override
  String get ideNotInstalled => '尚未安裝';

  @override
  String openInIde(String editor) {
    return '在 $editor 中開啟';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return '無法開啟 $editor：$error';
  }

  @override
  String get profileSearchHint => '搜尋 pull request…';

  @override
  String get stopAgentRun => '停止執行';

  @override
  String get stopAgentRunConfirm => '要停止這次執行嗎？進行中的工作將會遺失。';

  @override
  String get inProgress => '進行中';

  @override
  String get drafts => '草稿';

  @override
  String get sortOldest => '最舊';

  @override
  String get sortLargest => '最大';

  @override
  String get prFilterTooltip => '篩選';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個使用中篩選',
      one: '1 個使用中篩選',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => '新增篩選…';

  @override
  String get prFilterFieldHint => '篩選…';

  @override
  String get prFilterCategoryStatus => '狀態';

  @override
  String get prFilterCategoryAuthor => '作者';

  @override
  String get prFilterCategoryReviewer => '審查者';

  @override
  String get prFilterCategoryContent => '內容';

  @override
  String get prFilterCategoryRepoOwner => '存放庫擁有者';

  @override
  String get prFilterCategoryRepoName => '存放庫名稱';

  @override
  String get prFilterCategoryOpenedDate => '開啟日期';

  @override
  String get prFilterCategoryUpdatedDate => '更新日期';

  @override
  String get prFilterQuickToReview => '可快速審查';

  @override
  String get prFilterClearAll => '清除篩選';

  @override
  String prFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個 pull request',
      one: '1 個 pull request',
    );
    return '$_temp0';
  }

  @override
  String prFilterHiddenOptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個選項未符合任何 pull request',
      one: '1 個選項未符合任何 pull request',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => '標題或內文包含…';

  @override
  String get prFilterNoOptions => '沒有相符的選項';

  @override
  String get prFilterChipIs => '為';

  @override
  String get prFilterChipIsAnyOf => '為以下任一';

  @override
  String get prFilterChipContains => '包含';

  @override
  String get prFilterChipSince => '自';

  @override
  String get prFilterAddFilterButton => '新增篩選';

  @override
  String prFilterClearCategory(String category) {
    return '清除 $category 篩選';
  }

  @override
  String get prFilterCurrentUser => '目前使用者';

  @override
  String get prStatusDraft => '草稿';

  @override
  String get prStatusOpen => '開啟';

  @override
  String get prStatusInReview => '審查中';

  @override
  String get prStatusChangesRequested => '要求變更';

  @override
  String get prStatusApproved => '已核准';

  @override
  String get prStatusMerged => '已合併';

  @override
  String get prStatusClosed => '已關閉';

  @override
  String get prDateWindowDay => '1 天前';

  @override
  String get prDateWindowThreeDays => '3 天前';

  @override
  String get prDateWindowWeek => '1 週前';

  @override
  String get prDateWindowMonth => '1 個月前';

  @override
  String get prDateWindowThreeMonths => '3 個月前';

  @override
  String get prDateWindowSixMonths => '6 個月前';

  @override
  String get prDateWindowYear => '1 年前';

  @override
  String get prDisplayOptions => '顯示選項';

  @override
  String get prDisplayGrouping => '分組';

  @override
  String get prDisplayOrdering => '排序';

  @override
  String get prDisplayShowDrafts => '顯示草稿';

  @override
  String get prDisplayMergedWindow => '已合併時間範圍';

  @override
  String get prDisplayMergedWindowDay => '過去 1 天';

  @override
  String get prDisplayMergedWindowWeek => '過去 1 週';

  @override
  String get prDisplayMergedWindowMonth => '過去 1 個月';

  @override
  String get prDisplayProperties => '顯示屬性';

  @override
  String get prGroupingRepository => '存放庫';

  @override
  String get prGroupingAuthor => '作者';

  @override
  String get prGroupingStatus => '狀態';

  @override
  String get prGroupingNone => '不分組';

  @override
  String get prPropertyRepository => '存放庫';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => '分支';

  @override
  String get prPropertyUpdated => '更新時間';

  @override
  String get prPropertyAuthor => '作者';

  @override
  String get prPropertyChecks => '檢查';

  @override
  String get prPropertyDiff => '差異';

  @override
  String get prPropertyComments => '留言';

  @override
  String get keybindingOpenFilterMenu => '開啟篩選選單';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      '開啟 pull request 篩選選單';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已選取 $count 項',
      one: '已選取 1 項',
    );
    return '$_temp0';
  }

  @override
  String get summary => '摘要';

  @override
  String get kbMove => '移動';

  @override
  String get kbTabs => '分頁';

  @override
  String get kbSearch => '搜尋';

  @override
  String get kbViewed => '已檢視';

  @override
  String get kbCollapse => '收合';

  @override
  String get appearance => '外觀';

  @override
  String get appearanceSettingsDescription => '主題、語言與字型。';

  @override
  String get notificationsSettingsDescription => '選擇要接收通知的代理與工作區事件。';

  @override
  String get advanced => '進階';

  @override
  String get accounts => '帳戶';

  @override
  String get mcpServers => 'MCP 伺服器';

  @override
  String get mcpServersSettingsDescription => '內建 MCP 伺服器與外部 MCP 伺服器。';

  @override
  String get remoteControlAndDevices => '遠端控制與裝置';

  @override
  String get remoteControlAndDevicesSettingsDescription => '配對手機並設定遠端控制伺服器。';

  @override
  String get voiceAndMeetingsSettingsDescription => '此伺服器託管的語音與語者分離模型。';

  @override
  String get needsSetupLabel => '需要設定';

  @override
  String get collapseSidebar => '收合側邊欄';

  @override
  String get expandSidebar => '展開側邊欄';

  @override
  String get filterSpacesHint => '篩選空間';

  @override
  String noSpacesMatch(String query) {
    return '沒有符合「$query」的空間';
  }

  @override
  String get privacy => '隱私';

  @override
  String get sendDiffContentTitle => '將 diff 內容傳送給 AI 轉接器';

  @override
  String get diffSharingOnSubtitle => '原始 diff 行會納入代理提示，以便更深入檢視。';

  @override
  String get diffSharingOffSubtitle =>
      '代理僅使用結構化中繼資料（檔案路徑、行號、PR 說明）；原始程式碼不會離開應用程式。';

  @override
  String get errorReportingTitle => '分享當機報告';

  @override
  String get errorReportingOnSubtitle => '會傳送當機、錯誤與效能診斷資料以協助修正錯誤（僅限發行版組建）。';

  @override
  String get errorReportingOffSubtitle => '診斷已關閉。不會傳送當機或錯誤報告。';

  @override
  String get onboardingDiagnosticsTitle => '協助改善 Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      '傳送當機、錯誤與效能診斷資料，以便我們更快修正問題（僅限發行版組建）。可隨時在「設定 → 隱私」變更。';

  @override
  String get blocked => '已封鎖';

  @override
  String get idle => '閒置';

  @override
  String get noRunsYet => '尚無執行紀錄';

  @override
  String get copyPath => '複製路徑';

  @override
  String get copyRelativePath => '複製相對路徑';

  @override
  String get nameRequired => '必須填寫名稱';

  @override
  String get import => '匯入';

  @override
  String get noMatchingAgents => '沒有符合篩選條件的代理';

  @override
  String watchVideoOn(String provider) {
    return '在 $provider 觀看影片';
  }

  @override
  String get branchTemplate => '分支名稱範本';

  @override
  String get branchTemplateDescription => '在隔離工作樹中開始工單時所建立分支的模式。';

  @override
  String branchTemplatePreview(String example) {
    return '範例：$example';
  }

  @override
  String get deletePipelineRun => '刪除管線執行';

  @override
  String deletePipelineRunConfirm(String template) {
    return '要刪除「$template」的這次執行嗎？此動作無法復原。';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return '刪除管線執行時發生錯誤：$error';
  }

  @override
  String get deleteTicket => '刪除工單';

  @override
  String deleteTicketConfirm(String title) {
    return '要刪除「$title」嗎？此動作無法復原。';
  }

  @override
  String errorDeletingTicket(String error) {
    return '刪除工單時發生錯誤：$error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return '要刪除「$name」嗎？磁碟上的連結儲存庫不會受影響。';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return '刪除工作區時發生錯誤：$error';
  }

  @override
  String get indexCode => '建立程式碼索引';

  @override
  String get indexNoGrammars => '尚未安裝程式碼文法';

  @override
  String get indexFailed => '索引失敗';

  @override
  String indexedSymbolsCount(int count) {
    return '已索引 $count 個符號';
  }

  @override
  String get nodeConfigAdvanced => '進階';

  @override
  String get nodeConfigReducer => '縮減器';

  @override
  String get nodeConfigReducerHelp => '當此輸出鍵已有值時的合併方式';

  @override
  String get nodeConfigTimeoutMs => '逾時（毫秒）';

  @override
  String get nodeConfigRetryAttempts => '重試次數';

  @override
  String get nodeConfigContinueOnFail => '此步驟失敗時仍繼續';

  @override
  String get nodeConfigTeamId => '團隊 ID';

  @override
  String get nodeConfigDispatchMode => '分派模式';

  @override
  String get nodeConfigOutputSchema => '輸出結構描述（JSON）';

  @override
  String get nodeConfigOutputSchemaHelp => '步驟輸出必須符合的 JSON Schema';

  @override
  String get diffLineDisplay => 'diff 中的長行';

  @override
  String get diffLineDisplayDescription => '換行顯示長行，或水平捲動';

  @override
  String get diffLineWrap => '換行';

  @override
  String get diffLineScroll => '水平捲動';

  @override
  String get actions => '動作';

  @override
  String get activate => '啟用';

  @override
  String get activity => '活動';

  @override
  String get activityLabel => '活動';

  @override
  String get activitySearchHint => '搜尋活動';

  @override
  String get activityNoMatches => '沒有符合篩選條件的活動';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end，共 $total 筆';
  }

  @override
  String get activityPreviousPage => '上一頁';

  @override
  String get activityNextPage => '下一頁';

  @override
  String get activityNetworkLocal => '本機';

  @override
  String get activityClearFilter => '清除篩選';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return '國家 $country';
  }

  @override
  String get activitySavedWorkspaceLogo => '已儲存工作區標誌';

  @override
  String activityVerbCreated(String target) {
    return '已建立 $target';
  }

  @override
  String activityVerbUpdated(String target) {
    return '已更新 $target';
  }

  @override
  String activityVerbDeleted(String target) {
    return '已刪除 $target';
  }

  @override
  String activityVerbAdded(String target) {
    return '已新增 $target';
  }

  @override
  String activityVerbRemoved(String target) {
    return '已移除 $target';
  }

  @override
  String activityVerbInvited(String target) {
    return '已邀請 $target';
  }

  @override
  String activityVerbChanged(String target) {
    return '已變更 $target';
  }

  @override
  String activityVerbStarted(String target) {
    return '已啟動 $target';
  }

  @override
  String activityVerbStopped(String target) {
    return '已停止 $target';
  }

  @override
  String activityVerbWrote(String target) {
    return '已撰寫 $target';
  }

  @override
  String get activityTargetAgent => '代理';

  @override
  String get activityTargetTicket => '工單';

  @override
  String get activityTargetWorkspace => '工作區';

  @override
  String get activityTargetRepository => '儲存庫';

  @override
  String get activityTargetMember => '成員';

  @override
  String get activityTargetInvite => '邀請';

  @override
  String get activityTargetSpace => '空間';

  @override
  String get activityTargetMessage => '訊息';

  @override
  String get activityTargetCache => '快取';

  @override
  String get activityTargetFile => '檔案';

  @override
  String get activityTargetPipeline => '管線';

  @override
  String get activityTargetTemplate => '範本';

  @override
  String get activityTargetProvider => '提供者';

  @override
  String get activityTargetModel => '模型';

  @override
  String get activityTargetSkill => '技能';

  @override
  String get activityTargetTodo => '待辦';

  @override
  String get activityTargetMeeting => '會議';

  @override
  String get activityTargetProject => '專案';

  @override
  String get activityTargetTeam => '團隊';

  @override
  String get activityTargetDevice => '裝置';

  @override
  String get activityTargetPreference => '偏好設定';

  @override
  String get activityTargetBudget => '預算';

  @override
  String activityVerbApproved(String target) {
    return '已核准 $target';
  }

  @override
  String activityVerbArchived(String target) {
    return '已封存 $target';
  }

  @override
  String activityVerbAssigned(String target) {
    return '已指派 $target';
  }

  @override
  String activityVerbBackedUp(String target) {
    return '已備份 $target';
  }

  @override
  String activityVerbCancelled(String target) {
    return '已取消 $target';
  }

  @override
  String activityVerbCleared(String target) {
    return '已清除 $target';
  }

  @override
  String activityVerbClosed(String target) {
    return '已關閉 $target';
  }

  @override
  String activityVerbCommitted(String target) {
    return '已提交 $target';
  }

  @override
  String activityVerbCompacted(String target) {
    return '已壓縮 $target';
  }

  @override
  String activityVerbCompleted(String target) {
    return '已完成 $target';
  }

  @override
  String activityVerbConnected(String target) {
    return '已連線 $target';
  }

  @override
  String activityVerbContinued(String target) {
    return '已繼續 $target';
  }

  @override
  String activityVerbDisconnected(String target) {
    return '已中斷連線 $target';
  }

  @override
  String activityVerbDispatched(String target) {
    return '已派送 $target';
  }

  @override
  String activityVerbDrained(String target) {
    return '已排空 $target';
  }

  @override
  String activityVerbEnrolled(String target) {
    return '已註冊 $target';
  }

  @override
  String activityVerbEstimated(String target) {
    return '已估算 $target';
  }

  @override
  String activityVerbImported(String target) {
    return '已匯入 $target';
  }

  @override
  String activityVerbInstalled(String target) {
    return '已安裝 $target';
  }

  @override
  String activityVerbKilled(String target) {
    return '已強制結束 $target';
  }

  @override
  String activityVerbMarked(String target) {
    return '已標記 $target';
  }

  @override
  String activityVerbMerged(String target) {
    return '已合併 $target';
  }

  @override
  String activityVerbOpened(String target) {
    return '已開啟 $target';
  }

  @override
  String activityVerbPaused(String target) {
    return '已暫停 $target';
  }

  @override
  String activityVerbPolled(String target) {
    return '已輪詢 $target';
  }

  @override
  String activityVerbPrepared(String target) {
    return '已準備 $target';
  }

  @override
  String activityVerbProcessed(String target) {
    return '已處理 $target';
  }

  @override
  String activityVerbPublished(String target) {
    return '已發布 $target';
  }

  @override
  String activityVerbRefined(String target) {
    return '已精煉 $target';
  }

  @override
  String activityVerbRefreshed(String target) {
    return '已重新整理 $target';
  }

  @override
  String activityVerbRegistered(String target) {
    return '已登錄 $target';
  }

  @override
  String activityVerbRenamed(String target) {
    return '已重新命名 $target';
  }

  @override
  String activityVerbReordered(String target) {
    return '已重新排序 $target';
  }

  @override
  String activityVerbResponded(String target) {
    return '已回覆 $target';
  }

  @override
  String activityVerbRestored(String target) {
    return '已還原 $target';
  }

  @override
  String activityVerbResumed(String target) {
    return '已恢復 $target';
  }

  @override
  String activityVerbRetried(String target) {
    return '已重試 $target';
  }

  @override
  String activityVerbReverted(String target) {
    return '已還原變更 $target';
  }

  @override
  String activityVerbReviewed(String target) {
    return '已審查 $target';
  }

  @override
  String activityVerbRan(String target) {
    return '已執行 $target';
  }

  @override
  String activityVerbSelected(String target) {
    return '已選取 $target';
  }

  @override
  String activityVerbSent(String target) {
    return '已傳送 $target';
  }

  @override
  String activityVerbStaged(String target) {
    return '已暫存 $target';
  }

  @override
  String activityVerbSteered(String target) {
    return '已引導 $target';
  }

  @override
  String activityVerbSubmitted(String target) {
    return '已送出 $target';
  }

  @override
  String activityVerbSynced(String target) {
    return '已同步 $target';
  }

  @override
  String activityVerbToggled(String target) {
    return '已切換 $target';
  }

  @override
  String activityVerbUninstalled(String target) {
    return '已解除安裝 $target';
  }

  @override
  String activityVerbUnstaged(String target) {
    return '已取消暫存 $target';
  }

  @override
  String get activityTargetActionPolicy => '動作原則';

  @override
  String get activityTargetGoalRun => '目標執行';

  @override
  String get activityTargetRunLog => '執行紀錄';

  @override
  String get activityTargetWorkingMemory => '工作記憶';

  @override
  String get activityTargetRoutingPolicy => '路由原則';

  @override
  String get activityTargetAutonomy => '自主性';

  @override
  String get activityTargetCalendar => '行事曆';

  @override
  String get activityTargetChecker => '檢查器';

  @override
  String get activityTargetEditor => '編輯器';

  @override
  String get activityTargetConfirmation => '確認';

  @override
  String get activityTargetTunnel => '通道';

  @override
  String get activityTargetConversation => '對話';

  @override
  String get activityTargetCredentials => '憑證';

  @override
  String get activityTargetDictation => '聽寫';

  @override
  String get activityTargetAgentRun => '代理執行';

  @override
  String get activityTargetEvalSuite => '評測套件';

  @override
  String get activityTargetWorker => '工作者';

  @override
  String get activityTargetWorktree => '工作樹';

  @override
  String get activityTargetMcpServer => 'MCP 伺服器';

  @override
  String get activityTargetMemoryAccessGrant => '記憶存取授權';

  @override
  String get activityTargetMemoryDomain => '記憶網域';

  @override
  String get activityTargetMemoryFact => '記憶事實';

  @override
  String get activityTargetMemoryPolicy => '記憶原則';

  @override
  String get activityTargetFeed => '動態';

  @override
  String get activityTargetNote => '筆記';

  @override
  String get activityTargetOrchestration => '編排';

  @override
  String get activityTargetPipelineRun => '管線執行';

  @override
  String get activityTargetPipelineTrigger => '管線觸發器';

  @override
  String get activityTargetPlan => '計畫';

  @override
  String get activityTargetPlaybook => '劇本';

  @override
  String get activityTargetPullRequest => 'pull request';

  @override
  String get activityTargetReview => '審查';

  @override
  String get activityTargetProcess => '程序';

  @override
  String get activityTargetProviderPolicy => '供應商原則';

  @override
  String get activityTargetReaction => '反應';

  @override
  String get activityTargetReviewSpace => '審查空間';

  @override
  String get activityTargetReviewStudio => '審查工作室';

  @override
  String get activityTargetServerData => '伺服器資料';

  @override
  String get activityTargetSoundscape => '音景';

  @override
  String get activityTargetSession => '工作階段';

  @override
  String get activityTargetTerminal => '終端機';

  @override
  String get activityTargetTicketLink => '工單連結';

  @override
  String get activityTargetTicketSync => '工單同步';

  @override
  String get activityTargetProfile => '個人檔案';

  @override
  String get activityTargetVoiceProfile => '語音設定檔';

  @override
  String get activityTargetWeather => '天氣預報';

  @override
  String get activityTargetWorkProduct => '工作成品';

  @override
  String get activityChangedMemberRole => '已變更成員角色';

  @override
  String get activityChangedMemberRepoAccess => '已變更成員的存放庫存取權限';

  @override
  String get activityUpdatedGitHubToken => '已更新 GitHub 權杖';

  @override
  String get activityRefreshedWeather => '已重新整理天氣預報';

  @override
  String get activitySetWeatherLocation => '已設定天氣位置';

  @override
  String get activityClearedWeatherLocation => '已清除天氣位置';

  @override
  String get activityMarkedAllArticlesRead => '已將所有文章標為已讀';

  @override
  String get activityMarkedArticleRead => '已將一篇文章標為已讀';

  @override
  String get activityUpdatedSavedArticle => '已更新一篇已儲存的文章';

  @override
  String get activityTookOverSession => '已接管工作階段';

  @override
  String get activityHandedBackSession => '已交還工作階段';

  @override
  String get activityCommittedAndPushed => '已提交並推送';

  @override
  String get activityBackedUpServer => '已備份伺服器資料';

  @override
  String get activityMarkedSpaceRead => '已將空間標為已讀';

  @override
  String get activityRespondedToInvitation => '已回應活動邀請';

  @override
  String get activityStartedCalendarConnect => '已開始連接日曆';

  @override
  String get activityDisconnectedCalendar => '已中斷日曆連線';

  @override
  String get activityMarkedFileViewed => '已將檔案標為已檢視';

  @override
  String get activityRespondedToApproval => '已回應核准請求';

  @override
  String get activityChangedTunnel => '已變更通道設定';

  @override
  String get activitySentMessageToAgent => '已傳送訊息給代理';

  @override
  String get activityOpenedReviewSpace => '已開啟審查空間';

  @override
  String get activityOpenedStandingConversation => '已開啟常駐對話';

  @override
  String get activityStartedRecording => '已開始錄製';

  @override
  String get activityStoppedRecording => '已停止錄製';

  @override
  String get activityToggledMcpServer => '已切換 MCP 伺服器';

  @override
  String get activityUpdatedMcpToken => '已更新 MCP 權杖';

  @override
  String get activitySavedApiKey => '已儲存 API 金鑰';

  @override
  String get activityRemovedProviderCredential => '已移除供應商憑證';

  @override
  String get activityUpdatedLinkedRepos => '已更新連結的存放庫';

  @override
  String get activityUnlinkedRepo => '已取消連結存放庫';

  @override
  String get activityUpdatedActionItem => '已更新待辦項目';

  @override
  String adRulesCount(int count) {
    return '$count 則廣告規則';
  }

  @override
  String get adapter => '配接器';

  @override
  String get adapterLabel => '配接器';

  @override
  String get adapters => '配接器';

  @override
  String get adaptersAutoDetected => '已自動偵測本機上可用的代理執行器。請安裝缺少的 CLI 工具以啟用更多執行器。';

  @override
  String get add => '新增';

  @override
  String get addAComment => '新增留言';

  @override
  String get addAReaction => '新增表情反應';

  @override
  String get addASuggestion => '新增建議';

  @override
  String get addAgents => '新增代理';

  @override
  String get addEmoji => '新增表情符號';

  @override
  String get addFeed => '新增動態來源';

  @override
  String get addressBarHint => '輸入網址';

  @override
  String get addFromFile => '從檔案新增';

  @override
  String get addGif => '新增 GIF';

  @override
  String get addGithubRepoPrompt => '請至少新增一個 GitHub 存放庫以查看 pull request';

  @override
  String get addLocalCheckoutDescription => '新增本機 checkout，即可從此工作區指定目標。';

  @override
  String get addRepository => '新增存放庫';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '新增 $count 個存放庫',
      one: '新增存放庫',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro => '瀏覽執行伺服器之機器上的資料夾，並選取要註冊的 git checkout。';

  @override
  String get selectThisFolder => '選取此資料夾';

  @override
  String get deselectThisFolder => '取消選取此資料夾';

  @override
  String get goUp => '上一層';

  @override
  String get noSubfoldersHere => '此處沒有子資料夾';

  @override
  String get notAGitRepository => '此資料夾不是 git 儲存庫。';

  @override
  String get addToken => '新增權杖';

  @override
  String get addWorkspace => '新增工作區';

  @override
  String get addWorkspaceEllipsis => '新增工作區…';

  @override
  String get added => '已新增';

  @override
  String get addingEllipsis => '正在新增…';

  @override
  String get advancedLabel => '進階';

  @override
  String get agent => '代理';

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
  String get agentMdPath => '代理 MD 路徑';

  @override
  String get agentName => '代理名稱';

  @override
  String get agentTitle => '代理標題';

  @override
  String get agentUpdated => '代理已更新。';

  @override
  String get agents => '代理';

  @override
  String get agentsMentionSection => '代理';

  @override
  String get usersMentionSection => '人員';

  @override
  String get ticketsMentionSection => '工單';

  @override
  String get pullRequestsMentionSection => 'Pull requests';

  @override
  String get meetingsMentionSection => '會議';

  @override
  String get entityRefTicketFallback => '工單';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => '會議';

  @override
  String get aiReview => 'AI 審查';

  @override
  String get all => '全部';

  @override
  String get allAgentsAlreadyInSpace => '所有代理都已在此空間中。';

  @override
  String get allCommits => '所有提交';

  @override
  String get allSources => '所有來源';

  @override
  String get allow => '允許';

  @override
  String get allowGitPush => '允許 git push';

  @override
  String get allowGithubApi => '允許 GitHub API 呼叫';

  @override
  String get allowNetwork => '允許一般網路存取';

  @override
  String get apiKeys => 'API 金鑰';

  @override
  String get appFont => '應用程式字型';

  @override
  String get appLogLevelDebugDescription => '加入詳細追蹤，供開發使用。';

  @override
  String get appLogLevelDebugLabel => '偵錯';

  @override
  String get appLogLevelErrorDescription => '僅顯示未預期的錯誤和例外。';

  @override
  String get appLogLevelErrorLabel => '錯誤';

  @override
  String get appLogLevelInfoDescription => '加入生命週期和狀態訊息。';

  @override
  String get appLogLevelInfoLabel => '資訊';

  @override
  String get appLogLevelNoneDescription => '完全不輸出至主控台。';

  @override
  String get appLogLevelNoneLabel => '無';

  @override
  String get appLogLevelVerboseDescription => '全部輸出。極度冗長，僅供偵錯使用。';

  @override
  String get appLogLevelVerboseLabel => '詳細';

  @override
  String get appLogLevelWarningDescription => '加入警告和可復原的問題。';

  @override
  String get appLogLevelWarningLabel => '警告';

  @override
  String get appearanceLanguage => '外觀與語言';

  @override
  String get apply => '套用';

  @override
  String get approve => '核准';

  @override
  String get agentApprovalRequired => '需要核准';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '還有 $count 個等待中',
      one: '還有 1 個等待中',
    );
    return '$_temp0';
  }

  @override
  String get approved => '已核准';

  @override
  String get articleNoun => '文章';

  @override
  String get articlesSubscribed => '你訂閱的動態來源中的文章。';

  @override
  String get askAi => '詢問 AI';

  @override
  String get askAiReviewDescription => '請 AI 審查此 PR';

  @override
  String get assignees => '指派對象';

  @override
  String get attachImage => '附加圖片';

  @override
  String get attachedAgents => '已附加的代理';

  @override
  String get audioInput => '音訊輸入';

  @override
  String get audioOutput => '音訊輸出';

  @override
  String get authenticationToken => '驗證權杖';

  @override
  String authoredByLabel(String role) {
    return '由：$role';
  }

  @override
  String get autoRecommended => '自動（建議）';

  @override
  String get available => '可用';

  @override
  String get awaitingYourReview => '等待你的審查';

  @override
  String get back => '返回';

  @override
  String get backLabel => '返回';

  @override
  String get backend => '後端';

  @override
  String get blockAdsTrackers => '封鎖廣告、追蹤器與 Cookie 橫幅';

  @override
  String get blocking => '阻擋';

  @override
  String get bookmarkLabel => '書籤';

  @override
  String get briefDescription => '簡短說明';

  @override
  String get bugLabel => '錯誤';

  @override
  String get bundledDefaultsNeverUpdated => '內建預設值 — 永不更新';

  @override
  String get cancel => '取消';

  @override
  String get cancelEdit => '取消編輯';

  @override
  String get categoryCreation => '建立';

  @override
  String get categoryEditing => '編輯';

  @override
  String get categoryNavigation => '導覽';

  @override
  String get categorySystem => '系統';

  @override
  String get categoryView => '分類檢視';

  @override
  String get change => '變更';

  @override
  String get changesRequested => '要求變更';

  @override
  String get spacesMentionSection => '空間';

  @override
  String get checkForUpdates => '檢查更新';

  @override
  String get checking => '檢查中';

  @override
  String get checkingEllipsis => '檢查中…';

  @override
  String get chooseAppFont => '選擇應用程式字型';

  @override
  String get chooseCodeFont => '選擇程式碼字型';

  @override
  String get chooseRunner => '選擇你的代理執行器。';

  @override
  String get clear => '清除';

  @override
  String get clickToRetry => '點一下即可重試';

  @override
  String get close => '關閉';

  @override
  String get closeEsc => '關閉 (Esc)';

  @override
  String get closeReader => '關閉閱讀器';

  @override
  String get closed => '已關閉';

  @override
  String get codeFont => '程式碼字型';

  @override
  String get codeFontLigatures => '程式碼字型連字';

  @override
  String get codeFontLigaturesDescription =>
      '在程式碼與 diff 中將程式連字（=>、!=、->）顯示為合併字形';

  @override
  String get collapse => '收合';

  @override
  String get commandPalette => '命令面板';

  @override
  String get commandPaletteOrgMembers => '組織成員';

  @override
  String get commandPaletteBrowseTeam => '瀏覽團隊';

  @override
  String get commandPaletteBrowseTeamDesc => '檢視所有組織成員';

  @override
  String get compactDone => '對話已精簡。較早的紀錄已摺疊為摘要。';

  @override
  String get compactNothing => '目前無需精簡。對話仍很短。';

  @override
  String get compactBusy => '代理仍在運作中。請等此輪結束後再精簡。';

  @override
  String get compactUnavailable => '此伺服器無法使用精簡功能。';

  @override
  String get commandsMentionSection => '指令';

  @override
  String get comment => '評論';

  @override
  String get commentOnThisFile => '對此檔案發表評論';

  @override
  String get commented => '已評論';

  @override
  String get commits => '提交';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return '顯示最新 $loaded 筆，共 $total 筆提交';
  }

  @override
  String get prCloneProgressCloningTitle => '正在複製儲存庫';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return '此 PR 變更了 $fileCount 個檔案，已超出 GitHub 的 API 限制。正在本機複製儲存庫…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      '此 PR 超出 GitHub 的 API 檔案數量限制。正在本機複製儲存庫…';

  @override
  String get prCloneProgressFetchingTitle => '正在擷取 PR 參照';

  @override
  String get prCloneProgressFetchingSubtitle => '正在擷取基底分支與 PR head 參照…';

  @override
  String get prCloneProgressComputingTitle => '正在計算差異';

  @override
  String get prCloneProgressComputingSubtitle => '正在本機執行 git diff…';

  @override
  String get prCloneProgressErrorTitle => '無法載入差異';

  @override
  String get prCloneProgressErrorSubtitle => '複製儲存庫或計算差異時發生錯誤。請試著重新整理。';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return '仍在處理… 已過 $elapsed';
  }

  @override
  String confidenceLabel(int percent) {
    return '信心：$percent%';
  }

  @override
  String get configureAgentIdentities => '設定代理身分、提示詞、技能並檢視執行紀錄。';

  @override
  String get configureDefaultRunners => '設定新空間與標題產生所用的轉接器與模型。';

  @override
  String get configuredLabel => '已設定。';

  @override
  String get confirmedBy => '確認者';

  @override
  String get consensus => '共識';

  @override
  String get contentHint => '應記住的內容';

  @override
  String get contentLabel => '內容';

  @override
  String get contentMarkdown => '內容（Markdown）';

  @override
  String get contextWindowSize => '上下文視窗大小';

  @override
  String modelContextChip(String size) {
    return '模型 · $size';
  }

  @override
  String get continueLabel => '繼續';

  @override
  String get conversationMode => '模式';

  @override
  String cookieRulesCount(int count) {
    return '$count 條 Cookie 規則';
  }

  @override
  String get copied => '已複製！';

  @override
  String get copy => '複製';

  @override
  String get copyAddress => '複製位址';

  @override
  String get copyBaseBranchTooltip => '複製基底分支名稱';

  @override
  String get copyHeadBranchTooltip => '複製 head 分支名稱';

  @override
  String couldNotListDevices(String error) {
    return '無法列出裝置：$error';
  }

  @override
  String get create => '建立';

  @override
  String get createOrSelectWorkspace => '新增儲存庫前，請先建立或選取工作區。';

  @override
  String get createPullRequest => '建立 pull request';

  @override
  String get createdByMe => '由我建立';

  @override
  String createdLabel(String date) {
    return '建立時間：$date';
  }

  @override
  String get currentParticipants => '目前參與者';

  @override
  String get customCapabilitiesDescription => '自訂能力說明';

  @override
  String get customSystemPrompt => '此代理的自訂系統提示…';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天前',
      one: '1 天前',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => '停用';

  @override
  String get defaultCapabilities => '預設能力 · 新空間';

  @override
  String get defaultChat => '預設聊天';

  @override
  String get defaultRunners => '預設執行器';

  @override
  String get delete => '刪除';

  @override
  String get deleteAgent => '刪除代理';

  @override
  String deleteAgentConfirm(String name) {
    return '要刪除「$name」嗎？此操作無法復原。';
  }

  @override
  String get deleteSpace => '刪除空間';

  @override
  String deleteConfirmName(String name) {
    return '要刪除「$name」嗎？';
  }

  @override
  String get archiveConversation => '封存對話';

  @override
  String get deleteFact => '刪除事實';

  @override
  String get deleteFeedBody => '這會移除訂閱來源及其所有快取文章。此訂閱來源中已加入書籤的文章也會一併移除。';

  @override
  String deleteFeedConfirm(String name) {
    return '要刪除「$name」嗎？';
  }

  @override
  String get deletePolicy => '刪除政策';

  @override
  String get deletePolicyConfirm => '要刪除此政策嗎？此操作無法復原。';

  @override
  String deleteTopicConfirm(String topic) {
    return '要刪除「$topic」嗎？此操作無法復原。';
  }

  @override
  String get deleteWorkspace => '刪除工作區';

  @override
  String get deny => '拒絕';

  @override
  String get detailsLabel => '詳細資料';

  @override
  String get descriptionLabel => '說明';

  @override
  String detectedBackend(String label) {
    return '已偵測：$label';
  }

  @override
  String get detectedRunners => '已偵測的執行器';

  @override
  String get detectingAdapters => '正在偵測轉接器…';

  @override
  String get detectingInputDevices => '正在偵測輸入裝置…';

  @override
  String detectionFailed(String error) {
    return '偵測失敗：$error';
  }

  @override
  String get disabled => '已停用';

  @override
  String get discover => '探索';

  @override
  String get dismissed => '已忽略';

  @override
  String get domainHint => '例如 api-performance';

  @override
  String get domainLabel => '領域';

  @override
  String get download => '下載';

  @override
  String get downloadingLabel => '下載中';

  @override
  String downloadingModel(int pct) {
    return '正在下載模型… $pct%';
  }

  @override
  String get draft => '草稿';

  @override
  String get draftLabel => '草稿';

  @override
  String get edit => '編輯';

  @override
  String get edited => '已編輯';

  @override
  String get editMessage => '編輯訊息';

  @override
  String get revertToThere => '還原至該處';

  @override
  String get sendAsNewMessage => '作為新訊息傳送';

  @override
  String get editMessageChoiceBody =>
      '還原會隱藏這則訊息之後的內容，並回復代理的檔案。你可以復原。作為新訊息傳送則保持對話不變。';

  @override
  String get deleteMessage => '刪除訊息';

  @override
  String get deleteMessageConfirm => '要刪除此訊息嗎？此操作無法復原。';

  @override
  String get messageDeleted => '訊息已刪除';

  @override
  String get searchInConversation => '在對話中搜尋';

  @override
  String get searchMessagesHint => '搜尋訊息…';

  @override
  String get noMessagesFound => '找不到訊息';

  @override
  String get editFact => '編輯事實';

  @override
  String get editPolicy => '編輯政策';

  @override
  String get editSuggestedCodeHint => '編輯建議程式碼…';

  @override
  String get editSuggestion => '編輯建議';

  @override
  String get egArchitect => '例如 architect';

  @override
  String get egControlCenter => '例如 control-center';

  @override
  String get egPlatform => '例如 Platform';

  @override
  String get egSamuelAlev => '例如 SamuelAlev';

  @override
  String get egSoftwareArchitect => '例如 Software Architect';

  @override
  String get egTheVerge => '例如 The Verge';

  @override
  String get egTokenLimit => '例如 128000';

  @override
  String embeddingInstallFailed(String error) {
    return '安裝失敗：$error';
  }

  @override
  String get embeddingInstalled => '本機嵌入模型已安裝。混合搜尋已啟用。';

  @override
  String get embeddingModel => '嵌入模型（ONNX）';

  @override
  String get embeddingNotInstalled => '尚未安裝。在啟用前，搜尋會改用僅關鍵字。';

  @override
  String get embeddingRedownloadBody => '現有模型檔案將會刪除並重新下載。下載完成前無法使用語意搜尋。';

  @override
  String get embeddingRemoveBody => '在重新安裝前，語意搜尋將停用。你隨時可以再安裝。';

  @override
  String get speakerDiarization => '語者分離';

  @override
  String get diarizationModel => '語者分離模型';

  @override
  String get diarizationInstalled => '已安裝 — 會為會議逐字稿中的個別語者標示名稱';

  @override
  String get diarizationNotInstalled => '尚未安裝 — 不會分開會議語者';

  @override
  String diarizationInstallFailed(String error) {
    return '安裝失敗：$error';
  }

  @override
  String get redownloadDiarizationModel => '重新下載語者分離模型';

  @override
  String get diarizationRedownloadBody => '這會移除目前的語者分離模型並重新下載。';

  @override
  String get removeDiarizationModel => '移除語者分離模型';

  @override
  String get diarizationRemoveBody => '這會刪除裝置上的語者分離模型。已產生的會議逐字稿不受影響。';

  @override
  String get enableNotifications => '啟用通知';

  @override
  String get enableSandboxing => '啟用沙盒';

  @override
  String get enabled => '已啟用';

  @override
  String errorCreatingAgent(String error) {
    return '建立代理時發生錯誤：$error';
  }

  @override
  String errorDeletingAgent(String error) {
    return '刪除代理時發生錯誤：$error';
  }

  @override
  String errorWithDetail(String error) {
    return '錯誤：$error';
  }

  @override
  String get expand => '展開';

  @override
  String extractingModel(int pct) {
    return '正在解壓縮模型… $pct%';
  }

  @override
  String get fact => '事實';

  @override
  String factCount(int count) {
    return '$count 則事實';
  }

  @override
  String factCountPlural(int count) {
    return '$count 則事實';
  }

  @override
  String get facts => '事實';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount 則事實 · $policyCount 項政策';
  }

  @override
  String get failed => '失敗';

  @override
  String failedToDispatch(String error) {
    return '派送失敗：$error';
  }

  @override
  String get failedToLoad => '載入失敗';

  @override
  String failedToLoadAgents(String error) {
    return '載入代理失敗：$error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return '載入動態失敗：$error';
  }

  @override
  String get failedToLoadGifs => '載入 GIF 失敗';

  @override
  String failedToLoadLogs(String error) {
    return '載入紀錄失敗：$error';
  }

  @override
  String get failedToLoadRepos => '載入儲存庫失敗';

  @override
  String get failedToLoadWorkspaces => '載入工作區失敗';

  @override
  String failedToStartAiReview(String error) {
    return '開始 AI 審查失敗：$error';
  }

  @override
  String get failedToStartMicTest => '開始麥克風測試失敗。';

  @override
  String failedToSubmitReview(String error) {
    return '提交審查失敗：$error';
  }

  @override
  String failedToUpload(String name, String error) {
    return '上傳 $name 失敗：$error';
  }

  @override
  String failedWithError(String error) {
    return '失敗：$error';
  }

  @override
  String get failure => '失敗';

  @override
  String get feedAlreadyExists => '已有相同網址的摘要。';

  @override
  String get feedUrlExample => '例如 https://example.com/feed.xml';

  @override
  String get feedUrlLabel => '摘要網址';

  @override
  String feedsCount(int count) {
    return '摘要（$count）';
  }

  @override
  String get filesChanged => '已變更檔案';

  @override
  String filesCount(int count) {
    return '$count 個檔案';
  }

  @override
  String get filesMentionSection => '檔案';

  @override
  String get filterAgents => '篩選代理...';

  @override
  String get filterFilesHint => '篩選檔案…';

  @override
  String get filterLists => '篩選清單';

  @override
  String get filterSkillsPlaceholder => '篩選技能…';

  @override
  String get finish => '完成';

  @override
  String get fix => '修正';

  @override
  String get forward => '向前';

  @override
  String get gatesGithubPatPush => '閘控 GitHub PAT 注入。代理推送時必須具備。';

  @override
  String get general => '一般';

  @override
  String get githubLink => 'GitHub 連結';

  @override
  String get claudeStatusFetchFailed => '無法連線 status.claude.com';

  @override
  String get claudeStatusOpenInBrowser => '開啟 status.claude.com';

  @override
  String get githubStatusFetchFailed => '無法連線 githubstatus.com';

  @override
  String get githubDegradedTitle => 'GitHub 回報發生問題';

  @override
  String githubDegradedStatusLine(String status) {
    return 'GitHub 狀態：$status。';
  }

  @override
  String githubDegradedBody(String status) {
    return 'GitHub 狀態：$status。在恢復前，pull request 資料可能過時或不完整。';
  }

  @override
  String get githubStatusOpenInBrowser => '開啟 githubstatus.com';

  @override
  String get githubStatusRefresh => '重新整理';

  @override
  String githubStatusUpdated(String time) {
    return '更新於 $time';
  }

  @override
  String get kimiStatusFetchFailed => '無法連線 status.moonshot.cn';

  @override
  String get kimiStatusOpenInBrowser => '開啟 status.moonshot.cn';

  @override
  String get openaiStatusFetchFailed => '無法連線 status.openai.com';

  @override
  String get openaiStatusOpenInBrowser => '開啟 status.openai.com';

  @override
  String get serviceStatusMaintenance => '維護中';

  @override
  String get serviceStatusMajorIssues => '重大問題';

  @override
  String get serviceStatusMinorIssues => '輕微問題';

  @override
  String get serviceStatusOperational => '運作正常';

  @override
  String get serviceStatusOutage => '服務中斷';

  @override
  String get serviceStatusTitle => '服務狀態';

  @override
  String get serviceStatusUnknown => '未知';

  @override
  String lastChecked(String time) {
    return '檢查於 $time';
  }

  @override
  String get lastCheckedRecently => '最近已檢查';

  @override
  String get giveYourWorkAHome => '為你的工作找個家。';

  @override
  String get goBack => '返回';

  @override
  String get goForward => '前進';

  @override
  String get googleFonts => 'Google 字型';

  @override
  String get high => '高';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小時前',
      one: '1 小時前',
    );
    return '$_temp0';
  }

  @override
  String get images => '圖片';

  @override
  String get inactive => '未啟用';

  @override
  String get install => '安裝';

  @override
  String get installRequired => '需要安裝';

  @override
  String installedVersion(String version) {
    return '已安裝 $version';
  }

  @override
  String get invite => '邀請';

  @override
  String get inviteAgent => '邀請代理';

  @override
  String get isolateAgentExecution => '隔離代理執行。';

  @override
  String get justNow => '剛剛';

  @override
  String get keepSandboxing => '維持沙箱';

  @override
  String get keybindingAddARepositoryDescription => '新增儲存庫';

  @override
  String get keybindingAddRepository => '新增儲存庫';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      '為所選文章加上或取消書籤';

  @override
  String get keybindingCommandPalette => '命令面板';

  @override
  String get keybindingCreateANewAgentDescription => '建立新代理';

  @override
  String get keybindingCreateANewWorkspaceDescription => '建立新工作區';

  @override
  String get keybindingFocusSearch => '聚焦搜尋';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      '聚焦 pull request 搜尋欄';

  @override
  String get keybindingNewAgent => '新增代理';

  @override
  String get keybindingNewWorkspace => '新增工作區';

  @override
  String get keybindingNextArticle => '下一篇文章';

  @override
  String get keybindingNextSpace => '下一個空間';

  @override
  String get keybindingNextWorkspace => '下一個工作區';

  @override
  String get keybindingOpenArticle => '開啟文章';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      '開啟或關閉側邊欄的工作區切換彈出視窗';

  @override
  String get keybindingOpenPr => '開啟 PR';

  @override
  String get keybindingOpenSettings => '開啟設定';

  @override
  String get keybindingOpenTheApplicationSettingsDescription => '開啟應用程式設定';

  @override
  String get keybindingOpenTheCommandPaletteDescription => '開啟命令面板';

  @override
  String get keybindingOpenTheSelectedArticleDescription => '開啟所選文章';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      '開啟所選 pull request';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription => '開啟所選工作區';

  @override
  String get keybindingOpenWorkspace => '開啟工作區';

  @override
  String get keybindingPreviousArticle => '上一篇文章';

  @override
  String get keybindingPreviousSpace => '上一個空間';

  @override
  String get keybindingPreviousWorkspace => '上一個工作區';

  @override
  String get keybindingRefresh => '重新整理';

  @override
  String get keybindingRefreshAllFeedsDescription => '重新整理所有動態';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      '重新整理 pull request 清單';

  @override
  String get keybindingRescanForAdaptersDescription => '重新掃描配接器';

  @override
  String get keybindingSelectTheNextArticleDescription => '選取下一篇文章';

  @override
  String get keybindingSelectTheNextSpaceDescription => '選取下一個空間';

  @override
  String get keybindingSelectThePreviousArticleDescription => '選取上一篇文章';

  @override
  String get keybindingSelectThePreviousSpaceDescription => '選取上一個空間';

  @override
  String get keybindingSendMessage => '傳送訊息';

  @override
  String get keybindingSendTheCurrentMessageDescription => '傳送目前訊息';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      '在淺色與深色模式間切換';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription => '切換至第八個工作區';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription => '切換至第五個工作區';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription => '切換至第一個工作區';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription => '切換至第四個工作區';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription => '切換至下一個工作區';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription => '切換至第九個工作區';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription => '切換至上一個工作區';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription => '切換到第二個工作區';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription => '切換到第七個工作區';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription => '切換到第六個工作區';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription => '切換到第三個工作區';

  @override
  String get keybindingToggleBookmark => '切換書籤';

  @override
  String get keybindingToggleTheme => '切換主題';

  @override
  String get keybindingToggleWorkspaceSwitcher => '切換工作區切換器';

  @override
  String get keybindingWorkspace1 => '工作區 1';

  @override
  String get keybindingWorkspace2 => '工作區 2';

  @override
  String get keybindingWorkspace3 => '工作區 3';

  @override
  String get keybindingWorkspace4 => '工作區 4';

  @override
  String get keybindingWorkspace5 => '工作區 5';

  @override
  String get keybindingWorkspace6 => '工作區 6';

  @override
  String get keybindingWorkspace7 => '工作區 7';

  @override
  String get keybindingWorkspace8 => '工作區 8';

  @override
  String get keybindingWorkspace9 => '工作區 9';

  @override
  String get keybindings => '快捷鍵';

  @override
  String get keybindingsDescription => '所有鍵盤快捷鍵。快捷鍵為固定，無法重新指定。';

  @override
  String get killRunning => '終止執行中';

  @override
  String get languageSystem => '系統';

  @override
  String get leaveACommentEllipsis => '留下評論…';

  @override
  String get legendLabel => '圖例';

  @override
  String get lessLabel => '較少';

  @override
  String get letsPluginTools => '來接入你的工具。';

  @override
  String get level => '等級';

  @override
  String get loadingAgents => '正在載入代理…';

  @override
  String get loadingModels => '正在載入模型…';

  @override
  String get loadingProviders => '正在載入提供者…';

  @override
  String get logLevel => '日誌層級';

  @override
  String get logs => '日誌';

  @override
  String get low => '低';

  @override
  String get maintenance => '維護';

  @override
  String get manageParticipants => '管理參與者';

  @override
  String get manageWorkspaces => '管理工作區';

  @override
  String get reorderWorkspace => '重新排序工作區';

  @override
  String get matchOsAppearance => '符合你的作業系統外觀，或選擇固定模式。';

  @override
  String get mcpAuthToken => 'MCP 驗證權杖';

  @override
  String get mcpNotAvailableOnServer => '已連線的伺服器無法使用 MCP 伺服器控制。';

  @override
  String get modelManagedOnServer => '此模型在伺服器主機上執行，並由該處管理。';

  @override
  String get mcpServer => 'MCP 伺服器';

  @override
  String get medium => '中';

  @override
  String get memoryDataHint => '代理運作時，事實與政策會顯示於此。';

  @override
  String get memoryLabel => '記憶';

  @override
  String get merge => '合併';

  @override
  String get merged => '已合併';

  @override
  String get messagePlaceholder => '訊息…（@ 提及，/ 指令）';

  @override
  String get navConversations => '空間';

  @override
  String get microphonePermissionDenied => '已拒絕麥克風權限。';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分鐘前',
      one: '1 分鐘前',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => '模型';

  @override
  String get modified => '已修改';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個月前',
      one: '1 個月前',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => '更多';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => '名稱';

  @override
  String get nameAndTitleRequired => '名稱與職稱為必填。';

  @override
  String get nameAndUrlRequired => '名稱與 URL 為必填';

  @override
  String get nameLabel => '名稱';

  @override
  String nativeSandboxAvailable(String platform) {
    return '原生沙盒在 $platform 上可用。';
  }

  @override
  String get nativeSandboxNeedsInstall => '需要安裝原生沙盒';

  @override
  String get navObservability => '可觀測性';

  @override
  String get navSettings => '設定';

  @override
  String networkBlockCount(int count) {
    return '$count 個網路封鎖';
  }

  @override
  String get neutral => '中性';

  @override
  String get newCommitsPushed => '有新 commit 已推送 — 點選以重新載入 diff';

  @override
  String get newFact => '新事實';

  @override
  String get newPolicy => '新政策';

  @override
  String get newsfeed => 'Newsfeed';

  @override
  String get newsfeedLabel => 'Newsfeed';

  @override
  String get newsfeedSettingsDescription => '管理你訂閱的動態來源與閱讀偏好。';

  @override
  String get newsfeedSettingsTitle => 'Newsfeed 設定';

  @override
  String get nextMatch => '下一個相符項 (↵)';

  @override
  String get noActiveWorkspace => '尚未選取作用中的工作區或 repo。';

  @override
  String get noActiveWorkspaceCreate => '沒有作用中的工作區';

  @override
  String get noActiveWorkspaceGithub => '沒有含 GitHub repo 的作用中工作區。';

  @override
  String get noAgents => '沒有代理';

  @override
  String get noArticlesYet => '尚無文章';

  @override
  String get noArticlesYetBody => '來自你動態來源的文章會顯示在這裡。';

  @override
  String get noExecutionLogsYet => '尚無執行紀錄';

  @override
  String get noFacts => '尚無事實';

  @override
  String get noFeedsYet => '尚無動態來源';

  @override
  String get noFileAnchor => '沒有檔案錨點 — 無法張貼行內留言。';

  @override
  String get noFileChangesInScope => '此範圍內沒有檔案變更';

  @override
  String get noGifsFound => '找不到 GIF';

  @override
  String get noInputDevicesDetected => '未偵測到輸入裝置 — 改用系統預設。';

  @override
  String get noMatchingFiles => '沒有相符的檔案';

  @override
  String get noMatchingGoogleFonts => '沒有相符的 Google Fonts。';

  @override
  String get noMemoryData => '尚無記憶資料';

  @override
  String get noMessagesYet => '尚無訊息';

  @override
  String get noModelsAdvertised => '此外掛未公開任何模型。';

  @override
  String get noOpenPullRequests => '沒有未結案的 pull request';

  @override
  String get noPolicies => '尚無政策';

  @override
  String get noReposInWorkspaceYet => '此工作區尚無儲存庫';

  @override
  String get noRunnersDetected => '尚未偵測到 runner。重新整理以再次掃描。';

  @override
  String get noSavedArticles => '沒有已儲存的文章';

  @override
  String get noSavedArticlesBody => '你儲存的文章會顯示在這裡。';

  @override
  String noShortcutsMatch(String query) {
    return '沒有快捷鍵符合「$query」';
  }

  @override
  String get noSystemFonts => '未偵測到系統字型。';

  @override
  String get noTokenSet => '尚未設定權杖 — 存取不受限制。';

  @override
  String get noWorkingMemory => '尚無工作記憶備註。';

  @override
  String get noneAllRoles => '無（所有角色）';

  @override
  String get notAvailable => '無法使用';

  @override
  String get notConfiguredLabel => '尚未設定。';

  @override
  String get notFoundLabel => '找不到';

  @override
  String get notes => '備註';

  @override
  String get notificationAgentFinished => '代理已完成';

  @override
  String get notificationPrMentioned => '在 pull request 中被提及';

  @override
  String get notificationNewMessages => '新訊息';

  @override
  String get notificationPrMerged => 'PR 已合併';

  @override
  String get notificationPrPublished => 'PR 已發布';

  @override
  String get notificationReviewRequested => '已請求審查';

  @override
  String get notifications => '通知';

  @override
  String get notifyAgentRunCompleted => '代理完成執行時通知。';

  @override
  String get notifyPrMentioned => '在 pull request 中被提及時通知。';

  @override
  String get notifyNewMessages => '其他空間有新的代理訊息時通知。';

  @override
  String get notifyPrMerged => 'pull request 合併時通知。';

  @override
  String get notifyPrPublished => '代理發布 pull request 時通知。';

  @override
  String get notifyReviewRequested => '有人請求你審查 pull request 時通知。';

  @override
  String get notificationReviewStale => '審查已過時';

  @override
  String get notifyReviewStale => '你已審查的 pull request 有新的提交時';

  @override
  String get notificationPrMergeReadiness => '可合併';

  @override
  String get notifyPrMergeReadiness => '你建立的 pull request 變為可合併或不再可合併時通知。';

  @override
  String get notificationPrReviewDecision => '審查決定';

  @override
  String get notifyPrReviewDecision => '審查者核准、請求變更或核准被撤銷時通知。';

  @override
  String get notificationPrChecksStatus => '檢查';

  @override
  String get notifyPrChecksStatus => '你建立的 pull request 的 CI 失敗或恢復時通知。';

  @override
  String get notificationPrThreadActivity => '審查討論串';

  @override
  String get notifyPrThreadActivity => '你參與的討論串有人回覆或標為已解決時通知。';

  @override
  String get notificationPrReadyToMerge => '可合併';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '$prTitle 已具備合併所需條件。';
  }

  @override
  String get notificationPrMergeBlocked => '已無法合併';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '$prTitle 與基礎分支發生衝突。';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '$prTitle 落後於基礎分支。';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '$prTitle 正在等待必要審查。';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return '審查者對 $prTitle 請求變更。';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return '$prTitle 的檢查未通過。';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '$prTitle 已無法合併。';
  }

  @override
  String get notificationPrApproved => 'Pull request 已核准';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '$login 已核准 $prTitle';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '$prTitle 已核准';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '還有 $count 位審查者待回應',
      one: '還有 1 位審查者待回應',
      zero: '已無待回應的審查者',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => '已請求變更';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '$login 對 $prTitle 請求變更';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return '$prTitle 已被請求變更';
  }

  @override
  String get notificationPrReviewDismissed => '核准已撤銷';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '$prTitle 需要再次審查。';
  }

  @override
  String get notificationPrChecksFailed => '檢查失敗';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '$checkName 在 $prTitle 失敗';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return '$prTitle 的檢查未通過';
  }

  @override
  String get notificationPrChecksRecovered => '檢查已通過';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '$prTitle 已恢復通過。';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '$login 在 $location 提及你';
  }

  @override
  String get notificationPrThreadReplied => '新回覆';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '$login 在 $location 回覆';
  }

  @override
  String get notificationPrThreadResolved => '討論串已解決';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return '你在 $location 的討論串已解決。';
  }

  @override
  String get notificationGroupAgents => '代理';

  @override
  String get notificationGroupPullRequests => 'Pull requests';

  @override
  String get notificationGroupMessages => '訊息';

  @override
  String get notificationGroupTickets => '工單';

  @override
  String get notificationGroupCalendar => '行事曆';

  @override
  String get notificationGroupMachines => '機器';

  @override
  String get notificationsMutedRepos => '已靜音的存放庫';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已靜音 $count 個存放庫',
      one: '已靜音 1 個存放庫',
      zero: '沒有已靜音的存放庫',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => '靜音此存放庫';

  @override
  String get onboardingLinuxDescription => 'Control Center 可使用 Linux 容器隔離代理執行。';

  @override
  String get onboardingMacosDescription =>
      'Control Center 會使用 macOS 原生沙盒隔離代理執行。';

  @override
  String get onboardingUnsupportedDescription => '此平台無法使用沙盒。代理執行將沒有隔離。';

  @override
  String get openArticlesInApp => '在應用程式中開啟文章';

  @override
  String get openInBrowser => '在瀏覽器中開啟';

  @override
  String get openedInYourBrowser => '已在瀏覽器中開啟。';

  @override
  String get openLabel => '開啟';

  @override
  String get openOnGithub => '在 GitHub 上開啟';

  @override
  String get openStatus => '開啟';

  @override
  String get optionalPersonaDescription => '選填人設說明';

  @override
  String get otherLabel => '其他';

  @override
  String get ownerOrganization => '擁有者 / 組織';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => '通過';

  @override
  String get pasteValueHere => '在此貼上值';

  @override
  String get persona => '人設';

  @override
  String get policies => '政策';

  @override
  String get policiesHint => '代理將事實提升後，政策會顯示於此。';

  @override
  String get policy => '政策';

  @override
  String get popular => '熱門';

  @override
  String get port => '連接埠';

  @override
  String get postingEllipsis => '正在發佈…';

  @override
  String get prCommits => '提交';

  @override
  String get prMergedBody => '已合併 pull request';

  @override
  String get prMoreActions => '更多動作';

  @override
  String get prTitle => 'PR 標題';

  @override
  String get reviewCommentHint => '直接點選核准即可，想加點料也可以留言或加個表情…';

  @override
  String get nothingToPreview => '沒有可預覽的內容';

  @override
  String get previousMatch => '上一個相符 (⇧↵)';

  @override
  String get priorityReviewsDescription => '優先審核與存放庫總覽。';

  @override
  String get prsCreated => '已建立的 PR';

  @override
  String get prsMerged => '已合併的 PR';

  @override
  String get publishToGithub => '發佈到 GitHub';

  @override
  String get published => '已發佈';

  @override
  String get pullRequestApproved => 'Pull request 已核准';

  @override
  String get pullRequests => 'Pull requests';

  @override
  String get questionLabel => '問題';

  @override
  String get queued => '已排入佇列';

  @override
  String get react => 'React';

  @override
  String get readPrsIssuesMetadata => '允許代理讀取 PR、議題與存放庫中繼資料。';

  @override
  String get readerPreferences => '閱讀偏好';

  @override
  String get reasoningEffort => '推理力度';

  @override
  String get recommendLabel => '建議';

  @override
  String recordingFromDevice(String device) {
    return '正在從 $device 錄音。';
  }

  @override
  String get redownload => '重新下載';

  @override
  String get redownloadEmbeddingModel => '要重新下載嵌入模型嗎？';

  @override
  String get redownloadVoiceModel => '要重新下載語音模型嗎？';

  @override
  String get refinePlan => '精煉計畫';

  @override
  String get refresh => '重新整理';

  @override
  String get refreshAll => '全部重新整理';

  @override
  String get refreshAllFeeds => '重新整理所有動態';

  @override
  String get reject => '拒絕';

  @override
  String get rejected => '已拒絕';

  @override
  String get reload => '重新載入';

  @override
  String get remove => '移除';

  @override
  String get removeBookmark => '移除書籤';

  @override
  String get removeEmbeddingModel => '要移除嵌入模型嗎？';

  @override
  String get removeLogo => '移除標誌';

  @override
  String get removeRepoFromWorkspace => '要從工作區移除存放庫嗎？';

  @override
  String get removeVoiceModel => '要移除語音模型嗎？';

  @override
  String get removed => '已移除';

  @override
  String get renamed => '已重新命名';

  @override
  String get reopen => '重新開啟';

  @override
  String get resolve => '解決';

  @override
  String get replyEllipsis => '回覆…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name 將從此工作區移除。磁碟上的本機檔案不會更動。';
  }

  @override
  String repoAccessNoticeBody(String repos) {
    return '伺服器的 GitHub 憑證無法看到 $repos。若存放庫屬於組織，請在該處安裝 GitHub App，或連線具有存取權限的權杖。';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '無法存取 $count 個存放庫',
      one: '無法存取存放庫',
    );
    return '$_temp0';
  }

  @override
  String get repoAccessNoticeSuspendedTitle => 'GitHub App 安裝已暫停';

  @override
  String repoAccessNoticeSuspendedBody(String repos) {
    return '正在顯示 $repos 的上次已知資料。請在 GitHub 上恢復安裝，或連線具有存取權限的權杖。';
  }

  @override
  String get repoNoAccessBadge => '無權限';

  @override
  String get reportsTo => '直屬主管';

  @override
  String reposCount(int count) {
    return '存放庫 ($count)';
  }

  @override
  String get reposDescription => '此工作區所對應的本機簽出。';

  @override
  String get repositories => '存放庫';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個存放庫',
      one: '1 個存放庫',
    );
    return '無法新增 $_temp0：$error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已新增 $count 個存放庫',
      one: '已新增存放庫',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => '存放庫設定';

  @override
  String get repositoryName => '存放庫名稱';

  @override
  String get requestChanges => '要求變更';

  @override
  String get requested => '已請求';

  @override
  String get requestedChanges => '請求的變更';

  @override
  String requiredRoleLabel(String role) {
    return '必要角色：$role';
  }

  @override
  String get requiredRoleOptional => '必要角色（選填）';

  @override
  String get requirements => '需求';

  @override
  String get reset => '重設';

  @override
  String get resolved => '已解決';

  @override
  String get enclosedTerminalTitle => '內嵌終端機';

  @override
  String get enclosedTerminalStart => '開啟 Shell';

  @override
  String get enclosedTerminalStartHint =>
      '此 Shell 會在此對話的一次性虛擬機中執行。開啟時才會開機，而非應用程式啟動時。';

  @override
  String get terminalStreamReconnecting => '串流中斷 — 正在重新連線…';

  @override
  String get terminalStreamError => '串流錯誤：';

  @override
  String get terminalShellExited => 'Shell 已結束';

  @override
  String get restartShell => '重新啟動 Shell';

  @override
  String get retry => '重試';

  @override
  String get review => '檢閱';

  @override
  String get reviewedByMe => '由我檢閱';

  @override
  String get reviewers => '檢閱者';

  @override
  String get roleLabel => '角色';

  @override
  String get ruleHint => '政策規則（支援 Markdown）';

  @override
  String get ruleLabel => '規則';

  @override
  String get runCompleted => '執行完成';

  @override
  String get running => '執行中';

  @override
  String get runningLabel => '執行中';

  @override
  String get runs => '執行';

  @override
  String get runsLabel => '執行';

  @override
  String get sandboxBackendNativeLabel => '原生沙盒';

  @override
  String get sandboxBackendMicrovmLabel => '封閉式 VM';

  @override
  String get sandboxBackendNoneLabel => '無隔離';

  @override
  String get sandboxLinuxInstall =>
      'Linux/WSL2 上的原生沙箱使用 bubblewrap。安裝方式：\n\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'macOS 內建原生沙箱—使用 Apple Seatbelt（`sandbox-exec`）。無需安裝。';

  @override
  String get sandboxPermissions => '沙箱權限';

  @override
  String get sandboxUnsupported => '此平台尚未支援原生沙箱。將退回「無隔離」。';

  @override
  String get sandboxingDisabledDescription => '代理會直接在主機上執行並擁有完整環境—不建議使用。';

  @override
  String sandboxingEnabledDescription(String backend) {
    return '所有代理叫用都會經由 $backend。';
  }

  @override
  String get save => '儲存';

  @override
  String get saveChanges => '儲存變更';

  @override
  String get adapterArguments => '額外引數';

  @override
  String get adapterArgumentsHint => '額外的 CLI 旗標（例如 --yolo）';

  @override
  String get addVariable => '新增變數';

  @override
  String get environmentVariables => '環境變數';

  @override
  String get environmentVariablesDescription =>
      '傳遞給此介面卡的自訂環境變數（例如 API 金鑰）。儲存在鑰匙圈中。';

  @override
  String get variableKey => '鍵';

  @override
  String get variableValue => '值';

  @override
  String get savingEllipsis => '儲存中…';

  @override
  String get scopeDiffToCommits => '將 diff 範圍限定在 commit—按住 Shift 點擊可選取範圍';

  @override
  String get noPrsMatchSearch => '沒有符合的 pull request';

  @override
  String get searchFactsHint => '搜尋事實…';

  @override
  String get searchFonts => '搜尋字型…';

  @override
  String get searchGifs => '搜尋 GIF';

  @override
  String get searchGifsHint => '搜尋 GIF…';

  @override
  String get searchInDiffHint => '在 diff 中搜尋…';

  @override
  String get searchOrTypeModel => '搜尋或輸入模型名稱…';

  @override
  String get searchPlaceholder => '搜尋…';

  @override
  String get searchShortcuts => '搜尋捷徑…';

  @override
  String get shortcutUnavailableInBrowser => '在瀏覽器中無法使用';

  @override
  String get searching => '搜尋中…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 秒前',
      one: '1 秒前',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => '選擇介面卡';

  @override
  String get selectAdapterFirst => '請先選擇介面卡';

  @override
  String get selectAgentToReportTo => '選擇要回報的代理…';

  @override
  String get selectAnAgent => '選擇代理';

  @override
  String get selectConversation => '選擇對話';

  @override
  String get selectLabel => '選擇';

  @override
  String get selectRunner => '選擇執行器';

  @override
  String get semanticSearch => '語意搜尋';

  @override
  String get send => '傳送';

  @override
  String get sendFirstMessage => '傳送第一則訊息';

  @override
  String get sendMessage => '傳送訊息';

  @override
  String sentFindingsToAgent(int count) {
    return '已將 $count 項發現傳送給代理。';
  }

  @override
  String setGithubLinkDescription(String name) {
    return '設定 $name 的 GitHub 擁有者與儲存庫名稱。用於解析 Markdown 內容中像 #123 這樣的 PR 與 issue 參照。';
  }

  @override
  String get setLabel => '設定';

  @override
  String get setToken => '設定權杖';

  @override
  String get settingsLabel => '設定';

  @override
  String get settingsLanguage => '語言';

  @override
  String get settingsLanguageDescription => '選擇應用程式語言。';

  @override
  String get shortTask => '簡短任務';

  @override
  String get showNativeNotifications => '事件發生時顯示系統通知。';

  @override
  String get showSuperseded => '顯示已被取代者';

  @override
  String get signedIn => '已登入。';

  @override
  String signedInAs(String username) {
    return '已登入為 $username。';
  }

  @override
  String get skillNameRequired => '技能名稱為必填。';

  @override
  String skillSaved(String name) {
    return '技能「$name」已儲存。';
  }

  @override
  String get skillsSourcesTab => '來源';

  @override
  String get skillSourcesDisclaimer =>
      '技能會從你新增的 GitHub 儲存庫安裝。儲存庫中繼資料不可信任—防毒掃描才是真正的安全訊號。';

  @override
  String get skillSourcesEmpty => '沒有技能儲存庫';

  @override
  String get skillSourcesEmptyHint => '新增 GitHub 儲存庫以瀏覽其技能。';

  @override
  String get skillSourceAdd => '新增儲存庫';

  @override
  String get skillSourceAddTitle => '新增技能儲存庫';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      '請輸入 GitHub 儲存庫 URL（https://github.com/owner/repo）。';

  @override
  String skillSourceAdded(String repo) {
    return '已新增儲存庫 $repo。';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return '儲存庫 $repo 已經新增過了。';
  }

  @override
  String skillSourceRemoved(String repo) {
    return '已移除儲存庫 $repo。';
  }

  @override
  String get skillSourceRemove => '移除';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return '要移除 $repo 嗎？';
  }

  @override
  String get skillSourceRemoveConfirmBody => '已安裝的技能會保持安裝。只會移除儲存庫目錄。';

  @override
  String get skillSourceNoSkills => '此儲存庫中找不到技能（技能是包含 SKILL.md 的目錄）。';

  @override
  String get skillSourceRefresh => '重新整理';

  @override
  String get skillSourceInstalledBadge => '已安裝';

  @override
  String get skillSourceUpdateBadge => '有可用更新';

  @override
  String get skillSourceSlugTaken => '名稱已被使用';

  @override
  String skillSourceFilesCount(num count) {
    return '$count 個檔案';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => '此技能沒有 README。';

  @override
  String get skillSourceNoMatches => '沒有符合篩選條件的技能。';

  @override
  String get skillUpdateAction => '更新';

  @override
  String get skillUninstallAction => '解除安裝';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return '要解除安裝「$slug」嗎？';
  }

  @override
  String skillUninstalled(String slug) {
    return '技能「$slug」已解除安裝。';
  }

  @override
  String get skillFindingLine => '行';

  @override
  String get skillInstallAnywayOverride => '我了解風險—仍要安裝';

  @override
  String skillInstalled(String slug) {
    return '技能「$slug」已安裝。';
  }

  @override
  String get skillPreviewCapabilities => '能力';

  @override
  String get skillPreviewFindings => '發現項目';

  @override
  String get skillPreviewGuardedActions => '受防護動作';

  @override
  String get skillPreviewLlmReviewed => '已由 LLM 審閱';

  @override
  String get skillPreviewNoCapabilities => '未宣告任何能力。';

  @override
  String get skillPreviewNoFindings => '沒有發現項目。';

  @override
  String get skillPreviewScanning => '正在掃描技能…';

  @override
  String get skillPreviewVerdictLabel => '掃描判定';

  @override
  String get skillPreviewVerdictPass => '通過';

  @override
  String get skillPreviewVerdictQuarantine => '已隔離';

  @override
  String get skillPreviewVerdictWarn => '警告';

  @override
  String get skillQuarantineWarning =>
      '此技能已被掃描器隔離。安裝它會在你的機器上執行程式碼。只有在信任來源且已檢視發現項目時才繼續。';

  @override
  String skillDetachedFromAgents(String agents) {
    return '已隔離並自代理分離：$agents';
  }

  @override
  String get skillNotScanned => '尚未掃描';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => '手動';

  @override
  String get skillOriginRegistry => '登錄';

  @override
  String get skillOriginRuntimeLocal => '執行階段本機';

  @override
  String get skillRulesStale => '掃描已過時';

  @override
  String get skillSaveAnywayOverride => '我了解風險—仍要儲存';

  @override
  String get skillSaveBlockedBody => '內容在寫入任何東西前已被封鎖。';

  @override
  String get skillSaveBlockedTitle => '儲存已遭掃描閘門封鎖';

  @override
  String get skillScanAction => '掃描';

  @override
  String get skillScanAll => '全部掃描';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass 項通過 · $warn 項警告 · $quarantine 項隔離';
  }

  @override
  String get skillStateDrifted => '安裝後有修改';

  @override
  String get skillStateUnmanaged => '未受管理';

  @override
  String get skillSeverityBlocked => '已封鎖';

  @override
  String get skillSeverityWarn => '警告';

  @override
  String get skillsInstalledTab => '已安裝';

  @override
  String get skills => '技能';

  @override
  String get skipAcceptRisk => '略過—我接受風險';

  @override
  String get skipForNow => '暫時略過';

  @override
  String get skipSandboxing => '略過沙箱';

  @override
  String get skipSandboxingDialogContent => '確定要略過沙箱嗎？這會讓代理在未隔離的情況下於你的系統執行程式碼。';

  @override
  String get somethingWentWrong => '發生錯誤';

  @override
  String sourceCount(int count) {
    return '$count 個來源';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count 個來源';
  }

  @override
  String get sourceFacts => '來源事實：';

  @override
  String get splitDiff => '分割 diff（並排）';

  @override
  String get startLabel => '開始';

  @override
  String get startOnAppLaunch => '應用程式啟動時開始';

  @override
  String get statusLabel => '狀態';

  @override
  String get onboardingStepConnect => '連接';

  @override
  String get onboardingStepWorkspace => '工作區';

  @override
  String get onboardingStepSandbox => '沙箱';

  @override
  String get onboardingStepAdapter => '介面卡';

  @override
  String get onboardingStepVoice => '語音';

  @override
  String get stop => '停止';

  @override
  String get stopped => '已停止';

  @override
  String get strictIdentityCheck => '嚴格身分檢查';

  @override
  String get success => '成功';

  @override
  String get successLabel => '成功';

  @override
  String get suggestAChange => '建議變更';

  @override
  String get suggestion => '建議';

  @override
  String get suggestLabel => '建議';

  @override
  String get superseded => '已取代';

  @override
  String get synced => '已同步';

  @override
  String get systemDefault => '系統預設';

  @override
  String get systemFonts => '系統字型';

  @override
  String get systemPrompt => '系統提示';

  @override
  String get systemPromptLabel => '系統提示';

  @override
  String get talkToControlCenter => '與 Control Center 對話。';

  @override
  String get taskMentionSection => '任務';

  @override
  String get testLabel => '測試';

  @override
  String get theme => '主題';

  @override
  String get themeDark => '深色';

  @override
  String get themeLight => '淺色';

  @override
  String get themeSystem => '系統';

  @override
  String get thisCannotBeUndone => '此操作無法復原。';

  @override
  String get ticketLabel => '工單';

  @override
  String get titleLabel => '標題';

  @override
  String get todayLabel => '今天';

  @override
  String get toggleTheme => '切換主題';

  @override
  String get tokenConfigured => '已設定—用戶端必須出示此權杖。';

  @override
  String get topic => '主題';

  @override
  String get topicHint => '例如 Tech Stack、Design System';

  @override
  String get totalRuns => '總執行次數';

  @override
  String trackingParamsCount(int count) {
    return '$count 個追蹤參數';
  }

  @override
  String get typeCommandOrSearch => '輸入命令或搜尋…';

  @override
  String get typography => '字體';

  @override
  String get unavailable => '無法使用';

  @override
  String get unifiedDiff => '統一 diff';

  @override
  String get unknownAuthor => '未知';

  @override
  String get unnamedAgent => '未命名代理';

  @override
  String get updateKey => '更新金鑰';

  @override
  String get updateLabel => '更新';

  @override
  String get updateToken => '更新權杖';

  @override
  String updatedDaysAgo(int count) {
    return '$count 天前更新';
  }

  @override
  String updatedHoursAgo(int count) {
    return '$count 小時前更新';
  }

  @override
  String get updatedJustNow => '剛剛更新';

  @override
  String updatedMinutesAgo(int count) {
    return '$count 分鐘前更新';
  }

  @override
  String get useSandbox => '使用沙箱';

  @override
  String get useWorkspaceDefault => '使用工作區預設值';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      '留空以使用應用程式預設的 User-Agent。部分網站會封鎖非瀏覽器的 User-Agent。';

  @override
  String get usingSystemDefaultMicrophone => '目前使用系統預設麥克風。';

  @override
  String get viewLabel => '檢視';

  @override
  String get viewLogs => '檢視記錄檔';

  @override
  String voiceInstallFailed(String error) {
    return '安裝失敗：$error';
  }

  @override
  String get voiceModelNotInstalled => '尚未安裝。一次性下載約 200 MB；完全在裝置上執行。';

  @override
  String get voiceModelNotInstalledLabel => '語音模型尚未安裝。';

  @override
  String get voiceRedownloadBody =>
      '現有的模型檔案將被刪除，並重新下載約 200 MB 的封存檔。下載完成前，語音轉文字將無法使用。';

  @override
  String get voiceRemoveBody => '在你重新安裝之前，語音轉文字將停用。你可以隨時再次安裝。';

  @override
  String get voiceTranscription => '語音轉文字';

  @override
  String get weakIsolationDescription => '隔離力弱—僅有命名空間邊界，沒有核心邊界。';

  @override
  String get whenOffNoDefaultRoute => '關閉時，沙箱會在不設定預設路由的情況下啟動。';

  @override
  String get whenOffServerStaysStopped => '關閉時，伺服器會保持停止，直到你啟動它。';

  @override
  String get speechModel => '語音模型';

  @override
  String get speechModelHint => '用於會議轉錄與輸入框麥克風。';

  @override
  String get voiceModelInstalled => '已安裝。為會議轉錄與輸入框麥克風按鈕提供支援。';

  @override
  String get meetingMicSilentWarning => '你的麥克風可能已靜音—其他人在說話，但沒有任何聲音進到你的麥克風。';

  @override
  String get meetingSummaryPrivacyNotice =>
      '錄音與轉錄都保留在這台機器上。摘要由代理撰寫，因此若它使用雲端模型，你的逐字稿與筆記會傳送給該供應商。';

  @override
  String get meetingTemplates => '會議筆記範本';

  @override
  String get meetingTemplatesHint => '為特定類型的會議塑造 AI 摘要。作用中的範本會套用至新產生與重新產生的摘要。';

  @override
  String get meetingTemplateActive => '作用中的範本';

  @override
  String get meetingTemplateAdd => '新增範本';

  @override
  String get meetingTemplateNewTitle => '新範本';

  @override
  String get meetingTemplateEditTitle => '編輯範本';

  @override
  String get meetingTemplateNameLabel => '名稱';

  @override
  String get meetingTemplateNameHint => '例如 Sprint review';

  @override
  String get meetingTemplateInstructionsLabel => '指示';

  @override
  String get meetingTemplateInstructionsHint => 'AI 應如何組織並強調這些筆記？';

  @override
  String get workingMemory => '工作記憶';

  @override
  String get workspaceName => '工作區名稱';

  @override
  String get workspaceScopedSkills => '附加至代理的工作區範圍技能檔案。';

  @override
  String get workspaces => '工作區';

  @override
  String get writePrivateNotes => '寫下私人筆記、觀察、計畫…';

  @override
  String get writeSkillContent => '在此撰寫你的技能內容（Markdown）…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 年前',
      one: '1 年前',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => '昨天';

  @override
  String get focusModeStart => '開始專注時段';

  @override
  String get focusModeConfigTitle => '開始專注時段';

  @override
  String get focusModeGoalLabel => '目標';

  @override
  String get focusModeGoalHint => '你正在做什麼？';

  @override
  String get focusModeDurationLabel => '時長';

  @override
  String get focusModeBlockNotifications => '封鎖通知';

  @override
  String get focusModeStartButton => '開始';

  @override
  String get focusModeFloat => '最小化為浮動列';

  @override
  String get focusModeActiveTooltip => '專注模式作用中—點擊以結束';

  @override
  String get dismiss => '關閉';

  @override
  String get acceptAndResolve => '接受並解決';

  @override
  String reviewFatigueWarning(int minutes) {
    return '你已審查 $minutes 分鐘—研究顯示超過 60 分鐘後審查品質可能下降。建議休息一下。';
  }

  @override
  String get notificationSound => '通知音效';

  @override
  String get notificationSoundDescription => '顯示通知時播放的音效。';

  @override
  String get notificationSoundNone => '無';

  @override
  String get notificationSoundPing => 'Ping';

  @override
  String get notificationSoundChime => '鐘響';

  @override
  String get notificationSoundPop => '啵';

  @override
  String get notificationSoundDing => '叮';

  @override
  String get notificationSoundWhoosh => '咻';

  @override
  String get notificationSoundMigrosSoft => 'Migros（柔和）';

  @override
  String get notificationSoundMigrosHard => 'Migros（強烈）';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => '測試';

  @override
  String get notificationVolume => '音量';

  @override
  String noPrsByUserInWorkspace(String login) {
    return '此工作區中沒有 @$login 的 PR';
  }

  @override
  String get usersLabel => '使用者';

  @override
  String get mergePullRequest => '合併 pull request';

  @override
  String get forceMergePullRequest => '強制合併 pull request';

  @override
  String get closePullRequest => '關閉 pull request';

  @override
  String get closePullRequestConfirm => '確定要關閉此 pull request 嗎？';

  @override
  String get stackedPullRequests => '堆疊 pull request';

  @override
  String partOfStack(int position, int total) {
    return '堆疊的一部分（$position / $total）';
  }

  @override
  String get createStack => '建立堆疊';

  @override
  String get createStackDialogTitle => '建立 pull request 堆疊';

  @override
  String createStackDialogBody(int count) {
    return '這 $count 個 pull request 將由下而上堆疊：';
  }

  @override
  String get createStackInvalidSelection => '請至少選擇同一儲存庫的兩個 pull request 才能建立堆疊';

  @override
  String get createStackNotAChain =>
      '所選的 pull request 無法形成鏈：每個 pull request 的基礎分支必須是前一個的 head 分支';

  @override
  String get createStackAlreadyStacked => '一或多個所選 pull request 已在堆疊中';

  @override
  String get stackCreated => '堆疊已建立';

  @override
  String get stackCreationFailed => '無法建立堆疊';

  @override
  String get squashAndMerge => 'Squash 並合併';

  @override
  String get createMergeCommit => '建立合併 commit';

  @override
  String get rebaseAndMerge => 'Rebase 並合併';

  @override
  String get commitTitle => 'Commit 標題';

  @override
  String get commitDescription => 'Commit 描述';

  @override
  String get pullRequestMerged => 'Pull request 已合併';

  @override
  String get pullRequestClosed => 'Pull request 已關閉';

  @override
  String failedToMergePr(String error) {
    return '合併失敗：$error';
  }

  @override
  String failedToClosePr(String error) {
    return '關閉失敗：$error';
  }

  @override
  String get markReadyForReview => '準備接受審查';

  @override
  String get markReadyForReviewConfirm =>
      '此 pull request 將脫離草稿。審查者會收到通知、必要檢查開始把關合併，且任何監看 ready pull request 的自動化都會執行。';

  @override
  String get convertToDraft => '轉為草稿';

  @override
  String get convertToDraftConfirm =>
      '此 pull request 將回到草稿。待處理的審查請求會被取消，且在你再次標記為 ready 之前無法合併。';

  @override
  String get pullRequestMarkedReady => 'Pull request 已標記為 ready';

  @override
  String get pullRequestConvertedToDraft => 'Pull request 已轉為草稿';

  @override
  String failedToMarkPrReady(String error) {
    return '標記為 ready 失敗：$error';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return '轉為草稿失敗：$error';
  }

  @override
  String get checksFailing => '檢查失敗';

  @override
  String get reviewsPending => '有待處理的審查';

  @override
  String get mergeConflictsWithBase => '此分支存在必須解決的衝突';

  @override
  String get branchOutOfDateWithBase => '此分支落後於基礎分支';

  @override
  String get mergeBlockedByBranchProtection => '分支保護阻擋了此合併';

  @override
  String get confirm => '確認';

  @override
  String get trustedSitesSectionTitle => '信任的網站';

  @override
  String get trustedSitesEmpty => '沒有信任的網站。新增網域即可停用對該網域的封鎖。';

  @override
  String get addTrustedSite => '新增信任網站';

  @override
  String get removeTrustedSite => '移除';

  @override
  String get disableBlockingForThisSite => '停用此網站的封鎖';

  @override
  String get enableBlockingForThisSite => '啟用此網站的封鎖';

  @override
  String get enterDomainHint => '例如 example.com';

  @override
  String get invalidDomain => '請輸入有效的網域（例如 example.com）';

  @override
  String get pageLoadTimedOut => '頁面載入逾時。請重新載入或在瀏覽器中開啟。';

  @override
  String get pipelinesScreenTitle => '管線';

  @override
  String get pipelinesScreenSubtitle => '宣告式多步驟代理工作流程';

  @override
  String get pipelinesRunPipeline => '執行管線';

  @override
  String get pipelineRunLauncherTitle => '執行管線';

  @override
  String get pipelineRunSubtitle => '選擇管線並填入其輸入以開始執行。';

  @override
  String get pipelineRunNoInputsBadge => '無輸入';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個輸入',
      one: '1 個輸入',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => '此管線不需要輸入。';

  @override
  String get pipelineRunSubmit => '執行管線';

  @override
  String get pipelineRunCouldNotStart => '無法開始執行。';

  @override
  String pipelineRunStarted(String name) {
    return '已啟動 $name';
  }

  @override
  String get pipelineRunEmptyTitle => '沒有可執行的管線';

  @override
  String get pipelineRunEmptyHint => '在其編輯器中啟用管線並開啟手動執行，即可在此啟動。';

  @override
  String get pipelineRunManageTemplates => '管理管線';

  @override
  String get pipelineRunSettingsTitle => '手動執行';

  @override
  String get pipelineRunSettingsAllow => '允許手動執行';

  @override
  String get pipelineRunSettingsAllowHelp => '在執行頁面顯示此管線，以便手動啟動。';

  @override
  String get pipelineRunSettingsConcurrencyTitle => '並行';

  @override
  String get pipelineRunSettingsMaxParallel => '最大並行執行數';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      '留空表示不限數量。額外的執行會在佇列中等待，有名額釋出時再開始。';

  @override
  String get pipelineRunSettingsMaxParallelHint => '不限數量';

  @override
  String get pipelineRunSettingsMaxParallelInvalid => '請輸入大於等於 1 的整數，或留空表示不限。';

  @override
  String get pipelineRunSettingsInputsTitle => '輸入';

  @override
  String get pipelineRunSettingsAddInput => '新增輸入';

  @override
  String get pipelineRunSettingsNoInputs => '尚無輸入。';

  @override
  String get pipelineInputEditTitle => '輸入欄位';

  @override
  String get pipelineInputKeyLabel => '鍵';

  @override
  String get pipelineInputKeyHelp => '值儲存所在的狀態鍵（例如 repo_full_name）。';

  @override
  String get pipelineInputLabelLabel => '標籤';

  @override
  String get pipelineInputTypeLabel => '類型';

  @override
  String get pipelineInputOptionsLabel => '選項（以逗號分隔）';

  @override
  String get pipelineInputDefaultLabel => '預設值';

  @override
  String get pipelineInputPlaceholderLabel => '預留位置';

  @override
  String get pipelineInputHelpLabel => '說明文字';

  @override
  String get pipelineInputRequiredLabel => '必填';

  @override
  String get pipelineInputTypeText => '文字';

  @override
  String get pipelineInputTypeMultiline => '多行文字';

  @override
  String get pipelineInputTypeNumber => '數字';

  @override
  String get pipelineInputTypeBoolean => '開關';

  @override
  String get pipelineInputTypeSelect => '下拉選單';

  @override
  String get pipelinesEmpty => '尚無管線執行';

  @override
  String get pipelinesEmptyHint => '點擊「執行管線」即可開始。';

  @override
  String get pipelinesNoSteps => '尚無記錄的步驟';

  @override
  String get pipelinesNoActiveWorkspace => '選擇工作區以查看其管線';

  @override
  String pipelinesLoadError(String error) {
    return '載入管線失敗：$error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return '啟動管線失敗：$error';
  }

  @override
  String get pipelineStatusPending => '等待中';

  @override
  String get pipelineStatusQueued => '排隊中';

  @override
  String get pipelineStatusRunning => '執行中';

  @override
  String get pipelineStatusSuspended => '已暫停';

  @override
  String get pipelineStatusCompleted => '已完成';

  @override
  String get pipelineStatusFailed => '已失敗';

  @override
  String get pipelineStatusCancelled => '已取消';

  @override
  String get pipelineStatusSkipped => '已跳過';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed / $total 個步驟';
  }

  @override
  String get pipelineWaterfallTimeline => '時間軸';

  @override
  String pipelineWaterfallActive(String duration) {
    return '作用中 $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return '閒置 $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip => '未計入作用時間的部分：執行被停止或在步驟間等待。';

  @override
  String get pipelineStepStarted => '已開始';

  @override
  String get pipelineStepFinished => '已結束';

  @override
  String get pipelineStepDurationLabel => '時長';

  @override
  String get pipelineStepBranch => '分支';

  @override
  String get pipelineStepViewConversation => '檢視對話';

  @override
  String get pipelineStepError => '錯誤';

  @override
  String get pipelineStepInput => '輸入';

  @override
  String get pipelineStepOutput => '輸出';

  @override
  String get pipelineStepNotExecuted => '尚未執行';

  @override
  String pipelineRunFailedAtStep(String step) {
    return '在 $step 失敗';
  }

  @override
  String get pipelineRunTriggerManual => '手動';

  @override
  String get pipelineStepSkippedReason => '已跳過';

  @override
  String get pipelineStepPriorAttempts => '先前的嘗試';

  @override
  String get pipelineStepAttemptLabel => '嘗試';

  @override
  String pipelineStepAttemptN(int number) {
    return '第 $number 次嘗試';
  }

  @override
  String get pipelineStepAttemptInterrupted => '已中斷';

  @override
  String get pipelineRunColumnPipeline => '管線';

  @override
  String get pipelineRunColumnDuration => '時長';

  @override
  String get pipelineRunQueueNext => '下一個';

  @override
  String pipelineRunQueuePosition(int position) {
    return '佇列中第 $position 位';
  }

  @override
  String get pipelineRunColumnStarted => '開始時間';

  @override
  String get pipelineRunHistory => '執行歷史';

  @override
  String get pipelineRunHistoryEmpty => '尚無其他執行';

  @override
  String pipelineRunRerunAgo(String time) {
    return '重新執行於 $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return '第 $number 次嘗試';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return '首次開始於 $time';
  }

  @override
  String get pipelineRunFilterAll => '全部';

  @override
  String get pipelineRunFilterEmpty => '沒有符合此篩選條件的執行';

  @override
  String get relativeJustNow => '剛剛';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分鐘前',
      one: '1 分鐘前',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小時前',
      one: '1 小時前',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天前',
      one: '1 天前',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => '團隊';

  @override
  String get teamsAddTeam => '新增團隊';

  @override
  String get teamsLoadError => '無法載入團隊';

  @override
  String get teamsEmptyTitle => '尚無團隊';

  @override
  String get teamsEmptyDescription => '將代理分組為團隊，指派給團隊的工作會經由負責分派的隊長處理。';

  @override
  String get teamCreateTitle => '新團隊';

  @override
  String get teamEditTitle => '編輯團隊';

  @override
  String get teamNameLabel => '團隊名稱';

  @override
  String get teamNameHint => '例如前端';

  @override
  String get teamDescriptionLabel => '描述';

  @override
  String get teamDescriptionHint => '此團隊負責什麼';

  @override
  String get teamLeaderLabel => '隊長';

  @override
  String get teamLeaderHelp => '接收團隊指派工作並分派給最適合成員的協調者。';

  @override
  String get teamNoLeader => '沒有隊長';

  @override
  String get teamInstructionsLabel => '運作指示';

  @override
  String get teamInstructionsHelp => '附加於隊長的簡報之後—團隊慣例、升級規則、語氣。';

  @override
  String get teamInstructionsHint => '選填';

  @override
  String get teamSaved => '團隊已儲存';

  @override
  String get teamMembersError => '無法載入成員';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 位成員',
      one: '1 位成員',
      zero: '沒有成員',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => '新增成員';

  @override
  String get teamAddMemberTitle => '新增成員';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '新增 $count 位',
      one: '新增 1 位',
      zero: '新增',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => '所有代理都已在這個團隊中。';

  @override
  String get teamRemoveMember => '從團隊中移除';

  @override
  String get teamLeaderBadge => '隊長';

  @override
  String get teamUnknownAgent => '未知代理';

  @override
  String get teamMembersEmpty => '尚無成員';

  @override
  String get teamMembersEmptyDescription => '新增代理，讓隊長有對象可以分派工作。';

  @override
  String get teamSelectPrompt => '選擇團隊';

  @override
  String get teamSelectPromptDescription => '從清單中選擇團隊，或建立新的。';

  @override
  String get teamDeleteTitle => '刪除團隊？';

  @override
  String teamDeleteBody(String name) {
    return '$name 將被刪除。其代理不受影響。';
  }

  @override
  String get teamHasLeaderTooltip => '已有隊長';

  @override
  String get pipelineTemplatesNav => '管線範本';

  @override
  String get pipelineTemplatesTitle => '管線範本';

  @override
  String get pipelineTemplatesSubtitle => '以拖放方式編輯用來編排代理的管線。';

  @override
  String get pipelineTemplatesNew => '新增範本';

  @override
  String get pipelineTemplatesEmpty => '尚無管線範本。建立一個來開始吧。';

  @override
  String get pipelineTemplateBuiltInBadge => '內建';

  @override
  String get pipelineTemplateDeleteConfirmTitle => '刪除範本？';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return '要刪除管線範本 $name 嗎？此操作無法復原。';
  }

  @override
  String get pipelineTemplateEditorSubtitle => '從側邊欄將節點類型拖放到畫布上，再將它們連接起來。';

  @override
  String get unsavedChanges => '有未儲存的變更';

  @override
  String get nodeLibraryTitle => '節點庫';

  @override
  String get nodeLibraryHint => '將任一項目拖放到畫布即可新增節點。';

  @override
  String get editorEmptyCanvas => '從節點庫拖放一個節點開始。';

  @override
  String get pipelineWhenThisHappens => '當發生以下情況';

  @override
  String get pipelineDoThis => '執行此操作';

  @override
  String get pipelineAddStep => '新增步驟';

  @override
  String get pipelineTidyUp => '整理版面';

  @override
  String get pipelineEditorHint => '拖曳步驟以排列 · 拖曳控制點以連接';

  @override
  String get pipelineRemoveConnection => '移除連線';

  @override
  String get pipelineDragToConnect => '拖曳以連接';

  @override
  String get pipelineNewDefaultName => '新增管線';

  @override
  String get nodeCategoryTriggers => '觸發器';

  @override
  String get triggerEventWebhook => 'Webhook';

  @override
  String get pipelineAddTrigger => '新增觸發器';

  @override
  String get pipelineOnEvent => '於事件發生時';

  @override
  String get nodeConfigTitle => '節點設定';

  @override
  String get nodeConfigKind => '種類';

  @override
  String get nodeConfigLabel => '標籤';

  @override
  String get nodeConfigAgent => '代理';

  @override
  String get nodeConfigAgentHint => '選擇代理…';

  @override
  String get nodeConfigInputKeys => '輸入鍵（以逗號分隔）';

  @override
  String get nodeConfigInputKeysHelp => '此節點使用的狀態鍵。用於提示中的預留位置替換。';

  @override
  String get nodeConfigRepos => '要複製的儲存庫';

  @override
  String get nodeConfigReposHelp => '此節點開始對話時會複製並建立程式碼索引的儲存庫。全選時會全部複製（預設行為）。';

  @override
  String get nodeConfigRepoBranchHint => '分支（預設）';

  @override
  String get nodeConfigRepoBranchHelp =>
      '每個 checkout 切出的來源分支。留空則使用儲存庫自身的預設分支—工作樹仍會有自己的分支，代理提交的內容不會落在這個分支上。';

  @override
  String nodeConfigReposDynamic(String entries) {
    return '保留的動態項目：$entries';
  }

  @override
  String get nodeConfigCreateConversation => '在其中開啟對話';

  @override
  String get nodeConfigCreateConversationHelp =>
      '後面有多個代理節點時請保持關閉—每個都會開啟自己的具名資料流。後面只有單一代理節點時才開啟，空間就不會在旁邊顯示未命名的對話。';

  @override
  String get nodeConfigConversationTitle => '對話名稱';

  @override
  String get nodeConfigConversationTitleHelp =>
      '將此名稱設成與下游代理節點相同，兩者就會在同一個資料流中工作。預設為節點的標籤。';

  @override
  String get nodeConfigSpaceName => '空間名稱';

  @override
  String get nodeConfigSpaceNameHelp => '此節點開啟的房間名稱。支援與提示相同的狀態預留位置。留空則使用節點標籤。';

  @override
  String get nodeConfigSpaceNameHint => 'pr_number 的審查';

  @override
  String get nodeConfigStreamTitle => '對話名稱';

  @override
  String get nodeConfigStreamTitleHelp =>
      '此節點的代理在房間中工作的具名資料流。支援與提示相同的狀態預留位置。留空時，回合會落入房間的常設對話，展開時所有代理會交錯其中。';

  @override
  String get nodeConfigConversationTitleHint => '架構分析';

  @override
  String get nodeConfigOutputKey => '輸出鍵';

  @override
  String get nodeConfigPrompt => '提示範本';

  @override
  String get nodeConfigPromptHelp => '使用雙大括號預留位置，在執行時從狀態取出值。';

  @override
  String get nodeConfigScript => 'Bash 指令碼';

  @override
  String get nodeConfigScriptHelp =>
      '以 bash -c 執行。會設定 GITHUB_TOKEN。預留位置會在執行前替換。';

  @override
  String get nodeConfigRouteKeys => '路由鍵';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return '來自 $source 的路由鍵';
  }

  @override
  String get conditionSectionTitle => '條件';

  @override
  String get conditionMode => '模式';

  @override
  String get conditionModeFilesAny => '檔案存在—任一';

  @override
  String get conditionModeFilesAll => '檔案存在—全部';

  @override
  String get conditionModeComparison => '比較';

  @override
  String get conditionModeSwitch => '切換';

  @override
  String get conditionFilePaths => '檔案路徑';

  @override
  String get conditionFilePathsAnyHelp => '每行一個路徑，相對於基準目錄。任一存在即路由為真。';

  @override
  String get conditionFilePathsAllHelp => '每行一個路徑，相對於基準目錄。全部存在才路由為真。';

  @override
  String get conditionBaseKey => '基準目錄鍵';

  @override
  String get conditionBaseKeyHelp => '路徑據以解析的目錄狀態鍵（預設 repo_local_path）。';

  @override
  String get conditionRecursive => '搜尋子目錄';

  @override
  String get conditionNegate => '反轉：缺少時路由為真';

  @override
  String get conditionLeft => '左值';

  @override
  String get conditionOperator => '運算子';

  @override
  String get conditionRight => '右值';

  @override
  String get conditionSwitchKey => '依狀態鍵切換';

  @override
  String get conditionCases => '案例（以逗號分隔）';

  @override
  String get conditionCasesHelp => '依序與值比對的路由鍵。';

  @override
  String get conditionDefaultCase => '預設案例';

  @override
  String get triggerManualHelp => '顯示在執行頁面並可手動啟動。';

  @override
  String get triggerKindSchedule => '依排程';

  @override
  String get triggerScheduleExprLabel => '排程（cron 或 every:seconds）';

  @override
  String get triggerTimezoneLabel => '時區（選填）';

  @override
  String get triggerCatchUpLabel => '錯過執行時';

  @override
  String get triggerCatchUpRunOnce => '補執行一次';

  @override
  String get triggerCatchUpSkip => '略過';

  @override
  String get syncHealthTitle => '同步健康狀態';

  @override
  String get syncHealthNoConfigs => '尚無同步連線';

  @override
  String get syncHealthNeverSynced => '從未同步';

  @override
  String get syncOutcomeOk => '已同步';

  @override
  String get syncOutcomeFailed => '失敗';

  @override
  String get syncOutcomeSkipped => '已略過';

  @override
  String syncHealthFailedStreak(int count) {
    return '連續失敗 $count 次';
  }

  @override
  String get triggerWebhookHelp => '會產生一個帶簽章的 webhook URL。外部系統向它 POST 即可啟動此管線。';

  @override
  String get triggerWebhookPathLabel => 'Webhook 路徑';

  @override
  String get triggerMatchStatusLabel => '僅當狀態為';

  @override
  String get triggerSummaryNone => '無觸發器';

  @override
  String triggerEverySeconds(int seconds) {
    return '每 $seconds 秒';
  }

  @override
  String get triggerEventManual => '手動執行';

  @override
  String get triggerEventSchedule => '排程';

  @override
  String get triggerEventPrStatusChanged => 'PR 狀態變更';

  @override
  String get triggerEventExternalPr => '外部 PR 建立';

  @override
  String get triggerEventPrPublished => 'PR 發布';

  @override
  String get triggerEventPrMerged => 'PR 已合併';

  @override
  String get triggerEventRepoAdded => '儲存庫已新增';

  @override
  String get triggerEventCodeGraphWatch => '檔案變更';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個變更檔案',
      one: '1 個變更檔案',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '還有 $count 個';
  }

  @override
  String get pipelineRunCauseRescan => '磁碟上有變更';

  @override
  String get pipelineRunCauseInitial => '此 checkout 的首次索引';

  @override
  String get triggerEventMessageReceived => '收到訊息';

  @override
  String get triggerEventTicketCompleted => '工單已完成';

  @override
  String get triggerEventTicketFailed => '工單失敗';

  @override
  String get triggerEventTicketCancelled => '工單已取消';

  @override
  String get triggerEventBudgetCrossed => '跨越預算門檻';

  @override
  String get nodeLibrarySearchHint => '搜尋節點';

  @override
  String get nodeLibraryNoMatches => '沒有符合的節點';

  @override
  String get nodeCategoryFlow => '流程與邏輯';

  @override
  String get nodeCategoryPr => 'PR 審查';

  @override
  String get nodeCategoryAgents => '代理';

  @override
  String get nodeCategoryMessaging => '訊息';

  @override
  String get nodeCategoryCode => '程式碼';

  @override
  String get triggerDisabledTag => '關閉';

  @override
  String get pipelineInputTypeRepo => '儲存庫';

  @override
  String get pipelineRunNoRepos => '此工作區尚無儲存庫。';

  @override
  String get allowTicketingApi => '允許工單 API 呼叫';

  @override
  String get ticketingApiKey => '工單 API 金鑰';

  @override
  String get ticketingApiKeySubtitle => '將工單供應商的 API 金鑰注入沙箱。';

  @override
  String get ticketingProvider => '工單供應商';

  @override
  String get connectGitHubAndTicketing =>
      '連接程式碼託管平台，讓 Control Center 能讀取你的 pull request、issue 與審查。也可以選擇連接工單供應商。憑證由你的伺服器保管，絕不會存放在這台機器上。';

  @override
  String get triggerEventTicketAssigned => '工單已指派';

  @override
  String get triggerEventTicketCreated => '工單已建立';

  @override
  String get triggerEventTicketStatusChanged => '工單狀態已變更';

  @override
  String get triggerEventMeetingRecordingStopped => '會議錄製已停止';

  @override
  String get triggerEventSkillUpdated => '技能已更新';

  @override
  String get triggerEventSpaceDeleted => '空間已刪除';

  @override
  String get triggerExternalPrHelp =>
      '在程式碼託管平台上開啟的拉取請求，不是從 Control Center 開啟的。';

  @override
  String get triggerPrPublishedHelp => '從 Control Center 或由智慧體開啟的拉取請求。';

  @override
  String get triggerPrStatusChangedHelp => '已合併、關閉、開啟、重新開啟或核准。可在檢查器中依狀態篩選。';

  @override
  String get triggerPrMergedHelp => '僅在拉取請求合併時觸發，關閉或重新開啟時不會。';

  @override
  String get triggerRepoAddedHelp => '將儲存庫關聯到此工作區。';

  @override
  String get triggerCodeGraphWatchHelp => '已關聯儲存庫中的檔案在磁碟上變更。';

  @override
  String get triggerMessageReceivedHelp => '空間中收到新訊息。';

  @override
  String get triggerTicketCreatedHelp => '在此工作區中建立工單。';

  @override
  String get triggerTicketStatusChangedHelp => '工單在狀態之間切換。';

  @override
  String get triggerTicketCompletedHelp => '工單成功完成。';

  @override
  String get triggerTicketFailedHelp => '智慧體執行失敗，工單被標示為失敗。';

  @override
  String get triggerTicketCancelledHelp => '工單被取消，不會繼續。';

  @override
  String get triggerBudgetCrossedHelp => '工作區或智慧體的支出上限被突破。';

  @override
  String get triggerTicketAssignedHelp => '工單被指派給人員、智慧體或團隊。';

  @override
  String get triggerMeetingRecordingStoppedHelp => '會議錄音結束。';

  @override
  String get triggerSkillUpdatedHelp => '技能被安裝或更新。';

  @override
  String get triggerSpaceDeletedHelp => '對話空間被刪除。';

  @override
  String get navTickets => '工單';

  @override
  String get ticketsTitle => '工單';

  @override
  String get newTicket => '新增工單';

  @override
  String get noTicketsYet => '尚無工單';

  @override
  String get addCollaborator => '新增協作者';

  @override
  String get noCollaborators => '尚無協作者';

  @override
  String get linkedPullRequests => '已連結的 pull request';

  @override
  String get noLinkedPullRequests => '尚無已連結的 pull request';

  @override
  String get stopAgent => '停止代理';

  @override
  String get ticketProperties => '屬性';

  @override
  String get ticketTabIssue => 'Issue';

  @override
  String get ticketSelectPrompt => '選擇一張工單以查看詳細資訊';

  @override
  String get unassigned => '未指派';

  @override
  String get ticketStatusBacklog => '待處理';

  @override
  String get ticketStatusOpen => '待辦';

  @override
  String get ticketStatusInProgress => '進行中';

  @override
  String get ticketStatusInReview => '審查中';

  @override
  String get ticketStatusDone => '完成';

  @override
  String get ticketStatusBlocked => '已阻塞';

  @override
  String get ticketStatusFailed => '失敗';

  @override
  String get ticketStatusCancelled => '已取消';

  @override
  String get notificationTicketAssigned => '工單已指派';

  @override
  String get notificationTicketStatusChanged => '工單狀態已變更';

  @override
  String get priority => '優先順序';

  @override
  String get status => '狀態';

  @override
  String get assignee => '負責人';

  @override
  String get labels => '標籤';

  @override
  String get noLabelsYet => '尚無標籤';

  @override
  String get clearLabels => '清除標籤';

  @override
  String get pipelineStepAgentActivity => '代理活動';

  @override
  String get runStatusCompleted => '已完成';

  @override
  String get runStatusQueued => '排隊中';

  @override
  String get ticketDescription => '描述';

  @override
  String get ticketPriorityNone => '無';

  @override
  String get ticketPriorityUrgent => '緊急';

  @override
  String get ticketPriorityHigh => '高';

  @override
  String get ticketPriorityMedium => '中';

  @override
  String get ticketPriorityLow => '低';

  @override
  String get ticketViewList => '清單';

  @override
  String get ticketViewBoard => '看板';

  @override
  String get ticketTitlePlaceholder => 'Issue 標題';

  @override
  String get ticketDescriptionPlaceholder => '新增描述…';

  @override
  String get createMore => '建立更多';

  @override
  String selectedCount(int count) {
    return '已選取 $count 項';
  }

  @override
  String get clearSelection => '清除選取';

  @override
  String get bulkDeleteTitle => '刪除工單';

  @override
  String bulkDeleteMessage(int count) {
    return '要刪除已選取的 $count 張工單嗎？此操作無法復原。';
  }

  @override
  String get assignTo => '指派給…';

  @override
  String get sectionMembers => '成員';

  @override
  String get sectionAgents => '代理';

  @override
  String get sidebarGroupWorkspace => '工作區';

  @override
  String get notificationsTitle => '通知';

  @override
  String get notificationsTooltip => '通知';

  @override
  String get notificationsEmpty => '已全部讀完';

  @override
  String notificationsUnreadCount(int count) {
    return '$count 則未讀';
  }

  @override
  String get notificationsMarkRead => '標示為已讀';

  @override
  String get notificationsMarkUnread => '標示為未讀';

  @override
  String get notificationsEntryActions => '通知動作';

  @override
  String get markAllRead => '全部標示為已讀';

  @override
  String get teamsNav => '團隊';

  @override
  String get noWorkspace => '沒有工作區';

  @override
  String get selectWorkspace => '選擇工作區';

  @override
  String get navMemory => '記憶';

  @override
  String get memoryTabFacts => '事實';

  @override
  String get memoryTabPolicies => '政策';

  @override
  String get memoryGraphShowFacts => '顯示事實';

  @override
  String get memoryGraphHideFacts => '隱藏事實';

  @override
  String get memoryGraphExpandAll => '展開全部事實';

  @override
  String get memoryGraphCollapseAll => '摺疊全部事實';

  @override
  String get memoryTabGraph => '知識圖譜';

  @override
  String get memoryNoWorkspace => '選擇工作區以查看其記憶。';

  @override
  String get searchArticles => '搜尋文章';

  @override
  String get filterAll => '全部';

  @override
  String get filterUnread => '未讀';

  @override
  String get filterSaved => '已儲存';

  @override
  String get saveArticle => '儲存文章';

  @override
  String get removeFromSaved => '從已儲存移除';

  @override
  String get filterBySource => '依來源篩選';

  @override
  String get viewAsList => '清單檢視';

  @override
  String get viewAsGrid => '網格檢視';

  @override
  String get noMatchingArticles => '沒有符合的文章';

  @override
  String get noMatchingArticlesBody => '請嘗試其他搜尋字詞或來源篩選條件。';

  @override
  String get allCaughtUp => '已全部讀完';

  @override
  String get allCaughtUpBody => '沒有未讀文章—稍後再回來看看。';

  @override
  String get openArticlesInAppDescription => '在內建閱讀器而非預設瀏覽器中開啟連結。';

  @override
  String get blockAdsTrackersDescription => '從你在閱讀器中開啟的文章移除廣告、追蹤器與 Cookie 橫幅。';

  @override
  String get agentQuestionHeader => '給你的問題';

  @override
  String get agentQuestionAnsweredLabel => '已回答';

  @override
  String get agentQuestionFreeformHint => '輸入你的答案…';

  @override
  String agentQuestionProgress(int index, int count) {
    return '問題 $index / $count';
  }

  @override
  String get agentQuestionSkip => '略過';

  @override
  String get agentQuestionSkippedLabel => '已略過';

  @override
  String get agentQuestionFreeformOptionHint => '用你自己的話描述…';

  @override
  String get reviewRequested => '審查請求';

  @override
  String get connectGitHubHint =>
      '登入 GitHub，或在「設定 → 工作區 → 個人資料與身分 → 程式碼託管」中新增權杖';

  @override
  String get connectGitHubToLoadPrs => '連接 GitHub 以載入 pull request';

  @override
  String get noRepositoriesConfigured => '尚未設定任何儲存庫';

  @override
  String openedAgo(String age) {
    return '建立於 $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author 建立了此 pull request';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個 commit',
      one: '1 個 commit',
    );
    return '$author 建立了此 pull request，包含 $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor 向 $reviewers 請求審查';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor 移除了對 $reviewers 的審查請求';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor 向 $requested 請求審查，並移除了對 $removed 的審查請求';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '標籤',
      one: '標籤',
    );
    return '$actor 新增了 $labels $_temp0';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '標籤',
      one: '標籤',
    );
    return '$actor 移除了 $labels $_temp0';
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
      other: '標籤',
      one: '標籤',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: '標籤',
      one: '標籤',
    );
    return '$actor 新增了 $added $_temp0，並移除了 $removed $_temp1';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author 已提交';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個 commit',
      one: '1 個 commit',
    );
    return '$author 推送了 $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author 核准了這些變更';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author 要求修改';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 則程式碼評論',
      one: '1 則程式碼評論',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author 已審查';
  }

  @override
  String get prTimelineSomeone => '某人';

  @override
  String get prTimelineBotBadge => '機器人';

  @override
  String updatedAgo(String age) {
    return '更新於 $age';
  }

  @override
  String get checksPassing => '檢查通過';

  @override
  String get checksRunning => '檢查執行中';

  @override
  String get needsYourReview => '需要你審查';

  @override
  String get checks => '檢查';

  @override
  String get noReviewersAssigned => '未指派審查者';

  @override
  String get noAssignees => '沒有負責人';

  @override
  String get loadingEllipsis => '載入中…';

  @override
  String get loadingChecks => '正在載入檢查…';

  @override
  String get noChecksYet => '尚未執行任何檢查';

  @override
  String get noChangesToReview => '沒有要審查的變更';

  @override
  String checksFailingCount(int count) {
    return '$count 項失敗';
  }

  @override
  String get showMore => '顯示更多';

  @override
  String get showLess => '顯示較少';

  @override
  String get backToPullRequests => '返回 pull request';

  @override
  String get pullRequestNotFound => '找不到 pull request';

  @override
  String get pullRequestNotFoundBody => '它可能已被合併、關閉或移動。';

  @override
  String get couldntLoadPullRequest => '無法載入此 pull request';

  @override
  String get showDetails => '顯示詳細資訊';

  @override
  String get noDescriptionProvided => '未提供描述。';

  @override
  String get factsHint => '代理學到的事實會出現在這裡。';

  @override
  String get noFactsMatch => '沒有符合搜尋的事實';

  @override
  String get memoryLoadError => '無法載入記憶';

  @override
  String get sortRecent => '最近';

  @override
  String get sortConfidence => '信心';

  @override
  String get confidenceTooltip => '代理對此事實為真的把握程度，從 0 到 100%。';

  @override
  String get supersededTooltip => '已有較新的事實取代了它。';

  @override
  String get domain => '網域';

  @override
  String get fitToView => '符合檢視';

  @override
  String get project => '專案';

  @override
  String get newProject => '新增專案';

  @override
  String get editProject => '編輯專案';

  @override
  String get deleteProject => '刪除專案';

  @override
  String get noProject => '無專案';

  @override
  String get allTickets => '所有工單';

  @override
  String get projectNamePlaceholder => '專案名稱';

  @override
  String get projectDescriptionPlaceholder => '描述（選填）';

  @override
  String get projectColorLabel => '顏色';

  @override
  String get noProjectsYet => '尚無專案';

  @override
  String get projectTicketsEmpty => '此專案尚無工單';

  @override
  String get createProject => '建立專案';

  @override
  String projectProgress(int done, int total) {
    return '$done / $total 項完成';
  }

  @override
  String deleteProjectConfirm(String name) {
    return '要刪除「$name」嗎？其工單會保留，只是會從專案中移除。';
  }

  @override
  String get projectStatusActive => '進行中';

  @override
  String get projectStatusCompleted => '已完成';

  @override
  String get projectStatusArchived => '已封存';

  @override
  String get markProjectCompleted => '標示為已完成';

  @override
  String get markProjectActive => '標示為進行中';

  @override
  String get archiveProject => '封存';

  @override
  String get restoreProject => '還原';

  @override
  String get relations => '關聯';

  @override
  String get relateTo => '關聯至';

  @override
  String get relationSubIssueOf => '子 issue…';

  @override
  String get relationParentOf => '父 issue…';

  @override
  String get relationBlockedBy => '被阻擋…';

  @override
  String get relationBlocking => '阻擋…';

  @override
  String get relationRelatedTo => '相關…';

  @override
  String get relationDuplicateOf => '重複於…';

  @override
  String get relationGroupParent => '父項';

  @override
  String get relationGroupSubIssues => '子 issue';

  @override
  String get relationGroupBlockedBy => '被阻擋';

  @override
  String get relationGroupBlocking => '阻擋';

  @override
  String get relationGroupRelated => '相關';

  @override
  String get relationGroupDuplicateOf => '重複於';

  @override
  String get relationGroupDuplicatedBy => '被重複';

  @override
  String get copyId => '複製 ID';

  @override
  String get ticketIdCopied => '已複製工單 ID';

  @override
  String get searchTicketsHint => '搜尋工單…';

  @override
  String get noMatchingTickets => '沒有符合的工單';

  @override
  String get clearAll => '全部清除';

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos 個儲存庫',
      one: '1 個儲存庫',
    );
    String _temp1 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs 個 PR',
      one: '1 個 PR',
    );
    return '在 $_temp0 中，有 $_temp1 等待你審查';
  }

  @override
  String get manageWorkspacesSubtitle => '重新命名工作區並變更其標記—從左側選擇一個來編輯。';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個工作區',
      one: '1 個工作區',
      zero: '沒有工作區',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos 個儲存庫',
      one: '1 個儲存庫',
      zero: '沒有儲存庫',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents 個代理',
      one: '1 個代理',
      zero: '0 個代理',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => '身分';

  @override
  String get uploadImage => '上傳圖片';

  @override
  String get failedToSaveLogo => '無法儲存標誌圖片。請確認應用程式能讀取所選檔案。';

  @override
  String get workspaceLogoHint => 'PNG、JPG 或 GIF，最大 2 MB。否則將使用工作區名稱首字。';

  @override
  String get workspaceNameFieldHelp => '顯示在切換器、麵包屑與每個畫面上。';

  @override
  String get dangerZone => '危險區域';

  @override
  String get deleteThisWorkspace => '刪除此工作區';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return '將永久移除 $name 及其儲存庫連線、代理與記憶。此操作無法復原。';
  }

  @override
  String get discard => '捨棄';

  @override
  String discardChangesQuestion(String name) {
    return '要捨棄對 $name 的未儲存變更嗎？';
  }

  @override
  String get workspaceUpdated => '工作區已更新';

  @override
  String get editTitle => '編輯標題';

  @override
  String get editDescription => '編輯描述';

  @override
  String get addDescription => '新增描述';

  @override
  String get prTitlePlaceholder => '標題';

  @override
  String get prBodyPlaceholder => '留下描述';

  @override
  String get write => '撰寫';

  @override
  String get overview => '總覽';

  @override
  String get noFilesChanged => '沒有檔案變更';

  @override
  String get diff => 'Diff';

  @override
  String get preview => '預覽';

  @override
  String get imageDiffBefore => '變更前';

  @override
  String get imageDiffAfter => '變更後';

  @override
  String get imageDiffModeTwoUp => '並排';

  @override
  String get imageDiffModeSwipe => '滑動';

  @override
  String get imageDiffModeDifference => '差異';

  @override
  String imageDiffChangedPercent(String percent) {
    return '已變更 $percent%';
  }

  @override
  String get imageDiffPictures => '圖片';

  @override
  String get imageDiffSource => '原始碼';

  @override
  String get imageDiffDeleted => '已刪除';

  @override
  String get imageDiffAdded => '已新增';

  @override
  String imageDiffDimensions(int width, int height) {
    return '寬: ${width}px | 高: ${height}px';
  }

  @override
  String get outdated => '已過時';

  @override
  String get outdatedComments => '過時的評論';

  @override
  String outdatedCountLabel(int count) {
    return '$count 則過時';
  }

  @override
  String get prTemplateLabel => '範本';

  @override
  String get prTemplateDefault => '預設';

  @override
  String get addReviewers => '新增審查者';

  @override
  String get addAssignees => '新增負責人';

  @override
  String get searchUsers => '搜尋人員…';

  @override
  String get searchReviewers => '搜尋人員與團隊…';

  @override
  String get usersSectionLabel => '人員';

  @override
  String get userStatusBusy => '忙碌中';

  @override
  String get teamsSectionLabel => '團隊';

  @override
  String get suggestedReviewers => '建議的審查者';

  @override
  String get noMatchingUsers => '沒有符合的人員';

  @override
  String get noMatchingReviewers => '沒有符合項目';

  @override
  String get requiredByCodeOwners => '由程式碼擁有者要求';

  @override
  String reviewedOnBehalfOf(String login) {
    return '透過 $login';
  }

  @override
  String get team => '團隊';

  @override
  String get markdownBold => '粗體';

  @override
  String get markdownItalic => '斜體';

  @override
  String get markdownHeading => '標題';

  @override
  String get markdownBulletList => '項目符號清單';

  @override
  String get markdownChecklist => '核取清單';

  @override
  String get markdownCode => '程式碼';

  @override
  String get markdownLink => '連結';

  @override
  String get markdownQuote => '引用';

  @override
  String get markdownSupported => '支援 Markdown';

  @override
  String get markdownAttachImages => '點擊以新增圖片';

  @override
  String failedToUpdateTitle(String error) {
    return '無法更新標題：$error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return '無法更新描述：$error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return '無法更新審查者：$error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return '無法更新負責人：$error';
  }

  @override
  String get discardChangesConfirm => '要捨棄你的變更嗎？';

  @override
  String get newPr => '新增 PR';

  @override
  String get openPullRequest => '建立 pull request';

  @override
  String get composePrSubtitle => '從你已推送的分支建立—不涉及代理或工單';

  @override
  String get createAsDraft => '建立為草稿';

  @override
  String get composePrNoRepo => '未選取 GitHub 儲存庫';

  @override
  String get composePrNoRepoHint => '選擇具有 GitHub 連結儲存庫的工作區以建立 pull request。';

  @override
  String get composePrPickBranches => '選擇基礎與比較分支以預覽變更。';

  @override
  String get composePrNothingToCompare => '這些分支之間沒有任何變更。';

  @override
  String get repository => '儲存庫';

  @override
  String get baseBranchLabel => '基礎';

  @override
  String get compareBranchLabel => '比較';

  @override
  String get selectBranch => '選擇分支';

  @override
  String get navMeetings => '會議';

  @override
  String get meetingsNoWorkspace => '選擇工作區以查看會議。';

  @override
  String get meetingsEmpty => '尚無會議';

  @override
  String get meetingsEmptyHint => '錄下你的第一場會議—音訊只會留在這台裝置上，代理會將它轉為筆記、決議與行動項目。';

  @override
  String get meetingNotesHint => '快速記下筆記—會後代理會加以擴充。';

  @override
  String get meetingSpeakerMe => '你';

  @override
  String get meetingStatusRecording => '錄音中';

  @override
  String get meetingStatusProcessing => '處理中';

  @override
  String get meetingStatusDone => '完成';

  @override
  String get meetingStatusFailed => '失敗';

  @override
  String get meetingsSubtitle => '在此裝置上錄製與轉錄，再由代理撰寫摘要。';

  @override
  String get meetingsRecordMeeting => '錄製會議';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個處理中',
      one: '1 個處理中',
    );
    return '$_temp0';
  }

  @override
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 場會議',
      one: '1 場會議',
      zero: '沒有會議',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => '未完成行動';

  @override
  String get meetingsLedgerDecisions => '決議';

  @override
  String get meetingsLiveOpen => '開啟錄音';

  @override
  String get meetingTemplateShort => '範本';

  @override
  String get meetingsStatThisWeek => '本週';

  @override
  String get meetingsStatRecorded => '已錄製';

  @override
  String get meetingsFilterAll => '全部';

  @override
  String get meetingsFilterDone => '完成';

  @override
  String get meetingsFilterProcessing => '處理中';

  @override
  String get meetingsSearchHint => '依標題、人員、應用程式篩選…';

  @override
  String get meetingsBucketToday => '今天';

  @override
  String get meetingsBucketYesterday => '昨天';

  @override
  String get meetingsBucketEarlierThisWeek => '本週稍早';

  @override
  String get meetingsBucketLastWeek => '上週';

  @override
  String get meetingsBucketOlder => '更早';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 項決議',
      one: '1 項決議',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total 項行動項目';
  }

  @override
  String get meetingsEnhancedPill => '已增強';

  @override
  String get meetingsTranscribing => '轉錄並摘要中…';

  @override
  String get meetingsOpenAction => '開啟';

  @override
  String get meetingsStopProcessing => '停止';

  @override
  String get meetingsStillTranscribing => '仍在轉錄中—完成後摘要就會出現。';

  @override
  String get meetingsNoMatch => '沒有符合的會議';

  @override
  String get meetingsNoMatchHint => '請嘗試其他篩選條件或搜尋字詞。';

  @override
  String get meetingBackAllMeetings => '所有會議';

  @override
  String get meetingReRunSummary => '重新產生摘要';

  @override
  String get meetingExport => '匯出';

  @override
  String get meetingAugmentingBanner => '正在從逐字稿增補你的筆記—擷取決議與行動項目…';

  @override
  String get meetingTabNotes => '筆記';

  @override
  String get meetingTabTranscript => '逐字稿';

  @override
  String get meetingTabActionItems => '行動項目';

  @override
  String get meetingTabDecisions => '決議';

  @override
  String get meetingNotesEnhancedToggle => '增強版';

  @override
  String get meetingNotesYoursToggle => '你的筆記';

  @override
  String get meetingEnhancedByAgent => '由代理增強 · 來自逐字稿';

  @override
  String get meetingEnhancedPending => '代理仍在處理此摘要。';

  @override
  String get meetingNotesEmpty => '尚無增強筆記。';

  @override
  String get meetingNotesSavedLocally => '已儲存於本機';

  @override
  String get meetingNotesSaving => '儲存中…';

  @override
  String get meetingViewFullTranscript => '檢視完整逐字稿';

  @override
  String get meetingTranscriptSearchHint => '搜尋逐字稿…';

  @override
  String get meetingSpeakerEveryone => '所有人';

  @override
  String get meetingSpeakerOthers => '其他人';

  @override
  String get meetingTranscriptEmpty => '尚無逐字稿。';

  @override
  String get meetingActionItemsEmpty => '未擷取到任何行動項目。';

  @override
  String get meetingActionItemFrom => '來自此會議';

  @override
  String get meetingCreateTicket => '建立工單';

  @override
  String meetingTicketCreated(String key) {
    return '工單 $key 已建立並派送。';
  }

  @override
  String get meetingTicketFailed => '無法建立工單。';

  @override
  String get meetingDecisionsEmpty => '尚未記錄任何決議。';

  @override
  String get meetingEditTitle => '編輯標題';

  @override
  String get meetingTitleLabel => '標題';

  @override
  String get meetingAddActionItem => '新增行動項目';

  @override
  String get meetingEditActionItem => '編輯行動項目';

  @override
  String get meetingDeleteActionItem => '刪除行動項目';

  @override
  String get meetingActionItemContentLabel => '行動項目';

  @override
  String get meetingActionItemContentHint => '需要做什麼？';

  @override
  String get meetingActionItemOwnerLabel => '負責人';

  @override
  String get meetingActionItemOwnerHint => '由誰負責？（選填）';

  @override
  String get meetingAddDecision => '新增決議';

  @override
  String get meetingEditDecision => '編輯決議';

  @override
  String get meetingDeleteDecision => '刪除決議';

  @override
  String get meetingDecisionContentLabel => '決議';

  @override
  String get meetingDecisionContentHint => '決定了什麼？';

  @override
  String get meetingReRunStarted => '正在對逐字稿重新執行摘要器…';

  @override
  String get meetingReRunNoTranscript => '還沒有可摘要的逐字稿。';

  @override
  String get meetingExportCopied => '筆記已以 Markdown 複製到剪貼簿。';

  @override
  String get meetingExportSaved => '會議已匯出。';

  @override
  String meetingExportFailed(String error) {
    return '匯出失敗：$error';
  }

  @override
  String get meetingExportNothing => '還沒有可匯出的內容。';

  @override
  String get meetingPlaybackPlay => '播放';

  @override
  String get meetingPlaybackPause => '暫停';

  @override
  String get meetingPlaybackUnavailable => '此裝置無法播放音訊。';

  @override
  String get meetingDetectedTitle => '偵測到會議';

  @override
  String meetingDetectedSubtitle(String label) {
    return '「$label」看起來正在進行。要錄製嗎？';
  }

  @override
  String get meetingDetectedSubtitleGeneric => '看起來正在進行會議。要錄製嗎？';

  @override
  String get meetingDetectedRecord => '錄製';

  @override
  String get meetingDetectedDismiss => '關閉';

  @override
  String get meetingAutoStopTitle => '這場會議看起來已結束。要停止錄音嗎？';

  @override
  String get meetingAutoStopStop => '停止';

  @override
  String get meetingAutoStopKeep => '繼續錄音';

  @override
  String get meetingAutoDetect => '自動偵測會議';

  @override
  String get meetingAutoDetectDescription => '監看行事曆與視訊會議應用程式，並在會議開始時詢問是否錄製。';

  @override
  String get meetingsRecordingCrumb => '錄音中…';

  @override
  String get meetingRecordTitleHint => '會議標題';

  @override
  String get meetingRecordTappingLabel => '擷取：';

  @override
  String get meetingRecordMic => '麥克風';

  @override
  String get meetingRecordSystemAudio => '系統音訊';

  @override
  String get meetingRecordPause => '暫停';

  @override
  String get meetingRecordResume => '繼續';

  @override
  String get meetingRecordStop => '停止並摘要';

  @override
  String get meetingRecordYourNotes => '你的筆記';

  @override
  String get meetingRecordNotesPlaceholder => '邊聽邊打字。幾個片段就夠了—停止後代理會用逐字稿將它們擴充。';

  @override
  String get meetingRecordLiveTranscript => '即時逐字稿';

  @override
  String get meetingRecordDecoding => '於裝置端解碼';

  @override
  String get meetingRecordListening => '聆聽中…語音會在一兩秒內出現在這裡，並標記為你／其他人。';

  @override
  String get meetingRecordPausedHint => '已暫停—恢復前將忽略音訊。';

  @override
  String get meetingRecordNotActive => '目前沒有進行中的錄音。';

  @override
  String get meetingHudRecording => '錄音中';

  @override
  String get meetingHudPaused => '已暫停';

  @override
  String get meetingHudOpen => '開啟';

  @override
  String get meetingHudStop => '停止';

  @override
  String get meetingToolbarPopOut => '彈出視窗';

  @override
  String get meetingToolbarHoldToStop => '按住以停止錄音';

  @override
  String get meetingToolbarSemanticLabel => '會議錄音工具列';

  @override
  String get orchestrate => '編排';

  @override
  String get orchestrationUnavailable => '編排功能無法使用';

  @override
  String get orchestrationApprove => '核准計畫';

  @override
  String get orchestrationReject => '拒絕';

  @override
  String get orchestrationCancel => '取消編排';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count 個角色—$hires 個新進';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count 個子工單';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return '預估成本：\$$amount';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total 個子工單完成';
  }

  @override
  String get orchestrationStatusProposed => '已提出';

  @override
  String get orchestrationStatusApproved => '已核准';

  @override
  String get orchestrationStatusExecuting => '執行中';

  @override
  String get orchestrationStatusSynthesizing => '彙整中';

  @override
  String get orchestrationStatusCompleted => '已完成';

  @override
  String get orchestrationStatusFailed => '已失敗';

  @override
  String get orchestrationStatusCancelled => '已取消';

  @override
  String get messageFailed => '執行失敗';

  @override
  String get turnLimitReached => '已在回合上限停止—回覆以繼續';

  @override
  String get retried => '已重試';

  @override
  String replyingTo(String name) {
    return '回覆 $name';
  }

  @override
  String get silenceTimeoutLabel => '靜音逾時（分鐘）';

  @override
  String get silenceTimeoutHint => '例如 15—超過這段時間沒有輸出即終止執行';

  @override
  String get capabilityJsonMode => 'JSON 模式';

  @override
  String get capabilityModelSelection => '模型選擇';

  @override
  String get transcriptThinking => '思考中…';

  @override
  String transcriptThoughtFor(String duration) {
    return '思考了 $duration';
  }

  @override
  String get transcriptStatusMakingEdits => '正在編輯…';

  @override
  String get transcriptStatusReadingFiles => '正在讀取檔案…';

  @override
  String get transcriptStatusSearching => '正在搜尋程式碼庫…';

  @override
  String get transcriptStatusRunningCommands => '正在執行命令…';

  @override
  String get transcriptStatusResponding => '正在回應…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return '正在執行 $tool…';
  }

  @override
  String get transcriptInput => '輸入';

  @override
  String get transcriptOutput => '輸出';

  @override
  String get transcriptErrorLabel => '錯誤';

  @override
  String get transcriptSandboxBlocked => '沙箱封鎖了一個動作';

  @override
  String transcriptShowFullOutput(int kb) {
    return '顯示完整輸出（+$kb KB）';
  }

  @override
  String transcriptShowAllLines(int count) {
    return '顯示全部 $count 行';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return '顯示前 $count 行';
  }

  @override
  String get transcriptGrepNoMatches => '沒有符合項目';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches 筆符合',
      one: '1 筆符合',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files 個檔案',
      one: '1 個檔案',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return '人員 $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => '重新命名說話者';

  @override
  String get meetingRenameSpeakerTitle => '重新命名說話者';

  @override
  String get meetingSpeakerNameLabel => '名稱';

  @override
  String get meetingSpeakerSuggestFromCalendar => '來自此會議的受邀者';

  @override
  String get meetingRenameSpeakerApplyAll => '套用至此說話者的所有區塊';

  @override
  String get meetingRenameSpeakerScopeHint => '關閉時，只會重新命名選取的那一行。';

  @override
  String get meetingLinkEvent => '連結至活動';

  @override
  String get meetingChangeEvent => '變更活動';

  @override
  String get meetingLinkEventTitle => '連結至行事曆活動';

  @override
  String get meetingLinkEventSearchHint => '搜尋活動';

  @override
  String get meetingLinkEventEmpty => '附近沒有行事曆活動';

  @override
  String get meetingUnlinkEvent => '移除連結';

  @override
  String get calendarLinkExistingMeeting => '連結至現有會議';

  @override
  String get calendarLinkMeetingTitle => '連結會議';

  @override
  String get calendarLinkMeetingSearchHint => '搜尋會議';

  @override
  String get calendarLinkMeetingEmpty => '沒有可連結的會議';

  @override
  String get meetingRenameSpeakerFailed => '無法重新命名說話者';

  @override
  String get calendarLinkUpdateFailed => '無法更新行事曆連結';

  @override
  String get rename => '重新命名';

  @override
  String get notNow => '現在不要';

  @override
  String get meetingSaveVoiceProfileTitle => '儲存語音設定檔？';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return '儲存其聲紋後，未來的會議將自動辨識 $name。';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return '已儲存 $name 的語音設定檔';
  }

  @override
  String get meetingVoiceProfileSaveFailed => '無法儲存語音設定檔';

  @override
  String get voiceProfilesSection => '語音設定檔';

  @override
  String get voiceProfilesDescription => '已儲存的語音在未來的會議中會被自動辨識。';

  @override
  String get voiceProfilesEmpty => '尚無已儲存的語音。請先在會議逐字稿中為說話者命名，再選擇「儲存語音設定檔」。';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個樣本',
      one: '1 個樣本',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => '重新命名語音設定檔';

  @override
  String get deleteVoiceProfileTitle => '刪除語音設定檔？';

  @override
  String deleteVoiceProfileBody(String name) {
    return '要停止辨識 $name 嗎？其已儲存的聲紋將被移除。過去會議中已套用的名稱則會保留。';
  }

  @override
  String get connectedLabel => '已連線';

  @override
  String get ideTabGeneral => '一般';

  @override
  String get ideTabExplorer => '總管';

  @override
  String get ideTabSourceControl => '原始檔控制';

  @override
  String get generalSectionTodos => '待辦事項';

  @override
  String get generalSectionGoals => '目標';

  @override
  String get goalRunStatusActive => '進行中';

  @override
  String get goalRunStatusPaused => '已暫停';

  @override
  String get goalRunStatusCompleted => '已完成';

  @override
  String get goalRunStatusFailed => '已失敗';

  @override
  String get goalRunStatusCancelled => '已取消';

  @override
  String get goalRunStatusBudgetExhausted => '預算已用盡';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return '第 $run 次（共 $max 次）· $cost / $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return '第 $run 次 · $cost / $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return '期限 $deadline';
  }

  @override
  String get goalRunPause => '暫停目標';

  @override
  String get goalRunResume => '繼續目標';

  @override
  String goalRunResumeRaise(String cap) {
    return '繼續 · 上限提高至 $cap';
  }

  @override
  String get goalRunStop => '停止目標';

  @override
  String get generalSectionAgents => '代理';

  @override
  String get generalSectionTerminals => '終端機';

  @override
  String get generalTodosEmpty => '尚無待辦事項';

  @override
  String get generalAgentsEmpty => '沒有執行中的代理';

  @override
  String get generalTerminalsEmpty => '沒有開啟的終端機';

  @override
  String get generalSectionBrowsers => '瀏覽器';

  @override
  String get generalSectionComputers => '電腦';

  @override
  String get generalBrowsersEmpty => '沒有開啟的瀏覽器';

  @override
  String get generalComputersEmpty => '沒有開啟的電腦';

  @override
  String get generalSectionPhones => '手機';

  @override
  String get generalPhonesEmpty => '沒有開啟的手機';

  @override
  String get pauseAgent => '暫停代理';

  @override
  String get resumeAgent => '繼續代理';

  @override
  String get agentCannotPause => '此代理無法暫停—請改為停止。';

  @override
  String get goalClear => '清除目標';

  @override
  String get undoLabelGoalClear => '清除目標';

  @override
  String get todoStatusPending => '尚未開始';

  @override
  String get todoStatusInProgress => '進行中';

  @override
  String get todoStatusCompleted => '完成';

  @override
  String get reorderTodo => '重新排序待辦事項';

  @override
  String get focusTerminal => '聚焦終端機';

  @override
  String get focusMachine => '聚焦電腦';

  @override
  String get focusBrowser => '聚焦瀏覽器';

  @override
  String get todoEditorTitle => '編輯待辦事項';

  @override
  String get todoEditorHint => '每行一個項目。使用 - [ ] 表示待處理、- [~] 表示進行中、- [x] 表示完成。';

  @override
  String get todoNeedsText => '請在命令後加上一些文字';

  @override
  String get todoNotFound => '沒有符合的待辦事項';

  @override
  String get todoCleared => '已清除待辦清單';

  @override
  String get todoNothingToCopy => '沒有可複製的內容';

  @override
  String todoAdded(String content) {
    return '已新增「$content」';
  }

  @override
  String todoStarted(String content) {
    return '已開始「$content」';
  }

  @override
  String todoCompleted(String content) {
    return '已完成「$content」';
  }

  @override
  String todoRemoved(String content) {
    return '已移除「$content」';
  }

  @override
  String todoCopied(int count) {
    return '已複製 $count 個項目';
  }

  @override
  String todoImported(int count) {
    return '已匯入 $count 個項目';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return '未知的待辦命令「$name」';
  }

  @override
  String get terminal => '終端機';

  @override
  String get ideCloseTab => '關閉分頁';

  @override
  String get ideSplitEditor => '分割編輯器';

  @override
  String get ideSplitRight => '向右分割';

  @override
  String get ideSplitDown => '向下分割';

  @override
  String get ideSplitLeft => '向左分割';

  @override
  String get ideSplitUp => '向上分割';

  @override
  String get ideCloseGroup => '關閉群組';

  @override
  String get ideCloseOthers => '關閉其他';

  @override
  String get ideCloseToRight => '關閉右側';

  @override
  String get ideCloseSaved => '關閉已儲存';

  @override
  String get ideCloseAll => '全部關閉';

  @override
  String get ideSplit => '分割';

  @override
  String get ideToggleSidebar => '切換側邊欄';

  @override
  String get ideNewTab => '開啟編輯器';

  @override
  String get ideNewTabMenu => '新增分頁';

  @override
  String get ideReviewCode => '審查程式碼';

  @override
  String ideReviewCodeInRepo(String repo) {
    return '審查程式碼 ($repo)';
  }

  @override
  String get ideRevertConfirmTitle => '還原變更';

  @override
  String get ideRevertUntracked => '未追蹤的檔案無法還原';

  @override
  String get ideRevertFailed => '無法還原檔案。對話工作樹可能無法使用。';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個檔案',
      one: '1 個檔案',
    );
    return '$_temp0 無法還原（未追蹤）。';
  }

  @override
  String get ideSearchMatchCase => '區分大小寫';

  @override
  String get ideSearchWholeWord => '全字相符';

  @override
  String get ideSearchRegex => '規則運算式';

  @override
  String get ideSearchFilters => '搜尋篩選條件';

  @override
  String get ideSearchFilesToInclude => '要包含的檔案';

  @override
  String get ideSearchFilesToExclude => '要排除的檔案';

  @override
  String get ideNoOpenTabs => '沒有開啟的分頁—用 + 開啟';

  @override
  String get ideBrowserAddressHint => '輸入網址或搜尋';

  @override
  String get ideSimpleWebBrowser => '簡易網頁瀏覽器';

  @override
  String get ideWebBrowser => '網頁瀏覽器';

  @override
  String get ideBrowserEnterUrl => '在網址列輸入 URL 即可開始瀏覽';

  @override
  String get ideCodeServer => '編輯器';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return '要將變更儲存到 $fileName 嗎？';
  }

  @override
  String get ideUnsavedChangesBody => '若不儲存，你的變更將會遺失。';

  @override
  String get ideDontSave => '不儲存';

  @override
  String get editorAutoSave => '自動儲存';

  @override
  String get editorAutoSaveDescription => '在內嵌編輯器中自動儲存變更。';

  @override
  String get editorAutoSaveOff => '關閉';

  @override
  String get editorAutoSaveAfterDelay => '延遲後';

  @override
  String get editorAutoSaveOnFocusChange => '焦點變更時';

  @override
  String get ideCodeServerUnavailable => '此伺服器無法使用 code-server';

  @override
  String get ideCodeServerUnavailableHint =>
      '請在伺服器主機上安裝 code-server（coder/code-server），然後重新開啟編輯器。';

  @override
  String get ideCodeServerInstalling => '正在準備編輯器…';

  @override
  String get ideCodeServerOpenInBrowser => '在瀏覽器中開啟編輯器';

  @override
  String get ideCodeServerError => '無法開啟編輯器';

  @override
  String get paneSuspendedCaption => '已暫停以節省資源—聚焦時會重新載入';

  @override
  String get ideFolderLoadFailed => '無法載入此資料夾';

  @override
  String get ideFileSearchFailed => '無法搜尋檔案';

  @override
  String get ideSearchInFiles => '在檔案中搜尋';

  @override
  String get ideNoContentMatches => '沒有符合項目';

  @override
  String get ideSourceControlCreatePr => '建立 pull request';

  @override
  String ideSourceControlViewPr(int number) {
    return '檢視 pull request #$number';
  }

  @override
  String get ideSourceControlNoChanges => '沒有變更';

  @override
  String get noReposInConversation => '此對話中沒有儲存庫';

  @override
  String get ideSourceControlNoSpace => '開啟對話以查看其變更';

  @override
  String get ideFileLoading => '載入中…';

  @override
  String get ideFileBinary => '二進位檔案';

  @override
  String get mcpExternalServers => '外部 MCP 伺服器';

  @override
  String get mcpExternalServersDescription =>
      '連接外部 MCP 伺服器（GitHub、Sentry、Postgres、瀏覽器自動化）。你為 Claude、Cursor、VS Code 等工具設定的伺服器會被自動探索。';

  @override
  String get mcpApprovalMode => '工具核准';

  @override
  String get mcpApprovalModeDescription => '哪些工具動作不必詢問即可執行。讀取一律允許；較高的層級會出現詢問。';

  @override
  String get mcpApprovalAlwaysAsk => '總是詢問';

  @override
  String get mcpApprovalWrite => '自動核准寫入';

  @override
  String get mcpApprovalYolo => '全部自動核准';

  @override
  String get mcpNoExternalServers => '未探索到任何外部 MCP 伺服器。';

  @override
  String get mcpAuthorize => '授權';

  @override
  String get mcpReconnect => '重新連線';

  @override
  String get mcpExternalConnectionsNote =>
      '外部 MCP 伺服器執行於代理伺服器上（桌面版與網頁版共用）。授權 OAuth 伺服器僅能在桌面版進行。';

  @override
  String get mcpStatusConnected => '已連線';

  @override
  String get mcpStatusConnecting => '連線中…';

  @override
  String get mcpStatusNeedsAuth => '需要授權';

  @override
  String get mcpStatusFailed => '失敗';

  @override
  String get mcpStatusCircuitOpen => '已暫停';

  @override
  String get mcpStatusDisabled => '已停用';

  @override
  String get providersAndModels => '供應商與模型';

  @override
  String get providersAndModelsDescription =>
      '列出內建代理可使用的所有供應商—設定 API 金鑰或以瀏覽器登入、查看每個已連線供應商的模型與價格，並管理此工作區可使用哪些供應商。';

  @override
  String get syncNow => '立即同步';

  @override
  String syncNowResult(int applied, int failed) {
    return '同步完成—已套用 $applied 項、失敗 $failed 項';
  }

  @override
  String syncNowFailed(String error) {
    return '同步失敗：$error';
  }

  @override
  String get denied => '已拒絕';

  @override
  String get allowed => '已允許';

  @override
  String allowProviderSemantic(String provider) {
    return '允許 $provider';
  }

  @override
  String enabledViaEnv(String key) {
    return '透過 $key 啟用';
  }

  @override
  String costPerMillion(String input, String output) {
    return '每 1M $input / $output';
  }

  @override
  String contextTokens(String tokens) {
    return '$tokens 上下文';
  }

  @override
  String get usageAndCost => '用量與費用';

  @override
  String get usageAndCostDescription => '根據實際觀察到的執行成本，統計你的代理過去 7 天的花費。';

  @override
  String get noUsageYet => '尚無使用記錄。';

  @override
  String get spentThisWeek => '本週花費';

  @override
  String get subscriptionUsage => '訂閱用量';

  @override
  String get subscriptionUsageUnavailable => '無法使用';

  @override
  String get subscriptionUsageExhausted => '配額已用盡';

  @override
  String get subscriptionUsageSignInRequired => '重新登入';

  @override
  String get subscriptionUsageSignInExpired => '登入已過期，將於下次執行時更新';

  @override
  String get subscriptionUsagePartiallyAvailable => '部分可用';

  @override
  String resetsIn(String duration) {
    return '$duration後重設';
  }

  @override
  String get feedbackHelpful => '這有幫助';

  @override
  String get feedbackNotHelpful => '這沒有幫助';

  @override
  String get modeChat => '聊天';

  @override
  String get modePlan => '規劃';

  @override
  String get modeReview => '審查';

  @override
  String get modeOrchestrate => '編排';

  @override
  String get editorTheme => '編輯器主題';

  @override
  String get editorThemeDescription =>
      '匯入 VS Code 色彩主題，讓內嵌的 diff 與編輯器符合你的 IDE。';

  @override
  String get editorThemePasteHint => '貼上 VS Code 色彩主題 JSON 檔案的內容';

  @override
  String get editorThemeImported => '已匯入主題';

  @override
  String get editorThemeInvalid => '這看起來不是有效的 VS Code 主題';

  @override
  String get importTheme => '匯入主題';

  @override
  String get clearTheme => '清除主題';

  @override
  String get openInDiffViewer => '在 diff 檢視器中開啟';

  @override
  String get shellCommand => '命令';

  @override
  String get shellOutput => '輸出';

  @override
  String get revertToHere => '還原至此處';

  @override
  String get revertConfirmBody => '要隱藏此時間點之後的訊息，並將代理的檔案變更還原至此回合嗎？此操作可以復原。';

  @override
  String get revert => '還原';

  @override
  String get revertedToHere => '已還原至此處';

  @override
  String get nothingToRevert => '沒有可還原的項目';

  @override
  String get undoRevert => '取消還原';

  @override
  String get revertUndone => '已取消還原';

  @override
  String get systemBehavior => '系統行為';

  @override
  String get keepAwakeTitle => '代理執行時保持電腦喚醒';

  @override
  String get keepAwakeOnSubtitle => '代理工作時電腦不會睡眠';

  @override
  String get keepAwakeOffSubtitle => '即使代理正在工作，電腦仍可能睡眠';

  @override
  String get syncEngineSectionTitle => '同步引擎';

  @override
  String get syncEngineDescription =>
      '工單、訊息與筆記會以小型增量變更即時更新，而非完整快照。關閉某個切換開關會讓該儲存區退回完整快照模式—請重新載入應用程式以套用變更。';

  @override
  String get syncEngineTicketsTitle => '工單';

  @override
  String get syncEngineMessagingTitle => '訊息';

  @override
  String get syncEngineNotesTitle => '筆記';

  @override
  String get syncEngineOnSubtitle => '即時差異同步已啟用';

  @override
  String get syncEngineOffSubtitle => '使用完整快照同步';

  @override
  String get spaces => '空間';

  @override
  String get spacesHomeDescription => '從清單中選擇一個空間，或建立新的。';

  @override
  String get noSpacesYet => '尚無空間';

  @override
  String get newSpace => '新增空間';

  @override
  String get spaceName => '空間名稱';

  @override
  String get spaceReposHint => '要包含的儲存庫';

  @override
  String get ideSourceControl => '原始檔控制';

  @override
  String get stagedChanges => '已暫存的變更';

  @override
  String get changes => '變更';

  @override
  String get stageFile => '暫存';

  @override
  String get unstageFile => '取消暫存';

  @override
  String get stageAll => '暫存所有變更';

  @override
  String get unstageAll => '全部取消暫存';

  @override
  String get stageChangesToCommit => '暫存要提交的變更';

  @override
  String get syncToPrHead => '拉取最新 PR commit';

  @override
  String get syncedToPrHead => '已同步至最新的 PR commit';

  @override
  String get syncPrHeadDirty => '同步前請先提交或捨棄你的變更';

  @override
  String get syncPrHeadFailed => '無法同步至 PR head';

  @override
  String get spaceLabel => '空間';

  @override
  String get keybindingNewSpace => '新增空間';

  @override
  String get keybindingCreateANewSpaceDescription => '建立新的空間';

  @override
  String get jumpToLatest => '跳到最新';

  @override
  String get streaming => '串流中';

  @override
  String get newMessages => '新';

  @override
  String get copyLink => '複製連結';

  @override
  String get linkCopied => '已複製連結';

  @override
  String get agentResponding => '代理回應中';

  @override
  String get agentFinished => '代理已完成';

  @override
  String get harnessConnectProviderForModels => '連接供應商以查看模型。';

  @override
  String get providerSignOut => '登出';

  @override
  String get providerWaitingForDeviceCode => '等待你在瀏覽器中確認代碼…';

  @override
  String get providerDeviceCodeHint => '請確認此代碼與瀏覽器中顯示的一致，然後核准。';

  @override
  String get providerPlanUsageLoading => '正在檢查方案用量…';

  @override
  String get providerPlanUsageUnavailable => '此方案未回報用量。';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return '要移除 $provider 的 API 金鑰嗎？';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return '已儲存的金鑰會被刪除且無法再次顯示。使用 $provider 模型的代理會停止運作，直到你貼上新的金鑰為止。';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return '要移除 $provider 嗎？';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return '供應商及其儲存的金鑰會被刪除。釘選在其模型上的代理會停止運作。';
  }

  @override
  String get providerApiKeyHint => '貼上 API 金鑰';

  @override
  String get providerApiKeyStoredHint => '貼上另一個 API 金鑰以新增';

  @override
  String get providerAddAnotherAccount => '新增其他帳戶';

  @override
  String get providerActiveBadge => '使用中';

  @override
  String get providerOauthAccountFallback => 'OAuth 帳戶';

  @override
  String get providerApiKeyFallback => 'API 金鑰';

  @override
  String get providerRemoveCredentialConfirmTitle => '要移除此憑證嗎？';

  @override
  String get providerSignOutAccountConfirmTitle => '要登出此帳戶嗎？';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return '使用 $provider 的代理會改用它的其他金鑰與帳戶。若一個都不剩，代理會停止，直到你新增為止。';
  }

  @override
  String get providerBaseUrlHint => 'Base URL（選填）';

  @override
  String get addProvider => '新增供應商';

  @override
  String get noCustomProviders => '尚無自訂供應商。';

  @override
  String get providerNameLabel => '名稱';

  @override
  String get apiTypeLabel => 'API 類型';

  @override
  String get providerBaseUrlLabel => 'Base URL';

  @override
  String get providerApiKeyOptionalHint => 'API 金鑰（選填）';

  @override
  String get dialectOpenAiCompatible => 'OpenAI 相容';

  @override
  String get dialectAnthropicCompatible => 'Anthropic 相容';

  @override
  String get removeProviderTooltip => '移除供應商';

  @override
  String get providerLogInWithBrowser => '使用瀏覽器登入';

  @override
  String providerLoginDialogTitle(String provider) {
    return '登入 $provider';
  }

  @override
  String get providerLabel => '供應商';

  @override
  String get selectProviderToLogin => '選擇要登入的供應商';

  @override
  String providerLoginFailed(String error) {
    return '登入失敗：$error';
  }

  @override
  String get providerWaitingForBrowser => '等待你在瀏覽器中授權…';

  @override
  String get providerPasteCodeHint => '或貼上你瀏覽器中的代碼';

  @override
  String get providerCompleteLogin => '完成';

  @override
  String get providerConnectedApiKey => '已透過 API 金鑰連線';

  @override
  String get providerConnectedOauth => '已連線';

  @override
  String providerConnectedAccount(String account) {
    return '已連線 · $account';
  }

  @override
  String get providerLocalReady => '本機 · 就緒';

  @override
  String get providerNotConnected => '未連線';

  @override
  String get preparingWorkspace => '正在準備工作區…';

  @override
  String provisioningRunningSetupScript(String repo) {
    return '正在為 $repo 執行設定指令碼…';
  }

  @override
  String get repoScriptsTitle => '指令碼';

  @override
  String get repoScriptsTooltip => '設定生命週期指令碼';

  @override
  String get repoScriptsSetupLabel => '設定指令碼';

  @override
  String get repoScriptsSetupHelp =>
      '在空間的工作樹建立後立即於其中執行—安裝相依套件、產生檔案。失敗會將空間標記為失敗；重試會再次執行。';

  @override
  String get repoScriptsArchiveLabel => '封存指令碼';

  @override
  String get repoScriptsArchiveHelp => '在空間的工作樹刪除前執行—清理工作樹以外的資源。失敗不會阻擋刪除。';

  @override
  String get repoScriptsEnvHelp =>
      '從工作樹透過 bash 執行，並設定 CC_WORKSPACE_PATH（工作樹）、CC_ROOT_PATH（儲存庫根目錄）、CC_SPACE_ID、CC_SPACE_NAME 與 CC_REPO_NAME。';

  @override
  String get repoScriptsSetupPlaceholder => '例如 pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      '例如 docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => '最近的執行';

  @override
  String get repoScriptsNoRuns => '尚無執行記錄';

  @override
  String get repoScriptsSaved => '指令碼已儲存';

  @override
  String get repoScriptsRunKindSetup => '設定';

  @override
  String get repoScriptsRunKindArchive => '封存';

  @override
  String get repoScriptsRunStatusRunning => '執行中';

  @override
  String get repoScriptsRunStatusSucceeded => '已成功';

  @override
  String get repoScriptsRunStatusFailed => '失敗';

  @override
  String get repoScriptsRunStatusTimedOut => '逾時';

  @override
  String repoScriptsExitCode(int code) {
    return '結束代碼 $code';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return '正在複製 $repo…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return '正在簽出 $repo 中的 pull request…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return '正在設定代理 $agent…';
  }

  @override
  String get workspacePrepFailed => '工作區設定失敗';

  @override
  String get workspacePrepStopped => '工作區設定已停止';

  @override
  String get stopWorkspacePrep => '停止準備';

  @override
  String get stopWorkspacePrepTooltip => '停止準備此工作區';

  @override
  String get stopWorkspacePrepConfirm => '要停止準備此工作區嗎？進行中的複製將被捨棄—你可以從這裡再次開始。';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count 則訊息將於就緒時送出';
  }

  @override
  String get membersNav => '成員';

  @override
  String get membersSettingsDescription => '可存取此工作區的人員：名冊、邀請與稽核軌跡';

  @override
  String get memberRosterLabel => '成員名冊';

  @override
  String get memberRepoAccessAction => '儲存庫存取權';

  @override
  String memberRepoAccessTitle(String name) {
    return '$name 的儲存庫存取權';
  }

  @override
  String get roleOwner => '擁有者';

  @override
  String get roleAdmin => '管理員';

  @override
  String get roleMember => '成員';

  @override
  String get roleViewer => '檢視者';

  @override
  String get roleGuest => '訪客';

  @override
  String get removeMemberTitle => '移除成員';

  @override
  String removeMemberConfirm(String name) {
    return '要將 $name 從此工作區移除嗎？對方會立即失去存取權。';
  }

  @override
  String get transferOwnershipAction => '轉移擁有權';

  @override
  String get transferOwnershipTitle => '轉移擁有權';

  @override
  String transferOwnershipConfirm(String name) {
    return '要讓 $name 成為此工作區的擁有者嗎？你將成為管理員。只有擁有者能刪除工作區或變更其他管理員的角色。';
  }

  @override
  String get transferOwnershipCta => '轉移';

  @override
  String get auditTrailLabel => '授權稽核軌跡';

  @override
  String get auditTrailDescription => '每一次允許與拒絕都以雜湊鏈串連，任何遭到修改或刪除的項目皆可偵測。';

  @override
  String get auditVerifyChain => '驗證鏈';

  @override
  String auditChainIntact(int count) {
    return '鏈完整—已驗證 $count 個項目';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return '鏈在第 $seq 個項目中斷：$reason';
  }

  @override
  String get auditEmpty => '尚無決策記錄。';

  @override
  String get auditDenied => '已拒絕';

  @override
  String get auditAllowed => '已允許';

  @override
  String auditOnBehalfOf(String user) {
    return '為 $user';
  }

  @override
  String get policyTemplatesLabel => '政策範本';

  @override
  String get policyTemplatesDescription => '套用一個起始態勢，或在工作區之間搬移。';

  @override
  String get policyTemplateStrict => '嚴格';

  @override
  String get policyTemplateBalanced => '平衡';

  @override
  String get policyTemplatePermissive => '寬鬆';

  @override
  String get policyTemplateApply => '套用';

  @override
  String policyTemplateApplied(int count) {
    return '已套用 $count 條規則';
  }

  @override
  String get policyExport => '複製政策';

  @override
  String get policyExported => '政策已複製到剪貼簿';

  @override
  String get policyImport => '貼上政策';

  @override
  String policyImported(int count) {
    return '已匯入 $count 條規則';
  }

  @override
  String get approveAndRemember => '核准 8 小時';

  @override
  String get approveAndRememberTooltip =>
      '核准此動作，並在此空間中 8 小時內不再詢問類似的動作。時間到會自動失效。';

  @override
  String get unknownUserLabel => '未知使用者';

  @override
  String get inviteMember => '邀請成員';

  @override
  String get inviteRepoAccessHeader => '儲存庫存取權';

  @override
  String get inviteRepoAccessExplainer => '只有你勾選的儲存庫會以你選擇的層級與受邀者共用。其他一切保持隱藏。';

  @override
  String get grantLevelRead => '讀取';

  @override
  String get grantLevelReview => '檢閱';

  @override
  String get grantLevelWrite => '寫入';

  @override
  String get inviteExpiryLabel => '有效期間';

  @override
  String get expiryOneDay => '1 天';

  @override
  String get expirySevenDays => '7 天';

  @override
  String get expiryThirtyDays => '30 天';

  @override
  String get createInviteAction => '建立邀請';

  @override
  String get inviteOneTimeCodeLabel => '單次代碼';

  @override
  String get inviteCodeShownOnce => '此代碼只會顯示一次，請立即複製。';

  @override
  String get inviteLinkLabel => '邀請連結';

  @override
  String get inviteRedeemHint => '將代碼分享給受邀者，對方可憑它在你的伺服器網址兌換。';

  @override
  String get inviteScanQr => '或掃描兌換';

  @override
  String get inviteLoopbackWarningTitle => '邀請指向本機位址';

  @override
  String get inviteLoopbackWarningBody =>
      '其他機器上的協作者將無法連上這部伺服器。請啟用通道（設定 → 整合 → 分享此伺服器），或繫結到你的網路，讓外部使用者可以連線。';

  @override
  String get inviteStatusOpen => '待使用';

  @override
  String get inviteStatusUsed => '已使用';

  @override
  String get inviteStatusRevoked => '已撤銷';

  @override
  String get inviteStatusExpired => '已過期';

  @override
  String inviteCreatedTime(String time) {
    return '建立於 $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return '於 $date 到期';
  }

  @override
  String get noActivityYet => '尚無活動';

  @override
  String get couldNotLoadMembers => '無法載入成員';

  @override
  String get couldNotLoadInvites => '無法載入邀請';

  @override
  String get couldNotLoadActivity => '無法載入活動';

  @override
  String get yourDevices => '你的裝置';

  @override
  String get yourDevicesDescription => '在此伺服器上與你帳戶配對的用戶端。';

  @override
  String get noOwnDevices => '尚無裝置與你的帳戶配對';

  @override
  String get renameDeviceTitle => '重新命名裝置';

  @override
  String get revokeDeviceTitle => '撤銷裝置';

  @override
  String revokeDeviceConfirm(String label) {
    return '要撤銷 $label 嗎？它會立即中斷連線，且無法再存取此伺服器。';
  }

  @override
  String devicePairedTime(String time) {
    return '配對於 $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return '最後上線於 $time';
  }

  @override
  String get deviceNeverSeen => '從未連線';

  @override
  String get profileSectionLabel => '個人資料';

  @override
  String get profileSectionDescription =>
      '你在此工作區對同事和 git 提交作者資訊中的顯示方式。空白欄位繼承帳戶的名稱和電子郵件。';

  @override
  String get displayNameLabel => '顯示名稱';

  @override
  String get emailLabel => '電子郵件';

  @override
  String get gitAuthorNameLabel => 'Git 作者名稱';

  @override
  String get gitAuthorEmailLabel => 'Git 作者電子郵件';

  @override
  String get profileSaved => '個人資料已儲存';

  @override
  String get presenceOnline => '線上';

  @override
  String get presenceIdle => '閒置';

  @override
  String get presenceTyping => '輸入中…';

  @override
  String get presenceAgentThinking => '思考中';

  @override
  String get presenceAgentRunning => '執行中';

  @override
  String get presenceAgentBlocked => '已封鎖';

  @override
  String get presenceAgentDone => '完成';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status（$cost）';
  }

  @override
  String get presenceRailLabel => '線上人員';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => '開啟請勿打擾';

  @override
  String get dndTooltipOff => '關閉請勿打擾';

  @override
  String get startPresenting => '開始簡報';

  @override
  String get stopPresenting => '結束簡報';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name 正在簡報';
  }

  @override
  String get spotlightLeave => '離開';

  @override
  String typingIndicator(String name) {
    return '$name 正在輸入…';
  }

  @override
  String get ideTabNotes => '筆記';

  @override
  String get ideSidebarAllViews => '所有檢視';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return '所有檢視（已隱藏 $count 個）';
  }

  @override
  String get ideSidebarPinView => '釘選到側邊欄';

  @override
  String get ideSidebarUnpinView => '從側邊欄取消釘選';

  @override
  String get notesEmptyHint => '為接手此對話的人新增筆記…';

  @override
  String get notesEditTooltip => '編輯筆記';

  @override
  String notesUpdatedBy(String name, String time) {
    return '由 $name 更新 · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name 正在編輯';
  }

  @override
  String get notesSaveFailed => '無法儲存筆記';

  @override
  String get reactionAddTooltip => '新增反應';

  @override
  String reactionToggleTooltip(String emoji) {
    return '以 $emoji 回應';
  }

  @override
  String get autonomyDialLabel => '自主程度';

  @override
  String get autonomyProposeOnly => '僅提出建議';

  @override
  String get autonomyActWithApproval => '經核准後行動';

  @override
  String get autonomyActFreely => '自由行動';

  @override
  String get autonomyDefaultOption => '預設';

  @override
  String get checkerLabel => '檢查者';

  @override
  String get checkerNone => '無';

  @override
  String get checkerCaption => '檢查者會檢閱其他代理已完成的執行。';

  @override
  String get takeoverTooltip => '接管工作樹';

  @override
  String get takeoverBannerSelf => '你已接管此對話的工作樹';

  @override
  String takeoverBannerOther(String name) {
    return '$name 已接管此對話的工作樹';
  }

  @override
  String get handBackButton => '交還';

  @override
  String get handBackDialogTitle => '交還工作樹';

  @override
  String get handBackDialogNoteHint => '給代理的選填備註…';

  @override
  String takeoverFailed(String message) {
    return '無法接管：$message';
  }

  @override
  String handBackFailed(String message) {
    return '無法交還：$message';
  }

  @override
  String get planStudioTitle => 'Plan Studio';

  @override
  String get plansTitle => '計畫';

  @override
  String get plansSubtitle => '進行中的計畫、計畫文件與 playbook';

  @override
  String get plansActiveSection => '進行中的計畫';

  @override
  String get plansDocumentsSection => '計畫文件';

  @override
  String get plansPlaybooksSection => 'Playbook';

  @override
  String get plansNoActive => '尚無進行中的計畫。';

  @override
  String get plansNoDocuments => '尚無計畫文件。';

  @override
  String get plansNoPlaybooks => '尚無 playbook。';

  @override
  String get planNotFound => '找不到計畫。';

  @override
  String get planOpenInStudio => '開啟';

  @override
  String get planNodeTitle => '標題';

  @override
  String get planNodeDescription => '描述';

  @override
  String get planNodeDescriptionHint => '此步驟應該做什麼…';

  @override
  String get planNodeApplyDescription => '套用';

  @override
  String get planNodeRole => '角色';

  @override
  String get planNodeDependencies => '相依於';

  @override
  String get planNodeDependenciesHint => '新增相依項';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個相依項',
      one: '1 個相依項',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies => '沒有相依項，因此計畫一開始就會執行';

  @override
  String get planNodeOutputSchema => '輸出結構描述 (JSON)';

  @override
  String get planNodeEstimate => '預估';

  @override
  String get planNodeProvenance => '出處';

  @override
  String get planNodeAlreadyExecuted => '已執行——編輯會從此處分叉出計畫的新版本。';

  @override
  String get planNewNodeTitle => '新步驟';

  @override
  String get planEstimateNoHistory => '尚無歷史紀錄';

  @override
  String get planEstimateBlastUnknown => '影響範圍：未知';

  @override
  String get planEstimatePartial => '部分';

  @override
  String get planEstimateAction => '預估';

  @override
  String planEstimateDuration(String range) {
    return '所需時間 $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return '影響範圍：$files 個檔案、$symbols 個符號';
  }

  @override
  String get planApprove => '核准計畫';

  @override
  String get planApproveSelectedNodes => '核准所選';

  @override
  String get planReject => '拒絕';

  @override
  String get planCancel => '取消執行';

  @override
  String get planContinueNode => '繼續節點';

  @override
  String get planTotalNotEstimated => '尚未預估';

  @override
  String get planBudgetExceeded => '已超出預算';

  @override
  String planBudgetCeiling(String amount) {
    return '預算 ≤ \$$amount';
  }

  @override
  String get planVersionsTitle => '版本';

  @override
  String get planNoRevisions => '尚無修訂版本。';

  @override
  String get planDiffIdentical => '沒有變更。';

  @override
  String get planDiffGoalChanged => '目標已變更';

  @override
  String get planDiffBudgetChanged => '預算已變更';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'v$fromRev 到 v$toRev 之間的變更';
  }

  @override
  String planDiffAdded(String node) {
    return '已新增 $node';
  }

  @override
  String planDiffRemoved(String node) {
    return '已移除 $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return '已變更 $node：$fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return '已新增邊：$edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return '已移除邊：$edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return '已新增角色：$role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return '已移除角色：$role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return '角色已重新指派：$role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return '計畫已重新規劃：你核准的是 v$approved，現在是 v$current。請在它繼續之前檢閱差異。';
  }

  @override
  String planLiveActualCost(String amount) {
    return '實際成本：\$$amount';
  }

  @override
  String get planPlaybookRun => '執行';

  @override
  String get planPlaybookDelete => '刪除 playbook';

  @override
  String get planPlaybookProposed => '已提出計畫——請在 Plan Studio 核准。';

  @override
  String get planPlaybookAnchorTicket => '錨定工單';

  @override
  String get planPlaybookPickTicket => '選擇一張工單…';

  @override
  String get planPlaybookProposeRun => '提出計畫';

  @override
  String get planPlaybookRepoHint => '儲存庫 id';

  @override
  String get planPlaybookAgentHint => '代理 id';

  @override
  String planPlaybookRunTitle(String name) {
    return '執行 $name';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count 個參數';
  }

  @override
  String get recentLabel => '最近';

  @override
  String get cheatSheetTitle => '鍵盤快速鍵';

  @override
  String get cheatSheetGlobal => '全域';

  @override
  String get cheatSheetThisScreen => '此畫面';

  @override
  String get cheatSheetReservedInBrowser => '瀏覽器保留';

  @override
  String get keybindingCheatSheet => '鍵盤快速鍵';

  @override
  String get keybindingShowKeyboardShortcutsDescription => '顯示目前畫面的鍵盤快速鍵小抄';

  @override
  String get runPlaybookLabel => '執行 playbook';

  @override
  String get playbooksLabel => 'Playbook';

  @override
  String get keybindingUndo => '復原';

  @override
  String get keybindingRedo => '重做';

  @override
  String get keybindingUndoLastActionDescription => '復原上一個可復原的動作';

  @override
  String get keybindingRedoLastActionDescription => '重做上一個已復原的動作';

  @override
  String get undone => '已復原';

  @override
  String get redone => '已重做';

  @override
  String get undoFailed => '無法復原';

  @override
  String get undoLabelTicketEdit => '工單編輯';

  @override
  String get undoLabelMessageEdit => '訊息編輯';

  @override
  String get undoLabelTodoStatus => '待辦狀態';

  @override
  String get inboxTitle => '收件匣';

  @override
  String get inboxReview => '檢閱';

  @override
  String get inboxOpen => '開啟';

  @override
  String get inboxAllCaughtUp => '所有項目都處理完畢了';

  @override
  String get inboxGitHubDownTitle => 'GitHub 可能發生故障';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub 回報的狀態為 $status，因此 pull request 可能只是未出現在此清單中，而不是真的完成了。';
  }

  @override
  String get inboxGitHubIdentityTitle => '無法確認你的 GitHub 帳戶';

  @override
  String get inboxGitHubIdentityBody =>
      '收件匣會依你在 GitHub 上的身分排序。在它載入完成前會保持空白，即使有 pull request 正等著你。';

  @override
  String get inboxSeverityBlocking => '已封鎖';

  @override
  String get inboxSeverityWaiting => '等待中';

  @override
  String get inboxSeverityInfo => '資訊';

  @override
  String get inboxSyncFailed => '同步失敗';

  @override
  String get inboxNeedsYourAttention => '需要你的注意';

  @override
  String get inboxSectionNeedsYourReview => '需要你檢閱';

  @override
  String get inboxSectionReturnedToYou => '退回給你';

  @override
  String get inboxSectionApproved => '已核准';

  @override
  String get inboxSectionDrafts => '草稿';

  @override
  String get inboxSectionWaitingForReviewers => '等待檢閱者';

  @override
  String get inboxSectionMergingAndMerged => '合併中與最近合併';

  @override
  String get inboxSectionWaitingForAuthor => '等待作者';

  @override
  String get inboxColumnTitle => '標題';

  @override
  String get inboxColumnChanges => '變更';

  @override
  String get inboxColumnUpdated => '更新';

  @override
  String get inboxReviewApproved => '已核准';

  @override
  String get inboxReviewChangesRequested => '已要求變更';

  @override
  String get inboxHeroSubtitle => '所有與你相關的 pull request，依下一步動作排序。';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個 pull request 需要你檢閱',
      one: '1 個 pull request 需要你檢閱',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個退回給你',
      one: '1 個退回給你',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted => '該變更未儲存，已還原';

  @override
  String get offlinePendingLabel => '待處理';

  @override
  String get offlineSyncingLabel => '同步中';

  @override
  String get copyLinkLabel => '複製此頁面的連結';

  @override
  String get agentsSectionLabel => '代理';

  @override
  String get fleetWorkersTitle => '工作節點';

  @override
  String get fleetWorkersSubtitle => '可用於執行作業的機器';

  @override
  String get fleetJobsTitle => '作業';

  @override
  String get fleetJobsSubtitle => '分散到整個機群的工作';

  @override
  String get fleetNoWorkers =>
      '尚無工作節點——在另一台機器上執行 `cc_worker --server <url>` 即可加入機群。';

  @override
  String get fleetNoJobs => '沒有作業。';

  @override
  String get fleetError => '無法載入機群';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個核心',
      one: '1 個核心',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return '心跳 $time';
  }

  @override
  String get fleetNoHeartbeat => '尚無心跳';

  @override
  String fleetLastErrorLabel(String error) {
    return '最後錯誤：$error';
  }

  @override
  String get fleetDrain => '清空';

  @override
  String get fleetResume => '恢復';

  @override
  String get fleetRevoke => '撤銷';

  @override
  String get fleetRemove => '移除';

  @override
  String get fleetRevokeTitle => '要撤銷工作節點嗎？';

  @override
  String fleetRevokeBody(String name) {
    return '要撤銷 $name 嗎？其工作階段將結束，進行中的作業會被重新指派。';
  }

  @override
  String get fleetRemoveTitle => '要移除工作節點嗎？';

  @override
  String fleetRemoveBody(String name) {
    return '要將 $name 從機群移除嗎？這會刪除其紀錄。';
  }

  @override
  String get fleetActionFailed => '動作失敗';

  @override
  String get fleetJobUnassigned => '未指派';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max 次嘗試';
  }

  @override
  String get fleetPlacementReasons => '放置決策';

  @override
  String get fleetNoPlacements => '尚無放置決策。';

  @override
  String get fleetStatusOnline => '線上';

  @override
  String get fleetStatusDraining => '清空中';

  @override
  String get fleetStatusOffline => '離線';

  @override
  String get fleetStatusIncompatible => '不相容';

  @override
  String get fleetStatusRevoked => '已撤銷';

  @override
  String get fleetJobStatusQueued => '排隊中';

  @override
  String get fleetJobStatusRunning => '執行中';

  @override
  String get fleetJobStatusSucceeded => '成功';

  @override
  String get fleetJobStatusFailed => '失敗';

  @override
  String get fleetJobStatusCancelled => '已取消';

  @override
  String get evalsNoSuites => '尚無評測套件。';

  @override
  String get evalsError => '無法載入評測';

  @override
  String get evalsStarterBadge => '入門';

  @override
  String evalsDefaultBatch(int count) {
    return '預設批次 $count';
  }

  @override
  String get evalsRecentRuns => '最近的執行';

  @override
  String get evalsNoRuns => '尚無執行紀錄。';

  @override
  String get evalsPassRate => '通過率';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return '由 $who 觸發';
  }

  @override
  String evalsRunFinished(String rate) {
    return '評測完成——$rate 通過';
  }

  @override
  String get evalsRunFailed => '無法執行套件';

  @override
  String get evalsRun => '執行';

  @override
  String get evalsStatusQueued => '排隊中';

  @override
  String get evalsStatusRunning => '執行中';

  @override
  String get evalsStatusPassed => '已通過';

  @override
  String get evalsStatusFailed => '失敗';

  @override
  String get bannerMeetingJoin => '加入';

  @override
  String get bannerMeetingRecordAndLink => '錄製並連結';

  @override
  String get bannerCalendarReconnect => '重新連線';

  @override
  String get bannerView => '檢視';

  @override
  String get soundscapeTitle => '聲景';

  @override
  String get soundscapePlay => '播放';

  @override
  String get soundscapePause => '暫停';

  @override
  String get soundscapeMoodLabel => '情境';

  @override
  String get soundscapeMoodFocus => '專注';

  @override
  String get soundscapeMoodRelax => '放鬆';

  @override
  String get soundscapeMoodSleep => '睡眠';

  @override
  String get soundscapeMoodRise => '上升';

  @override
  String get soundscapeVolumeLabel => '音量';

  @override
  String get soundscapeTuneLabel => '調性';

  @override
  String get soundscapeTuneMellow => '柔和';

  @override
  String get soundscapeTuneBright => '明亮';

  @override
  String get soundscapeTuneEnergetic => '活力';

  @override
  String get soundscapeTuneSpacy => '空靈';

  @override
  String get soundscapeTuneResetHint => '雙擊以重設';

  @override
  String get soundscapeSceneLabel => '正在播放';

  @override
  String get soundscapeSceneLoading => '正在調整環境音…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees°C';
  }

  @override
  String get soundscapeLocationLabel => '位置';

  @override
  String get soundscapeLocationDetecting => '正在偵測位置…';

  @override
  String get soundscapeLocationAutoNote => '位置來自這部裝置。';

  @override
  String get soundscapeRefreshWeather => '重新整理天氣';

  @override
  String get soundscapeAutoStartLabel => '隨專注模式啟動';

  @override
  String get soundscapeAutoStartDescription => '開始專注階段時自動播放聲景。';

  @override
  String get soundscapeReturnToApp => '返回應用程式';

  @override
  String get soundscapePopOut => '彈出播放器';

  @override
  String get discussion => '討論';

  @override
  String get chat => '聊天';

  @override
  String get saving => '儲存中…';

  @override
  String get saved => '已儲存';

  @override
  String get saveFailed => '無法儲存';

  @override
  String get commitAndPush => '提交並推送';

  @override
  String get commit => '提交';

  @override
  String get commitAmend => '提交（修訂）';

  @override
  String get commitAndSync => '提交並同步';

  @override
  String get scmSyncChanges => '同步變更';

  @override
  String get scmPublishBranch => '發佈分支';

  @override
  String get scmSyncFailed => '同步失敗';

  @override
  String get scmSyncDirty => '同步前請提交或捨棄變更';

  @override
  String get scmSynced => '已同步';

  @override
  String get scmPushRefused => '推送被拒絕';

  @override
  String get scmPulledPushRefused => '已拉取，但推送被拒絕';

  @override
  String get scmPushRefusedHint => '遠端或鉤子拒絕了這次更新';

  @override
  String get scmSelectBranch => '選擇要取出的分支';

  @override
  String get scmCreateBranch => '建立新分支…';

  @override
  String get scmCreateBranchFrom => '從所選提交建立新分支…';

  @override
  String get scmCheckoutDetached => '分離 HEAD 取出…';

  @override
  String get scmBranchName => '分支名稱';

  @override
  String get scmCreateBranchTitle => '建立分支';

  @override
  String scmFromRef(String ref) {
    return '從 ⁨$ref⁩';
  }

  @override
  String get scmCheckoutFailed => '無法切換分支';

  @override
  String get scmCheckoutDirty => '切換分支前請提交或捨棄變更';

  @override
  String scmSwitchedToBranch(String branch) {
    return '已切換至 ⁨$branch⁩';
  }

  @override
  String scmDetachedAt(String ref) {
    return '已分離至 ⁨$ref⁩';
  }

  @override
  String get scmDetachedHead => '分離的 HEAD';

  @override
  String get scmNoBranches => '沒有相符的分支';

  @override
  String get scmBranches => '分支';

  @override
  String get scmRemoteBranches => '遠端分支';

  @override
  String get scmTags => '標籤';

  @override
  String get scmPickStartPoint => '選擇起點';

  @override
  String get scmSwitchBranch => '切換分支';

  @override
  String get scmPullConflictTitle => '拉取會產生衝突';

  @override
  String scmPullConflictBody(int count, String branch) {
    return '把 $count 個提交拉到 ⁨$branch⁩ 會和這份工作複本裡的改動衝突。';
  }

  @override
  String get scmAskAi => '讓 AI 處理';

  @override
  String scmResolveConflictPrompt(String branch, String repo, int count) {
    return '請拉取 ⁨$repo⁩ 裡的 ⁨$branch⁩。它比上游落後 $count 個提交，拉取會和本地改動衝突。請解決衝突並完成拉取。';
  }

  @override
  String commitMessageOnBranch(String shortcut, String branch) {
    return '訊息（$shortcut 提交到「$branch」）';
  }

  @override
  String get committed => '已提交';

  @override
  String get commitAmended => '已修訂提交';

  @override
  String get commitFailed => '提交失敗';

  @override
  String get moreCommitActions => '更多提交動作';

  @override
  String get sourceControl => '原始檔控制';

  @override
  String fixFindingTitle(String location) {
    return '修正：$location';
  }

  @override
  String get openInEditor => '在編輯器中開啟';

  @override
  String get regexTesterTitle => '測試正規表示式';

  @override
  String get regexTesterHint => '輸入範例';

  @override
  String get regexMatch => '符合';

  @override
  String get regexNoMatch => '不符合';

  @override
  String get regexInvalidPattern => '無效模式';

  @override
  String get symbolLookupNone => '索引或此拉取請求中沒有定義';

  @override
  String get symbolLookupInDiff => '在此拉取請求中找到';

  @override
  String get symbolLookupFromBase => '來自基礎簽出 — 此 PR 的工作樹尚未建立索引';

  @override
  String get symbolImplementations => '實作';

  @override
  String symbolCallersCount(int count) {
    return '$count 個呼叫端';
  }

  @override
  String get commitMessageHint => '提交訊息';

  @override
  String get pushedToPr => '已推送到 PR';

  @override
  String get pushFailed => '推送失敗';

  @override
  String get reviewFindings => '發現項';

  @override
  String get treeLabel => '樹';

  @override
  String get toggleFileTree => '顯示或隱藏檔案樹';

  @override
  String get diffViewSettings => '差異檢視設定';

  @override
  String get splitViewLabel => '並排';

  @override
  String get unifiedViewLabel => '整合';

  @override
  String get wrapLines => '自動換行';

  @override
  String get shiftClickSelectRange => '按住 Shift 點擊以選取範圍';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個檔案',
      one: '1 個檔案',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc 行';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return '小型 PR——$files，檢閱約需 $minutes 分鐘';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return '中型 PR——$files，請預留約 $minutes 分鐘檢閱';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return '大型 PR——$files，建議先拆分再送檢閱';
  }

  @override
  String get searchInFiles => '在檔案中搜尋';

  @override
  String get showFileList => '顯示檔案清單';

  @override
  String get searchInFilesHintField => '在檔案中搜尋…';

  @override
  String get searchInFilesHint => '搜尋整個 pull request 的檔案';

  @override
  String get searchInWholeRepo => '在整個儲存庫中搜尋';

  @override
  String get searchInThisPullRequest => '在此 pull request 中搜尋';

  @override
  String get searchNoResults => '找不到結果';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個結果',
      one: '1 個結果',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files 個檔案',
      one: '1 個檔案',
    );
    return '$_temp0，共 $_temp1';
  }

  @override
  String get discardChangesTitle => '要捨棄變更嗎？';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個檔案',
      one: '1 個檔案',
    );
    return '要將 $_temp0 捨棄回 HEAD 嗎？此動作無法復原。';
  }

  @override
  String get discardAll => '全部捨棄';

  @override
  String get discardFailed => '捨棄變更失敗';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個檔案',
      one: '1 個檔案',
    );
    return '已捨棄 $_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted 個檔案',
      one: '1 個檔案',
    );
    return '已捨棄 $_temp0；略過 $skipped 個（未追蹤）';
  }

  @override
  String get prWorktreeUnavailable => '工作區尚未就緒';

  @override
  String get prWorktreeUnavailableHint =>
      '準備 pull request 的檔案時失敗。請重新開啟 pull request 再試一次。';

  @override
  String get timestampRelativeLabel => '相對時間';

  @override
  String get timestampRawLabel => '時間戳記';

  @override
  String get copyTimestamp => '複製時間戳記';

  @override
  String get copiedTimestamp => '已複製時間戳記';

  @override
  String get previewDeployment => '預覽部署';

  @override
  String previewDeploymentTab(String site) {
    return '預覽：$site';
  }

  @override
  String get askForReview => '請求檢閱…';

  @override
  String get closePrsConfirmTitle => '要關閉 pull request 嗎？';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '要關閉 $count 個 pull request 嗎？',
      one: '要關閉 1 個 pull request 嗎？',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已關閉 $count 個 pull request',
      one: '已關閉 1 個 pull request',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已指派 $count 個 pull request',
      one: '已指派 1 個 pull request',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已在 $count 個 pull request 上請求檢閱',
      one: '已在 1 個 pull request 上請求檢閱',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個動作失敗',
      one: '1 個動作失敗',
    );
    return '$_temp0';
  }

  @override
  String get diagram => '圖表';

  @override
  String get diagramViewSource => '檢視原始碼';

  @override
  String get diagramHideSource => '隱藏原始碼';

  @override
  String diagramPreviewUnavailable(String reason) {
    return '圖表預覽無法使用（$reason）';
  }

  @override
  String get planUnavailable => '計畫無法使用';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個步驟',
      one: '1 個步驟',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => '核准並執行';

  @override
  String get planStatusDraft => '草稿';

  @override
  String get planStatusProposed => '計畫';

  @override
  String get planStatusApproved => '計畫已核准';

  @override
  String get planStatusRejected => '計畫已拒絕';

  @override
  String get planStatusSuperseded => '計畫已被取代';

  @override
  String planRevisionLabel(int revision) {
    return '修訂版 $revision';
  }

  @override
  String get adapterEnforcementTitle => '此轉接器強制執行的事項';

  @override
  String get enforcementFiltersToolSurface => '由 Control Center 挑選工具';

  @override
  String get enforcementInterceptsToolCalls => '每個呼叫都會在執行前經過閘門檢查';

  @override
  String get enforcementObservesCompletionContract => '執行必須兌現其交付成果';

  @override
  String get enforcementNativeToolsInterceptable => '執行器自身的工具是可見的';

  @override
  String get enforcementInProcessToolsSandboxed => '處理序內工具會在沙盒中執行';

  @override
  String get enforcementYes => '是';

  @override
  String get enforcementNo => '否';

  @override
  String get adapterEnforcementCaveats => '注意事項';

  @override
  String get enforcementSummaryModesEnforced => '模式已強制';

  @override
  String get enforcementSummaryModesNotEnforced => '模式未強制';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 項注意事項',
      one: '1 項注意事項',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      '唯讀模式並非結構性的：Control Center 無法移除此執行器自身的工具。';

  @override
  String get caveatToolCallsNotIntercepted =>
      '沒有執行前閘門：只有 MCP 工具呼叫會經過 Control Center。';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      '執行器自身的檔案與 shell 工具永遠不會經過 Control Center；OS 沙盒是它們唯一的安全底線。';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      '處理序內的檔案工具在沙盒外執行，因此工具面是唯一的檔案系統邊界。';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center 無法提醒或判定某個未產出交付成果就結束的執行為失敗。';

  @override
  String get modeDegraded => '已降級';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return '$adapter 上的 $mode 模式僅依賴沙盒；代理自身的檔案工具不會被攔截。';
  }

  @override
  String get artifactUnavailable => '成品無法使用';

  @override
  String artifactRevisionLabel(int count) {
    return '$count 個修訂版';
  }

  @override
  String get artifactShowMore => '顯示更多';

  @override
  String get artifactShowLess => '顯示較少';

  @override
  String get artifactCopy => '複製';

  @override
  String get artifactCopied => '已複製成品';

  @override
  String get artifactsTabLabel => '成品';

  @override
  String get artifactsEmptyTitle => '尚無成品';

  @override
  String get artifactsEmptyBody => '當代理在此發布表格、圖表或圖形時，它會出現在此清單中。';

  @override
  String get artifactRevisionPickerLabel => '修訂版';

  @override
  String get artifactRestoreRevision => '還原此修訂版';

  @override
  String get artifactOpenInTab => '在分頁中開啟';

  @override
  String get artifactTitleFallback => '成品';

  @override
  String get providerGenerationLabel => '生成預設值';

  @override
  String get providerGenerationHint =>
      '將欄位留空即可使用端點本身的預設值。模型會公布自身的輸出上限與取樣設定；以其他值供應模型可能使其效能下降。';

  @override
  String get providerMaxTokensLabel => '最大輸出 token 數';

  @override
  String get addModel => '新增模型';

  @override
  String get modelListTitle => '模型清單';

  @override
  String get railProvidersGroup => '供應商';

  @override
  String get railCustomProvidersGroup => '自訂供應商';

  @override
  String get editModelSettings => '編輯模型設定';

  @override
  String get modelIdLabel => '模型 ID';

  @override
  String get modelIdImmutableHint => '端點所供應的 id；一經列入即固定。';

  @override
  String get contextWindowLabel => '上下文視窗';

  @override
  String get inputTypesLabel => '輸入類型';

  @override
  String get outputTypesLabel => '輸出類型';

  @override
  String get modalityText => '文字';

  @override
  String get modalityImage => '影像';

  @override
  String get modalityAudio => '音訊';

  @override
  String get modalityVideo => '影片';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => '重設為自動';

  @override
  String get modelOverrideEdited => '已編輯';

  @override
  String get manualModelBadge => '手動新增';

  @override
  String get modelIdRequired => '請輸入模型 id。';

  @override
  String get modelTokensInvalid => '請輸入正整數的 token 數。';

  @override
  String get removeModelAction => '移除模型';

  @override
  String removeModelConfirmTitle(String model) {
    return '要移除 $model 嗎？';
  }

  @override
  String get removeModelConfirmBody => '該模型會離開清單，釘選它的代理將停止運作。供應商不受影響。';

  @override
  String get addModelProviderTitle => '新增模型供應商';

  @override
  String get addModelProviderDescription => '設定自訂 API 端點及其模型。';

  @override
  String get modelListEmptyHint => '尚未設定模型。新增模型後即可在聊天中使用。';

  @override
  String get addProviderModelsHint => '端點一旦回應，模型便會即時擷取。只有當它無法自行列出模型時，才需要手動新增。';

  @override
  String get providerTemperatureLabel => '溫度';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => '生成預設值已儲存';

  @override
  String get providerGenerationInvalid =>
      '請檢查數值：最大輸出 token 數與 top-k 必須為正數，溫度介於 0–2，top-p 介於 0–1。';

  @override
  String get providerGenerationOverridden => '已覆寫';

  @override
  String get branchNotPushed => '尚未推送';

  @override
  String branchNotOnRemote(String branch) {
    return '「$branch」只存在於此對話中';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub 從未見過此分支，因此 pull request 尚無法使用它。發布會推送工作樹中已有的提交——未提交的變更則保持原樣。';

  @override
  String get publishBranch => '發布分支';

  @override
  String branchPublished(String branch) {
    return '已將「$branch」發布至 origin';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return '分支已發布。$count 個未提交的變更未包含在內。';
  }

  @override
  String get composePrLoadingBranches => '正在從 GitHub 載入分支…';

  @override
  String get composePrBranchesFailed =>
      '無法從 GitHub 載入分支。請直接輸入分支名稱，或檢查 GitHub 連線。';

  @override
  String get composePrSubtitleFromSpace => '來自此對話的分支——若 GitHub 尚未見過它，請先發布';

  @override
  String get obsTabInsights => '洞察';

  @override
  String get obsTabLive => '即時';

  @override
  String get obsTabQuality => '品質';

  @override
  String get obsTabUsage => '用量';

  @override
  String get obsUsageTotalTokens => 'Token 總數';

  @override
  String get obsUsagePeakTokens => 'Token 峰值';

  @override
  String get obsUsageLongestSession => '最長工作階段';

  @override
  String get obsUsageCurrentStreak => '目前連續天數';

  @override
  String get obsUsageLongestStreak => '最長連續天數';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天',
      one: '1 天',
      zero: '0 天',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'Token 活動';

  @override
  String get obsUsageActivityModeLabel => 'Token 活動模式';

  @override
  String get obsUsageModeDaily => '每日';

  @override
  String get obsUsageModeWeekly => '每週';

  @override
  String get obsUsageModeCumulative => '累計';

  @override
  String get obsUsageTimeRange => '時間範圍';

  @override
  String get obsUsageTrendTitle => '每日 token 趨勢';

  @override
  String get obsUsageModelUsage => '模型用量';

  @override
  String get obsUsageTokensLabel => 'token';

  @override
  String get obsUsageNoActivity => '尚無 token 用量紀錄';

  @override
  String get obsUsageOtherModels => '其他';

  @override
  String obsUsageCellReadout(String date, String tokens) {
    return '$date · $tokens 個 token';
  }

  @override
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  ) {
    return '$start 至 $end 的 token 活動。活躍 $activeDays 天。單日高峰 $peak 個 token。';
  }

  @override
  String get obsScreenSubtitle => '即時代理控制、成本歸因、配額與品質訊號';

  @override
  String get obsRangeLast24h => '最近 24 小時';

  @override
  String get obsRangeLast7d => '最近 7 天';

  @override
  String get obsRangeLast30d => '最近 30 天';

  @override
  String get obsRangeAll => '所有時間';

  @override
  String get obsAddFilter => '新增篩選器';

  @override
  String get obsFilterAgent => '代理';

  @override
  String get obsFilterModel => '模型';

  @override
  String get obsFilterStatus => '狀態';

  @override
  String get obsFilterRole => '角色';

  @override
  String get obsKpiTotalRuns => '執行總數';

  @override
  String get obsKpiTotalCost => '總成本';

  @override
  String get obsKpiErrorRate => '錯誤率';

  @override
  String get obsKpiCacheRate => '快取率';

  @override
  String get obsKpiTokensPerSec => 'Token / 秒';

  @override
  String get obsKpiAvgLatency => '平均延遲';

  @override
  String get obsKpiTtft => '首 token 時間';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta（相較上一期）';
  }

  @override
  String get obsChartActivity => '活動';

  @override
  String get obsChartCost => '成本趨勢';

  @override
  String get obsLegendRuns => '執行';

  @override
  String get obsLegendErrors => '錯誤';

  @override
  String get obsAgentsTitle => '代理';

  @override
  String obsShowAllAgents(int count) {
    return '顯示全部 $count 個代理';
  }

  @override
  String get obsShowFewerAgents => '顯示較少';

  @override
  String get obsRunsTitle => '執行';

  @override
  String get obsNoRunsInRange => '此範圍內沒有執行紀錄';

  @override
  String get obsColTime => '時間';

  @override
  String get obsColAgent => '代理';

  @override
  String get obsColStatus => '狀態';

  @override
  String get obsColModel => '模型';

  @override
  String get obsColDuration => '持續時間';

  @override
  String get obsColTokens => 'Token';

  @override
  String get obsColCost => '成本';

  @override
  String get obsColErrors => '錯誤';

  @override
  String get obsColRuns => '執行';

  @override
  String get obsColAvgLatency => '平均延遲';

  @override
  String get obsColLastActive => '最後活動';

  @override
  String get obsStatusPending => '待處理';

  @override
  String get obsStatusRunning => '執行中';

  @override
  String get obsStatusCompleted => '已完成';

  @override
  String get obsStatusError => '錯誤';

  @override
  String get obsRosterLoadError => '無法載入代理名冊。';

  @override
  String get obsRosterEmpty => '尚無代理';

  @override
  String get obsRosterEmptyDescription =>
      '派出一個代理，它就會即時出現在這裡——狀態、目前工具、token、成本。';

  @override
  String get obsKillAgent => '終止代理';

  @override
  String get obsRosterTokensLabel => 'tok';

  @override
  String get obsCostByRoleTitle => '依角色的成本';

  @override
  String get obsCostByRoleSubtitle => '此工作區的支出分佈，依代理角色';

  @override
  String get obsRoleMain => '主代理';

  @override
  String get obsRoleSubagents => '子代理';

  @override
  String get obsRoleAdvisor => '顧問';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return '主代理：$main · 子代理：$sub · 顧問：$advisor';
  }

  @override
  String get obsTotal => '總計';

  @override
  String get obsTokenModelTitle => 'Token 模型（5 個軸）';

  @override
  String get obsTokenModelSubtitle => '此工作區花費的每個 token，依軸分類';

  @override
  String get obsAxisInput => '輸入';

  @override
  String get obsAxisOutput => '輸出';

  @override
  String get obsAxisReasoning => '推理';

  @override
  String get obsAxisCacheRead => '快取讀取';

  @override
  String get obsAxisCacheWrite => '快取寫入';

  @override
  String get obsTotalTokens => 'Token 總數';

  @override
  String get obsCacheDiscountNote => '快取讀取的 token 以折扣價計費，因此成本遠低於同量的全新輸入。';

  @override
  String get obsByModelTitle => '依模型';

  @override
  String get obsByModelSubtitle => '各模型的 token 與成本用量';

  @override
  String get obsNoModelUsage => '尚無模型用量紀錄。';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次執行',
      one: '1 次執行',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => '單次執行';

  @override
  String get obsPerRunSubtitle => '單次執行的一般 token 成本';

  @override
  String get obsMedianRunTokens => '執行的中位數 token';

  @override
  String get obsMedianRunTokensSub => '所有執行的中位數';

  @override
  String get obsRunsInWorkspace => '在此工作區中';

  @override
  String get obsCostShare => '成本佔比';

  @override
  String get obsQuotaConfiguredLimits => '已設定的上限';

  @override
  String get obsQuotaConfiguredLimitsSubtitle => '對照你所設上限的用量，狀態最差者在前。';

  @override
  String get obsQuotaAddLimit => '新增上限';

  @override
  String get obsQuotaNoLimits => '尚未設定配額上限——新增一個即可對照上限追蹤用量。';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return '移除 $title 上限';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return '將於 $duration 後重設 · $status';
  }

  @override
  String get obsQuotaUsageWindows => '用量時間窗';

  @override
  String get obsQuotaUsageWindowsSubtitle => '所有供應商的觀測用量，未套用上限。';

  @override
  String get obsQuotaNoUsage => '尚無用量紀錄。';

  @override
  String get obsQuotaTokensUsed => '已用 token';

  @override
  String get obsQuotaRequests => '請求數';

  @override
  String get obsQuotaUnitTokens => 'token';

  @override
  String get obsQuotaUnitRequests => '請求';

  @override
  String get obsQuotaUnitCost => '成本';

  @override
  String get obsQuotaAddLimitTitle => '新增配額上限';

  @override
  String get obsQuotaProviderLabel => '供應商';

  @override
  String get obsQuotaWindowLabel => '時間窗';

  @override
  String get obsQuotaUnitLabel => '單位';

  @override
  String obsQuotaLimitLabel(String unit) {
    return '上限（$unit）';
  }

  @override
  String get obsQuotaCentsHint => '以美分計（500 = \$5.00）。';

  @override
  String get obsQuotaStatusOk => '正常';

  @override
  String get obsQuotaStatusWarning => '警告';

  @override
  String get obsQuotaStatusExhausted => '已耗盡';

  @override
  String get obsQuotaStatusUnknown => '未知';

  @override
  String get obsGoalNoActiveTitle => '沒有進行中的目標';

  @override
  String get obsGoalNoActiveBody =>
      '設定目標可給代理一個目的及可選的 token 預算。隨著執行完成，預算會逐漸填滿；一旦快要耗盡，代理會被提醒收尾。';

  @override
  String get obsGoalSetGoal => '設定目標';

  @override
  String get obsGoalTokenBudget => 'Token 預算';

  @override
  String obsGoalTokensLeft(String tokens) {
    return '還剩 $tokens';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens（未設定預算）';
  }

  @override
  String get obsGoalTokensUsed => '已用 token';

  @override
  String get obsGoalElapsed => '已進行';

  @override
  String get obsGoalWrapUp => '收尾';

  @override
  String get obsGoalClear => '清除目標';

  @override
  String get obsGoalFallbackTitle => '目標';

  @override
  String get obsGoalSubtitle => '目標模式預算';

  @override
  String get obsGoalStatusActive => '進行中';

  @override
  String get obsGoalStatusPaused => '已暫停';

  @override
  String get obsGoalStatusBudgetLimited => '受預算限制';

  @override
  String get obsGoalStatusComplete => '已完成';

  @override
  String get obsGoalStatusDropped => '已放棄';

  @override
  String get obsGoalObjectiveLabel => '目的';

  @override
  String get obsGoalBudgetLabel => 'Token 預算（選填）';

  @override
  String get obsGoalSetAction => '設定目標';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => '成功率';

  @override
  String get obsBenchmarkPassed => '已通過';

  @override
  String get obsBenchmarkFailed => '失敗';

  @override
  String get obsBenchmarkErrors => '錯誤';

  @override
  String get obsBenchmarkSpend => '花費';

  @override
  String get obsBenchmarkCostPerTask => '成本 / 任務';

  @override
  String get obsBenchmarkTrials => '試驗';

  @override
  String get obsBenchmarkNoTrials => '尚無可評分的執行。';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '另有 $count 項',
      one: '另有 1 項',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => '通過';

  @override
  String get obsBenchmarkTrialFail => '失敗';

  @override
  String get obsBenchmarkTrialError => '錯誤';

  @override
  String get obsBenchmarkTrialRunning => '執行中';

  @override
  String get obsBenchmarkReward => '獎勵';

  @override
  String get obsBenchmarkReport => '報告';

  @override
  String get obsBenchmarkCopyMarkdown => '複製 markdown';

  @override
  String get obsBenchmarkCopied => '報告已複製到剪貼簿';

  @override
  String get obsBehaviorCaption =>
      '這些是從你自己的訊息解析出的挫折訊號——用來判讀對話健康度，而非代理的評分。在本機運算；沒有任何資料離開這部裝置。';

  @override
  String get obsBehaviorMessagesAnalyzed => '已分析的訊息';

  @override
  String get obsBehaviorTotalSignals => '訊號總數';

  @override
  String get obsBehaviorYelling => '咆哮';

  @override
  String get obsBehaviorProfanity => '粗話';

  @override
  String get obsBehaviorAnguish => '痛苦';

  @override
  String get obsBehaviorNegation => '否定';

  @override
  String get obsBehaviorRepetition => '重複';

  @override
  String get obsBehaviorBlame => '責怪';

  @override
  String get obsBehaviorConversationsTitle => '挫折感最高的對話';

  @override
  String get obsBehaviorConversationsSubtitle => '依你訊息中的訊號密度排序。';

  @override
  String get obsBehaviorNoSignals => '未偵測到挫折訊號——一切順利。';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '已分析 $count 則訊息';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count 個訊號';
  }

  @override
  String get obsAgentStatusIdle => '閒置';

  @override
  String get obsAgentStatusParked => '已停駐';

  @override
  String get obsAgentStatusAborted => '已中止';

  @override
  String get obsAgentKindSub => '子';

  @override
  String get noChecksOnCommit => '此提交尚未執行任何檢查。';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '執行中——$count 個作業',
      one: '執行中——1 個作業',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '所有檢查皆通過——$count 個作業',
      one: '所有檢查皆通過——1 個作業',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已完成——$count 個作業',
      one: '已完成——1 個作業',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total 個作業',
      one: '1 個作業',
    );
    return '$_temp0 中有 $failed 個失敗';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個作業',
      one: '1 個作業',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return '矩陣：$jobId';
  }

  @override
  String get jobLogsPending => '作業結束後，日誌會顯示在這裡。';

  @override
  String get jobLogsUnavailable => '此作業沒有可用的日誌。';

  @override
  String get noLogsForStep => '此步驟沒有擷取到日誌。';

  @override
  String get jobLogsTruncated => '日誌已截斷——僅顯示最近的輸出。';

  @override
  String get fullLog => '完整日誌';

  @override
  String get copyLogs => '複製日誌';

  @override
  String get resizeGraph => '拖曳以調整圖形大小';

  @override
  String workflowRunStartedAgo(String time) {
    return '開始於 $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return '完成於 $time';
  }

  @override
  String get chatBridgesTitle => '聊天橋接';

  @override
  String chatProviderDescription(String provider, String command) {
    return '在 $provider 中提及機器人即可派代理處理事情，或用 $command 建立工單。';
  }

  @override
  String chatConnectProvider(String provider) {
    return '連接 $provider';
  }

  @override
  String get chatDisconnectProvider => '中斷連線';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$teamName 中的 $botName';
  }

  @override
  String get chatStateLive => '已上線';

  @override
  String get chatStateConnecting => '連線中…';

  @override
  String get chatStateError => '連線錯誤';

  @override
  String get chatNotConnected => '未連線';

  @override
  String chatStreamingUnavailable(String provider) {
    return '此 $provider 應用程式已關閉即時串流——回覆會以單一訊息送達。';
  }

  @override
  String chatAdminOnly(String provider) {
    return '只有管理員能為此工作區連接 $provider。';
  }

  @override
  String chatConnectHint(String provider) {
    return '建立一個 $provider 應用程式，然後在這裡貼上其憑證。Control Center 會主動連出至 $provider，因此這部伺服器不需要公開位址。';
  }

  @override
  String chatOpenConsole(String provider) {
    return '開啟 $provider 主控台';
  }

  @override
  String get chatOpenSetupGuide => '設定指南';

  @override
  String get chatFieldBotToken => '機器人 token';

  @override
  String get chatFieldAppToken => '應用程式層級 token';

  @override
  String get chatFieldConfigRefreshToken => '應用程式設定 token';

  @override
  String chatFieldOptional(String label) {
    return '$label（選填）';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return '連結我的 $provider 帳戶';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return '連結你的 $provider 帳戶，讓你在那裡送出的訊息歸於你名下。';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return '已連結至 $externalUserId';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return '連結你的 $provider 帳戶';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return '在 $provider 中將此指令傳送給機器人。它只能使用一次，並在 15 分鐘後失效。';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return '你的 $provider 帳戶已連結——你在那裡送出的訊息會歸於你名下。';
  }

  @override
  String get chatLinkedAccounts => '已連結的帳戶';

  @override
  String chatNoLinkedAccounts(String provider) {
    return '尚無人連結其 $provider 帳戶。';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個已連結帳戶',
      one: '1 個已連結帳戶',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · 依電子郵件比對';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · 以代碼連結';
  }

  @override
  String get chatUnlink => '取消連結';

  @override
  String get chatCustomizeBot => '自訂機器人';

  @override
  String get chatCustomizeBotDescription => '重新命名機器人、變更它的自我介紹，或重新命名斜線指令。';

  @override
  String get chatCustomizeBotUnavailable =>
      'Control Center 需要應用程式設定 token 才能編輯機器人。請重新連線並一併提供。';

  @override
  String chatCreateAppTitle(String provider) {
    return '建立 $provider 應用程式';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center 可以代你建立 $provider 應用程式，並預先設好正確的權限與事件。你需要在 $provider 完成後續步驟，再將憑證貼到這裡。';
  }

  @override
  String get chatCreateApp => '建立應用程式';

  @override
  String get chatCreateAppCta => '幫我建立應用程式';

  @override
  String get chatAppNameLabel => '應用程式名稱';

  @override
  String get chatBotDisplayNameLabel => '機器人名稱（成員在 @ 後面輸入的名稱）';

  @override
  String get chatDescriptionLabel => '簡短描述';

  @override
  String get chatAgentDescriptionLabel => '機器人自述的能力';

  @override
  String get chatCommandLabel => '斜線指令';

  @override
  String get chatDirectMessages => '私訊';

  @override
  String chatDirectMessagesHint(String provider) {
    return '讓成員能在私訊中與機器人交談。可能需要 $provider 付費方案。';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$provider 已建立應用程式 $appId。';
  }

  @override
  String chatRemainingSteps(String provider) {
    return '還剩幾個步驟，只有 $provider 能完成：';
  }

  @override
  String get chatStepAppToken => '產生應用程式層級 token';

  @override
  String get chatStepInstall => '安裝應用程式';

  @override
  String get chatOpenAppSettings => '開啟應用程式設定';

  @override
  String get chatContinueToCredentials => '貼上憑證';

  @override
  String chatBotUpdated(String provider) {
    return '機器人已在 $provider 中更新。';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$provider 已變更應用程式的權限。請重新安裝應用程式才能生效。';
  }

  @override
  String get chatReinstallApp => '重新安裝應用程式';

  @override
  String chatIconNotEditable(String provider) {
    return '機器人圖示只能在 $provider 自身的應用程式設定中變更。';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return '你也可以自行在 $provider 中建立——不需要 token。上述設定會隨連結一併帶過去。';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return '在 $provider 中建立';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '$provider 已在你的瀏覽器中開啟並預填此設定。請在那裡建立應用程式，完成這些步驟後帶著 token 回來。';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider 不會回報它建立了哪個應用程式，因此之後需要應用程式設定 token 才能從這裡自訂機器人。';
  }

  @override
  String get chatStepCreateApp => '以預填的設定建立應用程式';

  @override
  String chatStepCreateAppHint(String provider) {
    return '在 $provider 中選擇一個工作區並確認。';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens，並勾選 connections:write 範圍。';

  @override
  String get chatStepInstallHint => 'Install app → 複製 bot user OAuth token。';

  @override
  String get calendarUseBuiltinApp => '使用 Control Center 的 Google 應用程式';

  @override
  String get calendarUseBuiltinAppHint =>
      '用你的 Google 帳戶核准即可。無需在 Google Cloud 做任何設定。';

  @override
  String get calendarUseOwnClient => '使用我自己的 Google Cloud 用戶端';

  @override
  String get calendarUseOwnClientHint => '輸入來自你自己 Google Cloud 專案的 OAuth 用戶端。';

  @override
  String get aboutTitle => '關於';

  @override
  String get aboutAppVersion => '應用程式版本';

  @override
  String get aboutServerVersion => '已連線的伺服器';

  @override
  String get aboutRpcCatalog => 'RPC 目錄';

  @override
  String get aboutServerUnknown => '未回報';

  @override
  String get serverStaleTitle => '內建伺服器比此應用程式舊';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return '執行中的 cc_server 為 $serverVersion，而此應用程式為 $appVersion。請重新啟動應用程式以取得最新的內建伺服器版本；開發時，請在 apps/cc_server 中以 `dart build cli` 重新建置。';
  }

  @override
  String get updateCheckButton => '檢查更新';

  @override
  String get updateChecking => '正在檢查更新…';

  @override
  String get updateUpToDate => '你已是最新版本';

  @override
  String get updateDeferredBusy => '已有可用更新，但會議正在錄製中——結束後會再提示。';

  @override
  String get updateOpenedReleasesPage => '已在你的瀏覽器中開啟版本發布頁面。';

  @override
  String get updateCheckFailed => '更新檢查失敗';

  @override
  String updateAvailableVersion(String version) {
    return '已有 $version 版本可用。';
  }

  @override
  String get updateBannerTitle => '有新的 Control Center 可用';

  @override
  String get updateBannerRefresh => '重新整理';

  @override
  String get updateBlockedRecording => '會議錄製期間會暫停重新整理——結束後會自動重新載入。';

  @override
  String get settingsScopeYou => '你';

  @override
  String get settingsScopeWorkspace => '工作區';

  @override
  String get settingsScopeServer => '伺服器';

  @override
  String get settingsProfile => '個人資料與身分';

  @override
  String get settingsYourDevices => '你的裝置';

  @override
  String get settingsWorkspaceGeneral => '一般';

  @override
  String get settingsServerConnection => '連線與狀態';

  @override
  String get settingsModelProviders => '模型供應商';

  @override
  String get settingsVoiceModels => '語音與會議模型';

  @override
  String get settingsDiagnostics => '診斷與隱私';

  @override
  String get settingsAbout => '關於';

  @override
  String get settingsScopeBadgeYou => '你';

  @override
  String get settingsScopeBadgeDevice => '此裝置';

  @override
  String get settingsScopeBadgeWorkspace => '工作區';

  @override
  String get settingsScopeBadgeServer => '伺服器';

  @override
  String get settingsProfileDescription =>
      '你在此工作區的名稱、電子郵件和 git 身分。切換工作區會切換此覆蓋層；帳號代號、登入與裝置仍在帳戶上。';

  @override
  String get settingsServerConnectionDescription =>
      '此用戶端連往哪部伺服器，以及這部伺服器如何分享（mDNS、通道、中繼）。';

  @override
  String get settingsAboutDescription => '建置資訊與更新。';

  @override
  String get settingsDiagnosticsDescription => '此安裝的隔離、索引、同步、日誌與當機回報。';

  @override
  String get settingsWorkspaceGeneralDescription => '此工作區中所有人共用的身分、政策與慣例。';

  @override
  String get settingsWorkspaceMeetingsDescription => '此工作區會議的筆記範本與已儲存的聲音。';

  @override
  String get settingsWorkspacePolicyLabel => '工作區政策';

  @override
  String get settingsWorkspacePolicyDescription => '適用於此工作區中的每個成員與每個代理。';

  @override
  String get settingsSecretGlobsLabel => '機密路徑排除';

  @override
  String get settingsSecretGlobsHelp =>
      '每行一個 glob。除了內建預設之外，這些路徑也會在含有程式碼的介面上對檢視者與訪客隱藏。';

  @override
  String get settingsReviewConcurrencyLabel => '檢閱分流數';

  @override
  String get settingsReviewConcurrencyHelp => '未明確指定數量時，要平行派出多少位檢閱者。';

  @override
  String get settingsReviewLevelLabel => '檢閱等級';

  @override
  String get settingsReviewLevelHelp =>
      'AI 檢閱的深入程度，以及一開始回報多少發現項。沒有任何項目會被丟棄——較輕的等級會將次要發現項分組，而不是直接省略。';

  @override
  String get reviewLevelLight => '輕量';

  @override
  String get reviewLevelBalanced => '均衡';

  @override
  String get reviewLevelThorough => '徹底';

  @override
  String get reviewLevelLightHint => '一位檢閱者。一開始只回報真正重要的項目。';

  @override
  String get reviewLevelBalancedHint => '三位檢閱者，涵蓋 QA、架構與實作。';

  @override
  String get reviewLevelThoroughHint => '加入安全性與效能專家，並回報所有發現。';

  @override
  String get askAiReviewAtLevel => '以不同等級檢閱';

  @override
  String reviewNitpicksGroup(int count) {
    return '細節挑剔（$count）';
  }

  @override
  String get reviewFindingResolve => '已修正';

  @override
  String get reviewFindingResolveHint => '將此發現項標記為已修正。它將不再計入此檢閱。';

  @override
  String get reviewFindingDismiss => '忽略';

  @override
  String get reviewFindingDismissHint => '不是真正的問題。檢閱者之後不會再在 PR 上標記此模式。';

  @override
  String get reviewFindingReopen => '重新開啟';

  @override
  String get reviewFindingStatusUndoLabel => '發現項狀態';

  @override
  String get reviewFindingDismissTitle => '忽略此發現項';

  @override
  String get reviewFindingDismissReasonHint => '為什麼這不適用？檢閱者會看到你的說明。';

  @override
  String reviewFindingStatusFailed(String error) {
    return '無法更新發現項：$error';
  }

  @override
  String get reviewStaleTitle => '此檢閱已過時';

  @override
  String get reviewStaleBody => '此檢閱執行後，pull request 已有新的進展。發現項可能指向已不存在的程式碼。';

  @override
  String reviewStaleReviewedAt(String sha) {
    return '檢閱於 $sha';
  }

  @override
  String get reviewStaleRerun => '再次檢閱';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return '#$prNumber 的檢閱已過時';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return '$title 自上次檢閱後有新的提交。';
  }

  @override
  String get reviewCategorySecurity => '安全性';

  @override
  String get reviewCategoryStability => '穩定性';

  @override
  String get reviewCategoryDataIntegrity => '資料完整性';

  @override
  String get reviewCategoryCorrectness => '正確性';

  @override
  String get reviewCategoryPerformance => '效能';

  @override
  String get reviewCategoryMaintainability => '可維護性';

  @override
  String get reviewEffortQuickWin => '快速見效';

  @override
  String get reviewEffortModerate => '中等';

  @override
  String get reviewEffortHeavyLift => '大工程';

  @override
  String get reviewProposedFix => '建議修正';

  @override
  String get reviewAiAgentPrompt => '給 AI 代理的提示詞';

  @override
  String get reviewCopyAiPrompt => '複製提示詞';

  @override
  String get settingsWorkspaceAdminOnly => '只有工作區管理員能變更這些設定。';

  @override
  String get chatMyAccountsTitle => '已連結的聊天帳戶';

  @override
  String get settingsServerSso => '單一登入';

  @override
  String get settingsServerSsoDescription => 'SAML 與 OpenID Connect 登入，含使用者佈建';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription => '使用者可以使用此供應商登入';

  @override
  String get ssoEnabledDescriptionOn => '此供應商的登入已上線';

  @override
  String get ssoIdpMetadataLabel => 'IdP 中繼資料 XML';

  @override
  String get ssoIdpMetadataHint => '貼上 IdP 的 EntityDescriptor XML';

  @override
  String get ssoEmailAttributeLabel => '電子郵件屬性';

  @override
  String get ssoDisplayNameAttributeLabel => '顯示名稱屬性';

  @override
  String get ssoGroupsAttributeLabel => '群組屬性';

  @override
  String get ssoIssuerLabel => '簽發者 URL';

  @override
  String get ssoClientIdLabel => '用戶端 ID';

  @override
  String get ssoGroupsClaimLabel => '群組宣告';

  @override
  String get ssoAutoMemberLabel => '首次登入時將使用者加入每個工作區';

  @override
  String get ssoAutoMemberDescription => '關閉後，每個工作區都需要個別邀請';

  @override
  String get ssoAllowJitLabel => '首次登入時佈建未知使用者';

  @override
  String get ssoAllowJitDescription => '關閉後，將拒絕沒有現有帳戶的使用者';

  @override
  String get ssoAllowIdpInitiatedLabel => '接受未經請求的（IdP 起始）登入';

  @override
  String get ssoAllowIdpInitiatedDescription => '專供直接啟動應用程式的 IdP 入口網站使用';

  @override
  String get ssoWantResponseSignedLabel => '要求簽署的回應封套';

  @override
  String get ssoWantResponseSignedDescription => '判斷提示簽章一律為必要';

  @override
  String get ssoTestConnectionButton => '測試連線';

  @override
  String get ssoTestConnectionOk => '連線正常：';

  @override
  String get ssoCopySpMetadata => '複製 SP 中繼資料';

  @override
  String get ssoCopySpMetadataDone => 'SP 中繼資料已複製到剪貼簿';

  @override
  String get ssoSavedToast => '單一登入設定已儲存';

  @override
  String get ssoUnavailable => '此伺服器未提供單一登入設定。請更新伺服器執行檔後再試一次。';

  @override
  String get ssoScimCardTitle => '使用者佈建（SCIM）';

  @override
  String get ssoScimDescription =>
      '將你身分識別供應商的 SCIM 連接器指向下方端點，並使用 bearer token。取消佈建會在幾秒內撤銷工作階段與工作區存取權。伺服器必須能讓 IdP 連到（通道或公開 URL）。';

  @override
  String get ssoScimEndpoint => 'SCIM 端點';

  @override
  String get ssoScimEndpointUnknownOrigin => '請先設定伺服器的公開 URL 或啟用通道';

  @override
  String get ssoScimRegenerate => '重新產生 token';

  @override
  String get ssoScimRegenerateConfirm =>
      '要產生新的 SCIM bearer token 嗎？先前的 token 會立即失效。';

  @override
  String get ssoScimTokenTitle => 'Bearer token';

  @override
  String get ssoScimTokenPresent => '已設定 token';

  @override
  String get ssoScimTokenAbsent => '尚無 token——產生一個即可啟用 SCIM';

  @override
  String get ssoScimTokenOnce => 'SCIM token（只顯示一次）';

  @override
  String ssoSignInWith(String provider) {
    return '以 $provider 登入';
  }

  @override
  String get ssoProbeFailed => '無法連上該伺服器進行單一登入';

  @override
  String get ssoOpensBrowser => '會開啟你的瀏覽器以完成登入';

  @override
  String get ssoWaitingForBrowser => '正在等待你的瀏覽器完成登入…';

  @override
  String get ssoBrowserOpenFailed => '無法開啟瀏覽器進行單一登入';

  @override
  String get ssoUseManualPairing => '改用邀請或配對金鑰登入';

  @override
  String get ssoHideManualPairing => '隱藏手動配對';

  @override
  String get ssoClientIdHint => '公開（PKCE）用戶端——不需要密碼';

  @override
  String get ssoClientSecretLabel => '用戶端密鑰（選填）';

  @override
  String get ssoClientSecretHintUnset => '僅機密式 IdP 用戶端需要';

  @override
  String get ssoClientSecretHintSet => '已儲存密鑰——留空即可保留';

  @override
  String get ssoPairingToggle => '允許手動配對（邀請代碼與配對金鑰）';

  @override
  String get ssoPairingToggleDescription =>
      '關閉後，加入將僅限單一登入——新裝置透過 SSO 登入加入；現有裝置不受影響';

  @override
  String get ssoPairConfirmTitle => '要連線到伺服器嗎？';

  @override
  String ssoPairConfirmBody(String server) {
    return '收到了 $server 的登入憑證，但此應用程式並未啟動任何登入。要連線到這部伺服器嗎？';
  }

  @override
  String get ssoPairConfirmConnect => '連線';

  @override
  String get ssoPairConfirmCancel => '忽略';

  @override
  String get forgeConnections => '程式碼託管';

  @override
  String get connect => '連線';

  @override
  String get disconnect => '中斷連線';

  @override
  String get notConnected => '未連線';

  @override
  String get checkingConnection => '正在檢查連線…';

  @override
  String get fromEnvironment => '來自環境變數';

  @override
  String forgeTokenTitle(String forge) {
    return '$forge token';
  }

  @override
  String get settingsAudio => '音訊';

  @override
  String get settingsAudioDescription => '麥克風、聽寫、會議偵測與聲景輸出。';

  @override
  String get audioDevicesSection => '音訊裝置';

  @override
  String get voiceInputBehaviorSection => '聽寫與會議';

  @override
  String get audioOutputDeviceTitle => '輸出裝置';

  @override
  String get audioOutputDefaultHint => '所有應用程式音效都會透過系統預設輸出播放。';

  @override
  String get audioOutputGone => '所選的輸出裝置已不再連接——在你選擇其他裝置前，將使用系統預設值。';

  @override
  String get reviewHubIntroBody => '代理會分析差異、對應變更區域，並得出共識結論。';

  @override
  String get reviewHubAlreadyRunning => '此 pull request 已有檢閱正在進行';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return '自上次檢閱以來：$resolved 項已解決 · $added 項新增 · $open 項仍未解決';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return '上次檢閱於 $sha';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return '修正 $count 項發現';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return '修正 $count 個所選項目';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return '對 $count 個所選項目留言';
  }

  @override
  String get webConnectTitle => '連線到 Control Center';

  @override
  String get webConnectSubtitle =>
      '透過 WebSocket 撥接執行中的 cc-server。你的金鑰會留在這部裝置上。';

  @override
  String get webConnectServerLabel => '伺服器';

  @override
  String get webConnectDeviceIdLabel => '裝置 id';

  @override
  String get webConnectPairingKeyLabel => '配對金鑰';

  @override
  String get webConnectPairingKeyHint => '貼上 PSK';

  @override
  String get webConnectStayConnected => '在此裝置上保持連線';

  @override
  String get webConnectStayConnectedDetail => '在此裝置上保持連線（將你的金鑰儲存在此瀏覽器中）';

  @override
  String failedToCreateWorkspace(String error) {
    return '無法建立工作區：$error';
  }

  @override
  String committedRelative(String relative) {
    return '提交於 $relative';
  }

  @override
  String get selectAgents => '選擇代理';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個代理',
      one: '1 個代理',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => '新對話';

  @override
  String get untitledConversation => '未命名對話';

  @override
  String get conversationTitleOptionalHint => '選填——留空時，標題模型會自動命名';

  @override
  String get conversationTitlesSectionTitle => '對話標題';

  @override
  String get conversationTitlesSectionCaption =>
      '選擇要在此工作區自動為新對話命名的執行器。在選擇轉接器之前，標題功能會保持關閉，且套用於每個成員。';

  @override
  String get conversationTitlesModelLabel => '標題模型';

  @override
  String get conversationTitlesAdapterLabel => '轉接器';

  @override
  String get conversationTitlesAdapterHint => '關閉';

  @override
  String get conversationTitlesAdapterOff => '關閉';

  @override
  String get startThread => '開始討論串';

  @override
  String get deleteSpaceConfirm => '要刪除此空間嗎？所有訊息都會消失。';

  @override
  String threadTabTitle(String title) {
    return '討論串：$title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 則回覆',
      one: '1 則回覆',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return '最後回覆於 $time';
  }

  @override
  String signInWithProvider(String provider) {
    return '以 $provider 登入';
  }

  @override
  String get signInAgain => '再次登入';

  @override
  String get signInNotFinished => '登入尚未返回。請在瀏覽器中完成後再檢查一次。';

  @override
  String get signedOutTitle => '你已登出';

  @override
  String get signedOutSubtitle =>
      '你的程式碼託管連線已失效——可能是 token 過期，或其存取權被撤銷。其他一切不變：重新登入後，所有東西都會原封不動。';

  @override
  String get viaServerApp => '透過此伺服器的應用程式';

  @override
  String get ticketing => '工單';

  @override
  String get ticketingProviderHelp => '你的工單存放處。選「本機」會將它們保存在 Control Center 中。';

  @override
  String providerComingSoon(String provider) {
    return '$provider（即將推出）';
  }

  @override
  String get ticketProviderLocal => '本機';

  @override
  String get addKey => '新增金鑰';

  @override
  String get providerApps => '供應商應用程式';

  @override
  String get providerAppsDescription =>
      '工作區繼承此 GitHub App，除非選擇其他 App 或僅使用個人存取權杖。背景工作——webhook、輪詢、同步——在應用程式上執行，絕不用個人權杖。';

  @override
  String get providerAppId => '應用程式 id';

  @override
  String get providerPrivateKey => '私鑰';

  @override
  String get providerClientId => '用戶端 id';

  @override
  String get providerClientSecret => '用戶端密鑰';

  @override
  String get providerApiKey => 'API 金鑰';

  @override
  String get providerCallbackUrl => '回呼 URL';

  @override
  String get providerAppFullyConfigured => '伺服器能以自身身分行動，且人們可以登入。';

  @override
  String get providerAppServerOnly => '伺服器能以自身身分行動。新增用戶端 id 與密鑰即可讓人們登入。';

  @override
  String get providerAppSignInOnly => '人們可以登入。背景工作會退而使用他們的憑證。';

  @override
  String providerAppInstalledOn(String accounts) {
    return '憑證可用。安裝於：$accounts';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return '請在剛開啟的 $provider 頁面上輸入此代碼。它已複製到你的剪貼簿。';
  }

  @override
  String get deviceCodeWaiting => '正在等你完成瀏覽器中的操作…';

  @override
  String get copyCodeAndOpen => '複製代碼並開啟';

  @override
  String get couldNotOpenBrowser => '無法開啟任何瀏覽器。請自行複製連結並完成登入。';

  @override
  String get contextUsage => '上下文用量';

  @override
  String get contextUsageFull => '已滿';

  @override
  String get contextUsageTokens => 'token';

  @override
  String get contextSeeMore => '查看更多';

  @override
  String get contextSegmentSystemPrompt => '系統提示';

  @override
  String get contextSegmentRules => '規則';

  @override
  String get contextSegmentSkills => '技能';

  @override
  String get contextSegmentToolDefinitions => '工具定義';

  @override
  String get contextSegmentMcpTools => 'MCP 與動態工具';

  @override
  String get contextSegmentDeferredTools => '隨需載入的工具';

  @override
  String get contextSegmentSubagents => '子代理定義';

  @override
  String get contextSegmentMemory => '記憶';

  @override
  String get contextSegmentConversation => '對話';

  @override
  String get contextExplorerTitle => '上下文';

  @override
  String get contextExplorerEverything => '全部';

  @override
  String get contextExplorerSelectPart => '選擇一個部分以檢查其內容';

  @override
  String get contextExplorerUnavailable => '無法提供上下文細目';

  @override
  String get contextRetry => '重試';

  @override
  String get settingsFieldOptional => '選填';

  @override
  String get settingsFilterHint => '篩選此清單';

  @override
  String get settingsValueNotAvailable => '尚未提供';

  @override
  String get settingsNoEntriesYet => '這裡還沒有東西';

  @override
  String get settingsChangedBadge => '已變更';

  @override
  String get ssoConnectionCardDescription => '選擇人們登入此伺服器的方式，然後開啟該連線。';

  @override
  String get ssoUseSamlForSignIn => '使用 SAML 登入';

  @override
  String get ssoUseOidcForSignIn => '使用 OpenID Connect 登入';

  @override
  String get ssoSaveConnection => '儲存連線';

  @override
  String get ssoStateLive => '已上線';

  @override
  String get ssoStateConfiguredOff => '已設定，未啟用';

  @override
  String get ssoStateOnIncomplete => '已啟用，未完成';

  @override
  String get ssoStateActive => '作用中';

  @override
  String get ssoStateAllowed => '允許';

  @override
  String get ssoStateNoToken => '無 token';

  @override
  String get ssoSummaryDirectorySync => '目錄同步';

  @override
  String get ssoSummaryManualPairing => '手動配對';

  @override
  String get ssoNoMethodLiveNote => '目前沒有已上線的登入方式。在你設定並開啟連線之前，新裝置會以邀請或配對金鑰加入。';

  @override
  String get ssoMethodSamlBlurb =>
      '適用於支援 SAML 2.0 的身分識別供應商，例如 Okta、Entra ID 或 Google Workspace。';

  @override
  String get ssoMethodOidcBlurb =>
      '適用於支援 OpenID Connect 的身分識別供應商。通常是兩者中較容易設定的。';

  @override
  String get ssoGroupIdentityProvider => '身分識別供應商';

  @override
  String get ssoGroupIdentityProviderSamlDescription => '判斷提示的來源，以及此伺服器如何驗證它們。';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      '此伺服器信任哪個簽發者，以及它以哪個用戶端身分驗證。';

  @override
  String get ssoSpEntityIdShortLabel => 'SP 實體 ID';

  @override
  String get ssoSpEntityIdDescription => '留空即可從伺服器 URL 衍生。';

  @override
  String get ssoIssuerDescription => '提供供應商探索文件的基礎 URL。';

  @override
  String get ssoSecretStored => '已儲存';

  @override
  String get ssoGroupHandoff => '你的身分識別供應商需要的資訊';

  @override
  String get ssoGroupHandoffDescription => '將這些貼到你在供應商那裡建立的應用程式。';

  @override
  String get ssoOriginUnknownTitle => '此伺服器不知道自己的公開 URL';

  @override
  String get ssoOriginUnknownBody =>
      '登入與回呼 URL 都是由它組成，因此在設定之前，你的供應商無法連上此伺服器。請在「伺服器 → 連線」下新增公開 URL 或啟用通道。';

  @override
  String get ssoAcsUrlLabel => '判斷提示消費者服務 (ACS) URL';

  @override
  String get ssoAcsUrlDescription => '你的供應商張貼已簽署判斷提示的位置。';

  @override
  String get ssoSpEntityIdResolvedLabel => '服務提供者實體 ID';

  @override
  String get ssoMetadataUrlLabel => 'SP 中繼資料 URL';

  @override
  String get ssoMetadataUrlDescription => '支援匯入中繼資料的供應商可改從這裡取得。';

  @override
  String get ssoRedirectUriLabel => '重新導向 URI';

  @override
  String get ssoRedirectUriDescription => '將此加到你供應商應用程式的允許重新導向 URI 中。';

  @override
  String get ssoSignInUrlLabel => '登入 URL';

  @override
  String get ssoSignInUrlDescription => '請引導使用者到此處開始單一登入。';

  @override
  String get ssoGroupAttributeMapping => '屬性對應';

  @override
  String get ssoGroupAttributeMappingDescription =>
      '哪個宣告承載哪個欄位。除非你的供應商改名，否則保留預設值。';

  @override
  String get ssoGroupAccess => '存取與角色';

  @override
  String get ssoGroupAccessDescription => '成功登入的人可以做什麼。';

  @override
  String get ssoDefaultRoleShortLabel => '預設角色';

  @override
  String get ssoDefaultRoleDescription => '授予群組不符合下方任何對應的使用者。';

  @override
  String get ssoRoleMapShortLabel => '群組至角色對應';

  @override
  String get ssoRoleMapDescription => '第一個符合的群組優先。擁有者無法以這種方式授予。';

  @override
  String get ssoRoleMapGroupHint => '來自你供應商的群組名稱';

  @override
  String get ssoRoleMapAdd => '新增對應';

  @override
  String get ssoRoleMapEmpty => '沒有任何對應——所有人都會取得預設角色。';

  @override
  String get ssoAdvancedSummary => '時鐘偏差、IdP 起始登入、簽章政策';

  @override
  String get ssoClockSkewShortLabel => '時鐘偏差';

  @override
  String get ssoClockSkewDescription => '判斷提示時間戳記的容許秒數。90 適用於大多數供應商。';

  @override
  String get ssoScimGenerate => '產生 token';

  @override
  String get ssoScimTokenOnceBody => '已複製到你的剪貼簿。它只顯示一次且無法復原，請立即貼到你的供應商。';

  @override
  String get ssoPairingCardTitle => '手動配對';

  @override
  String get ssoPairingCardDescription =>
      '進入此伺服器的另一種方式：邀請代碼與配對金鑰，供不透過單一登入的裝置使用。';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count / $total';
  }

  @override
  String get providersNoneConnectedNote =>
      '尚未連接任何供應商，因此內建的代理執行環境沒有可用的運行基礎。請在下方新增 API 金鑰或登入其中一個。';

  @override
  String get providersFilterHint => '篩選供應商';

  @override
  String get providersNoneMatch => '沒有項目符合此篩選條件';

  @override
  String get providerDeniedHereTitle => '已在此工作區中拒絕';

  @override
  String get providerDeniedHereBody => '此處的代理無法使用此供應商，即使它已連線。其他工作區不受影響。';

  @override
  String get providerNeedsSignIn => '登入以使用此供應商';

  @override
  String get providerNeedsApiKey => '新增 API 金鑰以使用此供應商';

  @override
  String get providerApiKeyLabel => 'API 金鑰';

  @override
  String get providerGenerationDefaults => '供應商預設值';

  @override
  String get providerNoModelsYet => '尚未回報任何模型。請先連接供應商，再同步。';

  @override
  String get providerModelsFilterHint => '篩選模型';

  @override
  String get adaptersNoneReadyNote => '此機器上找不到任何已列入目錄的執行器 CLI。請先安裝一個，再重新整理。';

  @override
  String get adaptersFilterHint => '篩選執行器';

  @override
  String get adaptersLaunchGroup => '啟動';

  @override
  String get adaptersLaunchGroupDescription =>
      '代理啟動此執行器時會給它什麼。你可以選擇在安裝 CLI 前先設定好。';

  @override
  String get adaptersEnvNone => '未設定';

  @override
  String adaptersEnvCount(int count) {
    return '已設定 $count 項';
  }

  @override
  String get adapterArgumentsDescription => '每次啟動時附加到執行器的命令列。';

  @override
  String get defaultChatDescription => '執行新對話，以及任何沒有專屬執行器的代理。';

  @override
  String get shortTaskDescription => '執行快速背景工作，例如標題與摘要。較小的模型適合放在這裡。';

  @override
  String get settingsStateFailed => '失敗';

  @override
  String get providerAppsGroupServer => '以伺服器身分行動';

  @override
  String get providerAppsGroupServerDescription =>
      '供繼承此安裝 GitHub App 的工作區使用。使用自己的 App 或 PAT 的工作區在工作區 → 一般中設定。';

  @override
  String get providerAppsGroupPrConversations => 'Pull request 對話';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      '繼承工作區中開發者如何在 GitHub 上與此伺服器對話。擁有自己 App 的工作區在工作區 → 一般下有自己的機器人。無需 webhook 或公開 URL——由伺服器輪詢。';

  @override
  String get providerAppBotLogin => '機器人登入名稱';

  @override
  String get providerAppBotLoginEmpty => '測試連線以解析機器人登入名稱。';

  @override
  String get providerAppAskOnGitHub => '在 GitHub 上發問';

  @override
  String get providerAppAskOnGitHubHint =>
      '在 pull request 留言中提及上方的機器人登入名稱——[bot] 後綴可省略——即可要求檢閱或提問；在其檢閱討論串中回覆，或加上 `ai-review` 標籤以要求檢閱。';

  @override
  String get providerAppsGroupSignIn => '讓人們登入';

  @override
  String get providerAppsGroupSignInDescription => '讓每位成員連接自己的帳戶並取得屬於自己的憑證。';

  @override
  String get providerAppCapActsAsServer => '以伺服器身分行動';

  @override
  String get providerAppCapSignsIn => '讓人們登入';

  @override
  String get portLabel => '連接埠';

  @override
  String get mcpNoTokenWarning => '若沒有 token，任何能連到這個連接埠的東西都能呼叫所有工具。';

  @override
  String get mcpBridgedToolsLabel => '工具';

  @override
  String get guardrailFamilyFiles => '檔案';

  @override
  String get guardrailFamilyGit => 'Git 與 pull request';

  @override
  String get guardrailFamilyMachine => '機器與網路';

  @override
  String get guardrailFamilyControl => '機密與工作區';

  @override
  String get guardrailScopeFieldLabel => '正在編輯的規則對象';

  @override
  String get guardrailScopeFieldDescription =>
      '較窄的範圍優先於較寬的範圍。此處設定的規則會疊加在繼承的規則之上。';

  @override
  String get guardrailSetHere => '於此設定';

  @override
  String get guardrailClearAllHere => '全部清除';

  @override
  String get sandboxingCardLabel => '沙盒';

  @override
  String get sandboxingCardDescription => '代理工作是否與此主機隔離執行，以及被隔離的代理還能存取什麼。';

  @override
  String get sandboxBackendNoneActive => '主機，無隔離';

  @override
  String get sandboxSummaryHost => '主機';

  @override
  String get sandboxGroupIsolation => '隔離';

  @override
  String get sandboxGroupIsolationDescription => '代理的處理序與檔案寫入實際發生在哪裡。';

  @override
  String get sandboxBackendFieldDescription =>
      '「自動」會選擇此主機支援的最強選項。釘選一個即可避免它在底下變動。';

  @override
  String get sandboxCapabilitiesDescription => '在邊界上打穿的孔。每一項都是被隔離的代理仍能對外界做的事。';

  @override
  String get sandboxSummaryInForce => '生效中';

  @override
  String get rigsInstallHintLabel => '安裝方式';

  @override
  String get rigsStarting => '啟動中';

  @override
  String get rigsResidentMemory => '常駐記憶體';

  @override
  String get installedLabel => '已安裝';

  @override
  String get notInstalledLabel => '未安裝';

  @override
  String ssoOtherKindUnsaved(String method) {
    return '$method 有未儲存的變更';
  }

  @override
  String get collapseComment => '摺疊留言';

  @override
  String get expandComment => '展開留言';

  @override
  String get suggestedChange => '建議的變更';

  @override
  String get emptyComment => '空留言';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 則回覆',
      one: '1 則回覆',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => '待送出的檢閱';

  @override
  String failedToResolveConversation(String error) {
    return '無法更新對話：$error';
  }

  @override
  String get addSingleComment => '新增單則留言';

  @override
  String get addToReview => '加入檢閱';

  @override
  String get startAReview => '開始檢閱';

  @override
  String get reviewNeedsABody => '請先撰寫摘要或排入行內留言';

  @override
  String get reviewSubmitted => '檢閱已送出';

  @override
  String get finishYourReview => '完成你的檢閱';

  @override
  String get commentVerdict => '留言';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 則待送出留言',
      one: '1 則待送出留言',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return '與另外 $count 項';
  }

  @override
  String get queuedCommentHint => '此留言會在你送出檢閱時一併送出。';

  @override
  String commentOnLinesRange(int start, int end) {
    return '第 $start 行至第 $end 行';
  }

  @override
  String get claudeAccountsTitle => 'Claude Code 帳戶';

  @override
  String get claudeAccountsDescription =>
      '每個帳戶都是獨立的 Claude Code 登入。執行會依序使用下方附加的帳戶。';

  @override
  String get claudeAccountsEmpty => '尚無帳戶';

  @override
  String get claudeAccountAdd => '新增帳戶';

  @override
  String get claudeAccountSignIn => '登入';

  @override
  String get claudeAccountSignInAgain => '再次登入';

  @override
  String get claudeAccountSignInHint =>
      '請在伺服器上的終端機執行此命令。它會開啟瀏覽器完成登入，並將憑證寫入此帳戶的目錄。';

  @override
  String get claudeAccountSignedOut => '已登出';

  @override
  String get claudeAccountExpired => '登入已過期';

  @override
  String claudeAccountExpiredDetail(String when) {
    return '登入已於 $when 過期。請再次登入以使用此帳戶。';
  }

  @override
  String get claudeAccountMakeDefault => '設為預設';

  @override
  String get claudeAccountDefault => '預設';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return '要移除 $label 嗎？';
  }

  @override
  String get claudeAccountRemoveDetail => '這會將帳戶登出並刪除其在伺服器上的目錄。登入本身不受影響。';

  @override
  String claudeAccountStatusUnknown(String error) {
    return '無法檢查此帳戶：$error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return '已使用 $percent%';
  }

  @override
  String get accountPoolStrategy => '輪替方式';

  @override
  String get accountPoolPinned => '釘選';

  @override
  String get accountPoolRoundRobin => '循環輪替';

  @override
  String get accountPoolSerial => '逐一使用';

  @override
  String get accountPoolPinnedHint => '一律從第一個帳戶開始。其他帳戶保留為失敗時的備援。';

  @override
  String get accountPoolRoundRobinHint => '將執行分散到各帳戶，每次派發輪到下一個。';

  @override
  String get accountPoolSerialHint => '先用完第一個帳戶再動下一個。';

  @override
  String get accountPoolMoveUp => '上移';

  @override
  String get accountPoolMoveDown => '下移';

  @override
  String get accountPoolUsingAll => '尚未附加任何項目——所有帳戶都會依此順序使用。';

  @override
  String get accountPoolInheriting => '繼承工作區的帳戶。';

  @override
  String get accountPoolResetToWorkspace => '重設為工作區的帳戶';

  @override
  String accountPoolCoolingOff(String when) {
    return '配額耗盡，直到 $when';
  }

  @override
  String get accountPoolSignedOut => '已登出';

  @override
  String get accountPoolExpired => '登入已過期';

  @override
  String accountPoolLoadFailed(String error) {
    return '無法載入輪替設定：$error';
  }

  @override
  String get providerSignedInAccount => '已登入的帳戶';

  @override
  String get agentAccountsTab => '帳戶';

  @override
  String get agentClaudeAccountsNoticeTitle => '多個 Claude Code 帳戶';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return '此執行器會以此主機上 $count 個 Claude Code 帳戶之一的身分登入。請在「帳戶」分頁中選擇其一，或在其間輪替。';
  }

  @override
  String get agentAccountsDescription => '此代理的執行使用哪些帳戶。每個區塊一開始都繼承工作區的選擇。';

  @override
  String get agentAccountsNothingToRotate => '沒有可輪替的項目——請先連接第二個帳戶或金鑰。';

  @override
  String failedToPostReply(String error) {
    return '無法張貼回覆：$error';
  }

  @override
  String commentOnLine(int line) {
    return '第 $line 行';
  }

  @override
  String get viewInDiff => '在差異中檢視';

  @override
  String get subscriptionUsagePreviousAccount => '上一個帳戶';

  @override
  String get subscriptionUsageNextAccount => '下一個帳戶';

  @override
  String inReplyTo(String path) {
    return '回覆 $path';
  }

  @override
  String get subscriptionUsageNoneReported => '此帳戶沒有回報用量。';

  @override
  String get subscriptionUsageCredits => '點數';

  @override
  String get reviewHubStaticRule => '靜態規則';

  @override
  String get reviewHubStarted => '檢閱已開始';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return '由確定性規則（$rule）在此 pull request 新增的某一行上發現——而非由檢閱代理發現。';
  }

  @override
  String get prReviewArtifactTab => 'PR 檢閱';

  @override
  String get prReviewRunning => '正在檢閱此 pull request…';

  @override
  String get prReviewStarting => '正在開始檢閱…';

  @override
  String get prReviewStartingBody => '正在準備此 pull request 的工作樹。一旦就緒，檢閱者就會開始。';

  @override
  String get prReviewFailed => '檢閱失敗。';

  @override
  String get prReviewRerunning => '正在重新檢閱…';

  @override
  String get prReviewNoOpenFindings => '沒有未解決的發現項';

  @override
  String prReviewOpenFindings(int count) {
    return '$count 項未解決的發現';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used / $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return '已以機器人身分張貼 $posted 則留言。$skipped 則略過（無檔案錨點），$failed 則失敗。';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count 項發現指向此 pull request 未變更的程式碼（$files）。GitHub 只接受差異上的行內留言。';
  }

  @override
  String get reviewRailReport => '報告';

  @override
  String get reviewNoFindingsTitle => '尚無檢閱發現';

  @override
  String get reviewNoFindingsHint => '代理張貼的發現項會出現在這裡。';

  @override
  String reviewShowDismissed(int count) {
    return '顯示 $count 項已忽略';
  }

  @override
  String reviewHideDismissed(int count) {
    return '隱藏 $count 項已忽略';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '偵測到 $count 項檢閱者分歧',
      one: '偵測到 1 項檢閱者分歧',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => '種類';

  @override
  String get reviewFilterStatus => '狀態';

  @override
  String get reviewKindBug => 'Bug';

  @override
  String get reviewKindSuggestion => '建議';

  @override
  String get reviewKindRecommendation => '推薦';

  @override
  String get reviewKindQuestion => '問題';

  @override
  String get reviewKindTicket => '工單';

  @override
  String get archiveSpace => '封存空間';

  @override
  String get archivedSpaces => '已封存的空間';

  @override
  String get archivedSpacesEmpty => '沒有已封存的空間';

  @override
  String get restoreSpace => '還原';

  @override
  String archivedWhen(String time) {
    return '封存於 $time';
  }

  @override
  String get deleteSpacePermanently => '永久刪除';

  @override
  String get renameSpace => '重新命名空間';

  @override
  String get renameConversation => '重新命名對話';

  @override
  String get spaceActions => '空間操作';

  @override
  String get conversationActions => '對話操作';

  @override
  String get editSpaceRepos => '編輯儲存庫';

  @override
  String get editSpaceReposTitle => '空間儲存庫';

  @override
  String get editSpaceReposWarning => '新增儲存庫會將它檢出至此空間；移除則會刪除其資料夾。';

  @override
  String get agentSectionIdentity => '身分';

  @override
  String get agentSectionRuntime => '執行環境';

  @override
  String get agentSectionGuardrails => '護欄';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 位部屬',
      one: '1 位部屬',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => '篩選團隊…';

  @override
  String get teamsSummaryWithLeader => '有領導者';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個團隊',
      one: '1 個團隊',
      zero: '沒有團隊',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return '刪除 $name 會移除其設定檔、技能連結與執行歷史。此動作無法復原。';
  }

  @override
  String get resetToDefault => '重設為預設值';

  @override
  String get newAgent => '新增代理';

  @override
  String get newSkill => '新增技能';

  @override
  String get zoomIn => '放大';

  @override
  String get zoomOut => '縮小';

  @override
  String get resetZoom => '重設縮放';

  @override
  String get imageHostedOnGitHub => '圖片由 GitHub 代管';

  @override
  String get imageOpenExternally => '圖片 · 於外部開啟';

  @override
  String get memoryScopeAll => '所有範圍';

  @override
  String get memoryScopeWorkspace => '整個工作區';

  @override
  String get memoryScopeFilterLabel => '依範圍篩選';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return '範圍限於 $repo 儲存庫';
  }

  @override
  String get toolScreenshot => '來自代理的螢幕截圖';

  @override
  String get toolImageUnavailable => '圖片無法使用';

  @override
  String toolImagesUnavailable(int count) {
    return '$count 張圖片無法使用';
  }

  @override
  String get shakeUnavailable => '此伺服器不支援搖晃功能';

  @override
  String get shakeNothing => '沒有東西可搖出——最近的回合受保護';

  @override
  String shakeDone(int tokens) {
    return '已釋放約 $tokens 個 token';
  }

  @override
  String get compactionDivider => '已壓縮';

  @override
  String compactionDividerCount(int count) {
    return '已壓縮 · 摺疊了 $count 則訊息';
  }

  @override
  String get composerDropToAttach => '放下以附加';

  @override
  String get attachmentUnavailable => '附件無法使用';

  @override
  String get attachmentUnavailableDetail => '此附件已不在記憶體中。請重新附加以預覽。';

  @override
  String get attachmentPreviewFailed => '無法開啟此檔案';

  @override
  String get attachmentPreviewUnsupported => '此檔案類型不支援預覽';

  @override
  String get attachmentTooLargeToPreview => '過大，無法預覽';

  @override
  String get attachmentOpenExternally => '在預設應用程式中開啟';

  @override
  String get asideUnavailable => '需先在工作區設定中設定一次性模型，才能使用此功能';

  @override
  String get asideEmpty => '尚無可依據的內容';

  @override
  String get asideFailed => '無法取得答案';

  @override
  String get handoffTitle => '交接';

  @override
  String get asideTitle => '側邊提問';

  @override
  String get attachFilesOrDrop => '附加檔案——或拖放到這裡';

  @override
  String get guidedGoalTitle => '讓目的更明確';

  @override
  String get guidedGoalIntro => '在無人監督下工作的代理需要確切知道何時算完成。先回答幾個問題。';

  @override
  String get guidedGoalAnswerHint => '你的回答';

  @override
  String get guidedGoalNext => '下一步';

  @override
  String get guidedGoalStart => '開始目標';

  @override
  String get guidedGoalSkip => '略過並按原樣執行';

  @override
  String guidedGoalStillMissing(String items) {
    return '尚未指定：$items';
  }

  @override
  String get conversationTreeTitle => '對話樹';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個分支',
      one: '1 個分支',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => '從這裡繼續';

  @override
  String get conversationTreeFork => '分叉成新對話';

  @override
  String get conversationTreeCurrent => '在此分支上';

  @override
  String get conversationTreeEmpty => '這裡還沒有東西';

  @override
  String get conversationTreeForked => '已分叉成新對話';

  @override
  String get conversationTreeSwitched => '現在從該訊息繼續';

  @override
  String exportSaved(String path) {
    return '已儲存至 $path';
  }

  @override
  String get exportFailed => '無法寫入匯出';

  @override
  String get contextCommandNoAgent => '此對話中沒有代理，因此沒有可開啟的上下文視窗';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return '此對話中沒有名為「$name」的代理。試試：$names';
  }

  @override
  String get dumpCopied => '對話紀錄已複製到剪貼簿';

  @override
  String get messageQueueHint => '繼續輸入即可將後續變更排入佇列';

  @override
  String get steerNow => '引導';

  @override
  String get steeringQueueLabel => '排隊中的引導訊息';

  @override
  String get steeringDeliverUnavailable => '目前沒有執行中的代理能接收——它會繼續排隊。';

  @override
  String get reorderSteeringCard => '重新排序排隊訊息';

  @override
  String get editSteeringCard => '編輯排隊訊息';

  @override
  String get deleteSteeringCard => '刪除排隊訊息';

  @override
  String get steeringBadge => '已引導';

  @override
  String get settingsSandboxLabel => '沙盒';

  @override
  String get sandboxExecGrantsTitle => '可執行檔授權';

  @override
  String get sandboxExecGrantsSubtitle =>
      '代理可從你的儲存庫工作複本中執行的程式。每一項都是沙盒提出請求時由你核准的。';

  @override
  String get sandboxExecGrantsEmpty => '尚無任何決定紀錄。第一次有代理需要從其工作複本執行程式時，系統會詢問你。';

  @override
  String get sandboxExecGrantRevoke => '撤銷';

  @override
  String get sandboxExecGrantAllowed => '已允許';

  @override
  String get sandboxExecGrantBlocked => '已封鎖';

  @override
  String get sandboxExecGrantRevokeConfirmTitle => '要撤銷此決定嗎？';

  @override
  String get sandboxExecGrantRevokeConfirmBody => '下次有代理需要從此複本執行程式時，系統會再次詢問你。';

  @override
  String get repoScriptsTest => '測試';

  @override
  String get repoScriptsTestTooltip => '在儲存庫的一次性複本中執行此草稿';

  @override
  String get repoScriptsRunKindTest => '測試';

  @override
  String get demoBadgeLabel => '示範';

  @override
  String get demoFilePickerTitle => '示範檔案';

  @override
  String get demoFilePickerBody => '示範會模擬上傳：任選一個，它就會附加到你的訊息，完全不碰磁碟。';

  @override
  String get demoFilePickerAttach => '附加';

  @override
  String get demoReadOnlySave => '示範中為唯讀';

  @override
  String get demoBadgeTooltip => '你正在探索示範。資料是虛構的，代理是預先編排的。';

  @override
  String get demoFirstRunTitle => '你正在線上示範中';

  @override
  String demoFirstRunBody(int minutes) {
    return '這是真實的應用程式在真實的程式碼上執行——只有資料是虛構的。代理串流的是照劇本播放的真實執行，因此沒有任何內容會送達模型，也沒有任何東西在機器上執行。你的工作區專屬於你，並會在 $minutes 分鐘後消失。';
  }

  @override
  String get demoFirstRunDismiss => '知道了';

  @override
  String get demoTourTitle => '先從哪裡看起';

  @override
  String get demoTourSubtitle => '四個能看出這個應用程式實際功能的地方。';

  @override
  String get demoTourSkip => '略過';

  @override
  String get demoTourStarRepo => '在 GitHub 上加星';

  @override
  String get demoTourOpen => '開啟';

  @override
  String get demoTourSpacesTitle => '與代理對話';

  @override
  String get demoTourSpacesBody =>
      '在空間中送出訊息，看著執行串流進來——思考、工具呼叫與成本，與真實執行的呈現完全相同。';

  @override
  String get demoTourReviewTitle => '檢閱 pull request';

  @override
  String get demoTourReviewBody => '開啟 #412。留下行內留言或送出檢閱；你寫的內容會進到討論串並留在那裡。';

  @override
  String get demoTourTicketsTitle => '追蹤工作';

  @override
  String get demoTourTicketsBody => '工單、待辦與計畫都連結到代理正在進行的同一批對話。';

  @override
  String get demoTourInboxTitle => '綜觀整個運作';

  @override
  String get demoTourInboxBody => '來自各個支柱的所有警示都會匯入同一個收件匣——檢閱、工單、執行與會議。';

  @override
  String get demoUnavailableTitle => '示範中不提供';

  @override
  String get demoUnavailableTerminal =>
      '終端機會在伺服器主機上執行真實的 shell。示範完全沒有執行面——這正是它能安全公開的原因。';

  @override
  String get demoUnavailableRig =>
      '隔離艙是一部由代理操縱的一次性虛擬機器。示範不會啟動任何一部：能啟動 VM 的公開端點就算不上示範。';

  @override
  String get demoUnavailableEditor =>
      '瀏覽器內的編輯器會對真實的 checkout 執行 code-server 處理序。示範則兩者皆無。';

  @override
  String get demoUnavailableFeeds => '示範會讀取真實的資訊源，但其訂閱清單是固定的。在此無法新增或移除。';

  @override
  String get demoUnavailableForge =>
      '示範不持有任何憑證，也絕不會聯絡 GitHub、GitLab 或 Linear。其 pull request 皆為預置資料，你對它們的留言只存在本機。';

  @override
  String get demoUnavailableModels =>
      '示範不會呼叫任何模型。代理執行是照劇本播放，因此不花任何成本，也不會連到任何供應商。';

  @override
  String get demoUnavailableMcp => 'MCP 工具面未掛載在示範上，因此沒有外部用戶端能附加到它。';

  @override
  String get demoUnavailableRepos =>
      '示範不會檢出任何程式碼，也不會執行任何 git。你看到的儲存庫是 pull request 背後的預置資料。';

  @override
  String get demoUnavailableSkills => '安裝技能會下載並掃描程式碼。示範不會擷取任何東西。';

  @override
  String get demoUnavailableSso => '單一登入屬於伺服器設定。示範會改讓你以臨時訪客身分登入。';

  @override
  String get demoUnavailableAudio =>
      '錄音與聽寫需要主機上的音訊擷取與語音模型。示範兩者皆未提供，因此其會議是只有逐字稿、沒有播放。';

  @override
  String get demoUnavailableServerAdmin =>
      '這是伺服器管理。示範只給每位訪客一個用完即丟的工作區，除此之外什麼都沒有。';

  @override
  String get demoUnavailablePipelines =>
      '此處無法執行管線。訪客若能撰寫 bash 步驟並以手動或事件觸發方式啟動，就是在此主機上執行程式碼。';

  @override
  String get settingsBackupRestore => '備份與還原';

  @override
  String get settingsBackupRestoreDescription =>
      '此伺服器上所有資料庫的快照，以及單一工作區的匯出、匯入與刪除。';

  @override
  String get backupSnapshotsLabel => '安裝快照';

  @override
  String get backupSnapshotsExplainer =>
      '快照會將每個資料庫複製到伺服器主機上一個以時間戳命名的資料夾。還原整個安裝需要在伺服器停止時把該資料夾複製回去；單一工作區則可從這裡還原。';

  @override
  String get backupNowAction => '立即備份';

  @override
  String backupSnapshotWritten(String path) {
    return '快照已寫入 $path';
  }

  @override
  String get backupNoSnapshots => '尚無快照。只有在你要求時才會建立——沒有任何排程。';

  @override
  String get backupSnapshotComplete => '完整';

  @override
  String get backupSnapshotIncomplete => '不完整';

  @override
  String get backupSnapshotIncompleteNote =>
      '資訊清單遺失，或指到了不存在的檔案，因此此快照無法還原整個安裝。它確實擁有的工作區檔案仍可逐一採用。';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個工作區',
      one: '1 個工作區',
      zero: '沒有工作區',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個工作區未擷取',
      one: '1 個工作區未擷取',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => '伺服器上的路徑';

  @override
  String get backupRestoreAction => '還原';

  @override
  String get backupRestoreTitle => '還原工作區';

  @override
  String backupRestoreBody(String name) {
    return '這會以快照中的副本取代 $name 的一切。該工作區自快照建立後所做的所有變更都會流失，且無法復原。';
  }

  @override
  String backupRestoreDone(String name) {
    return '已從快照還原 $name。';
  }

  @override
  String get backupWorkspaceUnknown => '已不在此伺服器上';

  @override
  String get backupWorkspaceDataLabel => '工作區資料';

  @override
  String get backupWorkspaceDataExplainer =>
      '一個工作區就是一個資料庫檔案，因此匯出是複製該檔案，而非逐表傾印。匯入則是以你指定的檔案取代目標工作區的一切。';

  @override
  String get backupExportAction => '匯出';

  @override
  String backupExportDone(String path) {
    return '已匯出至 $path';
  }

  @override
  String get backupExportedFileLabel => '伺服器上的匯出檔案';

  @override
  String get backupImportAction => '匯入';

  @override
  String backupImportTitle(String name) {
    return '匯入至 $name';
  }

  @override
  String backupImportBody(String name) {
    return '這會以檔案內容取代 $name 的一切。該工作區現有的一切都會流失，且無法復原。';
  }

  @override
  String get backupImportSourceLabel => '工作區資料庫檔案';

  @override
  String get backupImportSourceDescription =>
      '伺服器可讀取的 .db 檔案。路徑是在伺服器主機上解析，不是在這部裝置上。';

  @override
  String backupImportDone(String name) {
    return '已匯入至 $name。';
  }

  @override
  String backupDeleteBody(String name) {
    return '$name 會從所有清單與查詢中消失。其資料庫檔案仍留在磁碟上，備份仍會包含它，且沒有任何機制會自動回收該空間。';
  }

  @override
  String get backupExportDescription => '在伺服器上寫入一份副本，或下載一份到這部裝置。';

  @override
  String get backupExportOnServerAction => '儲存在伺服器上';

  @override
  String get backupDownloadAction => '下載';

  @override
  String backupDownloadSaved(String path) {
    return '已儲存至 $path';
  }

  @override
  String get backupDownloadInBrowser => '你的瀏覽器正在下載。';

  @override
  String get backupRestoreFromDeviceLabel => '從此裝置還原';

  @override
  String get backupRestoreFromDeviceDescription =>
      '在這裡選擇工作區資料庫檔案，Control Center 會將它上傳到伺服器。當伺服器不是這部機器時，這是唯一可行的方式。';

  @override
  String get backupUploadAction => '選擇檔案並上傳';

  @override
  String get backupTransferUnavailable =>
      '此連線是透過中繼連到伺服器，而中繼不承載檔案傳輸。請直接連線到伺服器以下載或上傳備份。';

  @override
  String get backupTransferForbidden =>
      '伺服器拒絕了。下載工作區需要管理員角色，還原工作區需要擁有者，整份快照則需要此安裝的操作員。';

  @override
  String get backupTransferUnsupported => '此伺服器沒有備份介面。';

  @override
  String get backupTransferTooLarge => '檔案大於伺服器接受的上限。';

  @override
  String get credentialGateWaitingTitle => '正在等待憑證';

  @override
  String credentialGateHarnessTitle(String provider) {
    return '$provider 沒有憑證';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Code 已登出';

  @override
  String get credentialGateExpiredTitle => '你的 Claude Code 登入已過期';

  @override
  String get credentialGatePlanSpentTitle => '已達 Claude Code 方案上限';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent 正在等待以繼續。';
  }

  @override
  String get credentialGateWaitingRun => '有個執行正在等待以繼續。';

  @override
  String get credentialGateWatching => '正在關注修正進度——執行會自行繼續。';

  @override
  String credentialGateFreesUpAt(String time) {
    return '將於 $time 恢復可用';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return '執行將於 $time 放棄';
  }

  @override
  String get credentialGateCheckAgain => '再次檢查';

  @override
  String get credentialGateCancelRun => '取消執行';

  @override
  String get credentialGateAccountsTried => '已嘗試的帳戶';

  @override
  String get credentialGateClaudeSignInHint =>
      '請從設定 → 轉接器 → Claude Code 登入，或在終端機執行登入命令。執行會自行接上。';

  @override
  String get credentialGateOpenSettings => '開啟設定';

  @override
  String get selectModel => '選擇模型';

  @override
  String get allModels => '所有模型';

  @override
  String get noModelsMatchSearch => '沒有符合搜尋的模型';

  @override
  String useCustomModelId(String id) {
    return '使用「$id」';
  }

  @override
  String get modelFree => '免費';

  @override
  String modelOutputTokens(String tokens) {
    return '輸出 $tokens';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return '每 100 萬 token 輸入 $input / 輸出 $output';
  }

  @override
  String modelEffortLevels(String levels) {
    return '推理力度：$levels';
  }

  @override
  String get modelSupportsReasoning => '支援推理力度';

  @override
  String get profileDeliveryMetrics => '交付指標';

  @override
  String profileMetricsSample(int count) {
    return '已分析 PR：$count';
  }

  @override
  String get profileMergeRate => '合併率';

  @override
  String get profileReviewCoverage => '審查涵蓋率';

  @override
  String get profilePrSize => 'PR 大小';

  @override
  String get profileTimeToMerge => '合併所需時間';

  @override
  String get profileMergeTimeTrend => '合併時間趨勢';

  @override
  String get profileWeeklyMedian => '每週中位數，對數刻度';

  @override
  String get profilePrOpeningPattern => '星期 × 小時，本地時間';

  @override
  String get profileFirstReview => '首次審查所需時間';

  @override
  String get profileMetricsTruncated => '百分位數是根據可用提取要求的有限樣本計算而得。';

  @override
  String profileLinesChanged(String count) {
    return '$count 行';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count 分鐘';
  }

  @override
  String profileDurationHours(int count) {
    return '$count 小時';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '$days天 $hours小時';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return '成員：$count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return '此工作區中沒有 $team 的提取要求';
  }

  @override
  String get profilePrStateFilterLabel => '依狀態篩選提取要求';

  @override
  String get noProfilePrsMatchSearchHint => '請嘗試其他標題或提取要求編號';

  @override
  String get rigNetworkUnrestricted => '網路不受限制';

  @override
  String get rigNetworkAllowAllHosts => '允許所有主機';

  @override
  String get rigBrowserPermissionsTitle => '網站權限';

  @override
  String get rigBrowserPermissionsTooltip => '網站權限與網路';

  @override
  String get rigBrowserPermissionEmpty => '還沒有網站要求過權限';

  @override
  String rigBrowserPermissionPrompt(String origin, String permission) {
    return '$origin 想要使用$permission';
  }

  @override
  String get rigBrowserPermissionBlock => '封鎖';

  @override
  String get rigBrowserPermissionCamera => '相機';

  @override
  String get rigBrowserPermissionMicrophone => '麥克風';

  @override
  String get rigBrowserPermissionNotifications => '通知';

  @override
  String get rigBrowserPermissionGeolocation => '位置';

  @override
  String get rigBrowserPermissionPersistentStorage => '持久儲存';

  @override
  String get rigBrowserPermissionClipboard => '剪貼簿';

  @override
  String get rigBrowserPermissionDisplayCapture => '螢幕擷取';

  @override
  String get rigBrowserPermissionMidi => 'MIDI';

  @override
  String get rigNetworkBypassTitle => '允許存取所有網路主機？';

  @override
  String get rigNetworkBypassBody =>
      '這會重新啟動隔離環境，並捨棄其中尚未提交的工作。之後，客體系統在關閉前可以存取任何網路主機。';

  @override
  String get rigNetworkRestartUnrestricted => '以不受限模式重新啟動';

  @override
  String get rigNetworkUnrestrictedBody =>
      '此隔離環境可以存取任何網路主機。關閉它並開啟新的環境，即可恢復預設限制。';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      '此 Android 模擬器已自行管理網路，因此 Control Center 無法強制執行個別主機的允許清單。無須重新啟動。';

  @override
  String get rigClipboardPermissionHostToRigTitle => '將剪貼簿貼到此環境？';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'Control Center 將讀取你裝置的剪貼簿，並將其內容傳送到該環境。剪貼簿內容可能包含密碼或其他機密資訊。';

  @override
  String get rigClipboardPermissionRigToHostTitle => '從此環境複製剪貼簿？';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'Control Center 將讀取該環境的剪貼簿，並以其內容取代你裝置的剪貼簿。請將來自該環境的內容視為不受信任。';

  @override
  String get rigClipboardAllowTenMinutes => '允許 10 分鐘';

  @override
  String get rigClipboardAlwaysAllow => '一律允許';

  @override
  String get rigClipboardSettingsTitle => '剪貼簿存取';

  @override
  String get rigClipboardSettingsHint => '選擇哪些剪貼簿傳輸可不經詢問即可執行。暫時權限會在 10 分鐘後到期。';

  @override
  String get rigClipboardAlwaysPasteTitle => '一律允許貼到環境';

  @override
  String get rigClipboardAlwaysPasteDescription => '不經詢問，將此裝置的剪貼簿傳送到任何環境。';

  @override
  String get rigClipboardAlwaysCopyTitle => '一律允許從環境複製';

  @override
  String get rigClipboardAlwaysCopyDescription => '不經詢問，將任何環境中的剪貼簿內容放到此裝置上。';

  @override
  String get workspaceGitHubIdentity => 'GitHub 身分';

  @override
  String get workspaceGitHubIdentityDescription =>
      '此工作區背景 GitHub 工作的驗證方式。繼承此安裝的 App、使用其他 App，或僅使用個人存取權杖。';

  @override
  String get workspaceGitHubModeInherit => '使用此安裝的 GitHub App';

  @override
  String get workspaceGitHubModeApp => '使用其他 GitHub App';

  @override
  String get workspaceGitHubModePat => '僅個人存取權杖';

  @override
  String get workspaceGitHubInheritHint => '使用伺服器 → 提供者應用程式中的 GitHub App。';

  @override
  String get workspaceGitHubAppHint => '此工作區的機器人和輪詢身分。成員在「你」中透過此 App 登入。';

  @override
  String get workspaceGitHubPatLabel => '背景權杖';

  @override
  String get workspaceGitHubPatDescription => '用於此工作區的輪詢和代理。不是成員的個人資料權杖。';

  @override
  String get workspaceGitHubHasPat => '已儲存背景權杖。';

  @override
  String get workspaceGitHubNoPat => '未儲存背景權杖。';

  @override
  String get profileOverlayHint =>
      '這些欄位是你在此工作區的身分。空白欄位繼承帳戶名稱和電子郵件。切換工作區會切換此覆蓋層。';

  @override
  String get forgeConnectionsThisWorkspace => '登入或貼上此工作區的權杖。';
}
