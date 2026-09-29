import type { LandingCopy } from "./landing-en";

export const cs: LandingCopy = {
  meta: {
    title: "Control Center \\\\ Domov pro tvůj vývojářský den",
    description:
      "Spoj tickety, revize kódu, AI agenty, schůzky a pipeline. Bezplatný pracovní prostor s otevřeným zdrojovým kódem pro počítač, web a telefon.",
    imageAlt:
      "Control Center, tvoje vývojářská práce v jednom pracovním prostoru.",
  },
  nav: {
    product: "Produkt",
    workflows: "Postupy",
    features: "Funkce",
    docs: "Dokumentace",
    demo: "Vyzkoušet demo",
    download: "Stáhnout",
    menu: "Nabídka",
    primary: "Hlavní navigace",
    mobile: "Mobilní navigace",
    home: "Domů Control Center",
    skip: "Přeskočit na obsah",
    language: "Jazyk",
    appearance: "Vzhled",
    light: "Světlý",
    dark: "Tmavý",
    system: "Systém",
  },
  hero: {
    line1: "Hodně pohyblivých částí.",
    line2: "Jeden Control Center.",
    description:
      "Domov pro kód, agenty, revize a všechno ostatní, z čeho se skládá vývojářský den.",
    download: "Získat Control Center",
    demo: "Prohlédnout živé demo",
    platforms: "macOS, Windows, Linux",
    web: "Také na webu a v telefonu",
  },
  media: {
    phone:
      "Telefonní společník ukazuje stejný pracovní prostor, čekající schválení a stav běhu agenta.",
  },
  tour: {
    label: "Prozkoumat Control Center",
    previous: "Předchozí pohled na produkt",
    next: "Další pohled na produkt",
    play: "Spustit prohlídku",
    pause: "Pozastavit prohlídku",
    videoPlay: "Přehrát náhled",
    videoPause: "Pozastavit náhled",
    expand: "Zvětšit náhled",
    preview: "Náhled produktu",
    close: "Zavřít náhled",
    note: "Bližší pohled na tvůj vývojářský den.",
    imageLanguage: "Zástupný symbol obrázku nebo videa",
    stops: [
      {
        kind: "agents",
        label: "Agenti",
        title: "Dej dobré práci prostor, aby se stala.",
        description:
          "Spouštěj agenty v izolovaných Git worktree. Sleduj jejich nástroje, řiď práci a udrž kontext.",
        alt: "Rozhovor s agentem v Control Center s kontextem úkolu a aktivitou.",
      },
      {
        kind: "desk",
        label: "Doručená pošta",
        title: "Začni tím, co tě potřebuje.",
        description:
          "Žádosti o revizi, schválení a blokace. Další krok, bez hledání v kartách.",
        alt: "Doručená pošta Control Center seskupuje pull requesty podle stavu revize a ukazuje blokaci synchronizace.",
      },
      {
        kind: "review",
        label: "Revize kódu",
        title: "Přečti změnu. Poznej příběh.",
        description:
          "Diffy, diskuse a kontroly zůstávají pohromadě. Publikuj revizi pod svým účtem.",
        alt: "Revize pull requestu v Control Center se změnami kódu a kontextem revize.",
      },
      {
        kind: "tickets",
        label: "Tickety",
        title: "Nenech další krok odpojený.",
        description:
          "Sleduj priority a vlastnictví, synchronizuj Linear a propoj rozhovor, kde práce vzniká.",
        alt: "Nástěnka ticketů Control Center s úkoly seskupenými podle stavu.",
      },
      {
        kind: "meetings",
        label: "Schůzky",
        title: "Nech rozhodnutí i po hovoru.",
        description:
          "Nahrávej a přepisuj na svém serveru. Po schůzce máš poznámky a úkoly.",
        alt: "Schůzka v Control Center s přepisem a informacemi o schůzce.",
      },
      {
        kind: "pipelines",
        label: "Pipeline",
        title: "Ať se opakovaná práce dá zopakovat.",
        description: "Sestav postup, zvol spouštěč a sleduj každý krok běhu.",
        alt: "Pohled na pipeline v Control Center s kroky postupu a stavem běhu.",
      },
    ],
  },
  integrations: {
    title: "Vezmi nástroje, se kterými už pracuješ.",
    note: "Připojené přes tvůj server, ne jako další kopie dne.",
  },
  grid: {
    title: "Nástroje, po kterých sáhneš každý den.",
    description: "Dělej práci, kontroluj změny a uchovávej rozhodnutí.",
    more: "Číst dokumentaci",
    items: [
      {
        title: "Agenti vedle sebe",
        description:
          "Dej každému úkolu izolovaný Git worktree. Sleduj běh, řiď agenta nebo převezmi řízení, aniž bys rušil zbytek.",
        link: "Spouštět agenty paralelně",
        kind: "agents",
        href: "/manual/guides/parallel-agents/",
      },
      {
        title: "Revize pull requestů",
        description:
          "Čti diffy vedle diskusí a kontrol. Přidej revizi pomocí AI, když pomůže, a publikuj vlastním účtem ve forge.",
        link: "Revidovat pull request",
        kind: "review",
        href: "/manual/guides/review-merge-pr/",
      },
      {
        title: "Propojené tickety",
        description:
          "Synchronizuj Linear, nastav priority a přiděl práci. Propoj ticket s rozhovorem, kde se udělá.",
        link: "Spravovat tickety",
        kind: "tickets",
        href: "/manual/guides/manage-tickets/",
      },
      {
        title: "Poznámky ze schůzek",
        description:
          "Nahrávej a přepisuj na svém serveru. Rozhodnutí a úkoly zůstanou i po skončení hovoru.",
        link: "Nahrát schůzku",
        kind: "meetings",
        href: "/manual/guides/record-meeting/",
      },
      {
        title: "Opakovatelné pipeline",
        description:
          "Sestav postup jednou. Spouštěj ho podle plánu, z události nebo ručně a prohlédni si každý krok.",
        link: "Sestavit pipeline",
        kind: "pipelines",
        href: "/manual/guides/create-pipeline/",
      },
      {
        title: "Přepínání účtů",
        description:
          "Vyber účty, které může každý agent používat, a střídej je bez ztráty kontextu běhu.",
        link: "Spravovat poskytovatele modelů",
        kind: "accounts",
        href: "/manual/guides/adapters/",
        alt: "Editor fondu účtů v Control Center ukazuje účty dostupné pro agenta.",
      },
      {
        title: "Limit využití",
        description:
          "Před dalším během zkontroluj limity poskytovatelů a časy jejich obnovení.",
        link: "Spravovat náklady",
        kind: "quota",
        href: "/manual/guides/manage-costs/",
        alt: "Panel využití v Control Center ukazuje limity poskytovatelů a časy jejich obnovení.",
      },
      {
        title: "Zvukové kulisy a soustředění",
        description:
          "Spusť časovaný blok soustředění, ztiš oznámení a uprav zvukovou kulisu, která ho doprovází.",
        link: "Používat režim soustředění",
        kind: "focus",
        href: "/manual/guides/focus-mode/",
        alt: "Časovač soustředění a ovládání zvukových kulis v Control Center.",
      },
      {
        title: "Přehled o bězích",
        description:
          "Sleduj aktivní agenty a prohlížej náklady, spotřebu tokenů a latenci jejich běhů ve svém pracovním prostoru.",
        link: "Prohlížet běhy agentů",
        kind: "observability",
        href: "/manual/guides/manage-costs/",
        alt: "Přehled běhů v Control Center s aktivními agenty a údaji o bězích.",
      },
      {
        title: "Editory dovedností a agentů",
        description:
          "Upravuj dovednosti pracovního prostoru a nastav model, pokyny a oprávnění každého agenta.",
        link: "Spravovat dovednosti",
        kind: "editors",
        href: "/manual/guides/manage-skills/",
        alt: "Editor dovedností a nastavení agentů v Control Center.",
      },
    ],
    supporting: [
      {
        title: "Jedna doručená pošta",
        description:
          "Revize, schválení a blokace v jedné frontě. Přejdi na další úkol paletou příkazů.",
        href: "/manual/guides/triage-inbox/",
      },
      {
        title: "Kontroluj z telefonu",
        description:
          "Sleduj běhy a vyřizuj schválení, aniž by ses vracel ke stolu.",
        href: "/manual/concepts/remote-control/",
      },
    ],
  },
  workflow: {
    title: "Drž nit.\nAž do vydání.",
    description: "Práce putuje mezi nástroji. Kontext by měl jít s ní.",
    label: "Propojený postup",
    steps: [
      {
        title: "Začni ticketem.",
        text: "Nastav prioritu, urči vlastníka a propoj rozhovor. Ticket drží záznam.",
        kind: "tickets",
        label: "Záměr",
      },
      {
        title: "Dej práci vlastní prostor.",
        text: "Prober plán, připrav izolovaný worktree a spusť agenta. Řiď, nebo převezmi, když je třeba.",
        kind: "agents",
        label: "Práce",
      },
      {
        title: "Vezmi výsledek do revize.",
        text: "Přečti změny, sleduj diskusi a publikuj svým účtem ve forge. Příběh zůstane spojený.",
        kind: "review",
        label: "Výsledek",
      },
    ],
  },
  boundaries: {
    title: "Schval push, než se spustí.",
    description:
      "Dej Git pushe, publikování pull requestů a další hlídané akce za schválení. Podívej se, co se agent chystá udělat, než se něco změní.",
    media:
      "Běh agenta pozastavený u žádosti o schválení Git pushe. Ukaž navržený příkaz, pracovní adresář a ovládání pro schválení nebo zamítnutí.",
    note: "Nikdo připojený ke schválení? Akce se zamítne. Oprávnění vynucuje tvůj server, ne prompt.",
    link: "Nastavit schvalování akcí",
  },
  surfaces: {
    title: "Stůl je místo.\nPráce ne.",
    description:
      "Začni na počítači. Nahlédni z prohlížeče. Zůstaň nablízku z telefonu. Jeden server drží provoz pohromadě.",
    desktop: "Nativní počítač",
    web: "V prohlížeči",
    phone: "Telefonní společník",
    note: "Tvůj server vlastní data a provádění. Zařízení zůstávají synchronizovaná.",
    link: "Najít svou platformu",
  },
  faq: {
    title: "Dobré otázky.",
    description: "Pár věcí, než se zabydlíš.",
    items: [
      {
        question: "Je Control Center jen pro AI agenty?",
        answer:
          "Ne. Control Center dává tickety, pull requesty, rozhovory, schůzky, kalendář, pipeline, agenty a osobní čtečku RSS do jednoho pracovního prostoru. Agenti jsou část stolu, ne podmínka pro používání zbytku.",
        links: [{ label: "Prozkoumat funkce", href: "/cs-CZ/#features" }],
      },
      {
        question: "Jaký je rozdíl mezi ticketem a rozhovorem?",
        answer:
          "Ticket zaznamenává práci a její stav; provádění se děje v rozhovoru. Rozhovor může před během agenta připravit izolovaný worktree s copy-on-write. Ve Windows tato příprava používá Git worktree.",
        links: [
          { label: "Sledovat ukázkový postup", href: "/cs-CZ/#workflows" },
        ],
      },
      {
        question: "Kde agenti běží a co dělá server?",
        answer:
          "Server vlastní databázi pracovního prostoru, přihlašovací údaje, API a provádění agentů; klienti na počítači a v prohlížeči tuto práci zobrazují a řídí. Volitelní pracovníci flotily si berou zapůjčené úlohy a streamují události, ale nedrží databázi, přihlašovací údaje ani rozpočty.",
        links: [
          {
            label: "Přečíst průvodce architekturou",
            href: "/manual/concepts/architecture/",
          },
        ],
      },
      {
        question: "Jak velkou kontrolu mám nad během agenta?",
        answer:
          "Každý rozhovor může používat Jen navrhovat, Jednat se schválením nebo Jednat volně. Oprávnění a sandbox dál omezují povolené akce; žádosti o schválení bez schvalovatele se zamítnou. Měkké limity rozpočtu varují, tvrdé pozastaví a běhy si vedou záznam.",
        links: [
          { label: "Podívat se na ovládání", href: "/cs-CZ/#boundaries" },
        ],
      },
      {
        question: "Najímá plán Orchestrate agenty automaticky?",
        answer:
          "Ne. Orchestrate umí prozkoumat a navrhnout role, podřízené tickety a plán, ale najímání čeká na schválení. Plan Studio se otevře z řádku plánu v původním rozhovoru; samotné přiřazení ticketu běh nespustí.",
        links: [
          { label: "Sledovat ukázkový postup", href: "/cs-CZ/#workflows" },
        ],
      },
      {
        question: "Můžu spouštět agenty ze spárovaného telefonu?",
        answer:
          "Spárovaný telefon je tenký klient téhož prostoru na serveru, ne druhý hostitel provádění. Počítač, prohlížeč i telefon ukazují stejný provoz; agenti běží na serveru nebo na volitelných zapůjčených pracovnících flotily.",
        links: [{ label: "Vidět propojené plochy", href: "/cs-CZ/#surfaces" }],
      },
      {
        question: "Jaké integrace můžu použít?",
        answer:
          "Synchronizace ticketů s Linear je hotová; Jira a ClickUp adaptéry nemají. Připojené události Google Calendar jsou jen ke čtení a odpověď na pozvánku je dostupná, jen když kalendář udělí právo zápisu. Vlákna Slacku se dají přemostit do rozhovorů a připojené forge dodávají pull requesty a kontroly.",
        links: [{ label: "Číst příručku", href: "/manual/" }],
      },
      {
        question: "Kdy se objeví poznámky ze schůzky a úkoly?",
        answer:
          "Živý přepis umí během nahrávání rozlišit mluvčí. Po zastavení souhrnný agent schůzku zpracuje a uloží poznámky, rozhodnutí a úkoly; nahrávání a zpracování jsou různé stavy.",
        links: [{ label: "Vidět den v souvislostech", href: "/cs-CZ/#day" }],
      },
      {
        question: "Je veřejné demo skutečný pracovní prostor?",
        answer:
          "Veřejné demo je samostatná, omezená verze s vymyšlenými daty a agenty podle scénáře. Jeho záznamy a běhy jsou ukázky, ne tvoje práce.",
        links: [{ label: "Prohlédnout živé demo", href: "/demo" }],
      },
    ],
  },
  pilot: {
    controls:
      "3D padákový kluzák. Tažením otáčej pohled a řiď let. Šipky vlevo a vpravo zatáčejí, šipky nahoru a dolů naklánějí příď vzhůru nebo dolů. R obnoví výchozí stav; mezerník pozastaví nebo obnoví let a vítr.",
  },
  install: {
    title: "Udělej si\npohodlí.",
    description:
      "Tvůj další vývojářský den může začít tady. Zdarma a s otevřeným zdrojovým kódem.",
    mac: "Apple Silicon · macOS 13+",
    windows: "x64 · Windows 10+",
    linux: "x86_64 · AppImage",
    release: "Zobrazit vydání",
    web: "Otevřít webovou aplikaci",
    phone: "Otevřít telefonního společníka",
    webNote: "Připoj se k serveru, který sám provozuješ.",
    phoneNote: "Spáruj telefon se serverem přes uzavřené relé.",
    selfHost: "Radši si ho budeš hostovat sám?",
    server: "Spustit server bez rozhraní",
    guide: "Přečíst stručného průvodce",
  },
  footer: {
    tagline: "Domov pro tvůj vývojářský den.",
    resources: "Zdroje",
    source: "Zdrojový kód na GitHubu",
    compare: "Porovnání",
    changelog: "Seznam změn",
    about: "O aplikaci",
    contact: "Kontakt",
    privacy: "Soukromí",
    terms: "Podmínky",
    licenses: "Licence",
    acknowledgements: "Poděkování",
    made: "Stavěno otevřeně.",
    top: "Zpět nahoru",
  },
};
