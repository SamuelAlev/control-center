import type { LandingCopy } from "./landing-en";

export const es: LandingCopy = {
  meta: {
    title: "Control Center \\\\ Un lugar para tu día de desarrollo",
    description:
      "Reúne tickets, revisiones de código, agentes de IA, reuniones y pipelines. Un espacio de trabajo gratuito y de código abierto para escritorio, web y teléfono.",
    imageAlt: "Control Center, tu trabajo de desarrollo en un solo espacio.",
  },
  nav: {
    product: "Producto",
    workflows: "Flujos",
    features: "Funciones",
    docs: "Documentación",
    demo: "Probar la demo",
    download: "Descargar",
    menu: "Menú",
    primary: "Navegación principal",
    mobile: "Navegación móvil",
    home: "Inicio de Control Center",
    skip: "Saltar al contenido",
    language: "Idioma",
    appearance: "Apariencia",
    light: "Claro",
    dark: "Oscuro",
    system: "Sistema",
  },
  hero: {
    line1: "Muchas piezas en movimiento.",
    line2: "Un solo Control Center.",
    description:
      "Un lugar para tu código, tus agentes, las revisiones y todo lo demás que llena un día de desarrollo.",
    download: "Obtener Control Center",
    demo: "Explorar la demo en vivo",
    platforms: "macOS, Windows, Linux",
    web: "También en la web y en el teléfono",
  },
  media: {
    phone:
      "El compañero para el teléfono muestra el mismo espacio de trabajo, una aprobación pendiente y el estado de una ejecución de agente.",
  },
  tour: {
    label: "Explorar Control Center",
    previous: "Vista anterior del producto",
    next: "Vista siguiente del producto",
    play: "Reproducir el recorrido",
    pause: "Pausar el recorrido",
    videoPlay: "Reproducir la vista previa",
    videoPause: "Pausar la vista previa",
    expand: "Ampliar la vista previa",
    preview: "Vista previa del producto",
    close: "Cerrar la vista previa",
    note: "Una mirada más de cerca a tu día de desarrollo.",
    imageLanguage: "Marcador de posición de imagen o vídeo",
    stops: [
      {
        kind: "agents",
        label: "Agentes",
        title: "Deja sitio para que el trabajo salga bien.",
        description:
          "Ejecuta agentes en worktrees de Git aislados. Sigue sus herramientas, orienta el trabajo y conserva el contexto.",
        alt: "Una conversación con un agente en Control Center, con el contexto de la tarea y la actividad.",
      },
      {
        kind: "desk",
        label: "Bandeja de entrada",
        title: "Empieza por lo que te necesita.",
        description:
          "Solicitudes de revisión, aprobaciones y bloqueos. La siguiente acción, sin buscar entre pestañas.",
        alt: "Bandeja de entrada de Control Center que agrupa las pull requests por estado de revisión y muestra un bloqueo de sincronización.",
      },
      {
        kind: "review",
        label: "Revisión de código",
        title: "Lee el cambio. Entiende la historia.",
        description:
          "Diffs, conversaciones y comprobaciones permanecen juntos. Publica la revisión con tu propia cuenta.",
        alt: "Revisión de una pull request en Control Center, con los cambios de código y el contexto de la revisión.",
      },
      {
        kind: "tickets",
        label: "Tickets",
        title: "Mantén conectado el siguiente paso.",
        description:
          "Sigue prioridades y responsables, sincroniza Linear y enlaza la conversación donde se hace el trabajo.",
        alt: "Tablero de tickets de Control Center con las tareas agrupadas por estado.",
      },
      {
        kind: "meetings",
        label: "Reuniones",
        title: "Conserva las decisiones después de la llamada.",
        description:
          "Graba y transcribe en tu servidor. Al terminar la reunión tienes notas y tareas.",
        alt: "Una reunión en Control Center con la transcripción y la información de la reunión.",
      },
      {
        kind: "pipelines",
        label: "Pipelines",
        title: "Haz repetible el trabajo que se repite.",
        description:
          "Crea un flujo, elige su disparador y sigue cada paso de la ejecución.",
        alt: "Vista de pipeline de Control Center con los pasos del flujo y el estado de la ejecución.",
      },
    ],
  },
  integrations: {
    title: "Trae las herramientas con las que ya trabajas.",
    note: "Conectadas a través de tu servidor, no como otra copia de tu día.",
  },
  grid: {
    title: "Las herramientas que vas a usar cada día.",
    description:
      "Haz el trabajo, revisa lo que cambió y guarda las decisiones.",
    more: "Leer la documentación",
    items: [
      {
        title: "Agentes en paralelo",
        description:
          "Dale a cada tarea un worktree de Git aislado. Sigue la ejecución, orienta al agente o toma el control sin molestar al resto.",
        link: "Ejecutar agentes en paralelo",
        kind: "agents",
        href: "/manual/guides/parallel-agents/",
      },
      {
        title: "Revisión de pull requests",
        description:
          "Lee los diffs con las conversaciones y las comprobaciones al lado. Añade una revisión con IA cuando ayude y publica con tu propia cuenta de la forja.",
        link: "Revisar una pull request",
        kind: "review",
        href: "/manual/guides/review-merge-pr/",
      },
      {
        title: "Tickets conectados",
        description:
          "Sincroniza Linear, fija prioridades y asigna el trabajo. Enlaza el ticket con la conversación donde se resuelve.",
        link: "Gestionar tickets",
        kind: "tickets",
        href: "/manual/guides/manage-tickets/",
      },
      {
        title: "Notas de reunión",
        description:
          "Graba y transcribe en tu servidor. Las decisiones y las tareas siguen ahí cuando termina la llamada.",
        link: "Grabar una reunión",
        kind: "meetings",
        href: "/manual/guides/record-meeting/",
      },
      {
        title: "Pipelines repetibles",
        description:
          "Crea un flujo una vez. Ejecútalo con una programación, a partir de un evento o a mano, y revisa cada paso.",
        link: "Crear un pipeline",
        kind: "pipelines",
        href: "/manual/guides/create-pipeline/",
      },
      {
        title: "Cambio de cuentas",
        description:
          "Elige qué cuentas puede usar cada agente y alterna entre ellas sin perder el contexto de la ejecución.",
        link: "Gestionar proveedores de modelos",
        kind: "accounts",
        href: "/manual/guides/adapters/",
        alt: "Editor de grupos de cuentas de Control Center con las cuentas disponibles para un agente.",
      },
      {
        title: "Cuota de uso",
        description:
          "Comprueba los límites de los proveedores y cuándo se restablecen antes de iniciar la siguiente ejecución.",
        link: "Gestionar costes",
        kind: "quota",
        href: "/manual/guides/manage-costs/",
        alt: "Panel de uso de Control Center con las cuotas de los proveedores y las horas de restablecimiento.",
      },
      {
        title: "Paisajes sonoros y concentración",
        description:
          "Inicia una sesión de concentración con temporizador, silencia las notificaciones y ajusta el paisaje sonoro de fondo.",
        link: "Usar el modo de concentración",
        kind: "focus",
        href: "/manual/guides/focus-mode/",
        alt: "Temporizador de concentración y controles de paisajes sonoros de Control Center.",
      },
      {
        title: "Observabilidad",
        description:
          "Sigue a los agentes activos y consulta los costes, el uso de tokens y la latencia de sus ejecuciones en tu espacio de trabajo.",
        link: "Examinar ejecuciones de agentes",
        kind: "observability",
        href: "/manual/guides/manage-costs/",
        alt: "Vista de observabilidad de Control Center con agentes activos y datos sobre sus ejecuciones.",
      },
      {
        title: "Editores de habilidades y agentes",
        description:
          "Edita las habilidades del espacio de trabajo y configura el modelo, las instrucciones y los permisos de cada agente.",
        link: "Gestionar habilidades",
        kind: "editors",
        href: "/manual/guides/manage-skills/",
        alt: "Editor de habilidades y ajustes de agentes de Control Center.",
      },
    ],
    supporting: [
      {
        title: "Una bandeja de entrada",
        description:
          "Revisiones, aprobaciones y bloqueos en una sola cola. Salta a la siguiente tarea con la paleta de comandos.",
        href: "/manual/guides/triage-inbox/",
      },
      {
        title: "Consulta desde el teléfono",
        description:
          "Sigue tus ejecuciones y gestiona las aprobaciones sin volver al escritorio.",
        href: "/manual/concepts/remote-control/",
      },
    ],
  },
  workflow: {
    title: "No pierdas el hilo.\nHasta que esté publicado.",
    description:
      "El trabajo pasa de una herramienta a otra. El contexto debería ir con él.",
    label: "Un flujo conectado",
    steps: [
      {
        title: "Empieza por el ticket.",
        text: "Fija la prioridad, nombra al responsable y enlaza la conversación. El ticket guarda el registro.",
        kind: "tickets",
        label: "La intención",
      },
      {
        title: "Dale al trabajo su propio espacio.",
        text: "Comenta un plan, prepara un worktree aislado y ejecuta el agente. Orienta o toma el control cuando haga falta.",
        kind: "agents",
        label: "El trabajo",
      },
      {
        title: "Lleva el resultado a revisión.",
        text: "Lee los cambios, sigue la conversación y publica con tu cuenta de la forja. La historia sigue conectada.",
        kind: "review",
        label: "El resultado",
      },
    ],
  },
  boundaries: {
    title: "Aprueba un push antes de que se ejecute.",
    description:
      "Pon los push de Git, la publicación de pull requests y otras acciones protegidas detrás de una aprobación. Revisa lo que el agente está a punto de hacer antes de que cambie nada.",
    media:
      "Una ejecución de agente en pausa ante una solicitud de aprobación de un push de Git. Muestra el comando propuesto, el directorio de trabajo y los controles para aprobar o denegar.",
    note: "¿No hay nadie conectado para aprobar? La acción se deniega. Los permisos los aplica tu servidor, no un prompt.",
    link: "Configurar las aprobaciones de acciones",
  },
  surfaces: {
    title: "Tu escritorio es un lugar.\nTu trabajo no.",
    description:
      "Empieza en el escritorio. Entra desde el navegador. Sigue de cerca desde el teléfono. Un servidor mantiene la operación unida.",
    desktop: "Escritorio nativo",
    web: "En el navegador",
    phone: "Compañero para el teléfono",
    note: "Tu servidor posee los datos y la ejecución. Tus dispositivos permanecen sincronizados.",
    link: "Encontrar tu plataforma",
  },
  faq: {
    title: "Buenas preguntas.",
    description: "Algunas cosas que conviene saber antes de instalarte.",
    items: [
      {
        question: "¿Control Center es solo para agentes de IA?",
        answer:
          "No. Control Center reúne tickets, pull requests, conversaciones, reuniones, calendario, pipelines, agentes y un lector RSS personal en un mismo espacio de trabajo. Los agentes son una parte del escritorio, no un requisito para usar el resto.",
        links: [{ label: "Explorar las funciones", href: "/es-ES/#features" }],
      },
      {
        question: "¿Qué diferencia hay entre un ticket y una conversación?",
        answer:
          "Un ticket registra el trabajo y su estado; la ejecución ocurre en una conversación. La conversación puede preparar un worktree aislado de copia en escritura antes de una ejecución de agente. En Windows, esa preparación usa un worktree de Git.",
        links: [
          { label: "Seguir un flujo de ejemplo", href: "/es-ES/#workflows" },
        ],
      },
      {
        question: "¿Dónde se ejecutan los agentes y qué hace el servidor?",
        answer:
          "El servidor posee la base de datos del espacio de trabajo, las credenciales, las API y la ejecución de los agentes; los clientes de escritorio y de navegador muestran y controlan ese trabajo. Los workers opcionales de la flota recogen trabajos en arrendamiento y transmiten eventos, pero no guardan la base de datos, las credenciales ni los presupuestos.",
        links: [
          {
            label: "Leer la guía de arquitectura",
            href: "/manual/concepts/architecture/",
          },
        ],
      },
      {
        question: "¿Cuánto control tengo sobre la ejecución de un agente?",
        answer:
          "Cada conversación puede usar Solo proponer, Actuar con aprobación o Actuar libremente. Los permisos y un entorno aislado siguen limitando las acciones permitidas; las solicitudes de aprobación sin alguien que apruebe se deniegan. Los límites de presupuesto suaves avisan, los duros pausan, y las ejecuciones quedan registradas.",
        links: [{ label: "Ver los controles", href: "/es-ES/#boundaries" }],
      },
      {
        question: "¿Un plan de Orchestrate contrata agentes automáticamente?",
        answer:
          "No. Orchestrate puede investigar y proponer roles, tickets hijos y un plan, pero la contratación espera una aprobación. Plan Studio se abre desde la fila del plan en la conversación de origen; asignar un ticket no inicia una ejecución por sí solo.",
        links: [
          { label: "Seguir el flujo de ejemplo", href: "/es-ES/#workflows" },
        ],
      },
      {
        question: "¿Puedo ejecutar agentes desde el teléfono vinculado?",
        answer:
          "El teléfono vinculado es un cliente ligero del mismo espacio respaldado por el servidor, no un segundo equipo de ejecución. Escritorio, navegador y teléfono muestran la misma operación; los agentes se ejecutan en el servidor o en workers de flota opcionales en arrendamiento.",
        links: [
          { label: "Ver las superficies conectadas", href: "/es-ES/#surfaces" },
        ],
      },
      {
        question: "¿Qué integraciones puedo usar?",
        answer:
          "La sincronización de tickets con Linear está implementada; Jira y ClickUp no tienen adaptadores. Los eventos de Google Calendar conectados son de solo lectura, y la respuesta a invitaciones solo está disponible si el calendario concede permiso de escritura. Los hilos de Slack pueden enlazarse con las conversaciones, y las forjas conectadas aportan pull requests y comprobaciones.",
        links: [{ label: "Leer el manual", href: "/manual/" }],
      },
      {
        question: "¿Cuándo aparecen las notas de la reunión y las tareas?",
        answer:
          "La transcripción en vivo puede separar a quienes hablan mientras se graba. Al detenerla, el agente de resumen procesa la reunión y guarda las notas, las decisiones y las tareas; la grabación y el procesamiento son estados distintos.",
        links: [{ label: "Ver el día en contexto", href: "/es-ES/#day" }],
      },
      {
        question: "¿La demo pública es un espacio de trabajo real?",
        answer:
          "La demo pública es una versión aparte y restringida, con datos inventados y agentes que siguen un guion. Sus registros y ejecuciones son ejemplos, no tu trabajo.",
        links: [{ label: "Explorar la demo en vivo", href: "/demo" }],
      },
    ],
  },
  pilot: {
    controls:
      "Parapente en 3D. Arrastra para orbitar la vista y dirigirlo. Las flechas izquierda y derecha giran; las flechas arriba y abajo inclinan el vuelo hacia arriba o abajo. R restablece; Espacio pausa o reanuda el vuelo y el viento.",
  },
  install: {
    title: "Ponte\ncómodo.",
    description:
      "Tu próximo día de desarrollo puede empezar aquí. Gratuito y de código abierto.",
    mac: "Apple Silicon · macOS 13+",
    windows: "x64 · ARM64 · Windows 10+",
    linux: "x86_64 · AppImage",
    release: "Ver las versiones",
    web: "Abrir la aplicación web",
    phone: "Abrir el compañero para el teléfono",
    webNote: "Conéctate a un servidor que tú ejecutas.",
    phoneNote:
      "Vincula el teléfono con tu servidor a través de un relé cifrado.",
    selfHost: "¿Prefieres alojarlo tú?",
    server: "Ejecutar un servidor sin interfaz",
    guide: "Leer la guía de inicio rápido",
  },
  footer: {
    tagline: "Un lugar para tu día de desarrollo.",
    resources: "Recursos",
    source: "Código fuente en GitHub",
    compare: "Comparar",
    changelog: "Registro de cambios",
    about: "Acerca de",
    contact: "Contacto",
    privacy: "Privacidad",
    terms: "Términos",
    licenses: "Licencias",
    acknowledgements: "Agradecimientos",
    made: "Hecho en abierto.",
    top: "Volver arriba",
  },
};
