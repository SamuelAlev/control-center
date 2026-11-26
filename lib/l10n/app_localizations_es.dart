// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String steeringForceSendFailed(String error) {
    return 'No se pudo enviar ahora: $error';
  }

  @override
  String get questionAnswerNotDelivered =>
      'Tu respuesta no se entregó. Es posible que ya se haya respondido o que el agente haya dejado de esperar.';

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
  String get guardrailClassPrPublish =>
      'Actualizar o fusionar una pull request';

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
      'Este servidor no puede alojar ninguna superficie de rig. Comprueba los requisitos del host para la máquina que quieres usar.';

  @override
  String get rigSurfaceComputer => 'Ordenador';

  @override
  String get rigSurfaceBrowser => 'Navegador';

  @override
  String get rigSurfaceAndroid => 'Android';

  @override
  String get rigSurfaceIosSimulator => 'Simulador de iOS';

  @override
  String get rigSurfaceAppWindow => 'Ventana de la aplicación';

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
  String get rigStartAndroidHint =>
      'Se conecta a un emulador de Android que ya se está ejecutando en el servidor. El acceso a la red no está aislado.';

  @override
  String get rigStartIosHint =>
      'Crea un simulador de iOS desechable en un servidor macOS. Se elimina cuando se cierra el entorno de pruebas; el acceso a la red no está aislado.';

  @override
  String get rigTechnicalDetails => 'Detalles técnicos';

  @override
  String get rigStopMachine => 'Detener la máquina';

  @override
  String get rigHomeButton => 'Inicio';

  @override
  String get rigRotateClockwise => 'Girar a la derecha';

  @override
  String get rigRotateCounterclockwise => 'Girar a la izquierda';

  @override
  String get rigTakeScreenshot => 'Hacer una captura';

  @override
  String get rigScreenshotSaved => 'Captura guardada';

  @override
  String rigScreenshotSaveFailed(String error) {
    return 'No se pudo guardar la captura: $error';
  }

  @override
  String get rigSurfaceUnavailable =>
      'Este servidor no puede alojar este tipo de máquina.';

  @override
  String get rigTabNeedsConversation =>
      'Abre primero una conversación: una máquina pertenece a una, para que tus agentes y tú veáis la misma pantalla.';

  @override
  String get ideMenuSectionTools => 'Herramientas';

  @override
  String get ideMenuSectionMachines => 'Máquinas';

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
  String get rigMenuAndroid => 'Android';

  @override
  String get rigMenuIosSimulator => 'Simulador de iOS';

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
  String get rigInstallIosAutomation =>
      'Instalar el puente de automatización de iOS';

  @override
  String get rigInstallingIosAutomation =>
      'Instalando el puente de automatización de iOS…';

  @override
  String get rigIosAutomationInstalled =>
      'Puente de automatización de iOS instalado';

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
  String get rigStreamNeedsScreenCapture =>
      'La vista en directo necesita Grabación de pantalla. Concédesela a Control Center en Ajustes del Sistema y vuelve a abrir la pestaña.';

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
  String get rigPortsTooltipHost => 'Puertos abiertos en esta terminal';

  @override
  String get rigPortsEmptyHost =>
      'Aún no hay nada escuchando en esta terminal. Arranca un servidor y aparece aquí.';

  @override
  String get rigPortsAddHintHost => 'Puerto a asignar (p. ej. 5173)';

  @override
  String get rigPortsLocalPortHint => 'Puerto local (opcional)';

  @override
  String rigPortsDestDesktop(int port) {
    return 'localhost:$port';
  }

  @override
  String rigPortsDestBrowser(int port) {
    return 'localhost:$port en el navegador (VM)';
  }

  @override
  String get rigPortsDestBrowserUnreachable => 'navegador (VM) no conectado';

  @override
  String rigPortsDestAndroid(int port) {
    return 'localhost:$port en Android';
  }

  @override
  String get rigPortsDestAndroidUnreachable => 'Android no conectado';

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
  String get serverActivityTitle => 'Actividad del servidor';

  @override
  String get serverActivityStarting => 'Iniciando el servidor local…';

  @override
  String get serverActivityConnecting => 'Conectando con el servidor…';

  @override
  String get serverActivityStartFailed => 'No se pudo iniciar el servidor';

  @override
  String get serverActivityDownloadFailed => 'No se pudo descargar';

  @override
  String get serverActivityStatusUnavailable =>
      'No se pudo consultar el estado del modelo';

  @override
  String get serverActivityPreparingModel => 'Preparando el modelo…';

  @override
  String get serverActivityPortInUse =>
      'El puerto del servidor ya está en uso. Detén el otro proceso o elige otro puerto en el servidor.';

  @override
  String get serverActivityStartFailedHint =>
      'Consulta los detalles técnicos y vuelve a intentarlo desde la configuración del servidor.';

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
  String get calendarJoinMeet => 'Unirse a la reunión';

  @override
  String get calendarJoinAndRecord => 'Unirse y grabar';

  @override
  String get calendarRecordFailed => 'No se pudo iniciar la grabación';

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
  String get calendarNewEvent => 'Nuevo evento';

  @override
  String get calendarComposerTitleHint => 'Añade un título';

  @override
  String get calendarComposerStarts => 'Inicio';

  @override
  String get calendarComposerEnds => 'Fin';

  @override
  String get calendarComposerDate => 'Fecha';

  @override
  String get calendarComposerEndDate => 'Último día';

  @override
  String get calendarComposerGuestsHint =>
      'Añade invitados por correo electrónico';

  @override
  String get calendarComposerMeet => 'Añade un enlace de Google Meet';

  @override
  String get calendarComposerLocationHint => 'Añade una ubicación';

  @override
  String get calendarComposerDescriptionHint => 'Añade una descripción';

  @override
  String get calendarComposerCalendar => 'Calendario';

  @override
  String get calendarComposerTitleRequired =>
      'Añade un título para guardar el evento';

  @override
  String get calendarComposerInvalidGuests =>
      'Una de las direcciones de correo de los invitados no es válida';

  @override
  String get calendarComposerEndBeforeStart =>
      'El evento debe terminar después de empezar';

  @override
  String get calendarComposerSaveFailed =>
      'No se pudo crear el evento. Inténtalo de nuevo.';

  @override
  String get calendarComposerGuestsNotified =>
      'Los invitados reciben una invitación por correo de Google.';

  @override
  String get calendarDeleteEvent => 'Eliminar evento';

  @override
  String calendarDeleteConfirmTitle(String title) {
    return '¿Eliminar «$title»?';
  }

  @override
  String get calendarDeleteConfirmBody => 'Se elimina de Google Calendar.';

  @override
  String get calendarDeleteConfirmGuests =>
      'Se elimina de Google Calendar y se avisa a todos los invitados de que se ha cancelado.';

  @override
  String get calendarDeleteConfirmInvite =>
      'Solo se elimina de tu calendario. El organizador y los demás invitados lo mantienen.';

  @override
  String get calendarDeleteConfirmRecurring =>
      'Solo se elimina esta repetición; el resto de la serie se mantiene.';

  @override
  String get calendarDeleteFailed =>
      'No se pudo eliminar el evento. Inténtalo de nuevo.';

  @override
  String get calendarMoveFailed =>
      'No se pudo mover el evento. Volvió a su lugar original.';

  @override
  String get activityCreatedCalendarEvent => 'Creó un evento de calendario';

  @override
  String get activityMovedCalendarEvent => 'Movió un evento de calendario';

  @override
  String get activityDeletedCalendarEvent => 'Eliminó un evento de calendario';

  @override
  String get calendarAddAccount => 'Añadir cuenta de calendario';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Conecta una cuenta de Google para sincronizar eventos en este espacio de trabajo. Estos calendarios son tuyos aquí.';

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
  String get remoteControlAndDevices => 'Control remoto y dispositivos';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'Empareja teléfonos y configura el servidor de control remoto.';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'Los modelos de voz y diarización que aloja este servidor.';

  @override
  String get needsSetupLabel => 'Requiere configuración';

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
  String get usageAnalyticsTitle => 'Compartir analíticas de uso';

  @override
  String get usageAnalyticsOnSubtitle =>
      'Todos los clientes de este servidor envían eventos de uso seudonimizados (pantallas, acciones, recuentos), solo en versiones de producción. Nunca nombres, contenido de mensajes, rutas de archivos ni direcciones de correo.';

  @override
  String get usageAnalyticsOffSubtitle =>
      'Las analíticas de uso están desactivadas. Ningún cliente de este servidor envía eventos de uso.';

  @override
  String get usageAnalyticsManagedOnSubtitle =>
      'Los clientes de este servidor envían eventos de uso seudonimizados. Solo el operador del servidor puede cambiarlo.';

  @override
  String get usageAnalyticsManagedOffSubtitle =>
      'Las analíticas de uso están desactivadas en este servidor. Solo el operador del servidor puede cambiarlo.';

  @override
  String get onboardingUsageAnalyticsSubtitle =>
      'Envía eventos de uso seudonimizados desde todos los clientes de este servidor para que sepamos qué funciones ayudan (solo en versiones de producción). Nunca nombres, contenido de mensajes, rutas de archivos ni direcciones de correo. Puedes cambiar esto en cualquier momento en Ajustes → Privacidad.';

  @override
  String get blocked => 'Bloqueado';

  @override
  String get idle => 'Inactivo';

  @override
  String get noRunsYet => 'Sin ejecuciones';

  @override
  String get copyPath => 'Copiar ruta';

  @override
  String get copyRelativePath => 'Copiar ruta relativa';

  @override
  String get nameRequired => 'El nombre es obligatorio';

  @override
  String get import => 'Importar';

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
  String get nodeConfigBackupRetentionDays =>
      'Eliminar copias anteriores a (días)';

  @override
  String get nodeConfigBackupRetentionDaysHelp =>
      'Solo se eliminan las copias de este espacio de trabajo. Introduce un número positivo de días.';

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
  String get activityRespondedToInvitation =>
      'Respondió a la invitación del evento';

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
  String conversationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conversaciones',
      one: '1 conversación',
    );
    return '$_temp0';
  }

  @override
  String agentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agentes',
      one: '1 agente',
    );
    return '$_temp0';
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
  String get articleNoun => 'Artículo';

  @override
  String get articlesSubscribed => 'Artículos de tus fuentes suscritas.';

  @override
  String get askAi => 'Ask AI';

  @override
  String get askAiReviewDescription => 'Pedir a la IA que revise esta PR';

  @override
  String get assignees => 'Asignados';

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
  String get bugLabel => 'Bug';

  @override
  String get bundledDefaultsNeverUpdated =>
      'Predefinidos incluidos - nunca actualizados';

  @override
  String get cancel => 'Cancelar';

  @override
  String get cancelEdit => 'Cancelar edición';

  @override
  String get categoryNavigation => 'Navegación';

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
  String typeToConfirmPrompt(String value) {
    return 'Escribe $value para confirmar.';
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
  String get detailsLabel => 'Detalles';

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
  String get revertToThere => 'Volver allí';

  @override
  String get sendAsNewMessage => 'Enviar como mensaje nuevo';

  @override
  String get editMessageChoiceBody =>
      'Volver oculta los mensajes posteriores y revierte los archivos del agente. Puedes deshacerlo. Enviarlo como mensaje nuevo deja la conversación como está.';

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
  String get egPlatform => 'ej: Platform';

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
  String serviceStatusOverflowCount(int count) {
    return '$count+';
  }

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
  String get sidebarAgeNow => 'ahora';

  @override
  String sidebarAgeMinutes(int count) {
    return '$count min';
  }

  @override
  String sidebarAgeHours(int count) {
    return '$count h';
  }

  @override
  String sidebarAgeDays(int count) {
    return '$count d';
  }

  @override
  String sidebarAgeMonths(int count) {
    return '$count mes';
  }

  @override
  String sidebarAgeYears(int count) {
    return '$count a';
  }

  @override
  String get images => 'Imágenes';

  @override
  String get inactive => 'Inactivo';

  @override
  String get install => 'Instalar';

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
  String get keybindingAddRepository => 'Añadir repositorio';

  @override
  String get keybindingCommandPalette => 'Paleta de comandos';

  @override
  String get keybindingFocusSearch => 'Enfocar búsqueda';

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
  String get keybindingOpenPr => 'Abrir PR';

  @override
  String get keybindingOpenSettings => 'Abrir ajustes';

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
  String get keybindingSendMessage => 'Enviar mensaje';

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
  String get killRunning => 'Detener en ejecución';

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
  String get exitSettings => 'Salir de ajustes';

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
  String get noSystemFonts => 'No se detectaron fuentes del sistema.';

  @override
  String get noWorkingMemory => 'Aún no hay notas de memoria de trabajo.';

  @override
  String get noneAllRoles => 'Ninguno (todos los roles)';

  @override
  String get notAvailable => 'No disponible';

  @override
  String get notConfiguredLabel => 'No configurado.';

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
      'Notificar cuando te mencionen en un espacio.';

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
  String get notificationSectionSound => 'Sonido';

  @override
  String get notificationSectionSchedule => 'Programación';

  @override
  String get notificationSectionEvents => 'Eventos';

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
  String get onboardingLinuxDescription =>
      'Control Center puede usar contenedores Linux para aislar la ejecución de agentes.';

  @override
  String get onboardingMacosDescription =>
      'Control Center utiliza sandbox nativo en macOS para aislar la ejecución de agentes.';

  @override
  String get onboardingUnsupportedDescription =>
      'Sandbox no disponible en esta plataforma. La ejecución de agentes será sin aislamiento.';

  @override
  String get openArticlesInApp => 'Abrir artículos en la app';

  @override
  String get openInBrowser => 'Abrir en el navegador';

  @override
  String get openedInYourBrowser => 'Abierto en tu navegador.';

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
  String get questionLabel => 'Pregunta';

  @override
  String get queued => 'En cola';

  @override
  String get react => 'Reaccionar';

  @override
  String get readerPreferences => 'Preferencias del lector';

  @override
  String get reasoningEffort => 'Esfuerzo de razonamiento';

  @override
  String get recommendLabel => 'Recomendar';

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
  String get reviewers => 'Revisores';

  @override
  String get roleLabel => 'Rol';

  @override
  String get ruleHint => 'La regla de la política (markdown soportado)';

  @override
  String get ruleLabel => 'Regla';

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
  String get savingEllipsis => 'Guardando…';

  @override
  String get scopeDiffToCommits =>
      'Filtrar diff por commits — Mayús-clic para rango';

  @override
  String get noPrsMatchSearch => 'No hay pull requests coincidentes';

  @override
  String get searchFactsHint => 'Buscar hechos...';

  @override
  String get searchFonts => 'Buscar fuentes…';

  @override
  String get searchGifs => 'Buscar GIFs';

  @override
  String get searchGifsHint => 'Buscar en KLIPY';

  @override
  String get searchInDiffHint => 'Buscar en diff...';

  @override
  String get searchOrTypeModel => 'Busca o escribe un nombre de modelo…';

  @override
  String get searchPlaceholder => 'Buscar...';

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
  String get settingsLabel => 'Ajustes';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageDescription =>
      'Elegir el idioma de la aplicación.';

  @override
  String get showNativeNotifications =>
      'Mostrar notificaciones del sistema para eventos.';

  @override
  String get showSuperseded => 'Mostrar sustituidos';

  @override
  String get signedIn => 'Sesión iniciada.';

  @override
  String signedInAs(String username) {
    return 'Sesión iniciada como $username.';
  }

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
  String get suggestion => 'Sugerencia';

  @override
  String get suggestLabel => 'Sugerir';

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
  String get ticketLabel => 'Ticket';

  @override
  String get titleLabel => 'Título';

  @override
  String get todayLabel => 'Hoy';

  @override
  String get toggleTheme => 'Cambiar tema';

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
  String get mergeMethod => 'Método de fusión';

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
  String get confirm => 'Confirmar';

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
  String get pipelineTemplateBuiltInBadge => 'Integrada';

  @override
  String get pipelineTemplateDeleteConfirmTitle => '¿Eliminar plantilla?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return '¿Eliminar la plantilla de pipeline $name? Esta acción no se puede deshacer.';
  }

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
  String get editorEmptyCanvas =>
      'Arrastra un nodo desde la biblioteca para empezar.';

  @override
  String get pipelineWhenThisHappens => 'Cuando ocurra esto';

  @override
  String get pipelineDoThis => 'Hacer esto';

  @override
  String get pipelineAddStep => 'Añadir paso';

  @override
  String get pipelineTidyUp => 'Ordenar el diseño';

  @override
  String get pipelineEditorHint =>
      'Arrastra los pasos para ordenarlos · arrastra un controlador para conectar';

  @override
  String get pipelineRemoveConnection => 'Quitar conexión';

  @override
  String get pipelineDragToConnect => 'Arrastra para conectar';

  @override
  String get pipelineNewDefaultName => 'Nuevo pipeline';

  @override
  String get nodeCategoryTriggers => 'Disparadores';

  @override
  String get triggerEventWebhook => 'Webhook';

  @override
  String get pipelineAddTrigger => 'Añadir un disparador';

  @override
  String get pipelineOnEvent => 'Por evento';

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
      'Se ejecuta con bash -c en el sandbox del sistema operativo. GH_TOKEN y GITHUB_TOKEN contienen un token de solo lectura para el repositorio vinculado. Los placeholders se entrecomillan y se sustituyen antes de ejecutar.';

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
  String get triggerManualHelp =>
      'Mostrar en la página de ejecución e iniciar a mano.';

  @override
  String get triggerKindSchedule => 'Según una programación';

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
  String get triggerWebhookPathLabel => 'Ruta del webhook';

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
  String get ticketingApiKey => 'Clave de API de tickets';

  @override
  String get ticketingProvider => 'Proveedor de tickets';

  @override
  String get connectGitHubAndTicketing =>
      'Conecta un alojamiento de código para que Control Center pueda leer tus pull requests, incidencias y revisiones. Conecta opcionalmente un proveedor de tickets. Las credenciales las guarda tu servidor, nunca esta máquina.';

  @override
  String get triggerEventTicketAssigned => 'Ticket asignado';

  @override
  String get triggerEventTicketCreated => 'Ticket creado';

  @override
  String get triggerEventTicketStatusChanged => 'Estado del ticket cambiado';

  @override
  String get triggerEventMeetingRecordingStopped =>
      'Grabación de la reunión detenida';

  @override
  String get triggerEventSkillUpdated => 'Habilidad actualizada';

  @override
  String get triggerEventSpaceDeleted => 'Espacio eliminado';

  @override
  String get triggerEventSpaceArchived => 'Espacio archivado';

  @override
  String get triggerEventSpaceProvisioningChanged =>
      'Aprovisionamiento del espacio cambiado';

  @override
  String get triggerEventPrHeadChanged => 'Head de la PR cambiado';

  @override
  String get triggerEventEnvironmentStatusChanged =>
      'Estado del entorno cambiado';

  @override
  String get triggerEventEnvironmentReady => 'Entorno listo';

  @override
  String get triggerEventEnvironmentDestroyed => 'Entorno destruido';

  @override
  String get triggerEventEnvironmentProcessExited =>
      'Proceso del entorno finalizado';

  @override
  String get triggerExternalPrHelp =>
      'Una pull request abierta en el anfitrión de código, no desde Control Center.';

  @override
  String get triggerPrPublishedHelp =>
      'Una pull request abierta desde Control Center o por un agente.';

  @override
  String get triggerPrStatusChangedHelp =>
      'Fusionada, cerrada, abierta, reabierta o aprobada. Filtra por estado en el inspector.';

  @override
  String get triggerPrMergedHelp =>
      'Solo cuando la pull request se fusiona, no al cerrarla o reabrirla.';

  @override
  String get triggerRepoAddedHelp =>
      'Se vincula un repositorio a este espacio de trabajo.';

  @override
  String get triggerCodeGraphWatchHelp =>
      'Un archivo de un repositorio vinculado cambia en disco.';

  @override
  String get triggerMessageReceivedHelp =>
      'Llega un mensaje nuevo a un espacio.';

  @override
  String get triggerTicketCreatedHelp =>
      'Se crea un ticket en este espacio de trabajo.';

  @override
  String get triggerTicketStatusChangedHelp => 'Un ticket cambia de estado.';

  @override
  String get triggerTicketCompletedHelp => 'Un ticket termina correctamente.';

  @override
  String get triggerTicketFailedHelp =>
      'Una ejecución del agente falló y el ticket se marca como fallido.';

  @override
  String get triggerTicketCancelledHelp =>
      'Se cancela un ticket y no continuará.';

  @override
  String get triggerBudgetCrossedHelp =>
      'Se supera un límite de gasto del espacio de trabajo o del agente.';

  @override
  String get triggerTicketAssignedHelp =>
      'Se asigna un ticket a una persona, un agente o un equipo.';

  @override
  String get triggerMeetingRecordingStoppedHelp =>
      'Termina la grabación de una reunión.';

  @override
  String get triggerSkillUpdatedHelp => 'Se instala o actualiza una habilidad.';

  @override
  String get triggerSpaceDeletedHelp =>
      'Se elimina un espacio de conversación.';

  @override
  String get triggerSpaceArchivedHelp =>
      'Se archiva un espacio de conversación.';

  @override
  String get triggerSpaceProvisioningChangedHelp =>
      'El aprovisionamiento de los worktrees de un espacio empieza, termina o falla.';

  @override
  String get triggerPrHeadChangedHelp =>
      'Se envían nuevos commits a una pull request abierta.';

  @override
  String get triggerEnvironmentStatusChangedHelp =>
      'Un entorno de espacio pasa a un nuevo estado.';

  @override
  String get triggerEnvironmentReadyHelp =>
      'Un entorno de espacio se ha iniciado y se puede usar.';

  @override
  String get triggerEnvironmentDestroyedHelp =>
      'Se desmonta un entorno de espacio.';

  @override
  String get triggerEnvironmentProcessExitedHelp =>
      'Finaliza un proceso ejecutado por un entorno.';

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
  String get agentQuestionFreeformHint => 'Escribe tu respuesta…';

  @override
  String agentQuestionProgress(int index, int count) {
    return 'Pregunta $index de $count';
  }

  @override
  String get agentQuestionSkip => 'Omitir';

  @override
  String get agentQuestionSkippedLabel => 'Omitida';

  @override
  String get agentQuestionTimedOutLabel => 'Tiempo agotado';

  @override
  String get agentQuestionTimeLeft => 'Tiempo restante para responder';

  @override
  String get agentQuestionFreeformOptionHint => 'Descríbelo con tus palabras…';

  @override
  String get reviewRequested => 'Revisión solicitada';

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
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'las etiquetas',
      one: 'la etiqueta',
    );
    return '$actor añadió $_temp0 $labels';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'las etiquetas',
      one: 'la etiqueta',
    );
    return '$actor quitó $_temp0 $labels';
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
      other: 'las etiquetas',
      one: 'la etiqueta',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: 'las etiquetas',
      one: 'la etiqueta',
    );
    return '$actor añadió $_temp0 $added y quitó $_temp1 $removed';
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
  String get noChangesToReview => 'No hay cambios que revisar';

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
  String get imageDiffBefore => 'Antes';

  @override
  String get imageDiffAfter => 'Después';

  @override
  String get imageDiffModeTwoUp => 'Dos columnas';

  @override
  String get imageDiffModeSwipe => 'Deslizar';

  @override
  String get imageDiffModeDifference => 'Diferencia';

  @override
  String imageDiffChangedPercent(String percent) {
    return '$percent% cambiado';
  }

  @override
  String get imageDiffPictures => 'Imágenes';

  @override
  String get imageDiffSource => 'Fuente';

  @override
  String get imageDiffDeleted => 'Eliminado';

  @override
  String get imageDiffAdded => 'Añadido';

  @override
  String imageDiffDimensions(int width, int height) {
    return 'An.: ${width}px | Al.: ${height}px';
  }

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
  String get reRequestReview => 'Volver a solicitar revisión';

  @override
  String reRequestReviewFor(String label) {
    return 'Volver a solicitar revisión a $label';
  }

  @override
  String get addAssignees => 'Añadir asignados';

  @override
  String get addLabels => 'Añadir etiquetas';

  @override
  String get searchLabels => 'Buscar etiquetas…';

  @override
  String get noMatchingLabels => 'No hay etiquetas coincidentes';

  @override
  String removeLabel(String label) {
    return 'Quitar $label';
  }

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
  String failedToUpdateLabels(String error) {
    return 'No se pudieron actualizar las etiquetas: $error';
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
  String get meetingStatusPaused => 'En pausa';

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
  String get meetingsLiveOpen => 'Abrir la grabación';

  @override
  String get meetingTemplateShort => 'Plantilla';

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
  String get meetingNotesEmptyDescription =>
      'Genéralas a partir de la transcripción o escribe las tuyas.';

  @override
  String get meetingNotesGenerate => 'Generar notas';

  @override
  String get meetingNotesWriteOwn => 'Escribir las tuyas';

  @override
  String get meetingNothingTranscribed => 'No se transcribió nada.';

  @override
  String get meetingNothingTranscribedDescription =>
      'No hay transcripción que resumir, pero puedes seguir tomando tus propias notas.';

  @override
  String get meetingOverviewSpeakers => 'Participantes';

  @override
  String get meetingOverviewSpeakersEmpty =>
      'El tiempo de habla de cada participante aparece cuando hay una transcripción.';

  @override
  String meetingOverviewMoreSpeakers(int count) {
    return '+$count más';
  }

  @override
  String meetingOverviewSpeakerShare(
    String name,
    String share,
    String duration,
  ) {
    return '$name: $share del tiempo de habla, $duration';
  }

  @override
  String get meetingOverviewActionItemsAllDone =>
      'Todas las tareas están completadas.';

  @override
  String meetingOverviewViewAll(int count) {
    return 'Ver todas ($count)';
  }

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
  String ideReviewCodeInRepo(String repo) {
    return 'Revisar código ($repo)';
  }

  @override
  String get ideRevertConfirmTitle => 'Revertir cambios';

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
  String get mcpApprovalMode => 'Aprobación de herramientas';

  @override
  String get mcpApprovalModeDescription =>
      'Qué acciones de las herramientas propias de Control Center, llamadas a través de su endpoint MCP o por sus agentes, se ejecutan sin preguntar. Las lecturas siempre se permiten; los niveles superiores piden confirmación. Los servidores dentro de una ejecución siguen la política de acciones de esa ejecución.';

  @override
  String get mcpApprovalAlwaysAsk => 'Preguntar siempre';

  @override
  String get mcpApprovalWrite => 'Aprobar escrituras';

  @override
  String get mcpApprovalYolo => 'Aprobar todo';

  @override
  String get mcpReconnect => 'Reconectar';

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
  String subscriptionUsagePercentUsed(int percent) {
    return '$percent % usado';
  }

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
  String get noSpaceFoldersYet => 'Aún no hay carpetas';

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
  String get providerSignInExpired => 'Sesión caducada';

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
  String provisioningRunningTasks(String repo) {
    return 'Ejecutando tareas del worktree de $repo…';
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
  String get deviceAwaitingApproval => 'Pendiente de aprobación';

  @override
  String get profileSectionLabel => 'Perfil';

  @override
  String get profileSectionDescription =>
      'Cómo te ven el equipo y la autoría de commits git en este espacio. Los campos vacíos heredan el nombre y el correo de tu cuenta.';

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
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
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
  String get reactionThumbsUp => 'Pulgar arriba';

  @override
  String get reactionThumbsDown => 'Pulgar abajo';

  @override
  String get reactionLaugh => 'Risa';

  @override
  String get reactionHooray => 'Celebración';

  @override
  String get reactionConfused => 'Confusión';

  @override
  String get reactionHeart => 'Corazón';

  @override
  String get reactionRocket => 'Cohete';

  @override
  String get reactionEyes => 'Ojos';

  @override
  String get commentReact => 'Reaccionar';

  @override
  String get commentResolveThread => 'Resolver hilo';

  @override
  String get commentReopenThread => 'Reabrir hilo';

  @override
  String get commentCopyLink => 'Copiar enlace al comentario';

  @override
  String get commentCopyMarkdown => 'Copiar como Markdown';

  @override
  String get commentCopyThreadMarkdown => 'Copiar hilo como Markdown';

  @override
  String get commentCopyPrompt => 'Copiar como prompt';

  @override
  String get commentCopyThreadPrompt => 'Copiar hilo como prompt';

  @override
  String get commentSendToAgent => 'Enviar al agente';

  @override
  String get commentDelete => 'Eliminar comentario';

  @override
  String get commentEdit => 'Editar comentario';

  @override
  String get commentActions => 'Acciones del comentario';

  @override
  String get commentDeleteTitle => '¿Eliminar este comentario?';

  @override
  String get commentDeleteBody => 'Se quita de la pull request.';

  @override
  String get commentSentToAgent => 'Enviado al agente';

  @override
  String get commentSendFailed =>
      'No se pudo enviar este comentario a un agente';

  @override
  String get commentDeleteFailed => 'No se pudo eliminar este comentario';

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
  String get runPlaybookLabel => 'Ejecutar playbook';

  @override
  String get playbooksLabel => 'Playbooks';

  @override
  String get keybindingUndo => 'Deshacer';

  @override
  String get keybindingRedo => 'Rehacer';

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
  String get soundscapeMoodRise => 'Ascenso';

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
      'La ubicación proviene de este dispositivo.';

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
  String get scmSyncChanges => 'Sincronizar cambios';

  @override
  String get scmPublishBranch => 'Publicar rama';

  @override
  String get scmSyncFailed => 'Error al sincronizar';

  @override
  String get scmSyncDirty =>
      'Confirma o descarta los cambios antes de sincronizar';

  @override
  String get scmSynced => 'Sincronizado';

  @override
  String get scmPushRefused => 'El push fue rechazado';

  @override
  String get scmPulledPushRefused =>
      'Se trajeron los cambios, pero el push fue rechazado';

  @override
  String get scmPushRefusedHint =>
      'El remoto o un hook rechazó la actualización';

  @override
  String get scmSelectBranch => 'Seleccionar una rama para cambiar';

  @override
  String get scmCreateBranch => 'Crear rama nueva…';

  @override
  String get scmCreateBranchFrom => 'Crear rama nueva desde…';

  @override
  String get scmCheckoutDetached => 'Cambiar a HEAD separado…';

  @override
  String get scmBranchName => 'Nombre de la rama';

  @override
  String get scmCreateBranchTitle => 'Crear rama';

  @override
  String scmFromRef(String ref) {
    return 'Desde ⁨$ref⁩';
  }

  @override
  String get scmCheckoutFailed => 'No se pudo cambiar de rama';

  @override
  String get scmCheckoutDirty =>
      'Confirma o descarta los cambios antes de cambiar de rama';

  @override
  String scmSwitchedToBranch(String branch) {
    return 'Cambiado a ⁨$branch⁩';
  }

  @override
  String scmDetachedAt(String ref) {
    return 'Separado en ⁨$ref⁩';
  }

  @override
  String get scmDetachedHead => 'HEAD separado';

  @override
  String get scmNoBranches => 'Ninguna rama coincide';

  @override
  String get scmBranches => 'Ramas';

  @override
  String get scmRemoteBranches => 'Ramas remotas';

  @override
  String get scmTags => 'Etiquetas';

  @override
  String get scmPickStartPoint => 'Seleccionar un punto de inicio';

  @override
  String get scmSwitchBranch => 'Cambiar de rama';

  @override
  String get scmPullConflictTitle => 'La descarga provocaría un conflicto';

  @override
  String scmPullConflictBody(int count, String branch) {
    return 'Traer $count commits a ⁨$branch⁩ entraría en conflicto con el trabajo de esta copia.';
  }

  @override
  String get scmAskAi => 'Pedir a la IA';

  @override
  String scmResolveConflictPrompt(String branch, String repo, int count) {
    return 'Trae ⁨$branch⁩ en ⁨$repo⁩. Está $count commits por detrás de su upstream y la descarga entra en conflicto con el trabajo local. Resuelve los conflictos y termina la descarga.';
  }

  @override
  String commitMessageOnBranch(String shortcut, String branch) {
    return 'Mensaje ($shortcut para confirmar en “$branch”)';
  }

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
  String get regexTesterTitle => 'Probar expresión regular';

  @override
  String get regexTesterHint => 'Escribe un ejemplo';

  @override
  String get regexMatch => 'Coincidencia';

  @override
  String get regexNoMatch => 'Sin coincidencia';

  @override
  String get regexInvalidPattern => 'Patrón no válido';

  @override
  String get symbolLookupNone =>
      'No hay una definición en el índice ni en esta solicitud de extracción';

  @override
  String get symbolLookupInDiff => 'Encontrado en esta solicitud de extracción';

  @override
  String get symbolLookupFromBase =>
      'Del checkout base: el worktree de este PR aún no está indexado';

  @override
  String get symbolImplementations => 'Implementaciones';

  @override
  String symbolCallersCount(int count) {
    return '$count llamadores';
  }

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
  String get searchInWholeRepo => 'Buscar en todo el repositorio';

  @override
  String get searchInThisPullRequest => 'Buscar en este pull request';

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
    return 'Menciona al bot en $provider para encargar algo a un agente, o crea borradores de tickets con $command.';
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
    return 'Envía este código al bot de $provider en un mensaje directo. Funciona una sola vez y caduca en 15 minutos.';
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
  String get settingsProfileDescription =>
      'Tu nombre, correo e identidad de git en este espacio de trabajo. Cambiar de espacio de trabajo cambia esta capa; tu nombre de usuario, inicio de sesión y dispositivos siguen en tu cuenta, en Tú → Perfil.';

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
      'Políticas y convenciones que comparten todas las personas de este espacio de trabajo.';

  @override
  String get settingsWorkspaceMeetingsDescription =>
      'Plantillas de notas y voces guardadas para las reuniones de este espacio de trabajo.';

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
  String get contentSynthesizerUnavailable =>
      'El agente Content synthesizer no existe o no tiene un runner que funcione';

  @override
  String get conversationNeedsAgent =>
      'Menciona un agente con @ para empezar esta conversación';

  @override
  String get conversationTitleGenerate => 'Generar';

  @override
  String get conversationTitleNoMessages =>
      'Envía un mensaje primero. El título se genera a partir de él.';

  @override
  String get conversationTitleGenerateFailed =>
      'No se pudo generar un título. Inténtalo de nuevo.';

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
  String get forgeSignInBannerTitle =>
      'El alojamiento de código no está conectado en este espacio de trabajo';

  @override
  String get forgeSignInBannerBody =>
      'Un inicio de sesión caducó o se revocó, o este espacio de trabajo usa su propia GitHub App. Las pull requests, las revisiones y la sincronización de repositorios están en pausa hasta que inicies sesión.';

  @override
  String get forgeSignInBannerAction => 'Iniciar sesión';

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
  String get providerApps => 'Aplicaciones de proveedor';

  @override
  String get providerAppsDescription =>
      'Apps que este servidor registró por su cuenta en cada proveedor. Las personas inician sesión a través de ellas, y el trabajo en segundo plano como webhooks, sondeo y sincronización se ejecuta en ellas, nunca en el inicio de sesión de una persona.';

  @override
  String get providerAppId => 'Id de la app';

  @override
  String get providerPrivateKey => 'Clave privada';

  @override
  String get providerClientId => 'Id de cliente';

  @override
  String get providerClientSecret => 'Secreto de cliente';

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
  String get contextSegmentRunner =>
      'Prompt del ejecutor, herramientas y trabajo del turno';

  @override
  String get contextUsageMeasured =>
      'Informado por la última llamada al modelo';

  @override
  String get contextUsageEstimated =>
      'Estimado hasta que una ejecución informe el uso';

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
  String get settingsStateFailed => 'Error';

  @override
  String get providerAppsGroupServer => 'Actuar como el servidor';

  @override
  String get providerAppsGroupServerDescription =>
      'Lo usan los espacios de trabajo que siguen las apps de inicio de sesión de este servidor. Un espacio de trabajo con sus propias apps configura su App en Espacio de trabajo → Integraciones.';

  @override
  String get providerAppsGroupPrConversations =>
      'Conversaciones de pull request';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'Cómo pueden hablar con este servidor en GitHub los desarrolladores de los espacios de trabajo que siguen a este servidor. Un espacio de trabajo con sus propias apps tiene su propio bot en Espacio de trabajo → Integraciones. Funciona sin webhook ni URL pública: el servidor hace sondeos.';

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
  String get guardrailFamilyCommands => 'Comandos';

  @override
  String get guardrailStandingApproval => 'Aprobación temporal';

  @override
  String guardrailEntryAllow(String what) {
    return 'Permitido: $what';
  }

  @override
  String guardrailEntryPrompt(String what) {
    return 'Preguntar primero: $what';
  }

  @override
  String guardrailEntryDeny(String what) {
    return 'Denegado: $what';
  }

  @override
  String guardrailCoversBranches(String patterns) {
    return 'ramas $patterns';
  }

  @override
  String guardrailCoversPaths(String patterns) {
    return 'rutas $patterns';
  }

  @override
  String guardrailCoversHosts(String patterns) {
    return 'hosts $patterns';
  }

  @override
  String guardrailCoversCommands(String patterns) {
    return 'comandos $patterns';
  }

  @override
  String guardrailCoversTools(String names) {
    return 'herramientas $names';
  }

  @override
  String guardrailCoversCommandPrefix(String prefix) {
    return 'comandos que empiezan por $prefix';
  }

  @override
  String guardrailCoversMaxCount(String count) {
    return 'como máximo $count a la vez';
  }

  @override
  String guardrailCoversMaxCents(String amount) {
    return 'como máximo $amount céntimos';
  }

  @override
  String get guardrailCoversEverything => 'toda acción de este tipo';

  @override
  String guardrailEntryGivenBy(String name) {
    return 'por $name';
  }

  @override
  String guardrailEntryEnds(String time) {
    return 'termina $time';
  }

  @override
  String get guardrailEntryNoEnd => 'hasta revocarla';

  @override
  String guardrailRevokeEntry(String entry) {
    return 'Revocar: $entry';
  }

  @override
  String get guardrailRevokeFailed => 'No se pudo revocar. Inténtalo de nuevo.';

  @override
  String get guardrailEntryInactive => 'sin efecto mientras esté en Denegar';

  @override
  String guardrailClassPartlyAllowed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Permitida en $count casos listados abajo',
      one: 'Permitida en 1 caso listado abajo',
    );
    return '$_temp0';
  }

  @override
  String guardrailStandingFromWorkspace(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count aprobaciones temporales para todo el espacio de trabajo también se aplican aquí.',
      one:
          '1 aprobación temporal para todo el espacio de trabajo también se aplica aquí.',
    );
    return '$_temp0';
  }

  @override
  String guardrailStandingInNarrowerScopes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count aprobaciones temporales están definidas para espacios o agentes concretos. Elige Espacio o Agente arriba para verlas.',
      one:
          '1 aprobación temporal está definida para un único espacio o agente. Elige Espacio o Agente arriba para verla.',
    );
    return '$_temp0';
  }

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
  String get sandboxGroupAgentActions => 'Qué pueden hacer los agentes';

  @override
  String get sandboxGroupAgentActionsDescription =>
      'Si enviar a un remoto, abrir una pull request y acceder a la red se permite, requiere preguntar o se deniega se define en los permisos de agentes.';

  @override
  String get sandboxBackendFieldDescription =>
      'El modo automático elige el más fuerte que admite este host. Fija uno para que no cambie por su cuenta.';

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
  String diffFileUnresolvedConversations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conversaciones sin resolver',
      one: '1 conversación sin resolver',
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
  String get commentModeAgent => 'Agente';

  @override
  String get commentModeComment => 'Comentario';

  @override
  String get commentModeReview => 'Revisión';

  @override
  String get commentDestination => 'Destino del comentario';

  @override
  String get commentHintAgent => 'Enviar al agente...';

  @override
  String get commentHintReview => 'Añadir a la revisión...';

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
  String failedToPostComment(String error) {
    return 'No se pudo publicar el comentario: $error';
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
  String get spaceAllPrsMerged =>
      'Se han fusionado todas las solicitudes de incorporación de este espacio. ¿Quieres archivarlo?';

  @override
  String get spaceKeepAfterMerge => 'No, conservar este espacio';

  @override
  String get spaceKeepAfterMergeHint =>
      'No volveremos a preguntarte por este espacio.';

  @override
  String get archiveSpace => 'Archivar espacio';

  @override
  String get archivedSpaces => 'Espacios archivados';

  @override
  String get archivedSpacesEmpty => 'No hay espacios archivados';

  @override
  String get restoreSpace => 'Restaurar';

  @override
  String get archivedConversations => 'Conversaciones archivadas';

  @override
  String get archivedConversationsEmpty => 'No hay conversaciones archivadas';

  @override
  String get restoreConversation => 'Restaurar';

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
  String get spaceActions => 'Acciones del espacio';

  @override
  String get conversationActions => 'Acciones de la conversación';

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
  String get newItemAction => 'Nuevo';

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
  String get composerAttachmentUploading => 'Subiendo…';

  @override
  String get composerAttachmentReady => 'Listo';

  @override
  String get composerAttachmentUploadFailed => 'Error al subir el archivo';

  @override
  String composerAttachmentTooLarge(String limit) {
    return 'El archivo supera el límite de $limit';
  }

  @override
  String get composerAttachmentUnreadable => 'No se pudo leer este archivo';

  @override
  String get composerAttachmentWaitForUploads =>
      'Espera a que terminen de subirse los adjuntos';

  @override
  String get composerAttachmentResolveFailures =>
      'Vuelve a intentar subir los adjuntos fallidos o elimínalos antes de enviar';

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
  String composerExpand(String shortcut) {
    return 'Ampliar el editor ($shortcut)';
  }

  @override
  String composerCollapse(String shortcut) {
    return 'Contraer el editor ($shortcut)';
  }

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
  String get steerForce => 'Detener y enviar';

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
  String get sandboxExecGrantsSearchHint => 'Buscar rutas';

  @override
  String get sandboxExecGrantsNoMatch =>
      'Ningún permiso coincide con tu búsqueda';

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
  String get demoUnavailablePipelines =>
      'Las canalizaciones no pueden ejecutarse aquí. Un visitante que pueda escribir un paso bash e iniciarlo — a mano o mediante un disparador de evento — está ejecutando código en este host.';

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
      'Todavía no hay instantáneas de la instalación. Crea una ahora o usa un pipeline programado para las copias del espacio de trabajo.';

  @override
  String get backupSnapshotComplete => 'Completa';

  @override
  String get backupDeleteSnapshotLabel => 'Eliminar instantánea';

  @override
  String get backupDeleteSnapshotDescription =>
      'Elimina esta instantánea del servidor de forma permanente. Descárgala antes si quieres conservarla.';

  @override
  String get backupDeleteSnapshotAction => 'Eliminar instantánea';

  @override
  String get backupDeleteSnapshotTitle => '¿Eliminar esta instantánea?';

  @override
  String backupDeleteSnapshotBody(String name) {
    return '¿Eliminar $name del servidor? Se perderán todas las bases de datos de esta instantánea. No se puede deshacer.';
  }

  @override
  String backupDeleteSnapshotDone(String name) {
    return 'Instantánea $name eliminada.';
  }

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
  String get backupScheduledLabel => 'Copias de seguridad programadas';

  @override
  String get backupScheduledExplainer =>
      'Copias guardadas por el pipeline de copia de cada espacio de trabajo. Define la programación y la retención en la plantilla del pipeline.';

  @override
  String get backupScheduledNone => 'Aún no hay copias de seguridad';

  @override
  String backupScheduledCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count copias de seguridad',
      one: '1 copia de seguridad',
    );
    return '$_temp0';
  }

  @override
  String backupScheduledLast(String time) {
    return 'Última copia: $time';
  }

  @override
  String get backupListForbidden =>
      'Necesitas el rol de administrador en este espacio de trabajo para ver sus copias.';

  @override
  String get backupScheduledDeleteTitle => '¿Eliminar esta copia de seguridad?';

  @override
  String backupScheduledDeleteBody(String date, String name) {
    return '¿Eliminar del servidor la copia del $date de $name? Esta acción no se puede deshacer.';
  }

  @override
  String get backupScheduledDeleteDone => 'Copia de seguridad eliminada.';

  @override
  String get backupScheduledWorkspaceDeleted => 'Espacio de trabajo eliminado';

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
      'Las transferencias de archivos aún no están configuradas para esta conexión. Vuelve a conectarte al servidor para descargar o subir una copia de seguridad.';

  @override
  String get backupTransferForbidden =>
      'El servidor lo rechazó. Descargar un espacio de trabajo requiere el rol de admin del espacio de trabajo. Restaurar uno requiere el propietario del servidor, que además debe ser propietario de ese espacio de trabajo. Una instantánea completa requiere el propietario del servidor.';

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

  @override
  String get credentialGateAccountsRemovedTitle =>
      'Se eliminaron las cuentas de Claude Code asignadas';

  @override
  String get credentialGateAccountsRemovedHint =>
      'Asigna otra cuenta en la configuración de cuentas de este agente o del espacio de trabajo, o vacía la lista para usar la predeterminada. La ejecución continuará sola.';

  @override
  String get accountPoolAllRemoved =>
      'Todas las cuentas de esta lista se eliminaron del servidor. Asigna otra o vacía la lista.';

  @override
  String get accountPoolClear => 'Vaciar la lista';

  @override
  String get selectModel => 'Seleccionar modelo';

  @override
  String get allModels => 'Todos los modelos';

  @override
  String get noModelsMatchSearch => 'Ningún modelo coincide con tu búsqueda';

  @override
  String useCustomModelId(String id) {
    return 'Usar “$id”';
  }

  @override
  String get modelFree => 'Gratis';

  @override
  String modelOutputTokens(String tokens) {
    return '$tokens de salida';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return '$input entrada / $output salida por 1M de tokens';
  }

  @override
  String modelEffortLevels(String levels) {
    return 'Esfuerzo de razonamiento: $levels';
  }

  @override
  String get modelSupportsReasoning => 'Admite esfuerzo de razonamiento';

  @override
  String get profileDeliveryMetrics => 'Métricas de entrega';

  @override
  String profileMetricsSample(int count) {
    return 'PR analizadas: $count';
  }

  @override
  String get profileMergeRate => 'Tasa de fusión';

  @override
  String get profileReviewCoverage => 'Cobertura de revisión';

  @override
  String get profilePrSize => 'Tamaño de PR';

  @override
  String get profileTimeToMerge => 'Tiempo hasta la fusión';

  @override
  String get profileMergeTimeTrend => 'Tendencia del tiempo de fusión';

  @override
  String get profileWeeklyMedian => 'Mediana semanal, escala logarítmica';

  @override
  String get profilePrOpeningPattern => 'Día de la semana × hora, hora local';

  @override
  String get profileFirstReview => 'Tiempo hasta la primera revisión';

  @override
  String get profileMetricsTruncated =>
      'Los percentiles se calculan a partir de una muestra limitada de las solicitudes de incorporación de cambios disponibles.';

  @override
  String profileLinesChanged(String count) {
    return '$count líneas';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count min';
  }

  @override
  String profileDurationHours(int count) {
    return '$count h';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '$days d $hours h';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return 'Miembros: $count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return 'No hay pull requests de $team en este espacio de trabajo';
  }

  @override
  String get profilePrStateFilterLabel => 'Filtrar pull requests por estado';

  @override
  String get noProfilePrsMatchSearchHint =>
      'Prueba con otro título o número de pull request';

  @override
  String get rigNetworkUnrestricted => 'Red sin restricciones';

  @override
  String get rigNetworkAllowAllHosts => 'Permitir todos los hosts';

  @override
  String get rigBrowserPermissionsTitle => 'Permisos del sitio';

  @override
  String get rigBrowserPermissionsTooltip => 'Permisos del sitio y red';

  @override
  String get rigBrowserPermissionEmpty =>
      'Ningún sitio ha pedido un permiso todavía';

  @override
  String rigBrowserPermissionPrompt(String origin, String permission) {
    return '$origin quiere usar $permission';
  }

  @override
  String get rigBrowserPermissionBlock => 'Bloquear';

  @override
  String get rigBrowserPermissionCamera => 'Cámara';

  @override
  String get rigBrowserPermissionMicrophone => 'Micrófono';

  @override
  String get rigBrowserPermissionNotifications => 'Notificaciones';

  @override
  String get rigBrowserPermissionGeolocation => 'Ubicación';

  @override
  String get rigBrowserPermissionPersistentStorage =>
      'Almacenamiento persistente';

  @override
  String get rigBrowserPermissionClipboard => 'Portapapeles';

  @override
  String get rigBrowserPermissionDisplayCapture => 'Captura de pantalla';

  @override
  String get rigBrowserPermissionMidi => 'MIDI';

  @override
  String get rigNetworkBypassTitle => '¿Permitir todos los hosts de red?';

  @override
  String get rigNetworkBypassBody =>
      'Esto reinicia el entorno aislado y descarta el trabajo sin confirmar que contenga. Después, el sistema invitado podrá acceder a cualquier host de red hasta que se cierre.';

  @override
  String get rigNetworkRestartUnrestricted => 'Reiniciar sin restricciones';

  @override
  String get rigNetworkUnrestrictedBody =>
      'Este entorno aislado puede acceder a cualquier host de red. Ciérralo y abre uno nuevo para restaurar las restricciones predeterminadas.';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      'Este emulador de Android ya administra su propia red, por lo que Control Center no puede aplicar una lista de hosts permitidos. No es necesario reiniciarlo.';

  @override
  String get rigClipboardPermissionHostToRigTitle =>
      '¿Pegar el portapapeles en este entorno?';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'Control Center leerá el portapapeles de tu dispositivo y enviará su contenido al entorno. El contenido del portapapeles puede incluir contraseñas u otros secretos.';

  @override
  String get rigClipboardPermissionRigToHostTitle =>
      '¿Copiar el portapapeles fuera de este entorno?';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'Control Center leerá el portapapeles del entorno y reemplazará el portapapeles de tu dispositivo con su contenido. Trata el contenido del entorno como no confiable.';

  @override
  String get rigClipboardAllowTenMinutes => 'Permitir durante 10 minutos';

  @override
  String get rigClipboardAlwaysAllow => 'Permitir siempre';

  @override
  String get rigClipboardSettingsTitle => 'Acceso al portapapeles';

  @override
  String get rigClipboardSettingsHint =>
      'Elige qué transferencias del portapapeles pueden ejecutarse sin preguntar. Los permisos temporales caducan después de 10 minutos.';

  @override
  String get rigClipboardAlwaysPasteTitle =>
      'Permitir siempre pegar en entornos';

  @override
  String get rigClipboardAlwaysPasteDescription =>
      'Enviar el portapapeles de este dispositivo a cualquier entorno sin preguntar.';

  @override
  String get rigClipboardAlwaysCopyTitle =>
      'Permitir siempre copiar desde entornos';

  @override
  String get rigClipboardAlwaysCopyDescription =>
      'Colocar contenido del portapapeles de cualquier entorno en este dispositivo sin preguntar.';

  @override
  String get profileOverlayHint =>
      'Estos campos eres tú en este espacio. Los vacíos heredan el nombre y el correo de tu cuenta. Cambiar de espacio cambia esta superposición.';

  @override
  String get stackStartNextPart => 'Empezar la siguiente parte';

  @override
  String get stackPartNameTitle => 'Nombre de la parte';

  @override
  String get stackPartNameHint => 'p. ej. migración';

  @override
  String get stackPublish => 'Publicar la pila';

  @override
  String get stackCurrentPart => 'Actual';

  @override
  String get stackSwitchDirty =>
      'Confirma o descarta los cambios antes de cambiar de parte';

  @override
  String get stackCutFailed => 'No se pudo empezar la siguiente parte';

  @override
  String get stackPublishFailed => 'No se pudo publicar la pila';

  @override
  String get stackPublished => 'La pila se publicó como borradores';

  @override
  String get stackOpenPullRequest => 'Abrir pull request';

  @override
  String get stackSection => 'Pila';

  @override
  String get mergeConflictsButton => 'Conflictos';

  @override
  String mergeConflictsFileCount(int count, String base) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos tienen conflictos con $base',
      one: '1 archivo tiene conflictos con $base',
    );
    return '$_temp0';
  }

  @override
  String get mergeConflictsLoading => 'Buscando los archivos en conflicto…';

  @override
  String get mergeConflictsLoadFailed =>
      'No se pudieron listar los archivos en conflicto';

  @override
  String get mergeConflictsNoneFound =>
      'No se encontraron archivos en conflicto. Puede que GitHub aún esté actualizando esta pull request.';

  @override
  String get askAiToFixConflicts => 'Pedir a la IA que resuelva los conflictos';

  @override
  String get fixConflictsStarted =>
      'Un agente está resolviendo los conflictos en el chat de esta pull request';

  @override
  String failedToStartConflictFix(String error) {
    return 'No se pudo iniciar la resolución de conflictos: $error';
  }

  @override
  String get settingsLinks => 'Enlaces';

  @override
  String get linksSettingsDescription =>
      'Elige dónde se abren los enlaces que llegan desde fuera de Control Center, como una pull request abierta desde GitHub.';

  @override
  String get repoLinkRememberedTitle => 'Espacios de trabajo recordados';

  @override
  String get repoLinkRememberedHint =>
      'Cuando un repositorio está vinculado a más de un espacio de trabajo, al abrir un enlace a él se te pregunta qué espacio de trabajo usar. Aquí aparecen las elecciones que pediste recordar.';

  @override
  String get repoLinkRememberedEmpty => 'Todavía no hay elecciones recordadas.';

  @override
  String get repoLinkForget => 'Olvidar';

  @override
  String get repoLinkWorkspaceUnavailable =>
      'El espacio de trabajo ya no está disponible';

  @override
  String get repoLinkWorkspaceDialogTitle => 'Elige un espacio de trabajo';

  @override
  String repoLinkWorkspaceDialogBody(String repo) {
    return '$repo está vinculado a más de un espacio de trabajo. ¿En cuál debe abrirse este enlace?';
  }

  @override
  String get repoLinkWorkspaceRemember =>
      'Recordar mi elección para este repositorio';

  @override
  String get repoLinkWorkspaceOpen => 'Abrir';

  @override
  String get repoLinkUnlinkedTitle =>
      'Añadir repositorio a un espacio de trabajo';

  @override
  String repoLinkUnlinkedBody(String repo) {
    return 'Ningún espacio de trabajo vincula $repo todavía. Añádelo a uno para abrir este enlace.';
  }

  @override
  String repoLinkUnlinkedAddTo(String workspace) {
    return 'Añadir a $workspace';
  }

  @override
  String get repoLinkUnlinkedAddToHint =>
      'Elige su copia local en el servidor.';

  @override
  String get repoLinkUnlinkedCreate => 'Nuevo espacio de trabajo';

  @override
  String get repoLinkUnlinkedCreateHint =>
      'Ponle nombre y luego elige la copia local.';

  @override
  String repoLinkChooseCheckout(String repo) {
    return 'Selecciona la copia local de $repo en la máquina que ejecuta el servidor.';
  }

  @override
  String repoLinkCheckoutMismatch(String repo) {
    return 'Ninguno de los repositorios añadidos es $repo, así que el enlace se abrió sin él.';
  }

  @override
  String get windowMinimize => 'Minimizar';

  @override
  String get windowMaximize => 'Maximizar';

  @override
  String get windowRestore => 'Restaurar';

  @override
  String nativeSandboxUnsupported(String platform) {
    return 'El sandbox nativo aún no es compatible con $platform.';
  }

  @override
  String get continueWithoutSandbox => 'Continuar sin sandbox';

  @override
  String get sandboxCheckAgain => 'Comprobar de nuevo';

  @override
  String get ideQuickOpen => 'Ir al archivo';

  @override
  String get ideQuickOpenHint => 'Buscar archivos por nombre';

  @override
  String get ideQuickOpenRecentlyOpened => 'Abierto recientemente';

  @override
  String get ideQuickOpenOpenToSide => 'Abrir en el lateral';

  @override
  String get ideQuickOpenRemoveRecent => 'Quitar de abiertos recientemente';

  @override
  String get ideQuickOpenNoRecent => 'No hay archivos abiertos recientemente';

  @override
  String get diffMarkFileViewed => 'Marcar como visto';

  @override
  String get diffMarkFileNotViewed => 'Marcar como no visto';

  @override
  String diffAdditionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count adiciones',
      one: '1 adición',
    );
    return '$_temp0';
  }

  @override
  String diffDeletionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eliminaciones',
      one: '1 eliminación',
    );
    return '$_temp0';
  }

  @override
  String diffFileSemantics(
    String path,
    String status,
    String additions,
    String deletions,
  ) {
    return '$path, $status, $additions, $deletions';
  }

  @override
  String diffFileSemanticsViewed(
    String path,
    String status,
    String additions,
    String deletions,
  ) {
    return '$path, $status, $additions, $deletions, visto';
  }

  @override
  String diffFileRenamedFrom(String previous) {
    return 'renombrado desde $previous';
  }

  @override
  String diffTreeFolderSemantics(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos',
      one: '1 archivo',
    );
    return '$name, carpeta, $_temp0';
  }

  @override
  String diffTreeFileSemantics(String name, String status) {
    return '$name, $status';
  }

  @override
  String diffTreeFileSemanticsViewed(String name, String status) {
    return '$name, $status, visto';
  }

  @override
  String diffLineAdded(int line, String code) {
    return 'Línea añadida $line: $code';
  }

  @override
  String diffLineRemoved(int line, String code) {
    return 'Línea eliminada $line: $code';
  }

  @override
  String diffLineContext(int line, String code) {
    return 'Línea $line: $code';
  }

  @override
  String diffLineHunk(String header) {
    return 'Bloque $header';
  }

  @override
  String get diffLineBlank => 'vacía';

  @override
  String get diffCommentOnLineAction => 'Comentar esta línea';

  @override
  String diffFileMarkedViewedAnnouncement(String path) {
    return '$path marcado como visto';
  }

  @override
  String diffFileMarkedNotViewedAnnouncement(String path) {
    return '$path marcado como no visto';
  }

  @override
  String prLineChangesSemantics(int additions, int deletions) {
    return 'Líneas añadidas: $additions, líneas eliminadas: $deletions';
  }

  @override
  String closeTabNamed(String tab) {
    return 'Cerrar $tab';
  }

  @override
  String get notificationAgentAwaitingInput => 'Un agente necesita tu atención';

  @override
  String get notifyAgentAwaitingInput =>
      'Cuando un agente necesita aprobación, una respuesta o credenciales válidas, o una política bloquea una acción';

  @override
  String notificationAgentNeedsApproval(String agent) {
    return '$agent necesita tu aprobación';
  }

  @override
  String get notificationAgentNeedsApprovalUnnamed =>
      'Un agente necesita tu aprobación';

  @override
  String notificationAgentAskedQuestion(String agent) {
    return '$agent tiene una pregunta';
  }

  @override
  String get notificationAgentAskedQuestionUnnamed =>
      'Un agente tiene una pregunta';

  @override
  String notificationAgentBlockedOnCredential(String agent) {
    return '$agent está bloqueado por una credencial';
  }

  @override
  String get notificationAgentBlockedOnCredentialUnnamed =>
      'Un agente está bloqueado por una credencial';

  @override
  String notificationWaitReminder(String title) {
    return 'Sigue esperando: $title';
  }

  @override
  String get killTerminal => 'Cerrar terminal';

  @override
  String get stopAgentCommand => 'Detener comando';

  @override
  String get agentCommandStopping => 'Deteniendo…';

  @override
  String sidebarAgeSeconds(int count) {
    return '$count s';
  }

  @override
  String agentCommandSemantics(String command, String elapsed) {
    return 'Comando del agente $command, en ejecución desde hace $elapsed';
  }

  @override
  String get serverLostTitle => 'Se perdió la conexión con el servidor';

  @override
  String get serverLostBody =>
      'Control Center sigue intentando reconectarse en segundo plano. Vuelve a intentarlo ahora o ve a la pantalla de inicio de sesión para elegir un servidor.';

  @override
  String get serverLostRetrying => 'Reconectando…';

  @override
  String serverLostNextAttempt(int seconds) {
    return 'Próximo intento en $seconds s';
  }

  @override
  String get serverLostReconnect => 'Intentar reconectar';

  @override
  String get serverLostSignIn => 'Ir al inicio de sesión';

  @override
  String get serverEndedTitle => 'No se puede reconectar con el servidor';

  @override
  String get shutdownSubtitleServer => 'El servidor se está deteniendo';

  @override
  String get skillEvalAbsent => 'Ausente vs. disponible';

  @override
  String get skillEvalAmbient => 'Habilidades disponibles';

  @override
  String skillEvalArtifactRef(String reference) {
    return 'Referencia del artefacto: $reference';
  }

  @override
  String skillEvalAttempt(String task, String arm, int repeat) {
    final intl.NumberFormat repeatNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String repeatString = repeatNumberFormat.format(repeat);

    return '$task · $arm · repetición $repeatString';
  }

  @override
  String get skillEvalAttempts => 'Intentos';

  @override
  String get skillEvalAvailableEvent => 'Disponible';

  @override
  String get skillEvalBaseline => 'Hash de la revisión anterior';

  @override
  String get skillEvalBodyLoad => 'Contenido cargado';

  @override
  String get skillEvalBudgetCents => 'Presupuesto (centavos de US)';

  @override
  String get skillEvalBudgetNote =>
      'La evaluación de pago usa el proveedor y el presupuesto seleccionados. Los resultados del análisis de seguridad son independientes.';

  @override
  String get skillEvalUsageBudgetNote =>
      'Los presupuestos de suscripción miden el uso equivalente de la API, no las facturas. Una llamada en curso puede superar el presupuesto; al alcanzarlo, no se inician más llamadas. Los análisis de seguridad son independientes.';

  @override
  String get skillEvalCancel => 'Cancelar ejecución';

  @override
  String get skillEvalCancelled => 'Cancelado';

  @override
  String get skillEvalCancelling => 'Cancelando';

  @override
  String get skillEvalComparison => 'Comparación';

  @override
  String get skillEvalCompleted => 'Completado';

  @override
  String get skillEvalComposition => 'Composición';

  @override
  String get skillEvalCorpus => 'Conjunto de tareas';

  @override
  String skillEvalCoverage(String corpus, int repeats) {
    final intl.NumberFormat repeatsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String repeatsString = repeatsNumberFormat.format(repeats);

    return '$corpus · $repeatsString repeticiones';
  }

  @override
  String get skillEvalCoverageComplete =>
      'Se observaron todas las pruebas previstas';

  @override
  String skillEvalCurrentHash(String hash) {
    return 'Hash del paquete actual: $hash';
  }

  @override
  String get skillEvalDisableUpdates =>
      'Desactivar evaluaciones de actualizaciones';

  @override
  String get skillEvalEnableUpdates =>
      'Activar evaluaciones de actualizaciones';

  @override
  String get skillEvalExport => 'Copiar JSON anonimizado';

  @override
  String get skillEvalFailed => 'Fallido';

  @override
  String get skillEvalForced => 'Carga forzada vs. ausencia';

  @override
  String get skillEvalForcedEvent => 'Carga forzada';

  @override
  String get skillEvalHashLabel => 'Hash del paquete';

  @override
  String get skillEvalProgressLabel => 'Progreso';

  @override
  String get skillEvalUpdatesToggle => 'Evaluaciones de actualizaciones';

  @override
  String get skillEvalHashUnavailable =>
      'El hash del paquete no está disponible en este servidor. La evaluación está desactivada.';

  @override
  String get skillEvalHistory => 'Historial de revisiones';

  @override
  String get skillEvalImproved => 'Mejoró';

  @override
  String get skillEvalIncomplete => 'Incompleto';

  @override
  String get skillEvalInconclusive =>
      'Sin decisión (no hay pruebas suficientes)';

  @override
  String get skillEvalInferred => 'Inferido';

  @override
  String get skillEvalInterrupted => 'Interrumpido';

  @override
  String get skillEvalLoadUnobserved =>
      'No se puede observar la carga de la habilidad; la ausencia de un evento no demuestra que se haya ignorado.';

  @override
  String get skillEvalModel => 'Modelo seleccionado';

  @override
  String get skillEvalNoAttempts => 'Aún no hay intentos.';

  @override
  String get skillEvalNoModels =>
      'No hay modelos conectados disponibles. Conecta primero un proveedor en Configuración.';

  @override
  String get skillEvalNoPrevious =>
      'No hay un hash anterior en el historial de la campaña. Evalúa la revisión anterior antes de reemplazarla.';

  @override
  String get skillEvalNoReport =>
      'Aún no hay informe; los intentos parciales siguen disponibles.';

  @override
  String get skillEvalNoWorkspace =>
      'No hay ningún espacio de trabajo seleccionado.';

  @override
  String get skillEvalNoTasks => 'Aún no se han registrado tareas.';

  @override
  String get skillEvalNoVerifiers =>
      'No se registraron pruebas de verificación.';

  @override
  String get skillEvalNotEvaluated =>
      'No se ha evaluado esta versión exacta. Un análisis no demuestra su comportamiento.';

  @override
  String get skillEvalNotVerified => 'Sin verificar';

  @override
  String get skillEvalObserved => 'Observado';

  @override
  String get skillEvalOpenQuality => 'Abrir Calidad';

  @override
  String get skillEvalPolicyNote =>
      'De forma predeterminada, guardar una habilidad no inicia una evaluación de pago. Si activas expresamente la reevaluación automática al actualizar, guardar inicia una evaluación de pago sujeta al presupuesto.';

  @override
  String get skillEvalPolicyNeedsCampaign =>
      'Evalúa primero una revisión para configurar la política de actualizaciones.';

  @override
  String get skillEvalPolicyTemplate =>
      'Configuración de la política de actualizaciones';

  @override
  String get skillEvalPartial => 'Pruebas parciales; sin veredicto de adopción';

  @override
  String skillEvalProgress(int completed, int planned) {
    final intl.NumberFormat completedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String completedString = completedNumberFormat.format(completed);
    final intl.NumberFormat plannedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String plannedString = plannedNumberFormat.format(planned);

    return '$completedString de $plannedString intentos';
  }

  @override
  String skillEvalProvider(String provider) {
    return 'Proveedor: $provider';
  }

  @override
  String get skillEvalQualityIntro =>
      'Campañas de habilidades del espacio de trabajo y pruebas específicas de cada revisión.';

  @override
  String get skillEvalQueued => 'En cola';

  @override
  String get skillEvalReconnecting =>
      'Reconectando con las instantáneas de la campaña…';

  @override
  String get skillEvalRefresh => 'Actualizar';

  @override
  String get skillEvalReferenceLoad => 'Referencia cargada';

  @override
  String get skillEvalRepetitions => 'Repeticiones por tarea';

  @override
  String get skillEvalReport => 'Informe de pruebas';

  @override
  String get skillEvalRunning => 'En ejecución';

  @override
  String get skillEvalScriptExecution => 'Script ejecutado';

  @override
  String skillEvalSpend(String spent, String budget) {
    return 'Gasto: $spent / presupuesto $budget';
  }

  @override
  String get skillEvalStart => 'Iniciar evaluación';

  @override
  String get skillEvalStartTitle => 'Comparar revisiones de la habilidad';

  @override
  String get skillEvalStale => 'Desactualizado';

  @override
  String skillEvalStaleReason(String reason) {
    return 'Desactualizado: $reason';
  }

  @override
  String skillEvalTaskClusters(String count) {
    return 'Grupos de tareas distintos: $count';
  }

  @override
  String skillEvalTaskEvidence(String rate, String passes, String cost) {
    return '$rate ($passes verificados) · $cost';
  }

  @override
  String get skillEvalTasks => 'Tareas por grupo';

  @override
  String get skillEvalToolError => 'Error de herramienta';

  @override
  String get skillEvalTools => 'Eventos de herramientas';

  @override
  String get skillEvalTitle => 'Evaluación de habilidades';

  @override
  String skillEvalUnavailable(String reason) {
    return 'No disponible: $reason';
  }

  @override
  String get skillEvalUnknown => 'Desconocido';

  @override
  String get skillEvalUnsaved =>
      'Los cambios sin guardar no se incluyen. Guarda antes de evaluar.';

  @override
  String get skillEvalUncertainty => 'Intervalo de incertidumbre';

  @override
  String get skillEvalVerified => 'Verificado';

  @override
  String get skillEvalVerifiers => 'Verificación';

  @override
  String get skillEvalVerdict => 'Veredicto';

  @override
  String skillEvalExportCopied(String filename) {
    return 'Copia completada: $filename';
  }

  @override
  String get skillEvalPlanViolation => 'Incumplimiento del plan';

  @override
  String get skillEvalPreserved => 'Calidad conservada';

  @override
  String get skillEvalPrevious => 'Anterior vs. actual';

  @override
  String get skillEvalRegressed => 'Regresión demostrada';

  @override
  String get skillEvalCostRegression => 'Regresión de costos';

  @override
  String get skillEvalHarnessError => 'Error del entorno de pruebas';

  @override
  String get skillBehaviorRouting => 'Enrutamiento de la habilidad';

  @override
  String skillBehaviorRoutingCounts(
    String truePositive,
    String falsePositive,
    String falseNegative,
    String trueNegative,
  ) {
    return '$truePositive usos esperados · $falsePositive usos inesperados · $falseNegative usos omitidos · $trueNegative omisiones correctas';
  }

  @override
  String skillBehaviorUnknownCounts(
    String positive,
    String negative,
    String notOffered,
  ) {
    return '$positive usos inciertos · $negative omisiones inciertas · $notOffered no ofrecidas';
  }

  @override
  String skillBehaviorRoutingRates(
    String precision,
    String recall,
    String falsePositiveRate,
  ) {
    return 'Precisión observada $precision · exhaustividad $recall · tasa de falsos positivos $falsePositiveRate';
  }

  @override
  String get skillBehaviorForced => 'Grupo forzado · solo diagnóstico';

  @override
  String get skillBehaviorRoutingNote =>
      'Las tasas solo incluyen accesos observables. El acceso por shell o búsqueda puede quedar desconocido; cargar una habilidad no demuestra que se haya aplicado.';

  @override
  String get skillBehaviorSafety => 'Seguridad sintética';

  @override
  String skillBehaviorSafetyCounts(
    String passes,
    String attempts,
    String denials,
    String violations,
  ) {
    return '$passes/$attempts artefactos aprobados · $denials denegaciones por política · $violations infracciones de archivos protegidos';
  }

  @override
  String get skillBehaviorSafetyNote =>
      'Las comprobaciones de artefactos son sintéticas y no representan tasas de ataques en el mundo real; los efectos secundarios reales no se registran.';

  @override
  String get skillBehaviorUtility => 'Utilidad por familia';

  @override
  String skillBehaviorUtilityCounts(String verified, String attempts) {
    return '$verified/$attempts éxitos verificados';
  }

  @override
  String get skillBehaviorUtilityNote =>
      'Todos los intentos cuentan en el denominador de utilidad, incluidos los fallidos y los incompletos.';

  @override
  String get claudeAccountSignInFailed => 'Error al iniciar sesión';

  @override
  String get claudeSignInDialogTitle => 'Iniciar sesión en Claude Code';

  @override
  String get claudeSignInDialogHint =>
      'Ejecuta cada comando en una terminal del servidor. Abre un navegador para completar el inicio de sesión y guarda la credencial en el directorio de esa cuenta.';

  @override
  String get claudeSignInNoAccounts =>
      'Ninguna cuenta gestionada tiene la sesión cerrada. Si este agente usa el inicio de sesión propio de Claude Code, ejecuta:';

  @override
  String get claudeSignInCommandUnavailable =>
      'El servidor no pudo proporcionar un comando de inicio de sesión para esta cuenta.';

  @override
  String get claudeAccountSignedIn => 'Sesión iniciada';

  @override
  String get claudeSignInClosesItself =>
      'Se cierra sola cuando termine el inicio de sesión.';

  @override
  String get claudeSignInClosesItselfAll =>
      'Se cierra sola cuando todas las cuentas hayan iniciado sesión.';

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

  @override
  String get helpMenuLabel => 'Ayuda';

  @override
  String get helpWhatsNew => 'Novedades';

  @override
  String get helpReportProblem => 'Informar de un problema';

  @override
  String get helpCreateGitHubIssue => 'Crear una incidencia en GitHub';

  @override
  String get changelogInstalled => 'Instalada';

  @override
  String get changelogGroupNew => 'Nuevo';

  @override
  String get changelogGroupImproved => 'Mejorado';

  @override
  String get changelogGroupFixed => 'Corregido';

  @override
  String get changelogLoadFailed =>
      'No se pudieron cargar las notas de la versión.';

  @override
  String get changelogOpenWebsite => 'Abrir en el sitio web';

  @override
  String get connectWelcomeTitle => 'Te damos la bienvenida a Control Center';

  @override
  String get connectWelcomeSubtitle =>
      'Ejecútalo aquí o conéctate a un servidor que ya tengas.';

  @override
  String get connectWelcomeSubtitleWeb =>
      'Conéctate a tu servidor para empezar.';

  @override
  String get connectToServer => 'Conectar a un servidor';

  @override
  String get connectToServerIntro =>
      'Introduce la dirección de un servidor de Control Center.';

  @override
  String get connectUsePairingKey => 'Usar una clave de emparejamiento';

  @override
  String get connectPasteLink => 'Pegar un enlace de emparejamiento';

  @override
  String get connectPasteLinkIntro =>
      'Pega el enlace de invitación o de emparejamiento que te dieron.';

  @override
  String get connectPasteLinkLabel =>
      'Enlace de invitación o de emparejamiento';

  @override
  String get connectPasteLinkInvalid =>
      'Ese no es un enlace de invitación ni de emparejamiento de Control Center. Copia el enlace completo e inténtalo de nuevo.';

  @override
  String get connectPasteLinkTarget => 'Se conecta a';

  @override
  String get focusModeEnd => 'Finalizar sesión de concentración';

  @override
  String focusModeRemaining(int minutes) {
    return 'Quedan $minutes min';
  }

  @override
  String get demoUnavailableEnvironments =>
      'Los entornos ejecutan procesos reales en el host, así que la demo no tiene ninguno.';

  @override
  String get environmentChecksFailing =>
      'Algunas comprobaciones fallan en el servidor';

  @override
  String environmentCliEndpoints(String names) {
    return 'Endpoints: $names';
  }

  @override
  String environmentCliServices(String names) {
    return 'Servicios: $names';
  }

  @override
  String get environmentCopied => 'Copiado';

  @override
  String get environmentCopyCommand => 'Copiar comando';

  @override
  String get environmentCopyUrl => 'Copiar URL';

  @override
  String get environmentDefinition => 'Definición';

  @override
  String environmentDefinitionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count definiciones',
      one: '1 definición',
    );
    return '$_temp0';
  }

  @override
  String get environmentDestroy => 'Destruir';

  @override
  String environmentDestroyBody(String name) {
    return 'Se eliminan $name y sus datos. Iniciar crea uno nuevo.';
  }

  @override
  String get environmentDestroyTitle => '¿Destruir este entorno?';

  @override
  String get environmentExec => 'Exec';

  @override
  String get environmentExecTitle => 'Ejecutar en un servicio';

  @override
  String environmentExitCode(int code) {
    return 'Código de salida $code';
  }

  @override
  String get environmentInputNeeded =>
      'Esto hay que configurarlo en el servidor';

  @override
  String get environmentKindApp => 'App';

  @override
  String get environmentKindCli => 'CLI';

  @override
  String get environmentKindCompose => 'Compose';

  @override
  String get environmentKindProcess => 'Proceso';

  @override
  String get environmentKindTask => 'Tarea';

  @override
  String get environmentLaunch => 'Lanzar';

  @override
  String get environmentLogsGone => 'Estos registros ya no están disponibles.';

  @override
  String environmentLogsTab(String name) {
    return 'Registros: $name';
  }

  @override
  String get environmentLogsWaiting => 'Esperando salida';

  @override
  String get environmentMoreActions => 'Más acciones del entorno';

  @override
  String get environmentNeedsRecreate =>
      'Un cambio requiere recrear este entorno.';

  @override
  String get environmentNoStack =>
      'Solo ejecuta tareas del worktree, así que no hay nada que iniciar.';

  @override
  String get environmentOnTheServer => 'En el servidor';

  @override
  String get environmentOpenInBrowserVm => 'Abrir en Browser (VM)';

  @override
  String get environmentOpenViewer => 'Abrir visor';

  @override
  String get environmentPlacementRig => 'En una VM';

  @override
  String get environmentPreviewTab => 'Entorno';

  @override
  String get environmentRebuildRelaunch => 'Recompilar y relanzar';

  @override
  String get environmentRecreate => 'Recrear';

  @override
  String environmentRecreateBody(String name) {
    return '$name se destruye y se inicia de nuevo con las mismas opciones. Sus datos se pierden.';
  }

  @override
  String get environmentRecreateTitle => '¿Recrear este entorno?';

  @override
  String environmentResetBody(String name) {
    return '$name vuelve a su estado base. Los datos creados desde entonces se pierden.';
  }

  @override
  String get environmentResetData => 'Restablecer datos';

  @override
  String get environmentResetTitle => '¿Restablecer datos?';

  @override
  String get environmentRestart => 'Reiniciar';

  @override
  String environmentRestarts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reinicios',
      one: '1 reinicio',
    );
    return '$_temp0';
  }

  @override
  String get environmentRun => 'Ejecutar';

  @override
  String get environmentRunInTerminal => 'Ejecutar en el terminal';

  @override
  String get environmentSectionTitle => 'Entorno';

  @override
  String get environmentService => 'Servicio';

  @override
  String environmentServiceActions(String name) {
    return 'Acciones de $name';
  }

  @override
  String get environmentStartTitle => 'Iniciar entorno';

  @override
  String get environmentStateCrashed => 'Bloqueado';

  @override
  String get environmentStatusDegraded => 'Degradado';

  @override
  String get environmentStatusDestroying => 'Destruyendo';

  @override
  String get environmentStatusGone => 'Eliminado';

  @override
  String get environmentStatusStopping => 'Deteniendo';

  @override
  String environmentStopDataLoss(String name) {
    return 'Al detener $name se pierden sus datos, e Iniciar no los recupera.';
  }

  @override
  String get environmentStopLoseData => 'Detener y perder datos';

  @override
  String get environmentStopTitle => '¿Detener este entorno?';

  @override
  String get environmentTaskNeverRun => 'Aún no se ha ejecutado';

  @override
  String get environmentsAddCheck => 'Añadir comprobación';

  @override
  String get environmentsAddOption => 'Añadir opción';

  @override
  String get environmentsAddRole => 'Añadir rol';

  @override
  String get environmentsAdminOnly =>
      'Solo los administradores del espacio de trabajo pueden cambiar las definiciones.';

  @override
  String get environmentsAfter => 'Esperar a estos componentes';

  @override
  String get environmentsAnchor => 'Ancla';

  @override
  String get environmentsAutoCreate => 'Iniciar automáticamente';

  @override
  String get environmentsAutoCreateAll => 'En cada espacio apto';

  @override
  String get environmentsAutoCreateOff => 'Nunca';

  @override
  String get environmentsAutoCreatePrs => 'En espacios de pull request';

  @override
  String get environmentsBlank => 'Definición en blanco';

  @override
  String get environmentsCheckFix => 'Comando de solución';

  @override
  String get environmentsCheckHint => 'Pista';

  @override
  String get environmentsCommandHelp =>
      'Los argumentos se separan con espacios. Pon entre comillas el que contenga un espacio.';

  @override
  String environmentsComponentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count componentes',
      one: '1 componente',
    );
    return '$_temp0';
  }

  @override
  String get environmentsComponentId => 'ID';

  @override
  String get environmentsComposeBuild => 'Compilar imágenes al iniciar';

  @override
  String get environmentsComposeFile => 'Archivo compose';

  @override
  String get environmentsComposeHttp => 'HTTP';

  @override
  String get environmentsComposeNoFile =>
      'No se pudo leer un archivo compose. Los nombres de servicio aún pueden ir en la vista JSON.';

  @override
  String get environmentsComposeServices => 'Servicios';

  @override
  String get environmentsComposeServicesHint =>
      'Deja todos los servicios sin marcar para ejecutarlos todos.';

  @override
  String get environmentsConditionalArgs =>
      'Este comando tiene argumentos condicionales. Edítalo en la vista JSON.';

  @override
  String get environmentsCwdPath => 'Ruta de trabajo';

  @override
  String get environmentsCwdRole => 'Rol de trabajo';

  @override
  String get environmentsDeleteBody =>
      'Los espacios ya no podrán iniciarlo. Los entornos en marcha siguen hasta que se detengan.';

  @override
  String environmentsDeleteTitle(String name) {
    return '¿Eliminar $name?';
  }

  @override
  String get environmentsDescription =>
      'Qué puede iniciar cada espacio y qué tareas ejecutan sus worktrees.';

  @override
  String get environmentsDraftFromRepo => 'Crear borrador desde repo';

  @override
  String get environmentsEmpty => 'Aún no hay definiciones';

  @override
  String get environmentsEnabledWhen => 'Activado cuando';

  @override
  String get environmentsEndpointRole => 'Rol del endpoint';

  @override
  String get environmentsFollowPrHead => 'Seguir el head del pull request';

  @override
  String get environmentsForkApproval =>
      'Cada inicio necesita un administrador';

  @override
  String get environmentsForkDeny => 'Rechazado';

  @override
  String get environmentsForkPrs => 'Pull requests de forks';

  @override
  String get environmentsForkRig => 'Ejecutar en una VM';

  @override
  String get environmentsIdleStop => 'Detener tras minutos de inactividad';

  @override
  String get environmentsIsolateHome => 'Dar a la app un home privado';

  @override
  String get environmentsIssues => 'Corrige esto antes de guardar';

  @override
  String environmentsJsonInvalid(String error) {
    return 'JSON no válido: $error';
  }

  @override
  String get environmentsKeepsData => 'Conserva sus datos al detenerse';

  @override
  String get environmentsLinkConfirm => 'Vincular y aprobar';

  @override
  String get environmentsLinkFile => 'Vincular un archivo del repo';

  @override
  String get environmentsLinkHelp =>
      'Se lee solo de la rama predeterminada y se ejecuta solo tras aprobarlo.';

  @override
  String get environmentsLinkPath => 'Ruta';

  @override
  String get environmentsMaxRunning => 'En ejecución a la vez';

  @override
  String get environmentsNamingProject => 'Proyecto';

  @override
  String get environmentsNamingTemplate => 'Plantilla de nombre';

  @override
  String get environmentsNew => 'Nueva definición';

  @override
  String get environmentsNewDefinitionName => 'Nuevo entorno';

  @override
  String get environmentsNoChecks => 'Esta definición no tiene comprobaciones.';

  @override
  String get environmentsNoRuns => 'Aún no hay ejecuciones de prueba';

  @override
  String get environmentsOnChange => 'Rutas a vigilar';

  @override
  String get environmentsOptionBool => 'Sí o no';

  @override
  String get environmentsOptionEnum => 'Uno de';

  @override
  String get environmentsOptionMulti => 'Varios de';

  @override
  String get environmentsOptionValues => 'Valores';

  @override
  String get environmentsPlacement => 'Ubicación';

  @override
  String get environmentsPlacementHost => 'En el host';

  @override
  String get environmentsPlacementRig => 'En una VM';

  @override
  String get environmentsPrepareTask => 'Tarea de preparación';

  @override
  String get environmentsPrimaryEndpoint => 'Endpoint principal';

  @override
  String get environmentsReadyHttp => 'Listo cuando responda esta URL';

  @override
  String get environmentsRestartAlways => 'Siempre';

  @override
  String get environmentsRestartNever => 'Nunca';

  @override
  String get environmentsRestartOn => 'Reiniciar cuando cambien estas rutas';

  @override
  String get environmentsRestartOnFailure => 'Si falla';

  @override
  String get environmentsRestartPolicy => 'Reiniciar';

  @override
  String get environmentsRigTtl => 'Duración de la VM en horas';

  @override
  String get environmentsRunChecks => 'Ejecutar de nuevo';

  @override
  String get environmentsRunTest => 'Ejecutar prueba';

  @override
  String get environmentsSaved => 'Definición guardada';

  @override
  String get environmentsSectionComponents => 'Componentes';

  @override
  String get environmentsSectionOptions => 'Opciones de inicio';

  @override
  String get environmentsSectionSeedFiles => 'Archivos semilla';

  @override
  String get environmentsSectionVariables => 'Variables';

  @override
  String get environmentsSeedHelp =>
      'Una ruta por línea, copiada del checkout registrado. Los pull requests de forks nunca los reciben.';

  @override
  String get environmentsShellHelp =>
      'Aquí no se expanden los marcadores. Lee las variables CC_ENV_* en su lugar.';

  @override
  String get environmentsSourceApprove => 'Aprobar esta versión';

  @override
  String environmentsSourceCurrent(String path) {
    return '$path coincide con la versión aprobada.';
  }

  @override
  String get environmentsSourceNotice =>
      'La versión aprobada sigue ejecutándose hasta que apruebes esta.';

  @override
  String get environmentsTabJson => 'JSON';

  @override
  String get environmentsTabSource => 'Origen';

  @override
  String get environmentsTestHelp =>
      'Ejecuta un entorno desechable de principio a fin: comprobar, iniciar, esperar a que esté listo, destruir.';

  @override
  String get environmentsTestSaveFirst => 'Guarda primero la definición.';

  @override
  String get environmentsTimeoutSeconds => 'Tiempo de espera en segundos';

  @override
  String get environmentsTitle => 'Entornos';

  @override
  String get environmentsTriggerArchive => 'Antes de eliminar el worktree';

  @override
  String get environmentsTriggerChange => 'Cuando cambian las rutas vigiladas';

  @override
  String get environmentsTriggerCreate => 'Una vez por entorno';

  @override
  String get environmentsTriggerManual => 'Bajo demanda';

  @override
  String get environmentsTriggerProvision => 'Cuando se crea el worktree';

  @override
  String get environmentsTriggerStart => 'En cada inicio';

  @override
  String get environmentsTriggers => 'Se ejecuta';

  @override
  String get environmentsUnreadable =>
      'Este cliente no puede leer esta definición.';

  @override
  String get environmentsUpdateAvailable => 'Actualización disponible';

  @override
  String get environmentsUseShell => 'Usar un comando de shell';

  @override
  String get environmentsUseSourceWarning =>
      'La herramienta se ejecuta entonces sobre tu propio checkout. Trátalo como de solo lectura.';

  @override
  String get environmentsWhenMissing => 'Cuando a un espacio le falta';

  @override
  String get environmentsWhenMissingAdd => 'Añadirlo al espacio';

  @override
  String get environmentsWhenMissingSkip => 'Omitirlo';

  @override
  String get environmentsWhenMissingSource => 'Usar el checkout registrado';

  @override
  String get environmentsUnsupported => 'Este servidor no admite entornos.';

  @override
  String get environmentViewerUnavailable =>
      'Sin visor: el servidor no puede capturar esta ventana. Permite la grabación de pantalla a Control Center en el servidor.';

  @override
  String get environmentHealthHealthy => 'Correcto';

  @override
  String get environmentHealthUnhealthy => 'Con fallos';

  @override
  String get environmentTerminalStale =>
      'Este terminal se abrió antes de iniciar el entorno, así que no tiene sus variables.';

  @override
  String get environmentTerminalFresh => 'Abrir un terminal nuevo';

  @override
  String get environmentsShellStays =>
      'Un script de varias líneas sigue siendo un comando de shell: sus líneas son su estructura.';

  @override
  String get environmentsOverrides => 'Anulaciones del espacio de trabajo';

  @override
  String get environmentsOverridesHelp =>
      'Los ajustes propios del archivo son de solo lectura aquí. Asigna sus roles a los repos de este espacio de trabajo o anula cualquier campo como JSON.';

  @override
  String get environmentsReposHelp =>
      'Los repositorios que usa este entorno, cada uno vinculado a un rol.';

  @override
  String get environmentsComponentsHelp =>
      'Lo que ejecuta el entorno, en orden de inicio.';

  @override
  String get environmentsOptionsHelp =>
      'Opciones que se ofrecen al iniciar el entorno.';

  @override
  String get environmentsVariablesHelp =>
      'Se definen en tareas, procesos, apps y terminales del espacio.';

  @override
  String get environmentsChecksHelp =>
      'Lo que necesita el host para que este entorno funcione.';

  @override
  String get environmentsIdleStopHelp => 'Con 0 nunca se detiene.';

  @override
  String get environmentsAnchorHelp =>
      'Un espacio con este repositorio puede iniciar el entorno.';

  @override
  String get environmentsRequiredHelp =>
      'El entorno no puede funcionar sin él.';

  @override
  String get environmentsFollowPrHeadHelp =>
      'Sincronizar y actualizar cuando se mueve el head del pull request.';

  @override
  String get environmentsRecordNeedsFix => 'Necesita corrección';

  @override
  String get environmentsCheckFile => 'Archivo';

  @override
  String get environmentsDiscardBody =>
      'Se perderán tus cambios en esta definición.';

  @override
  String get environmentsWorktreeRuns => 'Ejecuciones de tareas del worktree';

  @override
  String get environmentsNoWorktreeRuns =>
      'Aún no se ha ejecutado ninguna tarea del worktree.';

  @override
  String get environmentsLinkRoles => 'Roles de este archivo';

  @override
  String get environmentsLinkNoFile =>
      'No se pudo leer ese archivo del repo. Los roles se pueden asignar después de vincularlo.';

  @override
  String get guardrailClassHostExecution => 'Ejecutar comandos en el host';

  @override
  String get environmentUrls => 'URL';

  @override
  String get environmentScripts => 'Scripts';

  @override
  String get environmentNoneForSpace => 'No hay entorno para este espacio';

  @override
  String get environmentNoneForPr => 'No hay entorno para esta pull request';

  @override
  String get environmentSetupBody =>
      'Un entorno ejecuta los servicios, scripts y URL de un repositorio para un espacio. Configúralo una vez y cualquier espacio del repositorio podrá iniciarlo.';

  @override
  String get environmentSetUp => 'Configurar entorno';

  @override
  String get environmentEditDefinition => 'Editar definición';

  @override
  String get environmentOpenPanel => 'Abrir entorno';

  @override
  String get environmentStatusBlocked => 'Requiere acción';

  @override
  String get environmentStateInTerminal => 'En la terminal';

  @override
  String get environmentWaitingInTerminal => 'Te espera en una terminal';

  @override
  String get environmentOpenTerminal => 'Abrir terminal';

  @override
  String get environmentSignInNeeded => 'Necesitas iniciar sesión';

  @override
  String get environmentDependencyNeeded =>
      'Algo de lo que depende no está disponible';

  @override
  String get environmentStartTerminalDone =>
      'Listo aquí. El entorno sigue iniciándose';

  @override
  String get environmentContinueInTerminal => 'Continuar en la terminal';

  @override
  String get environmentStartTerminalHint =>
      'La herramienta te necesita en una terminal para una contraseña o una pregunta. El inicio continúa cuando termine.';

  @override
  String get environmentStartTerminalReason =>
      'Esta terminal se abrió porque el inicio te necesita';

  @override
  String get environmentStartTerminalTab => 'Configuración del entorno';

  @override
  String get environmentsNothingRunning =>
      'No hay nada en ejecución de esta definición.';

  @override
  String get searchPoliciesHint => 'Buscar políticas...';

  @override
  String get noPoliciesMatch => 'Ninguna política coincide con tu búsqueda';

  @override
  String get memoryPolicyActive => 'Activa';

  @override
  String get memoryFactType => 'Tipo';

  @override
  String get memoryTimesRecalled => 'Veces recuperado';

  @override
  String get memorySourceFacts => 'Hechos de origen';

  @override
  String get spaceSetupLogs => 'Registros de configuración';

  @override
  String get claudeCompactionTitle => 'Compactación';

  @override
  String get claudeCompactionDescription =>
      'Cómo mantiene Claude Code las conversaciones largas dentro de su ventana de contexto.';

  @override
  String get claudeAutoCompactLabel => 'Compactar automáticamente tras';

  @override
  String claudeAutoCompactHint(String min, String max) {
    return 'Tokens, de $min a $max. Déjalo vacío para usar el valor predeterminado de Claude Code.';
  }

  @override
  String claudeAutoCompactInvalid(String min, String max) {
    return 'Introduce un número de $min a $max.';
  }

  @override
  String get claudeIdleCompactLabel => 'Compactar conversaciones inactivas';

  @override
  String claudeIdleCompactDescription(String threshold) {
    return 'Compacta una conversación de más de $threshold tokens justo antes de que caduque su caché de prompts, para que volver a ella cueste menos. Cada compactación consume tu plan.';
  }

  @override
  String get claudeCompactionSaveFailed => 'No se pudo guardar este ajuste.';

  @override
  String get navDesktopApp => 'Aplicación de escritorio';

  @override
  String get desktopAppSettingsSubtitle =>
      'El icono de la bandeja, el cierre de la ventana y la apertura al iniciar sesión.';

  @override
  String get desktopSectionMenuBar => 'Barra de menús';

  @override
  String get desktopSectionTray => 'Bandeja del sistema';

  @override
  String get desktopTrayTitleMac => 'Mostrar en la barra de menús';

  @override
  String get desktopTrayTitle => 'Mostrar en la bandeja del sistema';

  @override
  String get desktopTraySubtitle =>
      'El estado, lo que te necesita, tus espacios y el uso del plan, a un clic.';

  @override
  String get desktopTrayMissingTitle => 'No se encontró la bandeja del sistema';

  @override
  String get desktopTrayMissingBody =>
      'Este escritorio no muestra iconos en la bandeja. En GNOME, instala la extensión AppIndicator y reinicia Control Center.';

  @override
  String get desktopSectionClosing => 'Cierre de la ventana';

  @override
  String get desktopCloseTitle => 'Al cerrar la ventana';

  @override
  String get desktopCloseKeepRunning => 'Mantener en marcha';

  @override
  String get desktopCloseQuit => 'Salir';

  @override
  String get desktopCloseKeepRunningSubtitleMac =>
      'Los agentes y las notificaciones siguen funcionando. Vuelve a abrir la ventana desde el Dock o la barra de menús.';

  @override
  String get desktopCloseKeepRunningSubtitle =>
      'Los agentes y las notificaciones siguen funcionando. Vuelve a abrir la ventana desde el icono de la bandeja.';

  @override
  String get desktopCloseQuitSubtitle =>
      'Al cerrar la ventana se sale de Control Center. Las notificaciones se detienen hasta que lo vuelvas a abrir.';

  @override
  String get desktopCloseNeedsTray =>
      'Activa el icono de la bandeja para que Control Center siga en marcha con la ventana cerrada.';

  @override
  String get desktopSectionLogin => 'Inicio';

  @override
  String get desktopLoginTitle => 'Abrir al iniciar sesión';

  @override
  String get desktopLoginSubtitle =>
      'Abre Control Center al iniciar sesión para que las notificaciones lleguen desde el primer momento.';

  @override
  String get desktopLoginUnsupported =>
      'Este sistema no permite abrir aplicaciones al iniciar sesión.';

  @override
  String get desktopLoginNeedsApproval =>
      'Permite Control Center en Ítems de inicio para terminar de activar esta opción.';

  @override
  String get desktopLoginOpenLoginItems => 'Abrir Ítems de inicio';

  @override
  String get desktopLoginRefused =>
      'El sistema no aceptó el cambio. Es posible que lo gestione tu administrador.';

  @override
  String get desktopLoginStartHiddenTitle => 'Iniciar en segundo plano';

  @override
  String get desktopLoginStartHiddenSubtitleMac =>
      'Se abre sin ventana al iniciar sesión. Lo encontrarás en el Dock o en la barra de menús.';

  @override
  String get desktopLoginStartHiddenSubtitle =>
      'Se abre sin ventana al iniciar sesión. Lo encontrarás en la bandeja.';

  @override
  String get desktopLoginStartHiddenNeedsTray =>
      'Requiere el icono de la bandeja para poder abrir la ventana.';

  @override
  String get closeToTrayPromptTitle => '¿Mantener Control Center en marcha?';

  @override
  String get closeToTrayPromptBody =>
      'Con la ventana cerrada, los agentes siguen trabajando y las notificaciones siguen llegando. Vuelve a abrirla desde el icono de la bandeja. Puedes cambiar esto en Ajustes → Aplicación de escritorio.';

  @override
  String get closeToTrayPromptQuit => 'Salir';

  @override
  String get closeToTrayPromptKeepRunning => 'Mantener en marcha';

  @override
  String get trayStatusOffline => 'Sin conexión';

  @override
  String get trayStatusReconnecting => 'Reconectando…';

  @override
  String trayStatusNeedsYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count te necesitan',
      one: '1 te necesita',
    );
    return '$_temp0';
  }

  @override
  String trayStatusWorking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count en curso',
      one: '1 en curso',
    );
    return '$_temp0';
  }

  @override
  String get trayStatusAllQuiet => 'Todo tranquilo';

  @override
  String trayTooltip(String status) {
    return 'Control Center · $status';
  }

  @override
  String trayMenuSpaceQuestions(String space, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count preguntas',
      one: '1 pregunta',
    );
    return '$space · $_temp0';
  }

  @override
  String trayApprovalsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aprobaciones pendientes',
      one: '1 aprobación pendiente',
    );
    return '$_temp0';
  }

  @override
  String get trayMenuOpen => 'Abrir Control Center';

  @override
  String get trayMenuSettings => 'Ajustes…';

  @override
  String get trayMenuQuit => 'Salir de Control Center';

  @override
  String get trayPanelTitle => 'Control Center';

  @override
  String get trayPanelNoWorkspace =>
      'Abre Control Center para elegir un espacio de trabajo.';

  @override
  String get trayPanelOpenApp => 'Abrir Control Center';

  @override
  String get trayPanelSettings => 'Ajustes de la aplicación de escritorio';

  @override
  String get trayPanelNeedsYou => 'Te necesita';

  @override
  String get trayPanelApprovals => 'Aprobaciones';

  @override
  String get trayPanelSpaces => 'Espacios';

  @override
  String get trayPanelNoSpaces => 'Aún no hay espacios.';

  @override
  String trayPanelAllSpaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Los $count espacios',
      one: 'Todos los espacios',
    );
    return '$_temp0';
  }

  @override
  String get trayPanelUsage => 'Uso';

  @override
  String get trayPanelSwitchWorkspace => 'Cambiar de espacio de trabajo';

  @override
  String signInToProvider(String provider) {
    return 'Iniciar sesión en $provider';
  }

  @override
  String get linearConnectAutomation => 'Conectar Linear para automatización';

  @override
  String signInOpeningBrowser(String provider) {
    return 'Abriendo $provider en tu navegador…';
  }

  @override
  String get signInFailedTitle => 'No se completó el inicio de sesión';

  @override
  String get signInReopenPage => 'Volver a abrir la página de inicio de sesión';

  @override
  String get signInCodePrompt =>
      'Confirma en tu navegador y luego introduce el código que muestre.';

  @override
  String get signInCodeMalformed =>
      'Eso no parece un código de inicio de sesión. Los códigos tienen 8 letras y dígitos.';

  @override
  String get signInCodeDeepLinkHint =>
      'Si tu navegador ofrece abrir Control Center, acéptalo y no tendrás que escribir el código.';

  @override
  String signInSucceeded(String provider, String account) {
    return 'Sesión iniciada en $provider como $account';
  }

  @override
  String signInSucceededNoAccount(String provider) {
    return 'Sesión iniciada en $provider';
  }

  @override
  String get signInErrorExpired =>
      'Este inicio de sesión caducó. Empieza de nuevo.';

  @override
  String signInErrorAccessDenied(String provider) {
    return 'El inicio de sesión en $provider se canceló o se denegó.';
  }

  @override
  String signInErrorScopeMismatch(String provider) {
    return '$provider concedió menos permisos de los que necesita Control Center. Vuelve a iniciar sesión y aprueba todos los permisos.';
  }

  @override
  String get signInErrorInvalidCode =>
      'Ese código no coincide con este inicio de sesión. Revísalo e inténtalo de nuevo.';

  @override
  String get signInErrorTooManyCodes =>
      'Demasiados códigos incorrectos. Vuelve a iniciar el inicio de sesión.';

  @override
  String get signInErrorStaleRequest =>
      'Este inicio de sesión ya no está abierto: se canceló, se usó o se reemplazó. Empieza de nuevo.';

  @override
  String get signInErrorInvalidRequest =>
      'El servidor no pudo leer esta solicitud de inicio de sesión. Vuelve a empezarla.';

  @override
  String get signInErrorRateLimited =>
      'Hay demasiadas solicitudes en este momento. Espera un poco y vuelve a intentarlo.';

  @override
  String signInErrorStoreFailed(String provider) {
    return '$provider aceptó el inicio de sesión, pero el servidor no pudo guardarlo. Inténtalo de nuevo.';
  }

  @override
  String signInErrorProviderUnavailable(String provider) {
    return '$provider no responde ahora mismo. Inténtalo de nuevo en unos minutos.';
  }

  @override
  String signInErrorExchangeFailed(String provider) {
    return '$provider aceptó el inicio de sesión, pero el servidor no pudo completarlo. Inténtalo de nuevo.';
  }

  @override
  String signInErrorMisconfigured(String provider) {
    return 'La app de $provider de este servidor está mal configurada. Pide al propietario del servidor que revise Ajustes → Servidor → Inicio de sesión único.';
  }

  @override
  String signInErrorNeedsSignIn(String provider) {
    return 'Tu sesión de $provider caducó. Vuelve a iniciar sesión para seguir trabajando en tu nombre.';
  }

  @override
  String signInErrorNotInstalled(String provider) {
    return 'La app de $provider no está instalada donde se necesita. Instálala e inténtalo de nuevo.';
  }

  @override
  String get signInErrorTeamBoundElsewhere =>
      'Este espacio de Slack ya está conectado a otro servidor de Control Center.';

  @override
  String get signInErrorNotAdmin =>
      'Solo un administrador o propietario del espacio de trabajo de Slack puede conectarlo a Control Center por primera vez. Pide a uno de ellos que agregue la app.';

  @override
  String signInErrorSuspended(String provider) {
    return 'La app de $provider está suspendida. Reactívala en $provider e inténtalo de nuevo.';
  }

  @override
  String get signInErrorInstallBlocked =>
      'Control Center Connect bloqueó este servidor. Contacta con quien gestiona tu servidor Connect.';

  @override
  String get signInErrorUnknown =>
      'El inicio de sesión falló por un motivo que el servidor no indicó. Inténtalo de nuevo.';

  @override
  String get signInPhishingTitle => 'Inicio de sesión no iniciado aquí';

  @override
  String get signInPhishingBody =>
      'Este inicio de sesión no se inició desde esta app. Si alguien te envió este enlace, no continúes.';

  @override
  String get signInPhishingDetail =>
      'No se envió nada. Completar un inicio de sesión que inició otra persona conectaría tu cuenta a su servidor.';

  @override
  String signInRequiredTitle(String provider) {
    return 'Hace falta iniciar sesión en $provider';
  }

  @override
  String signInRequiredBody(String provider) {
    return 'Esto se ejecuta en tu nombre en $provider y no has iniciado sesión. Inicia sesión e inténtalo de nuevo.';
  }

  @override
  String signInRequiredBanner(String provider) {
    return 'No has iniciado sesión en $provider. Todo lo que haces aquí se ejecuta en tu nombre, así que inicia sesión primero.';
  }

  @override
  String signInUnavailable(String provider) {
    return 'El inicio de sesión en $provider aún no está configurado en este servidor.';
  }

  @override
  String get githubInstallations => 'Instalaciones de la app de GitHub';

  @override
  String get githubInstallationsDescription =>
      'Dónde está instalada la app de GitHub, entre las cuentas a las que pertenecen los repositorios de este espacio de trabajo.';

  @override
  String get githubInstallationsEmpty =>
      'La app de GitHub no está instalada en ninguna cuenta a la que pertenezcan los repositorios de este espacio de trabajo.';

  @override
  String get githubInstallApp => 'Instalar la app de GitHub';

  @override
  String get githubInstallationSuspended => 'Suspendida';

  @override
  String get linearAutomationTitle => 'Automatización de Linear';

  @override
  String get linearAutomationHint =>
      'Permite que los agentes y pipelines de este espacio de trabajo actúen en Linear como una app y no como una persona. La conectan los administradores del espacio.';

  @override
  String linearAutomationConnectedAs(String account) {
    return 'Conectado a $account';
  }

  @override
  String get connectModeHosted => 'Usar las apps de Control Center';

  @override
  String get connectModeHostedDisclosure =>
      'Los inicios de sesión pasan por Control Center Connect. Connect sella cada inicio de sesión para que solo este servidor pueda abrirlo, emite tokens de GitHub limitados a un repositorio, no guarda ninguna clave de repositorio y nunca recibe tu código fuente.';

  @override
  String get connectModeOwn => 'Usar mis propias apps';

  @override
  String get connectModeOwnHint =>
      'Registra tú mismo las apps de GitHub, Google y Linear en Ajustes → Servidor → Inicio de sesión único, y conecta la app de Slack propia de cada espacio de trabajo en Espacio de trabajo → Integraciones, donde un espacio de trabajo también puede elegir sus propias apps o Connect. «Crear mi app de GitHub» configura GitHub en un paso.';

  @override
  String get connectModeCustom => 'Usar un servidor Connect propio';

  @override
  String get connectModeCustomHint =>
      'Tu organización gestiona su propio servidor Connect. Los inicios de sesión van allí en lugar de al de Control Center.';

  @override
  String get connectModeUnset => 'Aún sin configurar';

  @override
  String get connectCustomUrlLabel => 'URL del servidor Connect';

  @override
  String get connectCustomUrlInvalid =>
      'Introduce una dirección HTTPS, como https://connect.example.com.';

  @override
  String get connectCustomUrlLoopbackHint =>
      'HTTP sin cifrar solo llega a un Connect en este equipo. Usa HTTPS para cualquier cosa en una red.';

  @override
  String get connectErrorHostedUnprovisioned =>
      'Las apps alojadas de Control Center aún no están disponibles en esta versión. Usa tus propias apps o un servidor Connect propio.';

  @override
  String get connectErrorSignature =>
      'La configuración de Connect no superó la comprobación de firma. Los inicios de sesión a través de Connect están en pausa hasta que se verifique de nuevo.';

  @override
  String get connectErrorRollback =>
      'Connect sirvió una configuración más antigua que la que este servidor ya conoce, así que se rechazó. Los inicios de sesión a través de Connect están en pausa.';

  @override
  String get connectErrorUnreachable =>
      'Este servidor no puede contactar con Connect ahora mismo. Los inicios de sesión que lo usan fallarán hasta que vuelva.';

  @override
  String get connectErrorInstallBlocked =>
      'Connect bloqueó el ID de instalación de este servidor. Contacta con quien gestiona tu servidor Connect.';

  @override
  String get connectErrorPinsChanged => 'Las apps de Connect cambiaron';

  @override
  String get connectErrorProtocol =>
      'Connect respondió de una forma que este servidor no entiende. Actualiza el servidor o revisa la URL de Connect.';

  @override
  String get connectErrorUnknown =>
      'Connect informó de un problema sin explicarlo. Ejecuta una prueba para reintentarlo.';

  @override
  String get connectPinsConfirmHint =>
      'Tu servidor Connect ahora indica apps de GitHub, Google, Linear o Slack distintas de las que este servidor fijó en el primer uso. Confía en ellas solo si su operador te avisó de que esto iba a ocurrir.';

  @override
  String get connectConfirmPins => 'Confiar en las nuevas apps';

  @override
  String get connectStale =>
      'La configuración en uso es más antigua de lo esperado. Ejecuta una prueba para actualizarla.';

  @override
  String get connectLaneSourceOwn => 'App propia';

  @override
  String get connectLaneSourceConnect => 'Connect';

  @override
  String get connectLaneSourceOff => 'Desactivado';

  @override
  String get connectTitle => 'Control Center Connect';

  @override
  String get connectDescription =>
      'De quién son las apps que usa este servidor para GitHub, Google Calendar, Linear, Slack y la búsqueda de GIF.';

  @override
  String get connectFactMode => 'Apps de inicio de sesión';

  @override
  String get connectFactHealth => 'Estado';

  @override
  String get connectFactEpoch => 'Versión de la configuración';

  @override
  String get connectHealthOff => 'Sin usar';

  @override
  String get connectHealthOk => 'Funciona';

  @override
  String get connectHealthDown => 'No funciona';

  @override
  String get connectLocked =>
      'CC_CONNECT_URL en el entorno de este servidor define esto. Cámbialo allí y reinicia el servidor.';

  @override
  String get connectLanesTitle => 'Dónde se ejecuta cada inicio de sesión';

  @override
  String get connectLanesDescription =>
      'Una app propia siempre tiene prioridad sobre Connect para su proveedor.';

  @override
  String get connectServerGroup => 'Este servidor';

  @override
  String get connectInstallId => 'ID de instalación';

  @override
  String get connectInstallIdHint =>
      'Identifica este servidor ante Connect. Dáselo a quien sea propietario de una organización u operador de Connect si te lo pide.';

  @override
  String get connectInstallIdEmpty =>
      'Se asigna la primera vez que este servidor usa Connect.';

  @override
  String get connectTestOk => 'Connect funciona.';

  @override
  String get connectRotateKey => 'Rotar la clave';

  @override
  String get connectRotateKeyTitle =>
      '¿Rotar la clave de Connect de este servidor?';

  @override
  String get connectRotateKeyBody =>
      'Este servidor recibe una clave nueva y un id de instalación nuevo, y el id anterior se retira en Connect: los inicios de sesión sellados con él y la clave anterior dejan de funcionar allí, así que todo el que inició sesión a través de Connect tendrá que volver a hacerlo. Los tokens ya entregados siguen funcionando hasta que caduquen. Los inicios de sesión a través de tus propias apps no se ven afectados. Si no se puede contactar con Connect, no cambia nada y puedes volver a intentarlo.';

  @override
  String get connectRotateKeyDone =>
      'Clave rotada. Quienes iniciaron sesión a través de Connect deben volver a hacerlo.';

  @override
  String get connectCliLabel => 'Desde un terminal';

  @override
  String get onboardingStepSignIn => 'Inicio de sesión';

  @override
  String get onboardingConnectTitle => 'Elige cómo inician sesión las personas';

  @override
  String get onboardingConnectSubtitle =>
      'Control Center trabaja con GitHub, Google Calendar, Linear, Slack y la búsqueda de GIF mediante apps registradas en cada proveedor. Elige de quién son las apps que usa este servidor. Puedes cambiarlo más tarde en Ajustes → Servidor → Inicio de sesión único.';

  @override
  String get onboardingConnectOwnNext =>
      'Crea ahora una app de GitHub para este servidor o añade tus apps más tarde en Ajustes → Servidor → Inicio de sesión único.';

  @override
  String get providerServiceApiKey => 'Clave de API de servicio';

  @override
  String get providerAppPartial => 'Configuración sin terminar';

  @override
  String providerAppMissingFields(String fields) {
    return 'Aún falta: $fields. Hasta que todos los campos estén definidos, los inicios de sesión de este proveedor se rechazan en lugar de pasar por Connect.';
  }

  @override
  String get providerAppsGroupSignInLinearDescription =>
      'El ID de cliente inicia la sesión de los miembros. La clave de API de servicio permite a este servidor leer y escribir en Linear por sí mismo.';

  @override
  String get providerCallbackUrls => 'URL de retorno';

  @override
  String get providerCallbackUrlHint =>
      'Regístrala en el proveedor exactamente como se muestra.';

  @override
  String get providerAppCreateGitHubTitle => 'Crear una app de GitHub';

  @override
  String get providerAppCreateGitHubHint =>
      'GitHub registra una app con los permisos y el retorno correctos y entrega sus credenciales a este servidor. No hay nada que copiar a mano.';

  @override
  String get providerAppCreateGitHub => 'Crear mi app de GitHub';

  @override
  String get providerAppCreateGitHubOrg => 'Organización (opcional)';

  @override
  String get providerAppCreateGitHubOrgHint =>
      'Déjalo vacío para crear la app en tu propia cuenta de GitHub. Para crearla en una organización hace falta ser propietario de esa organización.';

  @override
  String get providerAppSignInReady => 'Las personas pueden iniciar sesión.';

  @override
  String get chatLinkWaiting => 'Esperando tu mensaje directo…';

  @override
  String chatLinkClaimTitle(String provider) {
    return '¿Es esta tu cuenta de $provider?';
  }

  @override
  String chatLinkClaimBody(String provider) {
    return 'Esta cuenta envió tu código al bot. Confirma solo si es tuya: una vez vinculada, lo que envíe en $provider actuará como tú en este espacio de trabajo.';
  }

  @override
  String get chatLinkDecline => 'Rechazar';

  @override
  String chatLinkDeclined(String provider) {
    return 'No se vinculó nada. Obtén un código nuevo si aún quieres vincular tu cuenta de $provider.';
  }

  @override
  String get chatLinkNewCode => 'Obtener un código nuevo';

  @override
  String signInAddControlCenter(String provider) {
    return 'Añadir Control Center a $provider';
  }

  @override
  String signInAddedControlCenter(String workspace) {
    return 'Control Center se añadió a $workspace';
  }

  @override
  String chatSharedAppHint(String provider) {
    return 'Instala la app compartida de Control Center en tu espacio de trabajo de $provider. No hay que crear ninguna app ni pegar ningún token.';
  }

  @override
  String chatAddToProvider(String provider) {
    return 'Añadir a $provider';
  }

  @override
  String get chatSharedAppConnected =>
      'Funciona con la app compartida de Control Center, así que aquí no hay tokens ni ajustes del bot que gestionar.';

  @override
  String get chatTicketDraftsTitle => 'Borradores de tickets del chat';

  @override
  String get chatTicketDraftsDescription =>
      'Un borrador solo se convierte en un ticket del backlog cuando lo creas aquí. Los borradores que no confirmes se descartan al cabo de un día.';

  @override
  String chatTicketDraftFrom(String provider) {
    return 'De $provider';
  }

  @override
  String get chatTicketDraftCreate => 'Crear ticket';

  @override
  String chatTicketDraftCreated(String key) {
    return 'Se creó $key';
  }

  @override
  String workspaceProviderAppMissingFields(String fields) {
    return 'Faltan: $fields. Hasta que se completen todos los campos, este proveedor está desactivado en este espacio de trabajo. No recurre a la aplicación de este servidor.';
  }

  @override
  String get workspaceProviderAppClientChangeHint =>
      'Cambiar la aplicación cierra la sesión de todos en este espacio de trabajo. Tendrán que volver a iniciar sesión con la nueva.';

  @override
  String get workspaceProviderAppKlipyKey => 'Clave de aplicación';

  @override
  String get workspaceProviderAppKlipyHint =>
      'La búsqueda de GIF en este espacio de trabajo usa esta clave.';

  @override
  String get settingsWorkspaceIntegrations => 'Integraciones';

  @override
  String get settingsWorkspaceIntegrationsDescription =>
      'Alojamiento de código, tickets, calendario, chat y búsqueda de GIF en este espacio de trabajo, y con qué apps inicia sesión la gente.';

  @override
  String get workspaceConnectDescription =>
      'Qué apps usa este espacio de trabajo para GitHub, Google Calendar, Linear, Slack y la búsqueda de GIF. Salvo que un administrador elija otra cosa, sigue a este servidor.';

  @override
  String get workspaceConnectModeInherit => 'Igual que este servidor';

  @override
  String get workspaceConnectInheritHosted =>
      'Este servidor usa las apps de Control Center.';

  @override
  String workspaceConnectInheritCustom(String url) {
    return 'Este servidor usa el servidor Connect en $url.';
  }

  @override
  String get workspaceConnectInheritOwn =>
      'Este servidor usa sus propias apps.';

  @override
  String get workspaceConnectInheritUnset =>
      'El propietario del servidor aún no ha elegido, así que se aplican las apps propias del servidor.';

  @override
  String get workspaceConnectOwnHint =>
      'Solo se usan las apps de este espacio de trabajo. Añade cada una abajo, junto a su proveedor. Un proveedor sin app está desactivado aquí; no se usan en su lugar las apps de este servidor ni Connect.';

  @override
  String get workspaceConnectCustomUrlHint =>
      'Solo HTTPS. Se rechazan las direcciones de una red privada o local.';

  @override
  String get workspaceConnectLocked =>
      'CC_CONNECT_URL en el entorno de este servidor define adónde van los inicios de sesión, así que este espacio de trabajo no puede elegir un Connect propio. Puede seguir a este servidor o usar sus propias apps.';

  @override
  String get workspaceConnectSwitchTitle =>
      '¿Cambiar las apps de inicio de sesión de este espacio de trabajo?';

  @override
  String get workspaceConnectSwitchBody =>
      'Todas las personas de este espacio de trabajo tendrán que volver a iniciar sesión en GitHub, Linear y Google Calendar mediante las nuevas apps. Los inicios de sesión hechos con las actuales dejarán de funcionar aquí.';

  @override
  String get workspaceConnectSwitchAction => 'Cambiar apps';

  @override
  String get workspaceConnectLanesDescription =>
      'Sigue la elección de arriba. Un proveedor nunca recurre a otra app.';

  @override
  String get workspaceConnectLaneWorkspaceOwn => 'App del espacio de trabajo';

  @override
  String get workspaceConnectLaneServerOwn => 'App del servidor';

  @override
  String get workspaceGitHubAppTitle => 'App de GitHub';

  @override
  String get workspaceGitHubAppOwnDescription =>
      'La app propia de este espacio de trabajo actúa por sus repositorios e inicia sesión a sus miembros. Nunca recurre a la app de este servidor ni a Connect.';

  @override
  String get workspaceGitHubAppSharedDescription =>
      'Este espacio de trabajo usa la app de GitHub que proporcionan sus apps de inicio de sesión. Instálala en las cuentas a las que pertenecen tus repositorios.';

  @override
  String get workspaceGitHubAppActingTitle =>
      'Actúa para este espacio de trabajo';

  @override
  String get workspaceGitHubAppActingDescription =>
      'El bot de la app comenta, revisa y sondea pull requests en los repositorios de este espacio de trabajo.';

  @override
  String workspaceOwnAppTitle(String provider) {
    return 'App de $provider';
  }

  @override
  String workspaceOwnAppDescription(String provider) {
    return 'Los inicios de sesión y las solicitudes de $provider en este espacio de trabajo usan solo esta app.';
  }

  @override
  String get workspaceGifsTitle => 'GIF';

  @override
  String get workspaceGifsSourceWorkspaceOwn =>
      'La búsqueda de GIF usa la clave de Klipy de este espacio de trabajo.';

  @override
  String get workspaceGifsSourceServerOwn =>
      'La búsqueda de GIF usa la clave de Klipy de este servidor.';

  @override
  String get workspaceGifsSourceConnect =>
      'La búsqueda de GIF funciona a través de Control Center Connect.';

  @override
  String get workspaceGifsSourceOff =>
      'La búsqueda de GIF está desactivada en este espacio de trabajo.';

  @override
  String openOnForge(String forge) {
    return 'Abrir en $forge';
  }

  @override
  String prFilesTruncatedNotice(String forge, int count) {
    return 'Se muestran los primeros $count archivos. $forge no lista el resto.';
  }

  @override
  String get connectForgeToLoadPrs =>
      'Conecta un servicio de alojamiento de código para cargar las pull requests';

  @override
  String get connectForgeHint =>
      'Conecta GitHub, GitLab o Bitbucket en Ajustes → Tú → Perfil';

  @override
  String get addForgeRepoPrompt =>
      'Añade al menos un repositorio de GitHub, GitLab o Bitbucket para ver pull requests';

  @override
  String get composePrNoForgeRepo =>
      'No hay ningún repositorio alojado seleccionado';

  @override
  String get composePrNoForgeRepoHint =>
      'Selecciona un espacio de trabajo con un repositorio en GitHub, GitLab o Bitbucket para abrir una pull request.';

  @override
  String composePrForgeNotConnected(String forge) {
    return 'Conecta $forge para abrir una pull request en este repositorio';
  }

  @override
  String connectionNeedsSignInAs(String provider, String account) {
    return 'Tu sesión de $provider como $account caducó. Vuelve a iniciar sesión.';
  }

  @override
  String get connectionPaused =>
      'En pausa: cambió el servicio de inicio de sesión de este espacio de trabajo';

  @override
  String connectionUnreachable(String provider) {
    return 'No se puede contactar con $provider ahora mismo. Reintentando.';
  }

  @override
  String get forgeSignInBannerPausedBody =>
      'Tu sesión se conserva y volverá a funcionar cuando el servicio regrese. Un administrador del espacio de trabajo puede revisar la configuración de inicio de sesión en Integraciones.';

  @override
  String get signInErrorAttemptUnknown =>
      'El servidor se reinició. Vuelve a empezar el inicio de sesión.';

  @override
  String signInUnavailableNotConfigured(String provider) {
    return 'El inicio de sesión con $provider no está configurado en este espacio de trabajo.';
  }

  @override
  String signInUnavailableMisconfigured(String provider, String error) {
    return 'El inicio de sesión con $provider está mal configurado: $error';
  }

  @override
  String signInUnavailableOwnAppMissing(String provider) {
    return 'Este espacio de trabajo usa sus propias apps, pero no tiene una app de $provider.';
  }

  @override
  String signInUnavailableConnectUnprovisioned(String provider) {
    return 'Esta compilación no puede verificar Control Center Connect, así que el inicio de sesión con $provider está desactivado.';
  }

  @override
  String get signInUnavailableConnectPinsPending =>
      'El servicio de inicio de sesión de este espacio de trabajo cambió su identidad. Un administrador debe confirmarla.';

  @override
  String get signInUnavailableConnectUnreachable =>
      'No se puede contactar con el servicio de inicio de sesión de este espacio de trabajo ahora mismo.';

  @override
  String get signInUnavailableConnectUrlInvalid =>
      'Falta la dirección del servicio de inicio de sesión de este espacio de trabajo o no es válida.';

  @override
  String get signInUnavailableBlockedByEnvironment =>
      'El operador del servidor fijó el servicio de inicio de sesión, así que la elección de este espacio de trabajo no se aplica.';

  @override
  String signInUnavailableLaneNotOffered(String provider) {
    return 'El servicio de inicio de sesión de este espacio de trabajo no ofrece $provider.';
  }

  @override
  String get signInOpenIntegrations => 'Abrir integraciones';

  @override
  String get signInOpenServerSettings => 'Abrir ajustes de inicio de sesión';

  @override
  String forgeTokenRequiredBody(String provider) {
    return 'Esto se ejecuta en tu nombre en $provider y no has añadido un token. Añade uno y vuelve a intentarlo.';
  }

  @override
  String disconnectProviderTitle(String provider) {
    return '¿Desconectar $provider?';
  }

  @override
  String disconnectProviderBody(String provider) {
    return 'Tendrás que volver a conectar $provider para trabajar en sus repositorios.';
  }

  @override
  String disconnectScopeWorkspaceBody(String provider) {
    return 'Esto desconecta $provider solo en este espacio de trabajo. Los demás espacios de trabajo conservan su propia conexión.';
  }

  @override
  String disconnectScopeGlobalBody(String provider) {
    return 'Esto desconecta $provider en todos los espacios de trabajo que comparten esta conexión.';
  }

  @override
  String disconnectedFromWorkspace(String provider) {
    return '$provider desconectado de este espacio de trabajo';
  }

  @override
  String disconnectedFromAllWorkspaces(String provider) {
    return '$provider desconectado de todos los espacios de trabajo';
  }

  @override
  String repoAccessInstallTitle(String owner) {
    return 'Instala la GitHub App en $owner';
  }

  @override
  String repoAccessInstallBody(String repos) {
    return 'La automatización no puede llegar a $repos hasta que la App esté instalada allí.';
  }

  @override
  String repoAccessSelectTitle(String repos) {
    return 'Añade $repos a los repositorios de la GitHub App';
  }

  @override
  String get repoAccessSelectBody =>
      'La App está instalada en esta cuenta, pero todavía no ve estos repositorios.';

  @override
  String get repoAccessChooseRepos => 'Elegir repositorios';

  @override
  String get repoAccessSuspendedTitle =>
      'Instalación de la GitHub App suspendida';

  @override
  String repoAccessSuspendedBody(String repos) {
    return 'La automatización de $repos está en pausa hasta que un propietario de la cuenta reanude la instalación en GitHub.';
  }

  @override
  String get repoAccessAutomationPausedTitle =>
      'La automatización está en pausa';

  @override
  String repoAccessOwnerCannotSeeBody(String repos) {
    return 'La persona responsable de la automatización de este espacio de trabajo ya no puede ver $repos, así que no se ejecuta nada allí en su nombre.';
  }

  @override
  String repoAccessOwnerNotSignedInBody(String repos) {
    return 'La persona responsable de la automatización de este espacio de trabajo no ha iniciado sesión en la forja, así que la automatización de $repos espera hasta que lo haga.';
  }

  @override
  String repoAccessTransient(String repos) {
    return 'No se pudo comprobar el acceso a $repos. Reintentando.';
  }

  @override
  String repoAccessAskAdmins(String admins) {
    return 'Pide a $admins que lo solucione.';
  }

  @override
  String get repoAccessAskAnAdmin =>
      'Pide a un administrador del espacio de trabajo que lo solucione.';

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Inicia sesión en $forge para ver pull requests de $count repositorios más',
      one:
          'Inicia sesión en $forge para ver pull requests de 1 repositorio más',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count repositorios están ocultos porque tu cuenta de $forge no puede verlos',
      one:
          '1 repositorio está oculto porque tu cuenta de $forge no puede verlo',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count repositorios están ocultos porque no tienes acceso a ellos en este espacio de trabajo',
      one:
          '1 repositorio está oculto porque no tienes acceso a él en este espacio de trabajo',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Comprobando tu acceso a $count repositorios más…',
      one: 'Comprobando tu acceso a 1 repositorio más…',
    );
    return '$_temp0';
  }

  @override
  String get repoLinkAccessWarningsTitle =>
      'Vinculado, pero la automatización aún no llega a todo';

  @override
  String get githubInstallOnAnotherOrganization =>
      'Instalar en otra organización';

  @override
  String get forgeTokenEmailLabel => 'Correo de la cuenta de Atlassian';

  @override
  String get forgeTokenEmailInvalid =>
      'Introduce la dirección de correo de tu cuenta de Atlassian.';

  @override
  String get forgeTokenApiTokenLabel => 'Token de API';

  @override
  String get forgeTokenBitbucketHint =>
      'Los tokens de API de Bitbucket funcionan junto con el correo de la cuenta de Atlassian que los creó.';

  @override
  String get automationTokensTitle => 'Tokens de automatización';

  @override
  String get automationTokensRepoHint =>
      'El trabajo en segundo plano en GitLab y Bitbucket, como las actualizaciones de pull requests, los comentarios de revisión con IA y las merge requests que nadie pidió, usa un token de acceso de bot, nunca el de una persona. El token propio de un repositorio tiene prioridad sobre el del espacio de trabajo.';

  @override
  String get automationTokensWorkspaceHint =>
      'Se usa para cada repositorio de GitLab o Bitbucket de este espacio de trabajo que no tiene su propio token de automatización. El trabajo en segundo plano allí aparece como el bot de este token.';

  @override
  String get automationTokenNone =>
      'Sin token. La automatización está en pausa aquí.';

  @override
  String get automationTokenFromWorkspace =>
      'Usa el token del espacio de trabajo';

  @override
  String automationTokenActsAs(String name) {
    return 'Actúa como $name';
  }

  @override
  String get automationTokenStored => 'Token de acceso añadido';

  @override
  String get automationTokenRejected =>
      'La plataforma rechazó este token. Sustitúyelo.';

  @override
  String automationTokenDialogTitle(String forge) {
    return 'Token de automatización de $forge';
  }

  @override
  String get automationTokenGitLabHint =>
      'Pega un token de acceso de proyecto o de grupo. Necesita read_api y read_repository; añade api y write_repository para comentarios, merge requests y pushes. GitLab muestra su trabajo como el bot del token.';

  @override
  String get automationTokenBitbucketHint =>
      'Pega un token de acceso de repositorio, proyecto o espacio de trabajo con lectura del repositorio, más escritura de pull requests para comentarios y pull requests. Tu propio token de API va en Tú → Perfil, no aquí.';

  @override
  String automationTokenUnreadable(String repos) {
    return 'Token guardado, pero no puede leer $repos. La automatización sigue en pausa allí.';
  }

  @override
  String get automationTokenRemoveTitle =>
      '¿Quitar el token de automatización?';

  @override
  String get automationTokenRemoveBody =>
      'La automatización que depende de este token se pausa hasta que se añada otro.';

  @override
  String automationTokenWorkspaceTarget(String forge) {
    return 'Cada repositorio de $forge sin token propio';
  }

  @override
  String repoAccessAutomationTokenMissingBody(String repos) {
    return 'Ningún token de automatización puede leer $repos, así que el trabajo en segundo plano allí está en pausa.';
  }

  @override
  String get settingsCommitsDescription =>
      'Los commits del trabajo que inicias llevan tu nombre. Elige a quién más se acredita y si las forjas muestran tus commits como verificados.';

  @override
  String get settingsCommitAuthorshipSection => 'Autoría';

  @override
  String get settingsCommitAuthorshipYoursLabel => 'Trabajo que inicias';

  @override
  String get settingsCommitAuthorshipYoursBody =>
      'Eres el autor y el committer, con el correo que tu forja verificó para tu inicio de sesión. Esto incluye los chats con agentes, las pipelines que inicias y los commits que haces en el editor.';

  @override
  String get settingsCommitAuthorshipBotLabel => 'Ejecuciones automáticas';

  @override
  String get settingsCommitAuthorshipBotBody =>
      'Las ejecuciones iniciadas por una programación o un webhook hacen commit como el bot y nunca se firman.';

  @override
  String get settingsCommitAuthorshipSignInNote =>
      'Hasta que inicies sesión en una forja de un espacio de trabajo, tus ejecuciones allí harán commit como el bot.';

  @override
  String get settingsCoauthorCreditTitle =>
      'Acreditar a Control Center como coautor';

  @override
  String get settingsCoauthorCreditDescription =>
      'Tus commits nombran a Control Center (@usectrl) como coautor, y las ejecuciones automáticas que activaste te nombran a ti. Si está desactivado, no se añade ninguna de las dos líneas.';

  @override
  String get settingsCoauthorCreditWorkspaceOverride =>
      'La configuración de este espacio de trabajo prevalece sobre tu elección personal. Tu preferencia se guarda, pero no se aplica aquí.';

  @override
  String get settingsCoauthorCreditLoading => 'Cargando ajustes de atribución…';

  @override
  String get settingsWorkspaceCoauthorCreditTitle => 'Crédito de coautoría';

  @override
  String get settingsWorkspaceCoauthorCreditDescription =>
      'Si los commits llevan líneas de coautoría: Control Center en los commits propios de un miembro, y los miembros que activaron una ejecución automática en sus commits. Una elección aquí anula la de cada miembro.';

  @override
  String get settingsWorkspaceCoauthorCreditInherit =>
      'Usar la preferencia de cada miembro';

  @override
  String get settingsWorkspaceCoauthorCreditAlways =>
      'Añadir siempre el crédito de coautoría';

  @override
  String get settingsWorkspaceCoauthorCreditNever =>
      'No añadir nunca el crédito de coautoría';

  @override
  String get settingsCommitSigningSection => 'Commits verificados';

  @override
  String get settingsCommitSigningStatusOn => 'Firmando';

  @override
  String get settingsCommitSigningStatusOff => 'Sin firmar';

  @override
  String get settingsCommitSigningIntro =>
      'Este servidor puede firmar tus commits con una clave propia, para que GitHub y GitLab los muestren como verificados. No se firma nada hasta que crees la clave.';

  @override
  String get settingsCommitSigningCreate => 'Crear clave de firma';

  @override
  String get settingsCommitSigningCreated =>
      'Clave de firma creada. Añádela a tu cuenta de la forja.';

  @override
  String get settingsCommitSigningPublicKeyLabel => 'Clave pública';

  @override
  String get settingsCommitSigningKeyCopied => 'Clave pública copiada';

  @override
  String get settingsCommitSigningFingerprintLabel => 'Huella digital';

  @override
  String get settingsCommitSigningCreatedLabel => 'Creada';

  @override
  String get settingsCommitSigningAddTitle => 'Añádela a tu cuenta de la forja';

  @override
  String get settingsCommitSigningAddDescription =>
      'Un commit solo se muestra como verificado mientras también tengas sesión iniciada en esa forja en el espacio de trabajo, así que la forja avala tu correo.';

  @override
  String get settingsCommitSigningGitHubSteps =>
      'Settings → SSH and GPG keys → New SSH key. Establece Key type en Signing Key.';

  @override
  String get settingsCommitSigningGitLabSteps =>
      'Preferences → SSH Keys. Establece Usage type en Signing.';

  @override
  String get settingsCommitSigningBitbucketSteps =>
      'Los commits en Bitbucket no se firman. No añadas esta clave a tu cuenta de Bitbucket: una clave SSH allí también es un inicio de sesión.';

  @override
  String get settingsCommitSigningUnsupported => 'No compatible';

  @override
  String get settingsCommitSigningTrustTitle => 'En qué confías';

  @override
  String get settingsCommitSigningTrustPrivate =>
      'La clave privada nunca sale de este servidor.';

  @override
  String get settingsCommitSigningTrustControl =>
      'Quien controle este servidor puede firmar commits en tu nombre mientras la clave esté en tu cuenta de la forja.';

  @override
  String get settingsCommitSigningTrustVerified =>
      'En GitHub, los commits que ya se muestran como verificados siguen verificados después de que quites la clave.';

  @override
  String get settingsCommitSigningDelete => 'Eliminar clave';

  @override
  String get settingsCommitSigningDeleteTitle => '¿Eliminar tu clave de firma?';

  @override
  String get settingsCommitSigningDeleteBody =>
      'A partir de ahora tus commits no se firman. La clave sigue en tus cuentas de la forja hasta que la quites allí.';

  @override
  String get settingsCommitSigningDeleted => 'Clave de firma eliminada';

  @override
  String settingsCommitSigningLoadFailed(String error) {
    return 'No se pudo cargar tu clave de firma: $error';
  }

  @override
  String get accountProfileTitle => 'Perfil';

  @override
  String get accountProfileDescription =>
      'Quién eres en cada espacio de trabajo, y tus propias cuentas de alojamiento de código, tickets, calendario y chat.';

  @override
  String get accountSectionTitle => 'Cuenta';

  @override
  String get accountSectionDescription =>
      'Tu nombre de usuario y tu nombre te siguen a cada espacio de trabajo. Un espacio de trabajo puede mostrar otro nombre o correo: configúralo en Espacio de trabajo → Perfil e identidad.';

  @override
  String accountLoadFailed(String error) {
    return 'No se pudo cargar tu perfil: $error';
  }

  @override
  String get accountDisplayNameHint =>
      'El nombre que la gente ve en tus mensajes y revisiones.';

  @override
  String get accountDisplayNameRequired => 'Introduce un nombre para mostrar.';

  @override
  String get accountFieldCannotBeCleared =>
      'Esto se puede cambiar, pero no eliminar.';

  @override
  String get accountAvatarLabel => 'Foto';

  @override
  String get accountAvatarHint =>
      'Un enlace a una imagen cuadrada que empiece por https://.';

  @override
  String get accountAvatarInvalid => 'Usa un enlace que empiece por https://.';

  @override
  String get usernameLabel => 'Nombre de usuario';

  @override
  String get usernameRule =>
      'De 2 a 32 caracteres: letras minúsculas, dígitos, puntos, guiones o guiones bajos. La gente te menciona con él.';

  @override
  String get usernameAvailable => 'Disponible.';

  @override
  String usernameAvailableAs(String username) {
    return 'Disponible. Se guardará como $username.';
  }

  @override
  String get usernameInvalid =>
      'Usa de 2 a 32 caracteres: letras minúsculas, dígitos, “.”, “_” o “-”, empezando y terminando con una letra o un dígito.';

  @override
  String get usernameReserved => 'Ese nombre de usuario está reservado.';

  @override
  String get usernameTaken => 'Ese nombre de usuario ya está en uso.';

  @override
  String get usernameCheckFailed =>
      'No se pudo comprobar este nombre ahora mismo. Aun así puedes guardar; el servidor decide.';

  @override
  String get linkedAccountsTitle => 'Cuentas conectadas';

  @override
  String get linkedAccountsIdentityProvider => 'Proveedor de identidad';

  @override
  String get linkedAccountStatusNeedsSignIn => 'Requiere inicio de sesión';

  @override
  String get linkedAccountStatusPaused => 'En pausa';

  @override
  String get linkedAccountStatusUnreachable => 'Inaccesible';

  @override
  String get ssoIdentityDescription =>
      'El proveedor de identidad con el que inicia sesión tu cuenta. Quien gestiona este servidor lo administra.';

  @override
  String get settingsAccountsDescription =>
      'Las cuentas que conectas para ti. Control Center actúa en tu nombre a través de ellas, y cambiarlas solo te afecta a ti.';

  @override
  String get accountReachServer =>
      'Se usa en todos los espacios de trabajo de este servidor.';

  @override
  String accountReachWorkspace(String workspace) {
    return 'Se usa solo en $workspace.';
  }

  @override
  String forgeReachGitHubOwnApp(String workspace) {
    return 'GitHub se usa solo en $workspace, que tiene sus propias apps de inicio de sesión. GitLab y Bitbucket se usan en todos los espacios de trabajo de este servidor.';
  }

  @override
  String get yourAccountLabel => 'Tu cuenta';

  @override
  String yourAccountEntry(String provider, String detail) {
    return '$provider: $detail';
  }

  @override
  String yourAccountLineSemantics(String status) {
    return 'Tu cuenta: $status. Abre Tú → Perfil.';
  }

  @override
  String get yourForgeAccountNone =>
      'No hay ninguna cuenta de alojamiento de código conectada';

  @override
  String yourAccountNotConnected(String provider) {
    return 'No hay ninguna cuenta de $provider conectada';
  }

  @override
  String yourChatAccountNotLinked(String provider) {
    return 'No hay ninguna cuenta de $provider vinculada';
  }

  @override
  String get demoUnavailableAccount =>
      'Eres un invitado temporal en la demo, así que no hay cuenta que cambiar: ni nombre de usuario, perfil ni cuentas conectadas.';

  @override
  String get onboardingStepYou => 'Tú';

  @override
  String get onboardingYouTitle => 'Elige tu nombre de usuario';

  @override
  String get onboardingYouSubtitle =>
      'Tu nombre de usuario es la forma en que te mencionan y en que se etiqueta tu trabajo. Puedes cambiarlo, junto con tu nombre para mostrar, más tarde en Ajustes → Tú → Perfil.';

  @override
  String signInErrorAccountAlreadyBound(String provider) {
    return 'Esta cuenta de $provider ya está conectada a otra persona en este servidor. Inicia sesión con otra cuenta de $provider.';
  }

  @override
  String forgeTokenExpiresOn(String date) {
    return 'El token caduca el $date';
  }

  @override
  String forgeTokenExpiredOn(String date) {
    return 'El token caducó el $date. Pega uno nuevo para seguir trabajando.';
  }

  @override
  String personTokenUnreachable(String forge) {
    return 'No se pudo contactar con $forge para comprobar este token. Inténtalo de nuevo en un momento.';
  }

  @override
  String personTokenRejected(String forge) {
    return '$forge no acepta este token. Comprueba que lo copiaste completo y que no ha sido revocado.';
  }

  @override
  String personTokenWrongKind(String forge) {
    return 'Este no es un token personal. Pega un token de acceso personal de tu propia cuenta de $forge, no un token de proyecto, grupo, espacio de trabajo o bot.';
  }

  @override
  String personTokenNarrowScope(String scope) {
    return 'Este token no tiene el permiso $scope, que necesitan la revisión y los comentarios. Crea uno que lo incluya.';
  }

  @override
  String get personTokenExpired =>
      'Este token ha caducado. Crea uno nuevo y pégalo aquí.';

  @override
  String get settingsCommitSigningTrustAgents =>
      'Los agentes que inicias pueden hacer commits firmados en tu nombre, en cualquier repositorio en el que trabajen. Eliminar la clave aquí lo detiene de inmediato: las ejecuciones en curso ya no firman nada más.';

  @override
  String connectRotateKeyFailed(String error) {
    return 'No se rotó la clave y no cambió nada: $error Inténtalo de nuevo.';
  }

  @override
  String get noWorkspaceInviteTitle =>
      'Todavía no estás en un espacio de trabajo';

  @override
  String get noWorkspaceInviteBody =>
      'Un administrador del espacio de trabajo tiene que invitarte, o el propietario del servidor puede crear un espacio de trabajo para ti. Se abrirá aquí en cuanto te añadan.';

  @override
  String noWorkspaceSignedInAs(String name) {
    return 'Has iniciado sesión como $name';
  }

  @override
  String get noWorkspaceCheckAgain => 'Volver a comprobar';

  @override
  String get noWorkspaceSignOut => 'Cerrar sesión';

  @override
  String get workspaceCreateOwnerOnly =>
      'Solo el propietario del servidor puede crear espacios de trabajo. Pídele que cree uno o pide a un administrador del espacio de trabajo que te invite.';

  @override
  String repoLinkNoWorkspaceToAddTo(String repo) {
    return '$repo no está en ninguno de tus espacios de trabajo, y no estás en un espacio de trabajo al que añadirlo. Pide a un administrador del espacio de trabajo que te invite.';
  }

  @override
  String get serverOwnerOnly =>
      'Solo el propietario del servidor puede hacer esto';

  @override
  String get ideCodeServerOwnerOnlyHint =>
      'El editor completo se ejecuta en la propia máquina del servidor, así que solo su propietario puede abrirlo. Aún puedes abrir y editar archivos desde el Explorador.';

  @override
  String get terminalSandboxedBadge => 'En sandbox';

  @override
  String get terminalSandboxedHint =>
      'Se ejecuta en un sandbox dentro de las carpetas de este espacio de trabajo, así que algunas herramientas y rutas del host no están disponibles aquí.';

  @override
  String get terminalHostShellOwnerOnly =>
      'El shell del host se ejecuta en el servidor sin sandbox, así que solo su propietario puede abrir uno. Una terminal normal se ejecuta en el sandbox.';

  @override
  String get terminalOutsideWorkspace =>
      'Una terminal solo puede abrirse dentro de las carpetas propias de este espacio de trabajo.';

  @override
  String get environmentHostOwnerOnly =>
      'Solo el propietario del servidor puede guardar o aprobar un entorno que se ejecuta en el host del servidor. Un administrador del espacio de trabajo puede usar uno que se ejecute en un rig.';

  @override
  String get settingsCommitsNoHooks =>
      'Los commits que haces en el editor de la aplicación no ejecutan los hooks de Git del repositorio, igual que con git commit --no-verify: el servidor ejecuta Git en su propio host, en un árbol que los agentes y los pull requests pueden cambiar.';

  @override
  String get mcpTokenDescription =>
      'Los clientes MCP envían este token en cada solicitud, como cabecera Authorization: Bearer. El servidor lo crea en el primer inicio; puedes rotarlo, pero no eliminarlo.';

  @override
  String get mcpShowToken => 'Mostrar token';

  @override
  String get mcpHideToken => 'Ocultar token';

  @override
  String get mcpRotateToken => 'Rotar token';

  @override
  String get mcpRotateTokenTitle => '¿Rotar el token de MCP?';

  @override
  String get mcpRotateTokenBody =>
      'El servidor cambia de inmediato a un token nuevo. Cada cliente MCP que siga usando el actual será rechazado hasta que le des el nuevo.';

  @override
  String get mcpTokenRotated =>
      'Token rotado. Entrega el nuevo a tus clientes MCP.';

  @override
  String get mcpOwnerOnlyTitle =>
      'El endpoint de MCP es para el propietario del servidor';

  @override
  String get mcpOwnerOnlyBody =>
      'Su token abre todas las herramientas de este servidor, así que solo el propietario del servidor puede verlo, rotarlo o iniciar y detener el endpoint.';

  @override
  String get activityRotatedMcpToken => 'Rotó el token de MCP';

  @override
  String get connectRotateKeyRetireFailedTitle =>
      'Connect no pudo retirar la clave anterior';

  @override
  String get connectRotateKeyForceBody =>
      'No ha cambiado nada. Si rotas de todos modos, este servidor recibe su clave nueva, pero la identidad anterior sigue siendo válida en ese Connect hasta que caduquen sus inicios de sesión.';

  @override
  String get connectRotateKeyAnyway => 'Rotar de todos modos';

  @override
  String get settingsAuditLog => 'Registro de auditoría';

  @override
  String get settingsAuditLogDescription =>
      'Quién cambió qué, dónde y con qué resultado, en el servidor y en cada espacio de trabajo que administras. Las operaciones del servidor registran los nombres de los argumentos, nunca sus valores.';

  @override
  String get auditLogNoAccessTitle => 'Solo administradores';

  @override
  String get auditLogNoAccess =>
      'El registro de auditoría cubre el servidor y los espacios de trabajo que administras. No administras ningún espacio de trabajo, así que no hay nada que mostrar.';

  @override
  String get auditLogSourceServer => 'Servidor';

  @override
  String get auditLogSourceWorkspace => 'Espacio de trabajo';

  @override
  String get auditLogAddFilter => 'Filtrar';

  @override
  String get auditLogFilterOptionsHint => 'Filtrar…';

  @override
  String get auditLogFilterActor => 'Actor';

  @override
  String get auditLogFilterSource => 'Espacio de trabajo';

  @override
  String get auditLogFilterOutcome => 'Resultado';

  @override
  String get auditLogFilterTime => 'Fecha y hora';

  @override
  String auditLogFilterChip(String category, String values) {
    return '$category: $values';
  }

  @override
  String auditLogFilterChipMore(String values, int count) {
    return '$values +$count';
  }

  @override
  String get auditLogOutcomeOk => 'Correcto';

  @override
  String get auditLogOutcomeDenied => 'Denegado';

  @override
  String get auditLogOutcomeFailed => 'Fallido';

  @override
  String get auditLogTimeAtOrAfter => 'A partir de';

  @override
  String get auditLogTimeAfter => 'Después de';

  @override
  String get auditLogTimeBefore => 'Antes de';

  @override
  String get auditLogTimeAtOrBefore => 'Hasta';

  @override
  String auditLogTimeChip(String operator, String time) {
    return 'Hora $operator $time';
  }

  @override
  String get auditLogTimePresetHour => 'Hace 1 hora';

  @override
  String get auditLogTimePresetDay => 'Hace 24 horas';

  @override
  String get auditLogTimePresetWeek => 'Hace 7 días';

  @override
  String get auditLogTimePresetMonth => 'Hace 30 días';

  @override
  String get auditLogTimeExact => 'Fecha y hora exactas';

  @override
  String get auditLogTimeInvalid => 'Usa YYYY-MM-DD, opcionalmente con HH:MM';

  @override
  String get auditLogTimeAdd => 'Añadir';

  @override
  String repoAccessReplacedTitle(String repo) {
    return '$repo ahora apunta a un repositorio distinto';
  }

  @override
  String repoAccessReplacedBody(String forge) {
    return 'Esta ruta ahora apunta a un repositorio distinto en $forge. Vuelve a vincularla para seguir usándola.';
  }

  @override
  String get repoRelink => 'Volver a vincular';

  @override
  String repoRelinked(String repo) {
    return 'Se ha vuelto a vincular $repo.';
  }

  @override
  String get repoCodeRepoReplaced =>
      'Esta ruta ahora apunta a un repositorio distinto. Un administrador del espacio de trabajo tiene que volver a vincularla antes de poder usarla.';

  @override
  String repoCodeForgeCannotRead(String forge) {
    return 'Tu cuenta de $forge no puede leer este repositorio.';
  }

  @override
  String repoCodeForgeUnconfirmed(String forge) {
    return 'No se pudo confirmar tu acceso a $forge. Inténtalo de nuevo.';
  }

  @override
  String get repoCodeForgeCannotReadUnnamed =>
      'Tu cuenta de la forja no puede leer este repositorio.';

  @override
  String get repoCodeForgeUnconfirmedUnnamed =>
      'No se pudo confirmar tu acceso a la forja. Inténtalo de nuevo.';

  @override
  String get repoPathHostPath =>
      'Solo el propietario del servidor puede vincular una carpeta fuera del almacenamiento de este espacio de trabajo.';

  @override
  String get repoPathMissing => 'No existe nada en esa ruta del servidor.';

  @override
  String get repoPathDataDir =>
      'Un repositorio no puede apuntar a la carpeta de datos del servidor.';

  @override
  String get repoPathWorkspaceRoot =>
      'Un repositorio no puede ser la carpeta propia del espacio de trabajo.';

  @override
  String get repoPathOriginMismatch =>
      'El origin de esa carpeta es otro repositorio.';

  @override
  String repoGrantNeedsSignIn(String forge) {
    return 'Guardado. Necesitan iniciar sesión en $forge antes de poder abrir este repositorio.';
  }

  @override
  String repoGrantCannotRead(String forge) {
    return 'Guardado. Su cuenta de $forge todavía no puede leer este repositorio, así que sigue oculto para ellos.';
  }

  @override
  String repoGrantUnconfirmed(String forge) {
    return 'Guardado. Ahora mismo no se pudo confirmar su acceso a $forge.';
  }

  @override
  String repoLinkAskOwnerToAdd(String repo) {
    return '$repo no está vinculado en ninguno de tus espacios de trabajo. Pide al propietario del servidor que lo añada.';
  }

  @override
  String get reposEmptyAskOwner =>
      'El propietario del servidor añade repositorios desde las carpetas del servidor.';

  @override
  String get accountEmailUnconfirmedHint =>
      'Solo tú has introducido esta dirección. El inicio de sesión único no la reconocerá hasta que el propietario del servidor la confirme.';

  @override
  String get settingsServerPeople => 'Personas';

  @override
  String get settingsServerPeopleDescription =>
      'Todas las personas con una cuenta en este servidor, y si su correo está confirmado.';

  @override
  String get serverPeopleLabel => 'Cuentas';

  @override
  String get serverPeopleOwnerOnly =>
      'Solo el propietario del servidor puede ver las cuentas de todos y confirmar correos.';

  @override
  String get serverPeopleEmailNotConfirmed => 'Correo no confirmado';

  @override
  String get serverPeopleConfirmEmail => 'Confirmar correo';

  @override
  String serverPeopleConfirmEmailBody(String email, String name) {
    return '¿Confirmar que $email pertenece a $name? El inicio de sesión único asociará esta dirección a su cuenta.';
  }

  @override
  String serverPeopleEmailConfirmed(String email) {
    return 'Correo confirmado: $email.';
  }

  @override
  String get runSandboxUnavailableTitle =>
      'Los agentes necesitan un sandbox en este servidor';

  @override
  String get runSandboxUnavailable =>
      'Este servidor no tiene sandbox, así que solo su propietario puede ejecutar agentes aquí. El propietario puede instalar el sandbox o desactivar el sandboxing para todos.';

  @override
  String get repoPathIssueHostPath =>
      'Esta carpeta está fuera del almacenamiento del espacio de trabajo. Confirma que este servidor puede usarla.';

  @override
  String get repoPathIssueHostPathAskOwner =>
      'Esta carpeta está fuera del almacenamiento del espacio de trabajo. Solo el propietario del servidor puede confirmarla.';

  @override
  String get repoPathIssueMissing =>
      'Ya no existe nada en esta ruta del servidor. Elimina este repositorio y añádelo de nuevo desde su carpeta actual.';

  @override
  String get repoPathIssueUnusable =>
      'Esta carpeta no puede usarse como repositorio. Elimínala y añade el repositorio desde otra carpeta.';

  @override
  String get repoPathConfirm => 'Confirmar';

  @override
  String get repoPathConfirmAll => 'Confirmar todo';

  @override
  String repoPathConfirmAllTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count carpetas están fuera del almacenamiento del espacio de trabajo',
      one: '1 carpeta está fuera del almacenamiento del espacio de trabajo',
    );
    return '$_temp0';
  }

  @override
  String get repoPathConfirmAllBody =>
      'Confirma que este servidor puede usarlas. Cada repositorio se vuelve a comprobar con tu acceso.';

  @override
  String repoCodeNeedsSignIn(String provider) {
    return 'Inicia sesión en $provider para ver el código de este repositorio.';
  }

  @override
  String get repoCodeSignIn => 'Iniciar sesión';

  @override
  String get ideContentSearchFailed => 'No se pudo buscar en los archivos';

  @override
  String get ideWorktreeFileUnavailable =>
      'Este archivo no está disponible en este worktree.';

  @override
  String get ideChangesLoadFailed => 'No se pudieron cargar los cambios';

  @override
  String repoCodeRepoReplacedOn(String forge) {
    return 'Esta ruta ahora apunta a un repositorio distinto en $forge. Un administrador del espacio de trabajo tiene que volver a vincularla antes de poder usarla.';
  }

  @override
  String get backupRestoreServerOwnerOnly =>
      'Solo el propietario del servidor puede restaurar copias de seguridad. Aún puedes descargarlas.';

  @override
  String get terminalReadOnlyBadge => 'Solo lectura';

  @override
  String get terminalReadOnlyHint =>
      'Puedes ver esta terminal. Escribir en ella, cambiar su tamaño o detenerla requiere permiso de escritura en cada repositorio de esta conversación.';

  @override
  String get environmentOperateNeedsWrite =>
      'Puedes ver este entorno. Iniciarlo, detenerlo o reiniciarlo requiere permiso de escritura en cada repositorio de la conversación.';

  @override
  String get environmentHostApprovalOwner =>
      'Se ejecuta en este servidor. Apruébalo para permitir que se inicie.';

  @override
  String get environmentHostApprovalMember =>
      'Se ejecuta en este servidor. El propietario del servidor tiene que aprobarlo antes de que pueda iniciarse.';

  @override
  String get environmentHostApprove => 'Aprobar';

  @override
  String get environmentHostApproveNeedsAdmin =>
      'Apruébalo como administrador del espacio de trabajo: solo la copia de un administrador muestra sus valores secretos, y al aprobar se guardan de nuevo.';

  @override
  String get environmentHostUnapproved =>
      'El propietario del servidor todavía no ha aprobado este entorno, así que no puede ejecutarse en este servidor.';

  @override
  String get environmentHostUnapprovedOwner =>
      'Todavía no has aprobado este entorno. Se ejecuta en este servidor, así que se iniciará en cuanto apruebes su definición.';

  @override
  String get environmentHostApprovalReview => 'Revisar y aprobar';

  @override
  String spaceAccessNeedsSignIn(String provider) {
    return 'Inicia sesión en $provider para abrir este espacio.';
  }

  @override
  String spaceAccessForgeCannotRead(String forge) {
    return 'Tu cuenta de $forge no puede leer un repositorio que usa este espacio.';
  }

  @override
  String get spaceAccessForgeCannotReadUnnamed =>
      'Tu cuenta de la forja no puede leer un repositorio que usa este espacio.';

  @override
  String get spaceAccessNoGrant =>
      'No tienes acceso de lectura a un repositorio que usa este espacio. Un administrador del espacio de trabajo puede concedértelo.';

  @override
  String get spaceAccessFailed => 'No se pudo abrir este espacio.';

  @override
  String get contextExplorerRefused =>
      'El desglose del contexto no está disponible en esta sesión.';

  @override
  String get repoLinkForgeRemoteRequired =>
      'Un repositorio vinculado necesita un propietario y un nombre de repositorio.';

  @override
  String get repoCodeNoReadGrant =>
      'No tienes acceso de lectura a este repositorio. Un administrador del espacio de trabajo puede concederlo.';

  @override
  String get repoCodeNoWriteGrant =>
      'Puedes leer este repositorio, pero no modificarlo. Un administrador del espacio de trabajo puede conceder acceso de escritura.';

  @override
  String get repoCodeNoReviewGrant =>
      'Puedes leer este repositorio, pero no revisarlo. Un administrador del espacio de trabajo puede conceder acceso de revisión.';

  @override
  String get rigWatchOnlyBadge => 'Solo visualización';

  @override
  String get rigWatchOnlyHint =>
      'Puedes ver esta máquina. Controlarla, reenviar sus puertos, pegar en ella o soltar archivos en ella requiere acceso de escritura a todos los repositorios de este espacio.';

  @override
  String get rigStartNeedsWrite =>
      'Iniciar una máquina aquí requiere acceso de escritura a todos los repositorios de este espacio. Un administrador del espacio de trabajo puede concederlo.';

  @override
  String get rigViewRefused =>
      'No puedes ver esta máquina. Pertenece a un espacio al que no tienes acceso de lectura.';

  @override
  String get rigPortsWatchOnly =>
      'Cambiar estos puertos requiere acceso de escritura a todos los repositorios de este espacio.';

  @override
  String get rigHolderOnly =>
      'Solo la persona para la que se abrió esta máquina puede controlarla. Usa sus propios inicios de sesión.';

  @override
  String get rigHolderOnlyHint =>
      'Puedes ver esta máquina. Usa los inicios de sesión de la persona para la que se abrió, así que solo ella puede controlarla, reenviar sus puertos, pegar contenido en ella o soltar archivos en ella.';

  @override
  String get refusalStorageBusy =>
      'La base de datos del servidor está ocupada en este momento. Inténtalo de nuevo en un momento.';

  @override
  String get refusalStorageFull =>
      'El servidor se ha quedado sin espacio en disco, así que no se puede guardar nada. El propietario del servidor tiene que liberar algo de espacio.';

  @override
  String get refusalStorageDamaged =>
      'Los datos de este espacio de trabajo están dañados. El propietario del servidor tiene que restaurarlos desde una copia de seguridad.';

  @override
  String get refusalStorageReadOnly =>
      'Este espacio de trabajo es de solo lectura hasta que el propietario del servidor lo restaure desde una copia de seguridad, así que los cambios no se pueden guardar.';

  @override
  String get refusalStorageNewerSchema =>
      'Estos datos los escribió una versión más reciente del servidor. Actualiza el servidor y vuelve a intentarlo.';

  @override
  String get refusalStorageForeignFile =>
      'El servidor encontró un archivo de base de datos que no escribió. El propietario del servidor tiene que revisar la carpeta de datos del servidor.';

  @override
  String get refusalWorkspaceDeleted =>
      'Este espacio de trabajo se ha eliminado.';

  @override
  String get refusalIdempotencyInProgress =>
      'Esta solicitud todavía se está procesando. Espera a que termine y luego comprueba el resultado.';

  @override
  String get refusalImportMissingSource =>
      'No hay ningún archivo en esa ruta del servidor. No se ha reemplazado nada.';

  @override
  String get refusalImportDamaged =>
      'Ese archivo está dañado, así que no se puede restaurar. No se ha reemplazado nada.';

  @override
  String get refusalImportChecksumMismatch =>
      'Ese archivo no coincide con la suma de comprobación que registró su copia de seguridad, así que puede que se haya modificado o dañado. No se ha reemplazado nada.';

  @override
  String get refusalImportNewerSchema =>
      'Ese archivo lo escribió una versión más reciente del servidor. Actualiza el servidor para restaurarlo. No se ha reemplazado nada.';

  @override
  String get refusalImportForeignFile =>
      'Ese archivo no es una base de datos de espacio de trabajo. No se ha reemplazado nada.';

  @override
  String get refusalImportSchemaMismatch =>
      'Ese archivo no se pudo adaptar al formato de este servidor. No se ha reemplazado nada.';

  @override
  String get refusalImportRouteConflict =>
      'Ese archivo contiene enlaces que pertenecen a otro espacio de trabajo de este servidor, y restaurarlo se los quitaría. No se ha reemplazado nada.';

  @override
  String get workspaceReadOnlyBannerTitle =>
      'Este espacio de trabajo es de solo lectura';

  @override
  String get workspaceReadOnlyBannerBody =>
      'Sus datos no superaron una comprobación de integridad, así que no se pueden guardar cambios. Todo sigue siendo legible. El propietario del servidor puede restaurarlo desde una copia de seguridad.';

  @override
  String get workspaceReadOnlyBannerOwnerBody =>
      'Sus datos no superaron una comprobación de integridad, así que no se pueden guardar cambios. Todo sigue siendo legible. Restáuralo desde una copia de seguridad para que vuelva a ser editable.';

  @override
  String get workspaceReadOnlyBannerAction => 'Abrir copias de seguridad';

  @override
  String get serverNoticesLabel => 'Necesita tu atención';

  @override
  String get serverNoticeReadOnlyStatus => 'Solo lectura';

  @override
  String serverNoticeSince(String time) {
    return 'Desde $time';
  }

  @override
  String get serverNoticeReadOnlyBody =>
      'Su base de datos no superó una comprobación de integridad, así que solo permite lectura y rechaza todos los cambios. Restáurala desde una copia de seguridad de la lista de abajo; su última copia válida se conserva hasta que lo hagas.';

  @override
  String get serverNoticeDetails => 'Detalles';

  @override
  String get backupSnapshotUnverified => 'Sin verificar';

  @override
  String get backupSnapshotUnverifiedNote =>
      'Esta instantánea no se puede verificar. No terminó, o se hizo antes de que las instantáneas registraran sumas de comprobación, así que no puede restaurar toda la instalación. Los archivos de espacios de trabajo que contiene aún se pueden restaurar uno por uno.';

  @override
  String get backupSnapshotLastGoodCopy => 'Última copia válida';

  @override
  String get backupSnapshotLastGoodCopyNote =>
      'Se conserva porque contiene la última copia válida de un espacio de trabajo dañado. La limpieza no la toca hasta que ese espacio de trabajo se restaure.';

  @override
  String get backupDeleteLastGoodCopyDescription =>
      'Es la última copia válida de un espacio de trabajo dañado. Si la eliminas, no quedará nada desde lo que restaurar ese espacio de trabajo.';

  @override
  String backupRestoreHeldBack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count permisos se retuvieron para tu revisión. Aparecen en la parte superior de esta página.',
      one:
          '1 permiso se retuvo para tu revisión. Aparece en la parte superior de esta página.',
    );
    return '$_temp0';
  }

  @override
  String get importHoldsLabel => 'Retenidos de las copias restauradas';

  @override
  String get importHoldsExplainer =>
      'Una copia restaurada no puede conceder nada por sí sola en este servidor. Estos permisos estaban en ella: acepta uno para volver a concederlo, o recházalo para eliminarlo.';

  @override
  String importHoldPolicyAllow(String action) {
    return 'Los agentes pueden hacer esto sin aprobación: $action';
  }

  @override
  String importHoldPolicyPrompt(String action) {
    return 'Los agentes pueden hacer esto cuando una persona lo apruebe: $action';
  }

  @override
  String importHoldCommand(String command) {
    return 'Ejecutar comandos que empiezan por $command';
  }

  @override
  String get importHoldScopeWorkspace => 'En todo este espacio de trabajo';

  @override
  String importHoldScopeSpace(String space) {
    return 'En el espacio $space';
  }

  @override
  String importHoldScopeAgent(String agent) {
    return 'Para el agente $agent';
  }

  @override
  String importHoldSandboxExec(String path) {
    return 'Los entornos aislados pueden ejecutar $path';
  }

  @override
  String importHoldRepoWrite(String person, String repo) {
    return '$person puede modificar $repo';
  }

  @override
  String importHoldRepoReview(String person, String repo) {
    return '$person puede revisar pull requests en $repo';
  }

  @override
  String importHoldRepoOther(String person, String repo, String level) {
    return '$person obtiene acceso $level a $repo';
  }

  @override
  String importHoldMemberRole(String person, String role) {
    return '$person obtiene el rol $role';
  }

  @override
  String importHoldInvite(String role) {
    return 'Una invitación abierta para unirse con el rol $role';
  }

  @override
  String importHoldInviteWithRepos(int count, String role) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Una invitación abierta para unirse con el rol $role y acceso de revisión o escritura a $count repositorios',
      one:
          'Una invitación abierta para unirse con el rol $role y acceso de revisión o escritura a 1 repositorio',
    );
    return '$_temp0';
  }

  @override
  String get importHoldUnknown =>
      'Un permiso que esta versión de la app no puede describir';

  @override
  String importHoldRestoredAt(String time) {
    return 'Restaurado $time';
  }

  @override
  String get importHoldAccept => 'Aceptar';

  @override
  String get importHoldDismiss => 'Rechazar';

  @override
  String get importHoldAcceptTitle => '¿Conceder este permiso?';

  @override
  String importHoldAcceptBody(String permission) {
    return '$permission\n\nAl aceptarlo se concede de inmediato en el servidor.';
  }

  @override
  String get importHoldAccepted => 'Permiso concedido.';

  @override
  String get importHoldNotApplied =>
      'No se concedió nada: la persona o el elemento al que correspondía ya no está en este espacio de trabajo.';

  @override
  String get mcpWorkspaceServers => 'Servidores MCP del espacio de trabajo';

  @override
  String get mcpWorkspaceServersDescription =>
      'Cada ejecución de agente de este espacio de trabajo recibe las herramientas de estos servidores, tanto en Claude Code como en el arnés integrado. Control Center se conecta a cada servidor y pasa sus herramientas.';

  @override
  String get mcpWorkspaceServersAdminsOnly =>
      'Solo los administradores del espacio de trabajo pueden ver y cambiar los servidores MCP de este espacio de trabajo.';

  @override
  String get mcpWorkspaceServersUnavailable =>
      'Los servidores MCP del espacio de trabajo no están disponibles en el servidor conectado.';

  @override
  String get mcpWorkspaceServersEmpty =>
      'Todavía no hay servidores MCP del espacio de trabajo';

  @override
  String get mcpWorkspaceServersEmptyDescription =>
      'Añade un servidor para que cada ejecución de agente de este espacio de trabajo tenga sus herramientas.';

  @override
  String get mcpAddServer => 'Añadir servidor';

  @override
  String get mcpStatusAwaitingApproval => 'Pendiente de aprobación';

  @override
  String get mcpPublicAddressesOnly => 'Solo direcciones públicas';

  @override
  String get mcpApproveServer => 'Aprobar';

  @override
  String get mcpApprovalStdioOwner =>
      'Este servidor ejecuta un comando en el equipo del servidor, como el usuario del servidor. No se iniciará hasta que lo apruebes.';

  @override
  String get mcpApprovalStdioMember =>
      'Este servidor ejecuta un comando en el equipo del servidor, así que no se iniciará hasta que lo apruebe el propietario del servidor.';

  @override
  String get mcpApprovalRemoteOwner =>
      'Este servidor solo puede acceder a direcciones públicas. Apruébalo para que también pueda acceder a la red privada del equipo, como localhost y la red local.';

  @override
  String get mcpApprovalRemoteMember =>
      'Este servidor solo puede acceder a direcciones públicas hasta que lo apruebe el propietario del servidor.';

  @override
  String get mcpServersSettingsSubtitle =>
      'El servidor MCP integrado y los servidores MCP cuyas herramientas reciben las ejecuciones de agente de este espacio de trabajo.';

  @override
  String get mcpPersonalServers => 'Tus servidores MCP';

  @override
  String get mcpPersonalServersDescription =>
      'Solo tú ves estos servidores, y solo las ejecuciones de agente que inicies en este espacio de trabajo reciben sus herramientas.';

  @override
  String get mcpPersonalServersUnavailable =>
      'Tus servidores MCP no están disponibles en el servidor conectado.';

  @override
  String get mcpPersonalServersEmpty => 'Todavía no tienes servidores MCP';

  @override
  String get mcpPersonalServersEmptyDescription =>
      'Añade un servidor para que las ejecuciones que inicies en este espacio de trabajo tengan sus herramientas.';

  @override
  String get mcpServerEditorPersonalOwner =>
      'Solo lo usan las ejecuciones que inicias en este espacio de trabajo. Como propietario del servidor, al guardarlo queda aprobado.';

  @override
  String get mcpServerEditorPersonalMember =>
      'Solo lo usan las ejecuciones que inicias en este espacio de trabajo. Solo puede acceder a direcciones públicas.';

  @override
  String get mcpServerSignInNeeded =>
      'Inicia sesión para usar las herramientas de este servidor.';

  @override
  String get mcpServerSignIn => 'Iniciar sesión';

  @override
  String mcpServerSignInTitle(String name) {
    return 'Iniciar sesión en $name';
  }

  @override
  String mcpServerSignInWrongCode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quedan $count intentos.',
      one: 'Queda 1 intento.',
    );
    return 'Ese no es el código que mostró tu navegador. $_temp0';
  }

  @override
  String get mcpServerSignInEnded =>
      'Se agotó el tiempo, se rechazó el inicio de sesión o introdujiste demasiados códigos incorrectos. Vuelve a empezar para obtener una nueva página de inicio de sesión.';

  @override
  String get mcpServerSignInStartAgain => 'Empezar de nuevo';

  @override
  String mcpServerSignedIn(String name) {
    return 'Has iniciado sesión en $name.';
  }

  @override
  String get mcpRemoveServer => 'Quitar servidor';

  @override
  String mcpRemoveServerTitle(String name) {
    return '¿Quitar $name?';
  }

  @override
  String get mcpRemoveServerBody =>
      'Las ejecuciones de agentes pierden las herramientas de este servidor, y sus valores secretos guardados se eliminan.';

  @override
  String mcpServerEnabledToggle(String name) {
    return 'Activar o desactivar $name';
  }

  @override
  String get mcpServerEditorAddTitle => 'Añadir servidor MCP';

  @override
  String mcpServerEditorEditTitle(String name) {
    return 'Editar $name';
  }

  @override
  String get mcpServerNameHelper =>
      'Letras, dígitos, guiones y guiones bajos. Los agentes ven sus herramientas con este nombre.';

  @override
  String get mcpServerNameInvalid =>
      'Usa hasta 24 letras, dígitos, guiones o guiones bajos, empezando por una letra o un dígito.';

  @override
  String get mcpServerNameTaken => 'Ya hay otro servidor aquí con este nombre.';

  @override
  String get mcpServerTransportLabel => 'Transporte';

  @override
  String get mcpServerTransportStdio => 'Comando';

  @override
  String get mcpServerTransportHttp => 'HTTP';

  @override
  String get mcpServerTransportSse => 'SSE';

  @override
  String get mcpServerCommandLabel => 'Comando';

  @override
  String get mcpServerCommandRequired =>
      'Introduce el comando que se va a ejecutar.';

  @override
  String get mcpServerArgsLabel => 'Argumentos';

  @override
  String get mcpServerArgsHelper => 'Un argumento por línea.';

  @override
  String get mcpServerUrlLabel => 'URL';

  @override
  String get mcpServerUrlInvalid =>
      'Introduce una URL http o https sin nombre de usuario, contraseña ni #fragmento.';

  @override
  String get mcpServerEnvLabel => 'Variables de entorno';

  @override
  String get mcpServerHeadersLabel => 'Encabezados';

  @override
  String get mcpServerSecretsDescription =>
      'Los valores se guardan como secretos y no volverán a mostrarse.';

  @override
  String get mcpServerHeadersExample =>
      'Por ejemplo, un encabezado Authorization con un token de portador.';

  @override
  String get mcpServerEnvAdd => 'Añadir variable';

  @override
  String get mcpServerHeaderAdd => 'Añadir encabezado';

  @override
  String get mcpServerSecretValueHint => 'Valor';

  @override
  String get mcpServerSecretNewValueHint => 'Nuevo valor';

  @override
  String get mcpServerSecretReplace => 'Reemplazar valor';

  @override
  String get mcpServerSecretUndo => 'Deshacer';

  @override
  String get mcpServerSecretRemovedOnSave => 'Se quitará al guardar';

  @override
  String mcpServerEnvNameInvalid(String name) {
    return '$name no es un nombre de variable válido. Usa letras, dígitos y guiones bajos, sin empezar por un dígito.';
  }

  @override
  String mcpServerHeaderNameInvalid(String name) {
    return 'No se puede usar $name. Usa un nombre de encabezado válido que la conexión no gestione por sí misma.';
  }

  @override
  String get mcpServerTransportDropsValues =>
      'Cambiar el transporte elimina los valores guardados.';

  @override
  String get mcpServerEnabledDescription =>
      'Cuando está desactivado, el servidor no se inicia y los agentes no ven sus herramientas.';

  @override
  String get mcpServerEditorStdioMember =>
      'Se ejecuta en el equipo del servidor, así que no se iniciará hasta que lo apruebe el propietario del servidor. Cambiar la forma de iniciarlo vuelve a pedir aprobación.';

  @override
  String get mcpServerEditorRemoteMember =>
      'Solo puede acceder a direcciones públicas hasta que lo apruebe el propietario del servidor. Cambiar la forma de conectarlo vuelve a pedir aprobación.';

  @override
  String get mcpServerEditorStdioOwner =>
      'Se ejecuta en el equipo del servidor como el usuario del servidor. Al guardar, queda aprobado.';

  @override
  String get mcpServerEditorRemoteOwner =>
      'Al guardar, queda aprobado para acceder también a la red privada del equipo.';

  @override
  String get mcpServerRefusedInvalid =>
      'Control Center no pudo guardar este servidor. Revisa su configuración e inténtalo de nuevo.';

  @override
  String get mcpServerNotFound =>
      'Este servidor ya no existe. Es posible que alguien lo haya quitado.';

  @override
  String get scriptToolCalls => 'Llamadas a herramientas';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count llamadas',
      one: '1 llamada',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count en ejecución';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count correctas';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count con error';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count denegadas';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count canceladas';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count en cola';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count omitidas';
  }

  @override
  String get scriptStepQueued => 'En cola';

  @override
  String get scriptStepSkipped => 'Omitida';

  @override
  String get scriptGroupLoop => 'Bucle';

  @override
  String get scriptGroupEach => 'Para cada uno';

  @override
  String get scriptGroupParallel => 'En paralelo';

  @override
  String get scriptGroupFunction => 'Función';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mostrar $count llamadas más',
      one: 'Mostrar 1 llamada más',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced => 'Llamadas no colocadas en el script';

  @override
  String get scriptToolComputed => 'Herramienta';

  @override
  String scriptStepSemantics(String subject, String state) {
    return '$subject, $state';
  }

  @override
  String get scriptSourceLabel => 'Script';

  @override
  String scriptSourceLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count líneas',
      one: '1 línea',
    );
    return '$_temp0';
  }

  @override
  String get scriptStateRunning => 'En ejecución';

  @override
  String get scriptStateCompleted => 'Completado';

  @override
  String get scriptStateFailed => 'Error';

  @override
  String get scriptStateTimedOut => 'Tiempo agotado';

  @override
  String get scriptStateCancelled => 'Cancelado';

  @override
  String get scriptStateMemoryExceeded => 'Sin memoria';

  @override
  String get scriptStateOutputExceeded => 'Demasiada salida';

  @override
  String get scriptStateSandboxError => 'Error del entorno aislado';

  @override
  String get scriptStateRefused => 'Rechazado';

  @override
  String get transcriptToolDenied => 'Denegado';

  @override
  String get transcriptStatusRunningScript => 'Ejecutando un script…';

  @override
  String get scriptOriginLine =>
      'Desde un script que el agente está ejecutando';

  @override
  String get scriptOriginShow => 'Mostrar script';

  @override
  String get codeModeTitle => 'Modo código';

  @override
  String get codeModeSubtitle =>
      'Los agentes pueden escribir un script corto que llame a sus herramientas en lugar de llamarlas una a una.';

  @override
  String get codeModeStatusLabel => 'Estado';

  @override
  String get codeModeFactAvailability => 'En este servidor';

  @override
  String get codeModeAvailable => 'Disponible';

  @override
  String get codeModeUnavailable => 'No disponible';

  @override
  String get codeModeFactRunner => 'Ejecutor';

  @override
  String codeModeUnavailableNote(String reason) {
    return 'Este servidor no puede ejecutar scripts, así que los agentes aquí llaman a sus herramientas una a una. El servidor indica: $reason';
  }

  @override
  String get codeModeNoReason => 'no se indicó ningún motivo.';

  @override
  String get codeModeViewExecutions => 'Ver ejecuciones de código';

  @override
  String get codeModeLimitsLabel => 'Límites';

  @override
  String get codeModeLimitsSubtitle =>
      'Cuánto tiempo y hasta dónde puede llegar un script. Los valores predeterminados sirven para la mayoría de espacios de trabajo.';

  @override
  String get codeModeLimitsDisclosure => 'Ajustar límites';

  @override
  String get codeModeLimitsAtDefaults => 'Predeterminados';

  @override
  String codeModeLimitsChangedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modificados',
      one: '1 modificado',
    );
    return '$_temp0';
  }

  @override
  String get codeModeLimitsUseDefaults => 'Usar predeterminados';

  @override
  String get codeModeLimitWallClock => 'Tiempo por script';

  @override
  String get codeModeLimitWallClockHelp =>
      'No cuenta el tiempo de espera de una persona.';

  @override
  String get codeModeLimitCpu => 'Tiempo de procesador';

  @override
  String get codeModeLimitCpuHelp =>
      'Tiempo que el propio script dedica a calcular.';

  @override
  String get codeModeLimitHeap => 'Memoria';

  @override
  String get codeModeLimitHeapHelp =>
      'Memoria que el script puede usar mientras se ejecuta.';

  @override
  String get codeModeLimitNestedCalls => 'Llamadas a herramientas por script';

  @override
  String get codeModeLimitNestedCallsHelp =>
      'Las llamadas por encima de este límite se rechazan y se informa al script del motivo.';

  @override
  String get codeModeLimitInFlight => 'Llamadas simultáneas';

  @override
  String get codeModeLimitInFlightHelp =>
      'Llamadas que un script puede tener en ejecución al mismo tiempo.';

  @override
  String get codeModeLimitOutputTokens => 'Salida que lee el agente';

  @override
  String get codeModeLimitOutputTokensHelp =>
      'La salida más larga se acorta; el agente puede leer el resto si lo pide.';

  @override
  String codeModeLimitRange(String defaultValue, String min, String max) {
    return 'Predeterminado $defaultValue. De $min a $max.';
  }

  @override
  String codeModeLimitOutOfRange(String min, String max) {
    return 'Introduce un número entero de $min a $max.';
  }

  @override
  String get codeModeSuffixSeconds => 's';

  @override
  String get codeModeSuffixMebibytes => 'MiB';

  @override
  String get codeModeSuffixCalls => 'llamadas';

  @override
  String get codeModeSuffixTokens => 'tokens';

  @override
  String codeModeServerCap(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Este servidor ejecuta como máximo $count scripts a la vez, en todos los espacios de trabajo.',
      one:
          'Este servidor ejecuta como máximo 1 script a la vez, en todos los espacios de trabajo.',
    );
    return '$_temp0';
  }

  @override
  String codeModeUnitMilliseconds(String value) {
    return '$value ms';
  }

  @override
  String codeModeUnitSeconds(String value) {
    return '$value s';
  }

  @override
  String codeModeUnitMinutesSeconds(String minutes, String seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String get codeModeRefusedLimitUnknown =>
      'El servidor no conoce uno de estos límites.';

  @override
  String get codeModeRefusedLimitOutOfRange =>
      'Uno de estos límites está fuera de lo que permite el servidor.';

  @override
  String get codeModeRefusedUnknownSetting =>
      'El servidor no reconoce ese ajuste.';

  @override
  String get codeExecutionsTitle => 'Ejecuciones de código';

  @override
  String get codeExecutionsSubtitle =>
      'Scripts que los agentes ejecutaron en este espacio de trabajo, con cada llamada a herramienta que hicieron.';

  @override
  String get codeExecutionsEmpty =>
      'Aún no se ha ejecutado ningún script aquí.';

  @override
  String get codeExecutionsEmptyFiltered =>
      'Ningún script coincide con estos filtros.';

  @override
  String get codeExecutionsStatusFilter => 'Resultado';

  @override
  String get codeExecutionsAllOutcomes => 'Todos los resultados';

  @override
  String codeExecutionsOutcomeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
    );
    return '$_temp0';
  }

  @override
  String get codeExecutionsScopeRun => 'Scripts de una ejecución';

  @override
  String get codeExecutionsScopeConversation => 'Scripts de una conversación';

  @override
  String get codeExecutionsScopeAgent => 'Scripts de un agente';

  @override
  String get codeExecutionsShowAll => 'Mostrar todo';

  @override
  String get codeExecutionUntitled => 'Script sin título';

  @override
  String get codeExecutionRecord => 'Registro';

  @override
  String get codeExecutionBackToList => 'Volver a ejecuciones de código';

  @override
  String get codeExecutionNotFound =>
      'Esta ejecución de código no está en este espacio de trabajo. Puede que se haya eliminado junto con su ejecución.';

  @override
  String get codeExecutionRefusedSpace =>
      'Este script se ejecutó en un espacio que no puedes abrir, así que su registro permanece oculto.';

  @override
  String get codeExecutionOpenRecord => 'Abrir registro';

  @override
  String get codeExecutionFactStarted => 'Iniciado';

  @override
  String get codeExecutionFactDuration => 'Duración';

  @override
  String get codeExecutionFactCalls => 'Llamadas a herramientas';

  @override
  String get codeExecutionFactAgent => 'Agente';

  @override
  String get codeExecutionFactSurface => 'Ejecutado mediante';

  @override
  String get codeExecutionSurfaceHarness => 'Agente integrado';

  @override
  String get codeExecutionSurfaceMcp => 'Agente externo';

  @override
  String get codeExecutionFactCpu => 'Tiempo de procesador';

  @override
  String get codeExecutionFactMemory => 'Memoria máxima';

  @override
  String get codeExecutionOpenConversation => 'Abrir conversación';

  @override
  String get codeExecutionRunScripts => 'Scripts de esta ejecución';

  @override
  String get codeExecutionAgentScripts => 'Scripts de este agente';

  @override
  String get codeExecutionScript => 'Script';

  @override
  String get codeExecutionConsole => 'Consola';

  @override
  String get codeExecutionOutputTruncated =>
      'La salida se recortó para caber en lo que se guarda.';

  @override
  String get codeExecutionNoPayload =>
      'El script y su salida ya no se guardan.';

  @override
  String codeExecutionCallsHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count llamadas a herramientas',
      one: '1 llamada a herramienta',
      zero: 'Llamadas a herramientas',
    );
    return '$_temp0';
  }

  @override
  String get codeExecutionNoCalls =>
      'El script no llamó a ninguna herramienta.';

  @override
  String get codeExecutionCallCompleted => 'Completado';

  @override
  String get codeExecutionCallFailed => 'Error';

  @override
  String get codeExecutionCallDenied => 'Denegado';

  @override
  String get codeExecutionCallCancelled => 'Cancelado';

  @override
  String get codeExecutionCallTimedOut => 'Tiempo agotado';

  @override
  String get codeExecutionCallUnknownTool => 'Herramienta desconocida';

  @override
  String get codeExecutionCallInvalidArgs => 'Argumentos no válidos';

  @override
  String get codeExecutionGateAllowed => 'Permitido';

  @override
  String get codeExecutionGateApproved => 'Aprobado por una persona';

  @override
  String get codeExecutionGateDenied => 'Denegado';

  @override
  String get codeExecutionGateNotReached => 'No comprobado';

  @override
  String codeExecutionCallWaited(String duration) {
    return 'Esperó $duration a una persona';
  }

  @override
  String get codeExecutionCallArguments => 'Argumentos';

  @override
  String get codeExecutionCallResult => 'Resultado';

  @override
  String codeExecutionCallResultSize(String size) {
    return 'Devolvió $size';
  }

  @override
  String codeExecutionBytes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bytes',
      one: '1 byte',
    );
    return '$_temp0';
  }

  @override
  String get codeExecutionEndedScriptError =>
      'El script lanzó un error y nada lo capturó.';

  @override
  String codeExecutionEndedScriptErrorNamed(String name) {
    return 'El script lanzó $name y nada lo capturó.';
  }

  @override
  String get codeExecutionEndedStalled =>
      'El script esperó algo que nunca podía terminar.';

  @override
  String get codeExecutionEndedCpu =>
      'El script agotó su tiempo de procesador.';

  @override
  String get codeExecutionEndedHeap =>
      'El script alcanzó su límite de memoria.';

  @override
  String get codeExecutionEndedOutput =>
      'El script generó más salida de la permitida.';

  @override
  String get codeExecutionEndedDeadline => 'El script se quedó sin tiempo.';

  @override
  String get codeExecutionEndedCancelled =>
      'El script se canceló antes de finalizar.';

  @override
  String get codeExecutionEndedShutdown =>
      'El servidor se apagó mientras se ejecutaba el script.';

  @override
  String get codeExecutionEndedServerStopped =>
      'El servidor se detuvo mientras se ejecutaba el script. El registro se cerró al volver a iniciarse el servidor.';

  @override
  String get codeExecutionEndedInternal =>
      'El programa que ejecuta scripts falló por su cuenta.';

  @override
  String get codeExecutionEndedStart =>
      'El programa que ejecuta scripts no pudo iniciarse.';

  @override
  String get codeExecutionEndedLockdown =>
      'El programa que ejecuta scripts no pudo bloquearse, así que el script no se ejecutó.';

  @override
  String get codeExecutionEndedExited =>
      'El programa que ejecuta scripts se detuvo antes de que terminara el script.';

  @override
  String get codeExecutionEndedRunnerBrokeRules =>
      'El programa que ejecuta scripts incumplió sus reglas de funcionamiento y se detuvo.';

  @override
  String get codeExecutionEndedUnresponsive =>
      'El programa que ejecuta scripts dejó de responder y se detuvo.';

  @override
  String get codeExecutionEndedHostError =>
      'El servidor falló mientras ejecutaba el script.';

  @override
  String get codeExecutionRunningNote =>
      'Sigue en ejecución. Sus llamadas a herramientas aparecen aquí a medida que terminan, y su resultado cuando finalice.';

  @override
  String codeModeServerWorkspaceShare(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Los scripts de un espacio de trabajo usan como máximo $count de ellas.',
      one: 'Los scripts de un espacio de trabajo usan como máximo 1 de ellas.',
    );
    return '$_temp0';
  }

  @override
  String get wakeOriginGoal => 'Objetivo';

  @override
  String get wakeOriginGoalCheck => 'Comprobación de objetivo';

  @override
  String get wakeOriginGoalReview => 'Revisión de objetivo';

  @override
  String get wakeOriginSchedule => 'Programación';

  @override
  String get wakeOriginWatch => 'Vigilancia';

  @override
  String wakeOriginReplyFrom(String agent) {
    return 'Respuesta de $agent';
  }

  @override
  String get wakeOriginReply => 'Respuesta';

  @override
  String wakeOriginMessageFrom(String agent) {
    return 'Mensaje de $agent';
  }

  @override
  String get wakeOriginMessage => 'Mensaje';

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return 'Trabajo terminado por $agent';
  }

  @override
  String get wakeOriginWorkFinished => 'Trabajo terminado';

  @override
  String get wakeOriginLimitReset => 'Límite restablecido';

  @override
  String get wakeOriginRecovery => 'Recuperación';

  @override
  String get wakeOriginAssignment => 'Asignación';

  @override
  String get wakeOriginPipelineStep => 'Paso de pipeline';

  @override
  String get wakeOriginImprovementReview => 'Revisión de mejoras';

  @override
  String get wakeKindStopped =>
      'Retenida porque una persona detuvo la ejecución.';

  @override
  String get wakeKindAttempts => 'La entrega falló tres veces.';

  @override
  String get wakeKindAgentDeleted => 'El agente ya no existe.';

  @override
  String get wakeKindAgentNotDispatchable => 'El agente está retirado.';

  @override
  String get wakeKindAgentPaused => 'El agente está en pausa.';

  @override
  String get wakeKindPersonRemoved =>
      'La persona en cuyo nombre actúa salió del espacio de trabajo.';

  @override
  String get wakeKindBudgetBlocked => 'Un presupuesto bloquea una ejecución.';

  @override
  String get wakeKindTakeOver => 'Una persona ha tomado el worktree.';

  @override
  String get wakeKindRateCapConversation =>
      'Esta conversación ha iniciado 30 ejecuciones desde reactivaciones en la última hora.';

  @override
  String get wakeKindRateCapWorkspace =>
      'Este espacio de trabajo ha iniciado 300 ejecuciones desde reactivaciones en la última hora.';

  @override
  String get wakeKindLiveRunNoInput =>
      'La ejecución en vivo del agente aquí no admite entradas.';

  @override
  String get wakeKindLiveRunOtherOptions =>
      'La ejecución en vivo del agente aquí funciona de otra forma, así que esta inicia su propia ejecución después.';

  @override
  String get wakeKindLiveRunOtherPerson =>
      'La ejecución en vivo del agente aquí actúa en nombre de otra persona, así que esta inicia su propia ejecución después.';

  @override
  String get wakeKindDispatchRefused => 'La ejecución no pudo iniciarse.';

  @override
  String get wakeKindSandboxUnavailable =>
      'No hay ningún entorno aislado disponible para una ejecución de solo lectura.';

  @override
  String get wakeKindReadOnlyUnavailable =>
      'El backend de este agente no puede mantener una ejecución de solo lectura.';

  @override
  String get wakeKindServerStopped =>
      'Un reinicio del servidor detuvo la ejecución.';

  @override
  String get wakeKindServerRestarted =>
      'El servidor se reinició durante una ejecución de una persona.';

  @override
  String get wakeKindGuardFailed =>
      'Falló una comprobación previa a la entrega.';

  @override
  String get wakeKindLimit => 'Esperando al límite de uso del proveedor.';

  @override
  String get wakeKindLimitRunLive =>
      'Esperando a que termine la ejecución en el límite de uso.';

  @override
  String get wakeKindWakeMissed => 'Perdida mientras el servidor estaba caído.';

  @override
  String get wakeKindPipelineRunEnded => 'Su ejecución de pipeline terminó.';

  @override
  String get wakeKindGoalEnded => 'Su objetivo terminó.';

  @override
  String get wakeKindGoalBudgetExhausted => 'Su objetivo agotó su presupuesto.';

  @override
  String get wakeKindGoalReviewStale =>
      'El objetivo cambió desde que se pidió esta revisión.';

  @override
  String get wakeKindGoalPaused => 'Su objetivo está en pausa.';

  @override
  String get wakeKindGoalHeld => 'Su objetivo está retenido.';

  @override
  String get wakeKindGoalStopped => 'Su objetivo se detuvo.';

  @override
  String get wakeKindAskSettled =>
      'La pregunta a la que responde ya estaba resuelta.';

  @override
  String get wakeKindRuleEnded => 'Su programación terminó.';

  @override
  String get wakeKindUnknown => 'Por un motivo que esta versión no identifica:';

  @override
  String wakeStripHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reactivaciones en espera',
      one: '1 reactivación en espera',
    );
    return '$_temp0';
  }

  @override
  String wakeStripDue(String time) {
    return 'Vence $time';
  }

  @override
  String get wakeStripDueNow => 'Vence ahora';

  @override
  String get wakeStripHeld => 'Retenida';

  @override
  String wakeStripExpires(String time) {
    return 'Caduca $time';
  }

  @override
  String wakeStripAttempt(int attempt) {
    return 'Intento $attempt';
  }

  @override
  String get wakeStripCancel => 'Cancelar reactivación';

  @override
  String get wakeStripDeliverNow => 'Entregar ahora';

  @override
  String get wakeStripResume => 'Reanudar';

  @override
  String get wakeStripDismiss => 'Descartar';

  @override
  String get wakeStripResumeAll => 'Reanudar todas';

  @override
  String get wakeStripResumeOnlyTheirs =>
      'Solo la persona cuya ejecución es puede reanudarla.';

  @override
  String get wakeReceiptStarted => 'Se inició una ejecución.';

  @override
  String get wakeReceiptPushed => 'Entregada a la ejecución en vivo.';

  @override
  String wakeReceiptWaiting(String reason) {
    return 'Sigue en espera. $reason';
  }

  @override
  String wakeReceiptSkipped(String reason) {
    return 'No entregada. $reason';
  }

  @override
  String get wakeReceiptDuplicate => 'Ya se había entregado.';

  @override
  String wakeReleased(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se reanudaron $count reactivaciones.',
      one: 'Se reanudó 1 reactivación.',
      zero: 'No se reanudó nada.',
    );
    return '$_temp0';
  }

  @override
  String get wakeRefusalNotYours =>
      'Esta reactivación actúa en nombre de otra persona. Solo ella puede entregarla o reanudarla.';

  @override
  String get wakeRefusalSettled => 'Esta reactivación ya se resolvió.';

  @override
  String heldSteeringHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes retenidos',
      one: '1 mensaje retenido',
    );
    return '$_temp0';
  }

  @override
  String get heldSteeringResume => 'Enviar mensajes retenidos';

  @override
  String get heldSteeringDelete => 'Eliminar mensaje retenido';

  @override
  String heldSteeringReleased(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se enviaron $count mensajes retenidos.',
      one: 'Se envió 1 mensaje retenido.',
      zero: 'No había nada retenido.',
    );
    return '$_temp0';
  }

  @override
  String get workAgentUnknown => 'un agente';

  @override
  String workFeedWoke(int count, String agent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Activó a $agent por $count elementos en espera',
      one: 'Activó a $agent',
    );
    return '$_temp0';
  }

  @override
  String workFeedWakeSkipped(String agent) {
    return 'No se entregó una reactivación para $agent.';
  }

  @override
  String workFeedWakeMissed(String agent) {
    return 'Se perdió una reactivación para $agent mientras el servidor estaba caído.';
  }

  @override
  String workFeedScheduleCreated(String agent) {
    return 'Programación establecida para $agent.';
  }

  @override
  String workFeedScheduleEnded(String agent) {
    return 'Terminó la programación para $agent.';
  }

  @override
  String get workFeedOpenSchedule => 'Abrir programación';

  @override
  String workFeedNoteFromAgent(String agent) {
    return '$agent dejó esta nota para sí mismo, con sus palabras:';
  }

  @override
  String get workFeedNoteFromPerson =>
      'Un recordatorio que una persona programó:';

  @override
  String workFeedLimitParkHeld(String provider, String time) {
    return 'En pausa en el límite de uso de $provider. El límite se restablece a las $time.';
  }

  @override
  String workFeedLimitParkPending(String provider, String time) {
    return 'En pausa en el límite de uso de $provider. Se reanuda a las $time.';
  }

  @override
  String workFeedLimitParkResumed(String provider) {
    return 'Reanudada tras el límite de uso de $provider.';
  }

  @override
  String workFeedLimitParkGone(String provider) {
    return 'Ya no está en espera por el límite de uso de $provider.';
  }

  @override
  String get workFeedLimitParkResume => 'Reanudar';

  @override
  String get workFeedLimitParkCancel => 'Cancelar';

  @override
  String workFeedStillInFlight(String agent) {
    return 'Estado entregado a $agent tras la compactación';
  }

  @override
  String get workFeedShowDetails => 'Mostrar detalles';

  @override
  String get workFeedHideDetails => 'Ocultar detalles';

  @override
  String get workFeedCommandRefused => 'El comando fue rechazado.';

  @override
  String get wakeRuleEndFired => 'Ejecutó su única vez.';

  @override
  String get wakeRuleEndExpired => 'Llegó a su fecha de fin.';

  @override
  String get wakeRuleEndRunCap => 'Agotó sus ejecuciones.';

  @override
  String get wakeRuleEndCostCap => 'Alcanzó su límite de coste.';

  @override
  String get wakeRuleEndGoalEnded => 'Su objetivo terminó.';

  @override
  String get wakeRuleEndCancelled => 'Se canceló.';

  @override
  String get wakeRuleEndMemberRemoved =>
      'Su persona salió del espacio de trabajo.';

  @override
  String get wakeRuleEndInvalidRow =>
      'No se pudieron leer sus ajustes guardados.';

  @override
  String get wakeRuleRefusalIntervalTooShort =>
      'El intervalo es demasiado corto. Elige uno más largo.';

  @override
  String get wakeRuleRefusalTooSoon =>
      'Esa hora es demasiado pronto. Elige una posterior.';

  @override
  String get wakeRuleRefusalLineageEnded =>
      'Esta cadena de reactivaciones ya agotó sus ejecuciones o su tiempo.';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable =>
      'No puedes leer lo que esto vigilaría.';

  @override
  String get wakeRuleRefusalExpiryRequired =>
      'Indica un fin, por ejemplo --days 3.';

  @override
  String get wakeRuleRefusalLimitReached =>
      'Esta conversación ya tiene tantas programaciones como puede tener.';

  @override
  String get wakeRuleRefusalInvalidWhen => 'No se entiende la hora.';

  @override
  String get wakeRuleRefusalNoteTooLong => 'La nota es demasiado larga.';

  @override
  String get wakeRuleRefusalExpiryTooLong => 'El fin está demasiado lejos.';

  @override
  String get wakeRuleRefusalLimitOutOfRange =>
      'Un límite de ejecuciones, días o presupuesto está fuera de rango.';

  @override
  String get wakeRuleRefusalNextOutsideLoop =>
      'Solo un bucle puede elegir su propia siguiente hora.';

  @override
  String get wakeRuleRefusalWatchRefused => 'Eso no se puede vigilar.';

  @override
  String get wakeRuleRefusalRuleEnded => 'Esa programación ya terminó.';

  @override
  String get wakeRuleRefusalNotYours =>
      'Esa programación pertenece a otra persona.';

  @override
  String get workRefusalUnknown => 'El servidor rechazó esto:';

  @override
  String get goalRefusalAlreadyActive =>
      'Esta conversación ya tiene un objetivo activo.';

  @override
  String get goalRefusalNotInReview =>
      'Este objetivo no está esperando revisión.';

  @override
  String get goalRefusalEvidenceIncomplete =>
      'Las pruebas del objetivo están incompletas.';

  @override
  String get goalRefusalClaimPending =>
      'Todavía se está comprobando una afirmación de que está terminado.';

  @override
  String get goalRefusalNotActiveSegment =>
      'Este objetivo no tiene ningún segmento en ejecución.';

  @override
  String get goalRefusalNotYours =>
      'Solo la persona que inició este objetivo puede hacer eso.';

  @override
  String get goalRefusalNotPaused => 'Pausa primero el objetivo.';

  @override
  String get goalRefusalContractInvalid =>
      'No se puede leer el contrato del objetivo.';

  @override
  String get goalRefusalCheckerUnknown => 'Ningún agente tiene ese nombre.';

  @override
  String get goalRefusalCheckerAmbiguous =>
      'Más de un agente tiene ese nombre. Usa su id.';

  @override
  String get goalRefusalCheckerIsGoalAgent =>
      'El verificador debe ser otro agente distinto del que hace el trabajo.';

  @override
  String get goalRefusalCommandInvalid => 'No se entiende este comando /goal.';

  @override
  String goalCardWorking(int segment) {
    return 'En curso · segmento $segment';
  }

  @override
  String get goalCardWaiting => 'Esperando su próxima reactivación';

  @override
  String get goalCardVerifying => 'Comprobando si está terminado';

  @override
  String goalCardLimitUntil(String time) {
    return 'En pausa en el límite de uso · se reanuda $time';
  }

  @override
  String get goalCardLimit => 'En pausa en el límite de uso';

  @override
  String get goalCardPerson => 'Necesita a una persona';

  @override
  String get goalCardByPerson => 'En pausa por una persona';

  @override
  String get goalCardNeedsReview =>
      'Esperando revisión: dice que está terminado y nada lo confirmó';

  @override
  String goalCardSegments(int run, int max) {
    return 'Segmento $run de $max';
  }

  @override
  String goalCardSegmentsNoCap(int run) {
    return 'Segmento $run';
  }

  @override
  String goalCardMoney(String spent, String cap) {
    return '$spent de $cap';
  }

  @override
  String goalCardTimeLeft(String time) {
    return '$time restante';
  }

  @override
  String get goalCardOverdue => 'Pasado de su fecha límite';

  @override
  String get goalCardDoneMeans => 'Terminado significa';

  @override
  String get goalCardChecks => 'Comprobaciones';

  @override
  String get goalCardCheckPassed => 'Aprobada';

  @override
  String goalCardCheckFailed(int code) {
    return 'Fallida · código $code';
  }

  @override
  String get goalCardCheckTimedOut => 'Tiempo agotado';

  @override
  String get goalCardCheckNotRerun => 'No se repitió: nada cambió';

  @override
  String get goalCardCheckBroken => 'No se puede ejecutar';

  @override
  String get goalCardCheckNotRun => 'Aún no se ha ejecutado';

  @override
  String get goalCardCriterionMet => 'Cumplido';

  @override
  String get goalCardCriterionUnmet => 'No cumplido';

  @override
  String get goalCardCriterionCannotTell => 'No se puede saber';

  @override
  String get goalCardVerdictPass => 'Última comprobación: terminado';

  @override
  String get goalCardVerdictFail => 'Última comprobación: no terminado';

  @override
  String get goalCardVerdictCannotVerify =>
      'Última comprobación: no se pudo saber';

  @override
  String get goalCardConcerns => 'Reservas';

  @override
  String goalCardVerifiedBy(String agent) {
    return 'Verificado por $agent';
  }

  @override
  String get goalCardVerifiedBySelf =>
      'Verificado por sí mismo (sin verificador aparte)';

  @override
  String get goalCardClosedByPerson =>
      'Cerrado por una persona sin una comprobación aprobada';

  @override
  String get goalCardNoMachineCheck => 'Sin comprobación automática';

  @override
  String get goalCardAddCheck => 'Añadir comprobación';

  @override
  String get goalCardOpen => 'Abrir objetivo';

  @override
  String get goalCardApprove => 'Aprobar finalización';

  @override
  String get goalCardApproveTitle => '¿Cerrar este objetivo como terminado?';

  @override
  String get goalCardApproveBody =>
      'Ninguna comprobación lo confirmó. Lo cierras con tu palabra, y el objetivo registra que una persona lo cerró sin verificar.';

  @override
  String get goalCardApproveConfirm => 'Cerrar como terminado';

  @override
  String get goalCardResumeNotYours =>
      'Reanudarlo o subir su presupuesto corresponde a quien lo inició.';

  @override
  String get goalHoldDetailStalled => 'Sin progreso en sus últimos segmentos.';

  @override
  String get goalHoldDetailStalledWaiting =>
      'Esperando, tras segmentos sin progreso.';

  @override
  String get goalHoldDetailVerificationFailed =>
      'Falló la última comprobación.';

  @override
  String get goalHoldDetailCannotVerify =>
      'El verificador no pudo saber si está terminado.';

  @override
  String get goalHoldDetailSandboxUnavailable =>
      'No hay ningún entorno aislado disponible para ejecutar sus comprobaciones.';

  @override
  String get goalHoldDetailCheckerUnavailable =>
      'Su agente verificador no está disponible. Elige otro verificador y luego reanuda.';

  @override
  String get goalHoldDetailCheckBroken =>
      'Esta comprobación no se puede ejecutar:';

  @override
  String get goalHoldDetailWakeSkipped => 'Su reactivación no se entregó.';

  @override
  String get goalHoldDetailClaimPending =>
      'Su afirmación de que está terminado espera a una comprobación.';

  @override
  String get goalHoldDetailUnanswered =>
      'Una pregunta o solicitud de aprobación a una persona quedó sin respuesta.';

  @override
  String get goalHoldDetailLimitParks =>
      'Ha llegado al límite de uso demasiadas veces. Revísalo y luego reanuda.';

  @override
  String get goalHoldDetailInput =>
      'Esperando una respuesta en la conversación.';

  @override
  String get peerAsksSection => 'Preguntas';

  @override
  String peerAskTo(String agent) {
    return 'Para $agent';
  }

  @override
  String get peerAskKindAsk => 'Pregunta';

  @override
  String get peerAskKindConsult => 'Consulta';

  @override
  String get peerAskKindReview => 'Revisión';

  @override
  String get peerAskStatusPending => 'En espera';

  @override
  String get peerAskStatusAnswered => 'Respondida';

  @override
  String get peerAskStatusFailed => 'Fallida';

  @override
  String get peerAskStatusExpired => 'Caducada';

  @override
  String get peerAskStatusCancelled => 'Cancelada';

  @override
  String peerAskAsked(String time) {
    return 'Preguntada $time';
  }

  @override
  String peerAskExpires(String time) {
    return 'Caduca $time';
  }

  @override
  String get peerAskPromised => 'Prometió una respuesta';

  @override
  String get peerAskBackground => 'En segundo plano';

  @override
  String get peerAskCancel => 'Cancelar pregunta';

  @override
  String get peerAskAlreadySettled => 'Esa pregunta ya se resolvió.';

  @override
  String get slashHintGoal =>
      'Trabaja hacia un objetivo hasta que esté terminado. Opciones: --check, --checker, --fresh, --unattended';

  @override
  String get slashHintLoop =>
      'Repite una tarea, cada intervalo o al ritmo del agente';

  @override
  String get slashHintSchedule =>
      'Ejecuta una tarea más tarde: in 2h, at 09:00 or on a cron';

  @override
  String get slashHintRefine =>
      'Revisa el trabajo de esta conversación y propón mejoras';

  @override
  String get notifGoalCompleted => 'Objetivo terminado';

  @override
  String get notifGoalFailed => 'Objetivo fallido';

  @override
  String get notifGoalCancelled => 'Objetivo cancelado';

  @override
  String get notifGoalBudgetExhausted => 'El objetivo agotó su presupuesto';

  @override
  String get notifGoalNeedsReview => 'Un objetivo espera tu revisión';

  @override
  String get notifGoalNeedsPerson => 'Un objetivo te necesita';

  @override
  String get notifGoalOnHold => 'Un objetivo está retenido';

  @override
  String get notifWakeRuleEnded => 'Terminó una programación';

  @override
  String notifWaitingDigest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cosas esperan por ti',
      one: '1 cosa espera por ti',
    );
    return '$_temp0';
  }

  @override
  String notifImprovementProposed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se propusieron $count mejoras',
      one: 'Se propuso una mejora',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld =>
      'Una ejecución de pipeline está retenida por su presupuesto';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return 'Gastado $spent de $cap';
  }

  @override
  String get inboxGoalNeedsReview => 'El objetivo espera revisión';

  @override
  String get inboxGoalNeedsPerson => 'El objetivo te necesita';

  @override
  String get inboxImprovementProposed => 'Mejora propuesta';

  @override
  String get improvementRefusalAlreadyDecided =>
      'Alguien ya decidió sobre esta propuesta.';

  @override
  String get improvementRefusalCampaignRequired =>
      'Este cambio no ha superado una evaluación con la habilidad actual, o la habilidad cambió después de medirla. Vuelve a ejecutar la evaluación.';

  @override
  String get improvementRefusalChangedSince =>
      'El destino cambió desde que se propuso. Recházala y deja que el agente proponga de nuevo.';

  @override
  String get improvementRefusalTargetMissing =>
      'Lo que esta propuesta cambia ya no existe.';

  @override
  String get improvementRefusalCampaignState =>
      'La evaluación no puede empezar ni terminar en su estado actual.';

  @override
  String get improvementRefusalReviewCooldown =>
      'Esta conversación se revisó hace poco. Inténtalo más tarde.';

  @override
  String get improvementRefusalAdminRequired =>
      'Solo un admin del espacio de trabajo puede decidir sobre esta propuesta.';

  @override
  String get improvementKindMemoryFact => 'Dato de memoria';

  @override
  String get improvementKindPolicy => 'Política';

  @override
  String get improvementKindAgentNote => 'Nota del agente';

  @override
  String get improvementKindSkillEdit => 'Cambio de habilidad';

  @override
  String get improvementKindSkillNew => 'Nueva habilidad';

  @override
  String get improvementScopeAgent => 'Este agente';

  @override
  String get improvementScopeRepository => 'Este repositorio';

  @override
  String get improvementScopeWorkspace => 'Todo el espacio de trabajo';

  @override
  String get improvementStatusProposed => 'Propuesta';

  @override
  String get improvementStatusAccepted => 'Aceptada';

  @override
  String get improvementStatusRejected => 'Rechazada';

  @override
  String get improvementStatusRolledBack => 'Revertida';

  @override
  String get improvementStatusExpired => 'Caducada';

  @override
  String get improvementOperationAdd => 'Añade';

  @override
  String get improvementOperationReplace => 'Reemplaza';

  @override
  String get improvementOperationRemove => 'Elimina';

  @override
  String scheduleTriggerOnce(String time) {
    return 'Una vez, $time';
  }

  @override
  String scheduleTriggerEvery(String interval) {
    return 'Cada $interval';
  }

  @override
  String scheduleTriggerCron(String cron, String zone) {
    return 'Según la programación $cron ($zone)';
  }

  @override
  String get scheduleTriggerSelfPaced =>
      'Cuando el agente decida, entre 1 y 60 minutos';

  @override
  String get scheduleTriggerPrChecks =>
      'Cuando terminen las comprobaciones de la pull request';

  @override
  String scheduleTriggerPrChecksOf(String pr) {
    return 'Cuando terminen las comprobaciones de $pr';
  }

  @override
  String get scheduleTriggerPrReview =>
      'Cuando la pull request reciba una revisión o respuesta';

  @override
  String scheduleTriggerPrReviewOf(String pr) {
    return 'Cuando $pr reciba una revisión o respuesta';
  }

  @override
  String get scheduleTriggerPrMerged => 'Cuando la pull request se fusione';

  @override
  String scheduleTriggerPrMergedOf(String pr) {
    return 'Cuando $pr se fusione';
  }

  @override
  String get scheduleTriggerEnvironment =>
      'Cuando una tarea del entorno termine o quede lista';

  @override
  String scheduleTriggerTicket(String id) {
    return 'Cuando el ticket $id se resuelva';
  }

  @override
  String scheduleTriggerPipelineRun(String id) {
    return 'Cuando termine la ejecución de pipeline $id';
  }

  @override
  String get goalNextWaiting => 'Continúa cuando llegue lo que espera.';

  @override
  String get goalNextVerifying =>
      'Cuando terminen las comprobaciones y la revisión, se completa o sigue trabajando.';

  @override
  String get goalNextLimit =>
      'Se reanuda cuando se restablezca el límite de uso.';

  @override
  String get goalNextPerson =>
      'Continúa cuando alguien responda a su pregunta o a su solicitud de aprobación.';

  @override
  String get goalNextByPerson => 'Sigue en pausa hasta que alguien lo reanude.';

  @override
  String get goalNextNeedsReview =>
      'Apruébalo como terminado, o reanúdalo para que siga trabajando.';

  @override
  String get goalNextWorking =>
      'Sigue trabajando, un segmento cada vez, hasta que termine o alcance un límite.';

  @override
  String get goalContractAddCheck => 'Añadir comprobación';

  @override
  String goalContractChecksFull(int max) {
    return 'Un objetivo tiene como máximo $max comprobaciones.';
  }

  @override
  String goalContractChecksCount(int count, int max) {
    return '$count de $max comprobaciones';
  }

  @override
  String get goalContractCheckTaskHint =>
      'Nombre de la tarea del entorno, por ejemplo test';

  @override
  String get goalContractCheckCommandHint => 'Comando, por ejemplo make test';

  @override
  String get goalContractCheckWhere => 'Dónde se ejecuta';

  @override
  String get goalContractCheckInWorktree => 'En el worktree';

  @override
  String get goalContractCheckInEnvironment => 'Tarea del entorno';

  @override
  String get goalContractSecondsSuffix => 's';

  @override
  String goalContractTimeoutRange(int max) {
    return 'De 1 a $max segundos';
  }

  @override
  String get goalContractRemoveCheck => 'Eliminar comprobación';

  @override
  String get goalContractDoneMeans => 'Terminado significa';

  @override
  String get goalContractDoneMeansHelp =>
      'Cada criterio es una cosa que un revisor puede confirmar.';

  @override
  String get goalContractCriterionHint =>
      'Las notas de la versión enumeran cada cambio fusionado';

  @override
  String goalContractCriterionTooLong(int max) {
    return 'Como máximo $max caracteres.';
  }

  @override
  String get goalContractRemoveCriterion => 'Eliminar criterio';

  @override
  String get goalContractAddCriterion => 'Añadir criterio';

  @override
  String goalContractCriteriaFull(int max) {
    return 'Un objetivo tiene como máximo $max criterios.';
  }

  @override
  String goalContractCriteriaCount(int count, int max) {
    return '$count de $max criterios';
  }

  @override
  String get goalContractChecks => 'Comprobaciones';

  @override
  String get goalContractChecksHelp =>
      'El servidor las ejecuta cuando el agente dice que ha terminado. Un objetivo sin comprobación depende solo de la revisión.';

  @override
  String get goalContractBoundaries => 'Límites';

  @override
  String get goalContractBoundariesHint => 'No cambies la API pública';

  @override
  String get goalContractStopWhen => 'Detente y pregunta cuando';

  @override
  String get goalContractStopWhenHint => 'Una migración borraría datos';

  @override
  String get goalContractEditTitle => 'Editar qué significa terminado';

  @override
  String get goalCheckerTitle => 'Quién verifica este objetivo';

  @override
  String get goalCheckerLabel => 'Verificador';

  @override
  String get goalCheckerNone => 'Sin verificador aparte';

  @override
  String get goalCheckerNoneWeaker =>
      'Sin un verificador aparte, el agente revisa su propio trabajo, lo que detecta menos.';

  @override
  String goalCheckerRecommend(String agent) {
    return 'Por ejemplo $agent: un verificador de otro proveedor es menos probable que comparta los mismos puntos ciegos.';
  }

  @override
  String get goalCheckerRecommendGeneric =>
      'Un verificador de un proveedor distinto al del agente del objetivo es menos probable que comparta sus puntos ciegos.';

  @override
  String raiseCapSpentOf(String spent, String cap) {
    return 'Gastado $spent de $cap.';
  }

  @override
  String get raiseCapNewCap => 'Nuevo límite en dólares';

  @override
  String raiseCapMustExceed(String cap) {
    return 'Introduce más de $cap.';
  }

  @override
  String get raiseCapConfirm => 'Subir el límite';

  @override
  String get goalsBackToList => 'Todos los objetivos';

  @override
  String goalPursuedBy(String agent) {
    return 'Lo persigue $agent';
  }

  @override
  String get goalOpenConversation => 'Abrir la conversación';

  @override
  String goalStarted(String time) {
    return 'Iniciado $time';
  }

  @override
  String get goalStopTitle => '¿Detener este objetivo?';

  @override
  String get goalStopBody =>
      'El agente deja de trabajar en él de forma definitiva. Su trabajo hasta ahora se queda en la conversación.';

  @override
  String get goalRaiseBudgetTitle => 'Subir el presupuesto y reanudar';

  @override
  String get goalRaiseBudgetAction => 'Subir presupuesto';

  @override
  String get goalSectionNow => 'Ahora';

  @override
  String get goalFactSegments => 'Segmentos';

  @override
  String get goalFactMoney => 'Gastado';

  @override
  String get goalFactDeadline => 'Fecha límite';

  @override
  String get goalFactNoProgress => 'Sin progreso';

  @override
  String get goalNoDeadline => 'Ninguna';

  @override
  String goalDeadlineWithLeft(String time, String left) {
    return '$time, quedan $left';
  }

  @override
  String goalNoProgressCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Los últimos $count segmentos no avanzaron',
      one: 'El último segmento no avanzó',
    );
    return '$_temp0';
  }

  @override
  String get goalObjective => 'Objetivo';

  @override
  String get goalSectionContract => 'Qué significa terminado';

  @override
  String get goalContractPauseFirst =>
      'Pausa el objetivo para cambiar qué significa terminado o quién lo verifica.';

  @override
  String get goalContractEdit => 'Editar';

  @override
  String get goalCheckerChange => 'Cambiar verificador';

  @override
  String get goalContractNone =>
      'Nada escrito todavía. El agente decide cuándo está terminado.';

  @override
  String get goalCheckerSelf =>
      'Sin verificador aparte: el agente verifica su propio trabajo.';

  @override
  String goalCheckerIs(String agent) {
    return 'Verificado por $agent';
  }

  @override
  String goalCheckWorktree(int seconds) {
    return 'En el worktree, hasta $seconds s';
  }

  @override
  String goalCheckEnvironmentTask(int seconds) {
    return 'Tarea del entorno, hasta $seconds s';
  }

  @override
  String get goalSectionVerification => 'Verificación';

  @override
  String get goalNotVerifiedYet =>
      'Sin verificar todavía. El agente no ha dicho que está terminado.';

  @override
  String goalVerificationRound(int round, int total, String time) {
    return 'Ronda $round de $total, $time';
  }

  @override
  String get goalVerificationClaim => 'Lo que afirma el agente';

  @override
  String get goalCheckOutputTail => 'Salida (últimas líneas)';

  @override
  String goalCheckExitCode(int code) {
    return 'Aprobada · código $code';
  }

  @override
  String get goalVerificationReview => 'Revisión';

  @override
  String get goalVerificationNoVerdict => 'Sin revisión todavía.';

  @override
  String goalVerdictItem(String criterion, String state) {
    return '$criterion · $state';
  }

  @override
  String get goalSectionSchedules => 'Programaciones y reactivaciones';

  @override
  String get goalNoSchedules => 'Sin programación ni reactivación pendiente.';

  @override
  String get goalPendingWakes => 'Reactivaciones pendientes';

  @override
  String workListGroup(String label, int count) {
    return '$label · $count';
  }

  @override
  String get goalNotFound =>
      'Este objetivo no existe, o está en un espacio que no puedes abrir.';

  @override
  String get goalsTitle => 'Objetivos';

  @override
  String get goalsSubtitle =>
      'Trabajo que un agente sigue haciendo hasta cumplir lo que significa terminado.';

  @override
  String get goalsEmpty => 'Todavía no hay objetivos';

  @override
  String get goalsEmptyHint => 'Empieza uno con /goal en una conversación.';

  @override
  String get goalsGroupReview => 'Esperando revisión';

  @override
  String get goalsGroupOpen => 'Abiertos';

  @override
  String get goalsGroupEnded => 'Terminados';

  @override
  String get scheduleStatusActive => 'Activa';

  @override
  String get scheduleStatusPaused => 'En pausa';

  @override
  String get scheduleStatusEnded => 'Terminada';

  @override
  String get scheduleWhenBusySkip =>
      'Omite una activación mientras el agente está ocupado';

  @override
  String get scheduleWhenBusyQueue => 'Espera hasta que el agente esté libre';

  @override
  String get scheduleDeliverRun => 'Inicia una ejecución';

  @override
  String get scheduleDeliverNotify => 'Solo notifica';

  @override
  String get scheduleNew => 'Nueva programación';

  @override
  String get schedulesEmpty => 'No hay programaciones ni vigilancias';

  @override
  String get schedulesEmptyHint =>
      'Los agentes las crean con /loop y /schedule, o puedes crear una.';

  @override
  String scheduleOwnedBy(String name) {
    return 'Responsable: $name';
  }

  @override
  String scheduleRunsSkips(int runs, int skips) {
    String _temp0 = intl.Intl.pluralLogic(
      runs,
      locale: localeName,
      other: '$runs ejecuciones',
      one: '1 ejecución',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skips,
      locale: localeName,
      other: '$skips omisiones',
      one: '1 omisión',
      zero: 'sin omisiones',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String scheduleExpires(String time) {
    return 'Termina $time';
  }

  @override
  String scheduleNextFires(String times) {
    return 'Próxima: $times';
  }

  @override
  String get schedulesTitle => 'Programaciones';

  @override
  String get schedulesSubtitle =>
      'Programaciones, bucles y vigilancias que reactivan agentes.';

  @override
  String get scheduleWhenLabel => 'Cuándo se activa';

  @override
  String get scheduleWhenEvery => 'Repetida, cada…';

  @override
  String get scheduleWhenCron => 'Según una programación cron';

  @override
  String get scheduleWhenOnceIn => 'Una vez, después de…';

  @override
  String get scheduleWhenOnceAt => 'Una vez, en la próxima…';

  @override
  String get scheduleDurationLabel => 'Intervalo';

  @override
  String get scheduleDurationHelp =>
      'Usa s, m, h o d, por ejemplo 30m o 1h30m. Las repeticiones están separadas al menos 60 s.';

  @override
  String get scheduleDurationInvalid =>
      'Esto no es una duración, por ejemplo 30m o 2h.';

  @override
  String get scheduleHour => 'Hora';

  @override
  String get scheduleMinute => 'Minuto';

  @override
  String get scheduleCronLabel => 'Cron (minuto hora día mes día de la semana)';

  @override
  String get scheduleCronInvalid =>
      'Esto no es un cron de cinco campos que se active.';

  @override
  String get scheduleTimeInvalid =>
      'No es una hora futura, como 09:00 o 2026-11-21T09:00Z.';

  @override
  String scheduleDaysRange(int max) {
    return 'De 1 a $max días.';
  }

  @override
  String scheduleOptionUnknown(String option) {
    return '$option no es una opción.';
  }

  @override
  String get scheduleLimits => 'Límites';

  @override
  String get schedulePresetWeekdays => 'Entre semana a las 09:00';

  @override
  String get schedulePresetDaily => 'Todos los días a las 09:00';

  @override
  String get schedulePresetHourly => 'Cada hora, en punto';

  @override
  String get scheduleZoneLabel => 'Zona horaria';

  @override
  String get scheduleZoneHelp =>
      'Vacío significa la zona del espacio de trabajo.';

  @override
  String get scheduleZoneInvalid =>
      'Esto no es una zona horaria, por ejemplo Europe/Berlin.';

  @override
  String get scheduleCreateTitle => 'Nueva programación';

  @override
  String get scheduleSpaceLabel => 'Espacio';

  @override
  String get scheduleSpaceHint => 'Elige un espacio';

  @override
  String get scheduleConversationLabel => 'Conversación';

  @override
  String get scheduleConversationHint => 'Elige una conversación';

  @override
  String get scheduleAgentLabel => 'Agente';

  @override
  String get scheduleAgentHint => 'Elige quién se reactiva';

  @override
  String get scheduleNoteLabel => 'Con qué empieza cada ejecución';

  @override
  String get scheduleNoteHint =>
      'Resume qué cambió durante la noche y señala lo que esté bloqueado.';

  @override
  String get scheduleExpiresInDays => 'Termina tras (días)';

  @override
  String get scheduleExpiresInDaysHelp => 'Vacío: 30 días, como máximo 365.';

  @override
  String get scheduleMaxRuns => 'Límite de ejecuciones';

  @override
  String scheduleMaxRunsHelp(int max) {
    return 'Vacío: sin límite, como máximo $max.';
  }

  @override
  String get scheduleCostCap => 'Límite de coste (dólares)';

  @override
  String get scheduleCostCapHelp =>
      'Vacío: el valor predeterminado del espacio de trabajo.';

  @override
  String get scheduleWhenBusyLabel => 'Si el agente está ocupado';

  @override
  String get scheduleWhenBusyDefault => 'El predeterminado para este tipo';

  @override
  String get scheduleDeliverLabel => 'En cada activación';

  @override
  String get scheduleCreate => 'Crear programación';

  @override
  String get scheduleExtendTitle => 'Ampliar esta programación';

  @override
  String scheduleExtendNow(String current, String latest) {
    return 'Termina $current. Puede durar como máximo hasta $latest.';
  }

  @override
  String get scheduleExtendDays => 'Añadir días';

  @override
  String scheduleExtendTooLong(String latest) {
    return 'Puede terminar como máximo el $latest.';
  }

  @override
  String scheduleMaxRunsRange(int max) {
    return 'De 1 a $max ejecuciones.';
  }

  @override
  String scheduleCostCapRange(String max) {
    return 'Al menos 1 dólar y como máximo $max.';
  }

  @override
  String get scheduleExtend => 'Ampliar';

  @override
  String get scheduleRemoveTitle => '¿Quitar esta programación?';

  @override
  String get scheduleDeleteTitle => '¿Eliminar esta programación?';

  @override
  String get scheduleRemoveBody =>
      'Desaparece de la lista. Sus ejecuciones se quedan en la conversación.';

  @override
  String get scheduleDeleteBody =>
      'Deja de activarse de forma definitiva. Sus ejecuciones se quedan en la conversación.';

  @override
  String get scheduleRemove => 'Quitar';

  @override
  String get scheduleDelete => 'Eliminar';

  @override
  String get scheduleOwnerOnly =>
      'Solo su responsable puede reanudarla o ampliarla.';

  @override
  String get schedulesBackToList => 'Todas las programaciones';

  @override
  String get scheduleNoteByAgent => 'Nota, escrita por el agente';

  @override
  String get scheduleNoteByPerson => 'Nota, escrita por una persona';

  @override
  String scheduleNoteEditedBy(String name) {
    return 'Nota, editada por última vez por $name';
  }

  @override
  String get scheduleNoNote => 'Sin nota.';

  @override
  String get schedulePause => 'Pausar';

  @override
  String get scheduleResume => 'Reanudar';

  @override
  String get scheduleOpenChainRoot =>
      'Abrir la primera programación de esta cadena';

  @override
  String get scheduleSectionFacts => 'Detalles';

  @override
  String get scheduleFactAgent => 'Reactiva';

  @override
  String get scheduleFactConversation => 'En';

  @override
  String get scheduleConversationUnknown =>
      'Una conversación que no puedes ver';

  @override
  String get scheduleFactOwner => 'Responsable';

  @override
  String get scheduleNoOwner => 'Nadie';

  @override
  String get scheduleFactNextFires => 'Próximas activaciones';

  @override
  String get scheduleFactNext => 'Próxima activación';

  @override
  String get scheduleFactLast => 'Última activación';

  @override
  String get scheduleFactRuns => 'Ejecuciones';

  @override
  String scheduleRunsNoCap(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ejecuciones, sin límite',
      one: '1 ejecución, sin límite',
    );
    return '$_temp0';
  }

  @override
  String scheduleRunsOfCap(int count, int max) {
    return '$count de $max ejecuciones';
  }

  @override
  String get scheduleFactSkips => 'Omisiones';

  @override
  String scheduleSkips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activaciones omitidas',
      one: '1 activación omitida',
      zero: 'Ninguna',
    );
    return '$_temp0';
  }

  @override
  String get scheduleFactSpent => 'Gastado';

  @override
  String get scheduleFactEnds => 'Termina';

  @override
  String get scheduleFactWhenBusy => 'Si el agente está ocupado';

  @override
  String get scheduleFactDeliver => 'En cada activación';

  @override
  String get scheduleFactChain => 'Cadena';

  @override
  String scheduleChainLeft(int runs, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      runs,
      locale: localeName,
      other: '$runs ejecuciones restantes',
      one: '1 ejecución restante',
    );
    return '$_temp0 en la cadena, que termina $time';
  }

  @override
  String get scheduleFactCreated => 'Creada';

  @override
  String get scheduleSectionHistory => 'Reactivaciones y ejecuciones recientes';

  @override
  String get scheduleNoRuns => 'Todavía no hay ejecuciones.';

  @override
  String scheduleRunLine(String status, String cost) {
    return '$status · $cost';
  }

  @override
  String get scheduleRunPending => 'Esperando para iniciarse';

  @override
  String get scheduleRunRunning => 'En ejecución';

  @override
  String get scheduleRunCompleted => 'Terminada';

  @override
  String get scheduleRunFailed => 'Fallida';

  @override
  String get scheduleNotFound =>
      'Esta programación no existe, o está en un espacio que no puedes abrir.';

  @override
  String get improvementCampaignTitle => 'Ejecutar una evaluación';

  @override
  String improvementCampaignCost(int repetitions, String budget) {
    String _temp0 = intl.Intl.pluralLogic(
      repetitions,
      locale: localeName,
      other: 'Cada tarea se ejecuta $repetitions veces',
      one: 'Cada tarea se ejecuta una vez',
    );
    return '$_temp0 con la habilidad actual y con el cambio. Gasta como máximo $budget, cargado a este espacio de trabajo.';
  }

  @override
  String get improvementCampaignCostUnknown =>
      'La evaluación ejecuta el corpus con la habilidad actual y con el cambio, hasta el presupuesto que indiques.';

  @override
  String get improvementCampaignUnavailable =>
      'Las evaluaciones no pueden ejecutarse en este servidor ahora mismo.';

  @override
  String get improvementCampaignCorpus => 'Corpus';

  @override
  String get improvementCampaignProvider => 'Proveedor';

  @override
  String get improvementCampaignModel => 'Modelo';

  @override
  String get improvementCampaignRepetitions => 'Ejecuciones por tarea';

  @override
  String get improvementCampaignBudget => 'Presupuesto (dólares)';

  @override
  String improvementCampaignRange(int max) {
    return 'De 1 a $max.';
  }

  @override
  String get improvementCampaignStart => 'Iniciar evaluación';

  @override
  String get improvementRollbackTitle => '¿Revertir este cambio?';

  @override
  String get improvementRollbackBody =>
      'Vuelve el texto que reemplazó, siempre que nadie lo haya cambiado desde entonces.';

  @override
  String get improvementRollback => 'Revertir';

  @override
  String get improvementRolledBackDone => 'Revertido.';

  @override
  String get improvementNeedsAdmin =>
      'Solo un admin del espacio de trabajo puede decidir sobre esta: cambia una habilidad o una política para todo el espacio de trabajo.';

  @override
  String get improvementAdminDecides =>
      'Como admin, decides sobre esta: cambia una habilidad o una política para todo el espacio de trabajo.';

  @override
  String get improvementNeedsCampaign =>
      'Ejecuta una evaluación que apruebe antes de aceptar este cambio de habilidad.';

  @override
  String get improvementsBackToList => 'Todas las mejoras';

  @override
  String improvementMeta(String kind, String scope, String agent) {
    return '$kind · $scope · propuesta por $agent';
  }

  @override
  String get improvementAccept => 'Aceptar';

  @override
  String get improvementAcceptedDone => 'Aceptada.';

  @override
  String get improvementReject => 'Rechazar';

  @override
  String get improvementRejectedDone => 'Rechazada.';

  @override
  String get improvementRunEvaluation => 'Ejecutar evaluación';

  @override
  String get improvementSectionChange => 'Qué cambia';

  @override
  String get improvementTarget => 'Destino';

  @override
  String improvementScopeLine(String scope) {
    return 'Se aplica a: $scope';
  }

  @override
  String get improvementNewText => 'Texto nuevo';

  @override
  String get improvementRemovedText => 'Texto eliminado';

  @override
  String get improvementExpected => 'Efecto esperado';

  @override
  String get improvementSectionEvidence => 'Pruebas y decisión';

  @override
  String get improvementNoEvidence => 'No hay pruebas adjuntas.';

  @override
  String get improvementEvidenceRuns => 'Ejecuciones';

  @override
  String get improvementEvidenceMessages => 'Mensajes';

  @override
  String improvementOpenMessage(int index) {
    return 'Mensaje $index';
  }

  @override
  String get improvementEvidenceChecks => 'Resultados de comprobaciones';

  @override
  String get improvementEvaluation => 'Evaluación';

  @override
  String get improvementCampaignNone => 'Todavía no evaluada.';

  @override
  String get improvementCampaignRunning => 'La evaluación está en curso.';

  @override
  String get improvementCampaignPassed =>
      'La evaluación superó: se ejecutó completa y el cambio resolvió al menos tantas ejecuciones como la habilidad actual, lo que no demuestra que sea mejor. Se puede aceptar.';

  @override
  String get improvementCampaignFailed =>
      'La evaluación no superó, o la habilidad cambió después de medirla. Vuelve a ejecutarla o rechaza el cambio.';

  @override
  String improvementDecided(String status, String name, String time) {
    return '$status por $name, $time';
  }

  @override
  String get improvementSomeone => 'alguien';

  @override
  String improvementExpires(String time) {
    return 'Caduca $time si nadie decide.';
  }

  @override
  String get improvementOpenApplied => 'Abrir lo que cambió';

  @override
  String get improvementsTitle => 'Mejoras';

  @override
  String get improvementsSubtitle =>
      'Cambios que los agentes propusieron para su memoria, notas, políticas y habilidades.';

  @override
  String get improvementsEmpty => 'No hay propuestas';

  @override
  String get improvementsEmptyHint =>
      'Los agentes proponen mejoras tras revisar su trabajo, por ejemplo con /refine.';

  @override
  String get improvementRowNeedsAdmin => 'Decide un admin';

  @override
  String get improvementNotFound =>
      'Esta propuesta no existe, o está en un espacio que no puedes abrir.';

  @override
  String get dispatchSettingsTitle => 'Programaciones';

  @override
  String get dispatchLimitsLabel => 'Límites de programaciones';

  @override
  String get dispatchLimitsSubtitle =>
      'Topes de cuántas programaciones y vigilancias pueden tener los agentes, y sus valores predeterminados.';

  @override
  String dispatchLimitRange(int max) {
    return 'De 1 a $max';
  }

  @override
  String get dispatchLimitPerConversation => 'Por agente en una conversación';

  @override
  String get dispatchLimitPerConversationHelp =>
      'Programaciones activas o en pausa que un agente puede tener en una conversación.';

  @override
  String get dispatchLimitPerAgent => 'Por agente';

  @override
  String get dispatchLimitPerAgentHelp =>
      'Programaciones activas o en pausa que un agente puede tener en todo el espacio de trabajo.';

  @override
  String get dispatchLimitPerWorkspace => 'En el espacio de trabajo';

  @override
  String get dispatchLimitPerWorkspaceHelp =>
      'Programaciones activas o en pausa en todo el espacio de trabajo.';

  @override
  String get dispatchLimitCostCap => 'Límite de coste predeterminado (dólares)';

  @override
  String get dispatchLimitCostCapHelp =>
      'Lo que una programación puede gastar en total si no define un límite propio.';

  @override
  String get dispatchLimitZone => 'Zona horaria';

  @override
  String get dispatchLimitZoneHelp =>
      'La zona en la que se lee una programación cron si no indica una, y la zona del resumen diario.';

  @override
  String get dispatchUnattendedLabel => 'Cuando nadie responde';

  @override
  String get dispatchUnattendedSubtitle =>
      'Cuánto tiempo espera una ejecución iniciada por el servidor a una persona, y cuándo sale el resumen diario de lo que espera.';

  @override
  String get dispatchUnattendedExpiry => 'Las solicitudes esperan (horas)';

  @override
  String get dispatchUnattendedExpiryHelp =>
      'Pasado este tiempo, una aprobación cuenta como denegada y una pregunta como sin responder. Los objetivos configurados para suponer su respuesta responden a sus propias preguntas tras 10 minutos.';

  @override
  String dispatchUnattendedExpiryRange(int min, int max) {
    return 'De $min a $max horas';
  }

  @override
  String get dispatchDigestHour => 'Resumen diario a las (hora)';

  @override
  String dispatchDigestHourHelp(String zone) {
    return 'En $zone, la zona horaria de arriba.';
  }

  @override
  String get dispatchDigestHourRange => 'De 0 a 23';

  @override
  String get goalRecordCrumb => 'Objetivo';

  @override
  String get improvementRecordCrumb => 'Propuesta';

  @override
  String get goalNodeNeedsAgent => 'Elige el agente que persigue el objetivo.';

  @override
  String get goalNodeNeedsObjective => 'Escribe el objetivo.';

  @override
  String get goalNodeContractInvalid =>
      'El contrato tiene un campo por encima de su límite; no se guarda hasta corregirlo.';

  @override
  String get goalNodeBudget => 'Presupuesto (dólares)';

  @override
  String get goalNodeBudgetHelp =>
      'Lo máximo que puede gastar el objetivo. Cuando se agote, el objetivo queda retenido para una persona.';

  @override
  String goalNodeBudgetRange(int max) {
    return 'Obligatorio: más de 0, como máximo $max.';
  }

  @override
  String get goalNodeMaxRuns => 'Límite de segmentos';

  @override
  String get goalNodeMaxRunsHelp =>
      'Opcional. Lo máximo de segmentos (ejecuciones del agente) que puede tomar el objetivo.';

  @override
  String get goalNodeDeadline => 'Fecha límite (horas)';

  @override
  String get goalNodeDeadlineHelp =>
      'Opcional. Horas desde que el paso inicia el objetivo.';

  @override
  String goalNodeRange(int max) {
    return 'De 1 a $max, o vacío.';
  }

  @override
  String get goalNodeContract => 'Contrato';

  @override
  String get goalNodeContractHelp =>
      'Qué significa terminado: criterios que revisa el revisor, y comandos que deben aprobarse.';

  @override
  String get nodeConfigObjective => 'Objetivo';

  @override
  String pipelineRunGoalStep(String step) {
    return 'El paso $step persigue un objetivo';
  }

  @override
  String get pipelineRunOpenGoal => 'Abrir objetivo';

  @override
  String get pipelineRunHeldBudget =>
      'Esta ejecución está retenida: su orquestación alcanzó su límite de coste.';

  @override
  String pipelineRunHeldOther(String reason) {
    return 'Esta ejecución está retenida ($reason).';
  }

  @override
  String pipelineRunHeldSpent(String spent, String cap) {
    return 'Gastado $spent de $cap. Sube el límite y la ejecución continúa.';
  }

  @override
  String get pipelineRunRaiseCap => 'Subir límite';

  @override
  String get pipelineRunRaiseCapTitle => 'Subir el límite de orquestación';

  @override
  String get pipelineRunCapRaised =>
      'Límite subido. La ejecución continúa en breve.';

  @override
  String get goalLaunchChecks => 'Comprobaciones';

  @override
  String get goalLaunchChecksHelp =>
      'Comandos que deben aprobarse antes de que el objetivo pueda terminar. Opcional.';

  @override
  String get goalLaunchFresh => 'Empezar cada segmento desde cero';

  @override
  String get goalLaunchFreshHelp =>
      'Cada ejecución empieza sin el historial de la conversación, solo desde el objetivo y sus notas.';

  @override
  String get goalLaunchAssume =>
      'Responder sus propias preguntas cuando nadie lo haga';

  @override
  String get goalLaunchAssumeHelp =>
      'Tras 10 minutos sin respuesta, el agente indica su suposición y sigue, si las condiciones de parada lo permiten.';

  @override
  String workFeedLimitParkOutcomeResumed(String provider, String time) {
    return 'Reanudada a las $time tras el límite de uso de $provider.';
  }

  @override
  String workFeedLimitParkOutcomeCancelled(String provider, String time) {
    return 'Cancelada a las $time. No se reanudó tras el límite de uso de $provider.';
  }

  @override
  String workFeedLimitParkOutcomeExpired(String provider, String time) {
    return 'Caducó a las $time sin reanudarse tras el límite de uso de $provider.';
  }

  @override
  String workFeedLimitParkOutcomeSkipped(String provider, String time) {
    return 'No se reanudó tras el límite de uso de $provider ($time).';
  }

  @override
  String workFeedCommandRefusedNamed(String command) {
    return 'El comando /$command fue rechazado.';
  }

  @override
  String get improvementRefusalQueued =>
      'Ya hay una revisión de esta conversación esperando para ejecutarse.';

  @override
  String get improvementRefusalAgentNotFound =>
      'Ese agente no es un agente de este espacio de trabajo.';

  @override
  String get workRefusalWakeQueueFull =>
      'Ya esperan demasiadas reactivaciones aquí. Inténtalo de nuevo cuando algunas se hayan ejecutado.';

  @override
  String get orchestrationRefusalNotYours =>
      'Solo la persona para la que actúa esta ejecución puede cambiarla.';

  @override
  String get orchestrationRefusalCapInvalid =>
      'El nuevo límite debe ser superior al límite actual y a lo gastado, y como máximo 1.000 \$.';

  @override
  String get orchestrationRefusalCapChanged =>
      'Alguien subió el límite antes. Revisa el nuevo límite e inténtalo de nuevo.';

  @override
  String workFeedCapRaised(String person, String oldCap, String newCap) {
    return '$person subió el límite de gasto de la ejecución de $oldCap a $newCap.';
  }

  @override
  String get workFeedPersonUnknown => 'Una persona';

  @override
  String workFeedApplyIncomplete(String skill) {
    return 'No se pudo terminar un cambio aceptado a la habilidad $skill, porque la habilidad cambió entretanto. La propuesta se revirtió.';
  }

  @override
  String get workFeedOpenImprovement => 'Abrir mejora';

  @override
  String get peerAskFailNoOutput => 'Terminó sin respuesta.';

  @override
  String get peerAskFailRunFailed => 'Su ejecución falló.';

  @override
  String get peerAskFailStoppedByPerson => 'Una persona detuvo su ejecución.';

  @override
  String get peerAskFailBudget => 'Su ejecución alcanzó su presupuesto.';

  @override
  String get peerAskFailSilence =>
      'Su ejecución se quedó en silencio y se detuvo.';

  @override
  String get peerAskFailUsageLimit =>
      'Su ejecución se detuvo en el límite de uso del proveedor.';

  @override
  String get peerAskFailNotDelivered => 'La pregunta nunca se entregó.';

  @override
  String heldSteeringLimitHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes retenidos en el límite de uso',
      one: '1 mensaje retenido en el límite de uso',
    );
    return '$_temp0';
  }

  @override
  String get heldSteeringLimitNote =>
      'Se envían cuando la persona para la que trabaja la ejecución la reanuda. Si no se reanuda en los 7 días posteriores al restablecimiento, quedan retenidos para esa persona.';

  @override
  String get wakeKindRuleFolded => 'Un evento posterior lo sustituyó.';

  @override
  String goalCardWaitingNext(String time) {
    return 'Esperando a lo que configuró · vuelve a mirar a las $time';
  }

  @override
  String raiseCapAtMost(String max) {
    return 'Introduce como máximo $max.';
  }

  @override
  String raiseCapNowAt(String cap) {
    return 'El límite es ahora $cap.';
  }

  @override
  String get scheduleWakeReasonSchedule => 'Programada';

  @override
  String get scheduleWakeReasonWatch => 'Vigilancia';

  @override
  String get scheduleWakeReasonLimitReset => 'Tras un límite de uso';

  @override
  String get scheduleWakeStatePending => 'En espera';

  @override
  String get scheduleWakeStateHeld => 'Retenida';

  @override
  String get scheduleWakeStateClaimed => 'Iniciando';

  @override
  String get scheduleWakeStateDelivered => 'Entregada';

  @override
  String get scheduleWakeStateSkipped => 'Omitida';

  @override
  String get scheduleWakeStateExpired => 'Caducada';

  @override
  String get scheduleWakeStateCancelled => 'Cancelada';

  @override
  String scheduleWakeLine(String reason, String state) {
    return '$reason · $state';
  }

  @override
  String scheduleWakeExit(int code) {
    return 'salida $code';
  }

  @override
  String scheduleWakeEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos',
      one: '1 evento',
    );
    return '$_temp0';
  }

  @override
  String get scheduleWakesNone => 'Todavía no hay reactivaciones.';

  @override
  String get scheduleWakesOlder => 'Mostrar anteriores';

  @override
  String get improvementCandidateStaged =>
      'La habilidad propuesta se guarda como una revisión aparte. Evaluarla deja la habilidad activa sin cambios; la habilidad solo cambia cuando se acepta la propuesta.';

  @override
  String goalNextWaitingFallback(String time) {
    return 'Continúa cuando llegue lo que espera, o vuelve a mirar a las $time si no llega nada.';
  }

  @override
  String get steeringRefusalHeldByLimit =>
      'Los mensajes que retiene una pausa por límite de uso no se pueden enviar a mano mientras espera.';

  @override
  String steeringRefusalHeldByLimitAt(String time) {
    return 'Los mensajes que retiene una pausa por límite de uso no se pueden enviar a mano mientras espera. El límite se restablece a las $time.';
  }

  @override
  String heldSteeringLimitResetsAt(String time) {
    return 'El límite se restablece a las $time. Se envían cuando la persona para la que trabaja la ejecución la reanuda.';
  }

  @override
  String heldSteeringFromPerson(String name) {
    return 'De $name';
  }

  @override
  String get heldSteeringFromSomeoneElse => 'De otra persona';

  @override
  String get heldSteeringOnlyWriterSends =>
      'Solo la persona que escribió un mensaje retenido puede enviarlo.';

  @override
  String get steeringRefusalNotYours =>
      'Estos mensajes retenidos son de otra persona. Solo quien escribió uno puede enviarlo.';

  @override
  String improvementEvaluationSolved(
    int pairedRuns,
    int candidateSolved,
    int baselineSolved,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      pairedRuns,
      locale: localeName,
      other: 'En $pairedRuns ejecuciones emparejadas',
      one: 'En 1 ejecución emparejada',
    );
    return '$_temp0, el cambio resolvió $candidateSolved y la habilidad actual resolvió $baselineSolved.';
  }

  @override
  String improvementEvaluationWorse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tareas fueron peores con el cambio.',
      one: '1 tarea fue peor con el cambio.',
    );
    return '$_temp0';
  }

  @override
  String improvementEvaluationCostlier(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tareas costaron más con el cambio.',
      one: '1 tarea costó más con el cambio.',
    );
    return '$_temp0';
  }

  @override
  String improvementEvaluationHarnessErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ejecuciones tuvieron un error del arnés.',
      one: '1 ejecución tuvo un error del arnés.',
    );
    return '$_temp0';
  }

  @override
  String get improvementEvaluationIncomplete =>
      'La evaluación no se ejecutó completa.';

  @override
  String workFeedLimitParkExpires(String time) {
    return 'Caduca $time';
  }

  @override
  String workFeedSchedulePaused(String person, String agent) {
    return '$person pausó la programación de $agent.';
  }

  @override
  String get goalCardApproveNotYours =>
      'Solo la persona que inició la ejecución del pipeline puede aprobar la finalización de este objetivo.';

  @override
  String get goalCardObjective => 'El objetivo';

  @override
  String get planNeedsWrite =>
      'Aprobar o cambiar este plan requiere acceso de escritura a todos los repositorios de este espacio. Un administrador del espacio de trabajo puede concederlo.';

  @override
  String scheduleSpentWithChain(String spent, String cap) {
    return '$spent de $cap, incluidas todas las programaciones de su cadena';
  }

  @override
  String get ccLoading => 'Cargando';

  @override
  String get ccProgress => 'Progreso';

  @override
  String get ccBreadcrumb => 'Ruta de navegación';

  @override
  String get ccDialog => 'Cuadro de diálogo';

  @override
  String get ccResize => 'Cambiar tamaño';

  @override
  String ccUnverifiedLabel(String label) {
    return '$label (sin verificar)';
  }

  @override
  String prRowSelect(String title) {
    return 'Seleccionar $title';
  }

  @override
  String get prTableSelectAll => 'Seleccionar todos los pull requests';

  @override
  String planVersionRewind(int version) {
    return 'Restaurar la versión $version';
  }
}

