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
      'Відскануйте QR-код на Mac, щоб під’єднати цей телефон.';

  @override
  String get scanQrHelp =>
      'Відкрийте камеру й наведіть її на QR у Control Center на Mac. Телефон з’єднується з Mac напряму через приватне посилання.';

  @override
  String get connectingToMac => 'Підключення до Mac…';

  @override
  String get connectingDetail => 'Налагоджуємо захищене пряме з’єднання.';

  @override
  String get identityChangedTitle => 'Ідентичність сервера змінилась';

  @override
  String get identityChangedBody =>
      'Цей сервер більше не відповідає ідентичності, збереженій під час підключення. Можливо, сервер перевстановили — або хтось перехоплює з’єднання. З міркувань безпеки цей пристрій не підключиться. Видаліть підключення, потім відскануйте новий QR-код на Mac, щоб під’єднатися знову.';

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
  String get failureNotPaired => 'Не підключено — відскануйте QR-код на Mac';

  @override
  String get failureUnreachable =>
      'Не вдалося достукатися до сервера жодним шляхом — перевірте, що він запущений, або спробуйте ту саму мережу';

  @override
  String get failureIdentityChanged =>
      'Ідентичність сервера змінилась — якщо його перевстановили, підключіть цей пристрій знову';

  @override
  String get failureAuthRejected =>
      'Сервер відхилив цей пристрій — підключіть його знову з Mac';

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
      'Натисніть ще раз, щоб від’єднати цей пристрій від Mac';

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
}
