// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Kembali';

  @override
  String get cancel => 'Batal';

  @override
  String get retry => 'Cuba semula';

  @override
  String get tryAgain => 'Cuba lagi';

  @override
  String get settings => 'Tetapan';

  @override
  String get refresh => 'Muat semula';

  @override
  String get approve => 'Luluskan';

  @override
  String get deny => 'Tolak';

  @override
  String get continueLabel => 'Teruskan';

  @override
  String get agentQuestionHeader => 'Soalan untuk anda';

  @override
  String get agentQuestionAnsweredLabel => 'Dijawab';

  @override
  String get agentQuestionSkip => 'Langkau';

  @override
  String get agentQuestionSkippedLabel => 'Dilangkau';

  @override
  String get agentQuestionFreeformHint => 'Taip jawapan anda…';

  @override
  String get agentApprovalRequired => 'Kelulusan diperlukan';

  @override
  String get approveAndRemember => 'Luluskan selama 8 jam';

  @override
  String get decline => 'Menolak';

  @override
  String get confirm => 'Sahkan';

  @override
  String get send => 'Hantar';

  @override
  String get close => 'Tutup';

  @override
  String get expand => 'Kembangkan';

  @override
  String get zoomIn => 'Zum masuk';

  @override
  String get zoomOut => 'Zum keluar';

  @override
  String get resetZoom => 'Tetapkan semula zum';

  @override
  String get scanQrPrompt =>
      'Imbas kod QR dari Mac anda untuk pasangkan telefon ini.';

  @override
  String get scanQrHelp =>
      'Buka kamera dan halakannya ke QR yang dipaparkan dalam Control Center pada Mac anda. Telefon ini bersambung terus ke Mac anda melalui pautan peribadi.';

  @override
  String get connectingToMac => 'Menyambung ke Mac anda…';

  @override
  String get connectingDetail => 'Menjalin pautan langsung yang selamat.';

  @override
  String get identityChangedTitle => 'Identiti pelayan berubah';

  @override
  String get identityChangedBody =>
      'Pelayan ini tidak lagi sepadan dengan identiti yang disimpan semasa pemasangan. Itu boleh bermaksud pelayan dipasang semula — atau sesuatu memintas sambungan. Demi keselamatan, peranti ini tidak akan bersambung. Buang pasangan, kemudian imbas kod QR baharu dari Mac anda untuk pasangkan semula.';

  @override
  String get removePairing => 'Buang pasangan';

  @override
  String get couldntConnect => 'Tidak dapat disambungkan';

  @override
  String get pendingPairingTitle => 'Sambung ke pelayan ini?';

  @override
  String get pendingPairingBody =>
      'Satu pautan meminta Control Center untuk berpasangan dengan pelayan ini. Teruskan hanya jika anda sendiri yang memulakannya.';

  @override
  String get connect => 'Sambung';

  @override
  String get failureNotPaired =>
      'Belum berpasangan — imbas kod QR dari Mac anda';

  @override
  String get failureUnreachable =>
      'Tidak dapat mencapai pelayan pada mana-mana laluan — pastikan ia berjalan, atau cuba rangkaian yang sama';

  @override
  String get failureIdentityChanged =>
      'Identiti pelayan berubah — jika ia dipasang semula, pasangkan semula peranti ini';

  @override
  String get failureAuthRejected =>
      'Pelayan menolak peranti ini — pasangkan semula dari Mac anda';

  @override
  String get failureUnknown =>
      'Tidak dapat disambungkan — ketik untuk cuba semula';

  @override
  String get statusConnected => 'Disambungkan';

  @override
  String get statusConnecting => 'Menyambung';

  @override
  String get statusOffline => 'Luar talian';

  @override
  String get statusIdentityMismatch => 'Identiti tidak sepadan';

  @override
  String get statusNotPaired => 'Belum berpasangan';

  @override
  String get statusConfirmPairing => 'Sahkan pasangan';

  @override
  String get connectionFailed => 'Sambungan gagal';

  @override
  String get identityMismatchBanner =>
      'Identiti pelayan berubah — sambungan dihentikan. Pasangkan semula peranti ini untuk meneruskan.';

  @override
  String get tabInbox => 'Peti masuk';

  @override
  String get tabTickets => 'Tiket';

  @override
  String get tabChat => 'Sembang';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'Kalendar';

  @override
  String get tabNews => 'Berita';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count menunggu';
  }

  @override
  String get updateAvailable => 'Control Center baharu tersedia';

  @override
  String get appearance => 'Penampilan';

  @override
  String get language => 'Bahasa';

  @override
  String get device => 'Peranti';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Cerah';

  @override
  String get themeDark => 'Gelap';

  @override
  String get languageSystem => 'Sistem';

  @override
  String get disconnectTapAgain =>
      'Ketik lagi untuk putuskan peranti ini dari Mac anda';

  @override
  String get disconnectDevice => 'Putuskan peranti ini';

  @override
  String get disconnect => 'Putuskan';

  @override
  String get chooseWorkspace => 'Pilih ruang kerja';

  @override
  String get workspaces => 'Ruang kerja';

  @override
  String get workspacesLoadFailed => 'Tidak dapat memuatkan ruang kerja';

  @override
  String get noWorkspacesYet => 'Belum ada ruang kerja';

  @override
  String selectWorkspace(String name) {
    return 'Pilih $name';
  }

  @override
  String get inboxLoadFailed => 'Tidak dapat memuatkan peti masuk anda';

  @override
  String get allCaughtUp => 'Anda sudah mengejar semuanya';

  @override
  String get inboxNoForgeAccount =>
      'Tiada akaun forge disambungkan pada pelayan, jadi pull request belum dapat dikaitkan kepada anda.';

  @override
  String get inboxNothingWaiting =>
      'Tiada yang disekat dan tiada pull request menunggu anda.';

  @override
  String get blocked => 'Disekat';

  @override
  String get sectionNeedsYourReview => 'Memerlukan semakan anda';

  @override
  String get sectionReturnedToYou => 'Dipulangkan kepada anda';

  @override
  String get sectionApprovedAndReady => 'Diluluskan dan sedia';

  @override
  String get sectionYourDrafts => 'Draf anda';

  @override
  String get sectionWaitingForReviewers => 'Menunggu penyemak';

  @override
  String get sectionMergingAndMerged => 'Mencantum dan baru dicantum';

  @override
  String get sectionWaitingForAuthor => 'Menunggu pengarang';

  @override
  String waitingAgo(String ago) {
    return 'menunggu $ago';
  }

  @override
  String get openConversation => 'Buka perbualan';

  @override
  String get calendarLoadFailed => 'Tidak dapat memuatkan kalendar anda';

  @override
  String get nothingScheduled => 'Tiada jadual';

  @override
  String get calendarEmptyDescription =>
      'Acara dari kalendar yang disambungkan muncul di sini.';

  @override
  String get agenda => 'Agenda';

  @override
  String get syncCalendarsNow => 'Segerak kalendar sekarang';

  @override
  String get event => 'Acara';

  @override
  String get eventNotFound => 'Acara tidak dijumpai';

  @override
  String get eventNotFoundDescription =>
      'Ia mungkin di luar tetingkap agenda, atau telah dibuang di hulu.';

  @override
  String get joinMeeting => 'Sertai mesyuarat';

  @override
  String get join => 'Sertai';

  @override
  String attendeesCount(int count) {
    return 'Hadirin ($count)';
  }

  @override
  String get details => 'Butiran';

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
  String get attendeeNoReply => 'tiada balasan';

  @override
  String get organizer => 'penganjur';

  @override
  String get calendarNoAccounts =>
      'Tiada kalendar disambungkan untuk ruang kerja ini. Sambungkan satu dari apl desktop — log masuk menyimpan tokennya pada pelayan.';

  @override
  String get calendarReauthNeeded =>
      'Akaun kalendar perlu disambungkan semula — apa yang anda lihat di bawah mungkin lapuk. Sambungkan semula dari apl desktop.';

  @override
  String get spacesLoadFailed => 'Tidak dapat memuatkan ruang';

  @override
  String get noSpaces => 'Tiada ruang';

  @override
  String get spacesEmptyDescription =>
      'Ruang dalam ruang kerja ini muncul di sini.';

  @override
  String get thread => 'Benang';

  @override
  String get agentWorking => 'Ejen sedang bekerja';

  @override
  String get messagesLoadFailed => 'Tidak dapat memuatkan mesej';

  @override
  String get noMessagesYet => 'Belum ada mesej';

  @override
  String get noMessagesDescription => 'Hantar mesej untuk memulakan perbualan.';

  @override
  String get agentResponding => 'Ejen membalas';

  @override
  String get agentFinished => 'Ejen selesai';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names terlalu besar untuk dihantar dari sini.',
      one: '$names terlalu besar untuk dihantar dari sini.',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names terlalu besar untuk dihantar melalui relay dari sini.',
      one: '$names terlalu besar untuk dihantar melalui relay dari sini.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'Tidak dapat memuat naik lampiran. Cuba lagi.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lampiran tidak dapat dimuat naik dan dikecualikan.',
      one: '1 lampiran tidak dapat dimuat naik dan dikecualikan.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Rakan sepasukan';

  @override
  String get agent => 'Ejen';

  @override
  String get attachFile => 'Lampirkan fail';

  @override
  String get messageHint => 'Mesej';

  @override
  String removeAttachment(String name) {
    return 'Buang $name';
  }

  @override
  String get articlesLoadFailed => 'Tidak dapat memuatkan artikel';

  @override
  String get noArticles => 'Tiada artikel';

  @override
  String get articlesEmptyDescription =>
      'Artikel baharu muncul di sini apabila suapan dikemas kini.';

  @override
  String get unread => 'Belum dibaca';

  @override
  String get allFeeds => 'Semua suapan';

  @override
  String get save => 'Simpan';

  @override
  String get unsave => 'Nyahsimpan';

  @override
  String get readFullArticle => 'Baca artikel penuh';

  @override
  String get ticketsLoadFailed => 'Tidak dapat memuatkan tiket';

  @override
  String get noTickets => 'Tiada tiket';

  @override
  String get ticketsEmptyDescription =>
      'Tiket dalam ruang kerja ini muncul di sini.';

  @override
  String get all => 'Semua';

  @override
  String get ticket => 'Tiket';

  @override
  String get ticketLoadFailed => 'Tidak dapat memuatkan tiket';

  @override
  String assignedTo(String name) {
    return 'Ditugaskan kepada $name';
  }

  @override
  String get openInBrowser => 'Buka dalam penyemak imbas';

  @override
  String get status => 'Status';

  @override
  String get assign => 'Tugaskan';

  @override
  String get reassign => 'Tugaskan semula';

  @override
  String get noAgents => 'Tiada ejen';

  @override
  String get noAgentsDescription => 'Tugaskan ejen dari ruang kerja ini.';

  @override
  String get statusOpen => 'Terbuka';

  @override
  String get statusInProgress => 'Sedang berjalan';

  @override
  String get statusBlocked => 'Disekat';

  @override
  String get statusInReview => 'Dalam semakan';

  @override
  String get statusDone => 'Selesai';

  @override
  String get statusBacklog => 'Backlog';

  @override
  String get lensNeedsMe => 'Memerlukan saya';

  @override
  String get lensMine => 'Milik saya';

  @override
  String get prsLoadFailed => 'Tidak dapat memuatkan pull request';

  @override
  String get noOpenPullRequests => 'Tiada pull request terbuka';

  @override
  String get nothingWaitingOnReview => 'Tiada yang menunggu semakan anda';

  @override
  String get noOwnOpenPullRequests => 'Anda tiada pull request terbuka';

  @override
  String get nothingBlocked => 'Tiada yang disekat';

  @override
  String get prsEmptyDescription =>
      'Pull request merentasi repo ruang kerja ini muncul di sini.';

  @override
  String get refreshPullRequests => 'Muat semula pull request';

  @override
  String get noForgeConnected =>
      'Tiada forge disambungkan pada pelayan, jadi pull request tidak dapat diambil. Sambungkan satu dari apl desktop.';

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
  String get installationSuspendedTitle => 'Pemasangan GitHub App digantung';

  @override
  String installationSuspendedBody(String names) {
    return 'Memaparkan data terakhir diketahui untuk $names. Sambung semula pemasangan di GitHub, atau sambungkan token yang mempunyai akses.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'Pemasangan GitHub App digantung. Memaparkan data terakhir diketahui untuk $names. Sambung semula pemasangan di GitHub, atau sambungkan token yang mempunyai akses.';
  }

  @override
  String get draft => 'Draf';

  @override
  String get merged => 'Dicantum';

  @override
  String get closed => 'Ditutup';

  @override
  String get open => 'Terbuka';

  @override
  String get approved => 'Diluluskan';

  @override
  String get changesRequested => 'Perubahan diminta';

  @override
  String get reviewRequired => 'Semakan diperlukan';

  @override
  String get checksPassing => 'Semakan lulus';

  @override
  String get checksFailing => 'Semakan gagal';

  @override
  String get checksRunning => 'Semakan berjalan';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'Tidak dapat memuatkan pull request ini';

  @override
  String get openOnForge => 'Buka di forge';

  @override
  String get requestChangesNeedsComment =>
      'Tambah komen yang menerangkan apa yang perlu diubah.';

  @override
  String get conversation => 'Perbualan';

  @override
  String get files => 'Fail';

  @override
  String get checks => 'Semakan';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fail',
      one: '1 fail',
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
  String get reviewers => 'Penyemak';

  @override
  String get noDescriptionNoComments => 'Belum ada perihalan mahupun komen.';

  @override
  String get noChangedFiles => 'Tiada fail yang diubah.';

  @override
  String get noChecksReported => 'Tiada semakan dilaporkan untuk commit head.';

  @override
  String get reviewCommentHint => 'Tulis komen semakan…';

  @override
  String get comment => 'Komen';

  @override
  String get commentPosted => 'Komen disiarkan';

  @override
  String get request => 'Minta';

  @override
  String get squashAndMerge => 'Squash dan cantum';

  @override
  String noActionsAvailable(String status) {
    return '$status — tiada tindakan tersedia.';
  }

  @override
  String get reviewApproved => 'diluluskan';

  @override
  String get reviewRequestedChanges => 'meminta perubahan';

  @override
  String get reviewCommented => 'disemak';

  @override
  String get reviewPending => 'tertunda';

  @override
  String get unknownAuthor => 'tidak diketahui';

  @override
  String hideDiffFor(String file) {
    return 'Sembunyikan diff untuk $file';
  }

  @override
  String showDiffFor(String file) {
    return 'Tunjukkan diff untuk $file';
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
  String get checkSkipped => 'dilangkau';

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
      'Tiada diff teks untuk fail ini — ia binari, atau terlalu besar untuk forge mengembalikannya.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tunjukkan $count baris yang tinggal',
      one: 'Tunjukkan baris yang tinggal',
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
  String get jumpToLatest => 'Lompat ke terkini';

  @override
  String get streaming => 'Menstrim';

  @override
  String get working => 'Bekerja';

  @override
  String get input => 'Input';

  @override
  String get output => 'Output';

  @override
  String get now => 'sekarang';

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
  String get tomorrow => 'Esok';

  @override
  String get yesterday => 'Semalam';

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
