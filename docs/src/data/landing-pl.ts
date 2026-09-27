import type { LandingCopy } from "./landing-en";

export const pl: LandingCopy = {
  meta: {
    title: "Control Center \\\\ Miejsce na twój dzień dewelopera",
    description:
      "Zbierz zgłoszenia, przeglądy kodu, agentów AI, spotkania i pipeline’y. Darmowa przestrzeń robocza open source na komputer, przeglądarkę i telefon.",
    imageAlt: "Control Center, twoja praca deweloperska w jednej przestrzeni.",
  },
  nav: {
    product: "Produkt",
    workflows: "Przepływy",
    features: "Funkcje",
    docs: "Dokumentacja",
    demo: "Wypróbuj demo",
    download: "Pobierz",
    menu: "Menu",
    primary: "Nawigacja główna",
    mobile: "Nawigacja mobilna",
    home: "Strona główna Control Center",
    skip: "Przejdź do treści",
    language: "Język",
    appearance: "Wygląd",
    light: "Jasny",
    dark: "Ciemny",
    system: "System",
  },
  hero: {
    line1: "Dużo ruchomych części.",
    line2: "Jeden Control Center.",
    description:
      "Miejsce na kod, agentów, przeglądy i wszystko inne, z czego składa się dzień dewelopera.",
    download: "Pobierz Control Center",
    demo: "Zobacz demo na żywo",
    platforms: "macOS, Windows, Linux",
    web: "Także w przeglądarce i na telefonie",
  },
  media: {
    phone:
      "Towarzysz na telefonie pokazuje tę samą przestrzeń roboczą, oczekującą zgodę i stan uruchomienia agenta.",
  },
  tour: {
    label: "Poznaj Control Center",
    previous: "Poprzedni widok produktu",
    next: "Następny widok produktu",
    play: "Odtwórz prezentację",
    pause: "Wstrzymaj prezentację",
    expand: "Powiększ podgląd",
    close: "Zamknij podgląd",
    preview: "Podgląd produktu",
    note: "Bliższe spojrzenie na twój dzień dewelopera.",
    imageLanguage: "Miejsce na obraz lub wideo",
    stops: [
      {
        kind: "desk",
        label: "Twój dzień",
        title: "Zacznij od tego, co cię potrzebuje.",
        description:
          "Prośby o przegląd, zgody i blokady. Następne działanie, bez szukania po kartach.",
        alt: "Skrzynka Control Center grupująca pull requesty według stanu przeglądu i pokazująca blokadę synchronizacji.",
      },
      {
        kind: "agents",
        label: "Agenci",
        title: "Daj dobrej pracy miejsce, żeby się wydarzyła.",
        description:
          "Uruchamiaj agentów w odizolowanych worktree Gita. Śledź ich narzędzia, kieruj pracą i zachowaj kontekst.",
        alt: "Rozmowa z agentem w Control Center, z kontekstem zadania i aktywnością.",
      },
      {
        kind: "review",
        label: "Przegląd kodu",
        title: "Przeczytaj zmianę. Poznaj historię.",
        description:
          "Diffy, dyskusje i sprawdzenia zostają razem. Opublikuj przegląd ze swojego konta.",
        alt: "Przegląd pull requesta w Control Center ze zmianami w kodzie i kontekstem przeglądu.",
      },
      {
        kind: "tickets",
        label: "Zgłoszenia",
        title: "Nie gub następnego kroku.",
        description:
          "Śledź priorytety i odpowiedzialność, synchronizuj Linear i powiąż rozmowę, w której powstaje praca.",
        alt: "Tablica zgłoszeń Control Center z zadaniami pogrupowanymi według stanu.",
      },
      {
        kind: "meetings",
        label: "Spotkania",
        title: "Zostaw decyzje po rozmowie.",
        description:
          "Nagrywaj i transkrybuj na swoim serwerze. Po spotkaniu masz notatki i działania.",
        alt: "Spotkanie w Control Center z transkrypcją i informacjami o spotkaniu.",
      },
      {
        kind: "pipelines",
        label: "Pipeline’y",
        title: "Niech powtarzalna praca naprawdę się powtarza.",
        description:
          "Zbuduj przepływ, wybierz wyzwalacz i śledź każdy krok uruchomienia.",
        alt: "Widok pipeline’u Control Center z krokami przepływu i stanem uruchomienia.",
      },
    ],
  },
  integrations: {
    title: "Weź narzędzia, z których już korzystasz.",
    note: "Podłączone przez twój serwer, a nie jako kolejna kopia dnia.",
  },
  grid: {
    title: "Narzędzia, po które sięgasz codziennie.",
    description: "Rób pracę, przeglądaj zmiany i zachowuj decyzje.",
    more: "Czytaj dokumentację",
    items: [
      {
        title: "Agenci równolegle",
        description:
          "Daj każdemu zadaniu odizolowany worktree Gita. Śledź uruchomienie, kieruj agentem albo przejmij stery, nie ruszając reszty.",
        link: "Uruchamiaj agentów równolegle",
        kind: "agents",
        href: "/manual/guides/parallel-agents/",
      },
      {
        title: "Przegląd pull requestów",
        description:
          "Czytaj diffy obok dyskusji i sprawdzeń. Dodaj przegląd AI, kiedy pomaga, i opublikuj ze swojego konta w forge.",
        link: "Przejrzyj pull request",
        kind: "review",
        href: "/manual/guides/review-merge-pr/",
      },
      {
        title: "Powiązane zgłoszenia",
        description:
          "Synchronizuj Linear, ustawiaj priorytety i przypisuj pracę. Połącz zgłoszenie z rozmową, w której jest robione.",
        link: "Zarządzaj zgłoszeniami",
        kind: "tickets",
        href: "/manual/guides/manage-tickets/",
      },
      {
        title: "Notatki ze spotkań",
        description:
          "Nagrywaj i transkrybuj na swoim serwerze. Decyzje i działania zostają po zakończeniu rozmowy.",
        link: "Nagraj spotkanie",
        kind: "meetings",
        href: "/manual/guides/record-meeting/",
      },
      {
        title: "Powtarzalne pipeline’y",
        description:
          "Zbuduj przepływ raz. Uruchamiaj go według harmonogramu, ze zdarzenia albo ręcznie i sprawdzaj każdy krok.",
        link: "Zbuduj pipeline",
        kind: "pipelines",
        href: "/manual/guides/create-pipeline/",
      },
      {
        title: "Przełączanie kont",
        description:
          "Wybierz konta dostępne dla każdego agenta i przełączaj się między nimi bez utraty kontekstu uruchomienia.",
        link: "Zarządzaj dostawcami modeli",
        kind: "accounts",
        href: "/manual/guides/adapters/",
        alt: "Edytor puli kont w Control Center pokazujący konta dostępne dla agenta.",
      },
      {
        title: "Limit użycia",
        description:
          "Sprawdź limit u dostawcy i terminy jego odnowienia przed kolejnym uruchomieniem.",
        link: "Zarządzaj kosztami",
        kind: "quota",
        href: "/manual/guides/manage-costs/",
        alt: "Panel użycia Control Center pokazujący limity dostawców i terminy ich odnowienia.",
      },
      {
        title: "Pejzaże dźwiękowe i skupienie",
        description:
          "Rozpocznij sesję skupienia na określony czas, wycisz powiadomienia i dostosuj towarzyszący jej pejzaż dźwiękowy.",
        link: "Używaj trybu skupienia",
        kind: "focus",
        href: "/manual/guides/focus-mode/",
        alt: "Minutnik skupienia i ustawienia pejzaży dźwiękowych w Control Center.",
      },
      {
        title: "Monitorowanie uruchomień",
        description:
          "Śledź aktywnych agentów i sprawdzaj koszty uruchomień, zużycie tokenów oraz opóźnienia w swojej przestrzeni roboczej.",
        link: "Sprawdź uruchomienia agentów",
        kind: "observability",
        href: "/manual/guides/manage-costs/",
        alt: "Widok monitorowania Control Center z aktywnymi agentami i analizą uruchomień.",
      },
      {
        title: "Edytory umiejętności i agentów",
        description:
          "Edytuj umiejętności przestrzeni roboczej i konfiguruj model, instrukcje oraz uprawnienia każdego agenta.",
        link: "Zarządzaj umiejętnościami",
        kind: "editors",
        href: "/manual/guides/manage-skills/",
        alt: "Edytor umiejętności i ustawienia agentów w Control Center.",
      },
    ],
    supporting: [
      {
        title: "Jedna skrzynka",
        description:
          "Przeglądy, zgody i blokady w jednej kolejce. Przejdź do następnego zadania paletą poleceń.",
        href: "/manual/guides/triage-inbox/",
      },
      {
        title: "Sprawdzaj z telefonu",
        description:
          "Śledź uruchomienia i obsługuj zgody bez wracania do biurka.",
        href: "/manual/concepts/remote-control/",
      },
    ],
  },
  workflow: {
    title: "Nie gub wątku.\nAż do wydania.",
    description:
      "Praca przechodzi między narzędziami. Kontekst powinien iść z nią.",
    label: "Połączony przepływ",
    steps: [
      {
        title: "Zacznij od zgłoszenia.",
        text: "Ustaw priorytet, wskaż właściciela i powiąż rozmowę. Zgłoszenie trzyma zapis.",
        kind: "tickets",
        label: "Zamiar",
      },
      {
        title: "Daj pracy własne miejsce.",
        text: "Omów plan, przygotuj odizolowany worktree i uruchom agenta. Kieruj albo przejmij, kiedy trzeba.",
        kind: "agents",
        label: "Praca",
      },
      {
        title: "Wnieś wynik do przeglądu.",
        text: "Przeczytaj zmiany, śledź dyskusję i opublikuj ze swojego konta w forge. Historia zostaje połączona.",
        kind: "review",
        label: "Wynik",
      },
    ],
  },
  boundaries: {
    title: "Zatwierdź push, zanim ruszy.",
    description:
      "Schowaj pushe Gita, publikowanie pull requestów i inne chronione działania za zgodą. Sprawdź, co agent ma zrobić, zanim cokolwiek zmieni.",
    media:
      "Uruchomienie agenta wstrzymane na prośbie o zgodę na push Gita. Pokaż proponowane polecenie, katalog roboczy i przyciski zatwierdzenia albo odmowy.",
    note: "Nikt nie jest podłączony, żeby zatwierdzić? Działanie jest odrzucane. Uprawnienia egzekwuje twój serwer, nie prompt.",
    link: "Skonfiguruj zgody na działania",
  },
  surfaces: {
    title: "Biurko jest miejscem.\nPraca nie.",
    description:
      "Zacznij na komputerze. Wejdź z przeglądarki. Bądź blisko z telefonu. Jeden serwer trzyma operację razem.",
    desktop: "Natywny pulpit",
    web: "W przeglądarce",
    phone: "Towarzysz na telefonie",
    note: "Twój serwer ma dane i wykonanie. Urządzenia zostają zsynchronizowane.",
    link: "Znajdź swoją platformę",
  },
  faq: {
    title: "Dobre pytania.",
    description: "Kilka rzeczy, zanim się rozgoszczysz.",
    items: [
      {
        question: "Czy Control Center jest tylko dla agentów AI?",
        answer:
          "Nie. Control Center zbiera zgłoszenia, pull requesty, rozmowy, spotkania, kalendarz, pipeline’y, agentów i osobny czytnik RSS w jednej przestrzeni roboczej. Agenci są częścią biurka, nie warunkiem korzystania z reszty.",
        links: [{ label: "Poznaj funkcje", href: "/pl-PL/#features" }],
      },
      {
        question: "Czym różni się zgłoszenie od rozmowy?",
        answer:
          "Zgłoszenie zapisuje pracę i jej stan; wykonanie dzieje się w rozmowie. Rozmowa może przygotować odizolowany worktree copy-on-write przed uruchomieniem agenta. W Windows to przygotowanie używa worktree Gita.",
        links: [
          { label: "Zobacz przykładowy przepływ", href: "/pl-PL/#workflows" },
        ],
      },
      {
        question: "Gdzie działają agenci i co robi serwer?",
        answer:
          "Serwer ma bazę przestrzeni roboczej, poświadczenia, API i wykonanie agentów; klienty na komputerze i w przeglądarce pokazują tę pracę i nią sterują. Opcjonalni workerzy floty pobierają wydzierżawione zadania i strumieniują zdarzenia, ale nie trzymają bazy, poświadczeń ani budżetów.",
        links: [
          {
            label: "Przeczytaj przewodnik po architekturze",
            href: "/manual/concepts/architecture/",
          },
        ],
      },
      {
        question: "Ile kontroli mam nad uruchomieniem agenta?",
        answer:
          "Każda rozmowa może używać Tylko propozycje, Działa po zatwierdzeniu albo Działa swobodnie. Uprawnienia i piaskownica nadal ograniczają dozwolone działania; prośby o zgodę bez osoby zatwierdzającej są odrzucane. Miękkie limity budżetu ostrzegają, twarde wstrzymują, a uruchomienia zostają w dzienniku.",
        links: [{ label: "Zobacz sterowanie", href: "/pl-PL/#boundaries" }],
      },
      {
        question: "Czy plan Orchestrate zatrudnia agentów automatycznie?",
        answer:
          "Nie. Orchestrate może zbadać i zaproponować role, zgłoszenia podrzędne i plan, ale zatrudnienie czeka na zgodę. Plan Studio otwiera się z wiersza planu w rozmowie źródłowej; samo przypisanie zgłoszenia nie uruchamia pracy.",
        links: [
          { label: "Zobacz przykładowy przepływ", href: "/pl-PL/#workflows" },
        ],
      },
      {
        question: "Czy mogę uruchamiać agentów ze sparowanego telefonu?",
        answer:
          "Sparowany telefon jest cienkim klientem tej samej przestrzeni na serwerze, a nie drugim hostem wykonania. Komputer, przeglądarka i telefon pokazują tę samą operację; agenci działają na serwerze albo na opcjonalnych, wydzierżawionych workerach floty.",
        links: [
          { label: "Zobacz połączone powierzchnie", href: "/pl-PL/#surfaces" },
        ],
      },
      {
        question: "Jakich integracji mogę użyć?",
        answer:
          "Synchronizacja zgłoszeń z Linear jest wdrożona; Jira i ClickUp nie mają adapterów. Połączone wydarzenia Google Calendar są tylko do odczytu, a RSVP działa dopiero wtedy, gdy kalendarz nada prawo zapisu. Wątki Slacka można mostkować do rozmów, a połączone forge dostarczają pull requesty i sprawdzenia.",
        links: [{ label: "Czytaj podręcznik", href: "/manual/" }],
      },
      {
        question: "Kiedy pojawiają się notatki ze spotkania i działania?",
        answer:
          "Transkrypcja na żywo może rozdzielać mówiących w trakcie nagrania. Po zatrzymaniu agent podsumowujący przetwarza spotkanie i zapisuje notatki, decyzje i działania; nagrywanie i przetwarzanie to osobne stany.",
        links: [{ label: "Zobacz dzień w kontekście", href: "/pl-PL/#day" }],
      },
      {
        question: "Czy publiczne demo jest prawdziwą przestrzenią roboczą?",
        answer:
          "Publiczne demo to osobna, ograniczona wersja z wymyślonymi danymi i agentami według scenariusza. Jej zapisy i uruchomienia są przykładami, nie twoją pracą.",
        links: [{ label: "Zobacz demo na żywo", href: "/demo" }],
      },
    ],
  },
  pilot: {
    controls:
      "Paralotnia 3D. Przeciągnij, by obracać widok i sterować. Strzałki w lewo i w prawo skręcają; strzałki w górę i w dół pochylają lot w górę lub w dół. R resetuje; spacja wstrzymuje lub wznawia lot i wiatr.",
  },
  install: {
    title: "Rozgość\nsię.",
    description:
      "Twój następny dzień dewelopera może zacząć się tutaj. Za darmo i open source.",
    mac: "Apple Silicon · macOS 13+",
    windows: "x64 · Windows 10+",
    linux: "x86_64 · AppImage",
    release: "Zobacz wydania",
    web: "Otwórz aplikację webową",
    phone: "Otwórz towarzysza na telefonie",
    webNote: "Połącz się z serwerem, który sam uruchamiasz.",
    phoneNote: "Sparuj telefon z serwerem przez zamknięty relay.",
    selfHost: "Wolisz hostować sam?",
    server: "Uruchom serwer bez interfejsu",
    guide: "Przeczytaj skrócony przewodnik",
  },
  footer: {
    tagline: "Miejsce na twój dzień dewelopera.",
    resources: "Zasoby",
    source: "Źródła na GitHubie",
    compare: "Porównanie",
    changelog: "Dziennik zmian",
    about: "O nas",
    contact: "Kontakt",
    privacy: "Prywatność",
    terms: "Warunki",
    licenses: "Licencje",
    acknowledgements: "Podziękowania",
    made: "Budowane otwarcie.",
    top: "Wróć na górę",
  },
};
