// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get navCalendar => 'Calendário';

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
  String get profileStateOpenHint => 'Atualmente abertos';

  @override
  String get profileStateMergedHint => 'Histórico mesclado';

  @override
  String get profileStateClosedHint => 'Fechados, não mesclados';

  @override
  String get profileNoPrsForFilter =>
      'Nenhum pull request para os estados selecionados';

  @override
  String get byAuthorPrefix => 'por';

  @override
  String get youLabel => 'você';

  @override
  String get readyToMerge => 'Pronto para mesclar';

  @override
  String get laneReadyHint => 'Verificações ok';

  @override
  String get laneReviewHint => 'Aguardando você';

  @override
  String get inProgress => 'Em andamento';

  @override
  String get laneInProgressHint => 'Aberto · em andamento';

  @override
  String get needsAttention => 'Requer atenção';

  @override
  String get laneAttentionHint => 'Com falhas ou obsoleto';

  @override
  String get drafts => 'Rascunhos';

  @override
  String get laneDraftsHint => 'Ainda não abertos';

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
  String get mergeReadyAction => 'Mesclar prontas';

  @override
  String get nothingInLane => 'Nada nesta faixa';

  @override
  String get nothingInLaneHint =>
      'Escolha outra faixa acima ou mostre todas as PRs abertas.';

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
  String get mergeReadyConfirmTitle => 'Mesclar PRs prontas?';

  @override
  String mergeReadyConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mesclar com squash $count PRs prontas? Não pode ser desfeito.',
      one: 'Mesclar com squash 1 PR pronta? Não pode ser desfeito.',
    );
    return '$_temp0';
  }

  @override
  String mergedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count PRs mescladas',
      one: '1 PR mesclada',
    );
    return '$_temp0';
  }

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
  String get kbSelect => 'selecionar';

  @override
  String get kbMerge => 'mesclar';

  @override
  String get kbOpen => 'abrir';

  @override
  String get kbPeek => 'espiar';

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
      'Nomenclatura de branches, voz, busca semântica, privacidade e registro.';

  @override
  String get agentRegistry => 'Registro de agentes';

  @override
  String get settingsGroupGeneral => 'Geral';

  @override
  String get settingsGroupAgents => 'Agentes';

  @override
  String get settingsGroupResources => 'Recursos';

  @override
  String get filterSettingsHint => 'Filtrar configurações';

  @override
  String get needsSetupLabel => 'Requer configuração';

  @override
  String noSettingsMatch(String query) {
    return 'Nenhuma configuração corresponde a \"$query\"';
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
  String get agentsLabel => 'AGENTES';

  @override
  String get agentsMentionSection => 'Agentes';

  @override
  String get aiReview => 'Revisão IA';

  @override
  String get all => 'Tudo';

  @override
  String get allAgentsAlreadyInChannel =>
      'Todos os agentes já estão neste canal.';

  @override
  String allAgentsCount(int count) {
    return 'Todos os agentes · $count';
  }

  @override
  String get allCommits => 'Todos os commits';

  @override
  String get allSessionsReset =>
      'Todas as sessões de sandbox foram redefinidas.';

  @override
  String get allSources => 'Todas as fontes';

  @override
  String get allStarBadge => 'All-Star';

  @override
  String get allTimeLabel => 'Total';

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
  String get avgDuration => 'Duração média';

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
  String get blockingLabel => 'Bloqueando';

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
  String get centurionBadge => 'Centurião';

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
  String get closeThread => 'Fechar tópico';

  @override
  String get closed => 'Fechado';

  @override
  String get codeFont => 'Fonte de código';

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
  String get continueLabel => 'Continuar';

  @override
  String get conversationMode => 'Modo de conversa';

  @override
  String get convertToGroup => 'Converter em grupo?';

  @override
  String get convertToGroupBody =>
      'Adicionar outro agente converte esta conversa numa conversa de grupo.';

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
  String defaultPort(int port) {
    return 'Predefinição: $port.';
  }

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
  String get diffWorkerPool => 'Pool de workers';

  @override
  String get directMessage => 'Mensagem direta';

  @override
  String get directMessages => 'Mensagens diretas';

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
  String get earnTiersDescription => 'Ganhe níveis usando o Control Center';

  @override
  String get edit => 'Editar';

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
  String get onboardingDiarizationTitle => 'Diarização de falantes (opcional)';

  @override
  String get onboardingDiarizationSubtitle =>
      'Baixe para identificar cada falante (Pessoa 1, Pessoa 2…) nas notas de reunião. Você pode adicionar isso depois nas configurações.';

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
  String get erroredLabel => 'Com erros';

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
  String get firstReviewBadge => 'Primeira revisão';

  @override
  String get fix => 'Corrigir';

  @override
  String get fixSelected => 'Corrigir selecionado';

  @override
  String get flawlessBadge => 'Impecável';

  @override
  String get forks => 'Forks';

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
  String get githubStatusAllOperational => 'Todos os sistemas operacionais';

  @override
  String get githubStatusComponents => 'Componentes';

  @override
  String get githubStatusFetchFailed =>
      'Não foi possível contactar githubstatus.com';

  @override
  String get githubStatusIncidents => 'Incidentes ativos';

  @override
  String get githubStatusOpenInBrowser => 'Abrir githubstatus.com';

  @override
  String get githubStatusRefresh => 'Atualizar';

  @override
  String get githubStatusTitle => 'Estado do GitHub';

  @override
  String githubStatusUpdated(String time) {
    return 'Atualizado $time';
  }

  @override
  String lastChecked(String time) {
    return 'Verificado $time';
  }

  @override
  String get lastCheckedRecently => 'Verificado recentemente';

  @override
  String get githubToken => 'Token do GitHub';

  @override
  String get giveAgentsAMemory => 'Dê memória aos agentes.';

  @override
  String get giveYourWorkAHome => 'Dê um lar ao seu trabalho.';

  @override
  String get goBack => 'Voltar';

  @override
  String get goForward => 'Avançar';

  @override
  String get googleFonts => 'Google Fonts';

  @override
  String get groupLabel => 'Grupo';

  @override
  String get groupName => 'Nome do grupo';

  @override
  String get groups => 'Grupos';

  @override
  String get hideContainerTerminal => 'Ocultar terminal do contentor';

  @override
  String get high => 'Alto';

  @override
  String get hotStreakBadge => 'Sequência quente';

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
  String get idleStatus => 'Inativo';

  @override
  String get images => 'Imagens';

  @override
  String get inFlightLabel => 'Em progresso';

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
  String jobCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count tarefa$_temp0';
  }

  @override
  String get justNow => 'agora mesmo';

  @override
  String get keepMessages => 'Manter mensagens';

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
  String get keybindingConversationTab => 'Separador conversação';

  @override
  String get keybindingCreateANewAgentDescription => 'Criar um novo agente';

  @override
  String get keybindingCreateANewGroupChannelDescription =>
      'Criar um novo canal de grupo';

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
  String get keybindingFilesChangedTab => 'Separador ficheiros alterados';

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
  String get keybindingGoToAnalytics => 'Ir para análises';

  @override
  String get keybindingGoToDashboard => 'Ir para o painel';

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
  String get keybindingNavigateToTheAnalyticsDashboardDescription =>
      'Navegar para o painel de análises';

  @override
  String get keybindingNavigateToTheGlobalDashboardDescription =>
      'Navegar para o painel global';

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
  String get keybindingNewDirectMessage => 'Nova mensagem direta';

  @override
  String get keybindingNewGroup => 'Novo grupo';

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
  String get keybindingRefreshAnalyticsDataDescription =>
      'Atualizar dados de análises';

  @override
  String get keybindingRefreshDashboardDataDescription =>
      'Atualizar dados do painel';

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
  String get keybindingStartANewDirectMessageDescription =>
      'Iniciar uma nova mensagem direta';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Alternar entre modo claro e escuro';

  @override
  String get keybindingSwitchToTheConversationTabDescription =>
      'Mudar para o separador de conversação';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Mudar para o oitavo espaço de trabalho';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Mudar para o quinto espaço de trabalho';

  @override
  String get keybindingSwitchToTheFilesChangedTabDescription =>
      'Mudar para o separador de ficheiros alterados';

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
  String lastMonths(int count) {
    return 'Últimos $count meses';
  }

  @override
  String get latestLabel => 'Recentes';

  @override
  String get leaderboardLabel => 'RANKING';

  @override
  String get leaderboardLabelShort => 'Ranking';

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
  String levelLabel(int level) {
    return 'Nível $level';
  }

  @override
  String get liveDiff => 'Diff em tempo real';

  @override
  String get liveSync => 'Sincronização em tempo real';

  @override
  String get loadingAgents => 'Carregando agentes…';

  @override
  String get loadingModels => 'Carregando modelos…';

  @override
  String get lockedLabel => 'Bloqueado';

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
  String get manageWorkspaces => 'Gerenciar espaços de trabalho';

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
    return 'Escutando em 127.0.0.1:$port.';
  }

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
  String get mergeMasterBadge => 'Mestre do merge';

  @override
  String get merged => 'Mesclado';

  @override
  String get messagePlaceholder =>
      'Mensagem… (@ para mencionar, / para comandos)';

  @override
  String get messagingLabel => 'Mensagens';

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
  String get navAnalytics => 'Análises';

  @override
  String get navDashboard => 'Painel';

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
  String get newGroup => 'Novo grupo';

  @override
  String get newLabel => 'Novo';

  @override
  String get newMessage => 'Nova mensagem';

  @override
  String get newPolicy => 'Nova política';

  @override
  String get newPrToReview => 'Nova PR para rever';

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
  String get noAgentsConfigured => 'Nenhum agente configurado';

  @override
  String get noAgentsDiscovered => 'Nenhum agente descoberto';

  @override
  String get noAgentsDiscoveredHint =>
      'Clique em \"Descobrir\" para procurar ficheiros AGENTS.md ou \"Adicionar agente\" para configurar manualmente';

  @override
  String get noAgentsMatchSearch => 'Nenhum agente corresponde à sua pesquisa';

  @override
  String get noAgentsRegisteredYet => 'Nenhum agente registrado ainda';

  @override
  String get noArticlesYet => 'Ainda não há artigos';

  @override
  String get noArticlesYetBody => 'Os artigos dos seus feeds aparecerão aqui.';

  @override
  String get noData => 'Sem dados';

  @override
  String get noDirectMessagesYet => 'Nenhuma mensagem direta ainda';

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
  String get noGroupsYet => 'Nenhum grupo ainda';

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
  String get notEarnedYet => 'Ainda não obtido';

  @override
  String get notFoundLabel => 'Não encontrado';

  @override
  String get notYetSpawned => 'Ainda não iniciado';

  @override
  String get notes => 'Notas';

  @override
  String get notificationAgentFinished => 'Agente finalizado';

  @override
  String get notificationExternalPr => 'PRs externas';

  @override
  String get notificationNewMessages => 'Novas mensagens';

  @override
  String get notificationPrMerged => 'PR mesclada';

  @override
  String get notificationPrPublished => 'PR publicada';

  @override
  String get notifications => 'Notificações';

  @override
  String get notifyAgentRunCompleted =>
      'Notificar quando um agente concluir uma execução.';

  @override
  String get notifyExternalPr =>
      'Notificar quando uma nova PR for detectada via polling.';

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
  String get onboardingLinuxDescription =>
      'O Control Center pode utilizar containers Linux para isolar a execução de agentes.';

  @override
  String get onboardingMacosDescription =>
      'O Control Center utiliza sandbox nativo no macOS para isolar a execução de agentes.';

  @override
  String get onboardingUnsupportedDescription =>
      'Sandbox não está disponível nesta plataforma. A execução de agentes será sem isolamento.';

  @override
  String get openAction => 'Abrir';

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
  String get perfectionistBadge => 'Perfeccionista';

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
  String get portLabel => 'Porta';

  @override
  String get postingEllipsis => 'A publicar...';

  @override
  String get prCommits => 'Commits';

  @override
  String get prDescriptionPlaceholder => 'Descrição da PR em Markdown...';

  @override
  String get prDraftCreated => 'Rascunho de PR criado';

  @override
  String get prMachineBadge => 'Máquina de PR';

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
  String get priorityReviews => 'Revisões prioritárias';

  @override
  String get priorityReviewsDescription =>
      'Revisões prioritárias e visão geral do repositório.';

  @override
  String get progressLabel => 'Progresso';

  @override
  String get proposeToCreateDomain =>
      'Proponha um facto ou política para criar um.';

  @override
  String get prsCreated => 'PRs criadas';

  @override
  String get prsCreatedLabel => 'PRs criadas';

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
  String get resolve => 'Resolver';

  @override
  String get resolved => 'Resolvido';

  @override
  String get restartServerToApply =>
      'Reinicie o servidor para aplicar as alterações.';

  @override
  String get restartShell => 'Reiniciar shell';

  @override
  String get restartToApply =>
      'Reinicie o servidor para aplicar as alterações.';

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
  String get reviewsLabel => 'Revisões';

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
  String get runningStatus => 'Em execução';

  @override
  String get runs => 'Execuções';

  @override
  String get runsAcrossAllAgents => 'Execuções em todos os agentes';

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
  String get sharpshooterBadge => 'Atirador de elite';

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
  String get startFresh => 'Começar do zero';

  @override
  String get startLabel => 'Iniciar';

  @override
  String get startOnAppLaunch => 'Iniciar ao abrir o app';

  @override
  String get startServerToAccept =>
      'Inicie o servidor para aceitar conexões MCP.';

  @override
  String get stats => 'Estatísticas';

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
  String get streaksLabel => 'Sequências';

  @override
  String get strictIdentityCheck => 'Verificação rigorosa de identidade';

  @override
  String get success => 'Sucesso';

  @override
  String get successLabel => 'Sucesso';

  @override
  String get successLabelShort => 'Sucesso';

  @override
  String get successRate => 'Taxa de sucesso';

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
  String get tapBadgeToLevelUp => 'Toque em um badge para ver como avançar';

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
  String get threadLabel => 'Tópico';

  @override
  String get throughput => 'Produtividade';

  @override
  String get ticketLabel => 'TICKET';

  @override
  String tierLabel(String tier) {
    return 'Nível $tier';
  }

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
  String get topPerformerLabel => 'MELHOR DESEMPENHO';

  @override
  String get topPerformersDescription =>
      'Melhores desempenhos, produtividade e saúde do espaço de trabalho.';

  @override
  String get topic => 'Tópico';

  @override
  String get topicHint => 'ex: Tech Stack, Design System';

  @override
  String get totalRuns => 'Execuções totais';

  @override
  String get totalRunsLabel => 'Execuções totais';

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
  String workerLabel(int index) {
    return 'Worker $index';
  }

  @override
  String workersCount(int count) {
    return '$count workers';
  }

  @override
  String get workingMemory => 'Memória de trabalho';

  @override
  String get workspaceName => 'Nome do espaço de trabalho';

  @override
  String get workspaceNotFound => 'Espaço de trabalho não encontrado';

  @override
  String get workspaceNotesScratchpad =>
      'Notas e rascunho do espaço de trabalho';

  @override
  String get workspacePulse => 'PULSO DO ESPAÇO';

  @override
  String get workspaceScopedSkills =>
      'Arquivos de habilidades com escopo do espaço de trabalho anexados aos agentes.';

  @override
  String workspaceTitle(String name) {
    return 'Espaço de trabalho: $name';
  }

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
  String get yourAchievements => 'SUAS CONQUISTAS';

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
  String get pipelineStepStarted => 'Iniciado';

  @override
  String get pipelineStepFinished => 'Concluído';

  @override
  String get pipelineStepDurationLabel => 'Duração';

  @override
  String get pipelineStepBranch => 'Ramo';

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
  String get sidebarGroupWork => 'Trabalho';

  @override
  String get sidebarGroupTeam => 'Equipa';

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
  String get dashboardGreeting => 'Grüezi';

  @override
  String get dashboardSubtitle =>
      'Eis no que os seus agentes estão a trabalhar.';

  @override
  String get recentActivityTitle => 'Atividade recente';

  @override
  String get noRecentActivity => 'Ainda não há atividade recente';

  @override
  String get noRecentActivitySubtitle =>
      'As execuções de agentes, os pull requests e as mensagens aparecerão aqui.';

  @override
  String get noWorkspace => 'Nenhum espaço de trabalho';

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
  String get sidebarGroupKnowledge => 'Conhecimento';

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
  String get noAuthorMatches => 'Sem correspondências';

  @override
  String openedAgo(String age) {
    return 'Aberto $age';
  }

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
  String get activeFleet => 'Frota ativa';

  @override
  String agentsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agentes',
      one: '1 agente',
    );
    return '$_temp0';
  }

  @override
  String get blockedStatus => 'Bloqueado';

  @override
  String get failedStatus => 'Falhou';

  @override
  String get neverRunStatus => 'Nunca executado';

  @override
  String get noActiveRun => 'Nenhuma execução ativa';

  @override
  String get allPullRequests => 'Todos os pull requests';

  @override
  String get clearAll => 'Limpar tudo';

  @override
  String get needsYouNow => 'Precisa de você agora';

  @override
  String get pipelinesSectionTitle => 'Pipelines';

  @override
  String get allRuns => 'Todas as execuções';

  @override
  String get triage => 'Triagem';

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
  String reviewsAwaitingYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count revisões',
      one: '1 revisão',
    );
    return '$_temp0 aguardando você';
  }

  @override
  String reviewsOverTwoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count com mais de 2 dias',
      one: '1 com mais de 2 dias',
    );
    return '$_temp0';
  }

  @override
  String agentBlockedTitle(String name) {
    return '$name está bloqueado';
  }

  @override
  String get agentBlockedSubtitle => 'Aguardando sua confirmação';

  @override
  String get pipelineFailedTitle => 'Pipeline falhou';

  @override
  String prStaleTitle(String number) {
    return 'PR $number obsoleta';
  }

  @override
  String get prStaleSubtitle => 'Sem atividade recente';

  @override
  String get reviewRequestedBadge => 'Revisão solicitada';

  @override
  String get draftBadge => 'Rascunho';

  @override
  String get staleLabel => 'Obsoleta';

  @override
  String stepsProgress(int done, int total) {
    return '$done de $total etapas';
  }

  @override
  String get allCaughtUpSubtitle =>
      'Nenhuma revisão, bloqueio ou falha precisa de você agora.';

  @override
  String dashboardGreetingNamed(String name) {
    return 'Grüezi, $name';
  }

  @override
  String workspaceEyebrow(String name) {
    return 'Espaço $name';
  }

  @override
  String get pipelineTriggerNode => 'Gatilho';

  @override
  String get priorityReviewsTooltip =>
      'PRs abertos que solicitam sua revisão e aguardam há mais de 24 horas.';

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
  String get diff => 'Diff';

  @override
  String get preview => 'Pré-visualização';

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
  String get meetingsEmpty =>
      'Ainda não há reuniões. Inicie uma gravação para capturar uma.';

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
  String get meetingsOverlineKnowledge => 'Conhecimento';

  @override
  String get meetingsOverlineEngine => 'No dispositivo · Whisper base.en';

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
  String get meetingExportNothing => 'Ainda não há nada para exportar.';

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
  String transcriptToolCalls(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chamadas de ferramentas',
      one: '1 chamada de ferramenta',
    );
    return '$_temp0';
  }

  @override
  String get transcriptErrorLabel => 'Erro';

  @override
  String get transcriptInterrupted => 'Interrompido';

  @override
  String get transcriptSandboxBlocked => 'O sandbox bloqueou uma ação';

  @override
  String get transcriptOutputTruncated => 'Saída truncada';

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
}