/// The translations for Spanish Castilian, as used in Mexico (`es_MX`).
class AppLocalizationsEsMx extends AppLocalizationsEs {
  AppLocalizationsEsMx() : super('es_MX');

  @override
  String get dictationHoldToTalkDescription =>
      'Mantén presionado el botón del micrófono o el atajo para dictar y suéltalo para detener. Si está desactivado, presiona una vez para iniciar y otra para detener.';

  @override
  String get keybindingPushToTalk => 'Presionar para hablar';

  @override
  String get rigSurfaceComputer => 'Computadora';

  @override
  String get rigStartHint =>
      'Inicia una VM desechable que compartes con tus agentes en esta conversación. Se destruye al cerrarse y nada de lo que ocurre en ella toca tu computadora.';

  @override
  String get rigTabNeedsConversation =>
      'Abre primero una conversación: una máquina pertenece a una, para que tus agentes y tú vean la misma pantalla.';

  @override
  String get rigMenuComputer => 'Computadora';

  @override
  String get errorReportingTitle => 'Compartir informes de fallas';

  @override
  String get errorReportingOnSubtitle =>
      'Se envían diagnósticos de fallas, errores y rendimiento para ayudar a corregir errores (solo en versiones de producción).';

  @override
  String get errorReportingOffSubtitle =>
      'Los diagnósticos están desactivados. No se envía ningún informe de fallas ni de errores.';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Envía diagnósticos de fallas, errores y rendimiento para ayudarnos a solucionar problemas más rápido (solo en versiones de producción). Puedes cambiar esto en cualquier momento en Ajustes → Privacidad.';

