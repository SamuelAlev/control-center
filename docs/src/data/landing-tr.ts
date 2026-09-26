import type { LandingCopy } from './landing-en';

export const tr: LandingCopy = {
  meta: {
    title: 'Control Center | Geliştirici günün için bir yer',
    description: 'Biletleri, kod incelemelerini, yapay zekâ ajanlarını, toplantıları ve işlem hatlarını bir araya getir. Masaüstü, web ve telefon için ücretsiz, açık kaynaklı bir çalışma alanı.',
    imageAlt: 'Control Center, geliştirici işin tek bir çalışma alanında.',
  },
  nav: { product: 'Ürün', workflows: 'Akışlar', features: 'Özellikler', docs: 'Belgeler', demo: 'Demoyu dene', download: 'İndir', menu: 'Menü', primary: 'Ana gezinti', mobile: 'Mobil gezinti', home: 'Control Center ana sayfası', skip: 'İçeriğe geç', language: 'Dil', appearance: 'Görünüm', light: 'Açık', dark: 'Koyu', system: 'Sistem' },
  hero: {
    line1: 'Çok hareketli parça.',
    line2: 'Tek bir Control Center.',
    description: 'Kodun, ajanların, incelemelerin ve bir geliştirici gününü dolduran her şey için bir yer.',
    download: 'Control Center’ı edin',
    demo: 'Canlı demoyu incele',
    platforms: 'macOS, Windows, Linux',
    web: 'Webde ve telefonda da',
  },
  media: {
    phone: 'Telefon yoldaşı aynı çalışma alanını, bekleyen bir onayı ve bir ajan çalıştırmasının durumunu gösterir.',
  },
  tour: {
    label: 'Control Center’ı keşfet',
    previous: 'Önceki ürün görünümü', next: 'Sonraki ürün görünümü',
    play: 'Turu oynat', pause: 'Turu duraklat', expand: 'Önizlemeyi büyüt', close: 'Önizlemeyi kapat',
    preview: 'Ürün önizlemesi', note: 'Geliştirici gününe daha yakından bakış.', imageLanguage: 'Görüntü veya video yer tutucusu',
    stops: [
      { kind: 'desk', label: 'Günün', title: 'Seni bekleyenle başla.', description: 'İnceleme istekleri, onaylar ve tıkanıklıklar. Sonraki adım, sekmeler arasında aramadan.', alt: 'Control Center gelen kutusu, pull request’leri inceleme durumuna göre gruplar ve bir eşitleme tıkanıklığı gösterir.' },
      { kind: 'agents', label: 'Ajanlar', title: 'İyi işe yer aç.', description: 'Ajanları yalıtılmış Git worktree’lerinde çalıştır. Araçlarını izle, işi yönlendir ve bağlamı koru.', alt: 'Control Center’da görev bağlamı ve etkinlikle bir ajan konuşması.' },
      { kind: 'review', label: 'Kod incelemesi', title: 'Değişikliği oku. Hikâyeyi bil.', description: 'Diff’ler, tartışmalar ve denetimler bir arada kalır. İncelemeyi kendi hesabınla yayımla.', alt: 'Control Center’da kod değişiklikleri ve inceleme bağlamıyla bir pull request incelemesi.' },
      { kind: 'tickets', label: 'Biletler', title: 'Sonraki adım bağlı kalsın.', description: 'Öncelikleri ve sahipliği izle, Linear’ı eşitle ve işin yapıldığı konuşmayı bağla.', alt: 'Control Center bilet panosu, görevleri duruma göre gruplar.' },
      { kind: 'meetings', label: 'Toplantılar', title: 'Kararlar aramadan sonra da kalsın.', description: 'Kendi sunucunda kaydet ve yazıya dök. Toplantı bitince notların ve eylemlerin olur.', alt: 'Control Center’da döküm ve toplantı bilgisiyle bir toplantı.' },
      { kind: 'pipelines', label: 'İşlem hatları', title: 'Tekrarlanan işi tekrarlanabilir kıl.', description: 'Bir akış kur, tetikleyicisini seç ve çalıştırmanın her adımını izle.', alt: 'Control Center işlem hattı görünümü, akış adımları ve çalıştırma durumuyla.' },
    ],
  },
  integrations: { title: 'Zaten çalıştığın araçları getir.', note: 'Sunucun üzerinden bağlı, gününün bir kopyası olarak değil.' },
  grid: {
    title: 'Her gün uzanacağın araçlar.',
    description: 'İşi yap, değişeni incele ve kararları sakla.',
    more: 'Belgeleri oku',
    items: [
      { title: 'Paralel ajanlar', description: 'Her göreve yalıtılmış bir Git worktree ver. Çalıştırmayı izle, ajanı yönlendir ya da gerisini bozmadan devral.', link: 'Ajanları paralel çalıştır', kind: 'agents', href: '/manual/guides/parallel-agents/' },
      { title: 'Pull request incelemesi', description: 'Diff’leri tartışmalar ve denetimlerle yan yana oku. Yardımcı olduğunda bir yapay zekâ incelemesi ekle, sonra kendi forge hesabınla yayımla.', link: 'Bir pull request incele', kind: 'review', href: '/manual/guides/review-merge-pr/' },
      { title: 'Bağlı biletler', description: 'Linear’ı eşitle, öncelik ver ve işi ata. Bileti, işin bittiği konuşmaya bağla.', link: 'Biletleri yönet', kind: 'tickets', href: '/manual/guides/manage-tickets/' },
      { title: 'Toplantı notları', description: 'Kendi sunucunda kaydet ve yazıya dök. Kararlar ve eylemler arama bittikten sonra da durur.', link: 'Bir toplantı kaydet', kind: 'meetings', href: '/manual/guides/record-meeting/' },
      { title: 'Tekrarlanabilir işlem hatları', description: 'Bir akışı bir kez kur. Zamanlamayla, bir olaydan ya da elle çalıştır ve her adımı incele.', link: 'Bir işlem hattı kur', kind: 'pipelines', href: '/manual/guides/create-pipeline/' },
    ],
    supporting: [
      { title: 'Tek gelen kutusu', description: 'İncelemeler, onaylar ve tıkanıklıklar tek kuyrukta. Komut paletiyle sonraki göreve geç.', href: '/manual/guides/triage-inbox/' },
      { title: 'Odaklanma zamanı', description: 'Bildirimleri sustur, bir odak oturumu başlat ve üretken bir ses manzarası seç.', href: '/manual/guides/focus-mode/' },
      { title: 'Telefondan bak', description: 'Masana dönmeden çalıştırmaları izle ve onayları hallet.', href: '/manual/concepts/remote-control/' },
    ],
  },
  workflow: {
    title: 'İpi kaçırma.\nYayımlanana kadar.',
    description: 'İş araçlar arasında dolaşır. Bağlam da onunla gelmeli.',
    label: 'Bağlı bir akış',
    steps: [
      { title: 'Biletle başla.', text: 'Önceliği koy, sahibi adlandır ve konuşmayı bağla. Bilet kaydı tutar.', kind: 'tickets', label: 'Niyet' },
      { title: 'İşe kendi alanını ver.', text: 'Bir planı konuş, yalıtılmış bir worktree hazırla ve ajanı çalıştır. Gerektiğinde yönlendir ya da devral.', kind: 'agents', label: 'İş' },
      { title: 'Sonucu incelemeye getir.', text: 'Değişiklikleri oku, tartışmayı izle ve forge hesabınla yayımla. Hikâye bağlı kalır.', kind: 'review', label: 'Sonuç' },
    ],
  },
  boundaries: {
    title: 'Bir push’u çalışmadan önce onayla.',
    description: 'Git push’larını, pull request yayımlamayı ve diğer korunan eylemleri bir onayın arkasına al. Ajan bir şeyi değiştirmeden önce ne yapmak üzere olduğuna bak.',
    media: 'Bir Git push onayı isteğinde duraklatılmış ajan çalıştırması. Önerilen komutu, çalışma dizinini ve onayla ya da reddet denetimlerini göster.',
    note: 'Onaylayacak kimse bağlı değil mi? Eylem reddedilir. İzinleri sunucun uygular, bir istem değil.',
    link: 'Eylem onaylarını yapılandır',
  },
  surfaces: {
    title: 'Masan bir yer.\nİşin değil.',
    description: 'Masaüstünde başla. Tarayıcıdan bak. Telefondan yakın dur. Tek sunucu işi bir arada tutar.',
    desktop: 'Yerel masaüstü', web: 'Tarayıcıda', phone: 'Telefon yoldaşı',
    note: 'Sunucun verinin ve yürütmenin sahibi. Aygıtların eşitlenmiş kalır.',
    link: 'Platformunu bul',
  },
  faq: {
    title: 'İyi sorular.', description: 'Yerleşmeden önce bilmen gereken birkaç şey.',
    items: [
      { question: 'Control Center yalnızca yapay zekâ ajanları için mi?', answer: 'Hayır. Control Center biletleri, pull request’leri, konuşmaları, toplantıları, takvimi, işlem hatlarını, ajanları ve kişisel bir RSS okuyucusunu tek çalışma alanında toplar. Ajanlar masanın bir parçasıdır, geri kalanı kullanmanın koşulu değildir.', links: [{ label: 'Özellikleri keşfet', href: '/tr-TR/#features' }] },
      { question: 'Bilet ile konuşma arasındaki fark nedir?', answer: 'Bilet işi ve durumunu kaydeder; yürütme bir konuşmada olur. Konuşma, bir ajan çalıştırmasından önce yalıtılmış bir copy-on-write worktree hazırlayabilir. Windows’ta bu hazırlık bir Git worktree kullanır.', links: [{ label: 'Örnek bir akışı izle', href: '/tr-TR/#workflows' }] },
      { question: 'Ajanlar nerede çalışır ve sunucu ne yapar?', answer: 'Sunucu çalışma alanının veritabanına, kimlik bilgilerine, API’lere ve ajan yürütmesine sahiptir; masaüstü ve tarayıcı istemcileri bu işi gösterir ve yönetir. İsteğe bağlı filo worker’ları kiralanmış işleri çeker ve olayları aktarır, ama veritabanını, kimlik bilgilerini ya da bütçeleri tutmaz.', links: [{ label: 'Mimari kılavuzunu oku', href: '/manual/concepts/architecture/' }] },
      { question: 'Bir ajan çalıştırması üzerinde ne kadar denetimim var?', answer: 'Her konuşma Yalnızca öner, Onayla hareket et ya da Serbest hareket et kullanabilir. İzinler ve bir sandbox izinli eylemleri sınırlamaya devam eder; onaylayacak kimse yoksa onay istekleri reddedilir. Yumuşak bütçe sınırları uyarır, sert olanlar duraklatır ve çalıştırmalar bir günlük tutar.', links: [{ label: 'Denetimleri gör', href: '/tr-TR/#boundaries' }] },
      { question: 'Bir Orchestrate planı ajanları kendiliğinden işe alır mı?', answer: 'Hayır. Orchestrate roller, alt biletler ve bir plan araştırıp önerebilir, ama işe alma onay bekler. Plan Studio, kaynak konuşmadaki plan satırından açılır; bir bileti atamak tek başına çalıştırma başlatmaz.', links: [{ label: 'Örnek akışı izle', href: '/tr-TR/#workflows' }] },
      { question: 'Eşleştirilmiş telefondan ajan çalıştırabilir miyim?', answer: 'Eşleştirilmiş telefon, aynı sunucu destekli çalışma alanının ince istemcisidir, ikinci bir yürütme makinesi değildir. Masaüstü, tarayıcı ve telefon aynı işi gösterir; ajanlar sunucuda ya da isteğe bağlı kiralanmış filo worker’larında çalışır.', links: [{ label: 'Bağlı yüzeyleri gör', href: '/tr-TR/#surfaces' }] },
      { question: 'Hangi bütünleştirmeleri kullanabilirim?', answer: 'Linear bilet eşitlemesi hazırdır; Jira ve ClickUp’ın bağdaştırıcısı yoktur. Bağlı Google Calendar etkinlikleri salt okunurdur, davete yanıt ise yalnızca takvim yazma izni verdiğinde vardır. Slack dizileri konuşmalara köprülenebilir ve bağlı forge’lar pull request’ler ile denetimler sağlar.', links: [{ label: 'Kılavuzu oku', href: '/manual/' }] },
      { question: 'Toplantı notları ve eylemler ne zaman görünür?', answer: 'Canlı döküm, kayıt sırasında konuşanları ayırabilir. Durdurduktan sonra özet ajanı toplantıyı işler ve notları, kararları ve eylemleri saklar; kayıt ve işleme ayrı durumlardır.', links: [{ label: 'Günü bağlamında gör', href: '/tr-TR/#day' }] },
      { question: 'Herkese açık demo gerçek bir çalışma alanı mı?', answer: 'Herkese açık demo, uydurma veriler ve bir senaryoyu izleyen ajanlarla ayrı, kilitli bir sürümdür. Kayıtları ve çalıştırmaları örnektir, senin işin değildir.', links: [{ label: 'Canlı demoyu incele', href: '/demo' }] },
    ],
  },
  pilot: {
      controls: '3B yamaç paraşütü. Görünümü döndürmek ve yön vermek için sürükle. Sol ve sağ oklar dönüş yapar; yukarı ve aşağı oklar uçuş açısını yukarı veya aşağı yatırır. R sıfırlar; Boşluk uçuşu ve rüzgârı duraklatır ya da sürdürür.',
    },
  install: {
    title: 'Kendini\nevinde hisset.', description: 'Sonraki geliştirici günün burada başlayabilir. Ücretsiz ve açık kaynak.',
    mac: 'Apple Silicon · macOS 13+', windows: 'x64 · Windows 10+', linux: 'x86_64 · AppImage',
    release: 'Sürümleri gör', web: 'Web uygulamasını aç', phone: 'Telefon yoldaşını aç',
    webNote: 'Kendin çalıştırdığın bir sunucuya bağlan.', phoneNote: 'Telefonu sunucunla mühürlü bir aktarıcı üzerinden eşleştir.',
    selfHost: 'Kendin barındırmayı mı yeğlersin?', server: 'Arayüzsüz bir sunucu çalıştır', guide: 'Hızlı başlangıç kılavuzunu oku',
  },
  footer: { tagline: 'Geliştirici günün için bir yer.', resources: 'Kaynaklar', source: 'GitHub’da kaynak', compare: 'Karşılaştır', changelog: 'Değişiklik günlüğü', about: 'Hakkında', contact: 'İletişim', privacy: 'Gizlilik', terms: 'Koşullar', licenses: 'Lisanslar', acknowledgements: 'Teşekkürler', made: 'Açıkta kuruldu.', top: 'Başa dön' },
};
