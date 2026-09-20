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
  String get inboxNoForgeAccount =>
      'Sunucuda bağlı forge hesabı yok; pull request’ler henüz size atanamıyor.';

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
  String get join => 'Katıl';

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
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names buradan relay üzerinden gönderilemeyecek kadar büyük.',
      one: '$names buradan relay üzerinden gönderilemeyecek kadar büyük.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed => 'Ek yüklenemedi. Tekrar deneyin.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ek yüklenemedi ve dahil edilmedi.',
      one: '1 ek yüklenemedi ve dahil edilmedi.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Ekip arkadaşı';

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
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repo okunamadı.',
      one: '1 repo okunamadı.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'Okunamıyor: $names';
  }

  @override
  String get installationSuspendedTitle => 'GitHub App kurulumu askıya alındı';

  @override
  String installationSuspendedBody(String names) {
    return '$names için son bilinen veriler gösteriliyor. GitHub’da kurulumu sürdürün veya erişimi olan bir token bağlayın.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'GitHub App kurulumu askıya alındı. $names için son bilinen veriler gösteriliyor. GitHub’da kurulumu sürdürün veya erişimi olan bir token bağlayın.';
  }

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
}