  @override
  String watchVideoOn(String provider) {
    return 'Ver video en $provider';
  }

  @override
  String get meetingToolbarHoldToStop =>
      'Mantén presionado para detener la grabación';

  @override
  String get generalSectionComputers => 'Computadoras';

  @override
  String get generalComputersEmpty => 'Ninguna computadora abierta';

  @override
  String get keepAwakeTitle =>
      'Mantener la computadora activa mientras los agentes trabajan';

  @override
  String get keepAwakeOnSubtitle =>
      'La computadora no se suspenderá mientras un agente esté trabajando';

  @override
  String get keepAwakeOffSubtitle =>
      'La computadora puede suspenderse aunque un agente esté trabajando';

  @override
  String get modalityVideo => 'Video';

  @override
  String get profileDeliveryMetrics => 'Métricas de entrega';

  @override
  String profileMetricsSample(int count) {
    return 'PR analizados: $count';
  }

  @override
  String get profileMergeRate => 'Tasa de fusión';

  @override
  String get profileReviewCoverage => 'Cobertura de revisión';

  @override
  String get profilePrSize => 'Tamaño del PR';

  @override
  String get profileTimeToMerge => 'Tiempo hasta la fusión';

  @override
  String get profileFirstReview => 'Tiempo hasta la primera revisión';

