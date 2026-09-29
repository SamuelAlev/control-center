import type { LandingCopy } from "./landing-en";

export const pt: LandingCopy = {
  meta: {
    title: "Control Center \\\\ Um lugar para o seu dia de desenvolvimento",
    description:
      "Reúna tickets, revisões de código, agentes de IA, reuniões e pipelines. Um espaço de trabalho gratuito e de código aberto para desktop, web e celular.",
    imageAlt:
      "Control Center, o seu trabalho de desenvolvimento em um só espaço.",
  },
  nav: {
    product: "Produto",
    workflows: "Fluxos",
    features: "Recursos",
    docs: "Documentação",
    demo: "Testar a demo",
    download: "Baixar",
    menu: "Menu",
    primary: "Navegação principal",
    mobile: "Navegação móvel",
    home: "Início do Control Center",
    skip: "Ir para o conteúdo",
    language: "Idioma",
    appearance: "Aparência",
    light: "Claro",
    dark: "Escuro",
    system: "Sistema",
  },
  hero: {
    line1: "Muita coisa em movimento.",
    line2: "Um só Control Center.",
    description:
      "Um lugar para o seu código, os seus agentes, as revisões e tudo o mais que preenche um dia de desenvolvimento.",
    download: "Obter o Control Center",
    demo: "Explorar a demo ao vivo",
    platforms: "macOS, Windows, Linux",
    web: "Também na web e no celular",
  },
  media: {
    phone:
      "O companheiro de celular mostra o mesmo espaço de trabalho, uma aprovação pendente e o status de uma execução de agente.",
  },
  tour: {
    label: "Explorar o Control Center",
    previous: "Visualização anterior do produto",
    next: "Próxima visualização do produto",
    play: "Reproduzir o tour",
    pause: "Pausar o tour",
    videoPlay: "Reproduzir a prévia",
    videoPause: "Pausar a prévia",
    expand: "Ampliar a prévia",
    preview: "Prévia do produto",
    close: "Fechar a prévia",
    note: "Um olhar mais de perto para o seu dia de desenvolvimento.",
    imageLanguage: "Espaço reservado para imagem ou vídeo",
    stops: [
      {
        kind: "desk",
        label: "O seu dia",
        title: "Comece pelo que precisa de você.",
        description:
          "Pedidos de revisão, aprovações e bloqueios. A próxima ação, sem caçar abas.",
        alt: "Caixa de entrada do Control Center agrupando pull requests por status de revisão e mostrando um bloqueio de sincronização.",
      },
      {
        kind: "agents",
        label: "Agentes",
        title: "Dê espaço para o trabalho acontecer bem.",
        description:
          "Execute agentes em worktrees Git isoladas. Acompanhe as ferramentas, oriente o trabalho e mantenha o contexto.",
        alt: "Uma conversa com um agente no Control Center, com o contexto da tarefa e a atividade.",
      },
      {
        kind: "review",
        label: "Revisão de código",
        title: "Leia a mudança. Entenda a história.",
        description:
          "Diffs, discussões e verificações ficam juntos. Publique a revisão com a sua própria conta.",
        alt: "Revisão de pull request no Control Center, com as mudanças de código e o contexto da revisão.",
      },
      {
        kind: "tickets",
        label: "Tickets",
        title: "Mantenha o próximo passo conectado.",
        description:
          "Acompanhe prioridades e responsáveis, sincronize o Linear e vincule a conversa onde o trabalho acontece.",
        alt: "Quadro de tickets do Control Center com as tarefas agrupadas por status.",
      },
      {
        kind: "meetings",
        label: "Reuniões",
        title: "Guarde as decisões depois da chamada.",
        description:
          "Grave e transcreva no seu servidor. Ao fim da reunião, você tem notas e itens de ação.",
        alt: "Uma reunião no Control Center com a transcrição e as informações da reunião.",
      },
      {
        kind: "pipelines",
        label: "Pipelines",
        title: "Torne repetível o trabalho que se repete.",
        description:
          "Monte um fluxo, escolha o gatilho e acompanhe cada etapa da execução.",
        alt: "Visão de pipeline do Control Center com as etapas do fluxo e o status da execução.",
      },
    ],
  },
  integrations: {
    title: "Traga as ferramentas com as quais você já trabalha.",
    note: "Conectadas pelo seu servidor, e não como outra cópia do seu dia.",
  },
  grid: {
    title: "As ferramentas que você vai usar todo dia.",
    description: "Faça o trabalho, revise o que mudou e guarde as decisões.",
    more: "Ler a documentação",
    items: [
      {
        title: "Agentes em paralelo",
        description:
          "Dê a cada tarefa uma worktree Git isolada. Acompanhe a execução, oriente o agente ou assuma o controle sem atrapalhar o resto.",
        link: "Executar agentes em paralelo",
        kind: "agents",
        href: "/manual/guides/parallel-agents/",
      },
      {
        title: "Revisão de pull requests",
        description:
          "Leia os diffs com discussões e verificações ao lado. Inclua uma revisão de IA quando ajudar e publique com a sua própria conta da forge.",
        link: "Revisar uma pull request",
        kind: "review",
        href: "/manual/guides/review-merge-pr/",
      },
      {
        title: "Tickets conectados",
        description:
          "Sincronize o Linear, defina prioridades e atribua o trabalho. Vincule o ticket à conversa em que ele é feito.",
        link: "Gerenciar tickets",
        kind: "tickets",
        href: "/manual/guides/manage-tickets/",
      },
      {
        title: "Notas de reunião",
        description:
          "Grave e transcreva no seu servidor. Decisões e itens de ação continuam lá quando a chamada termina.",
        link: "Gravar uma reunião",
        kind: "meetings",
        href: "/manual/guides/record-meeting/",
      },
      {
        title: "Pipelines repetíveis",
        description:
          "Monte um fluxo uma vez. Execute-o em um horário, a partir de um evento ou manualmente, e inspecione cada etapa.",
        link: "Criar um pipeline",
        kind: "pipelines",
        href: "/manual/guides/create-pipeline/",
      },
      {
        title: "Troca de contas",
        description:
          "Escolha as contas que cada agente pode usar e alterne entre elas sem perder o contexto da execução.",
        link: "Gerenciar provedores de modelos",
        kind: "accounts",
        href: "/manual/guides/adapters/",
        alt: "Editor de grupos de contas do Control Center mostrando as contas disponíveis para um agente.",
      },
      {
        title: "Cota de uso",
        description:
          "Confira o limite do provedor e os horários de renovação antes de iniciar a próxima execução.",
        link: "Gerenciar custos",
        kind: "quota",
        href: "/manual/guides/manage-costs/",
        alt: "Painel de uso do Control Center mostrando as cotas dos provedores e os horários de renovação.",
      },
      {
        title: "Paisagens sonoras e foco",
        description:
          "Faça uma sessão de foco com tempo definido, silencie as notificações e ajuste a paisagem sonora que toca ao fundo.",
        link: "Usar o modo foco",
        kind: "focus",
        href: "/manual/guides/focus-mode/",
        alt: "Temporizador de foco e controles de paisagens sonoras do Control Center.",
      },
      {
        title: "Observabilidade",
        description:
          "Acompanhe agentes ativos e consulte os custos, o uso de tokens e a latência das execuções no seu espaço de trabalho.",
        link: "Inspecionar execuções dos agentes",
        kind: "observability",
        href: "/manual/guides/manage-costs/",
        alt: "Visão de observabilidade do Control Center mostrando agentes ativos e análises das execuções.",
      },
      {
        title: "Editores de habilidades e agentes",
        description:
          "Edite as habilidades do espaço de trabalho e configure o modelo, as instruções e as permissões de cada agente.",
        link: "Gerenciar habilidades",
        kind: "editors",
        href: "/manual/guides/manage-skills/",
        alt: "Editor de habilidades e configurações de agentes do Control Center.",
      },
    ],
    supporting: [
      {
        title: "Uma caixa de entrada",
        description:
          "Revisões, aprovações e bloqueios em uma só fila. Vá para a próxima tarefa com a paleta de comandos.",
        href: "/manual/guides/triage-inbox/",
      },
      {
        title: "Acompanhe pelo celular",
        description:
          "Siga as execuções e cuide das aprovações sem voltar à mesa.",
        href: "/manual/concepts/remote-control/",
      },
    ],
  },
  workflow: {
    title: "Não perca o fio.\nAté o que foi publicado.",
    description:
      "O trabalho passa de uma ferramenta a outra. O contexto deve ir junto.",
    label: "Um fluxo conectado",
    steps: [
      {
        title: "Comece pelo ticket.",
        text: "Defina a prioridade, indique o responsável e vincule a conversa. O ticket guarda o registro.",
        kind: "tickets",
        label: "A intenção",
      },
      {
        title: "Dê ao trabalho um espaço próprio.",
        text: "Discuta um plano, prepare uma worktree isolada e execute o agente. Oriente ou assuma quando precisar.",
        kind: "agents",
        label: "O trabalho",
      },
      {
        title: "Leve o resultado para a revisão.",
        text: "Leia as mudanças, acompanhe a discussão e publique com a sua conta da forge. A história continua conectada.",
        kind: "review",
        label: "O resultado",
      },
    ],
  },
  boundaries: {
    title: "Aprove um push antes que ele rode.",
    description:
      "Coloque pushes do Git, a publicação de pull requests e outras ações protegidas atrás de uma aprovação. Revise o que o agente está prestes a fazer antes que algo mude.",
    media:
      "Uma execução de agente pausada em um pedido de aprovação de push do Git. Mostre o comando proposto, o diretório de trabalho e os controles para aprovar ou recusar.",
    note: "Ninguém conectado para aprovar? A ação é recusada. As permissões são aplicadas pelo seu servidor, não por um prompt.",
    link: "Configurar aprovações de ações",
  },
  surfaces: {
    title: "A sua mesa é um lugar.\nO seu trabalho não.",
    description:
      "Comece no desktop. Entre pelo navegador. Fique perto pelo celular. Um servidor mantém a operação junta.",
    desktop: "Desktop nativo",
    web: "No navegador",
    phone: "Companheiro de celular",
    note: "O seu servidor é dono dos dados e da execução. Os seus dispositivos ficam sincronizados.",
    link: "Encontrar a sua plataforma",
  },
  faq: {
    title: "Boas perguntas.",
    description: "Algumas coisas para saber antes de se instalar.",
    items: [
      {
        question: "O Control Center é só para agentes de IA?",
        answer:
          "Não. O Control Center reúne tickets, pull requests, conversas, reuniões, calendário, pipelines, agentes e um leitor RSS pessoal em um só espaço de trabalho. Os agentes são uma parte da mesa, não um requisito para usar o resto.",
        links: [{ label: "Explorar os recursos", href: "/pt-BR/#features" }],
      },
      {
        question: "Qual é a diferença entre um ticket e uma conversa?",
        answer:
          "Um ticket registra o trabalho e o status dele; a execução acontece em uma conversa. A conversa pode preparar uma worktree isolada com copy-on-write antes de uma execução de agente. No Windows, essa preparação usa uma worktree Git.",
        links: [
          { label: "Seguir um fluxo de exemplo", href: "/pt-BR/#workflows" },
        ],
      },
      {
        question: "Onde os agentes rodam e o que o servidor faz?",
        answer:
          "O servidor é dono do banco do espaço de trabalho, das credenciais, das APIs e da execução dos agentes; os clientes de desktop e de navegador exibem e controlam esse trabalho. Workers opcionais da frota pegam trabalhos em lease e transmitem eventos, mas não guardam o banco, as credenciais nem os orçamentos.",
        links: [
          {
            label: "Ler o guia de arquitetura",
            href: "/manual/concepts/architecture/",
          },
        ],
      },
      {
        question: "Quanto controle eu tenho sobre a execução de um agente?",
        answer:
          "Cada conversa pode usar Somente propor, Agir com aprovação ou Agir livremente. Permissões e um sandbox continuam limitando as ações permitidas; pedidos de aprovação sem alguém para aprovar são recusados. Limites de orçamento suaves avisam, os rígidos pausam, e as execuções ficam registradas.",
        links: [{ label: "Ver os controles", href: "/pt-BR/#boundaries" }],
      },
      {
        question: "Um plano do Orchestrate contrata agentes automaticamente?",
        answer:
          "Não. O Orchestrate pode pesquisar e propor papéis, tickets filhos e um plano, mas a contratação espera uma aprovação. O Plan Studio abre a partir da linha do plano na conversa de origem; atribuir um ticket sozinho não inicia uma execução.",
        links: [
          { label: "Seguir o fluxo de exemplo", href: "/pt-BR/#workflows" },
        ],
      },
      {
        question: "Posso executar agentes pelo celular pareado?",
        answer:
          "O celular pareado é um cliente leve do mesmo espaço no servidor, não um segundo host de execução. Desktop, navegador e celular mostram a mesma operação; os agentes rodam no servidor ou em workers opcionais da frota em lease.",
        links: [
          { label: "Ver as superfícies conectadas", href: "/pt-BR/#surfaces" },
        ],
      },
      {
        question: "Quais integrações posso usar?",
        answer:
          "A sincronização de tickets com o Linear está implementada; Jira e ClickUp não têm adaptadores. Eventos do Google Calendar conectados são somente leitura, e a resposta a convites só existe quando o calendário concede permissão de escrita. Threads do Slack podem se ligar às conversas, e as forges conectadas fornecem pull requests e verificações.",
        links: [{ label: "Ler o manual", href: "/manual/" }],
      },
      {
        question: "Quando as notas e os itens de ação da reunião aparecem?",
        answer:
          "A transcrição ao vivo pode separar quem fala durante a gravação. Depois que você para, o agente de resumo processa a reunião e guarda notas, decisões e itens de ação; gravação e processamento são estados distintos.",
        links: [{ label: "Ver o dia em contexto", href: "/pt-BR/#day" }],
      },
      {
        question: "A demo pública é um espaço de trabalho de verdade?",
        answer:
          "A demo pública é uma versão separada e restrita, com dados inventados e agentes que seguem um roteiro. Os registros e as execuções são exemplos, não o seu trabalho.",
        links: [{ label: "Explorar a demo ao vivo", href: "/demo" }],
      },
    ],
  },
  pilot: {
    controls:
      "Parapente em 3D. Arraste para girar a vista e controlar a direção. As setas esquerda e direita fazem virar; as setas para cima e para baixo inclinam o voo para cima ou para baixo. R restaura; Espaço pausa ou retoma o voo e o vento.",
  },
  install: {
    title: "Fique\nà vontade.",
    description:
      "O seu próximo dia de desenvolvimento pode começar aqui. Gratuito e de código aberto.",
    mac: "Apple Silicon · macOS 13+",
    windows: "x64 · Windows 10+",
    linux: "x86_64 · AppImage",
    release: "Ver as versões",
    web: "Abrir o app web",
    phone: "Abrir o companheiro de celular",
    webNote: "Conecte-se a um servidor que você executa.",
    phoneNote: "Pareie o celular com o seu servidor por um relay selado.",
    selfHost: "Prefere hospedar você mesmo?",
    server: "Executar um servidor sem interface",
    guide: "Ler o guia de início rápido",
  },
  footer: {
    tagline: "Um lugar para o seu dia de desenvolvimento.",
    resources: "Recursos",
    source: "Código-fonte no GitHub",
    compare: "Comparar",
    changelog: "Registro de mudanças",
    about: "Sobre",
    contact: "Contato",
    privacy: "Privacidade",
    terms: "Termos",
    licenses: "Licenças",
    acknowledgements: "Agradecimentos",
    made: "Feito em aberto.",
    top: "Voltar ao topo",
  },
};
