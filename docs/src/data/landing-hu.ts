import type { LandingCopy } from "./landing-en";

export const hu: LandingCopy = {
  meta: {
    title: "Control Center \\\\ Otthon a fejlesztői napodnak",
    description:
      "Hozd össze a jegyeket, a kódellenőrzést, az MI-ügynököket, a megbeszéléseket és a pipeline-okat. Ingyenes, nyílt forráskódú munkatér asztalra, webre és telefonra.",
    imageAlt: "Control Center, a fejlesztői munkád egy munkatérben.",
  },
  nav: {
    product: "Termék",
    workflows: "Folyamatok",
    features: "Funkciók",
    docs: "Dokumentáció",
    demo: "Demó kipróbálása",
    download: "Letöltés",
    menu: "Menü",
    primary: "Fő navigáció",
    mobile: "Mobilnavigáció",
    home: "Control Center kezdőlap",
    skip: "Ugrás a tartalomra",
    language: "Nyelv",
    appearance: "Megjelenés",
    light: "Világos",
    dark: "Sötét",
    system: "Rendszer",
  },
  hero: {
    line1: "Sok mozgó rész.",
    line2: "Egy Control Center.",
    description:
      "Otthon a kódodnak, az ügynökeidnek, az ellenőrzéseknek és minden másnak, ami egy fejlesztői napot kitölt.",
    download: "Control Center beszerzése",
    demo: "Az élő demó felfedezése",
    platforms: "macOS, Windows, Linux",
    web: "Weben és telefonon is",
  },
  media: {
    phone:
      "A telefonos társ ugyanazt a munkateret, egy függőben lévő jóváhagyást és egy ügynökfutás állapotát mutatja.",
  },
  tour: {
    label: "A Control Center felfedezése",
    previous: "Előző terméknézet",
    next: "Következő terméknézet",
    play: "Bemutató lejátszása",
    pause: "Bemutató szüneteltetése",
    videoPlay: "Előnézet lejátszása",
    videoPause: "Előnézet szüneteltetése",
    expand: "Előnézet nagyítása",
    preview: "Termékelőnézet",
    close: "Előnézet bezárása",
    note: "Közelebbi pillantás a fejlesztői napodra.",
    imageLanguage: "Kép vagy videó helye",
    stops: [
      {
        kind: "agents",
        label: "Ügynökök",
        title: "Adj teret a jó munkának.",
        description:
          "Futtasd az ügynököket elkülönített Git-worktree-kben. Kövesd az eszközeiket, irányítsd a munkát, és tartsd meg a kontextust.",
        alt: "Ügynökbeszélgetés a Control Centerben a feladat kontextusával és a tevékenységgel.",
      },
      {
        kind: "desk",
        label: "Beérkezett",
        title: "Kezdd azzal, aminek rád van szüksége.",
        description:
          "Ellenőrzési kérések, jóváhagyások és akadályok. A következő lépés, lapok közötti keresgélés nélkül.",
        alt: "A Control Center beérkezettjei a pull requesteket ellenőrzési állapot szerint csoportosítják, és szinkronizálási akadályt mutatnak.",
      },
      {
        kind: "review",
        label: "Kódellenőrzés",
        title: "Olvasd el a változást. Ismerd a történetet.",
        description:
          "A diffek, a beszélgetések és az ellenőrzések együtt maradnak. A saját fiókoddal tedd közzé az ellenőrzést.",
        alt: "Pull request ellenőrzése a Control Centerben, kódváltozásokkal és az ellenőrzés kontextusával.",
      },
      {
        kind: "tickets",
        label: "Jegyek",
        title: "A következő lépés maradjon kapcsolva.",
        description:
          "Kövesd a prioritást és a felelőst, szinkronizáld a Lineart, és kösd össze a beszélgetéssel, ahol a munka készül.",
        alt: "A Control Center jegytáblája állapot szerint csoportosított feladatokkal.",
      },
      {
        kind: "meetings",
        label: "Megbeszélések",
        title: "A döntések maradjanak a hívás után is.",
        description:
          "Vedd fel és írd le a saját szervereden. A megbeszélés végén jegyzetek és teendők várnak.",
        alt: "Megbeszélés a Control Centerben átirattal és a megbeszélés adataival.",
      },
      {
        kind: "pipelines",
        label: "Pipeline-ok",
        title: "Amit ismételni kell, legyen ismételhető.",
        description:
          "Építs egy folyamatot, válaszd ki az indítóját, és kövesd a futás minden lépését.",
        alt: "Pipeline-nézet a Control Centerben a folyamat lépéseivel és a futás állapotával.",
      },
    ],
  },
  integrations: {
    title: "Hozd az eszközöket, amelyekkel már dolgozol.",
    note: "A saját szervereden keresztül, nem a napod újabb másolataként.",
  },
  grid: {
    title: "Az eszközök, amelyekért minden nap nyúlsz.",
    description:
      "Végezd a munkát, nézd át, mi változott, és tartsd meg a döntéseket.",
    more: "A dokumentáció olvasása",
    items: [
      {
        title: "Párhuzamos ügynökök",
        description:
          "Adj minden feladatnak egy elkülönített Git-worktree-t. Kövesd a futást, irányíts egy ügynököt, vagy vedd át a munkát a többi zavarása nélkül.",
        link: "Ügynökök párhuzamos futtatása",
        kind: "agents",
        href: "/manual/guides/parallel-agents/",
      },
      {
        title: "Pull request ellenőrzése",
        description:
          "Olvasd a diffeket a beszélgetések és az ellenőrzések mellett. Tegyél hozzá MI-ellenőrzést, ha segít, majd a saját forge-fiókoddal tedd közzé.",
        link: "Pull request ellenőrzése",
        kind: "review",
        href: "/manual/guides/review-merge-pr/",
      },
      {
        title: "Kapcsolt jegyek",
        description:
          "Szinkronizáld a Lineart, állíts prioritást, és oszd ki a munkát. Kösd a jegyet ahhoz a beszélgetéshez, ahol elkészül.",
        link: "Jegyek kezelése",
        kind: "tickets",
        href: "/manual/guides/manage-tickets/",
      },
      {
        title: "Megbeszélésjegyzetek",
        description:
          "Vedd fel és írd le a saját szervereden. A döntések és a teendők a hívás után is megmaradnak.",
        link: "Megbeszélés felvétele",
        kind: "meetings",
        href: "/manual/guides/record-meeting/",
      },
      {
        title: "Ismételhető pipeline-ok",
        description:
          "Építs egy folyamatot egyszer. Futtasd ütemezve, eseményből vagy kézzel, és nézd meg minden lépését.",
        link: "Pipeline építése",
        kind: "pipelines",
        href: "/manual/guides/create-pipeline/",
      },
      {
        title: "Fiókváltás",
        description:
          "Válaszd ki, mely fiókokat használhatja az egyes ügynök, és válts köztük a futás kontextusának elvesztése nélkül.",
        link: "Modellszolgáltatók kezelése",
        kind: "accounts",
        href: "/manual/guides/adapters/",
        alt: "Fiókcsoport-szerkesztő a Control Centerben az ügynök számára elérhető fiókokkal.",
      },
      {
        title: "Felhasználási keret",
        description:
          "A következő futás előtt nézd meg a szolgáltatói kereteket és a megújulásuk időpontját.",
        link: "Költségek kezelése",
        kind: "quota",
        href: "/manual/guides/manage-costs/",
        alt: "A Control Center felhasználási panelje a szolgáltatói keretekkel és azok megújulási időpontjával.",
      },
      {
        title: "Hangkulisszák és fókusz",
        description:
          "Indíts időzített fókuszidőt, némítsd el az értesítéseket, és alakítsd a közben szóló hangkulisszát.",
        link: "Fókuszmód használata",
        kind: "focus",
        href: "/manual/guides/focus-mode/",
        alt: "Fókuszidőzítő és hangkulissza-vezérlők a Control Centerben.",
      },
      {
        title: "Futások áttekintése",
        description:
          "Kövesd az aktív ügynököket, és nézd meg a futások költségét, tokenhasználatát és késleltetését a munkaterületeden.",
        link: "Ügynökfutások vizsgálata",
        kind: "observability",
        href: "/manual/guides/manage-costs/",
        alt: "A Control Center futásáttekintő nézete aktív ügynökökkel és a futások adataival.",
      },
      {
        title: "Képesség- és ügynökszerkesztők",
        description:
          "Szerkeszd a munkaterület képességeit, és állítsd be minden ügynök modelljét, utasításait és jogosultságait.",
        link: "Képességek kezelése",
        kind: "editors",
        href: "/manual/guides/manage-skills/",
        alt: "Képességszerkesztő és ügynökbeállítások a Control Centerben.",
      },
    ],
    supporting: [
      {
        title: "Egy beérkezett",
        description:
          "Ellenőrzések, jóváhagyások és akadályok egy sorban. A parancspalettával ugorj a következő feladatra.",
        href: "/manual/guides/triage-inbox/",
      },
      {
        title: "Nézz rá a telefonodról",
        description:
          "Kövesd a futásokat, és intézd a jóváhagyásokat anélkül, hogy visszamennél az asztalhoz.",
        href: "/manual/concepts/remote-control/",
      },
    ],
  },
  workflow: {
    title: "Tartsd a fonalat.\nEgészen a kiadásig.",
    description:
      "A munka eszközről eszközre vándorol. A kontextusnak vele kell mennie.",
    label: "Összekapcsolt folyamat",
    steps: [
      {
        title: "Kezdd a jeggyel.",
        text: "Állítsd be a prioritást, nevezd meg a felelőst, és kösd össze a beszélgetést. A jegy őrzi a feljegyzést.",
        kind: "tickets",
        label: "A szándék",
      },
      {
        title: "Adj a munkának saját teret.",
        text: "Beszéld meg a tervet, készíts elkülönített worktree-t, és futtasd az ügynököt. Irányíts, vagy vedd át, amikor kell.",
        kind: "agents",
        label: "A munka",
      },
      {
        title: "Vidd az eredményt ellenőrzésre.",
        text: "Olvasd el a változásokat, kövesd a beszélgetést, és a forge-fiókoddal tedd közzé. A történet kapcsolva marad.",
        kind: "review",
        label: "Az eredmény",
      },
    ],
  },
  boundaries: {
    title: "Hagyj jóvá egy pusht, mielőtt lefut.",
    description:
      "Tedd a Git-pusheket, a pull requestek közzétételét és a többi őrzött műveletet jóváhagyás mögé. Nézd meg, mit készül tenni az ügynök, mielőtt bármi megváltozna.",
    media:
      "Egy ügynökfutás, amely egy Git-push jóváhagyási kérésénél áll. Mutasd a javasolt parancsot, a munkakönyvtárat és a jóváhagyás vagy elutasítás vezérlőit.",
    note: "Nincs csatlakozva jóváhagyó? A művelet elutasítva. Az engedélyeket a szervered kényszeríti ki, nem egy prompt.",
    link: "Műveleti jóváhagyások beállítása",
  },
  surfaces: {
    title: "Az asztal egy hely.\nA munka nem.",
    description:
      "Kezdd az asztalon. Nézz be a böngészőből. Maradj közel a telefonodról. Egy szerver tartja együtt a működést.",
    desktop: "Natív asztal",
    web: "A böngészőben",
    phone: "Telefonos társ",
    note: "A szervered birtokolja az adatokat és a végrehajtást. Az eszközeid szinkronban maradnak.",
    link: "A platformod megkeresése",
  },
  faq: {
    title: "Jó kérdések.",
    description: "Néhány dolog, mielőtt berendezkedsz.",
    items: [
      {
        question: "A Control Center csak MI-ügynököknek való?",
        answer:
          "Nem. A Control Center jegyeket, pull requesteket, beszélgetéseket, megbeszéléseket, naptárat, pipeline-okat, ügynököket és egy személyes RSS-olvasót tesz egy munkatérbe. Az ügynökök az asztal egy része, nem feltétele a többinek.",
        links: [{ label: "A funkciók felfedezése", href: "/hu-HU/#features" }],
      },
      {
        question: "Mi a különbség egy jegy és egy beszélgetés között?",
        answer:
          "A jegy rögzíti a munkát és annak állapotát; a végrehajtás egy beszélgetésben történik. A beszélgetés egy elkülönített copy-on-write worktree-t készíthet elő egy ügynökfutás előtt. Windowson ez az előkészítés Git-worktree-t használ.",
        links: [
          { label: "Egy mintafolyamat követése", href: "/hu-HU/#workflows" },
        ],
      },
      {
        question: "Hol futnak az ügynökök, és mit csinál a szerver?",
        answer:
          "A szerver birtokolja a munkatér adatbázisát, a hitelesítő adatokat, az API-kat és az ügynökök végrehajtását; az asztali és a böngészős kliensek megjelenítik és vezérlik ezt a munkát. A flotta opcionális workerei bérelt feladatokat vesznek fel és eseményeket streamelnek, de nem tartják az adatbázist, a hitelesítő adatokat vagy a kereteket.",
        links: [
          {
            label: "Az architektúra útmutató olvasása",
            href: "/manual/concepts/architecture/",
          },
        ],
      },
      {
        question: "Mennyi beleszólásom van egy ügynökfutásba?",
        answer:
          "Minden beszélgetés használhatja a Csak javaslat, a Cselekvés jóváhagyással vagy a Szabad cselekvés módot. Az engedélyek és a sandbox továbbra is határolják a megengedett műveleteket; jóváhagyó nélkül a kérések elutasítva. A puha keretek figyelmeztetnek, a kemények szüneteltetnek, a futások pedig naplót kapnak.",
        links: [
          { label: "A vezérlés megtekintése", href: "/hu-HU/#boundaries" },
        ],
      },
      {
        question: "Egy Orchestrate-terv automatikusan ügynököket fogad fel?",
        answer:
          "Nem. Az Orchestrate felkutathat és javasolhat szerepeket, gyermekjegyeket és egy tervet, de a felvétel jóváhagyásra vár. A Plan Studio a terv során nyílik meg az eredeti beszélgetésben; egy jegy kiosztása önmagában nem indít futást.",
        links: [
          { label: "A mintafolyamat követése", href: "/hu-HU/#workflows" },
        ],
      },
      {
        question: "Futtathatok ügynököket a párosított telefonról?",
        answer:
          "A párosított telefon vékony kliens ugyanahhoz a szerveres munkatérhez, nem második végrehajtó gép. Az asztal, a böngésző és a telefon ugyanazt a működést mutatja; az ügynökök a szerveren vagy opcionális, bérelt flotta-workereken futnak.",
        links: [
          {
            label: "A kapcsolt felületek megtekintése",
            href: "/hu-HU/#surfaces",
          },
        ],
      },
      {
        question: "Milyen integrációkat használhatok?",
        answer:
          "A Linear jegyszinkronizálás kész; a Jira és a ClickUp nem rendelkezik adapterrel. A csatlakoztatott Google Calendar-események csak olvashatók, a visszajelzés pedig csak akkor érhető el, ha a naptár írási jogot ad. A Slack-szálak beszélgetésekhez köthetők, a csatlakoztatott forge-ok pedig pull requesteket és ellenőrzéseket adnak.",
        links: [{ label: "A kézikönyv olvasása", href: "/manual/" }],
      },
      {
        question: "Mikor jelennek meg a megbeszélés jegyzetei és teendői?",
        answer:
          "Az élő átirat felvétel közben szét tudja választani a beszélőket. Ha leállítod, az összefoglaló ügynök feldolgozza a megbeszélést, és elmenti a jegyzeteket, a döntéseket és a teendőket; a felvétel és a feldolgozás külön állapot.",
        links: [{ label: "A nap összefüggésben", href: "/hu-HU/#day" }],
      },
      {
        question: "A nyilvános demó valódi munkatér?",
        answer:
          "A nyilvános demó külön, zárt változat kitalált adatokkal és forgatókönyvet követő ügynökökkel. A bejegyzései és a futásai példák, nem a te munkád.",
        links: [{ label: "Az élő demó felfedezése", href: "/demo" }],
      },
    ],
  },
  pilot: {
    controls:
      "3D siklóernyő. Húzd az egérrel a nézet forgatásához és a kormányzáshoz. A bal és jobb nyíl fordít; a fel és le nyíl felfelé vagy lefelé billenti a repülési irányt. Az R visszaállít; a szóköz szünetelteti vagy folytatja a repülést és a szelet.",
  },
  install: {
    title: "Érezd magad\notthon.",
    description:
      "A következő fejlesztői napod itt kezdődhet. Ingyenes és nyílt forráskódú.",
    mac: "Apple Silicon · macOS 13+",
    windows: "x64 · Windows 10+",
    linux: "x86_64 · AppImage",
    release: "Kiadások megtekintése",
    web: "A webalkalmazás megnyitása",
    phone: "A telefonos társ megnyitása",
    webNote: "Csatlakozz egy szerverhez, amelyet te futtatsz.",
    phoneNote: "Párosítsd a telefont a szervereddel egy zárt átjátszón át.",
    selfHost: "Inkább magad futtatnád?",
    server: "Felület nélküli szerver futtatása",
    guide: "A gyorstalpaló elolvasása",
  },
  footer: {
    tagline: "Otthon a fejlesztői napodnak.",
    resources: "Források",
    source: "Forrás a GitHubon",
    compare: "Összehasonlítás",
    changelog: "Változásnapló",
    about: "Névjegy",
    contact: "Kapcsolat",
    privacy: "Adatvédelem",
    terms: "Feltételek",
    licenses: "Licencek",
    acknowledgements: "Köszönetnyilvánítás",
    made: "Nyíltan építve.",
    top: "Vissza a tetejére",
  },
};
