import type { LandingCopy } from './landing-en';

export const nb: LandingCopy = {
  meta: {
    title: 'Control Center | Et hjem for utviklerdagen din',
    description: 'Samle saker, kodegjennomganger, KI-agenter, møter og pipelines. Et gratis arbeidsområde med åpen kildekode for skrivebord, nett og telefon.',
    imageAlt: 'Control Center, utviklerarbeidet ditt i ett arbeidsområde.',
  },
  nav: { product: 'Produkt', workflows: 'Flyter', features: 'Funksjoner', docs: 'Dokumentasjon', demo: 'Prøv demoen', download: 'Last ned', menu: 'Meny', primary: 'Hovednavigasjon', mobile: 'Mobilnavigasjon', home: 'Control Center-forsiden', skip: 'Hopp til innhold', language: 'Språk', appearance: 'Utseende', light: 'Lyst', dark: 'Mørkt', system: 'System' },
  hero: {
    line1: 'Mange deler i bevegelse.',
    line2: 'Ett Control Center.',
    description: 'Et hjem for koden, agentene, gjennomgangene og alt det andre som fyller en utviklerdag.',
    download: 'Hent Control Center',
    demo: 'Utforsk livedemoen',
    platforms: 'macOS, Windows, Linux',
    web: 'Også på nett og telefon',
  },
  media: {
    phone: 'Telefonfølgesvennen viser samme arbeidsområde, en ventende godkjenning og status for en agentkjøring.',
  },
  tour: {
    label: 'Utforsk Control Center',
    previous: 'Forrige produktvisning', next: 'Neste produktvisning',
    play: 'Spill av omvisningen', pause: 'Sett omvisningen på pause', expand: 'Utvid forhåndsvisningen', close: 'Lukk forhåndsvisningen',
    preview: 'Produktforhåndsvisning', note: 'Et nærmere blikk på utviklerdagen din.', imageLanguage: 'Plassholder for bilde eller video',
    stops: [
      { kind: 'desk', label: 'Dagen din', title: 'Start med det som trenger deg.', description: 'Forespørsler om gjennomgang, godkjenninger og blokkeringer. Neste handling, uten å lete i faner.', alt: 'Innboksen i Control Center grupperer pull requests etter gjennomgangsstatus og viser en synkblokkering.' },
      { kind: 'agents', label: 'Agenter', title: 'Gi godt arbeid rom til å skje.', description: 'Kjør agenter i isolerte Git-worktrees. Følg verktøyene deres, styr arbeidet og behold konteksten.', alt: 'En agentsamtale i Control Center med oppgavens kontekst og aktiviteten.' },
      { kind: 'review', label: 'Kodegjennomgang', title: 'Les endringen. Kjenn historien.', description: 'Diffs, diskusjoner og sjekker blir sammen. Publiser gjennomgangen med din egen konto.', alt: 'Pull request-gjennomgang i Control Center med kodeendringer og gjennomgangskontekst.' },
      { kind: 'tickets', label: 'Saker', title: 'Hold neste steg koblet.', description: 'Følg prioritet og eierskap, synkroniser Linear og knytt samtalen der arbeidet skjer.', alt: 'Sakstavle i Control Center med oppgaver gruppert etter status.' },
      { kind: 'meetings', label: 'Møter', title: 'Behold beslutningene etter samtalen.', description: 'Ta opp og transkriber på serveren din. Når møtet er slutt, har du notater og tiltak.', alt: 'Et møte i Control Center med transkripsjon og møteinformasjon.' },
      { kind: 'pipelines', label: 'Pipelines', title: 'Gjør det gjentakende arbeidet gjentakbart.', description: 'Bygg en flyt, velg utløseren og følg hvert steg i kjøringen.', alt: 'Pipelinevisning i Control Center med flytsteg og kjøringsstatus.' },
    ],
  },
  integrations: { title: 'Ta med verktøyene du allerede jobber i.', note: 'Koblet gjennom serveren din, ikke som enda en kopi av dagen.' },
  grid: {
    title: 'Verktøyene du griper etter hver dag.',
    description: 'Gjør arbeidet, se over det som endret seg, og behold beslutningene.',
    more: 'Les dokumentasjonen',
    items: [
      { title: 'Parallelle agenter', description: 'Gi hver oppgave en isolert Git-worktree. Følg kjøringen, styr en agent eller ta over uten å forstyrre resten.', link: 'Kjør agenter parallelt', kind: 'agents', href: '/manual/guides/parallel-agents/' },
      { title: 'Pull request-gjennomgang', description: 'Les diffs med diskusjoner og sjekker ved siden av. Legg til en KI-gjennomgang når den hjelper, og publiser med din egen forge-konto.', link: 'Gå gjennom en pull request', kind: 'review', href: '/manual/guides/review-merge-pr/' },
      { title: 'Koblede saker', description: 'Synkroniser Linear, sett prioritet og tildel arbeidet. Knytt saken til samtalen der den blir gjort.', link: 'Administrer saker', kind: 'tickets', href: '/manual/guides/manage-tickets/' },
      { title: 'Møtenotater', description: 'Ta opp og transkriber på serveren din. Beslutninger og tiltak blir igjen når samtalen er over.', link: 'Ta opp et møte', kind: 'meetings', href: '/manual/guides/record-meeting/' },
      { title: 'Gjentakbare pipelines', description: 'Bygg en flyt én gang. Kjør den etter tidsplan, fra en hendelse eller for hånd, og se på hvert steg.', link: 'Bygg en pipeline', kind: 'pipelines', href: '/manual/guides/create-pipeline/' },
    ],
    supporting: [
      { title: 'Én innboks', description: 'Gjennomganger, godkjenninger og blokkeringer i én kø. Hopp til neste oppgave med kommandopaletten.', href: '/manual/guides/triage-inbox/' },
      { title: 'Tid til å fokusere', description: 'Demp varsler, start en fokusøkt og velg et generativt lydlandskap.', href: '/manual/guides/focus-mode/' },
      { title: 'Sjekk inn fra telefonen', description: 'Følg kjøringene og håndter godkjenninger uten å gå tilbake til pulten.', href: '/manual/concepts/remote-control/' },
    ],
  },
  workflow: {
    title: 'Hold tråden.\nHelt til det er levert.',
    description: 'Arbeid flytter seg mellom verktøy. Konteksten bør bli med.',
    label: 'En sammenhengende flyt',
    steps: [
      { title: 'Start med saken.', text: 'Sett prioriteten, navngi eieren og knytt samtalen. Saken holder oversikten.', kind: 'tickets', label: 'Hensikten' },
      { title: 'Gi arbeidet et eget rom.', text: 'Diskuter en plan, klargjør en isolert worktree og kjør agenten. Styr eller ta over når du trenger det.', kind: 'agents', label: 'Arbeidet' },
      { title: 'Ta resultatet inn i gjennomgang.', text: 'Les endringene, følg diskusjonen og publiser med forge-kontoen din. Historien forblir koblet.', kind: 'review', label: 'Resultatet' },
    ],
  },
  boundaries: {
    title: 'Godkjenn en push før den kjører.',
    description: 'Legg Git-pusher, publisering av pull requests og andre bevoktede handlinger bak en godkjenning. Se hva agenten er i ferd med å gjøre før noe endres.',
    media: 'En agentkjøring satt på pause ved en forespørsel om godkjenning av en Git-push. Vis den foreslåtte kommandoen, arbeidskatalogen og kontrollene for å godkjenne eller avslå.',
    note: 'Ingen godkjenner tilkoblet? Handlingen avslås. Tillatelser håndheves av serveren din, ikke av en prompt.',
    link: 'Sett opp handlingsgodkjenninger',
  },
  surfaces: {
    title: 'Pulten er et sted.\nArbeidet er det ikke.',
    description: 'Start på skrivebordet. Se inn fra nettleseren. Hold deg nær fra telefonen. Én server holder driften samlet.',
    desktop: 'Innebygd skrivebord', web: 'I nettleseren', phone: 'Telefonfølgesvenn',
    note: 'Serveren din eier dataene og kjøringen. Enhetene dine holdes synkronisert.',
    link: 'Finn plattformen din',
  },
  faq: {
    title: 'Gode spørsmål.', description: 'Noen ting å vite før du slår deg ned.',
    items: [
      { question: 'Er Control Center bare for KI-agenter?', answer: 'Nei. Control Center samler saker, pull requests, samtaler, møter, kalender, pipelines, agenter og en personlig RSS-leser i ett arbeidsområde. Agenter er en del av pulten, ikke et krav for å bruke resten.', links: [{ label: 'Utforsk funksjonene', href: '/nb-NO/#features' }] },
      { question: 'Hva er forskjellen på en sak og en samtale?', answer: 'En sak registrerer arbeidet og statusen; utførelsen skjer i en samtale. Samtalen kan klargjøre en isolert copy-on-write-worktree før en agentkjøring. På Windows bruker den klargjøringen en Git-worktree.', links: [{ label: 'Følg en eksempelflyt', href: '/nb-NO/#workflows' }] },
      { question: 'Hvor kjører agenter, og hva gjør serveren?', answer: 'Serveren eier arbeidsområdets database, legitimasjon, API-er og agentkjøring; skrivebords- og nettleserklienter viser og styrer det arbeidet. Valgfrie flåtearbeidere henter leide jobber og strømmer hendelser, men holder ikke databasen, legitimasjonen eller budsjettene.', links: [{ label: 'Les arkitekturveiledningen', href: '/manual/concepts/architecture/' }] },
      { question: 'Hvor mye kontroll har jeg over en agentkjøring?', answer: 'Hver samtale kan bruke Bare foreslå, Handle med godkjenning eller Handle fritt. Tillatelser og en sandkasse begrenser fortsatt lovlige handlinger; godkjenningsforespørsler uten en godkjenner avslås. Myke budsjettgrenser varsler, harde setter på pause, og kjøringer beholder en logg.', links: [{ label: 'Se kontrollene', href: '/nb-NO/#boundaries' }] },
      { question: 'Ansetter en Orchestrate-plan agenter automatisk?', answer: 'Nei. Orchestrate kan undersøke og foreslå roller, undersaker og en plan, men ansettelse venter på godkjenning. Plan Studio åpnes fra planraden i den opprinnelige samtalen; det å tildele en sak starter ikke en kjøring alene.', links: [{ label: 'Følg eksempelflyten', href: '/nb-NO/#workflows' }] },
      { question: 'Kan jeg kjøre agenter fra den parede telefonen?', answer: 'Den parede telefonen er en tynn klient for det samme serverstøttede arbeidsområdet, ikke en annen kjørevert. Skrivebord, nettleser og telefon viser den samme driften; agenter kjører på serveren eller på valgfrie leide flåtearbeidere.', links: [{ label: 'Se de tilkoblede flatene', href: '/nb-NO/#surfaces' }] },
      { question: 'Hvilke integrasjoner kan jeg bruke?', answer: 'Saksynk med Linear er implementert; Jira og ClickUp har ingen adaptere. Tilkoblede Google Calendar-hendelser er skrivebeskyttet, og svar på invitasjon finnes bare når kalenderen gir skrivetilgang. Slack-tråder kan kobles til samtaler, og tilkoblede forge-tjenester leverer pull requests og sjekker.', links: [{ label: 'Les håndboken', href: '/manual/' }] },
      { question: 'Når dukker møtenotater og tiltak opp?', answer: 'Direktetranskripsjonen kan skille talere mens det tas opp. Etter at du stopper, behandler oppsummeringsagenten møtet og lagrer notater, beslutninger og tiltak; opptak og behandling er ulike tilstander.', links: [{ label: 'Se dagen i sammenheng', href: '/nb-NO/#day' }] },
      { question: 'Er den offentlige demoen et ekte arbeidsområde?', answer: 'Den offentlige demoen er en egen, låst utgave med oppdiktede data og agenter som følger et manus. Postene og kjøringene er eksempler, ikke ditt eget arbeid.', links: [{ label: 'Utforsk livedemoen', href: '/demo' }] },
    ],
  },
  pilot: {
      controls: '3D-paraglider. Dra for å dreie visningen og styre. Venstre- og høyrepil svinger; opp- og nedpil vipper flyretningen opp eller ned. R nullstiller; mellomrom setter flygingen og vinden på pause eller fortsetter dem.',
    },
  install: {
    title: 'Gjør deg\nhjemme.', description: 'Neste utviklerdag kan starte her. Gratis og åpen kildekode.',
    mac: 'Apple Silicon · macOS 13+', windows: 'x64 · Windows 10+', linux: 'x86_64 · AppImage',
    release: 'Se versjoner', web: 'Åpne nettappen', phone: 'Åpne telefonfølgesvennen',
    webNote: 'Koble til en server du kjører selv.', phoneNote: 'Par telefonen med serveren din over et lukket relé.',
    selfHost: 'Vil du heller drifte selv?', server: 'Kjør en server uten grensesnitt', guide: 'Les hurtigstartguiden',
  },
  footer: { tagline: 'Et hjem for utviklerdagen din.', resources: 'Ressurser', source: 'Kildekode på GitHub', compare: 'Sammenlign', changelog: 'Endringslogg', about: 'Om', contact: 'Kontakt', privacy: 'Personvern', terms: 'Vilkår', licenses: 'Lisenser', acknowledgements: 'Anerkjennelser', made: 'Bygget i det åpne.', top: 'Tilbake til toppen' },
};
