import type { LandingCopy } from './landing-en';

export const de: LandingCopy = {
  meta: {
    title: 'Control Center | Ein Zuhause für deinen Entwickleralltag',
    description: 'Tickets, Code-Reviews, KI-Agenten, Meetings und Pipelines an einem Ort. Ein kostenloser, quelloffener Arbeitsbereich für Desktop, Web und Smartphone.',
    imageAlt: 'Control Center vereint deinen Entwickleralltag in einem Arbeitsbereich.',
  },
  nav: { product: 'Produkt', workflows: 'Abläufe', features: 'Funktionen', docs: 'Dokumentation', demo: 'Demo testen', download: 'Herunterladen', menu: 'Menü', primary: 'Hauptnavigation', mobile: 'Mobile Navigation', home: 'Control Center: Startseite', skip: 'Zum Inhalt springen', language: 'Sprache', appearance: 'Darstellung', light: 'Hell', dark: 'Dunkel', system: 'System' },
  hero: {
    line1: 'Vieles läuft parallel.',
    line2: 'Alles im Control Center.',
    description: 'Ein Ort für deinen Code, deine Agenten, Reviews und alles, was sonst zu deinem Entwickleralltag gehört.',
    download: 'Control Center laden',
    demo: 'Live-Demo ansehen',
    platforms: 'macOS, Windows, Linux',
    web: 'Auch im Web und auf dem Smartphone',
  },
  media: {
    phone: 'Smartphone-Begleiter mit demselben Arbeitsbereich, einer ausstehenden Freigabe und dem Status eines Agentenlaufs.',
  },
  tour: {
    label: 'Control Center entdecken',
    previous: 'Vorherige Produktansicht', next: 'Nächste Produktansicht',
    play: 'Rundgang starten', pause: 'Rundgang pausieren', expand: 'Vorschau vergrößern', close: 'Vorschau schließen',
    preview: 'Produktvorschau', note: 'Ein genauerer Blick auf deinen Entwickleralltag.', imageLanguage: 'Platzhalter für Bild oder Video',
    stops: [
      { kind: 'desk', label: 'Dein Tag', title: 'Sieh zuerst, was dich braucht.', description: 'Review-Anfragen, Freigaben und Blockaden. Der nächste Schritt ist klar, ohne Tabs zu durchsuchen.', alt: 'Control-Center-Posteingang mit Pull Requests nach Review-Status und einer blockierten Synchronisierung.' },
      { kind: 'agents', label: 'Agenten', title: 'Gib der Arbeit ihren eigenen Raum.', description: 'Starte Agenten in isolierten Worktrees. Verfolge ihre Werkzeuge, lenke die Arbeit und behalte den Kontext.', alt: 'Agentengespräch in Control Center mit Aufgabenkontext und Aktivitäten.' },
      { kind: 'review', label: 'Code-Review', title: 'Verstehe jede Änderung im Zusammenhang.', description: 'Diffs, Diskussionen und Checks bleiben beisammen. Veröffentliche das Review unter deinem Namen.', alt: 'Pull-Request-Review in Control Center mit Codeänderungen und Review-Kontext.' },
      { kind: 'tickets', label: 'Tickets', title: 'Der nächste Schritt bleibt verbunden.', description: 'Halte Prioritäten und Zuständigkeiten fest, synchronisiere Linear und verknüpfe das Gespräch, in dem gearbeitet wird.', alt: 'Ticketübersicht in Control Center mit Aufgaben nach Status.' },
      { kind: 'meetings', label: 'Meetings', title: 'Entscheidungen bleiben nach dem Gespräch.', description: 'Aufnahme und Transkription laufen auf deinem Server. Nach dem Meeting bekommst du Notizen und Aufgaben.', alt: 'Meeting in Control Center mit Transkript und Meetinginformationen.' },
      { kind: 'pipelines', label: 'Pipelines', title: 'Mach wiederkehrende Arbeit wiederholbar.', description: 'Erstelle einen Ablauf, wähle seinen Auslöser und verfolge jeden Schritt.', alt: 'Pipeline-Ansicht in Control Center mit Ablaufschritten und Ausführungsstatus.' },
    ],
  },
  integrations: { title: 'Nutze die Werkzeuge, mit denen du schon arbeitest.', note: 'Verbunden über deinen Server, statt deinen Tag noch einmal zu kopieren.' },
  grid: {
    title: 'Die Werkzeuge für jeden Tag.',
    description: 'Erledige die Arbeit, prüfe Änderungen und halte Entscheidungen fest.',
    more: 'Dokumentation lesen',
    items: [
      { title: 'Parallele Agenten', description: 'Gib jeder Aufgabe einen eigenen Git-Worktree. Verfolge den Lauf, lenke den Agenten oder übernimm selbst, ohne die übrige Arbeit zu stören.', link: 'Agenten parallel ausführen', kind: 'agents', href: '/manual/guides/parallel-agents/' },
      { title: 'Pull-Request-Reviews', description: 'Lies Diffs mit Diskussionen und Checks direkt daneben. Nutze bei Bedarf ein KI-Review und veröffentliche dann über dein eigenes Forge-Konto.', link: 'Pull Request prüfen', kind: 'review', href: '/manual/guides/review-merge-pr/' },
      { title: 'Verknüpfte Tickets', description: 'Synchronisiere Linear, setze Prioritäten und weise Aufgaben zu. Verknüpfe das Ticket mit dem Gespräch, in dem die Arbeit erledigt wird.', link: 'Tickets verwalten', kind: 'tickets', href: '/manual/guides/manage-tickets/' },
      { title: 'Meetingnotizen', description: 'Nimm Meetings auf deinem Server auf und transkribiere sie. Entscheidungen und Aufgaben bleiben auch nach dem Gespräch erhalten.', link: 'Meeting aufzeichnen', kind: 'meetings', href: '/manual/guides/record-meeting/' },
      { title: 'Wiederverwendbare Pipelines', description: 'Erstelle einen Ablauf einmal. Starte ihn nach Zeitplan, durch ein Ereignis oder von Hand und prüfe jeden Schritt.', link: 'Pipeline erstellen', kind: 'pipelines', href: '/manual/guides/create-pipeline/' },
    ],
    supporting: [
      { title: 'Ein Posteingang', description: 'Reviews, Freigaben und Blockaden in einer Liste. Mit der Befehlspalette springst du zur nächsten Aufgabe.', href: '/manual/guides/triage-inbox/' },
      { title: 'Zeit zum Konzentrieren', description: 'Reduziere Benachrichtigungen, starte eine Fokussitzung und wähle eine generative Klanglandschaft.', href: '/manual/guides/focus-mode/' },
      { title: 'Vom Smartphone aus nachsehen', description: 'Verfolge deine Läufe und bearbeite Freigaben, ohne an den Schreibtisch zurückzukehren.', href: '/manual/concepts/remote-control/' },
    ],
  },
  workflow: {
    title: 'Ein roter Faden.\nBis zur Auslieferung.',
    description: 'Arbeit wandert zwischen Werkzeugen. Ihr Kontext sollte mitkommen.',
    label: 'Ein verbundener Ablauf',
    steps: [
      { title: 'Beginne mit dem Ticket.', text: 'Setze die Priorität, lege die Zuständigkeit fest und verknüpfe das Gespräch. Das Ticket hält alles fest.', kind: 'tickets', label: 'Der Auftrag' },
      { title: 'Gib der Arbeit ihren eigenen Raum.', text: 'Besprich einen Plan, bereite einen isolierten Worktree vor und starte den Agenten. Lenke die Arbeit oder übernimm selbst.', kind: 'agents', label: 'Die Arbeit' },
      { title: 'Bring das Ergebnis ins Review.', text: 'Lies die Änderungen, verfolge die Diskussion und veröffentliche mit deinem Forge-Konto. Der Zusammenhang bleibt erhalten.', kind: 'review', label: 'Das Ergebnis' },
    ],
  },
  boundaries: {
    title: 'Git-Push vor der Ausführung freigeben.',
    description: 'Sichere Git-Pushes, die Veröffentlichung von Pull Requests und andere geschützte Aktionen durch eine Freigabe ab. Prüfe, was der Agent vorhat, bevor er etwas ändert.',
    media: 'Ein Agentenlauf, der bei einer Freigabeanfrage für einen Git-Push pausiert. Zeige den vorgeschlagenen Befehl, das Arbeitsverzeichnis und Schaltflächen zum Freigeben oder Ablehnen.',
    note: 'Niemand zum Freigeben verbunden? Die Aktion wird abgelehnt. Dein Server setzt Berechtigungen durch, nicht ein Prompt.',
    link: 'Aktionsfreigaben einrichten',
  },
  surfaces: {
    title: 'Dein Arbeitsplatz ist ein Ort.\nDeine Arbeit nicht.',
    description: 'Starte am Desktop. Schau im Browser nach. Bleib auch auf dem Smartphone dabei. Ein Server hält alles zusammen.',
    desktop: 'Native Desktop-App', web: 'Im Browser', phone: 'Smartphone-Begleiter',
    note: 'Dein Server verwaltet die Daten und führt die Arbeit aus. Deine Geräte bleiben synchron.',
    link: 'Passende Plattform finden',
  },
  faq: {
    title: 'Gute Fragen.', description: 'Ein paar Dinge, die du vor dem Start wissen solltest.',
    items: [
      { question: 'Ist Control Center nur für KI-Agenten?', answer: 'Nein. Control Center bringt Tickets, Pull Requests, Gespräche, Meetings, Kalender, Pipelines, Agenten und einen persönlichen RSS-Reader in einem Arbeitsbereich zusammen. Agenten sind nur ein Teil davon; du brauchst sie nicht, um die anderen Funktionen zu nutzen.', links: [{ label: 'Funktionen entdecken', href: '/de-DE/#features' }] },
      { question: 'Was unterscheidet ein Ticket von einem Gespräch?', answer: 'Ein Ticket hält die Arbeit und ihren Status fest; ausgeführt wird sie in einem Gespräch. Vor einem Agentenlauf kann das Gespräch einen isolierten Copy-on-Write-Worktree bereitstellen. Unter Windows wird dafür ein Git-Worktree verwendet.', links: [{ label: 'Beispielablauf ansehen', href: '/de-DE/#workflows' }] },
      { question: 'Wo laufen Agenten und was macht der Server?', answer: 'Der Server verwaltet die Datenbank des Arbeitsbereichs, Zugangsdaten und APIs und führt Agenten aus; Desktop- und Browser-Clients zeigen und steuern die Arbeit. Optionale Worker-Maschinen holen befristet zugewiesene Aufträge ab und streamen Ereignisse, speichern aber weder Datenbank noch Zugangsdaten oder Budgets.', links: [{ label: 'Architektur nachlesen', href: '/manual/concepts/architecture/' }] },
      { question: 'Wie viel Kontrolle habe ich über einen Agentenlauf?', answer: 'Für jedes Gespräch kannst du „Nur vorschlagen“, „Mit Freigabe handeln“ oder „Eigenständig handeln“ wählen. Berechtigungen und eine Sandbox begrenzen weiterhin die erlaubten Aktionen; ohne zuständige Person werden Freigabeanfragen abgelehnt. Weiche Budgetgrenzen warnen, harte pausieren, und Ausführungen werden protokolliert.', links: [{ label: 'Steuerung ansehen', href: '/de-DE/#boundaries' }] },
      { question: 'Bindet ein Orchestrierungsplan automatisch Agenten ein?', answer: 'Nein. Die Orchestrierung kann Rollen, untergeordnete Tickets und einen Plan recherchieren und vorschlagen, doch weitere Agenten werden erst nach Freigabe eingebunden. Der Planeditor öffnet sich über die Planzeile im ursprünglichen Gespräch; eine Ticketzuweisung allein startet keinen Lauf.', links: [{ label: 'Beispielablauf ansehen', href: '/de-DE/#workflows' }] },
      { question: 'Kann ich Agenten vom gekoppelten Smartphone aus ausführen?', answer: 'Das gekoppelte Smartphone ist ein schlanker Client für denselben servergestützten Arbeitsbereich, kein zweiter Ausführungsrechner. Desktop, Browser und Smartphone zeigen dieselbe Arbeit; Agenten laufen auf dem Server oder optional auf befristet eingebundenen Worker-Maschinen.', links: [{ label: 'Verbundene Geräte ansehen', href: '/de-DE/#surfaces' }] },
      { question: 'Welche Integrationen kann ich nutzen?', answer: 'Die Synchronisierung mit Linear funktioniert; für Jira und ClickUp gibt es keine Anbindungen. Verbundene Google-Kalendertermine sind schreibgeschützt; Zu- und Absagen sind nur mit Schreibberechtigung für den Kalender möglich. Slack-Threads lassen sich mit Gesprächen verbinden, und angebundene Code-Hosts liefern Pull Requests und Checks.', links: [{ label: 'Handbuch lesen', href: '/manual/' }] },
      { question: 'Wann erscheinen Meetingnotizen und Aufgaben?', answer: 'Das Live-Transkript kann während der Aufnahme Sprechende unterscheiden. Nach dem Stopp verarbeitet ein zusammenfassender Agent das Meeting und speichert Notizen, Entscheidungen und Aufgaben; Aufnahme und Verarbeitung sind getrennte Zustände.', links: [{ label: 'Den Tag im Zusammenhang sehen', href: '/de-DE/#day' }] },
      { question: 'Ist die öffentliche Demo ein echter Arbeitsbereich?', answer: 'Die öffentliche Demo ist eine separate, eingeschränkte Version mit erfundenen Daten und Agenten, die einem Skript folgen. Ihre Einträge und Ausführungen sind Beispiele, nicht deine eigene Arbeit.', links: [{ label: 'Live-Demo ansehen', href: '/demo' }] },
    ],
  },
  pilot: {
      controls: '3D-Gleitschirm. Ziehen, um die Ansicht zu drehen und zu steuern. Die Pfeiltasten links und rechts lenken; oben und unten neigen den Schirm nach oben oder unten. R setzt zurück; die Leertaste pausiert oder setzt Flug und Wind fort.',
    },
  install: {
    title: 'Mach es dir\nbequem.', description: 'Dein nächster Entwickleralltag kann hier beginnen. Kostenlos und quelloffen.',
    mac: 'Apple Silicon · macOS 13+', windows: 'x64 · Windows 10+', linux: 'x86_64 · AppImage',
    release: 'Versionen ansehen', web: 'Web-App öffnen', phone: 'Smartphone-Begleiter öffnen',
    webNote: 'Verbinde dich mit deinem eigenen Server.', phoneNote: 'Kopple dein Gerät über einen verschlüsselten Relay-Dienst mit deinem Server.',
    selfHost: 'Lieber selbst hosten?', server: 'Server ohne Oberfläche betreiben', guide: 'Kurzanleitung lesen',
  },
  footer: { tagline: 'Ein Zuhause für deinen Entwickleralltag.', resources: 'Ressourcen', source: 'Quellcode auf GitHub', compare: 'Vergleich', changelog: 'Änderungsprotokoll', about: 'Über uns', contact: 'Kontakt', privacy: 'Datenschutz', terms: 'Nutzungsbedingungen', licenses: 'Lizenzen', acknowledgements: 'Danksagungen', made: 'Offen entwickelt.', top: 'Nach oben' },
};
