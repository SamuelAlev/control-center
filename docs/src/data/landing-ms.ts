import type { LandingCopy } from "./landing-en";

export const ms: LandingCopy = {
  meta: {
    title: "Control Center \\\\ Tempat untuk hari pembangun anda",
    description:
      "Kumpulkan tiket, semakan kod, ejen AI, mesyuarat dan saluran paip. Ruang kerja percuma dan sumber terbuka untuk desktop, web dan telefon.",
    imageAlt: "Control Center, kerja pembangun anda dalam satu ruang kerja.",
  },
  nav: {
    product: "Produk",
    workflows: "Aliran kerja",
    features: "Ciri",
    docs: "Dokumentasi",
    demo: "Cuba demo",
    download: "Muat turun",
    menu: "Menu",
    primary: "Navigasi utama",
    mobile: "Navigasi mudah alih",
    home: "Laman utama Control Center",
    skip: "Langkau ke kandungan",
    language: "Bahasa",
    appearance: "Penampilan",
    light: "Cerah",
    dark: "Gelap",
    system: "Sistem",
  },
  hero: {
    line1: "Banyak bahagian yang bergerak.",
    line2: "Satu Control Center.",
    description:
      "Tempat untuk kod, ejen, semakan dan segala yang lain yang mengisi hari seorang pembangun.",
    download: "Dapatkan Control Center",
    demo: "Terokai demo langsung",
    platforms: "macOS, Windows, Linux",
    web: "Juga di web dan telefon",
  },
  media: {
    phone:
      "Teman telefon memaparkan ruang kerja yang sama, kelulusan yang menunggu dan status larian ejen.",
  },
  tour: {
    label: "Terokai Control Center",
    previous: "Paparan produk sebelumnya",
    next: "Paparan produk seterusnya",
    play: "Mainkan lawatan",
    pause: "Jeda lawatan",
    videoPlay: "Mainkan pratonton",
    videoPause: "Jeda pratonton",
    expand: "Kembangkan pratonton",
    preview: "Pratonton produk",
    close: "Tutup pratonton",
    note: "Pandangan lebih dekat pada hari pembangun anda.",
    imageLanguage: "Ruang untuk imej atau video",
    stops: [
      {
        kind: "agents",
        label: "Ejen",
        title: "Beri ruang supaya kerja yang baik berlaku.",
        description:
          "Jalankan ejen dalam worktree Git yang terasing. Ikuti alat mereka, pandu kerja dan simpan konteks.",
        alt: "Perbualan dengan ejen dalam Control Center, dengan konteks tugas dan aktiviti.",
      },
      {
        kind: "desk",
        label: "Peti masuk",
        title: "Mulakan dengan yang memerlukan anda.",
        description:
          "Permintaan semakan, kelulusan dan halangan. Tindakan seterusnya, tanpa mencari dalam tab.",
        alt: "Peti masuk Control Center mengumpulkan pull request mengikut status semakan dan memaparkan halangan penyegerakan.",
      },
      {
        kind: "review",
        label: "Semakan kod",
        title: "Baca perubahan. Kenali ceritanya.",
        description:
          "Diff, perbincangan dan semakan kekal bersama. Terbitkan semakan dengan akaun anda sendiri.",
        alt: "Semakan pull request dalam Control Center, dengan perubahan kod dan konteks semakan.",
      },
      {
        kind: "tickets",
        label: "Tiket",
        title: "Kekalkan langkah seterusnya berhubung.",
        description:
          "Jejaki keutamaan dan pemilikan, segerakkan Linear dan pautkan perbualan tempat kerja berlaku.",
        alt: "Papan tiket Control Center dengan tugas dikumpulkan mengikut status.",
      },
      {
        kind: "meetings",
        label: "Mesyuarat",
        title: "Simpan keputusan selepas panggilan.",
        description:
          "Rakam dan transkrip pada pelayan anda. Apabila mesyuarat tamat, anda ada nota dan tindakan.",
        alt: "Mesyuarat dalam Control Center dengan transkrip dan maklumat mesyuarat.",
      },
      {
        kind: "pipelines",
        label: "Saluran paip",
        title: "Jadikan kerja yang berulang boleh diulang.",
        description:
          "Bina aliran, pilih pencetusnya dan ikuti setiap langkah larian.",
        alt: "Paparan saluran paip Control Center dengan langkah aliran dan status larian.",
      },
    ],
  },
  integrations: {
    title: "Bawa alat yang sudah anda gunakan.",
    note: "Disambungkan melalui pelayan anda, bukan sebagai salinan lain hari anda.",
  },
  grid: {
    title: "Alat yang anda hulur tangan setiap hari.",
    description: "Buat kerja, semak yang berubah dan simpan keputusan.",
    more: "Baca dokumentasi",
    items: [
      {
        title: "Ejen selari",
        description:
          "Beri setiap tugas worktree Git yang terasing. Ikuti larian, pandu ejen atau ambil alih tanpa mengganggu yang lain.",
        link: "Jalankan ejen secara selari",
        kind: "agents",
        href: "/manual/guides/parallel-agents/",
      },
      {
        title: "Semakan pull request",
        description:
          "Baca diff di sisi perbincangan dan semakan. Tambah semakan AI apabila ia membantu, kemudian terbitkan dengan akaun forge anda sendiri.",
        link: "Semak pull request",
        kind: "review",
        href: "/manual/guides/review-merge-pr/",
      },
      {
        title: "Tiket yang berhubung",
        description:
          "Segerakkan Linear, tetapkan keutamaan dan tugaskan kerja. Pautkan tiket pada perbualan tempat ia diselesaikan.",
        link: "Urus tiket",
        kind: "tickets",
        href: "/manual/guides/manage-tickets/",
      },
      {
        title: "Nota mesyuarat",
        description:
          "Rakam dan transkrip pada pelayan anda. Keputusan dan tindakan kekal selepas panggilan tamat.",
        link: "Rakam mesyuarat",
        kind: "meetings",
        href: "/manual/guides/record-meeting/",
      },
      {
        title: "Saluran paip yang boleh diulang",
        description:
          "Bina aliran sekali. Jalankannya mengikut jadual, daripada peristiwa atau dengan tangan, dan periksa setiap langkah.",
        link: "Bina saluran paip",
        kind: "pipelines",
        href: "/manual/guides/create-pipeline/",
      },
      {
        title: "Tukar akaun",
        description:
          "Pilih akaun yang boleh digunakan oleh setiap ejen, kemudian tukar antaranya tanpa kehilangan konteks larian.",
        link: "Urus penyedia model",
        kind: "accounts",
        href: "/manual/guides/adapters/",
        alt: "Penyunting kumpulan akaun Control Center yang menunjukkan akaun yang layak untuk ejen.",
      },
      {
        title: "Kuota penggunaan",
        description:
          "Semak peruntukan penyedia dan masa tetapan semula sebelum memulakan larian seterusnya.",
        link: "Urus kos",
        kind: "quota",
        href: "/manual/guides/manage-costs/",
        alt: "Panel penggunaan Control Center yang menunjukkan kuota penyedia dan masa tetapan semula.",
      },
      {
        title: "Landskap bunyi & fokus",
        description:
          "Jalankan sesi fokus bermasa, senyapkan pemberitahuan dan laraskan landskap bunyi yang mengiringinya.",
        link: "Gunakan mod fokus",
        kind: "focus",
        href: "/manual/guides/focus-mode/",
        alt: "Pemasa fokus dan kawalan landskap bunyi dalam Control Center.",
      },
      {
        title: "Pemantauan larian",
        description:
          "Ikuti ejen yang aktif dan semak kos larian, penggunaan token serta kependaman dalam ruang kerja anda.",
        link: "Periksa larian ejen",
        kind: "observability",
        href: "/manual/guides/manage-costs/",
        alt: "Paparan pemantauan Control Center yang menunjukkan ejen aktif dan maklumat larian.",
      },
      {
        title: "Penyunting kemahiran & ejen",
        description:
          "Sunting kemahiran ruang kerja dan tetapkan model, arahan serta keizinan setiap ejen.",
        link: "Urus kemahiran",
        kind: "editors",
        href: "/manual/guides/manage-skills/",
        alt: "Penyunting kemahiran dan tetapan ejen dalam Control Center.",
      },
    ],
    supporting: [
      {
        title: "Satu peti masuk",
        description:
          "Semakan, kelulusan dan halangan dalam satu barisan. Lompat ke tugas seterusnya dengan palet arahan.",
        href: "/manual/guides/triage-inbox/",
      },
      {
        title: "Semak dari telefon",
        description: "Ikuti larian dan urus kelulusan tanpa kembali ke meja.",
        href: "/manual/concepts/remote-control/",
      },
    ],
  },
  workflow: {
    title: "Pegang benangnya.\nSehingga ia dihantar.",
    description: "Kerja bergerak antara alat. Konteksnya patut ikut bersama.",
    label: "Aliran yang berhubung",
    steps: [
      {
        title: "Mulakan dengan tiket.",
        text: "Tetapkan keutamaan, namakan pemilik dan pautkan perbualan. Tiket menyimpan rekod.",
        kind: "tickets",
        label: "Niat",
      },
      {
        title: "Beri kerja ruangnya sendiri.",
        text: "Bincangkan rancangan, sediakan worktree terasing dan jalankan ejen. Pandu atau ambil alih apabila perlu.",
        kind: "agents",
        label: "Kerja",
      },
      {
        title: "Bawa hasil ke semakan.",
        text: "Baca perubahan, ikuti perbincangan dan terbitkan dengan akaun forge anda. Ceritanya kekal berhubung.",
        kind: "review",
        label: "Hasil",
      },
    ],
  },
  boundaries: {
    title: "Luluskan push sebelum ia dijalankan.",
    description:
      "Letakkan push Git, penerbitan pull request dan tindakan terjaga yang lain di sebalik kelulusan. Lihat apa yang ejen hendak lakukan sebelum sesuatu berubah.",
    media:
      "Larian ejen yang berhenti pada permintaan kelulusan push Git. Tunjukkan arahan yang dicadangkan, direktori kerja dan kawalan untuk meluluskan atau menolak.",
    note: "Tiada siapa yang bersambung untuk meluluskan? Tindakan ditolak. Kebenaran dikuatkuasakan oleh pelayan anda, bukan oleh gesaan.",
    link: "Konfigurasikan kelulusan tindakan",
  },
  surfaces: {
    title: "Meja ialah tempat.\nKerja bukan.",
    description:
      "Mulakan di desktop. Masuk dari pelayar. Kekal dekat dari telefon. Satu pelayan memegang operasi bersama.",
    desktop: "Desktop asli",
    web: "Dalam pelayar",
    phone: "Teman telefon",
    note: "Pelayan anda memiliki data dan pelaksanaan. Peranti anda kekal segerak.",
    link: "Cari platform anda",
  },
  faq: {
    title: "Soalan yang baik.",
    description: "Beberapa perkara untuk diketahui sebelum anda menetap.",
    items: [
      {
        question: "Adakah Control Center hanya untuk ejen AI?",
        answer:
          "Tidak. Control Center meletakkan tiket, pull request, perbualan, mesyuarat, kalendar, saluran paip, ejen dan pembaca RSS peribadi dalam satu ruang kerja. Ejen ialah sebahagian daripada meja, bukan syarat untuk menggunakan yang lain.",
        links: [{ label: "Terokai ciri", href: "/ms-MY/#features" }],
      },
      {
        question: "Apakah bezanya tiket dengan perbualan?",
        answer:
          "Tiket merekodkan kerja dan statusnya; pelaksanaan berlaku dalam perbualan. Perbualan boleh menyediakan worktree terasing salin-semasa-tulis sebelum larian ejen. Pada Windows, penyediaan itu menggunakan worktree Git.",
        links: [{ label: "Ikuti aliran contoh", href: "/ms-MY/#workflows" }],
      },
      {
        question:
          "Di manakah ejen berjalan, dan apakah yang dilakukan pelayan?",
        answer:
          "Pelayan memiliki pangkalan data ruang kerja, kelayakan, API dan pelaksanaan ejen; klien desktop dan pelayar memaparkan serta mengawal kerja itu. Pekerja armada pilihan menarik kerja pajak dan menstrim peristiwa, tetapi tidak memegang pangkalan data, kelayakan atau belanjawan.",
        links: [
          {
            label: "Baca panduan seni bina",
            href: "/manual/concepts/architecture/",
          },
        ],
      },
      {
        question: "Berapa banyak kawalan saya terhadap larian ejen?",
        answer:
          "Setiap perbualan boleh menggunakan Cadang sahaja, Bertindak dengan kelulusan atau Bertindak bebas. Kebenaran dan kotak pasir masih mengikat tindakan yang dibenarkan; permintaan kelulusan tanpa pelulus ditolak. Had belanjawan lembut memberi amaran, had keras menjeda, dan larian menyimpan log.",
        links: [{ label: "Lihat kawalan", href: "/ms-MY/#boundaries" }],
      },
      {
        question:
          "Adakah rancangan Orchestrate mengambil ejen secara automatik?",
        answer:
          "Tidak. Orchestrate boleh menyelidik dan mencadangkan peranan, tiket anak dan rancangan, tetapi pengambilan menunggu kelulusan. Plan Studio dibuka daripada baris rancangan dalam perbualan asal; menugaskan tiket semata-mata tidak memulakan larian.",
        links: [{ label: "Ikuti aliran contoh", href: "/ms-MY/#workflows" }],
      },
      {
        question:
          "Bolehkah saya menjalankan ejen dari telefon yang dipasangkan?",
        answer:
          "Telefon yang dipasangkan ialah klien nipis untuk ruang kerja yang sama pada pelayan, bukan hos pelaksanaan kedua. Desktop, pelayar dan telefon memaparkan operasi yang sama; ejen berjalan pada pelayan atau pada pekerja armada pajak yang pilihan.",
        links: [
          {
            label: "Lihat permukaan yang bersambung",
            href: "/ms-MY/#surfaces",
          },
        ],
      },
      {
        question: "Integrasi manakah yang boleh saya gunakan?",
        answer:
          "Penyegerakan tiket Linear telah dilaksanakan; Jira dan ClickUp tidak mempunyai penyesuai. Peristiwa Google Calendar yang disambungkan adalah baca sahaja, dan jawapan jemputan hanya ada apabila kalendar memberi kebenaran menulis. Benang Slack boleh dijembatani ke perbualan, dan forge yang disambungkan membekalkan pull request serta semakan.",
        links: [{ label: "Baca manual", href: "/manual/" }],
      },
      {
        question: "Bilakah nota mesyuarat dan tindakan muncul?",
        answer:
          "Transkrip langsung boleh memisahkan penutur semasa rakaman. Selepas anda berhenti, ejen ringkasan memproses mesyuarat dan menyimpan nota, keputusan serta tindakan; rakaman dan pemprosesan ialah keadaan yang berbeza.",
        links: [{ label: "Lihat hari dalam konteks", href: "/ms-MY/#day" }],
      },
      {
        question: "Adakah demo awam ruang kerja sebenar?",
        answer:
          "Demo awam ialah binaan berasingan yang dikunci, dengan data rekaan dan ejen yang mengikut skrip. Rekod dan lariannya ialah contoh, bukan kerja anda.",
        links: [{ label: "Terokai demo langsung", href: "/demo" }],
      },
    ],
  },
  pilot: {
    controls:
      "Paraglider 3D. Seret untuk mengorbit pandangan dan mengemudi. Anak panah kiri dan kanan membelok; anak panah atas dan bawah mencondongkan arah penerbangan ke atas atau bawah. R menetapkan semula; Space menjeda atau menyambung penerbangan dan angin.",
  },
  install: {
    title: "Buat diri\nselesa.",
    description:
      "Hari pembangun anda yang seterusnya boleh bermula di sini. Percuma dan sumber terbuka.",
    mac: "Apple Silicon · macOS 13+",
    windows: "x64 · Windows 10+",
    linux: "x86_64 · AppImage",
    release: "Lihat keluaran",
    web: "Buka aplikasi web",
    phone: "Buka teman telefon",
    webNote: "Sambung ke pelayan yang anda jalankan.",
    phoneNote:
      "Pasangkan telefon dengan pelayan anda melalui geganti tertutup.",
    selfHost: "Lebih suka mengehos sendiri?",
    server: "Jalankan pelayan tanpa antara muka",
    guide: "Baca panduan mula pantas",
  },
  footer: {
    tagline: "Tempat untuk hari pembangun anda.",
    resources: "Sumber",
    source: "Sumber di GitHub",
    compare: "Bandingkan",
    changelog: "Log perubahan",
    about: "Perihal",
    contact: "Hubungi",
    privacy: "Privasi",
    terms: "Terma",
    licenses: "Lesen",
    acknowledgements: "Penghargaan",
    made: "Dibina secara terbuka.",
    top: "Kembali ke atas",
  },
};
