import type { LandingCopy } from "./landing-en";

export const ro: LandingCopy = {
  meta: {
    title: "Control Center \\\\ Un loc pentru ziua ta de dezvoltare",
    description:
      "Adună tichete, revizuiri de cod, agenți IA, întâlniri și pipeline-uri. Un spațiu de lucru gratuit și cu sursă deschisă pentru desktop, web și telefon.",
    imageAlt: "Control Center, munca ta de dezvoltare într-un singur spațiu.",
  },
  nav: {
    product: "Produs",
    workflows: "Fluxuri",
    features: "Funcții",
    docs: "Documentație",
    demo: "Încearcă demo-ul",
    download: "Descarcă",
    menu: "Meniu",
    primary: "Navigare principală",
    mobile: "Navigare mobilă",
    home: "Pagina Control Center",
    skip: "Sari la conținut",
    language: "Limbă",
    appearance: "Aspect",
    light: "Luminos",
    dark: "Întunecat",
    system: "Sistem",
  },
  hero: {
    line1: "Multe piese în mișcare.",
    line2: "Un singur Control Center.",
    description:
      "Un loc pentru cod, agenți, revizuiri și tot ce umple o zi de dezvoltare.",
    download: "Obține Control Center",
    demo: "Explorează demo-ul live",
    platforms: "macOS, Windows, Linux",
    web: "Și pe web, și pe telefon",
  },
  media: {
    phone:
      "Companionul de telefon arată același spațiu de lucru, o aprobare în așteptare și starea unei rulări de agent.",
  },
  tour: {
    label: "Explorează Control Center",
    previous: "Vizualizarea anterioară a produsului",
    next: "Vizualizarea următoare a produsului",
    play: "Redă turul",
    pause: "Întrerupe turul",
    videoPlay: "Redă previzualizarea",
    videoPause: "Întrerupe previzualizarea",
    expand: "Extinde previzualizarea",
    preview: "Previzualizare produs",
    close: "Închide previzualizarea",
    note: "O privire mai apropiată asupra zilei tale de dezvoltare.",
    imageLanguage: "Substituent pentru imagine sau video",
    stops: [
      {
        kind: "agents",
        label: "Agenți",
        title: "Lasă lucrul bun să aibă loc.",
        description:
          "Rulează agenți în worktree-uri Git izolate. Urmărește-le uneltele, condu munca și păstrează contextul.",
        alt: "O conversație cu un agent în Control Center, cu contextul sarcinii și activitatea.",
      },
      {
        kind: "desk",
        label: "Inbox",
        title: "Începe cu ce are nevoie de tine.",
        description:
          "Cereri de revizuire, aprobări și blocaje. Următoarea acțiune, fără să cauți prin file.",
        alt: "Inbox-ul Control Center grupează pull request-urile după starea revizuirii și arată un blocaj de sincronizare.",
      },
      {
        kind: "review",
        label: "Revizuire de cod",
        title: "Citește schimbarea. Înțelege povestea.",
        description:
          "Diff-urile, discuțiile și verificările rămân împreună. Publică revizuirea cu propriul cont.",
        alt: "Revizuirea unui pull request în Control Center, cu schimbările de cod și contextul revizuirii.",
      },
      {
        kind: "tickets",
        label: "Tichete",
        title: "Ține pasul următor legat.",
        description:
          "Urmărește prioritățile și responsabilitatea, sincronizează Linear și leagă conversația în care se lucrează.",
        alt: "Tabloul de tichete Control Center cu sarcinile grupate după stare.",
      },
      {
        kind: "meetings",
        label: "Întâlniri",
        title: "Păstrează deciziile după apel.",
        description:
          "Înregistrează și transcrie pe serverul tău. La finalul întâlnirii ai note și acțiuni.",
        alt: "O întâlnire în Control Center cu transcrierea și informațiile întâlnirii.",
      },
      {
        kind: "pipelines",
        label: "Pipeline-uri",
        title: "Fă repetabilă munca care se repetă.",
        description:
          "Construiește un flux, alege declanșatorul și urmărește fiecare pas al rulării.",
        alt: "Vizualizarea pipeline din Control Center cu pașii fluxului și starea rulării.",
      },
    ],
  },
  integrations: {
    title: "Adu uneltele cu care lucrezi deja.",
    note: "Conectate prin serverul tău, nu ca încă o copie a zilei.",
  },
  grid: {
    title: "Uneltele la care ajungi în fiecare zi.",
    description:
      "Fă munca, revizuiește ce s-a schimbat și păstrează deciziile.",
    more: "Citește documentația",
    items: [
      {
        title: "Agenți în paralel",
        description:
          "Dă fiecărei sarcini un worktree Git izolat. Urmărește rularea, condu agentul sau preia controlul fără să deranjezi restul.",
        link: "Rulează agenți în paralel",
        kind: "agents",
        href: "/manual/guides/parallel-agents/",
      },
      {
        title: "Revizuirea pull request-urilor",
        description:
          "Citește diff-urile lângă discuții și verificări. Adaugă o revizuire IA când ajută, apoi publică cu propriul cont de forge.",
        link: "Revizuiește un pull request",
        kind: "review",
        href: "/manual/guides/review-merge-pr/",
      },
      {
        title: "Tichete conectate",
        description:
          "Sincronizează Linear, stabilește priorități și atribuie munca. Leagă tichetul de conversația în care se face.",
        link: "Gestionează tichetele",
        kind: "tickets",
        href: "/manual/guides/manage-tickets/",
      },
      {
        title: "Note de întâlnire",
        description:
          "Înregistrează și transcrie pe serverul tău. Deciziile și acțiunile rămân după ce apelul se termină.",
        link: "Înregistrează o întâlnire",
        kind: "meetings",
        href: "/manual/guides/record-meeting/",
      },
      {
        title: "Pipeline-uri repetabile",
        description:
          "Construiește un flux o dată. Rulează-l după un program, dintr-un eveniment sau manual și inspectează fiecare pas.",
        link: "Construiește un pipeline",
        kind: "pipelines",
        href: "/manual/guides/create-pipeline/",
      },
      {
        title: "Schimbarea conturilor",
        description:
          "Alege conturile pe care le poate folosi fiecare agent și treci de la unul la altul fără să pierzi contextul rulării.",
        link: "Gestionează furnizorii de modele",
        kind: "accounts",
        href: "/manual/guides/adapters/",
        alt: "Editorul grupurilor de conturi din Control Center, cu conturile disponibile pentru un agent.",
      },
      {
        title: "Cotă de utilizare",
        description:
          "Verifică limita oferită de furnizor și momentele de resetare înainte de următoarea rulare.",
        link: "Gestionează costurile",
        kind: "quota",
        href: "/manual/guides/manage-costs/",
        alt: "Panoul de utilizare din Control Center cu cotele furnizorilor și momentele de resetare.",
      },
      {
        title: "Ambianțe sonore și concentrare",
        description:
          "Pornește o sesiune de concentrare cronometrată, oprește notificările și adaptează ambianța sonoră care o însoțește.",
        link: "Folosește modul de concentrare",
        kind: "focus",
        href: "/manual/guides/focus-mode/",
        alt: "Cronometrul de concentrare și comenzile pentru ambianțe sonore din Control Center.",
      },
      {
        title: "Observabilitate",
        description:
          "Urmărește agenții activi și examinează costurile rulărilor, consumul de tokenuri și latența în spațiul tău de lucru.",
        link: "Examinează rulările agenților",
        kind: "observability",
        href: "/manual/guides/manage-costs/",
        alt: "Vizualizarea de observabilitate din Control Center cu agenți activi și analiza rulărilor.",
      },
      {
        title: "Editoare de abilități și agenți",
        description:
          "Editează abilitățile spațiului de lucru și configurează modelul, instrucțiunile și permisiunile fiecărui agent.",
        link: "Gestionează abilitățile",
        kind: "editors",
        href: "/manual/guides/manage-skills/",
        alt: "Editorul de abilități și setările agenților din Control Center.",
      },
    ],
    supporting: [
      {
        title: "Un singur inbox",
        description:
          "Revizuiri, aprobări și blocaje într-o singură coadă. Treci la sarcina următoare cu paleta de comenzi.",
        href: "/manual/guides/triage-inbox/",
      },
      {
        title: "Verifică de pe telefon",
        description:
          "Urmărește rulările și ocupă-te de aprobări fără să te întorci la birou.",
        href: "/manual/concepts/remote-control/",
      },
    ],
  },
  workflow: {
    title: "Ține firul.\nPână la publicare.",
    description:
      "Munca trece dintr-o unealtă în alta. Contextul ar trebui să vină cu ea.",
    label: "Un flux conectat",
    steps: [
      {
        title: "Începe cu tichetul.",
        text: "Stabilește prioritatea, numește responsabilul și leagă conversația. Tichetul ține evidența.",
        kind: "tickets",
        label: "Intenția",
      },
      {
        title: "Dă-i muncii un spațiu al ei.",
        text: "Discută un plan, pregătește un worktree izolat și rulează agentul. Condu sau preia când ai nevoie.",
        kind: "agents",
        label: "Munca",
      },
      {
        title: "Adu rezultatul în revizuire.",
        text: "Citește schimbările, urmărește discuția și publică cu contul tău de forge. Povestea rămâne legată.",
        kind: "review",
        label: "Rezultatul",
      },
    ],
  },
  boundaries: {
    title: "Aprobă un push înainte să ruleze.",
    description:
      "Pune push-urile Git, publicarea pull request-urilor și alte acțiuni păzite în spatele unei aprobări. Verifică ce urmează să facă agentul înainte să schimbe ceva.",
    media:
      "O rulare de agent oprită la o cerere de aprobare pentru un push Git. Arată comanda propusă, directorul de lucru și comenzile de aprobare sau refuz.",
    note: "Nimeni conectat să aprobe? Acțiunea este refuzată. Permisiunile sunt impuse de serverul tău, nu de un prompt.",
    link: "Configurează aprobările de acțiuni",
  },
  surfaces: {
    title: "Biroul este un loc.\nMunca nu.",
    description:
      "Începe pe desktop. Intră din browser. Rămâi aproape de pe telefon. Un server ține operațiunea laolaltă.",
    desktop: "Desktop nativ",
    web: "În browser",
    phone: "Companion de telefon",
    note: "Serverul tău deține datele și execuția. Dispozitivele rămân sincronizate.",
    link: "Găsește-ți platforma",
  },
  faq: {
    title: "Întrebări bune.",
    description: "Câteva lucruri de știut înainte să te instalezi.",
    items: [
      {
        question: "Control Center este doar pentru agenți IA?",
        answer:
          "Nu. Control Center pune tichete, pull request-uri, conversații, întâlniri, calendar, pipeline-uri, agenți și un cititor RSS personal într-un singur spațiu de lucru. Agenții sunt o parte a biroului, nu o condiție ca să folosești restul.",
        links: [{ label: "Explorează funcțiile", href: "/ro-RO/#features" }],
      },
      {
        question: "Care este diferența dintre un tichet și o conversație?",
        answer:
          "Un tichet înregistrează munca și starea ei; execuția se întâmplă într-o conversație. Conversația poate pregăti un worktree izolat copy-on-write înainte de o rulare de agent. Pe Windows, pregătirea folosește un worktree Git.",
        links: [
          { label: "Urmărește un flux exemplu", href: "/ro-RO/#workflows" },
        ],
      },
      {
        question: "Unde rulează agenții și ce face serverul?",
        answer:
          "Serverul deține baza de date a spațiului de lucru, acreditările, API-urile și execuția agenților; clienții de desktop și de browser afișează și controlează munca. Workerii opționali ai flotei preiau sarcini închiriate și transmit evenimente, dar nu țin baza de date, acreditările sau bugetele.",
        links: [
          {
            label: "Citește ghidul de arhitectură",
            href: "/manual/concepts/architecture/",
          },
        ],
      },
      {
        question: "Cât control am asupra unei rulări de agent?",
        answer:
          "Fiecare conversație poate folosi Doar propune, Acționează cu aprobare sau Acționează liber. Permisiunile și un sandbox limitează în continuare acțiunile permise; cererile de aprobare fără cineva care să aprobe sunt refuzate. Limitele moi de buget avertizează, cele dure pun pauză, iar rulările păstrează un jurnal.",
        links: [{ label: "Vezi comenzile", href: "/ro-RO/#boundaries" }],
      },
      {
        question: "Un plan Orchestrate angajează agenți automat?",
        answer:
          "Nu. Orchestrate poate cerceta și propune roluri, tichete copil și un plan, dar angajarea așteaptă o aprobare. Plan Studio se deschide din rândul planului în conversația de origine; atribuirea unui tichet nu pornește singură o rulare.",
        links: [
          { label: "Urmărește fluxul exemplu", href: "/ro-RO/#workflows" },
        ],
      },
      {
        question: "Pot rula agenți de pe telefonul asociat?",
        answer:
          "Telefonul asociat este un client subțire pentru același spațiu de pe server, nu o a doua gazdă de execuție. Desktopul, browserul și telefonul arată aceeași operațiune; agenții rulează pe server sau pe workeri opționali ai flotei, în chirie.",
        links: [
          { label: "Vezi suprafețele conectate", href: "/ro-RO/#surfaces" },
        ],
      },
      {
        question: "Ce integrări pot folosi?",
        answer:
          "Sincronizarea tichetelor cu Linear este implementată; Jira și ClickUp nu au adaptoare. Evenimentele Google Calendar conectate sunt doar în citire, iar răspunsul la invitații există doar când calendarul acordă drept de scriere. Firele Slack se pot lega de conversații, iar forge-urile conectate furnizează pull request-uri și verificări.",
        links: [{ label: "Citește manualul", href: "/manual/" }],
      },
      {
        question: "Când apar notele și acțiunile întâlnirii?",
        answer:
          "Transcrierea live poate separa vorbitorii în timpul înregistrării. După ce oprești, agentul de rezumat procesează întâlnirea și salvează notele, deciziile și acțiunile; înregistrarea și procesarea sunt stări distincte.",
        links: [{ label: "Vezi ziua în context", href: "/ro-RO/#day" }],
      },
      {
        question: "Demo-ul public este un spațiu de lucru real?",
        answer:
          "Demo-ul public este o versiune separată și restrânsă, cu date inventate și agenți care urmează un scenariu. Înregistrările și rulările sunt exemple, nu munca ta.",
        links: [{ label: "Explorează demo-ul live", href: "/demo" }],
      },
    ],
  },
  pilot: {
    controls:
      "Parapantă 3D. Trage ca să rotești perspectiva și să dirijezi zborul. Săgețile stânga și dreapta virează; cele sus și jos înclină zborul în sus sau în jos. R resetează; Spațiu întrerupe sau reia zborul și vântul.",
  },
  install: {
    title: "Simte-te\nacasă.",
    description:
      "Următoarea zi de dezvoltare poate începe aici. Gratuit și cu sursă deschisă.",
    mac: "Apple Silicon · macOS 13+",
    windows: "x64 · Windows 10+",
    linux: "x86_64 · AppImage",
    release: "Vezi versiunile",
    web: "Deschide aplicația web",
    phone: "Deschide companionul de telefon",
    webNote: "Conectează-te la un server pe care îl rulezi tu.",
    phoneNote: "Asociază telefonul cu serverul printr-un releu închis.",
    selfHost: "Preferi să-l găzduiești tu?",
    server: "Rulează un server fără interfață",
    guide: "Citește ghidul de pornire rapidă",
  },
  footer: {
    tagline: "Un loc pentru ziua ta de dezvoltare.",
    resources: "Resurse",
    source: "Sursa pe GitHub",
    compare: "Compară",
    changelog: "Jurnal de modificări",
    about: "Despre",
    contact: "Contact",
    privacy: "Confidențialitate",
    terms: "Termeni",
    licenses: "Licențe",
    acknowledgements: "Mulțumiri",
    made: "Construit la vedere.",
    top: "Înapoi sus",
  },
};
