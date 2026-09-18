// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Kembali';

  @override
  String get cancel => 'Batal';

  @override
  String get retry => 'Coba lagi';

  @override
  String get tryAgain => 'Coba lagi';

  @override
  String get settings => 'Pengaturan';

  @override
  String get refresh => 'Segarkan';

  @override
  String get approve => 'Setujui';

  @override
  String get deny => 'Tolak';

  @override
  String get continueLabel => 'Lanjutkan';

  @override
  String get agentQuestionHeader => 'Pertanyaan untuk Anda';

  @override
  String get agentQuestionAnsweredLabel => 'Dijawab';

  @override
  String get agentQuestionSkip => 'Lewati';

  @override
  String get agentQuestionSkippedLabel => 'Dilewati';

  @override
  String get agentQuestionFreeformHint => 'Ketik jawaban Anda…';

  @override
  String get agentApprovalRequired => 'Persetujuan diperlukan';

  @override
  String get approveAndRemember => 'Setujui selama 8 jam';

  @override
  String get decline => 'Tolak';

  @override
  String get confirm => 'Konfirmasi';

  @override
  String get send => 'Kirim';

  @override
  String get close => 'Tutup';

  @override
  String get expand => 'Perluas';

  @override
  String get zoomIn => 'Perbesar';

  @override
  String get zoomOut => 'Perkecil';

  @override
  String get resetZoom => 'Reset zoom';

  @override
  String get scanQrPrompt =>
      'Pindai kode QR dari Mac Anda untuk menyandingkan ponsel ini.';

  @override
  String get scanQrHelp =>
      'Buka kamera dan arahkan ke QR yang ditampilkan di Control Center di Mac Anda. Ponsel ini terhubung langsung ke Mac Anda lewat tautan privat.';

  @override
  String get connectingToMac => 'Menghubungkan ke Mac Anda…';

  @override
  String get connectingDetail => 'Menjalin tautan langsung yang aman.';

  @override
  String get identityChangedTitle => 'Identitas server berubah';

  @override
  String get identityChangedBody =>
      'Server ini tidak lagi cocok dengan identitas yang disimpan saat penyandingan. Itu bisa berarti server diinstal ulang — atau ada yang menyadap koneksi. Demi keamanan, perangkat ini tidak akan terhubung. Hapus penyandingan, lalu pindai kode QR baru dari Mac Anda untuk menyandingkan lagi.';

  @override
  String get removePairing => 'Hapus penyandingan';

  @override
  String get couldntConnect => 'Tidak dapat terhubung';

  @override
  String get pendingPairingTitle => 'Hubungkan ke server ini?';

  @override
  String get pendingPairingBody =>
      'Sebuah tautan meminta Control Center untuk menyandingkan dengan server ini. Lanjutkan hanya jika Anda yang memulainya.';

  @override
  String get connect => 'Hubungkan';

  @override
  String get failureNotPaired =>
      'Belum disandingkan — pindai kode QR dari Mac Anda';

  @override
  String get failureUnreachable =>
      'Tidak dapat menjangkau server di jalur mana pun — pastikan server berjalan, atau coba jaringan yang sama';

  @override
  String get failureIdentityChanged =>
      'Identitas server berubah — jika diinstal ulang, sandingkan ulang perangkat ini';

  @override
  String get failureAuthRejected =>
      'Server menolak perangkat ini — sandingkan ulang dari Mac Anda';

  @override
  String get failureUnknown =>
      'Tidak dapat terhubung — ketuk untuk mencoba lagi';

  @override
  String get statusConnected => 'Terhubung';

  @override
  String get statusConnecting => 'Menghubungkan';

  @override
  String get statusOffline => 'Luring';

  @override
  String get statusIdentityMismatch => 'Identitas tidak cocok';

  @override
  String get statusNotPaired => 'Belum disandingkan';

  @override
  String get statusConfirmPairing => 'Konfirmasi penyandingan';

  @override
  String get connectionFailed => 'Koneksi gagal';

  @override
  String get identityMismatchBanner =>
      'Identitas server berubah — koneksi dihentikan. Sandingkan ulang perangkat ini untuk melanjutkan.';

  @override
  String get tabInbox => 'Kotak masuk';

  @override
  String get tabTickets => 'Tiket';

  @override
  String get tabChat => 'Obrolan';

  @override
  String get tabPrs => 'PR';

  @override
  String get tabCalendar => 'Kalender';

  @override
  String get tabNews => 'Berita';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count menunggu';
  }

  @override
  String get updateAvailable => 'Control Center baru tersedia';

  @override
  String get appearance => 'Tampilan';

  @override
  String get language => 'Bahasa';

  @override
  String get device => 'Perangkat';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get languageSystem => 'Sistem';

  @override
  String get disconnectTapAgain =>
      'Ketuk lagi untuk memutus perangkat ini dari Mac Anda';

  @override
  String get disconnectDevice => 'Putuskan perangkat ini';

  @override
  String get disconnect => 'Putuskan';

  @override
  String get chooseWorkspace => 'Pilih ruang kerja';

  @override
  String get workspaces => 'Ruang kerja';

  @override
  String get workspacesLoadFailed => 'Tidak dapat memuat ruang kerja';

  @override
  String get noWorkspacesYet => 'Belum ada ruang kerja';

  @override
  String selectWorkspace(String name) {
    return 'Pilih $name';
  }

  @override
  String get inboxLoadFailed => 'Tidak dapat memuat kotak masuk Anda';

  @override
  String get allCaughtUp => 'Semua sudah tertangani';

  @override
  String get inboxNoForgeAccount =>
      'Tidak ada akun forge yang terhubung di server, jadi pull request belum dapat dikaitkan ke Anda.';

  @override
  String get inboxNothingWaiting =>
      'Tidak ada yang terblokir dan tidak ada pull request yang menunggu Anda.';

  @override
  String get blocked => 'Diblokir';

  @override
  String get sectionNeedsYourReview => 'Perlu tinjauan Anda';

  @override
  String get sectionReturnedToYou => 'Dikembalikan kepada Anda';

  @override
  String get sectionApprovedAndReady => 'Disetujui dan siap';

  @override
  String get sectionYourDrafts => 'Draf Anda';

  @override
  String get sectionWaitingForReviewers => 'Menunggu peninjau';

  @override
  String get sectionMergingAndMerged =>
      'Sedang digabung dan baru saja digabung';

  @override
  String get sectionWaitingForAuthor => 'Menunggu penulis';

  @override
  String waitingAgo(String ago) {
    return 'menunggu $ago';
  }

  @override
  String get openConversation => 'Buka percakapan';

  @override
  String get calendarLoadFailed => 'Tidak dapat memuat kalender Anda';

  @override
  String get nothingScheduled => 'Tidak ada jadwal';

  @override
  String get calendarEmptyDescription =>
      'Acara dari kalender yang terhubung muncul di sini.';

  @override
  String get agenda => 'Agenda';

  @override
  String get syncCalendarsNow => 'Sinkronkan kalender sekarang';

  @override
  String get event => 'Acara';

  @override
  String get eventNotFound => 'Acara tidak ditemukan';

  @override
  String get eventNotFoundDescription =>
      'Mungkin di luar jendela agenda, atau sudah dihapus di sumbernya.';

  @override
  String get joinMeeting => 'Gabung rapat';

  @override
  String get join => 'Gabung';

  @override
  String attendeesCount(int count) {
    return 'Peserta ($count)';
  }

  @override
  String get details => 'Detail';

  @override
  String get allDay => 'Sepanjang hari';

  @override
  String get happeningNow => 'Sedang berlangsung';

  @override
  String inDuration(String duration) {
    return 'Dalam $duration';
  }

  @override
  String eventTimeRange(String start, String end, String duration) {
    return '$start – $end · $duration';
  }

  @override
  String upNextSemantic(String lead, String title) {
    return '$lead: $title';
  }

  @override
  String get attendeeAccepted => 'diterima';

  @override
  String get attendeeDeclined => 'ditolak';

  @override
  String get attendeeMaybe => 'mungkin';

  @override
  String get attendeeNoReply => 'belum dibalas';

  @override
  String get organizer => 'penyelenggara';

  @override
  String get calendarNoAccounts =>
      'Tidak ada kalender yang terhubung untuk ruang kerja ini. Hubungkan dari aplikasi desktop — masuk menyimpan tokennya di server.';

  @override
  String get calendarReauthNeeded =>
      'Akun kalender perlu dihubungkan ulang — yang Anda lihat di bawah mungkin kedaluwarsa. Hubungkan ulang dari aplikasi desktop.';

  @override
  String get spacesLoadFailed => 'Tidak dapat memuat ruang';

  @override
  String get noSpaces => 'Tidak ada ruang';

  @override
  String get spacesEmptyDescription =>
      'Ruang di ruang kerja ini muncul di sini.';

  @override
  String get thread => 'Utas';

  @override
  String get agentWorking => 'Agen sedang bekerja';

  @override
  String get messagesLoadFailed => 'Tidak dapat memuat pesan';

  @override
  String get noMessagesYet => 'Belum ada pesan';

  @override
  String get noMessagesDescription => 'Kirim pesan untuk memulai percakapan.';

  @override
  String get agentResponding => 'Agen merespons';

  @override
  String get agentFinished => 'Agen selesai';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names terlalu besar untuk dikirim dari sini.',
      one: '$names terlalu besar untuk dikirim dari sini.',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names terlalu besar untuk dikirim lewat relay dari sini.',
      one: '$names terlalu besar untuk dikirim lewat relay dari sini.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'Tidak dapat mengunggah lampiran. Coba lagi.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lampiran tidak dapat diunggah dan dikecualikan.',
      one: '1 lampiran tidak dapat diunggah dan dikecualikan.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Rekan tim';

  @override
  String get agent => 'Agen';

  @override
  String get attachFile => 'Lampirkan file';

  @override
  String get messageHint => 'Pesan';

  @override
  String removeAttachment(String name) {
    return 'Hapus $name';
  }

  @override
  String get articlesLoadFailed => 'Artikel tidak dapat dimuat';

  @override
  String get noArticles => 'Tidak ada artikel';

  @override
  String get articlesEmptyDescription =>
      'Artikel baru muncul di sini saat feed diperbarui.';

  @override
  String get unread => 'Belum dibaca';

  @override
  String get allFeeds => 'Semua feed';

  @override
  String get save => 'Simpan';

  @override
  String get unsave => 'Batal simpan';

  @override
  String get readFullArticle => 'Baca artikel lengkap';

  @override
  String get ticketsLoadFailed => 'Tiket tidak dapat dimuat';

  @override
  String get noTickets => 'Tidak ada tiket';

  @override
  String get ticketsEmptyDescription =>
      'Tiket di workspace ini muncul di sini.';

  @override
  String get all => 'Semua';

  @override
  String get ticket => 'Tiket';

  @override
  String get ticketLoadFailed => 'Tiket tidak dapat dimuat';

  @override
  String assignedTo(String name) {
    return 'Ditugaskan ke $name';
  }

  @override
  String get openInBrowser => 'Buka di browser';

  @override
  String get status => 'Status';

  @override
  String get assign => 'Tugaskan';

  @override
  String get reassign => 'Tugaskan ulang';

  @override
  String get noAgents => 'Tidak ada agen';

  @override
  String get noAgentsDescription => 'Tugaskan agen dari workspace ini.';

  @override
  String get statusOpen => 'Terbuka';

  @override
  String get statusInProgress => 'Sedang dikerjakan';

  @override
  String get statusBlocked => 'Terblokir';

  @override
  String get statusInReview => 'Sedang ditinjau';

  @override
  String get statusDone => 'Selesai';

  @override
  String get statusBacklog => 'Backlog';

  @override
  String get lensNeedsMe => 'Butuh saya';

  @override
  String get lensMine => 'Milik saya';

  @override
  String get prsLoadFailed => 'Pull request tidak dapat dimuat';

  @override
  String get noOpenPullRequests => 'Tidak ada pull request yang terbuka';

  @override
  String get nothingWaitingOnReview => 'Tidak ada yang menunggu tinjauan Anda';

  @override
  String get noOwnOpenPullRequests => 'Anda tidak punya pull request terbuka';

  @override
  String get nothingBlocked => 'Tidak ada yang terblokir';

  @override
  String get prsEmptyDescription =>
      'Pull request dari repo workspace ini muncul di sini.';

  @override
  String get refreshPullRequests => 'Segarkan pull request';

  @override
  String get noForgeConnected =>
      'Tidak ada forge yang terhubung di server, jadi pull request tidak dapat diambil. Hubungkan dari aplikasi desktop.';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repo tidak dapat dibaca.',
      one: '1 repo tidak dapat dibaca.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'Tidak dapat dibaca: $names';
  }

  @override
  String get installationSuspendedTitle => 'Instalasi GitHub App ditangguhkan';

  @override
  String installationSuspendedBody(String names) {
    return 'Menampilkan data terakhir yang diketahui untuk $names. Lanjutkan instalasi di GitHub, atau hubungkan token yang memiliki akses.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'Instalasi GitHub App ditangguhkan. Menampilkan data terakhir yang diketahui untuk $names. Lanjutkan instalasi di GitHub, atau hubungkan token yang memiliki akses.';
  }

  @override
  String get draft => 'Draf';

  @override
  String get merged => 'Digabungkan';

  @override
  String get closed => 'Ditutup';

  @override
  String get open => 'Terbuka';

  @override
  String get approved => 'Disetujui';

  @override
  String get changesRequested => 'Perubahan diminta';

  @override
  String get reviewRequired => 'Perlu tinjauan';

  @override
  String get checksPassing => 'Pemeriksaan lulus';

  @override
  String get checksFailing => 'Pemeriksaan gagal';

  @override
  String get checksRunning => 'Pemeriksaan berjalan';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'Pull request ini tidak dapat dimuat';

  @override
  String get openOnForge => 'Buka di forge';

  @override
  String get requestChangesNeedsComment =>
      'Tambahkan komentar yang menjelaskan apa yang perlu diubah.';

  @override
  String get conversation => 'Percakapan';

  @override
  String get files => 'File';

  @override
  String get checks => 'Pemeriksaan';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commit',
      one: '1 commit',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => 'Konflik';

  @override
  String get reviewers => 'Peninjau';

  @override
  String get noDescriptionNoComments => 'Belum ada deskripsi maupun komentar.';

  @override
  String get noChangedFiles => 'Tidak ada file yang berubah.';

  @override
  String get noChecksReported =>
      'Tidak ada pemeriksaan yang dilaporkan untuk commit head.';

  @override
  String get reviewCommentHint => 'Tulis komentar tinjauan…';

  @override
  String get comment => 'Komentar';

  @override
  String get commentPosted => 'Komentar terkirim';

  @override
  String get request => 'Minta perubahan';

  @override
  String get squashAndMerge => 'Squash dan gabungkan';

  @override
  String noActionsAvailable(String status) {
    return '$status — tidak ada tindakan.';
  }

  @override
  String get reviewApproved => 'disetujui';

  @override
  String get reviewRequestedChanges => 'meminta perubahan';

  @override
  String get reviewCommented => 'ditinjau';

  @override
  String get reviewPending => 'tertunda';

  @override
  String get unknownAuthor => 'tidak diketahui';

  @override
  String hideDiffFor(String file) {
    return 'Sembunyikan diff $file';
  }

  @override
  String showDiffFor(String file) {
    return 'Tampilkan diff $file';
  }

  @override
  String get checkRunning => 'berjalan';

  @override
  String get checkPassed => 'lulus';

  @override
  String get checkFailed => 'gagal';

  @override
  String get checkCancelled => 'dibatalkan';

  @override
  String get checkSkipped => 'dilewati';

  @override
  String labelWithDuration(String label, String duration) {
    return '$label · $duration';
  }

  @override
  String checkSemanticLabel(String name, String state) {
    return '$name, $state';
  }

  @override
  String get noTextDiff =>
      'Tidak ada diff teks untuk file ini — file biner, atau terlalu besar untuk dikembalikan forge.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tampilkan $count baris yang tersisa',
      one: 'Tampilkan baris yang tersisa',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count baris tidak berubah',
      one: '1 baris tidak berubah',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'Lompat ke terbaru';

  @override
  String get streaming => 'Streaming';

  @override
  String get working => 'Sedang bekerja';

  @override
  String get input => 'Input';

  @override
  String get output => 'Output';

  @override
  String get now => 'baru saja';

  @override
  String agoMinutes(int count) {
    return '${count}m';
  }

  @override
  String agoHours(int count) {
    return '${count}h';
  }

  @override
  String agoDays(int count) {
    return '${count}d';
  }

  @override
  String get today => 'Hari ini';

  @override
  String get tomorrow => 'Besok';

  @override
  String get yesterday => 'Kemarin';

  @override
  String durationMinutes(int count) {
    return '${count}m';
  }

  @override
  String durationHours(int count) {
    return '${count}h';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }
}
