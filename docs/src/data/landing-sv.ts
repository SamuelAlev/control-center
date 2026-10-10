import type { LandingCopy } from "./landing-en";

export const sv: LandingCopy = {
  meta: {
    title: "Control Center \\\\ Ett hem för din utvecklardag",
    description:
      "Samla ärenden, kodgranskning, AI-agenter, möten och pipelines. En gratis arbetsyta med öppen källkod för dator, webb och telefon.",
    imageAlt: "Control Center, ditt utvecklararbete i en arbetsyta.",
  },
  nav: {
    product: "Produkt",
    workflows: "Flöden",
    features: "Funktioner",
    docs: "Dokumentation",
    demo: "Prova demon",
    download: "Hämta",
    menu: "Meny",
    primary: "Huvudnavigering",
    mobile: "Mobilnavigering",
    home: "Control Center-startsidan",
    skip: "Hoppa till innehållet",
    language: "Språk",
    appearance: "Utseende",
    light: "Ljust",
    dark: "Mörkt",
    system: "System",
  },
  hero: {
    line1: "Många delar i rörelse.",
    line2: "Ett Control Center.",
    description:
      "Ett hem för din kod, dina agenter, granskningar och allt annat som fyller en utvecklardag.",
    download: "Hämta Control Center",
    demo: "Utforska livedemon",
    platforms: "macOS, Windows, Linux",
    web: "Också på webb och telefon",
  },
  media: {
    phone:
      "Telefonkompanjonen visar samma arbetsyta, ett väntande godkännande och status för en agentkörning.",
  },
  tour: {
    label: "Utforska Control Center",
    previous: "Föregående produktvy",
    next: "Nästa produktvy",
    play: "Spela rundturen",
    pause: "Pausa rundturen",
    videoPlay: "Spela förhandsvisningen",
    videoPause: "Pausa förhandsvisningen",
    expand: "Expandera förhandsvisningen",
    preview: "Produktförhandsvisning",
    close: "Stäng förhandsvisningen",
    note: "En närmare titt på din utvecklardag.",
    imageLanguage: "Platshållare för bild eller video",
    stops: [
      {
        kind: "agents",
        label: "Agenter",
        title: "Ge bra arbete rum att hända.",
        description:
          "Kör agenter i isolerade Git-worktrees. Följ deras verktyg, styr arbetet och behåll sammanhanget.",
        alt: "Ett agentsamtal i Control Center med uppgiftens sammanhang och aktiviteten.",
      },
      {
        kind: "desk",
        label: "Inkorg",
        title: "Börja med det som behöver dig.",
        description:
          "Granskningsförfrågningar, godkännanden och blockeringar. Nästa åtgärd, utan att leta bland flikar.",
        alt: "Control Centers inkorg grupperar pull requests efter granskningsstatus och visar en synkblockering.",
      },
      {
        kind: "review",
        label: "Kodgranskning",
        title: "Läs ändringen. Förstå historien.",
        description:
          "Diffar, diskussioner och kontroller stannar tillsammans. Publicera granskningen med ditt eget konto.",
        alt: "Pull request-granskning i Control Center med kodändringar och granskningssammanhang.",
      },
      {
        kind: "tickets",
        label: "Ärenden",
        title: "Håll nästa steg kopplat.",
        description:
          "Följ prioritet och ägarskap, synka Linear och länka samtalet där arbetet sker.",
        alt: "Ärendetavla i Control Center med uppgifter grupperade efter status.",
      },
      {
        kind: "meetings",
        label: "Möten",
        title: "Behåll besluten efter samtalet.",
        description:
          "Spela in och transkribera på din server. När mötet slutar har du anteckningar och åtgärder.",
        alt: "Ett möte i Control Center med transkript och mötesinformation.",
      },
      {
        kind: "pipelines",
        label: "Pipelines",
        title: "Gör det återkommande arbetet upprepningsbart.",
        description:
          "Bygg ett flöde, välj dess utlösare och följ varje steg i körningen.",
        alt: "Pipelinevy i Control Center med flödessteg och körningsstatus.",
      },
    ],
  },
  integrations: {
    title: "Ta med verktygen du redan arbetar i.",
    note: "Kopplade via din server, inte som ännu en kopia av dagen.",
  },
  grid: {
    title: "Verktygen du tar fram varje dag.",
    description: "Gör arbetet, granska det som ändrats och behåll besluten.",
    more: "Läs dokumentationen",
    items: [
      {
        title: "Parallella agenter",
        description:
          "Ge varje uppgift en isolerad Git-worktree. Följ körningen, styr en agent eller ta över utan att störa resten.",
        link: "Kör agenter parallellt",
        kind: "agents",
        href: "/manual/guides/parallel-agents/",
      },
      {
        title: "Pull request-granskning",
        description:
          "Läs diffar med diskussioner och kontroller bredvid. Lägg till en AI-granskning när den hjälper, och publicera sedan med ditt eget forge-konto.",
        link: "Granska en pull request",
        kind: "review",
        href: "/manual/guides/review-merge-pr/",
      },
      {
        title: "Kopplade ärenden",
        description:
          "Synka Linear, sätt prioritet och tilldela arbetet. Länka ärendet till samtalet där det blir gjort.",
        link: "Hantera ärenden",
        kind: "tickets",
        href: "/manual/guides/manage-tickets/",
      },
      {
        title: "Mötesanteckningar",
        description:
          "Spela in och transkribera på din server. Beslut och åtgärder finns kvar när samtalet tar slut.",
        link: "Spela in ett möte",
        kind: "meetings",
        href: "/manual/guides/record-meeting/",
      },
      {
        title: "Upprepningsbara pipelines",
        description:
          "Bygg ett flöde en gång. Kör det enligt schema, från en händelse eller för hand, och granska varje steg.",
        link: "Bygg en pipeline",
        kind: "pipelines",
        href: "/manual/guides/create-pipeline/",
      },
      {
        title: "Byt mellan konton",
        description:
          "Välj vilka konton varje agent kan använda och växla mellan dem utan att förlora körningens sammanhang.",
        link: "Hantera modellleverantörer",
        kind: "accounts",
        href: "/manual/guides/adapters/",
        alt: "Redigerare för kontopooler i Control Center med konton som en agent kan använda.",
      },
      {
        title: "Användningskvot",
        description:
          "Kontrollera leverantörernas kvoter och när de nollställs innan du startar nästa körning.",
        link: "Hantera kostnader",
        kind: "quota",
        href: "/manual/guides/manage-costs/",
        alt: "Användningspanel i Control Center med leverantörskvoter och tider för nollställning.",
      },
      {
        title: "Ljudlandskap och fokus",
        description:
          "Starta en tidsbestämd fokusstund, tysta meddelanden och forma ljudlandskapet som spelas i bakgrunden.",
        link: "Använd fokusläget",
        kind: "focus",
        href: "/manual/guides/focus-mode/",
        alt: "Fokustimer och kontroller för ljudlandskap i Control Center.",
      },
      {
        title: "Överblick",
        description:
          "Följ aktiva agenter och granska körningarnas kostnader, tokenförbrukning och svarstider på din arbetsyta.",
        link: "Granska agentkörningar",
        kind: "observability",
        href: "/manual/guides/manage-costs/",
        alt: "Överblick i Control Center med aktiva agenter och insikter om körningar.",
      },
      {
        title: "Redigerare för färdigheter och agenter",
        description:
          "Redigera arbetsytans färdigheter och ställ in varje agents modell, instruktioner och behörigheter.",
        link: "Hantera färdigheter",
        kind: "editors",
        href: "/manual/guides/manage-skills/",
        alt: "Redigerare för färdigheter och agentinställningar i Control Center.",
      },
    ],
    supporting: [
      {
        title: "En inkorg",
        description:
          "Granskningar, godkännanden och blockeringar i en kö. Hoppa till nästa uppgift med kommandopaletten.",
        href: "/manual/guides/triage-inbox/",
      },
      {
        title: "Kolla in från telefonen",
        description:
          "Följ dina körningar och hantera godkännanden utan att gå tillbaka till skrivbordet.",
        href: "/manual/concepts/remote-control/",
      },
    ],
  },
  workflow: {
    title: "Håll tråden.\nHela vägen till leverans.",
    description: "Arbete rör sig mellan verktyg. Sammanhanget ska följa med.",
    label: "Ett sammanhållet flöde",
    steps: [
      {
        title: "Börja med ärendet.",
        text: "Sätt prioriteten, namnge ägaren och länka samtalet. Ärendet håller protokollet.",
        kind: "tickets",
        label: "Avsikten",
      },
      {
        title: "Ge arbetet ett eget rum.",
        text: "Diskutera en plan, förbered en isolerad worktree och kör agenten. Styr eller ta över när du behöver.",
        kind: "agents",
        label: "Arbetet",
      },
      {
        title: "Ta in resultatet i granskning.",
        text: "Läs ändringarna, följ diskussionen och publicera med ditt forge-konto. Historien förblir kopplad.",
        kind: "review",
        label: "Resultatet",
      },
    ],
  },
  boundaries: {
    title: "Godkänn en push innan den körs.",
    description:
      "Lägg Git-pushar, publicering av pull requests och andra bevakade åtgärder bakom ett godkännande. Granska vad agenten tänker göra innan något ändras.",
    media:
      "En agentkörning pausad vid en begäran om godkännande av en Git-push. Visa det föreslagna kommandot, arbetskatalogen och kontrollerna för att godkänna eller neka.",
    note: "Ingen godkännare ansluten? Åtgärden nekas. Behörigheter upprätthålls av din server, inte av en prompt.",
    link: "Konfigurera åtgärdsgodkännanden",
  },
  surfaces: {
    title: "Skrivbordet är en plats.\nArbetet är det inte.",
    description:
      "Börja på datorn. Titta in i webbläsaren. Håll dig nära från telefonen. En server håller ihop arbetet.",
    desktop: "Inbyggd datorapp",
    web: "I webbläsaren",
    phone: "Telefonkompanjon",
    note: "Din server äger data och körningen. Dina enheter hålls synkade.",
    link: "Hitta din plattform",
  },
  faq: {
    title: "Bra frågor.",
    description: "Några saker att veta innan du slår dig ner.",
    items: [
      {
        question: "Är Control Center bara för AI-agenter?",
        answer:
          "Nej. Control Center samlar ärenden, pull requests, samtal, möten, kalender, pipelines, agenter och en personlig RSS-läsare i en arbetsyta. Agenter är en del av skrivbordet, inte ett krav för att använda resten.",
        links: [{ label: "Utforska funktionerna", href: "/sv-SE/#features" }],
      },
      {
        question: "Vad är skillnaden mellan ett ärende och ett samtal?",
        answer:
          "Ett ärende registrerar arbetet och dess status; utförandet sker i ett samtal. Samtalet kan förbereda en isolerad copy-on-write-worktree före en agentkörning. I Windows använder den förberedelsen en Git-worktree.",
        links: [{ label: "Följ ett exempelflöde", href: "/sv-SE/#workflows" }],
      },
      {
        question: "Var körs agenter, och vad gör servern?",
        answer:
          "Servern äger arbetsytans databas, autentiseringsuppgifter, API:er och agentkörning; dator- och webbläsarklienter visar och styr det arbetet. Valfria fleet-workers hämtar leasade jobb och strömmar händelser, men håller inte databasen, autentiseringsuppgifterna eller budgetarna.",
        links: [
          {
            label: "Läs arkitekturguiden",
            href: "/manual/concepts/architecture/",
          },
        ],
      },
      {
        question: "Hur mycket kontroll har jag över en agentkörning?",
        answer:
          "Varje samtal kan använda Bara föreslå, Agera med godkännande eller Agera fritt. Behörigheter och en sandlåda begränsar fortfarande tillåtna åtgärder; godkännandeförfrågningar utan godkännare nekas. Mjuka budgetgränser varnar, hårda pausar, och körningar sparar en logg.",
        links: [{ label: "Se kontrollerna", href: "/sv-SE/#boundaries" }],
      },
      {
        question: "Anställer en Orchestrate-plan agenter automatiskt?",
        answer:
          "Nej. Orchestrate kan undersöka och föreslå roller, underärenden och en plan, men anställning väntar på godkännande. Plan Studio öppnas från planraden i det ursprungliga samtalet; att tilldela ett ärende startar inte en körning av sig själv.",
        links: [{ label: "Följ exempelflödet", href: "/sv-SE/#workflows" }],
      },
      {
        question: "Kan jag köra agenter från den parkopplade telefonen?",
        answer:
          "Den parkopplade telefonen är en tunn klient för samma serverstödda arbetsyta, inte en andra körningsvärd. Dator, webbläsare och telefon visar samma arbete; agenter körs på servern eller på valfria leasade fleet-workers.",
        links: [{ label: "Se de anslutna ytorna", href: "/sv-SE/#surfaces" }],
      },
      {
        question: "Vilka integrationer kan jag använda?",
        answer:
          "Synk av ärenden med Linear är implementerad; Jira och ClickUp har inga adaptrar. Anslutna Google Calendar-händelser är skrivskyddade, och svar på inbjudan finns bara när kalendern ger skrivbehörighet. Slack-trådar kan kopplas till samtal, och anslutna forge-tjänster levererar pull requests och kontroller.",
        links: [{ label: "Läs handboken", href: "/manual/" }],
      },
      {
        question: "När dyker mötesanteckningar och åtgärder upp?",
        answer:
          "Livetranskriptet kan skilja talare åt under inspelningen. När du stoppar bearbetar sammanfattningsagenten mötet och sparar anteckningar, beslut och åtgärder; inspelning och bearbetning är skilda tillstånd.",
        links: [{ label: "Se dagen i sitt sammanhang", href: "/sv-SE/#day" }],
      },
      {
        question: "Är den offentliga demon en riktig arbetsyta?",
        answer:
          "Den offentliga demon är en separat, låst version med påhittade data och agenter som följer ett manus. Dess poster och körningar är exempel, inte ditt eget arbete.",
        links: [{ label: "Utforska livedemon", href: "/demo" }],
      },
    ],
  },
  pilot: {
    controls:
      "3D-skärmflygare. Dra för att rotera vyn och styra. Vänster- och högerpil svänger; upp- och nedpil vinklar flygningen uppåt eller nedåt. R återställer; mellanslag pausar eller återupptar flygningen och vinden.",
  },
  install: {
    title: "Känn dig\nhemma.",
    description:
      "Din nästa utvecklardag kan börja här. Gratis och öppen källkod.",
    mac: "Apple Silicon · macOS 13+",
    windows: "x64 · ARM64 · Windows 10+",
    linux: "x86_64 · AppImage",
    release: "Visa versioner",
    web: "Öppna webbappen",
    phone: "Öppna telefonkompanjonen",
    webNote: "Anslut till en server som du kör.",
    phoneNote: "Parkoppla telefonen med din server över ett slutet relä.",
    selfHost: "Vill du hellre drifta själv?",
    server: "Kör en server utan gränssnitt",
    guide: "Läs snabbstartsguiden",
  },
  footer: {
    tagline: "Ett hem för din utvecklardag.",
    resources: "Resurser",
    source: "Källkod på GitHub",
    compare: "Jämför",
    changelog: "Ändringslogg",
    about: "Om",
    contact: "Kontakt",
    privacy: "Integritet",
    terms: "Villkor",
    licenses: "Licenser",
    acknowledgements: "Tack",
    made: "Byggt i det öppna.",
    top: "Tillbaka till toppen",
  },
};
