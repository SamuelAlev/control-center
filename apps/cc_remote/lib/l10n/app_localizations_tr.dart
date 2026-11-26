// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Geri';

  @override
  String get cancel => 'İptal';

  @override
  String get retry => 'Yeniden dene';

  @override
  String get tryAgain => 'Tekrar dene';

  @override
  String get settings => 'Ayarlar';

  @override
  String get refresh => 'Yenile';

  @override
  String get approve => 'Onayla';

  @override
  String get deny => 'Reddet';

  @override
  String get continueLabel => 'Devam';

  @override
  String get agentQuestionHeader => 'Sizin için soru';

  @override
  String get agentQuestionAnsweredLabel => 'Yanıtlandı';

  @override
  String get agentQuestionSkip => 'Atla';

  @override
  String get agentQuestionSkippedLabel => 'Atlandı';

  @override
  String get agentQuestionFreeformHint => 'Yanıtınızı yazın…';

  @override
  String get agentApprovalRequired => 'Onay gerekli';

  @override
  String get copyCommand => 'Komutu kopyala';

  @override
  String get approveAndRemember => '8 saatliğine onayla';

  @override
  String get decline => 'Reddet';

  @override
  String get confirm => 'Onayla';

  @override
  String get send => 'Gönder';

  @override
  String get close => 'Kapat';

  @override
  String get expand => 'Genişlet';

  @override
  String get zoomIn => 'Yakınlaştır';

  @override
  String get zoomOut => 'Uzaklaştır';

  @override
  String get resetZoom => 'Yakınlaştırmayı sıfırla';

  @override
  String get scanQrPrompt =>
      'Bu telefonu eşlemek için Control Center’daki QR kodunu tarayın.';

  @override
  String get scanQrHelp =>
      'Kamerayı açıp Control Center’da görünen QR koduna tutun. Bu telefon, özel bir bağlantıyla doğrudan bağlanır.';

  @override
  String get connectingToMac => 'Control Center’a bağlanılıyor…';

  @override
  String get connectingDetail => 'Güvenli, doğrudan bir bağlantı kuruluyor.';

  @override
  String get identityChangedTitle => 'Sunucu kimliği değişti';

  @override
  String get identityChangedBody =>
      'Bu sunucu, eşleme sırasında kaydedilen kimlikle artık eşleşmiyor. Sunucu yeniden kurulmuş olabilir — veya bağlantıya müdahale ediliyor olabilir. Güvenlik için bu cihaz bağlanmayacak. Eşlemeyi kaldırın, ardından Control Center’dan yeni bir QR kodu tarayarak yeniden eşleyin.';

  @override
  String get removePairing => 'Eşlemeyi kaldır';

  @override
  String get couldntConnect => 'Bağlanılamadı';

  @override
  String get pendingPairingTitle => 'Bu sunucuya bağlanılsın mı?';

  @override
  String get pendingPairingBody =>
      'Bir bağlantı, Control Center’ın bu sunucuyla eşlenmesini istedi. Yalnızca siz başlattıysanız devam edin.';

  @override
  String get connect => 'Bağlan';

  @override
  String get failureNotPaired =>
      'Eşlenmedi — Control Center’daki QR kodunu tarayın';

  @override
  String get failureUnreachable =>
      'Sunucunuza hiçbir yoldan ulaşılamadı — çalıştığını kontrol edin veya aynı ağı deneyin';

  @override
  String get failureIdentityChanged =>
      'Sunucunun kimliği değişti — yeniden kurulduysa bu cihazı yeniden eşleyin';

  @override
  String get failureAuthRejected =>
      'Sunucu bu cihazı reddetti — Control Center’dan yeniden eşleyin';

  @override
  String get failureUnknown => 'Bağlanılamadı — yeniden denemek için dokunun';

  @override
  String get statusConnected => 'Bağlı';

  @override
  String get statusConnecting => 'Bağlanıyor';

  @override
  String get statusOffline => 'Çevrimdışı';

  @override
  String get statusIdentityMismatch => 'Kimlik uyuşmazlığı';

  @override
  String get statusNotPaired => 'Eşlenmedi';

  @override
  String get statusConfirmPairing => 'Eşlemeyi onayla';

  @override
  String get connectionFailed => 'Bağlantı başarısız';

  @override
  String get identityMismatchBanner =>
      'Sunucu kimliği değişti — bağlantı durduruldu. Devam etmek için bu cihazı yeniden eşleyin.';

  @override
  String get tabInbox => 'Gelen kutusu';

  @override
  String get tabTickets => 'Talepler';

  @override
  String get tabChat => 'Sohbet';

  @override
  String get tabPrs => 'PR’lar';

  @override
  String get tabCalendar => 'Takvim';

  @override
  String get tabNews => 'Haberler';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count bekliyor';
  }

  @override
  String get updateAvailable => 'Yeni bir Control Center sürümü var';

  @override
  String get appearance => 'Görünüm';

  @override
  String get language => 'Dil';

  @override
  String get device => 'Cihaz';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get languageSystem => 'Sistem';

  @override
  String get disconnectTapAgain =>
      'Bu cihazın Control Center ile bağlantısını kesmek için tekrar dokunun';

  @override
  String get disconnectDevice => 'Bu cihazın bağlantısını kes';

  @override
  String get disconnect => 'Bağlantıyı kes';

  @override
  String get chooseWorkspace => 'Çalışma alanı seç';

  @override
  String get workspaces => 'Çalışma alanları';

  @override
  String get workspacesLoadFailed => 'Çalışma alanları yüklenemedi';

  @override
  String get noWorkspacesYet => 'Henüz çalışma alanı yok';

  @override
  String selectWorkspace(String name) {
    return '$name öğesini seç';
  }

  @override
  String get inboxLoadFailed => 'Gelen kutusu yüklenemedi';

  @override
  String get allCaughtUp => 'Hepsi güncel';

  @override
  String get inboxNothingWaiting =>
      'Bloke bir iş yok ve sizi bekleyen pull request yok.';

  @override
  String get blocked => 'Engellendi';

  @override
  String get sectionNeedsYourReview => 'İncelemeniz gerekiyor';

  @override
  String get sectionReturnedToYou => 'Size iade edildi';

  @override
  String get sectionApprovedAndReady => 'Onaylandı ve hazır';

  @override
  String get sectionYourDrafts => 'Taslaklarınız';

  @override
  String get sectionWaitingForReviewers => 'İnceleyenler bekleniyor';

  @override
  String get sectionMergingAndMerged =>
      'Birleştiriliyor ve yeni birleştirilenler';

  @override
  String get sectionWaitingForAuthor => 'Yazar bekleniyor';

  @override
  String waitingAgo(String ago) {
    return 'bekliyor $ago';
  }

  @override
  String get openConversation => 'Sohbeti aç';

  @override
  String get calendarLoadFailed => 'Takvim yüklenemedi';

  @override
  String get nothingScheduled => 'Planlanmış bir şey yok';

  @override
  String get calendarEmptyDescription =>
      'Bağlı takvimlerinizdeki etkinlikler burada görünür.';

  @override
  String get agenda => 'Ajanda';

  @override
  String get syncCalendarsNow => 'Takvimleri şimdi senkronize et';

  @override
  String get event => 'Etkinlik';

  @override
  String get eventNotFound => 'Etkinlik bulunamadı';

  @override
  String get eventNotFoundDescription =>
      'Ajanda penceresinin dışında olabilir veya kaynaktan kaldırılmış olabilir.';

  @override
  String get joinMeeting => 'Toplantıya katıl';

  @override
  String attendeesCount(int count) {
    return 'Katılımcılar ($count)';
  }

  @override
  String get details => 'Ayrıntılar';

  @override
  String get allDay => 'Tüm gün';

  @override
  String get happeningNow => 'Şimdi devam ediyor';

  @override
  String inDuration(String duration) {
    return '$duration içinde';
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
  String get attendeeAccepted => 'kabul etti';

  @override
  String get attendeeDeclined => 'reddetti';

  @override
  String get attendeeMaybe => 'belki';

  @override
  String get attendeeNoReply => 'yanıt yok';

  @override
  String get organizer => 'düzenleyen';

  @override
  String get calendarNoAccounts =>
      'Bu çalışma alanı için bağlı takvim yok. Masaüstü uygulamasından bağlayın — oturum açma, jetonunu sunucuda saklar.';

  @override
  String get calendarReauthNeeded =>
      'Bir takvim hesabının yeniden bağlanması gerekiyor — aşağıdakiler güncel olmayabilir. Masaüstü uygulamasından yeniden bağlayın.';

  @override
  String get spacesLoadFailed => 'Alanlar yüklenemedi';

  @override
  String get noSpaces => 'Alan yok';

  @override
  String get spacesEmptyDescription =>
      'Bu çalışma alanındaki alanlar burada görünür.';

  @override
  String get newSpaceFolder => 'Yeni klasör';

  @override
  String get folderName => 'Klasör adı';

  @override
  String get renameSpaceFolder => 'Klasörü yeniden adlandır';

  @override
  String get deleteSpaceFolder => 'Klasörü sil';

  @override
  String get moveSpaceToFolder => 'Klasöre taşı';

  @override
  String get removeSpaceFromFolder => 'Klasörden çıkar';

  @override
  String get spaceFolderActions => 'Klasör işlemleri';

  @override
  String get deleteFolderWithSpacesWarning =>
      'Alanları kalıcı olarak silmek, mesajlarını ve çalışma dizinlerini herkes için kaldırır. Bu işlem geri alınamaz.';

  @override
  String get deleteSpacesInFolder => 'Bu klasördeki alanları kalıcı olarak sil';

  @override
  String get deleteFolderAndSpaces => 'Klasörü ve alanları sil';

  @override
  String get keepSpacesInFolder =>
      'Aksi takdirde alanlar klasör dışında kalır.';

  @override
  String get create => 'Oluştur';

  @override
  String get otherSpaces => 'Diğer alanlar';

  @override
  String get folderUpdateFailed => 'Klasörler güncellenemedi';

  @override
  String get thread => 'Konu';

  @override
  String get agentWorking => 'Agent çalışıyor';

  @override
  String get messagesLoadFailed => 'İletiler yüklenemedi';

  @override
  String get noMessagesYet => 'Henüz mesaj yok';

  @override
  String get noMessagesDescription =>
      'Sohbeti başlatmak için bir ileti gönderin.';

  @override
  String get agentResponding => 'Ajan yanıtlıyor';

  @override
  String get agentFinished => 'Ajan tamamlandı';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names buradan gönderilemeyecek kadar büyük.',
      one: '$names buradan gönderilemeyecek kadar büyük.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Ekip arkadaşı';

  @override
  String get systemSender => 'Sistem';

  @override
  String get agent => 'Ajan';

  @override
  String get attachFile => 'Dosya ekle';

  @override
  String get messageHint => 'Mesaj';

  @override
  String removeAttachment(String name) {
    return '$name öğesini kaldır';
  }

  @override
  String get articlesLoadFailed => 'Makaleler yüklenemedi';

  @override
  String get noArticles => 'Makale yok';

  @override
  String get articlesEmptyDescription =>
      'Akışlar güncellendikçe yeni makaleler burada görünür.';

  @override
  String get unread => 'Okunmamış';

  @override
  String get allFeeds => 'Tüm akışlar';

  @override
  String get save => 'Kaydet';

  @override
  String get unsave => 'Kaydı kaldır';

  @override
  String get readFullArticle => 'Makalenin tamamını oku';

  @override
  String get ticketsLoadFailed => 'Ticket’lar yüklenemedi';

  @override
  String get noTickets => 'Ticket yok';

  @override
  String get ticketsEmptyDescription =>
      'Bu çalışma alanındaki ticket’lar burada görünür.';

  @override
  String get all => 'Tümü';

  @override
  String get ticket => 'Ticket';

  @override
  String get ticketLoadFailed => 'Ticket yüklenemedi';

  @override
  String assignedTo(String name) {
    return '$name kişisine atandı';
  }

  @override
  String get openInBrowser => 'Tarayıcıda aç';

  @override
  String get status => 'Durum';

  @override
  String get assign => 'Ata';

  @override
  String get reassign => 'Yeniden ata';

  @override
  String get noAgents => 'Ajan yok';

  @override
  String get noAgentsDescription => 'Bu çalışma alanından bir ajan ata.';

  @override
  String get statusOpen => 'Açık';

  @override
  String get statusInProgress => 'Devam ediyor';

  @override
  String get statusBlocked => 'Engellendi';

  @override
  String get statusInReview => 'İncelemede';

  @override
  String get statusDone => 'Tamamlandı';

  @override
  String get statusBacklog => 'Backlog';

  @override
  String get lensNeedsMe => 'Benden beklenen';

  @override
  String get lensMine => 'Benimkiler';

  @override
  String get prsLoadFailed => 'Çekme istekleri yüklenemedi';

  @override
  String get noOpenPullRequests => 'Açık pull request yok';

  @override
  String get nothingWaitingOnReview => 'İncelemeni bekleyen bir şey yok';

  @override
  String get noOwnOpenPullRequests => 'Açık çekme isteğin yok';

  @override
  String get nothingBlocked => 'Engellenen bir şey yok';

  @override
  String get prsEmptyDescription =>
      'Bu çalışma alanındaki depoların çekme istekleri burada görünür.';

  @override
  String get refreshPullRequests => 'Çekme isteklerini yenile';

  @override
  String get noForgeConnected =>
      'Sunucuda bağlı bir forge yok, bu yüzden çekme isteği alınamıyor. Masaüstü uygulamasından birini bağla.';

  @override
  String get draft => 'Taslak';

  @override
  String get merged => 'Birleştirildi';

  @override
  String get closed => 'Kapalı';

  @override
  String get open => 'Açık';

  @override
  String get approved => 'Onaylandı';

  @override
  String get changesRequested => 'Değişiklik istendi';

  @override
  String get reviewRequired => 'İnceleme gerekli';

  @override
  String get checksPassing => 'Kontroller geçiyor';

  @override
  String get checksFailing => 'Kontroller başarısız';

  @override
  String get checksRunning => 'Kontroller çalışıyor';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Çekme isteği';

  @override
  String get prLoadFailed => 'Bu çekme isteği yüklenemedi';

  @override
  String get openOnForge => 'Forge’da aç';

  @override
  String get requestChangesNeedsComment =>
      'Nelerin değişmesi gerektiğini açıklayan bir yorum ekle.';

  @override
  String get conversation => 'Konuşma';

  @override
  String get files => 'Dosyalar';

  @override
  String get checks => 'Kontroller';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya',
      one: '1 dosya',
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
  String get conflicts => 'Çakışmalar';

  @override
  String get reviewers => 'İnceleyenler';

  @override
  String get noDescriptionNoComments => 'Henüz açıklama ve yorum yok.';

  @override
  String get noChangedFiles => 'Değişen dosya yok.';

  @override
  String get noChecksReported => 'Head commit için raporlanan kontrol yok.';

  @override
  String get reviewCommentHint => 'İnceleme yorumu yaz…';

  @override
  String get comment => 'Yorum';

  @override
  String get commentPosted => 'Yorum gönderildi';

  @override
  String get request => 'Talep et';

  @override
  String get squashAndMerge => 'Sıkıştır ve birleştir';

  @override
  String noActionsAvailable(String status) {
    return '$status — yapılabilecek işlem yok.';
  }

  @override
  String get reviewApproved => 'onayladı';

  @override
  String get reviewRequestedChanges => 'değişiklik istedi';

  @override
  String get reviewCommented => 'inceledi';

  @override
  String get reviewPending => 'beklemede';

  @override
  String get unknownAuthor => 'bilinmiyor';

  @override
  String hideDiffFor(String file) {
    return '$file için farkı gizle';
  }

  @override
  String showDiffFor(String file) {
    return '$file için farkı göster';
  }

  @override
  String get checkRunning => 'çalışıyor';

  @override
  String get checkPassed => 'başarılı';

  @override
  String get checkFailed => 'başarısız';

  @override
  String get checkCancelled => 'iptal edildi';

  @override
  String get checkSkipped => 'atlandı';

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
      'Bu dosya için metin farkı yok — ikili dosya veya forge’un döndüremeyeceği kadar büyük.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kalan $count satırı göster',
      one: 'Kalan satırı göster',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count değişmeyen satır',
      one: '1 değişmeyen satır',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'En sona git';

  @override
  String get streaming => 'Yayınlanıyor';

  @override
  String get working => 'Çalışıyor';

  @override
  String get input => 'Girdi';

  @override
  String get output => 'Çıktı';

  @override
  String get now => 'şimdi';

  @override
  String agoMinutes(int count) {
    return '${count}dk';
  }

  @override
  String agoHours(int count) {
    return '${count}sa';
  }

  @override
  String agoDays(int count) {
    return '${count}g';
  }

  @override
  String get today => 'Bugün';

  @override
  String get tomorrow => 'Yarın';

  @override
  String get yesterday => 'Dün';

  @override
  String durationMinutes(int count) {
    return '${count}dk';
  }

  @override
  String durationHours(int count) {
    return '${count}sa';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}sa ${minutes}dk';
  }

  @override
  String get mobileConversations => 'Sohbetler';

  @override
  String get mobileNewConversation => 'Yeni sohbet';

  @override
  String get mobileConversationName => 'Konuşma adı';

  @override
  String get mobileRename => 'Yeniden adlandır';

  @override
  String get mobileManageSpace => 'Alanı yönet';

  @override
  String get mobileArchived => 'Arşivlendi';

  @override
  String get mobileSearchMessages => 'Bu alandaki tüm mesajlarda ara';

  @override
  String get mobileSearch => 'Ara';

  @override
  String get mobileNoResults => 'Sonuç yok';

  @override
  String get mobileReopen => 'Yeniden aç';

  @override
  String get mobileArchive => 'Arşivle';

  @override
  String get mobileProgress => 'İlerleme ve bağlam';

  @override
  String get mobileReadFailed => 'Bu sohbet okundu olarak işaretlenemedi';

  @override
  String get mobileSendFailed => 'Mesaj gönderilemedi. Taslağınız hâlâ burada.';

  @override
  String get sentAttachmentUnavailable => 'Ek kullanılamıyor';

  @override
  String get sentAttachmentLoadFailed => 'Ek yüklenemedi';

  @override
  String get mobileActionFailed => 'İşlem başarısız';

  @override
  String get mobileRemove => 'Kaldır';

  @override
  String get mobileLinkedMessage => 'Bağlı mesaj';

  @override
  String get mobileOlderMessages => 'Eski mesajlar';

  @override
  String get mobileMessageActions => 'Mesaj işlemleri';

  @override
  String get mobileOpenThread => 'Konuyu aç';

  @override
  String get mobileCopyLink => 'Bağlantıyı kopyala';

  @override
  String get mobileStopRun => 'Çalışmayı durdur';

  @override
  String get mobileStopRunConfirm =>
      'Bu ajan çalışması durdurulsun mu? Tamamlanan işler korunacak.';

  @override
  String get mobileControlUnsupported =>
      'Bu çalışma sona erdi veya bu denetimi desteklemiyor.';

  @override
  String get mobilePauseRequested => 'Sonraki tur sınırında duraklatma istendi';

  @override
  String get mobileResumed => 'Çalışma sürdürüldü';

  @override
  String get mobileStopRequested => 'Durdurma istendi';

  @override
  String get mobileQueuedMessages => 'Kuyruktaki mesajlar';

  @override
  String get mobilePauseRun => 'Sonraki turda duraklat';

  @override
  String get mobileResumeRun => 'Sürdür';

  @override
  String get mobileEditQueued => 'Kuyruktaki mesajı düzenle';

  @override
  String get mobileSteerNow => 'Şimdi yönlendir';

  @override
  String get mobileMoveUp => 'Yukarı taşı';

  @override
  String get mobileMoveDown => 'Aşağı taşı';

  @override
  String get mobileQueueChanged =>
      'Kuyruk değişti veya bu çalışma anlık yönlendirmeyi kabul etmiyor. Yenileyip tekrar deneyin.';

  @override
  String get mobileActivity => 'Etkinlik';

  @override
  String get mobilePermissions => 'İzinler ve denetim';

  @override
  String get mobilePlans => 'Planlar';

  @override
  String get mobileGoals => 'Gözetimli hedefler';

  @override
  String get mobileCredentials => 'Bağlantılar ve kimlik bilgileri';

  @override
  String get mobileWorkspaceUnavailable =>
      'Bu çalışma alanına erişilemiyor veya artık erişim izniniz yok.';

  @override
  String get mobilePrReviewThreads => 'İnceleme dizileri';

  @override
  String get mobilePrThreadsLoadFailed => 'İnceleme konuları yüklenemedi';

  @override
  String get mobilePrNoReviewThreads => 'Henüz satır içi inceleme konusu yok';

  @override
  String get mobilePrCommentPermissionDenied =>
      'Bu depoya yorum yapma izniniz yok.';

  @override
  String get mobilePrPermissionChecking => 'Yorum izinleri denetleniyor…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'Yorum izinleri denetlenemedi. Yorum yapmak için yeniden deneyin.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side tarafı, $line. satır';
  }

  @override
  String get mobilePrOriginalSide => 'Orijinal';

  @override
  String get mobilePrSelectCommentLine => 'Yorum yapmak için bir satır seçin';

  @override
  String get mobilePrUpdatedSide => 'Güncellendi';

  @override
  String get mobilePrThreadResolved => 'Çözüldü';

  @override
  String get mobilePrReplyHint => 'Yanıt yazın…';

  @override
  String get mobilePrCommentRequired => 'Göndermeden önce bir yorum yazın.';

  @override
  String get mobilePrReply => 'Yanıtla';

  @override
  String get mobilePrReopenThread => 'Konuyu yeniden aç';

  @override
  String get mobilePrResolveThread => 'Konuyu çöz';

  @override
  String get mobilePrResolvePermissionDenied =>
      'Bu konuyu yalnızca pull request yazarı veya yazma izni olan biri çözebilir.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return '$side tarafının $line. satırına yorum yap';
  }

  @override
  String get mobilePrInlineCommentHint => 'Satır içi yorum yazın…';

  @override
  String get mobilePrPostInlineComment => 'Yorumu gönder';

  @override
  String get mobilePrCommentUnavailable =>
      'Bu pull request için satır içi yorumlar kullanılamıyor.';

  @override
  String get mobilePrPatchUnavailable =>
      'Forge bu dosya için metin yaması sağlamadı.';

  @override
  String get mobilePrNoPatchForFile => 'Bu dosyanın yaması kullanılamıyor.';

  @override
  String get mobileTicketNew => 'Yeni bilet';

  @override
  String get mobileTicketCreate => 'Bilet oluştur';

  @override
  String get mobileTicketEdit => 'Bileti düzenle';

  @override
  String get mobileTicketTitle => 'Başlık';

  @override
  String get mobileTicketTitleRequired =>
      'Bu bileti kaydetmek için bir başlık girin.';

  @override
  String get mobileTicketDescription => 'Açıklama';

  @override
  String get mobileTicketMarkdownHint => 'Markdown ile ayrıntı ekleyin';

  @override
  String get mobileTicketPriority => 'Öncelik';

  @override
  String get mobileTicketPriorityNone => 'Öncelik yok';

  @override
  String get mobileTicketPriorityUrgent => 'Acil';

  @override
  String get mobileTicketPriorityHigh => 'Yüksek';

  @override
  String get mobileTicketPriorityMedium => 'Orta';

  @override
  String get mobileTicketPriorityLow => 'Düşük';

  @override
  String get mobileTicketLabels => 'Etiketler';

  @override
  String get mobileTicketLabelsHint => 'Her satıra bir etiket';

  @override
  String get mobileTicketLabelsHelp => 'Her etiketi ayrı bir satıra girin.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return '$provider üzerinde açıldı';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'Atanmamış';

  @override
  String get mobileTicketAssignedFilter => 'Atananlar';

  @override
  String get mobileTicketAgentsLoadFailed => 'Ajanlar yüklenemedi';

  @override
  String get mobileTicketSearch => 'Biletlerde ara';

  @override
  String get mobileTicketSearchHint =>
      'Başlık, anahtar, açıklama, etiket veya atanan kişi';

  @override
  String get mobileTicketClearSearch => 'Bilet aramasını temizle';

  @override
  String get mobileTicketNoMatches => 'Eşleşen bilet yok';

  @override
  String get mobileTicketAdjustFilters =>
      'Başka bir arama deneyin veya filtreleri değiştirin.';

  @override
  String get mobileTicketClearFilters => 'Filtreleri temizle';

  @override
  String get mobileTicketNotFound => 'Bilet bulunamadı';

  @override
  String get mobileTicketNotFoundDescription =>
      'Bu bilet silinmiş veya bu çalışma alanının dışına taşınmış olabilir.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'Çalışma alanı değişti. Kaydetmeden önce geçerli çalışma alanına dönün.';

  @override
  String get mobileTicketOpenLinkedSpace => 'Bağlı alanı aç';

  @override
  String get mobileTicketReadOnly =>
      'Biletleri değiştirmek için çalışma alanı üyesi olmalısınız.';

  @override
  String get permissionTitle => 'İzinler';

  @override
  String get permissionWorkspaceFailed => 'Çalışma alanı yüklenemedi';

  @override
  String get permissionNoWorkspace =>
      'İzinleri incelemek için bir çalışma alanı seçin.';

  @override
  String get permissionLoading => 'İzinler yükleniyor…';

  @override
  String get permissionScopeDescription =>
      'Bu kapsamda her işleme nasıl karar verildiğini inceleyin. Çalışma alanı kuralları ajanlara ve alanlara aktarılabilir.';

  @override
  String get permissionScope => 'İlke kapsamı';

  @override
  String get permissionWorkspaceScope => 'Çalışma alanı';

  @override
  String get permissionAgentScope => 'Ajan';

  @override
  String get permissionSpaceScope => 'Space';

  @override
  String get permissionAgentContext => 'Bu alanda işlem yapan ajan';

  @override
  String get permissionNoAgentContext => 'Ajan seçilmedi';

  @override
  String get permissionTargetsFailed => 'Kapsam hedefleri yüklenemedi';

  @override
  String get permissionNoTargets => 'Bu kapsamda kullanılabilir hedef yok.';

  @override
  String get permissionRoleFailed => 'Çalışma alanı rolünüz doğrulanamadı';

  @override
  String get permissionMemberRequired =>
      'İlke kurallarını görüntülemek için çalışma alanı üyesi olmalısınız.';

  @override
  String get permissionRulesFailed => 'İlke kuralları yüklenemedi';

  @override
  String get permissionAuditAdminOnly =>
      'Yetkilendirme geçmişini yalnızca çalışma alanı yöneticileri görebilir.';

  @override
  String get permissionAllow => 'İzin ver';

  @override
  String get permissionAsk => 'Önce sor';

  @override
  String get permissionDeny => 'Reddet';

  @override
  String get permissionFileDelete => 'Dosyaları sil';

  @override
  String get permissionFileWriteOutsideWorktree =>
      'Çalışma ağacının dışına yaz';

  @override
  String get permissionGitCommit => 'Değişiklikleri commit et';

  @override
  String get permissionGitPush => 'Commit\'leri push et';

  @override
  String get permissionPrCreate => 'Pull request oluştur';

  @override
  String get permissionPrPublish =>
      'Pull request\'leri güncelle veya birleştir';

  @override
  String get permissionVendorSyncWrite => 'Sağlayıcı eşitlemesine yaz';

  @override
  String get permissionNetworkEgress => 'Ağa eriş';

  @override
  String get permissionSecretAccess => 'Gizli bilgilere eriş';

  @override
  String get permissionPackageInstall => 'Paketleri yükle';

  @override
  String get permissionProcessSpawn => 'İşlemleri başlat';

  @override
  String get permissionWorkspaceMutation => 'Çalışma alanını değiştir';

  @override
  String get permissionEnclosureControl => 'Kapsayıcıyı denetle';

  @override
  String get permissionChangeFailed => 'Kural değiştirilemedi';

  @override
  String get permissionEffectiveDescription =>
      'İşlem argümanları olmadan bu kapsamda geçerlidir. Aşağıdaki koşullu izinler yalnızca eşleşen isteklere uygulanır; son kararı sunucu verir.';

  @override
  String get permissionSpaceAgentNote =>
      'Ajan seçilmedi. Yukarıdan birini seçene kadar ajana özgü kurallar gösterilmez.';

  @override
  String get permissionScopedGrants => 'Bu kapsamdaki kurallar';

  @override
  String get permissionModePreset => 'Mod ön ayarı';

  @override
  String get permissionBuiltInDefault => 'Yerleşik varsayılan';

  @override
  String get permissionRemembered => 'Süreli onay';

  @override
  String get permissionSource => 'Kaynak';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · burada ayarlandı';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · devralındı';
  }

  @override
  String permissionExpiresAt(String date) {
    return '$date tarihinde sona erer';
  }

  @override
  String get permissionSetHere => 'Burada kural belirle';

  @override
  String get permissionConfirmRevoke => 'İptali onayla';

  @override
  String get permissionRevokeRule => 'Kuralı iptal et';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'Komut öneki: $prefix';
  }

  @override
  String get permissionNoExpiry => 'Bitiş tarihi yok';

  @override
  String get permissionExpired => 'Süresi doldu';

  @override
  String get permissionExplicitRule => 'Açık kural';

  @override
  String get permissionEnforcementAdvisory =>
      'Tavsiye niteliğinde: önce sor kuralları soru sorulmadan kaydedilir';

  @override
  String get permissionEnforcementSoft =>
      'Esnek uygulama: geçersiz kılmak için yetkilendirme gerekir';

  @override
  String get permissionEnforcementHard => 'Katı uygulama: geçersiz kılınamaz';

  @override
  String permissionPaths(String paths) {
    return 'Yollar: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Git referansları: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'Ana makineler: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'Komutlar: $commands';
  }

  @override
  String permissionTools(String tools) {
    return 'Araçlar: $tools';
  }

  @override
  String get permissionNotInEffect =>
      'Bu eylem reddedildiği sürece geçerli değil';

  @override
  String permissionMaxCount(String count) {
    return 'En fazla: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'En fazla sent: $cents';
  }

  @override
  String get permissionAuditHeading => 'Yetkilendirme geçmişi';

  @override
  String get permissionAuditDescription =>
      'Sunucunun kaydettiği son kararlar. Günlüğü yalnızca yöneticiler inceleyebilir veya karma zincirini doğrulayabilir.';

  @override
  String permissionOnBehalfOf(String user) {
    return '$user adına';
  }

  @override
  String get permissionPrompted => 'İnsan onayı istendi';

  @override
  String get permissionVerifyChain => 'Denetim zincirini doğrula';

  @override
  String get permissionVerifyFailed => 'Denetim zinciri doğrulanamadı';

  @override
  String permissionChainIntact(String count) {
    return 'Zincir sağlam · $count kayıt denetlendi';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'Zincir $sequence. kayıtta bozuldu: $reason';
  }

  @override
  String get permissionAuditEmpty => 'Henüz yetkilendirme kararı kaydedilmedi.';

  @override
  String get permissionAuditFailed => 'Yetkilendirme geçmişi yüklenemedi';

  @override
  String get mobilePlansLoadFailed => 'Planlar yüklenemedi';

  @override
  String get mobilePlansEmpty => 'Henüz plan yok';

  @override
  String get mobilePlansEmptyDescription =>
      'Ajanların sunduğu planlar incelenmek üzere burada görünecek.';

  @override
  String get mobilePlanTitle => 'Plan';

  @override
  String get mobilePlanMissing =>
      'Bu plan artık bu çalışma alanında kullanılamıyor.';

  @override
  String mobilePlanStepCount(int count) {
    return '$count adım';
  }

  @override
  String get mobilePlanDraft => 'Taslak';

  @override
  String get mobilePlanProposed => 'İnceleme bekliyor';

  @override
  String get mobilePlanApproved => 'Onaylandı';

  @override
  String get mobilePlanRejected => 'Reddedildi';

  @override
  String get mobilePlanSuperseded => 'Geçersiz kılındı';

  @override
  String get mobilePlanExecuting => 'Yürütülüyor';

  @override
  String get mobilePlanSynthesizing => 'Sentezleniyor';

  @override
  String get mobilePlanCompleted => 'Tamamlandı';

  @override
  String get mobilePlanFailed => 'Başarısız';

  @override
  String get mobilePlanCancelled => 'İptal edildi';

  @override
  String mobilePlanRevision(String revision) {
    return 'Revizyon $revision';
  }

  @override
  String get mobilePlanSteps => 'Adımlar';

  @override
  String get mobilePlanNoSteps => 'Bu plan için adım sunulmadı.';

  @override
  String get mobilePlanAssumptions => 'Açıklığa kavuşturulacak konular';

  @override
  String mobilePlanDependsOn(String keys) {
    return '$keys öğesine bağlı';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'En fazla $cost olarak tahmin ediliyor';
  }

  @override
  String get mobilePlanSelect => 'Seç';

  @override
  String get mobilePlanSelected => 'Seçildi';

  @override
  String get mobilePlanEstimate => 'Maliyeti tahmin et';

  @override
  String get mobilePlanEstimateRequired =>
      'Yürütmeyi onaylamadan önce planın maliyetini tahmin edin.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'Tahmini maliyet: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'kullanılamıyor';

  @override
  String get mobilePlanNoHardCap => 'kesin üst sınır yok';

  @override
  String get mobilePlanExceedsBudget =>
      'Tahmin, belirlenen bütçeyi aşıyor. Onaylamadan önce inceleyin.';

  @override
  String get mobilePlanPartialEstimate =>
      'Bu tahmin planın tamamını kapsar; seçilen adımlar daha az maliyetli olabilir.';

  @override
  String get mobilePlanConfirmAll => 'Planın tamamı başlatılsın mı?';

  @override
  String get mobilePlanConfirmSelected => 'Seçilen adımlar başlatılsın mı?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'Onay, yürütmeyi başlatır ve ücrete yol açabilir. Tahmini en yüksek maliyet: $cost. Bütçe sınırı: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'Tümünü onayla ve çalıştır';

  @override
  String get mobilePlanApproveSelected => 'Seçilenleri onayla ve çalıştır';

  @override
  String get mobilePlanWiden => 'Ek adımları onayla';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return '$count adım daha yürütmeye açılsın mı? Ücrete yol açabilirler. Mevcut yürütme maliyeti sınırı: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'İnceleme sırasında plan değişti. Son revizyonu açıp maliyetini yeniden tahmin edin.';

  @override
  String get mobilePlanReject => 'Planı reddet';

  @override
  String get mobilePlanRejectConfirm =>
      'Bu plan reddedilsin mi? Yürütülmeyecek.';

  @override
  String get mobilePlanStop => 'Yürütmeyi durdur';

  @override
  String get mobilePlanStopConfirm =>
      'Bu planın yürütmesi durdurulsun mu? Tamamlanan işler geri alınmaz.';

  @override
  String mobilePlanRunId(String runId) {
    return 'Yürütme çalışması: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'Onay kabul edildi. Yürütme kaydı bekleniyor…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return '$total yürütme adımının $completed tanesi tamamlandı';
  }

  @override
  String get mobilePlanOpenConversation => 'Sohbeti aç';

  @override
  String get mobileGoalsTitle => 'Gözetimli hedefler';

  @override
  String get mobileGoalsLoadFailed => 'Gözetimli hedefler yüklenemedi';

  @override
  String get mobileGoalsEmpty => 'Henüz gözetimli hedef yok';

  @override
  String get mobileGoalsEmptyDescription =>
      'Bir alanda hedef başlatın veya sohbette /goal gönderin.';

  @override
  String get mobileGoalMissing =>
      'Bu hedef artık bu çalışma alanında kullanılamıyor.';

  @override
  String get mobileGoalActive => 'Etkin';

  @override
  String get mobileGoalPaused => 'Duraklatıldı';

  @override
  String get mobileGoalCompleted => 'Tamamlandı';

  @override
  String get mobileGoalFailed => 'Başarısız';

  @override
  String get mobileGoalCancelled => 'İptal edildi';

  @override
  String get mobileGoalBudgetExhausted => 'Bütçe sınırına ulaşıldı';

  @override
  String mobileGoalFailures(String count) {
    return 'Art arda başarısız çalışmalar: $count';
  }

  @override
  String get mobileGoalFailedDescription =>
      'Gözetmen, tekrarlanan başarısız çalışmalardan sonra durdu. Ayrıntılar için sohbeti inceleyin.';

  @override
  String get mobileGoalPause => 'Hedefi duraklat';

  @override
  String get mobileGoalResume => 'Hedefe devam et';

  @override
  String get mobileGoalStop => 'Hedefi iptal et';

  @override
  String get mobileGoalStopConfirm =>
      'Bu gözetimli hedef kalıcı olarak iptal edilsin mi? Yeniden sürdürülemez.';

  @override
  String get mobileGoalRaiseBudget => 'Bütçeyi artır ve sürdür';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'Bütçeyi $amount tutarına çıkar ve sürdür';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'Bu hedefin maliyet sınırı $oldCap tutarından $newCap tutarına yükseltilip harcamaya devam edilsin mi?';
  }

  @override
  String get mobileGoalOpenConversation => 'Hedef sohbetini aç';

  @override
  String get mobileGoalCreate => 'Gözetimli hedef başlat';

  @override
  String get mobileGoalChooseSpace => 'Şu alanda çalıştır';

  @override
  String get mobileGoalNoSpaces => 'Hedef başlatmadan önce bir alan oluşturun.';

  @override
  String get mobileGoalChooseAgent => 'Şu ajanla çalıştır';

  @override
  String get mobileGoalNoAgents =>
      'Hedef başlatmadan önce etkin bir ajan ekleyin.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return '$name seçildi';
  }

  @override
  String get mobileGoalObjectiveHint => 'Ajan hangi sonuca ulaşmalı?';

  @override
  String get mobileGoalBudgetUsd => 'Maliyet sınırı (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'Bir alan ve ajan seçin, bir hedef girin ve USD cinsinden pozitif bir maliyet sınırı belirleyin.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'En fazla $cap maliyetle gözetimli hedef başlatılsın mı? Ajan hemen başlayabilir.';
  }

  @override
  String get mobileGoalUnavailable =>
      'Sunucu bağlantısı hazır değil. Yeniden bağlandıktan sonra tekrar deneyin.';

  @override
  String get mobileGoalConversationMissing =>
      'Seçilen sohbet artık bu çalışma alanında kullanılamıyor.';

  @override
  String get mobileGoalCreateSent =>
      'Hedef başlatıldı. Gözetmen durumu bu listede görünecek.';

  @override
  String get mobileGoalStartRefused =>
      'Hedef çalışması başlatılmadı. Gözetmenin gerekçesi için sohbeti inceleyin.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return '$name seçildi';
  }

  @override
  String get requestUnavailable =>
      'Bu istek etkin çalışma alanında artık kullanılamıyor.';

  @override
  String get requestAlreadyResolved => 'Bu istek zaten çözüldü.';

  @override
  String get inboxCredentialsBlocked =>
      'Çalışmaları engelleyen kimlik bilgileri';

  @override
  String get inboxSyncFailures => 'Başarısız sağlayıcı eşitlemeleri';

  @override
  String get inboxConfigureCredentials => 'Kimlik bilgilerini yapılandır';

  @override
  String get openTicket => 'Bileti aç';

  @override
  String get activityTitle => 'Etkinlik';

  @override
  String get activityClearAll => 'Etkinliği temizle';

  @override
  String get activityClearConfirm =>
      'Bu işlem, şimdiye kadar kaydedilen tüm etkinliğinizi bütün cihazlarda gizler. Yeni etkinlikler görünmeye devam eder.';

  @override
  String get activityMarkAllRead => 'Tümünü okundu olarak işaretle';

  @override
  String get activityMarkAllConfirm =>
      'Bu çalışma alanındaki tüm etkinlikler bütün cihazlarınızda okundu olarak işaretlensin mi?';

  @override
  String get activityMarkRead => 'Okundu olarak işaretle';

  @override
  String get activityMarkUnread => 'Okunmadı olarak işaretle';

  @override
  String get activityDismiss => 'Kapat';

  @override
  String get activityResolved => 'Çözüldü';

  @override
  String get activityOpen => 'Açık';

  @override
  String get activityEmpty => 'Henüz etkinlik yok';

  @override
  String get activityLoadFailed => 'Etkinlik yüklenemedi';

  @override
  String get activityAgentWaiting => 'Ajanın girdiye ihtiyacı var';

  @override
  String get activityAgentBlocked => 'Ajan işlemi engellendi';

  @override
  String get activityMessage => 'Yeni mesaj';

  @override
  String get activityPullRequest => 'Pull request güncellemesi';

  @override
  String get activityRig => 'Kapsayıcı güncellemesi';

  @override
  String get activityEvent => 'Güncelle';

  @override
  String get activityPrReady => 'Pull request birleştirmeye hazır';

  @override
  String get activityPrBlocked => 'Pull request birleştirme engellendi';

  @override
  String get activityPrApproved => 'Pull request onaylandı';

  @override
  String get activityPrChanges => 'Değişiklik istendi';

  @override
  String get activityPrChecksFailed =>
      'Pull request denetimleri başarısız oldu';

  @override
  String get activityPrChecksRecovered =>
      'Pull request denetimleri yeniden başarılı';

  @override
  String get activityPrComment => 'Pull request yorumu';

  @override
  String get activityPrPublished => 'Pull request yayımlandı';

  @override
  String get activityPrMerged => 'Pull request birleştirildi';

  @override
  String get activityPrMentioned => 'Bir pull request\'te sizden bahsedildi';

  @override
  String get activityPrReviewRequested => 'İnceleme istendi';

  @override
  String get activityPrReviewStale => 'İncelemenin yenilenmesi gerekiyor';

  @override
  String get activityTicketAssigned => 'Bilet atandı';

  @override
  String get activityTicketChanged => 'Bilet durumu değişti';

  @override
  String get activityMeetingSoon => 'Toplantı yakında başlıyor';

  @override
  String get activityCalendarExpired => 'Takvim bağlantısının süresi doldu';

  @override
  String get activityRigControl => 'Kapsayıcı denetimi değişti';

  @override
  String get activityRigClosed => 'Kapsayıcı durduruldu';

  @override
  String get mobileSpacesSearch => 'Alanlarda ara';

  @override
  String get mobileSpacesArchived => 'Arşivlendi';

  @override
  String get mobileSpacesActive => 'Etkin';

  @override
  String get mobileSpacesNew => 'Yeni alan';

  @override
  String get mobileSpacesManage => 'Alanı yönet';

  @override
  String get mobileSpacesName => 'Alan adı';

  @override
  String get mobileSpacesAgents => 'Ajanlar';

  @override
  String get mobileSpacesMembers => 'Kişiler';

  @override
  String get mobileSpacesRepos => 'Depolar';

  @override
  String get mobileSpacesAllRepos => 'Bağlı tüm depolar';

  @override
  String get mobileSpacesNoRepos => 'Depo yok';

  @override
  String get mobileSpacesBaseBranch => 'Temel dal (isteğe bağlı)';

  @override
  String get mobileSpacesDefaultBranch => 'Varsayılan dal';

  @override
  String get mobileSpacesMode => 'Mod';

  @override
  String get mobileSpacesModeChat => 'Sohbet';

  @override
  String get mobileSpacesModeReview => 'İnceleme (salt okunur)';

  @override
  String get mobileSpacesModePlan => 'Plan (salt okunur)';

  @override
  String get mobileSpacesModeOrchestrate => 'Orkestre et';

  @override
  String get mobileSpacesAutonomy => 'Özerklik geçersiz kılması';

  @override
  String get mobileSpacesAutonomyInherited => 'Devralınan';

  @override
  String get mobileSpacesAutonomyPropose => 'Yalnızca öner';

  @override
  String get mobileSpacesAutonomyApproval => 'Onayla hareket et';

  @override
  String get mobileSpacesAutonomyFreely => 'Serbest hareket et';

  @override
  String get mobileSpacesAutonomyNotice =>
      'Geçersiz kılma, işlem ilkesi onay isteklerini veya retlerini aşamaz. Bunu yalnızca çalışma alanı yöneticileri değiştirebilir.';

  @override
  String get mobileSpacesArchive => 'Çalışma alanını arşivle';

  @override
  String get mobileSpacesReopen => 'Alanı yeniden aç';

  @override
  String get mobileSpacesSave => 'Değişiklikleri kaydet';

  @override
  String get mobileSpacesCreate => 'Alan oluştur';

  @override
  String get mobileSpacesOperationFailed => 'Alan güncellenemedi';

  @override
  String get mobileSpacesMissing => 'Bu çalışma alanında alan bulunamadı';

  @override
  String get mobileSpacesEmptyName => 'Bir alan adı girin';

  @override
  String get mobileSpacesNoMatches => 'Eşleşen alan yok';

  @override
  String get mobileSpacesUnread => 'Okunmamış ajan yanıtı';

  @override
  String get mobileSpacesNeedsInput => 'Girdiniz gerekiyor';

  @override
  String get mobileSpacesRunning => 'Ajan çalışıyor';

  @override
  String get mobileSpacesNoAgents => 'Bu çalışma alanında ajan yok';

  @override
  String get mobileSpacesNoMembers => 'Başka çalışma alanı üyesi yok';

  @override
  String get mobileSpacesRepoError => 'Depolar yüklenemedi';

  @override
  String get mobileSpacesRetry => 'Yeniden dene';

  @override
  String get mobileSpacesBranchUnavailable =>
      'Alan oluştururken bir temel dal seçin veya yazın; mevcut alanların temel dalları değiştirilemez.';

  @override
  String get mobileSpacesArchivedEmpty => 'Arşivlenmiş çalışma alanı yok';

  @override
  String get mobileSpacesAllRepoWarning =>
      'Yeni bağlanan çalışma alanı depoları da bu alana eklenecek.';

  @override
  String get mobileSpacesCreatedRetry =>
      'Alan oluşturuldu. Kişi eklemeyi yeniden deneyin veya yönetim sayfasını açın.';

  @override
  String get progressTitle => 'İlerleme';

  @override
  String get progressConversation => 'Sohbet';

  @override
  String get progressLoadFailed => 'İlerleme yüklenemedi';

  @override
  String get progressUnavailable => 'Sohbet kullanılamıyor';

  @override
  String get progressUnavailableDescription =>
      'Bu sohbet etkin çalışma alanında ve alanda bulunmuyor. Devam etmek için ait olduğu alana dönün.';

  @override
  String get progressSaveFailed => 'İlerleme güncellenemedi';

  @override
  String get progressGoal => 'Hedef';

  @override
  String get progressNoGoal => 'Çalışma hedefi belirlenmedi';

  @override
  String get progressSetGoal => 'Hedefi belirle';

  @override
  String get progressEditGoal => 'Hedefi düzenle';

  @override
  String get progressClearGoal => 'Hedefi temizle';

  @override
  String get progressGoalRequired => 'Kaydetmeden önce bir hedef girin.';

  @override
  String get progressTodos => 'Görevler';

  @override
  String get transcriptToolTodos => 'Görevler';

  @override
  String get transcriptToolSearchMemory => 'Bellekte ara';

  @override
  String get transcriptToolRenderMedia => 'Medyayı göster';

  @override
  String get progressNoTodos => 'Henüz görev yok';

  @override
  String get progressNewTodo => 'Yeni görev';

  @override
  String get progressAddTodo => 'Görev ekle';

  @override
  String get progressEditTodo => 'Görevi düzenle';

  @override
  String get progressTodoRequired => 'Kaydetmeden önce bir görev girin.';

  @override
  String get progressTodoNoLongerExists =>
      'Bu görev kaldırıldı. Listeyi yeniden yükleyip tekrar deneyin.';

  @override
  String get progressWorkspaceChanged =>
      'Etkin çalışma alanı değişti. Bu sohbete dönüp tekrar deneyin.';

  @override
  String progressRemoveTodo(String name) {
    return '$name görevini kaldır';
  }

  @override
  String get progressPending => 'Beklemede';

  @override
  String get progressInProgress => 'Devam ediyor';

  @override
  String get progressCompleted => 'Tamamlandı';

  @override
  String get progressMoveUp => 'Görevi yukarı taşı';

  @override
  String get progressMoveDown => 'Görevi aşağı taşı';

  @override
  String get progressRunTree => 'Ajan çalışmaları';

  @override
  String get progressNoRuns => 'Bu sohbette henüz çalışma yok';

  @override
  String get progressRunning => 'Çalışıyor';

  @override
  String get progressFailed => 'Başarısız';

  @override
  String get progressUnknown => 'Bilinmiyor';

  @override
  String get progressHealthy => 'Etkin';

  @override
  String get progressBlocked => 'Engellendi';

  @override
  String get progressLooping => 'Döngüde';

  @override
  String get progressStalled => 'Takıldı';

  @override
  String get progressDead => 'Beklenmedik şekilde durdu';

  @override
  String get progressQuiet => 'Henüz çıktı yok';

  @override
  String get progressCostReported => 'Sağlayıcının bildirdiği ücret';

  @override
  String get progressCostNotional =>
      'Abonelik liste fiyatı üzerinden varsayımsal tutar; fatura değildir';

  @override
  String get progressCostMixed => 'Karma maliyet kaynakları';

  @override
  String get progressCostEstimated => 'Tahmini maliyet';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds sn';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'Model: $model · Süre: $duration · Maliyet: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return '$time başladı';
  }

  @override
  String progressLiveness(String state) {
    return 'Durum: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'Girdi: $input · Çıktı: $output token';
  }

  @override
  String get progressOutputPreviewLimited =>
      'Yapılandırılmış çıktının yalnızca ilk 6.000 karakteri gösterilir.';

  @override
  String progressRetryOf(String runId) {
    return '$runId çalışmasının yeniden denemesi';
  }

  @override
  String get progressContext => 'Bağlam ve sınırlar';

  @override
  String get progressNoAgent => 'İncelenecek ajan yok';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window token';
  }

  @override
  String get progressMeasured => 'Son çağrıda sağlayıcının bildirdiği bağlam';

  @override
  String get progressEstimated =>
      'Kaydedilen sohbetten ve kalıcı bağlamdan tahmin edildi';

  @override
  String get progressContextUnknown => 'Bağlam kullanımı henüz bildirilmedi';

  @override
  String progressContextPercent(String percent) {
    return 'Bağlam penceresinin %$percent kadarı';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'Yapılandırılmış aylık ajan sınırı: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'Kaydedilen etkin sohbet: tahmini $tokens token';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return '$agent için kalıcı bağlam · $model';
  }

  @override
  String get progressContextSystem => 'Sistem promptu';

  @override
  String get progressContextRules => 'Kurallar';

  @override
  String get progressContextSkills => 'Beceriler';

  @override
  String get progressContextTools => 'Araç tanımları';

  @override
  String get progressContextMcp => 'MCP araçları';

  @override
  String get progressContextDeferred => 'Ertelenmiş araçlar';

  @override
  String get progressContextSubagents => 'Alt ajanlar';

  @override
  String get progressContextRunner => 'Harici çalıştırıcı';

  @override
  String get progressContextMemory => 'Bellek';

  @override
  String get progressContextHistory => 'Sohbet geçmişi';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens token';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens token';
  }

  @override
  String get progressOutputs => 'Son çıktılar';

  @override
  String get progressNoOutputs => 'Son ajan çıktısı yok';

  @override
  String get progressStructuredOutputsAbove =>
      'Yapılandırılmış çalışma çıktıları yukarıdaki ajan çalışmalarında gösterilir.';

  @override
  String get progressRecentOutputsOnly =>
      'Yalnızca son mesajlar gösteriliyor. Önceki işler için sohbeti açın.';

  @override
  String get progressPlan => 'Plan';

  @override
  String get progressArtifact => 'Artifakt';

  @override
  String get progressResult => 'Sonuç';

  @override
  String get progressHideArtifact => 'Artifaktı gizle';

  @override
  String get progressReadArtifact => 'Artifaktı oku';

  @override
  String get progressArtifactUnavailable => 'Artifakt artık kullanılamıyor';

  @override
  String get progressArtifactPreviewLimited =>
      'Bu artifaktın sınırlı bir önizlemesi gösteriliyor.';

  @override
  String get progressDiagramSource => 'Diyagram kaynağı';

  @override
  String progressOpenAttachment(String name) {
    return '$name öğesini aç';
  }

  @override
  String get progressOpenPlan => 'Planı aç';

  @override
  String progressOpenDiff(String label) {
    return 'Değişen dosyaları incele: $label';
  }

  @override
  String get progressViewMessage => 'Mesajı görüntüle';

  @override
  String get pushTitle => 'Arka plan bildirimleri';

  @override
  String get pushIntro =>
      'Uygulama kapalıyken bile ilgilenmeniz gereken bir durum olduğunda özel bildirim alın. Ayrıntılar şifreli bağlantınızda kalır.';

  @override
  String get pushLoading => 'Bildirim ayarları denetleniyor…';

  @override
  String get pushError =>
      'Bildirimler güncellenemedi. Bağlantınızı denetleyip tekrar deneyin.';

  @override
  String get pushEnable => 'Bildirimleri etkinleştir';

  @override
  String get pushDisable => 'Bildirimleri kapat';

  @override
  String get pushQuiet => 'Bu cihazda bildirimleri duraklat';

  @override
  String get pushCategories => 'Şunlar için bildirim gönder';

  @override
  String get pushCategoryAgents => 'Ajanlar';

  @override
  String get pushCategoryMessages => 'Mesajlar';

  @override
  String get pushCategoryPullRequests => 'Pull requests';

  @override
  String get pushCategoryTickets => 'Biletler';

  @override
  String get pushCategoryCalendar => 'Takvim';

  @override
  String get pushCategoryMachines => 'Makineler';

  @override
  String get pushSecureOrigin => 'Bildirimler için HTTPS gerekir.';

  @override
  String get pushInstallIos =>
      'Bildirimleri etkinleştirmek için iPhone veya iPad\'de bu uygulamayı Ana Ekran\'a ekleyip oradan açın.';

  @override
  String get pushUnsupported =>
      'Bu tarayıcı arka plan bildirimlerini desteklemiyor.';

  @override
  String get pushDenied =>
      'Tarayıcı bildirimlerin engellendiğini bildiriyor. Bu sitenin iznini ve tarayıcı veya cihaz bildirim ayarlarını kontrol edip sayfayı yenileyin.';

  @override
  String get pushOsHint =>
      'Tarayıcınızın, cihazın sistem ayarlarında da bildirim gösterme izni olması gerekir.';

  @override
  String get pushServiceUnavailable =>
      'Tarayıcının anlık bildirim hizmeti aboneliği reddetti. Brave gibi bazı tarayıcılar bu hizmeti varsayılan olarak kapatır: tarayıcının gizlilik ayarlarında anlık mesajlarla ilgili bir seçenek arayın ve yeniden deneyin.';

  @override
  String get pushWorkerUnavailable =>
      'Bildirim hizmeti bu tarayıcıda başlatılamadı. Sayfayı yeniden yükleyip tekrar deneyin.';

  @override
  String get pushResubscribe => 'Bildirimleri yeniden bağla';

  @override
  String get pushStatusEnabled => 'Bu cihazda bildirimler açık.';

  @override
  String get pushStatusDisabled => 'Bu cihazda bildirimler kapalı.';

  @override
  String get credentialsTitle => 'Bağlantılar ve kimlik bilgileri';

  @override
  String get credentialsIntro =>
      'Çalışmalarınızın ve entegrasyonlarınızın kullandığı hesapları bağlayın. Gizli bilgiler bu telefonda değil, sunucunuzda saklanır.';

  @override
  String get credentialsModelProviders => 'Model sağlayıcıları';

  @override
  String get credentialsOwnerOnly =>
      'Model sağlayıcılarının kimlik bilgilerini yalnızca sunucu sahibi ekleyebilir, bunlarla oturum açabilir veya bunları kaldırabilir. Bu anahtarlar çalışma alanları arasında paylaşılır.';

  @override
  String get credentialsContactOwner =>
      'Engellenen çalışmanız için gereken sağlayıcıyı bağlamasını sunucu sahibinden isteyin.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude Code, ana makinedeki CLI üzerinden oturum açar. Sunucu sahibinden, ana makinenin terminalinde hesap oturumunu açmasını veya yenilemesini isteyin; bu işlem telefonda yapılamaz.';

  @override
  String get credentialsYourForgeAccounts => 'Kod barındırma hesaplarınız';

  @override
  String get credentialsYourTicketingAccount => 'Bilet sistemi hesabınız';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'Yerel biletler için oturum açmak gerekmez. Çalışma alanınız Linear kullanıyorsa buradan bağlayın.';

  @override
  String get credentialsMembershipRequired =>
      'Kod barındırma veya bilet sistemi kimlik bilgilerinizi yönetmek için bir çalışma alanına katılın. Erişim için çalışma alanı yöneticisine başvurun.';

  @override
  String get credentialsSwitchWorkspace =>
      'Bu bağlantı başka bir çalışma alanına yönlendiriyor. Kimlik bilgilerini değiştirmeden önce o çalışma alanına geçin.';

  @override
  String get credentialsReturnToInbox =>
      'Kimlik bilgileri bağlandığında engellenen çalışmayı yeniden denemek için Gelen Kutusu\'na dönün. Ana makine, beklemeye alınan çalışmaları da otomatik olarak denetler.';

  @override
  String get credentialsLoadFailed =>
      'Bağlantılar yüklenemedi. Sunucu bağlantısını denetleyip yeniden deneyin.';

  @override
  String get credentialsOperationFailed =>
      'Bu bağlantı değiştirilemedi. Sunucu bağlantısını, erişiminizi ve kimlik bilgilerini denetleyip yeniden deneyin.';

  @override
  String get credentialsConnected => 'Bağlı';

  @override
  String get credentialsNotConnected => 'Bağlı değil';

  @override
  String credentialsSignedInAs(String username) {
    return '$username olarak oturum açıldı';
  }

  @override
  String get credentialsAccount => 'Bağlı hesap';

  @override
  String get credentialsStoredKey => 'Saklanan anahtar';

  @override
  String get credentialsActive => 'Etkin';

  @override
  String get credentialsRemove => 'Kaldır';

  @override
  String get credentialsRemoveConfirm =>
      'Kaydedilmiş kimlik bilgileriniz kaldırılsın mı? Yeniden oturum açmanız gerekebilir.';

  @override
  String get credentialsApiKey => 'API anahtarı';

  @override
  String get credentialsApiKeyHint => 'Sağlayıcı API anahtarını yapıştırın';

  @override
  String get credentialsBrowserLogin => 'Tarayıcıyla oturum aç';

  @override
  String get credentialsSignInAgain => 'Yeniden oturum aç';

  @override
  String get credentialsWaitingForLogin =>
      'Tarayıcıda yetkilendirme bekleniyor…';

  @override
  String get credentialsConnectCodePrompt => 'Onay kodu';

  @override
  String get credentialsConnectCodeMalformed =>
      'Bu bir oturum açma koduna benzemiyor. Kodlar 8 harf ve rakamdan oluşur.';

  @override
  String get credentialsSignInInvalidCode =>
      'Bu kod bu oturum açma işlemiyle eşleşmiyor. Kontrol edip yeniden dene.';

  @override
  String get credentialsSignInTooManyCodes =>
      'Çok fazla yanlış kod girildi. Oturum açmayı yeniden başlatın.';

  @override
  String get credentialsSignInRetryLater =>
      'Oturum açma hizmeti şu anda yanıt vermiyor. Bir dakika bekleyip yeniden deneyin.';

  @override
  String get credentialsSignInRefused =>
      'Oturum açma reddedildi. Yeniden başlatın ve istenen tüm izinleri onaylayın.';

  @override
  String get credentialsSignInNotSaved =>
      'Oturum açma başarılı oldu ancak sunucu bunu kaydedemedi. Yeniden deneyin.';

  @override
  String credentialsSignInUnavailable(String provider) {
    return '$provider oturum açma bu sunucuda henüz ayarlanmadı.';
  }

  @override
  String get credentialsSignInPhoneUnreachable =>
      'Bu sunucunun oturum açma geri dönüş adresine telefondan güvenli şekilde erişilemiyor. Masaüstü uygulamasından oturum açın veya sunucu sahibinden herkese açık bir HTTPS adresi ayarlamasını isteyin.';

  @override
  String get credentialsLoginTimedOut =>
      'Oturum açma süresi doldu. Yeni bir oturum açma işlemi başlatın.';

  @override
  String get credentialsCopyCode => 'Kodu kopyala';

  @override
  String get credentialsDeviceCodeHint =>
      'Bu kodu sağlayıcının sayfasında onaylayın. Sunucu oturum açma işlemini tamamlarken bu ekranı açık tutun.';

  @override
  String get credentialsPasteRedirect =>
      'Yetkilendirme kodu veya yönlendirme URL\'si';

  @override
  String get credentialsPasteRedirectHint =>
      'Sağlayıcının verdiği kodu veya tam yönlendirme URL\'sini yapıştırın';

  @override
  String get credentialsCompleteLogin => 'Oturum açmayı tamamla';

  @override
  String get credentialsUpdateToken => 'Token\'ı güncelle';

  @override
  String get credentialsAddToken => 'Token ekle';

  @override
  String get credentialsPersonalToken => 'Kişisel erişim token\'ı';

  @override
  String get credentialsPersonalTokenHint =>
      'Kişisel erişim token\'ını yapıştırın';

  @override
  String get credentialsStopWatching => 'İzlemeyi durdur';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'Claude Code oturumunun süresi doldu';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'Hesabı artık kimlik doğrulayamadığı için çalışma durdu. Yeniden oturum açın, ardından turu yeniden deneyin.';

  @override
  String get transcriptSignInExpiredTitle =>
      'Sağlayıcı oturumunun süresi doldu';

  @override
  String get transcriptSignInExpiredBody =>
      'Sağlayıcının kimlik bilgisi artık çalışmadığı için çalışma durdu. Ayarlar → Sağlayıcılar bölümünden yeniden bağlayın, ardından turu yeniden deneyin.';

  @override
  String get permissionHostExecution => 'Ana makinede komut çalıştır';

  @override
  String credentialsSignInLapsed(String provider) {
    return '$provider oturumunun süresi doldu. Yeniden oturum aç.';
  }

  @override
  String get credentialsSignInPaused =>
      'Duraklatıldı: bu çalışma alanının oturum açma hizmeti değişti. Hizmet geri geldiğinde yeniden çalışır.';

  @override
  String credentialsProviderUnreachable(String provider) {
    return '$provider şu anda erişilemiyor. Yeniden deneniyor.';
  }

  @override
  String get credentialsScopeWorkspace => 'Yalnızca bu çalışma alanı';

  @override
  String get credentialsScopeAllWorkspaces => 'Tüm çalışma alanları';

  @override
  String get credentialsRemoveConfirmWorkspace =>
      'Kayıtlı kimlik bilgin bu çalışma alanından kaldırılsın mı? Diğerleri kendi bilgilerini korur.';

  @override
  String get credentialsRemoveConfirmAllWorkspaces =>
      'Kayıtlı kimlik bilgin onu paylaşan tüm çalışma alanlarından kaldırılsın mı?';

  @override
  String get credentialsSignInServerRestarted =>
      'Sunucu yeniden başlatıldı. Oturum açmayı yeniden başlat.';

  @override
  String repoAccessInstallApp(String owner, String names) {
    return 'Otomasyonun $names depolarına erişmesi için GitHub App\'i $owner hesabına yükle. GitHub\'ı açmak için dokun.';
  }

  @override
  String repoAccessAskAdminInstall(String owner, String names) {
    return 'GitHub App $owner hesabında yüklü değil, bu yüzden otomasyon $names depolarına erişemiyor. Yüklemesi için çalışma alanının bir yöneticisine başvur.';
  }

  @override
  String repoAccessAddToApp(String names) {
    return '$names depolarını GitHub App\'in depolarına ekle. GitHub\'ı açmak için dokun.';
  }

  @override
  String repoAccessAskAdminAdd(String names) {
    return 'GitHub App $names depolarını henüz göremiyor. Onları uygulamanın depolarına eklemesi için çalışma alanının bir yöneticisine başvur.';
  }

  @override
  String repoAccessSuspended(String names) {
    return 'GitHub App kurulumu askıya alındı. Hesabın bir sahibi kurulumu GitHub\'da sürdürene kadar $names için otomasyon duraklatıldı.';
  }

  @override
  String repoAccessOwnerCannotSee(String names) {
    return 'Bu çalışma alanının otomasyonundan sorumlu kişi artık $names depolarını göremiyor, bu yüzden orada onun adına hiçbir şey çalışmıyor.';
  }

  @override
  String repoAccessOwnerNotSignedIn(String names) {
    return 'Bu çalışma alanının otomasyonundan sorumlu kişi forge\'da oturum açmamış, bu yüzden $names için otomasyon o oturum açana kadar bekliyor.';
  }

  @override
  String repoAccessRetrying(String names) {
    return '$names erişimi kontrol edilemedi. Yeniden deneniyor.';
  }

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count depodaki pull request\'leri de görmek için $forge hizmetinde oturum aç',
      one:
          '1 depodaki pull request\'leri de görmek için $forge hizmetinde oturum aç',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$forge hesabın göremediği için $count depo gizlendi',
      one: '$forge hesabın göremediği için 1 depo gizlendi',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bu çalışma alanında erişimin olmadığı için $count depo gizlendi',
      one: 'Bu çalışma alanında erişimin olmadığı için 1 depo gizlendi',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count depoya daha erişimin kontrol ediliyor…',
      one: '1 depoya daha erişimin kontrol ediliyor…',
    );
    return '$_temp0';
  }

  @override
  String get credentialsAtlassianEmail => 'Atlassian hesabının e-postası';

  @override
  String get credentialsAtlassianEmailInvalid =>
      'Atlassian hesabının e-posta adresini gir.';

  @override
  String get credentialsBitbucketApiToken => 'API token\'ı';

  @override
  String repoAccessAutomationTokenMissing(String names) {
    return 'Hiçbir otomasyon belirteci $names deposunu okuyamıyor, bu yüzden oradaki arka plan işleri duraklatıldı. Bir yönetici Ayarlar → Depolar bölümünden bir tane ekleyebilir.';
  }

  @override
  String get credentialsSignInConfirmInBrowser =>
      'Tarayıcınızda onaylayın, ardından gösterdiği kodu aşağıdaki alana girin.';

  @override
  String get credentialsSignInAccountAlreadyBound =>
      'Bu hesap bu sunucuda başka bir kişiye zaten bağlı. Farklı bir hesapla oturum açın.';

  @override
  String credentialsTokenUnreachable(String provider) {
    return 'Bu token’ı kontrol etmek için $provider ulaşılamadı. Birazdan yeniden deneyin.';
  }

  @override
  String credentialsTokenRejected(String provider) {
    return '$provider bu token’ı kabul etmiyor. Tamamını kopyaladığınızı ve iptal edilmediğini kontrol edin.';
  }

  @override
  String credentialsTokenWrongKind(String provider) {
    return 'Bu kişisel bir token değil. Kendi $provider hesabınızdan kişisel bir erişim token’ı yapıştırın; proje, grup, çalışma alanı veya bot token’ı değil.';
  }

  @override
  String credentialsTokenNarrowScope(String scope) {
    return 'Bu token’da $scope kapsamı yok; inceleme ve yorum için bu gerekli. Bunu içeren bir tane oluşturun.';
  }

  @override
  String get credentialsTokenExpired =>
      'Bu token’ın süresi dolmuş. Yeni bir tane oluşturup buraya yapıştırın.';

  @override
  String get credentialsSignInRateLimited =>
      'Şu anda çok fazla istek var. Bir süre bekleyip yeniden deneyin.';

  @override
  String get credentialsSignInCancelled =>
      'Oturum açma iptal edildi veya reddedildi. Hazır olduğunuzda yeniden başlatın.';

  @override
  String get credentialsSignInNoLongerOpen =>
      'Bu oturum açma artık açık değil: iptal edildi, kullanıldı veya yenisiyle değiştirildi. Yeniden başlatın.';

  @override
  String get noWorkspacesYetHint =>
      'Bir çalışma alanı yöneticisinin sizi davet etmesi gerekir ya da sunucu sahibi sizin için bir çalışma alanı oluşturabilir.';

  @override
  String repoAccessReplaced(String repos, String forge) {
    return '$repos artık $forge üzerinde farklı bir depoyu gösteriyor. Kullanmaya devam etmek için masaüstü ya da web uygulamasından yeniden bağlayın.';
  }

  @override
  String repoAccessAskAdminRelink(String repos, String forge) {
    return '$repos artık $forge üzerinde farklı bir depoyu gösteriyor. Tekrar kullanılabilmesi için bir çalışma alanı yöneticisinin yeniden bağlaması gerekir.';
  }

  @override
  String get runSandboxUnavailableTitle =>
      'Ajanların bu sunucuda sandbox’a ihtiyacı var';

  @override
  String get runSandboxUnavailable =>
      'Bu sunucuda sandbox yok, bu yüzden burada ajanları yalnızca sahibi çalıştırabilir. Sahip sandbox’ı kurabilir ya da herkes için sandboxing’i kapatabilir.';

  @override
  String get scriptToolCalls => 'Araç çağrıları';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count çağrı',
      one: '1 çağrı',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count çalışıyor';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count başarılı';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count başarısız';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count reddedildi';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count iptal edildi';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count kuyrukta';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count atlandı';
  }

  @override
  String get scriptStepQueued => 'Kuyrukta';

  @override
  String get scriptStepSkipped => 'Atlandı';

  @override
  String get scriptGroupLoop => 'Döngü';

  @override
  String get scriptGroupEach => 'Her biri için';

  @override
  String get scriptGroupParallel => 'Paralel';

  @override
  String get scriptGroupFunction => 'İşlev';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count çağrı daha göster',
      one: '1 çağrı daha göster',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced => 'Betikte yeri belirlenemeyen çağrılar';

  @override
  String get scriptToolComputed => 'Araç';

  @override
  String scriptStepSemantics(String subject, String state) {
    return '$subject, $state';
  }

  @override
  String get scriptSourceLabel => 'Betik';

  @override
  String scriptSourceLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count satır',
      one: '1 satır',
    );
    return '$_temp0';
  }

  @override
  String get scriptStateRunning => 'Çalışıyor';

  @override
  String get scriptStateCompleted => 'Tamamlandı';

  @override
  String get scriptStateFailed => 'Başarısız';

  @override
  String get scriptStateTimedOut => 'Süre doldu';

  @override
  String get scriptStateCancelled => 'İptal edildi';

  @override
  String get scriptStateMemoryExceeded => 'Bellek yetersiz';

  @override
  String get scriptStateOutputExceeded => 'Çıktı çok fazla';

  @override
  String get scriptStateSandboxError => 'Sandbox hatası';

  @override
  String get scriptStateRefused => 'Reddedildi';

  @override
  String get scriptOriginLine => 'Ajanın çalıştırdığı bir betikten';

  @override
  String get codeModeTitle => 'Kod modu';

  @override
  String get codeModeAvailable => 'Kullanılabilir';

  @override
  String get codeModeUnavailable => 'Kullanılamıyor';

  @override
  String codeModeUnavailableNote(String reason) {
    return 'Bu sunucu betik çalıştıramaz, bu yüzden buradaki ajanlar araçlarını tek tek çağırır. Sunucunun açıklaması: $reason';
  }

  @override
  String get codeModeNoReason => 'bir neden belirtilmedi.';

  @override
  String get workKindUnknown => 'Bu sürümün bilmediği bir neden:';

  @override
  String get workRefusalUnknown => 'Sunucu bunu reddetti:';

  @override
  String workActionFailed(String error) {
    return 'Bu işe yaramadı: $error';
  }

  @override
  String get wakeKindStopped =>
      'Bir kişi çalıştırmayı durdurduğu için tutuldu.';

  @override
  String get wakeKindAttempts => 'Teslimat üç kez başarısız oldu.';

  @override
  String get wakeKindAgentDeleted => 'Bu ajan artık yok.';

  @override
  String get wakeKindAgentNotDispatchable => 'Ajan kullanımdan kaldırıldı.';

  @override
  String get wakeKindAgentPaused => 'Ajan duraklatıldı.';

  @override
  String get wakeKindPersonRemoved =>
      'Adına hareket ettiği kişi çalışma alanından ayrıldı.';

  @override
  String get wakeKindBudgetBlocked => 'Bir bütçe çalıştırmayı engelliyor.';

  @override
  String get wakeKindTakeOver => 'Bir kişi çalışma ağacını devraldı.';

  @override
  String get wakeKindRateCapConversation =>
      'Bu konuşma son bir saatte uyandırmalardan 30 çalıştırma başlattı.';

  @override
  String get wakeKindRateCapWorkspace =>
      'Bu çalışma alanı son bir saatte uyandırmalardan 300 çalıştırma başlattı.';

  @override
  String get wakeKindLiveRunNoInput =>
      'Ajanın buradaki canlı çalıştırması girdi kabul etmiyor.';

  @override
  String get wakeKindLiveRunOtherOptions =>
      'Ajanın buradaki canlı çalıştırması farklı çalışıyor, bu yüzden bu, ondan sonra kendi çalıştırmasını başlatır.';

  @override
  String get wakeKindLiveRunOtherPerson =>
      'Ajanın buradaki canlı çalıştırması başka birine adına çalışıyor, bu yüzden bu, ondan sonra kendi çalıştırmasını başlatır.';

  @override
  String get wakeKindDispatchRefused => 'Çalıştırma başlatılamadı.';

  @override
  String get wakeKindSandboxUnavailable =>
      'Salt okunur bir çalıştırma için sandbox kullanılamıyor.';

  @override
  String get wakeKindReadOnlyUnavailable =>
      'Bu ajanın arka ucu bir çalıştırmayı salt okunur tutamıyor.';

  @override
  String get wakeKindServerStopped =>
      'Bir sunucu yeniden başlatması çalıştırmayı durdurdu.';

  @override
  String get wakeKindServerRestarted =>
      'Sunucu bir kişinin çalıştırması sırasında yeniden başlatıldı.';

  @override
  String get wakeKindGuardFailed =>
      'Teslimattan önceki bir kontrol başarısız oldu.';

  @override
  String get wakeKindLimit =>
      'Sağlayıcının kullanım sınırının sıfırlanmasını bekliyor.';

  @override
  String get wakeKindLimitRunLive =>
      'Kullanım sınırındaki çalıştırmanın bitmesi bekleniyor.';

  @override
  String get wakeKindWakeMissed => 'Sunucu kapalıyken kaçırıldı.';

  @override
  String get wakeKindPipelineRunEnded => 'Pipeline çalıştırması bitti.';

  @override
  String get wakeKindGoalEnded => 'Hedefi sona erdi.';

  @override
  String get wakeKindGoalBudgetExhausted => 'Hedef bütçesini tüketti.';

  @override
  String get wakeKindGoalReviewStale =>
      'Bu inceleme istendikten sonra hedef değişti.';

  @override
  String get wakeKindGoalPaused => 'Hedef duraklatıldı.';

  @override
  String get wakeKindGoalHeld => 'Hedef tutuluyor.';

  @override
  String get wakeKindGoalStopped => 'Hedef durduruldu.';

  @override
  String get wakeKindAskSettled => 'Yanıtladığı soru zaten sonuçlandı.';

  @override
  String get wakeKindRuleEnded => 'Zamanlaması sona erdi.';

  @override
  String get wakeRefusalNotYours =>
      'Bu uyandırma başka bir kişi adına hareket ediyor. Yalnızca onlar teslim edebilir veya sürdürebilir.';

  @override
  String get wakeRefusalSettled => 'Bu uyandırma zaten sonuçlandı.';

  @override
  String get goalRefusalAlreadyActive =>
      'Bu ajanın zaten etkin bir hedefi var.';

  @override
  String get goalRefusalNotInReview => 'Bu hedef inceleme beklemiyor.';

  @override
  String get goalRefusalEvidenceIncomplete => 'Hedefin kanıtı eksik.';

  @override
  String get goalRefusalClaimPending =>
      'Tamamlandığına dair iddia hâlâ kontrol ediliyor.';

  @override
  String get goalRefusalNotActiveSegment => 'Bu hedefte çalışan bir bölüm yok.';

  @override
  String get goalRefusalNotYours =>
      'Bunu yalnızca bu hedefi başlatan kişi yapabilir.';

  @override
  String get goalRefusalNotPaused => 'Önce hedefi duraklatın.';

  @override
  String get goalRefusalContractInvalid => 'Hedefin sözleşmesi okunamıyor.';

  @override
  String get goalRefusalCheckerUnknown => 'Bu ada sahip bir ajan yok.';

  @override
  String get goalRefusalCheckerAmbiguous =>
      'Bu ada sahip birden fazla ajan var.';

  @override
  String get goalRefusalCheckerIsGoalAgent =>
      'Denetleyici, işi yapan ajandan farklı bir ajan olmalı.';

  @override
  String get goalRefusalCommandInvalid => 'Bu hedef okunamıyor:';

  @override
  String get wakeRuleRefusalIntervalTooShort =>
      'Aralık çok kısa. En az bir dakika seçin.';

  @override
  String get wakeRuleRefusalTooSoon =>
      'Bu zaman çok yakın. Daha sonraki bir zaman seçin.';

  @override
  String get wakeRuleRefusalLineageEnded =>
      'Bu uyandırma zinciri çalıştırma hakkını veya süresini kullandı.';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable =>
      'Bunun izleyeceği şeyi göremezsiniz.';

  @override
  String get wakeRuleRefusalExpiryRequired =>
      'Bir bitiş tarihi ya da çalıştırma sayısı verin.';

  @override
  String get wakeRuleRefusalLimitReached =>
      'Bu konuşma veya ajan zaten izin verilen kadar zamanlamaya sahip.';

  @override
  String get wakeRuleRefusalInvalidWhen => 'Zaman okunamıyor.';

  @override
  String get wakeRuleRefusalNoteTooLong => 'Not çok uzun.';

  @override
  String get wakeRuleRefusalExpiryTooLong => 'Bitiş çok uzakta.';

  @override
  String get wakeRuleRefusalLimitOutOfRange =>
      'Çalıştırma, gün veya bütçe sınırı aralığın dışında.';

  @override
  String get wakeRuleRefusalNextOutsideLoop =>
      'Yalnızca bir döngü kendi sonraki zamanını seçebilir.';

  @override
  String get wakeRuleRefusalWatchRefused => 'Bu izlenemez.';

  @override
  String get wakeRuleRefusalRuleEnded => 'Bu zamanlama zaten sona erdi.';

  @override
  String get wakeRuleRefusalNotYours => 'Bu zamanlama başka birine ait.';

  @override
  String get wakeRuleEndFired => 'Tek seferlik çalıştırmasını yaptı.';

  @override
  String get wakeRuleEndExpired => 'Bitiş tarihine ulaştı.';

  @override
  String get wakeRuleEndRunCap => 'Çalıştırma hakkını kullandı.';

  @override
  String get wakeRuleEndCostCap => 'Maliyet sınırına ulaştı.';

  @override
  String get wakeRuleEndGoalEnded => 'Hedefi bitti.';

  @override
  String get wakeRuleEndCancelled => 'İptal edildi.';

  @override
  String get wakeRuleEndMemberRemoved =>
      'Adına hareket ettiği kişi çalışma alanından ayrıldı.';

  @override
  String get wakeRuleEndInvalidRow => 'Kayıtlı ayarları okunamadı.';

  @override
  String goalHoldWorking(int segment) {
    final intl.NumberFormat segmentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String segmentString = segmentNumberFormat.format(segment);

    return 'Bölüm $segmentString üzerinde çalışıyor. Kimsenin yapması gereken bir şey yok.';
  }

  @override
  String get goalHoldWaiting =>
      'Kendisine borçlu olunan iş için bekliyor. Kendiliğinden devam eder.';

  @override
  String goalHoldWaitingUntil(String time) {
    return 'Kendisine borçlu olunan iş için bekliyor. En geç $time saatinde kendiliğinden devam eder.';
  }

  @override
  String get goalHoldVerifying =>
      'Tamamlandığını söylüyor. Sunucu kontrollerini çalıştırır, sonra bir denetleyici karar verir.';

  @override
  String get goalHoldLimit =>
      'Sağlayıcının kullanım sınırında duraklatıldı. Sınır sıfırlandıktan sonra kendiliğinden sürdürülür.';

  @override
  String goalHoldLimitUntil(String time) {
    return 'Sağlayıcının kullanım sınırında duraklatıldı. $time saatinde kendiliğinden sürdürülür.';
  }

  @override
  String get goalHoldPerson =>
      'Konuşmada bir kişinin yanıtını bekliyor. Biri yanıtladığında devam eder.';

  @override
  String get goalHoldByPerson =>
      'Bir kişi tarafından duraklatıldı. Biri sürdürene kadar duraklatılmış kalır.';

  @override
  String get goalHoldNeedsReview =>
      'İnceleme bekliyor: kendiliğinden devam edemez. Tamamlandı olarak onaylayın, sürdürün veya iptal edin.';

  @override
  String get goalHoldBudget =>
      'Bütçesini tüketti. Devam etmesi için bütçeyi artırın.';

  @override
  String goalHoldLimitParks(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Kullanım sınırı duraklatmaları: $countString / $maxString';
  }

  @override
  String get goalHoldDetailStalled => 'Son bölümlerinde ilerleme yok.';

  @override
  String get goalHoldDetailStalledWaiting =>
      'Aynı iş için 24 saat bekledi, ilerleme olmadı.';

  @override
  String get goalHoldDetailVerificationFailed => 'Son kontrol başarısız oldu.';

  @override
  String get goalHoldDetailCannotVerify =>
      'Denetleyici, bitip bitmediğini anlayamadı.';

  @override
  String get goalHoldDetailSandboxUnavailable =>
      'Kontrollerini çalıştırmak için sandbox kullanılamıyor.';

  @override
  String get goalHoldDetailCheckerUnavailable =>
      'Denetleyici ajanı kullanılamıyor. Başka bir denetleyici seçin, sonra sürdürün.';

  @override
  String get goalHoldDetailCheckBroken => 'Bu kontrol çalıştırılamıyor:';

  @override
  String get goalHoldDetailWakeSkipped => 'Uyandırması teslim edilmedi.';

  @override
  String get goalHoldDetailClaimPending =>
      'Tamamlandığına dair iddiası bir kontrolü bekliyor.';

  @override
  String get goalHoldDetailUnanswered =>
      'Bir kişiye sorulan soru veya onay isteği yanıtsız kaldı.';

  @override
  String get goalHoldDetailLimitParks =>
      'Kullanım sınırlarına çok sık takıldı. Gözden geçirin, sonra sürdürün.';

  @override
  String get goalHoldDetailInput => 'Konuşmada bir yanıt bekleniyor.';

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

    return 'Bölüm $runString / $maxString';
  }

  @override
  String goalSegmentsNoCap(int run) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);

    return 'Bölüm $runString, sınır yok';
  }

  @override
  String goalMoney(String spent, String cap) {
    return '$cap sınırından $spent harcandı';
  }

  @override
  String goalDeadline(String time) {
    return 'Son tarih $time';
  }

  @override
  String get goalPipelineStep =>
      'Bir pipeline adımı bu hedef üzerinde çalışıyor.';

  @override
  String get goalSummaryHeading => 'Son özet';

  @override
  String get goalDoneMeans => 'Tamamlanma ölçütleri';

  @override
  String get goalChecks => 'Kontroller';

  @override
  String get goalBoundaries => 'Sınırlar';

  @override
  String get goalStopWhen => 'Şu durumda durup sorun';

  @override
  String get goalNoMachineCheck =>
      'Makine kontrolü yok. Bir denetleyici okuyabildiklerinden karar verir.';

  @override
  String get goalCheckEnvironment => 'Ortam görevi';

  @override
  String goalLastCheck(int round, String time) {
    final intl.NumberFormat roundNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String roundString = roundNumberFormat.format(round);

    return 'Son kontrol, tur $roundString, $time';
  }

  @override
  String get goalClaim => 'Ne iddia etti';

  @override
  String get goalCheckPassed => 'Geçti';

  @override
  String goalCheckFailed(int code) {
    return 'Başarısız, çıkış $code';
  }

  @override
  String get goalCheckTimedOut => 'Süre doldu';

  @override
  String get goalCheckNotRerun =>
      'Yeniden çalıştırılmadı: hiçbir şey değişmedi';

  @override
  String get goalCheckBroken => 'Çalıştırılamıyor';

  @override
  String get goalCriterionMet => 'Karşılandı';

  @override
  String get goalCriterionUnmet => 'Karşılanmadı';

  @override
  String get goalCriterionCannotTell => 'Anlaşılamıyor';

  @override
  String get goalVerdictPass => 'Karar: tamamlandı';

  @override
  String get goalVerdictFail => 'Karar: tamamlanmadı';

  @override
  String get goalVerdictCannotVerify => 'Karar: karar verilemedi';

  @override
  String get goalConcerns => 'Endişeler';

  @override
  String goalVerifiedBy(String agent) {
    return 'Doğrulayan: $agent';
  }

  @override
  String get goalVerifiedBySelf => 'Kendisi doğruladı (ayrı denetleyici yok)';

  @override
  String get goalClosedByPerson =>
      'Geçen bir kontrol olmadan bir kişi tarafından kapatıldı';

  @override
  String get goalApprove => 'Tamamlanmayı onayla';

  @override
  String get goalApproveTitle => 'Bu hedef tamamlandı olarak kapatılsın mı?';

  @override
  String get goalApproveBody =>
      'Hiçbir kontrol bunu doğrulamadı. Hedefi kendi sözünüze dayanarak kapatırsınız ve hedef, bir kişinin bunu doğrulanmadan kapattığını kaydeder.';

  @override
  String get goalApproveConfirm => 'Tamamlandı olarak kapat';

  @override
  String get goalResumeNotYours =>
      'Sürdürmek veya bütçesini artırmak, hedefi başlatan kişiye aittir.';

  @override
  String get goalChooseChecker => 'Başka bir denetleyici seçin';

  @override
  String goalCheckerSet(String agent) {
    return 'Artık $agent denetliyor. Yeniden doğrulamak için sürdürün.';
  }

  @override
  String get goalSchedules => 'Zamanlamalar';

  @override
  String get goalRepeat => 'Tekrarla';

  @override
  String get goalCreateChecks => 'Kontroller (isteğe bağlı)';

  @override
  String get goalCreateCheckHint => 'Çalışma bittiğinde geçen bir komut';

  @override
  String get goalCreateAddCheck => 'Kontrol ekle';

  @override
  String get goalCreateRemoveCheck => 'Kontrolü kaldır';

  @override
  String get goalCreateSegmentCap => 'Bölüm sınırı (isteğe bağlı)';

  @override
  String get goalCreateSegmentInvalid =>
      'Bölüm sınırı tam sayı olmalı ve en az 1 olmalı.';

  @override
  String get scheduleCreateTitle => 'Bir istemi tekrarla';

  @override
  String get scheduleCadence => 'Ne sıklıkla';

  @override
  String get scheduleEveryMinutes => 'Her N dakikada bir';

  @override
  String get scheduleEveryHours => 'Her N saatte bir';

  @override
  String get scheduleSelfPaced => 'Ajan belirler';

  @override
  String get scheduleSelfPacedHint =>
      'Ajan her çalıştırmadan sonra bir dakika ile bir saat arasında bir gecikme seçer.';

  @override
  String get scheduleInterval => 'Aralık';

  @override
  String get scheduleNote => 'Her çalıştırma ne yapmalı?';

  @override
  String get scheduleCostCap => 'Maliyet sınırı, USD (isteğe bağlı)';

  @override
  String get scheduleExpiryDays => 'N gün sonra biter (isteğe bağlı)';

  @override
  String get scheduleCreateInvalid =>
      'Bir space ve bir ajan seçin, her çalıştırmanın ne yapması gerektiğini yazın ve en az 1 olan tam sayılar verin.';

  @override
  String get scheduleCreateButton => 'Zamanlamayı başlat';

  @override
  String get scheduleCreateConfirmTitle => 'Bu zamanlama başlatılsın mı?';

  @override
  String scheduleCreateConfirmEveryMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Her $countString dakikada bir, şimdi başlayarak çalışır.',
      one: 'Her dakika, şimdi başlayarak çalışır.',
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
      other: 'Her $countString saatte bir, şimdi başlayarak çalışır.',
      one: 'Her saat, şimdi başlayarak çalışır.',
    );
    return '$_temp0';
  }

  @override
  String get scheduleCreateConfirmSelfPaced =>
      'Şimdi çalışır, sonra ajan yeniden ne zaman çalışacağını seçer.';

  @override
  String get scheduleCreated =>
      'Zamanlama başlatıldı. Zamanlamalar altında listelenir.';

  @override
  String get schedulesTitle => 'Zamanlamalar';

  @override
  String get schedulesLoadFailed => 'Zamanlamalar yüklenemedi';

  @override
  String get schedulesEmpty => 'Zamanlama veya izleme yok';

  @override
  String get schedulesEmptyDescription =>
      'Hedefler ekranından bir istemi tekrarlayın ya da bir konuşmada /loop veya /schedule gönderin.';

  @override
  String get scheduleMissing =>
      'Bu zamanlama artık bu çalışma alanında kullanılamıyor.';

  @override
  String scheduleEvery(String interval) {
    return 'Her $interval';
  }

  @override
  String get scheduleSelfPacedLoop => 'Ajanın sonraki zamanını seçtiği döngü';

  @override
  String get scheduleCron => 'Cron zamanlaması';

  @override
  String scheduleOnce(String time) {
    return '$time zamanında bir kez';
  }

  @override
  String scheduleWatch(String event) {
    return 'İzleme: $event';
  }

  @override
  String get scheduleWatchPrChecks => 'pull request kontrolleri';

  @override
  String get scheduleWatchPrReview => 'pull request incelemeleri';

  @override
  String get scheduleWatchPrMerged => 'pull request birleştirmesi';

  @override
  String get scheduleWatchEnvironment => 'ortam';

  @override
  String get scheduleWatchTicket => 'bilet';

  @override
  String get scheduleWatchPipelineRun => 'pipeline çalıştırması';

  @override
  String get scheduleStatusActive => 'Etkin';

  @override
  String get scheduleStatusPaused => 'Duraklatıldı';

  @override
  String get scheduleStatusEnded => 'Sona erdi';

  @override
  String scheduleWakes(String agent) {
    return 'Uyandırır: $agent';
  }

  @override
  String scheduleNext(String time) {
    return 'Sonraki çalıştırma $time';
  }

  @override
  String scheduleLast(String time) {
    return 'Son çalıştırma $time';
  }

  @override
  String scheduleRuns(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString çalıştırma',
      one: '1 çalıştırma',
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

    return '$countString / $maxString çalıştırma';
  }

  @override
  String scheduleSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString atlandı',
      one: '1 atlandı',
    );
    return '$_temp0';
  }

  @override
  String scheduleEnds(String time) {
    return 'Biter $time';
  }

  @override
  String scheduleChain(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Bir zincirin parçası: $countString çalıştırma kaldı, $time saatinde biter';
  }

  @override
  String get scheduleNoteAgent => 'Ajanın kendi notu, kendi sözleriyle:';

  @override
  String get scheduleNotePerson => 'Bir kişinin notu:';

  @override
  String scheduleActsFor(String name) {
    return '$name adına hareket eder';
  }

  @override
  String get scheduleActsForBot => 'Hiçbir kişi adına hareket etmez';

  @override
  String get scheduleGoalBound => 'Hedefiyle birlikte sona erer.';

  @override
  String get schedulePause => 'Duraklat';

  @override
  String get scheduleResume => 'Sürdür';

  @override
  String get scheduleDelete => 'Sil';

  @override
  String get scheduleRemove => 'Kaldır';

  @override
  String get scheduleDeleteTitle => 'Bu zamanlama silinsin mi?';

  @override
  String get scheduleDeleteBody =>
      'Kalıcı olarak durur. Zaten yaptığı hiçbir şey geri alınmaz.';

  @override
  String get scheduleRemoveTitle => 'Bu zamanlama kaldırılsın mı?';

  @override
  String get scheduleRemoveBody => 'Listeden kalkar.';

  @override
  String get scheduleResumeNotYours =>
      'Yalnızca bu zamanlamanın adına hareket ettiği kişi sürdürebilir.';

  @override
  String get scheduleResumeAdminOnly =>
      'Hiçbir kişiye ait olmayan bir zamanlamayı yalnızca çalışma alanı yöneticisi sürdürebilir.';

  @override
  String get scheduleOpenConversation => 'Konuşmayı aç';

  @override
  String get progressWaiting => 'Bekliyor';

  @override
  String get progressNothingWaiting => 'Hiçbir şey beklemiyor.';

  @override
  String get wakeOriginGoal => 'Hedef';

  @override
  String get wakeOriginGoalCheck => 'Hedef kontrolü';

  @override
  String get wakeOriginGoalReview => 'Hedef incelemesi';

  @override
  String get wakeOriginSchedule => 'Zamanlama';

  @override
  String get wakeOriginWatch => 'İzleme';

  @override
  String get wakeOriginReply => 'Yanıt';

  @override
  String get wakeOriginMessage => 'İleti';

  @override
  String get wakeOriginWorkFinished => 'Tamamlanan iş';

  @override
  String get wakeOriginLimitReset => 'Sınır sıfırlandı';

  @override
  String get wakeOriginRecovery => 'Kurtarma';

  @override
  String get wakeOriginAssignment => 'Atama';

  @override
  String get wakeOriginPipelineStep => 'Pipeline adımı';

  @override
  String get wakeOriginImprovementReview => 'İyileştirme incelemesi';

  @override
  String wakeOriginReplyFrom(String agent) {
    return '$agent yanıtı';
  }

  @override
  String wakeOriginMessageFrom(String agent) {
    return '$agent iletisi';
  }

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return '$agent tarafından tamamlanan iş';
  }

  @override
  String wakeFor(String agent) {
    return '$agent için';
  }

  @override
  String wakeDue(String time) {
    return 'Zamanı $time';
  }

  @override
  String get wakeDueNow => 'Şimdi zamanı geldi';

  @override
  String get wakeHeld => 'Tutuldu';

  @override
  String wakeExpires(String time) {
    return 'Sona erer: $time';
  }

  @override
  String wakeAttempt(int attempt) {
    final intl.NumberFormat attemptNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attemptString = attemptNumberFormat.format(attempt);

    return 'Deneme $attemptString';
  }

  @override
  String get wakeCancel => 'İptal';

  @override
  String get wakeDeliverNow => 'Şimdi teslim et';

  @override
  String get wakeResume => 'Sürdür';

  @override
  String get wakeDismiss => 'Yoksay';

  @override
  String get wakeResumeOnlyTheirs =>
      'Yalnızca bu çalıştırması kendisine ait olan kişi sürdürebilir.';

  @override
  String get wakeRecovery =>
      'Sunucu bu çalıştırma sırasında yeniden başladı. Sürdürmek için sürdürün veya yoksayın.';

  @override
  String limitParkTitle(String provider, String time) {
    return '$provider kullanım limitinde duraklatıldı; limit $time itibarıyla sıfırlanır. Çalışma, sıfırlanmadan sonra en fazla 7 gün Sürdür\'ü bekler.';
  }

  @override
  String limitParkTitleUnnamed(String time) {
    return 'Sağlayıcının kullanım limitinde duraklatıldı; limit $time itibarıyla sıfırlanır. Çalışma, sıfırlanmadan sonra en fazla 7 gün Sürdür\'ü bekler.';
  }

  @override
  String get limitParkResumeNow => 'Şimdi sürdür';

  @override
  String get limitParkCancel => 'İptal';

  @override
  String limitParkResumed(String provider) {
    return '$provider kullanım sınırından sonra sürdürüldü.';
  }

  @override
  String limitParkGone(String provider) {
    return 'Artık $provider kullanım sınırında beklemiyor.';
  }

  @override
  String get limitParkProviderUnknown => 'sağlayıcı';

  @override
  String get mobileHeldMessages => 'Tutulan iletiler';

  @override
  String get heldSteeringTitle =>
      'Çalıştırma, bunları almadan önce bittiği için tutuldu. Sizinkileri şimdi gönderin veya kaldırın.';

  @override
  String get heldSteeringRelease => 'Tutulan iletileri gönder';

  @override
  String get notifGoalCompleted => 'Hedef tamamlandı';

  @override
  String get notifGoalFailed => 'Hedef başarısız oldu';

  @override
  String get notifGoalCancelled => 'Hedef iptal edildi';

  @override
  String get notifGoalBudgetExhausted => 'Hedef bütçesini tüketti';

  @override
  String get notifGoalNeedsReview => 'Bir hedef incelemenizi bekliyor';

  @override
  String get notifGoalNeedsPerson => 'Bir hedefe sizin ilginiz gerekiyor';

  @override
  String get notifGoalOnHold => 'Bir hedef tutuluyor';

  @override
  String get notifWakeRuleEnded => 'Bir zamanlama sona erdi';

  @override
  String notifWaitingDigest(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString şey sizi bekliyor',
      one: '1 şey sizi bekliyor',
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
      other: '$countString iyileştirme önerildi',
      one: 'Bir iyileştirme önerildi',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld =>
      'Bir pipeline çalıştırması bütçesinde tutuluyor';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return '$cap sınırından $spent harcandı';
  }

  @override
  String get notifNeedsYou => 'Sizden bekleniyor';

  @override
  String get notifDigestGoalReview => 'Hedef incelemeyi bekliyor';

  @override
  String get notifDigestGoalPerson => 'Hedefin bir kişiye ihtiyacı var';

  @override
  String get notifDigestHeldWake => 'Tutulan uyandırma';

  @override
  String get notifDigestImprovement => 'Önerilen iyileştirme';

  @override
  String get wakeKindRulePaused => 'Zamanlaması duraklatıldı.';

  @override
  String get wakeKindRuleBusy =>
      'Ajan meşguldü ve bu zamanlama meşgul olduğu zamanları atlar.';

  @override
  String get wakeKindRuleFolded =>
      'Aynı izlemenin daha sonraki bir olayı onun yerini aldı.';

  @override
  String get wakeKindRuleSuperseded =>
      'Zamanlamasının daha sonraki bir zamanı onun yerini aldı.';

  @override
  String get wakeKindRuleNotified =>
      'Zamanlaması yalnızca bildirim gönderir, bu yüzden bir çalıştırma başlamadı.';

  @override
  String get wakeKindRuleLimitParked =>
      'Zamanlaması sağlayıcının kullanım sınırının sıfırlanmasını bekliyor.';

  @override
  String get improvementRefusalCooldown =>
      'Bu konuşmada kısa bir süre önce bir iyileştirme incelemesi çalıştı. Daha sonra yeniden deneyin.';

  @override
  String get improvementRefusalQueued =>
      'Bu konuşmanın bir iyileştirme incelemesi zaten çalışmayı bekliyor.';

  @override
  String get improvementRefusalAgentNotFound =>
      'Bu ajan bu çalışma alanının bir ajanı değil.';

  @override
  String get steeringRefusalHeldByLimit =>
      'Kullanım sınırında tutulan iletiler elle gönderilemez. Duraklatılmış çalıştırmanın sürdürülmesini bekler.';

  @override
  String limitParkCancelled(String provider) {
    return '$provider kullanım sınırındaki bekleme iptal edildi.';
  }

  @override
  String limitParkExpired(String provider) {
    return 'Çalıştırma sürdürülmeden önce $provider kullanım sınırındaki bekleme süresi doldu.';
  }

  @override
  String limitParkSkipped(String provider) {
    return 'Çalıştırma $provider kullanım sınırından sonra sürdürülmedi.';
  }

  @override
  String get heldSteeringLimitTitle =>
      'Çalışma, kullanım limitinin sıfırlanmasını beklerken tutuldu. Bunlar, çalışmanın adına hareket ettiği kişi çalışmayı sürdürdüğünde gönderilir.';

  @override
  String heldSteeringLimitAt(String time) {
    return 'Kullanım limiti $time itibarıyla sıfırlanana kadar tutuldu. Bunlar, çalışmanın adına hareket ettiği kişi çalışmayı sürdürdüğünde gönderilir.';
  }

  @override
  String get heldSteeringOtherTitle =>
      'Sunucu tarafından tutuldu. Kaldırabilirsiniz.';

  @override
  String workRowWoke(int count, String agent) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bekleyen öğe için $agent uyandırıldı',
      one: '$agent uyandırıldı',
    );
    return '$_temp0';
  }

  @override
  String workRowWakeMissed(String agent) {
    return '$agent için bir uyandırma sunucu kapalıyken kaçırıldı.';
  }

  @override
  String workRowWakeSkipped(String agent) {
    return '$agent için bir uyandırma teslim edilmedi.';
  }

  @override
  String workRowScheduleCreated(String agent) {
    return '$agent için zamanlama ayarlandı.';
  }

  @override
  String workRowScheduleEnded(String agent) {
    return '$agent için zamanlama sona erdi.';
  }

  @override
  String workRowNoteFromAgent(String agent) {
    return '$agent tarafından zamanlama notu:';
  }

  @override
  String get workRowNoteFromPerson => 'Bir kişiden zamanlama notu:';

  @override
  String workRowCommandRefusedNamed(String command) {
    return '$command komutu reddedildi.';
  }

  @override
  String get workRowCommandRefused => 'Bir komut reddedildi.';

  @override
  String workRowCapRaised(String person, String from, String to) {
    return '$person, pipeline’ın harcama sınırını $from değerinden $to değerine çıkardı.';
  }

  @override
  String workRowCapRaisedNoAmounts(String person) {
    return '$person, pipeline’ın harcama sınırını çıkardı.';
  }

  @override
  String get workRowApplyIncomplete =>
      'Bu beceriye kabul edilmiş bir değişiklik, beceri bu arada değiştiği için tamamlanamadı. Öneri geri alındı.';

  @override
  String get workRowOpenSchedule => 'Zamanlamayı aç';

  @override
  String get heldSteeringOthersTitle =>
      'Çalıştırma, bunları almadan önce bittiği için tutuldu. Bir iletiyi yalnızca onu yazan kişi gönderebilir.';

  @override
  String get heldSteeringOnlyYours =>
      'Yalnızca sizin iletilerinizi gönderir. Diğerleri, onları yazan kişileri bekler.';

  @override
  String heldSteeringWrittenBy(String name) {
    return 'Yazan: $name';
  }

  @override
  String get steeringRefusalNotYours =>
      'Tutulan bir iletiyi yalnızca onu yazan kişi gönderebilir ve bunların hiçbiri sizin değil.';

  @override
  String get steeringRefusalNeedsWrite =>
      'Başka birinin adına hareket eden bir çalışmayı yönlendirmek için bu Space\'in depolarına yazma erişimine ihtiyacınız var.';

  @override
  String workRowSchedulePaused(String name, String agent) {
    return '$name, $agent için zamanlamayı duraklattı.';
  }

  @override
  String get goalVerdictObjective => 'Amacın tamamı';

  @override
  String get notifDigestRequest => 'Yanıtınızı bekliyor';
}
