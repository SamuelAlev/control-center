import type { LandingCopy } from "./landing-en";

export const it: LandingCopy = {
  meta: {
    title: "Control Center \\\\ Una casa per la tua giornata da sviluppatore",
    description:
      "Riunisci ticket, revisioni del codice, agenti IA, riunioni e pipeline. Uno spazio di lavoro gratuito e open source per desktop, web e telefono.",
    imageAlt: "Control Center, il tuo lavoro di sviluppo in un solo spazio.",
  },
  nav: {
    product: "Prodotto",
    workflows: "Flussi",
    features: "Funzioni",
    docs: "Documentazione",
    demo: "Prova la demo",
    download: "Scarica",
    menu: "Menu",
    primary: "Navigazione principale",
    mobile: "Navigazione mobile",
    home: "Home di Control Center",
    skip: "Vai al contenuto",
    language: "Lingua",
    appearance: "Aspetto",
    light: "Chiaro",
    dark: "Scuro",
    system: "Sistema",
  },
  hero: {
    line1: "Tante parti in movimento.",
    line2: "Un solo Control Center.",
    description:
      "Una casa per il codice, gli agenti, le revisioni e tutto il resto che riempie una giornata da sviluppatore.",
    download: "Ottieni Control Center",
    demo: "Esplora la demo dal vivo",
    platforms: "macOS, Windows, Linux",
    web: "Anche su web e telefono",
  },
  media: {
    phone:
      "Il compagno per telefono mostra lo stesso spazio di lavoro, un’approvazione in attesa e lo stato di un’esecuzione di un agente.",
  },
  tour: {
    label: "Esplora Control Center",
    previous: "Vista precedente del prodotto",
    next: "Vista successiva del prodotto",
    play: "Avvia il tour",
    pause: "Metti in pausa il tour",
    expand: "Espandi l’anteprima",
    close: "Chiudi l’anteprima",
    preview: "Anteprima del prodotto",
    note: "Uno sguardo più da vicino alla tua giornata da sviluppatore.",
    imageLanguage: "Segnaposto per immagine o video",
    stops: [
      {
        kind: "desk",
        label: "La tua giornata",
        title: "Parti da ciò che ha bisogno di te.",
        description:
          "Richieste di revisione, approvazioni e blocchi. La prossima azione, senza cercare tra le schede.",
        alt: "Posta in arrivo di Control Center che raggruppa le pull request per stato di revisione e mostra un blocco di sincronizzazione.",
      },
      {
        kind: "agents",
        label: "Agenti",
        title: "Dai al lavoro lo spazio per riuscire.",
        description:
          "Esegui gli agenti in worktree Git isolati. Segui i loro strumenti, guida il lavoro e tieni il contesto.",
        alt: "Una conversazione con un agente in Control Center, con il contesto dell’attività e il suo lavoro.",
      },
      {
        kind: "review",
        label: "Revisione del codice",
        title: "Leggi la modifica. Capisci la storia.",
        description:
          "Diff, discussioni e controlli restano insieme. Pubblica la revisione con il tuo account.",
        alt: "Revisione di una pull request in Control Center, con le modifiche al codice e il contesto della revisione.",
      },
      {
        kind: "tickets",
        label: "Ticket",
        title: "Tieni collegato il passo successivo.",
        description:
          "Segui priorità e responsabilità, sincronizza Linear e collega la conversazione in cui si lavora.",
        alt: "Bacheca dei ticket di Control Center con le attività raggruppate per stato.",
      },
      {
        kind: "meetings",
        label: "Riunioni",
        title: "Tieni le decisioni dopo la chiamata.",
        description:
          "Registra e trascrivi sul tuo server. A fine riunione hai note e attività da fare.",
        alt: "Una riunione in Control Center con trascrizione e informazioni sulla riunione.",
      },
      {
        kind: "pipelines",
        label: "Pipeline",
        title: "Rendi ripetibile il lavoro che si ripete.",
        description:
          "Costruisci un flusso, scegli il suo trigger e segui ogni passo dell’esecuzione.",
        alt: "Vista pipeline di Control Center con i passi del flusso e lo stato dell’esecuzione.",
      },
    ],
  },
  integrations: {
    title: "Porta gli strumenti con cui lavori già.",
    note: "Collegati tramite il tuo server, non come un’altra copia della tua giornata.",
  },
  grid: {
    title: "Gli strumenti che userai ogni giorno.",
    description:
      "Svolgi il lavoro, rivedi ciò che è cambiato e conserva le decisioni.",
    more: "Leggi la documentazione",
    items: [
      {
        title: "Agenti in parallelo",
        description:
          "Dai a ogni attività un worktree Git isolato. Segui l’esecuzione, guida l’agente o prendi il controllo senza disturbare il resto.",
        link: "Eseguire agenti in parallelo",
        kind: "agents",
        href: "/manual/guides/parallel-agents/",
      },
      {
        title: "Revisione delle pull request",
        description:
          "Leggi i diff con discussioni e controlli accanto. Aggiungi una revisione IA quando serve, poi pubblica con il tuo account della forge.",
        link: "Revisionare una pull request",
        kind: "review",
        href: "/manual/guides/review-merge-pr/",
      },
      {
        title: "Ticket collegati",
        description:
          "Sincronizza Linear, imposta le priorità e assegna il lavoro. Collega il ticket alla conversazione in cui viene svolto.",
        link: "Gestire i ticket",
        kind: "tickets",
        href: "/manual/guides/manage-tickets/",
      },
      {
        title: "Note delle riunioni",
        description:
          "Registra e trascrivi sul tuo server. Decisioni e attività restano dopo la fine della chiamata.",
        link: "Registrare una riunione",
        kind: "meetings",
        href: "/manual/guides/record-meeting/",
      },
      {
        title: "Pipeline ripetibili",
        description:
          "Costruisci un flusso una volta. Eseguilo in base a una pianificazione, da un evento o a mano, e controlla ogni passo.",
        link: "Creare una pipeline",
        kind: "pipelines",
        href: "/manual/guides/create-pipeline/",
      },
      {
        title: "Cambio di account",
        description:
          "Scegli quali account può usare ogni agente e passa dall’uno all’altro senza perdere il contesto dell’esecuzione.",
        link: "Gestire i provider di modelli",
        kind: "accounts",
        href: "/manual/guides/adapters/",
        alt: "Editor dei gruppi di account in Control Center con gli account disponibili per un agente.",
      },
      {
        title: "Quote di utilizzo",
        description:
          "Controlla le quote dei provider e quando si azzerano prima di avviare l’esecuzione successiva.",
        link: "Gestire i costi",
        kind: "quota",
        href: "/manual/guides/manage-costs/",
        alt: "Pannello di utilizzo di Control Center con le quote dei provider e gli orari di azzeramento.",
      },
      {
        title: "Paesaggi sonori e concentrazione",
        description:
          "Avvia una sessione di concentrazione a tempo, silenzia le notifiche e modella il paesaggio sonoro di sottofondo.",
        link: "Usare la modalità concentrazione",
        kind: "focus",
        href: "/manual/guides/focus-mode/",
        alt: "Timer di concentrazione e controlli dei paesaggi sonori di Control Center.",
      },
      {
        title: "Osservabilità",
        description:
          "Segui gli agenti attivi e controlla costi, utilizzo dei token e latenza delle esecuzioni nel tuo spazio di lavoro.",
        link: "Esaminare le esecuzioni degli agenti",
        kind: "observability",
        href: "/manual/guides/manage-costs/",
        alt: "Vista di osservabilità di Control Center con agenti attivi e dettagli sulle esecuzioni.",
      },
      {
        title: "Editor di skill e agenti",
        description:
          "Modifica le skill dello spazio di lavoro e configura modello, istruzioni e permessi di ogni agente.",
        link: "Gestire le skill",
        kind: "editors",
        href: "/manual/guides/manage-skills/",
        alt: "Editor delle skill e impostazioni degli agenti in Control Center.",
      },
    ],
    supporting: [
      {
        title: "Una posta in arrivo",
        description:
          "Revisioni, approvazioni e blocchi in una sola coda. Passa all’attività successiva con la palette dei comandi.",
        href: "/manual/guides/triage-inbox/",
      },
      {
        title: "Controlla dal telefono",
        description:
          "Segui le esecuzioni e gestisci le approvazioni senza tornare alla scrivania.",
        href: "/manual/concepts/remote-control/",
      },
    ],
  },
  workflow: {
    title: "Tieni il filo.\nFino alla pubblicazione.",
    description:
      "Il lavoro passa da uno strumento all’altro. Il contesto dovrebbe seguirlo.",
    label: "Un flusso collegato",
    steps: [
      {
        title: "Parti dal ticket.",
        text: "Imposta la priorità, indica il responsabile e collega la conversazione. Il ticket tiene il registro.",
        kind: "tickets",
        label: "L’intento",
      },
      {
        title: "Dai al lavoro uno spazio suo.",
        text: "Discuti un piano, prepara un worktree isolato ed esegui l’agente. Guida o prendi il controllo quando serve.",
        kind: "agents",
        label: "Il lavoro",
      },
      {
        title: "Porta il risultato in revisione.",
        text: "Leggi le modifiche, segui la discussione e pubblica con il tuo account della forge. La storia resta collegata.",
        kind: "review",
        label: "Il risultato",
      },
    ],
  },
  boundaries: {
    title: "Approva un push prima che parta.",
    description:
      "Metti i push Git, la pubblicazione delle pull request e le altre azioni protette dietro un’approvazione. Controlla cosa sta per fare l’agente prima che cambi qualcosa.",
    media:
      "Un’esecuzione di agente in pausa su una richiesta di approvazione di un push Git. Mostra il comando proposto, la directory di lavoro e i controlli per approvare o rifiutare.",
    note: "Nessun approvatore collegato? L’azione viene rifiutata. I permessi li applica il tuo server, non un prompt.",
    link: "Configurare le approvazioni delle azioni",
  },
  surfaces: {
    title: "La scrivania è un luogo.\nIl lavoro no.",
    description:
      "Inizia sul desktop. Entra dal browser. Resta vicino dal telefono. Un server tiene insieme l’operazione.",
    desktop: "Desktop nativo",
    web: "Nel browser",
    phone: "Compagno per telefono",
    note: "Il tuo server possiede i dati e l’esecuzione. I dispositivi restano sincronizzati.",
    link: "Trova la tua piattaforma",
  },
  faq: {
    title: "Buone domande.",
    description: "Qualche cosa da sapere prima di sistemarti.",
    items: [
      {
        question: "Control Center è solo per gli agenti IA?",
        answer:
          "No. Control Center mette ticket, pull request, conversazioni, riunioni, calendario, pipeline, agenti e un lettore RSS personale in un solo spazio di lavoro. Gli agenti sono una parte della scrivania, non un requisito per usare il resto.",
        links: [{ label: "Esplora le funzioni", href: "/it-IT/#features" }],
      },
      {
        question: "Che differenza c’è tra un ticket e una conversazione?",
        answer:
          "Un ticket registra il lavoro e il suo stato; l’esecuzione avviene in una conversazione. La conversazione può preparare un worktree isolato in copy-on-write prima di un’esecuzione di un agente. Su Windows, quella preparazione usa un worktree Git.",
        links: [
          { label: "Segui un flusso di esempio", href: "/it-IT/#workflows" },
        ],
      },
      {
        question: "Dove girano gli agenti e cosa fa il server?",
        answer:
          "Il server possiede il database dello spazio di lavoro, le credenziali, le API e l’esecuzione degli agenti; i client desktop e browser mostrano e controllano quel lavoro. I worker opzionali della flotta prelevano lavori in lease e trasmettono gli eventi, ma non conservano database, credenziali o budget.",
        links: [
          {
            label: "Leggi la guida all’architettura",
            href: "/manual/concepts/architecture/",
          },
        ],
      },
      {
        question: "Quanto controllo ho su un’esecuzione di un agente?",
        answer:
          "Ogni conversazione può usare Solo proposta, Agisci con approvazione o Agisci liberamente. Permessi e sandbox continuano a limitare le azioni consentite; le richieste di approvazione senza un approvatore vengono rifiutate. I limiti di budget morbidi avvisano, quelli rigidi mettono in pausa, e le esecuzioni restano nel registro.",
        links: [{ label: "Vedi i controlli", href: "/it-IT/#boundaries" }],
      },
      {
        question: "Un piano Orchestrate assume agenti automaticamente?",
        answer:
          "No. Orchestrate può cercare e proporre ruoli, ticket figli e un piano, ma l’assunzione aspetta un’approvazione. Plan Studio si apre dalla riga del piano nella conversazione di origine; assegnare un ticket da solo non avvia un’esecuzione.",
        links: [
          { label: "Segui il flusso di esempio", href: "/it-IT/#workflows" },
        ],
      },
      {
        question: "Posso eseguire agenti dal telefono associato?",
        answer:
          "Il telefono associato è un client leggero dello stesso spazio sul server, non un secondo host di esecuzione. Desktop, browser e telefono mostrano la stessa operazione; gli agenti girano sul server o su worker di flotta opzionali in lease.",
        links: [
          { label: "Vedi le superfici collegate", href: "/it-IT/#surfaces" },
        ],
      },
      {
        question: "Quali integrazioni posso usare?",
        answer:
          "La sincronizzazione dei ticket con Linear è implementata; Jira e ClickUp non hanno adattatori. Gli eventi di Google Calendar collegati sono in sola lettura, e la risposta agli inviti è disponibile solo se il calendario concede il permesso di scrittura. I thread di Slack possono collegarsi alle conversazioni, e le forge collegate forniscono pull request e controlli.",
        links: [{ label: "Leggi il manuale", href: "/manual/" }],
      },
      {
        question: "Quando compaiono note e attività della riunione?",
        answer:
          "La trascrizione dal vivo può distinguere chi parla durante la registrazione. Quando la interrompi, l’agente di riepilogo elabora la riunione e salva note, decisioni e attività; registrazione ed elaborazione sono stati distinti.",
        links: [
          { label: "Vedi la giornata nel contesto", href: "/it-IT/#day" },
        ],
      },
      {
        question: "La demo pubblica è uno spazio di lavoro vero?",
        answer:
          "La demo pubblica è una build separata e limitata, con dati inventati e agenti che seguono un copione. I suoi record e le sue esecuzioni sono esempi, non il tuo lavoro.",
        links: [{ label: "Esplora la demo dal vivo", href: "/demo" }],
      },
    ],
  },
  pilot: {
    controls:
      "Parapendio in 3D. Trascina per orbitare intorno e sterzare. Le frecce sinistra e destra fanno virare; quelle su e giù inclinano il volo verso l’alto o il basso. R ripristina; Spazio mette in pausa o riprende il volo e il vento.",
  },
  install: {
    title: "Mettiti\ncomodo.",
    description:
      "La tua prossima giornata da sviluppatore può iniziare qui. Gratuito e open source.",
    mac: "Apple Silicon · macOS 13+",
    windows: "x64 · Windows 10+",
    linux: "x86_64 · AppImage",
    release: "Vedi le versioni",
    web: "Apri l’app web",
    phone: "Apri il compagno per telefono",
    webNote: "Collegati a un server che gestisci tu.",
    phoneNote: "Associa il telefono al tuo server tramite un relay cifrato.",
    selfHost: "Preferisci ospitarlo tu?",
    server: "Eseguire un server senza interfaccia",
    guide: "Leggi la guida rapida",
  },
  footer: {
    tagline: "Una casa per la tua giornata da sviluppatore.",
    resources: "Risorse",
    source: "Codice sorgente su GitHub",
    compare: "Confronta",
    changelog: "Registro delle modifiche",
    about: "Informazioni",
    contact: "Contatti",
    privacy: "Privacy",
    terms: "Termini",
    licenses: "Licenze",
    acknowledgements: "Riconoscimenti",
    made: "Costruito allo scoperto.",
    top: "Torna su",
  },
};
