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
      'Escanea el código QR de tu Mac para emparejar este teléfono.';

  @override
  String get scanQrHelp =>
      'Abre la cámara y apunta al QR que aparece en Control Center en tu Mac. Este teléfono se conecta directamente a tu Mac por un enlace privado.';

  @override
  String get connectingToMac => 'Conectando a tu Mac…';

  @override
  String get connectingDetail => 'Estableciendo un enlace directo y seguro.';

  @override
  String get identityChangedTitle => 'La identidad del servidor ha cambiado';

  @override
  String get identityChangedBody =>
      'Este servidor ya no coincide con la identidad guardada al emparejar. Puede deberse a que se ha reinstalado, o a que algo intercepta la conexión. Por seguridad, este dispositivo no se conectará. Quita el emparejamiento y escanea un código QR nuevo de tu Mac para volver a emparejar.';

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
      'Sin emparejar: escanea el código QR de tu Mac';

  @override
  String get failureUnreachable =>
      'No se ha podido alcanzar el servidor por ninguna ruta: comprueba que esté en marcha o prueba en la misma red';

  @override
  String get failureIdentityChanged =>
      'La identidad del servidor ha cambiado: si se ha reinstalado, vuelve a emparejar este dispositivo';

  @override
  String get failureAuthRejected =>
      'El servidor ha rechazado este dispositivo: vuelve a emparejarlo desde tu Mac';

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
      'Toca de nuevo para desconectar este dispositivo de tu Mac';

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
}

/// The translations for Spanish Castilian, as used in Mexico (`es_MX`).
class AppLocalizationsEsMx extends AppLocalizationsEs {
  AppLocalizationsEsMx() : super('es_MX');

  @override
  String get scanQrPrompt =>
      'Escanea el código QR de tu Mac para emparejar este celular.';

  @override
  String get scanQrHelp =>
      'Abre la cámara y apunta al QR que aparece en Control Center en tu Mac. Este celular se conecta directamente a tu Mac por un enlace privado.';
}
