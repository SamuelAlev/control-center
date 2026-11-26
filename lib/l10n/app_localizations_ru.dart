// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String steeringForceSendFailed(String error) {
    return 'Не удалось отправить сейчас: $error';
  }

  @override
  String get questionAnswerNotDelivered =>
      'Ваш ответ не доставлен. Возможно, на вопрос уже ответили или агент перестал ждать.';

  @override
  String get succeeded => 'Успешно';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'Повтор #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'Запуск · $time';
  }

  @override
  String get agentActivityFollowingLive => 'Следим за активностью';

  @override
  String get agentActivityJumpToLatest => 'К последнему';

  @override
  String get agentActivityLoadFailed =>
      'Не удалось загрузить активность этого запуска';

  @override
  String get agentActivityNotRecorded =>
      'Для этого запуска активность не записана';

  @override
  String get agentActivityNotRecordedHint =>
      'У запусков, завершённых до включения записи активности, нет таймлайна.';

  @override
  String get agentActivityRunUnavailable => 'Этот запуск больше недоступен';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'Субагент $agent';
  }

  @override
  String get agentActivityUnsupported =>
      'Запись активности недоступна на подключённом сервере';

  @override
  String get agentActivityUnsupportedHint =>
      'Перезапустите приложение, чтобы подтянуть свежую сборку сервера.';

  @override
  String get agentActivityWaiting => 'Ожидание активности…';

  @override
  String get created => 'Создано';

  @override
  String get dictationStart => 'Начать диктовку';

  @override
  String get dictationListening => 'Слушаю…';

  @override
  String get dictationUnavailable =>
      'Для диктовки нужна голосовая модель на хосте сервера. Настройте её в параметрах голоса.';

  @override
  String get dictationFailedToStart => 'Не удалось начать диктовку';

  @override
  String get dictationHoldToTalkTitle => 'Удерживайте, чтобы говорить';

  @override
  String get dictationHoldToTalkDescription =>
      'Удерживайте кнопку микрофона или сочетание клавиш, чтобы диктовать, и отпустите, чтобы остановить. Если выключено — нажмите один раз, чтобы начать, и ещё раз, чтобы остановить.';

  @override
  String get focusConversation => 'Фокус на разговоре';

  @override
  String get ideAgentActivity => 'Активность агента';

  @override
  String get keybindingPushToTalk => 'Нажмите, чтобы говорить';

  @override
  String get agentPermissions => 'Разрешения агента';

  @override
  String get agentPermissionsSettingsDescription =>
      'Задайте, что агенты могут делать сами, о чём должны спрашивать и чего не могут — для рабочего пространства, агента или пространства.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Задайте решение для каждого вида действия. Правила каскадируются: пространство перекрывает агента, агент — рабочее пространство, рабочее пространство — пресет режима. Побеждает самое конкретное правило.';

  @override
  String get guardrailLoading => 'Загрузка правил…';

  @override
  String get guardrailRulesLoadFailed =>
      'Не удалось загрузить правила разрешений.';

  @override
  String get guardrailScopeWorkspace => 'Рабочее пространство';

  @override
  String get guardrailScopeAgent => 'Агент';

  @override
  String get guardrailScopeSpace => 'Пространство';

  @override
  String get guardrailSelectAgent => 'Выберите агента';

  @override
  String get guardrailSelectSpace => 'Выберите пространство';

  @override
  String get guardrailNoAgents =>
      'В этом рабочем пространстве пока нет агентов.';

  @override
  String get guardrailNoSpaces =>
      'В этом рабочем пространстве пока нет пространств.';

  @override
  String get guardrailClassFileDelete => 'Удалить файл';

  @override
  String get guardrailClassFileWriteOutsideWorktree =>
      'Писать вне рабочего дерева';

  @override
  String get guardrailClassGitCommit => 'Создать коммит';

  @override
  String get guardrailClassGitPush => 'Отправить в удалённый репозиторий';

  @override
  String get guardrailClassPrCreate => 'Открыть pull request';

  @override
  String get guardrailClassPrPublish => 'Обновить или слить pull request';

  @override
  String get guardrailClassVendorSyncWrite => 'Писать во внешний трекер';

  @override
  String get guardrailClassNetworkEgress => 'Обращаться к сети';

  @override
  String get guardrailClassSecretAccess => 'Читать секрет';

  @override
  String get guardrailClassPackageInstall => 'Установить пакет';

  @override
  String get guardrailClassProcessSpawn => 'Запустить процесс';

  @override
  String get guardrailClassWorkspaceMutation =>
      'Изменять структуру рабочего пространства';

  @override
  String get guardrailClassEnclosureControl => 'Управлять enclosure (rig)';

  @override
  String get navRigs => 'Rigs';

  @override
  String get rigsUnsupportedServer =>
      'Этот сервер не может размещать поверхности rig. Проверьте требования к хосту для компьютера, который вы хотите использовать.';

  @override
  String get rigSurfaceComputer => 'Компьютер';

  @override
  String get rigSurfaceBrowser => 'Браузер';

  @override
  String get rigSurfaceAndroid => 'Android';

  @override
  String get rigSurfaceIosSimulator => 'Симулятор iOS';

  @override
  String get rigSurfaceAppWindow => 'Окно приложения';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return 'Одноразовый $engine, изолированный от вашей машины. Откройте другой движок, чтобы сравнить ту же страницу рядом.';
  }

  @override
  String get rigPhaseReady => 'Готов';

  @override
  String get rigPhaseStarting => 'Запуск';

  @override
  String get rigPhaseParked => 'Припаркован';

  @override
  String get rigPhaseClosing => 'Закрытие';

  @override
  String get rigPhaseClosed => 'Закрыта';

  @override
  String get rigPhaseFailed => 'Сбой';

  @override
  String get rigPhaseUnknown => 'Неизвестно';

  @override
  String get rigNotAccelerated => 'Эмуляция';

  @override
  String get rigAudioListen => 'Слушать машину';

  @override
  String get rigAudioMute => 'Выключить звук машины';

  @override
  String get rigYouHaveControl => 'Управление у вас';

  @override
  String get rigBackendAvailable => 'Доступен';

  @override
  String get rigBackendUnavailable => 'Недоступен';

  @override
  String get rigEgressNotEnforced =>
      'Сеть на этом бэкенде не изолирована — он сам управляет подключением.';

  @override
  String get rigStartMachine => 'Запустить машину';

  @override
  String get rigStartHint =>
      'Запускает одноразовую ВМ, которую вы и ваши агенты используете в этом разговоре. Она уничтожается при закрытии и ничего на вашем компьютере не затрагивает.';

  @override
  String get rigStartAndroidHint =>
      'Подключается к эмулятору Android, который уже запущен на сервере. Доступ к сети не изолирован.';

  @override
  String get rigStartIosHint =>
      'Создает временный симулятор iOS на сервере macOS. Он удаляется при закрытии тестовой среды; доступ к сети не изолирован.';

  @override
  String get rigTechnicalDetails => 'Технические сведения';

  @override
  String get rigStopMachine => 'Остановить машину';

  @override
  String get rigHomeButton => 'Домой';

  @override
  String get rigRotateClockwise => 'Повернуть по часовой стрелке';

  @override
  String get rigRotateCounterclockwise => 'Повернуть против часовой стрелки';

  @override
  String get rigTakeScreenshot => 'Сделать снимок экрана';

  @override
  String get rigScreenshotSaved => 'Снимок экрана сохранён';

  @override
  String rigScreenshotSaveFailed(String error) {
    return 'Не удалось сохранить снимок экрана: $error';
  }

  @override
  String get rigSurfaceUnavailable =>
      'Этот сервер не может размещать машины такого типа.';

  @override
  String get rigTabNeedsConversation =>
      'Сначала откройте разговор — машина принадлежит одному, поэтому вы и ваши агенты смотрите на один экран.';

  @override
  String get ideMenuSectionTools => 'Инструменты';

  @override
  String get ideMenuSectionMachines => 'Машины';

  @override
  String get ideMenuSectionReopen => 'Открыть снова';

  @override
  String get ideMenuSearchHint => 'Поиск';

  @override
  String get ideMenuNoMatches => 'Нет совпадений';

  @override
  String get rigMenuComputer => 'Компьютер';

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
    return 'Закрыть $name?';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'Машина продолжит работать в фоне — её можно снова открыть в боковой панели. Чтобы сразу освободить память, выключите её.';

  @override
  String get ideCloseKeepBodyShell =>
      'Команда продолжит выполняться в фоне — оболочку можно снова открыть в боковой панели. Чтобы остановить её сейчас, завершите сеанс.';

  @override
  String get ideCloseKeepBodyAgent =>
      'Агент продолжит работать в фоне — разговор можно снова открыть в боковой панели. Чтобы завершить запуск сейчас, остановите агента.';

  @override
  String get ideCloseKeepRunning => 'Продолжить работу';

  @override
  String get ideCloseShutDownMachine => 'Выключить';

  @override
  String get ideCloseEndShell => 'Завершить оболочку';

  @override
  String get ideCloseStopAgent => 'Остановить агента';

  @override
  String get rigsSettingsSubtitle =>
      'Что этот сервер может запускать, какие базовые образы ему нужны и какие машины работают сейчас';

  @override
  String get rigsCapabilitiesTitle => 'Этот сервер';

  @override
  String get rigInstallIosAutomation => 'Установить мост автоматизации iOS';

  @override
  String get rigInstallingIosAutomation => 'Установка моста автоматизации iOS…';

  @override
  String get rigIosAutomationInstalled => 'Мост автоматизации iOS установлен';

  @override
  String get rigsImagesTitle => 'Базовые образы';

  @override
  String get rigsImagesHint =>
      'Каждый риг загружается с одного из этих образов только для чтения. Каждая сессия пишет во временный оверлей, поэтому один риг не может изменить то, с чего стартует следующий.';

  @override
  String get rigsRunningTitle => 'Работают сейчас';

  @override
  String get rigsNoneRunning => 'Нет запущенных машин.';

  @override
  String get rigsCustomImagesTitle => 'Свои образы (это рабочее пространство)';

  @override
  String get rigsCustomImagesHint =>
      'Укажите свой образ для Terminal (VM) или Browser (VM) — дополните стандартные инструментами проекта или возьмите совместимый из реестра. Новые машины будут его использовать; уже запущенные сохранят свой. См. руководство по ригам, что должен предоставлять образ.';

  @override
  String get rigsCustomTerminalImageLabel => 'Образ Terminal (VM)';

  @override
  String get rigsCustomBrowserImageLabel => 'Образ Browser (VM)';

  @override
  String get rigsCustomImagePlaceholder =>
      'напр. ghcr.io/acme/dev-shell:1.2 — оставьте пустым для образа по умолчанию';

  @override
  String get rigsCustomImageInvalid =>
      'Укажите ссылку реестра в виде repo/name:tag. Локальные пути и архивы не допускаются.';

  @override
  String get rigsCustomImageSaved =>
      'Сохранено. Новые машины загрузятся с этим образом; уже запущенные сохранят свой.';

  @override
  String get rigsEgressTitle =>
      'Исходящий доступ браузера (это рабочее пространство)';

  @override
  String get rigsEgressHint =>
      'Дополнительные хосты, которые может открывать изолированный браузер — по одному в строке: точный хост (api.example.com) или маска его поддоменов (*.example.com). Сайт продукта разрешён в любом случае. Новые машины получат список; уже запущенные сохранят тот, с которым загрузились.';

  @override
  String rigsEgressInvalid(String host) {
    return '«$host» — недопустимая запись хоста.';
  }

  @override
  String get rigsEgressSaved =>
      'Сохранено. Новые браузерные машины получат эти хосты; уже запущенные сохранят свои.';

  @override
  String get rigImageInstalled => 'Установлен';

  @override
  String get rigImageNotDownloaded => 'Не загружен';

  @override
  String get rigImageNotPublished => 'Не опубликован';

  @override
  String get rigImageNotPublishedHint =>
      'Для этого ещё нет опубликованного образа, поэтому загружать нечего. Импортируйте совместимый образ диска, чтобы включить.';

  @override
  String get rigImageDownload => 'Скачать';

  @override
  String get rigImageDownloading => 'Загрузка…';

  @override
  String get rigImageImport => 'Импорт';

  @override
  String get rigImageImportMessage =>
      'Путь к образу диска qcow2 в файловой системе сервера. Файл копируется в хранилище образов, после этого его можно перемещать.';

  @override
  String get rigConnectingStream => 'Подключение к ригу';

  @override
  String get rigStreamNotAllowed => 'У вас нет доступа к этому ригу.';

  @override
  String get rigStreamNotRunning => 'Этот риг больше не работает.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'Для живого просмотра на этом хосте нужен ffmpeg. Установите ffmpeg и откройте вкладку снова.';

  @override
  String get rigStreamNeedsScreenCapture =>
      'Для просмотра в реальном времени нужна запись экрана. Разрешите её для Control Center в Системных настройках и снова откройте вкладку.';

  @override
  String get rigStreamEnded => 'Живой просмотр завершён.';

  @override
  String get rigStreamFailed => 'Не удалось открыть живой просмотр.';

  @override
  String get rigStreamDisconnected => 'Нет подключения к серверу.';

  @override
  String rigDropSendingOne(String name) {
    return 'Копирование «$name» на машину…';
  }

  @override
  String rigDropSendingMany(int count) {
    return 'Копирование $count файлов на машину…';
  }

  @override
  String get rigTerminalDropSending => 'Копирование на машину…';

  @override
  String get rigTerminalPasteImage =>
      'Вставленное изображение сохранено на машине';

  @override
  String get rigPortsTitle => 'Проброшенные порты';

  @override
  String get rigPortsTooltip => 'Порты, открытые внутри этой машины';

  @override
  String get rigPortsEmpty =>
      'Пока никто не слушает. Запустите сервер в терминале — сервер разработки на порту 3000 появится здесь.';

  @override
  String get rigPortsAdd => 'Добавить порт';

  @override
  String get rigPortsAddHint => 'Гостевой порт для проброса (например, 3000)';

  @override
  String get rigPortsAutoForward => 'Автопроброс портов';

  @override
  String get rigPortsCopyUrl => 'Скопировать локальный URL';

  @override
  String rigPortsCopiedUrl(String url) {
    return 'Скопировано $url';
  }

  @override
  String get rigPortsStopForward => 'Остановить проброс';

  @override
  String get rigPortsExposeLan => 'Открыть в локальной сети';

  @override
  String get rigPortsLanPrivate => 'Только локально';

  @override
  String get rigPortsLanShared => 'В сети';

  @override
  String get rigPortsSetDomain => 'Задать домен браузера (.test)';

  @override
  String get rigPortsDomainHint =>
      'Домен для браузера (VM), например myapp.test — доступен там, не на хосте';

  @override
  String get rigPortsProcessUnknown => 'неизвестный процесс';

  @override
  String get rigPortsInactive => 'не слушает';

  @override
  String get rigPortsTooltipHost => 'Порты, открытые в этом терминале';

  @override
  String get rigPortsEmptyHost =>
      'В этом терминале пока никто не слушает. Запустите сервер — он появится здесь.';

  @override
  String get rigPortsAddHintHost => 'Порт для сопоставления (напр. 5173)';

  @override
  String get rigPortsLocalPortHint => 'Локальный порт (необязательно)';

  @override
  String rigPortsDestDesktop(int port) {
    return 'localhost:$port';
  }

  @override
  String rigPortsDestBrowser(int port) {
    return 'localhost:$port в браузере (ВМ)';
  }

  @override
  String get rigPortsDestBrowserUnreachable => 'браузер (ВМ) не подключён';

  @override
  String rigPortsDestAndroid(int port) {
    return 'localhost:$port на Android';
  }

  @override
  String get rigPortsDestAndroidUnreachable => 'Android не подключён';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Осталось скачать $count базовых образов',
      many: 'Осталось скачать $count базовых образов',
      few: 'Осталось скачать $count базовых образа',
      one: 'Осталось скачать $count базовый образ',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'Разрешить';

  @override
  String get guardrailDecisionPrompt => 'Спросить сначала';

  @override
  String get guardrailDecisionDeny => 'Запретить';

  @override
  String get guardrailSourceThisScope => 'Эта область';

  @override
  String get guardrailSourceDefault => 'Встроенное по умолчанию';

  @override
  String get guardrailSourcePreset => 'Пресет режима';

  @override
  String get guardrailSourceInherited => 'Унаследовано';

  @override
  String get guardrailClearToInherited => 'Сбросить к унаследованному';

  @override
  String get guardrailWhatIf => 'Что если?';

  @override
  String get guardrailWhatIfDescription =>
      'Посмотрите, как текущие правила разрешат действие — по той же логике, что используют агенты.';

  @override
  String get guardrailProbeActionLabel => 'Действие';

  @override
  String get guardrailProbeCommandLabel => 'Команда (необязательно)';

  @override
  String get guardrailProbeCommandHint => 'например, git push origin main';

  @override
  String get guardrailProbeAgentLabel => 'Агент (необязательно)';

  @override
  String get guardrailProbeSpaceLabel => 'Пространство (необязательно)';

  @override
  String get guardrailProbeNone => 'Нет';

  @override
  String get guardrailProbeModeLabel => 'Режим';

  @override
  String get guardrailProbeResult => 'Результат';

  @override
  String get guardrailProbeSource => 'Источник:';

  @override
  String get guardrailAdapterMatrix => 'Где применяются правила';

  @override
  String get guardrailAdapterMatrixDescription =>
      'Справка как есть: где каждый эффект реально перехватывается, по каждому исполнителю агента. Это описание факта, а не гарантия — эффекты вне канала исполнителя перехватить нельзя.';

  @override
  String get guardrailEffectColumn => 'Эффект';

  @override
  String get guardrailAdapterHarness => 'Встроенный раннер';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'Нижняя граница песочницы';

  @override
  String get guardrailEnforcementPolicyGate => 'Шлюз политики';

  @override
  String get guardrailEnforcementSandbox => 'Только песочница';

  @override
  String get guardrailEnforcementNone => 'Не применяется';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'Решение о разрешении проверяется до выполнения эффекта и может его заблокировать.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'Ограничивает только песочница; правило разрешений не учитывается.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'Решение только рекомендательное — здесь его нельзя перехватить.';

  @override
  String get obsStatCost => 'стоимость';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount делегировано';
  }

  @override
  String get obsStatDuration => 'длительность';

  @override
  String get obsStatTokens => 'токены';

  @override
  String get obsStatTools => 'инструменты';

  @override
  String get openAgentActivity => 'Открыть активность';

  @override
  String get orgChart => 'Оргсхема';

  @override
  String get orgChartEmpty => 'Пока нет агентов';

  @override
  String get navCalendar => 'Календарь';

  @override
  String get serverConnection => 'Подключение к серверу';

  @override
  String get serverModeLocal => 'Запускать в этом приложении';

  @override
  String get serverModeLocalDescription =>
      'Control Center запускает собственный сервер на этом компьютере и хранит данные локально.';

  @override
  String get serverRemoteUrl => 'URL сервера';

  @override
  String get serverRemoteDeviceId => 'ID устройства';

  @override
  String get serverRemotePairingKey => 'Ключ сопряжения';

  @override
  String get serverRemotePairingKeyHint =>
      'Вставьте ключ сопряжения с удалённого сервера';

  @override
  String get serverSetupInviteCode => 'Код приглашения';

  @override
  String get serverSetupInviteCodeHint =>
      'Вставьте одноразовый код приглашения (оставьте пустым, чтобы использовать ключ сопряжения)';

  @override
  String get serverDiscoveryTooltip => 'Найти серверы в сети';

  @override
  String get serverDiscoveryTitle => 'Серверы в вашей сети';

  @override
  String get serverDiscoverySearching => 'Поиск серверов…';

  @override
  String get serverDiscoveryEmpty =>
      'Серверы не найдены. Убедитесь, что сервер запущен и доступен с этого устройства, затем повторите поиск.';

  @override
  String get serverDiscoveryRefresh => 'Искать снова';

  @override
  String get serverListActive => 'Активен';

  @override
  String get serverListSwitch => 'Переключить';

  @override
  String get serverListAddTitle => 'Добавить сервер';

  @override
  String get serverListRemoveActiveHint =>
      'Сначала переключитесь на другой сервер.';

  @override
  String get serverSwitchFailedTitle => 'Не удалось переключить сервер';

  @override
  String get serverListInsecureBadge => 'Незащищённое';

  @override
  String get connectionPathLocal => 'Локально';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'Завершение работы';

  @override
  String get shutdownSubtitle => 'Остановка локального сервера';

  @override
  String get shutdownServiceApprovals => 'Подтверждения';

  @override
  String get shutdownServiceBackgroundJobs => 'Фоновые задачи';

  @override
  String get shutdownServiceScheduler => 'Планировщик задач';

  @override
  String get shutdownServiceCalendar => 'Синхронизация календаря';

  @override
  String get shutdownServiceWeather => 'Погода';

  @override
  String get shutdownServiceSoundscape => 'Soundscape';

  @override
  String get shutdownServiceMeetings => 'Встречи';

  @override
  String get shutdownServiceVoiceModels => 'Голосовые модели';

  @override
  String get shutdownServiceNetworking => 'Сеть';

  @override
  String get shutdownServicePresence => 'Присутствие';

  @override
  String get shutdownServiceDataSync => 'Синхронизация данных';

  @override
  String get shutdownServiceDeviceRelay => 'Ретрансляция устройств';

  @override
  String get shutdownServiceMcpConnections => 'Подключения MCP';

  @override
  String get shutdownServiceCodeEditors => 'Редакторы кода';

  @override
  String get serverSharingTitle => 'Открыть доступ к серверу';

  @override
  String get serverSharingDescription =>
      'Сделайте этот сервер доступным с других устройств. Публичный доступ появится, только если включить туннель ниже. Приглашения для сопряжения автоматически содержат текущие адреса сервера — создайте их в настройках рабочего пространства.';

  @override
  String get serverSharingUnavailable =>
      'Управление доступом на этом сервере недоступно.';

  @override
  String get serverSharingMdnsLabel => 'Обнаружение в LAN';

  @override
  String get serverSharingMdnsOn =>
      'Сервер объявляется в локальной сети (mDNS)';

  @override
  String get serverSharingMdnsOff =>
      'Сервер не объявляется в локальной сети (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'Туннель';

  @override
  String get serverSharingTunnelHelper =>
      'Туннель делает сервер доступным из интернета. Публичный доступ включается явно и по умолчанию выключен.';

  @override
  String get serverSharingProviderOff => 'Выкл.';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'Публичный URL';

  @override
  String get serverSharingTunnelStarting => 'Запуск туннеля…';

  @override
  String serverSharingTunnelError(String error) {
    return 'Ошибка туннеля: $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'Туннель запущен. Доступ по настроенному DNS-имени.';

  @override
  String get serverSharingRelayLabel => 'Relay';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'Реле в этом месяце: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'Активные сессии реле: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle => 'Не удалось обновить доступ';

  @override
  String get pairNewClient => 'Привязать новый клиент';

  @override
  String get pairClientNameHint =>
      'Название клиента (например, рабочий ноутбук)';

  @override
  String get pairClientTypeWeb => 'Веб-браузер';

  @override
  String get pairClientTypeDesktop => 'Приложение для компьютера';

  @override
  String get pairClientTypePhone => 'Телефон';

  @override
  String get pairAction => 'Привязать';

  @override
  String get revoke => 'Отозвать';

  @override
  String get pairCredentialsIntro =>
      'Подключите новый клиент по этим данным или откройте в нём ссылку.';

  @override
  String get pairLinkLabel => 'Ссылка';

  @override
  String get pairScanQr =>
      'Отсканируйте QR-код камерой телефона, чтобы привязать его.';

  @override
  String get pairServerUnreachableTitle => 'Недоступен';

  @override
  String get pairServerUnreachable =>
      'Другие устройства не могут достучаться до этого сервера напрямую, поэтому новый клиент не подключится. Укажите публичный URL сервера, чтобы привязать ещё клиенты.';

  @override
  String get serverSetupRunLocal => 'Запустить в этом приложении';

  @override
  String get serverSetupConnect => 'Подключить';

  @override
  String get serverSetupInvalidUrl =>
      'Введите корректный URL сервера (ws:// или wss://).';

  @override
  String get serverSetupCouldNotConnect => 'Не удалось подключиться';

  @override
  String get serverSetupErrorUnreachable =>
      'Не удалось достучаться до сервера. Убедитесь, что он запущен и это устройство может до него достучаться (та же сеть или реле).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'Идентичность сервера не совпадает с сохранённой на этом устройстве. Если сервер переустановили или сбросили, удалите сохранённый сервер и выполните сопряжение заново.';

  @override
  String get serverSetupErrorAuthRejected =>
      'Сервер отклонил это устройство. Проверьте, что ключ сопряжения и идентификатор устройства совпадают с выданными сервером.';

  @override
  String get serverSetupErrorInviteRejected =>
      'Код приглашения недействителен или истёк. Запросите новый.';

  @override
  String get serverSetupErrorGeneric =>
      'Не удалось подключиться. Разверните технические сведения ниже, чтобы узнать больше.';

  @override
  String get serverSetupErrorDetails => 'Технические сведения';

  @override
  String get serverActivityTitle => 'Активность сервера';

  @override
  String get serverActivityStarting => 'Запуск локального сервера…';

  @override
  String get serverActivityConnecting => 'Подключение к серверу…';

  @override
  String get serverActivityStartFailed => 'Не удалось запустить сервер';

  @override
  String get serverActivityDownloadFailed => 'Не удалось скачать';

  @override
  String get serverActivityStatusUnavailable =>
      'Не удалось получить состояние модели';

  @override
  String get serverActivityPreparingModel => 'Подготовка модели…';

  @override
  String get serverActivityPortInUse =>
      'Порт сервера уже занят. Остановите другой процесс или выберите другой порт на сервере.';

  @override
  String get serverActivityStartFailedHint =>
      'Проверьте технические сведения и повторите попытку в настройке сервера.';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ещё $count',
      many: 'ещё $count',
      few: 'ещё $count',
      one: 'ещё $count',
    );
    return '$_temp0';
  }

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count события',
      many: '$count событий',
      few: '$count события',
      one: '$count событие',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => 'Свернуть события на весь день';

  @override
  String get calendarExpandAllDay => 'Развернуть события на весь день';

  @override
  String get calendarViewMonth => 'Месяц';

  @override
  String get calendarViewWeek => 'Неделя';

  @override
  String get calendarViewAgenda => 'Расписание';

  @override
  String get calendarConnectGoogle => 'Подключить Google Calendar';

  @override
  String get calendarConnectDescription =>
      'Синхронизируйте Google Calendar, чтобы видеть события здесь и получать напоминания перед началом встреч.';

  @override
  String get calendarDisconnect => 'Отключить';

  @override
  String get calendarReconnect => 'Подключить снова';

  @override
  String get calendarEmptyNoEvents => 'В этом диапазоне нет событий';

  @override
  String get calendarJoinMeet => 'Присоединиться к встрече';

  @override
  String get calendarJoinAndRecord => 'Присоединиться и записать';

  @override
  String get calendarRecordFailed => 'Не удалось начать запись';

  @override
  String get calendarFromCalendar => 'Из календаря';

  @override
  String get calendarLinkedMeeting => 'Привязанная встреча';

  @override
  String get calendarToday => 'Сегодня';

  @override
  String get calendarAllDay => 'Весь день';

  @override
  String calendarWeekNumber(int number) {
    return 'Неделя $number';
  }

  @override
  String get calendarPreviousPeriod => 'Назад';

  @override
  String get calendarNextPeriod => 'Вперёд';

  @override
  String calendarLastSynced(String time) {
    return 'Синхронизировано $time';
  }

  @override
  String get calendarNeverSynced => 'Ещё не синхронизировано';

  @override
  String get calendarSyncing => 'Синхронизация…';

  @override
  String get calendarViewDay => 'День';

  @override
  String get calendarShow => 'Показать';

  @override
  String get calendarHide => 'Скрыть';

  @override
  String get calendarRsvpGoing => 'Идёте?';

  @override
  String get calendarRsvpYes => 'Да';

  @override
  String get calendarRsvpNo => 'Нет';

  @override
  String get calendarRsvpMaybe => 'Возможно';

  @override
  String get calendarRsvpFailed => 'Не удалось обновить ответ';

  @override
  String get calendarNewEvent => 'Новое событие';

  @override
  String get calendarComposerTitleHint => 'Добавьте название';

  @override
  String get calendarComposerStarts => 'Начало';

  @override
  String get calendarComposerEnds => 'Конец';

  @override
  String get calendarComposerDate => 'Дата';

  @override
  String get calendarComposerEndDate => 'Последний день';

  @override
  String get calendarComposerGuestsHint => 'Добавьте гостей по email';

  @override
  String get calendarComposerMeet => 'Добавить ссылку Google Meet';

  @override
  String get calendarComposerLocationHint => 'Добавьте место';

  @override
  String get calendarComposerDescriptionHint => 'Добавьте описание';

  @override
  String get calendarComposerCalendar => 'Календарь';

  @override
  String get calendarComposerTitleRequired =>
      'Чтобы сохранить событие, добавьте название';

  @override
  String get calendarComposerInvalidGuests =>
      'Один из email гостей некорректен';

  @override
  String get calendarComposerEndBeforeStart =>
      'Событие должно заканчиваться после начала';

  @override
  String get calendarComposerSaveFailed =>
      'Не удалось создать событие. Попробуйте ещё раз.';

  @override
  String get calendarComposerGuestsNotified =>
      'Гости получат приглашение по email от Google.';

  @override
  String get calendarDeleteEvent => 'Удалить событие';

  @override
  String calendarDeleteConfirmTitle(String title) {
    return 'Удалить «$title»?';
  }

  @override
  String get calendarDeleteConfirmBody =>
      'Оно будет удалено из Google Calendar.';

  @override
  String get calendarDeleteConfirmGuests =>
      'Оно будет удалено из Google Calendar, а всем гостям сообщат, что встреча отменена.';

  @override
  String get calendarDeleteConfirmInvite =>
      'Оно удаляется только из вашего календаря. Организатор и другие гости сохраняют его.';

  @override
  String get calendarDeleteConfirmRecurring =>
      'Удаляется только это повторение; остальная серия сохраняется.';

  @override
  String get calendarDeleteFailed =>
      'Не удалось удалить событие. Попробуйте ещё раз.';

  @override
  String get calendarMoveFailed =>
      'Не удалось переместить событие. Оно вернулось на прежнее место.';

  @override
  String get activityCreatedCalendarEvent => 'Создал событие в календаре';

  @override
  String get activityMovedCalendarEvent => 'Переместил событие в календаре';

  @override
  String get activityDeletedCalendarEvent => 'Удалил событие из календаря';

  @override
  String get calendarAddAccount => 'Добавить аккаунт календаря';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Подключите аккаунт Google, чтобы синхронизировать события в это пространство. Эти календари здесь ваши.';

  @override
  String get calendarSyncNow => 'Синхронизировать';

  @override
  String get calendarNoWorkspace =>
      'Выберите рабочее пространство, чтобы просмотреть его календарь';

  @override
  String get calendarConnectError => 'Не удалось подключить Google Calendar';

  @override
  String get notificationMeetingStartsSoon => 'Встреча скоро начнётся';

  @override
  String get notifyMeetingStartsSoon =>
      'Когда встреча в календаре скоро начнётся';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Календарь отключён';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Подключите $email заново, чтобы продолжить синхронизацию';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Подключите календарь заново, чтобы продолжить синхронизацию';

  @override
  String get notifyCalendarAuthExpired =>
      'Когда нужно заново подключить аккаунт календаря';

  @override
  String get notificationRigStatusChanged => 'Обновления стенда';

  @override
  String get notifyRigStatusChanged =>
      'Когда стенд перехватывают, отзывают или происходит сбой';

  @override
  String get notificationRigTakenOver => 'Стенд перехвачен';

  @override
  String get notificationRigTakenOverBody =>
      'Человек управляет машиной; агент может наблюдать, но не действовать.';

  @override
  String get notificationRigReleased => 'Управление стендом освобождено';

  @override
  String get notificationRigReleasedBody => 'Агент снова управляет машиной.';

  @override
  String get notificationRigReclaimed => 'Стенд отозван';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'Стенд простаивал, поэтому машина была закрыта, чтобы освободить память.';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'Истекло ограничение по времени, машина закрыта.';

  @override
  String get notificationRigFailed => 'Сбой стенда';

  @override
  String get notificationRigFailedBody =>
      'Гипервизор аварийно завершился. Откройте машину снова, чтобы продолжить.';

  @override
  String get calendarAlertLeadTime => 'За сколько предупреждать';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'За сколько до встречи показывать оповещение';

  @override
  String calendarConnectedAs(String email) {
    return 'Подключено как $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count attendees';
  }

  @override
  String get calendarEventLabel => 'Событие';

  @override
  String get calendarRecurring => 'Повторяющееся событие';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Организатор';

  @override
  String get calendarYou => 'Вы';

  @override
  String get calendarShowFewer => 'Показать меньше';

  @override
  String get calendarRsvpAwaiting => 'Ожидание';

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
  String get openInEditorPrompt => 'В каком редакторе открыть?';

  @override
  String get ideNotInstalled => 'Не установлен';

  @override
  String openInIde(String editor) {
    return 'Открыть в $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'Не удалось открыть $editor: $error';
  }

  @override
  String get profileSearchHint => 'Поиск pull requests…';

  @override
  String get stopAgentRun => 'Остановить запуск';

  @override
  String get stopAgentRunConfirm =>
      'Остановить этот запуск? Незавершённая работа будет потеряна.';

  @override
  String get inProgress => 'В работе';

  @override
  String get drafts => 'Черновики';

  @override
  String get sortOldest => 'Старые';

  @override
  String get sortLargest => 'Крупные';

  @override
  String get prFilterTooltip => 'Фильтр';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count активных фильтров',
      many: '$count активных фильтров',
      few: '$count активных фильтра',
      one: '$count активный фильтр',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'Добавить фильтр…';

  @override
  String get prFilterFieldHint => 'Фильтр…';

  @override
  String get prFilterCategoryStatus => 'Статус';

  @override
  String get prFilterCategoryAuthor => 'Автор';

  @override
  String get prFilterCategoryReviewer => 'Ревьюеры';

  @override
  String get prFilterCategoryContent => 'Содержимое';

  @override
  String get prFilterCategoryRepoOwner => 'Владелец репозитория';

  @override
  String get prFilterCategoryRepoName => 'Имя репозитория';

  @override
  String get prFilterCategoryOpenedDate => 'Дата открытия';

  @override
  String get prFilterCategoryUpdatedDate => 'Дата обновления';

  @override
  String get prFilterQuickToReview => 'Быстрое ревью';

  @override
  String get prFilterClearAll => 'Сбросить фильтры';

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
      other: '$count вариантов не соответствуют ни одному pull request',
      many: '$count вариантов не соответствуют ни одному pull request',
      few: '$count варианта не соответствуют ни одному pull request',
      one: '$count вариант не соответствует ни одному pull request',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'Заголовок или текст содержит…';

  @override
  String get prFilterNoOptions => 'Нет подходящих вариантов';

  @override
  String get prFilterChipIs => 'равно';

  @override
  String get prFilterChipIsAnyOf => 'любое из';

  @override
  String get prFilterChipContains => 'содержит';

  @override
  String get prFilterChipSince => 'с';

  @override
  String get prFilterAddFilterButton => 'Добавить фильтр';

  @override
  String prFilterClearCategory(String category) {
    return 'Сбросить фильтр $category';
  }

  @override
  String get prFilterCurrentUser => 'Текущий пользователь';

  @override
  String get prStatusDraft => 'Черновик';

  @override
  String get prStatusOpen => 'Открыт';

  @override
  String get prStatusInReview => 'На ревью';

  @override
  String get prStatusChangesRequested => 'Запрошены изменения';

  @override
  String get prStatusApproved => 'Одобрен';

  @override
  String get prStatusMerged => 'Слит';

  @override
  String get prStatusClosed => 'Закрыт';

  @override
  String get prDateWindowDay => '1 день назад';

  @override
  String get prDateWindowThreeDays => '3 дня назад';

  @override
  String get prDateWindowWeek => '1 неделю назад';

  @override
  String get prDateWindowMonth => '1 месяц назад';

  @override
  String get prDateWindowThreeMonths => '3 месяца назад';

  @override
  String get prDateWindowSixMonths => '6 месяцев назад';

  @override
  String get prDateWindowYear => '1 год назад';

  @override
  String get prDisplayOptions => 'Параметры отображения';

  @override
  String get prDisplayGrouping => 'Группировка';

  @override
  String get prDisplayOrdering => 'Сортировка';

  @override
  String get prDisplayShowDrafts => 'Показывать черновики';

  @override
  String get prDisplayMergedWindow => 'Период слитых';

  @override
  String get prDisplayMergedWindowDay => 'За день';

  @override
  String get prDisplayMergedWindowWeek => 'За неделю';

  @override
  String get prDisplayMergedWindowMonth => 'За месяц';

  @override
  String get prDisplayProperties => 'Отображаемые свойства';

  @override
  String get prGroupingRepository => 'Репозиторий';

  @override
  String get prGroupingAuthor => 'Автор';

  @override
  String get prGroupingStatus => 'Статус';

  @override
  String get prGroupingNone => 'Без группировки';

  @override
  String get prPropertyRepository => 'Репозиторий';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'Ветка';

  @override
  String get prPropertyUpdated => 'Обновлён';

  @override
  String get prPropertyAuthor => 'Автор';

  @override
  String get prPropertyChecks => 'Проверки';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'Комментарии';

  @override
  String get keybindingOpenFilterMenu => 'Открыть меню фильтров';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count выбрано',
      many: '$count выбрано',
      few: '$count выбраны',
      one: '$count выбран',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'Сводка';

  @override
  String get kbMove => 'переместить';

  @override
  String get kbTabs => 'вкладки';

  @override
  String get kbSearch => 'поиск';

  @override
  String get kbViewed => 'просмотрено';

  @override
  String get kbCollapse => 'свернуть';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get appearanceSettingsDescription => 'Тема, язык и типографика.';

  @override
  String get notificationsSettingsDescription =>
      'Выберите, о каких событиях агентов и рабочих пространств вас уведомлять.';

  @override
  String get advanced => 'Дополнительно';

  @override
  String get accounts => 'Аккаунты';

  @override
  String get mcpServers => 'MCP-серверы';

  @override
  String get remoteControlAndDevices => 'Удалённое управление и устройства';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'Сопрягите телефоны и настройте сервер удалённого управления.';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'Модели распознавания речи и диаризации, которые размещает этот сервер.';

  @override
  String get needsSetupLabel => 'Требуется настройка';

  @override
  String get collapseSidebar => 'Свернуть боковую панель';

  @override
  String get expandSidebar => 'Развернуть боковую панель';

  @override
  String get filterSpacesHint => 'Фильтровать пространства';

  @override
  String noSpacesMatch(String query) {
    return 'Нет пространств по запросу «$query»';
  }

  @override
  String get privacy => 'Конфиденциальность';

  @override
  String get sendDiffContentTitle => 'Отправлять содержимое diff в AI-адаптер';

  @override
  String get diffSharingOnSubtitle =>
      'Исходные строки diff включаются в промпты агента для более глубокого ревью.';

  @override
  String get diffSharingOffSubtitle =>
      'Агенты используют только структурированные метаданные (пути к файлам, номера строк, описание PR); исходный код из приложения не уходит.';

  @override
  String get errorReportingTitle => 'Отправлять отчёты о сбоях';

  @override
  String get errorReportingOnSubtitle =>
      'Диагностика сбоев, ошибок и производительности отправляется, чтобы быстрее исправлять баги (только в release-сборках).';

  @override
  String get errorReportingOffSubtitle =>
      'Диагностика отключена. Отчёты о сбоях и ошибках не отправляются.';

  @override
  String get onboardingDiagnosticsTitle => 'Помогите улучшить Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Отправляйте диагностику сбоев, ошибок и производительности, чтобы мы быстрее исправляли проблемы (только в release-сборках). Это можно изменить в любой момент в «Настройки → Конфиденциальность».';

  @override
  String get usageAnalyticsTitle => 'Отправлять статистику использования';

  @override
  String get usageAnalyticsOnSubtitle =>
      'Все клиенты этого сервера отправляют псевдонимизированные события использования (экраны, действия, счётчики), только в release-сборках. Имена, содержимое сообщений, пути к файлам и адреса электронной почты не отправляются никогда.';

  @override
  String get usageAnalyticsOffSubtitle =>
      'Статистика использования выключена. Ни один клиент этого сервера не отправляет события использования.';

  @override
  String get usageAnalyticsManagedOnSubtitle =>
      'Клиенты этого сервера отправляют псевдонимизированные события использования. Изменить это может только оператор сервера.';

  @override
  String get usageAnalyticsManagedOffSubtitle =>
      'Статистика использования на этом сервере выключена. Изменить это может только оператор сервера.';

  @override
  String get onboardingUsageAnalyticsSubtitle =>
      'Отправляйте псевдонимизированные события использования со всех клиентов этого сервера, чтобы мы видели, какие функции полезны (только в release-сборках). Имена, содержимое сообщений, пути к файлам и адреса электронной почты не отправляются никогда. Это можно изменить в любой момент в «Настройки → Конфиденциальность».';

  @override
  String get blocked => 'Заблокирован';

  @override
  String get idle => 'Простой';

  @override
  String get noRunsYet => 'Запусков пока нет';

  @override
  String get copyPath => 'Копировать путь';

  @override
  String get copyRelativePath => 'Копировать относительный путь';

  @override
  String get nameRequired => 'Имя обязательно';

  @override
  String get import => 'Импорт';

  @override
  String get noMatchingAgents => 'Нет агентов, подходящих под фильтр';

  @override
  String watchVideoOn(String provider) {
    return 'Смотреть видео на $provider';
  }

  @override
  String get branchTemplate => 'Шаблон имени ветки';

  @override
  String get branchTemplateDescription =>
      'Шаблон ветки, создаваемой при запуске тикета в изолированном рабочем дереве.';

  @override
  String branchTemplatePreview(String example) {
    return 'Пример: $example';
  }

  @override
  String get deletePipelineRun => 'Удалить запуск конвейера';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Удалить этот запуск «$template»? Это действие нельзя отменить.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Ошибка удаления запуска конвейера: $error';
  }

  @override
  String get deleteTicket => 'Удалить тикет';

  @override
  String deleteTicketConfirm(String title) {
    return 'Удалить «$title»? Это действие нельзя отменить.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Ошибка удаления тикета: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return 'Удалить «$name»? Связанные репозитории на диске не затрагиваются.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Ошибка удаления рабочего пространства: $error';
  }

  @override
  String get indexCode => 'Индексировать код';

  @override
  String get indexNoGrammars => 'Грамматики кода не установлены';

  @override
  String get indexFailed => 'Индексирование не удалось';

  @override
  String indexedSymbolsCount(int count) {
    return '$count символов проиндексировано';
  }

  @override
  String get nodeConfigAdvanced => 'Дополнительно';

  @override
  String get nodeConfigReducer => 'Редьюсер';

  @override
  String get nodeConfigReducerHelp =>
      'Как объединять значения, если у этого ключа выхода уже есть значение';

  @override
  String get nodeConfigTimeoutMs => 'Таймаут (мс)';

  @override
  String get nodeConfigRetryAttempts => 'Число повторов';

  @override
  String get nodeConfigContinueOnFail => 'Продолжить при ошибке шага';

  @override
  String get nodeConfigTeamId => 'ID команды';

  @override
  String get nodeConfigDispatchMode => 'Режим диспетчеризации';

  @override
  String get nodeConfigOutputSchema => 'Схема выхода (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'JSON Schema, которой должен соответствовать выход шага';

  @override
  String get nodeConfigBackupRetentionDays => 'Удалить копии старше (дней)';

  @override
  String get nodeConfigBackupRetentionDaysHelp =>
      'Удаляются только копии этого рабочего пространства. Укажите положительное число дней.';

  @override
  String get diffLineDisplay => 'Длинные строки в diff';

  @override
  String get diffLineDisplayDescription =>
      'Переносить длинные строки или прокручивать их по горизонтали';

  @override
  String get diffLineWrap => 'Переносить';

  @override
  String get diffLineScroll => 'Прокручивать по горизонтали';

  @override
  String get actions => 'Действия';

  @override
  String get activate => 'Активировать';

  @override
  String get activity => 'Активность';

  @override
  String get activitySearchHint => 'Поиск по активности';

  @override
  String get activityNoMatches => 'Нет активности по заданным фильтрам';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end из $total';
  }

  @override
  String get activityPreviousPage => 'Предыдущая страница';

  @override
  String get activityNextPage => 'Следующая страница';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'Сбросить фильтр';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return 'Страна $country';
  }

  @override
  String get activitySavedWorkspaceLogo =>
      'Сохранён логотип рабочего пространства';

  @override
  String activityVerbCreated(String target) {
    return 'Создал $target';
  }

  @override
  String activityVerbUpdated(String target) {
    return 'Обновил $target';
  }

  @override
  String activityVerbDeleted(String target) {
    return 'Удалил $target';
  }

  @override
  String activityVerbAdded(String target) {
    return 'Добавил $target';
  }

  @override
  String activityVerbRemoved(String target) {
    return 'Убрал $target';
  }

  @override
  String activityVerbInvited(String target) {
    return 'Пригласил $target';
  }

  @override
  String activityVerbChanged(String target) {
    return 'Изменил $target';
  }

  @override
  String activityVerbStarted(String target) {
    return 'Запустил $target';
  }

  @override
  String activityVerbStopped(String target) {
    return 'Остановил $target';
  }

  @override
  String activityVerbWrote(String target) {
    return 'Записал $target';
  }

  @override
  String get activityTargetAgent => 'агент';

  @override
  String get activityTargetTicket => 'тикет';

  @override
  String get activityTargetWorkspace => 'рабочее пространство';

  @override
  String get activityTargetRepository => 'репозиторий';

  @override
  String get activityTargetMember => 'участника';

  @override
  String get activityTargetInvite => 'приглашение';

  @override
  String get activityTargetSpace => 'пространство';

  @override
  String get activityTargetMessage => 'сообщение';

  @override
  String get activityTargetCache => 'кэш';

  @override
  String get activityTargetFile => 'файл';

  @override
  String get activityTargetPipeline => 'конвейер';

  @override
  String get activityTargetTemplate => 'шаблон';

  @override
  String get activityTargetProvider => 'провайдер';

  @override
  String get activityTargetModel => 'модель';

  @override
  String get activityTargetSkill => 'навык';

  @override
  String get activityTargetTodo => 'задача';

  @override
  String get activityTargetMeeting => 'встреча';

  @override
  String get activityTargetProject => 'проект';

  @override
  String get activityTargetTeam => 'команда';

  @override
  String get activityTargetDevice => 'устройство';

  @override
  String get activityTargetPreference => 'настройка';

  @override
  String get activityTargetBudget => 'бюджет';

  @override
  String activityVerbApproved(String target) {
    return 'Одобрил $target';
  }

  @override
  String activityVerbArchived(String target) {
    return 'Архивировал $target';
  }

  @override
  String activityVerbAssigned(String target) {
    return 'Назначил $target';
  }

  @override
  String activityVerbBackedUp(String target) {
    return 'Создал резервную копию $target';
  }

  @override
  String activityVerbCancelled(String target) {
    return 'Отменил $target';
  }

  @override
  String activityVerbCleared(String target) {
    return 'Очистил $target';
  }

  @override
  String activityVerbClosed(String target) {
    return 'Закрыл $target';
  }

  @override
  String activityVerbCommitted(String target) {
    return 'Сделал коммит $target';
  }

  @override
  String activityVerbCompacted(String target) {
    return 'Уплотнил $target';
  }

  @override
  String activityVerbCompleted(String target) {
    return 'Завершил $target';
  }

  @override
  String activityVerbConnected(String target) {
    return 'Подключил $target';
  }

  @override
  String activityVerbContinued(String target) {
    return 'Продолжил $target';
  }

  @override
  String activityVerbDisconnected(String target) {
    return 'Отключил $target';
  }

  @override
  String activityVerbDispatched(String target) {
    return 'Отправил в работу $target';
  }

  @override
  String activityVerbDrained(String target) {
    return 'Опустошил $target';
  }

  @override
  String activityVerbEnrolled(String target) {
    return 'Поставил на учёт $target';
  }

  @override
  String activityVerbEstimated(String target) {
    return 'Оценил $target';
  }

  @override
  String activityVerbImported(String target) {
    return 'Импортировал $target';
  }

  @override
  String activityVerbInstalled(String target) {
    return 'Установил $target';
  }

  @override
  String activityVerbKilled(String target) {
    return 'Принудительно завершил $target';
  }

  @override
  String activityVerbMarked(String target) {
    return 'Отметил $target';
  }

  @override
  String activityVerbMerged(String target) {
    return 'Слил $target';
  }

  @override
  String activityVerbOpened(String target) {
    return 'Открыл $target';
  }

  @override
  String activityVerbPaused(String target) {
    return 'Приостановил $target';
  }

  @override
  String activityVerbPolled(String target) {
    return 'Опросил $target';
  }

  @override
  String activityVerbPrepared(String target) {
    return 'Подготовил $target';
  }

  @override
  String activityVerbProcessed(String target) {
    return 'Обработал $target';
  }

  @override
  String activityVerbPublished(String target) {
    return 'Опубликовал $target';
  }

  @override
  String activityVerbRefined(String target) {
    return 'Уточнил $target';
  }

  @override
  String activityVerbRefreshed(String target) {
    return 'Обновил $target';
  }

  @override
  String activityVerbRegistered(String target) {
    return 'Зарегистрировал $target';
  }

  @override
  String activityVerbRenamed(String target) {
    return 'Переименовал $target';
  }

  @override
  String activityVerbReordered(String target) {
    return 'Изменил порядок $target';
  }

  @override
  String activityVerbResponded(String target) {
    return 'Ответил на $target';
  }

  @override
  String activityVerbRestored(String target) {
    return 'Восстановил $target';
  }

  @override
  String activityVerbResumed(String target) {
    return 'Возобновил $target';
  }

  @override
  String activityVerbRetried(String target) {
    return 'Повторил $target';
  }

  @override
  String activityVerbReverted(String target) {
    return 'Откатил $target';
  }

  @override
  String activityVerbReviewed(String target) {
    return 'Проверил $target';
  }

  @override
  String activityVerbRan(String target) {
    return 'Запустил $target';
  }

  @override
  String activityVerbSelected(String target) {
    return 'Выбрал $target';
  }

  @override
  String activityVerbSent(String target) {
    return 'Отправил $target';
  }

  @override
  String activityVerbStaged(String target) {
    return 'Добавил в индекс $target';
  }

  @override
  String activityVerbSteered(String target) {
    return 'Скорректировал $target';
  }

  @override
  String activityVerbSubmitted(String target) {
    return 'Отправил на рассмотрение $target';
  }

  @override
  String activityVerbSynced(String target) {
    return 'Синхронизировал $target';
  }

  @override
  String activityVerbToggled(String target) {
    return 'Переключил $target';
  }

  @override
  String activityVerbUninstalled(String target) {
    return 'Удалил $target';
  }

  @override
  String activityVerbUnstaged(String target) {
    return 'Убрал из индекса $target';
  }

  @override
  String get activityTargetActionPolicy => 'политика действий';

  @override
  String get activityTargetGoalRun => 'запуск цели';

  @override
  String get activityTargetRunLog => 'журнал запуска';

  @override
  String get activityTargetWorkingMemory => 'рабочая память';

  @override
  String get activityTargetRoutingPolicy => 'политика маршрутизации';

  @override
  String get activityTargetAutonomy => 'автономия';

  @override
  String get activityTargetCalendar => 'календарь';

  @override
  String get activityTargetChecker => 'чекер';

  @override
  String get activityTargetEditor => 'редактор';

  @override
  String get activityTargetConfirmation => 'подтверждение';

  @override
  String get activityTargetTunnel => 'туннель';

  @override
  String get activityTargetConversation => 'разговор';

  @override
  String get activityTargetCredentials => 'учётные данные';

  @override
  String get activityTargetDictation => 'диктовка';

  @override
  String get activityTargetAgentRun => 'запуск агента';

  @override
  String get activityTargetEvalSuite => 'набор оценок';

  @override
  String get activityTargetWorker => 'воркер';

  @override
  String get activityTargetWorktree => 'рабочее дерево';

  @override
  String get activityTargetMcpServer => 'MCP-сервер';

  @override
  String get activityTargetMemoryAccessGrant => 'разрешение на доступ к памяти';

  @override
  String get activityTargetMemoryDomain => 'домен памяти';

  @override
  String get activityTargetMemoryFact => 'факт памяти';

  @override
  String get activityTargetMemoryPolicy => 'политика памяти';

  @override
  String get activityTargetFeed => 'лента';

  @override
  String get activityTargetNote => 'заметка';

  @override
  String get activityTargetOrchestration => 'оркестрация';

  @override
  String get activityTargetPipelineRun => 'запуск конвейера';

  @override
  String get activityTargetPipelineTrigger => 'триггер конвейера';

  @override
  String get activityTargetPlan => 'план';

  @override
  String get activityTargetPlaybook => 'плейбук';

  @override
  String get activityTargetPullRequest => 'pull request';

  @override
  String get activityTargetReview => 'ревью';

  @override
  String get activityTargetProcess => 'процесс';

  @override
  String get activityTargetProviderPolicy => 'политика провайдера';

  @override
  String get activityTargetReaction => 'реакция';

  @override
  String get activityTargetReviewSpace => 'пространство ревью';

  @override
  String get activityTargetReviewStudio => 'студия ревью';

  @override
  String get activityTargetServerData => 'данные сервера';

  @override
  String get activityTargetSoundscape => 'звуковая среда';

  @override
  String get activityTargetSession => 'сессия';

  @override
  String get activityTargetTerminal => 'терминал';

  @override
  String get activityTargetTicketLink => 'ссылка на тикет';

  @override
  String get activityTargetTicketSync => 'синхронизация тикетов';

  @override
  String get activityTargetProfile => 'профиль';

  @override
  String get activityTargetVoiceProfile => 'голосовой профиль';

  @override
  String get activityTargetWeather => 'прогноз погоды';

  @override
  String get activityTargetWorkProduct => 'рабочий продукт';

  @override
  String get activityChangedMemberRole => 'Изменена роль участника';

  @override
  String get activityChangedMemberRepoAccess =>
      'Изменён доступ участника к репозиторию';

  @override
  String get activityRefreshedWeather => 'Обновлён прогноз погоды';

  @override
  String get activitySetWeatherLocation => 'Задано местоположение для погоды';

  @override
  String get activityClearedWeatherLocation =>
      'Очищено местоположение для погоды';

  @override
  String get activityMarkedAllArticlesRead =>
      'Все статьи отмечены как прочитанные';

  @override
  String get activityMarkedArticleRead => 'Статья отмечена как прочитанная';

  @override
  String get activityUpdatedSavedArticle => 'Обновлена сохранённая статья';

  @override
  String get activityTookOverSession => 'Сессия перехвачена';

  @override
  String get activityHandedBackSession => 'Сессия возвращена';

  @override
  String get activityCommittedAndPushed => 'Сделан коммит и push';

  @override
  String get activityBackedUpServer => 'Создана резервная копия данных сервера';

  @override
  String get activityRespondedToInvitation => 'Ответ на приглашение на событие';

  @override
  String get activityDisconnectedCalendar => 'Отключил календарь';

  @override
  String get activityMarkedFileViewed => 'Отметил файл как просмотренный';

  @override
  String get activityRespondedToApproval => 'Ответил на запрос на одобрение';

  @override
  String get activityChangedTunnel => 'Изменил настройку туннеля';

  @override
  String get activitySentMessageToAgent => 'Отправил сообщение агенту';

  @override
  String get activityOpenedReviewSpace => 'Открыл пространство ревью';

  @override
  String get activityOpenedStandingConversation => 'Открыл постоянную беседу';

  @override
  String get activityStartedRecording => 'Начал запись';

  @override
  String get activityStoppedRecording => 'Остановил запись';

  @override
  String get activityToggledMcpServer => 'Переключил MCP-сервер';

  @override
  String get activitySavedApiKey => 'Сохранил API-ключ';

  @override
  String get activityRemovedProviderCredential =>
      'Удалил учётные данные провайдера';

  @override
  String get activityUpdatedLinkedRepos => 'Обновил связанные репозитории';

  @override
  String get activityUnlinkedRepo => 'Отвязал репозиторий';

  @override
  String get activityUpdatedActionItem => 'Обновил пункт действий';

  @override
  String adRulesCount(int count) {
    return '$count ad rules';
  }

  @override
  String get adapter => 'Адаптер';

  @override
  String get adapterLabel => 'Адаптер';

  @override
  String get adapters => 'Адаптеры';

  @override
  String get adaptersAutoDetected =>
      'Автоматически обнаруженные раннеры агентов на этой машине. Установите недостающие CLI-инструменты, чтобы включить дополнительные раннеры.';

  @override
  String get add => 'Добавить';

  @override
  String get addAComment => 'Добавить комментарий';

  @override
  String get addAReaction => 'Добавить реакцию';

  @override
  String get addASuggestion => 'Добавить предложение';

  @override
  String get addAgents => 'Добавить агентов';

  @override
  String get addEmoji => 'Добавить эмодзи';

  @override
  String get addFeed => 'Добавить ленту';

  @override
  String get addressBarHint => 'Введите URL';

  @override
  String get addFromFile => 'Добавить из файла';

  @override
  String get addGif => 'Добавить GIF';

  @override
  String get addLocalCheckoutDescription =>
      'Добавьте локальный checkout, чтобы начать работать с ним из этого рабочего пространства.';

  @override
  String get addRepository => 'Добавить репозиторий';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Добавить $count репозитория',
      many: 'Добавить $count репозиториев',
      few: 'Добавить $count репозитория',
      one: 'Добавить репозиторий',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'Просмотрите папки на машине, где запущен сервер, и выберите git-checkout’ы для регистрации.';

  @override
  String get selectThisFolder => 'Выбрать эту папку';

  @override
  String get deselectThisFolder => 'Снять выбор с этой папки';

  @override
  String get goUp => 'Вверх';

  @override
  String get noSubfoldersHere => 'Здесь нет вложенных папок';

  @override
  String get notAGitRepository => 'Эта папка не является git-репозиторием.';

  @override
  String get addToken => 'Добавить токен';

  @override
  String get addWorkspace => 'Добавить рабочее пространство';

  @override
  String get addWorkspaceEllipsis => 'Добавить рабочее пространство…';

  @override
  String get added => 'Добавлено';

  @override
  String get addingEllipsis => 'Добавление…';

  @override
  String get advancedLabel => 'Дополнительно';

  @override
  String get agent => 'Агент';

  @override
  String conversationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count беседы',
      many: '$count бесед',
      few: '$count беседы',
      one: '$count беседа',
    );
    return '$_temp0';
  }

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
  String get agentMdPath => 'Путь к MD агента';

  @override
  String get agentName => 'Имя агента';

  @override
  String get agentTitle => 'Название агента';

  @override
  String get agentUpdated => 'Агент обновлён.';

  @override
  String get agents => 'Агенты';

  @override
  String get agentsMentionSection => 'Агенты';

  @override
  String get usersMentionSection => 'Люди';

  @override
  String get ticketsMentionSection => 'Тикеты';

  @override
  String get pullRequestsMentionSection => 'Pull requests';

  @override
  String get meetingsMentionSection => 'Встречи';

  @override
  String get entityRefTicketFallback => 'Тикет';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'Встреча';

  @override
  String get aiReview => 'AI-ревью';

  @override
  String get all => 'Все';

  @override
  String get allAgentsAlreadyInSpace => 'Все агенты уже в этом пространстве.';

  @override
  String get allCommits => 'Все коммиты';

  @override
  String get allSources => 'Все источники';

  @override
  String get allow => 'Разрешить';

  @override
  String get apiKeys => 'Ключи API';

  @override
  String get appFont => 'Шрифт приложения';

  @override
  String get appLogLevelDebugDescription =>
      'Добавляет подробные трассировки — для разработки.';

  @override
  String get appLogLevelDebugLabel => 'Отладка';

  @override
  String get appLogLevelErrorDescription =>
      'Только неожиданные ошибки и исключения.';

  @override
  String get appLogLevelErrorLabel => 'Ошибка';

  @override
  String get appLogLevelInfoDescription =>
      'Добавляет сообщения о жизненном цикле и статусе.';

  @override
  String get appLogLevelInfoLabel => 'Информация';

  @override
  String get appLogLevelNoneDescription => 'Без вывода в консоль.';

  @override
  String get appLogLevelNoneLabel => 'Нет';

  @override
  String get appLogLevelVerboseDescription =>
      'Всё. Очень подробно — только для отладки.';

  @override
  String get appLogLevelVerboseLabel => 'Подробно';

  @override
  String get appLogLevelWarningDescription =>
      'Добавляет предупреждения и устранимые проблемы.';

  @override
  String get appLogLevelWarningLabel => 'Предупреждение';

  @override
  String get appearanceLanguage => 'Внешний вид и язык';

  @override
  String get apply => 'Применить';

  @override
  String get approve => 'Одобрить';

  @override
  String get agentApprovalRequired => 'Требуется одобрение';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ещё $count ожидают',
      many: 'ещё $count ожидают',
      few: 'ещё $count ожидают',
      one: 'ещё $count ожидает',
    );
    return '$_temp0';
  }

  @override
  String get approved => 'Одобрено';

  @override
  String get articleNoun => 'Статья';

  @override
  String get articlesSubscribed => 'Статьи из ваших подписок.';

  @override
  String get askAi => 'Спросить AI';

  @override
  String get askAiReviewDescription => 'Попросить AI сделать ревью этого PR';

  @override
  String get assignees => 'Исполнители';

  @override
  String get attachImage => 'Прикрепить изображение';

  @override
  String get attachedAgents => 'Прикреплённые агенты';

  @override
  String get audioInput => 'Аудиовход';

  @override
  String get audioOutput => 'Аудиовыход';

  @override
  String get authenticationToken => 'Токен аутентификации';

  @override
  String authoredByLabel(String role) {
    return 'Автор: $role';
  }

  @override
  String get autoRecommended => 'Автоматически (рекомендуется)';

  @override
  String get available => 'Доступно';

  @override
  String get awaitingYourReview => 'Ожидает вашего ревью';

  @override
  String get back => 'Назад';

  @override
  String get backLabel => 'Назад';

  @override
  String get backend => 'Бэкенд';

  @override
  String get blockAdsTrackers =>
      'Блокировать рекламу, трекеры и баннеры cookie';

  @override
  String get blocking => 'Блокирует';

  @override
  String get bookmarkLabel => 'Закладка';

  @override
  String get briefDescription => 'Краткое описание';

  @override
  String get bugLabel => 'Баг';

  @override
  String get bundledDefaultsNeverUpdated =>
      'Встроенные значения по умолчанию — не обновляются';

  @override
  String get cancel => 'Отмена';

  @override
  String get cancelEdit => 'Отменить правку';

  @override
  String get categoryNavigation => 'Навигация';

  @override
  String get change => 'Изменить';

  @override
  String get changesRequested => 'Запрошены изменения';

  @override
  String get spacesMentionSection => 'Пространства';

  @override
  String get checkForUpdates => 'Проверить обновления';

  @override
  String get checking => 'Проверка';

  @override
  String get checkingEllipsis => 'Проверка…';

  @override
  String get chooseAppFont => 'Выберите шрифт приложения';

  @override
  String get chooseCodeFont => 'Выберите шрифт кода';

  @override
  String get chooseRunner => 'Выберите раннер агента.';

  @override
  String get clear => 'Очистить';

  @override
  String get clickToRetry => 'Нажмите, чтобы повторить';

  @override
  String get close => 'Закрыть';

  @override
  String get closeEsc => 'Закрыть (Esc)';

  @override
  String get closeReader => 'Закрыть режим чтения';

  @override
  String get closed => 'Закрыто';

  @override
  String get codeFont => 'Шрифт кода';

  @override
  String get codeFontLigatures => 'Лигатуры шрифта кода';

  @override
  String get codeFontLigaturesDescription =>
      'Отображать программные лигатуры (=>, !=, ->) объединёнными глифами в коде и diff';

  @override
  String get collapse => 'Свернуть';

  @override
  String get commandPalette => 'Палитра команд';

  @override
  String get commandPaletteOrgMembers => 'Участники организации';

  @override
  String get commandPaletteBrowseTeam => 'Обзор команды';

  @override
  String get commandPaletteBrowseTeamDesc =>
      'Показать всех участников организации';

  @override
  String get compactDone =>
      'Разговор сжат. Более ранняя история свёрнута в сводку.';

  @override
  String get compactNothing => 'Пока нечего сжимать. Разговор ещё короткий.';

  @override
  String get compactBusy =>
      'Агент ещё работает. Сжимайте, когда ход завершится.';

  @override
  String get compactUnavailable => 'Сжатие недоступно на этом сервере.';

  @override
  String get commandsMentionSection => 'Команды';

  @override
  String get comment => 'Комментировать';

  @override
  String get commentOnThisFile => 'Комментировать этот файл';

  @override
  String get commented => 'Прокомментировано';

  @override
  String get commits => 'Коммиты';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Показаны последние $loaded из $total коммитов';
  }

  @override
  String get prCloneProgressCloningTitle => 'Клонирование репозитория';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'Этот PR изменяет $fileCount файлов — это превышает лимит API GitHub. Клонируем репозиторий локально…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'Этот PR превышает лимит файлов API GitHub. Клонируем репозиторий локально…';

  @override
  String get prCloneProgressFetchingTitle => 'Загрузка refs PR';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Загрузка базовой ветки и head ref PR…';

  @override
  String get prCloneProgressComputingTitle => 'Вычисление diff';

  @override
  String get prCloneProgressComputingSubtitle =>
      'Выполняется git diff локально…';

  @override
  String get prCloneProgressErrorTitle => 'Не удалось загрузить diff';

  @override
  String get prCloneProgressErrorSubtitle =>
      'Ошибка при клонировании или вычислении diff. Попробуйте обновить.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Ещё работаем… прошло $elapsed';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Уверенность: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'Настройте личности агентов, промпты, навыки и просматривайте запуски.';

  @override
  String get configuredLabel => 'Настроено.';

  @override
  String get confirmedBy => 'Подтвердил';

  @override
  String get consensus => 'Консенсус';

  @override
  String get contentHint => 'Что нужно запомнить';

  @override
  String get contentLabel => 'Содержимое';

  @override
  String get contentMarkdown => 'Содержимое (Markdown)';

  @override
  String get contextWindowSize => 'Размер контекстного окна';

  @override
  String modelContextChip(String size) {
    return 'Модель · $size';
  }

  @override
  String get continueLabel => 'Продолжить';

  @override
  String get conversationMode => 'Режим';

  @override
  String cookieRulesCount(int count) {
    return '$count cookie rules';
  }

  @override
  String typeToConfirmPrompt(String value) {
    return 'Введите $value для подтверждения.';
  }

  @override
  String get copied => 'Скопировано!';

  @override
  String get copy => 'Копировать';

  @override
  String get copyAddress => 'Копировать адрес';

  @override
  String get copyBaseBranchTooltip => 'Копировать имя базовой ветки';

  @override
  String get copyHeadBranchTooltip => 'Копировать имя ветки head';

  @override
  String couldNotListDevices(String error) {
    return 'Не удалось получить список устройств: $error';
  }

  @override
  String get create => 'Создать';

  @override
  String get createOrSelectWorkspace =>
      'Создайте или выберите рабочее пространство, прежде чем добавлять репозитории.';

  @override
  String get createPullRequest => 'Создать pull request';

  @override
  String get createdByMe => 'Созданные мной';

  @override
  String createdLabel(String date) {
    return 'Создано: $date';
  }

  @override
  String get currentParticipants => 'Текущие участники';

  @override
  String get customSystemPrompt =>
      'Пользовательский системный промпт для этого агента...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня назад',
      many: '$count дней назад',
      few: '$count дня назад',
      one: '$count день назад',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Деактивировать';

  @override
  String get delete => 'Удалить';

  @override
  String get deleteAgent => 'Удалить агента';

  @override
  String deleteAgentConfirm(String name) {
    return 'Удалить «$name»? Это действие нельзя отменить.';
  }

  @override
  String get deleteSpace => 'Удалить пространство';

  @override
  String deleteConfirmName(String name) {
    return 'Удалить «$name»?';
  }

  @override
  String get deleteFact => 'Удалить факт';

  @override
  String get deleteFeedBody =>
      'Лента и все её кэшированные статьи будут удалены. Закладки статей из этой ленты также будут удалены.';

  @override
  String deleteFeedConfirm(String name) {
    return 'Удалить «$name»?';
  }

  @override
  String get deletePolicy => 'Удалить политику';

  @override
  String get deletePolicyConfirm =>
      'Удалить эту политику? Это действие нельзя отменить.';

  @override
  String deleteTopicConfirm(String topic) {
    return 'Удалить «$topic»? Это действие нельзя отменить.';
  }

  @override
  String get deleteWorkspace => 'Удалить рабочее пространство';

  @override
  String get deny => 'Отклонить';

  @override
  String get detailsLabel => 'Подробности';

  @override
  String get descriptionLabel => 'Описание';

  @override
  String detectedBackend(String label) {
    return 'Обнаружено: $label';
  }

  @override
  String get detectedRunners => 'Обнаруженные раннеры';

  @override
  String get detectingAdapters => 'Обнаружение адаптеров…';

  @override
  String get detectingInputDevices => 'Обнаружение устройств ввода…';

  @override
  String detectionFailed(String error) {
    return 'Ошибка обнаружения: $error';
  }

  @override
  String get disabled => 'Отключено';

  @override
  String get discover => 'Обнаружить';

  @override
  String get dismissed => 'Отклонено';

  @override
  String get domainHint => 'напр. api-performance';

  @override
  String get domainLabel => 'Домен';

  @override
  String get download => 'Скачать';

  @override
  String get downloadingLabel => 'Скачивание';

  @override
  String downloadingModel(int pct) {
    return 'Скачивание модели… $pct%';
  }

  @override
  String get draft => 'Черновик';

  @override
  String get draftLabel => 'Черновик';

  @override
  String get edit => 'Изменить';

  @override
  String get edited => 'изменено';

  @override
  String get editMessage => 'Изменить сообщение';

  @override
  String get revertToThere => 'Откатить дотуда';

  @override
  String get sendAsNewMessage => 'Отправить как новое сообщение';

  @override
  String get editMessageChoiceBody =>
      'Откат скрывает сообщения после этого и возвращает файлы агента. Это можно отменить. Отправка новым сообщением оставляет разговор как есть.';

  @override
  String get deleteMessage => 'Удалить сообщение';

  @override
  String get deleteMessageConfirm =>
      'Удалить это сообщение? Это действие нельзя отменить.';

  @override
  String get messageDeleted => 'Сообщение удалено';

  @override
  String get searchInConversation => 'Поиск в беседе';

  @override
  String get searchMessagesHint => 'Поиск сообщений…';

  @override
  String get noMessagesFound => 'Сообщения не найдены';

  @override
  String get editFact => 'Изменить факт';

  @override
  String get editPolicy => 'Изменить политику';

  @override
  String get editSuggestedCodeHint => 'Изменить предложенный код…';

  @override
  String get editSuggestion => 'Предложение правки';

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
    return 'Не удалось установить: $error';
  }

  @override
  String get embeddingInstalled =>
      'Локальная модель эмбеддингов установлена. Гибридный поиск включён.';

  @override
  String get embeddingModel => 'Модель эмбеддингов (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Не установлена. Пока не включите, поиск работает только по ключевым словам.';

  @override
  String get embeddingRedownloadBody =>
      'Существующие файлы модели будут удалены и скачаны заново. Семантический поиск будет недоступен, пока загрузка не завершится.';

  @override
  String get embeddingRemoveBody =>
      'Семантический поиск будет отключён, пока вы не установите модель снова. Установить её можно в любой момент.';

  @override
  String get speakerDiarization => 'Диаризация спикеров';

  @override
  String get diarizationModel => 'Модель диаризации';

  @override
  String get diarizationInstalled =>
      'Установлена — в расшифровках встреч именуются отдельные спикеры';

  @override
  String get diarizationNotInstalled =>
      'Не установлена — спикеры на встречах не разделяются';

  @override
  String diarizationInstallFailed(String error) {
    return 'Не удалось установить: $error';
  }

  @override
  String get redownloadDiarizationModel => 'Скачать модель диаризации заново';

  @override
  String get diarizationRedownloadBody =>
      'Текущие модели диаризации будут удалены и скачаны заново.';

  @override
  String get removeDiarizationModel => 'Удалить модель диаризации';

  @override
  String get diarizationRemoveBody =>
      'Удаляет локальные модели диаризации. Уже созданные расшифровки встреч не изменятся.';

  @override
  String get enableNotifications => 'Включить уведомления';

  @override
  String get enableSandboxing => 'Включить песочницу';

  @override
  String get enabled => 'Включено';

  @override
  String errorCreatingAgent(String error) {
    return 'Ошибка создания агента: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Ошибка удаления агента: $error';
  }

  @override
  String errorWithDetail(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get expand => 'Развернуть';

  @override
  String extractingModel(int pct) {
    return 'Распаковка модели… $pct%';
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
  String get facts => 'Факты';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount фактов · $policyCount политик';
  }

  @override
  String get failed => 'Не удалось';

  @override
  String failedToDispatch(String error) {
    return 'Не удалось отправить: $error';
  }

  @override
  String get failedToLoad => 'Не удалось загрузить';

  @override
  String failedToLoadAgents(String error) {
    return 'Не удалось загрузить агентов: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Не удалось загрузить ленты: $error';
  }

  @override
  String get failedToLoadGifs => 'Не удалось загрузить GIF';

  @override
  String failedToLoadLogs(String error) {
    return 'Не удалось загрузить журналы: $error';
  }

  @override
  String get failedToLoadRepos => 'Не удалось загрузить репозитории';

  @override
  String get failedToLoadWorkspaces =>
      'Не удалось загрузить рабочие пространства';

  @override
  String failedToStartAiReview(String error) {
    return 'Не удалось запустить ИИ-ревью: $error';
  }

  @override
  String get failedToStartMicTest => 'Не удалось начать проверку микрофона.';

  @override
  String failedToSubmitReview(String error) {
    return 'Не удалось отправить ревью: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'Не удалось загрузить $name: $error';
  }

  @override
  String failedWithError(String error) {
    return 'Сбой: $error';
  }

  @override
  String get failure => 'Сбой';

  @override
  String get feedAlreadyExists => 'Лента с таким URL уже существует.';

  @override
  String get feedUrlExample => 'напр. https://example.com/feed.xml';

  @override
  String get feedUrlLabel => 'URL ленты';

  @override
  String feedsCount(int count) {
    return 'Ленты ($count)';
  }

  @override
  String get filesChanged => 'Изменённые файлы';

  @override
  String filesCount(int count) {
    return '$count file(s)';
  }

  @override
  String get filesMentionSection => 'Файлы';

  @override
  String get filterAgents => 'Фильтр агентов...';

  @override
  String get filterFilesHint => 'Фильтр файлов…';

  @override
  String get filterLists => 'Фильтровать списки';

  @override
  String get filterSkillsPlaceholder => 'Фильтровать навыки…';

  @override
  String get finish => 'Завершить';

  @override
  String get fix => 'Исправить';

  @override
  String get forward => 'Вперёд';

  @override
  String get general => 'Общие';

  @override
  String get githubLink => 'Ссылка на GitHub';

  @override
  String get claudeStatusFetchFailed =>
      'Не удалось подключиться к status.claude.com';

  @override
  String get claudeStatusOpenInBrowser => 'Открыть status.claude.com';

  @override
  String get githubStatusFetchFailed =>
      'Не удалось подключиться к githubstatus.com';

  @override
  String get githubDegradedTitle => 'GitHub сообщает о проблемах';

  @override
  String githubDegradedStatusLine(String status) {
    return 'Статус GitHub: $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'Статус GitHub: $status. Данные pull request могут быть устаревшими или неполными, пока сервис не восстановится.';
  }

  @override
  String get githubStatusOpenInBrowser => 'Открыть githubstatus.com';

  @override
  String get githubStatusRefresh => 'Обновить';

  @override
  String githubStatusUpdated(String time) {
    return 'Обновлено $time';
  }

  @override
  String get kimiStatusFetchFailed =>
      'Не удалось подключиться к status.moonshot.cn';

  @override
  String get kimiStatusOpenInBrowser => 'Открыть status.moonshot.cn';

  @override
  String get openaiStatusFetchFailed =>
      'Не удалось подключиться к status.openai.com';

  @override
  String get openaiStatusOpenInBrowser => 'Открыть status.openai.com';

  @override
  String get serviceStatusMaintenance => 'Обслуживание';

  @override
  String get serviceStatusMajorIssues => 'Серьёзные проблемы';

  @override
  String get serviceStatusMinorIssues => 'Незначительные проблемы';

  @override
  String get serviceStatusOperational => 'Работает';

  @override
  String get serviceStatusOutage => 'Сбой';

  @override
  String serviceStatusOverflowCount(int count) {
    return '$count+';
  }

  @override
  String get serviceStatusTitle => 'Статус сервиса';

  @override
  String get serviceStatusUnknown => 'Неизвестно';

  @override
  String lastChecked(String time) {
    return 'Проверено $time';
  }

  @override
  String get lastCheckedRecently => 'Проверено недавно';

  @override
  String get giveYourWorkAHome => 'Дайте работе дом.';

  @override
  String get goBack => 'Назад';

  @override
  String get goForward => 'Вперёд';

  @override
  String get googleFonts => 'Шрифты Google';

  @override
  String get high => 'Высокий';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count часа назад',
      many: '$count часов назад',
      few: '$count часа назад',
      one: '$count час назад',
    );
    return '$_temp0';
  }

  @override
  String get sidebarAgeNow => 'сейчас';

  @override
  String sidebarAgeMinutes(int count) {
    return '$count мин';
  }

  @override
  String sidebarAgeHours(int count) {
    return '$count ч';
  }

  @override
  String sidebarAgeDays(int count) {
    return '$count д';
  }

  @override
  String sidebarAgeMonths(int count) {
    return '$count мес.';
  }

  @override
  String sidebarAgeYears(int count) {
    return '$count г';
  }

  @override
  String get images => 'Изображения';

  @override
  String get inactive => 'Неактивно';

  @override
  String get install => 'Установить';

  @override
  String installedVersion(String version) {
    return 'Установлено $version';
  }

  @override
  String get invite => 'Пригласить';

  @override
  String get inviteAgent => 'Пригласить агента';

  @override
  String get isolateAgentExecution => 'Изолировать выполнение агента.';

  @override
  String get justNow => 'Только что';

  @override
  String get keepSandboxing => 'Оставить песочницу';

  @override
  String get keybindingAddRepository => 'Добавить репозиторий';

  @override
  String get keybindingCommandPalette => 'Палитра команд';

  @override
  String get keybindingFocusSearch => 'Перейти к поиску';

  @override
  String get keybindingNewAgent => 'Новый агент';

  @override
  String get keybindingNewWorkspace => 'Новое рабочее пространство';

  @override
  String get keybindingNextArticle => 'Следующая статья';

  @override
  String get keybindingNextSpace => 'Следующее пространство';

  @override
  String get keybindingNextWorkspace => 'Следующее рабочее пространство';

  @override
  String get keybindingOpenArticle => 'Открыть статью';

  @override
  String get keybindingOpenPr => 'Открыть PR';

  @override
  String get keybindingOpenSettings => 'Открыть настройки';

  @override
  String get keybindingOpenWorkspace => 'Открыть рабочее пространство';

  @override
  String get keybindingPreviousArticle => 'Предыдущая статья';

  @override
  String get keybindingPreviousSpace => 'Предыдущее пространство';

  @override
  String get keybindingPreviousWorkspace => 'Предыдущее рабочее пространство';

  @override
  String get keybindingRefresh => 'Обновить';

  @override
  String get keybindingSendMessage => 'Отправить сообщение';

  @override
  String get keybindingToggleBookmark => 'Переключить закладку';

  @override
  String get keybindingToggleTheme => 'Переключить тему';

  @override
  String get keybindingToggleWorkspaceSwitcher =>
      'Переключатель рабочих пространств';

  @override
  String get keybindingWorkspace1 => 'Рабочее пространство 1';

  @override
  String get keybindingWorkspace2 => 'Рабочее пространство 2';

  @override
  String get keybindingWorkspace3 => 'Рабочее пространство 3';

  @override
  String get keybindingWorkspace4 => 'Рабочее пространство 4';

  @override
  String get keybindingWorkspace5 => 'Рабочее пространство 5';

  @override
  String get keybindingWorkspace6 => 'Рабочее пространство 6';

  @override
  String get keybindingWorkspace7 => 'Рабочее пространство 7';

  @override
  String get keybindingWorkspace8 => 'Рабочее пространство 8';

  @override
  String get keybindingWorkspace9 => 'Рабочее пространство 9';

  @override
  String get killRunning => 'Прервать выполнение';

  @override
  String get languageSystem => 'Системный';

  @override
  String get leaveACommentEllipsis => 'Оставить комментарий…';

  @override
  String get legendLabel => 'Легенда';

  @override
  String get lessLabel => 'Меньше';

  @override
  String get letsPluginTools => 'Подключим ваши инструменты.';

  @override
  String get level => 'Уровень';

  @override
  String get loadingAgents => 'Загрузка агентов…';

  @override
  String get loadingModels => 'Загрузка моделей…';

  @override
  String get loadingProviders => 'Загрузка провайдеров…';

  @override
  String get logLevel => 'Уровень журнала';

  @override
  String get logs => 'Журнал';

  @override
  String get low => 'Низкий';

  @override
  String get maintenance => 'Обслуживание';

  @override
  String get manageParticipants => 'Управлять участниками';

  @override
  String get manageWorkspaces => 'Управлять рабочими пространствами';

  @override
  String get reorderWorkspace => 'Изменить порядок рабочего пространства';

  @override
  String get matchOsAppearance =>
      'Соответствовать оформлению ОС или выбрать фиксированный режим.';

  @override
  String get mcpNotAvailableOnServer =>
      'Управление MCP-сервером недоступно на подключённом сервере.';

  @override
  String get modelManagedOnServer =>
      'Эта модель работает на хосте сервера и управляется там.';

  @override
  String get mcpServer => 'MCP-сервер';

  @override
  String get medium => 'Средний';

  @override
  String get memoryDataHint =>
      'Факты и политики будут появляться здесь по мере работы агентов.';

  @override
  String get memoryLabel => 'Память';

  @override
  String get merge => 'Слить';

  @override
  String get merged => 'Слито';

  @override
  String get messagePlaceholder => 'Сообщение… (@ — упоминание, / — команды)';

  @override
  String get navConversations => 'Пространства';

  @override
  String get microphonePermissionDenied => 'Доступ к микрофону запрещён.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count минут назад',
      many: '$count минут назад',
      few: '$count минуты назад',
      one: '$count минуту назад',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Модель';

  @override
  String get modified => 'Изменено';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count месяцев назад',
      many: '$count месяцев назад',
      few: '$count месяца назад',
      one: '$count месяц назад',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => 'Ещё';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Имя';

  @override
  String get nameAndTitleRequired => 'Имя и название обязательны.';

  @override
  String get nameAndUrlRequired => 'Имя и URL обязательны';

  @override
  String get nameLabel => 'Имя';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Нативная песочница доступна на $platform.';
  }

  @override
  String get nativeSandboxNeedsInstall =>
      'Требуется установка нативной песочницы';

  @override
  String get navObservability => 'Наблюдаемость';

  @override
  String get navSettings => 'Настройки';

  @override
  String get exitSettings => 'Выйти из настроек';

  @override
  String networkBlockCount(int count) {
    return '$count сетевых блокировок';
  }

  @override
  String get neutral => 'Нейтральный';

  @override
  String get newCommitsPushed =>
      'Появились новые коммиты — нажмите, чтобы обновить diff';

  @override
  String get newFact => 'Новый факт';

  @override
  String get newPolicy => 'Новая политика';

  @override
  String get newsfeed => 'Лента новостей';

  @override
  String get newsfeedLabel => 'Лента новостей';

  @override
  String get newsfeedSettingsDescription =>
      'Управляйте подписками и настройками чтения.';

  @override
  String get newsfeedSettingsTitle => 'Настройки ленты новостей';

  @override
  String get nextMatch => 'Следующее совпадение (↵)';

  @override
  String get noActiveWorkspace =>
      'Не выбрано активное рабочее пространство или репозиторий.';

  @override
  String get noActiveWorkspaceCreate => 'Нет активного рабочего пространства';

  @override
  String get noActiveWorkspaceGithub =>
      'Нет активного рабочего пространства с репозиторием GitHub.';

  @override
  String get noAgents => 'Нет агентов';

  @override
  String get noArticlesYet => 'Пока нет статей';

  @override
  String get noArticlesYetBody => 'Статьи из ваших лент появятся здесь.';

  @override
  String get noExecutionLogsYet => 'Пока нет журналов выполнения';

  @override
  String get noFacts => 'Пока нет фактов';

  @override
  String get noFeedsYet => 'Пока нет лент';

  @override
  String get noFileAnchor =>
      'Нет привязки к файлу — нельзя оставить внутристрочный комментарий.';

  @override
  String get noFileChangesInScope => 'В этой области нет изменений файлов';

  @override
  String get noGifsFound => 'GIF не найдены';

  @override
  String get noInputDevicesDetected =>
      'Устройства ввода не обнаружены — используется системное по умолчанию.';

  @override
  String get noMatchingFiles => 'Нет подходящих файлов';

  @override
  String get noMatchingGoogleFonts => 'Нет подходящих Google Fonts.';

  @override
  String get noMemoryData => 'Пока нет данных памяти';

  @override
  String get noMessagesYet => 'Пока нет сообщений';

  @override
  String get noModelsAdvertised => 'Этот адаптер не объявил модели.';

  @override
  String get noOpenPullRequests => 'Нет открытых pull request';

  @override
  String get noPolicies => 'Пока нет политик';

  @override
  String get noReposInWorkspaceYet =>
      'В этом рабочем пространстве пока нет репозиториев';

  @override
  String get noRunnersDetected =>
      'Раннеры пока не обнаружены. Обновите, чтобы просканировать снова.';

  @override
  String get noSavedArticles => 'Нет сохранённых статей';

  @override
  String get noSavedArticlesBody => 'Сохранённые статьи появятся здесь.';

  @override
  String get noSystemFonts => 'Системные шрифты не обнаружены.';

  @override
  String get noWorkingMemory => 'Пока нет заметок рабочей памяти.';

  @override
  String get noneAllRoles => 'Нет (все роли)';

  @override
  String get notAvailable => 'Недоступно';

  @override
  String get notConfiguredLabel => 'Не настроено.';

  @override
  String get notFoundLabel => 'Не найдено';

  @override
  String get notes => 'Заметки';

  @override
  String get notificationAgentFinished => 'Агент завершил работу';

  @override
  String get notificationPrMentioned => 'Упоминание в pull request';

  @override
  String get notificationNewMessages => 'Новые сообщения';

  @override
  String get notificationPrMerged => 'PR объединён';

  @override
  String get notificationPrPublished => 'PR опубликован';

  @override
  String get notificationReviewRequested => 'Запрошено ревью';

  @override
  String get notifications => 'Уведомления';

  @override
  String get notifyAgentRunCompleted =>
      'Уведомлять, когда агент завершает запуск.';

  @override
  String get notifyPrMentioned =>
      'Уведомлять, когда вас упоминают в pull request.';

  @override
  String get notifyNewMessages =>
      'Уведомлять, когда вас упоминают в пространстве.';

  @override
  String get notifyPrMerged => 'Уведомлять, когда pull request объединяется.';

  @override
  String get notifyPrPublished =>
      'Уведомлять, когда агент публикует pull request.';

  @override
  String get notifyReviewRequested =>
      'Уведомлять, когда у вас запрашивают ревью pull request.';

  @override
  String get notificationReviewStale => 'Ревью устарело';

  @override
  String get notifyReviewStale =>
      'Когда в уже проверенный вами pull request попадают новые коммиты';

  @override
  String get notificationPrMergeReadiness => 'Готово к слиянию';

  @override
  String get notifyPrMergeReadiness =>
      'Уведомлять, когда созданный вами pull request становится готовым к слиянию или перестаёт быть таковым.';

  @override
  String get notificationPrReviewDecision => 'Решения по ревью';

  @override
  String get notifyPrReviewDecision =>
      'Уведомлять, когда рецензент одобряет, запрашивает изменения или когда одобрение отклоняется.';

  @override
  String get notificationPrChecksStatus => 'Проверки';

  @override
  String get notifyPrChecksStatus =>
      'Уведомлять, когда CI падает на созданном вами pull request и когда восстанавливается.';

  @override
  String get notificationPrThreadActivity => 'Ветки обсуждения';

  @override
  String get notifyPrThreadActivity =>
      'Уведомлять, когда кто-то отвечает в ветке, в которой вы участвуете, или закрывает её.';

  @override
  String get notificationPrReadyToMerge => 'Готово к слиянию';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return 'У $prTitle есть всё необходимое.';
  }

  @override
  String get notificationPrMergeBlocked => 'Больше нельзя слить';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '$prTitle конфликтует с базовой веткой.';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '$prTitle отстаёт от базовой ветки.';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '$prTitle ожидает обязательное ревью.';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'Рецензент запросил изменения в $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return 'Проверки не проходят для $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '$prTitle больше нельзя слить.';
  }

  @override
  String get notificationPrApproved => 'Pull request одобрен';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '$login одобрил $prTitle';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '$prTitle одобрен';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ещё $count рецензента',
      many: 'ещё $count рецензентов',
      few: 'ещё $count рецензента',
      one: 'ещё 1 рецензент',
      zero: 'не осталось рецензентов',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => 'Запрошены изменения';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '$login запросил изменения в $prTitle';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return 'Для $prTitle запрошены изменения';
  }

  @override
  String get notificationPrReviewDismissed => 'Одобрение отозвано';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '$prTitle снова нужно ревью.';
  }

  @override
  String get notificationPrChecksFailed => 'Проверки не прошли';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '$checkName не прошла в $prTitle';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return 'Проверки не проходят в $prTitle';
  }

  @override
  String get notificationPrChecksRecovered => 'Проверки проходят';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '$prTitle снова зелёный.';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '$login упомянул вас в $location';
  }

  @override
  String get notificationPrThreadReplied => 'Новый ответ';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '$login ответил в $location';
  }

  @override
  String get notificationPrThreadResolved => 'Обсуждение закрыто';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return 'Ваше обсуждение в $location закрыто.';
  }

  @override
  String get notificationGroupAgents => 'Агенты';

  @override
  String get notificationGroupPullRequests => 'Pull requests';

  @override
  String get notificationGroupMessages => 'Сообщения';

  @override
  String get notificationGroupTickets => 'Тикеты';

  @override
  String get notificationGroupCalendar => 'Календарь';

  @override
  String get notificationGroupMachines => 'Машины';

  @override
  String get notificationSectionSound => 'Звук';

  @override
  String get notificationSectionSchedule => 'Расписание';

  @override
  String get notificationSectionEvents => 'События';

  @override
  String get notificationsMutedRepos => 'Репозитории без уведомлений';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count репозитория без уведомлений',
      many: '$count репозиториев без уведомлений',
      few: '$count репозитория без уведомлений',
      one: '$count репозиторий без уведомлений',
      zero: 'Нет репозиториев без уведомлений',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'Отключить уведомления этого репозитория';

  @override
  String get onboardingLinuxDescription =>
      'Control Center может использовать контейнеры Linux для изоляции выполнения агентов.';

  @override
  String get onboardingMacosDescription =>
      'Control Center использует встроенную песочницу macOS для изоляции выполнения агентов.';

  @override
  String get onboardingUnsupportedDescription =>
      'Песочница недоступна на этой платформе. Агенты будут выполняться без изоляции.';

  @override
  String get openArticlesInApp => 'Открыть статьи в приложении';

  @override
  String get openInBrowser => 'Открыть в браузере';

  @override
  String get openedInYourBrowser => 'Открыто в браузере.';

  @override
  String get openLabel => 'Открыть';

  @override
  String get openOnGithub => 'Открыть на GitHub';

  @override
  String get openStatus => 'Открыто';

  @override
  String get optionalPersonaDescription => 'Необязательное описание персоны';

  @override
  String get otherLabel => 'Другое';

  @override
  String get ownerOrganization => 'Владелец / организация';

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
  String get pasteValueHere => 'Вставьте значение';

  @override
  String get persona => 'Персона';

  @override
  String get policies => 'Политики';

  @override
  String get policiesHint =>
      'Политики появятся здесь, когда агенты повысят факты.';

  @override
  String get policy => 'Политика';

  @override
  String get popular => 'Популярное';

  @override
  String get port => 'Порт';

  @override
  String get postingEllipsis => 'Публикация…';

  @override
  String get prCommits => 'Коммиты';

  @override
  String get prMergedBody => 'Pull request объединён';

  @override
  String get prMoreActions => 'Ещё действия';

  @override
  String get prTitle => 'Название PR';

  @override
  String get reviewCommentHint =>
      'Просто нажмите «одобрить» или, если хочется поострее, добавьте комментарий или реакцию…';

  @override
  String get nothingToPreview => 'Нечего предпросматривать';

  @override
  String get previousMatch => 'Предыдущее совпадение (⇧↵)';

  @override
  String get priorityReviewsDescription =>
      'Приоритетные ревью и обзор репозитория.';

  @override
  String get prsCreated => 'Созданные PR';

  @override
  String get prsMerged => 'Объединённые PR';

  @override
  String get publishToGithub => 'Опубликовать на GitHub';

  @override
  String get published => 'Опубликовано';

  @override
  String get pullRequestApproved => 'Pull request одобрен';

  @override
  String get pullRequests => 'Pull requests';

  @override
  String get questionLabel => 'Вопрос';

  @override
  String get queued => 'В очереди';

  @override
  String get react => 'React';

  @override
  String get readerPreferences => 'Настройки чтения';

  @override
  String get reasoningEffort => 'Усилие рассуждения';

  @override
  String get recommendLabel => 'Рекомендуем';

  @override
  String recordingFromDevice(String device) {
    return 'Запись с $device.';
  }

  @override
  String get redownload => 'Скачать заново';

  @override
  String get redownloadEmbeddingModel => 'Скачать модель эмбеддингов заново?';

  @override
  String get redownloadVoiceModel => 'Скачать голосовую модель заново?';

  @override
  String get refinePlan => 'Уточнить план';

  @override
  String get refresh => 'Обновить';

  @override
  String get refreshAll => 'Обновить все';

  @override
  String get refreshAllFeeds => 'Обновить все ленты';

  @override
  String get reject => 'Отклонить';

  @override
  String get rejected => 'Отклонено';

  @override
  String get reload => 'Перезагрузить';

  @override
  String get remove => 'Удалить';

  @override
  String get removeBookmark => 'Удалить закладку';

  @override
  String get removeEmbeddingModel => 'Удалить модель эмбеддингов?';

  @override
  String get removeLogo => 'Удалить логотип';

  @override
  String get removeRepoFromWorkspace =>
      'Удалить репозиторий из рабочего пространства?';

  @override
  String get removeVoiceModel => 'Удалить голосовую модель?';

  @override
  String get removed => 'Удалено';

  @override
  String get renamed => 'Переименовано';

  @override
  String get reopen => 'Открыть заново';

  @override
  String get resolve => 'Разрешить';

  @override
  String get replyEllipsis => 'Ответить…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name будет удалён из этого рабочего пространства. Локальные файлы на диске не изменятся.';
  }

  @override
  String get repoNoAccessBadge => 'Нет доступа';

  @override
  String get reportsTo => 'Руководитель';

  @override
  String reposCount(int count) {
    return 'Репозитории ($count)';
  }

  @override
  String get reposDescription =>
      'Локальные копии, с которыми работает это рабочее пространство.';

  @override
  String get repositories => 'Репозитории';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count репозитория',
      many: '$count репозиториев',
      few: '$count репозитория',
      one: '1 репозиторий',
    );
    return 'Не удалось добавить $_temp0: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count репозитория добавлено',
      many: '$count репозиториев добавлено',
      few: '$count репозитория добавлено',
      one: 'Репозиторий добавлен',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'Настройки репозиториев';

  @override
  String get repositoryName => 'Имя репозитория';

  @override
  String get requestChanges => 'Запросить изменения';

  @override
  String get requested => 'Запрошено';

  @override
  String get requestedChanges => 'Запрошены изменения';

  @override
  String requiredRoleLabel(String role) {
    return 'Обязательная роль: $role';
  }

  @override
  String get requiredRoleOptional => 'Обязательная роль (необязательно)';

  @override
  String get requirements => 'Требования';

  @override
  String get reset => 'Сбросить';

  @override
  String get resolved => 'Разрешено';

  @override
  String get enclosedTerminalTitle => 'Изолированный терминал';

  @override
  String get enclosedTerminalStart => 'Открыть оболочку';

  @override
  String get enclosedTerminalStartHint =>
      'Эта оболочка работает во временной VM этого разговора. Она запускается при открытии, а не при старте приложения.';

  @override
  String get terminalStreamReconnecting => 'поток прерван — переподключение…';

  @override
  String get terminalStreamError => 'ошибка потока:';

  @override
  String get terminalShellExited => 'оболочка завершила работу';

  @override
  String get restartShell => 'Перезапустить оболочку';

  @override
  String get retry => 'Повторить';

  @override
  String get review => 'Ревью';

  @override
  String get reviewedByMe => 'Проверено мной';

  @override
  String get reviewers => 'Ревьюеры';

  @override
  String get roleLabel => 'Роль';

  @override
  String get ruleHint => 'Правило политики (поддерживается markdown)';

  @override
  String get ruleLabel => 'Правило';

  @override
  String get running => 'Выполняется';

  @override
  String get runningLabel => 'выполняется';

  @override
  String get runs => 'Запуски';

  @override
  String get runsLabel => 'Запуски';

  @override
  String get sandboxBackendNativeLabel => 'Нативная песочница';

  @override
  String get sandboxBackendMicrovmLabel => 'Изолированная VM';

  @override
  String get sandboxBackendNoneLabel => 'Без изоляции';

  @override
  String get sandboxLinuxInstall =>
      'Нативная песочница на Linux/WSL2 использует bubblewrap. Установка:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'Нативная песочница встроена в macOS — использует Apple Seatbelt (`sandbox-exec`). Установка не нужна.';

  @override
  String get sandboxUnsupported =>
      'Нативная песочница пока не поддерживается на этой платформе. Используется «Без изоляции».';

  @override
  String get sandboxingDisabledDescription =>
      'Агенты запускаются напрямую на хосте с полным доступом к окружению — не рекомендуется.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Все вызовы агента проходят через $backend.';
  }

  @override
  String get save => 'Сохранить';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get adapterArguments => 'Дополнительные аргументы';

  @override
  String get adapterArgumentsHint => 'Дополнительные флаги CLI (напр. --yolo)';

  @override
  String get addVariable => 'Добавить переменную';

  @override
  String get environmentVariables => 'Переменные окружения';

  @override
  String get environmentVariablesDescription =>
      'Пользовательские переменные окружения для этого адаптера (напр. ключи API). Хранятся в связке ключей.';

  @override
  String get variableKey => 'Ключ';

  @override
  String get variableValue => 'Значение';

  @override
  String get savingEllipsis => 'Сохранение…';

  @override
  String get scopeDiffToCommits =>
      'Ограничить diff коммитами — Shift-клик для диапазона';

  @override
  String get noPrsMatchSearch => 'Нет подходящих pull request';

  @override
  String get searchFactsHint => 'Поиск фактов...';

  @override
  String get searchFonts => 'Поиск шрифтов…';

  @override
  String get searchGifs => 'Поиск GIF';

  @override
  String get searchGifsHint => 'Искать в KLIPY';

  @override
  String get searchInDiffHint => 'Поиск в diff…';

  @override
  String get searchOrTypeModel => 'Найдите или введите имя модели…';

  @override
  String get searchPlaceholder => 'Поиск…';

  @override
  String get searching => 'Идёт поиск…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count секунд назад',
      many: '$count секунд назад',
      few: '$count секунды назад',
      one: '$count секунду назад',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Выберите адаптер';

  @override
  String get selectAdapterFirst => 'Сначала выберите адаптер';

  @override
  String get selectAgentToReportTo => 'Выберите агента для отчёта…';

  @override
  String get selectAnAgent => 'Выберите агента';

  @override
  String get selectConversation => 'Выберите беседу';

  @override
  String get selectLabel => 'Выбрать';

  @override
  String get selectRunner => 'Выберите раннер';

  @override
  String get semanticSearch => 'Семантический поиск';

  @override
  String get send => 'Отправить';

  @override
  String get sendFirstMessage => 'Отправьте первое сообщение';

  @override
  String get sendMessage => 'Отправить сообщение';

  @override
  String sentFindingsToAgent(int count) {
    return 'Агенту отправлено $count находок.';
  }

  @override
  String setGithubLinkDescription(String name) {
    return 'Укажите владельца GitHub и имя репозитория для $name. Нужно, чтобы разрешать ссылки на PR и issue вроде #123 в markdown.';
  }

  @override
  String get setLabel => 'Задать';

  @override
  String get settingsLabel => 'Настройки';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageDescription => 'Выберите язык приложения.';

  @override
  String get showNativeNotifications =>
      'Показывать системные уведомления для событий.';

  @override
  String get showSuperseded => 'Показывать заменённые';

  @override
  String get signedIn => 'Вы вошли.';

  @override
  String signedInAs(String username) {
    return 'Вы вошли как $username.';
  }

  @override
  String get skillNameRequired => 'Укажите имя скилла.';

  @override
  String skillSaved(String name) {
    return 'Скилл «$name» сохранён.';
  }

  @override
  String get skillsSourcesTab => 'Источники';

  @override
  String get skillSourcesDisclaimer =>
      'Скиллы устанавливаются из добавленных репозиториев GitHub. Метаданные репозитория ненадёжны — реальный сигнал безопасности даёт антивирусная проверка.';

  @override
  String get skillSourcesEmpty => 'Нет репозиториев скиллов';

  @override
  String get skillSourcesEmptyHint =>
      'Добавьте репозиторий GitHub, чтобы просмотреть его скиллы.';

  @override
  String get skillSourceAdd => 'Добавить репозиторий';

  @override
  String get skillSourceAddTitle => 'Добавить репозиторий скиллов';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      'Введите URL репозитория GitHub (https://github.com/owner/repo).';

  @override
  String skillSourceAdded(String repo) {
    return 'Репозиторий $repo добавлен.';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'Репозиторий $repo уже добавлен.';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'Репозиторий $repo удалён.';
  }

  @override
  String get skillSourceRemove => 'Удалить';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return 'Удалить $repo?';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'Установленные скиллы останутся. Удаляется только каталог репозитория.';

  @override
  String get skillSourceNoSkills =>
      'В этом репозитории нет скиллов (скилл — каталог с файлом SKILL.md).';

  @override
  String get skillSourceRefresh => 'Обновить';

  @override
  String get skillSourceInstalledBadge => 'Установлен';

  @override
  String get skillSourceUpdateBadge => 'Доступно обновление';

  @override
  String get skillSourceSlugTaken => 'Имя занято';

  @override
  String skillSourceFilesCount(num count) {
    return '$count files';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'У этого скилла нет README.';

  @override
  String get skillSourceNoMatches => 'Нет скиллов, подходящих под фильтр.';

  @override
  String get skillUpdateAction => 'Обновить';

  @override
  String get skillUninstallAction => 'Удалить';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return 'Удалить «$slug»?';
  }

  @override
  String skillUninstalled(String slug) {
    return 'Скилл «$slug» удалён.';
  }

  @override
  String get skillFindingLine => 'строка';

  @override
  String get skillInstallAnywayOverride =>
      'Я понимаю риск — установить всё равно';

  @override
  String skillInstalled(String slug) {
    return 'Скилл «$slug» установлен.';
  }

  @override
  String get skillPreviewCapabilities => 'Возможности';

  @override
  String get skillPreviewFindings => 'Находки';

  @override
  String get skillPreviewGuardedActions => 'Охраняемые действия';

  @override
  String get skillPreviewLlmReviewed => 'Проверено LLM';

  @override
  String get skillPreviewNoCapabilities => 'Возможности не объявлены.';

  @override
  String get skillPreviewNoFindings => 'Находок нет.';

  @override
  String get skillPreviewScanning => 'Сканирование скилла…';

  @override
  String get skillPreviewVerdictLabel => 'Вердикт сканирования';

  @override
  String get skillPreviewVerdictPass => 'Пройдено';

  @override
  String get skillPreviewVerdictQuarantine => 'Карантин';

  @override
  String get skillPreviewVerdictWarn => 'Предупреждение';

  @override
  String get skillQuarantineWarning =>
      'Сканер поместил этот скилл в карантин. Установка запускает код на вашем компьютере. Продолжайте, только если доверяете источнику и просмотрели находки.';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'В карантине и отключён от агентов: $agents';
  }

  @override
  String get skillNotScanned => 'Не сканировался';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'Вручную';

  @override
  String get skillOriginRuntimeLocal => 'Локальный runtime';

  @override
  String get skillRulesStale => 'Сканирование устарело';

  @override
  String get skillSaveAnywayOverride => 'Я понимаю риск — сохранить всё равно';

  @override
  String get skillSaveBlockedBody => 'Содержимое заблокировано до записи.';

  @override
  String get skillSaveBlockedTitle =>
      'Сохранение заблокировано шлюзом сканирования';

  @override
  String get skillScanAction => 'Сканировать';

  @override
  String get skillScanAll => 'Сканировать все';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass пройдено · $warn предупреждений · $quarantine в карантине';
  }

  @override
  String get skillStateDrifted => 'Изменено после установки';

  @override
  String get skillStateUnmanaged => 'Неуправляемый';

  @override
  String get skillSeverityBlocked => 'Заблокировано';

  @override
  String get skillSeverityWarn => 'Предупреждение';

  @override
  String get skillsInstalledTab => 'Установленные';

  @override
  String get skills => 'Навыки';

  @override
  String get skipAcceptRisk => 'Пропустить — принимаю риск';

  @override
  String get skipForNow => 'Пропустить пока';

  @override
  String get skipSandboxing => 'Пропустить песочницу';

  @override
  String get skipSandboxingDialogContent =>
      'Вы уверены, что хотите пропустить песочницу? Это позволит агентам выполнять код в вашей системе без изоляции.';

  @override
  String get somethingWentWrong => 'Что-то пошло не так';

  @override
  String sourceCount(int count) {
    return '$count источник';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count источников';
  }

  @override
  String get sourceFacts => 'Факты источника:';

  @override
  String get splitDiff => 'Разделённый (бок о бок) diff';

  @override
  String get startLabel => 'Запустить';

  @override
  String get startOnAppLaunch => 'Запускать при старте приложения';

  @override
  String get statusLabel => 'Статус';

  @override
  String get onboardingStepConnect => 'Подключение';

  @override
  String get onboardingStepWorkspace => 'Рабочее пространство';

  @override
  String get onboardingStepSandbox => 'Песочница';

  @override
  String get onboardingStepAdapter => 'Адаптер';

  @override
  String get onboardingStepVoice => 'Голос';

  @override
  String get stop => 'Остановить';

  @override
  String get stopped => 'Остановлено';

  @override
  String get strictIdentityCheck => 'Строгая проверка идентичности';

  @override
  String get success => 'Успех';

  @override
  String get successLabel => 'Успех';

  @override
  String get suggestion => 'Предложение';

  @override
  String get suggestLabel => 'Предложить';

  @override
  String get superseded => 'Заменено';

  @override
  String get synced => 'Синхронизировано';

  @override
  String get systemDefault => 'Системное по умолчанию';

  @override
  String get systemFonts => 'Системные шрифты';

  @override
  String get systemPrompt => 'Системный промпт';

  @override
  String get systemPromptLabel => 'Системный промпт';

  @override
  String get talkToControlCenter => 'Говорите с Control Center.';

  @override
  String get taskMentionSection => 'Задача';

  @override
  String get testLabel => 'Тест';

  @override
  String get theme => 'Тема';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeSystem => 'Системная';

  @override
  String get thisCannotBeUndone => 'Это действие нельзя отменить.';

  @override
  String get ticketLabel => 'Тикет';

  @override
  String get titleLabel => 'Название';

  @override
  String get todayLabel => 'Сегодня';

  @override
  String get toggleTheme => 'Переключить тему';

  @override
  String get topic => 'Тема';

  @override
  String get topicHint => 'напр. Tech Stack, Design System';

  @override
  String get totalRuns => 'Всего запусков';

  @override
  String trackingParamsCount(int count) {
    return '$count параметра отслеживания';
  }

  @override
  String get typeCommandOrSearch => 'Введите команду или поиск…';

  @override
  String get typography => 'Типографика';

  @override
  String get unavailable => 'Недоступно';

  @override
  String get unifiedDiff => 'Объединённый diff';

  @override
  String get unknownAuthor => 'Неизвестный';

  @override
  String get unnamedAgent => 'Безымянный агент';

  @override
  String get updateLabel => 'Обновить';

  @override
  String get updateToken => 'Обновить токен';

  @override
  String updatedDaysAgo(int count) {
    return 'Обновлено $count дн. назад';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'Обновлено $count ч назад';
  }

  @override
  String get updatedJustNow => 'Обновлено только что';

  @override
  String updatedMinutesAgo(int count) {
    return 'Обновлено $count мин назад';
  }

  @override
  String get useSandbox => 'Использовать песочницу';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'Оставьте пустым, чтобы использовать User-Agent приложения по умолчанию. Некоторые сайты блокируют User-Agent, не похожие на браузерные.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Используется системный микрофон по умолчанию.';

  @override
  String get viewLabel => 'Просмотр';

  @override
  String get viewLogs => 'Показать логи';

  @override
  String voiceInstallFailed(String error) {
    return 'Установка не удалась: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Не установлено. Разовая загрузка ~200 МБ; работает полностью на устройстве.';

  @override
  String get voiceModelNotInstalledLabel => 'Голосовая модель не установлена.';

  @override
  String get voiceRedownloadBody =>
      'Существующие файлы модели будут удалены, архив ~200 МБ загрузится заново. Голосовая транскрипция будет недоступна до завершения загрузки.';

  @override
  String get voiceRemoveBody =>
      'Голосовая транскрипция будет отключена, пока вы не установите её снова. Установить можно в любой момент.';

  @override
  String get voiceTranscription => 'Голосовая транскрипция';

  @override
  String get weakIsolationDescription =>
      'Слабая изоляция — только граница пространства имён, без границы ядра.';

  @override
  String get whenOffServerStaysStopped =>
      'Если выключено, сервер остаётся остановленным, пока вы его не запустите.';

  @override
  String get speechModel => 'Речевая модель';

  @override
  String get speechModelHint =>
      'Для транскрипции встреч и микрофона в композере.';

  @override
  String get voiceModelInstalled =>
      'Установлено. Обеспечивает транскрипцию встреч и кнопку микрофона в композере.';

  @override
  String get meetingMicSilentWarning =>
      'Микрофон, возможно, выключен — остальные говорят, но звук не доходит до вашего микрофона.';

  @override
  String get meetingSummaryPrivacyNotice =>
      'Запись и транскрипция остаются на этом компьютере. Сводку пишет агент: если он использует облачную модель, транскрипт и заметки отправляются этому провайдеру.';

  @override
  String get meetingTemplates => 'Шаблоны заметок о встречах';

  @override
  String get meetingTemplatesHint =>
      'Задайте форму ИИ-сводки для типа встречи. Активный шаблон применяется к новым сводкам и при повторном запуске.';

  @override
  String get meetingTemplateActive => 'Активный шаблон';

  @override
  String get meetingTemplateAdd => 'Добавить шаблон';

  @override
  String get meetingTemplateNewTitle => 'Новый шаблон';

  @override
  String get meetingTemplateEditTitle => 'Редактировать шаблон';

  @override
  String get meetingTemplateNameLabel => 'Название';

  @override
  String get meetingTemplateNameHint => 'например, обзор спринта';

  @override
  String get meetingTemplateInstructionsLabel => 'Инструкции';

  @override
  String get meetingTemplateInstructionsHint =>
      'Как ИИ должен структурировать эти заметки и на чём делать акцент?';

  @override
  String get workingMemory => 'Рабочая память';

  @override
  String get workspaceName => 'Название рабочего пространства';

  @override
  String get workspaceScopedSkills =>
      'Файлы навыков рабочего пространства, прикреплённые к агентам.';

  @override
  String get workspaces => 'Рабочие пространства';

  @override
  String get writePrivateNotes => 'Личные заметки, наблюдения, планы...';

  @override
  String get writeSkillContent =>
      'Напишите содержимое навыка здесь (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count лет назад',
      many: '$count лет назад',
      few: '$count года назад',
      one: '$count год назад',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Вчера';

  @override
  String get focusModeStart => 'Начать сессию фокуса';

  @override
  String get focusModeConfigTitle => 'Начать сессию фокуса';

  @override
  String get focusModeGoalLabel => 'Цель';

  @override
  String get focusModeGoalHint => 'Над чем вы работаете?';

  @override
  String get focusModeDurationLabel => 'Длительность';

  @override
  String get focusModeBlockNotifications => 'Блокировать уведомления';

  @override
  String get focusModeStartButton => 'Начать';

  @override
  String get focusModeFloat => 'Свернуть на панель';

  @override
  String get dismiss => 'Закрыть';

  @override
  String get acceptAndResolve => 'Принять и разрешить';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'Вы ревьюите уже $minutes мин — исследования показывают, что качество ревью может снижаться после 60 мин. Стоит сделать перерыв.';
  }

  @override
  String get notificationSound => 'Звук уведомления';

  @override
  String get notificationSoundDescription => 'Звук при появлении уведомления.';

  @override
  String get notificationSoundNone => 'Нет';

  @override
  String get notificationSoundPing => 'Пинг';

  @override
  String get notificationSoundChime => 'Перезвон';

  @override
  String get notificationSoundPop => 'Хлопок';

  @override
  String get notificationSoundDing => 'Динь';

  @override
  String get notificationSoundWhoosh => 'Свист';

  @override
  String get notificationSoundMigrosSoft => 'Migros (мягкий)';

  @override
  String get notificationSoundMigrosHard => 'Migros (жёсткий)';

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
  String get notificationVolume => 'Громкость';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Нет PR от @$login в этом рабочем пространстве';
  }

  @override
  String get usersLabel => 'Пользователи';

  @override
  String get mergePullRequest => 'Слить pull request';

  @override
  String get forceMergePullRequest => 'Принудительно слить pull request';

  @override
  String get closePullRequest => 'Закрыть pull request';

  @override
  String get closePullRequestConfirm => 'Закрыть этот pull request?';

  @override
  String get stackedPullRequests => 'Стек pull request';

  @override
  String partOfStack(int position, int total) {
    return 'Часть стека ($position из $total)';
  }

  @override
  String get createStack => 'Создать стек';

  @override
  String get createStackDialogTitle => 'Создать стек pull request';

  @override
  String createStackDialogBody(int count) {
    return 'Эти $count pull request будут сложены в стек снизу вверх:';
  }

  @override
  String get createStackInvalidSelection =>
      'Выберите минимум два pull request из одного репозитория, чтобы создать стек';

  @override
  String get createStackNotAChain =>
      'Выбранные pull request не образуют цепочку: базовая ветка каждого должна быть головной веткой предыдущего';

  @override
  String get createStackAlreadyStacked =>
      'Один или несколько выбранных pull request уже в стеке';

  @override
  String get stackCreated => 'Стек создан';

  @override
  String get stackCreationFailed => 'Не удалось создать стек';

  @override
  String get squashAndMerge => 'Объединить и слить';

  @override
  String get createMergeCommit => 'Создать коммит слияния';

  @override
  String get rebaseAndMerge => 'Перебазировать и слить';

  @override
  String get mergeMethod => 'Способ слияния';

  @override
  String get commitTitle => 'Заголовок коммита';

  @override
  String get commitDescription => 'Описание коммита';

  @override
  String get pullRequestMerged => 'Pull request слит';

  @override
  String get pullRequestClosed => 'Pull request закрыт';

  @override
  String failedToMergePr(String error) {
    return 'Не удалось слить: $error';
  }

  @override
  String failedToClosePr(String error) {
    return 'Не удалось закрыть: $error';
  }

  @override
  String get markReadyForReview => 'Готово к ревью';

  @override
  String get markReadyForReviewConfirm =>
      'Этот pull request выйдет из черновика. Ревьюеры получат уведомление, обязательные проверки начнут блокировать слияние, а автоматизация, ожидающая готовые pull request, запустится.';

  @override
  String get convertToDraft => 'В черновик';

  @override
  String get convertToDraftConfirm =>
      'Этот pull request снова станет черновиком. Ожидающие запросы на ревью будут отозваны, слить его можно будет только после повторной пометки «готово».';

  @override
  String get pullRequestMarkedReady =>
      'Pull request помечен как готовый к ревью';

  @override
  String get pullRequestConvertedToDraft =>
      'Pull request преобразован в черновик';

  @override
  String failedToMarkPrReady(String error) {
    return 'Не удалось пометить как готовый к ревью: $error';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'Не удалось преобразовать в черновик: $error';
  }

  @override
  String get checksFailing => 'Проверки не проходят';

  @override
  String get reviewsPending => 'Есть незавершённые ревью';

  @override
  String get mergeConflictsWithBase =>
      'В этой ветке есть конфликты, которые нужно разрешить';

  @override
  String get branchOutOfDateWithBase => 'Эта ветка отстаёт от базовой';

  @override
  String get mergeBlockedByBranchProtection =>
      'Защита ветки блокирует это слияние';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get trustedSitesSectionTitle => 'Доверенные сайты';

  @override
  String get trustedSitesEmpty =>
      'Нет доверенных сайтов. Добавьте домен, чтобы отключить блокировку для него.';

  @override
  String get addTrustedSite => 'Добавить доверенный сайт';

  @override
  String get removeTrustedSite => 'Удалить';

  @override
  String get disableBlockingForThisSite => 'Отключить блокировку на этом сайте';

  @override
  String get enableBlockingForThisSite => 'Включить блокировку на этом сайте';

  @override
  String get enterDomainHint => 'напр. example.com';

  @override
  String get invalidDomain => 'Введите корректный домен (напр. example.com)';

  @override
  String get pageLoadTimedOut =>
      'Истекло время загрузки страницы. Перезагрузите или откройте в браузере.';

  @override
  String get pipelinesScreenTitle => 'Конвейеры';

  @override
  String get pipelinesScreenSubtitle =>
      'Декларативные многошаговые рабочие процессы агента';

  @override
  String get pipelinesRunPipeline => 'Запустить конвейер';

  @override
  String get pipelineRunLauncherTitle => 'Запустить конвейер';

  @override
  String get pipelineRunSubtitle =>
      'Выберите конвейер и заполните его входные данные, чтобы начать запуск.';

  @override
  String get pipelineRunNoInputsBadge => 'Нет входных данных';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count поля',
      many: '$count полей',
      few: '$count поля',
      one: '$count поле',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'У этого конвейера нет входных данных.';

  @override
  String get pipelineRunSubmit => 'Запустить конвейер';

  @override
  String get pipelineRunCouldNotStart => 'Не удалось начать запуск.';

  @override
  String pipelineRunStarted(String name) {
    return 'Запущен $name';
  }

  @override
  String get pipelineRunEmptyTitle => 'Нет конвейеров, готовых к запуску';

  @override
  String get pipelineRunEmptyHint =>
      'Включите конвейер и разрешите ручной запуск в его редакторе, чтобы запускать его здесь.';

  @override
  String get pipelineRunManageTemplates => 'Управление конвейерами';

  @override
  String get pipelineRunSettingsTitle => 'Ручной запуск';

  @override
  String get pipelineRunSettingsAllow => 'Разрешить ручной запуск';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Показывать этот конвейер на странице запуска, чтобы его можно было запустить вручную.';

  @override
  String get pipelineRunSettingsConcurrencyTitle => 'Параллельность';

  @override
  String get pipelineRunSettingsMaxParallel => 'Макс. параллельных запусков';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'Оставьте пустым, чтобы не ограничивать. Лишние запуски ждут в очереди и стартуют, когда освобождаются слоты.';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'Без ограничений';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      'Введите целое число не меньше 1 или оставьте пустым, чтобы не ограничивать.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Входные данные';

  @override
  String get pipelineRunSettingsAddInput => 'Добавить поле';

  @override
  String get pipelineRunSettingsNoInputs => 'Пока нет входных данных.';

  @override
  String get pipelineInputEditTitle => 'Поле ввода';

  @override
  String get pipelineInputKeyLabel => 'Ключ';

  @override
  String get pipelineInputKeyHelp =>
      'Ключ состояния, под которым хранится значение (напр. repo_full_name).';

  @override
  String get pipelineInputLabelLabel => 'Подпись';

  @override
  String get pipelineInputTypeLabel => 'Тип';

  @override
  String get pipelineInputOptionsLabel => 'Варианты (через запятую)';

  @override
  String get pipelineInputDefaultLabel => 'Значение по умолчанию';

  @override
  String get pipelineInputPlaceholderLabel => 'Заполнитель';

  @override
  String get pipelineInputHelpLabel => 'Текст справки';

  @override
  String get pipelineInputRequiredLabel => 'Обязательное';

  @override
  String get pipelineInputTypeText => 'Текст';

  @override
  String get pipelineInputTypeMultiline => 'Многострочный текст';

  @override
  String get pipelineInputTypeNumber => 'Число';

  @override
  String get pipelineInputTypeBoolean => 'Переключатель';

  @override
  String get pipelineInputTypeSelect => 'Список';

  @override
  String get pipelinesEmpty => 'Пока нет запусков конвейеров';

  @override
  String get pipelinesEmptyHint =>
      'Нажмите «Запустить конвейер», чтобы начать.';

  @override
  String get pipelinesNoSteps => 'Шаги ещё не записаны';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Выберите рабочее пространство, чтобы просмотреть его конвейеры';

  @override
  String pipelinesLoadError(String error) {
    return 'Не удалось загрузить конвейеры: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Не удалось запустить конвейер: $error';
  }

  @override
  String get pipelineStatusPending => 'Ожидание';

  @override
  String get pipelineStatusQueued => 'В очереди';

  @override
  String get pipelineStatusRunning => 'Выполняется';

  @override
  String get pipelineStatusSuspended => 'Приостановлен';

  @override
  String get pipelineStatusCompleted => 'Завершён';

  @override
  String get pipelineStatusFailed => 'Ошибка';

  @override
  String get pipelineStatusCancelled => 'Отменён';

  @override
  String get pipelineStatusSkipped => 'Пропущен';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed из $total шагов';
  }

  @override
  String get pipelineWaterfallTimeline => 'Хронология';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'Активен $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'простой $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'Время, исключённое из активного итога: запуск был остановлен или ждал между шагами.';

  @override
  String get pipelineStepStarted => 'Начато';

  @override
  String get pipelineStepFinished => 'Завершено';

  @override
  String get pipelineStepDurationLabel => 'Длительность';

  @override
  String get pipelineStepViewConversation => 'Открыть диалог';

  @override
  String get pipelineStepError => 'Ошибка';

  @override
  String get pipelineStepInput => 'Вход';

  @override
  String get pipelineStepOutput => 'Выход';

  @override
  String get pipelineStepNotExecuted => 'Ещё не выполнен';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Сбой на $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Вручную';

  @override
  String get pipelineStepSkippedReason => 'Пропущен';

  @override
  String get pipelineStepPriorAttempts => 'Предыдущие попытки';

  @override
  String get pipelineStepAttemptLabel => 'Попытка';

  @override
  String pipelineStepAttemptN(int number) {
    return 'Попытка $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'Прервано';

  @override
  String get pipelineRunColumnPipeline => 'Конвейер';

  @override
  String get pipelineRunColumnDuration => 'Длительность';

  @override
  String get pipelineRunQueueNext => 'Следующий';

  @override
  String pipelineRunQueuePosition(int position) {
    return '$position в очереди';
  }

  @override
  String get pipelineRunColumnStarted => 'Начало';

  @override
  String get pipelineRunHistory => 'История запусков';

  @override
  String get pipelineRunHistoryEmpty => 'Других запусков пока нет';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'Повтор $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return 'Попытка $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'первый запуск $time';
  }

  @override
  String get pipelineRunFilterAll => 'Все';

  @override
  String get pipelineRunFilterEmpty => 'Нет запусков по этому фильтру';

  @override
  String get relativeJustNow => 'только что';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count мин назад',
      many: '$count мин назад',
      few: '$count мин назад',
      one: '$count мин назад',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count часа назад',
      many: '$count часов назад',
      few: '$count часа назад',
      one: '$count час назад',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня назад',
      many: '$count дней назад',
      few: '$count дня назад',
      one: '$count день назад',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'Команды';

  @override
  String get teamsAddTeam => 'Добавить команду';

  @override
  String get teamsLoadError => 'Не удалось загрузить команды';

  @override
  String get teamsEmptyTitle => 'Команд пока нет';

  @override
  String get teamsEmptyDescription =>
      'Объединяйте агентов в команды: работа для команды идёт через лидера, который делегирует.';

  @override
  String get teamCreateTitle => 'Новая команда';

  @override
  String get teamEditTitle => 'Изменить команду';

  @override
  String get teamNameLabel => 'Название команды';

  @override
  String get teamNameHint => 'напр. Frontend';

  @override
  String get teamDescriptionLabel => 'Описание';

  @override
  String get teamDescriptionHint => 'За что отвечает эта команда';

  @override
  String get teamLeaderLabel => 'Лидер';

  @override
  String get teamLeaderHelp =>
      'Координатор, который получает работу команды и делегирует подходящему участнику.';

  @override
  String get teamNoLeader => 'Без лидера';

  @override
  String get teamInstructionsLabel => 'Рабочие инструкции';

  @override
  String get teamInstructionsHelp =>
      'Добавляются к брифингу лидера — договорённости команды, эскалация, тон.';

  @override
  String get teamInstructionsHint => 'Необязательно';

  @override
  String get teamSaved => 'Команда сохранена';

  @override
  String get teamMembersError => 'Не удалось загрузить участников';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count участника',
      many: '$count участников',
      few: '$count участника',
      one: '$count участник',
      zero: 'Нет участников',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'Добавить участника';

  @override
  String get teamAddMemberTitle => 'Добавить участников';

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
  String get teamNoAgentsToAdd => 'Все агенты уже в этой команде.';

  @override
  String get teamRemoveMember => 'Убрать из команды';

  @override
  String get teamLeaderBadge => 'Лидер';

  @override
  String get teamUnknownAgent => 'Неизвестный агент';

  @override
  String get teamMembersEmpty => 'Пока нет участников';

  @override
  String get teamMembersEmptyDescription =>
      'Добавьте агентов, чтобы лидеру было кому делегировать.';

  @override
  String get teamSelectPrompt => 'Выберите команду';

  @override
  String get teamSelectPromptDescription =>
      'Выберите команду из списка или создайте новую.';

  @override
  String get teamDeleteTitle => 'Удалить команду?';

  @override
  String teamDeleteBody(String name) {
    return '$name будет удалена. Агенты команды не изменятся.';
  }

  @override
  String get teamHasLeaderTooltip => 'Есть лидер';

  @override
  String get pipelineTemplatesNav => 'Шаблоны конвейеров';

  @override
  String get pipelineTemplatesTitle => 'Шаблоны конвейеров';

  @override
  String get pipelineTemplatesSubtitle =>
      'Редактор с перетаскиванием для конвейеров, которые оркестрируют агентов.';

  @override
  String get pipelineTemplatesNew => 'Новый шаблон';

  @override
  String get pipelineTemplatesEmpty =>
      'Пока нет шаблонов конвейеров. Создайте первый, чтобы начать.';

  @override
  String get pipelineTemplateBuiltInBadge => 'Встроенный';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Удалить шаблон?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Удалить шаблон конвейера $name? Это действие нельзя отменить.';
  }

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Перетащите типы узлов с боковой панели на холст и соедините их.';

  @override
  String get unsavedChanges => 'Несохранённые изменения';

  @override
  String get nodeLibraryTitle => 'Библиотека узлов';

  @override
  String get nodeLibraryHint =>
      'Перетащите элемент на холст, чтобы добавить узел.';

  @override
  String get editorEmptyCanvas =>
      'Перетащите узел из библиотеки, чтобы начать.';

  @override
  String get pipelineWhenThisHappens => 'Когда это происходит';

  @override
  String get pipelineDoThis => 'Сделать это';

  @override
  String get pipelineAddStep => 'Добавить шаг';

  @override
  String get pipelineTidyUp => 'Упорядочить схему';

  @override
  String get pipelineEditorHint =>
      'Перетащите шаги, чтобы расставить · перетащите маркер, чтобы соединить';

  @override
  String get pipelineRemoveConnection => 'Удалить соединение';

  @override
  String get pipelineDragToConnect => 'Перетащите, чтобы соединить';

  @override
  String get pipelineNewDefaultName => 'Новый конвейер';

  @override
  String get nodeCategoryTriggers => 'Триггеры';

  @override
  String get triggerEventWebhook => 'Webhook';

  @override
  String get pipelineAddTrigger => 'Добавить триггер';

  @override
  String get pipelineOnEvent => 'По событию';

  @override
  String get nodeConfigTitle => 'Настройки узла';

  @override
  String get nodeConfigKind => 'Тип';

  @override
  String get nodeConfigLabel => 'Метка';

  @override
  String get nodeConfigAgent => 'Агент';

  @override
  String get nodeConfigAgentHint => 'Выберите агента…';

  @override
  String get nodeConfigInputKeys => 'Входные ключи (через запятую)';

  @override
  String get nodeConfigInputKeysHelp =>
      'Ключи состояния, которые потребляет этот узел. Используются для подстановки плейсхолдеров в промпт.';

  @override
  String get nodeConfigRepos => 'Репозитории для клонирования';

  @override
  String get nodeConfigReposHelp =>
      'Репозитории клонируются и индексируются, когда узел начинает разговор. Выбор всех репозиториев клонирует каждый (так по умолчанию).';

  @override
  String get nodeConfigRepoBranchHint => 'Ветка (по умолчанию)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'Ветка, от которой создаётся каждый checkout. Оставьте пустым, чтобы взять ветку репозитория по умолчанию — у рабочего дерева всё равно будет своя ветка, поэтому коммиты агента сюда не попадут.';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'Сохранены динамические записи: $entries';
  }

  @override
  String get nodeConfigCreateConversation => 'Открыть в нём разговор';

  @override
  String get nodeConfigCreateConversationHelp =>
      'Оставьте выключенным, если дальше несколько узлов агентов — каждый откроет свой именованный поток. Включите, если дальше один узел агента, чтобы в комнате не появлялся безымянный разговор рядом с ним.';

  @override
  String get nodeConfigConversationTitle => 'Название разговора';

  @override
  String get nodeConfigConversationTitleHelp =>
      'Задайте узлу агента дальше то же имя — оба будут работать в одном потоке. По умолчанию — метка узла.';

  @override
  String get nodeConfigSpaceName => 'Название пространства';

  @override
  String get nodeConfigSpaceNameHelp =>
      'Как называется комната, которую открывает этот узел. Поддерживает те же плейсхолдеры состояния, что и промпт. Оставьте пустым, чтобы взять метку узла.';

  @override
  String get nodeConfigSpaceNameHint => 'Ревью pr_number';

  @override
  String get nodeConfigStreamTitle => 'Название разговора';

  @override
  String get nodeConfigStreamTitleHelp =>
      'Именованный поток, в котором агент этого узла работает внутри комнаты. Поддерживает те же плейсхолдеры состояния, что и промпт. Если оставить пустым, ход попадёт в постоянный разговор комнаты, где fan-out чередует всех агентов.';

  @override
  String get nodeConfigConversationTitleHint => 'Анализ архитектуры';

  @override
  String get nodeConfigOutputKey => 'Ключ выхода';

  @override
  String get nodeConfigPrompt => 'Шаблон промпта';

  @override
  String get nodeConfigPromptHelp =>
      'Используйте плейсхолдеры в двойных фигурных скобках, чтобы брать значения из состояния во время выполнения.';

  @override
  String get nodeConfigScript => 'Скрипт bash';

  @override
  String get nodeConfigScriptHelp =>
      'Запускается через bash -c в песочнице ОС. В GH_TOKEN и GITHUB_TOKEN — токен только для чтения для связанного репозитория. Плейсхолдеры перед выполнением берутся в кавычки и подставляются.';

  @override
  String get nodeConfigRouteKeys => 'Ключи маршрута';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Ключ маршрута от $source';
  }

  @override
  String get conditionSectionTitle => 'Условие';

  @override
  String get conditionMode => 'Режим';

  @override
  String get conditionModeFilesAny => 'Файл(ы) существуют — любой';

  @override
  String get conditionModeFilesAll => 'Файлы существуют — все';

  @override
  String get conditionModeComparison => 'Сравнение';

  @override
  String get conditionModeSwitch => 'Переключить';

  @override
  String get conditionFilePaths => 'Пути к файлам';

  @override
  String get conditionFilePathsAnyHelp =>
      'По одному пути на строку, относительно базового каталога. Срабатывает, если существует любой из них.';

  @override
  String get conditionFilePathsAllHelp =>
      'По одному пути на строку, относительно базового каталога. Срабатывает, только если существуют все.';

  @override
  String get conditionBaseKey => 'Ключ базового каталога';

  @override
  String get conditionBaseKeyHelp =>
      'Ключ состояния с каталогом, относительно которого разрешаются пути (по умолчанию repo_local_path).';

  @override
  String get conditionRecursive => 'Искать в подкаталогах';

  @override
  String get conditionNegate => 'Инвертировать: срабатывать, если отсутствует';

  @override
  String get conditionLeft => 'Левое значение';

  @override
  String get conditionOperator => 'Оператор';

  @override
  String get conditionRight => 'Правое значение';

  @override
  String get conditionSwitchKey => 'Переключение по ключу состояния';

  @override
  String get conditionCases => 'Варианты (через запятую)';

  @override
  String get conditionCasesHelp =>
      'Ключи маршрутов для сопоставления со значением, по порядку.';

  @override
  String get conditionDefaultCase => 'Вариант по умолчанию';

  @override
  String get triggerManualHelp =>
      'Показывать на странице запуска и запускать вручную.';

  @override
  String get triggerKindSchedule => 'По расписанию';

  @override
  String get triggerScheduleExprLabel => 'Расписание (cron или every:seconds)';

  @override
  String get triggerTimezoneLabel => 'Часовой пояс (необязательно)';

  @override
  String get triggerCatchUpLabel => 'При пропущенных запусках';

  @override
  String get triggerCatchUpRunOnce => 'Запустить один раз';

  @override
  String get triggerCatchUpSkip => 'Пропустить';

  @override
  String get syncHealthTitle => 'Состояние синхронизации';

  @override
  String get syncHealthNoConfigs => 'Подключений синхронизации пока нет';

  @override
  String get syncHealthNeverSynced => 'Никогда не синхронизировалось';

  @override
  String get syncOutcomeOk => 'Синхронизировано';

  @override
  String get syncOutcomeFailed => 'Сбой';

  @override
  String get syncOutcomeSkipped => 'Пропущено';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count сбоев подряд';
  }

  @override
  String get triggerWebhookHelp =>
      'Создаётся подписанный URL webhook. Внешние системы отправляют на него POST, чтобы запустить этот конвейер.';

  @override
  String get triggerWebhookPathLabel => 'Путь вебхука';

  @override
  String get triggerMatchStatusLabel => 'Только при статусе';

  @override
  String get triggerSummaryNone => 'Нет триггеров';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Каждые $seconds с';
  }

  @override
  String get triggerEventManual => 'Ручной запуск';

  @override
  String get triggerEventSchedule => 'Расписание';

  @override
  String get triggerEventPrStatusChanged => 'Изменился статус PR';

  @override
  String get triggerEventExternalPr => 'Открыт внешний PR';

  @override
  String get triggerEventPrPublished => 'PR опубликован';

  @override
  String get triggerEventPrMerged => 'PR смержен';

  @override
  String get triggerEventRepoAdded => 'Репозиторий добавлен';

  @override
  String get triggerEventCodeGraphWatch => 'Изменение файла';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count изменённых файла',
      many: '$count изменённых файлов',
      few: '$count изменённых файла',
      one: '$count изменённый файл',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return 'ещё +$count';
  }

  @override
  String get pipelineRunCauseRescan => 'Изменено на диске';

  @override
  String get pipelineRunCauseInitial => 'Первая индексация этого checkout';

  @override
  String get triggerEventMessageReceived => 'Получено сообщение';

  @override
  String get triggerEventTicketCompleted => 'Тикет выполнен';

  @override
  String get triggerEventTicketFailed => 'Сбой тикета';

  @override
  String get triggerEventTicketCancelled => 'Тикет отменён';

  @override
  String get triggerEventBudgetCrossed => 'Превышен порог бюджета';

  @override
  String get nodeLibrarySearchHint => 'Поиск узлов';

  @override
  String get nodeLibraryNoMatches => 'Нет подходящих узлов';

  @override
  String get nodeCategoryFlow => 'Поток и логика';

  @override
  String get nodeCategoryPr => 'Ревью PR';

  @override
  String get nodeCategoryAgents => 'Агенты';

  @override
  String get nodeCategoryMessaging => 'Сообщения';

  @override
  String get nodeCategoryCode => 'Код';

  @override
  String get triggerDisabledTag => 'выкл.';

  @override
  String get pipelineInputTypeRepo => 'Репозиторий';

  @override
  String get pipelineRunNoRepos =>
      'В этом рабочем пространстве пока нет репозиториев.';

  @override
  String get ticketingApiKey => 'API-ключ тикетов';

  @override
  String get ticketingProvider => 'Провайдер тикетов';

  @override
  String get connectGitHubAndTicketing =>
      'Подключите хост кода, чтобы Control Center мог читать ваши pull requests, issues и ревью. При необходимости подключите провайдера тикетов. Учётные данные хранятся на вашем сервере, а не на этой машине.';

  @override
  String get triggerEventTicketAssigned => 'Тикет назначен';

  @override
  String get triggerEventTicketCreated => 'Тикет создан';

  @override
  String get triggerEventTicketStatusChanged => 'Статус тикета изменён';

  @override
  String get triggerEventMeetingRecordingStopped =>
      'Запись встречи остановлена';

  @override
  String get triggerEventSkillUpdated => 'Навык обновлён';

  @override
  String get triggerEventSpaceDeleted => 'Пространство удалено';

  @override
  String get triggerEventSpaceArchived => 'Пространство заархивировано';

  @override
  String get triggerEventSpaceProvisioningChanged =>
      'Подготовка пространства изменилась';

  @override
  String get triggerEventPrHeadChanged => 'Head PR изменён';

  @override
  String get triggerEventEnvironmentStatusChanged => 'Статус окружения изменён';

  @override
  String get triggerEventEnvironmentReady => 'Окружение готово';

  @override
  String get triggerEventEnvironmentDestroyed => 'Окружение уничтожено';

  @override
  String get triggerEventEnvironmentProcessExited =>
      'Процесс окружения завершён';

  @override
  String get triggerExternalPrHelp =>
      'Pull request, открытый на хосте кода, а не из Control Center.';

  @override
  String get triggerPrPublishedHelp =>
      'Pull request, открытый из Control Center или агентом.';

  @override
  String get triggerPrStatusChangedHelp =>
      'Слит, закрыт, открыт, заново открыт или одобрен. Фильтруйте по статусу в инспекторе.';

  @override
  String get triggerPrMergedHelp =>
      'Только когда pull request сливают, не когда закрывают или открывают заново.';

  @override
  String get triggerRepoAddedHelp =>
      'Репозиторий связывается с этим рабочим пространством.';

  @override
  String get triggerCodeGraphWatchHelp =>
      'Файл в связанном репозитории меняется на диске.';

  @override
  String get triggerMessageReceivedHelp =>
      'В пространство приходит новое сообщение.';

  @override
  String get triggerTicketCreatedHelp =>
      'В этом рабочем пространстве создаётся тикет.';

  @override
  String get triggerTicketStatusChangedHelp =>
      'Тикет переходит между статусами.';

  @override
  String get triggerTicketCompletedHelp => 'Тикет успешно завершается.';

  @override
  String get triggerTicketFailedHelp =>
      'Запуск агента не удался, и тикет помечается как неудачный.';

  @override
  String get triggerTicketCancelledHelp => 'Тикет отменяется и не продолжится.';

  @override
  String get triggerBudgetCrossedHelp =>
      'Превышен лимит расходов рабочего пространства или агента.';

  @override
  String get triggerTicketAssignedHelp =>
      'Тикет назначается человеку, агенту или команде.';

  @override
  String get triggerMeetingRecordingStoppedHelp =>
      'Запись встречи заканчивается.';

  @override
  String get triggerSkillUpdatedHelp =>
      'Навык устанавливается или обновляется.';

  @override
  String get triggerSpaceDeletedHelp => 'Пространство беседы удаляется.';

  @override
  String get triggerSpaceArchivedHelp => 'Пространство беседы архивируется.';

  @override
  String get triggerSpaceProvisioningChangedHelp =>
      'Подготовка рабочих деревьев пространства начинается, завершается или прерывается ошибкой.';

  @override
  String get triggerPrHeadChangedHelp =>
      'В открытый pull request отправлены новые коммиты.';

  @override
  String get triggerEnvironmentStatusChangedHelp =>
      'Окружение пространства переходит в новый статус.';

  @override
  String get triggerEnvironmentReadyHelp =>
      'Окружение пространства запущено и готово к работе.';

  @override
  String get triggerEnvironmentDestroyedHelp =>
      'Окружение пространства удаляется.';

  @override
  String get triggerEnvironmentProcessExitedHelp =>
      'Процесс, запущенный окружением, завершается.';

  @override
  String get navTickets => 'Тикеты';

  @override
  String get ticketsTitle => 'Тикеты';

  @override
  String get newTicket => 'Новый тикет';

  @override
  String get noTicketsYet => 'Тикетов пока нет';

  @override
  String get addCollaborator => 'Добавить участника';

  @override
  String get noCollaborators => 'Участников пока нет';

  @override
  String get linkedPullRequests => 'Связанные pull requests';

  @override
  String get noLinkedPullRequests => 'Связанных pull requests пока нет';

  @override
  String get stopAgent => 'Остановить агента';

  @override
  String get ticketProperties => 'Свойства';

  @override
  String get ticketTabIssue => 'Задача';

  @override
  String get ticketSelectPrompt =>
      'Выберите тикет, чтобы посмотреть подробности';

  @override
  String get unassigned => 'Не назначен';

  @override
  String get ticketStatusBacklog => 'Бэклог';

  @override
  String get ticketStatusOpen => 'К выполнению';

  @override
  String get ticketStatusInProgress => 'В работе';

  @override
  String get ticketStatusInReview => 'На ревью';

  @override
  String get ticketStatusDone => 'Готово';

  @override
  String get ticketStatusBlocked => 'Заблокировано';

  @override
  String get ticketStatusFailed => 'Сбой';

  @override
  String get ticketStatusCancelled => 'Отменено';

  @override
  String get notificationTicketAssigned => 'Тикет назначен';

  @override
  String get notificationTicketStatusChanged => 'Статус тикета изменён';

  @override
  String get priority => 'Приоритет';

  @override
  String get status => 'Статус';

  @override
  String get assignee => 'Исполнитель';

  @override
  String get labels => 'Метки';

  @override
  String get noLabelsYet => 'Меток пока нет';

  @override
  String get clearLabels => 'Очистить метки';

  @override
  String get pipelineStepAgentActivity => 'Активность агента';

  @override
  String get runStatusCompleted => 'Завершено';

  @override
  String get runStatusQueued => 'В очереди';

  @override
  String get ticketDescription => 'Описание';

  @override
  String get ticketPriorityNone => 'Нет';

  @override
  String get ticketPriorityUrgent => 'Срочный';

  @override
  String get ticketPriorityHigh => 'Высокий';

  @override
  String get ticketPriorityMedium => 'Средний';

  @override
  String get ticketPriorityLow => 'Низкий';

  @override
  String get ticketViewList => 'Список';

  @override
  String get ticketViewBoard => 'Доска';

  @override
  String get ticketTitlePlaceholder => 'Название задачи';

  @override
  String get ticketDescriptionPlaceholder => 'Добавьте описание…';

  @override
  String get createMore => 'Создать ещё';

  @override
  String selectedCount(int count) {
    return '$count выбрано';
  }

  @override
  String get clearSelection => 'Снять выделение';

  @override
  String get bulkDeleteTitle => 'Удалить тикеты';

  @override
  String bulkDeleteMessage(int count) {
    return 'Удалить $count выбранных тикетов? Это нельзя отменить.';
  }

  @override
  String get assignTo => 'Назначить…';

  @override
  String get sectionMembers => 'Участники';

  @override
  String get sectionAgents => 'Агенты';

  @override
  String get sidebarGroupWorkspace => 'Рабочее пространство';

  @override
  String get notificationsTitle => 'Уведомления';

  @override
  String get notificationsTooltip => 'Уведомления';

  @override
  String get notificationsEmpty => 'Вы всё просмотрели';

  @override
  String notificationsUnreadCount(int count) {
    return '$count непрочитанных';
  }

  @override
  String get notificationsMarkRead => 'Отметить как прочитанное';

  @override
  String get notificationsMarkUnread => 'Отметить как непрочитанное';

  @override
  String get notificationsEntryActions => 'Действия с уведомлением';

  @override
  String get markAllRead => 'Отметить все как прочитанные';

  @override
  String get teamsNav => 'Команды';

  @override
  String get noWorkspace => 'Нет рабочего пространства';

  @override
  String get selectWorkspace => 'Выберите рабочее пространство';

  @override
  String get navMemory => 'Память';

  @override
  String get memoryTabFacts => 'Факты';

  @override
  String get memoryTabPolicies => 'Политики';

  @override
  String get memoryGraphShowFacts => 'Показать факты';

  @override
  String get memoryGraphHideFacts => 'Скрыть факты';

  @override
  String get memoryGraphExpandAll => 'Развернуть все факты';

  @override
  String get memoryGraphCollapseAll => 'Свернуть все факты';

  @override
  String get memoryTabGraph => 'Граф знаний';

  @override
  String get memoryNoWorkspace =>
      'Выберите рабочее пространство, чтобы просмотреть его память.';

  @override
  String get searchArticles => 'Поиск статей';

  @override
  String get filterAll => 'Все';

  @override
  String get filterUnread => 'Непрочитанные';

  @override
  String get filterSaved => 'Сохранённые';

  @override
  String get saveArticle => 'Сохранить статью';

  @override
  String get removeFromSaved => 'Удалить из сохранённых';

  @override
  String get filterBySource => 'Фильтр по источнику';

  @override
  String get viewAsList => 'Вид списком';

  @override
  String get viewAsGrid => 'Вид сеткой';

  @override
  String get noMatchingArticles => 'Нет подходящих статей';

  @override
  String get noMatchingArticlesBody =>
      'Попробуйте другой поиск или фильтр по источнику.';

  @override
  String get allCaughtUp => 'Всё прочитано';

  @override
  String get allCaughtUpBody => 'Нет непрочитанных статей — загляните позже.';

  @override
  String get openArticlesInAppDescription =>
      'Открывать ссылки во встроенной читалке, а не в браузере по умолчанию.';

  @override
  String get blockAdsTrackersDescription =>
      'Убирать рекламу, трекеры и cookie-баннеры из статей, открытых в читалке.';

  @override
  String get agentQuestionHeader => 'Вопрос для вас';

  @override
  String get agentQuestionAnsweredLabel => 'Отвечено';

  @override
  String get agentQuestionFreeformHint => 'Введите ответ…';

  @override
  String agentQuestionProgress(int index, int count) {
    return 'Вопрос $index из $count';
  }

  @override
  String get agentQuestionSkip => 'Пропустить';

  @override
  String get agentQuestionSkippedLabel => 'Пропущено';

  @override
  String get agentQuestionTimedOutLabel => 'Время истекло';

  @override
  String get agentQuestionTimeLeft => 'Оставшееся время на ответ';

  @override
  String get agentQuestionFreeformOptionHint => 'Опишите своими словами…';

  @override
  String get reviewRequested => 'Запрошено ревью';

  @override
  String get noRepositoriesConfigured => 'Репозитории не настроены';

  @override
  String openedAgo(String age) {
    return 'Открыт $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author открыл этот pull request';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count коммита',
      many: '$count коммитами',
      few: '$count коммитами',
      one: '$count коммитом',
    );
    return '$author открыл этот pull request с $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor запросил ревью у $reviewers';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor снял запрос ревью с $reviewers';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor запросил ревью у $requested и снял запрос ревью с $removed';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'метки',
      one: 'метку',
    );
    return '$actor добавил $_temp0 $labels';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'метки',
      one: 'метку',
    );
    return '$actor удалил $_temp0 $labels';
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
      other: 'метки',
      one: 'метку',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: 'метки',
      one: 'метку',
    );
    return '$actor добавил $_temp0 $added и удалил $_temp1 $removed';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author сделал коммит';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count коммита',
      many: '$count коммитов',
      few: '$count коммита',
      one: '$count коммит',
    );
    return '$author отправил $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author одобрил эти изменения';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author запросил изменения';
  }

  @override
  String prTimelineApprovedWithComments(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count комментария',
      many: '$count комментариев',
      few: '$count комментария',
      one: '$count комментарий',
    );
    return '$author одобрил эти изменения и оставил $_temp0';
  }

  @override
  String prTimelineChangesRequestedWithComments(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count комментария',
      many: '$count комментариев',
      few: '$count комментария',
      one: '$count комментарий',
    );
    return '$author запросил изменения и оставил $_temp0';
  }

  @override
  String prTimelineReviewedWithComments(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count комментария',
      many: '$count комментариев',
      few: '$count комментария',
      one: '$count комментарий',
    );
    return '$author проверил и оставил $_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author проверил';
  }

  @override
  String get prTimelineSomeone => 'Кто-то';

  @override
  String get prTimelineBotBadge => 'бот';

  @override
  String updatedAgo(String age) {
    return 'Обновлено $age';
  }

  @override
  String get checksPassing => 'Проверки пройдены';

  @override
  String get checksRunning => 'Проверки выполняются';

  @override
  String get needsYourReview => 'Нужна ваша проверка';

  @override
  String get checks => 'Проверки';

  @override
  String get noReviewersAssigned => 'Ревьюеры не назначены';

  @override
  String get noAssignees => 'Нет исполнителей';

  @override
  String get loadingEllipsis => 'Загрузка…';

  @override
  String get loadingChecks => 'Загрузка проверок…';

  @override
  String get noChecksYet => 'Проверки ещё не запускались';

  @override
  String get noChangesToReview => 'Нет изменений для ревью';

  @override
  String checksFailingCount(int count) {
    return '$count не пройдено';
  }

  @override
  String get showMore => 'Показать ещё';

  @override
  String get showLess => 'Показать меньше';

  @override
  String get backToPullRequests => 'Назад к pull requests';

  @override
  String get pullRequestNotFound => 'Pull request не найден';

  @override
  String get pullRequestNotFoundBody =>
      'Возможно, он объединён, закрыт или перемещён.';

  @override
  String get couldntLoadPullRequest => 'Не удалось загрузить этот pull request';

  @override
  String get showDetails => 'Подробнее';

  @override
  String get noDescriptionProvided => 'Описание не указано.';

  @override
  String get factsHint => 'Факты появятся здесь по мере обучения агентов.';

  @override
  String get noFactsMatch => 'Нет фактов по запросу';

  @override
  String get memoryLoadError => 'Не удалось загрузить память';

  @override
  String get sortRecent => 'Недавние';

  @override
  String get sortConfidence => 'Уверенность';

  @override
  String get confidenceTooltip =>
      'Насколько агенты уверены, что факт верен: от 0 до 100%.';

  @override
  String get supersededTooltip => 'Этот факт заменён более новым.';

  @override
  String get domain => 'Домен';

  @override
  String get fitToView => 'Вписать в экран';

  @override
  String get project => 'Проект';

  @override
  String get newProject => 'Новый проект';

  @override
  String get editProject => 'Изменить проект';

  @override
  String get deleteProject => 'Удалить проект';

  @override
  String get noProject => 'Без проекта';

  @override
  String get allTickets => 'Все тикеты';

  @override
  String get projectNamePlaceholder => 'Название проекта';

  @override
  String get projectDescriptionPlaceholder => 'Описание (необязательно)';

  @override
  String get projectColorLabel => 'Цвет';

  @override
  String get noProjectsYet => 'Пока нет проектов';

  @override
  String get projectTicketsEmpty => 'В этом проекте пока нет тикетов';

  @override
  String get createProject => 'Создать проект';

  @override
  String projectProgress(int done, int total) {
    return '$done из $total готово';
  }

  @override
  String deleteProjectConfirm(String name) {
    return 'Удалить «$name»? Тикеты сохранятся и будут убраны из проекта.';
  }

  @override
  String get projectStatusActive => 'Активный';

  @override
  String get projectStatusCompleted => 'Завершён';

  @override
  String get projectStatusArchived => 'В архиве';

  @override
  String get markProjectCompleted => 'Отметить завершённым';

  @override
  String get markProjectActive => 'Отметить активным';

  @override
  String get archiveProject => 'Архивировать';

  @override
  String get restoreProject => 'Восстановить';

  @override
  String get relations => 'Связи';

  @override
  String get relateTo => 'Связать с';

  @override
  String get relationSubIssueOf => 'Подтикет для…';

  @override
  String get relationParentOf => 'Родитель для…';

  @override
  String get relationBlockedBy => 'Блокируется…';

  @override
  String get relationBlocking => 'Блокирует…';

  @override
  String get relationRelatedTo => 'Связано с…';

  @override
  String get relationDuplicateOf => 'Дубликат…';

  @override
  String get relationGroupParent => 'Родитель';

  @override
  String get relationGroupSubIssues => 'Подтикеты';

  @override
  String get relationGroupBlockedBy => 'Блокируется';

  @override
  String get relationGroupBlocking => 'Блокирует';

  @override
  String get relationGroupRelated => 'Связано';

  @override
  String get relationGroupDuplicateOf => 'Дубликат';

  @override
  String get relationGroupDuplicatedBy => 'Дублируется';

  @override
  String get copyId => 'Копировать ID';

  @override
  String get ticketIdCopied => 'ID тикета скопирован';

  @override
  String get searchTicketsHint => 'Поиск тикетов…';

  @override
  String get noMatchingTickets => 'Нет подходящих тикетов';

  @override
  String get clearAll => 'Очистить всё';

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PR ожидают вашей проверки',
      many: '$prs PR ожидают вашей проверки',
      few: '$prs PR ожидают вашей проверки',
      one: '$prs PR ожидает вашей проверки',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos репозиториях',
      many: '$repos репозиториях',
      few: '$repos репозиториях',
      one: '$repos репозитории',
    );
    return '$_temp0 в $_temp1';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'Переименуйте рабочее пространство и измените его метку — выберите слева, чтобы править.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count рабочих пространств',
      many: '$count рабочих пространств',
      few: '$count рабочих пространства',
      one: '$count рабочее пространство',
      zero: 'Нет рабочих пространств',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos репозиториев',
      many: '$repos репозиториев',
      few: '$repos репозитория',
      one: '$repos репозиторий',
      zero: 'Нет репозиториев',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents агентов',
      many: '$agents агентов',
      few: '$agents агента',
      one: '$agents агент',
      zero: '0 агентов',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'Идентичность';

  @override
  String get uploadImage => 'Загрузить изображение';

  @override
  String get failedToSaveLogo =>
      'Не удалось сохранить изображение логотипа. Убедитесь, что приложение может прочитать выбранный файл.';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG или GIF до 2 МБ. Иначе используем первую букву рабочего пространства.';

  @override
  String get workspaceNameFieldHelp =>
      'Отображается в переключателе, в хлебных крошках и на каждом экране.';

  @override
  String get dangerZone => 'Опасная зона';

  @override
  String get deleteThisWorkspace => 'Удалить это рабочее пространство';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Безвозвратно удаляет $name, его подключения репозиториев, агентов и память. Это нельзя отменить.';
  }

  @override
  String get discard => 'Отменить';

  @override
  String discardChangesQuestion(String name) {
    return 'Отменить несохранённые изменения в $name?';
  }

  @override
  String get workspaceUpdated => 'Рабочее пространство обновлено';

  @override
  String get editTitle => 'Изменить заголовок';

  @override
  String get editDescription => 'Изменить описание';

  @override
  String get addDescription => 'Добавить описание';

  @override
  String get prTitlePlaceholder => 'Заголовок';

  @override
  String get prBodyPlaceholder => 'Оставьте описание';

  @override
  String get write => 'Написать';

  @override
  String get overview => 'Обзор';

  @override
  String get noFilesChanged => 'Файлы не изменены';

  @override
  String get diff => 'Различия';

  @override
  String get preview => 'Предпросмотр';

  @override
  String get imageDiffBefore => 'До';

  @override
  String get imageDiffAfter => 'После';

  @override
  String get imageDiffModeTwoUp => 'Рядом';

  @override
  String get imageDiffModeSwipe => 'Свайп';

  @override
  String get imageDiffModeDifference => 'Разница';

  @override
  String imageDiffChangedPercent(String percent) {
    return 'изменено $percent %';
  }

  @override
  String get imageDiffPictures => 'Изображения';

  @override
  String get imageDiffSource => 'Исходник';

  @override
  String get imageDiffDeleted => 'Удалено';

  @override
  String get imageDiffAdded => 'Добавлено';

  @override
  String imageDiffDimensions(int width, int height) {
    return 'Ш: ${width}px | В: ${height}px';
  }

  @override
  String get outdated => 'Устарело';

  @override
  String get outdatedComments => 'Устаревшие комментарии';

  @override
  String outdatedCountLabel(int count) {
    return '$count устаревших';
  }

  @override
  String get prTemplateLabel => 'Шаблон';

  @override
  String get prTemplateDefault => 'По умолчанию';

  @override
  String get addReviewers => 'Добавить рецензентов';

  @override
  String get reRequestReview => 'Повторно запросить проверку';

  @override
  String reRequestReviewFor(String label) {
    return 'Повторно запросить проверку у $label';
  }

  @override
  String get addAssignees => 'Добавить исполнителей';

  @override
  String get addLabels => 'Добавить метки';

  @override
  String get searchLabels => 'Искать метки…';

  @override
  String get noMatchingLabels => 'Нет подходящих меток';

  @override
  String removeLabel(String label) {
    return 'Удалить $label';
  }

  @override
  String get searchUsers => 'Поиск людей…';

  @override
  String get searchReviewers => 'Поиск людей и команд…';

  @override
  String get usersSectionLabel => 'Люди';

  @override
  String get userStatusBusy => 'Занят';

  @override
  String get teamsSectionLabel => 'Команды';

  @override
  String get suggestedReviewers => 'Предложенные рецензенты';

  @override
  String get noMatchingUsers => 'Нет подходящих людей';

  @override
  String get noMatchingReviewers => 'Нет совпадений';

  @override
  String get requiredByCodeOwners => 'Требуется владельцами кода';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'через $login';
  }

  @override
  String get team => 'Команда';

  @override
  String get markdownBold => 'Жирный';

  @override
  String get markdownItalic => 'Курсив';

  @override
  String get markdownHeading => 'Заголовок';

  @override
  String get markdownBulletList => 'Маркированный список';

  @override
  String get markdownChecklist => 'Чеклист';

  @override
  String get markdownCode => 'Код';

  @override
  String get markdownLink => 'Ссылка';

  @override
  String get markdownQuote => 'Цитата';

  @override
  String get markdownTabIndentHint =>
      'Здесь Tab выполняет отступ. Нажмите Esc, затем Tab, чтобы перейти к следующему элементу управления.';

  @override
  String get markdownSupported => 'Поддерживается Markdown';

  @override
  String get markdownAttachImages => 'Нажмите, чтобы добавить изображения';

  @override
  String failedToUpdateTitle(String error) {
    return 'Не удалось обновить название: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Не удалось обновить описание: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Не удалось обновить ревьюеров: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Не удалось обновить исполнителей: $error';
  }

  @override
  String failedToUpdateLabels(String error) {
    return 'Не удалось обновить метки: $error';
  }

  @override
  String get discardChangesConfirm => 'Отменить изменения?';

  @override
  String get newPr => 'Новый PR';

  @override
  String get openPullRequest => 'Открыть pull request';

  @override
  String get composePrSubtitle =>
      'Из ветки, которую вы отправили — без агентов и тикетов';

  @override
  String get createAsDraft => 'Создать как черновик';

  @override
  String get composePrPickBranches =>
      'Выберите базовую и сравниваемую ветки, чтобы увидеть изменения.';

  @override
  String get composePrNothingToCompare => 'Между этими ветками нет изменений.';

  @override
  String get repository => 'Репозиторий';

  @override
  String get baseBranchLabel => 'База';

  @override
  String get compareBranchLabel => 'Сравнение';

  @override
  String get selectBranch => 'Выберите ветку';

  @override
  String get navMeetings => 'Встречи';

  @override
  String get meetingsNoWorkspace =>
      'Выберите рабочее пространство, чтобы увидеть встречи.';

  @override
  String get meetingsEmpty => 'Пока нет встреч';

  @override
  String get meetingsEmptyHint =>
      'Запишите первую встречу — аудио остаётся на этом устройстве, а агент превращает его в заметки, решения и задачи.';

  @override
  String get meetingNotesHint =>
      'Набросайте заметки — агент разовьёт их после встречи.';

  @override
  String get meetingSpeakerMe => 'Вы';

  @override
  String get meetingStatusRecording => 'Запись';

  @override
  String get meetingStatusPaused => 'На паузе';

  @override
  String get meetingStatusProcessing => 'Обработка';

  @override
  String get meetingStatusDone => 'Готово';

  @override
  String get meetingStatusFailed => 'Ошибка';

  @override
  String get meetingsSubtitle =>
      'Запись и транскрипция на этом устройстве, затем агент составляет саммари.';

  @override
  String get meetingsRecordMeeting => 'Записать встречу';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count обрабатываются',
      many: '$count обрабатываются',
      few: '$count обрабатываются',
      one: '$count обрабатывается',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLiveOpen => 'Открыть запись';

  @override
  String get meetingTemplateShort => 'Шаблон';

  @override
  String get meetingsFilterAll => 'Все';

  @override
  String get meetingsFilterDone => 'Готово';

  @override
  String get meetingsFilterProcessing => 'Обработка';

  @override
  String get meetingsSearchHint => 'Фильтр по названию, человеку, приложению…';

  @override
  String get meetingsBucketToday => 'Сегодня';

  @override
  String get meetingsBucketYesterday => 'Вчера';

  @override
  String get meetingsBucketEarlierThisWeek => 'Ранее на этой неделе';

  @override
  String get meetingsBucketLastWeek => 'На прошлой неделе';

  @override
  String get meetingsBucketOlder => 'Ранее';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count решений',
      many: '$count решений',
      few: '$count решения',
      one: '$count решение',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total задач';
  }

  @override
  String get meetingsTranscribing => 'транскрипция и саммари…';

  @override
  String get meetingsOpenAction => 'Открыть';

  @override
  String get meetingsStopProcessing => 'Остановить';

  @override
  String get meetingsStillTranscribing =>
      'Транскрибирование ещё идёт — сводка появится, когда оно завершится.';

  @override
  String get meetingsNoMatch => 'Нет подходящих встреч';

  @override
  String get meetingsNoMatchHint =>
      'Попробуйте другой фильтр или поисковый запрос.';

  @override
  String get meetingBackAllMeetings => 'Все встречи';

  @override
  String get meetingReRunSummary => 'Пересоздать сводку';

  @override
  String get meetingExport => 'Экспорт';

  @override
  String get meetingAugmentingBanner =>
      'Дополняем ваши заметки по транскрипту — извлекаем решения и пункты действий…';

  @override
  String get meetingTabNotes => 'Заметки';

  @override
  String get meetingTabTranscript => 'Транскрипт';

  @override
  String get meetingTabActionItems => 'Пункты действий';

  @override
  String get meetingTabDecisions => 'Решения';

  @override
  String get meetingNotesEnhancedToggle => 'Улучшенные';

  @override
  String get meetingNotesYoursToggle => 'Ваши заметки';

  @override
  String get meetingEnhancedByAgent => 'Улучшено агентом · по транскрипту';

  @override
  String get meetingEnhancedPending => 'Агент ещё работает над этой сводкой.';

  @override
  String get meetingNotesEmpty => 'Улучшенных заметок пока нет.';

  @override
  String get meetingNotesSavedLocally => 'Сохранено локально';

  @override
  String get meetingNotesSaving => 'Сохранение…';

  @override
  String get meetingViewFullTranscript => 'Открыть полный транскрипт';

  @override
  String get meetingTranscriptSearchHint => 'Поиск по транскрипту…';

  @override
  String get meetingSpeakerEveryone => 'Все';

  @override
  String get meetingSpeakerOthers => 'Остальные';

  @override
  String get meetingTranscriptEmpty => 'Транскрипта пока нет.';

  @override
  String get meetingActionItemsEmpty => 'Пункты действий не извлечены.';

  @override
  String get meetingActionItemFrom => 'из этой встречи';

  @override
  String get meetingCreateTicket => 'Создать тикет';

  @override
  String meetingTicketCreated(String key) {
    return 'Тикет $key создан и отправлен.';
  }

  @override
  String get meetingTicketFailed => 'Не удалось создать тикет.';

  @override
  String get meetingDecisionsEmpty => 'Решения не зафиксированы.';

  @override
  String get meetingEditTitle => 'Изменить название';

  @override
  String get meetingTitleLabel => 'Название';

  @override
  String get meetingAddActionItem => 'Добавить пункт действий';

  @override
  String get meetingEditActionItem => 'Изменить пункт действий';

  @override
  String get meetingDeleteActionItem => 'Удалить пункт действий';

  @override
  String get meetingActionItemContentLabel => 'Пункт действий';

  @override
  String get meetingActionItemContentHint => 'Что нужно сделать?';

  @override
  String get meetingActionItemOwnerLabel => 'Ответственный';

  @override
  String get meetingActionItemOwnerHint => 'Кто отвечает? (необязательно)';

  @override
  String get meetingAddDecision => 'Добавить решение';

  @override
  String get meetingEditDecision => 'Изменить решение';

  @override
  String get meetingDeleteDecision => 'Удалить решение';

  @override
  String get meetingDecisionContentLabel => 'Решение';

  @override
  String get meetingDecisionContentHint => 'Что решили?';

  @override
  String get meetingReRunStarted =>
      'Повторно запускаем суммаризацию транскрипта…';

  @override
  String get meetingReRunNoTranscript => 'Пока нет транскрипта для сводки.';

  @override
  String get meetingNotesEmptyDescription =>
      'Создайте их из транскрипта или напишите свои.';

  @override
  String get meetingNotesGenerate => 'Создать заметки';

  @override
  String get meetingNotesWriteOwn => 'Написать свои';

  @override
  String get meetingNothingTranscribed => 'Ничего не было расшифровано.';

  @override
  String get meetingNothingTranscribedDescription =>
      'Транскрипта для сводки нет, но вы можете вести свои заметки.';

  @override
  String get meetingOverviewSpeakers => 'Участники';

  @override
  String get meetingOverviewSpeakersEmpty =>
      'Время речи каждого участника появится, когда будет транскрипт.';

  @override
  String meetingOverviewMoreSpeakers(int count) {
    return 'Ещё $count';
  }

  @override
  String meetingOverviewSpeakerShare(
    String name,
    String share,
    String duration,
  ) {
    return '$name: $share времени речи, $duration';
  }

  @override
  String get meetingOverviewActionItemsAllDone =>
      'Все пункты действий выполнены.';

  @override
  String meetingOverviewViewAll(int count) {
    return 'Показать все ($count)';
  }

  @override
  String get meetingExportCopied =>
      'Заметки скопированы в буфер обмена как Markdown.';

  @override
  String get meetingExportSaved => 'Встреча экспортирована.';

  @override
  String meetingExportFailed(String error) {
    return 'Не удалось экспортировать: $error';
  }

  @override
  String get meetingExportNothing => 'Пока нечего экспортировать.';

  @override
  String get meetingPlaybackPlay => 'Воспроизвести';

  @override
  String get meetingPlaybackPause => 'Пауза';

  @override
  String get meetingPlaybackUnavailable =>
      'Воспроизведение аудио недоступно на этом устройстве.';

  @override
  String get meetingDetectedTitle => 'Обнаружена встреча';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'Похоже, идёт «$label». Записать?';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'Похоже, идёт встреча. Записать?';

  @override
  String get meetingDetectedDismiss => 'Отклонить';

  @override
  String get meetingAutoStopTitle =>
      'Похоже, встреча закончилась. Остановить запись?';

  @override
  String get meetingAutoStopStop => 'Остановить';

  @override
  String get meetingAutoStopKeep => 'Продолжить запись';

  @override
  String get meetingAutoDetect => 'Автоопределение встреч';

  @override
  String get meetingAutoDetectDescription =>
      'Следить за календарём и приложениями для конференций и предлагать запись, когда начинается встреча.';

  @override
  String get meetingsRecordingCrumb => 'Запись…';

  @override
  String get meetingRecordTitleHint => 'Название встречи';

  @override
  String get meetingRecordTappingLabel => 'Захват:';

  @override
  String get meetingRecordMic => 'Микрофон';

  @override
  String get meetingRecordSystemAudio => 'Системный звук';

  @override
  String get meetingRecordPause => 'Пауза';

  @override
  String get meetingRecordResume => 'Продолжить';

  @override
  String get meetingRecordStop => 'Остановить и суммировать';

  @override
  String get meetingRecordYourNotes => 'Ваши заметки';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Пишите, пока слушаете. Хватит нескольких фрагментов — после остановки агент разовьёт их по транскрипту.';

  @override
  String get meetingRecordLiveTranscript => 'Транскрипт в реальном времени';

  @override
  String get meetingRecordDecoding => 'распознавание на устройстве';

  @override
  String get meetingRecordListening =>
      'Слушаем… речь появится здесь через секунду-две, с метками Вы / Другие.';

  @override
  String get meetingRecordPausedHint =>
      'Пауза — звук игнорируется, пока не продолжите.';

  @override
  String get meetingRecordNotActive => 'Нет активной записи.';

  @override
  String get meetingHudRecording => 'запись';

  @override
  String get meetingHudPaused => 'пауза';

  @override
  String get meetingHudOpen => 'Открыть';

  @override
  String get meetingHudStop => 'Стоп';

  @override
  String get meetingToolbarPopOut => 'Вынести';

  @override
  String get meetingToolbarHoldToStop => 'Удерживайте, чтобы остановить запись';

  @override
  String get meetingToolbarSemanticLabel => 'Панель записи встречи';

  @override
  String get orchestrate => 'Оркестрировать';

  @override
  String get orchestrationUnavailable => 'Оркестрация недоступна';

  @override
  String get orchestrationApprove => 'Утвердить план';

  @override
  String get orchestrationReject => 'Отклонить';

  @override
  String get orchestrationCancel => 'Отменить оркестрацию';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count ролей — $hires новых наймов';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count подтикетов';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Ориентировочная стоимость: \$$amount';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total подтикетов готово';
  }

  @override
  String get orchestrationStatusProposed => 'Предложен';

  @override
  String get orchestrationStatusApproved => 'Утверждён';

  @override
  String get orchestrationStatusExecuting => 'Выполняется';

  @override
  String get orchestrationStatusSynthesizing => 'Синтез';

  @override
  String get orchestrationStatusCompleted => 'Завершён';

  @override
  String get orchestrationStatusFailed => 'Сбой';

  @override
  String get orchestrationStatusCancelled => 'Отменён';

  @override
  String get messageFailed => 'Запуск не удался';

  @override
  String get turnLimitReached =>
      'Остановлено по лимиту ходов — ответьте, чтобы продолжить';

  @override
  String get retried => 'Повторено';

  @override
  String replyingTo(String name) {
    return 'ответ $name';
  }

  @override
  String get silenceTimeoutLabel => 'Таймаут тишины (минуты)';

  @override
  String get silenceTimeoutHint =>
      'напр. 15 — завершить запуск, если столько времени нет вывода';

  @override
  String get capabilityJsonMode => 'Режим JSON';

  @override
  String get capabilityModelSelection => 'Выбор модели';

  @override
  String get transcriptThinking => 'Думаю…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'Думал $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'Вношу правки…';

  @override
  String get transcriptStatusReadingFiles => 'Читаю файлы…';

  @override
  String get transcriptStatusSearching => 'Ищу в коде…';

  @override
  String get transcriptStatusRunningCommands => 'Выполняю команды…';

  @override
  String get transcriptStatusResponding => 'Отвечаю…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'Запускаю $tool…';
  }

  @override
  String get transcriptInput => 'Ввод';

  @override
  String get transcriptOutput => 'Вывод';

  @override
  String get transcriptErrorLabel => 'Ошибка';

  @override
  String get transcriptSandboxBlocked => 'Песочница заблокировала действие';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'Показать полный вывод (+$kb КБ)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'Показать все $count строк';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'Показаны первые $count строк';
  }

  @override
  String get transcriptGrepNoMatches => 'Нет совпадений';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches совпадения',
      many: '$matches совпадений',
      few: '$matches совпадения',
      one: '$matches совпадение',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files файла',
      many: '$files файлов',
      few: '$files файла',
      one: '$files файл',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'Человек $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'Переименовать спикера';

  @override
  String get meetingRenameSpeakerTitle => 'Переименовать спикера';

  @override
  String get meetingSpeakerNameLabel => 'Имя';

  @override
  String get meetingSpeakerSuggestFromCalendar =>
      'Из приглашённых на эту встречу';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'Применить ко всем блокам этого спикера';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'Если выключено, переименовывается только выбранная строка.';

  @override
  String get meetingLinkEvent => 'Привязать к событию';

  @override
  String get meetingChangeEvent => 'Изменить событие';

  @override
  String get meetingLinkEventTitle => 'Привязать к событию календаря';

  @override
  String get meetingLinkEventSearchHint => 'Поиск событий';

  @override
  String get meetingLinkEventEmpty => 'Нет ближайших событий в календаре';

  @override
  String get meetingUnlinkEvent => 'Отвязать';

  @override
  String get calendarLinkExistingMeeting => 'Привязать к существующей встрече';

  @override
  String get calendarLinkMeetingTitle => 'Привязать встречу';

  @override
  String get calendarLinkMeetingSearchHint => 'Поиск встреч';

  @override
  String get calendarLinkMeetingEmpty => 'Нет встреч для привязки';

  @override
  String get meetingRenameSpeakerFailed => 'Не удалось переименовать спикера';

  @override
  String get calendarLinkUpdateFailed =>
      'Не удалось обновить привязку к календарю';

  @override
  String get rename => 'Переименовать';

  @override
  String get notNow => 'Не сейчас';

  @override
  String get meetingSaveVoiceProfileTitle => 'Сохранить голосовой профиль?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'Сохраните голосовой отпечаток, чтобы автоматически узнавать $name на будущих встречах.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'Голосовой профиль $name сохранён';
  }

  @override
  String get meetingVoiceProfileSaveFailed =>
      'Не удалось сохранить голосовой профиль';

  @override
  String get voiceProfilesSection => 'Голосовые профили';

  @override
  String get voiceProfilesDescription =>
      'Сохранённые голоса автоматически распознаются на будущих встречах.';

  @override
  String get voiceProfilesEmpty =>
      'Пока нет сохранённых голосов. Назовите спикера в расшифровке встречи и выберите «Сохранить голосовой профиль».';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count образца',
      many: '$count образцов',
      few: '$count образца',
      one: '$count образец',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'Переименовать голосовой профиль';

  @override
  String get deleteVoiceProfileTitle => 'Удалить голосовой профиль?';

  @override
  String deleteVoiceProfileBody(String name) {
    return 'Перестать узнавать $name? Сохранённый голосовой отпечаток будет удалён. Имена, уже указанные на прошлых встречах, сохранятся.';
  }

  @override
  String get connectedLabel => 'Подключено';

  @override
  String get ideTabGeneral => 'Общие';

  @override
  String get ideTabExplorer => 'Проводник';

  @override
  String get ideTabSourceControl => 'Управление исходным кодом';

  @override
  String get generalSectionTodos => 'Задачи';

  @override
  String get generalSectionGoals => 'Цели';

  @override
  String get goalRunStatusActive => 'Активна';

  @override
  String get goalRunStatusPaused => 'Приостановлена';

  @override
  String get goalRunStatusCompleted => 'Завершена';

  @override
  String get goalRunStatusFailed => 'Ошибка';

  @override
  String get goalRunStatusCancelled => 'Отменена';

  @override
  String get goalRunStatusBudgetExhausted => 'Бюджет исчерпан';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'Запуск $run из $max · $cost из $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'Запуск $run · $cost из $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'Срок $deadline';
  }

  @override
  String get goalRunPause => 'Приостановить цель';

  @override
  String get goalRunResume => 'Возобновить цель';

  @override
  String goalRunResumeRaise(String cap) {
    return 'Возобновить · поднять лимит до $cap';
  }

  @override
  String get goalRunStop => 'Остановить цель';

  @override
  String get generalSectionAgents => 'Агенты';

  @override
  String get generalSectionTerminals => 'Терминалы';

  @override
  String get generalTodosEmpty => 'Пока нет задач';

  @override
  String get generalAgentsEmpty => 'Нет запущенных агентов';

  @override
  String get generalTerminalsEmpty => 'Нет открытых терминалов';

  @override
  String get generalSectionBrowsers => 'Браузеры';

  @override
  String get generalSectionComputers => 'Компьютеры';

  @override
  String get generalBrowsersEmpty => 'Нет открытых браузеров';

  @override
  String get generalComputersEmpty => 'Нет открытых компьютеров';

  @override
  String get generalSectionPhones => 'Телефоны';

  @override
  String get generalPhonesEmpty => 'Нет открытых телефонов';

  @override
  String get pauseAgent => 'Приостановить агента';

  @override
  String get resumeAgent => 'Возобновить агента';

  @override
  String get agentCannotPause =>
      'Этого агента нельзя приостановить — остановите его.';

  @override
  String get goalClear => 'Очистить цель';

  @override
  String get undoLabelGoalClear => 'очистить цель';

  @override
  String get todoStatusPending => 'Не начато';

  @override
  String get todoStatusInProgress => 'В работе';

  @override
  String get todoStatusCompleted => 'Готово';

  @override
  String get reorderTodo => 'Изменить порядок задач';

  @override
  String get focusTerminal => 'Перейти к терминалу';

  @override
  String get focusMachine => 'Перейти к машине';

  @override
  String get focusBrowser => 'Перейти к браузеру';

  @override
  String get todoEditorTitle => 'Редактировать задачи';

  @override
  String get todoEditorHint =>
      'По одному пункту на строку. Используйте - [ ] для неначатых, - [~] для выполняемых, - [x] для готовых.';

  @override
  String get todoNeedsText => 'Добавьте текст после команды';

  @override
  String get todoNotFound => 'Нет подходящей задачи';

  @override
  String get todoCleared => 'Список задач очищен';

  @override
  String get todoNothingToCopy => 'Нечего копировать';

  @override
  String todoAdded(String content) {
    return 'Добавлено «$content»';
  }

  @override
  String todoStarted(String content) {
    return 'Начато «$content»';
  }

  @override
  String todoCompleted(String content) {
    return 'Выполнено «$content»';
  }

  @override
  String todoRemoved(String content) {
    return 'Удалено «$content»';
  }

  @override
  String todoCopied(int count) {
    return 'Скопировано элементов: $count';
  }

  @override
  String todoImported(int count) {
    return 'Импортировано элементов: $count';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'Неизвестная команда todo «$name»';
  }

  @override
  String get terminal => 'Терминал';

  @override
  String get ideCloseTab => 'Закрыть вкладку';

  @override
  String get ideSplitEditor => 'Разделить редактор';

  @override
  String get ideSplitRight => 'Разделить вправо';

  @override
  String get ideSplitDown => 'Разделить вниз';

  @override
  String get ideSplitLeft => 'Разделить влево';

  @override
  String get ideSplitUp => 'Разделить вверх';

  @override
  String get ideCloseGroup => 'Закрыть группу';

  @override
  String get ideCloseOthers => 'Закрыть остальные';

  @override
  String get ideCloseToRight => 'Закрыть справа';

  @override
  String get ideCloseSaved => 'Закрыть сохранённые';

  @override
  String get ideCloseAll => 'Закрыть все';

  @override
  String get ideSplit => 'Разделить';

  @override
  String get ideToggleSidebar => 'Боковая панель';

  @override
  String get ideNewTab => 'Открыть редактор';

  @override
  String get ideNewTabMenu => 'Новая вкладка';

  @override
  String get ideReviewCode => 'Проверить код';

  @override
  String ideReviewCodeInRepo(String repo) {
    return 'Проверить код ($repo)';
  }

  @override
  String get ideRevertConfirmTitle => 'Откатить изменения';

  @override
  String get ideRevertUntracked => 'Неотслеживаемые файлы нельзя откатить';

  @override
  String get ideRevertFailed =>
      'Не удалось откатить файлы. Рабочее дерево разговора может быть недоступно.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файлов не удалось откатить (неотслеживаемые)',
      many: '$count файлов не удалось откатить (неотслеживаемые)',
      few: '$count файла не удалось откатить (неотслеживаемые)',
      one: '$count файл не удалось откатить (неотслеживаемый)',
    );
    return '$_temp0.';
  }

  @override
  String get ideSearchMatchCase => 'Учитывать регистр';

  @override
  String get ideSearchWholeWord => 'Слово целиком';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'Фильтры поиска';

  @override
  String get ideSearchFilesToInclude => 'Включаемые файлы';

  @override
  String get ideSearchFilesToExclude => 'Исключаемые файлы';

  @override
  String get ideNoOpenTabs => 'Нет открытых вкладок — нажмите +, чтобы открыть';

  @override
  String get ideBrowserAddressHint => 'Введите адрес или поисковый запрос';

  @override
  String get ideSimpleWebBrowser => 'Простой веб-браузер';

  @override
  String get ideWebBrowser => 'Веб-браузер';

  @override
  String get ideBrowserEnterUrl =>
      'Введите URL в адресной строке, чтобы начать просмотр';

  @override
  String get ideCodeServer => 'Редактор';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'Сохранить изменения в $fileName?';
  }

  @override
  String get ideUnsavedChangesBody => 'Несохранённые изменения будут потеряны.';

  @override
  String get ideDontSave => 'Не сохранять';

  @override
  String get editorAutoSave => 'Автосохранение';

  @override
  String get editorAutoSaveDescription =>
      'Автоматически сохранять изменения во встроенном редакторе.';

  @override
  String get editorAutoSaveOff => 'Выкл.';

  @override
  String get editorAutoSaveAfterDelay => 'После задержки';

  @override
  String get editorAutoSaveOnFocusChange => 'При смене фокуса';

  @override
  String get ideCodeServerUnavailable =>
      'code-server недоступен на этом сервере';

  @override
  String get ideCodeServerUnavailableHint =>
      'Установите code-server (coder/code-server) на хост сервера, затем откройте редактор заново.';

  @override
  String get ideCodeServerInstalling => 'Подготовка редактора…';

  @override
  String get ideCodeServerOpenInBrowser => 'Открыть редактор в браузере';

  @override
  String get ideCodeServerError => 'Не удалось открыть редактор';

  @override
  String get paneSuspendedCaption =>
      'Приостановлено для экономии ресурсов — перезагрузится при фокусе';

  @override
  String get ideFolderLoadFailed => 'Не удалось загрузить эту папку';

  @override
  String get ideFileSearchFailed => 'Не удалось выполнить поиск файлов';

  @override
  String get ideSearchInFiles => 'Поиск в файлах';

  @override
  String get ideNoContentMatches => 'Нет совпадений';

  @override
  String get ideSourceControlCreatePr => 'Создать pull request';

  @override
  String get ideSourceControlNoChanges => 'Нет изменений';

  @override
  String get noReposInConversation => 'В этом разговоре нет репозиториев';

  @override
  String get ideSourceControlNoSpace =>
      'Откройте разговор, чтобы увидеть его изменения';

  @override
  String get ideFileLoading => 'Загрузка…';

  @override
  String get ideFileBinary => 'Двоичный файл';

  @override
  String get mcpApprovalMode => 'Подтверждение инструментов';

  @override
  String get mcpApprovalModeDescription =>
      'Какие действия собственных инструментов Control Center, вызываемые через его MCP-эндпоинт или его агентами, выполняются без запроса. Чтение всегда разрешено; более высокие уровни запрашивают подтверждение. Серверы внутри запуска следуют политике действий этого запуска.';

  @override
  String get mcpApprovalAlwaysAsk => 'Всегда спрашивать';

  @override
  String get mcpApprovalWrite => 'Автоподтверждение записи';

  @override
  String get mcpApprovalYolo => 'Автоподтверждение всего';

  @override
  String get mcpReconnect => 'Переподключить';

  @override
  String get mcpStatusConnected => 'Подключено';

  @override
  String get mcpStatusConnecting => 'Подключение…';

  @override
  String get mcpStatusNeedsAuth => 'Требуется авторизация';

  @override
  String get mcpStatusFailed => 'Ошибка';

  @override
  String get mcpStatusCircuitOpen => 'Приостановлено';

  @override
  String get mcpStatusDisabled => 'Отключено';

  @override
  String get providersAndModels => 'Провайдеры и модели';

  @override
  String get providersAndModelsDescription =>
      'Список всех провайдеров встроенного агента: укажите API-ключ или войдите через браузер, просматривайте модели и цены каждого подключённого провайдера и выбирайте, какие провайдеры доступны в этом рабочем пространстве.';

  @override
  String get syncNow => 'Синхронизировать';

  @override
  String syncNowResult(int applied, int failed) {
    return 'Синхронизация завершена — применено: $applied, ошибок: $failed';
  }

  @override
  String syncNowFailed(String error) {
    return 'Синхронизация не удалась: $error';
  }

  @override
  String get denied => 'Запрещено';

  @override
  String get allowed => 'Разрешено';

  @override
  String allowProviderSemantic(String provider) {
    return 'Разрешить $provider';
  }

  @override
  String enabledViaEnv(String key) {
    return 'Включено через $key';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output за 1 млн';
  }

  @override
  String contextTokens(String tokens) {
    return '$tokens контекста';
  }

  @override
  String get subscriptionUsage => 'Использование подписки';

  @override
  String get subscriptionUsageUnavailable => 'Недоступно';

  @override
  String get subscriptionUsageExhausted => 'Квота исчерпана';

  @override
  String get subscriptionUsageSignInRequired => 'Войдите снова';

  @override
  String get subscriptionUsageSignInExpired =>
      'Сеанс истёк, обновится при следующем запуске';

  @override
  String subscriptionUsagePercentUsed(int percent) {
    return 'Использовано $percent%';
  }

  @override
  String resetsIn(String duration) {
    return 'Сброс через $duration';
  }

  @override
  String get feedbackHelpful => 'Это было полезно';

  @override
  String get feedbackNotHelpful => 'Это не помогло';

  @override
  String get modeChat => 'Чат';

  @override
  String get modePlan => 'План';

  @override
  String get modeReview => 'Ревью';

  @override
  String get modeOrchestrate => 'Оркестрация';

  @override
  String get editorTheme => 'Тема редактора';

  @override
  String get editorThemeDescription =>
      'Импортируйте цветовую тему VS Code, чтобы встроенный diff и редактор совпадали с IDE.';

  @override
  String get editorThemePasteHint =>
      'Вставьте содержимое JSON-файла цветовой темы VS Code';

  @override
  String get editorThemeImported => 'Тема импортирована';

  @override
  String get editorThemeInvalid => 'Это не похоже на допустимую тему VS Code';

  @override
  String get importTheme => 'Импортировать тему';

  @override
  String get clearTheme => 'Сбросить тему';

  @override
  String get openInDiffViewer => 'Открыть в просмотрщике diff';

  @override
  String get shellCommand => 'Команда';

  @override
  String get shellOutput => 'Вывод';

  @override
  String get revertToHere => 'Откатить досюда';

  @override
  String get revertConfirmBody =>
      'Скрыть сообщения после этой точки и откатить файловые изменения агента до этого хода? Это можно отменить.';

  @override
  String get revert => 'Откатить';

  @override
  String get revertedToHere => 'Откатили досюда';

  @override
  String get nothingToRevert => 'Нечего откатывать';

  @override
  String get undoRevert => 'Отменить откат';

  @override
  String get revertUndone => 'Откат отменён';

  @override
  String get systemBehavior => 'Поведение системы';

  @override
  String get keepAwakeTitle =>
      'Не давать компьютеру засыпать, пока работают агенты';

  @override
  String get keepAwakeOnSubtitle => 'Компьютер не заснёт, пока работает агент';

  @override
  String get keepAwakeOffSubtitle =>
      'Компьютер может заснуть даже во время работы агента';

  @override
  String get spaces => 'Пространства';

  @override
  String get spacesHomeDescription =>
      'Выберите пространство из списка или создайте новое.';

  @override
  String get noSpacesYet => 'Пространств пока нет';

  @override
  String get newSpace => 'Новое пространство';

  @override
  String get spaceName => 'Название пространства';

  @override
  String get spaceReposHint => 'Репозитории для включения';

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
  String get noSpaceFoldersYet => 'Папок пока нет';

  @override
  String get ideSourceControl => 'Контроль версий';

  @override
  String get stagedChanges => 'Индексированные изменения';

  @override
  String get changes => 'Изменения';

  @override
  String get stageFile => 'Индексировать';

  @override
  String get unstageFile => 'Убрать из индекса';

  @override
  String get stageAll => 'Проиндексировать все изменения';

  @override
  String get unstageAll => 'Убрать всё из индекса';

  @override
  String get stageChangesToCommit => 'Проиндексировать изменения для коммита';

  @override
  String get syncToPrHead => 'Получить последние коммиты PR';

  @override
  String get syncedToPrHead => 'Синхронизировано с последними коммитами PR';

  @override
  String get syncPrHeadDirty =>
      'Сделайте коммит или отмените изменения перед синхронизацией';

  @override
  String get syncPrHeadFailed => 'Не удалось синхронизироваться с головой PR';

  @override
  String get spaceLabel => 'Пространство';

  @override
  String get keybindingNewSpace => 'Новое пространство';

  @override
  String get jumpToLatest => 'К последнему';

  @override
  String get streaming => 'Стриминг';

  @override
  String get newMessages => 'Новые';

  @override
  String get copyLink => 'Копировать ссылку';

  @override
  String get linkCopied => 'Ссылка скопирована';

  @override
  String get agentResponding => 'Агент отвечает';

  @override
  String get agentFinished => 'Агент завершил работу';

  @override
  String get harnessConnectProviderForModels =>
      'Подключите провайдера, чтобы увидеть модели.';

  @override
  String get providerSignOut => 'Выйти';

  @override
  String get providerWaitingForDeviceCode =>
      'Ожидание подтверждения кода в браузере…';

  @override
  String get providerDeviceCodeHint =>
      'Убедитесь, что код совпадает с показанным в браузере, затем подтвердите.';

  @override
  String get providerPlanUsageLoading => 'Проверка использования тарифа…';

  @override
  String get providerPlanUsageUnavailable =>
      'Этот тариф не сообщает об использовании.';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return 'Удалить API-ключ $provider?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'Сохранённый ключ будет удалён и его нельзя будет показать снова. Агенты с моделями $provider перестанут работать, пока вы не вставите новый.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return 'Удалить $provider?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'Провайдер и сохранённый ключ будут удалены. Агенты, привязанные к его моделям, перестанут работать.';
  }

  @override
  String get providerApiKeyHint => 'Вставьте API-ключ';

  @override
  String get providerApiKeyStoredHint =>
      'Вставьте другой API-ключ, чтобы добавить его';

  @override
  String get providerAddAnotherAccount => 'Добавить ещё один аккаунт';

  @override
  String get providerActiveBadge => 'Активен';

  @override
  String get providerSignInExpired => 'Срок входа истёк';

  @override
  String get providerOauthAccountFallback => 'Аккаунт OAuth';

  @override
  String get providerApiKeyFallback => 'API-ключ';

  @override
  String get providerRemoveCredentialConfirmTitle =>
      'Удалить эти учётные данные?';

  @override
  String get providerSignOutAccountConfirmTitle => 'Выйти из этого аккаунта?';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'Агенты с $provider переключатся на другие ключи и аккаунты. Если ничего не останется, они остановятся, пока вы не добавите новые.';
  }

  @override
  String get providerBaseUrlHint => 'Базовый URL (необязательно)';

  @override
  String get addProvider => 'Добавить провайдера';

  @override
  String get noCustomProviders => 'Пока нет пользовательских провайдеров.';

  @override
  String get providerNameLabel => 'Имя';

  @override
  String get apiTypeLabel => 'Тип API';

  @override
  String get providerBaseUrlLabel => 'Базовый URL';

  @override
  String get providerApiKeyOptionalHint => 'API-ключ (необязательно)';

  @override
  String get dialectOpenAiCompatible => 'Совместимый с OpenAI';

  @override
  String get dialectAnthropicCompatible => 'Совместимый с Anthropic';

  @override
  String get removeProviderTooltip => 'Удалить провайдера';

  @override
  String get providerLogInWithBrowser => 'Войти через браузер';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'Войти в $provider';
  }

  @override
  String get providerLabel => 'Провайдер';

  @override
  String get selectProviderToLogin => 'Выберите провайдера для входа';

  @override
  String providerLoginFailed(String error) {
    return 'Не удалось войти: $error';
  }

  @override
  String get providerWaitingForBrowser => 'Ожидание авторизации в браузере…';

  @override
  String get providerPasteCodeHint => 'Или вставьте код из браузера';

  @override
  String get providerCompleteLogin => 'Завершить';

  @override
  String get providerConnectedApiKey => 'Подключено через API-ключ';

  @override
  String get providerConnectedOauth => 'Подключено';

  @override
  String providerConnectedAccount(String account) {
    return 'Подключено · $account';
  }

  @override
  String get providerLocalReady => 'Локально · готово';

  @override
  String get providerNotConnected => 'Не подключено';

  @override
  String get preparingWorkspace => 'Подготовка рабочего пространства…';

  @override
  String provisioningRunningTasks(String repo) {
    return 'Запуск задач worktree для $repo…';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return 'Клонирование $repo…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'Checkout pull request в $repo…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'Настройка агента $agent…';
  }

  @override
  String get workspacePrepFailed =>
      'Не удалось подготовить рабочее пространство';

  @override
  String get workspacePrepStopped =>
      'Подготовка рабочего пространства остановлена';

  @override
  String get stopWorkspacePrep => 'Остановить подготовку';

  @override
  String get stopWorkspacePrepTooltip =>
      'Остановить подготовку этого рабочего пространства';

  @override
  String get stopWorkspacePrepConfirm =>
      'Остановить подготовку этого рабочего пространства? Текущее клонирование будет отброшено — можно запустить снова отсюда.';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count message(s) will send when ready';
  }

  @override
  String get membersNav => 'Участники';

  @override
  String get membersSettingsDescription =>
      'Люди с доступом к этому рабочему пространству: состав, приглашения и журнал аудита';

  @override
  String get memberRosterLabel => 'Список участников';

  @override
  String get memberRepoAccessAction => 'Доступ к репозиторию';

  @override
  String memberRepoAccessTitle(String name) {
    return 'Доступ к репозиторию для $name';
  }

  @override
  String get roleOwner => 'Владелец';

  @override
  String get roleAdmin => 'Администратор';

  @override
  String get roleMember => 'Участник';

  @override
  String get roleViewer => 'Наблюдатель';

  @override
  String get roleGuest => 'Гость';

  @override
  String get removeMemberTitle => 'Удалить участника';

  @override
  String removeMemberConfirm(String name) {
    return 'Удалить $name из этого рабочего пространства? Доступ будет сразу отозван.';
  }

  @override
  String get transferOwnershipAction => 'Передать владение';

  @override
  String get transferOwnershipTitle => 'Передать владение';

  @override
  String transferOwnershipConfirm(String name) {
    return 'Сделать $name владельцем этого рабочего пространства? Вы станете администратором. Только владелец может удалить рабочее пространство или изменить роль другого администратора.';
  }

  @override
  String get transferOwnershipCta => 'Передать';

  @override
  String get auditTrailLabel => 'Журнал аудита авторизации';

  @override
  String get auditTrailDescription =>
      'Каждое разрешение и отказ связаны хеш-цепочкой: изменение или удаление записи обнаруживается.';

  @override
  String get auditVerifyChain => 'Проверить цепочку';

  @override
  String auditChainIntact(int count) {
    return 'Chain intact — $count entries verified';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'Цепочка нарушена на записи $seq: $reason';
  }

  @override
  String get auditEmpty => 'Решений пока нет.';

  @override
  String get auditDenied => 'Отказано';

  @override
  String get auditAllowed => 'Разрешено';

  @override
  String auditOnBehalfOf(String user) {
    return 'от имени $user';
  }

  @override
  String get policyTemplatesLabel => 'Шаблоны политик';

  @override
  String get policyTemplatesDescription =>
      'Применить начальную позицию или перенести шаблон между рабочими пространствами.';

  @override
  String get policyTemplateStrict => 'Строгий';

  @override
  String get policyTemplateBalanced => 'Сбалансированный';

  @override
  String get policyTemplatePermissive => 'Разрешающая';

  @override
  String get policyTemplateApply => 'Применить';

  @override
  String policyTemplateApplied(int count) {
    return 'Применено правил: $count';
  }

  @override
  String get policyExport => 'Копировать политику';

  @override
  String get policyExported => 'Политика скопирована в буфер обмена';

  @override
  String get policyImport => 'Вставить политику';

  @override
  String policyImported(int count) {
    return 'Импортировано правил: $count';
  }

  @override
  String get approveAndRemember => 'Одобрить на 8 часов';

  @override
  String get approveAndRememberTooltip =>
      'Одобряет это действие и больше не спрашивает о похожих в этом пространстве в течение 8 часов. Срок истекает сам.';

  @override
  String get unknownUserLabel => 'Неизвестный пользователь';

  @override
  String get inviteMember => 'Пригласить участника';

  @override
  String get inviteRepoAccessHeader => 'Доступ к репозиториям';

  @override
  String get inviteRepoAccessExplainer =>
      'Приглашённому доступны только отмеченные репозитории и на выбранном уровне. Остальное остаётся скрытым.';

  @override
  String get grantLevelRead => 'Чтение';

  @override
  String get grantLevelReview => 'Проверка';

  @override
  String get grantLevelWrite => 'Запись';

  @override
  String get inviteExpiryLabel => 'Истекает через';

  @override
  String get expiryOneDay => '1 день';

  @override
  String get expirySevenDays => '7 дней';

  @override
  String get expiryThirtyDays => '30 дней';

  @override
  String get createInviteAction => 'Создать приглашение';

  @override
  String get inviteOneTimeCodeLabel => 'Одноразовый код';

  @override
  String get inviteCodeShownOnce =>
      'Этот код показывается только один раз — скопируйте его сейчас.';

  @override
  String get inviteLinkLabel => 'Ссылка-приглашение';

  @override
  String get inviteRedeemHint =>
      'Передайте код приглашённому; он активирует его по URL вашего сервера.';

  @override
  String get inviteScanQr => 'Или отсканируйте, чтобы активировать';

  @override
  String get inviteLoopbackWarningTitle =>
      'Приглашение указывает на локальный адрес';

  @override
  String get inviteLoopbackWarningBody =>
      'Сотрудники на других машинах не смогут достучаться до этого сервера. Запустите туннель (Настройки → Интеграции → Поделиться этим сервером) или привяжите его к сети, чтобы пользователи вне хоста могли подключаться.';

  @override
  String get inviteStatusOpen => 'Открыто';

  @override
  String get inviteStatusUsed => 'Использовано';

  @override
  String get inviteStatusRevoked => 'Отозвано';

  @override
  String get inviteStatusExpired => 'Истекло';

  @override
  String inviteCreatedTime(String time) {
    return 'Создано $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'истекает $date';
  }

  @override
  String get noActivityYet => 'Пока нет активности';

  @override
  String get couldNotLoadMembers => 'Не удалось загрузить участников';

  @override
  String get couldNotLoadInvites => 'Не удалось загрузить приглашения';

  @override
  String get couldNotLoadActivity => 'Не удалось загрузить активность';

  @override
  String get yourDevices => 'Ваши устройства';

  @override
  String get yourDevicesDescription =>
      'Клиенты, привязанные к вашей учётной записи на этом сервере.';

  @override
  String get noOwnDevices =>
      'К вашей учётной записи пока не привязано ни одного устройства';

  @override
  String get renameDeviceTitle => 'Переименовать устройство';

  @override
  String get revokeDeviceTitle => 'Отозвать устройство';

  @override
  String revokeDeviceConfirm(String label) {
    return 'Отозвать $label? Соединение разрывается сразу, доступ к этому серверу будет закрыт.';
  }

  @override
  String devicePairedTime(String time) {
    return 'Привязано $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'В сети $time';
  }

  @override
  String get deviceNeverSeen => 'Никогда не подключалось';

  @override
  String get deviceAwaitingApproval => 'Ждёт одобрения';

  @override
  String get profileSectionLabel => 'Профиль';

  @override
  String get profileSectionDescription =>
      'Как вас видит команда и авторство git-коммитов в этом пространстве. Пустые поля наследуют имя и почту аккаунта.';

  @override
  String get displayNameLabel => 'Отображаемое имя';

  @override
  String get emailLabel => 'Email';

  @override
  String get gitAuthorNameLabel => 'Имя автора Git';

  @override
  String get gitAuthorEmailLabel => 'Email автора Git';

  @override
  String get profileSaved => 'Профиль сохранён';

  @override
  String get presenceOnline => 'В сети';

  @override
  String get presenceIdle => 'Неактивен';

  @override
  String get presenceTyping => 'Печатает…';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String get presenceRailLabel => 'Кто в сети';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'Включить «не беспокоить»';

  @override
  String get dndTooltipOff => 'Выключить «не беспокоить»';

  @override
  String get startPresenting => 'Начать показ';

  @override
  String get stopPresenting => 'Остановить показ';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name проводит показ';
  }

  @override
  String get spotlightLeave => 'Выйти';

  @override
  String typingIndicator(String name) {
    return '$name печатает…';
  }

  @override
  String get ideTabNotes => 'Заметки';

  @override
  String get ideSidebarAllViews => 'Все представления';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'Все представления ($count скрыто)';
  }

  @override
  String get ideSidebarPinView => 'Закрепить на боковой панели';

  @override
  String get ideSidebarUnpinView => 'Открепить от боковой панели';

  @override
  String get notesEmptyHint =>
      'Добавьте заметку для того, кто продолжит этот разговор…';

  @override
  String get notesEditTooltip => 'Изменить заметку';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'Обновлено: $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name редактирует';
  }

  @override
  String get notesSaveFailed => 'Не удалось сохранить заметку';

  @override
  String get reactionAddTooltip => 'Добавить реакцию';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'Реакция $emoji';
  }

  @override
  String get reactionThumbsUp => 'Палец вверх';

  @override
  String get reactionThumbsDown => 'Палец вниз';

  @override
  String get reactionLaugh => 'Смех';

  @override
  String get reactionHooray => 'Ура';

  @override
  String get reactionConfused => 'Недоумение';

  @override
  String get reactionHeart => 'Сердце';

  @override
  String get reactionRocket => 'Ракета';

  @override
  String get reactionEyes => 'Глаза';

  @override
  String get commentReact => 'Отреагировать';

  @override
  String get commentResolveThread => 'Решить ветку';

  @override
  String get commentReopenThread => 'Открыть ветку снова';

  @override
  String get commentCopyLink => 'Копировать ссылку на комментарий';

  @override
  String get commentCopyMarkdown => 'Копировать как Markdown';

  @override
  String get commentCopyThreadMarkdown => 'Копировать ветку как Markdown';

  @override
  String get commentCopyPrompt => 'Копировать как промпт';

  @override
  String get commentCopyThreadPrompt => 'Копировать ветку как промпт';

  @override
  String get commentSendToAgent => 'Отправить агенту';

  @override
  String get commentDelete => 'Удалить комментарий';

  @override
  String get commentEdit => 'Изменить комментарий';

  @override
  String get commentActions => 'Действия с комментарием';

  @override
  String get commentDeleteTitle => 'Удалить этот комментарий?';

  @override
  String get commentDeleteBody => 'Он будет убран из pull request.';

  @override
  String get commentSentToAgent => 'Отправлено агенту';

  @override
  String get commentSendFailed =>
      'Не удалось отправить этот комментарий агенту';

  @override
  String get commentDeleteFailed => 'Не удалось удалить этот комментарий';

  @override
  String get autonomyDialLabel => 'Автономия';

  @override
  String get autonomyProposeOnly => 'Только предлагать';

  @override
  String get autonomyActWithApproval => 'Действовать с одобрения';

  @override
  String get autonomyActFreely => 'Действовать свободно';

  @override
  String get autonomyDefaultOption => 'По умолчанию';

  @override
  String get checkerLabel => 'Проверяющий';

  @override
  String get checkerNone => 'Нет';

  @override
  String get checkerCaption =>
      'Проверяющий просматривает завершённые запуски других агентов.';

  @override
  String get takeoverTooltip => 'Перехватить рабочее дерево';

  @override
  String get takeoverBannerSelf =>
      'Вы перехватили рабочее дерево этого разговора';

  @override
  String takeoverBannerOther(String name) {
    return '$name перехватил рабочее дерево этого разговора';
  }

  @override
  String get handBackButton => 'Вернуть';

  @override
  String get handBackDialogTitle => 'Вернуть рабочее дерево';

  @override
  String get handBackDialogNoteHint => 'Необязательная заметка для агента…';

  @override
  String takeoverFailed(String message) {
    return 'Не удалось перехватить: $message';
  }

  @override
  String handBackFailed(String message) {
    return 'Не удалось вернуть: $message';
  }

  @override
  String get planStudioTitle => 'Студия планов';

  @override
  String get plansTitle => 'Планы';

  @override
  String get plansSubtitle => 'Активные планы, документы планов и плейбуки';

  @override
  String get plansActiveSection => 'Активные планы';

  @override
  String get plansDocumentsSection => 'Документы планов';

  @override
  String get plansPlaybooksSection => 'Плейбуки';

  @override
  String get plansNoActive => 'Пока нет активных планов.';

  @override
  String get plansNoDocuments => 'Пока нет документов планов.';

  @override
  String get plansNoPlaybooks => 'Пока нет плейбуков.';

  @override
  String get planNotFound => 'План не найден.';

  @override
  String get planOpenInStudio => 'Открыть';

  @override
  String get planNodeTitle => 'Название';

  @override
  String get planNodeDescription => 'Описание';

  @override
  String get planNodeDescriptionHint => 'Что должен делать этот шаг…';

  @override
  String get planNodeApplyDescription => 'Применить';

  @override
  String get planNodeRole => 'Роль';

  @override
  String get planNodeDependencies => 'Зависит от';

  @override
  String get planNodeDependenciesHint => 'Добавить зависимость';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count зависимостей',
      many: '$count зависимостей',
      few: '$count зависимости',
      one: '$count зависимость',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'Нет зависимостей — шаг запустится сразу после старта плана';

  @override
  String get planNodeOutputSchema => 'Схема вывода (JSON)';

  @override
  String get planNodeEstimate => 'Оценка';

  @override
  String get planNodeProvenance => 'Происхождение';

  @override
  String get planNodeAlreadyExecuted =>
      'Уже выполнено — правки создают ответвление плана отсюда.';

  @override
  String get planNewNodeTitle => 'Новый шаг';

  @override
  String get planEstimateNoHistory => 'Истории пока нет';

  @override
  String get planEstimateBlastUnknown => 'Радиус воздействия: неизвестен';

  @override
  String get planEstimatePartial => 'частично';

  @override
  String get planEstimateAction => 'Оценить';

  @override
  String planEstimateDuration(String range) {
    return 'Длительность $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'Радиус воздействия: $files файлов, $symbols символов';
  }

  @override
  String get planApprove => 'Утвердить план';

  @override
  String get planApproveSelectedNodes => 'Утвердить выбранные';

  @override
  String get planReject => 'Отклонить';

  @override
  String get planCancel => 'Отменить запуск';

  @override
  String get planContinueNode => 'Продолжить узел';

  @override
  String get planTotalNotEstimated => 'Ещё не оценено';

  @override
  String get planBudgetExceeded => 'сверх бюджета';

  @override
  String planBudgetCeiling(String amount) {
    return 'бюджет ≤ \$$amount';
  }

  @override
  String get planVersionsTitle => 'Версии';

  @override
  String get planNoRevisions => 'Версий пока нет.';

  @override
  String get planDiffIdentical => 'Нет изменений.';

  @override
  String get planDiffGoalChanged => 'Цель изменена';

  @override
  String get planDiffBudgetChanged => 'Бюджет изменён';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'Изменения с v$fromRev на v$toRev';
  }

  @override
  String planDiffAdded(String node) {
    return 'Добавлен $node';
  }

  @override
  String planDiffRemoved(String node) {
    return 'Удалён $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return 'Изменён $node: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'Добавлено ребро: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'Удалено ребро: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'Добавлена роль: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'Удалена роль: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'Роль переназначена: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'План перепланирован: вы утвердили v$approved, сейчас v$current. Просмотрите изменения перед продолжением.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'Фактическая стоимость: \$$amount';
  }

  @override
  String get planPlaybookRun => 'Запустить';

  @override
  String get planPlaybookDelete => 'Удалить плейбук';

  @override
  String get planPlaybookProposed =>
      'План предложен — утвердите его в Plan Studio.';

  @override
  String get planPlaybookAnchorTicket => 'Якорный тикет';

  @override
  String get planPlaybookPickTicket => 'Выберите тикет…';

  @override
  String get planPlaybookProposeRun => 'Предложить план';

  @override
  String get planPlaybookRepoHint => 'Идентификатор репозитория';

  @override
  String get planPlaybookAgentHint => 'Идентификатор агента';

  @override
  String planPlaybookRunTitle(String name) {
    return 'Запуск $name';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count параметров';
  }

  @override
  String get recentLabel => 'Недавние';

  @override
  String get cheatSheetTitle => 'Сочетания клавиш';

  @override
  String get cheatSheetGlobal => 'Глобальные';

  @override
  String get cheatSheetThisScreen => 'Этот экран';

  @override
  String get cheatSheetReservedInBrowser => 'Зарезервировано браузером';

  @override
  String get keybindingCheatSheet => 'Сочетания клавиш';

  @override
  String get runPlaybookLabel => 'Запустить плейбук';

  @override
  String get playbooksLabel => 'Плейбуки';

  @override
  String get keybindingUndo => 'Отменить';

  @override
  String get keybindingRedo => 'Повторить';

  @override
  String get undone => 'Отменено';

  @override
  String get redone => 'Повторено';

  @override
  String get undoFailed => 'Не удалось отменить';

  @override
  String get undoLabelTicketEdit => 'правка тикета';

  @override
  String get undoLabelMessageEdit => 'правка сообщения';

  @override
  String get undoLabelTodoStatus => 'статус todo';

  @override
  String get inboxTitle => 'Входящие';

  @override
  String get inboxReview => 'Ревью';

  @override
  String get inboxOpen => 'Открытые';

  @override
  String get inboxAllCaughtUp => 'Вы всё просмотрели';

  @override
  String get inboxGitHubDownTitle => 'GitHub, возможно, недоступен';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub сообщает $status, поэтому pull request могут отсутствовать в списке, а не быть уже завершёнными.';
  }

  @override
  String get inboxGitHubIdentityTitle =>
      'Не удалось подтвердить аккаунт GitHub';

  @override
  String get inboxGitHubIdentityBody =>
      'Входящие сортируются по вашему аккаунту GitHub. Пока он не загрузится, список останется пустым, даже если вас ждут pull request.';

  @override
  String get inboxSeverityBlocking => 'Заблокировано';

  @override
  String get inboxSeverityWaiting => 'Ожидание';

  @override
  String get inboxSeverityInfo => 'Инфо';

  @override
  String get inboxSyncFailed => 'Синхронизация не удалась';

  @override
  String get inboxNeedsYourAttention => 'Требует внимания';

  @override
  String get inboxSectionNeedsYourReview => 'Ждут вашего ревью';

  @override
  String get inboxSectionReturnedToYou => 'Возвращены вам';

  @override
  String get inboxSectionApproved => 'Одобрено';

  @override
  String get inboxSectionDrafts => 'Черновики';

  @override
  String get inboxSectionWaitingForReviewers => 'Ожидают ревьюеров';

  @override
  String get inboxSectionMergingAndMerged => 'Слияние и недавно слитые';

  @override
  String get inboxSectionWaitingForAuthor => 'Ожидают автора';

  @override
  String get inboxColumnTitle => 'Название';

  @override
  String get inboxColumnChanges => 'Изменения';

  @override
  String get inboxColumnUpdated => 'Обновлено';

  @override
  String get inboxReviewApproved => 'Одобрено';

  @override
  String get inboxReviewChangesRequested => 'Запрошены изменения';

  @override
  String get inboxHeroSubtitle =>
      'Все pull request, в которых вы участвуете, отсортированы по следующему шагу.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request требуют вашего ревью',
      many: '$count pull request требуют вашего ревью',
      few: '$count pull request требуют вашего ревью',
      one: '$count pull request требует вашего ревью',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count возвращены вам',
      many: '$count возвращены вам',
      few: '$count возвращены вам',
      one: '$count возвращён вам',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted =>
      'Изменение не сохранилось и было отменено';

  @override
  String get offlinePendingLabel => 'ожидание';

  @override
  String get offlineSyncingLabel => 'синхронизация';

  @override
  String get copyLinkLabel => 'Скопировать ссылку на эту страницу';

  @override
  String get agentsSectionLabel => 'Агенты';

  @override
  String get fleetWorkersTitle => 'Воркеры';

  @override
  String get fleetWorkersSubtitle => 'Машины, доступные для выполнения заданий';

  @override
  String get fleetJobsTitle => 'Задания';

  @override
  String get fleetJobsSubtitle => 'Работа, распределённая по флоту';

  @override
  String get fleetNoWorkers =>
      'Пока нет воркеров — вторая машина с `cc_worker --server <url>` присоединится к флоту.';

  @override
  String get fleetNoJobs => 'Нет заданий.';

  @override
  String get fleetError => 'Не удалось загрузить флот';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ядер',
      many: '$count ядер',
      few: '$count ядра',
      one: '$count ядро',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'Пульс $time';
  }

  @override
  String get fleetNoHeartbeat => 'Пульса ещё нет';

  @override
  String fleetLastErrorLabel(String error) {
    return 'Последняя ошибка: $error';
  }

  @override
  String get fleetDrain => 'Дренировать';

  @override
  String get fleetResume => 'Возобновить';

  @override
  String get fleetRevoke => 'Отозвать';

  @override
  String get fleetRemove => 'Удалить';

  @override
  String get fleetRevokeTitle => 'Отозвать воркер?';

  @override
  String fleetRevokeBody(String name) {
    return 'Отозвать $name? Его сессия завершится, а активные задания будут переназначены.';
  }

  @override
  String get fleetRemoveTitle => 'Удалить воркер?';

  @override
  String fleetRemoveBody(String name) {
    return 'Удалить $name из флота? Запись будет удалена.';
  }

  @override
  String get fleetActionFailed => 'Не удалось выполнить действие';

  @override
  String get fleetJobUnassigned => 'Не назначено';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max попыток';
  }

  @override
  String get fleetPlacementReasons => 'Решения о размещении';

  @override
  String get fleetNoPlacements => 'Решений о размещении пока нет.';

  @override
  String get fleetStatusOnline => 'Онлайн';

  @override
  String get fleetStatusDraining => 'Освобождается';

  @override
  String get fleetStatusOffline => 'Офлайн';

  @override
  String get fleetStatusIncompatible => 'Несовместимо';

  @override
  String get fleetStatusRevoked => 'Отозвано';

  @override
  String get fleetJobStatusQueued => 'В очереди';

  @override
  String get fleetJobStatusRunning => 'Выполняется';

  @override
  String get fleetJobStatusSucceeded => 'Успешно';

  @override
  String get fleetJobStatusFailed => 'Ошибка';

  @override
  String get fleetJobStatusCancelled => 'Отменено';

  @override
  String get evalsNoSuites => 'Сьюитов eval пока нет.';

  @override
  String get evalsError => 'Не удалось загрузить eval';

  @override
  String get evalsStarterBadge => 'Стартовый';

  @override
  String evalsDefaultBatch(int count) {
    return 'Пакет по умолчанию: $count';
  }

  @override
  String get evalsRecentRuns => 'Недавние запуски';

  @override
  String get evalsNoRuns => 'Запусков пока нет.';

  @override
  String get evalsPassRate => 'Доля успешных';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return 'от $who';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'Eval завершён — $rate успешно';
  }

  @override
  String get evalsRunFailed => 'Не удалось запустить сьюит';

  @override
  String get evalsRun => 'Запустить';

  @override
  String get evalsStatusQueued => 'В очереди';

  @override
  String get evalsStatusRunning => 'Выполняется';

  @override
  String get evalsStatusPassed => 'Пройдено';

  @override
  String get evalsStatusFailed => 'Ошибка';

  @override
  String get bannerCalendarReconnect => 'Подключить снова';

  @override
  String get bannerView => 'Открыть';

  @override
  String get soundscapeTitle => 'Звуковые пейзажи';

  @override
  String get soundscapePlay => 'Играть';

  @override
  String get soundscapePause => 'Пауза';

  @override
  String get soundscapeMoodLabel => 'Настроение';

  @override
  String get soundscapeMoodFocus => 'Концентрация';

  @override
  String get soundscapeMoodRelax => 'Расслабление';

  @override
  String get soundscapeMoodSleep => 'Сон';

  @override
  String get soundscapeMoodRise => 'Подъём';

  @override
  String get soundscapeVolumeLabel => 'Громкость';

  @override
  String get soundscapeTuneLabel => 'Тембр';

  @override
  String get soundscapeTuneMellow => 'Мягкий';

  @override
  String get soundscapeTuneBright => 'Яркий';

  @override
  String get soundscapeTuneEnergetic => 'Энергичный';

  @override
  String get soundscapeTuneSpacy => 'Космический';

  @override
  String get soundscapeTuneResetHint => 'Двойное нажатие сбрасывает';

  @override
  String get soundscapeSceneLabel => 'Сейчас играет';

  @override
  String get soundscapeSceneLoading => 'Настраиваем атмосферу…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees°C';
  }

  @override
  String get soundscapeLocationLabel => 'Местоположение';

  @override
  String get soundscapeLocationDetecting => 'Определяем местоположение…';

  @override
  String get soundscapeLocationAutoNote =>
      'Местоположение определяется этим устройством.';

  @override
  String get soundscapeRefreshWeather => 'Обновить погоду';

  @override
  String get soundscapeAutoStartLabel => 'Включать в режиме фокуса';

  @override
  String get soundscapeAutoStartDescription =>
      'Автоматически включать звуковой пейзаж при старте сессии фокуса.';

  @override
  String get soundscapeReturnToApp => 'Вернуться в приложение';

  @override
  String get soundscapePopOut => 'Вынести плеер';

  @override
  String get discussion => 'Обсуждение';

  @override
  String get chat => 'Чат';

  @override
  String get saving => 'Сохранение…';

  @override
  String get saved => 'Сохранено';

  @override
  String get saveFailed => 'Не удалось сохранить';

  @override
  String get commitAndPush => 'Коммит и push';

  @override
  String get commit => 'Коммит';

  @override
  String get commitAmend => 'Коммит (amend)';

  @override
  String get commitAndSync => 'Коммит и синхронизация';

  @override
  String get scmSyncChanges => 'Синхронизировать изменения';

  @override
  String get scmPublishBranch => 'Опубликовать ветку';

  @override
  String get scmSyncFailed => 'Не удалось синхронизировать';

  @override
  String get scmSyncDirty =>
      'Закоммитьте или отмените изменения перед синхронизацией';

  @override
  String get scmSynced => 'Синхронизировано';

  @override
  String get scmPushRefused => 'Push отклонён';

  @override
  String get scmPulledPushRefused => 'Получено, но push отклонён';

  @override
  String get scmPushRefusedHint =>
      'Удалённая сторона или хук отклонили обновление';

  @override
  String get scmSelectBranch => 'Выберите ветку для переключения';

  @override
  String get scmCreateBranch => 'Создать новую ветку…';

  @override
  String get scmCreateBranchFrom => 'Создать новую ветку из…';

  @override
  String get scmCheckoutDetached => 'Отсоединённое переключение…';

  @override
  String get scmBranchName => 'Имя ветки';

  @override
  String get scmCreateBranchTitle => 'Создать ветку';

  @override
  String scmFromRef(String ref) {
    return 'Из ⁨$ref⁩';
  }

  @override
  String get scmCheckoutFailed => 'Не удалось переключить ветку';

  @override
  String get scmCheckoutDirty =>
      'Зафиксируйте или отмените изменения перед переключением ветки';

  @override
  String scmSwitchedToBranch(String branch) {
    return 'Переключено на ⁨$branch⁩';
  }

  @override
  String scmDetachedAt(String ref) {
    return 'Отсоединено на ⁨$ref⁩';
  }

  @override
  String get scmDetachedHead => 'Отсоединённый HEAD';

  @override
  String get scmNoBranches => 'Нет подходящих веток';

  @override
  String get scmBranches => 'Ветки';

  @override
  String get scmRemoteBranches => 'Удалённые ветки';

  @override
  String get scmTags => 'Метки';

  @override
  String get scmPickStartPoint => 'Выберите начальную точку';

  @override
  String get scmSwitchBranch => 'Переключить ветку';

  @override
  String get scmPullConflictTitle => 'Получение создаст конфликт';

  @override
  String scmPullConflictBody(int count, String branch) {
    return 'Получение $count коммитов в ⁨$branch⁩ конфликтует с работой в этой копии.';
  }

  @override
  String get scmAskAi => 'Спросить ИИ';

  @override
  String scmResolveConflictPrompt(String branch, String repo, int count) {
    return 'Получи ⁨$branch⁩ в ⁨$repo⁩. Ветка отстаёт на $count коммитов от upstream, и получение конфликтует с локальной работой. Разреши конфликты и заверши получение.';
  }

  @override
  String commitMessageOnBranch(String shortcut, String branch) {
    return 'Сообщение ($shortcut, чтобы закоммитить в «$branch»)';
  }

  @override
  String get committed => 'Закоммичено';

  @override
  String get commitAmended => 'Коммит изменён';

  @override
  String get commitFailed => 'Не удалось создать коммит';

  @override
  String get moreCommitActions => 'Другие действия коммита';

  @override
  String get sourceControl => 'Контроль версий';

  @override
  String fixFindingTitle(String location) {
    return 'Исправление: $location';
  }

  @override
  String get openInEditor => 'Открыть в редакторе';

  @override
  String get regexTesterTitle => 'Проверить регулярное выражение';

  @override
  String get regexTesterHint => 'Введите пример';

  @override
  String get regexMatch => 'Совпадение';

  @override
  String get regexNoMatch => 'Нет совпадений';

  @override
  String get regexInvalidPattern => 'Недопустимый шаблон';

  @override
  String get symbolLookupNone =>
      'Нет определения в индексе или в этом pull request';

  @override
  String get symbolLookupInDiff => 'Найдено в этом pull request';

  @override
  String get symbolLookupFromBase =>
      'Из базового checkout — worktree этого PR ещё не проиндексирован';

  @override
  String get symbolImplementations => 'Реализации';

  @override
  String symbolCallersCount(int count) {
    return '$count вызывающих';
  }

  @override
  String get commitMessageHint => 'Сообщение коммита';

  @override
  String get pushedToPr => 'Отправлено в PR';

  @override
  String get pushFailed => 'Не удалось выполнить push';

  @override
  String get reviewFindings => 'Замечания';

  @override
  String get treeLabel => 'Дерево';

  @override
  String get toggleFileTree => 'Показать или скрыть дерево файлов';

  @override
  String get diffViewSettings => 'Параметры представления diff';

  @override
  String get splitViewLabel => 'Раздельный';

  @override
  String get unifiedViewLabel => 'Объединённый';

  @override
  String get wrapLines => 'Переносить строки';

  @override
  String get shiftClickSelectRange => 'Shift+клик выбирает диапазон';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файла',
      many: '$count файлов',
      few: '$count файла',
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
    return 'Небольшой PR — $files, ~$minutes мин на ревью';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'Средний PR — $files, заложите ~$minutes мин на ревью';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'Крупный PR — $files, лучше разбить перед ревью';
  }

  @override
  String get searchInFiles => 'Поиск в файлах';

  @override
  String get showFileList => 'Показать список файлов';

  @override
  String get searchInFilesHintField => 'Поиск в файлах…';

  @override
  String get searchInFilesHint => 'Поиск по файлам pull request';

  @override
  String get searchInWholeRepo => 'Искать во всём репозитории';

  @override
  String get searchInThisPullRequest => 'Искать в этом pull request';

  @override
  String get searchNoResults => 'Ничего не найдено';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count результата',
      many: '$count результатов',
      few: '$count результата',
      one: '$count результат',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files файлах',
      many: '$files файлах',
      few: '$files файлах',
      one: '$files файле',
    );
    return '$_temp0 в $_temp1';
  }

  @override
  String get discardChangesTitle => 'Сбросить изменения?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файла',
      many: '$count файлов',
      few: '$count файла',
      one: '$count файл',
    );
    return 'Сбросить $_temp0 к HEAD? Это действие нельзя отменить.';
  }

  @override
  String get discardAll => 'Сбросить все';

  @override
  String get discardFailed => 'Не удалось сбросить изменения';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файла',
      many: '$count файлов',
      few: '$count файла',
      one: '$count файл',
    );
    return 'Сброшено $_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted файла',
      many: '$reverted файлов',
      few: '$reverted файла',
      one: '$reverted файл',
    );
    return 'Сброшено $_temp0; $skipped пропущено (неотслеживаемые)';
  }

  @override
  String get prWorktreeUnavailable => 'Рабочее пространство не готово';

  @override
  String get prWorktreeUnavailableHint =>
      'Не удалось подготовить файлы pull request. Откройте pull request снова, чтобы повторить попытку.';

  @override
  String get timestampRelativeLabel => 'Относительное';

  @override
  String get timestampRawLabel => 'Метка времени';

  @override
  String get previewDeployment => 'Предпросмотр развёртывания';

  @override
  String previewDeploymentTab(String site) {
    return 'Предпросмотр: $site';
  }

  @override
  String get askForReview => 'Запросить ревью…';

  @override
  String get closePrsConfirmTitle => 'Закрыть pull request?';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Закрыть $count pull request?',
      many: 'Закрыть $count pull request?',
      few: 'Закрыть $count pull request?',
      one: 'Закрыть $count pull request?',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Закрыто $count pull request',
      many: 'Закрыто $count pull request',
      few: 'Закрыто $count pull request',
      one: 'Закрыт $count pull request',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Назначено $count pull request',
      many: 'Назначено $count pull request',
      few: 'Назначено $count pull request',
      one: 'Назначен $count pull request',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Запрошено ревью для $count pull request',
      many: 'Запрошено ревью для $count pull request',
      few: 'Запрошено ревью для $count pull request',
      one: 'Запрошено ревью для $count pull request',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count действия не выполнено',
      many: '$count действий не выполнено',
      few: '$count действия не выполнены',
      one: '$count действие не выполнено',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'Диаграмма';

  @override
  String get diagramViewSource => 'Показать исходник';

  @override
  String get diagramHideSource => 'Скрыть исходник';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'Предпросмотр диаграммы недоступен ($reason)';
  }

  @override
  String get planUnavailable => 'План недоступен';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count шага',
      many: '$count шагов',
      few: '$count шага',
      one: '$count шаг',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'Одобрить и запустить';

  @override
  String get planStatusDraft => 'Черновик';

  @override
  String get planStatusProposed => 'План';

  @override
  String get planStatusApproved => 'План одобрен';

  @override
  String get planStatusRejected => 'План отклонён';

  @override
  String get planStatusSuperseded => 'План замещён';

  @override
  String planRevisionLabel(int revision) {
    return 'Ревизия $revision';
  }

  @override
  String get adapterEnforcementTitle => 'Что обеспечивает этот адаптер';

  @override
  String get enforcementFiltersToolSurface =>
      'Control Center выбирает инструменты';

  @override
  String get enforcementInterceptsToolCalls =>
      'Каждый вызов проверяется до выполнения';

  @override
  String get enforcementObservesCompletionContract =>
      'Запуск сверяется с результатом';

  @override
  String get enforcementNativeToolsInterceptable =>
      'Собственные инструменты раннера видны';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'Внутрипроцессные инструменты в песочнице';

  @override
  String get enforcementYes => 'Да';

  @override
  String get enforcementNo => 'Нет';

  @override
  String get adapterEnforcementCaveats => 'Оговорки';

  @override
  String get enforcementSummaryModesEnforced => 'Режимы под контролем';

  @override
  String get enforcementSummaryModesNotEnforced => 'Режимы без контроля';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count оговорки',
      many: '$count оговорок',
      few: '$count оговорки',
      one: '$count оговорка',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'Режимы только для чтения не структурны: Control Center не может убрать собственные инструменты этого раннера.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'Нет проверки до выполнения: через Control Center проходят только вызовы MCP-инструментов.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'Собственные файловые и shell-инструменты раннера не доходят до Control Center; песочница ОС — единственная опора под ними.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'Внутрипроцессные файловые инструменты работают вне песочницы, поэтому набор инструментов — единственная граница файловой системы.';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center не может подтолкнуть или завершить с ошибкой запуск, который закончился без результата.';

  @override
  String get modeDegraded => 'Ослаблен';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return 'Режим $mode на $adapter опирается только на песочницу; собственные файловые инструменты агента не перехватываются.';
  }

  @override
  String get artifactUnavailable => 'Артефакт недоступен';

  @override
  String artifactRevisionLabel(int count) {
    return '$count revisions';
  }

  @override
  String get artifactShowMore => 'Показать ещё';

  @override
  String get artifactShowLess => 'Показать меньше';

  @override
  String get artifactCopy => 'Копировать';

  @override
  String get artifactCopied => 'Артефакт скопирован';

  @override
  String get artifactsTabLabel => 'Артефакты';

  @override
  String get artifactsEmptyTitle => 'Пока нет артефактов';

  @override
  String get artifactsEmptyBody =>
      'Когда агент публикует сюда таблицу, график или схему, она появляется в этом списке.';

  @override
  String get artifactRevisionPickerLabel => 'Ревизия';

  @override
  String get artifactRestoreRevision => 'Восстановить эту ревизию';

  @override
  String get artifactOpenInTab => 'Открыть во вкладке';

  @override
  String get artifactTitleFallback => 'Артефакт';

  @override
  String get providerGenerationLabel => 'Параметры генерации';

  @override
  String get providerGenerationHint =>
      'Оставьте поле пустым, чтобы взять значение по умолчанию эндпоинта. У моделей свои потолки вывода и рецепты сэмплирования; другие значения могут ухудшить качество.';

  @override
  String get providerMaxTokensLabel => 'Макс. токенов на вывод';

  @override
  String get addModel => 'Добавить модель';

  @override
  String get modelListTitle => 'Список моделей';

  @override
  String get railProvidersGroup => 'Провайдеры';

  @override
  String get railCustomProvidersGroup => 'Свои провайдеры';

  @override
  String get editModelSettings => 'Изменить настройки модели';

  @override
  String get modelIdLabel => 'ID модели';

  @override
  String get modelIdImmutableHint =>
      'ID, который отдаёт эндпоинт; после добавления в список не меняется.';

  @override
  String get contextWindowLabel => 'Контекстное окно';

  @override
  String get inputTypesLabel => 'Типы входа';

  @override
  String get outputTypesLabel => 'Типы выхода';

  @override
  String get modalityText => 'Текст';

  @override
  String get modalityImage => 'Изображение';

  @override
  String get modalityAudio => 'Аудио';

  @override
  String get modalityVideo => 'Видео';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'Сбросить на автоматический';

  @override
  String get modelOverrideEdited => 'Изменено';

  @override
  String get manualModelBadge => 'Добавлена вручную';

  @override
  String get modelIdRequired => 'Введите идентификатор модели.';

  @override
  String get modelTokensInvalid => 'Введите положительное целое число токенов.';

  @override
  String get removeModelAction => 'Удалить модель';

  @override
  String removeModelConfirmTitle(String model) {
    return 'Удалить $model?';
  }

  @override
  String get removeModelConfirmBody =>
      'Модель исчезнет из списка, и агенты, привязанные к ней, перестанут работать. Провайдер не затронут.';

  @override
  String get addModelProviderTitle => 'Добавить провайдера моделей';

  @override
  String get addModelProviderDescription =>
      'Настройте пользовательский API-эндпоинт и его модели.';

  @override
  String get modelListEmptyHint =>
      'Модели не настроены. Добавьте модель, чтобы использовать её в чате.';

  @override
  String get addProviderModelsHint =>
      'Модели подгружаются вживую, когда эндпоинт отвечает. Добавляйте вручную только если он не умеет отдавать свой список.';

  @override
  String get providerTemperatureLabel => 'Temperature';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => 'Параметры генерации сохранены';

  @override
  String get providerGenerationInvalid =>
      'Проверьте значения: max output tokens и top-k должны быть положительными, temperature — от 0 до 2, top-p — от 0 до 1.';

  @override
  String get providerGenerationOverridden => 'Переопределено';

  @override
  String get branchNotPushed => 'не отправлена';

  @override
  String branchNotOnRemote(String branch) {
    return '«$branch» есть только в этом разговоре';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub ещё не видел эту ветку, поэтому pull request пока не может её использовать. Публикация отправит коммиты, уже есть в рабочем дереве, — незакоммиченные изменения не затрагиваются.';

  @override
  String get publishBranch => 'Опубликовать ветку';

  @override
  String branchPublished(String branch) {
    return 'Ветка «$branch» опубликована в origin';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'Branch published. $count uncommitted change(s) were not included.';
  }

  @override
  String get composePrLoadingBranches => 'Загрузка веток из GitHub…';

  @override
  String get composePrBranchesFailed =>
      'Не удалось загрузить ветки из GitHub. Введите имя ветки или проверьте подключение к GitHub.';

  @override
  String get composePrSubtitleFromSpace =>
      'Из ветки этого разговора — сначала опубликуйте её, если GitHub её ещё не видел';

  @override
  String get obsTabInsights => 'Инсайты';

  @override
  String get obsTabLive => 'Онлайн';

  @override
  String get obsTabQuality => 'Качество';

  @override
  String get obsTabUsage => 'Использование';

  @override
  String get obsUsageTotalTokens => 'Всего токенов';

  @override
  String get obsUsagePeakTokens => 'Пик токенов';

  @override
  String get obsUsageLongestSession => 'Самая длинная сессия';

  @override
  String get obsUsageCurrentStreak => 'Текущая серия';

  @override
  String get obsUsageLongestStreak => 'Самая длинная серия';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'Активность токенов';

  @override
  String get obsUsageActivityModeLabel => 'Режим активности токенов';

  @override
  String get obsUsageModeDaily => 'По дням';

  @override
  String get obsUsageModeWeekly => 'По неделям';

  @override
  String get obsUsageModeCumulative => 'Накопительно';

  @override
  String get obsUsageTimeRange => 'Период';

  @override
  String get obsUsageTrendTitle => 'Дневной тренд токенов';

  @override
  String get obsUsageModelUsage => 'Использование моделей';

  @override
  String get obsUsageTokensLabel => 'токены';

  @override
  String get obsUsageNoActivity =>
      'Использование токенов пока не зафиксировано';

  @override
  String get obsUsageOtherModels => 'Другие';

  @override
  String obsUsageCellReadout(String date, String tokens) {
    return '$date · $tokens токенов';
  }

  @override
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  ) {
    return 'Активность токенов с $start по $end. Активных дней: $activeDays. Самый загруженный день: $peak токенов.';
  }

  @override
  String get obsScreenSubtitle =>
      'Управление агентом в реальном времени, учёт стоимости, квоты и сигналы качества';

  @override
  String get obsRangeLast24h => 'Последние 24 часа';

  @override
  String get obsRangeLast7d => 'Последние 7 дней';

  @override
  String get obsRangeLast30d => 'Последние 30 дней';

  @override
  String get obsRangeAll => 'За всё время';

  @override
  String get obsAddFilter => 'Добавить фильтр';

  @override
  String get obsFilterAgent => 'Агент';

  @override
  String get obsFilterModel => 'Модель';

  @override
  String get obsFilterStatus => 'Статус';

  @override
  String get obsFilterRole => 'Роль';

  @override
  String get obsKpiTotalRuns => 'Всего запусков';

  @override
  String get obsKpiTotalCost => 'Общая стоимость';

  @override
  String get obsKpiErrorRate => 'Доля ошибок';

  @override
  String get obsKpiCacheRate => 'Доля кэша';

  @override
  String get obsKpiTokensPerSec => 'Токенов / с';

  @override
  String get obsKpiAvgLatency => 'Средняя задержка';

  @override
  String get obsKpiTtft => 'Время до первого токена';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta к предыдущему периоду';
  }

  @override
  String get obsChartActivity => 'Активность';

  @override
  String get obsChartCost => 'Стоимость во времени';

  @override
  String get obsLegendRuns => 'Запуски';

  @override
  String get obsLegendErrors => 'Ошибки';

  @override
  String get obsAgentsTitle => 'Агенты';

  @override
  String obsShowAllAgents(int count) {
    return 'Показать все агенты: $count';
  }

  @override
  String get obsShowFewerAgents => 'Показать меньше';

  @override
  String get obsRunsTitle => 'Запуски';

  @override
  String get obsNoRunsInRange => 'Нет запусков в этом диапазоне';

  @override
  String get obsColTime => 'Время';

  @override
  String get obsColAgent => 'Агент';

  @override
  String get obsColStatus => 'Статус';

  @override
  String get obsColModel => 'Модель';

  @override
  String get obsColDuration => 'Длительность';

  @override
  String get obsColTokens => 'Токены';

  @override
  String get obsColCost => 'Стоимость';

  @override
  String get obsColErrors => 'Ошибки';

  @override
  String get obsColRuns => 'Запуски';

  @override
  String get obsColAvgLatency => 'Средняя задержка';

  @override
  String get obsColLastActive => 'Последняя активность';

  @override
  String get obsStatusPending => 'Ожидание';

  @override
  String get obsStatusRunning => 'Выполняется';

  @override
  String get obsStatusCompleted => 'Завершён';

  @override
  String get obsStatusError => 'Ошибка';

  @override
  String get obsRosterLoadError => 'Не удалось загрузить список агентов.';

  @override
  String get obsRosterEmpty => 'Агентов пока нет';

  @override
  String get obsRosterEmptyDescription =>
      'Запустите агента — он появится здесь в реальном времени: статус, текущий инструмент, токены, стоимость.';

  @override
  String get obsKillAgent => 'Остановить агента';

  @override
  String get obsRosterTokensLabel => 'ток';

  @override
  String get obsCostByRoleTitle => 'Стоимость по ролям';

  @override
  String get obsCostByRoleSubtitle =>
      'На что это рабочее пространство тратит, по роли агента';

  @override
  String get obsRoleMain => 'Основной';

  @override
  String get obsRoleSubagents => 'Субагенты';

  @override
  String get obsRoleAdvisor => 'Advisor';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'Основной: $main · субагенты: $sub · advisor: $advisor';
  }

  @override
  String get obsTotal => 'Всего';

  @override
  String get obsTokenModelTitle => 'Модель токенов (5 осей)';

  @override
  String get obsTokenModelSubtitle =>
      'Все токены, потраченные этим рабочим пространством, по осям';

  @override
  String get obsAxisInput => 'Вход';

  @override
  String get obsAxisOutput => 'Выход';

  @override
  String get obsAxisReasoning => 'Рассуждение';

  @override
  String get obsAxisCacheRead => 'Чтение кэша';

  @override
  String get obsAxisCacheWrite => 'Запись в кэш';

  @override
  String get obsTotalTokens => 'Всего токенов';

  @override
  String get obsCacheDiscountNote =>
      'Токены чтения кэша тарифицируются со скидкой, поэтому они намного дешевле того же объёма свежего входа.';

  @override
  String get obsByModelTitle => 'По модели';

  @override
  String get obsByModelSubtitle =>
      'Использование токенов и стоимость по модели';

  @override
  String get obsNoModelUsage => 'Использование модели пока не зафиксировано.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count запуска',
      many: '$count запусков',
      few: '$count запуска',
      one: '$count запуск',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => 'На запуск';

  @override
  String get obsPerRunSubtitle => 'Типичная стоимость токенов одного запуска';

  @override
  String get obsMedianRunTokens => 'Медиана токенов за запуск';

  @override
  String get obsMedianRunTokensSub => 'Середина по всем запускам';

  @override
  String get obsRunsInWorkspace => 'В этом рабочем пространстве';

  @override
  String get obsCostShare => 'Доля затрат';

  @override
  String get obsQuotaConfiguredLimits => 'Настроенные лимиты';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'Использование относительно заданных потолков, сначала худший статус.';

  @override
  String get obsQuotaAddLimit => 'Добавить лимит';

  @override
  String get obsQuotaNoLimits =>
      'Лимиты квоты ещё не настроены — добавьте, чтобы отслеживать использование относительно потолка.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'Удалить лимит $title';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'Сброс через $duration · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'Окна использования';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'Наблюдаемое использование по всем провайдерам, без потолка.';

  @override
  String get obsQuotaNoUsage => 'Использование пока не зафиксировано.';

  @override
  String get obsQuotaTokensUsed => 'Использовано токенов';

  @override
  String get obsQuotaRequests => 'Запросы';

  @override
  String get obsQuotaUnitTokens => 'токены';

  @override
  String get obsQuotaUnitRequests => 'запросы';

  @override
  String get obsQuotaUnitCost => 'стоимость';

  @override
  String get obsQuotaAddLimitTitle => 'Добавить лимит квоты';

  @override
  String get obsQuotaProviderLabel => 'Провайдер';

  @override
  String get obsQuotaWindowLabel => 'Окно';

  @override
  String get obsQuotaUnitLabel => 'Единица';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'Лимит ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'В центах США (500 = \$5.00).';

  @override
  String get obsQuotaStatusOk => 'Норма';

  @override
  String get obsQuotaStatusWarning => 'Предупреждение';

  @override
  String get obsQuotaStatusExhausted => 'Исчерпан';

  @override
  String get obsQuotaStatusUnknown => 'Неизвестно';

  @override
  String get obsGoalNoActiveTitle => 'Нет активной цели';

  @override
  String get obsGoalNoActiveBody =>
      'Задайте цель, чтобы дать агентам задачу и необязательный бюджет токенов. По мере завершения запусков бюджет заполняется, и агентов подталкивают завершить работу, когда он почти исчерпан.';

  @override
  String get obsGoalSetGoal => 'Задать цель';

  @override
  String get obsGoalTokenBudget => 'Бюджет токенов';

  @override
  String obsGoalTokensLeft(String tokens) {
    return 'Осталось $tokens';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (бюджет не задан)';
  }

  @override
  String get obsGoalTokensUsed => 'Использовано токенов';

  @override
  String get obsGoalElapsed => 'Прошло';

  @override
  String get obsGoalWrapUp => 'Завершить';

  @override
  String get obsGoalClear => 'Сбросить цель';

  @override
  String get obsGoalFallbackTitle => 'Цель';

  @override
  String get obsGoalSubtitle => 'Бюджет режима цели';

  @override
  String get obsGoalStatusActive => 'Активна';

  @override
  String get obsGoalStatusPaused => 'Приостановлена';

  @override
  String get obsGoalStatusBudgetLimited => 'Ограничена бюджетом';

  @override
  String get obsGoalStatusComplete => 'Завершена';

  @override
  String get obsGoalStatusDropped => 'Сброшена';

  @override
  String get obsGoalObjectiveLabel => 'Задача';

  @override
  String get obsGoalBudgetLabel => 'Бюджет токенов (необязательно)';

  @override
  String get obsGoalSetAction => 'Задать цель';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => '% успеха';

  @override
  String get obsBenchmarkPassed => 'Успешно';

  @override
  String get obsBenchmarkFailed => 'Неудачно';

  @override
  String get obsBenchmarkErrors => 'Ошибки';

  @override
  String get obsBenchmarkSpend => 'Затраты';

  @override
  String get obsBenchmarkCostPerTask => 'Стоимость / задача';

  @override
  String get obsBenchmarkTrials => 'Попытки';

  @override
  String get obsBenchmarkNoTrials => 'Пока нет прогонов для оценки.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'И ещё $count',
      many: 'И ещё $count',
      few: 'И ещё $count',
      one: 'И ещё $count',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'Пройден';

  @override
  String get obsBenchmarkTrialFail => 'Провал';

  @override
  String get obsBenchmarkTrialError => 'Ошибка';

  @override
  String get obsBenchmarkTrialRunning => 'Выполняется';

  @override
  String get obsBenchmarkReward => 'Награда';

  @override
  String get obsBenchmarkReport => 'Отчёт';

  @override
  String get obsBenchmarkCopyMarkdown => 'Копировать markdown';

  @override
  String get obsBenchmarkCopied => 'Отчёт скопирован в буфер обмена';

  @override
  String get obsBehaviorCaption =>
      'Это сигналы раздражения из ваших сообщений — снимок здоровья переписки, а не оценка агентов. Считается локально; ничего не покидает это устройство.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'Проанализировано сообщений';

  @override
  String get obsBehaviorTotalSignals => 'Всего сигналов';

  @override
  String get obsBehaviorYelling => 'Крик';

  @override
  String get obsBehaviorProfanity => 'Мат';

  @override
  String get obsBehaviorAnguish => 'Отчаяние';

  @override
  String get obsBehaviorNegation => 'Отрицание';

  @override
  String get obsBehaviorRepetition => 'Повторы';

  @override
  String get obsBehaviorBlame => 'Обвинения';

  @override
  String get obsBehaviorConversationsTitle => 'Самые напряжённые переписки';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'Ранжированы по плотности сигналов в ваших сообщениях.';

  @override
  String get obsBehaviorNoSignals => 'Сигналов раздражения нет — всё спокойно.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count messages analyzed';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count signals';
  }

  @override
  String get obsAgentStatusIdle => 'Простой';

  @override
  String get obsAgentStatusParked => 'На паузе';

  @override
  String get obsAgentStatusAborted => 'Прерван';

  @override
  String get obsAgentKindSub => 'Дочерний';

  @override
  String get noChecksOnCommit => 'На этом коммите проверки не запускались.';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Выполняется — $count заданий',
      many: 'Выполняется — $count заданий',
      few: 'Выполняется — $count задания',
      one: 'Выполняется — $count задание',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Все проверки пройдены — $count заданий',
      many: 'Все проверки пройдены — $count заданий',
      few: 'Все проверки пройдены — $count задания',
      one: 'Все проверки пройдены — $count задание',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Завершено — $count заданий',
      many: 'Завершено — $count заданий',
      few: 'Завершено — $count задания',
      one: 'Завершено — $count задание',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total заданий',
      many: '$total заданий',
      few: '$total заданий',
      one: '$total задания',
    );
    return '$failed из $_temp0 с ошибкой';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count заданий',
      many: '$count заданий',
      few: '$count задания',
      one: '$count задание',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'Матрица: $jobId';
  }

  @override
  String get jobLogsPending => 'Логи появятся здесь, когда задание завершится.';

  @override
  String get jobLogsUnavailable => 'Логи для этого задания недоступны.';

  @override
  String get noLogsForStep => 'Для этого шага логи не записаны.';

  @override
  String get jobLogsTruncated => 'Лог обрезан — показан самый свежий вывод.';

  @override
  String get fullLog => 'Полный лог';

  @override
  String get copyLogs => 'Копировать логи';

  @override
  String get resizeGraph => 'Перетащите, чтобы изменить размер графа';

  @override
  String workflowRunStartedAgo(String time) {
    return 'Запущено $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'Завершено $time';
  }

  @override
  String get chatBridgesTitle => 'Чат-мосты';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'Упомяните бота в $provider, чтобы поставить агента на задачу, или создавайте черновики тикетов командой $command.';
  }

  @override
  String chatConnectProvider(String provider) {
    return 'Подключить $provider';
  }

  @override
  String get chatDisconnectProvider => 'Отключить';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName в $teamName';
  }

  @override
  String get chatStateLive => 'Онлайн';

  @override
  String get chatStateConnecting => 'Подключение…';

  @override
  String get chatStateError => 'Ошибка подключения';

  @override
  String get chatNotConnected => 'Не подключено';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'Потоковая передача для этого приложения $provider выключена — ответы приходят одним сообщением.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'Подключить $provider для этого рабочего пространства может только администратор.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'Создайте приложение $provider и вставьте сюда его учётные данные. Control Center сам подключается к $provider, поэтому этому серверу не нужен публичный адрес.';
  }

  @override
  String chatOpenConsole(String provider) {
    return 'Открыть консоль $provider';
  }

  @override
  String get chatOpenSetupGuide => 'Руководство по настройке';

  @override
  String get chatFieldBotToken => 'Токен бота';

  @override
  String get chatFieldAppToken => 'Токен приложения';

  @override
  String get chatFieldConfigRefreshToken => 'Токен конфигурации приложения';

  @override
  String chatFieldOptional(String label) {
    return '$label (необязательно)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'Привязать мой аккаунт $provider';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'Привяжите аккаунт $provider, чтобы сообщения, которые вы отправляете там, приписывались вам.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'Привязан к $externalUserId';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'Привяжите аккаунт $provider';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'Отправьте этот код боту $provider в личном сообщении. Он сработает один раз и истечёт через 15 минут.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'Аккаунт $provider привязан — сообщения, которые вы отправляете там, приписываются вам.';
  }

  @override
  String get chatLinkedAccounts => 'Привязанные аккаунты';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'Пока никто не привязал аккаунт $provider.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count привязанных аккаунтов',
      many: '$count привязанных аккаунтов',
      few: '$count привязанных аккаунта',
      one: '$count привязанный аккаунт',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · сопоставлено по email';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · привязано по коду';
  }

  @override
  String get chatUnlink => 'Отвязать';

  @override
  String get chatCustomizeBot => 'Настроить бота';

  @override
  String get chatCustomizeBotDescription =>
      'Переименуйте бота, измените, что он говорит о себе, или переименуйте слэш-команду.';

  @override
  String get chatCustomizeBotUnavailable =>
      'Чтобы изменить бота, Control Center нужен токен конфигурации приложения. Подключитесь заново и укажите его.';

  @override
  String chatCreateAppTitle(String provider) {
    return 'Создайте приложение $provider';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center может создать приложение $provider за вас — с нужными правами и событиями. Завершите настройку в $provider и вставьте учётные данные сюда.';
  }

  @override
  String get chatCreateApp => 'Создать приложение';

  @override
  String get chatCreateAppCta => 'Создать приложение за меня';

  @override
  String get chatAppNameLabel => 'Имя приложения';

  @override
  String get chatBotDisplayNameLabel =>
      'Имя бота (что участники вводят после @)';

  @override
  String get chatDescriptionLabel => 'Краткое описание';

  @override
  String get chatAgentDescriptionLabel =>
      'Что бот говорит о своих возможностях';

  @override
  String get chatCommandLabel => 'Слэш-команда';

  @override
  String get chatDirectMessages => 'Личные сообщения';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'Позволяет участникам писать боту в личные сообщения. Может потребоваться платный план $provider.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return 'В $provider создано приложение $appId.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'Осталось несколько шагов, которые может выполнить только $provider:';
  }

  @override
  String get chatStepAppToken => 'Создать токен уровня приложения';

  @override
  String get chatStepInstall => 'Установить приложение';

  @override
  String get chatOpenAppSettings => 'Открыть настройки приложения';

  @override
  String get chatContinueToCredentials => 'Вставить учётные данные';

  @override
  String chatBotUpdated(String provider) {
    return 'Бот обновлён в $provider.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return 'В $provider изменились права приложения. Переустановите его, чтобы изменения вступили в силу.';
  }

  @override
  String get chatReinstallApp => 'Переустановить приложение';

  @override
  String chatIconNotEditable(String provider) {
    return 'Значок бота можно изменить только в настройках приложения в $provider.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'Можно создать его самостоятельно в $provider — токен не нужен. Настройки выше передаются вместе со ссылкой.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'Создать в $provider';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '$provider открылся в браузере с этой заранее заполненной конфигурацией. Создайте приложение там, затем завершите эти шаги и вернитесь с токенами.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider не сообщает, какое приложение создано, поэтому чтобы настраивать бота отсюда, позже понадобится токен конфигурации приложения.';
  }

  @override
  String get chatStepCreateApp =>
      'Создать приложение по заранее заполненной конфигурации';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'Выберите рабочее пространство в $provider и подтвердите.';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens, с правом connections:write.';

  @override
  String get chatStepInstallHint =>
      'Install app → скопируйте OAuth-токен пользователя бота.';

  @override
  String get aboutTitle => 'О программе';

  @override
  String get aboutAppVersion => 'Версия приложения';

  @override
  String get aboutServerVersion => 'Подключённый сервер';

  @override
  String get aboutRpcCatalog => 'Каталог RPC';

  @override
  String get aboutServerUnknown => 'Не указано';

  @override
  String get serverStaleTitle => 'Встроенный сервер старше этого приложения';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'Запущенный cc_server — $serverVersion, а это приложение — $appVersion. Перезапустите приложение, чтобы подхватить последнюю встроенную сборку сервера; при разработке пересоберите её командой `dart build cli` в apps/cc_server.';
  }

  @override
  String get updateCheckButton => 'Проверить обновления';

  @override
  String get updateChecking => 'Проверка обновлений…';

  @override
  String get updateUpToDate => 'У вас актуальная версия';

  @override
  String get updateDeferredBusy =>
      'Обновление готово, но идёт запись встречи — запрос появится после её окончания.';

  @override
  String get updateOpenedReleasesPage => 'Страница релизов открыта в браузере.';

  @override
  String get updateCheckFailed => 'Не удалось проверить обновления';

  @override
  String updateAvailableVersion(String version) {
    return 'Доступна версия $version.';
  }

  @override
  String get updateBannerTitle => 'Доступна новая версия Control Center';

  @override
  String get updateBannerRefresh => 'Обновить';

  @override
  String get updateBlockedRecording =>
      'Обновление приостановлено, пока идёт запись встречи — перезагрузка произойдёт после её окончания.';

  @override
  String get settingsScopeYou => 'Вы';

  @override
  String get settingsScopeWorkspace => 'Рабочее пространство';

  @override
  String get settingsScopeServer => 'Сервер';

  @override
  String get settingsProfile => 'Профиль и идентичность';

  @override
  String get settingsYourDevices => 'Ваши устройства';

  @override
  String get settingsWorkspaceGeneral => 'Основные';

  @override
  String get settingsServerConnection => 'Подключение и состояние';

  @override
  String get settingsModelProviders => 'Провайдеры моделей';

  @override
  String get settingsVoiceModels => 'Модели голоса и встреч';

  @override
  String get settingsDiagnostics => 'Диагностика и конфиденциальность';

  @override
  String get settingsAbout => 'О программе';

  @override
  String get settingsProfileDescription =>
      'Ваше имя, почта и git-идентичность в этом рабочем пространстве. Смена рабочего пространства меняет этот слой; имя пользователя, вход и устройства остаются в вашем аккаунте в Вы → Профиль.';

  @override
  String get settingsServerConnectionDescription =>
      'К какому серверу подключается этот клиент и как сервер доступен (mDNS, туннели, relay).';

  @override
  String get settingsAboutDescription => 'Идентичность сборки и обновления.';

  @override
  String get settingsDiagnosticsDescription =>
      'Изоляция, индексирование, синхронизация, журналирование и отчёты о сбоях для этой установки.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'Политики и соглашения, общие для всех в этом рабочем пространстве.';

  @override
  String get settingsWorkspaceMeetingsDescription =>
      'Шаблоны заметок и сохранённые голоса для встреч в этом рабочем пространстве.';

  @override
  String get settingsWorkspacePolicyLabel => 'Политика рабочего пространства';

  @override
  String get settingsWorkspacePolicyDescription =>
      'Действует для всех участников и всех агентов в этом рабочем пространстве.';

  @override
  String get settingsSecretGlobsLabel => 'Исключения секретных путей';

  @override
  String get settingsSecretGlobsHelp =>
      'По одному glob на строку. Эти пути скрыты от наблюдателей и гостей на поверхностях с кодом — в дополнение к встроенным значениям по умолчанию.';

  @override
  String get settingsReviewConcurrencyLabel => 'Распараллеливание ревью';

  @override
  String get settingsReviewConcurrencyHelp =>
      'Сколько ревьюеров запускается параллельно, если число не задано явно.';

  @override
  String get settingsReviewLevelLabel => 'Уровень ревью';

  @override
  String get settingsReviewLevelHelp =>
      'Насколько глубоко идёт ИИ-ревью и какая часть находок показывается сразу. Ничего не отбрасывается — на более лёгком уровне мелкие замечания группируются, а не скрываются.';

  @override
  String get reviewLevelLight => 'Лёгкий';

  @override
  String get reviewLevelBalanced => 'Сбалансированный';

  @override
  String get reviewLevelThorough => 'Тщательный';

  @override
  String get reviewLevelLightHint =>
      'Один ревьюер. Сразу показывается только то, что действительно важно.';

  @override
  String get reviewLevelBalancedHint =>
      'Три ревьюера: QA, архитектура и реализация.';

  @override
  String get reviewLevelThoroughHint =>
      'Добавляет специалистов по безопасности и производительности и показывает все находки.';

  @override
  String get askAiReviewAtLevel => 'Ревью на другом уровне';

  @override
  String reviewNitpicksGroup(int count) {
    return 'Мелочи ($count)';
  }

  @override
  String get reviewFindingResolve => 'Исправлено';

  @override
  String get reviewFindingResolveHint =>
      'Отметить замечание как исправленное. Оно перестанет учитываться в ревью.';

  @override
  String get reviewFindingDismiss => 'Отклонить';

  @override
  String get reviewFindingDismissHint =>
      'Это не настоящая проблема. Ревьюеры больше не будут отмечать такой паттерн в будущих PR.';

  @override
  String get reviewFindingReopen => 'Открыть снова';

  @override
  String get reviewFindingStatusUndoLabel => 'Статус замечания';

  @override
  String get reviewFindingDismissTitle => 'Отклонить это замечание';

  @override
  String get reviewFindingDismissReasonHint =>
      'Почему это не применимо? Ревьюеры это прочитают.';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'Не удалось обновить замечание: $error';
  }

  @override
  String get reviewStaleTitle => 'Это ревью устарело';

  @override
  String get reviewStaleBody =>
      'Pull request изменился после этого ревью. Замечания могут указывать на код, которого уже нет.';

  @override
  String reviewStaleReviewedAt(String sha) {
    return 'Ревью на $sha';
  }

  @override
  String get reviewStaleRerun => 'Ревью ещё раз';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return 'Ревью устарело в #$prNumber';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return 'В «$title» появились новые коммиты с момента последнего ревью.';
  }

  @override
  String get reviewCategorySecurity => 'Безопасность';

  @override
  String get reviewCategoryStability => 'Стабильность';

  @override
  String get reviewCategoryDataIntegrity => 'Целостность данных';

  @override
  String get reviewCategoryCorrectness => 'Корректность';

  @override
  String get reviewCategoryPerformance => 'Производительность';

  @override
  String get reviewCategoryMaintainability => 'Сопровождаемость';

  @override
  String get reviewEffortQuickWin => 'Быстрая победа';

  @override
  String get reviewEffortModerate => 'Средняя';

  @override
  String get reviewEffortHeavyLift => 'Трудоёмкая задача';

  @override
  String get reviewProposedFix => 'Предлагаемое исправление';

  @override
  String get reviewAiAgentPrompt => 'Промпт для ИИ-агентов';

  @override
  String get reviewCopyAiPrompt => 'Копировать промпт';

  @override
  String get settingsWorkspaceAdminOnly =>
      'Изменять это могут только администраторы рабочего пространства.';

  @override
  String get chatMyAccountsTitle => 'Привязанные аккаунты чата';

  @override
  String get settingsServerSso => 'Единый вход';

  @override
  String get settingsServerSsoDescription =>
      'Вход через SAML и OpenID Connect с подготовкой пользователей';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription =>
      'Пользователи могут входить через этого провайдера';

  @override
  String get ssoEnabledDescriptionOn => 'Вход через этого провайдера включён';

  @override
  String get ssoIdpMetadataLabel => 'XML метаданных IdP';

  @override
  String get ssoIdpMetadataHint => 'вставьте XML EntityDescriptor вашего IdP';

  @override
  String get ssoEmailAttributeLabel => 'Атрибут email';

  @override
  String get ssoDisplayNameAttributeLabel => 'Атрибут отображаемого имени';

  @override
  String get ssoGroupsAttributeLabel => 'Атрибут групп';

  @override
  String get ssoIssuerLabel => 'URL издателя';

  @override
  String get ssoClientIdLabel => 'Идентификатор клиента';

  @override
  String get ssoGroupsClaimLabel => 'Claim групп';

  @override
  String get ssoAutoMemberLabel =>
      'Добавлять пользователей во все рабочие пространства при первом входе';

  @override
  String get ssoAutoMemberDescription =>
      'Отключите, чтобы требовать приглашение в каждое рабочее пространство';

  @override
  String get ssoAllowJitLabel =>
      'Создавать неизвестных пользователей при первом входе';

  @override
  String get ssoAllowJitDescription =>
      'Отключите, чтобы отклонять пользователей без учётной записи';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'Принимать незапрошенный вход (инициированный IdP)';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'Только для порталов IdP, которые запускают приложения напрямую';

  @override
  String get ssoWantResponseSignedLabel =>
      'Требовать подписанный конверт ответа';

  @override
  String get ssoWantResponseSignedDescription =>
      'Подписи assertion всегда обязательны';

  @override
  String get ssoTestConnectionButton => 'Проверить подключение';

  @override
  String get ssoTestConnectionOk => 'Подключение работает:';

  @override
  String get ssoCopySpMetadata => 'Копировать метаданные SP';

  @override
  String get ssoCopySpMetadataDone =>
      'Метаданные SP скопированы в буфер обмена';

  @override
  String get ssoSavedToast => 'Настройки единого входа сохранены';

  @override
  String get ssoUnavailable =>
      'Этот сервер не предоставляет настройки единого входа. Обновите серверный бинарник и повторите попытку.';

  @override
  String get ssoScimCardTitle => 'Подготовка пользователей (SCIM)';

  @override
  String get ssoScimDescription =>
      'Направьте SCIM-коннектор вашего провайдера идентификации на указанный ниже эндпоинт с bearer-токеном. При отзыве доступа сессии и доступ к рабочему пространству отзываются за секунды. Сервер должен быть доступен IdP (туннель или публичный URL).';

  @override
  String get ssoScimEndpoint => 'Эндпоинт SCIM';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'Сначала задайте публичный URL сервера или включите туннель';

  @override
  String get ssoScimRegenerate => 'Перевыпустить токен';

  @override
  String get ssoScimRegenerateConfirm =>
      'Создать новый bearer-токен SCIM? Предыдущий токен сразу перестанет работать.';

  @override
  String get ssoScimTokenTitle => 'Bearer-токен';

  @override
  String get ssoScimTokenPresent => 'Токен настроен';

  @override
  String get ssoScimTokenAbsent =>
      'Токена пока нет — создайте его, чтобы включить SCIM';

  @override
  String get ssoScimTokenOnce => 'Токен SCIM (показывается один раз)';

  @override
  String ssoSignInWith(String provider) {
    return 'Войти через $provider';
  }

  @override
  String get ssoProbeFailed =>
      'Не удалось связаться с этим сервером для единого входа';

  @override
  String get ssoOpensBrowser => 'Откроется браузер, чтобы завершить вход';

  @override
  String get ssoWaitingForBrowser => 'Ожидание завершения входа в браузере…';

  @override
  String get ssoBrowserOpenFailed =>
      'Не удалось открыть браузер для единого входа';

  @override
  String get ssoUseManualPairing => 'Войти по приглашению или ключу сопряжения';

  @override
  String get ssoHideManualPairing => 'Скрыть ручное сопряжение';

  @override
  String get ssoClientIdHint => 'Публичный клиент (PKCE) — секрет не нужен';

  @override
  String get ssoClientSecretLabel => 'Секрет клиента (необязательно)';

  @override
  String get ssoClientSecretHintUnset =>
      'Нужен только для конфиденциальных клиентов IdP';

  @override
  String get ssoClientSecretHintSet =>
      'Секрет уже сохранён — оставьте поле пустым, чтобы не менять его';

  @override
  String get ssoPairingToggle =>
      'Разрешить ручное сопряжение (коды приглашения и ключи сопряжения)';

  @override
  String get ssoPairingToggleDescription =>
      'Отключите, чтобы подключение было только через единый вход — новые устройства появляются через вход SSO; уже подключённые продолжают работать';

  @override
  String get ssoPairConfirmTitle => 'Подключиться к серверу?';

  @override
  String ssoPairConfirmBody(String server) {
    return 'Получены учётные данные для входа на $server, но вход из этого приложения не запускался. Подключиться к этому серверу?';
  }

  @override
  String get ssoPairConfirmConnect => 'Подключить';

  @override
  String get ssoPairConfirmCancel => 'Игнорировать';

  @override
  String get forgeConnections => 'Хостинг кода';

  @override
  String get connect => 'Подключить';

  @override
  String get disconnect => 'Отключить';

  @override
  String get notConnected => 'Не подключено';

  @override
  String get checkingConnection => 'Проверка подключения…';

  @override
  String forgeTokenTitle(String forge) {
    return 'Токен $forge';
  }

  @override
  String get settingsAudio => 'Аудио';

  @override
  String get settingsAudioDescription =>
      'Микрофон, диктовка, определение встреч и вывод звукового ландшафта.';

  @override
  String get audioDevicesSection => 'Аудиоустройства';

  @override
  String get voiceInputBehaviorSection => 'Диктовка и встречи';

  @override
  String get audioOutputDeviceTitle => 'Устройство вывода';

  @override
  String get audioOutputDefaultHint =>
      'Весь звук приложения идёт через системное устройство вывода по умолчанию.';

  @override
  String get audioOutputGone =>
      'Выбранное устройство вывода больше не подключено — используется системное по умолчанию, пока не выберете другое.';

  @override
  String get reviewHubIntroBody =>
      'Агенты анализируют diff, выделяют области изменений и приходят к общему вердикту.';

  @override
  String get reviewHubAlreadyRunning => 'Для этого pull request уже идёт ревью';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'С прошлого ревью: $resolved закрыто · $added новых · $open ещё открыто';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'Предыдущее ревью: $sha';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return 'Исправить $count замечаний';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return 'Исправить выбранные: $count';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return 'Прокомментировать выбранные: $count';
  }

  @override
  String get webConnectStayConnected =>
      'Оставаться подключённым на этом устройстве';

  @override
  String get webConnectStayConnectedDetail =>
      'Оставаться подключённым на этом устройстве (ключ сохраняется в этом браузере)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'Не удалось создать рабочее пространство: $error';
  }

  @override
  String committedRelative(String relative) {
    return 'закоммичено $relative';
  }

  @override
  String get selectAgents => 'Выберите агентов';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count агента',
      many: '$count агентов',
      few: '$count агента',
      one: '$count агент',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => 'Новый разговор';

  @override
  String get untitledConversation => 'Разговор без названия';

  @override
  String get conversationTitleOptionalHint =>
      'Необязательно — оставьте пустым, и модель заголовков назовёт его автоматически';

  @override
  String get contentSynthesizerUnavailable =>
      'Агента Content synthesizer нет, или у него нет рабочего раннера';

  @override
  String get conversationNeedsAgent =>
      'Упомяните агента через @, чтобы начать этот разговор';

  @override
  String get conversationTitleGenerate => 'Сгенерировать';

  @override
  String get conversationTitleNoMessages =>
      'Сначала отправьте сообщение. Название создаётся по нему.';

  @override
  String get conversationTitleGenerateFailed =>
      'Не удалось сгенерировать название. Попробуйте ещё раз.';

  @override
  String get startThread => 'Начать ветку';

  @override
  String get deleteSpaceConfirm =>
      'Удалить это пространство? Все сообщения будут потеряны.';

  @override
  String threadTabTitle(String title) {
    return 'Ветка: $title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ответа',
      many: '$count ответов',
      few: '$count ответа',
      one: '$count ответ',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return 'Последний ответ $time';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Войти через $provider';
  }

  @override
  String get signInAgain => 'Войти снова';

  @override
  String get forgeSignInBannerTitle =>
      'Хостинг кода не подключён в этом рабочем пространстве';

  @override
  String get forgeSignInBannerBody =>
      'Срок действия входа истёк или доступ был отозван, либо это рабочее пространство использует собственный GitHub App. Пул-реквесты, ревью и синхронизация репозиториев приостановлены, пока вы не войдёте.';

  @override
  String get forgeSignInBannerAction => 'Войти';

  @override
  String get ticketing => 'Тикеты';

  @override
  String get ticketingProviderHelp =>
      'Где хранятся ваши тикеты. Локальный вариант оставляет их в Control Center.';

  @override
  String providerComingSoon(String provider) {
    return '$provider (скоро)';
  }

  @override
  String get ticketProviderLocal => 'Локальный';

  @override
  String get providerApps => 'Приложения провайдера';

  @override
  String get providerAppsDescription =>
      'Приложения, которые этот сервер сам зарегистрировал у каждого провайдера. Через них люди входят в систему, и на них же выполняется фоновая работа — вебхуки, опрос и синхронизация, — но никогда не на чьём-то личном входе.';

  @override
  String get providerAppId => 'ID приложения';

  @override
  String get providerPrivateKey => 'Закрытый ключ';

  @override
  String get providerClientId => 'ID клиента';

  @override
  String get providerClientSecret => 'Секрет клиента';

  @override
  String get providerCallbackUrl => 'Callback URL';

  @override
  String get providerAppFullyConfigured =>
      'Сервер может действовать от своего имени, и люди могут входить.';

  @override
  String get providerAppServerOnly =>
      'Сервер может действовать от своего имени. Добавьте ID клиента и секрет, чтобы люди могли входить.';

  @override
  String get providerAppSignInOnly =>
      'Люди могут входить. Фоновая работа использует их учётные данные.';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'Учётные данные работают. Установлено на: $accounts';
  }

  @override
  String get couldNotOpenBrowser =>
      'Не удалось открыть браузер. Скопируйте ссылку и завершите вход самостоятельно.';

  @override
  String get contextUsage => 'Использование контекста';

  @override
  String get contextUsageFull => 'полный';

  @override
  String get contextUsageTokens => 'токены';

  @override
  String get contextSeeMore => 'Ещё';

  @override
  String get contextSegmentSystemPrompt => 'Системный промпт';

  @override
  String get contextSegmentRules => 'Правила';

  @override
  String get contextSegmentSkills => 'Навыки';

  @override
  String get contextSegmentToolDefinitions => 'Определения инструментов';

  @override
  String get contextSegmentMcpTools => 'MCP и динамические инструменты';

  @override
  String get contextSegmentDeferredTools => 'Инструменты по требованию';

  @override
  String get contextSegmentSubagents => 'Определения субагентов';

  @override
  String get contextSegmentMemory => 'Память';

  @override
  String get contextSegmentConversation => 'Диалог';

  @override
  String get contextSegmentRunner =>
      'Промпт исполнителя, инструменты и работа хода';

  @override
  String get contextUsageMeasured => 'По данным последнего вызова модели';

  @override
  String get contextUsageEstimated => 'Оценка, пока запуск не сообщит расход';

  @override
  String get contextExplorerTitle => 'Контекст';

  @override
  String get contextExplorerEverything => 'Всё';

  @override
  String get contextExplorerSelectPart =>
      'Выберите часть, чтобы посмотреть содержимое';

  @override
  String get contextExplorerUnavailable => 'Разбивка контекста недоступна';

  @override
  String get contextRetry => 'Повторить';

  @override
  String get settingsFieldOptional => 'Необязательно';

  @override
  String get settingsFilterHint => 'Фильтровать список';

  @override
  String get settingsValueNotAvailable => 'Пока недоступно';

  @override
  String get settingsNoEntriesYet => 'Пока ничего нет';

  @override
  String get settingsChangedBadge => 'Изменено';

  @override
  String get ssoConnectionCardDescription =>
      'Выберите, как люди входят на этот сервер, затем включите это подключение.';

  @override
  String get ssoUseSamlForSignIn => 'Вход через SAML';

  @override
  String get ssoUseOidcForSignIn => 'Вход через OpenID Connect';

  @override
  String get ssoSaveConnection => 'Сохранить подключение';

  @override
  String get ssoStateLive => 'Работает';

  @override
  String get ssoStateConfiguredOff => 'Настроено, выкл.';

  @override
  String get ssoStateOnIncomplete => 'Вкл., не завершено';

  @override
  String get ssoStateActive => 'Активно';

  @override
  String get ssoStateAllowed => 'Разрешено';

  @override
  String get ssoStateNoToken => 'Нет токена';

  @override
  String get ssoSummaryDirectorySync => 'Синхронизация каталога';

  @override
  String get ssoSummaryManualPairing => 'Ручное сопряжение';

  @override
  String get ssoNoMethodLiveNote =>
      'Ни один способ входа не включён. Новые устройства подключаются по приглашению или ключу сопряжения, пока вы не настроите подключение и не включите его.';

  @override
  String get ssoMethodSamlBlurb =>
      'Для провайдеров идентификации с SAML 2.0, например Okta, Entra ID или Google Workspace.';

  @override
  String get ssoMethodOidcBlurb =>
      'Для провайдеров идентификации с OpenID Connect. Обычно настраивается проще.';

  @override
  String get ssoGroupIdentityProvider => 'Провайдер идентификации';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'Откуда приходят утверждения и как этот сервер их проверяет.';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'Какому издателю доверяет этот сервер и от имени какого клиента он аутентифицируется.';

  @override
  String get ssoSpEntityIdShortLabel => 'Entity ID SP';

  @override
  String get ssoSpEntityIdDescription =>
      'Оставьте пустым, чтобы вывести из URL сервера.';

  @override
  String get ssoIssuerDescription =>
      'Базовый URL, по которому доступен discovery-документ провайдера.';

  @override
  String get ssoSecretStored => 'Сохранено';

  @override
  String get ssoGroupHandoff => 'Что нужно вашему провайдеру удостоверений';

  @override
  String get ssoGroupHandoffDescription =>
      'Вставьте это в приложение, которое вы создали у провайдера.';

  @override
  String get ssoOriginUnknownTitle => 'Этот сервер не знает свой публичный URL';

  @override
  String get ssoOriginUnknownBody =>
      'URL входа и обратного вызова строятся на его основе, поэтому провайдер не сможет достучаться до этого сервера, пока URL не задан. Добавьте публичный URL или включите туннель в разделе «Сервер → Подключение».';

  @override
  String get ssoAcsUrlLabel => 'URL службы потребителя утверждений (ACS)';

  @override
  String get ssoAcsUrlDescription =>
      'Куда провайдер отправляет подписанное утверждение.';

  @override
  String get ssoSpEntityIdResolvedLabel =>
      'Идентификатор сущности поставщика услуг';

  @override
  String get ssoMetadataUrlLabel => 'URL метаданных SP';

  @override
  String get ssoMetadataUrlDescription =>
      'Провайдеры, которые импортируют метаданные, могут загрузить их отсюда.';

  @override
  String get ssoRedirectUriLabel => 'URI перенаправления';

  @override
  String get ssoRedirectUriDescription =>
      'Добавьте его в разрешённые URI перенаправления приложения у провайдера.';

  @override
  String get ssoSignInUrlLabel => 'URL входа';

  @override
  String get ssoSignInUrlDescription =>
      'Отправляйте людей сюда, чтобы начать вход через единый вход.';

  @override
  String get ssoGroupAttributeMapping => 'Сопоставление атрибутов';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'Какой claim несёт каждое поле. Оставьте значения по умолчанию, если провайдер не переименовал их.';

  @override
  String get ssoGroupAccess => 'Доступ и роли';

  @override
  String get ssoGroupAccessDescription =>
      'Что разрешено делать тем, кто успешно вошёл.';

  @override
  String get ssoDefaultRoleShortLabel => 'Роль по умолчанию';

  @override
  String get ssoDefaultRoleDescription =>
      'Назначается всем, чьи группы не совпали ни с одним сопоставлением ниже.';

  @override
  String get ssoRoleMapShortLabel => 'Сопоставление групп и ролей';

  @override
  String get ssoRoleMapDescription =>
      'Побеждает первая совпавшая группа. Владелец этим способом не назначается.';

  @override
  String get ssoRoleMapGroupHint => 'Имя группы у провайдера';

  @override
  String get ssoRoleMapAdd => 'Добавить сопоставление';

  @override
  String get ssoRoleMapEmpty =>
      'Нет сопоставлений — всем назначается роль по умолчанию.';

  @override
  String get ssoAdvancedSummary =>
      'Расхождение часов, вход по инициативе IdP, политика подписи';

  @override
  String get ssoClockSkewShortLabel => 'Расхождение часов';

  @override
  String get ssoClockSkewDescription =>
      'Допустимое расхождение меток времени утверждений в секундах. Для большинства провайдеров подходит 90.';

  @override
  String get ssoScimGenerate => 'Создать токен';

  @override
  String get ssoScimTokenOnceBody =>
      'Скопировано в буфер обмена. Токен показывается один раз и не восстанавливается — сразу вставьте его у провайдера.';

  @override
  String get ssoPairingCardTitle => 'Ручное сопряжение';

  @override
  String get ssoPairingCardDescription =>
      'Другой способ попасть на этот сервер: коды приглашения и ключи сопряжения для устройств без единого входа.';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count из $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'Ни один провайдер не подключён, поэтому встроенной среде выполнения агентов не на чем работать. Добавьте API-ключ или войдите в один из провайдеров ниже.';

  @override
  String get providersFilterHint => 'Фильтр провайдеров';

  @override
  String get providersNoneMatch => 'Ничего не подходит под фильтр';

  @override
  String get providerDeniedHereTitle => 'Запрещён в этом рабочем пространстве';

  @override
  String get providerDeniedHereBody =>
      'Агенты здесь не могут использовать этот провайдер, хотя он подключён. Другие рабочие пространства не затрагиваются.';

  @override
  String get providerNeedsSignIn =>
      'Войдите, чтобы использовать этот провайдер';

  @override
  String get providerNeedsApiKey =>
      'Добавьте API-ключ, чтобы использовать этот провайдер';

  @override
  String get providerApiKeyLabel => 'API-ключ';

  @override
  String get providerGenerationDefaults => 'Значения провайдера по умолчанию';

  @override
  String get providerNoModelsYet =>
      'Модели пока не получены. Подключите провайдера, затем синхронизируйте.';

  @override
  String get providerModelsFilterHint => 'Фильтр моделей';

  @override
  String get adaptersNoneReadyNote =>
      'На этой машине не найдено ни одного CLI из каталога раннеров. Установите один, затем обновите список.';

  @override
  String get adaptersFilterHint => 'Фильтр раннеров';

  @override
  String get adaptersLaunchGroup => 'Запуск';

  @override
  String get adaptersLaunchGroupDescription =>
      'Что передаётся этому раннеру, когда агент его запускает. Можно задать до установки CLI.';

  @override
  String get adaptersEnvNone => 'Не заданы';

  @override
  String adaptersEnvCount(int count) {
    return '$count set';
  }

  @override
  String get adapterArgumentsDescription =>
      'Добавляются к командной строке раннера при каждом запуске.';

  @override
  String get settingsStateFailed => 'Сбой';

  @override
  String get providerAppsGroupServer => 'В роли сервера';

  @override
  String get providerAppsGroupServerDescription =>
      'Используется рабочими пространствами, которые следуют приложениям входа этого сервера. Рабочее пространство со своими приложениями настраивает своё App в разделе Рабочее пространство → Интеграции.';

  @override
  String get providerAppsGroupPrConversations => 'Беседы в pull request';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'Как разработчики могут общаться с этим сервером на GitHub в рабочих пространствах, которые следуют этому серверу. Рабочее пространство со своими приложениями имеет собственного бота в разделе Рабочее пространство → Интеграции. Работает без webhook и публичного URL: сервер опрашивает GitHub сам.';

  @override
  String get providerAppBotLogin => 'Логин бота';

  @override
  String get providerAppBotLoginEmpty =>
      'Проверьте подключение, чтобы узнать логин бота.';

  @override
  String get providerAppAskOnGitHub => 'Обращения на GitHub';

  @override
  String get providerAppAskOnGitHubHint =>
      'Упомяните логин бота выше в комментарии к pull request — суффикс [bot] необязателен — чтобы запросить ревью или задать вопрос, ответить в его обсуждениях ревью или добавить метку `ai-review` для запроса ревью.';

  @override
  String get providerAppsGroupSignIn => 'Вход пользователей';

  @override
  String get providerAppsGroupSignInDescription =>
      'Позволяет каждому участнику подключить свой аккаунт и получить собственные учётные данные.';

  @override
  String get providerAppCapActsAsServer => 'Действует как сервер';

  @override
  String get providerAppCapSignsIn => 'Выполняет вход пользователей';

  @override
  String get portLabel => 'Порт';

  @override
  String get mcpBridgedToolsLabel => 'Инструменты';

  @override
  String get guardrailFamilyFiles => 'Файлы';

  @override
  String get guardrailFamilyGit => 'Git и pull request';

  @override
  String get guardrailFamilyMachine => 'Машина и сеть';

  @override
  String get guardrailFamilyControl => 'Секреты и рабочее пространство';

  @override
  String get guardrailScopeFieldLabel => 'Правила для';

  @override
  String get guardrailScopeFieldDescription =>
      'Более узкая область перекрывает более широкую. Правила, заданные здесь, дополняют унаследованные.';

  @override
  String get guardrailSetHere => 'Задано здесь';

  @override
  String get guardrailClearAllHere => 'Очистить все';

  @override
  String get guardrailFamilyCommands => 'Команды';

  @override
  String get guardrailStandingApproval => 'Одобрение на время';

  @override
  String guardrailEntryAllow(String what) {
    return 'Разрешено: $what';
  }

  @override
  String guardrailEntryPrompt(String what) {
    return 'Спрашивать сначала: $what';
  }

  @override
  String guardrailEntryDeny(String what) {
    return 'Запрещено: $what';
  }

  @override
  String guardrailCoversBranches(String patterns) {
    return 'ветки $patterns';
  }

  @override
  String guardrailCoversPaths(String patterns) {
    return 'пути $patterns';
  }

  @override
  String guardrailCoversHosts(String patterns) {
    return 'хосты $patterns';
  }

  @override
  String guardrailCoversCommands(String patterns) {
    return 'команды $patterns';
  }

  @override
  String guardrailCoversTools(String names) {
    return 'инструменты $names';
  }

  @override
  String guardrailCoversCommandPrefix(String prefix) {
    return 'команды, начинающиеся с $prefix';
  }

  @override
  String guardrailCoversMaxCount(String count) {
    return 'не более $count одновременно';
  }

  @override
  String guardrailCoversMaxCents(String amount) {
    return 'не более $amount центов';
  }

  @override
  String get guardrailCoversEverything => 'каждое действие такого вида';

  @override
  String guardrailEntryGivenBy(String name) {
    return 'от $name';
  }

  @override
  String guardrailEntryEnds(String time) {
    return 'до $time';
  }

  @override
  String get guardrailEntryNoEnd => 'до отзыва';

  @override
  String guardrailRevokeEntry(String entry) {
    return 'Отозвать: $entry';
  }

  @override
  String get guardrailRevokeFailed =>
      'Не удалось отозвать. Попробуйте ещё раз.';

  @override
  String get guardrailEntryInactive => 'не действует, пока стоит «Запретить»';

  @override
  String guardrailClassPartlyAllowed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Разрешено в $count случаях из перечисленных ниже',
      many: 'Разрешено в $count случаях из перечисленных ниже',
      few: 'Разрешено в $count случаях из перечисленных ниже',
      one: 'Разрешено в $count случае из перечисленных ниже',
    );
    return '$_temp0';
  }

  @override
  String guardrailStandingFromWorkspace(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count одобрений на время, выданных на всё рабочее пространство, тоже действуют здесь.',
      many:
          '$count одобрений на время, выданных на всё рабочее пространство, тоже действуют здесь.',
      few:
          '$count одобрения на время, выданные на всё рабочее пространство, тоже действуют здесь.',
      one:
          '$count одобрение на время, выданное на всё рабочее пространство, тоже действует здесь.',
    );
    return '$_temp0';
  }

  @override
  String guardrailStandingInNarrowerScopes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count одобрений на время задано для отдельных пространств или агентов. Выберите «Пространство» или «Агент» выше, чтобы их увидеть.',
      many:
          '$count одобрений на время задано для отдельных пространств или агентов. Выберите «Пространство» или «Агент» выше, чтобы их увидеть.',
      few:
          '$count одобрения на время заданы для отдельных пространств или агентов. Выберите «Пространство» или «Агент» выше, чтобы их увидеть.',
      one:
          '$count одобрение на время задано для отдельного пространства или агента. Выберите «Пространство» или «Агент» выше, чтобы его увидеть.',
    );
    return '$_temp0';
  }

  @override
  String get sandboxingCardLabel => 'Песочница';

  @override
  String get sandboxingCardDescription =>
      'Изолирована ли работа агента от этого хоста и к чему изолированный агент всё ещё может обращаться.';

  @override
  String get sandboxBackendNoneActive => 'Хост, без изоляции';

  @override
  String get sandboxSummaryHost => 'Хост';

  @override
  String get sandboxGroupIsolation => 'Изоляция';

  @override
  String get sandboxGroupIsolationDescription =>
      'Где на самом деле выполняются процессы агента и запись в файлы.';

  @override
  String get sandboxGroupAgentActions => 'Что разрешено агентам';

  @override
  String get sandboxGroupAgentActionsDescription =>
      'Разрешать ли отправку в удалённый репозиторий, открытие pull request и доступ к сети, спрашивать ли сначала или запрещать, задаётся в разрешениях агента.';

  @override
  String get sandboxBackendFieldDescription =>
      'Авто выбирает самый сильный вариант, который поддерживает этот хост. Зафиксируйте один, чтобы он не менялся сам.';

  @override
  String get sandboxSummaryInForce => 'Действует';

  @override
  String get rigsInstallHintLabel => 'Как установить';

  @override
  String get rigsStarting => 'Запуск';

  @override
  String get rigsResidentMemory => 'Резидентная память';

  @override
  String get installedLabel => 'Установлено';

  @override
  String get notInstalledLabel => 'Не установлено';

  @override
  String ssoOtherKindUnsaved(String method) {
    return 'В $method есть несохранённые изменения';
  }

  @override
  String get collapseComment => 'Свернуть комментарий';

  @override
  String get expandComment => 'Развернуть комментарий';

  @override
  String get suggestedChange => 'Предложенное изменение';

  @override
  String get emptyComment => 'Пустой комментарий';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ответа',
      many: '$count ответов',
      few: '$count ответа',
      one: '$count ответ',
    );
    return '$_temp0';
  }

  @override
  String diffFileUnresolvedConversations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count нерешённых бесед',
      many: '$count нерешённых бесед',
      few: '$count нерешённые беседы',
      one: '$count нерешённая беседа',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => 'Ожидает ревью';

  @override
  String failedToResolveConversation(String error) {
    return 'Не удалось обновить беседу: $error';
  }

  @override
  String get addSingleComment => 'Добавить один комментарий';

  @override
  String get addToReview => 'Добавить в ревью';

  @override
  String get startAReview => 'Начать ревью';

  @override
  String get commentModeAgent => 'Агент';

  @override
  String get commentModeComment => 'Комментарий';

  @override
  String get commentModeReview => 'Ревью';

  @override
  String get commentDestination => 'Куда отправить комментарий';

  @override
  String get commentHintAgent => 'Отправить агенту…';

  @override
  String get commentHintReview => 'Добавить в ревью…';

  @override
  String get reviewNeedsABody =>
      'Сначала напишите сводку или поставьте в очередь комментарий в коде';

  @override
  String get reviewSubmitted => 'Ревью отправлено';

  @override
  String get finishYourReview => 'Завершить ревью';

  @override
  String get commentVerdict => 'Комментарий';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count комментария в очереди',
      many: '$count комментариев в очереди',
      few: '$count комментария в очереди',
      one: '$count комментарий в очереди',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 'и ещё $count';
  }

  @override
  String get queuedCommentHint =>
      'Этот комментарий отправится, когда вы отправите ревью.';

  @override
  String commentOnLinesRange(int start, int end) {
    return 'Строки $start–$end';
  }

  @override
  String get claudeAccountsTitle => 'Аккаунты Claude Code';

  @override
  String get claudeAccountsDescription =>
      'Каждая учётная запись — отдельный вход в Claude Code. Запуски используют привязанные ниже учётные записи в этом порядке.';

  @override
  String get claudeAccountsEmpty => 'Пока нет учётных записей';

  @override
  String get claudeAccountAdd => 'Добавить учётную запись';

  @override
  String get claudeAccountSignIn => 'Войти';

  @override
  String get claudeAccountSignInAgain => 'Войти снова';

  @override
  String get claudeAccountSignInHint =>
      'Выполните это в терминале на сервере. Откроется браузер для завершения входа, а учётные данные запишутся в каталог этой учётной записи.';

  @override
  String get claudeAccountSignedOut => 'Выход выполнен';

  @override
  String get claudeAccountExpired => 'Срок входа истёк';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'Срок входа истёк $when. Войдите снова, чтобы использовать эту учётную запись.';
  }

  @override
  String get claudeAccountMakeDefault => 'Сделать основной';

  @override
  String get claudeAccountDefault => 'Основная';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return 'Удалить $label?';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'Будет выполнен выход из учётной записи, а её каталог на сервере будет удалён. Сам вход не затрагивается.';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'Не удалось проверить эту учётную запись: $error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return 'Использовано $percent%';
  }

  @override
  String get accountPoolStrategy => 'Ротация';

  @override
  String get accountPoolPinned => 'Закреплённая';

  @override
  String get accountPoolRoundRobin => 'По кругу';

  @override
  String get accountPoolSerial => 'По одной';

  @override
  String get accountPoolPinnedHint =>
      'Всегда начинать с первой учётной записи. Остальные остаются запасными, если она не сработает.';

  @override
  String get accountPoolRoundRobinHint =>
      'Распределять запуски по учётным записям, переходя к следующей при каждой отправке.';

  @override
  String get accountPoolSerialHint =>
      'Исчерпать первую учётную запись, прежде чем переходить к следующей.';

  @override
  String get accountPoolMoveUp => 'Вверх';

  @override
  String get accountPoolMoveDown => 'Вниз';

  @override
  String get accountPoolUsingAll =>
      'Пока ничего не привязано — используются все учётные записи в этом порядке.';

  @override
  String get accountPoolInheriting =>
      'Наследуются учётные записи рабочего пространства.';

  @override
  String get accountPoolResetToWorkspace =>
      'Сбросить к учётным записям рабочего пространства';

  @override
  String accountPoolCoolingOff(String when) {
    return 'квота исчерпана до $when';
  }

  @override
  String get accountPoolSignedOut => 'выход выполнен';

  @override
  String get accountPoolExpired => 'срок входа истёк';

  @override
  String accountPoolLoadFailed(String error) {
    return 'Не удалось загрузить ротацию: $error';
  }

  @override
  String get providerSignedInAccount => 'вошедшая учётная запись';

  @override
  String get agentAccountsTab => 'Учётные записи';

  @override
  String get agentClaudeAccountsNoticeTitle =>
      'Несколько учётных записей Claude Code';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return 'Этот раннер входит под одной из $count учётных записей Claude Code на этом хосте. Выберите нужную или чередуйте их на вкладке «Аккаунты».';
  }

  @override
  String get agentAccountsDescription =>
      'Какие учётные записи используют запуски этого агента. Каждый блок сначала наследует выбор рабочего пространства.';

  @override
  String get agentAccountsNothingToRotate =>
      'Нечего ротировать — сначала подключите вторую учётную запись или ключ.';

  @override
  String failedToPostReply(String error) {
    return 'Не удалось отправить ответ: $error';
  }

  @override
  String failedToPostComment(String error) {
    return 'Не удалось отправить комментарий: $error';
  }

  @override
  String commentOnLine(int line) {
    return 'Строка $line';
  }

  @override
  String get viewInDiff => 'Открыть в diff';

  @override
  String get subscriptionUsagePreviousAccount => 'Предыдущая учётная запись';

  @override
  String get subscriptionUsageNextAccount => 'Следующая учётная запись';

  @override
  String inReplyTo(String path) {
    return 'В ответ на $path';
  }

  @override
  String get subscriptionUsageNoneReported =>
      'Для этой учётной записи нет данных об использовании.';

  @override
  String get subscriptionUsageCredits => 'Кредиты';

  @override
  String get subscriptionUsageBalance => 'Баланс';

  @override
  String subscriptionUsageBalanceLeft(String amount) {
    return 'Осталось $amount';
  }

  @override
  String get reviewHubStaticRule => 'Статическое правило';

  @override
  String get reviewHubStarted => 'Ревью начато';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'Найдено детерминированным правилом ($rule) в строке, которую добавляет этот pull request, — не агентом-ревьюером.';
  }

  @override
  String get prReviewArtifactTab => 'Ревью PR';

  @override
  String get prReviewRunning => 'Идёт ревью этого pull request…';

  @override
  String get prReviewStarting => 'Запуск ревью…';

  @override
  String get prReviewStartingBody =>
      'Готовится рабочее дерево этого pull request. Ревьюеры запустятся, как только оно будет готово.';

  @override
  String get prReviewFailed => 'Ревью не удалось.';

  @override
  String get prReviewRerunning => 'Повторное ревью…';

  @override
  String get prReviewNoOpenFindings => 'Нет открытых замечаний';

  @override
  String prReviewOpenFindings(int count) {
    return '$count open findings';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used из $limit';
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
  String get reviewRailReport => 'Отчёт';

  @override
  String get reviewNoFindingsTitle => 'Пока нет замечаний по ревью';

  @override
  String get reviewNoFindingsHint =>
      'Замечания появляются здесь, когда агенты их публикуют.';

  @override
  String reviewShowDismissed(int count) {
    return 'Показать $count отклонённых';
  }

  @override
  String reviewHideDismissed(int count) {
    return 'Скрыть $count отклонённых';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'обнаружено $count разногласий рецензентов',
      many: 'обнаружено $count разногласий рецензентов',
      few: 'обнаружено $count разногласия рецензентов',
      one: 'обнаружено $count разногласие рецензентов',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'Тип';

  @override
  String get reviewFilterStatus => 'Статус';

  @override
  String get reviewKindBug => 'Ошибка';

  @override
  String get reviewKindSuggestion => 'Предложение';

  @override
  String get reviewKindRecommendation => 'Рекомендация';

  @override
  String get reviewKindQuestion => 'Вопрос';

  @override
  String get reviewKindTicket => 'Тикет';

  @override
  String get spaceAllPrsMerged =>
      'Все запросы на слияние в этом пространстве объединены. Архивировать пространство?';

  @override
  String get spaceKeepAfterMerge => 'Нет, сохранить пространство';

  @override
  String get spaceKeepAfterMergeHint =>
      'Вас больше не спросят об этом пространстве.';

  @override
  String get archiveSpace => 'Архивировать пространство';

  @override
  String get archivedSpaces => 'Архивные пространства';

  @override
  String get archivedSpacesEmpty => 'Нет архивных пространств';

  @override
  String get restoreSpace => 'Восстановить';

  @override
  String get archivedConversations => 'Архивные беседы';

  @override
  String get archivedConversationsEmpty => 'Нет архивных бесед';

  @override
  String get restoreConversation => 'Восстановить';

  @override
  String archivedWhen(String time) {
    return 'Архивировано $time';
  }

  @override
  String get deleteSpacePermanently => 'Удалить безвозвратно';

  @override
  String get renameSpace => 'Переименовать пространство';

  @override
  String get renameConversation => 'Переименовать беседу';

  @override
  String get spaceActions => 'Действия с пространством';

  @override
  String get conversationActions => 'Действия с беседой';

  @override
  String get editSpaceRepos => 'Изменить репозитории';

  @override
  String get editSpaceReposTitle => 'Репозитории пространства';

  @override
  String get editSpaceReposWarning =>
      'Добавление репозитория извлекает его в это пространство; удаление стирает его папку.';

  @override
  String get agentSectionIdentity => 'Идентичность';

  @override
  String get agentSectionRuntime => 'Среда выполнения';

  @override
  String get agentSectionGuardrails => 'Ограничения';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count подчинённых',
      many: '$count подчинённых',
      few: '$count подчинённых',
      one: '$count подчинённый',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'Фильтровать команды…';

  @override
  String get teamsSummaryWithLeader => 'С руководителем';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count команд',
      many: '$count команд',
      few: '$count команды',
      one: '$count команда',
      zero: 'Нет команд',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return 'Удаление $name стирает его профиль, связи с навыками и историю запусков. Это нельзя отменить.';
  }

  @override
  String get resetToDefault => 'Сбросить по умолчанию';

  @override
  String get newAgent => 'Новый агент';

  @override
  String get newSkill => 'Новый навык';

  @override
  String get newItemAction => 'Новый';

  @override
  String get zoomIn => 'Увеличить';

  @override
  String get zoomOut => 'Уменьшить';

  @override
  String get resetZoom => 'Сбросить масштаб';

  @override
  String get imageHostedOnGitHub => 'Изображение размещено на GitHub';

  @override
  String get imageOpenExternally => 'Изображение · открыть внешне';

  @override
  String get memoryScopeAll => 'Все области';

  @override
  String get memoryScopeWorkspace => 'На всё рабочее пространство';

  @override
  String get memoryScopeFilterLabel => 'Фильтровать по области';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return 'Ограничено репозиторием $repo';
  }

  @override
  String get toolScreenshot => 'Снимок экрана от агента';

  @override
  String get toolImageUnavailable => 'Изображение недоступно';

  @override
  String toolImagesUnavailable(int count) {
    return '$count изображений недоступно';
  }

  @override
  String get shakeUnavailable => 'Встряхивание недоступно на этом сервере';

  @override
  String get shakeNothing => 'Нечего вытряхнуть — недавние ходы защищены';

  @override
  String shakeDone(int tokens) {
    return 'Освобождено около $tokens токенов';
  }

  @override
  String get compactionDivider => 'Сжато';

  @override
  String compactionDividerCount(int count) {
    return 'Сжато · свёрнуто сообщений: $count';
  }

  @override
  String get composerDropToAttach => 'Перетащите, чтобы прикрепить';

  @override
  String get composerAttachmentUploading => 'Загрузка…';

  @override
  String get composerAttachmentReady => 'Готово';

  @override
  String get composerAttachmentUploadFailed => 'Не удалось загрузить';

  @override
  String composerAttachmentTooLarge(String limit) {
    return 'Размер файла превышает лимит $limit';
  }

  @override
  String get composerAttachmentUnreadable => 'Не удалось прочитать этот файл';

  @override
  String get composerAttachmentWaitForUploads =>
      'Дождитесь завершения загрузки вложений';

  @override
  String get composerAttachmentResolveFailures =>
      'Перед отправкой повторите загрузку вложений с ошибкой или удалите их';

  @override
  String get attachmentUnavailable => 'Вложение недоступно';

  @override
  String get attachmentUnavailableDetail =>
      'Это вложение больше не хранится в памяти. Прикрепите его снова, чтобы посмотреть.';

  @override
  String get attachmentPreviewFailed => 'Не удалось открыть этот файл';

  @override
  String get attachmentPreviewUnsupported =>
      'Нет просмотра для этого типа файлов';

  @override
  String get attachmentTooLargeToPreview => 'Слишком большой для просмотра';

  @override
  String get attachmentOpenExternally => 'Открыть в приложении по умолчанию';

  @override
  String get asideEmpty => 'Пока не на чем работать';

  @override
  String get asideFailed => 'Не удалось получить ответ';

  @override
  String get handoffTitle => 'Передача';

  @override
  String get asideTitle => 'Побочный вопрос';

  @override
  String get attachFilesOrDrop => 'Прикрепите файлы — или перетащите сюда';

  @override
  String composerExpand(String shortcut) {
    return 'Развернуть редактор ($shortcut)';
  }

  @override
  String composerCollapse(String shortcut) {
    return 'Свернуть редактор ($shortcut)';
  }

  @override
  String get guidedGoalTitle => 'Уточните цель';

  @override
  String get guidedGoalIntro =>
      'Агенту без надзора нужно точно знать, когда задача выполнена. Сначала несколько вопросов.';

  @override
  String get guidedGoalAnswerHint => 'Ваш ответ';

  @override
  String get guidedGoalNext => 'Далее';

  @override
  String get guidedGoalStart => 'Запустить цель';

  @override
  String get guidedGoalSkip => 'Пропустить и запустить как есть';

  @override
  String guidedGoalStillMissing(String items) {
    return 'Ещё не указано: $items';
  }

  @override
  String get conversationTreeTitle => 'Дерево переписки';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count веток',
      many: '$count веток',
      few: '$count ветки',
      one: '$count ветка',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'Продолжить отсюда';

  @override
  String get conversationTreeFork => 'Ответвить в новую переписку';

  @override
  String get conversationTreeCurrent => 'На этой ветке';

  @override
  String get conversationTreeEmpty => 'Пока ничего нет';

  @override
  String get conversationTreeForked => 'Ответвлено в новую переписку';

  @override
  String get conversationTreeSwitched => 'Продолжение с этого сообщения';

  @override
  String exportSaved(String path) {
    return 'Сохранено в $path';
  }

  @override
  String get exportFailed => 'Не удалось записать экспорт';

  @override
  String get contextCommandNoAgent =>
      'В этой переписке нет агента, поэтому окно контекста открыть нельзя';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'В этой переписке нет агента «$name». Попробуйте: $names';
  }

  @override
  String get dumpCopied => 'Транскрипт скопирован в буфер обмена';

  @override
  String get messageQueueHint =>
      'Продолжайте вводить, чтобы поставить следующие изменения в очередь';

  @override
  String get steerNow => 'Направить';

  @override
  String get steerForce => 'Остановить и отправить';

  @override
  String get steeringQueueLabel => 'Сообщения управления в очереди';

  @override
  String get steeringDeliverUnavailable =>
      'Сейчас нет работающего агента, который мог бы это принять — останется в очереди.';

  @override
  String get reorderSteeringCard => 'Изменить порядок сообщения в очереди';

  @override
  String get editSteeringCard => 'Изменить сообщение в очереди';

  @override
  String get deleteSteeringCard => 'Удалить сообщение в очереди';

  @override
  String get steeringBadge => 'Направлено';

  @override
  String get settingsSandboxLabel => 'Песочница';

  @override
  String get sandboxExecGrantsTitle => 'Разрешения на запуск';

  @override
  String get sandboxExecGrantsSubtitle =>
      'Программы, которые агенты могут запускать из своей рабочей копии ваших репозиториев. Каждая запись одобрена вами, когда песочница запросила разрешение.';

  @override
  String get sandboxExecGrantsEmpty =>
      'Решений пока нет. Спросим, когда агенту впервые понадобится запустить программу из своей рабочей копии.';

  @override
  String get sandboxExecGrantRevoke => 'Отозвать';

  @override
  String get sandboxExecGrantAllowed => 'Разрешено';

  @override
  String get sandboxExecGrantBlocked => 'Запрещено';

  @override
  String get sandboxExecGrantRevokeConfirmTitle => 'Отозвать это решение?';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'Спросим снова, когда агенту понадобится запустить программу из этой копии.';

  @override
  String get sandboxExecGrantsSearchHint => 'Поиск по путям';

  @override
  String get sandboxExecGrantsNoMatch =>
      'Нет разрешений, соответствующих запросу';

  @override
  String get demoBadgeLabel => 'Демо';

  @override
  String get demoFilePickerTitle => 'Файлы демо';

  @override
  String get demoFilePickerBody =>
      'В демо загрузка имитируется: выберите любой файл — он прикрепится к сообщению, не затрагивая диск.';

  @override
  String get demoFilePickerAttach => 'Прикрепить';

  @override
  String get demoReadOnlySave => 'В демо только чтение';

  @override
  String get demoBadgeTooltip =>
      'Вы в демо. Данные вымышленные, агенты работают по сценарию.';

  @override
  String get demoFirstRunTitle => 'Вы в живом демо';

  @override
  String demoFirstRunBody(int minutes) {
    return 'Это настоящее приложение на настоящем коде — выдуманы только данные. Агенты транслируют настоящие прогоны по сценарию: ничего не уходит в модель и ничего не запускается на машине. Рабочее пространство только ваше и исчезает через $minutes минут.';
  }

  @override
  String get demoFirstRunDismiss => 'Понятно';

  @override
  String get demoTourTitle => 'С чего начать';

  @override
  String get demoTourSubtitle =>
      'Четыре места, где видно, что делает приложение.';

  @override
  String get demoTourSkip => 'Пропустить';

  @override
  String get demoTourStarRepo => 'Поставить звезду на GitHub';

  @override
  String get demoTourOpen => 'Открыть';

  @override
  String get demoTourSpacesTitle => 'Поговорить с агентом';

  @override
  String get demoTourSpacesBody =>
      'Отправьте сообщение в пространстве и смотрите, как в поток приходит запуск — рассуждения, вызовы инструментов и стоимость, как в настоящем запуске.';

  @override
  String get demoTourReviewTitle => 'Просмотрите pull request';

  @override
  String get demoTourReviewBody =>
      'Откройте #412. Оставьте комментарий в строке или отправьте ревью: текст попадёт в обсуждение и останется там.';

  @override
  String get demoTourTicketsTitle => 'Следите за работой';

  @override
  String get demoTourTicketsBody =>
      'Тикеты, to-do и планы связаны с теми же разговорами, которые ведут агенты.';

  @override
  String get demoTourInboxTitle => 'Смотрите всю операцию';

  @override
  String get demoTourInboxBody =>
      'Все оповещения со всех направлений собираются во входящих — ревью, тикеты, запуски и встречи.';

  @override
  String get demoUnavailableTitle => 'В демо недоступно';

  @override
  String get demoUnavailableTerminal =>
      'Терминал запускает настоящий shell на хосте сервера. В демо нет среды исполнения — поэтому его безопасно открыть публично.';

  @override
  String get demoUnavailableRig =>
      'Enclosure — одноразовая виртуальная машина, которой управляет агент. Демо не запускает ни одной: публичная точка, которая может стартовать VM, — это уже не демо.';

  @override
  String get demoUnavailableEditor =>
      'Редактор в браузере запускает процесс code-server на настоящей рабочей копии. В демо нет ни того ни другого.';

  @override
  String get demoUnavailableFeeds =>
      'Демо читает настоящие ленты, но список подписок фиксирован. Добавлять и удалять их здесь нельзя.';

  @override
  String get demoUnavailableForge =>
      'В демо нет учётных данных, оно не обращается к GitHub, GitLab или Linear. Его pull request — фикстуры, а ваши комментарии к ним хранятся локально.';

  @override
  String get demoUnavailableModels =>
      'Демо не вызывает модель. Запуски агентов — записанное воспроизведение, поэтому они ничего не стоят и не обращаются к провайдеру.';

  @override
  String get demoUnavailableMcp =>
      'Поверхность инструментов MCP в демо не подключена, поэтому внешний клиент к ней не подключится.';

  @override
  String get demoUnavailableRepos =>
      'Демо не клонирует код и не запускает git. Репозиторий, который вы видите, — фикстура за pull request.';

  @override
  String get demoUnavailableSkills =>
      'Установка скилла скачивает и сканирует код. Демо ничего не загружает.';

  @override
  String get demoUnavailableSso =>
      'Единый вход — это конфигурация сервера. Демо вместо этого входит как временный гость.';

  @override
  String get demoUnavailableAudio =>
      'Запись и диктовка требуют захвата звука и речевой модели на хосте. В демо нет ни того ни другого, поэтому встречи — только расшифровки без воспроизведения.';

  @override
  String get demoUnavailableServerAdmin =>
      'Это администрирование сервера. Демо даёт каждому посетителю своё одноразовое рабочее пространство и ничего сверх этого.';

  @override
  String get demoUnavailablePipelines =>
      'Конвейеры здесь не запускаются. Посетитель, который может написать шаг bash и запустить его — вручную или через триггер события — выполняет код на этом хосте.';

  @override
  String get settingsBackupRestore => 'Резервное копирование и восстановление';

  @override
  String get settingsBackupRestoreDescription =>
      'Снимки всех баз данных на этом сервере, а также экспорт, импорт и удаление одного рабочего пространства.';

  @override
  String get backupSnapshotsLabel => 'Снимки установки';

  @override
  String get backupSnapshotsExplainer =>
      'Снимок копирует все базы данных в папку с меткой времени на хосте сервера. Чтобы восстановить всю установку, эту папку копируют обратно при остановленном сервере; одно рабочее пространство можно восстановить отсюда.';

  @override
  String get backupNowAction => 'Создать снимок';

  @override
  String backupSnapshotWritten(String path) {
    return 'Снимок записан в $path';
  }

  @override
  String get backupNoSnapshots =>
      'Снимков установки пока нет. Создайте один сейчас или используйте запланированный конвейер для резервных копий рабочего пространства.';

  @override
  String get backupSnapshotComplete => 'Полный';

  @override
  String get backupDeleteSnapshotLabel => 'Удалить снимок';

  @override
  String get backupDeleteSnapshotDescription =>
      'Безвозвратно удалить этот снимок с сервера. Сначала скачайте его, если хотите сохранить.';

  @override
  String get backupDeleteSnapshotAction => 'Удалить снимок';

  @override
  String get backupDeleteSnapshotTitle => 'Удалить этот снимок?';

  @override
  String backupDeleteSnapshotBody(String name) {
    return 'Удалить $name с сервера? Все базы данных в этом снимке будут потеряны. Действие необратимо.';
  }

  @override
  String backupDeleteSnapshotDone(String name) {
    return 'Снимок $name удалён.';
  }

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count рабочего пространства',
      many: '$count рабочих пространств',
      few: '$count рабочих пространства',
      one: '$count рабочее пространство',
      zero: 'Нет рабочих пространств',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count рабочего пространства не попало в снимок',
      many: '$count рабочих пространств не попали в снимок',
      few: '$count рабочих пространства не попали в снимок',
      one: '$count рабочее пространство не попало в снимок',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'Путь на сервере';

  @override
  String get backupScheduledLabel => 'Резервные копии по расписанию';

  @override
  String get backupScheduledExplainer =>
      'Копии, которые сохраняет конвейер резервного копирования каждого рабочего пространства. Расписание и срок хранения задаются в шаблоне конвейера.';

  @override
  String get backupScheduledNone => 'Резервных копий пока нет';

  @override
  String backupScheduledCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count резервной копии',
      many: '$count резервных копий',
      few: '$count резервные копии',
      one: '$count резервная копия',
    );
    return '$_temp0';
  }

  @override
  String backupScheduledLast(String time) {
    return 'Последняя копия: $time';
  }

  @override
  String get backupListForbidden =>
      'Чтобы видеть резервные копии этого рабочего пространства, нужна роль администратора.';

  @override
  String get backupScheduledDeleteTitle => 'Удалить эту резервную копию?';

  @override
  String backupScheduledDeleteBody(String date, String name) {
    return 'Удалить с сервера копию $name от $date? Это действие нельзя отменить.';
  }

  @override
  String get backupScheduledDeleteDone => 'Резервная копия удалена.';

  @override
  String get backupScheduledWorkspaceDeleted => 'Рабочее пространство удалено';

  @override
  String get backupRestoreAction => 'Восстановить';

  @override
  String get backupRestoreTitle => 'Восстановить рабочее пространство';

  @override
  String backupRestoreBody(String name) {
    return 'Всё содержимое $name будет заменено копией из этого снимка. Всё, что рабочее пространство сделало после снимка, будет потеряно, отменить это нельзя.';
  }

  @override
  String backupRestoreDone(String name) {
    return 'Восстановлено $name из снимка.';
  }

  @override
  String get backupWorkspaceUnknown => 'Больше нет на этом сервере';

  @override
  String get backupWorkspaceDataLabel => 'Данные рабочего пространства';

  @override
  String get backupWorkspaceDataExplainer =>
      'Одно рабочее пространство — один файл базы, поэтому экспорт копирует этот файл, а не выгружает таблицы по отдельности. Импорт заменяет всё в целевом рабочем пространстве указанным файлом.';

  @override
  String get backupExportAction => 'Экспорт';

  @override
  String backupExportDone(String path) {
    return 'Экспортировано в $path';
  }

  @override
  String get backupExportedFileLabel => 'Экспортированный файл на сервере';

  @override
  String get backupImportAction => 'Импорт';

  @override
  String backupImportTitle(String name) {
    return 'Импорт в $name';
  }

  @override
  String backupImportBody(String name) {
    return 'Всё содержимое $name будет заменено содержимым файла. То, что сейчас в рабочем пространстве, будет потеряно, отменить это нельзя.';
  }

  @override
  String get backupImportSourceLabel => 'Файл базы рабочего пространства';

  @override
  String get backupImportSourceDescription =>
      'Файл .db, который сервер может прочитать. Пути разрешаются на хосте сервера, не на этом устройстве.';

  @override
  String backupImportDone(String name) {
    return 'Импортировано в $name.';
  }

  @override
  String backupDeleteBody(String name) {
    return '$name исчезнет из всех списков и поиска. Файл базы останется на диске, резервные копии по-прежнему его включают, место само не освободится.';
  }

  @override
  String get backupExportDescription =>
      'Записать копию на сервер или скачать на это устройство.';

  @override
  String get backupExportOnServerAction => 'Сохранить на сервере';

  @override
  String get backupDownloadAction => 'Скачать';

  @override
  String backupDownloadSaved(String path) {
    return 'Сохранено в $path';
  }

  @override
  String get backupDownloadInBrowser => 'Браузер скачивает файл.';

  @override
  String get backupRestoreFromDeviceLabel => 'Восстановить с этого устройства';

  @override
  String get backupRestoreFromDeviceDescription =>
      'Выберите файл базы рабочего пространства — Control Center загрузит его на сервер. Этот способ подходит, когда сервер — не этот компьютер.';

  @override
  String get backupUploadAction => 'Выберите файл и загрузите';

  @override
  String get backupTransferUnavailable =>
      'Передача файлов для этого подключения ещё не настроена. Переподключитесь к серверу, чтобы скачать или загрузить резервную копию.';

  @override
  String get backupTransferForbidden =>
      'Сервер отказал. Для скачивания рабочего пространства нужна роль администратора рабочего пространства. Для восстановления нужен владелец сервера, который также должен быть владельцем этого рабочего пространства. Для полного снимка нужен владелец сервера.';

  @override
  String get backupTransferUnsupported =>
      'У этого сервера нет интерфейса резервного копирования.';

  @override
  String get backupTransferTooLarge => 'Файл больше, чем принимает сервер.';

  @override
  String get credentialGateWaitingTitle => 'Ожидание учётных данных';

  @override
  String credentialGateHarnessTitle(String provider) {
    return 'У $provider нет учётных данных';
  }

  @override
  String get credentialGateSignedOutTitle => 'Выполнен выход из Claude Code';

  @override
  String get credentialGateExpiredTitle => 'Срок входа в Claude Code истёк';

  @override
  String get credentialGatePlanSpentTitle =>
      'Достигнут лимит плана Claude Code';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent ожидает продолжения.';
  }

  @override
  String get credentialGateWaitingRun => 'Запуск ожидает продолжения.';

  @override
  String get credentialGateWatching =>
      'Следим за исправлением — запуск продолжится сам.';

  @override
  String credentialGateFreesUpAt(String time) {
    return 'Освободится в $time';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'Запуск прекратит ожидание в $time';
  }

  @override
  String get credentialGateCheckAgain => 'Проверить снова';

  @override
  String get credentialGateCancelRun => 'Отменить запуск';

  @override
  String get credentialGateAccountsTried => 'Проверенные аккаунты';

  @override
  String get credentialGateClaudeSignInHint =>
      'Войдите через Настройки → Адаптеры → Claude Code или выполните команду входа в терминале. Запуск подхватит это сам.';

  @override
  String get credentialGateOpenSettings => 'Открыть настройки';

  @override
  String get credentialGateAccountsRemovedTitle =>
      'Привязанные аккаунты Claude Code удалены';

  @override
  String get credentialGateAccountsRemovedHint =>
      'Привяжите другой аккаунт в настройках аккаунтов этого агента или рабочего пространства либо очистите список, чтобы использовать аккаунт по умолчанию. Запуск продолжится сам.';

  @override
  String get accountPoolAllRemoved =>
      'Все аккаунты из этого списка удалены с сервера. Привяжите другой или очистите список.';

  @override
  String get accountPoolClear => 'Очистить список';

  @override
  String get selectModel => 'Выбрать модель';

  @override
  String get allModels => 'Все модели';

  @override
  String get noModelsMatchSearch => 'Ни одна модель не соответствует запросу';

  @override
  String useCustomModelId(String id) {
    return 'Использовать «$id»';
  }

  @override
  String get modelFree => 'Бесплатно';

  @override
  String modelOutputTokens(String tokens) {
    return '$tokens вывода';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return '$input ввод / $output вывод за 1 млн токенов';
  }

  @override
  String modelEffortLevels(String levels) {
    return 'Усилие рассуждения: $levels';
  }

  @override
  String get modelSupportsReasoning => 'Поддерживает усилие рассуждения';

  @override
  String get profileDeliveryMetrics => 'Метрики доставки';

  @override
  String profileMetricsSample(int count) {
    return 'Проанализировано PR: $count';
  }

  @override
  String get profileMergeRate => 'Доля слияний';

  @override
  String get profileReviewCoverage => 'Охват проверками';

  @override
  String get profilePrSize => 'Размер PR';

  @override
  String get profileTimeToMerge => 'Время до слияния';

  @override
  String get profileMergeTimeTrend => 'Динамика времени слияния';

  @override
  String get profileWeeklyMedian => 'Недельная медиана, логарифмическая шкала';

  @override
  String get profilePrOpeningPattern => 'День недели × час, местное время';

  @override
  String get profileFirstReview => 'Время до первой проверки';

  @override
  String get profileMetricsTruncated =>
      'Процентили рассчитываются по ограниченной выборке доступных запросов на включение изменений.';

  @override
  String profileLinesChanged(String count) {
    return 'Строк: $count';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count мин';
  }

  @override
  String profileDurationHours(int count) {
    return '$count ч';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '$days д $hours ч';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return 'Участников: $count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return 'В этом рабочем пространстве нет запросов на слияние от $team';
  }

  @override
  String get profilePrStateFilterLabel =>
      'Фильтр запросов на слияние по состоянию';

  @override
  String get noProfilePrsMatchSearchHint =>
      'Попробуйте другое название или номер запроса на слияние';

  @override
  String get rigNetworkUnrestricted => 'Сеть без ограничений';

  @override
  String get rigNetworkAllowAllHosts => 'Разрешить все узлы';

  @override
  String get rigBrowserPermissionsTitle => 'Разрешения сайта';

  @override
  String get rigBrowserPermissionsTooltip => 'Разрешения сайта и сеть';

  @override
  String get rigBrowserPermissionEmpty =>
      'Пока ни один сайт не запрашивал разрешение';

  @override
  String rigBrowserPermissionPrompt(String origin, String permission) {
    return '$origin хочет использовать: $permission';
  }

  @override
  String get rigBrowserPermissionBlock => 'Заблокировать';

  @override
  String get rigBrowserPermissionCamera => 'Камера';

  @override
  String get rigBrowserPermissionMicrophone => 'Микрофон';

  @override
  String get rigBrowserPermissionNotifications => 'Уведомления';

  @override
  String get rigBrowserPermissionGeolocation => 'Геолокация';

  @override
  String get rigBrowserPermissionPersistentStorage => 'Постоянное хранилище';

  @override
  String get rigBrowserPermissionClipboard => 'Буфер обмена';

  @override
  String get rigBrowserPermissionDisplayCapture => 'Запись экрана';

  @override
  String get rigBrowserPermissionMidi => 'MIDI';

  @override
  String get rigNetworkBypassTitle => 'Разрешить все сетевые узлы?';

  @override
  String get rigNetworkBypassBody =>
      'Изолированная среда будет перезапущена, а незакоммиченная работа внутри неё будет удалена. После этого гостевая система сможет обращаться к любым сетевым узлам до закрытия.';

  @override
  String get rigNetworkRestartUnrestricted => 'Перезапустить без ограничений';

  @override
  String get rigNetworkUnrestrictedBody =>
      'Эта изолированная среда может обращаться к любым сетевым узлам. Закройте её и откройте новую, чтобы восстановить ограничения по умолчанию.';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      'Этот эмулятор Android уже управляет своей сетью самостоятельно, поэтому Control Center не может применить список разрешённых узлов. Перезапуск не требуется.';

  @override
  String get rigClipboardPermissionHostToRigTitle =>
      'Вставить буфер обмена в эту среду?';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'Control Center прочитает буфер обмена вашего устройства и отправит его содержимое в среду. Содержимое буфера обмена может включать пароли или другие секретные данные.';

  @override
  String get rigClipboardPermissionRigToHostTitle =>
      'Скопировать буфер обмена из этой среды?';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'Control Center прочитает буфер обмена среды и заменит буфер обмена вашего устройства его содержимым. Считайте содержимое из среды недоверенным.';

  @override
  String get rigClipboardAllowTenMinutes => 'Разрешить на 10 минут';

  @override
  String get rigClipboardAlwaysAllow => 'Всегда разрешать';

  @override
  String get rigClipboardSettingsTitle => 'Доступ к буферу обмена';

  @override
  String get rigClipboardSettingsHint =>
      'Выберите, какие передачи буфера обмена могут выполняться без запроса. Временные разрешения истекают через 10 минут.';

  @override
  String get rigClipboardAlwaysPasteTitle => 'Всегда разрешать вставку в среды';

  @override
  String get rigClipboardAlwaysPasteDescription =>
      'Отправлять буфер обмена этого устройства в любую среду без запроса.';

  @override
  String get rigClipboardAlwaysCopyTitle =>
      'Всегда разрешать копирование из сред';

  @override
  String get rigClipboardAlwaysCopyDescription =>
      'Помещать содержимое буфера обмена из любой среды на это устройство без запроса.';

  @override
  String get profileOverlayHint =>
      'Эти поля — вы в этом пространстве. Пустые поля наследуют имя и почту аккаунта. Смена пространства меняет этот слой.';

  @override
  String get stackStartNextPart => 'Начать следующую часть';

  @override
  String get stackPartNameTitle => 'Имя части';

  @override
  String get stackPartNameHint => 'напр. миграция';

  @override
  String get stackPublish => 'Опубликовать стек';

  @override
  String get stackCurrentPart => 'Текущая';

  @override
  String get stackSwitchDirty =>
      'Зафиксируйте или отмените изменения перед переключением частей';

  @override
  String get stackCutFailed => 'Не удалось начать следующую часть';

  @override
  String get stackPublishFailed => 'Не удалось опубликовать стек';

  @override
  String get stackPublished => 'Стек опубликован как черновики';

  @override
  String get stackOpenPullRequest => 'Открыть pull request';

  @override
  String get stackSection => 'Стек';

  @override
  String get mergeConflictsButton => 'Конфликты';

  @override
  String mergeConflictsFileCount(int count, String base) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файла конфликтуют с $base',
      many: '$count файлов конфликтуют с $base',
      few: '$count файла конфликтуют с $base',
      one: '1 файл конфликтует с $base',
    );
    return '$_temp0';
  }

  @override
  String get mergeConflictsLoading => 'Поиск конфликтующих файлов…';

  @override
  String get mergeConflictsLoadFailed =>
      'Не удалось получить список конфликтующих файлов';

  @override
  String get mergeConflictsNoneFound =>
      'Конфликтующие файлы не найдены. Возможно, GitHub ещё обновляет этот pull request.';

  @override
  String get askAiToFixConflicts => 'Попросить ИИ исправить конфликты';

  @override
  String get fixConflictsStarted =>
      'Агент устраняет конфликты в чате этого pull request';

  @override
  String failedToStartConflictFix(String error) {
    return 'Не удалось запустить исправление конфликтов: $error';
  }

  @override
  String get settingsLinks => 'Ссылки';

  @override
  String get linksSettingsDescription =>
      'Выберите, где открываются ссылки извне Control Center, например pull request, открытый из GitHub.';

  @override
  String get repoLinkRememberedTitle => 'Запомненные рабочие пространства';

  @override
  String get repoLinkRememberedHint =>
      'Если репозиторий привязан к нескольким рабочим пространствам, при открытии ссылки на него появится вопрос, какое рабочее пространство использовать. Здесь перечислены выборы, которые вы попросили запомнить.';

  @override
  String get repoLinkRememberedEmpty => 'Запомненных вариантов пока нет.';

  @override
  String get repoLinkForget => 'Забыть';

  @override
  String get repoLinkWorkspaceUnavailable =>
      'Рабочее пространство больше недоступно';

  @override
  String get repoLinkWorkspaceDialogTitle => 'Выберите рабочее пространство';

  @override
  String repoLinkWorkspaceDialogBody(String repo) {
    return '$repo привязан к нескольким рабочим пространствам. В каком открыть эту ссылку?';
  }

  @override
  String get repoLinkWorkspaceRemember =>
      'Запомнить мой выбор для этого репозитория';

  @override
  String get repoLinkWorkspaceOpen => 'Открыть';

  @override
  String get repoLinkUnlinkedTitle =>
      'Добавить репозиторий в рабочее пространство';

  @override
  String repoLinkUnlinkedBody(String repo) {
    return '$repo пока не привязан ни к одному рабочему пространству. Добавьте его в одно из них, чтобы открыть эту ссылку.';
  }

  @override
  String repoLinkUnlinkedAddTo(String workspace) {
    return 'Добавить в $workspace';
  }

  @override
  String get repoLinkUnlinkedAddToHint => 'Выберите его checkout на сервере.';

  @override
  String get repoLinkUnlinkedCreate => 'Новое рабочее пространство';

  @override
  String get repoLinkUnlinkedCreateHint =>
      'Задайте название, затем выберите checkout.';

  @override
  String repoLinkChooseCheckout(String repo) {
    return 'Выберите checkout $repo на машине, где запущен сервер.';
  }

  @override
  String repoLinkCheckoutMismatch(String repo) {
    return 'Среди добавленных репозиториев нет $repo, поэтому ссылка открылась без него.';
  }

  @override
  String get windowMinimize => 'Свернуть';

  @override
  String get windowMaximize => 'Развернуть';

  @override
  String get windowRestore => 'Восстановить';

  @override
  String nativeSandboxUnsupported(String platform) {
    return 'Нативная песочница пока не поддерживается на $platform.';
  }

  @override
  String get continueWithoutSandbox => 'Продолжить без песочницы';

  @override
  String get sandboxCheckAgain => 'Проверить снова';

  @override
  String get ideQuickOpen => 'Перейти к файлу';

  @override
  String get ideQuickOpenHint => 'Поиск файлов по имени';

  @override
  String get ideQuickOpenRecentlyOpened => 'Недавно открытые';

  @override
  String get ideQuickOpenOpenToSide => 'Открыть сбоку';

  @override
  String get ideQuickOpenRemoveRecent => 'Удалить из недавно открытых';

  @override
  String get ideQuickOpenNoRecent => 'Нет недавно открытых файлов';

  @override
  String get diffMarkFileViewed => 'Отметить как просмотренный';

  @override
  String get diffMarkFileNotViewed => 'Отметить как непросмотренный';

  @override
  String diffAdditionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count добавления',
      many: '$count добавлений',
      few: '$count добавления',
      one: '$count добавление',
    );
    return '$_temp0';
  }

  @override
  String diffDeletionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count удаления',
      many: '$count удалений',
      few: '$count удаления',
      one: '$count удаление',
    );
    return '$_temp0';
  }

  @override
  String diffFileSemantics(
    String path,
    String status,
    String additions,
    String deletions,
  ) {
    return '$path, $status, $additions, $deletions';
  }

  @override
  String diffFileSemanticsViewed(
    String path,
    String status,
    String additions,
    String deletions,
  ) {
    return '$path, $status, $additions, $deletions, просмотрен';
  }

  @override
  String diffFileRenamedFrom(String previous) {
    return 'переименован из $previous';
  }

  @override
  String diffTreeFolderSemantics(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файла',
      many: '$count файлов',
      few: '$count файла',
      one: '$count файл',
    );
    return '$name, папка, $_temp0';
  }

  @override
  String diffTreeFileSemantics(String name, String status) {
    return '$name, $status';
  }

  @override
  String diffTreeFileSemanticsViewed(String name, String status) {
    return '$name, $status, просмотрен';
  }

  @override
  String diffLineAdded(int line, String code) {
    return 'Добавлена строка $line: $code';
  }

  @override
  String diffLineRemoved(int line, String code) {
    return 'Удалена строка $line: $code';
  }

  @override
  String diffLineContext(int line, String code) {
    return 'Строка $line: $code';
  }

  @override
  String diffLineHunk(String header) {
    return 'Фрагмент $header';
  }

  @override
  String get diffLineBlank => 'пусто';

  @override
  String get diffCommentOnLineAction => 'Прокомментировать эту строку';

  @override
  String diffFileMarkedViewedAnnouncement(String path) {
    return '$path отмечен как просмотренный';
  }

  @override
  String diffFileMarkedNotViewedAnnouncement(String path) {
    return '$path отмечен как непросмотренный';
  }

  @override
  String prLineChangesSemantics(int additions, int deletions) {
    return 'Добавлено строк: $additions, удалено строк: $deletions';
  }

  @override
  String closeTabNamed(String tab) {
    return 'Закрыть $tab';
  }

  @override
  String get notificationAgentAwaitingInput => 'Агенту требуется внимание';

  @override
  String get notifyAgentAwaitingInput =>
      'Когда агенту нужны одобрение, ответ или действующие учётные данные либо правило блокирует действие';

  @override
  String notificationAgentNeedsApproval(String agent) {
    return '$agent ждёт вашего одобрения';
  }

  @override
  String get notificationAgentNeedsApprovalUnnamed =>
      'Агент ждёт вашего одобрения';

  @override
  String notificationAgentAskedQuestion(String agent) {
    return 'У $agent есть вопрос';
  }

  @override
  String get notificationAgentAskedQuestionUnnamed => 'У агента есть вопрос';

  @override
  String notificationAgentBlockedOnCredential(String agent) {
    return '$agent остановлен из-за учётных данных';
  }

  @override
  String get notificationAgentBlockedOnCredentialUnnamed =>
      'Агент остановлен из-за учётных данных';

  @override
  String notificationWaitReminder(String title) {
    return 'Всё ещё ждёт: $title';
  }

  @override
  String get killTerminal => 'Завершить терминал';

  @override
  String get stopAgentCommand => 'Остановить команду';

  @override
  String get agentCommandStopping => 'Остановка…';

  @override
  String sidebarAgeSeconds(int count) {
    return '$count с';
  }

  @override
  String agentCommandSemantics(String command, String elapsed) {
    return 'Команда агента $command, выполняется $elapsed';
  }

  @override
  String get serverLostTitle => 'Соединение с сервером потеряно';

  @override
  String get serverLostBody =>
      'Control Center продолжает пытаться переподключиться в фоновом режиме. Повторите попытку сейчас или перейдите на экран входа, чтобы выбрать сервер.';

  @override
  String get serverLostRetrying => 'Переподключение…';

  @override
  String serverLostNextAttempt(int seconds) {
    return 'Следующая попытка через $seconds с';
  }

  @override
  String get serverLostReconnect => 'Переподключиться';

  @override
  String get serverLostSignIn => 'Перейти ко входу';

  @override
  String get serverEndedTitle => 'Не удаётся переподключиться к серверу';

  @override
  String get shutdownSubtitleServer => 'Сервер останавливается';

  @override
  String get skillEvalAbsent => 'Отсутствует или доступен';

  @override
  String get skillEvalAmbient => 'Фоновые навыки';

  @override
  String skillEvalArtifactRef(String reference) {
    return 'Ссылка на артефакт: $reference';
  }

  @override
  String skillEvalAttempt(String task, String arm, int repeat) {
    final intl.NumberFormat repeatNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String repeatString = repeatNumberFormat.format(repeat);

    return '$task · $arm · повтор $repeatString';
  }

  @override
  String get skillEvalAttempts => 'Попытки';

  @override
  String get skillEvalAvailableEvent => 'Доступен';

  @override
  String get skillEvalBaseline => 'Хеш предыдущей ревизии';

  @override
  String get skillEvalBodyLoad => 'Содержимое загружено';

  @override
  String get skillEvalBudgetCents => 'Бюджет (US cents)';

  @override
  String get skillEvalBudgetNote =>
      'Платная оценка использует выбранного провайдера и бюджет. Результаты проверки безопасности отображаются отдельно.';

  @override
  String get skillEvalUsageBudgetNote =>
      'Бюджеты подписки учитывают потребление по эквивалентным тарифам API, а не суммы счетов. Уже выполняющийся вызов может превысить бюджет; после достижения лимита новые вызовы не запускаются. Проверки безопасности выполняются отдельно.';

  @override
  String get skillEvalCancel => 'Отменить запуск';

  @override
  String get skillEvalCancelled => 'Отменено';

  @override
  String get skillEvalCancelling => 'Отмена';

  @override
  String get skillEvalComparison => 'Сравнение';

  @override
  String get skillEvalCompleted => 'Завершено';

  @override
  String get skillEvalComposition => 'Состав';

  @override
  String get skillEvalCorpus => 'Набор задач';

  @override
  String skillEvalCoverage(String corpus, int repeats) {
    final intl.NumberFormat repeatsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String repeatsString = repeatsNumberFormat.format(repeats);

    return '$corpus · $repeatsString повторов';
  }

  @override
  String get skillEvalCoverageComplete =>
      'Все запланированные испытания проведены';

  @override
  String skillEvalCurrentHash(String hash) {
    return 'Хеш текущего пакета: $hash';
  }

  @override
  String get skillEvalDisableUpdates => 'Отключить оценки обновлений';

  @override
  String get skillEvalEnableUpdates => 'Включить оценки обновлений';

  @override
  String get skillEvalExport => 'Скопировать JSON со скрытыми данными';

  @override
  String get skillEvalFailed => 'Ошибка';

  @override
  String get skillEvalForced => 'Принудительная загрузка или отсутствие';

  @override
  String get skillEvalForcedEvent => 'Принудительная загрузка';

  @override
  String get skillEvalHashLabel => 'Хеш пакета';

  @override
  String get skillEvalProgressLabel => 'Ход выполнения';

  @override
  String get skillEvalUpdatesToggle => 'Оценки обновлений';

  @override
  String get skillEvalHashUnavailable =>
      'Хеш пакета недоступен на этом сервере. Оценка отключена.';

  @override
  String get skillEvalHistory => 'История ревизий';

  @override
  String get skillEvalImproved => 'Улучшено';

  @override
  String get skillEvalIncomplete => 'Не завершено';

  @override
  String get skillEvalInconclusive => 'Решения нет (недостаточно данных)';

  @override
  String get skillEvalInferred => 'Выведено косвенно';

  @override
  String get skillEvalInterrupted => 'Прервано';

  @override
  String get skillEvalLoadUnobserved =>
      'Загрузка навыка не отслеживается; отсутствие события не доказывает, что навык был проигнорирован.';

  @override
  String get skillEvalModel => 'Выбранная модель';

  @override
  String get skillEvalNoAttempts => 'Попыток пока нет.';

  @override
  String get skillEvalNoModels =>
      'Нет доступных подключённых моделей. Сначала подключите провайдера в настройках.';

  @override
  String get skillEvalNoPrevious =>
      'В истории кампании нет предыдущего хеша. Оцените предыдущую ревизию перед её заменой.';

  @override
  String get skillEvalNoReport =>
      'Отчёта пока нет; данные частичных попыток доступны.';

  @override
  String get skillEvalNoWorkspace => 'Рабочее пространство не выбрано.';

  @override
  String get skillEvalNoTasks => 'Данных о задачах пока нет.';

  @override
  String get skillEvalNoVerifiers => 'Данные проверок не зафиксированы.';

  @override
  String get skillEvalNotEvaluated =>
      'Эта точная версия не оценивалась. Сканирование не подтверждает поведение.';

  @override
  String get skillEvalNotVerified => 'Не проверено';

  @override
  String get skillEvalObserved => 'Наблюдалось';

  @override
  String get skillEvalOpenQuality => 'Открыть раздел «Качество»';

  @override
  String get skillEvalPolicyNote =>
      'По умолчанию сохранение навыка не запускает платную оценку. Если вы явно включите автоматическую переоценку при обновлении, сохранение запустит платную переоценку в пределах заданного бюджета.';

  @override
  String get skillEvalPolicyNeedsCampaign =>
      'Сначала оцените ревизию, чтобы настроить политику обновлений.';

  @override
  String get skillEvalPolicyTemplate => 'Настройка политики обновлений';

  @override
  String get skillEvalPartial => 'Неполные данные; решения о принятии нет';

  @override
  String skillEvalProgress(int completed, int planned) {
    final intl.NumberFormat completedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String completedString = completedNumberFormat.format(completed);
    final intl.NumberFormat plannedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String plannedString = plannedNumberFormat.format(planned);

    return '$completedString из $plannedString попыток';
  }

  @override
  String skillEvalProvider(String provider) {
    return 'Провайдер: $provider';
  }

  @override
  String get skillEvalQualityIntro =>
      'Кампании навыков рабочего пространства и данные по отдельным ревизиям.';

  @override
  String get skillEvalQueued => 'В очереди';

  @override
  String get skillEvalReconnecting =>
      'Повторное подключение к снимкам кампании…';

  @override
  String get skillEvalRefresh => 'Обновить';

  @override
  String get skillEvalReferenceLoad => 'Эталон загружен';

  @override
  String get skillEvalRepetitions => 'Повторов на задачу';

  @override
  String get skillEvalReport => 'Отчёт с результатами';

  @override
  String get skillEvalRunning => 'Выполняется';

  @override
  String get skillEvalScriptExecution => 'Скрипт выполнен';

  @override
  String skillEvalSpend(String spent, String budget) {
    return 'Расходы: $spent / бюджет $budget';
  }

  @override
  String get skillEvalStart => 'Начать оценку';

  @override
  String get skillEvalStartTitle => 'Сравнить ревизии навыка';

  @override
  String get skillEvalStale => 'Устарело';

  @override
  String skillEvalStaleReason(String reason) {
    return 'Устарело: $reason';
  }

  @override
  String skillEvalTaskClusters(String count) {
    return 'Различные кластеры задач: $count';
  }

  @override
  String skillEvalTaskEvidence(String rate, String passes, String cost) {
    return '$rate ($passes подтверждено) · $cost';
  }

  @override
  String get skillEvalTasks => 'Задачи по вариантам';

  @override
  String get skillEvalToolError => 'Ошибка инструмента';

  @override
  String get skillEvalTools => 'События инструментов';

  @override
  String get skillEvalTitle => 'Оценка навыка';

  @override
  String skillEvalUnavailable(String reason) {
    return 'Недоступно: $reason';
  }

  @override
  String get skillEvalUnknown => 'Неизвестно';

  @override
  String get skillEvalUnsaved =>
      'Несохранённые изменения не учитываются. Сохраните их перед оценкой.';

  @override
  String get skillEvalUncertainty => 'Интервал неопределённости';

  @override
  String get skillEvalVerified => 'Подтверждено';

  @override
  String get skillEvalVerifiers => 'Проверка';

  @override
  String get skillEvalVerdict => 'Заключение';

  @override
  String skillEvalExportCopied(String filename) {
    return 'Копирование завершено: $filename';
  }

  @override
  String get skillEvalPlanViolation => 'Нарушение плана';

  @override
  String get skillEvalPreserved => 'Качество сохранено';

  @override
  String get skillEvalPrevious => 'Предыдущая и текущая версии';

  @override
  String get skillEvalRegressed => 'Регрессия подтверждена';

  @override
  String get skillEvalCostRegression => 'Регрессия стоимости';

  @override
  String get skillEvalHarnessError => 'Ошибка тестового окружения';

  @override
  String get skillBehaviorRouting => 'Маршрутизация навыка';

  @override
  String skillBehaviorRoutingCounts(
    String truePositive,
    String falsePositive,
    String falseNegative,
    String trueNegative,
  ) {
    return '$truePositive ожидаемых применений · $falsePositive неожиданных применений · $falseNegative пропущенных применений · $trueNegative верных пропусков';
  }

  @override
  String skillBehaviorUnknownCounts(
    String positive,
    String negative,
    String notOffered,
  ) {
    return '$positive неясных применений · $negative неясных пропусков · $notOffered не предлагался';
  }

  @override
  String skillBehaviorRoutingRates(
    String precision,
    String recall,
    String falsePositiveRate,
  ) {
    return 'Наблюдаемая точность $precision · полнота $recall · доля ложноположительных $falsePositiveRate';
  }

  @override
  String get skillBehaviorForced =>
      'Принудительная группа · только диагностика';

  @override
  String get skillBehaviorRoutingNote =>
      'Показатели учитывают только наблюдаемый доступ. Доступ через оболочку или поиск может остаться неизвестным; загрузка навыка не доказывает его применение.';

  @override
  String get skillBehaviorSafety => 'Синтетическая безопасность';

  @override
  String skillBehaviorSafetyCounts(
    String passes,
    String attempts,
    String denials,
    String violations,
  ) {
    return '$passes/$attempts успешных проверок артефактов · $denials отказов по правилам · $violations нарушений защиты файлов';
  }

  @override
  String get skillBehaviorSafetyNote =>
      'Проверки артефактов синтетические и не отражают частоту атак в реальных условиях; фактические побочные эффекты не отслеживаются.';

  @override
  String get skillBehaviorUtility => 'Польза по семействам';

  @override
  String skillBehaviorUtilityCounts(String verified, String attempts) {
    return '$verified/$attempts подтверждённых успехов';
  }

  @override
  String get skillBehaviorUtilityNote =>
      'В знаменатель пользы входят все попытки, включая неудачные и незавершённые.';

  @override
  String get claudeAccountSignInFailed => 'Не удалось войти';

  @override
  String get claudeSignInDialogTitle => 'Вход в Claude Code';

  @override
  String get claudeSignInDialogHint =>
      'Выполните каждую команду в терминале на сервере. Она откроет браузер для завершения входа и запишет учётные данные в каталог этого аккаунта.';

  @override
  String get claudeSignInNoAccounts =>
      'Ни один управляемый аккаунт не вышел из системы. Если этот агент использует собственный вход Claude Code, выполните:';

  @override
  String get claudeSignInCommandUnavailable =>
      'Сервер не смог предоставить команду входа для этого аккаунта.';

  @override
  String get claudeAccountSignedIn => 'Вход выполнен';

  @override
  String get claudeSignInClosesItself =>
      'Окно закроется автоматически после завершения входа.';

  @override
  String get claudeSignInClosesItselfAll =>
      'Окно закроется автоматически, когда все аккаунты войдут в систему.';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'Срок входа в Claude Code истёк';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'Запуск остановлен, потому что его аккаунт больше не проходит аутентификацию. Войдите снова, затем повторите ход.';

  @override
  String get transcriptSignInExpiredTitle => 'Срок входа к провайдеру истёк';

  @override
  String get transcriptSignInExpiredBody =>
      'Запуск остановлен, потому что учётные данные провайдера больше не работают. Переподключите его в Настройки → Провайдеры, затем повторите ход.';

  @override
  String get helpMenuLabel => 'Справка';

  @override
  String get helpWhatsNew => 'Что нового';

  @override
  String get helpReportProblem => 'Сообщить о проблеме';

  @override
  String get helpCreateGitHubIssue => 'Создать issue на GitHub';

  @override
  String get changelogInstalled => 'Установлена';

  @override
  String get changelogGroupNew => 'Новое';

  @override
  String get changelogGroupImproved => 'Улучшено';

  @override
  String get changelogGroupFixed => 'Исправлено';

  @override
  String get changelogLoadFailed =>
      'Не удалось загрузить примечания к выпуску.';

  @override
  String get changelogOpenWebsite => 'Открыть на сайте';

  @override
  String get connectWelcomeTitle => 'Добро пожаловать в Control Center';

  @override
  String get connectWelcomeSubtitle =>
      'Запустите его здесь или подключитесь к уже имеющемуся серверу.';

  @override
  String get connectWelcomeSubtitleWeb =>
      'Подключитесь к своему серверу, чтобы начать.';

  @override
  String get connectToServer => 'Подключиться к серверу';

  @override
  String get connectToServerIntro => 'Введите адрес сервера Control Center.';

  @override
  String get connectUsePairingKey => 'Использовать ключ сопряжения';

  @override
  String get connectPasteLink => 'Вставить ссылку сопряжения';

  @override
  String get connectPasteLinkIntro =>
      'Вставьте полученную ссылку-приглашение или ссылку сопряжения.';

  @override
  String get connectPasteLinkLabel =>
      'Ссылка-приглашение или ссылка сопряжения';

  @override
  String get connectPasteLinkInvalid =>
      'Это не ссылка-приглашение и не ссылка сопряжения Control Center. Скопируйте ссылку целиком и повторите попытку.';

  @override
  String get connectPasteLinkTarget => 'Подключение к';

  @override
  String get focusModeEnd => 'Завершить сеанс фокусировки';

  @override
  String focusModeRemaining(int minutes) {
    return 'Осталось $minutes мин';
  }

  @override
  String get demoUnavailableEnvironments =>
      'Окружения запускают настоящие процессы на хосте, поэтому в демо их нет.';

  @override
  String get environmentChecksFailing =>
      'Некоторые проверки на сервере не проходят';

  @override
  String environmentCliEndpoints(String names) {
    return 'Конечные точки: $names';
  }

  @override
  String environmentCliServices(String names) {
    return 'Сервисы: $names';
  }

  @override
  String get environmentCopied => 'Скопировано';

  @override
  String get environmentCopyCommand => 'Копировать команду';

  @override
  String get environmentCopyUrl => 'Копировать URL';

  @override
  String get environmentDefinition => 'Определение';

  @override
  String environmentDefinitionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count определения',
      many: '$count определений',
      few: '$count определения',
      one: '1 определение',
    );
    return '$_temp0';
  }

  @override
  String get environmentDestroy => 'Уничтожить';

  @override
  String environmentDestroyBody(String name) {
    return '$name и его данные будут удалены. Запуск создаст новое.';
  }

  @override
  String get environmentDestroyTitle => 'Уничтожить это окружение?';

  @override
  String get environmentExec => 'Exec';

  @override
  String get environmentExecTitle => 'Выполнить в сервисе';

  @override
  String environmentExitCode(int code) {
    return 'Код выхода $code';
  }

  @override
  String get environmentInputNeeded => 'Это нужно настроить на сервере';

  @override
  String get environmentKindApp => 'Приложение';

  @override
  String get environmentKindCli => 'CLI';

  @override
  String get environmentKindCompose => 'Compose';

  @override
  String get environmentKindProcess => 'Процесс';

  @override
  String get environmentKindTask => 'Задача';

  @override
  String get environmentLaunch => 'Открыть';

  @override
  String get environmentLogsGone => 'Эти логи больше недоступны.';

  @override
  String environmentLogsTab(String name) {
    return 'Логи: $name';
  }

  @override
  String get environmentLogsWaiting => 'Ожидание вывода';

  @override
  String get environmentMoreActions => 'Другие действия с окружением';

  @override
  String get environmentNeedsRecreate =>
      'Из-за изменения это окружение нужно пересоздать.';

  @override
  String get environmentNoStack =>
      'Выполняет только задачи worktree, поэтому запускать нечего.';

  @override
  String get environmentOnTheServer => 'На сервере';

  @override
  String get environmentOpenInBrowserVm => 'Открыть в Browser (VM)';

  @override
  String get environmentOpenViewer => 'Открыть просмотр';

  @override
  String get environmentPlacementRig => 'В ВМ';

  @override
  String get environmentPreviewTab => 'Окружение';

  @override
  String get environmentRebuildRelaunch => 'Пересобрать и перезапустить';

  @override
  String get environmentRecreate => 'Пересоздать';

  @override
  String environmentRecreateBody(String name) {
    return '$name будет уничтожено и запущено снова с теми же параметрами. Его данные будут потеряны.';
  }

  @override
  String get environmentRecreateTitle => 'Пересоздать это окружение?';

  @override
  String environmentResetBody(String name) {
    return '$name вернётся к исходному состоянию. Данные, созданные с тех пор, будут потеряны.';
  }

  @override
  String get environmentResetData => 'Сбросить данные';

  @override
  String get environmentResetTitle => 'Сбросить данные?';

  @override
  String get environmentRestart => 'Перезапустить';

  @override
  String environmentRestarts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count перезапуска',
      many: '$count перезапусков',
      few: '$count перезапуска',
      one: '1 перезапуск',
    );
    return '$_temp0';
  }

  @override
  String get environmentRun => 'Выполнить';

  @override
  String get environmentRunInTerminal => 'Выполнить в терминале';

  @override
  String get environmentSectionTitle => 'Окружение';

  @override
  String get environmentService => 'Сервис';

  @override
  String environmentServiceActions(String name) {
    return 'Действия для $name';
  }

  @override
  String get environmentStartTitle => 'Запустить окружение';

  @override
  String get environmentStateCrashed => 'Сбой';

  @override
  String get environmentStatusDegraded => 'Деградировало';

  @override
  String get environmentStatusDestroying => 'Уничтожается';

  @override
  String get environmentStatusGone => 'Удалено';

  @override
  String get environmentStatusStopping => 'Останавливается';

  @override
  String environmentStopDataLoss(String name) {
    return 'При остановке $name потеряет свои данные, и запуск их не вернёт.';
  }

  @override
  String get environmentStopLoseData => 'Остановить и потерять данные';

  @override
  String get environmentStopTitle => 'Остановить это окружение?';

  @override
  String get environmentTaskNeverRun => 'Ещё не запускалась';

  @override
  String get environmentsAddCheck => 'Добавить проверку';

  @override
  String get environmentsAddOption => 'Добавить параметр';

  @override
  String get environmentsAddRole => 'Добавить роль';

  @override
  String get environmentsAdminOnly =>
      'Менять определения могут только администраторы рабочего пространства.';

  @override
  String get environmentsAfter => 'Ждать эти компоненты';

  @override
  String get environmentsAnchor => 'Якорь';

  @override
  String get environmentsAutoCreate => 'Запускать автоматически';

  @override
  String get environmentsAutoCreateAll => 'В каждом подходящем пространстве';

  @override
  String get environmentsAutoCreateOff => 'Никогда';

  @override
  String get environmentsAutoCreatePrs => 'В пространствах pull request';

  @override
  String get environmentsBlank => 'Пустое определение';

  @override
  String get environmentsCheckFix => 'Команда исправления';

  @override
  String get environmentsCheckHint => 'Подсказка';

  @override
  String get environmentsCommandHelp =>
      'Аргументы разделяются пробелами. Аргумент с пробелом заключите в кавычки.';

  @override
  String environmentsComponentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count компонента',
      many: '$count компонентов',
      few: '$count компонента',
      one: '1 компонент',
    );
    return '$_temp0';
  }

  @override
  String get environmentsComponentId => 'ID';

  @override
  String get environmentsComposeBuild => 'Собирать образы при запуске';

  @override
  String get environmentsComposeFile => 'Файл compose';

  @override
  String get environmentsComposeHttp => 'HTTP';

  @override
  String get environmentsComposeNoFile =>
      'Не удалось прочитать файл compose. Имена сервисов всё ещё можно указать в режиме JSON.';

  @override
  String get environmentsComposeServices => 'Сервисы';

  @override
  String get environmentsComposeServicesHint =>
      'Оставьте все сервисы неотмеченными, чтобы запустить их все.';

  @override
  String get environmentsConditionalArgs =>
      'У этой команды есть условные аргументы. Измените её в режиме JSON.';

  @override
  String get environmentsCwdPath => 'Рабочий путь';

  @override
  String get environmentsCwdRole => 'Рабочая роль';

  @override
  String get environmentsDeleteBody =>
      'Пространства больше не смогут его запускать. Работающие окружения продолжат работу до остановки.';

  @override
  String environmentsDeleteTitle(String name) {
    return 'Удалить $name?';
  }

  @override
  String get environmentsDescription =>
      'Что может запускать каждое пространство и какие задачи выполняют его worktree.';

  @override
  String get environmentsDraftFromRepo => 'Черновик из репозитория';

  @override
  String get environmentsEmpty => 'Определений пока нет';

  @override
  String get environmentsEnabledWhen => 'Включено, когда';

  @override
  String get environmentsEndpointRole => 'Роль конечной точки';

  @override
  String get environmentsFollowPrHead => 'Следовать за head pull request';

  @override
  String get environmentsForkApproval => 'Каждый запуск требует администратора';

  @override
  String get environmentsForkDeny => 'Запрещено';

  @override
  String get environmentsForkPrs => 'Pull request из форков';

  @override
  String get environmentsForkRig => 'Запускать в ВМ';

  @override
  String get environmentsIdleStop => 'Останавливать после минут простоя';

  @override
  String get environmentsIsolateHome =>
      'Дать приложению личный домашний каталог';

  @override
  String get environmentsIssues => 'Исправьте это перед сохранением';

  @override
  String environmentsJsonInvalid(String error) {
    return 'Недопустимый JSON: $error';
  }

  @override
  String get environmentsKeepsData => 'Сохраняет данные при остановке';

  @override
  String get environmentsLinkConfirm => 'Связать и одобрить';

  @override
  String get environmentsLinkFile => 'Связать файл репозитория';

  @override
  String get environmentsLinkHelp =>
      'Читается только из ветки по умолчанию и запускается только после одобрения.';

  @override
  String get environmentsLinkPath => 'Путь';

  @override
  String get environmentsMaxRunning => 'Одновременно запущено';

  @override
  String get environmentsNamingProject => 'Проект';

  @override
  String get environmentsNamingTemplate => 'Шаблон имени';

  @override
  String get environmentsNew => 'Новое определение';

  @override
  String get environmentsNewDefinitionName => 'Новое окружение';

  @override
  String get environmentsNoChecks => 'В этом определении нет проверок.';

  @override
  String get environmentsNoRuns => 'Тестовых запусков пока нет';

  @override
  String get environmentsOnChange => 'Отслеживаемые пути';

  @override
  String get environmentsOptionBool => 'Да или нет';

  @override
  String get environmentsOptionEnum => 'Один из';

  @override
  String get environmentsOptionMulti => 'Несколько из';

  @override
  String get environmentsOptionValues => 'Значения';

  @override
  String get environmentsPlacement => 'Размещение';

  @override
  String get environmentsPlacementHost => 'На хосте';

  @override
  String get environmentsPlacementRig => 'В ВМ';

  @override
  String get environmentsPrepareTask => 'Подготовительная задача';

  @override
  String get environmentsPrimaryEndpoint => 'Основная конечная точка';

  @override
  String get environmentsReadyHttp => 'Готово, когда этот URL отвечает';

  @override
  String get environmentsRestartAlways => 'Всегда';

  @override
  String get environmentsRestartNever => 'Никогда';

  @override
  String get environmentsRestartOn => 'Перезапускать при изменении этих путей';

  @override
  String get environmentsRestartOnFailure => 'При сбое';

  @override
  String get environmentsRestartPolicy => 'Перезапустить';

  @override
  String get environmentsRigTtl => 'Время жизни ВМ в часах';

  @override
  String get environmentsRunChecks => 'Запустить снова';

  @override
  String get environmentsRunTest => 'Запустить тест';

  @override
  String get environmentsSaved => 'Определение сохранено';

  @override
  String get environmentsSectionComponents => 'Компоненты';

  @override
  String get environmentsSectionOptions => 'Параметры запуска';

  @override
  String get environmentsSectionSeedFiles => 'Начальные файлы';

  @override
  String get environmentsSectionVariables => 'Переменные';

  @override
  String get environmentsSeedHelp =>
      'Один путь в строке, копируется из зарегистрированного checkout. Pull request из форков их никогда не получают.';

  @override
  String get environmentsShellHelp =>
      'Заполнители здесь не раскрываются. Вместо них читайте переменные CC_ENV_*.';

  @override
  String get environmentsSourceApprove => 'Одобрить эту версию';

  @override
  String environmentsSourceCurrent(String path) {
    return '$path совпадает с одобренной версией.';
  }

  @override
  String get environmentsSourceNotice =>
      'Одобренная версия продолжает работать, пока вы не одобрите эту.';

  @override
  String get environmentsTabJson => 'JSON';

  @override
  String get environmentsTabSource => 'Источник';

  @override
  String get environmentsTestHelp =>
      'Запускает одноразовое окружение от начала до конца: проверка, запуск, ожидание готовности, уничтожение.';

  @override
  String get environmentsTestSaveFirst => 'Сначала сохраните определение.';

  @override
  String get environmentsTimeoutSeconds => 'Тайм-аут в секундах';

  @override
  String get environmentsTitle => 'Окружения';

  @override
  String get environmentsTriggerArchive => 'Перед удалением worktree';

  @override
  String get environmentsTriggerChange => 'При изменении отслеживаемых путей';

  @override
  String get environmentsTriggerCreate => 'Один раз на окружение';

  @override
  String get environmentsTriggerManual => 'По запросу';

  @override
  String get environmentsTriggerProvision => 'При создании worktree';

  @override
  String get environmentsTriggerStart => 'При каждом запуске';

  @override
  String get environmentsTriggers => 'Запускается';

  @override
  String get environmentsUnreadable =>
      'Этот клиент не может прочитать определение.';

  @override
  String get environmentsUpdateAvailable => 'Доступно обновление';

  @override
  String get environmentsUseShell => 'Использовать команду оболочки';

  @override
  String get environmentsUseSourceWarning =>
      'Инструмент будет работать с вашим собственным checkout. Считайте его доступным только для чтения.';

  @override
  String get environmentsWhenMissing => 'Когда в пространстве этого нет';

  @override
  String get environmentsWhenMissingAdd => 'Добавить в пространство';

  @override
  String get environmentsWhenMissingSkip => 'Пропустить';

  @override
  String get environmentsWhenMissingSource =>
      'Использовать зарегистрированный checkout';

  @override
  String get environmentsUnsupported =>
      'Этот сервер не поддерживает окружения.';

  @override
  String get environmentViewerUnavailable =>
      'Нет просмотра: сервер не может захватить это окно. Разрешите Control Center запись экрана на сервере.';

  @override
  String get environmentHealthHealthy => 'Исправен';

  @override
  String get environmentHealthUnhealthy => 'Неисправен';

  @override
  String get environmentTerminalStale =>
      'Этот терминал открыт до запуска окружения, поэтому в нём нет его переменных.';

  @override
  String get environmentTerminalFresh => 'Открыть новый терминал';

  @override
  String get environmentsShellStays =>
      'Многострочный скрипт остаётся командой оболочки: строки — это его структура.';

  @override
  String get environmentsOverrides => 'Переопределения рабочего пространства';

  @override
  String get environmentsOverridesHelp =>
      'Собственные настройки файла здесь только для чтения. Привяжите его роли к репозиториям этого рабочего пространства или переопределите любое поле в JSON.';

  @override
  String get environmentsReposHelp =>
      'Репозитории, которые использует это окружение, каждый привязан к роли.';

  @override
  String get environmentsComponentsHelp =>
      'Что запускает окружение, в порядке старта.';

  @override
  String get environmentsOptionsHelp =>
      'Варианты, предлагаемые при запуске окружения.';

  @override
  String get environmentsVariablesHelp =>
      'Задаются для задач, процессов, приложений и терминалов пространства.';

  @override
  String get environmentsChecksHelp =>
      'Что нужно хосту для работы этого окружения.';

  @override
  String get environmentsIdleStopHelp => 'При 0 никогда не останавливается.';

  @override
  String get environmentsAnchorHelp =>
      'Пространство с этим репозиторием может запустить окружение.';

  @override
  String get environmentsRequiredHelp => 'Без него окружение не запустится.';

  @override
  String get environmentsFollowPrHeadHelp =>
      'Синхронизировать и обновлять при смещении head pull request.';

  @override
  String get environmentsRecordNeedsFix => 'Нужно исправить';

  @override
  String get environmentsCheckFile => 'Файл';

  @override
  String get environmentsDiscardBody =>
      'Ваши изменения этого определения будут потеряны.';

  @override
  String get environmentsWorktreeRuns => 'Запуски задач worktree';

  @override
  String get environmentsNoWorktreeRuns =>
      'Задачи worktree ещё не запускались.';

  @override
  String get environmentsLinkRoles => 'Роли в этом файле';

  @override
  String get environmentsLinkNoFile =>
      'Не удалось прочитать файл из репозитория. Роли можно привязать после связывания.';

  @override
  String get guardrailClassHostExecution => 'Выполнение команд на хосте';

  @override
  String get environmentUrls => 'URL-адреса';

  @override
  String get environmentScripts => 'Скрипты';

  @override
  String get environmentNoneForSpace => 'У этого пространства нет окружения';

  @override
  String get environmentNoneForPr => 'У этого pull request нет окружения';

  @override
  String get environmentSetupBody =>
      'Окружение запускает сервисы, скрипты и URL-адреса репозитория для одного пространства. Настройте его один раз, и любое пространство этого репозитория сможет его запустить.';

  @override
  String get environmentSetUp => 'Настроить окружение';

  @override
  String get environmentEditDefinition => 'Изменить определение';

  @override
  String get environmentOpenPanel => 'Открыть окружение';

  @override
  String get environmentStatusBlocked => 'Нужны ваши действия';

  @override
  String get environmentStateInTerminal => 'В терминале';

  @override
  String get environmentWaitingInTerminal => 'Ждёт вас в терминале';

  @override
  String get environmentOpenTerminal => 'Открыть терминал';

  @override
  String get environmentSignInNeeded => 'Нужно войти в аккаунт';

  @override
  String get environmentDependencyNeeded => 'Нужный компонент недоступен';

  @override
  String get environmentStartTerminalDone =>
      'Готово здесь. Окружение ещё запускается';

  @override
  String get environmentContinueInTerminal => 'Продолжить в терминале';

  @override
  String get environmentStartTerminalHint =>
      'Инструменту нужен ввод в терминале: пароль или ответ на вопрос. После этого запуск продолжится.';

  @override
  String get environmentStartTerminalReason =>
      'Этот терминал открыт, потому что для запуска нужны ваши действия';

  @override
  String get environmentStartTerminalTab => 'Настройка окружения';

  @override
  String get environmentsNothingRunning =>
      'Из этого определения ничего не запущено.';

  @override
  String get searchPoliciesHint => 'Поиск политик...';

  @override
  String get noPoliciesMatch => 'Нет политик, соответствующих запросу';

  @override
  String get memoryPolicyActive => 'Активна';

  @override
  String get memoryFactType => 'Тип';

  @override
  String get memoryTimesRecalled => 'Число обращений';

  @override
  String get memorySourceFacts => 'Исходные факты';

  @override
  String get spaceSetupLogs => 'Журналы настройки';

  @override
  String get claudeCompactionTitle => 'Сжатие';

  @override
  String get claudeCompactionDescription =>
      'Как Claude Code удерживает длинные беседы в пределах контекстного окна.';

  @override
  String get claudeAutoCompactLabel => 'Автоматически сжимать после';

  @override
  String claudeAutoCompactHint(String min, String max) {
    return 'Токены, от $min до $max. Оставьте пустым, чтобы использовать значение Claude Code по умолчанию.';
  }

  @override
  String claudeAutoCompactInvalid(String min, String max) {
    return 'Введите число от $min до $max.';
  }

  @override
  String get claudeIdleCompactLabel => 'Сжимать неактивные беседы';

  @override
  String claudeIdleCompactDescription(String threshold) {
    return 'Сжимает беседу длиннее $threshold токенов незадолго до истечения кеша промпта, чтобы возвращение к ней стоило дешевле. Каждое сжатие расходует ваш тариф.';
  }

  @override
  String get claudeCompactionSaveFailed =>
      'Не удалось сохранить этот параметр.';

  @override
  String get navDesktopApp => 'Приложение для компьютера';

  @override
  String get desktopAppSettingsSubtitle =>
      'Значок в трее, закрытие окна и открытие при входе в систему.';

  @override
  String get desktopSectionMenuBar => 'Строка меню';

  @override
  String get desktopSectionTray => 'Системный трей';

  @override
  String get desktopTrayTitleMac => 'Показывать в строке меню';

  @override
  String get desktopTrayTitle => 'Показывать в системном трее';

  @override
  String get desktopTraySubtitle =>
      'Статус, всё, что ждёт вас, ваши пространства и использование подписки — в один клик.';

  @override
  String get desktopTrayMissingTitle => 'Системный трей не найден';

  @override
  String get desktopTrayMissingBody =>
      'Это окружение рабочего стола не показывает значки в трее. В GNOME установите расширение AppIndicator, затем перезапустите Control Center.';

  @override
  String get desktopSectionClosing => 'Закрытие окна';

  @override
  String get desktopCloseTitle => 'При закрытии окна';

  @override
  String get desktopCloseKeepRunning => 'Продолжить работу';

  @override
  String get desktopCloseQuit => 'Завершить';

  @override
  String get desktopCloseKeepRunningSubtitleMac =>
      'Агенты и уведомления продолжают работать. Снова откройте окно из Dock или строки меню.';

  @override
  String get desktopCloseKeepRunningSubtitle =>
      'Агенты и уведомления продолжают работать. Снова откройте окно с помощью значка в трее.';

  @override
  String get desktopCloseQuitSubtitle =>
      'Закрытие окна завершает Control Center. Уведомления не приходят, пока вы снова его не откроете.';

  @override
  String get desktopCloseNeedsTray =>
      'Включите значок в трее, чтобы Control Center продолжал работать с закрытым окном.';

  @override
  String get desktopSectionLogin => 'Запуск';

  @override
  String get desktopLoginTitle => 'Открывать при входе';

  @override
  String get desktopLoginSubtitle =>
      'Запускать Control Center при входе в систему, чтобы уведомления приходили с самого начала.';

  @override
  String get desktopLoginUnsupported =>
      'Эта система не поддерживает открытие приложений при входе.';

  @override
  String get desktopLoginNeedsApproval =>
      'Разрешите Control Center в разделе «Объекты входа», чтобы завершить включение.';

  @override
  String get desktopLoginOpenLoginItems => 'Открыть «Объекты входа»';

  @override
  String get desktopLoginRefused =>
      'Система не приняла изменение. Возможно, им управляет ваш администратор.';

  @override
  String get desktopLoginStartHiddenTitle => 'Запускать в фоне';

  @override
  String get desktopLoginStartHiddenSubtitleMac =>
      'При входе открывается без окна. Найдите его в Dock или строке меню.';

  @override
  String get desktopLoginStartHiddenSubtitle =>
      'При входе открывается без окна. Найдите его в трее.';

  @override
  String get desktopLoginStartHiddenNeedsTray =>
      'Нужен значок в трее, чтобы было как открыть окно.';

  @override
  String get closeToTrayPromptTitle => 'Оставить Control Center работать?';

  @override
  String get closeToTrayPromptBody =>
      'Когда окно закрыто, агенты продолжают работать, а уведомления продолжают приходить. Снова откройте его с помощью значка в трее. Это можно изменить в «Настройки → Приложение для компьютера».';

  @override
  String get closeToTrayPromptQuit => 'Завершить';

  @override
  String get closeToTrayPromptKeepRunning => 'Продолжить работу';

  @override
  String get trayStatusOffline => 'Офлайн';

  @override
  String get trayStatusReconnecting => 'Переподключение…';

  @override
  String trayStatusNeedsYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ждут вас',
      many: '$count ждут вас',
      few: '$count ждут вас',
      one: '$count ждёт вас',
    );
    return '$_temp0';
  }

  @override
  String trayStatusWorking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count работают',
      many: '$count работают',
      few: '$count работают',
      one: '$count работает',
    );
    return '$_temp0';
  }

  @override
  String get trayStatusAllQuiet => 'Всё спокойно';

  @override
  String trayTooltip(String status) {
    return 'Control Center · $status';
  }

  @override
  String trayMenuSpaceQuestions(String space, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count вопроса',
      many: '$count вопросов',
      few: '$count вопроса',
      one: '$count вопрос',
    );
    return '$space · $_temp0';
  }

  @override
  String trayApprovalsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count действия ждут подтверждения',
      many: '$count действий ждут подтверждения',
      few: '$count действия ждут подтверждения',
      one: '$count действие ждёт подтверждения',
    );
    return '$_temp0';
  }

  @override
  String get trayMenuOpen => 'Открыть Control Center';

  @override
  String get trayMenuSettings => 'Настройки…';

  @override
  String get trayMenuQuit => 'Завершить Control Center';

  @override
  String get trayPanelTitle => 'Control Center';

  @override
  String get trayPanelNoWorkspace =>
      'Откройте Control Center, чтобы выбрать рабочее пространство.';

  @override
  String get trayPanelOpenApp => 'Открыть Control Center';

  @override
  String get trayPanelSettings => 'Настройки приложения для компьютера';

  @override
  String get trayPanelNeedsYou => 'Ждут вас';

  @override
  String get trayPanelApprovals => 'Подтверждения';

  @override
  String get trayPanelSpaces => 'Пространства';

  @override
  String get trayPanelNoSpaces => 'Пространств пока нет.';

  @override
  String trayPanelAllSpaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Все $count пространства',
      many: 'Все $count пространств',
      few: 'Все $count пространства',
      one: 'Все пространства',
    );
    return '$_temp0';
  }

  @override
  String get trayPanelUsage => 'Использование';

  @override
  String get trayPanelSwitchWorkspace => 'Сменить рабочее пространство';

  @override
  String signInToProvider(String provider) {
    return 'Войти в $provider';
  }

  @override
  String get linearConnectAutomation => 'Подключить Linear для автоматизации';

  @override
  String signInOpeningBrowser(String provider) {
    return 'Открываем $provider в браузере…';
  }

  @override
  String get signInFailedTitle => 'Вход не завершён';

  @override
  String get signInReopenPage => 'Снова открыть страницу входа';

  @override
  String get signInCodePrompt =>
      'Подтвердите в браузере, затем введите показанный код.';

  @override
  String get signInCodeMalformed =>
      'Это не похоже на код входа. Коды состоят из 8 букв и цифр.';

  @override
  String get signInCodeDeepLinkHint =>
      'Если браузер предложит открыть Control Center, разрешите — тогда код вводить не придётся.';

  @override
  String signInSucceeded(String provider, String account) {
    return 'Выполнен вход в $provider как $account';
  }

  @override
  String signInSucceededNoAccount(String provider) {
    return 'Выполнен вход в $provider';
  }

  @override
  String get signInErrorExpired => 'Время входа истекло. Начните заново.';

  @override
  String signInErrorAccessDenied(String provider) {
    return 'Вход в $provider отменён или отклонён.';
  }

  @override
  String signInErrorScopeMismatch(String provider) {
    return '$provider выдал меньше разрешений, чем нужно Control Center. Войдите снова и подтвердите все разрешения.';
  }

  @override
  String get signInErrorInvalidCode =>
      'Этот код не подходит к этому входу. Проверьте его и попробуйте снова.';

  @override
  String get signInErrorTooManyCodes =>
      'Слишком много неверных кодов. Начните вход заново.';

  @override
  String get signInErrorStaleRequest =>
      'Этот вход больше не открыт: его отменили, использовали или заменили. Начните заново.';

  @override
  String get signInErrorInvalidRequest =>
      'Серверу не удалось прочитать этот запрос на вход. Начните его заново.';

  @override
  String get signInErrorRateLimited =>
      'Сейчас слишком много запросов. Подождите немного и попробуйте снова.';

  @override
  String signInErrorStoreFailed(String provider) {
    return '$provider принял вход, но сервер не смог его сохранить. Попробуйте снова.';
  }

  @override
  String signInErrorProviderUnavailable(String provider) {
    return '$provider сейчас не отвечает. Попробуйте через несколько минут.';
  }

  @override
  String signInErrorExchangeFailed(String provider) {
    return '$provider принял вход, но сервер не смог его завершить. Попробуйте снова.';
  }

  @override
  String signInErrorMisconfigured(String provider) {
    return 'Приложение $provider на этом сервере настроено неверно. Попросите владельца сервера проверить Настройки → Сервер → Единый вход.';
  }

  @override
  String signInErrorNeedsSignIn(String provider) {
    return 'Ваш вход в $provider истёк. Войдите снова, чтобы продолжить работать от своего имени.';
  }

  @override
  String signInErrorNotInstalled(String provider) {
    return 'Приложение $provider не установлено там, где оно нужно. Установите его и попробуйте снова.';
  }

  @override
  String get signInErrorTeamBoundElsewhere =>
      'Это рабочее пространство Slack уже подключено к другому серверу Control Center.';

  @override
  String get signInErrorNotAdmin =>
      'Впервые подключить рабочее пространство Slack к Control Center может только его администратор или владелец. Попросите кого-то из них добавить приложение.';

  @override
  String signInErrorSuspended(String provider) {
    return 'Приложение $provider приостановлено. Возобновите его в $provider и попробуйте снова.';
  }

  @override
  String get signInErrorInstallBlocked =>
      'Control Center Connect заблокировал этот сервер. Свяжитесь с оператором вашего сервера Connect.';

  @override
  String get signInErrorUnknown =>
      'Вход не удался по причине, которую сервер не сообщил. Попробуйте снова.';

  @override
  String get signInPhishingTitle => 'Вход начат не здесь';

  @override
  String get signInPhishingBody =>
      'Этот вход был начат не из этого приложения. Если кто-то прислал вам эту ссылку, не продолжайте.';

  @override
  String get signInPhishingDetail =>
      'Ничего не отправлено. Завершив вход, начатый кем-то другим, вы привязали бы свой аккаунт к его серверу.';

  @override
  String signInRequiredTitle(String provider) {
    return 'Нужен вход в $provider';
  }

  @override
  String signInRequiredBody(String provider) {
    return 'Это действие выполняется от вашего имени в $provider, а вы не вошли. Войдите и попробуйте снова.';
  }

  @override
  String signInRequiredBanner(String provider) {
    return 'Вы не вошли в $provider. Всё, что вы здесь делаете, выполняется от вашего имени, поэтому сначала войдите.';
  }

  @override
  String signInUnavailable(String provider) {
    return 'Вход в $provider на этом сервере ещё не настроен.';
  }

  @override
  String get githubInstallations => 'Установки приложения GitHub';

  @override
  String get githubInstallationsDescription =>
      'Где установлено приложение GitHub — среди аккаунтов, которым принадлежат репозитории этого рабочего пространства.';

  @override
  String get githubInstallationsEmpty =>
      'Приложение GitHub не установлено ни в одном аккаунте, которому принадлежат репозитории этого рабочего пространства.';

  @override
  String get githubInstallApp => 'Установить приложение GitHub';

  @override
  String get githubInstallationSuspended => 'Приостановлена';

  @override
  String get linearAutomationTitle => 'Автоматизация Linear';

  @override
  String get linearAutomationHint =>
      'Позволяет агентам и конвейерам этого рабочего пространства действовать в Linear как приложение, а не как человек. Подключают его администраторы пространства.';

  @override
  String linearAutomationConnectedAs(String account) {
    return 'Подключено к $account';
  }

  @override
  String get connectModeHosted => 'Использовать приложения Control Center';

  @override
  String get connectModeHostedDisclosure =>
      'Входы проходят через Control Center Connect. Connect запечатывает каждый вход так, что открыть его может только этот сервер, выпускает токены GitHub с доступом к одному репозиторию, не хранит ключей от репозиториев и никогда не получает ваш исходный код.';

  @override
  String get connectModeOwn => 'Использовать свои приложения';

  @override
  String get connectModeOwnHint =>
      'Зарегистрируйте приложения GitHub, Google и Linear сами в разделе Настройки → Сервер → Единый вход, а собственное приложение Slack каждого рабочего пространства подключите в разделе Рабочее пространство → Интеграции, где рабочее пространство также может выбрать свои приложения или Connect. «Создать моё приложение GitHub» настраивает GitHub в один шаг.';

  @override
  String get connectModeCustom => 'Использовать свой сервер Connect';

  @override
  String get connectModeCustomHint =>
      'Ваша организация держит собственный сервер Connect. Входы идут туда, а не на сервер Control Center.';

  @override
  String get connectModeUnset => 'Ещё не настроено';

  @override
  String get connectCustomUrlLabel => 'URL сервера Connect';

  @override
  String get connectCustomUrlInvalid =>
      'Введите HTTPS-адрес, например https://connect.example.com.';

  @override
  String get connectCustomUrlLoopbackHint =>
      'Обычный HTTP доходит только до Connect на этом компьютере. Для всего в сети используйте HTTPS.';

  @override
  String get connectErrorHostedUnprovisioned =>
      'Размещённые приложения Control Center пока недоступны в этой сборке. Используйте свои приложения или свой сервер Connect.';

  @override
  String get connectErrorSignature =>
      'Конфигурация Connect не прошла проверку подписи. Входы через Connect приостановлены, пока она снова не пройдёт проверку.';

  @override
  String get connectErrorRollback =>
      'Connect выдал более старую конфигурацию, чем этот сервер уже видел, поэтому она отклонена. Входы через Connect приостановлены.';

  @override
  String get connectErrorUnreachable =>
      'Этот сервер сейчас не может связаться с Connect. Входы через него будут завершаться ошибкой, пока связь не восстановится.';

  @override
  String get connectErrorInstallBlocked =>
      'Connect заблокировал идентификатор установки этого сервера. Свяжитесь с оператором вашего сервера Connect.';

  @override
  String get connectErrorPinsChanged => 'Приложения Connect изменились';

  @override
  String get connectErrorProtocol =>
      'Connect ответил так, что этот сервер его не понимает. Обновите сервер или проверьте URL Connect.';

  @override
  String get connectErrorUnknown =>
      'Connect сообщил о проблеме без пояснений. Запустите проверку, чтобы повторить попытку.';

  @override
  String get connectPinsConfirmHint =>
      'Ваш сервер Connect теперь указывает другие приложения GitHub, Google, Linear или Slack, чем те, что этот сервер закрепил при первом использовании. Доверяйте им, только если оператор заранее вас об этом предупредил.';

  @override
  String get connectConfirmPins => 'Доверять новым приложениям';

  @override
  String get connectStale =>
      'Используемая конфигурация старее ожидаемой. Запустите проверку, чтобы обновить её.';

  @override
  String get connectLaneSourceOwn => 'Своё приложение';

  @override
  String get connectLaneSourceConnect => 'Connect';

  @override
  String get connectLaneSourceOff => 'Выкл.';

  @override
  String get connectTitle => 'Control Center Connect';

  @override
  String get connectDescription =>
      'Чьи приложения этот сервер использует для GitHub, Google Calendar, Linear, Slack и поиска GIF.';

  @override
  String get connectFactMode => 'Приложения для входа';

  @override
  String get connectFactHealth => 'Состояние';

  @override
  String get connectFactEpoch => 'Версия конфигурации';

  @override
  String get connectHealthOff => 'Не используется';

  @override
  String get connectHealthOk => 'Работает';

  @override
  String get connectHealthDown => 'Не работает';

  @override
  String get connectLocked =>
      'Это задаёт CC_CONNECT_URL в окружении сервера. Измените значение там и перезапустите сервер.';

  @override
  String get connectLanesTitle => 'Где выполняется каждый вход';

  @override
  String get connectLanesDescription =>
      'Собственное приложение всегда важнее Connect для своего провайдера.';

  @override
  String get connectServerGroup => 'Этот сервер';

  @override
  String get connectInstallId => 'Идентификатор установки';

  @override
  String get connectInstallIdHint =>
      'Идентифицирует этот сервер в Connect. Сообщите его владельцу организации или оператору Connect, если они попросят.';

  @override
  String get connectInstallIdEmpty =>
      'Назначается, когда этот сервер впервые использует Connect.';

  @override
  String get connectTestOk => 'Connect работает.';

  @override
  String get connectRotateKey => 'Сменить ключ';

  @override
  String get connectRotateKeyTitle => 'Сменить ключ Connect этого сервера?';

  @override
  String get connectRotateKeyBody =>
      'Сервер получит новый ключ и новый идентификатор установки, а старый идентификатор выводится из обращения в Connect: входы, зашифрованные под ним, и старый ключ там перестают работать, поэтому все, кто входил через Connect, должны войти снова. Уже выданные токены работают до истечения срока. Входы через ваши собственные приложения не затрагиваются. Если Connect недоступен, ничего не меняется, и вы можете попробовать снова.';

  @override
  String get connectRotateKeyDone =>
      'Ключ сменён. Всем, кто входил через Connect, нужно войти снова.';

  @override
  String get connectCliLabel => 'Из терминала';

  @override
  String get onboardingStepSignIn => 'Вход';

  @override
  String get onboardingConnectTitle => 'Выберите, как люди будут входить';

  @override
  String get onboardingConnectSubtitle =>
      'Control Center работает с GitHub, Google Calendar, Linear, Slack и поиском GIF через приложения, зарегистрированные у каждого провайдера. Выберите, чьи приложения использует этот сервер. Это можно изменить позже в разделе Настройки → Сервер → Единый вход.';

  @override
  String get onboardingConnectOwnNext =>
      'Создайте приложение GitHub для этого сервера сейчас или добавьте свои приложения позже в разделе Настройки → Сервер → Единый вход.';

  @override
  String get providerServiceApiKey => 'Сервисный ключ API';

  @override
  String get providerAppPartial => 'Настройка не завершена';

  @override
  String providerAppMissingFields(String fields) {
    return 'Ещё не хватает: $fields. Пока не заполнены все поля, входы для этого провайдера отклоняются, а не перенаправляются через Connect.';
  }

  @override
  String get providerAppsGroupSignInLinearDescription =>
      'Идентификатор клиента выполняет вход участников. Сервисный ключ API позволяет этому серверу самостоятельно читать и записывать данные в Linear.';

  @override
  String get providerCallbackUrls => 'URL обратного вызова';

  @override
  String get providerCallbackUrlHint =>
      'Зарегистрируйте его у провайдера точно в таком виде.';

  @override
  String get providerAppCreateGitHubTitle => 'Создать приложение GitHub';

  @override
  String get providerAppCreateGitHubHint =>
      'GitHub регистрирует приложение с нужными разрешениями и адресом обратного вызова, а затем передаёт его учётные данные этому серверу. Ничего не нужно копировать вручную.';

  @override
  String get providerAppCreateGitHub => 'Создать моё приложение GitHub';

  @override
  String get providerAppCreateGitHubOrg => 'Организация (необязательно)';

  @override
  String get providerAppCreateGitHubOrgHint =>
      'Оставьте пустым, чтобы создать приложение в своём аккаунте GitHub. Создать его в организации может только её владелец.';

  @override
  String get providerAppSignInReady => 'Пользователи могут входить.';

  @override
  String get chatLinkWaiting => 'Ждём ваше личное сообщение…';

  @override
  String chatLinkClaimTitle(String provider) {
    return 'Это ваш аккаунт $provider?';
  }

  @override
  String chatLinkClaimBody(String provider) {
    return 'Этот аккаунт отправил ваш код боту. Подтверждайте, только если он ваш: после привязки всё, что он отправляет в $provider, будет действовать от вашего имени в этом рабочем пространстве.';
  }

  @override
  String get chatLinkDecline => 'Отклонить';

  @override
  String chatLinkDeclined(String provider) {
    return 'Ничего не привязано. Получите новый код, если всё ещё хотите привязать аккаунт $provider.';
  }

  @override
  String get chatLinkNewCode => 'Получить новый код';

  @override
  String signInAddControlCenter(String provider) {
    return 'Добавить Control Center в $provider';
  }

  @override
  String signInAddedControlCenter(String workspace) {
    return 'Control Center добавлен в $workspace';
  }

  @override
  String chatSharedAppHint(String provider) {
    return 'Устанавливает общее приложение Control Center в ваше рабочее пространство $provider. Не нужно создавать приложение или вставлять токен.';
  }

  @override
  String chatAddToProvider(String provider) {
    return 'Добавить в $provider';
  }

  @override
  String get chatSharedAppConnected =>
      'Работает через общее приложение Control Center, поэтому здесь нет токенов и настроек бота.';

  @override
  String get chatTicketDraftsTitle => 'Черновики тикетов из чата';

  @override
  String get chatTicketDraftsDescription =>
      'Черновик становится тикетом в бэклоге, только когда вы создаёте его здесь. Оставленные черновики удаляются через сутки.';

  @override
  String chatTicketDraftFrom(String provider) {
    return 'Из $provider';
  }

  @override
  String get chatTicketDraftCreate => 'Создать тикет';

  @override
  String chatTicketDraftCreated(String key) {
    return 'Создан $key';
  }

  @override
  String workspaceProviderAppMissingFields(String fields) {
    return 'Ещё не заполнено: $fields. Пока не заданы все поля, провайдер в этом рабочем пространстве отключён. Он не переходит на приложение этого сервера.';
  }

  @override
  String get workspaceProviderAppClientChangeHint =>
      'При смене приложения все в этом рабочем пространстве выходят из него. Войти снова нужно через новое приложение.';

  @override
  String get workspaceProviderAppKlipyKey => 'Ключ приложения';

  @override
  String get workspaceProviderAppKlipyHint =>
      'Поиск GIF в этом рабочем пространстве использует этот ключ.';

  @override
  String get settingsWorkspaceIntegrations => 'Интеграции';

  @override
  String get settingsWorkspaceIntegrationsDescription =>
      'Хостинг кода, задачи, календарь, чат и поиск GIF в этом рабочем пространстве, а также приложения, через которые в них выполняется вход.';

  @override
  String get workspaceConnectDescription =>
      'Какие приложения это рабочее пространство использует для GitHub, Google Календаря, Linear, Slack и поиска GIF. Если администратор не выберет иное, оно следует за этим сервером.';

  @override
  String get workspaceConnectModeInherit => 'Как на этом сервере';

  @override
  String get workspaceConnectInheritHosted =>
      'Этот сервер использует приложения Control Center.';

  @override
  String workspaceConnectInheritCustom(String url) {
    return 'Этот сервер использует сервер Connect по адресу $url.';
  }

  @override
  String get workspaceConnectInheritOwn =>
      'Этот сервер использует свои приложения.';

  @override
  String get workspaceConnectInheritUnset =>
      'Владелец сервера ещё не выбрал вариант, поэтому действуют собственные приложения сервера.';

  @override
  String get workspaceConnectOwnHint =>
      'Используются только приложения этого рабочего пространства. Добавьте каждое из них ниже, рядом с его провайдером. Провайдер без приложения здесь отключён; вместо него не используются ни приложения этого сервера, ни Connect.';

  @override
  String get workspaceConnectCustomUrlHint =>
      'Только HTTPS. Адреса в частной или локальной сети отклоняются.';

  @override
  String get workspaceConnectLocked =>
      'CC_CONNECT_URL в окружении этого сервера определяет, куда направляются входы, поэтому это рабочее пространство не может выбрать собственный Connect. Оно может следовать за этим сервером или использовать свои приложения.';

  @override
  String get workspaceConnectSwitchTitle =>
      'Сменить приложения для входа в этом рабочем пространстве?';

  @override
  String get workspaceConnectSwitchBody =>
      'Всем участникам рабочего пространства придётся заново войти в GitHub, Linear и Google Календарь через новые приложения. Входы, выполненные через текущие приложения, здесь перестанут работать.';

  @override
  String get workspaceConnectSwitchAction => 'Сменить приложения';

  @override
  String get workspaceConnectLanesDescription =>
      'Следует выбору выше. Провайдер никогда не переключается на другое приложение.';

  @override
  String get workspaceConnectLaneWorkspaceOwn =>
      'Приложение рабочего пространства';

  @override
  String get workspaceConnectLaneServerOwn => 'Приложение сервера';

  @override
  String get workspaceGitHubAppTitle => 'Приложение GitHub';

  @override
  String get workspaceGitHubAppOwnDescription =>
      'Собственное приложение этого рабочего пространства действует от имени его репозиториев и выполняет вход участников. Оно никогда не переключается на приложение этого сервера или на Connect.';

  @override
  String get workspaceGitHubAppSharedDescription =>
      'Это рабочее пространство использует GitHub App, которое предоставляют его приложения для входа. Установите его на аккаунты, которым принадлежат ваши репозитории.';

  @override
  String get workspaceGitHubAppActingTitle =>
      'Действует от имени этого рабочего пространства';

  @override
  String get workspaceGitHubAppActingDescription =>
      'Бот приложения комментирует, рецензирует и опрашивает pull request-ы в репозиториях этого рабочего пространства.';

  @override
  String workspaceOwnAppTitle(String provider) {
    return 'Приложение $provider';
  }

  @override
  String workspaceOwnAppDescription(String provider) {
    return 'Входы и запросы $provider в этом рабочем пространстве используют только это приложение.';
  }

  @override
  String get workspaceGifsTitle => 'GIF';

  @override
  String get workspaceGifsSourceWorkspaceOwn =>
      'Поиск GIF использует ключ Klipy этого рабочего пространства.';

  @override
  String get workspaceGifsSourceServerOwn =>
      'Поиск GIF использует ключ Klipy этого сервера.';

  @override
  String get workspaceGifsSourceConnect =>
      'Поиск GIF работает через Control Center Connect.';

  @override
  String get workspaceGifsSourceOff =>
      'Поиск GIF отключён в этом рабочем пространстве.';

  @override
  String openOnForge(String forge) {
    return 'Открыть в $forge';
  }

  @override
  String prFilesTruncatedNotice(String forge, int count) {
    return 'Показаны первые $count файлов. $forge не выводит остальные.';
  }

  @override
  String get connectForgeToLoadPrs =>
      'Подключите хостинг кода, чтобы загрузить pull request’ы';

  @override
  String get connectForgeHint =>
      'Подключите GitHub, GitLab или Bitbucket в разделе Настройки → Вы → Профиль';

  @override
  String get addForgeRepoPrompt =>
      'Добавьте хотя бы один репозиторий на GitHub, GitLab или Bitbucket, чтобы видеть pull request’ы';

  @override
  String get composePrNoForgeRepo => 'Не выбран размещённый репозиторий';

  @override
  String get composePrNoForgeRepoHint =>
      'Выберите рабочее пространство с репозиторием на GitHub, GitLab или Bitbucket, чтобы открыть pull request.';

  @override
  String composePrForgeNotConnected(String forge) {
    return 'Подключите $forge, чтобы открыть pull request в этом репозитории';
  }

  @override
  String connectionNeedsSignInAs(String provider, String account) {
    return 'Ваш вход в $provider как $account истёк. Войдите снова.';
  }

  @override
  String get connectionPaused =>
      'Приостановлено: служба входа этого рабочего пространства изменилась';

  @override
  String connectionUnreachable(String provider) {
    return 'Сейчас не удаётся связаться с $provider. Повторяем попытку.';
  }

  @override
  String get forgeSignInBannerPausedBody =>
      'Ваш вход сохранён и снова заработает, когда служба вернётся. Администратор рабочего пространства может проверить настройку входа в разделе «Интеграции».';

  @override
  String get signInErrorAttemptUnknown =>
      'Сервер перезапустился. Начните вход заново.';

  @override
  String signInUnavailableNotConfigured(String provider) {
    return 'Вход через $provider не настроен для этого рабочего пространства.';
  }

  @override
  String signInUnavailableMisconfigured(String provider, String error) {
    return 'Вход через $provider настроен неверно: $error';
  }

  @override
  String signInUnavailableOwnAppMissing(String provider) {
    return 'Это рабочее пространство использует собственные приложения, но приложения для $provider у него нет.';
  }

  @override
  String signInUnavailableConnectUnprovisioned(String provider) {
    return 'Эта сборка не может проверить Control Center Connect, поэтому вход через $provider отключён.';
  }

  @override
  String get signInUnavailableConnectPinsPending =>
      'Служба входа этого рабочего пространства сменила идентификацию. Администратор должен это подтвердить.';

  @override
  String get signInUnavailableConnectUnreachable =>
      'Сейчас не удаётся связаться со службой входа этого рабочего пространства.';

  @override
  String get signInUnavailableConnectUrlInvalid =>
      'Адрес службы входа этого рабочего пространства не указан или неверен.';

  @override
  String get signInUnavailableBlockedByEnvironment =>
      'Оператор сервера закрепил службу входа, поэтому выбор этого рабочего пространства не действует.';

  @override
  String signInUnavailableLaneNotOffered(String provider) {
    return 'Служба входа этого рабочего пространства не поддерживает $provider.';
  }

  @override
  String get signInOpenIntegrations => 'Открыть интеграции';

  @override
  String get signInOpenServerSettings => 'Открыть настройки входа';

  @override
  String forgeTokenRequiredBody(String provider) {
    return 'Это выполняется от вашего имени в $provider, а токен не добавлен. Добавьте его и повторите попытку.';
  }

  @override
  String disconnectProviderTitle(String provider) {
    return 'Отключить $provider?';
  }

  @override
  String disconnectProviderBody(String provider) {
    return 'Чтобы работать с репозиториями $provider, его нужно будет подключить снова.';
  }

  @override
  String disconnectScopeWorkspaceBody(String provider) {
    return '$provider отключится только в этом рабочем пространстве. Другие рабочие пространства сохранят своё подключение.';
  }

  @override
  String disconnectScopeGlobalBody(String provider) {
    return '$provider отключится во всех рабочих пространствах, которые используют это подключение.';
  }

  @override
  String disconnectedFromWorkspace(String provider) {
    return '$provider отключён от этого рабочего пространства';
  }

  @override
  String disconnectedFromAllWorkspaces(String provider) {
    return '$provider отключён от всех рабочих пространств';
  }

  @override
  String repoAccessInstallTitle(String owner) {
    return 'Установите GitHub App в $owner';
  }

  @override
  String repoAccessInstallBody(String repos) {
    return 'Автоматизация не получит доступ к $repos, пока там не установлено приложение.';
  }

  @override
  String repoAccessSelectTitle(String repos) {
    return 'Добавьте $repos в репозитории GitHub App';
  }

  @override
  String get repoAccessSelectBody =>
      'Приложение установлено в этом аккаунте, но пока не видит эти репозитории.';

  @override
  String get repoAccessChooseRepos => 'Выбрать репозитории';

  @override
  String get repoAccessSuspendedTitle => 'Установка GitHub App приостановлена';

  @override
  String repoAccessSuspendedBody(String repos) {
    return 'Автоматизация для $repos приостановлена, пока владелец аккаунта не возобновит установку на GitHub.';
  }

  @override
  String get repoAccessAutomationPausedTitle => 'Автоматизация приостановлена';

  @override
  String repoAccessOwnerCannotSeeBody(String repos) {
    return 'Ответственный за автоматизацию этого рабочего пространства больше не видит $repos, поэтому там ничего не выполняется от его имени.';
  }

  @override
  String repoAccessOwnerNotSignedInBody(String repos) {
    return 'Ответственный за автоматизацию этого рабочего пространства не вошёл в forge, поэтому автоматизация для $repos ждёт его входа.';
  }

  @override
  String repoAccessTransient(String repos) {
    return 'Не удалось проверить доступ к $repos. Повторяем попытку.';
  }

  @override
  String repoAccessAskAdmins(String admins) {
    return 'Попросите исправить это: $admins.';
  }

  @override
  String get repoAccessAskAnAdmin =>
      'Попросите администратора рабочего пространства исправить это.';

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Войдите в $forge, чтобы видеть pull requests из других репозиториев: $count',
      one: 'Войдите в $forge, чтобы видеть pull requests ещё из 1 репозитория',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Скрыто репозиториев, которые не видит ваш аккаунт $forge: $count',
      one: '1 репозиторий скрыт, потому что ваш аккаунт $forge его не видит',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Скрыто репозиториев, к которым у вас нет доступа в этом рабочем пространстве: $count',
      one:
          '1 репозиторий скрыт, потому что у вас нет к нему доступа в этом рабочем пространстве',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Проверяем ваш доступ к другим репозиториям: $count…',
      one: 'Проверяем ваш доступ ещё к 1 репозиторию…',
    );
    return '$_temp0';
  }

  @override
  String get repoLinkAccessWarningsTitle =>
      'Связано, но автоматизация пока доступна не везде';

  @override
  String get githubInstallOnAnotherOrganization =>
      'Установить в другой организации';

  @override
  String get forgeTokenEmailLabel => 'Email аккаунта Atlassian';

  @override
  String get forgeTokenEmailInvalid =>
      'Введите адрес электронной почты вашего аккаунта Atlassian.';

  @override
  String get forgeTokenApiTokenLabel => 'API-токен';

  @override
  String get forgeTokenBitbucketHint =>
      'API-токены Bitbucket работают вместе с email аккаунта Atlassian, который их создал.';

  @override
  String get automationTokensTitle => 'Токены автоматизации';

  @override
  String get automationTokensRepoHint =>
      'Фоновая работа в GitLab и Bitbucket, например обновления pull request, комментарии ИИ-ревью и merge request, о которых никто не просил, использует токен доступа бота, а не человека. Собственный токен репозитория важнее токена рабочего пространства.';

  @override
  String get automationTokensWorkspaceHint =>
      'Используется для каждого репозитория GitLab или Bitbucket в этом рабочем пространстве без собственного токена автоматизации. Фоновая работа там отображается как бот этого токена.';

  @override
  String get automationTokenNone =>
      'Токена нет. Автоматизация здесь приостановлена.';

  @override
  String get automationTokenFromWorkspace =>
      'Использует токен рабочего пространства';

  @override
  String automationTokenActsAs(String name) {
    return 'Действует как $name';
  }

  @override
  String get automationTokenStored => 'Токен доступа добавлен';

  @override
  String get automationTokenRejected =>
      'Платформа отклонила этот токен. Замените его.';

  @override
  String automationTokenDialogTitle(String forge) {
    return 'Токен автоматизации $forge';
  }

  @override
  String get automationTokenGitLabHint =>
      'Вставьте токен доступа проекта или группы. Нужны read_api и read_repository; для комментариев, merge request и push добавьте api и write_repository. GitLab показывает его работу как бота токена.';

  @override
  String get automationTokenBitbucketHint =>
      'Вставьте токен доступа репозитория, проекта или рабочего пространства с чтением репозитория и записью pull request для комментариев и pull request. Ваш личный API-токен добавляется в разделе Вы → Профиль, а не здесь.';

  @override
  String automationTokenUnreadable(String repos) {
    return 'Токен сохранён, но не может читать $repos. Автоматизация там остаётся приостановленной.';
  }

  @override
  String get automationTokenRemoveTitle => 'Удалить токен автоматизации?';

  @override
  String get automationTokenRemoveBody =>
      'Автоматизация, зависящая от этого токена, приостановится, пока не будет добавлен другой.';

  @override
  String automationTokenWorkspaceTarget(String forge) {
    return 'Каждый репозиторий $forge без собственного токена';
  }

  @override
  String repoAccessAutomationTokenMissingBody(String repos) {
    return 'Ни один токен автоматизации не может читать $repos, поэтому фоновая работа там приостановлена.';
  }

  @override
  String get settingsCommitsDescription =>
      'Коммиты из работы, которую вы запускаете, несут ваше имя. Выберите, кто ещё указан как соавтор, и показывать ли forge ваши коммиты как проверенные.';

  @override
  String get settingsCommitAuthorshipSection => 'Авторство';

  @override
  String get settingsCommitAuthorshipYoursLabel =>
      'Работа, которую вы запускаете';

  @override
  String get settingsCommitAuthorshipYoursBody =>
      'Вы автор и committer под адресом электронной почты, которую forge подтвердил для вашего входа. Сюда относятся чаты с агентами, пайплайны, которые вы запускаете, и коммиты, которые вы делаете в редакторе.';

  @override
  String get settingsCommitAuthorshipBotLabel => 'Автоматические запуски';

  @override
  String get settingsCommitAuthorshipBotBody =>
      'Запуски по расписанию или по webhook коммитят от имени бота и никогда не подписываются.';

  @override
  String get settingsCommitAuthorshipSignInNote =>
      'Пока вы не войдёте в forge в рабочем пространстве, ваши запуски там коммитят от имени бота.';

  @override
  String get settingsCoauthorCreditTitle =>
      'Указывать Control Center соавтором';

  @override
  String get settingsCoauthorCreditDescription =>
      'Ваши коммиты указывают Control Center (@usectrl) как соавтора, а включённые вами автоматические запуски — вас. Если выключено, ни одна строка не добавляется.';

  @override
  String get settingsCoauthorCreditWorkspaceOverride =>
      'Настройка рабочего пространства имеет приоритет над вашим выбором. Ваше предпочтение сохранено, но здесь не действует.';

  @override
  String get settingsCoauthorCreditLoading => 'Загрузка настроек авторства…';

  @override
  String get settingsWorkspaceCoauthorCreditTitle => 'Указание соавторов';

  @override
  String get settingsWorkspaceCoauthorCreditDescription =>
      'Добавлять ли в коммиты строки соавторов: Control Center — в собственные коммиты участника, а участники, включившие автоматический запуск, — в его коммиты. Выбор здесь переопределяет настройку каждого участника.';

  @override
  String get settingsWorkspaceCoauthorCreditInherit =>
      'Использовать предпочтение каждого участника';

  @override
  String get settingsWorkspaceCoauthorCreditAlways =>
      'Всегда указывать соавтора';

  @override
  String get settingsWorkspaceCoauthorCreditNever =>
      'Никогда не указывать соавтора';

  @override
  String get settingsCommitSigningSection => 'Проверенные коммиты';

  @override
  String get settingsCommitSigningStatusOn => 'Подпись';

  @override
  String get settingsCommitSigningStatusOff => 'Без подписи';

  @override
  String get settingsCommitSigningIntro =>
      'Этот сервер может подписывать ваши коммиты вашим собственным ключом, поэтому GitHub и GitLab показывают их как проверенные. Ничего не подписывается, пока вы не создадите ключ.';

  @override
  String get settingsCommitSigningCreate => 'Создать ключ подписи';

  @override
  String get settingsCommitSigningCreated =>
      'Ключ подписи создан. Добавьте его в свой аккаунт forge.';

  @override
  String get settingsCommitSigningPublicKeyLabel => 'Открытый ключ';

  @override
  String get settingsCommitSigningKeyCopied => 'Открытый ключ скопирован';

  @override
  String get settingsCommitSigningFingerprintLabel => 'Отпечаток';

  @override
  String get settingsCommitSigningCreatedLabel => 'Создан';

  @override
  String get settingsCommitSigningAddTitle =>
      'Добавьте его в свой аккаунт forge';

  @override
  String get settingsCommitSigningAddDescription =>
      'Коммит отображается как проверенный, только пока вы также вошли в этот forge в рабочем пространстве: так forge подтверждает ваш адрес электронной почты.';

  @override
  String get settingsCommitSigningGitHubSteps =>
      'Settings → SSH and GPG keys → New SSH key. В поле Key type выберите Signing Key.';

  @override
  String get settingsCommitSigningGitLabSteps =>
      'Preferences → SSH Keys. В поле Usage type выберите Signing.';

  @override
  String get settingsCommitSigningBitbucketSteps =>
      'Коммиты на Bitbucket не подписываются. Не добавляйте этот ключ в свой аккаунт Bitbucket: SSH-ключ там также служит для входа.';

  @override
  String get settingsCommitSigningUnsupported => 'Не поддерживается';

  @override
  String get settingsCommitSigningTrustTitle => 'Чему вы доверяете';

  @override
  String get settingsCommitSigningTrustPrivate =>
      'Закрытый ключ никогда не покидает этот сервер.';

  @override
  String get settingsCommitSigningTrustControl =>
      'Тот, кто контролирует этот сервер, может подписывать коммиты от вашего имени, пока ключ находится в вашем аккаунте forge.';

  @override
  String get settingsCommitSigningTrustVerified =>
      'На GitHub коммиты, уже отмеченные как проверенные, остаются проверенными после удаления ключа.';

  @override
  String get settingsCommitSigningDelete => 'Удалить ключ';

  @override
  String get settingsCommitSigningDeleteTitle => 'Удалить ваш ключ подписи?';

  @override
  String get settingsCommitSigningDeleteBody =>
      'С этого момента ваши коммиты не подписываются. Ключ остаётся в ваших аккаунтах forge, пока вы не удалите его там.';

  @override
  String get settingsCommitSigningDeleted => 'Ключ подписи удалён';

  @override
  String settingsCommitSigningLoadFailed(String error) {
    return 'Не удалось загрузить ваш ключ подписи: $error';
  }

  @override
  String get accountProfileTitle => 'Профиль';

  @override
  String get accountProfileDescription =>
      'Кто вы в каждом рабочем пространстве и какие у вас есть собственные аккаунты для хостинга кода, тикетов, календаря и чата.';

  @override
  String get accountSectionTitle => 'Аккаунт';

  @override
  String get accountSectionDescription =>
      'Ваши имя пользователя и имя следуют за вами в каждое рабочее пространство. В рабочем пространстве может отображаться другое имя или адрес почты: задайте их в Рабочее пространство → Профиль и идентичность.';

  @override
  String accountLoadFailed(String error) {
    return 'Не удалось загрузить ваш профиль: $error';
  }

  @override
  String get accountDisplayNameHint =>
      'Имя, которое люди видят в ваших сообщениях и ревью.';

  @override
  String get accountDisplayNameRequired => 'Введите отображаемое имя.';

  @override
  String get accountFieldCannotBeCleared =>
      'Это можно изменить, но нельзя удалить.';

  @override
  String get accountAvatarLabel => 'Фото';

  @override
  String get accountAvatarHint =>
      'Ссылка на квадратное изображение, начинающаяся с https://.';

  @override
  String get accountAvatarInvalid =>
      'Используйте ссылку, начинающуюся с https://.';

  @override
  String get usernameLabel => 'Имя пользователя';

  @override
  String get usernameRule =>
      'От 2 до 32 строчных букв, цифр, точек, дефисов или подчёркиваний. По нему вас упоминают люди.';

  @override
  String get usernameAvailable => 'Доступно.';

  @override
  String usernameAvailableAs(String username) {
    return 'Доступно. Будет сохранено как $username.';
  }

  @override
  String get usernameInvalid =>
      'Используйте от 2 до 32 строчных букв, цифр, «.», «_» или «-», начиная и заканчивая буквой или цифрой.';

  @override
  String get usernameReserved => 'Это имя пользователя зарезервировано.';

  @override
  String get usernameTaken => 'Это имя пользователя уже занято.';

  @override
  String get usernameCheckFailed =>
      'Сейчас не удалось проверить это имя. Вы всё равно можете сохранить: решит сервер.';

  @override
  String get linkedAccountsTitle => 'Подключённые аккаунты';

  @override
  String get linkedAccountsIdentityProvider => 'Провайдер идентификации';

  @override
  String get linkedAccountStatusNeedsSignIn => 'Нужен вход';

  @override
  String get linkedAccountStatusPaused => 'Приостановлен';

  @override
  String get linkedAccountStatusUnreachable => 'Недоступен';

  @override
  String get ssoIdentityDescription =>
      'Поставщик удостоверений, через который входит ваш аккаунт. Управляет им тот, кто запускает этот сервер.';

  @override
  String get settingsAccountsDescription =>
      'Аккаунты, которые вы подключили для себя. Control Center действует от вашего имени через них, и изменения затрагивают только вас.';

  @override
  String get accountReachServer =>
      'Используется во всех рабочих пространствах этого сервера.';

  @override
  String accountReachWorkspace(String workspace) {
    return 'Используется только в $workspace.';
  }

  @override
  String forgeReachGitHubOwnApp(String workspace) {
    return 'GitHub используется только в $workspace, у которого есть собственные приложения для входа. GitLab и Bitbucket используются во всех рабочих пространствах этого сервера.';
  }

  @override
  String get yourAccountLabel => 'Ваш аккаунт';

  @override
  String yourAccountEntry(String provider, String detail) {
    return '$provider: $detail';
  }

  @override
  String yourAccountLineSemantics(String status) {
    return 'Ваш аккаунт: $status. Открывает Вы → Профиль.';
  }

  @override
  String get yourForgeAccountNone => 'Аккаунт для хостинга кода не подключён';

  @override
  String yourAccountNotConnected(String provider) {
    return 'Аккаунт $provider не подключён';
  }

  @override
  String yourChatAccountNotLinked(String provider) {
    return 'Аккаунт $provider не привязан';
  }

  @override
  String get demoUnavailableAccount =>
      'В демо вы временный гость, поэтому аккаунта для изменения нет: ни имени пользователя, ни профиля, ни подключённых аккаунтов.';

  @override
  String get onboardingStepYou => 'Вы';

  @override
  String get onboardingYouTitle => 'Выберите имя пользователя';

  @override
  String get onboardingYouSubtitle =>
      'Имя пользователя — это то, как вас упоминают люди и как подписывается ваша работа. Позже вы сможете изменить его и отображаемое имя в Настройки → Вы → Профиль.';

  @override
  String signInErrorAccountAlreadyBound(String provider) {
    return 'Этот аккаунт $provider уже подключён к другому человеку на этом сервере. Войдите с другим аккаунтом $provider.';
  }

  @override
  String forgeTokenExpiresOn(String date) {
    return 'Токен истекает $date';
  }

  @override
  String forgeTokenExpiredOn(String date) {
    return 'Срок действия токена истёк $date. Вставьте новый, чтобы продолжить работу.';
  }

  @override
  String personTokenUnreachable(String forge) {
    return 'Не удалось связаться с $forge, чтобы проверить этот токен. Попробуйте ещё раз немного позже.';
  }

  @override
  String personTokenRejected(String forge) {
    return '$forge не принимает этот токен. Проверьте, что вы скопировали его целиком и что он не был отозван.';
  }

  @override
  String personTokenWrongKind(String forge) {
    return 'Это не личный токен. Вставьте личный токен доступа из своего аккаунта $forge, а не токен проекта, группы, рабочего пространства или бота.';
  }

  @override
  String personTokenNarrowScope(String scope) {
    return 'В этом токене не хватает области $scope, которая нужна для ревью и комментариев. Создайте токен с ней.';
  }

  @override
  String get personTokenExpired =>
      'Срок действия этого токена истёк. Создайте новый и вставьте его сюда.';

  @override
  String get settingsCommitSigningTrustAgents =>
      'Запущенные вами агенты могут делать коммиты, подписанные от вашего имени, в любом репозитории, с которым они работают. Удаление ключа здесь сразу это останавливает: уже идущие запуски ничего больше не подписывают.';

  @override
  String connectRotateKeyFailed(String error) {
    return 'Ключ не был заменён, и ничего не изменилось: $error Попробуйте ещё раз.';
  }

  @override
  String get noWorkspaceInviteTitle => 'Вы пока не в рабочем пространстве';

  @override
  String get noWorkspaceInviteBody =>
      'Администратор рабочего пространства должен пригласить вас, или владелец сервера может создать для вас рабочее пространство. Оно откроется здесь, как только вас добавят.';

  @override
  String noWorkspaceSignedInAs(String name) {
    return 'Вход выполнен как $name';
  }

  @override
  String get noWorkspaceCheckAgain => 'Проверить снова';

  @override
  String get noWorkspaceSignOut => 'Выйти';

  @override
  String get workspaceCreateOwnerOnly =>
      'Только владелец сервера может создавать рабочие пространства. Попросите его создать одно или попросите администратора рабочего пространства пригласить вас.';

  @override
  String repoLinkNoWorkspaceToAddTo(String repo) {
    return '$repo не входит ни в одно из ваших рабочих пространств, а вы не состоите в рабочем пространстве, куда его можно добавить. Попросите администратора рабочего пространства пригласить вас.';
  }

  @override
  String get serverOwnerOnly => 'Это может сделать только владелец сервера';

  @override
  String get ideCodeServerOwnerOnlyHint =>
      'Полный редактор работает на машине сервера, поэтому открыть его может только владелец сервера. Файлы в Проводнике вы по-прежнему можете открывать и редактировать.';

  @override
  String get terminalSandboxedBadge => 'В песочнице';

  @override
  String get terminalSandboxedHint =>
      'Работает в песочнице внутри папок этого рабочего пространства, поэтому некоторые инструменты и пути хоста здесь недоступны.';

  @override
  String get terminalHostShellOwnerOnly =>
      'Оболочка хоста работает на сервере без песочницы, поэтому открыть её может только владелец сервера. Обычный терминал работает в песочнице.';

  @override
  String get terminalOutsideWorkspace =>
      'Терминал можно открыть только внутри собственных папок этого рабочего пространства.';

  @override
  String get environmentHostOwnerOnly =>
      'Только владелец сервера может сохранять или одобрять окружение, которое работает на хосте сервера. Администратор рабочего пространства может использовать окружение, которое работает в риге.';

  @override
  String get settingsCommitsNoHooks =>
      'Коммиты, которые вы делаете в собственном редакторе приложения, не запускают Git-хуки из репозитория, как и git commit --no-verify: сервер запускает Git на своём хосте, в дереве, которое могут менять агенты и пул-реквесты.';

  @override
  String get mcpTokenDescription =>
      'MCP-клиенты отправляют этот токен с каждым запросом в заголовке Authorization: Bearer. Сервер создаёт его при первом запуске; его можно перевыпустить, но нельзя удалить.';

  @override
  String get mcpShowToken => 'Показать токен';

  @override
  String get mcpHideToken => 'Скрыть токен';

  @override
  String get mcpRotateToken => 'Перевыпустить токен';

  @override
  String get mcpRotateTokenTitle => 'Перевыпустить токен MCP?';

  @override
  String get mcpRotateTokenBody =>
      'Сервер сразу переключится на новый токен. Каждый MCP-клиент, который ещё использует текущий, будет отклонён, пока вы не передадите ему новый.';

  @override
  String get mcpTokenRotated =>
      'Токен перевыпущен. Передайте новый вашим MCP-клиентам.';

  @override
  String get mcpOwnerOnlyTitle =>
      'MCP-эндпоинт предназначен для владельца сервера';

  @override
  String get mcpOwnerOnlyBody =>
      'Его токен открывает все инструменты на этом сервере, поэтому только владелец сервера может видеть его, перевыпускать, а также запускать и останавливать эндпоинт.';

  @override
  String get activityRotatedMcpToken => 'Перевыпустил токен MCP';

  @override
  String get connectRotateKeyRetireFailedTitle =>
      'Connect не смог вывести старый ключ из обращения';

  @override
  String get connectRotateKeyForceBody =>
      'Ничего не изменилось. Если вы всё равно перевыпустите ключ, этот сервер получит новый, но старый идентификатор останется рабочим в этом Connect, пока не истекут его входы.';

  @override
  String get connectRotateKeyAnyway => 'Всё равно перевыпустить';

  @override
  String get settingsAuditLog => 'Журнал аудита';

  @override
  String get settingsAuditLogDescription =>
      'Кто что изменил, где и чем это закончилось, на уровне сервера и во всех рабочих пространствах, которыми вы управляете. Серверные операции записывают имена аргументов, но не их значения.';

  @override
  String get auditLogNoAccessTitle => 'Только для администраторов';

  @override
  String get auditLogNoAccess =>
      'Журнал аудита охватывает сервер и рабочие пространства, которыми вы управляете. У вас нет прав администратора ни в одном рабочем пространстве, поэтому показывать нечего.';

  @override
  String get auditLogSourceServer => 'Сервер';

  @override
  String get auditLogSourceWorkspace => 'Рабочее пространство';

  @override
  String get auditLogAddFilter => 'Фильтр';

  @override
  String get auditLogFilterOptionsHint => 'Фильтр…';

  @override
  String get auditLogFilterActor => 'Пользователь';

  @override
  String get auditLogFilterSource => 'Рабочее пространство';

  @override
  String get auditLogFilterOutcome => 'Результат';

  @override
  String get auditLogFilterTime => 'Время';

  @override
  String auditLogFilterChip(String category, String values) {
    return '$category: $values';
  }

  @override
  String auditLogFilterChipMore(String values, int count) {
    return '$values +$count';
  }

  @override
  String get auditLogOutcomeOk => 'Выполнено';

  @override
  String get auditLogOutcomeDenied => 'Отказано';

  @override
  String get auditLogOutcomeFailed => 'Сбой';

  @override
  String get auditLogTimeAtOrAfter => 'Не раньше';

  @override
  String get auditLogTimeAfter => 'После';

  @override
  String get auditLogTimeBefore => 'До';

  @override
  String get auditLogTimeAtOrBefore => 'Не позже';

  @override
  String auditLogTimeChip(String operator, String time) {
    return 'Время $operator $time';
  }

  @override
  String get auditLogTimePresetHour => '1 час назад';

  @override
  String get auditLogTimePresetDay => '24 часа назад';

  @override
  String get auditLogTimePresetWeek => '7 дней назад';

  @override
  String get auditLogTimePresetMonth => '30 дней назад';

  @override
  String get auditLogTimeExact => 'Точное время';

  @override
  String get auditLogTimeInvalid =>
      'Введите YYYY-MM-DD, при необходимости с HH:MM';

  @override
  String get auditLogTimeAdd => 'Добавить';

  @override
  String repoAccessReplacedTitle(String repo) {
    return '$repo теперь указывает на другой репозиторий';
  }

  @override
  String repoAccessReplacedBody(String forge) {
    return 'Этот путь теперь указывает на другой репозиторий на $forge. Переподключите его, чтобы продолжить работу.';
  }

  @override
  String get repoRelink => 'Переподключить';

  @override
  String repoRelinked(String repo) {
    return 'Переподключено: $repo.';
  }

  @override
  String get repoCodeRepoReplaced =>
      'Этот путь теперь указывает на другой репозиторий. Администратор рабочего пространства должен переподключить его, прежде чем его можно будет использовать.';

  @override
  String repoCodeForgeCannotRead(String forge) {
    return 'Ваш аккаунт $forge не может читать этот репозиторий.';
  }

  @override
  String repoCodeForgeUnconfirmed(String forge) {
    return 'Не удалось подтвердить ваш доступ к $forge. Попробуйте ещё раз.';
  }

  @override
  String get repoCodeForgeCannotReadUnnamed =>
      'Ваш аккаунт forge не может читать этот репозиторий.';

  @override
  String get repoCodeForgeUnconfirmedUnnamed =>
      'Не удалось подтвердить ваш доступ к forge. Попробуйте ещё раз.';

  @override
  String get repoPathHostPath =>
      'Только владелец сервера может подключить папку вне хранилища этого рабочего пространства.';

  @override
  String get repoPathMissing => 'По этому пути на сервере ничего нет.';

  @override
  String get repoPathDataDir =>
      'Репозиторий не может указывать в папку данных сервера.';

  @override
  String get repoPathWorkspaceRoot =>
      'Репозиторий не может быть самой папкой рабочего пространства.';

  @override
  String get repoPathOriginMismatch =>
      'Origin этой папки — другой репозиторий.';

  @override
  String repoGrantNeedsSignIn(String forge) {
    return 'Сохранено. Им нужно войти в $forge, прежде чем они смогут открыть этот репозиторий.';
  }

  @override
  String repoGrantCannotRead(String forge) {
    return 'Сохранено. Их аккаунт $forge пока не может читать этот репозиторий, поэтому он остаётся для них скрытым.';
  }

  @override
  String repoGrantUnconfirmed(String forge) {
    return 'Сохранено. Сейчас не удалось подтвердить их доступ к $forge.';
  }

  @override
  String repoLinkAskOwnerToAdd(String repo) {
    return '$repo не подключён ни в одном из ваших рабочих пространств. Попросите владельца сервера добавить его.';
  }

  @override
  String get reposEmptyAskOwner =>
      'Репозитории из папок сервера добавляет владелец сервера.';

  @override
  String get accountEmailUnconfirmedHint =>
      'Этот адрес ввели только вы. Единый вход не будет его сопоставлять, пока владелец сервера его не подтвердит.';

  @override
  String get settingsServerPeople => 'Люди';

  @override
  String get settingsServerPeopleDescription =>
      'Все, у кого есть аккаунт на этом сервере, и подтверждён ли их адрес электронной почты.';

  @override
  String get serverPeopleLabel => 'Аккаунты';

  @override
  String get serverPeopleOwnerOnly =>
      'Только владелец сервера может видеть аккаунты всех и подтверждать адреса электронной почты.';

  @override
  String get serverPeopleEmailNotConfirmed => 'Почта не подтверждена';

  @override
  String get serverPeopleConfirmEmail => 'Подтвердить почту';

  @override
  String serverPeopleConfirmEmailBody(String email, String name) {
    return 'Подтвердить, что $email принадлежит $name? Единый вход будет сопоставлять этот адрес с их аккаунтом.';
  }

  @override
  String serverPeopleEmailConfirmed(String email) {
    return 'Подтверждено: $email.';
  }

  @override
  String get runSandboxUnavailableTitle =>
      'Агентам нужна песочница на этом сервере';

  @override
  String get runSandboxUnavailable =>
      'На этом сервере нет песочницы, поэтому агентов здесь может запускать только его владелец. Владелец может установить песочницу или отключить её для всех.';

  @override
  String get repoPathIssueHostPath =>
      'Эта папка находится вне хранилища рабочего пространства. Подтвердите, что этот сервер может её использовать.';

  @override
  String get repoPathIssueHostPathAskOwner =>
      'Эта папка находится вне хранилища рабочего пространства. Подтвердить её может только владелец сервера.';

  @override
  String get repoPathIssueMissing =>
      'По этому пути на сервере больше ничего нет. Удалите этот репозиторий и добавьте его снова из текущей папки.';

  @override
  String get repoPathIssueUnusable =>
      'Эту папку нельзя использовать как репозиторий. Удалите её и добавьте репозиторий из другой папки.';

  @override
  String get repoPathConfirm => 'Подтвердить';

  @override
  String get repoPathConfirmAll => 'Подтвердить все';

  @override
  String repoPathConfirmAllTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count папки находятся вне хранилища рабочего пространства',
      many: '$count папок находятся вне хранилища рабочего пространства',
      few: '$count папки находятся вне хранилища рабочего пространства',
      one: '$count папка находится вне хранилища рабочего пространства',
    );
    return '$_temp0';
  }

  @override
  String get repoPathConfirmAllBody =>
      'Подтвердите, что этот сервер может их использовать. Каждый репозиторий снова проверяется с вашим доступом.';

  @override
  String repoCodeNeedsSignIn(String provider) {
    return 'Войдите в $provider, чтобы увидеть код этого репозитория.';
  }

  @override
  String get repoCodeSignIn => 'Войти';

  @override
  String get ideContentSearchFailed => 'Не удалось выполнить поиск по файлам';

  @override
  String get ideWorktreeFileUnavailable =>
      'Этот файл недоступен в этом рабочем дереве.';

  @override
  String get ideChangesLoadFailed => 'Не удалось загрузить изменения';

  @override
  String repoCodeRepoReplacedOn(String forge) {
    return 'Этот путь теперь указывает на другой репозиторий на $forge. Администратор рабочего пространства должен переподключить его, прежде чем его можно будет использовать.';
  }

  @override
  String get backupRestoreServerOwnerOnly =>
      'Только владелец сервера может восстанавливать резервные копии. Скачивать их вы можете по-прежнему.';

  @override
  String get terminalReadOnlyBadge => 'Только чтение';

  @override
  String get terminalReadOnlyHint =>
      'Вы можете наблюдать за этим терминалом. Ввод в него, изменение размера и остановка требуют права записи в каждый репозиторий этого разговора.';

  @override
  String get environmentOperateNeedsWrite =>
      'Вы можете наблюдать за этим окружением. Запуск, остановка или перезапуск требуют права записи в каждый репозиторий этого разговора.';

  @override
  String get environmentHostApprovalOwner =>
      'Запускается на этом сервере. Одобрите, чтобы оно могло стартовать.';

  @override
  String get environmentHostApprovalMember =>
      'Запускается на этом сервере. Владелец сервера должен его одобрить, прежде чем оно сможет стартовать.';

  @override
  String get environmentHostApprove => 'Одобрить';

  @override
  String get environmentHostApproveNeedsAdmin =>
      'Одобрите как администратор рабочего пространства: только копия администратора показывает секретные значения, а одобрение сохраняет их обратно.';

  @override
  String get environmentHostUnapproved =>
      'Владелец сервера ещё не одобрил это окружение, поэтому оно не может работать на этом сервере.';

  @override
  String get environmentHostUnapprovedOwner =>
      'Вы ещё не одобрили это окружение. Оно работает на этом сервере, поэтому запустится, когда вы одобрите его определение.';

  @override
  String get environmentHostApprovalReview => 'Проверить и одобрить';

  @override
  String spaceAccessNeedsSignIn(String provider) {
    return 'Войдите в $provider, чтобы открыть это пространство.';
  }

  @override
  String spaceAccessForgeCannotRead(String forge) {
    return 'Ваш аккаунт $forge не может читать один из репозиториев, которые использует это пространство.';
  }

  @override
  String get spaceAccessForgeCannotReadUnnamed =>
      'Ваш аккаунт forge не может читать один из репозиториев, которые использует это пространство.';

  @override
  String get spaceAccessNoGrant =>
      'У вас нет доступа на чтение к одному из репозиториев, которые использует это пространство. Администратор рабочего пространства может его предоставить.';

  @override
  String get spaceAccessFailed => 'Не удалось открыть это пространство.';

  @override
  String get contextExplorerRefused =>
      'Разбивка контекста недоступна в этой сессии.';

  @override
  String get repoLinkForgeRemoteRequired =>
      'Подключённому репозиторию нужны и владелец, и имя репозитория.';

  @override
  String get repoCodeNoReadGrant =>
      'У вас нет доступа на чтение к этому репозиторию. Администратор рабочего пространства может его предоставить.';

  @override
  String get repoCodeNoWriteGrant =>
      'Вы можете читать этот репозиторий, но не можете его изменять. Администратор рабочего пространства может предоставить доступ на запись.';

  @override
  String get repoCodeNoReviewGrant =>
      'Вы можете читать этот репозиторий, но не можете его проверять. Администратор рабочего пространства может предоставить доступ на проверку.';

  @override
  String get rigWatchOnlyBadge => 'Только просмотр';

  @override
  String get rigWatchOnlyHint =>
      'Вы можете смотреть на эту машину. Управление ею, проброс её портов, вставка в неё и перетаскивание на неё файлов требуют доступа на запись ко всем репозиториям этого пространства.';

  @override
  String get rigStartNeedsWrite =>
      'Чтобы запустить машину здесь, нужен доступ на запись ко всем репозиториям этого пространства. Администратор рабочего пространства может его предоставить.';

  @override
  String get rigViewRefused =>
      'Вы не можете просмотреть эту машину. Она принадлежит пространству, на чтение которого у вас нет доступа.';

  @override
  String get rigPortsWatchOnly =>
      'Изменение этих портов требует доступа на запись ко всем репозиториям этого пространства.';

  @override
  String get rigHolderOnly =>
      'Управлять этой машиной может только тот, для кого её открыли. Она использует его собственные входы в сервисы.';

  @override
  String get rigHolderOnlyHint =>
      'Вы можете смотреть на эту машину. Она использует входы в сервисы того, для кого её открыли, поэтому только он может управлять ею, пробрасывать её порты, вставлять в неё данные или перетаскивать на неё файлы.';

  @override
  String get refusalStorageBusy =>
      'База данных сервера сейчас занята. Повторите попытку через минуту.';

  @override
  String get refusalStorageFull =>
      'На сервере закончилось место на диске, поэтому ничего нельзя сохранить. Владельцу сервера нужно освободить место.';

  @override
  String get refusalStorageDamaged =>
      'Данные этого рабочего пространства повреждены. Владелец сервера должен восстановить их из резервной копии.';

  @override
  String get refusalStorageReadOnly =>
      'Это рабочее пространство доступно только для чтения, пока владелец сервера не восстановит его из резервной копии, поэтому изменения сохранить нельзя.';

  @override
  String get refusalStorageNewerSchema =>
      'Эти данные записаны более новой версией сервера. Обновите сервер и повторите попытку.';

  @override
  String get refusalStorageForeignFile =>
      'Сервер нашёл файл базы данных, который он не записывал. Владельцу сервера нужно проверить папку данных сервера.';

  @override
  String get refusalWorkspaceDeleted => 'Это рабочее пространство удалено.';

  @override
  String get refusalIdempotencyInProgress =>
      'Этот запрос ещё обрабатывается. Дождитесь завершения, затем проверьте результат.';

  @override
  String get refusalImportMissingSource =>
      'На сервере нет файла по этому пути. Ничего не заменено.';

  @override
  String get refusalImportDamaged =>
      'Этот файл повреждён, поэтому его нельзя восстановить. Ничего не заменено.';

  @override
  String get refusalImportChecksumMismatch =>
      'Контрольная сумма этого файла не совпадает с записанной в резервной копии, поэтому файл мог быть изменён или повреждён. Ничего не заменено.';

  @override
  String get refusalImportNewerSchema =>
      'Этот файл записан более новой версией сервера. Обновите сервер, чтобы восстановить его. Ничего не заменено.';

  @override
  String get refusalImportForeignFile =>
      'Этот файл не является базой данных рабочего пространства. Ничего не заменено.';

  @override
  String get refusalImportSchemaMismatch =>
      'Этот файл не удалось привести к формату этого сервера. Ничего не заменено.';

  @override
  String get refusalImportRouteConflict =>
      'Этот файл содержит ссылки, которые принадлежат другому рабочему пространству на этом сервере, и восстановление перехватило бы их. Ничего не заменено.';

  @override
  String get workspaceReadOnlyBannerTitle =>
      'Это рабочее пространство доступно только для чтения';

  @override
  String get workspaceReadOnlyBannerBody =>
      'Его данные не прошли проверку целостности, поэтому изменения сохранить нельзя. Всё по-прежнему можно читать. Владелец сервера может восстановить его из резервной копии.';

  @override
  String get workspaceReadOnlyBannerOwnerBody =>
      'Его данные не прошли проверку целостности, поэтому изменения сохранить нельзя. Всё по-прежнему можно читать. Восстановите его из резервной копии, чтобы снова разрешить запись.';

  @override
  String get workspaceReadOnlyBannerAction => 'Открыть резервные копии';

  @override
  String get serverNoticesLabel => 'Требует вашего внимания';

  @override
  String get serverNoticeReadOnlyStatus => 'Только чтение';

  @override
  String serverNoticeSince(String time) {
    return 'С $time';
  }

  @override
  String get serverNoticeReadOnlyBody =>
      'Его база данных не прошла проверку целостности, поэтому она доступна только для чтения и отклоняет любые изменения. Восстановите её из резервной копии в списках ниже: её последняя исправная копия сохраняется, пока вы этого не сделаете.';

  @override
  String get serverNoticeDetails => 'Подробности';

  @override
  String get backupSnapshotUnverified => 'Не проверен';

  @override
  String get backupSnapshotUnverifiedNote =>
      'Этот снимок нельзя проверить. Он не был завершён или был создан до того, как снимки начали записывать контрольные суммы, поэтому им нельзя восстановить всю установку. Файлы рабочего пространства, которые он содержит, всё же можно восстановить по одному.';

  @override
  String get backupSnapshotLastGoodCopy => 'Последняя исправная копия';

  @override
  String get backupSnapshotLastGoodCopyNote =>
      'Сохранена, потому что содержит последнюю исправную копию повреждённого рабочего пространства. Очистка не трогает её, пока это рабочее пространство не восстановлено.';

  @override
  String get backupDeleteLastGoodCopyDescription =>
      'Это последняя исправная копия повреждённого рабочего пространства. Если её удалить, восстановить это рабочее пространство будет не из чего.';

  @override
  String backupRestoreHeldBack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count разрешений отложено для проверки. Они указаны в начале этой страницы.',
      many:
          '$count разрешений отложено для проверки. Они указаны в начале этой страницы.',
      few:
          '$count разрешения отложены для проверки. Они указаны в начале этой страницы.',
      one:
          '$count разрешение отложено для проверки. Оно указано в начале этой страницы.',
    );
    return '$_temp0';
  }

  @override
  String get importHoldsLabel => 'Отложено из восстановленных копий';

  @override
  String get importHoldsExplainer =>
      'Восстановленная копия сама по себе не может ничего предоставить на этом сервере. В ней были такие разрешения: примите одно, чтобы предоставить его снова, или отклоните, чтобы удалить.';

  @override
  String importHoldPolicyAllow(String action) {
    return 'Агенты могут делать это без одобрения: $action';
  }

  @override
  String importHoldPolicyPrompt(String action) {
    return 'Агенты могут делать это, когда человек одобрит: $action';
  }

  @override
  String importHoldCommand(String command) {
    return 'Запускать команды, которые начинаются с $command';
  }

  @override
  String get importHoldScopeWorkspace => 'Во всём этом рабочем пространстве';

  @override
  String importHoldScopeSpace(String space) {
    return 'В пространстве $space';
  }

  @override
  String importHoldScopeAgent(String agent) {
    return 'Для агента $agent';
  }

  @override
  String importHoldSandboxExec(String path) {
    return 'Песочницы могут запускать $path';
  }

  @override
  String importHoldRepoWrite(String person, String repo) {
    return '$person может изменять $repo';
  }

  @override
  String importHoldRepoReview(String person, String repo) {
    return '$person может проверять pull request в $repo';
  }

  @override
  String importHoldRepoOther(String person, String repo, String level) {
    return '$person получает доступ уровня $level к $repo';
  }

  @override
  String importHoldMemberRole(String person, String role) {
    return '$person получает роль $role';
  }

  @override
  String importHoldInvite(String role) {
    return 'Открытое приглашение войти с ролью $role';
  }

  @override
  String importHoldInviteWithRepos(int count, String role) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Открытое приглашение войти с ролью $role и доступом на проверку или запись в $count репозиториев',
      many:
          'Открытое приглашение войти с ролью $role и доступом на проверку или запись в $count репозиториев',
      few:
          'Открытое приглашение войти с ролью $role и доступом на проверку или запись в $count репозитория',
      one:
          'Открытое приглашение войти с ролью $role и доступом на проверку или запись в $count репозиторий',
    );
    return '$_temp0';
  }

  @override
  String get importHoldUnknown =>
      'Разрешение, которое эта версия приложения не может описать';

  @override
  String importHoldRestoredAt(String time) {
    return 'Восстановлено $time';
  }

  @override
  String get importHoldAccept => 'Принять';

  @override
  String get importHoldDismiss => 'Отклонить';

  @override
  String get importHoldAcceptTitle => 'Предоставить это разрешение?';

  @override
  String importHoldAcceptBody(String permission) {
    return '$permission\n\nПринятие сразу предоставит его на сервере.';
  }

  @override
  String get importHoldAccepted => 'Разрешение предоставлено.';

  @override
  String get importHoldNotApplied =>
      'Ничего не предоставлено: тот, для кого оно было, или то, для чего оно было, больше не находится в этом рабочем пространстве.';

  @override
  String get mcpWorkspaceServers => 'MCP-серверы рабочего пространства';

  @override
  String get mcpWorkspaceServersDescription =>
      'Каждый запуск агента в этом рабочем пространстве получает инструменты этих серверов, и в Claude Code, и во встроенном раннере. Control Center подключается к каждому серверу и передаёт его инструменты дальше.';

  @override
  String get mcpWorkspaceServersAdminsOnly =>
      'Только администраторы рабочего пространства могут видеть и менять его MCP-серверы.';

  @override
  String get mcpWorkspaceServersUnavailable =>
      'MCP-серверы рабочего пространства недоступны на подключённом сервере.';

  @override
  String get mcpWorkspaceServersEmpty =>
      'Пока нет MCP-серверов рабочего пространства';

  @override
  String get mcpWorkspaceServersEmptyDescription =>
      'Добавьте сервер, чтобы каждый запуск агента в этом рабочем пространстве получил его инструменты.';

  @override
  String get mcpAddServer => 'Добавить сервер';

  @override
  String get mcpStatusAwaitingApproval => 'Ждёт одобрения';

  @override
  String get mcpPublicAddressesOnly => 'Только публичные адреса';

  @override
  String get mcpApproveServer => 'Одобрить';

  @override
  String get mcpApprovalStdioOwner =>
      'Этот сервер запускает команду на хосте сервера от имени пользователя сервера. Он не запустится, пока вы его не одобрите.';

  @override
  String get mcpApprovalStdioMember =>
      'Этот сервер запускает команду на хосте сервера, поэтому он не запустится, пока владелец сервера его не одобрит.';

  @override
  String get mcpApprovalRemoteOwner =>
      'Этот сервер может обращаться только к публичным адресам. Одобрите его, чтобы он мог обращаться и к частной сети хоста, например localhost и локальной сети.';

  @override
  String get mcpApprovalRemoteMember =>
      'Этот сервер может обращаться только к публичным адресам, пока владелец сервера его не одобрит.';

  @override
  String get mcpServersSettingsSubtitle =>
      'Встроенный MCP-сервер и MCP-серверы, инструменты которых получают запуски агентов в этом рабочем пространстве.';

  @override
  String get mcpPersonalServers => 'Ваши MCP-серверы';

  @override
  String get mcpPersonalServersDescription =>
      'Их видите только вы, и их инструменты получают только запуски агентов, которые вы начинаете в этом рабочем пространстве.';

  @override
  String get mcpPersonalServersUnavailable =>
      'Ваши MCP-серверы недоступны на подключённом сервере.';

  @override
  String get mcpPersonalServersEmpty => 'Своих MCP-серверов пока нет';

  @override
  String get mcpPersonalServersEmptyDescription =>
      'Добавьте сервер, чтобы запуски агентов, которые вы начинаете в этом рабочем пространстве, получили его инструменты.';

  @override
  String get mcpServerEditorPersonalOwner =>
      'Его используют только запуски, которые вы начинаете в этом рабочем пространстве. Как владелец сервера, вы одобряете его при сохранении.';

  @override
  String get mcpServerEditorPersonalMember =>
      'Его используют только запуски, которые вы начинаете в этом рабочем пространстве. Он может обращаться только к публичным адресам.';

  @override
  String get mcpServerSignInNeeded =>
      'Войдите, чтобы использовать инструменты этого сервера.';

  @override
  String get mcpServerSignIn => 'Войти';

  @override
  String mcpServerSignInTitle(String name) {
    return 'Вход в $name';
  }

  @override
  String mcpServerSignInWrongCode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Осталось $count попытки.',
      many: 'Осталось $count попыток.',
      few: 'Осталось $count попытки.',
      one: 'Осталась $count попытка.',
    );
    return 'Это не тот код, который показал браузер. $_temp0';
  }

  @override
  String get mcpServerSignInEnded =>
      'Время истекло, вход был отклонён или введено слишком много неверных кодов. Начните заново, чтобы получить новую страницу входа.';

  @override
  String get mcpServerSignInStartAgain => 'Начать заново';

  @override
  String mcpServerSignedIn(String name) {
    return 'Выполнен вход в $name.';
  }

  @override
  String get mcpRemoveServer => 'Удалить сервер';

  @override
  String mcpRemoveServerTitle(String name) {
    return 'Удалить $name?';
  }

  @override
  String get mcpRemoveServerBody =>
      'Запуски агентов потеряют инструменты этого сервера, а сохранённые значения его секретов будут удалены.';

  @override
  String mcpServerEnabledToggle(String name) {
    return 'Включить или выключить $name';
  }

  @override
  String get mcpServerEditorAddTitle => 'Добавить MCP-сервер';

  @override
  String mcpServerEditorEditTitle(String name) {
    return 'Изменить $name';
  }

  @override
  String get mcpServerNameHelper =>
      'Буквы, цифры, дефисы и подчёркивания. Агенты видят его инструменты под этим именем.';

  @override
  String get mcpServerNameInvalid =>
      'Используйте до 24 букв, цифр, дефисов или подчёркиваний, начиная с буквы или цифры.';

  @override
  String get mcpServerNameTaken =>
      'Здесь уже есть другой сервер с таким именем.';

  @override
  String get mcpServerTransportLabel => 'Транспорт';

  @override
  String get mcpServerTransportStdio => 'Команда';

  @override
  String get mcpServerTransportHttp => 'HTTP';

  @override
  String get mcpServerTransportSse => 'SSE';

  @override
  String get mcpServerCommandLabel => 'Команда';

  @override
  String get mcpServerCommandRequired => 'Введите команду для запуска.';

  @override
  String get mcpServerArgsLabel => 'Аргументы';

  @override
  String get mcpServerArgsHelper => 'По одному аргументу в строке.';

  @override
  String get mcpServerUrlLabel => 'URL';

  @override
  String get mcpServerUrlInvalid =>
      'Введите URL с http или https, без имени пользователя, пароля и #fragment.';

  @override
  String get mcpServerEnvLabel => 'Переменные окружения';

  @override
  String get mcpServerHeadersLabel => 'Заголовки';

  @override
  String get mcpServerSecretsDescription =>
      'Значения сохраняются как секреты и больше не показываются.';

  @override
  String get mcpServerHeadersExample =>
      'Например, заголовок Authorization с bearer-токеном.';

  @override
  String get mcpServerEnvAdd => 'Добавить переменную';

  @override
  String get mcpServerHeaderAdd => 'Добавить заголовок';

  @override
  String get mcpServerSecretValueHint => 'Значение';

  @override
  String get mcpServerSecretNewValueHint => 'Новое значение';

  @override
  String get mcpServerSecretReplace => 'Заменить значение';

  @override
  String get mcpServerSecretUndo => 'Отменить';

  @override
  String get mcpServerSecretRemovedOnSave => 'Удалится при сохранении';

  @override
  String mcpServerEnvNameInvalid(String name) {
    return '$name — недопустимое имя переменной. Используйте буквы, цифры и подчёркивания, не начиная с цифры.';
  }

  @override
  String mcpServerHeaderNameInvalid(String name) {
    return '$name нельзя задать. Используйте допустимое имя заголовка, которым соединение не управляет само.';
  }

  @override
  String get mcpServerTransportDropsValues =>
      'Смена транспорта удалит сохранённые значения.';

  @override
  String get mcpServerEnabledDescription =>
      'Когда выключено, сервер не запускается, и агенты не видят его инструменты.';

  @override
  String get mcpServerEditorStdioMember =>
      'Он запускается на хосте сервера, поэтому не начнёт работу, пока владелец сервера его не одобрит. Изменение способа запуска потребует одобрения заново.';

  @override
  String get mcpServerEditorRemoteMember =>
      'Он может обращаться только к публичным адресам, пока владелец сервера его не одобрит. Изменение способа подключения потребует одобрения заново.';

  @override
  String get mcpServerEditorStdioOwner =>
      'Он запускается на хосте сервера от имени пользователя сервера. Сохранение одобряет его.';

  @override
  String get mcpServerEditorRemoteOwner =>
      'Сохранение одобряет доступ и к частной сети хоста.';

  @override
  String get mcpServerRefusedInvalid =>
      'Control Center не смог сохранить этот сервер. Проверьте его настройки и попробуйте снова.';

  @override
  String get mcpServerNotFound =>
      'Этого сервера больше нет. Возможно, его удалили.';

  @override
  String get scriptToolCalls => 'Вызовы инструментов';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count вызова',
      many: '$count вызовов',
      few: '$count вызова',
      one: '1 вызов',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count выполняется';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count успешно';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count с ошибкой';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count запрещено';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count отменено';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count в очереди';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count пропущено';
  }

  @override
  String get scriptStepQueued => 'В очереди';

  @override
  String get scriptStepSkipped => 'Пропущен';

  @override
  String get scriptGroupLoop => 'Цикл';

  @override
  String get scriptGroupEach => 'Для каждого';

  @override
  String get scriptGroupParallel => 'Параллельно';

  @override
  String get scriptGroupFunction => 'Функция';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Показать ещё $count вызова',
      many: 'Показать ещё $count вызовов',
      few: 'Показать ещё $count вызова',
      one: 'Показать ещё 1 вызов',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced => 'Вызовы, не привязанные к коду скрипта';

  @override
  String get scriptToolComputed => 'Инструмент';

  @override
  String scriptStepSemantics(String subject, String state) {
    return '$subject, $state';
  }

  @override
  String get scriptSourceLabel => 'Скрипт';

  @override
  String scriptSourceLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count строки',
      many: '$count строк',
      few: '$count строки',
      one: '1 строка',
    );
    return '$_temp0';
  }

  @override
  String get scriptStateRunning => 'Выполняется';

  @override
  String get scriptStateCompleted => 'Завершён';

  @override
  String get scriptStateFailed => 'Сбой';

  @override
  String get scriptStateTimedOut => 'Время истекло';

  @override
  String get scriptStateCancelled => 'Отменён';

  @override
  String get scriptStateMemoryExceeded => 'Нехватка памяти';

  @override
  String get scriptStateOutputExceeded => 'Слишком большой вывод';

  @override
  String get scriptStateSandboxError => 'Ошибка песочницы';

  @override
  String get scriptStateRefused => 'Отклонён';

  @override
  String get transcriptToolDenied => 'Запрещено';

  @override
  String get transcriptStatusRunningScript => 'Выполняется скрипт…';

  @override
  String get scriptOriginLine => 'Из скрипта, который запустил агент';

  @override
  String get scriptOriginShow => 'Показать скрипт';

  @override
  String get codeModeTitle => 'Режим кода';

  @override
  String get codeModeSubtitle =>
      'Агенты могут написать короткий скрипт, который вызывает их инструменты, вместо того чтобы вызывать их по одному.';

  @override
  String get codeModeStatusLabel => 'Статус';

  @override
  String get codeModeFactAvailability => 'На этом сервере';

  @override
  String get codeModeAvailable => 'Доступен';

  @override
  String get codeModeUnavailable => 'Недоступен';

  @override
  String get codeModeFactRunner => 'Раннер';

  @override
  String codeModeUnavailableNote(String reason) {
    return 'Этот сервер не может выполнять скрипты, поэтому агенты здесь вызывают инструменты по одному. Сервер сообщает: $reason';
  }

  @override
  String get codeModeNoReason => 'причина не указана.';

  @override
  String get codeModeViewExecutions => 'Открыть выполнения кода';

  @override
  String get codeModeLimitsLabel => 'Лимиты';

  @override
  String get codeModeLimitsSubtitle =>
      'Как долго и как далеко может зайти один скрипт. Значения по умолчанию подходят большинству рабочих пространств.';

  @override
  String get codeModeLimitsDisclosure => 'Настроить лимиты';

  @override
  String get codeModeLimitsAtDefaults => 'По умолчанию';

  @override
  String codeModeLimitsChangedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count изменено',
      many: '$count изменено',
      few: '$count изменены',
      one: '1 изменён',
    );
    return '$_temp0';
  }

  @override
  String get codeModeLimitsUseDefaults => 'Вернуть значения по умолчанию';

  @override
  String get codeModeLimitWallClock => 'Время на скрипт';

  @override
  String get codeModeLimitWallClockHelp =>
      'Время ожидания человека не учитывается.';

  @override
  String get codeModeLimitCpu => 'Время процессора';

  @override
  String get codeModeLimitCpuHelp =>
      'Время, которое сам скрипт тратит на вычисления.';

  @override
  String get codeModeLimitHeap => 'Память';

  @override
  String get codeModeLimitHeapHelp =>
      'Память, которую скрипт может использовать во время работы.';

  @override
  String get codeModeLimitNestedCalls => 'Вызовы инструментов на скрипт';

  @override
  String get codeModeLimitNestedCallsHelp =>
      'Вызовы сверх этого лимита отклоняются, и скрипт получает объяснение.';

  @override
  String get codeModeLimitInFlight => 'Вызовов одновременно';

  @override
  String get codeModeLimitInFlightHelp =>
      'Сколько вызовов инструментов скрипт может выполнять одновременно.';

  @override
  String get codeModeLimitOutputTokens => 'Вывод, который читает агент';

  @override
  String get codeModeLimitOutputTokensHelp =>
      'Длинный вывод сокращается; остальное агент может запросить.';

  @override
  String codeModeLimitRange(String defaultValue, String min, String max) {
    return 'По умолчанию $defaultValue. От $min до $max.';
  }

  @override
  String codeModeLimitOutOfRange(String min, String max) {
    return 'Введите целое число от $min до $max.';
  }

  @override
  String get codeModeSuffixSeconds => 'с';

  @override
  String get codeModeSuffixMebibytes => 'МиБ';

  @override
  String get codeModeSuffixCalls => 'вызовов';

  @override
  String get codeModeSuffixTokens => 'токенов';

  @override
  String codeModeServerCap(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Этот сервер выполняет не более $count скриптов одновременно, во всех рабочих пространствах.',
      many:
          'Этот сервер выполняет не более $count скриптов одновременно, во всех рабочих пространствах.',
      few:
          'Этот сервер выполняет не более $count скриптов одновременно, во всех рабочих пространствах.',
      one:
          'Этот сервер выполняет не более 1 скрипта одновременно, во всех рабочих пространствах.',
    );
    return '$_temp0';
  }

  @override
  String codeModeUnitMilliseconds(String value) {
    return '$value мс';
  }

  @override
  String codeModeUnitSeconds(String value) {
    return '$value с';
  }

  @override
  String codeModeUnitMinutesSeconds(String minutes, String seconds) {
    return '$minutes мин $seconds с';
  }

  @override
  String get codeModeRefusedLimitUnknown =>
      'Сервер не знает один из этих лимитов.';

  @override
  String get codeModeRefusedLimitOutOfRange =>
      'Один из этих лимитов выходит за пределы допустимого сервером.';

  @override
  String get codeModeRefusedUnknownSetting =>
      'Сервер не распознал эту настройку.';

  @override
  String get codeExecutionsTitle => 'Выполнения кода';

  @override
  String get codeExecutionsSubtitle =>
      'Скрипты, которые агенты запускали в этом рабочем пространстве, со всеми вызовами инструментов.';

  @override
  String get codeExecutionsEmpty => 'Здесь ещё не запускался ни один скрипт.';

  @override
  String get codeExecutionsEmptyFiltered =>
      'Ни один скрипт не подходит под эти фильтры.';

  @override
  String get codeExecutionsStatusFilter => 'Результат';

  @override
  String get codeExecutionsAllOutcomes => 'Все результаты';

  @override
  String codeExecutionsOutcomeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count результата',
      many: '$count результатов',
      few: '$count результата',
      one: '1 результат',
    );
    return '$_temp0';
  }

  @override
  String get codeExecutionsScopeRun => 'Скрипты одного запуска';

  @override
  String get codeExecutionsScopeConversation => 'Скрипты одного разговора';

  @override
  String get codeExecutionsScopeAgent => 'Скрипты одного агента';

  @override
  String get codeExecutionsShowAll => 'Показать все';

  @override
  String get codeExecutionUntitled => 'Скрипт без названия';

  @override
  String get codeExecutionRecord => 'Запись';

  @override
  String get codeExecutionBackToList => 'Назад к выполнениям кода';

  @override
  String get codeExecutionNotFound =>
      'Этого выполнения кода нет в этом рабочем пространстве. Возможно, оно было удалено вместе со своим запуском.';

  @override
  String get codeExecutionRefusedSpace =>
      'Этот скрипт работал в пространстве, которое вы не можете открыть, поэтому его запись скрыта.';

  @override
  String get codeExecutionOpenRecord => 'Открыть запись';

  @override
  String get codeExecutionFactStarted => 'Начато';

  @override
  String get codeExecutionFactDuration => 'Длительность';

  @override
  String get codeExecutionFactCalls => 'Вызовы инструментов';

  @override
  String get codeExecutionFactAgent => 'Агент';

  @override
  String get codeExecutionFactSurface => 'Запущен через';

  @override
  String get codeExecutionSurfaceHarness => 'Встроенный агент';

  @override
  String get codeExecutionSurfaceMcp => 'Внешний агент';

  @override
  String get codeExecutionFactCpu => 'Время процессора';

  @override
  String get codeExecutionFactMemory => 'Пиковая память';

  @override
  String get codeExecutionOpenConversation => 'Открыть разговор';

  @override
  String get codeExecutionRunScripts => 'Скрипты в этом запуске';

  @override
  String get codeExecutionAgentScripts => 'Скрипты этого агента';

  @override
  String get codeExecutionScript => 'Скрипт';

  @override
  String get codeExecutionConsole => 'Консоль';

  @override
  String get codeExecutionOutputTruncated =>
      'Вывод сокращён, чтобы поместиться в сохранённое.';

  @override
  String get codeExecutionNoPayload => 'Скрипт и его вывод больше не хранятся.';

  @override
  String codeExecutionCallsHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count вызова инструментов',
      many: '$count вызовов инструментов',
      few: '$count вызова инструментов',
      one: '1 вызов инструмента',
      zero: 'Вызовы инструментов',
    );
    return '$_temp0';
  }

  @override
  String get codeExecutionNoCalls => 'Скрипт не вызывал инструменты.';

  @override
  String get codeExecutionCallCompleted => 'Завершён';

  @override
  String get codeExecutionCallFailed => 'Сбой';

  @override
  String get codeExecutionCallDenied => 'Запрещено';

  @override
  String get codeExecutionCallCancelled => 'Отменён';

  @override
  String get codeExecutionCallTimedOut => 'Время истекло';

  @override
  String get codeExecutionCallUnknownTool => 'Неизвестный инструмент';

  @override
  String get codeExecutionCallInvalidArgs => 'Неверные аргументы';

  @override
  String get codeExecutionGateAllowed => 'Разрешено';

  @override
  String get codeExecutionGateApproved => 'Одобрено человеком';

  @override
  String get codeExecutionGateDenied => 'Запрещено';

  @override
  String get codeExecutionGateNotReached => 'Не проверялось';

  @override
  String codeExecutionCallWaited(String duration) {
    return 'Ожидание человека: $duration';
  }

  @override
  String get codeExecutionCallArguments => 'Аргументы';

  @override
  String get codeExecutionCallResult => 'Результат';

  @override
  String codeExecutionCallResultSize(String size) {
    return 'Возвращено $size';
  }

  @override
  String codeExecutionBytes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count байта',
      many: '$count байт',
      few: '$count байта',
      one: '1 байт',
    );
    return '$_temp0';
  }

  @override
  String get codeExecutionEndedScriptError =>
      'Скрипт выдал ошибку, и её никто не перехватил.';

  @override
  String codeExecutionEndedScriptErrorNamed(String name) {
    return 'Скрипт выдал $name, и никто это не перехватил.';
  }

  @override
  String get codeExecutionEndedStalled =>
      'Скрипт ждал чего-то, что никогда не завершится.';

  @override
  String get codeExecutionEndedCpu =>
      'Скрипт израсходовал своё время процессора.';

  @override
  String get codeExecutionEndedHeap => 'Скрипт достиг лимита памяти.';

  @override
  String get codeExecutionEndedOutput =>
      'Скрипт вывел больше данных, чем разрешено.';

  @override
  String get codeExecutionEndedDeadline => 'Скрипту не хватило времени.';

  @override
  String get codeExecutionEndedCancelled => 'Скрипт был отменён до завершения.';

  @override
  String get codeExecutionEndedShutdown =>
      'Сервер был выключен во время работы скрипта.';

  @override
  String get codeExecutionEndedServerStopped =>
      'Сервер остановился во время работы скрипта. Запись закрыта при следующем запуске сервера.';

  @override
  String get codeExecutionEndedInternal =>
      'Программа для запуска скриптов завершилась с внутренней ошибкой.';

  @override
  String get codeExecutionEndedStart =>
      'Программе для запуска скриптов не удалось стартовать.';

  @override
  String get codeExecutionEndedLockdown =>
      'Программа для запуска скриптов не смогла ограничить себя, поэтому скрипт не был запущен.';

  @override
  String get codeExecutionEndedExited =>
      'Программа для запуска скриптов остановилась до завершения скрипта.';

  @override
  String get codeExecutionEndedRunnerBrokeRules =>
      'Программа для запуска скриптов нарушила правила, по которым работает, и была остановлена.';

  @override
  String get codeExecutionEndedUnresponsive =>
      'Программа для запуска скриптов перестала отвечать и была остановлена.';

  @override
  String get codeExecutionEndedHostError =>
      'Сервер дал сбой при выполнении скрипта.';

  @override
  String get codeExecutionRunningNote =>
      'Ещё выполняется. Вызовы инструментов появляются здесь по мере завершения, а результат — когда скрипт закончится.';

  @override
  String codeModeServerWorkspaceShare(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Скрипты одного рабочего пространства могут использовать не более $count из них.',
      many:
          'Скрипты одного рабочего пространства могут использовать не более $count из них.',
      few:
          'Скрипты одного рабочего пространства могут использовать не более $count из них.',
      one:
          'Скрипты одного рабочего пространства могут использовать не более 1 из них.',
    );
    return '$_temp0';
  }

  @override
  String get wakeOriginGoal => 'Цель';

  @override
  String get wakeOriginGoalCheck => 'Проверка цели';

  @override
  String get wakeOriginGoalReview => 'Ревью цели';

  @override
  String get wakeOriginSchedule => 'Расписание';

  @override
  String get wakeOriginWatch => 'Наблюдение';

  @override
  String wakeOriginReplyFrom(String agent) {
    return 'Ответ от $agent';
  }

  @override
  String get wakeOriginReply => 'Ответ';

  @override
  String wakeOriginMessageFrom(String agent) {
    return 'Сообщение от $agent';
  }

  @override
  String get wakeOriginMessage => 'Сообщение';

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return 'Готовая работа от $agent';
  }

  @override
  String get wakeOriginWorkFinished => 'Готовая работа';

  @override
  String get wakeOriginLimitReset => 'Сброс лимита';

  @override
  String get wakeOriginRecovery => 'Восстановление';

  @override
  String get wakeOriginAssignment => 'Назначение';

  @override
  String get wakeOriginPipelineStep => 'Шаг конвейера';

  @override
  String get wakeOriginImprovementReview => 'Ревью улучшений';

  @override
  String get wakeKindStopped =>
      'Задержано, потому что человек остановил запуск.';

  @override
  String get wakeKindAttempts => 'Доставка не удалась трижды.';

  @override
  String get wakeKindAgentDeleted => 'Агент больше не существует.';

  @override
  String get wakeKindAgentNotDispatchable => 'Агент выведен из работы.';

  @override
  String get wakeKindAgentPaused => 'Агент на паузе.';

  @override
  String get wakeKindPersonRemoved =>
      'Человек, от имени которого действует пробуждение, покинул рабочее пространство.';

  @override
  String get wakeKindBudgetBlocked => 'Бюджет блокирует запуск.';

  @override
  String get wakeKindTakeOver => 'Человек взял рабочее дерево на себя.';

  @override
  String get wakeKindRateCapConversation =>
      'Этот разговор начал 30 запусков из пробуждений за последний час.';

  @override
  String get wakeKindRateCapWorkspace =>
      'Это рабочее пространство начало 300 запусков из пробуждений за последний час.';

  @override
  String get wakeKindLiveRunNoInput =>
      'Текущий запуск агента здесь не принимает ввод.';

  @override
  String get wakeKindLiveRunOtherOptions =>
      'Текущий запуск агента здесь работает иначе, поэтому это запустит свой запуск после него.';

  @override
  String get wakeKindLiveRunOtherPerson =>
      'Текущий запуск агента здесь действует от имени другого человека, поэтому это запустит свой запуск после него.';

  @override
  String get wakeKindDispatchRefused => 'Запуск не удалось начать.';

  @override
  String get wakeKindSandboxUnavailable =>
      'Для запуска только на чтение песочница недоступна.';

  @override
  String get wakeKindReadOnlyUnavailable =>
      'Бэкенд этого агента не может держать запуск только на чтение.';

  @override
  String get wakeKindServerStopped => 'Перезапуск сервера остановил запуск.';

  @override
  String get wakeKindServerRestarted =>
      'Сервер перезапустился во время запуска человека.';

  @override
  String get wakeKindGuardFailed => 'Проверка перед доставкой не прошла.';

  @override
  String get wakeKindLimit => 'Ожидание на лимите использования у провайдера.';

  @override
  String get wakeKindLimitRunLive =>
      'Ожидание окончания запуска на лимите использования.';

  @override
  String get wakeKindWakeMissed => 'Пропущено, пока сервер был выключен.';

  @override
  String get wakeKindPipelineRunEnded => 'Его запуск конвейера завершился.';

  @override
  String get wakeKindGoalEnded => 'Его цель завершена.';

  @override
  String get wakeKindGoalBudgetExhausted => 'Его цель израсходовала бюджет.';

  @override
  String get wakeKindGoalReviewStale =>
      'Цель изменилась с тех пор, как запросили это ревью.';

  @override
  String get wakeKindGoalPaused => 'Его цель на паузе.';

  @override
  String get wakeKindGoalHeld => 'Его цель задержана.';

  @override
  String get wakeKindGoalStopped => 'Его цель остановлена.';

  @override
  String get wakeKindAskSettled =>
      'Вопрос, на который оно отвечает, уже решён.';

  @override
  String get wakeKindRuleEnded => 'Его расписание завершено.';

  @override
  String get wakeKindUnknown => 'По причине, которую эта версия не называет:';

  @override
  String wakeStripHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count пробуждения ждут',
      many: '$count пробуждений ждут',
      few: '$count пробуждения ждут',
      one: '$count пробуждение ждёт',
    );
    return '$_temp0';
  }

  @override
  String wakeStripDue(String time) {
    return 'Срок: $time';
  }

  @override
  String get wakeStripDueNow => 'Срок настал';

  @override
  String get wakeStripHeld => 'Задержано';

  @override
  String wakeStripExpires(String time) {
    return 'Истекает $time';
  }

  @override
  String wakeStripAttempt(int attempt) {
    return 'Попытка $attempt';
  }

  @override
  String get wakeStripCancel => 'Отменить пробуждение';

  @override
  String get wakeStripDeliverNow => 'Доставить сейчас';

  @override
  String get wakeStripResume => 'Продолжить';

  @override
  String get wakeStripDismiss => 'Отклонить';

  @override
  String get wakeStripResumeAll => 'Продолжить все';

  @override
  String get wakeStripResumeOnlyTheirs =>
      'Продолжить может только тот человек, чей это запуск.';

  @override
  String get wakeReceiptStarted => 'Запуск начат.';

  @override
  String get wakeReceiptPushed => 'Передано текущему запуску.';

  @override
  String wakeReceiptWaiting(String reason) {
    return 'Всё ещё ждёт. $reason';
  }

  @override
  String wakeReceiptSkipped(String reason) {
    return 'Не доставлено. $reason';
  }

  @override
  String get wakeReceiptDuplicate => 'Уже доставлено.';

  @override
  String wakeReleased(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Продолжено $count пробуждения.',
      many: 'Продолжено $count пробуждений.',
      few: 'Продолжено $count пробуждения.',
      one: 'Продолжено $count пробуждение.',
      zero: 'Ничего не продолжено.',
    );
    return '$_temp0';
  }

  @override
  String get wakeRefusalNotYours =>
      'Это пробуждение действует от имени другого человека. Доставить или продолжить его может только он.';

  @override
  String get wakeRefusalSettled => 'Это пробуждение уже завершено.';

  @override
  String heldSteeringHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count задержанных сообщения',
      many: '$count задержанных сообщений',
      few: '$count задержанных сообщения',
      one: '$count задержанное сообщение',
    );
    return '$_temp0';
  }

  @override
  String get heldSteeringResume => 'Отправить задержанные сообщения';

  @override
  String get heldSteeringDelete => 'Удалить задержанное сообщение';

  @override
  String heldSteeringReleased(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Отправлено $count задержанных сообщения.',
      many: 'Отправлено $count задержанных сообщений.',
      few: 'Отправлено $count задержанных сообщения.',
      one: 'Отправлено $count задержанное сообщение.',
      zero: 'Ничего не было задержано.',
    );
    return '$_temp0';
  }

  @override
  String get workAgentUnknown => 'агент';

  @override
  String workFeedWoke(int count, String agent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Запущен агент $agent для $count ожидающих элементов',
      many: 'Запущен агент $agent для $count ожидающих элементов',
      few: 'Запущен агент $agent для $count ожидающих элементов',
      one: 'Запущен агент $agent для $count ожидающего элемента',
    );
    return '$_temp0';
  }

  @override
  String workFeedWakeSkipped(String agent) {
    return 'Пробуждение для $agent не доставлено.';
  }

  @override
  String workFeedWakeMissed(String agent) {
    return 'Пробуждение для $agent пропущено, пока сервер был выключен.';
  }

  @override
  String workFeedScheduleCreated(String agent) {
    return 'Расписание задано для $agent.';
  }

  @override
  String workFeedScheduleEnded(String agent) {
    return 'Расписание для $agent завершено.';
  }

  @override
  String get workFeedOpenSchedule => 'Открыть расписание';

  @override
  String workFeedNoteFromAgent(String agent) {
    return '$agent оставил себе заметку своими словами:';
  }

  @override
  String get workFeedNoteFromPerson => 'Напоминание, которое задал человек:';

  @override
  String workFeedLimitParkHeld(String provider, String time) {
    return 'Приостановлено на лимите использования у $provider. Лимит сбрасывается в $time.';
  }

  @override
  String workFeedLimitParkPending(String provider, String time) {
    return 'Приостановлено на лимите использования у $provider. Продолжится в $time.';
  }

  @override
  String workFeedLimitParkResumed(String provider) {
    return 'Продолжено после лимита использования у $provider.';
  }

  @override
  String workFeedLimitParkGone(String provider) {
    return 'Больше не ждёт на лимите использования у $provider.';
  }

  @override
  String get workFeedLimitParkResume => 'Продолжить';

  @override
  String get workFeedLimitParkCancel => 'Отменить';

  @override
  String workFeedStillInFlight(String agent) {
    return 'Состояние передано агенту $agent после сжатия';
  }

  @override
  String get workFeedShowDetails => 'Показать подробности';

  @override
  String get workFeedHideDetails => 'Скрыть подробности';

  @override
  String get workFeedCommandRefused => 'Команда отклонена.';

  @override
  String get wakeRuleEndFired => 'Сработало свой один раз.';

  @override
  String get wakeRuleEndExpired => 'Достигнута дата окончания.';

  @override
  String get wakeRuleEndRunCap => 'Израсходованы его запуски.';

  @override
  String get wakeRuleEndCostCap => 'Достигнут предел стоимости.';

  @override
  String get wakeRuleEndGoalEnded => 'Его цель завершена.';

  @override
  String get wakeRuleEndCancelled => 'Отменено.';

  @override
  String get wakeRuleEndMemberRemoved =>
      'Человек, которому оно принадлежит, покинул рабочее пространство.';

  @override
  String get wakeRuleEndInvalidRow =>
      'Не удалось прочитать сохранённые настройки.';

  @override
  String get wakeRuleRefusalIntervalTooShort =>
      'Интервал слишком короткий. Выберите более длинный.';

  @override
  String get wakeRuleRefusalTooSoon =>
      'Это время слишком близко. Выберите более позднее.';

  @override
  String get wakeRuleRefusalLineageEnded =>
      'Эта цепочка пробуждений израсходовала свои запуски или время.';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable =>
      'Вы не можете прочитать, за чем это будет наблюдать.';

  @override
  String get wakeRuleRefusalExpiryRequired =>
      'Укажите окончание, например --days 3.';

  @override
  String get wakeRuleRefusalLimitReached =>
      'В этом разговоре уже максимум допустимых расписаний.';

  @override
  String get wakeRuleRefusalInvalidWhen => 'Не удалось разобрать время.';

  @override
  String get wakeRuleRefusalNoteTooLong => 'Заметка слишком длинная.';

  @override
  String get wakeRuleRefusalExpiryTooLong => 'Окончание слишком далеко.';

  @override
  String get wakeRuleRefusalLimitOutOfRange =>
      'Лимит запусков, дней или бюджета вне допустимого диапазона.';

  @override
  String get wakeRuleRefusalNextOutsideLoop =>
      'Выбрать следующее время может только цикл.';

  @override
  String get wakeRuleRefusalWatchRefused => 'Это нельзя отслеживать.';

  @override
  String get wakeRuleRefusalRuleEnded => 'Это расписание уже завершено.';

  @override
  String get wakeRuleRefusalNotYours =>
      'Это расписание принадлежит другому человеку.';

  @override
  String get workRefusalUnknown => 'Сервер отклонил это:';

  @override
  String get goalRefusalAlreadyActive =>
      'В этом разговоре уже есть активная цель.';

  @override
  String get goalRefusalNotInReview => 'Эта цель не ждёт ревью.';

  @override
  String get goalRefusalEvidenceIncomplete => 'Доказательства цели неполны.';

  @override
  String get goalRefusalClaimPending =>
      'Утверждение, что цель выполнена, ещё проверяется.';

  @override
  String get goalRefusalNotActiveSegment =>
      'У этой цели не запущен ни один сегмент.';

  @override
  String get goalRefusalNotYours =>
      'Это может сделать только тот человек, который начал цель.';

  @override
  String get goalRefusalNotPaused => 'Сначала приостановите цель.';

  @override
  String get goalRefusalContractInvalid => 'Условия цели нельзя прочитать.';

  @override
  String get goalRefusalCheckerUnknown => 'Нет агента с таким именем.';

  @override
  String get goalRefusalCheckerAmbiguous =>
      'Несколько агентов с таким именем. Укажите его id.';

  @override
  String get goalRefusalCheckerIsGoalAgent =>
      'Чекер должен быть другим агентом, а не тем, который выполняет работу.';

  @override
  String get goalRefusalCommandInvalid => 'Эту команду /goal нельзя прочитать.';

  @override
  String goalCardWorking(int segment) {
    return 'Работает · сегмент $segment';
  }

  @override
  String get goalCardWaiting => 'Ожидание следующего пробуждения';

  @override
  String get goalCardVerifying => 'Проверка, выполнена ли цель';

  @override
  String goalCardLimitUntil(String time) {
    return 'Приостановлено на лимите использования · продолжится $time';
  }

  @override
  String get goalCardLimit => 'Приостановлено на лимите использования';

  @override
  String get goalCardPerson => 'Нужен человек';

  @override
  String get goalCardByPerson => 'Приостановлено человеком';

  @override
  String get goalCardNeedsReview =>
      'Ждёт ревью: цель заявлена как выполненная, но ничто это не подтвердило';

  @override
  String goalCardSegments(int run, int max) {
    return 'Сегмент $run из $max';
  }

  @override
  String goalCardSegmentsNoCap(int run) {
    return 'Сегмент $run';
  }

  @override
  String goalCardMoney(String spent, String cap) {
    return '$spent из $cap';
  }

  @override
  String goalCardTimeLeft(String time) {
    return 'Осталось $time';
  }

  @override
  String get goalCardOverdue => 'Срок прошёл';

  @override
  String get goalCardDoneMeans => 'Критерии готовности';

  @override
  String get goalCardChecks => 'Проверки';

  @override
  String get goalCardCheckPassed => 'Пройдена';

  @override
  String goalCardCheckFailed(int code) {
    return 'Не пройдена · код $code';
  }

  @override
  String get goalCardCheckTimedOut => 'Время истекло';

  @override
  String get goalCardCheckNotRerun => 'Не перезапущена: ничего не изменилось';

  @override
  String get goalCardCheckBroken => 'Не может запуститься';

  @override
  String get goalCardCheckNotRun => 'Ещё не запускалась';

  @override
  String get goalCardCriterionMet => 'Выполнен';

  @override
  String get goalCardCriterionUnmet => 'Не выполнен';

  @override
  String get goalCardCriterionCannotTell => 'Не понятно';

  @override
  String get goalCardVerdictPass => 'Последняя проверка: готово';

  @override
  String get goalCardVerdictFail => 'Последняя проверка: не готово';

  @override
  String get goalCardVerdictCannotVerify =>
      'Последняя проверка: не удалось определить';

  @override
  String get goalCardConcerns => 'Замечания';

  @override
  String goalCardVerifiedBy(String agent) {
    return 'Проверил: $agent';
  }

  @override
  String get goalCardVerifiedBySelf => 'Проверил сам (отдельного чекера нет)';

  @override
  String get goalCardClosedByPerson =>
      'Закрыто человеком без пройденной проверки';

  @override
  String get goalCardNoMachineCheck => 'Нет машинной проверки';

  @override
  String get goalCardAddCheck => 'Добавить проверку';

  @override
  String get goalCardOpen => 'Открыть цель';

  @override
  String get goalCardApprove => 'Подтвердить выполнение';

  @override
  String get goalCardApproveTitle => 'Закрыть эту цель как выполненную?';

  @override
  String get goalCardApproveBody =>
      'Ни одна проверка это не подтвердила. Вы закрываете цель по собственному слову, и цель запишет, что её закрыл человек без проверки.';

  @override
  String get goalCardApproveConfirm => 'Закрыть как выполненную';

  @override
  String get goalCardResumeNotYours =>
      'Продолжить её или повысить бюджет может только тот, кто её начал.';

  @override
  String get goalHoldDetailStalled => 'Нет прогресса в последних сегментах.';

  @override
  String get goalHoldDetailStalledWaiting =>
      'Ожидание после сегментов без прогресса.';

  @override
  String get goalHoldDetailVerificationFailed =>
      'Последняя проверка не пройдена.';

  @override
  String get goalHoldDetailCannotVerify =>
      'Чекер не смог определить, выполнена ли цель.';

  @override
  String get goalHoldDetailSandboxUnavailable =>
      'Для запуска её проверок песочница недоступна.';

  @override
  String get goalHoldDetailCheckerUnavailable =>
      'Агент-чекер недоступен. Выберите другого чекера и продолжите.';

  @override
  String get goalHoldDetailCheckBroken => 'Эту проверку нельзя запустить:';

  @override
  String get goalHoldDetailWakeSkipped => 'Её пробуждение не доставлено.';

  @override
  String get goalHoldDetailClaimPending =>
      'Утверждение о выполнении ждёт проверки.';

  @override
  String get goalHoldDetailUnanswered =>
      'Вопрос или запрос на одобрение к человеку остался без ответа.';

  @override
  String get goalHoldDetailLimitParks =>
      'Слишком часто упиралась в лимиты использования. Просмотрите её и продолжите.';

  @override
  String get goalHoldDetailInput => 'Ожидает ответа в разговоре.';

  @override
  String get peerAsksSection => 'Запросы';

  @override
  String peerAskTo(String agent) {
    return 'Агенту $agent';
  }

  @override
  String get peerAskKindAsk => 'Вопрос';

  @override
  String get peerAskKindConsult => 'Консультация';

  @override
  String get peerAskKindReview => 'Ревью';

  @override
  String get peerAskStatusPending => 'Ожидает';

  @override
  String get peerAskStatusAnswered => 'Получен ответ';

  @override
  String get peerAskStatusFailed => 'Ошибка';

  @override
  String get peerAskStatusExpired => 'Истёк срок';

  @override
  String get peerAskStatusCancelled => 'Отменён';

  @override
  String peerAskAsked(String time) {
    return 'Задан $time';
  }

  @override
  String peerAskExpires(String time) {
    return 'Истекает $time';
  }

  @override
  String get peerAskPromised => 'Обещан ответ';

  @override
  String get peerAskBackground => 'В фоне';

  @override
  String get peerAskCancel => 'Отменить запрос';

  @override
  String get peerAskAlreadySettled => 'Этот запрос уже завершён.';

  @override
  String get slashHintGoal =>
      'Работать над целью, пока она не будет выполнена. Флаги: --check, --checker, --fresh, --unattended';

  @override
  String get slashHintLoop =>
      'Повторять задачу через интервал или в темпе агента';

  @override
  String get slashHintSchedule =>
      'Запустить задачу позже: in 2h, в 09:00 или по cron';

  @override
  String get slashHintRefine =>
      'Просмотреть работу в этом разговоре и предложить улучшения';

  @override
  String get notifGoalCompleted => 'Цель выполнена';

  @override
  String get notifGoalFailed => 'Цель не выполнена';

  @override
  String get notifGoalCancelled => 'Цель отменена';

  @override
  String get notifGoalBudgetExhausted => 'Цель израсходовала бюджет';

  @override
  String get notifGoalNeedsReview => 'Цель ждёт вашего ревью';

  @override
  String get notifGoalNeedsPerson => 'Цель нуждается в вас';

  @override
  String get notifGoalOnHold => 'Цель удерживается';

  @override
  String get notifWakeRuleEnded => 'Расписание завершено';

  @override
  String notifWaitingDigest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дела ждут вас',
      many: '$count дел ждут вас',
      few: '$count дела ждут вас',
      one: '$count дело ждёт вас',
    );
    return '$_temp0';
  }

  @override
  String notifImprovementProposed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Предложено $count улучшения',
      many: 'Предложено $count улучшений',
      few: 'Предложено $count улучшения',
      one: 'Предложено $count улучшение',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld => 'Запуск конвейера задержан из-за бюджета';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return 'Потрачено $spent из $cap';
  }

  @override
  String get inboxGoalNeedsReview => 'Цель ждёт ревью';

  @override
  String get inboxGoalNeedsPerson => 'Цель нуждается в вас';

  @override
  String get inboxImprovementProposed => 'Предложено улучшение';

  @override
  String get improvementRefusalAlreadyDecided =>
      'По этому предложению уже приняли решение.';

  @override
  String get improvementRefusalCampaignRequired =>
      'Это изменение не прошло оценку против текущего навыка, или навык изменился после замера. Запустите оценку заново.';

  @override
  String get improvementRefusalChangedSince =>
      'Цель изменилась с тех пор, как это предложили. Отклоните предложение, и агент предложит его снова.';

  @override
  String get improvementRefusalTargetMissing =>
      'То, что меняет это предложение, больше не существует.';

  @override
  String get improvementRefusalCampaignState =>
      'Оценка не может начаться или завершиться в её текущем состоянии.';

  @override
  String get improvementRefusalReviewCooldown =>
      'Этот разговор недавно проверяли. Попробуйте позже.';

  @override
  String get improvementRefusalAdminRequired =>
      'Решение по этому предложению может принять только администратор рабочего пространства.';

  @override
  String get improvementKindMemoryFact => 'Факт памяти';

  @override
  String get improvementKindPolicy => 'Политика';

  @override
  String get improvementKindAgentNote => 'Заметка агента';

  @override
  String get improvementKindSkillEdit => 'Изменение навыка';

  @override
  String get improvementKindSkillNew => 'Новый навык';

  @override
  String get improvementScopeAgent => 'Этот агент';

  @override
  String get improvementScopeRepository => 'Этот репозиторий';

  @override
  String get improvementScopeWorkspace => 'Всё рабочее пространство';

  @override
  String get improvementStatusProposed => 'Предложено';

  @override
  String get improvementStatusAccepted => 'Принято';

  @override
  String get improvementStatusRejected => 'Отклонено';

  @override
  String get improvementStatusRolledBack => 'Откачено';

  @override
  String get improvementStatusExpired => 'Истекло';

  @override
  String get improvementOperationAdd => 'Добавляет';

  @override
  String get improvementOperationReplace => 'Заменяет';

  @override
  String get improvementOperationRemove => 'Удаляет';

  @override
  String scheduleTriggerOnce(String time) {
    return 'Один раз, $time';
  }

  @override
  String scheduleTriggerEvery(String interval) {
    return 'Каждые $interval';
  }

  @override
  String scheduleTriggerCron(String cron, String zone) {
    return 'По расписанию $cron ($zone)';
  }

  @override
  String get scheduleTriggerSelfPaced =>
      'Когда выберет агент, с интервалом от 1 до 60 минут';

  @override
  String get scheduleTriggerPrChecks =>
      'Когда проверки pull request завершатся';

  @override
  String scheduleTriggerPrChecksOf(String pr) {
    return 'Когда проверки $pr завершатся';
  }

  @override
  String get scheduleTriggerPrReview =>
      'Когда pull request получит ревью или ответ';

  @override
  String scheduleTriggerPrReviewOf(String pr) {
    return 'Когда $pr получит ревью или ответ';
  }

  @override
  String get scheduleTriggerPrMerged => 'Когда pull request будет слит';

  @override
  String scheduleTriggerPrMergedOf(String pr) {
    return 'Когда $pr будет слит';
  }

  @override
  String get scheduleTriggerEnvironment =>
      'Когда задача окружения завершится или окружение станет готово';

  @override
  String scheduleTriggerTicket(String id) {
    return 'Когда тикет $id завершится';
  }

  @override
  String scheduleTriggerPipelineRun(String id) {
    return 'Когда запуск конвейера $id завершится';
  }

  @override
  String get goalNextWaiting => 'Продолжится, когда придёт то, чего она ждёт.';

  @override
  String get goalNextVerifying =>
      'Когда проверки и ревью завершатся, цель будет выполнена или продолжит работу.';

  @override
  String get goalNextLimit =>
      'Продолжится, когда лимит использования сбросится.';

  @override
  String get goalNextPerson =>
      'Она продолжит, когда кто-то ответит на её вопрос или запрос на одобрение.';

  @override
  String get goalNextByPerson =>
      'Останется на паузе, пока кто-то её не продолжит.';

  @override
  String get goalNextNeedsReview =>
      'Подтвердите её как выполненную или продолжите, чтобы она дальше работала.';

  @override
  String get goalNextWorking =>
      'Она продолжает работать, по одному сегменту за раз, пока не будет выполнена или не достигнет лимита.';

  @override
  String get goalContractAddCheck => 'Добавить проверку';

  @override
  String goalContractChecksFull(int max) {
    return 'У цели не может быть больше $max проверок.';
  }

  @override
  String goalContractChecksCount(int count, int max) {
    return 'Проверок: $count из $max';
  }

  @override
  String get goalContractCheckTaskHint => 'Имя задачи окружения, например test';

  @override
  String get goalContractCheckCommandHint => 'Команда, например make test';

  @override
  String get goalContractCheckWhere => 'Где запускается';

  @override
  String get goalContractCheckInWorktree => 'В рабочем дереве';

  @override
  String get goalContractCheckInEnvironment => 'Задача окружения';

  @override
  String get goalContractSecondsSuffix => 'с';

  @override
  String goalContractTimeoutRange(int max) {
    return 'От 1 до $max секунд';
  }

  @override
  String get goalContractRemoveCheck => 'Удалить проверку';

  @override
  String get goalContractDoneMeans => 'Критерии готовности';

  @override
  String get goalContractDoneMeansHelp =>
      'Каждый критерий — это одно утверждение, которое ревьюер может подтвердить.';

  @override
  String get goalContractCriterionHint =>
      'В заметках к релизу перечислено каждое слитое изменение';

  @override
  String goalContractCriterionTooLong(int max) {
    return 'Не больше $max символов.';
  }

  @override
  String get goalContractRemoveCriterion => 'Удалить критерий';

  @override
  String get goalContractAddCriterion => 'Добавить критерий';

  @override
  String goalContractCriteriaFull(int max) {
    return 'У цели не может быть больше $max критериев.';
  }

  @override
  String goalContractCriteriaCount(int count, int max) {
    return 'Критериев: $count из $max';
  }

  @override
  String get goalContractChecks => 'Проверки';

  @override
  String get goalContractChecksHelp =>
      'Сервер запускает их, когда агент говорит, что закончил. Цель без проверки опирается только на ревью.';

  @override
  String get goalContractBoundaries => 'Границы';

  @override
  String get goalContractBoundariesHint => 'Не менять публичный API';

  @override
  String get goalContractStopWhen => 'Остановиться и спросить, когда';

  @override
  String get goalContractStopWhenHint => 'Миграция удалит данные';

  @override
  String get goalContractEditTitle => 'Изменить критерии готовности';

  @override
  String get goalCheckerTitle => 'Кто проверяет эту цель';

  @override
  String get goalCheckerLabel => 'Чекер';

  @override
  String get goalCheckerNone => 'Без отдельного чекера';

  @override
  String get goalCheckerNoneWeaker =>
      'Без отдельного чекера агент проверяет собственную работу, а это замечает меньше.';

  @override
  String goalCheckerRecommend(String agent) {
    return 'Например, $agent: чекер у другого провайдера с меньшей вероятностью разделяет те же слепые зоны.';
  }

  @override
  String get goalCheckerRecommendGeneric =>
      'Чекер у другого провайдера, чем агент цели, с меньшей вероятностью разделяет его слепые зоны.';

  @override
  String raiseCapSpentOf(String spent, String cap) {
    return 'Потрачено $spent из $cap.';
  }

  @override
  String get raiseCapNewCap => 'Новый лимит в долларах';

  @override
  String raiseCapMustExceed(String cap) {
    return 'Введите сумму больше $cap.';
  }

  @override
  String get raiseCapConfirm => 'Повысить лимит';

  @override
  String get goalsBackToList => 'Все цели';

  @override
  String goalPursuedBy(String agent) {
    return 'Над ней работает $agent';
  }

  @override
  String get goalOpenConversation => 'Открыть разговор';

  @override
  String goalStarted(String time) {
    return 'Начата $time';
  }

  @override
  String get goalStopTitle => 'Остановить эту цель?';

  @override
  String get goalStopBody =>
      'Агент окончательно прекратит над ней работу. Сделанная до этого работа останется в разговоре.';

  @override
  String get goalRaiseBudgetTitle => 'Повысить бюджет и продолжить';

  @override
  String get goalRaiseBudgetAction => 'Повысить бюджет';

  @override
  String get goalSectionNow => 'Сейчас';

  @override
  String get goalFactSegments => 'Сегменты';

  @override
  String get goalFactMoney => 'Потрачено';

  @override
  String get goalFactDeadline => 'Срок';

  @override
  String get goalFactNoProgress => 'Без прогресса';

  @override
  String get goalNoDeadline => 'Нет';

  @override
  String goalDeadlineWithLeft(String time, String left) {
    return '$time, осталось $left';
  }

  @override
  String goalNoProgressCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сегмента подряд не дали прогресса',
      many: '$count сегментов подряд не дали прогресса',
      few: '$count сегмента подряд не дали прогресса',
      one: '$count сегмент подряд не дал прогресса',
    );
    return '$_temp0';
  }

  @override
  String get goalObjective => 'Задача';

  @override
  String get goalSectionContract => 'Что означает «готово»';

  @override
  String get goalContractPauseFirst =>
      'Приостановите цель, чтобы изменить критерии готовности или того, кто проверяет.';

  @override
  String get goalContractEdit => 'Изменить';

  @override
  String get goalCheckerChange => 'Изменить чекера';

  @override
  String get goalContractNone =>
      'Пока ничего не записано. Агент сам решает, когда работа готова.';

  @override
  String get goalCheckerSelf =>
      'Отдельного чекера нет: агент проверяет собственную работу.';

  @override
  String goalCheckerIs(String agent) {
    return 'Проверяет: $agent';
  }

  @override
  String goalCheckWorktree(int seconds) {
    return 'В рабочем дереве, до $seconds с';
  }

  @override
  String goalCheckEnvironmentTask(int seconds) {
    return 'Задача окружения, до $seconds с';
  }

  @override
  String get goalSectionVerification => 'Проверка';

  @override
  String get goalNotVerifiedYet =>
      'Ещё не проверено. Агент не говорил, что закончил.';

  @override
  String goalVerificationRound(int round, int total, String time) {
    return 'Раунд $round из $total, $time';
  }

  @override
  String get goalVerificationClaim => 'Что утверждает агент';

  @override
  String get goalCheckOutputTail => 'Вывод (последние строки)';

  @override
  String goalCheckExitCode(int code) {
    return 'Пройдена · код $code';
  }

  @override
  String get goalVerificationReview => 'Ревью';

  @override
  String get goalVerificationNoVerdict => 'Ревью пока нет.';

  @override
  String goalVerdictItem(String criterion, String state) {
    return '$criterion · $state';
  }

  @override
  String get goalSectionSchedules => 'Расписания и пробуждения';

  @override
  String get goalNoSchedules => 'Нет расписания и ожидающих пробуждений.';

  @override
  String get goalPendingWakes => 'Ожидающие пробуждения';

  @override
  String workListGroup(String label, int count) {
    return '$label · $count';
  }

  @override
  String get goalNotFound =>
      'Этой цели нет или она находится в пространстве, которое вы не можете открыть.';

  @override
  String get goalsTitle => 'Цели';

  @override
  String get goalsSubtitle =>
      'Работа, над которой агент продолжает трудиться, пока не выполнены критерии готовности.';

  @override
  String get goalsEmpty => 'Целей пока нет';

  @override
  String get goalsEmptyHint => 'Начните с /goal в разговоре.';

  @override
  String get goalsGroupReview => 'Ждут ревью';

  @override
  String get goalsGroupOpen => 'Открытые';

  @override
  String get goalsGroupEnded => 'Завершённые';

  @override
  String get scheduleStatusActive => 'Активно';

  @override
  String get scheduleStatusPaused => 'На паузе';

  @override
  String get scheduleStatusEnded => 'Завершено';

  @override
  String get scheduleWhenBusySkip =>
      'Пропускает срабатывание, пока агент занят';

  @override
  String get scheduleWhenBusyQueue => 'Ждёт, пока агент освободится';

  @override
  String get scheduleDeliverRun => 'Запускает новый запуск';

  @override
  String get scheduleDeliverNotify => 'Только уведомляет';

  @override
  String get scheduleNew => 'Новое расписание';

  @override
  String get schedulesEmpty => 'Нет расписаний и наблюдений';

  @override
  String get schedulesEmptyHint =>
      'Агенты задают их через /loop и /schedule, или вы можете создать своё.';

  @override
  String scheduleOwnedBy(String name) {
    return 'Ответственный: $name';
  }

  @override
  String scheduleRunsSkips(int runs, int skips) {
    String _temp0 = intl.Intl.pluralLogic(
      runs,
      locale: localeName,
      other: '$runs запуска',
      many: '$runs запусков',
      few: '$runs запуска',
      one: '$runs запуск',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skips,
      locale: localeName,
      other: '$skips пропуска',
      many: '$skips пропусков',
      few: '$skips пропуска',
      one: '$skips пропуск',
      zero: 'без пропусков',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String scheduleExpires(String time) {
    return 'Заканчивается $time';
  }

  @override
  String scheduleNextFires(String times) {
    return 'Далее: $times';
  }

  @override
  String get schedulesTitle => 'Расписания';

  @override
  String get schedulesSubtitle =>
      'Расписания, циклы и наблюдения, которые пробуждают агентов.';

  @override
  String get scheduleWhenLabel => 'Когда срабатывает';

  @override
  String get scheduleWhenEvery => 'Регулярно, каждые…';

  @override
  String get scheduleWhenCron => 'По расписанию cron';

  @override
  String get scheduleWhenOnceIn => 'Один раз, через…';

  @override
  String get scheduleWhenOnceAt => 'Один раз, в ближайшее…';

  @override
  String get scheduleDurationLabel => 'Интервал';

  @override
  String get scheduleDurationHelp =>
      'Используйте s, m, h или d, например 30m или 1h30m. Повторы идут не чаще, чем через 60 с.';

  @override
  String get scheduleDurationInvalid =>
      'Это не длительность, например 30m или 2h.';

  @override
  String get scheduleHour => 'Час';

  @override
  String get scheduleMinute => 'Минута';

  @override
  String get scheduleCronLabel => 'Cron (минута час день месяц день недели)';

  @override
  String get scheduleCronInvalid =>
      'Это не пятизначное cron-выражение, которое срабатывает.';

  @override
  String get scheduleTimeInvalid =>
      'Это не время в будущем, например 09:00 или 2026-11-21T09:00Z.';

  @override
  String scheduleDaysRange(int max) {
    return 'От 1 до $max дней.';
  }

  @override
  String scheduleOptionUnknown(String option) {
    return '$option не является параметром.';
  }

  @override
  String get scheduleLimits => 'Ограничения';

  @override
  String get schedulePresetWeekdays => 'По будням в 09:00';

  @override
  String get schedulePresetDaily => 'Каждый день в 09:00';

  @override
  String get schedulePresetHourly => 'Каждый час, в начале часа';

  @override
  String get scheduleZoneLabel => 'Часовой пояс';

  @override
  String get scheduleZoneHelp => 'Пусто — часовой пояс рабочего пространства.';

  @override
  String get scheduleZoneInvalid =>
      'Это не часовой пояс, например Europe/Berlin.';

  @override
  String get scheduleCreateTitle => 'Новое расписание';

  @override
  String get scheduleSpaceLabel => 'Пространство';

  @override
  String get scheduleSpaceHint => 'Выберите пространство';

  @override
  String get scheduleConversationLabel => 'Разговор';

  @override
  String get scheduleConversationHint => 'Выберите разговор';

  @override
  String get scheduleAgentLabel => 'Агент';

  @override
  String get scheduleAgentHint => 'Выберите, кого пробуждать';

  @override
  String get scheduleNoteLabel => 'С чего начинается каждый запуск';

  @override
  String get scheduleNoteHint =>
      'Кратко опишите, что изменилось за ночь, и отметьте всё заблокированное.';

  @override
  String get scheduleExpiresInDays => 'Заканчивается через (дней)';

  @override
  String get scheduleExpiresInDaysHelp => 'Пусто: 30 дней, не больше 365.';

  @override
  String get scheduleMaxRuns => 'Лимит запусков';

  @override
  String scheduleMaxRunsHelp(int max) {
    return 'Пусто: без предела, не больше $max.';
  }

  @override
  String get scheduleCostCap => 'Лимит стоимости (доллары)';

  @override
  String get scheduleCostCapHelp =>
      'Пусто — значение рабочего пространства по умолчанию.';

  @override
  String get scheduleWhenBusyLabel => 'Если агент занят';

  @override
  String get scheduleWhenBusyDefault => 'По умолчанию для этого типа';

  @override
  String get scheduleDeliverLabel => 'Каждое срабатывание';

  @override
  String get scheduleCreate => 'Создать расписание';

  @override
  String get scheduleExtendTitle => 'Продлить это расписание';

  @override
  String scheduleExtendNow(String current, String latest) {
    return 'Заканчивается $current. Может действовать не дольше $latest.';
  }

  @override
  String get scheduleExtendDays => 'Добавить дней';

  @override
  String scheduleExtendTooLong(String latest) {
    return 'Самый поздний срок окончания — $latest.';
  }

  @override
  String scheduleMaxRunsRange(int max) {
    return 'От 1 до $max запусков.';
  }

  @override
  String scheduleCostCapRange(String max) {
    return 'Минимум 1 доллар и не больше $max.';
  }

  @override
  String get scheduleExtend => 'Продлить';

  @override
  String get scheduleRemoveTitle => 'Убрать это расписание?';

  @override
  String get scheduleDeleteTitle => 'Удалить это расписание?';

  @override
  String get scheduleRemoveBody =>
      'Оно исчезнет из списка. Его запуски останутся в разговоре.';

  @override
  String get scheduleDeleteBody =>
      'Оно перестанет срабатывать окончательно. Его запуски останутся в разговоре.';

  @override
  String get scheduleRemove => 'Убрать';

  @override
  String get scheduleDelete => 'Удалить';

  @override
  String get scheduleOwnerOnly =>
      'Возобновить или продлить его может только владелец.';

  @override
  String get schedulesBackToList => 'Все расписания';

  @override
  String get scheduleNoteByAgent => 'Заметка, написанная агентом';

  @override
  String get scheduleNoteByPerson => 'Заметка, написанная человеком';

  @override
  String scheduleNoteEditedBy(String name) {
    return 'Заметка, последний раз изменена: $name';
  }

  @override
  String get scheduleNoNote => 'Заметки нет.';

  @override
  String get schedulePause => 'Пауза';

  @override
  String get scheduleResume => 'Продолжить';

  @override
  String get scheduleOpenChainRoot => 'Открыть первое расписание этой цепочки';

  @override
  String get scheduleSectionFacts => 'Подробности';

  @override
  String get scheduleFactAgent => 'Пробуждает';

  @override
  String get scheduleFactConversation => 'Где';

  @override
  String get scheduleConversationUnknown =>
      'Разговор, который вы не можете видеть';

  @override
  String get scheduleFactOwner => 'Ответственный';

  @override
  String get scheduleNoOwner => 'Никто';

  @override
  String get scheduleFactNextFires => 'Следующие срабатывания';

  @override
  String get scheduleFactNext => 'Следующее срабатывание';

  @override
  String get scheduleFactLast => 'Последнее срабатывание';

  @override
  String get scheduleFactRuns => 'Запуски';

  @override
  String scheduleRunsNoCap(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count запуска без предела',
      many: '$count запусков без предела',
      few: '$count запуска без предела',
      one: '$count запуск без предела',
    );
    return '$_temp0';
  }

  @override
  String scheduleRunsOfCap(int count, int max) {
    return '$count из $max запусков';
  }

  @override
  String get scheduleFactSkips => 'Пропуски';

  @override
  String scheduleSkips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count срабатывания пропущены',
      many: '$count срабатываний пропущено',
      few: '$count срабатывания пропущены',
      one: '$count срабатывание пропущено',
      zero: 'Нет',
    );
    return '$_temp0';
  }

  @override
  String get scheduleFactSpent => 'Потрачено';

  @override
  String get scheduleFactEnds => 'Заканчивается';

  @override
  String get scheduleFactWhenBusy => 'Если агент занят';

  @override
  String get scheduleFactDeliver => 'Каждое срабатывание';

  @override
  String get scheduleFactChain => 'Цепочка';

  @override
  String scheduleChainLeft(int runs, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      runs,
      locale: localeName,
      other: 'Осталось $runs запуска',
      many: 'Осталось $runs запусков',
      few: 'Осталось $runs запуска',
      one: 'Осталось $runs запуск',
    );
    return '$_temp0 в цепочке, которая заканчивается $time';
  }

  @override
  String get scheduleFactCreated => 'Создано';

  @override
  String get scheduleSectionHistory => 'Последние пробуждения и запуски';

  @override
  String get scheduleNoRuns => 'Запусков пока нет.';

  @override
  String scheduleRunLine(String status, String cost) {
    return '$status · $cost';
  }

  @override
  String get scheduleRunPending => 'Ждёт запуска';

  @override
  String get scheduleRunRunning => 'Выполняется';

  @override
  String get scheduleRunCompleted => 'Завершён';

  @override
  String get scheduleRunFailed => 'Ошибка';

  @override
  String get scheduleNotFound =>
      'Этого расписания нет или оно находится в пространстве, которое вы не можете открыть.';

  @override
  String get improvementCampaignTitle => 'Запустить оценку';

  @override
  String improvementCampaignCost(int repetitions, String budget) {
    String _temp0 = intl.Intl.pluralLogic(
      repetitions,
      locale: localeName,
      other: 'Каждая задача запускается $repetitions раза',
      many: 'Каждая задача запускается $repetitions раз',
      few: 'Каждая задача запускается $repetitions раза',
      one: 'Каждая задача запускается $repetitions раз',
    );
    return '$_temp0 с текущим навыком и с изменением. Расходует не больше $budget, списывается с этого рабочего пространства.';
  }

  @override
  String get improvementCampaignCostUnknown =>
      'Оценка прогоняет корпус с текущим навыком и с изменением, не превышая заданный вами бюджет.';

  @override
  String get improvementCampaignUnavailable =>
      'Оценки сейчас не могут запускаться на этом сервере.';

  @override
  String get improvementCampaignCorpus => 'Корпус';

  @override
  String get improvementCampaignProvider => 'Провайдер';

  @override
  String get improvementCampaignModel => 'Модель';

  @override
  String get improvementCampaignRepetitions => 'Запусков на задачу';

  @override
  String get improvementCampaignBudget => 'Бюджет (доллары)';

  @override
  String improvementCampaignRange(int max) {
    return 'От 1 до $max.';
  }

  @override
  String get improvementCampaignStart => 'Начать оценку';

  @override
  String get improvementRollbackTitle => 'Откатить это изменение?';

  @override
  String get improvementRollbackBody =>
      'Текст, который оно заменило, вернётся, если никто его с тех пор не менял.';

  @override
  String get improvementRollback => 'Откатить';

  @override
  String get improvementRolledBackDone => 'Откачено.';

  @override
  String get improvementNeedsAdmin =>
      'Решить может только администратор рабочего пространства: это меняет навык или политику для всего рабочего пространства.';

  @override
  String get improvementAdminDecides =>
      'Как администратор, решение по этому принимаете вы: это меняет навык или политику для всего рабочего пространства.';

  @override
  String get improvementNeedsCampaign =>
      'Прежде чем принять это изменение навыка, запустите успешную оценку.';

  @override
  String get improvementsBackToList => 'Все улучшения';

  @override
  String improvementMeta(String kind, String scope, String agent) {
    return '$kind · $scope · предложил $agent';
  }

  @override
  String get improvementAccept => 'Принять';

  @override
  String get improvementAcceptedDone => 'Принято.';

  @override
  String get improvementReject => 'Отклонить';

  @override
  String get improvementRejectedDone => 'Отклонено.';

  @override
  String get improvementRunEvaluation => 'Запустить оценку';

  @override
  String get improvementSectionChange => 'Что меняется';

  @override
  String get improvementTarget => 'Объект';

  @override
  String improvementScopeLine(String scope) {
    return 'Применяется к: $scope';
  }

  @override
  String get improvementNewText => 'Новый текст';

  @override
  String get improvementRemovedText => 'Удалённый текст';

  @override
  String get improvementExpected => 'Ожидаемый эффект';

  @override
  String get improvementSectionEvidence => 'Доказательства и решение';

  @override
  String get improvementNoEvidence => 'Доказательств не приложено.';

  @override
  String get improvementEvidenceRuns => 'Запуски';

  @override
  String get improvementEvidenceMessages => 'Сообщения';

  @override
  String improvementOpenMessage(int index) {
    return 'Сообщение $index';
  }

  @override
  String get improvementEvidenceChecks => 'Результаты проверок';

  @override
  String get improvementEvaluation => 'Оценка';

  @override
  String get improvementCampaignNone => 'Ещё не оценивалось.';

  @override
  String get improvementCampaignRunning => 'Оценка выполняется.';

  @override
  String get improvementCampaignPassed =>
      'Оценка пройдена: она выполнена полностью, и изменение решило не меньше запусков, чем текущий навык. Это не доказывает, что оно лучше. Его можно принять.';

  @override
  String get improvementCampaignFailed =>
      'Оценка не пройдена или навык изменился после замера. Запустите её снова или отклоните изменение.';

  @override
  String improvementDecided(String status, String name, String time) {
    return '$status: $name, $time';
  }

  @override
  String get improvementSomeone => 'кто-то';

  @override
  String improvementExpires(String time) {
    return 'Истекает $time, если никто не решит.';
  }

  @override
  String get improvementOpenApplied => 'Открыть то, что оно изменило';

  @override
  String get improvementsTitle => 'Улучшения';

  @override
  String get improvementsSubtitle =>
      'Изменения, которые агенты предложили для своей памяти, заметок, политик и навыков.';

  @override
  String get improvementsEmpty => 'Предложений нет';

  @override
  String get improvementsEmptyHint =>
      'Агенты предлагают улучшения после ревью своей работы, например через /refine.';

  @override
  String get improvementRowNeedsAdmin => 'Решает администратор';

  @override
  String get improvementNotFound =>
      'Этого предложения нет или оно находится в пространстве, которое вы не можете открыть.';

  @override
  String get dispatchSettingsTitle => 'Расписания';

  @override
  String get dispatchLimitsLabel => 'Лимиты расписаний';

  @override
  String get dispatchLimitsSubtitle =>
      'Сколько расписаний и наблюдений могут держать агенты и какие значения по умолчанию.';

  @override
  String dispatchLimitRange(int max) {
    return 'От 1 до $max';
  }

  @override
  String get dispatchLimitPerConversation => 'На агента в разговоре';

  @override
  String get dispatchLimitPerConversationHelp =>
      'Активные или приостановленные расписания, которые один агент может держать в одном разговоре.';

  @override
  String get dispatchLimitPerAgent => 'На агента';

  @override
  String get dispatchLimitPerAgentHelp =>
      'Активные или приостановленные расписания, которые один агент может держать во всём рабочем пространстве.';

  @override
  String get dispatchLimitPerWorkspace => 'В рабочем пространстве';

  @override
  String get dispatchLimitPerWorkspaceHelp =>
      'Активные или приостановленные расписания во всём рабочем пространстве.';

  @override
  String get dispatchLimitCostCap => 'Лимит стоимости по умолчанию (доллары)';

  @override
  String get dispatchLimitCostCapHelp =>
      'Сколько расписание может потратить в сумме, если не задало собственный лимит.';

  @override
  String get dispatchLimitZone => 'Часовой пояс';

  @override
  String get dispatchLimitZoneHelp =>
      'Пояс, в котором читается cron-расписание без своего пояса, и пояс ежедневной сводки.';

  @override
  String get dispatchUnattendedLabel => 'Если никто не отвечает';

  @override
  String get dispatchUnattendedSubtitle =>
      'Сколько запуск, начатый сервером, ждёт человека и когда отправляется ежедневная сводка того, что ждёт.';

  @override
  String get dispatchUnattendedExpiry => 'Запросы ждут (часы)';

  @override
  String get dispatchUnattendedExpiryHelp =>
      'По истечении этого срока одобрение считается отказом, а вопрос — без ответа. Цели, настроенные на ответ на свои вопросы, отвечают сами через 10 минут.';

  @override
  String dispatchUnattendedExpiryRange(int min, int max) {
    return 'От $min до $max часов';
  }

  @override
  String get dispatchDigestHour => 'Ежедневная сводка в (час)';

  @override
  String dispatchDigestHourHelp(String zone) {
    return 'В $zone, в часовом поясе выше.';
  }

  @override
  String get dispatchDigestHourRange => 'От 0 до 23';

  @override
  String get goalRecordCrumb => 'Цель';

  @override
  String get improvementRecordCrumb => 'Предложение';

  @override
  String get goalNodeNeedsAgent => 'Выберите агента, который ведёт цель.';

  @override
  String get goalNodeNeedsObjective => 'Опишите задачу.';

  @override
  String get goalNodeContractInvalid =>
      'В условиях есть поле вне лимита; оно не сохранится, пока не будет исправлено.';

  @override
  String get goalNodeBudget => 'Бюджет (доллары)';

  @override
  String get goalNodeBudgetHelp =>
      'Больше всего, что цель может потратить. Когда бюджет закончится, цель будет ждать человека.';

  @override
  String goalNodeBudgetRange(int max) {
    return 'Обязательно: больше 0, не больше $max.';
  }

  @override
  String get goalNodeMaxRuns => 'Лимит сегментов';

  @override
  String get goalNodeMaxRunsHelp =>
      'Необязательно. Больше всего сегментов (запусков агента), которые может занять цель.';

  @override
  String get goalNodeDeadline => 'Срок (часы)';

  @override
  String get goalNodeDeadlineHelp =>
      'Необязательно. Часы с момента, когда шаг запускает цель.';

  @override
  String goalNodeRange(int max) {
    return 'От 1 до $max или пусто.';
  }

  @override
  String get goalNodeContract => 'Условия';

  @override
  String get goalNodeContractHelp =>
      'Что значит «готово»: критерии, которые проверяет ревьюер, и команды, которые должны пройти.';

  @override
  String get nodeConfigObjective => 'Задача';

  @override
  String pipelineRunGoalStep(String step) {
    return 'Шаг $step ведёт цель';
  }

  @override
  String get pipelineRunOpenGoal => 'Открыть цель';

  @override
  String get pipelineRunHeldBudget =>
      'Запуск задержан: его оркестрация достигла лимита стоимости.';

  @override
  String pipelineRunHeldOther(String reason) {
    return 'Запуск задержан ($reason).';
  }

  @override
  String pipelineRunHeldSpent(String spent, String cap) {
    return 'Потрачено $spent из $cap. Повысьте лимит, и запуск продолжится.';
  }

  @override
  String get pipelineRunRaiseCap => 'Повысить лимит';

  @override
  String get pipelineRunRaiseCapTitle => 'Повысить лимит оркестрации';

  @override
  String get pipelineRunCapRaised => 'Лимит повышен. Запуск скоро продолжится.';

  @override
  String get goalLaunchChecks => 'Проверки';

  @override
  String get goalLaunchChecksHelp =>
      'Команды, которые должны пройти, прежде чем цель сможет завершиться. Необязательно.';

  @override
  String get goalLaunchFresh => 'Начинать каждый сегмент с чистого листа';

  @override
  String get goalLaunchFreshHelp =>
      'Каждый запуск начинается без истории разговора, только с цели и её заметок.';

  @override
  String get goalLaunchAssume =>
      'Отвечать на свои вопросы, если никто не отвечает';

  @override
  String get goalLaunchAssumeHelp =>
      'Через 10 минут без ответа агент фиксирует своё допущение и продолжает, если это позволяют условия остановки.';

  @override
  String workFeedLimitParkOutcomeResumed(String provider, String time) {
    return 'Продолжено в $time после лимита использования у $provider.';
  }

  @override
  String workFeedLimitParkOutcomeCancelled(String provider, String time) {
    return 'Отменено в $time. Не продолжено после лимита использования у $provider.';
  }

  @override
  String workFeedLimitParkOutcomeExpired(String provider, String time) {
    return 'Истекло в $time, так и не продолжившись после лимита использования у $provider.';
  }

  @override
  String workFeedLimitParkOutcomeSkipped(String provider, String time) {
    return 'Не продолжено после лимита использования у $provider ($time).';
  }

  @override
  String workFeedCommandRefusedNamed(String command) {
    return 'Команда /$command отклонена.';
  }

  @override
  String get improvementRefusalQueued =>
      'Ревью этого разговора уже ждёт, когда его запустят.';

  @override
  String get improvementRefusalAgentNotFound =>
      'Этого агента нет в рабочем пространстве.';

  @override
  String get workRefusalWakeQueueFull =>
      'Здесь уже ждёт слишком много пробуждений. Попробуйте, когда часть из них запустится.';

  @override
  String get orchestrationRefusalNotYours =>
      'Изменить это может только человек, от имени которого работает запуск.';

  @override
  String get orchestrationRefusalCapInvalid =>
      'Новый лимит должен быть выше текущего и уже потраченной суммы, и не больше \$1,000.';

  @override
  String get orchestrationRefusalCapChanged =>
      'Лимит уже повысил кто-то другой. Проверьте новый лимит и попробуйте снова.';

  @override
  String workFeedCapRaised(String person, String oldCap, String newCap) {
    return '$person повысил лимит запуска с $oldCap до $newCap.';
  }

  @override
  String get workFeedPersonUnknown => 'Человек';

  @override
  String workFeedApplyIncomplete(String skill) {
    return 'Принятое изменение навыка $skill не удалось завершить, потому что навык тем временем изменился. Предложение откатили.';
  }

  @override
  String get workFeedOpenImprovement => 'Открыть улучшение';

  @override
  String get peerAskFailNoOutput => 'Он завершился без ответа.';

  @override
  String get peerAskFailRunFailed => 'Его запуск завершился с ошибкой.';

  @override
  String get peerAskFailStoppedByPerson => 'Человек остановил его запуск.';

  @override
  String get peerAskFailBudget => 'Его запуск достиг бюджета.';

  @override
  String get peerAskFailSilence => 'Его запуск замолчал и был остановлен.';

  @override
  String get peerAskFailUsageLimit =>
      'Его запуск остановился на лимите использования у провайдера.';

  @override
  String get peerAskFailNotDelivered => 'Вопрос так и не был доставлен.';

  @override
  String heldSteeringLimitHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сообщения задержаны на лимите использования',
      many: '$count сообщений задержано на лимите использования',
      few: '$count сообщения задержаны на лимите использования',
      one: '$count сообщение задержано на лимите использования',
    );
    return '$_temp0';
  }

  @override
  String get heldSteeringLimitNote =>
      'Они будут отправлены, когда человек, для которого работает запуск, продолжит его. Если его не продолжат в течение 7 дней после сброса лимита, они останутся задержаны для этого человека.';

  @override
  String get wakeKindRuleFolded => 'Его заменило более позднее событие.';

  @override
  String goalCardWaitingNext(String time) {
    return 'Ждёт того, что сама настроила · проверит снова к $time';
  }

  @override
  String raiseCapAtMost(String max) {
    return 'Введите не больше $max.';
  }

  @override
  String raiseCapNowAt(String cap) {
    return 'Теперь лимит — $cap.';
  }

  @override
  String get scheduleWakeReasonSchedule => 'По расписанию';

  @override
  String get scheduleWakeReasonWatch => 'Наблюдение';

  @override
  String get scheduleWakeReasonLimitReset =>
      'После сброса лимита использования';

  @override
  String get scheduleWakeStatePending => 'Ожидает';

  @override
  String get scheduleWakeStateHeld => 'Задержано';

  @override
  String get scheduleWakeStateClaimed => 'Запускается';

  @override
  String get scheduleWakeStateDelivered => 'Доставлено';

  @override
  String get scheduleWakeStateSkipped => 'Пропущено';

  @override
  String get scheduleWakeStateExpired => 'Истекло';

  @override
  String get scheduleWakeStateCancelled => 'Отменено';

  @override
  String scheduleWakeLine(String reason, String state) {
    return '$reason · $state';
  }

  @override
  String scheduleWakeExit(int code) {
    return 'код $code';
  }

  @override
  String scheduleWakeEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count события',
      many: '$count событий',
      few: '$count события',
      one: '$count событие',
    );
    return '$_temp0';
  }

  @override
  String get scheduleWakesNone => 'Пробуждений пока нет.';

  @override
  String get scheduleWakesOlder => 'Показать более ранние';

  @override
  String get improvementCandidateStaged =>
      'Предложенный навык хранится как отдельная ревизия. Оценка не меняет действующий навык; он меняется только после принятия предложения.';

  @override
  String goalNextWaitingFallback(String time) {
    return 'Она продолжит, когда придёт то, чего она ждёт, или снова проверит в $time, если ничего не придёт.';
  }

  @override
  String get steeringRefusalHeldByLimit =>
      'Сообщения, которые держит пауза на лимите использования, нельзя отправить вручную, пока она ждёт.';

  @override
  String steeringRefusalHeldByLimitAt(String time) {
    return 'Сообщения, которые держит пауза на лимите использования, нельзя отправить вручную, пока она ждёт. Лимит сбросится в $time.';
  }

  @override
  String heldSteeringLimitResetsAt(String time) {
    return 'Лимит сбрасывается в $time. Они будут отправлены, когда человек, для которого работает запуск, продолжит его.';
  }

  @override
  String heldSteeringFromPerson(String name) {
    return 'От $name';
  }

  @override
  String get heldSteeringFromSomeoneElse => 'От другого человека';

  @override
  String get heldSteeringOnlyWriterSends =>
      'Отправить задержанное сообщение может только тот, кто его написал.';

  @override
  String get steeringRefusalNotYours =>
      'Эти задержанные сообщения принадлежат другим людям. Отправить может только тот, кто написал сообщение.';

  @override
  String improvementEvaluationSolved(
    int pairedRuns,
    int candidateSolved,
    int baselineSolved,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      pairedRuns,
      locale: localeName,
      other: 'В $pairedRuns парных запусках',
      many: 'В $pairedRuns парных запусках',
      few: 'В $pairedRuns парных запусках',
      one: 'В $pairedRuns парном запуске',
    );
    return '$_temp0, изменение решило $candidateSolved, а текущий навык — $baselineSolved.';
  }

  @override
  String improvementEvaluationWorse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count задачи стали хуже с изменением.',
      many: '$count задач стали хуже с изменением.',
      few: '$count задачи стали хуже с изменением.',
      one: '$count задача стала хуже с изменением.',
    );
    return '$_temp0';
  }

  @override
  String improvementEvaluationCostlier(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count задачи стали дороже с изменением.',
      many: '$count задач стали дороже с изменением.',
      few: '$count задачи стали дороже с изменением.',
      one: '$count задача стала дороже с изменением.',
    );
    return '$_temp0';
  }

  @override
  String improvementEvaluationHarnessErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count запуска изменения завершились ошибкой раннера.',
      many: '$count запусков изменения завершились ошибкой раннера.',
      few: '$count запуска изменения завершились ошибкой раннера.',
      one: '$count запуск изменения завершился ошибкой раннера.',
    );
    return '$_temp0';
  }

  @override
  String get improvementEvaluationIncomplete =>
      'Оценка выполнилась не полностью.';

  @override
  String workFeedLimitParkExpires(String time) {
    return 'Истекает $time';
  }

  @override
  String workFeedSchedulePaused(String person, String agent) {
    return '$person поставил на паузу расписание для $agent.';
  }

  @override
  String get goalCardApproveNotYours =>
      'Одобрить завершение этой цели может только тот, кто запустил конвейер.';

  @override
  String get goalCardObjective => 'Задача';

  @override
  String get planNeedsWrite =>
      'Одобрять или менять этот план можно только с доступом на запись ко всем репозиториям этого пространства. Такой доступ может предоставить администратор рабочего пространства.';

  @override
  String scheduleSpentWithChain(String spent, String cap) {
    return '$spent из $cap, с учётом каждого расписания в его цепочке';
  }

  @override
  String get ccLoading => 'Загрузка';

  @override
  String get ccProgress => 'Ход выполнения';

  @override
  String get ccBreadcrumb => 'Путь навигации';

  @override
  String get ccDialog => 'Диалоговое окно';

  @override
  String get ccResize => 'Изменить размер';

  @override
  String ccUnverifiedLabel(String label) {
    return '$label (не проверено)';
  }

  @override
  String prRowSelect(String title) {
    return 'Выбрать $title';
  }

  @override
  String get prTableSelectAll => 'Выбрать все pull requests';

  @override
  String planVersionRewind(int version) {
    return 'Откатить к версии $version';
  }
}