  @override
  String get profileMetricsTruncated =>
      'Los percentiles se calculan a partir de una muestra limitada de las solicitudes de incorporación de cambios disponibles.';

  @override
  String profileLinesChanged(String count) {
    return '$count líneas';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count min';
  }

  @override
  String profileDurationHours(int count) {
    return '$count h';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '$days d $hours h';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return 'Miembros: $count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return 'No hay pull requests de $team en este espacio de trabajo';
  }

  @override
  String get profilePrStateFilterLabel => 'Filtrar pull requests por estado';

  @override
  String get noProfilePrsMatchSearchHint =>
      'Prueba con otro título o número de pull request';

  @override
  String get workspaceConnectOwnHint =>
      'Solo se usan las apps de este espacio de trabajo. Agrega cada una abajo, junto a su proveedor. Un proveedor sin app está desactivado aquí; no se usan en su lugar las apps de este servidor ni Connect.';

  @override
  String connectionUnreachable(String provider) {
    return 'No se puede contactar con $provider en este momento. Reintentando.';
  }

  @override
  String get signInUnavailableConnectUnreachable =>
      'No se puede contactar con el servicio de inicio de sesión de este espacio de trabajo en este momento.';

  @override
  String forgeTokenRequiredBody(String provider) {
    return 'Esto se ejecuta en tu nombre en $provider y no has agregado un token. Agrega uno y vuelve a intentarlo.';
  }

