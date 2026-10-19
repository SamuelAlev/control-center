// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Atrás';

  @override
  String get cancel => 'Cancelar';

  @override
  String get retry => 'Reintentar';

  @override
  String get tryAgain => 'Reintentar';

  @override
  String get settings => 'Ajustes';

  @override
  String get refresh => 'Actualizar';

  @override
  String get approve => 'Aprobar';

  @override
  String get deny => 'Denegar';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get agentQuestionHeader => 'Pregunta para ti';

  @override
  String get agentQuestionAnsweredLabel => 'Respondido';

  @override
  String get agentQuestionSkip => 'Omitir';

  @override
  String get agentQuestionSkippedLabel => 'Omitida';

  @override
  String get agentQuestionFreeformHint => 'Escribe tu respuesta…';

  @override
  String get agentApprovalRequired => 'Se requiere aprobación';

  @override
  String get copyCommand => 'Copiar comando';

  @override
  String get approveAndRemember => 'Aprobar durante 8 horas';

  @override
  String get decline => 'Rechazar';

  @override
  String get confirm => 'Confirm';

  @override
  String get send => 'Enviar';

  @override
  String get close => 'Cerrar';

  @override
  String get expand => 'Expandir';

  @override
  String get zoomIn => 'Acercar';

  @override
  String get zoomOut => 'Alejar';

  @override
  String get resetZoom => 'Restablecer el zoom';

  @override
  String get scanQrPrompt =>
      'Escanea el código QR de Control Center para emparejar este teléfono.';

  @override
  String get scanQrHelp =>
      'Abre la cámara y apunta al QR que aparece en Control Center. Este teléfono se conecta directamente por un enlace privado.';

  @override
  String get connectingToMac => 'Conectando a Control Center…';

  @override
  String get connectingDetail => 'Estableciendo un enlace directo y seguro.';

  @override
  String get identityChangedTitle => 'La identidad del servidor ha cambiado';

  @override
  String get identityChangedBody =>
      'Este servidor ya no coincide con la identidad guardada al emparejar. Puede deberse a que se ha reinstalado, o a que algo intercepta la conexión. Por seguridad, este dispositivo no se conectará. Quita el emparejamiento y escanea un código QR nuevo de Control Center para volver a emparejar.';

  @override
  String get removePairing => 'Quitar emparejamiento';

  @override
  String get couldntConnect => 'No se ha podido conectar';

  @override
  String get pendingPairingTitle => '¿Conectar a este servidor?';

  @override
  String get pendingPairingBody =>
      'Un enlace ha pedido a Control Center que se empareje con este servidor. Continúa solo si lo has iniciado tú.';

  @override
  String get connect => 'Conectar';

  @override
  String get failureNotPaired =>
      'Sin emparejar: escanea el código QR de Control Center';

  @override
  String get failureUnreachable =>
      'No se ha podido alcanzar el servidor por ninguna ruta: comprueba que esté en marcha o prueba en la misma red';

  @override
  String get failureIdentityChanged =>
      'La identidad del servidor ha cambiado: si se ha reinstalado, vuelve a emparejar este dispositivo';

  @override
  String get failureAuthRejected =>
      'El servidor ha rechazado este dispositivo: vuelve a emparejarlo desde Control Center';

  @override
  String get failureUnknown => 'No se ha podido conectar: toca para reintentar';

  @override
  String get statusConnected => 'Conectado';

  @override
  String get statusConnecting => 'Conectando';

  @override
  String get statusOffline => 'Sin conexión';

  @override
  String get statusIdentityMismatch => 'Identidad distinta';

  @override
  String get statusNotPaired => 'Sin emparejar';

  @override
  String get statusConfirmPairing => 'Confirmar emparejamiento';

  @override
  String get connectionFailed => 'Error de conexión';

  @override
  String get identityMismatchBanner =>
      'La identidad del servidor ha cambiado: conexión detenida. Vuelve a emparejar este dispositivo para continuar.';

  @override
  String get tabInbox => 'Bandeja';

  @override
  String get tabTickets => 'Tickets';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'Calendario';

  @override
  String get tabNews => 'Noticias';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count en espera';
  }

  @override
  String get updateAvailable => 'Hay un Control Center nuevo';

  @override
  String get appearance => 'Apariencia';

  @override
  String get language => 'Idioma';

  @override
  String get device => 'Dispositivo';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get disconnectTapAgain =>
      'Toca de nuevo para desconectar este dispositivo de Control Center';

  @override
  String get disconnectDevice => 'Desconectar este dispositivo';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get chooseWorkspace => 'Elegir espacio de trabajo';

  @override
  String get workspaces => 'Espacios de trabajo';

  @override
  String get workspacesLoadFailed =>
      'No se han podido cargar los espacios de trabajo';

  @override
  String get noWorkspacesYet => 'Aún no hay espacios de trabajo';

  @override
  String selectWorkspace(String name) {
    return 'Seleccionar $name';
  }

  @override
  String get inboxLoadFailed => 'No se ha podido cargar tu bandeja';

  @override
  String get allCaughtUp => 'Estás al día';

  @override
  String get inboxNoForgeAccount =>
      'No hay ninguna cuenta de forge conectada en el servidor, así que aún no se te pueden atribuir las pull requests.';

  @override
  String get inboxNothingWaiting =>
      'Nada está bloqueado y no hay ninguna pull request esperándote.';

  @override
  String get blocked => 'Bloqueado';

  @override
  String get sectionNeedsYourReview => 'Pendiente de tu revisión';

  @override
  String get sectionReturnedToYou => 'Devueltas a ti';

  @override
  String get sectionApprovedAndReady => 'Aprobadas y listas';

  @override
  String get sectionYourDrafts => 'Tus borradores';

  @override
  String get sectionWaitingForReviewers => 'Esperando revisores';

  @override
  String get sectionMergingAndMerged => 'En fusión y fusionadas recientemente';

  @override
  String get sectionWaitingForAuthor => 'Esperando al autor';

  @override
  String waitingAgo(String ago) {
    return 'esperando $ago';
  }

  @override
  String get openConversation => 'Abrir la conversación';

  @override
  String get calendarLoadFailed => 'No se ha podido cargar tu calendario';

  @override
  String get nothingScheduled => 'Nada programado';

  @override
  String get calendarEmptyDescription =>
      'Aquí aparecen los eventos de tus calendarios conectados.';

  @override
  String get agenda => 'Agenda';

  @override
  String get syncCalendarsNow => 'Sincronizar calendarios ahora';

  @override
  String get event => 'Evento';

  @override
  String get eventNotFound => 'Evento no encontrado';

  @override
  String get eventNotFoundDescription =>
      'Puede estar fuera de la ventana de la agenda o haberse eliminado en origen.';

  @override
  String get joinMeeting => 'Unirse a la reunión';

  @override
  String get join => 'Unirse';

  @override
  String attendeesCount(int count) {
    return 'Asistentes ($count)';
  }

  @override
  String get details => 'Detalles';

  @override
  String get allDay => 'Todo el día';

  @override
  String get happeningNow => 'En curso';

  @override
  String inDuration(String duration) {
    return 'En $duration';
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
  String get attendeeAccepted => 'aceptado';

  @override
  String get attendeeDeclined => 'rechazado';

  @override
  String get attendeeMaybe => 'tal vez';

  @override
  String get attendeeNoReply => 'sin respuesta';

  @override
  String get organizer => 'organizador';

  @override
  String get calendarNoAccounts =>
      'No hay ningún calendario conectado en este espacio de trabajo. Conéctalo desde la app de escritorio: el inicio de sesión guarda el token en el servidor.';

  @override
  String get calendarReauthNeeded =>
      'Hay que volver a conectar una cuenta de calendario: lo que ves abajo puede estar desactualizado. Vuelve a conectarla desde la app de escritorio.';

  @override
  String get spacesLoadFailed => 'No se han podido cargar los espacios';

  @override
  String get noSpaces => 'No hay espacios';

  @override
  String get spacesEmptyDescription =>
      'Aquí aparecen los espacios de este espacio de trabajo.';

  @override
  String get newSpaceFolder => 'Nueva carpeta';

  @override
  String get folderName => 'Nombre de la carpeta';

  @override
  String get renameSpaceFolder => 'Cambiar nombre de la carpeta';

  @override
  String get deleteSpaceFolder => 'Eliminar carpeta';

  @override
  String get moveSpaceToFolder => 'Mover a una carpeta';

  @override
  String get removeSpaceFromFolder => 'Quitar de la carpeta';

  @override
  String get spaceFolderActions => 'Acciones de la carpeta';

  @override
  String get deleteFolderWithSpacesWarning =>
      'Eliminar espacios de forma permanente borra sus mensajes y árboles de trabajo para todos. Esta acción no se puede deshacer.';

  @override
  String get deleteSpacesInFolder =>
      'Eliminar permanentemente los espacios de esta carpeta';

  @override
  String get deleteFolderAndSpaces => 'Eliminar carpeta y espacios';

  @override
  String get keepSpacesInFolder =>
      'De lo contrario, los espacios quedarán fuera de cualquier carpeta.';

  @override
  String get create => 'Crear';

  @override
  String get otherSpaces => 'Otros espacios';

  @override
  String get folderUpdateFailed => 'No se pudieron actualizar las carpetas';

  @override
  String get thread => 'Hilo';

  @override
  String get agentWorking => 'El agente está trabajando';

  @override
  String get messagesLoadFailed => 'No se han podido cargar los mensajes';

  @override
  String get noMessagesYet => 'Aún no hay mensajes';

  @override
  String get noMessagesDescription =>
      'Envía un mensaje para empezar la conversación.';

  @override
  String get agentResponding => 'Agente respondiendo';

  @override
  String get agentFinished => 'Agente terminado';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names son demasiado grandes para enviarlos desde aquí.',
      one: '$names es demasiado grande para enviarlo desde aquí.',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$names son demasiado grandes para enviarlos por el relay desde aquí.',
      one: '$names es demasiado grande para enviarlo por el relay desde aquí.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'No se ha podido subir el archivo adjunto. Inténtalo de nuevo.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'No se han podido subir $count archivos adjuntos y se han omitido.',
      one: 'No se ha podido subir 1 archivo adjunto y se ha omitido.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Compañero';

  @override
  String get agent => 'Agente';

  @override
  String get attachFile => 'Adjuntar un archivo';

  @override
  String get messageHint => 'Mensaje';

  @override
  String removeAttachment(String name) {
    return 'Quitar $name';
  }

  @override
  String get articlesLoadFailed => 'No se han podido cargar los artículos';

  @override
  String get noArticles => 'No hay artículos';

  @override
  String get articlesEmptyDescription =>
      'Los artículos nuevos aparecen aquí al actualizarse las fuentes.';

  @override
  String get unread => 'No leídos';

  @override
  String get allFeeds => 'Todas las fuentes';

  @override
  String get save => 'Guardar';

  @override
  String get unsave => 'Quitar de guardados';

  @override
  String get readFullArticle => 'Leer el artículo completo';

  @override
  String get ticketsLoadFailed => 'No se han podido cargar los tickets';

  @override
  String get noTickets => 'No hay tickets';

  @override
  String get ticketsEmptyDescription =>
      'Aquí aparecen los tickets de este espacio de trabajo.';

  @override
  String get all => 'Todo';

  @override
  String get ticket => 'Ticket';

  @override
  String get ticketLoadFailed => 'No se ha podido cargar el ticket';

  @override
  String assignedTo(String name) {
    return 'Asignado a $name';
  }

  @override
  String get openInBrowser => 'Abrir en el navegador';

  @override
  String get status => 'Estado';

  @override
  String get assign => 'Asignar';

  @override
  String get reassign => 'Reasignar';

  @override
  String get noAgents => 'Sin agentes';

  @override
  String get noAgentsDescription =>
      'Asigna un agente de este espacio de trabajo.';

  @override
  String get statusOpen => 'Abierto';

  @override
  String get statusInProgress => 'En curso';

  @override
  String get statusBlocked => 'Bloqueado';

  @override
  String get statusInReview => 'En revisión';

  @override
  String get statusDone => 'Hecho';

  @override
  String get statusBacklog => 'Backlog';

  @override
  String get lensNeedsMe => 'Me necesitan';

  @override
  String get lensMine => 'Míos';

  @override
  String get prsLoadFailed => 'No se han podido cargar las pull requests';

  @override
  String get noOpenPullRequests => 'No hay pull requests abiertas';

  @override
  String get nothingWaitingOnReview => 'Nada pendiente de tu revisión';

  @override
  String get noOwnOpenPullRequests => 'No tienes pull requests abiertas';

  @override
  String get nothingBlocked => 'Nada bloqueado';

  @override
  String get prsEmptyDescription =>
      'Aquí aparecen las pull requests de los repositorios de este espacio de trabajo.';

  @override
  String get refreshPullRequests => 'Actualizar pull requests';

  @override
  String get noForgeConnected =>
      'No hay ningún forge conectado en el servidor, así que no se pueden obtener pull requests. Conéctalo desde la aplicación de escritorio.';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'No se han podido leer $count repositorios.',
      one: 'No se ha podido leer 1 repositorio.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'No se pueden leer: $names';
  }

  @override
  String get installationSuspendedTitle =>
      'Instalación de GitHub App suspendida';

  @override
  String installationSuspendedBody(String names) {
    return 'Se muestran los últimos datos conocidos de $names. Reanuda la instalación en GitHub o conecta un token con acceso.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'Instalación de GitHub App suspendida. Se muestran los últimos datos conocidos de $names. Reanuda la instalación en GitHub o conecta un token con acceso.';
  }

  @override
  String get draft => 'Borrador';

  @override
  String get merged => 'Fusionado';

  @override
  String get closed => 'Cerrado';

  @override
  String get open => 'Abierta';

  @override
  String get approved => 'Aprobado';

  @override
  String get changesRequested => 'Cambios solicitados';

  @override
  String get reviewRequired => 'Revisión necesaria';

  @override
  String get checksPassing => 'Comprobaciones correctas';

  @override
  String get checksFailing => 'Comprobaciones fallidas';

  @override
  String get checksRunning => 'Comprobaciones en curso';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'No se ha podido cargar esta pull request';

  @override
  String get openOnForge => 'Abrir en el forge';

  @override
  String get requestChangesNeedsComment =>
      'Añade un comentario explicando qué hay que cambiar.';

  @override
  String get conversation => 'Conversación';

  @override
  String get files => 'Archivos';

  @override
  String get checks => 'Comprobaciones';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos',
      one: '1 archivo',
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
  String get conflicts => 'Conflictos';

  @override
  String get reviewers => 'REVISORES';

  @override
  String get noDescriptionNoComments =>
      'Aún no hay descripción ni comentarios.';

  @override
  String get noChangedFiles => 'No hay archivos modificados.';

  @override
  String get noChecksReported =>
      'No hay comprobaciones para el commit de cabecera.';

  @override
  String get reviewCommentHint => 'Deja un comentario de revisión…';

  @override
  String get comment => 'Comentario';

  @override
  String get commentPosted => 'Comentario publicado';

  @override
  String get request => 'Solicitar';

  @override
  String get squashAndMerge => 'Squash and merge';

  @override
  String noActionsAvailable(String status) {
    return '$status — no hay acciones disponibles.';
  }

  @override
  String get reviewApproved => 'aprobada';

  @override
  String get reviewRequestedChanges => 'ha solicitado cambios';

  @override
  String get reviewCommented => 'revisada';

  @override
  String get reviewPending => 'pendiente';

  @override
  String get unknownAuthor => 'desconocido';

  @override
  String hideDiffFor(String file) {
    return 'Ocultar el diff de $file';
  }

  @override
  String showDiffFor(String file) {
    return 'Mostrar el diff de $file';
  }

  @override
  String get checkRunning => 'en ejecución';

  @override
  String get checkPassed => 'correcta';

  @override
  String get checkFailed => 'fallida';

  @override
  String get checkCancelled => 'cancelada';

  @override
  String get checkSkipped => 'omitida';

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
      'No hay diff de texto para este archivo: es binario o demasiado grande para que el forge lo devuelva.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mostrar las $count líneas restantes',
      one: 'Mostrar la línea restante',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count líneas sin cambios',
      one: '1 línea sin cambios',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'Ir al más reciente';

  @override
  String get streaming => 'Transmitiendo';

  @override
  String get working => 'Trabajando';

  @override
  String get input => 'Entrada';

  @override
  String get output => 'Salida';

  @override
  String get now => 'ahora';

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
  String get today => 'Hoy';

  @override
  String get tomorrow => 'Mañana';

  @override
  String get yesterday => 'ayer';

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
  String get mobileConversations => 'Conversaciones';

  @override
  String get mobileNewConversation => 'Nueva conversación';

  @override
  String get mobileConversationName => 'Nombre de la conversación';

  @override
  String get mobileRename => 'Cambiar nombre';

  @override
  String get mobileManageSpace => 'Gestionar espacio';

  @override
  String get mobileArchived => 'Archivado';

  @override
  String get mobileSearchMessages =>
      'Buscar en todos los mensajes de este espacio';

  @override
  String get mobileSearch => 'Buscar';

  @override
  String get mobileNoResults => 'Sin resultados';

  @override
  String get mobileReopen => 'Reabrir';

  @override
  String get mobileArchive => 'Archivar';

  @override
  String get mobileProgress => 'Progreso y contexto';

  @override
  String get mobileReadFailed =>
      'No se pudo marcar esta conversación como leída';

  @override
  String get mobileSendFailed =>
      'No se envió el mensaje. Tu borrador sigue aquí.';

  @override
  String get sentAttachmentUnavailable => 'Adjunto no disponible';

  @override
  String get sentAttachmentLoadFailed => 'No se pudo cargar el adjunto';

  @override
  String get mobileActionFailed => 'La acción falló';

  @override
  String get mobileRemove => 'Quitar';

  @override
  String get mobileLinkedMessage => 'Mensaje enlazado';

  @override
  String get mobileOlderMessages => 'Mensajes anteriores';

  @override
  String get mobileMessageActions => 'Acciones del mensaje';

  @override
  String get mobileOpenThread => 'Abrir hilo';

  @override
  String get mobileCopyLink => 'Copiar enlace';

  @override
  String get mobileStopRun => 'Detener ejecución';

  @override
  String get mobileStopRunConfirm =>
      '¿Detener esta ejecución del agente? Se conservará el trabajo ya completado.';

  @override
  String get mobileControlUnsupported =>
      'Esta ejecución ha terminado o no admite esta acción.';

  @override
  String get mobilePauseRequested => 'Se solicitó pausar en el siguiente turno';

  @override
  String get mobileResumed => 'Ejecución reanudada';

  @override
  String get mobileStopRequested => 'Se solicitó detener la ejecución';

  @override
  String get mobileQueuedMessages => 'Mensajes en cola';

  @override
  String get mobilePauseRun => 'Pausar en el siguiente turno';

  @override
  String get mobileResumeRun => 'Reanudar';

  @override
  String get mobileEditQueued => 'Editar el mensaje en cola';

  @override
  String get mobileSteerNow => 'Redirigir ahora';

  @override
  String get mobileMoveUp => 'Subir';

  @override
  String get mobileMoveDown => 'Bajar';

  @override
  String get mobileQueueChanged =>
      'La cola ha cambiado o esta ejecución no admite instrucciones en directo. Actualiza y vuelve a intentarlo.';

  @override
  String get mobileActivity => 'Actividad';

  @override
  String get mobilePermissions => 'Permisos y auditoría';

  @override
  String get mobilePlans => 'Planes';

  @override
  String get mobileGoals => 'Objetivos supervisados';

  @override
  String get mobileCredentials => 'Conexiones y credenciales';

  @override
  String get mobileWorkspaceUnavailable =>
      'Este espacio de trabajo no está disponible o ya no tienes acceso.';

  @override
  String get mobilePrReviewThreads => 'Hilos de revisión';

  @override
  String get mobilePrThreadsLoadFailed =>
      'No se pudieron cargar los hilos de revisión';

  @override
  String get mobilePrNoReviewThreads =>
      'Todavía no hay hilos de revisión en línea';

  @override
  String get mobilePrCommentPermissionDenied =>
      'No tienes permiso para comentar en este repositorio.';

  @override
  String get mobilePrPermissionChecking =>
      'Comprobando permisos para comentar…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'No se pudieron comprobar los permisos. Vuelve a intentarlo para comentar.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return 'Línea $line ($side)';
  }

  @override
  String get mobilePrOriginalSide => 'Original';

  @override
  String get mobilePrSelectCommentLine => 'Elige una línea para comentar';

  @override
  String get mobilePrUpdatedSide => 'Actualizado';

  @override
  String get mobilePrThreadResolved => 'Resuelto';

  @override
  String get mobilePrReplyHint => 'Escribe una respuesta…';

  @override
  String get mobilePrCommentRequired =>
      'Escribe un comentario antes de publicarlo.';

  @override
  String get mobilePrReply => 'Responder';

  @override
  String get mobilePrReopenThread => 'Reabrir hilo';

  @override
  String get mobilePrResolveThread => 'Resolver hilo';

  @override
  String get mobilePrResolvePermissionDenied =>
      'Solo quien creó la pull request o alguien con acceso de escritura puede resolver este hilo.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'Comentar en la línea $line ($side)';
  }

  @override
  String get mobilePrInlineCommentHint => 'Escribe un comentario en línea…';

  @override
  String get mobilePrPostInlineComment => 'Publicar comentario';

  @override
  String get mobilePrCommentUnavailable =>
      'Los comentarios en línea no están disponibles para esta pull request.';

  @override
  String get mobilePrPatchUnavailable =>
      'El servicio de repositorios no proporcionó un parche de texto para este archivo.';

  @override
  String get mobilePrNoPatchForFile =>
      'El parche de este archivo no está disponible.';

  @override
  String get mobileTicketNew => 'Nuevo ticket';

  @override
  String get mobileTicketCreate => 'Crear ticket';

  @override
  String get mobileTicketEdit => 'Editar ticket';

  @override
  String get mobileTicketTitle => 'Título';

  @override
  String get mobileTicketTitleRequired =>
      'Introduce un título para guardar este ticket.';

  @override
  String get mobileTicketDescription => 'Descripción';

  @override
  String get mobileTicketMarkdownHint => 'Añade detalles en Markdown';

  @override
  String get mobileTicketPriority => 'Prioridad';

  @override
  String get mobileTicketPriorityNone => 'Sin prioridad';

  @override
  String get mobileTicketPriorityUrgent => 'Urgente';

  @override
  String get mobileTicketPriorityHigh => 'Alto';

  @override
  String get mobileTicketPriorityMedium => 'Medio';

  @override
  String get mobileTicketPriorityLow => 'Bajo';

  @override
  String get mobileTicketLabels => 'Etiquetas';

  @override
  String get mobileTicketLabelsHint => 'Una etiqueta por línea';

  @override
  String get mobileTicketLabelsHelp =>
      'Escribe cada etiqueta en una línea distinta.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'Registrado en $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'Sin asignar';

  @override
  String get mobileTicketAssignedFilter => 'Asignados';

  @override
  String get mobileTicketAgentsLoadFailed =>
      'No se pudieron cargar los agentes';

  @override
  String get mobileTicketSearch => 'Buscar tickets';

  @override
  String get mobileTicketSearchHint =>
      'Título, clave, descripción, etiqueta o persona asignada';

  @override
  String get mobileTicketClearSearch => 'Borrar búsqueda de tickets';

  @override
  String get mobileTicketNoMatches => 'No hay tickets que coincidan';

  @override
  String get mobileTicketAdjustFilters =>
      'Prueba otra búsqueda o cambia los filtros.';

  @override
  String get mobileTicketClearFilters => 'Borrar filtros';

  @override
  String get mobileTicketNotFound => 'No se encontró el ticket';

  @override
  String get mobileTicketNotFoundDescription =>
      'Puede que este ticket se haya eliminado o trasladado fuera de este espacio de trabajo.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'Ha cambiado el espacio de trabajo. Vuelve al actual antes de guardar.';

  @override
  String get mobileTicketOpenLinkedSpace => 'Abrir espacio vinculado';

  @override
  String get mobileTicketReadOnly =>
      'Debes ser miembro del espacio de trabajo para modificar tickets.';

  @override
  String get permissionTitle => 'Permisos';

  @override
  String get permissionWorkspaceFailed =>
      'No se pudo cargar el espacio de trabajo';

  @override
  String get permissionNoWorkspace =>
      'Selecciona un espacio de trabajo para consultar los permisos.';

  @override
  String get permissionLoading => 'Cargando permisos…';

  @override
  String get permissionScopeDescription =>
      'Consulta cómo se decide cada acción en este ámbito. Los agentes y espacios pueden heredar las reglas del espacio de trabajo.';

  @override
  String get permissionScope => 'Ámbito de la política';

  @override
  String get permissionWorkspaceScope => 'Espacio de trabajo';

  @override
  String get permissionAgentScope => 'Agente';

  @override
  String get permissionSpaceScope => 'Espacio';

  @override
  String get permissionAgentContext => 'Agente que actúa en este espacio';

  @override
  String get permissionNoAgentContext => 'No se ha seleccionado ningún agente';

  @override
  String get permissionTargetsFailed =>
      'No se pudieron cargar los ámbitos disponibles';

  @override
  String get permissionNoTargets =>
      'No hay opciones disponibles en este ámbito.';

  @override
  String get permissionRoleFailed =>
      'No se pudo confirmar tu rol en el espacio de trabajo';

  @override
  String get permissionMemberRequired =>
      'Debes ser miembro del espacio de trabajo para ver las reglas de la política.';

  @override
  String get permissionRulesFailed =>
      'No se pudieron cargar las reglas de la política';

  @override
  String get permissionAuditAdminOnly =>
      'El historial de autorizaciones solo está disponible para administradores del espacio de trabajo.';

  @override
  String get permissionAllow => 'Permitir';

  @override
  String get permissionAsk => 'Preguntar primero';

  @override
  String get permissionDeny => 'Denegar';

  @override
  String get permissionFileDelete => 'Eliminar archivos';

  @override
  String get permissionFileWriteOutsideWorktree =>
      'Escribir fuera del árbol de trabajo';

  @override
  String get permissionGitCommit => 'Confirmar cambios';

  @override
  String get permissionGitPush => 'Enviar commits';

  @override
  String get permissionPrCreate => 'Crear pull requests';

  @override
  String get permissionPrPublish => 'Publicar pull requests';

  @override
  String get permissionVendorSyncWrite =>
      'Escribir datos de sincronización del proveedor';

  @override
  String get permissionNetworkEgress => 'Acceder a la red';

  @override
  String get permissionSecretAccess => 'Acceder a secretos';

  @override
  String get permissionPackageInstall => 'Instalar paquetes';

  @override
  String get permissionProcessSpawn => 'Iniciar procesos';

  @override
  String get permissionWorkspaceMutation => 'Modificar el espacio de trabajo';

  @override
  String get permissionEnclosureControl => 'Controlar el entorno aislado';

  @override
  String get permissionChangeFailed => 'No se pudo cambiar la regla';

  @override
  String get permissionEffectiveDescription =>
      'Regla efectiva en este ámbito sin argumentos de acción. Las autorizaciones condicionales siguientes solo se aplican a solicitudes que coincidan; el servidor toma la decisión final.';

  @override
  String get permissionSpaceAgentNote =>
      'No se ha seleccionado ningún agente. Elige uno arriba para ver sus reglas específicas.';

  @override
  String get permissionScopedGrants => 'Reglas en este ámbito';

  @override
  String get permissionModePreset => 'Preajuste del modo';

  @override
  String get permissionBuiltInDefault => 'Valor predeterminado';

  @override
  String get permissionRemembered => 'Aprobación recordada';

  @override
  String get permissionSource => 'Fuente';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · definida aquí';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · heredada';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'Caduca el $date';
  }

  @override
  String get permissionSetHere => 'Definir una regla aquí';

  @override
  String get permissionRevokeBeforeEdit =>
      'Revoca la regla específica o recordada antes de definir una regla general para esta acción.';

  @override
  String get permissionConfirmRevoke => 'Confirmar revocación';

  @override
  String get permissionRevokeRule => 'Revocar regla';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'Prefijo del comando: $prefix';
  }

  @override
  String get permissionNoExpiry => 'Sin caducidad';

  @override
  String get permissionExpired => 'Caducada';

  @override
  String get permissionExplicitRule => 'Regla explícita';

  @override
  String get permissionEnforcementAdvisory =>
      'Informativa: las reglas «preguntar primero» se registran sin solicitar aprobación';

  @override
  String get permissionEnforcementSoft =>
      'Aplicación flexible: anular la regla requiere autorización';

  @override
  String get permissionEnforcementHard =>
      'Aplicación estricta: no se puede anular';

  @override
  String permissionPaths(String paths) {
    return 'Rutas: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Referencias de Git: $refs';
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
    return 'Cantidad máxima: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'Céntimos máximos: $cents';
  }

  @override
  String get permissionAuditHeading => 'Historial de autorizaciones';

  @override
  String get permissionAuditDescription =>
      'Decisiones recientes registradas por el servidor. Solo los administradores pueden consultar el registro o verificar su cadena de hashes.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'en nombre de $user';
  }

  @override
  String get permissionPrompted => 'Se solicitó aprobación humana';

  @override
  String get permissionVerifyChain => 'Verificar cadena de auditoría';

  @override
  String get permissionVerifyFailed =>
      'No se pudo verificar la cadena de auditoría';

  @override
  String permissionChainIntact(String count) {
    return 'Cadena íntegra · $count entradas comprobadas';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'Cadena rota en la entrada $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty =>
      'Todavía no se han registrado decisiones de autorización.';

  @override
  String get permissionAuditFailed =>
      'No se pudo cargar el historial de autorizaciones';

  @override
  String get mobilePlansLoadFailed => 'No se pudieron cargar los planes';

  @override
  String get mobilePlansEmpty => 'Todavía no hay planes';

  @override
  String get mobilePlansEmptyDescription =>
      'Los planes enviados por los agentes aparecerán aquí para su revisión.';

  @override
  String get mobilePlanTitle => 'Plan';

  @override
  String get mobilePlanMissing =>
      'Este plan ya no está disponible en este espacio de trabajo.';

  @override
  String mobilePlanStepCount(int count) {
    return '$count pasos';
  }

  @override
  String get mobilePlanDraft => 'Borrador';

  @override
  String get mobilePlanProposed => 'Pendiente de revisión';

  @override
  String get mobilePlanApproved => 'Aprobado';

  @override
  String get mobilePlanRejected => 'Rechazado';

  @override
  String get mobilePlanSuperseded => 'Sustituido';

  @override
  String get mobilePlanExecuting => 'Ejecutando';

  @override
  String get mobilePlanSynthesizing => 'Sintetizando';

  @override
  String get mobilePlanCompleted => 'Completed';

  @override
  String get mobilePlanFailed => 'Error';

  @override
  String get mobilePlanCancelled => 'Cancelled';

  @override
  String mobilePlanRevision(String revision) {
    return 'Revisión $revision';
  }

  @override
  String get mobilePlanSteps => 'Pasos';

  @override
  String get mobilePlanNoSteps => 'No se enviaron pasos para este plan.';

  @override
  String get mobilePlanAssumptions => 'Aclaraciones';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'Depende de $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'Estimación máxima: $cost';
  }

  @override
  String get mobilePlanSelect => 'Seleccionar';

  @override
  String get mobilePlanSelected => 'Seleccionado';

  @override
  String get mobilePlanEstimate => 'Estimar coste';

  @override
  String get mobilePlanEstimateRequired =>
      'Estima el coste del plan antes de aprobar su ejecución.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'Coste estimado: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'no disponible';

  @override
  String get mobilePlanNoHardCap => 'sin límite estricto';

  @override
  String get mobilePlanExceedsBudget =>
      'La estimación supera el presupuesto configurado. Revísala antes de aprobar.';

  @override
  String get mobilePlanPartialEstimate =>
      'Esta estimación abarca todo el plan; los pasos seleccionados podrían costar menos.';

  @override
  String get mobilePlanConfirmAll => '¿Iniciar el plan completo?';

  @override
  String get mobilePlanConfirmSelected => '¿Iniciar los pasos seleccionados?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'La aprobación inicia la ejecución y puede generar cargos. Coste máximo estimado: $cost. Límite presupuestario: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'Aprobar todo y ejecutar';

  @override
  String get mobilePlanApproveSelected => 'Aprobar seleccionados y ejecutar';

  @override
  String get mobilePlanWiden => 'Aprobar más pasos';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return '¿Autorizar la ejecución de $count pasos más? Pueden generar cargos. Límite de coste de la ejecución actual: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'El plan ha cambiado durante la revisión. Abre la revisión más reciente y vuelve a estimar su coste.';

  @override
  String get mobilePlanReject => 'Rechazar plan';

  @override
  String get mobilePlanRejectConfirm => '¿Rechazar este plan? No se ejecutará.';

  @override
  String get mobilePlanStop => 'Detener ejecución';

  @override
  String get mobilePlanStopConfirm =>
      '¿Detener la ejecución de este plan? El trabajo ya completado no se deshará.';

  @override
  String mobilePlanRunId(String runId) {
    return 'Ejecución: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'Aprobación aceptada. Esperando el registro de ejecución…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return '$completed de $total pasos de ejecución completados';
  }

  @override
  String get mobilePlanOpenConversation => 'Abrir conversación';

  @override
  String get mobileGoalsTitle => 'Objetivos supervisados';

  @override
  String get mobileGoalsLoadFailed =>
      'No se pudieron cargar los objetivos supervisados';

  @override
  String get mobileGoalsEmpty => 'Todavía no hay objetivos supervisados';

  @override
  String get mobileGoalsEmptyDescription =>
      'Inicia uno en un espacio o envía /goal en una conversación.';

  @override
  String get mobileGoalMissing =>
      'Este objetivo ya no está disponible en este espacio de trabajo.';

  @override
  String get mobileGoalActive => 'Activo';

  @override
  String get mobileGoalPaused => 'En pausa';

  @override
  String get mobileGoalCompleted => 'Completed';

  @override
  String get mobileGoalFailed => 'Error';

  @override
  String get mobileGoalCancelled => 'Cancelled';

  @override
  String get mobileGoalBudgetExhausted => 'Presupuesto agotado';

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
    return '$count ejecuciones';
  }

  @override
  String get mobileGoalNoRunLimit => 'sin límite';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return 'Ejecuciones: $runs / $maxRuns · Gastado: $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return 'Fecha límite: $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return 'Ejecuciones fallidas consecutivas: $count';
  }

  @override
  String get mobileGoalSummary => 'Resumen de finalización';

  @override
  String get mobileGoalFailedDescription =>
      'El supervisor se detuvo tras varios fallos de ejecución. Consulta los detalles en la conversación.';

  @override
  String get mobileGoalBudgetWall =>
      'Se alcanzó la fecha límite o el máximo de ejecuciones. Este objetivo no puede reanudarse aumentando el límite de coste.';

  @override
  String get mobileGoalPause => 'Pausar objetivo';

  @override
  String get mobileGoalResume => 'Reanudar objetivo';

  @override
  String get mobileGoalStop => 'Cancelar objetivo';

  @override
  String get mobileGoalStopConfirm =>
      '¿Cancelar definitivamente este objetivo supervisado? No podrá reanudarse.';

  @override
  String get mobileGoalRaiseBudget => 'Aumentar presupuesto y reanudar';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'Aumentar el presupuesto a $amount y reanudar';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return '¿Aumentar el límite de coste de este objetivo de $oldCap a $newCap y reanudar el gasto?';
  }

  @override
  String get mobileGoalOpenConversation => 'Abrir conversación del objetivo';

  @override
  String get mobileGoalCreate => 'Iniciar objetivo supervisado';

  @override
  String get mobileGoalChooseSpace => 'Ejecutar en el espacio';

  @override
  String get mobileGoalNoSpaces =>
      'Crea un espacio antes de iniciar un objetivo.';

  @override
  String get mobileGoalChooseAgent => 'Ejecutar con el agente';

  @override
  String get mobileGoalNoAgents =>
      'Añade un agente activo antes de iniciar un objetivo.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return '$name seleccionado';
  }

  @override
  String get mobileGoalObjectiveHint =>
      '¿Qué resultado debe perseguir el agente?';

  @override
  String get mobileGoalBudgetUsd => 'Límite de coste (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'Elige un espacio y un agente, escribe un objetivo y fija un límite de coste positivo en USD.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return '¿Iniciar un objetivo supervisado con un coste máximo de $cap? El agente podría empezar de inmediato.';
  }

  @override
  String get mobileGoalUnavailable =>
      'La conexión con el servidor no está lista. Reinténtalo cuando se restablezca.';

  @override
  String get mobileGoalConversationMissing =>
      'La conversación seleccionada ya no está disponible en este espacio de trabajo.';

  @override
  String get mobileGoalCreateSent =>
      'Objetivo iniciado. Su estado aparecerá en esta lista.';

  @override
  String get mobileGoalStartRefused =>
      'No se inició ninguna ejecución del objetivo. Consulta el motivo del supervisor en la conversación.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return '$name seleccionado';
  }

  @override
  String get requestUnavailable =>
      'Esta solicitud ya no está disponible en el espacio de trabajo activo.';

  @override
  String get requestAlreadyResolved => 'Esta solicitud ya se ha resuelto.';

  @override
  String get inboxCredentialsBlocked => 'Credenciales que bloquean ejecuciones';

  @override
  String get inboxSyncFailures => 'Sincronizaciones fallidas con proveedores';

  @override
  String get inboxConfigureCredentials => 'Configurar credenciales';

  @override
  String get openTicket => 'Abrir ticket';

  @override
  String get activityTitle => 'Actividad';

  @override
  String get activityClearAll => 'Borrar actividad';

  @override
  String get activityClearConfirm =>
      'Esto ocultará toda la actividad registrada hasta ahora para ti en todos tus dispositivos. La actividad nueva seguirá apareciendo.';

  @override
  String get activityMarkAllRead => 'Marcar todo como leído';

  @override
  String get activityMarkAllConfirm =>
      '¿Marcar como leídos todos los elementos de actividad de este espacio de trabajo en todos tus dispositivos?';

  @override
  String get activityMarkRead => 'Marcar como leído';

  @override
  String get activityMarkUnread => 'Marcar como no leído';

  @override
  String get activityDismiss => 'Descartar';

  @override
  String get activityResolved => 'Resuelto';

  @override
  String get activityOpen => 'Abierto';

  @override
  String get activityEmpty => 'Sin actividad todavía';

  @override
  String get activityLoadFailed => 'No se pudo cargar la actividad';

  @override
  String get activityAgentWaiting => 'El agente necesita información';

  @override
  String get activityAgentBlocked => 'Acción del agente bloqueada';

  @override
  String get activityMessage => 'Mensaje nuevo';

  @override
  String get activityPullRequest => 'Actualización de pull request';

  @override
  String get activityTicket => 'Actualización de ticket';

  @override
  String get activityMeeting => 'Actualización de reunión';

  @override
  String get activityCalendar => 'Conexión con el calendario';

  @override
  String get activityRig => 'Actualización del entorno aislado';

  @override
  String get activityEvent => 'Actualizar';

  @override
  String get activityPrReady => 'Pull request lista para fusionar';

  @override
  String get activityPrBlocked => 'Fusión de pull request bloqueada';

  @override
  String get activityPrApproved => 'Pull request aprobada';

  @override
  String get activityPrChanges => 'Cambios solicitados';

  @override
  String get activityPrChecksFailed =>
      'Fallaron las comprobaciones de la pull request';

  @override
  String get activityPrChecksRecovered =>
      'Las comprobaciones de la pull request vuelven a funcionar';

  @override
  String get activityPrComment => 'Comentario en pull request';

  @override
  String get activityPrPublished => 'Pull request publicada';

  @override
  String get activityPrMerged => 'Pull request merged';

  @override
  String get activityPrMentioned => 'Mención en una pull request';

  @override
  String get activityPrReviewRequested => 'Revisión solicitada';

  @override
  String get activityPrReviewStale => 'La revisión debe actualizarse';

  @override
  String get activityTicketAssigned => 'Ticket asignado';

  @override
  String get activityTicketChanged => 'Estado del ticket cambiado';

  @override
  String get activityMeetingSoon => 'Reunión a punto de empezar';

  @override
  String get activityCalendarExpired =>
      'La conexión con el calendario ha caducado';

  @override
  String get activityRigControl => 'Cambio en el control del entorno aislado';

  @override
  String get activityRigClosed => 'Entorno aislado detenido';

  @override
  String get mobileSpacesSearch => 'Buscar espacios';

  @override
  String get mobileSpacesArchived => 'Archivado';

  @override
  String get mobileSpacesActive => 'Activo';

  @override
  String get mobileSpacesNew => 'Nuevo espacio';

  @override
  String get mobileSpacesManage => 'Gestionar espacio';

  @override
  String get mobileSpacesName => 'Nombre del espacio';

  @override
  String get mobileSpacesAgents => 'Agentes';

  @override
  String get mobileSpacesMembers => 'Personas';

  @override
  String get mobileSpacesRepos => 'Repositorios';

  @override
  String get mobileSpacesAllRepos => 'Todos los repositorios vinculados';

  @override
  String get mobileSpacesNoRepos => 'Sin repositorios';

  @override
  String get mobileSpacesBaseBranch => 'Rama base (opcional)';

  @override
  String get mobileSpacesDefaultBranch => 'Rama predeterminada';

  @override
  String get mobileSpacesMode => 'Modo';

  @override
  String get mobileSpacesModeChat => 'Chat';

  @override
  String get mobileSpacesModeReview => 'Revisión (solo lectura)';

  @override
  String get mobileSpacesModePlan => 'Planificación (solo lectura)';

  @override
  String get mobileSpacesModeOrchestrate => 'Orquestar';

  @override
  String get mobileSpacesAutonomy => 'Anulación de autonomía';

  @override
  String get mobileSpacesAutonomyInherited => 'Heredado';

  @override
  String get mobileSpacesAutonomyPropose => 'Solo proponer';

  @override
  String get mobileSpacesAutonomyApproval => 'Actuar con aprobación';

  @override
  String get mobileSpacesAutonomyFreely => 'Actuar libremente';

  @override
  String get mobileSpacesAutonomyNotice =>
      'Una anulación no puede eludir solicitudes ni denegaciones de la política de acciones. Solo los administradores del espacio de trabajo pueden cambiarla.';

  @override
  String get mobileSpacesArchive => 'Archivar espacio';

  @override
  String get mobileSpacesReopen => 'Reabrir espacio';

  @override
  String get mobileSpacesSave => 'Guardar cambios';

  @override
  String get mobileSpacesCreate => 'Crear espacio';

  @override
  String get mobileSpacesOperationFailed => 'No se pudo actualizar el espacio';

  @override
  String get mobileSpacesMissing =>
      'No se encontró el espacio en este espacio de trabajo';

  @override
  String get mobileSpacesEmptyName => 'Introduce un nombre para el espacio';

  @override
  String get mobileSpacesNoMatches => 'No hay espacios que coincidan';

  @override
  String get mobileSpacesUnread => 'Respuesta del agente sin leer';

  @override
  String get mobileSpacesNeedsInput => 'Necesita tu respuesta';

  @override
  String get mobileSpacesRunning => 'Agente en ejecución';

  @override
  String get mobileSpacesNoAgents =>
      'No hay agentes en este espacio de trabajo';

  @override
  String get mobileSpacesNoMembers =>
      'No hay más miembros en el espacio de trabajo';

  @override
  String get mobileSpacesRepoError => 'No se pudieron cargar los repositorios';

  @override
  String get mobileSpacesRetry => 'Reintentar';

  @override
  String get mobileSpacesBranchUnavailable =>
      'Elige o escribe una rama base al crear un espacio; no se puede cambiar la rama base de un espacio existente.';

  @override
  String get mobileSpacesArchivedEmpty => 'No hay espacios archivados';

  @override
  String get mobileSpacesAllRepoWarning =>
      'Los repositorios que se vinculen más adelante al espacio de trabajo también se incluirán en este espacio.';

  @override
  String get mobileSpacesCreatedRetry =>
      'Espacio creado. Vuelve a intentar añadir personas o abre su página de gestión.';

  @override
  String get progressTitle => 'Progreso';

  @override
  String get progressConversation => 'Conversación';

  @override
  String get progressLoadFailed => 'No se pudo cargar el progreso';

  @override
  String get progressUnavailable => 'Conversación no disponible';

  @override
  String get progressUnavailableDescription =>
      'Esta conversación no está en el espacio de trabajo y el espacio activos. Vuelve a su espacio para continuar.';

  @override
  String get progressSaveFailed => 'No se pudo actualizar el progreso';

  @override
  String get progressGoal => 'Objetivo';

  @override
  String get progressNoGoal => 'No hay ningún objetivo de trabajo definido';

  @override
  String get progressSetGoal => 'Definir objetivo';

  @override
  String get progressEditGoal => 'Editar objetivo';

  @override
  String get progressClearGoal => 'Borrar objetivo';

  @override
  String get progressGoalRequired => 'Introduce un objetivo antes de guardar.';

  @override
  String get progressTodos => 'Tareas';

  @override
  String get transcriptToolTodos => 'Tareas';

  @override
  String get transcriptToolSearchMemory => 'Buscar en la memoria';

  @override
  String get transcriptToolRenderMedia => 'Mostrar contenido multimedia';

  @override
  String get progressNoTodos => 'Todavía no hay tareas';

  @override
  String get progressNewTodo => 'Nueva tarea';

  @override
  String get progressAddTodo => 'Añadir tarea';

  @override
  String get progressEditTodo => 'Editar tarea';

  @override
  String get progressTodoRequired => 'Introduce una tarea antes de guardar.';

  @override
  String get progressTodoNoLongerExists =>
      'Esa tarea se ha eliminado. Recarga la lista y vuelve a intentarlo.';

  @override
  String get progressWorkspaceChanged =>
      'Ha cambiado el espacio de trabajo activo. Vuelve a esta conversación e inténtalo de nuevo.';

  @override
  String progressRemoveTodo(String name) {
    return 'Quitar tarea $name';
  }

  @override
  String get progressPending => 'Pending';

  @override
  String get progressInProgress => 'En curso';

  @override
  String get progressCompleted => 'Completed';

  @override
  String get progressMoveUp => 'Subir tarea';

  @override
  String get progressMoveDown => 'Bajar tarea';

  @override
  String get progressRunTree => 'Ejecuciones de agentes';

  @override
  String get progressNoRuns =>
      'Todavía no hay ejecuciones en esta conversación';

  @override
  String get progressRunning => 'En ejecución';

  @override
  String get progressFailed => 'Error';

  @override
  String get progressUnknown => 'Desconocido';

  @override
  String get progressHealthy => 'Activo';

  @override
  String get progressBlocked => 'Bloqueado';

  @override
  String get progressLooping => 'En bucle';

  @override
  String get progressStalled => 'Estancado';

  @override
  String get progressDead => 'Detenido inesperadamente';

  @override
  String get progressQuiet => 'Todavía no hay resultados';

  @override
  String get progressCostReported => 'Cargo indicado por el proveedor';

  @override
  String get progressCostNotional =>
      'Precio de lista teórico de la suscripción; no es una factura';

  @override
  String get progressCostMixed => 'Fuentes de costes combinadas';

  @override
  String get progressCostEstimated => 'Coste estimado';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'Modelo: $model · Tiempo: $duration · Coste: $cost';
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
    return 'Entrada: $input · Salida: $output tokens';
  }

  @override
  String get progressOutputPreviewLimited =>
      'Solo se muestran los primeros 6000 caracteres del resultado estructurado.';

  @override
  String progressRetryOf(String runId) {
    return 'Reintento de la ejecución $runId';
  }

  @override
  String get progressContext => 'Contexto y límites';

  @override
  String get progressNoAgent => 'No hay ningún agente que consultar';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window tokens';
  }

  @override
  String get progressMeasured =>
      'Contexto indicado por el proveedor en la última llamada';

  @override
  String get progressEstimated =>
      'Estimado a partir de la conversación guardada y el contexto persistente';

  @override
  String get progressContextUnknown =>
      'Todavía no se ha informado del uso del contexto';

  @override
  String progressContextPercent(String percent) {
    return '$percent % de la ventana de contexto';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'Límite mensual configurado para el agente: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'Conversación activa guardada: $tokens tokens estimados';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'Contexto persistente de $agent · $model';
  }

  @override
  String get progressContextSystem => 'Prompt del sistema';

  @override
  String get progressContextRules => 'Reglas';

  @override
  String get progressContextSkills => 'Habilidades';

  @override
  String get progressContextTools => 'Definiciones de herramientas';

  @override
  String get progressContextMcp => 'Herramientas MCP';

  @override
  String get progressContextDeferred => 'Herramientas diferidas';

  @override
  String get progressContextSubagents => 'Subagentes';

  @override
  String get progressContextRunner => 'Ejecutor externo';

  @override
  String get progressContextMemory => 'Memoria';

  @override
  String get progressContextHistory => 'Historial de conversación';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens tokens';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens tokens';
  }

  @override
  String get progressOutputs => 'Resultados recientes';

  @override
  String get progressNoOutputs => 'No hay resultados recientes del agente';

  @override
  String get progressStructuredOutputsAbove =>
      'Los resultados estructurados de las ejecuciones aparecen arriba, en las ejecuciones de agentes.';

  @override
  String get progressRecentOutputsOnly =>
      'Solo se muestran mensajes recientes. Abre la conversación para ver el trabajo anterior.';

  @override
  String get progressPlan => 'Plan';

  @override
  String get progressArtifact => 'Artefacto';

  @override
  String get progressResult => 'Resultado';

  @override
  String get progressHideArtifact => 'Ocultar artefacto';

  @override
  String get progressReadArtifact => 'Leer artefacto';

  @override
  String get progressArtifactUnavailable =>
      'El artefacto ya no está disponible';

  @override
  String get progressArtifactPreviewLimited =>
      'Se muestra una vista previa limitada de este artefacto.';

  @override
  String get progressDiagramSource => 'Código fuente del diagrama';

  @override
  String progressOpenAttachment(String name) {
    return 'Abrir $name';
  }

  @override
  String get progressOpenPlan => 'Abrir plan';

  @override
  String progressOpenDiff(String label) {
    return 'Revisar archivos modificados: $label';
  }

  @override
  String get progressViewMessage => 'Ver mensaje';

  @override
  String get pushTitle => 'Notificaciones en segundo plano';

  @override
  String get pushIntro =>
      'Recibe una alerta privada cuando algo requiera tu atención, incluso con la aplicación cerrada. Los detalles permanecen en tu conexión cifrada.';

  @override
  String get pushLoading => 'Comprobando ajustes de notificaciones…';

  @override
  String get pushError =>
      'No se pudieron actualizar las notificaciones. Comprueba tu conexión y vuelve a intentarlo.';

  @override
  String get pushEnable => 'Activar notificaciones';

  @override
  String get pushDisable => 'Desactivar notificaciones';

  @override
  String get pushQuiet => 'Pausar alertas en este dispositivo';

  @override
  String get pushCategories => 'Notificarme sobre';

  @override
  String get pushCategoryAgents => 'Agentes';

  @override
  String get pushCategoryMessages => 'Mensajes';

  @override
  String get pushCategoryPullRequests => 'Pull requests';

  @override
  String get pushCategoryTickets => 'Tickets';

  @override
  String get pushCategoryCalendar => 'Calendario';

  @override
  String get pushCategoryMachines => 'Máquinas';

  @override
  String get pushSecureOrigin => 'Las notificaciones requieren HTTPS.';

  @override
  String get pushInstallIos =>
      'En iPhone o iPad, añade esta aplicación a la pantalla de inicio y ábrela desde allí para activar las notificaciones.';

  @override
  String get pushUnsupported =>
      'Este navegador no admite notificaciones en segundo plano.';

  @override
  String get pushDenied =>
      'El navegador indica que las notificaciones están bloqueadas. Revisa los permisos de este sitio y los ajustes de notificaciones del navegador o del dispositivo; luego actualiza.';

  @override
  String get pushOsHint =>
      'Tu navegador también necesita permiso para mostrar notificaciones en los ajustes del sistema de tu dispositivo.';

  @override
  String get pushServiceUnavailable =>
      'El servicio push del navegador rechazó la suscripción. Algunos navegadores, como Brave, lo desactivan de forma predeterminada: busca una opción de mensajes push en los ajustes de privacidad del navegador y vuelve a intentarlo.';

  @override
  String get pushWorkerUnavailable =>
      'No se pudo iniciar el servicio de notificaciones en este navegador. Recarga la página y vuelve a intentarlo.';

  @override
  String get pushResubscribe => 'Reconectar notificaciones';

  @override
  String get pushStatusEnabled =>
      'Las notificaciones están activadas en este dispositivo.';

  @override
  String get pushStatusDisabled =>
      'Las notificaciones están desactivadas en este dispositivo.';

  @override
  String get credentialsTitle => 'Conexiones y credenciales';

  @override
  String get credentialsIntro =>
      'Conecta las cuentas que usan tus ejecuciones e integraciones. Los secretos se guardan en tu servidor, no en este teléfono.';

  @override
  String get credentialsModelProviders => 'Proveedores de modelos';

  @override
  String get credentialsOwnerOnly =>
      'Solo el propietario del servidor puede añadir, conectar o quitar credenciales de proveedores de modelos. Estas claves se comparten entre espacios de trabajo.';

  @override
  String get credentialsContactOwner =>
      'Pide al propietario del servidor que conecte el proveedor necesario para tu ejecución bloqueada.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude Code inicia sesión mediante la CLI en el host. Pide al propietario del servidor que complete o renueve el inicio de sesión en el terminal del host; no se puede hacer desde este teléfono.';

  @override
  String get credentialsYourForgeAccounts => 'Tus cuentas de repositorios';

  @override
  String get credentialsYourTicketingAccount => 'Tu cuenta de tickets';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'Los tickets locales no necesitan inicio de sesión. Conecta Linear aquí si tu espacio de trabajo lo utiliza.';

  @override
  String get credentialsMembershipRequired =>
      'Únete a un espacio de trabajo para gestionar tus credenciales de repositorios o tickets. Pide acceso a un administrador del espacio de trabajo.';

  @override
  String get credentialsSwitchWorkspace =>
      'Este enlace apunta a otro espacio de trabajo. Cambia a él antes de modificar las credenciales.';

  @override
  String get credentialsReturnToInbox =>
      'Vuelve a la bandeja de entrada para reintentar una ejecución bloqueada cuando conectes su credencial. El host también comprueba automáticamente las ejecuciones en espera.';

  @override
  String get credentialsLoadFailed =>
      'No se pudieron cargar las conexiones. Comprueba el enlace al servidor y vuelve a intentarlo.';

  @override
  String get credentialsOperationFailed =>
      'No se pudo modificar esta conexión. Comprueba el enlace al servidor, tus permisos y la credencial, y vuelve a intentarlo.';

  @override
  String get credentialsConnected => 'Conectado';

  @override
  String get credentialsNotConnected => 'No conectado';

  @override
  String credentialsSignedInAs(String username) {
    return 'Sesión iniciada como $username';
  }

  @override
  String get credentialsAccount => 'Cuenta conectada';

  @override
  String get credentialsStoredKey => 'Clave guardada';

  @override
  String get credentialsActive => 'Activo';

  @override
  String get credentialsRemove => 'Quitar';

  @override
  String get credentialsRemoveConfirm =>
      '¿Quitar tu credencial guardada? Puede que tengas que volver a iniciar sesión.';

  @override
  String get credentialsApiKey => 'Clave de API';

  @override
  String get credentialsApiKeyHint => 'Pega una clave de API del proveedor';

  @override
  String get credentialsBrowserLogin => 'Iniciar sesión en el navegador';

  @override
  String get credentialsSignInAgain => 'Vuelve a iniciar sesión';

  @override
  String get credentialsWaitingForLogin =>
      'Esperando autorización en tu navegador…';

  @override
  String get credentialsLoginTimedOut =>
      'El inicio de sesión ha caducado. Vuelve a iniciarlo.';

  @override
  String get credentialsCopyCode => 'Copiar código';

  @override
  String get credentialsDeviceCodeHint =>
      'Confirma este código en la página del proveedor. Mantén abierta esta pantalla mientras el servidor completa el inicio de sesión.';

  @override
  String get credentialsPasteRedirect =>
      'Código de autorización o URL de redirección';

  @override
  String get credentialsPasteRedirectHint =>
      'Pega el código o la URL de redirección completa del proveedor';

  @override
  String get credentialsCompleteLogin => 'Completar inicio de sesión';

  @override
  String get credentialsRedirectUnavailable =>
      'No se puede acceder de forma segura a la devolución de llamada del navegador de este servidor desde un teléfono. Pide al propietario que configure una devolución de llamada HTTPS pública o añade un token.';

  @override
  String get credentialsUpdateToken => 'Actualizar token';

  @override
  String get credentialsAddToken => 'Añadir token';

  @override
  String get credentialsPersonalToken => 'Token de acceso personal';

  @override
  String get credentialsPersonalTokenHint => 'Pega un token de acceso personal';

  @override
  String get credentialsHostManaged =>
      'Esta conexión procede de la aplicación del servidor o de su entorno. Solo el propietario del servidor puede cambiarla allí; tú puedes añadir tu propio token.';

  @override
  String get credentialsStopWatching => 'Dejar de esperar';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'La sesión de Claude Code ha caducado';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'La ejecución se detuvo porque su cuenta ya no se autentica. Vuelve a iniciar sesión y reintenta el turno.';

  @override
  String get transcriptSignInExpiredTitle =>
      'La sesión del proveedor ha caducado';

  @override
  String get transcriptSignInExpiredBody =>
      'La ejecución se detuvo porque la credencial de su proveedor ya no funciona. Vuelve a conectarlo en Ajustes → Proveedores y reintenta el turno.';
}

/// The translations for Spanish Castilian, as used in Mexico (`es_MX`).
class AppLocalizationsEsMx extends AppLocalizationsEs {
  AppLocalizationsEsMx() : super('es_MX');

  @override
  String get scanQrPrompt =>
      'Escanea el código QR de Control Center para emparejar este celular.';

  @override
  String get scanQrHelp =>
      'Abre la cámara y apunta al QR que aparece en Control Center. Este celular se conecta directamente por un enlace privado.';
}
