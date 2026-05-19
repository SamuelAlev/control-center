// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get succeeded => 'Concluído';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'Nova tentativa n.º $number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'A iniciar · $time';
  }

  @override
  String get agentActivityFollowingLive => 'A acompanhar a atividade em direto';

  @override
  String get agentActivityJumpToLatest => 'Ir para o mais recente';

  @override
  String get agentActivityLoadFailed =>
      'Não foi possível carregar a atividade desta execução';

  @override
  String get agentActivityNotRecorded =>
      'Nenhuma atividade foi registrada para esta execução';

  @override
  String get agentActivityNotRecordedHint =>
      'Execuções concluídas antes de a captura de atividade ser ativada não têm cronologia.';

  @override
  String get agentActivityRunUnavailable =>
      'Esta execução já não está disponível';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'Subagente de $agent';
  }

  @override
  String get agentActivityUnsupported =>
      'A captura de atividade não está disponível no servidor ligado';

  @override
  String get agentActivityUnsupportedHint =>
      'Reinicie a aplicação para que use a versão mais recente do servidor.';

  @override
  String get agentActivityWaiting => 'Aguardando atividade…';

  @override
  String get created => 'Criado';

  @override
  String get dictationStart => 'Iniciar ditado';

  @override
  String get dictationListening => 'A ouvir…';

  @override
  String get dictationUnavailable =>
      'O ditado precisa de um modelo de voz no servidor anfitrião. Configure um nas definições de voz.';

  @override
  String get dictationFailedToStart => 'Não foi possível iniciar o ditado';

  @override
  String get dictationHoldToTalkTitle => 'Manter para falar';

  @override
  String get dictationHoldToTalkDescription =>
      'Mantenha o botão do microfone ou o atalho para ditar e solte para parar. Quando desativado, prima uma vez para iniciar e novamente para parar.';

  @override
  String get focusConversation => 'Focar a conversa';

  @override
  String get ideAgentActivity => 'Atividade do agente';

  @override
  String get keybindingPushToTalk => 'Premir para falar';

  @override
  String get keybindingPushToTalkDescription =>
      'Manter ou alternar o ditado por voz no compositor de mensagens';

  @override
  String get agentPermissions => 'Permissões dos agentes';

  @override
  String get agentPermissionsSettingsDescription =>
      'Decida o que os agentes podem fazer sozinhos, o que devem perguntar primeiro ou o que nunca podem fazer — por espaço de trabalho, agente ou canal.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Defina uma decisão para cada tipo de efeito. As regras têm precedência: o canal sobrepõe-se ao agente, que se sobrepõe ao espaço de trabalho.';

  @override
  String get guardrailLoading => 'A carregar regras…';

  @override
  String get guardrailRulesLoadFailed =>
      'Não foi possível carregar as regras de permissão.';

  @override
  String get guardrailScopeWorkspace => 'Espaço de trabalho';

  @override
  String get guardrailScopeAgent => 'Agente';

  @override
  String get guardrailScopeChannel => 'Canal';

  @override
  String get guardrailSelectAgent => 'Selecionar um agente';

  @override
  String get guardrailSelectChannel => 'Selecionar um canal';

  @override
  String get guardrailNoAgents =>
      'Ainda não há agentes neste espaço de trabalho.';

  @override
  String get guardrailNoChannels =>
      'Ainda não há canais neste espaço de trabalho.';

  @override
  String get guardrailClassFileDelete => 'Eliminar um ficheiro';

  @override
  String get guardrailClassFileWriteOutsideWorktree =>
      'Escrever fora da árvore de trabalho';

  @override
  String get guardrailClassGitCommit => 'Criar um commit';

  @override
  String get guardrailClassGitPush => 'Fazer push para um remoto';

  @override
  String get guardrailClassPrCreate => 'Abrir um pull request';

  @override
  String get guardrailClassPrPublish => 'Publicar uma revisão ou fazer merge';

  @override
  String get guardrailClassVendorSyncWrite => 'Escrever num rastreador externo';

  @override
  String get guardrailClassNetworkEgress => 'Aceder à rede';

  @override
  String get guardrailClassSecretAccess => 'Ler um segredo';

  @override
  String get guardrailClassPackageInstall => 'Instalar um pacote';

  @override
  String get guardrailClassProcessSpawn => 'Executar um processo';

  @override
  String get guardrailClassWorkspaceMutation =>
      'Alterar a estrutura do espaço de trabalho';

  @override
  String get guardrailDecisionAllow => 'Permitir';

  @override
  String get guardrailDecisionPrompt => 'Perguntar primeiro';

  @override
  String get guardrailDecisionDeny => 'Negar';

  @override
  String get guardrailSourceThisScope => 'Este âmbito';

  @override
  String get guardrailSourceDefault => 'Predefinição';

  @override
  String get guardrailSourcePreset => 'Predefinição do modo';

  @override
  String get guardrailSourceInherited => 'Herdado';

  @override
  String get guardrailClearToInherited => 'Repor para o valor herdado';

  @override
  String get guardrailWhatIf => 'E se?';

  @override
  String get guardrailWhatIfDescription =>
      'Veja como as regras atuais resolveriam uma ação, com a mesma lógica aplicada aos agentes.';

  @override
  String get guardrailProbeActionLabel => 'Ação';

  @override
  String get guardrailProbeCommandLabel => 'Comando (opcional)';

  @override
  String get guardrailProbeCommandHint => 'ex. git push origin main';

  @override
  String get guardrailProbeAgentLabel => 'Agente (opcional)';

  @override
  String get guardrailProbeChannelLabel => 'Canal (opcional)';

  @override
  String get guardrailProbeNone => 'Nenhum';

  @override
  String get guardrailProbeModeLabel => 'Modo';

  @override
  String get guardrailProbeResult => 'Resultado';

  @override
  String get guardrailProbeSource => 'Origem:';

  @override
  String get guardrailAdapterMatrix => 'Onde as regras são aplicadas';

  @override
  String get guardrailAdapterMatrixDescription =>
      'Referência honesta: onde cada efeito é realmente intercetado, por executor de agente. Documenta a realidade, não uma garantia — efeitos que um executor realiza fora do circuito não podem ser intercetados.';

  @override
  String get guardrailEffectColumn => 'Efeito';

  @override
  String get guardrailAdapterHarness => 'Harness integrado';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'Base da sandbox';

  @override
  String get guardrailEnforcementPolicyGate => 'Controlo por política';

  @override
  String get guardrailEnforcementSandbox => 'Apenas sandbox';

  @override
  String get guardrailEnforcementNone => 'Não aplicável';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'A decisão de permissão é verificada antes de o efeito ser executado e pode bloqueá-lo.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'Apenas a sandbox o limita; a regra de permissão não é consultada.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'A decisão é apenas indicativa — não pode ser intercetada aqui.';

  @override
  String get obsStatCost => 'custo';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount delegado';
  }

  @override
  String get obsStatDuration => 'duração';

  @override
  String get obsStatTokens => 'tokens';

  @override
  String get obsStatTools => 'ferramentas';

  @override
  String get openAgentActivity => 'Abrir atividade';

  @override
  String get orgChart => 'Organograma';

  @override
  String get orgChartEmpty => 'Ainda não há agentes';

  @override
  String get navCalendar => 'Calendário';

  @override
  String get serverConnection => 'Conexão com o servidor';

  @override
  String get serverConnectionMode => 'Modo';

  @override
  String get serverModeLocal => 'Executar neste aplicativo';

  @override
  String get serverModeLocalDescription =>
      'O Control Center executa o próprio servidor nesta máquina e mantém seus dados localmente.';

  @override
  String get serverModeRemote => 'Conectar a uma instância remota';

  @override
  String get serverModeRemoteDescription =>
      'Conecte-se a um servidor do Control Center em execução em outro lugar. Seus dados ficam nesse servidor.';

  @override
  String get serverRemoteUrl => 'URL do servidor';

  @override
  String get serverRemoteDeviceId => 'ID do dispositivo';

  @override
  String get serverRemotePairingKey => 'Chave de pareamento';

  @override
  String get serverRemotePairingKeyHint =>
      'Cole a chave de pareamento do servidor remoto';

  @override
  String get serverSetupInviteCode => 'Código de convite';

  @override
  String get serverSetupInviteCodeHint =>
      'Cole um código de convite de uso único (deixe vazio para usar uma chave de pareamento)';

  @override
  String get serverDiscoveryTooltip => 'Procurar servidores na sua rede';

  @override
  String get serverDiscoveryTitle => 'Servidores na sua rede';

  @override
  String get serverDiscoverySearching => 'A procurar servidores…';

  @override
  String get serverDiscoveryEmpty =>
      'Nenhum servidor encontrado. Verifique se o servidor está em execução e se este dispositivo consegue alcançá-lo, e procure novamente.';

  @override
  String get serverDiscoveryRefresh => 'Procurar novamente';

  @override
  String get serverListActive => 'Ativo';

  @override
  String get serverListSwitch => 'Alternar';

  @override
  String get serverListAddTitle => 'Adicionar servidor';

  @override
  String get serverListRemoveActiveHint =>
      'Alterne para outro servidor antes de remover este.';

  @override
  String get serverSwitchFailedTitle => 'Não foi possível alternar de servidor';

  @override
  String get serverListInsecureBadge => 'Inseguro';

  @override
  String get connectionPathLocal => 'Local';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'Encerrando';

  @override
  String get shutdownSubtitle => 'Fechando o servidor local';

  @override
  String get shutdownServiceApprovals => 'Aprovações';

  @override
  String get shutdownServiceBackgroundJobs => 'Tarefas em segundo plano';

  @override
  String get shutdownServiceScheduler => 'Agendador de tarefas';

  @override
  String get shutdownServiceCalendar => 'Sincronização da agenda';

  @override
  String get shutdownServiceWeather => 'Clima';

  @override
  String get shutdownServiceSoundscape => 'Paisagem sonora';

  @override
  String get shutdownServiceMeetings => 'Reuniões';

  @override
  String get shutdownServiceVoiceModels => 'Modelos de voz';

  @override
  String get shutdownServiceNetworking => 'Rede';

  @override
  String get shutdownServicePresence => 'Presença';

  @override
  String get shutdownServiceDataSync => 'Sincronização de dados';

  @override
  String get shutdownServiceDeviceRelay => 'Retransmissão de dispositivos';

  @override
  String get shutdownServiceMcpConnections => 'Conexões MCP';

  @override
  String get shutdownServiceCodeEditors => 'Editores de código';

  @override
  String get serverSharingTitle => 'Compartilhar este servidor';

  @override
  String get serverSharingDescription =>
      'Torne este servidor acessível a partir dos seus outros dispositivos. Nada é exposto publicamente a menos que você ative um túnel abaixo. Os convites de pareamento incluem automaticamente os endereços atuais do servidor; crie-os nas configurações do espaço de trabalho.';

  @override
  String get serverSharingUnavailable =>
      'Os controles de compartilhamento não estão disponíveis neste servidor.';

  @override
  String get serverSharingMdnsLabel => 'Descoberta na LAN';

  @override
  String get serverSharingMdnsOn =>
      'Anunciando este servidor na sua rede local (mDNS)';

  @override
  String get serverSharingMdnsOff =>
      'Este servidor não está sendo anunciado na sua rede local (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'Túnel';

  @override
  String get serverSharingTunnelHelper =>
      'Ativar um túnel torna este servidor acessível pela internet. A exposição pública é opcional e vem desativada por padrão.';

  @override
  String get serverSharingProviderOff => 'Desativado';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'URL pública';

  @override
  String get serverSharingTunnelStarting => 'Iniciando o túnel…';

  @override
  String serverSharingTunnelError(String error) {
    return 'Erro no túnel: $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'O túnel está ativo. Acesse-o pelo seu nome de host DNS configurado.';

  @override
  String get serverSharingRelayLabel => 'Retransmissão';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'Retransmitido este mês: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'Sessões de retransmissão ativas: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle =>
      'Não foi possível atualizar o compartilhamento';

  @override
  String get serverConnectionRestartHint =>
      'Reinicie o Control Center para aplicar as alterações de conexão.';

  @override
  String get serverConnectionReloadHint =>
      'Recarregue a página para reconectar com estas alterações.';

  @override
  String get pairNewClient => 'Emparelhar um novo cliente';

  @override
  String get pairClientNameHint =>
      'Dê um nome a este cliente (ex.: Notebook de trabalho)';

  @override
  String get pairClientTypeWeb => 'Navegador web';

  @override
  String get pairClientTypeDesktop => 'App de desktop';

  @override
  String get pairClientTypePhone => 'Telefone';

  @override
  String get pairAction => 'Emparelhar';

  @override
  String get revoke => 'Revogar';

  @override
  String get pairCredentialsIntro =>
      'Conecte o novo cliente com estes dados, ou abra o link nele.';

  @override
  String get pairLinkLabel => 'Link';

  @override
  String get pairScanQr =>
      'Leia este código QR com a câmera do seu telefone para emparelhá-lo.';

  @override
  String get pairServerUnreachableTitle => 'Inacessível';

  @override
  String get pairServerUnreachable =>
      'Outros dispositivos não conseguem acessar este servidor diretamente, então um novo cliente não pode conectar. Defina a URL pública do servidor para emparelhar mais clientes.';

  @override
  String get serverSetupTitle => 'Como o Control Center deve ser executado?';

  @override
  String get serverSetupSubtitle =>
      'O Control Center precisa de um servidor que seja o dono dos seus dados. Execute um neste aplicativo ou conecte-se a uma instância em execução em outro lugar.';

  @override
  String get serverSetupRunLocal => 'Executar neste aplicativo';

  @override
  String get serverSetupConnect => 'Conectar';

  @override
  String get serverSetupInvalidUrl =>
      'Insira uma URL de servidor ws:// ou wss:// válida.';

  @override
  String get serverSetupCouldNotConnect => 'Não foi possível conectar';

  @override
  String get serverSetupErrorUnreachable =>
      'Não conseguimos alcançar o servidor. Verifique se ele está em execução e se este dispositivo consegue alcançá-lo (mesma rede ou relay).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'A identidade do servidor não corresponde à salva neste dispositivo. Se o servidor foi reinstalado ou redefinido, remova o servidor salvo e emparelhe novamente.';

  @override
  String get serverSetupErrorAuthRejected =>
      'O servidor rejeitou este dispositivo. Verifique se a chave de emparelhamento e o id do dispositivo correspondem aos emitidos pelo servidor.';

  @override
  String get serverSetupErrorInviteRejected =>
      'Esse código de convite é inválido ou expirou. Peça um novo.';

  @override
  String get serverSetupErrorGeneric =>
      'Ocorreu um erro ao conectar. Expanda os detalhes técnicos abaixo para mais informações.';

  @override
  String get serverSetupErrorDetails => 'Detalhes técnicos';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mais $count',
      one: 'mais 1',
    );
    return '$_temp0';
  }

  @override
  String get calendarViewMonth => 'Mês';

  @override
  String get calendarViewWeek => 'Semana';

  @override
  String get calendarViewAgenda => 'Agenda';

  @override
  String get calendarConnectGoogle => 'Conectar o Google Calendar';

  @override
  String get calendarConnectDescription =>
      'Sincronize o seu Google Calendar para ver os eventos aqui e receber alertas antes do início das reuniões.';

  @override
  String get calendarDisconnect => 'Desconectar';

  @override
  String get calendarReconnect => 'Reconectar';

  @override
  String get calendarEmptyNoEvents => 'Nenhum evento neste intervalo';

  @override
  String get calendarStartRecording => 'Iniciar gravação';

  @override
  String get calendarStartRecordingAndLink => 'Gravar e vincular';

  @override
  String get calendarJoinMeet => 'Entrar na reunião';

  @override
  String get calendarFromCalendar => 'Do calendário';

  @override
  String get calendarLinkedMeeting => 'Reunião vinculada';

  @override
  String get calendarToday => 'Hoje';

  @override
  String get calendarAllDay => 'Dia inteiro';

  @override
  String calendarWeekNumber(int number) {
    return 'Semana $number';
  }

  @override
  String get calendarPreviousPeriod => 'Anterior';

  @override
  String get calendarNextPeriod => 'Próximo';

  @override
  String calendarLastSynced(String time) {
    return 'Sincronizado $time';
  }

  @override
  String get calendarNeverSynced => 'Ainda não sincronizado';

  @override
  String get calendarSyncing => 'Sincronizando…';

  @override
  String get calendarViewDay => 'Dia';

  @override
  String get calendarSectionCalendars => 'Calendários';

  @override
  String get calendarShow => 'Mostrar';

  @override
  String get calendarHide => 'Ocultar';

  @override
  String get calendarRsvpGoing => 'Vai participar?';

  @override
  String get calendarRsvpYes => 'Sim';

  @override
  String get calendarRsvpNo => 'Não';

  @override
  String get calendarRsvpMaybe => 'Talvez';

  @override
  String get calendarRsvpFailed => 'Não foi possível atualizar a sua resposta';

  @override
  String get calendarAddAccount => 'Adicionar conta de calendário';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Conecte uma conta Google para sincronizar eventos neste espaço de trabalho.';

  @override
  String get calendarNotConnected => 'Nenhuma conta Google conectada';

  @override
  String get calendarConnecting => 'Conectando…';

  @override
  String get calendarSyncNow => 'Sincronizar agora';

  @override
  String get calendarNoWorkspace =>
      'Selecione um espaço de trabalho para ver o seu calendário';

  @override
  String get calendarConnectError =>
      'Não foi possível conectar o Google Calendar';

  @override
  String get calendarClientIdLabel => 'ID do cliente';

  @override
  String get calendarClientSecretLabel => 'Segredo do cliente';

  @override
  String get calendarConnectCredsHint =>
      'Insira o ID do cliente e o segredo OAuth (device-code) do seu projeto Google. O servidor faz a conexão e a sincronização — o seu navegador nunca guarda os tokens.';

  @override
  String get calendarConnectApproveInstruction =>
      'Abra a página de verificação em qualquer dispositivo, faça login e insira este código:';

  @override
  String get calendarConnectOpenPage => 'Abrir página de verificação';

  @override
  String get calendarConnectWaiting => 'Aguardando aprovação…';

  @override
  String get calendarConnectDenied =>
      'A autorização foi negada. Tente novamente.';

  @override
  String get calendarConnectExpired => 'O código expirou. Tente novamente.';

  @override
  String get calendarNotConfigured =>
      'O Google Calendar não está configurado. Defina GOOGLE_OAUTH_CLIENT_ID para conectar uma conta.';

  @override
  String get notificationMeetingStartsSoon => 'Reunião prestes a começar';

  @override
  String get notifyMeetingStartsSoon =>
      'Quando uma reunião do calendário está prestes a começar';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Calendário desconectado';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Reconecte $email para retomar a sincronização';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Reconecte seu calendário para retomar a sincronização';

  @override
  String get notifyCalendarAuthExpired =>
      'Quando uma conta de calendário precisa ser reconectada';

  @override
  String get calendarAlertLeadTime => 'Antecedência do alerta';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'Com quanto tempo antes de uma reunião avisar você';

  @override
  String calendarConnectedAs(String email) {
    return 'Conectado como $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count participantes';
  }

  @override
  String get calendarEventLabel => 'Evento';

  @override
  String get calendarRecurring => 'Evento recorrente';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Organizador';

  @override
  String get calendarYou => 'Você';

  @override
  String get calendarShowFewer => 'Mostrar menos';

  @override
  String get calendarRsvpAwaiting => 'Pendente';

  @override
  String calendarParticipantsCount(int count) {
    return '$count participantes';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'Ver todos os $count participantes';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count sim';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count não';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count talvez';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count pendentes';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count minutos';
  }

  @override
  String get openInEditorPrompt => 'Abrir em qual editor?';

  @override
  String get ideNotInstalled => 'Não instalado';

  @override
  String openInIde(String editor) {
    return 'Abrir no $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'Não foi possível abrir o $editor: $error';
  }

  @override
  String get profileSearchHint => 'Pesquisar pull requests…';

  @override
  String get profileClickToLoad => 'Clique para carregar';

  @override
  String get byAuthorPrefix => 'por';

  @override
  String get stopAgentRun => 'Parar execução';

  @override
  String get stopAgentRunConfirm =>
      'Parar esta execução? O trabalho em curso será perdido.';

  @override
  String get youLabel => 'você';

  @override
  String get readyToMerge => 'Pronto para mesclar';

  @override
  String get inProgress => 'Em andamento';

  @override
  String get needsAttention => 'Requer atenção';

  @override
  String get drafts => 'Rascunhos';

  @override
  String get allOpenPrs => 'Todas as PRs abertas';

  @override
  String showAllCount(int count) {
    return 'Mostrar todas ($count)';
  }

  @override
  String get sortOldest => 'Mais antigas';

  @override
  String get sortLargest => 'Maiores';

  @override
  String get prFilterTooltip => 'Filtrar';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filtros ativos',
      one: '1 filtro ativo',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'Adicionar filtro…';

  @override
  String get prFilterFieldHint => 'Filtrar…';

  @override
  String get prFilterCategoryStatus => 'Status';

  @override
  String get prFilterCategoryAuthor => 'Autor';

  @override
  String get prFilterCategoryReviewer => 'Revisores';

  @override
  String get prFilterCategoryContent => 'Conteúdo';

  @override
  String get prFilterCategoryRepoOwner => 'Proprietário do repositório';

  @override
  String get prFilterCategoryRepoName => 'Nome do repositório';

  @override
  String get prFilterCategoryOpenedDate => 'Data de abertura';

  @override
  String get prFilterCategoryUpdatedDate => 'Data de atualização';

  @override
  String get prFilterQuickToReview => 'Rápido de revisar';

  @override
  String get prFilterClearAll => 'Limpar filtros';

  @override
  String prFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests',
      one: '1 pull request',
    );
    return '$_temp0';
  }

  @override
  String prFilterHiddenOptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opções que não correspondem a nenhum pull request',
      one: '1 opção que não corresponde a nenhum pull request',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'O título ou o corpo contém…';

  @override
  String get prFilterNoOptions => 'Nenhuma opção correspondente';

  @override
  String get prFilterChipIs => 'é';

  @override
  String get prFilterChipIsAnyOf => 'é um de';

  @override
  String get prFilterChipContains => 'contém';

  @override
  String get prFilterChipSince => 'desde';

  @override
  String get prFilterAddFilterButton => 'Adicionar filtro';

  @override
  String prFilterClearCategory(String category) {
    return 'Limpar filtro de $category';
  }

  @override
  String get prFilterCurrentUser => 'Usuário atual';

  @override
  String get prStatusDraft => 'Rascunho';

  @override
  String get prStatusOpen => 'Aberto';

  @override
  String get prStatusInReview => 'Em revisão';

  @override
  String get prStatusChangesRequested => 'Alterações solicitadas';

  @override
  String get prStatusApproved => 'Aprovado';

  @override
  String get prStatusMerged => 'Mesclado';

  @override
  String get prStatusClosed => 'Fechado';

  @override
  String get prDateWindowDay => 'há 1 dia';

  @override
  String get prDateWindowThreeDays => 'há 3 dias';

  @override
  String get prDateWindowWeek => 'há 1 semana';

  @override
  String get prDateWindowMonth => 'há 1 mês';

  @override
  String get prDateWindowThreeMonths => 'há 3 meses';

  @override
  String get prDateWindowSixMonths => 'há 6 meses';

  @override
  String get prDateWindowYear => 'há 1 ano';

  @override
  String get prDisplayOptions => 'Opções de exibição';

  @override
  String get prDisplayGrouping => 'Agrupamento';

  @override
  String get prDisplayOrdering => 'Ordenação';

  @override
  String get prDisplayShowDrafts => 'Mostrar rascunhos';

  @override
  String get prDisplayMergedWindow => 'Janela de merge';

  @override
  String get prDisplayMergedWindowDay => 'Último dia';

  @override
  String get prDisplayMergedWindowWeek => 'Última semana';

  @override
  String get prDisplayMergedWindowMonth => 'Último mês';

  @override
  String get prDisplayProperties => 'Propriedades de exibição';

  @override
  String get prGroupingRepository => 'Repositório';

  @override
  String get prGroupingAuthor => 'Autor';

  @override
  String get prGroupingStatus => 'Status';

  @override
  String get prGroupingNone => 'Sem agrupamento';

  @override
  String get prPropertyRepository => 'Repositório';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'Branch';

  @override
  String get prPropertyUpdated => 'Atualizado';

  @override
  String get prPropertyAuthor => 'Autor';

  @override
  String get prPropertyChecks => 'Verificações';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'Comentários';

  @override
  String get prGroupUnknownAuthor => 'Autor desconhecido';

  @override
  String get keybindingOpenFilterMenu => 'Abrir o menu de filtros';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'Abrir o menu de filtros de PR';

  @override
  String get selectAction => 'Selecionar';

  @override
  String mergeCountReady(int count) {
    return 'Mesclar $count prontas';
  }

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selecionadas',
      one: '1 selecionada',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'Resumo';

  @override
  String get openFullDiff => 'Abrir diff completo';

  @override
  String get viewFiles => 'Ver arquivos';

  @override
  String get checksLabel => 'Verificações';

  @override
  String get commentsLabel => 'Comentários';

  @override
  String get keybindingSelectPr => 'Selecionar PR';

  @override
  String get keybindingMergePr => 'Mesclar PR';

  @override
  String get keybindingPeekPr => 'Espiar PR';

  @override
  String get keybindingToggleSelectionOfTheFocusedPullRequestDescription =>
      'Alternar a seleção da PR em foco';

  @override
  String get keybindingMergeTheFocusedPullRequestDescription =>
      'Mesclar a PR em foco se estiver pronta';

  @override
  String get keybindingExpandOrCollapseTheFocusedPullRequestPeekDescription =>
      'Expandir ou recolher o painel de espiada da PR em foco';

  @override
  String get kbMove => 'mover';

  @override
  String get kbTabs => 'abas';

  @override
  String get kbSearch => 'buscar';

  @override
  String get kbViewed => 'visto';

  @override
  String get kbCollapse => 'recolher';

  @override
  String get appearance => 'Aparência';

  @override
  String get appearanceSettingsDescription => 'Tema, idioma e tipografia.';

  @override
  String get notificationsSettingsDescription =>
      'Escolha quais eventos de agentes e espaços de trabalho notificam você.';

  @override
  String get integrationsSettingsDescription =>
      'Conecte o GitHub, o sistema de tickets e o servidor MCP.';

  @override
  String get advanced => 'Avançado';

  @override
  String get advancedSettingsDescription =>
      'Nomenclatura de branches, busca semântica, conexão com o servidor, comportamento do sistema e registro.';

  @override
  String get agentRegistry => 'Registro de agentes';

  @override
  String get settingsGroupGeneral => 'Geral';

  @override
  String get settingsGroupAgents => 'Agentes';

  @override
  String get settingsGroupResources => 'Recursos';

  @override
  String get settingsGroupWorkspace => 'Workspace';

  @override
  String get settingsGroupSystem => 'Sistema';

  @override
  String get settingsGroupIntegrations => 'Integrações';

  @override
  String get accounts => 'Contas';

  @override
  String get accountsSettingsDescription =>
      'Contas de GitHub, ticketing, calendário e chat.';

  @override
  String get mcpServers => 'Servidores MCP';

  @override
  String get mcpServersSettingsDescription =>
      'Servidor MCP integrado e servidores MCP externos.';

  @override
  String get remoteControlAndDevices => 'Controle remoto e dispositivos';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'Pareie telefones e configure o servidor de controle remoto.';

  @override
  String get voiceAndMeetings => 'Voz e reuniões';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'Transcrição, diarização, perfis de voz e modelos de reuniões.';

  @override
  String get securityAndPrivacy => 'Segurança e privacidade';

  @override
  String get securityAndPrivacySettingsDescription =>
      'Sandboxing, regras de comandos e privacidade.';

  @override
  String get filterSettingsHint => 'Filtrar configurações';

  @override
  String get needsSetupLabel => 'Requer configuração';

  @override
  String noSettingsMatch(String query) {
    return 'Nenhuma configuração corresponde a \"$query\"';
  }

  @override
  String get collapseSidebar => 'Recolher a barra lateral';

  @override
  String get expandSidebar => 'Expandir a barra lateral';

  @override
  String get filterChannelsHint => 'Filtrar canais';

  @override
  String noChannelsMatch(String query) {
    return 'Nenhum canal corresponde a \"$query\"';
  }

  @override
  String get privacy => 'Privacidade';

  @override
  String get sendDiffContentTitle =>
      'Enviar conteúdo do diff para o adaptador de IA';

  @override
  String get diffSharingOnSubtitle =>
      'Linhas de diff brutas são incluídas nos prompts dos agentes para uma revisão mais aprofundada.';

  @override
  String get diffSharingOffSubtitle =>
      'Os agentes usam apenas metadados estruturados (caminhos de arquivos, números de linha, descrição da PR); nenhum código bruto sai do aplicativo.';

  @override
  String get errorReportingTitle => 'Compartilhar relatórios de falhas';

  @override
  String get errorReportingOnSubtitle =>
      'Diagnósticos de falhas, erros e desempenho são enviados para ajudar a corrigir bugs (apenas em versões de produção).';

  @override
  String get errorReportingOffSubtitle =>
      'Os diagnósticos estão desativados. Nenhum relatório de falhas ou erros é enviado.';

  @override
  String get onboardingDiagnosticsTitle => 'Ajude a melhorar o Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Envie diagnósticos de falhas, erros e desempenho para nos ajudar a corrigir problemas mais rápido (apenas em versões de produção). Você pode alterar isso a qualquer momento em Configurações → Privacidade.';

  @override
  String get blocked => 'Bloqueado';

  @override
  String get idle => 'Inativo';

  @override
  String get noRunsYet => 'Sem execuções';

  @override
  String runsInLastSixMonths(String count) {
    return '$count execuções nos últimos 6 meses';
  }

  @override
  String lastActiveAgo(String duration) {
    return 'Ativo há $duration';
  }

  @override
  String get reportsToNobody => 'Sem responsável';

  @override
  String get copyPath => 'Copiar caminho';

  @override
  String get copyRelativePath => 'Copiar caminho relativo';

  @override
  String get pathCopied => 'Caminho copiado para a área de transferência';

  @override
  String get editAgent => 'Editar agente';

  @override
  String get nameRequired => 'O nome é obrigatório';

  @override
  String get titleRequired => 'O título é obrigatório';

  @override
  String get import => 'Importar';

  @override
  String discoverAgentsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count definições de agente encontradas',
      one: '1 definição de agente encontrada',
    );
    return '$_temp0';
  }

  @override
  String get noAgentsToDiscover => 'Nenhum novo agente para importar';

  @override
  String get noAgentsToDiscoverHint =>
      'As definições de agente neste espaço de trabalho já foram importadas.';

  @override
  String get sortByStatus => 'Estado';

  @override
  String get sortByName => 'Nome';

  @override
  String get noMatchingAgents => 'Nenhum agente corresponde ao filtro';

  @override
  String get selectAnAgentHint =>
      'Escolha um agente para ver o estado, a atividade e os detalhes.';

  @override
  String watchVideoOn(String provider) {
    return 'Assistir ao vídeo no $provider';
  }

  @override
  String get branchTemplate => 'Modelo de nome de branch';

  @override
  String get branchTemplateDescription =>
      'Padrão do branch criado ao iniciar um ticket em um worktree isolado.';

  @override
  String branchTemplatePreview(String example) {
    return 'Exemplo: $example';
  }

  @override
  String get deletePipelineRun => 'Excluir execução do pipeline';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Excluir esta execução de \"$template\"? Esta ação não pode ser desfeita.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Erro ao excluir a execução do pipeline: $error';
  }

  @override
  String get deleteTicket => 'Excluir ticket';

  @override
  String deleteTicketConfirm(String title) {
    return 'Excluir \"$title\"? Esta ação não pode ser desfeita.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Erro ao excluir o ticket: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return 'Excluir \"$name\"? Os repositórios vinculados no disco não são afetados.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Erro ao excluir o espaço de trabalho: $error';
  }

  @override
  String get indexCode => 'Indexar código';

  @override
  String get indexing => 'Indexando…';

  @override
  String get indexNoGrammars => 'Gramáticas de código não instaladas';

  @override
  String get indexFailed => 'Falha na indexação';

  @override
  String indexedSymbolsCount(int count) {
    return '$count símbolos indexados';
  }

  @override
  String get nodeConfigAdvanced => 'Avançado';

  @override
  String get nodeConfigReducer => 'Redutor';

  @override
  String get nodeConfigReducerHelp =>
      'Como mesclar quando esta chave de saída já tem um valor';

  @override
  String get nodeConfigTimeoutMs => 'Tempo limite (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Tentativas de repetição';

  @override
  String get nodeConfigContinueOnFail => 'Continuar se esta etapa falhar';

  @override
  String get nodeConfigTeamId => 'ID da equipe';

  @override
  String get nodeConfigDispatchMode => 'Modo de despacho';

  @override
  String get nodeConfigOutputSchema => 'Esquema de saída (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'Esquema JSON que a saída da etapa deve satisfazer';

  @override
  String get diffLineDisplay => 'Linhas longas nos diffs';

  @override
  String get diffLineDisplayDescription =>
      'Quebrar linhas longas ou rolá-las horizontalmente';

  @override
  String get diffLineWrap => 'Quebrar';

  @override
  String get diffLineScroll => 'Rolar horizontalmente';

  @override
  String get actions => 'Ações';

  @override
  String get activate => 'Ativar';

  @override
  String get activity => 'Atividade';

  @override
  String get activityLabel => 'ATIVIDADE';

  @override
  String get activitySearchHint => 'Pesquisar na atividade';

  @override
  String get activityNoMatches =>
      'Nenhuma atividade corresponde aos seus filtros';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end de $total';
  }

  @override
  String get activityPreviousPage => 'Página anterior';

  @override
  String get activityNextPage => 'Página seguinte';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'Limpar filtro';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return 'País $country';
  }

  @override
  String get activitySavedWorkspaceLogo =>
      'Salvou o logo do espaço de trabalho';

  @override
  String activityVerbCreated(String target) {
    return 'Criou $target';
  }

  @override
  String activityVerbUpdated(String target) {
    return 'Atualizou $target';
  }

  @override
  String activityVerbDeleted(String target) {
    return 'Excluiu $target';
  }

  @override
  String activityVerbAdded(String target) {
    return 'Adicionou $target';
  }

  @override
  String activityVerbRemoved(String target) {
    return 'Removeu $target';
  }

  @override
  String activityVerbInvited(String target) {
    return 'Convidou $target';
  }

  @override
  String activityVerbRevoked(String target) {
    return 'Revogou $target';
  }

  @override
  String activityVerbChanged(String target) {
    return 'Alterou $target';
  }

  @override
  String activityVerbStarted(String target) {
    return 'Iniciou $target';
  }

  @override
  String activityVerbStopped(String target) {
    return 'Parou $target';
  }

  @override
  String activityVerbWrote(String target) {
    return 'Escreveu $target';
  }

  @override
  String get activityTargetAgent => 'um agente';

  @override
  String get activityTargetTicket => 'um ticket';

  @override
  String get activityTargetWorkspace => 'um espaço de trabalho';

  @override
  String get activityTargetRepository => 'um repositório';

  @override
  String get activityTargetMember => 'um membro';

  @override
  String get activityTargetInvite => 'um convite';

  @override
  String get activityTargetChannel => 'um canal';

  @override
  String get activityTargetMessage => 'uma mensagem';

  @override
  String get activityTargetCache => 'um cache';

  @override
  String get activityTargetFile => 'um arquivo';

  @override
  String get activityTargetPipeline => 'um pipeline';

  @override
  String get activityTargetTemplate => 'um template';

  @override
  String get activityTargetProvider => 'um provedor';

  @override
  String get activityTargetModel => 'um modelo';

  @override
  String get activityTargetSkill => 'uma habilidade';

  @override
  String get activityTargetTodo => 'uma tarefa';

  @override
  String get activityTargetMeeting => 'uma reunião';

  @override
  String get activityTargetProject => 'um projeto';

  @override
  String get activityTargetTeam => 'uma equipe';

  @override
  String get activityTargetDevice => 'um dispositivo';

  @override
  String get activityTargetPreference => 'uma preferência';

  @override
  String get activityTargetBudget => 'um orçamento';

  @override
  String activityVerbApproved(String target) {
    return 'Aprovou $target';
  }

  @override
  String activityVerbArchived(String target) {
    return 'Arquivou $target';
  }

  @override
  String activityVerbAssigned(String target) {
    return 'Atribuiu $target';
  }

  @override
  String activityVerbBackedUp(String target) {
    return 'Fez backup de $target';
  }

  @override
  String activityVerbCancelled(String target) {
    return 'Cancelou $target';
  }

  @override
  String activityVerbCleared(String target) {
    return 'Limpou $target';
  }

  @override
  String activityVerbClosed(String target) {
    return 'Fechou $target';
  }

  @override
  String activityVerbCommitted(String target) {
    return 'Fez commit de $target';
  }

  @override
  String activityVerbCompacted(String target) {
    return 'Compactou $target';
  }

  @override
  String activityVerbCompleted(String target) {
    return 'Concluiu $target';
  }

  @override
  String activityVerbConnected(String target) {
    return 'Conectou $target';
  }

  @override
  String activityVerbContinued(String target) {
    return 'Continuou $target';
  }

  @override
  String activityVerbDisconnected(String target) {
    return 'Desconectou $target';
  }

  @override
  String activityVerbDispatched(String target) {
    return 'Despachou $target';
  }

  @override
  String activityVerbDrained(String target) {
    return 'Drenou $target';
  }

  @override
  String activityVerbEnrolled(String target) {
    return 'Inscreveu $target';
  }

  @override
  String activityVerbEstimated(String target) {
    return 'Estimou $target';
  }

  @override
  String activityVerbImported(String target) {
    return 'Importou $target';
  }

  @override
  String activityVerbInstalled(String target) {
    return 'Instalou $target';
  }

  @override
  String activityVerbKilled(String target) {
    return 'Encerrou $target';
  }

  @override
  String activityVerbMarked(String target) {
    return 'Marcou $target';
  }

  @override
  String activityVerbMerged(String target) {
    return 'Mesclou $target';
  }

  @override
  String activityVerbOpened(String target) {
    return 'Abriu $target';
  }

  @override
  String activityVerbPaused(String target) {
    return 'Pausou $target';
  }

  @override
  String activityVerbPolled(String target) {
    return 'Sondou $target';
  }

  @override
  String activityVerbPrepared(String target) {
    return 'Preparou $target';
  }

  @override
  String activityVerbProcessed(String target) {
    return 'Processou $target';
  }

  @override
  String activityVerbPublished(String target) {
    return 'Publicou $target';
  }

  @override
  String activityVerbRefined(String target) {
    return 'Refinou $target';
  }

  @override
  String activityVerbRefreshed(String target) {
    return 'Recarregou $target';
  }

  @override
  String activityVerbRegistered(String target) {
    return 'Registrou $target';
  }

  @override
  String activityVerbRenamed(String target) {
    return 'Renomeou $target';
  }

  @override
  String activityVerbReordered(String target) {
    return 'Reordenou $target';
  }

  @override
  String activityVerbResponded(String target) {
    return 'Respondeu a $target';
  }

  @override
  String activityVerbRestored(String target) {
    return 'Restaurou $target';
  }

  @override
  String activityVerbResumed(String target) {
    return 'Retomou $target';
  }

  @override
  String activityVerbRetried(String target) {
    return 'Tentou $target novamente';
  }

  @override
  String activityVerbReverted(String target) {
    return 'Reverteu $target';
  }

  @override
  String activityVerbReviewed(String target) {
    return 'Revisou $target';
  }

  @override
  String activityVerbRan(String target) {
    return 'Executou $target';
  }

  @override
  String activityVerbSelected(String target) {
    return 'Selecionou $target';
  }

  @override
  String activityVerbSent(String target) {
    return 'Enviou $target';
  }

  @override
  String activityVerbStaged(String target) {
    return 'Adicionou $target ao staging';
  }

  @override
  String activityVerbSteered(String target) {
    return 'Direcionou $target';
  }

  @override
  String activityVerbSubmitted(String target) {
    return 'Submeteu $target';
  }

  @override
  String activityVerbSynced(String target) {
    return 'Sincronizou $target';
  }

  @override
  String activityVerbToggled(String target) {
    return 'Alternou $target';
  }

  @override
  String activityVerbUninstalled(String target) {
    return 'Desinstalou $target';
  }

  @override
  String activityVerbUnstaged(String target) {
    return 'Removeu $target do staging';
  }

  @override
  String get activityTargetActionPolicy => 'uma política de ações';

  @override
  String get activityTargetGoalRun => 'uma execução de objetivo';

  @override
  String get activityTargetRunLog => 'um log de execução';

  @override
  String get activityTargetWorkingMemory => 'uma memória de trabalho';

  @override
  String get activityTargetRoutingPolicy => 'uma política de roteamento';

  @override
  String get activityTargetAutonomy => 'uma autonomia';

  @override
  String get activityTargetCalendar => 'um calendário';

  @override
  String get activityTargetChecker => 'um verificador';

  @override
  String get activityTargetEditor => 'um editor';

  @override
  String get activityTargetConfirmation => 'uma confirmação';

  @override
  String get activityTargetTunnel => 'um túnel';

  @override
  String get activityTargetConversation => 'uma conversa';

  @override
  String get activityTargetCredentials => 'umas credenciais';

  @override
  String get activityTargetDictation => 'um ditado';

  @override
  String get activityTargetAgentRun => 'uma execução de agente';

  @override
  String get activityTargetEvalSuite => 'uma suíte de avaliação';

  @override
  String get activityTargetWorker => 'um worker';

  @override
  String get activityTargetWorktree => 'um worktree';

  @override
  String get activityTargetMcpServer => 'um servidor MCP';

  @override
  String get activityTargetMemoryAccessGrant =>
      'uma concessão de acesso à memória';

  @override
  String get activityTargetMemoryDomain => 'um domínio de memória';

  @override
  String get activityTargetMemoryFact => 'um fato de memória';

  @override
  String get activityTargetMemoryPolicy => 'uma política de memória';

  @override
  String get activityTargetFeed => 'um feed';

  @override
  String get activityTargetNote => 'uma nota';

  @override
  String get activityTargetOrchestration => 'uma orquestração';

  @override
  String get activityTargetPipelineRun => 'uma execução de pipeline';

  @override
  String get activityTargetPipelineTrigger => 'um gatilho de pipeline';

  @override
  String get activityTargetPlan => 'um plano';

  @override
  String get activityTargetPlaybook => 'um playbook';

  @override
  String get activityTargetPullRequest => 'um pull request';

  @override
  String get activityTargetReview => 'uma revisão';

  @override
  String get activityTargetProcess => 'um processo';

  @override
  String get activityTargetProviderPolicy => 'uma política de provedor';

  @override
  String get activityTargetReaction => 'uma reação';

  @override
  String get activityTargetReviewChannel => 'um canal de revisão';

  @override
  String get activityTargetReviewStudio => 'um estúdio de revisão';

  @override
  String get activityTargetServerData => 'uns dados do servidor';

  @override
  String get activityTargetSoundscape => 'uma paisagem sonora';

  @override
  String get activityTargetSession => 'uma sessão';

  @override
  String get activityTargetTerminal => 'um terminal';

  @override
  String get activityTargetTicketLink => 'um link de ticket';

  @override
  String get activityTargetTicketSync => 'uma sincronização de tickets';

  @override
  String get activityTargetProfile => 'um perfil';

  @override
  String get activityTargetVoiceProfile => 'um perfil de voz';

  @override
  String get activityTargetWeather => 'uma previsão do tempo';

  @override
  String get activityTargetWorkProduct => 'um produto de trabalho';

  @override
  String get activityChangedMemberRole => 'Alterou o papel de um membro';

  @override
  String get activityChangedMemberRepoAccess =>
      'Alterou o acesso de um membro aos repositórios';

  @override
  String get activityUpdatedGitHubToken => 'Atualizou o token do GitHub';

  @override
  String get activityRefreshedWeather => 'Recarregou a previsão do tempo';

  @override
  String get activitySetWeatherLocation =>
      'Definiu a localização da previsão do tempo';

  @override
  String get activityClearedWeatherLocation =>
      'Limpou a localização da previsão do tempo';

  @override
  String get activityMarkedAllArticlesRead =>
      'Marcou todos os artigos como lidos';

  @override
  String get activityMarkedArticleRead => 'Marcou um artigo como lido';

  @override
  String get activityUpdatedSavedArticle => 'Atualizou um artigo salvo';

  @override
  String get activityTookOverSession => 'Assumiu a sessão';

  @override
  String get activityHandedBackSession => 'Devolveu a sessão';

  @override
  String get activityCommittedAndPushed => 'Fez commit e push';

  @override
  String get activityBackedUpServer => 'Fez backup dos dados do servidor';

  @override
  String get activityMarkedChannelRead => 'Marcou o canal como lido';

  @override
  String get activityRespondedToInvitation => 'Respondeu ao convite do evento';

  @override
  String get activityStartedCalendarConnect =>
      'Iniciou a conexão do calendário';

  @override
  String get activityDisconnectedCalendar => 'Desconectou o calendário';

  @override
  String get activityMarkedFileViewed => 'Marcou um arquivo como visualizado';

  @override
  String get activityRespondedToApproval =>
      'Respondeu a uma solicitação de aprovação';

  @override
  String get activityChangedTunnel => 'Alterou a configuração do túnel';

  @override
  String get activitySentMessageToAgent => 'Enviou uma mensagem ao agente';

  @override
  String get activityOpenedReviewChannel => 'Abriu o canal de revisão';

  @override
  String get activityOpenedMainConversation => 'Abriu a conversa principal';

  @override
  String get activityStartedRecording => 'Iniciou a gravação';

  @override
  String get activityStoppedRecording => 'Parou a gravação';

  @override
  String get activityToggledMcpServer => 'Alternou o servidor MCP';

  @override
  String get activityUpdatedMcpToken => 'Atualizou o token MCP';

  @override
  String get activitySavedApiKey => 'Salvou uma chave de API';

  @override
  String get activityRemovedProviderCredential =>
      'Removeu uma credencial de provedor';

  @override
  String get activityUpdatedLinkedRepos =>
      'Atualizou os repositórios vinculados';

  @override
  String get activityUnlinkedRepo => 'Desvinculou um repositório';

  @override
  String get activityUpdatedActionItem => 'Atualizou um item de ação';

  @override
  String adRulesCount(int count) {
    return '$count regras de anúncios';
  }

  @override
  String get adapter => 'Adaptador';

  @override
  String get adapterLabel => 'Adaptador';

  @override
  String get adapters => 'Adaptadores';

  @override
  String get adaptersAutoDetected =>
      'Executores de agentes detectados automaticamente nesta máquina. Instale as ferramentas CLI ausentes para habilitar executores adicionais.';

  @override
  String get add => 'Adicionar';

  @override
  String get addAComment => 'Adicionar um comentário';

  @override
  String get addAReaction => 'Adicionar uma reação';

  @override
  String get addASuggestion => 'Adicionar uma sugestão';

  @override
  String get addAgent => 'Adicionar agente';

  @override
  String get addAgents => 'Adicionar agentes';

  @override
  String get addAgentsToEnable =>
      'Adicione agentes para ativar a orquestração multi-agente';

  @override
  String get addEmoji => 'Adicionar emoji';

  @override
  String get addFeed => 'Adicionar feed';

  @override
  String get addFromFile => 'Adicionar de arquivo';

  @override
  String get addGif => 'Adicionar GIF';

  @override
  String get addGithubRepoPrompt =>
      'Adicione pelo menos um repositório do GitHub para ver as pull requests';

  @override
  String get addLocalCheckoutDescription =>
      'Adicione um checkout local para começar a direcioná-lo a partir deste espaço de trabalho.';

  @override
  String get addRepository => 'Adicionar repositório';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Adicionar # repositórios',
      one: 'Adicionar repositório',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'Navegue pelas pastas na máquina que executa o servidor e selecione os checkouts git para registrar.';

  @override
  String get selectThisFolder => 'Selecionar esta pasta';

  @override
  String get deselectThisFolder => 'Desselecionar esta pasta';

  @override
  String get goUp => 'Subir';

  @override
  String get noSubfoldersHere => 'Nenhuma subpasta aqui';

  @override
  String get notAGitRepository => 'Esta pasta não é um repositório git.';

  @override
  String get addToken => 'Adicionar token';

  @override
  String get addWorkspace => 'Adicionar espaço de trabalho';

  @override
  String get addWorkspaceEllipsis => 'Adicionar espaço de trabalho…';

  @override
  String get added => 'Adicionado';

  @override
  String get addingEllipsis => 'A adicionar...';

  @override
  String get advancedLabel => 'Avançado';

  @override
  String get agent => 'Agente';

  @override
  String agentCount(int count, int plural) {
    String _temp0 = intl.Intl.pluralLogic(
      plural,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count agente$_temp0';
  }

  @override
  String get agentMdPath => 'Caminho MD do agente';

  @override
  String get agentName => 'Nome do agente';

  @override
  String get agentTitle => 'Título do agente';

  @override
  String get agentUpdated => 'Agente atualizado.';

  @override
  String get agents => 'Agentes';

  @override
  String agentsCount(int count, num plural) {
    return 'Agentes ($count)';
  }

  @override
  String get agentsMentionSection => 'Agentes';

  @override
  String get usersMentionSection => 'Pessoas';

  @override
  String get ticketsMentionSection => 'Tickets';

  @override
  String get pullRequestsMentionSection => 'Pull requests';

  @override
  String get meetingsMentionSection => 'Reuniões';

  @override
  String get entityRefTicketFallback => 'Ticket';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'Reunião';

  @override
  String get aiReview => 'Revisão IA';

  @override
  String get all => 'Tudo';

  @override
  String get allAgentsAlreadyInChannel =>
      'Todos os agentes já estão neste canal.';

  @override
  String get allCommits => 'Todos os commits';

  @override
  String get allSessionsReset =>
      'Todas as sessões de sandbox foram redefinidas.';

  @override
  String get allSources => 'Todas as fontes';

  @override
  String get allow => 'Permitir';

  @override
  String get allowGitPush => 'Permitir git push';

  @override
  String get allowGithubApi => 'Permitir chamadas à API do GitHub';

  @override
  String get allowNetwork => 'Permitir acesso geral à rede';

  @override
  String get apiKeys => 'Chaves API';

  @override
  String get appFont => 'Fonte do app';

  @override
  String get appLogLevelDebugDescription =>
      'Adiciona rastos detalhados - para desenvolvimento.';

  @override
  String get appLogLevelDebugLabel => 'Depuração';

  @override
  String get appLogLevelErrorDescription =>
      'Apenas erros e exceções inesperados.';

  @override
  String get appLogLevelErrorLabel => 'Erro';

  @override
  String get appLogLevelInfoDescription =>
      'Adiciona mensagens de ciclo de vida e estado.';

  @override
  String get appLogLevelInfoLabel => 'Informação';

  @override
  String get appLogLevelNoneDescription => 'Sem saída de consola.';

  @override
  String get appLogLevelNoneLabel => 'Nenhum';

  @override
  String get appLogLevelVerboseDescription =>
      'Tudo. Muito verboso - use apenas para depuração.';

  @override
  String get appLogLevelVerboseLabel => 'Verboso';

  @override
  String get appLogLevelWarningDescription =>
      'Adiciona avisos e problemas recuperáveis.';

  @override
  String get appLogLevelWarningLabel => 'Aviso';

  @override
  String get appTitle => 'Control Center';

  @override
  String get appearanceLanguage => 'Aparência e idioma';

  @override
  String get apply => 'Aplicar';

  @override
  String get approve => 'Aprovar';

  @override
  String get agentApprovalRequired => 'Aprovação necessária';

  @override
  String get approveAndCompact => 'Aprovar e compactar contexto';

  @override
  String get approveAndExecute => 'Aprovar e executar';

  @override
  String get approveAndHire => 'Aprovar e contratar';

  @override
  String get approved => 'Aprovado';

  @override
  String get articlesSubscribed => 'Artigos dos seus feeds inscritos.';

  @override
  String get askAi => 'Ask AI';

  @override
  String get askAiReview => 'Solicitar revisão IA';

  @override
  String get askAiReviewDescription => 'Pedir à IA para revisar esta PR';

  @override
  String get askAnything =>
      'Pergunte qualquer coisa… (@ para mencionar agentes, / para comandos)';

  @override
  String get assignees => 'RESPONSÁVEIS';

  @override
  String get attachFiles => 'Anexar arquivos';

  @override
  String get attachImage => 'Anexar imagem';

  @override
  String get attachedAgents => 'Agentes anexados';

  @override
  String get audioInput => 'Entrada de áudio';

  @override
  String get authentication => 'Autenticação';

  @override
  String get authenticationToken => 'Token de autenticação';

  @override
  String authoredByLabel(String role) {
    return 'Por: $role';
  }

  @override
  String get authorsLabel => 'Autores';

  @override
  String authorsWithCount(int count) {
    return 'Autores · $count';
  }

  @override
  String get autoRecommended => 'Automático (recomendado)';

  @override
  String get available => 'Disponível';

  @override
  String get awaitingYourApproval => 'Aguardando sua aprovação';

  @override
  String get awaitingYourReview => 'Aguardando sua revisão';

  @override
  String get back => 'Voltar';

  @override
  String get backLabel => 'Voltar';

  @override
  String get backend => 'Backend';

  @override
  String get blockAdsDescription =>
      'Bloquear anúncios, rastreadores e banners de cookies';

  @override
  String get blockAdsTrackers =>
      'Bloquear anúncios, rastreadores e banners de cookies';

  @override
  String get blocking => 'Bloqueando';

  @override
  String get bookmarkLabel => 'Favorito';

  @override
  String get briefDescription => 'Breve descrição';

  @override
  String get bugLabel => 'BUG';

  @override
  String get bundledDefaultsNeverUpdated => 'Predefinições nunca atualizadas';

  @override
  String get cached => 'Em cache';

  @override
  String get cancel => 'Cancelar';

  @override
  String get cancelEdit => 'Cancelar edição';

  @override
  String get categoryCreation => 'Criação';

  @override
  String get categoryDeletion => 'Eliminação';

  @override
  String get categoryEditing => 'Edição';

  @override
  String get categoryNavigation => 'Navegação';

  @override
  String get categorySystem => 'Sistema';

  @override
  String get categoryView => 'Visualização';

  @override
  String get change => 'Alterar';

  @override
  String get changesRequested => 'Alterações solicitadas';

  @override
  String get changesSummary => 'Resumo das alterações';

  @override
  String get channelsMentionSection => 'Canais';

  @override
  String get checkForUpdates => 'Verificar atualizações';

  @override
  String get checking => 'Verificando';

  @override
  String get checkingEllipsis => 'Verificando…';

  @override
  String get checkingGhCli => 'Verificando gh CLI…';

  @override
  String get chooseAppFont => 'Escolher fonte do app';

  @override
  String get chooseCodeFont => 'Escolher fonte de código';

  @override
  String get chooseRunner => 'Escolha seu executor de agentes.';

  @override
  String get clear => 'Limpar';

  @override
  String get clickToRetry => 'Clique para tentar novamente';

  @override
  String get close => 'Fechar';

  @override
  String get closeEsc => 'Fechar (Esc)';

  @override
  String get closeKeyboardHint => 'Fechar atalhos de teclado';

  @override
  String get closePanel => 'Fechar painel';

  @override
  String get closeReader => 'Fechar leitor';

  @override
  String get closed => 'Fechado';

  @override
  String get codeFont => 'Fonte de código';

  @override
  String get codeFontLigatures => 'Ligaduras da fonte de código';

  @override
  String get codeFontLigaturesDescription =>
      'Renderizar ligaduras de programação (=>, !=, ->) como glifos combinados no código e nos diffs';

  @override
  String get collapse => 'Recolher';

  @override
  String get commandPalette => 'Paleta de comandos';

  @override
  String get commandPaletteOrgMembers => 'Organization members';

  @override
  String get commandPaletteBrowseTeam => 'Browse team';

  @override
  String get commandPaletteBrowseTeamDesc => 'View all organization members';

  @override
  String get compactDone =>
      'Conversa compactada. O histórico anterior foi resumido.';

  @override
  String get compactNothing =>
      'Nada para compactar ainda. A conversa ainda é curta.';

  @override
  String get compactBusy =>
      'Um agente ainda está trabalhando. Compacte quando o turno terminar.';

  @override
  String get compactUnavailable =>
      'A compactação não está disponível neste servidor.';

  @override
  String get commandsMentionSection => 'Comandos';

  @override
  String get comment => 'Comentário';

  @override
  String get commentOnFile => 'Comentar este arquivo';

  @override
  String get commentOnThisFile => 'Comentar este arquivo';

  @override
  String get commentSelected => 'Comentar seleção';

  @override
  String get commented => 'Comentado';

  @override
  String get commits => 'Commits';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Mostrando os últimos $loaded de $total commits';
  }

  @override
  String get prCloneProgressCloningTitle => 'Clonando repositório';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'Este PR modifica $fileCount arquivos, excedendo o limite da API do GitHub. Clonando o repositório localmente…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'Este PR excede o limite de arquivos da API do GitHub. Clonando o repositório localmente…';

  @override
  String get prCloneProgressFetchingTitle => 'Buscando refs';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Buscando o branch base e a ref do PR…';

  @override
  String get prCloneProgressComputingTitle => 'Calculando diff';

  @override
  String get prCloneProgressComputingSubtitle =>
      'Executando git diff localmente…';

  @override
  String get prCloneProgressErrorTitle => 'Falha ao carregar o diff';

  @override
  String get prCloneProgressErrorSubtitle =>
      'Ocorreu um erro ao clonar ou calcular o diff.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Ainda em andamento… $elapsed decorridos';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Confiança: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'Configurar identidades, prompts e habilidades dos agentes, e ver execuções.';

  @override
  String get configureDefaultRunners =>
      'Configure qual adaptador e modelo são usados para novas conversas e geração de títulos.';

  @override
  String get configuredLabel => 'Configurado.';

  @override
  String get confirmedBy => 'Confirmado por';

  @override
  String get consensus => 'Consenso';

  @override
  String get contentBlockingDescription =>
      'Bloquear anúncios, rastreadores e banners de cookies';

  @override
  String get contentHint => 'O que deve ser memorizado';

  @override
  String get contentLabel => 'Conteúdo';

  @override
  String get contentMarkdown => 'Conteúdo (Markdown)';

  @override
  String get contextWindowSize => 'Tamanho da janela de contexto';

  @override
  String modelContextChip(String size) {
    return 'Modelo · $size';
  }

  @override
  String get continueLabel => 'Continuar';

  @override
  String get conversationMode => 'Modo';

  @override
  String cookieRulesCount(int count) {
    return '$count regras de cookies';
  }

  @override
  String get copied => 'Copiado!';

  @override
  String get copy => 'Copiar';

  @override
  String get copyBaseBranchTooltip => 'Copiar o nome do branch de destino';

  @override
  String get copyHeadBranchTooltip => 'Copiar o nome do branch de origem';

  @override
  String get couldNotCheckGhCli => 'Não foi possível verificar o gh CLI.';

  @override
  String couldNotListDevices(String error) {
    return 'Não foi possível listar dispositivos: $error';
  }

  @override
  String get create => 'Criar';

  @override
  String get createFirstAgent => 'Crie o seu primeiro agente para começar.';

  @override
  String get createOrSelectWorkspace =>
      'Crie ou selecione um espaço de trabalho antes de adicionar repositórios.';

  @override
  String get createPr => 'Criar PR';

  @override
  String get createPullRequest => 'Criar pull request';

  @override
  String get createdByMe => 'Criadas por mim';

  @override
  String createdLabel(String date) {
    return 'Criado: $date';
  }

  @override
  String get currentParticipants => 'Participantes atuais';

  @override
  String get customCapabilitiesDescription =>
      'Capacidades personalizadas para este agente';

  @override
  String get customSystemPrompt =>
      'Prompt do sistema personalizado para este agente...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count dias',
      one: 'há 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Desativar';

  @override
  String get defaultCapabilities => 'Capacidades padrão · novas conversas';

  @override
  String get defaultChat => 'Chat padrão';

  @override
  String defaultPortHint(int port) {
    return 'Padrão: $port.';
  }

  @override
  String get defaultRunners => 'Executores padrão';

  @override
  String get delete => 'Excluir';

  @override
  String get deleteAgent => 'Excluir agente';

  @override
  String deleteAgentConfirm(String name) {
    return 'Excluir \"$name\"? Esta ação não pode ser desfeita.';
  }

  @override
  String get deleteChannel => 'Excluir canal';

  @override
  String deleteConfirmName(String name) {
    return 'Excluir \"$name\"?';
  }

  @override
  String get deleteConversation => 'Excluir conversa';

  @override
  String get deleteConversationConfirm =>
      'Excluir esta conversa? Todas as mensagens serão perdidas.';

  @override
  String get deleteFact => 'Excluir fato';

  @override
  String get deleteFeedBody =>
      'Isso remove o feed e todos os seus artigos em cache. Artigos favoritados deste feed também serão removidos.';

  @override
  String deleteFeedConfirm(String name) {
    return 'Excluir \"$name\"?';
  }

  @override
  String deleteNamedConversation(String name) {
    return 'Eliminar \"$name\"? Todas as mensagens serão perdidas.';
  }

  @override
  String get deletePolicy => 'Excluir política';

  @override
  String get deletePolicyConfirm =>
      'Excluir esta política? Esta ação não pode ser desfeita.';

  @override
  String deleteTopicConfirm(String topic) {
    return 'Eliminar \"$topic\"? Esta ação não pode ser desfeita.';
  }

  @override
  String get deleteWorkspace => 'Excluir espaço de trabalho';

  @override
  String get deny => 'Negar';

  @override
  String get descriptionLabel => 'Descrição';

  @override
  String get detailsLabel => 'Detalhes';

  @override
  String detectedBackend(String label) {
    return 'Detectado: $label';
  }

  @override
  String detectedRunners(int count) {
    return 'Executores detectados ($count)';
  }

  @override
  String get detectingAdapters => 'Detectando adaptadores…';

  @override
  String get detectingGhCli => 'Detectando gh CLI…';

  @override
  String get detectingInputDevices => 'A detetar dispositivos de entrada…';

  @override
  String detectionFailed(String error) {
    return 'Falha na detecção: $error';
  }

  @override
  String diffFailed(String message) {
    return 'Falha no diff: $message';
  }

  @override
  String get disabled => 'Desativado';

  @override
  String get discover => 'Descobrir';

  @override
  String get discoverAgents => 'Descobrir agentes';

  @override
  String get discoverAgentsDescription =>
      'A descoberta de agentes procura ficheiros AGENTS.md e TEAM.md nos caminhos do espaço de trabalho, analisando-os no registo de agentes.\n\nConfigure um espaço de trabalho primeiro e depois use esta funcionalidade para preencher agentes automaticamente.';

  @override
  String get dismissed => 'Descartado';

  @override
  String get domainHint => 'ex: api-performance';

  @override
  String get domainLabel => 'Domínio';

  @override
  String get download => 'Baixar';

  @override
  String get downloadingLabel => 'Baixando';

  @override
  String downloadingModel(int pct) {
    return 'Baixando modelo… $pct%';
  }

  @override
  String get draft => 'Rascunho';

  @override
  String get draftLabel => 'Rascunho';

  @override
  String get edit => 'Editar';

  @override
  String get edited => 'editado';

  @override
  String get editMessage => 'Editar mensagem';

  @override
  String get deleteMessage => 'Excluir mensagem';

  @override
  String get deleteMessageConfirm =>
      'Excluir esta mensagem? Isso não pode ser desfeito.';

  @override
  String get messageDeleted => 'Mensagem excluída';

  @override
  String get searchInConversation => 'Pesquisar na conversa';

  @override
  String get searchMessagesHint => 'Pesquisar mensagens…';

  @override
  String get noMessagesFound => 'Nenhuma mensagem encontrada';

  @override
  String get editFact => 'Editar facto';

  @override
  String get editPolicy => 'Editar política';

  @override
  String get editSuggestedCodeHint => 'Editar código sugerido...';

  @override
  String get editSuggestion => 'Editar sugestão';

  @override
  String get editTheSuggestedCodeHint => 'Editar o código sugerido...';

  @override
  String get egArchitect => 'ex: arquiteto';

  @override
  String get egControlCenter => 'ex: control-center';

  @override
  String get egPlatform => 'ex: macOS';

  @override
  String get egSamuelAlev => 'ex: SamuelAlev';

  @override
  String get egSoftwareArchitect => 'ex: Arquiteto de Software';

  @override
  String get egTheVerge => 'ex: The Verge';

  @override
  String get egTokenLimit => 'ex: 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Falha na instalação: $error';
  }

  @override
  String get embeddingInstalled =>
      'Modelo de embedding local instalado. Busca híbrida habilitada.';

  @override
  String get embeddingModel => 'Modelo de embedding (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Não instalado. A busca volta a ser apenas por palavras-chave até ser habilitado.';

  @override
  String get embeddingRedownloadBody =>
      'Os arquivos do modelo existente serão excluídos e baixados novamente. A busca semântica ficará indisponível até o download ser concluído.';

  @override
  String get embeddingRemoveBody =>
      'A busca semântica será desabilitada até você reinstalá-la. Você pode instalá-la novamente a qualquer momento.';

  @override
  String get speakerDiarization => 'Diarização de falantes';

  @override
  String get diarizationModel => 'Modelo de diarização';

  @override
  String get diarizationInstalled =>
      'Instalado — nomeia cada falante nas transcrições de reuniões';

  @override
  String get diarizationNotInstalled =>
      'Não instalado — os falantes das reuniões não serão separados';

  @override
  String diarizationInstallFailed(String error) {
    return 'Falha na instalação: $error';
  }

  @override
  String get redownloadDiarizationModel =>
      'Baixar novamente o modelo de diarização';

  @override
  String get diarizationRedownloadBody =>
      'Isso remove os modelos de diarização atuais e os baixa novamente.';

  @override
  String get removeDiarizationModel => 'Remover o modelo de diarização';

  @override
  String get diarizationRemoveBody =>
      'Isso exclui os modelos de diarização no dispositivo. As transcrições de reuniões já produzidas não são afetadas.';

  @override
  String get enableMcpServer => 'Ativar servidor MCP';

  @override
  String get enableNotifications => 'Ativar notificações';

  @override
  String get enableSandboxing => 'Ativar sandboxing';

  @override
  String get enabled => 'Ativado';

  @override
  String enterToken(String name) {
    return 'Insira o token $name';
  }

  @override
  String get enterTokenToAuth => 'Insira um token para exigir autenticação';

  @override
  String errorCreatingAgent(String error) {
    return 'Erro ao criar agente: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Erro ao excluir agente: $error';
  }

  @override
  String get errorLoadingAgents => 'Erro ao carregar agentes';

  @override
  String errorWithDetail(String error) {
    return 'Erro: $error';
  }

  @override
  String get errored => 'Com erros';

  @override
  String get exitSelection => 'Sair da seleção';

  @override
  String get expand => 'Expandir';

  @override
  String get extractingLabel => 'Extraindo';

  @override
  String extractingModel(int pct) {
    return 'Extraindo modelo… $pct%';
  }

  @override
  String get fact => 'Fato';

  @override
  String factCount(int count) {
    return '$count facto';
  }

  @override
  String factCountPlural(int count) {
    return '$count factos';
  }

  @override
  String get facts => 'Fatos';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount factos · $policyCount políticas';
  }

  @override
  String get failed => 'Falhou';

  @override
  String failedToDispatch(String error) {
    return 'Falha ao enviar: $error';
  }

  @override
  String get failedToLoad => 'Falha ao carregar';

  @override
  String failedToLoadAgents(String error) {
    return 'Falha ao carregar agentes: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Falha ao carregar feeds: $error';
  }

  @override
  String get failedToLoadGifs => 'Falha ao carregar GIFs';

  @override
  String failedToLoadLogs(String error) {
    return 'Falha ao carregar registros: $error';
  }

  @override
  String get failedToLoadRepos => 'Falha ao carregar repositórios';

  @override
  String get failedToLoadWorkspaces => 'Falha ao carregar espaços de trabalho';

  @override
  String failedToStartAiReview(String error) {
    return 'Falha ao iniciar revisão IA: $error';
  }

  @override
  String get failedToStartMicTest => 'Falha ao iniciar o teste do microfone.';

  @override
  String failedToSubmitReview(String error) {
    return 'Falha ao enviar revisão: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'Falha ao enviar $name: $error';
  }

  @override
  String failedWithError(String error) {
    return 'Falhou: $error';
  }

  @override
  String get failure => 'Falha';

  @override
  String get feedAlreadyExists => 'Já existe um feed com esta URL.';

  @override
  String get feedUrl => 'URL do feed';

  @override
  String get feedUrlExample => 'ex: https://example.com/feed.xml';

  @override
  String get feedUrlExists => 'Já existe um feed com esta URL.';

  @override
  String get feedUrlLabel => 'URL do feed';

  @override
  String feedsCount(int count) {
    return 'Feeds ($count)';
  }

  @override
  String get feedsLabel => 'Feeds';

  @override
  String get filesChanged => 'Arquivos alterados';

  @override
  String filesCount(int count) {
    return '$count ficheiro(s)';
  }

  @override
  String get filesMentionSection => 'Arquivos';

  @override
  String get filterAgents => 'Filtrar agentes...';

  @override
  String get filterAgentsPlaceholder => 'Filtrar agentes…';

  @override
  String get filterFilesHint => 'Filtrar ficheiros...';

  @override
  String get filterLists => 'Listas de filtros';

  @override
  String get filterSkillsPlaceholder => 'Filtrar habilidades…';

  @override
  String get finish => 'Concluir';

  @override
  String get fix => 'Corrigir';

  @override
  String get fixSelected => 'Corrigir selecionado';

  @override
  String get forward => 'Avançar';

  @override
  String get gatesGithubPatPush =>
      'Controla a injeção do PAT do GitHub. Necessário para o agente fazer push.';

  @override
  String get general => 'Geral';

  @override
  String get generalSettingsDescription =>
      'Aparência, tipografia, integrações e servidor MCP.';

  @override
  String get ghCliAuthButPatOverrideBody =>
      'O GitHub CLI está autenticado e pronto, mas um token de acesso pessoal está definido abaixo e será usado em vez dele. Limpe o PAT para usar a autenticação gh CLI.';

  @override
  String get ghCliInstalledAuth =>
      'Instalado. Execute `gh auth login` e depois toque em Atualizar.';

  @override
  String get ghCliNotInstalled =>
      'gh CLI não instalado — instale em cli.github.com.';

  @override
  String get ghCliNotInstalledLabel => 'gh CLI não instalado';

  @override
  String get githubCli => 'GitHub CLI';

  @override
  String get githubCliIntegration => 'Integração com o GitHub CLI';

  @override
  String get githubCliReady => 'O GitHub CLI está autenticado e pronto.';

  @override
  String get githubLink => 'Link do GitHub';

  @override
  String get githubPersonalAccessToken => 'Token de acesso pessoal do GitHub';

  @override
  String get claudeStatusFetchFailed =>
      'Não foi possível contactar status.claude.com';

  @override
  String get claudeStatusOpenInBrowser => 'Abrir status.claude.com';

  @override
  String get githubStatusFetchFailed =>
      'Não foi possível contactar githubstatus.com';

  @override
  String get githubStatusOpenInBrowser => 'Abrir githubstatus.com';

  @override
  String get githubStatusRefresh => 'Atualizar';

  @override
  String githubStatusUpdated(String time) {
    return 'Atualizado $time';
  }

  @override
  String get kimiStatusFetchFailed =>
      'Não foi possível contactar status.moonshot.cn';

  @override
  String get kimiStatusOpenInBrowser => 'Abrir status.moonshot.cn';

  @override
  String get openaiStatusFetchFailed =>
      'Não foi possível contactar status.openai.com';

  @override
  String get openaiStatusOpenInBrowser => 'Abrir status.openai.com';

  @override
  String get serviceStatusMaintenance => 'Manutenção';

  @override
  String get serviceStatusMajorIssues => 'Problemas graves';

  @override
  String get serviceStatusMinorIssues => 'Problemas menores';

  @override
  String get serviceStatusOperational => 'Operacional';

  @override
  String get serviceStatusOutage => 'Interrupção';

  @override
  String get serviceStatusTitle => 'Estado dos serviços';

  @override
  String get serviceStatusUnknown => 'Desconhecido';

  @override
  String lastChecked(String time) {
    return 'Verificado $time';
  }

  @override
  String get lastCheckedRecently => 'Verificado recentemente';

  @override
  String get githubToken => 'Token do GitHub';

  @override
  String get giveYourWorkAHome => 'Dê um lar ao seu trabalho.';

  @override
  String get goBack => 'Voltar';

  @override
  String get goForward => 'Avançar';

  @override
  String get googleFonts => 'Google Fonts';

  @override
  String get hideContainerTerminal => 'Ocultar terminal do contentor';

  @override
  String get hideConversationChanges => 'Ocultar alterações';

  @override
  String get showConversationChanges => 'Mostrar alterações';

  @override
  String get noConversationChanges =>
      'Ainda não há alterações não confirmadas nesta conversa.';

  @override
  String get conversationChangesTitle => 'Alterações';

  @override
  String get high => 'Alto';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count horas',
      one: 'há 1 hora',
    );
    return '$_temp0';
  }

  @override
  String get images => 'Imagens';

  @override
  String get inactive => 'Inativo';

  @override
  String get install => 'Instalar';

  @override
  String get installGhCliBody =>
      'Instale gh em https://cli.github.com/ e execute `gh auth login`, depois toque em Atualizar.';

  @override
  String get installRequired => 'Instalação necessária';

  @override
  String get installedNotSignedIn => 'Instalado - não autenticado';

  @override
  String installedVersion(String version) {
    return 'Instalado $version';
  }

  @override
  String get integrations => 'Integrações';

  @override
  String get invite => 'Convidar';

  @override
  String get inviteAgent => 'Convidar agente';

  @override
  String get isolateAgentExecution => 'Isolar a execução de agentes.';

  @override
  String get justNow => 'agora mesmo';

  @override
  String get keepSandboxing => 'Manter sandboxing';

  @override
  String get keybindingAdapters => 'Adaptadores';

  @override
  String get keybindingAddARepositoryDescription => 'Adicionar um repositório';

  @override
  String get keybindingAddRepository => 'Adicionar repositório';

  @override
  String get keybindingAgents => 'Agentes';

  @override
  String get keybindingApprove => 'Aprovar';

  @override
  String get keybindingApproveThePeerReviewDescription =>
      'Aprovar a revisão por pares';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Marcar ou desmarcar o artigo selecionado';

  @override
  String get keybindingCommandPalette => 'Palete de comandos';

  @override
  String get keybindingConversationTab => 'Separador visão geral';

  @override
  String get keybindingCreateANewAgentDescription => 'Criar um novo agente';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Criar um novo espaço de trabalho';

  @override
  String get keybindingDeleteAgent => 'Eliminar agente';

  @override
  String get keybindingDeleteChannel => 'Eliminar canal';

  @override
  String get keybindingDeleteTheSelectedAgentDescription =>
      'Eliminar o agente selecionado';

  @override
  String get keybindingDeleteTheSelectedChannelDescription =>
      'Eliminar o canal selecionado';

  @override
  String get keybindingDeleteTheSelectedWorkspaceDescription =>
      'Eliminar o espaço de trabalho selecionado';

  @override
  String get keybindingDeleteWorkspace => 'Eliminar espaço de trabalho';

  @override
  String get keybindingFilesChangedTab => 'Separador diff';

  @override
  String get keybindingFocusSearch => 'Focar na busca';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Focar no campo de busca de pull requests';

  @override
  String get keybindingGeneral => 'Geral';

  @override
  String get keybindingGoToAgents => 'Ir para agentes';

  @override
  String get keybindingGoToInbox => 'Ir para a caixa de entrada';

  @override
  String get keybindingGoToMemory => 'Ir para memória';

  @override
  String get keybindingGoToNewsfeed => 'Ir para notícias';

  @override
  String get keybindingGoToPipelines => 'Ir para pipelines';

  @override
  String get keybindingGoToPullRequests => 'Ir para pull requests';

  @override
  String get keybindingGoToTickets => 'Ir para tickets';

  @override
  String get keybindingKeybindings => 'Atalhos';

  @override
  String get keybindingNavigateToTheAgentsRegistryDescription =>
      'Navegar para o registo de agentes';

  @override
  String get keybindingNavigateToTheInboxDescription =>
      'Navegar para a caixa de entrada';

  @override
  String get keybindingNavigateToTheMemoryDescription =>
      'Ir para a base de conhecimento de memória';

  @override
  String get keybindingNavigateToTheNewsfeedDescription =>
      'Navegar para as notícias';

  @override
  String get keybindingNavigateToThePipelinesListDescription =>
      'Ir para a lista de pipelines';

  @override
  String get keybindingNavigateToThePullRequestListDescription =>
      'Navegar para a lista de pull requests';

  @override
  String get keybindingNavigateToTheTicketsBoardDescription =>
      'Ir para o quadro de tickets';

  @override
  String get keybindingNewAgent => 'Novo agente';

  @override
  String get keybindingNewWorkspace => 'Novo espaço de trabalho';

  @override
  String get keybindingNextArticle => 'Artigo seguinte';

  @override
  String get keybindingNextChannel => 'Canal seguinte';

  @override
  String get keybindingNextPr => 'PR seguinte';

  @override
  String get keybindingNextWorkspace => 'Espaço de trabalho seguinte';

  @override
  String get keybindingOpenArticle => 'Abrir artigo';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Abrir ou fechar o popup do seletor de espaço na barra lateral';

  @override
  String get keybindingOpenPr => 'Abrir PR';

  @override
  String get keybindingOpenSettings => 'Abrir definições';

  @override
  String get keybindingOpenTheAdaptersSettingsPageDescription =>
      'Abrir a página de definições de adaptadores';

  @override
  String get keybindingOpenTheAgentsSettingsPageDescription =>
      'Abrir a página de definições de agentes';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Abrir as definições da aplicação';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Abrir a palete de comandos';

  @override
  String get keybindingOpenTheGeneralSettingsPageDescription =>
      'Abrir a página de definições gerais';

  @override
  String get keybindingOpenTheKeybindingsSettingsPageDescription =>
      'Abrir a página de definições de atalhos';

  @override
  String get keybindingOpenTheRepositoriesSettingsPageDescription =>
      'Abrir a página de definições de repositórios';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Abrir o artigo selecionado';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Abrir a pull request selecionada';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Abrir o espaço de trabalho selecionado';

  @override
  String get keybindingOpenTheSkillsSettingsPageDescription =>
      'Abrir a página de definições de habilidades';

  @override
  String get keybindingOpenWorkspace => 'Abrir espaço de trabalho';

  @override
  String get keybindingPreviousArticle => 'Artigo anterior';

  @override
  String get keybindingPreviousChannel => 'Canal anterior';

  @override
  String get keybindingPreviousPr => 'PR anterior';

  @override
  String get keybindingPreviousWorkspace => 'Espaço de trabalho anterior';

  @override
  String get keybindingRefresh => 'Atualizar';

  @override
  String get keybindingRefreshAllFeedsDescription => 'Atualizar todos os feeds';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Atualizar a lista de pull requests';

  @override
  String get keybindingRemoveRepository => 'Remover repositório';

  @override
  String get keybindingRemoveTheSelectedRepositoryDescription =>
      'Remover o repositório selecionado';

  @override
  String get keybindingRepositories => 'Repositórios';

  @override
  String get keybindingRequestChanges => 'Solicitar alterações';

  @override
  String get keybindingRequestChangesOnThePeerReviewDescription =>
      'Solicitar alterações na revisão por pares';

  @override
  String get keybindingRescanForAdaptersDescription => 'Reprocurar adaptadores';

  @override
  String get keybindingSearchInDiff => 'Procurar no diff';

  @override
  String get keybindingSearchWithinTheDiffViewDescription =>
      'Procurar na vista de diff';

  @override
  String get keybindingToggleViewed => 'Alternar visto';

  @override
  String get keybindingMarkTheFocusedFileAsViewedOrUnviewedDescription =>
      'Marcar o ficheiro focado como visto ou não visto';

  @override
  String get keybindingToggleCollapse => 'Alternar colapso';

  @override
  String get keybindingShowFileList => 'Mostrar lista de arquivos';

  @override
  String get keybindingShowFileListDescription =>
      'Voltar a barra lateral do diff para a árvore de arquivos';

  @override
  String get keybindingCollapseOrExpandTheFocusedFileDescription =>
      'Colapsar ou expandir o ficheiro focado';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Selecionar o artigo seguinte';

  @override
  String get keybindingSelectTheNextChannelDescription =>
      'Selecionar o canal seguinte';

  @override
  String get keybindingSelectTheNextPullRequestDescription =>
      'Selecionar a pull request seguinte';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Selecionar o artigo anterior';

  @override
  String get keybindingSelectThePreviousChannelDescription =>
      'Selecionar o canal anterior';

  @override
  String get keybindingSelectThePreviousPullRequestDescription =>
      'Selecionar a pull request anterior';

  @override
  String get keybindingSendMessage => 'Enviar mensagem';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Enviar a mensagem atual';

  @override
  String get keybindingSkills => 'Habilidades';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Alternar entre modo claro e escuro';

  @override
  String get keybindingSwitchToTheConversationTabDescription =>
      'Mudar para o separador de visão geral';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Mudar para o oitavo espaço de trabalho';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Mudar para o quinto espaço de trabalho';

  @override
  String get keybindingSwitchToTheFilesChangedTabDescription =>
      'Mudar para o separador de diff';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Mudar para o primeiro espaço de trabalho';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Mudar para o quarto espaço de trabalho';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Mudar para o espaço de trabalho seguinte';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Mudar para o nono espaço de trabalho';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Mudar para o espaço de trabalho anterior';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Mudar para o segundo espaço de trabalho';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Mudar para o sétimo espaço de trabalho';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Mudar para o sexto espaço de trabalho';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Mudar para o terceiro espaço de trabalho';

  @override
  String get keybindingToggleBookmark => 'Alternar marcador';

  @override
  String get keybindingToggleTheme => 'Alternar tema';

  @override
  String get keybindingToggleWorkspaceSwitcher => 'Alternar seletor de espaço';

  @override
  String get keybindingWorkspace1 => 'Workspace1';

  @override
  String get keybindingWorkspace2 => 'Workspace2';

  @override
  String get keybindingWorkspace3 => 'Workspace3';

  @override
  String get keybindingWorkspace4 => 'Workspace4';

  @override
  String get keybindingWorkspace5 => 'Workspace5';

  @override
  String get keybindingWorkspace6 => 'Workspace6';

  @override
  String get keybindingWorkspace7 => 'Workspace7';

  @override
  String get keybindingWorkspace8 => 'Workspace8';

  @override
  String get keybindingWorkspace9 => 'Workspace9';

  @override
  String get keybindings => 'Atalhos de teclado';

  @override
  String get keybindingsDescription =>
      'Todos os atalhos de teclado. Os atalhos são fixos e não podem ser reatribuídos.';

  @override
  String get killRunning => 'Encerrar em execução';

  @override
  String get klipyNotConfigured => 'KLIPY_APP_KEY não configurada';

  @override
  String get klipyNotConfiguredHint =>
      'Passe --dart-define=KLIPY_APP_KEY=...\nou defina-a no .env antes de executar.';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get latestLabel => 'Recentes';

  @override
  String get leaveACommentEllipsis => 'Deixe um comentário...';

  @override
  String get legendLabel => 'Legenda';

  @override
  String get lessLabel => 'Menos';

  @override
  String get letsPluginTools => 'Vamos conectar suas ferramentas.';

  @override
  String get level => 'Nível';

  @override
  String get loadingAgents => 'Carregando agentes…';

  @override
  String get loadingModels => 'Carregando modelos…';

  @override
  String get loadingProviders => 'Carregando fornecedores…';

  @override
  String get logLevel => 'Nível de log';

  @override
  String get logs => 'Registros';

  @override
  String get low => 'Baixo';

  @override
  String get maintenance => 'Manutenção';

  @override
  String get manageParticipants => 'Gerenciar participantes';

  @override
  String get createTicketFromConversation =>
      'Criar ticket a partir da conversa';

  @override
  String get manageWorkspaces => 'Gerenciar espaços de trabalho';

  @override
  String get reorderWorkspace => 'Reordenar espaço de trabalho';

  @override
  String get masterToggle => 'Interruptor principal';

  @override
  String get matchOsAppearance =>
      'Adaptar a aparência ao sistema operacional ou escolher um modo fixo.';

  @override
  String get mcpActiveAccepting =>
      'O servidor MCP está ativo e aceitando conexões.';

  @override
  String get mcpAuthToken => 'Token de autenticação MCP';

  @override
  String get mcpAuthentication => 'Autenticação';

  @override
  String get mcpAutoStartDescription =>
      'Se desativado, o servidor permanece parado até você iniciá-lo.';

  @override
  String mcpDefaultPort(int port) {
    return 'Padrão: $port';
  }

  @override
  String mcpListeningOn(int port) {
    return 'Escutando em 127.0.0.1:$port';
  }

  @override
  String mcpListeningOnPort(int port) {
    return 'Escutando na porta $port, partilhada com cc_server.';
  }

  @override
  String get mcpNotAvailableOnServer =>
      'O controle do servidor MCP não está disponível no servidor conectado.';

  @override
  String get modelManagedOnServer =>
      'Este modelo é executado no host do servidor e é gerenciado lá.';

  @override
  String get mcpNotRunning =>
      'O servidor não está em execução. Inicie-o para habilitar conexões MCP.';

  @override
  String get mcpRestartPortChanges =>
      'O servidor deve ser reiniciado para aplicar alterações de porta.';

  @override
  String get mcpServer => 'Servidor MCP';

  @override
  String get mcpServerStopped => 'O servidor está parado';

  @override
  String get mcpStatus => 'Status';

  @override
  String get medium => 'Médio';

  @override
  String get memoryDataHint =>
      'Factos e políticas aparecerão aqui à medida que os agentes trabalham.';

  @override
  String get memoryLabel => 'Memória';

  @override
  String get merge => 'Merge';

  @override
  String get merged => 'Mesclado';

  @override
  String get messagePlaceholder =>
      'Mensagem… (@ para mencionar, / para comandos)';

  @override
  String get navConversations => 'Canais';

  @override
  String get microphonePermissionDenied => 'Permissão do microfone negada.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count minutos',
      one: 'há 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Modelo';

  @override
  String get modified => 'Modificado';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count meses',
      one: 'há 1 mês',
    );
    return '$_temp0';
  }

  @override
  String get more => 'Mais';

  @override
  String get moreLabel => 'Mais';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Nome';

  @override
  String get nameAndTitleRequired => 'Nome e título são obrigatórios.';

  @override
  String get nameAndUrlRequired => 'Nome e URL são obrigatórios';

  @override
  String get nameLabel => 'Nome';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Sandbox nativo disponível em $platform.';
  }

  @override
  String get nativeSandboxNeedsInstall =>
      'Instalação necessária para sandbox nativo';

  @override
  String get navObservability => 'Observabilidade';

  @override
  String get navSaved => 'Salvos';

  @override
  String get navSettings => 'Configurações';

  @override
  String get navigateLabel => 'Navegar';

  @override
  String networkBlockCount(int count) {
    return '$count bloqueios de rede';
  }

  @override
  String get neutral => 'Neutro';

  @override
  String get newAgent => 'Novo agente';

  @override
  String get newCommitsPushed =>
      'Novos commits foram enviados — clique para recarregar o diff';

  @override
  String get newFact => 'Novo facto';

  @override
  String get newLabel => 'Novo';

  @override
  String get newPolicy => 'Nova política';

  @override
  String get newsfeed => 'Notícias';

  @override
  String get newsfeedLabel => 'Notícias';

  @override
  String get newsfeedSettingsDescription =>
      'Gerencie seus feeds inscritos e preferências do leitor.';

  @override
  String get newsfeedSettingsTitle => 'Configurações de notícias';

  @override
  String get nextMatch => 'Próxima correspondência (↵)';

  @override
  String get noAccessGrants => 'Não há concessões de acesso configuradas';

  @override
  String get noActiveWorkspace =>
      'Nenhum espaço de trabalho ou repositório ativo selecionado.';

  @override
  String get noActiveWorkspaceCreate => 'Nenhum espaço de trabalho ativo';

  @override
  String get noActiveWorkspaceGithub =>
      'Nenhum espaço de trabalho ativo com um repositório do GitHub.';

  @override
  String get noAgentAssigned => 'Nenhum agente atribuído';

  @override
  String get noAgentProcessesRunning => 'Nenhum processo de agente em execução';

  @override
  String get noAgents => 'Nenhum agente';

  @override
  String get noAgentsDiscovered => 'Nenhum agente descoberto';

  @override
  String get noAgentsDiscoveredHint =>
      'Clique em \"Descobrir\" para procurar ficheiros AGENTS.md ou \"Adicionar agente\" para configurar manualmente';

  @override
  String get noAgentsRegisteredYet => 'Nenhum agente registrado ainda';

  @override
  String get noArticlesYet => 'Ainda não há artigos';

  @override
  String get noArticlesYetBody => 'Os artigos dos seus feeds aparecerão aqui.';

  @override
  String get noData => 'Sem dados';

  @override
  String get noDomains => 'Ainda não há domínios';

  @override
  String get noExecutionLogsYet => 'Ainda não há registos de execução';

  @override
  String get noFacts => 'Ainda não há factos';

  @override
  String get noFeedsYet => 'Ainda não há feeds';

  @override
  String get noFileAnchor =>
      'Nenhuma âncora de arquivo — não é possível postar comentário inline.';

  @override
  String get noFileChangesInScope =>
      'Não há alterações de ficheiros neste âmbito';

  @override
  String get noGifsFound => 'Nenhum GIF encontrado';

  @override
  String get noInputDevicesDetected =>
      'Nenhum dispositivo de entrada detetado — a utilizar a predefinição do sistema.';

  @override
  String get noMatchingFiles => 'Nenhum ficheiro correspondente';

  @override
  String get noMatchingGoogleFonts => 'Nenhuma Google Fonts correspondente.';

  @override
  String get noMemoryData => 'Ainda não há dados de memória';

  @override
  String get noMessagesYet => 'Nenhuma mensagem ainda';

  @override
  String get noModelsAdvertised =>
      'Nenhum modelo divulgado por este adaptador.';

  @override
  String get noOpenPullRequests => 'Nenhum pull request aberto';

  @override
  String get noPolicies => 'Ainda não há políticas';

  @override
  String get noReposInWorkspaceYet =>
      'Ainda não há repositórios neste espaço de trabalho';

  @override
  String get noRunnersDetected =>
      'Nenhum executor detectado ainda. Atualize para escanear novamente.';

  @override
  String get noSavedArticles => 'Ainda não há artigos guardados';

  @override
  String get noSavedArticlesBody => 'Os artigos que guardar aparecerão aqui.';

  @override
  String noShortcutsMatch(String query) {
    return 'Nenhum atalho corresponde a \"$query\"';
  }

  @override
  String get noSystemFonts => 'Nenhuma fonte do sistema detectada.';

  @override
  String get noTokenSet => 'Nenhum token definido — o acesso é irrestrito.';

  @override
  String get noTokenSetUnrestricted =>
      'Nenhum token definido — o acesso é irrestrito.';

  @override
  String get noTokenUnrestricted => 'Sem token — o acesso é irrestrito';

  @override
  String get noWorkingMemory => 'Ainda não há notas de memória de trabalho.';

  @override
  String get noneAllRoles => 'Nenhum (todos os papéis)';

  @override
  String get notAvailable => 'Indisponível';

  @override
  String get notConfiguredLabel => 'Não configurado.';

  @override
  String get notDetected => 'Não detetado';

  @override
  String get notFoundLabel => 'Não encontrado';

  @override
  String get notes => 'Notas';

  @override
  String get notificationAgentFinished => 'Agente finalizado';

  @override
  String get notificationPrMentioned => 'Mencionado em um pull request';

  @override
  String get notificationNewMessages => 'Novas mensagens';

  @override
  String get notificationPrMerged => 'PR mesclada';

  @override
  String get notificationPrPublished => 'PR publicada';

  @override
  String get notificationReviewRequested => 'Revisão solicitada';

  @override
  String get notifications => 'Notificações';

  @override
  String get notifyAgentRunCompleted =>
      'Notificar quando um agente concluir uma execução.';

  @override
  String get notifyPrMentioned =>
      'Notificar quando você for mencionado em um pull request.';

  @override
  String get notifyNewMessages =>
      'Notificar sobre novas mensagens de agentes em outros canais.';

  @override
  String get notifyPrMerged =>
      'Notificar quando uma pull request for mesclada.';

  @override
  String get notifyPrPublished =>
      'Notificar quando um agente publicar uma pull request.';

  @override
  String get notifyReviewRequested =>
      'Notificar quando sua revisão for solicitada em um pull request.';

  @override
  String get onboardingLinuxDescription =>
      'O Control Center pode utilizar containers Linux para isolar a execução de agentes.';

  @override
  String get onboardingMacosDescription =>
      'O Control Center utiliza sandbox nativo no macOS para isolar a execução de agentes.';

  @override
  String get onboardingUnsupportedDescription =>
      'Sandbox não está disponível nesta plataforma. A execução de agentes será sem isolamento.';

  @override
  String get openApplicationSettings => 'Abrir configurações do aplicativo';

  @override
  String get openArticlesBrowserFallback => 'Abrir artigo no navegador';

  @override
  String get openArticlesInApp => 'Abrir artigos no app';

  @override
  String get openContainerTerminal => 'Abrir terminal do contentor';

  @override
  String get openFolder => 'Abrir pasta';

  @override
  String get openInBrowser => 'Abrir no navegador';

  @override
  String get openLabel => 'Abrir';

  @override
  String get openOnGithub => 'Abrir no GitHub';

  @override
  String get openStatus => 'Aberto';

  @override
  String get optionalPersonaDescription => 'Descrição opcional da persona';

  @override
  String get otherLabel => 'Outro';

  @override
  String get ownerOrganization => 'Proprietário / Organização';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get parsingDiff => 'Analisando diff…';

  @override
  String get passed => 'Passou';

  @override
  String get pasteTokenHere => 'Cole o token aqui';

  @override
  String get pasteValueHere => 'Cole o valor aqui';

  @override
  String get patNotNeededGhCli => 'Desnecessário — o gh CLI está conectado.';

  @override
  String get patOverridesGhCli => 'Configurado — substitui o gh CLI.';

  @override
  String get pathLabel => 'Caminho';

  @override
  String get pendingApproval => 'Aguardando sua aprovação';

  @override
  String get persona => 'Persona';

  @override
  String get personaColon => 'Persona:';

  @override
  String get personaOptional => 'Persona (opcional)';

  @override
  String get personalAccessTokenOptional =>
      'Token de acesso pessoal (opcional)';

  @override
  String get planLabel => 'Plano';

  @override
  String get policies => 'Políticas';

  @override
  String get policiesHint =>
      'As políticas aparecerão aqui quando os agentes promoverem factos.';

  @override
  String get policy => 'Política';

  @override
  String get popular => 'Populares';

  @override
  String get port => 'Porta';

  @override
  String get postingEllipsis => 'A publicar...';

  @override
  String get prCommits => 'Commits';

  @override
  String get prDescriptionPlaceholder => 'Descrição da PR em Markdown...';

  @override
  String get prDraftCreated => 'Rascunho de PR criado';

  @override
  String get prMergedBody => 'Uma pull request foi mesclada';

  @override
  String get prMoreActions => 'More actions';

  @override
  String get prTitle => 'Título da PR';

  @override
  String get previewLabel => 'Pré-visualizar';

  @override
  String get previousArticle => 'Artigo anterior';

  @override
  String get previousChannel => 'Canal anterior';

  @override
  String get previousMatch => 'Correspondência anterior (⇧↵)';

  @override
  String get previousPr => 'PR anterior';

  @override
  String get previousWorkspace => 'Espaço anterior';

  @override
  String get priorityReviewsDescription =>
      'Revisões prioritárias e visão geral do repositório.';

  @override
  String get proposeToCreateDomain =>
      'Proponha um facto ou política para criar um.';

  @override
  String get prsCreated => 'PRs criadas';

  @override
  String get prsMerged => 'PRs mescladas';

  @override
  String get publishToGithub => 'Publicar no GitHub';

  @override
  String get published => 'Publicada';

  @override
  String get pullRequestApproved => 'Pull request aprovada';

  @override
  String get pullRequests => 'Pull requests';

  @override
  String get questionLabel => 'PERGUNTA';

  @override
  String get queued => 'Na fila';

  @override
  String get react => 'Reagir';

  @override
  String get readPrsIssuesMetadata =>
      'Permite ao agente ler PRs, issues e metadados do repositório.';

  @override
  String get readerPreferences => 'Preferências do leitor';

  @override
  String get reasoningEffort => 'Esforço de raciocínio';

  @override
  String get recommendLabel => 'RECOMENDAÇÃO';

  @override
  String recordingFromDevice(String device) {
    return 'A gravar de $device.';
  }

  @override
  String get redownload => 'Baixar novamente';

  @override
  String get redownloadEmbeddingModel =>
      'Baixar novamente o modelo de embedding?';

  @override
  String get redownloadVoiceModel => 'Baixar novamente o modelo de voz?';

  @override
  String get refinePlan => 'Refinar plano';

  @override
  String get refiningPlan => 'Refinando plano…';

  @override
  String get refresh => 'Atualizar';

  @override
  String get refreshAll => 'Atualizar tudo';

  @override
  String get refreshAllFeeds => 'Atualizar todos os feeds';

  @override
  String get refreshLabel => 'Atualizar';

  @override
  String get refreshPrData => 'Atualizar dados da PR';

  @override
  String get reject => 'Rejeitar';

  @override
  String get rejected => 'Rejeitado';

  @override
  String get reload => 'Recarregar';

  @override
  String get remove => 'Remover';

  @override
  String get removeBookmark => 'Remover favorito';

  @override
  String get removeEmbeddingModel => 'Remover o modelo de embedding?';

  @override
  String get removeLogo => 'Remover logo';

  @override
  String get removeRepoFromWorkspace =>
      'Remover repositório do espaço de trabalho?';

  @override
  String get removeRepository => 'Remover repositório';

  @override
  String get removeRepositoryConfirm =>
      'Remover repositório do espaço de trabalho?';

  @override
  String get removeVoiceModel => 'Remover o modelo de voz?';

  @override
  String get removed => 'Removido';

  @override
  String get renamed => 'Renomeado';

  @override
  String get reopen => 'Reabrir';

  @override
  String get resolve => 'Resolver';

  @override
  String get replyEllipsis => 'Responder…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name será removido deste espaço de trabalho. Os arquivos locais no disco não são afetados.';
  }

  @override
  String get reportsTo => 'Reporta-se a';

  @override
  String get reportsToOptional => 'Reporta-se a (opcional)';

  @override
  String reposCount(int count) {
    return 'Repositórios ($count)';
  }

  @override
  String get reposDescription =>
      'Os checkouts locais que este espaço de trabalho utiliza.';

  @override
  String get repositories => 'Repositórios';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# repositórios',
      one: '1 repositório',
    );
    return 'Não foi possível adicionar $_temp0: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# repositórios adicionados',
      one: 'Repositório adicionado',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'Configurações de repositórios';

  @override
  String get repositoryName => 'Nome do repositório';

  @override
  String get requestChanges => 'Solicitar alterações';

  @override
  String get requested => 'Solicitado';

  @override
  String get requestedChanges => 'Alterações solicitadas';

  @override
  String get requiredIfGhCliUnavailable =>
      'Necessário se gh CLI não estiver disponível';

  @override
  String requiredRoleLabel(String role) {
    return 'Função necessária: $role';
  }

  @override
  String get requiredRoleOptional => 'Função necessária (opcional)';

  @override
  String get requirements => 'Requisitos';

  @override
  String get reset => 'Redefinir';

  @override
  String get resetAllSandboxes => 'Redefinir todos os sandboxes';

  @override
  String get resolved => 'Resolvido';

  @override
  String get restartServerToApply =>
      'Reinicie o servidor para aplicar as alterações.';

  @override
  String get restartShell => 'Reiniciar shell';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get review => 'Revisão';

  @override
  String get reviewChanges => 'Revisar alterações';

  @override
  String get reviewedByMe => 'Revisadas por mim';

  @override
  String get reviewers => 'REVISORES';

  @override
  String get reviewersActive => 'Revisores ativos';

  @override
  String get roleLabel => 'Função';

  @override
  String get ruleHint => 'A regra da política (markdown suportado)';

  @override
  String get ruleLabel => 'Regra';

  @override
  String get runCompleted => 'Execução concluída';

  @override
  String get runGhAuthLoginBody =>
      'Execute `gh auth login` no seu terminal e depois toque em Atualizar.';

  @override
  String get running => 'Em execução';

  @override
  String get runningLabel => 'em execução';

  @override
  String get runs => 'Execuções';

  @override
  String get runsLabel => 'Execuções';

  @override
  String get sandboxBackendNativeLabel => 'Native sandbox';

  @override
  String get sandboxBackendNoneLabel => 'No isolation';

  @override
  String get sandboxLinuxInstall =>
      'O sandbox nativo no Linux/WSL2 utiliza bubblewrap. Instale com:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'O sandbox nativo está integrado no macOS — utiliza Apple Seatbelt (`sandbox-exec`). Não requer instalação.';

  @override
  String get sandboxPermissions => 'Permissões do sandbox';

  @override
  String get sandboxUnsupported =>
      'O sandbox nativo ainda não é suportado nesta plataforma. Reverte para \"Sem isolamento\".';

  @override
  String get sandboxing => 'Sandboxing';

  @override
  String get sandboxingDescription =>
      'Execute agentes num sandbox ao nível do SO para que não possam aceder à pasta pessoal, chaves SSH ou tokens não concedidos.';

  @override
  String get sandboxingDisabledDescription =>
      'Os agentes executam diretamente no anfitrião com ambiente completo — não recomendado.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Todas as invocações de agentes são encaminhadas através de $backend.';
  }

  @override
  String get save => 'Salvar';

  @override
  String get saveChanges => 'Guardar alterações';

  @override
  String get adapterArguments => 'Argumentos adicionais';

  @override
  String get adapterArgumentsHint => 'Flags CLI adicionais (ex. --yolo)';

  @override
  String get addVariable => 'Adicionar variável';

  @override
  String get environmentVariables => 'Variáveis de ambiente';

  @override
  String get environmentVariablesDescription =>
      'Variáveis de ambiente personalizadas passadas para este adaptador (ex. chaves de API). Armazenadas no chaveiro.';

  @override
  String get resetToDefault => 'Redefinir para o padrão';

  @override
  String get variableKey => 'Chave';

  @override
  String get variableValue => 'Valor';

  @override
  String get savedArticlesDescription => 'Artigos que você salvou.';

  @override
  String get savedLabel => 'Salvos';

  @override
  String get savingChanges => 'A guardar alterações...';

  @override
  String get savingEllipsis => 'Salvando…';

  @override
  String get scopeDiffToCommits =>
      'Filtrar diff por commits — Shift-clique para intervalo';

  @override
  String get searchAgents => 'Pesquisar agentes';

  @override
  String get searchAuthors => 'Pesquisar autores…';

  @override
  String get searchPullRequestsHint => 'Pesquisar… ex. author:@user';

  @override
  String get noPrsMatchSearch => 'Nenhum pull request correspondente';

  @override
  String get noPrsMatchSearchHint =>
      'Nenhum PR aberto corresponde à pesquisa. Tente outros termos ou limpe a pesquisa.';

  @override
  String get searchAuthorsPlaceholder => 'Pesquisar autores…';

  @override
  String get searchFactsHint => 'Procurar factos...';

  @override
  String get searchFonts => 'Pesquisar fontes…';

  @override
  String get searchGifs => 'Procurar GIFs';

  @override
  String get searchGifsHint => 'Procurar GIFs...';

  @override
  String get searchInDiff => 'Pesquisar no diff';

  @override
  String get searchInDiffHint => 'Procurar no diff...';

  @override
  String get searchOrTypeModel => 'Pesquisar ou digitar o nome de um modelo…';

  @override
  String get searchPlaceholder => 'Procurar...';

  @override
  String get searchShortcuts => 'Pesquisar atalhos…';

  @override
  String get shortcutUnavailableInBrowser => 'Indisponível no navegador';

  @override
  String get searching => 'A procurar...';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count segundos',
      one: 'há 1 segundo',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Selecionar adaptador';

  @override
  String get selectAdapterFirst => 'Selecione um adaptador primeiro';

  @override
  String get selectAgentToReportTo => 'Selecione o agente para reportar…';

  @override
  String get selectAnAgent => 'Selecionar um agente';

  @override
  String get selectConversation => 'Selecionar uma conversa';

  @override
  String get selectEffortLevel => 'Selecionar nível de esforço';

  @override
  String get selectLabel => 'Selecionar';

  @override
  String get selectRunner => 'Selecionar um executor';

  @override
  String get semanticSearch => 'Busca semântica';

  @override
  String get send => 'Enviar';

  @override
  String get sendFirstMessage => 'Enviar a primeira mensagem';

  @override
  String get sendMessage => 'Enviar mensagem';

  @override
  String sentFindingsToAgent(int count) {
    return '$count achado(s) enviado(s) ao agente.';
  }

  @override
  String get serverRunning => 'Servidor em execução';

  @override
  String get serverStopped => 'Servidor parado';

  @override
  String setGithubLinkDescription(String name) {
    return 'Defina o proprietário do GitHub e o nome do repositório para $name. Isto é usado para resolver referências de PR e issues como #123 em conteúdo markdown.';
  }

  @override
  String get setLabel => 'Definir';

  @override
  String get setToken => 'Definir token';

  @override
  String get settingsGeneralDescription =>
      'Aparência, tipografia, integrações e servidor MCP.';

  @override
  String get settingsLabel => 'Configurações';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageDescription => 'Escolher o idioma do aplicativo.';

  @override
  String get sharedSecretToken => 'Token secreto compartilhado';

  @override
  String get shortTask => 'Tarefa curta';

  @override
  String get showNativeNotifications =>
      'Mostrar notificações nativas do macOS para eventos.';

  @override
  String get showSuperseded => 'Mostrar substituídos';

  @override
  String get signInWithGhAuth =>
      'Faça login com gh auth login ou adicione um token em Configurações > Chaves API';

  @override
  String get signedIn => 'Conectado.';

  @override
  String signedInAs(String username) {
    return 'Conectado como $username.';
  }

  @override
  String get skillEditor => 'Editor de habilidades';

  @override
  String get skillNameRequired => 'O nome da habilidade é obrigatório.';

  @override
  String skillSaved(String name) {
    return 'Habilidade \"$name\" salva.';
  }

  @override
  String get skillBrowseDisclaimer =>
      'O registro skills.sh não é confiável. O autor, o número de instalações e o selo de editor verificado são apenas indícios de procedência — o veredito da análise abaixo é o verdadeiro sinal de segurança.';

  @override
  String get skillBrowseNoResults =>
      'Nenhuma habilidade corresponde à sua pesquisa.';

  @override
  String get skillBrowsePrompt =>
      'Pesquise no registro skills.sh para instalar uma habilidade.';

  @override
  String get skillBrowseSearchHint => 'Pesquisar em skills.sh…';

  @override
  String get skillFindingLine => 'linha';

  @override
  String get skillInstallAnywayOverride =>
      'Compreendo o risco — instalar mesmo assim';

  @override
  String skillInstallCount(int count) {
    return '$count instalações';
  }

  @override
  String skillInstalled(String slug) {
    return 'Habilidade «$slug» instalada.';
  }

  @override
  String get skillPreviewCapabilities => 'Capacidades';

  @override
  String get skillPreviewFindings => 'Achados';

  @override
  String get skillPreviewGuardedActions => 'Ações protegidas';

  @override
  String get skillPreviewLlmReviewed => 'Revisado por LLM';

  @override
  String get skillPreviewNoCapabilities => 'Nenhuma capacidade declarada.';

  @override
  String get skillPreviewNoFindings => 'Nenhum achado.';

  @override
  String get skillPreviewScanning => 'Analisando habilidade…';

  @override
  String get skillPreviewVerdictLabel => 'Veredito da análise';

  @override
  String get skillPreviewVerdictPass => 'Aprovado';

  @override
  String get skillPreviewVerdictQuarantine => 'Em quarentena';

  @override
  String get skillPreviewVerdictWarn => 'Aviso';

  @override
  String get skillQuarantineWarning =>
      'Esta habilidade foi colocada em quarentena pelo analisador. Instalá-la executa código na sua máquina. Continue apenas se confiar na fonte e tiver revisado os achados.';

  @override
  String get skillSeverityBlocked => 'Bloqueado';

  @override
  String get skillSeverityWarn => 'Aviso';

  @override
  String get skillVerifiedPublisher => 'Editor verificado';

  @override
  String get skillsBrowseTab => 'Explorar';

  @override
  String get skillsInstalledTab => 'Instaladas';

  @override
  String get skills => 'Habilidades';

  @override
  String get skillsColon => 'Habilidades:';

  @override
  String get skillsCommaSeparated => 'Habilidades (separadas por vírgula)';

  @override
  String get skillsLabel => 'HABILIDADES';

  @override
  String get skipAcceptRisk => 'Pular — Eu aceito o risco';

  @override
  String get skipForNow => 'Pular por enquanto';

  @override
  String get skipSandboxing => 'Pular sandboxing';

  @override
  String get skipSandboxingDialogContent =>
      'Tem a certeza de que pretende saltar o sandboxing? Isto permite que os agentes executem código no seu sistema sem isolamento.';

  @override
  String get somethingWentWrong => 'Algo deu errado';

  @override
  String sourceCount(int count) {
    return '$count fonte';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count fontes';
  }

  @override
  String get sourceFacts => 'Factos de origem:';

  @override
  String get splitDiff => 'Diff lado a lado';

  @override
  String get startDmWithAgent => 'Iniciar mensagem direta com agente';

  @override
  String get startLabel => 'Iniciar';

  @override
  String get startOnAppLaunch => 'Iniciar ao abrir o app';

  @override
  String get startServerToAccept =>
      'Inicie o servidor para aceitar conexões MCP.';

  @override
  String get statusLabel => 'Estado';

  @override
  String stepConnect(int number) {
    return 'Passo $number · Conectar';
  }

  @override
  String get stop => 'Parar';

  @override
  String get stopped => 'Parado';

  @override
  String get streaks => 'Sequências';

  @override
  String get strictIdentityCheck => 'Verificação rigorosa de identidade';

  @override
  String get success => 'Sucesso';

  @override
  String get successLabel => 'Sucesso';

  @override
  String get suggestAChange => 'Sugerir uma alteração';

  @override
  String get suggestAChangeEllipsis => 'Sugerir uma alteração...';

  @override
  String get suggestLabel => 'SUGESTÃO';

  @override
  String get superseded => 'Substituído';

  @override
  String get synced => 'Sincronizado';

  @override
  String get systemDefault => 'Predefinição do sistema';

  @override
  String get systemFonts => 'Fontes do sistema';

  @override
  String get systemPrompt => 'Prompt do sistema';

  @override
  String get systemPromptLabel => 'Prompt do sistema';

  @override
  String get talkToControlCenter => 'Fale com o Control Center.';

  @override
  String get tapBadgeDescription => 'Toque em um badge para ver como avançar';

  @override
  String get taskMentionSection => 'Tarefa';

  @override
  String get testLabel => 'Testar';

  @override
  String get theme => 'Tema';

  @override
  String get themeDark => 'Escuro';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get thisCannotBeUndone => 'Esta ação não pode ser desfeita.';

  @override
  String get thisConversation => 'esta conversa';

  @override
  String get ticketLabel => 'TICKET';

  @override
  String get titleDescription => 'Descrição';

  @override
  String get titleLabel => 'Título';

  @override
  String get todayLabel => 'Hoje';

  @override
  String get toggleBookmark => 'Marcar/desmarcar';

  @override
  String get toggleTheme => 'Alternar tema';

  @override
  String get toggleWorkspaceSwitcher => 'Alternar seletor de espaço';

  @override
  String get tokenConfigured =>
      'Configurado — os clientes devem apresentar este token.';

  @override
  String get tokenConfiguredClients =>
      'Configurado — clientes devem apresentar este token.';

  @override
  String tokenName(String name) {
    return 'Token $name';
  }

  @override
  String get topic => 'Tópico';

  @override
  String get topicHint => 'ex: Tech Stack, Design System';

  @override
  String get totalRuns => 'Execuções totais';

  @override
  String trackingParamsCount(int count) {
    return '$count parâmetros de rastreamento';
  }

  @override
  String get typeCommandOrSearch => 'Digite um comando ou pesquise…';

  @override
  String get typography => 'Tipografia';

  @override
  String get unavailable => 'Indisponível';

  @override
  String get unexpectedError => 'Ocorreu um erro inesperado.';

  @override
  String get unifiedDiff => 'Diff unificado';

  @override
  String get unknownAuthor => 'Desconhecido';

  @override
  String get unnamedAgent => 'Agente sem nome';

  @override
  String get updateKey => 'Atualizar chave';

  @override
  String get updateLabel => 'Atualizar';

  @override
  String get updateToken => 'Atualizar token';

  @override
  String updatedDaysAgo(int count) {
    return 'Atualizado há ${count}d';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'Atualizado há ${count}h';
  }

  @override
  String get updatedJustNow => 'Atualizado agora';

  @override
  String updatedMinutesAgo(int count) {
    return 'Atualizado há ${count}min';
  }

  @override
  String get useSandbox => 'Usar sandbox';

  @override
  String get useWorkspaceDefault => 'Usar predefinição do espaço de trabalho';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'Deixe vazio para usar o User-Agent padrão do app. Alguns sites bloqueiam User-Agents que não são de navegador.';

  @override
  String get usingSystemDefaultMicrophone =>
      'A utilizar o microfone predefinido do sistema.';

  @override
  String get viewAll => 'Ver tudo';

  @override
  String get viewLabel => 'Visualizar';

  @override
  String get viewLog => 'Ver registro';

  @override
  String get viewLogs => 'Ver registros';

  @override
  String voiceInstallFailed(String error) {
    return 'Falha na instalação: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Não instalado. Baixa ~200 MB uma vez; executa totalmente no dispositivo.';

  @override
  String get voiceModelNotInstalledLabel => 'Modelo de voz não instalado.';

  @override
  String get voiceRedownloadBody =>
      'Os arquivos do modelo existente serão excluídos e o arquivo de ~200 MB baixado novamente. A transcrição de voz ficará indisponível até o download ser concluído.';

  @override
  String get voiceRemoveBody =>
      'A transcrição de voz será desativada até reinstalá-la. Pode instalá-la novamente a qualquer momento.';

  @override
  String get voiceTranscription => 'Transcrição de voz';

  @override
  String get meetingVad => 'Deteção de fala (Silero VAD)';

  @override
  String get meetingVadDescription =>
      'Um modelo aprendido de atividade de voz que ignora os silêncios para transcrever apenas a fala. Recorre a um limiar de energia quando não está instalado.';

  @override
  String get meetingVadInstalled =>
      'Instalado. A transcrição é filtrada pela fala detetada.';

  @override
  String get meetingVadNotInstalled =>
      'Não instalado — a usar o limiar de energia.';

  @override
  String get meetingModelIncluded => 'Incluído';

  @override
  String get weakIsolationDescription =>
      'Isolamento fraco — apenas limite de namespace, sem limite de kernel.';

  @override
  String get whenOffNoDefaultRoute =>
      'Quando desativado, o sandbox inicia sem uma rota padrão.';

  @override
  String get whenOffServerStaysStopped =>
      'Quando desativado, o servidor permanece parado até você iniciá-lo.';

  @override
  String get whisperBaseEn => 'Whisper base.en (sherpa-onnx)';

  @override
  String get whisperInstalled =>
      'Whisper base.en instalado. Usado pelo botão de microfone do compositor.';

  @override
  String get speechModel => 'Modelo de fala';

  @override
  String get speechModelHint =>
      'Usado para transcrição de reuniões e o microfone do compositor.';

  @override
  String get voiceModelInstalled =>
      'Instalado. Alimenta a transcrição de reuniões e o botão de microfone do compositor.';

  @override
  String get meetingMicSilentWarning =>
      'Seu microfone pode estar mudo — os outros estão falando, mas nada chega ao seu microfone.';

  @override
  String get meetingTemplates => 'Modelos de notas de reunião';

  @override
  String get meetingTemplatesHint =>
      'Adapte o resumo da IA a um tipo de reunião. O modelo ativo aplica-se a resumos novos e reexecutados.';

  @override
  String get meetingTemplateActive => 'Modelo ativo';

  @override
  String get meetingTemplateAdd => 'Adicionar modelo';

  @override
  String get meetingTemplateNewTitle => 'Novo modelo';

  @override
  String get meetingTemplateEditTitle => 'Editar modelo';

  @override
  String get meetingTemplateNameLabel => 'Nome';

  @override
  String get meetingTemplateNameHint => 'ex. Revisão de sprint';

  @override
  String get meetingTemplateInstructionsLabel => 'Instruções';

  @override
  String get meetingTemplateInstructionsHint =>
      'Como a IA deve estruturar e enfatizar estas notas?';

  @override
  String get workingMemory => 'Memória de trabalho';

  @override
  String get workspaceName => 'Nome do espaço de trabalho';

  @override
  String get workspaceNotesScratchpad =>
      'Notas e rascunho do espaço de trabalho';

  @override
  String get workspaceScopedSkills =>
      'Arquivos de habilidades com escopo do espaço de trabalho anexados aos agentes.';

  @override
  String get workspaces => 'Espaços de trabalho';

  @override
  String get writeLabel => 'Escrever';

  @override
  String get writePrivateNotes =>
      'Escreva notas privadas, observações, planos...';

  @override
  String get writeSkillContent =>
      'Escreva o conteúdo da habilidade aqui (Markdown)…';

  @override
  String get xp => 'XP';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count anos',
      one: 'há 1 ano',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'ontem';

  @override
  String get focusModeStart => 'Iniciar sessão de foco';

  @override
  String get focusModeConfigTitle => 'Iniciar sessão de foco';

  @override
  String get focusModeGoalLabel => 'Objetivo';

  @override
  String get focusModeGoalHint => 'Em que está a trabalhar?';

  @override
  String get focusModeDurationLabel => 'Duração';

  @override
  String get focusModeBlockNotifications => 'Bloquear notificações';

  @override
  String get focusModeStartButton => 'Iniciar';

  @override
  String get focusModeEndSession => 'Terminar sessão';

  @override
  String get focusModeExpand => 'Expandir aplicação';

  @override
  String get focusModeFloat => 'Minimizar para barra';

  @override
  String get focusModeActiveTooltip =>
      'Modo de foco ativo — toque para terminar';

  @override
  String get dismiss => 'Dispensar';

  @override
  String get acceptAndResolve => 'Aceitar e resolver';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'Parece que está a fazer muitas revisões seguidas. Descanse um pouco!';
  }

  @override
  String get notificationSound => 'Som de notificação';

  @override
  String get notificationSoundDescription =>
      'Som reproduzido quando uma notificação é mostrada.';

  @override
  String get notificationSoundNone => 'Nenhum';

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
  String get notificationSoundMigrosSoft => 'Migros (soft)';

  @override
  String get notificationSoundMigrosHard => 'Migros (hard)';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => 'Testar';

  @override
  String get notificationVolume => 'Volume';

  @override
  String get viewProfile => 'Ver perfil';

  @override
  String get clearAllFilters => '× Limpar tudo';

  @override
  String acrossNRepos(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Em $countString repos',
      one: 'Em 1 repo',
    );
    return '$_temp0';
  }

  @override
  String get pullRequestsLabel => 'PRs';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Sem PRs de @$login neste espaço de trabalho';
  }

  @override
  String get usersLabel => 'Utilizadores';

  @override
  String get mergePullRequest => 'Merge pull request';

  @override
  String get forceMergePullRequest => 'Force merge pull request';

  @override
  String get closePullRequest => 'Close pull request';

  @override
  String get closePullRequestConfirm =>
      'Are you sure you want to close this pull request?';

  @override
  String get squashAndMerge => 'Squash and merge';

  @override
  String get createMergeCommit => 'Create a merge commit';

  @override
  String get rebaseAndMerge => 'Rebase and merge';

  @override
  String get commitTitle => 'Commit title';

  @override
  String get commitDescription => 'Commit description';

  @override
  String get pullRequestMerged => 'Pull request merged';

  @override
  String get pullRequestClosed => 'Pull request closed';

  @override
  String failedToMergePr(String error) {
    return 'Failed to merge: $error';
  }

  @override
  String failedToClosePr(String error) {
    return 'Failed to close: $error';
  }

  @override
  String get checksFailing => 'Verificações com falha';

  @override
  String get reviewsPending => 'Some reviews are pending';

  @override
  String get confirm => 'Confirm';

  @override
  String get trustedSitesSectionTitle => 'Sites confiáveis';

  @override
  String get trustedSitesEmpty =>
      'Nenhum site confiável. Adicione um domínio para desativar o bloqueio nele.';

  @override
  String get addTrustedSite => 'Adicionar site confiável';

  @override
  String get removeTrustedSite => 'Remover';

  @override
  String get disableBlockingForThisSite => 'Desativar bloqueio neste site';

  @override
  String get enableBlockingForThisSite => 'Ativar bloqueio neste site';

  @override
  String get enterDomainHint => 'ex. exemplo.com';

  @override
  String get invalidDomain => 'Insira um domínio válido (ex. exemplo.com)';

  @override
  String get pageLoadTimedOut =>
      'Carregamento da página esgotado. Recarregue ou abra no navegador.';

  @override
  String get pipelinesScreenTitle => 'Pipelines';

  @override
  String get pipelinesScreenSubtitle =>
      'Declarative multi-step agent workflows';

  @override
  String get pipelinesRunHello => 'Run hello pipeline';

  @override
  String get pipelinesRunPipeline => 'Executar pipeline';

  @override
  String get pipelineRunLauncherTitle => 'Executar pipeline';

  @override
  String get pipelineRunSubtitle =>
      'Escolha um pipeline e preencha as suas entradas para iniciar uma execução.';

  @override
  String get pipelineRunNoInputsBadge => 'Sem entradas';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entradas',
      one: '1 entrada',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'Este pipeline não requer entradas.';

  @override
  String get pipelineRunSubmit => 'Executar pipeline';

  @override
  String get pipelineRunCouldNotStart => 'Não foi possível iniciar a execução.';

  @override
  String pipelineRunStarted(String name) {
    return '$name iniciado';
  }

  @override
  String get pipelineRunEmptyTitle => 'Nenhum pipeline pronto para executar';

  @override
  String get pipelineRunEmptyHint =>
      'Ative um pipeline e ligue a execução manual no seu editor para o iniciar aqui.';

  @override
  String get pipelineRunManageTemplates => 'Gerir pipelines';

  @override
  String get pipelineRunSettingsTitle => 'Execução manual';

  @override
  String get pipelineRunSettingsAllow => 'Permitir execução manual';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Mostrar este pipeline na página de execução para que possa ser iniciado manualmente.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Entradas';

  @override
  String get pipelineRunSettingsAddInput => 'Adicionar entrada';

  @override
  String get pipelineRunSettingsNoInputs => 'Ainda sem entradas.';

  @override
  String get pipelineInputEditTitle => 'Campo de entrada';

  @override
  String get pipelineInputKeyLabel => 'Chave';

  @override
  String get pipelineInputKeyHelp =>
      'Chave de estado onde o valor é guardado (por ex. repoFullName).';

  @override
  String get pipelineInputLabelLabel => 'Rótulo';

  @override
  String get pipelineInputTypeLabel => 'Tipo';

  @override
  String get pipelineInputOptionsLabel => 'Opções (separadas por vírgulas)';

  @override
  String get pipelineInputDefaultLabel => 'Valor predefinido';

  @override
  String get pipelineInputPlaceholderLabel => 'Marcador de posição';

  @override
  String get pipelineInputHelpLabel => 'Texto de ajuda';

  @override
  String get pipelineInputRequiredLabel => 'Obrigatório';

  @override
  String get pipelineInputTypeText => 'Texto';

  @override
  String get pipelineInputTypeMultiline => 'Texto de várias linhas';

  @override
  String get pipelineInputTypeNumber => 'Número';

  @override
  String get pipelineInputTypeBoolean => 'Alternância';

  @override
  String get pipelineInputTypeSelect => 'Seleção';

  @override
  String get pipelinesEmpty => 'No pipeline runs yet';

  @override
  String get pipelinesEmptyHint =>
      'Clique em «Executar pipeline» para iniciar um.';

  @override
  String get pipelinesSelectRun => 'Select a pipeline run to view steps';

  @override
  String get pipelinesNoSteps => 'No steps recorded yet';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Selecione um espaço de trabalho para ver seus pipelines';

  @override
  String pipelinesLoadError(String error) {
    return 'Falha ao carregar pipelines: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Falha ao iniciar pipeline: $error';
  }

  @override
  String get pipelineStatusPending => 'Pending';

  @override
  String get pipelineStatusRunning => 'Running';

  @override
  String get pipelineStatusSuspended => 'Suspended';

  @override
  String get pipelineStatusCompleted => 'Completed';

  @override
  String get pipelineStatusFailed => 'Failed';

  @override
  String get pipelineStatusCancelled => 'Cancelled';

  @override
  String get pipelineStatusSkipped => 'Skipped';

  @override
  String pipelineRunDuration(int seconds) {
    return '${seconds}s';
  }

  @override
  String pipelineStepDuration(int seconds) {
    return '${seconds}s';
  }

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed de $total etapas';
  }

  @override
  String get pipelineWaterfallTimeline => 'Cronologia';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'Ativo $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'inativo $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'Tempo excluído do total ativo: a execução estava parada ou aguardando entre etapas.';

  @override
  String get pipelineStepStarted => 'Iniciado';

  @override
  String get pipelineStepFinished => 'Concluído';

  @override
  String get pipelineStepDurationLabel => 'Duração';

  @override
  String get pipelineStepBranch => 'Ramo';

  @override
  String get pipelineStepViewConversation => 'Ver conversa';

  @override
  String get pipelineStepError => 'Erro';

  @override
  String get pipelineStepInput => 'Entrada';

  @override
  String get pipelineStepOutput => 'Saída';

  @override
  String get pipelineStepNotExecuted => 'Ainda não executado';

  @override
  String get pipelineRunViewTimeline => 'Linha do tempo';

  @override
  String get pipelineRunViewGraph => 'Gráfico';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Falhou em $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Manual';

  @override
  String get pipelineRunTriggerAuto => 'Automático';

  @override
  String get pipelineStepSkippedReason => 'Ignorado';

  @override
  String get pipelineRunColumnPipeline => 'Pipeline';

  @override
  String get pipelineRunColumnDuration => 'Duração';

  @override
  String get pipelineRunColumnStarted => 'Iniciado';

  @override
  String get pipelineRunFilterAll => 'Todos';

  @override
  String get pipelineRunFilterEmpty =>
      'Nenhuma execução corresponde a este filtro';

  @override
  String get relativeJustNow => 'agora mesmo';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count min',
      one: 'há 1 min',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count horas',
      one: 'há 1 hora',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count dias',
      one: 'há 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get automationsTitle => 'Automações';

  @override
  String get automationsSubtitle =>
      'Iniciar pipelines automaticamente quando eventos de domínio são disparados';

  @override
  String get automationsNoTriggers =>
      'Nenhum gatilho configurado para este evento.';

  @override
  String get automationsAddTrigger => 'Adicionar gatilho';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get taskStatusPending => 'Pending';

  @override
  String get taskStatusInProgress => 'In progress';

  @override
  String get taskStatusCompleted => 'Completed';

  @override
  String get taskStatusFailed => 'Failed';

  @override
  String get taskStatusCancelled => 'Cancelled';

  @override
  String get tasksNoTasks => 'Sem tickets';

  @override
  String get teamsTitle => 'Teams';

  @override
  String get teamsNoTeams => 'No teams configured';

  @override
  String get teamsAddTeam => 'Add team';

  @override
  String get teamsManageSubtitle =>
      'Agrupe agentes em equipes e encaminhe o trabalho atribuído por meio de um líder.';

  @override
  String get teamsLoadError => 'Não foi possível carregar as equipes';

  @override
  String get teamsEmptyTitle => 'Nenhuma equipe ainda';

  @override
  String get teamsEmptyDescription =>
      'Agrupe agentes em equipes para que o trabalho atribuído a uma equipe seja encaminhado por um líder que delega.';

  @override
  String get teamCreateTitle => 'Nova equipe';

  @override
  String get teamEditTitle => 'Editar equipe';

  @override
  String get teamNameLabel => 'Nome da equipe';

  @override
  String get teamNameHint => 'ex.: Frontend';

  @override
  String get teamDescriptionLabel => 'Descrição';

  @override
  String get teamDescriptionHint => 'Pelo que esta equipe é responsável';

  @override
  String get teamLeaderLabel => 'Líder';

  @override
  String get teamLeaderHelp =>
      'O coordenador que recebe o trabalho atribuído à equipe e delega ao membro mais adequado.';

  @override
  String get teamNoLeader => 'Sem líder';

  @override
  String get teamInstructionsLabel => 'Instruções operacionais';

  @override
  String get teamInstructionsHelp =>
      'Anexadas ao briefing do líder — convenções da equipe, regras de escalonamento, tom.';

  @override
  String get teamInstructionsHint => 'Opcional';

  @override
  String get teamSaved => 'Equipe salva';

  @override
  String get teamMembersError => 'Não foi possível carregar os membros';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membros',
      one: '1 membro',
      zero: 'Nenhum membro',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'Adicionar membro';

  @override
  String get teamAddMemberTitle => 'Adicionar membros';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Adicionar $count',
      one: 'Adicionar 1',
      zero: 'Adicionar',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => 'Todos os agentes já estão nesta equipe.';

  @override
  String get teamRemoveMember => 'Remover da equipe';

  @override
  String get teamLeaderBadge => 'Líder';

  @override
  String get teamUnknownAgent => 'Agente desconhecido';

  @override
  String get teamMembersEmpty => 'Nenhum membro ainda';

  @override
  String get teamMembersEmptyDescription =>
      'Adicione agentes para que o líder tenha pessoas a quem delegar.';

  @override
  String get teamSelectPrompt => 'Selecione uma equipe';

  @override
  String get teamSelectPromptDescription =>
      'Escolha uma equipe da lista ou crie uma nova.';

  @override
  String get teamDeleteTitle => 'Excluir equipe?';

  @override
  String teamDeleteBody(String name) {
    return '$name será excluída. Seus agentes não são afetados.';
  }

  @override
  String get teamHasLeaderTooltip => 'Tem um líder';

  @override
  String get pipelineRunTitle => 'Pipeline run';

  @override
  String get pipelineNotFound => 'Pipeline run not found';

  @override
  String get pipelineTemplatesNav => 'Modelos de pipeline';

  @override
  String get pipelineTemplatesTitle => 'Modelos de pipeline';

  @override
  String get pipelineTemplatesSubtitle =>
      'Editor de arrastar e soltar para as pipelines que orquestram seus agentes.';

  @override
  String get pipelineTemplatesNew => 'Novo modelo';

  @override
  String get pipelineTemplatesEmpty =>
      'Ainda não há modelos de pipeline. Crie um para começar.';

  @override
  String get pipelineTemplateIdLabel => 'ID do modelo';

  @override
  String get pipelineTemplateBuiltInBadge => 'Integrado';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Excluir modelo?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Excluir o modelo de pipeline $name? Não é possível desfazer.';
  }

  @override
  String get pipelineTemplateSaved => 'Modelo de pipeline salvo';

  @override
  String get pipelineTemplateEditorTitle => 'Editar pipeline';

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Arraste tipos de nós da barra lateral até o canvas e conecte-os.';

  @override
  String get unsavedChanges => 'Alterações não salvas';

  @override
  String get nodeLibraryTitle => 'Biblioteca de nós';

  @override
  String get nodeLibraryHint =>
      'Arraste qualquer item para o canvas para adicionar um nó.';

  @override
  String get editorDragHint =>
      'Arraste da biblioteca, clique em um nó para editar';

  @override
  String get editorEmptyCanvas => 'Arraste um nó da biblioteca para começar.';

  @override
  String get nodeConfigTitle => 'Configuração do nó';

  @override
  String get nodeConfigKind => 'Tipo';

  @override
  String get nodeConfigLabel => 'Rótulo';

  @override
  String get nodeConfigAgent => 'Agente';

  @override
  String get nodeConfigAgentHint => 'Escolher um agente…';

  @override
  String get nodeConfigInputKeys => 'Chaves de entrada (separadas por vírgula)';

  @override
  String get nodeConfigInputKeysHelp =>
      'Chaves de estado que este nó consome. Usadas para a substituição de placeholders no prompt.';

  @override
  String get nodeConfigOutputKey => 'Chave de saída';

  @override
  String get nodeConfigPrompt => 'Modelo de prompt';

  @override
  String get nodeConfigPromptHelp =>
      'Use placeholders com chaves duplas para inserir valores do estado em tempo de execução.';

  @override
  String get nodeConfigScript => 'Script bash';

  @override
  String get nodeConfigScriptHelp =>
      'Executado com bash -c. GITHUB_TOKEN está disponível. Os placeholders são substituídos antes da execução.';

  @override
  String get nodeConfigTriggers => 'Acionado por';

  @override
  String get nodeConfigNoUpstream => 'Não há outros nós para conectar.';

  @override
  String get nodeConfigRouteKeys => 'Chaves de rota';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Chave de rota de $source';
  }

  @override
  String get conditionSectionTitle => 'Condição';

  @override
  String get conditionMode => 'Modo';

  @override
  String get conditionModeFilesAny => 'Arquivo(s) existe(m) — algum';

  @override
  String get conditionModeFilesAll => 'Arquivos existem — todos';

  @override
  String get conditionModeComparison => 'Comparação';

  @override
  String get conditionModeSwitch => 'Comutador';

  @override
  String get conditionFilePaths => 'Caminhos de arquivo';

  @override
  String get conditionFilePathsAnyHelp =>
      'Um caminho por linha, relativo ao diretório base. Retorna true se algum existir.';

  @override
  String get conditionFilePathsAllHelp =>
      'Um caminho por linha, relativo ao diretório base. Retorna true apenas se todos existirem.';

  @override
  String get conditionBaseKey => 'Chave do diretório base';

  @override
  String get conditionBaseKeyHelp =>
      'Chave de estado com o diretório onde os caminhos são resolvidos (padrão repoLocalPath).';

  @override
  String get conditionRecursive => 'Pesquisar subdiretórios';

  @override
  String get conditionNegate => 'Inverter: retorna true se ausente';

  @override
  String get conditionLeft => 'Valor à esquerda';

  @override
  String get conditionOperator => 'Operador';

  @override
  String get conditionRight => 'Valor à direita';

  @override
  String get conditionSwitchKey => 'Comutar pela chave de estado';

  @override
  String get conditionCases => 'Casos (separados por vírgulas)';

  @override
  String get conditionCasesHelp =>
      'Chaves de rota a comparar com o valor, em ordem.';

  @override
  String get conditionDefaultCase => 'Caso padrão';

  @override
  String get triggerPanelTitle => 'Gatilhos';

  @override
  String get triggerPanelHelp => 'O que inicia este pipeline.';

  @override
  String get triggerManualHelp =>
      'Mostrar na página de execução e iniciar manualmente.';

  @override
  String get triggerSectionAutomatic => 'Gatilhos automáticos';

  @override
  String get triggerAddButton => 'Adicionar gatilho';

  @override
  String get triggerNoneYet => 'Ainda não há gatilhos automáticos.';

  @override
  String get triggerAddDialogTitle => 'Adicionar gatilho';

  @override
  String get triggerKindLabel => 'Tipo de gatilho';

  @override
  String get triggerKindEvent => 'Em um evento';

  @override
  String get triggerKindSchedule => 'Em uma programação';

  @override
  String get triggerIntervalLabel => 'Executar a cada (segundos)';

  @override
  String get triggerKindWebhook => 'Através de um webhook';

  @override
  String get triggerScheduleExprLabel => 'Agendamento (cron ou every:segundos)';

  @override
  String get triggerTimezoneLabel => 'Fuso horário (opcional)';

  @override
  String get triggerCatchUpLabel => 'Em execuções perdidas';

  @override
  String get triggerCatchUpRunOnce => 'Executar uma vez';

  @override
  String get triggerCatchUpSkip => 'Ignorar';

  @override
  String get syncHealthTitle => 'Estado da sincronização';

  @override
  String get syncHealthNoConfigs => 'Ainda sem conexões de sincronização';

  @override
  String get syncHealthNeverSynced => 'Nunca sincronizado';

  @override
  String get syncOutcomeOk => 'Sincronizado';

  @override
  String get syncOutcomeFailed => 'Falhou';

  @override
  String get syncOutcomeSkipped => 'Ignorado';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count falhas consecutivas';
  }

  @override
  String get triggerWebhookHelp =>
      'É gerado um URL de webhook assinado. Sistemas externos fazem POST para iniciar este pipeline.';

  @override
  String get triggerEventFieldLabel => 'Evento';

  @override
  String get triggerNoMoreEvents =>
      'Todos os eventos disponíveis já estão configurados.';

  @override
  String get triggerMatchStatusLabel => 'Somente quando o status for';

  @override
  String get triggerSummaryNone => 'Sem gatilhos';

  @override
  String triggerEverySeconds(int seconds) {
    return 'A cada ${seconds}s';
  }

  @override
  String get triggerEventManual => 'Execução manual';

  @override
  String get triggerEventSchedule => 'Programação';

  @override
  String get triggerEventPrStatusChanged => 'Status da PR alterado';

  @override
  String get triggerEventExternalPr => 'PR externa aberta';

  @override
  String get triggerEventPrPublished => 'PR publicada';

  @override
  String get triggerEventPrMerged => 'PR mesclada';

  @override
  String get triggerEventRepoAdded => 'Repositório adicionado';

  @override
  String get triggerEventMessageReceived => 'Mensagem recebida';

  @override
  String get triggerEventTicketCompleted => 'Tarefa concluída';

  @override
  String get triggerEventTicketFailed => 'Tarefa falhou';

  @override
  String get triggerEventTicketCancelled => 'Tarefa cancelada';

  @override
  String get triggerEventBudgetCrossed => 'Limite de orçamento ultrapassado';

  @override
  String get automationsManagedHint =>
      'Os gatilhos são configurados por pipeline no seu editor. Ative-os ou desative-os aqui.';

  @override
  String get automationsEditInPipeline => 'Editar no pipeline';

  @override
  String get nodeLibrarySearchHint => 'Pesquisar nós';

  @override
  String get nodeLibraryNoMatches => 'Nenhum nó correspondente';

  @override
  String get nodeCategoryFlow => 'Fluxo e lógica';

  @override
  String get nodeCategoryPr => 'Revisão de PR';

  @override
  String get nodeCategoryAgents => 'Agentes';

  @override
  String get nodeCategoryMessaging => 'Mensagens';

  @override
  String get nodeCategoryCode => 'Código';

  @override
  String get nodeCategoryDemo => 'Demo';

  @override
  String get triggerDisabledTag => 'desativado';

  @override
  String get pipelineInputTypeRepo => 'Repositório';

  @override
  String get pipelineRunNoRepos => 'Ainda não há repositórios neste workspace.';

  @override
  String get allowTicketingApi => 'Permitir chamadas à API de tickets';

  @override
  String get ticketingApiKey => 'Chave de API de tickets';

  @override
  String get ticketingApiKeySubtitle =>
      'Injeta a chave de API do provedor de tickets no sandbox.';

  @override
  String get ticketingProvider => 'Provedor de tickets';

  @override
  String get connectGitHubAndTicketing =>
      'Conecte o GitHub para que o Control Center possa ler seus pull requests, issues e revisões. Opcionalmente conecte um provedor de tickets. Nada sai desta máquina.';

  @override
  String get triggerEventTicketAssigned => 'Ticket atribuído';

  @override
  String get navTickets => 'Tickets';

  @override
  String get ticketsTitle => 'Tickets';

  @override
  String get newTicket => 'Novo ticket';

  @override
  String get noTicketsYet => 'Ainda não há tickets';

  @override
  String get assignTicket => 'Atribuir ticket';

  @override
  String get addCollaborator => 'Adicionar colaborador';

  @override
  String get noCollaborators => 'Ainda não há colaboradores';

  @override
  String get linkedPullRequests => 'Pull requests vinculados';

  @override
  String get noLinkedPullRequests => 'Nenhum pull request vinculado';

  @override
  String get ticketActivity => 'Atividade';

  @override
  String get ticketDispatchHint => '@mencione um agente para acioná-lo…';

  @override
  String get stopAgent => 'Parar agente';

  @override
  String get removeQueuedMessage => 'Remover mensagem na fila';

  @override
  String get ticketProperties => 'Propriedades';

  @override
  String get ticketTabIssue => 'Ticket';

  @override
  String get ticketTabActivity => 'Atividade';

  @override
  String get ticketTabChanges => 'Alterações';

  @override
  String get ticketTabTerminal => 'Terminal';

  @override
  String get ticketSelectPrompt => 'Selecione um ticket para ver os detalhes';

  @override
  String get ticketNoChanges =>
      'Ainda não há alterações nos repositórios vinculados';

  @override
  String get ticketTerminalNoAgent =>
      'Atribua um agente para abrir um terminal';

  @override
  String get unassigned => 'Não atribuído';

  @override
  String get ticketStatusBacklog => 'Backlog';

  @override
  String get ticketStatusOpen => 'A fazer';

  @override
  String get ticketStatusInProgress => 'Em andamento';

  @override
  String get ticketStatusInReview => 'Em revisão';

  @override
  String get ticketStatusDone => 'Concluído';

  @override
  String get ticketStatusBlocked => 'Bloqueado';

  @override
  String get ticketStatusFailed => 'Falhou';

  @override
  String get ticketStatusCancelled => 'Cancelado';

  @override
  String get notificationTicketAssigned => 'Ticket atribuído';

  @override
  String get notificationTicketStatusChanged => 'Status do ticket alterado';

  @override
  String get notificationTicketCollaboratorAdded => 'Colaborador adicionado';

  @override
  String get priority => 'Prioridade';

  @override
  String get status => 'Status';

  @override
  String get assignee => 'Responsável';

  @override
  String get labels => 'Etiquetas';

  @override
  String get noLabelsYet => 'Ainda sem etiquetas';

  @override
  String get clearLabels => 'Limpar etiquetas';

  @override
  String get pipelineStepAgentActivity => 'Atividade do agente';

  @override
  String get runStatusCompleted => 'Concluído';

  @override
  String get runStatusQueued => 'Na fila';

  @override
  String get ticketDescription => 'Descrição';

  @override
  String get ticketPriorityNone => 'Nenhuma';

  @override
  String get ticketPriorityUrgent => 'Urgente';

  @override
  String get ticketPriorityHigh => 'Alta';

  @override
  String get ticketPriorityMedium => 'Média';

  @override
  String get ticketPriorityLow => 'Baixa';

  @override
  String get ticketViewList => 'Lista';

  @override
  String get ticketViewBoard => 'Quadro';

  @override
  String get ticketTitlePlaceholder => 'Título do ticket';

  @override
  String get ticketDescriptionPlaceholder => 'Adicionar uma descrição…';

  @override
  String get createMore => 'Criar mais';

  @override
  String selectedCount(int count) {
    return '$count selecionados';
  }

  @override
  String get clearSelection => 'Limpar seleção';

  @override
  String get bulkDeleteTitle => 'Excluir tickets';

  @override
  String bulkDeleteMessage(int count) {
    return 'Excluir $count tickets selecionados? Isso não pode ser desfeito.';
  }

  @override
  String get assignTo => 'Atribuir a…';

  @override
  String get sectionMembers => 'Membros';

  @override
  String get sectionAgents => 'Agentes';

  @override
  String get sidebarGroupWorkspace => 'Workspace';

  @override
  String get notificationsTitle => 'Notificações';

  @override
  String get notificationsTooltip => 'Notificações';

  @override
  String get notificationsEmpty => 'Está tudo em dia';

  @override
  String get markAllRead => 'Marcar tudo como lido';

  @override
  String get toggleThemeLabel => 'Alternar tema';

  @override
  String get teamsNav => 'Equipas';

  @override
  String get noWorkspace => 'Nenhum espaço de trabalho';

  @override
  String get selectWorkspace => 'Selecionar um espaço de trabalho';

  @override
  String get allAgentsIdle => 'Todos os agentes inativos';

  @override
  String get statWorkspaces => 'Áreas de trabalho';

  @override
  String get statAgents => 'Agentes';

  @override
  String get statRunning => 'Em execução';

  @override
  String get activeAgentsTitle => 'Agentes ativos';

  @override
  String get noAgentProcessesSubtitle =>
      'A atividade dos agentes aparecerá aqui quando uma execução começar.';

  @override
  String agentIdShort(String id) {
    return 'ID $id';
  }

  @override
  String runningProcessesLabel(int count) {
    return 'Em execução · $count';
  }

  @override
  String get noneLabel => 'Nenhum';

  @override
  String get navMemory => 'Memória';

  @override
  String get memoryTabFacts => 'Factos';

  @override
  String get memoryTabPolicies => 'Políticas';

  @override
  String get memoryTabGraph => 'Grafo de conhecimento';

  @override
  String get memoryNoWorkspace =>
      'Selecione uma área de trabalho para ver a sua memória.';

  @override
  String get topStory => 'Destaque';

  @override
  String get searchArticles => 'Pesquisar artigos';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterUnread => 'Não lidos';

  @override
  String get filterSaved => 'Salvos';

  @override
  String get saveArticle => 'Salvar artigo';

  @override
  String get removeFromSaved => 'Remover dos salvos';

  @override
  String get filterBySource => 'Filtrar por fonte';

  @override
  String get viewAsList => 'Visualização em lista';

  @override
  String get viewAsGrid => 'Visualização em grade';

  @override
  String get noMatchingArticles => 'Nenhum artigo correspondente';

  @override
  String get noMatchingArticlesBody =>
      'Tente uma pesquisa ou um filtro de fonte diferente.';

  @override
  String get allCaughtUp => 'Tudo em dia';

  @override
  String get allCaughtUpBody => 'Nenhum artigo não lido — volte mais tarde.';

  @override
  String get openArticlesInAppDescription =>
      'Abrir os links no leitor integrado em vez do seu navegador padrão.';

  @override
  String get blockAdsTrackersDescription =>
      'Remover anúncios, rastreadores e banners de cookies dos artigos abertos no leitor.';

  @override
  String get agentQuestionHeader => 'Pergunta para você';

  @override
  String get agentQuestionAnsweredLabel => 'Respondido';

  @override
  String get agentQuestionSubmit => 'Enviar resposta';

  @override
  String get agentQuestionFreeformHint => 'Digite sua resposta…';

  @override
  String get agentQuestionAnswerLabel => 'Sua resposta';

  @override
  String get reviewRequested => 'Revisão solicitada';

  @override
  String get loadMorePrs => 'Carregar mais';

  @override
  String get loadingMorePrs => 'Carregando mais…';

  @override
  String get noPrsMatchFilters =>
      'Nenhum pull request corresponde aos filtros neste repositório';

  @override
  String get connectGitHubToLoadPrs =>
      'Conecte o GitHub para carregar os pull requests';

  @override
  String get noRepositoriesConfigured => 'Nenhum repositório configurado';

  @override
  String get noAuthors => 'Nenhum autor';

  @override
  String openedAgo(String age) {
    return 'Aberto $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author abriu este pull request';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$author abriu este pull request com $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor solicitou revisão de $reviewers';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor removeu a solicitação de revisão para $reviewers';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor solicitou revisão de $requested e removeu a solicitação de revisão para $removed';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author fez commit';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$author enviou $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author aprovou estas alterações';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author solicitou alterações';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comentários de código',
      one: '1 comentário de código',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author deixou uma revisão';
  }

  @override
  String get prTimelineSomeone => 'Alguém';

  @override
  String get prTimelineBotBadge => 'bot';

  @override
  String updatedAgo(String age) {
    return 'Atualizado $age';
  }

  @override
  String get checksPassing => 'Verificações aprovadas';

  @override
  String get checksRunning => 'Verificações em andamento';

  @override
  String get needsYourReview => 'Precisa da sua revisão';

  @override
  String diffSummary(int additions, int deletions) {
    return '+$additions −$deletions linhas';
  }

  @override
  String get checks => 'Verificações';

  @override
  String get noReviewersAssigned => 'Nenhum revisor atribuído';

  @override
  String get noAssignees => 'Nenhum responsável';

  @override
  String get noChecksYet => 'Nenhuma verificação executada ainda';

  @override
  String checksFailingCount(int count) {
    return '$count com falha';
  }

  @override
  String get showMore => 'Mostrar mais';

  @override
  String get showLess => 'Mostrar menos';

  @override
  String get backToPullRequests => 'Voltar para as pull requests';

  @override
  String get pullRequestNotFound => 'Pull request não encontrada';

  @override
  String get pullRequestNotFoundBody =>
      'Ela pode ter sido mesclada, fechada ou movida.';

  @override
  String get couldntLoadPullRequest =>
      'Não foi possível carregar esta pull request';

  @override
  String get showDetails => 'Mostrar detalhes';

  @override
  String loadingPullRequestNumber(int number) {
    return 'Carregando a pull request #$number…';
  }

  @override
  String get noDescriptionProvided => 'Nenhuma descrição fornecida.';

  @override
  String get factsHint =>
      'Os fatos aparecerão aqui à medida que seus agentes aprendem.';

  @override
  String get noFactsMatch => 'Nenhum fato corresponde à sua pesquisa';

  @override
  String get memoryLoadError => 'Não foi possível carregar a memória';

  @override
  String get sortRecent => 'Recente';

  @override
  String get sortConfidence => 'Confiança';

  @override
  String get confidenceTooltip =>
      'O quanto os agentes têm certeza de que este fato é verdadeiro, de 0 a 100%.';

  @override
  String get supersededTooltip => 'Um fato mais recente substituiu este.';

  @override
  String get domain => 'Domínio';

  @override
  String get fitToView => 'Ajustar à vista';

  @override
  String get project => 'Projeto';

  @override
  String get projects => 'Projetos';

  @override
  String get newProject => 'Novo projeto';

  @override
  String get editProject => 'Editar projeto';

  @override
  String get deleteProject => 'Excluir projeto';

  @override
  String get noProject => 'Sem projeto';

  @override
  String get allTickets => 'Todos os tickets';

  @override
  String get projectNamePlaceholder => 'Nome do projeto';

  @override
  String get projectDescriptionPlaceholder => 'Descrição (opcional)';

  @override
  String get projectColorLabel => 'Cor';

  @override
  String get noProjectsYet => 'Ainda não há projetos';

  @override
  String get projectTicketsEmpty => 'Ainda não há tickets neste projeto';

  @override
  String get createProject => 'Criar projeto';

  @override
  String projectProgress(int done, int total) {
    return '$done de $total concluídos';
  }

  @override
  String deleteProjectConfirm(String name) {
    return 'Excluir \"$name\"? Os tickets são mantidos e removidos do projeto.';
  }

  @override
  String get projectStatusActive => 'Ativo';

  @override
  String get projectStatusCompleted => 'Concluído';

  @override
  String get projectStatusArchived => 'Arquivado';

  @override
  String get markProjectCompleted => 'Marcar como concluído';

  @override
  String get markProjectActive => 'Marcar como ativo';

  @override
  String get archiveProject => 'Arquivar';

  @override
  String get restoreProject => 'Restaurar';

  @override
  String get relations => 'Relações';

  @override
  String get relateTo => 'Relacionar com';

  @override
  String get relationSubIssueOf => 'Subtarefa de…';

  @override
  String get relationParentOf => 'Pai de…';

  @override
  String get relationBlockedBy => 'Bloqueado por…';

  @override
  String get relationBlocking => 'Bloqueando…';

  @override
  String get relationRelatedTo => 'Relacionado a…';

  @override
  String get relationDuplicateOf => 'Duplicado de…';

  @override
  String get relationGroupParent => 'Pai';

  @override
  String get relationGroupSubIssues => 'Subtarefas';

  @override
  String get relationGroupBlockedBy => 'Bloqueado por';

  @override
  String get relationGroupBlocking => 'Bloqueando';

  @override
  String get relationGroupRelated => 'Relacionado';

  @override
  String get relationGroupDuplicateOf => 'Duplicado de';

  @override
  String get relationGroupDuplicatedBy => 'Duplicado por';

  @override
  String get copyId => 'Copiar ID';

  @override
  String get ticketIdCopied => 'ID do ticket copiado';

  @override
  String get selectTicket => 'Selecionar um ticket';

  @override
  String get searchTicketsHint => 'Pesquisar tickets…';

  @override
  String get noMatchingTickets => 'Nenhum ticket corresponde';

  @override
  String get addToProject => 'Adicionar ao projeto';

  @override
  String get clearAll => 'Limpar tudo';

  @override
  String agentsRunningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agentes em execução',
      one: '1 agente em execução',
    );
    return '$_temp0';
  }

  @override
  String blockedCountLabel(int count) {
    return '$count bloqueados';
  }

  @override
  String needsYouCountLabel(int count) {
    return '$count para você';
  }

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PRs aguardando',
      one: '1 PR aguardando',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos repositórios',
      one: '1 repositório',
    );
    return '$_temp0 sua revisão em $_temp1';
  }

  @override
  String get staleLabel => 'Obsoleta';

  @override
  String stepsProgress(int done, int total) {
    return '$done de $total etapas';
  }

  @override
  String workspaceEyebrow(String name) {
    return 'Espaço $name';
  }

  @override
  String get pipelineTriggerNode => 'Gatilho';

  @override
  String get workspaceSettings => 'Configurações do espaço';

  @override
  String get manageWorkspacesSubtitle =>
      'Renomeie um espaço e altere a sua marca — escolha um à esquerda para editá-lo.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count espaços',
      one: '1 espaço',
      zero: 'Nenhum espaço',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos repositórios',
      one: '1 repositório',
      zero: 'Nenhum repositório',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents agentes',
      one: '1 agente',
      zero: '0 agentes',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'Identidade';

  @override
  String get uploadImage => 'Enviar imagem';

  @override
  String get failedToSaveLogo =>
      'Falha ao salvar o logo. Verifique se o app pode ler o arquivo selecionado.';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG ou GIF até 2 MB. Caso contrário, usaremos a inicial do espaço.';

  @override
  String get workspaceNameFieldHelp =>
      'Exibido no seletor, na trilha de navegação e em todas as telas.';

  @override
  String get dangerZone => 'Zona de perigo';

  @override
  String get deleteThisWorkspace => 'Excluir este espaço';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Remove permanentemente $name, as suas conexões de repositório, agentes e memória. Esta ação não pode ser desfeita.';
  }

  @override
  String get discard => 'Descartar';

  @override
  String discardChangesQuestion(String name) {
    return 'Descartar alterações não salvas em $name?';
  }

  @override
  String get workspaceUpdated => 'Espaço atualizado';

  @override
  String get editTitle => 'Editar título';

  @override
  String get editDescription => 'Editar descrição';

  @override
  String get addDescription => 'Adicionar uma descrição';

  @override
  String get prTitlePlaceholder => 'Título';

  @override
  String get prBodyPlaceholder => 'Adicione uma descrição';

  @override
  String get write => 'Escrever';

  @override
  String get overview => 'Visão geral';

  @override
  String get filesTabShort => 'Arquivos';

  @override
  String get noFilesChanged => 'Nenhum arquivo alterado';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Pré-visualização';

  @override
  String get outdated => 'Desatualizado';

  @override
  String get outdatedComments => 'Comentários desatualizados';

  @override
  String outdatedCountLabel(int count) {
    return '$count desatualizados';
  }

  @override
  String get prTemplateLabel => 'Modelo';

  @override
  String get prTemplateDefault => 'Padrão';

  @override
  String get addReviewers => 'Adicionar revisores';

  @override
  String get addAssignees => 'Adicionar responsáveis';

  @override
  String get searchUsers => 'Pesquisar pessoas…';

  @override
  String get searchReviewers => 'Pesquisar pessoas e equipes…';

  @override
  String get usersSectionLabel => 'Pessoas';

  @override
  String get teamsSectionLabel => 'Equipes';

  @override
  String get suggestedReviewers => 'Revisores sugeridos';

  @override
  String get noMatchingUsers => 'Nenhuma pessoa correspondente';

  @override
  String get noMatchingReviewers => 'Sem correspondências';

  @override
  String addCount(int count) {
    return 'Adicionar ($count)';
  }

  @override
  String get requiredByCodeOwners => 'Exigido pelos proprietários do código';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'via $login';
  }

  @override
  String get team => 'Equipe';

  @override
  String get markdownBold => 'Negrito';

  @override
  String get markdownItalic => 'Itálico';

  @override
  String get markdownHeading => 'Cabeçalho';

  @override
  String get markdownBulletList => 'Lista com marcadores';

  @override
  String get markdownChecklist => 'Lista de tarefas';

  @override
  String get markdownCode => 'Código';

  @override
  String get markdownLink => 'Link';

  @override
  String get markdownQuote => 'Citação';

  @override
  String failedToUpdateTitle(String error) {
    return 'Não foi possível atualizar o título: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Não foi possível atualizar a descrição: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Não foi possível atualizar os revisores: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Não foi possível atualizar os responsáveis: $error';
  }

  @override
  String get discardChangesConfirm => 'Descartar suas alterações?';

  @override
  String get newPr => 'Nova PR';

  @override
  String get openPullRequest => 'Abrir uma pull request';

  @override
  String get composePrSubtitle =>
      'A partir de um branch que você enviou — sem agentes ou tickets';

  @override
  String get createAsDraft => 'Criar como rascunho';

  @override
  String get composePrNoRepo => 'Nenhum repositório do GitHub selecionado';

  @override
  String get composePrNoRepoHint =>
      'Selecione um espaço de trabalho com um repositório vinculado ao GitHub para abrir uma pull request.';

  @override
  String get composePrPickBranches =>
      'Escolha um branch base e um branch de comparação para pré-visualizar as alterações.';

  @override
  String get composePrNothingToCompare =>
      'Não há alterações entre esses branches.';

  @override
  String get repository => 'Repositório';

  @override
  String get baseBranchLabel => 'Base';

  @override
  String get compareBranchLabel => 'Comparar';

  @override
  String get selectBranch => 'Selecione um branch';

  @override
  String get navMeetings => 'Reuniões';

  @override
  String get meetingsNoWorkspace =>
      'Selecione um espaço de trabalho para ver as reuniões.';

  @override
  String get meetingsEmpty => 'Ainda não há reuniões';

  @override
  String get meetingsEmptyHint =>
      'Grave a sua primeira reunião — o áudio fica neste dispositivo e o agente transforma-a em notas, decisões e ações.';

  @override
  String get meetingsStartRecording => 'Iniciar gravação';

  @override
  String get meetingsStopRecording => 'Parar gravação';

  @override
  String get meetingsProcessing => 'Resumindo…';

  @override
  String get meetingEnhancedNotes => 'Notas aprimoradas';

  @override
  String get meetingYourNotes => 'Suas notas';

  @override
  String get meetingNotesHint =>
      'Anote notas rápidas — o agente as expandirá após a reunião.';

  @override
  String get meetingTranscriptTitle => 'Transcrição';

  @override
  String get meetingNoTranscriptYet =>
      'A transcrição aparece aqui conforme as pessoas falam.';

  @override
  String get meetingSpeakerMe => 'Você';

  @override
  String get meetingSpeakerThem => 'Eles';

  @override
  String get meetingStatusRecording => 'Gravando';

  @override
  String get meetingStatusProcessing => 'Processando';

  @override
  String get meetingStatusDone => 'Concluído';

  @override
  String get meetingStatusFailed => 'Falhou';

  @override
  String get keybindingGoToMeetings => 'Ir para reuniões';

  @override
  String get keybindingNavigateToTheMeetingsDescription =>
      'Navegar até a lista de reuniões';

  @override
  String get meetingsSubtitle =>
      'Captura local das suas reuniões. Captamos o áudio da reunião e o seu microfone, transcrevemos no dispositivo e deixamos um agente transformar as suas notas esparsas em decisões e tarefas — nenhum bot entra na chamada.';

  @override
  String get meetingsRecordMeeting => 'Gravar reunião';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count em processamento agora',
      one: '1 em processamento agora',
    );
    return '$_temp0';
  }

  @override
  String get meetingsStatThisWeek => 'Esta semana';

  @override
  String get meetingsStatThisWeekUnit => 'reuniões capturadas';

  @override
  String get meetingsStatRecorded => 'Gravado';

  @override
  String get meetingsStatRecordedUnit => 'transcrito localmente';

  @override
  String get meetingsStatOpen => 'Abertas';

  @override
  String get meetingsStatOpenUnit => 'tarefas pendentes';

  @override
  String get meetingsStatLogged => 'Registradas';

  @override
  String get meetingsStatLoggedUnit => 'decisões extraídas';

  @override
  String get meetingsCaptureTitle =>
      'A captura de áudio do sistema sem driver está pronta.';

  @override
  String get meetingsCaptureBody =>
      'O Control Center capta a saída de alto-falante do app em que você está — Slack Huddle, Meet, Zoom, Tuple — além do microfone, e decodifica ambos os fluxos neste dispositivo.';

  @override
  String get meetingsCapturePermission => 'Permissão concedida';

  @override
  String get meetingsCaptureOnDevice => '100% no dispositivo';

  @override
  String get meetingsCaptureNoBot => 'Nenhum bot entra';

  @override
  String get meetingsScopeAll => 'Todas as reuniões';

  @override
  String get meetingsFilterAll => 'Todas';

  @override
  String get meetingsFilterDone => 'Concluídas';

  @override
  String get meetingsFilterProcessing => 'Em processamento';

  @override
  String get meetingsSearchHint => 'Filtrar por título, pessoa, app…';

  @override
  String get meetingsBucketToday => 'Hoje';

  @override
  String get meetingsBucketYesterday => 'Ontem';

  @override
  String get meetingsBucketEarlierThisWeek => 'No início desta semana';

  @override
  String get meetingsBucketLastWeek => 'Semana passada';

  @override
  String get meetingsBucketOlder => 'Mais antigas';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count decisões',
      one: '1 decisão',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total tarefas';
  }

  @override
  String get meetingsEnhancedPill => 'aprimorada';

  @override
  String get meetingsTranscribing => 'transcrevendo e resumindo…';

  @override
  String get meetingsOpenAction => 'Abrir';

  @override
  String get meetingsStopProcessing => 'Parar';

  @override
  String get meetingsStillTranscribing =>
      'Ainda transcrevendo — o resumo aparecerá quando terminar.';

  @override
  String get meetingsNoMatch => 'Nenhuma reunião corresponde';

  @override
  String get meetingsNoMatchHint => 'Tente outro filtro ou termo de busca.';

  @override
  String get meetingBackAllMeetings => 'Todas as reuniões';

  @override
  String meetingPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pessoas',
      one: '1 pessoa',
    );
    return '$_temp0';
  }

  @override
  String get meetingReRunSummary => 'Refazer resumo';

  @override
  String get meetingExport => 'Exportar';

  @override
  String get meetingAugmentingBanner =>
      'Aprimorando suas notas a partir da transcrição — extraindo decisões e tarefas…';

  @override
  String get meetingTabNotes => 'Notas';

  @override
  String get meetingTabTranscript => 'Transcrição';

  @override
  String get meetingTabActionItems => 'Tarefas';

  @override
  String get meetingTabDecisions => 'Decisões';

  @override
  String get meetingNotesEnhancedToggle => 'Aprimoradas';

  @override
  String get meetingNotesYoursToggle => 'Suas notas';

  @override
  String get meetingEnhancedByAgent =>
      'Aprimorado pelo agente · a partir da transcrição';

  @override
  String get meetingEnhancedPending =>
      'O agente ainda está trabalhando neste resumo.';

  @override
  String get meetingNotesEmpty => 'Ainda não há notas aprimoradas.';

  @override
  String get meetingNotesSavedLocally => 'Salvo localmente';

  @override
  String get meetingNotesSaving => 'Salvando…';

  @override
  String get meetingViewFullTranscript => 'Ver transcrição completa';

  @override
  String get meetingTranscriptSearchHint => 'Pesquisar na transcrição…';

  @override
  String get meetingSpeakerEveryone => 'Todos';

  @override
  String get meetingSpeakerOthers => 'Outros';

  @override
  String get meetingTranscriptEmpty => 'Ainda não há transcrição.';

  @override
  String get meetingActionItemsEmpty => 'Nenhuma tarefa extraída.';

  @override
  String get meetingActionItemFrom => 'desta reunião';

  @override
  String get meetingCreateTicket => 'Criar ticket';

  @override
  String meetingTicketCreated(String key) {
    return 'Ticket $key criado e despachado.';
  }

  @override
  String get meetingTicketFailed => 'Não foi possível criar o ticket.';

  @override
  String get meetingDecisionsEmpty => 'Nenhuma decisão registrada.';

  @override
  String get meetingEditTitle => 'Editar título';

  @override
  String get meetingTitleLabel => 'Título';

  @override
  String get meetingAddActionItem => 'Adicionar ação';

  @override
  String get meetingEditActionItem => 'Editar ação';

  @override
  String get meetingDeleteActionItem => 'Excluir ação';

  @override
  String get meetingActionItemContentLabel => 'Ação';

  @override
  String get meetingActionItemContentHint => 'O que precisa ser feito?';

  @override
  String get meetingActionItemOwnerLabel => 'Responsável';

  @override
  String get meetingActionItemOwnerHint => 'Quem é responsável? (opcional)';

  @override
  String get meetingAddDecision => 'Adicionar decisão';

  @override
  String get meetingEditDecision => 'Editar decisão';

  @override
  String get meetingDeleteDecision => 'Excluir decisão';

  @override
  String get meetingDecisionContentLabel => 'Decisão';

  @override
  String get meetingDecisionContentHint => 'O que foi decidido?';

  @override
  String get meetingReRunStarted => 'Refazendo o resumo sobre a transcrição…';

  @override
  String get meetingReRunDone => 'Resumo atualizado.';

  @override
  String get meetingReRunNoTranscript =>
      'Ainda não há transcrição para resumir.';

  @override
  String get meetingExportCopied =>
      'Notas copiadas para a área de transferência em Markdown.';

  @override
  String get meetingExportSaved => 'Reunião exportada.';

  @override
  String meetingExportFailed(String error) {
    return 'Falha ao exportar: $error';
  }

  @override
  String get meetingExportNothing => 'Ainda não há nada para exportar.';

  @override
  String get meetingPlaybackPlay => 'Reproduzir';

  @override
  String get meetingPlaybackPause => 'Pausar';

  @override
  String get meetingPlaybackUnavailable =>
      'A reprodução de áudio não está disponível neste dispositivo.';

  @override
  String get meetingDetectedTitle => 'Reunião detectada';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'Parece que \"$label\" está a decorrer. Gravar?';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'Parece que há uma reunião a decorrer. Gravar?';

  @override
  String get meetingDetectedRecord => 'Gravar';

  @override
  String get meetingDetectedDismiss => 'Dispensar';

  @override
  String get meetingAutoStopTitle =>
      'Esta reunião parece ter terminado. Parar a gravação?';

  @override
  String get meetingAutoStopStop => 'Parar';

  @override
  String get meetingAutoStopKeep => 'Continuar a gravar';

  @override
  String get meetingAutoDetect => 'Detetar reuniões automaticamente';

  @override
  String get meetingAutoDetectDescription =>
      'Vigia o calendário e as apps de videoconferência e oferece-se para gravar quando uma reunião começa.';

  @override
  String get meetingsRecordingCrumb => 'Gravando…';

  @override
  String get meetingRecordTitleHint => 'Título da reunião';

  @override
  String get meetingRecordTappingLabel => 'Captando:';

  @override
  String get meetingRecordMic => 'Microfone';

  @override
  String get meetingRecordSystemAudio => 'Áudio do sistema';

  @override
  String get meetingRecordPause => 'Pausar';

  @override
  String get meetingRecordResume => 'Retomar';

  @override
  String get meetingRecordStop => 'Parar e resumir';

  @override
  String get meetingRecordYourNotes => 'Suas notas';

  @override
  String get meetingRecordNotesTagline =>
      'anote o essencial — o agente preenche o resto';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Escreva enquanto escuta. Alguns fragmentos bastam — após parar, o agente os expande usando a transcrição.';

  @override
  String get meetingRecordLiveTranscript => 'Transcrição ao vivo';

  @override
  String get meetingRecordDecoding => 'decodificando no dispositivo';

  @override
  String get meetingRecordListening =>
      'Ouvindo… a fala aparecerá aqui em um ou dois segundos, marcada como Você / Outros.';

  @override
  String get meetingRecordPausedHint =>
      'Pausado — o áudio é ignorado até você retomar.';

  @override
  String get meetingRecordNotActive => 'Nenhuma gravação ativa.';

  @override
  String get meetingHudRecording => 'gravando';

  @override
  String get meetingHudPaused => 'pausado';

  @override
  String get meetingHudOpen => 'Abrir';

  @override
  String get meetingHudStop => 'Parar';

  @override
  String get meetingToolbarPopOut => 'Destacar';

  @override
  String get meetingToolbarHoldToStop =>
      'Mantenha pressionado para parar a gravação';

  @override
  String get meetingToolbarSemanticLabel => 'Barra de gravação de reunião';

  @override
  String get orchestrate => 'Orquestrar';

  @override
  String get orchestrationUnavailable => 'Orquestração indisponível';

  @override
  String get orchestrationApprove => 'Aprovar plano';

  @override
  String get orchestrationReject => 'Rejeitar';

  @override
  String get orchestrationCancel => 'Cancelar orquestração';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count funções — $hires novas contratações';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count subtarefas';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Custo estimado: $amount \$';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total subtarefas concluídas';
  }

  @override
  String get orchestrationStatusProposed => 'Proposto';

  @override
  String get orchestrationStatusApproved => 'Aprovado';

  @override
  String get orchestrationStatusExecuting => 'Em execução';

  @override
  String get orchestrationStatusSynthesizing => 'Sintetizando';

  @override
  String get orchestrationStatusCompleted => 'Concluído';

  @override
  String get orchestrationStatusFailed => 'Falhou';

  @override
  String get orchestrationStatusCancelled => 'Cancelado';

  @override
  String get messageFailed => 'Execução falhou';

  @override
  String get turnLimitReached =>
      'Limite de turnos atingido — responde para continuar';

  @override
  String get retried => 'Repetido';

  @override
  String replyingTo(String name) {
    return 'em resposta a $name';
  }

  @override
  String get recentRuns => 'Execuções recentes';

  @override
  String get runIdCopied => 'Id de execução copiado';

  @override
  String get copyRunId => 'Copiar id de execução';

  @override
  String get copyLogPath => 'Copiar caminho do log';

  @override
  String get silenceTimeoutLabel => 'Tempo de silêncio (minutos)';

  @override
  String get silenceTimeoutHint =>
      'ex. 15 — encerra um run após esse tempo sem saída';

  @override
  String get ticketOutput => 'Saída';

  @override
  String missingRequiredField(String field) {
    return 'Campo obrigatório ausente: $field';
  }

  @override
  String get capabilityJsonMode => 'Modo JSON';

  @override
  String get capabilityModelSelection => 'Seleção de modelo';

  @override
  String get transcriptThinking => 'Pensando…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'Pensou por $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'Fazendo edições…';

  @override
  String get transcriptStatusReadingFiles => 'Lendo arquivos…';

  @override
  String get transcriptStatusSearching => 'Pesquisando no código…';

  @override
  String get transcriptStatusRunningCommands => 'Executando comandos…';

  @override
  String get transcriptStatusResponding => 'Respondendo…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'Executando $tool…';
  }

  @override
  String get transcriptInput => 'Entrada';

  @override
  String get transcriptOutput => 'Saída';

  @override
  String get transcriptShowMore => 'Mostrar mais';

  @override
  String get transcriptShowLess => 'Mostrar menos';

  @override
  String get transcriptErrorLabel => 'Erro';

  @override
  String get transcriptInterrupted => 'Interrompido';

  @override
  String get transcriptSandboxBlocked => 'O sandbox bloqueou uma ação';

  @override
  String get transcriptOutputTruncated => 'Saída truncada';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'Mostrar saída completa (+$kb KB)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'Mostrar todas as $count linhas';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'Mostrando as primeiras $count linhas';
  }

  @override
  String get transcriptGrepNoMatches => 'Nenhuma correspondência';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches correspondências',
      one: '1 correspondência',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files arquivos',
      one: '1 arquivo',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String transcriptDiffStats(int adds, int dels) {
    return '$adds adições, $dels exclusões';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'Pessoa $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'Renomear participante';

  @override
  String get meetingRenameSpeakerTitle => 'Renomear participante';

  @override
  String get meetingSpeakerNameLabel => 'Nome';

  @override
  String get meetingSpeakerSuggestFromCalendar =>
      'Entre os convidados desta reunião';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'Aplicar a todos os blocos deste interlocutor';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'Quando desativado, apenas a linha selecionada é renomeada.';

  @override
  String get meetingLinkEvent => 'Vincular a evento';

  @override
  String get meetingChangeEvent => 'Alterar evento';

  @override
  String get meetingLinkEventTitle => 'Vincular a um evento do calendário';

  @override
  String get meetingLinkEventSearchHint => 'Pesquisar eventos';

  @override
  String get meetingLinkEventEmpty => 'Nenhum evento do calendário por perto';

  @override
  String get meetingUnlinkEvent => 'Remover vínculo';

  @override
  String get calendarLinkExistingMeeting => 'Vincular a uma reunião existente';

  @override
  String get calendarLinkMeetingTitle => 'Vincular uma reunião';

  @override
  String get calendarLinkMeetingSearchHint => 'Pesquisar reuniões';

  @override
  String get calendarLinkMeetingEmpty => 'Nenhuma reunião para vincular';

  @override
  String get meetingRenameSpeakerFailed =>
      'Não foi possível renomear o participante';

  @override
  String get calendarLinkUpdateFailed =>
      'Não foi possível atualizar o vínculo com o calendário';

  @override
  String get rename => 'Renomear';

  @override
  String get notNow => 'Agora não';

  @override
  String get meetingSaveVoiceProfileTitle => 'Salvar perfil de voz?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'Reconhecer $name automaticamente em reuniões futuras salvando a sua impressão de voz.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'Perfil de voz salvo para $name';
  }

  @override
  String get meetingVoiceProfileSaveFailed =>
      'Não foi possível salvar o perfil de voz';

  @override
  String get voiceProfilesSection => 'Perfis de voz';

  @override
  String get voiceProfilesDescription =>
      'Vozes salvas são reconhecidas automaticamente em reuniões futuras.';

  @override
  String get voiceProfilesEmpty =>
      'Ainda não há vozes salvas. Dê um nome a um participante na transcrição de uma reunião e escolha «Salvar perfil de voz».';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amostras',
      one: '1 amostra',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'Renomear perfil de voz';

  @override
  String get deleteVoiceProfileTitle => 'Excluir perfil de voz?';

  @override
  String deleteVoiceProfileBody(String name) {
    return 'Parar de reconhecer $name? A impressão de voz salva será removida. Os nomes já aplicados em reuniões anteriores são mantidos.';
  }

  @override
  String get remoteControl => 'Controle remoto';

  @override
  String get remoteControlListening => 'Aguardando dispositivos';

  @override
  String get remoteControlListenerStopped => 'Listener parado';

  @override
  String get remoteControlStartToAccept =>
      'Inicie o listener para aceitar conexões do telefone.';

  @override
  String get remoteControlStartOnLaunch => 'Iniciar ao abrir';

  @override
  String get remoteControlWhenOffStaysStopped =>
      'Se desativado, o listener fica parado até você iniciá-lo.';

  @override
  String get remoteControlRestartToApply =>
      'Reinicie o listener para aplicar as alterações.';

  @override
  String get remoteControlSignalingUrl => 'URL do broker de sinalização';

  @override
  String get remoteControlSignalingHint =>
      'Broker wss:// que retransmite apenas o handshake de pareamento.';

  @override
  String get remoteControlStunServers => 'Servidores STUN';

  @override
  String get remoteControlStunHint =>
      'URLs STUN separadas por vírgulas. Sem TURN por design.';

  @override
  String get remoteControlPwaHost => 'Host do app do telefone';

  @override
  String get remoteControlPwaHostHint =>
      'Onde o web app do telefone é hospedado; codificado no QR de pareamento.';

  @override
  String get remoteControlNotConfigured =>
      'Adicione uma URL de sinalização e um host de app para habilitar o pareamento.';

  @override
  String get remoteControlPairDevice => 'Parear um dispositivo';

  @override
  String get remoteControlScanQr =>
      'Escaneie este código com a câmera do telefone.';

  @override
  String get remoteControlAllWorkspacesWarning =>
      'Este dispositivo poderá acessar todos os espaços de trabalho neste Mac.';

  @override
  String get remoteControlCopyLink => 'Copiar link';

  @override
  String get remoteControlWantsToConnect => 'Quer conectar';

  @override
  String get remoteControlApproveDevice => 'Aprovar dispositivo';

  @override
  String get remoteControlDeviceConnected =>
      'Dispositivo conectado — aprove-o para concluir o emparelhamento.';

  @override
  String remoteControlQrExpiresIn(int minutes) {
    return 'Expira em $minutes min';
  }

  @override
  String get remoteControlPairedDevices => 'Dispositivos pareados';

  @override
  String get remoteControlNoPairedDevices =>
      'Nenhum dispositivo pareado ainda.';

  @override
  String get remoteControlPending => 'Confirmação pendente';

  @override
  String get remoteControlActive => 'Ativo';

  @override
  String get remoteControlRevoked => 'Revogado';

  @override
  String get remoteControlRevoke => 'Revogar';

  @override
  String get remoteControlConfirmDevice => 'Confirmar dispositivo';

  @override
  String get remoteControlRevokeConfirm =>
      'Revogar este dispositivo? Ele será desconectado imediatamente.';

  @override
  String get devicesSettingsDescription =>
      'Pareie e gerencie os telefones que podem controlar este app remotamente.';

  @override
  String get connectedLabel => 'Conectado';

  @override
  String get ideTabGeneral => 'Geral';

  @override
  String get ideTabExplorer => 'Explorador';

  @override
  String get ideTabSourceControl => 'Controlo de origem';

  @override
  String get ideTabPullRequests => 'Pull requests';

  @override
  String get generalSectionTodos => 'Tarefas';

  @override
  String get generalSectionGoals => 'Metas';

  @override
  String get goalRunStatusActive => 'Ativo';

  @override
  String get goalRunStatusPaused => 'Em pausa';

  @override
  String get goalRunStatusCompleted => 'Concluído';

  @override
  String get goalRunStatusFailed => 'Falhou';

  @override
  String get goalRunStatusCancelled => 'Cancelado';

  @override
  String get goalRunStatusBudgetExhausted => 'Orçamento esgotado';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'Execução $run de $max · $cost de $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'Execução $run · $cost de $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'Prazo: $deadline';
  }

  @override
  String get goalRunPause => 'Pausar meta';

  @override
  String get goalRunResume => 'Retomar meta';

  @override
  String goalRunResumeRaise(String cap) {
    return 'Retomar · aumentar limite para $cap';
  }

  @override
  String get goalRunStop => 'Parar meta';

  @override
  String get generalSectionPlan => 'Plano';

  @override
  String get generalSectionAgents => 'Agentes';

  @override
  String get generalSectionTerminals => 'Terminais';

  @override
  String get generalTodosEmpty => 'Sem tarefas';

  @override
  String get generalAgentsEmpty => 'Nenhum agente em execução';

  @override
  String get generalTerminalsEmpty => 'Nenhum terminal aberto';

  @override
  String get pauseAgent => 'Pausar agente';

  @override
  String get resumeAgent => 'Retomar agente';

  @override
  String get agentCannotPause =>
      'Este agente não pode ser pausado — pare-o em vez disso.';

  @override
  String get goalClear => 'Limpar objetivo';

  @override
  String get undoLabelGoalClear => 'limpar objetivo';

  @override
  String get todoStatusPending => 'Não iniciado';

  @override
  String get todoStatusInProgress => 'Em andamento';

  @override
  String get todoStatusCompleted => 'Concluído';

  @override
  String get reorderTodo => 'Reordenar tarefa';

  @override
  String get focusAgentRun => 'Focar execução do agente';

  @override
  String get focusTerminal => 'Focar terminal';

  @override
  String get todoEditorTitle => 'Editar tarefas';

  @override
  String get todoEditorHint =>
      'Um item por linha. Use - [ ] para pendente, - [~] para em andamento, - [x] para concluído.';

  @override
  String get todoNeedsText => 'Adicione texto após o comando';

  @override
  String get todoNotFound => 'Nenhuma tarefa correspondente';

  @override
  String get todoCleared => 'Lista de tarefas limpa';

  @override
  String get todoNothingToCopy => 'Nada para copiar';

  @override
  String todoAdded(String content) {
    return 'Adicionado \"$content\"';
  }

  @override
  String todoStarted(String content) {
    return 'Iniciado \"$content\"';
  }

  @override
  String todoCompleted(String content) {
    return 'Concluído \"$content\"';
  }

  @override
  String todoRemoved(String content) {
    return 'Removido \"$content\"';
  }

  @override
  String todoCopied(int count) {
    return '$count itens copiados';
  }

  @override
  String todoImported(int count) {
    return '$count itens importados';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'Comando de tarefa desconhecido \"$name\"';
  }

  @override
  String generalAgentTurns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turnos',
      one: '1 turno',
    );
    return '$_temp0';
  }

  @override
  String get terminal => 'Terminal';

  @override
  String get ideNewTerminal => 'Novo terminal';

  @override
  String get ideOpenChat => 'Abrir chat';

  @override
  String get ideCloseTab => 'Fechar aba';

  @override
  String get ideSplitEditor => 'Dividir editor';

  @override
  String get ideSplitRight => 'Dividir à direita';

  @override
  String get ideSplitDown => 'Dividir para baixo';

  @override
  String get ideSplitLeft => 'Dividir à esquerda';

  @override
  String get ideSplitUp => 'Dividir para cima';

  @override
  String get ideCloseGroup => 'Fechar grupo';

  @override
  String get ideCloseOthers => 'Fechar as outras';

  @override
  String get ideCloseToRight => 'Fechar à direita';

  @override
  String get ideCloseSaved => 'Fechar salvas';

  @override
  String get ideCloseAll => 'Fechar tudo';

  @override
  String get ideSplit => 'Dividir';

  @override
  String get ideToggleSidebar => 'Mostrar/ocultar barra lateral';

  @override
  String get ideNewTab => 'Abrir editor';

  @override
  String get ideReviewCode => 'Revisar código';

  @override
  String get ideReviewNoChanges => 'Nenhuma alteração para revisar';

  @override
  String get ideRevert => 'Reverter';

  @override
  String get ideRevertConfirmTitle => 'Reverter alterações';

  @override
  String ideRevertConfirmMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos',
      one: '1 arquivo',
    );
    return 'Reverter $_temp0 para HEAD? Isso descarta as alterações da árvore de trabalho.';
  }

  @override
  String get ideRevertConfirmAction => 'Reverter';

  @override
  String get ideRevertConfirmCancel => 'Cancelar';

  @override
  String get ideRevertUntracked =>
      'Arquivos não rastreados não podem ser revertidos';

  @override
  String get ideRevertFailed =>
      'Não foi possível reverter os arquivos. A árvore de trabalho da conversa pode estar indisponível.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos',
      one: '1 arquivo',
    );
    return '$_temp0 não pôde(puderam) ser revertido(s) (não rastreado).';
  }

  @override
  String get ideViewSource => 'Ver código-fonte';

  @override
  String get ideSearchMatchCase => 'Diferenciar maiúsculas/minúsculas';

  @override
  String get ideSearchWholeWord => 'Palavra inteira';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'Filtros de busca';

  @override
  String get ideSearchFilesToInclude => 'Arquivos a incluir';

  @override
  String get ideSearchFilesToExclude => 'Arquivos a excluir';

  @override
  String get ideNoOpenTabs => 'Sem abas abertas — use + para abrir';

  @override
  String get ideBrowserAddressHint => 'Digite um endereço ou pesquise';

  @override
  String get ideSimpleWebBrowser => 'Navegador web simples';

  @override
  String get ideWebBrowser => 'Navegador web';

  @override
  String get ideBrowserEnterUrl =>
      'Digite um URL na barra de endereço para começar a navegar';

  @override
  String get ideCodeServer => 'Editor';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'Salvar alterações em $fileName?';
  }

  @override
  String get ideUnsavedChangesBody =>
      'Suas alterações serão perdidas se você não salvá-las.';

  @override
  String get ideDontSave => 'Não salvar';

  @override
  String get editorAutoSave => 'Salvamento automático';

  @override
  String get editorAutoSaveDescription =>
      'Salvar automaticamente as alterações no editor incorporado.';

  @override
  String get editorAutoSaveOff => 'Desativado';

  @override
  String get editorAutoSaveAfterDelay => 'Após um atraso';

  @override
  String get editorAutoSaveOnFocusChange => 'Ao mudar o foco';

  @override
  String get ideCodeServerUnavailable =>
      'Code-server não está disponível neste servidor';

  @override
  String get ideCodeServerUnavailableHint =>
      'Instale o code-server (coder/code-server) no host do servidor e reabra o editor.';

  @override
  String get ideCodeServerInstalling => 'Preparando o editor…';

  @override
  String get ideCodeServerOpenInBrowser => 'Abrir editor no navegador';

  @override
  String get ideCodeServerError => 'Não foi possível abrir o editor';

  @override
  String get paneSuspendedCaption =>
      'Suspenso para economizar recursos — recarrega ao receber o foco';

  @override
  String get ideFileSearchFailed => 'Não foi possível pesquisar arquivos';

  @override
  String get ideSearchFilename => 'Nome do arquivo';

  @override
  String get ideSearchContent => 'Conteúdo';

  @override
  String get ideSearchInFiles => 'Pesquisar nos arquivos';

  @override
  String get ideNoContentMatches => 'Sem correspondências';

  @override
  String get ideSourceControlCreatePr => 'Criar pull request';

  @override
  String get ideSourceControlNoChanges => 'Sem alterações';

  @override
  String ideSourceControlChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alterados',
      one: '1 alterado',
    );
    return '$_temp0';
  }

  @override
  String get ideConnectGithub => 'Conecte o GitHub para ver os pull requests';

  @override
  String get ideNoConversationPr => 'Nenhum pull request para esta conversa';

  @override
  String get ideFileLoading => 'Carregando…';

  @override
  String get ideFileBinary => 'Arquivo binário';

  @override
  String get mcpExternalServers => 'Servidores MCP externos';

  @override
  String get mcpExternalServersDescription =>
      'Conecte-se a servidores MCP externos (GitHub, Sentry, Postgres, automação de navegador). Os servidores configurados para Claude, Cursor, VS Code e outras ferramentas são detectados automaticamente.';

  @override
  String get mcpApprovalMode => 'Aprovação de ferramentas';

  @override
  String get mcpApprovalModeDescription =>
      'Quais ações são executadas sem perguntar. Leituras são sempre permitidas; níveis superiores pedem confirmação.';

  @override
  String get mcpApprovalAlwaysAsk => 'Sempre perguntar';

  @override
  String get mcpApprovalWrite => 'Aprovar gravações';

  @override
  String get mcpApprovalYolo => 'Aprovar tudo';

  @override
  String get mcpNoExternalServers => 'Nenhum servidor MCP externo detectado.';

  @override
  String get mcpAuthorize => 'Autorizar';

  @override
  String get mcpReconnect => 'Reconectar';

  @override
  String get mcpExternalConnectionsNote =>
      'Os servidores MCP externos são executados no servidor de agentes (compartilhado por desktop e web). Autorizar servidores OAuth só está disponível no desktop.';

  @override
  String mcpToolsSummary(int count) {
    return '$count ferramentas';
  }

  @override
  String get mcpStatusConnected => 'Conectado';

  @override
  String get mcpStatusConnecting => 'Conectando…';

  @override
  String get mcpStatusNeedsAuth => 'Requer autorização';

  @override
  String get mcpStatusFailed => 'Falhou';

  @override
  String get mcpStatusCircuitOpen => 'Em pausa';

  @override
  String get mcpStatusDisabled => 'Desativado';

  @override
  String get providersAndModels => 'Provedores e modelos';

  @override
  String get providersAndModelsDescription =>
      'Liste todos os provedores que o agente integrado pode usar — defina uma chave de API ou entre pelo navegador, veja os modelos e preços de cada provedor conectado e controle quais provedores este espaço de trabalho pode usar.';

  @override
  String modelsCountFromProviders(int count, int providers) {
    return '$count modelos de $providers provedores';
  }

  @override
  String get syncNow => 'Sincronizar';

  @override
  String syncNowResult(int applied, int failed) {
    return 'Sincronização concluída — $applied aplicados, $failed com falha';
  }

  @override
  String syncNowFailed(String error) {
    return 'Falha na sincronização: $error';
  }

  @override
  String get toggleDetails => 'Alternar detalhes';

  @override
  String get denied => 'Negado';

  @override
  String get allowed => 'Permitido';

  @override
  String allowProviderSemantic(String provider) {
    return 'Permitir $provider';
  }

  @override
  String enabledViaEnv(String key) {
    return 'Ativado via $key';
  }

  @override
  String enabledViaAccount(String service) {
    return 'Ativado via $service';
  }

  @override
  String get enabledLabel => 'Ativado';

  @override
  String get disabledLabel => 'Desativado';

  @override
  String disabledSetEnvHint(String keys) {
    return 'Desativado — defina $keys ou faça login';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output por 1M';
  }

  @override
  String contextTokens(String tokens) {
    return 'contexto $tokens';
  }

  @override
  String get capabilityTools => 'Ferramentas';

  @override
  String get capabilityVision => 'Visão';

  @override
  String get capabilityReasoning => 'Raciocínio';

  @override
  String get statusDeprecated => 'Obsoleto';

  @override
  String get usageAndCost => 'Uso e custo';

  @override
  String get usageAndCostDescription =>
      'Gastos dos seus agentes nos últimos 7 dias, com base nos custos de execução observados.';

  @override
  String get noUsageYet => 'Nenhum uso registrado ainda.';

  @override
  String get spentThisWeek => 'gastos esta semana';

  @override
  String get subscriptionUsage => 'Uso da assinatura';

  @override
  String get subscriptionUsageUnavailable => 'Indisponível';

  @override
  String get subscriptionUsagePartiallyAvailable => 'Parcialmente disponível';

  @override
  String resetsIn(String duration) {
    return 'Redefine em $duration';
  }

  @override
  String get feedbackHelpful => 'Isto foi útil';

  @override
  String get feedbackNotHelpful => 'Isto não foi útil';

  @override
  String get modeChat => 'Conversa';

  @override
  String get modePlan => 'Plano';

  @override
  String get modeReview => 'Revisão';

  @override
  String get modeOrchestrate => 'Orquestração';

  @override
  String get commandRules => 'Regras de comando';

  @override
  String get commandRulesDescription =>
      'Como o Control Center decide quais comandos de shell um agente pode executar, por modo de conversa.';

  @override
  String get scopeGlobal => 'Sempre';

  @override
  String get ruleDenied => 'Negado';

  @override
  String get ruleAsk => 'Perguntar primeiro';

  @override
  String get editorTheme => 'Tema do editor';

  @override
  String get editorThemeDescription =>
      'Importe um tema de cores do VS Code para que o diff e o editor incorporados combinem com o seu IDE.';

  @override
  String get editorThemePasteHint =>
      'Cole o conteúdo de um ficheiro de tema de cores do VS Code';

  @override
  String get editorThemeImported => 'Tema importado';

  @override
  String get editorThemeInvalid => 'Isto não parece um tema VS Code válido';

  @override
  String get importTheme => 'Importar tema';

  @override
  String get clearTheme => 'Limpar tema';

  @override
  String get openInDiffViewer => 'Abrir no visualizador de diff';

  @override
  String get shellCommand => 'Comando';

  @override
  String get shellOutput => 'Saída';

  @override
  String get planReadyToImplement => 'Pronto para implementar?';

  @override
  String get planContinueHere => 'Continuar aqui';

  @override
  String get planContinueHereDescription => 'Implementar o plano nesta sessão';

  @override
  String get planStartNewSession => 'Iniciar nova sessão';

  @override
  String get planStartNewSessionDescription =>
      'Implementar numa sessão nova com um contexto limpo';

  @override
  String get revertToHere => 'Voltar para aqui';

  @override
  String get revertConfirmBody =>
      'Ocultar as mensagens após este ponto e reverter as alterações de ficheiros do agente para este turno? Pode desfazer isto.';

  @override
  String get revert => 'Reverter';

  @override
  String get revertedToHere => 'Revertido para este ponto';

  @override
  String get nothingToRevert => 'Nada para reverter';

  @override
  String get undoRevert => 'Desfazer reversão';

  @override
  String get revertUndone => 'Reversão desfeita';

  @override
  String get systemBehavior => 'Comportamento do sistema';

  @override
  String get keepAwakeTitle =>
      'Manter o computador ativo enquanto os agentes trabalham';

  @override
  String get keepAwakeOnSubtitle =>
      'O computador não entrará em suspensão enquanto um agente estiver a trabalhar';

  @override
  String get keepAwakeOffSubtitle =>
      'O computador pode entrar em suspensão mesmo enquanto um agente está a trabalhar';

  @override
  String get syncEngineSectionTitle => 'Motor de sincronização';

  @override
  String get syncEngineDescription =>
      'Os tickets, as mensagens e as notas são atualizados em tempo real através de pequenas alterações incrementais em vez de snapshots completos. Desativar um interrutor faz esse armazenamento voltar ao modo de snapshot completo — reinicie a aplicação para que a alteração tenha efeito.';

  @override
  String get syncEngineTicketsTitle => 'Tickets';

  @override
  String get syncEngineMessagingTitle => 'Mensagens';

  @override
  String get syncEngineNotesTitle => 'Notas';

  @override
  String get syncEngineOnSubtitle => 'A sincronização em tempo real está ativa';

  @override
  String get syncEngineOffSubtitle =>
      'A utilizar sincronização por snapshot completo';

  @override
  String get channels => 'Canais';

  @override
  String get channelsHomeDescription =>
      'Escolha um canal na lista ou inicie um novo.';

  @override
  String get noChannelsYet => 'Ainda não há canais';

  @override
  String get newChannel => 'Novo canal';

  @override
  String get channelName => 'Nome do canal';

  @override
  String get channelReposHint => 'Repos a incluir';

  @override
  String get ideSourceControl => 'Controlo de código-fonte';

  @override
  String get stagedChanges => 'Alterações preparadas';

  @override
  String get changes => 'Alterações';

  @override
  String get stageFile => 'Preparar';

  @override
  String get unstageFile => 'Remover dos preparados';

  @override
  String get stageAll => 'Preparar todas as alterações';

  @override
  String get unstageAll => 'Remover tudo dos preparados';

  @override
  String get stageChangesToCommit => 'Prepare alterações para confirmar';

  @override
  String get syncToPrHead => 'Obter os commits mais recentes da PR';

  @override
  String get syncedToPrHead =>
      'Sincronizado com os commits mais recentes da PR';

  @override
  String get syncPrHeadDirty =>
      'Confirme ou descarte as suas alterações antes de sincronizar';

  @override
  String get syncPrHeadFailed => 'Não foi possível sincronizar com a PR';

  @override
  String get channelLabel => 'Canal';

  @override
  String get keybindingNewChannel => 'Novo canal';

  @override
  String get keybindingCreateANewChannelDescription => 'Criar um novo canal';

  @override
  String get jumpToLatest => 'Ir para o mais recente';

  @override
  String get streaming => 'Transmitindo';

  @override
  String get newMessages => 'Novo';

  @override
  String get copyLink => 'Copiar link';

  @override
  String get linkCopied => 'Link copiado';

  @override
  String get messageTooFarBack => 'A mensagem está muito atrás';

  @override
  String newMessagesCount(int count) {
    return '$count novos';
  }

  @override
  String get agentResponding => 'Agente respondendo';

  @override
  String get agentFinished => 'Agente concluído';

  @override
  String get harnessConnectProviderForModels =>
      'Conecte um fornecedor para ver os modelos.';

  @override
  String get providerSignOut => 'Terminar sessão';

  @override
  String get providerWaitingForDeviceCode =>
      'A aguardar que confirmes o código no navegador…';

  @override
  String get providerDeviceCodeHint =>
      'Verifica se este código corresponde ao mostrado no navegador e depois aprova.';

  @override
  String get providerPlanUsageLoading => 'A verificar a utilização do plano…';

  @override
  String get providerPlanUsageUnavailable =>
      'Este plano não comunicou a utilização.';

  @override
  String providerSignOutConfirmTitle(String provider) {
    return 'Terminar sessão em $provider?';
  }

  @override
  String providerSignOutConfirmBody(String provider) {
    return 'Os agentes que usam modelos $provider deixam de funcionar até iniciares sessão de novo, o que exige todo o processo no navegador.';
  }

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return 'Remover a chave de API de $provider?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'A chave guardada é eliminada e não poderá voltar a ser mostrada. Os agentes que usam modelos $provider deixam de funcionar até colares uma nova.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return 'Remover $provider?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'O fornecedor e a respetiva chave guardada são eliminados. Os agentes fixados nos seus modelos deixam de funcionar.';
  }

  @override
  String get providerApiKeyHint => 'Cole uma chave de API';

  @override
  String get providerApiKeyStoredHint =>
      'Chave de API salva — cole uma nova para substituir';

  @override
  String get providerBaseUrlHint => 'URL base (opcional)';

  @override
  String get customProviders => 'Fornecedores personalizados';

  @override
  String get customProvidersDescription =>
      'Qualquer endpoint compatível com OpenAI ou Anthropic — Ollama, LM Studio, vLLM ou uma implantação privada — com uma chave de API opcional.';

  @override
  String get addProvider => 'Adicionar fornecedor';

  @override
  String get noCustomProviders => 'Ainda não há fornecedores personalizados.';

  @override
  String get providerNameLabel => 'Nome';

  @override
  String get apiTypeLabel => 'Tipo de API';

  @override
  String get providerBaseUrlLabel => 'URL base';

  @override
  String get providerApiKeyOptionalHint => 'Chave de API (opcional)';

  @override
  String get dialectOpenAiCompatible => 'Compatível com OpenAI';

  @override
  String get dialectAnthropicCompatible => 'Compatível com Anthropic';

  @override
  String get removeProviderTooltip => 'Remover fornecedor';

  @override
  String get providerLogInWithBrowser => 'Entrar pelo navegador';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'Entrar em $provider';
  }

  @override
  String get providerLabel => 'Fornecedor';

  @override
  String get selectProviderToLogin => 'Selecione um fornecedor para entrar';

  @override
  String providerLoginFailed(String error) {
    return 'Falha no login: $error';
  }

  @override
  String get providerWaitingForBrowser =>
      'Aguardando sua autorização no navegador…';

  @override
  String get providerPasteCodeHint => 'Ou cole o código do seu navegador';

  @override
  String get providerCompleteLogin => 'Concluir';

  @override
  String get providerConnectedApiKey => 'Conectado via chave de API';

  @override
  String get providerConnectedOauth => 'Conectado';

  @override
  String providerConnectedAccount(String account) {
    return 'Conectado · $account';
  }

  @override
  String get providerLocalReady => 'Local · pronto';

  @override
  String get providerNotConnected => 'Não conectado';

  @override
  String get preparingWorkspace => 'Preparando espaço de trabalho…';

  @override
  String provisioningCloningRepo(String repo) {
    return 'Clonando $repo…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'Obtendo a pull request em $repo…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'Configurando o agente $agent…';
  }

  @override
  String get workspacePrepFailed => 'Falha ao preparar';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count mensagem(s) enviada(s) quando pronto';
  }

  @override
  String get membersNav => 'Membros';

  @override
  String get membersSettingsDescription =>
      'Pessoas com acesso a este espaço de trabalho: lista, convites e trilha de auditoria';

  @override
  String get memberRosterLabel => 'Lista de membros';

  @override
  String get roleOwner => 'Proprietário';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Membro';

  @override
  String get roleViewer => 'Observador';

  @override
  String get roleGuest => 'Convidado';

  @override
  String get removeMemberTitle => 'Remover membro';

  @override
  String removeMemberConfirm(String name) {
    return 'Remover $name deste espaço de trabalho? O acesso é perdido imediatamente.';
  }

  @override
  String get unknownUserLabel => 'Usuário desconhecido';

  @override
  String get inviteMember => 'Convidar membro';

  @override
  String get inviteRepoAccessHeader => 'Acesso aos repositórios';

  @override
  String get inviteRepoAccessExplainer =>
      'Apenas os repositórios marcados são compartilhados com o convidado, no nível escolhido. Todo o resto permanece oculto.';

  @override
  String get grantLevelRead => 'Leitura';

  @override
  String get grantLevelReview => 'Revisão';

  @override
  String get grantLevelWrite => 'Escrita';

  @override
  String get inviteExpiryLabel => 'Expira em';

  @override
  String get expiryOneDay => '1 dia';

  @override
  String get expirySevenDays => '7 dias';

  @override
  String get expiryThirtyDays => '30 dias';

  @override
  String get createInviteAction => 'Criar convite';

  @override
  String get inviteOneTimeCodeLabel => 'Código de uso único';

  @override
  String get inviteCodeShownOnce =>
      'Este código é exibido apenas uma vez — copie-o agora.';

  @override
  String get inviteLinkLabel => 'Link de convite';

  @override
  String get inviteRedeemHint =>
      'Compartilhe o código com o convidado; ele o resgatará com a URL do seu servidor.';

  @override
  String get inviteScanQr => 'Ou escaneie para resgatar';

  @override
  String get inviteLoopbackWarningTitle =>
      'O convite aponta para um endereço local';

  @override
  String get inviteLoopbackWarningBody =>
      'Colaboradores em outras máquinas não poderão acessar este servidor. Inicie um túnel (Configurações → Integrações → Compartilhar este servidor) ou conecte-se à sua rede para que usuários externos possam se conectar.';

  @override
  String get inviteStatusOpen => 'Aberto';

  @override
  String get inviteStatusUsed => 'Usado';

  @override
  String get inviteStatusRevoked => 'Revogado';

  @override
  String get inviteStatusExpired => 'Expirado';

  @override
  String inviteCreatedTime(String time) {
    return 'Criado $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'expira em $date';
  }

  @override
  String get noActivityYet => 'Nenhuma atividade ainda';

  @override
  String get couldNotLoadMembers => 'Não foi possível carregar os membros';

  @override
  String get couldNotLoadInvites => 'Não foi possível carregar os convites';

  @override
  String get couldNotLoadActivity => 'Não foi possível carregar a atividade';

  @override
  String get yourDevices => 'Seus dispositivos';

  @override
  String get yourDevicesDescription =>
      'Clientes pareados com a sua conta neste servidor.';

  @override
  String get noOwnDevices => 'Nenhum dispositivo pareado com a sua conta ainda';

  @override
  String get renameDeviceTitle => 'Renomear dispositivo';

  @override
  String get revokeDeviceTitle => 'Revogar dispositivo';

  @override
  String revokeDeviceConfirm(String label) {
    return 'Revogar $label? Ele é desconectado imediatamente e não pode mais acessar este servidor.';
  }

  @override
  String devicePairedTime(String time) {
    return 'Pareado $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'Visto pela última vez $time';
  }

  @override
  String get deviceNeverSeen => 'Nunca conectado';

  @override
  String get profileSectionLabel => 'Perfil';

  @override
  String get profileSectionDescription =>
      'Como você aparece para a equipe e na autoria dos commits do git.';

  @override
  String get displayNameLabel => 'Nome de exibição';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get gitAuthorNameLabel => 'Nome do autor no git';

  @override
  String get gitAuthorEmailLabel => 'E-mail do autor no git';

  @override
  String get profileSaved => 'Perfil salvo';

  @override
  String get presenceOnline => 'Online';

  @override
  String get presenceIdle => 'Inativo';

  @override
  String get presenceTyping => 'Digitando…';

  @override
  String get presenceAgentThinking => 'Pensando';

  @override
  String get presenceAgentRunning => 'Em execução';

  @override
  String get presenceAgentBlocked => 'Bloqueado';

  @override
  String get presenceAgentDone => 'Concluído';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
  }

  @override
  String get presenceRailLabel => 'Quem está online';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'Ativar não perturbe';

  @override
  String get dndTooltipOff => 'Desativar não perturbe';

  @override
  String get startPresenting => 'Iniciar apresentação';

  @override
  String get stopPresenting => 'Encerrar apresentação';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name está apresentando';
  }

  @override
  String get spotlightLeave => 'Sair';

  @override
  String typingIndicator(String name) {
    return '$name está digitando…';
  }

  @override
  String get ideTabNotes => 'Notas';

  @override
  String get ideSidebarAllViews => 'Todas as vistas';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'Todas as vistas ($count ocultas)';
  }

  @override
  String get ideSidebarPinView => 'Fixar na barra lateral';

  @override
  String get ideSidebarUnpinView => 'Desafixar da barra lateral';

  @override
  String get notesEmptyHint =>
      'Adicione uma nota para quem retomar esta conversa…';

  @override
  String get notesEditTooltip => 'Editar nota';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'Atualizado por $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name está editando';
  }

  @override
  String get notesSaveFailed => 'Não foi possível salvar a nota';

  @override
  String get reactionAddTooltip => 'Adicionar reação';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'Reagir com $emoji';
  }

  @override
  String get autonomyDialLabel => 'Autonomia';

  @override
  String get autonomyProposeOnly => 'Somente propor';

  @override
  String get autonomyActWithApproval => 'Agir com aprovação';

  @override
  String get autonomyActFreely => 'Agir livremente';

  @override
  String get autonomyDefaultOption => 'Padrão';

  @override
  String get checkerLabel => 'Verificador';

  @override
  String get checkerNone => 'Nenhum';

  @override
  String get checkerCaption =>
      'O verificador revisa as execuções concluídas de outros agentes.';

  @override
  String get takeoverTooltip => 'Assumir o controle do worktree';

  @override
  String get takeoverBannerSelf =>
      'Você assumiu o controle do worktree desta conversa';

  @override
  String takeoverBannerOther(String name) {
    return '$name assumiu o controle do worktree desta conversa';
  }

  @override
  String get handBackButton => 'Devolver o controle';

  @override
  String get handBackDialogTitle => 'Devolver o controle do worktree';

  @override
  String get handBackDialogNoteHint => 'Nota opcional para o agente…';

  @override
  String takeoverFailed(String message) {
    return 'Não foi possível assumir o controle: $message';
  }

  @override
  String handBackFailed(String message) {
    return 'Não foi possível devolver o controle: $message';
  }

  @override
  String get planStudioTitle => 'Estúdio de plano';

  @override
  String get plansTitle => 'Planos';

  @override
  String get plansSubtitle => 'Planos ativos, documentos de plano e playbooks';

  @override
  String get plansActiveSection => 'Planos ativos';

  @override
  String get plansDocumentsSection => 'Documentos de plano';

  @override
  String get plansPlaybooksSection => 'Playbooks';

  @override
  String get plansNoActive => 'Ainda não há planos ativos.';

  @override
  String get plansNoDocuments => 'Ainda não há documentos de plano.';

  @override
  String get plansNoPlaybooks => 'Ainda não há playbooks.';

  @override
  String get planNotFound => 'Plano não encontrado.';

  @override
  String get planOpenInStudio => 'Abrir';

  @override
  String get planNodeTitle => 'Título';

  @override
  String get planNodeDescription => 'Descrição';

  @override
  String get planNodeDescriptionHint => 'O que este passo deve fazer…';

  @override
  String get planNodeApplyDescription => 'Aplicar';

  @override
  String get planNodeRole => 'Função';

  @override
  String get planNodeDependencies => 'Depende de';

  @override
  String get planNodeDependenciesHint => 'Adicionar uma dependência';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dependências',
      one: '1 dependência',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'Sem dependências, começa assim que o plano iniciar';

  @override
  String get planNodeOutputSchema => 'Esquema de saída (JSON)';

  @override
  String get planNodeEstimate => 'Estimativa';

  @override
  String get planNodeProvenance => 'Proveniência';

  @override
  String get planNodeAlreadyExecuted =>
      'Já executado — editar bifurca o plano a partir daqui.';

  @override
  String get planNewNodeTitle => 'Novo passo';

  @override
  String get planEstimateNoHistory => 'Ainda sem histórico';

  @override
  String get planEstimateBlastUnknown => 'Raio de impacto: desconhecido';

  @override
  String get planEstimatePartial => 'parcial';

  @override
  String get planEstimateAction => 'Estimar';

  @override
  String planEstimateDuration(String range) {
    return 'Duração $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'Raio de impacto: $files arquivos, $symbols símbolos';
  }

  @override
  String get planApprove => 'Aprovar plano';

  @override
  String get planApproveSelectedNodes => 'Aprovar selecionados';

  @override
  String get planReject => 'Rejeitar';

  @override
  String get planCancel => 'Cancelar execução';

  @override
  String get planContinueNode => 'Continuar nó';

  @override
  String get planTotalNotEstimated => 'Ainda não estimado';

  @override
  String get planBudgetExceeded => 'acima do orçamento';

  @override
  String planBudgetCeiling(String amount) {
    return 'orçamento ≤ $amount \$';
  }

  @override
  String get planVersionsTitle => 'Versões';

  @override
  String get planNoRevisions => 'Ainda sem revisões.';

  @override
  String get planDiffIdentical => 'Sem alterações.';

  @override
  String get planDiffGoalChanged => 'Objetivo alterado';

  @override
  String get planDiffBudgetChanged => 'Orçamento alterado';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'Alterações de v$fromRev para v$toRev';
  }

  @override
  String planDiffAdded(String node) {
    return 'Adicionado $node';
  }

  @override
  String planDiffRemoved(String node) {
    return 'Removido $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return 'Alterado $node: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'Aresta adicionada: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'Aresta removida: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'Função adicionada: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'Função removida: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'Função reatribuída: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'Plano replanejado: você aprovou v$approved, agora é v$current. Revise as diferenças.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'Custo real: $amount \$';
  }

  @override
  String get planPlaybookRun => 'Executar';

  @override
  String get planPlaybookDelete => 'Excluir playbook';

  @override
  String get planPlaybookProposed =>
      'Plano proposto — aprove-o no Estúdio de plano.';

  @override
  String get planPlaybookAnchorTicket => 'Ticket de âncora';

  @override
  String get planPlaybookPickTicket => 'Escolher um ticket…';

  @override
  String get planPlaybookProposeRun => 'Propor plano';

  @override
  String get planPlaybookRepoHint => 'Um id de repositório';

  @override
  String get planPlaybookAgentHint => 'Um id de agente';

  @override
  String planPlaybookRunTitle(String name) {
    return 'Executar $name';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count parâmetros';
  }

  @override
  String get reviewStudioTitle => 'Estúdio de revisão';

  @override
  String get reviewStudioWalkthrough => 'Passo a passo';

  @override
  String get reviewStudioContract => 'Contrato de API';

  @override
  String get reviewStudioVisual => 'Diff visual';

  @override
  String get reviewStudioBlastRadius => 'Raio de impacto';

  @override
  String get reviewStudioRecompute => 'Recalcular';

  @override
  String get reviewStudioCohortsHeader => 'Coortes';

  @override
  String get reviewStudioNoCohorts =>
      'Ainda não há coortes — execute a análise para agrupar esta PR por significado.';

  @override
  String get reviewStudioGroupedByPath =>
      'Agrupado por caminho (repo não indexado)';

  @override
  String get reviewStudioIndexRepo => 'Indexar repo';

  @override
  String reviewStudioFilesCount(int count) {
    return '$count arquivos';
  }

  @override
  String get reviewStudioFilesInCohort => 'Arquivos nesta coorte';

  @override
  String get reviewStudioSelectCohort =>
      'Selecione uma coorte para ver o resumo.';

  @override
  String get reviewStudioSummaryEmpty =>
      'Ainda não há resumo para esta coorte.';

  @override
  String get reviewStudioNoAxes =>
      'Nenhum eixo de revisão foi executado ainda.';

  @override
  String get reviewAxisCorrectness => 'Correção';

  @override
  String get reviewAxisSecurity => 'Segurança';

  @override
  String get reviewAxisTestGap => 'Lacunas de teste';

  @override
  String get reviewAxisPerformance => 'Desempenho';

  @override
  String get reviewAxisVisual => 'Visual';

  @override
  String get reviewAxisApiContract => 'Contrato de API';

  @override
  String get reviewAxisPass => 'Aprovado';

  @override
  String get reviewAxisWarn => 'Aviso';

  @override
  String get reviewAxisFail => 'Falhou';

  @override
  String get reviewAxisPartial => 'Parcial';

  @override
  String get reviewAxisUnavailable => 'Indisponível';

  @override
  String get reviewStudioVerdictShip => 'Enviar';

  @override
  String get reviewStudioVerdictHold => 'Reter';

  @override
  String get reviewStudioVerdictBlock => 'Bloquear';

  @override
  String get reviewStudioVerdictClear => 'Nenhum eixo bloqueia o merge.';

  @override
  String reviewStudioBlockingAxes(String axes) {
    return '$axes bloqueiam o merge';
  }

  @override
  String get reviewStudioNoContractChanges =>
      'Nenhuma alteração de contrato de API nesta PR.';

  @override
  String get reviewStudioBreaking => 'Ruptura';

  @override
  String reviewStudioBreakingCount(int count) {
    return '$count de ruptura';
  }

  @override
  String get reviewStudioDerivedContract => 'Derivado (informativo)';

  @override
  String get reviewStudioApprove => 'Aprovar';

  @override
  String get reviewStudioReject => 'Rejeitar';

  @override
  String get reviewStudioApproved => 'Aprovado';

  @override
  String get reviewStudioRejected => 'Rejeitado';

  @override
  String get reviewStudioNoVisualChanges =>
      'Nenhuma alteração visual detectada.';

  @override
  String get reviewStudioVisualUnavailable => 'Diff visual indisponível';

  @override
  String get reviewStudioApproveChange => 'Aprovar a alteração pretendida';

  @override
  String reviewStudioChangedRegion(String percent) {
    return '$percent% alterado';
  }

  @override
  String get reviewStudioRenderedOnHost => 'Renderizado no host';

  @override
  String get reviewStudioVisualAdded => 'Adicionado';

  @override
  String get reviewStudioVisualChanged => 'Alterado';

  @override
  String get reviewStudioVisualRemoved => 'Removido';

  @override
  String get reviewStudioVisualApproved => 'Aprovado';

  @override
  String get reviewStudioVisualUnchanged => 'Inalterado';

  @override
  String get reviewStudioSelectFileForBlast =>
      'Selecione um arquivo alterado para ver o raio de impacto.';

  @override
  String get reviewStudioNotIndexed =>
      'Repo não indexado — raio de impacto indisponível.';

  @override
  String reviewStudioAffectedCount(int count) {
    return '$count símbolos afetados';
  }

  @override
  String get reviewStudioDirectCallers => 'Chamadores diretos';

  @override
  String reviewStudioTransitiveAt(int depth) {
    return 'Transitivo (salto $depth)';
  }

  @override
  String get recentLabel => 'Recente';

  @override
  String get cheatSheetTitle => 'Atalhos de teclado';

  @override
  String get cheatSheetGlobal => 'Global';

  @override
  String get cheatSheetThisScreen => 'Esta tela';

  @override
  String get cheatSheetReservedInBrowser => 'Reservado pelo navegador';

  @override
  String get keybindingCheatSheet => 'Atalhos de teclado';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      'Mostrar a folha de referência de atalhos de teclado da tela atual';

  @override
  String get runPlaybookLabel => 'Executar playbook';

  @override
  String get playbooksLabel => 'Playbooks';

  @override
  String get keybindingUndo => 'Desfazer';

  @override
  String get keybindingRedo => 'Refazer';

  @override
  String get keybindingUndoLastActionDescription =>
      'Desfazer sua última ação reversível';

  @override
  String get keybindingRedoLastActionDescription =>
      'Refazer a última ação desfeita';

  @override
  String get undone => 'Desfeito';

  @override
  String get redone => 'Refeito';

  @override
  String get undoFailed => 'Não foi possível desfazer';

  @override
  String get undoLabelTicketEdit => 'edição de ticket';

  @override
  String get undoLabelMessageEdit => 'edição de mensagem';

  @override
  String get undoLabelTodoStatus => 'status da tarefa';

  @override
  String get inboxTitle => 'Caixa de entrada';

  @override
  String get inboxReview => 'Revisar';

  @override
  String get inboxOpen => 'Abrir';

  @override
  String get inboxAllCaughtUp => 'Você está em dia';

  @override
  String get inboxSeverityBlocking => 'Bloqueado';

  @override
  String get inboxSeverityWaiting => 'Aguardando';

  @override
  String get inboxSeverityInfo => 'Info';

  @override
  String get inboxSyncFailed => 'Falha na sincronização';

  @override
  String get inboxNeedsYourAttention => 'Precisa da sua atenção';

  @override
  String get inboxSectionNeedsYourReview => 'Aguardando sua revisão';

  @override
  String get inboxSectionReturnedToYou => 'Devolvidas a você';

  @override
  String get inboxSectionApproved => 'Aprovadas';

  @override
  String get inboxSectionDrafts => 'Rascunhos';

  @override
  String get inboxSectionWaitingForReviewers => 'Aguardando revisores';

  @override
  String get inboxSectionMergingAndMerged =>
      'Em merge e mescladas recentemente';

  @override
  String get inboxSectionWaitingForAuthor => 'Aguardando o autor';

  @override
  String get inboxColumnTitle => 'Título';

  @override
  String get inboxColumnChanges => 'Alterações';

  @override
  String get inboxColumnUpdated => 'Atualizado';

  @override
  String get inboxReviewApproved => 'Aprovada';

  @override
  String get inboxReviewChangesRequested => 'Alterações solicitadas';

  @override
  String get inboxHeroSubtitle =>
      'Cada pull request que envolve você, ordenado pelo que vem a seguir.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests precisam da sua revisão',
      one: '1 pull request precisa da sua revisão',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devolvidas a você',
      one: '1 devolvida a você',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted =>
      'Essa alteração não foi salva e foi revertida';

  @override
  String get offlinePendingLabel => 'pendente';

  @override
  String get offlineSyncingLabel => 'sincronizando';

  @override
  String get copyLinkLabel => 'Copiar link desta página';

  @override
  String get fleetTabLabel => 'Frota';

  @override
  String get evalsTabLabel => 'Avaliações';

  @override
  String get agentsSectionLabel => 'Agentes';

  @override
  String get fleetWorkersTitle => 'Trabalhadores';

  @override
  String get fleetWorkersSubtitle =>
      'Máquinas disponíveis para executar trabalhos';

  @override
  String get fleetJobsTitle => 'Trabalhos';

  @override
  String get fleetJobsSubtitle => 'Trabalho distribuído pela frota';

  @override
  String get fleetNoWorkers =>
      'Ainda não há trabalhadores — uma segunda máquina executando `cc_worker --server <url>` entra na frota.';

  @override
  String get fleetNoJobs => 'Sem trabalhos.';

  @override
  String get fleetError => 'Não foi possível carregar a frota';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count núcleos',
      one: '1 núcleo',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'Sinal $time';
  }

  @override
  String get fleetNoHeartbeat => 'Ainda sem sinal';

  @override
  String fleetLastErrorLabel(String error) {
    return 'Último erro: $error';
  }

  @override
  String get fleetDrain => 'Drenar';

  @override
  String get fleetResume => 'Retomar';

  @override
  String get fleetRevoke => 'Revogar';

  @override
  String get fleetRemove => 'Remover';

  @override
  String get fleetRevokeTitle => 'Revogar o trabalhador?';

  @override
  String fleetRevokeBody(String name) {
    return 'Revogar $name? A sessão termina e os trabalhos ativos são reatribuídos.';
  }

  @override
  String get fleetRemoveTitle => 'Remover o trabalhador?';

  @override
  String fleetRemoveBody(String name) {
    return 'Remover $name da frota? Isto exclui o seu registo.';
  }

  @override
  String get fleetActionFailed => 'A ação falhou';

  @override
  String get fleetJobUnassigned => 'Não atribuído';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max tentativas';
  }

  @override
  String get fleetPlacementReasons => 'Decisões de alocação';

  @override
  String get fleetNoPlacements => 'Ainda não há decisões de alocação.';

  @override
  String get fleetStatusOnline => 'Online';

  @override
  String get fleetStatusDraining => 'Drenando';

  @override
  String get fleetStatusOffline => 'Offline';

  @override
  String get fleetStatusIncompatible => 'Incompatível';

  @override
  String get fleetStatusRevoked => 'Revogado';

  @override
  String get fleetJobStatusQueued => 'Em fila';

  @override
  String get fleetJobStatusRunning => 'Em execução';

  @override
  String get fleetJobStatusSucceeded => 'Concluído';

  @override
  String get fleetJobStatusFailed => 'Falhou';

  @override
  String get fleetJobStatusCancelled => 'Cancelado';

  @override
  String get evalsNoSuites => 'Ainda não há suítes de avaliação.';

  @override
  String get evalsError => 'Não foi possível carregar as avaliações';

  @override
  String get evalsStarterBadge => 'Inicial';

  @override
  String evalsDefaultBatch(int count) {
    return 'Lote padrão de $count';
  }

  @override
  String get evalsRecentRuns => 'Execuções recentes';

  @override
  String get evalsNoRuns => 'Ainda não há execuções.';

  @override
  String get evalsPassRate => 'Taxa de aprovação';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return 'por $who';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'Avaliação concluída — $rate aprovado';
  }

  @override
  String get evalsRunFailed => 'Não foi possível executar a suíte';

  @override
  String get evalsRun => 'Executar';

  @override
  String get evalsStatusQueued => 'Em fila';

  @override
  String get evalsStatusRunning => 'Em execução';

  @override
  String get evalsStatusPassed => 'Aprovado';

  @override
  String get evalsStatusFailed => 'Falhou';

  @override
  String get bannerMeetingJoin => 'Entrar';

  @override
  String get bannerMeetingRecordAndLink => 'Gravar e vincular';

  @override
  String get bannerCalendarReconnect => 'Reconectar';

  @override
  String get bannerView => 'Ver';

  @override
  String get soundscapeTitle => 'Paisagens sonoras';

  @override
  String get soundscapePlay => 'Reproduzir';

  @override
  String get soundscapePause => 'Pausar';

  @override
  String get soundscapeMoodLabel => 'Ambiente';

  @override
  String get soundscapeMoodFocus => 'Concentração';

  @override
  String get soundscapeMoodRelax => 'Relaxamento';

  @override
  String get soundscapeMoodSleep => 'Sono';

  @override
  String get soundscapeVolumeLabel => 'Volume';

  @override
  String get soundscapeTuneLabel => 'Ajuste';

  @override
  String get soundscapeTuneMellow => 'Suave';

  @override
  String get soundscapeTuneBright => 'Brilhante';

  @override
  String get soundscapeTuneEnergetic => 'Energético';

  @override
  String get soundscapeTuneSpacy => 'Espacial';

  @override
  String get soundscapeTuneResetHint => 'Toque duas vezes para redefinir';

  @override
  String get soundscapeSceneLabel => 'A reproduzir agora';

  @override
  String get soundscapeSceneLoading => 'A ajustar o ambiente…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees °C';
  }

  @override
  String get soundscapeLocationLabel => 'Localização';

  @override
  String get soundscapeLocationDetecting => 'A detetar a localização…';

  @override
  String get soundscapeLocationAutoNote =>
      'A localização é detetada automaticamente a partir deste espaço de trabalho.';

  @override
  String get soundscapeRefreshWeather => 'Atualizar meteorologia';

  @override
  String get soundscapeAutoStartLabel => 'Iniciar com o modo de concentração';

  @override
  String get soundscapeAutoStartDescription =>
      'Reproduzir uma paisagem sonora automaticamente quando inicia uma sessão de concentração.';

  @override
  String get soundscapeReturnToApp => 'Voltar à aplicação';

  @override
  String get soundscapePopOut => 'Destacar o leitor';

  @override
  String get newParenthesis => 'Novo parêntese';

  @override
  String get parenthesisTitleHint => 'ex. correção rápida';

  @override
  String get discussion => 'Discussão';

  @override
  String get chat => 'Chat';

  @override
  String get saving => 'Salvando…';

  @override
  String get saved => 'Salvo';

  @override
  String get saveFailed => 'Falha ao salvar';

  @override
  String get commitAndPush => 'Confirmar e enviar';

  @override
  String get commit => 'Confirmar';

  @override
  String get commitAmend => 'Confirmar (emendar)';

  @override
  String get commitAndSync => 'Confirmar e sincronizar';

  @override
  String get committed => 'Confirmado';

  @override
  String get commitAmended => 'Confirmação emendada';

  @override
  String get commitFailed => 'Falha ao confirmar';

  @override
  String get moreCommitActions => 'Mais ações de confirmação';

  @override
  String get sourceControl => 'Controle de versão';

  @override
  String fixFindingTitle(String location) {
    return 'Corrigir: $location';
  }

  @override
  String get reviewSplitLayout => 'Layout de revisão';

  @override
  String get openInEditor => 'Abrir no editor';

  @override
  String uncommittedChanges(int count) {
    return '$count alterações não confirmadas';
  }

  @override
  String get commitMessageHint => 'Mensagem de commit';

  @override
  String get pushedToPr => 'Enviado para a PR';

  @override
  String get pushFailed => 'Falha no push';

  @override
  String get openAtPrHead => 'Abrir no head da PR';

  @override
  String get reviewFindings => 'Constatações';

  @override
  String get treeLabel => 'Árvore';

  @override
  String get toggleFileTree => 'Mostrar ou ocultar a árvore de arquivos';

  @override
  String get diffViewSettings => 'Configurações de visualização do diff';

  @override
  String get splitViewLabel => 'Dividida';

  @override
  String get unifiedViewLabel => 'Unificada';

  @override
  String get wrapLines => 'Quebrar linhas';

  @override
  String get shiftClickSelectRange =>
      'Shift-clique para selecionar um intervalo';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos',
      one: '1 arquivo',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'PR pequeno — $files, ~$minutes min de revisão';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'PR médio — $files, reserve ~$minutes min de revisão';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'PR grande — $files, considere dividi-lo antes da revisão';
  }

  @override
  String get searchInFiles => 'Pesquisar em arquivos';

  @override
  String get showFileList => 'Mostrar lista de arquivos';

  @override
  String get searchInFilesHintField => 'Pesquisar em arquivos…';

  @override
  String get searchInFilesHint => 'Pesquisar nos arquivos do pull request';

  @override
  String get searchNoResults => 'Nenhum resultado';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files arquivos',
      one: '1 arquivo',
    );
    return '$_temp0 em $_temp1';
  }

  @override
  String get discardChangesTitle => 'Descartar alterações?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos',
      one: '1 arquivo',
    );
    return 'Redefinir $_temp0 para HEAD? Isso não pode ser desfeito.';
  }

  @override
  String get discardAll => 'Descartar tudo';

  @override
  String get discardFailed => 'Falha ao descartar alterações';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos descartados',
      one: '1 arquivo descartado',
    );
    return '$_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted arquivos descartados',
      one: '1 arquivo descartado',
    );
    return '$_temp0; $skipped ignorado(s) (não rastreado(s))';
  }

  @override
  String get prWorktreeUnavailable => 'Espaço de trabalho não pronto';

  @override
  String get prWorktreeUnavailableHint =>
      'Falha ao preparar os arquivos do pull request. Reabra o pull request para tentar novamente.';

  @override
  String get timestampRelativeLabel => 'Relativo';

  @override
  String get timestampRawLabel => 'Carimbo de data/hora';

  @override
  String get copyTimestamp => 'Copiar carimbo de data/hora';

  @override
  String get copiedTimestamp => 'Carimbo de data/hora copiado';

  @override
  String get previewDeployment => 'Implantação de pré-visualização';

  @override
  String previewDeploymentTab(String site) {
    return 'Pré-visualização: $site';
  }

  @override
  String get askForReview => 'Pedir revisão…';

  @override
  String get closePrsConfirmTitle => 'Fechar as pull requests?';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fechar $count pull requests?',
      one: 'Fechar 1 pull request?',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests fechadas',
      one: '1 pull request fechada',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests atribuídas',
      one: '1 pull request atribuída',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Revisão solicitada em $count pull requests',
      one: 'Revisão solicitada em 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ações falharam',
      one: '1 ação falhou',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'Diagrama';

  @override
  String get diagramViewSource => 'Ver o código-fonte';

  @override
  String get diagramHideSource => 'Ocultar o código-fonte';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'Pré-visualização do diagrama indisponível ($reason)';
  }

  @override
  String get planUnavailable => 'Plano indisponível';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count etapas',
      one: '1 etapa',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'Aprovar e executar';

  @override
  String get planStatusDraft => 'Rascunho';

  @override
  String get planStatusProposed => 'Plano';

  @override
  String get planStatusApproved => 'Plano aprovado';

  @override
  String get planStatusRejected => 'Plano rejeitado';

  @override
  String get planStatusSuperseded => 'Plano substituído';

  @override
  String planRevisionLabel(int revision) {
    return 'Revisão $revision';
  }

  @override
  String get adapterEnforcementTitle => 'O que este adaptador aplica';

  @override
  String get enforcementFiltersToolSurface =>
      'O Control Center escolhe as ferramentas';

  @override
  String get enforcementInterceptsToolCalls =>
      'Cada chamada é verificada antes de ser executada';

  @override
  String get enforcementObservesCompletionContract =>
      'A execução responde pela sua entrega';

  @override
  String get enforcementNativeToolsInterceptable =>
      'As ferramentas próprias do motor são visíveis';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'As ferramentas executadas no processo estão isoladas';

  @override
  String get enforcementYes => 'Sim';

  @override
  String get enforcementNo => 'Não';

  @override
  String get adapterEnforcementCaveats => 'Ressalvas';

  @override
  String get enforcementSummaryModesEnforced => 'Modos aplicados';

  @override
  String get enforcementSummaryModesNotEnforced => 'Modos não aplicados';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ressalvas',
      one: '1 ressalva',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'Os modos somente leitura não são estruturais: o Control Center não pode remover as ferramentas próprias deste motor.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'Sem verificação antes da execução: apenas as chamadas de ferramentas MCP passam pelo Control Center.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'As ferramentas de ficheiros e shell próprias do motor nunca chegam ao Control Center; o isolamento do sistema é a sua única barreira.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'As ferramentas de ficheiros executadas no processo ficam fora do isolamento, por isso a superfície de ferramentas é o único limite do sistema de ficheiros.';

  @override
  String get caveatCompletionContractUnobservable =>
      'O Control Center não pode insistir nem fazer falhar uma execução que termina sem produzir a sua entrega.';

  @override
  String get modeDegraded => 'Degradado';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return 'O modo $mode em $adapter depende apenas do isolamento; as ferramentas de ficheiros do agente não são interceptadas.';
  }

  @override
  String get artifactUnavailable => 'Artefato indisponível';

  @override
  String artifactRevisionLabel(int count) {
    return '$count revisões';
  }

  @override
  String get artifactShowMore => 'Mostrar mais';

  @override
  String get artifactShowLess => 'Mostrar menos';

  @override
  String get artifactCopy => 'Copiar';

  @override
  String get artifactCopied => 'Artefato copiado';

  @override
  String get artifactsTabLabel => 'Artefatos';

  @override
  String get artifactsEmptyTitle => 'Ainda sem artefatos';

  @override
  String get artifactsEmptyBody =>
      'Quando um agente publicar uma tabela, um gráfico ou um diagrama aqui, ele aparecerá nesta lista.';

  @override
  String get artifactRevisionPickerLabel => 'Revisão';

  @override
  String get artifactRestoreRevision => 'Restaurar esta revisão';

  @override
  String get artifactOpenInTab => 'Abrir em uma aba';

  @override
  String get artifactTitleFallback => 'Artefato';

  @override
  String get providerGenerationLabel => 'Padrões de geração';

  @override
  String get providerGenerationHint =>
      'Deixe um campo vazio para usar o padrão do endpoint. Cada modelo publica os seus próprios limites de saída e receitas de amostragem; outros valores podem degradá-lo.';

  @override
  String get providerMaxTokensLabel => 'Tokens de saída máx.';

  @override
  String get providerTemperatureLabel => 'Temperatura';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => 'Padrões de geração guardados';

  @override
  String get providerGenerationInvalid =>
      'Verifique os valores: tokens de saída máx. e top-k têm de ser positivos, temperatura 0–2, top-p 0–1.';

  @override
  String get providerGenerationOverridden => 'Personalizado';

  @override
  String get channelFlyoutNeedsInput => 'Precisa da sua resposta';

  @override
  String get channelFlyoutPreparing => 'A preparar';

  @override
  String get channelFlyoutSetupFailed => 'Falha na configuração';

  @override
  String get channelFlyoutNeverRun => 'Nenhum agente trabalhou aqui ainda';

  @override
  String channelFlyoutContextUsage(String used, String percent) {
    return 'Janela de contexto: $used usados, $percent cheia';
  }

  @override
  String subagentsRunningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subagentes',
      one: '1 subagente',
    );
    return '$_temp0';
  }

  @override
  String get branchNotPushed => 'não enviado';

  @override
  String branchNotOnRemote(String branch) {
    return '“$branch” só existe nesta conversa';
  }

  @override
  String get branchNotOnRemoteHint =>
      'O GitHub nunca viu este branch, por isso um pull request ainda não pode usá-lo. Publicar envia os commits que já estão no worktree — alterações não commitadas ficam intactas.';

  @override
  String get publishBranch => 'Publicar branch';

  @override
  String branchPublished(String branch) {
    return '“$branch” publicado no origin';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'Branch publicado. $count alteração(ões) não commitada(s) não foram incluídas.';
  }

  @override
  String get composePrLoadingBranches => 'A carregar branches do GitHub…';

  @override
  String get composePrBranchesFailed =>
      'Não foi possível carregar os branches do GitHub. Escreva um nome de branch ou verifique a ligação ao GitHub.';

  @override
  String get composePrSubtitleFromChannel =>
      'A partir do branch desta conversa — publique-o primeiro se o GitHub não o conhecer';

  @override
  String get obsTabInsights => 'Resumo';

  @override
  String get obsTabLive => 'Ao vivo';

  @override
  String get obsTabQuality => 'Qualidade';

  @override
  String get obsScreenSubtitle =>
      'Controlo de agentes ao vivo, atribuição de custos, quotas e sinais de qualidade';

  @override
  String get obsRangeLast24h => 'Últimas 24 horas';

  @override
  String get obsRangeLast7d => 'Últimos 7 dias';

  @override
  String get obsRangeLast30d => 'Últimos 30 dias';

  @override
  String get obsRangeAll => 'Desde sempre';

  @override
  String get obsAddFilter => 'Adicionar filtro';

  @override
  String get obsFilterAgent => 'Agente';

  @override
  String get obsFilterModel => 'Modelo';

  @override
  String get obsFilterStatus => 'Estado';

  @override
  String get obsFilterRole => 'Função';

  @override
  String get obsKpiTotalRuns => 'Execuções totais';

  @override
  String get obsKpiTotalCost => 'Custo total';

  @override
  String get obsKpiErrorRate => 'Taxa de erro';

  @override
  String get obsKpiCacheRate => 'Taxa de cache';

  @override
  String get obsKpiTokensPerSec => 'Tokens / s';

  @override
  String get obsKpiAvgLatency => 'Latência média';

  @override
  String get obsKpiTtft => 'Tempo até ao primeiro token';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta vs período anterior';
  }

  @override
  String get obsChartActivity => 'Atividade';

  @override
  String get obsChartCost => 'Custo ao longo do tempo';

  @override
  String get obsLegendRuns => 'Execuções';

  @override
  String get obsLegendErrors => 'Erros';

  @override
  String get obsAgentsTitle => 'Agentes';

  @override
  String obsShowAllAgents(int count) {
    return 'Mostrar os $count agentes';
  }

  @override
  String get obsShowFewerAgents => 'Mostrar menos';

  @override
  String get obsRunsTitle => 'Execuções';

  @override
  String get obsNoRunsInRange => 'Sem execuções neste período';

  @override
  String get obsColTime => 'Hora';

  @override
  String get obsColAgent => 'Agente';

  @override
  String get obsColStatus => 'Estado';

  @override
  String get obsColModel => 'Modelo';

  @override
  String get obsColDuration => 'Duração';

  @override
  String get obsColTokens => 'Tokens';

  @override
  String get obsColCost => 'Custo';

  @override
  String get obsColErrors => 'Erros';

  @override
  String get obsColRuns => 'Execuções';

  @override
  String get obsColAvgLatency => 'Latência média';

  @override
  String get obsColLastActive => 'Última atividade';

  @override
  String get obsStatusPending => 'Pendente';

  @override
  String get obsStatusRunning => 'Em curso';

  @override
  String get obsStatusCompleted => 'Concluída';

  @override
  String get obsStatusError => 'Erro';

  @override
  String get obsRosterLoadError =>
      'Não foi possível carregar a lista de agentes.';

  @override
  String get obsRosterEmpty => 'Ainda sem agentes';

  @override
  String get obsRosterEmptyDescription =>
      'Execute um agente e ele aparecerá aqui ao vivo — estado, ferramenta atual, tokens, custo.';

  @override
  String get obsKillAgent => 'Terminar agente';

  @override
  String get obsRosterTokensLabel => 'tok';

  @override
  String get obsCostByRoleTitle => 'Custo por função';

  @override
  String get obsCostByRoleSubtitle =>
      'Onde este espaço gasta, por função do agente';

  @override
  String get obsRoleMain => 'Principal';

  @override
  String get obsRoleSubagents => 'Subagentes';

  @override
  String get obsRoleAdvisor => 'Consultor';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'Principal: $main · subagentes: $sub · consultor: $advisor';
  }

  @override
  String get obsTotal => 'Total';

  @override
  String get obsTokenModelTitle => 'Modelo de tokens (5 eixos)';

  @override
  String get obsTokenModelSubtitle =>
      'Todos os tokens gastos por este espaço, por eixo';

  @override
  String get obsAxisInput => 'Entrada';

  @override
  String get obsAxisOutput => 'Saída';

  @override
  String get obsAxisReasoning => 'Raciocínio';

  @override
  String get obsAxisCacheRead => 'Leitura de cache';

  @override
  String get obsAxisCacheWrite => 'Escrita de cache';

  @override
  String get obsTotalTokens => 'Tokens totais';

  @override
  String get obsCacheDiscountNote =>
      'Os tokens lidos da cache são faturados com desconto, pelo que custam muito menos do que o mesmo volume de nova entrada.';

  @override
  String get obsByModelTitle => 'Por modelo';

  @override
  String get obsByModelSubtitle => 'Utilização de tokens e custo por modelo';

  @override
  String get obsNoModelUsage => 'Ainda sem utilização de modelos registada.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count execuções',
      one: '1 execução',
    );
    return '$_temp0';
  }

  @override
  String obsTokensSuffix(String tokens) {
    return '$tokens tokens';
  }

  @override
  String get obsPerRunTitle => 'Por execução';

  @override
  String get obsPerRunSubtitle => 'Custo típico em tokens de uma execução';

  @override
  String get obsMedianRunTokens => 'Tokens medianos por execução';

  @override
  String get obsMedianRunTokensSub => 'Mediana de todas as execuções';

  @override
  String get obsRunsInWorkspace => 'Neste espaço';

  @override
  String get obsCostShare => 'Quota do custo';

  @override
  String get obsQuotaConfiguredLimits => 'Limites configurados';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'Utilização face aos limites definidos, o pior estado primeiro.';

  @override
  String get obsQuotaAddLimit => 'Adicionar limite';

  @override
  String get obsQuotaNoLimits =>
      'Ainda sem limites de quota configurados — adicione um para acompanhar a utilização face a um teto.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'Remover o limite $title';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'Repor em $duration · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'Janelas de utilização';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'Utilização observada em todos os fornecedores, sem teto aplicado.';

  @override
  String get obsQuotaNoUsage => 'Ainda sem utilização registada.';

  @override
  String get obsQuotaTokensUsed => 'Tokens usados';

  @override
  String get obsQuotaRequests => 'Pedidos';

  @override
  String get obsQuotaUnitTokens => 'tokens';

  @override
  String get obsQuotaUnitRequests => 'pedidos';

  @override
  String get obsQuotaUnitCost => 'custo';

  @override
  String get obsQuotaAddLimitTitle => 'Adicionar limite de quota';

  @override
  String get obsQuotaProviderLabel => 'Fornecedor';

  @override
  String get obsQuotaWindowLabel => 'Janela';

  @override
  String get obsQuotaUnitLabel => 'Unidade';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'Limite ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'Em cêntimos americanos (500 = \$5.00).';

  @override
  String get obsQuotaStatusOk => 'Ok';

  @override
  String get obsQuotaStatusWarning => 'Aviso';

  @override
  String get obsQuotaStatusExhausted => 'Esgotado';

  @override
  String get obsQuotaStatusUnknown => 'Desconhecido';

  @override
  String get obsGoalNoActiveTitle => 'Sem objetivo ativo';

  @override
  String get obsGoalNoActiveBody =>
      'Defina um objetivo para dar aos agentes um propósito e um orçamento de tokens opcional. À medida que as execuções terminam, o orçamento enche e os agentes são incentivados a concluir quando estiver quase esgotado.';

  @override
  String get obsGoalSetGoal => 'Definir objetivo';

  @override
  String get obsGoalTokenBudget => 'Orçamento de tokens';

  @override
  String obsGoalTokensLeft(String tokens) {
    return '$tokens restantes';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (sem orçamento definido)';
  }

  @override
  String get obsGoalTokensUsed => 'Tokens usados';

  @override
  String get obsGoalElapsed => 'Decorrido';

  @override
  String get obsGoalWrapUp => 'Concluir';

  @override
  String get obsGoalClear => 'Limpar objetivo';

  @override
  String get obsGoalFallbackTitle => 'Objetivo';

  @override
  String get obsGoalSubtitle => 'Orçamento do modo objetivo';

  @override
  String get obsGoalStatusActive => 'Ativo';

  @override
  String get obsGoalStatusPaused => 'Em pausa';

  @override
  String get obsGoalStatusBudgetLimited => 'Orçamento limitado';

  @override
  String get obsGoalStatusComplete => 'Concluído';

  @override
  String get obsGoalStatusDropped => 'Abandonado';

  @override
  String get obsGoalObjectiveLabel => 'Objetivo';

  @override
  String get obsGoalBudgetLabel => 'Orçamento de tokens (opcional)';

  @override
  String get obsGoalSetAction => 'Definir objetivo';

  @override
  String get obsBenchmarkCaption =>
      'Uma vista pontuada das execuções recentes dos agentes — sucesso/falha, recompensa e gasto por tarefa.';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => 'Sucesso %';

  @override
  String get obsBenchmarkPassed => 'Aprovadas';

  @override
  String get obsBenchmarkFailed => 'Falhadas';

  @override
  String get obsBenchmarkErrors => 'Erros';

  @override
  String get obsBenchmarkSpend => 'Gasto';

  @override
  String get obsBenchmarkCostPerTask => 'Custo / tarefa';

  @override
  String get obsBenchmarkTrials => 'Ensaios';

  @override
  String get obsBenchmarkNoTrials => 'Ainda sem execuções para pontuar.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'e mais $count',
      one: 'e mais 1',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'Aprovado';

  @override
  String get obsBenchmarkTrialFail => 'Falhado';

  @override
  String get obsBenchmarkTrialError => 'Erro';

  @override
  String get obsBenchmarkTrialRunning => 'Em curso';

  @override
  String get obsBenchmarkReward => 'Recompensa';

  @override
  String get obsBenchmarkReport => 'Relatório';

  @override
  String get obsBenchmarkCopyMarkdown => 'Copiar markdown';

  @override
  String get obsBenchmarkCopied =>
      'Relatório copiado para a área de transferência';

  @override
  String get obsBehaviorCaption =>
      'Estes são sinais de frustração extraídos das suas próprias mensagens — uma leitura da saúde da conversa, não uma nota para os agentes. Calculado localmente; nada sai deste dispositivo.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'Mensagens analisadas';

  @override
  String get obsBehaviorTotalSignals => 'Sinais totais';

  @override
  String get obsBehaviorYelling => 'Gritos';

  @override
  String get obsBehaviorProfanity => 'Palavrões';

  @override
  String get obsBehaviorAnguish => 'Angústia';

  @override
  String get obsBehaviorNegation => 'Negação';

  @override
  String get obsBehaviorRepetition => 'Repetição';

  @override
  String get obsBehaviorBlame => 'Culpa';

  @override
  String get obsBehaviorConversationsTitle => 'Conversas mais frustradas';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'Ordenadas por densidade de sinais nas suas mensagens.';

  @override
  String get obsBehaviorNoSignals =>
      'Nenhum sinal de frustração detetado — tudo tranquilo.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count mensagens analisadas';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count sinais';
  }

  @override
  String get obsAgentStatusIdle => 'Inativo';

  @override
  String get obsAgentStatusParked => 'Estacionado';

  @override
  String get obsAgentStatusAborted => 'Abortado';

  @override
  String get obsAgentKindSub => 'Subagente';

  @override
  String get noChecksOnCommit =>
      'Nenhuma verificação foi executada neste commit.';

  @override
  String get ciCdChecks => 'CI/CD checks';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Em execução — $count jobs',
      one: 'Em execução — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Todas as verificações passaram — $count jobs',
      one: 'Todas as verificações passaram — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Concluído — $count jobs',
      one: 'Concluído — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total jobs',
      one: '1 job',
    );
    return '$failed de $_temp0 com falha';
  }

  @override
  String checksFailingBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count com falha',
      one: '1 com falha',
    );
    return '$_temp0';
  }

  @override
  String get checkCompletedSuccessfully => 'Concluído com sucesso';

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jobs',
      one: '1 job',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'Matriz: $jobId';
  }

  @override
  String get jobLogsPending => 'Os logs aparecerão aqui quando o job terminar.';

  @override
  String get jobLogsUnavailable =>
      'Os logs não estão disponíveis para este job.';

  @override
  String get noLogsForStep => 'Nenhum log capturado para esta etapa.';

  @override
  String get jobLogsTruncated =>
      'Log truncado — a mostrar a saída mais recente.';

  @override
  String get fullLog => 'Log completo';

  @override
  String get copyLogs => 'Copiar logs';

  @override
  String get resizeGraph => 'Arraste para redimensionar o grafo';

  @override
  String workflowRunStartedAgo(String time) {
    return 'Iniciado $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'Concluído $time';
  }

  @override
  String get chatBridgesTitle => 'Pontes de chat';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'Mencione o bot no $provider para encarregar um agente, ou abra tickets com $command.';
  }

  @override
  String chatConnectProvider(String provider) {
    return 'Conectar $provider';
  }

  @override
  String get chatDisconnectProvider => 'Desconectar';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName em $teamName';
  }

  @override
  String get chatStateLive => 'Ativo';

  @override
  String get chatStateConnecting => 'Conectando…';

  @override
  String get chatStateError => 'Erro de conexão';

  @override
  String get chatNotConnected => 'Não conectado';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'O streaming ao vivo está desligado para este app do $provider — as respostas chegam numa única mensagem.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'Só um administrador pode conectar o $provider neste espaço de trabalho.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'Crie um app do $provider e cole aqui as credenciais. O Control Center conecta-se para fora até o $provider, então este servidor não precisa de endereço público.';
  }

  @override
  String chatOpenConsole(String provider) {
    return 'Abrir o console do $provider';
  }

  @override
  String get chatOpenSetupGuide => 'Guia de configuração';

  @override
  String get chatFieldBotToken => 'Token do bot';

  @override
  String get chatFieldAppToken => 'Token de aplicação';

  @override
  String get chatFieldConfigRefreshToken => 'Token de configuração do app';

  @override
  String chatFieldOptional(String label) {
    return '$label (opcional)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'Vincular minha conta do $provider';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'Vincule sua conta do $provider para que as mensagens que você envia lá sejam atribuídas a você.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'Vinculado a $externalUserId';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'Vincule sua conta do $provider';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'Envie este comando ao bot no $provider. Funciona uma vez e expira em 15 minutos.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'A sua conta $provider já está associada — as mensagens que enviar lá são atribuídas a si.';
  }

  @override
  String get chatLinkedAccounts => 'Contas vinculadas';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'Ninguém vinculou a conta do $provider ainda.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contas vinculadas',
      one: '1 conta vinculada',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · associado por e-mail';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · vinculado com um código';
  }

  @override
  String get chatUnlink => 'Desvincular';

  @override
  String get chatCustomizeBot => 'Personalizar o bot';

  @override
  String get chatCustomizeBotDescription =>
      'Renomeie o bot, mude o que ele diz sobre si mesmo ou renomeie o comando.';

  @override
  String get chatCustomizeBotUnavailable =>
      'O Control Center precisa de um token de configuração do app para editar o bot. Reconecte incluindo um.';

  @override
  String chatCreateAppTitle(String provider) {
    return 'Criar o app do $provider';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'O Control Center pode criar o app do $provider para você, com as permissões e os eventos certos já definidos. Você termina no $provider e depois cola as credenciais aqui.';
  }

  @override
  String get chatCreateApp => 'Criar app';

  @override
  String get chatCreateAppCta => 'Criar o app para mim';

  @override
  String get chatAppNameLabel => 'Nome do app';

  @override
  String get chatBotDisplayNameLabel => 'Nome do bot (o que se digita após @)';

  @override
  String get chatDescriptionLabel => 'Descrição curta';

  @override
  String get chatAgentDescriptionLabel => 'O que o bot diz que sabe fazer';

  @override
  String get chatCommandLabel => 'Comando';

  @override
  String get chatDirectMessages => 'Mensagens diretas';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'Permite conversar com o bot numa mensagem direta. Pode exigir um plano pago do $provider.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return 'O $provider criou o app $appId.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'Faltam alguns passos, e só o $provider pode fazê-los:';
  }

  @override
  String get chatStepAppToken => 'Gerar um token de aplicação';

  @override
  String get chatStepInstall => 'Instalar o app';

  @override
  String get chatOpenAppSettings => 'Abrir as configurações do app';

  @override
  String get chatContinueToCredentials => 'Colar as credenciais';

  @override
  String chatBotUpdated(String provider) {
    return 'Bot atualizado no $provider.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return 'O $provider alterou as permissões do app. Reinstale-o para que passem a valer.';
  }

  @override
  String get chatReinstallApp => 'Reinstalar o app';

  @override
  String chatIconNotEditable(String provider) {
    return 'O ícone do bot só pode ser alterado nas configurações de app do $provider.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'Também podes criá-la no $provider, sem token. As configurações acima seguem com o link.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'Criar no $provider';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return 'O $provider abriu no teu navegador com esta configuração pré-preenchida. Cria a app lá, conclui estes passos e volta com os tokens.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return 'O $provider não informa qual app criou, por isso personalizar o bot a partir daqui exigirá mais tarde um token de configuração da app.';
  }

  @override
  String get chatStepCreateApp =>
      'Criar a app a partir da configuração pré-preenchida';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'Escolhe um espaço de trabalho no $provider e confirma.';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens, com o âmbito connections:write.';

  @override
  String get chatStepInstallHint =>
      'Install app → copia o token OAuth do utilizador bot.';

  @override
  String get calendarUseBuiltinApp => 'Usar a app Google do Control Center';

  @override
  String get calendarUseBuiltinAppHint =>
      'Autoriza com a tua conta Google. Nada para configurar no Google Cloud.';

  @override
  String get calendarUseOwnClient => 'Usar o meu cliente do Google Cloud';

  @override
  String get calendarUseOwnClientHint =>
      'Introduz um cliente OAuth do teu projeto do Google Cloud.';

  @override
  String get aboutTitle => 'Sobre';

  @override
  String get aboutAppVersion => 'Versão do aplicativo';

  @override
  String get aboutServerVersion => 'Servidor conectado';

  @override
  String get aboutRpcCatalog => 'Catálogo RPC';

  @override
  String get aboutServerUnknown => 'Não relatado';

  @override
  String get serverStaleTitle =>
      'O servidor integrado é anterior a este aplicativo';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'O cc_server em execução é $serverVersion enquanto este aplicativo é $appVersion. Reinicie o aplicativo para que ele use a versão mais recente do servidor integrado; em desenvolvimento, recompile-o com `dart build cli` em apps/cc_server.';
  }

  @override
  String get updateCheckButton => 'Verificar atualizações';

  @override
  String get updateChecking => 'Verificando atualizações…';

  @override
  String get updateUpToDate => 'Você está atualizado';

  @override
  String get updateDeferredBusy =>
      'Uma atualização está pronta, mas uma reunião está sendo gravada — ela será oferecida após o término.';

  @override
  String get updateOpenedReleasesPage =>
      'A página de versões foi aberta no seu navegador.';

  @override
  String get updateCheckFailed => 'Falha ao verificar atualizações';

  @override
  String updateAvailableVersion(String version) {
    return 'A versão $version está disponível.';
  }

  @override
  String get updateBannerTitle =>
      'Uma nova versão do Control Center está disponível';

  @override
  String get updateBannerRefresh => 'Atualizar';

  @override
  String get updateBlockedRecording =>
      'A atualização está pausada enquanto uma reunião é gravada — a página será recarregada ao terminar.';

  @override
  String get settingsScopeYou => 'Você';

  @override
  String get settingsScopeWorkspace => 'Espaço de trabalho';

  @override
  String get settingsScopeServer => 'Servidor';

  @override
  String get settingsProfile => 'Perfil e identidade';

  @override
  String get settingsYourDevices => 'Seus dispositivos';

  @override
  String get settingsWorkspaceGeneral => 'Geral';

  @override
  String get settingsServerConnection => 'Conexão e status';

  @override
  String get settingsServerSharing => 'Compartilhamento e acesso remoto';

  @override
  String get settingsModelProviders => 'Provedores de modelos';

  @override
  String get settingsVoiceModels => 'Modelos de voz e reunião';

  @override
  String get settingsDiagnostics => 'Diagnóstico e privacidade';

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get settingsScopeBadgeYou => 'VOCÊ';

  @override
  String get settingsScopeBadgeDevice => 'ESTE DISPOSITIVO';

  @override
  String get settingsScopeBadgeWorkspace => 'ESPAÇO DE TRABALHO';

  @override
  String get settingsScopeBadgeServer => 'SERVIDOR';

  @override
  String get settingsProfileDescription =>
      'Seu nome, e-mail e a identidade git aplicada aos commits feitos em seu nome.';

  @override
  String get settingsServerConnectionDescription =>
      'A qual servidor este cliente se conecta e o que ele relata.';

  @override
  String get settingsServerSharingDescription =>
      'Anuncie este servidor na rede local ou exponha-o por um túnel.';

  @override
  String get settingsAboutDescription =>
      'Identidade da compilação e atualizações.';

  @override
  String get settingsDiagnosticsDescription =>
      'Isolamento, indexação, sincronização, registro e relatórios de erro desta instalação.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'Identidade, políticas e convenções compartilhadas por todos neste espaço de trabalho.';

  @override
  String get settingsWorkspacePolicyLabel => 'Política do espaço de trabalho';

  @override
  String get settingsWorkspacePolicyDescription =>
      'Aplica-se a cada membro e cada agente deste espaço de trabalho.';

  @override
  String get settingsSecretGlobsLabel => 'Caminhos secretos excluídos';

  @override
  String get settingsSecretGlobsHelp =>
      'Um padrão por linha. Esses caminhos ficam ocultos para leitores e convidados nas superfícies de código, além dos padrões internos.';

  @override
  String get settingsReviewConcurrencyLabel => 'Revisores em paralelo';

  @override
  String get settingsReviewConcurrencyHelp =>
      'Quantos revisores são despachados em paralelo quando nenhum número é informado.';

  @override
  String get settingsWorkspaceAdminOnly =>
      'Apenas administradores do espaço de trabalho podem alterar isso.';

  @override
  String get chatMyAccountsTitle => 'Contas de chat vinculadas';
}