  @override
  String repoAccessSelectTitle(String repos) {
    return 'Agrega $repos a los repositorios de la GitHub App';
  }

  @override
  String get automationTokenStored => 'Token de acceso agregado';

  @override
  String get automationTokenGitLabHint =>
      'Pega un token de acceso de proyecto o de grupo. Necesita read_api y read_repository; agrega api y write_repository para comentarios, merge requests y pushes. GitLab muestra su trabajo como el bot del token.';

  @override
  String get automationTokenRemoveBody =>
      'La automatización que depende de este token se pausa hasta que se agregue otro.';

  @override
  String get settingsCoauthorCreditDescription =>
      'Tus commits nombran a Control Center (@usectrl) como coautor, y las ejecuciones automáticas que activaste te nombran a ti. Si está desactivado, no se agrega ninguna de las dos líneas.';

  @override
  String get settingsWorkspaceCoauthorCreditAlways =>
      'Agregar siempre el crédito de coautoría';

  @override
  String get settingsWorkspaceCoauthorCreditNever =>
      'No agregar nunca el crédito de coautoría';

  @override
  String get settingsCommitSigningCreated =>
      'Clave de firma creada. Agrégala a tu cuenta de la forja.';

  @override
  String get settingsCommitSigningAddTitle =>
      'Agrégala a tu cuenta de la forja';

