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
      'Отсканируйте QR-код с Mac, чтобы связать этот телефон.';

  @override
  String get scanQrHelp =>
      'Откройте камеру и наведите её на QR в Control Center на Mac. Телефон подключается к Mac напрямую по закрытому каналу.';

  @override
  String get connectingToMac => 'Подключение к Mac…';

  @override
  String get connectingDetail =>
      'Устанавливается защищённое прямое соединение.';

  @override
  String get identityChangedTitle => 'Идентичность сервера изменилась';

  @override
  String get identityChangedBody =>
      'Этот сервер больше не совпадает с идентичностью, сохранённой при сопряжении. Возможно, сервер переустановили — или соединение перехватывают. В целях безопасности устройство не подключится. Удалите сопряжение и отсканируйте новый QR-код с Mac.';

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
  String get failureNotPaired => 'Нет сопряжения — отсканируйте QR-код с Mac';

  @override
  String get failureUnreachable =>
      'Сервер недоступен ни по одному пути — проверьте, что он запущен, или используйте ту же сеть';

  @override
  String get failureIdentityChanged =>
      'Идентичность сервера изменилась — если его переустановили, сопрягите устройство заново';

  @override
  String get failureAuthRejected =>
      'Сервер отклонил это устройство — сопрягите его заново с Mac';

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
      'Нажмите ещё раз, чтобы отключить это устройство от Mac';

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
}
