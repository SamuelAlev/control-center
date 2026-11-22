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
  String get teammate => 'Rakan sepasukan';

  @override
  String get systemSender => 'Sistem';

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
  String get sentAttachmentUnavailable => 'Lampiran tidak tersedia';

  @override
  String get sentAttachmentLoadFailed => 'Tidak dapat memuatkan lampiran';

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
  String get mobilePrSelectCommentLine => 'Pilih baris untuk diulas';

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
  String get permissionPrPublish => 'Kemas kini atau gabungkan pull request';

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
  String get permissionRemembered => 'Kelulusan sementara';

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
  String permissionTools(String tools) {
    return 'Alat: $tools';
  }

  @override
  String get permissionNotInEffect =>
      'Tidak berkuat kuasa semasa tindakan ini ditolak';

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
  String mobileGoalFailures(String count) {
    return 'Larian gagal berturut-turut: $count';
  }

  @override
  String get mobileGoalFailedDescription =>
      'Penyelia berhenti selepas larian gagal berulang kali. Semak perbualan untuk butiran.';

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
  String get transcriptToolTodos => 'Tugas';

  @override
  String get transcriptToolSearchMemory => 'Cari dalam ingatan';

  @override
  String get transcriptToolRenderMedia => 'Paparkan media';

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
      'Pelayar melaporkan pemberitahuan disekat. Semak kebenaran tapak ini dan tetapan pemberitahuan pelayar atau peranti, kemudian muat semula.';

  @override
  String get pushOsHint =>
      'Pelayar anda juga memerlukan kebenaran untuk memaparkan pemberitahuan dalam tetapan sistem peranti.';

  @override
  String get pushServiceUnavailable =>
      'Perkhidmatan tolak pelayar menolak langganan. Sesetengah pelayar, seperti Brave, mematikannya secara lalai: cari pilihan mesej tolak dalam tetapan privasi pelayar, kemudian cuba lagi.';

  @override
  String get pushWorkerUnavailable =>
      'Perkhidmatan pemberitahuan tidak dapat dimulakan dalam pelayar ini. Muat semula halaman dan cuba lagi.';

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
  String get credentialsConnectCodePrompt => 'Kod pengesahan';

  @override
  String get credentialsConnectCodeMalformed =>
      'Itu tidak kelihatan seperti kod log masuk. Kod terdiri daripada 8 huruf dan digit.';

  @override
  String get credentialsSignInInvalidCode =>
      'Kod itu tidak sepadan dengan log masuk ini. Semak dan cuba lagi.';

  @override
  String get credentialsSignInTooManyCodes =>
      'Terlalu banyak kod yang salah. Mulakan semula log masuk.';

  @override
  String get credentialsSignInRetryLater =>
      'Perkhidmatan log masuk tidak bertindak balas sekarang. Tunggu seminit, kemudian cuba lagi.';

  @override
  String get credentialsSignInRefused =>
      'Log masuk ditolak. Mulakannya semula dan luluskan setiap kebenaran yang diminta.';

  @override
  String get credentialsSignInNotSaved =>
      'Log masuk berjaya, tetapi pelayan tidak dapat menyimpannya. Cuba lagi.';

  @override
  String credentialsSignInUnavailable(String provider) {
    return 'Log masuk ke $provider belum disediakan pada pelayan ini.';
  }

  @override
  String get credentialsSignInPhoneUnreachable =>
      'Alamat panggilan balik log masuk pelayan ini tidak boleh dicapai dengan selamat dari telefon. Log masuk daripada aplikasi desktop, atau minta pemilik pelayan menyediakan alamat HTTPS awam.';

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
  String get credentialsUpdateToken => 'Kemas kini token';

  @override
  String get credentialsAddToken => 'Tambah token';

  @override
  String get credentialsPersonalToken => 'Token akses peribadi';

  @override
  String get credentialsPersonalTokenHint => 'Tampal token akses peribadi';

  @override
  String get credentialsStopWatching => 'Berhenti memantau';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'Log masuk Claude Code telah tamat tempoh';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'Larian berhenti kerana akaunnya tidak lagi disahkan. Log masuk semula, kemudian cuba semula giliran ini.';

  @override
  String get transcriptSignInExpiredTitle =>
      'Log masuk penyedia telah tamat tempoh';

  @override
  String get transcriptSignInExpiredBody =>
      'Larian berhenti kerana kelayakan penyedianya tidak lagi berfungsi. Sambung semula dalam Tetapan → Penyedia, kemudian cuba semula giliran ini.';

  @override
  String get permissionHostExecution => 'Jalankan arahan pada hos';

  @override
  String credentialsSignInLapsed(String provider) {
    return 'Log masuk $provider anda telah tamat. Log masuk semula.';
  }

  @override
  String get credentialsSignInPaused =>
      'Dijeda: perkhidmatan log masuk ruang kerja ini telah berubah. Ia berfungsi semula apabila perkhidmatan kembali.';

  @override
  String credentialsProviderUnreachable(String provider) {
    return '$provider tidak dapat dihubungi sekarang. Mencuba semula.';
  }

  @override
  String get credentialsScopeWorkspace => 'Ruang kerja ini sahaja';

  @override
  String get credentialsScopeAllWorkspaces => 'Semua ruang kerja';

  @override
  String get credentialsRemoveConfirmWorkspace =>
      'Alih keluar kelayakan tersimpan anda daripada ruang kerja ini? Ruang kerja lain mengekalkan milik mereka.';

  @override
  String get credentialsRemoveConfirmAllWorkspaces =>
      'Alih keluar kelayakan tersimpan anda daripada setiap ruang kerja yang berkongsinya?';

  @override
  String get credentialsSignInServerRestarted =>
      'Pelayan telah dimulakan semula. Mulakan log masuk sekali lagi.';

  @override
  String repoAccessInstallApp(String owner, String names) {
    return 'Pasang GitHub App pada $owner supaya automasi dapat mencapai $names. Ketik untuk membuka GitHub.';
  }

  @override
  String repoAccessAskAdminInstall(String owner, String names) {
    return 'GitHub App belum dipasang pada $owner, jadi automasi tidak dapat mencapai $names. Minta pentadbir ruang kerja memasangnya.';
  }

  @override
  String repoAccessAddToApp(String names) {
    return 'Tambah $names pada repositori GitHub App. Ketik untuk membuka GitHub.';
  }

  @override
  String repoAccessAskAdminAdd(String names) {
    return 'GitHub App belum dapat melihat $names. Minta pentadbir ruang kerja menambahnya pada repositorinya.';
  }

  @override
  String repoAccessSuspended(String names) {
    return 'Pemasangan GitHub App digantung. Automasi untuk $names dijeda sehingga pemilik akaun menyambung semula pemasangan di GitHub.';
  }

  @override
  String repoAccessOwnerCannotSee(String names) {
    return 'Orang yang bertanggungjawab atas automasi ruang kerja ini tidak lagi dapat melihat $names, jadi tiada apa-apa berjalan di sana bagi pihaknya.';
  }

  @override
  String repoAccessOwnerNotSignedIn(String names) {
    return 'Orang yang bertanggungjawab atas automasi ruang kerja ini belum log masuk ke forge, jadi automasi untuk $names menunggu sehingga mereka log masuk.';
  }

  @override
  String repoAccessRetrying(String names) {
    return 'Tidak dapat menyemak akses ke $names. Mencuba semula.';
  }

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Log masuk ke $forge untuk melihat pull request daripada $count lagi repositori',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count repositori disembunyikan kerana akaun $forge anda tidak dapat melihatnya',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count repositori disembunyikan kerana anda tiada akses dalam ruang kerja ini',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Menyemak akses anda ke $count lagi repositori…',
    );
    return '$_temp0';
  }

  @override
  String get credentialsAtlassianEmail => 'E-mel akaun Atlassian';

  @override
  String get credentialsAtlassianEmailInvalid =>
      'Masukkan alamat e-mel akaun Atlassian anda.';

  @override
  String get credentialsBitbucketApiToken => 'Token API';

  @override
  String repoAccessAutomationTokenMissing(String names) {
    return 'Tiada token automasi yang dapat membaca $names, jadi kerja latar belakang di sana dijeda. Pentadbir boleh menambahnya di Tetapan → Repositori.';
  }

  @override
  String get credentialsSignInConfirmInBrowser =>
      'Sahkan dalam pelayar anda, kemudian masukkan kod yang dipaparkannya.';

  @override
  String get credentialsSignInAccountAlreadyBound =>
      'Akaun ini sudah disambungkan kepada orang lain pada pelayan ini. Log masuk dengan akaun yang berbeza.';

  @override
  String credentialsTokenUnreachable(String provider) {
    return '$provider tidak dapat dihubungi untuk menyemak token ini. Cuba sebentar lagi.';
  }

  @override
  String credentialsTokenRejected(String provider) {
    return '$provider tidak menerima token ini. Semak sama ada anda menyalin semuanya dan ia belum dibatalkan.';
  }

  @override
  String credentialsTokenWrongKind(String provider) {
    return 'Ini bukan token peribadi. Tampal token akses peribadi daripada akaun $provider anda sendiri, bukan token projek, kumpulan, ruang kerja atau bot.';
  }

  @override
  String credentialsTokenNarrowScope(String scope) {
    return 'Token ini tidak mempunyai skop $scope, yang diperlukan untuk semakan dan ulasan. Cipta satu yang mempunyainya.';
  }

  @override
  String get credentialsTokenExpired =>
      'Token ini telah tamat tempoh. Cipta yang baharu dan tampalkannya di sini.';

  @override
  String get credentialsSignInRateLimited =>
      'Terlalu banyak permintaan sekarang. Tunggu sebentar, kemudian cuba lagi.';

  @override
  String get credentialsSignInCancelled =>
      'Log masuk dibatalkan atau ditolak. Mulakannya semula apabila anda sudah bersedia.';

  @override
  String get credentialsSignInNoLongerOpen =>
      'Log masuk ini tidak lagi dibuka: ia telah dibatalkan, digunakan atau digantikan. Mulakannya semula.';

  @override
  String get noWorkspacesYetHint =>
      'Admin ruang kerja perlu menjemput anda, atau pemilik pelayan boleh mencipta ruang kerja untuk anda.';

  @override
  String repoAccessReplaced(String repos, String forge) {
    return '$repos kini menunjuk kepada repositori yang berbeza pada $forge. Pautkannya semula dari apl desktop atau web untuk terus menggunakannya.';
  }

  @override
  String repoAccessAskAdminRelink(String repos, String forge) {
    return '$repos kini menunjuk kepada repositori yang berbeza pada $forge. Admin ruang kerja perlu memautkannya semula sebelum ia boleh digunakan semula.';
  }

  @override
  String get runSandboxUnavailableTitle =>
      'Ejen memerlukan kotak pasir pada pelayan ini';

  @override
  String get runSandboxUnavailable =>
      'Pelayan ini tiada kotak pasir, jadi hanya pemiliknya boleh menjalankan ejen di sini. Pemilik boleh memasang kotak pasir atau mematikan kotak pasir untuk semua orang.';

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
    return '$count sedang berjalan';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count berjaya';
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
    return '$count dalam barisan';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count dilangkau';
  }

  @override
  String get scriptStepQueued => 'Dalam barisan';

  @override
  String get scriptStepSkipped => 'Dilangkau';

  @override
  String get scriptGroupLoop => 'Gelung';

  @override
  String get scriptGroupEach => 'Untuk setiap';

  @override
  String get scriptGroupParallel => 'Selari';

  @override
  String get scriptGroupFunction => 'Fungsi';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tunjuk $count panggilan lagi',
      one: 'Tunjuk 1 panggilan lagi',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced =>
      'Panggilan yang tidak diletakkan dalam skrip';

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
  String get scriptStateTimedOut => 'Masa tamat';

  @override
  String get scriptStateCancelled => 'Dibatalkan';

  @override
  String get scriptStateMemoryExceeded => 'Memori habis';

  @override
  String get scriptStateOutputExceeded => 'Output terlalu banyak';

  @override
  String get scriptStateSandboxError => 'Ralat kotak pasir';

  @override
  String get scriptStateRefused => 'Ditolak';

  @override
  String get scriptOriginLine =>
      'Daripada skrip yang sedang dijalankan oleh ejen';

  @override
  String get codeModeTitle => 'Mod kod';

  @override
  String get codeModeAvailable => 'Tersedia';

  @override
  String get codeModeUnavailable => 'Tidak tersedia';

  @override
  String codeModeUnavailableNote(String reason) {
    return 'Pelayan ini tidak boleh menjalankan skrip, jadi ejen di sini memanggil alatnya satu demi satu. Pelayan berkata: $reason';
  }

  @override
  String get codeModeNoReason => 'tiada sebab diberikan.';

  @override
  String get workKindUnknown => 'Atas sebab yang versi ini tidak namakan:';

  @override
  String get workRefusalUnknown => 'Pelayan menolak ini:';

  @override
  String workActionFailed(String error) {
    return 'Tidak berjaya: $error';
  }

  @override
  String get wakeKindStopped => 'Ditahan kerana seseorang menghentikan larian.';

  @override
  String get wakeKindAttempts => 'Penghantaran gagal tiga kali.';

  @override
  String get wakeKindAgentDeleted => 'Ejen itu tidak wujud lagi.';

  @override
  String get wakeKindAgentNotDispatchable => 'Ejen itu telah bersara.';

  @override
  String get wakeKindAgentPaused => 'Ejen itu dijeda.';

  @override
  String get wakeKindPersonRemoved =>
      'Orang yang diwakilinya telah keluar daripada ruang kerja.';

  @override
  String get wakeKindBudgetBlocked => 'Bajet menyekat larian.';

  @override
  String get wakeKindTakeOver => 'Seseorang telah mengambil alih worktree.';

  @override
  String get wakeKindRateCapConversation =>
      'Perbualan ini telah memulakan 30 larian daripada panggilan bangun dalam sejam yang lalu.';

  @override
  String get wakeKindRateCapWorkspace =>
      'Ruang kerja ini telah memulakan 300 larian daripada panggilan bangun dalam sejam yang lalu.';

  @override
  String get wakeKindLiveRunNoInput =>
      'Larian langsung ejen di sini tidak menerima input.';

  @override
  String get wakeKindLiveRunOtherOptions =>
      'Larian langsung ejen di sini berjalan dengan cara yang berbeza, jadi ini memulakan larian sendiri selepas itu.';

  @override
  String get wakeKindLiveRunOtherPerson =>
      'Larian langsung ejen di sini bertindak untuk orang lain, jadi ini memulakan larian sendiri selepas itu.';

  @override
  String get wakeKindDispatchRefused => 'Larian tidak dapat dimulakan.';

  @override
  String get wakeKindSandboxUnavailable =>
      'Tiada kotak pasir tersedia untuk larian baca sahaja.';

  @override
  String get wakeKindReadOnlyUnavailable =>
      'Backend ejen ini tidak dapat mengekalkan larian sebagai baca sahaja.';

  @override
  String get wakeKindServerStopped =>
      'Pemulaan semula pelayan menghentikan larian.';

  @override
  String get wakeKindServerRestarted =>
      'Pelayan dimulakan semula semasa larian seseorang.';

  @override
  String get wakeKindGuardFailed => 'Satu semakan sebelum penghantaran gagal.';

  @override
  String get wakeKindLimit =>
      'Menunggu had penggunaan penyedia ditetapkan semula.';

  @override
  String get wakeKindLimitRunLive => 'Menunggu larian di had penggunaan tamat.';

  @override
  String get wakeKindWakeMissed => 'Terlepas semasa pelayan tidak aktif.';

  @override
  String get wakeKindPipelineRunEnded => 'Larian pipelinenya telah tamat.';

  @override
  String get wakeKindGoalEnded => 'Matlamatnya telah tamat.';

  @override
  String get wakeKindGoalBudgetExhausted =>
      'Matlamatnya telah menggunakan bajetnya.';

  @override
  String get wakeKindGoalReviewStale =>
      'Matlamat telah berubah sejak kajian ini diminta.';

  @override
  String get wakeKindGoalPaused => 'Matlamatnya dijeda.';

  @override
  String get wakeKindGoalHeld => 'Matlamatnya sedang ditahan.';

  @override
  String get wakeKindGoalStopped => 'Matlamatnya telah dihentikan.';

  @override
  String get wakeKindAskSettled => 'Soalan yang dijawabnya telah diselesaikan.';

  @override
  String get wakeKindRuleEnded => 'Jadualnya telah tamat.';

  @override
  String get wakeRefusalNotYours =>
      'Panggilan bangun ini bertindak untuk orang lain. Hanya mereka boleh menghantar, menyambung atau membatalkannya.';

  @override
  String get wakeRefusalSettled => 'Panggilan bangun ini telah selesai.';

  @override
  String get goalRefusalAlreadyActive =>
      'Ejen ini sudah mempunyai matlamat yang aktif.';

  @override
  String get goalRefusalNotInReview =>
      'Matlamat ini tidak sedang menunggu kajian.';

  @override
  String get goalRefusalEvidenceIncomplete =>
      'Bukti matlamat ini tidak lengkap.';

  @override
  String get goalRefusalClaimPending =>
      'Dakwaan bahawa ia telah selesai masih disemak.';

  @override
  String get goalRefusalNotActiveSegment =>
      'Tiada segmen sedang berjalan untuk matlamat ini.';

  @override
  String get goalRefusalNotYours =>
      'Hanya orang yang memulakan matlamat ini boleh melakukannya.';

  @override
  String get goalRefusalNotPaused => 'Jedakan matlamat dahulu.';

  @override
  String get goalRefusalContractInvalid =>
      'Kontrak matlamat tidak dapat dibaca.';

  @override
  String get goalRefusalCheckerUnknown => 'Tiada ejen dengan nama itu.';

  @override
  String get goalRefusalCheckerAmbiguous =>
      'Lebih daripada satu ejen mempunyai nama itu.';

  @override
  String get goalRefusalCheckerIsGoalAgent =>
      'Penyemak mesti ejen yang lain daripada ejen yang membuat kerja.';

  @override
  String get goalRefusalCommandInvalid => 'Matlamat ini tidak dapat dibaca:';

  @override
  String get wakeRuleRefusalIntervalTooShort =>
      'Sela itu terlalu pendek. Pilih sekurang-kurangnya satu minit.';

  @override
  String get wakeRuleRefusalTooSoon =>
      'Masa itu terlalu awal. Pilih masa yang lebih lewat.';

  @override
  String get wakeRuleRefusalLineageEnded =>
      'Rantaian panggilan bangun ini telah menggunakan larian atau masanya.';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable =>
      'Anda tidak dapat membaca perkara yang akan dipantau ini.';

  @override
  String get wakeRuleRefusalExpiryRequired =>
      'Berikan tarikh tamat atau bilangan larian.';

  @override
  String get wakeRuleRefusalLimitReached =>
      'Perbualan atau ejen ini sudah mempunyai seberapa banyak jadual yang dibenarkan.';

  @override
  String get wakeRuleRefusalInvalidWhen => 'Masa itu tidak dapat dibaca.';

  @override
  String get wakeRuleRefusalNoteTooLong => 'Nota itu terlalu panjang.';

  @override
  String get wakeRuleRefusalExpiryTooLong => 'Tarikh tamat itu terlalu jauh.';

  @override
  String get wakeRuleRefusalLimitOutOfRange =>
      'Had larian, hari atau bajet berada di luar julat.';

  @override
  String get wakeRuleRefusalNextOutsideLoop =>
      'Hanya gelung boleh memilih masa seterusnya sendiri.';

  @override
  String get wakeRuleRefusalWatchRefused => 'Itu tidak boleh dipantau.';

  @override
  String get wakeRuleRefusalRuleEnded => 'Jadual itu telah tamat.';

  @override
  String get wakeRuleRefusalNotYours => 'Jadual itu milik orang lain.';

  @override
  String get wakeRuleEndFired => 'Ia berjalan sekali.';

  @override
  String get wakeRuleEndExpired => 'Ia telah sampai tarikh tamatnya.';

  @override
  String get wakeRuleEndRunCap =>
      'Ia telah menggunakan larian yang dibenarkan.';

  @override
  String get wakeRuleEndCostCap => 'Ia telah mencapai had kosnya.';

  @override
  String get wakeRuleEndGoalEnded => 'Matlamatnya telah tamat.';

  @override
  String get wakeRuleEndCancelled => 'Ia telah dibatalkan.';

  @override
  String get wakeRuleEndMemberRemoved =>
      'Orang yang diwakilinya telah keluar daripada ruang kerja.';

  @override
  String get wakeRuleEndInvalidRow =>
      'Tetapan yang disimpan tidak dapat dibaca.';

  @override
  String goalHoldWorking(int segment) {
    final intl.NumberFormat segmentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String segmentString = segmentNumberFormat.format(segment);

    return 'Sedang berfungsi pada segmen $segmentString. Tiada sesiapa perlu bertindak.';
  }

  @override
  String get goalHoldWaiting =>
      'Menunggu kerja yang masih perlu dilakukan. Ia diteruskan dengan sendirinya.';

  @override
  String goalHoldWaitingUntil(String time) {
    return 'Menunggu kerja yang masih perlu dilakukan. Ia akan diteruskan dengan sendirinya pada $time paling lewat.';
  }

  @override
  String get goalHoldVerifying =>
      'Ia mendakwa telah selesai. Pelayan menjalankan semakannya, kemudian penyemak membuat keputusan.';

  @override
  String get goalHoldLimit =>
      'Dijeda di had penggunaan penyedia. Ia disambung dengan sendirinya selepas ditetapkan semula.';

  @override
  String goalHoldLimitUntil(String time) {
    return 'Dijeda di had penggunaan penyedia. Ia disambung dengan sendirinya pada $time.';
  }

  @override
  String get goalHoldPerson =>
      'Menunggu seseorang menjawab dalam perbualan. Ia diteruskan selepas seseorang menjawab.';

  @override
  String get goalHoldByPerson =>
      'Dijeda oleh seseorang. Ia kekal dijeda sehingga seseorang menyambungnya.';

  @override
  String get goalHoldNeedsReview =>
      'Menunggu kajian: ia tidak boleh diteruskan dengan sendirinya. Luluskan sebagai selesai, sambungkannya atau batalkannya.';

  @override
  String get goalHoldBudget =>
      'Ia telah menggunakan bajetnya. Naikkan bajet untuk membenarkannya diteruskan.';

  @override
  String goalHoldLimitParks(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Jeda had penggunaan: $countString daripada $maxString';
  }

  @override
  String get goalHoldDetailStalled =>
      'Tiada kemajuan dalam segmen terakhirnya.';

  @override
  String get goalHoldDetailStalledWaiting =>
      'Ia menunggu 24 jam untuk kerja yang sama tanpa kemajuan.';

  @override
  String get goalHoldDetailVerificationFailed => 'Semakan terakhir gagal.';

  @override
  String get goalHoldDetailCannotVerify =>
      'Penyemak tidak pasti sama ada ia telah selesai.';

  @override
  String get goalHoldDetailSandboxUnavailable =>
      'Tiada kotak pasir tersedia untuk menjalankan semakannya.';

  @override
  String get goalHoldDetailCheckerUnavailable =>
      'Ejen penyemaknya tidak tersedia. Pilih penyemak lain, kemudian sambung.';

  @override
  String get goalHoldDetailCheckBroken => 'Semakan ini tidak dapat dijalankan:';

  @override
  String get goalHoldDetailWakeSkipped => 'Panggilan bangunnya tidak dihantar.';

  @override
  String get goalHoldDetailClaimPending =>
      'Dakwaannya bahawa ia telah selesai sedang menunggu semakan.';

  @override
  String get goalHoldDetailUnanswered =>
      'Soalan atau permintaan kelulusan kepada seseorang tidak dijawab.';

  @override
  String get goalHoldDetailLimitParks =>
      'Ia terlalu kerap mencapai had penggunaan. Semak, kemudian sambung.';

  @override
  String get goalHoldDetailInput => 'Menunggu jawapan dalam perbualan.';

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

    return 'Segmen $runString daripada $maxString';
  }

  @override
  String goalSegmentsNoCap(int run) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);

    return 'Segmen $runString, tanpa had';
  }

  @override
  String goalMoney(String spent, String cap) {
    return 'Dibelanjakan $spent daripada $cap';
  }

  @override
  String goalDeadline(String time) {
    return 'Tarikh akhir $time';
  }

  @override
  String get goalPipelineStep =>
      'Satu langkah pipeline mengusahakan matlamat ini.';

  @override
  String get goalSummaryHeading => 'Ringkasan terakhir';

  @override
  String get goalDoneMeans => 'Maksud siap';

  @override
  String get goalChecks => 'Semakan';

  @override
  String get goalBoundaries => 'Sempadan';

  @override
  String get goalStopWhen => 'Berhenti dan tanya apabila';

  @override
  String get goalNoMachineCheck =>
      'Tiada semakan mesin. Penyemak membuat keputusan daripada apa yang boleh dibacanya.';

  @override
  String get goalCheckEnvironment => 'Tugasan persekitaran';

  @override
  String goalLastCheck(int round, String time) {
    final intl.NumberFormat roundNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String roundString = roundNumberFormat.format(round);

    return 'Semakan terakhir, pusingan $roundString, $time';
  }

  @override
  String get goalClaim => 'Apa yang didakwanya';

  @override
  String get goalCheckPassed => 'Lulus';

  @override
  String goalCheckFailed(int code) {
    return 'Gagal, kod keluar $code';
  }

  @override
  String get goalCheckTimedOut => 'Masa tamat';

  @override
  String get goalCheckNotRerun => 'Tidak dijalankan semula: tiada yang berubah';

  @override
  String get goalCheckBroken => 'Tidak dapat dijalankan';

  @override
  String get goalCriterionMet => 'Dipenuhi';

  @override
  String get goalCriterionUnmet => 'Tidak dipenuhi';

  @override
  String get goalCriterionCannotTell => 'Tidak pasti';

  @override
  String get goalVerdictPass => 'Keputusan: selesai';

  @override
  String get goalVerdictFail => 'Keputusan: belum selesai';

  @override
  String get goalVerdictCannotVerify => 'Keputusan: tidak pasti';

  @override
  String get goalConcerns => 'Kebimbangan';

  @override
  String goalVerifiedBy(String agent) {
    return 'Disahkan oleh $agent';
  }

  @override
  String get goalVerifiedBySelf =>
      'Disahkan oleh dirinya sendiri (tiada penyemak berasingan)';

  @override
  String get goalClosedByPerson =>
      'Ditutup oleh seseorang tanpa semakan yang lulus';

  @override
  String get goalApprove => 'Luluskan penyiapan';

  @override
  String get goalApproveTitle => 'Tutup matlamat ini sebagai selesai?';

  @override
  String get goalApproveBody =>
      'Tiada semakan yang mengesahkannya. Anda menutupnya berdasarkan kata anda sendiri, dan matlamat itu merekodkan bahawa seseorang menutupnya tanpa pengesahan.';

  @override
  String get goalApproveConfirm => 'Tutup sebagai selesai';

  @override
  String get goalResumeNotYours =>
      'Menyambungnya atau menaikkan bajetnya ialah hak orang yang memulakannya.';

  @override
  String get goalChooseChecker => 'Pilih penyemak lain';

  @override
  String goalCheckerSet(String agent) {
    return '$agent kini menyemaknya. Sambung untuk mengesahkan semula.';
  }

  @override
  String get goalSchedules => 'Jadual';

  @override
  String get goalRepeat => 'Ulang';

  @override
  String get goalCreateChecks => 'Semakan (pilihan)';

  @override
  String get goalCreateCheckHint => 'Arahan yang lulus apabila kerja selesai';

  @override
  String get goalCreateAddCheck => 'Tambah semakan';

  @override
  String get goalCreateRemoveCheck => 'Buang semakan';

  @override
  String get goalCreateSegmentCap => 'Had segmen (pilihan)';

  @override
  String get goalCreateSegmentInvalid =>
      'Had segmen ialah nombor bulat, sekurang-kurangnya 1.';

  @override
  String get scheduleCreateTitle => 'Ulang satu arahan';

  @override
  String get scheduleCadence => 'Setiap berapa kerap';

  @override
  String get scheduleEveryMinutes => 'Setiap N minit';

  @override
  String get scheduleEveryHours => 'Setiap N jam';

  @override
  String get scheduleSelfPaced => 'Mengikut rentak ejen';

  @override
  String get scheduleSelfPacedHint =>
      'Ejen memilih kelewatan selepas setiap larian, antara 1 minit dan 1 jam.';

  @override
  String get scheduleInterval => 'Sela';

  @override
  String get scheduleNote => 'Apa yang perlu dilakukan setiap larian?';

  @override
  String get scheduleCostCap => 'Had kos dalam USD (pilihan)';

  @override
  String get scheduleExpiryDays => 'Tamat selepas N hari (pilihan)';

  @override
  String get scheduleCreateInvalid =>
      'Pilih ruang dan ejen, tulis apa yang perlu dilakukan setiap larian, dan beri nombor bulat sekurang-kurangnya 1.';

  @override
  String get scheduleCreateButton => 'Mulakan jadual';

  @override
  String get scheduleCreateConfirmTitle => 'Mulakan jadual ini?';

  @override
  String scheduleCreateConfirmEveryMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ia berjalan setiap $countString minit, bermula sekarang.',
      one: 'Ia berjalan setiap minit, bermula sekarang.',
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
      other: 'Ia berjalan setiap $countString jam, bermula sekarang.',
      one: 'Ia berjalan setiap jam, bermula sekarang.',
    );
    return '$_temp0';
  }

  @override
  String get scheduleCreateConfirmSelfPaced =>
      'Ia berjalan sekarang, kemudian ejen memilih bila untuk berjalan semula.';

  @override
  String get scheduleCreated =>
      'Jadual dimulakan. Ia disenaraikan di bawah Jadual.';

  @override
  String get schedulesTitle => 'Jadual';

  @override
  String get schedulesLoadFailed => 'Jadual tidak dapat dimuatkan';

  @override
  String get schedulesEmpty => 'Tiada jadual atau pantauan';

  @override
  String get schedulesEmptyDescription =>
      'Ulang arahan daripada skrin matlamat, atau hantar /loop atau /schedule dalam perbualan.';

  @override
  String get scheduleMissing =>
      'Jadual ini tidak lagi tersedia dalam ruang kerja ini.';

  @override
  String scheduleEvery(String interval) {
    return 'Setiap $interval';
  }

  @override
  String get scheduleSelfPacedLoop => 'Gelung mengikut rentak ejen';

  @override
  String get scheduleCron => 'Jadual cron';

  @override
  String scheduleOnce(String time) {
    return 'Sekali pada $time';
  }

  @override
  String scheduleWatch(String event) {
    return 'Pantauan: $event';
  }

  @override
  String get scheduleWatchPrChecks => 'semakan pull request';

  @override
  String get scheduleWatchPrReview => 'ulasan pull request';

  @override
  String get scheduleWatchPrMerged => 'penggabungan pull request';

  @override
  String get scheduleWatchEnvironment => 'persekitaran';

  @override
  String get scheduleWatchTicket => 'tiket';

  @override
  String get scheduleWatchPipelineRun => 'larian pipeline';

  @override
  String get scheduleStatusActive => 'Aktif';

  @override
  String get scheduleStatusPaused => 'Dijeda';

  @override
  String get scheduleStatusEnded => 'Tamat';

  @override
  String scheduleWakes(String agent) {
    return 'Membangunkan $agent';
  }

  @override
  String scheduleNext(String time) {
    return 'Larian seterusnya $time';
  }

  @override
  String scheduleLast(String time) {
    return 'Larian terakhir $time';
  }

  @override
  String scheduleRuns(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString larian',
      one: '1 larian',
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

    return '$countString daripada $maxString larian';
  }

  @override
  String scheduleSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString dilangkau',
      one: '1 dilangkau',
    );
    return '$_temp0';
  }

  @override
  String scheduleEnds(String time) {
    return 'Tamat $time';
  }

  @override
  String scheduleChain(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Sebahagian daripada rantaian: tinggal $countString larian, tamat $time';
  }

  @override
  String get scheduleNoteAgent => 'Nota ejen itu sendiri, dengan kata-katanya:';

  @override
  String get scheduleNotePerson => 'Nota seseorang:';

  @override
  String scheduleActsFor(String name) {
    return 'Bertindak untuk $name';
  }

  @override
  String get scheduleActsForBot => 'Tidak bertindak untuk sesiapa';

  @override
  String get scheduleGoalBound => 'Ia tamat bersama matlamatnya.';

  @override
  String get schedulePause => 'Jeda';

  @override
  String get scheduleResume => 'Sambung';

  @override
  String get scheduleDelete => 'Padam';

  @override
  String get scheduleRemove => 'Buang';

  @override
  String get scheduleDeleteTitle => 'Padam jadual ini?';

  @override
  String get scheduleDeleteBody =>
      'Ia berhenti selama-lamanya. Apa-apa yang telah dilakukannya tidak dibatalkan.';

  @override
  String get scheduleRemoveTitle => 'Buang jadual ini?';

  @override
  String get scheduleRemoveBody => 'Ia hilang daripada senarai.';

  @override
  String get scheduleResumeNotYours =>
      'Hanya orang yang diwakili oleh jadual ini boleh menyambungnya.';

  @override
  String get scheduleResumeAdminOnly =>
      'Hanya pentadbir ruang kerja boleh menyambung jadual yang tiada sesiapa miliki.';

  @override
  String get scheduleOpenConversation => 'Buka perbualan';

  @override
  String get progressWaiting => 'Menunggu';

  @override
  String get progressNothingWaiting => 'Tiada yang menunggu.';

  @override
  String get wakeOriginGoal => 'Matlamat';

  @override
  String get wakeOriginGoalCheck => 'Semakan matlamat';

  @override
  String get wakeOriginGoalReview => 'Kajian matlamat';

  @override
  String get wakeOriginSchedule => 'Jadual';

  @override
  String get wakeOriginWatch => 'Pantauan';

  @override
  String get wakeOriginReply => 'Balasan';

  @override
  String get wakeOriginMessage => 'Mesej';

  @override
  String get wakeOriginWorkFinished => 'Kerja selesai';

  @override
  String get wakeOriginLimitReset => 'Had ditetapkan semula';

  @override
  String get wakeOriginRecovery => 'Pemulihan';

  @override
  String get wakeOriginAssignment => 'Tugasan';

  @override
  String get wakeOriginPipelineStep => 'Langkah pipeline';

  @override
  String get wakeOriginImprovementReview => 'Kajian penambahbaikan';

  @override
  String wakeOriginReplyFrom(String agent) {
    return 'Balasan daripada $agent';
  }

  @override
  String wakeOriginMessageFrom(String agent) {
    return 'Mesej daripada $agent';
  }

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return 'Kerja selesai daripada $agent';
  }

  @override
  String wakeFor(String agent) {
    return 'Untuk $agent';
  }

  @override
  String wakeDue(String time) {
    return 'Tiba pada $time';
  }

  @override
  String get wakeDueNow => 'Tiba sekarang';

  @override
  String get wakeHeld => 'Ditahan';

  @override
  String wakeExpires(String time) {
    return 'Tamat pada $time';
  }

  @override
  String wakeAttempt(int attempt) {
    final intl.NumberFormat attemptNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attemptString = attemptNumberFormat.format(attempt);

    return 'Percubaan $attemptString';
  }

  @override
  String get wakeCancel => 'Batal';

  @override
  String get wakeDeliverNow => 'Hantar sekarang';

  @override
  String get wakeResume => 'Sambung';

  @override
  String get wakeDismiss => 'Tolak';

  @override
  String get wakeResumeOnlyTheirs =>
      'Hanya orang yang larian ini milik boleh menyambungnya.';

  @override
  String get wakeRecovery =>
      'Pelayan dimulakan semula semasa larian ini. Sambung untuk meneruskannya, atau tolak.';

  @override
  String limitParkTitle(String provider, String time) {
    return 'Dijeda pada had penggunaan $provider, yang ditetapkan semula pada $time. Larian menunggu Sambung, sehingga 7 hari selepas penetapan semula.';
  }

  @override
  String limitParkTitleUnnamed(String time) {
    return 'Dijeda pada had penggunaan penyedia, yang ditetapkan semula pada $time. Larian menunggu Sambung, sehingga 7 hari selepas penetapan semula.';
  }

  @override
  String get limitParkResumeNow => 'Sambung sekarang';

  @override
  String get limitParkCancel => 'Batal';

  @override
  String limitParkResumed(String provider) {
    return 'Disambung selepas had penggunaan $provider.';
  }

  @override
  String limitParkGone(String provider) {
    return 'Tidak lagi menunggu di had penggunaan $provider.';
  }

  @override
  String get limitParkProviderUnknown => 'penyedia';

  @override
  String get mobileHeldMessages => 'Mesej ditahan';

  @override
  String get heldSteeringTitle =>
      'Ditahan kerana larian tamat sebelum sempat mengambilnya. Hantar mesej anda sekarang atau buangkannya.';

  @override
  String get heldSteeringRelease => 'Hantar mesej yang ditahan';

  @override
  String get notifGoalCompleted => 'Matlamat selesai';

  @override
  String get notifGoalFailed => 'Matlamat gagal';

  @override
  String get notifGoalCancelled => 'Matlamat dibatalkan';

  @override
  String get notifGoalBudgetExhausted => 'Matlamat telah menggunakan bajetnya';

  @override
  String get notifGoalNeedsReview => 'Satu matlamat menunggu kajian anda';

  @override
  String get notifGoalNeedsPerson => 'Satu matlamat memerlukan anda';

  @override
  String get notifGoalOnHold => 'Satu matlamat sedang ditahan';

  @override
  String get notifWakeRuleEnded => 'Satu jadual telah tamat';

  @override
  String notifWaitingDigest(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString perkara menunggu anda',
      one: '1 perkara menunggu anda',
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
      other: '$countString penambahbaikan dicadangkan',
      one: 'Satu penambahbaikan dicadangkan',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld =>
      'Satu larian pipeline ditahan pada bajetnya';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return 'Dibelanjakan $spent daripada $cap';
  }

  @override
  String get notifNeedsYou => 'Memerlukan anda';

  @override
  String get notifDigestGoalReview => 'Matlamat menunggu kajian';

  @override
  String get notifDigestGoalPerson => 'Matlamat memerlukan seseorang';

  @override
  String get notifDigestHeldWake => 'Panggilan bangun ditahan';

  @override
  String get notifDigestImprovement => 'Penambahbaikan yang dicadangkan';

  @override
  String get wakeKindRulePaused => 'Jadualnya dijeda.';

  @override
  String get wakeKindRuleBusy =>
      'Ejen sedang sibuk, dan jadual ini melangkau masa apabila ia sibuk.';

  @override
  String get wakeKindRuleFolded =>
      'Peristiwa kemudian bagi pantauan yang sama mengambil tempatnya.';

  @override
  String get wakeKindRuleSuperseded =>
      'Masa kemudian bagi jadualnya menggantikannya.';

  @override
  String get wakeKindRuleNotified =>
      'Jadualnya hanya menghantar notifikasi, jadi tiada larian dimulakan.';

  @override
  String get wakeKindRuleLimitParked =>
      'Jadualnya menunggu had penggunaan penyedia ditetapkan semula.';

  @override
  String get improvementRefusalCooldown =>
      'Kajian penambahbaikan dijalankan dalam perbualan ini sebentar tadi. Cuba lagi kemudian.';

  @override
  String get improvementRefusalQueued =>
      'Kajian penambahbaikan perbualan ini sudah menunggu untuk dijalankan.';

  @override
  String get improvementRefusalAgentNotFound =>
      'Ejen itu bukan ejen dalam ruang kerja ini.';

  @override
  String get steeringRefusalHeldByLimit =>
      'Mesej yang ditahan di had penggunaan tidak boleh dihantar secara manual. Ia menunggu larian yang dijeda disambung.';

  @override
  String limitParkCancelled(String provider) {
    return 'Menunggu di had penggunaan $provider telah dibatalkan.';
  }

  @override
  String limitParkExpired(String provider) {
    return 'Menunggu di had penggunaan $provider luput sebelum larian disambung.';
  }

  @override
  String limitParkSkipped(String provider) {
    return 'Larian tidak disambung selepas had penggunaan $provider.';
  }

  @override
  String get heldSteeringLimitTitle =>
      'Ditahan semasa larian menunggu had penggunaan ditetapkan semula. Ini dihantar apabila orang yang larian ini bekerja untuk menyambungkannya.';

  @override
  String heldSteeringLimitAt(String time) {
    return 'Ditahan sehingga had penggunaan ditetapkan semula pada $time. Ini dihantar apabila orang yang larian ini bekerja untuk menyambungkannya.';
  }

  @override
  String get heldSteeringOtherTitle =>
      'Ditahan oleh pelayan. Anda boleh membuangnya.';

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
    return 'Panggilan bangun untuk $agent terlepas semasa pelayan tidak aktif.';
  }

  @override
  String workRowWakeSkipped(String agent) {
    return 'Panggilan bangun untuk $agent tidak dihantar.';
  }

  @override
  String workRowScheduleCreated(String agent) {
    return 'Jadual ditetapkan untuk $agent.';
  }

  @override
  String workRowScheduleEnded(String agent) {
    return 'Jadual $agent telah tamat.';
  }

  @override
  String workRowNoteFromAgent(String agent) {
    return 'Nota jadual daripada $agent:';
  }

  @override
  String get workRowNoteFromPerson => 'Nota jadual daripada seseorang:';

  @override
  String workRowCommandRefusedNamed(String command) {
    return 'Arahan $command ditolak.';
  }

  @override
  String get workRowCommandRefused => 'Satu arahan ditolak.';

  @override
  String workRowCapRaised(String person, String from, String to) {
    return '$person menaikkan had belanjawan pipeline daripada $from kepada $to.';
  }

  @override
  String workRowCapRaisedNoAmounts(String person) {
    return '$person menaikkan had belanjawan pipeline.';
  }

  @override
  String get workRowApplyIncomplete =>
      'Perubahan yang diterima kepada kemahiran ini tidak dapat diselesaikan, kerana kemahiran itu berubah sementara itu. Cadangan itu telah dikembalikan.';

  @override
  String get workRowOpenSchedule => 'Buka jadual';

  @override
  String get heldSteeringOthersTitle =>
      'Ditahan kerana larian tamat sebelum sempat mengambilnya. Hanya orang yang menulis mesej boleh menghantarnya.';

  @override
  String get heldSteeringOnlyYours =>
      'Hanya menghantar mesej anda. Yang lain menunggu untuk orang yang menulisnya.';

  @override
  String heldSteeringWrittenBy(String name) {
    return 'Ditulis oleh $name';
  }

  @override
  String get steeringRefusalNotYours =>
      'Hanya orang yang menulis mesej ditahan boleh menghantarnya, dan tiada satu pun daripada ini milik anda.';

  @override
  String get steeringRefusalNeedsWrite =>
      'Anda memerlukan akses tulis kepada repositori ruang ini untuk mengarahkan larian yang bertindak untuk orang lain.';

  @override
  String workRowSchedulePaused(String name, String agent) {
    return '$name menjeda jadual untuk $agent.';
  }

  @override
  String get goalVerdictObjective => 'Objektif secara keseluruhan';

  @override
  String get notifDigestRequest => 'Menunggu jawapan anda';
}