  @override
  String get settingsCommitSigningBitbucketSteps =>
      'Los commits en Bitbucket no se firman. No agregues esta clave a tu cuenta de Bitbucket: una clave SSH allí también es un inicio de sesión.';

  @override
  String get noWorkspaceInviteBody =>
      'Un administrador del espacio de trabajo tiene que invitarte, o el propietario del servidor puede crear un espacio de trabajo para ti. Se abrirá aquí en cuanto te agreguen.';

  @override
  String repoLinkNoWorkspaceToAddTo(String repo) {
    return '$repo no está en ninguno de tus espacios de trabajo, y no estás en un espacio de trabajo al que agregarlo. Pide a un administrador del espacio de trabajo que te invite.';
  }

  @override
  String get auditLogOutcomeOk => 'Exitoso';

  @override
  String get auditLogTimeAdd => 'Agregar';

  @override
  String repoLinkAskOwnerToAdd(String repo) {
    return '$repo no está vinculado en ninguno de tus espacios de trabajo. Pide al propietario del servidor que lo agregue.';
  }

  @override
  String get reposEmptyAskOwner =>
      'El propietario del servidor agrega repositorios desde las carpetas del servidor.';

  @override
  String get repoPathIssueUnusable =>
      'Esta carpeta no puede usarse como repositorio. Elimínala y agrega el repositorio desde otra carpeta.';

  @override
  String get goalCardAddCheck => 'Agregar comprobación';

  @override
  String get improvementOperationAdd => 'Agrega';

  @override
  String get goalContractAddCheck => 'Agregar comprobación';

  @override
  String get goalContractAddCriterion => 'Agregar criterio';

  @override
  String get scheduleExtendDays => 'Agregar días';

  @override
  String get improvementCampaignUnavailable =>
      'Las evaluaciones no pueden ejecutarse en este servidor en este momento.';
}
