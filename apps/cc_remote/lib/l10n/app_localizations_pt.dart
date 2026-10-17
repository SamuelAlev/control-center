// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Voltar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get tryAgain => 'Tentar de novo';

  @override
  String get settings => 'Ajustes';

  @override
  String get refresh => 'Atualizar';

  @override
  String get approve => 'Aprovar';

  @override
  String get deny => 'Negar';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get agentQuestionHeader => 'Pergunta para você';

  @override
  String get agentQuestionAnsweredLabel => 'Respondido';

  @override
  String get agentQuestionSkip => 'Pular';

  @override
  String get agentQuestionSkippedLabel => 'Pulada';

  @override
  String get agentQuestionFreeformHint => 'Digite sua resposta…';

  @override
  String get agentApprovalRequired => 'Aprovação necessária';

  @override
  String get copyCommand => 'Copiar comando';

  @override
  String get approveAndRemember => 'Aprovar por 8 horas';

  @override
  String get decline => 'Recusar';

  @override
  String get confirm => 'Confirm';

  @override
  String get send => 'Enviar';

  @override
  String get close => 'Fechar';

  @override
  String get expand => 'Expandir';

  @override
  String get zoomIn => 'Aproximar';

  @override
  String get zoomOut => 'Afastar';

  @override
  String get resetZoom => 'Repor o zoom';

  @override
  String get scanQrPrompt =>
      'Escaneie o QR do Control Center para emparelhar este celular.';

  @override
  String get scanQrHelp =>
      'Abra a câmera e aponte para o QR exibido no Control Center. Este celular se conecta diretamente por um link privado.';

  @override
  String get connectingToMac => 'Conectando ao Control Center…';

  @override
  String get connectingDetail => 'Estabelecendo um link direto e seguro.';

  @override
  String get identityChangedTitle => 'Identidade do servidor mudou';

  @override
  String get identityChangedBody =>
      'Este servidor não corresponde mais à identidade salva no emparelhamento. Isso pode significar que o servidor foi reinstalado — ou que algo está interceptando a conexão. Por segurança, este dispositivo não vai conectar. Remova o emparelhamento e escaneie um QR novo no Control Center para emparelhar de novo.';

  @override
  String get removePairing => 'Remover emparelhamento';

  @override
  String get couldntConnect => 'Não foi possível conectar';

  @override
  String get pendingPairingTitle => 'Conectar a este servidor?';

  @override
  String get pendingPairingBody =>
      'Um link pediu ao Control Center para emparelhar com este servidor. Continue só se foi você quem iniciou.';

  @override
  String get connect => 'Conectar';

  @override
  String get failureNotPaired =>
      'Não emparelhado — escaneie o QR do Control Center';

  @override
  String get failureUnreachable =>
      'Não foi possível alcançar o servidor por nenhum caminho — verifique se ele está em execução ou tente a mesma rede';

  @override
  String get failureIdentityChanged =>
      'A identidade do servidor mudou — se ele foi reinstalado, emparelhe este dispositivo de novo';

  @override
  String get failureAuthRejected =>
      'O servidor rejeitou este dispositivo — emparelhe de novo pelo Control Center';

  @override
  String get failureUnknown =>
      'Não foi possível conectar — toque para tentar de novo';

  @override
  String get statusConnected => 'Conectado';

  @override
  String get statusConnecting => 'Conectando';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusIdentityMismatch => 'Identidade divergente';

  @override
  String get statusNotPaired => 'Não emparelhado';

  @override
  String get statusConfirmPairing => 'Confirmar emparelhamento';

  @override
  String get connectionFailed => 'Falha na conexão';

  @override
  String get identityMismatchBanner =>
      'Identidade do servidor mudou — conexão interrompida. Emparelhe este dispositivo de novo para continuar.';

  @override
  String get tabInbox => 'Caixa de entrada';

  @override
  String get tabTickets => 'Tickets';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'Agenda';

  @override
  String get tabNews => 'Notícias';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count aguardando';
  }

  @override
  String get updateAvailable =>
      'Uma nova versão do Control Center está disponível';

  @override
  String get appearance => 'Aparência';

  @override
  String get language => 'Idioma';

  @override
  String get device => 'Dispositivo';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get disconnectTapAgain =>
      'Toque de novo para desconectar este dispositivo do Control Center';

  @override
  String get disconnectDevice => 'Desconectar este dispositivo';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get chooseWorkspace => 'Escolher workspace';

  @override
  String get workspaces => 'Espaços de trabalho';

  @override
  String get workspacesLoadFailed => 'Não foi possível carregar os workspaces';

  @override
  String get noWorkspacesYet => 'Nenhum workspace ainda';

  @override
  String selectWorkspace(String name) {
    return 'Selecionar $name';
  }

  @override
  String get inboxLoadFailed => 'Não foi possível carregar a caixa de entrada';

  @override
  String get allCaughtUp => 'Tudo em dia';

  @override
  String get inboxNoForgeAccount =>
      'Nenhuma conta de forge está conectada no servidor, então os pull requests ainda não podem ser atribuídos a você.';

  @override
  String get inboxNothingWaiting =>
      'Nada bloqueado e nenhum pull request aguardando você.';

  @override
  String get blocked => 'Bloqueado';

  @override
  String get sectionNeedsYourReview => 'Precisa da sua revisão';

  @override
  String get sectionReturnedToYou => 'Devolvidos para você';

  @override
  String get sectionApprovedAndReady => 'Aprovados e prontos';

  @override
  String get sectionYourDrafts => 'Seus rascunhos';

  @override
  String get sectionWaitingForReviewers => 'Aguardando revisores';

  @override
  String get sectionMergingAndMerged => 'Mesclando e recém-mesclados';

  @override
  String get sectionWaitingForAuthor => 'Aguardando o autor';

  @override
  String waitingAgo(String ago) {
    return 'aguardando $ago';
  }

  @override
  String get openConversation => 'Abrir a conversa';

  @override
  String get calendarLoadFailed => 'Não foi possível carregar sua agenda';

  @override
  String get nothingScheduled => 'Nada agendado';

  @override
  String get calendarEmptyDescription =>
      'Os eventos dos calendários conectados aparecem aqui.';

  @override
  String get agenda => 'Agenda';

  @override
  String get syncCalendarsNow => 'Sincronizar calendários agora';

  @override
  String get event => 'Evento';

  @override
  String get eventNotFound => 'Evento não encontrado';

  @override
  String get eventNotFoundDescription =>
      'Pode estar fora da janela da agenda ou ter sido removido na origem.';

  @override
  String get joinMeeting => 'Entrar na reunião';

  @override
  String get join => 'Entrar';

  @override
  String attendeesCount(int count) {
    return 'Participantes ($count)';
  }

  @override
  String get details => 'Detalhes';

  @override
  String get allDay => 'Dia inteiro';

  @override
  String get happeningNow => 'Acontecendo agora';

  @override
  String inDuration(String duration) {
    return 'Em $duration';
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
  String get attendeeAccepted => 'aceitou';

  @override
  String get attendeeDeclined => 'recusou';

  @override
  String get attendeeMaybe => 'talvez';

  @override
  String get attendeeNoReply => 'sem resposta';

  @override
  String get organizer => 'organizador';

  @override
  String get calendarNoAccounts =>
      'Nenhum calendário está conectado neste workspace. Conecte um pelo app do desktop — o login guarda o token no servidor.';

  @override
  String get calendarReauthNeeded =>
      'Uma conta de calendário precisa ser reconectada — o que você vê abaixo pode estar desatualizado. Reconecte pelo app do desktop.';

  @override
  String get spacesLoadFailed => 'Não foi possível carregar os spaces';

  @override
  String get noSpaces => 'Nenhum space';

  @override
  String get spacesEmptyDescription =>
      'Os spaces deste workspace aparecem aqui.';

  @override
  String get newSpaceFolder => 'Nova pasta';

  @override
  String get folderName => 'Nome da pasta';

  @override
  String get renameSpaceFolder => 'Renomear pasta';

  @override
  String get deleteSpaceFolder => 'Excluir pasta';

  @override
  String get moveSpaceToFolder => 'Mover para uma pasta';

  @override
  String get removeSpaceFromFolder => 'Remover da pasta';

  @override
  String get spaceFolderActions => 'Ações da pasta';

  @override
  String get deleteFolderWithSpacesWarning =>
      'Excluir espaços permanentemente remove suas mensagens e diretórios de trabalho para todos. Essa ação não pode ser desfeita.';

  @override
  String get deleteSpacesInFolder =>
      'Excluir permanentemente os espaços desta pasta';

  @override
  String get deleteFolderAndSpaces => 'Excluir pasta e espaços';

  @override
  String get keepSpacesInFolder =>
      'Caso contrário, os espaços ficarão fora de qualquer pasta.';

  @override
  String get create => 'Criar';

  @override
  String get otherSpaces => 'Outros espaços';

  @override
  String get folderUpdateFailed => 'Não foi possível atualizar as pastas';

  @override
  String get thread => 'Conversa';

  @override
  String get agentWorking => 'O agente está trabalhando';

  @override
  String get messagesLoadFailed => 'Não foi possível carregar as mensagens';

  @override
  String get noMessagesYet => 'Nenhuma mensagem ainda';

  @override
  String get noMessagesDescription =>
      'Envie uma mensagem para começar a conversa.';

  @override
  String get agentResponding => 'Agente respondendo';

  @override
  String get agentFinished => 'Agente concluído';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names são grandes demais para enviar daqui.',
      one: '$names é grande demais para enviar daqui.',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names são grandes demais para enviar pelo relay daqui.',
      one: '$names é grande demais para enviar pelo relay daqui.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'Não foi possível enviar o anexo. Tente de novo.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count anexos não puderam ser enviados e ficaram de fora.',
      one: '1 anexo não pôde ser enviado e ficou de fora.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Colega';

  @override
  String get agent => 'Agente';

  @override
  String get attachFile => 'Anexar um arquivo';

  @override
  String get messageHint => 'Mensagem';

  @override
  String removeAttachment(String name) {
    return 'Remover $name';
  }

  @override
  String get articlesLoadFailed => 'Não foi possível carregar os artigos';

  @override
  String get noArticles => 'Nenhum artigo';

  @override
  String get articlesEmptyDescription =>
      'Novos artigos aparecem aqui conforme os feeds são atualizados.';

  @override
  String get unread => 'Não lidos';

  @override
  String get allFeeds => 'Todos os feeds';

  @override
  String get save => 'Salvar';

  @override
  String get unsave => 'Remover dos salvos';

  @override
  String get readFullArticle => 'Ler artigo completo';

  @override
  String get ticketsLoadFailed => 'Não foi possível carregar os tickets';

  @override
  String get noTickets => 'Nenhum ticket';

  @override
  String get ticketsEmptyDescription =>
      'Os tickets deste espaço de trabalho aparecem aqui.';

  @override
  String get all => 'Tudo';

  @override
  String get ticket => 'Ticket';

  @override
  String get ticketLoadFailed => 'Não foi possível carregar o ticket';

  @override
  String assignedTo(String name) {
    return 'Atribuído a $name';
  }

  @override
  String get openInBrowser => 'Abrir no navegador';

  @override
  String get status => 'Status';

  @override
  String get assign => 'Atribuir';

  @override
  String get reassign => 'Reatribuir';

  @override
  String get noAgents => 'Nenhum agente';

  @override
  String get noAgentsDescription =>
      'Atribua um agente deste espaço de trabalho.';

  @override
  String get statusOpen => 'Aberto';

  @override
  String get statusInProgress => 'Em andamento';

  @override
  String get statusBlocked => 'Bloqueado';

  @override
  String get statusInReview => 'Em revisão';

  @override
  String get statusDone => 'Concluído';

  @override
  String get statusBacklog => 'Backlog';

  @override
  String get lensNeedsMe => 'Precisa de mim';

  @override
  String get lensMine => 'Meus';

  @override
  String get prsLoadFailed => 'Não foi possível carregar as pull requests';

  @override
  String get noOpenPullRequests => 'Nenhum pull request aberto';

  @override
  String get nothingWaitingOnReview => 'Nada aguardando sua revisão';

  @override
  String get noOwnOpenPullRequests => 'Você não tem pull requests abertas';

  @override
  String get nothingBlocked => 'Nada bloqueado';

  @override
  String get prsEmptyDescription =>
      'As pull requests dos repositórios deste espaço de trabalho aparecem aqui.';

  @override
  String get refreshPullRequests => 'Atualizar pull requests';

  @override
  String get noForgeConnected =>
      'Nenhuma forge está conectada no servidor, então não é possível buscar pull requests. Conecte uma pelo app para computador.';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Não foi possível ler $count repos.',
      one: 'Não foi possível ler 1 repo.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'Não legíveis: $names';
  }

  @override
  String get installationSuspendedTitle => 'Instalação do GitHub App suspensa';

  @override
  String installationSuspendedBody(String names) {
    return 'Exibindo os últimos dados conhecidos de $names. Retome a instalação no GitHub ou conecte um token com acesso.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'Instalação do GitHub App suspensa. Exibindo os últimos dados conhecidos de $names. Retome a instalação no GitHub ou conecte um token com acesso.';
  }

  @override
  String get draft => 'Rascunho';

  @override
  String get merged => 'Mesclado';

  @override
  String get closed => 'Fechado';

  @override
  String get open => 'Aberto';

  @override
  String get approved => 'Aprovado';

  @override
  String get changesRequested => 'Alterações solicitadas';

  @override
  String get reviewRequired => 'Revisão necessária';

  @override
  String get checksPassing => 'Verificações aprovadas';

  @override
  String get checksFailing => 'Verificações com falha';

  @override
  String get checksRunning => 'Verificações em andamento';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'Não foi possível carregar esta pull request';

  @override
  String get openOnForge => 'Abrir na forge';

  @override
  String get requestChangesNeedsComment =>
      'Adicione um comentário explicando o que precisa ser alterado.';

  @override
  String get conversation => 'Conversa';

  @override
  String get files => 'Arquivos';

  @override
  String get checks => 'Verificações';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos',
      one: '1 arquivo',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => 'Conflitos';

  @override
  String get reviewers => 'REVISORES';

  @override
  String get noDescriptionNoComments =>
      'Ainda sem descrição e sem comentários.';

  @override
  String get noChangedFiles => 'Nenhum arquivo alterado.';

  @override
  String get noChecksReported => 'Nenhuma verificação para o commit HEAD.';

  @override
  String get reviewCommentHint => 'Deixe um comentário de revisão…';

  @override
  String get comment => 'Comentário';

  @override
  String get commentPosted => 'Comentário publicado';

  @override
  String get request => 'Solicitar';

  @override
  String get squashAndMerge => 'Squash and merge';

  @override
  String noActionsAvailable(String status) {
    return '$status — nenhuma ação disponível.';
  }

  @override
  String get reviewApproved => 'aprovou';

  @override
  String get reviewRequestedChanges => 'solicitou alterações';

  @override
  String get reviewCommented => 'revisou';

  @override
  String get reviewPending => 'pendente';

  @override
  String get unknownAuthor => 'desconhecido';

  @override
  String hideDiffFor(String file) {
    return 'Ocultar o diff de $file';
  }

  @override
  String showDiffFor(String file) {
    return 'Mostrar o diff de $file';
  }

  @override
  String get checkRunning => 'em execução';

  @override
  String get checkPassed => 'passou';

  @override
  String get checkFailed => 'falhou';

  @override
  String get checkCancelled => 'cancelado';

  @override
  String get checkSkipped => 'ignorado';

  @override
  String labelWithDuration(String label, String duration) {
    return '$label · $duration';
  }

  @override
  String checkSemanticLabel(String name, String state) {
    return '$name, $state';
  }

  @override
  String get noTextDiff =>
      'Não há diff de texto para este arquivo — é binário ou grande demais para a forge retornar.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mostrar as $count linhas restantes',
      one: 'Mostrar a linha restante',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count linhas inalteradas',
      one: '1 linha inalterada',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'Ir para o mais recente';

  @override
  String get streaming => 'Transmitindo';

  @override
  String get working => 'Trabalhando';

  @override
  String get input => 'Entrada';

  @override
  String get output => 'Saída';

  @override
  String get now => 'agora';

  @override
  String agoMinutes(int count) {
    return '${count}m';
  }

  @override
  String agoHours(int count) {
    return '${count}h';
  }

  @override
  String agoDays(int count) {
    return '${count}d';
  }

  @override
  String get today => 'Hoje';

  @override
  String get tomorrow => 'Amanhã';

  @override
  String get yesterday => 'ontem';

  @override
  String durationMinutes(int count) {
    return '${count}m';
  }

  @override
  String durationHours(int count) {
    return '${count}h';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get mobileConversations => 'Conversas';

  @override
  String get mobileNewConversation => 'Nova conversa';

  @override
  String get mobileConversationName => 'Nome da conversa';

  @override
  String get mobileRename => 'Renomear';

  @override
  String get mobileManageSpace => 'Gerenciar espaço';

  @override
  String get mobileArchived => 'Arquivado';

  @override
  String get mobileSearchMessages =>
      'Pesquisar todas as mensagens deste espaço';

  @override
  String get mobileSearch => 'Pesquisar';

  @override
  String get mobileNoResults => 'Nenhum resultado';

  @override
  String get mobileReopen => 'Reabrir';

  @override
  String get mobileArchive => 'Arquivar';

  @override
  String get mobileProgress => 'Progresso e contexto';

  @override
  String get mobileReadFailed =>
      'Não foi possível marcar esta conversa como lida';

  @override
  String get mobileSendFailed =>
      'Mensagem não enviada. Seu rascunho continua aqui.';

  @override
  String get sentAttachmentUnavailable => 'Anexo indisponível';

  @override
  String get sentAttachmentLoadFailed => 'Não foi possível carregar o anexo';

  @override
  String get mobileActionFailed => 'A ação falhou';

  @override
  String get mobileRemove => 'Remover';

  @override
  String get mobileLinkedMessage => 'Mensagem vinculada';

  @override
  String get mobileOlderMessages => 'Mensagens anteriores';

  @override
  String get mobileMessageActions => 'Ações da mensagem';

  @override
  String get mobileOpenThread => 'Abrir tópico';

  @override
  String get mobileCopyLink => 'Copiar link';

  @override
  String get mobileStopRun => 'Parar execução';

  @override
  String get mobileStopRunConfirm =>
      'Parar esta execução do agente? O trabalho já concluído será mantido.';

  @override
  String get mobileControlUnsupported =>
      'Esta execução terminou ou não oferece suporte a este controle.';

  @override
  String get mobilePauseRequested => 'Pausa solicitada após o turno atual';

  @override
  String get mobileResumed => 'Execução retomada';

  @override
  String get mobileStopRequested => 'Parada solicitada';

  @override
  String get mobileQueuedMessages => 'Mensagens na fila';

  @override
  String get mobilePauseRun => 'Pausar após o próximo turno';

  @override
  String get mobileResumeRun => 'Retomar';

  @override
  String get mobileEditQueued => 'Editar mensagem na fila';

  @override
  String get mobileSteerNow => 'Orientar agora';

  @override
  String get mobileMoveUp => 'Mover para cima';

  @override
  String get mobileMoveDown => 'Mover para baixo';

  @override
  String get mobileQueueChanged =>
      'A fila mudou ou esta execução não aceita orientações em tempo real. Atualize e tente novamente.';

  @override
  String get mobileActivity => 'Atividade';

  @override
  String get mobilePermissions => 'Permissões e auditoria';

  @override
  String get mobilePlans => 'Planos';

  @override
  String get mobileGoals => 'Metas supervisionadas';

  @override
  String get mobileCredentials => 'Conexões e credenciais';

  @override
  String get mobileWorkspaceUnavailable =>
      'Este espaço de trabalho está indisponível ou você não tem mais acesso a ele.';

  @override
  String get mobilePrReviewThreads => 'Tópicos de revisão';

  @override
  String get mobilePrThreadsLoadFailed =>
      'Não foi possível carregar os tópicos de revisão';

  @override
  String get mobilePrNoReviewThreads =>
      'Ainda não há tópicos de revisão no código';

  @override
  String get mobilePrCommentPermissionDenied =>
      'Você não tem permissão para comentar neste repositório.';

  @override
  String get mobilePrPermissionChecking =>
      'Verificando permissão para comentar…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'Não foi possível verificar sua permissão. Tente comentar novamente.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side, linha $line';
  }

  @override
  String get mobilePrOriginalSide => 'Original';

  @override
  String get mobilePrSelectCommentLine => 'Escolha uma linha para comentar';

  @override
  String get mobilePrUpdatedSide => 'Atualizado';

  @override
  String get mobilePrThreadResolved => 'Resolvido';

  @override
  String get mobilePrReplyHint => 'Escreva uma resposta…';

  @override
  String get mobilePrCommentRequired =>
      'Escreva um comentário antes de publicar.';

  @override
  String get mobilePrReply => 'Responder';

  @override
  String get mobilePrReopenThread => 'Reabrir fio';

  @override
  String get mobilePrResolveThread => 'Resolver fio';

  @override
  String get mobilePrResolvePermissionDenied =>
      'Somente o autor da pull request ou alguém com acesso de escrita pode resolver este tópico.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'Comentar em $side, linha $line';
  }

  @override
  String get mobilePrInlineCommentHint => 'Escreva um comentário no código…';

  @override
  String get mobilePrPostInlineComment => 'Publicar comentário';

  @override
  String get mobilePrCommentUnavailable =>
      'Comentários no código não estão disponíveis para esta pull request.';

  @override
  String get mobilePrPatchUnavailable =>
      'O serviço não forneceu um patch de texto para este arquivo.';

  @override
  String get mobilePrNoPatchForFile =>
      'O patch deste arquivo não está disponível.';

  @override
  String get mobileTicketNew => 'Novo ticket';

  @override
  String get mobileTicketCreate => 'Criar ticket';

  @override
  String get mobileTicketEdit => 'Editar ticket';

  @override
  String get mobileTicketTitle => 'Título';

  @override
  String get mobileTicketTitleRequired =>
      'Digite um título para salvar este ticket.';

  @override
  String get mobileTicketDescription => 'Descrição';

  @override
  String get mobileTicketMarkdownHint => 'Adicione detalhes em Markdown';

  @override
  String get mobileTicketPriority => 'Prioridade';

  @override
  String get mobileTicketPriorityNone => 'Sem prioridade';

  @override
  String get mobileTicketPriorityUrgent => 'Urgente';

  @override
  String get mobileTicketPriorityHigh => 'Alto';

  @override
  String get mobileTicketPriorityMedium => 'Médio';

  @override
  String get mobileTicketPriorityLow => 'Baixo';

  @override
  String get mobileTicketLabels => 'Etiquetas';

  @override
  String get mobileTicketLabelsHint => 'Uma etiqueta por linha';

  @override
  String get mobileTicketLabelsHelp =>
      'Digite cada etiqueta em uma linha separada.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'Registrado em $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'Não atribuído';

  @override
  String get mobileTicketAssignedFilter => 'Atribuídos';

  @override
  String get mobileTicketAgentsLoadFailed =>
      'Não foi possível carregar os agentes';

  @override
  String get mobileTicketSearch => 'Pesquisar tickets';

  @override
  String get mobileTicketSearchHint =>
      'Título, chave, descrição, etiqueta ou pessoa responsável';

  @override
  String get mobileTicketClearSearch => 'Limpar pesquisa de tickets';

  @override
  String get mobileTicketNoMatches => 'Nenhum ticket encontrado';

  @override
  String get mobileTicketAdjustFilters =>
      'Tente outra pesquisa ou altere os filtros.';

  @override
  String get mobileTicketClearFilters => 'Limpar filtros';

  @override
  String get mobileTicketNotFound => 'Ticket não encontrado';

  @override
  String get mobileTicketNotFoundDescription =>
      'Este ticket pode ter sido excluído ou movido para fora deste espaço de trabalho.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'O espaço de trabalho mudou. Volte ao espaço atual antes de salvar.';

  @override
  String get mobileTicketOpenLinkedSpace => 'Abrir espaço vinculado';

  @override
  String get mobileTicketReadOnly =>
      'É preciso ser membro do espaço de trabalho para alterar tickets.';

  @override
  String get permissionTitle => 'Permissões';

  @override
  String get permissionWorkspaceFailed =>
      'Não foi possível carregar o espaço de trabalho';

  @override
  String get permissionNoWorkspace =>
      'Selecione um espaço de trabalho para consultar as permissões.';

  @override
  String get permissionLoading => 'Carregando permissões…';

  @override
  String get permissionScopeDescription =>
      'Veja como cada ação é decidida neste âmbito. Agentes e espaços podem herdar regras do espaço de trabalho.';

  @override
  String get permissionScope => 'Âmbito da política';

  @override
  String get permissionWorkspaceScope => 'Espaço de trabalho';

  @override
  String get permissionAgentScope => 'Agente';

  @override
  String get permissionSpaceScope => 'Espaço';

  @override
  String get permissionAgentContext => 'Agente atuando neste espaço';

  @override
  String get permissionNoAgentContext => 'Nenhum agente selecionado';

  @override
  String get permissionTargetsFailed =>
      'Não foi possível carregar os alvos deste âmbito';

  @override
  String get permissionNoTargets => 'Não há alvos disponíveis neste âmbito.';

  @override
  String get permissionRoleFailed =>
      'Não foi possível confirmar sua função no espaço de trabalho';

  @override
  String get permissionMemberRequired =>
      'É preciso ser membro do espaço de trabalho para ver as regras da política.';

  @override
  String get permissionRulesFailed =>
      'Não foi possível carregar as regras da política';

  @override
  String get permissionAuditAdminOnly =>
      'O histórico de autorizações está disponível apenas para administradores do espaço de trabalho.';

  @override
  String get permissionAllow => 'Permitir';

  @override
  String get permissionAsk => 'Perguntar primeiro';

  @override
  String get permissionDeny => 'Negar';

  @override
  String get permissionFileDelete => 'Excluir arquivos';

  @override
  String get permissionFileWriteOutsideWorktree =>
      'Gravar fora da árvore de trabalho';

  @override
  String get permissionGitCommit => 'Registrar alterações em commits';

  @override
  String get permissionGitPush => 'Enviar commits';

  @override
  String get permissionPrCreate => 'Criar pull requests';

  @override
  String get permissionPrPublish => 'Publicar pull requests';

  @override
  String get permissionVendorSyncWrite =>
      'Gravar sincronização de fornecedores';

  @override
  String get permissionNetworkEgress => 'Acessar a rede';

  @override
  String get permissionSecretAccess => 'Acessar segredos';

  @override
  String get permissionPackageInstall => 'Instalar pacotes';

  @override
  String get permissionProcessSpawn => 'Iniciar processos';

  @override
  String get permissionWorkspaceMutation => 'Alterar espaço de trabalho';

  @override
  String get permissionEnclosureControl => 'Controlar ambiente isolado';

  @override
  String get permissionChangeFailed => 'Não foi possível alterar a regra';

  @override
  String get permissionEffectiveDescription =>
      'Válida neste âmbito sem parâmetros de ação. As permissões condicionais abaixo valem apenas para solicitações correspondentes; o servidor toma a decisão final.';

  @override
  String get permissionSpaceAgentNote =>
      'Nenhum agente selecionado. Selecione um acima para ver as regras específicas do agente.';

  @override
  String get permissionScopedGrants => 'Regras neste âmbito';

  @override
  String get permissionModePreset => 'Predefinição do modo';

  @override
  String get permissionBuiltInDefault => 'Predefinição';

  @override
  String get permissionRemembered => 'Aprovação lembrada';

  @override
  String get permissionSource => 'Código';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · definida aqui';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · herdada';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'Expira em $date';
  }

  @override
  String get permissionSetHere => 'Definir regra aqui';

  @override
  String get permissionRevokeBeforeEdit =>
      'Revogue a regra deste âmbito ou a regra lembrada antes de definir uma regra geral para esta ação.';

  @override
  String get permissionConfirmRevoke => 'Confirmar revogação';

  @override
  String get permissionRevokeRule => 'Revogar regra';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'Prefixo do comando: $prefix';
  }

  @override
  String get permissionNoExpiry => 'Sem prazo de validade';

  @override
  String get permissionExpired => 'Expirado';

  @override
  String get permissionExplicitRule => 'Regra explícita';

  @override
  String get permissionEnforcementAdvisory =>
      'Modo consultivo: regras que pedem aprovação são registradas sem solicitar confirmação';

  @override
  String get permissionEnforcementSoft =>
      'Aplicação flexível: a substituição exige autorização';

  @override
  String get permissionEnforcementHard =>
      'Aplicação rígida: não pode ser substituída';

  @override
  String permissionPaths(String paths) {
    return 'Caminhos: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Referências Git: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'Hosts: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'Comandos: $commands';
  }

  @override
  String permissionMaxCount(String count) {
    return 'Quantidade máxima: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'Máximo em centavos: $cents';
  }

  @override
  String get permissionAuditHeading => 'Histórico de autorizações';

  @override
  String get permissionAuditDescription =>
      'Decisões recentes registradas pelo servidor. Apenas administradores podem consultar o registro ou verificar sua cadeia de hashes.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'em nome de $user';
  }

  @override
  String get permissionPrompted => 'Aprovação humana solicitada';

  @override
  String get permissionVerifyChain => 'Verificar cadeia de auditoria';

  @override
  String get permissionVerifyFailed =>
      'Não foi possível verificar a cadeia de auditoria';

  @override
  String permissionChainIntact(String count) {
    return 'Cadeia íntegra · $count entradas verificadas';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'Cadeia interrompida na entrada $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty =>
      'Ainda não há decisões de autorização registradas.';

  @override
  String get permissionAuditFailed =>
      'Não foi possível carregar o histórico de autorizações';

  @override
  String get mobilePlansLoadFailed => 'Não foi possível carregar os planos';

  @override
  String get mobilePlansEmpty => 'Ainda não há planos';

  @override
  String get mobilePlansEmptyDescription =>
      'Os planos enviados pelos agentes aparecerão aqui para revisão.';

  @override
  String get mobilePlanTitle => 'Plano';

  @override
  String get mobilePlanMissing =>
      'Este plano não está mais disponível neste espaço de trabalho.';

  @override
  String mobilePlanStepCount(int count) {
    return '$count etapas';
  }

  @override
  String get mobilePlanDraft => 'Rascunho';

  @override
  String get mobilePlanProposed => 'Aguardando revisão';

  @override
  String get mobilePlanApproved => 'Aprovado';

  @override
  String get mobilePlanRejected => 'Rejeitado';

  @override
  String get mobilePlanSuperseded => 'Substituído';

  @override
  String get mobilePlanExecuting => 'Em execução';

  @override
  String get mobilePlanSynthesizing => 'Sintetizando';

  @override
  String get mobilePlanCompleted => 'Completed';

  @override
  String get mobilePlanFailed => 'Falhou';

  @override
  String get mobilePlanCancelled => 'Cancelled';

  @override
  String mobilePlanRevision(String revision) {
    return 'Revisão $revision';
  }

  @override
  String get mobilePlanSteps => 'Etapas';

  @override
  String get mobilePlanNoSteps => 'Nenhuma etapa foi enviada para este plano.';

  @override
  String get mobilePlanAssumptions => 'Esclarecimentos';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'Depende de $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'Estimativa de até $cost';
  }

  @override
  String get mobilePlanSelect => 'Selecionar';

  @override
  String get mobilePlanSelected => 'Selecionadas';

  @override
  String get mobilePlanEstimate => 'Estimar custo';

  @override
  String get mobilePlanEstimateRequired =>
      'Estime o custo do plano antes de aprovar a execução.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'Custo estimado: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'indisponível';

  @override
  String get mobilePlanNoHardCap => 'sem limite fixo';

  @override
  String get mobilePlanExceedsBudget =>
      'A estimativa excede o orçamento definido. Revise antes de aprovar.';

  @override
  String get mobilePlanPartialEstimate =>
      'Esta estimativa cobre o plano inteiro; as etapas selecionadas podem custar menos.';

  @override
  String get mobilePlanConfirmAll => 'Iniciar o plano inteiro?';

  @override
  String get mobilePlanConfirmSelected => 'Iniciar as etapas selecionadas?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'A aprovação inicia a execução e pode gerar cobranças. Custo máximo estimado: $cost. Limite do orçamento: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'Aprovar tudo e executar';

  @override
  String get mobilePlanApproveSelected => 'Aprovar seleção e executar';

  @override
  String get mobilePlanWiden => 'Aprovar mais etapas';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'Liberar mais $count etapas para execução? Elas podem gerar cobranças. Limite atual do custo de execução: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'O plano mudou durante a revisão. Abra a versão mais recente e estime o custo novamente.';

  @override
  String get mobilePlanReject => 'Rejeitar plano';

  @override
  String get mobilePlanRejectConfirm =>
      'Rejeitar este plano? Ele não será executado.';

  @override
  String get mobilePlanStop => 'Parar execução';

  @override
  String get mobilePlanStopConfirm =>
      'Parar a execução deste plano? O trabalho já concluído não será desfeito.';

  @override
  String mobilePlanRunId(String runId) {
    return 'Execução: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'Aprovação aceita. Aguardando o registro da execução…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return '$completed de $total etapas de execução concluídas';
  }

  @override
  String get mobilePlanOpenConversation => 'Abrir conversa';

  @override
  String get mobileGoalsTitle => 'Metas supervisionadas';

  @override
  String get mobileGoalsLoadFailed =>
      'Não foi possível carregar as metas supervisionadas';

  @override
  String get mobileGoalsEmpty => 'Ainda não há metas supervisionadas';

  @override
  String get mobileGoalsEmptyDescription =>
      'Inicie uma em um espaço ou envie /goal em uma conversa.';

  @override
  String get mobileGoalMissing =>
      'Esta meta não está mais disponível neste espaço de trabalho.';

  @override
  String get mobileGoalActive => 'Ativo';

  @override
  String get mobileGoalPaused => 'Em pausa';

  @override
  String get mobileGoalCompleted => 'Completed';

  @override
  String get mobileGoalFailed => 'Falhou';

  @override
  String get mobileGoalCancelled => 'Cancelled';

  @override
  String get mobileGoalBudgetExhausted => 'Orçamento esgotado';

  @override
  String get mobileGoalGoal => 'Objetivo';

  @override
  String get mobileGoalLoop => 'Ciclo';

  @override
  String mobileGoalKind(String kind) {
    return 'Tipo: $kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return '$count execuções';
  }

  @override
  String get mobileGoalNoRunLimit => 'sem limite';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return 'Execuções: $runs / $maxRuns · Gasto: $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return 'Prazo: $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return 'Execuções consecutivas com falha: $count';
  }

  @override
  String get mobileGoalSummary => 'Resumo da conclusão';

  @override
  String get mobileGoalFailedDescription =>
      'O supervisor parou após falhas repetidas nas execuções. Veja os detalhes na conversa.';

  @override
  String get mobileGoalBudgetWall =>
      'O prazo ou o limite de execuções foi atingido. Aumentar o limite de custo não permite retomar esta meta.';

  @override
  String get mobileGoalPause => 'Pausar meta';

  @override
  String get mobileGoalResume => 'Retomar meta';

  @override
  String get mobileGoalStop => 'Cancelar meta';

  @override
  String get mobileGoalStopConfirm =>
      'Cancelar permanentemente esta meta supervisionada? Não será possível retomá-la.';

  @override
  String get mobileGoalRaiseBudget => 'Aumentar orçamento e retomar';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'Aumentar orçamento para $amount e retomar';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'Aumentar o limite de custo desta meta de $oldCap para $newCap e retomar os gastos?';
  }

  @override
  String get mobileGoalOpenConversation => 'Abrir conversa da meta';

  @override
  String get mobileGoalCreate => 'Iniciar meta supervisionada';

  @override
  String get mobileGoalChooseSpace => 'Executar no espaço';

  @override
  String get mobileGoalNoSpaces => 'Crie um espaço antes de iniciar uma meta.';

  @override
  String get mobileGoalChooseAgent => 'Executar com agente';

  @override
  String get mobileGoalNoAgents =>
      'Adicione um agente ativo antes de iniciar uma meta.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return '$name selecionado';
  }

  @override
  String get mobileGoalObjectiveHint =>
      'Qual resultado o agente deve alcançar?';

  @override
  String get mobileGoalBudgetUsd => 'Limite de custo (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'Escolha um espaço e um agente, descreva o objetivo e defina um limite de custo positivo em USD.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'Iniciar uma meta supervisionada com custo máximo de $cap? O agente pode começar imediatamente.';
  }

  @override
  String get mobileGoalUnavailable =>
      'A conexão com o servidor ainda não está pronta. Tente novamente após reconectar.';

  @override
  String get mobileGoalConversationMissing =>
      'A conversa selecionada não está mais disponível neste espaço de trabalho.';

  @override
  String get mobileGoalCreateSent =>
      'Meta iniciada. O estado do supervisor aparecerá nesta lista.';

  @override
  String get mobileGoalStartRefused =>
      'A meta não começou a ser executada. Veja o motivo dado pelo supervisor na conversa.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return '$name selecionado';
  }

  @override
  String get requestUnavailable =>
      'Esta solicitação não está mais disponível no espaço de trabalho ativo.';

  @override
  String get requestAlreadyResolved => 'Esta solicitação já foi resolvida.';

  @override
  String get inboxCredentialsBlocked => 'Credenciais bloqueando execuções';

  @override
  String get inboxSyncFailures => 'Falhas de sincronização com fornecedores';

  @override
  String get inboxConfigureCredentials => 'Configurar credenciais';

  @override
  String get openTicket => 'Abrir ticket';

  @override
  String get activityTitle => 'Atividade';

  @override
  String get activityClearAll => 'Limpar atividade';

  @override
  String get activityClearConfirm =>
      'Isso oculta toda a atividade registrada até agora para você em todos os dispositivos. Novas atividades continuarão aparecendo.';

  @override
  String get activityMarkAllRead => 'Marcar tudo como lido';

  @override
  String get activityMarkAllConfirm =>
      'Marcar todos os itens de atividade deste espaço de trabalho como lidos em todos os seus dispositivos?';

  @override
  String get activityMarkRead => 'Marcar como lido';

  @override
  String get activityMarkUnread => 'Marcar como não lido';

  @override
  String get activityDismiss => 'Dispensar';

  @override
  String get activityResolved => 'Resolvido';

  @override
  String get activityOpen => 'Aberto';

  @override
  String get activityEmpty => 'Nenhuma atividade ainda';

  @override
  String get activityLoadFailed => 'Não foi possível carregar a atividade';

  @override
  String get activityAgentWaiting => 'Agente precisa de informações';

  @override
  String get activityAgentBlocked => 'Ação do agente bloqueada';

  @override
  String get activityMessage => 'Nova mensagem';

  @override
  String get activityPullRequest => 'Atualização de pull request';

  @override
  String get activityTicket => 'Atualização de ticket';

  @override
  String get activityMeeting => 'Atualização de reunião';

  @override
  String get activityCalendar => 'Conexão com calendário';

  @override
  String get activityRig => 'Atualização do ambiente isolado';

  @override
  String get activityEvent => 'Atualizar';

  @override
  String get activityPrReady => 'Pull request pronta para mesclagem';

  @override
  String get activityPrBlocked => 'Mesclagem da pull request bloqueada';

  @override
  String get activityPrApproved => 'Pull request aprovada';

  @override
  String get activityPrChanges => 'Alterações solicitadas';

  @override
  String get activityPrChecksFailed => 'Verificações da pull request falharam';

  @override
  String get activityPrChecksRecovered =>
      'Verificações da pull request voltaram a passar';

  @override
  String get activityPrComment => 'Comentário na pull request';

  @override
  String get activityPrPublished => 'Pull request publicada';

  @override
  String get activityPrMerged => 'Pull request merged';

  @override
  String get activityPrMentioned => 'Você foi mencionado em uma pull request';

  @override
  String get activityPrReviewRequested => 'Revisão solicitada';

  @override
  String get activityPrReviewStale => 'A revisão precisa ser atualizada';

  @override
  String get activityTicketAssigned => 'Ticket atribuído';

  @override
  String get activityTicketChanged => 'Status do ticket alterado';

  @override
  String get activityMeetingSoon => 'Reunião prestes a começar';

  @override
  String get activityCalendarExpired => 'Conexão com calendário expirada';

  @override
  String get activityRigControl => 'Controle do ambiente isolado alterado';

  @override
  String get activityRigClosed => 'Ambiente isolado encerrado';

  @override
  String get mobileSpacesSearch => 'Pesquisar espaços';

  @override
  String get mobileSpacesArchived => 'Arquivado';

  @override
  String get mobileSpacesActive => 'Ativo';

  @override
  String get mobileSpacesNew => 'Novo espaço';

  @override
  String get mobileSpacesManage => 'Gerenciar espaço';

  @override
  String get mobileSpacesName => 'Nome do espaço';

  @override
  String get mobileSpacesAgents => 'Agentes';

  @override
  String get mobileSpacesMembers => 'Pessoas';

  @override
  String get mobileSpacesRepos => 'Repositórios';

  @override
  String get mobileSpacesAllRepos => 'Todos os repositórios vinculados';

  @override
  String get mobileSpacesNoRepos => 'Nenhum repositório';

  @override
  String get mobileSpacesBaseBranch => 'Branch base (opcional)';

  @override
  String get mobileSpacesDefaultBranch => 'Branch padrão';

  @override
  String get mobileSpacesMode => 'Modo';

  @override
  String get mobileSpacesModeChat => 'Conversa';

  @override
  String get mobileSpacesModeReview => 'Revisão (somente leitura)';

  @override
  String get mobileSpacesModePlan => 'Plano (somente leitura)';

  @override
  String get mobileSpacesModeOrchestrate => 'Orquestrar';

  @override
  String get mobileSpacesAutonomy => 'Substituição do nível de autonomia';

  @override
  String get mobileSpacesAutonomyInherited => 'Herdado';

  @override
  String get mobileSpacesAutonomyPropose => 'Somente propor';

  @override
  String get mobileSpacesAutonomyApproval => 'Agir com aprovação';

  @override
  String get mobileSpacesAutonomyFreely => 'Agir livremente';

  @override
  String get mobileSpacesAutonomyNotice =>
      'A substituição não ignora pedidos de aprovação nem negativas da política de ações. Somente administradores do espaço de trabalho podem alterá-la.';

  @override
  String get mobileSpacesArchive => 'Arquivar espaço';

  @override
  String get mobileSpacesReopen => 'Reabrir espaço';

  @override
  String get mobileSpacesSave => 'Guardar alterações';

  @override
  String get mobileSpacesCreate => 'Criar espaço';

  @override
  String get mobileSpacesOperationFailed =>
      'Não foi possível atualizar o espaço';

  @override
  String get mobileSpacesMissing =>
      'Espaço não encontrado neste espaço de trabalho';

  @override
  String get mobileSpacesEmptyName => 'Digite um nome para o espaço';

  @override
  String get mobileSpacesNoMatches => 'Nenhum espaço encontrado';

  @override
  String get mobileSpacesUnread => 'Resposta não lida do agente';

  @override
  String get mobileSpacesNeedsInput => 'Aguardando sua resposta';

  @override
  String get mobileSpacesRunning => 'Agente em execução';

  @override
  String get mobileSpacesNoAgents => 'Nenhum agente neste espaço de trabalho';

  @override
  String get mobileSpacesNoMembers =>
      'Nenhum outro membro do espaço de trabalho';

  @override
  String get mobileSpacesRepoError =>
      'Não foi possível carregar os repositórios';

  @override
  String get mobileSpacesRetry => 'Tentar novamente';

  @override
  String get mobileSpacesBranchUnavailable =>
      'Ao criar um espaço, escolha ou digite uma branch base; não é possível alterar a branch base de um espaço existente.';

  @override
  String get mobileSpacesArchivedEmpty => 'Nenhum espaço arquivado';

  @override
  String get mobileSpacesAllRepoWarning =>
      'Novos repositórios vinculados ao espaço de trabalho também serão incluídos neste espaço.';

  @override
  String get mobileSpacesCreatedRetry =>
      'Espaço criado. Tente adicionar pessoas novamente ou abra a página de gerenciamento.';

  @override
  String get progressTitle => 'Progresso';

  @override
  String get progressConversation => 'Conversa';

  @override
  String get progressLoadFailed => 'Não foi possível carregar o progresso';

  @override
  String get progressUnavailable => 'Conversa indisponível';

  @override
  String get progressUnavailableDescription =>
      'Esta conversa não pertence ao espaço de trabalho e ao espaço ativos. Volte ao espaço dela para continuar.';

  @override
  String get progressSaveFailed => 'Não foi possível atualizar o progresso';

  @override
  String get progressGoal => 'Objetivo';

  @override
  String get progressNoGoal => 'Nenhum objetivo de trabalho definido';

  @override
  String get progressSetGoal => 'Definir objetivo';

  @override
  String get progressEditGoal => 'Editar objetivo';

  @override
  String get progressClearGoal => 'Limpar objetivo';

  @override
  String get progressGoalRequired => 'Digite um objetivo antes de salvar.';

  @override
  String get progressTodos => 'Tarefas';

  @override
  String get transcriptToolTodos => 'Tarefas';

  @override
  String get transcriptToolSearchMemory => 'Buscar na memória';

  @override
  String get transcriptToolRenderMedia => 'Exibir mídia';

  @override
  String get progressNoTodos => 'Ainda não há tarefas';

  @override
  String get progressNewTodo => 'Nova tarefa';

  @override
  String get progressAddTodo => 'Adicionar tarefa';

  @override
  String get progressEditTodo => 'Editar tarefa';

  @override
  String get progressTodoRequired => 'Digite uma tarefa antes de salvar.';

  @override
  String get progressTodoNoLongerExists =>
      'Esta tarefa foi removida. Recarregue a lista e tente novamente.';

  @override
  String get progressWorkspaceChanged =>
      'O espaço de trabalho ativo mudou. Volte a esta conversa e tente novamente.';

  @override
  String progressRemoveTodo(String name) {
    return 'Remover tarefa $name';
  }

  @override
  String get progressPending => 'Pending';

  @override
  String get progressInProgress => 'Em andamento';

  @override
  String get progressCompleted => 'Completed';

  @override
  String get progressMoveUp => 'Mover tarefa para cima';

  @override
  String get progressMoveDown => 'Mover tarefa para baixo';

  @override
  String get progressRunTree => 'Execuções dos agentes';

  @override
  String get progressNoRuns => 'Ainda não há execuções nesta conversa';

  @override
  String get progressRunning => 'Em execução';

  @override
  String get progressFailed => 'Falhou';

  @override
  String get progressUnknown => 'Desconhecido';

  @override
  String get progressHealthy => 'Ativo';

  @override
  String get progressBlocked => 'Bloqueado';

  @override
  String get progressLooping => 'Em ciclo';

  @override
  String get progressStalled => 'Paralisado';

  @override
  String get progressDead => 'Parou inesperadamente';

  @override
  String get progressQuiet => 'Ainda sem saída';

  @override
  String get progressCostReported => 'Cobrança informada pelo provedor';

  @override
  String get progressCostNotional =>
      'Preço de tabela estimado da assinatura; não é uma cobrança';

  @override
  String get progressCostMixed => 'Fontes de custo combinadas';

  @override
  String get progressCostEstimated => 'Custo estimado';

  @override
  String progressDurationSeconds(String seconds) {
    return '${seconds}s';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'Modelo: $model · Tempo: $duration · Custo: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'Iniciado $time';
  }

  @override
  String progressLiveness(String state) {
    return 'Estado: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'Entrada: $input · Saída: $output tokens';
  }

  @override
  String get progressOutputPreviewLimited =>
      'Apenas os primeiros 6.000 caracteres da saída estruturada são exibidos.';

  @override
  String progressRetryOf(String runId) {
    return 'Nova tentativa da execução $runId';
  }

  @override
  String get progressContext => 'Contexto e limites';

  @override
  String get progressNoAgent => 'Nenhum agente para consultar';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window tokens';
  }

  @override
  String get progressMeasured =>
      'Contexto informado pelo provedor na última chamada';

  @override
  String get progressEstimated =>
      'Estimado a partir da conversa armazenada e do contexto persistente';

  @override
  String get progressContextUnknown => 'Uso do contexto ainda não informado';

  @override
  String progressContextPercent(String percent) {
    return '$percent% da janela de contexto';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'Limite mensal configurado para o agente: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'Conversa ativa armazenada: cerca de $tokens tokens';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'Contexto persistente de $agent · $model';
  }

  @override
  String get progressContextSystem => 'Prompt do sistema';

  @override
  String get progressContextRules => 'Regras';

  @override
  String get progressContextSkills => 'Habilidades';

  @override
  String get progressContextTools => 'Definições de ferramentas';

  @override
  String get progressContextMcp => 'Ferramentas MCP';

  @override
  String get progressContextDeferred => 'Ferramentas adiadas';

  @override
  String get progressContextSubagents => 'Subagentes';

  @override
  String get progressContextRunner => 'Executor externo';

  @override
  String get progressContextMemory => 'Memória';

  @override
  String get progressContextHistory => 'Histórico da conversa';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens tokens';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens tokens';
  }

  @override
  String get progressOutputs => 'Saídas recentes';

  @override
  String get progressNoOutputs => 'Nenhuma saída recente do agente';

  @override
  String get progressStructuredOutputsAbove =>
      'As saídas estruturadas das execuções aparecem acima.';

  @override
  String get progressRecentOutputsOnly =>
      'Exibindo apenas mensagens recentes. Abra a conversa para ver o trabalho anterior.';

  @override
  String get progressPlan => 'Plano';

  @override
  String get progressArtifact => 'Artefato';

  @override
  String get progressResult => 'Resultado';

  @override
  String get progressHideArtifact => 'Ocultar artefato';

  @override
  String get progressReadArtifact => 'Ler artefato';

  @override
  String get progressArtifactUnavailable => 'Artefato não está mais disponível';

  @override
  String get progressArtifactPreviewLimited =>
      'Exibindo uma prévia limitada deste artefato.';

  @override
  String get progressDiagramSource => 'Código-fonte do diagrama';

  @override
  String progressOpenAttachment(String name) {
    return 'Abrir $name';
  }

  @override
  String get progressOpenPlan => 'Abrir plano';

  @override
  String progressOpenDiff(String label) {
    return 'Revisar arquivos alterados: $label';
  }

  @override
  String get progressViewMessage => 'Ver mensagem';

  @override
  String get pushTitle => 'Notificações em segundo plano';

  @override
  String get pushIntro =>
      'Receba um alerta privado quando algo precisar da sua atenção, mesmo com o aplicativo fechado. Os detalhes ficam na sua conexão criptografada.';

  @override
  String get pushLoading => 'Verificando configurações de notificação…';

  @override
  String get pushError =>
      'Não foi possível atualizar as notificações. Verifique sua conexão e tente novamente.';

  @override
  String get pushEnable => 'Ativar notificações';

  @override
  String get pushDisable => 'Desativar notificações';

  @override
  String get pushQuiet => 'Pausar alertas neste dispositivo';

  @override
  String get pushCategories => 'Notificar sobre';

  @override
  String get pushCategoryAgents => 'Agentes';

  @override
  String get pushCategoryMessages => 'Mensagens';

  @override
  String get pushCategoryPullRequests => 'Pull requests';

  @override
  String get pushCategoryTickets => 'Tickets';

  @override
  String get pushCategoryCalendar => 'Calendário';

  @override
  String get pushCategoryMachines => 'Máquinas';

  @override
  String get pushSecureOrigin => 'As notificações exigem HTTPS.';

  @override
  String get pushInstallIos =>
      'No iPhone ou iPad, adicione este aplicativo à Tela de Início e abra-o por lá para ativar as notificações.';

  @override
  String get pushUnsupported =>
      'Este navegador não oferece suporte a notificações em segundo plano.';

  @override
  String get pushDenied =>
      'O navegador informa que as notificações estão bloqueadas. Confira a permissão deste site e as configurações de notificações do navegador ou dispositivo e atualize a página.';

  @override
  String get pushResubscribe => 'Reconectar notificações';

  @override
  String get pushStatusEnabled =>
      'As notificações estão ativadas neste dispositivo.';

  @override
  String get pushStatusDisabled =>
      'As notificações estão desativadas neste dispositivo.';

  @override
  String get credentialsTitle => 'Conexões e credenciais';

  @override
  String get credentialsIntro =>
      'Conecte as contas usadas pelas suas execuções e integrações. Os segredos ficam no seu servidor, não neste telefone.';

  @override
  String get credentialsModelProviders => 'Provedores de modelos';

  @override
  String get credentialsOwnerOnly =>
      'Somente o proprietário do servidor pode adicionar, acessar ou remover credenciais dos provedores de modelos. Essas chaves são compartilhadas entre espaços de trabalho.';

  @override
  String get credentialsContactOwner =>
      'Peça ao proprietário do servidor para conectar o provedor necessário à sua execução bloqueada.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'O Claude Code faz login pela CLI no host. Peça ao proprietário do servidor para entrar na conta ou renovar o acesso pelo terminal do host; isso não pode ser feito neste telefone.';

  @override
  String get credentialsYourForgeAccounts =>
      'Suas contas de plataformas de código';

  @override
  String get credentialsYourTicketingAccount => 'Sua conta de tickets';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'Tickets locais não exigem login. Conecte o Linear aqui se seu espaço de trabalho o utilizar.';

  @override
  String get credentialsMembershipRequired =>
      'Entre em um espaço de trabalho para gerenciar suas credenciais de plataformas de código ou tickets. Peça acesso a um administrador.';

  @override
  String get credentialsSwitchWorkspace =>
      'Este link aponta para outro espaço de trabalho. Mude para ele antes de alterar as credenciais.';

  @override
  String get credentialsReturnToInbox =>
      'Volte à Caixa de entrada para repetir uma execução bloqueada após conectar a credencial. O host também verifica automaticamente as execuções em espera.';

  @override
  String get credentialsLoadFailed =>
      'Não foi possível carregar as conexões. Verifique a conexão com o servidor e tente novamente.';

  @override
  String get credentialsOperationFailed =>
      'Não foi possível alterar esta conexão. Verifique a conexão com o servidor, seu acesso e a credencial, e tente novamente.';

  @override
  String get credentialsConnected => 'Conectado';

  @override
  String get credentialsNotConnected => 'Não conectado';

  @override
  String credentialsSignedInAs(String username) {
    return 'Conectado como $username';
  }

  @override
  String get credentialsAccount => 'Conta conectada';

  @override
  String get credentialsStoredKey => 'Chave armazenada';

  @override
  String get credentialsActive => 'Ativo';

  @override
  String get credentialsRemove => 'Remover';

  @override
  String get credentialsRemoveConfirm =>
      'Remover sua credencial salva? Talvez você precise entrar novamente.';

  @override
  String get credentialsApiKey => 'Chave de API';

  @override
  String get credentialsApiKeyHint => 'Cole uma chave de API do provedor';

  @override
  String get credentialsBrowserLogin => 'Entrar pelo navegador';

  @override
  String get credentialsSignInAgain => 'Inicia sessão novamente';

  @override
  String get credentialsWaitingForLogin =>
      'Aguardando autorização no navegador…';

  @override
  String get credentialsLoginTimedOut =>
      'O login expirou. Inicie uma nova tentativa.';

  @override
  String get credentialsCopyCode => 'Copiar código';

  @override
  String get credentialsDeviceCodeHint =>
      'Confirme este código na página do provedor. Mantenha esta tela aberta enquanto o servidor conclui o login.';

  @override
  String get credentialsPasteRedirect =>
      'Código de autorização ou URL de redirecionamento';

  @override
  String get credentialsPasteRedirectHint =>
      'Cole o código ou a URL completa de redirecionamento fornecida pelo provedor';

  @override
  String get credentialsCompleteLogin => 'Concluir login';

  @override
  String get credentialsRedirectUnavailable =>
      'Não é possível acessar com segurança o retorno do navegador deste servidor pelo telefone. Peça ao proprietário do servidor para configurar um endereço público de retorno HTTPS ou adicione um token.';

  @override
  String get credentialsUpdateToken => 'Atualizar token';

  @override
  String get credentialsAddToken => 'Adicionar token';

  @override
  String get credentialsPersonalToken => 'Token de acesso pessoal';

  @override
  String get credentialsPersonalTokenHint => 'Cole um token de acesso pessoal';

  @override
  String get credentialsHostManaged =>
      'Esta conexão vem do aplicativo ou ambiente do servidor. Somente o proprietário do servidor pode alterá-la lá; você ainda pode adicionar seu próprio token.';

  @override
  String get credentialsStopWatching => 'Parar de acompanhar';
}

