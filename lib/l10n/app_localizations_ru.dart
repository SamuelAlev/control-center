// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

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
  String get keybindingPushToTalkDescription =>
      'Удерживайте или переключайте голосовую диктовку в поле сообщения';

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
  String get guardrailClassPrPublish => 'Опубликовать ревью или слияние';

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
      'Создает временный симулятор iOS на сервере Mac. Он удаляется при закрытии тестовой среды; доступ к сети не изолирован.';

  @override
  String get rigStopMachine => 'Остановить машину';

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
  String get serverModeRemote => 'Подключиться к удалённому экземпляру';

  @override
  String get serverModeRemoteDescription =>
      'Подключение к серверу Control Center на другом компьютере. Данные хранятся на этом сервере.';

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
  String get serverSetupTitle => 'Как запускать Control Center?';

  @override
  String get serverSetupSubtitle =>
      'Control Center нужен сервер, который хранит ваши данные. Запустите его в этом приложении или подключитесь к уже работающему экземпляру.';

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
  String get calendarAllDayGutter => 'Весь день';

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
  String get calendarStartRecording => 'Начать запись';

  @override
  String get calendarStartRecordingAndLink => 'Начать запись и привязать';

  @override
  String get calendarJoinMeet => 'Присоединиться к встрече';

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
  String get calendarAddAccount => 'Добавить аккаунт календаря';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Подключите аккаунт Google, чтобы синхронизировать события в это рабочее пространство.';

  @override
  String get calendarConnecting => 'Подключение…';

  @override
  String get calendarSyncNow => 'Синхронизировать';

  @override
  String get calendarNoWorkspace =>
      'Выберите рабочее пространство, чтобы просмотреть его календарь';

  @override
  String get calendarConnectError => 'Не удалось подключить Google Calendar';

  @override
  String get calendarClientIdLabel => 'Идентификатор клиента';

  @override
  String get calendarClientSecretLabel => 'Секрет клиента';

  @override
  String get calendarConnectCredsHint =>
      'Введите идентификатор клиента и секрет Google OAuth (device code) для вашего проекта. Подключение и синхронизацию выполняет сервер — браузер никогда не хранит токены.';

  @override
  String get calendarConnectApproveInstruction =>
      'Откройте страницу подтверждения на любом устройстве, войдите в аккаунт и введите этот код:';

  @override
  String get calendarConnectOpenPage => 'Открыть страницу подтверждения';

  @override
  String get calendarConnectWaiting => 'Ожидание подтверждения…';

  @override
  String get calendarConnectDenied =>
      'Авторизация отклонена. Попробуйте ещё раз.';

  @override
  String get calendarConnectExpired =>
      'Срок действия кода истёк. Попробуйте ещё раз.';

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
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'Открыть меню фильтров pull request';

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
  String get mcpServersSettingsDescription =>
      'Встроенный MCP-сервер и внешние MCP-серверы.';

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
  String get activityLabel => 'АКТИВНОСТЬ';

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
  String get activityUpdatedGitHubToken => 'Обновлён токен GitHub';

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
  String get activityMarkedSpaceRead => 'Пространство отмечено как прочитанное';

  @override
  String get activityRespondedToInvitation => 'Ответ на приглашение на событие';

  @override
  String get activityStartedCalendarConnect => 'Начато подключение календаря';

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
  String get activityUpdatedMcpToken => 'Обновил токен MCP';

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
  String get addGithubRepoPrompt =>
      'Добавьте хотя бы один репозиторий GitHub, чтобы видеть pull requests';

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
  String get allowGitPush => 'Разрешить git push';

  @override
  String get allowGithubApi => 'Разрешить вызовы GitHub API';

  @override
  String get allowNetwork => 'Разрешить общий доступ к сети';

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
  String get bugLabel => 'БАГ';

  @override
  String get bundledDefaultsNeverUpdated =>
      'Встроенные значения по умолчанию — не обновляются';

  @override
  String get cancel => 'Отмена';

  @override
  String get cancelEdit => 'Отменить правку';

  @override
  String get categoryCreation => 'Создание';

  @override
  String get categoryEditing => 'Редактирование';

  @override
  String get categoryNavigation => 'Навигация';

  @override
  String get categorySystem => 'Система';

  @override
  String get categoryView => 'Вид по категориям';

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
  String get configureDefaultRunners =>
      'Настройте адаптер и модель для новых пространств и генерации заголовков.';

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
  String get customCapabilitiesDescription =>
      'Описание пользовательских возможностей';

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
  String get defaultCapabilities =>
      'Возможности по умолчанию · новые пространства';

  @override
  String get defaultChat => 'Чат по умолчанию';

  @override
  String get defaultRunners => 'Раннеры по умолчанию';

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
  String get archiveConversation => 'Архивировать беседу';

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
  String get egPlatform => 'напр. macOS';

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
  String get gatesGithubPatPush =>
      'Ограничивает внедрение GitHub PAT. Нужно, чтобы агент мог выполнять push.';

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
  String get images => 'Изображения';

  @override
  String get inactive => 'Неактивно';

  @override
  String get install => 'Установить';

  @override
  String get installRequired => 'Требуется установка';

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
  String get keybindingAddARepositoryDescription => 'Добавить репозиторий';

  @override
  String get keybindingAddRepository => 'Добавить репозиторий';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Добавить или убрать закладку у выбранной статьи';

  @override
  String get keybindingCommandPalette => 'Палитра команд';

  @override
  String get keybindingCreateANewAgentDescription => 'Создать нового агента';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Создать новое рабочее пространство';

  @override
  String get keybindingFocusSearch => 'Перейти к поиску';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Перейти к полю поиска pull request';

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
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Открыть или закрыть всплывающий переключатель рабочих пространств на боковой панели';

  @override
  String get keybindingOpenPr => 'Открыть PR';

  @override
  String get keybindingOpenSettings => 'Открыть настройки';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Открыть настройки приложения';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Открыть палитру команд';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Открыть выбранную статью';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Открыть выбранный pull request';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Открыть выбранное рабочее пространство';

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
  String get keybindingRefreshAllFeedsDescription => 'Обновить все ленты';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Обновить список pull request';

  @override
  String get keybindingRescanForAdaptersDescription =>
      'Повторно найти адаптеры';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Выбрать следующую статью';

  @override
  String get keybindingSelectTheNextSpaceDescription =>
      'Выбрать следующее пространство';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Выбрать предыдущую статью';

  @override
  String get keybindingSelectThePreviousSpaceDescription =>
      'Выбрать предыдущее пространство';

  @override
  String get keybindingSendMessage => 'Отправить сообщение';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Отправить текущее сообщение';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Переключить светлую и тёмную тему';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Переключиться на восьмое рабочее пространство';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Переключиться на пятое рабочее пространство';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Переключиться на первое рабочее пространство';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Переключиться на четвёртое рабочее пространство';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Переключиться на следующее рабочее пространство';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Переключиться на девятое рабочее пространство';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Переключиться на предыдущее рабочее пространство';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Переключиться на второе рабочее пространство';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Переключиться на седьмое рабочее пространство';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Переключиться на шестое рабочее пространство';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Переключиться на третье рабочее пространство';

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
  String get keybindings => 'Сочетания клавиш';

  @override
  String get keybindingsDescription =>
      'Все сочетания клавиш. Их нельзя переназначить.';

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
  String get mcpAuthToken => 'Токен аутентификации MCP';

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
  String noShortcutsMatch(String query) {
    return 'Нет сочетаний клавиш по запросу «$query»';
  }

  @override
  String get noSystemFonts => 'Системные шрифты не обнаружены.';

  @override
  String get noTokenSet => 'Токен не задан — доступ не ограничен.';

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
      'Уведомлять о новых сообщениях агента в других пространствах.';

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
  String get readPrsIssuesMetadata =>
      'Позволяет агенту читать PR, issues и метаданные репозитория.';

  @override
  String get readerPreferences => 'Настройки чтения';

  @override
  String get reasoningEffort => 'Усилие рассуждения';

  @override
  String get recommendLabel => 'РЕКОМЕНДУЕМ';

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
  String repoAccessNoticeBody(String repos) {
    return 'Учётные данные GitHub на сервере не видят $repos. Если репозиторий принадлежит организации, установите GitHub App там или подключите токен с доступом.';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count репозитория недоступны',
      many: '$count репозиториев недоступны',
      few: '$count репозитория недоступны',
      one: 'Репозиторий недоступен',
    );
    return '$_temp0';
  }

  @override
  String get repoAccessNoticeSuspendedTitle =>
      'Установка GitHub App приостановлена';

  @override
  String repoAccessNoticeSuspendedBody(String repos) {
    return 'Показаны последние известные данные для $repos. Возобновите установку на GitHub или подключите токен с доступом.';
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
  String get runCompleted => 'Запуск завершён';

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
  String get sandboxPermissions => 'Права песочницы';

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
  String get searchGifsHint => 'Поиск GIF...';

  @override
  String get searchInDiffHint => 'Поиск в diff…';

  @override
  String get searchOrTypeModel => 'Найдите или введите имя модели…';

  @override
  String get searchPlaceholder => 'Поиск…';

  @override
  String get searchShortcuts => 'Поиск сочетаний клавиш…';

  @override
  String get shortcutUnavailableInBrowser => 'Недоступно в браузере';

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
  String get setToken => 'Задать токен';

  @override
  String get settingsLabel => 'Настройки';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageDescription => 'Выберите язык приложения.';

  @override
  String get shortTask => 'Короткая задача';

  @override
  String get showNativeNotifications =>
      'Показывать системные уведомления macOS для событий.';

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
  String get skillOriginRegistry => 'Реестр';

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
  String get suggestAChange => 'Предложить изменение';

  @override
  String get suggestLabel => 'ПРЕДЛОЖИТЬ';

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
  String get ticketLabel => 'ТИКЕТ';

  @override
  String get titleLabel => 'Название';

  @override
  String get todayLabel => 'Сегодня';

  @override
  String get toggleTheme => 'Переключить тему';

  @override
  String get tokenConfigured =>
      'Настроено — клиенты должны предъявлять этот токен.';

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
  String get updateKey => 'Обновить ключ';

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
  String get useWorkspaceDefault => 'По умолчанию рабочего пространства';

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
  String get whenOffNoDefaultRoute =>
      'Если выключено, песочница запускается без маршрута по умолчанию.';

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
  String get focusModeActiveTooltip =>
      'Режим фокуса активен — нажмите, чтобы завершить';

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
  String get pipelineStepBranch => 'Ветка';

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
      'Запускается через bash -c. Задаётся GITHUB_TOKEN. Плейсхолдеры подставляются до выполнения.';

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
  String get allowTicketingApi => 'Разрешить вызовы API тикетов';

  @override
  String get ticketingApiKey => 'API-ключ тикетов';

  @override
  String get ticketingApiKeySubtitle =>
      'Передаёт API-ключ провайдера тикетов в песочницу.';

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
  String get agentQuestionFreeformOptionHint => 'Опишите своими словами…';

  @override
  String get reviewRequested => 'Запрошено ревью';

  @override
  String get connectGitHubHint =>
      'Войдите в GitHub или добавьте токен в Настройки → Вы → Профиль и идентичность → Хостинг кода';

  @override
  String get connectGitHubToLoadPrs =>
      'Подключите GitHub, чтобы загружать pull request';

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
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count комментария к коду',
      many: '$count комментариев к коду',
      few: '$count комментария к коду',
      one: '$count комментарий к коду',
    );
    return '$_temp0';
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
  String get addAssignees => 'Добавить исполнителей';

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
  String get composePrNoRepo => 'Репозиторий GitHub не выбран';

  @override
  String get composePrNoRepoHint =>
      'Выберите рабочее пространство с репозиторием, связанным с GitHub, чтобы открыть pull request.';

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
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count встреч',
      many: '$count встреч',
      few: '$count встречи',
      one: '$count встреча',
      zero: 'Нет встреч',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'Открытые задачи';

  @override
  String get meetingsLedgerDecisions => 'Решения';

  @override
  String get meetingsLiveOpen => 'Открыть запись';

  @override
  String get meetingTemplateShort => 'Шаблон';

  @override
  String get meetingsStatThisWeek => 'На этой неделе';

  @override
  String get meetingsStatRecorded => 'Записано';

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
  String get meetingsEnhancedPill => 'улучшено';

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
  String get meetingDetectedRecord => 'Записать';

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
  String ideSourceControlViewPr(int number) {
    return 'Открыть pull request #$number';
  }

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
  String get mcpExternalServers => 'Внешние MCP-серверы';

  @override
  String get mcpExternalServersDescription =>
      'Подключение к внешним MCP-серверам (GitHub, Sentry, Postgres, автоматизация браузера). Серверы, настроенные для Claude, Cursor, VS Code и других инструментов, обнаруживаются автоматически.';

  @override
  String get mcpApprovalMode => 'Подтверждение инструментов';

  @override
  String get mcpApprovalModeDescription =>
      'Какие действия инструментов выполняются без запроса. Чтение всегда разрешено; более высокие уровни запрашивают подтверждение.';

  @override
  String get mcpApprovalAlwaysAsk => 'Всегда спрашивать';

  @override
  String get mcpApprovalWrite => 'Автоподтверждение записи';

  @override
  String get mcpApprovalYolo => 'Автоподтверждение всего';

  @override
  String get mcpNoExternalServers => 'Внешние MCP-серверы не обнаружены.';

  @override
  String get mcpAuthorize => 'Авторизовать';

  @override
  String get mcpReconnect => 'Переподключить';

  @override
  String get mcpExternalConnectionsNote =>
      'Внешние MCP-серверы работают на сервере агента (общий для компьютера и веба). Авторизация OAuth-серверов доступна только в настольном приложении.';

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
  String get usageAndCost => 'Использование и стоимость';

  @override
  String get usageAndCostDescription =>
      'Расходы по агентам за последние 7 дней по фактической стоимости запусков.';

  @override
  String get noUsageYet => 'Использование пока не зафиксировано.';

  @override
  String get spentThisWeek => 'потрачено на этой неделе';

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
  String get subscriptionUsagePartiallyAvailable => 'Частично доступно';

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
  String get syncEngineSectionTitle => 'Движок синхронизации';

  @override
  String get syncEngineDescription =>
      'Тикеты, сообщения и заметки обновляются в реальном времени небольшими инкрементальными изменениями, а не полными снимками. Выключение переключателя возвращает это хранилище к режиму полных снимков — перезагрузите приложение, чтобы изменение вступило в силу.';

  @override
  String get syncEngineTicketsTitle => 'Тикеты';

  @override
  String get syncEngineMessagingTitle => 'Сообщения';

  @override
  String get syncEngineNotesTitle => 'Заметки';

  @override
  String get syncEngineOnSubtitle =>
      'Включена живая инкрементальная синхронизация';

  @override
  String get syncEngineOffSubtitle =>
      'Используется синхронизация полными снимками';

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
  String get keybindingCreateANewSpaceDescription =>
      'Создать новое пространство';

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
  String provisioningRunningSetupScript(String repo) {
    return 'Запуск скрипта настройки для $repo…';
  }

  @override
  String get repoScriptsTitle => 'Скрипты';

  @override
  String get repoScriptsTooltip => 'Настроить скрипты жизненного цикла';

  @override
  String get repoScriptsSetupLabel => 'Скрипт настройки';

  @override
  String get repoScriptsSetupHelp =>
      'Запускается в рабочем дереве пространства сразу после создания — установка зависимостей, генерация файлов. При ошибке пространство помечается как сбойное; повтор запускает скрипт снова.';

  @override
  String get repoScriptsArchiveLabel => 'Скрипт архивации';

  @override
  String get repoScriptsArchiveHelp =>
      'Запускается непосредственно перед удалением рабочего дерева пространства — очистка ресурсов вне рабочего дерева. Ошибка не блокирует удаление.';

  @override
  String get repoScriptsEnvHelp =>
      'Запускается через bash из рабочего дерева; заданы CC_WORKSPACE_PATH (рабочее дерево), CC_ROOT_PATH (корень репозитория), CC_SPACE_ID, CC_SPACE_NAME и CC_REPO_NAME.';

  @override
  String get repoScriptsSetupPlaceholder => 'например, pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      'например, docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => 'Недавние запуски';

  @override
  String get repoScriptsNoRuns => 'Запусков пока нет';

  @override
  String get repoScriptsSaved => 'Скрипты сохранены';

  @override
  String get repoScriptsRunKindSetup => 'Настройка';

  @override
  String get repoScriptsRunKindArchive => 'Архивация';

  @override
  String get repoScriptsRunStatusRunning => 'Выполняется';

  @override
  String get repoScriptsRunStatusSucceeded => 'Успешно';

  @override
  String get repoScriptsRunStatusFailed => 'Ошибка';

  @override
  String get repoScriptsRunStatusTimedOut => 'Время истекло';

  @override
  String repoScriptsExitCode(int code) {
    return 'Код выхода $code';
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
  String get profileSectionLabel => 'Профиль';

  @override
  String get profileSectionDescription =>
      'Как вас видят коллеги и как вы указываетесь автором git-коммитов.';

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
  String get presenceAgentThinking => 'Думает';

  @override
  String get presenceAgentRunning => 'Выполняет';

  @override
  String get presenceAgentBlocked => 'Заблокирован';

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
  String get keybindingShowKeyboardShortcutsDescription =>
      'Показать шпаргалку сочетаний клавиш для текущего экрана';

  @override
  String get runPlaybookLabel => 'Запустить плейбук';

  @override
  String get playbooksLabel => 'Плейбуки';

  @override
  String get keybindingUndo => 'Отменить';

  @override
  String get keybindingRedo => 'Повторить';

  @override
  String get keybindingUndoLastActionDescription =>
      'Отменить последнее обратимое действие';

  @override
  String get keybindingRedoLastActionDescription =>
      'Повторить последнее отменённое действие';

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
  String get bannerMeetingJoin => 'Присоединиться';

  @override
  String get bannerMeetingRecordAndLink => 'Записать и привязать';

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
      'Местоположение определяется автоматически из этого рабочего пространства.';

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
  String get discussion =>
      'Переведены все 60 строк: ключи и плейсхолдеры сохранены, формулировки короткие и естественные для интерфейса.';

  @override
  String get chat =>
      'Готово: все 60 строк переведены на русский, ключи и плейсхолдеры без изменений.';

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
  String get copyTimestamp => 'Копировать метку времени';

  @override
  String get copiedTimestamp => 'Метка времени скопирована';

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
    return 'Упомяните бота в $provider, чтобы поставить агента на задачу, или создайте тикеты командой $command.';
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
    return 'Отправьте эту команду боту в $provider. Она сработает один раз и истечёт через 15 минут.';
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
  String get calendarUseBuiltinApp =>
      'Использовать приложение Google от Control Center';

  @override
  String get calendarUseBuiltinAppHint =>
      'Подтвердите доступ аккаунтом Google. Ничего настраивать в Google Cloud не нужно.';

  @override
  String get calendarUseOwnClient => 'Использовать свой клиент Google Cloud';

  @override
  String get calendarUseOwnClientHint =>
      'Укажите OAuth-клиент из своего проекта Google Cloud.';

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
  String get settingsScopeBadgeYou => 'ВЫ';

  @override
  String get settingsScopeBadgeDevice => 'ЭТО УСТРОЙСТВО';

  @override
  String get settingsScopeBadgeWorkspace => 'РАБОЧЕЕ ПРОСТРАНСТВО';

  @override
  String get settingsScopeBadgeServer => 'СЕРВЕР';

  @override
  String get settingsProfileDescription =>
      'Ваше имя, email и git-идентичность в коммитах, которые создаются от вашего имени.';

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
      'Идентичность, политика и соглашения, общие для всех в этом рабочем пространстве.';

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
  String get fromEnvironment => 'из окружения';

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
  String get webConnectTitle => 'Подключиться к Control Center';

  @override
  String get webConnectSubtitle =>
      'Подключитесь к запущенному cc-server по WebSocket. Ключ остаётся на этом устройстве.';

  @override
  String get webConnectServerLabel => 'Сервер';

  @override
  String get webConnectDeviceIdLabel => 'ID устройства';

  @override
  String get webConnectPairingKeyLabel => 'Ключ сопряжения';

  @override
  String get webConnectPairingKeyHint => 'вставьте PSK';

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
  String get conversationTitlesSectionTitle => 'Заголовки разговоров';

  @override
  String get conversationTitlesSectionCaption =>
      'Выберите раннер, который автоматически называет новые разговоры в этом рабочем пространстве. Заголовки выключены, пока не выбран адаптер, и действуют для всех участников.';

  @override
  String get conversationTitlesModelLabel => 'Модель заголовков';

  @override
  String get conversationTitlesAdapterLabel => 'Адаптер';

  @override
  String get conversationTitlesAdapterHint => 'Выкл.';

  @override
  String get conversationTitlesAdapterOff => 'Выкл.';

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
  String get signInNotFinished =>
      'Вход ещё не завершён. Завершите его в браузере, затем проверьте снова.';

  @override
  String get signedOutTitle => 'Вы вышли из аккаунта';

  @override
  String get signedOutSubtitle =>
      'Подключение к хостингу кода больше недействительно: токен истёк или доступ отозван. Остальное не изменилось: войдите снова, и всё будет на своих местах.';

  @override
  String get viaServerApp => 'через приложение этого сервера';

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
  String get addKey => 'Добавить ключ';

  @override
  String get providerApps => 'Приложения провайдера';

  @override
  String get providerAppsDescription =>
      'Как этот сервер аутентифицируется от своего имени и через что входит человек. Фоновая работа — вебхуки, опрос, синхронизация — идёт через приложение, а не через токен человека.';

  @override
  String get providerAppId => 'ID приложения';

  @override
  String get providerPrivateKey => 'Закрытый ключ';

  @override
  String get providerClientId => 'ID клиента';

  @override
  String get providerClientSecret => 'Секрет клиента';

  @override
  String get providerApiKey => 'API-ключ';

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
  String deviceCodeInstructions(String provider) {
    return 'Введите этот код на открывшейся странице $provider. Он скопирован в буфер обмена.';
  }

  @override
  String get deviceCodeWaiting => 'Ждём, пока вы завершите вход в браузере…';

  @override
  String get copyCodeAndOpen => 'Скопировать код и открыть';

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
  String get defaultChatDescription =>
      'Запускает новые беседы и любого агента без собственного раннера.';

  @override
  String get shortTaskDescription =>
      'Выполняет быструю фоновую работу: заголовки и сводки. Сюда подходит меньшая модель.';

  @override
  String get settingsStateFailed => 'Сбой';

  @override
  String get providerAppsGroupServer => 'В роли сервера';

  @override
  String get providerAppsGroupServerDescription =>
      'Позволяет фоновой работе обращаться к репозиториям без человека за запросом: вебхуки, опрос pull request, синхронизация тикетов.';

  @override
  String get providerAppsGroupPrConversations => 'Беседы в pull request';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'Как разработчики могут обращаться к этому серверу прямо на GitHub. Работает без вебхука и публичного URL — сервер сам опрашивает.';

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
  String get mcpNoTokenWarning =>
      'Без токена всё, что достучится до этого порта, сможет вызывать любой инструмент.';

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
  String get sandboxBackendFieldDescription =>
      'Авто выбирает самый сильный вариант, который поддерживает этот хост. Зафиксируйте один, чтобы он не менялся сам.';

  @override
  String get sandboxCapabilitiesDescription =>
      'Прорехи в границе. Каждая — то, что изолированный агент всё ещё может делать во внешнем мире.';

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
  String get archiveSpace => 'Архивировать пространство';

  @override
  String get archivedSpaces => 'Архивные пространства';

  @override
  String get archivedSpacesEmpty => 'Нет архивных пространств';

  @override
  String get restoreSpace => 'Восстановить';

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
  String get asideUnavailable =>
      'Чтобы это использовать, задайте one-shot модель в настройках рабочего пространства';

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
  String get repoScriptsTest => 'Тест';

  @override
  String get repoScriptsTestTooltip =>
      'Запустить этот черновик в одноразовом клоне репозитория';

  @override
  String get repoScriptsRunKindTest => 'Тест';

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
      'Снимков пока нет. Они создаются только по запросу — расписания нет.';

  @override
  String get backupSnapshotComplete => 'Полный';

  @override
  String get backupSnapshotIncomplete => 'Неполный';

  @override
  String get backupSnapshotIncompleteNote =>
      'Нет манифеста или в нём указаны отсутствующие файлы, поэтому этот снимок не восстановит всю установку. Файлы рабочих пространств, которые в нём есть, можно принять по одному.';

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
      'Это подключение идёт к серверу через ретранслятор, который не передаёт файлы. Подключитесь к серверу напрямую, чтобы скачать или загрузить резервную копию.';

  @override
  String get backupTransferForbidden =>
      'Сервер отказал. Для скачивания рабочего пространства нужна роль администратора, для восстановления — владельца, а для полного снимка — оператор установки.';

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
}
