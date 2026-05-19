// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get succeeded => 'Completado';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'Reintento n.º $number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'Iniciando · $time';
  }

  @override
  String get agentActivityFollowingLive => 'Siguiendo la actividad en vivo';

  @override
  String get agentActivityJumpToLatest => 'Ir a lo más reciente';

  @override
  String get agentActivityLoadFailed =>
      'No se pudo cargar la actividad de esta ejecución';

  @override
  String get agentActivityNotRecorded =>
      'No se registró actividad para esta ejecución';

  @override
  String get agentActivityNotRecordedHint =>
      'Las ejecuciones que terminaron antes de habilitar la captura de actividad no tienen cronología.';

  @override
  String get agentActivityRunUnavailable =>
      'Esta ejecución ya no está disponible';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'Subagente de $agent';
  }

  @override
  String get agentActivityUnsupported =>
      'La captura de actividad no está disponible en el servidor conectado';

  @override
  String get agentActivityUnsupportedHint =>
      'Reinicia la aplicación para que use la última versión del servidor.';

  @override
  String get agentActivityWaiting => 'Esperando actividad…';

  @override
  String get created => 'Creado';

  @override
  String get dictationStart => 'Iniciar dictado';

  @override
  String get dictationListening => 'Escuchando…';

  @override
  String get dictationUnavailable =>
      'El dictado necesita un modelo de voz en el servidor host. Configura uno en los ajustes de voz.';

  @override
  String get dictationFailedToStart => 'No se pudo iniciar el dictado';

  @override
  String get dictationHoldToTalkTitle => 'Mantener para hablar';

  @override
  String get dictationHoldToTalkDescription =>
      'Mantén pulsado el botón del micrófono o el atajo para dictar y suéltalo para detener. Si está desactivado, pulsa una vez para iniciar y otra para detener.';

  @override
  String get focusConversation => 'Enfocar la conversación';

  @override
  String get ideAgentActivity => 'Actividad del agente';

  @override
  String get keybindingPushToTalk => 'Pulsar para hablar';

  @override
  String get keybindingPushToTalkDescription =>
      'Mantener o alternar el dictado de voz en el compositor de mensajes';

  @override
  String get agentPermissions => 'Permisos de agentes';

  @override
  String get agentPermissionsSettingsDescription =>
      'Decide qué pueden hacer los agentes por su cuenta, qué deben preguntar primero o qué no pueden hacer nunca, por espacio de trabajo, agente o canal.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Establece una decisión para cada tipo de efecto. Las reglas se heredan: el canal prevalece sobre el agente, que prevalece sobre el espacio de trabajo.';

  @override
  String get guardrailLoading => 'Cargando reglas…';

  @override
  String get guardrailRulesLoadFailed =>
      'No se pudieron cargar las reglas de permisos.';

  @override
  String get guardrailScopeWorkspace => 'Espacio de trabajo';

  @override
  String get guardrailScopeAgent => 'Agente';

  @override
  String get guardrailScopeChannel => 'Canal';

  @override
  String get guardrailSelectAgent => 'Selecciona un agente';

  @override
  String get guardrailSelectChannel => 'Selecciona un canal';

  @override
  String get guardrailNoAgents =>
      'Aún no hay agentes en este espacio de trabajo.';

  @override
  String get guardrailNoChannels =>
      'Aún no hay canales en este espacio de trabajo.';

  @override
  String get guardrailClassFileDelete => 'Eliminar un archivo';

  @override
  String get guardrailClassFileWriteOutsideWorktree =>
      'Escribir fuera del árbol de trabajo';

  @override
  String get guardrailClassGitCommit => 'Crear un commit';

  @override
  String get guardrailClassGitPush => 'Enviar a un remoto';

  @override
  String get guardrailClassPrCreate => 'Abrir una pull request';

  @override
  String get guardrailClassPrPublish => 'Publicar una revisión o fusionar';

  @override
  String get guardrailClassVendorSyncWrite =>
      'Escribir en un rastreador externo';

  @override
  String get guardrailClassNetworkEgress => 'Acceder a la red';

  @override
  String get guardrailClassSecretAccess => 'Leer un secreto';

  @override
  String get guardrailClassPackageInstall => 'Instalar un paquete';

  @override
  String get guardrailClassProcessSpawn => 'Ejecutar un proceso';

  @override
  String get guardrailClassWorkspaceMutation =>
      'Cambiar la estructura del espacio de trabajo';

  @override
  String get guardrailDecisionAllow => 'Permitir';

  @override
  String get guardrailDecisionPrompt => 'Preguntar primero';

  @override
  String get guardrailDecisionDeny => 'Denegar';

  @override
  String get guardrailSourceThisScope => 'Este ámbito';

  @override
  String get guardrailSourceDefault => 'Valor predeterminado';

  @override
  String get guardrailSourcePreset => 'Preajuste del modo';

  @override
  String get guardrailSourceInherited => 'Heredado';

  @override
  String get guardrailClearToInherited => 'Restablecer al valor heredado';

  @override
  String get guardrailWhatIf => '¿Qué pasaría si?';

  @override
  String get guardrailWhatIfDescription =>
      'Comprueba cómo resolverían las reglas actuales una acción, con la misma lógica que se aplica a los agentes.';

  @override
  String get guardrailProbeActionLabel => 'Acción';

  @override
  String get guardrailProbeCommandLabel => 'Comando (opcional)';

  @override
  String get guardrailProbeCommandHint => 'p. ej. git push origin main';

  @override
  String get guardrailProbeAgentLabel => 'Agente (opcional)';

  @override
  String get guardrailProbeChannelLabel => 'Canal (opcional)';

  @override
  String get guardrailProbeNone => 'Ninguno';

  @override
  String get guardrailProbeModeLabel => 'Modo';

  @override
  String get guardrailProbeResult => 'Resultado';

  @override
  String get guardrailProbeSource => 'Origen:';

  @override
  String get guardrailAdapterMatrix => 'Dónde se aplican las reglas';

  @override
  String get guardrailAdapterMatrixDescription =>
      'Referencia honesta: dónde se intercepta realmente cada efecto, según el ejecutor del agente. Documenta la realidad, no una garantía: los efectos que un ejecutor realiza por fuera no se pueden interceptar.';

  @override
  String get guardrailEffectColumn => 'Efecto';

  @override
  String get guardrailAdapterHarness => 'Arnés integrado';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'Base del entorno aislado';

  @override
  String get guardrailEnforcementPolicyGate => 'Control por política';

  @override
  String get guardrailEnforcementSandbox => 'Solo entorno aislado';

  @override
  String get guardrailEnforcementNone => 'No aplicable';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'La decisión de permiso se comprueba antes de que se ejecute el efecto y puede bloquearlo.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'Solo el entorno aislado lo limita; no se consulta la regla de permiso.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'La decisión es solo orientativa: no se puede interceptar aquí.';

  @override
  String get obsStatCost => 'coste';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount delegado';
  }

  @override
  String get obsStatDuration => 'duración';

  @override
  String get obsStatTokens => 'tokens';

  @override
  String get obsStatTools => 'herramientas';

  @override
  String get openAgentActivity => 'Abrir actividad';

  @override
  String get orgChart => 'Organigrama';

  @override
  String get orgChartEmpty => 'Aún no hay agentes';

  @override
  String get navCalendar => 'Calendario';

  @override
  String get serverConnection => 'Conexión al servidor';

  @override
  String get serverConnectionMode => 'Modo';

  @override
  String get serverModeLocal => 'Ejecutar en esta aplicación';

  @override
  String get serverModeLocalDescription =>
      'Control Center ejecuta su propio servidor en este equipo y conserva tus datos localmente.';

  @override
  String get serverModeRemote => 'Conectar a una instancia remota';

  @override
  String get serverModeRemoteDescription =>
      'Conéctate a un servidor de Control Center que se ejecuta en otro lugar. Tus datos residen en ese servidor.';

  @override
  String get serverRemoteUrl => 'URL del servidor';

  @override
  String get serverRemoteDeviceId => 'Id. del dispositivo';

  @override
  String get serverRemotePairingKey => 'Clave de emparejamiento';

  @override
  String get serverRemotePairingKeyHint =>
      'Pega la clave de emparejamiento del servidor remoto';

  @override
  String get serverSetupInviteCode => 'Código de invitación';

  @override
  String get serverSetupInviteCodeHint =>
      'Pega un código de invitación de un solo uso (déjalo vacío para usar una clave de emparejamiento)';

  @override
  String get serverDiscoveryTooltip => 'Buscar servidores en tu red';

  @override
  String get serverDiscoveryTitle => 'Servidores en tu red';

  @override
  String get serverDiscoverySearching => 'Buscando servidores…';

  @override
  String get serverDiscoveryEmpty =>
      'No se encontraron servidores. Comprueba que el servidor esté en ejecución y que este dispositivo pueda alcanzarlo, y vuelve a buscar.';

  @override
  String get serverDiscoveryRefresh => 'Buscar de nuevo';

  @override
  String get serverListActive => 'Activo';

  @override
  String get serverListSwitch => 'Cambiar';

  @override
  String get serverListAddTitle => 'Añadir servidor';

  @override
  String get serverListRemoveActiveHint =>
      'Cambia a otro servidor antes de eliminar este.';

  @override
  String get serverSwitchFailedTitle => 'No se pudo cambiar de servidor';

  @override
  String get serverListInsecureBadge => 'No seguro';

  @override
  String get connectionPathLocal => 'Local';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'Apagando';

  @override
  String get shutdownSubtitle => 'Cerrando el servidor local';

  @override
  String get shutdownServiceApprovals => 'Aprobaciones';

  @override
  String get shutdownServiceBackgroundJobs => 'Tareas en segundo plano';

  @override
  String get shutdownServiceScheduler => 'Planificador de tareas';

  @override
  String get shutdownServiceCalendar => 'Sincronización del calendario';

  @override
  String get shutdownServiceWeather => 'Clima';

  @override
  String get shutdownServiceSoundscape => 'Paisaje sonoro';

  @override
  String get shutdownServiceMeetings => 'Reuniones';

  @override
  String get shutdownServiceVoiceModels => 'Modelos de voz';

  @override
  String get shutdownServiceNetworking => 'Red';

  @override
  String get shutdownServicePresence => 'Presencia';

  @override
  String get shutdownServiceDataSync => 'Sincronización de datos';

  @override
  String get shutdownServiceDeviceRelay => 'Retransmisión de dispositivos';

  @override
  String get shutdownServiceMcpConnections => 'Conexiones MCP';

  @override
  String get shutdownServiceCodeEditors => 'Editores de código';

  @override
  String get serverSharingTitle => 'Compartir este servidor';

  @override
  String get serverSharingDescription =>
      'Haz que este servidor sea accesible desde tus otros dispositivos. No se expone nada públicamente a menos que actives un túnel más abajo. Las invitaciones de vinculación incluyen automáticamente las direcciones actuales del servidor; créalas en los ajustes del espacio de trabajo.';

  @override
  String get serverSharingUnavailable =>
      'Los controles para compartir no están disponibles en este servidor.';

  @override
  String get serverSharingMdnsLabel => 'Descubrimiento LAN';

  @override
  String get serverSharingMdnsOn =>
      'Anunciando este servidor en tu red local (mDNS)';

  @override
  String get serverSharingMdnsOff =>
      'Este servidor no se anuncia en tu red local (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'Túnel';

  @override
  String get serverSharingTunnelHelper =>
      'Activar un túnel hace que este servidor sea accesible desde internet. La exposición pública es opcional y está desactivada por defecto.';

  @override
  String get serverSharingProviderOff => 'Desactivado';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'URL pública';

  @override
  String get serverSharingTunnelStarting => 'Iniciando el túnel…';

  @override
  String serverSharingTunnelError(String error) {
    return 'Error del túnel: $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'El túnel está activo. Accede a él mediante tu nombre de host DNS configurado.';

  @override
  String get serverSharingRelayLabel => 'Retransmisión';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'Retransmitido este mes: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'Sesiones de retransmisión activas: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle =>
      'No se pudo actualizar el uso compartido';

  @override
  String get serverConnectionRestartHint =>
      'Reinicia Control Center para aplicar los cambios de conexión.';

  @override
  String get serverConnectionReloadHint =>
      'Recarga la página para volver a conectar con estos cambios.';

  @override
  String get pairNewClient => 'Vincular un nuevo cliente';

  @override
  String get pairClientNameHint =>
      'Asigna un nombre a este cliente (p. ej. Portátil de trabajo)';

  @override
  String get pairClientTypeWeb => 'Navegador web';

  @override
  String get pairClientTypeDesktop => 'Aplicación de escritorio';

  @override
  String get pairClientTypePhone => 'Teléfono';

  @override
  String get pairAction => 'Vincular';

  @override
  String get revoke => 'Revocar';

  @override
  String get pairCredentialsIntro =>
      'Conecta el nuevo cliente con estos datos, o abre el enlace en él.';

  @override
  String get pairLinkLabel => 'Enlace';

  @override
  String get pairScanQr =>
      'Escanea este código QR con la cámara de tu teléfono para vincularlo.';

  @override
  String get pairServerUnreachableTitle => 'No accesible';

  @override
  String get pairServerUnreachable =>
      'Otros dispositivos no pueden acceder a este servidor directamente, así que un nuevo cliente no puede conectarse. Configura la URL pública del servidor para vincular más clientes.';

  @override
  String get serverSetupTitle => '¿Cómo debe ejecutarse Control Center?';

  @override
  String get serverSetupSubtitle =>
      'Control Center necesita un servidor que sea el propietario de tus datos. Ejecuta uno en esta aplicación o conéctate a una instancia que se ejecute en otro lugar.';

  @override
  String get serverSetupRunLocal => 'Ejecutar en esta aplicación';

  @override
  String get serverSetupConnect => 'Conectar';

  @override
  String get serverSetupInvalidUrl =>
      'Introduce una URL de servidor ws:// o wss:// válida.';

  @override
  String get serverSetupCouldNotConnect => 'No se pudo conectar';

  @override
  String get serverSetupErrorUnreachable =>
      'No pudimos contactar con el servidor. Comprueba que esté en ejecución y que este dispositivo pueda alcanzarlo (misma red o relé).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'La identidad del servidor no coincide con la guardada en este dispositivo. Si el servidor se reinstaló o se restableció, elimina el servidor guardado y vuelve a emparejar.';

  @override
  String get serverSetupErrorAuthRejected =>
      'El servidor rechazó este dispositivo. Comprueba que la clave de emparejamiento y el id del dispositivo coincidan con los que emitió el servidor.';

  @override
  String get serverSetupErrorInviteRejected =>
      'Ese código de invitación no es válido o ha caducado. Pide uno nuevo.';

  @override
  String get serverSetupErrorGeneric =>
      'Algo salió mal al conectar. Despliega los detalles técnicos a continuación para más información.';

  @override
  String get serverSetupErrorDetails => 'Detalles técnicos';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count más',
      one: '1 más',
    );
    return '$_temp0';
  }

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
  String get calendarClientIdLabel => 'ID de cliente';

  @override
  String get calendarClientSecretLabel => 'Secreto de cliente';

  @override
  String get calendarConnectCredsHint =>
      'Introduce el ID de cliente y el secreto OAuth (device-code) de tu proyecto de Google. El servidor gestiona la conexión y la sincronización; tu navegador nunca guarda los tokens.';

  @override
  String get calendarConnectApproveInstruction =>
      'Abre la página de verificación en cualquier dispositivo, inicia sesión e introduce este código:';

  @override
  String get calendarConnectOpenPage => 'Abrir página de verificación';

  @override
  String get calendarConnectWaiting => 'Esperando aprobación…';

  @override
  String get calendarConnectDenied =>
      'Se denegó la autorización. Inténtalo de nuevo.';

  @override
  String get calendarConnectExpired => 'El código caducó. Inténtalo de nuevo.';

  @override
  String get calendarNotConfigured =>
      'Google Calendar no está configurado. Define GOOGLE_OAUTH_CLIENT_ID para conectar una cuenta.';

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
  String get byAuthorPrefix => 'por';

  @override
  String get stopAgentRun => 'Detener ejecución';

  @override
  String get stopAgentRunConfirm =>
      '¿Detener esta ejecución? Se perderá el trabajo en curso.';

  @override
  String get youLabel => 'tú';

  @override
  String get readyToMerge => 'Listo para fusionar';

  @override
  String get inProgress => 'En curso';

  @override
  String get needsAttention => 'Requiere atención';

  @override
  String get drafts => 'Borradores';

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
  String get prFilterTooltip => 'Filtrar';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filtros activos',
      one: '1 filtro activo',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'Añadir filtro…';

  @override
  String get prFilterFieldHint => 'Filtrar…';

  @override
  String get prFilterCategoryStatus => 'Estado';

  @override
  String get prFilterCategoryAuthor => 'Autor';

  @override
  String get prFilterCategoryReviewer => 'Revisores';

  @override
  String get prFilterCategoryContent => 'Contenido';

  @override
  String get prFilterCategoryRepoOwner => 'Propietario del repositorio';

  @override
  String get prFilterCategoryRepoName => 'Nombre del repositorio';

  @override
  String get prFilterCategoryOpenedDate => 'Fecha de apertura';

  @override
  String get prFilterCategoryUpdatedDate => 'Fecha de actualización';

  @override
  String get prFilterQuickToReview => 'Rápida de revisar';

  @override
  String get prFilterClearAll => 'Borrar filtros';

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
      other: '$count opciones que no coinciden con ninguna pull request',
      one: '1 opción que no coincide con ninguna pull request',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'El título o el cuerpo contiene…';

  @override
  String get prFilterNoOptions => 'No hay opciones coincidentes';

  @override
  String get prFilterChipIs => 'es';

  @override
  String get prFilterChipIsAnyOf => 'es uno de';

  @override
  String get prFilterChipContains => 'contiene';

  @override
  String get prFilterChipSince => 'desde';

  @override
  String get prFilterAddFilterButton => 'Añadir filtro';

  @override
  String prFilterClearCategory(String category) {
    return 'Borrar filtro de $category';
  }

  @override
  String get prFilterCurrentUser => 'Usuario actual';

  @override
  String get prStatusDraft => 'Borrador';

  @override
  String get prStatusOpen => 'Abierto';

  @override
  String get prStatusInReview => 'En revisión';

  @override
  String get prStatusChangesRequested => 'Cambios solicitados';

  @override
  String get prStatusApproved => 'Aprobado';

  @override
  String get prStatusMerged => 'Fusionado';

  @override
  String get prStatusClosed => 'Cerrado';

  @override
  String get prDateWindowDay => 'hace 1 día';

  @override
  String get prDateWindowThreeDays => 'hace 3 días';

  @override
  String get prDateWindowWeek => 'hace 1 semana';

  @override
  String get prDateWindowMonth => 'hace 1 mes';

  @override
  String get prDateWindowThreeMonths => 'hace 3 meses';

  @override
  String get prDateWindowSixMonths => 'hace 6 meses';

  @override
  String get prDateWindowYear => 'hace 1 año';

  @override
  String get prDisplayOptions => 'Opciones de visualización';

  @override
  String get prDisplayGrouping => 'Agrupación';

  @override
  String get prDisplayOrdering => 'Orden';

  @override
  String get prDisplayShowDrafts => 'Mostrar borradores';

  @override
  String get prDisplayMergedWindow => 'Ventana de fusión';

  @override
  String get prDisplayMergedWindowDay => 'Último día';

  @override
  String get prDisplayMergedWindowWeek => 'Última semana';

  @override
  String get prDisplayMergedWindowMonth => 'Último mes';

  @override
  String get prDisplayProperties => 'Propiedades de visualización';

  @override
  String get prGroupingRepository => 'Repositorio';

  @override
  String get prGroupingAuthor => 'Autor';

  @override
  String get prGroupingStatus => 'Estado';

  @override
  String get prGroupingNone => 'Sin agrupación';

  @override
  String get prPropertyRepository => 'Repositorio';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'Rama';

  @override
  String get prPropertyUpdated => 'Actualizado';

  @override
  String get prPropertyAuthor => 'Autor';

  @override
  String get prPropertyChecks => 'Comprobaciones';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'Comentarios';

  @override
  String get prGroupUnknownAuthor => 'Autor desconocido';

  @override
  String get keybindingOpenFilterMenu => 'Abrir el menú de filtros';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'Abrir el menú de filtros de PR';

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
      'Nomenclatura de ramas, búsqueda semántica, conexión al servidor, comportamiento del sistema y registro.';

  @override
  String get agentRegistry => 'Registro de agentes';

  @override
  String get settingsGroupGeneral => 'General';

  @override
  String get settingsGroupAgents => 'Agentes';

  @override
  String get settingsGroupResources => 'Recursos';

  @override
  String get settingsGroupWorkspace => 'Espacio de trabajo';

  @override
  String get settingsGroupSystem => 'Sistema';

  @override
  String get settingsGroupIntegrations => 'Integraciones';

  @override
  String get accounts => 'Cuentas';

  @override
  String get accountsSettingsDescription =>
      'Cuentas de GitHub, ticketing, calendario y chat.';

  @override
  String get mcpServers => 'Servidores MCP';

  @override
  String get mcpServersSettingsDescription =>
      'Servidor MCP integrado y servidores MCP externos.';

  @override
  String get remoteControlAndDevices => 'Control remoto y dispositivos';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'Empareja teléfonos y configura el servidor de control remoto.';

  @override
  String get voiceAndMeetings => 'Voz y reuniones';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'Transcripción, diarización, perfiles de voz y plantillas de reuniones.';

  @override
  String get securityAndPrivacy => 'Seguridad y privacidad';

  @override
  String get securityAndPrivacySettingsDescription =>
      'Sandboxing, reglas de comandos y privacidad.';

  @override
  String get filterSettingsHint => 'Filtrar ajustes';

  @override
  String get needsSetupLabel => 'Requiere configuración';

  @override
  String noSettingsMatch(String query) {
    return 'Ningún ajuste coincide con «$query»';
  }

  @override
  String get collapseSidebar => 'Contraer la barra lateral';

  @override
  String get expandSidebar => 'Expandir la barra lateral';

  @override
  String get filterChannelsHint => 'Filtrar canales';

  @override
  String noChannelsMatch(String query) {
    return 'Ningún canal coincide con «$query»';
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
  String get copyRelativePath => 'Copiar ruta relativa';

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
  String get activitySearchHint => 'Buscar en la actividad';

  @override
  String get activityNoMatches => 'Ninguna actividad coincide con tus filtros';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end de $total';
  }

  @override
  String get activityPreviousPage => 'Página anterior';

  @override
  String get activityNextPage => 'Página siguiente';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'Borrar filtro';

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
      'Guardó el logo del espacio de trabajo';

  @override
  String activityVerbCreated(String target) {
    return 'Creó $target';
  }

  @override
  String activityVerbUpdated(String target) {
    return 'Actualizó $target';
  }

  @override
  String activityVerbDeleted(String target) {
    return 'Eliminó $target';
  }

  @override
  String activityVerbAdded(String target) {
    return 'Añadió $target';
  }

  @override
  String activityVerbRemoved(String target) {
    return 'Quitó $target';
  }

  @override
  String activityVerbInvited(String target) {
    return 'Invitó a $target';
  }

  @override
  String activityVerbRevoked(String target) {
    return 'Revocó $target';
  }

  @override
  String activityVerbChanged(String target) {
    return 'Cambió $target';
  }

  @override
  String activityVerbStarted(String target) {
    return 'Inició $target';
  }

  @override
  String activityVerbStopped(String target) {
    return 'Detuvo $target';
  }

  @override
  String activityVerbWrote(String target) {
    return 'Escribió $target';
  }

  @override
  String get activityTargetAgent => 'un agente';

  @override
  String get activityTargetTicket => 'un ticket';

  @override
  String get activityTargetWorkspace => 'un espacio de trabajo';

  @override
  String get activityTargetRepository => 'un repositorio';

  @override
  String get activityTargetMember => 'un miembro';

  @override
  String get activityTargetInvite => 'una invitación';

  @override
  String get activityTargetChannel => 'un canal';

  @override
  String get activityTargetMessage => 'un mensaje';

  @override
  String get activityTargetCache => 'un caché';

  @override
  String get activityTargetFile => 'un archivo';

  @override
  String get activityTargetPipeline => 'un pipeline';

  @override
  String get activityTargetTemplate => 'una plantilla';

  @override
  String get activityTargetProvider => 'un proveedor';

  @override
  String get activityTargetModel => 'un modelo';

  @override
  String get activityTargetSkill => 'una habilidad';

  @override
  String get activityTargetTodo => 'una tarea';

  @override
  String get activityTargetMeeting => 'una reunión';

  @override
  String get activityTargetProject => 'un proyecto';

  @override
  String get activityTargetTeam => 'un equipo';

  @override
  String get activityTargetDevice => 'un dispositivo';

  @override
  String get activityTargetPreference => 'una preferencia';

  @override
  String get activityTargetBudget => 'un presupuesto';

  @override
  String activityVerbApproved(String target) {
    return 'Aprobó $target';
  }

  @override
  String activityVerbArchived(String target) {
    return 'Archivó $target';
  }

  @override
  String activityVerbAssigned(String target) {
    return 'Asignó $target';
  }

  @override
  String activityVerbBackedUp(String target) {
    return 'Respaldó $target';
  }

  @override
  String activityVerbCancelled(String target) {
    return 'Canceló $target';
  }

  @override
  String activityVerbCleared(String target) {
    return 'Borró $target';
  }

  @override
  String activityVerbClosed(String target) {
    return 'Cerró $target';
  }

  @override
  String activityVerbCommitted(String target) {
    return 'Hizo commit de $target';
  }

  @override
  String activityVerbCompacted(String target) {
    return 'Compactó $target';
  }

  @override
  String activityVerbCompleted(String target) {
    return 'Completó $target';
  }

  @override
  String activityVerbConnected(String target) {
    return 'Conectó $target';
  }

  @override
  String activityVerbContinued(String target) {
    return 'Continuó $target';
  }

  @override
  String activityVerbDisconnected(String target) {
    return 'Desconectó $target';
  }

  @override
  String activityVerbDispatched(String target) {
    return 'Despachó $target';
  }

  @override
  String activityVerbDrained(String target) {
    return 'Drenó $target';
  }

  @override
  String activityVerbEnrolled(String target) {
    return 'Inscribió $target';
  }

  @override
  String activityVerbEstimated(String target) {
    return 'Estimó $target';
  }

  @override
  String activityVerbImported(String target) {
    return 'Importó $target';
  }

  @override
  String activityVerbInstalled(String target) {
    return 'Instaló $target';
  }

  @override
  String activityVerbKilled(String target) {
    return 'Terminó $target';
  }

  @override
  String activityVerbMarked(String target) {
    return 'Marcó $target';
  }

  @override
  String activityVerbMerged(String target) {
    return 'Fusionó $target';
  }

  @override
  String activityVerbOpened(String target) {
    return 'Abrió $target';
  }

  @override
  String activityVerbPaused(String target) {
    return 'Pausó $target';
  }

  @override
  String activityVerbPolled(String target) {
    return 'Sondeó $target';
  }

  @override
  String activityVerbPrepared(String target) {
    return 'Preparó $target';
  }

  @override
  String activityVerbProcessed(String target) {
    return 'Procesó $target';
  }

  @override
  String activityVerbPublished(String target) {
    return 'Publicó $target';
  }

  @override
  String activityVerbRefined(String target) {
    return 'Refinó $target';
  }

  @override
  String activityVerbRefreshed(String target) {
    return 'Refrescó $target';
  }

  @override
  String activityVerbRegistered(String target) {
    return 'Registró $target';
  }

  @override
  String activityVerbRenamed(String target) {
    return 'Renombró $target';
  }

  @override
  String activityVerbReordered(String target) {
    return 'Reordenó $target';
  }

  @override
  String activityVerbResponded(String target) {
    return 'Respondió a $target';
  }

  @override
  String activityVerbRestored(String target) {
    return 'Restauró $target';
  }

  @override
  String activityVerbResumed(String target) {
    return 'Reanudó $target';
  }

  @override
  String activityVerbRetried(String target) {
    return 'Reintentó $target';
  }

  @override
  String activityVerbReverted(String target) {
    return 'Revirtió $target';
  }

  @override
  String activityVerbReviewed(String target) {
    return 'Revisó $target';
  }

  @override
  String activityVerbRan(String target) {
    return 'Ejecutó $target';
  }

  @override
  String activityVerbSelected(String target) {
    return 'Seleccionó $target';
  }

  @override
  String activityVerbSent(String target) {
    return 'Envió $target';
  }

  @override
  String activityVerbStaged(String target) {
    return 'Agregó $target al staging';
  }

  @override
  String activityVerbSteered(String target) {
    return 'Dirigió $target';
  }

  @override
  String activityVerbSubmitted(String target) {
    return 'Presentó $target';
  }

  @override
  String activityVerbSynced(String target) {
    return 'Sincronizó $target';
  }

  @override
  String activityVerbToggled(String target) {
    return 'Alternó $target';
  }

  @override
  String activityVerbUninstalled(String target) {
    return 'Desinstaló $target';
  }

  @override
  String activityVerbUnstaged(String target) {
    return 'Quitó $target del staging';
  }

  @override
  String get activityTargetActionPolicy => 'una política de acciones';

  @override
  String get activityTargetGoalRun => 'una ejecución de objetivo';

  @override
  String get activityTargetRunLog => 'un registro de ejecución';

  @override
  String get activityTargetWorkingMemory => 'una memoria de trabajo';

  @override
  String get activityTargetRoutingPolicy => 'una política de enrutamiento';

  @override
  String get activityTargetAutonomy => 'una autonomía';

  @override
  String get activityTargetCalendar => 'un calendario';

  @override
  String get activityTargetChecker => 'un verificador';

  @override
  String get activityTargetEditor => 'un editor';

  @override
  String get activityTargetConfirmation => 'una confirmación';

  @override
  String get activityTargetTunnel => 'un túnel';

  @override
  String get activityTargetConversation => 'una conversación';

  @override
  String get activityTargetCredentials => 'unas credenciales';

  @override
  String get activityTargetDictation => 'un dictado';

  @override
  String get activityTargetAgentRun => 'una ejecución de agente';

  @override
  String get activityTargetEvalSuite => 'una suite de evaluación';

  @override
  String get activityTargetWorker => 'un worker';

  @override
  String get activityTargetWorktree => 'un worktree';

  @override
  String get activityTargetMcpServer => 'un servidor MCP';

  @override
  String get activityTargetMemoryAccessGrant =>
      'un permiso de acceso a la memoria';

  @override
  String get activityTargetMemoryDomain => 'un dominio de memoria';

  @override
  String get activityTargetMemoryFact => 'un hecho de memoria';

  @override
  String get activityTargetMemoryPolicy => 'una política de memoria';

  @override
  String get activityTargetFeed => 'un feed';

  @override
  String get activityTargetNote => 'una nota';

  @override
  String get activityTargetOrchestration => 'una orquestación';

  @override
  String get activityTargetPipelineRun => 'una ejecución de pipeline';

  @override
  String get activityTargetPipelineTrigger => 'un disparador de pipeline';

  @override
  String get activityTargetPlan => 'un plan';

  @override
  String get activityTargetPlaybook => 'un playbook';

  @override
  String get activityTargetPullRequest => 'una pull request';

  @override
  String get activityTargetReview => 'una revisión';

  @override
  String get activityTargetProcess => 'un proceso';

  @override
  String get activityTargetProviderPolicy => 'una política de proveedor';

  @override
  String get activityTargetReaction => 'una reacción';

  @override
  String get activityTargetReviewChannel => 'un canal de revisión';

  @override
  String get activityTargetReviewStudio => 'un estudio de revisión';

  @override
  String get activityTargetServerData => 'unos datos del servidor';

  @override
  String get activityTargetSoundscape => 'un paisaje sonoro';

  @override
  String get activityTargetSession => 'una sesión';

  @override
  String get activityTargetTerminal => 'una terminal';

  @override
  String get activityTargetTicketLink => 'un enlace de ticket';

  @override
  String get activityTargetTicketSync => 'una sincronización de tickets';

  @override
  String get activityTargetProfile => 'un perfil';

  @override
  String get activityTargetVoiceProfile => 'un perfil de voz';

  @override
  String get activityTargetWeather => 'un pronóstico del tiempo';

  @override
  String get activityTargetWorkProduct => 'un producto de trabajo';

  @override
  String get activityChangedMemberRole => 'Cambió el rol de un miembro';

  @override
  String get activityChangedMemberRepoAccess =>
      'Cambió el acceso de un miembro a los repositorios';

  @override
  String get activityUpdatedGitHubToken => 'Actualizó el token de GitHub';

  @override
  String get activityRefreshedWeather => 'Refrescó el pronóstico del tiempo';

  @override
  String get activitySetWeatherLocation =>
      'Estableció la ubicación del pronóstico';

  @override
  String get activityClearedWeatherLocation =>
      'Borró la ubicación del pronóstico';

  @override
  String get activityMarkedAllArticlesRead =>
      'Marcó todos los artículos como leídos';

  @override
  String get activityMarkedArticleRead => 'Marcó un artículo como leído';

  @override
  String get activityUpdatedSavedArticle => 'Actualizó un artículo guardado';

  @override
  String get activityTookOverSession => 'Tomó el control de la sesión';

  @override
  String get activityHandedBackSession => 'Devolvió la sesión';

  @override
  String get activityCommittedAndPushed => 'Hizo commit y push';

  @override
  String get activityBackedUpServer => 'Respaldó los datos del servidor';

  @override
  String get activityMarkedChannelRead => 'Marcó el canal como leído';

  @override
  String get activityRespondedToInvitation =>
      'Respondió a la invitación del evento';

  @override
  String get activityStartedCalendarConnect =>
      'Inició la conexión del calendario';

  @override
  String get activityDisconnectedCalendar => 'Desconectó el calendario';

  @override
  String get activityMarkedFileViewed => 'Marcó un archivo como visto';

  @override
  String get activityRespondedToApproval =>
      'Respondió a una solicitud de aprobación';

  @override
  String get activityChangedTunnel => 'Cambió el ajuste del túnel';

  @override
  String get activitySentMessageToAgent => 'Envió un mensaje al agente';

  @override
  String get activityOpenedReviewChannel => 'Abrió el canal de revisión';

  @override
  String get activityOpenedMainConversation =>
      'Abrió la conversación principal';

  @override
  String get activityStartedRecording => 'Inició la grabación';

  @override
  String get activityStoppedRecording => 'Detuvo la grabación';

  @override
  String get activityToggledMcpServer => 'Alternó el servidor MCP';

  @override
  String get activityUpdatedMcpToken => 'Actualizó el token de MCP';

  @override
  String get activitySavedApiKey => 'Guardó una clave de API';

  @override
  String get activityRemovedProviderCredential =>
      'Quitó una credencial de proveedor';

  @override
  String get activityUpdatedLinkedRepos =>
      'Actualizó los repositorios vinculados';

  @override
  String get activityUnlinkedRepo => 'Desvinculó un repositorio';

  @override
  String get activityUpdatedActionItem => 'Actualizó un elemento de acción';

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
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Añadir # repositorios',
      one: 'Añadir repositorio',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'Explora las carpetas de la máquina que ejecuta el servidor y selecciona los repositorios git para registrar.';

  @override
  String get selectThisFolder => 'Seleccionar esta carpeta';

  @override
  String get deselectThisFolder => 'Deseleccionar esta carpeta';

  @override
  String get goUp => 'Subir';

  @override
  String get noSubfoldersHere => 'No hay subcarpetas aquí';

  @override
  String get notAGitRepository => 'Esta carpeta no es un repositorio git.';

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
  String get agentsMentionSection => 'Agentes';

  @override
  String get usersMentionSection => 'Personas';

  @override
  String get ticketsMentionSection => 'Tickets';

  @override
  String get pullRequestsMentionSection => 'Pull requests';

  @override
  String get meetingsMentionSection => 'Reuniones';

  @override
  String get entityRefTicketFallback => 'Ticket';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'Reunión';

  @override
  String get aiReview => 'Revisión IA';

  @override
  String get all => 'Todo';

  @override
  String get allAgentsAlreadyInChannel =>
      'Todos los agentes ya están en este canal.';

  @override
  String get allCommits => 'Todos los commits';

  @override
  String get allSessionsReset => 'Todas las sesiones de sandbox restablecidas.';

  @override
  String get allSources => 'Todas las fuentes';

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
  String get agentApprovalRequired => 'Aprobación requerida';

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
  String get closed => 'Cerrado';

  @override
  String get codeFont => 'Fuente de código';

  @override
  String get codeFontLigatures => 'Ligaduras de la fuente de código';

  @override
  String get codeFontLigaturesDescription =>
      'Mostrar ligaduras de programación (=>, !=, ->) como glifos combinados en el código y los diffs';

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
  String get compactDone =>
      'Conversación compactada. El historial anterior se ha resumido.';

  @override
  String get compactNothing =>
      'Nada que compactar todavía. La conversación aún es corta.';

  @override
  String get compactBusy =>
      'Un agente sigue trabajando. Compacta cuando termine el turno.';

  @override
  String get compactUnavailable =>
      'La compactación no está disponible en este servidor.';

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
  String modelContextChip(String size) {
    return 'Modelo · $size';
  }

  @override
  String get continueLabel => 'Continuar';

  @override
  String get conversationMode => 'Modo';

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
  String get edit => 'Editar';

  @override
  String get edited => 'editado';

  @override
  String get editMessage => 'Editar mensaje';

  @override
  String get deleteMessage => 'Eliminar mensaje';

  @override
  String get deleteMessageConfirm =>
      '¿Eliminar este mensaje? No se puede deshacer.';

  @override
  String get messageDeleted => 'Mensaje eliminado';

  @override
  String get searchInConversation => 'Buscar en la conversación';

  @override
  String get searchMessagesHint => 'Buscar mensajes…';

  @override
  String get noMessagesFound => 'No se encontraron mensajes';

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
  String get fix => 'Corregir';

  @override
  String get fixSelected => 'Corregir selección';

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
  String get claudeStatusFetchFailed =>
      'No se pudo contactar con status.claude.com';

  @override
  String get claudeStatusOpenInBrowser => 'Abrir status.claude.com';

  @override
  String get githubStatusFetchFailed =>
      'No se pudo contactar con githubstatus.com';

  @override
  String get githubStatusOpenInBrowser => 'Abrir githubstatus.com';

  @override
  String get githubStatusRefresh => 'Actualizar';

  @override
  String githubStatusUpdated(String time) {
    return 'Actualizado $time';
  }

  @override
  String get kimiStatusFetchFailed =>
      'No se pudo contactar con status.moonshot.cn';

  @override
  String get kimiStatusOpenInBrowser => 'Abrir status.moonshot.cn';

  @override
  String get openaiStatusFetchFailed =>
      'No se pudo contactar con status.openai.com';

  @override
  String get openaiStatusOpenInBrowser => 'Abrir status.openai.com';

  @override
  String get serviceStatusMaintenance => 'Mantenimiento';

  @override
  String get serviceStatusMajorIssues => 'Problemas importantes';

  @override
  String get serviceStatusMinorIssues => 'Problemas menores';

  @override
  String get serviceStatusOperational => 'Operativo';

  @override
  String get serviceStatusOutage => 'Interrupción';

  @override
  String get serviceStatusTitle => 'Estado de los servicios';

  @override
  String get serviceStatusUnknown => 'Desconocido';

  @override
  String lastChecked(String time) {
    return 'Comprobado $time';
  }

  @override
  String get lastCheckedRecently => 'Comprobado hace poco';

  @override
  String get githubToken => 'Token de GitHub';

  @override
  String get giveYourWorkAHome => 'Dale un hogar a tu trabajo.';

  @override
  String get goBack => 'Volver';

  @override
  String get goForward => 'Avanzar';

  @override
  String get googleFonts => 'Google Fonts';

  @override
  String get hideContainerTerminal => 'Ocultar terminal del contenedor';

  @override
  String get hideConversationChanges => 'Ocultar cambios';

  @override
  String get showConversationChanges => 'Mostrar cambios';

  @override
  String get noConversationChanges =>
      'Aún no hay cambios sin confirmar en esta conversación.';

  @override
  String get conversationChangesTitle => 'Cambios';

  @override
  String get high => 'Alto';

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
  String get images => 'Imágenes';

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
  String get justNow => 'ahora mismo';

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
  String get keybindingConversationTab => 'Pestaña resumen';

  @override
  String get keybindingCreateANewAgentDescription => 'Crear un nuevo agente';

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
  String get keybindingFilesChangedTab => 'Pestaña diff';

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
  String get keybindingGoToInbox => 'Ir a la bandeja de entrada';

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
  String get keybindingNavigateToTheInboxDescription =>
      'Navegar a la bandeja de entrada';

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
  String get keybindingShowFileList => 'Mostrar lista de archivos';

  @override
  String get keybindingShowFileListDescription =>
      'Volver a mostrar el árbol de archivos en la barra lateral del diff';

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
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Cambiar entre modo claro y oscuro';

  @override
  String get keybindingSwitchToTheConversationTabDescription =>
      'Cambiar a la pestaña de resumen';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Cambiar al octavo espacio de trabajo';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Cambiar al quinto espacio de trabajo';

  @override
  String get keybindingSwitchToTheFilesChangedTabDescription =>
      'Cambiar a la pestaña de diff';

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
  String get latestLabel => 'Recientes';

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
  String get loadingAgents => 'Cargando agentes…';

  @override
  String get loadingModels => 'Cargando modelos…';

  @override
  String get loadingProviders => 'Cargando proveedores…';

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
  String get createTicketFromConversation =>
      'Crear ticket desde la conversación';

  @override
  String get manageWorkspaces => 'Gestionar espacios de trabajo';

  @override
  String get reorderWorkspace => 'Reordenar espacio de trabajo';

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
    return 'Escuchando en el puerto $port, compartido con cc_server.';
  }

  @override
  String get mcpNotAvailableOnServer =>
      'El control del servidor MCP no está disponible en el servidor conectado.';

  @override
  String get modelManagedOnServer =>
      'Este modelo se ejecuta en el host del servidor y se gestiona allí.';

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
  String get merged => 'Fusionado';

  @override
  String get messagePlaceholder =>
      'Mensaje… (@ para mencionar, / para comandos)';

  @override
  String get navConversations => 'Canales';

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
  String get navObservability => 'Observabilidad';

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
  String get newLabel => 'Nuevo';

  @override
  String get newPolicy => 'Nueva política';

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
  String get noAgentsDiscovered => 'Ningún agente descubierto';

  @override
  String get noAgentsDiscoveredHint =>
      'Haz clic en \"Descubrir\" para buscar archivos AGENTS.md o \"Añadir agente\" para configurar uno manualmente';

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
  String get notFoundLabel => 'No encontrado';

  @override
  String get notes => 'Notas';

  @override
  String get notificationAgentFinished => 'Agente finalizado';

  @override
  String get notificationPrMentioned => 'Mencionado en pull request';

  @override
  String get notificationNewMessages => 'Nuevos mensajes';

  @override
  String get notificationPrMerged => 'PR fusionada';

  @override
  String get notificationPrPublished => 'PR publicada';

  @override
  String get notificationReviewRequested => 'Revisión solicitada';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get notifyAgentRunCompleted =>
      'Notificar cuando un agente complete una ejecución.';

  @override
  String get notifyPrMentioned =>
      'Notificar cuando te mencionen en una pull request.';

  @override
  String get notifyNewMessages =>
      'Notificar sobre nuevos mensajes de agentes en otros canales.';

  @override
  String get notifyPrMerged => 'Notificar cuando se fusione una pull request.';

  @override
  String get notifyPrPublished =>
      'Notificar cuando un agente publique una pull request.';

  @override
  String get notifyReviewRequested =>
      'Notificar cuando se solicite tu revisión en una pull request.';

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
  String get postingEllipsis => 'Publicando...';

  @override
  String get prCommits => 'Commits';

  @override
  String get prDescriptionPlaceholder => 'Descripción de la PR en Markdown...';

  @override
  String get prDraftCreated => 'Borrador de PR creado';

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
  String get priorityReviewsDescription =>
      'Revisiones prioritarias y resumen del repositorio.';

  @override
  String get proposeToCreateDomain =>
      'Proponga un hecho o política para crear uno.';

  @override
  String get prsCreated => 'PRs creadas';

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
  String get resolve => 'Resolver';

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
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# repositorios',
      one: '1 repositorio',
    );
    return 'No se pudieron añadir $_temp0: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# repositorios añadidos',
      one: 'Repositorio añadido',
    );
    return '$_temp0';
  }

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
  String get resolved => 'Resuelto';

  @override
  String get restartServerToApply =>
      'Reinicia el servidor para aplicar los cambios.';

  @override
  String get restartShell => 'Reiniciar shell';

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
  String get runs => 'Ejecuciones';

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
  String get adapterArguments => 'Argumentos adicionales';

  @override
  String get adapterArgumentsHint => 'Banderas CLI adicionales (p. ej. --yolo)';

  @override
  String get addVariable => 'Añadir variable';

  @override
  String get environmentVariables => 'Variables de entorno';

  @override
  String get environmentVariablesDescription =>
      'Variables de entorno personalizadas pasadas a este adaptador (p. ej. claves API). Guardadas en el llavero.';

  @override
  String get resetToDefault => 'Restablecer por defecto';

  @override
  String get variableKey => 'Clave';

  @override
  String get variableValue => 'Valor';

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
  String get shortcutUnavailableInBrowser => 'No disponible en el navegador';

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
  String get skillBrowseDisclaimer =>
      'El registro skills.sh no es de confianza. El autor, el número de instalaciones y la insignia de editor verificado son solo indicios de procedencia; el veredicto del análisis a continuación es la verdadera señal de seguridad.';

  @override
  String get skillBrowseNoResults =>
      'Ninguna habilidad coincide con tu búsqueda.';

  @override
  String get skillBrowsePrompt =>
      'Busca en el registro skills.sh para instalar una habilidad.';

  @override
  String get skillBrowseSearchHint => 'Buscar en skills.sh…';

  @override
  String get skillFindingLine => 'línea';

  @override
  String get skillInstallAnywayOverride =>
      'Entiendo el riesgo — instalar de todos modos';

  @override
  String skillInstallCount(int count) {
    return '$count instalaciones';
  }

  @override
  String skillInstalled(String slug) {
    return 'Habilidad «$slug» instalada.';
  }

  @override
  String get skillPreviewCapabilities => 'Capacidades';

  @override
  String get skillPreviewFindings => 'Hallazgos';

  @override
  String get skillPreviewGuardedActions => 'Acciones protegidas';

  @override
  String get skillPreviewLlmReviewed => 'Revisado por LLM';

  @override
  String get skillPreviewNoCapabilities => 'Sin capacidades declaradas.';

  @override
  String get skillPreviewNoFindings => 'Sin hallazgos.';

  @override
  String get skillPreviewScanning => 'Analizando habilidad…';

  @override
  String get skillPreviewVerdictLabel => 'Veredicto del análisis';

  @override
  String get skillPreviewVerdictPass => 'Aprobado';

  @override
  String get skillPreviewVerdictQuarantine => 'En cuarentena';

  @override
  String get skillPreviewVerdictWarn => 'Advertencia';

  @override
  String get skillQuarantineWarning =>
      'Esta habilidad fue puesta en cuarentena por el analizador. Instalarla ejecuta código en tu máquina. Continúa solo si confías en la fuente y has revisado los hallazgos.';

  @override
  String get skillSeverityBlocked => 'Bloqueado';

  @override
  String get skillSeverityWarn => 'Advertencia';

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
  String get startLabel => 'Iniciar';

  @override
  String get startOnAppLaunch => 'Iniciar al abrir la app';

  @override
  String get startServerToAccept =>
      'Inicia el servidor para aceptar conexiones MCP.';

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
  String get strictIdentityCheck => 'Verificación estricta de identidad';

  @override
  String get success => 'Éxito';

  @override
  String get successLabel => 'Éxito';

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
  String get ticketLabel => 'TICKET';

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
  String get topic => 'Tema';

  @override
  String get topicHint => 'ej: Tech Stack, Design System';

  @override
  String get totalRuns => 'Ejecuciones totales';

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
  String get meetingVad => 'Detección de voz (Silero VAD)';

  @override
  String get meetingVadDescription =>
      'Un modelo aprendido de actividad de voz que omite los silencios para transcribir solo el habla. Recurre a un umbral de energía si no está instalado.';

  @override
  String get meetingVadInstalled =>
      'Instalado. Filtra la transcripción según el habla detectada.';

  @override
  String get meetingVadNotInstalled =>
      'No instalado: se usa el umbral de energía.';

  @override
  String get meetingModelIncluded => 'Incluido';

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
  String get speechModel => 'Modelo de voz';

  @override
  String get speechModelHint =>
      'Se usa para transcribir reuniones y el micrófono del compositor.';

  @override
  String get voiceModelInstalled =>
      'Instalado. Impulsa la transcripción de reuniones y el botón de micrófono del compositor.';

  @override
  String get meetingMicSilentWarning =>
      'Tu micrófono podría estar silenciado — los demás hablan pero no llega nada a tu micrófono.';

  @override
  String get meetingTemplates => 'Plantillas de notas de reunión';

  @override
  String get meetingTemplatesHint =>
      'Adapta el resumen de IA a un tipo de reunión. La plantilla activa se aplica a los resúmenes nuevos y reejecutados.';

  @override
  String get meetingTemplateActive => 'Plantilla activa';

  @override
  String get meetingTemplateAdd => 'Añadir plantilla';

  @override
  String get meetingTemplateNewTitle => 'Nueva plantilla';

  @override
  String get meetingTemplateEditTitle => 'Editar plantilla';

  @override
  String get meetingTemplateNameLabel => 'Nombre';

  @override
  String get meetingTemplateNameHint => 'p. ej. Revisión de sprint';

  @override
  String get meetingTemplateInstructionsLabel => 'Instrucciones';

  @override
  String get meetingTemplateInstructionsHint =>
      '¿Cómo debe la IA estructurar y enfatizar estas notas?';

  @override
  String get workingMemory => 'Memoria de trabajo';

  @override
  String get workspaceName => 'Nombre del espacio de trabajo';

  @override
  String get workspaceNotesScratchpad =>
      'Notas y borrador del espacio de trabajo';

  @override
  String get workspaceScopedSkills =>
      'Archivos de habilidades del espacio de trabajo adjuntos a los agentes.';

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
  String get pipelineWaterfallTimeline => 'Cronología';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'Activo $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'inactivo $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'Tiempo excluido del total activo: la ejecución estuvo detenida o esperando entre pasos.';

  @override
  String get pipelineStepStarted => 'Iniciado';

  @override
  String get pipelineStepFinished => 'Finalizado';

  @override
  String get pipelineStepDurationLabel => 'Duración';

  @override
  String get pipelineStepBranch => 'Rama';

  @override
  String get pipelineStepViewConversation => 'Ver conversación';

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
  String get pipelineRunColumnPipeline => 'Pipeline';

  @override
  String get pipelineRunColumnDuration => 'Duración';

  @override
  String get pipelineRunColumnStarted => 'Iniciado';

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
  String get teamsManageSubtitle =>
      'Agrupa agentes en equipos y dirige el trabajo asignado a través de un líder.';

  @override
  String get teamsLoadError => 'No se pudieron cargar los equipos';

  @override
  String get teamsEmptyTitle => 'Aún no hay equipos';

  @override
  String get teamsEmptyDescription =>
      'Agrupa agentes en equipos para que el trabajo asignado a un equipo se dirija a través de un líder que delega.';

  @override
  String get teamCreateTitle => 'Nuevo equipo';

  @override
  String get teamEditTitle => 'Editar equipo';

  @override
  String get teamNameLabel => 'Nombre del equipo';

  @override
  String get teamNameHint => 'p. ej. Frontend';

  @override
  String get teamDescriptionLabel => 'Descripción';

  @override
  String get teamDescriptionHint => 'De qué es responsable este equipo';

  @override
  String get teamLeaderLabel => 'Líder';

  @override
  String get teamLeaderHelp =>
      'El coordinador que recibe el trabajo asignado al equipo y lo delega al miembro más adecuado.';

  @override
  String get teamNoLeader => 'Sin líder';

  @override
  String get teamInstructionsLabel => 'Instrucciones de operación';

  @override
  String get teamInstructionsHelp =>
      'Se añaden al briefing del líder: convenciones del equipo, reglas de escalado, tono.';

  @override
  String get teamInstructionsHint => 'Opcional';

  @override
  String get teamSaved => 'Equipo guardado';

  @override
  String get teamMembersError => 'No se pudieron cargar los miembros';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros',
      one: '1 miembro',
      zero: 'Sin miembros',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'Añadir miembro';

  @override
  String get teamAddMemberTitle => 'Añadir miembros';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Añadir $count',
      one: 'Añadir 1',
      zero: 'Añadir',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => 'Todos los agentes ya están en este equipo.';

  @override
  String get teamRemoveMember => 'Quitar del equipo';

  @override
  String get teamLeaderBadge => 'Líder';

  @override
  String get teamUnknownAgent => 'Agente desconocido';

  @override
  String get teamMembersEmpty => 'Aún no hay miembros';

  @override
  String get teamMembersEmptyDescription =>
      'Añade agentes para que el líder tenga personas a quienes delegar.';

  @override
  String get teamSelectPrompt => 'Selecciona un equipo';

  @override
  String get teamSelectPromptDescription =>
      'Elige un equipo de la lista o crea uno nuevo.';

  @override
  String get teamDeleteTitle => '¿Eliminar equipo?';

  @override
  String teamDeleteBody(String name) {
    return '$name será eliminado. Sus agentes no se ven afectados.';
  }

  @override
  String get teamHasLeaderTooltip => 'Tiene un líder';

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
  String get triggerKindWebhook => 'Mediante un webhook';

  @override
  String get triggerScheduleExprLabel => 'Programación (cron o every:segundos)';

  @override
  String get triggerTimezoneLabel => 'Zona horaria (opcional)';

  @override
  String get triggerCatchUpLabel => 'Si se pierden ejecuciones';

  @override
  String get triggerCatchUpRunOnce => 'Ejecutar una vez';

  @override
  String get triggerCatchUpSkip => 'Omitir';

  @override
  String get syncHealthTitle => 'Estado de sincronización';

  @override
  String get syncHealthNoConfigs => 'Aún no hay conexiones de sincronización';

  @override
  String get syncHealthNeverSynced => 'Nunca sincronizado';

  @override
  String get syncOutcomeOk => 'Sincronizado';

  @override
  String get syncOutcomeFailed => 'Error';

  @override
  String get syncOutcomeSkipped => 'Omitido';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count errores consecutivos';
  }

  @override
  String get triggerWebhookHelp =>
      'Se genera una URL de webhook firmada. Los sistemas externos hacen POST para iniciar este pipeline.';

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
  String get triggerEventTicketCancelled => 'Tarea cancelada';

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
  String get labels => 'Etiquetas';

  @override
  String get noLabelsYet => 'Aún no hay etiquetas';

  @override
  String get clearLabels => 'Borrar etiquetas';

  @override
  String get pipelineStepAgentActivity => 'Actividad del agente';

  @override
  String get runStatusCompleted => 'Completado';

  @override
  String get runStatusQueued => 'En cola';

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
  String get sidebarGroupWorkspace => 'Espacio de trabajo';

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
  String get noWorkspace => 'Sin espacio de trabajo';

  @override
  String get selectWorkspace => 'Seleccionar un espacio de trabajo';

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
  String openedAgo(String age) {
    return 'Abierto $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author abrió esta pull request';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$author abrió esta pull request con $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor solicitó revisión a $reviewers';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor retiró la solicitud de revisión para $reviewers';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor solicitó revisión a $requested y retiró la solicitud de revisión para $removed';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author hizo commit';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$author envió $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author aprobó estos cambios';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author solicitó cambios';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comentarios de código',
      one: '1 comentario de código',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author dejó una revisión';
  }

  @override
  String get prTimelineSomeone => 'Alguien';

  @override
  String get prTimelineBotBadge => 'bot';

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
  String get clearAll => 'Borrar todo';

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
  String get staleLabel => 'Obsoleta';

  @override
  String stepsProgress(int done, int total) {
    return '$done de $total pasos';
  }

  @override
  String workspaceEyebrow(String name) {
    return 'Espacio $name';
  }

  @override
  String get pipelineTriggerNode => 'Disparador';

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
  String get failedToSaveLogo =>
      'No se pudo guardar el logo. Comprueba que la app puede leer el archivo seleccionado.';

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
  String get overview => 'Resumen';

  @override
  String get filesTabShort => 'Archivos';

  @override
  String get noFilesChanged => 'Sin archivos modificados';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Vista previa';

  @override
  String get outdated => 'Obsoleto';

  @override
  String get outdatedComments => 'Comentarios obsoletos';

  @override
  String outdatedCountLabel(int count) {
    return '$count obsoletos';
  }

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
  String get suggestedReviewers => 'Revisores sugeridos';

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
  String get meetingsEmpty => 'Aún no hay reuniones';

  @override
  String get meetingsEmptyHint =>
      'Graba tu primera reunión: el audio se queda en este dispositivo y el agente la convierte en notas, decisiones y tareas.';

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
  String get meetingEditTitle => 'Editar título';

  @override
  String get meetingTitleLabel => 'Título';

  @override
  String get meetingAddActionItem => 'Añadir acción';

  @override
  String get meetingEditActionItem => 'Editar acción';

  @override
  String get meetingDeleteActionItem => 'Eliminar acción';

  @override
  String get meetingActionItemContentLabel => 'Acción';

  @override
  String get meetingActionItemContentHint => '¿Qué hay que hacer?';

  @override
  String get meetingActionItemOwnerLabel => 'Responsable';

  @override
  String get meetingActionItemOwnerHint => '¿Quién se encarga? (opcional)';

  @override
  String get meetingAddDecision => 'Añadir decisión';

  @override
  String get meetingEditDecision => 'Editar decisión';

  @override
  String get meetingDeleteDecision => 'Eliminar decisión';

  @override
  String get meetingDecisionContentLabel => 'Decisión';

  @override
  String get meetingDecisionContentHint => '¿Qué se decidió?';

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
  String get meetingExportSaved => 'Reunión exportada.';

  @override
  String meetingExportFailed(String error) {
    return 'Error al exportar: $error';
  }

  @override
  String get meetingExportNothing => 'Aún no hay nada que exportar.';

  @override
  String get meetingPlaybackPlay => 'Reproducir';

  @override
  String get meetingPlaybackPause => 'Pausar';

  @override
  String get meetingPlaybackUnavailable =>
      'La reproducción de audio no está disponible en este dispositivo.';

  @override
  String get meetingDetectedTitle => 'Reunión detectada';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'Parece que «$label» está en curso. ¿Grabarla?';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'Parece que hay una reunión en curso. ¿Grabarla?';

  @override
  String get meetingDetectedRecord => 'Grabar';

  @override
  String get meetingDetectedDismiss => 'Descartar';

  @override
  String get meetingAutoStopTitle =>
      'Esta reunión parece haber terminado. ¿Detener la grabación?';

  @override
  String get meetingAutoStopStop => 'Detener';

  @override
  String get meetingAutoStopKeep => 'Seguir grabando';

  @override
  String get meetingAutoDetect => 'Detección automática de reuniones';

  @override
  String get meetingAutoDetectDescription =>
      'Vigila el calendario y las apps de videoconferencia, y ofrece grabar cuando empieza una reunión.';

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

  @override
  String get meetingToolbarPopOut => 'Separar';

  @override
  String get meetingToolbarHoldToStop =>
      'Mantén pulsado para detener la grabación';

  @override
  String get meetingToolbarSemanticLabel => 'Barra de grabación de reunión';

  @override
  String get orchestrate => 'Orquestar';

  @override
  String get orchestrationUnavailable => 'Orquestación no disponible';

  @override
  String get orchestrationApprove => 'Aprobar plan';

  @override
  String get orchestrationReject => 'Rechazar';

  @override
  String get orchestrationCancel => 'Cancelar orquestación';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count roles — $hires nuevas contrataciones';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count subtickets';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Costo estimado: $amount \$';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total subtickets completados';
  }

  @override
  String get orchestrationStatusProposed => 'Propuesto';

  @override
  String get orchestrationStatusApproved => 'Aprobado';

  @override
  String get orchestrationStatusExecuting => 'Ejecutando';

  @override
  String get orchestrationStatusSynthesizing => 'Sintetizando';

  @override
  String get orchestrationStatusCompleted => 'Completado';

  @override
  String get orchestrationStatusFailed => 'Fallido';

  @override
  String get orchestrationStatusCancelled => 'Cancelado';

  @override
  String get messageFailed => 'Ejecución fallida';

  @override
  String get turnLimitReached =>
      'Límite de turnos alcanzado — responde para continuar';

  @override
  String get retried => 'Reintentado';

  @override
  String replyingTo(String name) {
    return 'en respuesta a $name';
  }

  @override
  String get recentRuns => 'Ejecuciones recientes';

  @override
  String get runIdCopied => 'Id de ejecución copiado';

  @override
  String get copyRunId => 'Copiar id de ejecución';

  @override
  String get copyLogPath => 'Copiar ruta del registro';

  @override
  String get silenceTimeoutLabel => 'Tiempo de silencio (minutos)';

  @override
  String get silenceTimeoutHint =>
      'p. ej. 15 — termina un run tras este tiempo sin salida';

  @override
  String get ticketOutput => 'Resultado';

  @override
  String missingRequiredField(String field) {
    return 'Falta el campo obligatorio: $field';
  }

  @override
  String get capabilityJsonMode => 'Modo JSON';

  @override
  String get capabilityModelSelection => 'Selección de modelo';

  @override
  String get transcriptThinking => 'Pensando…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'Pensó durante $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'Haciendo cambios…';

  @override
  String get transcriptStatusReadingFiles => 'Leyendo archivos…';

  @override
  String get transcriptStatusSearching => 'Buscando en el código…';

  @override
  String get transcriptStatusRunningCommands => 'Ejecutando comandos…';

  @override
  String get transcriptStatusResponding => 'Respondiendo…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'Ejecutando $tool…';
  }

  @override
  String get transcriptInput => 'Entrada';

  @override
  String get transcriptOutput => 'Salida';

  @override
  String get transcriptShowMore => 'Mostrar más';

  @override
  String get transcriptShowLess => 'Mostrar menos';

  @override
  String get transcriptErrorLabel => 'Error';

  @override
  String get transcriptInterrupted => 'Interrumpido';

  @override
  String get transcriptSandboxBlocked =>
      'El espacio aislado bloqueó una acción';

  @override
  String get transcriptOutputTruncated => 'Salida truncada';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'Mostrar toda la salida (+$kb KB)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'Mostrar todas las $count líneas';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'Mostrando las primeras $count líneas';
  }

  @override
  String get transcriptGrepNoMatches => 'Sin coincidencias';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches coincidencias',
      one: '1 coincidencia',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files archivos',
      one: '1 archivo',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String transcriptDiffStats(int adds, int dels) {
    return '$adds adiciones, $dels eliminaciones';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'Persona $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'Cambiar nombre del hablante';

  @override
  String get meetingRenameSpeakerTitle => 'Cambiar nombre del hablante';

  @override
  String get meetingSpeakerNameLabel => 'Nombre';

  @override
  String get meetingSpeakerSuggestFromCalendar =>
      'De los invitados de esta reunión';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'Aplicar a todos los bloques de este interlocutor';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'Si está desactivado, solo se renombra la línea seleccionada.';

  @override
  String get meetingLinkEvent => 'Vincular a evento';

  @override
  String get meetingChangeEvent => 'Cambiar evento';

  @override
  String get meetingLinkEventTitle => 'Vincular a un evento del calendario';

  @override
  String get meetingLinkEventSearchHint => 'Buscar eventos';

  @override
  String get meetingLinkEventEmpty => 'No hay eventos del calendario cercanos';

  @override
  String get meetingUnlinkEvent => 'Quitar vínculo';

  @override
  String get calendarLinkExistingMeeting => 'Vincular a una reunión existente';

  @override
  String get calendarLinkMeetingTitle => 'Vincular una reunión';

  @override
  String get calendarLinkMeetingSearchHint => 'Buscar reuniones';

  @override
  String get calendarLinkMeetingEmpty => 'No hay reuniones para vincular';

  @override
  String get meetingRenameSpeakerFailed =>
      'No se pudo cambiar el nombre del interlocutor';

  @override
  String get calendarLinkUpdateFailed =>
      'No se pudo actualizar el vínculo con el calendario';

  @override
  String get rename => 'Cambiar nombre';

  @override
  String get notNow => 'Ahora no';

  @override
  String get meetingSaveVoiceProfileTitle => '¿Guardar perfil de voz?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'Reconocer a $name automáticamente en futuras reuniones guardando su huella de voz.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'Perfil de voz guardado para $name';
  }

  @override
  String get meetingVoiceProfileSaveFailed =>
      'No se pudo guardar el perfil de voz';

  @override
  String get voiceProfilesSection => 'Perfiles de voz';

  @override
  String get voiceProfilesDescription =>
      'Las voces guardadas se reconocen automáticamente en futuras reuniones.';

  @override
  String get voiceProfilesEmpty =>
      'Aún no hay voces guardadas. Asigna un nombre a un participante en la transcripción de una reunión y elige «Guardar perfil de voz».';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count muestras',
      one: '1 muestra',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'Cambiar nombre del perfil de voz';

  @override
  String get deleteVoiceProfileTitle => '¿Eliminar perfil de voz?';

  @override
  String deleteVoiceProfileBody(String name) {
    return '¿Dejar de reconocer a $name? Se eliminará su huella de voz guardada. Los nombres ya aplicados en reuniones anteriores se conservan.';
  }

  @override
  String get remoteControl => 'Control remoto';

  @override
  String get remoteControlListening => 'Esperando dispositivos';

  @override
  String get remoteControlListenerStopped => 'Listener detenido';

  @override
  String get remoteControlStartToAccept =>
      'Inicia el listener para aceptar conexiones del teléfono.';

  @override
  String get remoteControlStartOnLaunch => 'Iniciar al lanzar la app';

  @override
  String get remoteControlWhenOffStaysStopped =>
      'Si está desactivado, el listener permanece detenido hasta que lo inicies.';

  @override
  String get remoteControlRestartToApply =>
      'Reinicia el listener para aplicar los cambios.';

  @override
  String get remoteControlSignalingUrl => 'URL del broker de señalización';

  @override
  String get remoteControlSignalingHint =>
      'Broker wss:// que solo retransmite el handshake de emparejamiento.';

  @override
  String get remoteControlStunServers => 'Servidores STUN';

  @override
  String get remoteControlStunHint =>
      'URLs STUN separadas por comas. Sin TURN por diseño.';

  @override
  String get remoteControlPwaHost => 'Host de la app del teléfono';

  @override
  String get remoteControlPwaHostHint =>
      'Dónde se aloja la web app del teléfono; se codifica en el QR de emparejamiento.';

  @override
  String get remoteControlNotConfigured =>
      'Añade una URL de señalización y un host de app para habilitar el emparejamiento.';

  @override
  String get remoteControlPairDevice => 'Emparejar un dispositivo';

  @override
  String get remoteControlScanQr =>
      'Escanea este código con la cámara de tu teléfono.';

  @override
  String get remoteControlAllWorkspacesWarning =>
      'Este dispositivo podrá acceder a todos los espacios de trabajo de este Mac.';

  @override
  String get remoteControlCopyLink => 'Copiar enlace';

  @override
  String get remoteControlWantsToConnect => 'Quiere conectarse';

  @override
  String get remoteControlApproveDevice => 'Aprobar dispositivo';

  @override
  String get remoteControlDeviceConnected =>
      'Dispositivo conectado: apruébalo para completar el emparejamiento.';

  @override
  String remoteControlQrExpiresIn(int minutes) {
    return 'Caduca en $minutes min';
  }

  @override
  String get remoteControlPairedDevices => 'Dispositivos emparejados';

  @override
  String get remoteControlNoPairedDevices =>
      'Aún no hay dispositivos emparejados.';

  @override
  String get remoteControlPending => 'Pendiente de confirmación';

  @override
  String get remoteControlActive => 'Activo';

  @override
  String get remoteControlRevoked => 'Revocado';

  @override
  String get remoteControlRevoke => 'Revocar';

  @override
  String get remoteControlConfirmDevice => 'Confirmar dispositivo';

  @override
  String get remoteControlRevokeConfirm =>
      '¿Revocar este dispositivo? Se desconectará de inmediato.';

  @override
  String get devicesSettingsDescription =>
      'Empareja y gestiona los teléfonos que pueden controlar esta app de forma remota.';

  @override
  String get connectedLabel => 'Conectado';

  @override
  String get ideTabGeneral => 'General';

  @override
  String get ideTabExplorer => 'Explorador';

  @override
  String get ideTabSourceControl => 'Control de código';

  @override
  String get ideTabPullRequests => 'Pull requests';

  @override
  String get generalSectionTodos => 'Tareas';

  @override
  String get generalSectionGoals => 'Objetivos';

  @override
  String get goalRunStatusActive => 'Activo';

  @override
  String get goalRunStatusPaused => 'En pausa';

  @override
  String get goalRunStatusCompleted => 'Completado';

  @override
  String get goalRunStatusFailed => 'Fallido';

  @override
  String get goalRunStatusCancelled => 'Cancelado';

  @override
  String get goalRunStatusBudgetExhausted => 'Presupuesto agotado';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'Ejecución $run de $max · $cost de $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'Ejecución $run · $cost de $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'Vence: $deadline';
  }

  @override
  String get goalRunPause => 'Pausar objetivo';

  @override
  String get goalRunResume => 'Reanudar objetivo';

  @override
  String goalRunResumeRaise(String cap) {
    return 'Reanudar · subir límite a $cap';
  }

  @override
  String get goalRunStop => 'Detener objetivo';

  @override
  String get generalSectionPlan => 'Plan';

  @override
  String get generalSectionAgents => 'Agentes';

  @override
  String get generalSectionTerminals => 'Terminales';

  @override
  String get generalTodosEmpty => 'Sin tareas';

  @override
  String get generalAgentsEmpty => 'Ningún agente en ejecución';

  @override
  String get generalTerminalsEmpty => 'Ningún terminal abierto';

  @override
  String get pauseAgent => 'Pausar agente';

  @override
  String get resumeAgent => 'Reanudar agente';

  @override
  String get agentCannotPause =>
      'Este agente no se puede pausar; deténlo en su lugar.';

  @override
  String get goalClear => 'Borrar objetivo';

  @override
  String get undoLabelGoalClear => 'borrar objetivo';

  @override
  String get todoStatusPending => 'Sin empezar';

  @override
  String get todoStatusInProgress => 'En curso';

  @override
  String get todoStatusCompleted => 'Hecho';

  @override
  String get reorderTodo => 'Reordenar tarea';

  @override
  String get focusAgentRun => 'Enfocar ejecución del agente';

  @override
  String get focusTerminal => 'Enfocar terminal';

  @override
  String get todoEditorTitle => 'Editar tareas';

  @override
  String get todoEditorHint =>
      'Un elemento por línea. Usa - [ ] para pendiente, - [~] para en curso, - [x] para hecho.';

  @override
  String get todoNeedsText => 'Añade texto después del comando';

  @override
  String get todoNotFound => 'Ninguna tarea coincidente';

  @override
  String get todoCleared => 'Lista de tareas vaciada';

  @override
  String get todoNothingToCopy => 'Nada que copiar';

  @override
  String todoAdded(String content) {
    return 'Añadido «$content»';
  }

  @override
  String todoStarted(String content) {
    return 'Iniciado «$content»';
  }

  @override
  String todoCompleted(String content) {
    return 'Completado «$content»';
  }

  @override
  String todoRemoved(String content) {
    return 'Eliminado «$content»';
  }

  @override
  String todoCopied(int count) {
    return '$count elementos copiados';
  }

  @override
  String todoImported(int count) {
    return '$count elementos importados';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'Comando de tarea desconocido «$name»';
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
  String get ideNewTerminal => 'Nueva terminal';

  @override
  String get ideOpenChat => 'Abrir chat';

  @override
  String get ideCloseTab => 'Cerrar pestaña';

  @override
  String get ideSplitEditor => 'Dividir editor';

  @override
  String get ideSplitRight => 'Dividir a la derecha';

  @override
  String get ideSplitDown => 'Dividir abajo';

  @override
  String get ideSplitLeft => 'Dividir a la izquierda';

  @override
  String get ideSplitUp => 'Dividir arriba';

  @override
  String get ideCloseGroup => 'Cerrar grupo';

  @override
  String get ideCloseOthers => 'Cerrar las demás';

  @override
  String get ideCloseToRight => 'Cerrar a la derecha';

  @override
  String get ideCloseSaved => 'Cerrar guardadas';

  @override
  String get ideCloseAll => 'Cerrar todo';

  @override
  String get ideSplit => 'Dividir';

  @override
  String get ideToggleSidebar => 'Mostrar/ocultar barra lateral';

  @override
  String get ideNewTab => 'Abrir editor';

  @override
  String get ideReviewCode => 'Revisar código';

  @override
  String get ideReviewNoChanges => 'No hay cambios que revisar';

  @override
  String get ideRevert => 'Revertir';

  @override
  String get ideRevertConfirmTitle => 'Revertir cambios';

  @override
  String ideRevertConfirmMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos',
      one: '1 archivo',
    );
    return '¿Revertir $_temp0 a HEAD? Esto descarta los cambios del árbol de trabajo.';
  }

  @override
  String get ideRevertConfirmAction => 'Revertir';

  @override
  String get ideRevertConfirmCancel => 'Cancelar';

  @override
  String get ideRevertUntracked =>
      'Los archivos sin seguimiento no se pueden revertir';

  @override
  String get ideRevertFailed =>
      'No se pudieron revertir los archivos. El árbol de trabajo de la conversación podría no estar disponible.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos',
      one: '1 archivo',
    );
    return '$_temp0 no se pudieron revertir (sin seguimiento).';
  }

  @override
  String get ideViewSource => 'Ver código fuente';

  @override
  String get ideSearchMatchCase => 'Coincidir mayúsculas/minúsculas';

  @override
  String get ideSearchWholeWord => 'Palabra completa';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'Filtros de búsqueda';

  @override
  String get ideSearchFilesToInclude => 'Archivos a incluir';

  @override
  String get ideSearchFilesToExclude => 'Archivos a excluir';

  @override
  String get ideNoOpenTabs => 'Sin pestañas abiertas — usa + para abrir';

  @override
  String get ideBrowserAddressHint => 'Escribe una dirección o busca';

  @override
  String get ideSimpleWebBrowser => 'Navegador web simple';

  @override
  String get ideWebBrowser => 'Navegador web';

  @override
  String get ideBrowserEnterUrl =>
      'Escribe una URL en la barra de direcciones para empezar a navegar';

  @override
  String get ideCodeServer => 'Editor';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return '¿Guardar los cambios en $fileName?';
  }

  @override
  String get ideUnsavedChangesBody =>
      'Se perderán los cambios si no los guardas.';

  @override
  String get ideDontSave => 'No guardar';

  @override
  String get editorAutoSave => 'Guardado automático';

  @override
  String get editorAutoSaveDescription =>
      'Guardar automáticamente los cambios en el editor integrado.';

  @override
  String get editorAutoSaveOff => 'Desactivado';

  @override
  String get editorAutoSaveAfterDelay => 'Tras un retraso';

  @override
  String get editorAutoSaveOnFocusChange => 'Al cambiar el foco';

  @override
  String get ideCodeServerUnavailable =>
      'Code-server no está disponible en este servidor';

  @override
  String get ideCodeServerUnavailableHint =>
      'Instala code-server (coder/code-server) en el host del servidor y vuelve a abrir el editor.';

  @override
  String get ideCodeServerInstalling => 'Preparando el editor…';

  @override
  String get ideCodeServerOpenInBrowser => 'Abrir editor en el navegador';

  @override
  String get ideCodeServerError => 'No se pudo abrir el editor';

  @override
  String get paneSuspendedCaption =>
      'Suspendido para ahorrar recursos — se recarga al enfocarlo';

  @override
  String get ideFileSearchFailed => 'No se pudieron buscar archivos';

  @override
  String get ideSearchFilename => 'Nombre de archivo';

  @override
  String get ideSearchContent => 'Contenido';

  @override
  String get ideSearchInFiles => 'Buscar en archivos';

  @override
  String get ideNoContentMatches => 'Sin coincidencias';

  @override
  String get ideSourceControlCreatePr => 'Crear petición de extracción';

  @override
  String get ideSourceControlNoChanges => 'Sin cambios';

  @override
  String ideSourceControlChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cambiados',
      one: '1 cambiado',
    );
    return '$_temp0';
  }

  @override
  String get ideConnectGithub =>
      'Conecta GitHub para ver las peticiones de extracción';

  @override
  String get ideNoConversationPr =>
      'No hay petición de extracción para esta conversación';

  @override
  String get ideFileLoading => 'Cargando…';

  @override
  String get ideFileBinary => 'Archivo binario';

  @override
  String get mcpExternalServers => 'Servidores MCP externos';

  @override
  String get mcpExternalServersDescription =>
      'Conéctate a servidores MCP externos (GitHub, Sentry, Postgres, automatización del navegador). Los servidores configurados para Claude, Cursor, VS Code y otras herramientas se detectan automáticamente.';

  @override
  String get mcpApprovalMode => 'Aprobación de herramientas';

  @override
  String get mcpApprovalModeDescription =>
      'Qué acciones se ejecutan sin preguntar. Las lecturas siempre se permiten; los niveles superiores piden confirmación.';

  @override
  String get mcpApprovalAlwaysAsk => 'Preguntar siempre';

  @override
  String get mcpApprovalWrite => 'Aprobar escrituras';

  @override
  String get mcpApprovalYolo => 'Aprobar todo';

  @override
  String get mcpNoExternalServers =>
      'No se detectaron servidores MCP externos.';

  @override
  String get mcpAuthorize => 'Autorizar';

  @override
  String get mcpReconnect => 'Reconectar';

  @override
  String get mcpExternalConnectionsNote =>
      'Los servidores MCP externos se ejecutan en el servidor de agentes (compartido por el escritorio y la web). Autorizar servidores OAuth solo está disponible en el escritorio.';

  @override
  String mcpToolsSummary(int count) {
    return '$count herramientas';
  }

  @override
  String get mcpStatusConnected => 'Conectado';

  @override
  String get mcpStatusConnecting => 'Conectando…';

  @override
  String get mcpStatusNeedsAuth => 'Requiere autorización';

  @override
  String get mcpStatusFailed => 'Falló';

  @override
  String get mcpStatusCircuitOpen => 'En pausa';

  @override
  String get mcpStatusDisabled => 'Desactivado';

  @override
  String get providersAndModels => 'Proveedores y modelos';

  @override
  String get providersAndModelsDescription =>
      'Lista cada proveedor que el agente integrado puede usar: define una clave de API o inicia sesión con el navegador, consulta los modelos y precios de cada proveedor conectado y controla qué proveedores puede usar este espacio de trabajo.';

  @override
  String modelsCountFromProviders(int count, int providers) {
    return '$count modelos de $providers proveedores';
  }

  @override
  String get syncNow => 'Sincronizar';

  @override
  String syncNowResult(int applied, int failed) {
    return 'Sincronización completa: $applied aplicados, $failed fallidos';
  }

  @override
  String syncNowFailed(String error) {
    return 'Error de sincronización: $error';
  }

  @override
  String get toggleDetails => 'Mostrar detalles';

  @override
  String get denied => 'Denegado';

  @override
  String get allowed => 'Permitido';

  @override
  String allowProviderSemantic(String provider) {
    return 'Permitir $provider';
  }

  @override
  String enabledViaEnv(String key) {
    return 'Activado mediante $key';
  }

  @override
  String enabledViaAccount(String service) {
    return 'Activado mediante $service';
  }

  @override
  String get enabledLabel => 'Activado';

  @override
  String get disabledLabel => 'Desactivado';

  @override
  String disabledSetEnvHint(String keys) {
    return 'Desactivado — define $keys o inicia sesión';
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
  String get capabilityTools => 'Herramientas';

  @override
  String get capabilityVision => 'Visión';

  @override
  String get capabilityReasoning => 'Razonamiento';

  @override
  String get statusDeprecated => 'Obsoleto';

  @override
  String get usageAndCost => 'Uso y coste';

  @override
  String get usageAndCostDescription =>
      'Gasto de tus agentes en los últimos 7 días, según los costes de ejecución observados.';

  @override
  String get noUsageYet => 'Aún no hay uso registrado.';

  @override
  String get spentThisWeek => 'gastados esta semana';

  @override
  String get subscriptionUsage => 'Uso de la suscripción';

  @override
  String get subscriptionUsageUnavailable => 'No disponible';

  @override
  String get subscriptionUsagePartiallyAvailable => 'Parcialmente disponible';

  @override
  String resetsIn(String duration) {
    return 'Se restablece en $duration';
  }

  @override
  String get feedbackHelpful => 'Esto fue útil';

  @override
  String get feedbackNotHelpful => 'Esto no fue útil';

  @override
  String get modeChat => 'Chat';

  @override
  String get modePlan => 'Plan';

  @override
  String get modeReview => 'Revisión';

  @override
  String get modeOrchestrate => 'Orquestación';

  @override
  String get commandRules => 'Reglas de comandos';

  @override
  String get commandRulesDescription =>
      'Cómo Control Center decide qué comandos de shell puede ejecutar un agente, según el modo de conversación.';

  @override
  String get scopeGlobal => 'Siempre';

  @override
  String get ruleDenied => 'Denegado';

  @override
  String get ruleAsk => 'Preguntar primero';

  @override
  String get editorTheme => 'Tema del editor';

  @override
  String get editorThemeDescription =>
      'Importa un tema de colores de VS Code para que el diff y el editor integrados coincidan con tu IDE.';

  @override
  String get editorThemePasteHint =>
      'Pega el contenido de un archivo de tema de colores de VS Code';

  @override
  String get editorThemeImported => 'Tema importado';

  @override
  String get editorThemeInvalid => 'Eso no parece un tema de VS Code válido';

  @override
  String get importTheme => 'Importar tema';

  @override
  String get clearTheme => 'Borrar tema';

  @override
  String get openInDiffViewer => 'Abrir en el visor de diferencias';

  @override
  String get shellCommand => 'Comando';

  @override
  String get shellOutput => 'Salida';

  @override
  String get planReadyToImplement => '¿Listo para implementar?';

  @override
  String get planContinueHere => 'Continuar aquí';

  @override
  String get planContinueHereDescription =>
      'Implementar el plan en esta sesión';

  @override
  String get planStartNewSession => 'Iniciar una nueva sesión';

  @override
  String get planStartNewSessionDescription =>
      'Implementar en una sesión nueva con un contexto limpio';

  @override
  String get revertToHere => 'Volver aquí';

  @override
  String get revertConfirmBody =>
      '¿Ocultar los mensajes posteriores a este punto y revertir los cambios de archivos del agente a este turno? Puedes deshacerlo.';

  @override
  String get revert => 'Revertir';

  @override
  String get revertedToHere => 'Revertido a este punto';

  @override
  String get nothingToRevert => 'Nada que revertir';

  @override
  String get undoRevert => 'Deshacer reversión';

  @override
  String get revertUndone => 'Reversión deshecha';

  @override
  String get systemBehavior => 'Comportamiento del sistema';

  @override
  String get keepAwakeTitle =>
      'Mantener el ordenador activo mientras los agentes trabajan';

  @override
  String get keepAwakeOnSubtitle =>
      'El ordenador no se suspenderá mientras un agente esté trabajando';

  @override
  String get keepAwakeOffSubtitle =>
      'El ordenador puede suspenderse aunque un agente esté trabajando';

  @override
  String get syncEngineSectionTitle => 'Motor de sincronización';

  @override
  String get syncEngineDescription =>
      'Los tickets, la mensajería y las notas se actualizan en vivo mediante pequeños cambios incrementales en lugar de instantáneas completas. Desactivar un interruptor hace que ese almacén vuelva al modo de instantánea completa; reinicia la aplicación para que el cambio surta efecto.';

  @override
  String get syncEngineTicketsTitle => 'Tickets';

  @override
  String get syncEngineMessagingTitle => 'Mensajería';

  @override
  String get syncEngineNotesTitle => 'Notas';

  @override
  String get syncEngineOnSubtitle => 'La sincronización en vivo está activa';

  @override
  String get syncEngineOffSubtitle =>
      'Usando sincronización por instantánea completa';

  @override
  String get channels => 'Canales';

  @override
  String get channelsHomeDescription =>
      'Elige un canal de la lista o inicia uno nuevo.';

  @override
  String get noChannelsYet => 'Aún no hay canales';

  @override
  String get newChannel => 'Nuevo canal';

  @override
  String get channelName => 'Nombre del canal';

  @override
  String get channelReposHint => 'Repos a incluir';

  @override
  String get ideSourceControl => 'Control de código fuente';

  @override
  String get stagedChanges => 'Cambios preparados';

  @override
  String get changes => 'Cambios';

  @override
  String get stageFile => 'Preparar';

  @override
  String get unstageFile => 'Quitar de preparados';

  @override
  String get stageAll => 'Preparar todos los cambios';

  @override
  String get unstageAll => 'Quitar todo de preparados';

  @override
  String get stageChangesToCommit => 'Prepara cambios para confirmar';

  @override
  String get syncToPrHead => 'Obtener los últimos commits de la PR';

  @override
  String get syncedToPrHead => 'Sincronizado con los últimos commits de la PR';

  @override
  String get syncPrHeadDirty =>
      'Confirma o descarta tus cambios antes de sincronizar';

  @override
  String get syncPrHeadFailed => 'No se pudo sincronizar con la PR';

  @override
  String get channelLabel => 'Canal';

  @override
  String get keybindingNewChannel => 'Nuevo canal';

  @override
  String get keybindingCreateANewChannelDescription => 'Crear un nuevo canal';

  @override
  String get jumpToLatest => 'Ir al más reciente';

  @override
  String get streaming => 'Transmitiendo';

  @override
  String get newMessages => 'Nuevo';

  @override
  String get copyLink => 'Copiar enlace';

  @override
  String get linkCopied => 'Enlace copiado';

  @override
  String get messageTooFarBack => 'El mensaje está demasiado atrás';

  @override
  String newMessagesCount(int count) {
    return '$count nuevos';
  }

  @override
  String get agentResponding => 'Agente respondiendo';

  @override
  String get agentFinished => 'Agente terminado';

  @override
  String get harnessConnectProviderForModels =>
      'Conecta un proveedor para ver los modelos.';

  @override
  String get providerSignOut => 'Cerrar sesión';

  @override
  String get providerWaitingForDeviceCode =>
      'Esperando a que confirmes el código en tu navegador…';

  @override
  String get providerDeviceCodeHint =>
      'Comprueba que este código coincide con el del navegador y luego apruébalo.';

  @override
  String get providerPlanUsageLoading => 'Comprobando el uso del plan…';

  @override
  String get providerPlanUsageUnavailable => 'Este plan no informó del uso.';

  @override
  String providerSignOutConfirmTitle(String provider) {
    return '¿Cerrar sesión en $provider?';
  }

  @override
  String providerSignOutConfirmBody(String provider) {
    return 'Los agentes que usan modelos de $provider dejarán de funcionar hasta que vuelvas a iniciar sesión, lo que requiere todo el proceso del navegador.';
  }

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return '¿Eliminar la clave de API de $provider?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'La clave guardada se elimina y no se podrá volver a mostrar. Los agentes que usan modelos de $provider dejarán de funcionar hasta que pegues una nueva.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return '¿Eliminar $provider?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'Se eliminan el proveedor y su clave guardada. Los agentes fijados a sus modelos dejarán de funcionar.';
  }

  @override
  String get providerApiKeyHint => 'Pega una clave de API';

  @override
  String get providerApiKeyStoredHint =>
      'Clave de API guardada: pega una nueva para reemplazarla';

  @override
  String get providerBaseUrlHint => 'URL base (opcional)';

  @override
  String get customProviders => 'Proveedores personalizados';

  @override
  String get customProvidersDescription =>
      'Cualquier endpoint compatible con OpenAI o Anthropic — Ollama, LM Studio, vLLM o un despliegue privado — con una clave de API opcional.';

  @override
  String get addProvider => 'Añadir proveedor';

  @override
  String get noCustomProviders => 'Aún no hay proveedores personalizados.';

  @override
  String get providerNameLabel => 'Nombre';

  @override
  String get apiTypeLabel => 'Tipo de API';

  @override
  String get providerBaseUrlLabel => 'URL base';

  @override
  String get providerApiKeyOptionalHint => 'Clave de API (opcional)';

  @override
  String get dialectOpenAiCompatible => 'Compatible con OpenAI';

  @override
  String get dialectAnthropicCompatible => 'Compatible con Anthropic';

  @override
  String get removeProviderTooltip => 'Eliminar proveedor';

  @override
  String get providerLogInWithBrowser => 'Iniciar sesión con el navegador';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'Iniciar sesión en $provider';
  }

  @override
  String get providerLabel => 'Proveedor';

  @override
  String get selectProviderToLogin =>
      'Selecciona un proveedor para iniciar sesión';

  @override
  String providerLoginFailed(String error) {
    return 'Error de inicio de sesión: $error';
  }

  @override
  String get providerWaitingForBrowser =>
      'Esperando que autorices en el navegador…';

  @override
  String get providerPasteCodeHint => 'O pega el código de tu navegador';

  @override
  String get providerCompleteLogin => 'Completar';

  @override
  String get providerConnectedApiKey => 'Conectado mediante clave de API';

  @override
  String get providerConnectedOauth => 'Conectado';

  @override
  String providerConnectedAccount(String account) {
    return 'Conectado · $account';
  }

  @override
  String get providerLocalReady => 'Local · listo';

  @override
  String get providerNotConnected => 'No conectado';

  @override
  String get preparingWorkspace => 'Preparando espacio de trabajo…';

  @override
  String provisioningCloningRepo(String repo) {
    return 'Clonando $repo…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'Obteniendo la pull request en $repo…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'Configurando el agente $agent…';
  }

  @override
  String get workspacePrepFailed => 'Error al preparar el espacio de trabajo';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count mensaje(s) enviado(s) cuando esté listo';
  }

  @override
  String get membersNav => 'Miembros';

  @override
  String get membersSettingsDescription =>
      'Personas con acceso a este espacio de trabajo: lista, invitaciones y registro de auditoría';

  @override
  String get memberRosterLabel => 'Lista de miembros';

  @override
  String get roleOwner => 'Propietario';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Miembro';

  @override
  String get roleViewer => 'Observador';

  @override
  String get roleGuest => 'Invitado';

  @override
  String get removeMemberTitle => 'Quitar miembro';

  @override
  String removeMemberConfirm(String name) {
    return '¿Quitar a $name de este espacio de trabajo? Perderá el acceso de inmediato.';
  }

  @override
  String get unknownUserLabel => 'Usuario desconocido';

  @override
  String get inviteMember => 'Invitar miembro';

  @override
  String get inviteRepoAccessHeader => 'Acceso a repositorios';

  @override
  String get inviteRepoAccessExplainer =>
      'Solo los repositorios que marques se comparten con la persona invitada, al nivel que elijas. Todo lo demás permanece oculto.';

  @override
  String get grantLevelRead => 'Lectura';

  @override
  String get grantLevelReview => 'Revisión';

  @override
  String get grantLevelWrite => 'Escritura';

  @override
  String get inviteExpiryLabel => 'Caduca en';

  @override
  String get expiryOneDay => '1 día';

  @override
  String get expirySevenDays => '7 días';

  @override
  String get expiryThirtyDays => '30 días';

  @override
  String get createInviteAction => 'Crear invitación';

  @override
  String get inviteOneTimeCodeLabel => 'Código de un solo uso';

  @override
  String get inviteCodeShownOnce =>
      'Este código se muestra solo una vez: cópialo ahora.';

  @override
  String get inviteLinkLabel => 'Enlace de invitación';

  @override
  String get inviteRedeemHint =>
      'Comparte el código con la persona invitada; lo canjeará con la URL de tu servidor.';

  @override
  String get inviteScanQr => 'O escanea para canjear';

  @override
  String get inviteLoopbackWarningTitle =>
      'La invitación apunta a una dirección local';

  @override
  String get inviteLoopbackWarningBody =>
      'Los colaboradores en otras máquinas no podrán acceder a este servidor. Inicia un túnel (Configuración → Integraciones → Compartir este servidor) o conéctate a tu red para que los usuarios externos puedan conectarse.';

  @override
  String get inviteStatusOpen => 'Abierta';

  @override
  String get inviteStatusUsed => 'Usada';

  @override
  String get inviteStatusRevoked => 'Revocada';

  @override
  String get inviteStatusExpired => 'Caducada';

  @override
  String inviteCreatedTime(String time) {
    return 'Creada $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'caduca el $date';
  }

  @override
  String get noActivityYet => 'Sin actividad todavía';

  @override
  String get couldNotLoadMembers => 'No se pudieron cargar los miembros';

  @override
  String get couldNotLoadInvites => 'No se pudieron cargar las invitaciones';

  @override
  String get couldNotLoadActivity => 'No se pudo cargar la actividad';

  @override
  String get yourDevices => 'Tus dispositivos';

  @override
  String get yourDevicesDescription =>
      'Clientes emparejados con tu cuenta en este servidor.';

  @override
  String get noOwnDevices =>
      'Aún no hay dispositivos emparejados con tu cuenta';

  @override
  String get renameDeviceTitle => 'Renombrar dispositivo';

  @override
  String get revokeDeviceTitle => 'Revocar dispositivo';

  @override
  String revokeDeviceConfirm(String label) {
    return '¿Revocar $label? Se desconecta de inmediato y ya no puede acceder a este servidor.';
  }

  @override
  String devicePairedTime(String time) {
    return 'Emparejado $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'Visto por última vez $time';
  }

  @override
  String get deviceNeverSeen => 'Nunca conectado';

  @override
  String get profileSectionLabel => 'Perfil';

  @override
  String get profileSectionDescription =>
      'Cómo apareces ante tu equipo y en la autoría de los commits de git.';

  @override
  String get displayNameLabel => 'Nombre visible';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get gitAuthorNameLabel => 'Nombre de autor de git';

  @override
  String get gitAuthorEmailLabel => 'Correo de autor de git';

  @override
  String get profileSaved => 'Perfil guardado';

  @override
  String get presenceOnline => 'En línea';

  @override
  String get presenceIdle => 'Inactivo';

  @override
  String get presenceTyping => 'Escribiendo…';

  @override
  String get presenceAgentThinking => 'Pensando';

  @override
  String get presenceAgentRunning => 'En curso';

  @override
  String get presenceAgentBlocked => 'Bloqueado';

  @override
  String get presenceAgentDone => 'Listo';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
  }

  @override
  String get presenceRailLabel => 'Quién está en línea';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'Activar no molestar';

  @override
  String get dndTooltipOff => 'Desactivar no molestar';

  @override
  String get startPresenting => 'Empezar a presentar';

  @override
  String get stopPresenting => 'Dejar de presentar';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name está presentando';
  }

  @override
  String get spotlightLeave => 'Salir';

  @override
  String typingIndicator(String name) {
    return '$name está escribiendo…';
  }

  @override
  String get ideTabNotes => 'Notas';

  @override
  String get ideSidebarAllViews => 'Todas las vistas';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'Todas las vistas ($count ocultas)';
  }

  @override
  String get ideSidebarPinView => 'Fijar a la barra lateral';

  @override
  String get ideSidebarUnpinView => 'Quitar de la barra lateral';

  @override
  String get notesEmptyHint =>
      'Añade una nota para quien retome esta conversación…';

  @override
  String get notesEditTooltip => 'Editar nota';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'Actualizado por $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name está editando';
  }

  @override
  String get notesSaveFailed => 'No se pudo guardar la nota';

  @override
  String get reactionAddTooltip => 'Añadir reacción';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'Reaccionar con $emoji';
  }

  @override
  String get autonomyDialLabel => 'Autonomía';

  @override
  String get autonomyProposeOnly => 'Solo proponer';

  @override
  String get autonomyActWithApproval => 'Actuar con aprobación';

  @override
  String get autonomyActFreely => 'Actuar libremente';

  @override
  String get autonomyDefaultOption => 'Predeterminado';

  @override
  String get checkerLabel => 'Verificador';

  @override
  String get checkerNone => 'Ninguno';

  @override
  String get checkerCaption =>
      'El verificador revisa las ejecuciones completadas de otros agentes.';

  @override
  String get takeoverTooltip => 'Tomar el control del árbol de trabajo';

  @override
  String get takeoverBannerSelf =>
      'Has tomado el control del árbol de trabajo de esta conversación';

  @override
  String takeoverBannerOther(String name) {
    return '$name ha tomado el control del árbol de trabajo de esta conversación';
  }

  @override
  String get handBackButton => 'Devolver el control';

  @override
  String get handBackDialogTitle => 'Devolver el control del árbol de trabajo';

  @override
  String get handBackDialogNoteHint => 'Nota opcional para el agente…';

  @override
  String takeoverFailed(String message) {
    return 'No se pudo tomar el control: $message';
  }

  @override
  String handBackFailed(String message) {
    return 'No se pudo devolver el control: $message';
  }

  @override
  String get planStudioTitle => 'Estudio de planes';

  @override
  String get plansTitle => 'Planes';

  @override
  String get plansSubtitle => 'Planes activos, documentos de plan y playbooks';

  @override
  String get plansActiveSection => 'Planes activos';

  @override
  String get plansDocumentsSection => 'Documentos de plan';

  @override
  String get plansPlaybooksSection => 'Playbooks';

  @override
  String get plansNoActive => 'Aún no hay planes activos.';

  @override
  String get plansNoDocuments => 'Aún no hay documentos de plan.';

  @override
  String get plansNoPlaybooks => 'Aún no hay playbooks.';

  @override
  String get planNotFound => 'Plan no encontrado.';

  @override
  String get planOpenInStudio => 'Abrir';

  @override
  String get planNodeTitle => 'Título';

  @override
  String get planNodeDescription => 'Descripción';

  @override
  String get planNodeDescriptionHint => 'Qué debe hacer este paso…';

  @override
  String get planNodeApplyDescription => 'Aplicar';

  @override
  String get planNodeRole => 'Rol';

  @override
  String get planNodeDependencies => 'Depende de';

  @override
  String get planNodeDependenciesHint => 'Añadir una dependencia';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dependencias',
      one: '1 dependencia',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'Sin dependencias, se ejecuta en cuanto empieza el plan';

  @override
  String get planNodeOutputSchema => 'Esquema de salida (JSON)';

  @override
  String get planNodeEstimate => 'Estimación';

  @override
  String get planNodeProvenance => 'Procedencia';

  @override
  String get planNodeAlreadyExecuted =>
      'Ya ejecutado: editar bifurca el plan desde aquí.';

  @override
  String get planNewNodeTitle => 'Nuevo paso';

  @override
  String get planEstimateNoHistory => 'Aún sin historial';

  @override
  String get planEstimateBlastUnknown => 'Radio de impacto: desconocido';

  @override
  String get planEstimatePartial => 'parcial';

  @override
  String get planEstimateAction => 'Estimar';

  @override
  String planEstimateDuration(String range) {
    return 'Duración $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'Radio de impacto: $files archivos, $symbols símbolos';
  }

  @override
  String get planApprove => 'Aprobar plan';

  @override
  String get planApproveSelectedNodes => 'Aprobar seleccionados';

  @override
  String get planReject => 'Rechazar';

  @override
  String get planCancel => 'Cancelar ejecución';

  @override
  String get planContinueNode => 'Continuar nodo';

  @override
  String get planTotalNotEstimated => 'Aún sin estimar';

  @override
  String get planBudgetExceeded => 'sobre presupuesto';

  @override
  String planBudgetCeiling(String amount) {
    return 'presupuesto ≤ $amount \$';
  }

  @override
  String get planVersionsTitle => 'Versiones';

  @override
  String get planNoRevisions => 'Aún sin revisiones.';

  @override
  String get planDiffIdentical => 'Sin cambios.';

  @override
  String get planDiffGoalChanged => 'Objetivo cambiado';

  @override
  String get planDiffBudgetChanged => 'Presupuesto cambiado';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'Cambios de v$fromRev a v$toRev';
  }

  @override
  String planDiffAdded(String node) {
    return 'Añadido $node';
  }

  @override
  String planDiffRemoved(String node) {
    return 'Eliminado $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return 'Cambiado $node: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'Arista añadida: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'Arista eliminada: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'Rol añadido: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'Rol eliminado: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'Rol reasignado: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'Plan replanificado: aprobaste v$approved, ahora es v$current. Revisa las diferencias.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'Costo real: $amount \$';
  }

  @override
  String get planPlaybookRun => 'Ejecutar';

  @override
  String get planPlaybookDelete => 'Eliminar playbook';

  @override
  String get planPlaybookProposed =>
      'Plan propuesto: aprúbalo en el estudio de planes.';

  @override
  String get planPlaybookAnchorTicket => 'Ticket de anclaje';

  @override
  String get planPlaybookPickTicket => 'Elegir un ticket…';

  @override
  String get planPlaybookProposeRun => 'Proponer plan';

  @override
  String get planPlaybookRepoHint => 'Un id de repositorio';

  @override
  String get planPlaybookAgentHint => 'Un id de agente';

  @override
  String planPlaybookRunTitle(String name) {
    return 'Ejecutar $name';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count parámetros';
  }

  @override
  String get reviewStudioTitle => 'Estudio de revisión';

  @override
  String get reviewStudioWalkthrough => 'Recorrido';

  @override
  String get reviewStudioContract => 'Contrato de API';

  @override
  String get reviewStudioVisual => 'Diferencia visual';

  @override
  String get reviewStudioBlastRadius => 'Radio de impacto';

  @override
  String get reviewStudioRecompute => 'Recalcular';

  @override
  String get reviewStudioCohortsHeader => 'Cohortes';

  @override
  String get reviewStudioNoCohorts =>
      'Aún no hay cohortes: ejecuta el análisis para agrupar esta PR por significado.';

  @override
  String get reviewStudioGroupedByPath =>
      'Agrupado por ruta (repo no indexado)';

  @override
  String get reviewStudioIndexRepo => 'Indexar repo';

  @override
  String reviewStudioFilesCount(int count) {
    return '$count archivos';
  }

  @override
  String get reviewStudioFilesInCohort => 'Archivos de esta cohorte';

  @override
  String get reviewStudioSelectCohort =>
      'Selecciona una cohorte para ver su resumen.';

  @override
  String get reviewStudioSummaryEmpty =>
      'Aún no hay resumen para esta cohorte.';

  @override
  String get reviewStudioNoAxes => 'Aún no se han ejecutado ejes de revisión.';

  @override
  String get reviewAxisCorrectness => 'Corrección';

  @override
  String get reviewAxisSecurity => 'Seguridad';

  @override
  String get reviewAxisTestGap => 'Brechas de pruebas';

  @override
  String get reviewAxisPerformance => 'Rendimiento';

  @override
  String get reviewAxisVisual => 'Visual';

  @override
  String get reviewAxisApiContract => 'Contrato de API';

  @override
  String get reviewAxisPass => 'Aprobado';

  @override
  String get reviewAxisWarn => 'Aviso';

  @override
  String get reviewAxisFail => 'Fallo';

  @override
  String get reviewAxisPartial => 'Parcial';

  @override
  String get reviewAxisUnavailable => 'No disponible';

  @override
  String get reviewStudioVerdictShip => 'Enviar';

  @override
  String get reviewStudioVerdictHold => 'Retener';

  @override
  String get reviewStudioVerdictBlock => 'Bloquear';

  @override
  String get reviewStudioVerdictClear => 'Ningún eje bloquea la fusión.';

  @override
  String reviewStudioBlockingAxes(String axes) {
    return '$axes bloquean la fusión';
  }

  @override
  String get reviewStudioNoContractChanges =>
      'No hay cambios en el contrato de API en esta PR.';

  @override
  String get reviewStudioBreaking => 'Ruptura';

  @override
  String reviewStudioBreakingCount(int count) {
    return '$count de ruptura';
  }

  @override
  String get reviewStudioDerivedContract => 'Derivado (informativo)';

  @override
  String get reviewStudioApprove => 'Aprobar';

  @override
  String get reviewStudioReject => 'Rechazar';

  @override
  String get reviewStudioApproved => 'Aprobado';

  @override
  String get reviewStudioRejected => 'Rechazado';

  @override
  String get reviewStudioNoVisualChanges =>
      'No se detectaron cambios visuales.';

  @override
  String get reviewStudioVisualUnavailable => 'Diferencia visual no disponible';

  @override
  String get reviewStudioApproveChange => 'Aprobar el cambio previsto';

  @override
  String reviewStudioChangedRegion(String percent) {
    return '$percent% cambiado';
  }

  @override
  String get reviewStudioRenderedOnHost => 'Renderizado en el host';

  @override
  String get reviewStudioVisualAdded => 'Añadido';

  @override
  String get reviewStudioVisualChanged => 'Modificado';

  @override
  String get reviewStudioVisualRemoved => 'Eliminado';

  @override
  String get reviewStudioVisualApproved => 'Aprobado';

  @override
  String get reviewStudioVisualUnchanged => 'Sin cambios';

  @override
  String get reviewStudioSelectFileForBlast =>
      'Selecciona un archivo modificado para ver su radio de impacto.';

  @override
  String get reviewStudioNotIndexed =>
      'Repo no indexado: radio de impacto no disponible.';

  @override
  String reviewStudioAffectedCount(int count) {
    return '$count símbolos afectados';
  }

  @override
  String get reviewStudioDirectCallers => 'Llamadores directos';

  @override
  String reviewStudioTransitiveAt(int depth) {
    return 'Transitivo (salto $depth)';
  }

  @override
  String get recentLabel => 'Reciente';

  @override
  String get cheatSheetTitle => 'Atajos de teclado';

  @override
  String get cheatSheetGlobal => 'Global';

  @override
  String get cheatSheetThisScreen => 'Esta pantalla';

  @override
  String get cheatSheetReservedInBrowser => 'Reservado por el navegador';

  @override
  String get keybindingCheatSheet => 'Atajos de teclado';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      'Mostrar la hoja de referencia de atajos de teclado de la pantalla actual';

  @override
  String get runPlaybookLabel => 'Ejecutar playbook';

  @override
  String get playbooksLabel => 'Playbooks';

  @override
  String get keybindingUndo => 'Deshacer';

  @override
  String get keybindingRedo => 'Rehacer';

  @override
  String get keybindingUndoLastActionDescription =>
      'Deshacer tu última acción reversible';

  @override
  String get keybindingRedoLastActionDescription =>
      'Rehacer la última acción deshecha';

  @override
  String get undone => 'Deshecho';

  @override
  String get redone => 'Rehecho';

  @override
  String get undoFailed => 'No se pudo deshacer';

  @override
  String get undoLabelTicketEdit => 'edición de ticket';

  @override
  String get undoLabelMessageEdit => 'edición de mensaje';

  @override
  String get undoLabelTodoStatus => 'estado de tarea';

  @override
  String get inboxTitle => 'Bandeja de entrada';

  @override
  String get inboxReview => 'Revisar';

  @override
  String get inboxOpen => 'Abrir';

  @override
  String get inboxAllCaughtUp => 'Estás al día';

  @override
  String get inboxSeverityBlocking => 'Bloqueado';

  @override
  String get inboxSeverityWaiting => 'En espera';

  @override
  String get inboxSeverityInfo => 'Info';

  @override
  String get inboxSyncFailed => 'Error de sincronización';

  @override
  String get inboxNeedsYourAttention => 'Requiere tu atención';

  @override
  String get inboxSectionNeedsYourReview => 'Esperan tu revisión';

  @override
  String get inboxSectionReturnedToYou => 'Devueltas a ti';

  @override
  String get inboxSectionApproved => 'Aprobadas';

  @override
  String get inboxSectionDrafts => 'Borradores';

  @override
  String get inboxSectionWaitingForReviewers => 'Esperando revisores';

  @override
  String get inboxSectionMergingAndMerged =>
      'Fusionándose y fusionadas recientemente';

  @override
  String get inboxSectionWaitingForAuthor => 'Esperando al autor';

  @override
  String get inboxColumnTitle => 'Título';

  @override
  String get inboxColumnChanges => 'Cambios';

  @override
  String get inboxColumnUpdated => 'Actualizado';

  @override
  String get inboxReviewApproved => 'Aprobada';

  @override
  String get inboxReviewChangesRequested => 'Cambios solicitados';

  @override
  String get inboxHeroSubtitle =>
      'Cada pull request que te involucra, ordenada por lo que sigue.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests necesitan tu revisión',
      one: '1 pull request necesita tu revisión',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count volvieron a ti',
      one: '1 volvió a ti',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted =>
      'Ese cambio no se guardó y se revirtió';

  @override
  String get offlinePendingLabel => 'pendiente';

  @override
  String get offlineSyncingLabel => 'sincronizando';

  @override
  String get copyLinkLabel => 'Copiar enlace de esta página';

  @override
  String get fleetTabLabel => 'Flota';

  @override
  String get evalsTabLabel => 'Evals';

  @override
  String get agentsSectionLabel => 'Agentes';

  @override
  String get fleetWorkersTitle => 'Trabajadores';

  @override
  String get fleetWorkersSubtitle =>
      'Máquinas disponibles para ejecutar trabajos';

  @override
  String get fleetJobsTitle => 'Trabajos';

  @override
  String get fleetJobsSubtitle => 'Trabajo distribuido en la flota';

  @override
  String get fleetNoWorkers =>
      'Aún no hay trabajadores — una segunda máquina que ejecute `cc_worker --server <url>` se une a la flota.';

  @override
  String get fleetNoJobs => 'Sin trabajos.';

  @override
  String get fleetError => 'No se pudo cargar la flota';

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
    return 'Latido $time';
  }

  @override
  String get fleetNoHeartbeat => 'Aún sin latido';

  @override
  String fleetLastErrorLabel(String error) {
    return 'Último error: $error';
  }

  @override
  String get fleetDrain => 'Drenar';

  @override
  String get fleetResume => 'Reanudar';

  @override
  String get fleetRevoke => 'Revocar';

  @override
  String get fleetRemove => 'Eliminar';

  @override
  String get fleetRevokeTitle => '¿Revocar el trabajador?';

  @override
  String fleetRevokeBody(String name) {
    return '¿Revocar $name? Su sesión finaliza y los trabajos activos se reasignan.';
  }

  @override
  String get fleetRemoveTitle => '¿Eliminar el trabajador?';

  @override
  String fleetRemoveBody(String name) {
    return '¿Eliminar $name de la flota? Esto borra su registro.';
  }

  @override
  String get fleetActionFailed => 'La acción falló';

  @override
  String get fleetJobUnassigned => 'Sin asignar';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max intentos';
  }

  @override
  String get fleetPlacementReasons => 'Decisiones de asignación';

  @override
  String get fleetNoPlacements => 'Aún no hay decisiones de asignación.';

  @override
  String get fleetStatusOnline => 'En línea';

  @override
  String get fleetStatusDraining => 'Drenando';

  @override
  String get fleetStatusOffline => 'Sin conexión';

  @override
  String get fleetStatusIncompatible => 'Incompatible';

  @override
  String get fleetStatusRevoked => 'Revocado';

  @override
  String get fleetJobStatusQueued => 'En cola';

  @override
  String get fleetJobStatusRunning => 'En ejecución';

  @override
  String get fleetJobStatusSucceeded => 'Correcto';

  @override
  String get fleetJobStatusFailed => 'Fallido';

  @override
  String get fleetJobStatusCancelled => 'Cancelado';

  @override
  String get evalsNoSuites => 'Aún no hay conjuntos de evaluación.';

  @override
  String get evalsError => 'No se pudieron cargar las evaluaciones';

  @override
  String get evalsStarterBadge => 'Inicial';

  @override
  String evalsDefaultBatch(int count) {
    return 'Lote predeterminado de $count';
  }

  @override
  String get evalsRecentRuns => 'Ejecuciones recientes';

  @override
  String get evalsNoRuns => 'Aún no hay ejecuciones.';

  @override
  String get evalsPassRate => 'Tasa de aprobación';

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
    return 'Evaluación terminada — $rate aprobado';
  }

  @override
  String get evalsRunFailed => 'No se pudo ejecutar el conjunto';

  @override
  String get evalsRun => 'Ejecutar';

  @override
  String get evalsStatusQueued => 'En cola';

  @override
  String get evalsStatusRunning => 'En ejecución';

  @override
  String get evalsStatusPassed => 'Aprobado';

  @override
  String get evalsStatusFailed => 'Fallido';

  @override
  String get bannerMeetingJoin => 'Unirse';

  @override
  String get bannerMeetingRecordAndLink => 'Grabar y vincular';

  @override
  String get bannerCalendarReconnect => 'Reconectar';

  @override
  String get bannerView => 'Ver';

  @override
  String get soundscapeTitle => 'Paisajes sonoros';

  @override
  String get soundscapePlay => 'Reproducir';

  @override
  String get soundscapePause => 'Pausar';

  @override
  String get soundscapeMoodLabel => 'Ambiente';

  @override
  String get soundscapeMoodFocus => 'Concentración';

  @override
  String get soundscapeMoodRelax => 'Relajación';

  @override
  String get soundscapeMoodSleep => 'Sueño';

  @override
  String get soundscapeVolumeLabel => 'Volumen';

  @override
  String get soundscapeTuneLabel => 'Ajuste';

  @override
  String get soundscapeTuneMellow => 'Suave';

  @override
  String get soundscapeTuneBright => 'Brillante';

  @override
  String get soundscapeTuneEnergetic => 'Enérgico';

  @override
  String get soundscapeTuneSpacy => 'Espacial';

  @override
  String get soundscapeTuneResetHint => 'Toca dos veces para restablecer';

  @override
  String get soundscapeSceneLabel => 'Reproduciendo ahora';

  @override
  String get soundscapeSceneLoading => 'Ajustando el ambiente…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees °C';
  }

  @override
  String get soundscapeLocationLabel => 'Ubicación';

  @override
  String get soundscapeLocationDetecting => 'Detectando ubicación…';

  @override
  String get soundscapeLocationAutoNote =>
      'La ubicación se detecta automáticamente desde este espacio de trabajo.';

  @override
  String get soundscapeRefreshWeather => 'Actualizar el tiempo';

  @override
  String get soundscapeAutoStartLabel => 'Iniciar con el modo concentración';

  @override
  String get soundscapeAutoStartDescription =>
      'Reproduce un paisaje sonoro automáticamente cuando inicias una sesión de concentración.';

  @override
  String get soundscapeReturnToApp => 'Volver a la aplicación';

  @override
  String get soundscapePopOut => 'Separar el reproductor';

  @override
  String get newParenthesis => 'Nuevo paréntesis';

  @override
  String get parenthesisTitleHint => 'p. ej. arreglo rápido';

  @override
  String get discussion => 'Debate';

  @override
  String get chat => 'Chat';

  @override
  String get saving => 'Guardando…';

  @override
  String get saved => 'Guardado';

  @override
  String get saveFailed => 'No se pudo guardar';

  @override
  String get commitAndPush => 'Confirmar y subir';

  @override
  String get commit => 'Confirmar';

  @override
  String get commitAmend => 'Confirmar (enmendar)';

  @override
  String get commitAndSync => 'Confirmar y sincronizar';

  @override
  String get committed => 'Confirmado';

  @override
  String get commitAmended => 'Confirmación enmendada';

  @override
  String get commitFailed => 'Error al confirmar';

  @override
  String get moreCommitActions => 'Más acciones de confirmación';

  @override
  String get sourceControl => 'Control de código fuente';

  @override
  String fixFindingTitle(String location) {
    return 'Corregir: $location';
  }

  @override
  String get reviewSplitLayout => 'Diseño de revisión';

  @override
  String get openInEditor => 'Abrir en el editor';

  @override
  String uncommittedChanges(int count) {
    return '$count cambios sin confirmar';
  }

  @override
  String get commitMessageHint => 'Mensaje de confirmación';

  @override
  String get pushedToPr => 'Subido a la PR';

  @override
  String get pushFailed => 'Error al subir';

  @override
  String get openAtPrHead => 'Abrir en el head de la PR';

  @override
  String get reviewFindings => 'Hallazgos';

  @override
  String get treeLabel => 'Árbol';

  @override
  String get toggleFileTree => 'Mostrar u ocultar el árbol de archivos';

  @override
  String get diffViewSettings => 'Ajustes de vista del diff';

  @override
  String get splitViewLabel => 'Dividida';

  @override
  String get unifiedViewLabel => 'Unificada';

  @override
  String get wrapLines => 'Ajustar líneas';

  @override
  String get shiftClickSelectRange => 'Mayús-clic para seleccionar un rango';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos',
      one: '1 archivo',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'PR pequeña — $files, ~$minutes min de revisión';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'PR mediana — $files, reserva ~$minutes min de revisión';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'PR grande — $files, considera dividirla antes de revisarla';
  }

  @override
  String get searchInFiles => 'Buscar en archivos';

  @override
  String get showFileList => 'Mostrar lista de archivos';

  @override
  String get searchInFilesHintField => 'Buscar en archivos…';

  @override
  String get searchInFilesHint => 'Buscar en los archivos de la pull request';

  @override
  String get searchNoResults => 'Sin resultados';

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
      other: '$files archivos',
      one: '1 archivo',
    );
    return '$_temp0 en $_temp1';
  }

  @override
  String get discardChangesTitle => '¿Descartar cambios?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos',
      one: '1 archivo',
    );
    return '¿Restablecer $_temp0 a HEAD? Esto no se puede deshacer.';
  }

  @override
  String get discardAll => 'Descartar todo';

  @override
  String get discardFailed => 'No se pudieron descartar los cambios';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos descartados',
      one: '1 archivo descartado',
    );
    return '$_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted archivos descartados',
      one: '1 archivo descartado',
    );
    return '$_temp0; $skipped omitido(s) (sin seguimiento)';
  }

  @override
  String get prWorktreeUnavailable => 'Espacio de trabajo no listo';

  @override
  String get prWorktreeUnavailableHint =>
      'No se pudieron preparar los archivos de la pull request. Vuelve a abrir la pull request para reintentar.';

  @override
  String get timestampRelativeLabel => 'Relativo';

  @override
  String get timestampRawLabel => 'Marca de tiempo';

  @override
  String get copyTimestamp => 'Copiar marca de tiempo';

  @override
  String get copiedTimestamp => 'Marca de tiempo copiada';

  @override
  String get previewDeployment => 'Despliegue de vista previa';

  @override
  String previewDeploymentTab(String site) {
    return 'Vista previa: $site';
  }

  @override
  String get askForReview => 'Pedir revisión…';

  @override
  String get closePrsConfirmTitle => '¿Cerrar las pull requests?';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Cerrar $count pull requests?',
      one: '¿Cerrar 1 pull request?',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests cerradas',
      one: '1 pull request cerrada',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests asignadas',
      one: '1 pull request asignada',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Revisión solicitada en $count pull requests',
      one: 'Revisión solicitada en 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count acciones fallaron',
      one: '1 acción falló',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'Diagrama';

  @override
  String get diagramViewSource => 'Ver la fuente';

  @override
  String get diagramHideSource => 'Ocultar la fuente';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'Vista previa del diagrama no disponible ($reason)';
  }

  @override
  String get planUnavailable => 'Plan no disponible';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pasos',
      one: '1 paso',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'Aprobar y ejecutar';

  @override
  String get planStatusDraft => 'Borrador';

  @override
  String get planStatusProposed => 'Plan';

  @override
  String get planStatusApproved => 'Plan aprobado';

  @override
  String get planStatusRejected => 'Plan rechazado';

  @override
  String get planStatusSuperseded => 'Plan reemplazado';

  @override
  String planRevisionLabel(int revision) {
    return 'Revisión $revision';
  }

  @override
  String get adapterEnforcementTitle => 'Lo que aplica este adaptador';

  @override
  String get enforcementFiltersToolSurface =>
      'Control Center elige las herramientas';

  @override
  String get enforcementInterceptsToolCalls =>
      'Cada llamada se controla antes de ejecutarse';

  @override
  String get enforcementObservesCompletionContract =>
      'La ejecución responde por su entregable';

  @override
  String get enforcementNativeToolsInterceptable =>
      'Las herramientas propias del motor son visibles';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'Las herramientas en proceso están aisladas';

  @override
  String get enforcementYes => 'Sí';

  @override
  String get enforcementNo => 'No';

  @override
  String get adapterEnforcementCaveats => 'Advertencias';

  @override
  String get enforcementSummaryModesEnforced => 'Modos aplicados';

  @override
  String get enforcementSummaryModesNotEnforced => 'Modos no aplicados';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count advertencias',
      one: '1 advertencia',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'Los modos de solo lectura no son estructurales: Control Center no puede quitar las herramientas propias de este motor.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'Sin control previo a la ejecución: solo las llamadas a herramientas MCP pasan por Control Center.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'Las herramientas de archivos y shell propias del motor nunca llegan a Control Center; el aislamiento del sistema es su única barrera.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'Las herramientas de archivos en proceso se ejecutan fuera del aislamiento, así que la superficie de herramientas es el único límite del sistema de archivos.';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center no puede insistir ni hacer fallar una ejecución que termina sin producir su entregable.';

  @override
  String get modeDegraded => 'Degradado';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return 'El modo $mode en $adapter depende solo del aislamiento; las herramientas de archivos del agente no se interceptan.';
  }

  @override
  String get artifactUnavailable => 'Artefacto no disponible';

  @override
  String artifactRevisionLabel(int count) {
    return '$count revisiones';
  }

  @override
  String get artifactShowMore => 'Mostrar más';

  @override
  String get artifactShowLess => 'Mostrar menos';

  @override
  String get artifactCopy => 'Copiar';

  @override
  String get artifactCopied => 'Artefacto copiado';

  @override
  String get artifactsTabLabel => 'Artefactos';

  @override
  String get artifactsEmptyTitle => 'Aún no hay artefactos';

  @override
  String get artifactsEmptyBody =>
      'Cuando un agente publique una tabla, un gráfico o un diagrama aquí, aparecerá en esta lista.';

  @override
  String get artifactRevisionPickerLabel => 'Revisión';

  @override
  String get artifactRestoreRevision => 'Restaurar esta revisión';

  @override
  String get artifactOpenInTab => 'Abrir en una pestaña';

  @override
  String get artifactTitleFallback => 'Artefacto';

  @override
  String get providerGenerationLabel => 'Valores de generación predeterminados';

  @override
  String get providerGenerationHint =>
      'Deja un campo vacío para usar el valor predeterminado del endpoint. Cada modelo publica sus propios límites de salida y recetas de muestreo; otros valores pueden degradarlo.';

  @override
  String get providerMaxTokensLabel => 'Tokens de salida máx.';

  @override
  String get providerTemperatureLabel => 'Temperatura';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => 'Valores de generación guardados';

  @override
  String get providerGenerationInvalid =>
      'Revisa los valores: los tokens de salida máx. y el top-k deben ser positivos, la temperatura 0–2, el top-p 0–1.';

  @override
  String get providerGenerationOverridden => 'Personalizado';

  @override
  String get channelFlyoutNeedsInput => 'Necesita tu respuesta';

  @override
  String get channelFlyoutPreparing => 'Preparando';

  @override
  String get channelFlyoutSetupFailed => 'Error de configuración';

  @override
  String get channelFlyoutNeverRun => 'Ningún agente ha trabajado aquí todavía';

  @override
  String channelFlyoutContextUsage(String used, String percent) {
    return 'Ventana de contexto: $used usados, $percent llena';
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
  String get branchNotPushed => 'sin subir';

  @override
  String branchNotOnRemote(String branch) {
    return '«$branch» solo existe en esta conversación';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub nunca ha visto esta rama, así que una pull request todavía no puede usarla. Publicar sube los commits que ya están en el worktree; los cambios sin confirmar se dejan intactos.';

  @override
  String get publishBranch => 'Publicar rama';

  @override
  String branchPublished(String branch) {
    return '«$branch» publicada en origin';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'Rama publicada. No se incluyeron $count cambio(s) sin confirmar.';
  }

  @override
  String get composePrLoadingBranches => 'Cargando ramas desde GitHub…';

  @override
  String get composePrBranchesFailed =>
      'No se pudieron cargar las ramas desde GitHub. Escribe un nombre de rama o revisa la conexión con GitHub.';

  @override
  String get composePrSubtitleFromChannel =>
      'Desde la rama de esta conversación: publícala primero si GitHub no la conoce';

  @override
  String get obsTabInsights => 'Resumen';

  @override
  String get obsTabLive => 'En vivo';

  @override
  String get obsTabQuality => 'Calidad';

  @override
  String get obsScreenSubtitle =>
      'Control de agentes en vivo, atribución de costos, cuotas y señales de calidad';

  @override
  String get obsRangeLast24h => 'Últimas 24 horas';

  @override
  String get obsRangeLast7d => 'Últimos 7 días';

  @override
  String get obsRangeLast30d => 'Últimos 30 días';

  @override
  String get obsRangeAll => 'Todo';

  @override
  String get obsAddFilter => 'Añadir filtro';

  @override
  String get obsFilterAgent => 'Agente';

  @override
  String get obsFilterModel => 'Modelo';

  @override
  String get obsFilterStatus => 'Estado';

  @override
  String get obsFilterRole => 'Rol';

  @override
  String get obsKpiTotalRuns => 'Ejecuciones totales';

  @override
  String get obsKpiTotalCost => 'Costo total';

  @override
  String get obsKpiErrorRate => 'Tasa de error';

  @override
  String get obsKpiCacheRate => 'Tasa de caché';

  @override
  String get obsKpiTokensPerSec => 'Tokens / s';

  @override
  String get obsKpiAvgLatency => 'Latencia media';

  @override
  String get obsKpiTtft => 'Tiempo hasta el primer token';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta vs período anterior';
  }

  @override
  String get obsChartActivity => 'Actividad';

  @override
  String get obsChartCost => 'Costo a lo largo del tiempo';

  @override
  String get obsLegendRuns => 'Ejecuciones';

  @override
  String get obsLegendErrors => 'Errores';

  @override
  String get obsAgentsTitle => 'Agentes';

  @override
  String obsShowAllAgents(int count) {
    return 'Mostrar los $count agentes';
  }

  @override
  String get obsShowFewerAgents => 'Mostrar menos';

  @override
  String get obsRunsTitle => 'Ejecuciones';

  @override
  String get obsNoRunsInRange => 'No hay ejecuciones en este período';

  @override
  String get obsColTime => 'Hora';

  @override
  String get obsColAgent => 'Agente';

  @override
  String get obsColStatus => 'Estado';

  @override
  String get obsColModel => 'Modelo';

  @override
  String get obsColDuration => 'Duración';

  @override
  String get obsColTokens => 'Tokens';

  @override
  String get obsColCost => 'Costo';

  @override
  String get obsColErrors => 'Errores';

  @override
  String get obsColRuns => 'Ejecuciones';

  @override
  String get obsColAvgLatency => 'Latencia media';

  @override
  String get obsColLastActive => 'Última actividad';

  @override
  String get obsStatusPending => 'Pendiente';

  @override
  String get obsStatusRunning => 'En curso';

  @override
  String get obsStatusCompleted => 'Completado';

  @override
  String get obsStatusError => 'Error';

  @override
  String get obsRosterLoadError => 'No se pudo cargar la lista de agentes.';

  @override
  String get obsRosterEmpty => 'Aún no hay agentes';

  @override
  String get obsRosterEmptyDescription =>
      'Ejecuta un agente y aparecerá aquí en vivo: estado, herramienta actual, tokens, costo.';

  @override
  String get obsKillAgent => 'Detener agente';

  @override
  String get obsRosterTokensLabel => 'tok';

  @override
  String get obsCostByRoleTitle => 'Costo por rol';

  @override
  String get obsCostByRoleSubtitle =>
      'En qué gasta este espacio de trabajo, por rol de agente';

  @override
  String get obsRoleMain => 'Principal';

  @override
  String get obsRoleSubagents => 'Subagentes';

  @override
  String get obsRoleAdvisor => 'Asesor';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'Principal: $main · subagentes: $sub · asesor: $advisor';
  }

  @override
  String get obsTotal => 'Total';

  @override
  String get obsTokenModelTitle => 'Modelo de tokens (5 ejes)';

  @override
  String get obsTokenModelSubtitle =>
      'Todos los tokens gastados por este espacio, por eje';

  @override
  String get obsAxisInput => 'Entrada';

  @override
  String get obsAxisOutput => 'Salida';

  @override
  String get obsAxisReasoning => 'Razonamiento';

  @override
  String get obsAxisCacheRead => 'Lectura de caché';

  @override
  String get obsAxisCacheWrite => 'Escritura de caché';

  @override
  String get obsTotalTokens => 'Tokens totales';

  @override
  String get obsCacheDiscountNote =>
      'Los tokens leídos de caché se facturan con descuento, por lo que cuestan mucho menos que el mismo volumen de entrada nueva.';

  @override
  String get obsByModelTitle => 'Por modelo';

  @override
  String get obsByModelSubtitle => 'Uso de tokens y costo por modelo';

  @override
  String get obsNoModelUsage => 'Aún no se registró uso de modelos.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ejecuciones',
      one: '1 ejecución',
    );
    return '$_temp0';
  }

  @override
  String obsTokensSuffix(String tokens) {
    return '$tokens tokens';
  }

  @override
  String get obsPerRunTitle => 'Por ejecución';

  @override
  String get obsPerRunSubtitle => 'Costo típico en tokens de una ejecución';

  @override
  String get obsMedianRunTokens => 'Tokens medianos por ejecución';

  @override
  String get obsMedianRunTokensSub => 'Mediana de todas las ejecuciones';

  @override
  String get obsRunsInWorkspace => 'En este espacio';

  @override
  String get obsCostShare => 'Parte del costo';

  @override
  String get obsQuotaConfiguredLimits => 'Límites configurados';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'Uso frente a los techos definidos, el peor estado primero.';

  @override
  String get obsQuotaAddLimit => 'Añadir límite';

  @override
  String get obsQuotaNoLimits =>
      'Aún no hay límites de cuota configurados: añade uno para seguir el uso frente a un techo.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'Eliminar el límite $title';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'Se restablece en $duration · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'Ventanas de uso';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'Uso observado en todos los proveedores, sin techo aplicado.';

  @override
  String get obsQuotaNoUsage => 'Aún no se registró uso.';

  @override
  String get obsQuotaTokensUsed => 'Tokens usados';

  @override
  String get obsQuotaRequests => 'Solicitudes';

  @override
  String get obsQuotaUnitTokens => 'tokens';

  @override
  String get obsQuotaUnitRequests => 'solicitudes';

  @override
  String get obsQuotaUnitCost => 'costo';

  @override
  String get obsQuotaAddLimitTitle => 'Añadir límite de cuota';

  @override
  String get obsQuotaProviderLabel => 'Proveedor';

  @override
  String get obsQuotaWindowLabel => 'Ventana';

  @override
  String get obsQuotaUnitLabel => 'Unidad';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'Límite ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'En centavos estadounidenses (500 = \$5.00).';

  @override
  String get obsQuotaStatusOk => 'Ok';

  @override
  String get obsQuotaStatusWarning => 'Advertencia';

  @override
  String get obsQuotaStatusExhausted => 'Agotado';

  @override
  String get obsQuotaStatusUnknown => 'Desconocido';

  @override
  String get obsGoalNoActiveTitle => 'Sin objetivo activo';

  @override
  String get obsGoalNoActiveBody =>
      'Define un objetivo para dar a los agentes un propósito y un presupuesto de tokens opcional. A medida que las ejecuciones se completan, el presupuesto se llena y se pide a los agentes que concluyan cuando esté casi agotado.';

  @override
  String get obsGoalSetGoal => 'Definir un objetivo';

  @override
  String get obsGoalTokenBudget => 'Presupuesto de tokens';

  @override
  String obsGoalTokensLeft(String tokens) {
    return 'Quedan $tokens';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (sin presupuesto definido)';
  }

  @override
  String get obsGoalTokensUsed => 'Tokens usados';

  @override
  String get obsGoalElapsed => 'Transcurrido';

  @override
  String get obsGoalWrapUp => 'Concluir';

  @override
  String get obsGoalClear => 'Borrar objetivo';

  @override
  String get obsGoalFallbackTitle => 'Objetivo';

  @override
  String get obsGoalSubtitle => 'Presupuesto del modo objetivo';

  @override
  String get obsGoalStatusActive => 'Activo';

  @override
  String get obsGoalStatusPaused => 'En pausa';

  @override
  String get obsGoalStatusBudgetLimited => 'Presupuesto limitado';

  @override
  String get obsGoalStatusComplete => 'Completado';

  @override
  String get obsGoalStatusDropped => 'Abandonado';

  @override
  String get obsGoalObjectiveLabel => 'Objetivo';

  @override
  String get obsGoalBudgetLabel => 'Presupuesto de tokens (opcional)';

  @override
  String get obsGoalSetAction => 'Definir objetivo';

  @override
  String get obsBenchmarkCaption =>
      'Una vista puntuada de las ejecuciones recientes de los agentes: acierto/fallo, recompensa y gasto por tarea.';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => 'Éxito %';

  @override
  String get obsBenchmarkPassed => 'Aprobadas';

  @override
  String get obsBenchmarkFailed => 'Fallidas';

  @override
  String get obsBenchmarkErrors => 'Errores';

  @override
  String get obsBenchmarkSpend => 'Gasto';

  @override
  String get obsBenchmarkCostPerTask => 'Costo / tarea';

  @override
  String get obsBenchmarkTrials => 'Pruebas';

  @override
  String get obsBenchmarkNoTrials => 'Aún no hay ejecuciones para puntuar.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'y $count más',
      one: 'y 1 más',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'Aprobada';

  @override
  String get obsBenchmarkTrialFail => 'Fallida';

  @override
  String get obsBenchmarkTrialError => 'Error';

  @override
  String get obsBenchmarkTrialRunning => 'En curso';

  @override
  String get obsBenchmarkReward => 'Recompensa';

  @override
  String get obsBenchmarkReport => 'Informe';

  @override
  String get obsBenchmarkCopyMarkdown => 'Copiar markdown';

  @override
  String get obsBenchmarkCopied => 'Informe copiado al portapapeles';

  @override
  String get obsBehaviorCaption =>
      'Estas son señales de frustración extraídas de tus propios mensajes: una lectura de la salud de la conversación, no una nota para los agentes. Calculado localmente; nada sale de este dispositivo.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'Mensajes analizados';

  @override
  String get obsBehaviorTotalSignals => 'Señales totales';

  @override
  String get obsBehaviorYelling => 'Gritos';

  @override
  String get obsBehaviorProfanity => 'Palabrotas';

  @override
  String get obsBehaviorAnguish => 'Angustia';

  @override
  String get obsBehaviorNegation => 'Negación';

  @override
  String get obsBehaviorRepetition => 'Repetición';

  @override
  String get obsBehaviorBlame => 'Culpa';

  @override
  String get obsBehaviorConversationsTitle => 'Conversaciones más frustradas';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'Ordenadas por densidad de señales en tus mensajes.';

  @override
  String get obsBehaviorNoSignals =>
      'No se detectaron señales de frustración: todo en orden.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count mensajes analizados';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count señales';
  }

  @override
  String get obsAgentStatusIdle => 'Inactivo';

  @override
  String get obsAgentStatusParked => 'Aparcado';

  @override
  String get obsAgentStatusAborted => 'Abortado';

  @override
  String get obsAgentKindSub => 'Subagente';

  @override
  String get noChecksOnCommit => 'No se han ejecutado checks en este commit.';

  @override
  String get ciCdChecks => 'CI/CD checks';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ejecutando — $count trabajos',
      one: 'Ejecutando — 1 trabajo',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Todos los checks pasaron — $count trabajos',
      one: 'Todos los checks pasaron — 1 trabajo',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Completado — $count trabajos',
      one: 'Completado — 1 trabajo',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total trabajos',
      one: '1 trabajo',
    );
    return '$failed de $_temp0 con error';
  }

  @override
  String checksFailingBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count con error',
      one: '1 con error',
    );
    return '$_temp0';
  }

  @override
  String get checkCompletedSuccessfully => 'Completado correctamente';

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trabajos',
      one: '1 trabajo',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'Matriz: $jobId';
  }

  @override
  String get jobLogsPending =>
      'Los logs aparecerán aquí cuando termine el trabajo.';

  @override
  String get jobLogsUnavailable =>
      'Los logs no están disponibles para este trabajo.';

  @override
  String get noLogsForStep => 'No hay logs para este paso.';

  @override
  String get jobLogsTruncated =>
      'Log truncado — se muestra la salida más reciente.';

  @override
  String get fullLog => 'Log completo';

  @override
  String get copyLogs => 'Copiar logs';

  @override
  String get resizeGraph => 'Arrastrar para redimensionar el gráfico';

  @override
  String workflowRunStartedAgo(String time) {
    return 'Iniciado $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'Completado $time';
  }

  @override
  String get chatBridgesTitle => 'Puentes de chat';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'Menciona al bot en $provider para encargar algo a un agente, o crea tickets con $command.';
  }

  @override
  String chatConnectProvider(String provider) {
    return 'Conectar $provider';
  }

  @override
  String get chatDisconnectProvider => 'Desconectar';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName en $teamName';
  }

  @override
  String get chatStateLive => 'En vivo';

  @override
  String get chatStateConnecting => 'Conectando…';

  @override
  String get chatStateError => 'Error de conexión';

  @override
  String get chatNotConnected => 'Sin conectar';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'El streaming en vivo está desactivado para esta app de $provider: las respuestas llegan en un solo mensaje.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'Solo un administrador puede conectar $provider en este espacio de trabajo.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'Crea una app de $provider y pega aquí sus credenciales. Control Center se conecta hacia $provider, así que este servidor no necesita dirección pública.';
  }

  @override
  String chatOpenConsole(String provider) {
    return 'Abrir la consola de $provider';
  }

  @override
  String get chatOpenSetupGuide => 'Guía de configuración';

  @override
  String get chatFieldBotToken => 'Token del bot';

  @override
  String get chatFieldAppToken => 'Token de aplicación';

  @override
  String get chatFieldConfigRefreshToken => 'Token de configuración de la app';

  @override
  String chatFieldOptional(String label) {
    return '$label (opcional)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'Vincular mi cuenta de $provider';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'Vincula tu cuenta de $provider para que los mensajes que envíes allí se te atribuyan.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'Vinculado a $externalUserId';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'Vincula tu cuenta de $provider';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'Envía este comando al bot en $provider. Funciona una sola vez y caduca en 15 minutos.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'Tu cuenta de $provider ya está vinculada: los mensajes que envíes allí se te atribuirán.';
  }

  @override
  String get chatLinkedAccounts => 'Cuentas vinculadas';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'Nadie ha vinculado aún su cuenta de $provider.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cuentas vinculadas',
      one: '1 cuenta vinculada',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · emparejado por correo';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · vinculado con un código';
  }

  @override
  String get chatUnlink => 'Desvincular';

  @override
  String get chatCustomizeBot => 'Personalizar el bot';

  @override
  String get chatCustomizeBotDescription =>
      'Renombra el bot, cambia lo que dice de sí mismo o renombra el comando.';

  @override
  String get chatCustomizeBotUnavailable =>
      'Control Center necesita un token de configuración de la app para editar el bot. Vuelve a conectar incluyendo uno.';

  @override
  String chatCreateAppTitle(String provider) {
    return 'Crear la app de $provider';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center puede crear la app de $provider por ti, con los permisos y eventos correctos ya configurados. Terminarás en $provider y luego pegarás aquí las credenciales.';
  }

  @override
  String get chatCreateApp => 'Crear app';

  @override
  String get chatCreateAppCta => 'Crear la app por mí';

  @override
  String get chatAppNameLabel => 'Nombre de la app';

  @override
  String get chatBotDisplayNameLabel =>
      'Nombre del bot (lo que se escribe tras @)';

  @override
  String get chatDescriptionLabel => 'Descripción corta';

  @override
  String get chatAgentDescriptionLabel => 'Lo que el bot dice que puede hacer';

  @override
  String get chatCommandLabel => 'Comando';

  @override
  String get chatDirectMessages => 'Mensajes directos';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'Permite hablar con el bot por mensaje directo. Puede requerir un plan de pago de $provider.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$provider creó la app $appId.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'Quedan unos pasos que solo $provider puede hacer:';
  }

  @override
  String get chatStepAppToken => 'Generar un token de aplicación';

  @override
  String get chatStepInstall => 'Instalar la app';

  @override
  String get chatOpenAppSettings => 'Abrir los ajustes de la app';

  @override
  String get chatContinueToCredentials => 'Pegar las credenciales';

  @override
  String chatBotUpdated(String provider) {
    return 'Bot actualizado en $provider.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$provider cambió los permisos de la app. Reinstálala para que surtan efecto.';
  }

  @override
  String get chatReinstallApp => 'Reinstalar la app';

  @override
  String chatIconNotEditable(String provider) {
    return 'El icono del bot solo se puede cambiar en los ajustes de app de $provider.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'También puedes crearla tú mismo en $provider, sin token. Los ajustes de arriba viajan con el enlace.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'Crear en $provider';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '$provider se abrió en tu navegador con esta configuración precargada. Crea la app allí, completa estos pasos y vuelve con los tokens.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider no informa qué app creó, así que personalizar el bot desde aquí necesitará más adelante un token de configuración de la app.';
  }

  @override
  String get chatStepCreateApp =>
      'Crear la app desde la configuración precargada';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'Elige un espacio de trabajo en $provider y confirma.';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens, con el ámbito connections:write.';

  @override
  String get chatStepInstallHint =>
      'Install app → copia el token OAuth del usuario bot.';

  @override
  String get calendarUseBuiltinApp => 'Usar la app de Google de Control Center';

  @override
  String get calendarUseBuiltinAppHint =>
      'Autoriza con tu cuenta de Google. Nada que configurar en Google Cloud.';

  @override
  String get calendarUseOwnClient => 'Usar mi propio cliente de Google Cloud';

  @override
  String get calendarUseOwnClientHint =>
      'Introduce un cliente OAuth de tu propio proyecto de Google Cloud.';

  @override
  String get aboutTitle => 'Acerca de';

  @override
  String get aboutAppVersion => 'Versión de la aplicación';

  @override
  String get aboutServerVersion => 'Servidor conectado';

  @override
  String get aboutRpcCatalog => 'Catálogo RPC';

  @override
  String get aboutServerUnknown => 'No informado';

  @override
  String get serverStaleTitle =>
      'El servidor integrado es anterior a esta aplicación';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'El cc_server en ejecución es $serverVersion mientras que esta aplicación es $appVersion. Reinicia la aplicación para que use la última versión del servidor integrado; en desarrollo, recompílalo con `dart build cli` en apps/cc_server.';
  }

  @override
  String get updateCheckButton => 'Buscar actualizaciones';

  @override
  String get updateChecking => 'Buscando actualizaciones…';

  @override
  String get updateUpToDate => 'Estás al día';

  @override
  String get updateDeferredBusy =>
      'Hay una actualización lista pero se está grabando una reunión; se ofrecerá cuando termine.';

  @override
  String get updateOpenedReleasesPage =>
      'Se abrió la página de versiones en tu navegador.';

  @override
  String get updateCheckFailed => 'Error al buscar actualizaciones';

  @override
  String updateAvailableVersion(String version) {
    return 'La versión $version está disponible.';
  }

  @override
  String get updateBannerTitle =>
      'Hay una nueva versión de Control Center disponible';

  @override
  String get updateBannerRefresh => 'Actualizar';

  @override
  String get updateBlockedRecording =>
      'La actualización está en pausa mientras se graba una reunión; se recargará al terminar.';

  @override
  String get settingsScopeYou => 'Tú';

  @override
  String get settingsScopeWorkspace => 'Espacio de trabajo';

  @override
  String get settingsScopeServer => 'Servidor';

  @override
  String get settingsProfile => 'Perfil e identidad';

  @override
  String get settingsYourDevices => 'Tus dispositivos';

  @override
  String get settingsWorkspaceGeneral => 'General';

  @override
  String get settingsServerConnection => 'Conexión y estado';

  @override
  String get settingsServerSharing => 'Uso compartido y acceso remoto';

  @override
  String get settingsModelProviders => 'Proveedores de modelos';

  @override
  String get settingsVoiceModels => 'Modelos de voz y reuniones';

  @override
  String get settingsDiagnostics => 'Diagnóstico y privacidad';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsScopeBadgeYou => 'TÚ';

  @override
  String get settingsScopeBadgeDevice => 'ESTE DISPOSITIVO';

  @override
  String get settingsScopeBadgeWorkspace => 'ESPACIO DE TRABAJO';

  @override
  String get settingsScopeBadgeServer => 'SERVIDOR';

  @override
  String get settingsProfileDescription =>
      'Tu nombre, correo e identidad de git que se estampa en los commits hechos en tu nombre.';

  @override
  String get settingsServerConnectionDescription =>
      'A qué servidor se conecta este cliente y qué informa.';

  @override
  String get settingsServerSharingDescription =>
      'Anuncia este servidor en la red local o expónlo mediante un túnel.';

  @override
  String get settingsAboutDescription =>
      'Identidad de la compilación y actualizaciones.';

  @override
  String get settingsDiagnosticsDescription =>
      'Aislamiento, indexación, sincronización, registro e informes de errores de esta instalación.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'Identidad, políticas y convenciones que comparten todos en este espacio de trabajo.';

  @override
  String get settingsWorkspacePolicyLabel => 'Política del espacio de trabajo';

  @override
  String get settingsWorkspacePolicyDescription =>
      'Se aplica a cada miembro y cada agente de este espacio de trabajo.';

  @override
  String get settingsSecretGlobsLabel => 'Rutas secretas excluidas';

  @override
  String get settingsSecretGlobsHelp =>
      'Un patrón por línea. Estas rutas se ocultan a lectores e invitados en las superficies de código, además de los valores predeterminados.';

  @override
  String get settingsReviewConcurrencyLabel => 'Revisores en paralelo';

  @override
  String get settingsReviewConcurrencyHelp =>
      'Cuántos revisores se despachan en paralelo cuando no se indica un número explícito.';

  @override
  String get settingsWorkspaceAdminOnly =>
      'Solo los administradores del espacio de trabajo pueden cambiarlo.';

  @override
  String get chatMyAccountsTitle => 'Cuentas de chat vinculadas';
}