/// The translations for Portuguese, as used in Portugal (`pt_PT`).
class AppLocalizationsPtPt extends AppLocalizationsPt {
  AppLocalizationsPtPt() : super('pt_PT');

  @override
  String get scanQrHelp =>
      'Abra a câmera e aponte para o QR exibido no Control Center. Este celular liga-se diretamente por um link privado.';

  @override
  String get connectingToMac => 'A ligar ao Control Center…';

  @override
  String get identityChangedBody =>
      'Este servidor não corresponde mais à identidade guardada no emparelhamento. Isso pode significar que o servidor foi reinstalado — ou que algo está interceptando a ligação. Por segurança, este dispositivo não vai ligar. Remova o emparelhamento e escaneie um QR novo no Control Center para emparelhar de novo.';

  @override
  String get couldntConnect => 'Não foi possível ligar';

  @override
  String get pendingPairingTitle => 'Ligar a este servidor?';

  @override
  String get connect => 'Ligar';

  @override
  String get failureUnknown =>
      'Não foi possível ligar — toque para tentar de novo';

  @override
  String get statusConnected => 'Ligado';

  @override
  String get statusConnecting => 'A ligar';

  @override
  String get connectionFailed => 'Falha na ligação';

  @override
  String get identityMismatchBanner =>
      'Identidade do servidor mudou — ligação interrompida. Emparelhe este dispositivo de novo para continuar.';

