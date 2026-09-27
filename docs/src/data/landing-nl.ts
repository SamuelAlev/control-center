import type { LandingCopy } from "./landing-en";

export const nl: LandingCopy = {
  meta: {
    title: "Control Center \\\\ Een plek voor je ontwikkelaarsdag",
    description:
      "Breng tickets, code-reviews, AI-agents, vergaderingen en pipelines samen. Een gratis, open-source werkruimte voor desktop, web en telefoon.",
    imageAlt: "Control Center, je ontwikkelaarswerk in één werkruimte.",
  },
  nav: {
    product: "Product",
    workflows: "Werkstromen",
    features: "Functies",
    docs: "Documentatie",
    demo: "Demo proberen",
    download: "Downloaden",
    menu: "Menu",
    primary: "Hoofdnavigatie",
    mobile: "Mobiele navigatie",
    home: "Control Center-startpagina",
    skip: "Naar de inhoud",
    language: "Taal",
    appearance: "Weergave",
    light: "Licht",
    dark: "Donker",
    system: "Systeem",
  },
  hero: {
    line1: "Veel onderdelen in beweging.",
    line2: "Eén Control Center.",
    description:
      "Een plek voor je code, agents, reviews en al het andere dat een ontwikkelaarsdag vult.",
    download: "Control Center downloaden",
    demo: "De live demo verkennen",
    platforms: "macOS, Windows, Linux",
    web: "Ook op web en telefoon",
  },
  media: {
    phone:
      "Telefoonpartner met dezelfde werkruimte, een openstaande goedkeuring en de status van een agentuitvoering.",
  },
  tour: {
    label: "Control Center verkennen",
    previous: "Vorige productweergave",
    next: "Volgende productweergave",
    play: "Rondleiding afspelen",
    pause: "Rondleiding pauzeren",
    expand: "Voorbeeld vergroten",
    close: "Voorbeeld sluiten",
    preview: "Productvoorbeeld",
    note: "Een nadere blik op je ontwikkelaarsdag.",
    imageLanguage: "Plaatshouder voor beeld of video",
    stops: [
      {
        kind: "desk",
        label: "Je dag",
        title: "Begin bij wat jou nodig heeft.",
        description:
          "Reviewverzoeken, goedkeuringen en blokkades. De volgende actie, zonder te zoeken tussen tabbladen.",
        alt: "Postvak in van Control Center dat pull requests groepeert op reviewstatus en een synchronisatieblokkade toont.",
      },
      {
        kind: "agents",
        label: "Agenten",
        title: "Geef goed werk de ruimte.",
        description:
          "Draai agents in geïsoleerde Git-worktrees. Volg hun tools, stuur het werk en bewaar de context.",
        alt: "Een agentgesprek in Control Center met de taakcontext en de activiteit.",
      },
      {
        kind: "review",
        label: "Code-review",
        title: "Lees de wijziging. Ken het verhaal.",
        description:
          "Diffs, discussies en checks blijven bij elkaar. Publiceer de review met je eigen account.",
        alt: "Pull-requestreview in Control Center met codewijzigingen en reviewcontext.",
      },
      {
        kind: "tickets",
        label: "Tickets",
        title: "Houd de volgende stap verbonden.",
        description:
          "Volg prioriteiten en eigenaarschap, synchroniseer Linear en koppel het gesprek waarin het werk gebeurt.",
        alt: "Ticketbord van Control Center met taken gegroepeerd op status.",
      },
      {
        kind: "meetings",
        label: "Vergaderingen",
        title: "Bewaar de besluiten na het gesprek.",
        description:
          "Neem op en transcribeer op je server. Na de vergadering heb je notities en actiepunten.",
        alt: "Een vergadering in Control Center met transcript en vergaderinformatie.",
      },
      {
        kind: "pipelines",
        label: "Pipelines",
        title: "Maak herhalend werk herhaalbaar.",
        description:
          "Bouw een werkstroom, kies de trigger en volg elke stap van de run.",
        alt: "Pipelineweergave van Control Center met werkstroomstappen en uitvoeringsstatus.",
      },
    ],
  },
  integrations: {
    title: "Neem de tools mee waarmee je al werkt.",
    note: "Verbonden via je server, niet als een tweede kopie van je dag.",
  },
  grid: {
    title: "De tools die je elke dag pakt.",
    description: "Doe het werk, review wat veranderde en bewaar de besluiten.",
    more: "Documentatie lezen",
    items: [
      {
        title: "Parallelle agents",
        description:
          "Geef elke taak een geïsoleerde Git-worktree. Volg de run, stuur een agent of neem over zonder de rest te storen.",
        link: "Agents parallel draaien",
        kind: "agents",
        href: "/manual/guides/parallel-agents/",
      },
      {
        title: "Pull-requestreview",
        description:
          "Lees diffs met discussies en checks ernaast. Voeg een AI-review toe wanneer dat helpt en publiceer daarna met je eigen forge-account.",
        link: "Een pull request reviewen",
        kind: "review",
        href: "/manual/guides/review-merge-pr/",
      },
      {
        title: "Verbonden tickets",
        description:
          "Synchroniseer Linear, stel prioriteiten in en wijs het werk toe. Koppel het ticket aan het gesprek waarin het wordt gedaan.",
        link: "Tickets beheren",
        kind: "tickets",
        href: "/manual/guides/manage-tickets/",
      },
      {
        title: "Vergadernotities",
        description:
          "Neem op en transcribeer op je server. Besluiten en actiepunten blijven nadat het gesprek stopt.",
        link: "Een vergadering opnemen",
        kind: "meetings",
        href: "/manual/guides/record-meeting/",
      },
      {
        title: "Herhaalbare pipelines",
        description:
          "Bouw een werkstroom één keer. Draai hem op een schema, vanuit een gebeurtenis of met de hand, en bekijk elke stap.",
        link: "Een pipeline bouwen",
        kind: "pipelines",
        href: "/manual/guides/create-pipeline/",
      },
      {
        title: "Wisselen tussen accounts",
        description:
          "Kies welke accounts elke agent mag gebruiken en wissel ertussen zonder de context van de run te verliezen.",
        link: "Modelaanbieders beheren",
        kind: "accounts",
        href: "/manual/guides/adapters/",
        alt: "Editor voor accountgroepen in Control Center met de beschikbare accounts voor een agent.",
      },
      {
        title: "Gebruikslimiet",
        description:
          "Bekijk de limieten van aanbieders en wanneer ze worden vernieuwd voordat je de volgende run start.",
        link: "Kosten beheren",
        kind: "quota",
        href: "/manual/guides/manage-costs/",
        alt: "Gebruiksoverzicht van Control Center met limieten van aanbieders en tijdstippen waarop ze worden vernieuwd.",
      },
      {
        title: "Geluidslandschappen en focus",
        description:
          "Start een focussessie met timer, demp meldingen en pas het geluidslandschap op de achtergrond aan.",
        link: "Focusmodus gebruiken",
        kind: "focus",
        href: "/manual/guides/focus-mode/",
        alt: "Focustimer en bediening voor geluidslandschappen in Control Center.",
      },
      {
        title: "Inzicht in runs",
        description:
          "Volg actieve agents en bekijk de kosten, het tokengebruik en de latentie van hun runs in je werkruimte.",
        link: "Agentruns bekijken",
        kind: "observability",
        href: "/manual/guides/manage-costs/",
        alt: "Overzicht in Control Center met actieve agents en inzichten in hun runs.",
      },
      {
        title: "Editors voor skills en agents",
        description:
          "Bewerk skills in de werkruimte en stel het model, de instructies en de rechten van elke agent in.",
        link: "Skills beheren",
        kind: "editors",
        href: "/manual/guides/manage-skills/",
        alt: "Skilleditor en agentinstellingen in Control Center.",
      },
    ],
    supporting: [
      {
        title: "Eén postvak in",
        description:
          "Reviews, goedkeuringen en blokkades in één wachtrij. Spring naar de volgende taak met het opdrachtpalet.",
        href: "/manual/guides/triage-inbox/",
      },
      {
        title: "Kijk mee vanaf je telefoon",
        description:
          "Volg je runs en handel goedkeuringen af zonder terug te gaan naar je bureau.",
        href: "/manual/concepts/remote-control/",
      },
    ],
  },
  workflow: {
    title: "Houd de draad vast.\nTot het gepubliceerd is.",
    description: "Werk beweegt tussen tools. De context hoort mee te gaan.",
    label: "Een verbonden werkstroom",
    steps: [
      {
        title: "Begin bij het ticket.",
        text: "Stel de prioriteit in, noem de eigenaar en koppel het gesprek. Het ticket bewaart het verslag.",
        kind: "tickets",
        label: "De bedoeling",
      },
      {
        title: "Geef het werk een eigen plek.",
        text: "Bespreek een plan, bereid een geïsoleerde worktree voor en draai de agent. Stuur of neem over wanneer het nodig is.",
        kind: "agents",
        label: "Het werk",
      },
      {
        title: "Breng het resultaat naar review.",
        text: "Lees de wijzigingen, volg de discussie en publiceer met je forge-account. Het verhaal blijft verbonden.",
        kind: "review",
        label: "Het resultaat",
      },
    ],
  },
  boundaries: {
    title: "Keur een push goed voordat hij draait.",
    description:
      "Zet Git-pushes, het publiceren van pull requests en andere bewaakte acties achter een goedkeuring. Bekijk wat de agent gaat doen voordat er iets verandert.",
    media:
      "Een agentrun die pauzeert bij een goedkeuringsverzoek voor een Git-push. Toon het voorgestelde commando, de werkmap en de knoppen om goed te keuren of te weigeren.",
    note: "Geen goedkeurder verbonden? De actie wordt geweigerd. Rechten worden afgedwongen door je server, niet door een prompt.",
    link: "Actiegoedkeuringen instellen",
  },
  surfaces: {
    title: "Je bureau is een plek.\nJe werk niet.",
    description:
      "Begin op de desktop. Kijk in de browser. Blijf dichtbij vanaf je telefoon. Eén server houdt de operatie bij elkaar.",
    desktop: "Native desktop",
    web: "In je browser",
    phone: "Telefoonpartner",
    note: "Je server bezit de data en de uitvoering. Je apparaten blijven synchroon.",
    link: "Vind je platform",
  },
  faq: {
    title: "Goede vragen.",
    description: "Een paar dingen om te weten voordat je je nestelt.",
    items: [
      {
        question: "Is Control Center alleen voor AI-agents?",
        answer:
          "Nee. Control Center brengt tickets, pull requests, gesprekken, vergaderingen, agenda, pipelines, agents en een persoonlijke RSS-lezer samen in één werkruimte. Agents zijn een deel van het bureau, geen voorwaarde om de rest te gebruiken.",
        links: [{ label: "De functies verkennen", href: "/nl-NL/#features" }],
      },
      {
        question: "Wat is het verschil tussen een ticket en een gesprek?",
        answer:
          "Een ticket legt het werk en de status vast; de uitvoering gebeurt in een gesprek. Het gesprek kan vóór een agentrun een geïsoleerde copy-on-write-worktree klaarzetten. Op Windows gebruikt die voorbereiding een Git-worktree.",
        links: [
          {
            label: "Een voorbeeldwerkstroom volgen",
            href: "/nl-NL/#workflows",
          },
        ],
      },
      {
        question: "Waar draaien agents en wat doet de server?",
        answer:
          "De server bezit de database van de werkruimte, de referenties, de API’s en de uitvoering van agents; desktop- en browserclients tonen en besturen dat werk. Optionele fleet-workers halen geleasede taken op en streamen gebeurtenissen, maar bewaren geen database, referenties of budgetten.",
        links: [
          {
            label: "De architectuurgids lezen",
            href: "/manual/concepts/architecture/",
          },
        ],
      },
      {
        question: "Hoeveel controle heb ik over een agentrun?",
        answer:
          "Elk gesprek kan Alleen voorstellen, Handelen met goedkeuring of Vrij handelen gebruiken. Rechten en een sandbox blijven toegestane acties begrenzen; goedkeuringsverzoeken zonder goedkeurder worden geweigerd. Zachte budgetgrenzen waarschuwen, harde pauzeren, en runs houden een log bij.",
        links: [{ label: "De bediening bekijken", href: "/nl-NL/#boundaries" }],
      },
      {
        question: "Neemt een Orchestrate-plan automatisch agents aan?",
        answer:
          "Nee. Orchestrate kan rollen, kindtickets en een plan uitzoeken en voorstellen, maar aannemen wacht op goedkeuring. Plan Studio opent vanuit de planregel in het oorspronkelijke gesprek; een ticket toewijzen start op zichzelf geen run.",
        links: [
          { label: "De voorbeeldwerkstroom volgen", href: "/nl-NL/#workflows" },
        ],
      },
      {
        question: "Kan ik agents draaien vanaf de gekoppelde telefoon?",
        answer:
          "De gekoppelde telefoon is een lichte client voor dezelfde werkruimte op de server, geen tweede uitvoeringshost. Desktop, browser en telefoon tonen dezelfde operatie; agents draaien op de server of op optionele geleasede fleet-workers.",
        links: [
          { label: "De verbonden oppervlakken zien", href: "/nl-NL/#surfaces" },
        ],
      },
      {
        question: "Welke integraties kan ik gebruiken?",
        answer:
          "Ticketsynchronisatie met Linear is geïmplementeerd; Jira en ClickUp hebben geen adapters. Verbonden Google Calendar-afspraken zijn alleen-lezen, en RSVP is er alleen als de agenda schrijfrechten geeft. Slack-threads kunnen aan gesprekken worden gekoppeld, en verbonden forges leveren pull requests en checks.",
        links: [{ label: "De handleiding lezen", href: "/manual/" }],
      },
      {
        question: "Wanneer verschijnen vergadernotities en actiepunten?",
        answer:
          "Het livetranscript kan sprekers scheiden tijdens de opname. Nadat je stopt, verwerkt de samenvattingsagent de vergadering en bewaart notities, besluiten en actiepunten; opnemen en verwerken zijn verschillende staten.",
        links: [{ label: "De dag in context zien", href: "/nl-NL/#day" }],
      },
      {
        question: "Is de openbare demo een echte werkruimte?",
        answer:
          "De openbare demo is een aparte, afgeschermde build met verzonnen data en agents die een script volgen. De records en runs zijn voorbeelden, niet je eigen werk.",
        links: [{ label: "De live demo verkennen", href: "/demo" }],
      },
    ],
  },
  pilot: {
    controls:
      "3D-paraglider. Sleep om het beeld te draaien en te sturen. Pijl links en rechts sturen; pijl omhoog en omlaag kantelen de vlucht omhoog of omlaag. R zet terug; spatie pauzeert of hervat de vlucht en de wind.",
  },
  install: {
    title: "Maak het je\ngemakkelijk.",
    description:
      "Je volgende ontwikkelaarsdag kan hier beginnen. Gratis en open source.",
    mac: "Apple Silicon · macOS 13+",
    windows: "x64 · Windows 10+",
    linux: "x86_64 · AppImage",
    release: "Releases bekijken",
    web: "De webapp openen",
    phone: "De telefoonpartner openen",
    webNote: "Verbind met een server die jij draait.",
    phoneNote: "Koppel je telefoon aan je server via een afgeschermde relay.",
    selfHost: "Host je het liever zelf?",
    server: "Een headless server draaien",
    guide: "De snelstartgids lezen",
  },
  footer: {
    tagline: "Een plek voor je ontwikkelaarsdag.",
    resources: "Bronnen",
    source: "Bron op GitHub",
    compare: "Vergelijken",
    changelog: "Wijzigingslog",
    about: "Over",
    contact: "Contact",
    privacy: "Privacy",
    terms: "Voorwaarden",
    licenses: "Licenties",
    acknowledgements: "Dankbetuigingen",
    made: "In het openbaar gebouwd.",
    top: "Terug naar boven",
  },
};
