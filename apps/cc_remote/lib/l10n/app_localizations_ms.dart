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
  String get copyCommand => 'Salin perintah';

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
      'Imbas kod QR dari Control Center untuk pasangkan telefon ini.';

  @override
  String get scanQrHelp =>
      'Buka kamera dan halakannya ke QR yang dipaparkan dalam Control Center. Telefon ini bersambung terus melalui pautan peribadi.';

  @override
  String get connectingToMac => 'Menyambung ke Control Center…';

  @override
  String get connectingDetail => 'Menjalin pautan langsung yang selamat.';

  @override
  String get identityChangedTitle => 'Identiti pelayan berubah';

  @override
  String get identityChangedBody =>
      'Pelayan ini tidak lagi sepadan dengan identiti yang disimpan semasa pemasangan. Itu boleh bermaksud pelayan dipasang semula — atau sesuatu memintas sambungan. Demi keselamatan, peranti ini tidak akan bersambung. Buang pasangan, kemudian imbas kod QR baharu dari Control Center untuk pasangkan semula.';

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
      'Belum berpasangan — imbas kod QR dari Control Center';

  @override
  String get failureUnreachable =>
      'Tidak dapat mencapai pelayan pada mana-mana laluan — pastikan ia berjalan, atau cuba rangkaian yang sama';

  @override
  String get failureIdentityChanged =>
      'Identiti pelayan berubah — jika ia dipasang semula, pasangkan semula peranti ini';

  @override
  String get failureAuthRejected =>
      'Pelayan menolak peranti ini — pasangkan semula dari Control Center';

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
      'Ketik lagi untuk putuskan peranti ini dari Control Center';

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
  String get newSpaceFolder => 'Folder baharu';

  @override
  String get folderName => 'Nama folder';

  @override
  String get renameSpaceFolder => 'Namakan semula folder';

  @override
  String get deleteSpaceFolder => 'Padam folder';

  @override
  String get moveSpaceToFolder => 'Alihkan ke folder';

  @override
  String get removeSpaceFromFolder => 'Alih keluar daripada folder';

  @override
  String get spaceFolderActions => 'Tindakan folder';

  @override
  String get deleteFolderWithSpacesWarning =>
      'Memadam ruang secara kekal akan mengalih keluar mesej dan direktori kerja ruang itu untuk semua orang. Tindakan ini tidak boleh dibuat asal.';

  @override
  String get deleteSpacesInFolder =>
      'Padam secara kekal ruang dalam folder ini';

  @override
  String get deleteFolderAndSpaces => 'Padam folder dan ruang';

  @override
  String get keepSpacesInFolder =>
      'Jika tidak, ruang akan kekal di luar folder.';

  @override
  String get create => 'Cipta';

  @override
  String get otherSpaces => 'Ruang lain';

  @override
  String get folderUpdateFailed => 'Tidak dapat mengemas kini folder';

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

  @override
  String get mobileConversations => 'Perbualan';

  @override
  String get mobileNewConversation => 'Perbualan baharu';

  @override
  String get mobileConversationName => 'Nama perbualan';

  @override
  String get mobileRename => 'Namakan semula';

  @override
  String get mobileManageSpace => 'Urus ruang';

  @override
  String get mobileArchived => 'Diarkibkan';

  @override
  String get mobileSearchMessages => 'Cari semua mesej dalam ruang ini';

  @override
  String get mobileSearch => 'Cari';

  @override
  String get mobileNoResults => 'Tiada hasil';

  @override
  String get mobileReopen => 'Buka semula';

  @override
  String get mobileArchive => 'Arkibkan';

  @override
  String get mobileProgress => 'Kemajuan dan konteks';

  @override
  String get mobileReadFailed =>
      'Tidak dapat menandakan perbualan ini sebagai dibaca';

  @override
  String get mobileSendFailed => 'Mesej tidak dihantar. Draf anda masih ada.';

  @override
  String get mobileActionFailed => 'Tindakan gagal';

  @override
  String get mobileRemove => 'Buang';

  @override
  String get mobileLinkedMessage => 'Mesej terpaut';

  @override
  String get mobileOlderMessages => 'Mesej terdahulu';

  @override
  String get mobileMessageActions => 'Tindakan mesej';

  @override
  String get mobileOpenThread => 'Buka bebenang';

  @override
  String get mobileCopyLink => 'Salin pautan';

  @override
  String get mobileStopRun => 'Henti larian';

  @override
  String get mobileStopRunConfirm =>
      'Hentikan larian ejen ini? Kerja yang sudah selesai akan disimpan.';

  @override
  String get mobileControlUnsupported =>
      'Larian ini telah tamat atau tidak menyokong kawalan ini.';

  @override
  String get mobilePauseRequested =>
      'Jeda diminta pada akhir giliran seterusnya';

  @override
  String get mobileResumed => 'Larian disambung';

  @override
  String get mobileStopRequested => 'Henti diminta';

  @override
  String get mobileQueuedMessages => 'Mesej dalam barisan';

  @override
  String get mobilePauseRun => 'Jeda pada giliran seterusnya';

  @override
  String get mobileResumeRun => 'Sambung';

  @override
  String get mobileEditQueued => 'Sunting mesej dalam barisan';

  @override
  String get mobileSteerNow => 'Ubah arah sekarang';

  @override
  String get mobileMoveUp => 'Alih ke atas';

  @override
  String get mobileMoveDown => 'Alih ke bawah';

  @override
  String get mobileQueueChanged =>
      'Barisan telah berubah atau larian ini tidak menerima arahan langsung. Muat semula dan cuba lagi.';

  @override
  String get mobileActivity => 'Aktiviti';

  @override
  String get mobilePermissions => 'Keizinan dan audit';

  @override
  String get mobilePlans => 'Rancangan';

  @override
  String get mobileGoals => 'Matlamat dipantau';

  @override
  String get mobileCredentials => 'Sambungan dan kelayakan';

  @override
  String get mobileWorkspaceUnavailable =>
      'Ruang kerja ini tidak tersedia atau anda tidak lagi mempunyai akses.';

  @override
  String get mobilePrReviewThreads => 'Benang semakan';

  @override
  String get mobilePrThreadsLoadFailed =>
      'Tidak dapat memuatkan bebenang semakan';

  @override
  String get mobilePrNoReviewThreads => 'Belum ada bebenang semakan sebaris';

  @override
  String get mobilePrCommentPermissionDenied =>
      'Anda tiada keizinan untuk mengulas repositori ini.';

  @override
  String get mobilePrPermissionChecking => 'Menyemak keizinan mengulas…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'Tidak dapat menyemak keizinan mengulas. Cuba lagi untuk mengulas.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return 'Baris $line $side';
  }

  @override
  String get mobilePrOriginalSide => 'Asal';

  @override
  String get mobilePrUpdatedSide => 'Dikemas kini';

  @override
  String get mobilePrThreadResolved => 'Diselesaikan';

  @override
  String get mobilePrReplyHint => 'Tulis balasan…';

  @override
  String get mobilePrCommentRequired => 'Tulis ulasan sebelum menghantar.';

  @override
  String get mobilePrReply => 'Balas';

  @override
  String get mobilePrReopenThread => 'Buka semula bebenang';

  @override
  String get mobilePrResolveThread => 'Selesaikan bebenang';

  @override
  String get mobilePrResolvePermissionDenied =>
      'Hanya penulis pull request atau pengguna dengan akses tulis boleh menyelesaikan bebenang ini.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'Ulas baris $line $side';
  }

  @override
  String get mobilePrInlineCommentHint => 'Tulis ulasan sebaris…';

  @override
  String get mobilePrPostInlineComment => 'Hantar ulasan';

  @override
  String get mobilePrCommentUnavailable =>
      'Ulasan sebaris tidak tersedia untuk pull request ini.';

  @override
  String get mobilePrPatchUnavailable =>
      'Perkhidmatan kod tidak menyediakan tampalan teks untuk fail ini.';

  @override
  String get mobilePrNoPatchForFile =>
      'Tampalan untuk fail ini tidak tersedia.';

  @override
  String get mobileTicketNew => 'Tiket baharu';

  @override
  String get mobileTicketCreate => 'Cipta tiket';

  @override
  String get mobileTicketEdit => 'Sunting tiket';

  @override
  String get mobileTicketTitle => 'Tajuk';

  @override
  String get mobileTicketTitleRequired =>
      'Masukkan tajuk untuk menyimpan tiket ini.';

  @override
  String get mobileTicketDescription => 'Perihalan';

  @override
  String get mobileTicketMarkdownHint => 'Tambah butiran dalam Markdown';

  @override
  String get mobileTicketPriority => 'Keutamaan';

  @override
  String get mobileTicketPriorityNone => 'Tiada keutamaan';

  @override
  String get mobileTicketPriorityUrgent => 'Mendesak';

  @override
  String get mobileTicketPriorityHigh => 'Tinggi';

  @override
  String get mobileTicketPriorityMedium => 'Sederhana';

  @override
  String get mobileTicketPriorityLow => 'Rendah';

  @override
  String get mobileTicketLabels => 'Label';

  @override
  String get mobileTicketLabelsHint => 'Satu label setiap baris';

  @override
  String get mobileTicketLabelsHelp =>
      'Masukkan setiap label pada baris berasingan.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'Difailkan dalam $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'Tidak ditugaskan';

  @override
  String get mobileTicketAssignedFilter => 'Ditugaskan';

  @override
  String get mobileTicketAgentsLoadFailed => 'Tidak dapat memuatkan ejen';

  @override
  String get mobileTicketSearch => 'Cari tiket';

  @override
  String get mobileTicketSearchHint =>
      'Tajuk, kunci, perihalan, label atau penerima tugas';

  @override
  String get mobileTicketClearSearch => 'Kosongkan carian tiket';

  @override
  String get mobileTicketNoMatches => 'Tiada tiket yang sepadan';

  @override
  String get mobileTicketAdjustFilters => 'Cuba carian lain atau ubah penapis.';

  @override
  String get mobileTicketClearFilters => 'Kosongkan penapis';

  @override
  String get mobileTicketNotFound => 'Tiket tidak ditemukan';

  @override
  String get mobileTicketNotFoundDescription =>
      'Tiket ini mungkin telah dipadam atau dipindahkan keluar dari ruang kerja ini.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'Ruang kerja telah berubah. Kembali ke ruang kerja semasa sebelum menyimpan.';

  @override
  String get mobileTicketOpenLinkedSpace => 'Buka ruang terpaut';

  @override
  String get mobileTicketReadOnly =>
      'Peranan ahli ruang kerja diperlukan untuk mengubah tiket.';

  @override
  String get permissionTitle => 'Keizinan';

  @override
  String get permissionWorkspaceFailed => 'Tidak dapat memuatkan ruang kerja';

  @override
  String get permissionNoWorkspace =>
      'Pilih ruang kerja untuk menyemak keizinan.';

  @override
  String get permissionLoading => 'Memuatkan keizinan…';

  @override
  String get permissionScopeDescription =>
      'Semak cara setiap tindakan diputuskan pada skop ini. Peraturan ruang kerja boleh diwarisi oleh ejen dan ruang.';

  @override
  String get permissionScope => 'Skop dasar';

  @override
  String get permissionWorkspaceScope => 'Ruang kerja';

  @override
  String get permissionAgentScope => 'Ejen';

  @override
  String get permissionSpaceScope => 'Ruang';

  @override
  String get permissionAgentContext => 'Ejen yang bertindak dalam ruang ini';

  @override
  String get permissionNoAgentContext => 'Tiada ejen dipilih';

  @override
  String get permissionTargetsFailed => 'Tidak dapat memuatkan sasaran skop';

  @override
  String get permissionNoTargets => 'Tiada sasaran tersedia pada skop ini.';

  @override
  String get permissionRoleFailed =>
      'Tidak dapat mengesahkan peranan ruang kerja anda';

  @override
  String get permissionMemberRequired =>
      'Peranan ahli ruang kerja diperlukan untuk melihat peraturan dasar.';

  @override
  String get permissionRulesFailed => 'Tidak dapat memuatkan peraturan dasar';

  @override
  String get permissionAuditAdminOnly =>
      'Sejarah kebenaran hanya tersedia kepada pentadbir ruang kerja.';

  @override
  String get permissionAllow => 'Benarkan';

  @override
  String get permissionAsk => 'Tanya dahulu';

  @override
  String get permissionDeny => 'Tolak';

  @override
  String get permissionFileDelete => 'Padam fail';

  @override
  String get permissionFileWriteOutsideWorktree =>
      'Tulis di luar pepohon kerja';

  @override
  String get permissionGitCommit => 'Komit perubahan';

  @override
  String get permissionGitPush => 'Tolak komit';

  @override
  String get permissionPrCreate => 'Cipta pull request';

  @override
  String get permissionPrPublish => 'Terbitkan pull request';

  @override
  String get permissionVendorSyncWrite => 'Tulis penyegerakan penyedia';

  @override
  String get permissionNetworkEgress => 'Akses rangkaian';

  @override
  String get permissionSecretAccess => 'Akses rahsia';

  @override
  String get permissionPackageInstall => 'Pasang pakej';

  @override
  String get permissionProcessSpawn => 'Mulakan proses';

  @override
  String get permissionWorkspaceMutation => 'Ubah ruang kerja';

  @override
  String get permissionEnclosureControl => 'Kawal kepungan';

  @override
  String get permissionChangeFailed => 'Tidak dapat mengubah peraturan';

  @override
  String get permissionEffectiveDescription =>
      'Berkuat kuasa pada skop ini tanpa argumen tindakan. Keizinan bersyarat di bawah hanya terpakai pada permintaan yang sepadan; pelayan membuat keputusan akhir.';

  @override
  String get permissionSpaceAgentNote =>
      'Tiada ejen dipilih. Peraturan khusus ejen tidak dipaparkan sehingga anda memilih satu di atas.';

  @override
  String get permissionScopedGrants => 'Peraturan pada skop ini';

  @override
  String get permissionModePreset => 'Praset modus';

  @override
  String get permissionBuiltInDefault => 'Lalai terbina';

  @override
  String get permissionRemembered => 'Kelulusan yang diingati';

  @override
  String get permissionSource => 'Sumber';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · ditetapkan di sini';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · diwarisi';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'Luput pada $date';
  }

  @override
  String get permissionSetHere => 'Tetapkan peraturan di sini';

  @override
  String get permissionRevokeBeforeEdit =>
      'Tarik balik peraturan berskop atau yang diingati sebelum menetapkan peraturan umum untuk tindakan ini.';

  @override
  String get permissionConfirmRevoke => 'Sahkan penarikan balik';

  @override
  String get permissionRevokeRule => 'Tarik balik peraturan';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'Awalan arahan: $prefix';
  }

  @override
  String get permissionNoExpiry => 'Tiada tarikh luput';

  @override
  String get permissionExpired => 'Luput';

  @override
  String get permissionExplicitRule => 'Peraturan jelas';

  @override
  String get permissionEnforcementAdvisory =>
      'Nasihat: peraturan tanya dahulu dicatat tanpa meminta pengesahan';

  @override
  String get permissionEnforcementSoft =>
      'Penguatkuasaan lembut: penggantian memerlukan kebenaran';

  @override
  String get permissionEnforcementHard =>
      'Penguatkuasaan ketat: tidak boleh diganti';

  @override
  String permissionPaths(String paths) {
    return 'Laluan: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Rujukan Git: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'Hos: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'Arahan: $commands';
  }

  @override
  String permissionMaxCount(String count) {
    return 'Bilangan maksimum: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'Sen maksimum: $cents';
  }

  @override
  String get permissionAuditHeading => 'Sejarah kebenaran';

  @override
  String get permissionAuditDescription =>
      'Keputusan terkini yang dicatat oleh pelayan. Hanya pentadbir boleh melihat log atau mengesahkan rantaian cincangnya.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'Bagi pihak $user';
  }

  @override
  String get permissionPrompted => 'Kelulusan manusia diminta';

  @override
  String get permissionVerifyChain => 'Sahkan rantaian audit';

  @override
  String get permissionVerifyFailed => 'Tidak dapat mengesahkan rantaian audit';

  @override
  String permissionChainIntact(String count) {
    return 'Rantaian utuh · $count entri diperiksa';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'Rantaian terputus pada entri $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty =>
      'Belum ada keputusan kebenaran yang dicatat.';

  @override
  String get permissionAuditFailed => 'Tidak dapat memuatkan sejarah kebenaran';

  @override
  String get mobilePlansLoadFailed => 'Tidak dapat memuatkan rancangan';

  @override
  String get mobilePlansEmpty => 'Belum ada rancangan';

  @override
  String get mobilePlansEmptyDescription =>
      'Rancangan yang dihantar oleh ejen akan muncul di sini untuk disemak.';

  @override
  String get mobilePlanTitle => 'Rancang';

  @override
  String get mobilePlanMissing =>
      'Rancangan ini tidak lagi tersedia dalam ruang kerja ini.';

  @override
  String mobilePlanStepCount(int count) {
    return '$count langkah';
  }

  @override
  String get mobilePlanDraft => 'Draf';

  @override
  String get mobilePlanProposed => 'Menunggu semakan';

  @override
  String get mobilePlanApproved => 'Diluluskan';

  @override
  String get mobilePlanRejected => 'Ditolak';

  @override
  String get mobilePlanSuperseded => 'Diganti';

  @override
  String get mobilePlanExecuting => 'Melaksanakan';

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
    return 'Semakan $revision';
  }

  @override
  String get mobilePlanSteps => 'Langkah';

  @override
  String get mobilePlanNoSteps => 'Tiada langkah dihantar untuk rancangan ini.';

  @override
  String get mobilePlanAssumptions => 'Penjelasan';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'Bergantung pada $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'Anggaran sehingga $cost';
  }

  @override
  String get mobilePlanSelect => 'Pilih';

  @override
  String get mobilePlanSelected => 'Dipilih';

  @override
  String get mobilePlanEstimate => 'Anggarkan kos';

  @override
  String get mobilePlanEstimateRequired =>
      'Anggarkan kos rancangan sebelum meluluskan pelaksanaan.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'Anggaran kos: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'tidak tersedia';

  @override
  String get mobilePlanNoHardCap => 'tiada had tetap';

  @override
  String get mobilePlanExceedsBudget =>
      'Anggaran melebihi belanjawan yang ditetapkan. Semak sebelum meluluskan.';

  @override
  String get mobilePlanPartialEstimate =>
      'Anggaran ini meliputi seluruh rancangan; langkah yang dipilih mungkin lebih murah.';

  @override
  String get mobilePlanConfirmAll => 'Mulakan seluruh rancangan?';

  @override
  String get mobilePlanConfirmSelected => 'Mulakan langkah yang dipilih?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'Kelulusan akan memulakan pelaksanaan dan mungkin dikenakan bayaran. Anggaran kos tertinggi: $cost. Had belanjawan: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'Luluskan semua dan jalankan';

  @override
  String get mobilePlanApproveSelected => 'Luluskan pilihan dan jalankan';

  @override
  String get mobilePlanWiden => 'Luluskan langkah tambahan';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'Benarkan $count langkah lagi untuk dilaksanakan? Bayaran mungkin dikenakan. Had kos pelaksanaan sedia ada: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'Rancangan berubah semasa semakan. Buka semula semakan terkini dan anggarkan kos sekali lagi.';

  @override
  String get mobilePlanReject => 'Tolak rancangan';

  @override
  String get mobilePlanRejectConfirm =>
      'Tolak rancangan ini? Rancangan tidak akan dilaksanakan.';

  @override
  String get mobilePlanStop => 'Hentikan pelaksanaan';

  @override
  String get mobilePlanStopConfirm =>
      'Hentikan pelaksanaan rancangan ini? Kerja yang sudah selesai tidak akan dibatalkan.';

  @override
  String mobilePlanRunId(String runId) {
    return 'Larian pelaksanaan: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'Kelulusan diterima. Menunggu rekod pelaksanaan…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return '$completed daripada $total langkah pelaksanaan selesai';
  }

  @override
  String get mobilePlanOpenConversation => 'Buka perbualan';

  @override
  String get mobileGoalsTitle => 'Matlamat dipantau';

  @override
  String get mobileGoalsLoadFailed => 'Tidak dapat memuatkan matlamat dipantau';

  @override
  String get mobileGoalsEmpty => 'Belum ada matlamat dipantau';

  @override
  String get mobileGoalsEmptyDescription =>
      'Mulakan matlamat dalam ruang atau hantar /goal dalam perbualan.';

  @override
  String get mobileGoalMissing =>
      'Matlamat ini tidak lagi tersedia dalam ruang kerja ini.';

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
  String get mobileGoalBudgetExhausted => 'Had belanjawan dicapai';

  @override
  String get mobileGoalGoal => 'Matlamat';

  @override
  String get mobileGoalLoop => 'Gelung';

  @override
  String mobileGoalKind(String kind) {
    return 'Jenis: $kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return '$count larian';
  }

  @override
  String get mobileGoalNoRunLimit => 'tanpa had';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return 'Larian: $runs / $maxRuns · Dibelanjakan: $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return 'Tarikh akhir: $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return 'Larian gagal berturut-turut: $count';
  }

  @override
  String get mobileGoalSummary => 'Ringkasan penyelesaian';

  @override
  String get mobileGoalFailedDescription =>
      'Penyelia berhenti selepas larian gagal berulang kali. Semak perbualan untuk butiran.';

  @override
  String get mobileGoalBudgetWall =>
      'Tarikh akhir atau had larian telah dicapai. Matlamat ini tidak boleh disambung dengan menaikkan had kos.';

  @override
  String get mobileGoalPause => 'Jeda matlamat';

  @override
  String get mobileGoalResume => 'Sambung matlamat';

  @override
  String get mobileGoalStop => 'Batalkan matlamat';

  @override
  String get mobileGoalStopConfirm =>
      'Batalkan matlamat dipantau ini secara kekal? Matlamat ini tidak boleh disambung.';

  @override
  String get mobileGoalRaiseBudget => 'Naikkan belanjawan dan sambung';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'Naikkan belanjawan kepada $amount dan sambung';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'Naikkan had kos matlamat ini daripada $oldCap kepada $newCap dan sambung perbelanjaan?';
  }

  @override
  String get mobileGoalOpenConversation => 'Buka perbualan matlamat';

  @override
  String get mobileGoalCreate => 'Mulakan matlamat dipantau';

  @override
  String get mobileGoalChooseSpace => 'Jalankan dalam ruang';

  @override
  String get mobileGoalNoSpaces => 'Cipta ruang sebelum memulakan matlamat.';

  @override
  String get mobileGoalChooseAgent => 'Jalankan dengan ejen';

  @override
  String get mobileGoalNoAgents =>
      'Tambah ejen aktif sebelum memulakan matlamat.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return '$name dipilih';
  }

  @override
  String get mobileGoalObjectiveHint =>
      'Apakah hasil yang perlu dicapai oleh ejen?';

  @override
  String get mobileGoalBudgetUsd => 'Had kos (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'Pilih ruang dan ejen, masukkan objektif dan tetapkan had kos positif dalam USD.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'Mulakan matlamat dipantau dengan kos maksimum $cap? Ejen mungkin bermula serta-merta.';
  }

  @override
  String get mobileGoalUnavailable =>
      'Sambungan pelayan belum sedia. Cuba lagi selepas menyambung semula.';

  @override
  String get mobileGoalConversationMissing =>
      'Perbualan yang dipilih tidak lagi tersedia dalam ruang kerja ini.';

  @override
  String get mobileGoalCreateSent =>
      'Matlamat dimulakan. Status penyelia akan muncul dalam senarai ini.';

  @override
  String get mobileGoalStartRefused =>
      'Tiada larian matlamat dimulakan. Semak perbualan untuk mengetahui sebab daripada penyelia.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return '$name dipilih';
  }

  @override
  String get requestUnavailable =>
      'Permintaan ini tidak lagi tersedia dalam ruang kerja aktif.';

  @override
  String get requestAlreadyResolved => 'Permintaan ini sudah diselesaikan.';

  @override
  String get inboxCredentialsBlocked => 'Kelayakan menghalang larian';

  @override
  String get inboxSyncFailures => 'Penyegerakan penyedia yang gagal';

  @override
  String get inboxConfigureCredentials => 'Konfigurasi kelayakan';

  @override
  String get openTicket => 'Buka tiket';

  @override
  String get activityTitle => 'Aktiviti';

  @override
  String get activityClearAll => 'Kosongkan aktiviti';

  @override
  String get activityClearConfirm =>
      'Ini menyembunyikan semua aktiviti yang telah direkodkan untuk anda pada setiap peranti. Aktiviti baharu masih akan muncul.';

  @override
  String get activityMarkAllRead => 'Tandakan semua sebagai dibaca';

  @override
  String get activityMarkAllConfirm =>
      'Tandakan setiap aktiviti dalam ruang kerja ini sebagai dibaca pada semua peranti anda?';

  @override
  String get activityMarkRead => 'Tandakan dibaca';

  @override
  String get activityMarkUnread => 'Tandakan belum dibaca';

  @override
  String get activityDismiss => 'Tolak';

  @override
  String get activityResolved => 'Diselesaikan';

  @override
  String get activityOpen => 'Terbuka';

  @override
  String get activityEmpty => 'Belum ada aktiviti';

  @override
  String get activityLoadFailed => 'Tidak dapat memuatkan aktiviti';

  @override
  String get activityAgentWaiting => 'Ejen memerlukan input';

  @override
  String get activityAgentBlocked => 'Tindakan ejen disekat';

  @override
  String get activityMessage => 'Mesej baharu';

  @override
  String get activityPullRequest => 'Kemas kini pull request';

  @override
  String get activityTicket => 'Kemas kini tiket';

  @override
  String get activityMeeting => 'Kemas kini mesyuarat';

  @override
  String get activityCalendar => 'Sambungan kalendar';

  @override
  String get activityRig => 'Kemas kini kepungan';

  @override
  String get activityEvent => 'Kemas kini';

  @override
  String get activityPrReady => 'Pull request sedia untuk dicantum';

  @override
  String get activityPrBlocked => 'Cantuman pull request disekat';

  @override
  String get activityPrApproved => 'Pull request diluluskan';

  @override
  String get activityPrChanges => 'Perubahan diminta';

  @override
  String get activityPrChecksFailed => 'Semakan pull request gagal';

  @override
  String get activityPrChecksRecovered => 'Semakan pull request pulih';

  @override
  String get activityPrComment => 'Ulasan pull request';

  @override
  String get activityPrPublished => 'Pull request diterbitkan';

  @override
  String get activityPrMerged => 'Pull request dicantum';

  @override
  String get activityPrMentioned => 'Disebut dalam pull request';

  @override
  String get activityPrReviewRequested => 'Semakan diminta';

  @override
  String get activityPrReviewStale => 'Semakan perlu disegarkan';

  @override
  String get activityTicketAssigned => 'Tiket ditugaskan';

  @override
  String get activityTicketChanged => 'Status tiket berubah';

  @override
  String get activityMeetingSoon => 'Mesyuarat akan bermula tidak lama lagi';

  @override
  String get activityCalendarExpired => 'Sambungan kalendar luput';

  @override
  String get activityRigControl => 'Kawalan kepungan berubah';

  @override
  String get activityRigClosed => 'Kepungan dihentikan';

  @override
  String get mobileSpacesSearch => 'Cari ruang';

  @override
  String get mobileSpacesArchived => 'Diarkibkan';

  @override
  String get mobileSpacesActive => 'Aktif';

  @override
  String get mobileSpacesNew => 'Ruang baharu';

  @override
  String get mobileSpacesManage => 'Urus ruang';

  @override
  String get mobileSpacesName => 'Nama ruang';

  @override
  String get mobileSpacesAgents => 'Ejen';

  @override
  String get mobileSpacesMembers => 'Orang';

  @override
  String get mobileSpacesRepos => 'Repositori';

  @override
  String get mobileSpacesAllRepos => 'Semua repositori terpaut';

  @override
  String get mobileSpacesNoRepos => 'Tiada repositori';

  @override
  String get mobileSpacesBaseBranch => 'Cabang asas (pilihan)';

  @override
  String get mobileSpacesDefaultBranch => 'Cabang lalai';

  @override
  String get mobileSpacesMode => 'Modus';

  @override
  String get mobileSpacesModeChat => 'Sembang';

  @override
  String get mobileSpacesModeReview => 'Semak (baca sahaja)';

  @override
  String get mobileSpacesModePlan => 'Rancang (baca sahaja)';

  @override
  String get mobileSpacesModeOrchestrate => 'Orkestrakan';

  @override
  String get mobileSpacesAutonomy => 'Penggantian autonomi';

  @override
  String get mobileSpacesAutonomyInherited => 'Diwarisi';

  @override
  String get mobileSpacesAutonomyPropose => 'Cadang sahaja';

  @override
  String get mobileSpacesAutonomyApproval => 'Bertindak dengan kelulusan';

  @override
  String get mobileSpacesAutonomyFreely => 'Bertindak bebas';

  @override
  String get mobileSpacesAutonomyNotice =>
      'Penggantian tidak boleh memintas permintaan kelulusan atau penolakan dasar tindakan. Hanya pentadbir ruang kerja boleh mengubahnya.';

  @override
  String get mobileSpacesArchive => 'Arkibkan ruang';

  @override
  String get mobileSpacesReopen => 'Buka semula ruang';

  @override
  String get mobileSpacesSave => 'Simpan perubahan';

  @override
  String get mobileSpacesCreate => 'Cipta ruang';

  @override
  String get mobileSpacesOperationFailed => 'Tidak dapat mengemas kini ruang';

  @override
  String get mobileSpacesMissing =>
      'Ruang tidak ditemukan dalam ruang kerja ini';

  @override
  String get mobileSpacesEmptyName => 'Masukkan nama ruang';

  @override
  String get mobileSpacesNoMatches => 'Tiada ruang yang sepadan';

  @override
  String get mobileSpacesUnread => 'Balasan ejen belum dibaca';

  @override
  String get mobileSpacesNeedsInput => 'Memerlukan input anda';

  @override
  String get mobileSpacesRunning => 'Ejen sedang berjalan';

  @override
  String get mobileSpacesNoAgents => 'Tiada ejen dalam ruang kerja ini';

  @override
  String get mobileSpacesNoMembers => 'Tiada ahli ruang kerja lain';

  @override
  String get mobileSpacesRepoError => 'Tidak dapat memuatkan repositori';

  @override
  String get mobileSpacesRetry => 'Cuba semula';

  @override
  String get mobileSpacesBranchUnavailable =>
      'Pilih atau taip cabang asas semasa mencipta ruang; cabang asas ruang sedia ada tidak boleh diubah.';

  @override
  String get mobileSpacesArchivedEmpty => 'Tiada ruang diarkibkan';

  @override
  String get mobileSpacesAllRepoWarning =>
      'Repositori yang baru dipautkan ke ruang kerja juga akan disertakan dalam ruang ini.';

  @override
  String get mobileSpacesCreatedRetry =>
      'Ruang dicipta. Cuba tambah orang sekali lagi atau buka halaman pengurusannya.';

  @override
  String get progressTitle => 'Kemajuan';

  @override
  String get progressConversation => 'Perbualan';

  @override
  String get progressLoadFailed => 'Tidak dapat memuatkan kemajuan';

  @override
  String get progressUnavailable => 'Perbualan tidak tersedia';

  @override
  String get progressUnavailableDescription =>
      'Perbualan ini tiada dalam ruang kerja dan ruang yang aktif. Kembali ke ruangnya untuk meneruskan.';

  @override
  String get progressSaveFailed => 'Tidak dapat mengemas kini kemajuan';

  @override
  String get progressGoal => 'Matlamat';

  @override
  String get progressNoGoal => 'Tiada matlamat kerja ditetapkan';

  @override
  String get progressSetGoal => 'Tetapkan matlamat';

  @override
  String get progressEditGoal => 'Sunting matlamat';

  @override
  String get progressClearGoal => 'Kosongkan matlamat';

  @override
  String get progressGoalRequired => 'Masukkan matlamat sebelum menyimpan.';

  @override
  String get progressTodos => 'Tugas';

  @override
  String get progressNoTodos => 'Belum ada tugas';

  @override
  String get progressNewTodo => 'Tugas baharu';

  @override
  String get progressAddTodo => 'Tambah tugas';

  @override
  String get progressEditTodo => 'Sunting tugas';

  @override
  String get progressTodoRequired => 'Masukkan tugas sebelum menyimpan.';

  @override
  String get progressTodoNoLongerExists =>
      'Tugas itu telah dibuang. Muat semula senarai dan cuba lagi.';

  @override
  String get progressWorkspaceChanged =>
      'Ruang kerja aktif telah berubah. Kembali ke perbualan ini dan cuba lagi.';

  @override
  String progressRemoveTodo(String name) {
    return 'Buang tugas $name';
  }

  @override
  String get progressPending => 'Tertunda';

  @override
  String get progressInProgress => 'Sedang berjalan';

  @override
  String get progressCompleted => 'Selesai';

  @override
  String get progressMoveUp => 'Alih tugas ke atas';

  @override
  String get progressMoveDown => 'Alih tugas ke bawah';

  @override
  String get progressRunTree => 'Larian ejen';

  @override
  String get progressNoRuns => 'Belum ada larian dalam perbualan ini';

  @override
  String get progressRunning => 'Berjalan';

  @override
  String get progressFailed => 'Gagal';

  @override
  String get progressUnknown => 'Tidak diketahui';

  @override
  String get progressHealthy => 'Aktif';

  @override
  String get progressBlocked => 'Disekat';

  @override
  String get progressLooping => 'Berulang';

  @override
  String get progressStalled => 'Tergendala';

  @override
  String get progressDead => 'Berhenti tanpa dijangka';

  @override
  String get progressQuiet => 'Belum ada output';

  @override
  String get progressCostReported => 'Caj dilaporkan oleh penyedia';

  @override
  String get progressCostNotional =>
      'Harga senarai langganan sebagai anggaran; bukan bil';

  @override
  String get progressCostMixed => 'Sumber kos bercampur';

  @override
  String get progressCostEstimated => 'Anggaran kos';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds saat';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'Model: $model · Masa: $duration · Kos: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'Dimulakan $time';
  }

  @override
  String progressLiveness(String state) {
    return 'Keadaan: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'Input: $input · Output: $output token';
  }

  @override
  String get progressOutputPreviewLimited =>
      'Hanya 6,000 aksara pertama output berstruktur dipaparkan.';

  @override
  String progressRetryOf(String runId) {
    return 'Percubaan semula larian $runId';
  }

  @override
  String get progressContext => 'Konteks dan had';

  @override
  String get progressNoAgent => 'Tiada ejen untuk diperiksa';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window token';
  }

  @override
  String get progressMeasured =>
      'Konteks yang dilaporkan penyedia pada panggilan terkini';

  @override
  String get progressEstimated =>
      'Dianggarkan daripada perbualan tersimpan dan konteks berterusan';

  @override
  String get progressContextUnknown => 'Penggunaan konteks belum dilaporkan';

  @override
  String progressContextPercent(String percent) {
    return '$percent% daripada tetingkap konteks';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'Had bulanan ejen yang ditetapkan: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'Perbualan aktif tersimpan: anggaran $tokens token';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'Konteks berterusan untuk $agent · $model';
  }

  @override
  String get progressContextSystem => 'Prompt sistem';

  @override
  String get progressContextRules => 'Peraturan';

  @override
  String get progressContextSkills => 'Kemahiran';

  @override
  String get progressContextTools => 'Takrifan alat';

  @override
  String get progressContextMcp => 'Alat MCP';

  @override
  String get progressContextDeferred => 'Alat tertunda';

  @override
  String get progressContextSubagents => 'Subejen';

  @override
  String get progressContextRunner => 'Pelaksana luaran';

  @override
  String get progressContextMemory => 'Memori';

  @override
  String get progressContextHistory => 'Sejarah perbualan';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens token';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens token';
  }

  @override
  String get progressOutputs => 'Output terkini';

  @override
  String get progressNoOutputs => 'Tiada output ejen terkini';

  @override
  String get progressStructuredOutputsAbove =>
      'Output larian berstruktur dipaparkan dalam larian ejen di atas.';

  @override
  String get progressRecentOutputsOnly =>
      'Hanya mesej terkini dipaparkan. Buka perbualan untuk melihat kerja terdahulu.';

  @override
  String get progressPlan => 'Rancang';

  @override
  String get progressArtifact => 'Artifak';

  @override
  String get progressResult => 'Hasil';

  @override
  String get progressHideArtifact => 'Sembunyikan artifak';

  @override
  String get progressReadArtifact => 'Baca artifak';

  @override
  String get progressArtifactUnavailable => 'Artifak tidak lagi tersedia';

  @override
  String get progressArtifactPreviewLimited =>
      'Pratonton terhad artifak ini dipaparkan.';

  @override
  String get progressDiagramSource => 'Sumber rajah';

  @override
  String progressOpenAttachment(String name) {
    return 'Buka $name';
  }

  @override
  String get progressOpenPlan => 'Buka rancangan';

  @override
  String progressOpenDiff(String label) {
    return 'Semak fail yang diubah: $label';
  }

  @override
  String get progressViewMessage => 'Lihat mesej';

  @override
  String get pushTitle => 'Pemberitahuan latar belakang';

  @override
  String get pushIntro =>
      'Terima makluman peribadi apabila sesuatu memerlukan perhatian anda, walaupun aplikasi ditutup. Butiran kekal dalam sambungan tersulit anda.';

  @override
  String get pushLoading => 'Menyemak tetapan pemberitahuan…';

  @override
  String get pushError =>
      'Tidak dapat mengemas kini pemberitahuan. Semak sambungan anda dan cuba lagi.';

  @override
  String get pushEnable => 'Dayakan pemberitahuan';

  @override
  String get pushDisable => 'Matikan pemberitahuan';

  @override
  String get pushQuiet => 'Jeda makluman pada peranti ini';

  @override
  String get pushCategories => 'Maklumkan saya tentang';

  @override
  String get pushCategoryAgents => 'Ejen';

  @override
  String get pushCategoryMessages => 'Mesej';

  @override
  String get pushCategoryPullRequests => 'Pull request';

  @override
  String get pushCategoryTickets => 'Tiket';

  @override
  String get pushCategoryCalendar => 'Kalendar';

  @override
  String get pushCategoryMachines => 'Mesin';

  @override
  String get pushSecureOrigin => 'Pemberitahuan memerlukan HTTPS.';

  @override
  String get pushInstallIos =>
      'Pada iPhone atau iPad, tambah aplikasi ini pada Skrin Utama dan bukanya di sana untuk mendayakan pemberitahuan.';

  @override
  String get pushUnsupported =>
      'Pelayar ini tidak menyokong pemberitahuan latar belakang.';

  @override
  String get pushDenied =>
      'Pemberitahuan disekat dalam tetapan pelayar. Benarkan di sana untuk meneruskan.';

  @override
  String get pushResubscribe => 'Sambung semula pemberitahuan';

  @override
  String get pushStatusEnabled => 'Pemberitahuan dihidupkan untuk peranti ini.';

  @override
  String get pushStatusDisabled => 'Pemberitahuan dimatikan untuk peranti ini.';

  @override
  String get credentialsTitle => 'Sambungan dan kelayakan';

  @override
  String get credentialsIntro =>
      'Sambungkan akaun yang digunakan oleh larian dan integrasi anda. Rahsia disimpan pada pelayan anda, bukan telefon ini.';

  @override
  String get credentialsModelProviders => 'Penyedia model';

  @override
  String get credentialsOwnerOnly =>
      'Hanya pemilik pelayan boleh menambah, log masuk atau membuang kelayakan penyedia model. Kunci ini dikongsi antara ruang kerja.';

  @override
  String get credentialsContactOwner =>
      'Minta pemilik pelayan menyambungkan penyedia yang diperlukan oleh larian anda yang tersekat.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude Code log masuk melalui CLI pada hos. Minta pemilik pelayan melengkapkan atau memperbaharui log masuk akaun pada terminal hos; telefon ini tidak boleh menjalankannya.';

  @override
  String get credentialsYourForgeAccounts => 'Akaun perkhidmatan kod anda';

  @override
  String get credentialsYourTicketingAccount => 'Akaun perkhidmatan tiket anda';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'Tiket setempat tidak memerlukan log masuk. Sambungkan Linear di sini jika ruang kerja anda menggunakan Linear.';

  @override
  String get credentialsMembershipRequired =>
      'Sertai ruang kerja untuk mengurus kelayakan perkhidmatan kod atau tiket anda. Minta akses daripada pentadbir ruang kerja.';

  @override
  String get credentialsSwitchWorkspace =>
      'Pautan ini menghala ke ruang kerja lain. Beralih ke ruang kerja itu sebelum mengubah kelayakan.';

  @override
  String get credentialsReturnToInbox =>
      'Kembali ke Peti Masuk untuk mencuba semula larian tersekat setelah kelayakannya disambungkan. Hos juga menyemak larian yang dijeda secara automatik.';

  @override
  String get credentialsLoadFailed =>
      'Tidak dapat memuatkan sambungan. Semak pautan pelayan dan cuba lagi.';

  @override
  String get credentialsOperationFailed =>
      'Tidak dapat mengubah sambungan ini. Semak pautan pelayan, akses dan kelayakan anda, kemudian cuba lagi.';

  @override
  String get credentialsConnected => 'Disambungkan';

  @override
  String get credentialsNotConnected => 'Tidak disambungkan';

  @override
  String credentialsSignedInAs(String username) {
    return 'Log masuk sebagai $username';
  }

  @override
  String get credentialsAccount => 'Akaun disambungkan';

  @override
  String get credentialsStoredKey => 'Kunci tersimpan';

  @override
  String get credentialsActive => 'Aktif';

  @override
  String get credentialsRemove => 'Buang';

  @override
  String get credentialsRemoveConfirm =>
      'Buang kelayakan tersimpan anda? Anda mungkin perlu log masuk semula.';

  @override
  String get credentialsApiKey => 'Kunci API';

  @override
  String get credentialsApiKeyHint => 'Tampal kunci API penyedia';

  @override
  String get credentialsBrowserLogin => 'Log masuk melalui pelayar';

  @override
  String get credentialsSignInAgain => 'Log masuk semula';

  @override
  String get credentialsWaitingForLogin =>
      'Menunggu kebenaran dalam pelayar anda…';

  @override
  String get credentialsLoginTimedOut =>
      'Sesi log masuk telah luput. Mulakan percubaan log masuk baharu.';

  @override
  String get credentialsCopyCode => 'Salin kod';

  @override
  String get credentialsDeviceCodeHint =>
      'Sahkan kod ini pada halaman penyedia. Pastikan skrin ini terbuka sementara pelayan melengkapkan log masuk.';

  @override
  String get credentialsPasteRedirect => 'Kod kebenaran atau URL ubah hala';

  @override
  String get credentialsPasteRedirectHint =>
      'Tampal kod atau URL ubah hala penuh daripada penyedia';

  @override
  String get credentialsCompleteLogin => 'Lengkapkan log masuk';

  @override
  String get credentialsRedirectUnavailable =>
      'Panggil balik pelayar pelayan ini tidak dapat dicapai dengan selamat daripada telefon. Minta pemilik pelayan menetapkan panggil balik HTTPS awam atau tambah token sebagai ganti.';

  @override
  String get credentialsUpdateToken => 'Kemas kini token';

  @override
  String get credentialsAddToken => 'Tambah token';

  @override
  String get credentialsPersonalToken => 'Token akses peribadi';

  @override
  String get credentialsPersonalTokenHint => 'Tampal token akses peribadi';

  @override
  String get credentialsHostManaged =>
      'Sambungan ini datang daripada aplikasi atau persekitaran pelayan. Hanya pemilik pelayan boleh mengubahnya di sana; anda masih boleh menambah token sendiri.';

  @override
  String get credentialsStopWatching => 'Berhenti memantau';
}
