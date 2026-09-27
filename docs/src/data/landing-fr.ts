import type { LandingCopy } from "./landing-en";

export const fr: LandingCopy = {
  meta: {
    title:
      "Control Center \\\\ Un point d’ancrage pour vos journées de développement",
    description:
      "Réunissez tickets, revues de code, agents IA, réunions et pipelines. Un espace de travail libre et gratuit pour ordinateur, navigateur et téléphone.",
    imageAlt:
      "Control Center, votre travail de développement réuni dans un seul espace.",
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
      "Un espace pour votre code, vos agents, vos revues et tout ce qui rythme votre journée de développement.",
    download: "Obtenir Control Center",
    demo: "Explorer la démo interactive",
    platforms: "macOS, Windows, Linux",
    web: "Aussi sur navigateur et téléphone",
  },
  media: {
    phone:
      "Compagnon sur téléphone affichant le même espace de travail, une validation en attente et l’état d’une exécution d’agent.",
  },
  tour: {
    label: "Découvrir Control Center",
    previous: "Vue précédente du produit",
    next: "Vue suivante du produit",
    play: "Lancer la visite",
    pause: "Mettre la visite en pause",
    expand: "Agrandir l’aperçu",
    close: "Fermer l’aperçu",
    preview: "Aperçu du produit",
    note: "Votre journée de développement, de plus près.",
    imageLanguage: "Emplacement réservé à une image ou une vidéo",
    stops: [
      {
        kind: "desk",
        label: "Votre journée",
        title: "Commencez par ce qui vous attend.",
        description:
          "Demandes de revue, validations et blocages. La prochaine action, sans chercher parmi les onglets.",
        alt: "Boîte de réception de Control Center regroupant les demandes de fusion par état de revue et affichant un blocage de synchronisation.",
      },
      {
        kind: "agents",
        label: "Agents",
        title: "Donnez aux agents de quoi travailler.",
        description:
          "Lancez-les dans des arbres de travail isolés. Suivez leurs outils, guidez leur travail et gardez le contexte.",
        alt: "Conversation avec un agent dans Control Center, montrant le contexte de sa tâche et son activité.",
      },
      {
        kind: "review",
        label: "Revue de code",
        title: "Lisez les changements, avec leur contexte.",
        description:
          "Diffs, discussions et vérifications restent ensemble. Publiez la revue avec votre propre compte.",
        alt: "Revue d’une demande de fusion dans Control Center, avec changements de code et contexte de revue.",
      },
      {
        kind: "tickets",
        label: "Tickets",
        title: "Gardez le fil de la prochaine étape.",
        description:
          "Suivez les priorités et les responsables, synchronisez Linear et liez la conversation où le travail se fait.",
        alt: "Tableau de tickets de Control Center affichant les tâches regroupées par statut.",
      },
      {
        kind: "meetings",
        label: "Réunions",
        title: "Gardez une trace des décisions.",
        description:
          "Enregistrez et transcrivez sur votre serveur. Retrouvez notes et actions à suivre une fois la réunion terminée.",
        alt: "Réunion dans Control Center avec transcription et informations sur la réunion.",
      },
      {
        kind: "pipelines",
        label: "Pipelines",
        title: "Répétez le travail qui doit l’être.",
        description:
          "Construisez un flux, choisissez son déclencheur et suivez chaque étape de son exécution.",
        alt: "Vue d’un pipeline dans Control Center avec étapes du flux et statut de l’exécution.",
      },
    ],
  },
  integrations: {
    title: "Retrouvez les outils que vous utilisez déjà.",
    note: "Connectés par votre serveur, sans recréer votre journée ailleurs.",
  },
  grid: {
    title: "Les outils dont vous vous servirez chaque jour.",
    description:
      "Faites avancer le travail, examinez les changements et gardez une trace des décisions.",
    more: "Lire la documentation",
    items: [
      {
        title: "Agents en parallèle",
        description:
          "Donnez à chaque tâche son propre arbre de travail Git. Suivez l’exécution, guidez l’agent ou reprenez la main sans perturber les autres.",
        link: "Lancer des agents en parallèle",
        kind: "agents",
        href: "/manual/guides/parallel-agents/",
      },
      {
        title: "Revue de pull request",
        description:
          "Lisez les diffs avec les discussions et les vérifications sous les yeux. Ajoutez une revue par IA si elle vous aide, puis publiez avec votre compte sur la forge.",
        link: "Passer une pull request en revue",
        kind: "review",
        href: "/manual/guides/review-merge-pr/",
      },
      {
        title: "Tickets reliés au travail",
        description:
          "Synchronisez Linear, définissez les priorités et attribuez les tâches. Liez chaque ticket à la conversation où le travail avance.",
        link: "Gérer les tickets",
        kind: "tickets",
        href: "/manual/guides/manage-tickets/",
      },
      {
        title: "Notes de réunion",
        description:
          "Enregistrez et transcrivez sur votre serveur. Retrouvez les décisions et les actions à suivre une fois la réunion terminée.",
        link: "Enregistrer une réunion",
        kind: "meetings",
        href: "/manual/guides/record-meeting/",
      },
      {
        title: "Pipelines réutilisables",
        description:
          "Créez un flux de travail une fois. Lancez-le à heure fixe, à la suite d’un événement ou à la main, et examinez chaque étape.",
        link: "Créer un pipeline",
        kind: "pipelines",
        href: "/manual/guides/create-pipeline/",
      },
      {
        title: "Changement de compte",
        description:
          "Choisissez les comptes accessibles à chaque agent, puis passez de l’un à l’autre sans perdre le contexte de l’exécution.",
        link: "Gérer les fournisseurs de modèles",
        kind: "accounts",
        href: "/manual/guides/adapters/",
        alt: "Éditeur de groupes de comptes dans Control Center affichant les comptes disponibles pour un agent.",
      },
      {
        title: "Quota d’utilisation",
        description:
          "Consultez les quotas des fournisseurs et leurs heures de réinitialisation avant de lancer la prochaine exécution.",
        link: "Gérer les coûts",
        kind: "quota",
        href: "/manual/guides/manage-costs/",
        alt: "Panneau d’utilisation de Control Center affichant les quotas des fournisseurs et les heures de réinitialisation.",
      },
      {
        title: "Ambiances sonores et concentration",
        description:
          "Lancez une séance de concentration chronométrée, coupez les notifications et adaptez l’ambiance sonore en fond.",
        link: "Utiliser le mode concentration",
        kind: "focus",
        href: "/manual/guides/focus-mode/",
        alt: "Minuteur de concentration et commandes des ambiances sonores de Control Center.",
      },
      {
        title: "Observabilité",
        description:
          "Suivez les agents actifs et consultez le coût, l’utilisation des tokens et la latence de leurs exécutions dans votre espace de travail.",
        link: "Examiner les exécutions des agents",
        kind: "observability",
        href: "/manual/guides/manage-costs/",
        alt: "Vue d’observabilité de Control Center affichant les agents actifs et les détails de leurs exécutions.",
      },
      {
        title: "Éditeurs de compétences et d’agents",
        description:
          "Modifiez les compétences de l’espace de travail et configurez le modèle, les instructions et les autorisations de chaque agent.",
        link: "Gérer les compétences",
        kind: "editors",
        href: "/manual/guides/manage-skills/",
        alt: "Éditeur de compétences et paramètres des agents dans Control Center.",
      },
    ],
    supporting: [
      {
        title: "Une seule boîte de réception",
        description:
          "Revues, validations et blocages au même endroit. Passez à la tâche suivante avec la palette de commandes.",
        href: "/manual/guides/triage-inbox/",
      },
      {
        title: "Un œil sur le travail depuis votre téléphone",
        description:
          "Suivez vos exécutions et donnez vos validations sans retourner à votre bureau.",
        href: "/manual/concepts/remote-control/",
      },
    ],
  },
  workflow: {
    title: "Gardez le fil.\nJusqu’à la livraison.",
    description:
      "Le travail passe d’un outil à l’autre. Son contexte doit suivre.",
    label: "Un flux de travail relié",
    steps: [
      {
        title: "Partez du ticket.",
        text: "Fixez la priorité, désignez un responsable et liez la conversation. Le ticket garde la trace du travail.",
        kind: "tickets",
        label: "L’intention",
      },
      {
        title: "Donnez au travail son espace.",
        text: "Discutez d’un plan, préparez un arbre de travail isolé et lancez l’agent. Guidez-le ou reprenez la main si besoin.",
        kind: "agents",
        label: "Le travail",
      },
      {
        title: "Passez le résultat en revue.",
        text: "Lisez les changements, suivez la discussion et publiez avec votre compte sur la forge. Le contexte reste lié.",
        kind: "review",
        label: "Le résultat",
      },
    ],
  },
  boundaries: {
    title: "Validez un push Git avant son exécution.",
    description:
      "Soumettez les push Git, les publications de pull requests et les autres actions protégées à une validation. Examinez ce que l’agent s’apprête à faire avant qu’il ne change quoi que ce soit.",
    media:
      "Une exécution d’agent en pause devant une demande de validation pour un push Git. Montrer la commande proposée, le répertoire de travail et les commandes pour approuver ou refuser.",
    note: "Personne pour valider ? L’action est refusée. Les permissions sont appliquées par votre serveur, pas par un prompt.",
    link: "Configurer les validations d’actions",
  },
  surfaces: {
    title: "Votre espace reste le même.\nOù que vous soyez.",
    description:
      "Commencez sur ordinateur. Consultez le travail dans un navigateur. Gardez le contact depuis votre téléphone. Un seul serveur relie le tout.",
    desktop: "Application de bureau native",
    web: "Dans votre navigateur",
    phone: "Compagnon sur téléphone",
    note: "Votre serveur gère les données et l’exécution. Vos appareils restent synchronisés.",
    link: "Choisir votre plateforme",
  },
  faq: {
    title: "Vos questions.",
    description: "Quelques repères avant de vous lancer.",
    items: [
      {
        question: "Control Center est-il réservé aux agents IA ?",
        answer:
          "Non. Control Center réunit tickets, demandes de fusion, conversations, réunions, calendrier, pipelines, agents et lecteur RSS personnel dans un seul espace de travail. Les agents en font partie, mais les autres outils fonctionnent sans eux.",
        links: [
          { label: "Découvrir les fonctionnalités", href: "/fr-FR/#features" },
        ],
      },
      {
        question: "Quelle différence entre un ticket et une conversation ?",
        answer:
          "Le ticket consigne le travail et son statut ; l’exécution se déroule dans une conversation. Celle-ci peut préparer un arbre de travail isolé à copie à l’écriture avant de lancer un agent. Sous Windows, cette préparation utilise un arbre de travail Git.",
        links: [
          {
            label: "Suivre un exemple de flux de travail",
            href: "/fr-FR/#workflows",
          },
        ],
      },
      {
        question:
          "Où les agents s’exécutent-ils et quel est le rôle du serveur ?",
        answer:
          "Le serveur gère la base de l’espace de travail, les identifiants, les API et l’exécution des agents ; les clients sur ordinateur et navigateur affichent et pilotent le travail. Des machines de travail facultatives peuvent récupérer des tâches sous bail et transmettre les événements, mais elles ne détiennent ni base de données, ni identifiants, ni budgets.",
        links: [
          {
            label: "Lire le guide d’architecture",
            href: "/manual/concepts/architecture/",
          },
        ],
      },
      {
        question: "Quel contrôle ai-je sur l’exécution d’un agent ?",
        answer:
          "Chaque conversation peut être réglée sur Proposer seulement, Agir avec validation ou Agir librement. Les permissions et le bac à sable limitent toujours les actions possibles ; sans personne pour valider une demande, elle est refusée. Les budgets souples alertent, les limites strictes mettent en pause et les exécutions sont journalisées.",
        links: [{ label: "Voir les contrôles", href: "/fr-FR/#boundaries" }],
      },
      {
        question:
          "Un plan Orchestrate recrute-t-il automatiquement des agents ?",
        answer:
          "Non. Orchestrate peut étudier et proposer des rôles, des tickets enfants et un plan, mais le recrutement attend une validation. Plan Studio s’ouvre depuis la ligne du plan dans sa conversation d’origine ; attribuer un ticket ne lance pas à lui seul une exécution.",
        links: [
          {
            label: "Suivre l’exemple de flux de travail",
            href: "/fr-FR/#workflows",
          },
        ],
      },
      {
        question: "Puis-je lancer des agents depuis mon téléphone associé ?",
        answer:
          "Le téléphone associé est un client léger relié au même espace sur le serveur, pas une deuxième machine d’exécution. Ordinateur, navigateur et téléphone montrent la même activité ; les agents s’exécutent sur le serveur ou, en option, sur des machines de travail qui reçoivent des tâches sous bail.",
        links: [
          { label: "Voir les interfaces connectées", href: "/fr-FR/#surfaces" },
        ],
      },
      {
        question: "Quelles intégrations puis-je utiliser ?",
        answer:
          "La synchronisation des tickets Linear fonctionne ; Jira et ClickUp n’ont pas de connecteurs. Les événements Google Calendar connectés sont en lecture seule, avec réponse aux invitations seulement si le calendrier accorde le droit d’écriture. Les fils Slack peuvent être reliés aux conversations, tandis que les forges connectées fournissent les demandes de fusion et leurs vérifications.",
        links: [{ label: "Lire le manuel", href: "/manual/" }],
      },
      {
        question:
          "Quand les notes et les actions d’une réunion apparaissent-elles ?",
        answer:
          "La transcription en direct peut distinguer les intervenants pendant l’enregistrement. Après l’arrêt, l’agent de synthèse traite la réunion et enregistre les notes, décisions et actions à suivre ; l’enregistrement et le traitement sont deux étapes distinctes.",
        links: [{ label: "Voir la journée en contexte", href: "/fr-FR/#day" }],
      },
      {
        question: "La démo publique est-elle un véritable espace de travail ?",
        answer:
          "La démo publique est une version distincte et verrouillée, avec des données fictives et des agents suivant des scénarios. Ses fiches et ses exécutions servent d’exemples : ce n’est pas votre travail.",
        links: [{ label: "Explorer la démo interactive", href: "/demo" }],
      },
    ],
  },
  pilot: {
    controls:
      "Parapente en 3D. Faites glisser pour tourner autour et piloter. Les flèches gauche et droite font virer ; celles du haut et du bas inclinent le vol vers le haut ou le bas. R réinitialise ; Espace met en pause ou reprend le vol et le vent.",
  },
  install: {
    title: "Prenez vos marques.",
    description:
      "Votre prochaine journée de développement peut commencer ici. Gratuit et libre.",
    mac: "Apple Silicon · macOS 13+",
    windows: "x64 · Windows 10+",
    linux: "x86_64 · AppImage",
    release: "Voir les versions",
    web: "Ouvrir l’application web",
    phone: "Ouvrir le compagnon sur téléphone",
    webNote: "Connectez-vous à un serveur que vous gérez.",
    phoneNote:
      "Associez votre téléphone à votre serveur par un relais chiffré.",
    selfHost: "Vous préférez l’héberger vous-même ?",
    server: "Installer un serveur sans interface",
    guide: "Lire le guide de démarrage rapide",
  },
  footer: {
    tagline: "Un point d’ancrage pour vos journées de développement.",
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
