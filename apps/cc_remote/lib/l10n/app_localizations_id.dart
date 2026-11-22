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
  String get copyCommand => 'Salin perintah';

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
      'Pindai kode QR dari Control Center untuk menyandingkan ponsel ini.';

  @override
  String get scanQrHelp =>
      'Buka kamera dan arahkan ke QR yang ditampilkan di Control Center. Ponsel ini terhubung langsung lewat tautan privat.';

  @override
  String get connectingToMac => 'Menghubungkan ke Control Center…';

  @override
  String get connectingDetail => 'Menjalin tautan langsung yang aman.';

  @override
  String get identityChangedTitle => 'Identitas server berubah';

  @override
  String get identityChangedBody =>
      'Server ini tidak lagi cocok dengan identitas yang disimpan saat penyandingan. Itu bisa berarti server diinstal ulang — atau ada yang menyadap koneksi. Demi keamanan, perangkat ini tidak akan terhubung. Hapus penyandingan, lalu pindai kode QR baru dari Control Center untuk menyandingkan lagi.';

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
      'Belum disandingkan — pindai kode QR dari Control Center';

  @override
  String get failureUnreachable =>
      'Tidak dapat menjangkau server di jalur mana pun — pastikan server berjalan, atau coba jaringan yang sama';

  @override
  String get failureIdentityChanged =>
      'Identitas server berubah — jika diinstal ulang, sandingkan ulang perangkat ini';

  @override
  String get failureAuthRejected =>
      'Server menolak perangkat ini — sandingkan ulang dari Control Center';

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
      'Ketuk lagi untuk memutus perangkat ini dari Control Center';

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
  String get newSpaceFolder => 'Folder baru';

  @override
  String get folderName => 'Nama folder';

  @override
  String get renameSpaceFolder => 'Ubah nama folder';

  @override
  String get deleteSpaceFolder => 'Hapus folder';

  @override
  String get moveSpaceToFolder => 'Pindahkan ke folder';

  @override
  String get removeSpaceFromFolder => 'Keluarkan dari folder';

  @override
  String get spaceFolderActions => 'Tindakan folder';

  @override
  String get deleteFolderWithSpacesWarning =>
      'Menghapus ruang secara permanen akan menghapus pesan dan direktori kerja ruang tersebut untuk semua orang. Tindakan ini tidak dapat dibatalkan.';

  @override
  String get deleteSpacesInFolder => 'Hapus permanen ruang dalam folder ini';

  @override
  String get deleteFolderAndSpaces => 'Hapus folder dan ruang';

  @override
  String get keepSpacesInFolder =>
      'Jika tidak, ruang akan tetap berada di luar folder.';

  @override
  String get create => 'Buat';

  @override
  String get otherSpaces => 'Ruang lainnya';

  @override
  String get folderUpdateFailed => 'Tidak dapat memperbarui folder';

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
  String get teammate => 'Rekan tim';

  @override
  String get systemSender => 'Sistem';

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

  @override
  String get mobileConversations => 'Percakapan';

  @override
  String get mobileNewConversation => 'Percakapan baru';

  @override
  String get mobileConversationName => 'Nama percakapan';

  @override
  String get mobileRename => 'Ganti nama';

  @override
  String get mobileManageSpace => 'Kelola ruang';

  @override
  String get mobileArchived => 'Diarsipkan';

  @override
  String get mobileSearchMessages => 'Cari semua pesan di ruang ini';

  @override
  String get mobileSearch => 'Cari';

  @override
  String get mobileNoResults => 'Tidak ada hasil';

  @override
  String get mobileReopen => 'Buka lagi';

  @override
  String get mobileArchive => 'Arsipkan';

  @override
  String get mobileProgress => 'Progres dan konteks';

  @override
  String get mobileReadFailed =>
      'Tidak dapat menandai percakapan ini sebagai dibaca';

  @override
  String get mobileSendFailed =>
      'Pesan tidak terkirim. Draf Anda masih tersimpan.';

  @override
  String get sentAttachmentUnavailable => 'Lampiran tidak tersedia';

  @override
  String get sentAttachmentLoadFailed => 'Tidak dapat memuat lampiran';

  @override
  String get mobileActionFailed => 'Tindakan gagal';

  @override
  String get mobileRemove => 'Hapus';

  @override
  String get mobileLinkedMessage => 'Pesan tertaut';

  @override
  String get mobileOlderMessages => 'Pesan lama';

  @override
  String get mobileMessageActions => 'Tindakan pesan';

  @override
  String get mobileOpenThread => 'Buka utas';

  @override
  String get mobileCopyLink => 'Salin tautan';

  @override
  String get mobileStopRun => 'Hentikan run';

  @override
  String get mobileStopRunConfirm =>
      'Hentikan run agen ini? Pekerjaan yang sudah selesai akan tetap tersimpan.';

  @override
  String get mobileControlUnsupported =>
      'Run ini sudah selesai atau tidak mendukung kendali ini.';

  @override
  String get mobilePauseRequested => 'Jeda diminta setelah giliran berikutnya';

  @override
  String get mobileResumed => 'Run dilanjutkan';

  @override
  String get mobileStopRequested => 'Penghentian diminta';

  @override
  String get mobileQueuedMessages => 'Pesan dalam antrean';

  @override
  String get mobilePauseRun => 'Jeda setelah giliran berikutnya';

  @override
  String get mobileResumeRun => 'Lanjutkan';

  @override
  String get mobileEditQueued => 'Edit pesan dalam antrean';

  @override
  String get mobileSteerNow => 'Arahkan sekarang';

  @override
  String get mobileMoveUp => 'Naikkan';

  @override
  String get mobileMoveDown => 'Turunkan';

  @override
  String get mobileQueueChanged =>
      'Antrean berubah, atau run ini tidak menerima arahan langsung. Segarkan lalu coba lagi.';

  @override
  String get mobileActivity => 'Aktivitas';

  @override
  String get mobilePermissions => 'Izin dan audit';

  @override
  String get mobilePlans => 'Rencana';

  @override
  String get mobileGoals => 'Tujuan terawasi';

  @override
  String get mobileCredentials => 'Koneksi dan kredensial';

  @override
  String get mobileWorkspaceUnavailable =>
      'Ruang kerja ini tidak tersedia atau Anda tidak lagi memiliki akses.';

  @override
  String get mobilePrReviewThreads => 'Utas tinjauan';

  @override
  String get mobilePrThreadsLoadFailed => 'Tidak dapat memuat utas tinjauan';

  @override
  String get mobilePrNoReviewThreads => 'Belum ada utas tinjauan sebaris';

  @override
  String get mobilePrCommentPermissionDenied =>
      'Anda tidak memiliki izin untuk berkomentar di repositori ini.';

  @override
  String get mobilePrPermissionChecking => 'Memeriksa izin berkomentar…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'Tidak dapat memeriksa izin berkomentar. Coba lagi untuk berkomentar.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return 'Sisi $side baris $line';
  }

  @override
  String get mobilePrOriginalSide => 'Asli';

  @override
  String get mobilePrSelectCommentLine => 'Pilih baris untuk dikomentari';

  @override
  String get mobilePrUpdatedSide => 'Diperbarui';

  @override
  String get mobilePrThreadResolved => 'Diselesaikan';

  @override
  String get mobilePrReplyHint => 'Tulis balasan…';

  @override
  String get mobilePrCommentRequired => 'Tulis komentar sebelum mengirim.';

  @override
  String get mobilePrReply => 'Balas';

  @override
  String get mobilePrReopenThread => 'Buka kembali utas';

  @override
  String get mobilePrResolveThread => 'Selesaikan utas';

  @override
  String get mobilePrResolvePermissionDenied =>
      'Hanya penulis pull request atau pengguna dengan akses tulis yang dapat menyelesaikan utas ini.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'Komentari sisi $side baris $line';
  }

  @override
  String get mobilePrInlineCommentHint => 'Tulis komentar sebaris…';

  @override
  String get mobilePrPostInlineComment => 'Kirim komentar';

  @override
  String get mobilePrCommentUnavailable =>
      'Komentar sebaris tidak tersedia untuk pull request ini.';

  @override
  String get mobilePrPatchUnavailable =>
      'Layanan repositori tidak menyediakan patch teks untuk berkas ini.';

  @override
  String get mobilePrNoPatchForFile => 'Patch untuk berkas ini tidak tersedia.';

  @override
  String get mobileTicketNew => 'Tiket baru';

  @override
  String get mobileTicketCreate => 'Buat tiket';

  @override
  String get mobileTicketEdit => 'Edit tiket';

  @override
  String get mobileTicketTitle => 'Judul';

  @override
  String get mobileTicketTitleRequired =>
      'Masukkan judul untuk menyimpan tiket ini.';

  @override
  String get mobileTicketDescription => 'Deskripsi';

  @override
  String get mobileTicketMarkdownHint => 'Tambahkan detail dalam Markdown';

  @override
  String get mobileTicketPriority => 'Prioritas';

  @override
  String get mobileTicketPriorityNone => 'Tanpa prioritas';

  @override
  String get mobileTicketPriorityUrgent => 'Mendesak';

  @override
  String get mobileTicketPriorityHigh => 'Tinggi';

  @override
  String get mobileTicketPriorityMedium => 'Sedang';

  @override
  String get mobileTicketPriorityLow => 'Rendah';

  @override
  String get mobileTicketLabels => 'Label';

  @override
  String get mobileTicketLabelsHint => 'Satu label per baris';

  @override
  String get mobileTicketLabelsHelp =>
      'Masukkan setiap label di baris terpisah.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'Dibuat di $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'Belum ditugaskan';

  @override
  String get mobileTicketAssignedFilter => 'Ditugaskan';

  @override
  String get mobileTicketAgentsLoadFailed => 'Tidak dapat memuat agen';

  @override
  String get mobileTicketSearch => 'Cari tiket';

  @override
  String get mobileTicketSearchHint =>
      'Judul, kode, deskripsi, label, atau penerima tugas';

  @override
  String get mobileTicketClearSearch => 'Hapus pencarian tiket';

  @override
  String get mobileTicketNoMatches => 'Tidak ada tiket yang cocok';

  @override
  String get mobileTicketAdjustFilters =>
      'Coba pencarian lain atau ubah filternya.';

  @override
  String get mobileTicketClearFilters => 'Hapus filter';

  @override
  String get mobileTicketNotFound => 'Tiket tidak ditemukan';

  @override
  String get mobileTicketNotFoundDescription =>
      'Tiket ini mungkin telah dihapus atau dipindahkan dari ruang kerja ini.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'Ruang kerja berubah. Kembali ke ruang kerja saat ini sebelum menyimpan.';

  @override
  String get mobileTicketOpenLinkedSpace => 'Buka ruang tertaut';

  @override
  String get mobileTicketReadOnly =>
      'Anda harus menjadi anggota ruang kerja untuk mengubah tiket.';

  @override
  String get permissionTitle => 'Izin';

  @override
  String get permissionWorkspaceFailed => 'Tidak dapat memuat ruang kerja';

  @override
  String get permissionNoWorkspace => 'Pilih ruang kerja untuk melihat izin.';

  @override
  String get permissionLoading => 'Memuat izin…';

  @override
  String get permissionScopeDescription =>
      'Lihat bagaimana setiap tindakan diputuskan pada cakupan ini. Aturan ruang kerja dapat diwariskan oleh agen dan ruang.';

  @override
  String get permissionScope => 'Cakupan kebijakan';

  @override
  String get permissionWorkspaceScope => 'Ruang kerja';

  @override
  String get permissionAgentScope => 'Agen';

  @override
  String get permissionSpaceScope => 'Space';

  @override
  String get permissionAgentContext => 'Agen yang bertindak di ruang ini';

  @override
  String get permissionNoAgentContext => 'Belum ada agen yang dipilih';

  @override
  String get permissionTargetsFailed => 'Tidak dapat memuat target cakupan';

  @override
  String get permissionNoTargets => 'Tidak ada target pada cakupan ini.';

  @override
  String get permissionRoleFailed =>
      'Tidak dapat memastikan peran Anda di ruang kerja';

  @override
  String get permissionMemberRequired =>
      'Anda harus menjadi anggota ruang kerja untuk melihat aturan kebijakan.';

  @override
  String get permissionRulesFailed => 'Tidak dapat memuat aturan kebijakan';

  @override
  String get permissionAuditAdminOnly =>
      'Riwayat otorisasi hanya tersedia bagi admin ruang kerja.';

  @override
  String get permissionAllow => 'Izinkan';

  @override
  String get permissionAsk => 'Tanyakan dulu';

  @override
  String get permissionDeny => 'Tolak';

  @override
  String get permissionFileDelete => 'Hapus berkas';

  @override
  String get permissionFileWriteOutsideWorktree => 'Tulis di luar pohon kerja';

  @override
  String get permissionGitCommit => 'Commit perubahan';

  @override
  String get permissionGitPush => 'Push commit';

  @override
  String get permissionPrCreate => 'Buat pull request';

  @override
  String get permissionPrPublish => 'Perbarui atau gabungkan pull request';

  @override
  String get permissionVendorSyncWrite => 'Tulis sinkronisasi penyedia';

  @override
  String get permissionNetworkEgress => 'Akses jaringan';

  @override
  String get permissionSecretAccess => 'Akses rahasia';

  @override
  String get permissionPackageInstall => 'Instal paket';

  @override
  String get permissionProcessSpawn => 'Jalankan proses';

  @override
  String get permissionWorkspaceMutation => 'Ubah ruang kerja';

  @override
  String get permissionEnclosureControl => 'Kendalikan lingkungan terisolasi';

  @override
  String get permissionChangeFailed => 'Tidak dapat mengubah aturan';

  @override
  String get permissionEffectiveDescription =>
      'Berlaku pada cakupan ini tanpa argumen tindakan. Izin bersyarat di bawah hanya berlaku untuk permintaan yang cocok; server membuat keputusan akhir.';

  @override
  String get permissionSpaceAgentNote =>
      'Belum ada agen yang dipilih. Aturan khusus agen disembunyikan sampai Anda memilih agen di atas.';

  @override
  String get permissionScopedGrants => 'Aturan pada cakupan ini';

  @override
  String get permissionModePreset => 'Preset mode';

  @override
  String get permissionBuiltInDefault => 'Default bawaan';

  @override
  String get permissionRemembered => 'Persetujuan sementara';

  @override
  String get permissionSource => 'Sumber';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · ditetapkan di sini';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · diwariskan';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'Kedaluwarsa $date';
  }

  @override
  String get permissionSetHere => 'Tetapkan aturan di sini';

  @override
  String get permissionConfirmRevoke => 'Konfirmasi pencabutan';

  @override
  String get permissionRevokeRule => 'Cabut aturan';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'Awalan perintah: $prefix';
  }

  @override
  String get permissionNoExpiry => 'Tidak kedaluwarsa';

  @override
  String get permissionExpired => 'Kedaluwarsa';

  @override
  String get permissionExplicitRule => 'Aturan eksplisit';

  @override
  String get permissionEnforcementAdvisory =>
      'Advisori: aturan yang meminta persetujuan dicatat tanpa menampilkan permintaan';

  @override
  String get permissionEnforcementSoft =>
      'Penerapan lunak: pengesampingan memerlukan otorisasi';

  @override
  String get permissionEnforcementHard =>
      'Penerapan ketat: tidak dapat dikesampingkan';

  @override
  String permissionPaths(String paths) {
    return 'Jalur: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Referensi Git: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'Host: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'Perintah: $commands';
  }

  @override
  String permissionTools(String tools) {
    return 'Tool: $tools';
  }

  @override
  String get permissionNotInEffect => 'Tidak berlaku saat tindakan ini ditolak';

  @override
  String permissionMaxCount(String count) {
    return 'Jumlah maksimum: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'Maksimum sen: $cents';
  }

  @override
  String get permissionAuditHeading => 'Riwayat otorisasi';

  @override
  String get permissionAuditDescription =>
      'Keputusan terbaru yang dicatat server. Hanya admin yang dapat melihat log atau memverifikasi rantai hash-nya.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'atas nama $user';
  }

  @override
  String get permissionPrompted => 'Persetujuan manusia diminta';

  @override
  String get permissionVerifyChain => 'Verifikasi rantai audit';

  @override
  String get permissionVerifyFailed => 'Tidak dapat memverifikasi rantai audit';

  @override
  String permissionChainIntact(String count) {
    return 'Rantai utuh · $count entri diperiksa';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'Rantai rusak pada entri $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty =>
      'Belum ada keputusan otorisasi yang dicatat.';

  @override
  String get permissionAuditFailed => 'Tidak dapat memuat riwayat otorisasi';

  @override
  String get mobilePlansLoadFailed => 'Tidak dapat memuat rencana';

  @override
  String get mobilePlansEmpty => 'Belum ada rencana';

  @override
  String get mobilePlansEmptyDescription =>
      'Rencana yang dikirim agen akan muncul di sini untuk ditinjau.';

  @override
  String get mobilePlanTitle => 'Rencana';

  @override
  String get mobilePlanMissing =>
      'Rencana ini tidak lagi tersedia di ruang kerja ini.';

  @override
  String mobilePlanStepCount(int count) {
    return '$count langkah';
  }

  @override
  String get mobilePlanDraft => 'Draf';

  @override
  String get mobilePlanProposed => 'Menunggu tinjauan';

  @override
  String get mobilePlanApproved => 'Disetujui';

  @override
  String get mobilePlanRejected => 'Ditolak';

  @override
  String get mobilePlanSuperseded => 'Digantikan';

  @override
  String get mobilePlanExecuting => 'Menjalankan';

  @override
  String get mobilePlanSynthesizing => 'Mensintesis';

  @override
  String get mobilePlanCompleted => 'Selesai';

  @override
  String get mobilePlanFailed => 'Gagal';

  @override
  String get mobilePlanCancelled => 'Dibatalkan';

  @override
  String mobilePlanRevision(String revision) {
    return 'Revisi $revision';
  }

  @override
  String get mobilePlanSteps => 'Langkah';

  @override
  String get mobilePlanNoSteps =>
      'Tidak ada langkah yang dikirim untuk rencana ini.';

  @override
  String get mobilePlanAssumptions => 'Klarifikasi';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'Bergantung pada $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'Perkiraan hingga $cost';
  }

  @override
  String get mobilePlanSelect => 'Pilih';

  @override
  String get mobilePlanSelected => 'Dipilih';

  @override
  String get mobilePlanEstimate => 'Perkirakan biaya';

  @override
  String get mobilePlanEstimateRequired =>
      'Perkirakan biaya rencana sebelum menyetujui pelaksanaannya.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'Perkiraan biaya: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'tidak tersedia';

  @override
  String get mobilePlanNoHardCap => 'tanpa batas maksimum tetap';

  @override
  String get mobilePlanExceedsBudget =>
      'Perkiraan melebihi anggaran yang ditetapkan. Tinjau sebelum menyetujui.';

  @override
  String get mobilePlanPartialEstimate =>
      'Perkiraan ini mencakup seluruh rencana; langkah yang dipilih mungkin lebih murah.';

  @override
  String get mobilePlanConfirmAll => 'Jalankan seluruh rencana?';

  @override
  String get mobilePlanConfirmSelected => 'Jalankan langkah yang dipilih?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'Persetujuan akan memulai pelaksanaan dan dapat menimbulkan biaya. Perkiraan biaya tertinggi: $cost. Batas anggaran: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'Setujui semua dan jalankan';

  @override
  String get mobilePlanApproveSelected => 'Setujui pilihan dan jalankan';

  @override
  String get mobilePlanWiden => 'Setujui langkah tambahan';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'Izinkan $count langkah tambahan untuk dijalankan? Ini dapat menimbulkan biaya. Batas biaya pelaksanaan saat ini: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'Rencana berubah saat ditinjau. Buka revisi terbaru dan perkirakan lagi biayanya.';

  @override
  String get mobilePlanReject => 'Tolak rencana';

  @override
  String get mobilePlanRejectConfirm =>
      'Tolak rencana ini? Rencana tidak akan dijalankan.';

  @override
  String get mobilePlanStop => 'Hentikan pelaksanaan';

  @override
  String get mobilePlanStopConfirm =>
      'Hentikan pelaksanaan rencana ini? Pekerjaan yang sudah selesai tidak akan dibatalkan.';

  @override
  String mobilePlanRunId(String runId) {
    return 'Run pelaksanaan: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'Persetujuan diterima. Menunggu catatan pelaksanaan…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return '$completed dari $total langkah pelaksanaan selesai';
  }

  @override
  String get mobilePlanOpenConversation => 'Buka percakapan';

  @override
  String get mobileGoalsTitle => 'Tujuan terawasi';

  @override
  String get mobileGoalsLoadFailed => 'Tidak dapat memuat tujuan terawasi';

  @override
  String get mobileGoalsEmpty => 'Belum ada tujuan terawasi';

  @override
  String get mobileGoalsEmptyDescription =>
      'Mulai di sebuah ruang, atau kirim /goal dalam percakapan.';

  @override
  String get mobileGoalMissing =>
      'Tujuan ini tidak lagi tersedia di ruang kerja ini.';

  @override
  String get mobileGoalActive => 'Aktif';

  @override
  String get mobileGoalPaused => 'Dijeda';

  @override
  String get mobileGoalCompleted => 'Selesai';

  @override
  String get mobileGoalFailed => 'Gagal';

  @override
  String get mobileGoalCancelled => 'Dibatalkan';

  @override
  String get mobileGoalBudgetExhausted => 'Batas anggaran tercapai';

  @override
  String mobileGoalFailures(String count) {
    return 'Run gagal berturut-turut: $count';
  }

  @override
  String get mobileGoalFailedDescription =>
      'Pengawas berhenti setelah beberapa run gagal. Lihat percakapan untuk detailnya.';

  @override
  String get mobileGoalPause => 'Jeda tujuan';

  @override
  String get mobileGoalResume => 'Lanjutkan tujuan';

  @override
  String get mobileGoalStop => 'Batalkan tujuan';

  @override
  String get mobileGoalStopConfirm =>
      'Batalkan tujuan terawasi ini secara permanen? Tujuan ini tidak dapat dilanjutkan.';

  @override
  String get mobileGoalRaiseBudget => 'Naikkan anggaran dan lanjutkan';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'Naikkan anggaran menjadi $amount dan lanjutkan';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'Naikkan batas biaya tujuan ini dari $oldCap menjadi $newCap dan lanjutkan pengeluaran?';
  }

  @override
  String get mobileGoalOpenConversation => 'Buka percakapan tujuan';

  @override
  String get mobileGoalCreate => 'Mulai tujuan terawasi';

  @override
  String get mobileGoalChooseSpace => 'Jalankan di ruang';

  @override
  String get mobileGoalNoSpaces => 'Buat ruang sebelum memulai tujuan.';

  @override
  String get mobileGoalChooseAgent => 'Jalankan dengan agen';

  @override
  String get mobileGoalNoAgents =>
      'Tambahkan agen aktif sebelum memulai tujuan.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return '$name dipilih';
  }

  @override
  String get mobileGoalObjectiveHint => 'Hasil apa yang harus dicapai agen?';

  @override
  String get mobileGoalBudgetUsd => 'Batas biaya (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'Pilih ruang dan agen, masukkan tujuan, serta tetapkan batas biaya positif dalam USD.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'Mulai tujuan terawasi dengan biaya maksimal $cap? Agen dapat segera memulai.';
  }

  @override
  String get mobileGoalUnavailable =>
      'Koneksi server belum siap. Coba lagi setelah terhubung kembali.';

  @override
  String get mobileGoalConversationMissing =>
      'Percakapan yang dipilih tidak lagi tersedia di ruang kerja ini.';

  @override
  String get mobileGoalCreateSent =>
      'Tujuan dimulai. Status pengawas akan muncul dalam daftar ini.';

  @override
  String get mobileGoalStartRefused =>
      'Tidak ada run tujuan yang dimulai. Lihat alasan pengawas dalam percakapan.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return '$name dipilih';
  }

  @override
  String get requestUnavailable =>
      'Permintaan ini tidak lagi tersedia di ruang kerja aktif.';

  @override
  String get requestAlreadyResolved => 'Permintaan ini sudah diselesaikan.';

  @override
  String get inboxCredentialsBlocked => 'Run terhambat oleh kredensial';

  @override
  String get inboxSyncFailures => 'Sinkronisasi penyedia gagal';

  @override
  String get inboxConfigureCredentials => 'Atur kredensial';

  @override
  String get openTicket => 'Buka tiket';

  @override
  String get activityTitle => 'Aktivitas';

  @override
  String get activityClearAll => 'Hapus aktivitas';

  @override
  String get activityClearConfirm =>
      'Ini menyembunyikan semua aktivitas yang telah dicatat untuk Anda di semua perangkat. Aktivitas baru tetap akan muncul.';

  @override
  String get activityMarkAllRead => 'Tandai semua dibaca';

  @override
  String get activityMarkAllConfirm =>
      'Tandai semua item aktivitas di ruang kerja ini sebagai dibaca di semua perangkat Anda?';

  @override
  String get activityMarkRead => 'Tandai dibaca';

  @override
  String get activityMarkUnread => 'Tandai belum dibaca';

  @override
  String get activityDismiss => 'Tutup';

  @override
  String get activityResolved => 'Diselesaikan';

  @override
  String get activityOpen => 'Terbuka';

  @override
  String get activityEmpty => 'Belum ada aktivitas';

  @override
  String get activityLoadFailed => 'Tidak dapat memuat aktivitas';

  @override
  String get activityAgentWaiting => 'Agen memerlukan masukan';

  @override
  String get activityAgentBlocked => 'Tindakan agen diblokir';

  @override
  String get activityMessage => 'Pesan baru';

  @override
  String get activityPullRequest => 'Pembaruan pull request';

  @override
  String get activityRig => 'Pembaruan lingkungan terisolasi';

  @override
  String get activityEvent => 'Perbarui';

  @override
  String get activityPrReady => 'Pull request siap digabungkan';

  @override
  String get activityPrBlocked => 'Penggabungan pull request terhalang';

  @override
  String get activityPrApproved => 'Pull request disetujui';

  @override
  String get activityPrChanges => 'Perubahan diminta';

  @override
  String get activityPrChecksFailed => 'Pemeriksaan pull request gagal';

  @override
  String get activityPrChecksRecovered =>
      'Pemeriksaan pull request kembali berhasil';

  @override
  String get activityPrComment => 'Komentar pada pull request';

  @override
  String get activityPrPublished => 'Pull request dipublikasikan';

  @override
  String get activityPrMerged => 'Pull request digabungkan';

  @override
  String get activityPrMentioned => 'Disebut dalam pull request';

  @override
  String get activityPrReviewRequested => 'Tinjauan diminta';

  @override
  String get activityPrReviewStale => 'Tinjauan perlu diperbarui';

  @override
  String get activityTicketAssigned => 'Tiket ditugaskan';

  @override
  String get activityTicketChanged => 'Status tiket berubah';

  @override
  String get activityMeetingSoon => 'Rapat segera dimulai';

  @override
  String get activityCalendarExpired => 'Koneksi kalender kedaluwarsa';

  @override
  String get activityRigControl => 'Kendali lingkungan terisolasi berubah';

  @override
  String get activityRigClosed => 'Lingkungan terisolasi dihentikan';

  @override
  String get mobileSpacesSearch => 'Cari ruang';

  @override
  String get mobileSpacesArchived => 'Diarsipkan';

  @override
  String get mobileSpacesActive => 'Aktif';

  @override
  String get mobileSpacesNew => 'Ruang baru';

  @override
  String get mobileSpacesManage => 'Kelola ruang';

  @override
  String get mobileSpacesName => 'Nama space';

  @override
  String get mobileSpacesAgents => 'Agen';

  @override
  String get mobileSpacesMembers => 'Orang';

  @override
  String get mobileSpacesRepos => 'Repositori';

  @override
  String get mobileSpacesAllRepos => 'Semua repositori tertaut';

  @override
  String get mobileSpacesNoRepos => 'Tidak ada repositori';

  @override
  String get mobileSpacesBaseBranch => 'Cabang dasar (opsional)';

  @override
  String get mobileSpacesDefaultBranch => 'Cabang default';

  @override
  String get mobileSpacesMode => 'Mode';

  @override
  String get mobileSpacesModeChat => 'Chat';

  @override
  String get mobileSpacesModeReview => 'Tinjau (hanya baca)';

  @override
  String get mobileSpacesModePlan => 'Rencanakan (hanya baca)';

  @override
  String get mobileSpacesModeOrchestrate => 'Orkestrasikan';

  @override
  String get mobileSpacesAutonomy => 'Pengesampingan otonomi';

  @override
  String get mobileSpacesAutonomyInherited => 'Diwariskan';

  @override
  String get mobileSpacesAutonomyPropose => 'Hanya usulkan';

  @override
  String get mobileSpacesAutonomyApproval => 'Bertindak dengan persetujuan';

  @override
  String get mobileSpacesAutonomyFreely => 'Bertindak bebas';

  @override
  String get mobileSpacesAutonomyNotice =>
      'Pengesampingan tidak dapat melewati permintaan persetujuan atau penolakan kebijakan tindakan. Hanya admin ruang kerja yang dapat mengubahnya.';

  @override
  String get mobileSpacesArchive => 'Arsipkan ruang';

  @override
  String get mobileSpacesReopen => 'Buka kembali ruang';

  @override
  String get mobileSpacesSave => 'Simpan perubahan';

  @override
  String get mobileSpacesCreate => 'Buat ruang';

  @override
  String get mobileSpacesOperationFailed => 'Tidak dapat memperbarui ruang';

  @override
  String get mobileSpacesMissing => 'Ruang tidak ditemukan di ruang kerja ini';

  @override
  String get mobileSpacesEmptyName => 'Masukkan nama ruang';

  @override
  String get mobileSpacesNoMatches => 'Tidak ada ruang yang cocok';

  @override
  String get mobileSpacesUnread => 'Balasan agen belum dibaca';

  @override
  String get mobileSpacesNeedsInput => 'Memerlukan masukan Anda';

  @override
  String get mobileSpacesRunning => 'Agen berjalan';

  @override
  String get mobileSpacesNoAgents => 'Tidak ada agen di ruang kerja ini';

  @override
  String get mobileSpacesNoMembers =>
      'Tidak ada anggota lain di ruang kerja ini';

  @override
  String get mobileSpacesRepoError => 'Tidak dapat memuat repositori';

  @override
  String get mobileSpacesRetry => 'Coba lagi';

  @override
  String get mobileSpacesBranchUnavailable =>
      'Pilih atau ketik cabang dasar saat membuat ruang; cabang dasar ruang yang sudah ada tidak dapat diubah.';

  @override
  String get mobileSpacesArchivedEmpty => 'Tidak ada ruang terarsip';

  @override
  String get mobileSpacesAllRepoWarning =>
      'Repositori yang baru ditautkan ke ruang kerja juga akan disertakan dalam ruang ini.';

  @override
  String get mobileSpacesCreatedRetry =>
      'Ruang dibuat. Coba lagi menambahkan orang, atau buka halaman pengelolaannya.';

  @override
  String get progressTitle => 'Progres';

  @override
  String get progressConversation => 'Percakapan';

  @override
  String get progressLoadFailed => 'Tidak dapat memuat progres';

  @override
  String get progressUnavailable => 'Percakapan tidak tersedia';

  @override
  String get progressUnavailableDescription =>
      'Percakapan ini tidak berada di ruang kerja dan ruang yang aktif. Kembali ke ruangnya untuk melanjutkan.';

  @override
  String get progressSaveFailed => 'Tidak dapat memperbarui progres';

  @override
  String get progressGoal => 'Tujuan';

  @override
  String get progressNoGoal => 'Belum ada tujuan kerja';

  @override
  String get progressSetGoal => 'Tetapkan tujuan';

  @override
  String get progressEditGoal => 'Edit tujuan';

  @override
  String get progressClearGoal => 'Hapus tujuan';

  @override
  String get progressGoalRequired => 'Masukkan tujuan sebelum menyimpan.';

  @override
  String get progressTodos => 'Tugas';

  @override
  String get transcriptToolTodos => 'Tugas';

  @override
  String get transcriptToolSearchMemory => 'Cari di memori';

  @override
  String get transcriptToolRenderMedia => 'Tampilkan media';

  @override
  String get progressNoTodos => 'Belum ada tugas';

  @override
  String get progressNewTodo => 'Tugas baru';

  @override
  String get progressAddTodo => 'Tambahkan tugas';

  @override
  String get progressEditTodo => 'Edit tugas';

  @override
  String get progressTodoRequired => 'Masukkan tugas sebelum menyimpan.';

  @override
  String get progressTodoNoLongerExists =>
      'Tugas tersebut telah dihapus. Muat ulang daftar lalu coba lagi.';

  @override
  String get progressWorkspaceChanged =>
      'Ruang kerja aktif berubah. Kembali ke percakapan ini lalu coba lagi.';

  @override
  String progressRemoveTodo(String name) {
    return 'Hapus tugas $name';
  }

  @override
  String get progressPending => 'Menunggu';

  @override
  String get progressInProgress => 'Sedang berjalan';

  @override
  String get progressCompleted => 'Selesai';

  @override
  String get progressMoveUp => 'Naikkan tugas';

  @override
  String get progressMoveDown => 'Turunkan tugas';

  @override
  String get progressRunTree => 'Run agen';

  @override
  String get progressNoRuns => 'Belum ada run dalam percakapan ini';

  @override
  String get progressRunning => 'Berjalan';

  @override
  String get progressFailed => 'Gagal';

  @override
  String get progressUnknown => 'Tidak diketahui';

  @override
  String get progressHealthy => 'Aktif';

  @override
  String get progressBlocked => 'Diblokir';

  @override
  String get progressLooping => 'Berulang';

  @override
  String get progressStalled => 'Terhenti';

  @override
  String get progressDead => 'Berhenti tiba-tiba';

  @override
  String get progressQuiet => 'Belum ada keluaran';

  @override
  String get progressCostReported => 'Biaya yang dilaporkan penyedia';

  @override
  String get progressCostNotional =>
      'Harga daftar langganan secara teoretis; bukan tagihan';

  @override
  String get progressCostMixed => 'Sumber biaya campuran';

  @override
  String get progressCostEstimated => 'Perkiraan biaya';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds dtk';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'Model: $model · Waktu: $duration · Biaya: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'Dimulai $time';
  }

  @override
  String progressLiveness(String state) {
    return 'Kondisi: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'Masukan: $input · Keluaran: $output token';
  }

  @override
  String get progressOutputPreviewLimited =>
      'Hanya 6.000 karakter pertama dari keluaran terstruktur yang ditampilkan.';

  @override
  String progressRetryOf(String runId) {
    return 'Percobaan ulang run $runId';
  }

  @override
  String get progressContext => 'Konteks dan batas';

  @override
  String get progressNoAgent => 'Tidak ada agen untuk diperiksa';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window token';
  }

  @override
  String get progressMeasured =>
      'Konteks yang dilaporkan penyedia pada panggilan terakhir';

  @override
  String get progressEstimated =>
      'Diperkirakan dari percakapan tersimpan dan konteks persisten';

  @override
  String get progressContextUnknown => 'Penggunaan konteks belum dilaporkan';

  @override
  String progressContextPercent(String percent) {
    return '$percent% dari jendela konteks';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'Batas bulanan agen yang ditetapkan: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'Percakapan aktif tersimpan: sekitar $tokens token';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'Konteks persisten untuk $agent · $model';
  }

  @override
  String get progressContextSystem => 'Prompt sistem';

  @override
  String get progressContextRules => 'Aturan';

  @override
  String get progressContextSkills => 'Skill';

  @override
  String get progressContextTools => 'Definisi alat';

  @override
  String get progressContextMcp => 'Alat MCP';

  @override
  String get progressContextDeferred => 'Alat tertunda';

  @override
  String get progressContextSubagents => 'Subagen';

  @override
  String get progressContextRunner => 'Runner eksternal';

  @override
  String get progressContextMemory => 'Memori';

  @override
  String get progressContextHistory => 'Riwayat percakapan';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens token';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens token';
  }

  @override
  String get progressOutputs => 'Keluaran terbaru';

  @override
  String get progressNoOutputs => 'Belum ada keluaran agen terbaru';

  @override
  String get progressStructuredOutputsAbove =>
      'Keluaran run terstruktur ditampilkan dalam daftar run agen di atas.';

  @override
  String get progressRecentOutputsOnly =>
      'Hanya pesan terbaru yang ditampilkan. Buka percakapan untuk melihat pekerjaan lama.';

  @override
  String get progressPlan => 'Rencana';

  @override
  String get progressArtifact => 'Artefak';

  @override
  String get progressResult => 'Hasil';

  @override
  String get progressHideArtifact => 'Sembunyikan artefak';

  @override
  String get progressReadArtifact => 'Baca artefak';

  @override
  String get progressArtifactUnavailable => 'Artefak tidak lagi tersedia';

  @override
  String get progressArtifactPreviewLimited =>
      'Hanya pratinjau terbatas dari artefak ini yang ditampilkan.';

  @override
  String get progressDiagramSource => 'Sumber diagram';

  @override
  String progressOpenAttachment(String name) {
    return 'Buka $name';
  }

  @override
  String get progressOpenPlan => 'Buka rencana';

  @override
  String progressOpenDiff(String label) {
    return 'Tinjau berkas yang diubah: $label';
  }

  @override
  String get progressViewMessage => 'Lihat pesan';

  @override
  String get pushTitle => 'Notifikasi latar belakang';

  @override
  String get pushIntro =>
      'Dapatkan pemberitahuan pribadi saat sesuatu memerlukan perhatian Anda, bahkan ketika aplikasi ditutup. Detail tetap berada dalam koneksi terenkripsi Anda.';

  @override
  String get pushLoading => 'Memeriksa pengaturan notifikasi…';

  @override
  String get pushError =>
      'Tidak dapat memperbarui notifikasi. Periksa koneksi Anda lalu coba lagi.';

  @override
  String get pushEnable => 'Aktifkan notifikasi';

  @override
  String get pushDisable => 'Matikan notifikasi';

  @override
  String get pushQuiet => 'Jeda pemberitahuan di perangkat ini';

  @override
  String get pushCategories => 'Beri tahu saya tentang';

  @override
  String get pushCategoryAgents => 'Agen';

  @override
  String get pushCategoryMessages => 'Pesan';

  @override
  String get pushCategoryPullRequests => 'Pull request';

  @override
  String get pushCategoryTickets => 'Tiket';

  @override
  String get pushCategoryCalendar => 'Kalender';

  @override
  String get pushCategoryMachines => 'Mesin';

  @override
  String get pushSecureOrigin => 'Notifikasi memerlukan HTTPS.';

  @override
  String get pushInstallIos =>
      'Di iPhone atau iPad, tambahkan aplikasi ini ke Layar Utama lalu buka dari sana untuk mengaktifkan notifikasi.';

  @override
  String get pushUnsupported =>
      'Browser ini tidak mendukung notifikasi latar belakang.';

  @override
  String get pushDenied =>
      'Browser melaporkan notifikasi diblokir. Periksa izin situs ini dan pengaturan notifikasi browser atau perangkat, lalu muat ulang.';

  @override
  String get pushOsHint =>
      'Browser Anda juga memerlukan izin untuk menampilkan notifikasi di pengaturan sistem perangkat.';

  @override
  String get pushServiceUnavailable =>
      'Layanan push browser menolak langganan. Beberapa browser, seperti Brave, mematikannya secara default: cari opsi pesan push di pengaturan privasi browser, lalu coba lagi.';

  @override
  String get pushWorkerUnavailable =>
      'Layanan notifikasi tidak dapat dimulai di browser ini. Muat ulang halaman dan coba lagi.';

  @override
  String get pushResubscribe => 'Hubungkan kembali notifikasi';

  @override
  String get pushStatusEnabled => 'Notifikasi aktif di perangkat ini.';

  @override
  String get pushStatusDisabled => 'Notifikasi nonaktif di perangkat ini.';

  @override
  String get credentialsTitle => 'Koneksi dan kredensial';

  @override
  String get credentialsIntro =>
      'Hubungkan akun yang digunakan run dan integrasi Anda. Rahasia disimpan di server Anda, bukan di ponsel ini.';

  @override
  String get credentialsModelProviders => 'Penyedia model';

  @override
  String get credentialsOwnerOnly =>
      'Hanya pemilik server yang dapat menambahkan, masuk, atau menghapus kredensial penyedia model. Kunci ini digunakan bersama di seluruh ruang kerja.';

  @override
  String get credentialsContactOwner =>
      'Minta pemilik server menghubungkan penyedia yang diperlukan oleh run Anda yang terhambat.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude Code masuk melalui CLI di host. Minta pemilik server menyelesaikan atau memperbarui login akun di terminal host; ponsel ini tidak dapat menjalankannya.';

  @override
  String get credentialsYourForgeAccounts => 'Akun layanan repositori Anda';

  @override
  String get credentialsYourTicketingAccount => 'Akun layanan tiket Anda';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'Tiket lokal tidak memerlukan login. Hubungkan Linear di sini jika ruang kerja Anda menggunakan Linear.';

  @override
  String get credentialsMembershipRequired =>
      'Bergabunglah dengan ruang kerja untuk mengelola kredensial layanan repositori atau tiket. Minta akses kepada admin ruang kerja.';

  @override
  String get credentialsSwitchWorkspace =>
      'Tautan ini mengarah ke ruang kerja lain. Beralihlah ke ruang kerja tersebut sebelum mengubah kredensial.';

  @override
  String get credentialsReturnToInbox =>
      'Kembali ke Kotak Masuk untuk mencoba lagi run yang terhambat setelah kredensialnya terhubung. Host juga memeriksa run yang dijeda secara otomatis.';

  @override
  String get credentialsLoadFailed =>
      'Tidak dapat memuat koneksi. Periksa tautan server lalu coba lagi.';

  @override
  String get credentialsOperationFailed =>
      'Tidak dapat mengubah koneksi ini. Periksa tautan server, akses Anda, dan kredensialnya, lalu coba lagi.';

  @override
  String get credentialsConnected => 'Terhubung';

  @override
  String get credentialsNotConnected => 'Tidak terhubung';

  @override
  String credentialsSignedInAs(String username) {
    return 'Masuk sebagai $username';
  }

  @override
  String get credentialsAccount => 'Akun terhubung';

  @override
  String get credentialsStoredKey => 'Kunci tersimpan';

  @override
  String get credentialsActive => 'Aktif';

  @override
  String get credentialsRemove => 'Hapus';

  @override
  String get credentialsRemoveConfirm =>
      'Hapus kredensial tersimpan Anda? Anda mungkin perlu masuk lagi.';

  @override
  String get credentialsApiKey => 'Kunci API';

  @override
  String get credentialsApiKeyHint => 'Tempel kunci API penyedia';

  @override
  String get credentialsBrowserLogin => 'Masuk melalui browser';

  @override
  String get credentialsSignInAgain => 'Masuk lagi';

  @override
  String get credentialsWaitingForLogin =>
      'Menunggu otorisasi di browser Anda…';

  @override
  String get credentialsConnectCodePrompt => 'Kode konfirmasi';

  @override
  String get credentialsConnectCodeMalformed =>
      'Itu tidak terlihat seperti kode masuk. Kode terdiri dari 8 huruf dan angka.';

  @override
  String get credentialsSignInInvalidCode =>
      'Kode itu tidak cocok dengan proses masuk ini. Periksa lalu coba lagi.';

  @override
  String get credentialsSignInTooManyCodes =>
      'Terlalu banyak kode yang salah. Mulai ulang proses masuk.';

  @override
  String get credentialsSignInRetryLater =>
      'Layanan masuk tidak merespons saat ini. Tunggu satu menit, lalu coba lagi.';

  @override
  String get credentialsSignInRefused =>
      'Proses masuk ditolak. Mulai ulang dan setujui semua izin yang diminta.';

  @override
  String get credentialsSignInNotSaved =>
      'Proses masuk berhasil, tetapi server tidak dapat menyimpannya. Coba lagi.';

  @override
  String credentialsSignInUnavailable(String provider) {
    return 'Proses masuk ke $provider belum disiapkan di server ini.';
  }

  @override
  String get credentialsSignInPhoneUnreachable =>
      'Alamat callback masuk server ini tidak dapat dijangkau dengan aman dari ponsel. Masuk dari aplikasi desktop, atau minta pemilik server menyiapkan alamat HTTPS publik.';

  @override
  String get credentialsLoginTimedOut =>
      'Sesi login kedaluwarsa. Mulai lagi proses masuk.';

  @override
  String get credentialsCopyCode => 'Salin kode';

  @override
  String get credentialsDeviceCodeHint =>
      'Konfirmasikan kode ini di halaman penyedia. Biarkan layar ini terbuka sementara server menyelesaikan login.';

  @override
  String get credentialsPasteRedirect => 'Kode otorisasi atau URL pengalihan';

  @override
  String get credentialsPasteRedirectHint =>
      'Tempel kode atau URL pengalihan lengkap dari penyedia';

  @override
  String get credentialsCompleteLogin => 'Selesaikan proses masuk';

  @override
  String get credentialsUpdateToken => 'Perbarui token';

  @override
  String get credentialsAddToken => 'Tambah token';

  @override
  String get credentialsPersonalToken => 'Token akses pribadi';

  @override
  String get credentialsPersonalTokenHint => 'Tempel token akses pribadi';

  @override
  String get credentialsStopWatching => 'Berhenti memantau';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'Login Claude Code kedaluwarsa';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'Proses berhenti karena akunnya tidak lagi terautentikasi. Masuk lagi, lalu coba ulang giliran ini.';

  @override
  String get transcriptSignInExpiredTitle => 'Login penyedia kedaluwarsa';

  @override
  String get transcriptSignInExpiredBody =>
      'Proses berhenti karena kredensial penyedianya tidak lagi berfungsi. Hubungkan ulang di Pengaturan → Penyedia, lalu coba ulang giliran ini.';

  @override
  String get permissionHostExecution => 'Jalankan perintah di host';

  @override
  String credentialsSignInLapsed(String provider) {
    return 'Sesi $provider Anda sudah berakhir. Masuk lagi.';
  }

  @override
  String get credentialsSignInPaused =>
      'Dijeda: layanan masuk ruang kerja ini berubah. Akan berfungsi lagi setelah layanan kembali.';

  @override
  String credentialsProviderUnreachable(String provider) {
    return '$provider tidak dapat dihubungi saat ini. Mencoba lagi.';
  }

  @override
  String get credentialsScopeWorkspace => 'Hanya ruang kerja ini';

  @override
  String get credentialsScopeAllWorkspaces => 'Semua ruang kerja';

  @override
  String get credentialsRemoveConfirmWorkspace =>
      'Hapus kredensial tersimpan Anda dari ruang kerja ini? Ruang kerja lain tetap menyimpan miliknya.';

  @override
  String get credentialsRemoveConfirmAllWorkspaces =>
      'Hapus kredensial tersimpan Anda dari setiap ruang kerja yang membagikannya?';

  @override
  String get credentialsSignInServerRestarted =>
      'Server dimulai ulang. Mulai proses masuk lagi.';

  @override
  String repoAccessInstallApp(String owner, String names) {
    return 'Pasang GitHub App di $owner agar otomatisasi dapat menjangkau $names. Ketuk untuk membuka GitHub.';
  }

  @override
  String repoAccessAskAdminInstall(String owner, String names) {
    return 'GitHub App belum dipasang di $owner, jadi otomatisasi tidak dapat menjangkau $names. Minta admin ruang kerja untuk memasangnya.';
  }

  @override
  String repoAccessAddToApp(String names) {
    return 'Tambahkan $names ke repositori GitHub App. Ketuk untuk membuka GitHub.';
  }

  @override
  String repoAccessAskAdminAdd(String names) {
    return 'GitHub App belum dapat melihat $names. Minta admin ruang kerja untuk menambahkannya ke repositorinya.';
  }

  @override
  String repoAccessSuspended(String names) {
    return 'Instalasi GitHub App ditangguhkan. Otomatisasi untuk $names dijeda sampai pemilik akun melanjutkan instalasi di GitHub.';
  }

  @override
  String repoAccessOwnerCannotSee(String names) {
    return 'Orang yang bertanggung jawab atas otomatisasi ruang kerja ini tidak lagi dapat melihat $names, jadi tidak ada yang berjalan di sana atas namanya.';
  }

  @override
  String repoAccessOwnerNotSignedIn(String names) {
    return 'Orang yang bertanggung jawab atas otomatisasi ruang kerja ini belum masuk ke forge, jadi otomatisasi untuk $names menunggu sampai mereka masuk.';
  }

  @override
  String repoAccessRetrying(String names) {
    return 'Tidak dapat memeriksa akses ke $names. Mencoba lagi.';
  }

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Masuk ke $forge untuk melihat pull request dari $count repositori lagi',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count repositori disembunyikan karena akun $forge Anda tidak dapat melihatnya',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count repositori disembunyikan karena Anda tidak punya akses di ruang kerja ini',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Memeriksa akses Anda ke $count repositori lagi…',
    );
    return '$_temp0';
  }

  @override
  String get credentialsAtlassianEmail => 'Email akun Atlassian';

  @override
  String get credentialsAtlassianEmailInvalid =>
      'Masukkan alamat email akun Atlassian Anda.';

  @override
  String get credentialsBitbucketApiToken => 'Token API';

  @override
  String repoAccessAutomationTokenMissing(String names) {
    return 'Tidak ada token otomatisasi yang bisa membaca $names, jadi pekerjaan latar belakang di sana dijeda. Admin bisa menambahkannya di Pengaturan → Repositori.';
  }

  @override
  String get credentialsSignInConfirmInBrowser =>
      'Konfirmasi di browser Anda, lalu masukkan kode yang ditampilkannya.';

  @override
  String get credentialsSignInAccountAlreadyBound =>
      'Akun ini sudah terhubung ke orang lain di server ini. Masuk dengan akun yang berbeda.';

  @override
  String credentialsTokenUnreachable(String provider) {
    return '$provider tidak dapat dihubungi untuk memeriksa token ini. Coba lagi sebentar.';
  }

  @override
  String credentialsTokenRejected(String provider) {
    return '$provider tidak menerima token ini. Periksa bahwa Anda sudah menyalin seluruhnya dan token itu belum dicabut.';
  }

  @override
  String credentialsTokenWrongKind(String provider) {
    return 'Ini bukan token pribadi. Tempel token akses pribadi dari akun $provider Anda sendiri, bukan token proyek, grup, ruang kerja, atau bot.';
  }

  @override
  String credentialsTokenNarrowScope(String scope) {
    return 'Token ini tidak memiliki cakupan $scope, yang dibutuhkan untuk meninjau dan mengomentari. Buat token yang memilikinya.';
  }

  @override
  String get credentialsTokenExpired =>
      'Token ini sudah berakhir. Buat yang baru dan tempel di sini.';

  @override
  String get credentialsSignInRateLimited =>
      'Terlalu banyak permintaan saat ini. Tunggu sebentar, lalu coba lagi.';

  @override
  String get credentialsSignInCancelled =>
      'Proses masuk dibatalkan atau ditolak. Mulai lagi saat Anda siap.';

  @override
  String get credentialsSignInNoLongerOpen =>
      'Proses masuk ini sudah tidak terbuka: dibatalkan, sudah dipakai, atau diganti. Mulai lagi.';

  @override
  String get noWorkspacesYetHint =>
      'Admin ruang kerja harus mengundang Anda, atau pemilik server dapat membuatkan ruang kerja untuk Anda.';

  @override
  String repoAccessReplaced(String repos, String forge) {
    return '$repos sekarang mengarah ke repositori lain di $forge. Tautkan ulang dari aplikasi desktop atau web agar tetap bisa digunakan.';
  }

  @override
  String repoAccessAskAdminRelink(String repos, String forge) {
    return '$repos sekarang mengarah ke repositori lain di $forge. Admin ruang kerja harus menautkannya ulang sebelum dapat digunakan lagi.';
  }

  @override
  String get runSandboxUnavailableTitle =>
      'Agen memerlukan sandbox di server ini';

  @override
  String get runSandboxUnavailable =>
      'Server ini tidak memiliki sandbox, sehingga hanya pemiliknya yang dapat menjalankan agen di sini. Pemilik dapat memasang sandbox atau mematikan sandboxing untuk semua orang.';

  @override
  String get scriptToolCalls => 'Panggilan alat';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count panggilan',
      one: '1 panggilan',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count berjalan';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count berhasil';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count gagal';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count ditolak';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count dibatalkan';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count antre';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count dilewati';
  }

  @override
  String get scriptStepQueued => 'Dalam antrean';

  @override
  String get scriptStepSkipped => 'Dilewati';

  @override
  String get scriptGroupLoop => 'Loop';

  @override
  String get scriptGroupEach => 'Untuk setiap';

  @override
  String get scriptGroupParallel => 'Secara paralel';

  @override
  String get scriptGroupFunction => 'Fungsi';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tampilkan $count panggilan lagi',
      one: 'Tampilkan 1 panggilan lagi',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced =>
      'Panggilan yang tidak ditempatkan dalam skrip';

  @override
  String get scriptToolComputed => 'Alat';

  @override
  String scriptStepSemantics(String subject, String state) {
    return '$subject, $state';
  }

  @override
  String get scriptSourceLabel => 'Skrip';

  @override
  String scriptSourceLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count baris',
      one: '1 baris',
    );
    return '$_temp0';
  }

  @override
  String get scriptStateRunning => 'Berjalan';

  @override
  String get scriptStateCompleted => 'Selesai';

  @override
  String get scriptStateFailed => 'Gagal';

  @override
  String get scriptStateTimedOut => 'Waktu habis';

  @override
  String get scriptStateCancelled => 'Dibatalkan';

  @override
  String get scriptStateMemoryExceeded => 'Kehabisan memori';

  @override
  String get scriptStateOutputExceeded => 'Output terlalu banyak';

  @override
  String get scriptStateSandboxError => 'Error sandbox';

  @override
  String get scriptStateRefused => 'Ditolak';

  @override
  String get scriptOriginLine => 'Dari skrip yang dijalankan agen';

  @override
  String get codeModeTitle => 'Mode kode';

  @override
  String get codeModeAvailable => 'Tersedia';

  @override
  String get codeModeUnavailable => 'Tidak tersedia';

  @override
  String codeModeUnavailableNote(String reason) {
    return 'Server ini tidak bisa menjalankan skrip, jadi agen di sini memanggil alatnya satu per satu. Kata server: $reason';
  }

  @override
  String get codeModeNoReason => 'tidak ada alasan yang diberikan.';

  @override
  String get workKindUnknown => 'Karena alasan yang tidak dikenali versi ini:';

  @override
  String get workRefusalUnknown => 'Server menolak ini:';

  @override
  String workActionFailed(String error) {
    return 'Tidak berhasil: $error';
  }

  @override
  String get wakeKindStopped => 'Ditahan karena seseorang menghentikan run.';

  @override
  String get wakeKindAttempts => 'Pengiriman gagal tiga kali.';

  @override
  String get wakeKindAgentDeleted => 'Agen itu sudah tidak ada.';

  @override
  String get wakeKindAgentNotDispatchable => 'Agen itu sudah dipensiunkan.';

  @override
  String get wakeKindAgentPaused => 'Agen itu sedang dijeda.';

  @override
  String get wakeKindPersonRemoved =>
      'Orang yang diwakilinya sudah keluar dari ruang kerja.';

  @override
  String get wakeKindBudgetBlocked => 'Anggaran memblokir run.';

  @override
  String get wakeKindTakeOver => 'Seseorang sudah mengambil alih pohon kerja.';

  @override
  String get wakeKindRateCapConversation =>
      'Percakapan ini memulai 30 run dari pengingat dalam satu jam terakhir.';

  @override
  String get wakeKindRateCapWorkspace =>
      'Ruang kerja ini memulai 300 run dari pengingat dalam satu jam terakhir.';

  @override
  String get wakeKindLiveRunNoInput =>
      'Run langsung agen di sini tidak menerima input.';

  @override
  String get wakeKindLiveRunOtherOptions =>
      'Run langsung agen di sini berjalan dengan opsi berbeda, jadi ini memulai run sendiri setelahnya.';

  @override
  String get wakeKindLiveRunOtherPerson =>
      'Run langsung agen di sini bertindak untuk orang lain, jadi ini memulai run sendiri setelahnya.';

  @override
  String get wakeKindDispatchRefused => 'Run tidak dapat dimulai.';

  @override
  String get wakeKindSandboxUnavailable =>
      'Tidak ada sandbox untuk run hanya baca.';

  @override
  String get wakeKindReadOnlyUnavailable =>
      'Backend agen ini tidak dapat menjalankan run hanya baca.';

  @override
  String get wakeKindServerStopped => 'Restart server menghentikan run.';

  @override
  String get wakeKindServerRestarted => 'Server restart saat run seseorang.';

  @override
  String get wakeKindGuardFailed => 'Pemeriksaan sebelum pengiriman gagal.';

  @override
  String get wakeKindLimit => 'Menunggu batas penggunaan penyedia direset.';

  @override
  String get wakeKindLimitRunLive =>
      'Menunggu run di batas penggunaan selesai.';

  @override
  String get wakeKindWakeMissed => 'Terlewat saat server mati.';

  @override
  String get wakeKindPipelineRunEnded => 'Run pipeline-nya sudah selesai.';

  @override
  String get wakeKindGoalEnded => 'Tujuannya sudah berakhir.';

  @override
  String get wakeKindGoalBudgetExhausted =>
      'Tujuannya sudah menghabiskan anggarannya.';

  @override
  String get wakeKindGoalReviewStale =>
      'Tujuan berubah sejak tinjauan ini diminta.';

  @override
  String get wakeKindGoalPaused => 'Tujuannya sedang dijeda.';

  @override
  String get wakeKindGoalHeld => 'Tujuannya sedang ditahan.';

  @override
  String get wakeKindGoalStopped => 'Tujuannya dihentikan.';

  @override
  String get wakeKindAskSettled =>
      'Pertanyaan yang dijawabnya sudah diselesaikan.';

  @override
  String get wakeKindRuleEnded => 'Jadwalnya sudah berakhir.';

  @override
  String get wakeRefusalNotYours =>
      'Pengingat ini bertindak untuk orang lain. Hanya mereka yang dapat mengirim atau melanjutkannya.';

  @override
  String get wakeRefusalSettled => 'Pengingat ini sudah selesai.';

  @override
  String get goalRefusalAlreadyActive =>
      'Agen ini sudah memiliki tujuan aktif.';

  @override
  String get goalRefusalNotInReview =>
      'Tujuan ini tidak sedang menunggu tinjauan.';

  @override
  String get goalRefusalEvidenceIncomplete => 'Bukti tujuan ini belum lengkap.';

  @override
  String get goalRefusalClaimPending =>
      'Klaim bahwa tujuan sudah selesai masih diperiksa.';

  @override
  String get goalRefusalNotActiveSegment =>
      'Tujuan ini tidak punya segmen yang sedang berjalan.';

  @override
  String get goalRefusalNotYours =>
      'Hanya orang yang memulai tujuan ini yang dapat melakukannya.';

  @override
  String get goalRefusalNotPaused => 'Jeda tujuan ini terlebih dahulu.';

  @override
  String get goalRefusalContractInvalid =>
      'Kontrak tujuan ini tidak dapat dibaca.';

  @override
  String get goalRefusalCheckerUnknown => 'Tidak ada agen dengan nama itu.';

  @override
  String get goalRefusalCheckerAmbiguous =>
      'Ada lebih dari satu agen dengan nama itu.';

  @override
  String get goalRefusalCheckerIsGoalAgent =>
      'Pemeriksa harus agen lain selain agen yang mengerjakan.';

  @override
  String get goalRefusalCommandInvalid => 'Tujuan ini tidak dapat dibaca:';

  @override
  String get wakeRuleRefusalIntervalTooShort =>
      'Intervalnya terlalu pendek. Pilih minimal satu menit.';

  @override
  String get wakeRuleRefusalTooSoon =>
      'Waktu itu terlalu cepat. Pilih waktu yang lebih nanti.';

  @override
  String get wakeRuleRefusalLineageEnded =>
      'Rangkaian pengingat ini sudah menghabiskan run atau waktunya.';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable =>
      'Anda tidak dapat membaca apa yang akan dipantau ini.';

  @override
  String get wakeRuleRefusalExpiryRequired =>
      'Beri tanggal berakhir atau jumlah run.';

  @override
  String get wakeRuleRefusalLimitReached =>
      'Percakapan atau agen ini sudah memiliki jumlah jadwal maksimum.';

  @override
  String get wakeRuleRefusalInvalidWhen => 'Waktunya tidak dapat dibaca.';

  @override
  String get wakeRuleRefusalNoteTooLong => 'Catatannya terlalu panjang.';

  @override
  String get wakeRuleRefusalExpiryTooLong => 'Batas akhirnya terlalu jauh.';

  @override
  String get wakeRuleRefusalLimitOutOfRange =>
      'Batas run, hari, atau anggaran di luar rentang.';

  @override
  String get wakeRuleRefusalNextOutsideLoop =>
      'Hanya loop yang dapat menentukan waktu berikutnya sendiri.';

  @override
  String get wakeRuleRefusalWatchRefused => 'Itu tidak dapat dipantau.';

  @override
  String get wakeRuleRefusalRuleEnded => 'Jadwal itu sudah berakhir.';

  @override
  String get wakeRuleRefusalNotYours => 'Jadwal itu milik orang lain.';

  @override
  String get wakeRuleEndFired => 'Sudah dijalankan sekali.';

  @override
  String get wakeRuleEndExpired => 'Sudah mencapai tanggal berakhirnya.';

  @override
  String get wakeRuleEndRunCap => 'Batas run-nya sudah habis.';

  @override
  String get wakeRuleEndCostCap => 'Sudah mencapai batas biayanya.';

  @override
  String get wakeRuleEndGoalEnded => 'Tujuannya sudah berakhir.';

  @override
  String get wakeRuleEndCancelled => 'Dibatalkan.';

  @override
  String get wakeRuleEndMemberRemoved =>
      'Orang yang diwakilinya sudah keluar dari ruang kerja.';

  @override
  String get wakeRuleEndInvalidRow =>
      'Pengaturan yang tersimpan tidak dapat dibaca.';

  @override
  String goalHoldWorking(int segment) {
    final intl.NumberFormat segmentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String segmentString = segmentNumberFormat.format(segment);

    return 'Sedang mengerjakan segmen $segmentString. Tidak ada yang perlu dilakukan.';
  }

  @override
  String get goalHoldWaiting =>
      'Menunggu pekerjaan yang menjadi haknya. Akan lanjut sendiri.';

  @override
  String goalHoldWaitingUntil(String time) {
    return 'Menunggu pekerjaan yang menjadi haknya. Akan lanjut sendiri paling lambat pada $time.';
  }

  @override
  String get goalHoldVerifying =>
      'Tujuan menyatakan sudah selesai. Server menjalankan pemeriksaannya, lalu seorang peninjau memutuskan.';

  @override
  String get goalHoldLimit =>
      'Dijeda di batas penggunaan penyedia. Akan lanjut sendiri setelah batas direset.';

  @override
  String goalHoldLimitUntil(String time) {
    return 'Dijeda di batas penggunaan penyedia. Akan lanjut sendiri pada $time.';
  }

  @override
  String get goalHoldPerson =>
      'Menunggu seseorang menjawab di percakapan. Akan lanjut setelah ada yang menjawab.';

  @override
  String get goalHoldByPerson =>
      'Dijeda oleh seseorang. Tetap dijeda sampai ada yang melanjutkannya.';

  @override
  String get goalHoldNeedsReview =>
      'Menunggu tinjauan: tidak bisa lanjut sendiri. Setujui sebagai selesai, lanjutkan, atau batalkan.';

  @override
  String get goalHoldBudget =>
      'Anggarannya sudah habis. Naikkan anggaran agar bisa lanjut.';

  @override
  String goalHoldLimitParks(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Jeda karena batas penggunaan: $countString dari $maxString';
  }

  @override
  String get goalHoldDetailStalled =>
      'Tidak ada kemajuan pada segmen terakhirnya.';

  @override
  String get goalHoldDetailStalledWaiting =>
      'Menunggu 24 jam untuk pekerjaan yang sama tanpa kemajuan.';

  @override
  String get goalHoldDetailVerificationFailed => 'Pemeriksaan terakhir gagal.';

  @override
  String get goalHoldDetailCannotVerify =>
      'Pemeriksa tidak dapat memastikan apakah sudah selesai.';

  @override
  String get goalHoldDetailSandboxUnavailable =>
      'Tidak ada sandbox untuk menjalankan pemeriksaannya.';

  @override
  String get goalHoldDetailCheckerUnavailable =>
      'Agen pemeriksanya tidak tersedia. Pilih pemeriksa lain, lalu lanjutkan.';

  @override
  String get goalHoldDetailCheckBroken =>
      'Pemeriksaan ini tidak dapat dijalankan:';

  @override
  String get goalHoldDetailWakeSkipped => 'Pengingatnya tidak dikirim.';

  @override
  String get goalHoldDetailClaimPending =>
      'Klaimnya bahwa sudah selesai menunggu pemeriksaan.';

  @override
  String get goalHoldDetailUnanswered =>
      'Pertanyaan atau permintaan persetujuan kepada seseorang belum dijawab.';

  @override
  String get goalHoldDetailLimitParks =>
      'Terlalu sering mencapai batas penggunaan. Periksa dulu, lalu lanjutkan.';

  @override
  String get goalHoldDetailInput => 'Menunggu jawaban dalam percakapan.';

  @override
  String goalSegments(int run, int max) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Segmen $runString dari $maxString';
  }

  @override
  String goalSegmentsNoCap(int run) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);

    return 'Segmen $runString, tanpa batas';
  }

  @override
  String goalMoney(String spent, String cap) {
    return 'Terpakai $spent dari $cap';
  }

  @override
  String goalDeadline(String time) {
    return 'Tenggat $time';
  }

  @override
  String get goalPipelineStep =>
      'Sebuah langkah pipeline mengerjakan tujuan ini.';

  @override
  String get goalSummaryHeading => 'Ringkasan terakhir';

  @override
  String get goalDoneMeans => 'Artinya selesai';

  @override
  String get goalChecks => 'Pemeriksaan';

  @override
  String get goalBoundaries => 'Batasan';

  @override
  String get goalStopWhen => 'Berhenti dan tanya saat';

  @override
  String get goalNoMachineCheck =>
      'Tidak ada pemeriksaan otomatis. Peninjau menilai dari apa yang bisa dibacanya.';

  @override
  String get goalCheckEnvironment => 'Tugas lingkungan';

  @override
  String goalLastCheck(int round, String time) {
    final intl.NumberFormat roundNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String roundString = roundNumberFormat.format(round);

    return 'Pemeriksaan terakhir, putaran $roundString, $time';
  }

  @override
  String get goalClaim => 'Klaim yang dibuatnya';

  @override
  String get goalCheckPassed => 'Lulus';

  @override
  String goalCheckFailed(int code) {
    return 'Gagal, exit $code';
  }

  @override
  String get goalCheckTimedOut => 'Waktu habis';

  @override
  String get goalCheckNotRerun =>
      'Tidak dijalankan ulang: tidak ada yang berubah';

  @override
  String get goalCheckBroken => 'Tidak dapat dijalankan';

  @override
  String get goalCriterionMet => 'Terpenuhi';

  @override
  String get goalCriterionUnmet => 'Belum terpenuhi';

  @override
  String get goalCriterionCannotTell => 'Tidak dapat dipastikan';

  @override
  String get goalVerdictPass => 'Keputusan: selesai';

  @override
  String get goalVerdictFail => 'Keputusan: belum selesai';

  @override
  String get goalVerdictCannotVerify => 'Keputusan: tidak dapat dipastikan';

  @override
  String get goalConcerns => 'Kekhawatiran';

  @override
  String goalVerifiedBy(String agent) {
    return 'Diverifikasi oleh $agent';
  }

  @override
  String get goalVerifiedBySelf =>
      'Diverifikasi oleh dirinya sendiri (tanpa pemeriksa terpisah)';

  @override
  String get goalClosedByPerson =>
      'Ditutup oleh seseorang tanpa pemeriksaan yang lulus';

  @override
  String get goalApprove => 'Setujui penyelesaian';

  @override
  String get goalApproveTitle => 'Tutup tujuan ini sebagai selesai?';

  @override
  String get goalApproveBody =>
      'Tidak ada pemeriksaan yang mengonfirmasinya. Anda menutupnya berdasarkan keyakinan Anda sendiri, dan tujuan mencatat bahwa seseorang menutupnya tanpa verifikasi.';

  @override
  String get goalApproveConfirm => 'Tutup sebagai selesai';

  @override
  String get goalResumeNotYours =>
      'Melanjutkan atau menaikkan anggarannya menjadi hak orang yang memulainya.';

  @override
  String get goalChooseChecker => 'Pilih pemeriksa lain';

  @override
  String goalCheckerSet(String agent) {
    return '$agent sekarang memeriksanya. Lanjutkan untuk memverifikasi lagi.';
  }

  @override
  String get goalSchedules => 'Jadwal';

  @override
  String get goalRepeat => 'Ulangi';

  @override
  String get goalCreateChecks => 'Pemeriksaan (opsional)';

  @override
  String get goalCreateCheckHint =>
      'Perintah yang lulus saat pekerjaan selesai';

  @override
  String get goalCreateAddCheck => 'Tambah pemeriksaan';

  @override
  String get goalCreateRemoveCheck => 'Hapus pemeriksaan';

  @override
  String get goalCreateSegmentCap => 'Batas segmen (opsional)';

  @override
  String get goalCreateSegmentInvalid =>
      'Batas segmen harus bilangan bulat, minimal 1.';

  @override
  String get scheduleCreateTitle => 'Ulangi sebuah perintah';

  @override
  String get scheduleCadence => 'Seberapa sering';

  @override
  String get scheduleEveryMinutes => 'Setiap N menit';

  @override
  String get scheduleEveryHours => 'Setiap N jam';

  @override
  String get scheduleSelfPaced => 'Atur sendiri';

  @override
  String get scheduleSelfPacedHint =>
      'Agen memilih jeda setelah setiap run, antara 1 menit dan 1 jam.';

  @override
  String get scheduleInterval => 'Interval';

  @override
  String get scheduleNote => 'Apa yang harus dilakukan setiap run?';

  @override
  String get scheduleCostCap => 'Batas biaya dalam USD (opsional)';

  @override
  String get scheduleExpiryDays => 'Berakhir setelah N hari (opsional)';

  @override
  String get scheduleCreateInvalid =>
      'Pilih space dan agen, tulis apa yang harus dilakukan setiap run, dan isi angka bulat minimal 1.';

  @override
  String get scheduleCreateButton => 'Mulai jadwal';

  @override
  String get scheduleCreateConfirmTitle => 'Mulai jadwal ini?';

  @override
  String scheduleCreateConfirmEveryMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Berjalan setiap $countString menit, mulai sekarang.',
      one: 'Berjalan setiap menit, mulai sekarang.',
    );
    return '$_temp0';
  }

  @override
  String scheduleCreateConfirmEveryHours(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Berjalan setiap $countString jam, mulai sekarang.',
      one: 'Berjalan setiap jam, mulai sekarang.',
    );
    return '$_temp0';
  }

  @override
  String get scheduleCreateConfirmSelfPaced =>
      'Berjalan sekarang, lalu agen memilih kapan berjalan lagi.';

  @override
  String get scheduleCreated =>
      'Jadwal dimulai. Jadwal ini tercantum di Jadwal.';

  @override
  String get schedulesTitle => 'Jadwal';

  @override
  String get schedulesLoadFailed => 'Jadwal tidak dapat dimuat';

  @override
  String get schedulesEmpty => 'Tidak ada jadwal atau pantauan';

  @override
  String get schedulesEmptyDescription =>
      'Ulangi perintah dari layar tujuan, atau kirim /loop atau /schedule di sebuah percakapan.';

  @override
  String get scheduleMissing =>
      'Jadwal ini tidak lagi tersedia di ruang kerja ini.';

  @override
  String scheduleEvery(String interval) {
    return 'Setiap $interval';
  }

  @override
  String get scheduleSelfPacedLoop => 'Loop atur sendiri';

  @override
  String get scheduleCron => 'Jadwal cron';

  @override
  String scheduleOnce(String time) {
    return 'Sekali pada $time';
  }

  @override
  String scheduleWatch(String event) {
    return 'Pantau: $event';
  }

  @override
  String get scheduleWatchPrChecks => 'pemeriksaan pull request';

  @override
  String get scheduleWatchPrReview => 'tinjauan pull request';

  @override
  String get scheduleWatchPrMerged => 'merge pull request';

  @override
  String get scheduleWatchEnvironment => 'lingkungan';

  @override
  String get scheduleWatchTicket => 'tiket';

  @override
  String get scheduleWatchPipelineRun => 'run pipeline';

  @override
  String get scheduleStatusActive => 'Aktif';

  @override
  String get scheduleStatusPaused => 'Dijeda';

  @override
  String get scheduleStatusEnded => 'Berakhir';

  @override
  String scheduleWakes(String agent) {
    return 'Membangunkan $agent';
  }

  @override
  String scheduleNext(String time) {
    return 'Run berikutnya $time';
  }

  @override
  String scheduleLast(String time) {
    return 'Run terakhir $time';
  }

  @override
  String scheduleRuns(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString run',
      one: '1 run',
    );
    return '$_temp0';
  }

  @override
  String scheduleRunsOf(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return '$countString dari $maxString run';
  }

  @override
  String scheduleSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString dilewati',
      one: '1 dilewati',
    );
    return '$_temp0';
  }

  @override
  String scheduleEnds(String time) {
    return 'Berakhir $time';
  }

  @override
  String scheduleChain(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Bagian dari rangkaian: sisa $countString run, berakhir $time';
  }

  @override
  String get scheduleNoteAgent => 'Catatan agen sendiri, dengan kata-katanya:';

  @override
  String get scheduleNotePerson => 'Catatan seseorang:';

  @override
  String scheduleActsFor(String name) {
    return 'Bertindak untuk $name';
  }

  @override
  String get scheduleActsForBot => 'Tidak bertindak untuk siapa pun';

  @override
  String get scheduleGoalBound => 'Berakhir bersama tujuannya.';

  @override
  String get schedulePause => 'Jeda';

  @override
  String get scheduleResume => 'Lanjutkan';

  @override
  String get scheduleDelete => 'Hapus';

  @override
  String get scheduleRemove => 'Hapus';

  @override
  String get scheduleDeleteTitle => 'Hapus jadwal ini?';

  @override
  String get scheduleDeleteBody =>
      'Jadwal berhenti untuk selamanya. Apa pun yang sudah dilakukannya tidak dibatalkan.';

  @override
  String get scheduleRemoveTitle => 'Hapus jadwal ini?';

  @override
  String get scheduleRemoveBody => 'Jadwal hilang dari daftar.';

  @override
  String get scheduleResumeNotYours =>
      'Hanya orang yang diwakili jadwal ini yang dapat melanjutkannya.';

  @override
  String get scheduleResumeAdminOnly =>
      'Hanya admin ruang kerja yang dapat melanjutkan jadwal yang tidak dimiliki siapa pun.';

  @override
  String get scheduleOpenConversation => 'Buka percakapan';

  @override
  String get progressWaiting => 'Menunggu';

  @override
  String get progressNothingWaiting => 'Tidak ada yang menunggu.';

  @override
  String get wakeOriginGoal => 'Tujuan';

  @override
  String get wakeOriginGoalCheck => 'Pemeriksaan tujuan';

  @override
  String get wakeOriginGoalReview => 'Tinjauan tujuan';

  @override
  String get wakeOriginSchedule => 'Jadwal';

  @override
  String get wakeOriginWatch => 'Pantauan';

  @override
  String get wakeOriginReply => 'Balasan';

  @override
  String get wakeOriginMessage => 'Pesan';

  @override
  String get wakeOriginWorkFinished => 'Pekerjaan selesai';

  @override
  String get wakeOriginLimitReset => 'Batas direset';

  @override
  String get wakeOriginRecovery => 'Pemulihan';

  @override
  String get wakeOriginAssignment => 'Penugasan';

  @override
  String get wakeOriginPipelineStep => 'Langkah pipeline';

  @override
  String get wakeOriginImprovementReview => 'Tinjauan perbaikan';

  @override
  String wakeOriginReplyFrom(String agent) {
    return 'Balasan dari $agent';
  }

  @override
  String wakeOriginMessageFrom(String agent) {
    return 'Pesan dari $agent';
  }

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return 'Pekerjaan selesai dari $agent';
  }

  @override
  String wakeFor(String agent) {
    return 'Untuk $agent';
  }

  @override
  String wakeDue(String time) {
    return 'Jatuh tempo $time';
  }

  @override
  String get wakeDueNow => 'Jatuh tempo sekarang';

  @override
  String get wakeHeld => 'Ditahan';

  @override
  String wakeExpires(String time) {
    return 'Berakhir $time';
  }

  @override
  String wakeAttempt(int attempt) {
    final intl.NumberFormat attemptNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attemptString = attemptNumberFormat.format(attempt);

    return 'Percobaan $attemptString';
  }

  @override
  String get wakeCancel => 'Batal';

  @override
  String get wakeDeliverNow => 'Kirim sekarang';

  @override
  String get wakeResume => 'Lanjutkan';

  @override
  String get wakeDismiss => 'Abaikan';

  @override
  String get wakeResumeOnlyTheirs =>
      'Hanya orang yang run-nya ini yang dapat melanjutkannya.';

  @override
  String get wakeRecovery =>
      'Server di-restart saat run ini. Lanjutkan untuk meneruskannya, atau abaikan.';

  @override
  String limitParkTitle(String provider, String time) {
    return 'Dijeda di batas penggunaan $provider, yang diatur ulang pada $time. Run menunggu Lanjutkan, hingga 7 hari setelah reset.';
  }

  @override
  String limitParkTitleUnnamed(String time) {
    return 'Dijeda di batas penggunaan penyedia, yang diatur ulang pada $time. Run menunggu Lanjutkan, hingga 7 hari setelah reset.';
  }

  @override
  String get limitParkResumeNow => 'Lanjutkan sekarang';

  @override
  String get limitParkCancel => 'Batal';

  @override
  String limitParkResumed(String provider) {
    return 'Dilanjutkan setelah batas penggunaan $provider.';
  }

  @override
  String limitParkGone(String provider) {
    return 'Tidak lagi menunggu di batas penggunaan $provider.';
  }

  @override
  String get limitParkProviderUnknown => 'penyedia';

  @override
  String get mobileHeldMessages => 'Pesan yang ditahan';

  @override
  String get heldSteeringTitle =>
      'Ditahan karena run berakhir sebelum sempat mengambilnya. Kirim pesan Anda sekarang atau hapus.';

  @override
  String get heldSteeringRelease => 'Kirim pesan yang ditahan';

  @override
  String get notifGoalCompleted => 'Tujuan selesai';

  @override
  String get notifGoalFailed => 'Tujuan gagal';

  @override
  String get notifGoalCancelled => 'Tujuan dibatalkan';

  @override
  String get notifGoalBudgetExhausted => 'Tujuan menghabiskan anggarannya';

  @override
  String get notifGoalNeedsReview => 'Sebuah tujuan menunggu tinjauan Anda';

  @override
  String get notifGoalNeedsPerson => 'Sebuah tujuan membutuhkan Anda';

  @override
  String get notifGoalOnHold => 'Sebuah tujuan sedang ditahan';

  @override
  String get notifWakeRuleEnded => 'Sebuah jadwal berakhir';

  @override
  String notifWaitingDigest(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString hal menunggu Anda',
      one: '1 hal menunggu Anda',
    );
    return '$_temp0';
  }

  @override
  String notifImprovementProposed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString perbaikan diusulkan',
      one: 'Sebuah perbaikan diusulkan',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld =>
      'Sebuah run pipeline ditahan di anggarannya';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return 'Terpakai $spent dari $cap';
  }

  @override
  String get notifNeedsYou => 'Perlu Anda';

  @override
  String get notifDigestGoalReview => 'Tujuan menunggu tinjauan';

  @override
  String get notifDigestGoalPerson => 'Tujuan membutuhkan seseorang';

  @override
  String get notifDigestHeldWake => 'Pengingat ditahan';

  @override
  String get notifDigestImprovement => 'Perbaikan yang diusulkan';

  @override
  String get wakeKindRulePaused => 'Jadwalnya dijeda.';

  @override
  String get wakeKindRuleBusy =>
      'Agen sedang sibuk, dan jadwal ini melewati waktu saat agen sedang sibuk.';

  @override
  String get wakeKindRuleFolded =>
      'Peristiwa lain dari pantauan yang sama menggantikannya.';

  @override
  String get wakeKindRuleSuperseded =>
      'Waktu terjadwal yang lebih baru menggantikannya.';

  @override
  String get wakeKindRuleNotified =>
      'Jadwalnya hanya mengirim notifikasi, jadi tidak ada run yang dimulai.';

  @override
  String get wakeKindRuleLimitParked =>
      'Jadwalnya menunggu batas penggunaan penyedia direset.';

  @override
  String get improvementRefusalCooldown =>
      'Tinjauan perbaikan berjalan di percakapan ini tidak lama tadi. Coba lagi nanti.';

  @override
  String get improvementRefusalQueued =>
      'Tinjauan perbaikan percakapan ini sudah menunggu untuk dijalankan.';

  @override
  String get improvementRefusalAgentNotFound =>
      'Agen itu bukan agen di ruang kerja ini.';

  @override
  String get steeringRefusalHeldByLimit =>
      'Pesan yang ditahan di batas penggunaan tidak dapat dikirim secara manual. Pesan menunggu run yang dijeda dilanjutkan.';

  @override
  String limitParkCancelled(String provider) {
    return 'Tunggu di batas penggunaan $provider dibatalkan.';
  }

  @override
  String limitParkExpired(String provider) {
    return 'Tunggu di batas penggunaan $provider kedaluwarsa sebelum run dilanjutkan.';
  }

  @override
  String limitParkSkipped(String provider) {
    return 'Run tidak dilanjutkan setelah batas penggunaan $provider.';
  }

  @override
  String get heldSteeringLimitTitle =>
      'Ditahan selama run menunggu batas penggunaan diatur ulang. Pesan ini dikirim saat orang yang diwakili run melanjutkannya.';

  @override
  String heldSteeringLimitAt(String time) {
    return 'Ditahan hingga batas penggunaan diatur ulang pada $time. Pesan ini dikirim saat orang yang diwakili run melanjutkannya.';
  }

  @override
  String get heldSteeringOtherTitle =>
      'Ditahan oleh server. Anda dapat menghapusnya.';

  @override
  String workRowWoke(int count, String agent) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Membangunkan $agent untuk $countString item menunggu',
      one: 'Membangunkan $agent',
    );
    return '$_temp0';
  }

  @override
  String workRowWakeMissed(String agent) {
    return 'Pengingat untuk $agent terlewat saat server mati.';
  }

  @override
  String workRowWakeSkipped(String agent) {
    return 'Pengingat untuk $agent tidak dikirim.';
  }

  @override
  String workRowScheduleCreated(String agent) {
    return 'Jadwal diatur untuk $agent.';
  }

  @override
  String workRowScheduleEnded(String agent) {
    return 'Jadwal $agent berakhir.';
  }

  @override
  String workRowNoteFromAgent(String agent) {
    return 'Catatan jadwal dari $agent:';
  }

  @override
  String get workRowNoteFromPerson => 'Catatan jadwal dari seseorang:';

  @override
  String workRowCommandRefusedNamed(String command) {
    return 'Perintah $command ditolak.';
  }

  @override
  String get workRowCommandRefused => 'Sebuah perintah ditolak.';

  @override
  String workRowCapRaised(String person, String from, String to) {
    return '$person menaikkan batas pengeluaran pipeline dari $from menjadi $to.';
  }

  @override
  String workRowCapRaisedNoAmounts(String person) {
    return '$person menaikkan batas pengeluaran pipeline.';
  }

  @override
  String get workRowApplyIncomplete =>
      'Perubahan yang diterima pada skill ini tidak dapat diselesaikan, karena skill berubah sementara itu. Usulan dikembalikan.';

  @override
  String get workRowOpenSchedule => 'Buka jadwal';

  @override
  String get heldSteeringOthersTitle =>
      'Ditahan karena run berakhir sebelum sempat mengambilnya. Hanya orang yang menulis pesan yang dapat mengirimnya.';

  @override
  String get heldSteeringOnlyYours =>
      'Hanya mengirim pesan Anda. Yang lain menunggu orang yang menulisnya.';

  @override
  String heldSteeringWrittenBy(String name) {
    return 'Ditulis oleh $name';
  }

  @override
  String get steeringRefusalNotYours =>
      'Hanya orang yang menulis pesan yang ditahan yang dapat mengirimnya, dan tidak ada yang ini milik Anda.';

  @override
  String get steeringRefusalNeedsWrite =>
      'Anda memerlukan akses tulis ke repositori space ini untuk mengarahkan run yang bertindak untuk orang lain.';

  @override
  String workRowSchedulePaused(String name, String agent) {
    return '$name menjeda jadwal untuk $agent.';
  }

  @override
  String get goalVerdictObjective => 'Sasaran secara keseluruhan';

  @override
  String get notifDigestRequest => 'Menunggu jawaban Anda';
}
