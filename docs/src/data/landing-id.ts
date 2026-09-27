import type { LandingCopy } from "./landing-en";

export const id: LandingCopy = {
  meta: {
    title: "Control Center \\\\ Rumah untuk hari pengembangmu",
    description:
      "Satukan tiket, tinjauan kode, agen AI, rapat, dan pipeline. Ruang kerja gratis dan sumber terbuka untuk desktop, web, dan ponsel.",
    imageAlt: "Control Center, pekerjaan pengembangmu dalam satu ruang kerja.",
  },
  nav: {
    product: "Produk",
    workflows: "Alur kerja",
    features: "Fitur",
    docs: "Dokumentasi",
    demo: "Coba demo",
    download: "Unduh",
    menu: "Menu",
    primary: "Navigasi utama",
    mobile: "Navigasi seluler",
    home: "Beranda Control Center",
    skip: "Lewati ke isi",
    language: "Bahasa",
    appearance: "Tampilan",
    light: "Terang",
    dark: "Gelap",
    system: "Sistem",
  },
  hero: {
    line1: "Banyak bagian yang bergerak.",
    line2: "Satu Control Center.",
    description:
      "Rumah untuk kodemu, agenmu, tinjauan, dan segala hal lain yang mengisi hari seorang pengembang.",
    download: "Dapatkan Control Center",
    demo: "Jelajahi demo langsung",
    platforms: "macOS, Windows, Linux",
    web: "Juga di web dan ponsel",
  },
  media: {
    phone:
      "Pendamping ponsel menampilkan ruang kerja yang sama, persetujuan yang menunggu, dan status jalannya agen.",
  },
  tour: {
    label: "Jelajahi Control Center",
    previous: "Tampilan produk sebelumnya",
    next: "Tampilan produk berikutnya",
    play: "Putar tur",
    pause: "Jeda tur",
    expand: "Perbesar pratinjau",
    close: "Tutup pratinjau",
    preview: "Pratinjau produk",
    note: "Pandangan lebih dekat pada hari pengembangmu.",
    imageLanguage: "Tempat gambar atau video",
    stops: [
      {
        kind: "desk",
        label: "Harimu",
        title: "Mulai dari yang membutuhkanmu.",
        description:
          "Permintaan tinjauan, persetujuan, dan penghalang. Tindakan berikutnya, tanpa mencari di antara tab.",
        alt: "Kotak masuk Control Center mengelompokkan pull request menurut status tinjauan dan menampilkan penghalang sinkronisasi.",
      },
      {
        kind: "agents",
        label: "Agen",
        title: "Beri ruang agar kerja yang baik terjadi.",
        description:
          "Jalankan agen di worktree Git yang terisolasi. Ikuti alatnya, arahkan pekerjaan, dan simpan konteksnya.",
        alt: "Percakapan dengan agen di Control Center, dengan konteks tugas dan aktivitasnya.",
      },
      {
        kind: "review",
        label: "Tinjauan kode",
        title: "Baca perubahannya. Kenali ceritanya.",
        description:
          "Diff, diskusi, dan pemeriksaan tetap bersama. Terbitkan tinjauan dengan akunmu sendiri.",
        alt: "Tinjauan pull request di Control Center, dengan perubahan kode dan konteks tinjauan.",
      },
      {
        kind: "tickets",
        label: "Tiket",
        title: "Biarkan langkah berikutnya tetap terhubung.",
        description:
          "Ikuti prioritas dan kepemilikan, sinkronkan Linear, dan tautkan percakapan tempat pekerjaan terjadi.",
        alt: "Papan tiket Control Center dengan tugas yang dikelompokkan menurut status.",
      },
      {
        kind: "meetings",
        label: "Rapat",
        title: "Simpan keputusan setelah panggilan.",
        description:
          "Rekam dan transkripsikan di servermu. Saat rapat selesai, ada catatan dan tindakan.",
        alt: "Rapat di Control Center dengan transkrip dan informasi rapat.",
      },
      {
        kind: "pipelines",
        label: "Pipeline",
        title: "Jadikan pekerjaan yang berulang bisa diulang.",
        description:
          "Bangun alur, pilih pemicunya, dan ikuti setiap langkah jalannya.",
        alt: "Tampilan pipeline Control Center dengan langkah alur dan status jalannya.",
      },
    ],
  },
  integrations: {
    title: "Bawa alat yang sudah kamu pakai.",
    note: "Terhubung lewat servermu, bukan sebagai salinan lain dari harimu.",
  },
  grid: {
    title: "Alat yang akan kamu raih setiap hari.",
    description: "Kerjakan, tinjau yang berubah, dan simpan keputusannya.",
    more: "Baca dokumentasi",
    items: [
      {
        title: "Agen paralel",
        description:
          "Beri setiap tugas worktree Git yang terisolasi. Ikuti jalannya, arahkan agen, atau ambil alih tanpa mengganggu yang lain.",
        link: "Jalankan agen secara paralel",
        kind: "agents",
        href: "/manual/guides/parallel-agents/",
      },
      {
        title: "Tinjauan pull request",
        description:
          "Baca diff di samping diskusi dan pemeriksaan. Tambahkan tinjauan AI saat membantu, lalu terbitkan dengan akun forge-mu sendiri.",
        link: "Tinjau pull request",
        kind: "review",
        href: "/manual/guides/review-merge-pr/",
      },
      {
        title: "Tiket yang terhubung",
        description:
          "Sinkronkan Linear, tetapkan prioritas, dan tugaskan pekerjaan. Tautkan tiket ke percakapan tempat pekerjaan selesai.",
        link: "Kelola tiket",
        kind: "tickets",
        href: "/manual/guides/manage-tickets/",
      },
      {
        title: "Catatan rapat",
        description:
          "Rekam dan transkripsikan di servermu. Keputusan dan tindakan tetap ada setelah panggilan selesai.",
        link: "Rekam rapat",
        kind: "meetings",
        href: "/manual/guides/record-meeting/",
      },
      {
        title: "Pipeline yang bisa diulang",
        description:
          "Bangun alur sekali. Jalankan sesuai jadwal, dari peristiwa, atau dengan tangan, lalu periksa setiap langkah.",
        link: "Bangun pipeline",
        kind: "pipelines",
        href: "/manual/guides/create-pipeline/",
      },
      {
        title: "Beralih akun",
        description:
          "Pilih akun yang dapat digunakan tiap agen, lalu beralih di antaranya tanpa kehilangan konteks proses.",
        link: "Kelola penyedia model",
        kind: "accounts",
        href: "/manual/guides/adapters/",
        alt: "Editor kumpulan akun Control Center yang menampilkan akun yang tersedia untuk agen.",
      },
      {
        title: "Kuota penggunaan",
        description:
          "Periksa jatah penyedia dan waktu pengaturan ulang sebelum memulai proses berikutnya.",
        link: "Kelola biaya",
        kind: "quota",
        href: "/manual/guides/manage-costs/",
        alt: "Panel penggunaan Control Center yang menampilkan kuota penyedia dan waktu pengaturan ulang.",
      },
      {
        title: "Lanskap suara & fokus",
        description:
          "Jalankan sesi fokus dengan batas waktu, senyapkan notifikasi, dan sesuaikan lanskap suara yang mengiringinya.",
        link: "Gunakan mode fokus",
        kind: "focus",
        href: "/manual/guides/focus-mode/",
        alt: "Pengatur waktu fokus dan kontrol lanskap suara di Control Center.",
      },
      {
        title: "Pemantauan proses",
        description:
          "Pantau agen yang aktif dan periksa biaya proses, penggunaan token, serta latensi di ruang kerjamu.",
        link: "Periksa proses agen",
        kind: "observability",
        href: "/manual/guides/manage-costs/",
        alt: "Tampilan pemantauan Control Center yang menampilkan agen aktif dan wawasan proses.",
      },
      {
        title: "Editor keahlian & agen",
        description:
          "Edit keahlian ruang kerja dan atur model, instruksi, serta izin setiap agen.",
        link: "Kelola keahlian",
        kind: "editors",
        href: "/manual/guides/manage-skills/",
        alt: "Editor keahlian dan pengaturan agen di Control Center.",
      },
    ],
    supporting: [
      {
        title: "Satu kotak masuk",
        description:
          "Tinjauan, persetujuan, dan penghalang dalam satu antrean. Lompat ke tugas berikutnya dengan palet perintah.",
        href: "/manual/guides/triage-inbox/",
      },
      {
        title: "Cek dari ponsel",
        description:
          "Ikuti jalannya dan urus persetujuan tanpa kembali ke meja.",
        href: "/manual/concepts/remote-control/",
      },
    ],
  },
  workflow: {
    title: "Pegang benangnya.\nSampai terkirim.",
    description: "Pekerjaan berpindah antaralat. Konteksnya harus ikut.",
    label: "Alur yang terhubung",
    steps: [
      {
        title: "Mulai dari tiket.",
        text: "Tetapkan prioritas, sebut pemiliknya, dan tautkan percakapan. Tiket menyimpan catatannya.",
        kind: "tickets",
        label: "Maksud",
      },
      {
        title: "Beri pekerjaan ruangnya sendiri.",
        text: "Bahas rencana, siapkan worktree terisolasi, dan jalankan agen. Arahkan atau ambil alih saat perlu.",
        kind: "agents",
        label: "Pekerjaan",
      },
      {
        title: "Bawa hasilnya ke tinjauan.",
        text: "Baca perubahannya, ikuti diskusinya, dan terbitkan dengan akun forge-mu. Ceritanya tetap terhubung.",
        kind: "review",
        label: "Hasil",
      },
    ],
  },
  boundaries: {
    title: "Setujui push sebelum dijalankan.",
    description:
      "Letakkan push Git, penerbitan pull request, dan tindakan terjaga lainnya di balik persetujuan. Lihat apa yang akan dilakukan agen sebelum ada yang berubah.",
    media:
      "Jalan agen yang berhenti pada permintaan persetujuan push Git. Tunjukkan perintah yang diusulkan, direktori kerja, dan kontrol untuk menyetujui atau menolak.",
    note: "Tidak ada yang terhubung untuk menyetujui? Tindakan ditolak. Izin ditegakkan oleh servermu, bukan oleh prompt.",
    link: "Atur persetujuan tindakan",
  },
  surfaces: {
    title: "Meja adalah tempat.\nPekerjaan bukan.",
    description:
      "Mulai di desktop. Masuk dari peramban. Tetap dekat dari ponsel. Satu server menahan semuanya bersama.",
    desktop: "Desktop asli",
    web: "Di peramban",
    phone: "Pendamping ponsel",
    note: "Servermu memiliki data dan eksekusi. Perangkatmu tetap tersinkron.",
    link: "Temukan platformmu",
  },
  faq: {
    title: "Pertanyaan yang bagus.",
    description: "Beberapa hal yang perlu diketahui sebelum kamu menetap.",
    items: [
      {
        question: "Apakah Control Center hanya untuk agen AI?",
        answer:
          "Tidak. Control Center menempatkan tiket, pull request, percakapan, rapat, kalender, pipeline, agen, dan pembaca RSS pribadi dalam satu ruang kerja. Agen adalah bagian dari meja, bukan syarat untuk memakai yang lain.",
        links: [{ label: "Jelajahi fitur", href: "/id-ID/#features" }],
      },
      {
        question: "Apa beda tiket dan percakapan?",
        answer:
          "Tiket mencatat pekerjaan dan statusnya; eksekusi terjadi dalam percakapan. Percakapan dapat menyiapkan worktree terisolasi copy-on-write sebelum agen berjalan. Di Windows, persiapan itu memakai worktree Git.",
        links: [{ label: "Ikuti alur contoh", href: "/id-ID/#workflows" }],
      },
      {
        question: "Di mana agen berjalan, dan apa yang dilakukan server?",
        answer:
          "Server memiliki basis data ruang kerja, kredensial, API, dan eksekusi agen; klien desktop dan peramban menampilkan serta mengendalikan pekerjaan itu. Worker armada opsional mengambil pekerjaan sewaan dan mengalirkan peristiwa, tetapi tidak menyimpan basis data, kredensial, atau anggaran.",
        links: [
          {
            label: "Baca panduan arsitektur",
            href: "/manual/concepts/architecture/",
          },
        ],
      },
      {
        question: "Seberapa besar kendaliku atas jalannya agen?",
        answer:
          "Setiap percakapan dapat memakai Hanya usulkan, Bertindak dengan persetujuan, atau Bertindak bebas. Izin dan sandbox tetap membatasi tindakan yang boleh; permintaan persetujuan tanpa orang yang menyetujui ditolak. Batas anggaran lunak memperingatkan, batas keras menjeda, dan setiap jalan menyimpan log.",
        links: [{ label: "Lihat kendalinya", href: "/id-ID/#boundaries" }],
      },
      {
        question:
          "Apakah rencana Orchestrate mempekerjakan agen secara otomatis?",
        answer:
          "Tidak. Orchestrate dapat meneliti dan mengusulkan peran, tiket anak, dan sebuah rencana, tetapi perekrutan menunggu persetujuan. Plan Studio terbuka dari baris rencana di percakapan asal; menugaskan tiket saja tidak memulai jalan.",
        links: [{ label: "Ikuti alur contoh", href: "/id-ID/#workflows" }],
      },
      {
        question: "Bisakah aku menjalankan agen dari ponsel yang dipasangkan?",
        answer:
          "Ponsel yang dipasangkan adalah klien tipis untuk ruang kerja yang sama di server, bukan host eksekusi kedua. Desktop, peramban, dan ponsel menampilkan operasi yang sama; agen berjalan di server atau di worker armada sewaan yang opsional.",
        links: [
          { label: "Lihat permukaan yang terhubung", href: "/id-ID/#surfaces" },
        ],
      },
      {
        question: "Integrasi apa yang bisa kupakai?",
        answer:
          "Sinkronisasi tiket Linear sudah ada; Jira dan ClickUp tidak punya adaptor. Peristiwa Google Calendar yang terhubung hanya bisa dibaca, dan balasan undangan ada hanya jika kalender memberi izin menulis. Utas Slack dapat dijembatani ke percakapan, dan forge yang terhubung memasok pull request serta pemeriksaan.",
        links: [{ label: "Baca manual", href: "/manual/" }],
      },
      {
        question: "Kapan catatan rapat dan tindakan muncul?",
        answer:
          "Transkrip langsung dapat memisahkan pembicara saat merekam. Setelah kamu berhenti, agen ringkasan memproses rapat dan menyimpan catatan, keputusan, serta tindakan; perekaman dan pemrosesan adalah keadaan yang berbeda.",
        links: [{ label: "Lihat hari dalam konteksnya", href: "/id-ID/#day" }],
      },
      {
        question: "Apakah demo publik adalah ruang kerja sungguhan?",
        answer:
          "Demo publik adalah build terpisah yang dikunci, dengan data yang dikarang dan agen yang mengikuti naskah. Catatan dan jalannya adalah contoh, bukan pekerjaanmu.",
        links: [{ label: "Jelajahi demo langsung", href: "/demo" }],
      },
    ],
  },
  pilot: {
    controls:
      "Paraglider 3D. Seret untuk mengorbit tampilan dan mengendalikan arah. Panah kiri dan kanan membelokkan; panah atas dan bawah memiringkan arah terbang ke atas atau bawah. R mengatur ulang; Spasi menjeda atau melanjutkan penerbangan dan angin.",
  },
  install: {
    title: "Buat dirimu\nbetah.",
    description:
      "Hari pengembang berikutnya bisa dimulai di sini. Gratis dan sumber terbuka.",
    mac: "Apple Silicon · macOS 13+",
    windows: "x64 · Windows 10+",
    linux: "x86_64 · AppImage",
    release: "Lihat rilis",
    web: "Buka aplikasi web",
    phone: "Buka pendamping ponsel",
    webNote: "Hubungkan ke server yang kamu jalankan.",
    phoneNote: "Pasangkan ponsel dengan servermu lewat relai tertutup.",
    selfHost: "Lebih suka menghosting sendiri?",
    server: "Jalankan server tanpa antarmuka",
    guide: "Baca panduan mulai cepat",
  },
  footer: {
    tagline: "Rumah untuk hari pengembangmu.",
    resources: "Sumber daya",
    source: "Sumber di GitHub",
    compare: "Bandingkan",
    changelog: "Catatan perubahan",
    about: "Tentang",
    contact: "Kontak",
    privacy: "Privasi",
    terms: "Ketentuan",
    licenses: "Lisensi",
    acknowledgements: "Ucapan terima kasih",
    made: "Dibangun secara terbuka.",
    top: "Kembali ke atas",
  },
};
