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
      'Decide qué pueden hacer los agentes por su cuenta, qué deben preguntar antes o qué no pueden hacer nunca — por espacio de trabajo, agente o espacio.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Establece una decisión para cada tipo de efecto. Las reglas se heredan: el espacio prevalece sobre el agente, que prevalece sobre el espacio de trabajo.';

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
  String get guardrailScopeSpace => 'Espacio';

  @override
  String get guardrailSelectAgent => 'Selecciona un agente';

  @override
  String get guardrailSelectSpace => 'Selecciona un espacio';

  @override
  String get guardrailNoAgents =>
      'Aún no hay agentes en este espacio de trabajo.';

  @override
  String get guardrailNoSpaces =>
      'Aún no hay espacios en este espacio de trabajo.';

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
  String get guardrailClassEnclosureControl => 'Controlar un recinto (rig)';

  @override
  String get navRigs => 'Rigs';

  @override
  String get rigsUnsupportedServer =>
      'Este servidor no puede alojar VM aisladas. Los rigs necesitan un hipervisor en la máquina que ejecuta cc_server.';

  @override
  String get rigSurfaceComputer => 'Ordenador';

  @override
  String get rigSurfaceBrowser => 'Navegador';

  @override
  String get rigSurfaceMobile => 'Móvil';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return 'Un $engine desechable, aislado de tu máquina. Abre otro motor para comparar la misma página en paralelo.';
  }

  @override
  String get rigPhaseReady => 'Listo';

  @override
  String get rigPhaseStarting => 'Iniciando';

  @override
  String get rigPhaseParked => 'En pausa';

  @override
  String get rigPhaseClosing => 'Cerrando';

  @override
  String get rigPhaseClosed => 'Cerrado';

  @override
  String get rigPhaseFailed => 'Error';

  @override
  String get rigPhaseUnknown => 'Desconocido';

  @override
  String get rigNotAccelerated => 'Emulado';

  @override
  String get rigAudioListen => 'Escuchar la máquina';

  @override
  String get rigAudioMute => 'Silenciar la máquina';

  @override
  String get rigYouHaveControl => 'Tienes el control';

  @override
  String get rigBackendAvailable => 'Disponible';

  @override
  String get rigBackendUnavailable => 'No disponible';

  @override
  String get rigEgressNotEnforced =>
      'La red no está aislada en este backend: gestiona su propia conectividad.';

  @override
  String get rigStartMachine => 'Iniciar la máquina';

  @override
  String get rigStartHint =>
      'Inicia una VM desechable que compartes con tus agentes en esta conversación. Se destruye al cerrarse y nada de lo que ocurre en ella toca tu ordenador.';

  @override
  String get rigStopMachine => 'Detener la máquina';

  @override
  String get rigSurfaceUnavailable =>
      'Este servidor no puede alojar este tipo de máquina.';

  @override
  String get rigTabNeedsConversation =>
      'Abre primero una conversación: una máquina pertenece a una, para que tus agentes y tú veáis la misma pantalla.';

  @override
  String get ideMenuSectionTools => 'Herramientas';

  @override
  String get ideMenuSectionVirtualMachine => 'Máquina virtual';

  @override
  String get ideMenuSectionReopen => 'Reabrir';

  @override
  String get ideMenuSearchHint => 'Buscar';

  @override
  String get ideMenuNoMatches => 'Sin resultados';

  @override
  String get rigMenuComputer => 'Ordenador';

  @override
  String get rigMenuBrowser => 'Navegador';

  @override
  String get rigMenuMobile => 'Teléfono';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return '¿Cerrar $name?';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'La máquina sigue funcionando en segundo plano: vuelve a abrirla cuando quieras desde la barra lateral. Apágala para liberar su memoria ahora.';

  @override
  String get ideCloseKeepBodyShell =>
      'El comando sigue ejecutándose en segundo plano: vuelve a abrir la shell cuando quieras desde la barra lateral. Termínala para detener lo que está haciendo.';

  @override
  String get ideCloseKeepBodyAgent =>
      'El agente sigue trabajando en segundo plano: vuelve a abrir la conversación cuando quieras desde la barra lateral. Deténlo para terminar la ejecución ahora.';

  @override
  String get ideCloseKeepRunning => 'Mantener en marcha';

  @override
  String get ideCloseShutDownMachine => 'Apagar';

  @override
  String get ideCloseEndShell => 'Terminar shell';

  @override
  String get ideCloseStopAgent => 'Detener agente';

  @override
  String get rigsSettingsSubtitle =>
      'Lo que este servidor puede arrancar, las imágenes base que necesita y las máquinas en marcha';

  @override
  String get rigsCapabilitiesTitle => 'Este servidor';

  @override
  String get rigsImagesTitle => 'Imágenes base';

  @override
  String get rigsImagesHint =>
      'Cada rig arranca desde una de estas imágenes de solo lectura. Cada sesión escribe en una capa desechable, así que un rig nunca puede cambiar de dónde parte el siguiente.';

  @override
  String get rigsRunningTitle => 'En marcha';

  @override
  String get rigsNoneRunning => 'No hay máquinas en marcha.';

  @override
  String get rigsCustomImagesTitle =>
      'Imágenes personalizadas (este espacio de trabajo)';

  @override
  String get rigsCustomImagesHint =>
      'Apunta la Terminal (VM) o el Navegador (VM) a tu propia imagen — extiende las predeterminadas con las herramientas de tu proyecto, o usa una compatible desde un registro. Las máquinas nuevas la usan; las que ya corren conservan la suya. Consulta la guía de rigs para saber qué debe proveer una imagen.';

  @override
  String get rigsCustomTerminalImageLabel => 'Imagen de la Terminal (VM)';

  @override
  String get rigsCustomBrowserImageLabel => 'Imagen del Navegador (VM)';

  @override
  String get rigsCustomImagePlaceholder =>
      'p. ej. ghcr.io/acme/dev-shell:1.2 — en blanco para la predeterminada';

  @override
  String get rigsCustomImageInvalid =>
      'Introduce una referencia de registro como repo/nombre:tag. No se permiten rutas locales ni archivos.';

  @override
  String get rigsCustomImageSaved =>
      'Guardado. Las máquinas nuevas arrancan esta imagen; las que corren conservan la suya.';

  @override
  String get rigsEgressTitle =>
      'Salida del navegador (este espacio de trabajo)';

  @override
  String get rigsEgressHint =>
      'Hosts adicionales a los que puede acceder el navegador aislado — uno por línea: un host exacto (api.example.com) o un comodín para sus subdominios (*.example.com). El sitio del producto siempre está permitido. Las máquinas nuevas usan la lista; las que ya se ejecutan conservan la suya.';

  @override
  String rigsEgressInvalid(String host) {
    return '\"$host\" no es un host válido.';
  }

  @override
  String get rigsEgressSaved =>
      'Guardado. Las nuevas máquinas de navegador admiten estos hosts; las que ya se ejecutan conservan los suyos.';

  @override
  String get rigImageInstalled => 'Instalada';

  @override
  String get rigImageNotDownloaded => 'No descargada';

  @override
  String get rigImageNotPublished => 'No publicada';

  @override
  String get rigImageNotPublishedHint =>
      'Aún no se ha publicado ninguna imagen para esto, así que no hay nada que descargar. Importa una imagen de disco compatible para habilitarlo.';

  @override
  String get rigImageDownload => 'Descargar';

  @override
  String get rigImageDownloading => 'Descargando…';

  @override
  String get rigImageImport => 'Importar';

  @override
  String get rigImageImportMessage =>
      'Ruta a una imagen de disco qcow2 en el sistema de archivos del servidor. Se copia al almacén de imágenes, así que el archivo puede moverse después.';

  @override
  String get rigConnectingStream => 'Conectando con el rig';

  @override
  String get rigStreamNotAllowed => 'No tienes acceso a este rig.';

  @override
  String get rigStreamNotRunning => 'Este rig ya no está en ejecución.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'La vista en directo necesita ffmpeg en este host. Instala ffmpeg y vuelve a abrir la pestaña.';

  @override
  String get rigStreamEnded => 'La vista en directo ha terminado.';

  @override
  String get rigStreamFailed => 'No se pudo abrir la vista en directo.';

  @override
  String get rigStreamDisconnected => 'Sin conexión a un servidor.';

  @override
  String rigDropSendingOne(String name) {
    return 'Copiando «$name» en la máquina…';
  }

  @override
  String rigDropSendingMany(int count) {
    return 'Copiando $count archivos en la máquina…';
  }

  @override
  String get rigTerminalDropSending => 'Copiando en la máquina…';

  @override
  String get rigTerminalPasteImage => 'Imagen pegada guardada en la máquina';

  @override
  String get rigPortsTitle => 'Puertos reenviados';

  @override
  String get rigPortsTooltip => 'Puertos abiertos en esta máquina';

  @override
  String get rigPortsEmpty =>
      'Nada está escuchando aún. Inicia un servidor en la terminal — un servidor de desarrollo en el puerto 3000 aparece aquí.';

  @override
  String get rigPortsAdd => 'Añadir puerto';

  @override
  String get rigPortsAddHint => 'Puerto del huésped a reenviar (p. ej. 3000)';

  @override
  String get rigPortsAutoForward => 'Reenvío automático de puertos';

  @override
  String get rigPortsCopyUrl => 'Copiar URL local';

  @override
  String rigPortsCopiedUrl(String url) {
    return '$url copiado';
  }

  @override
  String get rigPortsStopForward => 'Detener el reenvío';

  @override
  String get rigPortsExposeLan => 'Compartir en la red local';

  @override
  String get rigPortsLanPrivate => 'Solo local';

  @override
  String get rigPortsLanShared => 'En la red';

  @override
  String get rigPortsSetDomain => 'Establecer un dominio del navegador (.test)';

  @override
  String get rigPortsDomainHint =>
      'Dominio para el Navegador (VM), p. ej. myapp.test — accesible allí, no en el host';

  @override
  String get rigPortsProcessUnknown => 'proceso desconocido';

  @override
  String get rigPortsInactive => 'no escucha';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count imágenes base por descargar',
      one: '1 imagen base por descargar',
    );
    return '$_temp0';
  }

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
  String get guardrailProbeSpaceLabel => 'Espacio (opcional)';

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
  String get calendarAllDayGutter => 'Todo el día';

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos',
      one: '1 evento',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => 'Contraer los eventos de todo el día';

  @override
  String get calendarExpandAllDay => 'Expandir los eventos de todo el día';

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
  String get notificationRigStatusChanged => 'Novedades de los recintos';

  @override
  String get notifyRigStatusChanged =>
      'Cuando alguien toma el control de un recinto, se recupera o falla';

  @override
  String get notificationRigTakenOver => 'Recinto tomado';

  @override
  String get notificationRigTakenOverBody =>
      'Una persona está manejando la máquina; el agente puede observar pero no actuar.';

  @override
  String get notificationRigReleased => 'Control del recinto liberado';

  @override
  String get notificationRigReleasedBody =>
      'El agente vuelve a tener la máquina.';

  @override
  String get notificationRigReclaimed => 'Recinto recuperado';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'Estuvo inactiva, así que la máquina se cerró para liberar memoria.';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'Alcanzó su límite de tiempo y se cerró.';

  @override
  String get notificationRigFailed => 'Fallo del recinto';

  @override
  String get notificationRigFailedBody =>
      'El hipervisor murió por debajo. Vuelve a abrir la máquina para continuar.';

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
  String get stopAgentRun => 'Detener ejecución';

  @override
  String get stopAgentRunConfirm =>
      '¿Detener esta ejecución? Se perderá el trabajo en curso.';

  @override
  String get inProgress => 'En curso';

  @override
  String get drafts => 'Borradores';

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
  String get keybindingOpenFilterMenu => 'Abrir el menú de filtros';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'Abrir el menú de filtros de PR';

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
  String get advanced => 'Avanzado';

  @override
  String get accounts => 'Cuentas';

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
  String get voiceAndMeetingsSettingsDescription =>
      'Los modelos de voz y diarización que aloja este servidor.';

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
  String get filterSpacesHint => 'Filtrar espacios';

  @override
  String noSpacesMatch(String query) {
    return 'Ningún espacio coincide con «$query»';
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
  String lastActiveAgo(String duration) {
    return 'Activo hace $duration';
  }

  @override
  String get copyPath => 'Copiar ruta';

  @override
  String get copyRelativePath => 'Copiar ruta relativa';

  @override
  String get nameRequired => 'El nombre es obligatorio';

  @override
  String get import => 'Importar';

  @override
  String get sortByStatus => 'Estado';

  @override
  String get sortByName => 'Nombre';

  @override
  String get noMatchingAgents => 'Ningún agente coincide con tu filtro';

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
  String get activityTargetSpace => 'un espacio';

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
  String get activityTargetReviewSpace => 'un espacio de revisión';

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
  String get activityMarkedSpaceRead => 'Marcó el espacio como leído';

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
  String get activityOpenedReviewSpace => 'Abrió el espacio de revisión';

  @override
  String get activityOpenedStandingConversation =>
      'Abrió la conversación permanente';

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
  String get addAgents => 'Añadir agentes';

  @override
  String get addEmoji => 'Añadir emoji';

  @override
  String get addFeed => 'Añadir fuente';

  @override
  String get addressBarHint => 'Introducir una URL';

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
      other: 'Añadir $count repositorios',
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
  String get allAgentsAlreadyInSpace =>
      'Todos los agentes ya están en este espacio.';

  @override
  String get allCommits => 'Todos los commits';

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
  String get appearanceLanguage => 'Apariencia e idioma';

  @override
  String get apply => 'Aplicar';

  @override
  String get approve => 'Aprobar';

  @override
  String get agentApprovalRequired => 'Aprobación requerida';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count más en espera',
      one: '1 más en espera',
    );
    return '$_temp0';
  }

  @override
  String get approved => 'Aprobado';

  @override
  String get articlesSubscribed => 'Artículos de tus fuentes suscritas.';

  @override
  String get askAi => 'Ask AI';

  @override
  String get askAiReviewDescription => 'Pedir a la IA que revise esta PR';

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
  String get audioOutput => 'Salida de audio';

  @override
  String get authenticationToken => 'Token de autenticación';

  @override
  String authoredByLabel(String role) {
    return 'Por: $role';
  }

  @override
  String get autoRecommended => 'Auto (recomendado)';

  @override
  String get available => 'Disponible';

  @override
  String get awaitingYourReview => 'Esperando tu revisión';

  @override
  String get back => 'Atrás';

  @override
  String get backLabel => 'Atrás';

  @override
  String get backend => 'Backend';

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
  String get cancel => 'Cancelar';

  @override
  String get cancelEdit => 'Cancelar edición';

  @override
  String get categoryCreation => 'Creación';

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
  String get spacesMentionSection => 'Espacios';

  @override
  String get checkForUpdates => 'Buscar actualizaciones';

  @override
  String get checking => 'Comprobando';

  @override
  String get checkingEllipsis => 'Comprobando…';

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
  String get commentOnThisFile => 'Comentar este archivo';

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
  String get copyAddress => 'Copiar dirección';

  @override
  String get copyBaseBranchTooltip => 'Copiar el nombre de la rama de destino';

  @override
  String get copyHeadBranchTooltip => 'Copiar el nombre de la rama de origen';

  @override
  String couldNotListDevices(String error) {
    return 'No se pudieron listar los dispositivos: $error';
  }

  @override
  String get create => 'Crear';

  @override
  String get createOrSelectWorkspace =>
      'Crea o selecciona un espacio de trabajo antes de añadir repositorios.';

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
  String get deleteSpace => 'Eliminar espacio';

  @override
  String deleteConfirmName(String name) {
    return '¿Eliminar \"$name\"?';
  }

  @override
  String get archiveConversation => 'Archivar conversación';

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
  String detectedBackend(String label) {
    return 'Detectado: $label';
  }

  @override
  String get detectedRunners => 'Ejecutores detectados';

  @override
  String get detectingAdapters => 'Detectando adaptadores…';

  @override
  String get detectingInputDevices => 'Detectando dispositivos de entrada…';

  @override
  String detectionFailed(String error) {
    return 'Error de detección: $error';
  }

  @override
  String get disabled => 'Desactivado';

  @override
  String get discover => 'Descubrir';

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
  String get enableNotifications => 'Activar notificaciones';

  @override
  String get enableSandboxing => 'Activar sandboxing';

  @override
  String get enabled => 'Activado';

  @override
  String errorCreatingAgent(String error) {
    return 'Error al crear el agente: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Error al eliminar el agente: $error';
  }

  @override
  String errorWithDetail(String error) {
    return 'Error: $error';
  }

  @override
  String get expand => 'Expandir';

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
  String get feedUrlExample => 'ej: https://example.com/feed.xml';

  @override
  String get feedUrlLabel => 'URL de la fuente';

  @override
  String feedsCount(int count) {
    return 'Fuentes ($count)';
  }

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
  String get forward => 'Reenviar';

  @override
  String get gatesGithubPatPush =>
      'Controla la inyección del PAT de GitHub. Necesario para que el agente pueda hacer push.';

  @override
  String get general => 'General';

  @override
  String get githubLink => 'Enlace de GitHub';

  @override
  String get claudeStatusFetchFailed =>
      'No se pudo contactar con status.claude.com';

  @override
  String get claudeStatusOpenInBrowser => 'Abrir status.claude.com';

  @override
  String get githubStatusFetchFailed =>
      'No se pudo contactar con githubstatus.com';

  @override
  String get githubDegradedTitle => 'GitHub informa de problemas';

  @override
  String githubDegradedStatusLine(String status) {
    return 'Estado de GitHub: $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'Estado de GitHub: $status. Los datos de las pull requests pueden estar desactualizados o incompletos hasta que se recupere.';
  }

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
  String get giveYourWorkAHome => 'Dale un hogar a tu trabajo.';

  @override
  String get goBack => 'Volver';

  @override
  String get goForward => 'Avanzar';

  @override
  String get googleFonts => 'Google Fonts';

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
  String get installRequired => 'Instalación necesaria';

  @override
  String installedVersion(String version) {
    return 'Instalado $version';
  }

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
  String get keybindingAddARepositoryDescription => 'Añadir un repositorio';

  @override
  String get keybindingAddRepository => 'Añadir repositorio';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Marcar o desmarcar el artículo seleccionado';

  @override
  String get keybindingCommandPalette => 'Paleta de comandos';

  @override
  String get keybindingCreateANewAgentDescription => 'Crear un nuevo agente';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Crear un nuevo espacio de trabajo';

  @override
  String get keybindingFocusSearch => 'Enfocar búsqueda';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Enfocar el campo de búsqueda de pull requests';

  @override
  String get keybindingNewAgent => 'Nuevo agente';

  @override
  String get keybindingNewWorkspace => 'Nuevo espacio de trabajo';

  @override
  String get keybindingNextArticle => 'Artículo siguiente';

  @override
  String get keybindingNextSpace => 'Espacio siguiente';

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
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Abrir los ajustes de la aplicación';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Abrir la paleta de comandos';

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
  String get keybindingOpenWorkspace => 'Abrir espacio de trabajo';

  @override
  String get keybindingPreviousArticle => 'Artículo anterior';

  @override
  String get keybindingPreviousSpace => 'Espacio anterior';

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
  String get keybindingRescanForAdaptersDescription => 'Reescanear adaptadores';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Seleccionar el artículo siguiente';

  @override
  String get keybindingSelectTheNextSpaceDescription =>
      'Seleccionar el espacio siguiente';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Seleccionar el artículo anterior';

  @override
  String get keybindingSelectThePreviousSpaceDescription =>
      'Seleccionar el espacio anterior';

  @override
  String get keybindingSendMessage => 'Enviar mensaje';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Enviar el mensaje actual';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Cambiar entre modo claro y oscuro';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Cambiar al octavo espacio de trabajo';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Cambiar al quinto espacio de trabajo';

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
  String get manageWorkspaces => 'Gestionar espacios de trabajo';

  @override
  String get reorderWorkspace => 'Reordenar espacio de trabajo';

  @override
  String get matchOsAppearance =>
      'Adaptar la apariencia al sistema operativo o elegir un modo fijo.';

  @override
  String get mcpAuthToken => 'Token de autenticación MCP';

  @override
  String get mcpNotAvailableOnServer =>
      'El control del servidor MCP no está disponible en el servidor conectado.';

  @override
  String get modelManagedOnServer =>
      'Este modelo se ejecuta en el host del servidor y se gestiona allí.';

  @override
  String get mcpServer => 'Servidor MCP';

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
  String get navConversations => 'Espacios';

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
  String get noActiveWorkspace =>
      'No hay espacio de trabajo o repositorio activo.';

  @override
  String get noActiveWorkspaceCreate => 'No hay espacio de trabajo activo';

  @override
  String get noActiveWorkspaceGithub =>
      'No hay espacio de trabajo activo con un repositorio de GitHub.';

  @override
  String get noAgents => 'Sin agentes';

  @override
  String get noArticlesYet => 'Aún no hay artículos';

  @override
  String get noArticlesYetBody =>
      'Los artículos de tus fuentes aparecerán aquí.';

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
      'Notificar sobre nuevos mensajes de agentes en otros espacios.';

  @override
  String get notifyPrMerged => 'Notificar cuando se fusione una pull request.';

  @override
  String get notifyPrPublished =>
      'Notificar cuando un agente publique una pull request.';

  @override
  String get notifyReviewRequested =>
      'Notificar cuando se solicite tu revisión en una pull request.';

  @override
  String get notificationReviewStale => 'Revisión desactualizada';

  @override
  String get notifyReviewStale =>
      'Cuando llegan nuevos commits a un pull request ya revisado';

  @override
  String get notificationPrMergeReadiness => 'Listo para fusionar';

  @override
  String get notifyPrMergeReadiness =>
      'Avisar cuando una pull request tuya se pueda fusionar, o deje de poder.';

  @override
  String get notificationPrReviewDecision => 'Decisiones de revisión';

  @override
  String get notifyPrReviewDecision =>
      'Avisar cuando alguien apruebe, pida cambios o se descarte una aprobación.';

  @override
  String get notificationPrChecksStatus => 'Comprobaciones';

  @override
  String get notifyPrChecksStatus =>
      'Avisar cuando la CI falle en una pull request tuya, y cuando vuelva a pasar.';

  @override
  String get notificationPrThreadActivity => 'Hilos de revisión';

  @override
  String get notifyPrThreadActivity =>
      'Avisar cuando alguien responda o resuelva un hilo en el que participas.';

  @override
  String get notificationPrReadyToMerge => 'Listo para fusionar';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '$prTitle cumple todos los requisitos.';
  }

  @override
  String get notificationPrMergeBlocked => 'Ya no se puede fusionar';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '$prTitle tiene conflictos con la rama base.';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '$prTitle está por detrás de la rama base.';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '$prTitle espera una revisión obligatoria.';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'Alguien ha pedido cambios en $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return 'Las comprobaciones fallan en $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '$prTitle ya no se puede fusionar.';
  }

  @override
  String get notificationPrApproved => 'Pull request aprobada';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '$login ha aprobado $prTitle';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '$prTitle ha sido aprobada';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'faltan $count revisores por responder',
      one: 'falta 1 revisor por responder',
      zero: 'no queda ningún revisor',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => 'Cambios solicitados';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '$login ha pedido cambios en $prTitle';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return 'Se han pedido cambios en $prTitle';
  }

  @override
  String get notificationPrReviewDismissed => 'Aprobación descartada';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '$prTitle necesita revisión otra vez.';
  }

  @override
  String get notificationPrChecksFailed => 'Comprobaciones fallidas';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '$checkName ha fallado en $prTitle';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return 'Las comprobaciones fallan en $prTitle';
  }

  @override
  String get notificationPrChecksRecovered => 'Comprobaciones en verde';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '$prTitle vuelve a estar en verde.';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '$login te ha mencionado en $location';
  }

  @override
  String get notificationPrThreadReplied => 'Nueva respuesta';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '$login ha respondido en $location';
  }

  @override
  String get notificationPrThreadResolved => 'Hilo resuelto';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return 'Tu hilo en $location se ha resuelto.';
  }

  @override
  String get notificationGroupAgents => 'Agentes';

  @override
  String get notificationGroupPullRequests => 'Pull requests';

  @override
  String get notificationGroupMessages => 'Mensajes';

  @override
  String get notificationGroupTickets => 'Tickets';

  @override
  String get notificationGroupCalendar => 'Calendario';

  @override
  String get notificationGroupMachines => 'Máquinas';

  @override
  String get notificationsMutedRepos => 'Repositorios silenciados';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repositorios silenciados',
      one: '1 repositorio silenciado',
      zero: 'Ningún repositorio silenciado',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'Silenciar este repositorio';

  @override
  String get notificationsUnmuteRepo => 'Reactivar este repositorio';

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
  String get openArticlesInApp => 'Abrir artículos en la app';

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
  String get passed => 'Aprobado';

  @override
  String get pasteValueHere => 'Pegar valor aquí';

  @override
  String get persona => 'Persona';

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
  String get prMergedBody => 'Se ha fusionado una pull request';

  @override
  String get prMoreActions => 'More actions';

  @override
  String get prTitle => 'Título de la PR';

  @override
  String get reviewCommentHint =>
      'Simplemente haz clic en aprobar o, si te apetece, añade un comentario o una reacción…';

  @override
  String get nothingToPreview => 'Nada que previsualizar';

  @override
  String get previousMatch => 'Coincidencia anterior (⇧↵)';

  @override
  String get priorityReviewsDescription =>
      'Revisiones prioritarias y resumen del repositorio.';

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
  String get refresh => 'Actualizar';

  @override
  String get refreshAll => 'Actualizar todo';

  @override
  String get refreshAllFeeds => 'Actualizar todas las fuentes';

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
  String repoAccessNoticeBody(String repos) {
    return 'Las credenciales de GitHub del servidor no pueden ver $repos. Si un repositorio pertenece a una organización, instala allí la GitHub App o conecta un token con acceso.';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repositorios no son accesibles',
      one: 'Un repositorio no es accesible',
    );
    return '$_temp0';
  }

  @override
  String get repoNoAccessBadge => 'Sin acceso';

  @override
  String get reportsTo => 'Reporta a';

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
      other: '$count repositorios',
      one: '1 repositorio',
    );
    return 'No se pudieron añadir $_temp0: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repositorios añadidos',
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
  String get resolved => 'Resuelto';

  @override
  String get enclosedTerminalTitle => 'Terminal aislado';

  @override
  String get enclosedTerminalStart => 'Abrir el shell';

  @override
  String get enclosedTerminalStartHint =>
      'Este shell se ejecuta dentro de la VM desechable de esta conversación. Arranca cuando lo abres, no al iniciar la aplicación.';

  @override
  String get terminalStreamReconnecting => 'flujo interrumpido — reconectando…';

  @override
  String get terminalStreamError => 'error de flujo:';

  @override
  String get terminalShellExited => 'shell finalizado';

  @override
  String get restartShell => 'Reiniciar shell';

  @override
  String get retry => 'Reintentar';

  @override
  String get review => 'Revisar';

  @override
  String get reviewedByMe => 'Revisadas por mí';

  @override
  String get reviewers => 'REVISORES';

  @override
  String get roleLabel => 'Rol';

  @override
  String get ruleHint => 'La regla de la política (markdown soportado)';

  @override
  String get ruleLabel => 'Regla';

  @override
  String get runCompleted => 'Ejecución completada';

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
  String get sandboxBackendMicrovmLabel => 'VM aislada';

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
  String get variableKey => 'Clave';

  @override
  String get variableValue => 'Valor';

  @override
  String get savingChanges => 'Guardando cambios...';

  @override
  String get savingEllipsis => 'Guardando…';

  @override
  String get scopeDiffToCommits =>
      'Filtrar diff por commits — Mayús-clic para rango';

  @override
  String get noPrsMatchSearch => 'No hay pull requests coincidentes';

  @override
  String get noPrsMatchSearchHint =>
      'Ninguna PR abierta coincide con tu búsqueda. Prueba otros términos o borra la búsqueda.';

  @override
  String get searchFactsHint => 'Buscar hechos...';

  @override
  String get searchFonts => 'Buscar fuentes…';

  @override
  String get searchGifs => 'Buscar GIFs';

  @override
  String get searchGifsHint => 'Buscar GIFs...';

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
  String setGithubLinkDescription(String name) {
    return 'Establece el propietario de GitHub y el nombre del repositorio para $name. Esto se usa para resolver referencias de PR e issues como #123 en contenido markdown.';
  }

  @override
  String get setLabel => 'Establecer';

  @override
  String get setToken => 'Establecer token';

  @override
  String get settingsLabel => 'Ajustes';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageDescription =>
      'Elegir el idioma de la aplicación.';

  @override
  String get shortTask => 'Tarea corta';

  @override
  String get showNativeNotifications =>
      'Mostrar notificaciones nativas de macOS para eventos.';

  @override
  String get showSuperseded => 'Mostrar sustituidos';

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
  String get skillsSourcesTab => 'Fuentes';

  @override
  String get skillSourcesDisclaimer =>
      'Las skills se instalan desde repositorios de GitHub que añadas. los metadatos del repositorio no son de confianza: el análisis antivirus es la señal de seguridad real.';

  @override
  String get skillSourcesEmpty => 'Sin repositorios de skills';

  @override
  String get skillSourcesEmptyHint =>
      'Añade un repositorio de GitHub para explorar sus skills.';

  @override
  String get skillSourceAdd => 'Añadir repositorio';

  @override
  String get skillSourceAddTitle => 'Añadir repositorio de skills';

  @override
  String get skillSourceAddHint => 'https://github.com/propietario/repositorio';

  @override
  String get skillSourceInvalidUrl =>
      'Introduce una URL de repositorio de GitHub (https://github.com/propietario/repositorio).';

  @override
  String skillSourceAdded(String repo) {
    return 'Repositorio $repo añadido.';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'El repositorio $repo ya está añadido.';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'Repositorio $repo eliminado.';
  }

  @override
  String get skillSourceRemove => 'Eliminar';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return '¿Eliminar $repo?';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'Las skills instaladas permanecen instaladas. Solo se elimina el catálogo del repositorio.';

  @override
  String get skillSourceNoSkills =>
      'No se encontraron skills en este repositorio (una skill es un directorio que contiene un SKILL.md).';

  @override
  String get skillSourceRefresh => 'Actualizar';

  @override
  String get skillSourceInstalledBadge => 'Instalada';

  @override
  String get skillSourceUpdateBadge => 'Actualización disponible';

  @override
  String get skillSourceSlugTaken => 'Nombre en uso';

  @override
  String skillSourceFilesCount(num count) {
    return '$count archivos';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'Esta skill no tiene README.';

  @override
  String get skillSourceNoMatches => 'Ninguna skill coincide con tu filtro.';

  @override
  String get skillUpdateAction => 'Actualizar';

  @override
  String get skillUninstallAction => 'Desinstalar';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return '¿Desinstalar \"$slug\"?';
  }

  @override
  String skillUninstalled(String slug) {
    return 'Skill \"$slug\" desinstalada.';
  }

  @override
  String get skillFindingLine => 'línea';

  @override
  String get skillInstallAnywayOverride =>
      'Entiendo el riesgo — instalar de todos modos';

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
  String skillDetachedFromAgents(String agents) {
    return 'En cuarentena y desvinculado de los agentes: $agents';
  }

  @override
  String get skillNotScanned => 'Sin analizar';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'Manual';

  @override
  String get skillOriginRegistry => 'Registro';

  @override
  String get skillOriginRuntimeLocal => 'Runtime local';

  @override
  String get skillRulesStale => 'Análisis obsoleto';

  @override
  String get skillSaveAnywayOverride =>
      'Entiendo el riesgo — guardar de todos modos';

  @override
  String get skillSaveBlockedBody =>
      'El contenido se bloqueó antes de escribir nada.';

  @override
  String get skillSaveBlockedTitle => 'Guardado bloqueado por el análisis';

  @override
  String get skillScanAction => 'Analizar';

  @override
  String get skillScanAll => 'Analizar todo';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass aprobados · $warn advertencias · $quarantine en cuarentena';
  }

  @override
  String get skillStateDrifted => 'Modificado tras la instalación';

  @override
  String get skillStateUnmanaged => 'Sin gestionar';

  @override
  String get skillSeverityBlocked => 'Bloqueado';

  @override
  String get skillSeverityWarn => 'Advertencia';

  @override
  String get skillsInstalledTab => 'Instaladas';

  @override
  String get skills => 'Habilidades';

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
  String get startLabel => 'Iniciar';

  @override
  String get startOnAppLaunch => 'Iniciar al abrir la app';

  @override
  String get statusLabel => 'Estado';

  @override
  String get onboardingStepConnect => 'Conectar';

  @override
  String get onboardingStepWorkspace => 'Espacio de trabajo';

  @override
  String get onboardingStepSandbox => 'Entorno aislado';

  @override
  String get onboardingStepAdapter => 'Adaptador';

  @override
  String get onboardingStepVoice => 'Voz';

  @override
  String get stop => 'Detener';

  @override
  String get stopped => 'Detenido';

  @override
  String get strictIdentityCheck => 'Verificación estricta de identidad';

  @override
  String get success => 'Éxito';

  @override
  String get successLabel => 'Éxito';

  @override
  String get suggestAChange => 'Sugerir un cambio';

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
  String get ticketLabel => 'TICKET';

  @override
  String get titleLabel => 'Título';

  @override
  String get todayLabel => 'Hoy';

  @override
  String get toggleTheme => 'Cambiar tema';

  @override
  String get tokenConfigured =>
      'Configurado — los clientes deben presentar este token.';

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
  String get viewLabel => 'Vista';

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
  String get meetingSummaryPrivacyNotice =>
      'La grabación y la transcripción permanecen en este equipo. El resumen lo escribe un agente, así que si usa un modelo en la nube, tu transcripción y tus notas se envían a ese proveedor.';

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
  String get workspaceScopedSkills =>
      'Archivos de habilidades del espacio de trabajo adjuntos a los agentes.';

  @override
  String get workspaces => 'Espacios de trabajo';

  @override
  String get writePrivateNotes =>
      'Escribe notas privadas, observaciones, planes...';

  @override
  String get writeSkillContent =>
      'Escribe el contenido de la habilidad aquí (Markdown)…';

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
  String get stackedPullRequests => 'Pull requests apiladas';

  @override
  String partOfStack(int position, int total) {
    return 'Parte de una pila ($position de $total)';
  }

  @override
  String get createStack => 'Crear pila';

  @override
  String get createStackDialogTitle => 'Crear una pila de pull requests';

  @override
  String createStackDialogBody(int count) {
    return 'Estas $count pull requests se apilarán, de abajo hacia arriba:';
  }

  @override
  String get createStackInvalidSelection =>
      'Selecciona al menos dos pull requests del mismo repositorio para crear una pila';

  @override
  String get createStackNotAChain =>
      'Las pull requests seleccionadas no forman una cadena: la rama base de cada una debe ser la rama head de la anterior';

  @override
  String get createStackAlreadyStacked =>
      'Una o más pull requests seleccionadas ya están en una pila';

  @override
  String get stackCreated => 'Pila creada';

  @override
  String get stackCreationFailed => 'No se pudo crear la pila';

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
  String get markReadyForReview => 'Lista para revisión';

  @override
  String get markReadyForReviewConfirm =>
      'Esta pull request dejará de ser un borrador. Se notifica a los revisores, las comprobaciones obligatorias pasan a condicionar la fusión y se ejecuta cualquier automatización que vigile las pull requests listas.';

  @override
  String get convertToDraft => 'Convertir en borrador';

  @override
  String get convertToDraftConfirm =>
      'Esta pull request volverá a ser un borrador. Sus solicitudes de revisión pendientes se descartarán y no podrá fusionarse hasta que la marques como lista de nuevo.';

  @override
  String get pullRequestMarkedReady =>
      'Pull request marcada como lista para revisión';

  @override
  String get pullRequestConvertedToDraft =>
      'Pull request convertida en borrador';

  @override
  String failedToMarkPrReady(String error) {
    return 'Error al marcar como lista para revisión: $error';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'Error al convertir en borrador: $error';
  }

  @override
  String get checksFailing => 'Comprobaciones fallidas';

  @override
  String get reviewsPending => 'Some reviews are pending';

  @override
  String get mergeConflictsWithBase =>
      'Esta rama tiene conflictos que deben resolverse';

  @override
  String get branchOutOfDateWithBase =>
      'Esta rama está desactualizada respecto a la rama base';

  @override
  String get mergeBlockedByBranchProtection =>
      'La protección de rama bloquea esta fusión';

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
  String get pipelineRunSettingsConcurrencyTitle => 'Concurrencia';

  @override
  String get pipelineRunSettingsMaxParallel => 'Ejecuciones paralelas máx.';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'Déjalo vacío para ilimitado. Las ejecuciones adicionales esperan en una cola y arrancan cuando se libera un hueco.';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'Ilimitado';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      'Introduce un número entero de 1 o más, o déjalo vacío para ilimitado.';

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
      'Clave de estado bajo la que se guarda el valor (p. ej. repo_full_name).';

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
  String get pipelineStatusQueued => 'En cola';

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
  String pipelineRunFailedAtStep(String step) {
    return 'Falló en $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Manual';

  @override
  String get pipelineStepSkippedReason => 'Omitido';

  @override
  String get pipelineStepPriorAttempts => 'Intentos anteriores';

  @override
  String get pipelineStepAttemptLabel => 'Intento';

  @override
  String pipelineStepAttemptN(int number) {
    return 'Intento $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'Interrumpido';

  @override
  String get pipelineRunColumnPipeline => 'Pipeline';

  @override
  String get pipelineRunColumnDuration => 'Duración';

  @override
  String get pipelineRunQueueNext => 'Siguiente';

  @override
  String pipelineRunQueuePosition(int position) {
    return '$position.º en cola';
  }

  @override
  String get pipelineRunColumnStarted => 'Iniciado';

  @override
  String get pipelineRunHistory => 'Historial de ejecuciones';

  @override
  String get pipelineRunHistoryEmpty => 'Aún no hay otras ejecuciones';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'Reejecutado $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return 'Intento $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'primer inicio $time';
  }

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
  String get teamsTitle => 'Teams';

  @override
  String get teamsAddTeam => 'Add team';

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
  String get nodeConfigRepos => 'Repositorios a clonar';

  @override
  String get nodeConfigReposHelp =>
      'Repositorios clonados e indexados cuando este nodo inicia su conversación. Seleccionar todos clona todos ellos (comportamiento predeterminado).';

  @override
  String get nodeConfigRepoBranchHint => 'Rama (predeterminada)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'La rama desde la que se crea cada copia. Déjalo vacío para la rama predeterminada del repositorio — la copia de trabajo recibe su propia rama, así que nada de lo que confirme un agente acaba en esta.';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'Entradas dinámicas conservadas: $entries';
  }

  @override
  String get nodeConfigCreateConversation => 'Abrir una conversación en ella';

  @override
  String get nodeConfigCreateConversationHelp =>
      'Déjalo desactivado cuando siguen varios nodos de agente: cada uno abre su propio hilo con nombre. Actívalo cuando sigue un solo nodo de agente, para que la sala nunca muestre una conversación sin título junto a él.';

  @override
  String get nodeConfigConversationTitle => 'Nombre de la conversación';

  @override
  String get nodeConfigConversationTitleHelp =>
      'Dale el mismo nombre al nodo de agente posterior y ambos trabajarán en un solo hilo. Por defecto, la etiqueta del nodo.';

  @override
  String get nodeConfigSpaceName => 'Nombre del espacio';

  @override
  String get nodeConfigSpaceNameHelp =>
      'Cómo se llama la sala que abre este nodo. Admite los mismos marcadores de estado que un prompt. Déjalo vacío para usar la etiqueta del nodo.';

  @override
  String get nodeConfigSpaceNameHint => 'Revisión de pr_number';

  @override
  String get nodeConfigStreamTitle => 'Nombre de la conversación';

  @override
  String get nodeConfigStreamTitleHelp =>
      'El hilo con nombre en el que trabaja el agente de este nodo dentro de la sala. Admite los mismos marcadores de estado que un prompt. Si lo dejas vacío, el turno cae en la conversación permanente de la sala, donde un abanico de agentes se entremezcla.';

  @override
  String get nodeConfigConversationTitleHint => 'Análisis de arquitectura';

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
      'Clave de estado con el directorio donde se resuelven las rutas (por defecto repo_local_path).';

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
  String get triggerEventCodeGraphWatch => 'Cambio de archivo';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos modificados',
      one: '1 archivo modificado',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '+$count más';
  }

  @override
  String get pipelineRunCauseRescan => 'Modificado en el disco';

  @override
  String get pipelineRunCauseInitial => 'Primera indexación de esta copia';

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
      'Conecta un alojamiento de código para que Control Center pueda leer tus pull requests, incidencias y revisiones. Conecta opcionalmente un proveedor de tickets. Las credenciales las guarda tu servidor, nunca esta máquina.';

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
  String get addCollaborator => 'Añadir colaborador';

  @override
  String get noCollaborators => 'Aún no hay colaboradores';

  @override
  String get linkedPullRequests => 'Pull requests vinculadas';

  @override
  String get noLinkedPullRequests => 'Aún no hay pull requests vinculadas';

  @override
  String get stopAgent => 'Detener agente';

  @override
  String get ticketProperties => 'Propiedades';

  @override
  String get ticketTabIssue => 'Ticket';

  @override
  String get ticketSelectPrompt => 'Selecciona un ticket para ver sus detalles';

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
  String notificationsUnreadCount(int count) {
    return '$count sin leer';
  }

  @override
  String get notificationsMarkRead => 'Marcar como leída';

  @override
  String get notificationsMarkUnread => 'Marcar como no leída';

  @override
  String get notificationsEntryActions => 'Acciones de notificación';

  @override
  String get markAllRead => 'Marcar todo como leído';

  @override
  String get teamsNav => 'Equipos';

  @override
  String get noWorkspace => 'Sin espacio de trabajo';

  @override
  String get selectWorkspace => 'Seleccionar un espacio de trabajo';

  @override
  String get navMemory => 'Memoria';

  @override
  String get memoryTabFacts => 'Hechos';

  @override
  String get memoryTabPolicies => 'Políticas';

  @override
  String get memoryGraphShowFacts => 'Mostrar hechos';

  @override
  String get memoryGraphHideFacts => 'Ocultar hechos';

  @override
  String get memoryGraphExpandAll => 'Mostrar todos los hechos';

  @override
  String get memoryGraphCollapseAll => 'Ocultar todos los hechos';

  @override
  String get memoryTabGraph => 'Grafo de conocimiento';

  @override
  String get memoryNoWorkspace =>
      'Selecciona un espacio de trabajo para ver su memoria.';

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
  String get connectGitHubHint =>
      'Inicia sesión en GitHub o añade un token en Ajustes → Tú → Perfil e identidad → Alojamiento de código';

  @override
  String get connectGitHubToLoadPrs =>
      'Conecta GitHub para cargar las pull requests';

  @override
  String get noRepositoriesConfigured => 'No hay repositorios configurados';

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
  String get checks => 'Comprobaciones';

  @override
  String get noReviewersAssigned => 'Sin revisores asignados';

  @override
  String get noAssignees => 'Sin asignados';

  @override
  String get loadingEllipsis => 'Cargando…';

  @override
  String get loadingChecks => 'Cargando comprobaciones…';

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
  String get searchTicketsHint => 'Buscar tickets…';

  @override
  String get noMatchingTickets => 'Ningún ticket coincide';

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
  String get userStatusBusy => 'Ocupado';

  @override
  String get teamsSectionLabel => 'Equipos';

  @override
  String get suggestedReviewers => 'Revisores sugeridos';

  @override
  String get noMatchingUsers => 'No hay personas coincidentes';

  @override
  String get noMatchingReviewers => 'Sin coincidencias';

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
  String get markdownSupported => 'Markdown es compatible';

  @override
  String get markdownAttachImages => 'Haz clic para añadir imágenes';

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
  String get meetingNotesHint =>
      'Anota notas rápidas: el agente las ampliará tras la reunión.';

  @override
  String get meetingSpeakerMe => 'Tú';

  @override
  String get meetingStatusRecording => 'Grabando';

  @override
  String get meetingStatusProcessing => 'Procesando';

  @override
  String get meetingStatusDone => 'Listo';

  @override
  String get meetingStatusFailed => 'Error';

  @override
  String get meetingsSubtitle =>
      'Capturado y transcrito en este dispositivo, y luego resumido por un agente.';

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
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reuniones',
      one: '1 reunión',
      zero: 'Ninguna reunión',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'Tareas abiertas';

  @override
  String get meetingsLedgerDecisions => 'Decisiones';

  @override
  String get meetingsLiveOpen => 'Abrir la grabación';

  @override
  String get meetingTemplateShort => 'Plantilla';

  @override
  String get meetingsStatThisWeek => 'Esta semana';

  @override
  String get meetingsStatRecorded => 'Grabado';

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
  String get silenceTimeoutLabel => 'Tiempo de silencio (minutos)';

  @override
  String get silenceTimeoutHint =>
      'p. ej. 15 — termina un run tras este tiempo sin salida';

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
  String get transcriptErrorLabel => 'Error';

  @override
  String get transcriptSandboxBlocked =>
      'El espacio aislado bloqueó una acción';

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
  String get connectedLabel => 'Conectado';

  @override
  String get ideTabGeneral => 'General';

  @override
  String get ideTabExplorer => 'Explorador';

  @override
  String get ideTabSourceControl => 'Control de código';

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
  String get generalSectionBrowsers => 'Navegadores';

  @override
  String get generalSectionComputers => 'Ordenadores';

  @override
  String get generalBrowsersEmpty => 'Ningún navegador abierto';

  @override
  String get generalComputersEmpty => 'Ningún ordenador abierto';

  @override
  String get generalSectionPhones => 'Teléfonos';

  @override
  String get generalPhonesEmpty => 'No hay teléfonos abiertos';

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
  String get focusTerminal => 'Enfocar terminal';

  @override
  String get focusMachine => 'Enfocar máquina';

  @override
  String get focusBrowser => 'Enfocar navegador';

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
  String get terminal => 'Terminal';

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
  String get ideNewTabMenu => 'Nueva pestaña';

  @override
  String get ideReviewCode => 'Revisar código';

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
  String get ideFolderLoadFailed => 'No se pudo cargar esta carpeta';

  @override
  String get ideFileSearchFailed => 'No se pudieron buscar archivos';

  @override
  String get ideSearchInFiles => 'Buscar en archivos';

  @override
  String get ideNoContentMatches => 'Sin coincidencias';

  @override
  String get ideSourceControlCreatePr => 'Crear petición de extracción';

  @override
  String ideSourceControlViewPr(int number) {
    return 'Ver la pull request #$number';
  }

  @override
  String get ideSourceControlNoChanges => 'Sin cambios';

  @override
  String get noReposInConversation => 'Ningún repositorio en esta conversación';

  @override
  String get ideSourceControlNoSpace =>
      'Abre una conversación para ver sus cambios';

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
  String costPerMillion(String input, String output) {
    return '$input / $output por 1M';
  }

  @override
  String contextTokens(String tokens) {
    return 'contexto $tokens';
  }

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
  String get subscriptionUsageExhausted => 'Cuota agotada';

  @override
  String get subscriptionUsageSignInRequired => 'Vuelve a iniciar sesión';

  @override
  String get subscriptionUsageSignInExpired =>
      'La sesión expiró, se renueva en la próxima ejecución';

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
  String get spaces => 'Espacios';

  @override
  String get spacesHomeDescription =>
      'Elige un espacio de la lista o inicia uno nuevo.';

  @override
  String get noSpacesYet => 'Aún no hay espacios';

  @override
  String get newSpace => 'Nuevo espacio';

  @override
  String get spaceName => 'Nombre del espacio';

  @override
  String get spaceReposHint => 'Repos a incluir';

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
  String get spaceLabel => 'Espacio';

  @override
  String get keybindingNewSpace => 'Nuevo espacio';

  @override
  String get keybindingCreateANewSpaceDescription => 'Crear un nuevo espacio';

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
  String get providerApiKeyStoredHint => 'Pega otra clave de API para añadirla';

  @override
  String get providerAddAnotherAccount => 'Añadir otra cuenta';

  @override
  String get providerActiveBadge => 'Activa';

  @override
  String get providerOauthAccountFallback => 'Cuenta de OAuth';

  @override
  String get providerApiKeyFallback => 'Clave de API';

  @override
  String get providerRemoveCredentialConfirmTitle =>
      '¿Eliminar esta credencial?';

  @override
  String get providerSignOutAccountConfirmTitle =>
      '¿Cerrar sesión de esta cuenta?';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'Los agentes que usan $provider recurren a sus otras claves y cuentas. Si no queda ninguna, se detienen hasta que añadas una.';
  }

  @override
  String get providerBaseUrlHint => 'URL base (opcional)';

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
  String provisioningRunningSetupScript(String repo) {
    return 'Ejecutando el script de configuración de $repo…';
  }

  @override
  String get repoScriptsTitle => 'Scripts';

  @override
  String get repoScriptsTooltip => 'Configurar scripts del ciclo de vida';

  @override
  String get repoScriptsSetupLabel => 'Script de configuración';

  @override
  String get repoScriptsSetupHelp =>
      'Se ejecuta en el worktree del espacio justo después de crearse: instalar dependencias, generar archivos. Un fallo marca el espacio como fallido; reintentar lo ejecuta de nuevo.';

  @override
  String get repoScriptsArchiveLabel => 'Script de archivado';

  @override
  String get repoScriptsArchiveHelp =>
      'Se ejecuta justo antes de eliminar el worktree de un espacio: limpia recursos fuera del worktree. Un fallo nunca bloquea la eliminación.';

  @override
  String get repoScriptsEnvHelp =>
      'Se ejecuta con bash desde el worktree, con CC_WORKSPACE_PATH (el worktree), CC_ROOT_PATH (la raíz del repositorio), CC_SPACE_ID, CC_SPACE_NAME y CC_REPO_NAME definidos.';

  @override
  String get repoScriptsSetupPlaceholder => 'p. ej. pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      'p. ej. docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => 'Ejecuciones recientes';

  @override
  String get repoScriptsNoRuns => 'Aún no hay ejecuciones';

  @override
  String get repoScriptsOutput => 'Salida';

  @override
  String get repoScriptsSaved => 'Scripts guardados';

  @override
  String get repoScriptsRunKindSetup => 'Configuración';

  @override
  String get repoScriptsRunKindArchive => 'Archivado';

  @override
  String get repoScriptsRunStatusRunning => 'En curso';

  @override
  String get repoScriptsRunStatusSucceeded => 'Completado';

  @override
  String get repoScriptsRunStatusFailed => 'Fallido';

  @override
  String get repoScriptsRunStatusTimedOut => 'Caducado';

  @override
  String repoScriptsExitCode(int code) {
    return 'Código de salida $code';
  }

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
  String get workspacePrepStopped => 'Preparación detenida';

  @override
  String get stopWorkspacePrep => 'Detener la preparación';

  @override
  String get stopWorkspacePrepTooltip =>
      'Detener la preparación de este espacio de trabajo';

  @override
  String get stopWorkspacePrepConfirm =>
      '¿Detener la preparación de este espacio de trabajo? Se descarta la clonación en curso; puedes volver a iniciarla desde aquí.';

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
  String get memberRepoAccessAction => 'Acceso a repositorios';

  @override
  String memberRepoAccessTitle(String name) {
    return 'Acceso a repositorios de $name';
  }

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
  String get transferOwnershipAction => 'Transferir la propiedad';

  @override
  String get transferOwnershipTitle => 'Transferir la propiedad';

  @override
  String transferOwnershipConfirm(String name) {
    return '¿Hacer a $name propietario de este espacio de trabajo? Pasas a ser administrador. Solo un propietario puede eliminar el espacio de trabajo o cambiar el rol de otro administrador.';
  }

  @override
  String get transferOwnershipCta => 'Transferir';

  @override
  String get auditTrailLabel => 'Registro de auditoría de autorizaciones';

  @override
  String get auditTrailDescription =>
      'Cada permiso y cada rechazo, encadenados por hash: una entrada modificada o eliminada es detectable.';

  @override
  String get auditVerifyChain => 'Verificar la cadena';

  @override
  String auditChainIntact(int count) {
    return 'Cadena intacta: $count entradas verificadas';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'Cadena rota en la entrada $seq: $reason';
  }

  @override
  String get auditEmpty => 'Aún no hay decisiones registradas.';

  @override
  String get auditDenied => 'Denegado';

  @override
  String get auditAllowed => 'Permitido';

  @override
  String auditOnBehalfOf(String user) {
    return 'para $user';
  }

  @override
  String get policyTemplatesLabel => 'Plantillas de política';

  @override
  String get policyTemplatesDescription =>
      'Aplica una postura inicial o trasládala entre espacios de trabajo.';

  @override
  String get policyTemplateStrict => 'Estricta';

  @override
  String get policyTemplateBalanced => 'Equilibrada';

  @override
  String get policyTemplatePermissive => 'Permisiva';

  @override
  String get policyTemplateApply => 'Aplicar';

  @override
  String policyTemplateApplied(int count) {
    return '$count reglas aplicadas';
  }

  @override
  String get policyExport => 'Copiar la política';

  @override
  String get policyExported => 'Política copiada al portapapeles';

  @override
  String get policyImport => 'Pegar la política';

  @override
  String policyImported(int count) {
    return '$count reglas importadas';
  }

  @override
  String get approveAndRemember => 'Aprobar durante 8 horas';

  @override
  String get approveAndRememberTooltip =>
      'Aprueba esta acción y deja de preguntar por otras similares en este espacio durante 8 horas. Caduca por sí sola.';

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
  String get inboxGitHubDownTitle => 'GitHub podría estar caído';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub informa: $status. Puede que falten pull requests en esta lista en lugar de estar realmente terminadas.';
  }

  @override
  String get inboxGitHubIdentityTitle =>
      'No se pudo confirmar tu cuenta de GitHub';

  @override
  String get inboxGitHubIdentityBody =>
      'La bandeja se ordena según quién eres en GitHub. Hasta que eso se cargue, la lista sigue vacía aunque tengas pull requests esperando.';

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
  String get openInEditor => 'Abrir en el editor';

  @override
  String get commitMessageHint => 'Mensaje de confirmación';

  @override
  String get pushedToPr => 'Subido a la PR';

  @override
  String get pushFailed => 'Error al subir';

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
  String get addModel => 'Añadir modelo';

  @override
  String get modelListTitle => 'Lista de modelos';

  @override
  String get railProvidersGroup => 'Proveedores';

  @override
  String get railCustomProvidersGroup => 'Proveedores personalizados';

  @override
  String get editModelSettings => 'Editar modelo';

  @override
  String get modelIdLabel => 'ID del modelo';

  @override
  String get modelIdImmutableHint =>
      'El identificador que sirve el endpoint; fijo una vez listado.';

  @override
  String get contextWindowLabel => 'Ventana de contexto';

  @override
  String get inputTypesLabel => 'Tipos de entrada';

  @override
  String get outputTypesLabel => 'Tipos de salida';

  @override
  String get modalityText => 'Texto';

  @override
  String get modalityImage => 'Imagen';

  @override
  String get modalityAudio => 'Audio';

  @override
  String get modalityVideo => 'Vídeo';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'Restablecer automático';

  @override
  String get modelOverrideEdited => 'Editado';

  @override
  String get manualModelBadge => 'Añadido a mano';

  @override
  String get modelIdRequired => 'Introduce un identificador de modelo.';

  @override
  String get modelTokensInvalid =>
      'Introduce un número entero positivo de tokens.';

  @override
  String get removeModelAction => 'Eliminar modelo';

  @override
  String removeModelConfirmTitle(String model) {
    return '¿Eliminar $model?';
  }

  @override
  String get removeModelConfirmBody =>
      'El modelo sale de la lista y los agentes fijados a él dejan de funcionar. El proveedor no se ve afectado.';

  @override
  String get addModelProviderTitle => 'Añadir proveedor de modelos';

  @override
  String get addModelProviderDescription =>
      'Configura un endpoint de API personalizado y sus modelos.';

  @override
  String get modelListEmptyHint =>
      'No hay modelos configurados. Añade un modelo para usarlo en el chat.';

  @override
  String get addProviderModelsHint =>
      'Los modelos se obtienen en directo cuando el endpoint responde. Añade uno a mano solo si no puede listar los suyos.';

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
  String get spaceFlyoutNeedsInput => 'Necesita tu respuesta';

  @override
  String get spaceFlyoutPreparing => 'Preparando';

  @override
  String get spaceFlyoutSetupFailed => 'Error de configuración';

  @override
  String get spaceFlyoutSetupStopped => 'Configuración detenida';

  @override
  String get spaceFlyoutNeverRun => 'Ningún agente ha trabajado aquí todavía';

  @override
  String spaceFlyoutContextUsage(String used, String percent) {
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
  String get composePrSubtitleFromSpace =>
      'Desde la rama de esta conversación: publícala primero si GitHub no la conoce';

  @override
  String get obsTabInsights => 'Resumen';

  @override
  String get obsTabLive => 'En vivo';

  @override
  String get obsTabQuality => 'Calidad';

  @override
  String get obsTabUsage => 'Uso';

  @override
  String get obsUsageTotalTokens => 'Tokens totales';

  @override
  String get obsUsagePeakTokens => 'Pico de tokens';

  @override
  String get obsUsageLongestSession => 'Sesión más larga';

  @override
  String get obsUsageCurrentStreak => 'Racha actual';

  @override
  String get obsUsageLongestStreak => 'Racha más larga';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
      zero: '0 días',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'Actividad de tokens';

  @override
  String get obsUsageActivityModeLabel => 'Modo de actividad de tokens';

  @override
  String get obsUsageModeDaily => 'Diario';

  @override
  String get obsUsageModeWeekly => 'Semanal';

  @override
  String get obsUsageModeCumulative => 'Acumulado';

  @override
  String get obsUsageTimeRange => 'Rango de tiempo';

  @override
  String get obsUsageTrendTitle => 'Tendencia diaria de tokens';

  @override
  String get obsUsageModelUsage => 'Uso por modelo';

  @override
  String get obsUsageTokensLabel => 'tokens';

  @override
  String get obsUsageNoActivity => 'Aún no se ha registrado uso de tokens';

  @override
  String get obsUsageOtherModels => 'Otros';

  @override
  String obsUsageCellReadout(String date, String tokens) {
    return '$date · $tokens tokens';
  }

  @override
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  ) {
    return 'Actividad de tokens del $start al $end. $activeDays días activos. Día más intenso: $peak tokens.';
  }

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
      'El servidor al que se conecta este cliente y cómo se comparte este servidor (mDNS, túneles, relé).';

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
  String get settingsReviewLevelLabel => 'Nivel de revisión';

  @override
  String get settingsReviewLevelHelp =>
      'Hasta dónde llega la revisión con IA y cuánto de lo que encuentra se destaca. No se descarta nada: un nivel más ligero agrupa los hallazgos menores en lugar de omitirlos.';

  @override
  String get reviewLevelLight => 'Ligera';

  @override
  String get reviewLevelBalanced => 'Equilibrada';

  @override
  String get reviewLevelThorough => 'Exhaustiva';

  @override
  String get reviewLevelLightHint =>
      'Un revisor. Solo se destaca lo que realmente importa.';

  @override
  String get reviewLevelBalancedHint =>
      'Tres revisores: calidad, arquitectura e implementación.';

  @override
  String get reviewLevelThoroughHint =>
      'Añade especialistas en seguridad y rendimiento, e informa de todo lo que encuentra.';

  @override
  String get askAiReviewAtLevel => 'Revisar con otro nivel';

  @override
  String reviewNitpicksGroup(int count) {
    return 'Detalles menores ($count)';
  }

  @override
  String get reviewFindingResolve => 'Corregido';

  @override
  String get reviewFindingResolveHint =>
      'Marcar este hallazgo como corregido. Deja de contar en la revisión.';

  @override
  String get reviewFindingDismiss => 'Descartar';

  @override
  String get reviewFindingDismissHint =>
      'No es un problema real. Los revisores dejarán de señalar este patrón.';

  @override
  String get reviewFindingReopen => 'Reabrir';

  @override
  String get reviewFindingStatusUndoLabel => 'Estado del hallazgo';

  @override
  String get reviewFindingDismissTitle => 'Descartar este hallazgo';

  @override
  String get reviewFindingDismissReasonHint =>
      '¿Por qué no aplica? Los revisores lo leerán.';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'No se pudo actualizar el hallazgo: $error';
  }

  @override
  String get reviewStaleTitle => 'Esta revisión está desactualizada';

  @override
  String get reviewStaleBody =>
      'El pull request ha cambiado desde esta revisión. Los hallazgos pueden apuntar a código que ya no existe.';

  @override
  String reviewStaleReviewedAt(String sha) {
    return 'Revisado en $sha';
  }

  @override
  String get reviewStaleRerun => 'Revisar de nuevo';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return 'Revisión desactualizada en #$prNumber';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return '$title tiene nuevos commits desde su última revisión.';
  }

  @override
  String get reviewCategorySecurity => 'Seguridad';

  @override
  String get reviewCategoryStability => 'Estabilidad';

  @override
  String get reviewCategoryDataIntegrity => 'Integridad de datos';

  @override
  String get reviewCategoryCorrectness => 'Corrección';

  @override
  String get reviewCategoryPerformance => 'Rendimiento';

  @override
  String get reviewCategoryMaintainability => 'Mantenibilidad';

  @override
  String get reviewEffortQuickWin => 'Mejora rápida';

  @override
  String get reviewEffortModerate => 'Moderado';

  @override
  String get reviewEffortHeavyLift => 'Trabajo mayor';

  @override
  String get reviewProposedFix => 'Corrección propuesta';

  @override
  String get reviewAiAgentPrompt => 'Instrucción para agentes de IA';

  @override
  String get reviewCopyAiPrompt => 'Copiar instrucción';

  @override
  String get settingsWorkspaceAdminOnly =>
      'Solo los administradores del espacio de trabajo pueden cambiarlo.';

  @override
  String get chatMyAccountsTitle => 'Cuentas de chat vinculadas';

  @override
  String get settingsServerSso => 'Inicio de sesión único';

  @override
  String get settingsServerSsoDescription =>
      'Inicio de sesión SAML y OpenID Connect con aprovisionamiento de usuarios';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription =>
      'Los usuarios pueden iniciar sesión con este proveedor';

  @override
  String get ssoEnabledDescriptionOn =>
      'El inicio de sesión está activo para este proveedor';

  @override
  String get ssoIdpMetadataLabel => 'XML de metadatos del IdP';

  @override
  String get ssoIdpMetadataHint => 'pega el XML EntityDescriptor del IdP';

  @override
  String get ssoEmailAttributeLabel => 'Atributo de correo electrónico';

  @override
  String get ssoDisplayNameAttributeLabel => 'Atributo de nombre para mostrar';

  @override
  String get ssoGroupsAttributeLabel => 'Atributo de grupos';

  @override
  String get ssoIssuerLabel => 'URL del emisor';

  @override
  String get ssoClientIdLabel => 'ID de cliente';

  @override
  String get ssoGroupsClaimLabel => 'Claim de grupos';

  @override
  String get ssoAutoMemberLabel =>
      'Añadir usuarios a cada espacio en el primer inicio de sesión';

  @override
  String get ssoAutoMemberDescription =>
      'Desactívalo para requerir una invitación por espacio';

  @override
  String get ssoAllowJitLabel =>
      'Aprovisionar usuarios desconocidos en el primer inicio de sesión';

  @override
  String get ssoAllowJitDescription =>
      'Desactívalo para rechazar usuarios sin cuenta existente';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'Aceptar inicio de sesión iniciado por el IdP';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'Solo para portales IdP que lanzan aplicaciones directamente';

  @override
  String get ssoWantResponseSignedLabel => 'Exigir sobre de respuesta firmado';

  @override
  String get ssoWantResponseSignedDescription =>
      'Las firmas de aserción siempre son obligatorias';

  @override
  String get ssoTestConnectionButton => 'Probar conexión';

  @override
  String get ssoTestConnectionOk => 'La conexión funciona:';

  @override
  String get ssoCopySpMetadata => 'Copiar metadatos SP';

  @override
  String get ssoCopySpMetadataDone => 'Metadatos SP copiados al portapapeles';

  @override
  String get ssoSavedToast => 'Ajustes de inicio de sesión único guardados';

  @override
  String get ssoUnavailable =>
      'Este servidor no expone ajustes de inicio de sesión único. Actualiza el binario del servidor e inténtalo de nuevo.';

  @override
  String get ssoScimCardTitle => 'Aprovisionamiento de usuarios (SCIM)';

  @override
  String get ssoScimDescription =>
      'Apunta el conector SCIM de tu proveedor de identidad al endpoint de abajo con un token bearer. La desprovisión revoca sesiones y accesos a espacios en segundos. El servidor debe ser accesible por el IdP (túnel o URL pública).';

  @override
  String get ssoScimEndpoint => 'Endpoint SCIM';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'Configura primero la URL pública del servidor o activa un túnel';

  @override
  String get ssoScimRegenerate => 'Regenerar token';

  @override
  String get ssoScimRegenerateConfirm =>
      '¿Generar un nuevo token bearer SCIM? El token anterior dejará de funcionar inmediatamente.';

  @override
  String get ssoScimTokenTitle => 'Token bearer';

  @override
  String get ssoScimTokenPresent => 'Hay un token configurado';

  @override
  String get ssoScimTokenAbsent =>
      'Aún no hay token: genera uno para activar SCIM';

  @override
  String get ssoScimTokenOnce => 'Token SCIM (mostrado una vez)';

  @override
  String ssoSignInWith(String provider) {
    return 'Iniciar sesión con $provider';
  }

  @override
  String get ssoProbeFailed =>
      'No se pudo contactar con ese servidor para el inicio de sesión único';

  @override
  String get ssoOpensBrowser =>
      'Abre tu navegador para terminar de iniciar sesión';

  @override
  String get ssoWaitingForBrowser =>
      'Esperando a que tu navegador termine de iniciar sesión…';

  @override
  String get ssoBrowserOpenFailed =>
      'No se pudo abrir el navegador para el inicio de sesión único';

  @override
  String get ssoUseManualPairing =>
      'Inicia sesión con un código de invitación o una clave de emparejamiento';

  @override
  String get ssoHideManualPairing => 'Ocultar el emparejamiento manual';

  @override
  String get ssoClientIdHint =>
      'Cliente público (PKCE) — no hace falta secreto';

  @override
  String get ssoClientSecretLabel => 'Secreto del cliente (opcional)';

  @override
  String get ssoClientSecretHintUnset =>
      'Solo necesario para clientes confidenciales del IdP';

  @override
  String get ssoClientSecretHintSet =>
      'Hay un secreto guardado — déjalo en blanco para conservarlo';

  @override
  String get ssoPairingToggle =>
      'Permitir el emparejamiento manual (códigos de invitación y claves de emparejamiento)';

  @override
  String get ssoPairingToggleDescription =>
      'Desactívalo para que unirse sea solo con inicio de sesión único — los nuevos dispositivos llegan mediante SSO; los existentes siguen funcionando';

  @override
  String get ssoPairConfirmTitle => '¿Conectar al servidor?';

  @override
  String ssoPairConfirmBody(String server) {
    return 'Llegó una credencial de inicio de sesión para $server, pero no se inició ningún inicio de sesión desde esta aplicación. ¿Conectar a este servidor?';
  }

  @override
  String get ssoPairConfirmConnect => 'Conectar';

  @override
  String get ssoPairConfirmCancel => 'Ignorar';

  @override
  String get forgeConnections => 'Alojamiento de código';

  @override
  String get connect => 'Conectar';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get notConnected => 'No conectado';

  @override
  String get checkingConnection => 'Comprobando la conexión…';

  @override
  String get fromEnvironment => 'desde el entorno';

  @override
  String forgeTokenTitle(String forge) {
    return 'Token de $forge';
  }

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAudioDescription =>
      'Micrófono, dictado, detección de reuniones y salida de los paisajes sonoros.';

  @override
  String get audioDevicesSection => 'Dispositivos de audio';

  @override
  String get voiceInputBehaviorSection => 'Dictado y reuniones';

  @override
  String get audioOutputDeviceTitle => 'Dispositivo de salida';

  @override
  String get audioOutputDefaultHint =>
      'Todo el sonido de la aplicación se reproduce por la salida predeterminada del sistema.';

  @override
  String get audioOutputGone =>
      'El dispositivo de salida seleccionado ya no está conectado: se usa la salida predeterminada del sistema hasta que elijas otro.';

  @override
  String get reviewHubIntroBody =>
      'Los agentes analizan el diff, mapean las áreas de cambio y alcanzan un veredicto de consenso.';

  @override
  String get reviewHubAlreadyRunning =>
      'Ya hay una revisión en curso para este pull request';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'Desde la última revisión: $resolved resueltos · $added nuevos · $open aún abiertos';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'Revisado anteriormente en $sha';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return 'Corregir $count hallazgos';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return 'Corregir $count seleccionados';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return 'Comentar $count seleccionados';
  }

  @override
  String get webConnectTitle => 'Conectar a Control Center';

  @override
  String get webConnectSubtitle =>
      'Conecta con un cc-server en ejecución por WebSocket. Tu clave permanece en este dispositivo.';

  @override
  String get webConnectServerLabel => 'Servidor';

  @override
  String get webConnectDeviceIdLabel => 'Id. del dispositivo';

  @override
  String get webConnectPairingKeyLabel => 'Clave de emparejamiento';

  @override
  String get webConnectPairingKeyHint => 'pega la PSK';

  @override
  String get webConnectStayConnected => 'Seguir conectado en este dispositivo';

  @override
  String get webConnectStayConnectedDetail =>
      'Seguir conectado en este dispositivo (guarda tu clave en este navegador)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'No se pudo crear el espacio de trabajo: $error';
  }

  @override
  String committedRelative(String relative) {
    return 'confirmado $relative';
  }

  @override
  String get selectAgents => 'Seleccionar agentes';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agentes',
      one: '1 agente',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => 'Nueva conversación';

  @override
  String get untitledConversation => 'Conversación sin título';

  @override
  String get conversationTitleOptionalHint =>
      'Opcional: déjalo vacío y el modelo de títulos lo nombrará automáticamente';

  @override
  String get conversationTitlesSectionTitle => 'Títulos de conversación';

  @override
  String get conversationTitlesSectionCaption =>
      'Elige el motor que nombra automáticamente las conversaciones nuevas de este espacio de trabajo. Los títulos permanecen desactivados hasta que se elija un adaptador y se aplican a cada miembro.';

  @override
  String get conversationTitlesModelLabel => 'Modelo de títulos';

  @override
  String get conversationTitlesAdapterLabel => 'Adaptador';

  @override
  String get conversationTitlesAdapterHint => 'Desactivado';

  @override
  String get conversationTitlesAdapterOff => 'Desactivado';

  @override
  String get startThread => 'Iniciar hilo';

  @override
  String get deleteSpaceConfirm =>
      '¿Eliminar este espacio? Se perderán todos los mensajes.';

  @override
  String threadTabTitle(String title) {
    return 'Hilo: $title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respuestas',
      one: '1 respuesta',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return 'Última respuesta $time';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Iniciar sesión con $provider';
  }

  @override
  String get signInAgain => 'Volver a iniciar sesión';

  @override
  String get signInNotFinished =>
      'El inicio de sesión aún no ha vuelto. Termínalo en el navegador y vuelve a comprobarlo.';

  @override
  String get signedOutTitle => 'Has cerrado sesión';

  @override
  String get signedOutSubtitle =>
      'Tu conexión con el alojamiento de código ya no es válida — un token caducó o se revocó su acceso. No ha cambiado nada más: vuelve a iniciar sesión y todo estará donde lo dejaste.';

  @override
  String get viaServerApp => 'mediante la app de este servidor';

  @override
  String get ticketing => 'Tickets';

  @override
  String get ticketingProviderHelp =>
      'Dónde viven tus tickets. Local los mantiene en Control Center.';

  @override
  String providerComingSoon(String provider) {
    return '$provider (pronto)';
  }

  @override
  String get ticketProviderLocal => 'Local';

  @override
  String get addKey => 'Añadir clave';

  @override
  String get providerApps => 'Aplicaciones de proveedor';

  @override
  String get providerAppsDescription =>
      'Cómo se autentica este servidor a sí mismo y con qué inicia sesión una persona. El trabajo en segundo plano — webhooks, sondeos, sincronización — usa la app, nunca el token de una persona.';

  @override
  String get providerAppId => 'Id de la app';

  @override
  String get providerPrivateKey => 'Clave privada';

  @override
  String get providerClientId => 'Id de cliente';

  @override
  String get providerClientSecret => 'Secreto de cliente';

  @override
  String get providerApiKey => 'Clave de API';

  @override
  String get providerCallbackUrl => 'URL de retorno';

  @override
  String get providerAppFullyConfigured =>
      'El servidor puede actuar por sí mismo y las personas pueden iniciar sesión.';

  @override
  String get providerAppServerOnly =>
      'El servidor puede actuar por sí mismo. Añade un id y un secreto de cliente para permitir inicios de sesión.';

  @override
  String get providerAppSignInOnly =>
      'Las personas pueden iniciar sesión. El trabajo en segundo plano recurre a sus credenciales.';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'Las credenciales funcionan. Instalada en: $accounts';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return 'Introduce este código en la página de $provider que se acaba de abrir. Lo hemos copiado a tu portapapeles.';
  }

  @override
  String get deviceCodeWaiting => 'Esperando a que termines en el navegador…';

  @override
  String get copyCodeAndOpen => 'Copiar código y abrir';

  @override
  String get couldNotOpenBrowser =>
      'No se pudo abrir ningún navegador. Copia el enlace y termina el inicio de sesión tú mismo.';

  @override
  String get contextUsage => 'Uso del contexto';

  @override
  String get contextUsageFull => 'lleno';

  @override
  String get contextUsageTokens => 'tokens';

  @override
  String get contextSeeMore => 'Ver más';

  @override
  String get contextSegmentSystemPrompt => 'Prompt del sistema';

  @override
  String get contextSegmentRules => 'Reglas';

  @override
  String get contextSegmentSkills => 'Habilidades';

  @override
  String get contextSegmentToolDefinitions => 'Definiciones de herramientas';

  @override
  String get contextSegmentMcpTools => 'MCP y herramientas dinámicas';

  @override
  String get contextSegmentDeferredTools =>
      'Herramientas cargadas bajo demanda';

  @override
  String get contextSegmentSubagents => 'Definiciones de subagentes';

  @override
  String get contextSegmentMemory => 'Memoria';

  @override
  String get contextSegmentConversation => 'Conversación';

  @override
  String get contextExplorerTitle => 'Contexto';

  @override
  String get contextExplorerEverything => 'Todo';

  @override
  String get contextExplorerSelectPart =>
      'Selecciona una parte para inspeccionar su contenido';

  @override
  String get contextExplorerUnavailable => 'Desglose de contexto no disponible';

  @override
  String get contextRetry => 'Reintentar';

  @override
  String get settingsFieldOptional => 'Opcional';

  @override
  String get settingsFilterHint => 'Filtrar esta lista';

  @override
  String get settingsValueNotAvailable => 'Aún no disponible';

  @override
  String get settingsNoEntriesYet => 'Todavía no hay nada';

  @override
  String get settingsChangedBadge => 'Modificado';

  @override
  String get ssoConnectionCardDescription =>
      'Elige cómo inicia sesión la gente en este servidor y luego activa esa conexión.';

  @override
  String get ssoUseSamlForSignIn => 'Usar SAML para iniciar sesión';

  @override
  String get ssoUseOidcForSignIn => 'Usar OpenID Connect para iniciar sesión';

  @override
  String get ssoSaveConnection => 'Guardar conexión';

  @override
  String get ssoStateLive => 'Activo';

  @override
  String get ssoStateConfiguredOff => 'Configurado, desactivado';

  @override
  String get ssoStateOnIncomplete => 'Activado, incompleto';

  @override
  String get ssoStateActive => 'Activo';

  @override
  String get ssoStateAllowed => 'Permitido';

  @override
  String get ssoStateNoToken => 'Sin token';

  @override
  String get ssoSummaryDirectorySync => 'Sincronización del directorio';

  @override
  String get ssoSummaryManualPairing => 'Emparejamiento manual';

  @override
  String get ssoNoMethodLiveNote =>
      'No hay ningún método de inicio de sesión activo. Los dispositivos nuevos se unen con una invitación o una clave de emparejamiento hasta que configures una conexión y la actives.';

  @override
  String get ssoMethodSamlBlurb =>
      'Para proveedores de identidad que hablan SAML 2.0, como Okta, Entra ID o Google Workspace.';

  @override
  String get ssoMethodOidcBlurb =>
      'Para proveedores de identidad que hablan OpenID Connect. Normalmente el más sencillo de configurar de los dos.';

  @override
  String get ssoGroupIdentityProvider => 'Proveedor de identidad';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'De dónde vienen las aserciones y cómo las verifica este servidor.';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'En qué emisor confía este servidor y el cliente con el que se autentica.';

  @override
  String get ssoSpEntityIdShortLabel => 'ID de entidad del SP';

  @override
  String get ssoSpEntityIdDescription =>
      'Déjalo en blanco para derivarlo de la URL del servidor.';

  @override
  String get ssoIssuerDescription =>
      'La URL base que sirve el documento de descubrimiento del proveedor.';

  @override
  String get ssoSecretStored => 'Guardado';

  @override
  String get ssoGroupHandoff => 'Lo que necesita tu proveedor de identidad';

  @override
  String get ssoGroupHandoffDescription =>
      'Pega estos valores en la aplicación que creaste en tu proveedor.';

  @override
  String get ssoOriginUnknownTitle => 'Este servidor no conoce su URL pública';

  @override
  String get ssoOriginUnknownBody =>
      'Las URL de inicio de sesión y de retorno se construyen a partir de ella, así que tu proveedor no puede llegar a este servidor hasta que definas una. Añade una URL pública o activa un túnel en Servidor → Conexión.';

  @override
  String get ssoAcsUrlLabel =>
      'URL del servicio consumidor de aserciones (ACS)';

  @override
  String get ssoAcsUrlDescription =>
      'Donde tu proveedor envía la aserción firmada.';

  @override
  String get ssoSpEntityIdResolvedLabel =>
      'ID de entidad del proveedor de servicio';

  @override
  String get ssoMetadataUrlLabel => 'URL de metadatos del SP';

  @override
  String get ssoMetadataUrlDescription =>
      'Los proveedores que importan metadatos pueden obtenerlos aquí.';

  @override
  String get ssoRedirectUriLabel => 'URI de redirección';

  @override
  String get ssoRedirectUriDescription =>
      'Añádela a las URI de redirección permitidas de la aplicación de tu proveedor.';

  @override
  String get ssoSignInUrlLabel => 'URL de inicio de sesión';

  @override
  String get ssoSignInUrlDescription =>
      'Envía a las personas aquí para iniciar un inicio de sesión único.';

  @override
  String get ssoGroupAttributeMapping => 'Asignación de atributos';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'Qué reclamación lleva cada campo. Mantén los valores por defecto salvo que tu proveedor los renombre.';

  @override
  String get ssoGroupAccess => 'Acceso y roles';

  @override
  String get ssoGroupAccessDescription =>
      'Lo que puede hacer alguien que inicia sesión correctamente.';

  @override
  String get ssoDefaultRoleShortLabel => 'Rol por defecto';

  @override
  String get ssoDefaultRoleDescription =>
      'Se asigna a quien no coincida con ninguna asignación de abajo.';

  @override
  String get ssoRoleMapShortLabel => 'Asignación de grupo a rol';

  @override
  String get ssoRoleMapDescription =>
      'Gana el primer grupo que coincida. El rol de propietario no se puede conceder así.';

  @override
  String get ssoRoleMapGroupHint => 'Nombre del grupo en tu proveedor';

  @override
  String get ssoRoleMapAdd => 'Añadir asignación';

  @override
  String get ssoRoleMapEmpty =>
      'Sin asignaciones: todos reciben el rol por defecto.';

  @override
  String get ssoAdvancedSummary =>
      'Desfase de reloj, inicio de sesión iniciado por el IdP, política de firmas';

  @override
  String get ssoClockSkewShortLabel => 'Desfase de reloj';

  @override
  String get ssoClockSkewDescription =>
      'Segundos de tolerancia en las marcas de tiempo de las aserciones. 90 sirve para la mayoría de proveedores.';

  @override
  String get ssoScimGenerate => 'Generar token';

  @override
  String get ssoScimTokenOnceBody =>
      'Copiado al portapapeles. Se muestra una sola vez y no se puede recuperar, así que pégalo en tu proveedor ahora.';

  @override
  String get ssoPairingCardTitle => 'Emparejamiento manual';

  @override
  String get ssoPairingCardDescription =>
      'La otra vía de entrada a este servidor: códigos de invitación y claves de emparejamiento, para dispositivos que no pasan por el inicio de sesión único.';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count de $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'No hay ningún proveedor conectado, así que el motor de agentes integrado no tiene con qué funcionar. Añade una clave de API o inicia sesión en alguno de abajo.';

  @override
  String get providersFilterHint => 'Filtrar proveedores';

  @override
  String get providersFacetNeedsSetup => 'Falta configurar';

  @override
  String get providersFacetCustom => 'Personalizados';

  @override
  String get providersNoneMatch => 'Nada coincide con este filtro';

  @override
  String get providerDeniedHereTitle => 'Denegado en este espacio de trabajo';

  @override
  String get providerDeniedHereBody =>
      'Los agentes de aquí no pueden usar este proveedor, aunque esté conectado. Otros espacios de trabajo no se ven afectados.';

  @override
  String get providerNeedsSignIn => 'Inicia sesión para usar este proveedor';

  @override
  String get providerNeedsApiKey =>
      'Añade una clave de API para usar este proveedor';

  @override
  String get providerApiKeyLabel => 'Clave de API';

  @override
  String get providerGenerationDefaults => 'Valores por defecto del proveedor';

  @override
  String get providerNoModelsYet =>
      'Todavía no hay modelos. Conecta el proveedor y luego sincroniza.';

  @override
  String get providerModelsFilterHint => 'Filtrar modelos';

  @override
  String get adaptersNoneReadyNote =>
      'No se encontró en esta máquina ninguna de las CLI de runners del catálogo. Instala una y luego actualiza.';

  @override
  String get adaptersFilterHint => 'Filtrar runners';

  @override
  String get adaptersFacetReady => 'Listos';

  @override
  String get adaptersFacetMissing => 'Ausentes';

  @override
  String get adaptersLaunchGroup => 'Lanzamiento';

  @override
  String get adaptersLaunchGroupDescription =>
      'Lo que recibe este runner cuando un agente lo inicia. Puedes configurarlo antes incluso de instalar la CLI.';

  @override
  String get adaptersEnvNone => 'Ninguna definida';

  @override
  String adaptersEnvCount(int count) {
    return '$count definidas';
  }

  @override
  String get adapterArgumentsDescription =>
      'Se añaden a la línea de comandos del runner en cada arranque.';

  @override
  String get defaultChatDescription =>
      'Ejecuta las conversaciones nuevas y cualquier agente sin runner propio.';

  @override
  String get shortTaskDescription =>
      'Ejecuta trabajo breve en segundo plano, como títulos y resúmenes. Aquí encaja un modelo más pequeño.';

  @override
  String get settingsStateFailed => 'Error';

  @override
  String get providerAppsGroupServer => 'Actuar como el servidor';

  @override
  String get providerAppsGroupServerDescription =>
      'Permite que el trabajo en segundo plano llegue a los repositorios sin una persona detrás: webhooks, sondeo de pull requests, sincronización de tickets.';

  @override
  String get providerAppsGroupPrConversations =>
      'Conversaciones de pull request';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'Cómo pueden los desarrolladores hablar con este servidor directamente en GitHub. Funciona sin webhook y sin URL pública — el servidor sondea periódicamente.';

  @override
  String get providerAppBotLogin => 'Login del bot';

  @override
  String get providerAppBotLoginEmpty =>
      'Prueba la conexión para resolver el login del bot.';

  @override
  String get providerAppAskOnGitHub => 'Consultar en GitHub';

  @override
  String get providerAppAskOnGitHubHint =>
      'Menciona el login del bot de arriba en un comentario de pull request — el sufijo [bot] es opcional — para pedir una revisión o hacer una pregunta, responde en sus hilos de revisión, o añade la etiqueta `ai-review` para solicitar una revisión.';

  @override
  String get providerAppsGroupSignIn => 'Inicio de sesión de las personas';

  @override
  String get providerAppsGroupSignInDescription =>
      'Permite que cada miembro conecte su propia cuenta y obtenga sus propias credenciales.';

  @override
  String get providerAppCapActsAsServer => 'Actúa como el servidor';

  @override
  String get providerAppCapSignsIn => 'Inicia sesión a las personas';

  @override
  String get portLabel => 'Puerto';

  @override
  String get mcpNoTokenWarning =>
      'Sin un token, cualquier cosa que alcance este puerto puede llamar a todas las herramientas.';

  @override
  String get mcpBridgedToolsLabel => 'Herramientas';

  @override
  String get guardrailFamilyFiles => 'Archivos';

  @override
  String get guardrailFamilyGit => 'Git y pull requests';

  @override
  String get guardrailFamilyMachine => 'Máquina y red';

  @override
  String get guardrailFamilyControl => 'Secretos y espacio de trabajo';

  @override
  String get guardrailScopeFieldLabel => 'Editando reglas para';

  @override
  String get guardrailScopeFieldDescription =>
      'Un ámbito más estrecho prevalece sobre uno más amplio. Las reglas definidas aquí se aplican por encima de lo heredado.';

  @override
  String get guardrailSetHere => 'Definidas aquí';

  @override
  String get guardrailClearAllHere => 'Borrar todo';

  @override
  String get sandboxingCardLabel => 'Aislamiento';

  @override
  String get sandboxingCardDescription =>
      'Si el trabajo de los agentes se ejecuta aislado de este host y a qué puede llegar aún un agente aislado.';

  @override
  String get sandboxBackendNoneActive => 'Host, sin aislamiento';

  @override
  String get sandboxSummaryHost => 'Host';

  @override
  String get sandboxGroupIsolation => 'Aislamiento';

  @override
  String get sandboxGroupIsolationDescription =>
      'Dónde ocurren realmente los procesos y las escrituras de archivos de un agente.';

  @override
  String get sandboxBackendFieldDescription =>
      'El modo automático elige el más fuerte que admite este host. Fija uno para que no cambie por su cuenta.';

  @override
  String get sandboxCapabilitiesDescription =>
      'Los huecos abiertos en la frontera. Cada uno es algo que un agente aislado todavía puede hacer al mundo exterior.';

  @override
  String get sandboxSummaryInForce => 'En vigor';

  @override
  String get rigsInstallHintLabel => 'Cómo instalarlo';

  @override
  String get rigsStarting => 'Iniciando';

  @override
  String get rigsResidentMemory => 'Memoria residente';

  @override
  String get installedLabel => 'Instalado';

  @override
  String get notInstalledLabel => 'No instalado';

  @override
  String ssoOtherKindUnsaved(String method) {
    return '$method tiene cambios sin guardar';
  }

  @override
  String get collapseComment => 'Contraer comentario';

  @override
  String get expandComment => 'Expandir comentario';

  @override
  String get suggestedChange => 'Cambio sugerido';

  @override
  String get emptyComment => 'Comentario vacío';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respuestas',
      one: '1 respuesta',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => 'Revisión pendiente';

  @override
  String failedToResolveConversation(String error) {
    return 'No se pudo actualizar la conversación: $error';
  }

  @override
  String get addSingleComment => 'Añadir un solo comentario';

  @override
  String get addToReview => 'Añadir a la revisión';

  @override
  String get startAReview => 'Iniciar una revisión';

  @override
  String get reviewNeedsABody =>
      'Escribe un resumen o añade primero un comentario en línea';

  @override
  String get reviewSubmitted => 'Revisión enviada';

  @override
  String get finishYourReview => 'Finalizar tu revisión';

  @override
  String get commentVerdict => 'Comentar';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comentarios pendientes',
      one: '1 comentario pendiente',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 'y $count más';
  }

  @override
  String get queuedCommentHint =>
      'Este comentario se enviará cuando envíes tu revisión.';

  @override
  String commentOnLinesRange(int start, int end) {
    return 'Líneas $start a $end';
  }

  @override
  String get claudeAccountsTitle => 'Cuentas de Claude Code';

  @override
  String get claudeAccountsDescription =>
      'Cada cuenta es un inicio de sesión de Claude Code independiente. Las ejecuciones usan las cuentas adjuntas abajo, en este orden.';

  @override
  String get claudeAccountsEmpty => 'Aún no hay cuentas';

  @override
  String get claudeAccountAdd => 'Añadir cuenta';

  @override
  String get claudeAccountSignIn => 'Iniciar sesión';

  @override
  String get claudeAccountSignInAgain => 'Volver a iniciar sesión';

  @override
  String get claudeAccountSignInHint =>
      'Ejecuta esto en una terminal del servidor. Se abre un navegador para completar el inicio de sesión y la credencial se guarda en la carpeta de esta cuenta.';

  @override
  String get claudeAccountSignedOut => 'Sesión cerrada';

  @override
  String get claudeAccountExpired => 'Sesión caducada';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'La sesión caducó a las $when. Vuelve a iniciar sesión para usar esta cuenta.';
  }

  @override
  String get claudeAccountMakeDefault => 'Establecer como predeterminada';

  @override
  String get claudeAccountDefault => 'Predeterminada';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return '¿Eliminar $label?';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'Se cierra la sesión de la cuenta y se elimina su carpeta del servidor. El inicio de sesión en sí no se ve afectado.';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'No se pudo comprobar esta cuenta: $error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return '$percent % usado';
  }

  @override
  String get accountPoolStrategy => 'Rotación';

  @override
  String get accountPoolPinned => 'Fija';

  @override
  String get accountPoolRoundRobin => 'Por turnos';

  @override
  String get accountPoolSerial => 'Uno a uno';

  @override
  String get accountPoolPinnedHint =>
      'Empezar siempre por la primera cuenta. Las demás quedan como respaldo si falla.';

  @override
  String get accountPoolRoundRobinHint =>
      'Repartir las ejecuciones entre las cuentas, pasando a la siguiente en cada envío.';

  @override
  String get accountPoolSerialHint =>
      'Agotar la primera cuenta antes de pasar a la siguiente.';

  @override
  String get accountPoolMoveUp => 'Subir';

  @override
  String get accountPoolMoveDown => 'Bajar';

  @override
  String get accountPoolUsingAll =>
      'Sin cuentas adjuntas: se usan todas, en este orden.';

  @override
  String get accountPoolInheriting =>
      'Hereda las cuentas del espacio de trabajo.';

  @override
  String get accountPoolResetToWorkspace =>
      'Volver a las cuentas del espacio de trabajo';

  @override
  String accountPoolCoolingOff(String when) {
    return 'sin cuota hasta $when';
  }

  @override
  String get accountPoolSignedOut => 'sesión cerrada';

  @override
  String get accountPoolExpired => 'sesión caducada';

  @override
  String accountPoolLoadFailed(String error) {
    return 'No se pudo cargar la rotación: $error';
  }

  @override
  String get providerSignedInAccount => 'cuenta con sesión iniciada';

  @override
  String get agentAccountsTab => 'Cuentas';

  @override
  String get agentClaudeAccountsNoticeTitle => 'Varias cuentas de Claude Code';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return 'Este ejecutor inicia sesión con una de las $count cuentas de Claude Code de este host. Elige cuál, o alterna entre ellas, en la pestaña Cuentas.';
  }

  @override
  String get agentAccountsDescription =>
      'Qué cuentas usan las ejecuciones de este agente. Cada bloque hereda al principio la elección del espacio de trabajo.';

  @override
  String get agentAccountsNothingToRotate =>
      'Nada que rotar: conecta primero una segunda cuenta o clave.';

  @override
  String failedToPostReply(String error) {
    return 'No se pudo publicar la respuesta: $error';
  }

  @override
  String commentOnLine(int line) {
    return 'Línea $line';
  }

  @override
  String get viewInDiff => 'Ver en el diff';

  @override
  String get subscriptionUsagePreviousAccount => 'Cuenta anterior';

  @override
  String get subscriptionUsageNextAccount => 'Cuenta siguiente';

  @override
  String inReplyTo(String path) {
    return 'En respuesta a $path';
  }

  @override
  String get subscriptionUsageNoneReported =>
      'Esta cuenta no informa de ningún uso.';

  @override
  String get subscriptionUsageCredits => 'Créditos';

  @override
  String get reviewHubStaticRule => 'Regla estática';

  @override
  String get reviewHubStarted => 'Revisión iniciada';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'Encontrado por una regla determinista ($rule) en una línea que añade esta pull request, no por un agente revisor.';
  }

  @override
  String get prReviewArtifactTab => 'Revisión de PR';

  @override
  String get prReviewRunning => 'Revisando esta pull request…';

  @override
  String get prReviewStarting => 'Iniciando la revisión…';

  @override
  String get prReviewStartingBody =>
      'Preparando el worktree de esta pull request. Los revisores empiezan en cuanto esté listo.';

  @override
  String get prReviewFailed => 'La revisión falló.';

  @override
  String get prReviewRerunning => 'Revisando de nuevo…';

  @override
  String get prReviewNoOpenFindings => 'Sin hallazgos abiertos';

  @override
  String prReviewOpenFindings(int count) {
    return '$count hallazgos abiertos';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used de $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return '$posted comentario(s) publicado(s) por el bot. $skipped omitido(s) (sin ancla de archivo), $failed fallido(s).';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count hallazgo(s) apuntan a código que este pull request no modifica ($files). GitHub solo acepta comentarios en línea sobre el diff.';
  }

  @override
  String get reviewRailReport => 'Informe';

  @override
  String get reviewNoFindingsTitle => 'Aún no hay hallazgos';

  @override
  String get reviewNoFindingsHint =>
      'Los hallazgos aparecerán aquí a medida que los agentes los publiquen.';

  @override
  String reviewShowDismissed(int count) {
    return 'Mostrar $count descartados';
  }

  @override
  String reviewHideDismissed(int count) {
    return 'Ocultar $count descartados';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count discrepancias entre revisores detectadas',
      one: '1 discrepancia entre revisores detectada',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'Tipo';

  @override
  String get reviewFilterStatus => 'Estado';

  @override
  String get reviewKindBug => 'Error';

  @override
  String get reviewKindSuggestion => 'Sugerencia';

  @override
  String get reviewKindRecommendation => 'Recomendación';

  @override
  String get reviewKindQuestion => 'Pregunta';

  @override
  String get reviewKindTicket => 'Ticket';

  @override
  String get archiveSpace => 'Archivar espacio';

  @override
  String get archivedSpaces => 'Espacios archivados';

  @override
  String get archivedSpacesEmpty => 'No hay espacios archivados';

  @override
  String get restoreSpace => 'Restaurar';

  @override
  String archivedWhen(String time) {
    return 'Archivado $time';
  }

  @override
  String get deleteSpacePermanently => 'Eliminar permanentemente';

  @override
  String get renameSpace => 'Renombrar espacio';

  @override
  String get renameConversation => 'Renombrar conversación';

  @override
  String get editSpaceRepos => 'Editar repositorios';

  @override
  String get editSpaceReposTitle => 'Repositorios del espacio';

  @override
  String get editSpaceReposWarning =>
      'Añadir un repositorio lo descarga en este espacio; quitar uno elimina su carpeta.';

  @override
  String get agentSectionIdentity => 'Identidad';

  @override
  String get agentSectionRuntime => 'Ejecución';

  @override
  String get agentSectionGuardrails => 'Salvaguardas';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subordinados',
      one: '1 subordinado',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'Filtrar equipos…';

  @override
  String get teamsSummaryWithLeader => 'Con responsable';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count equipos',
      one: '1 equipo',
      zero: 'Sin equipos',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return 'Eliminar $name borra su perfil, sus vínculos de habilidades y su historial de ejecución. Esta acción no se puede deshacer.';
  }

  @override
  String get resetToDefault => 'Restablecer valores';

  @override
  String get newAgent => 'Nuevo agente';

  @override
  String get newSkill => 'Nueva habilidad';

  @override
  String get zoomIn => 'Acercar';

  @override
  String get zoomOut => 'Alejar';

  @override
  String get resetZoom => 'Restablecer el zoom';

  @override
  String get imageHostedOnGitHub => 'Imagen alojada en GitHub';

  @override
  String get imageOpenExternally => 'Imagen · abrir externamente';

  @override
  String get memoryScopeAll => 'Todos los ámbitos';

  @override
  String get memoryScopeWorkspace => 'Todo el espacio de trabajo';

  @override
  String get memoryScopeFilterLabel => 'Filtrar por ámbito';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return 'Limitado al repositorio $repo';
  }

  @override
  String get toolScreenshot => 'Captura de pantalla del agente';

  @override
  String get toolImageUnavailable => 'Imagen no disponible';

  @override
  String toolImagesUnavailable(int count) {
    return '$count imágenes no disponibles';
  }

  @override
  String get shakeUnavailable =>
      'La limpieza no está disponible en este servidor';

  @override
  String get shakeNothing =>
      'Nada que limpiar: los turnos recientes están protegidos';

  @override
  String shakeDone(int tokens) {
    return 'Se liberaron unos $tokens tokens';
  }

  @override
  String get compactionDivider => 'Compactado';

  @override
  String compactionDividerCount(int count) {
    return 'Compactado · $count mensajes plegados';
  }

  @override
  String get composerDropToAttach => 'Suelta para adjuntar';

  @override
  String get attachmentUnavailable => 'Adjunto no disponible';

  @override
  String get attachmentUnavailableDetail =>
      'Este adjunto ya no está en memoria. Vuelve a adjuntarlo para verlo.';

  @override
  String get attachmentPreviewFailed => 'No se pudo abrir este archivo';

  @override
  String get attachmentPreviewUnsupported =>
      'Sin vista previa para este tipo de archivo';

  @override
  String get attachmentTooLargeToPreview =>
      'Demasiado grande para la vista previa';

  @override
  String get attachmentOpenExternally => 'Abrir en la app predeterminada';

  @override
  String get asideUnavailable =>
      'Configura un modelo puntual en los ajustes para usar esto';

  @override
  String get asideEmpty => 'Todavía no hay nada con qué trabajar';

  @override
  String get asideFailed => 'No se pudo obtener una respuesta';

  @override
  String get handoffTitle => 'Traspaso';

  @override
  String get asideTitle => 'Pregunta lateral';

  @override
  String get attachFilesOrDrop => 'Adjuntar archivos — o suéltalos aquí';

  @override
  String get guidedGoalTitle => 'Afinar el objetivo';

  @override
  String get guidedGoalIntro =>
      'Un agente que trabaja sin supervisión necesita saber exactamente cuándo ha terminado. Primero, unas preguntas.';

  @override
  String get guidedGoalAnswerHint => 'Tu respuesta';

  @override
  String get guidedGoalNext => 'Siguiente';

  @override
  String get guidedGoalStart => 'Iniciar el objetivo';

  @override
  String get guidedGoalSkip => 'Omitir y ejecutar tal cual';

  @override
  String guidedGoalStillMissing(String items) {
    return 'Aún sin especificar: $items';
  }

  @override
  String get conversationTreeTitle => 'Árbol de la conversación';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ramas',
      one: '1 rama',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'Continuar desde aquí';

  @override
  String get conversationTreeFork => 'Bifurcar en una conversación nueva';

  @override
  String get conversationTreeCurrent => 'En esta rama';

  @override
  String get conversationTreeEmpty => 'Aún no hay nada';

  @override
  String get conversationTreeForked => 'Bifurcada en una conversación nueva';

  @override
  String get conversationTreeSwitched => 'Continuará desde ese mensaje';

  @override
  String exportSaved(String path) {
    return 'Guardado en $path';
  }

  @override
  String get exportFailed => 'No se pudo escribir la exportación';

  @override
  String get contextCommandNoAgent =>
      'No hay ningún agente en esta conversación, así que no hay ventana de contexto que abrir';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'No hay ningún agente llamado «$name» en esta conversación. Prueba con: $names';
  }

  @override
  String get dumpCopied => 'Transcripción copiada al portapapeles';

  @override
  String get messageQueueHint =>
      'Sigue escribiendo para poner en cola los cambios de seguimiento';

  @override
  String get steerNow => 'Orientar';

  @override
  String get steeringQueueLabel => 'Mensajes de orientación en cola';

  @override
  String get steeringDeliverUnavailable =>
      'Ningún agente en ejecución puede recibirlo ahora; queda en cola.';

  @override
  String get reorderSteeringCard => 'Reordenar el mensaje en cola';

  @override
  String get editSteeringCard => 'Editar el mensaje en cola';

  @override
  String get deleteSteeringCard => 'Eliminar el mensaje en cola';

  @override
  String get steeringBadge => 'Orientado';

  @override
  String get settingsSandboxLabel => 'Entorno aislado';

  @override
  String get sandboxExecGrantsTitle => 'Permisos de ejecución';

  @override
  String get sandboxExecGrantsSubtitle =>
      'Programas que los agentes pueden ejecutar desde su copia de trabajo de tus repositorios. Cada entrada fue aprobada por ti cuando el entorno aislado lo preguntó.';

  @override
  String get sandboxExecGrantsEmpty =>
      'Aún no hay decisiones registradas. Se te preguntará la primera vez que un agente necesite ejecutar un programa desde su copia de trabajo.';

  @override
  String get sandboxExecGrantRevoke => 'Revocar';

  @override
  String get sandboxExecGrantAllowed => 'Permitido';

  @override
  String get sandboxExecGrantBlocked => 'Bloqueado';

  @override
  String get sandboxExecGrantRevokeConfirmTitle => '¿Revocar esta decisión?';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'Se te volverá a preguntar la próxima vez que un agente necesite ejecutar un programa desde esta copia.';

  @override
  String get repoScriptsTest => 'Probar';

  @override
  String get repoScriptsTestTooltip =>
      'Ejecutar este borrador en un clon desechable del repositorio';

  @override
  String get repoScriptsRunKindTest => 'Prueba';

  @override
  String get demoBadgeLabel => 'Demo';

  @override
  String get demoFilePickerTitle => 'Archivos de demo';

  @override
  String get demoFilePickerBody =>
      'La demo simula las subidas: elige uno y se adjunta a tu mensaje sin tocar ningún disco.';

  @override
  String get demoFilePickerAttach => 'Adjuntar';

  @override
  String get demoReadOnlySave => 'Solo lectura en la demo';

  @override
  String get demoBadgeTooltip =>
      'Estás explorando una demo. Los datos son ficticios y los agentes están guionizados.';

  @override
  String get demoFirstRunTitle => 'Estás en una demo en vivo';

  @override
  String demoFirstRunBody(int minutes) {
    return 'Esta es la aplicación real sobre código real: solo los datos son inventados. Los agentes transmiten ejecuciones auténticas desde un guion, así que nada llega a un modelo y nada se ejecuta en una máquina. Tu espacio de trabajo es solo tuyo y desaparece a los $minutes minutos.';
  }

  @override
  String get demoFirstRunDismiss => 'Entendido';

  @override
  String get demoTourTitle => 'Por dónde empezar';

  @override
  String get demoTourSubtitle =>
      'Cuatro lugares que muestran lo que hace realmente la aplicación.';

  @override
  String get demoTourSkip => 'Omitir';

  @override
  String get demoTourStarRepo => 'Dar una estrella en GitHub';

  @override
  String get demoTourDone => 'Listo';

  @override
  String get demoTourOpen => 'Abrir';

  @override
  String get demoTourSpacesTitle => 'Habla con un agente';

  @override
  String get demoTourSpacesBody =>
      'Envía un mensaje en un espacio y observa cómo llega una ejecución: razonamiento, llamadas a herramientas y coste, igual que una ejecución real.';

  @override
  String get demoTourReviewTitle => 'Revisa una pull request';

  @override
  String get demoTourReviewBody =>
      'Abre la #412. Deja un comentario en línea o envía una revisión: tus palabras aparecen en el hilo y se quedan ahí.';

  @override
  String get demoTourTicketsTitle => 'Sigue el trabajo';

  @override
  String get demoTourTicketsBody =>
      'Los tickets, las tareas y los planes están enlazados con las mismas conversaciones que mantienen los agentes.';

  @override
  String get demoTourInboxTitle => 'Ve toda la operación';

  @override
  String get demoTourInboxBody =>
      'Cada aviso de cada pilar llega a una sola bandeja de entrada: revisiones, tickets, ejecuciones y reuniones.';

  @override
  String demoSessionEndingSoon(int minutes) {
    return 'Esta sesión de demo termina en $minutes minutos.';
  }

  @override
  String get demoSessionEnded =>
      'Esta sesión de demo ha terminado. Recarga la página para iniciar otra.';

  @override
  String get demoUnavailableTitle => 'No disponible en la demo';

  @override
  String get demoUnavailableTerminal =>
      'Un terminal ejecuta un shell real en el servidor. La demo no tiene ninguna superficie de ejecución: eso es lo que permite abrirla al público con seguridad.';

  @override
  String get demoUnavailableRig =>
      'Un recinto es una máquina virtual desechable que dirige un agente. La demo no arranca ninguna: un endpoint público capaz de lanzar una VM no es una demo.';

  @override
  String get demoUnavailableEditor =>
      'El editor en el navegador ejecuta un proceso code-server sobre una copia de trabajo real. La demo no tiene ninguna de las dos cosas.';

  @override
  String get demoUnavailableFeeds =>
      'La demo lee feeds reales, pero su lista de suscripciones es fija. Añadir o quitar uno está desactivado aquí.';

  @override
  String get demoUnavailableForge =>
      'La demo no guarda credenciales y nunca contacta con GitHub, GitLab ni Linear. Sus pull requests son fixtures y tus comentarios se guardan en local.';

  @override
  String get demoUnavailableModels =>
      'La demo no llama a ningún modelo. Las ejecuciones de agentes son reproducciones guionizadas, por eso no cuestan nada ni alcanzan a ningún proveedor.';

  @override
  String get demoUnavailableMcp =>
      'La superficie de herramientas MCP no está montada en la demo, así que ningún cliente externo puede conectarse.';

  @override
  String get demoUnavailableRepos =>
      'La demo no descarga código ni ejecuta git. El repositorio que ves es una fixture detrás de las pull requests.';

  @override
  String get demoUnavailableSkills =>
      'Instalar una skill descarga y analiza código. La demo no descarga nada.';

  @override
  String get demoUnavailableSso =>
      'El inicio de sesión único es configuración del servidor. La demo te identifica como invitado temporal.';

  @override
  String get demoUnavailableAudio =>
      'Grabar y dictar requieren captura de audio y un modelo de voz en el host. La demo no incluye ninguno: sus reuniones son transcripciones sin reproducción.';

  @override
  String get demoUnavailableServerAdmin =>
      'Esto es administración del servidor. La demo te da un espacio de trabajo desechable y nada más.';

  @override
  String get settingsBackupRestore => 'Copia de seguridad y restauración';

  @override
  String get settingsBackupRestoreDescription =>
      'Instantáneas de todas las bases de datos de este servidor, además de exportar, importar y eliminar un espacio de trabajo.';

  @override
  String get backupSnapshotsLabel => 'Instantáneas de la instalación';

  @override
  String get backupSnapshotsExplainer =>
      'Una instantánea copia cada base de datos en una carpeta con fecha en el host del servidor. Restaurar toda la instalación es volver a copiar esa carpeta con el servidor detenido; un solo espacio de trabajo se puede restaurar desde aquí.';

  @override
  String get backupNowAction => 'Crear copia ahora';

  @override
  String backupSnapshotWritten(String path) {
    return 'Instantánea escrita en $path';
  }

  @override
  String get backupNoSnapshots =>
      'Todavía no hay instantáneas. Solo se crean cuando lo pides: no hay nada programado.';

  @override
  String get backupSnapshotComplete => 'Completa';

  @override
  String get backupSnapshotIncomplete => 'Incompleta';

  @override
  String get backupSnapshotIncompleteNote =>
      'Falta el manifiesto o nombra archivos que no están, así que esta instantánea no puede restaurar toda la instalación. Los archivos de espacio de trabajo que sí tiene siguen siendo adoptables uno a uno.';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count espacios de trabajo',
      one: '1 espacio de trabajo',
      zero: 'Ningún espacio de trabajo',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count espacios de trabajo no capturados',
      one: '1 espacio de trabajo no capturado',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'Ruta en el servidor';

  @override
  String get backupRestoreAction => 'Restaurar';

  @override
  String get backupRestoreTitle => 'Restaurar espacio de trabajo';

  @override
  String backupRestoreBody(String name) {
    return 'Esto sustituye todo lo que hay en $name por la copia guardada en esta instantánea. Todo lo que ese espacio de trabajo haya hecho desde entonces se pierde, y no se puede deshacer.';
  }

  @override
  String backupRestoreDone(String name) {
    return '$name restaurado desde la instantánea.';
  }

  @override
  String get backupWorkspaceUnknown => 'Ya no está en este servidor';

  @override
  String get backupWorkspaceDataLabel => 'Datos del espacio de trabajo';

  @override
  String get backupWorkspaceDataExplainer =>
      'Un espacio de trabajo es un solo archivo de base de datos, así que exportarlo copia ese archivo en vez de volcar tabla por tabla. Importar sustituye todo lo que hay en el espacio de trabajo de destino por el archivo que indiques.';

  @override
  String get backupExportAction => 'Exportar';

  @override
  String backupExportDone(String path) {
    return 'Exportado a $path';
  }

  @override
  String get backupExportedFileLabel => 'Archivo exportado en el servidor';

  @override
  String get backupImportAction => 'Importar';

  @override
  String backupImportTitle(String name) {
    return 'Importar en $name';
  }

  @override
  String backupImportBody(String name) {
    return 'Esto sustituye todo lo que hay en $name por el contenido del archivo. Lo que ese espacio de trabajo contenga ahora se pierde, y no se puede deshacer.';
  }

  @override
  String get backupImportSourceLabel =>
      'Archivo de base de datos del espacio de trabajo';

  @override
  String get backupImportSourceDescription =>
      'Un archivo .db que el servidor pueda leer. Las rutas se resuelven en el host del servidor, no en este dispositivo.';

  @override
  String get backupImportChooseFile => 'Elegir archivo';

  @override
  String backupImportDone(String name) {
    return 'Importado en $name.';
  }

  @override
  String backupDeleteBody(String name) {
    return '$name desaparece de todas las listas y búsquedas. Su archivo de base de datos permanece en el disco, las copias de seguridad lo siguen incluyendo y nada recupera ese espacio automáticamente.';
  }

  @override
  String get backupExportDescription =>
      'Escribe una copia en el servidor o descarga una en este dispositivo.';

  @override
  String get backupExportOnServerAction => 'Guardar en el servidor';

  @override
  String get backupDownloadAction => 'Descargar';

  @override
  String backupDownloadSaved(String path) {
    return 'Guardado en $path';
  }

  @override
  String get backupDownloadInBrowser => 'Tu navegador se está encargando.';

  @override
  String get backupRestoreFromDeviceLabel => 'Restaurar desde este dispositivo';

  @override
  String get backupRestoreFromDeviceDescription =>
      'Elige aquí un archivo de base de datos de espacio de trabajo y Control Center lo sube al servidor. Es la vía que funciona cuando el servidor no es esta máquina.';

  @override
  String get backupUploadAction => 'Elegir un archivo y subirlo';

  @override
  String get backupTransferUnavailable =>
      'Esta conexión llega al servidor a través de un relé, que no transporta archivos. Conéctate directamente al servidor para descargar o subir una copia de seguridad.';

  @override
  String get backupTransferForbidden =>
      'El servidor lo rechazó. Descargar un espacio de trabajo requiere el rol admin, restaurarlo requiere owner y una instantánea completa requiere el operador de la instalación.';

  @override
  String get backupTransferUnsupported =>
      'Este servidor no expone ninguna superficie de copia de seguridad.';

  @override
  String get backupTransferTooLarge =>
      'El archivo supera el tamaño que acepta el servidor.';

  @override
  String get credentialGateWaitingTitle => 'Esperando una credencial';

  @override
  String credentialGateHarnessTitle(String provider) {
    return '$provider no tiene credencial';
  }

  @override
  String get credentialGateSignedOutTitle =>
      'Claude Code no tiene sesión iniciada';

  @override
  String get credentialGateExpiredTitle =>
      'Tu sesión de Claude Code ha caducado';

  @override
  String get credentialGatePlanSpentTitle =>
      'Límite del plan de Claude Code alcanzado';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent está esperando para continuar.';
  }

  @override
  String get credentialGateWaitingRun =>
      'Una ejecución está esperando para continuar.';

  @override
  String get credentialGateWatching =>
      'Vigilando el arreglo: la ejecución continúa por sí sola.';

  @override
  String credentialGateFreesUpAt(String time) {
    return 'Se libera a las $time';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'La ejecución se rinde a las $time';
  }

  @override
  String get credentialGateCheckAgain => 'Comprobar de nuevo';

  @override
  String get credentialGateCancelRun => 'Cancelar la ejecución';

  @override
  String get credentialGateAccountsTried => 'Cuentas probadas';

  @override
  String get credentialGateClaudeSignInHint =>
      'Inicia sesión desde Ajustes → Adaptadores → Claude Code, o ejecuta el comando de inicio de sesión en una terminal. La ejecución lo detecta por sí sola.';

  @override
  String get credentialGateOpenSettings => 'Abrir ajustes';
}
