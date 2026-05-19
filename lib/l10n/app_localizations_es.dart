// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navCalendar => 'Calendario';

  @override
  String get calendarViewMonth => 'Mes';

  @override
  String get calendarViewWeek => 'Semana';

  @override
  String get calendarViewAgenda => 'Agenda';

  @override
  String get calendarConnectGoogle => 'Conectar Google Calendar';

  @override
  String get calendarConnectDescription =>
      'Sincroniza tu Google Calendar para ver los eventos aquí y recibir avisos antes de que empiecen las reuniones.';

  @override
  String get calendarDisconnect => 'Desconectar';

  @override
  String get calendarReconnect => 'Volver a conectar';

  @override
  String get calendarEmptyNoEvents => 'No hay eventos en este intervalo';

  @override
  String get calendarStartRecording => 'Empezar a grabar';

  @override
  String get calendarStartRecordingAndLink => 'Grabar y vincular';

  @override
  String get calendarJoinMeet => 'Unirse a la reunión';

  @override
  String get calendarFromCalendar => 'Desde el calendario';

  @override
  String get calendarLinkedMeeting => 'Reunión vinculada';

  @override
  String get calendarToday => 'Hoy';

  @override
  String get calendarAllDay => 'Todo el día';

  @override
  String calendarWeekNumber(int number) {
    return 'Semana $number';
  }

  @override
  String get calendarPreviousPeriod => 'Anterior';

  @override
  String get calendarNextPeriod => 'Siguiente';

  @override
  String calendarLastSynced(String time) {
    return 'Sincronizado $time';
  }

  @override
  String get calendarNeverSynced => 'Aún no sincronizado';

  @override
  String get calendarSyncing => 'Sincronizando…';

  @override
  String get calendarViewDay => 'Día';

  @override
  String get calendarSectionCalendars => 'Calendarios';

  @override
  String get calendarShow => 'Mostrar';

  @override
  String get calendarHide => 'Ocultar';

  @override
  String get calendarRsvpGoing => '¿Asistirás?';

  @override
  String get calendarRsvpYes => 'Sí';

  @override
  String get calendarRsvpNo => 'No';

  @override
  String get calendarRsvpMaybe => 'Quizás';

  @override
  String get calendarRsvpFailed => 'No se pudo actualizar tu respuesta';

  @override
  String get calendarAddAccount => 'Añadir cuenta de calendario';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Conecta una cuenta de Google para sincronizar los eventos en este espacio de trabajo.';

  @override
  String get calendarNotConnected => 'Ninguna cuenta de Google conectada';

  @override
  String get calendarConnecting => 'Conectando…';

  @override
  String get calendarSyncNow => 'Sincronizar ahora';

  @override
  String get calendarNoWorkspace =>
      'Selecciona un espacio de trabajo para ver su calendario';

  @override
  String get calendarConnectError => 'No se pudo conectar Google Calendar';

  @override
  String get notificationMeetingStartsSoon => 'Reunión a punto de empezar';

  @override
  String get notifyMeetingStartsSoon =>
      'Cuando una reunión del calendario está a punto de empezar';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Calendario desconectado';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Vuelve a conectar $email para reanudar la sincronización';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Vuelve a conectar tu calendario para reanudar la sincronización';

  @override
  String get notifyCalendarAuthExpired =>
      'Cuando una cuenta de calendario necesita volver a conectarse';

  @override
  String get calendarAlertLeadTime => 'Antelación del aviso';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'Cuánto tiempo antes de una reunión avisarte';

  @override
  String calendarConnectedAs(String email) {
    return 'Conectado como $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count asistentes';
  }

  @override
  String get calendarEventLabel => 'Evento';

  @override
  String get calendarRecurring => 'Evento recurrente';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Organizador';

  @override
  String get calendarYou => 'Tú';

  @override
  String get calendarShowFewer => 'Mostrar menos';

  @override
  String get calendarRsvpAwaiting => 'Pendiente';

  @override
  String calendarParticipantsCount(int count) {
    return '$count participantes';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'Ver los $count participantes';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count sí';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count no';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count quizás';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count pendientes';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count minutos';
  }

  @override
  String get openInEditorPrompt => '¿En qué editor abrir?';

  @override
  String get ideNotInstalled => 'No instalado';

  @override
  String openInIde(String editor) {
    return 'Abrir en $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'No se pudo abrir $editor: $error';
  }

  @override
  String get profileSearchHint => 'Buscar pull requests…';

  @override
  String get profileClickToLoad => 'Clic para cargar';

  @override
  String get profileStateOpenHint => 'Actualmente abiertas';

  @override
  String get profileStateMergedHint => 'Historial fusionado';

  @override
  String get profileStateClosedHint => 'Cerradas, no fusionadas';

  @override
  String get profileNoPrsForFilter =>
      'No hay pull requests para los estados seleccionados';

  @override
  String get byAuthorPrefix => 'por';

  @override
  String get youLabel => 'tú';

  @override
  String get readyToMerge => 'Listo para fusionar';

  @override
  String get laneReadyHint => 'Comprobaciones en verde';

  @override
  String get laneReviewHint => 'Esperándote';

  @override
  String get inProgress => 'En curso';

  @override
  String get laneInProgressHint => 'Abierto · en curso';

  @override
  String get needsAttention => 'Requiere atención';

  @override
  String get laneAttentionHint => 'Con fallos u obsoleto';

  @override
  String get drafts => 'Borradores';

  @override
  String get laneDraftsHint => 'Aún sin abrir';

  @override
  String get allOpenPrs => 'Todas las PR abiertas';

  @override
  String showAllCount(int count) {
    return 'Mostrar todas ($count)';
  }

  @override
  String get sortOldest => 'Más antiguas';

  @override
  String get sortLargest => 'Más grandes';

  @override
  String get selectAction => 'Seleccionar';

  @override
  String mergeCountReady(int count) {
    return 'Fusionar $count listas';
  }

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seleccionadas',
      one: '1 seleccionada',
    );
    return '$_temp0';
  }

  @override
  String get mergeReadyAction => 'Fusionar listas';

  @override
  String get nothingInLane => 'Nada en este carril';

  @override
  String get nothingInLaneHint =>
      'Elige otro carril arriba o muestra todas las PR abiertas.';

  @override
  String get summary => 'Resumen';

  @override
  String get openFullDiff => 'Abrir diff completo';

  @override
  String get viewFiles => 'Ver archivos';

  @override
  String get checksLabel => 'Comprobaciones';

  @override
  String get commentsLabel => 'Comentarios';

  @override
  String get mergeReadyConfirmTitle => '¿Fusionar las PR listas?';

  @override
  String mergeReadyConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Fusionar con squash $count PR listas? No se puede deshacer.',
      one: '¿Fusionar con squash 1 PR lista? No se puede deshacer.',
    );
    return '$_temp0';
  }

  @override
  String mergedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count PR fusionadas',
      one: '1 PR fusionada',
    );
    return '$_temp0';
  }

  @override
  String get keybindingSelectPr => 'Seleccionar PR';

  @override
  String get keybindingMergePr => 'Fusionar PR';

  @override
  String get keybindingPeekPr => 'Vista rápida de PR';

  @override
  String get keybindingToggleSelectionOfTheFocusedPullRequestDescription =>
      'Alternar la selección de la PR enfocada';

  @override
  String get keybindingMergeTheFocusedPullRequestDescription =>
      'Fusionar la PR enfocada si está lista';

  @override
  String get keybindingExpandOrCollapseTheFocusedPullRequestPeekDescription =>
      'Expandir o contraer el panel de vista rápida de la PR enfocada';

  @override
  String get kbMove => 'mover';

  @override
  String get kbSelect => 'seleccionar';

  @override
  String get kbMerge => 'fusionar';

  @override
  String get kbOpen => 'abrir';

  @override
  String get kbPeek => 'vista';

  @override
  String get kbTabs => 'pestañas';

  @override
  String get kbSearch => 'buscar';

  @override
  String get kbViewed => 'visto';

  @override
  String get kbCollapse => 'contraer';

  @override
  String get appearance => 'Apariencia';

  @override
  String get appearanceSettingsDescription => 'Tema, idioma y tipografía.';

  @override
  String get notificationsSettingsDescription =>
      'Elige qué eventos de agentes y espacios de trabajo te notifican.';

  @override
  String get integrationsSettingsDescription =>
      'Conecta GitHub, la gestión de tickets y el servidor MCP.';

  @override
  String get advanced => 'Avanzado';

  @override
  String get advancedSettingsDescription =>
      'Nomenclatura de ramas, voz, búsqueda semántica, privacidad y registro.';

  @override
  String get agentRegistry => 'Registro de agentes';

  @override
  String get settingsGroupGeneral => 'General';

  @override
  String get settingsGroupAgents => 'Agentes';

  @override
  String get settingsGroupResources => 'Recursos';

  @override
  String get filterSettingsHint => 'Filtrar ajustes';

  @override
  String get needsSetupLabel => 'Requiere configuración';

  @override
  String noSettingsMatch(String query) {
    return 'Ningún ajuste coincide con «$query»';
  }

  @override
  String get privacy => 'Privacidad';

  @override
  String get sendDiffContentTitle =>
      'Enviar el contenido del diff al adaptador de IA';

  @override
  String get diffSharingOnSubtitle =>
      'Las líneas de diff sin procesar se incluyen en las indicaciones de los agentes para una revisión más profunda.';

  @override
  String get diffSharingOffSubtitle =>
      'Los agentes solo usan metadatos estructurados (rutas de archivos, números de línea, descripción de la PR); ningún código sin procesar sale de la aplicación.';

  @override
  String get errorReportingTitle => 'Compartir informes de fallos';

  @override
  String get errorReportingOnSubtitle =>
      'Se envían diagnósticos de fallos, errores y rendimiento para ayudar a corregir errores (solo en versiones de producción).';

  @override
  String get errorReportingOffSubtitle =>
      'Los diagnósticos están desactivados. No se envía ningún informe de fallos ni de errores.';

  @override
  String get onboardingDiagnosticsTitle => 'Ayuda a mejorar Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Envía diagnósticos de fallos, errores y rendimiento para ayudarnos a solucionar problemas más rápido (solo en versiones de producción). Puedes cambiar esto en cualquier momento en Ajustes → Privacidad.';

  @override
  String get blocked => 'Bloqueado';

  @override
  String get idle => 'Inactivo';

  @override
  String get noRunsYet => 'Sin ejecuciones';

  @override
  String runsInLastSixMonths(String count) {
    return '$count ejecuciones en los últimos 6 meses';
  }

  @override
  String lastActiveAgo(String duration) {
    return 'Activo hace $duration';
  }

  @override
  String get reportsToNobody => 'Sin responsable';

  @override
  String get copyPath => 'Copiar ruta';

  @override
  String get pathCopied => 'Ruta copiada al portapapeles';

  @override
  String get editAgent => 'Editar agente';

  @override
  String get nameRequired => 'El nombre es obligatorio';

  @override
  String get titleRequired => 'El título es obligatorio';

  @override
  String get import => 'Importar';

  @override
  String discoverAgentsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count definiciones de agente encontradas',
      one: '1 definición de agente encontrada',
    );
    return '$_temp0';
  }

  @override
  String get noAgentsToDiscover => 'No hay nuevos agentes para importar';

  @override
  String get noAgentsToDiscoverHint =>
      'Las definiciones de agente de este espacio de trabajo ya están importadas.';

  @override
  String get sortByStatus => 'Estado';

  @override
  String get sortByName => 'Nombre';

  @override
  String get noMatchingAgents => 'Ningún agente coincide con tu filtro';

  @override
  String get selectAnAgentHint =>
      'Elige un agente para ver su estado, actividad y detalles.';

  @override
  String watchVideoOn(String provider) {
    return 'Ver vídeo en $provider';
  }

  @override
  String get branchTemplate => 'Plantilla de nombre de rama';

  @override
  String get branchTemplateDescription =>
      'Patrón de la rama creada al iniciar un ticket en un worktree aislado.';

  @override
  String branchTemplatePreview(String example) {
    return 'Ejemplo: $example';
  }

  @override
  String get deletePipelineRun => 'Eliminar ejecución del pipeline';

  @override
  String deletePipelineRunConfirm(String template) {
    return '¿Eliminar esta ejecución de «$template»? Esta acción no se puede deshacer.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Error al eliminar la ejecución del pipeline: $error';
  }

  @override
  String get deleteTicket => 'Eliminar ticket';

  @override
  String deleteTicketConfirm(String title) {
    return '¿Eliminar «$title»? Esta acción no se puede deshacer.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Error al eliminar el ticket: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return '¿Eliminar «$name»? Los repositorios vinculados en el disco no se modifican.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Error al eliminar el espacio de trabajo: $error';
  }

  @override
  String get indexCode => 'Indexar código';

  @override
  String get indexing => 'Indexando…';

  @override
  String get indexNoGrammars => 'Gramáticas de código no instaladas';

  @override
  String get indexFailed => 'Error de indexación';

  @override
  String indexedSymbolsCount(int count) {
    return '$count símbolos indexados';
  }

  @override
  String get nodeConfigAdvanced => 'Avanzado';

  @override
  String get nodeConfigReducer => 'Reductor';

  @override
  String get nodeConfigReducerHelp =>
      'Cómo fusionar cuando esta clave de salida ya tiene un valor';

  @override
  String get nodeConfigTimeoutMs => 'Tiempo de espera (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Reintentos';

  @override
  String get nodeConfigContinueOnFail => 'Continuar si este paso falla';

  @override
  String get nodeConfigTeamId => 'ID de equipo';

  @override
  String get nodeConfigDispatchMode => 'Modo de despacho';

  @override
  String get nodeConfigOutputSchema => 'Esquema de salida (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'Esquema JSON que debe cumplir la salida del paso';

  @override
  String get diffLineDisplay => 'Líneas largas en los diffs';

  @override
  String get diffLineDisplayDescription =>
      'Ajustar las líneas largas o desplazarlas horizontalmente';

  @override
  String get diffLineWrap => 'Ajustar';

  @override
  String get diffLineScroll => 'Desplazar horizontalmente';

  @override
  String get actions => 'Acciones';

  @override
  String get activate => 'Activar';

  @override
  String get activity => 'Actividad';

  @override
  String get activityLabel => 'ACTIVIDAD';

  @override
  String adRulesCount(int count) {
    return '$count reglas de anuncios';
  }

  @override
  String get adapter => 'Adaptador';

  @override
  String get adapterLabel => 'Adaptador';

  @override
  String get adapters => 'Adaptadores';

  @override
  String get adaptersAutoDetected =>
      'Ejecutores de agentes detectados automáticamente disponibles en esta máquina. Instala las herramientas CLI que falten para habilitar ejecutores adicionales.';

  @override
  String get add => 'Añadir';

  @override
  String get addAComment => 'Añadir un comentario';

  @override
  String get addAReaction => 'Añadir una reacción';

  @override
  String get addASuggestion => 'Añadir una sugerencia';

  @override
  String get addAgent => 'Añadir agente';

  @override
  String get addAgents => 'Añadir agentes';

  @override
  String get addAgentsToEnable =>
      'Añade agentes para activar la orquestación multi-agente';

  @override
  String get addEmoji => 'Añadir emoji';

  @override
  String get addFeed => 'Añadir fuente';

  @override
  String get addFromFile => 'Añadir desde archivo';

  @override
  String get addGif => 'Añadir GIF';

  @override
  String get addGithubRepoPrompt =>
      'Añade al menos un repositorio de GitHub para ver pull requests';

  @override
  String get addLocalCheckoutDescription =>
      'Añade un checkout local para empezar a dirigirlo desde este espacio de trabajo.';

  @override
  String get addRepository => 'Añadir repositorio';

  @override
  String get addToken => 'Añadir token';

  @override
  String get addWorkspace => 'Añadir espacio de trabajo';

  @override
  String get addWorkspaceEllipsis => 'Añadir espacio de trabajo…';

  @override
  String get added => 'Añadido';

  @override
  String get addingEllipsis => 'Añadiendo...';

  @override
  String get advancedLabel => 'Avanzado';

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
  String get agentMdPath => 'Ruta MD del agente';

  @override
  String get agentName => 'Nombre del agente';

  @override
  String get agentTitle => 'Título del agente';

  @override
  String get agentUpdated => 'Agente actualizado.';

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
  String get aiReview => 'Revisión IA';

  @override
  String get all => 'Todo';

  @override
  String get allAgentsAlreadyInChannel =>
      'Todos los agentes ya están en este canal.';

  @override
  String allAgentsCount(int count) {
    return 'Todos los agentes · $count';
  }

  @override
  String get allCommits => 'Todos los commits';

  @override
  String get allSessionsReset => 'Todas las sesiones de sandbox restablecidas.';

  @override
  String get allSources => 'Todas las fuentes';

  @override
  String get allStarBadge => 'All-Star';

  @override
  String get allTimeLabel => 'Todo';

  @override
  String get allow => 'Permitir';

  @override
  String get allowGitPush => 'Permitir git push';

  @override
  String get allowGithubApi => 'Permitir llamadas a la API de GitHub';

  @override
  String get allowNetwork => 'Permitir acceso general a la red';

  @override
  String get apiKeys => 'Claves API';

  @override
  String get appFont => 'Fuente de la app';

  @override
  String get appLogLevelDebugDescription =>
      'Añade trazas detalladas - para desarrollo.';

  @override
  String get appLogLevelDebugLabel => 'Depuración';

  @override
  String get appLogLevelErrorDescription =>
      'Solo errores y excepciones inesperadas.';

  @override
  String get appLogLevelErrorLabel => 'Error';

  @override
  String get appLogLevelInfoDescription =>
      'Añade mensajes de ciclo de vida y estado.';

  @override
  String get appLogLevelInfoLabel => 'Información';

  @override
  String get appLogLevelNoneDescription => 'Sin salida de consola.';

  @override
  String get appLogLevelNoneLabel => 'Ninguno';

  @override
  String get appLogLevelVerboseDescription =>
      'Todo. Extremadamente verboso - usar solo para depuración.';

  @override
  String get appLogLevelVerboseLabel => 'Verboso';

  @override
  String get appLogLevelWarningDescription =>
      'Añade advertencias y problemas recuperables.';

  @override
  String get appLogLevelWarningLabel => 'Advertencia';

  @override
  String get appTitle => 'Control Center';

  @override
  String get appearanceLanguage => 'Apariencia e idioma';

  @override
  String get apply => 'Aplicar';

  @override
  String get approve => 'Aprobar';

  @override
  String get approveAndCompact => 'Aprobar y compactar contexto';

  @override
  String get approveAndExecute => 'Aprobar y ejecutar';

  @override
  String get approveAndHire => 'Aprobar y contratar';

  @override
  String get approved => 'Aprobado';

  @override
  String get articlesSubscribed => 'Artículos de tus fuentes suscritas.';

  @override
  String get askAi => 'Ask AI';

  @override
  String get askAiReview => 'Solicitar revisión IA';

  @override
  String get askAiReviewDescription => 'Pedir a la IA que revise esta PR';

  @override
  String get askAnything =>
      'Pregunta lo que quieras… (@ para mencionar agentes, / para comandos)';

  @override
  String get assignees => 'ASIGNADOS';

  @override
  String get attachFiles => 'Adjuntar archivos';

  @override
  String get attachImage => 'Adjuntar imagen';

  @override
  String get attachedAgents => 'Agentes adjuntos';

  @override
  String get audioInput => 'Entrada de audio';

  @override
  String get authentication => 'Autenticación';

  @override
  String get authenticationToken => 'Token de autenticación';

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
  String get autoRecommended => 'Auto (recomendado)';

  @override
  String get available => 'Disponible';

  @override
  String get avgDuration => 'Duración media';

  @override
  String get awaitingYourApproval => 'Esperando tu aprobación';

  @override
  String get awaitingYourReview => 'Esperando tu revisión';

  @override
  String get back => 'Atrás';

  @override
  String get backLabel => 'Atrás';

  @override
  String get backend => 'Backend';

  @override
  String get blockAdsDescription =>
      'Bloquear anuncios, rastreadores y banners de cookies';

  @override
  String get blockAdsTrackers =>
      'Bloquear anuncios, rastreadores y banners de cookies';

  @override
  String get blocking => 'Bloqueando';

  @override
  String get blockingLabel => 'Bloqueando';

  @override
  String get bookmarkLabel => 'Marcador';

  @override
  String get briefDescription => 'Descripción breve';

  @override
  String get bugLabel => 'BUG';

  @override
  String get bundledDefaultsNeverUpdated =>
      'Predefinidos incluidos - nunca actualizados';

  @override
  String get cached => 'En caché';

  @override
  String get cancel => 'Cancelar';

  @override
  String get cancelEdit => 'Cancelar edición';

  @override
  String get categoryCreation => 'Creación';

  @override
  String get categoryDeletion => 'Eliminación';

  @override
  String get categoryEditing => 'Edición';

  @override
  String get categoryNavigation => 'Navegación';

  @override
  String get categorySystem => 'Sistema';

  @override
  String get categoryView => 'Vista';

  @override
  String get centurionBadge => 'Centurión';

  @override
  String get change => 'Cambiar';

  @override
  String get changesRequested => 'Cambios solicitados';

  @override
  String get changesSummary => 'Resumen de cambios';

  @override
  String get channelsMentionSection => 'Canales';

  @override
  String get checkForUpdates => 'Buscar actualizaciones';

  @override
  String get checking => 'Comprobando';

  @override
  String get checkingEllipsis => 'Comprobando…';

  @override
  String get checkingGhCli => 'Comprobando gh CLI…';

  @override
  String get chooseAppFont => 'Elige la fuente de la app';

  @override
  String get chooseCodeFont => 'Elige la fuente de código';

  @override
  String get chooseRunner => 'Elige tu ejecutor de agentes.';

  @override
  String get clear => 'Limpiar';

  @override
  String get clickToRetry => 'Haz clic para reintentar';

  @override
  String get close => 'Cerrar';

  @override
  String get closeEsc => 'Cerrar (Esc)';

  @override
  String get closeKeyboardHint => 'Cerrar atajos de teclado';

  @override
  String get closePanel => 'Cerrar panel';

  @override
  String get closeReader => 'Cerrar lector';

  @override
  String get closeThread => 'Cerrar hilo';

  @override
  String get closed => 'Cerrado';

  @override
  String get codeFont => 'Fuente de código';

  @override
  String get collapse => 'Colapsar';

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
  String get comment => 'Comentario';

  @override
  String get commentOnFile => 'Comentar este archivo';

  @override
  String get commentOnThisFile => 'Comentar este archivo';

  @override
  String get commentSelected => 'Comentar selección';

  @override
  String get commented => 'Comentado';

  @override
  String get commits => 'Commits';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Mostrando los últimos $loaded de $total commits';
  }

  @override
  String get prCloneProgressCloningTitle => 'Clonando repositorio';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'Esta PR modifica $fileCount archivos, superando el límite de la API de GitHub. Clonando el repositorio localmente…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'Esta PR supera el límite de archivos de la API de GitHub. Clonando el repositorio localmente…';

  @override
  String get prCloneProgressFetchingTitle => 'Obteniendo refs';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Obteniendo la rama base y la ref de la PR…';

  @override
  String get prCloneProgressComputingTitle => 'Calculando diff';

  @override
  String get prCloneProgressComputingSubtitle =>
      'Ejecutando git diff localmente…';

  @override
  String get prCloneProgressErrorTitle => 'Error al cargar el diff';

  @override
  String get prCloneProgressErrorSubtitle =>
      'Se produjo un error al clonar o calcular el diff.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Trabajando aún… $elapsed transcurridos';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Confianza: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'Configura identidades de agentes, prompts, habilidades y ve ejecuciones.';

  @override
  String get configureDefaultRunners =>
      'Configura qué adaptador y modelo se usan para las conversaciones nuevas y la generación de títulos.';

  @override
  String get configuredLabel => 'Configurado.';

  @override
  String get confirmedBy => 'Confirmado por';

  @override
  String get consensus => 'Consenso';

  @override
  String get contentBlockingDescription =>
      'Bloquear anuncios, rastreadores y banners de cookies';

  @override
  String get contentHint => 'Lo que debe recordarse';

  @override
  String get contentLabel => 'Contenido';

  @override
  String get contentMarkdown => 'Contenido (Markdown)';

  @override
  String get contextWindowSize => 'Tamaño de la ventana de contexto';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get conversationMode => 'Modo de conversación';

  @override
  String get convertToGroup => '¿Convertir en grupo?';

  @override
  String get convertToGroupBody =>
      'Añadir otro agente convierte esta conversación en una conversación de grupo.';

  @override
  String cookieRulesCount(int count) {
    return '$count reglas de cookies';
  }

  @override
  String get copied => '¡Copiado!';

  @override
  String get copy => 'Copiar';

  @override
  String get copyBaseBranchTooltip => 'Copiar el nombre de la rama de destino';

  @override
  String get copyHeadBranchTooltip => 'Copiar el nombre de la rama de origen';

  @override
  String get couldNotCheckGhCli => 'No se pudo comprobar gh CLI.';

  @override
  String couldNotListDevices(String error) {
    return 'No se pudieron listar los dispositivos: $error';
  }

  @override
  String get create => 'Crear';

  @override
  String get createFirstAgent => 'Crea tu primer agente para empezar.';

  @override
  String get createOrSelectWorkspace =>
      'Crea o selecciona un espacio de trabajo antes de añadir repositorios.';

  @override
  String get createPr => 'Crear PR';

  @override
  String get createPullRequest => 'Crear pull request';

  @override
  String get createdByMe => 'Creadas por mí';

  @override
  String createdLabel(String date) {
    return 'Creado: $date';
  }

  @override
  String get currentParticipants => 'Participantes actuales';

  @override
  String get customCapabilitiesDescription =>
      'Capacidades personalizadas para este agente';

  @override
  String get customSystemPrompt =>
      'Prompt del sistema personalizado para este agente...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Desactivar';

  @override
  String get defaultCapabilities =>
      'Capacidades predeterminadas · conversaciones nuevas';

  @override
  String get defaultChat => 'Chat predeterminado';

  @override
  String defaultPort(int port) {
    return 'Predeterminado: $port.';
  }

  @override
  String defaultPortHint(int port) {
    return 'Predeterminado: $port.';
  }

  @override
  String get defaultRunners => 'Ejecutores predeterminados';

  @override
  String get delete => 'Eliminar';

  @override
  String get deleteAgent => 'Eliminar agente';

  @override
  String deleteAgentConfirm(String name) {
    return '¿Eliminar \"$name\"? Esta acción no se puede deshacer.';
  }

  @override
  String get deleteChannel => 'Eliminar canal';

  @override
  String deleteConfirmName(String name) {
    return '¿Eliminar \"$name\"?';
  }

  @override
  String get deleteConversation => 'Eliminar conversación';

  @override
  String get deleteConversationConfirm =>
      '¿Eliminar esta conversación? Se perderán todos los mensajes.';

  @override
  String get deleteFact => 'Eliminar hecho';

  @override
  String get deleteFeedBody =>
      'Esto elimina la fuente y todos sus artículos en caché. Los artículos marcados de esta fuente también se eliminarán.';

  @override
  String deleteFeedConfirm(String name) {
    return '¿Eliminar \"$name\"?';
  }

  @override
  String deleteNamedConversation(String name) {
    return '¿Eliminar \"$name\"? Se perderán todos los mensajes.';
  }

  @override
  String get deletePolicy => 'Eliminar política';

  @override
  String get deletePolicyConfirm =>
      '¿Eliminar esta política? Esta acción no se puede deshacer.';

  @override
  String deleteTopicConfirm(String topic) {
    return '¿Eliminar \"$topic\"? Esta acción no se puede deshacer.';
  }

  @override
  String get deleteWorkspace => 'Eliminar espacio de trabajo';

  @override
  String get deny => 'Denegar';

  @override
  String get descriptionLabel => 'Descripción';

  @override
  String get detailsLabel => 'Detalles';

  @override
  String detectedBackend(String label) {
    return 'Detectado: $label';
  }

  @override
  String detectedRunners(int count) {
    return 'Ejecutores detectados ($count)';
  }

  @override
  String get detectingAdapters => 'Detectando adaptadores…';

  @override
  String get detectingGhCli => 'Detectando gh CLI…';

  @override
  String get detectingInputDevices => 'Detectando dispositivos de entrada…';

  @override
  String detectionFailed(String error) {
    return 'Error de detección: $error';
  }

  @override
  String diffFailed(String message) {
    return 'Error en diff: $message';
  }

  @override
  String get diffWorkerPool => 'Pool de workers';

  @override
  String get directMessage => 'Mensaje directo';

  @override
  String get directMessages => 'Mensajes directos';

  @override
  String get disabled => 'Desactivado';

  @override
  String get discover => 'Descubrir';

  @override
  String get discoverAgents => 'Descubrir agentes';

  @override
  String get discoverAgentsDescription =>
      'El descubrimiento de agentes busca archivos AGENTS.md y TEAM.md en las rutas del espacio de trabajo, analizándolos en el registro de agentes.\n\nConfigura primero un espacio de trabajo y luego usa esta función para poblar agentes automáticamente.';

  @override
  String get dismissed => 'Descartado';

  @override
  String get domainHint => 'ej: api-performance';

  @override
  String get domainLabel => 'Dominio';

  @override
  String get download => 'Descargar';

  @override
  String get downloadingLabel => 'Descargando';

  @override
  String downloadingModel(int pct) {
    return 'Descargando modelo… $pct%';
  }

  @override
  String get draft => 'Borrador';

  @override
  String get draftLabel => 'Borrador';

  @override
  String get earnTiersDescription => 'Gana niveles al usar el Control Center';

  @override
  String get edit => 'Editar';

  @override
  String get editFact => 'Editar hecho';

  @override
  String get editPolicy => 'Editar política';

  @override
  String get editSuggestedCodeHint => 'Editar código sugerido...';

  @override
  String get editSuggestion => 'Editar sugerencia';

  @override
  String get editTheSuggestedCodeHint => 'Editar el código sugerido...';

  @override
  String get egArchitect => 'ej. arquitecto';

  @override
  String get egControlCenter => 'ej: control-center';

  @override
  String get egPlatform => 'ej: macOS';

  @override
  String get egSamuelAlev => 'ej: SamuelAlev';

  @override
  String get egSoftwareArchitect => 'ej. Arquitecto de Software';

  @override
  String get egTheVerge => 'ej. The Verge';

  @override
  String get egTokenLimit => 'ej: 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Error de instalación: $error';
  }

  @override
  String get embeddingInstalled =>
      'Modelo de embeddings local instalado. La búsqueda híbrida está activada.';

  @override
  String get embeddingModel => 'Modelo de embeddings (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'No instalado. La búsqueda recurre solo a palabras clave hasta que se active.';

  @override
  String get embeddingRedownloadBody =>
      'Los archivos del modelo existente se eliminarán y se descargarán de nuevo. La búsqueda semántica no estará disponible hasta que se complete la descarga.';

  @override
  String get embeddingRemoveBody =>
      'La búsqueda semántica se desactivará hasta que la vuelvas a instalar. Puedes instalarla de nuevo en cualquier momento.';

  @override
  String get speakerDiarization => 'Diarización de hablantes';

  @override
  String get diarizationModel => 'Modelo de diarización';

  @override
  String get diarizationInstalled =>
      'Instalado — nombra a cada hablante en las transcripciones de reuniones';

  @override
  String get diarizationNotInstalled =>
      'No instalado — los hablantes de las reuniones no se separarán';

  @override
  String diarizationInstallFailed(String error) {
    return 'Error de instalación: $error';
  }

  @override
  String get redownloadDiarizationModel =>
      'Volver a descargar el modelo de diarización';

  @override
  String get diarizationRedownloadBody =>
      'Esto elimina los modelos de diarización actuales y los descarga de nuevo.';

  @override
  String get removeDiarizationModel => 'Eliminar el modelo de diarización';

  @override
  String get diarizationRemoveBody =>
      'Esto elimina los modelos de diarización del dispositivo. Las transcripciones de reuniones ya producidas no se ven afectadas.';

  @override
  String get onboardingDiarizationTitle =>
      'Diarización de hablantes (opcional)';

  @override
  String get onboardingDiarizationSubtitle =>
      'Descárgalo para etiquetar a cada hablante (Persona 1, Persona 2…) en las notas de reunión. Puedes añadirlo más tarde en los ajustes.';

  @override
  String get enableMcpServer => 'Activar servidor MCP';

  @override
  String get enableNotifications => 'Activar notificaciones';

  @override
  String get enableSandboxing => 'Activar sandboxing';

  @override
  String get enabled => 'Activado';

  @override
  String enterToken(String name) {
    return 'Introduce el token de $name';
  }

  @override
  String get enterTokenToAuth =>
      'Introduce un token para requerir autenticación';

  @override
  String errorCreatingAgent(String error) {
    return 'Error al crear el agente: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Error al eliminar el agente: $error';
  }

  @override
  String get errorLoadingAgents => 'Error al cargar agentes';

  @override
  String errorWithDetail(String error) {
    return 'Error: $error';
  }

  @override
  String get errored => 'Con errores';

  @override
  String get erroredLabel => 'Con errores';

  @override
  String get exitSelection => 'Salir de la selección';

  @override
  String get expand => 'Expandir';

  @override
  String get extractingLabel => 'Extrayendo';

  @override
  String extractingModel(int pct) {
    return 'Extrayendo modelo… $pct%';
  }

  @override
  String get fact => 'Hecho';

  @override
  String factCount(int count) {
    return '$count hecho';
  }

  @override
  String factCountPlural(int count) {
    return '$count hechos';
  }

  @override
  String get facts => 'Hechos';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount hechos · $policyCount políticas';
  }

  @override
  String get failed => 'Fallido';

  @override
  String failedToDispatch(String error) {
    return 'Error al enviar: $error';
  }

  @override
  String get failedToLoad => 'Error al cargar';

  @override
  String failedToLoadAgents(String error) {
    return 'Error al cargar los agentes: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Error al cargar las fuentes: $error';
  }

  @override
  String get failedToLoadGifs => 'Error al cargar GIFs';

  @override
  String failedToLoadLogs(String error) {
    return 'Error al cargar los registros: $error';
  }

  @override
  String get failedToLoadRepos => 'Error al cargar los repositorios';

  @override
  String get failedToLoadWorkspaces =>
      'Error al cargar los espacios de trabajo';

  @override
  String failedToStartAiReview(String error) {
    return 'Error al iniciar la revisión IA: $error';
  }

  @override
  String get failedToStartMicTest =>
      'Error al iniciar la prueba del micrófono.';

  @override
  String failedToSubmitReview(String error) {
    return 'Error al enviar la revisión: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'Error al subir $name: $error';
  }

  @override
  String failedWithError(String error) {
    return 'Error: $error';
  }

  @override
  String get failure => 'Fallo';

  @override
  String get feedAlreadyExists => 'Ya existe una fuente con esta URL.';

  @override
  String get feedUrl => 'URL de la fuente';

  @override
  String get feedUrlExample => 'ej: https://example.com/feed.xml';

  @override
  String get feedUrlExists => 'Ya existe una fuente con esta URL.';

  @override
  String get feedUrlLabel => 'URL de la fuente';

  @override
  String feedsCount(int count) {
    return 'Fuentes ($count)';
  }

  @override
  String get feedsLabel => 'Fuentes';

  @override
  String get filesChanged => 'Archivos modificados';

  @override
  String filesCount(int count) {
    return '$count archivo(s)';
  }

  @override
  String get filesMentionSection => 'Archivos';

  @override
  String get filterAgents => 'Filtrar agentes...';

  @override
  String get filterAgentsPlaceholder => 'Filtrar agentes…';

  @override
  String get filterFilesHint => 'Filtrar archivos...';

  @override
  String get filterLists => 'Listas de filtros';

  @override
  String get filterSkillsPlaceholder => 'Filtrar habilidades…';

  @override
  String get finish => 'Finalizar';

  @override
  String get firstReviewBadge => 'Primera revisión';

  @override
  String get fix => 'Corregir';

  @override
  String get fixSelected => 'Corregir selección';

  @override
  String get flawlessBadge => 'Impecable';

  @override
  String get forks => 'Forks';

  @override
  String get forward => 'Reenviar';

  @override
  String get gatesGithubPatPush =>
      'Controla la inyección del PAT de GitHub. Necesario para que el agente pueda hacer push.';

  @override
  String get general => 'General';

  @override
  String get generalSettingsDescription =>
      'Apariencia, tipografía, integraciones y servidor MCP.';

  @override
  String get ghCliAuthButPatOverrideBody =>
      'GitHub CLI está autenticado y listo, pero un token de acceso personal está definido abajo y se usará en su lugar. Borra el PAT para usar la autenticación gh CLI.';

  @override
  String get ghCliInstalledAuth =>
      'Instalado. Ejecuta `gh auth login` y luego pulsa Actualizar.';

  @override
  String get ghCliNotInstalled =>
      'gh CLI no instalado — instálalo desde cli.github.com.';

  @override
  String get ghCliNotInstalledLabel => 'gh CLI no instalado';

  @override
  String get githubCli => 'GitHub CLI';

  @override
  String get githubCliIntegration => 'Integración con GitHub CLI';

  @override
  String get githubCliReady => 'GitHub CLI está autenticado y listo.';

  @override
  String get githubLink => 'Enlace de GitHub';

  @override
  String get githubPersonalAccessToken => 'Token de acceso personal de GitHub';

  @override
  String get githubStatusAllOperational => 'Todos los sistemas operativos';

  @override
  String get githubStatusComponents => 'Componentes';

  @override
  String get githubStatusFetchFailed =>
      'No se pudo contactar con githubstatus.com';

  @override
  String get githubStatusIncidents => 'Incidentes activos';

  @override
  String get githubStatusOpenInBrowser => 'Abrir githubstatus.com';

  @override
  String get githubStatusRefresh => 'Actualizar';

  @override
  String get githubStatusTitle => 'Estado de GitHub';

  @override
  String githubStatusUpdated(String time) {
    return 'Actualizado $time';
  }

  @override
  String lastChecked(String time) {
    return 'Comprobado $time';
  }

  @override
  String get lastCheckedRecently => 'Comprobado hace poco';

  @override
  String get githubToken => 'Token de GitHub';

  @override
  String get giveAgentsAMemory => 'Dales memoria a los agentes.';

  @override
  String get giveYourWorkAHome => 'Dale un hogar a tu trabajo.';

  @override
  String get goBack => 'Volver';

  @override
  String get goForward => 'Avanzar';

  @override
  String get googleFonts => 'Google Fonts';

  @override
  String get groupLabel => 'Grupo';

  @override
  String get groupName => 'Nombre del grupo';

  @override
  String get groups => 'Grupos';

  @override
  String get hideContainerTerminal => 'Ocultar terminal del contenedor';

  @override
  String get high => 'Alto';

  @override
  String get hotStreakBadge => 'Racha caliente';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count horas',
      one: 'hace 1 hora',
    );
    return '$_temp0';
  }

  @override
  String get idleStatus => 'Inactivo';

  @override
  String get images => 'Imágenes';

  @override
  String get inFlightLabel => 'En progreso';

  @override
  String get inactive => 'Inactivo';

  @override
  String get install => 'Instalar';

  @override
  String get installGhCliBody =>
      'Instala gh desde https://cli.github.com/ y ejecuta `gh auth login`, luego pulsa Actualizar.';

  @override
  String get installRequired => 'Instalación necesaria';

  @override
  String get installedNotSignedIn => 'Instalado - no autenticado';

  @override
  String installedVersion(String version) {
    return 'Instalado $version';
  }

  @override
  String get integrations => 'Integraciones';

  @override
  String get invite => 'Invitar';

  @override
  String get inviteAgent => 'Invitar agente';

  @override
  String get isolateAgentExecution => 'Aísla la ejecución de agentes.';

  @override
  String jobCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count tarea$_temp0';
  }

  @override
  String get justNow => 'ahora mismo';

  @override
  String get keepMessages => 'Conservar mensajes';

  @override
  String get keepSandboxing => 'Mantener sandboxing';

  @override
  String get keybindingAdapters => 'Adaptadores';

  @override
  String get keybindingAddARepositoryDescription => 'Añadir un repositorio';

  @override
  String get keybindingAddRepository => 'Añadir repositorio';

  @override
  String get keybindingAgents => 'Agentes';

  @override
  String get keybindingApprove => 'Aprobar';

  @override
  String get keybindingApproveThePeerReviewDescription =>
      'Aprobar la revisión por pares';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Marcar o desmarcar el artículo seleccionado';

  @override
  String get keybindingCommandPalette => 'Paleta de comandos';

  @override
  String get keybindingConversationTab => 'Pestaña conversación';

  @override
  String get keybindingCreateANewAgentDescription => 'Crear un nuevo agente';

  @override
  String get keybindingCreateANewGroupChannelDescription =>
      'Crear un nuevo canal de grupo';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Crear un nuevo espacio de trabajo';

  @override
  String get keybindingDeleteAgent => 'Eliminar agente';

  @override
  String get keybindingDeleteChannel => 'Eliminar canal';

  @override
  String get keybindingDeleteTheSelectedAgentDescription =>
      'Eliminar el agente seleccionado';

  @override
  String get keybindingDeleteTheSelectedChannelDescription =>
      'Eliminar el canal seleccionado';

  @override
  String get keybindingDeleteTheSelectedWorkspaceDescription =>
      'Eliminar el espacio de trabajo seleccionado';

  @override
  String get keybindingDeleteWorkspace => 'Eliminar espacio de trabajo';

  @override
  String get keybindingFilesChangedTab => 'Pestaña archivos modificados';

  @override
  String get keybindingFocusSearch => 'Enfocar búsqueda';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Enfocar el campo de búsqueda de pull requests';

  @override
  String get keybindingGeneral => 'General';

  @override
  String get keybindingGoToAgents => 'Ir a agentes';

  @override
  String get keybindingGoToAnalytics => 'Ir a análisis';

  @override
  String get keybindingGoToDashboard => 'Ir al panel';

  @override
  String get keybindingGoToMemory => 'Ir a memoria';

  @override
  String get keybindingGoToNewsfeed => 'Ir a noticias';

  @override
  String get keybindingGoToPipelines => 'Ir a pipelines';

  @override
  String get keybindingGoToPullRequests => 'Ir a pull requests';

  @override
  String get keybindingGoToTickets => 'Ir a tickets';

  @override
  String get keybindingKeybindings => 'Atajos';

  @override
  String get keybindingNavigateToTheAgentsRegistryDescription =>
      'Navegar al registro de agentes';

  @override
  String get keybindingNavigateToTheAnalyticsDashboardDescription =>
      'Navegar al panel de análisis';

  @override
  String get keybindingNavigateToTheGlobalDashboardDescription =>
      'Navegar al panel global';

  @override
  String get keybindingNavigateToTheMemoryDescription =>
      'Ir a la base de conocimiento de memoria';

  @override
  String get keybindingNavigateToTheNewsfeedDescription =>
      'Navegar al feed de noticias';

  @override
  String get keybindingNavigateToThePipelinesListDescription =>
      'Ir a la lista de pipelines';

  @override
  String get keybindingNavigateToThePullRequestListDescription =>
      'Navegar a la lista de pull requests';

  @override
  String get keybindingNavigateToTheTicketsBoardDescription =>
      'Ir al tablero de tickets';

  @override
  String get keybindingNewAgent => 'Nuevo agente';

  @override
  String get keybindingNewDirectMessage => 'Nuevo mensaje directo';

  @override
  String get keybindingNewGroup => 'Nuevo grupo';

  @override
  String get keybindingNewWorkspace => 'Nuevo espacio de trabajo';

  @override
  String get keybindingNextArticle => 'Artículo siguiente';

  @override
  String get keybindingNextChannel => 'Canal siguiente';

  @override
  String get keybindingNextPr => 'PR siguiente';

  @override
  String get keybindingNextWorkspace => 'Espacio de trabajo siguiente';

  @override
  String get keybindingOpenArticle => 'Abrir artículo';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Abrir o cerrar el popup del selector de espacio en la barra lateral';

  @override
  String get keybindingOpenPr => 'Abrir PR';

  @override
  String get keybindingOpenSettings => 'Abrir ajustes';

  @override
  String get keybindingOpenTheAdaptersSettingsPageDescription =>
      'Abrir la página de ajustes de adaptadores';

  @override
  String get keybindingOpenTheAgentsSettingsPageDescription =>
      'Abrir la página de ajustes de agentes';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Abrir los ajustes de la aplicación';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Abrir la paleta de comandos';

  @override
  String get keybindingOpenTheGeneralSettingsPageDescription =>
      'Abrir la página de ajustes generales';

  @override
  String get keybindingOpenTheKeybindingsSettingsPageDescription =>
      'Abrir la página de ajustes de atajos';

  @override
  String get keybindingOpenTheRepositoriesSettingsPageDescription =>
      'Abrir la página de ajustes de repositorios';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Abrir el artículo seleccionado';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Abrir la pull request seleccionada';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Abrir el espacio de trabajo seleccionado';

  @override
  String get keybindingOpenTheSkillsSettingsPageDescription =>
      'Abrir la página de ajustes de habilidades';

  @override
  String get keybindingOpenWorkspace => 'Abrir espacio de trabajo';

  @override
  String get keybindingPreviousArticle => 'Artículo anterior';

  @override
  String get keybindingPreviousChannel => 'Canal anterior';

  @override
  String get keybindingPreviousPr => 'PR anterior';

  @override
  String get keybindingPreviousWorkspace => 'Espacio de trabajo anterior';

  @override
  String get keybindingRefresh => 'Actualizar';

  @override
  String get keybindingRefreshAllFeedsDescription =>
      'Actualizar todas las fuentes';

  @override
  String get keybindingRefreshAnalyticsDataDescription =>
      'Actualizar datos de análisis';

  @override
  String get keybindingRefreshDashboardDataDescription =>
      'Actualizar datos del panel';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Actualizar la lista de pull requests';

  @override
  String get keybindingRemoveRepository => 'Quitar repositorio';

  @override
  String get keybindingRemoveTheSelectedRepositoryDescription =>
      'Quitar el repositorio seleccionado';

  @override
  String get keybindingRepositories => 'Repositorios';

  @override
  String get keybindingRequestChanges => 'Solicitar cambios';

  @override
  String get keybindingRequestChangesOnThePeerReviewDescription =>
      'Solicitar cambios en la revisión por pares';

  @override
  String get keybindingRescanForAdaptersDescription => 'Reescanear adaptadores';

  @override
  String get keybindingSearchInDiff => 'Buscar en diff';

  @override
  String get keybindingSearchWithinTheDiffViewDescription =>
      'Buscar en la vista de diff';

  @override
  String get keybindingToggleViewed => 'Alternar visto';

  @override
  String get keybindingMarkTheFocusedFileAsViewedOrUnviewedDescription =>
      'Marcar el archivo enfocado como visto o no visto';

  @override
  String get keybindingToggleCollapse => 'Alternar colapsar';

  @override
  String get keybindingCollapseOrExpandTheFocusedFileDescription =>
      'Colapsar o expandir el archivo enfocado';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Seleccionar el artículo siguiente';

  @override
  String get keybindingSelectTheNextChannelDescription =>
      'Seleccionar el canal siguiente';

  @override
  String get keybindingSelectTheNextPullRequestDescription =>
      'Seleccionar la pull request siguiente';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Seleccionar el artículo anterior';

  @override
  String get keybindingSelectThePreviousChannelDescription =>
      'Seleccionar el canal anterior';

  @override
  String get keybindingSelectThePreviousPullRequestDescription =>
      'Seleccionar la pull request anterior';

  @override
  String get keybindingSendMessage => 'Enviar mensaje';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Enviar el mensaje actual';

  @override
  String get keybindingSkills => 'Habilidades';

  @override
  String get keybindingStartANewDirectMessageDescription =>
      'Iniciar un nuevo mensaje directo';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Cambiar entre modo claro y oscuro';

  @override
  String get keybindingSwitchToTheConversationTabDescription =>
      'Cambiar a la pestaña de conversación';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Cambiar al octavo espacio de trabajo';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Cambiar al quinto espacio de trabajo';

  @override
  String get keybindingSwitchToTheFilesChangedTabDescription =>
      'Cambiar a la pestaña de archivos modificados';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Cambiar al primer espacio de trabajo';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Cambiar al cuarto espacio de trabajo';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Cambiar al espacio de trabajo siguiente';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Cambiar al noveno espacio de trabajo';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Cambiar al espacio de trabajo anterior';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Cambiar al segundo espacio de trabajo';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Cambiar al séptimo espacio de trabajo';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Cambiar al sexto espacio de trabajo';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Cambiar al tercer espacio de trabajo';

  @override
  String get keybindingToggleBookmark => 'Marcar/desmarcar';

  @override
  String get keybindingToggleTheme => 'Cambiar tema';

  @override
  String get keybindingToggleWorkspaceSwitcher => 'Cambiar selector de espacio';

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
  String get keybindings => 'Atajos de teclado';

  @override
  String get keybindingsDescription =>
      'Todos los atajos de teclado. Los atajos son fijos y no se pueden reasignar.';

  @override
  String get killRunning => 'Detener en ejecución';

  @override
  String get klipyNotConfigured => 'KLIPY_APP_KEY no configurada';

  @override
  String get klipyNotConfiguredHint =>
      'Pasa --dart-define=KLIPY_APP_KEY=...\no defínela en .env antes de ejecutar.';

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
  String get latestLabel => 'Recientes';

  @override
  String get leaderboardLabel => 'CLASIFICACIÓN';

  @override
  String get leaderboardLabelShort => 'Clasificación';

  @override
  String get leaveACommentEllipsis => 'Dejar un comentario...';

  @override
  String get legendLabel => 'Leyenda';

  @override
  String get lessLabel => 'Menos';

  @override
  String get letsPluginTools => 'Vamos a conectar tus herramientas.';

  @override
  String get level => 'Nivel';

  @override
  String levelLabel(int level) {
    return 'Nivel $level';
  }

  @override
  String get liveDiff => 'Diff en vivo';

  @override
  String get liveSync => 'Sincronización en vivo';

  @override
  String get loadingAgents => 'Cargando agentes…';

  @override
  String get loadingModels => 'Cargando modelos…';

  @override
  String get lockedLabel => 'Bloqueado';

  @override
  String get logLevel => 'Nivel de registro';

  @override
  String get logs => 'Registros';

  @override
  String get low => 'Bajo';

  @override
  String get maintenance => 'Mantenimiento';

  @override
  String get manageParticipants => 'Gestionar participantes';

  @override
  String get manageWorkspaces => 'Gestionar espacios de trabajo';

  @override
  String get masterToggle => 'Interruptor maestro';

  @override
  String get matchOsAppearance =>
      'Adaptar la apariencia al sistema operativo o elegir un modo fijo.';

  @override
  String get mcpActiveAccepting =>
      'El servidor MCP está activo y aceptando conexiones.';

  @override
  String get mcpAuthToken => 'Token de autenticación MCP';

  @override
  String get mcpAuthentication => 'Autenticación';

  @override
  String get mcpAutoStartDescription =>
      'Si está desactivado, el servidor permanece detenido hasta que lo inicies.';

  @override
  String mcpDefaultPort(int port) {
    return 'Predeterminado: $port';
  }

  @override
  String mcpListeningOn(int port) {
    return 'Escuchando en 127.0.0.1:$port';
  }

  @override
  String mcpListeningOnPort(int port) {
    return 'Escuchando en 127.0.0.1:$port.';
  }

  @override
  String get mcpNotRunning =>
      'El servidor no está en ejecución. Inícialo para habilitar las conexiones MCP.';

  @override
  String get mcpRestartPortChanges =>
      'Debes reiniciar el servidor para aplicar los cambios de puerto.';

  @override
  String get mcpServer => 'Servidor MCP';

  @override
  String get mcpServerStopped => 'El servidor está detenido';

  @override
  String get mcpStatus => 'Estado';

  @override
  String get medium => 'Medio';

  @override
  String get memoryDataHint =>
      'Los hechos y políticas aparecerán aquí a medida que los agentes trabajen.';

  @override
  String get memoryLabel => 'Memoria';

  @override
  String get merge => 'Merge';

  @override
  String get mergeMasterBadge => 'Maestro de merges';

  @override
  String get merged => 'Fusionado';

  @override
  String get messagePlaceholder =>
      'Mensaje… (@ para mencionar, / para comandos)';

  @override
  String get messagingLabel => 'Mensajería';

  @override
  String get microphonePermissionDenied => 'Permiso del micrófono denegado.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count minutos',
      one: 'hace 1 minuto',
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
      other: 'hace $count meses',
      one: 'hace 1 mes',
    );
    return '$_temp0';
  }

  @override
  String get more => 'Más';

  @override
  String get moreLabel => 'Más';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Nombre';

  @override
  String get nameAndTitleRequired => 'El nombre y el título son obligatorios.';

  @override
  String get nameAndUrlRequired => 'Nombre y URL son obligatorios';

  @override
  String get nameLabel => 'Nombre';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Sandbox nativo disponible en $platform.';
  }

  @override
  String get nativeSandboxNeedsInstall =>
      'Instalación necesaria para sandbox nativo';

  @override
  String get navAnalytics => 'Analíticas';

  @override
  String get navDashboard => 'Panel';

  @override
  String get navSaved => 'Guardados';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get navigateLabel => 'Navegar';

  @override
  String networkBlockCount(int count) {
    return '$count bloqueos de red';
  }

  @override
  String get neutral => 'Neutral';

  @override
  String get newAgent => 'Nuevo agente';

  @override
  String get newCommitsPushed =>
      'Se han enviado nuevos commits — haz clic para recargar el diff';

  @override
  String get newFact => 'Nuevo hecho';

  @override
  String get newGroup => 'Nuevo grupo';

  @override
  String get newLabel => 'Nuevo';

  @override
  String get newMessage => 'Nuevo mensaje';

  @override
  String get newPolicy => 'Nueva política';

  @override
  String get newPrToReview => 'Nueva PR para revisar';

  @override
  String get newsfeed => 'Noticias';

  @override
  String get newsfeedLabel => 'Fuente de noticias';

  @override
  String get newsfeedSettingsDescription =>
      'Gestiona tus fuentes suscritas y preferencias del lector.';

  @override
  String get newsfeedSettingsTitle => 'Ajustes de noticias';

  @override
  String get nextMatch => 'Siguiente coincidencia (↵)';

  @override
  String get noAccessGrants => 'No hay permisos de acceso configurados';

  @override
  String get noActiveWorkspace =>
      'No hay espacio de trabajo o repositorio activo.';

  @override
  String get noActiveWorkspaceCreate => 'No hay espacio de trabajo activo';

  @override
  String get noActiveWorkspaceGithub =>
      'No hay espacio de trabajo activo con un repositorio de GitHub.';

  @override
  String get noAgentAssigned => 'Ningún agente asignado';

  @override
  String get noAgentProcessesRunning =>
      'No hay procesos de agentes en ejecución';

  @override
  String get noAgents => 'Sin agentes';

  @override
  String get noAgentsConfigured => 'No hay agentes configurados';

  @override
  String get noAgentsDiscovered => 'Ningún agente descubierto';

  @override
  String get noAgentsDiscoveredHint =>
      'Haz clic en \"Descubrir\" para buscar archivos AGENTS.md o \"Añadir agente\" para configurar uno manualmente';

  @override
  String get noAgentsMatchSearch => 'Ningún agente coincide con tu búsqueda';

  @override
  String get noAgentsRegisteredYet => 'Aún no hay agentes registrados';

  @override
  String get noArticlesYet => 'Aún no hay artículos';

  @override
  String get noArticlesYetBody =>
      'Los artículos de tus fuentes aparecerán aquí.';

  @override
  String get noData => 'Sin datos';

  @override
  String get noDirectMessagesYet => 'Aún no hay mensajes directos';

  @override
  String get noDomains => 'Aún no hay dominios';

  @override
  String get noExecutionLogsYet => 'Aún no hay registros de ejecución';

  @override
  String get noFacts => 'Aún no hay hechos';

  @override
  String get noFeedsYet => 'Aún no hay fuentes';

  @override
  String get noFileAnchor =>
      'Sin ancla de archivo — no se puede publicar comentario en línea.';

  @override
  String get noFileChangesInScope => 'No hay cambios de archivo en este ámbito';

  @override
  String get noGifsFound => 'No se encontraron GIFs';

  @override
  String get noGroupsYet => 'Aún no hay grupos';

  @override
  String get noInputDevicesDetected =>
      'No se detectaron dispositivos de entrada — usando el predeterminado del sistema.';

  @override
  String get noMatchingFiles => 'No hay archivos coincidentes';

  @override
  String get noMatchingGoogleFonts =>
      'No hay fuentes de Google Fonts coincidentes.';

  @override
  String get noMemoryData => 'Aún no hay datos de memoria';

  @override
  String get noMessagesYet => 'Aún no hay mensajes';

  @override
  String get noModelsAdvertised => 'Este adaptador no ofrece modelos.';

  @override
  String get noOpenPullRequests => 'No hay pull requests abiertas';

  @override
  String get noPolicies => 'Aún no hay políticas';

  @override
  String get noReposInWorkspaceYet =>
      'Aún no hay repositorios en este espacio de trabajo';

  @override
  String get noRunnersDetected =>
      'No se han detectado ejecutores. Actualiza para volver a escanear.';

  @override
  String get noSavedArticles => 'Aún no hay artículos guardados';

  @override
  String get noSavedArticlesBody =>
      'Los artículos que guardes aparecerán aquí.';

  @override
  String noShortcutsMatch(String query) {
    return 'Ningún atajo coincide con \"$query\"';
  }

  @override
  String get noSystemFonts => 'No se detectaron fuentes del sistema.';

  @override
  String get noTokenSet =>
      'No se ha configurado ningún token — el acceso es irrestringido.';

  @override
  String get noTokenSetUnrestricted =>
      'No hay token configurado — el acceso es libre.';

  @override
  String get noTokenUnrestricted => 'Sin token — el acceso es libre';

  @override
  String get noWorkingMemory => 'Aún no hay notas de memoria de trabajo.';

  @override
  String get noneAllRoles => 'Ninguno (todos los roles)';

  @override
  String get notAvailable => 'No disponible';

  @override
  String get notConfiguredLabel => 'No configurado.';

  @override
  String get notDetected => 'No detectado';

  @override
  String get notEarnedYet => 'Aún no obtenido';

  @override
  String get notFoundLabel => 'No encontrado';

  @override
  String get notYetSpawned => 'Aún no iniciado';

  @override
  String get notes => 'Notas';

  @override
  String get notificationAgentFinished => 'Agente finalizado';

  @override
  String get notificationExternalPr => 'PRs externas';

  @override
  String get notificationNewMessages => 'Nuevos mensajes';

  @override
  String get notificationPrMerged => 'PR fusionada';

  @override
  String get notificationPrPublished => 'PR publicada';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get notifyAgentRunCompleted =>
      'Notificar cuando un agente complete una ejecución.';

  @override
  String get notifyExternalPr =>
      'Notificar cuando se detecte una nueva PR mediante sondeo.';

  @override
  String get notifyNewMessages =>
      'Notificar sobre nuevos mensajes de agentes en otros canales.';

  @override
  String get notifyPrMerged => 'Notificar cuando se fusione una pull request.';

  @override
  String get notifyPrPublished =>
      'Notificar cuando un agente publique una pull request.';

  @override
  String get onboardingLinuxDescription =>
      'Control Center puede usar contenedores Linux para aislar la ejecución de agentes.';

  @override
  String get onboardingMacosDescription =>
      'Control Center utiliza sandbox nativo en macOS para aislar la ejecución de agentes.';

  @override
  String get onboardingUnsupportedDescription =>
      'Sandbox no disponible en esta plataforma. La ejecución de agentes será sin aislamiento.';

  @override
  String get openAction => 'Abrir';

  @override
  String get openApplicationSettings => 'Abrir ajustes de la aplicación';

  @override
  String get openArticlesBrowserFallback => 'Abrir artículo en el navegador';

  @override
  String get openArticlesInApp => 'Abrir artículos en la app';

  @override
  String get openContainerTerminal => 'Abrir terminal del contenedor';

  @override
  String get openFolder => 'Abrir carpeta';

  @override
  String get openInBrowser => 'Abrir en el navegador';

  @override
  String get openLabel => 'Abierto';

  @override
  String get openOnGithub => 'Abrir en GitHub';

  @override
  String get openStatus => 'Abierto';

  @override
  String get optionalPersonaDescription => 'Descripción de persona opcional';

  @override
  String get otherLabel => 'Otros';

  @override
  String get ownerOrganization => 'Propietario / Organización';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get parsingDiff => 'Analizando diff…';

  @override
  String get passed => 'Aprobado';

  @override
  String get pasteTokenHere => 'Pegar token aquí';

  @override
  String get pasteValueHere => 'Pegar valor aquí';

  @override
  String get patNotNeededGhCli =>
      'No necesario — gh CLI tiene sesión iniciada.';

  @override
  String get patOverridesGhCli => 'Configurado — prevalece sobre gh CLI.';

  @override
  String get pathLabel => 'Ruta';

  @override
  String get pendingApproval => 'Pendiente de tu aprobación';

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
      'Token de acceso personal (opcional)';

  @override
  String get planLabel => 'Plan';

  @override
  String get policies => 'Políticas';

  @override
  String get policiesHint =>
      'Las políticas aparecerán aquí una vez que los agentes promuevan hechos.';

  @override
  String get policy => 'Política';

  @override
  String get popular => 'Populares';

  @override
  String get port => 'Puerto';

  @override
  String get portLabel => 'Puerto';

  @override
  String get postingEllipsis => 'Publicando...';

  @override
  String get prCommits => 'Commits';

  @override
  String get prDescriptionPlaceholder => 'Descripción de la PR en Markdown...';

  @override
  String get prDraftCreated => 'Borrador de PR creado';

  @override
  String get prMachineBadge => 'Máquina de PRs';

  @override
  String get prMergedBody => 'Se ha fusionado una pull request';

  @override
  String get prMoreActions => 'More actions';

  @override
  String get prTitle => 'Título de la PR';

  @override
  String get previewLabel => 'Vista previa';

  @override
  String get previousArticle => 'Artículo anterior';

  @override
  String get previousChannel => 'Canal anterior';

  @override
  String get previousMatch => 'Coincidencia anterior (⇧↵)';

  @override
  String get previousPr => 'PR anterior';

  @override
  String get previousWorkspace => 'Espacio anterior';

  @override
  String get priorityReviews => 'Revisiones prioritarias';

  @override
  String get priorityReviewsDescription =>
      'Revisiones prioritarias y resumen del repositorio.';

  @override
  String get progressLabel => 'Progreso';

  @override
  String get proposeToCreateDomain =>
      'Proponga un hecho o política para crear uno.';

  @override
  String get prsCreated => 'PRs creadas';

  @override
  String get prsCreatedLabel => 'PRs creadas';

  @override
  String get prsMerged => 'PRs fusionadas';

  @override
  String get publishToGithub => 'Publicar en GitHub';

  @override
  String get published => 'Publicado';

  @override
  String get pullRequestApproved => 'Pull request aprobada';

  @override
  String get pullRequests => 'Pull requests';

  @override
  String get questionLabel => 'PREGUNTA';

  @override
  String get queued => 'En cola';

  @override
  String get react => 'Reaccionar';

  @override
  String get readPrsIssuesMetadata =>
      'Permite al agente leer PRs, issues y metadatos del repositorio.';

  @override
  String get readerPreferences => 'Preferencias del lector';

  @override
  String get reasoningEffort => 'Esfuerzo de razonamiento';

  @override
  String get recommendLabel => 'RECOMENDAR';

  @override
  String recordingFromDevice(String device) {
    return 'Grabando desde $device.';
  }

  @override
  String get redownload => 'Descargar de nuevo';

  @override
  String get redownloadEmbeddingModel =>
      '¿Descargar de nuevo el modelo de embeddings?';

  @override
  String get redownloadVoiceModel => '¿Descargar de nuevo el modelo de voz?';

  @override
  String get refinePlan => 'Refinar plan';

  @override
  String get refiningPlan => 'Refinando plan…';

  @override
  String get refresh => 'Actualizar';

  @override
  String get refreshAll => 'Actualizar todo';

  @override
  String get refreshAllFeeds => 'Actualizar todas las fuentes';

  @override
  String get refreshLabel => 'Actualizar';

  @override
  String get refreshPrData => 'Actualizar datos de la PR';

  @override
  String get reject => 'Rechazar';

  @override
  String get rejected => 'Rechazado';

  @override
  String get reload => 'Recargar';

  @override
  String get remove => 'Quitar';

  @override
  String get removeBookmark => 'Quitar marcador';

  @override
  String get removeEmbeddingModel => '¿Eliminar el modelo de embeddings?';

  @override
  String get removeLogo => 'Quitar logo';

  @override
  String get removeRepoFromWorkspace =>
      '¿Quitar repositorio del espacio de trabajo?';

  @override
  String get removeRepository => 'Quitar repositorio';

  @override
  String get removeRepositoryConfirm =>
      '¿Quitar repositorio del espacio de trabajo?';

  @override
  String get removeVoiceModel => '¿Eliminar el modelo de voz?';

  @override
  String get removed => 'Eliminado';

  @override
  String get renamed => 'Renombrado';

  @override
  String get reopen => 'Reabrir';

  @override
  String get replyEllipsis => 'Responder…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name se eliminará de este espacio de trabajo. Los archivos locales en disco no se modifican.';
  }

  @override
  String get reportsTo => 'Reporta a';

  @override
  String get reportsToOptional => 'Reporta a (opcional)';

  @override
  String reposCount(int count) {
    return 'Repositorios ($count)';
  }

  @override
  String get reposDescription =>
      'Los checkouts locales a los que apunta este espacio de trabajo.';

  @override
  String get repositories => 'Repositorios';

  @override
  String get repositoriesSettings => 'Ajustes de repositorios';

  @override
  String get repositoryName => 'Nombre del repositorio';

  @override
  String get requestChanges => 'Solicitar cambios';

  @override
  String get requested => 'Solicitado';

  @override
  String get requestedChanges => 'Cambios solicitados';

  @override
  String get requiredIfGhCliUnavailable =>
      'Necesario si gh CLI no está disponible';

  @override
  String requiredRoleLabel(String role) {
    return 'Rol requerido: $role';
  }

  @override
  String get requiredRoleOptional => 'Rol requerido (opcional)';

  @override
  String get requirements => 'Requisitos';

  @override
  String get reset => 'Restablecer';

  @override
  String get resetAllSandboxes => 'Restablecer todos los sandboxes';

  @override
  String get resolve => 'Resolver';

  @override
  String get resolved => 'Resuelto';

  @override
  String get restartServerToApply =>
      'Reinicia el servidor para aplicar los cambios.';

  @override
  String get restartShell => 'Reiniciar shell';

  @override
  String get restartToApply => 'Reinicia el servidor para aplicar los cambios.';

  @override
  String get retry => 'Reintentar';

  @override
  String get review => 'Revisar';

  @override
  String get reviewChanges => 'Revisar cambios';

  @override
  String get reviewedByMe => 'Revisadas por mí';

  @override
  String get reviewers => 'REVISORES';

  @override
  String get reviewersActive => 'Revisores activos';

  @override
  String get reviewsLabel => 'Revisiones';

  @override
  String get roleLabel => 'Rol';

  @override
  String get ruleHint => 'La regla de la política (markdown soportado)';

  @override
  String get ruleLabel => 'Regla';

  @override
  String get runCompleted => 'Ejecución completada';

  @override
  String get runGhAuthLoginBody =>
      'Ejecuta `gh auth login` en tu terminal y luego pulsa Actualizar.';

  @override
  String get running => 'En ejecución';

  @override
  String get runningLabel => 'en ejecución';

  @override
  String get runningStatus => 'En ejecución';

  @override
  String get runs => 'Ejecuciones';

  @override
  String get runsAcrossAllAgents => 'Ejecuciones en todos los agentes';

  @override
  String get runsLabel => 'Ejecuciones';

  @override
  String get sandboxBackendNativeLabel => 'Native sandbox';

  @override
  String get sandboxBackendNoneLabel => 'No isolation';

  @override
  String get sandboxLinuxInstall =>
      'El sandbox nativo en Linux/WSL2 utiliza bubblewrap. Instálalo con:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'El sandbox nativo está integrado en macOS — utiliza Apple Seatbelt (`sandbox-exec`). No requiere instalación.';

  @override
  String get sandboxPermissions => 'Permisos del sandbox';

  @override
  String get sandboxUnsupported =>
      'El sandbox nativo aún no es compatible con esta plataforma. Vuelve a \"Sin aislamiento\".';

  @override
  String get sandboxing => 'Sandboxing';

  @override
  String get sandboxingDescription =>
      'Ejecuta agentes dentro de un sandbox a nivel de SO para que no puedan tocar tu carpeta de inicio, claves SSH o tokens que no hayas concedido.';

  @override
  String get sandboxingDisabledDescription =>
      'Los agentes se ejecutan directamente en el host con entorno completo — no recomendado.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Todas las invocaciones de agentes se enrutan a través de $backend.';
  }

  @override
  String get save => 'Guardar';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get savedArticlesDescription => 'Artículos que has guardado.';

  @override
  String get savedLabel => 'Guardados';

  @override
  String get savingChanges => 'Guardando cambios...';

  @override
  String get savingEllipsis => 'Guardando…';

  @override
  String get scopeDiffToCommits =>
      'Filtrar diff por commits — Mayús-clic para rango';

  @override
  String get searchAgents => 'Buscar agentes';

  @override
  String get searchAuthors => 'Buscar autores…';

  @override
  String get searchPullRequestsHint => 'Buscar… p. ej. author:@user';

  @override
  String get noPrsMatchSearch => 'No hay pull requests coincidentes';

  @override
  String get noPrsMatchSearchHint =>
      'Ninguna PR abierta coincide con tu búsqueda. Prueba otros términos o borra la búsqueda.';

  @override
  String get searchAuthorsPlaceholder => 'Buscar autores…';

  @override
  String get searchFactsHint => 'Buscar hechos...';

  @override
  String get searchFonts => 'Buscar fuentes…';

  @override
  String get searchGifs => 'Buscar GIFs';

  @override
  String get searchGifsHint => 'Buscar GIFs...';

  @override
  String get searchInDiff => 'Buscar en el diff';

  @override
  String get searchInDiffHint => 'Buscar en diff...';

  @override
  String get searchOrTypeModel => 'Busca o escribe un nombre de modelo…';

  @override
  String get searchPlaceholder => 'Buscar...';

  @override
  String get searchShortcuts => 'Buscar atajos…';

  @override
  String get searching => 'Buscando...';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count segundos',
      one: 'hace 1 segundo',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Seleccionar adaptador';

  @override
  String get selectAdapterFirst => 'Selecciona un adaptador primero';

  @override
  String get selectAgentToReportTo => 'Selecciona un agente al que reportar…';

  @override
  String get selectAnAgent => 'Seleccionar un agente';

  @override
  String get selectConversation => 'Seleccionar una conversación';

  @override
  String get selectEffortLevel => 'Selecciona el nivel de esfuerzo';

  @override
  String get selectLabel => 'Seleccionar';

  @override
  String get selectRunner => 'Seleccionar un ejecutor';

  @override
  String get semanticSearch => 'Búsqueda semántica';

  @override
  String get send => 'Enviar';

  @override
  String get sendFirstMessage => 'Enviar el primer mensaje';

  @override
  String get sendMessage => 'Enviar mensaje';

  @override
  String sentFindingsToAgent(int count) {
    return 'Se enviaron $count hallazgo(s) al agente.';
  }

  @override
  String get serverRunning => 'Servidor en ejecución';

  @override
  String get serverStopped => 'Servidor detenido';

  @override
  String setGithubLinkDescription(String name) {
    return 'Establece el propietario de GitHub y el nombre del repositorio para $name. Esto se usa para resolver referencias de PR e issues como #123 en contenido markdown.';
  }

  @override
  String get setLabel => 'Establecer';

  @override
  String get setToken => 'Establecer token';

  @override
  String get settingsGeneralDescription =>
      'Apariencia, tipografía, integraciones y servidor MCP.';

  @override
  String get settingsLabel => 'Ajustes';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageDescription =>
      'Elegir el idioma de la aplicación.';

  @override
  String get sharedSecretToken => 'Token secreto compartido';

  @override
  String get sharpshooterBadge => 'Tirador certero';

  @override
  String get shortTask => 'Tarea corta';

  @override
  String get showNativeNotifications =>
      'Mostrar notificaciones nativas de macOS para eventos.';

  @override
  String get showSuperseded => 'Mostrar sustituidos';

  @override
  String get signInWithGhAuth =>
      'Inicia sesión con gh auth login o añade un token en Ajustes > Claves API';

  @override
  String get signedIn => 'Sesión iniciada.';

  @override
  String signedInAs(String username) {
    return 'Sesión iniciada como $username.';
  }

  @override
  String get skillEditor => 'Editor de habilidades';

  @override
  String get skillNameRequired => 'El nombre de la habilidad es obligatorio.';

  @override
  String skillSaved(String name) {
    return 'Habilidad \"$name\" guardada.';
  }

  @override
  String get skills => 'Habilidades';

  @override
  String get skillsColon => 'Habilidades:';

  @override
  String get skillsCommaSeparated => 'Habilidades (separadas por comas)';

  @override
  String get skillsLabel => 'HABILIDADES';

  @override
  String get skipAcceptRisk => 'Saltar — Acepto el riesgo';

  @override
  String get skipForNow => 'Omitir por ahora';

  @override
  String get skipSandboxing => 'Saltar sandboxing';

  @override
  String get skipSandboxingDialogContent =>
      '¿Estás seguro de que quieres omitir el sandbox? Esto permite que los agentes ejecuten código en tu sistema sin aislamiento.';

  @override
  String get somethingWentWrong => 'Algo salió mal';

  @override
  String sourceCount(int count) {
    return '$count fuente';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count fuentes';
  }

  @override
  String get sourceFacts => 'Hechos de origen:';

  @override
  String get splitDiff => 'Diff en paralelo';

  @override
  String get startDmWithAgent => 'Iniciar mensaje directo con agente';

  @override
  String get startFresh => 'Empezar de cero';

  @override
  String get startLabel => 'Iniciar';

  @override
  String get startOnAppLaunch => 'Iniciar al abrir la app';

  @override
  String get startServerToAccept =>
      'Inicia el servidor para aceptar conexiones MCP.';

  @override
  String get stats => 'Estadísticas';

  @override
  String get statusLabel => 'Estado';

  @override
  String stepConnect(int number) {
    return 'Paso $number · Conectar';
  }

  @override
  String get stop => 'Detener';

  @override
  String get stopped => 'Detenido';

  @override
  String get streaks => 'Rachas';

  @override
  String get streaksLabel => 'Rachas';

  @override
  String get strictIdentityCheck => 'Verificación estricta de identidad';

  @override
  String get success => 'Éxito';

  @override
  String get successLabel => 'Éxito';

  @override
  String get successLabelShort => 'Éxito';

  @override
  String get successRate => 'Tasa de éxito';

  @override
  String get suggestAChange => 'Sugerir un cambio';

  @override
  String get suggestAChangeEllipsis => 'Sugerir un cambio...';

  @override
  String get suggestLabel => 'SUGERIR';

  @override
  String get superseded => 'Sustituido';

  @override
  String get synced => 'Sincronizado';

  @override
  String get systemDefault => 'Valor predeterminado del sistema';

  @override
  String get systemFonts => 'Fuentes del sistema';

  @override
  String get systemPrompt => 'Prompt del sistema';

  @override
  String get systemPromptLabel => 'Prompt del sistema';

  @override
  String get talkToControlCenter => 'Habla con Control Center.';

  @override
  String get tapBadgeDescription =>
      'Toca una insignia para ver cómo subir de nivel';

  @override
  String get tapBadgeToLevelUp =>
      'Toca una insignia para ver cómo subir de nivel';

  @override
  String get taskMentionSection => 'Tarea';

  @override
  String get testLabel => 'Probar';

  @override
  String get theme => 'Tema';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get thisCannotBeUndone => 'Esta acción no se puede deshacer.';

  @override
  String get thisConversation => 'esta conversación';

  @override
  String get threadLabel => 'Hilo';

  @override
  String get throughput => 'Rendimiento';

  @override
  String get ticketLabel => 'TICKET';

  @override
  String tierLabel(String tier) {
    return 'Nivel $tier';
  }

  @override
  String get titleDescription => 'Descripción';

  @override
  String get titleLabel => 'Título';

  @override
  String get todayLabel => 'Hoy';

  @override
  String get toggleBookmark => 'Marcar/desmarcar';

  @override
  String get toggleTheme => 'Cambiar tema';

  @override
  String get toggleWorkspaceSwitcher => 'Cambiar selector de espacio';

  @override
  String get tokenConfigured =>
      'Configurado — los clientes deben presentar este token.';

  @override
  String get tokenConfiguredClients =>
      'Configurado — los clientes deben presentar este token.';

  @override
  String tokenName(String name) {
    return 'Token de $name';
  }

  @override
  String get topPerformerLabel => 'MEJOR RESULTADO';

  @override
  String get topPerformersDescription =>
      'Mejores resultados, rendimiento y salud del espacio de trabajo.';

  @override
  String get topic => 'Tema';

  @override
  String get topicHint => 'ej: Tech Stack, Design System';

  @override
  String get totalRuns => 'Ejecuciones totales';

  @override
  String get totalRunsLabel => 'Ejecuciones totales';

  @override
  String trackingParamsCount(int count) {
    return '$count parámetros de seguimiento';
  }

  @override
  String get typeCommandOrSearch => 'Escribe un comando o busca…';

  @override
  String get typography => 'Tipografía';

  @override
  String get unavailable => 'No disponible';

  @override
  String get unexpectedError => 'Ocurrió un error inesperado.';

  @override
  String get unifiedDiff => 'Diff unificado';

  @override
  String get unknownAuthor => 'Desconocido';

  @override
  String get unnamedAgent => 'Agente sin nombre';

  @override
  String get updateKey => 'Actualizar clave';

  @override
  String get updateLabel => 'Actualizar';

  @override
  String get updateToken => 'Actualizar token';

  @override
  String updatedDaysAgo(int count) {
    return 'Actualizado hace $count d';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'Actualizado hace $count h';
  }

  @override
  String get updatedJustNow => 'Actualizado ahora';

  @override
  String updatedMinutesAgo(int count) {
    return 'Actualizado hace $count min';
  }

  @override
  String get useSandbox => 'Usar sandbox';

  @override
  String get useWorkspaceDefault =>
      'Usar valor por defecto del espacio de trabajo';

  @override
  String get userAgent => 'Agente de usuario';

  @override
  String get userAgentDescription =>
      'Déjalo vacío para usar el agente de usuario predeterminado de la app. Algunos sitios bloquean agentes de usuario que no son de navegador.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Usando el micrófono predeterminado del sistema.';

  @override
  String get viewAll => 'Ver todo';

  @override
  String get viewLabel => 'Vista';

  @override
  String get viewLog => 'Ver registro';

  @override
  String get viewLogs => 'Ver registros';

  @override
  String voiceInstallFailed(String error) {
    return 'Error de instalación: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'No instalado. Descarga ~200 MB una vez; se ejecuta completamente en el dispositivo.';

  @override
  String get voiceModelNotInstalledLabel => 'Modelo de voz no instalado.';

  @override
  String get voiceRedownloadBody =>
      'Los archivos del modelo existente se eliminarán y se descargará de nuevo el archivo de ~200 MB. La transcripción de voz no estará disponible hasta que se complete la descarga.';

  @override
  String get voiceRemoveBody =>
      'La transcripción de voz se desactivará hasta que la reinstales. Puedes reinstalarla en cualquier momento.';

  @override
  String get voiceTranscription => 'Transcripción de voz';

  @override
  String get weakIsolationDescription =>
      'Aislamiento débil — solo límite de namespace, sin límite de kernel.';

  @override
  String get whenOffNoDefaultRoute =>
      'Cuando está desactivado, el sandbox arranca sin ruta predeterminada.';

  @override
  String get whenOffServerStaysStopped =>
      'Cuando está desactivado, el servidor permanece detenido hasta que lo inicies.';

  @override
  String get whisperBaseEn => 'Whisper base.en (sherpa-onnx)';

  @override
  String get whisperInstalled =>
      'Whisper base.en instalado. Se usa con el botón de micrófono del compositor.';

  @override
  String workerLabel(int index) {
    return 'Worker $index';
  }

  @override
  String workersCount(int count) {
    return '$count workers';
  }

  @override
  String get workingMemory => 'Memoria de trabajo';

  @override
  String get workspaceName => 'Nombre del espacio de trabajo';

  @override
  String get workspaceNotFound => 'Espacio de trabajo no encontrado';

  @override
  String get workspaceNotesScratchpad =>
      'Notas y borrador del espacio de trabajo';

  @override
  String get workspacePulse => 'PULSO DEL ESPACIO';

  @override
  String get workspaceScopedSkills =>
      'Archivos de habilidades del espacio de trabajo adjuntos a los agentes.';

  @override
  String workspaceTitle(String name) {
    return 'Espacio de trabajo: $name';
  }

  @override
  String get workspaces => 'Espacios de trabajo';

  @override
  String get writeLabel => 'Escribir';

  @override
  String get writePrivateNotes =>
      'Escribe notas privadas, observaciones, planes...';

  @override
  String get writeSkillContent =>
      'Escribe el contenido de la habilidad aquí (Markdown)…';

  @override
  String get xp => 'XP';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count años',
      one: 'hace 1 año',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'ayer';

  @override
  String get yourAchievements => 'TUS LOGROS';

  @override
  String get focusModeStart => 'Iniciar sesión de enfoque';

  @override
  String get focusModeConfigTitle => 'Iniciar sesión de enfoque';

  @override
  String get focusModeGoalLabel => 'Objetivo';

  @override
  String get focusModeGoalHint => '¿En qué estás trabajando?';

  @override
  String get focusModeDurationLabel => 'Duración';

  @override
  String get focusModeBlockNotifications => 'Bloquear notificaciones';

  @override
  String get focusModeStartButton => 'Iniciar';

  @override
  String get focusModeEndSession => 'Finalizar sesión';

  @override
  String get focusModeExpand => 'Expandir aplicación';

  @override
  String get focusModeFloat => 'Minimizar a barra';

  @override
  String get focusModeActiveTooltip =>
      'Modo de enfoque activo — toca para finalizar';

  @override
  String get dismiss => 'Descartar';

  @override
  String get acceptAndResolve => 'Aceptar y resolver';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'Parece que estás haciendo muchas revisiones seguidas. ¡Tómate un descanso!';
  }

  @override
  String get notificationSound => 'Sonido de notificación';

  @override
  String get notificationSoundDescription =>
      'Sonido reproducido cuando se muestra una notificación.';

  @override
  String get notificationSoundNone => 'Ninguno';

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
  String get notificationSoundTest => 'Probar';

  @override
  String get notificationVolume => 'Volumen';

  @override
  String get viewProfile => 'Ver perfil';

  @override
  String get clearAllFilters => '× Borrar todo';

  @override
  String acrossNRepos(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'En $countString repos',
      one: 'En 1 repo',
    );
    return '$_temp0';
  }

  @override
  String get pullRequestsLabel => 'PRs';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Sin PRs de @$login en este espacio de trabajo';
  }

  @override
  String get usersLabel => 'Usuarios';

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
  String get checksFailing => 'Comprobaciones fallidas';

  @override
  String get reviewsPending => 'Some reviews are pending';

  @override
  String get confirm => 'Confirm';

  @override
  String get trustedSitesSectionTitle => 'Sitios de confianza';

  @override
  String get trustedSitesEmpty =>
      'Sin sitios de confianza. Añade un dominio para desactivar el bloqueo en él.';

  @override
  String get addTrustedSite => 'Añadir sitio de confianza';

  @override
  String get removeTrustedSite => 'Eliminar';

  @override
  String get disableBlockingForThisSite => 'Desactivar bloqueo en este sitio';

  @override
  String get enableBlockingForThisSite => 'Activar bloqueo en este sitio';

  @override
  String get enterDomainHint => 'ej. ejemplo.com';

  @override
  String get invalidDomain => 'Introduce un dominio válido (ej. ejemplo.com)';

  @override
  String get pageLoadTimedOut =>
      'Tiempo de carga agotado. Recarga o abre en el navegador.';

  @override
  String get pipelinesScreenTitle => 'Pipelines';

  @override
  String get pipelinesScreenSubtitle =>
      'Declarative multi-step agent workflows';

  @override
  String get pipelinesRunHello => 'Run hello pipeline';

  @override
  String get pipelinesRunPipeline => 'Ejecutar pipeline';

  @override
  String get pipelineRunLauncherTitle => 'Ejecutar pipeline';

  @override
  String get pipelineRunSubtitle =>
      'Elige un pipeline y completa sus entradas para iniciar una ejecución.';

  @override
  String get pipelineRunNoInputsBadge => 'Sin entradas';

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
  String get pipelineRunNoInputs => 'Este pipeline no requiere entradas.';

  @override
  String get pipelineRunSubmit => 'Ejecutar pipeline';

  @override
  String get pipelineRunCouldNotStart => 'No se pudo iniciar la ejecución.';

  @override
  String pipelineRunStarted(String name) {
    return '$name iniciado';
  }

  @override
  String get pipelineRunEmptyTitle => 'Ningún pipeline listo para ejecutar';

  @override
  String get pipelineRunEmptyHint =>
      'Habilita un pipeline y activa la ejecución manual en su editor para lanzarlo aquí.';

  @override
  String get pipelineRunManageTemplates => 'Gestionar pipelines';

  @override
  String get pipelineRunSettingsTitle => 'Ejecución manual';

  @override
  String get pipelineRunSettingsAllow => 'Permitir ejecución manual';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Mostrar este pipeline en la página de ejecución para poder iniciarlo manualmente.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Entradas';

  @override
  String get pipelineRunSettingsAddInput => 'Añadir entrada';

  @override
  String get pipelineRunSettingsNoInputs => 'Aún no hay entradas.';

  @override
  String get pipelineInputEditTitle => 'Campo de entrada';

  @override
  String get pipelineInputKeyLabel => 'Clave';

  @override
  String get pipelineInputKeyHelp =>
      'Clave de estado bajo la que se guarda el valor (p. ej. repoFullName).';

  @override
  String get pipelineInputLabelLabel => 'Etiqueta';

  @override
  String get pipelineInputTypeLabel => 'Tipo';

  @override
  String get pipelineInputOptionsLabel => 'Opciones (separadas por comas)';

  @override
  String get pipelineInputDefaultLabel => 'Valor predeterminado';

  @override
  String get pipelineInputPlaceholderLabel => 'Marcador de posición';

  @override
  String get pipelineInputHelpLabel => 'Texto de ayuda';

  @override
  String get pipelineInputRequiredLabel => 'Obligatorio';

  @override
  String get pipelineInputTypeText => 'Texto';

  @override
  String get pipelineInputTypeMultiline => 'Texto multilínea';

  @override
  String get pipelineInputTypeNumber => 'Número';

  @override
  String get pipelineInputTypeBoolean => 'Interruptor';

  @override
  String get pipelineInputTypeSelect => 'Selección';

  @override
  String get pipelinesEmpty => 'No pipeline runs yet';

  @override
  String get pipelinesEmptyHint =>
      'Haz clic en «Ejecutar pipeline» para iniciar uno.';

  @override
  String get pipelinesSelectRun => 'Select a pipeline run to view steps';

  @override
  String get pipelinesNoSteps => 'No steps recorded yet';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Selecciona un espacio de trabajo para ver sus pipelines';

  @override
  String pipelinesLoadError(String error) {
    return 'Error al cargar los pipelines: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Error al iniciar el pipeline: $error';
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
    return '$completed de $total pasos';
  }

  @override
  String get pipelineStepStarted => 'Iniciado';

  @override
  String get pipelineStepFinished => 'Finalizado';

  @override
  String get pipelineStepDurationLabel => 'Duración';

  @override
  String get pipelineStepBranch => 'Rama';

  @override
  String get pipelineStepError => 'Error';

  @override
  String get pipelineStepInput => 'Entrada';

  @override
  String get pipelineStepOutput => 'Salida';

  @override
  String get pipelineStepNotExecuted => 'Aún no ejecutado';

  @override
  String get pipelineRunViewTimeline => 'Cronología';

  @override
  String get pipelineRunViewGraph => 'Gráfico';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Falló en $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Manual';

  @override
  String get pipelineRunTriggerAuto => 'Automático';

  @override
  String get pipelineStepSkippedReason => 'Omitido';

  @override
  String get pipelineRunFilterAll => 'Todos';

  @override
  String get pipelineRunFilterEmpty =>
      'Ninguna ejecución coincide con este filtro';

  @override
  String get relativeJustNow => 'ahora mismo';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count min',
      one: 'hace 1 min',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count horas',
      one: 'hace 1 hora',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get automationsTitle => 'Automatizaciones';

  @override
  String get automationsSubtitle =>
      'Iniciar automáticamente pipelines cuando se disparan eventos de dominio';

  @override
  String get automationsNoTriggers =>
      'No hay disparadores configurados para este evento.';

  @override
  String get automationsAddTrigger => 'Añadir disparador';

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
  String get tasksNoTasks => 'Sin tickets';

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
  String get pipelineTemplatesNav => 'Plantillas de pipeline';

  @override
  String get pipelineTemplatesTitle => 'Plantillas de pipeline';

  @override
  String get pipelineTemplatesSubtitle =>
      'Editor arrastrar y soltar para los pipelines que orquestan tus agentes.';

  @override
  String get pipelineTemplatesNew => 'Nueva plantilla';

  @override
  String get pipelineTemplatesEmpty =>
      'Aún no hay plantillas de pipeline. Crea una para empezar.';

  @override
  String get pipelineTemplateIdLabel => 'ID de plantilla';

  @override
  String get pipelineTemplateBuiltInBadge => 'Integrada';

  @override
  String get pipelineTemplateDeleteConfirmTitle => '¿Eliminar plantilla?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return '¿Eliminar la plantilla de pipeline $name? Esta acción no se puede deshacer.';
  }

  @override
  String get pipelineTemplateSaved => 'Plantilla de pipeline guardada';

  @override
  String get pipelineTemplateEditorTitle => 'Editar pipeline';

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Arrastra tipos de nodos desde la barra lateral al lienzo y conéctalos.';

  @override
  String get unsavedChanges => 'Cambios sin guardar';

  @override
  String get nodeLibraryTitle => 'Biblioteca de nodos';

  @override
  String get nodeLibraryHint =>
      'Arrastra cualquier entrada al lienzo para añadir un nodo.';

  @override
  String get editorDragHint =>
      'Arrastra desde la biblioteca, haz clic en un nodo para editarlo';

  @override
  String get editorEmptyCanvas =>
      'Arrastra un nodo desde la biblioteca para empezar.';

  @override
  String get nodeConfigTitle => 'Configuración del nodo';

  @override
  String get nodeConfigKind => 'Tipo';

  @override
  String get nodeConfigLabel => 'Etiqueta';

  @override
  String get nodeConfigAgent => 'Agente';

  @override
  String get nodeConfigAgentHint => 'Elige un agente…';

  @override
  String get nodeConfigInputKeys => 'Claves de entrada (separadas por comas)';

  @override
  String get nodeConfigInputKeysHelp =>
      'Claves de estado que consume este nodo. Usadas para la sustitución de placeholders en el prompt.';

  @override
  String get nodeConfigOutputKey => 'Clave de salida';

  @override
  String get nodeConfigPrompt => 'Plantilla del prompt';

  @override
  String get nodeConfigPromptHelp =>
      'Usa marcadores con doble llave para insertar valores desde el estado en tiempo de ejecución.';

  @override
  String get nodeConfigScript => 'Script bash';

  @override
  String get nodeConfigScriptHelp =>
      'Se ejecuta con bash -c. GITHUB_TOKEN está disponible. Los placeholders se sustituyen antes de ejecutar.';

  @override
  String get nodeConfigTriggers => 'Activado por';

  @override
  String get nodeConfigNoUpstream => 'No hay otros nodos para conectar.';

  @override
  String get nodeConfigRouteKeys => 'Claves de ruta';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Clave de ruta desde $source';
  }

  @override
  String get conditionSectionTitle => 'Condición';

  @override
  String get conditionMode => 'Modo';

  @override
  String get conditionModeFilesAny => 'Archivo(s) existe(n) — alguno';

  @override
  String get conditionModeFilesAll => 'Archivos existen — todos';

  @override
  String get conditionModeComparison => 'Comparación';

  @override
  String get conditionModeSwitch => 'Conmutador';

  @override
  String get conditionFilePaths => 'Rutas de archivo';

  @override
  String get conditionFilePathsAnyHelp =>
      'Una ruta por línea, relativa al directorio base. Devuelve true si existe alguna.';

  @override
  String get conditionFilePathsAllHelp =>
      'Una ruta por línea, relativa al directorio base. Devuelve true solo si existen todas.';

  @override
  String get conditionBaseKey => 'Clave del directorio base';

  @override
  String get conditionBaseKeyHelp =>
      'Clave de estado con el directorio donde se resuelven las rutas (por defecto repoLocalPath).';

  @override
  String get conditionRecursive => 'Buscar en subdirectorios';

  @override
  String get conditionNegate => 'Invertir: devuelve true si falta';

  @override
  String get conditionLeft => 'Valor izquierdo';

  @override
  String get conditionOperator => 'Operador';

  @override
  String get conditionRight => 'Valor derecho';

  @override
  String get conditionSwitchKey => 'Conmutar según la clave de estado';

  @override
  String get conditionCases => 'Casos (separados por comas)';

  @override
  String get conditionCasesHelp =>
      'Claves de ruta para comparar con el valor, en orden.';

  @override
  String get conditionDefaultCase => 'Caso por defecto';

  @override
  String get triggerPanelTitle => 'Disparadores';

  @override
  String get triggerPanelHelp => 'Qué inicia este pipeline.';

  @override
  String get triggerManualHelp =>
      'Mostrar en la página de ejecución e iniciar a mano.';

  @override
  String get triggerSectionAutomatic => 'Disparadores automáticos';

  @override
  String get triggerAddButton => 'Añadir disparador';

  @override
  String get triggerNoneYet => 'Aún no hay disparadores automáticos.';

  @override
  String get triggerAddDialogTitle => 'Añadir disparador';

  @override
  String get triggerKindLabel => 'Tipo de disparador';

  @override
  String get triggerKindEvent => 'Por un evento';

  @override
  String get triggerKindSchedule => 'Según una programación';

  @override
  String get triggerIntervalLabel => 'Ejecutar cada (segundos)';

  @override
  String get triggerEventFieldLabel => 'Evento';

  @override
  String get triggerNoMoreEvents =>
      'Todos los eventos disponibles ya están configurados.';

  @override
  String get triggerMatchStatusLabel => 'Solo cuando el estado es';

  @override
  String get triggerSummaryNone => 'Sin disparadores';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Cada ${seconds}s';
  }

  @override
  String get triggerEventManual => 'Ejecución manual';

  @override
  String get triggerEventSchedule => 'Programación';

  @override
  String get triggerEventPrStatusChanged => 'Estado de la PR cambiado';

  @override
  String get triggerEventExternalPr => 'PR externa abierta';

  @override
  String get triggerEventPrPublished => 'PR publicada';

  @override
  String get triggerEventPrMerged => 'PR fusionada';

  @override
  String get triggerEventRepoAdded => 'Repositorio añadido';

  @override
  String get triggerEventMessageReceived => 'Mensaje recibido';

  @override
  String get triggerEventTicketCompleted => 'Tarea completada';

  @override
  String get triggerEventTicketFailed => 'Tarea fallida';

  @override
  String get triggerEventBudgetCrossed => 'Umbral de presupuesto superado';

  @override
  String get automationsManagedHint =>
      'Los disparadores se configuran por pipeline en su editor. Actívalos o desactívalos aquí.';

  @override
  String get automationsEditInPipeline => 'Editar en el pipeline';

  @override
  String get nodeLibrarySearchHint => 'Buscar nodos';

  @override
  String get nodeLibraryNoMatches => 'No hay nodos coincidentes';

  @override
  String get nodeCategoryFlow => 'Flujo y lógica';

  @override
  String get nodeCategoryPr => 'Revisión de PR';

  @override
  String get nodeCategoryAgents => 'Agentes';

  @override
  String get nodeCategoryMessaging => 'Mensajería';

  @override
  String get nodeCategoryCode => 'Código';

  @override
  String get nodeCategoryDemo => 'Demo';

  @override
  String get triggerDisabledTag => 'desactivado';

  @override
  String get pipelineInputTypeRepo => 'Repositorio';

  @override
  String get pipelineRunNoRepos =>
      'Aún no hay repositorios en este espacio de trabajo.';

  @override
  String get allowTicketingApi => 'Permitir llamadas a la API de tickets';

  @override
  String get ticketingApiKey => 'Clave de API de tickets';

  @override
  String get ticketingApiKeySubtitle =>
      'Inyecta la clave de API del proveedor de tickets en el sandbox.';

  @override
  String get ticketingProvider => 'Proveedor de tickets';

  @override
  String get connectGitHubAndTicketing =>
      'Conecta GitHub para que Control Center pueda leer tus pull requests, incidencias y revisiones. Conecta opcionalmente un proveedor de tickets. Nada sale de esta máquina.';

  @override
  String get triggerEventTicketAssigned => 'Ticket asignado';

  @override
  String get navTickets => 'Tickets';

  @override
  String get ticketsTitle => 'Tickets';

  @override
  String get newTicket => 'Nuevo ticket';

  @override
  String get noTicketsYet => 'Aún no hay tickets';

  @override
  String get assignTicket => 'Asignar ticket';

  @override
  String get addCollaborator => 'Añadir colaborador';

  @override
  String get noCollaborators => 'Aún no hay colaboradores';

  @override
  String get linkedPullRequests => 'Pull requests vinculadas';

  @override
  String get noLinkedPullRequests => 'Aún no hay pull requests vinculadas';

  @override
  String get ticketActivity => 'Actividad';

  @override
  String get ticketDispatchHint => '@menciona a un agente para activarlo…';

  @override
  String get stopAgent => 'Detener agente';

  @override
  String get removeQueuedMessage => 'Eliminar mensaje en cola';

  @override
  String get ticketProperties => 'Propiedades';

  @override
  String get ticketTabIssue => 'Ticket';

  @override
  String get ticketTabActivity => 'Actividad';

  @override
  String get ticketTabChanges => 'Cambios';

  @override
  String get ticketTabTerminal => 'Terminal';

  @override
  String get ticketSelectPrompt => 'Selecciona un ticket para ver sus detalles';

  @override
  String get ticketNoChanges =>
      'Aún no hay cambios en los repositorios vinculados';

  @override
  String get ticketTerminalNoAgent => 'Asigna un agente para abrir un terminal';

  @override
  String get unassigned => 'Sin asignar';

  @override
  String get ticketStatusBacklog => 'Backlog';

  @override
  String get ticketStatusOpen => 'Por hacer';

  @override
  String get ticketStatusInProgress => 'En progreso';

  @override
  String get ticketStatusInReview => 'En revisión';

  @override
  String get ticketStatusDone => 'Hecho';

  @override
  String get ticketStatusBlocked => 'Bloqueado';

  @override
  String get ticketStatusFailed => 'Fallido';

  @override
  String get ticketStatusCancelled => 'Cancelado';

  @override
  String get notificationTicketAssigned => 'Ticket asignado';

  @override
  String get notificationTicketStatusChanged => 'Estado del ticket cambiado';

  @override
  String get notificationTicketCollaboratorAdded => 'Colaborador añadido';

  @override
  String get priority => 'Prioridad';

  @override
  String get status => 'Estado';

  @override
  String get assignee => 'Asignado a';

  @override
  String get ticketDescription => 'Descripción';

  @override
  String get ticketPriorityNone => 'Ninguna';

  @override
  String get ticketPriorityUrgent => 'Urgente';

  @override
  String get ticketPriorityHigh => 'Alta';

  @override
  String get ticketPriorityMedium => 'Media';

  @override
  String get ticketPriorityLow => 'Baja';

  @override
  String get ticketViewList => 'Lista';

  @override
  String get ticketViewBoard => 'Tablero';

  @override
  String get ticketTitlePlaceholder => 'Título del ticket';

  @override
  String get ticketDescriptionPlaceholder => 'Añadir una descripción…';

  @override
  String get createMore => 'Crear más';

  @override
  String selectedCount(int count) {
    return '$count seleccionados';
  }

  @override
  String get clearSelection => 'Borrar selección';

  @override
  String get bulkDeleteTitle => 'Eliminar tickets';

  @override
  String bulkDeleteMessage(int count) {
    return '¿Eliminar $count tickets seleccionados? Esta acción no se puede deshacer.';
  }

  @override
  String get assignTo => 'Asignar a…';

  @override
  String get sectionMembers => 'Miembros';

  @override
  String get sectionAgents => 'Agentes';

  @override
  String get sidebarGroupWork => 'Trabajo';

  @override
  String get sidebarGroupTeam => 'Equipo';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsTooltip => 'Notificaciones';

  @override
  String get notificationsEmpty => 'Estás al día';

  @override
  String get markAllRead => 'Marcar todo como leído';

  @override
  String get toggleThemeLabel => 'Cambiar tema';

  @override
  String get teamsNav => 'Equipos';

  @override
  String get dashboardGreeting => 'Grüezi';

  @override
  String get dashboardSubtitle =>
      'Esto es en lo que están trabajando tus agentes.';

  @override
  String get recentActivityTitle => 'Actividad reciente';

  @override
  String get noRecentActivity => 'Aún no hay actividad reciente';

  @override
  String get noRecentActivitySubtitle =>
      'Las ejecuciones de agentes, las pull requests y los mensajes aparecerán aquí.';

  @override
  String get noWorkspace => 'Sin espacio de trabajo';

  @override
  String get allAgentsIdle => 'Todos los agentes inactivos';

  @override
  String get statWorkspaces => 'Espacios de trabajo';

  @override
  String get statAgents => 'Agentes';

  @override
  String get statRunning => 'En ejecución';

  @override
  String get activeAgentsTitle => 'Agentes activos';

  @override
  String get noAgentProcessesSubtitle =>
      'La actividad de los agentes aparecerá aquí cuando se inicie una ejecución.';

  @override
  String agentIdShort(String id) {
    return 'ID $id';
  }

  @override
  String runningProcessesLabel(int count) {
    return 'En ejecución · $count';
  }

  @override
  String get noneLabel => 'Ninguno';

  @override
  String get sidebarGroupKnowledge => 'Conocimiento';

  @override
  String get navMemory => 'Memoria';

  @override
  String get memoryTabFacts => 'Hechos';

  @override
  String get memoryTabPolicies => 'Políticas';

  @override
  String get memoryTabGraph => 'Grafo de conocimiento';

  @override
  String get memoryNoWorkspace =>
      'Selecciona un espacio de trabajo para ver su memoria.';

  @override
  String get topStory => 'Destacado';

  @override
  String get searchArticles => 'Buscar artículos';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterUnread => 'No leídos';

  @override
  String get filterSaved => 'Guardados';

  @override
  String get saveArticle => 'Guardar artículo';

  @override
  String get removeFromSaved => 'Quitar de guardados';

  @override
  String get filterBySource => 'Filtrar por fuente';

  @override
  String get viewAsList => 'Vista de lista';

  @override
  String get viewAsGrid => 'Vista de cuadrícula';

  @override
  String get noMatchingArticles => 'No hay artículos coincidentes';

  @override
  String get noMatchingArticlesBody =>
      'Prueba con otra búsqueda o filtro de fuente.';

  @override
  String get allCaughtUp => 'Todo al día';

  @override
  String get allCaughtUpBody => 'No hay artículos sin leer; vuelve más tarde.';

  @override
  String get openArticlesInAppDescription =>
      'Abrir los enlaces en el lector integrado en lugar de tu navegador predeterminado.';

  @override
  String get blockAdsTrackersDescription =>
      'Eliminar anuncios, rastreadores y banners de cookies de los artículos que abras en el lector.';

  @override
  String get agentQuestionHeader => 'Pregunta para ti';

  @override
  String get agentQuestionAnsweredLabel => 'Respondido';

  @override
  String get agentQuestionSubmit => 'Enviar respuesta';

  @override
  String get agentQuestionFreeformHint => 'Escribe tu respuesta…';

  @override
  String get agentQuestionAnswerLabel => 'Tu respuesta';

  @override
  String get reviewRequested => 'Revisión solicitada';

  @override
  String get loadMorePrs => 'Cargar más';

  @override
  String get loadingMorePrs => 'Cargando más…';

  @override
  String get noPrsMatchFilters =>
      'Ninguna pull request coincide con los filtros en este repositorio';

  @override
  String get connectGitHubToLoadPrs =>
      'Conecta GitHub para cargar las pull requests';

  @override
  String get noRepositoriesConfigured => 'No hay repositorios configurados';

  @override
  String get noAuthors => 'Sin autores';

  @override
  String get noAuthorMatches => 'Sin coincidencias';

  @override
  String openedAgo(String age) {
    return 'Abierto $age';
  }

  @override
  String updatedAgo(String age) {
    return 'Actualizado $age';
  }

  @override
  String get checksPassing => 'Comprobaciones correctas';

  @override
  String get checksRunning => 'Comprobaciones en curso';

  @override
  String get needsYourReview => 'Necesita tu revisión';

  @override
  String diffSummary(int additions, int deletions) {
    return '+$additions −$deletions líneas';
  }

  @override
  String get checks => 'Comprobaciones';

  @override
  String get noReviewersAssigned => 'Sin revisores asignados';

  @override
  String get noAssignees => 'Sin asignados';

  @override
  String get noChecksYet => 'Aún no se han ejecutado comprobaciones';

  @override
  String checksFailingCount(int count) {
    return '$count con errores';
  }

  @override
  String get showMore => 'Mostrar más';

  @override
  String get showLess => 'Mostrar menos';

  @override
  String get backToPullRequests => 'Volver a las pull requests';

  @override
  String get pullRequestNotFound => 'Pull request no encontrada';

  @override
  String get pullRequestNotFoundBody =>
      'Es posible que se haya fusionado, cerrado o movido.';

  @override
  String get couldntLoadPullRequest => 'No se pudo cargar esta pull request';

  @override
  String get showDetails => 'Mostrar detalles';

  @override
  String loadingPullRequestNumber(int number) {
    return 'Cargando la pull request n.º $number…';
  }

  @override
  String get noDescriptionProvided => 'No se proporcionó ninguna descripción.';

  @override
  String get factsHint =>
      'Los hechos aparecerán aquí a medida que tus agentes aprendan.';

  @override
  String get noFactsMatch => 'Ningún hecho coincide con tu búsqueda';

  @override
  String get memoryLoadError => 'No se pudo cargar la memoria';

  @override
  String get sortRecent => 'Reciente';

  @override
  String get sortConfidence => 'Confianza';

  @override
  String get confidenceTooltip =>
      'Qué tan seguros están los agentes de que este hecho es cierto, de 0 a 100 %.';

  @override
  String get supersededTooltip =>
      'Un hecho más reciente ha reemplazado a este.';

  @override
  String get domain => 'Dominio';

  @override
  String get fitToView => 'Ajustar a la vista';

  @override
  String get project => 'Proyecto';

  @override
  String get projects => 'Proyectos';

  @override
  String get newProject => 'Nuevo proyecto';

  @override
  String get editProject => 'Editar proyecto';

  @override
  String get deleteProject => 'Eliminar proyecto';

  @override
  String get noProject => 'Sin proyecto';

  @override
  String get allTickets => 'Todos los tickets';

  @override
  String get projectNamePlaceholder => 'Nombre del proyecto';

  @override
  String get projectDescriptionPlaceholder => 'Descripción (opcional)';

  @override
  String get projectColorLabel => 'Color';

  @override
  String get noProjectsYet => 'Aún no hay proyectos';

  @override
  String get projectTicketsEmpty => 'Aún no hay tickets en este proyecto';

  @override
  String get createProject => 'Crear proyecto';

  @override
  String projectProgress(int done, int total) {
    return '$done de $total completados';
  }

  @override
  String deleteProjectConfirm(String name) {
    return '¿Eliminar «$name»? Sus tickets se conservan y se quitan del proyecto.';
  }

  @override
  String get projectStatusActive => 'Activo';

  @override
  String get projectStatusCompleted => 'Completado';

  @override
  String get projectStatusArchived => 'Archivado';

  @override
  String get markProjectCompleted => 'Marcar como completado';

  @override
  String get markProjectActive => 'Marcar como activo';

  @override
  String get archiveProject => 'Archivar';

  @override
  String get restoreProject => 'Restaurar';

  @override
  String get relations => 'Relaciones';

  @override
  String get relateTo => 'Relacionar con';

  @override
  String get relationSubIssueOf => 'Subtarea de…';

  @override
  String get relationParentOf => 'Padre de…';

  @override
  String get relationBlockedBy => 'Bloqueado por…';

  @override
  String get relationBlocking => 'Bloquea…';

  @override
  String get relationRelatedTo => 'Relacionado con…';

  @override
  String get relationDuplicateOf => 'Duplicado de…';

  @override
  String get relationGroupParent => 'Padre';

  @override
  String get relationGroupSubIssues => 'Subtareas';

  @override
  String get relationGroupBlockedBy => 'Bloqueado por';

  @override
  String get relationGroupBlocking => 'Bloquea';

  @override
  String get relationGroupRelated => 'Relacionado';

  @override
  String get relationGroupDuplicateOf => 'Duplicado de';

  @override
  String get relationGroupDuplicatedBy => 'Duplicado por';

  @override
  String get copyId => 'Copiar ID';

  @override
  String get ticketIdCopied => 'ID del ticket copiado';

  @override
  String get selectTicket => 'Seleccionar un ticket';

  @override
  String get searchTicketsHint => 'Buscar tickets…';

  @override
  String get noMatchingTickets => 'Ningún ticket coincide';

  @override
  String get addToProject => 'Añadir al proyecto';

  @override
  String get activeFleet => 'Flota activa';

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
  String get failedStatus => 'Fallido';

  @override
  String get neverRunStatus => 'Nunca ejecutado';

  @override
  String get noActiveRun => 'Sin ejecución activa';

  @override
  String get allPullRequests => 'Todas las pull requests';

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get needsYouNow => 'Te necesita ahora';

  @override
  String get pipelinesSectionTitle => 'Pipelines';

  @override
  String get allRuns => 'Todas las ejecuciones';

  @override
  String get triage => 'Clasificar';

  @override
  String agentsRunningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agentes en ejecución',
      one: '1 agente en ejecución',
    );
    return '$_temp0';
  }

  @override
  String blockedCountLabel(int count) {
    return '$count bloqueados';
  }

  @override
  String needsYouCountLabel(int count) {
    return '$count para ti';
  }

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PR pendientes',
      one: '1 PR pendiente',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos repositorios',
      one: '1 repositorio',
    );
    return '$_temp0 de tu revisión en $_temp1';
  }

  @override
  String reviewsAwaitingYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count revisiones',
      one: '1 revisión',
    );
    return '$_temp0 pendientes';
  }

  @override
  String reviewsOverTwoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count con más de 2 días',
      one: '1 con más de 2 días',
    );
    return '$_temp0';
  }

  @override
  String agentBlockedTitle(String name) {
    return '$name está bloqueado';
  }

  @override
  String get agentBlockedSubtitle => 'Esperando tu confirmación';

  @override
  String get pipelineFailedTitle => 'Pipeline fallido';

  @override
  String prStaleTitle(String number) {
    return 'PR $number obsoleta';
  }

  @override
  String get prStaleSubtitle => 'Sin actividad reciente';

  @override
  String get reviewRequestedBadge => 'Revisión solicitada';

  @override
  String get draftBadge => 'Borrador';

  @override
  String get staleLabel => 'Obsoleta';

  @override
  String stepsProgress(int done, int total) {
    return '$done de $total pasos';
  }

  @override
  String get allCaughtUpSubtitle =>
      'Ninguna revisión, bloqueo o fallo te necesita ahora mismo.';

  @override
  String dashboardGreetingNamed(String name) {
    return 'Grüezi, $name';
  }

  @override
  String workspaceEyebrow(String name) {
    return 'Espacio $name';
  }

  @override
  String get pipelineTriggerNode => 'Disparador';

  @override
  String get priorityReviewsTooltip =>
      'PR abiertas que solicitan tu revisión y llevan esperando más de 24 horas.';

  @override
  String get workspaceSettings => 'Ajustes del espacio de trabajo';

  @override
  String get manageWorkspacesSubtitle =>
      'Cambia el nombre de un espacio de trabajo y su marca: selecciona uno a la izquierda para editarlo.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count espacios de trabajo',
      one: '1 espacio de trabajo',
      zero: 'Sin espacios de trabajo',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos repos',
      one: '1 repo',
      zero: 'Sin repos',
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
  String get identity => 'Identidad';

  @override
  String get uploadImage => 'Subir imagen';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG o GIF de hasta 2 MB. De lo contrario, usaremos la inicial del espacio de trabajo.';

  @override
  String get workspaceNameFieldHelp =>
      'Se muestra en el selector, la ruta de navegación y en cada pantalla.';

  @override
  String get dangerZone => 'Zona de peligro';

  @override
  String get deleteThisWorkspace => 'Eliminar este espacio de trabajo';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Elimina permanentemente $name, sus conexiones de repositorio, agentes y memoria. Esto no se puede deshacer.';
  }

  @override
  String get discard => 'Descartar';

  @override
  String discardChangesQuestion(String name) {
    return '¿Descartar los cambios sin guardar de $name?';
  }

  @override
  String get workspaceUpdated => 'Espacio de trabajo actualizado';

  @override
  String get editTitle => 'Editar título';

  @override
  String get editDescription => 'Editar descripción';

  @override
  String get addDescription => 'Añadir una descripción';

  @override
  String get prTitlePlaceholder => 'Título';

  @override
  String get prBodyPlaceholder => 'Escribe una descripción';

  @override
  String get write => 'Escribir';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Vista previa';

  @override
  String get prTemplateLabel => 'Plantilla';

  @override
  String get prTemplateDefault => 'Predeterminada';

  @override
  String get addReviewers => 'Añadir revisores';

  @override
  String get addAssignees => 'Añadir asignados';

  @override
  String get searchUsers => 'Buscar personas…';

  @override
  String get searchReviewers => 'Buscar personas y equipos…';

  @override
  String get usersSectionLabel => 'Personas';

  @override
  String get teamsSectionLabel => 'Equipos';

  @override
  String get noMatchingUsers => 'No hay personas coincidentes';

  @override
  String get noMatchingReviewers => 'Sin coincidencias';

  @override
  String addCount(int count) {
    return 'Añadir ($count)';
  }

  @override
  String get requiredByCodeOwners =>
      'Requerido por los propietarios del código';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'vía $login';
  }

  @override
  String get team => 'Equipo';

  @override
  String get markdownBold => 'Negrita';

  @override
  String get markdownItalic => 'Cursiva';

  @override
  String get markdownHeading => 'Encabezado';

  @override
  String get markdownBulletList => 'Lista con viñetas';

  @override
  String get markdownChecklist => 'Lista de tareas';

  @override
  String get markdownCode => 'Código';

  @override
  String get markdownLink => 'Enlace';

  @override
  String get markdownQuote => 'Cita';

  @override
  String failedToUpdateTitle(String error) {
    return 'No se pudo actualizar el título: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'No se pudo actualizar la descripción: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'No se pudieron actualizar los revisores: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'No se pudieron actualizar los asignados: $error';
  }

  @override
  String get discardChangesConfirm => '¿Descartar los cambios?';

  @override
  String get newPr => 'Nueva PR';

  @override
  String get openPullRequest => 'Abrir una pull request';

  @override
  String get composePrSubtitle =>
      'Desde una rama que has subido — sin agentes ni tickets';

  @override
  String get createAsDraft => 'Crear como borrador';

  @override
  String get composePrNoRepo => 'Ningún repositorio de GitHub seleccionado';

  @override
  String get composePrNoRepoHint =>
      'Selecciona un espacio de trabajo con un repositorio vinculado a GitHub para abrir una pull request.';

  @override
  String get composePrPickBranches =>
      'Elige una rama base y una rama de comparación para previsualizar los cambios.';

  @override
  String get composePrNothingToCompare => 'No hay cambios entre estas ramas.';

  @override
  String get repository => 'Repositorio';

  @override
  String get baseBranchLabel => 'Base';

  @override
  String get compareBranchLabel => 'Comparar';

  @override
  String get selectBranch => 'Selecciona una rama';

  @override
  String get navMeetings => 'Reuniones';

  @override
  String get meetingsNoWorkspace =>
      'Selecciona un espacio de trabajo para ver las reuniones.';

  @override
  String get meetingsEmpty =>
      'Aún no hay reuniones. Inicia una grabación para capturar una.';

  @override
  String get meetingsStartRecording => 'Iniciar grabación';

  @override
  String get meetingsStopRecording => 'Detener grabación';

  @override
  String get meetingsProcessing => 'Resumiendo…';

  @override
  String get meetingEnhancedNotes => 'Notas mejoradas';

  @override
  String get meetingYourNotes => 'Tus notas';

  @override
  String get meetingNotesHint =>
      'Anota notas rápidas: el agente las ampliará tras la reunión.';

  @override
  String get meetingTranscriptTitle => 'Transcripción';

  @override
  String get meetingNoTranscriptYet =>
      'La transcripción aparece aquí a medida que la gente habla.';

  @override
  String get meetingSpeakerMe => 'Tú';

  @override
  String get meetingSpeakerThem => 'Ellos';

  @override
  String get meetingStatusRecording => 'Grabando';

  @override
  String get meetingStatusProcessing => 'Procesando';

  @override
  String get meetingStatusDone => 'Listo';

  @override
  String get meetingStatusFailed => 'Error';

  @override
  String get keybindingGoToMeetings => 'Ir a reuniones';

  @override
  String get keybindingNavigateToTheMeetingsDescription =>
      'Navegar a la lista de reuniones';

  @override
  String get meetingsOverlineKnowledge => 'Conocimiento';

  @override
  String get meetingsOverlineEngine => 'En el dispositivo · Whisper base.en';

  @override
  String get meetingsSubtitle =>
      'Captura local de tus reuniones. Captamos el audio de la reunión y tu micrófono, transcribimos en el dispositivo y dejamos que un agente convierta tus notas dispersas en decisiones y tareas — ningún bot se une nunca a la llamada.';

  @override
  String get meetingsRecordMeeting => 'Grabar reunión';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count procesándose ahora',
      one: '1 procesándose ahora',
    );
    return '$_temp0';
  }

  @override
  String get meetingsStatThisWeek => 'Esta semana';

  @override
  String get meetingsStatThisWeekUnit => 'reuniones capturadas';

  @override
  String get meetingsStatRecorded => 'Grabado';

  @override
  String get meetingsStatRecordedUnit => 'transcrito localmente';

  @override
  String get meetingsStatOpen => 'Abiertas';

  @override
  String get meetingsStatOpenUnit => 'tareas pendientes';

  @override
  String get meetingsStatLogged => 'Registradas';

  @override
  String get meetingsStatLoggedUnit => 'decisiones extraídas';

  @override
  String get meetingsCaptureTitle =>
      'La captura de audio del sistema sin controladores está lista.';

  @override
  String get meetingsCaptureBody =>
      'Control Center capta la salida de altavoz de la aplicación en la que estés — Slack Huddle, Meet, Zoom, Tuple — además de tu micrófono, y decodifica ambos flujos en este dispositivo.';

  @override
  String get meetingsCapturePermission => 'Permiso concedido';

  @override
  String get meetingsCaptureOnDevice => '100 % en el dispositivo';

  @override
  String get meetingsCaptureNoBot => 'Ningún bot se une';

  @override
  String get meetingsScopeAll => 'Todas las reuniones';

  @override
  String get meetingsFilterAll => 'Todas';

  @override
  String get meetingsFilterDone => 'Completadas';

  @override
  String get meetingsFilterProcessing => 'En proceso';

  @override
  String get meetingsSearchHint => 'Filtrar por título, persona, aplicación…';

  @override
  String get meetingsBucketToday => 'Hoy';

  @override
  String get meetingsBucketYesterday => 'Ayer';

  @override
  String get meetingsBucketEarlierThisWeek => 'Antes esta semana';

  @override
  String get meetingsBucketLastWeek => 'La semana pasada';

  @override
  String get meetingsBucketOlder => 'Más antiguas';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count decisiones',
      one: '1 decisión',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total tareas';
  }

  @override
  String get meetingsEnhancedPill => 'mejorada';

  @override
  String get meetingsTranscribing => 'transcribiendo y resumiendo…';

  @override
  String get meetingsOpenAction => 'Abrir';

  @override
  String get meetingsStopProcessing => 'Detener';

  @override
  String get meetingsStillTranscribing =>
      'Aún transcribiendo — el resumen aparecerá cuando termine.';

  @override
  String get meetingsNoMatch => 'Ninguna reunión coincide';

  @override
  String get meetingsNoMatchHint =>
      'Prueba con otro filtro o término de búsqueda.';

  @override
  String get meetingBackAllMeetings => 'Todas las reuniones';

  @override
  String meetingPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas',
      one: '1 persona',
    );
    return '$_temp0';
  }

  @override
  String get meetingReRunSummary => 'Rehacer resumen';

  @override
  String get meetingExport => 'Exportar';

  @override
  String get meetingAugmentingBanner =>
      'Mejorando tus notas a partir de la transcripción — extrayendo decisiones y tareas…';

  @override
  String get meetingTabNotes => 'Notas';

  @override
  String get meetingTabTranscript => 'Transcripción';

  @override
  String get meetingTabActionItems => 'Tareas';

  @override
  String get meetingTabDecisions => 'Decisiones';

  @override
  String get meetingNotesEnhancedToggle => 'Mejoradas';

  @override
  String get meetingNotesYoursToggle => 'Tus notas';

  @override
  String get meetingEnhancedByAgent =>
      'Mejorado por el agente · a partir de la transcripción';

  @override
  String get meetingEnhancedPending =>
      'El agente aún está trabajando en este resumen.';

  @override
  String get meetingNotesEmpty => 'Aún no hay notas mejoradas.';

  @override
  String get meetingNotesSavedLocally => 'Guardado localmente';

  @override
  String get meetingNotesSaving => 'Guardando…';

  @override
  String get meetingViewFullTranscript => 'Ver transcripción completa';

  @override
  String get meetingTranscriptSearchHint => 'Buscar en la transcripción…';

  @override
  String get meetingSpeakerEveryone => 'Todos';

  @override
  String get meetingSpeakerOthers => 'Otros';

  @override
  String get meetingTranscriptEmpty => 'Aún no hay transcripción.';

  @override
  String get meetingActionItemsEmpty => 'No se extrajeron tareas.';

  @override
  String get meetingActionItemFrom => 'de esta reunión';

  @override
  String get meetingCreateTicket => 'Crear ticket';

  @override
  String meetingTicketCreated(String key) {
    return 'Ticket $key creado y enviado.';
  }

  @override
  String get meetingTicketFailed => 'No se pudo crear el ticket.';

  @override
  String get meetingDecisionsEmpty => 'No hay decisiones registradas.';

  @override
  String get meetingReRunStarted =>
      'Rehaciendo el resumen sobre la transcripción…';

  @override
  String get meetingReRunDone => 'Resumen actualizado.';

  @override
  String get meetingReRunNoTranscript =>
      'Todavía no hay transcripción para resumir.';

  @override
  String get meetingExportCopied =>
      'Notas copiadas al portapapeles en Markdown.';

  @override
  String get meetingExportNothing => 'Aún no hay nada que exportar.';

  @override
  String get meetingsRecordingCrumb => 'Grabando…';

  @override
  String get meetingRecordTitleHint => 'Título de la reunión';

  @override
  String get meetingRecordTappingLabel => 'Captando:';

  @override
  String get meetingRecordMic => 'Micrófono';

  @override
  String get meetingRecordSystemAudio => 'Audio del sistema';

  @override
  String get meetingRecordPause => 'Pausar';

  @override
  String get meetingRecordResume => 'Reanudar';

  @override
  String get meetingRecordStop => 'Detener y resumir';

  @override
  String get meetingRecordYourNotes => 'Tus notas';

  @override
  String get meetingRecordNotesTagline =>
      'anota lo justo — el agente completa el resto';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Escribe mientras escuchas. Unos pocos fragmentos bastan — tras detener, el agente los amplía con la transcripción.';

  @override
  String get meetingRecordLiveTranscript => 'Transcripción en vivo';

  @override
  String get meetingRecordDecoding => 'decodificando en el dispositivo';

  @override
  String get meetingRecordListening =>
      'Escuchando… el habla aparecerá aquí en uno o dos segundos, etiquetada como Tú / Otros.';

  @override
  String get meetingRecordPausedHint =>
      'En pausa — el audio se ignora hasta que reanudes.';

  @override
  String get meetingRecordNotActive => 'No hay grabación activa.';

  @override
  String get meetingHudRecording => 'grabando';

  @override
  String get meetingHudPaused => 'en pausa';

  @override
  String get meetingHudOpen => 'Abrir';

  @override
  String get meetingHudStop => 'Detener';
}
