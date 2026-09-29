import type { LandingCopy } from "./landing-en";

export const ptPt: LandingCopy = {
  meta: {
    title: "Control Center \\\\ Um sítio para o teu dia de desenvolvimento",
    description:
      "Reúne tickets, revisões de código, agentes de IA, reuniões e pipelines. Um espaço de trabalho gratuito e de código aberto para computador, web e telemóvel.",
    imageAlt:
      "Control Center, o teu trabalho de desenvolvimento num só espaço.",
  },
  nav: {
    product: "Produto",
    workflows: "Fluxos",
    features: "Funcionalidades",
    docs: "Documentação",
    demo: "Experimentar a demo",
    download: "Transferir",
    menu: "Menu",
    primary: "Navegação principal",
    mobile: "Navegação móvel",
    home: "Início do Control Center",
    skip: "Saltar para o conteúdo",
    language: "Idioma",
    appearance: "Aspeto",
    light: "Claro",
    dark: "Escuro",
    system: "Sistema",
  },
  hero: {
    line1: "Muita coisa em movimento.",
    line2: "Um só Control Center.",
    description:
      "Um sítio para o teu código, os teus agentes, as revisões e tudo o resto que enche um dia de desenvolvimento.",
    download: "Obter o Control Center",
    demo: "Explorar a demo em direto",
    platforms: "macOS, Windows, Linux",
    web: "Também na web e no telemóvel",
  },
  media: {
    phone:
      "O companheiro para telemóvel mostra o mesmo espaço de trabalho, uma aprovação pendente e o estado de uma execução de agente.",
  },
  tour: {
    label: "Explorar o Control Center",
    previous: "Vista anterior do produto",
    next: "Vista seguinte do produto",
    play: "Reproduzir a visita",
    pause: "Pausar a visita",
    videoPlay: "Reproduzir a pré-visualização",
    videoPause: "Pausar a pré-visualização",
    expand: "Expandir a pré-visualização",
    preview: "Pré-visualização do produto",
    close: "Fechar a pré-visualização",
    note: "Um olhar mais próximo sobre o teu dia de desenvolvimento.",
    imageLanguage: "Espaço reservado para imagem ou vídeo",
    stops: [
      {
        kind: "agents",
        label: "Agentes",
        title: "Dá espaço para o trabalho correr bem.",
        description:
          "Executa agentes em worktrees Git isoladas. Acompanha as ferramentas, orienta o trabalho e mantém o contexto.",
        alt: "Uma conversa com um agente no Control Center, com o contexto da tarefa e a atividade.",
      },
      {
        kind: "desk",
        label: "Caixa de entrada",
        title: "Começa pelo que precisa de ti.",
        description:
          "Pedidos de revisão, aprovações e bloqueios. A ação seguinte, sem procurar entre separadores.",
        alt: "Caixa de entrada do Control Center a agrupar pull requests por estado de revisão e a mostrar um bloqueio de sincronização.",
      },
      {
        kind: "review",
        label: "Revisão de código",
        title: "Lê a alteração. Percebe a história.",
        description:
          "Diffs, discussões e verificações ficam juntos. Publica a revisão com a tua própria conta.",
        alt: "Revisão de uma pull request no Control Center, com as alterações de código e o contexto da revisão.",
      },
      {
        kind: "tickets",
        label: "Tickets",
        title: "Mantém o passo seguinte ligado.",
        description:
          "Acompanha prioridades e responsáveis, sincroniza o Linear e liga a conversa onde o trabalho acontece.",
        alt: "Quadro de tickets do Control Center com as tarefas agrupadas por estado.",
      },
      {
        kind: "meetings",
        label: "Reuniões",
        title: "Guarda as decisões depois da chamada.",
        description:
          "Grava e transcreve no teu servidor. No fim da reunião tens notas e ações.",
        alt: "Uma reunião no Control Center com a transcrição e a informação da reunião.",
      },
      {
        kind: "pipelines",
        label: "Pipelines",
        title: "Torna repetível o trabalho que se repete.",
        description:
          "Constrói um fluxo, escolhe o gatilho e acompanha cada passo da execução.",
        alt: "Vista de pipeline do Control Center com os passos do fluxo e o estado da execução.",
      },
    ],
  },
  integrations: {
    title: "Traz as ferramentas com que já trabalhas.",
    note: "Ligadas através do teu servidor, e não como outra cópia do teu dia.",
  },
  grid: {
    title: "As ferramentas a que vais recorrer todos os dias.",
    description: "Faz o trabalho, revê o que mudou e guarda as decisões.",
    more: "Ler a documentação",
    items: [
      {
        title: "Agentes em paralelo",
        description:
          "Dá a cada tarefa uma worktree Git isolada. Acompanha a execução, orienta o agente ou assume o controlo sem perturbar o resto.",
        link: "Executar agentes em paralelo",
        kind: "agents",
        href: "/manual/guides/parallel-agents/",
      },
      {
        title: "Revisão de pull requests",
        description:
          "Lê os diffs com discussões e verificações ao lado. Acrescenta uma revisão de IA quando ajudar e publica com a tua própria conta da forge.",
        link: "Rever uma pull request",
        kind: "review",
        href: "/manual/guides/review-merge-pr/",
      },
      {
        title: "Tickets ligados",
        description:
          "Sincroniza o Linear, define prioridades e atribui o trabalho. Liga o ticket à conversa onde ele é feito.",
        link: "Gerir tickets",
        kind: "tickets",
        href: "/manual/guides/manage-tickets/",
      },
      {
        title: "Notas de reunião",
        description:
          "Grava e transcreve no teu servidor. As decisões e as ações ficam depois de a chamada terminar.",
        link: "Gravar uma reunião",
        kind: "meetings",
        href: "/manual/guides/record-meeting/",
      },
      {
        title: "Pipelines repetíveis",
        description:
          "Constrói um fluxo uma vez. Executa-o numa agenda, a partir de um evento ou à mão, e inspeciona cada passo.",
        link: "Criar um pipeline",
        kind: "pipelines",
        href: "/manual/guides/create-pipeline/",
      },
      {
        title: "Troca de contas",
        description:
          "Escolhe as contas que cada agente pode usar e alterna entre elas sem perder o contexto da execução.",
        link: "Gerir fornecedores de modelos",
        kind: "accounts",
        href: "/manual/guides/adapters/",
        alt: "Editor de grupos de contas do Control Center com as contas disponíveis para um agente.",
      },
      {
        title: "Quota de utilização",
        description:
          "Consulta o limite do fornecedor e as datas de reposição antes de iniciares a próxima execução.",
        link: "Gerir custos",
        kind: "quota",
        href: "/manual/guides/manage-costs/",
        alt: "Painel de utilização do Control Center com as quotas dos fornecedores e as datas de reposição.",
      },
      {
        title: "Paisagens sonoras e foco",
        description:
          "Faz uma sessão de foco com tempo definido, silencia as notificações e ajusta a paisagem sonora que toca em fundo.",
        link: "Usar o modo de foco",
        kind: "focus",
        href: "/manual/guides/focus-mode/",
        alt: "Temporizador de foco e controlos das paisagens sonoras no Control Center.",
      },
      {
        title: "Observabilidade",
        description:
          "Acompanha agentes ativos e consulta os custos, a utilização de tokens e a latência das execuções no teu espaço de trabalho.",
        link: "Inspecionar execuções dos agentes",
        kind: "observability",
        href: "/manual/guides/manage-costs/",
        alt: "Vista de observabilidade do Control Center com agentes ativos e análises das execuções.",
      },
      {
        title: "Editores de competências e agentes",
        description:
          "Edita as competências do espaço de trabalho e configura o modelo, as instruções e as permissões de cada agente.",
        link: "Gerir competências",
        kind: "editors",
        href: "/manual/guides/manage-skills/",
        alt: "Editor de competências e definições dos agentes no Control Center.",
      },
    ],
    supporting: [
      {
        title: "Uma caixa de entrada",
        description:
          "Revisões, aprovações e bloqueios numa só fila. Salta para a tarefa seguinte com a paleta de comandos.",
        href: "/manual/guides/triage-inbox/",
      },
      {
        title: "Consulta a partir do telemóvel",
        description:
          "Acompanha as execuções e trata das aprovações sem voltares à secretária.",
        href: "/manual/concepts/remote-control/",
      },
    ],
  },
  workflow: {
    title: "Não percas o fio.\nAté ficar publicado.",
    description:
      "O trabalho passa de uma ferramenta para outra. O contexto deve ir com ele.",
    label: "Um fluxo ligado",
    steps: [
      {
        title: "Começa pelo ticket.",
        text: "Define a prioridade, indica o responsável e liga a conversa. O ticket guarda o registo.",
        kind: "tickets",
        label: "A intenção",
      },
      {
        title: "Dá ao trabalho um espaço seu.",
        text: "Discute um plano, prepara uma worktree isolada e executa o agente. Orienta ou assume quando precisares.",
        kind: "agents",
        label: "O trabalho",
      },
      {
        title: "Traz o resultado para revisão.",
        text: "Lê as alterações, segue a discussão e publica com a tua conta da forge. A história mantém-se ligada.",
        kind: "review",
        label: "O resultado",
      },
    ],
  },
  boundaries: {
    title: "Aprova um push antes de ele correr.",
    description:
      "Põe os pushes de Git, a publicação de pull requests e outras ações protegidas atrás de uma aprovação. Revê o que o agente está prestes a fazer antes de alguma coisa mudar.",
    media:
      "Uma execução de agente em pausa num pedido de aprovação de um push de Git. Mostra o comando proposto, o diretório de trabalho e os controlos para aprovar ou recusar.",
    note: "Ninguém ligado para aprovar? A ação é recusada. As permissões são impostas pelo teu servidor, não por um prompt.",
    link: "Configurar aprovações de ações",
  },
  surfaces: {
    title: "A tua secretária é um sítio.\nO teu trabalho não.",
    description:
      "Começa no computador. Entra pelo navegador. Mantém-te perto a partir do telemóvel. Um servidor mantém a operação junta.",
    desktop: "Computador nativo",
    web: "No navegador",
    phone: "Companheiro para telemóvel",
    note: "O teu servidor é dono dos dados e da execução. Os teus dispositivos ficam sincronizados.",
    link: "Encontrar a tua plataforma",
  },
  faq: {
    title: "Boas perguntas.",
    description: "Algumas coisas a saber antes de te instalares.",
    items: [
      {
        question: "O Control Center é só para agentes de IA?",
        answer:
          "Não. O Control Center reúne tickets, pull requests, conversas, reuniões, calendário, pipelines, agentes e um leitor RSS pessoal num só espaço de trabalho. Os agentes são uma parte da secretária, não um requisito para usares o resto.",
        links: [
          { label: "Explorar as funcionalidades", href: "/pt-PT/#features" },
        ],
      },
      {
        question: "Qual é a diferença entre um ticket e uma conversa?",
        answer:
          "Um ticket regista o trabalho e o respetivo estado; a execução acontece numa conversa. A conversa pode preparar uma worktree isolada com copy-on-write antes de uma execução de agente. No Windows, essa preparação usa uma worktree Git.",
        links: [
          { label: "Seguir um fluxo de exemplo", href: "/pt-PT/#workflows" },
        ],
      },
      {
        question: "Onde correm os agentes e o que faz o servidor?",
        answer:
          "O servidor é dono da base de dados do espaço de trabalho, das credenciais, das APIs e da execução dos agentes; os clientes de computador e de navegador mostram e controlam esse trabalho. Workers opcionais da frota recolhem trabalhos em lease e transmitem eventos, mas não guardam a base de dados, as credenciais nem os orçamentos.",
        links: [
          {
            label: "Ler o guia de arquitetura",
            href: "/manual/concepts/architecture/",
          },
        ],
      },
      {
        question: "Quanto controlo tenho sobre a execução de um agente?",
        answer:
          "Cada conversa pode usar Somente propor, Agir com aprovação ou Agir livremente. As permissões e uma sandbox continuam a limitar as ações permitidas; os pedidos de aprovação sem alguém para aprovar são recusados. Os limites de orçamento suaves avisam, os rígidos pausam, e as execuções ficam registadas.",
        links: [{ label: "Ver os controlos", href: "/pt-PT/#boundaries" }],
      },
      {
        question: "Um plano do Orchestrate contrata agentes automaticamente?",
        answer:
          "Não. O Orchestrate pode pesquisar e propor papéis, tickets filhos e um plano, mas a contratação espera uma aprovação. O Plan Studio abre a partir da linha do plano na conversa de origem; atribuir um ticket sozinho não inicia uma execução.",
        links: [
          { label: "Seguir o fluxo de exemplo", href: "/pt-PT/#workflows" },
        ],
      },
      {
        question: "Posso executar agentes a partir do telemóvel emparelhado?",
        answer:
          "O telemóvel emparelhado é um cliente leve do mesmo espaço no servidor, não um segundo anfitrião de execução. Computador, navegador e telemóvel mostram a mesma operação; os agentes correm no servidor ou em workers opcionais da frota em lease.",
        links: [
          { label: "Ver as superfícies ligadas", href: "/pt-PT/#surfaces" },
        ],
      },
      {
        question: "Que integrações posso usar?",
        answer:
          "A sincronização de tickets com o Linear está implementada; o Jira e o ClickUp não têm adaptadores. Os eventos do Google Calendar ligados são só de leitura, e a resposta a convites só existe quando o calendário concede permissão de escrita. As conversas do Slack podem ligar-se às conversas do espaço, e as forges ligadas fornecem pull requests e verificações.",
        links: [{ label: "Ler o manual", href: "/manual/" }],
      },
      {
        question: "Quando aparecem as notas e as ações da reunião?",
        answer:
          "A transcrição em direto pode separar quem fala durante a gravação. Depois de parares, o agente de resumo processa a reunião e guarda notas, decisões e ações; gravação e processamento são estados distintos.",
        links: [{ label: "Ver o dia em contexto", href: "/pt-PT/#day" }],
      },
      {
        question: "A demo pública é um espaço de trabalho real?",
        answer:
          "A demo pública é uma versão separada e restringida, com dados inventados e agentes que seguem um guião. Os registos e as execuções são exemplos, não o teu trabalho.",
        links: [{ label: "Explorar a demo em direto", href: "/demo" }],
      },
    ],
  },
  pilot: {
    controls:
      "Parapente em 3D. Arrasta para rodar a vista e orientar o voo. As setas esquerda e direita fazem virar; as setas para cima e para baixo inclinam o voo para cima ou para baixo. R repõe; Espaço pausa ou retoma o voo e o vento.",
  },
  install: {
    title: "Fica\nà vontade.",
    description:
      "O teu próximo dia de desenvolvimento pode começar aqui. Gratuito e de código aberto.",
    mac: "Apple Silicon · macOS 13+",
    windows: "x64 · Windows 10+",
    linux: "x86_64 · AppImage",
    release: "Ver as versões",
    web: "Abrir a aplicação web",
    phone: "Abrir o companheiro para telemóvel",
    webNote: "Liga-te a um servidor que executas tu.",
    phoneNote:
      "Emparelha o telemóvel com o teu servidor através de um relay selado.",
    selfHost: "Preferes alojá-lo tu?",
    server: "Executar um servidor sem interface",
    guide: "Ler o guia de início rápido",
  },
  footer: {
    tagline: "Um sítio para o teu dia de desenvolvimento.",
    resources: "Recursos",
    source: "Código-fonte no GitHub",
    compare: "Comparar",
    changelog: "Registo de alterações",
    about: "Sobre",
    contact: "Contacto",
    privacy: "Privacidade",
    terms: "Termos",
    licenses: "Licenças",
    acknowledgements: "Agradecimentos",
    made: "Feito em aberto.",
    top: "Voltar ao topo",
  },
};