  @override
  String get disconnectTapAgain =>
      'Toque de novo para desligar este dispositivo do Control Center';

  @override
  String get disconnectDevice => 'Desligar este dispositivo';

  @override
  String get disconnect => 'Desligar';

  @override
  String get inboxNoForgeAccount =>
      'Nenhuma conta de forge está ligada no servidor, então os pull requests ainda não podem ser atribuídos a você.';

  @override
  String get calendarEmptyDescription =>
      'Os eventos dos calendários ligados aparecem aqui.';

  @override
  String get calendarNoAccounts =>
      'Nenhum calendário está ligado neste workspace. Ligue um pelo app do desktop — o login guarda o token no servidor.';

  @override
  String get calendarReauthNeeded =>
      'Uma conta de calendário precisa ser ligada novamente — o que você vê abaixo pode estar desatualizado. Volte a ligar pelo app do desktop.';

  @override
  String get attachFile => 'Anexar um ficheiro';

  @override
  String get save => 'Guardar';

  @override
  String get unsave => 'Remover dos guardados';

  @override
  String get noForgeConnected =>
      'Nenhuma forge está ligada no servidor, então não é possível buscar pull requests. Ligue uma pelo app para computador.';

  @override
  String get files => 'Ficheiros';

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ficheiros',
      one: '1 ficheiro',
    );
    return '$_temp0';
  }

  @override
  String get noChangedFiles => 'Nenhum ficheiro alterado.';

  @override
  String get noTextDiff =>
      'Não há diff de texto para este ficheiro — é binário ou grande demais para a forge retornar.';
}
