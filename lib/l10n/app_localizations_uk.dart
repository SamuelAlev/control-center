// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get succeeded => 'Успішно';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'Повтор #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'Запуск · $time';
  }

  @override
  String get agentActivityFollowingLive => 'Стеження за активністю наживо';

  @override
  String get agentActivityJumpToLatest => 'Перейти до останнього';

  @override
  String get agentActivityLoadFailed =>
      'Не вдалося завантажити активність цього запуску';

  @override
  String get agentActivityNotRecorded =>
      'Для цього запуску не записано активності';

  @override
  String get agentActivityNotRecordedHint =>
      'Запуски, що завершилися до ввімкнення запису активності, не мають шкали часу.';

  @override
  String get agentActivityRunUnavailable => 'Цей запуск більше недоступний';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'Субагент $agent';
  }

  @override
  String get agentActivityUnsupported =>
      'Запис активності недоступний на підключеному сервері';

  @override
  String get agentActivityUnsupportedHint =>
      'Перезапустіть застосунок, щоб підхопити останню збірку сервера.';

  @override
  String get agentActivityWaiting => 'Очікування активності…';

  @override
  String get created => 'Створено';

  @override
  String get dictationStart => 'Почати диктування';

  @override
  String get dictationListening => 'Слухаємо…';

  @override
  String get dictationUnavailable =>
      'Для диктування потрібна голосова модель на хості сервера. Налаштуйте її в параметрах голосу.';

  @override
  String get dictationFailedToStart => 'Не вдалося почати диктування';

  @override
  String get dictationHoldToTalkTitle => 'Утримуйте, щоб говорити';

  @override
  String get dictationHoldToTalkDescription =>
      'Утримуйте кнопку мікрофона або сполучення клавіш, щоб диктувати, і відпустіть, щоб зупинити. Коли вимкнено, натисніть один раз, щоб почати, і ще раз — щоб зупинити.';

  @override
  String get focusConversation => 'Фокус на розмові';

  @override
  String get ideAgentActivity => 'Активність агента';

  @override
  String get keybindingPushToTalk => 'Натисніть, щоб говорити';

  @override
  String get keybindingPushToTalkDescription =>
      'Утримуйте або перемикайте голосове диктування в полі повідомлення';

  @override
  String get agentPermissions => 'Дозволи агента';

  @override
  String get agentPermissionsSettingsDescription =>
      'Визначте, що агенти можуть робити самостійно, про що мають спершу запитати, а чого не можуть ніколи — для робочого простору, агента чи простору.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Задайте рішення для кожного типу дії. Правила каскадні: простір перевизначає агента, агент — робочий простір, робочий простір — пресет режиму. Перемагає найконкретніше правило.';

  @override
  String get guardrailLoading => 'Завантаження правил…';

  @override
  String get guardrailRulesLoadFailed =>
      'Не вдалося завантажити правила дозволів.';

  @override
  String get guardrailScopeWorkspace => 'Робочий простір';

  @override
  String get guardrailScopeAgent => 'Агент';

  @override
  String get guardrailScopeSpace => 'Простір';

  @override
  String get guardrailSelectAgent => 'Виберіть агента';

  @override
  String get guardrailSelectSpace => 'Виберіть простір';

  @override
  String get guardrailNoAgents => 'У цьому робочому просторі ще немає агентів.';

  @override
  String get guardrailNoSpaces =>
      'У цьому робочому просторі ще немає просторів.';

  @override
  String get guardrailClassFileDelete => 'Видалити файл';

  @override
  String get guardrailClassFileWriteOutsideWorktree =>
      'Запис поза робочим деревом';

  @override
  String get guardrailClassGitCommit => 'Створити коміт';

  @override
  String get guardrailClassGitPush => 'Надіслати на віддалений репозиторій';

  @override
  String get guardrailClassPrCreate => 'Відкрити pull request';

  @override
  String get guardrailClassPrPublish => 'Опублікувати рецензію або злити';

  @override
  String get guardrailClassVendorSyncWrite => 'Запис у зовнішній трекер';

  @override
  String get guardrailClassNetworkEgress => 'Доступ до мережі';

  @override
  String get guardrailClassSecretAccess => 'Читати секрет';

  @override
  String get guardrailClassPackageInstall => 'Установити пакет';

  @override
  String get guardrailClassProcessSpawn => 'Запустити процес';

  @override
  String get guardrailClassWorkspaceMutation =>
      'Змінити структуру робочого простору';

  @override
  String get guardrailClassEnclosureControl =>
      'Керувати ізольованим середовищем (rig)';

  @override
  String get navRigs => 'Rigs';

  @override
  String get rigsUnsupportedServer =>
      'Цей сервер не може розміщувати поверхні rig. Перевірте вимоги до хоста для комп’ютера, який ви хочете використовувати.';

  @override
  String get rigSurfaceComputer => 'Комп\'ютер';

  @override
  String get rigSurfaceBrowser => 'Браузер';

  @override
  String get rigSurfaceAndroid => 'Android';

  @override
  String get rigSurfaceIosSimulator => 'Симулятор iOS';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return 'Тимчасовий $engine, ізольований від вашої машини. Відкрийте інший рушій, щоб порівняти ту саму сторінку поруч.';
  }

  @override
  String get rigPhaseReady => 'Готово';

  @override
  String get rigPhaseStarting => 'Запуск';

  @override
  String get rigPhaseParked => 'Припарковано';

  @override
  String get rigPhaseClosing => 'Закриття';

  @override
  String get rigPhaseClosed => 'Закрито';

  @override
  String get rigPhaseFailed => 'Збій';

  @override
  String get rigPhaseUnknown => 'Невідомо';

  @override
  String get rigNotAccelerated => 'Емуляція';

  @override
  String get rigAudioListen => 'Слухати машину';

  @override
  String get rigAudioMute => 'Вимкнути звук машини';

  @override
  String get rigYouHaveControl => 'Керування у вас';

  @override
  String get rigBackendAvailable => 'Доступний';

  @override
  String get rigBackendUnavailable => 'Недоступний';

  @override
  String get rigEgressNotEnforced =>
      'Мережа на цьому бекенді не ізольована — він керує з’єднанням самостійно.';

  @override
  String get rigStartMachine => 'Запустити машину';

  @override
  String get rigStartHint =>
      'Запускає одноразову ВМ, яку ви з агентами спільно використовуєте в цій розмові. Її знищують після закриття, і нічого в ній не зачіпає ваш комп’ютер.';

  @override
  String get rigStartAndroidHint =>
      'Підключається до емулятора Android, який уже запущено на сервері. Доступ до мережі не ізольовано.';

  @override
  String get rigStartIosHint =>
      'Створює тимчасовий симулятор iOS на сервері macOS. Він видаляється після закриття тестового середовища; доступ до мережі не ізольовано.';

  @override
  String get rigTechnicalDetails => 'Технічні деталі';

  @override
  String get rigStopMachine => 'Зупинити машину';

  @override
  String get rigHomeButton => 'Додому';

  @override
  String get rigRotateClockwise => 'Повернути за годинниковою стрілкою';

  @override
  String get rigRotateCounterclockwise =>
      'Повернути проти годинникової стрілки';

  @override
  String get rigTakeScreenshot => 'Зробити знімок екрана';

  @override
  String get rigScreenshotSaved => 'Знімок екрана збережено';

  @override
  String rigScreenshotSaveFailed(String error) {
    return 'Не вдалося зберегти знімок екрана: $error';
  }

  @override
  String get rigSurfaceUnavailable =>
      'Цей сервер не може розмістити такий тип машини.';

  @override
  String get rigTabNeedsConversation =>
      'Спочатку відкрийте розмову — машина належить до неї, тож ви з агентами бачите той самий екран.';

  @override
  String get ideMenuSectionTools => 'Інструменти';

  @override
  String get ideMenuSectionMachines => 'Машини';

  @override
  String get ideMenuSectionReopen => 'Відкрити знову';

  @override
  String get ideMenuSearchHint => 'Пошук';

  @override
  String get ideMenuNoMatches => 'Немає збігів';

  @override
  String get rigMenuComputer => 'Комп’ютер';

  @override
  String get rigMenuBrowser => 'Браузер';

  @override
  String get rigMenuAndroid => 'Android';

  @override
  String get rigMenuIosSimulator => 'Симулятор iOS';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return 'Закрити $name?';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'Машина продовжує працювати у фоні — відкрийте її знову будь-коли з бічної панелі. Або вимкніть її зараз, щоб звільнити пам’ять.';

  @override
  String get ideCloseKeepBodyShell =>
      'Команда продовжує виконуватися у фоні — відкрийте оболонку знову будь-коли з бічної панелі. Або завершіть її зараз, щоб зупинити поточну роботу.';

  @override
  String get ideCloseKeepBodyAgent =>
      'Агент продовжує працювати у фоні — відкрийте розмову знову будь-коли з бічної панелі. Або зупиніть його зараз, щоб завершити запуск.';

  @override
  String get ideCloseKeepRunning => 'Залишити в роботі';

  @override
  String get ideCloseShutDownMachine => 'Вимкнути';

  @override
  String get ideCloseEndShell => 'Завершити оболонку';

  @override
  String get ideCloseStopAgent => 'Зупинити агента';

  @override
  String get rigsSettingsSubtitle =>
      'Що цей сервер може запускати, потрібні базові образи та машини, що зараз працюють';

  @override
  String get rigsCapabilitiesTitle => 'Цей сервер';

  @override
  String get rigInstallIosAutomation => 'Установити міст автоматизації iOS';

  @override
  String get rigInstallingIosAutomation =>
      'Установлення моста автоматизації iOS…';

  @override
  String get rigIosAutomationInstalled => 'Міст автоматизації iOS установлено';

  @override
  String get rigsImagesTitle => 'Базові образи';

  @override
  String get rigsImagesHint =>
      'Кожен rig завантажує один із цих образів лише для читання. Кожна сесія пише в одноразовий оверлей, тож один rig ніколи не змінює те, з чого стартує наступний.';

  @override
  String get rigsRunningTitle => 'Зараз працюють';

  @override
  String get rigsNoneRunning => 'Жодна машина не працює.';

  @override
  String get rigsCustomImagesTitle => 'Власні образи (цей робочий простір)';

  @override
  String get rigsCustomImagesHint =>
      'Вкажіть власний образ для Terminal (VM) або Browser (VM) — доповніть типові інструментами, потрібними проєкту, або візьміть будь-який сумісний із реєстру. Нові машини його використовують; уже запущені залишають свій. Див. посібник з rigs щодо вимог до образу.';

  @override
  String get rigsCustomTerminalImageLabel => 'Образ Terminal (VM)';

  @override
  String get rigsCustomBrowserImageLabel => 'Образ Browser (VM)';

  @override
  String get rigsCustomImagePlaceholder =>
      'напр. ghcr.io/acme/dev-shell:1.2 — залиште порожнім для типового';

  @override
  String get rigsCustomImageInvalid =>
      'Введіть посилання реєстру у форматі repo/name:tag. Локальні шляхи й архіви не дозволені.';

  @override
  String get rigsCustomImageSaved =>
      'Збережено. Нові машини завантажують цей образ; уже запущені залишають свій.';

  @override
  String get rigsEgressTitle => 'Вихід браузера (цей робочий простір)';

  @override
  String get rigsEgressHint =>
      'Додаткові хости, які може відкривати ізольований браузер — по одному в рядку: точний хост (api.example.com) або шаблон піддоменів (*.example.com). Сайт продукту дозволений у будь-якому разі. Нові машини отримують список; уже запущені зберігають той, з яким завантажились.';

  @override
  String rigsEgressInvalid(String host) {
    return '«$host» — некоректний запис хоста.';
  }

  @override
  String get rigsEgressSaved =>
      'Збережено. Нові браузерні машини допускають ці хости; уже запущені залишають свої.';

  @override
  String get rigImageInstalled => 'Установлено';

  @override
  String get rigImageNotDownloaded => 'Не завантажено';

  @override
  String get rigImageNotPublished => 'Не опубліковано';

  @override
  String get rigImageNotPublishedHint =>
      'Для цього ще немає опублікованого образу, тож завантажувати нічого. Імпортуйте сумісний образ диска, щоб увімкнути.';

  @override
  String get rigImageDownload => 'Завантажити';

  @override
  String get rigImageDownloading => 'Завантаження…';

  @override
  String get rigImageImport => 'Імпортувати';

  @override
  String get rigImageImportMessage =>
      'Шлях до образу диска qcow2 у файловій системі сервера. Його копіюють у сховище образів, тож файл можна перемістити пізніше.';

  @override
  String get rigConnectingStream => 'Підключення до rig';

  @override
  String get rigStreamNotAllowed => 'У вас немає доступу до цього rig.';

  @override
  String get rigStreamNotRunning => 'Цей rig уже не працює.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'Для живого перегляду на цьому хості потрібен ffmpeg. Встановіть ffmpeg і знову відкрийте вкладку.';

  @override
  String get rigStreamEnded => 'Живий перегляд завершено.';

  @override
  String get rigStreamFailed => 'Не вдалося відкрити живий перегляд.';

  @override
  String get rigStreamDisconnected => 'Немає з’єднання із сервером.';

  @override
  String rigDropSendingOne(String name) {
    return 'Копіювання «$name» у машину…';
  }

  @override
  String rigDropSendingMany(int count) {
    return 'Копіювання $count файлів у машину…';
  }

  @override
  String get rigTerminalDropSending => 'Копіювання у машину…';

  @override
  String get rigTerminalPasteImage => 'Вставлене зображення збережено в машині';

  @override
  String get rigPortsTitle => 'Переадресовані порти';

  @override
  String get rigPortsTooltip => 'Порти, відкриті всередині цієї машини';

  @override
  String get rigPortsEmpty =>
      'Поки нічого не слухає. Запустіть сервер у терміналі — dev-сервер на порту 3000 з’явиться тут.';

  @override
  String get rigPortsAdd => 'Додати порт';

  @override
  String get rigPortsAddHint => 'Гостьовий порт для переадресації (напр. 3000)';

  @override
  String get rigPortsAutoForward => 'Автопереадресація портів';

  @override
  String get rigPortsCopyUrl => 'Копіювати локальний URL';

  @override
  String rigPortsCopiedUrl(String url) {
    return 'Скопійовано $url';
  }

  @override
  String get rigPortsStopForward => 'Зупинити переадресацію';

  @override
  String get rigPortsExposeLan => 'Поділитися в локальній мережі';

  @override
  String get rigPortsLanPrivate => 'Лише локально';

  @override
  String get rigPortsLanShared => 'У мережі';

  @override
  String get rigPortsSetDomain => 'Задати домен браузера (.test)';

  @override
  String get rigPortsDomainHint =>
      'Домен для браузера (VM), напр. myapp.test — доступний там, не на хості';

  @override
  String get rigPortsProcessUnknown => 'невідомий процес';

  @override
  String get rigPortsInactive => 'не слухає';

  @override
  String get rigPortsTooltipHost => 'Порти, відкриті в цьому терміналі';

  @override
  String get rigPortsEmptyHost =>
      'У цьому терміналі ще ніхто не слухає. Запустіть сервер — він з’явиться тут.';

  @override
  String get rigPortsAddHintHost => 'Порт для зіставлення (напр. 5173)';

  @override
  String get rigPortsLocalPortHint => 'Локальний порт (необов’язково)';

  @override
  String rigPortsDestDesktop(int port) {
    return 'localhost:$port';
  }

  @override
  String rigPortsDestBrowser(int port) {
    return 'localhost:$port у браузері (ВМ)';
  }

  @override
  String get rigPortsDestBrowserUnreachable => 'браузер (ВМ) не підключено';

  @override
  String rigPortsDestAndroid(int port) {
    return 'localhost:$port на Android';
  }

  @override
  String get rigPortsDestAndroidUnreachable => 'Android не підключено';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count базових образів ще потрібно завантажити',
      many: '$count базових образів ще потрібно завантажити',
      few: '$count базові образи ще потрібно завантажити',
      one: '$count базовий образ ще потрібно завантажити',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'Дозволити';

  @override
  String get guardrailDecisionPrompt => 'Спочатку запитати';

  @override
  String get guardrailDecisionDeny => 'Заборонити';

  @override
  String get guardrailSourceThisScope => 'Ця область';

  @override
  String get guardrailSourceDefault => 'Вбудований стандарт';

  @override
  String get guardrailSourcePreset => 'Пресет режиму';

  @override
  String get guardrailSourceInherited => 'Успадковано';

  @override
  String get guardrailClearToInherited => 'Скинути до успадкованого';

  @override
  String get guardrailWhatIf => 'Що якщо?';

  @override
  String get guardrailWhatIfDescription =>
      'Перегляньте, як поточні правила розв’яжуть дію — тією ж логікою, яку застосовують агенти.';

  @override
  String get guardrailProbeActionLabel => 'Дія';

  @override
  String get guardrailProbeCommandLabel => 'Команда (необов’язково)';

  @override
  String get guardrailProbeCommandHint => 'напр. git push origin main';

  @override
  String get guardrailProbeAgentLabel => 'Агент (необов’язково)';

  @override
  String get guardrailProbeSpaceLabel => 'Простір (необов’язково)';

  @override
  String get guardrailProbeNone => 'Немає';

  @override
  String get guardrailProbeModeLabel => 'Режим';

  @override
  String get guardrailProbeResult => 'Результат';

  @override
  String get guardrailProbeSource => 'Джерело:';

  @override
  String get guardrailAdapterMatrix => 'Де застосовуються правила';

  @override
  String get guardrailAdapterMatrixDescription =>
      'Чесна довідка: де кожен ефект насправді перехоплюється, для кожного раннера агента. Це опис реальності, а не гарантія — ефекти, які раннер виконує в обхід, перехопити не можна.';

  @override
  String get guardrailEffectColumn => 'Ефект';

  @override
  String get guardrailAdapterHarness => 'Вбудований harness';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'Базовий рівень пісочниці';

  @override
  String get guardrailEnforcementPolicyGate => 'Шлюз політики';

  @override
  String get guardrailEnforcementSandbox => 'Лише пісочниця';

  @override
  String get guardrailEnforcementNone => 'Не забезпечується';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'Рішення про дозвіл перевіряється до виконання ефекту і може його заблокувати.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'Обмежує лише пісочниця; правило дозволу не враховується.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'Рішення лише довідкове — тут його не можна перехопити.';

  @override
  String get obsStatCost => 'вартість';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount делеговано';
  }

  @override
  String get obsStatDuration => 'тривалість';

  @override
  String get obsStatTokens => 'токени';

  @override
  String get obsStatTools => 'інструменти';

  @override
  String get openAgentActivity => 'Відкрити активність';

  @override
  String get orgChart => 'Оргструктура';

  @override
  String get orgChartEmpty => 'Ще немає агентів';

  @override
  String get navCalendar => 'Календар';

  @override
  String get serverConnection => 'Підключення до сервера';

  @override
  String get serverModeLocal => 'Запускати в цьому застосунку';

  @override
  String get serverModeLocalDescription =>
      'Control Center запускає власний сервер на цьому комп\'ютері й зберігає ваші дані локально.';

  @override
  String get serverModeRemote => 'Підключитися до віддаленого екземпляра';

  @override
  String get serverModeRemoteDescription =>
      'Підключіться до сервера Control Center, який працює в іншому місці. Ваші дані зберігаються на тому сервері.';

  @override
  String get serverRemoteUrl => 'URL сервера';

  @override
  String get serverRemoteDeviceId => 'Ідентифікатор пристрою';

  @override
  String get serverRemotePairingKey => 'Ключ спарювання';

  @override
  String get serverRemotePairingKeyHint =>
      'Вставте ключ спарювання з віддаленого сервера';

  @override
  String get serverSetupInviteCode => 'Код запрошення';

  @override
  String get serverSetupInviteCodeHint =>
      'Вставте одноразовий код запрошення (залиште порожнім, щоб використати ключ спарювання)';

  @override
  String get serverDiscoveryTooltip => 'Знайти сервери у вашій мережі';

  @override
  String get serverDiscoveryTitle => 'Сервери у вашій мережі';

  @override
  String get serverDiscoverySearching => 'Пошук серверів…';

  @override
  String get serverDiscoveryEmpty =>
      'Серверів не знайдено. Переконайтеся, що сервер запущено і цей пристрій може до нього з\'єднатися, потім повторіть пошук.';

  @override
  String get serverDiscoveryRefresh => 'Шукати знову';

  @override
  String get serverListActive => 'Активний';

  @override
  String get serverListSwitch => 'Перемкнути';

  @override
  String get serverListAddTitle => 'Додати сервер';

  @override
  String get serverListRemoveActiveHint =>
      'Перемкніться на інший сервер, перш ніж видалити цей.';

  @override
  String get serverSwitchFailedTitle => 'Не вдалося перемкнути сервер';

  @override
  String get serverListInsecureBadge => 'Незахищений';

  @override
  String get connectionPathLocal => 'Локальний';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'Завершення роботи';

  @override
  String get shutdownSubtitle => 'Закриття локального сервера';

  @override
  String get shutdownServiceApprovals => 'Схвалення';

  @override
  String get shutdownServiceBackgroundJobs => 'Фонові завдання';

  @override
  String get shutdownServiceScheduler => 'Планувальник завдань';

  @override
  String get shutdownServiceCalendar => 'Синхронізація календаря';

  @override
  String get shutdownServiceWeather => 'Погода';

  @override
  String get shutdownServiceSoundscape => 'Звуковий ландшафт';

  @override
  String get shutdownServiceMeetings => 'Зустрічі';

  @override
  String get shutdownServiceVoiceModels => 'Голосові моделі';

  @override
  String get shutdownServiceNetworking => 'Мережа';

  @override
  String get shutdownServicePresence => 'Присутність';

  @override
  String get shutdownServiceDataSync => 'Синхронізація даних';

  @override
  String get shutdownServiceDeviceRelay => 'Ретрансляція пристрою';

  @override
  String get shutdownServiceMcpConnections => 'Підключення MCP';

  @override
  String get shutdownServiceCodeEditors => 'Редактори коду';

  @override
  String get serverSharingTitle => 'Надати доступ до цього сервера';

  @override
  String get serverSharingDescription =>
      'Зробіть цей сервер доступним з інших ваших пристроїв. Нічого не відкривається публічно, доки ви не ввімкнете тунель нижче. Запрошення на спарювання автоматично містять поточні адреси сервера — створюйте їх у налаштуваннях робочого простору.';

  @override
  String get serverSharingUnavailable =>
      'Елементи керування спільним доступом недоступні на цьому сервері.';

  @override
  String get serverSharingMdnsLabel => 'Виявлення в LAN';

  @override
  String get serverSharingMdnsOn =>
      'Сервер оголошується в локальній мережі (mDNS)';

  @override
  String get serverSharingMdnsOff =>
      'Не оголошується в локальній мережі (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'Тунель';

  @override
  String get serverSharingTunnelHelper =>
      'Увімкнення тунелю робить цей сервер доступним з інтернету. Публічний доступ потрібно вмикати окремо — за замовчуванням він вимкнений.';

  @override
  String get serverSharingProviderOff => 'Вимкнено';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'Публічний URL';

  @override
  String get serverSharingTunnelStarting => 'Запуск тунелю…';

  @override
  String serverSharingTunnelError(String error) {
    return 'Помилка тунелю: $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'Тунель працює. Доступний за налаштованим DNS-іменем.';

  @override
  String get serverSharingRelayLabel => 'Релей';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'Ретрансльовано цього місяця: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'Активні сесії релею: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle =>
      'Не вдалося оновити спільний доступ';

  @override
  String get pairNewClient => 'Спарувати новий клієнт';

  @override
  String get pairClientNameHint =>
      'Назва цього клієнта (наприклад, Робочий ноутбук)';

  @override
  String get pairClientTypeWeb => 'Веббраузер';

  @override
  String get pairClientTypeDesktop => 'Настільна програма';

  @override
  String get pairClientTypePhone => 'Телефон';

  @override
  String get pairAction => 'Спарувати';

  @override
  String get revoke => 'Відкликати';

  @override
  String get pairCredentialsIntro =>
      'Підключіть новий клієнт цими даними або відкрийте посилання в ньому.';

  @override
  String get pairLinkLabel => 'Посилання';

  @override
  String get pairScanQr =>
      'Відскануйте цей QR-код камерою телефону, щоб спарувати його.';

  @override
  String get pairServerUnreachableTitle => 'Недоступний';

  @override
  String get pairServerUnreachable =>
      'Інші пристрої не можуть з’єднатися з цим сервером напряму, тож новий клієнт не підключиться. Вкажіть публічну URL-адресу сервера, щоб спарувати більше клієнтів.';

  @override
  String get serverSetupTitle => 'Як має працювати Control Center?';

  @override
  String get serverSetupSubtitle =>
      'Control Center потрібен сервер, який зберігає ваші дані. Запустіть його в цій програмі або підключіться до екземпляра, що працює деінде.';

  @override
  String get serverSetupRunLocal => 'Запустити в цій програмі';

  @override
  String get serverSetupConnect => 'Підключитись';

  @override
  String get serverSetupInvalidUrl =>
      'Введіть коректну URL-адресу сервера (ws:// або wss://).';

  @override
  String get serverSetupCouldNotConnect => 'Не вдалося підключитись';

  @override
  String get serverSetupErrorUnreachable =>
      'Не вдалося зв’язатися із сервером. Перевірте, що він запущений і що цей пристрій може до нього достукатись (та сама мережа або релей).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'Ідентичність сервера не збігається зі збереженою на цьому пристрої. Якщо сервер перевстановили або скинули, видаліть збережений сервер і спаруйте знову.';

  @override
  String get serverSetupErrorAuthRejected =>
      'Сервер відхилив цей пристрій. Перевірте, що ключ парування та ідентифікатор пристрою збігаються з виданими сервером.';

  @override
  String get serverSetupErrorInviteRejected =>
      'Цей код запрошення недійсний або прострочений. Попросіть новий.';

  @override
  String get serverSetupErrorGeneric =>
      'Під час підключення сталася помилка. Розгорніть технічні деталі нижче, щоб дізнатися більше.';

  @override
  String get serverSetupErrorDetails => 'Технічні деталі';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ще $count',
      many: 'ще $count',
      few: 'ще $count',
      one: 'ще $count',
    );
    return '$_temp0';
  }

  @override
  String get calendarAllDayGutter => 'На весь день';

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count події',
      many: '$count подій',
      few: '$count події',
      one: '$count подія',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => 'Згорнути події на весь день';

  @override
  String get calendarExpandAllDay => 'Розгорнути події на весь день';

  @override
  String get calendarViewMonth => 'Місяць';

  @override
  String get calendarViewWeek => 'Тиждень';

  @override
  String get calendarViewAgenda => 'Розклад';

  @override
  String get calendarConnectGoogle => 'Підключити Google Calendar';

  @override
  String get calendarConnectDescription =>
      'Синхронізуйте Google Calendar, щоб бачити події тут і отримувати сповіщення перед зустрічами.';

  @override
  String get calendarDisconnect => 'Відключити';

  @override
  String get calendarReconnect => 'Підключити знову';

  @override
  String get calendarEmptyNoEvents => 'У цьому діапазоні немає подій';

  @override
  String get calendarStartRecording => 'Почати запис';

  @override
  String get calendarStartRecordingAndLink => 'Почати запис і прив’язати';

  @override
  String get calendarJoinMeet => 'Приєднатися до зустрічі';

  @override
  String get calendarFromCalendar => 'З календаря';

  @override
  String get calendarLinkedMeeting => 'Прив’язана зустріч';

  @override
  String get calendarToday => 'Сьогодні';

  @override
  String get calendarAllDay => 'Увесь день';

  @override
  String calendarWeekNumber(int number) {
    return 'Тиждень $number';
  }

  @override
  String get calendarPreviousPeriod => 'Назад';

  @override
  String get calendarNextPeriod => 'Далі';

  @override
  String calendarLastSynced(String time) {
    return 'Синхронізовано $time';
  }

  @override
  String get calendarNeverSynced => 'Ще не синхронізовано';

  @override
  String get calendarSyncing => 'Синхронізація…';

  @override
  String get calendarViewDay => 'День';

  @override
  String get calendarShow => 'Показати';

  @override
  String get calendarHide => 'Сховати';

  @override
  String get calendarRsvpGoing => 'Підете?';

  @override
  String get calendarRsvpYes => 'Так';

  @override
  String get calendarRsvpNo => 'Ні';

  @override
  String get calendarRsvpMaybe => 'Можливо';

  @override
  String get calendarRsvpFailed => 'Не вдалося оновити відповідь';

  @override
  String get calendarAddAccount => 'Додати обліковий запис календаря';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Підключіть обліковий запис Google, щоб синхронізувати події в цей простір. Ці календарі тут ваші.';

  @override
  String get calendarConnecting => 'Підключення…';

  @override
  String get calendarSyncNow => 'Синхронізувати зараз';

  @override
  String get calendarNoWorkspace =>
      'Виберіть робочий простір, щоб переглянути його календар';

  @override
  String get calendarConnectError => 'Не вдалося підключити Google Calendar';

  @override
  String get calendarClientIdLabel => 'Ідентифікатор клієнта';

  @override
  String get calendarClientSecretLabel => 'Секрет клієнта';

  @override
  String get calendarConnectCredsHint =>
      'Введіть ідентифікатор і секрет клієнта Google OAuth device-code для вашого проєкту. Підключення й синхронізацію виконує сервер — браузер ніколи не зберігає токени.';

  @override
  String get calendarConnectApproveInstruction =>
      'Відкрийте сторінку підтвердження на будь-якому пристрої, увійдіть і введіть цей код:';

  @override
  String get calendarConnectOpenPage => 'Відкрити сторінку підтвердження';

  @override
  String get calendarConnectWaiting => 'Очікування підтвердження…';

  @override
  String get calendarConnectDenied =>
      'Авторизацію відхилено. Спробуйте ще раз.';

  @override
  String get calendarConnectExpired => 'Код застарів. Спробуйте ще раз.';

  @override
  String get notificationMeetingStartsSoon => 'Зустріч незабаром почнеться';

  @override
  String get notifyMeetingStartsSoon =>
      'Коли зустріч у календарі ось-ось почнеться';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Календар відключено';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Підключіть $email знову, щоб відновити синхронізацію';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Підключіть календар знову, щоб відновити синхронізацію';

  @override
  String get notifyCalendarAuthExpired =>
      'Коли обліковий запис календаря потрібно підключити знову';

  @override
  String get notificationRigStatusChanged => 'Оновлення середовища';

  @override
  String get notifyRigStatusChanged =>
      'Коли середовище перехоплюють, вилучають або стається збій';

  @override
  String get notificationRigTakenOver => 'Середовище перехоплено';

  @override
  String get notificationRigTakenOverBody =>
      'Машиною керує людина; агент може лише спостерігати.';

  @override
  String get notificationRigReleased => 'Керування середовищем звільнено';

  @override
  String get notificationRigReleasedBody => 'Агент знову має машину.';

  @override
  String get notificationRigReclaimed => 'Середовище вилучено';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'Воно простоювало, тож машину закрито, щоб звільнити пам’ять.';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'Досягнуто ліміту часу, тож його закрито.';

  @override
  String get notificationRigFailed => 'Збій середовища';

  @override
  String get notificationRigFailedBody =>
      'Гіпервізор зупинився. Відкрийте машину знову, щоб продовжити.';

  @override
  String get calendarAlertLeadTime => 'Час попередження';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'За скільки до зустрічі сповіщати';

  @override
  String calendarConnectedAs(String email) {
    return 'Підключено як $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count attendees';
  }

  @override
  String get calendarEventLabel => 'Подія';

  @override
  String get calendarRecurring => 'Повторювана подія';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Організатор';

  @override
  String get calendarYou => 'Ви';

  @override
  String get calendarShowFewer => 'Показати менше';

  @override
  String get calendarRsvpAwaiting => 'Очікується';

  @override
  String calendarParticipantsCount(int count) {
    return '$count participants';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'See all $count participants';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count yes';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count no';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count maybe';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count awaiting';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count minutes';
  }

  @override
  String get openInEditorPrompt => 'У якому редакторі відкрити?';

  @override
  String get ideNotInstalled => 'Не встановлено';

  @override
  String openInIde(String editor) {
    return 'Відкрити в $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'Не вдалося відкрити $editor: $error';
  }

  @override
  String get profileSearchHint => 'Пошук pull requests…';

  @override
  String get stopAgentRun => 'Зупинити запуск';

  @override
  String get stopAgentRunConfirm =>
      'Зупинити цей запуск? Незавершену роботу буде втрачено.';

  @override
  String get inProgress => 'У процесі';

  @override
  String get drafts => 'Чернетки';

  @override
  String get sortOldest => 'Найстаріші';

  @override
  String get sortLargest => 'Найбільші';

  @override
  String get prFilterTooltip => 'Фільтр';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count активних фільтрів',
      many: '$count активних фільтрів',
      few: '$count активні фільтри',
      one: '$count активний фільтр',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'Додати фільтр…';

  @override
  String get prFilterFieldHint => 'Фільтр…';

  @override
  String get prFilterCategoryStatus => 'Статус';

  @override
  String get prFilterCategoryAuthor => 'Автор';

  @override
  String get prFilterCategoryReviewer => 'Рецензенти';

  @override
  String get prFilterCategoryContent => 'Вміст';

  @override
  String get prFilterCategoryRepoOwner => 'Власник репозиторію';

  @override
  String get prFilterCategoryRepoName => 'Назва репозиторію';

  @override
  String get prFilterCategoryOpenedDate => 'Дата відкриття';

  @override
  String get prFilterCategoryUpdatedDate => 'Дата оновлення';

  @override
  String get prFilterQuickToReview => 'Швидка рецензія';

  @override
  String get prFilterClearAll => 'Очистити фільтри';

  @override
  String prFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request',
      many: '$count pull request',
      few: '$count pull request',
      one: '$count pull request',
    );
    return '$_temp0';
  }

  @override
  String prFilterHiddenOptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count варіантів не відповідають жодному pull request',
      many: '$count варіантів не відповідають жодному pull request',
      few: '$count варіанти не відповідають жодному pull request',
      one: '$count варіант не відповідає жодному pull request',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'Заголовок або вміст містить…';

  @override
  String get prFilterNoOptions => 'Немає відповідних варіантів';

  @override
  String get prFilterChipIs => 'є';

  @override
  String get prFilterChipIsAnyOf => 'є будь-яким із';

  @override
  String get prFilterChipContains => 'містить';

  @override
  String get prFilterChipSince => 'від';

  @override
  String get prFilterAddFilterButton => 'Додати фільтр';

  @override
  String prFilterClearCategory(String category) {
    return 'Очистити фільтр $category';
  }

  @override
  String get prFilterCurrentUser => 'Поточний користувач';

  @override
  String get prStatusDraft => 'Чернетка';

  @override
  String get prStatusOpen => 'Відкритий';

  @override
  String get prStatusInReview => 'На рецензії';

  @override
  String get prStatusChangesRequested => 'Запитано зміни';

  @override
  String get prStatusApproved => 'Схвалено';

  @override
  String get prStatusMerged => 'Злито';

  @override
  String get prStatusClosed => 'Закрито';

  @override
  String get prDateWindowDay => '1 день тому';

  @override
  String get prDateWindowThreeDays => '3 дні тому';

  @override
  String get prDateWindowWeek => '1 тиждень тому';

  @override
  String get prDateWindowMonth => '1 місяць тому';

  @override
  String get prDateWindowThreeMonths => '3 місяці тому';

  @override
  String get prDateWindowSixMonths => '6 місяців тому';

  @override
  String get prDateWindowYear => '1 рік тому';

  @override
  String get prDisplayOptions => 'Параметри відображення';

  @override
  String get prDisplayGrouping => 'Групування';

  @override
  String get prDisplayOrdering => 'Сортування';

  @override
  String get prDisplayShowDrafts => 'Показувати чернетки';

  @override
  String get prDisplayMergedWindow => 'Період злиття';

  @override
  String get prDisplayMergedWindowDay => 'Минулий день';

  @override
  String get prDisplayMergedWindowWeek => 'Минулий тиждень';

  @override
  String get prDisplayMergedWindowMonth => 'Минулий місяць';

  @override
  String get prDisplayProperties => 'Відображувані властивості';

  @override
  String get prGroupingRepository => 'Репозиторій';

  @override
  String get prGroupingAuthor => 'Автор';

  @override
  String get prGroupingStatus => 'Статус';

  @override
  String get prGroupingNone => 'Без групування';

  @override
  String get prPropertyRepository => 'Репозиторій';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'Гілка';

  @override
  String get prPropertyUpdated => 'Оновлено';

  @override
  String get prPropertyAuthor => 'Автор';

  @override
  String get prPropertyChecks => 'Перевірки';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'Коментарі';

  @override
  String get keybindingOpenFilterMenu => 'Відкрити меню фільтра';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'Відкрити меню фільтра pull request';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count вибрано',
      many: '$count вибрано',
      few: '$count вибрано',
      one: '$count вибрано',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'Зведення';

  @override
  String get kbMove => 'перемістити';

  @override
  String get kbTabs => 'вкладки';

  @override
  String get kbSearch => 'пошук';

  @override
  String get kbViewed => 'переглянуто';

  @override
  String get kbCollapse => 'згорнути';

  @override
  String get appearance => 'Вигляд';

  @override
  String get appearanceSettingsDescription => 'Тема, мова та типографіка.';

  @override
  String get notificationsSettingsDescription =>
      'Оберіть, про які події агентів і робочих просторів вас сповіщати.';

  @override
  String get advanced => 'Додатково';

  @override
  String get accounts => 'Облікові записи';

  @override
  String get mcpServers => 'MCP-сервери';

  @override
  String get mcpServersSettingsDescription =>
      'Вбудований MCP-сервер і зовнішні MCP-сервери.';

  @override
  String get remoteControlAndDevices => 'Віддалене керування та пристрої';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'Прив’яжіть телефони та налаштуйте сервер віддаленого керування.';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'Моделі розпізнавання мовлення та діаризації, які хостить цей сервер.';

  @override
  String get needsSetupLabel => 'Потрібне налаштування';

  @override
  String get collapseSidebar => 'Згорнути бічну панель';

  @override
  String get expandSidebar => 'Розгорнути бічну панель';

  @override
  String get filterSpacesHint => 'Фільтрувати простори';

  @override
  String noSpacesMatch(String query) {
    return 'Немає просторів за запитом «$query»';
  }

  @override
  String get privacy => 'Приватність';

  @override
  String get sendDiffContentTitle => 'Надсилати вміст diff адаптеру ШІ';

  @override
  String get diffSharingOnSubtitle =>
      'Необроблені рядки diff додаються в підказки агента для глибшого перегляду.';

  @override
  String get diffSharingOffSubtitle =>
      'Агенти використовують лише структуровані метадані (шляхи до файлів, номери рядків, опис PR); необроблений код не залишає програму.';

  @override
  String get errorReportingTitle => 'Надсилати звіти про збої';

  @override
  String get errorReportingOnSubtitle =>
      'Діагностика збоїв, помилок і швидкодії надсилається, щоб допомагати виправляти вади (лише релізні збірки).';

  @override
  String get errorReportingOffSubtitle =>
      'Діагностику вимкнено. Звіти про збої та помилки не надсилаються.';

  @override
  String get onboardingDiagnosticsTitle =>
      'Допоможіть покращити Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Надсилайте діагностику збоїв, помилок і швидкодії, щоб ми швидше виправляли проблеми (лише релізні збірки). Це можна змінити будь-коли в Налаштування → Приватність.';

  @override
  String get blocked => 'Заблоковано';

  @override
  String get idle => 'Неактивний';

  @override
  String get noRunsYet => 'Запусків ще немає';

  @override
  String get copyPath => 'Копіювати шлях';

  @override
  String get copyRelativePath => 'Копіювати відносний шлях';

  @override
  String get nameRequired => 'Потрібна назва';

  @override
  String get import => 'Імпортувати';

  @override
  String get noMatchingAgents => 'Немає агентів, які відповідають фільтру';

  @override
  String watchVideoOn(String provider) {
    return 'Дивитися відео на $provider';
  }

  @override
  String get branchTemplate => 'Шаблон назви гілки';

  @override
  String get branchTemplateDescription =>
      'Шаблон гілки, яку створюють, коли тікет запускають в ізольованому робочому дереві.';

  @override
  String branchTemplatePreview(String example) {
    return 'Приклад: $example';
  }

  @override
  String get deletePipelineRun => 'Видалити запуск конвеєра';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Видалити цей запуск «$template»? Цю дію не можна скасувати.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Помилка видалення запуску конвеєра: $error';
  }

  @override
  String get deleteTicket => 'Видалити тікет';

  @override
  String deleteTicketConfirm(String title) {
    return 'Видалити «$title»? Цю дію не можна скасувати.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Помилка видалення тікета: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return 'Видалити «$name»? Пов’язані репозиторії на диску не змінюються.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Помилка видалення робочого простору: $error';
  }

  @override
  String get indexCode => 'Індексувати код';

  @override
  String get indexNoGrammars => 'Граматики коду не встановлено';

  @override
  String get indexFailed => 'Індексування не вдалося';

  @override
  String indexedSymbolsCount(int count) {
    return '$count символів проіндексовано';
  }

  @override
  String get nodeConfigAdvanced => 'Додатково';

  @override
  String get nodeConfigReducer => 'Редюсер';

  @override
  String get nodeConfigReducerHelp =>
      'Як об’єднувати, якщо цей ключ виводу вже має значення';

  @override
  String get nodeConfigTimeoutMs => 'Таймаут (мс)';

  @override
  String get nodeConfigRetryAttempts => 'Спроби повтору';

  @override
  String get nodeConfigContinueOnFail => 'Продовжити, якщо цей крок не вдався';

  @override
  String get nodeConfigTeamId => 'ID команди';

  @override
  String get nodeConfigDispatchMode => 'Режим диспетчеризації';

  @override
  String get nodeConfigOutputSchema => 'Схема виводу (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'JSON Schema, якій має відповідати вивід кроку';

  @override
  String get diffLineDisplay => 'Довгі рядки в diff';

  @override
  String get diffLineDisplayDescription =>
      'Переносити довгі рядки або прокручувати їх горизонтально';

  @override
  String get diffLineWrap => 'Переносити';

  @override
  String get diffLineScroll => 'Прокручувати горизонтально';

  @override
  String get actions => 'Дії';

  @override
  String get activate => 'Активувати';

  @override
  String get activity => 'Активність';

  @override
  String get activityLabel => 'АКТИВНІСТЬ';

  @override
  String get activitySearchHint => 'Пошук активності';

  @override
  String get activityNoMatches => 'Немає активності за вашими фільтрами';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end з $total';
  }

  @override
  String get activityPreviousPage => 'Попередня сторінка';

  @override
  String get activityNextPage => 'Наступна сторінка';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'Скинути фільтр';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return 'Країна $country';
  }

  @override
  String get activitySavedWorkspaceLogo =>
      'Збережено логотип робочого простору';

  @override
  String activityVerbCreated(String target) {
    return 'Створено $target';
  }

  @override
  String activityVerbUpdated(String target) {
    return 'Оновлено $target';
  }

  @override
  String activityVerbDeleted(String target) {
    return 'Видалено $target';
  }

  @override
  String activityVerbAdded(String target) {
    return 'Додано $target';
  }

  @override
  String activityVerbRemoved(String target) {
    return 'Вилучено $target';
  }

  @override
  String activityVerbInvited(String target) {
    return 'Запрошено $target';
  }

  @override
  String activityVerbChanged(String target) {
    return 'Змінено $target';
  }

  @override
  String activityVerbStarted(String target) {
    return 'Запущено $target';
  }

  @override
  String activityVerbStopped(String target) {
    return 'Зупинено $target';
  }

  @override
  String activityVerbWrote(String target) {
    return 'Написано $target';
  }

  @override
  String get activityTargetAgent => 'агента';

  @override
  String get activityTargetTicket => 'тікет';

  @override
  String get activityTargetWorkspace => 'робочий простір';

  @override
  String get activityTargetRepository => 'репозиторій';

  @override
  String get activityTargetMember => 'учасника';

  @override
  String get activityTargetInvite => 'запрошення';

  @override
  String get activityTargetSpace => 'простір';

  @override
  String get activityTargetMessage => 'повідомлення';

  @override
  String get activityTargetCache => 'кеш';

  @override
  String get activityTargetFile => 'файл';

  @override
  String get activityTargetPipeline => 'конвеєр';

  @override
  String get activityTargetTemplate => 'шаблон';

  @override
  String get activityTargetProvider => 'провайдера';

  @override
  String get activityTargetModel => 'модель';

  @override
  String get activityTargetSkill => 'навичка';

  @override
  String get activityTargetTodo => 'завдання';

  @override
  String get activityTargetMeeting => 'зустріч';

  @override
  String get activityTargetProject => 'проєкт';

  @override
  String get activityTargetTeam => 'команда';

  @override
  String get activityTargetDevice => 'пристрій';

  @override
  String get activityTargetPreference => 'налаштування';

  @override
  String get activityTargetBudget => 'бюджет';

  @override
  String activityVerbApproved(String target) {
    return 'Схвалено $target';
  }

  @override
  String activityVerbArchived(String target) {
    return 'Архівовано $target';
  }

  @override
  String activityVerbAssigned(String target) {
    return 'Призначено $target';
  }

  @override
  String activityVerbBackedUp(String target) {
    return 'Зроблено резервну копію $target';
  }

  @override
  String activityVerbCancelled(String target) {
    return 'Скасовано $target';
  }

  @override
  String activityVerbCleared(String target) {
    return 'Очищено $target';
  }

  @override
  String activityVerbClosed(String target) {
    return 'Закрито $target';
  }

  @override
  String activityVerbCommitted(String target) {
    return 'Закомічено $target';
  }

  @override
  String activityVerbCompacted(String target) {
    return 'Ущільнено $target';
  }

  @override
  String activityVerbCompleted(String target) {
    return 'Завершено $target';
  }

  @override
  String activityVerbConnected(String target) {
    return 'Підключено $target';
  }

  @override
  String activityVerbContinued(String target) {
    return 'Продовжено $target';
  }

  @override
  String activityVerbDisconnected(String target) {
    return 'Відключено $target';
  }

  @override
  String activityVerbDispatched(String target) {
    return 'Відправлено $target';
  }

  @override
  String activityVerbDrained(String target) {
    return 'Спустошено $target';
  }

  @override
  String activityVerbEnrolled(String target) {
    return 'Зараховано $target';
  }

  @override
  String activityVerbEstimated(String target) {
    return 'Оцінено $target';
  }

  @override
  String activityVerbImported(String target) {
    return 'Імпортовано $target';
  }

  @override
  String activityVerbInstalled(String target) {
    return 'Встановлено $target';
  }

  @override
  String activityVerbKilled(String target) {
    return 'Примусово зупинено $target';
  }

  @override
  String activityVerbMarked(String target) {
    return 'Позначено $target';
  }

  @override
  String activityVerbMerged(String target) {
    return 'Злито $target';
  }

  @override
  String activityVerbOpened(String target) {
    return 'Відкрито $target';
  }

  @override
  String activityVerbPaused(String target) {
    return 'Призупинено $target';
  }

  @override
  String activityVerbPolled(String target) {
    return 'Опитано $target';
  }

  @override
  String activityVerbPrepared(String target) {
    return 'Підготовлено $target';
  }

  @override
  String activityVerbProcessed(String target) {
    return 'Оброблено $target';
  }

  @override
  String activityVerbPublished(String target) {
    return 'Опубліковано $target';
  }

  @override
  String activityVerbRefined(String target) {
    return 'Доопрацьовано $target';
  }

  @override
  String activityVerbRefreshed(String target) {
    return 'Оновлено $target';
  }

  @override
  String activityVerbRegistered(String target) {
    return 'Зареєстровано $target';
  }

  @override
  String activityVerbRenamed(String target) {
    return 'Перейменовано $target';
  }

  @override
  String activityVerbReordered(String target) {
    return 'Змінено порядок $target';
  }

  @override
  String activityVerbResponded(String target) {
    return 'Відповіли на $target';
  }

  @override
  String activityVerbRestored(String target) {
    return 'Відновлено $target';
  }

  @override
  String activityVerbResumed(String target) {
    return 'Поновлено $target';
  }

  @override
  String activityVerbRetried(String target) {
    return 'Повторно запущено $target';
  }

  @override
  String activityVerbReverted(String target) {
    return 'Відкочено $target';
  }

  @override
  String activityVerbReviewed(String target) {
    return 'Переглянуто $target';
  }

  @override
  String activityVerbRan(String target) {
    return 'Запущено $target';
  }

  @override
  String activityVerbSelected(String target) {
    return 'Вибрано $target';
  }

  @override
  String activityVerbSent(String target) {
    return 'Надіслано $target';
  }

  @override
  String activityVerbStaged(String target) {
    return 'Додано в індекс $target';
  }

  @override
  String activityVerbSteered(String target) {
    return 'Скеровано $target';
  }

  @override
  String activityVerbSubmitted(String target) {
    return 'Подано $target';
  }

  @override
  String activityVerbSynced(String target) {
    return 'Синхронізовано $target';
  }

  @override
  String activityVerbToggled(String target) {
    return 'Перемкнуто $target';
  }

  @override
  String activityVerbUninstalled(String target) {
    return 'Видалено $target';
  }

  @override
  String activityVerbUnstaged(String target) {
    return 'Прибрано з індексу $target';
  }

  @override
  String get activityTargetActionPolicy => 'політика дій';

  @override
  String get activityTargetGoalRun => 'запуск цілі';

  @override
  String get activityTargetRunLog => 'журнал запуску';

  @override
  String get activityTargetWorkingMemory => 'робоча пам\'ять';

  @override
  String get activityTargetRoutingPolicy => 'політика маршрутизації';

  @override
  String get activityTargetAutonomy => 'автономність';

  @override
  String get activityTargetCalendar => 'календар';

  @override
  String get activityTargetChecker => 'перевіряльник';

  @override
  String get activityTargetEditor => 'редактор';

  @override
  String get activityTargetConfirmation => 'підтвердження';

  @override
  String get activityTargetTunnel => 'тунель';

  @override
  String get activityTargetConversation => 'розмова';

  @override
  String get activityTargetCredentials => 'облікові дані';

  @override
  String get activityTargetDictation => 'диктування';

  @override
  String get activityTargetAgentRun => 'запуск агента';

  @override
  String get activityTargetEvalSuite => 'набір eval';

  @override
  String get activityTargetWorker => 'воркер';

  @override
  String get activityTargetWorktree => 'робоче дерево';

  @override
  String get activityTargetMcpServer => 'MCP-сервер';

  @override
  String get activityTargetMemoryAccessGrant => 'дозвіл на доступ до пам\'яті';

  @override
  String get activityTargetMemoryDomain => 'домен пам\'яті';

  @override
  String get activityTargetMemoryFact => 'факт пам\'яті';

  @override
  String get activityTargetMemoryPolicy => 'політика пам\'яті';

  @override
  String get activityTargetFeed => 'стрічка';

  @override
  String get activityTargetNote => 'нотатка';

  @override
  String get activityTargetOrchestration => 'оркестрація';

  @override
  String get activityTargetPipelineRun => 'запуск конвеєра';

  @override
  String get activityTargetPipelineTrigger => 'тригер конвеєра';

  @override
  String get activityTargetPlan => 'план';

  @override
  String get activityTargetPlaybook => 'плейбук';

  @override
  String get activityTargetPullRequest => 'pull request';

  @override
  String get activityTargetReview => 'рев\'ю';

  @override
  String get activityTargetProcess => 'процес';

  @override
  String get activityTargetProviderPolicy => 'політика провайдера';

  @override
  String get activityTargetReaction => 'реакція';

  @override
  String get activityTargetReviewSpace => 'простір рев\'ю';

  @override
  String get activityTargetReviewStudio => 'студія рев\'ю';

  @override
  String get activityTargetServerData => 'дані сервера';

  @override
  String get activityTargetSoundscape => 'звуковий ландшафт';

  @override
  String get activityTargetSession => 'сеанс';

  @override
  String get activityTargetTerminal => 'термінал';

  @override
  String get activityTargetTicketLink => 'посилання на тікет';

  @override
  String get activityTargetTicketSync => 'синхронізація тікетів';

  @override
  String get activityTargetProfile => 'профіль';

  @override
  String get activityTargetVoiceProfile => 'голосовий профіль';

  @override
  String get activityTargetWeather => 'прогноз погоди';

  @override
  String get activityTargetWorkProduct => 'робочий продукт';

  @override
  String get activityChangedMemberRole => 'Змінено роль учасника';

  @override
  String get activityChangedMemberRepoAccess =>
      'Змінено доступ учасника до репозиторію';

  @override
  String get activityUpdatedGitHubToken => 'Оновлено токен GitHub';

  @override
  String get activityRefreshedWeather => 'Оновлено прогноз погоди';

  @override
  String get activitySetWeatherLocation =>
      'Встановлено місце для прогнозу погоди';

  @override
  String get activityClearedWeatherLocation =>
      'Очищено місце для прогнозу погоди';

  @override
  String get activityMarkedAllArticlesRead =>
      'Позначено всі статті як прочитані';

  @override
  String get activityMarkedArticleRead => 'Позначено статтю як прочитану';

  @override
  String get activityUpdatedSavedArticle => 'Оновлено збережену статтю';

  @override
  String get activityTookOverSession => 'Перехоплено сеанс';

  @override
  String get activityHandedBackSession => 'Повернуто сеанс';

  @override
  String get activityCommittedAndPushed => 'Зроблено коміт і push';

  @override
  String get activityBackedUpServer => 'Зроблено резервну копію даних сервера';

  @override
  String get activityMarkedSpaceRead => 'Позначено простір як прочитаний';

  @override
  String get activityRespondedToInvitation =>
      'Відповідено на запрошення на подію';

  @override
  String get activityStartedCalendarConnect =>
      'Розпочато підключення календаря';

  @override
  String get activityDisconnectedCalendar => 'Від\'єднано календар';

  @override
  String get activityMarkedFileViewed => 'Позначено файл як переглянутий';

  @override
  String get activityRespondedToApproval =>
      'Відповідь на запит на затвердження';

  @override
  String get activityChangedTunnel => 'Змінено налаштування тунелю';

  @override
  String get activitySentMessageToAgent => 'Надіслано повідомлення агенту';

  @override
  String get activityOpenedReviewSpace => 'Відкрито простір рецензування';

  @override
  String get activityOpenedStandingConversation => 'Відкрито постійну розмову';

  @override
  String get activityStartedRecording => 'Розпочато запис';

  @override
  String get activityStoppedRecording => 'Зупинено запис';

  @override
  String get activityToggledMcpServer => 'Перемкнуто MCP-сервер';

  @override
  String get activityUpdatedMcpToken => 'Оновлено MCP-токен';

  @override
  String get activitySavedApiKey => 'Збережено API-ключ';

  @override
  String get activityRemovedProviderCredential =>
      'Видалено облікові дані провайдера';

  @override
  String get activityUpdatedLinkedRepos => 'Оновлено пов\'язані репозиторії';

  @override
  String get activityUnlinkedRepo => 'Від\'єднано репозиторій';

  @override
  String get activityUpdatedActionItem => 'Оновлено пункт дії';

  @override
  String adRulesCount(int count) {
    return '$count ad rules';
  }

  @override
  String get adapter => 'Адаптер';

  @override
  String get adapterLabel => 'Адаптер';

  @override
  String get adapters => 'Адаптери';

  @override
  String get adaptersAutoDetected =>
      'Автоматично виявлені раннери агентів, доступні на цій машині. Встановіть відсутні CLI-інструменти, щоб увімкнути додаткових раннерів.';

  @override
  String get add => 'Додати';

  @override
  String get addAComment => 'Додати коментар';

  @override
  String get addAReaction => 'Додати реакцію';

  @override
  String get addASuggestion => 'Додати пропозицію';

  @override
  String get addAgents => 'Додати агентів';

  @override
  String get addEmoji => 'Додати емодзі';

  @override
  String get addFeed => 'Додати стрічку';

  @override
  String get addressBarHint => 'Введіть URL';

  @override
  String get addFromFile => 'Додати з файлу';

  @override
  String get addGif => 'Додати GIF';

  @override
  String get addGithubRepoPrompt =>
      'Додайте принаймні один репозиторій GitHub, щоб бачити pull requests';

  @override
  String get addLocalCheckoutDescription =>
      'Додайте локальний checkout, щоб почати націлюватися на нього з цього робочого простору.';

  @override
  String get addRepository => 'Додати репозиторій';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Додати $count репозиторія',
      many: 'Додати $count репозиторіїв',
      few: 'Додати $count репозиторії',
      one: 'Додати репозиторій',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'Перегляньте папки на машині, де запущено сервер, і виберіть git checkout\'и для реєстрації.';

  @override
  String get selectThisFolder => 'Вибрати цю папку';

  @override
  String get deselectThisFolder => 'Зняти вибір з цієї папки';

  @override
  String get goUp => 'Вгору';

  @override
  String get noSubfoldersHere => 'Тут немає вкладених папок';

  @override
  String get notAGitRepository => 'Ця папка не є git-репозиторієм.';

  @override
  String get addToken => 'Додати токен';

  @override
  String get addWorkspace => 'Додати робочий простір';

  @override
  String get addWorkspaceEllipsis => 'Додати робочий простір…';

  @override
  String get added => 'Додано';

  @override
  String get addingEllipsis => 'Додавання…';

  @override
  String get advancedLabel => 'Розширені';

  @override
  String get agent => 'Агент';

  @override
  String agentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agents',
      one: '1 agent',
    );
    return '$_temp0';
  }

  @override
  String get agentMdPath => 'Шлях до MD агента';

  @override
  String get agentName => 'Назва агента';

  @override
  String get agentTitle => 'Заголовок агента';

  @override
  String get agentUpdated => 'Агента оновлено.';

  @override
  String get agents => 'Агенти';

  @override
  String get agentsMentionSection => 'Агенти';

  @override
  String get usersMentionSection => 'Люди';

  @override
  String get ticketsMentionSection => 'Тікети';

  @override
  String get pullRequestsMentionSection => 'Pull requests';

  @override
  String get meetingsMentionSection => 'Зустрічі';

  @override
  String get entityRefTicketFallback => 'Тікет';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'Зустріч';

  @override
  String get aiReview => 'AI-рев\'ю';

  @override
  String get all => 'Усі';

  @override
  String get allAgentsAlreadyInSpace => 'Усі агенти вже в цьому просторі.';

  @override
  String get allCommits => 'Усі коміти';

  @override
  String get allSources => 'Усі джерела';

  @override
  String get allow => 'Дозволити';

  @override
  String get allowGitPush => 'Дозволити git push';

  @override
  String get allowGithubApi => 'Дозволити виклики GitHub API';

  @override
  String get allowNetwork => 'Дозволити загальний доступ до мережі';

  @override
  String get apiKeys => 'Ключі API';

  @override
  String get appFont => 'Шрифт застосунку';

  @override
  String get appLogLevelDebugDescription =>
      'Додає докладні трасування — для розробки.';

  @override
  String get appLogLevelDebugLabel => 'Налагодження';

  @override
  String get appLogLevelErrorDescription =>
      'Лише неочікувані помилки та винятки.';

  @override
  String get appLogLevelErrorLabel => 'Помилка';

  @override
  String get appLogLevelInfoDescription =>
      'Додає повідомлення про життєвий цикл і стан.';

  @override
  String get appLogLevelInfoLabel => 'Інформація';

  @override
  String get appLogLevelNoneDescription => 'Зовсім без виводу в консоль.';

  @override
  String get appLogLevelNoneLabel => 'Немає';

  @override
  String get appLogLevelVerboseDescription =>
      'Усе. Дуже багато шуму — лише для налагодження.';

  @override
  String get appLogLevelVerboseLabel => 'Докладно';

  @override
  String get appLogLevelWarningDescription =>
      'Додає попередження та виправні проблеми.';

  @override
  String get appLogLevelWarningLabel => 'Попередження';

  @override
  String get appearanceLanguage => 'Вигляд і мова';

  @override
  String get apply => 'Застосувати';

  @override
  String get approve => 'Схвалити';

  @override
  String get agentApprovalRequired => 'Потрібне схвалення';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ще $count очікують',
      many: 'ще $count очікують',
      few: 'ще $count очікують',
      one: 'ще $count очікує',
    );
    return '$_temp0';
  }

  @override
  String get approved => 'Схвалено';

  @override
  String get articleNoun => 'Стаття';

  @override
  String get articlesSubscribed => 'Статті з підписаних стрічок.';

  @override
  String get askAi => 'Запитати AI';

  @override
  String get askAiReviewDescription => 'Попросити AI зробити рев\'ю цього PR';

  @override
  String get assignees => 'Призначені';

  @override
  String get attachImage => 'Прикріпити зображення';

  @override
  String get attachedAgents => 'Прикріплені агенти';

  @override
  String get audioInput => 'Аудіовхід';

  @override
  String get audioOutput => 'Аудіовихід';

  @override
  String get authenticationToken => 'Токен автентифікації';

  @override
  String authoredByLabel(String role) {
    return 'Від: $role';
  }

  @override
  String get autoRecommended => 'Автоматично (рекомендовано)';

  @override
  String get available => 'Доступно';

  @override
  String get awaitingYourReview => 'Очікує вашого рев\'ю';

  @override
  String get back => 'Назад';

  @override
  String get backLabel => 'Назад';

  @override
  String get backend => 'Бекенд';

  @override
  String get blockAdsTrackers => 'Блокувати рекламу, трекери та банери cookies';

  @override
  String get blocking => 'Блокує';

  @override
  String get bookmarkLabel => 'Закладка';

  @override
  String get briefDescription => 'Короткий опис';

  @override
  String get bugLabel => 'Баг';

  @override
  String get bundledDefaultsNeverUpdated =>
      'Вбудовані типові значення — ніколи не оновлюються';

  @override
  String get cancel => 'Скасувати';

  @override
  String get cancelEdit => 'Скасувати редагування';

  @override
  String get categoryCreation => 'Створення';

  @override
  String get categoryEditing => 'Редагування';

  @override
  String get categoryNavigation => 'Навігація';

  @override
  String get categorySystem => 'Система';

  @override
  String get categoryView => 'Перегляд категорій';

  @override
  String get change => 'Змінити';

  @override
  String get changesRequested => 'Запитано зміни';

  @override
  String get spacesMentionSection => 'Простори';

  @override
  String get checkForUpdates => 'Перевірити оновлення';

  @override
  String get checking => 'Перевірка';

  @override
  String get checkingEllipsis => 'Перевірка…';

  @override
  String get chooseAppFont => 'Обрати шрифт програми';

  @override
  String get chooseCodeFont => 'Обрати шрифт коду';

  @override
  String get chooseRunner => 'Оберіть раннер агента.';

  @override
  String get clear => 'Очистити';

  @override
  String get clickToRetry => 'Натисніть, щоб повторити';

  @override
  String get close => 'Закрити';

  @override
  String get closeEsc => 'Закрити (Esc)';

  @override
  String get closeReader => 'Закрити читач';

  @override
  String get closed => 'Закрито';

  @override
  String get codeFont => 'Шрифт коду';

  @override
  String get codeFontLigatures => 'Лігатури шрифту коду';

  @override
  String get codeFontLigaturesDescription =>
      'Показувати програмні лігатури (=>, !=, ->) як об’єднані гліфи в коді та diff';

  @override
  String get collapse => 'Згорнути';

  @override
  String get commandPalette => 'Палітра команд';

  @override
  String get commandPaletteOrgMembers => 'Учасники організації';

  @override
  String get commandPaletteBrowseTeam => 'Переглянути команду';

  @override
  String get commandPaletteBrowseTeamDesc =>
      'Переглянути всіх учасників організації';

  @override
  String get compactDone =>
      'Розмову стиснуто. Ранішу історію згорнуто в підсумок.';

  @override
  String get compactNothing => 'Поки нічого стискати. Розмова ще коротка.';

  @override
  String get compactBusy => 'Агент ще працює. Стискайте після завершення ходу.';

  @override
  String get compactUnavailable => 'Стискання недоступне на цьому сервері.';

  @override
  String get commandsMentionSection => 'Команди';

  @override
  String get comment => 'Коментар';

  @override
  String get commentOnThisFile => 'Коментувати цей файл';

  @override
  String get commented => 'Прокоментовано';

  @override
  String get commits => 'Коміти';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Показано останні $loaded з $total комітів';
  }

  @override
  String get prCloneProgressCloningTitle => 'Клонування репозиторію';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'Цей PR змінює $fileCount файлів, що перевищує ліміт API GitHub. Клонуємо репозиторій локально…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'Цей PR перевищує ліміт файлів API GitHub. Клонуємо репозиторій локально…';

  @override
  String get prCloneProgressFetchingTitle => 'Отримання refs PR';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Отримуємо базову гілку та head-ref PR…';

  @override
  String get prCloneProgressComputingTitle => 'Обчислення diff';

  @override
  String get prCloneProgressComputingSubtitle =>
      'Запускаємо git diff локально…';

  @override
  String get prCloneProgressErrorTitle => 'Не вдалося завантажити diff';

  @override
  String get prCloneProgressErrorSubtitle =>
      'Сталася помилка під час клонування або обчислення diff. Спробуйте оновити.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Ще працюємо… минуло $elapsed';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Впевненість: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'Налаштуйте ідентичності агентів, промпти, навички та переглядайте запуски.';

  @override
  String get configureDefaultRunners =>
      'Налаштуйте адаптер і модель для нових просторів і створення заголовків.';

  @override
  String get configuredLabel => 'Налаштовано.';

  @override
  String get confirmedBy => 'Підтверджено';

  @override
  String get consensus => 'Консенсус';

  @override
  String get contentHint => 'Що варто запам’ятати';

  @override
  String get contentLabel => 'Вміст';

  @override
  String get contentMarkdown => 'Вміст (Markdown)';

  @override
  String get contextWindowSize => 'Розмір вікна контексту';

  @override
  String modelContextChip(String size) {
    return 'Модель · $size';
  }

  @override
  String get continueLabel => 'Продовжити';

  @override
  String get conversationMode => 'Режим';

  @override
  String cookieRulesCount(int count) {
    return '$count cookie rules';
  }

  @override
  String get copied => 'Скопійовано!';

  @override
  String get copy => 'Копіювати';

  @override
  String get copyAddress => 'Копіювати адресу';

  @override
  String get copyBaseBranchTooltip => 'Копіювати назву базової гілки';

  @override
  String get copyHeadBranchTooltip => 'Копіювати назву гілки head';

  @override
  String couldNotListDevices(String error) {
    return 'Не вдалося отримати список пристроїв: $error';
  }

  @override
  String get create => 'Створити';

  @override
  String get createOrSelectWorkspace =>
      'Створіть або виберіть робочий простір, перш ніж додавати репозиторії.';

  @override
  String get createPullRequest => 'Створити pull request';

  @override
  String get createdByMe => 'Створені мною';

  @override
  String createdLabel(String date) {
    return 'Створено: $date';
  }

  @override
  String get currentParticipants => 'Поточні учасники';

  @override
  String get customCapabilitiesDescription => 'Опис власних можливостей';

  @override
  String get customSystemPrompt =>
      'Власний системний промпт для цього агента...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count днів тому',
      many: '$count днів тому',
      few: '$count дні тому',
      one: '$count день тому',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Деактивувати';

  @override
  String get defaultCapabilities => 'Типові можливості · нові простори';

  @override
  String get defaultChat => 'Типовий чат';

  @override
  String get defaultRunners => 'Типові раннери';

  @override
  String get delete => 'Видалити';

  @override
  String get deleteAgent => 'Видалити агента';

  @override
  String deleteAgentConfirm(String name) {
    return 'Видалити «$name»? Цю дію не можна скасувати.';
  }

  @override
  String get deleteSpace => 'Видалити простір';

  @override
  String deleteConfirmName(String name) {
    return 'Видалити «$name»?';
  }

  @override
  String get archiveConversation => 'Архівувати розмову';

  @override
  String get deleteFact => 'Видалити факт';

  @override
  String get deleteFeedBody =>
      'Це видалить стрічку та всі кешовані статті. Статті з закладками з цієї стрічки також буде видалено.';

  @override
  String deleteFeedConfirm(String name) {
    return 'Видалити «$name»?';
  }

  @override
  String get deletePolicy => 'Видалити політику';

  @override
  String get deletePolicyConfirm =>
      'Видалити цю політику? Цю дію не можна скасувати.';

  @override
  String deleteTopicConfirm(String topic) {
    return 'Видалити «$topic»? Цю дію не можна скасувати.';
  }

  @override
  String get deleteWorkspace => 'Видалити робочий простір';

  @override
  String get deny => 'Відхилити';

  @override
  String get detailsLabel => 'Подробиці';

  @override
  String get descriptionLabel => 'Опис';

  @override
  String detectedBackend(String label) {
    return 'Виявлено: $label';
  }

  @override
  String get detectedRunners => 'Виявлені раннери';

  @override
  String get detectingAdapters => 'Виявлення адаптерів…';

  @override
  String get detectingInputDevices => 'Виявлення пристроїв введення…';

  @override
  String detectionFailed(String error) {
    return 'Не вдалося виявити: $error';
  }

  @override
  String get disabled => 'Вимкнено';

  @override
  String get discover => 'Огляд';

  @override
  String get dismissed => 'Відхилено';

  @override
  String get domainHint => 'напр. api-performance';

  @override
  String get domainLabel => 'Домен';

  @override
  String get download => 'Завантажити';

  @override
  String get downloadingLabel => 'Завантаження';

  @override
  String downloadingModel(int pct) {
    return 'Завантаження моделі… $pct%';
  }

  @override
  String get draft => 'Чернетка';

  @override
  String get draftLabel => 'Чернетка';

  @override
  String get edit => 'Редагувати';

  @override
  String get edited => 'змінено';

  @override
  String get editMessage => 'Редагувати повідомлення';

  @override
  String get revertToThere => 'Відкотити туди';

  @override
  String get sendAsNewMessage => 'Надіслати як нове повідомлення';

  @override
  String get editMessageChoiceBody =>
      'Відкат ховає повідомлення після цього й повертає файли агента. Це можна скасувати. Надсилання новим повідомленням лишає розмову як є.';

  @override
  String get deleteMessage => 'Видалити повідомлення';

  @override
  String get deleteMessageConfirm =>
      'Видалити це повідомлення? Цю дію не можна скасувати.';

  @override
  String get messageDeleted => 'Повідомлення видалено';

  @override
  String get searchInConversation => 'Пошук у розмові';

  @override
  String get searchMessagesHint => 'Пошук повідомлень…';

  @override
  String get noMessagesFound => 'Повідомлень не знайдено';

  @override
  String get editFact => 'Редагувати факт';

  @override
  String get editPolicy => 'Редагувати політику';

  @override
  String get editSuggestedCodeHint => 'Редагувати запропонований код…';

  @override
  String get editSuggestion => 'Пропозиція редагування';

  @override
  String get egArchitect => 'напр. architect';

  @override
  String get egControlCenter => 'напр. control-center';

  @override
  String get egPlatform => 'напр. Platform';

  @override
  String get egSamuelAlev => 'напр. SamuelAlev';

  @override
  String get egSoftwareArchitect => 'напр. Software Architect';

  @override
  String get egTheVerge => 'напр. The Verge';

  @override
  String get egTokenLimit => 'напр. 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Не вдалося встановити: $error';
  }

  @override
  String get embeddingInstalled =>
      'Локальну модель ембедингів установлено. Гібридний пошук увімкнено.';

  @override
  String get embeddingModel => 'Модель ембедингів (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Не встановлено. Поки функцію не ввімкнено, пошук працює лише за ключовими словами.';

  @override
  String get embeddingRedownloadBody =>
      'Наявні файли моделі буде видалено й завантажено знову. Семантичний пошук буде недоступний, доки завантаження не завершиться.';

  @override
  String get embeddingRemoveBody =>
      'Семантичний пошук буде вимкнено, доки ви не встановите його знову. Можна встановити повторно будь-коли.';

  @override
  String get speakerDiarization => 'Діаризація спікерів';

  @override
  String get diarizationModel => 'Модель діаризації';

  @override
  String get diarizationInstalled =>
      'Установлено — позначає окремих спікерів у стенограмах зустрічей';

  @override
  String get diarizationNotInstalled =>
      'Не встановлено — спікерів на зустрічах не буде розділено';

  @override
  String diarizationInstallFailed(String error) {
    return 'Не вдалося встановити: $error';
  }

  @override
  String get redownloadDiarizationModel =>
      'Завантажити модель діаризації знову';

  @override
  String get diarizationRedownloadBody =>
      'Поточні моделі діаризації буде видалено й завантажено знову.';

  @override
  String get removeDiarizationModel => 'Видалити модель діаризації';

  @override
  String get diarizationRemoveBody =>
      'Моделі діаризації на пристрої буде видалено. Уже створені стенограми зустрічей не зміняться.';

  @override
  String get enableNotifications => 'Увімкнути сповіщення';

  @override
  String get enableSandboxing => 'Увімкнути пісочницю';

  @override
  String get enabled => 'Увімкнено';

  @override
  String errorCreatingAgent(String error) {
    return 'Помилка створення агента: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Помилка видалення агента: $error';
  }

  @override
  String errorWithDetail(String error) {
    return 'Помилка: $error';
  }

  @override
  String get expand => 'Розгорнути';

  @override
  String extractingModel(int pct) {
    return 'Розпакування моделі… $pct%';
  }

  @override
  String get fact => 'Факт';

  @override
  String factCount(int count) {
    return '$count факт';
  }

  @override
  String factCountPlural(int count) {
    return '$count facts';
  }

  @override
  String get facts => 'Факти';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount фактів · $policyCount політик';
  }

  @override
  String get failed => 'Не вдалося';

  @override
  String failedToDispatch(String error) {
    return 'Не вдалося надіслати: $error';
  }

  @override
  String get failedToLoad => 'Не вдалося завантажити';

  @override
  String failedToLoadAgents(String error) {
    return 'Не вдалося завантажити агентів: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Не вдалося завантажити стрічки: $error';
  }

  @override
  String get failedToLoadGifs => 'Не вдалося завантажити GIF';

  @override
  String failedToLoadLogs(String error) {
    return 'Не вдалося завантажити журнали: $error';
  }

  @override
  String get failedToLoadRepos => 'Не вдалося завантажити репозиторії';

  @override
  String get failedToLoadWorkspaces => 'Не вдалося завантажити робочі простори';

  @override
  String failedToStartAiReview(String error) {
    return 'Не вдалося почати AI-перевірку: $error';
  }

  @override
  String get failedToStartMicTest => 'Не вдалося почати перевірку мікрофона.';

  @override
  String failedToSubmitReview(String error) {
    return 'Не вдалося надіслати перевірку: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'Не вдалося вивантажити $name: $error';
  }

  @override
  String failedWithError(String error) {
    return 'Не вдалося: $error';
  }

  @override
  String get failure => 'Збій';

  @override
  String get feedAlreadyExists => 'Стрічка з цим URL уже існує.';

  @override
  String get feedUrlExample => 'напр. https://example.com/feed.xml';

  @override
  String get feedUrlLabel => 'URL стрічки';

  @override
  String feedsCount(int count) {
    return 'Стрічки ($count)';
  }

  @override
  String get filesChanged => 'Змінені файли';

  @override
  String filesCount(int count) {
    return '$count file(s)';
  }

  @override
  String get filesMentionSection => 'Файли';

  @override
  String get filterAgents => 'Фільтрувати агентів...';

  @override
  String get filterFilesHint => 'Фільтрувати файли…';

  @override
  String get filterLists => 'Фільтрувати списки';

  @override
  String get filterSkillsPlaceholder => 'Фільтрувати навички…';

  @override
  String get finish => 'Завершити';

  @override
  String get fix => 'Виправити';

  @override
  String get forward => 'Вперед';

  @override
  String get gatesGithubPatPush =>
      'Керує підстановкою GitHub PAT. Потрібно, щоб агент міг виконувати push.';

  @override
  String get general => 'Загальні';

  @override
  String get githubLink => 'Посилання GitHub';

  @override
  String get claudeStatusFetchFailed =>
      'Не вдалося з\'єднатися зі status.claude.com';

  @override
  String get claudeStatusOpenInBrowser => 'Відкрити status.claude.com';

  @override
  String get githubStatusFetchFailed =>
      'Не вдалося з\'єднатися з githubstatus.com';

  @override
  String get githubDegradedTitle => 'GitHub повідомляє про проблеми';

  @override
  String githubDegradedStatusLine(String status) {
    return 'Стан GitHub: $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'Стан GitHub: $status. Дані pull request можуть бути застарілими або неповними, поки сервіс не відновиться.';
  }

  @override
  String get githubStatusOpenInBrowser => 'Відкрити githubstatus.com';

  @override
  String get githubStatusRefresh => 'Оновити';

  @override
  String githubStatusUpdated(String time) {
    return 'Оновлено $time';
  }

  @override
  String get kimiStatusFetchFailed =>
      'Не вдалося з\'єднатися зі status.moonshot.cn';

  @override
  String get kimiStatusOpenInBrowser => 'Відкрити status.moonshot.cn';

  @override
  String get openaiStatusFetchFailed =>
      'Не вдалося з\'єднатися зі status.openai.com';

  @override
  String get openaiStatusOpenInBrowser => 'Відкрити status.openai.com';

  @override
  String get serviceStatusMaintenance => 'Обслуговування';

  @override
  String get serviceStatusMajorIssues => 'Серйозні проблеми';

  @override
  String get serviceStatusMinorIssues => 'Незначні проблеми';

  @override
  String get serviceStatusOperational => 'Працює';

  @override
  String get serviceStatusOutage => 'Збій';

  @override
  String get serviceStatusTitle => 'Стан сервісів';

  @override
  String get serviceStatusUnknown => 'Невідомо';

  @override
  String lastChecked(String time) {
    return 'Перевірено $time';
  }

  @override
  String get lastCheckedRecently => 'Перевірено нещодавно';

  @override
  String get giveYourWorkAHome => 'Дайте своїй роботі дім.';

  @override
  String get goBack => 'Назад';

  @override
  String get goForward => 'Вперед';

  @override
  String get googleFonts => 'Шрифти Google';

  @override
  String get high => 'Високий';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count години тому',
      many: '$count годин тому',
      few: '$count години тому',
      one: '$count годину тому',
    );
    return '$_temp0';
  }

  @override
  String get images => 'Зображення';

  @override
  String get inactive => 'Неактивний';

  @override
  String get install => 'Установити';

  @override
  String get installRequired => 'Потрібне встановлення';

  @override
  String installedVersion(String version) {
    return 'Установлено $version';
  }

  @override
  String get invite => 'Запросити';

  @override
  String get inviteAgent => 'Запросити агента';

  @override
  String get isolateAgentExecution => 'Ізолювати виконання агента.';

  @override
  String get justNow => 'Щойно';

  @override
  String get keepSandboxing => 'Залишити пісочницю';

  @override
  String get keybindingAddARepositoryDescription => 'Додати репозиторій';

  @override
  String get keybindingAddRepository => 'Додати репозиторій';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Додати або зняти закладку з вибраної статті';

  @override
  String get keybindingCommandPalette => 'Палітра команд';

  @override
  String get keybindingCreateANewAgentDescription => 'Створити нового агента';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Створити новий робочий простір';

  @override
  String get keybindingFocusSearch => 'Фокус на пошук';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Фокус на поле пошуку pull request';

  @override
  String get keybindingNewAgent => 'Новий агент';

  @override
  String get keybindingNewWorkspace => 'Новий робочий простір';

  @override
  String get keybindingNextArticle => 'Наступна стаття';

  @override
  String get keybindingNextSpace => 'Наступний простір';

  @override
  String get keybindingNextWorkspace => 'Наступний робочий простір';

  @override
  String get keybindingOpenArticle => 'Відкрити статтю';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Відкрити або закрити спливне вікно перемикача робочих просторів на бічній панелі';

  @override
  String get keybindingOpenPr => 'Відкрити PR';

  @override
  String get keybindingOpenSettings => 'Відкрити налаштування';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Відкрити налаштування програми';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Відкрити палітру команд';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Відкрити вибрану статтю';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Відкрити вибраний pull request';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Відкрити вибраний робочий простір';

  @override
  String get keybindingOpenWorkspace => 'Відкрити робочий простір';

  @override
  String get keybindingPreviousArticle => 'Попередня стаття';

  @override
  String get keybindingPreviousSpace => 'Попередній простір';

  @override
  String get keybindingPreviousWorkspace => 'Попередній робочий простір';

  @override
  String get keybindingRefresh => 'Оновити';

  @override
  String get keybindingRefreshAllFeedsDescription => 'Оновити всі стрічки';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Оновити список pull request';

  @override
  String get keybindingRescanForAdaptersDescription =>
      'Повторно сканувати адаптери';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Вибрати наступну статтю';

  @override
  String get keybindingSelectTheNextSpaceDescription =>
      'Вибрати наступний простір';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Вибрати попередню статтю';

  @override
  String get keybindingSelectThePreviousSpaceDescription =>
      'Вибрати попередній простір';

  @override
  String get keybindingSendMessage => 'Надіслати повідомлення';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Надіслати поточне повідомлення';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Перемкнути світлу та темну тему';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Перейти до восьмого робочого простору';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Перейти до п\'ятого робочого простору';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Перейти до першого робочого простору';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Перейти до четвертого робочого простору';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Перейти до наступного робочого простору';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Перейти до дев\'ятого робочого простору';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Перейти до попереднього робочого простору';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Перейти до другого робочого простору';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Перейти до сьомого робочого простору';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Перейти до шостого робочого простору';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Перейти до третього робочого простору';

  @override
  String get keybindingToggleBookmark => 'Перемкнути закладку';

  @override
  String get keybindingToggleTheme => 'Перемкнути тему';

  @override
  String get keybindingToggleWorkspaceSwitcher =>
      'Перемкнути перемикач робочих просторів';

  @override
  String get keybindingWorkspace1 => 'Робочий простір 1';

  @override
  String get keybindingWorkspace2 => 'Робочий простір 2';

  @override
  String get keybindingWorkspace3 => 'Робочий простір 3';

  @override
  String get keybindingWorkspace4 => 'Робочий простір 4';

  @override
  String get keybindingWorkspace5 => 'Робочий простір 5';

  @override
  String get keybindingWorkspace6 => 'Робочий простір 6';

  @override
  String get keybindingWorkspace7 => 'Робочий простір 7';

  @override
  String get keybindingWorkspace8 => 'Робочий простір 8';

  @override
  String get keybindingWorkspace9 => 'Робочий простір 9';

  @override
  String get keybindings => 'Сполучення клавіш';

  @override
  String get keybindingsDescription =>
      'Усі сполучення клавіш. Сполучення фіксовані, їх не можна змінити.';

  @override
  String get killRunning => 'Завершити запущені';

  @override
  String get languageSystem => 'Системна';

  @override
  String get leaveACommentEllipsis => 'Залишити коментар…';

  @override
  String get legendLabel => 'Легенда';

  @override
  String get lessLabel => 'Менше';

  @override
  String get letsPluginTools => 'Підключімо ваші інструменти.';

  @override
  String get level => 'Рівень';

  @override
  String get loadingAgents => 'Завантаження агентів…';

  @override
  String get loadingModels => 'Завантаження моделей…';

  @override
  String get loadingProviders => 'Завантаження провайдерів…';

  @override
  String get logLevel => 'Рівень журналу';

  @override
  String get logs => 'Журнали';

  @override
  String get low => 'Низький';

  @override
  String get maintenance => 'Обслуговування';

  @override
  String get manageParticipants => 'Керувати учасниками';

  @override
  String get manageWorkspaces => 'Керувати робочими просторами';

  @override
  String get reorderWorkspace => 'Змінити порядок робочого простору';

  @override
  String get matchOsAppearance =>
      'Відповідати оформленню ОС або вибрати фіксований режим.';

  @override
  String get mcpAuthToken => 'Токен автентифікації MCP';

  @override
  String get mcpNotAvailableOnServer =>
      'Керування MCP-сервером недоступне на підключеному сервері.';

  @override
  String get modelManagedOnServer =>
      'Ця модель працює на сервері й керується там.';

  @override
  String get mcpServer => 'MCP-сервер';

  @override
  String get medium => 'Середній';

  @override
  String get memoryDataHint =>
      'Факти й політики з’являтимуться тут під час роботи агентів.';

  @override
  String get memoryLabel => 'Пам’ять';

  @override
  String get merge => 'Злити';

  @override
  String get merged => 'Злито';

  @override
  String get messagePlaceholder => 'Повідомлення… (@ — згадати, / — команди)';

  @override
  String get navConversations => 'Простори';

  @override
  String get microphonePermissionDenied => 'Доступ до мікрофона відхилено.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count хвилин тому',
      many: '$count хвилин тому',
      few: '$count хвилини тому',
      one: '$count хвилину тому',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Модель';

  @override
  String get modified => 'Змінено';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count місяців тому',
      many: '$count місяців тому',
      few: '$count місяці тому',
      one: '$count місяць тому',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => 'Більше';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Назва';

  @override
  String get nameAndTitleRequired => 'Назва й заголовок обов’язкові.';

  @override
  String get nameAndUrlRequired => 'Потрібні назва й URL';

  @override
  String get nameLabel => 'Назва';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Нативна пісочниця доступна на $platform.';
  }

  @override
  String get nativeSandboxNeedsInstall =>
      'Потрібне встановлення нативної пісочниці';

  @override
  String get navObservability => 'Спостережуваність';

  @override
  String get navSettings => 'Налаштування';

  @override
  String networkBlockCount(int count) {
    return '$count мережевих блокувань';
  }

  @override
  String get neutral => 'Нейтральний';

  @override
  String get newCommitsPushed =>
      'Надіслано нові коміти — натисніть, щоб оновити diff';

  @override
  String get newFact => 'Новий факт';

  @override
  String get newPolicy => 'Нова політика';

  @override
  String get newsfeed => 'Стрічка новин';

  @override
  String get newsfeedLabel => 'Стрічка новин';

  @override
  String get newsfeedSettingsDescription =>
      'Керуйте підписаними стрічками та параметрами читання.';

  @override
  String get newsfeedSettingsTitle => 'Налаштування стрічки новин';

  @override
  String get nextMatch => 'Наступний збіг (↵)';

  @override
  String get noActiveWorkspace =>
      'Не вибрано активний робочий простір або репозиторій.';

  @override
  String get noActiveWorkspaceCreate => 'Немає активного робочого простору';

  @override
  String get noActiveWorkspaceGithub =>
      'Немає активного робочого простору з репозиторієм GitHub.';

  @override
  String get noAgents => 'Немає агентів';

  @override
  String get noArticlesYet => 'Ще немає статей';

  @override
  String get noArticlesYetBody => 'Тут з’являтимуться статті з ваших стрічок.';

  @override
  String get noExecutionLogsYet => 'Ще немає журналів виконання';

  @override
  String get noFacts => 'Ще немає фактів';

  @override
  String get noFeedsYet => 'Ще немає стрічок';

  @override
  String get noFileAnchor =>
      'Немає прив’язки до файлу — не можна додати вбудований коментар.';

  @override
  String get noFileChangesInScope => 'У цій області немає змін файлів';

  @override
  String get noGifsFound => 'GIF-файлів не знайдено';

  @override
  String get noInputDevicesDetected =>
      'Пристроїв введення не виявлено — використовується системний стандарт.';

  @override
  String get noMatchingFiles => 'Немає відповідних файлів';

  @override
  String get noMatchingGoogleFonts => 'Немає відповідних Google Fonts.';

  @override
  String get noMemoryData => 'Ще немає даних пам’яті';

  @override
  String get noMessagesYet => 'Повідомлень ще немає';

  @override
  String get noModelsAdvertised => 'Цей адаптер не оголошує моделі.';

  @override
  String get noOpenPullRequests => 'Немає відкритих pull request';

  @override
  String get noPolicies => 'Політик ще немає';

  @override
  String get noReposInWorkspaceYet =>
      'У цьому робочому просторі ще немає репозиторіїв';

  @override
  String get noRunnersDetected =>
      'Раннерів ще не виявлено. Оновіть, щоб сканувати знову.';

  @override
  String get noSavedArticles => 'Немає збережених статей';

  @override
  String get noSavedArticlesBody => 'Збережені статті з’являться тут.';

  @override
  String noShortcutsMatch(String query) {
    return 'Немає скорочень, що відповідають «$query»';
  }

  @override
  String get noSystemFonts => 'Системних шрифтів не виявлено.';

  @override
  String get noTokenSet => 'Токен не задано — доступ необмежений.';

  @override
  String get noWorkingMemory => 'Нотаток у робочій пам’яті ще немає.';

  @override
  String get noneAllRoles => 'Немає (усі ролі)';

  @override
  String get notAvailable => 'Недоступно';

  @override
  String get notConfiguredLabel => 'Не налаштовано.';

  @override
  String get notFoundLabel => 'Не знайдено';

  @override
  String get notes => 'Нотатки';

  @override
  String get notificationAgentFinished => 'Агент завершив роботу';

  @override
  String get notificationPrMentioned => 'Згадка в pull request';

  @override
  String get notificationNewMessages => 'Нові повідомлення';

  @override
  String get notificationPrMerged => 'PR злито';

  @override
  String get notificationPrPublished => 'PR опубліковано';

  @override
  String get notificationReviewRequested => 'Запит на рев’ю';

  @override
  String get notifications => 'Сповіщення';

  @override
  String get notifyAgentRunCompleted =>
      'Сповіщати, коли агент завершує запуск.';

  @override
  String get notifyPrMentioned =>
      'Сповіщати, коли вас згадують у pull request.';

  @override
  String get notifyNewMessages =>
      'Сповіщати про нові повідомлення агента в інших просторах.';

  @override
  String get notifyPrMerged => 'Сповіщати, коли pull request злито.';

  @override
  String get notifyPrPublished =>
      'Сповіщати, коли агент публікує pull request.';

  @override
  String get notifyReviewRequested =>
      'Сповіщати, коли вас просять зробити рев’ю pull request.';

  @override
  String get notificationReviewStale => 'Рев’ю застаріло';

  @override
  String get notifyReviewStale =>
      'Коли в pull request, який ви вже рев’ювали, з’являються нові коміти';

  @override
  String get notificationPrMergeReadiness => 'Готово до злиття';

  @override
  String get notifyPrMergeReadiness =>
      'Сповіщати, коли написаний вами pull request стає готовим до злиття або перестає ним бути.';

  @override
  String get notificationPrReviewDecision => 'Рішення рев’ю';

  @override
  String get notifyPrReviewDecision =>
      'Сповіщати, коли рецензент схвалює, запитує зміни або схвалення скасовують.';

  @override
  String get notificationPrChecksStatus => 'Перевірки';

  @override
  String get notifyPrChecksStatus =>
      'Сповіщати, коли CI не проходить на написаному вами pull request, і коли він відновлюється.';

  @override
  String get notificationPrThreadActivity => 'Обговорення рев’ю';

  @override
  String get notifyPrThreadActivity =>
      'Сповіщати, коли хтось відповідає в обговоренні, у якому ви є, або закриває його.';

  @override
  String get notificationPrReadyToMerge => 'Готово до злиття';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '$prTitle має все необхідне.';
  }

  @override
  String get notificationPrMergeBlocked => 'Більше не можна злити';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '$prTitle конфліктує з базовою гілкою.';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '$prTitle відстає від базової гілки.';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '$prTitle очікує обов’язкового рев’ю.';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'Рецензент запросив зміни в $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return 'Перевірки не проходять у $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '$prTitle більше не можна злити.';
  }

  @override
  String get notificationPrApproved => 'Pull request схвалено';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '$login схвалив $prTitle';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '$prTitle схвалено';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count рецензентів ще мають відповісти',
      many: '$count рецензентів ще мають відповісти',
      few: '$count рецензенти ще мають відповісти',
      one: '$count рецензент ще має відповісти',
      zero: 'немає рецензентів',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => 'Запитано зміни';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '$login запросив зміни в $prTitle';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return 'У $prTitle запитано зміни';
  }

  @override
  String get notificationPrReviewDismissed => 'Схвалення скасовано';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '$prTitle знову потребує рев’ю.';
  }

  @override
  String get notificationPrChecksFailed => 'Перевірки не пройшли';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '$checkName не пройшла на $prTitle';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return 'Перевірки не проходять на $prTitle';
  }

  @override
  String get notificationPrChecksRecovered => 'Перевірки проходять';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '$prTitle знову зелений.';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '$login згадав вас у $location';
  }

  @override
  String get notificationPrThreadReplied => 'Нова відповідь';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '$login відповів у $location';
  }

  @override
  String get notificationPrThreadResolved => 'Обговорення розв’язано';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return 'Ваше обговорення в $location розв’язано.';
  }

  @override
  String get notificationGroupAgents => 'Агенти';

  @override
  String get notificationGroupPullRequests => 'Pull requests';

  @override
  String get notificationGroupMessages => 'Повідомлення';

  @override
  String get notificationGroupTickets => 'Тікети';

  @override
  String get notificationGroupCalendar => 'Календар';

  @override
  String get notificationGroupMachines => 'Машини';

  @override
  String get notificationsMutedRepos => 'Вимкнені репозиторії';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count репозиторіїв вимкнено',
      many: '$count репозиторіїв вимкнено',
      few: '$count репозиторії вимкнено',
      one: '$count репозиторій вимкнено',
      zero: 'Немає вимкнених репозиторіїв',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'Вимкнути цей репозиторій';

  @override
  String get onboardingLinuxDescription =>
      'Control Center може використовувати контейнери Linux, щоб ізолювати виконання агентів.';

  @override
  String get onboardingMacosDescription =>
      'Control Center використовує нативну пісочницю на macOS, щоб ізолювати виконання агентів.';

  @override
  String get onboardingUnsupportedDescription =>
      'Пісочниця недоступна на цій платформі. Агенти виконуватимуться без ізоляції.';

  @override
  String get openArticlesInApp => 'Відкривати статті в застосунку';

  @override
  String get openInBrowser => 'Відкрити в браузері';

  @override
  String get openedInYourBrowser => 'Відкрито у браузері.';

  @override
  String get openLabel => 'Відкрити';

  @override
  String get openOnGithub => 'Відкрити на GitHub';

  @override
  String get openStatus => 'Відкритий';

  @override
  String get optionalPersonaDescription => 'Необов’язковий опис персони';

  @override
  String get otherLabel => 'Інше';

  @override
  String get ownerOrganization => 'Власник / організація';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => 'Пройдено';

  @override
  String get pasteValueHere => 'Вставте значення сюди';

  @override
  String get persona => 'Персона';

  @override
  String get policies => 'Політики';

  @override
  String get policiesHint =>
      'Політики з’являться тут, щойно агенти підвищать факти.';

  @override
  String get policy => 'Політика';

  @override
  String get popular => 'Популярні';

  @override
  String get port => 'Порт';

  @override
  String get postingEllipsis => 'Публікація…';

  @override
  String get prCommits => 'Коміти';

  @override
  String get prMergedBody => 'Pull request об’єднано';

  @override
  String get prMoreActions => 'Більше дій';

  @override
  String get prTitle => 'Назва PR';

  @override
  String get reviewCommentHint =>
      'Просто натисніть схвалити — або додайте коментар чи реакцію…';

  @override
  String get nothingToPreview => 'Немає що попередньо переглянути';

  @override
  String get previousMatch => 'Попередній збіг (⇧↵)';

  @override
  String get priorityReviewsDescription =>
      'Пріоритетні рев’ю та огляд репозиторію.';

  @override
  String get prsCreated => 'Створені PR';

  @override
  String get prsMerged => 'Об’єднані PR';

  @override
  String get publishToGithub => 'Опублікувати на GitHub';

  @override
  String get published => 'Опубліковано';

  @override
  String get pullRequestApproved => 'Pull request схвалено';

  @override
  String get pullRequests => 'Pull requests';

  @override
  String get questionLabel => 'ПИТАННЯ';

  @override
  String get queued => 'У черзі';

  @override
  String get react => 'React';

  @override
  String get readPrsIssuesMetadata =>
      'Дозволяє агенту читати PR, issues і метадані репозиторію.';

  @override
  String get readerPreferences => 'Налаштування читача';

  @override
  String get reasoningEffort => 'Зусилля міркування';

  @override
  String get recommendLabel => 'Рекомендовано';

  @override
  String recordingFromDevice(String device) {
    return 'Запис із $device.';
  }

  @override
  String get redownload => 'Завантажити знову';

  @override
  String get redownloadEmbeddingModel => 'Завантажити модель ембедингів знову?';

  @override
  String get redownloadVoiceModel => 'Завантажити голосову модель знову?';

  @override
  String get refinePlan => 'Уточнити план';

  @override
  String get refresh => 'Оновити';

  @override
  String get refreshAll => 'Оновити все';

  @override
  String get refreshAllFeeds => 'Оновити всі стрічки';

  @override
  String get reject => 'Відхилити';

  @override
  String get rejected => 'Відхилено';

  @override
  String get reload => 'Перезавантажити';

  @override
  String get remove => 'Видалити';

  @override
  String get removeBookmark => 'Видалити закладку';

  @override
  String get removeEmbeddingModel => 'Видалити модель ембедингів?';

  @override
  String get removeLogo => 'Видалити логотип';

  @override
  String get removeRepoFromWorkspace =>
      'Видалити репозиторій із робочого простору?';

  @override
  String get removeVoiceModel => 'Видалити голосову модель?';

  @override
  String get removed => 'Видалено';

  @override
  String get renamed => 'Перейменовано';

  @override
  String get reopen => 'Відкрити знову';

  @override
  String get resolve => 'Розв\'язати';

  @override
  String get replyEllipsis => 'Відповісти…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name буде видалено з цього робочого простору. Локальні файли на диску не змінюються.';
  }

  @override
  String repoAccessNoticeBody(String repos) {
    return 'Облікові дані GitHub сервера не бачать $repos. Якщо репозиторій належить організації, встановіть GitHub App там або підключіть токен із доступом.';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Немає доступу до $count репозиторіїв',
      many: 'Немає доступу до $count репозиторіїв',
      few: 'Немає доступу до $count репозиторіїв',
      one: 'Немає доступу до репозиторію',
    );
    return '$_temp0';
  }

  @override
  String get repoAccessNoticeSuspendedTitle =>
      'Встановлення GitHub App призупинено';

  @override
  String repoAccessNoticeSuspendedBody(String repos) {
    return 'Показано останні відомі дані для $repos. Відновіть встановлення на GitHub або підключіть токен із доступом.';
  }

  @override
  String get repoNoAccessBadge => 'Немає доступу';

  @override
  String get reportsTo => 'Керівник';

  @override
  String reposCount(int count) {
    return 'Репозиторії ($count)';
  }

  @override
  String get reposDescription =>
      'Локальні копії, з якими працює цей робочий простір.';

  @override
  String get repositories => 'Репозиторії';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count репозиторіїв',
      many: '$count репозиторіїв',
      few: '$count репозиторії',
      one: '1 репозиторій',
    );
    return 'Не вдалося додати $_temp0: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count репозиторіїв додано',
      many: '$count репозиторіїв додано',
      few: '$count репозиторії додано',
      one: 'Репозиторій додано',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'Налаштування репозиторіїв';

  @override
  String get repositoryName => 'Назва репозиторію';

  @override
  String get requestChanges => 'Запросити зміни';

  @override
  String get requested => 'Запитано';

  @override
  String get requestedChanges => 'Запитані зміни';

  @override
  String requiredRoleLabel(String role) {
    return 'Обов\'язкова роль: $role';
  }

  @override
  String get requiredRoleOptional => 'Обов\'язкова роль (необов\'язково)';

  @override
  String get requirements => 'Вимоги';

  @override
  String get reset => 'Скинути';

  @override
  String get resolved => 'Розв\'язано';

  @override
  String get enclosedTerminalTitle => 'Вбудований термінал';

  @override
  String get enclosedTerminalStart => 'Відкрити shell';

  @override
  String get enclosedTerminalStartHint =>
      'Цей shell працює в одноразовій VM цієї розмови. Він запускається, коли ви його відкриваєте, а не під час старту програми.';

  @override
  String get terminalStreamReconnecting =>
      'потік перервано — повторне з\'єднання…';

  @override
  String get terminalStreamError => 'помилка потоку:';

  @override
  String get terminalShellExited => 'shell завершився';

  @override
  String get restartShell => 'Перезапустити shell';

  @override
  String get retry => 'Повторити';

  @override
  String get review => 'Рев\'ю';

  @override
  String get reviewedByMe => 'Перевірені мною';

  @override
  String get reviewers => 'Рев\'юери';

  @override
  String get roleLabel => 'Роль';

  @override
  String get ruleHint => 'Правило політики (підтримується markdown)';

  @override
  String get ruleLabel => 'Правило';

  @override
  String get runCompleted => 'Запуск завершено';

  @override
  String get running => 'Виконується';

  @override
  String get runningLabel => 'виконується';

  @override
  String get runs => 'Запуски';

  @override
  String get runsLabel => 'Запуски';

  @override
  String get sandboxBackendNativeLabel => 'Нативна пісочниця';

  @override
  String get sandboxBackendMicrovmLabel => 'Ізольована VM';

  @override
  String get sandboxBackendNoneLabel => 'Без ізоляції';

  @override
  String get sandboxLinuxInstall =>
      'Нативна пісочниця на Linux/WSL2 використовує bubblewrap. Встановіть так:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'Нативна пісочниця вбудована в macOS — використовує Apple Seatbelt (`sandbox-exec`). Встановлення не потрібне.';

  @override
  String get sandboxPermissions => 'Дозволи пісочниці';

  @override
  String get sandboxUnsupported =>
      'Нативна пісочниця ще не підтримується на цій платформі. Застосовується «Без ізоляції».';

  @override
  String get sandboxingDisabledDescription =>
      'Агенти виконуються безпосередньо на хості з повним середовищем — не рекомендовано.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Усі виклики агентів проходять через $backend.';
  }

  @override
  String get save => 'Зберегти';

  @override
  String get saveChanges => 'Зберегти зміни';

  @override
  String get adapterArguments => 'Додаткові аргументи';

  @override
  String get adapterArgumentsHint => 'Додаткові CLI-прапорці (напр. --yolo)';

  @override
  String get addVariable => 'Додати змінну';

  @override
  String get environmentVariables => 'Змінні середовища';

  @override
  String get environmentVariablesDescription =>
      'Користувацькі змінні середовища для цього адаптера (напр. ключі API). Зберігаються у зв’язці ключів.';

  @override
  String get variableKey => 'Ключ';

  @override
  String get variableValue => 'Значення';

  @override
  String get savingEllipsis => 'Збереження…';

  @override
  String get scopeDiffToCommits =>
      'Обмежити diff комітами — Shift-клік для діапазону';

  @override
  String get noPrsMatchSearch => 'Немає відповідних pull request';

  @override
  String get searchFactsHint => 'Шукати факти...';

  @override
  String get searchFonts => 'Шукати шрифти…';

  @override
  String get searchGifs => 'Шукати GIF';

  @override
  String get searchGifsHint => 'Шукати GIF...';

  @override
  String get searchInDiffHint => 'Шукати в diff…';

  @override
  String get searchOrTypeModel => 'Шукати або ввести назву моделі…';

  @override
  String get searchPlaceholder => 'Пошук…';

  @override
  String get searchShortcuts => 'Шукати скорочення…';

  @override
  String get shortcutUnavailableInBrowser => 'Недоступно в браузері';

  @override
  String get searching => 'Пошук…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count секунд тому',
      many: '$count секунд тому',
      few: '$count секунди тому',
      one: '$count секунду тому',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Вибрати адаптер';

  @override
  String get selectAdapterFirst => 'Спочатку виберіть адаптер';

  @override
  String get selectAgentToReportTo => 'Вибрати агента для звіту…';

  @override
  String get selectAnAgent => 'Вибрати агента';

  @override
  String get selectConversation => 'Вибрати розмову';

  @override
  String get selectLabel => 'Вибрати';

  @override
  String get selectRunner => 'Вибрати runner';

  @override
  String get semanticSearch => 'Семантичний пошук';

  @override
  String get send => 'Надіслати';

  @override
  String get sendFirstMessage => 'Надіслати перше повідомлення';

  @override
  String get sendMessage => 'Надіслати повідомлення';

  @override
  String sentFindingsToAgent(int count) {
    return 'Надіслано $count знахідки агенту.';
  }

  @override
  String setGithubLinkDescription(String name) {
    return 'Укажіть власника та назву репозиторію GitHub для $name. Це потрібно, щоб розпізнавати посилання на PR і issue на кшталт #123 у markdown.';
  }

  @override
  String get setLabel => 'Задати';

  @override
  String get setToken => 'Задати токен';

  @override
  String get settingsLabel => 'Налаштування';

  @override
  String get settingsLanguage => 'Мова';

  @override
  String get settingsLanguageDescription => 'Виберіть мову застосунку.';

  @override
  String get shortTask => 'Коротке завдання';

  @override
  String get showNativeNotifications =>
      'Показувати системні сповіщення про події.';

  @override
  String get showSuperseded => 'Показувати замінені';

  @override
  String get signedIn => 'Вхід виконано.';

  @override
  String signedInAs(String username) {
    return 'Ви увійшли як $username.';
  }

  @override
  String get skillNameRequired => 'Потрібна назва скіла.';

  @override
  String skillSaved(String name) {
    return 'Скіл «$name» збережено.';
  }

  @override
  String get skillsSourcesTab => 'Джерела';

  @override
  String get skillSourcesDisclaimer =>
      'Скіли встановлюються з доданих репозиторіїв GitHub. Метадані репозиторію ненадійні — справжній сигнал безпеки дає антивірусне сканування.';

  @override
  String get skillSourcesEmpty => 'Немає репозиторіїв скілів';

  @override
  String get skillSourcesEmptyHint =>
      'Додайте репозиторій GitHub, щоб переглянути його скіли.';

  @override
  String get skillSourceAdd => 'Додати репозиторій';

  @override
  String get skillSourceAddTitle => 'Додати репозиторій скілів';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      'Введіть URL репозиторію GitHub (https://github.com/owner/repo).';

  @override
  String skillSourceAdded(String repo) {
    return 'Репозиторій $repo додано.';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'Репозиторій $repo уже додано.';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'Репозиторій $repo вилучено.';
  }

  @override
  String get skillSourceRemove => 'Вилучити';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return 'Вилучити $repo?';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'Установлені скіли залишаться. Вилучається лише каталог репозиторію.';

  @override
  String get skillSourceNoSkills =>
      'У цьому репозиторії немає скілів (скіл — це каталог із файлом SKILL.md).';

  @override
  String get skillSourceRefresh => 'Оновити';

  @override
  String get skillSourceInstalledBadge => 'Установлено';

  @override
  String get skillSourceUpdateBadge => 'Є оновлення';

  @override
  String get skillSourceSlugTaken => 'Назва зайнята';

  @override
  String skillSourceFilesCount(num count) {
    return '$count files';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'У цього скіла немає README.';

  @override
  String get skillSourceNoMatches => 'Жоден скіл не відповідає фільтру.';

  @override
  String get skillUpdateAction => 'Оновити';

  @override
  String get skillUninstallAction => 'Видалити';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return 'Видалити «$slug»?';
  }

  @override
  String skillUninstalled(String slug) {
    return 'Скіл «$slug» видалено.';
  }

  @override
  String get skillFindingLine => 'рядок';

  @override
  String get skillInstallAnywayOverride =>
      'Я розумію ризик — установити все одно';

  @override
  String skillInstalled(String slug) {
    return 'Скіл «$slug» установлено.';
  }

  @override
  String get skillPreviewCapabilities => 'Можливості';

  @override
  String get skillPreviewFindings => 'Виявлення';

  @override
  String get skillPreviewGuardedActions => 'Захищені дії';

  @override
  String get skillPreviewLlmReviewed => 'Перевірено LLM';

  @override
  String get skillPreviewNoCapabilities => 'Можливості не оголошено.';

  @override
  String get skillPreviewNoFindings => 'Виявлень немає.';

  @override
  String get skillPreviewScanning => 'Сканування скіла…';

  @override
  String get skillPreviewVerdictLabel => 'Вердикт сканування';

  @override
  String get skillPreviewVerdictPass => 'Пройдено';

  @override
  String get skillPreviewVerdictQuarantine => 'На карантині';

  @override
  String get skillPreviewVerdictWarn => 'Попередження';

  @override
  String get skillQuarantineWarning =>
      'Сканер помістив цей скіл на карантин. Установлення запускає код на вашому комп’ютері. Продовжуйте лише якщо довіряєте джерелу й переглянули виявлення.';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'На карантині й від’єднано від агентів: $agents';
  }

  @override
  String get skillNotScanned => 'Не скановано';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'Вручну';

  @override
  String get skillOriginRegistry => 'Реєстр';

  @override
  String get skillOriginRuntimeLocal => 'Локальний runtime';

  @override
  String get skillRulesStale => 'Сканування застаріле';

  @override
  String get skillSaveAnywayOverride => 'Я розумію ризик — зберегти все одно';

  @override
  String get skillSaveBlockedBody => 'Вміст заблоковано до запису.';

  @override
  String get skillSaveBlockedTitle =>
      'Збереження заблоковано шлюзом сканування';

  @override
  String get skillScanAction => 'Сканувати';

  @override
  String get skillScanAll => 'Сканувати все';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass пройдено · $warn попереджень · $quarantine в карантині';
  }

  @override
  String get skillStateDrifted => 'Змінено після встановлення';

  @override
  String get skillStateUnmanaged => 'Некерований';

  @override
  String get skillSeverityBlocked => 'Заблоковано';

  @override
  String get skillSeverityWarn => 'Попередження';

  @override
  String get skillsInstalledTab => 'Встановлені';

  @override
  String get skills => 'Навички';

  @override
  String get skipAcceptRisk => 'Пропустити — я приймаю ризик';

  @override
  String get skipForNow => 'Пропустити наразі';

  @override
  String get skipSandboxing => 'Пропустити пісочницю';

  @override
  String get skipSandboxingDialogContent =>
      'Ви впевнені, що хочете пропустити пісочницю? Це дозволить агентам виконувати код у вашій системі без ізоляції.';

  @override
  String get somethingWentWrong => 'Щось пішло не так';

  @override
  String sourceCount(int count) {
    return '$count джерело';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count джерел';
  }

  @override
  String get sourceFacts => 'Факти джерел:';

  @override
  String get splitDiff => 'Розділений diff (поряд)';

  @override
  String get startLabel => 'Запустити';

  @override
  String get startOnAppLaunch => 'Запускати разом із додатком';

  @override
  String get statusLabel => 'Статус';

  @override
  String get onboardingStepConnect => 'Підключення';

  @override
  String get onboardingStepWorkspace => 'Робочий простір';

  @override
  String get onboardingStepSandbox => 'Пісочниця';

  @override
  String get onboardingStepAdapter => 'Адаптер';

  @override
  String get onboardingStepVoice => 'Голос';

  @override
  String get stop => 'Зупинити';

  @override
  String get stopped => 'Зупинено';

  @override
  String get strictIdentityCheck => 'Сувора перевірка ідентичності';

  @override
  String get success => 'Успіх';

  @override
  String get successLabel => 'Успіх';

  @override
  String get suggestAChange => 'Запропонувати зміну';

  @override
  String get suggestLabel => 'Пропозиція';

  @override
  String get superseded => 'Замінено';

  @override
  String get synced => 'Синхронізовано';

  @override
  String get systemDefault => 'Системне за замовчуванням';

  @override
  String get systemFonts => 'Системні шрифти';

  @override
  String get systemPrompt => 'Системний промпт';

  @override
  String get systemPromptLabel => 'Системний промпт';

  @override
  String get talkToControlCenter => 'Говоріть із Control Center.';

  @override
  String get taskMentionSection => 'Завдання';

  @override
  String get testLabel => 'Тест';

  @override
  String get theme => 'Тема';

  @override
  String get themeDark => 'Темна';

  @override
  String get themeLight => 'Світла';

  @override
  String get themeSystem => 'Системна';

  @override
  String get thisCannotBeUndone => 'Цю дію не можна скасувати.';

  @override
  String get ticketLabel => 'Тікет';

  @override
  String get titleLabel => 'Назва';

  @override
  String get todayLabel => 'Сьогодні';

  @override
  String get toggleTheme => 'Перемкнути тему';

  @override
  String get tokenConfigured =>
      'Налаштовано — клієнти мають надавати цей токен.';

  @override
  String get topic => 'Тема';

  @override
  String get topicHint => 'напр. стек технологій, дизайн-система';

  @override
  String get totalRuns => 'Усього запусків';

  @override
  String trackingParamsCount(int count) {
    return '$count tracking params';
  }

  @override
  String get typeCommandOrSearch => 'Введіть команду або шукайте…';

  @override
  String get typography => 'Типографіка';

  @override
  String get unavailable => 'Недоступно';

  @override
  String get unifiedDiff => 'Уніфікований diff';

  @override
  String get unknownAuthor => 'Невідомий';

  @override
  String get unnamedAgent => 'Безіменний агент';

  @override
  String get updateKey => 'Оновити ключ';

  @override
  String get updateLabel => 'Оновити';

  @override
  String get updateToken => 'Оновити токен';

  @override
  String updatedDaysAgo(int count) {
    return 'Оновлено $count д. тому';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'Оновлено $count год. тому';
  }

  @override
  String get updatedJustNow => 'Оновлено щойно';

  @override
  String updatedMinutesAgo(int count) {
    return 'Оновлено $count хв. тому';
  }

  @override
  String get useSandbox => 'Використовувати пісочницю';

  @override
  String get useWorkspaceDefault => 'Типовий для робочого простору';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'Залиште порожнім, щоб використовувати типовий User-Agent застосунку. Деякі сайти блокують небраузерні User-Agent.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Використовується системний мікрофон за замовчуванням.';

  @override
  String get viewLabel => 'Перегляд';

  @override
  String get viewLogs => 'Переглянути логи';

  @override
  String voiceInstallFailed(String error) {
    return 'Не вдалося встановити: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Не встановлено. Одноразове завантаження ~200 МБ; працює повністю на пристрої.';

  @override
  String get voiceModelNotInstalledLabel => 'Голосову модель не встановлено.';

  @override
  String get voiceRedownloadBody =>
      'Наявні файли моделі буде видалено, і архів ~200 МБ завантажиться знову. Голосова транскрипція буде недоступна, доки завантаження не завершиться.';

  @override
  String get voiceRemoveBody =>
      'Голосову транскрипцію буде вимкнено, доки ви не встановите її знову. Встановити можна будь-коли.';

  @override
  String get voiceTranscription => 'Голосова транскрипція';

  @override
  String get weakIsolationDescription =>
      'Слабка ізоляція — лише межа простору імен, без межі ядра.';

  @override
  String get whenOffNoDefaultRoute =>
      'Коли вимкнено, пісочниця запускається без маршруту за замовчуванням.';

  @override
  String get whenOffServerStaysStopped =>
      'Коли вимкнено, сервер залишається зупиненим, доки ви його не запустите.';

  @override
  String get speechModel => 'Модель мовлення';

  @override
  String get speechModelHint =>
      'Використовується для транскрипції зустрічей і мікрофона композера.';

  @override
  String get voiceModelInstalled =>
      'Встановлено. Забезпечує транскрипцію зустрічей і кнопку мікрофона в композері.';

  @override
  String get meetingMicSilentWarning =>
      'Мікрофон, можливо, вимкнено — інші говорять, але сигнал не надходить на ваш мікрофон.';

  @override
  String get meetingSummaryPrivacyNotice =>
      'Запис і транскрипція залишаються на цьому комп’ютері. Підсумок пише агент, тож якщо він використовує хмарну модель, транскрипт і нотатки надсилаються цьому провайдеру.';

  @override
  String get meetingTemplates => 'Шаблони нотаток зустрічі';

  @override
  String get meetingTemplatesHint =>
      'Налаштуйте ШІ-підсумок під тип зустрічі. Активний шаблон застосовується до нових і повторно згенерованих підсумків.';

  @override
  String get meetingTemplateActive => 'Активний шаблон';

  @override
  String get meetingTemplateAdd => 'Додати шаблон';

  @override
  String get meetingTemplateNewTitle => 'Новий шаблон';

  @override
  String get meetingTemplateEditTitle => 'Редагувати шаблон';

  @override
  String get meetingTemplateNameLabel => 'Назва';

  @override
  String get meetingTemplateNameHint => 'напр. огляд спринту';

  @override
  String get meetingTemplateInstructionsLabel => 'Інструкції';

  @override
  String get meetingTemplateInstructionsHint =>
      'Як ШІ має структурувати й акцентувати ці нотатки?';

  @override
  String get workingMemory => 'Робоча пам’ять';

  @override
  String get workspaceName => 'Назва робочого простору';

  @override
  String get workspaceScopedSkills =>
      'Файли навичок робочого простору, прикріплені до агентів.';

  @override
  String get workspaces => 'Робочі простори';

  @override
  String get writePrivateNotes =>
      'Пишіть приватні нотатки, спостереження, плани...';

  @override
  String get writeSkillContent => 'Напишіть вміст навички тут (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count років тому',
      many: '$count років тому',
      few: '$count роки тому',
      one: '$count рік тому',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Вчора';

  @override
  String get focusModeStart => 'Почати сеанс фокусування';

  @override
  String get focusModeConfigTitle => 'Почати сеанс фокусування';

  @override
  String get focusModeGoalLabel => 'Мета';

  @override
  String get focusModeGoalHint => 'Над чим ви працюєте?';

  @override
  String get focusModeDurationLabel => 'Тривалість';

  @override
  String get focusModeBlockNotifications => 'Блокувати сповіщення';

  @override
  String get focusModeStartButton => 'Почати';

  @override
  String get focusModeFloat => 'Згорнути на панель';

  @override
  String get focusModeActiveTooltip =>
      'Режим фокусування активний — натисніть, щоб завершити';

  @override
  String get dismiss => 'Відхилити';

  @override
  String get acceptAndResolve => 'Прийняти й вирішити';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'Ви вже $minutes хв. робите рев’ю — дослідження показують, що якість може падати після 60 хв. Варто зробити перерву.';
  }

  @override
  String get notificationSound => 'Звук сповіщень';

  @override
  String get notificationSoundDescription =>
      'Звук, який відтворюється під час показу сповіщення.';

  @override
  String get notificationSoundNone => 'Немає';

  @override
  String get notificationSoundPing => 'Пінг';

  @override
  String get notificationSoundChime => 'Передзвін';

  @override
  String get notificationSoundPop => 'Поп';

  @override
  String get notificationSoundDing => 'Дінг';

  @override
  String get notificationSoundWhoosh => 'Шурхіт';

  @override
  String get notificationSoundMigrosSoft => 'Migros (м’який)';

  @override
  String get notificationSoundMigrosHard => 'Migros (жорсткий)';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => 'Тест';

  @override
  String get notificationVolume => 'Гучність';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Немає PR від @$login у цьому робочому просторі';
  }

  @override
  String get usersLabel => 'Користувачі';

  @override
  String get mergePullRequest => 'Злити pull request';

  @override
  String get forceMergePullRequest => 'Примусово злити pull request';

  @override
  String get closePullRequest => 'Закрити pull request';

  @override
  String get closePullRequestConfirm => 'Справді закрити цей pull request?';

  @override
  String get stackedPullRequests => 'Стек pull request';

  @override
  String partOfStack(int position, int total) {
    return 'Частина стека ($position з $total)';
  }

  @override
  String get createStack => 'Створити стек';

  @override
  String get createStackDialogTitle => 'Створити стек pull request';

  @override
  String createStackDialogBody(int count) {
    return 'Ці $count pull request буде зібрано в стек знизу вгору:';
  }

  @override
  String get createStackInvalidSelection =>
      'Виберіть принаймні два pull request з одного репозиторію, щоб створити стек';

  @override
  String get createStackNotAChain =>
      'Вибрані pull request не утворюють ланцюжок: базова гілка кожного має бути гілкою head попереднього';

  @override
  String get createStackAlreadyStacked =>
      'Один або кілька вибраних pull request уже в стеку';

  @override
  String get stackCreated => 'Стек створено';

  @override
  String get stackCreationFailed => 'Не вдалося створити стек';

  @override
  String get squashAndMerge => 'Стиснути й злити';

  @override
  String get createMergeCommit => 'Створити коміт злиття';

  @override
  String get rebaseAndMerge => 'Перебазувати й злити';

  @override
  String get commitTitle => 'Заголовок коміту';

  @override
  String get commitDescription => 'Опис коміту';

  @override
  String get pullRequestMerged => 'Pull request злито';

  @override
  String get pullRequestClosed => 'Pull request закрито';

  @override
  String failedToMergePr(String error) {
    return 'Не вдалося злити: $error';
  }

  @override
  String failedToClosePr(String error) {
    return 'Не вдалося закрити: $error';
  }

  @override
  String get markReadyForReview => 'Готово до перегляду';

  @override
  String get markReadyForReviewConfirm =>
      'Цей pull request вийде з чернетки. Рецензентів буде сповіщено, обов’язкові перевірки почнуть блокувати злиття, і запуститься автоматизація, що очікує готові pull request.';

  @override
  String get convertToDraft => 'Перетворити на чернетку';

  @override
  String get convertToDraftConfirm =>
      'Цей pull request знову стане чернеткою. Запити на рецензування буде відхилено, і його не можна буде злити, доки ви знову не позначите його готовим.';

  @override
  String get pullRequestMarkedReady =>
      'Pull request позначено готовим до перегляду';

  @override
  String get pullRequestConvertedToDraft =>
      'Pull request перетворено на чернетку';

  @override
  String failedToMarkPrReady(String error) {
    return 'Не вдалося позначити готовим до перегляду: $error';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'Не вдалося перетворити на чернетку: $error';
  }

  @override
  String get checksFailing => 'Перевірки не проходять';

  @override
  String get reviewsPending => 'Деякі рецензії ще очікуються';

  @override
  String get mergeConflictsWithBase =>
      'У цій гілці є конфлікти, які потрібно розв’язати';

  @override
  String get branchOutOfDateWithBase => 'Ця гілка відстає від базової гілки';

  @override
  String get mergeBlockedByBranchProtection => 'Захист гілки блокує це злиття';

  @override
  String get confirm => 'Підтвердити';

  @override
  String get trustedSitesSectionTitle => 'Довірені сайти';

  @override
  String get trustedSitesEmpty =>
      'Немає довірених сайтів. Додайте домен, щоб вимкнути блокування для нього.';

  @override
  String get addTrustedSite => 'Додати довірений сайт';

  @override
  String get removeTrustedSite => 'Видалити';

  @override
  String get disableBlockingForThisSite => 'Вимкнути блокування на цьому сайті';

  @override
  String get enableBlockingForThisSite => 'Увімкнути блокування на цьому сайті';

  @override
  String get enterDomainHint => 'напр. example.com';

  @override
  String get invalidDomain => 'Введіть дійсний домен (напр. example.com)';

  @override
  String get pageLoadTimedOut =>
      'Час завантаження сторінки вичерпано. Перезавантажте або відкрийте в браузері.';

  @override
  String get pipelinesScreenTitle => 'Конвеєри';

  @override
  String get pipelinesScreenSubtitle =>
      'Декларативні багатокрокові робочі процеси агентів';

  @override
  String get pipelinesRunPipeline => 'Запустити конвеєр';

  @override
  String get pipelineRunLauncherTitle => 'Запустити конвеєр';

  @override
  String get pipelineRunSubtitle =>
      'Оберіть конвеєр і заповніть його входи, щоб почати запуск.';

  @override
  String get pipelineRunNoInputsBadge => 'Немає входів';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count входу',
      many: '$count входів',
      few: '$count входи',
      one: '1 вхід',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'Цей конвеєр не потребує входів.';

  @override
  String get pipelineRunSubmit => 'Запустити конвеєр';

  @override
  String get pipelineRunCouldNotStart => 'Не вдалося почати запуск.';

  @override
  String pipelineRunStarted(String name) {
    return 'Запущено $name';
  }

  @override
  String get pipelineRunEmptyTitle => 'Немає конвеєрів, готових до запуску';

  @override
  String get pipelineRunEmptyHint =>
      'Увімкніть конвеєр і ручний запуск у його редакторі, щоб запускати його тут.';

  @override
  String get pipelineRunManageTemplates => 'Керувати конвеєрами';

  @override
  String get pipelineRunSettingsTitle => 'Ручний запуск';

  @override
  String get pipelineRunSettingsAllow => 'Дозволити ручний запуск';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Показувати цей конвеєр на сторінці запуску, щоб його можна було запускати вручну.';

  @override
  String get pipelineRunSettingsConcurrencyTitle => 'Паралельність';

  @override
  String get pipelineRunSettingsMaxParallel => 'Макс. паралельних запусків';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'Залиште порожнім для необмеженої кількості. Додаткові запуски чекають у черзі й стартують, коли звільняються слоти.';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'Необмежено';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      'Введіть ціле число від 1 або залиште порожнім для необмеженої кількості.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Входи';

  @override
  String get pipelineRunSettingsAddInput => 'Додати вхід';

  @override
  String get pipelineRunSettingsNoInputs => 'Ще немає входів.';

  @override
  String get pipelineInputEditTitle => 'Поле вводу';

  @override
  String get pipelineInputKeyLabel => 'Ключ';

  @override
  String get pipelineInputKeyHelp =>
      'Ключ стану, під яким зберігається значення (напр. repo_full_name).';

  @override
  String get pipelineInputLabelLabel => 'Мітка';

  @override
  String get pipelineInputTypeLabel => 'Тип';

  @override
  String get pipelineInputOptionsLabel => 'Варіанти (через кому)';

  @override
  String get pipelineInputDefaultLabel => 'Значення за замовчуванням';

  @override
  String get pipelineInputPlaceholderLabel => 'Підказка';

  @override
  String get pipelineInputHelpLabel => 'Текст довідки';

  @override
  String get pipelineInputRequiredLabel => 'Обов’язкове';

  @override
  String get pipelineInputTypeText => 'Текст';

  @override
  String get pipelineInputTypeMultiline => 'Багаторядковий текст';

  @override
  String get pipelineInputTypeNumber => 'Число';

  @override
  String get pipelineInputTypeBoolean => 'Перемикач';

  @override
  String get pipelineInputTypeSelect => 'Список';

  @override
  String get pipelinesEmpty => 'Ще немає запусків конвеєрів';

  @override
  String get pipelinesEmptyHint => 'Натисніть «Запустити конвеєр», щоб почати.';

  @override
  String get pipelinesNoSteps => 'Ще немає записаних кроків';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Оберіть робочий простір, щоб переглянути його конвеєри';

  @override
  String pipelinesLoadError(String error) {
    return 'Не вдалося завантажити конвеєри: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Не вдалося запустити конвеєр: $error';
  }

  @override
  String get pipelineStatusPending => 'Очікування';

  @override
  String get pipelineStatusQueued => 'У черзі';

  @override
  String get pipelineStatusRunning => 'Виконується';

  @override
  String get pipelineStatusSuspended => 'Призупинено';

  @override
  String get pipelineStatusCompleted => 'Завершено';

  @override
  String get pipelineStatusFailed => 'Помилка';

  @override
  String get pipelineStatusCancelled => 'Скасовано';

  @override
  String get pipelineStatusSkipped => 'Пропущено';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed з $total кроків';
  }

  @override
  String get pipelineWaterfallTimeline => 'Хронологія';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'Активно $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'простоювання $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'Час, виключений з активного підсумку: запуск було зупинено або він очікував між кроками.';

  @override
  String get pipelineStepStarted => 'Почато';

  @override
  String get pipelineStepFinished => 'Завершено';

  @override
  String get pipelineStepDurationLabel => 'Тривалість';

  @override
  String get pipelineStepBranch => 'Гілка';

  @override
  String get pipelineStepViewConversation => 'Переглянути розмову';

  @override
  String get pipelineStepError => 'Помилка';

  @override
  String get pipelineStepInput => 'Вхід';

  @override
  String get pipelineStepOutput => 'Вихід';

  @override
  String get pipelineStepNotExecuted => 'Ще не виконано';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Збій на $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Вручну';

  @override
  String get pipelineStepSkippedReason => 'Пропущено';

  @override
  String get pipelineStepPriorAttempts => 'Попередні спроби';

  @override
  String get pipelineStepAttemptLabel => 'Спроба';

  @override
  String pipelineStepAttemptN(int number) {
    return 'Спроба $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'Перервано';

  @override
  String get pipelineRunColumnPipeline => 'Конвеєр';

  @override
  String get pipelineRunColumnDuration => 'Тривалість';

  @override
  String get pipelineRunQueueNext => 'Наступний';

  @override
  String pipelineRunQueuePosition(int position) {
    return '$position у черзі';
  }

  @override
  String get pipelineRunColumnStarted => 'Почато';

  @override
  String get pipelineRunHistory => 'Історія запусків';

  @override
  String get pipelineRunHistoryEmpty => 'Інших запусків ще немає';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'Повторний запуск $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return 'Спроба $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'уперше почато $time';
  }

  @override
  String get pipelineRunFilterAll => 'Усі';

  @override
  String get pipelineRunFilterEmpty => 'Немає запусків за цим фільтром';

  @override
  String get relativeJustNow => 'щойно';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count хв тому',
      many: '$count хв тому',
      few: '$count хв тому',
      one: '1 хв тому',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count годин тому',
      many: '$count годин тому',
      few: '$count години тому',
      one: '1 годину тому',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count днів тому',
      many: '$count днів тому',
      few: '$count дні тому',
      one: '1 день тому',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'Команди';

  @override
  String get teamsAddTeam => 'Додати команду';

  @override
  String get teamsLoadError => 'Не вдалося завантажити команди';

  @override
  String get teamsEmptyTitle => 'Команд ще немає';

  @override
  String get teamsEmptyDescription =>
      'Об\'єднуйте агентів у команди, щоб призначена команді робота проходила через лідера, який делегує.';

  @override
  String get teamCreateTitle => 'Нова команда';

  @override
  String get teamEditTitle => 'Редагувати команду';

  @override
  String get teamNameLabel => 'Назва команди';

  @override
  String get teamNameHint => 'напр. Frontend';

  @override
  String get teamDescriptionLabel => 'Опис';

  @override
  String get teamDescriptionHint => 'За що відповідає ця команда';

  @override
  String get teamLeaderLabel => 'Лідер';

  @override
  String get teamLeaderHelp =>
      'Координатор, який отримує призначену команді роботу й делегує її найвідповіднішому учаснику.';

  @override
  String get teamNoLeader => 'Без лідера';

  @override
  String get teamInstructionsLabel => 'Інструкції роботи';

  @override
  String get teamInstructionsHelp =>
      'Додається до брифінгу лідера — командні правила, ескалація, тон.';

  @override
  String get teamInstructionsHint => 'Необов\'язково';

  @override
  String get teamSaved => 'Команду збережено';

  @override
  String get teamMembersError => 'Не вдалося завантажити учасників';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count учасників',
      many: '$count учасників',
      few: '$count учасники',
      one: '1 учасник',
      zero: 'Немає учасників',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'Додати учасника';

  @override
  String get teamAddMemberTitle => 'Додати учасників';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count',
      one: 'Add 1',
      zero: 'Add',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => 'Усі агенти вже в цій команді.';

  @override
  String get teamRemoveMember => 'Вилучити з команди';

  @override
  String get teamLeaderBadge => 'Лідер';

  @override
  String get teamUnknownAgent => 'Невідомий агент';

  @override
  String get teamMembersEmpty => 'Ще немає учасників';

  @override
  String get teamMembersEmptyDescription =>
      'Додайте агентів, щоб лідер мав кому делегувати.';

  @override
  String get teamSelectPrompt => 'Виберіть команду';

  @override
  String get teamSelectPromptDescription =>
      'Виберіть команду зі списку або створіть нову.';

  @override
  String get teamDeleteTitle => 'Видалити команду?';

  @override
  String teamDeleteBody(String name) {
    return '$name буде видалено. Агенти команди не зміняться.';
  }

  @override
  String get teamHasLeaderTooltip => 'Є лідер';

  @override
  String get pipelineTemplatesNav => 'Шаблони конвеєрів';

  @override
  String get pipelineTemplatesTitle => 'Шаблони конвеєрів';

  @override
  String get pipelineTemplatesSubtitle =>
      'Редактор із перетягуванням для конвеєрів, які оркеструють ваших агентів.';

  @override
  String get pipelineTemplatesNew => 'Новий шаблон';

  @override
  String get pipelineTemplatesEmpty =>
      'Ще немає шаблонів конвеєрів. Створіть перший, щоб почати.';

  @override
  String get pipelineTemplateBuiltInBadge => 'Вбудований';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Видалити шаблон?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Видалити шаблон конвеєра $name? Цю дію не можна скасувати.';
  }

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Перетягніть типи вузлів із бічної панелі на полотно, потім з’єднайте їх.';

  @override
  String get unsavedChanges => 'Незбережені зміни';

  @override
  String get nodeLibraryTitle => 'Бібліотека вузлів';

  @override
  String get nodeLibraryHint =>
      'Перетягніть елемент на полотно, щоб додати вузол.';

  @override
  String get editorEmptyCanvas =>
      'Перетягніть вузол із бібліотеки, щоб почати.';

  @override
  String get pipelineWhenThisHappens => 'Коли це відбувається';

  @override
  String get pipelineDoThis => 'Зробити це';

  @override
  String get pipelineAddStep => 'Додати крок';

  @override
  String get pipelineTidyUp => 'Упорядкувати схему';

  @override
  String get pipelineEditorHint =>
      'Перетягніть кроки, щоб розташувати · перетягніть маркер, щоб з’єднати';

  @override
  String get pipelineRemoveConnection => 'Видалити з’єднання';

  @override
  String get pipelineDragToConnect => 'Перетягніть, щоб з’єднати';

  @override
  String get pipelineNewDefaultName => 'Новий конвеєр';

  @override
  String get nodeCategoryTriggers => 'Тригери';

  @override
  String get triggerEventWebhook => 'Webhook';

  @override
  String get pipelineAddTrigger => 'Додати тригер';

  @override
  String get pipelineOnEvent => 'За подією';

  @override
  String get nodeConfigTitle => 'Конфігурація вузла';

  @override
  String get nodeConfigKind => 'Тип';

  @override
  String get nodeConfigLabel => 'Мітка';

  @override
  String get nodeConfigAgent => 'Агент';

  @override
  String get nodeConfigAgentHint => 'Виберіть агента…';

  @override
  String get nodeConfigInputKeys => 'Ключі входу (через кому)';

  @override
  String get nodeConfigInputKeysHelp =>
      'Ключі стану, які споживає цей вузол. Використовуються для підстановки плейсхолдерів у промпті.';

  @override
  String get nodeConfigRepos => 'Репозиторії для клонування';

  @override
  String get nodeConfigReposHelp =>
      'Репозиторії клонуються й індексуються, коли цей вузол починає розмову. Вибір усіх репозиторіїв клонує їх усі (за замовчуванням).';

  @override
  String get nodeConfigRepoBranchHint => 'Гілка (за замовчуванням)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'Гілка, від якої створюється кожен checkout. Залиште порожнім для стандартної гілки репозиторію — робоче дерево все одно отримає власну гілку, тож коміти агента сюди не потраплять.';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'Збережено динамічних записів: $entries';
  }

  @override
  String get nodeConfigCreateConversation => 'Відкрити в ньому розмову';

  @override
  String get nodeConfigCreateConversationHelp =>
      'Залиште вимкненим, якщо далі кілька вузлів агентів — кожен відкриває власний іменований стрім. Увімкніть, якщо далі один вузол агента, щоб у кімнаті не з’являлася розмова без назви поруч.';

  @override
  String get nodeConfigConversationTitle => 'Назва розмови';

  @override
  String get nodeConfigConversationTitleHelp =>
      'Дайте наступному вузлу агента ту саму назву — обидва працюватимуть в одному стрімі. За замовчуванням — мітка вузла.';

  @override
  String get nodeConfigSpaceName => 'Назва простору';

  @override
  String get nodeConfigSpaceNameHelp =>
      'Назва кімнати, яку відкриває цей вузол. Підтримує ті самі плейсхолдери стану, що й промпт. Залиште порожнім, щоб використати мітку вузла.';

  @override
  String get nodeConfigSpaceNameHint => 'Огляд pr_number';

  @override
  String get nodeConfigStreamTitle => 'Назва розмови';

  @override
  String get nodeConfigStreamTitleHelp =>
      'Іменований стрім, у якому агент цього вузла працює в кімнаті. Підтримує ті самі плейсхолдери стану, що й промпт. Якщо залишити порожнім, хід потрапить у постійну розмову кімнати, де розгалуження чергує всіх агентів.';

  @override
  String get nodeConfigConversationTitleHint => 'Аналіз архітектури';

  @override
  String get nodeConfigOutputKey => 'Ключ виходу';

  @override
  String get nodeConfigPrompt => 'Шаблон промпту';

  @override
  String get nodeConfigPromptHelp =>
      'Використовуйте плейсхолдери з подвійними дужками, щоб підставляти значення зі стану під час виконання.';

  @override
  String get nodeConfigScript => 'Bash-скрипт';

  @override
  String get nodeConfigScriptHelp =>
      'Запускається через bash -c. GITHUB_TOKEN задано. Плейсхолдери підставляються перед виконанням.';

  @override
  String get nodeConfigRouteKeys => 'Ключі маршруту';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Ключ маршруту від $source';
  }

  @override
  String get conditionSectionTitle => 'Умова';

  @override
  String get conditionMode => 'Режим';

  @override
  String get conditionModeFilesAny => 'Файл(и) існують — будь-який';

  @override
  String get conditionModeFilesAll => 'Файли існують — усі';

  @override
  String get conditionModeComparison => 'Порівняння';

  @override
  String get conditionModeSwitch => 'Перемикач';

  @override
  String get conditionFilePaths => 'Шляхи до файлів';

  @override
  String get conditionFilePathsAnyHelp =>
      'Один шлях на рядок, відносно базового каталогу. Істина, якщо існує хоча б один.';

  @override
  String get conditionFilePathsAllHelp =>
      'Один шлях на рядок, відносно базового каталогу. Істина лише якщо існують усі.';

  @override
  String get conditionBaseKey => 'Ключ базового каталогу';

  @override
  String get conditionBaseKeyHelp =>
      'Ключ стану з каталогом, відносно якого розв’язуються шляхи (за замовчуванням repo_local_path).';

  @override
  String get conditionRecursive => 'Шукати в підкаталогах';

  @override
  String get conditionNegate => 'Інверсія: істина, якщо немає';

  @override
  String get conditionLeft => 'Ліве значення';

  @override
  String get conditionOperator => 'Оператор';

  @override
  String get conditionRight => 'Праве значення';

  @override
  String get conditionSwitchKey => 'Перемикач за ключем стану';

  @override
  String get conditionCases => 'Варіанти (через кому)';

  @override
  String get conditionCasesHelp =>
      'Ключі маршрутів для зіставлення зі значенням, у заданому порядку.';

  @override
  String get conditionDefaultCase => 'Варіант за замовчуванням';

  @override
  String get triggerManualHelp =>
      'Показати на сторінці запуску й запускати вручну.';

  @override
  String get triggerKindSchedule => 'За розкладом';

  @override
  String get triggerScheduleExprLabel => 'Розклад (cron або every:seconds)';

  @override
  String get triggerTimezoneLabel => 'Часовий пояс (необов’язково)';

  @override
  String get triggerCatchUpLabel => 'Пропущені запуски';

  @override
  String get triggerCatchUpRunOnce => 'Запустити один раз';

  @override
  String get triggerCatchUpSkip => 'Пропустити';

  @override
  String get syncHealthTitle => 'Стан синхронізації';

  @override
  String get syncHealthNoConfigs => 'Ще немає підключень синхронізації';

  @override
  String get syncHealthNeverSynced => 'Ще не синхронізовано';

  @override
  String get syncOutcomeOk => 'Синхронізовано';

  @override
  String get syncOutcomeFailed => 'Помилка';

  @override
  String get syncOutcomeSkipped => 'Пропущено';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count помилок поспіль';
  }

  @override
  String get triggerWebhookHelp =>
      'Генерується підписаний URL webhook. Зовнішні системи надсилають POST, щоб запустити цей конвеєр.';

  @override
  String get triggerWebhookPathLabel => 'Шлях вебхука';

  @override
  String get triggerMatchStatusLabel => 'Лише коли статус';

  @override
  String get triggerSummaryNone => 'Немає тригерів';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Кожні $seconds с';
  }

  @override
  String get triggerEventManual => 'Ручний запуск';

  @override
  String get triggerEventSchedule => 'Розклад';

  @override
  String get triggerEventPrStatusChanged => 'Змінено статус PR';

  @override
  String get triggerEventExternalPr => 'Відкрито зовнішній PR';

  @override
  String get triggerEventPrPublished => 'PR опубліковано';

  @override
  String get triggerEventPrMerged => 'PR злито';

  @override
  String get triggerEventRepoAdded => 'Додано репозиторій';

  @override
  String get triggerEventCodeGraphWatch => 'Зміна файлу';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count змінених файлів',
      many: '$count змінених файлів',
      few: '$count змінені файли',
      one: '$count змінений файл',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '+$count ще';
  }

  @override
  String get pipelineRunCauseRescan => 'Змінено на диску';

  @override
  String get pipelineRunCauseInitial => 'Перша індексація цього checkout';

  @override
  String get triggerEventMessageReceived => 'Отримано повідомлення';

  @override
  String get triggerEventTicketCompleted => 'Тікет завершено';

  @override
  String get triggerEventTicketFailed => 'Тікет завершився помилкою';

  @override
  String get triggerEventTicketCancelled => 'Тікет скасовано';

  @override
  String get triggerEventBudgetCrossed => 'Перетнуто поріг бюджету';

  @override
  String get nodeLibrarySearchHint => 'Пошук вузлів';

  @override
  String get nodeLibraryNoMatches => 'Немає відповідних вузлів';

  @override
  String get nodeCategoryFlow => 'Потік і логіка';

  @override
  String get nodeCategoryPr => 'Перегляд PR';

  @override
  String get nodeCategoryAgents => 'Агенти';

  @override
  String get nodeCategoryMessaging => 'Повідомлення';

  @override
  String get nodeCategoryCode => 'Код';

  @override
  String get triggerDisabledTag => 'вимк.';

  @override
  String get pipelineInputTypeRepo => 'Репозиторій';

  @override
  String get pipelineRunNoRepos =>
      'У цьому робочому просторі ще немає репозиторіїв.';

  @override
  String get allowTicketingApi => 'Дозволити виклики ticketing API';

  @override
  String get ticketingApiKey => 'Ключ ticketing API';

  @override
  String get ticketingApiKeySubtitle =>
      'Підставляє ключ API провайдера тікетів у пісочницю.';

  @override
  String get ticketingProvider => 'Провайдер тікетів';

  @override
  String get connectGitHubAndTicketing =>
      'Підключіть хост коду, щоб Control Center міг читати ваші pull requests, issues і reviews. За бажанням підключіть провайдера тікетів. Облікові дані зберігаються на вашому сервері, а не на цій машині.';

  @override
  String get triggerEventTicketAssigned => 'Тікет призначено';

  @override
  String get triggerEventTicketCreated => 'Тікет створено';

  @override
  String get triggerEventTicketStatusChanged => 'Статус тікета змінено';

  @override
  String get triggerEventMeetingRecordingStopped => 'Запис зустрічі зупинено';

  @override
  String get triggerEventSkillUpdated => 'Навичку оновлено';

  @override
  String get triggerEventSpaceDeleted => 'Простір видалено';

  @override
  String get triggerExternalPrHelp =>
      'Pull request, відкритий на хості коду, а не з Control Center.';

  @override
  String get triggerPrPublishedHelp =>
      'Pull request, відкритий із Control Center або агентом.';

  @override
  String get triggerPrStatusChangedHelp =>
      'Злитий, закритий, відкритий, знову відкритий або схвалений. Фільтруйте за статусом в інспекторі.';

  @override
  String get triggerPrMergedHelp =>
      'Лише коли pull request зливають, не коли закривають чи відкривають знову.';

  @override
  String get triggerRepoAddedHelp =>
      'Репозиторій пов’язується з цим робочим простором.';

  @override
  String get triggerCodeGraphWatchHelp =>
      'Файл у пов’язаному репозиторії змінюється на диску.';

  @override
  String get triggerMessageReceivedHelp =>
      'У простір надходить нове повідомлення.';

  @override
  String get triggerTicketCreatedHelp =>
      'У цьому робочому просторі створюється тікет.';

  @override
  String get triggerTicketStatusChangedHelp =>
      'Тікет переходить між статусами.';

  @override
  String get triggerTicketCompletedHelp => 'Тікет успішно завершується.';

  @override
  String get triggerTicketFailedHelp =>
      'Запуск агента не вдався, і тікет позначено як невдалий.';

  @override
  String get triggerTicketCancelledHelp =>
      'Тікет скасовується і не продовжиться.';

  @override
  String get triggerBudgetCrossedHelp =>
      'Перевищено ліміт витрат робочого простору або агента.';

  @override
  String get triggerTicketAssignedHelp =>
      'Тікет призначається особі, агенту або команді.';

  @override
  String get triggerMeetingRecordingStoppedHelp =>
      'Запис зустрічі закінчується.';

  @override
  String get triggerSkillUpdatedHelp => 'Навичку встановлюють або оновлюють.';

  @override
  String get triggerSpaceDeletedHelp => 'Простір розмови видаляється.';

  @override
  String get navTickets => 'Тікети';

  @override
  String get ticketsTitle => 'Тікети';

  @override
  String get newTicket => 'Новий тікет';

  @override
  String get noTicketsYet => 'Тікетів ще немає';

  @override
  String get addCollaborator => 'Додати співавтора';

  @override
  String get noCollaborators => 'Співавторів ще немає';

  @override
  String get linkedPullRequests => 'Пов’язані pull requests';

  @override
  String get noLinkedPullRequests => 'Пов’язаних pull requests ще немає';

  @override
  String get stopAgent => 'Зупинити агент';

  @override
  String get ticketProperties => 'Властивості';

  @override
  String get ticketTabIssue => 'Issue';

  @override
  String get ticketSelectPrompt => 'Виберіть тікет, щоб переглянути деталі';

  @override
  String get unassigned => 'Не призначено';

  @override
  String get ticketStatusBacklog => 'Беклог';

  @override
  String get ticketStatusOpen => 'До виконання';

  @override
  String get ticketStatusInProgress => 'У роботі';

  @override
  String get ticketStatusInReview => 'На перегляді';

  @override
  String get ticketStatusDone => 'Готово';

  @override
  String get ticketStatusBlocked => 'Заблоковано';

  @override
  String get ticketStatusFailed => 'Невдало';

  @override
  String get ticketStatusCancelled => 'Скасовано';

  @override
  String get notificationTicketAssigned => 'Тікет призначено';

  @override
  String get notificationTicketStatusChanged => 'Статус тікета змінено';

  @override
  String get priority => 'Пріоритет';

  @override
  String get status => 'Статус';

  @override
  String get assignee => 'Виконавець';

  @override
  String get labels => 'Мітки';

  @override
  String get noLabelsYet => 'Міток ще немає';

  @override
  String get clearLabels => 'Очистити мітки';

  @override
  String get pipelineStepAgentActivity => 'Активність агента';

  @override
  String get runStatusCompleted => 'Завершено';

  @override
  String get runStatusQueued => 'У черзі';

  @override
  String get ticketDescription => 'Опис';

  @override
  String get ticketPriorityNone => 'Немає';

  @override
  String get ticketPriorityUrgent => 'Терміновий';

  @override
  String get ticketPriorityHigh => 'Високий';

  @override
  String get ticketPriorityMedium => 'Середній';

  @override
  String get ticketPriorityLow => 'Низький';

  @override
  String get ticketViewList => 'Список';

  @override
  String get ticketViewBoard => 'Дошка';

  @override
  String get ticketTitlePlaceholder => 'Назва issue';

  @override
  String get ticketDescriptionPlaceholder => 'Додати опис…';

  @override
  String get createMore => 'Створити ще';

  @override
  String selectedCount(int count) {
    return '$count вибрано';
  }

  @override
  String get clearSelection => 'Очистити вибір';

  @override
  String get bulkDeleteTitle => 'Видалити тікети';

  @override
  String bulkDeleteMessage(int count) {
    return 'Видалити $count вибраних тікетів? Цю дію не можна скасувати.';
  }

  @override
  String get assignTo => 'Призначити…';

  @override
  String get sectionMembers => 'Учасники';

  @override
  String get sectionAgents => 'Агенти';

  @override
  String get sidebarGroupWorkspace => 'Робочий простір';

  @override
  String get notificationsTitle => 'Сповіщення';

  @override
  String get notificationsTooltip => 'Сповіщення';

  @override
  String get notificationsEmpty => 'Усе переглянуто';

  @override
  String notificationsUnreadCount(int count) {
    return '$count непрочитаних';
  }

  @override
  String get notificationsMarkRead => 'Позначити як прочитане';

  @override
  String get notificationsMarkUnread => 'Позначити як непрочитане';

  @override
  String get notificationsEntryActions => 'Дії зі сповіщенням';

  @override
  String get markAllRead => 'Позначити все як прочитане';

  @override
  String get teamsNav => 'Команди';

  @override
  String get noWorkspace => 'Немає робочого простору';

  @override
  String get selectWorkspace => 'Виберіть робочий простір';

  @override
  String get navMemory => 'Пам\'ять';

  @override
  String get memoryTabFacts => 'Факти';

  @override
  String get memoryTabPolicies => 'Політики';

  @override
  String get memoryGraphShowFacts => 'Показати факти';

  @override
  String get memoryGraphHideFacts => 'Сховати факти';

  @override
  String get memoryGraphExpandAll => 'Розгорнути всі факти';

  @override
  String get memoryGraphCollapseAll => 'Згорнути всі факти';

  @override
  String get memoryTabGraph => 'Граф знань';

  @override
  String get memoryNoWorkspace =>
      'Виберіть робочий простір, щоб переглянути його пам\'ять.';

  @override
  String get searchArticles => 'Пошук статей';

  @override
  String get filterAll => 'Усі';

  @override
  String get filterUnread => 'Непрочитані';

  @override
  String get filterSaved => 'Збережені';

  @override
  String get saveArticle => 'Зберегти статтю';

  @override
  String get removeFromSaved => 'Вилучити зі збережених';

  @override
  String get filterBySource => 'Фільтр за джерелом';

  @override
  String get viewAsList => 'Список';

  @override
  String get viewAsGrid => 'Сітка';

  @override
  String get noMatchingArticles => 'Немає відповідних статей';

  @override
  String get noMatchingArticlesBody =>
      'Спробуйте інший пошук або фільтр джерела.';

  @override
  String get allCaughtUp => 'Усе переглянуто';

  @override
  String get allCaughtUpBody =>
      'Немає непрочитаних статей — загляньте пізніше.';

  @override
  String get openArticlesInAppDescription =>
      'Відкривати посилання у вбудованому читачі замість стандартного браузера.';

  @override
  String get blockAdsTrackersDescription =>
      'Прибирати рекламу, трекери та банери cookies зі статей, відкритих у читачі.';

  @override
  String get agentQuestionHeader => 'Питання до вас';

  @override
  String get agentQuestionAnsweredLabel => 'Відповідь надано';

  @override
  String get agentQuestionFreeformHint => 'Введіть відповідь…';

  @override
  String agentQuestionProgress(int index, int count) {
    return 'Питання $index з $count';
  }

  @override
  String get agentQuestionSkip => 'Пропустити';

  @override
  String get agentQuestionSkippedLabel => 'Пропущено';

  @override
  String get agentQuestionFreeformOptionHint => 'Опишіть своїми словами…';

  @override
  String get reviewRequested => 'Запит на рев\'ю';

  @override
  String get connectGitHubHint =>
      'Увійдіть у GitHub або додайте токен у Налаштування → Робочий простір → Профіль і ідентичність → Хостинг коду';

  @override
  String get connectGitHubToLoadPrs =>
      'Підключіть GitHub, щоб завантажити pull requests';

  @override
  String get noRepositoriesConfigured => 'Репозиторії не налаштовано';

  @override
  String openedAgo(String age) {
    return 'Відкрито $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author відкрив цей pull request';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count комітами',
      many: '$count комітами',
      few: '$count комітами',
      one: '$count комітом',
    );
    return '$author відкрив цей pull request з $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor запросив рев\'ю в $reviewers';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor скасував запит на рев\'ю для $reviewers';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor запросив рев\'ю в $requested і скасував запит на рев\'ю для $removed';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'мітки',
      one: 'мітку',
    );
    return '$actor додав $_temp0 $labels';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'мітки',
      one: 'мітку',
    );
    return '$actor видалив $_temp0 $labels';
  }

  @override
  String prTimelineAddedAndRemovedLabels(
    String actor,
    String added,
    int addedCount,
    String removed,
    int removedCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      addedCount,
      locale: localeName,
      other: 'мітки',
      one: 'мітку',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: 'мітки',
      one: 'мітку',
    );
    return '$actor додав $_temp0 $added і видалив $_temp1 $removed';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author зробив коміт';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count комітів',
      many: '$count комітів',
      few: '$count коміти',
      one: '$count коміт',
    );
    return '$author опублікував $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author схвалив ці зміни';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author запросив зміни';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count коментарів до коду',
      many: '$count коментарів до коду',
      few: '$count коментарі до коду',
      one: '$count коментар до коду',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author переглянув';
  }

  @override
  String get prTimelineSomeone => 'Хтось';

  @override
  String get prTimelineBotBadge => 'бот';

  @override
  String updatedAgo(String age) {
    return 'Оновлено $age';
  }

  @override
  String get checksPassing => 'Перевірки проходять';

  @override
  String get checksRunning => 'Перевірки виконуються';

  @override
  String get needsYourReview => 'Потрібен ваш перегляд';

  @override
  String get checks => 'Перевірки';

  @override
  String get noReviewersAssigned => 'Рецензентів не призначено';

  @override
  String get noAssignees => 'Виконавців не призначено';

  @override
  String get loadingEllipsis => 'Завантаження…';

  @override
  String get loadingChecks => 'Завантаження перевірок…';

  @override
  String get noChecksYet => 'Перевірки ще не запускалися';

  @override
  String get noChangesToReview => 'Немає змін для рев’ю';

  @override
  String checksFailingCount(int count) {
    return '$count не пройдено';
  }

  @override
  String get showMore => 'Показати більше';

  @override
  String get showLess => 'Показати менше';

  @override
  String get backToPullRequests => 'Назад до pull requests';

  @override
  String get pullRequestNotFound => 'Pull request не знайдено';

  @override
  String get pullRequestNotFoundBody =>
      'Можливо, його злито, закрито або переміщено.';

  @override
  String get couldntLoadPullRequest =>
      'Не вдалося завантажити цей pull request';

  @override
  String get showDetails => 'Показати деталі';

  @override
  String get noDescriptionProvided => 'Опис не надано.';

  @override
  String get factsHint => 'Факти з’являться тут, коли ваші агенти навчаться.';

  @override
  String get noFactsMatch => 'Немає фактів за вашим пошуком';

  @override
  String get memoryLoadError => 'Не вдалося завантажити пам’ять';

  @override
  String get sortRecent => 'Нещодавні';

  @override
  String get sortConfidence => 'Упевненість';

  @override
  String get confidenceTooltip =>
      'Наскільки агенти впевнені, що цей факт правдивий, від 0 до 100%.';

  @override
  String get supersededTooltip => 'Новіший факт замінив цей.';

  @override
  String get domain => 'Домен';

  @override
  String get fitToView => 'Вмістити в екран';

  @override
  String get project => 'Проєкт';

  @override
  String get newProject => 'Новий проєкт';

  @override
  String get editProject => 'Редагувати проєкт';

  @override
  String get deleteProject => 'Видалити проєкт';

  @override
  String get noProject => 'Без проєкту';

  @override
  String get allTickets => 'Усі тікети';

  @override
  String get projectNamePlaceholder => 'Назва проєкту';

  @override
  String get projectDescriptionPlaceholder => 'Опис (необов’язково)';

  @override
  String get projectColorLabel => 'Колір';

  @override
  String get noProjectsYet => 'Проєктів ще немає';

  @override
  String get projectTicketsEmpty => 'У цьому проєкті ще немає тікетів';

  @override
  String get createProject => 'Створити проєкт';

  @override
  String projectProgress(int done, int total) {
    return '$done з $total виконано';
  }

  @override
  String deleteProjectConfirm(String name) {
    return 'Видалити «$name»? Його тікети збережуться й будуть прибрані з проєкту.';
  }

  @override
  String get projectStatusActive => 'Активний';

  @override
  String get projectStatusCompleted => 'Завершений';

  @override
  String get projectStatusArchived => 'Архівований';

  @override
  String get markProjectCompleted => 'Позначити завершеним';

  @override
  String get markProjectActive => 'Позначити активним';

  @override
  String get archiveProject => 'Архівувати';

  @override
  String get restoreProject => 'Відновити';

  @override
  String get relations => 'Зв’язки';

  @override
  String get relateTo => 'Пов’язати з';

  @override
  String get relationSubIssueOf => 'Підзадача для…';

  @override
  String get relationParentOf => 'Батьківський для…';

  @override
  String get relationBlockedBy => 'Заблоковано…';

  @override
  String get relationBlocking => 'Блокує…';

  @override
  String get relationRelatedTo => 'Пов’язано з…';

  @override
  String get relationDuplicateOf => 'Дублікат…';

  @override
  String get relationGroupParent => 'Батьківський';

  @override
  String get relationGroupSubIssues => 'Підтікети';

  @override
  String get relationGroupBlockedBy => 'Заблоковано';

  @override
  String get relationGroupBlocking => 'Блокує';

  @override
  String get relationGroupRelated => 'Пов’язані';

  @override
  String get relationGroupDuplicateOf => 'Дублікат';

  @override
  String get relationGroupDuplicatedBy => 'Дубльовано';

  @override
  String get copyId => 'Копіювати ID';

  @override
  String get ticketIdCopied => 'ID тікета скопійовано';

  @override
  String get searchTicketsHint => 'Шукати тікети…';

  @override
  String get noMatchingTickets => 'Немає відповідних тікетів';

  @override
  String get clearAll => 'Очистити все';

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PR очікують',
      many: '$prs PR очікують',
      few: '$prs PR очікують',
      one: '1 PR очікує',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos репозиторіях',
      many: '$repos репозиторіях',
      few: '$repos репозиторіях',
      one: '1 репозиторії',
    );
    return '$_temp0 вашого рев’ю в $_temp1';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'Перейменуйте робочий простір і змініть його позначку — виберіть його ліворуч, щоб редагувати.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count робочих просторів',
      many: '$count робочих просторів',
      few: '$count робочі простори',
      one: '1 робочий простір',
      zero: 'Немає робочих просторів',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos репозиторіїв',
      many: '$repos репозиторіїв',
      few: '$repos репозиторії',
      one: '1 репозиторій',
      zero: 'Немає репозиторіїв',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents агентів',
      many: '$agents агентів',
      few: '$agents агенти',
      one: '1 агент',
      zero: '0 агентів',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'Ідентичність';

  @override
  String get uploadImage => 'Завантажити зображення';

  @override
  String get failedToSaveLogo =>
      'Не вдалося зберегти зображення логотипа. Переконайтеся, що програма може прочитати вибраний файл.';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG або GIF до 2 МБ. Інакше використаємо ініціал робочого простору.';

  @override
  String get workspaceNameFieldHelp =>
      'Відображається в перемикачі, у шляху навігації та на кожному екрані.';

  @override
  String get dangerZone => 'Небезпечна зона';

  @override
  String get deleteThisWorkspace => 'Видалити цей робочий простір';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Остаточно видаляє $name, його підключення репозиторіїв, агентів і пам’ять. Цю дію не можна скасувати.';
  }

  @override
  String get discard => 'Відкинути';

  @override
  String discardChangesQuestion(String name) {
    return 'Відкинути незбережені зміни в $name?';
  }

  @override
  String get workspaceUpdated => 'Робочий простір оновлено';

  @override
  String get editTitle => 'Редагувати заголовок';

  @override
  String get editDescription => 'Редагувати опис';

  @override
  String get addDescription => 'Додати опис';

  @override
  String get prTitlePlaceholder => 'Заголовок';

  @override
  String get prBodyPlaceholder => 'Залиште опис';

  @override
  String get write => 'Написати';

  @override
  String get overview => 'Огляд';

  @override
  String get noFilesChanged => 'Немає змінених файлів';

  @override
  String get diff => 'Різниця';

  @override
  String get preview => 'Попередній перегляд';

  @override
  String get imageDiffBefore => 'До';

  @override
  String get imageDiffAfter => 'Після';

  @override
  String get imageDiffModeTwoUp => 'Поруч';

  @override
  String get imageDiffModeSwipe => 'Свайп';

  @override
  String get imageDiffModeDifference => 'Різниця';

  @override
  String imageDiffChangedPercent(String percent) {
    return 'змінено $percent%';
  }

  @override
  String get imageDiffPictures => 'Зображення';

  @override
  String get imageDiffSource => 'Джерело';

  @override
  String get imageDiffDeleted => 'Видалено';

  @override
  String get imageDiffAdded => 'Додано';

  @override
  String imageDiffDimensions(int width, int height) {
    return 'Ш: ${width}px | В: ${height}px';
  }

  @override
  String get outdated => 'Застаріло';

  @override
  String get outdatedComments => 'Застарілі коментарі';

  @override
  String outdatedCountLabel(int count) {
    return '$count застарілих';
  }

  @override
  String get prTemplateLabel => 'Шаблон';

  @override
  String get prTemplateDefault => 'Типовий';

  @override
  String get addReviewers => 'Додати рецензентів';

  @override
  String get addAssignees => 'Додати виконавців';

  @override
  String get searchUsers => 'Шукати людей…';

  @override
  String get searchReviewers => 'Шукати людей і команди…';

  @override
  String get usersSectionLabel => 'Люди';

  @override
  String get userStatusBusy => 'Зайнято';

  @override
  String get teamsSectionLabel => 'Команди';

  @override
  String get suggestedReviewers => 'Запропоновані рецензенти';

  @override
  String get noMatchingUsers => 'Немає відповідних людей';

  @override
  String get noMatchingReviewers => 'Немає збігів';

  @override
  String get requiredByCodeOwners => 'Обов’язково за code owners';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'через $login';
  }

  @override
  String get team => 'Команда';

  @override
  String get markdownBold => 'Жирний';

  @override
  String get markdownItalic => 'Курсив';

  @override
  String get markdownHeading => 'Заголовок';

  @override
  String get markdownBulletList => 'Маркований список';

  @override
  String get markdownChecklist => 'Чекліст';

  @override
  String get markdownCode => 'Код';

  @override
  String get markdownLink => 'Посилання';

  @override
  String get markdownQuote => 'Цитата';

  @override
  String get markdownSupported => 'Підтримується Markdown';

  @override
  String get markdownAttachImages => 'Натисніть, щоб додати зображення';

  @override
  String failedToUpdateTitle(String error) {
    return 'Не вдалося оновити назву: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Не вдалося оновити опис: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Не вдалося оновити рецензентів: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Не вдалося оновити виконавців: $error';
  }

  @override
  String get discardChangesConfirm => 'Відхилити зміни?';

  @override
  String get newPr => 'Новий PR';

  @override
  String get openPullRequest => 'Відкрити pull request';

  @override
  String get composePrSubtitle =>
      'З гілки, яку ви вже надіслали — без агентів і тікетів';

  @override
  String get createAsDraft => 'Створити як чернетку';

  @override
  String get composePrNoRepo => 'Не вибрано репозиторій GitHub';

  @override
  String get composePrNoRepoHint =>
      'Виберіть робочий простір із репозиторієм, пов’язаним із GitHub, щоб відкрити pull request.';

  @override
  String get composePrPickBranches =>
      'Виберіть базову та порівнювану гілки, щоб переглянути зміни.';

  @override
  String get composePrNothingToCompare => 'Між цими гілками немає змін.';

  @override
  String get repository => 'Репозиторій';

  @override
  String get baseBranchLabel => 'База';

  @override
  String get compareBranchLabel => 'Порівняння';

  @override
  String get selectBranch => 'Виберіть гілку';

  @override
  String get navMeetings => 'Зустрічі';

  @override
  String get meetingsNoWorkspace =>
      'Виберіть робочий простір, щоб побачити зустрічі.';

  @override
  String get meetingsEmpty => 'Ще немає зустрічей';

  @override
  String get meetingsEmptyHint =>
      'Запишіть першу зустріч — аудіо залишається на цьому пристрої, а агент перетворює його на нотатки, рішення та пункти дій.';

  @override
  String get meetingNotesHint =>
      'Занотуйте коротко — агент розгорне нотатки після зустрічі.';

  @override
  String get meetingSpeakerMe => 'Ви';

  @override
  String get meetingStatusRecording => 'Запис';

  @override
  String get meetingStatusProcessing => 'Обробка';

  @override
  String get meetingStatusDone => 'Готово';

  @override
  String get meetingStatusFailed => 'Помилка';

  @override
  String get meetingsSubtitle =>
      'Записується й транскрибується на цьому пристрої, потім агент робить підсумок.';

  @override
  String get meetingsRecordMeeting => 'Записати зустріч';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count обробляються зараз',
      many: '$count обробляються зараз',
      few: '$count обробляються зараз',
      one: '1 обробляється зараз',
    );
    return '$_temp0';
  }

  @override
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count зустрічі',
      many: '$count зустрічей',
      few: '$count зустрічі',
      one: '1 зустріч',
      zero: 'Немає зустрічей',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'Відкриті пункти дій';

  @override
  String get meetingsLedgerDecisions => 'Рішення';

  @override
  String get meetingsLiveOpen => 'Відкрити запис';

  @override
  String get meetingTemplateShort => 'Шаблон';

  @override
  String get meetingsStatThisWeek => 'Цього тижня';

  @override
  String get meetingsStatRecorded => 'Записано';

  @override
  String get meetingsFilterAll => 'Усі';

  @override
  String get meetingsFilterDone => 'Готово';

  @override
  String get meetingsFilterProcessing => 'Обробка';

  @override
  String get meetingsSearchHint => 'Фільтр за назвою, особою, додатком…';

  @override
  String get meetingsBucketToday => 'Сьогодні';

  @override
  String get meetingsBucketYesterday => 'Вчора';

  @override
  String get meetingsBucketEarlierThisWeek => 'Раніше цього тижня';

  @override
  String get meetingsBucketLastWeek => 'Минулого тижня';

  @override
  String get meetingsBucketOlder => 'Раніше';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count рішення',
      many: '$count рішень',
      few: '$count рішення',
      one: '1 рішення',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total пунктів дій';
  }

  @override
  String get meetingsEnhancedPill => 'покращено';

  @override
  String get meetingsTranscribing => 'транскрибування й підсумок…';

  @override
  String get meetingsOpenAction => 'Відкрити';

  @override
  String get meetingsStopProcessing => 'Зупинити';

  @override
  String get meetingsStillTranscribing =>
      'Триває транскрибування — підсумок з’явиться після завершення.';

  @override
  String get meetingsNoMatch => 'Немає відповідних зустрічей';

  @override
  String get meetingsNoMatchHint =>
      'Спробуйте інший фільтр або пошуковий запит.';

  @override
  String get meetingBackAllMeetings => 'Усі зустрічі';

  @override
  String get meetingReRunSummary => 'Повторити підсумок';

  @override
  String get meetingExport => 'Експорт';

  @override
  String get meetingAugmentingBanner =>
      'Доповнюємо ваші нотатки з транскрипту — витягуємо рішення та пункти дій…';

  @override
  String get meetingTabNotes => 'Нотатки';

  @override
  String get meetingTabTranscript => 'Транскрипт';

  @override
  String get meetingTabActionItems => 'Пункти дій';

  @override
  String get meetingTabDecisions => 'Рішення';

  @override
  String get meetingNotesEnhancedToggle => 'Покращені';

  @override
  String get meetingNotesYoursToggle => 'Ваші нотатки';

  @override
  String get meetingEnhancedByAgent => 'Покращено агентом · з транскрипту';

  @override
  String get meetingEnhancedPending => 'Агент ще працює над цим підсумком.';

  @override
  String get meetingNotesEmpty => 'Поки немає покращених нотаток.';

  @override
  String get meetingNotesSavedLocally => 'Збережено локально';

  @override
  String get meetingNotesSaving => 'Збереження…';

  @override
  String get meetingViewFullTranscript => 'Переглянути повний транскрипт';

  @override
  String get meetingTranscriptSearchHint => 'Пошук у транскрипті…';

  @override
  String get meetingSpeakerEveryone => 'Усі';

  @override
  String get meetingSpeakerOthers => 'Інші';

  @override
  String get meetingTranscriptEmpty => 'Поки немає транскрипту.';

  @override
  String get meetingActionItemsEmpty => 'Не витягнуто пунктів дій.';

  @override
  String get meetingActionItemFrom => 'з цієї зустрічі';

  @override
  String get meetingCreateTicket => 'Створити тікет';

  @override
  String meetingTicketCreated(String key) {
    return 'Тікет $key створено й надіслано.';
  }

  @override
  String get meetingTicketFailed => 'Не вдалося створити тікет.';

  @override
  String get meetingDecisionsEmpty => 'Не зафіксовано рішень.';

  @override
  String get meetingEditTitle => 'Редагувати назву';

  @override
  String get meetingTitleLabel => 'Назва';

  @override
  String get meetingAddActionItem => 'Додати пункт дій';

  @override
  String get meetingEditActionItem => 'Редагувати пункт дій';

  @override
  String get meetingDeleteActionItem => 'Видалити пункт дій';

  @override
  String get meetingActionItemContentLabel => 'Пункт дій';

  @override
  String get meetingActionItemContentHint => 'Що потрібно зробити?';

  @override
  String get meetingActionItemOwnerLabel => 'Відповідальний';

  @override
  String get meetingActionItemOwnerHint => 'Хто відповідає? (необов’язково)';

  @override
  String get meetingAddDecision => 'Додати рішення';

  @override
  String get meetingEditDecision => 'Редагувати рішення';

  @override
  String get meetingDeleteDecision => 'Видалити рішення';

  @override
  String get meetingDecisionContentLabel => 'Рішення';

  @override
  String get meetingDecisionContentHint => 'Що вирішили?';

  @override
  String get meetingReRunStarted =>
      'Повторно запускаємо підсумовування транскрипту…';

  @override
  String get meetingReRunNoTranscript => 'Поки немає транскрипту для підсумку.';

  @override
  String get meetingExportCopied =>
      'Нотатки скопійовано в буфер обміну як Markdown.';

  @override
  String get meetingExportSaved => 'Зустріч експортовано.';

  @override
  String meetingExportFailed(String error) {
    return 'Не вдалося експортувати: $error';
  }

  @override
  String get meetingExportNothing => 'Поки немає що експортувати.';

  @override
  String get meetingPlaybackPlay => 'Відтворити';

  @override
  String get meetingPlaybackPause => 'Пауза';

  @override
  String get meetingPlaybackUnavailable =>
      'Відтворення аудіо недоступне на цьому пристрої.';

  @override
  String get meetingDetectedTitle => 'Виявлено зустріч';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'Схоже, триває «$label». Записати?';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'Схоже, триває зустріч. Записати?';

  @override
  String get meetingDetectedRecord => 'Записати';

  @override
  String get meetingDetectedDismiss => 'Відхилити';

  @override
  String get meetingAutoStopTitle =>
      'Схоже, зустріч завершилася. Зупинити запис?';

  @override
  String get meetingAutoStopStop => 'Зупинити';

  @override
  String get meetingAutoStopKeep => 'Продовжити запис';

  @override
  String get meetingAutoDetect => 'Автовиявлення зустрічей';

  @override
  String get meetingAutoDetectDescription =>
      'Стежити за календарем і програмами для конференцій і пропонувати запис, коли починається зустріч.';

  @override
  String get meetingsRecordingCrumb => 'Запис…';

  @override
  String get meetingRecordTitleHint => 'Назва зустрічі';

  @override
  String get meetingRecordTappingLabel => 'Захоплення:';

  @override
  String get meetingRecordMic => 'Мікрофон';

  @override
  String get meetingRecordSystemAudio => 'Системне аудіо';

  @override
  String get meetingRecordPause => 'Пауза';

  @override
  String get meetingRecordResume => 'Продовжити';

  @override
  String get meetingRecordStop => 'Зупинити й підсумувати';

  @override
  String get meetingRecordYourNotes => 'Ваші нотатки';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Пишіть, поки слухаєте. Кілька уривків достатньо — після зупинки агент розгорне їх за транскриптом.';

  @override
  String get meetingRecordLiveTranscript => 'Транскрипт наживо';

  @override
  String get meetingRecordDecoding => 'декодування на пристрої';

  @override
  String get meetingRecordListening =>
      'Слухаю… мова з’явиться тут за секунду-дві, з мітками Ви / Інші.';

  @override
  String get meetingRecordPausedHint =>
      'На паузі — аудіо ігнорується, доки не продовжите.';

  @override
  String get meetingRecordNotActive => 'Немає активного запису.';

  @override
  String get meetingHudRecording => 'запис';

  @override
  String get meetingHudPaused => 'пауза';

  @override
  String get meetingHudOpen => 'Відкрити';

  @override
  String get meetingHudStop => 'Зупинити';

  @override
  String get meetingToolbarPopOut => 'Відкріпити';

  @override
  String get meetingToolbarHoldToStop => 'Утримуйте, щоб зупинити запис';

  @override
  String get meetingToolbarSemanticLabel => 'Панель запису зустрічі';

  @override
  String get orchestrate => 'Оркеструвати';

  @override
  String get orchestrationUnavailable => 'Оркестрація недоступна';

  @override
  String get orchestrationApprove => 'Затвердити план';

  @override
  String get orchestrationReject => 'Відхилити';

  @override
  String get orchestrationCancel => 'Скасувати оркестрацію';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count ролей — $hires нових наймів';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count підтікетів';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Орієнтовна вартість: \$$amount';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total підтікетів виконано';
  }

  @override
  String get orchestrationStatusProposed => 'Запропоновано';

  @override
  String get orchestrationStatusApproved => 'Затверджено';

  @override
  String get orchestrationStatusExecuting => 'Виконується';

  @override
  String get orchestrationStatusSynthesizing => 'Синтез';

  @override
  String get orchestrationStatusCompleted => 'Завершено';

  @override
  String get orchestrationStatusFailed => 'Не вдалося';

  @override
  String get orchestrationStatusCancelled => 'Скасовано';

  @override
  String get messageFailed => 'Запуск не вдався';

  @override
  String get turnLimitReached =>
      'Зупинено на ліміті ходів — дайте відповідь, щоб продовжити';

  @override
  String get retried => 'Повторно';

  @override
  String replyingTo(String name) {
    return 'відповідь для $name';
  }

  @override
  String get silenceTimeoutLabel => 'Тайм-аут тиші (хвилини)';

  @override
  String get silenceTimeoutHint =>
      'напр. 15 — зупинити запуск після цього часу без виводу';

  @override
  String get capabilityJsonMode => 'Режим JSON';

  @override
  String get capabilityModelSelection => 'Вибір моделі';

  @override
  String get transcriptThinking => 'Думаю…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'Міркував $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'Вношу зміни…';

  @override
  String get transcriptStatusReadingFiles => 'Читаю файли…';

  @override
  String get transcriptStatusSearching => 'Шукаю в кодовій базі…';

  @override
  String get transcriptStatusRunningCommands => 'Виконую команди…';

  @override
  String get transcriptStatusResponding => 'Відповідаю…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'Виконую $tool…';
  }

  @override
  String get transcriptInput => 'Вхід';

  @override
  String get transcriptOutput => 'Вивід';

  @override
  String get transcriptErrorLabel => 'Помилка';

  @override
  String get transcriptSandboxBlocked => 'Пісочниця заблокувала дію';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'Показати повний вивід (+$kb КБ)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'Показати всі $count рядків';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'Показано перші $count рядків';
  }

  @override
  String get transcriptGrepNoMatches => 'Немає збігів';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches збігів',
      many: '$matches збігів',
      few: '$matches збіги',
      one: '$matches збіг',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files файлів',
      many: '$files файлів',
      few: '$files файли',
      one: '$files файл',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'Особа $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'Перейменувати спікера';

  @override
  String get meetingRenameSpeakerTitle => 'Перейменувати спікера';

  @override
  String get meetingSpeakerNameLabel => 'Ім’я';

  @override
  String get meetingSpeakerSuggestFromCalendar => 'З запрошених цієї зустрічі';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'Застосувати до всіх блоків цього спікера';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'Якщо вимкнено, перейменовується лише вибраний рядок.';

  @override
  String get meetingLinkEvent => 'Прив’язати до події';

  @override
  String get meetingChangeEvent => 'Змінити подію';

  @override
  String get meetingLinkEventTitle => 'Прив’язати до події календаря';

  @override
  String get meetingLinkEventSearchHint => 'Пошук подій';

  @override
  String get meetingLinkEventEmpty => 'Немає близьких подій календаря';

  @override
  String get meetingUnlinkEvent => 'Прибрати прив’язку';

  @override
  String get calendarLinkExistingMeeting => 'Прив’язати до наявної зустрічі';

  @override
  String get calendarLinkMeetingTitle => 'Прив’язати зустріч';

  @override
  String get calendarLinkMeetingSearchHint => 'Пошук зустрічей';

  @override
  String get calendarLinkMeetingEmpty => 'Немає зустрічей для прив’язки';

  @override
  String get meetingRenameSpeakerFailed => 'Не вдалося перейменувати спікера';

  @override
  String get calendarLinkUpdateFailed =>
      'Не вдалося оновити прив’язку календаря';

  @override
  String get rename => 'Перейменувати';

  @override
  String get notNow => 'Не зараз';

  @override
  String get meetingSaveVoiceProfileTitle => 'Зберегти голосовий профіль?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'Збережіть голосовий відбиток, щоб надалі автоматично розпізнавати $name на зустрічах.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'Збережено голосовий профіль для $name';
  }

  @override
  String get meetingVoiceProfileSaveFailed =>
      'Не вдалося зберегти голосовий профіль';

  @override
  String get voiceProfilesSection => 'Голосові профілі';

  @override
  String get voiceProfilesDescription =>
      'Збережені голоси розпізнаються автоматично на наступних зустрічах.';

  @override
  String get voiceProfilesEmpty =>
      'Ще немає збережених голосів. Назвіть спікера в транскрипті зустрічі, потім виберіть «Зберегти голосовий профіль».';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count зразків',
      many: '$count зразків',
      few: '$count зразки',
      one: '$count зразок',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'Перейменувати голосовий профіль';

  @override
  String get deleteVoiceProfileTitle => 'Видалити голосовий профіль?';

  @override
  String deleteVoiceProfileBody(String name) {
    return 'Припинити розпізнавати $name? Збережений голосовий відбиток буде видалено. Імена, уже застосовані в минулих зустрічах, залишаться.';
  }

  @override
  String get connectedLabel => 'Підключено';

  @override
  String get ideTabGeneral => 'Загальне';

  @override
  String get ideTabExplorer => 'Провідник';

  @override
  String get ideTabSourceControl => 'Керування кодом';

  @override
  String get generalSectionTodos => 'Задачі';

  @override
  String get generalSectionGoals => 'Цілі';

  @override
  String get goalRunStatusActive => 'Активна';

  @override
  String get goalRunStatusPaused => 'Призупинена';

  @override
  String get goalRunStatusCompleted => 'Завершена';

  @override
  String get goalRunStatusFailed => 'Помилка';

  @override
  String get goalRunStatusCancelled => 'Скасована';

  @override
  String get goalRunStatusBudgetExhausted => 'Бюджет вичерпано';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'Запуск $run з $max · $cost з $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'Запуск $run · $cost з $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'До $deadline';
  }

  @override
  String get goalRunPause => 'Призупинити ціль';

  @override
  String get goalRunResume => 'Відновити ціль';

  @override
  String goalRunResumeRaise(String cap) {
    return 'Відновити · підняти ліміт до $cap';
  }

  @override
  String get goalRunStop => 'Зупинити ціль';

  @override
  String get generalSectionAgents => 'Агенти';

  @override
  String get generalSectionTerminals => 'Термінали';

  @override
  String get generalTodosEmpty => 'Ще немає задач';

  @override
  String get generalAgentsEmpty => 'Немає запущених агентів';

  @override
  String get generalTerminalsEmpty => 'Немає відкритих терміналів';

  @override
  String get generalSectionBrowsers => 'Браузери';

  @override
  String get generalSectionComputers => 'Комп\'ютери';

  @override
  String get generalBrowsersEmpty => 'Немає відкритих браузерів';

  @override
  String get generalComputersEmpty => 'Немає відкритих комп\'ютерів';

  @override
  String get generalSectionPhones => 'Телефони';

  @override
  String get generalPhonesEmpty => 'Немає відкритих телефонів';

  @override
  String get pauseAgent => 'Призупинити агента';

  @override
  String get resumeAgent => 'Відновити агента';

  @override
  String get agentCannotPause =>
      'Цього агента не можна призупинити — зупиніть його.';

  @override
  String get goalClear => 'Очистити ціль';

  @override
  String get undoLabelGoalClear => 'очистити ціль';

  @override
  String get todoStatusPending => 'Не почато';

  @override
  String get todoStatusInProgress => 'У процесі';

  @override
  String get todoStatusCompleted => 'Готово';

  @override
  String get reorderTodo => 'Змінити порядок завдань';

  @override
  String get focusTerminal => 'Сфокусувати термінал';

  @override
  String get focusMachine => 'Сфокусувати машину';

  @override
  String get focusBrowser => 'Сфокусувати браузер';

  @override
  String get todoEditorTitle => 'Редагувати завдання';

  @override
  String get todoEditorHint =>
      'По одному пункту в рядку. Використовуйте - [ ] для не початих, - [~] для тих, що в процесі, - [x] для готових.';

  @override
  String get todoNeedsText => 'Додайте текст після команди';

  @override
  String get todoNotFound => 'Немає відповідного завдання';

  @override
  String get todoCleared => 'Список завдань очищено';

  @override
  String get todoNothingToCopy => 'Немає що копіювати';

  @override
  String todoAdded(String content) {
    return 'Додано «$content»';
  }

  @override
  String todoStarted(String content) {
    return 'Розпочато «$content»';
  }

  @override
  String todoCompleted(String content) {
    return 'Завершено «$content»';
  }

  @override
  String todoRemoved(String content) {
    return 'Видалено «$content»';
  }

  @override
  String todoCopied(int count) {
    return 'Скопійовано $count елементів';
  }

  @override
  String todoImported(int count) {
    return 'Імпортовано $count елементів';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'Невідома команда todo «$name»';
  }

  @override
  String get terminal => 'Термінал';

  @override
  String get ideCloseTab => 'Закрити вкладку';

  @override
  String get ideSplitEditor => 'Розділити редактор';

  @override
  String get ideSplitRight => 'Розділити праворуч';

  @override
  String get ideSplitDown => 'Розділити вниз';

  @override
  String get ideSplitLeft => 'Розділити ліворуч';

  @override
  String get ideSplitUp => 'Розділити вгору';

  @override
  String get ideCloseGroup => 'Закрити групу';

  @override
  String get ideCloseOthers => 'Закрити інші';

  @override
  String get ideCloseToRight => 'Закрити праворуч';

  @override
  String get ideCloseSaved => 'Закрити збережені';

  @override
  String get ideCloseAll => 'Закрити всі';

  @override
  String get ideSplit => 'Розділити';

  @override
  String get ideToggleSidebar => 'Перемкнути бічну панель';

  @override
  String get ideNewTab => 'Відкрити редактор';

  @override
  String get ideNewTabMenu => 'Нова вкладка';

  @override
  String get ideReviewCode => 'Рев\'ю коду';

  @override
  String ideReviewCodeInRepo(String repo) {
    return 'Рев\'ю коду ($repo)';
  }

  @override
  String get ideRevertConfirmTitle => 'Відкотити зміни';

  @override
  String get ideRevertUntracked => 'Невідстежувані файли не можна відкотити';

  @override
  String get ideRevertFailed =>
      'Не вдалося відкотити файли. Робоче дерево розмови може бути недоступне.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файлу',
      many: '$count файлів',
      few: '$count файли',
      one: '$count файл',
    );
    return '$_temp0 не вдалося відкотити (невідстежувані).';
  }

  @override
  String get ideSearchMatchCase => 'Зважати на регістр';

  @override
  String get ideSearchWholeWord => 'Ціле слово';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'Фільтри пошуку';

  @override
  String get ideSearchFilesToInclude => 'Файли для включення';

  @override
  String get ideSearchFilesToExclude => 'Файли для виключення';

  @override
  String get ideNoOpenTabs =>
      'Немає відкритих вкладок — натисніть +, щоб відкрити';

  @override
  String get ideBrowserAddressHint => 'Введіть адресу або пошук';

  @override
  String get ideSimpleWebBrowser => 'Простий веббраузер';

  @override
  String get ideWebBrowser => 'Веббраузер';

  @override
  String get ideBrowserEnterUrl =>
      'Введіть URL в адресному рядку, щоб почати перегляд';

  @override
  String get ideCodeServer => 'Редактор';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'Зберегти зміни в $fileName?';
  }

  @override
  String get ideUnsavedChangesBody => 'Незбережені зміни буде втрачено.';

  @override
  String get ideDontSave => 'Не зберігати';

  @override
  String get editorAutoSave => 'Автозбереження';

  @override
  String get editorAutoSaveDescription =>
      'Автоматично зберігати зміни у вбудованому редакторі.';

  @override
  String get editorAutoSaveOff => 'Вимкнено';

  @override
  String get editorAutoSaveAfterDelay => 'Із затримкою';

  @override
  String get editorAutoSaveOnFocusChange => 'При зміні фокуса';

  @override
  String get ideCodeServerUnavailable =>
      'code-server недоступний на цьому сервері';

  @override
  String get ideCodeServerUnavailableHint =>
      'Установіть code-server (coder/code-server) на хості сервера, потім знову відкрийте редактор.';

  @override
  String get ideCodeServerInstalling => 'Підготовка редактора…';

  @override
  String get ideCodeServerOpenInBrowser => 'Відкрити редактор у браузері';

  @override
  String get ideCodeServerError => 'Не вдалося відкрити редактор';

  @override
  String get paneSuspendedCaption =>
      'Призупинено для економії ресурсів — перезавантажиться після фокуса';

  @override
  String get ideFolderLoadFailed => 'Не вдалося завантажити цю папку';

  @override
  String get ideFileSearchFailed => 'Не вдалося шукати файли';

  @override
  String get ideSearchInFiles => 'Пошук у файлах';

  @override
  String get ideNoContentMatches => 'Немає збігів';

  @override
  String get ideSourceControlCreatePr => 'Створити pull request';

  @override
  String ideSourceControlViewPr(int number) {
    return 'Переглянути pull request #$number';
  }

  @override
  String get ideSourceControlNoChanges => 'Немає змін';

  @override
  String get noReposInConversation => 'У цій розмові немає репозиторіїв';

  @override
  String get ideSourceControlNoSpace =>
      'Відкрийте розмову, щоб побачити її зміни';

  @override
  String get ideFileLoading => 'Завантаження…';

  @override
  String get ideFileBinary => 'Двійковий файл';

  @override
  String get mcpExternalServers => 'Зовнішні MCP-сервери';

  @override
  String get mcpExternalServersDescription =>
      'Підключення до зовнішніх MCP-серверів (GitHub, Sentry, Postgres, автоматизація браузера). Сервери, налаштовані для Claude, Cursor, VS Code та інших інструментів, виявляються автоматично.';

  @override
  String get mcpApprovalMode => 'Підтвердження інструментів';

  @override
  String get mcpApprovalModeDescription =>
      'Які дії інструментів виконуються без запиту. Читання завжди дозволене; вищі рівні запитують підтвердження.';

  @override
  String get mcpApprovalAlwaysAsk => 'Завжди запитувати';

  @override
  String get mcpApprovalWrite => 'Автосхвалення запису';

  @override
  String get mcpApprovalYolo => 'Автосхвалення всього';

  @override
  String get mcpNoExternalServers => 'Зовнішніх MCP-серверів не знайдено.';

  @override
  String get mcpAuthorize => 'Авторизувати';

  @override
  String get mcpReconnect => 'Перепідключити';

  @override
  String get mcpExternalConnectionsNote =>
      'Зовнішні MCP-сервери працюють на сервері агента (спільні для desktop і web). Авторизація OAuth-серверів доступна лише на desktop.';

  @override
  String get mcpStatusConnected => 'Підключено';

  @override
  String get mcpStatusConnecting => 'Підключення…';

  @override
  String get mcpStatusNeedsAuth => 'Потрібна авторизація';

  @override
  String get mcpStatusFailed => 'Помилка';

  @override
  String get mcpStatusCircuitOpen => 'Призупинено';

  @override
  String get mcpStatusDisabled => 'Вимкнено';

  @override
  String get providersAndModels => 'Провайдери й моделі';

  @override
  String get providersAndModelsDescription =>
      'Список усіх провайдерів, які може використовувати вбудований агент — укажіть API-ключ або увійдіть через браузер, перегляньте моделі й тарифи кожного підключеного провайдера та визначте, які провайдери дозволені в цьому робочому просторі.';

  @override
  String get syncNow => 'Синхронізувати зараз';

  @override
  String syncNowResult(int applied, int failed) {
    return 'Синхронізацію завершено — застосовано $applied, помилок $failed';
  }

  @override
  String syncNowFailed(String error) {
    return 'Помилка синхронізації: $error';
  }

  @override
  String get denied => 'Заборонено';

  @override
  String get allowed => 'Дозволено';

  @override
  String allowProviderSemantic(String provider) {
    return 'Дозволити $provider';
  }

  @override
  String enabledViaEnv(String key) {
    return 'Увімкнено через $key';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output за 1 млн';
  }

  @override
  String contextTokens(String tokens) {
    return '$tokens контексту';
  }

  @override
  String get usageAndCost => 'Використання та вартість';

  @override
  String get usageAndCostDescription =>
      'Витрати на агентів за останні 7 днів за спостережуваною вартістю запусків.';

  @override
  String get noUsageYet => 'Використання ще не зафіксовано.';

  @override
  String get spentThisWeek => 'витрачено цього тижня';

  @override
  String get subscriptionUsage => 'Використання підписки';

  @override
  String get subscriptionUsageUnavailable => 'Недоступно';

  @override
  String get subscriptionUsageExhausted => 'Квоту вичерпано';

  @override
  String get subscriptionUsageSignInRequired => 'Увійдіть знову';

  @override
  String get subscriptionUsageSignInExpired =>
      'Сеанс закінчився, оновиться з наступним запуском';

  @override
  String get subscriptionUsagePartiallyAvailable => 'Частково доступно';

  @override
  String resetsIn(String duration) {
    return 'Скидається через $duration';
  }

  @override
  String get feedbackHelpful => 'Це було корисно';

  @override
  String get feedbackNotHelpful => 'Це не допомогло';

  @override
  String get modeChat => 'Чат';

  @override
  String get modePlan => 'План';

  @override
  String get modeReview => 'Огляд';

  @override
  String get modeOrchestrate => 'Оркестрація';

  @override
  String get editorTheme => 'Тема редактора';

  @override
  String get editorThemeDescription =>
      'Імпортуйте колірну тему VS Code, щоб вбудований diff і редактор відповідали вашій IDE.';

  @override
  String get editorThemePasteHint =>
      'Вставте вміст JSON-файлу колірної теми VS Code';

  @override
  String get editorThemeImported => 'Тему імпортовано';

  @override
  String get editorThemeInvalid => 'Це не схоже на дійсну тему VS Code';

  @override
  String get importTheme => 'Імпортувати тему';

  @override
  String get clearTheme => 'Очистити тему';

  @override
  String get openInDiffViewer => 'Відкрити в переглядачі diff';

  @override
  String get shellCommand => 'Команда';

  @override
  String get shellOutput => 'Вивід';

  @override
  String get revertToHere => 'Відкотити сюди';

  @override
  String get revertConfirmBody =>
      'Приховати повідомлення після цієї точки й відкотити зміни файлів агента до цього ходу? Це можна скасувати.';

  @override
  String get revert => 'Відкотити';

  @override
  String get revertedToHere => 'Відкочено сюди';

  @override
  String get nothingToRevert => 'Немає що відкотити';

  @override
  String get undoRevert => 'Скасувати відкат';

  @override
  String get revertUndone => 'Відкат скасовано';

  @override
  String get systemBehavior => 'Поведінка системи';

  @override
  String get keepAwakeTitle =>
      'Не давати комп’ютеру засинати, поки працюють агенти';

  @override
  String get keepAwakeOnSubtitle =>
      'Комп’ютер не засинатиме, поки працює агент';

  @override
  String get keepAwakeOffSubtitle =>
      'Комп’ютер може заснути навіть під час роботи агента';

  @override
  String get syncEngineSectionTitle => 'Рушій синхронізації';

  @override
  String get syncEngineDescription =>
      'Тікети, повідомлення та нотатки оновлюються наживо малими інкрементальними змінами замість повних знімків. Вимкнення перемикача повертає це сховище до режиму повного знімка — перезавантажте застосунок, щоб зміна набула чинності.';

  @override
  String get syncEngineTicketsTitle => 'Тікети';

  @override
  String get syncEngineMessagingTitle => 'Повідомлення';

  @override
  String get syncEngineNotesTitle => 'Нотатки';

  @override
  String get syncEngineOnSubtitle => 'Активна жива дельта-синхронізація';

  @override
  String get syncEngineOffSubtitle =>
      'Використовується синхронізація повним знімком';

  @override
  String get spaces => 'Простори';

  @override
  String get spacesHomeDescription =>
      'Виберіть простір зі списку або створіть новий.';

  @override
  String get noSpacesYet => 'Просторів ще немає';

  @override
  String get newSpace => 'Новий простір';

  @override
  String get spaceName => 'Назва простору';

  @override
  String get spaceReposHint => 'Репозиторії для включення';

  @override
  String get ideSourceControl => 'Контроль версій';

  @override
  String get stagedChanges => 'Проіндексовані зміни';

  @override
  String get changes => 'Зміни';

  @override
  String get stageFile => 'Проіндексувати';

  @override
  String get unstageFile => 'Прибрати з індексу';

  @override
  String get stageAll => 'Проіндексувати всі зміни';

  @override
  String get unstageAll => 'Скасувати всю індексацію';

  @override
  String get stageChangesToCommit => 'Проіндексувати зміни для коміту';

  @override
  String get syncToPrHead => 'Підтягнути останні коміти PR';

  @override
  String get syncedToPrHead => 'Синхронізовано з останніми комітами PR';

  @override
  String get syncPrHeadDirty =>
      'Закомітьте або відкиньте зміни перед синхронізацією';

  @override
  String get syncPrHeadFailed => 'Не вдалося синхронізуватися з HEAD PR';

  @override
  String get spaceLabel => 'Простір';

  @override
  String get keybindingNewSpace => 'Новий простір';

  @override
  String get keybindingCreateANewSpaceDescription => 'Створити новий простір';

  @override
  String get jumpToLatest => 'Перейти до останнього';

  @override
  String get streaming => 'Стрімінг';

  @override
  String get newMessages => 'Нові';

  @override
  String get copyLink => 'Копіювати посилання';

  @override
  String get linkCopied => 'Посилання скопійовано';

  @override
  String get agentResponding => 'Агент відповідає';

  @override
  String get agentFinished => 'Агент завершив';

  @override
  String get harnessConnectProviderForModels =>
      'Підключіть провайдера, щоб побачити моделі.';

  @override
  String get providerSignOut => 'Вийти';

  @override
  String get providerWaitingForDeviceCode =>
      'Очікуємо підтвердження коду в браузері…';

  @override
  String get providerDeviceCodeHint =>
      'Переконайтеся, що код збігається з тим, що в браузері, і підтвердіть.';

  @override
  String get providerPlanUsageLoading => 'Перевіряємо використання плану…';

  @override
  String get providerPlanUsageUnavailable =>
      'Цей план не надав даних про використання.';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return 'Видалити API-ключ $provider?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'Збережений ключ буде видалено, і його не можна буде показати знову. Агенти з моделями $provider перестануть працювати, доки ви не вставите новий.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return 'Видалити $provider?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'Провайдера та збережений ключ буде видалено. Агенти, прив’язані до його моделей, перестануть працювати.';
  }

  @override
  String get providerApiKeyHint => 'Вставте API-ключ';

  @override
  String get providerApiKeyStoredHint =>
      'Вставте інший API-ключ, щоб додати його';

  @override
  String get providerAddAnotherAccount => 'Додати інший обліковий запис';

  @override
  String get providerActiveBadge => 'Активний';

  @override
  String get providerOauthAccountFallback => 'Обліковий запис OAuth';

  @override
  String get providerApiKeyFallback => 'API-ключ';

  @override
  String get providerRemoveCredentialConfirmTitle =>
      'Видалити ці облікові дані?';

  @override
  String get providerSignOutAccountConfirmTitle =>
      'Вийти з цього облікового запису?';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'Агенти з $provider перейдуть на інші ключі й облікові записи. Якщо їх не лишиться, агенти зупиняться, доки ви не додасте нові.';
  }

  @override
  String get providerBaseUrlHint => 'Базовий URL (необов’язково)';

  @override
  String get addProvider => 'Додати провайдера';

  @override
  String get noCustomProviders => 'Ще немає власних провайдерів.';

  @override
  String get providerNameLabel => 'Назва';

  @override
  String get apiTypeLabel => 'Тип API';

  @override
  String get providerBaseUrlLabel => 'Базовий URL';

  @override
  String get providerApiKeyOptionalHint => 'API-ключ (необов’язково)';

  @override
  String get dialectOpenAiCompatible => 'Сумісний з OpenAI';

  @override
  String get dialectAnthropicCompatible => 'Сумісний з Anthropic';

  @override
  String get removeProviderTooltip => 'Видалити провайдера';

  @override
  String get providerLogInWithBrowser => 'Увійти через браузер';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'Увійти в $provider';
  }

  @override
  String get providerLabel => 'Провайдер';

  @override
  String get selectProviderToLogin => 'Виберіть провайдера для входу';

  @override
  String providerLoginFailed(String error) {
    return 'Не вдалося увійти: $error';
  }

  @override
  String get providerWaitingForBrowser => 'Очікуємо авторизації в браузері…';

  @override
  String get providerPasteCodeHint => 'Або вставте код із браузера';

  @override
  String get providerCompleteLogin => 'Завершити';

  @override
  String get providerConnectedApiKey => 'Підключено через API-ключ';

  @override
  String get providerConnectedOauth => 'Підключено';

  @override
  String providerConnectedAccount(String account) {
    return 'Підключено · $account';
  }

  @override
  String get providerLocalReady => 'Локально · готово';

  @override
  String get providerNotConnected => 'Не підключено';

  @override
  String get preparingWorkspace => 'Підготовка робочого простору…';

  @override
  String provisioningRunningSetupScript(String repo) {
    return 'Запуск скрипта налаштування для $repo…';
  }

  @override
  String get repoScriptsTitle => 'Скрипти';

  @override
  String get repoScriptsTooltip => 'Налаштувати скрипти життєвого циклу';

  @override
  String get repoScriptsSetupLabel => 'Скрипт налаштування';

  @override
  String get repoScriptsSetupHelp =>
      'Запускається в робочому дереві простору одразу після створення — встановити залежності, згенерувати файли. Помилка позначає простір як невдалий; повторна спроба запускає скрипт знову.';

  @override
  String get repoScriptsArchiveLabel => 'Скрипт архівування';

  @override
  String get repoScriptsArchiveHelp =>
      'Запускається безпосередньо перед видаленням робочого дерева простору — прибрати ресурси поза робочим деревом. Помилка ніколи не блокує видалення.';

  @override
  String get repoScriptsEnvHelp =>
      'Запускається через bash із робочого дерева; задано CC_WORKSPACE_PATH (робоче дерево), CC_ROOT_PATH (корінь репозиторію), CC_SPACE_ID, CC_SPACE_NAME і CC_REPO_NAME.';

  @override
  String get repoScriptsSetupPlaceholder => 'напр. pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      'напр. docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => 'Останні запуски';

  @override
  String get repoScriptsNoRuns => 'Запусків ще не було';

  @override
  String get repoScriptsSaved => 'Скрипти збережено';

  @override
  String get repoScriptsRunKindSetup => 'Налаштування';

  @override
  String get repoScriptsRunKindArchive => 'Архівування';

  @override
  String get repoScriptsRunStatusRunning => 'Виконується';

  @override
  String get repoScriptsRunStatusSucceeded => 'Успішно';

  @override
  String get repoScriptsRunStatusFailed => 'Невдало';

  @override
  String get repoScriptsRunStatusTimedOut => 'Час вичерпано';

  @override
  String repoScriptsExitCode(int code) {
    return 'Код виходу $code';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return 'Клонування $repo…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'Checkout pull request у $repo…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'Налаштування агента $agent…';
  }

  @override
  String get workspacePrepFailed => 'Не вдалося підготувати робочий простір';

  @override
  String get workspacePrepStopped => 'Підготовку робочого простору зупинено';

  @override
  String get stopWorkspacePrep => 'Зупинити підготовку';

  @override
  String get stopWorkspacePrepTooltip =>
      'Зупинити підготовку цього робочого простору';

  @override
  String get stopWorkspacePrepConfirm =>
      'Зупинити підготовку цього робочого простору? Поточне клонування буде відкинуто — можна почати знову звідси.';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count message(s) will send when ready';
  }

  @override
  String get membersNav => 'Учасники';

  @override
  String get membersSettingsDescription =>
      'Люди з доступом до цього робочого простору: список, запрошення та журнал аудиту';

  @override
  String get memberRosterLabel => 'Список учасників';

  @override
  String get memberRepoAccessAction => 'Доступ до репозиторію';

  @override
  String memberRepoAccessTitle(String name) {
    return 'Доступ до репозиторію для $name';
  }

  @override
  String get roleOwner => 'Власник';

  @override
  String get roleAdmin => 'Адмін';

  @override
  String get roleMember => 'Учасник';

  @override
  String get roleViewer => 'Переглядач';

  @override
  String get roleGuest => 'Гість';

  @override
  String get removeMemberTitle => 'Вилучити учасника';

  @override
  String removeMemberConfirm(String name) {
    return 'Вилучити $name з цього робочого простору? Доступ буде втрачено одразу.';
  }

  @override
  String get transferOwnershipAction => 'Передати володіння';

  @override
  String get transferOwnershipTitle => 'Передати володіння';

  @override
  String transferOwnershipConfirm(String name) {
    return 'Зробити $name власником цього робочого простору? Ви станете адміном. Лише власник може видалити робочий простір або змінити роль іншого адміна.';
  }

  @override
  String get transferOwnershipCta => 'Передати';

  @override
  String get auditTrailLabel => 'Журнал аудиту авторизації';

  @override
  String get auditTrailDescription =>
      'Кожен дозвіл і відмова, пов’язані хеш-ланцюгом, тож змінений або видалений запис можна виявити.';

  @override
  String get auditVerifyChain => 'Перевірити ланцюг';

  @override
  String auditChainIntact(int count) {
    return 'Chain intact — $count entries verified';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'Ланцюг розірвано на записі $seq: $reason';
  }

  @override
  String get auditEmpty => 'Рішень ще не записано.';

  @override
  String get auditDenied => 'Відмовлено';

  @override
  String get auditAllowed => 'Дозволено';

  @override
  String auditOnBehalfOf(String user) {
    return 'від імені $user';
  }

  @override
  String get policyTemplatesLabel => 'Шаблони політик';

  @override
  String get policyTemplatesDescription =>
      'Застосувати початкову поставу або перенести її між робочими просторами.';

  @override
  String get policyTemplateStrict => 'Суворий';

  @override
  String get policyTemplateBalanced => 'Збалансований';

  @override
  String get policyTemplatePermissive => 'Дозвільна';

  @override
  String get policyTemplateApply => 'Застосувати';

  @override
  String policyTemplateApplied(int count) {
    return 'Застосовано $count правил';
  }

  @override
  String get policyExport => 'Копіювати політику';

  @override
  String get policyExported => 'Політику скопійовано в буфер обміну';

  @override
  String get policyImport => 'Вставити політику';

  @override
  String policyImported(int count) {
    return 'Імпортовано $count правил';
  }

  @override
  String get approveAndRemember => 'Схвалити на 8 годин';

  @override
  String get approveAndRememberTooltip =>
      'Схвалює цю дію й більше не запитує про подібні в цьому просторі протягом 8 годин. Термін спливає самостійно.';

  @override
  String get unknownUserLabel => 'Невідомий користувач';

  @override
  String get inviteMember => 'Запросити учасника';

  @override
  String get inviteRepoAccessHeader => 'Доступ до репозиторіїв';

  @override
  String get inviteRepoAccessExplainer =>
      'Запрошеному надаються лише позначені репозиторії з обраним рівнем доступу. Решта залишається прихованою.';

  @override
  String get grantLevelRead => 'Читання';

  @override
  String get grantLevelReview => 'Рецензування';

  @override
  String get grantLevelWrite => 'Запис';

  @override
  String get inviteExpiryLabel => 'Термін дії';

  @override
  String get expiryOneDay => '1 день';

  @override
  String get expirySevenDays => '7 днів';

  @override
  String get expiryThirtyDays => '30 днів';

  @override
  String get createInviteAction => 'Створити запрошення';

  @override
  String get inviteOneTimeCodeLabel => 'Одноразовий код';

  @override
  String get inviteCodeShownOnce =>
      'Цей код показується лише раз — скопіюйте його зараз.';

  @override
  String get inviteLinkLabel => 'Посилання-запрошення';

  @override
  String get inviteRedeemHint =>
      'Передайте код запрошеному; він активує його за URL вашого сервера.';

  @override
  String get inviteScanQr => 'Або відскануйте, щоб активувати';

  @override
  String get inviteLoopbackWarningTitle =>
      'Запрошення вказує на локальну адресу';

  @override
  String get inviteLoopbackWarningBody =>
      'Колеги на інших комп’ютерах не зможуть підключитися до цього сервера. Запустіть тунель (Налаштування → Інтеграції → Поділитися цим сервером) або прив’яжіть його до мережі, щоб користувачі поза цим хостом могли з’єднатися.';

  @override
  String get inviteStatusOpen => 'Відкрите';

  @override
  String get inviteStatusUsed => 'Використане';

  @override
  String get inviteStatusRevoked => 'Відкликане';

  @override
  String get inviteStatusExpired => 'Прострочене';

  @override
  String inviteCreatedTime(String time) {
    return 'Створено $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'спливає $date';
  }

  @override
  String get noActivityYet => 'Поки немає активності';

  @override
  String get couldNotLoadMembers => 'Не вдалося завантажити учасників';

  @override
  String get couldNotLoadInvites => 'Не вдалося завантажити запрошення';

  @override
  String get couldNotLoadActivity => 'Не вдалося завантажити активність';

  @override
  String get yourDevices => 'Ваші пристрої';

  @override
  String get yourDevicesDescription =>
      'Клієнти, прив’язані до вашого облікового запису на цьому сервері.';

  @override
  String get noOwnDevices =>
      'Ще немає пристроїв, прив’язаних до вашого облікового запису';

  @override
  String get renameDeviceTitle => 'Перейменувати пристрій';

  @override
  String get revokeDeviceTitle => 'Відкликати пристрій';

  @override
  String revokeDeviceConfirm(String label) {
    return 'Відкликати $label? З’єднання розірветься одразу, і пристрій більше не зможе звертатися до цього сервера.';
  }

  @override
  String devicePairedTime(String time) {
    return 'Прив’язано $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'Востаннє в мережі $time';
  }

  @override
  String get deviceNeverSeen => 'Ніколи не підключався';

  @override
  String get profileSectionLabel => 'Профіль';

  @override
  String get profileSectionDescription =>
      'Як вас бачить команда й авторство git-комітів у цьому просторі. Порожні поля успадковують ім\'я й пошту облікового запису.';

  @override
  String get displayNameLabel => 'Ім’я для відображення';

  @override
  String get emailLabel => 'Email';

  @override
  String get gitAuthorNameLabel => 'Ім’я автора Git';

  @override
  String get gitAuthorEmailLabel => 'Email автора Git';

  @override
  String get profileSaved => 'Профіль збережено';

  @override
  String get presenceOnline => 'У мережі';

  @override
  String get presenceIdle => 'Неактивний';

  @override
  String get presenceTyping => 'Друкує…';

  @override
  String get presenceAgentThinking => 'Думає';

  @override
  String get presenceAgentRunning => 'Виконується';

  @override
  String get presenceAgentBlocked => 'Заблоковано';

  @override
  String get presenceAgentDone => 'Готово';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
  }

  @override
  String get presenceRailLabel => 'Хто онлайн';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'Увімкнути «не турбувати»';

  @override
  String get dndTooltipOff => 'Вимкнути «не турбувати»';

  @override
  String get startPresenting => 'Почати показ';

  @override
  String get stopPresenting => 'Зупинити показ';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name проводить показ';
  }

  @override
  String get spotlightLeave => 'Вийти';

  @override
  String typingIndicator(String name) {
    return '$name друкує…';
  }

  @override
  String get ideTabNotes => 'Нотатки';

  @override
  String get ideSidebarAllViews => 'Усі подання';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'Усі подання ($count сховано)';
  }

  @override
  String get ideSidebarPinView => 'Закріпити на бічній панелі';

  @override
  String get ideSidebarUnpinView => 'Відкріпити від бічної панелі';

  @override
  String get notesEmptyHint =>
      'Додайте нотатку для того, хто продовжить цю розмову…';

  @override
  String get notesEditTooltip => 'Редагувати нотатку';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'Оновлено $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name редагує';
  }

  @override
  String get notesSaveFailed => 'Не вдалося зберегти нотатку';

  @override
  String get reactionAddTooltip => 'Додати реакцію';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'Відреагувати $emoji';
  }

  @override
  String get autonomyDialLabel => 'Автономність';

  @override
  String get autonomyProposeOnly => 'Лише пропонувати';

  @override
  String get autonomyActWithApproval => 'Діяти з підтвердженням';

  @override
  String get autonomyActFreely => 'Діяти вільно';

  @override
  String get autonomyDefaultOption => 'Типовий';

  @override
  String get checkerLabel => 'Перевіряч';

  @override
  String get checkerNone => 'Немає';

  @override
  String get checkerCaption =>
      'Перевіряч переглядає завершені запуски інших агентів.';

  @override
  String get takeoverTooltip => 'Перехопити робоче дерево';

  @override
  String get takeoverBannerSelf => 'Ви перехопили робоче дерево цієї розмови';

  @override
  String takeoverBannerOther(String name) {
    return '$name перехопив робоче дерево цієї розмови';
  }

  @override
  String get handBackButton => 'Повернути';

  @override
  String get handBackDialogTitle => 'Повернути робоче дерево';

  @override
  String get handBackDialogNoteHint => 'Необов’язкова нотатка для агента…';

  @override
  String takeoverFailed(String message) {
    return 'Не вдалося перехопити: $message';
  }

  @override
  String handBackFailed(String message) {
    return 'Не вдалося повернути: $message';
  }

  @override
  String get planStudioTitle => 'Plan Studio';

  @override
  String get plansTitle => 'Плани';

  @override
  String get plansSubtitle => 'Активні плани, документи планів і плейбуки';

  @override
  String get plansActiveSection => 'Активні плани';

  @override
  String get plansDocumentsSection => 'Документи планів';

  @override
  String get plansPlaybooksSection => 'Плейбуки';

  @override
  String get plansNoActive => 'Ще немає активних планів.';

  @override
  String get plansNoDocuments => 'Ще немає документів планів.';

  @override
  String get plansNoPlaybooks => 'Ще немає плейбуків.';

  @override
  String get planNotFound => 'План не знайдено.';

  @override
  String get planOpenInStudio => 'Відкрити';

  @override
  String get planNodeTitle => 'Назва';

  @override
  String get planNodeDescription => 'Опис';

  @override
  String get planNodeDescriptionHint => 'Що має робити цей крок…';

  @override
  String get planNodeApplyDescription => 'Застосувати';

  @override
  String get planNodeRole => 'Роль';

  @override
  String get planNodeDependencies => 'Залежить від';

  @override
  String get planNodeDependenciesHint => 'Додати залежність';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count залежності',
      many: '$count залежностей',
      few: '$count залежності',
      one: '$count залежність',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'Немає залежностей, тож цей крок запускається одразу після старту плану';

  @override
  String get planNodeOutputSchema => 'Схема виводу (JSON)';

  @override
  String get planNodeEstimate => 'Оцінка';

  @override
  String get planNodeProvenance => 'Походження';

  @override
  String get planNodeAlreadyExecuted =>
      'Уже виконано — редагування відгалужує план звідси.';

  @override
  String get planNewNodeTitle => 'Новий крок';

  @override
  String get planEstimateNoHistory => 'Історії ще немає';

  @override
  String get planEstimateBlastUnknown => 'Радіус впливу: невідомо';

  @override
  String get planEstimatePartial => 'частково';

  @override
  String get planEstimateAction => 'Оцінити';

  @override
  String planEstimateDuration(String range) {
    return 'Тривалість $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'Радіус впливу: $files файлів, $symbols символів';
  }

  @override
  String get planApprove => 'Затвердити план';

  @override
  String get planApproveSelectedNodes => 'Затвердити вибрані';

  @override
  String get planReject => 'Відхилити';

  @override
  String get planCancel => 'Скасувати запуск';

  @override
  String get planContinueNode => 'Продовжити вузол';

  @override
  String get planTotalNotEstimated => 'Ще не оцінено';

  @override
  String get planBudgetExceeded => 'понад бюджет';

  @override
  String planBudgetCeiling(String amount) {
    return 'бюджет ≤ \$$amount';
  }

  @override
  String get planVersionsTitle => 'Версії';

  @override
  String get planNoRevisions => 'Ревізій ще немає.';

  @override
  String get planDiffIdentical => 'Змін немає.';

  @override
  String get planDiffGoalChanged => 'Ціль змінено';

  @override
  String get planDiffBudgetChanged => 'Бюджет змінено';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'Зміни з v$fromRev до v$toRev';
  }

  @override
  String planDiffAdded(String node) {
    return 'Додано $node';
  }

  @override
  String planDiffRemoved(String node) {
    return 'Видалено $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return 'Змінено $node: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'Додано ребро: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'Видалено ребро: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'Додано роль: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'Видалено роль: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'Роль перепризначено: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'План переплановано: ви затвердили v$approved, зараз це v$current. Перегляньте зміни, перш ніж він продовжиться.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'Фактична вартість: \$$amount';
  }

  @override
  String get planPlaybookRun => 'Запустити';

  @override
  String get planPlaybookDelete => 'Видалити плейбук';

  @override
  String get planPlaybookProposed =>
      'Запропоновано план — затвердьте його в Plan Studio.';

  @override
  String get planPlaybookAnchorTicket => 'Опорний тікет';

  @override
  String get planPlaybookPickTicket => 'Виберіть тікет…';

  @override
  String get planPlaybookProposeRun => 'Запропонувати план';

  @override
  String get planPlaybookRepoHint => 'id репозиторію';

  @override
  String get planPlaybookAgentHint => 'id агента';

  @override
  String planPlaybookRunTitle(String name) {
    return 'Запуск $name';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count параметрів';
  }

  @override
  String get recentLabel => 'Останні';

  @override
  String get cheatSheetTitle => 'Сполучення клавіш';

  @override
  String get cheatSheetGlobal => 'Глобальні';

  @override
  String get cheatSheetThisScreen => 'Цей екран';

  @override
  String get cheatSheetReservedInBrowser => 'Зарезервовано браузером';

  @override
  String get keybindingCheatSheet => 'Сполучення клавіш';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      'Показати довідку сполучень клавіш для поточного екрана';

  @override
  String get runPlaybookLabel => 'Запустити плейбук';

  @override
  String get playbooksLabel => 'Плейбуки';

  @override
  String get keybindingUndo => 'Відмінити';

  @override
  String get keybindingRedo => 'Повторити';

  @override
  String get keybindingUndoLastActionDescription =>
      'Відмінити останню зворотну дію';

  @override
  String get keybindingRedoLastActionDescription =>
      'Повторити останню відмінену дію';

  @override
  String get undone => 'Відмінено';

  @override
  String get redone => 'Повторено';

  @override
  String get undoFailed => 'Не вдалося скасувати';

  @override
  String get undoLabelTicketEdit => 'редагування тікета';

  @override
  String get undoLabelMessageEdit => 'редагування повідомлення';

  @override
  String get undoLabelTodoStatus => 'статус todo';

  @override
  String get inboxTitle => 'Вхідні';

  @override
  String get inboxReview => 'Перевірка';

  @override
  String get inboxOpen => 'Відкрити';

  @override
  String get inboxAllCaughtUp => 'Усе переглянуто';

  @override
  String get inboxGitHubDownTitle => 'Можливо, GitHub недоступний';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub повідомляє про $status, тож pull request можуть бути відсутні в цьому списку, хоча насправді вони ще не завершені.';
  }

  @override
  String get inboxGitHubIdentityTitle =>
      'Не вдалося підтвердити ваш обліковий запис GitHub';

  @override
  String get inboxGitHubIdentityBody =>
      'Вхідні сортуються за тим, хто ви в GitHub. Доки це не завантажиться, список лишається порожнім, навіть якщо на вас чекають pull request.';

  @override
  String get inboxSeverityBlocking => 'Заблоковано';

  @override
  String get inboxSeverityWaiting => 'Очікування';

  @override
  String get inboxSeverityInfo => 'Інфо';

  @override
  String get inboxSyncFailed => 'Не вдалося синхронізувати';

  @override
  String get inboxNeedsYourAttention => 'Потрібна ваша увага';

  @override
  String get inboxSectionNeedsYourReview => 'Потрібна ваша перевірка';

  @override
  String get inboxSectionReturnedToYou => 'Повернуто вам';

  @override
  String get inboxSectionApproved => 'Схвалено';

  @override
  String get inboxSectionDrafts => 'Чернетки';

  @override
  String get inboxSectionWaitingForReviewers => 'Очікують рецензентів';

  @override
  String get inboxSectionMergingAndMerged => 'Зливаються та нещодавно злиті';

  @override
  String get inboxSectionWaitingForAuthor => 'Очікують автора';

  @override
  String get inboxColumnTitle => 'Назва';

  @override
  String get inboxColumnChanges => 'Зміни';

  @override
  String get inboxColumnUpdated => 'Оновлено';

  @override
  String get inboxReviewApproved => 'Схвалено';

  @override
  String get inboxReviewChangesRequested => 'Запитано зміни';

  @override
  String get inboxHeroSubtitle =>
      'Усі pull request, у яких ви берете участь, відсортовані за тим, що буде далі.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request потребують вашої перевірки',
      many: '$count pull request потребують вашої перевірки',
      few: '$count pull request потребують вашої перевірки',
      one: '$count pull request потребує вашої перевірки',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count повернуто вам',
      many: '$count повернуто вам',
      few: '$count повернуто вам',
      one: '$count повернуто вам',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted => 'Цю зміну не збережено, її скасовано';

  @override
  String get offlinePendingLabel => 'очікує';

  @override
  String get offlineSyncingLabel => 'синхронізація';

  @override
  String get copyLinkLabel => 'Копіювати посилання на цю сторінку';

  @override
  String get agentsSectionLabel => 'Агенти';

  @override
  String get fleetWorkersTitle => 'Воркери';

  @override
  String get fleetWorkersSubtitle => 'Машини, доступні для виконання завдань';

  @override
  String get fleetJobsTitle => 'Завдання';

  @override
  String get fleetJobsSubtitle => 'Робота, розподілена по флоту';

  @override
  String get fleetNoWorkers =>
      'Ще немає воркерів — друга машина з `cc_worker --server <url>` приєднається до флоту.';

  @override
  String get fleetNoJobs => 'Немає завдань.';

  @override
  String get fleetError => 'Не вдалося завантажити флот';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ядра',
      many: '$count ядер',
      few: '$count ядра',
      one: '$count ядро',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'Heartbeat $time';
  }

  @override
  String get fleetNoHeartbeat => 'Ще немає heartbeat';

  @override
  String fleetLastErrorLabel(String error) {
    return 'Остання помилка: $error';
  }

  @override
  String get fleetDrain => 'Зупинити прийом';

  @override
  String get fleetResume => 'Відновити';

  @override
  String get fleetRevoke => 'Відкликати';

  @override
  String get fleetRemove => 'Вилучити';

  @override
  String get fleetRevokeTitle => 'Відкликати воркера?';

  @override
  String fleetRevokeBody(String name) {
    return 'Відкликати $name? Його сеанс завершиться, а активні завдання буде перепризначено.';
  }

  @override
  String get fleetRemoveTitle => 'Вилучити воркера?';

  @override
  String fleetRemoveBody(String name) {
    return 'Вилучити $name з флоту? Це видалить його запис.';
  }

  @override
  String get fleetActionFailed => 'Не вдалося виконати дію';

  @override
  String get fleetJobUnassigned => 'Не призначено';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max спроб';
  }

  @override
  String get fleetPlacementReasons => 'Рішення про розміщення';

  @override
  String get fleetNoPlacements => 'Ще немає рішень щодо розміщення.';

  @override
  String get fleetStatusOnline => 'Онлайн';

  @override
  String get fleetStatusDraining => 'Звільняється';

  @override
  String get fleetStatusOffline => 'Офлайн';

  @override
  String get fleetStatusIncompatible => 'Несумісний';

  @override
  String get fleetStatusRevoked => 'Відкликано';

  @override
  String get fleetJobStatusQueued => 'У черзі';

  @override
  String get fleetJobStatusRunning => 'Виконується';

  @override
  String get fleetJobStatusSucceeded => 'Успішно';

  @override
  String get fleetJobStatusFailed => 'Помилка';

  @override
  String get fleetJobStatusCancelled => 'Скасовано';

  @override
  String get evalsNoSuites => 'Ще немає наборів eval.';

  @override
  String get evalsError => 'Не вдалося завантажити evals';

  @override
  String get evalsStarterBadge => 'Starter';

  @override
  String evalsDefaultBatch(int count) {
    return 'Стандартна партія з $count';
  }

  @override
  String get evalsRecentRuns => 'Останні запуски';

  @override
  String get evalsNoRuns => 'Ще немає запусків.';

  @override
  String get evalsPassRate => 'Частка успішних';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return 'від $who';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'Eval завершено — $rate успішних';
  }

  @override
  String get evalsRunFailed => 'Не вдалося запустити набір';

  @override
  String get evalsRun => 'Запустити';

  @override
  String get evalsStatusQueued => 'У черзі';

  @override
  String get evalsStatusRunning => 'Виконується';

  @override
  String get evalsStatusPassed => 'Пройдено';

  @override
  String get evalsStatusFailed => 'Помилка';

  @override
  String get bannerMeetingJoin => 'Приєднатися';

  @override
  String get bannerMeetingRecordAndLink => 'Записати й прив’язати';

  @override
  String get bannerCalendarReconnect => 'Підключити знову';

  @override
  String get bannerView => 'Переглянути';

  @override
  String get soundscapeTitle => 'Soundscapes';

  @override
  String get soundscapePlay => 'Відтворити';

  @override
  String get soundscapePause => 'Пауза';

  @override
  String get soundscapeMoodLabel => 'Настрій';

  @override
  String get soundscapeMoodFocus => 'Фокус';

  @override
  String get soundscapeMoodRelax => 'Релакс';

  @override
  String get soundscapeMoodSleep => 'Сон';

  @override
  String get soundscapeMoodRise => 'Підйом';

  @override
  String get soundscapeVolumeLabel => 'Гучність';

  @override
  String get soundscapeTuneLabel => 'Тон';

  @override
  String get soundscapeTuneMellow => 'М’який';

  @override
  String get soundscapeTuneBright => 'Яскравий';

  @override
  String get soundscapeTuneEnergetic => 'Енергійний';

  @override
  String get soundscapeTuneSpacy => 'Космічний';

  @override
  String get soundscapeTuneResetHint => 'Двічі торкніться, щоб скинути';

  @override
  String get soundscapeSceneLabel => 'Зараз грає';

  @override
  String get soundscapeSceneLoading => 'Налаштовуємо атмосферу…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees°C';
  }

  @override
  String get soundscapeLocationLabel => 'Розташування';

  @override
  String get soundscapeLocationDetecting => 'Визначаємо розташування…';

  @override
  String get soundscapeLocationAutoNote =>
      'Розташування надходить із цього пристрою.';

  @override
  String get soundscapeRefreshWeather => 'Оновити погоду';

  @override
  String get soundscapeAutoStartLabel => 'Запускати з режимом фокусу';

  @override
  String get soundscapeAutoStartDescription =>
      'Автоматично відтворювати звуковий пейзаж, коли ви починаєте сеанс фокусу.';

  @override
  String get soundscapeReturnToApp => 'Повернутися до програми';

  @override
  String get soundscapePopOut => 'Винести плеєр';

  @override
  String get discussion => 'Обговорення';

  @override
  String get chat => 'Чат';

  @override
  String get saving => 'Збереження…';

  @override
  String get saved => 'Збережено';

  @override
  String get saveFailed => 'Не вдалося зберегти';

  @override
  String get commitAndPush => 'Закомітити й надіслати';

  @override
  String get commit => 'Закомітити';

  @override
  String get commitAmend => 'Закомітити (amend)';

  @override
  String get commitAndSync => 'Закомітити й синхронізувати';

  @override
  String get scmSyncChanges => 'Синхронізувати зміни';

  @override
  String get scmPublishBranch => 'Опублікувати гілку';

  @override
  String get scmSyncFailed => 'Не вдалося синхронізувати';

  @override
  String get scmSyncDirty =>
      'Закомітьте або скасуйте зміни перед синхронізацією';

  @override
  String get scmSynced => 'Синхронізовано';

  @override
  String get scmPushRefused => 'Push відхилено';

  @override
  String get scmPulledPushRefused => 'Отримано, але push відхилено';

  @override
  String get scmPushRefusedHint =>
      'Віддалена сторона або хук відхилили оновлення';

  @override
  String get scmSelectBranch => 'Виберіть гілку для перемикання';

  @override
  String get scmCreateBranch => 'Створити нову гілку…';

  @override
  String get scmCreateBranchFrom => 'Створити нову гілку з…';

  @override
  String get scmCheckoutDetached => 'Від\'єднане перемикання…';

  @override
  String get scmBranchName => 'Назва гілки';

  @override
  String get scmCreateBranchTitle => 'Створити гілку';

  @override
  String scmFromRef(String ref) {
    return 'З ⁨$ref⁩';
  }

  @override
  String get scmCheckoutFailed => 'Не вдалося перемкнути гілку';

  @override
  String get scmCheckoutDirty =>
      'Зафіксуйте або скасуйте зміни перед перемиканням гілки';

  @override
  String scmSwitchedToBranch(String branch) {
    return 'Перемкнуто на ⁨$branch⁩';
  }

  @override
  String scmDetachedAt(String ref) {
    return 'Від\'єднано на ⁨$ref⁩';
  }

  @override
  String get scmDetachedHead => 'Від\'єднаний HEAD';

  @override
  String get scmNoBranches => 'Немає відповідних гілок';

  @override
  String get scmBranches => 'Гілки';

  @override
  String get scmRemoteBranches => 'Віддалені гілки';

  @override
  String get scmTags => 'Мітки';

  @override
  String get scmPickStartPoint => 'Виберіть початкову точку';

  @override
  String get scmSwitchBranch => 'Перемкнути гілку';

  @override
  String get scmPullConflictTitle => 'Отримання створить конфлікт';

  @override
  String scmPullConflictBody(int count, String branch) {
    return 'Отримання $count комітів у ⁨$branch⁩ конфліктуватиме з роботою в цій копії.';
  }

  @override
  String get scmAskAi => 'Запитати ШІ';

  @override
  String scmResolveConflictPrompt(String branch, String repo, int count) {
    return 'Отримай ⁨$branch⁩ у ⁨$repo⁩. Гілка відстає на $count комітів від upstream, і отримання конфліктує з локальною роботою. Розв\'яжи конфлікти й заверши отримання.';
  }

  @override
  String commitMessageOnBranch(String shortcut, String branch) {
    return 'Повідомлення ($shortcut, щоб закомітити в «$branch»)';
  }

  @override
  String get committed => 'Закомічено';

  @override
  String get commitAmended => 'Коміт змінено';

  @override
  String get commitFailed => 'Не вдалося закомітити';

  @override
  String get moreCommitActions => 'Інші дії коміту';

  @override
  String get sourceControl => 'Керування кодом';

  @override
  String fixFindingTitle(String location) {
    return 'Виправлення: $location';
  }

  @override
  String get openInEditor => 'Відкрити в редакторі';

  @override
  String get regexTesterTitle => 'Перевірити регулярний вираз';

  @override
  String get regexTesterHint => 'Введіть приклад';

  @override
  String get regexMatch => 'Збіг';

  @override
  String get regexNoMatch => 'Немає збігу';

  @override
  String get regexInvalidPattern => 'Неприпустимий шаблон';

  @override
  String get symbolLookupNone =>
      'Немає визначення в індексі або в цьому запиті на злиття';

  @override
  String get symbolLookupInDiff => 'Знайдено в цьому запиті на злиття';

  @override
  String get symbolLookupFromBase =>
      'З базового checkout — worktree цього PR ще не проіндексовано';

  @override
  String get symbolImplementations => 'Реалізації';

  @override
  String symbolCallersCount(int count) {
    return '$count викликачів';
  }

  @override
  String get commitMessageHint => 'Повідомлення коміту';

  @override
  String get pushedToPr => 'Надіслано до PR';

  @override
  String get pushFailed => 'Не вдалося надіслати';

  @override
  String get reviewFindings => 'Зауваження';

  @override
  String get treeLabel => 'Дерево';

  @override
  String get toggleFileTree => 'Показати або сховати дерево файлів';

  @override
  String get diffViewSettings => 'Параметри перегляду diff';

  @override
  String get splitViewLabel => 'Поділений';

  @override
  String get unifiedViewLabel => 'Об’єднаний';

  @override
  String get wrapLines => 'Переносити рядки';

  @override
  String get shiftClickSelectRange => 'Shift-клацання, щоб вибрати діапазон';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файлів',
      many: '$count файлів',
      few: '$count файли',
      one: '$count файл',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'Малий PR — $files, ~$minutes хв на рев’ю';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'Середній PR — $files, закладіть ~$minutes хв на рев’ю';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'Великий PR — $files, варто розділити перед рев’ю';
  }

  @override
  String get searchInFiles => 'Пошук у файлах';

  @override
  String get showFileList => 'Показати список файлів';

  @override
  String get searchInFilesHintField => 'Пошук у файлах…';

  @override
  String get searchInFilesHint => 'Пошук у файлах pull request';

  @override
  String get searchInWholeRepo => 'Шукати в усьому репозиторії';

  @override
  String get searchInThisPullRequest => 'Шукати в цьому pull request';

  @override
  String get searchNoResults => 'Нічого не знайдено';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count результатів',
      many: '$count результатів',
      few: '$count результати',
      one: '$count результат',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files файлах',
      many: '$files файлах',
      few: '$files файлах',
      one: '$files файлі',
    );
    return '$_temp0 у $_temp1';
  }

  @override
  String get discardChangesTitle => 'Відкинути зміни?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файлів',
      many: '$count файлів',
      few: '$count файли',
      one: '$count файл',
    );
    return 'Відкинути $_temp0 до HEAD? Це не можна скасувати.';
  }

  @override
  String get discardAll => 'Відкинути все';

  @override
  String get discardFailed => 'Не вдалося відкинути зміни';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файлів',
      many: '$count файлів',
      few: '$count файли',
      one: '$count файл',
    );
    return 'Відкинуто $_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted файлів',
      many: '$reverted файлів',
      few: '$reverted файли',
      one: '$reverted файл',
    );
    return 'Відкинуто $_temp0; пропущено $skipped (невідстежувані)';
  }

  @override
  String get prWorktreeUnavailable => 'Робочий простір не готовий';

  @override
  String get prWorktreeUnavailableHint =>
      'Не вдалося підготувати файли pull request. Відкрийте pull request знову, щоб спробувати ще раз.';

  @override
  String get timestampRelativeLabel => 'Відносний';

  @override
  String get timestampRawLabel => 'Мітка часу';

  @override
  String get copyTimestamp => 'Копіювати мітку часу';

  @override
  String get copiedTimestamp => 'Мітку часу скопійовано';

  @override
  String get previewDeployment => 'Попередній перегляд розгортання';

  @override
  String previewDeploymentTab(String site) {
    return 'Попередній перегляд: $site';
  }

  @override
  String get askForReview => 'Запитати рев’ю…';

  @override
  String get closePrsConfirmTitle => 'Закрити pull request?';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Закрити $count pull request?',
      many: 'Закрити $count pull request?',
      few: 'Закрити $count pull request?',
      one: 'Закрити $count pull request?',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Закрито $count pull request',
      many: 'Закрито $count pull request',
      few: 'Закрито $count pull request',
      one: 'Закрито $count pull request',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Призначено $count pull request',
      many: 'Призначено $count pull request',
      few: 'Призначено $count pull request',
      one: 'Призначено $count pull request',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Запитано рев’ю для $count pull request',
      many: 'Запитано рев’ю для $count pull request',
      few: 'Запитано рев’ю для $count pull request',
      one: 'Запитано рев’ю для $count pull request',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дій не вдалися',
      many: '$count дій не вдалися',
      few: '$count дії не вдалися',
      one: '$count дія не вдалася',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'Діаграма';

  @override
  String get diagramViewSource => 'Переглянути джерело';

  @override
  String get diagramHideSource => 'Сховати джерело';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'Попередній перегляд діаграми недоступний ($reason)';
  }

  @override
  String get planUnavailable => 'План недоступний';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count кроку',
      many: '$count кроків',
      few: '$count кроки',
      one: '$count крок',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'Схвалити й запустити';

  @override
  String get planStatusDraft => 'Чернетка';

  @override
  String get planStatusProposed => 'План';

  @override
  String get planStatusApproved => 'План схвалено';

  @override
  String get planStatusRejected => 'План відхилено';

  @override
  String get planStatusSuperseded => 'План замінено';

  @override
  String planRevisionLabel(int revision) {
    return 'Ревізія $revision';
  }

  @override
  String get adapterEnforcementTitle => 'Що забезпечує цей адаптер';

  @override
  String get enforcementFiltersToolSurface =>
      'Control Center обирає інструменти';

  @override
  String get enforcementInterceptsToolCalls =>
      'Кожен виклик перевіряється перед виконанням';

  @override
  String get enforcementObservesCompletionContract =>
      'Запуск прив’язано до очікуваного результату';

  @override
  String get enforcementNativeToolsInterceptable =>
      'Власні інструменти раннера видно';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'Інструменти в процесі працюють у пісочниці';

  @override
  String get enforcementYes => 'Так';

  @override
  String get enforcementNo => 'Ні';

  @override
  String get adapterEnforcementCaveats => 'Застереження';

  @override
  String get enforcementSummaryModesEnforced => 'Режими під контролем';

  @override
  String get enforcementSummaryModesNotEnforced => 'Режими без контролю';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count застереження',
      many: '$count застережень',
      few: '$count застереження',
      one: '$count застереження',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'Режими лише для читання не структурні: Control Center не може прибрати власні інструменти цього раннера.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'Немає перевірки перед виконанням: через Control Center проходять лише виклики інструментів MCP.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'Власні файлові та shell-інструменти раннера ніколи не потрапляють до Control Center; єдиний захист під ними — пісочниця ОС.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'Файлові інструменти в процесі працюють поза пісочницею, тож поверхня інструментів — єдина межа файлової системи.';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center не може підштовхнути чи провалити запуск, який завершився без очікуваного результату.';

  @override
  String get modeDegraded => 'Обмежено';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return 'Режим $mode на $adapter покладається лише на пісочницю; власні файлові інструменти агента не перехоплюються.';
  }

  @override
  String get artifactUnavailable => 'Артефакт недоступний';

  @override
  String artifactRevisionLabel(int count) {
    return '$count ревізій';
  }

  @override
  String get artifactShowMore => 'Показати більше';

  @override
  String get artifactShowLess => 'Показати менше';

  @override
  String get artifactCopy => 'Копіювати';

  @override
  String get artifactCopied => 'Артефакт скопійовано';

  @override
  String get artifactsTabLabel => 'Артефакти';

  @override
  String get artifactsEmptyTitle => 'Артефактів ще немає';

  @override
  String get artifactsEmptyBody =>
      'Коли агент опублікує тут таблицю, діаграму чи схему, вона з’явиться в цьому списку.';

  @override
  String get artifactRevisionPickerLabel => 'Ревізія';

  @override
  String get artifactRestoreRevision => 'Відновити цю ревізію';

  @override
  String get artifactOpenInTab => 'Відкрити у вкладці';

  @override
  String get artifactTitleFallback => 'Артефакт';

  @override
  String get providerGenerationLabel => 'Параметри генерації за замовчуванням';

  @override
  String get providerGenerationHint =>
      'Залиште поле порожнім, щоб узяти стандарт ендпоінта. Моделі задають власні межі виводу та рецепти семплювання; інші значення можуть погіршити якість.';

  @override
  String get providerMaxTokensLabel => 'Макс. токенів виводу';

  @override
  String get addModel => 'Додати модель';

  @override
  String get modelListTitle => 'Список моделей';

  @override
  String get railProvidersGroup => 'Провайдери';

  @override
  String get railCustomProvidersGroup => 'Користувацькі провайдери';

  @override
  String get editModelSettings => 'Редагувати параметри моделі';

  @override
  String get modelIdLabel => 'ID моделі';

  @override
  String get modelIdImmutableHint =>
      'Ідентифікатор, який віддає ендпоінт; після внесення до списку не змінюється.';

  @override
  String get contextWindowLabel => 'Контекстне вікно';

  @override
  String get inputTypesLabel => 'Типи вводу';

  @override
  String get outputTypesLabel => 'Типи виводу';

  @override
  String get modalityText => 'Текст';

  @override
  String get modalityImage => 'Зображення';

  @override
  String get modalityAudio => 'Аудіо';

  @override
  String get modalityVideo => 'Відео';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'Скинути до автоматичного';

  @override
  String get modelOverrideEdited => 'Змінено';

  @override
  String get manualModelBadge => 'Додано вручну';

  @override
  String get modelIdRequired => 'Введіть id моделі.';

  @override
  String get modelTokensInvalid => 'Введіть додатне ціле число токенів.';

  @override
  String get removeModelAction => 'Вилучити модель';

  @override
  String removeModelConfirmTitle(String model) {
    return 'Вилучити $model?';
  }

  @override
  String get removeModelConfirmBody =>
      'Модель зникне зі списку, а агенти, прив’язані до неї, перестануть працювати. Провайдер не зміниться.';

  @override
  String get addModelProviderTitle => 'Додати провайдера моделей';

  @override
  String get addModelProviderDescription =>
      'Налаштуйте власний API-ендпоінт і його моделі.';

  @override
  String get modelListEmptyHint =>
      'Моделей немає. Додайте модель, щоб використовувати її в чаті.';

  @override
  String get addProviderModelsHint =>
      'Моделі підтягуються наживо, щойно ендпоінт відповість. Додавайте вручну лише якщо він не вміє їх перелічити.';

  @override
  String get providerTemperatureLabel => 'Температура';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => 'Параметри генерації збережено';

  @override
  String get providerGenerationInvalid =>
      'Перевірте значення: макс. вихідних токенів і top-k мають бути додатними, температура — 0–2, top-p — 0–1.';

  @override
  String get providerGenerationOverridden => 'Перевизначено';

  @override
  String get branchNotPushed => 'не опубліковано';

  @override
  String branchNotOnRemote(String branch) {
    return '«$branch» є лише в цій розмові';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub ще не бачив цю гілку, тож pull request поки не може її використати. Публікація надсилає коміти, які вже є в робочому дереві — незакомічені зміни лишаються.';

  @override
  String get publishBranch => 'Опублікувати гілку';

  @override
  String branchPublished(String branch) {
    return '«$branch» опубліковано в origin';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'Гілку опубліковано. $count незакомічених змін не включено.';
  }

  @override
  String get composePrLoadingBranches => 'Завантаження гілок з GitHub…';

  @override
  String get composePrBranchesFailed =>
      'Не вдалося завантажити гілки з GitHub. Введіть назву гілки або перевірте з’єднання з GitHub.';

  @override
  String get composePrSubtitleFromSpace =>
      'З гілки цієї розмови — спочатку опублікуйте її, якщо GitHub її ще не бачив';

  @override
  String get obsTabInsights => 'Інсайти';

  @override
  String get obsTabLive => 'Наживо';

  @override
  String get obsTabQuality => 'Якість';

  @override
  String get obsTabUsage => 'Використання';

  @override
  String get obsUsageTotalTokens => 'Усього токенів';

  @override
  String get obsUsagePeakTokens => 'Пік токенів';

  @override
  String get obsUsageLongestSession => 'Найдовша сесія';

  @override
  String get obsUsageCurrentStreak => 'Поточна серія';

  @override
  String get obsUsageLongestStreak => 'Найдовша серія';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count днів',
      few: '$count дні',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'Активність токенів';

  @override
  String get obsUsageActivityModeLabel => 'Режим активності токенів';

  @override
  String get obsUsageModeDaily => 'Щоденно';

  @override
  String get obsUsageModeWeekly => 'Щотижня';

  @override
  String get obsUsageModeCumulative => 'Накопичувально';

  @override
  String get obsUsageTimeRange => 'Період';

  @override
  String get obsUsageTrendTitle => 'Щоденний тренд токенів';

  @override
  String get obsUsageModelUsage => 'Використання моделей';

  @override
  String get obsUsageTokensLabel => 'токени';

  @override
  String get obsUsageNoActivity => 'Використання токенів ще не записано';

  @override
  String get obsUsageOtherModels => 'Інші';

  @override
  String obsUsageCellReadout(String date, String tokens) {
    return '$date · $tokens токенів';
  }

  @override
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  ) {
    return 'Активність токенів з $start до $end. Активних днів: $activeDays. Найзавантаженіший день — $peak токенів.';
  }

  @override
  String get obsScreenSubtitle =>
      'Керування агентами наживо, атрибуція витрат, квоти та сигнали якості';

  @override
  String get obsRangeLast24h => 'Останні 24 години';

  @override
  String get obsRangeLast7d => 'Останні 7 днів';

  @override
  String get obsRangeLast30d => 'Останні 30 днів';

  @override
  String get obsRangeAll => 'Весь час';

  @override
  String get obsAddFilter => 'Додати фільтр';

  @override
  String get obsFilterAgent => 'Агент';

  @override
  String get obsFilterModel => 'Модель';

  @override
  String get obsFilterStatus => 'Статус';

  @override
  String get obsFilterRole => 'Роль';

  @override
  String get obsKpiTotalRuns => 'Усього запусків';

  @override
  String get obsKpiTotalCost => 'Загальна вартість';

  @override
  String get obsKpiErrorRate => 'Частота помилок';

  @override
  String get obsKpiCacheRate => 'Частка кешу';

  @override
  String get obsKpiTokensPerSec => 'Токени / с';

  @override
  String get obsKpiAvgLatency => 'Середня затримка';

  @override
  String get obsKpiTtft => 'Час до першого токена';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta порівняно з попереднім періодом';
  }

  @override
  String get obsChartActivity => 'Активність';

  @override
  String get obsChartCost => 'Вартість у часі';

  @override
  String get obsLegendRuns => 'Запуски';

  @override
  String get obsLegendErrors => 'Помилки';

  @override
  String get obsAgentsTitle => 'Агенти';

  @override
  String obsShowAllAgents(int count) {
    return 'Показати всіх $count агентів';
  }

  @override
  String get obsShowFewerAgents => 'Показати менше';

  @override
  String get obsRunsTitle => 'Запуски';

  @override
  String get obsNoRunsInRange => 'У цьому діапазоні немає запусків';

  @override
  String get obsColTime => 'Час';

  @override
  String get obsColAgent => 'Агент';

  @override
  String get obsColStatus => 'Статус';

  @override
  String get obsColModel => 'Модель';

  @override
  String get obsColDuration => 'Тривалість';

  @override
  String get obsColTokens => 'Токени';

  @override
  String get obsColCost => 'Вартість';

  @override
  String get obsColErrors => 'Помилки';

  @override
  String get obsColRuns => 'Запуски';

  @override
  String get obsColAvgLatency => 'Середня затримка';

  @override
  String get obsColLastActive => 'Остання активність';

  @override
  String get obsStatusPending => 'Очікування';

  @override
  String get obsStatusRunning => 'Виконується';

  @override
  String get obsStatusCompleted => 'Завершено';

  @override
  String get obsStatusError => 'Помилка';

  @override
  String get obsRosterLoadError => 'Не вдалося завантажити список агентів.';

  @override
  String get obsRosterEmpty => 'Агентів ще немає';

  @override
  String get obsRosterEmptyDescription =>
      'Запустіть агента — він з’явиться тут наживо: статус, поточний інструмент, токени, вартість.';

  @override
  String get obsKillAgent => 'Зупинити агента';

  @override
  String get obsRosterTokensLabel => 'ток';

  @override
  String get obsCostByRoleTitle => 'Вартість за роллю';

  @override
  String get obsCostByRoleSubtitle =>
      'Куди витрачає цей робочий простір, за роллю агента';

  @override
  String get obsRoleMain => 'Основний';

  @override
  String get obsRoleSubagents => 'Субагенти';

  @override
  String get obsRoleAdvisor => 'Радник';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'Основний: $main · субагенти: $sub · радник: $advisor';
  }

  @override
  String get obsTotal => 'Разом';

  @override
  String get obsTokenModelTitle => 'Модель токенів (5 осей)';

  @override
  String get obsTokenModelSubtitle =>
      'Усі токени, витрачені цим робочим простором, за осями';

  @override
  String get obsAxisInput => 'Вхід';

  @override
  String get obsAxisOutput => 'Вихід';

  @override
  String get obsAxisReasoning => 'Міркування';

  @override
  String get obsAxisCacheRead => 'Читання кешу';

  @override
  String get obsAxisCacheWrite => 'Запис у кеш';

  @override
  String get obsTotalTokens => 'Усього токенів';

  @override
  String get obsCacheDiscountNote =>
      'Токени читання кешу тарифікуються зі знижкою, тож коштують значно менше, ніж такий самий обсяг нового входу.';

  @override
  String get obsByModelTitle => 'За моделлю';

  @override
  String get obsByModelSubtitle => 'Використання токенів і вартості за моделлю';

  @override
  String get obsNoModelUsage => 'Використання моделей ще не записано.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count запуску',
      many: '$count запусків',
      few: '$count запуски',
      one: '$count запуск',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => 'На запуск';

  @override
  String get obsPerRunSubtitle => 'Типові витрати токенів на один запуск';

  @override
  String get obsMedianRunTokens => 'Медіана токенів запуску';

  @override
  String get obsMedianRunTokensSub => 'Середина за всіма запусками';

  @override
  String get obsRunsInWorkspace => 'У цьому робочому просторі';

  @override
  String get obsCostShare => 'Частка витрат';

  @override
  String get obsQuotaConfiguredLimits => 'Налаштовані ліміти';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'Використання відносно заданих вами стель, спочатку найгірший статус.';

  @override
  String get obsQuotaAddLimit => 'Додати ліміт';

  @override
  String get obsQuotaNoLimits =>
      'Квотні ліміти ще не налаштовано — додайте один, щоб відстежувати використання відносно стелі.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'Видалити ліміт $title';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'Скидається через $duration · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'Вікна використання';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'Спостережуване використання за всіма провайдерами, без застосування стелі.';

  @override
  String get obsQuotaNoUsage => 'Використання ще не записано.';

  @override
  String get obsQuotaTokensUsed => 'Використано токенів';

  @override
  String get obsQuotaRequests => 'Запити';

  @override
  String get obsQuotaUnitTokens => 'токени';

  @override
  String get obsQuotaUnitRequests => 'запити';

  @override
  String get obsQuotaUnitCost => 'вартість';

  @override
  String get obsQuotaAddLimitTitle => 'Додати ліміт квоти';

  @override
  String get obsQuotaProviderLabel => 'Провайдер';

  @override
  String get obsQuotaWindowLabel => 'Вікно';

  @override
  String get obsQuotaUnitLabel => 'Одиниця';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'Ліміт ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'У центах США (500 = \$5.00).';

  @override
  String get obsQuotaStatusOk => 'Ок';

  @override
  String get obsQuotaStatusWarning => 'Попередження';

  @override
  String get obsQuotaStatusExhausted => 'Вичерпано';

  @override
  String get obsQuotaStatusUnknown => 'Невідомо';

  @override
  String get obsGoalNoActiveTitle => 'Немає активної цілі';

  @override
  String get obsGoalNoActiveBody =>
      'Задайте ціль, щоб дати агентам завдання й необов’язковий бюджет токенів. У міру завершення запусків бюджет заповнюється, і агентів підштовхують завершити роботу, коли він майже вичерпаний.';

  @override
  String get obsGoalSetGoal => 'Задати ціль';

  @override
  String get obsGoalTokenBudget => 'Бюджет токенів';

  @override
  String obsGoalTokensLeft(String tokens) {
    return 'залишилось $tokens';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (бюджет не задано)';
  }

  @override
  String get obsGoalTokensUsed => 'Використано токенів';

  @override
  String get obsGoalElapsed => 'Минуло';

  @override
  String get obsGoalWrapUp => 'Завершити';

  @override
  String get obsGoalClear => 'Скинути ціль';

  @override
  String get obsGoalFallbackTitle => 'Ціль';

  @override
  String get obsGoalSubtitle => 'Бюджет режиму цілей';

  @override
  String get obsGoalStatusActive => 'Активна';

  @override
  String get obsGoalStatusPaused => 'Призупинена';

  @override
  String get obsGoalStatusBudgetLimited => 'Обмежена бюджетом';

  @override
  String get obsGoalStatusComplete => 'Завершена';

  @override
  String get obsGoalStatusDropped => 'Скасована';

  @override
  String get obsGoalObjectiveLabel => 'Завдання';

  @override
  String get obsGoalBudgetLabel => 'Бюджет токенів (необов’язково)';

  @override
  String get obsGoalSetAction => 'Задати ціль';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => 'Успіх %';

  @override
  String get obsBenchmarkPassed => 'Пройдено';

  @override
  String get obsBenchmarkFailed => 'Провалено';

  @override
  String get obsBenchmarkErrors => 'Помилки';

  @override
  String get obsBenchmarkSpend => 'Витрати';

  @override
  String get obsBenchmarkCostPerTask => 'Вартість / завдання';

  @override
  String get obsBenchmarkTrials => 'Спроби';

  @override
  String get obsBenchmarkNoTrials => 'Поки немає прогонів для оцінки.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'І ще $count',
      many: 'І ще $count',
      few: 'І ще $count',
      one: 'І ще $count',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'Пройдено';

  @override
  String get obsBenchmarkTrialFail => 'Провалено';

  @override
  String get obsBenchmarkTrialError => 'Помилка';

  @override
  String get obsBenchmarkTrialRunning => 'Виконується';

  @override
  String get obsBenchmarkReward => 'Винагорода';

  @override
  String get obsBenchmarkReport => 'Звіт';

  @override
  String get obsBenchmarkCopyMarkdown => 'Копіювати markdown';

  @override
  String get obsBenchmarkCopied => 'Звіт скопійовано в буфер обміну';

  @override
  String get obsBehaviorCaption =>
      'Це сигнали роздратування з ваших повідомлень — зріз стану розмови, а не оцінка агентів. Обчислюється локально; нічого не покидає цей пристрій.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'Проаналізовано повідомлень';

  @override
  String get obsBehaviorTotalSignals => 'Усього сигналів';

  @override
  String get obsBehaviorYelling => 'Крик';

  @override
  String get obsBehaviorProfanity => 'Нецензурна лексика';

  @override
  String get obsBehaviorAnguish => 'Розпач';

  @override
  String get obsBehaviorNegation => 'Заперечення';

  @override
  String get obsBehaviorRepetition => 'Повторення';

  @override
  String get obsBehaviorBlame => 'Обвинувачення';

  @override
  String get obsBehaviorConversationsTitle =>
      'Розмови з найбільшим роздратуванням';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'Ранжовано за щільністю сигналів у ваших повідомленнях.';

  @override
  String get obsBehaviorNoSignals =>
      'Сигналів роздратування не виявлено — усе спокійно.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count messages analyzed';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count signals';
  }

  @override
  String get obsAgentStatusIdle => 'Очікує';

  @override
  String get obsAgentStatusParked => 'Припарковано';

  @override
  String get obsAgentStatusAborted => 'Перервано';

  @override
  String get obsAgentKindSub => 'Суб';

  @override
  String get noChecksOnCommit => 'На цьому коміті перевірки ще не запускалися.';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Виконується — $count завдань',
      many: 'Виконується — $count завдань',
      few: 'Виконується — $count завдання',
      one: 'Виконується — 1 завдання',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Усі перевірки пройдено — $count завдань',
      many: 'Усі перевірки пройдено — $count завдань',
      few: 'Усі перевірки пройдено — $count завдання',
      one: 'Усі перевірки пройдено — 1 завдання',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Завершено — $count завдань',
      many: 'Завершено — $count завдань',
      few: 'Завершено — $count завдання',
      one: 'Завершено — 1 завдання',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total завдань',
      many: '$total завдань',
      few: '$total завдань',
      one: '1 завдання',
    );
    return '$failed з $_temp0 провалено';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count завдань',
      many: '$count завдань',
      few: '$count завдання',
      one: '1 завдання',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'Матриця: $jobId';
  }

  @override
  String get jobLogsPending =>
      'Журнал з\'явиться тут, коли завдання завершиться.';

  @override
  String get jobLogsUnavailable => 'Журнал для цього завдання недоступний.';

  @override
  String get noLogsForStep => 'Для цього кроку журнал не записано.';

  @override
  String get jobLogsTruncated => 'Журнал обрізано — показано найновіший вивід.';

  @override
  String get fullLog => 'Повний журнал';

  @override
  String get copyLogs => 'Копіювати журнал';

  @override
  String get resizeGraph => 'Перетягніть, щоб змінити розмір графа';

  @override
  String workflowRunStartedAgo(String time) {
    return 'Запущено $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'Завершено $time';
  }

  @override
  String get chatBridgesTitle => 'Чат-мости';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'Згадайте бота в $provider, щоб поставити агента на завдання, або створюйте тікети командою $command.';
  }

  @override
  String chatConnectProvider(String provider) {
    return 'Підключити $provider';
  }

  @override
  String get chatDisconnectProvider => 'Відключити';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName у $teamName';
  }

  @override
  String get chatStateLive => 'Наживо';

  @override
  String get chatStateConnecting => 'Підключення…';

  @override
  String get chatStateError => 'Помилка з\'єднання';

  @override
  String get chatNotConnected => 'Не підключено';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'Потокова передача вимкнена для цього застосунку $provider — відповіді надходять одним повідомленням.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'Лише адміністратор може підключити $provider для цього робочого простору.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'Створіть застосунок $provider і вставте його облікові дані сюди. Control Center сам підключається до $provider, тож цьому серверу не потрібна публічна адреса.';
  }

  @override
  String chatOpenConsole(String provider) {
    return 'Відкрити консоль $provider';
  }

  @override
  String get chatOpenSetupGuide => 'Інструкція з налаштування';

  @override
  String get chatFieldBotToken => 'Токен бота';

  @override
  String get chatFieldAppToken => 'Токен застосунку';

  @override
  String get chatFieldConfigRefreshToken => 'Токен конфігурації застосунку';

  @override
  String chatFieldOptional(String label) {
    return '$label (необов\'язково)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'Прив\'язати мій обліковий запис $provider';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'Прив\'яжіть обліковий запис $provider, щоб повідомлення, які ви надсилаєте там, приписувалися вам.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'Прив\'язано до $externalUserId';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'Прив\'яжіть обліковий запис $provider';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'Надішліть цю команду боту в $provider. Вона спрацює один раз і втратить чинність за 15 хвилин.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'Обліковий запис $provider прив\'язано — повідомлення, які ви надсилаєте там, приписуються вам.';
  }

  @override
  String get chatLinkedAccounts => 'Прив\'язані облікові записи';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'Ще ніхто не прив\'язав обліковий запис $provider.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count прив\'язаних облікових записів',
      many: '$count прив\'язаних облікових записів',
      few: '$count прив\'язані облікові записи',
      one: '$count прив\'язаний обліковий запис',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · зіставлено за email';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · прив\'язано кодом';
  }

  @override
  String get chatUnlink => 'Відв\'язати';

  @override
  String get chatCustomizeBot => 'Налаштувати бота';

  @override
  String get chatCustomizeBotDescription =>
      'Перейменуйте бота, змініть, що він каже про себе, або перейменуйте slash-команду.';

  @override
  String get chatCustomizeBotUnavailable =>
      'Control Center потрібен токен конфігурації застосунку, щоб редагувати бота. Підключіться знову й додайте його.';

  @override
  String chatCreateAppTitle(String provider) {
    return 'Створіть застосунок $provider';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center може створити застосунок $provider за вас — із потрібними дозволами та подіями. Завершите в $provider, потім вставте облікові дані сюди.';
  }

  @override
  String get chatCreateApp => 'Створити застосунок';

  @override
  String get chatCreateAppCta => 'Створити застосунок за мене';

  @override
  String get chatAppNameLabel => 'Назва застосунку';

  @override
  String get chatBotDisplayNameLabel =>
      'Ім\'я бота (що учасники вводять після @)';

  @override
  String get chatDescriptionLabel => 'Короткий опис';

  @override
  String get chatAgentDescriptionLabel => 'Що бот каже, що вміє';

  @override
  String get chatCommandLabel => 'Slash-команда';

  @override
  String get chatDirectMessages => 'Особисті повідомлення';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'Дозволяє учасникам спілкуватися з ботом в особистих повідомленнях. Може знадобитися платний план $provider.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$provider створив застосунок $appId.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'Залишилося кілька кроків, які може виконати лише $provider:';
  }

  @override
  String get chatStepAppToken => 'Згенеруйте токен рівня застосунку';

  @override
  String get chatStepInstall => 'Встановіть застосунок';

  @override
  String get chatOpenAppSettings => 'Відкрити налаштування застосунку';

  @override
  String get chatContinueToCredentials => 'Вставити облікові дані';

  @override
  String chatBotUpdated(String provider) {
    return 'Бота оновлено в $provider.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$provider змінив дозволи застосунку. Перевстановіть застосунок, щоб вони набули чинності.';
  }

  @override
  String get chatReinstallApp => 'Перевстановити застосунок';

  @override
  String chatIconNotEditable(String provider) {
    return 'Іконку бота можна змінити лише в налаштуваннях застосунку $provider.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'Можете також створити його самостійно в $provider — токен не потрібен. Налаштування вище передаються з посиланням.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'Створити в $provider';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '$provider відкрито в браузері з уже заповненою конфігурацією. Створіть застосунок там, завершіть ці кроки й поверніться з токенами.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider не повідомляє, який застосунок створено, тому щоб налаштувати бота звідси, пізніше знадобиться токен конфігурації застосунку.';
  }

  @override
  String get chatStepCreateApp =>
      'Створіть застосунок із попередньо заповненої конфігурації';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'Оберіть робочий простір у $provider і підтвердьте.';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens, зі scope connections:write.';

  @override
  String get chatStepInstallHint =>
      'Install app → скопіюйте bot user OAuth token.';

  @override
  String get calendarUseBuiltinApp =>
      'Використовувати застосунок Google від Control Center';

  @override
  String get calendarUseBuiltinAppHint =>
      'Підтвердьте своїм обліковим записом Google. Нічого налаштовувати в Google Cloud.';

  @override
  String get calendarUseOwnClient =>
      'Використовувати власний клієнт Google Cloud';

  @override
  String get calendarUseOwnClientHint =>
      'Вкажіть OAuth-клієнт зі свого проєкту Google Cloud.';

  @override
  String get aboutTitle => 'Про програму';

  @override
  String get aboutAppVersion => 'Версія застосунку';

  @override
  String get aboutServerVersion => 'Підключений сервер';

  @override
  String get aboutRpcCatalog => 'Каталог RPC';

  @override
  String get aboutServerUnknown => 'Не повідомлено';

  @override
  String get serverStaleTitle => 'Вбудований сервер старіший за цей застосунок';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'Запущений cc_server — $serverVersion, а цей застосунок — $appVersion. Перезапустіть застосунок, щоб підхопити найновішу вбудовану збірку сервера; у розробці зберіть її командою `dart build cli` у apps/cc_server.';
  }

  @override
  String get updateCheckButton => 'Перевірити оновлення';

  @override
  String get updateChecking => 'Перевірка оновлень…';

  @override
  String get updateUpToDate => 'У вас остання версія';

  @override
  String get updateDeferredBusy =>
      'Оновлення готове, але триває запис зустрічі — запит з’явиться після завершення.';

  @override
  String get updateOpenedReleasesPage =>
      'Сторінку випусків відкрито в браузері.';

  @override
  String get updateCheckFailed => 'Не вдалося перевірити оновлення';

  @override
  String updateAvailableVersion(String version) {
    return 'Доступна версія $version.';
  }

  @override
  String get updateBannerTitle => 'Доступна нова версія Control Center';

  @override
  String get updateBannerRefresh => 'Оновити';

  @override
  String get updateBlockedRecording =>
      'Оновлення призупинено, поки триває запис зустрічі — перезавантаження відбудеться після завершення.';

  @override
  String get settingsScopeYou => 'Ви';

  @override
  String get settingsScopeWorkspace => 'Робочий простір';

  @override
  String get settingsScopeServer => 'Сервер';

  @override
  String get settingsProfile => 'Профіль і ідентичність';

  @override
  String get settingsYourDevices => 'Ваші пристрої';

  @override
  String get settingsWorkspaceGeneral => 'Загальні';

  @override
  String get settingsServerConnection => 'Підключення та стан';

  @override
  String get settingsModelProviders => 'Постачальники моделей';

  @override
  String get settingsVoiceModels => 'Моделі голосу та зустрічей';

  @override
  String get settingsDiagnostics => 'Діагностика та приватність';

  @override
  String get settingsAbout => 'Про програму';

  @override
  String get settingsScopeBadgeYou => 'ВИ';

  @override
  String get settingsScopeBadgeDevice => 'ЦЕЙ ПРИСТРІЙ';

  @override
  String get settingsScopeBadgeWorkspace => 'РОБОЧИЙ ПРОСТІР';

  @override
  String get settingsScopeBadgeServer => 'СЕРВЕР';

  @override
  String get settingsProfileDescription =>
      'Ваше ім\'я, пошта й git-ідентичність у цьому просторі. Зміна простору змінює цей шар; псевдонім, вхід і пристрої лишаються на обліковому записі.';

  @override
  String get settingsServerConnectionDescription =>
      'З яким сервером спілкується цей клієнт і як сервер поширюється (mDNS, тунелі, реле).';

  @override
  String get settingsAboutDescription => 'Ідентичність збірки та оновлення.';

  @override
  String get settingsDiagnosticsDescription =>
      'Ізоляція, індексування, синхронізація, журналювання та звіти про збої для цієї інсталяції.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'Ідентичність, політика та угоди, спільні для всіх у цьому робочому просторі.';

  @override
  String get settingsWorkspaceMeetingsDescription =>
      'Шаблони нотаток і збережені голоси для зустрічей у цьому робочому просторі.';

  @override
  String get settingsWorkspacePolicyLabel => 'Політика робочого простору';

  @override
  String get settingsWorkspacePolicyDescription =>
      'Застосовується до кожного учасника й кожного агента в цьому робочому просторі.';

  @override
  String get settingsSecretGlobsLabel => 'Виключення секретних шляхів';

  @override
  String get settingsSecretGlobsHelp =>
      'Один glob на рядок. Ці шляхи приховано від глядачів і гостей на поверхнях із кодом, на додачу до вбудованих типових.';

  @override
  String get settingsReviewConcurrencyLabel => 'Розпаралелення рев’ю';

  @override
  String get settingsReviewConcurrencyHelp =>
      'Скільки рецензентів запускається паралельно, якщо кількість не вказано явно.';

  @override
  String get settingsReviewLevelLabel => 'Рівень рев’ю';

  @override
  String get settingsReviewLevelHelp =>
      'Наскільки глибоко йде AI-рев’ю і скільки знахідок показується одразу. Нічого не відкидається — легший рівень групує дрібні знахідки, а не прибирає їх.';

  @override
  String get reviewLevelLight => 'Легкий';

  @override
  String get reviewLevelBalanced => 'Збалансований';

  @override
  String get reviewLevelThorough => 'Ретельний';

  @override
  String get reviewLevelLightHint =>
      'Один рецензент. Одразу показується лише те, що справді важливо.';

  @override
  String get reviewLevelBalancedHint =>
      'Три рецензенти: QA, архітектура та реалізація.';

  @override
  String get reviewLevelThoroughHint =>
      'Додає спеціалістів з безпеки та продуктивності й повідомляє про все знайдене.';

  @override
  String get askAiReviewAtLevel => 'Рев’ю на іншому рівні';

  @override
  String reviewNitpicksGroup(int count) {
    return 'Дрібниці ($count)';
  }

  @override
  String get reviewFindingResolve => 'Виправлено';

  @override
  String get reviewFindingResolveHint =>
      'Позначити знахідку як виправлену. Вона більше не враховується в рев’ю.';

  @override
  String get reviewFindingDismiss => 'Відхилити';

  @override
  String get reviewFindingDismissHint =>
      'Це не справжня проблема. Рецензенти більше не позначатимуть цей шаблон у майбутніх PR.';

  @override
  String get reviewFindingReopen => 'Відкрити знову';

  @override
  String get reviewFindingStatusUndoLabel => 'Статус знахідки';

  @override
  String get reviewFindingDismissTitle => 'Відхилити цю знахідку';

  @override
  String get reviewFindingDismissReasonHint =>
      'Чому це не застосовується? Рецензенти це прочитають.';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'Не вдалося оновити знахідку: $error';
  }

  @override
  String get reviewStaleTitle => 'Це рев’ю застаріло';

  @override
  String get reviewStaleBody =>
      'Pull request змінився після цього рев’ю. Знахідки можуть вказувати на код, якого вже немає.';

  @override
  String reviewStaleReviewedAt(String sha) {
    return 'Рев’ю на $sha';
  }

  @override
  String get reviewStaleRerun => 'Рев’ю ще раз';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return 'Застаріле рев’ю в #$prNumber';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return 'У $title з’явилися нові коміти після останнього рев’ю.';
  }

  @override
  String get reviewCategorySecurity => 'Безпека';

  @override
  String get reviewCategoryStability => 'Стабільність';

  @override
  String get reviewCategoryDataIntegrity => 'Цілісність даних';

  @override
  String get reviewCategoryCorrectness => 'Коректність';

  @override
  String get reviewCategoryPerformance => 'Продуктивність';

  @override
  String get reviewCategoryMaintainability => 'Супроводжуваність';

  @override
  String get reviewEffortQuickWin => 'Швидка перемога';

  @override
  String get reviewEffortModerate => 'Помірно';

  @override
  String get reviewEffortHeavyLift => 'Великий обсяг';

  @override
  String get reviewProposedFix => 'Пропоноване виправлення';

  @override
  String get reviewAiAgentPrompt => 'Промпт для AI-агентів';

  @override
  String get reviewCopyAiPrompt => 'Копіювати промпт';

  @override
  String get settingsWorkspaceAdminOnly =>
      'Змінювати це можуть лише адміністратори робочого простору.';

  @override
  String get chatMyAccountsTitle => 'Прив\'язані облікові записи чату';

  @override
  String get settingsServerSso => 'Єдиний вхід';

  @override
  String get settingsServerSsoDescription =>
      'Вхід через SAML і OpenID Connect із підготовкою користувачів';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription =>
      'Користувачі можуть входити через цього провайдера';

  @override
  String get ssoEnabledDescriptionOn =>
      'Вхід через цього провайдера вже активний';

  @override
  String get ssoIdpMetadataLabel => 'XML метаданих IdP';

  @override
  String get ssoIdpMetadataHint => 'вставте XML EntityDescriptor вашого IdP';

  @override
  String get ssoEmailAttributeLabel => 'Атрибут email';

  @override
  String get ssoDisplayNameAttributeLabel => 'Атрибут відображуваного імені';

  @override
  String get ssoGroupsAttributeLabel => 'Атрибут груп';

  @override
  String get ssoIssuerLabel => 'URL видавця';

  @override
  String get ssoClientIdLabel => 'Ідентифікатор клієнта';

  @override
  String get ssoGroupsClaimLabel => 'Клейм груп';

  @override
  String get ssoAutoMemberLabel =>
      'Додавати користувачів до кожного робочого простору під час першого входу';

  @override
  String get ssoAutoMemberDescription =>
      'Вимкніть, щоб вимагати запрошення для кожного робочого простору';

  @override
  String get ssoAllowJitLabel =>
      'Створювати невідомих користувачів під час першого входу';

  @override
  String get ssoAllowJitDescription =>
      'Вимкніть, щоб відхиляти користувачів без наявного облікового запису';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'Приймати незапитаний вхід (ініційований IdP)';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'Лише для порталів IdP, які запускають застосунки безпосередньо';

  @override
  String get ssoWantResponseSignedLabel =>
      'Вимагати підписаний конверт відповіді';

  @override
  String get ssoWantResponseSignedDescription =>
      'Підписи Assertion завжди обов\'язкові';

  @override
  String get ssoTestConnectionButton => 'Перевірити з\'єднання';

  @override
  String get ssoTestConnectionOk => 'З\'єднання працює:';

  @override
  String get ssoCopySpMetadata => 'Копіювати метадані SP';

  @override
  String get ssoCopySpMetadataDone => 'Метадані SP скопійовано в буфер обміну';

  @override
  String get ssoSavedToast => 'Налаштування єдиного входу збережено';

  @override
  String get ssoUnavailable =>
      'Цей сервер не надає налаштування єдиного входу. Оновіть бінарний файл сервера й спробуйте ще раз.';

  @override
  String get ssoScimCardTitle => 'Підготовка користувачів (SCIM)';

  @override
  String get ssoScimDescription =>
      'Направте SCIM-конектор свого провайдера ідентифікації на кінцеву точку нижче з bearer-токеном. Скасування підготовки відкликає сесії та доступ до робочого простору за лічені секунди. Сервер має бути доступний для IdP (тунель або публічний URL).';

  @override
  String get ssoScimEndpoint => 'Кінцева точка SCIM';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'Спочатку вкажіть публічний URL сервера або ввімкніть тунель';

  @override
  String get ssoScimRegenerate => 'Перегенерувати токен';

  @override
  String get ssoScimRegenerateConfirm =>
      'Згенерувати новий bearer-токен SCIM? Попередній токен одразу перестане працювати.';

  @override
  String get ssoScimTokenTitle => 'Bearer-токен';

  @override
  String get ssoScimTokenPresent => 'Токен налаштовано';

  @override
  String get ssoScimTokenAbsent =>
      'Токена ще немає — згенеруйте його, щоб увімкнути SCIM';

  @override
  String get ssoScimTokenOnce => 'Токен SCIM (показується один раз)';

  @override
  String ssoSignInWith(String provider) {
    return 'Увійти через $provider';
  }

  @override
  String get ssoProbeFailed =>
      'Не вдалося з\'єднатися з цим сервером для єдиного входу';

  @override
  String get ssoOpensBrowser => 'Відкриває браузер, щоб завершити вхід';

  @override
  String get ssoWaitingForBrowser => 'Очікування, поки браузер завершить вхід…';

  @override
  String get ssoBrowserOpenFailed =>
      'Не вдалося відкрити браузер для єдиного входу';

  @override
  String get ssoUseManualPairing =>
      'Увійти за запрошенням або ключем парування';

  @override
  String get ssoHideManualPairing => 'Приховати ручне парування';

  @override
  String get ssoClientIdHint => 'Публічний клієнт (PKCE) — секрет не потрібен';

  @override
  String get ssoClientSecretLabel => 'Секрет клієнта (необов\'язково)';

  @override
  String get ssoClientSecretHintUnset =>
      'Потрібен лише для конфіденційних клієнтів IdP';

  @override
  String get ssoClientSecretHintSet =>
      'Секрет уже збережено — залиште порожнім, щоб не змінювати';

  @override
  String get ssoPairingToggle =>
      'Дозволити ручне спарювання (коди запрошень і ключі спарювання)';

  @override
  String get ssoPairingToggleDescription =>
      'Вимкніть, щоб приєднання було лише через SSO — нові пристрої з’являються після входу через SSO; наявні продовжать працювати';

  @override
  String get ssoPairConfirmTitle => 'Під’єднатися до сервера?';

  @override
  String ssoPairConfirmBody(String server) {
    return 'Надійшли облікові дані для входу на $server, але вхід із цього застосунку не починали. Під’єднатися до цього сервера?';
  }

  @override
  String get ssoPairConfirmConnect => 'Під’єднатися';

  @override
  String get ssoPairConfirmCancel => 'Ігнорувати';

  @override
  String get forgeConnections => 'Хостинг коду';

  @override
  String get connect => 'Під’єднатися';

  @override
  String get disconnect => 'Від’єднатися';

  @override
  String get notConnected => 'Не під’єднано';

  @override
  String get checkingConnection => 'Перевірка з’єднання…';

  @override
  String get fromEnvironment => 'із середовища';

  @override
  String forgeTokenTitle(String forge) {
    return 'Токен $forge';
  }

  @override
  String get settingsAudio => 'Аудіо';

  @override
  String get settingsAudioDescription =>
      'Мікрофон, диктування, виявлення нарад і вивід саундскейпу.';

  @override
  String get audioDevicesSection => 'Аудіопристрої';

  @override
  String get voiceInputBehaviorSection => 'Диктування й наради';

  @override
  String get audioOutputDeviceTitle => 'Пристрій виводу';

  @override
  String get audioOutputDefaultHint =>
      'Увесь звук застосунку відтворюється через системний вивід за замовчуванням.';

  @override
  String get audioOutputGone =>
      'Вибраний пристрій виводу більше не під’єднано — доки не оберете інший, використовується системний за замовчуванням.';

  @override
  String get reviewHubIntroBody =>
      'Агенти аналізують diff, мапують зони змін і формують узгоджений вердикт.';

  @override
  String get reviewHubAlreadyRunning =>
      'Для цього pull request уже триває рев’ю';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'Від попереднього рев’ю: $resolved вирішено · $added нових · $open ще відкрито';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'Попереднє рев’ю на $sha';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return 'Виправити $count зауважень';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return 'Виправити $count вибраних';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return 'Прокоментувати $count вибраних';
  }

  @override
  String get webConnectTitle => 'Під’єднатися до Control Center';

  @override
  String get webConnectSubtitle =>
      'Підключіться до запущеного cc-server через WebSocket. Ключ залишається на цьому пристрої.';

  @override
  String get webConnectServerLabel => 'Сервер';

  @override
  String get webConnectDeviceIdLabel => 'Ідентифікатор пристрою';

  @override
  String get webConnectPairingKeyLabel => 'Ключ спарювання';

  @override
  String get webConnectPairingKeyHint => 'вставте PSK';

  @override
  String get webConnectStayConnected =>
      'Залишатися під’єднаним на цьому пристрої';

  @override
  String get webConnectStayConnectedDetail =>
      'Залишатися під’єднаним на цьому пристрої (ключ зберігається в цьому браузері)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'Не вдалося створити робочий простір: $error';
  }

  @override
  String committedRelative(String relative) {
    return 'закомічено $relative';
  }

  @override
  String get selectAgents => 'Вибрати агентів';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count агента',
      many: '$count агентів',
      few: '$count агенти',
      one: '$count агент',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => 'Нова розмова';

  @override
  String get untitledConversation => 'Розмова без назви';

  @override
  String get conversationTitleOptionalHint =>
      'Необов’язково — залиште порожнім, і модель назв задасть назву автоматично';

  @override
  String get conversationTitlesSectionTitle => 'Назви розмов';

  @override
  String get conversationTitlesSectionCaption =>
      'Оберіть раннер, який автоматично називає нові розмови в цьому робочому просторі. Назви вимкнені, доки не вибрано адаптер, і діють для всіх учасників.';

  @override
  String get conversationTitlesModelLabel => 'Модель назв';

  @override
  String get conversationTitlesAdapterLabel => 'Адаптер';

  @override
  String get conversationTitlesAdapterHint => 'Вимкнено';

  @override
  String get conversationTitlesAdapterOff => 'Вимкнено';

  @override
  String get startThread => 'Почати гілку';

  @override
  String get deleteSpaceConfirm =>
      'Видалити цей простір? Усі повідомлення буде втрачено.';

  @override
  String threadTabTitle(String title) {
    return 'Гілка: $title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count відповіді',
      many: '$count відповідей',
      few: '$count відповіді',
      one: '$count відповідь',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return 'Остання відповідь $time';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Увійти через $provider';
  }

  @override
  String get signInAgain => 'Увійти ще раз';

  @override
  String get signInNotFinished =>
      'Вхід ще не завершився. Завершіть його в браузері, потім перевірте знову.';

  @override
  String get signedOutTitle => 'Ви вийшли з облікового запису';

  @override
  String get signedOutSubtitle =>
      'Підключення до хостингу коду більше не чинне — токен закінчився або доступ відкликано. Нічого більше не змінилося: увійдіть знову, і все залишиться на своїх місцях.';

  @override
  String get viaServerApp => 'через застосунок цього сервера';

  @override
  String get ticketing => 'Тікетинг';

  @override
  String get ticketingProviderHelp =>
      'Де зберігаються ваші тікети. Локально залишає їх у Control Center.';

  @override
  String providerComingSoon(String provider) {
    return '$provider (скоро)';
  }

  @override
  String get ticketProviderLocal => 'Локально';

  @override
  String get addKey => 'Додати ключ';

  @override
  String get providerApps => 'Застосунки провайдера';

  @override
  String get providerAppsDescription =>
      'Простори успадковують цей GitHub App, якщо не оберуть інший App або персональний токен. Фонова робота — вебхуки, опитування, синхронізація — йде на застосунку, ніколи на токені людини.';

  @override
  String get providerAppId => 'ID застосунку';

  @override
  String get providerPrivateKey => 'Приватний ключ';

  @override
  String get providerClientId => 'ID клієнта';

  @override
  String get providerClientSecret => 'Секрет клієнта';

  @override
  String get providerApiKey => 'API-ключ';

  @override
  String get providerCallbackUrl => 'URL зворотного виклику';

  @override
  String get providerAppFullyConfigured =>
      'Сервер може діяти від свого імені, і люди можуть входити.';

  @override
  String get providerAppServerOnly =>
      'Сервер може діяти від свого імені. Додайте ID клієнта та секрет, щоб люди могли входити.';

  @override
  String get providerAppSignInOnly =>
      'Люди можуть входити. Фонова робота переходить на їхні облікові дані.';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'Облікові дані працюють. Установлено на: $accounts';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return 'Введіть цей код на сторінці $provider, яка щойно відкрилася. Його скопійовано в буфер обміну.';
  }

  @override
  String get deviceCodeWaiting => 'Очікуємо, поки ви завершите в браузері…';

  @override
  String get copyCodeAndOpen => 'Скопіювати код і відкрити';

  @override
  String get couldNotOpenBrowser =>
      'Не вдалося відкрити браузер. Скопіюйте посилання й завершіть вхід самостійно.';

  @override
  String get contextUsage => 'Використання контексту';

  @override
  String get contextUsageFull => 'повний';

  @override
  String get contextUsageTokens => 'токени';

  @override
  String get contextSeeMore => 'Показати більше';

  @override
  String get contextSegmentSystemPrompt => 'Системний промпт';

  @override
  String get contextSegmentRules => 'Правила';

  @override
  String get contextSegmentSkills => 'Навички';

  @override
  String get contextSegmentToolDefinitions => 'Визначення інструментів';

  @override
  String get contextSegmentMcpTools => 'MCP і динамічні інструменти';

  @override
  String get contextSegmentDeferredTools =>
      'Інструменти, що завантажуються за потреби';

  @override
  String get contextSegmentSubagents => 'Визначення субагентів';

  @override
  String get contextSegmentMemory => 'Пам\'ять';

  @override
  String get contextSegmentConversation => 'Розмова';

  @override
  String get contextExplorerTitle => 'Контекст';

  @override
  String get contextExplorerEverything => 'Усе';

  @override
  String get contextExplorerSelectPart =>
      'Виберіть частину, щоб переглянути її вміст';

  @override
  String get contextExplorerUnavailable => 'Розбивка контексту недоступна';

  @override
  String get contextRetry => 'Повторити';

  @override
  String get settingsFieldOptional => 'Необов\'язково';

  @override
  String get settingsFilterHint => 'Фільтрувати цей список';

  @override
  String get settingsValueNotAvailable => 'Ще недоступно';

  @override
  String get settingsNoEntriesYet => 'Тут ще нічого немає';

  @override
  String get settingsChangedBadge => 'Змінено';

  @override
  String get ssoConnectionCardDescription =>
      'Виберіть, як люди входять на цей сервер, а потім увімкніть це з\'єднання.';

  @override
  String get ssoUseSamlForSignIn => 'Використовувати SAML для входу';

  @override
  String get ssoUseOidcForSignIn => 'Використовувати OpenID Connect для входу';

  @override
  String get ssoSaveConnection => 'Зберегти з\'єднання';

  @override
  String get ssoStateLive => 'Працює';

  @override
  String get ssoStateConfiguredOff => 'Налаштовано, вимкнено';

  @override
  String get ssoStateOnIncomplete => 'Увімкнено, неповне';

  @override
  String get ssoStateActive => 'Активно';

  @override
  String get ssoStateAllowed => 'Дозволено';

  @override
  String get ssoStateNoToken => 'Немає токена';

  @override
  String get ssoSummaryDirectorySync => 'Синхронізація каталогу';

  @override
  String get ssoSummaryManualPairing => 'Ручне парування';

  @override
  String get ssoNoMethodLiveNote =>
      'Жоден спосіб входу не працює. Нові пристрої приєднуються за запрошенням або ключем парування, поки ви не налаштуєте з\'єднання й не ввімкнете його.';

  @override
  String get ssoMethodSamlBlurb =>
      'Для постачальників ідентичності, які підтримують SAML 2.0, наприклад Okta, Entra ID або Google Workspace.';

  @override
  String get ssoMethodOidcBlurb =>
      'Для постачальників ідентичності, які підтримують OpenID Connect. Зазвичай простіший у налаштуванні з двох.';

  @override
  String get ssoGroupIdentityProvider => 'Постачальник ідентичності';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'Звідки надходять твердження і як цей сервер їх перевіряє.';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'Якому видавцю довіряє цей сервер і від імені якого клієнта він автентифікується.';

  @override
  String get ssoSpEntityIdShortLabel => 'Entity ID SP';

  @override
  String get ssoSpEntityIdDescription =>
      'Залиште порожнім, щоб вивести з URL сервера.';

  @override
  String get ssoIssuerDescription =>
      'Базовий URL, з якого надається discovery-документ провайдера.';

  @override
  String get ssoSecretStored => 'Збережено';

  @override
  String get ssoGroupHandoff => 'Що потрібно вашому провайдеру ідентифікації';

  @override
  String get ssoGroupHandoffDescription =>
      'Вставте їх у застосунок, який ви створили в провайдері.';

  @override
  String get ssoOriginUnknownTitle => 'Цей сервер не знає свій публічний URL';

  @override
  String get ssoOriginUnknownBody =>
      'URL входу та callback будуються з нього, тож провайдер не зможе достукатися до цього сервера, доки його не задано. Додайте публічний URL або увімкніть тунель у Server → Connection.';

  @override
  String get ssoAcsUrlLabel => 'URL служби споживача тверджень (ACS)';

  @override
  String get ssoAcsUrlDescription =>
      'Куди провайдер надсилає підписане твердження.';

  @override
  String get ssoSpEntityIdResolvedLabel => 'Entity ID постачальника послуг';

  @override
  String get ssoMetadataUrlLabel => 'URL метаданих SP';

  @override
  String get ssoMetadataUrlDescription =>
      'Провайдери, які імпортують метадані, можуть завантажити їх звідси.';

  @override
  String get ssoRedirectUriLabel => 'Redirect URI';

  @override
  String get ssoRedirectUriDescription =>
      'Додайте це до дозволених redirect URI в застосунку провайдера.';

  @override
  String get ssoSignInUrlLabel => 'URL входу';

  @override
  String get ssoSignInUrlDescription =>
      'Надсилайте людей сюди, щоб почати вхід через SSO.';

  @override
  String get ssoGroupAttributeMapping => 'Зіставлення атрибутів';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'У якому клеймі передається кожне поле. Залиште типові значення, якщо провайдер їх не перейменовує.';

  @override
  String get ssoGroupAccess => 'Доступ і ролі';

  @override
  String get ssoGroupAccessDescription =>
      'Що дозволено робити тому, хто успішно ввійшов.';

  @override
  String get ssoDefaultRoleShortLabel => 'Типова роль';

  @override
  String get ssoDefaultRoleDescription =>
      'Призначається всім, чиї групи не збігаються з жодним зіставленням нижче.';

  @override
  String get ssoRoleMapShortLabel => 'Зіставлення груп з ролями';

  @override
  String get ssoRoleMapDescription =>
      'Перемагає перша відповідна група. Owner так призначити не можна.';

  @override
  String get ssoRoleMapGroupHint => 'Назва групи від провайдера';

  @override
  String get ssoRoleMapAdd => 'Додати зіставлення';

  @override
  String get ssoRoleMapEmpty =>
      'Немає зіставлень — усім призначається типова роль.';

  @override
  String get ssoAdvancedSummary =>
      'Розсинхронізація годинників, вхід з ініціативи IdP, політика підпису';

  @override
  String get ssoClockSkewShortLabel => 'Розсинхронізація';

  @override
  String get ssoClockSkewDescription =>
      'Секунди допуску для часових міток тверджень. 90 підходить більшості провайдерів.';

  @override
  String get ssoScimGenerate => 'Згенерувати токен';

  @override
  String get ssoScimTokenOnceBody =>
      'Скопійовано в буфер обміну. Показується лише раз і відновити його не можна, тож вставте в провайдера зараз.';

  @override
  String get ssoPairingCardTitle => 'Парування вручну';

  @override
  String get ssoPairingCardDescription =>
      'Інший спосіб потрапити на цей сервер: коди запрошень і ключі парування — для пристроїв, які не проходять через SSO.';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count з $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'Не підключено жодного провайдера, тож вбудованому середовищу виконання агентів немає на чому працювати. Додайте API-ключ або увійдіть у провайдера нижче.';

  @override
  String get providersFilterHint => 'Фільтрувати провайдерів';

  @override
  String get providersNoneMatch => 'Нічого не відповідає цьому фільтру';

  @override
  String get providerDeniedHereTitle => 'Заборонено в цьому робочому просторі';

  @override
  String get providerDeniedHereBody =>
      'Агенти тут не можуть використовувати цей провайдер, хоч він і підключений. Інших робочих просторів це не стосується.';

  @override
  String get providerNeedsSignIn =>
      'Увійдіть, щоб користуватися цим провайдером';

  @override
  String get providerNeedsApiKey =>
      'Додайте API-ключ, щоб користуватися цим провайдером';

  @override
  String get providerApiKeyLabel => 'API-ключ';

  @override
  String get providerGenerationDefaults => 'Типові параметри провайдера';

  @override
  String get providerNoModelsYet =>
      'Моделей ще не отримано. Підключіть провайдера, потім синхронізуйте.';

  @override
  String get providerModelsFilterHint => 'Фільтрувати моделі';

  @override
  String get adaptersNoneReadyNote =>
      'Жодного з CLI раннерів з каталогу не знайдено на цій машині. Встановіть один, потім оновіть.';

  @override
  String get adaptersFilterHint => 'Фільтрувати раннери';

  @override
  String get adaptersLaunchGroup => 'Запуск';

  @override
  String get adaptersLaunchGroupDescription =>
      'Що отримує цей раннер, коли агент його запускає. Можете задати це ще до встановлення CLI.';

  @override
  String get adaptersEnvNone => 'Не задано';

  @override
  String adaptersEnvCount(int count) {
    return '$count set';
  }

  @override
  String get adapterArgumentsDescription =>
      'Додається до командного рядка раннера при кожному запуску.';

  @override
  String get defaultChatDescription =>
      'Запускає нові розмови та будь-якого агента без власного виконавця.';

  @override
  String get shortTaskDescription =>
      'Виконує швидку фонову роботу, як-от заголовки й підсумки. Сюди пасує менша модель.';

  @override
  String get settingsStateFailed => 'Помилка';

  @override
  String get providerAppsGroupServer => 'Роль сервера';

  @override
  String get providerAppsGroupServerDescription =>
      'Для просторів, що успадковують GitHub App цієї інсталяції. Простір із власним App або PAT налаштовується в Простір → Загальні.';

  @override
  String get providerAppsGroupPrConversations => 'Розмови в pull request';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'Як розробники говорять із цим сервером на GitHub у просторах, що успадковують. Простір із власним App має бота в Простір → Загальні. Без вебхука й публічної URL — сервер опитує.';

  @override
  String get providerAppBotLogin => 'Логін бота';

  @override
  String get providerAppBotLoginEmpty =>
      'Перевірте з’єднання, щоб визначити логін бота.';

  @override
  String get providerAppAskOnGitHub => 'Запити на GitHub';

  @override
  String get providerAppAskOnGitHubHint =>
      'Згадайте логін бота вище в коментарі до pull request — суфікс [bot] необов’язковий — щоб запросити рев’ю чи поставити запитання, відповісти в його гілках рев’ю або додати мітку `ai-review`, щоб запросити рев’ю.';

  @override
  String get providerAppsGroupSignIn => 'Вхід користувачів';

  @override
  String get providerAppsGroupSignInDescription =>
      'Дозволяє кожному учаснику підключити свій обліковий запис і отримати власні облікові дані.';

  @override
  String get providerAppCapActsAsServer => 'Діє як сервер';

  @override
  String get providerAppCapSignsIn => 'Авторизує користувачів';

  @override
  String get portLabel => 'Порт';

  @override
  String get mcpNoTokenWarning =>
      'Без токена все, що має доступ до цього порту, може викликати кожен інструмент.';

  @override
  String get mcpBridgedToolsLabel => 'Інструменти';

  @override
  String get guardrailFamilyFiles => 'Файли';

  @override
  String get guardrailFamilyGit => 'Git і pull request';

  @override
  String get guardrailFamilyMachine => 'Машина й мережа';

  @override
  String get guardrailFamilyControl => 'Секрети й робочий простір';

  @override
  String get guardrailScopeFieldLabel => 'Правила редагування для';

  @override
  String get guardrailScopeFieldDescription =>
      'Вужча область має пріоритет над ширшою. Правила, задані тут, діють поверх успадкованих.';

  @override
  String get guardrailSetHere => 'Задано тут';

  @override
  String get guardrailClearAllHere => 'Очистити все';

  @override
  String get sandboxingCardLabel => 'Пісочниця';

  @override
  String get sandboxingCardDescription =>
      'Чи робота агента виконується ізольовано від цього хоста, і до чого ізольований агент усе ще має доступ.';

  @override
  String get sandboxBackendNoneActive => 'Хост, без ізоляції';

  @override
  String get sandboxSummaryHost => 'Хост';

  @override
  String get sandboxGroupIsolation => 'Ізоляція';

  @override
  String get sandboxGroupIsolationDescription =>
      'Де насправді виконуються процеси агента й запис файлів.';

  @override
  String get sandboxBackendFieldDescription =>
      'Автоматично обирає найсильніший варіант, який підтримує цей хост. Зафіксуйте один, щоб він не змінювався сам.';

  @override
  String get sandboxCapabilitiesDescription =>
      'Прорізи в межі. Кожен — це те, що ізольований агент усе ще може робити із зовнішнім світом.';

  @override
  String get sandboxSummaryInForce => 'Чинне';

  @override
  String get rigsInstallHintLabel => 'Як установити';

  @override
  String get rigsStarting => 'Запуск';

  @override
  String get rigsResidentMemory => 'Резидентна пам’ять';

  @override
  String get installedLabel => 'Установлено';

  @override
  String get notInstalledLabel => 'Не встановлено';

  @override
  String ssoOtherKindUnsaved(String method) {
    return 'У $method є незбережені зміни';
  }

  @override
  String get collapseComment => 'Згорнути коментар';

  @override
  String get expandComment => 'Розгорнути коментар';

  @override
  String get suggestedChange => 'Запропонована зміна';

  @override
  String get emptyComment => 'Порожній коментар';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count відповідей',
      many: '$count відповідей',
      few: '$count відповіді',
      one: '1 відповідь',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => 'Очікує рев’ю';

  @override
  String failedToResolveConversation(String error) {
    return 'Не вдалося оновити розмову: $error';
  }

  @override
  String get addSingleComment => 'Додати окремий коментар';

  @override
  String get addToReview => 'Додати до рев’ю';

  @override
  String get startAReview => 'Почати рев’ю';

  @override
  String get reviewNeedsABody =>
      'Спочатку напишіть підсумок або поставте в чергу вбудований коментар';

  @override
  String get reviewSubmitted => 'Рев’ю надіслано';

  @override
  String get finishYourReview => 'Завершити рев’ю';

  @override
  String get commentVerdict => 'Коментар';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count коментарів у черзі',
      many: '$count коментарів у черзі',
      few: '$count коментарі в черзі',
      one: '1 коментар у черзі',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 'і ще $count';
  }

  @override
  String get queuedCommentHint =>
      'Цей коментар буде надіслано, коли ви надішлете рев’ю.';

  @override
  String commentOnLinesRange(int start, int end) {
    return 'Рядки $start–$end';
  }

  @override
  String get claudeAccountsTitle => 'Облікові записи Claude Code';

  @override
  String get claudeAccountsDescription =>
      'Кожен обліковий запис — окремий вхід у Claude Code. Запуски використовують облікові записи, приєднані нижче, у цьому порядку.';

  @override
  String get claudeAccountsEmpty => 'Облікових записів ще немає';

  @override
  String get claudeAccountAdd => 'Додати обліковий запис';

  @override
  String get claudeAccountSignIn => 'Увійти';

  @override
  String get claudeAccountSignInAgain => 'Увійти знову';

  @override
  String get claudeAccountSignInHint =>
      'Виконайте це в терміналі на сервері. Відкриється браузер, щоб завершити вхід, а облікові дані запишуться в каталог цього облікового запису.';

  @override
  String get claudeAccountSignedOut => 'Вихід виконано';

  @override
  String get claudeAccountExpired => 'Сеанс входу закінчився';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'Сеанс входу закінчився $when. Увійдіть знову, щоб користуватися цим обліковим записом.';
  }

  @override
  String get claudeAccountMakeDefault => 'Зробити типовим';

  @override
  String get claudeAccountDefault => 'Типовий';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return 'Вилучити $label?';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'Обліковий запис буде виведено із системи, а його каталог на сервері — видалено. Сам вхід не зміниться.';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'Не вдалося перевірити цей обліковий запис: $error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return 'Використано $percent%';
  }

  @override
  String get accountPoolStrategy => 'Ротація';

  @override
  String get accountPoolPinned => 'Закріплений';

  @override
  String get accountPoolRoundRobin => 'По колу';

  @override
  String get accountPoolSerial => 'По одному';

  @override
  String get accountPoolPinnedHint =>
      'Завжди починати з першого облікового запису. Інші лишаються запасними, якщо він не спрацює.';

  @override
  String get accountPoolRoundRobinHint =>
      'Розподіляти запуски між обліковими записами, переходячи до наступного на кожному відправленні.';

  @override
  String get accountPoolSerialHint =>
      'Вичерпати перший обліковий запис, перш ніж переходити до наступного.';

  @override
  String get accountPoolMoveUp => 'Перемістити вгору';

  @override
  String get accountPoolMoveDown => 'Перемістити вниз';

  @override
  String get accountPoolUsingAll =>
      'Нічого ще не приєднано — використовуються всі облікові записи, у цьому порядку.';

  @override
  String get accountPoolInheriting =>
      'Успадковуються облікові записи робочого простору.';

  @override
  String get accountPoolResetToWorkspace =>
      'Скинути до облікових записів робочого простору';

  @override
  String accountPoolCoolingOff(String when) {
    return 'квота вичерпана до $when';
  }

  @override
  String get accountPoolSignedOut => 'вихід виконано';

  @override
  String get accountPoolExpired => 'сеанс входу закінчився';

  @override
  String accountPoolLoadFailed(String error) {
    return 'Не вдалося завантажити ротацію: $error';
  }

  @override
  String get providerSignedInAccount => 'обліковий запис із входом';

  @override
  String get agentAccountsTab => 'Облікові записи';

  @override
  String get agentClaudeAccountsNoticeTitle =>
      'Кілька облікових записів Claude Code';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return 'Цей раннер входить як один із $count облікових записів Claude Code на цьому хості. Оберіть потрібний або налаштуйте ротацію на вкладці «Облікові записи».';
  }

  @override
  String get agentAccountsDescription =>
      'Які облікові записи використовують запуски цього агента. Кожен блок спочатку успадковує вибір робочого простору.';

  @override
  String get agentAccountsNothingToRotate =>
      'Немає що ротувати — спочатку підключіть другий обліковий запис або ключ.';

  @override
  String failedToPostReply(String error) {
    return 'Не вдалося опублікувати відповідь: $error';
  }

  @override
  String commentOnLine(int line) {
    return 'Рядок $line';
  }

  @override
  String get viewInDiff => 'Переглянути в diff';

  @override
  String get subscriptionUsagePreviousAccount => 'Попередній обліковий запис';

  @override
  String get subscriptionUsageNextAccount => 'Наступний обліковий запис';

  @override
  String inReplyTo(String path) {
    return 'У відповідь на $path';
  }

  @override
  String get subscriptionUsageNoneReported =>
      'Для цього облікового запису немає даних про використання.';

  @override
  String get subscriptionUsageCredits => 'Кредити';

  @override
  String get reviewHubStaticRule => 'Статичне правило';

  @override
  String get reviewHubStarted => 'Рев\'ю розпочато';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'Знайдено детермінованим правилом ($rule) у рядку, який додає цей pull request, — не агентом-рев\'юером.';
  }

  @override
  String get prReviewArtifactTab => 'Рев\'ю PR';

  @override
  String get prReviewRunning => 'Триває рев\'ю цього pull request…';

  @override
  String get prReviewStarting => 'Запуск рев\'ю…';

  @override
  String get prReviewStartingBody =>
      'Готується робоче дерево цього pull request. Рев\'юери запустяться, щойно воно буде готове.';

  @override
  String get prReviewFailed => 'Рев\'ю не вдалося.';

  @override
  String get prReviewRerunning => 'Повторне рев\'ю…';

  @override
  String get prReviewNoOpenFindings => 'Немає відкритих зауважень';

  @override
  String prReviewOpenFindings(int count) {
    return '$count open findings';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used з $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return 'Posted $posted comment(s) as the bot. $skipped skipped (no file anchor), $failed failed.';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count finding(s) target code this pull request does not change ($files). GitHub only accepts inline comments on the diff.';
  }

  @override
  String get reviewRailReport => 'Звіт';

  @override
  String get reviewNoFindingsTitle => 'Ще немає знахідок';

  @override
  String get reviewNoFindingsHint =>
      'Знахідки з’являються тут, коли агенти їх публікують.';

  @override
  String reviewShowDismissed(int count) {
    return 'Показати $count відхилених';
  }

  @override
  String reviewHideDismissed(int count) {
    return 'Сховати $count відхилених';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Виявлено $count розбіжностей рецензентів',
      many: 'Виявлено $count розбіжностей рецензентів',
      few: 'Виявлено $count розбіжності рецензентів',
      one: 'Виявлено 1 розбіжність рецензента',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'Тип';

  @override
  String get reviewFilterStatus => 'Статус';

  @override
  String get reviewKindBug => 'Помилка';

  @override
  String get reviewKindSuggestion => 'Пропозиція';

  @override
  String get reviewKindRecommendation => 'Рекомендація';

  @override
  String get reviewKindQuestion => 'Запитання';

  @override
  String get reviewKindTicket => 'Тікет';

  @override
  String get archiveSpace => 'Архівувати простір';

  @override
  String get archivedSpaces => 'Архівовані простори';

  @override
  String get archivedSpacesEmpty => 'Немає архівованих просторів';

  @override
  String get restoreSpace => 'Відновити';

  @override
  String archivedWhen(String time) {
    return 'Архівовано $time';
  }

  @override
  String get deleteSpacePermanently => 'Видалити остаточно';

  @override
  String get renameSpace => 'Перейменувати простір';

  @override
  String get renameConversation => 'Перейменувати розмову';

  @override
  String get spaceActions => 'Дії з простором';

  @override
  String get conversationActions => 'Дії з розмовою';

  @override
  String get editSpaceRepos => 'Редагувати репозиторії';

  @override
  String get editSpaceReposTitle => 'Репозиторії простору';

  @override
  String get editSpaceReposWarning =>
      'Додавання репозиторію вивантажує його в цей простір; вилучення видаляє його теку.';

  @override
  String get agentSectionIdentity => 'Ідентичність';

  @override
  String get agentSectionRuntime => 'Середовище виконання';

  @override
  String get agentSectionGuardrails => 'Обмеження';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count підлеглих',
      many: '$count підлеглих',
      few: '$count підлеглі',
      one: '1 підлеглий',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'Фільтрувати команди…';

  @override
  String get teamsSummaryWithLeader => 'З лідером';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count команд',
      many: '$count команд',
      few: '$count команди',
      one: '1 команда',
      zero: 'Немає команд',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return 'Видалення $name прибере його профіль, зв’язки з навичками та історію запусків. Цю дію не можна скасувати.';
  }

  @override
  String get resetToDefault => 'Скинути до типових';

  @override
  String get newAgent => 'Новий агент';

  @override
  String get newSkill => 'Нова навичка';

  @override
  String get zoomIn => 'Збільшити';

  @override
  String get zoomOut => 'Зменшити';

  @override
  String get resetZoom => 'Скинути масштаб';

  @override
  String get imageHostedOnGitHub => 'Зображення на GitHub';

  @override
  String get imageOpenExternally => 'Зображення · відкрити зовні';

  @override
  String get memoryScopeAll => 'Усі області';

  @override
  String get memoryScopeWorkspace => 'На весь робочий простір';

  @override
  String get memoryScopeFilterLabel => 'Фільтр за областю';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return 'Обмежено репозиторієм $repo';
  }

  @override
  String get toolScreenshot => 'Знімок екрана від агента';

  @override
  String get toolImageUnavailable => 'Зображення недоступне';

  @override
  String toolImagesUnavailable(int count) {
    return '$count зображень недоступно';
  }

  @override
  String get shakeUnavailable => 'Струшування недоступне на цьому сервері';

  @override
  String get shakeNothing => 'Немає що витрусити — недавні ходи захищено';

  @override
  String shakeDone(int tokens) {
    return 'Звільнено близько $tokens токенів';
  }

  @override
  String get compactionDivider => 'Стиснуто';

  @override
  String compactionDividerCount(int count) {
    return 'Стиснуто · згорнуто $count повідомлень';
  }

  @override
  String get composerDropToAttach => 'Відпустіть, щоб прикріпити';

  @override
  String get attachmentUnavailable => 'Вкладення недоступне';

  @override
  String get attachmentUnavailableDetail =>
      'Це вкладення більше не зберігається в пам’яті. Прикріпіть його знову, щоб переглянути.';

  @override
  String get attachmentPreviewFailed => 'Не вдалося відкрити цей файл';

  @override
  String get attachmentPreviewUnsupported =>
      'Немає попереднього перегляду для цього типу файлу';

  @override
  String get attachmentTooLargeToPreview =>
      'Завеликий для попереднього перегляду';

  @override
  String get attachmentOpenExternally => 'Відкрити в типовій програмі';

  @override
  String get asideUnavailable =>
      'Задайте одноразову модель у параметрах робочого простору, щоб скористатися цим';

  @override
  String get asideEmpty => 'Ще немає з чого почати';

  @override
  String get asideFailed => 'Не вдалося отримати відповідь';

  @override
  String get handoffTitle => 'Передача';

  @override
  String get asideTitle => 'Побічне питання';

  @override
  String get attachFilesOrDrop => 'Прикріпіть файли — або перетягніть сюди';

  @override
  String get guidedGoalTitle => 'Уточніть ціль';

  @override
  String get guidedGoalIntro =>
      'Агенту без нагляду потрібно точно знати, коли роботу завершено. Спершу кілька запитань.';

  @override
  String get guidedGoalAnswerHint => 'Ваша відповідь';

  @override
  String get guidedGoalNext => 'Далі';

  @override
  String get guidedGoalStart => 'Запустити ціль';

  @override
  String get guidedGoalSkip => 'Пропустити і запустити як є';

  @override
  String guidedGoalStillMissing(String items) {
    return 'Ще не вказано: $items';
  }

  @override
  String get conversationTreeTitle => 'Дерево розмови';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count гілки',
      many: '$count гілок',
      few: '$count гілки',
      one: '$count гілка',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'Продовжити звідси';

  @override
  String get conversationTreeFork => 'Відгалузити в нову розмову';

  @override
  String get conversationTreeCurrent => 'На цій гілці';

  @override
  String get conversationTreeEmpty => 'Поки нічого немає';

  @override
  String get conversationTreeForked => 'Відгалужено в нову розмову';

  @override
  String get conversationTreeSwitched => 'Продовжуємо з того повідомлення';

  @override
  String exportSaved(String path) {
    return 'Збережено в $path';
  }

  @override
  String get exportFailed => 'Не вдалося записати експорт';

  @override
  String get contextCommandNoAgent =>
      'У цій розмові немає агента, тож вікно контексту відкрити не можна';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'У цій розмові немає агента «$name». Спробуйте: $names';
  }

  @override
  String get dumpCopied => 'Транскрипт скопійовано в буфер обміну';

  @override
  String get messageQueueHint =>
      'Продовжуйте вводити, щоб поставити подальші зміни в чергу';

  @override
  String get steerNow => 'Скоригувати';

  @override
  String get steeringQueueLabel => 'Черга коригувальних повідомлень';

  @override
  String get steeringDeliverUnavailable =>
      'Зараз жоден запущений агент не може це прийняти — залишиться в черзі.';

  @override
  String get reorderSteeringCard => 'Змінити порядок повідомлення в черзі';

  @override
  String get editSteeringCard => 'Редагувати повідомлення в черзі';

  @override
  String get deleteSteeringCard => 'Видалити повідомлення в черзі';

  @override
  String get steeringBadge => 'Скориговано';

  @override
  String get settingsSandboxLabel => 'Пісочниця';

  @override
  String get sandboxExecGrantsTitle => 'Дозволи на виконання';

  @override
  String get sandboxExecGrantsSubtitle =>
      'Програми, які агенти можуть запускати зі своєї робочої копії ваших репозиторіїв. Кожен запис ви схвалили, коли пісочниця запитала.';

  @override
  String get sandboxExecGrantsEmpty =>
      'Рішень ще немає. Вас запитають, коли агент уперше потребуватиме запустити програму зі своєї робочої копії.';

  @override
  String get sandboxExecGrantRevoke => 'Скасувати';

  @override
  String get sandboxExecGrantAllowed => 'Дозволено';

  @override
  String get sandboxExecGrantBlocked => 'Заблоковано';

  @override
  String get sandboxExecGrantRevokeConfirmTitle => 'Скасувати це рішення?';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'Вас запитають знову, коли агент наступного разу потребуватиме запустити програму з цієї копії.';

  @override
  String get repoScriptsTest => 'Тест';

  @override
  String get repoScriptsTestTooltip =>
      'Запустити цю чернетку в одноразовому клоні репозиторію';

  @override
  String get repoScriptsRunKindTest => 'Тест';

  @override
  String get demoBadgeLabel => 'Демо';

  @override
  String get demoFilePickerTitle => 'Файли демо';

  @override
  String get demoFilePickerBody =>
      'Демо імітує завантаження: виберіть будь-який файл — він прикріпиться до повідомлення, не торкаючись диска.';

  @override
  String get demoFilePickerAttach => 'Прикріпити';

  @override
  String get demoReadOnlySave => 'Лише читання в демо';

  @override
  String get demoBadgeTooltip =>
      'Ви в демо. Дані вигадані, а агенти працюють за сценарієм.';

  @override
  String get demoFirstRunTitle => 'Ви в живому демо';

  @override
  String demoFirstRunBody(int minutes) {
    return 'Це справжня програма на справжньому коді — вигадані лише дані. Агенти показують справжні запуски зі сценарію, тож нічого не йде в модель і нічого не виконується на машині. Робочий простір лише ваш і зникне через $minutes хвилин.';
  }

  @override
  String get demoFirstRunDismiss => 'Зрозуміло';

  @override
  String get demoTourTitle => 'З чого почати';

  @override
  String get demoTourSubtitle =>
      'Чотири місця, що показують, що робить програма.';

  @override
  String get demoTourSkip => 'Пропустити';

  @override
  String get demoTourStarRepo => 'Поставити зірку на GitHub';

  @override
  String get demoTourOpen => 'Відкрити';

  @override
  String get demoTourSpacesTitle => 'Поговоріть з агентом';

  @override
  String get demoTourSpacesBody =>
      'Надішліть повідомлення в просторі й дивіться стрім запуску — міркування, виклики інструментів і вартість, як у справжньому запуску.';

  @override
  String get demoTourReviewTitle => 'Переглянути pull request';

  @override
  String get demoTourReviewBody =>
      'Відкрийте #412. Залиште коментар у коді або надішліть рев’ю — текст потрапить у тред і залишиться там.';

  @override
  String get demoTourTicketsTitle => 'Стежити за роботою';

  @override
  String get demoTourTicketsBody =>
      'Тікети, todo й плани прив’язані до тих самих розмов, які ведуть агенти.';

  @override
  String get demoTourInboxTitle => 'Бачити всю операцію';

  @override
  String get demoTourInboxBody =>
      'Усі сповіщення з кожного стовпа збираються в одну скриньку — рев’ю, тікети, запуски й зустрічі.';

  @override
  String get demoUnavailableTitle => 'У демо недоступно';

  @override
  String get demoUnavailableTerminal =>
      'Термінал запускає справжню оболонку на хості сервера. У демо немає жодної поверхні виконання — саме тому його безпечно відкривати публічно.';

  @override
  String get demoUnavailableRig =>
      'Enclosure — одноразова віртуальна машина, якою керує агент. Демо не запускає жодної: публічна кінцева точка, яка може стартувати VM, — це вже не демо.';

  @override
  String get demoUnavailableEditor =>
      'Редактор у браузері запускає процес code-server на реальній робочій копії. У демо немає ні того, ні того.';

  @override
  String get demoUnavailableFeeds =>
      'Демо читає справжні стрічки, але список підписок фіксований. Додавати чи вилучати тут не можна.';

  @override
  String get demoUnavailableForge =>
      'Демо не зберігає облікових даних і ніколи не звертається до GitHub, GitLab чи Linear. Його pull request — фікстури, а ваші коментарі до них зберігаються локально.';

  @override
  String get demoUnavailableModels =>
      'Демо не викликає жодної моделі. Запуски агентів — скриптове відтворення, тому вони нічого не коштують і не звертаються до провайдера.';

  @override
  String get demoUnavailableMcp =>
      'Поверхня інструментів MCP у демо не змонтована, тож зовнішній клієнт не може до неї під’єднатися.';

  @override
  String get demoUnavailableRepos =>
      'Демо не витягує код і не запускає git. Репозиторій, який ви бачите, — фікстура за pull request.';

  @override
  String get demoUnavailableSkills =>
      'Встановлення скіла завантажує й сканує код. Демо нічого не завантажує.';

  @override
  String get demoUnavailableSso =>
      'Єдиний вхід — це конфігурація сервера. Демо натомість входить як тимчасовий гість.';

  @override
  String get demoUnavailableAudio =>
      'Запис і диктування потребують захоплення звуку та моделі мовлення на хості. Демо не має ні того, ні того, тож зустрічі — це транскрипти без відтворення.';

  @override
  String get demoUnavailableServerAdmin =>
      'Це адміністрування сервера. Демо дає кожному відвідувачу власний одноразовий робочий простір і нічого більше.';

  @override
  String get demoUnavailablePipelines =>
      'Конвеєри тут не запускаються. Відвідувач, який може написати крок bash і запустити його — вручну або через тригер події — виконує код на цьому хості.';

  @override
  String get settingsBackupRestore => 'Резервні копії та відновлення';

  @override
  String get settingsBackupRestoreDescription =>
      'Знімки всіх баз даних на цьому сервері, а також експорт, імпорт і видалення для одного робочого простору.';

  @override
  String get backupSnapshotsLabel => 'Знімки інсталяції';

  @override
  String get backupSnapshotsExplainer =>
      'Знімок копіює кожну базу даних у папку з часовою міткою на хості сервера. Відновлення всієї інсталяції — це копіювання тієї папки назад, коли сервер зупинено; один робочий простір можна відновити звідси.';

  @override
  String get backupNowAction => 'Зробити знімок зараз';

  @override
  String backupSnapshotWritten(String path) {
    return 'Знімок записано в $path';
  }

  @override
  String get backupNoSnapshots =>
      'Знімків ще немає. Знімок створюється лише на ваш запит — нічого не заплановано.';

  @override
  String get backupSnapshotComplete => 'Повний';

  @override
  String get backupSnapshotIncomplete => 'Неповний';

  @override
  String get backupSnapshotIncompleteNote =>
      'Маніфест відсутній або вказує на файли, яких немає, тож цей знімок не може відновити всю інсталяцію. Файли робочих просторів, які в ньому є, можна все одно прийняти по одному.';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count робочого простору',
      many: '$count робочих просторів',
      few: '$count робочі простори',
      one: '1 робочий простір',
      zero: 'Немає робочих просторів',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count робочого простору не потрапило до знімка',
      many: '$count робочих просторів не потрапило до знімка',
      few: '$count робочі простори не потрапили до знімка',
      one: '1 робочий простір не потрапив до знімка',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'Шлях на сервері';

  @override
  String get backupRestoreAction => 'Відновити';

  @override
  String get backupRestoreTitle => 'Відновити робочий простір';

  @override
  String backupRestoreBody(String name) {
    return 'Це замінить усе в $name копією з цього знімка. Усе, що робочий простір зробив після знімка, буде втрачено, і це не можна скасувати.';
  }

  @override
  String backupRestoreDone(String name) {
    return 'Відновлено $name зі знімка.';
  }

  @override
  String get backupWorkspaceUnknown => 'Більше немає на цьому сервері';

  @override
  String get backupWorkspaceDataLabel => 'Дані робочого простору';

  @override
  String get backupWorkspaceDataExplainer =>
      'Один робочий простір — один файл бази даних, тож експорт копіює цей файл, а не вивантажує таблиці по одній. Імпорт замінює все в цільовому робочому просторі вказаним файлом.';

  @override
  String get backupExportAction => 'Експортувати';

  @override
  String backupExportDone(String path) {
    return 'Експортовано в $path';
  }

  @override
  String get backupExportedFileLabel => 'Експортований файл на сервері';

  @override
  String get backupImportAction => 'Імпортувати';

  @override
  String backupImportTitle(String name) {
    return 'Імпортувати в $name';
  }

  @override
  String backupImportBody(String name) {
    return 'Це замінить усе в $name вмістом файлу. Усе, що зараз є в цьому робочому просторі, буде втрачено, і це не можна скасувати.';
  }

  @override
  String get backupImportSourceLabel => 'Файл бази даних робочого простору';

  @override
  String get backupImportSourceDescription =>
      'Файл .db, який сервер може прочитати. Шляхи вказують на хост сервера, а не на цей пристрій.';

  @override
  String backupImportDone(String name) {
    return 'Імпортовано в $name.';
  }

  @override
  String backupDeleteBody(String name) {
    return '$name зникне з усіх списків і пошуку. Файл бази даних залишиться на диску, резервні копії й далі його включатимуть, і місце саме не звільниться.';
  }

  @override
  String get backupExportDescription =>
      'Записати копію на сервер або завантажити на цей пристрій.';

  @override
  String get backupExportOnServerAction => 'Зберегти на сервері';

  @override
  String get backupDownloadAction => 'Завантажити';

  @override
  String backupDownloadSaved(String path) {
    return 'Збережено в $path';
  }

  @override
  String get backupDownloadInBrowser => 'Браузер завантажує файл.';

  @override
  String get backupRestoreFromDeviceLabel => 'Відновити з цього пристрою';

  @override
  String get backupRestoreFromDeviceDescription =>
      'Виберіть тут файл бази даних робочого простору, і Control Center завантажить його на сервер. Це варіант, коли сервер — не ця машина.';

  @override
  String get backupUploadAction => 'Вибрати файл і вивантажити';

  @override
  String get backupTransferUnavailable =>
      'Це з’єднання досягає сервера через ретранслятор, який не передає файли. Підключіться до сервера напряму, щоб завантажити або вивантажити резервну копію.';

  @override
  String get backupTransferForbidden =>
      'Сервер відмовив. Щоб завантажити робочий простір, потрібна роль admin, щоб відновити — owner, а для всього знімка — operator інсталяції.';

  @override
  String get backupTransferUnsupported =>
      'На цьому сервері немає поверхні резервного копіювання.';

  @override
  String get backupTransferTooLarge => 'Файл більший, ніж приймає сервер.';

  @override
  String get credentialGateWaitingTitle => 'Очікування облікових даних';

  @override
  String credentialGateHarnessTitle(String provider) {
    return '$provider не має облікових даних';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Code вийшов із системи';

  @override
  String get credentialGateExpiredTitle => 'Термін входу в Claude Code минув';

  @override
  String get credentialGatePlanSpentTitle =>
      'Ліміт плану Claude Code вичерпано';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent очікує продовження.';
  }

  @override
  String get credentialGateWaitingRun => 'Запуск очікує продовження.';

  @override
  String get credentialGateWatching =>
      'Стежимо за виправленням — запуск продовжується сам.';

  @override
  String credentialGateFreesUpAt(String time) {
    return 'Звільниться о $time';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'Запуск здається о $time';
  }

  @override
  String get credentialGateCheckAgain => 'Перевірити знову';

  @override
  String get credentialGateCancelRun => 'Скасувати запуск';

  @override
  String get credentialGateAccountsTried => 'Спробовані облікові записи';

  @override
  String get credentialGateClaudeSignInHint =>
      'Увійдіть у Налаштування → Адаптери → Claude Code або виконайте команду login у терміналі. Запуск підхопить це сам.';

  @override
  String get credentialGateOpenSettings => 'Відкрити налаштування';

  @override
  String get selectModel => 'Вибрати модель';

  @override
  String get allModels => 'Усі моделі';

  @override
  String get noModelsMatchSearch => 'Жодна модель не відповідає пошуку';

  @override
  String useCustomModelId(String id) {
    return 'Використати «$id»';
  }

  @override
  String get modelFree => 'Безплатно';

  @override
  String modelOutputTokens(String tokens) {
    return '$tokens виводу';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return '$input введення / $output виведення за 1 млн токенів';
  }

  @override
  String modelEffortLevels(String levels) {
    return 'Зусилля міркування: $levels';
  }

  @override
  String get modelSupportsReasoning => 'Підтримує зусилля міркування';

  @override
  String get profileDeliveryMetrics => 'Показники доставки';

  @override
  String profileMetricsSample(int count) {
    return 'Проаналізовано PR: $count';
  }

  @override
  String get profileMergeRate => 'Частка злиттів';

  @override
  String get profileReviewCoverage => 'Охоплення перевірками';

  @override
  String get profilePrSize => 'Розмір PR';

  @override
  String get profileTimeToMerge => 'Час до злиття';

  @override
  String get profileMergeTimeTrend => 'Динаміка часу злиття';

  @override
  String get profileWeeklyMedian => 'Тижнева медіана, логарифмічна шкала';

  @override
  String get profilePrOpeningPattern => 'День тижня × година, місцевий час';

  @override
  String get profileFirstReview => 'Час до першої перевірки';

  @override
  String get profileMetricsTruncated =>
      'Процентилі розраховуються на основі обмеженої вибірки доступних запитів на злиття.';

  @override
  String profileLinesChanged(String count) {
    return 'Рядків: $count';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count хв';
  }

  @override
  String profileDurationHours(int count) {
    return '$count год';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '$days д $hours год';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return 'Учасників: $count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return 'У цьому робочому просторі немає запитів на злиття від $team';
  }

  @override
  String get profilePrStateFilterLabel =>
      'Фільтрувати запити на злиття за станом';

  @override
  String get noProfilePrsMatchSearchHint =>
      'Спробуйте іншу назву або номер запиту на злиття';

  @override
  String get rigNetworkUnrestricted => 'Мережа без обмежень';

  @override
  String get rigNetworkAllowAllHosts => 'Дозволити всі вузли';

  @override
  String get rigBrowserPermissionsTitle => 'Дозволи сайту';

  @override
  String get rigBrowserPermissionsTooltip => 'Дозволи сайту та мережа';

  @override
  String get rigBrowserPermissionEmpty => 'Жоден сайт ще не запитував дозвіл';

  @override
  String rigBrowserPermissionPrompt(String origin, String permission) {
    return '$origin хоче використати $permission';
  }

  @override
  String get rigBrowserPermissionBlock => 'Заблокувати';

  @override
  String get rigBrowserPermissionCamera => 'Камера';

  @override
  String get rigBrowserPermissionMicrophone => 'Мікрофон';

  @override
  String get rigBrowserPermissionNotifications => 'Сповіщення';

  @override
  String get rigBrowserPermissionGeolocation => 'Розташування';

  @override
  String get rigBrowserPermissionPersistentStorage => 'Постійне сховище';

  @override
  String get rigBrowserPermissionClipboard => 'Буфер обміну';

  @override
  String get rigBrowserPermissionDisplayCapture => 'Захоплення екрана';

  @override
  String get rigBrowserPermissionMidi => 'MIDI';

  @override
  String get rigNetworkBypassTitle => 'Дозволити всі мережеві вузли?';

  @override
  String get rigNetworkBypassBody =>
      'Ізольоване середовище буде перезапущено, а незакомічену роботу всередині нього буде видалено. Після цього гостьова система зможе звертатися до будь-яких мережевих вузлів, доки її не закриють.';

  @override
  String get rigNetworkRestartUnrestricted => 'Перезапустити без обмежень';

  @override
  String get rigNetworkUnrestrictedBody =>
      'Це ізольоване середовище може звертатися до будь-яких мережевих вузлів. Закрийте його й відкрийте нове, щоб відновити стандартні обмеження.';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      'Цей емулятор Android уже сам керує своєю мережею, тому Control Center не може застосувати список дозволених вузлів. Перезапуск не потрібен.';

  @override
  String get rigClipboardPermissionHostToRigTitle =>
      'Вставити буфер обміну в це середовище?';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'Control Center прочитає буфер обміну вашого пристрою та надішле його вміст у середовище. Вміст буфера обміну може містити паролі або інші секретні дані.';

  @override
  String get rigClipboardPermissionRigToHostTitle =>
      'Скопіювати буфер обміну з цього середовища?';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'Control Center прочитає буфер обміну середовища та замінить буфер обміну вашого пристрою його вмістом. Ставтеся до вмісту із середовища як до ненадійного.';

  @override
  String get rigClipboardAllowTenMinutes => 'Дозволити на 10 хвилин';

  @override
  String get rigClipboardAlwaysAllow => 'Завжди дозволяти';

  @override
  String get rigClipboardSettingsTitle => 'Доступ до буфера обміну';

  @override
  String get rigClipboardSettingsHint =>
      'Виберіть, які передавання буфера обміну можуть виконуватися без запиту. Тимчасові дозволи спливають через 10 хвилин.';

  @override
  String get rigClipboardAlwaysPasteTitle =>
      'Завжди дозволяти вставлення в середовища';

  @override
  String get rigClipboardAlwaysPasteDescription =>
      'Надсилати буфер обміну цього пристрою в будь-яке середовище без запиту.';

  @override
  String get rigClipboardAlwaysCopyTitle =>
      'Завжди дозволяти копіювання із середовищ';

  @override
  String get rigClipboardAlwaysCopyDescription =>
      'Розміщувати вміст буфера обміну з будь-якого середовища на цьому пристрої без запиту.';

  @override
  String get workspaceGitHubIdentity => 'Ідентичність GitHub';

  @override
  String get workspaceGitHubIdentityDescription =>
      'Як фонова робота з GitHub автентифікується в цьому просторі. Успадкувати App інсталяції, інший App або лише персональний токен доступу.';

  @override
  String get workspaceGitHubModeInherit =>
      'Використовувати GitHub App цієї інсталяції';

  @override
  String get workspaceGitHubModeApp => 'Використовувати інший GitHub App';

  @override
  String get workspaceGitHubModePat => 'Лише персональний токен доступу';

  @override
  String get workspaceGitHubInheritHint =>
      'Використовує GitHub App у Сервер → Застосунки постачальників.';

  @override
  String get workspaceGitHubAppHint =>
      'Ідентичність бота й опитування цього простору. Учасники входять у Ви через цей App.';

  @override
  String get workspaceGitHubPatLabel => 'Фоновий токен';

  @override
  String get workspaceGitHubPatDescription =>
      'Для опитування й агентів у цьому просторі. Це не токен профілю учасника.';

  @override
  String get workspaceGitHubHasPat => 'Фоновий токен збережено.';

  @override
  String get workspaceGitHubNoPat => 'Фоновий токен не збережено.';

  @override
  String get profileOverlayHint =>
      'Ці поля — ви в цьому просторі. Порожні поля успадковують ім\'я й пошту облікового запису. Зміна простору змінює цей шар.';

  @override
  String get forgeConnectionsThisWorkspace =>
      'Увійдіть або вставте токен для цього простору.';
}
