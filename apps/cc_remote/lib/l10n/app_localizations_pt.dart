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
