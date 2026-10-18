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
  String get permissionPrPublish => 'Publikasikan pull request';

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
  String get permissionRemembered => 'Persetujuan tersimpan';

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
  String get permissionRevokeBeforeEdit =>
      'Cabut aturan bercakupan atau aturan tersimpan sebelum menetapkan aturan umum untuk tindakan ini.';

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
  String get mobileGoalGoal => 'Tujuan';

  @override
  String get mobileGoalLoop => 'Siklus';

  @override
  String mobileGoalKind(String kind) {
    return 'Jenis: $kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return '$count run';
  }

  @override
  String get mobileGoalNoRunLimit => 'tanpa batas';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return 'Run: $runs / $maxRuns · Terpakai: $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return 'Batas waktu: $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return 'Run gagal berturut-turut: $count';
  }

  @override
  String get mobileGoalSummary => 'Ringkasan penyelesaian';

  @override
  String get mobileGoalFailedDescription =>
      'Pengawas berhenti setelah beberapa run gagal. Lihat percakapan untuk detailnya.';

  @override
  String get mobileGoalBudgetWall =>
      'Batas waktu atau jumlah run telah tercapai. Tujuan ini tidak dapat dilanjutkan dengan menaikkan batas biaya.';

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
  String get activityTicket => 'Pembaruan tiket';

  @override
  String get activityMeeting => 'Pembaruan rapat';

  @override
  String get activityCalendar => 'Koneksi kalender';

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
  String get credentialsRedirectUnavailable =>
      'Callback browser server ini tidak dapat diakses secara aman dari ponsel. Minta pemilik server mengatur callback HTTPS publik, atau tambahkan token sebagai gantinya.';

  @override
  String get credentialsUpdateToken => 'Perbarui token';

  @override
  String get credentialsAddToken => 'Tambah token';

  @override
  String get credentialsPersonalToken => 'Token akses pribadi';

  @override
  String get credentialsPersonalTokenHint => 'Tempel token akses pribadi';

  @override
  String get credentialsHostManaged =>
      'Koneksi ini berasal dari aplikasi server atau lingkungannya. Hanya pemilik server yang dapat mengubahnya di sana; Anda tetap dapat menambahkan token sendiri.';

  @override
  String get credentialsStopWatching => 'Berhenti memantau';
}
