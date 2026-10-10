import type { LandingCopy } from "./landing-en";

export const frCa: LandingCopy = {
  meta: {
    title:
      "Control Center \\\\ Un point d’ancrage pour tes journées de développement",
    description:
      "Réunis tickets, révisions de code, agents IA, réunions et pipelines. Un espace de travail libre et gratuit pour l’ordinateur, le navigateur et le téléphone.",
    imageAlt:
      "Control Center, ton travail de développement réuni dans un seul espace.",
  },
  nav: {
    product: "Produit",
    workflows: "Flux de travail",
    features: "Fonctionnalités",
    docs: "Documentation",
    demo: "Essayer la démo",
    download: "Télécharger",
    menu: "Menu",
    primary: "Navigation principale",
    mobile: "Navigation mobile",
    home: "Accueil de Control Center",
    skip: "Aller au contenu",
    language: "Langue",
    appearance: "Apparence",
    light: "Clair",
    dark: "Sombre",
    system: "Système",
  },
  hero: {
    line1: "Tant de choses à suivre.",
    line2: "Un seul Control Center.",
    description:
      "Un espace pour ton code, tes agents, tes révisions et tout ce qui rythme ta journée de développement.",
    download: "Obtenir Control Center",
    demo: "Explorer la démo interactive",
    platforms: "macOS, Windows, Linux",
    web: "Aussi dans le navigateur et sur le téléphone",
  },
  media: {
    phone:
      "Le compagnon sur téléphone affiche le même espace de travail, une approbation en attente et l’état d’une exécution d’agent.",
  },
  tour: {
    label: "Découvrir Control Center",
    previous: "Vue précédente du produit",
    next: "Vue suivante du produit",
    play: "Lancer la visite",
    pause: "Mettre la visite en pause",
    videoPlay: "Lire l’aperçu",
    videoPause: "Mettre l’aperçu en pause",
    expand: "Agrandir l’aperçu",
    preview: "Aperçu du produit",
    close: "Fermer l’aperçu",
    note: "Ta journée de développement, de plus près.",
    imageLanguage: "Emplacement réservé à une image ou à une vidéo",
    stops: [
      {
        kind: "agents",
        label: "Agents",
        title: "Donne aux agents de quoi travailler.",
        description:
          "Lance-les dans des arbres de travail isolés. Suis leurs outils, guide leur travail et garde le contexte.",
        alt: "Conversation avec un agent dans Control Center, montrant le contexte de sa tâche et son activité.",
      },
      {
        kind: "desk",
        label: "Boîte de réception",
        title: "Commence par ce qui t’attend.",
        description:
          "Demandes de révision, approbations et blocages. La prochaine action, sans chercher parmi les onglets.",
        alt: "Boîte de réception de Control Center regroupant les demandes de tirage par état de révision et affichant un blocage de synchronisation.",
      },
      {
        kind: "review",
        label: "Révision de code",
        title: "Lis les changements, avec leur contexte.",
        description:
          "Diffs, discussions et vérifications restent ensemble. Publie la révision avec ton propre compte.",
        alt: "Révision d’une demande de tirage dans Control Center, avec changements de code et contexte de révision.",
      },
      {
        kind: "tickets",
        label: "Tickets",
        title: "Garde l’étape suivante reliée.",
        description:
          "Suis les priorités et les responsabilités, synchronise Linear et relie la conversation où le travail se fait.",
        alt: "Tableau des tickets de Control Center, avec les tâches regroupées par état.",
      },
      {
        kind: "meetings",
        label: "Réunions",
        title: "Garde les décisions après l’appel.",
        description:
          "Enregistre et transcris sur ton serveur. À la fin de la réunion, tu as des notes et des actions.",
        alt: "Une réunion dans Control Center, avec la transcription et les renseignements sur la réunion.",
      },
      {
        kind: "pipelines",
        label: "Pipelines",
        title: "Rends le travail récurrent vraiment répétable.",
        description:
          "Construis un flux, choisis son déclencheur et suis chaque étape de l’exécution.",
        alt: "Vue de pipeline de Control Center, avec les étapes du flux et l’état de l’exécution.",
      },
    ],
  },
  integrations: {
    title: "Apporte les outils avec lesquels tu travailles déjà.",
    note: "Branchés par ton serveur, pas comme une autre copie de ta journée.",
  },
  grid: {
    title: "Les outils que tu vas prendre chaque jour.",
    description:
      "Fais le travail, révise ce qui a changé et garde les décisions.",
    more: "Lire la documentation",
    items: [
      {
        title: "Agents en parallèle",
        description:
          "Donne à chaque tâche un arbre de travail Git isolé. Suis l’exécution, guide l’agent ou prends le relais sans déranger le reste.",
        link: "Exécuter des agents en parallèle",
        kind: "agents",
        href: "/manual/guides/parallel-agents/",
      },
      {
        title: "Révision des demandes de tirage",
        description:
          "Lis les diffs à côté des discussions et des vérifications. Ajoute une révision par IA quand elle aide, puis publie avec ton compte de forge.",
        link: "Réviser une demande de tirage",
        kind: "review",
        href: "/manual/guides/review-merge-pr/",
      },
      {
        title: "Tickets reliés",
        description:
          "Synchronise Linear, fixe les priorités et assigne le travail. Relie le ticket à la conversation où il se fait.",
        link: "Gérer les tickets",
        kind: "tickets",
        href: "/manual/guides/manage-tickets/",
      },
      {
        title: "Notes de réunion",
        description:
          "Enregistre et transcris sur ton serveur. Les décisions et les actions restent après la fin de l’appel.",
        link: "Enregistrer une réunion",
        kind: "meetings",
        href: "/manual/guides/record-meeting/",
      },
      {
        title: "Pipelines répétables",
        description:
          "Construis un flux une fois. Lance-le selon un horaire, à partir d’un événement ou à la main, et inspecte chaque étape.",
        link: "Construire un pipeline",
        kind: "pipelines",
        href: "/manual/guides/create-pipeline/",
      },
      {
        title: "Changement de compte",
        description:
          "Choisis les comptes que chaque agent peut utiliser, puis passe de l’un à l’autre sans perdre le contexte de l’exécution.",
        link: "Gérer les fournisseurs de modèles",
        kind: "accounts",
        href: "/manual/guides/adapters/",
        alt: "Éditeur de groupes de comptes dans Control Center montrant les comptes disponibles pour un agent.",
      },
      {
        title: "Quota d’utilisation",
        description:
          "Vérifie les quotas des fournisseurs et leurs heures de réinitialisation avant de lancer la prochaine exécution.",
        link: "Gérer les coûts",
        kind: "quota",
        href: "/manual/guides/manage-costs/",
        alt: "Panneau d’utilisation de Control Center montrant les quotas des fournisseurs et les heures de réinitialisation.",
      },
      {
        title: "Ambiances sonores et concentration",
        description:
          "Lance une séance de concentration chronométrée, coupe les notifications et adapte l’ambiance sonore qui joue en fond.",
        link: "Utiliser le mode concentration",
        kind: "focus",
        href: "/manual/guides/focus-mode/",
        alt: "Minuteur de concentration et commandes des ambiances sonores de Control Center.",
      },
      {
        title: "Observabilité",
        description:
          "Suis les agents actifs et consulte les coûts, l’utilisation des jetons et la latence de leurs exécutions dans ton espace de travail.",
        link: "Examiner les exécutions des agents",
        kind: "observability",
        href: "/manual/guides/manage-costs/",
        alt: "Vue d’observabilité de Control Center montrant les agents actifs et les détails de leurs exécutions.",
      },
      {
        title: "Éditeurs de compétences et d’agents",
        description:
          "Modifie les compétences de l’espace de travail et configure le modèle, les instructions et les permissions de chaque agent.",
        link: "Gérer les compétences",
        kind: "editors",
        href: "/manual/guides/manage-skills/",
        alt: "Éditeur de compétences et paramètres des agents dans Control Center.",
      },
    ],
    supporting: [
      {
        title: "Une boîte de réception",
        description:
          "Révisions, approbations et blocages dans une seule file. Passe à la tâche suivante avec la palette de commandes.",
        href: "/manual/guides/triage-inbox/",
      },
      {
        title: "Jette un œil depuis ton téléphone",
        description:
          "Suis tes exécutions et traite les approbations sans revenir à ton bureau.",
        href: "/manual/concepts/remote-control/",
      },
    ],
  },
  workflow: {
    title: "Garde le fil.\nJusqu’à la livraison.",
    description:
      "Le travail passe d’un outil à l’autre. Son contexte devrait suivre.",
    label: "Un flux relié",
    steps: [
      {
        title: "Commence par le ticket.",
        text: "Fixe la priorité, nomme le responsable et relie la conversation. Le ticket garde la trace.",
        kind: "tickets",
        label: "L’intention",
      },
      {
        title: "Donne au travail son propre espace.",
        text: "Discute d’un plan, prépare un arbre de travail isolé et lance l’agent. Guide ou prends le relais quand il le faut.",
        kind: "agents",
        label: "Le travail",
      },
      {
        title: "Amène le résultat en révision.",
        text: "Lis les changements, suis la discussion et publie avec ton compte de forge. L’histoire reste reliée.",
        kind: "review",
        label: "Le résultat",
      },
    ],
  },
  boundaries: {
    title: "Approuve un push avant qu’il parte.",
    description:
      "Place les push Git, la publication des demandes de tirage et les autres actions protégées derrière une approbation. Regarde ce que l’agent s’apprête à faire avant que quoi que ce soit change.",
    media:
      "Une exécution d’agent en pause sur une demande d’approbation d’un push Git. Montre la commande proposée, le répertoire de travail et les commandes pour approuver ou refuser.",
    note: "Personne n’est branché pour approuver? L’action est refusée. Les permissions sont appliquées par ton serveur, pas par une invite.",
    link: "Configurer les approbations d’actions",
  },
  surfaces: {
    title: "Ton bureau est un endroit.\nTon travail, non.",
    description:
      "Commence sur l’ordinateur. Consulte le travail dans un navigateur. Reste proche depuis ton téléphone. Un seul serveur relie le tout.",
    desktop: "Application de bureau native",
    web: "Dans ton navigateur",
    phone: "Compagnon sur téléphone",
    note: "Ton serveur gère les données et l’exécution. Tes appareils restent synchronisés.",
    link: "Choisir ta plateforme",
  },
  faq: {
    title: "De bonnes questions.",
    description: "Quelques repères avant de t’installer.",
    items: [
      {
        question: "Control Center est-il réservé aux agents IA?",
        answer:
          "Non. Control Center réunit tickets, demandes de tirage, conversations, réunions, calendrier, pipelines, agents et lecteur RSS personnel dans un seul espace de travail. Les agents en font partie, mais les autres outils fonctionnent sans eux.",
        links: [
          { label: "Découvrir les fonctionnalités", href: "/fr-CA/#features" },
        ],
      },
      {
        question:
          "Quelle est la différence entre un ticket et une conversation?",
        answer:
          "Le ticket consigne le travail et son état; l’exécution se déroule dans une conversation. Celle-ci peut préparer un arbre de travail isolé à copie sur écriture avant de lancer un agent. Sous Windows, cette préparation utilise un arbre de travail Git.",
        links: [
          {
            label: "Suivre un exemple de flux de travail",
            href: "/fr-CA/#workflows",
          },
        ],
      },
      {
        question:
          "Où les agents s’exécutent-ils et quel est le rôle du serveur?",
        answer:
          "Le serveur gère la base de l’espace de travail, les identifiants, les API et l’exécution des agents; les clients sur ordinateur et dans le navigateur affichent et pilotent le travail. Des machines de travail facultatives peuvent récupérer des tâches sous bail et transmettre les événements, mais elles ne détiennent ni base de données, ni identifiants, ni budgets.",
        links: [
          {
            label: "Lire le guide d’architecture",
            href: "/manual/concepts/architecture/",
          },
        ],
      },
      {
        question: "Quel contrôle as-tu sur l’exécution d’un agent?",
        answer:
          "Chaque conversation peut être réglée sur Proposer uniquement, Agir avec approbation ou Agir librement. Les permissions et le bac à sable limitent toujours les actions possibles; sans personne pour approuver une demande, elle est refusée. Les budgets souples alertent, les limites strictes mettent en pause et les exécutions sont journalisées.",
        links: [{ label: "Voir les contrôles", href: "/fr-CA/#boundaries" }],
      },
      {
        question:
          "Un plan Orchestrate recrute-t-il automatiquement des agents?",
        answer:
          "Non. Orchestrate peut étudier et proposer des rôles, des tickets enfants et un plan, mais le recrutement attend une approbation. Plan Studio s’ouvre depuis la ligne du plan dans sa conversation d’origine; attribuer un ticket ne lance pas à lui seul une exécution.",
        links: [
          {
            label: "Suivre l’exemple de flux de travail",
            href: "/fr-CA/#workflows",
          },
        ],
      },
      {
        question: "Puis-je lancer des agents depuis mon téléphone associé?",
        answer:
          "Le téléphone associé est un client léger relié au même espace sur le serveur, pas une deuxième machine d’exécution. Ordinateur, navigateur et téléphone montrent la même activité; les agents s’exécutent sur le serveur ou, en option, sur des machines de travail qui reçoivent des tâches sous bail.",
        links: [
          { label: "Voir les interfaces connectées", href: "/fr-CA/#surfaces" },
        ],
      },
      {
        question: "Quelles intégrations puis-je utiliser?",
        answer:
          "La synchronisation des tickets Linear fonctionne; Jira et ClickUp n’ont pas de connecteurs. Les événements Google Calendar connectés sont en lecture seule, avec réponse aux invitations seulement si le calendrier accorde le droit d’écriture. Les fils Slack peuvent être reliés aux conversations, et les forges connectées fournissent les demandes de tirage et leurs vérifications.",
        links: [{ label: "Lire le manuel", href: "/manual/" }],
      },
      {
        question:
          "Quand les notes et les actions d’une réunion apparaissent-elles?",
        answer:
          "La transcription en direct peut distinguer les intervenants pendant l’enregistrement. Après l’arrêt, l’agent de synthèse traite la réunion et enregistre les notes, décisions et actions à suivre; l’enregistrement et le traitement sont deux étapes distinctes.",
        links: [{ label: "Voir la journée en contexte", href: "/fr-CA/#day" }],
      },
      {
        question: "La démo publique est-elle un véritable espace de travail?",
        answer:
          "La démo publique est une version distincte et verrouillée, avec des données fictives et des agents qui suivent des scénarios. Ses fiches et ses exécutions servent d’exemples : ce n’est pas ton travail.",
        links: [{ label: "Explorer la démo interactive", href: "/demo" }],
      },
    ],
  },
  pilot: {
    controls:
      "Parapente en 3D. Glisse pour tourner autour et piloter. Les flèches gauche et droite font virer; celles du haut et du bas inclinent le vol vers le haut ou le bas. R réinitialise; Espace met en pause ou reprend le vol et le vent.",
  },
  install: {
    title: "Installe-toi\nici.",
    description:
      "Ta prochaine journée de développement peut commencer ici. Gratuit et libre.",
    mac: "Apple Silicon · macOS 13+",
    windows: "x64 · ARM64 · Windows 10+",
    linux: "x86_64 · AppImage",
    release: "Voir les versions",
    web: "Ouvrir l’application web",
    phone: "Ouvrir le compagnon sur téléphone",
    webNote: "Connecte-toi à un serveur que tu gères.",
    phoneNote: "Associe ton téléphone à ton serveur par un relais chiffré.",
    selfHost: "Tu préfères l’héberger toi-même?",
    server: "Installer un serveur sans interface",
    guide: "Lire le guide de démarrage rapide",
  },
  footer: {
    tagline: "Un point d’ancrage pour tes journées de développement.",
    resources: "Ressources",
    source: "Code source sur GitHub",
    compare: "Comparer",
    changelog: "Historique des changements",
    about: "À propos",
    contact: "Contact",
    privacy: "Confidentialité",
    terms: "Conditions d’utilisation",
    licenses: "Licences",
    acknowledgements: "Remerciements",
    made: "Développé au grand jour.",
    top: "Retour en haut",
  },
};
