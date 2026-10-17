// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Назад';

  @override
  String get cancel => 'Отмена';

  @override
  String get retry => 'Повторить';

  @override
  String get tryAgain => 'Повторить';

  @override
  String get settings => 'Настройки';

  @override
  String get refresh => 'Обновить';

  @override
  String get approve => 'Одобрить';

  @override
  String get deny => 'Отклонить';

  @override
  String get continueLabel => 'Продолжить';

  @override
  String get agentQuestionHeader => 'Вопрос для вас';

  @override
  String get agentQuestionAnsweredLabel => 'Отвечено';

  @override
  String get agentQuestionSkip => 'Пропустить';

  @override
  String get agentQuestionSkippedLabel => 'Пропущено';

  @override
  String get agentQuestionFreeformHint => 'Введите ответ…';

  @override
  String get agentApprovalRequired => 'Требуется подтверждение';

  @override
  String get copyCommand => 'Скопировать команду';

  @override
  String get approveAndRemember => 'Разрешить на 8 часов';

  @override
  String get decline => 'Отклонить';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get send => 'Отправить';

  @override
  String get close => 'Закрыть';

  @override
  String get expand => 'Развернуть';

  @override
  String get zoomIn => 'Увеличить';

  @override
  String get zoomOut => 'Уменьшить';

  @override
  String get resetZoom => 'Сбросить масштаб';

  @override
  String get scanQrPrompt =>
      'Отсканируйте QR-код в Control Center, чтобы связать этот телефон.';

  @override
  String get scanQrHelp =>
      'Откройте камеру и наведите её на QR в Control Center. Телефон подключается напрямую по закрытому каналу.';

  @override
  String get connectingToMac => 'Подключение к Control Center…';

  @override
  String get connectingDetail =>
      'Устанавливается защищённое прямое соединение.';

  @override
  String get identityChangedTitle => 'Идентичность сервера изменилась';

  @override
  String get identityChangedBody =>
      'Этот сервер больше не совпадает с идентичностью, сохранённой при сопряжении. Возможно, сервер переустановили — или соединение перехватывают. В целях безопасности устройство не подключится. Удалите сопряжение и отсканируйте новый QR-код в Control Center.';

  @override
  String get removePairing => 'Удалить сопряжение';

  @override
  String get couldntConnect => 'Не удалось подключиться';

  @override
  String get pendingPairingTitle => 'Подключиться к этому серверу?';

  @override
  String get pendingPairingBody =>
      'По ссылке Control Center предлагает сопряжение с этим сервером. Продолжайте, только если вы сами это начали.';

  @override
  String get connect => 'Подключить';

  @override
  String get failureNotPaired =>
      'Нет сопряжения — отсканируйте QR-код в Control Center';

  @override
  String get failureUnreachable =>
      'Сервер недоступен ни по одному пути — проверьте, что он запущен, или используйте ту же сеть';

  @override
  String get failureIdentityChanged =>
      'Идентичность сервера изменилась — если его переустановили, сопрягите устройство заново';

  @override
  String get failureAuthRejected =>
      'Сервер отклонил это устройство — сопрягите его заново из Control Center';

  @override
  String get failureUnknown =>
      'Не удалось подключиться — нажмите, чтобы повторить';

  @override
  String get statusConnected => 'Подключено';

  @override
  String get statusConnecting => 'Подключение';

  @override
  String get statusOffline => 'Офлайн';

  @override
  String get statusIdentityMismatch => 'Идентичность не совпадает';

  @override
  String get statusNotPaired => 'Нет сопряжения';

  @override
  String get statusConfirmPairing => 'Подтвердите сопряжение';

  @override
  String get connectionFailed => 'Ошибка подключения';

  @override
  String get identityMismatchBanner =>
      'Идентичность сервера изменилась — подключение остановлено. Сопрягите устройство заново, чтобы продолжить.';

  @override
  String get tabInbox => 'Входящие';

  @override
  String get tabTickets => 'Тикеты';

  @override
  String get tabChat => 'Чат';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'Календарь';

  @override
  String get tabNews => 'Новости';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count в ожидании';
  }

  @override
  String get updateAvailable => 'Доступна новая версия Control Center';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get language => 'Язык';

  @override
  String get device => 'Устройство';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get languageSystem => 'Системный';

  @override
  String get disconnectTapAgain =>
      'Нажмите ещё раз, чтобы отключить это устройство от Control Center';

  @override
  String get disconnectDevice => 'Отключить это устройство';

  @override
  String get disconnect => 'Отключить';

  @override
  String get chooseWorkspace => 'Выбрать рабочую область';

  @override
  String get workspaces => 'Рабочие пространства';

  @override
  String get workspacesLoadFailed => 'Не удалось загрузить рабочие области';

  @override
  String get noWorkspacesYet => 'Пока нет рабочих областей';

  @override
  String selectWorkspace(String name) {
    return 'Выбрать $name';
  }

  @override
  String get inboxLoadFailed => 'Не удалось загрузить входящие';

  @override
  String get allCaughtUp => 'Вы всё просмотрели';

  @override
  String get inboxNoForgeAccount =>
      'На сервере не подключён аккаунт forge, поэтому pull request пока нельзя отнести к вам.';

  @override
  String get inboxNothingWaiting =>
      'Ничего не заблокировано, и нет pull request, ожидающих вас.';

  @override
  String get blocked => 'Заблокирован';

  @override
  String get sectionNeedsYourReview => 'Нужно ваше ревью';

  @override
  String get sectionReturnedToYou => 'Вернули вам';

  @override
  String get sectionApprovedAndReady => 'Одобрено и готово';

  @override
  String get sectionYourDrafts => 'Ваши черновики';

  @override
  String get sectionWaitingForReviewers => 'Ожидают ревьюеров';

  @override
  String get sectionMergingAndMerged => 'В слиянии и недавно слитые';

  @override
  String get sectionWaitingForAuthor => 'Ожидают автора';

  @override
  String waitingAgo(String ago) {
    return 'ожидает $ago';
  }

  @override
  String get openConversation => 'Открыть переписку';

  @override
  String get calendarLoadFailed => 'Не удалось загрузить календарь';

  @override
  String get nothingScheduled => 'Ничего не запланировано';

  @override
  String get calendarEmptyDescription =>
      'Здесь появятся события из подключённых календарей.';

  @override
  String get agenda => 'Расписание';

  @override
  String get syncCalendarsNow => 'Синхронизировать календари';

  @override
  String get event => 'Событие';

  @override
  String get eventNotFound => 'Событие не найдено';

  @override
  String get eventNotFoundDescription =>
      'Возможно, оно вне окна расписания или удалено в источнике.';

  @override
  String get joinMeeting => 'Присоединиться к встрече';

  @override
  String get join => 'Войти';

  @override
  String attendeesCount(int count) {
    return 'Участники ($count)';
  }

  @override
  String get details => 'Подробности';

  @override
  String get allDay => 'Весь день';

  @override
  String get happeningNow => 'Идёт сейчас';

  @override
  String inDuration(String duration) {
    return 'Через $duration';
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
  String get attendeeAccepted => 'принято';

  @override
  String get attendeeDeclined => 'отклонено';

  @override
  String get attendeeMaybe => 'возможно';

  @override
  String get attendeeNoReply => 'нет ответа';

  @override
  String get organizer => 'организатор';

  @override
  String get calendarNoAccounts =>
      'Для этой рабочей области не подключён календарь. Подключите его в приложении для компьютера — вход сохранит токен на сервере.';

  @override
  String get calendarReauthNeeded =>
      'Нужно заново подключить аккаунт календаря — данные ниже могут быть устаревшими. Сделайте это в приложении для компьютера.';

  @override
  String get spacesLoadFailed => 'Не удалось загрузить пространства';

  @override
  String get noSpaces => 'Нет пространств';

  @override
  String get spacesEmptyDescription =>
      'Здесь появятся пространства этой рабочей области.';

  @override
  String get newSpaceFolder => 'Новая папка';

  @override
  String get folderName => 'Название папки';

  @override
  String get renameSpaceFolder => 'Переименовать папку';

  @override
  String get deleteSpaceFolder => 'Удалить папку';

  @override
  String get moveSpaceToFolder => 'Переместить в папку';

  @override
  String get removeSpaceFromFolder => 'Убрать из папки';

  @override
  String get spaceFolderActions => 'Действия с папкой';

  @override
  String get deleteFolderWithSpacesWarning =>
      'При безвозвратном удалении пространств их сообщения и рабочие деревья удаляются для всех. Это действие нельзя отменить.';

  @override
  String get deleteSpacesInFolder =>
      'Безвозвратно удалить пространства в этой папке';

  @override
  String get deleteFolderAndSpaces => 'Удалить папку и пространства';

  @override
  String get keepSpacesInFolder =>
      'В противном случае пространства останутся вне папок.';

  @override
  String get create => 'Создать';

  @override
  String get otherSpaces => 'Другие пространства';

  @override
  String get folderUpdateFailed => 'Не удалось обновить папки';

  @override
  String get thread => 'Переписка';

  @override
  String get agentWorking => 'Агент работает';

  @override
  String get messagesLoadFailed => 'Не удалось загрузить сообщения';

  @override
  String get noMessagesYet => 'Пока нет сообщений';

  @override
  String get noMessagesDescription =>
      'Отправьте сообщение, чтобы начать переписку.';

  @override
  String get agentResponding => 'Агент отвечает';

  @override
  String get agentFinished => 'Агент завершил работу';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names слишком большие, чтобы отправить отсюда.',
      one: '$names слишком большой, чтобы отправить отсюда.',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names слишком большие, чтобы отправить через релей отсюда.',
      one: '$names слишком большой, чтобы отправить через релей отсюда.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'Не удалось загрузить вложение. Попробуйте снова.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count вложений не удалось загрузить — их не отправили.',
      one: '1 вложение не удалось загрузить — его не отправили.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Коллега';

  @override
  String get agent => 'Агент';

  @override
  String get attachFile => 'Прикрепить файл';

  @override
  String get messageHint => 'Сообщение';

  @override
  String removeAttachment(String name) {
    return 'Удалить $name';
  }

  @override
  String get articlesLoadFailed => 'Не удалось загрузить статьи';

  @override
  String get noArticles => 'Нет статей';

  @override
  String get articlesEmptyDescription =>
      'Новые статьи появятся здесь по мере обновления лент.';

  @override
  String get unread => 'Непрочитанные';

  @override
  String get allFeeds => 'Все ленты';

  @override
  String get save => 'Сохранить';

  @override
  String get unsave => 'Убрать из сохранённых';

  @override
  String get readFullArticle => 'Читать статью целиком';

  @override
  String get ticketsLoadFailed => 'Не удалось загрузить тикеты';

  @override
  String get noTickets => 'Нет тикетов';

  @override
  String get ticketsEmptyDescription =>
      'Тикеты этого рабочего пространства появятся здесь.';

  @override
  String get all => 'Все';

  @override
  String get ticket => 'Тикет';

  @override
  String get ticketLoadFailed => 'Не удалось загрузить тикет';

  @override
  String assignedTo(String name) {
    return 'Назначен: $name';
  }

  @override
  String get openInBrowser => 'Открыть в браузере';

  @override
  String get status => 'Статус';

  @override
  String get assign => 'Назначить';

  @override
  String get reassign => 'Переназначить';

  @override
  String get noAgents => 'Нет агентов';

  @override
  String get noAgentsDescription =>
      'Назначьте агента из этого рабочего пространства.';

  @override
  String get statusOpen => 'Открыт';

  @override
  String get statusInProgress => 'В работе';

  @override
  String get statusBlocked => 'Заблокирован';

  @override
  String get statusInReview => 'На проверке';

  @override
  String get statusDone => 'Готово';

  @override
  String get statusBacklog => 'Бэклог';

  @override
  String get lensNeedsMe => 'Нужен я';

  @override
  String get lensMine => 'Мои';

  @override
  String get prsLoadFailed => 'Не удалось загрузить pull request’ы';

  @override
  String get noOpenPullRequests => 'Нет открытых pull request';

  @override
  String get nothingWaitingOnReview => 'Нет запросов на вашу проверку';

  @override
  String get noOwnOpenPullRequests => 'У вас нет открытых pull request’ов';

  @override
  String get nothingBlocked => 'Ничего не заблокировано';

  @override
  String get prsEmptyDescription =>
      'Здесь появятся pull request’ы репозиториев этого рабочего пространства.';

  @override
  String get refreshPullRequests => 'Обновить pull request’ы';

  @override
  String get noForgeConnected =>
      'На сервере не подключена forge, поэтому pull request’ы получить нельзя. Подключите её в приложении для компьютера.';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count репозиториев не удалось прочитать.',
      one: '1 репозиторий не удалось прочитать.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'Не читаются: $names';
  }

  @override
  String get installationSuspendedTitle =>
      'Установка GitHub App приостановлена';

  @override
  String installationSuspendedBody(String names) {
    return 'Показаны последние известные данные для $names. Возобновите установку на GitHub или подключите токен с доступом.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'Установка GitHub App приостановлена. Показаны последние известные данные для $names. Возобновите установку на GitHub или подключите токен с доступом.';
  }

  @override
  String get draft => 'Черновик';

  @override
  String get merged => 'Слито';

  @override
  String get closed => 'Закрыто';

  @override
  String get open => 'Открыт';

  @override
  String get approved => 'Одобрено';

  @override
  String get changesRequested => 'Запрошены изменения';

  @override
  String get reviewRequired => 'Нужна проверка';

  @override
  String get checksPassing => 'Проверки пройдены';

  @override
  String get checksFailing => 'Проверки не проходят';

  @override
  String get checksRunning => 'Проверки выполняются';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'Не удалось загрузить этот pull request';

  @override
  String get openOnForge => 'Открыть на forge';

  @override
  String get requestChangesNeedsComment =>
      'Добавьте комментарий, что нужно изменить.';

  @override
  String get conversation => 'Обсуждение';

  @override
  String get files => 'Файлы';

  @override
  String get checks => 'Проверки';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файлов',
      one: '1 файл',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count коммитов',
      one: '1 коммит',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => 'Конфликты';

  @override
  String get reviewers => 'Ревьюеры';

  @override
  String get noDescriptionNoComments => 'Пока нет описания и комментариев.';

  @override
  String get noChangedFiles => 'Нет изменённых файлов.';

  @override
  String get noChecksReported => 'Для head-коммита нет отчётов о проверках.';

  @override
  String get reviewCommentHint => 'Оставьте комментарий к проверке…';

  @override
  String get comment => 'Комментировать';

  @override
  String get commentPosted => 'Комментарий отправлен';

  @override
  String get request => 'Запросить';

  @override
  String get squashAndMerge => 'Объединить и слить';

  @override
  String noActionsAvailable(String status) {
    return '$status — нет доступных действий.';
  }

  @override
  String get reviewApproved => 'одобрил';

  @override
  String get reviewRequestedChanges => 'запросил изменения';

  @override
  String get reviewCommented => 'оставил отзыв';

  @override
  String get reviewPending => 'ожидает';

  @override
  String get unknownAuthor => 'неизвестно';

  @override
  String hideDiffFor(String file) {
    return 'Скрыть diff для $file';
  }

  @override
  String showDiffFor(String file) {
    return 'Показать diff для $file';
  }

  @override
  String get checkRunning => 'выполняется';

  @override
  String get checkPassed => 'успешно';

  @override
  String get checkFailed => 'ошибка';

  @override
  String get checkCancelled => 'отменено';

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
      'Текстового diff для этого файла нет — он бинарный или слишком большой, чтобы forge его вернул.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Показать оставшиеся $count строк',
      one: 'Показать оставшуюся строку',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count неизменённых строк',
      one: '1 неизменённая строка',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'К последнему';

  @override
  String get streaming => 'Стриминг';

  @override
  String get working => 'Работает';

  @override
  String get input => 'Вход';

  @override
  String get output => 'Выход';

  @override
  String get now => 'сейчас';

  @override
  String agoMinutes(int count) {
    return '$countм';
  }

  @override
  String agoHours(int count) {
    return '$countч';
  }

  @override
  String agoDays(int count) {
    return '$countд';
  }

  @override
  String get today => 'Сегодня';

  @override
  String get tomorrow => 'Завтра';

  @override
  String get yesterday => 'Вчера';

  @override
  String durationMinutes(int count) {
    return '$countм';
  }

  @override
  String durationHours(int count) {
    return '$countч';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hoursч $minutesм';
  }

  @override
  String get mobileConversations => 'Разговоры';

  @override
  String get mobileNewConversation => 'Новый разговор';

  @override
  String get mobileConversationName => 'Название разговора';

  @override
  String get mobileRename => 'Переименовать';

  @override
  String get mobileManageSpace => 'Управление пространством';

  @override
  String get mobileArchived => 'В архиве';

  @override
  String get mobileSearchMessages =>
      'Поиск по всем сообщениям в этом пространстве';

  @override
  String get mobileSearch => 'Поиск';

  @override
  String get mobileNoResults => 'Ничего не найдено';

  @override
  String get mobileReopen => 'Открыть снова';

  @override
  String get mobileArchive => 'Архивировать';

  @override
  String get mobileProgress => 'Прогресс и контекст';

  @override
  String get mobileReadFailed => 'Не удалось отметить разговор как прочитанный';

  @override
  String get mobileSendFailed => 'Сообщение не отправлено. Черновик сохранён.';

  @override
  String get mobileActionFailed => 'Не удалось выполнить действие';

  @override
  String get mobileRemove => 'Удалить';

  @override
  String get mobileLinkedMessage => 'Связанное сообщение';

  @override
  String get mobileOlderMessages => 'Более ранние сообщения';

  @override
  String get mobileMessageActions => 'Действия с сообщением';

  @override
  String get mobileOpenThread => 'Открыть ветку';

  @override
  String get mobileCopyLink => 'Копировать ссылку';

  @override
  String get mobileStopRun => 'Остановить запуск';

  @override
  String get mobileStopRunConfirm =>
      'Остановить запуск агента? Уже выполненная работа сохранится.';

  @override
  String get mobileControlUnsupported =>
      'Этот запуск завершён или не поддерживает это действие.';

  @override
  String get mobilePauseRequested => 'Пауза запрошена после следующего шага';

  @override
  String get mobileResumed => 'Запуск возобновлён';

  @override
  String get mobileStopRequested => 'Остановка запрошена';

  @override
  String get mobileQueuedMessages => 'Сообщения в очереди';

  @override
  String get mobilePauseRun => 'Пауза после следующего шага';

  @override
  String get mobileResumeRun => 'Продолжить';

  @override
  String get mobileEditQueued => 'Изменить сообщение в очереди';

  @override
  String get mobileSteerNow => 'Изменить ход работы сейчас';

  @override
  String get mobileMoveUp => 'Вверх';

  @override
  String get mobileMoveDown => 'Вниз';

  @override
  String get mobileQueueChanged =>
      'Очередь изменилась или этот запуск не поддерживает изменение хода работы на лету. Обновите страницу и повторите попытку.';

  @override
  String get mobileActivity => 'Активность';

  @override
  String get mobilePermissions => 'Разрешения и аудит';

  @override
  String get mobilePlans => 'Планы';

  @override
  String get mobileGoals => 'Цели под контролем';

  @override
  String get mobileCredentials => 'Подключения и учётные данные';

  @override
  String get mobileWorkspaceUnavailable =>
      'Это рабочее пространство недоступно или у вас больше нет к нему доступа.';

  @override
  String get mobilePrReviewThreads => 'Ветки обсуждения';

  @override
  String get mobilePrThreadsLoadFailed =>
      'Не удалось загрузить ветки обсуждения';

  @override
  String get mobilePrNoReviewThreads => 'Пока нет веток обсуждения строк кода';

  @override
  String get mobilePrCommentPermissionDenied =>
      'У вас нет права комментировать этот репозиторий.';

  @override
  String get mobilePrPermissionChecking =>
      'Проверяем права на комментирование…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'Не удалось проверить права на комментирование. Повторите попытку.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side, строка $line';
  }

  @override
  String get mobilePrOriginalSide => 'Исходный';

  @override
  String get mobilePrUpdatedSide => 'Обновлён';

  @override
  String get mobilePrThreadResolved => 'Разрешено';

  @override
  String get mobilePrReplyHint => 'Напишите ответ…';

  @override
  String get mobilePrCommentRequired =>
      'Напишите комментарий перед публикацией.';

  @override
  String get mobilePrReply => 'Ответить';

  @override
  String get mobilePrReopenThread => 'Открыть ветку снова';

  @override
  String get mobilePrResolveThread => 'Решить ветку';

  @override
  String get mobilePrResolvePermissionDenied =>
      'Только автор pull request или пользователь с правом записи может закрыть эту ветку.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'Комментировать $side, строку $line';
  }

  @override
  String get mobilePrInlineCommentHint => 'Напишите комментарий к строке…';

  @override
  String get mobilePrPostInlineComment => 'Опубликовать комментарий';

  @override
  String get mobilePrCommentUnavailable =>
      'Комментарии к строкам недоступны для этого pull request.';

  @override
  String get mobilePrPatchUnavailable =>
      'Платформа Git не предоставила текстовый патч для этого файла.';

  @override
  String get mobilePrNoPatchForFile => 'Патч для этого файла недоступен.';

  @override
  String get mobileTicketNew => 'Новый тикет';

  @override
  String get mobileTicketCreate => 'Создать тикет';

  @override
  String get mobileTicketEdit => 'Изменить тикет';

  @override
  String get mobileTicketTitle => 'Название';

  @override
  String get mobileTicketTitleRequired =>
      'Введите название, чтобы сохранить тикет.';

  @override
  String get mobileTicketDescription => 'Описание';

  @override
  String get mobileTicketMarkdownHint => 'Добавьте подробности в Markdown';

  @override
  String get mobileTicketPriority => 'Приоритет';

  @override
  String get mobileTicketPriorityNone => 'Без приоритета';

  @override
  String get mobileTicketPriorityUrgent => 'Срочный';

  @override
  String get mobileTicketPriorityHigh => 'Высокий';

  @override
  String get mobileTicketPriorityMedium => 'Средний';

  @override
  String get mobileTicketPriorityLow => 'Низкий';

  @override
  String get mobileTicketLabels => 'Метки';

  @override
  String get mobileTicketLabelsHint => 'По одной метке на строку';

  @override
  String get mobileTicketLabelsHelp =>
      'Введите каждую метку на отдельной строке.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'Создан в $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'Не назначен';

  @override
  String get mobileTicketAssignedFilter => 'Назначенные';

  @override
  String get mobileTicketAgentsLoadFailed => 'Не удалось загрузить агентов';

  @override
  String get mobileTicketSearch => 'Поиск тикетов';

  @override
  String get mobileTicketSearchHint =>
      'Название, ключ, описание, метка или исполнитель';

  @override
  String get mobileTicketClearSearch => 'Очистить поиск тикетов';

  @override
  String get mobileTicketNoMatches => 'Подходящих тикетов нет';

  @override
  String get mobileTicketAdjustFilters =>
      'Попробуйте другой запрос или измените фильтры.';

  @override
  String get mobileTicketClearFilters => 'Сбросить фильтры';

  @override
  String get mobileTicketNotFound => 'Тикет не найден';

  @override
  String get mobileTicketNotFoundDescription =>
      'Возможно, тикет удалён или перенесён из этого рабочего пространства.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'Рабочее пространство изменилось. Вернитесь в текущее пространство перед сохранением.';

  @override
  String get mobileTicketOpenLinkedSpace => 'Открыть связанное пространство';

  @override
  String get mobileTicketReadOnly =>
      'Для изменения тикетов нужно быть участником рабочего пространства.';

  @override
  String get permissionTitle => 'Разрешения';

  @override
  String get permissionWorkspaceFailed =>
      'Не удалось загрузить рабочее пространство';

  @override
  String get permissionNoWorkspace =>
      'Выберите рабочее пространство для просмотра разрешений.';

  @override
  String get permissionLoading => 'Загружаем разрешения…';

  @override
  String get permissionScopeDescription =>
      'Посмотрите, как принимается решение для каждого действия в этой области. Агенты и пространства могут наследовать правила рабочего пространства.';

  @override
  String get permissionScope => 'Область действия политики';

  @override
  String get permissionWorkspaceScope => 'Рабочее пространство';

  @override
  String get permissionAgentScope => 'Агент';

  @override
  String get permissionSpaceScope => 'Пространство';

  @override
  String get permissionAgentContext => 'Агент, действующий в этом пространстве';

  @override
  String get permissionNoAgentContext => 'Агент не выбран';

  @override
  String get permissionTargetsFailed =>
      'Не удалось загрузить объекты области действия';

  @override
  String get permissionNoTargets =>
      'В этой области действия нет доступных объектов.';

  @override
  String get permissionRoleFailed =>
      'Не удалось подтвердить вашу роль в рабочем пространстве';

  @override
  String get permissionMemberRequired =>
      'Для просмотра правил политики нужно быть участником рабочего пространства.';

  @override
  String get permissionRulesFailed => 'Не удалось загрузить правила политики';

  @override
  String get permissionAuditAdminOnly =>
      'История авторизаций доступна только администраторам рабочего пространства.';

  @override
  String get permissionAllow => 'Разрешить';

  @override
  String get permissionAsk => 'Спросить сначала';

  @override
  String get permissionDeny => 'Запретить';

  @override
  String get permissionFileDelete => 'Удалять файлы';

  @override
  String get permissionFileWriteOutsideWorktree =>
      'Записывать вне рабочего дерева';

  @override
  String get permissionGitCommit => 'Создавать коммиты';

  @override
  String get permissionGitPush => 'Отправлять коммиты';

  @override
  String get permissionPrCreate => 'Создавать pull request';

  @override
  String get permissionPrPublish => 'Публиковать pull request';

  @override
  String get permissionVendorSyncWrite =>
      'Записывать синхронизацию с поставщиком';

  @override
  String get permissionNetworkEgress => 'Подключаться к сети';

  @override
  String get permissionSecretAccess => 'Получать доступ к секретам';

  @override
  String get permissionPackageInstall => 'Устанавливать пакеты';

  @override
  String get permissionProcessSpawn => 'Запускать процессы';

  @override
  String get permissionWorkspaceMutation => 'Изменять рабочее пространство';

  @override
  String get permissionEnclosureControl => 'Управлять изолированной средой';

  @override
  String get permissionChangeFailed => 'Не удалось изменить правило';

  @override
  String get permissionEffectiveDescription =>
      'Действует в этой области без аргументов действия. Условные разрешения ниже применяются только к подходящим запросам; окончательное решение принимает сервер.';

  @override
  String get permissionSpaceAgentNote =>
      'Агент не выбран. Правила для конкретного агента появятся после выбора выше.';

  @override
  String get permissionScopedGrants => 'Правила в этой области';

  @override
  String get permissionModePreset => 'Пресет режима';

  @override
  String get permissionBuiltInDefault => 'Встроенное по умолчанию';

  @override
  String get permissionRemembered => 'Сохранённое одобрение';

  @override
  String get permissionSource => 'Исходник';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · задано здесь';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · унаследовано';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'Истекает $date';
  }

  @override
  String get permissionSetHere => 'Задать правило здесь';

  @override
  String get permissionRevokeBeforeEdit =>
      'Отзовите правило для этой области или сохранённое правило, прежде чем задать общее правило для этого действия.';

  @override
  String get permissionConfirmRevoke => 'Подтвердить отзыв';

  @override
  String get permissionRevokeRule => 'Отозвать правило';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'Префикс команды: $prefix';
  }

  @override
  String get permissionNoExpiry => 'Без срока действия';

  @override
  String get permissionExpired => 'Истекло';

  @override
  String get permissionExplicitRule => 'Явное правило';

  @override
  String get permissionEnforcementAdvisory =>
      'Рекомендательный режим: правила «Спросить сначала» записываются без запроса подтверждения';

  @override
  String get permissionEnforcementSoft =>
      'Мягкое применение: для исключения требуется авторизация';

  @override
  String get permissionEnforcementHard =>
      'Строгое применение: исключения невозможны';

  @override
  String permissionPaths(String paths) {
    return 'Пути: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Ссылки Git: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'Хосты: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'Команды: $commands';
  }

  @override
  String permissionMaxCount(String count) {
    return 'Максимальное количество: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'Максимальная сумма в центах: $cents';
  }

  @override
  String get permissionAuditHeading => 'История авторизаций';

  @override
  String get permissionAuditDescription =>
      'Недавние решения, записанные сервером. Только администраторы могут просматривать журнал и проверять цепочку его хешей.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'от имени $user';
  }

  @override
  String get permissionPrompted => 'Запрошено подтверждение человека';

  @override
  String get permissionVerifyChain => 'Проверить цепочку аудита';

  @override
  String get permissionVerifyFailed => 'Не удалось проверить цепочку аудита';

  @override
  String permissionChainIntact(String count) {
    return 'Цепочка не нарушена · проверено записей: $count';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'Цепочка нарушена на записи $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty => 'Решения об авторизации пока не записаны.';

  @override
  String get permissionAuditFailed =>
      'Не удалось загрузить историю авторизаций';

  @override
  String get mobilePlansLoadFailed => 'Не удалось загрузить планы';

  @override
  String get mobilePlansEmpty => 'Планов пока нет';

  @override
  String get mobilePlansEmptyDescription =>
      'Планы, предложенные агентами, появятся здесь для проверки.';

  @override
  String get mobilePlanTitle => 'План';

  @override
  String get mobilePlanMissing =>
      'Этот план больше недоступен в рабочем пространстве.';

  @override
  String mobilePlanStepCount(int count) {
    return 'Шагов: $count';
  }

  @override
  String get mobilePlanDraft => 'Черновик';

  @override
  String get mobilePlanProposed => 'Ожидает проверки';

  @override
  String get mobilePlanApproved => 'Одобрен';

  @override
  String get mobilePlanRejected => 'Отклонено';

  @override
  String get mobilePlanSuperseded => 'Заменено';

  @override
  String get mobilePlanExecuting => 'Выполняется';

  @override
  String get mobilePlanSynthesizing => 'Синтез';

  @override
  String get mobilePlanCompleted => 'Завершён';

  @override
  String get mobilePlanFailed => 'Сбой';

  @override
  String get mobilePlanCancelled => 'Отменён';

  @override
  String mobilePlanRevision(String revision) {
    return 'Ревизия $revision';
  }

  @override
  String get mobilePlanSteps => 'Шаги';

  @override
  String get mobilePlanNoSteps =>
      'Для этого плана не предложено ни одного шага.';

  @override
  String get mobilePlanAssumptions => 'Уточнения';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'Зависит от $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'Предположительно до $cost';
  }

  @override
  String get mobilePlanSelect => 'Выбрать';

  @override
  String get mobilePlanSelected => 'Выбрано';

  @override
  String get mobilePlanEstimate => 'Оценить стоимость';

  @override
  String get mobilePlanEstimateRequired =>
      'Оцените план перед одобрением выполнения.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'Оценка стоимости: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'недоступно';

  @override
  String get mobilePlanNoHardCap => 'без жёсткого лимита';

  @override
  String get mobilePlanExceedsBudget =>
      'Оценка превышает заданный бюджет. Проверьте её перед одобрением.';

  @override
  String get mobilePlanPartialEstimate =>
      'Эта оценка относится ко всему плану; выбранные шаги могут стоить дешевле.';

  @override
  String get mobilePlanConfirmAll => 'Запустить весь план?';

  @override
  String get mobilePlanConfirmSelected => 'Запустить выбранные шаги?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'После одобрения начнётся выполнение, за которое может взиматься плата. Верхняя оценка стоимости: $cost. Лимит бюджета: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'Одобрить всё и запустить';

  @override
  String get mobilePlanApproveSelected => 'Одобрить выбранное и запустить';

  @override
  String get mobilePlanWiden => 'Одобрить дополнительные шаги';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'Запустить ещё $count шагов? Они могут повлечь расходы. Текущий лимит затрат на выполнение: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'План изменился во время проверки. Откройте последнюю редакцию и оцените её заново.';

  @override
  String get mobilePlanReject => 'Отклонить план';

  @override
  String get mobilePlanRejectConfirm =>
      'Отклонить этот план? Он не будет выполнен.';

  @override
  String get mobilePlanStop => 'Остановить выполнение';

  @override
  String get mobilePlanStopConfirm =>
      'Остановить выполнение плана? Уже выполненная работа не будет отменена.';

  @override
  String mobilePlanRunId(String runId) {
    return 'Запуск выполнения: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'Одобрение принято. Ожидаем запись о выполнении…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return 'Выполнено шагов: $completed из $total';
  }

  @override
  String get mobilePlanOpenConversation => 'Открыть разговор';

  @override
  String get mobileGoalsTitle => 'Цели под контролем';

  @override
  String get mobileGoalsLoadFailed => 'Не удалось загрузить цели под контролем';

  @override
  String get mobileGoalsEmpty => 'Целей под контролем пока нет';

  @override
  String get mobileGoalsEmptyDescription =>
      'Задайте цель в пространстве или отправьте /goal в разговоре.';

  @override
  String get mobileGoalMissing =>
      'Эта цель больше недоступна в рабочем пространстве.';

  @override
  String get mobileGoalActive => 'Активен';

  @override
  String get mobileGoalPaused => 'Приостановлена';

  @override
  String get mobileGoalCompleted => 'Завершён';

  @override
  String get mobileGoalFailed => 'Сбой';

  @override
  String get mobileGoalCancelled => 'Отменён';

  @override
  String get mobileGoalBudgetExhausted => 'Бюджет исчерпан';

  @override
  String get mobileGoalGoal => 'Цель';

  @override
  String get mobileGoalLoop => 'Цикл';

  @override
  String mobileGoalKind(String kind) {
    return 'Тип: $kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return 'Запусков: $count';
  }

  @override
  String get mobileGoalNoRunLimit => 'без ограничений';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return 'Запуски: $runs / $maxRuns · Потрачено: $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return 'Срок: $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return 'Неудачных запусков подряд: $count';
  }

  @override
  String get mobileGoalSummary => 'Итоги выполнения';

  @override
  String get mobileGoalFailedDescription =>
      'Контроллер остановился после повторных неудачных запусков. Подробности — в разговоре.';

  @override
  String get mobileGoalBudgetWall =>
      'Срок или лимит запусков исчерпан. Повышение лимита затрат не позволит возобновить эту цель.';

  @override
  String get mobileGoalPause => 'Приостановить цель';

  @override
  String get mobileGoalResume => 'Возобновить цель';

  @override
  String get mobileGoalStop => 'Отменить цель';

  @override
  String get mobileGoalStopConfirm =>
      'Отменить эту цель без возможности возобновления?';

  @override
  String get mobileGoalRaiseBudget => 'Увеличить бюджет и возобновить';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'Увеличить бюджет до $amount и возобновить';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'Увеличить лимит затрат на эту цель с $oldCap до $newCap и возобновить расходы?';
  }

  @override
  String get mobileGoalOpenConversation => 'Открыть разговор о цели';

  @override
  String get mobileGoalCreate => 'Задать цель под контролем';

  @override
  String get mobileGoalChooseSpace => 'Запустить в пространстве';

  @override
  String get mobileGoalNoSpaces => 'Создайте пространство перед запуском цели.';

  @override
  String get mobileGoalChooseAgent => 'Запустить с агентом';

  @override
  String get mobileGoalNoAgents =>
      'Добавьте активного агента перед запуском цели.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return 'Выбран: $name';
  }

  @override
  String get mobileGoalObjectiveHint =>
      'Какого результата должен достичь агент?';

  @override
  String get mobileGoalBudgetUsd => 'Лимит затрат (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'Выберите пространство и агента, укажите цель и положительный лимит затрат в USD.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'Запустить цель под контролем с максимальными затратами $cap? Агент может начать сразу.';
  }

  @override
  String get mobileGoalUnavailable =>
      'Соединение с сервером ещё не готово. Повторите попытку после подключения.';

  @override
  String get mobileGoalConversationMissing =>
      'Выбранный разговор больше недоступен в рабочем пространстве.';

  @override
  String get mobileGoalCreateSent =>
      'Цель запущена. Состояние контроллера появится в этом списке.';

  @override
  String get mobileGoalStartRefused =>
      'Запуск цели не начался. Причину отказа контроллера можно узнать в разговоре.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return 'Выбрано пространство: $name';
  }

  @override
  String get requestUnavailable =>
      'Этот запрос больше недоступен в активном рабочем пространстве.';

  @override
  String get requestAlreadyResolved => 'Этот запрос уже обработан.';

  @override
  String get inboxCredentialsBlocked => 'Учётные данные блокируют запуски';

  @override
  String get inboxSyncFailures => 'Сбои синхронизации с поставщиками';

  @override
  String get inboxConfigureCredentials => 'Настроить учётные данные';

  @override
  String get openTicket => 'Открыть тикет';

  @override
  String get activityTitle => 'Активность';

  @override
  String get activityClearAll => 'Очистить активность';

  @override
  String get activityClearConfirm =>
      'Вся активность, записанная для вас до сих пор, будет скрыта на всех устройствах. Новая активность продолжит появляться.';

  @override
  String get activityMarkAllRead => 'Отметить всё как прочитанное';

  @override
  String get activityMarkAllConfirm =>
      'Отметить всю активность в этом рабочем пространстве как прочитанную на всех ваших устройствах?';

  @override
  String get activityMarkRead => 'Отметить как прочитанное';

  @override
  String get activityMarkUnread => 'Отметить как непрочитанное';

  @override
  String get activityDismiss => 'Закрыть';

  @override
  String get activityResolved => 'Разрешено';

  @override
  String get activityOpen => 'Открыт';

  @override
  String get activityEmpty => 'Пока нет активности';

  @override
  String get activityLoadFailed => 'Не удалось загрузить активность';

  @override
  String get activityAgentWaiting => 'Агент ожидает ответа';

  @override
  String get activityAgentBlocked => 'Действие агента заблокировано';

  @override
  String get activityMessage => 'Новое сообщение';

  @override
  String get activityPullRequest => 'Обновление pull request';

  @override
  String get activityTicket => 'Обновление тикета';

  @override
  String get activityMeeting => 'Обновление встречи';

  @override
  String get activityCalendar => 'Подключение календаря';

  @override
  String get activityRig => 'Обновление изолированной среды';

  @override
  String get activityEvent => 'Обновить';

  @override
  String get activityPrReady => 'Pull request готов к слиянию';

  @override
  String get activityPrBlocked => 'Слияние pull request заблокировано';

  @override
  String get activityPrApproved => 'Pull request одобрен';

  @override
  String get activityPrChanges => 'Запрошены изменения';

  @override
  String get activityPrChecksFailed => 'Проверки pull request не пройдены';

  @override
  String get activityPrChecksRecovered =>
      'Проверки pull request снова пройдены';

  @override
  String get activityPrComment => 'Комментарий к pull request';

  @override
  String get activityPrPublished => 'Pull request опубликован';

  @override
  String get activityPrMerged => 'Pull request слит';

  @override
  String get activityPrMentioned => 'Упоминание в pull request';

  @override
  String get activityPrReviewRequested => 'Запрошено ревью';

  @override
  String get activityPrReviewStale => 'Нужно обновить ревью';

  @override
  String get activityTicketAssigned => 'Тикет назначен';

  @override
  String get activityTicketChanged => 'Статус тикета изменён';

  @override
  String get activityMeetingSoon => 'Встреча скоро начнётся';

  @override
  String get activityCalendarExpired => 'Истёк срок подключения календаря';

  @override
  String get activityRigControl => 'Управление изолированной средой изменилось';

  @override
  String get activityRigClosed => 'Изолированная среда остановлена';

  @override
  String get mobileSpacesSearch => 'Поиск пространств';

  @override
  String get mobileSpacesArchived => 'В архиве';

  @override
  String get mobileSpacesActive => 'Активен';

  @override
  String get mobileSpacesNew => 'Новое пространство';

  @override
  String get mobileSpacesManage => 'Управление пространством';

  @override
  String get mobileSpacesName => 'Название пространства';

  @override
  String get mobileSpacesAgents => 'Агенты';

  @override
  String get mobileSpacesMembers => 'Люди';

  @override
  String get mobileSpacesRepos => 'Репозитории';

  @override
  String get mobileSpacesAllRepos => 'Все связанные репозитории';

  @override
  String get mobileSpacesNoRepos => 'Нет репозиториев';

  @override
  String get mobileSpacesBaseBranch => 'Базовая ветка (необязательно)';

  @override
  String get mobileSpacesDefaultBranch => 'Ветка по умолчанию';

  @override
  String get mobileSpacesMode => 'Режим';

  @override
  String get mobileSpacesModeChat => 'Чат';

  @override
  String get mobileSpacesModeReview => 'Ревью (только чтение)';

  @override
  String get mobileSpacesModePlan => 'Планирование (только чтение)';

  @override
  String get mobileSpacesModeOrchestrate => 'Оркестрировать';

  @override
  String get mobileSpacesAutonomy => 'Переопределение автономии';

  @override
  String get mobileSpacesAutonomyInherited => 'Унаследовано';

  @override
  String get mobileSpacesAutonomyPropose => 'Только предлагать';

  @override
  String get mobileSpacesAutonomyApproval => 'Действовать с одобрения';

  @override
  String get mobileSpacesAutonomyFreely => 'Действовать свободно';

  @override
  String get mobileSpacesAutonomyNotice =>
      'Переопределение не отменяет запросы подтверждения и запреты политики действий. Изменять его могут только администраторы рабочего пространства.';

  @override
  String get mobileSpacesArchive => 'Архивировать пространство';

  @override
  String get mobileSpacesReopen => 'Открыть пространство снова';

  @override
  String get mobileSpacesSave => 'Сохранить изменения';

  @override
  String get mobileSpacesCreate => 'Создать пространство';

  @override
  String get mobileSpacesOperationFailed => 'Не удалось обновить пространство';

  @override
  String get mobileSpacesMissing =>
      'Пространство не найдено в рабочем пространстве';

  @override
  String get mobileSpacesEmptyName => 'Введите название пространства';

  @override
  String get mobileSpacesNoMatches => 'Подходящих пространств нет';

  @override
  String get mobileSpacesUnread => 'Непрочитанный ответ агента';

  @override
  String get mobileSpacesNeedsInput => 'Нужен ваш ответ';

  @override
  String get mobileSpacesRunning => 'Агент работает';

  @override
  String get mobileSpacesNoAgents => 'В рабочем пространстве нет агентов';

  @override
  String get mobileSpacesNoMembers =>
      'В рабочем пространстве нет других участников';

  @override
  String get mobileSpacesRepoError => 'Не удалось загрузить репозитории';

  @override
  String get mobileSpacesRetry => 'Повторить';

  @override
  String get mobileSpacesBranchUnavailable =>
      'При создании пространства выберите или укажите базовую ветку. У существующих пространств её нельзя изменить.';

  @override
  String get mobileSpacesArchivedEmpty => 'Нет архивных пространств';

  @override
  String get mobileSpacesAllRepoWarning =>
      'Новые репозитории, связанные с рабочим пространством, тоже будут включены сюда.';

  @override
  String get mobileSpacesCreatedRetry =>
      'Пространство создано. Повторите добавление людей или откройте страницу управления пространством.';

  @override
  String get progressTitle => 'Прогресс';

  @override
  String get progressConversation => 'Диалог';

  @override
  String get progressLoadFailed => 'Не удалось загрузить прогресс';

  @override
  String get progressUnavailable => 'Разговор недоступен';

  @override
  String get progressUnavailableDescription =>
      'Этот разговор не относится к активному рабочему пространству и пространству. Вернитесь в его пространство, чтобы продолжить.';

  @override
  String get progressSaveFailed => 'Не удалось обновить прогресс';

  @override
  String get progressGoal => 'Цель';

  @override
  String get progressNoGoal => 'Рабочая цель не задана';

  @override
  String get progressSetGoal => 'Задать цель';

  @override
  String get progressEditGoal => 'Изменить цель';

  @override
  String get progressClearGoal => 'Очистить цель';

  @override
  String get progressGoalRequired => 'Укажите цель перед сохранением.';

  @override
  String get progressTodos => 'Задачи';

  @override
  String get progressNoTodos => 'Задач пока нет';

  @override
  String get progressNewTodo => 'Новая задача';

  @override
  String get progressAddTodo => 'Добавить задачу';

  @override
  String get progressEditTodo => 'Изменить задачу';

  @override
  String get progressTodoRequired => 'Укажите задачу перед сохранением.';

  @override
  String get progressTodoNoLongerExists =>
      'Эта задача была удалена. Обновите список и повторите попытку.';

  @override
  String get progressWorkspaceChanged =>
      'Активное рабочее пространство изменилось. Вернитесь к этому разговору и повторите попытку.';

  @override
  String progressRemoveTodo(String name) {
    return 'Удалить задачу $name';
  }

  @override
  String get progressPending => 'Ожидание';

  @override
  String get progressInProgress => 'В работе';

  @override
  String get progressCompleted => 'Завершён';

  @override
  String get progressMoveUp => 'Переместить задачу вверх';

  @override
  String get progressMoveDown => 'Переместить задачу вниз';

  @override
  String get progressRunTree => 'Запуски агентов';

  @override
  String get progressNoRuns => 'В этом разговоре ещё нет запусков';

  @override
  String get progressRunning => 'Выполняется';

  @override
  String get progressFailed => 'Сбой';

  @override
  String get progressUnknown => 'Неизвестно';

  @override
  String get progressHealthy => 'Активен';

  @override
  String get progressBlocked => 'Заблокирован';

  @override
  String get progressLooping => 'Повторяется по кругу';

  @override
  String get progressStalled => 'Не продвигается';

  @override
  String get progressDead => 'Неожиданно остановлен';

  @override
  String get progressQuiet => 'Вывода пока нет';

  @override
  String get progressCostReported => 'Стоимость по данным поставщика';

  @override
  String get progressCostNotional =>
      'Условная стоимость подписки по прайс-листу, не счёт к оплате';

  @override
  String get progressCostMixed => 'Разные источники данных о стоимости';

  @override
  String get progressCostEstimated => 'Оценка стоимости';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds с';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'Модель: $model · Время: $duration · Стоимость: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'Запущено $time';
  }

  @override
  String progressLiveness(String state) {
    return 'Состояние: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'Вход: $input · Выход: $output токенов';
  }

  @override
  String get progressOutputPreviewLimited =>
      'Показаны только первые 6 000 символов структурированного вывода.';

  @override
  String progressRetryOf(String runId) {
    return 'Повтор запуска $runId';
  }

  @override
  String get progressContext => 'Контекст и лимиты';

  @override
  String get progressNoAgent => 'Нет агента для просмотра';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window токенов';
  }

  @override
  String get progressMeasured =>
      'Контекст последнего вызова по данным поставщика';

  @override
  String get progressEstimated =>
      'Оценка по сохранённому разговору и постоянному контексту';

  @override
  String get progressContextUnknown => 'Использование контекста ещё не указано';

  @override
  String progressContextPercent(String percent) {
    return '$percent% окна контекста';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'Заданный месячный лимит агента: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'Сохранённый текущий разговор: примерно $tokens токенов';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'Постоянный контекст для $agent · $model';
  }

  @override
  String get progressContextSystem => 'Системный промпт';

  @override
  String get progressContextRules => 'Правила';

  @override
  String get progressContextSkills => 'Навыки';

  @override
  String get progressContextTools => 'Определения инструментов';

  @override
  String get progressContextMcp => 'Инструменты MCP';

  @override
  String get progressContextDeferred => 'Отложенные инструменты';

  @override
  String get progressContextSubagents => 'Субагенты';

  @override
  String get progressContextRunner => 'Внешний исполнитель';

  @override
  String get progressContextMemory => 'Память';

  @override
  String get progressContextHistory => 'История разговора';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens токенов';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens токенов';
  }

  @override
  String get progressOutputs => 'Недавние результаты';

  @override
  String get progressNoOutputs => 'Нет недавних результатов агентов';

  @override
  String get progressStructuredOutputsAbove =>
      'Структурированные результаты запусков показаны выше, в списке запусков агентов.';

  @override
  String get progressRecentOutputsOnly =>
      'Показаны только недавние сообщения. Откройте разговор, чтобы увидеть более раннюю работу.';

  @override
  String get progressPlan => 'План';

  @override
  String get progressArtifact => 'Артефакт';

  @override
  String get progressResult => 'Результат';

  @override
  String get progressHideArtifact => 'Скрыть артефакт';

  @override
  String get progressReadArtifact => 'Прочитать артефакт';

  @override
  String get progressArtifactUnavailable => 'Артефакт больше недоступен';

  @override
  String get progressArtifactPreviewLimited =>
      'Показан сокращённый просмотр этого артефакта.';

  @override
  String get progressDiagramSource => 'Исходный код диаграммы';

  @override
  String progressOpenAttachment(String name) {
    return 'Открыть $name';
  }

  @override
  String get progressOpenPlan => 'Открыть план';

  @override
  String progressOpenDiff(String label) {
    return 'Просмотреть изменённые файлы: $label';
  }

  @override
  String get progressViewMessage => 'Посмотреть сообщение';

  @override
  String get pushTitle => 'Фоновые уведомления';

  @override
  String get pushIntro =>
      'Получайте личные оповещения, когда что-то требует внимания, даже если приложение закрыто. Подробности остаются внутри вашего зашифрованного соединения.';

  @override
  String get pushLoading => 'Проверяем настройки уведомлений…';

  @override
  String get pushError =>
      'Не удалось обновить уведомления. Проверьте подключение и повторите попытку.';

  @override
  String get pushEnable => 'Включить уведомления';

  @override
  String get pushDisable => 'Отключить уведомления';

  @override
  String get pushQuiet => 'Приостановить оповещения на этом устройстве';

  @override
  String get pushCategories => 'Уведомлять меня о';

  @override
  String get pushCategoryAgents => 'Агенты';

  @override
  String get pushCategoryMessages => 'Сообщения';

  @override
  String get pushCategoryPullRequests => 'Pull requests';

  @override
  String get pushCategoryTickets => 'Тикеты';

  @override
  String get pushCategoryCalendar => 'Календарь';

  @override
  String get pushCategoryMachines => 'Машины';

  @override
  String get pushSecureOrigin => 'Для уведомлений требуется HTTPS.';

  @override
  String get pushInstallIos =>
      'На iPhone или iPad добавьте приложение на экран «Домой» и откройте его оттуда, чтобы включить уведомления.';

  @override
  String get pushUnsupported =>
      'Этот браузер не поддерживает фоновые уведомления.';

  @override
  String get pushDenied =>
      'Уведомления заблокированы в настройках браузера. Разрешите их там, чтобы продолжить.';

  @override
  String get pushResubscribe => 'Переподключить уведомления';

  @override
  String get pushStatusEnabled => 'На этом устройстве уведомления включены.';

  @override
  String get pushStatusDisabled => 'На этом устройстве уведомления отключены.';

  @override
  String get credentialsTitle => 'Подключения и учётные данные';

  @override
  String get credentialsIntro =>
      'Подключите аккаунты, которые используют ваши запуски и интеграции. Секреты хранятся на вашем сервере, а не на этом телефоне.';

  @override
  String get credentialsModelProviders => 'Провайдеры моделей';

  @override
  String get credentialsOwnerOnly =>
      'Только владелец сервера может добавлять, подключать и удалять учётные данные поставщиков моделей. Эти ключи общие для всех рабочих пространств.';

  @override
  String get credentialsContactOwner =>
      'Попросите владельца сервера подключить поставщика, который нужен заблокированному запуску.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Вход в Claude Code выполняется через CLI на хосте. Попросите владельца сервера войти в аккаунт или обновить авторизацию в терминале хоста; с телефона это сделать нельзя.';

  @override
  String get credentialsYourForgeAccounts => 'Ваши аккаунты на Git-платформах';

  @override
  String get credentialsYourTicketingAccount => 'Ваш аккаунт в системе тикетов';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'Для локальных тикетов вход не нужен. Подключите Linear здесь, если ваше рабочее пространство использует Linear.';

  @override
  String get credentialsMembershipRequired =>
      'Чтобы управлять учётными данными Git-платформ и системы тикетов, присоединитесь к рабочему пространству. Запросите доступ у его администратора.';

  @override
  String get credentialsSwitchWorkspace =>
      'Эта ссылка ведёт в другое рабочее пространство. Переключитесь на него, прежде чем менять учётные данные.';

  @override
  String get credentialsReturnToInbox =>
      'Вернитесь во «Входящие», чтобы повторить заблокированный запуск после подключения учётных данных. Хост также автоматически проверяет отложенные запуски.';

  @override
  String get credentialsLoadFailed =>
      'Не удалось загрузить подключения. Проверьте связь с сервером и повторите попытку.';

  @override
  String get credentialsOperationFailed =>
      'Не удалось изменить это подключение. Проверьте связь с сервером, свои права и учётные данные, затем повторите попытку.';

  @override
  String get credentialsConnected => 'Подключено';

  @override
  String get credentialsNotConnected => 'Не подключено';

  @override
  String credentialsSignedInAs(String username) {
    return 'Вход выполнен как $username';
  }

  @override
  String get credentialsAccount => 'Подключённый аккаунт';

  @override
  String get credentialsStoredKey => 'Сохранённый ключ';

  @override
  String get credentialsActive => 'Активен';

  @override
  String get credentialsRemove => 'Удалить';

  @override
  String get credentialsRemoveConfirm =>
      'Удалить сохранённые учётные данные? Возможно, потребуется войти снова.';

  @override
  String get credentialsApiKey => 'API-ключ';

  @override
  String get credentialsApiKeyHint => 'Вставьте API-ключ поставщика';

  @override
  String get credentialsBrowserLogin => 'Войти через браузер';

  @override
  String get credentialsSignInAgain => 'Войдите снова';

  @override
  String get credentialsWaitingForLogin => 'Ожидаем авторизацию в браузере…';

  @override
  String get credentialsLoginTimedOut =>
      'Время для входа истекло. Начните заново.';

  @override
  String get credentialsCopyCode => 'Скопировать код';

  @override
  String get credentialsDeviceCodeHint =>
      'Подтвердите этот код на странице поставщика. Не закрывайте этот экран, пока сервер завершает вход.';

  @override
  String get credentialsPasteRedirect =>
      'Код авторизации или URL перенаправления';

  @override
  String get credentialsPasteRedirectHint =>
      'Вставьте код или полный URL перенаправления от поставщика';

  @override
  String get credentialsCompleteLogin => 'Завершить вход';

  @override
  String get credentialsRedirectUnavailable =>
      'Обратный вызов браузера на этом сервере недоступен с телефона по защищённому соединению. Попросите владельца сервера настроить общедоступный обратный вызов через HTTPS или добавьте токен.';

  @override
  String get credentialsUpdateToken => 'Обновить токен';

  @override
  String get credentialsAddToken => 'Добавить токен';

  @override
  String get credentialsPersonalToken => 'Персональный токен доступа';

  @override
  String get credentialsPersonalTokenHint =>
      'Вставьте персональный токен доступа';

  @override
  String get credentialsHostManaged =>
      'Это подключение настроено в приложении сервера или его окружении. Изменить его там может только владелец сервера; вы также можете добавить свой токен.';

  @override
  String get credentialsStopWatching => 'Прекратить отслеживание';
}
