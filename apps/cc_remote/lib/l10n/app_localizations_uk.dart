// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Назад';

  @override
  String get cancel => 'Скасувати';

  @override
  String get retry => 'Повторити';

  @override
  String get tryAgain => 'Спробувати знову';

  @override
  String get settings => 'Налаштування';

  @override
  String get refresh => 'Оновити';

  @override
  String get approve => 'Схвалити';

  @override
  String get deny => 'Відхилити';

  @override
  String get continueLabel => 'Продовжити';

  @override
  String get agentQuestionHeader => 'Питання до вас';

  @override
  String get agentQuestionAnsweredLabel => 'Відповідь надано';

  @override
  String get agentQuestionSkip => 'Пропустити';

  @override
  String get agentQuestionSkippedLabel => 'Пропущено';

  @override
  String get agentQuestionFreeformHint => 'Введіть відповідь…';

  @override
  String get agentApprovalRequired => 'Потрібне підтвердження';

  @override
  String get copyCommand => 'Копіювати команду';

  @override
  String get approveAndRemember => 'Дозволити на 8 годин';

  @override
  String get decline => 'Відхилити';

  @override
  String get confirm => 'Підтвердити';

  @override
  String get send => 'Надіслати';

  @override
  String get close => 'Закрити';

  @override
  String get expand => 'Розгорнути';

  @override
  String get zoomIn => 'Збільшити';

  @override
  String get zoomOut => 'Зменшити';

  @override
  String get resetZoom => 'Скинути масштаб';

  @override
  String get scanQrPrompt =>
      'Відскануйте QR-код у Control Center, щоб під’єднати цей телефон.';

  @override
  String get scanQrHelp =>
      'Відкрийте камеру й наведіть її на QR у Control Center. Телефон з’єднується напряму через приватне посилання.';

  @override
  String get connectingToMac => 'Підключення до Control Center…';

  @override
  String get connectingDetail => 'Налагоджуємо захищене пряме з’єднання.';

  @override
  String get identityChangedTitle => 'Ідентичність сервера змінилась';

  @override
  String get identityChangedBody =>
      'Цей сервер більше не відповідає ідентичності, збереженій під час підключення. Можливо, сервер перевстановили — або хтось перехоплює з’єднання. З міркувань безпеки цей пристрій не підключиться. Видаліть підключення, потім відскануйте новий QR-код у Control Center, щоб під’єднатися знову.';

  @override
  String get removePairing => 'Видалити підключення';

  @override
  String get couldntConnect => 'Не вдалося підключитися';

  @override
  String get pendingPairingTitle => 'Підключитися до цього сервера?';

  @override
  String get pendingPairingBody =>
      'Посилання запропонувало Control Center підключитися до цього сервера. Продовжуйте лише якщо ви самі це ініціювали.';

  @override
  String get connect => 'Під’єднатися';

  @override
  String get failureNotPaired =>
      'Не підключено — відскануйте QR-код у Control Center';

  @override
  String get failureUnreachable =>
      'Не вдалося достукатися до сервера жодним шляхом — перевірте, що він запущений, або спробуйте ту саму мережу';

  @override
  String get failureIdentityChanged =>
      'Ідентичність сервера змінилась — якщо його перевстановили, підключіть цей пристрій знову';

  @override
  String get failureAuthRejected =>
      'Сервер відхилив цей пристрій — підключіть його знову з Control Center';

  @override
  String get failureUnknown =>
      'Не вдалося підключитися — натисніть, щоб повторити';

  @override
  String get statusConnected => 'Підключено';

  @override
  String get statusConnecting => 'Підключення';

  @override
  String get statusOffline => 'Офлайн';

  @override
  String get statusIdentityMismatch => 'Невідповідність ідентичності';

  @override
  String get statusNotPaired => 'Не підключено';

  @override
  String get statusConfirmPairing => 'Підтвердити підключення';

  @override
  String get connectionFailed => 'З’єднання не вдалося';

  @override
  String get identityMismatchBanner =>
      'Ідентичність сервера змінилась — з’єднання зупинено. Підключіть цей пристрій знову, щоб продовжити.';

  @override
  String get tabInbox => 'Вхідні';

  @override
  String get tabTickets => 'Тікети';

  @override
  String get tabChat => 'Чат';

  @override
  String get tabPrs => 'PR';

  @override
  String get tabCalendar => 'Календар';

  @override
  String get tabNews => 'Новини';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, очікує: $count';
  }

  @override
  String get updateAvailable => 'Доступна нова версія Control Center';

  @override
  String get appearance => 'Вигляд';

  @override
  String get language => 'Мова';

  @override
  String get device => 'Пристрій';

  @override
  String get themeSystem => 'Системна';

  @override
  String get themeLight => 'Світла';

  @override
  String get themeDark => 'Темна';

  @override
  String get languageSystem => 'Системна';

  @override
  String get disconnectTapAgain =>
      'Натисніть ще раз, щоб від’єднати цей пристрій від Control Center';

  @override
  String get disconnectDevice => 'Від’єднати цей пристрій';

  @override
  String get disconnect => 'Від’єднатися';

  @override
  String get chooseWorkspace => 'Обрати робочий простір';

  @override
  String get workspaces => 'Робочі простори';

  @override
  String get workspacesLoadFailed => 'Не вдалося завантажити робочі простори';

  @override
  String get noWorkspacesYet => 'Поки немає робочих просторів';

  @override
  String selectWorkspace(String name) {
    return 'Вибрати $name';
  }

  @override
  String get inboxLoadFailed => 'Не вдалося завантажити вхідні';

  @override
  String get allCaughtUp => 'Усе переглянуто';

  @override
  String get inboxNoForgeAccount =>
      'На сервері немає підключеного облікового запису forge, тож pull request ще не можна прив’язати до вас.';

  @override
  String get inboxNothingWaiting =>
      'Нічого не заблоковано, і жоден pull request на вас не чекає.';

  @override
  String get blocked => 'Заблоковано';

  @override
  String get sectionNeedsYourReview => 'Потрібен ваш перегляд';

  @override
  String get sectionReturnedToYou => 'Повернуто вам';

  @override
  String get sectionApprovedAndReady => 'Схвалено й готово';

  @override
  String get sectionYourDrafts => 'Ваші чернетки';

  @override
  String get sectionWaitingForReviewers => 'Очікують рецензентів';

  @override
  String get sectionMergingAndMerged => 'Зливаються й нещодавно злиті';

  @override
  String get sectionWaitingForAuthor => 'Очікують автора';

  @override
  String waitingAgo(String ago) {
    return 'чекає $ago';
  }

  @override
  String get openConversation => 'Відкрити розмову';

  @override
  String get calendarLoadFailed => 'Не вдалося завантажити календар';

  @override
  String get nothingScheduled => 'Нічого не заплановано';

  @override
  String get calendarEmptyDescription =>
      'Тут з’являться події з підключених календарів.';

  @override
  String get agenda => 'Розклад';

  @override
  String get syncCalendarsNow => 'Синхронізувати календарі зараз';

  @override
  String get event => 'Подія';

  @override
  String get eventNotFound => 'Подію не знайдено';

  @override
  String get eventNotFoundDescription =>
      'Можливо, вона поза вікном розкладу або її видалили вище за потоком.';

  @override
  String get joinMeeting => 'Приєднатися до зустрічі';

  @override
  String get join => 'Приєднатися';

  @override
  String attendeesCount(int count) {
    return 'Учасники ($count)';
  }

  @override
  String get details => 'Деталі';

  @override
  String get allDay => 'Весь день';

  @override
  String get happeningNow => 'Триває зараз';

  @override
  String inDuration(String duration) {
    return 'За $duration';
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
  String get attendeeAccepted => 'прийнято';

  @override
  String get attendeeDeclined => 'відхилено';

  @override
  String get attendeeMaybe => 'можливо';

  @override
  String get attendeeNoReply => 'без відповіді';

  @override
  String get organizer => 'організатор';

  @override
  String get calendarNoAccounts =>
      'Для цього робочого простору не підключено календар. Підключіть його в десктопній програмі — вхід зберігає токен на сервері.';

  @override
  String get calendarReauthNeeded =>
      'Потрібно знову підключити обліковий запис календаря — дані нижче можуть бути застарілими. Зробіть це в десктопній програмі.';

  @override
  String get spacesLoadFailed => 'Не вдалося завантажити простори';

  @override
  String get noSpaces => 'Немає просторів';

  @override
  String get spacesEmptyDescription =>
      'Тут з’являться простори цього робочого простору.';

  @override
  String get newSpaceFolder => 'Нова папка';

  @override
  String get folderName => 'Назва папки';

  @override
  String get renameSpaceFolder => 'Перейменувати папку';

  @override
  String get deleteSpaceFolder => 'Видалити папку';

  @override
  String get moveSpaceToFolder => 'Перемістити до папки';

  @override
  String get removeSpaceFromFolder => 'Прибрати з папки';

  @override
  String get spaceFolderActions => 'Дії з папкою';

  @override
  String get deleteFolderWithSpacesWarning =>
      'Остаточне видалення просторів вилучає їхні повідомлення та робочі дерева для всіх. Цю дію неможливо скасувати.';

  @override
  String get deleteSpacesInFolder => 'Остаточно видалити простори в цій папці';

  @override
  String get deleteFolderAndSpaces => 'Видалити папку й простори';

  @override
  String get keepSpacesInFolder => 'Інакше простори залишаться поза папками.';

  @override
  String get create => 'Створити';

  @override
  String get otherSpaces => 'Інші простори';

  @override
  String get folderUpdateFailed => 'Не вдалося оновити папки';

  @override
  String get thread => 'Тред';

  @override
  String get agentWorking => 'Агент працює';

  @override
  String get messagesLoadFailed => 'Не вдалося завантажити повідомлення';

  @override
  String get noMessagesYet => 'Повідомлень ще немає';

  @override
  String get noMessagesDescription =>
      'Надішліть повідомлення, щоб почати розмову.';

  @override
  String get agentResponding => 'Агент відповідає';

  @override
  String get agentFinished => 'Агент завершив';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names завеликі, щоб надіслати звідси.',
      one: '$names завеликий, щоб надіслати звідси.',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names завеликі, щоб надіслати через relay звідси.',
      one: '$names завеликий, щоб надіслати через relay звідси.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'Не вдалося завантажити вкладення. Спробуйте знову.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count вкладень не вдалося завантажити, їх пропущено.',
      one: '1 вкладення не вдалося завантажити, його пропущено.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Колега';

  @override
  String get agent => 'Агент';

  @override
  String get attachFile => 'Прикріпити файл';

  @override
  String get messageHint => 'Повідомлення';

  @override
  String removeAttachment(String name) {
    return 'Видалити $name';
  }

  @override
  String get articlesLoadFailed => 'Не вдалося завантажити статті';

  @override
  String get noArticles => 'Немає статей';

  @override
  String get articlesEmptyDescription =>
      'Нові статті з’являються тут, коли оновлюються стрічки.';

  @override
  String get unread => 'Непрочитані';

  @override
  String get allFeeds => 'Усі стрічки';

  @override
  String get save => 'Зберегти';

  @override
  String get unsave => 'Прибрати зі збережених';

  @override
  String get readFullArticle => 'Читати повністю';

  @override
  String get ticketsLoadFailed => 'Не вдалося завантажити тікети';

  @override
  String get noTickets => 'Немає тікетів';

  @override
  String get ticketsEmptyDescription =>
      'Тікети цього робочого простору з’являються тут.';

  @override
  String get all => 'Усі';

  @override
  String get ticket => 'Тікет';

  @override
  String get ticketLoadFailed => 'Не вдалося завантажити тікет';

  @override
  String assignedTo(String name) {
    return 'Призначено: $name';
  }

  @override
  String get openInBrowser => 'Відкрити в браузері';

  @override
  String get status => 'Статус';

  @override
  String get assign => 'Призначити';

  @override
  String get reassign => 'Перепризначити';

  @override
  String get noAgents => 'Немає агентів';

  @override
  String get noAgentsDescription =>
      'Призначте агента з цього робочого простору.';

  @override
  String get statusOpen => 'Відкрито';

  @override
  String get statusInProgress => 'У роботі';

  @override
  String get statusBlocked => 'Заблоковано';

  @override
  String get statusInReview => 'На перевірці';

  @override
  String get statusDone => 'Готово';

  @override
  String get statusBacklog => 'Беклог';

  @override
  String get lensNeedsMe => 'Чекають на мене';

  @override
  String get lensMine => 'Мої';

  @override
  String get prsLoadFailed => 'Не вдалося завантажити pull request';

  @override
  String get noOpenPullRequests => 'Немає відкритих pull request';

  @override
  String get nothingWaitingOnReview => 'Немає запитів на вашу перевірку';

  @override
  String get noOwnOpenPullRequests => 'У вас немає відкритих pull request';

  @override
  String get nothingBlocked => 'Нічого не заблоковано';

  @override
  String get prsEmptyDescription =>
      'Pull request із репозиторіїв цього робочого простору з’являються тут.';

  @override
  String get refreshPullRequests => 'Оновити pull request';

  @override
  String get noForgeConnected =>
      'На сервері не підключено forge, тож pull request не можна отримати. Підключіть його в програмі для комп’ютера.';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count репозиторіїв не вдалося прочитати.',
      one: '1 репозиторій не вдалося прочитати.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'Нечитабельні: $names';
  }

  @override
  String get installationSuspendedTitle =>
      'Встановлення GitHub App призупинено';

  @override
  String installationSuspendedBody(String names) {
    return 'Показано останні відомі дані для $names. Відновіть встановлення на GitHub або підключіть токен із доступом.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'Встановлення GitHub App призупинено. Показано останні відомі дані для $names. Відновіть встановлення на GitHub або підключіть токен із доступом.';
  }

  @override
  String get draft => 'Чернетка';

  @override
  String get merged => 'Злито';

  @override
  String get closed => 'Закрито';

  @override
  String get open => 'Відкрито';

  @override
  String get approved => 'Схвалено';

  @override
  String get changesRequested => 'Запитано зміни';

  @override
  String get reviewRequired => 'Потрібна перевірка';

  @override
  String get checksPassing => 'Перевірки проходять';

  @override
  String get checksFailing => 'Перевірки не проходять';

  @override
  String get checksRunning => 'Перевірки виконуються';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'Не вдалося завантажити цей pull request';

  @override
  String get openOnForge => 'Відкрити на forge';

  @override
  String get requestChangesNeedsComment =>
      'Додайте коментар, що саме потрібно змінити.';

  @override
  String get conversation => 'Обговорення';

  @override
  String get files => 'Файли';

  @override
  String get checks => 'Перевірки';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файлів',
      one: '1 файл',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count комітів',
      one: '1 коміт',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => 'Конфлікти';

  @override
  String get reviewers => 'Рев\'юери';

  @override
  String get noDescriptionNoComments => 'Ще немає опису й коментарів.';

  @override
  String get noChangedFiles => 'Немає змінених файлів.';

  @override
  String get noChecksReported => 'Для головного коміту перевірок немає.';

  @override
  String get reviewCommentHint => 'Залиште коментар до перевірки…';

  @override
  String get comment => 'Коментар';

  @override
  String get commentPosted => 'Коментар опубліковано';

  @override
  String get request => 'Запит';

  @override
  String get squashAndMerge => 'Стиснути й злити';

  @override
  String noActionsAvailable(String status) {
    return '$status — немає доступних дій.';
  }

  @override
  String get reviewApproved => 'схвалено';

  @override
  String get reviewRequestedChanges => 'запитано змін';

  @override
  String get reviewCommented => 'переглянуто';

  @override
  String get reviewPending => 'очікує';

  @override
  String get unknownAuthor => 'невідомо';

  @override
  String hideDiffFor(String file) {
    return 'Сховати diff для $file';
  }

  @override
  String showDiffFor(String file) {
    return 'Показати diff для $file';
  }

  @override
  String get checkRunning => 'виконується';

  @override
  String get checkPassed => 'пройдено';

  @override
  String get checkFailed => 'не пройдено';

  @override
  String get checkCancelled => 'скасовано';

  @override
  String get checkSkipped => 'пропущено';

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
      'Текстового diff для цього файлу немає — він двійковий або завеликий, щоб forge його повернув.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Показати решту $count рядків',
      one: 'Показати решту рядка',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count незмінених рядків',
      one: '1 незмінений рядок',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'Перейти до останнього';

  @override
  String get streaming => 'Стрімінг';

  @override
  String get working => 'Працює';

  @override
  String get input => 'Вхідні дані';

  @override
  String get output => 'Вихідні дані';

  @override
  String get now => 'щойно';

  @override
  String agoMinutes(int count) {
    return '$countхв';
  }

  @override
  String agoHours(int count) {
    return '$countгод';
  }

  @override
  String agoDays(int count) {
    return '$countд';
  }

  @override
  String get today => 'Сьогодні';

  @override
  String get tomorrow => 'Завтра';

  @override
  String get yesterday => 'Вчора';

  @override
  String durationMinutes(int count) {
    return '$countхв';
  }

  @override
  String durationHours(int count) {
    return '$countгод';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hoursгод $minutesхв';
  }

  @override
  String get mobileConversations => 'Розмови';

  @override
  String get mobileNewConversation => 'Нова розмова';

  @override
  String get mobileConversationName => 'Назва розмови';

  @override
  String get mobileRename => 'Перейменувати';

  @override
  String get mobileManageSpace => 'Керувати простором';

  @override
  String get mobileArchived => 'Архівований';

  @override
  String get mobileSearchMessages =>
      'Шукати в усіх повідомленнях цього простору';

  @override
  String get mobileSearch => 'Пошук';

  @override
  String get mobileNoResults => 'Нічого не знайдено';

  @override
  String get mobileReopen => 'Відкрити знову';

  @override
  String get mobileArchive => 'Архівувати';

  @override
  String get mobileProgress => 'Прогрес і контекст';

  @override
  String get mobileReadFailed => 'Не вдалося позначити цю розмову як прочитану';

  @override
  String get mobileSendFailed =>
      'Повідомлення не надіслано. Чернетку збережено.';

  @override
  String get sentAttachmentUnavailable => 'Вкладення недоступне';

  @override
  String get sentAttachmentLoadFailed => 'Не вдалося завантажити вкладення';

  @override
  String get mobileActionFailed => 'Не вдалося виконати дію';

  @override
  String get mobileRemove => 'Видалити';

  @override
  String get mobileLinkedMessage => 'Пов’язане повідомлення';

  @override
  String get mobileOlderMessages => 'Старіші повідомлення';

  @override
  String get mobileMessageActions => 'Дії з повідомленням';

  @override
  String get mobileOpenThread => 'Відкрити гілку';

  @override
  String get mobileCopyLink => 'Копіювати посилання';

  @override
  String get mobileStopRun => 'Зупинити запуск';

  @override
  String get mobileStopRunConfirm =>
      'Зупинити цей запуск агента? Виконана робота збережеться.';

  @override
  String get mobileControlUnsupported =>
      'Цей запуск завершено або він не підтримує цю дію.';

  @override
  String get mobilePauseRequested => 'Запитано паузу після наступного ходу';

  @override
  String get mobileResumed => 'Запуск відновлено';

  @override
  String get mobileStopRequested => 'Запитано зупинку';

  @override
  String get mobileQueuedMessages => 'Повідомлення в черзі';

  @override
  String get mobilePauseRun => 'Призупинити після наступного ходу';

  @override
  String get mobileResumeRun => 'Продовжити';

  @override
  String get mobileEditQueued => 'Редагувати повідомлення в черзі';

  @override
  String get mobileSteerNow => 'Скерувати зараз';

  @override
  String get mobileMoveUp => 'Перемістити вгору';

  @override
  String get mobileMoveDown => 'Перемістити вниз';

  @override
  String get mobileQueueChanged =>
      'Черга змінилася або цей запуск не приймає вказівок під час виконання. Оновіть сторінку й повторіть спробу.';

  @override
  String get mobileActivity => 'Активність';

  @override
  String get mobilePermissions => 'Дозволи й аудит';

  @override
  String get mobilePlans => 'Плани';

  @override
  String get mobileGoals => 'Контрольовані цілі';

  @override
  String get mobileCredentials => 'Підключення й облікові дані';

  @override
  String get mobileWorkspaceUnavailable =>
      'Цей робочий простір недоступний або ви більше не маєте до нього доступу.';

  @override
  String get mobilePrReviewThreads => 'Обговорення рев’ю';

  @override
  String get mobilePrThreadsLoadFailed =>
      'Не вдалося завантажити обговорення рев’ю';

  @override
  String get mobilePrNoReviewThreads => 'Поки немає обговорень окремих рядків';

  @override
  String get mobilePrCommentPermissionDenied =>
      'Ви не маєте дозволу коментувати цей репозиторій.';

  @override
  String get mobilePrPermissionChecking => 'Перевірка дозволу на коментування…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'Не вдалося перевірити дозвіл. Повторіть спробу, щоб залишити коментар.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side, рядок $line';
  }

  @override
  String get mobilePrOriginalSide => 'Оригінал';

  @override
  String get mobilePrSelectCommentLine => 'Виберіть рядок для коментаря';

  @override
  String get mobilePrUpdatedSide => 'Оновлено';

  @override
  String get mobilePrThreadResolved => 'Розв\'язано';

  @override
  String get mobilePrReplyHint => 'Напишіть відповідь…';

  @override
  String get mobilePrCommentRequired => 'Напишіть коментар перед публікацією.';

  @override
  String get mobilePrReply => 'Відповісти';

  @override
  String get mobilePrReopenThread => 'Відкрити гілку знову';

  @override
  String get mobilePrResolveThread => 'Вирішити гілку';

  @override
  String get mobilePrResolvePermissionDenied =>
      'Вирішити цю гілку може лише автор pull request або користувач із правом запису.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'Коментувати рядок $line ($side)';
  }

  @override
  String get mobilePrInlineCommentHint => 'Напишіть коментар до рядка…';

  @override
  String get mobilePrPostInlineComment => 'Опублікувати коментар';

  @override
  String get mobilePrCommentUnavailable =>
      'Коментарі до рядків недоступні для цього pull request.';

  @override
  String get mobilePrPatchUnavailable =>
      'Forge не надав текстовий патч для цього файлу.';

  @override
  String get mobilePrNoPatchForFile => 'Патч для цього файлу недоступний.';

  @override
  String get mobileTicketNew => 'Новий тікет';

  @override
  String get mobileTicketCreate => 'Створити тікет';

  @override
  String get mobileTicketEdit => 'Редагувати тікет';

  @override
  String get mobileTicketTitle => 'Назва';

  @override
  String get mobileTicketTitleRequired => 'Введіть назву, щоб зберегти тікет.';

  @override
  String get mobileTicketDescription => 'Опис';

  @override
  String get mobileTicketMarkdownHint => 'Додайте подробиці у Markdown';

  @override
  String get mobileTicketPriority => 'Пріоритет';

  @override
  String get mobileTicketPriorityNone => 'Без пріоритету';

  @override
  String get mobileTicketPriorityUrgent => 'Терміновий';

  @override
  String get mobileTicketPriorityHigh => 'Високий';

  @override
  String get mobileTicketPriorityMedium => 'Середній';

  @override
  String get mobileTicketPriorityLow => 'Низький';

  @override
  String get mobileTicketLabels => 'Мітки';

  @override
  String get mobileTicketLabelsHint => 'Одна мітка на рядок';

  @override
  String get mobileTicketLabelsHelp => 'Вводьте кожну мітку з нового рядка.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'Створено в $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'Не призначено';

  @override
  String get mobileTicketAssignedFilter => 'Призначені';

  @override
  String get mobileTicketAgentsLoadFailed => 'Не вдалося завантажити агентів';

  @override
  String get mobileTicketSearch => 'Пошук тікетів';

  @override
  String get mobileTicketSearchHint =>
      'Назва, ключ, опис, мітка або виконавець';

  @override
  String get mobileTicketClearSearch => 'Очистити пошук тікетів';

  @override
  String get mobileTicketNoMatches => 'Тікетів не знайдено';

  @override
  String get mobileTicketAdjustFilters =>
      'Спробуйте інший запит або змініть фільтри.';

  @override
  String get mobileTicketClearFilters => 'Очистити фільтри';

  @override
  String get mobileTicketNotFound => 'Тікет не знайдено';

  @override
  String get mobileTicketNotFoundDescription =>
      'Можливо, цей тікет видалено або перенесено з цього робочого простору.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'Робочий простір змінився. Перед збереженням поверніться до поточного простору.';

  @override
  String get mobileTicketOpenLinkedSpace => 'Відкрити пов’язаний простір';

  @override
  String get mobileTicketReadOnly =>
      'Щоб змінювати тікети, потрібна роль учасника робочого простору.';

  @override
  String get permissionTitle => 'Дозволи';

  @override
  String get permissionWorkspaceFailed =>
      'Не вдалося завантажити робочий простір';

  @override
  String get permissionNoWorkspace =>
      'Виберіть робочий простір, щоб переглянути дозволи.';

  @override
  String get permissionLoading => 'Завантаження дозволів…';

  @override
  String get permissionScopeDescription =>
      'Перегляньте, як ухвалюється рішення щодо кожної дії в цій області. Агенти й простори можуть успадковувати правила робочого простору.';

  @override
  String get permissionScope => 'Область дії політики';

  @override
  String get permissionWorkspaceScope => 'Робочий простір';

  @override
  String get permissionAgentScope => 'Агент';

  @override
  String get permissionSpaceScope => 'Простір';

  @override
  String get permissionAgentContext => 'Агент, що діє в цьому просторі';

  @override
  String get permissionNoAgentContext => 'Агента не вибрано';

  @override
  String get permissionTargetsFailed =>
      'Не вдалося завантажити об’єкти цієї області';

  @override
  String get permissionNoTargets => 'У цій області немає доступних об’єктів.';

  @override
  String get permissionRoleFailed =>
      'Не вдалося підтвердити вашу роль у робочому просторі';

  @override
  String get permissionMemberRequired =>
      'Щоб переглядати правила політики, потрібна роль учасника робочого простору.';

  @override
  String get permissionRulesFailed => 'Не вдалося завантажити правила політики';

  @override
  String get permissionAuditAdminOnly =>
      'Історія авторизації доступна лише адміністраторам робочого простору.';

  @override
  String get permissionAllow => 'Дозволити';

  @override
  String get permissionAsk => 'Спочатку запитати';

  @override
  String get permissionDeny => 'Заборонити';

  @override
  String get permissionFileDelete => 'Видаляти файли';

  @override
  String get permissionFileWriteOutsideWorktree =>
      'Записувати за межами робочого дерева';

  @override
  String get permissionGitCommit => 'Створювати коміти';

  @override
  String get permissionGitPush => 'Надсилати коміти';

  @override
  String get permissionPrCreate => 'Створювати pull request';

  @override
  String get permissionPrPublish => 'Публікувати pull request';

  @override
  String get permissionVendorSyncWrite =>
      'Записувати синхронізацію постачальника';

  @override
  String get permissionNetworkEgress => 'Мати доступ до мережі';

  @override
  String get permissionSecretAccess => 'Мати доступ до секретів';

  @override
  String get permissionPackageInstall => 'Встановлювати пакети';

  @override
  String get permissionProcessSpawn => 'Запускати процеси';

  @override
  String get permissionWorkspaceMutation => 'Змінювати робочий простір';

  @override
  String get permissionEnclosureControl => 'Керувати середовищем виконання';

  @override
  String get permissionChangeFailed => 'Не вдалося змінити правило';

  @override
  String get permissionEffectiveDescription =>
      'Діє в цій області без аргументів дії. Умовні дозволи нижче застосовуються лише до відповідних запитів; остаточне рішення ухвалює сервер.';

  @override
  String get permissionSpaceAgentNote =>
      'Агента не вибрано. Правила для конкретного агента з’являться після вибору вище.';

  @override
  String get permissionScopedGrants => 'Правила в цій області';

  @override
  String get permissionModePreset => 'Пресет режиму';

  @override
  String get permissionBuiltInDefault => 'Вбудований стандарт';

  @override
  String get permissionRemembered => 'Збережене схвалення';

  @override
  String get permissionSource => 'Джерело';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · встановлено тут';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · успадковано';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'Закінчується $date';
  }

  @override
  String get permissionSetHere => 'Установити правило тут';

  @override
  String get permissionRevokeBeforeEdit =>
      'Перш ніж установлювати загальне правило для цієї дії, скасуйте правило з обмеженою областю дії або збережене правило.';

  @override
  String get permissionConfirmRevoke => 'Підтвердити скасування';

  @override
  String get permissionRevokeRule => 'Скасувати правило';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'Префікс команди: $prefix';
  }

  @override
  String get permissionNoExpiry => 'Без строку дії';

  @override
  String get permissionExpired => 'Прострочене';

  @override
  String get permissionExplicitRule => 'Явне правило';

  @override
  String get permissionEnforcementAdvisory =>
      'Рекомендаційний режим: правила «спочатку запитати» фіксуються без запиту';

  @override
  String get permissionEnforcementSoft =>
      'М’яке застосування: для обходу потрібна авторизація';

  @override
  String get permissionEnforcementHard =>
      'Суворе застосування: обійти неможливо';

  @override
  String permissionPaths(String paths) {
    return 'Шляхи: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Посилання Git: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'Хости: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'Команди: $commands';
  }

  @override
  String permissionMaxCount(String count) {
    return 'Максимальна кількість: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'Максимум центів: $cents';
  }

  @override
  String get permissionAuditHeading => 'Історія авторизації';

  @override
  String get permissionAuditDescription =>
      'Нещодавні рішення, записані сервером. Лише адміністратори можуть переглядати журнал або перевіряти його ланцюг хешів.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'від імені $user';
  }

  @override
  String get permissionPrompted => 'Запитано схвалення людини';

  @override
  String get permissionVerifyChain => 'Перевірити ланцюг аудиту';

  @override
  String get permissionVerifyFailed => 'Не вдалося перевірити ланцюг аудиту';

  @override
  String permissionChainIntact(String count) {
    return 'Ланцюг цілий · перевірено записів: $count';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'Ланцюг порушено на записі $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty =>
      'Рішення щодо авторизації ще не записувалися.';

  @override
  String get permissionAuditFailed =>
      'Не вдалося завантажити історію авторизації';

  @override
  String get mobilePlansLoadFailed => 'Не вдалося завантажити плани';

  @override
  String get mobilePlansEmpty => 'Планів поки немає';

  @override
  String get mobilePlansEmptyDescription =>
      'Плани, надіслані агентами, з’являться тут для перегляду.';

  @override
  String get mobilePlanTitle => 'План';

  @override
  String get mobilePlanMissing =>
      'Цей план більше недоступний у цьому робочому просторі.';

  @override
  String mobilePlanStepCount(int count) {
    return 'Кроків: $count';
  }

  @override
  String get mobilePlanDraft => 'Чернетка';

  @override
  String get mobilePlanProposed => 'Очікує перегляду';

  @override
  String get mobilePlanApproved => 'Схвалено';

  @override
  String get mobilePlanRejected => 'Відхилено';

  @override
  String get mobilePlanSuperseded => 'Замінено';

  @override
  String get mobilePlanExecuting => 'Виконується';

  @override
  String get mobilePlanSynthesizing => 'Синтез';

  @override
  String get mobilePlanCompleted => 'Завершено';

  @override
  String get mobilePlanFailed => 'Збій';

  @override
  String get mobilePlanCancelled => 'Скасовано';

  @override
  String mobilePlanRevision(String revision) {
    return 'Ревізія $revision';
  }

  @override
  String get mobilePlanSteps => 'Кроки';

  @override
  String get mobilePlanNoSteps => 'Для цього плану не подано жодного кроку.';

  @override
  String get mobilePlanAssumptions => 'Уточнення';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'Залежить від $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'Орієнтовно до $cost';
  }

  @override
  String get mobilePlanSelect => 'Вибрати';

  @override
  String get mobilePlanSelected => 'Вибрано';

  @override
  String get mobilePlanEstimate => 'Оцінити вартість';

  @override
  String get mobilePlanEstimateRequired =>
      'Оцініть вартість плану, перш ніж схвалювати виконання.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'Орієнтовна вартість: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'недоступно';

  @override
  String get mobilePlanNoHardCap => 'без жорсткого обмеження';

  @override
  String get mobilePlanExceedsBudget =>
      'Оцінка перевищує встановлений бюджет. Перевірте перед схваленням.';

  @override
  String get mobilePlanPartialEstimate =>
      'Оцінка охоплює весь план; вибрані кроки можуть коштувати менше.';

  @override
  String get mobilePlanConfirmAll => 'Запустити весь план?';

  @override
  String get mobilePlanConfirmSelected => 'Запустити вибрані кроки?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'Схвалення запускає виконання й може спричинити витрати. Верхня оцінка вартості: $cost. Ліміт бюджету: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'Схвалити все й запустити';

  @override
  String get mobilePlanApproveSelected => 'Схвалити вибране й запустити';

  @override
  String get mobilePlanWiden => 'Схвалити додаткові кроки';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'Дозволити виконання ще $count кроків? Це може спричинити витрати. Поточний ліміт витрат на виконання: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'План змінився під час перегляду. Відкрийте останню редакцію та оцініть її знову.';

  @override
  String get mobilePlanReject => 'Відхилити план';

  @override
  String get mobilePlanRejectConfirm =>
      'Відхилити цей план? Його не буде виконано.';

  @override
  String get mobilePlanStop => 'Зупинити виконання';

  @override
  String get mobilePlanStopConfirm =>
      'Зупинити виконання цього плану? Уже зроблену роботу не буде скасовано.';

  @override
  String mobilePlanRunId(String runId) {
    return 'Запуск виконання: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'Схвалення прийнято. Очікування запису про виконання…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return 'Виконано $completed із $total кроків';
  }

  @override
  String get mobilePlanOpenConversation => 'Відкрити розмову';

  @override
  String get mobileGoalsTitle => 'Контрольовані цілі';

  @override
  String get mobileGoalsLoadFailed =>
      'Не вдалося завантажити контрольовані цілі';

  @override
  String get mobileGoalsEmpty => 'Контрольованих цілей поки немає';

  @override
  String get mobileGoalsEmptyDescription =>
      'Почніть ціль у просторі або надішліть /goal у розмові.';

  @override
  String get mobileGoalMissing =>
      'Ця ціль більше недоступна в цьому робочому просторі.';

  @override
  String get mobileGoalActive => 'Активний';

  @override
  String get mobileGoalPaused => 'Призупинена';

  @override
  String get mobileGoalCompleted => 'Завершено';

  @override
  String get mobileGoalFailed => 'Збій';

  @override
  String get mobileGoalCancelled => 'Скасовано';

  @override
  String get mobileGoalBudgetExhausted => 'Ліміт бюджету досягнуто';

  @override
  String get mobileGoalGoal => 'Мета';

  @override
  String get mobileGoalLoop => 'Цикл';

  @override
  String mobileGoalKind(String kind) {
    return 'Тип: $kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return 'Запусків: $count';
  }

  @override
  String get mobileGoalNoRunLimit => 'без обмежень';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return 'Запуски: $runs / $maxRuns · Витрачено: $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return 'Кінцевий термін: $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return 'Невдалих запусків поспіль: $count';
  }

  @override
  String get mobileGoalSummary => 'Підсумок виконання';

  @override
  String get mobileGoalFailedDescription =>
      'Керівник зупинився після кількох невдалих запусків. Подробиці є в розмові.';

  @override
  String get mobileGoalBudgetWall =>
      'Досягнуто кінцевого терміну або ліміту запусків. Підвищення ліміту витрат не відновить цю ціль.';

  @override
  String get mobileGoalPause => 'Призупинити ціль';

  @override
  String get mobileGoalResume => 'Відновити ціль';

  @override
  String get mobileGoalStop => 'Скасувати ціль';

  @override
  String get mobileGoalStopConfirm =>
      'Назавжди скасувати цю контрольовану ціль? Її не можна буде відновити.';

  @override
  String get mobileGoalRaiseBudget => 'Збільшити бюджет і відновити';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'Збільшити бюджет до $amount і відновити';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'Збільшити ліміт витрат на цю ціль із $oldCap до $newCap і відновити витрати?';
  }

  @override
  String get mobileGoalOpenConversation => 'Відкрити розмову про ціль';

  @override
  String get mobileGoalCreate => 'Почати контрольовану ціль';

  @override
  String get mobileGoalChooseSpace => 'Запустити в просторі';

  @override
  String get mobileGoalNoSpaces => 'Створіть простір, перш ніж починати ціль.';

  @override
  String get mobileGoalChooseAgent => 'Запустити з агентом';

  @override
  String get mobileGoalNoAgents =>
      'Додайте активного агента, перш ніж починати ціль.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return 'Вибрано: $name';
  }

  @override
  String get mobileGoalObjectiveHint => 'Якого результату має досягти агент?';

  @override
  String get mobileGoalBudgetUsd => 'Ліміт витрат (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'Виберіть простір і агента, введіть ціль та встановіть додатний ліміт витрат у USD.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'Почати контрольовану ціль із лімітом витрат $cap? Агент може розпочати роботу відразу.';
  }

  @override
  String get mobileGoalUnavailable =>
      'З’єднання із сервером не готове. Повторіть спробу після перепідключення.';

  @override
  String get mobileGoalConversationMissing =>
      'Вибрана розмова більше недоступна в цьому робочому просторі.';

  @override
  String get mobileGoalCreateSent =>
      'Ціль запущено. Стан керівника з’явиться в цьому списку.';

  @override
  String get mobileGoalStartRefused =>
      'Запуск цілі не розпочався. Перегляньте причину керівника в розмові.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return 'Вибрано: $name';
  }

  @override
  String get requestUnavailable =>
      'Цей запит більше недоступний в активному робочому просторі.';

  @override
  String get requestAlreadyResolved => 'Цей запит уже вирішено.';

  @override
  String get inboxCredentialsBlocked => 'Облікові дані блокують запуски';

  @override
  String get inboxSyncFailures => 'Невдалі синхронізації з постачальниками';

  @override
  String get inboxConfigureCredentials => 'Налаштувати облікові дані';

  @override
  String get openTicket => 'Відкрити тікет';

  @override
  String get activityTitle => 'Активність';

  @override
  String get activityClearAll => 'Очистити активність';

  @override
  String get activityClearConfirm =>
      'Це приховає всю записану для вас активність на всіх пристроях. Нова активність і далі з’являтиметься.';

  @override
  String get activityMarkAllRead => 'Позначити все як прочитане';

  @override
  String get activityMarkAllConfirm =>
      'Позначити всі записи активності цього робочого простору як прочитані на всіх ваших пристроях?';

  @override
  String get activityMarkRead => 'Позначити як прочитане';

  @override
  String get activityMarkUnread => 'Позначити як непрочитане';

  @override
  String get activityDismiss => 'Відхилити';

  @override
  String get activityResolved => 'Розв\'язано';

  @override
  String get activityOpen => 'Відкритий';

  @override
  String get activityEmpty => 'Поки немає активності';

  @override
  String get activityLoadFailed => 'Не вдалося завантажити активність';

  @override
  String get activityAgentWaiting => 'Агенту потрібні ваші вказівки';

  @override
  String get activityAgentBlocked => 'Дію агента заблоковано';

  @override
  String get activityMessage => 'Нове повідомлення';

  @override
  String get activityPullRequest => 'Оновлення pull request';

  @override
  String get activityTicket => 'Оновлення тікета';

  @override
  String get activityMeeting => 'Оновлення зустрічі';

  @override
  String get activityCalendar => 'Підключення календаря';

  @override
  String get activityRig => 'Оновлення середовища виконання';

  @override
  String get activityEvent => 'Оновити';

  @override
  String get activityPrReady => 'Pull request готовий до злиття';

  @override
  String get activityPrBlocked => 'Злиття pull request заблоковано';

  @override
  String get activityPrApproved => 'Pull request схвалено';

  @override
  String get activityPrChanges => 'Запитано зміни';

  @override
  String get activityPrChecksFailed => 'Перевірки pull request не пройдено';

  @override
  String get activityPrChecksRecovered =>
      'Перевірки pull request знову пройдено';

  @override
  String get activityPrComment => 'Коментар до pull request';

  @override
  String get activityPrPublished => 'Pull request опубліковано';

  @override
  String get activityPrMerged => 'Pull request злито';

  @override
  String get activityPrMentioned => 'Вас згадано в pull request';

  @override
  String get activityPrReviewRequested => 'Запит на рев’ю';

  @override
  String get activityPrReviewStale => 'Рев’ю потрібно оновити';

  @override
  String get activityTicketAssigned => 'Тікет призначено';

  @override
  String get activityTicketChanged => 'Статус тікета змінено';

  @override
  String get activityMeetingSoon => 'Зустріч незабаром почнеться';

  @override
  String get activityCalendarExpired =>
      'Термін дії підключення календаря закінчився';

  @override
  String get activityRigControl => 'Керування середовищем виконання змінено';

  @override
  String get activityRigClosed => 'Середовище виконання зупинено';

  @override
  String get mobileSpacesSearch => 'Пошук просторів';

  @override
  String get mobileSpacesArchived => 'Архівований';

  @override
  String get mobileSpacesActive => 'Активний';

  @override
  String get mobileSpacesNew => 'Новий простір';

  @override
  String get mobileSpacesManage => 'Керувати простором';

  @override
  String get mobileSpacesName => 'Назва простору';

  @override
  String get mobileSpacesAgents => 'Агенти';

  @override
  String get mobileSpacesMembers => 'Люди';

  @override
  String get mobileSpacesRepos => 'Репозиторії';

  @override
  String get mobileSpacesAllRepos => 'Усі пов’язані репозиторії';

  @override
  String get mobileSpacesNoRepos => 'Немає репозиторіїв';

  @override
  String get mobileSpacesBaseBranch => 'Базова гілка (необов’язково)';

  @override
  String get mobileSpacesDefaultBranch => 'Гілка за замовчуванням';

  @override
  String get mobileSpacesMode => 'Режим';

  @override
  String get mobileSpacesModeChat => 'Чат';

  @override
  String get mobileSpacesModeReview => 'Рев’ю (лише читання)';

  @override
  String get mobileSpacesModePlan => 'Планування (лише читання)';

  @override
  String get mobileSpacesModeOrchestrate => 'Оркеструвати';

  @override
  String get mobileSpacesAutonomy => 'Перевизначення автономії';

  @override
  String get mobileSpacesAutonomyInherited => 'Успадковано';

  @override
  String get mobileSpacesAutonomyPropose => 'Лише пропонувати';

  @override
  String get mobileSpacesAutonomyApproval => 'Діяти з підтвердженням';

  @override
  String get mobileSpacesAutonomyFreely => 'Діяти вільно';

  @override
  String get mobileSpacesAutonomyNotice =>
      'Перевизначення не може обійти запити схвалення або заборони політики дій. Змінювати його можуть лише адміністратори робочого простору.';

  @override
  String get mobileSpacesArchive => 'Архівувати простір';

  @override
  String get mobileSpacesReopen => 'Відкрити простір знову';

  @override
  String get mobileSpacesSave => 'Зберегти зміни';

  @override
  String get mobileSpacesCreate => 'Створити простір';

  @override
  String get mobileSpacesOperationFailed => 'Не вдалося оновити простір';

  @override
  String get mobileSpacesMissing =>
      'Простір не знайдено в цьому робочому просторі';

  @override
  String get mobileSpacesEmptyName => 'Введіть назву простору';

  @override
  String get mobileSpacesNoMatches => 'Просторів не знайдено';

  @override
  String get mobileSpacesUnread => 'Непрочитана відповідь агента';

  @override
  String get mobileSpacesNeedsInput => 'Потрібні ваші вказівки';

  @override
  String get mobileSpacesRunning => 'Агент працює';

  @override
  String get mobileSpacesNoAgents => 'У цьому робочому просторі немає агентів';

  @override
  String get mobileSpacesNoMembers => 'Немає інших учасників робочого простору';

  @override
  String get mobileSpacesRepoError => 'Не вдалося завантажити репозиторії';

  @override
  String get mobileSpacesRetry => 'Повторити';

  @override
  String get mobileSpacesBranchUnavailable =>
      'Під час створення простору виберіть або введіть базову гілку; базову гілку наявного простору змінити не можна.';

  @override
  String get mobileSpacesArchivedEmpty => 'Немає архівованих просторів';

  @override
  String get mobileSpacesAllRepoWarning =>
      'Нові репозиторії, пов’язані з робочим простором, також додаватимуться до цього простору.';

  @override
  String get mobileSpacesCreatedRetry =>
      'Простір створено. Спробуйте ще раз додати людей або відкрийте сторінку керування.';

  @override
  String get progressTitle => 'Прогрес';

  @override
  String get progressConversation => 'Розмова';

  @override
  String get progressLoadFailed => 'Не вдалося завантажити прогрес';

  @override
  String get progressUnavailable => 'Розмова недоступна';

  @override
  String get progressUnavailableDescription =>
      'Ця розмова не належить до активного робочого простору та простору. Щоб продовжити, поверніться до її простору.';

  @override
  String get progressSaveFailed => 'Не вдалося оновити прогрес';

  @override
  String get progressGoal => 'Мета';

  @override
  String get progressNoGoal => 'Робочу ціль не задано';

  @override
  String get progressSetGoal => 'Задати ціль';

  @override
  String get progressEditGoal => 'Редагувати ціль';

  @override
  String get progressClearGoal => 'Очистити ціль';

  @override
  String get progressGoalRequired => 'Введіть ціль перед збереженням.';

  @override
  String get progressTodos => 'Завдання';

  @override
  String get transcriptToolTodos => 'Завдання';

  @override
  String get transcriptToolSearchMemory => 'Пошук у пам’яті';

  @override
  String get transcriptToolRenderMedia => 'Показати медіа';

  @override
  String get progressNoTodos => 'Завдань поки немає';

  @override
  String get progressNewTodo => 'Нове завдання';

  @override
  String get progressAddTodo => 'Додати завдання';

  @override
  String get progressEditTodo => 'Редагувати завдання';

  @override
  String get progressTodoRequired => 'Введіть завдання перед збереженням.';

  @override
  String get progressTodoNoLongerExists =>
      'Це завдання видалено. Оновіть список і повторіть спробу.';

  @override
  String get progressWorkspaceChanged =>
      'Активний робочий простір змінився. Поверніться до цієї розмови й повторіть спробу.';

  @override
  String progressRemoveTodo(String name) {
    return 'Видалити завдання $name';
  }

  @override
  String get progressPending => 'Очікування';

  @override
  String get progressInProgress => 'У процесі';

  @override
  String get progressCompleted => 'Завершено';

  @override
  String get progressMoveUp => 'Перемістити завдання вгору';

  @override
  String get progressMoveDown => 'Перемістити завдання вниз';

  @override
  String get progressRunTree => 'Запуски агентів';

  @override
  String get progressNoRuns => 'У цій розмові ще немає запусків';

  @override
  String get progressRunning => 'Виконується';

  @override
  String get progressFailed => 'Збій';

  @override
  String get progressUnknown => 'Невідомо';

  @override
  String get progressHealthy => 'Активний';

  @override
  String get progressBlocked => 'Заблоковано';

  @override
  String get progressLooping => 'Зациклено';

  @override
  String get progressStalled => 'Завис';

  @override
  String get progressDead => 'Неочікувано зупинено';

  @override
  String get progressQuiet => 'Поки немає виводу';

  @override
  String get progressCostReported => 'Сума, повідомлена постачальником';

  @override
  String get progressCostNotional =>
      'Умовна ціна підписки за прейскурантом, а не рахунок';

  @override
  String get progressCostMixed => 'Різні джерела даних про вартість';

  @override
  String get progressCostEstimated => 'Орієнтовна вартість';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds с';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'Модель: $model · Час: $duration · Вартість: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'Запущено $time';
  }

  @override
  String progressLiveness(String state) {
    return 'Стан: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'Вхід: $input · Вихід: $output токенів';
  }

  @override
  String get progressOutputPreviewLimited =>
      'Показано лише перші 6 000 символів структурованого виводу.';

  @override
  String progressRetryOf(String runId) {
    return 'Повтор запуску $runId';
  }

  @override
  String get progressContext => 'Контекст і обмеження';

  @override
  String get progressNoAgent => 'Немає агента для перегляду';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window токенів';
  }

  @override
  String get progressMeasured =>
      'Контекст останнього виклику за даними постачальника';

  @override
  String get progressEstimated =>
      'Оцінка за збереженою розмовою та постійним контекстом';

  @override
  String get progressContextUnknown =>
      'Використання контексту ще не повідомлено';

  @override
  String progressContextPercent(String percent) {
    return '$percent% контекстного вікна';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'Налаштований місячний ліміт агента: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'Збережена активна розмова: орієнтовно $tokens токенів';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'Постійний контекст для $agent · $model';
  }

  @override
  String get progressContextSystem => 'Системний промпт';

  @override
  String get progressContextRules => 'Правила';

  @override
  String get progressContextSkills => 'Навички';

  @override
  String get progressContextTools => 'Визначення інструментів';

  @override
  String get progressContextMcp => 'Інструменти MCP';

  @override
  String get progressContextDeferred => 'Відкладені інструменти';

  @override
  String get progressContextSubagents => 'Субагенти';

  @override
  String get progressContextRunner => 'Зовнішній засіб запуску';

  @override
  String get progressContextMemory => 'Пам’ять';

  @override
  String get progressContextHistory => 'Історія розмови';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens токенів';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens токенів';
  }

  @override
  String get progressOutputs => 'Останні результати';

  @override
  String get progressNoOutputs => 'Немає нещодавніх результатів роботи агента';

  @override
  String get progressStructuredOutputsAbove =>
      'Структуровані результати запусків наведено вище серед запусків агентів.';

  @override
  String get progressRecentOutputsOnly =>
      'Показано лише останні повідомлення. Щоб переглянути попередню роботу, відкрийте розмову.';

  @override
  String get progressPlan => 'План';

  @override
  String get progressArtifact => 'Артефакт';

  @override
  String get progressResult => 'Результат';

  @override
  String get progressHideArtifact => 'Приховати артефакт';

  @override
  String get progressReadArtifact => 'Прочитати артефакт';

  @override
  String get progressArtifactUnavailable => 'Артефакт більше недоступний';

  @override
  String get progressArtifactPreviewLimited =>
      'Показано скорочений перегляд цього артефакту.';

  @override
  String get progressDiagramSource => 'Джерело діаграми';

  @override
  String progressOpenAttachment(String name) {
    return 'Відкрити $name';
  }

  @override
  String get progressOpenPlan => 'Відкрити план';

  @override
  String progressOpenDiff(String label) {
    return 'Переглянути змінені файли: $label';
  }

  @override
  String get progressViewMessage => 'Переглянути повідомлення';

  @override
  String get pushTitle => 'Фонові сповіщення';

  @override
  String get pushIntro =>
      'Отримуйте приватне сповіщення, коли щось потребує вашої уваги, навіть якщо застосунок закрито. Подробиці залишаються у вашому зашифрованому з’єднанні.';

  @override
  String get pushLoading => 'Перевірка налаштувань сповіщень…';

  @override
  String get pushError =>
      'Не вдалося оновити сповіщення. Перевірте з’єднання й повторіть спробу.';

  @override
  String get pushEnable => 'Увімкнути сповіщення';

  @override
  String get pushDisable => 'Вимкнути сповіщення';

  @override
  String get pushQuiet => 'Призупинити сповіщення на цьому пристрої';

  @override
  String get pushCategories => 'Сповіщати мене про';

  @override
  String get pushCategoryAgents => 'Агенти';

  @override
  String get pushCategoryMessages => 'Повідомлення';

  @override
  String get pushCategoryPullRequests => 'Pull requests';

  @override
  String get pushCategoryTickets => 'Тікети';

  @override
  String get pushCategoryCalendar => 'Календар';

  @override
  String get pushCategoryMachines => 'Машини';

  @override
  String get pushSecureOrigin => 'Для сповіщень потрібен HTTPS.';

  @override
  String get pushInstallIos =>
      'Щоб увімкнути сповіщення на iPhone або iPad, додайте застосунок на головний екран і відкрийте його звідти.';

  @override
  String get pushUnsupported => 'Цей браузер не підтримує фонові сповіщення.';

  @override
  String get pushDenied =>
      'Браузер повідомляє, що сповіщення заблоковано. Перевірте дозвіл для цього сайту й налаштування сповіщень у браузері або на пристрої, а потім оновіть сторінку.';

  @override
  String get pushResubscribe => 'Підключити сповіщення знову';

  @override
  String get pushStatusEnabled => 'Сповіщення на цьому пристрої ввімкнено.';

  @override
  String get pushStatusDisabled => 'Сповіщення на цьому пристрої вимкнено.';

  @override
  String get credentialsTitle => 'Підключення й облікові дані';

  @override
  String get credentialsIntro =>
      'Підключіть облікові записи, які використовують ваші запуски та інтеграції. Секрети зберігаються на вашому сервері, а не на телефоні.';

  @override
  String get credentialsModelProviders => 'Постачальники моделей';

  @override
  String get credentialsOwnerOnly =>
      'Лише власник сервера може додавати чи видаляти облікові дані постачальників моделей і входити за їх допомогою. Ці ключі спільні для всіх робочих просторів.';

  @override
  String get credentialsContactOwner =>
      'Попросіть власника сервера підключити постачальника, потрібного для заблокованого запуску.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude Code входить через CLI на хостовій машині. Попросіть власника сервера увійти в обліковий запис або оновити вхід у терміналі хоста; із телефона це зробити не можна.';

  @override
  String get credentialsYourForgeAccounts =>
      'Ваші облікові записи платформ коду';

  @override
  String get credentialsYourTicketingAccount =>
      'Ваш обліковий запис системи тікетів';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'Для локальних тікетів вхід не потрібен. Якщо ваш робочий простір використовує Linear, підключіть його тут.';

  @override
  String get credentialsMembershipRequired =>
      'Приєднайтеся до робочого простору, щоб керувати обліковими даними платформ коду або системи тікетів. Попросіть доступ в адміністратора робочого простору.';

  @override
  String get credentialsSwitchWorkspace =>
      'Це посилання веде до іншого робочого простору. Перейдіть до нього, перш ніж змінювати облікові дані.';

  @override
  String get credentialsReturnToInbox =>
      'Коли облікові дані буде підключено, поверніться до вхідних, щоб повторити заблокований запуск. Хост також автоматично перевіряє призупинені запуски.';

  @override
  String get credentialsLoadFailed =>
      'Не вдалося завантажити підключення. Перевірте з’єднання із сервером і повторіть спробу.';

  @override
  String get credentialsOperationFailed =>
      'Не вдалося змінити це підключення. Перевірте з’єднання із сервером, свій доступ і облікові дані, а потім повторіть спробу.';

  @override
  String get credentialsConnected => 'Підключено';

  @override
  String get credentialsNotConnected => 'Не підключено';

  @override
  String credentialsSignedInAs(String username) {
    return 'Вхід як $username';
  }

  @override
  String get credentialsAccount => 'Підключений обліковий запис';

  @override
  String get credentialsStoredKey => 'Збережений ключ';

  @override
  String get credentialsActive => 'Активний';

  @override
  String get credentialsRemove => 'Видалити';

  @override
  String get credentialsRemoveConfirm =>
      'Видалити збережені облікові дані? Можливо, доведеться увійти знову.';

  @override
  String get credentialsApiKey => 'API-ключ';

  @override
  String get credentialsApiKeyHint => 'Вставте API-ключ постачальника';

  @override
  String get credentialsBrowserLogin => 'Увійти через браузер';

  @override
  String get credentialsSignInAgain => 'Увійдіть знову';

  @override
  String get credentialsWaitingForLogin =>
      'Очікування авторизації у вашому браузері…';

  @override
  String get credentialsLoginTimedOut => 'Час входу минув. Почніть вхід знову.';

  @override
  String get credentialsCopyCode => 'Копіювати код';

  @override
  String get credentialsDeviceCodeHint =>
      'Підтвердьте цей код на сторінці постачальника. Не закривайте цей екран, доки сервер не завершить вхід.';

  @override
  String get credentialsPasteRedirect =>
      'Код авторизації або URL переспрямування';

  @override
  String get credentialsPasteRedirectHint =>
      'Вставте код або повний URL переспрямування від постачальника';

  @override
  String get credentialsCompleteLogin => 'Завершити вхід';

  @override
  String get credentialsRedirectUnavailable =>
      'Захищений доступ до зворотного виклику браузера цього сервера з телефона неможливий. Попросіть власника сервера налаштувати загальнодоступний зворотний виклик HTTPS або додайте токен.';

  @override
  String get credentialsUpdateToken => 'Оновити токен';

  @override
  String get credentialsAddToken => 'Додати токен';

  @override
  String get credentialsPersonalToken => 'Особистий токен доступу';

  @override
  String get credentialsPersonalTokenHint => 'Вставте особистий токен доступу';

  @override
  String get credentialsHostManaged =>
      'Це підключення налаштовано в серверному застосунку або середовищі. Змінити його там може лише власник сервера, але ви можете додати власний токен.';

  @override
  String get credentialsStopWatching => 'Припинити відстеження';
}
