// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get succeeded => 'Zakończono pomyślnie';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'Ponowna próba #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'Rozpoczynanie · $time';
  }

  @override
  String get agentActivityFollowingLive => 'Śledzenie aktywności na żywo';

  @override
  String get agentActivityJumpToLatest => 'Przejdź do najnowszych';

  @override
  String get agentActivityLoadFailed =>
      'Nie udało się wczytać aktywności tego uruchomienia';

  @override
  String get agentActivityNotRecorded =>
      'Dla tego uruchomienia nie zarejestrowano żadnej aktywności';

  @override
  String get agentActivityNotRecordedHint =>
      'Uruchomienia zakończone przed włączeniem rejestrowania aktywności nie mają osi czasu.';

  @override
  String get agentActivityRunUnavailable =>
      'To uruchomienie nie jest już dostępne';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'Podagent agenta $agent';
  }

  @override
  String get agentActivityUnsupported =>
      'Rejestrowanie aktywności jest niedostępne na połączonym serwerze';

  @override
  String get agentActivityUnsupportedHint =>
      'Uruchom aplikację ponownie, aby pobrała najnowszą wersję serwera.';

  @override
  String get agentActivityWaiting => 'Oczekiwanie na aktywność…';

  @override
  String get created => 'Utworzono';

  @override
  String get dictationStart => 'Rozpocznij dyktowanie';

  @override
  String get dictationListening => 'Nasłuchiwanie…';

  @override
  String get dictationUnavailable =>
      'Dyktowanie wymaga modelu głosowego na hoście serwera. Skonfiguruj go w ustawieniach głosu.';

  @override
  String get dictationFailedToStart => 'Nie udało się rozpocząć dyktowania';

  @override
  String get dictationHoldToTalkTitle => 'Przytrzymaj, aby mówić';

  @override
  String get dictationHoldToTalkDescription =>
      'Przytrzymaj przycisk mikrofonu lub skrót, aby dyktować, i puść, aby zatrzymać. Gdy wyłączone, naciśnij raz, aby rozpocząć, i ponownie, aby zatrzymać.';

  @override
  String get focusConversation => 'Przejdź do rozmowy';

  @override
  String get ideAgentActivity => 'Aktywność agenta';

  @override
  String get keybindingPushToTalk => 'Przyciśnij i mów';

  @override
  String get keybindingPushToTalkDescription =>
      'Przytrzymaj lub przełącz dyktowanie głosowe w polu pisania wiadomości';

  @override
  String get agentPermissions => 'Uprawnienia agentów';

  @override
  String get agentPermissionsSettingsDescription =>
      'Zdecyduj, co agenty mogą robić samodzielnie, o czym muszą najpierw zapytać i czego nie mogą robić nigdy — osobno dla obszaru roboczego, agenta i przestrzeni.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Ustaw decyzję dla każdego rodzaju efektu. Reguły kaskadują: przestrzeń nadpisuje agenta, agent nadpisuje obszar roboczy, a obszar roboczy nadpisuje preset trybu. Wygrywa najbardziej szczegółowa reguła.';

  @override
  String get guardrailLoading => 'Wczytywanie reguł…';

  @override
  String get guardrailRulesLoadFailed =>
      'Nie udało się wczytać reguł uprawnień.';

  @override
  String get guardrailScopeWorkspace => 'Obszar roboczy';

  @override
  String get guardrailScopeAgent => 'Agent';

  @override
  String get guardrailScopeSpace => 'Przestrzeń';

  @override
  String get guardrailSelectAgent => 'Wybierz agenta';

  @override
  String get guardrailSelectSpace => 'Wybierz przestrzeń';

  @override
  String get guardrailNoAgents =>
      'W tym obszarze roboczym nie ma jeszcze agentów.';

  @override
  String get guardrailNoSpaces =>
      'W tym obszarze roboczym nie ma jeszcze przestrzeni.';

  @override
  String get guardrailClassFileDelete => 'Usunięcie pliku';

  @override
  String get guardrailClassFileWriteOutsideWorktree =>
      'Zapis poza drzewem roboczym';

  @override
  String get guardrailClassGitCommit => 'Utworzenie commita';

  @override
  String get guardrailClassGitPush => 'Push do zdalnego repozytorium';

  @override
  String get guardrailClassPrCreate => 'Otwarcie pull requesta';

  @override
  String get guardrailClassPrPublish => 'Opublikowanie recenzji lub scalenie';

  @override
  String get guardrailClassVendorSyncWrite => 'Zapis do zewnętrznego trackera';

  @override
  String get guardrailClassNetworkEgress => 'Dostęp do sieci';

  @override
  String get guardrailClassSecretAccess => 'Odczyt sekretu';

  @override
  String get guardrailClassPackageInstall => 'Instalacja pakietu';

  @override
  String get guardrailClassProcessSpawn => 'Uruchomienie procesu';

  @override
  String get guardrailClassWorkspaceMutation =>
      'Zmiana struktury obszaru roboczego';

  @override
  String get guardrailClassEnclosureControl => 'Sterowanie rigiem';

  @override
  String get navRigs => 'Rigi';

  @override
  String get rigsUnsupportedServer =>
      'Ten serwer nie może hostować żadnych powierzchni rig. Sprawdź wymagania hosta dla komputera, którego chcesz użyć.';

  @override
  String get rigSurfaceComputer => 'Komputer';

  @override
  String get rigSurfaceBrowser => 'Przeglądarka';

  @override
  String get rigSurfaceAndroid => 'Android';

  @override
  String get rigSurfaceIosSimulator => 'Symulator iOS';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return 'Jednorazowa przeglądarka $engine, odizolowana od Twojego komputera. Otwórz drugą, aby porównać tę samą stronę obok siebie.';
  }

  @override
  String get rigPhaseReady => 'Gotowy';

  @override
  String get rigPhaseStarting => 'Uruchamianie';

  @override
  String get rigPhaseParked => 'Zaparkowany';

  @override
  String get rigPhaseClosing => 'Zamykanie';

  @override
  String get rigPhaseClosed => 'Zamknięty';

  @override
  String get rigPhaseFailed => 'Niepowodzenie';

  @override
  String get rigPhaseUnknown => 'Nieznany';

  @override
  String get rigNotAccelerated => 'Emulacja';

  @override
  String get rigAudioListen => 'Słuchaj maszyny';

  @override
  String get rigAudioMute => 'Wycisz maszynę';

  @override
  String get rigYouHaveControl => 'Masz kontrolę';

  @override
  String get rigBackendAvailable => 'Dostępny';

  @override
  String get rigBackendUnavailable => 'Niedostępny';

  @override
  String get rigEgressNotEnforced =>
      'W tym backendzie sieć nie jest odizolowana — maszyna sama zarządza swoją łącznością.';

  @override
  String get rigStartMachine => 'Uruchom maszynę';

  @override
  String get rigStartHint =>
      'Uruchamia jednorazową maszynę wirtualną współdzieloną przez Ciebie i Twoich agentów w tej rozmowie. Jest niszczona po zamknięciu, a nic w niej nie ma dostępu do Twojego komputera.';

  @override
  String get rigStartAndroidHint =>
      'Łączy się z emulatorem Androida, który jest już uruchomiony na serwerze. Dostęp do sieci nie jest odizolowany.';

  @override
  String get rigStartIosHint =>
      'Tworzy tymczasowy symulator iOS na serwerowym Macu. Jest usuwany po zamknięciu środowiska testowego; dostęp do sieci nie jest odizolowany.';

  @override
  String get rigStopMachine => 'Zatrzymaj maszynę';

  @override
  String get rigSurfaceUnavailable =>
      'Ten serwer nie może hostować tego rodzaju maszyny.';

  @override
  String get rigTabNeedsConversation =>
      'Najpierw otwórz rozmowę — maszyna należy do rozmowy, dzięki czemu Ty i Twoi agenci widzicie ten sam ekran.';

  @override
  String get ideMenuSectionTools => 'Narzędzia';

  @override
  String get ideMenuSectionMachines => 'Maszyny';

  @override
  String get ideMenuSectionReopen => 'Otwórz ponownie';

  @override
  String get ideMenuSearchHint => 'Szukaj';

  @override
  String get ideMenuNoMatches => 'Brak dopasowań';

  @override
  String get rigMenuComputer => 'Komputer';

  @override
  String get rigMenuBrowser => 'Przeglądarka';

  @override
  String get rigMenuAndroid => 'Android';

  @override
  String get rigMenuIosSimulator => 'Symulator iOS';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return 'Zamknąć $name?';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'Maszyna będzie działać w tle — możesz ją ponownie otworzyć w każdej chwili z paska bocznego. Wyłącz ją całkowicie, aby natychmiast zwolnić pamięć.';

  @override
  String get ideCloseKeepBodyShell =>
      'Polecenie będzie działać w tle — powłokę możesz ponownie otworzyć w każdej chwili z paska bocznego. Zakończ ją, aby natychmiast przerwać wykonywane czynności.';

  @override
  String get ideCloseKeepBodyAgent =>
      'Agent będzie pracował w tle — rozmowę możesz ponownie otworzyć w każdej chwili z paska bocznego. Zatrzymaj go, aby natychmiast zakończyć uruchomienie.';

  @override
  String get ideCloseKeepRunning => 'Pozostaw w tle';

  @override
  String get ideCloseShutDownMachine => 'Wyłącz';

  @override
  String get ideCloseEndShell => 'Zakończ powłokę';

  @override
  String get ideCloseStopAgent => 'Zatrzymaj agenta';

  @override
  String get rigsSettingsSubtitle =>
      'Co ten serwer potrafi uruchomić, potrzebne obrazy podstawowe i maszyny działające teraz';

  @override
  String get rigsCapabilitiesTitle => 'Ten serwer';

  @override
  String get rigInstallIosAutomation => 'Zainstaluj most automatyzacji iOS';

  @override
  String get rigInstallingIosAutomation =>
      'Instalowanie mostu automatyzacji iOS…';

  @override
  String get rigIosAutomationInstalled =>
      'Most automatyzacji iOS został zainstalowany';

  @override
  String get rigsImagesTitle => 'Obrazy podstawowe';

  @override
  String get rigsImagesHint =>
      'Każdy rig uruchamia się z jednego z tych obrazów tylko do odczytu. Każda sesja zapisuje do jednorazowej warstwy, więc jeden rig nigdy nie zmieni stanu wyjściowego kolejnego.';

  @override
  String get rigsRunningTitle => 'Działające teraz';

  @override
  String get rigsNoneRunning => 'Żadna maszyna nie działa.';

  @override
  String get rigsCustomImagesTitle =>
      'Obrazy niestandardowe (ten obszar roboczy)';

  @override
  String get rigsCustomImagesHint =>
      'Wskaż Terminalowi (VM) lub Przeglądarce (VM) własny obraz — rozszerz domyślne o narzędzia potrzebne Twojemu projektowi albo użyj dowolnego zgodnego z rejestru. Nowe maszyny będą go używać; działające zachowają własne. Zobacz przewodnik rigów, aby dowiedzieć się, co musi zawierać obraz.';

  @override
  String get rigsCustomTerminalImageLabel => 'Obraz terminala (VM)';

  @override
  String get rigsCustomBrowserImageLabel => 'Obraz przeglądarki (VM)';

  @override
  String get rigsCustomImagePlaceholder =>
      'np. ghcr.io/acme/dev-shell:1.2 — zostaw puste, aby użyć domyślnego';

  @override
  String get rigsCustomImageInvalid =>
      'Wpisz odniesienie do rejestru, np. repo/name:tag. Ścieżki lokalne i archiwa są niedozwolone.';

  @override
  String get rigsCustomImageSaved =>
      'Zapisano. Nowe maszyny uruchamiają ten obraz; działające zachowują swoje.';

  @override
  String get rigsEgressTitle =>
      'Ruch wychodzący przeglądarki (ten obszar roboczy)';

  @override
  String get rigsEgressHint =>
      'Dodatkowe hosty, z którymi zamknięta przeglądarka może się łączyć — po jednym w wierszu: dokładny host (api.example.com) lub symbol wieloznaczny dla jego subdomen (*.example.com). Witryna produktu pozostaje dozwolona w każdym przypadku. Nowe maszyny otrzymają tę listę; działające zachowują tę, z którą wystartowały.';

  @override
  String rigsEgressInvalid(String host) {
    return '„$host” nie jest prawidłowym wpisem hosta.';
  }

  @override
  String get rigsEgressSaved =>
      'Zapisano. Nowe maszyny przeglądarki przyjmą te hosty; działające zachowują swoje.';

  @override
  String get rigImageInstalled => 'Zainstalowany';

  @override
  String get rigImageNotDownloaded => 'Niepobrany';

  @override
  String get rigImageNotPublished => 'Nieopublikowany';

  @override
  String get rigImageNotPublishedHint =>
      'Nie opublikowano jeszcze żadnego obrazu, więc nie ma czego pobierać. Zaimportuj zgodny obraz dysku, aby to włączyć.';

  @override
  String get rigImageDownload => 'Pobierz';

  @override
  String get rigImageDownloading => 'Pobieranie…';

  @override
  String get rigImageImport => 'Importuj';

  @override
  String get rigImageImportMessage =>
      'Ścieżka do obrazu dysku qcow2 w systemie plików serwera. Jest kopiowany do magazynu obrazów, więc plik można później przenieść.';

  @override
  String get rigConnectingStream => 'Łączenie z rigiem';

  @override
  String get rigStreamNotAllowed => 'Nie masz dostępu do tego riga.';

  @override
  String get rigStreamNotRunning => 'Ten rig już nie działa.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'Podgląd na żywo wymaga ffmpeg na tym hoście. Zainstaluj ffmpeg i otwórz kartę ponownie.';

  @override
  String get rigStreamEnded => 'Podgląd na żywo został zakończony.';

  @override
  String get rigStreamFailed => 'Nie udało się otworzyć podglądu na żywo.';

  @override
  String get rigStreamDisconnected => 'Brak połączenia z serwerem.';

  @override
  String rigDropSendingOne(String name) {
    return 'Kopiowanie „$name” do maszyny…';
  }

  @override
  String rigDropSendingMany(int count) {
    return 'Kopiowanie $count plików do maszyny…';
  }

  @override
  String get rigTerminalDropSending => 'Kopiowanie do maszyny…';

  @override
  String get rigTerminalPasteImage => 'Wklejony obraz zapisany w maszynie';

  @override
  String get rigPortsTitle => 'Przekierowane porty';

  @override
  String get rigPortsTooltip => 'Porty otwarte w tej maszynie';

  @override
  String get rigPortsEmpty =>
      'Niczego jeszcze nie nasłuchuje. Uruchom serwer w terminalu — serwer deweloperski na porcie 3000 pojawi się tutaj.';

  @override
  String get rigPortsAdd => 'Dodaj port';

  @override
  String get rigPortsAddHint => 'Port gościa do przekierowania (np. 3000)';

  @override
  String get rigPortsAutoForward => 'Automatyczne przekierowywanie portów';

  @override
  String get rigPortsCopyUrl => 'Kopiuj lokalny adres URL';

  @override
  String rigPortsCopiedUrl(String url) {
    return 'Skopiowano $url';
  }

  @override
  String get rigPortsStopForward => 'Zatrzymaj przekierowywanie';

  @override
  String get rigPortsExposeLan => 'Udostępnij w sieci lokalnej';

  @override
  String get rigPortsLanPrivate => 'Tylko lokalnie';

  @override
  String get rigPortsLanShared => 'W sieci';

  @override
  String get rigPortsSetDomain => 'Ustaw domenę przeglądarki (.test)';

  @override
  String get rigPortsDomainHint =>
      'Domena przeglądarki (VM), np. myapp.test — osiągalna tam, nie na hoście';

  @override
  String get rigPortsProcessUnknown => 'nieznany proces';

  @override
  String get rigPortsInactive => 'nie nasłuchuje';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count obrazu podstawowego jeszcze do pobrania',
      many: '$count obrazów podstawowych jeszcze do pobrania',
      few: '$count obrazy podstawowe jeszcze do pobrania',
      one: '$count obraz podstawowy jeszcze do pobrania',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'Zezwól';

  @override
  String get guardrailDecisionPrompt => 'Zapytaj najpierw';

  @override
  String get guardrailDecisionDeny => 'Odmów';

  @override
  String get guardrailSourceThisScope => 'Ten zakres';

  @override
  String get guardrailSourceDefault => 'Wbudowana wartość domyślna';

  @override
  String get guardrailSourcePreset => 'Preset trybu';

  @override
  String get guardrailSourceInherited => 'Odziedziczone';

  @override
  String get guardrailClearToInherited => 'Przywróć odziedziczone';

  @override
  String get guardrailWhatIf => 'A co jeśli?';

  @override
  String get guardrailWhatIfDescription =>
      'Zobacz, jak bieżące reguły rozstrzygnęłyby akcję, według tej samej logiki, którą stosują agenty.';

  @override
  String get guardrailProbeActionLabel => 'Akcja';

  @override
  String get guardrailProbeCommandLabel => 'Polecenie (opcjonalnie)';

  @override
  String get guardrailProbeCommandHint => 'np. git push origin main';

  @override
  String get guardrailProbeAgentLabel => 'Agent (opcjonalnie)';

  @override
  String get guardrailProbeSpaceLabel => 'Przestrzeń (opcjonalnie)';

  @override
  String get guardrailProbeNone => 'Brak';

  @override
  String get guardrailProbeModeLabel => 'Tryb';

  @override
  String get guardrailProbeResult => 'Wynik';

  @override
  String get guardrailProbeSource => 'Źródło:';

  @override
  String get guardrailAdapterMatrix => 'Gdzie reguły są egzekwowane';

  @override
  String get guardrailAdapterMatrixDescription =>
      'Uczciwe odniesienie: gdzie każdy efekt jest faktycznie przechwytywany, w podziale na runnery agentów. To dokumentacja rzeczywistości, nie gwarancja — efektów wykonywanych przez runner poza tym kanałem nie da się przechwycić.';

  @override
  String get guardrailEffectColumn => 'Efekt';

  @override
  String get guardrailAdapterHarness => 'Wbudowany harness';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'Minimum sandboxa';

  @override
  String get guardrailEnforcementPolicyGate => 'Bramka reguł';

  @override
  String get guardrailEnforcementSandbox => 'Tylko sandbox';

  @override
  String get guardrailEnforcementNone => 'Niewymuszalne';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'Decyzja uprawnień jest sprawdzana przed wykonaniem efektu i może go zablokować.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'Ogranicza go tylko sandbox; reguła uprawnień nie jest brana pod uwagę.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'Decyzja ma charakter wyłącznie doradczy — nie da się jej tutaj przechwycić.';

  @override
  String get obsStatCost => 'koszt';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount oddelegowane';
  }

  @override
  String get obsStatDuration => 'czas trwania';

  @override
  String get obsStatTokens => 'tokeny';

  @override
  String get obsStatTools => 'narzędzia';

  @override
  String get openAgentActivity => 'Otwórz aktywność';

  @override
  String get orgChart => 'Schemat organizacyjny';

  @override
  String get orgChartEmpty => 'Brak agentów';

  @override
  String get navCalendar => 'Kalendarz';

  @override
  String get serverConnection => 'Połączenie z serwerem';

  @override
  String get serverModeLocal => 'Uruchom w tej aplikacji';

  @override
  String get serverModeLocalDescription =>
      'Control Center uruchamia własny serwer na tym komputerze i przechowuje Twoje dane lokalnie.';

  @override
  String get serverModeRemote => 'Połącz ze zdalną instancją';

  @override
  String get serverModeRemoteDescription =>
      'Połącz z serwerem Control Center działającym gdzie indziej. Twoje dane znajdują się na tym serwerze.';

  @override
  String get serverRemoteUrl => 'Adres URL serwera';

  @override
  String get serverRemoteDeviceId => 'Identyfikator urządzenia';

  @override
  String get serverRemotePairingKey => 'Klucz parowania';

  @override
  String get serverRemotePairingKeyHint =>
      'Wklej klucz parowania ze zdalnego serwera';

  @override
  String get serverSetupInviteCode => 'Kod zaproszenia';

  @override
  String get serverSetupInviteCodeHint =>
      'Wklej jednorazowy kod zaproszenia (zostaw puste, aby użyć klucza parowania)';

  @override
  String get serverDiscoveryTooltip => 'Znajdź serwery w Twojej sieci';

  @override
  String get serverDiscoveryTitle => 'Serwery w Twojej sieci';

  @override
  String get serverDiscoverySearching => 'Wyszukiwanie serwerów…';

  @override
  String get serverDiscoveryEmpty =>
      'Nie znaleziono serwerów. Sprawdź, czy serwer działa i czy to urządzenie może się z nim połączyć, a potem wyszukaj ponownie.';

  @override
  String get serverDiscoveryRefresh => 'Wyszukaj ponownie';

  @override
  String get serverListActive => 'Aktywny';

  @override
  String get serverListSwitch => 'Przełącz';

  @override
  String get serverListAddTitle => 'Dodaj serwer';

  @override
  String get serverListRemoveActiveHint =>
      'Przełącz się na inny serwer przed usunięciem tego.';

  @override
  String get serverSwitchFailedTitle => 'Nie udało się przełączyć serwera';

  @override
  String get serverListInsecureBadge => 'Niezabezpieczone';

  @override
  String get connectionPathLocal => 'Lokalnie';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'Wyłączanie';

  @override
  String get shutdownSubtitle => 'Zamykanie lokalnego serwera';

  @override
  String get shutdownServiceApprovals => 'Zatwierdzenia';

  @override
  String get shutdownServiceBackgroundJobs => 'Zadania w tle';

  @override
  String get shutdownServiceScheduler => 'Harmonogram zadań';

  @override
  String get shutdownServiceCalendar => 'Synchronizacja kalendarza';

  @override
  String get shutdownServiceWeather => 'Pogoda';

  @override
  String get shutdownServiceSoundscape => 'Pejzaż dźwiękowy';

  @override
  String get shutdownServiceMeetings => 'Spotkania';

  @override
  String get shutdownServiceVoiceModels => 'Modele głosowe';

  @override
  String get shutdownServiceNetworking => 'Sieć';

  @override
  String get shutdownServicePresence => 'Obecność';

  @override
  String get shutdownServiceDataSync => 'Synchronizacja danych';

  @override
  String get shutdownServiceDeviceRelay => 'Relay urządzeń';

  @override
  String get shutdownServiceMcpConnections => 'Połączenia MCP';

  @override
  String get shutdownServiceCodeEditors => 'Edytory kodu';

  @override
  String get serverSharingTitle => 'Udostępnij ten serwer';

  @override
  String get serverSharingDescription =>
      'Spraw, by ten serwer był osiągalny z Twoich innych urządzeń. Nic nie jest wystawiane publicznie, chyba że włączysz tunel poniżej. Zaproszenia parowania automatycznie osadzają bieżące adresy serwera — twórz je w ustawieniach obszaru roboczego.';

  @override
  String get serverSharingUnavailable =>
      'Sterowanie udostępnianiem nie jest dostępne na tym serwerze.';

  @override
  String get serverSharingMdnsLabel => 'Wykrywanie w LAN';

  @override
  String get serverSharingMdnsOn =>
      'Ogłaszanie tego serwera w sieci lokalnej (mDNS)';

  @override
  String get serverSharingMdnsOff => 'Brak ogłaszania w sieci lokalnej (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'Tunel';

  @override
  String get serverSharingTunnelHelper =>
      'Włączenie tunelu sprawia, że ten serwer jest osiągalny z internetu. Publiczna ekspozycja jest opcjonalna i domyślnie wyłączona.';

  @override
  String get serverSharingProviderOff => 'Wyłączony';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'Publiczny adres URL';

  @override
  String get serverSharingTunnelStarting => 'Uruchamianie tunelu…';

  @override
  String serverSharingTunnelError(String error) {
    return 'Błąd tunelu: $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'Tunel działa. Osiągniesz go pod skonfigurowaną nazwą DNS.';

  @override
  String get serverSharingRelayLabel => 'Relay';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'Retransmitowano w tym miesiącu: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'Aktywne sesje relay: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle =>
      'Nie udało się zaktualizować udostępniania';

  @override
  String get pairNewClient => 'Sparuj nowego klienta';

  @override
  String get pairClientNameHint => 'Nazwij tego klienta (np. Laptop służbowy)';

  @override
  String get pairClientTypeWeb => 'Przeglądarka internetowa';

  @override
  String get pairClientTypeDesktop => 'Aplikacja desktopowa';

  @override
  String get pairClientTypePhone => 'Telefon';

  @override
  String get pairAction => 'Sparuj';

  @override
  String get revoke => 'Cofnij';

  @override
  String get pairCredentialsIntro =>
      'Połącz nowego klienta tymi danymi albo otwórz w nim ten link.';

  @override
  String get pairLinkLabel => 'Link';

  @override
  String get pairScanQr =>
      'Zeskanuj ten kod QR aparatem telefonu, aby go sparować.';

  @override
  String get pairServerUnreachableTitle => 'Nieosiągalny';

  @override
  String get pairServerUnreachable =>
      'Inne urządzenia nie mogą połączyć się z tym serwerem bezpośrednio, więc nowy klient nie może się połączyć. Ustaw publiczny adres URL serwera, aby sparować więcej klientów.';

  @override
  String get serverSetupTitle => 'Jak ma działać Control Center?';

  @override
  String get serverSetupSubtitle =>
      'Control Center potrzebuje serwera, który jest właścicielem Twoich danych. Uruchom go w tej aplikacji albo połącz się z instancją działającą gdzie indziej.';

  @override
  String get serverSetupRunLocal => 'Uruchom w tej aplikacji';

  @override
  String get serverSetupConnect => 'Połącz';

  @override
  String get serverSetupInvalidUrl =>
      'Wpisz prawidłowy adres URL serwera (ws:// lub wss://).';

  @override
  String get serverSetupCouldNotConnect => 'Nie udało się połączyć';

  @override
  String get serverSetupErrorUnreachable =>
      'Nie mogliśmy połączyć się z serwerem. Sprawdź, czy działa i czy to urządzenie może się z nim połączyć (ta sama sieć lub relay).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'Tożsamość serwera nie zgadza się z zapisaną na tym urządzeniu. Jeśli serwer został przeinstalowany lub zresetowany, usuń zapisany serwer i sparuj ponownie.';

  @override
  String get serverSetupErrorAuthRejected =>
      'Serwer odrzucił to urządzenie. Sprawdź, czy klucz parowania i identyfikator urządzenia zgadzają się z wydanymi przez serwer.';

  @override
  String get serverSetupErrorInviteRejected =>
      'Ten kod zaproszenia jest nieprawidłowy lub wygasł. Poproś o nowy.';

  @override
  String get serverSetupErrorGeneric =>
      'Coś poszło nie tak podczas łączenia. Rozwiń szczegóły techniczne poniżej, aby uzyskać więcej informacji.';

  @override
  String get serverSetupErrorDetails => 'Szczegóły techniczne';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Jeszcze $count',
      many: 'Jeszcze $count',
      few: 'Jeszcze $count',
      one: 'Jeszcze $count',
    );
    return '$_temp0';
  }

  @override
  String get calendarAllDayGutter => 'Całodniowe';

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wydarzenia',
      many: '$count wydarzeń',
      few: '$count wydarzenia',
      one: '$count wydarzenie',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => 'Zwiń wydarzenia całodniowe';

  @override
  String get calendarExpandAllDay => 'Rozwiń wydarzenia całodniowe';

  @override
  String get calendarViewMonth => 'Miesiąc';

  @override
  String get calendarViewWeek => 'Tydzień';

  @override
  String get calendarViewAgenda => 'Agenda';

  @override
  String get calendarConnectGoogle => 'Połącz Kalendarz Google';

  @override
  String get calendarConnectDescription =>
      'Zsynchronizuj Kalendarz Google, aby widzieć tutaj wydarzenia i otrzymywać alerty przed rozpoczęciem spotkań.';

  @override
  String get calendarDisconnect => 'Rozłącz';

  @override
  String get calendarReconnect => 'Połącz ponownie';

  @override
  String get calendarEmptyNoEvents => 'Brak wydarzeń w tym zakresie';

  @override
  String get calendarStartRecording => 'Rozpocznij nagrywanie';

  @override
  String get calendarStartRecordingAndLink => 'Rozpocznij nagrywanie i powiąż';

  @override
  String get calendarJoinMeet => 'Dołącz do spotkania';

  @override
  String get calendarFromCalendar => 'Z kalendarza';

  @override
  String get calendarLinkedMeeting => 'Powiązane spotkanie';

  @override
  String get calendarToday => 'Dziś';

  @override
  String get calendarAllDay => 'Cały dzień';

  @override
  String calendarWeekNumber(int number) {
    return 'Tydzień $number';
  }

  @override
  String get calendarPreviousPeriod => 'Poprzedni';

  @override
  String get calendarNextPeriod => 'Następny';

  @override
  String calendarLastSynced(String time) {
    return 'Zsynchronizowano $time';
  }

  @override
  String get calendarNeverSynced => 'Jeszcze nie zsynchronizowano';

  @override
  String get calendarSyncing => 'Synchronizowanie…';

  @override
  String get calendarViewDay => 'Dzień';

  @override
  String get calendarShow => 'Pokaż';

  @override
  String get calendarHide => 'Ukryj';

  @override
  String get calendarRsvpGoing => 'Idziesz?';

  @override
  String get calendarRsvpYes => 'Tak';

  @override
  String get calendarRsvpNo => 'Nie';

  @override
  String get calendarRsvpMaybe => 'Może';

  @override
  String get calendarRsvpFailed => 'Nie udało się zaktualizować odpowiedzi';

  @override
  String get calendarAddAccount => 'Dodaj konto kalendarza';

  @override
  String get calendarSettingsTitle => 'Kalendarz Google';

  @override
  String get calendarSettingsDescription =>
      'Połącz konto Google, aby synchronizować wydarzenia do tego obszaru roboczego.';

  @override
  String get calendarConnecting => 'Łączenie…';

  @override
  String get calendarSyncNow => 'Synchronizuj teraz';

  @override
  String get calendarNoWorkspace =>
      'Wybierz obszar roboczy, aby wyświetlić jego kalendarz';

  @override
  String get calendarConnectError =>
      'Nie udało się połączyć z Kalendarzem Google';

  @override
  String get calendarClientIdLabel => 'Identyfikator klienta';

  @override
  String get calendarClientSecretLabel => 'Sekret klienta';

  @override
  String get calendarConnectCredsHint =>
      'Wpisz identyfikator klienta i sekret klienta typu kod urządzenia Google OAuth dla swojego projektu. Połączenie i synchronizację obsługuje serwer — Twoja przeglądarka nigdy nie przechowuje tokenów.';

  @override
  String get calendarConnectApproveInstruction =>
      'Otwórz stronę weryfikacji na dowolnym urządzeniu, zaloguj się i wpisz ten kod:';

  @override
  String get calendarConnectOpenPage => 'Otwórz stronę weryfikacji';

  @override
  String get calendarConnectWaiting => 'Oczekiwanie na zatwierdzenie…';

  @override
  String get calendarConnectDenied =>
      'Autoryzacja została odrzucona. Spróbuj ponownie.';

  @override
  String get calendarConnectExpired => 'Kod wygasł. Spróbuj ponownie.';

  @override
  String get notificationMeetingStartsSoon =>
      'Spotkanie wkrótce się rozpocznie';

  @override
  String get notifyMeetingStartsSoon =>
      'Gdy spotkanie z kalendarza ma się wkrótce rozpocząć';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Kalendarz rozłączony';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Połącz ponownie $email, aby wznowić synchronizację';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Połącz ponownie kalendarz, aby wznowić synchronizację';

  @override
  String get notifyCalendarAuthExpired =>
      'Gdy konto kalendarza wymaga ponownego połączenia';

  @override
  String get notificationRigStatusChanged => 'Aktualizacje rigów';

  @override
  String get notifyRigStatusChanged =>
      'Gdy rig zostanie przejęty, odzyskany lub ulegnie awarii';

  @override
  String get notificationRigTakenOver => 'Rig przejęty';

  @override
  String get notificationRigTakenOverBody =>
      'Osoba steruje maszyną; agent może obserwować, ale nie działać.';

  @override
  String get notificationRigReleased => 'Zwolniono kontrolę nad rigiem';

  @override
  String get notificationRigReleasedBody => 'Agent odzyskał maszynę.';

  @override
  String get notificationRigReclaimed => 'Rig odzyskany';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'Był bezczynny, więc maszyna została zamknięta, aby zwolnić pamięć.';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'Osiągnął limit czasu i został zamknięty.';

  @override
  String get notificationRigFailed => 'Awaria riga';

  @override
  String get notificationRigFailedBody =>
      'Hiperwizor pod nim przestał działać. Otwórz maszynę ponownie, aby kontynuować.';

  @override
  String get calendarAlertLeadTime => 'Czas wyprzedzenia alertu';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'Jak wcześnie przed spotkaniem Cię powiadomić';

  @override
  String calendarConnectedAs(String email) {
    return 'Połączono jako $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count uczestników';
  }

  @override
  String get calendarEventLabel => 'Wydarzenie';

  @override
  String get calendarRecurring => 'Wydarzenie cykliczne';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Organizator';

  @override
  String get calendarYou => 'Ty';

  @override
  String get calendarShowFewer => 'Pokaż mniej';

  @override
  String get calendarRsvpAwaiting => 'Oczekuje';

  @override
  String calendarParticipantsCount(int count) {
    return '$count uczestników';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'Zobacz wszystkich $count uczestników';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count tak';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count nie';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count może';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count oczekuje';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count min';
  }

  @override
  String get openInEditorPrompt => 'Otworzyć w którym edytorze?';

  @override
  String get ideNotInstalled => 'Niezainstalowany';

  @override
  String openInIde(String editor) {
    return 'Otwórz w $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'Nie udało się otworzyć w $editor: $error';
  }

  @override
  String get profileSearchHint => 'Szukaj pull requestów…';

  @override
  String get stopAgentRun => 'Zatrzymaj uruchomienie';

  @override
  String get stopAgentRunConfirm =>
      'Zatrzymać to uruchomienie? Praca w toku zostanie utracona.';

  @override
  String get inProgress => 'W toku';

  @override
  String get drafts => 'Szkice';

  @override
  String get sortOldest => 'Najstarsze';

  @override
  String get sortLargest => 'Największe';

  @override
  String get prFilterTooltip => 'Filtruj';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktywnego filtra',
      many: '$count aktywnych filtrów',
      few: '$count aktywne filtry',
      one: '$count aktywny filtr',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'Dodaj filtr…';

  @override
  String get prFilterFieldHint => 'Filtruj…';

  @override
  String get prFilterCategoryStatus => 'Status';

  @override
  String get prFilterCategoryAuthor => 'Autor';

  @override
  String get prFilterCategoryReviewer => 'Recenzenci';

  @override
  String get prFilterCategoryContent => 'Treść';

  @override
  String get prFilterCategoryRepoOwner => 'Właściciel repozytorium';

  @override
  String get prFilterCategoryRepoName => 'Nazwa repozytorium';

  @override
  String get prFilterCategoryOpenedDate => 'Data otwarcia';

  @override
  String get prFilterCategoryUpdatedDate => 'Data aktualizacji';

  @override
  String get prFilterQuickToReview => 'Szybkie do zrecenzowania';

  @override
  String get prFilterClearAll => 'Wyczyść filtry';

  @override
  String prFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requesta',
      many: '$count pull requestów',
      few: '$count pull requesty',
      one: '$count pull request',
    );
    return '$_temp0';
  }

  @override
  String prFilterHiddenOptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opcji niepasujących do żadnego pull requesta',
      many: '$count opcji niepasujących do żadnego pull requesta',
      few: '$count opcje niepasujące do żadnego pull requesta',
      one: '$count opcja niepasująca do żadnego pull requesta',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'Tytuł lub treść zawiera…';

  @override
  String get prFilterNoOptions => 'Brak pasujących opcji';

  @override
  String get prFilterChipIs => 'jest';

  @override
  String get prFilterChipIsAnyOf => 'jest jednym z';

  @override
  String get prFilterChipContains => 'zawiera';

  @override
  String get prFilterChipSince => 'od';

  @override
  String get prFilterAddFilterButton => 'Dodaj filtr';

  @override
  String prFilterClearCategory(String category) {
    return 'Wyczyść filtr $category';
  }

  @override
  String get prFilterCurrentUser => 'Bieżący użytkownik';

  @override
  String get prStatusDraft => 'Szkic';

  @override
  String get prStatusOpen => 'Otwarty';

  @override
  String get prStatusInReview => 'W recenzji';

  @override
  String get prStatusChangesRequested => 'Zażądano zmian';

  @override
  String get prStatusApproved => 'Zatwierdzony';

  @override
  String get prStatusMerged => 'Scalony';

  @override
  String get prStatusClosed => 'Zamknięty';

  @override
  String get prDateWindowDay => '1 dzień temu';

  @override
  String get prDateWindowThreeDays => '3 dni temu';

  @override
  String get prDateWindowWeek => 'Tydzień temu';

  @override
  String get prDateWindowMonth => 'Miesiąc temu';

  @override
  String get prDateWindowThreeMonths => '3 miesiące temu';

  @override
  String get prDateWindowSixMonths => '6 miesięcy temu';

  @override
  String get prDateWindowYear => 'Rok temu';

  @override
  String get prDisplayOptions => 'Opcje wyświetlania';

  @override
  String get prDisplayGrouping => 'Grupowanie';

  @override
  String get prDisplayOrdering => 'Sortowanie';

  @override
  String get prDisplayShowDrafts => 'Pokaż szkice';

  @override
  String get prDisplayMergedWindow => 'Zakres scalonych';

  @override
  String get prDisplayMergedWindowDay => 'Ostatni dzień';

  @override
  String get prDisplayMergedWindowWeek => 'Ostatni tydzień';

  @override
  String get prDisplayMergedWindowMonth => 'Ostatni miesiąc';

  @override
  String get prDisplayProperties => 'Właściwości wyświetlania';

  @override
  String get prGroupingRepository => 'Repozytorium';

  @override
  String get prGroupingAuthor => 'Autor';

  @override
  String get prGroupingStatus => 'Status';

  @override
  String get prGroupingNone => 'Bez grupowania';

  @override
  String get prPropertyRepository => 'Repozytorium';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'Gałąź';

  @override
  String get prPropertyUpdated => 'Zaktualizowano';

  @override
  String get prPropertyAuthor => 'Autor';

  @override
  String get prPropertyChecks => 'Sprawdzenia';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'Komentarze';

  @override
  String get keybindingOpenFilterMenu => 'Otwórz menu filtrów';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'Otwórz menu filtrów pull requestów';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wybranych',
      many: '$count wybranych',
      few: '$count wybrane',
      one: '$count wybrany',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'Podsumowanie';

  @override
  String get kbMove => 'przenoszenie';

  @override
  String get kbTabs => 'karty';

  @override
  String get kbSearch => 'wyszukiwanie';

  @override
  String get kbViewed => 'wyświetlone';

  @override
  String get kbCollapse => 'zwijanie';

  @override
  String get appearance => 'Wygląd';

  @override
  String get appearanceSettingsDescription => 'Motyw, język i typografia.';

  @override
  String get notificationsSettingsDescription =>
      'Wybierz, które zdarzenia agentów i obszarów roboczych Cię powiadamiają.';

  @override
  String get advanced => 'Zaawansowane';

  @override
  String get accounts => 'Konta';

  @override
  String get mcpServers => 'Serwery MCP';

  @override
  String get mcpServersSettingsDescription =>
      'Wbudowany serwer MCP i zewnętrzne serwery MCP.';

  @override
  String get remoteControlAndDevices => 'Sterowanie zdalne i urządzenia';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'Sparuj telefony i skonfiguruj serwer zdalnego sterowania.';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'Modele mowy i diaryzacji hostowane przez ten serwer.';

  @override
  String get needsSetupLabel => 'Wymaga konfiguracji';

  @override
  String get collapseSidebar => 'Zwiń pasek boczny';

  @override
  String get expandSidebar => 'Rozwiń pasek boczny';

  @override
  String get filterSpacesHint => 'Filtruj przestrzenie';

  @override
  String noSpacesMatch(String query) {
    return 'Żadne przestrzenie nie pasują do „$query”';
  }

  @override
  String get privacy => 'Prywatność';

  @override
  String get sendDiffContentTitle => 'Wysyłanie treści diffów do adaptera AI';

  @override
  String get diffSharingOnSubtitle =>
      'Surowe wiersze diffów są dołączane do promptów agenta, aby pogłębić recenzję.';

  @override
  String get diffSharingOffSubtitle =>
      'Agenty korzystają tylko z metadanych strukturalnych (ścieżki plików, numery wierszy, opis PR); surowy kod nie opuszcza aplikacji.';

  @override
  String get errorReportingTitle => 'Udostępnianie raportów awarii';

  @override
  String get errorReportingOnSubtitle =>
      'Diagnostyka awarii, błędów i wydajności jest wysyłana, aby pomóc naprawiać błędy (tylko wydania release).';

  @override
  String get errorReportingOffSubtitle =>
      'Diagnostyka jest wyłączona. Żadne raporty awarii ani błędów nie są wysyłane.';

  @override
  String get onboardingDiagnosticsTitle => 'Pomóż ulepszać Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Wysyłaj diagnostykę awarii, błędów i wydajności, abyśmy mogli szybciej naprawiać problemy (tylko wydania release). Możesz to zmienić w każdej chwili w Ustawienia → Prywatność.';

  @override
  String get blocked => 'Zablokowany';

  @override
  String get idle => 'Bezczynny';

  @override
  String get noRunsYet => 'Brak uruchomień';

  @override
  String get copyPath => 'Kopiuj ścieżkę';

  @override
  String get copyRelativePath => 'Kopiuj ścieżkę względną';

  @override
  String get nameRequired => 'Nazwa jest wymagana';

  @override
  String get import => 'Importuj';

  @override
  String get noMatchingAgents => 'Żaden agent nie spełnia kryteriów filtra';

  @override
  String watchVideoOn(String provider) {
    return 'Zobacz film na $provider';
  }

  @override
  String get branchTemplate => 'Szablon nazwy gałęzi';

  @override
  String get branchTemplateDescription =>
      'Wzorzec nazwy gałęzi tworzonej, gdy zgłoszenie jest rozpoczynane w odizolowanym drzewie roboczym.';

  @override
  String branchTemplatePreview(String example) {
    return 'Przykład: $example';
  }

  @override
  String get deletePipelineRun => 'Usuń uruchomienie potoku';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Usunąć to uruchomienie potoku „$template”? Tej operacji nie można cofnąć.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Błąd usuwania uruchomienia potoku: $error';
  }

  @override
  String get deleteTicket => 'Usuń zgłoszenie';

  @override
  String deleteTicketConfirm(String title) {
    return 'Usunąć „$title”? Tej operacji nie można cofnąć.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Błąd usuwania zgłoszenia: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return 'Usunąć „$name”? Powiązane repozytoria na dysku nie zostaną dotknięte.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Błąd usuwania obszaru roboczego: $error';
  }

  @override
  String get indexCode => 'Indeksuj kod';

  @override
  String get indexNoGrammars => 'Gramatyki kodu niezainstalowane';

  @override
  String get indexFailed => 'Indeksowanie nie powiodło się';

  @override
  String indexedSymbolsCount(int count) {
    return 'Zindeksowano $count symboli';
  }

  @override
  String get nodeConfigAdvanced => 'Zaawansowane';

  @override
  String get nodeConfigReducer => 'Reducer';

  @override
  String get nodeConfigReducerHelp =>
      'Jak scalić, gdy ten klucz wyjściowy ma już wartość';

  @override
  String get nodeConfigTimeoutMs => 'Limit czasu (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Liczba ponownych prób';

  @override
  String get nodeConfigContinueOnFail =>
      'Kontynuuj, jeśli ten krok się nie powiedzie';

  @override
  String get nodeConfigTeamId => 'ID zespołu';

  @override
  String get nodeConfigDispatchMode => 'Tryb wysyłania';

  @override
  String get nodeConfigOutputSchema => 'Schemat wyjściowy (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'Schemat JSON, jaki musi spełniać wyjście kroku';

  @override
  String get diffLineDisplay => 'Długie wiersze w diffach';

  @override
  String get diffLineDisplayDescription =>
      'Zawijaj długie wiersze lub przewijaj je w poziomie';

  @override
  String get diffLineWrap => 'Zawijaj';

  @override
  String get diffLineScroll => 'Przewijaj w poziomie';

  @override
  String get actions => 'Akcje';

  @override
  String get activate => 'Aktywuj';

  @override
  String get activity => 'Aktywność';

  @override
  String get activityLabel => 'AKTYWNOŚĆ';

  @override
  String get activitySearchHint => 'Szukaj w aktywności';

  @override
  String get activityNoMatches =>
      'Żadna aktywność nie spełnia kryteriów filtrów';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end z $total';
  }

  @override
  String get activityPreviousPage => 'Poprzednia strona';

  @override
  String get activityNextPage => 'Następna strona';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'Wyczyść filtr';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return 'Kraj $country';
  }

  @override
  String get activitySavedWorkspaceLogo => 'Zapisano logo obszaru roboczego';

  @override
  String activityVerbCreated(String target) {
    return 'Utworzono $target';
  }

  @override
  String activityVerbUpdated(String target) {
    return 'Zaktualizowano $target';
  }

  @override
  String activityVerbDeleted(String target) {
    return 'Skasowano $target';
  }

  @override
  String activityVerbAdded(String target) {
    return 'Dodano $target';
  }

  @override
  String activityVerbRemoved(String target) {
    return 'Usunięto $target';
  }

  @override
  String activityVerbInvited(String target) {
    return 'Zaproszono $target';
  }

  @override
  String activityVerbChanged(String target) {
    return 'Zmieniono $target';
  }

  @override
  String activityVerbStarted(String target) {
    return 'Rozpoczęto $target';
  }

  @override
  String activityVerbStopped(String target) {
    return 'Zatrzymano $target';
  }

  @override
  String activityVerbWrote(String target) {
    return 'Zapisano $target';
  }

  @override
  String get activityTargetAgent => 'agenta';

  @override
  String get activityTargetTicket => 'zgłoszenie';

  @override
  String get activityTargetWorkspace => 'obszar roboczy';

  @override
  String get activityTargetRepository => 'repozytorium';

  @override
  String get activityTargetMember => 'członka';

  @override
  String get activityTargetInvite => 'zaproszenie';

  @override
  String get activityTargetSpace => 'przestrzeń';

  @override
  String get activityTargetMessage => 'wiadomość';

  @override
  String get activityTargetCache => 'cache';

  @override
  String get activityTargetFile => 'plik';

  @override
  String get activityTargetPipeline => 'potok';

  @override
  String get activityTargetTemplate => 'szablon';

  @override
  String get activityTargetProvider => 'dostawcę';

  @override
  String get activityTargetModel => 'model';

  @override
  String get activityTargetSkill => 'skill';

  @override
  String get activityTargetTodo => 'zadanie';

  @override
  String get activityTargetMeeting => 'spotkanie';

  @override
  String get activityTargetProject => 'projekt';

  @override
  String get activityTargetTeam => 'zespół';

  @override
  String get activityTargetDevice => 'urządzenie';

  @override
  String get activityTargetPreference => 'preferencję';

  @override
  String get activityTargetBudget => 'budżet';

  @override
  String activityVerbApproved(String target) {
    return 'Zatwierdzono $target';
  }

  @override
  String activityVerbArchived(String target) {
    return 'Zarchiwizowano $target';
  }

  @override
  String activityVerbAssigned(String target) {
    return 'Przypisano $target';
  }

  @override
  String activityVerbBackedUp(String target) {
    return 'Zabezpieczono $target';
  }

  @override
  String activityVerbCancelled(String target) {
    return 'Anulowano $target';
  }

  @override
  String activityVerbCleared(String target) {
    return 'Wyczyszczono $target';
  }

  @override
  String activityVerbClosed(String target) {
    return 'Zamknięto $target';
  }

  @override
  String activityVerbCommitted(String target) {
    return 'Wycommitowano $target';
  }

  @override
  String activityVerbCompacted(String target) {
    return 'Skompresowano $target';
  }

  @override
  String activityVerbCompleted(String target) {
    return 'Ukończono $target';
  }

  @override
  String activityVerbConnected(String target) {
    return 'Połączono $target';
  }

  @override
  String activityVerbContinued(String target) {
    return 'Kontynuowano $target';
  }

  @override
  String activityVerbDisconnected(String target) {
    return 'Rozłączono $target';
  }

  @override
  String activityVerbDispatched(String target) {
    return 'Zlecono $target';
  }

  @override
  String activityVerbDrained(String target) {
    return 'Opróżniono $target';
  }

  @override
  String activityVerbEnrolled(String target) {
    return 'Zapisano $target';
  }

  @override
  String activityVerbEstimated(String target) {
    return 'Oszacowano $target';
  }

  @override
  String activityVerbImported(String target) {
    return 'Zaimportowano $target';
  }

  @override
  String activityVerbInstalled(String target) {
    return 'Zainstalowano $target';
  }

  @override
  String activityVerbKilled(String target) {
    return 'Zabito $target';
  }

  @override
  String activityVerbMarked(String target) {
    return 'Oznaczono $target';
  }

  @override
  String activityVerbMerged(String target) {
    return 'Scalono $target';
  }

  @override
  String activityVerbOpened(String target) {
    return 'Otwarto $target';
  }

  @override
  String activityVerbPaused(String target) {
    return 'Wstrzymano $target';
  }

  @override
  String activityVerbPolled(String target) {
    return 'Odpytano $target';
  }

  @override
  String activityVerbPrepared(String target) {
    return 'Przygotowano $target';
  }

  @override
  String activityVerbProcessed(String target) {
    return 'Przetworzono $target';
  }

  @override
  String activityVerbPublished(String target) {
    return 'Opublikowano $target';
  }

  @override
  String activityVerbRefined(String target) {
    return 'Dopracowano $target';
  }

  @override
  String activityVerbRefreshed(String target) {
    return 'Odświeżono $target';
  }

  @override
  String activityVerbRegistered(String target) {
    return 'Zarejestrowano $target';
  }

  @override
  String activityVerbRenamed(String target) {
    return 'Zmieniono nazwę $target';
  }

  @override
  String activityVerbReordered(String target) {
    return 'Zmieniono kolejność $target';
  }

  @override
  String activityVerbResponded(String target) {
    return 'Odpowiedziano na $target';
  }

  @override
  String activityVerbRestored(String target) {
    return 'Przywrócono $target';
  }

  @override
  String activityVerbResumed(String target) {
    return 'Wznowiono $target';
  }

  @override
  String activityVerbRetried(String target) {
    return 'Ponowiono $target';
  }

  @override
  String activityVerbReverted(String target) {
    return 'Cofnięto $target';
  }

  @override
  String activityVerbReviewed(String target) {
    return 'Zrecenzowano $target';
  }

  @override
  String activityVerbRan(String target) {
    return 'Uruchomiono $target';
  }

  @override
  String activityVerbSelected(String target) {
    return 'Wybrano $target';
  }

  @override
  String activityVerbSent(String target) {
    return 'Wysłano $target';
  }

  @override
  String activityVerbStaged(String target) {
    return 'Dodano do stage\'u $target';
  }

  @override
  String activityVerbSteered(String target) {
    return 'Nakierowano $target';
  }

  @override
  String activityVerbSubmitted(String target) {
    return 'Zgłoszono $target';
  }

  @override
  String activityVerbSynced(String target) {
    return 'Zsynchronizowano $target';
  }

  @override
  String activityVerbToggled(String target) {
    return 'Przełączono $target';
  }

  @override
  String activityVerbUninstalled(String target) {
    return 'Odinstalowano $target';
  }

  @override
  String activityVerbUnstaged(String target) {
    return 'Usunięto ze stage\'u $target';
  }

  @override
  String get activityTargetActionPolicy => 'politykę akcji';

  @override
  String get activityTargetGoalRun => 'uruchomienie celu';

  @override
  String get activityTargetRunLog => 'dziennik uruchomienia';

  @override
  String get activityTargetWorkingMemory => 'pamięć roboczą';

  @override
  String get activityTargetRoutingPolicy => 'politykę routingu';

  @override
  String get activityTargetAutonomy => 'autonomię';

  @override
  String get activityTargetCalendar => 'kalendarz';

  @override
  String get activityTargetChecker => 'kontrolera';

  @override
  String get activityTargetEditor => 'edytor';

  @override
  String get activityTargetConfirmation => 'potwierdzenie';

  @override
  String get activityTargetTunnel => 'tunel';

  @override
  String get activityTargetConversation => 'rozmowę';

  @override
  String get activityTargetCredentials => 'dane uwierzytelniające';

  @override
  String get activityTargetDictation => 'dyktowanie';

  @override
  String get activityTargetAgentRun => 'uruchomienie agenta';

  @override
  String get activityTargetEvalSuite => 'zestaw eval';

  @override
  String get activityTargetWorker => 'workera';

  @override
  String get activityTargetWorktree => 'drzewo robocze';

  @override
  String get activityTargetMcpServer => 'serwer MCP';

  @override
  String get activityTargetMemoryAccessGrant =>
      'uprawnienie dostępu do pamięci';

  @override
  String get activityTargetMemoryDomain => 'dziedzinę pamięci';

  @override
  String get activityTargetMemoryFact => 'fakt pamięci';

  @override
  String get activityTargetMemoryPolicy => 'politykę pamięci';

  @override
  String get activityTargetFeed => 'kanał';

  @override
  String get activityTargetNote => 'notatkę';

  @override
  String get activityTargetOrchestration => 'orkiestrację';

  @override
  String get activityTargetPipelineRun => 'uruchomienie potoku';

  @override
  String get activityTargetPipelineTrigger => 'wyzwalacz potoku';

  @override
  String get activityTargetPlan => 'plan';

  @override
  String get activityTargetPlaybook => 'playbook';

  @override
  String get activityTargetPullRequest => 'pull request';

  @override
  String get activityTargetReview => 'recenzję';

  @override
  String get activityTargetProcess => 'proces';

  @override
  String get activityTargetProviderPolicy => 'politykę dostawcy';

  @override
  String get activityTargetReaction => 'reakcję';

  @override
  String get activityTargetReviewSpace => 'przestrzeń recenzji';

  @override
  String get activityTargetReviewStudio => 'studio recenzji';

  @override
  String get activityTargetServerData => 'dane serwera';

  @override
  String get activityTargetSoundscape => 'pejzaż dźwiękowy';

  @override
  String get activityTargetSession => 'sesję';

  @override
  String get activityTargetTerminal => 'terminal';

  @override
  String get activityTargetTicketLink => 'powiązanie zgłoszenia';

  @override
  String get activityTargetTicketSync => 'synchronizację zgłoszenia';

  @override
  String get activityTargetProfile => 'profil';

  @override
  String get activityTargetVoiceProfile => 'profil głosowy';

  @override
  String get activityTargetWeather => 'prognozę pogody';

  @override
  String get activityTargetWorkProduct => 'efekt pracy';

  @override
  String get activityChangedMemberRole => 'Zmieniono rolę członka';

  @override
  String get activityChangedMemberRepoAccess =>
      'Zmieniono dostęp członka do repozytorium';

  @override
  String get activityUpdatedGitHubToken => 'Zaktualizowano token GitHub';

  @override
  String get activityRefreshedWeather => 'Odświeżono prognozę pogody';

  @override
  String get activitySetWeatherLocation => 'Ustawiono lokalizację pogody';

  @override
  String get activityClearedWeatherLocation =>
      'Wyczyszczono lokalizację pogody';

  @override
  String get activityMarkedAllArticlesRead =>
      'Oznaczono wszystkie artykuły jako przeczytane';

  @override
  String get activityMarkedArticleRead => 'Oznaczono artykuł jako przeczytany';

  @override
  String get activityUpdatedSavedArticle => 'Zaktualizowano zapisany artykuł';

  @override
  String get activityTookOverSession => 'Przejęto sesję';

  @override
  String get activityHandedBackSession => 'Zwrócono sesję';

  @override
  String get activityCommittedAndPushed => 'Wycommitowano i wypchnięto';

  @override
  String get activityBackedUpServer => 'Wykonano kopię zapasową danych serwera';

  @override
  String get activityMarkedSpaceRead => 'Oznaczono przestrzeń jako przeczytaną';

  @override
  String get activityRespondedToInvitation =>
      'Odpowiedziano na zaproszenie na wydarzenie';

  @override
  String get activityStartedCalendarConnect =>
      'Rozpoczęto łączenie z kalendarzem';

  @override
  String get activityDisconnectedCalendar => 'Rozłączono kalendarz';

  @override
  String get activityMarkedFileViewed => 'Oznaczono plik jako obejrzany';

  @override
  String get activityRespondedToApproval =>
      'Odpowiedziano na prośbę o zatwierdzenie';

  @override
  String get activityChangedTunnel => 'Zmieniono ustawienie tunelu';

  @override
  String get activitySentMessageToAgent => 'Wysłano wiadomość do agenta';

  @override
  String get activityOpenedReviewSpace => 'Otwarto przestrzeń recenzji';

  @override
  String get activityOpenedStandingConversation => 'Otwarto stałą rozmowę';

  @override
  String get activityStartedRecording => 'Rozpoczęto nagranie';

  @override
  String get activityStoppedRecording => 'Zatrzymano nagranie';

  @override
  String get activityToggledMcpServer => 'Przełączono serwer MCP';

  @override
  String get activityUpdatedMcpToken => 'Zaktualizowano token MCP';

  @override
  String get activitySavedApiKey => 'Zapisano klucz API';

  @override
  String get activityRemovedProviderCredential =>
      'Usunięto dane uwierzytelniające dostawcy';

  @override
  String get activityUpdatedLinkedRepos =>
      'Zaktualizowano powiązane repozytoria';

  @override
  String get activityUnlinkedRepo => 'Odwiązano repozytorium';

  @override
  String get activityUpdatedActionItem => 'Zaktualizowano zadanie do wykonania';

  @override
  String adRulesCount(int count) {
    return '$count reguł reklam';
  }

  @override
  String get adapter => 'Adapter';

  @override
  String get adapterLabel => 'Adapter';

  @override
  String get adapters => 'Adaptery';

  @override
  String get adaptersAutoDetected =>
      'Automatycznie wykryte runnery agentów dostępne na tym komputerze. Zainstaluj brakujące narzędzia CLI, aby włączyć dodatkowe runnery.';

  @override
  String get add => 'Dodaj';

  @override
  String get addAComment => 'Dodaj komentarz';

  @override
  String get addAReaction => 'Dodaj reakcję';

  @override
  String get addASuggestion => 'Dodaj sugestię';

  @override
  String get addAgents => 'Dodaj agentów';

  @override
  String get addEmoji => 'Dodaj emoji';

  @override
  String get addFeed => 'Dodaj kanał';

  @override
  String get addressBarHint => 'Wpisz adres URL';

  @override
  String get addFromFile => 'Dodaj z pliku';

  @override
  String get addGif => 'Dodaj GIF';

  @override
  String get addGithubRepoPrompt =>
      'Dodaj co najmniej jedno repozytorium GitHub, aby widzieć pull requesty';

  @override
  String get addLocalCheckoutDescription =>
      'Dodaj lokalny checkout, aby zacząć na nim pracować z tego obszaru roboczego.';

  @override
  String get addRepository => 'Dodaj repozytorium';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dodaj $count repozytorium',
      many: 'Dodaj $count repozytoriów',
      few: 'Dodaj $count repozytoria',
      one: 'Dodaj repozytorium',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'Przeglądaj foldery na maszynie, na której działa serwer, i wybierz checkouty gita do zarejestrowania.';

  @override
  String get selectThisFolder => 'Wybierz ten folder';

  @override
  String get deselectThisFolder => 'Odznacz ten folder';

  @override
  String get goUp => 'W górę';

  @override
  String get noSubfoldersHere => 'Brak podfolderów';

  @override
  String get notAGitRepository => 'Ten folder nie jest repozytorium gita.';

  @override
  String get addToken => 'Dodaj token';

  @override
  String get addWorkspace => 'Dodaj obszar roboczy';

  @override
  String get addWorkspaceEllipsis => 'Dodaj obszar roboczy…';

  @override
  String get added => 'Dodano';

  @override
  String get addingEllipsis => 'Dodawanie…';

  @override
  String get advancedLabel => 'Zaawansowane';

  @override
  String get agent => 'Agent';

  @override
  String agentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agenta',
      many: '$count agentów',
      few: '$count agenci',
      one: '$count agent',
    );
    return '$_temp0';
  }

  @override
  String get agentMdPath => 'Ścieżka do Agent MD';

  @override
  String get agentName => 'Nazwa agenta';

  @override
  String get agentTitle => 'Tytuł agenta';

  @override
  String get agentUpdated => 'Zaktualizowano agenta.';

  @override
  String get agents => 'Agenci';

  @override
  String get agentsMentionSection => 'Agenci';

  @override
  String get usersMentionSection => 'Osoby';

  @override
  String get ticketsMentionSection => 'Zgłoszenia';

  @override
  String get pullRequestsMentionSection => 'Pull requesty';

  @override
  String get meetingsMentionSection => 'Spotkania';

  @override
  String get entityRefTicketFallback => 'Zgłoszenie';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'Spotkanie';

  @override
  String get aiReview => 'Recenzja AI';

  @override
  String get all => 'Wszystkie';

  @override
  String get allAgentsAlreadyInSpace =>
      'Wszyscy agenci są już w tej przestrzeni.';

  @override
  String get allCommits => 'Wszystkie commity';

  @override
  String get allSources => 'Wszystkie źródła';

  @override
  String get allow => 'Zezwól';

  @override
  String get allowGitPush => 'Zezwól na git push';

  @override
  String get allowGithubApi => 'Zezwól na wywołania GitHub API';

  @override
  String get allowNetwork => 'Zezwól na ogólny dostęp do sieci';

  @override
  String get apiKeys => 'Klucze API';

  @override
  String get appFont => 'Czcionka aplikacji';

  @override
  String get appLogLevelDebugDescription =>
      'Dodaje szczegółowe ślady - do celów programistycznych.';

  @override
  String get appLogLevelDebugLabel => 'Debug';

  @override
  String get appLogLevelErrorDescription =>
      'Tylko nieoczekiwane błędy i wyjątki.';

  @override
  String get appLogLevelErrorLabel => 'Błąd';

  @override
  String get appLogLevelInfoDescription =>
      'Dodaje komunikaty cyklu życia i stanu.';

  @override
  String get appLogLevelInfoLabel => 'Info';

  @override
  String get appLogLevelNoneDescription =>
      'Brak jakichkolwiek danych wyjściowych w konsoli.';

  @override
  String get appLogLevelNoneLabel => 'Brak';

  @override
  String get appLogLevelVerboseDescription =>
      'Wszystko. Bardzo szumne - używaj tylko do debugowania.';

  @override
  String get appLogLevelVerboseLabel => 'Verbose';

  @override
  String get appLogLevelWarningDescription =>
      'Dodaje ostrzeżenia i problemy możliwe do naprawienia.';

  @override
  String get appLogLevelWarningLabel => 'Ostrzeżenie';

  @override
  String get appearanceLanguage => 'Wygląd i język';

  @override
  String get apply => 'Zastosuj';

  @override
  String get approve => 'Zatwierdź';

  @override
  String get agentApprovalRequired => 'Wymagane zatwierdzenie';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Jeszcze $count oczekuje',
      many: 'Jeszcze $count oczekuje',
      few: 'Jeszcze $count oczekują',
      one: 'Jeszcze $count oczekuje',
    );
    return '$_temp0';
  }

  @override
  String get approved => 'Zatwierdzono';

  @override
  String get articleNoun => 'Artykuł';

  @override
  String get articlesSubscribed => 'Artykuły z Twoich subskrybowanych kanałów.';

  @override
  String get askAi => 'Zapytaj AI';

  @override
  String get askAiReviewDescription => 'Poproś AI o zrecenzowanie tego PR';

  @override
  String get assignees => 'Osoby przypisane';

  @override
  String get attachImage => 'Załącz obraz';

  @override
  String get attachedAgents => 'Dołączeni agenci';

  @override
  String get audioInput => 'Wejście audio';

  @override
  String get audioOutput => 'Wyjście audio';

  @override
  String get authenticationToken => 'Token uwierzytelniający';

  @override
  String authoredByLabel(String role) {
    return 'Autor: $role';
  }

  @override
  String get autoRecommended => 'Auto (zalecane)';

  @override
  String get available => 'Dostępne';

  @override
  String get awaitingYourReview => 'Czeka na Twoją recenzję';

  @override
  String get back => 'Wstecz';

  @override
  String get backLabel => 'Wstecz';

  @override
  String get backend => 'Backend';

  @override
  String get blockAdsTrackers => 'Blokuj reklamy, trackery i banery cookie';

  @override
  String get blocking => 'Blokujące';

  @override
  String get bookmarkLabel => 'Zakładka';

  @override
  String get briefDescription => 'Krótki opis';

  @override
  String get bugLabel => 'BŁĄD';

  @override
  String get bundledDefaultsNeverUpdated =>
      'Wbudowane domyślne — bez aktualizacji';

  @override
  String get cancel => 'Anuluj';

  @override
  String get cancelEdit => 'Anuluj edycję';

  @override
  String get categoryCreation => 'Tworzenie';

  @override
  String get categoryEditing => 'Edycja';

  @override
  String get categoryNavigation => 'Nawigacja';

  @override
  String get categorySystem => 'System';

  @override
  String get categoryView => 'Widok kategorii';

  @override
  String get change => 'Zmień';

  @override
  String get changesRequested => 'Zażądano zmian';

  @override
  String get spacesMentionSection => 'Przestrzenie';

  @override
  String get checkForUpdates => 'Sprawdź aktualizacje';

  @override
  String get checking => 'Sprawdzanie';

  @override
  String get checkingEllipsis => 'Sprawdzanie…';

  @override
  String get chooseAppFont => 'Wybierz czcionkę aplikacji';

  @override
  String get chooseCodeFont => 'Wybierz czcionkę kodu';

  @override
  String get chooseRunner => 'Wybierz swój runner agenta.';

  @override
  String get clear => 'Wyczyść';

  @override
  String get clickToRetry => 'Kliknij, aby ponowić';

  @override
  String get close => 'Zamknij';

  @override
  String get closeEsc => 'Zamknij (Esc)';

  @override
  String get closeReader => 'Zamknij czytnik';

  @override
  String get closed => 'Zamknięte';

  @override
  String get codeFont => 'Czcionka kodu';

  @override
  String get codeFontLigatures => 'Ligatury czcionki kodu';

  @override
  String get codeFontLigaturesDescription =>
      'Renderuj ligatury programistyczne (=>, !=, ->) jako połączone glify w kodzie i diffach';

  @override
  String get collapse => 'Zwiń';

  @override
  String get commandPalette => 'Paleta poleceń';

  @override
  String get commandPaletteOrgMembers => 'Członkowie organizacji';

  @override
  String get commandPaletteBrowseTeam => 'Przeglądaj zespół';

  @override
  String get commandPaletteBrowseTeamDesc =>
      'Wyświetl wszystkich członków organizacji';

  @override
  String get compactDone =>
      'Rozmowa została skompresowana. Wcześniejsza historia została zwinięta w podsumowanie.';

  @override
  String get compactNothing =>
      'Nie ma jeszcze czego kompresować. Rozmowa jest wciąż krótka.';

  @override
  String get compactBusy =>
      'Agent nadal pracuje. Skompresuj po zakończeniu tury.';

  @override
  String get compactUnavailable =>
      'Kompresja jest niedostępna na tym serwerze.';

  @override
  String get commandsMentionSection => 'Polecenia';

  @override
  String get comment => 'Komentarz';

  @override
  String get commentOnThisFile => 'Skomentuj ten plik';

  @override
  String get commented => 'Skomentowano';

  @override
  String get commits => 'Commity';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Wyświetlanie najnowszych $loaded z $total commitów';
  }

  @override
  String get prCloneProgressCloningTitle => 'Klonowanie repozytorium';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'Ten PR zmienia $fileCount plików, co przekracza limit API GitHuba. Klonowanie repozytorium lokalnie…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'Ten PR przekracza limit plików API GitHuba. Klonowanie repozytorium lokalnie…';

  @override
  String get prCloneProgressFetchingTitle => 'Pobieranie refów PR';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Pobieranie gałęzi bazowej i refa head PR…';

  @override
  String get prCloneProgressComputingTitle => 'Obliczanie diffa';

  @override
  String get prCloneProgressComputingSubtitle =>
      'Uruchamianie git diff lokalnie…';

  @override
  String get prCloneProgressErrorTitle => 'Nie udało się wczytać diffa';

  @override
  String get prCloneProgressErrorSubtitle =>
      'Wystąpił błąd podczas klonowania lub obliczania diffa. Spróbuj odświeżyć.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Nadal trwa… minęło $elapsed';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Pewność: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'Konfiguruj tożsamości agentów, prompty, skille i przeglądaj uruchomienia.';

  @override
  String get configureDefaultRunners =>
      'Skonfiguruj, który adapter i model są używane dla nowych przestrzeni i generowania tytułów.';

  @override
  String get configuredLabel => 'Skonfigurowano.';

  @override
  String get confirmedBy => 'Potwierdzone przez';

  @override
  String get consensus => 'Konsensus';

  @override
  String get contentHint => 'Co powinno zostać zapamiętane';

  @override
  String get contentLabel => 'Treść';

  @override
  String get contentMarkdown => 'Treść (Markdown)';

  @override
  String get contextWindowSize => 'Rozmiar okna kontekstu';

  @override
  String modelContextChip(String size) {
    return 'Model · $size';
  }

  @override
  String get continueLabel => 'Kontynuuj';

  @override
  String get conversationMode => 'Tryb';

  @override
  String cookieRulesCount(int count) {
    return '$count reguł cookie';
  }

  @override
  String get copied => 'Skopiowano!';

  @override
  String get copy => 'Kopiuj';

  @override
  String get copyAddress => 'Kopiuj adres';

  @override
  String get copyBaseBranchTooltip => 'Kopiuj nazwę gałęzi bazowej';

  @override
  String get copyHeadBranchTooltip => 'Kopiuj nazwę gałęzi źródłowej';

  @override
  String couldNotListDevices(String error) {
    return 'Nie udało się wyświetlić listy urządzeń: $error';
  }

  @override
  String get create => 'Utwórz';

  @override
  String get createOrSelectWorkspace =>
      'Utwórz lub wybierz obszar roboczy przed dodaniem repozytoriów.';

  @override
  String get createPullRequest => 'Utwórz pull request';

  @override
  String get createdByMe => 'Utworzone przeze mnie';

  @override
  String createdLabel(String date) {
    return 'Utworzono: $date';
  }

  @override
  String get currentParticipants => 'Bieżący uczestnicy';

  @override
  String get customCapabilitiesDescription =>
      'Opis niestandardowych możliwości';

  @override
  String get customSystemPrompt =>
      'Niestandardowy prompt systemowy dla tego agenta...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dnia temu',
      many: '$count dni temu',
      few: '$count dni temu',
      one: '$count dzień temu',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Dezaktywuj';

  @override
  String get defaultCapabilities => 'Domyślne możliwości · nowe przestrzenie';

  @override
  String get defaultChat => 'Domyślny czat';

  @override
  String get defaultRunners => 'Domyślne runnery';

  @override
  String get delete => 'Usuń';

  @override
  String get deleteAgent => 'Usuń agenta';

  @override
  String deleteAgentConfirm(String name) {
    return 'Usunąć „$name”? Tej operacji nie można cofnąć.';
  }

  @override
  String get deleteSpace => 'Usuń przestrzeń';

  @override
  String deleteConfirmName(String name) {
    return 'Usunąć „$name”?';
  }

  @override
  String get archiveConversation => 'Zarchiwizuj rozmowę';

  @override
  String get deleteFact => 'Usuń fakt';

  @override
  String get deleteFeedBody =>
      'Spowoduje to usunięcie kanału i wszystkich jego zbuforowanych artykułów. Artykuły z tego kanału zapisane w zakładkach także zostaną usunięte.';

  @override
  String deleteFeedConfirm(String name) {
    return 'Usunąć „$name”?';
  }

  @override
  String get deletePolicy => 'Usuń politykę';

  @override
  String get deletePolicyConfirm =>
      'Usunąć tę politykę? Tej operacji nie można cofnąć.';

  @override
  String deleteTopicConfirm(String topic) {
    return 'Usunąć „$topic”? Tej operacji nie można cofnąć.';
  }

  @override
  String get deleteWorkspace => 'Usuń obszar roboczy';

  @override
  String get deny => 'Odmów';

  @override
  String get detailsLabel => 'Szczegóły';

  @override
  String get descriptionLabel => 'Opis';

  @override
  String detectedBackend(String label) {
    return 'Wykryto: $label';
  }

  @override
  String get detectedRunners => 'Wykryte runnery';

  @override
  String get detectingAdapters => 'Wykrywanie adapterów…';

  @override
  String get detectingInputDevices => 'Wykrywanie urządzeń wejściowych…';

  @override
  String detectionFailed(String error) {
    return 'Wykrywanie nie powiodło się: $error';
  }

  @override
  String get disabled => 'Wyłączone';

  @override
  String get discover => 'Odkrywaj';

  @override
  String get dismissed => 'Odrzucone';

  @override
  String get domainHint => 'np. api-performance';

  @override
  String get domainLabel => 'Domena';

  @override
  String get download => 'Pobierz';

  @override
  String get downloadingLabel => 'Pobieranie';

  @override
  String downloadingModel(int pct) {
    return 'Pobieranie modelu… $pct%';
  }

  @override
  String get draft => 'Szkic';

  @override
  String get draftLabel => 'Szkic';

  @override
  String get edit => 'Edytuj';

  @override
  String get edited => 'edytowano';

  @override
  String get editMessage => 'Edytuj wiadomość';

  @override
  String get deleteMessage => 'Usuń wiadomość';

  @override
  String get deleteMessageConfirm =>
      'Usunąć tę wiadomość? Tej operacji nie można cofnąć.';

  @override
  String get messageDeleted => 'Wiadomość usunięta';

  @override
  String get searchInConversation => 'Szukaj w rozmowie';

  @override
  String get searchMessagesHint => 'Szukaj wiadomości…';

  @override
  String get noMessagesFound => 'Nie znaleziono wiadomości';

  @override
  String get editFact => 'Edytuj fakt';

  @override
  String get editPolicy => 'Edytuj politykę';

  @override
  String get editSuggestedCodeHint => 'Edytuj sugerowany kod…';

  @override
  String get editSuggestion => 'Edytuj sugestię';

  @override
  String get egArchitect => 'np. architekt';

  @override
  String get egControlCenter => 'np. control-center';

  @override
  String get egPlatform => 'np. macOS';

  @override
  String get egSamuelAlev => 'np. SamuelAlev';

  @override
  String get egSoftwareArchitect => 'np. Architekt oprogramowania';

  @override
  String get egTheVerge => 'np. The Verge';

  @override
  String get egTokenLimit => 'np. 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Instalacja nie powiodła się: $error';
  }

  @override
  String get embeddingInstalled =>
      'Lokalny model osadzeń zainstalowany. Wyszukiwanie hybrydowe jest włączone.';

  @override
  String get embeddingModel => 'Model osadzeń (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Niezainstalowany. Wyszukiwanie wraca do trybu opartego tylko na słowach kluczowych do czasu włączenia.';

  @override
  String get embeddingRedownloadBody =>
      'Istniejące pliki modelu zostaną usunięte i pobrane ponownie. Wyszukiwanie semantyczne będzie niedostępne do zakończenia pobierania.';

  @override
  String get embeddingRemoveBody =>
      'Wyszukiwanie semantyczne zostanie wyłączone do czasu ponownej instalacji. Możesz zainstalować je ponownie w każdej chwili.';

  @override
  String get speakerDiarization => 'Diaryzacja mówców';

  @override
  String get diarizationModel => 'Model diaryzacji';

  @override
  String get diarizationInstalled =>
      'Zainstalowany — nazywa poszczególnych mówców w transkrypcjach spotkań';

  @override
  String get diarizationNotInstalled =>
      'Niezainstalowany — mówcy na spotkaniach nie będą rozróżniani';

  @override
  String diarizationInstallFailed(String error) {
    return 'Instalacja nie powiodła się: $error';
  }

  @override
  String get redownloadDiarizationModel => 'Pobierz ponownie model diaryzacji';

  @override
  String get diarizationRedownloadBody =>
      'Usuwa bieżące modele diaryzacji i pobiera je ponownie.';

  @override
  String get removeDiarizationModel => 'Usuń model diaryzacji';

  @override
  String get diarizationRemoveBody =>
      'Spowoduje to usunięcie modeli diaryzacji z urządzenia. Już utworzone transkrypcje spotkań pozostaną bez zmian.';

  @override
  String get enableNotifications => 'Włącz powiadomienia';

  @override
  String get enableSandboxing => 'Włącz sandboxowanie';

  @override
  String get enabled => 'Włączone';

  @override
  String errorCreatingAgent(String error) {
    return 'Błąd tworzenia agenta: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Błąd usuwania agenta: $error';
  }

  @override
  String errorWithDetail(String error) {
    return 'Błąd: $error';
  }

  @override
  String get expand => 'Rozwiń';

  @override
  String extractingModel(int pct) {
    return 'Rozpakowywanie modelu… $pct%';
  }

  @override
  String get fact => 'Fakt';

  @override
  String factCount(int count) {
    return '$count fakt';
  }

  @override
  String factCountPlural(int count) {
    return '$count faktów';
  }

  @override
  String get facts => 'Fakty';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount faktów · $policyCount polityk';
  }

  @override
  String get failed => 'Niepowodzenie';

  @override
  String failedToDispatch(String error) {
    return 'Nie udało się wysłać: $error';
  }

  @override
  String get failedToLoad => 'Nie udało się wczytać';

  @override
  String failedToLoadAgents(String error) {
    return 'Nie udało się wczytać agentów: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Nie udało się wczytać kanałów: $error';
  }

  @override
  String get failedToLoadGifs => 'Nie udało się wczytać GIF-ów';

  @override
  String failedToLoadLogs(String error) {
    return 'Nie udało się wczytać logów: $error';
  }

  @override
  String get failedToLoadRepos => 'Nie udało się wczytać repozytoriów';

  @override
  String get failedToLoadWorkspaces =>
      'Nie udało się wczytać obszarów roboczych';

  @override
  String failedToStartAiReview(String error) {
    return 'Nie udało się rozpocząć recenzji AI: $error';
  }

  @override
  String get failedToStartMicTest => 'Nie udało się rozpocząć testu mikrofonu.';

  @override
  String failedToSubmitReview(String error) {
    return 'Nie udało się przesłać recenzji: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'Nie udało się przesłać $name: $error';
  }

  @override
  String failedWithError(String error) {
    return 'Niepowodzenie: $error';
  }

  @override
  String get failure => 'Niepowodzenie';

  @override
  String get feedAlreadyExists => 'Kanał z tym adresem URL już istnieje.';

  @override
  String get feedUrlExample => 'np. https://example.com/feed.xml';

  @override
  String get feedUrlLabel => 'Adres URL kanału';

  @override
  String feedsCount(int count) {
    return 'Kanały ($count)';
  }

  @override
  String get filesChanged => 'Zmienione pliki';

  @override
  String filesCount(int count) {
    return '$count plik(ów)';
  }

  @override
  String get filesMentionSection => 'Pliki';

  @override
  String get filterAgents => 'Filtruj agentów...';

  @override
  String get filterFilesHint => 'Filtruj pliki…';

  @override
  String get filterLists => 'Filtruj listy';

  @override
  String get filterSkillsPlaceholder => 'Filtruj skille…';

  @override
  String get finish => 'Zakończ';

  @override
  String get fix => 'Napraw';

  @override
  String get forward => 'Dalej';

  @override
  String get gatesGithubPatPush =>
      'Kontroluje wstrzykiwanie GitHub PAT. Wymagane, aby agent mógł wypychać.';

  @override
  String get general => 'Ogólne';

  @override
  String get githubLink => 'Link do GitHuba';

  @override
  String get claudeStatusFetchFailed =>
      'Nie udało się połączyć ze status.claude.com';

  @override
  String get claudeStatusOpenInBrowser => 'Otwórz status.claude.com';

  @override
  String get githubStatusFetchFailed =>
      'Nie udało się połączyć z githubstatus.com';

  @override
  String get githubDegradedTitle => 'GitHub zgłasza problemy';

  @override
  String githubDegradedStatusLine(String status) {
    return 'Status GitHuba: $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'Status GitHuba: $status. Dane pull requestów mogą być nieaktualne lub niekompletne do czasu odzyskania sprawności.';
  }

  @override
  String get githubStatusOpenInBrowser => 'Otwórz githubstatus.com';

  @override
  String get githubStatusRefresh => 'Odśwież';

  @override
  String githubStatusUpdated(String time) {
    return 'Zaktualizowano $time';
  }

  @override
  String get kimiStatusFetchFailed =>
      'Nie udało się połączyć ze status.moonshot.cn';

  @override
  String get kimiStatusOpenInBrowser => 'Otwórz status.moonshot.cn';

  @override
  String get openaiStatusFetchFailed =>
      'Nie udało się połączyć ze status.openai.com';

  @override
  String get openaiStatusOpenInBrowser => 'Otwórz status.openai.com';

  @override
  String get serviceStatusMaintenance => 'Przerwa techniczna';

  @override
  String get serviceStatusMajorIssues => 'Poważne problemy';

  @override
  String get serviceStatusMinorIssues => 'Drobne problemy';

  @override
  String get serviceStatusOperational => 'Działa';

  @override
  String get serviceStatusOutage => 'Awaria';

  @override
  String get serviceStatusTitle => 'Status usługi';

  @override
  String get serviceStatusUnknown => 'Nieznany';

  @override
  String lastChecked(String time) {
    return 'Sprawdzono $time';
  }

  @override
  String get lastCheckedRecently => 'Sprawdzono niedawno';

  @override
  String get giveYourWorkAHome => 'Znajdź dom dla swojej pracy.';

  @override
  String get goBack => 'Wstecz';

  @override
  String get goForward => 'Naprzód';

  @override
  String get googleFonts => 'Czcionki Google';

  @override
  String get high => 'Wysoki';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count godziny temu',
      many: '$count godzin temu',
      few: '$count godziny temu',
      one: '$count godzinę temu',
    );
    return '$_temp0';
  }

  @override
  String get images => 'Obrazy';

  @override
  String get inactive => 'Nieaktywny';

  @override
  String get install => 'Zainstaluj';

  @override
  String get installRequired => 'Wymagana instalacja';

  @override
  String installedVersion(String version) {
    return 'Zainstalowano $version';
  }

  @override
  String get invite => 'Zaproś';

  @override
  String get inviteAgent => 'Zaproś agenta';

  @override
  String get isolateAgentExecution => 'Odizoluj wykonywanie agentów.';

  @override
  String get justNow => 'Właśnie teraz';

  @override
  String get keepSandboxing => 'Zachowaj sandboxowanie';

  @override
  String get keybindingAddARepositoryDescription => 'Dodaj repozytorium';

  @override
  String get keybindingAddRepository => 'Dodaj repozytorium';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Dodaj lub usuń zakładkę z wybranego artykułu';

  @override
  String get keybindingCommandPalette => 'Paleta poleceń';

  @override
  String get keybindingCreateANewAgentDescription => 'Utwórz nowego agenta';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Utwórz nowy obszar roboczy';

  @override
  String get keybindingFocusSearch => 'Przejdź do wyszukiwania';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Przejdź do pola wyszukiwania pull requestów';

  @override
  String get keybindingNewAgent => 'Nowy agent';

  @override
  String get keybindingNewWorkspace => 'Nowy obszar roboczy';

  @override
  String get keybindingNextArticle => 'Następny artykuł';

  @override
  String get keybindingNextSpace => 'Następna przestrzeń';

  @override
  String get keybindingNextWorkspace => 'Następny obszar roboczy';

  @override
  String get keybindingOpenArticle => 'Otwórz artykuł';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Otwórz lub zamknij przełącznik obszarów roboczych na pasku bocznym';

  @override
  String get keybindingOpenPr => 'Otwórz PR';

  @override
  String get keybindingOpenSettings => 'Otwórz ustawienia';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Otwórz ustawienia aplikacji';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Otwórz paletę poleceń';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Otwórz wybrany artykuł';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Otwórz wybrany pull request';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Otwórz wybrany obszar roboczy';

  @override
  String get keybindingOpenWorkspace => 'Otwórz obszar roboczy';

  @override
  String get keybindingPreviousArticle => 'Poprzedni artykuł';

  @override
  String get keybindingPreviousSpace => 'Poprzednia przestrzeń';

  @override
  String get keybindingPreviousWorkspace => 'Poprzedni obszar roboczy';

  @override
  String get keybindingRefresh => 'Odśwież';

  @override
  String get keybindingRefreshAllFeedsDescription => 'Odśwież wszystkie kanały';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Odśwież listę pull requestów';

  @override
  String get keybindingRescanForAdaptersDescription =>
      'Ponownie przeskanuj adaptery';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Wybierz następny artykuł';

  @override
  String get keybindingSelectTheNextSpaceDescription =>
      'Wybierz następną przestrzeń';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Wybierz poprzedni artykuł';

  @override
  String get keybindingSelectThePreviousSpaceDescription =>
      'Wybierz poprzednią przestrzeń';

  @override
  String get keybindingSendMessage => 'Wyślij wiadomość';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Wyślij bieżącą wiadomość';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Przełącz między trybem jasnym a ciemnym';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Przełącz na ósmy obszar roboczy';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Przełącz na piąty obszar roboczy';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Przełącz na pierwszy obszar roboczy';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Przełącz na czwarty obszar roboczy';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Przełącz na następny obszar roboczy';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Przełącz na dziewiąty obszar roboczy';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Przełącz na poprzedni obszar roboczy';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Przełącz na drugi obszar roboczy';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Przełącz na siódmy obszar roboczy';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Przełącz na szósty obszar roboczy';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Przełącz na trzeci obszar roboczy';

  @override
  String get keybindingToggleBookmark => 'Przełącz zakładkę';

  @override
  String get keybindingToggleTheme => 'Przełącz motyw';

  @override
  String get keybindingToggleWorkspaceSwitcher =>
      'Przełącz przełącznik obszarów roboczych';

  @override
  String get keybindingWorkspace1 => 'Obszar roboczy 1';

  @override
  String get keybindingWorkspace2 => 'Obszar roboczy 2';

  @override
  String get keybindingWorkspace3 => 'Obszar roboczy 3';

  @override
  String get keybindingWorkspace4 => 'Obszar roboczy 4';

  @override
  String get keybindingWorkspace5 => 'Obszar roboczy 5';

  @override
  String get keybindingWorkspace6 => 'Obszar roboczy 6';

  @override
  String get keybindingWorkspace7 => 'Obszar roboczy 7';

  @override
  String get keybindingWorkspace8 => 'Obszar roboczy 8';

  @override
  String get keybindingWorkspace9 => 'Obszar roboczy 9';

  @override
  String get keybindings => 'Skróty klawiszowe';

  @override
  String get keybindingsDescription =>
      'Wszystkie skróty klawiszowe. Skróty są stałe i nie można ich przypisać ponownie.';

  @override
  String get killRunning => 'Zabij uruchomione';

  @override
  String get languageSystem => 'Systemowy';

  @override
  String get leaveACommentEllipsis => 'Zostaw komentarz…';

  @override
  String get legendLabel => 'Legenda';

  @override
  String get lessLabel => 'Mniej';

  @override
  String get letsPluginTools => 'Czas podłączyć Twoje narzędzia.';

  @override
  String get level => 'Poziom';

  @override
  String get loadingAgents => 'Wczytywanie agentów…';

  @override
  String get loadingModels => 'Wczytywanie modeli…';

  @override
  String get loadingProviders => 'Wczytywanie dostawców…';

  @override
  String get logLevel => 'Poziom logów';

  @override
  String get logs => 'Logi';

  @override
  String get low => 'Niski';

  @override
  String get maintenance => 'Przerwa techniczna';

  @override
  String get manageParticipants => 'Zarządzaj uczestnikami';

  @override
  String get manageWorkspaces => 'Zarządzaj obszarami roboczymi';

  @override
  String get reorderWorkspace => 'Zmień kolejność obszarów roboczych';

  @override
  String get matchOsAppearance =>
      'Dopasuj do wyglądu systemu operacyjnego lub wybierz stały tryb.';

  @override
  String get mcpAuthToken => 'Token uwierzytelniający MCP';

  @override
  String get mcpNotAvailableOnServer =>
      'Sterowanie serwerem MCP nie jest dostępne na połączonym serwerze.';

  @override
  String get modelManagedOnServer =>
      'Ten model działa na hoście serwera i jest tam zarządzany.';

  @override
  String get mcpServer => 'Serwer MCP';

  @override
  String get medium => 'Średni';

  @override
  String get memoryDataHint =>
      'Fakty i polityki pojawią się tutaj w miarę pracy agentów.';

  @override
  String get memoryLabel => 'Pamięć';

  @override
  String get merge => 'Scal';

  @override
  String get merged => 'Scalono';

  @override
  String get messagePlaceholder => 'Wiadomość… (@ dla wzmianek, / dla poleceń)';

  @override
  String get navConversations => 'Przestrzenie';

  @override
  String get microphonePermissionDenied =>
      'Odmówiono uprawnienia do mikrofonu.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuty temu',
      many: '$count minut temu',
      few: '$count minuty temu',
      one: '$count minutę temu',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Model';

  @override
  String get modified => 'Zmodyfikowano';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miesiąca temu',
      many: '$count miesięcy temu',
      few: '$count miesiące temu',
      one: '$count miesiąc temu',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => 'Więcej';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Nazwa';

  @override
  String get nameAndTitleRequired => 'Nazwa i tytuł są wymagane.';

  @override
  String get nameAndUrlRequired => 'Nazwa i adres URL są wymagane';

  @override
  String get nameLabel => 'Nazwa';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Natywny sandbox jest dostępny na $platform.';
  }

  @override
  String get nativeSandboxNeedsInstall =>
      'Wymagana instalacja natywnego sandboxa';

  @override
  String get navObservability => 'Obserwowalność';

  @override
  String get navSettings => 'Ustawienia';

  @override
  String networkBlockCount(int count) {
    return '$count blokad sieci';
  }

  @override
  String get neutral => 'Neutralny';

  @override
  String get newCommitsPushed =>
      'Wypchnięto nowe commity — kliknij, aby ponownie wczytać diffa';

  @override
  String get newFact => 'Nowy fakt';

  @override
  String get newPolicy => 'Nowa polityka';

  @override
  String get newsfeed => 'Newsfeed';

  @override
  String get newsfeedLabel => 'Newsfeed';

  @override
  String get newsfeedSettingsDescription =>
      'Zarządzaj subskrybowanymi kanałami i preferencjami czytnika.';

  @override
  String get newsfeedSettingsTitle => 'Ustawienia newsfeeda';

  @override
  String get nextMatch => 'Następne dopasowanie (↵)';

  @override
  String get noActiveWorkspace =>
      'Nie wybrano aktywnego obszaru roboczego ani repozytorium.';

  @override
  String get noActiveWorkspaceCreate => 'Brak aktywnego obszaru roboczego';

  @override
  String get noActiveWorkspaceGithub =>
      'Brak aktywnego obszaru roboczego z repozytorium GitHub.';

  @override
  String get noAgents => 'Brak agentów';

  @override
  String get noArticlesYet => 'Brak artykułów';

  @override
  String get noArticlesYetBody =>
      'Artykuły z Twoich kanałów pojawią się tutaj.';

  @override
  String get noExecutionLogsYet => 'Brak logów wykonania';

  @override
  String get noFacts => 'Brak faktów';

  @override
  String get noFeedsYet => 'Brak kanałów';

  @override
  String get noFileAnchor =>
      'Brak zakotwiczenia pliku — nie można opublikować komentarza w wierszu.';

  @override
  String get noFileChangesInScope => 'Brak zmian plików w tym zakresie';

  @override
  String get noGifsFound => 'Nie znaleziono GIF-ów';

  @override
  String get noInputDevicesDetected =>
      'Nie wykryto urządzeń wejściowych — używane jest domyślne systemowe.';

  @override
  String get noMatchingFiles => 'Brak pasujących plików';

  @override
  String get noMatchingGoogleFonts => 'Brak pasujących czcionek Google Fonts.';

  @override
  String get noMemoryData => 'Brak danych pamięci';

  @override
  String get noMessagesYet => 'Brak wiadomości';

  @override
  String get noModelsAdvertised => 'Ten adapter nie rozgłasza żadnych modeli.';

  @override
  String get noOpenPullRequests => 'Brak otwartych pull requestów';

  @override
  String get noPolicies => 'Brak polityk';

  @override
  String get noReposInWorkspaceYet =>
      'W tym obszarze roboczym nie ma jeszcze repozytoriów';

  @override
  String get noRunnersDetected =>
      'Nie wykryto jeszcze runnerów. Odśwież, aby przeskanować ponownie.';

  @override
  String get noSavedArticles => 'Brak zapisanych artykułów';

  @override
  String get noSavedArticlesBody =>
      'Artykuły, które zapiszesz, pojawią się tutaj.';

  @override
  String noShortcutsMatch(String query) {
    return 'Żaden skrót nie pasuje do „$query”';
  }

  @override
  String get noSystemFonts => 'Nie wykryto czcionek systemowych.';

  @override
  String get noTokenSet =>
      'Brak ustawionego tokena — dostęp jest bez ograniczeń.';

  @override
  String get noWorkingMemory => 'Brak notatek pamięci roboczej.';

  @override
  String get noneAllRoles => 'Brak (wszystkie role)';

  @override
  String get notAvailable => 'Niedostępne';

  @override
  String get notConfiguredLabel => 'Nieskonfigurowane.';

  @override
  String get notFoundLabel => 'Nie znaleziono';

  @override
  String get notes => 'Notatki';

  @override
  String get notificationAgentFinished => 'Agent ukończył pracę';

  @override
  String get notificationPrMentioned => 'Wzmianka w pull requeście';

  @override
  String get notificationNewMessages => 'Nowe wiadomości';

  @override
  String get notificationPrMerged => 'Scalono PR';

  @override
  String get notificationPrPublished => 'Opublikowano PR';

  @override
  String get notificationReviewRequested => 'Prośba o recenzję';

  @override
  String get notifications => 'Powiadomienia';

  @override
  String get notifyAgentRunCompleted =>
      'Powiadom, gdy agent zakończy uruchomienie.';

  @override
  String get notifyPrMentioned =>
      'Powiadom, gdy zostaniesz wspomniany w pull requeście.';

  @override
  String get notifyNewMessages =>
      'Powiadom o nowych wiadomościach agentów w innych przestrzeniach.';

  @override
  String get notifyPrMerged => 'Powiadom, gdy pull request zostanie scalony.';

  @override
  String get notifyPrPublished =>
      'Powiadom, gdy agent opublikuje pull request.';

  @override
  String get notifyReviewRequested =>
      'Powiadom, gdy Twoja recenzja będzie potrzebna w pull requeście.';

  @override
  String get notificationReviewStale => 'Nieaktualna recenzja';

  @override
  String get notifyReviewStale =>
      'Gdy nowe commity trafią do pull requesta, który już zrecenzowałeś';

  @override
  String get notificationPrMergeReadiness => 'Gotowy do scalenia';

  @override
  String get notifyPrMergeReadiness =>
      'Powiadom, gdy utworzony przez Ciebie pull request stanie się możliwy do scalenia albo przestanie.';

  @override
  String get notificationPrReviewDecision => 'Decyzje recenzji';

  @override
  String get notifyPrReviewDecision =>
      'Powiadom, gdy recenzent zatwierdzi, zażąda zmian albo gdy jego zatwierdzenie zostanie odrzucone.';

  @override
  String get notificationPrChecksStatus => 'Sprawdzenia';

  @override
  String get notifyPrChecksStatus =>
      'Powiadom, gdy CI zawiedzie w Twoim pull requeście i gdy znów zadziała.';

  @override
  String get notificationPrThreadActivity => 'Wątki recenzji';

  @override
  String get notifyPrThreadActivity =>
      'Powiadom, gdy ktoś odpowie w wątku, w którym uczestniczysz, albo go rozwiąże.';

  @override
  String get notificationPrReadyToMerge => 'Gotowy do scalenia';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '$prTitle ma wszystko, czego potrzebuje.';
  }

  @override
  String get notificationPrMergeBlocked => 'Scalanie już niemożliwe';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '$prTitle jest w konflikcie z gałęzią bazową.';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '$prTitle jest w tyle za gałęzią bazową.';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '$prTitle czeka na wymaganą recenzję.';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'Recenzent zażądał zmian w $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return 'Sprawdzenia nie przechodzą na $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '$prTitle nie może już zostać scalony.';
  }

  @override
  String get notificationPrApproved => 'Pull request zatwierdzony';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '$login zatwierdził $prTitle';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '$prTitle został zatwierdzony';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Czeka jeszcze odpowiedź $count recenzenta',
      many: 'Czeka jeszcze odpowiedź $count recenzentów',
      few: 'Czekają jeszcze odpowiedzi $count recenzentów',
      one: 'Czeka jeszcze odpowiedź 1 recenzenta',
      zero: 'Nie czeka już żaden recenzent',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => 'Zażądano zmian';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '$login zażądał zmian w $prTitle';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return 'Zażądano zmian w $prTitle';
  }

  @override
  String get notificationPrReviewDismissed => 'Zatwierdzenie odrzucone';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '$prTitle wymaga ponownej recenzji.';
  }

  @override
  String get notificationPrChecksFailed => 'Sprawdzenia nieudane';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '$checkName nie powiódł się na $prTitle';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return 'Sprawdzenia nie przechodzą na $prTitle';
  }

  @override
  String get notificationPrChecksRecovered => 'Sprawdzenia przechodzą';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '$prTitle jest znów zielony.';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '$login wspomniał o Tobie w $location';
  }

  @override
  String get notificationPrThreadReplied => 'Nowa odpowiedź';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '$login odpowiedział w $location';
  }

  @override
  String get notificationPrThreadResolved => 'Wątek rozwiązany';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return 'Twój wątek w $location został rozwiązany.';
  }

  @override
  String get notificationGroupAgents => 'Agenci';

  @override
  String get notificationGroupPullRequests => 'Pull requesty';

  @override
  String get notificationGroupMessages => 'Wiadomości';

  @override
  String get notificationGroupTickets => 'Zgłoszenia';

  @override
  String get notificationGroupCalendar => 'Kalendarz';

  @override
  String get notificationGroupMachines => 'Maszyny';

  @override
  String get notificationsMutedRepos => 'Wyciszone repozytoria';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wyciszono $count repozytorium',
      many: 'Wyciszono $count repozytoriów',
      few: 'Wyciszono $count repozytoria',
      one: 'Wyciszono 1 repozytorium',
      zero: 'Brak wyciszonych repozytoriów',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'Wycisz to repozytorium';

  @override
  String get onboardingLinuxDescription =>
      'Control Center może używać kontenerów Linuksa do odizolowania wykonywania agentów.';

  @override
  String get onboardingMacosDescription =>
      'Control Center używa natywnego sandboxa w systemie macOS do odizolowania wykonywania agentów.';

  @override
  String get onboardingUnsupportedDescription =>
      'Sandbox jest niedostępny na tej platformie. Wykonywanie agentów będzie bez izolacji.';

  @override
  String get openArticlesInApp => 'Otwieraj artykuły w aplikacji';

  @override
  String get openInBrowser => 'Otwórz w przeglądarce';

  @override
  String get openedInYourBrowser => 'Otwarto w przeglądarce.';

  @override
  String get openLabel => 'Otwórz';

  @override
  String get openOnGithub => 'Otwórz na GitHubie';

  @override
  String get openStatus => 'Otwarte';

  @override
  String get optionalPersonaDescription => 'Opcjonalny opis persony';

  @override
  String get otherLabel => 'Inne';

  @override
  String get ownerOrganization => 'Właściciel / Organizacja';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => 'Zaliczone';

  @override
  String get pasteValueHere => 'Wklej wartość tutaj';

  @override
  String get persona => 'Persona';

  @override
  String get policies => 'Polityki';

  @override
  String get policiesHint =>
      'Polityki pojawią się tutaj, gdy agenty awansują fakty.';

  @override
  String get policy => 'Polityka';

  @override
  String get popular => 'Popularne';

  @override
  String get port => 'Port';

  @override
  String get postingEllipsis => 'Publikowanie…';

  @override
  String get prCommits => 'Commity';

  @override
  String get prMergedBody => 'Pull request został scalony';

  @override
  String get prMoreActions => 'Więcej akcji';

  @override
  String get prTitle => 'Tytuł PR';

  @override
  String get reviewCommentHint =>
      'Po prostu kliknij zatwierdź, a jeśli czujesz się odważnie, dodaj komentarz lub reakcję…';

  @override
  String get nothingToPreview => 'Nie ma czego podglądać';

  @override
  String get previousMatch => 'Poprzednie dopasowanie (⇧↵)';

  @override
  String get priorityReviewsDescription =>
      'Priorytetowe recenzje i przegląd repozytoriów.';

  @override
  String get prsCreated => 'Utworzone PR';

  @override
  String get prsMerged => 'Scalone PR';

  @override
  String get publishToGithub => 'Opublikuj na GitHubie';

  @override
  String get published => 'Opublikowano';

  @override
  String get pullRequestApproved => 'Pull request zatwierdzony';

  @override
  String get pullRequests => 'Pull requesty';

  @override
  String get questionLabel => 'PYTANIE';

  @override
  String get queued => 'W kolejce';

  @override
  String get react => 'Zareaguj';

  @override
  String get readPrsIssuesMetadata =>
      'Pozwala agentowi czytać PR, issues i metadane repozytorium.';

  @override
  String get readerPreferences => 'Preferencje czytnika';

  @override
  String get reasoningEffort => 'Wysiłek rozumowania';

  @override
  String get recommendLabel => 'POLECANE';

  @override
  String recordingFromDevice(String device) {
    return 'Nagrywanie z $device.';
  }

  @override
  String get redownload => 'Pobierz ponownie';

  @override
  String get redownloadEmbeddingModel => 'Pobrać ponownie model osadzeń?';

  @override
  String get redownloadVoiceModel => 'Pobrać ponownie model głosowy?';

  @override
  String get refinePlan => 'Dopracuj plan';

  @override
  String get refresh => 'Odśwież';

  @override
  String get refreshAll => 'Odśwież wszystko';

  @override
  String get refreshAllFeeds => 'Odśwież wszystkie kanały';

  @override
  String get reject => 'Odrzuć';

  @override
  String get rejected => 'Odrzucono';

  @override
  String get reload => 'Przeładuj';

  @override
  String get remove => 'Usuń';

  @override
  String get removeBookmark => 'Usuń zakładkę';

  @override
  String get removeEmbeddingModel => 'Usunąć model osadzeń?';

  @override
  String get removeLogo => 'Usuń logo';

  @override
  String get removeRepoFromWorkspace =>
      'Usunąć repozytorium z obszaru roboczego?';

  @override
  String get removeVoiceModel => 'Usunąć model głosowy?';

  @override
  String get removed => 'Usunięto';

  @override
  String get renamed => 'Zmieniono nazwę';

  @override
  String get reopen => 'Otwórz ponownie';

  @override
  String get resolve => 'Rozwiąż';

  @override
  String get replyEllipsis => 'Odpowiedz…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name zostanie usunięty z tego obszaru roboczego. Lokalne pliki na dysku nie zostaną dotknięte.';
  }

  @override
  String repoAccessNoticeBody(String repos) {
    return 'Dane uwierzytelniające GitHub serwera nie widzą $repos. Jeśli repozytorium należy do organizacji, zainstaluj tam GitHub App albo podłącz token z dostępem.';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Brak dostępu do $count repozytorium',
      many: 'Brak dostępu do $count repozytoriów',
      few: 'Brak dostępu do $count repozytoriów',
      one: 'Brak dostępu do repozytorium',
    );
    return '$_temp0';
  }

  @override
  String get repoAccessNoticeSuspendedTitle =>
      'Instalacja GitHub App została wstrzymana';

  @override
  String repoAccessNoticeSuspendedBody(String repos) {
    return 'Wyświetlane są ostatnio znane dane dla $repos. Wznów instalację na GitHubie albo podłącz token z dostępem.';
  }

  @override
  String get repoNoAccessBadge => 'Brak dostępu';

  @override
  String get reportsTo => 'Raportuje do';

  @override
  String reposCount(int count) {
    return 'Repozytoria ($count)';
  }

  @override
  String get reposDescription =>
      'Lokalne checkouty, na których pracuje ten obszar roboczy.';

  @override
  String get repositories => 'Repozytoria';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repozytorium',
      many: '$count repozytoriów',
      few: '$count repozytoria',
      one: '$count repozytorium',
    );
    return 'Nie udało się dodać $_temp0: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dodano $count repozytorium',
      many: 'Dodano $count repozytoriów',
      few: 'Dodano $count repozytoria',
      one: 'Dodano repozytorium',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'Ustawienia repozytoriów';

  @override
  String get repositoryName => 'Nazwa repozytorium';

  @override
  String get requestChanges => 'Zażądaj zmian';

  @override
  String get requested => 'Zażądano';

  @override
  String get requestedChanges => 'Zażądane zmiany';

  @override
  String requiredRoleLabel(String role) {
    return 'Wymagana rola: $role';
  }

  @override
  String get requiredRoleOptional => 'Wymagana rola (opcjonalnie)';

  @override
  String get requirements => 'Wymagania';

  @override
  String get reset => 'Resetuj';

  @override
  String get resolved => 'Rozwiązane';

  @override
  String get enclosedTerminalTitle => 'Zamknięty terminal';

  @override
  String get enclosedTerminalStart => 'Otwórz powłokę';

  @override
  String get enclosedTerminalStartHint =>
      'Ta powłoka działa w jednorazowej maszynie wirtualnej tej rozmowy. Uruchamia się, gdy ją otworzysz, a nie gdy startuje aplikacja.';

  @override
  String get terminalStreamReconnecting =>
      'strumień przerwany — ponowne łączenie…';

  @override
  String get terminalStreamError => 'błąd strumienia:';

  @override
  String get terminalShellExited => 'powłoka zakończyła działanie';

  @override
  String get restartShell => 'Uruchom powłokę ponownie';

  @override
  String get retry => 'Ponów';

  @override
  String get review => 'Recenzja';

  @override
  String get reviewedByMe => 'Zrecenzowane przeze mnie';

  @override
  String get reviewers => 'Recenzenci';

  @override
  String get roleLabel => 'Rola';

  @override
  String get ruleHint => 'Reguła polityki (obsługa markdown)';

  @override
  String get ruleLabel => 'Reguła';

  @override
  String get runCompleted => 'Uruchomienie zakończone';

  @override
  String get running => 'Działa';

  @override
  String get runningLabel => 'uruchomione';

  @override
  String get runs => 'Uruchomienia';

  @override
  String get runsLabel => 'Uruchomienia';

  @override
  String get sandboxBackendNativeLabel => 'Natywny sandbox';

  @override
  String get sandboxBackendMicrovmLabel => 'Zamknięta VM';

  @override
  String get sandboxBackendNoneLabel => 'Bez izolacji';

  @override
  String get sandboxLinuxInstall =>
      'Natywna piaskownica na Linux/WSL2 korzysta z bubblewrap. Instalacja:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'Natywna piaskownica jest wbudowana w macOS — korzysta z Apple Seatbelt (`sandbox-exec`). Instalacja nie jest wymagana.';

  @override
  String get sandboxPermissions => 'Uprawnienia piaskownicy';

  @override
  String get sandboxUnsupported =>
      'Natywna piaskownica nie jest jeszcze obsługiwana na tej platformie. Używane jest „Bez izolacji”.';

  @override
  String get sandboxingDisabledDescription =>
      'Agenty działają bezpośrednio na hoście z pełnym środowiskiem — niezalecane.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Wszystkie wywołania agenta przechodzą przez $backend.';
  }

  @override
  String get save => 'Zapisz';

  @override
  String get saveChanges => 'Zapisz zmiany';

  @override
  String get adapterArguments => 'Dodatkowe argumenty';

  @override
  String get adapterArgumentsHint => 'Dodatkowe flagi CLI (np. --yolo)';

  @override
  String get addVariable => 'Dodaj zmienną';

  @override
  String get environmentVariables => 'Zmienne środowiskowe';

  @override
  String get environmentVariablesDescription =>
      'Niestandardowe zmienne środowiskowe przekazywane do tego adaptera (np. klucze API). Przechowywane w pęku kluczy.';

  @override
  String get variableKey => 'Klucz';

  @override
  String get variableValue => 'Wartość';

  @override
  String get savingEllipsis => 'Zapisywanie…';

  @override
  String get scopeDiffToCommits =>
      'Ogranicz diff do commitów — Shift+klik dla zakresu';

  @override
  String get noPrsMatchSearch => 'Brak pasujących pull requestów';

  @override
  String get searchFactsHint => 'Szukaj faktów...';

  @override
  String get searchFonts => 'Szukaj czcionek…';

  @override
  String get searchGifs => 'Szukaj GIF-ów';

  @override
  String get searchGifsHint => 'Szukaj GIF-ów...';

  @override
  String get searchInDiffHint => 'Szukaj w diffie…';

  @override
  String get searchOrTypeModel => 'Szukaj lub wpisz nazwę modelu…';

  @override
  String get searchPlaceholder => 'Szukaj…';

  @override
  String get searchShortcuts => 'Szukaj skrótów…';

  @override
  String get shortcutUnavailableInBrowser => 'Niedostępne w przeglądarce';

  @override
  String get searching => 'Wyszukiwanie…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sekund temu',
      many: '$count sekund temu',
      few: '$count sekundy temu',
      one: '$count sekundę temu',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Wybierz adapter';

  @override
  String get selectAdapterFirst => 'Najpierw wybierz adapter';

  @override
  String get selectAgentToReportTo => 'Wybierz agenta, któremu zgłosić…';

  @override
  String get selectAnAgent => 'Wybierz agenta';

  @override
  String get selectConversation => 'Wybierz rozmowę';

  @override
  String get selectLabel => 'Wybierz';

  @override
  String get selectRunner => 'Wybierz runner';

  @override
  String get semanticSearch => 'Wyszukiwanie semantyczne';

  @override
  String get send => 'Wyślij';

  @override
  String get sendFirstMessage => 'Wyślij pierwszą wiadomość';

  @override
  String get sendMessage => 'Wyślij wiadomość';

  @override
  String sentFindingsToAgent(int count) {
    return 'Sent $count finding(s) to agent.';
  }

  @override
  String setGithubLinkDescription(String name) {
    return 'Ustaw właściciela i nazwę repozytorium GitHub dla $name. Służy do rozpoznawania odwołań do PR i zgłoszeń takich jak #123 w treści markdown.';
  }

  @override
  String get setLabel => 'Ustaw';

  @override
  String get setToken => 'Ustaw token';

  @override
  String get settingsLabel => 'Ustawienia';

  @override
  String get settingsLanguage => 'Język';

  @override
  String get settingsLanguageDescription => 'Wybierz język aplikacji.';

  @override
  String get shortTask => 'Krótkie zadanie';

  @override
  String get showNativeNotifications =>
      'Pokazuj natywne powiadomienia macOS dla zdarzeń.';

  @override
  String get showSuperseded => 'Pokaż zastąpione';

  @override
  String get signedIn => 'Zalogowano.';

  @override
  String signedInAs(String username) {
    return 'Zalogowano jako $username.';
  }

  @override
  String get skillNameRequired => 'Nazwa skillu jest wymagana.';

  @override
  String skillSaved(String name) {
    return 'Zapisano skill „$name”.';
  }

  @override
  String get skillsSourcesTab => 'Źródła';

  @override
  String get skillSourcesDisclaimer =>
      'Skille instalujesz z dodanych repozytoriów GitHub. Metadane repozytorium są niezaufane — prawdziwym sygnałem bezpieczeństwa jest skan antywirusowy.';

  @override
  String get skillSourcesEmpty => 'Brak repozytoriów skilli';

  @override
  String get skillSourcesEmptyHint =>
      'Dodaj repozytorium GitHub, aby przeglądać jego skille.';

  @override
  String get skillSourceAdd => 'Dodaj repozytorium';

  @override
  String get skillSourceAddTitle => 'Dodaj repozytorium skilli';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      'Podaj URL repozytorium GitHub (https://github.com/owner/repo).';

  @override
  String skillSourceAdded(String repo) {
    return 'Dodano repozytorium $repo.';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'Repozytorium $repo jest już dodane.';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'Usunięto repozytorium $repo.';
  }

  @override
  String get skillSourceRemove => 'Usuń';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return 'Usunąć $repo?';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'Zainstalowane skille pozostaną. Usunięty zostanie tylko katalog repozytorium.';

  @override
  String get skillSourceNoSkills =>
      'W tym repozytorium nie znaleziono skilli (skill to katalog zawierający SKILL.md).';

  @override
  String get skillSourceRefresh => 'Odśwież';

  @override
  String get skillSourceInstalledBadge => 'Zainstalowany';

  @override
  String get skillSourceUpdateBadge => 'Dostępna aktualizacja';

  @override
  String get skillSourceSlugTaken => 'Nazwa zajęta';

  @override
  String skillSourceFilesCount(num count) {
    return '$count plików';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'Ten skill nie ma pliku README.';

  @override
  String get skillSourceNoMatches => 'Żaden skill nie pasuje do filtra.';

  @override
  String get skillUpdateAction => 'Aktualizuj';

  @override
  String get skillUninstallAction => 'Odinstaluj';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return 'Odinstalować „$slug”?';
  }

  @override
  String skillUninstalled(String slug) {
    return 'Odinstalowano skill „$slug”.';
  }

  @override
  String get skillFindingLine => 'wiersz';

  @override
  String get skillInstallAnywayOverride =>
      'Rozumiem ryzyko — zainstaluj mimo to';

  @override
  String skillInstalled(String slug) {
    return 'Zainstalowano skill „$slug”.';
  }

  @override
  String get skillPreviewCapabilities => 'Możliwości';

  @override
  String get skillPreviewFindings => 'Ustalenia';

  @override
  String get skillPreviewGuardedActions => 'Chronione działania';

  @override
  String get skillPreviewLlmReviewed => 'Przejrzane przez LLM';

  @override
  String get skillPreviewNoCapabilities => 'Nie zadeklarowano możliwości.';

  @override
  String get skillPreviewNoFindings => 'Brak ustaleń.';

  @override
  String get skillPreviewScanning => 'Skanowanie skilla…';

  @override
  String get skillPreviewVerdictLabel => 'Werdykt skanu';

  @override
  String get skillPreviewVerdictPass => 'Zaliczony';

  @override
  String get skillPreviewVerdictQuarantine => 'Kwarantanna';

  @override
  String get skillPreviewVerdictWarn => 'Ostrzeżenie';

  @override
  String get skillQuarantineWarning =>
      'Skaner objął ten skill kwarantanną. Instalacja uruchamia kod na Twoim komputerze. Kontynuuj tylko, jeśli ufasz źródłu i zapoznałeś się z ustaleniami.';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'W kwarantannie i odłączony od agentów: $agents';
  }

  @override
  String get skillNotScanned => 'Nieskanowany';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'Ręczne';

  @override
  String get skillOriginRegistry => 'Rejestr';

  @override
  String get skillOriginRuntimeLocal => 'Lokalny runtime';

  @override
  String get skillRulesStale => 'Skan nieaktualny';

  @override
  String get skillSaveAnywayOverride => 'Rozumiem ryzyko — zapisz mimo to';

  @override
  String get skillSaveBlockedBody =>
      'Treść została zablokowana, zanim cokolwiek zapisano.';

  @override
  String get skillSaveBlockedTitle => 'Zapis zablokowany przez bramkę skanu';

  @override
  String get skillScanAction => 'Skanuj';

  @override
  String get skillScanAll => 'Skanuj wszystko';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass zaliczone · $warn ostrzeżenia · $quarantine w kwarantannie';
  }

  @override
  String get skillStateDrifted => 'Zmieniony od instalacji';

  @override
  String get skillStateUnmanaged => 'Niezarządzany';

  @override
  String get skillSeverityBlocked => 'Zablokowany';

  @override
  String get skillSeverityWarn => 'Ostrzeżenie';

  @override
  String get skillsInstalledTab => 'Zainstalowane';

  @override
  String get skills => 'Umiejętności';

  @override
  String get skipAcceptRisk => 'Pomiń — akceptuję ryzyko';

  @override
  String get skipForNow => 'Pomiń na razie';

  @override
  String get skipSandboxing => 'Pomiń sandboxing';

  @override
  String get skipSandboxingDialogContent =>
      'Na pewno chcesz pominąć sandboxing? Agenty będą mogły wykonywać kod w systemie bez izolacji.';

  @override
  String get somethingWentWrong => 'Coś poszło nie tak';

  @override
  String sourceCount(int count) {
    return '$count źródło';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count źródeł';
  }

  @override
  String get sourceFacts => 'Fakty źródłowe:';

  @override
  String get splitDiff => 'Podzielony diff (obok siebie)';

  @override
  String get startLabel => 'Uruchom';

  @override
  String get startOnAppLaunch => 'Uruchom przy starcie aplikacji';

  @override
  String get statusLabel => 'Status';

  @override
  String get onboardingStepConnect => 'Połącz';

  @override
  String get onboardingStepWorkspace => 'Obszar roboczy';

  @override
  String get onboardingStepSandbox => 'Sandbox';

  @override
  String get onboardingStepAdapter => 'Adapter';

  @override
  String get onboardingStepVoice => 'Głos';

  @override
  String get stop => 'Zatrzymaj';

  @override
  String get stopped => 'Zatrzymano';

  @override
  String get strictIdentityCheck => 'Ścisła weryfikacja tożsamości';

  @override
  String get success => 'Sukces';

  @override
  String get successLabel => 'Sukces';

  @override
  String get suggestAChange => 'Zasugeruj zmianę';

  @override
  String get suggestLabel => 'SUGESTIA';

  @override
  String get superseded => 'Zastąpiono';

  @override
  String get synced => 'Zsynchronizowano';

  @override
  String get systemDefault => 'Domyślne systemowe';

  @override
  String get systemFonts => 'Czcionki systemowe';

  @override
  String get systemPrompt => 'Prompt systemowy';

  @override
  String get systemPromptLabel => 'Prompt systemowy';

  @override
  String get talkToControlCenter => 'Porozmawiaj z Control Center.';

  @override
  String get taskMentionSection => 'Zadanie';

  @override
  String get testLabel => 'Test';

  @override
  String get theme => 'Motyw';

  @override
  String get themeDark => 'Ciemny';

  @override
  String get themeLight => 'Jasny';

  @override
  String get themeSystem => 'Systemowy';

  @override
  String get thisCannotBeUndone => 'Tej operacji nie można cofnąć.';

  @override
  String get ticketLabel => 'ZGŁOSZENIE';

  @override
  String get titleLabel => 'Tytuł';

  @override
  String get todayLabel => 'Dzisiaj';

  @override
  String get toggleTheme => 'Przełącz motyw';

  @override
  String get tokenConfigured =>
      'Skonfigurowano — klienci muszą podać ten token.';

  @override
  String get topic => 'Temat';

  @override
  String get topicHint => 'np. Tech Stack, Design System';

  @override
  String get totalRuns => 'Łącznie uruchomień';

  @override
  String trackingParamsCount(int count) {
    return '$count parametrów śledzenia';
  }

  @override
  String get typeCommandOrSearch => 'Wpisz polecenie lub wyszukaj…';

  @override
  String get typography => 'Typografia';

  @override
  String get unavailable => 'Niedostępne';

  @override
  String get unifiedDiff => 'Zunifikowany diff';

  @override
  String get unknownAuthor => 'Nieznany';

  @override
  String get unnamedAgent => 'Agent bez nazwy';

  @override
  String get updateKey => 'Aktualizuj klucz';

  @override
  String get updateLabel => 'Aktualizuj';

  @override
  String get updateToken => 'Aktualizuj token';

  @override
  String updatedDaysAgo(int count) {
    return 'Zaktualizowano $count dn. temu';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'Zaktualizowano $count godz. temu';
  }

  @override
  String get updatedJustNow => 'Zaktualizowano przed chwilą';

  @override
  String updatedMinutesAgo(int count) {
    return 'Zaktualizowano $count min temu';
  }

  @override
  String get useSandbox => 'Użyj piaskownicy';

  @override
  String get useWorkspaceDefault =>
      'Użyj domyślnych ustawień obszaru roboczego';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'Pozostaw puste, aby użyć domyślnego User-Agent aplikacji. Niektóre witryny blokują User-Agent spoza przeglądarki.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Używany jest domyślny mikrofon systemu.';

  @override
  String get viewLabel => 'Widok';

  @override
  String get viewLogs => 'Pokaż logi';

  @override
  String voiceInstallFailed(String error) {
    return 'Instalacja nie powiodła się: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Nie zainstalowano. Jednorazowe pobranie ~200 MB; działa w pełni na urządzeniu.';

  @override
  String get voiceModelNotInstalledLabel =>
      'Model głosowy nie jest zainstalowany.';

  @override
  String get voiceRedownloadBody =>
      'Istniejące pliki modelu zostaną usunięte, a archiwum (~200 MB) zostanie pobrane ponownie. Transkrypcja głosu będzie niedostępna do zakończenia pobierania.';

  @override
  String get voiceRemoveBody =>
      'Transkrypcja głosu zostanie wyłączona do czasu ponownej instalacji. Możesz zainstalować ją ponownie w dowolnym momencie.';

  @override
  String get voiceTranscription => 'Transkrypcja głosu';

  @override
  String get weakIsolationDescription =>
      'Słaba izolacja — tylko granica przestrzeni nazw, bez granicy jądra.';

  @override
  String get whenOffNoDefaultRoute =>
      'Gdy wyłączone, piaskownica uruchamia się bez trasy domyślnej.';

  @override
  String get whenOffServerStaysStopped =>
      'Gdy wyłączone, serwer pozostaje zatrzymany, dopóki go nie uruchomisz.';

  @override
  String get speechModel => 'Model mowy';

  @override
  String get speechModelHint =>
      'Używany do transkrypcji spotkań i mikrofonu w Composerze.';

  @override
  String get voiceModelInstalled =>
      'Zainstalowano. Obsługuje transkrypcję spotkań i przycisk mikrofonu w Composerze.';

  @override
  String get meetingMicSilentWarning =>
      'Mikrofon może być wyciszony — inni mówią, ale nic nie dociera do mikrofonu.';

  @override
  String get meetingSummaryPrivacyNotice =>
      'Nagrywanie i transkrypcja pozostają na tym komputerze. Podsumowanie pisze agent, więc jeśli używa modelu w chmurze, transkrypt i notatki są wysyłane do tego dostawcy.';

  @override
  String get meetingTemplates => 'Szablony notatek ze spotkań';

  @override
  String get meetingTemplatesHint =>
      'Dostosuj podsumowanie AI do rodzaju spotkania. Aktywny szablon dotyczy nowych podsumowań i ponownych wygenerowań.';

  @override
  String get meetingTemplateActive => 'Aktywny szablon';

  @override
  String get meetingTemplateAdd => 'Dodaj szablon';

  @override
  String get meetingTemplateNewTitle => 'Nowy szablon';

  @override
  String get meetingTemplateEditTitle => 'Edytuj szablon';

  @override
  String get meetingTemplateNameLabel => 'Nazwa';

  @override
  String get meetingTemplateNameHint => 'np. Przegląd sprintu';

  @override
  String get meetingTemplateInstructionsLabel => 'Instrukcje';

  @override
  String get meetingTemplateInstructionsHint =>
      'Jak AI ma strukturyzować i akcentować te notatki?';

  @override
  String get workingMemory => 'Pamięć robocza';

  @override
  String get workspaceName => 'Nazwa obszaru roboczego';

  @override
  String get workspaceScopedSkills =>
      'Pliki umiejętności z zakresu obszaru roboczego dołączone do agentów.';

  @override
  String get workspaces => 'Obszary robocze';

  @override
  String get writePrivateNotes => 'Pisz prywatne notatki, obserwacje, plany…';

  @override
  String get writeSkillContent => 'Wpisz treść umiejętności tutaj (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lat temu',
      many: '$count lat temu',
      few: '$count lata temu',
      one: '$count rok temu',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Wczoraj';

  @override
  String get focusModeStart => 'Rozpocznij sesję skupienia';

  @override
  String get focusModeConfigTitle => 'Rozpocznij sesję skupienia';

  @override
  String get focusModeGoalLabel => 'Cel';

  @override
  String get focusModeGoalHint => 'Nad czym pracujesz?';

  @override
  String get focusModeDurationLabel => 'Czas trwania';

  @override
  String get focusModeBlockNotifications => 'Blokuj powiadomienia';

  @override
  String get focusModeStartButton => 'Rozpocznij';

  @override
  String get focusModeFloat => 'Zminimalizuj do paska';

  @override
  String get focusModeActiveTooltip =>
      'Tryb skupienia aktywny — dotknij, aby zakończyć';

  @override
  String get dismiss => 'Odrzuć';

  @override
  String get acceptAndResolve => 'Zaakceptuj i rozwiąż';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'Przeglądasz już od $minutes min — badania wskazują, że jakość recenzji może spaść po 60 min. Rozważ przerwę.';
  }

  @override
  String get notificationSound => 'Dźwięk powiadomienia';

  @override
  String get notificationSoundDescription =>
      'Dźwięk odtwarzany przy wyświetleniu powiadomienia.';

  @override
  String get notificationSoundNone => 'Brak';

  @override
  String get notificationSoundPing => 'Ping';

  @override
  String get notificationSoundChime => 'Chime';

  @override
  String get notificationSoundPop => 'Pop';

  @override
  String get notificationSoundDing => 'Ding';

  @override
  String get notificationSoundWhoosh => 'Whoosh';

  @override
  String get notificationSoundMigrosSoft => 'Migros (miękki)';

  @override
  String get notificationSoundMigrosHard => 'Migros (twardy)';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => 'Test';

  @override
  String get notificationVolume => 'Głośność';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Brak PR użytkownika @$login w tym obszarze roboczym';
  }

  @override
  String get usersLabel => 'Użytkownicy';

  @override
  String get mergePullRequest => 'Scal pull request';

  @override
  String get forceMergePullRequest => 'Wymuś scalenie pull requestu';

  @override
  String get closePullRequest => 'Zamknij pull request';

  @override
  String get closePullRequestConfirm =>
      'Czy na pewno chcesz zamknąć ten pull request?';

  @override
  String get stackedPullRequests => 'Stos pull requestów';

  @override
  String partOfStack(int position, int total) {
    return 'Część stosu ($position z $total)';
  }

  @override
  String get createStack => 'Utwórz stos';

  @override
  String get createStackDialogTitle => 'Utwórz stos pull requestów';

  @override
  String createStackDialogBody(int count) {
    return 'Te $count pull requesty zostaną ułożone w stos, od dołu:';
  }

  @override
  String get createStackInvalidSelection =>
      'Wybierz co najmniej dwa pull requesty z tego samego repozytorium, aby utworzyć stos';

  @override
  String get createStackNotAChain =>
      'Wybrane pull requesty nie tworzą łańcucha: gałąź bazowa każdego pull requestu musi być gałęzią head poprzedniego';

  @override
  String get createStackAlreadyStacked =>
      'Co najmniej jeden z wybranych pull requestów jest już w stosie';

  @override
  String get stackCreated => 'Utworzono stos';

  @override
  String get stackCreationFailed => 'Nie udało się utworzyć stosu';

  @override
  String get squashAndMerge => 'Scal ze squashowaniem';

  @override
  String get createMergeCommit => 'Utwórz commit scalający';

  @override
  String get rebaseAndMerge => 'Rebase i scal';

  @override
  String get commitTitle => 'Tytuł commita';

  @override
  String get commitDescription => 'Opis commita';

  @override
  String get pullRequestMerged => 'Scalono pull request';

  @override
  String get pullRequestClosed => 'Zamknięto pull request';

  @override
  String failedToMergePr(String error) {
    return 'Nie udało się scalić: $error';
  }

  @override
  String failedToClosePr(String error) {
    return 'Nie udało się zamknąć: $error';
  }

  @override
  String get markReadyForReview => 'Gotowe do recenzji';

  @override
  String get markReadyForReviewConfirm =>
      'Ten pull request przestanie być wersją roboczą. Recenzenci zostaną powiadomieni, wymagane kontrole zaczną blokować scalenie, a automatyzacja nasłuchująca gotowych pull requestów zostanie uruchomiona.';

  @override
  String get convertToDraft => 'Konwertuj na wersję roboczą';

  @override
  String get convertToDraftConfirm =>
      'Ten pull request wróci do wersji roboczej. Oczekujące prośby o recenzję zostaną odrzucone i nie będzie można go scalić, dopóki ponownie nie oznaczysz go jako gotowy.';

  @override
  String get pullRequestMarkedReady =>
      'Oznaczono pull request jako gotowy do recenzji';

  @override
  String get pullRequestConvertedToDraft =>
      'Przekonwertowano pull request na wersję roboczą';

  @override
  String failedToMarkPrReady(String error) {
    return 'Nie udało się oznaczyć jako gotowy do recenzji: $error';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'Nie udało się przekonwertować na wersję roboczą: $error';
  }

  @override
  String get checksFailing => 'Kontrole nie przechodzą';

  @override
  String get reviewsPending => 'Oczekują recenzje';

  @override
  String get mergeConflictsWithBase =>
      'Ta gałąź ma konflikty, które trzeba rozwiązać';

  @override
  String get branchOutOfDateWithBase =>
      'Ta gałąź jest nieaktualna względem gałęzi bazowej';

  @override
  String get mergeBlockedByBranchProtection =>
      'Ochrona gałęzi blokuje to scalenie';

  @override
  String get confirm => 'Potwierdź';

  @override
  String get trustedSitesSectionTitle => 'Zaufane witryny';

  @override
  String get trustedSitesEmpty =>
      'Brak zaufanych witryn. Dodaj domenę, aby wyłączyć na niej blokowanie.';

  @override
  String get addTrustedSite => 'Dodaj zaufaną witrynę';

  @override
  String get removeTrustedSite => 'Usuń';

  @override
  String get disableBlockingForThisSite => 'Wyłącz blokowanie na tej witrynie';

  @override
  String get enableBlockingForThisSite => 'Włącz blokowanie na tej witrynie';

  @override
  String get enterDomainHint => 'np. example.com';

  @override
  String get invalidDomain => 'Podaj prawidłową domenę (np. example.com)';

  @override
  String get pageLoadTimedOut =>
      'Przekroczono czas ładowania strony. Odśwież lub otwórz w przeglądarce.';

  @override
  String get pipelinesScreenTitle => 'Potoki';

  @override
  String get pipelinesScreenSubtitle =>
      'Deklaratywne wieloetapowe przepływy pracy agentów';

  @override
  String get pipelinesRunPipeline => 'Uruchom potok';

  @override
  String get pipelineRunLauncherTitle => 'Uruchom potok';

  @override
  String get pipelineRunSubtitle =>
      'Wybierz potok i uzupełnij dane wejściowe, aby go uruchomić.';

  @override
  String get pipelineRunNoInputsBadge => 'Brak danych wejściowych';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pola wejściowe',
      many: '$count pól wejściowych',
      few: '$count pola wejściowe',
      one: '$count pole wejściowe',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs =>
      'Ten potok nie przyjmuje danych wejściowych.';

  @override
  String get pipelineRunSubmit => 'Uruchom potok';

  @override
  String get pipelineRunCouldNotStart =>
      'Nie udało się rozpocząć uruchomienia.';

  @override
  String pipelineRunStarted(String name) {
    return 'Uruchomiono $name';
  }

  @override
  String get pipelineRunEmptyTitle => 'Brak potoków gotowych do uruchomienia';

  @override
  String get pipelineRunEmptyHint =>
      'Włącz potok i zezwól na ręczne uruchamianie w jego edytorze, aby uruchamiać go tutaj.';

  @override
  String get pipelineRunManageTemplates => 'Zarządzaj potokami';

  @override
  String get pipelineRunSettingsTitle => 'Ręczne uruchamianie';

  @override
  String get pipelineRunSettingsAllow => 'Zezwól na ręczne uruchamianie';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Pokaż ten potok na stronie uruchamiania, aby można było uruchomić go ręcznie.';

  @override
  String get pipelineRunSettingsConcurrencyTitle => 'Współbieżność';

  @override
  String get pipelineRunSettingsMaxParallel => 'Maks. równoległych uruchomień';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'Zostaw puste, aby nie ograniczać. Nadmiarowe uruchomienia czekają w kolejce i startują, gdy zwolni się miejsce.';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'Bez limitu';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      'Podaj liczbę całkowitą 1 lub większą albo zostaw puste, aby nie ograniczać.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Dane wejściowe';

  @override
  String get pipelineRunSettingsAddInput => 'Dodaj pole';

  @override
  String get pipelineRunSettingsNoInputs => 'Brak pól wejściowych.';

  @override
  String get pipelineInputEditTitle => 'Pole wejściowe';

  @override
  String get pipelineInputKeyLabel => 'Klucz';

  @override
  String get pipelineInputKeyHelp =>
      'Klucz stanu, pod którym zapisywana jest wartość (np. repo_full_name).';

  @override
  String get pipelineInputLabelLabel => 'Etykieta';

  @override
  String get pipelineInputTypeLabel => 'Typ';

  @override
  String get pipelineInputOptionsLabel => 'Opcje (oddzielone przecinkami)';

  @override
  String get pipelineInputDefaultLabel => 'Wartość domyślna';

  @override
  String get pipelineInputPlaceholderLabel => 'Tekst zastępczy';

  @override
  String get pipelineInputHelpLabel => 'Tekst pomocy';

  @override
  String get pipelineInputRequiredLabel => 'Wymagane';

  @override
  String get pipelineInputTypeText => 'Tekst';

  @override
  String get pipelineInputTypeMultiline => 'Tekst wielowierszowy';

  @override
  String get pipelineInputTypeNumber => 'Liczba';

  @override
  String get pipelineInputTypeBoolean => 'Przełącznik';

  @override
  String get pipelineInputTypeSelect => 'Lista wyboru';

  @override
  String get pipelinesEmpty => 'Brak uruchomień potoków';

  @override
  String get pipelinesEmptyHint => 'Kliknij „Uruchom potok”, aby rozpocząć.';

  @override
  String get pipelinesNoSteps => 'Brak zarejestrowanych kroków';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Wybierz obszar roboczy, aby zobaczyć jego potoki';

  @override
  String pipelinesLoadError(String error) {
    return 'Nie udało się wczytać potoków: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Nie udało się uruchomić potoku: $error';
  }

  @override
  String get pipelineStatusPending => 'Oczekujące';

  @override
  String get pipelineStatusQueued => 'W kolejce';

  @override
  String get pipelineStatusRunning => 'W toku';

  @override
  String get pipelineStatusSuspended => 'Wstrzymane';

  @override
  String get pipelineStatusCompleted => 'Ukończone';

  @override
  String get pipelineStatusFailed => 'Niepowodzenie';

  @override
  String get pipelineStatusCancelled => 'Anulowane';

  @override
  String get pipelineStatusSkipped => 'Pominięte';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed z $total kroków';
  }

  @override
  String get pipelineWaterfallTimeline => 'Oś czasu';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'Aktywny $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'bezczynny $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'Czas wyłączony z sumy aktywnej: uruchomienie było zatrzymane lub czekało między krokami.';

  @override
  String get pipelineStepStarted => 'Rozpoczęto';

  @override
  String get pipelineStepFinished => 'Zakończono';

  @override
  String get pipelineStepDurationLabel => 'Czas trwania';

  @override
  String get pipelineStepBranch => 'Gałąź';

  @override
  String get pipelineStepViewConversation => 'Zobacz rozmowę';

  @override
  String get pipelineStepError => 'Błąd';

  @override
  String get pipelineStepInput => 'Wejście';

  @override
  String get pipelineStepOutput => 'Wyjście';

  @override
  String get pipelineStepNotExecuted => 'Jeszcze nie wykonano';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Niepowodzenie na kroku $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Ręczne';

  @override
  String get pipelineStepSkippedReason => 'Pominięto';

  @override
  String get pipelineStepPriorAttempts => 'Poprzednie próby';

  @override
  String get pipelineStepAttemptLabel => 'Próba';

  @override
  String pipelineStepAttemptN(int number) {
    return 'Próba $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'Przerwano';

  @override
  String get pipelineRunColumnPipeline => 'Potok';

  @override
  String get pipelineRunColumnDuration => 'Czas trwania';

  @override
  String get pipelineRunQueueNext => 'Następny';

  @override
  String pipelineRunQueuePosition(int position) {
    return '$position w kolejce';
  }

  @override
  String get pipelineRunColumnStarted => 'Start';

  @override
  String get pipelineRunHistory => 'Historia uruchomień';

  @override
  String get pipelineRunHistoryEmpty => 'Brak innych uruchomień';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'Ponownie $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return 'Próba $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'pierwsze uruchomienie $time';
  }

  @override
  String get pipelineRunFilterAll => 'Wszystkie';

  @override
  String get pipelineRunFilterEmpty => 'Brak uruchomień pasujących do filtra';

  @override
  String get relativeJustNow => 'przed chwilą';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min temu',
      many: '$count min temu',
      few: '$count min temu',
      one: '1 min temu',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count godziny temu',
      many: '$count godzin temu',
      few: '$count godziny temu',
      one: '1 godzinę temu',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dnia temu',
      many: '$count dni temu',
      few: '$count dni temu',
      one: '1 dzień temu',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'Zespoły';

  @override
  String get teamsAddTeam => 'Dodaj zespół';

  @override
  String get teamsLoadError => 'Nie udało się wczytać zespołów';

  @override
  String get teamsEmptyTitle => 'Brak zespołów';

  @override
  String get teamsEmptyDescription =>
      'Grupuj agentów w zespoły, aby praca przypisana do zespołu trafiała do lidera, który deleguje zadania.';

  @override
  String get teamCreateTitle => 'Nowy zespół';

  @override
  String get teamEditTitle => 'Edytuj zespół';

  @override
  String get teamNameLabel => 'Nazwa zespołu';

  @override
  String get teamNameHint => 'np. Frontend';

  @override
  String get teamDescriptionLabel => 'Opis';

  @override
  String get teamDescriptionHint => 'Za co odpowiada ten zespół';

  @override
  String get teamLeaderLabel => 'Lider';

  @override
  String get teamLeaderHelp =>
      'Koordynator, który otrzymuje pracę przypisaną do zespołu i deleguje ją najbardziej odpowiedniemu członkowi.';

  @override
  String get teamNoLeader => 'Brak lidera';

  @override
  String get teamInstructionsLabel => 'Instrukcje operacyjne';

  @override
  String get teamInstructionsHelp =>
      'Dołączane do briefingu lidera — konwencje zespołu, zasady eskalacji, ton.';

  @override
  String get teamInstructionsHint => 'Opcjonalne';

  @override
  String get teamSaved => 'Zapisano zespół';

  @override
  String get teamMembersError => 'Nie udało się wczytać członków';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count członka',
      many: '$count członków',
      few: '$count członków',
      one: '1 członek',
      zero: 'Brak członków',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'Dodaj członka';

  @override
  String get teamAddMemberTitle => 'Dodaj członków';

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
  String get teamNoAgentsToAdd => 'Wszyscy agenci są już w tym zespole.';

  @override
  String get teamRemoveMember => 'Usuń z zespołu';

  @override
  String get teamLeaderBadge => 'Lider';

  @override
  String get teamUnknownAgent => 'Nieznany agent';

  @override
  String get teamMembersEmpty => 'Brak członków';

  @override
  String get teamMembersEmptyDescription =>
      'Dodaj agentów, aby lider miał do kogo delegować.';

  @override
  String get teamSelectPrompt => 'Wybierz zespół';

  @override
  String get teamSelectPromptDescription =>
      'Wybierz zespół z listy lub utwórz nowy.';

  @override
  String get teamDeleteTitle => 'Usunąć zespół?';

  @override
  String teamDeleteBody(String name) {
    return '$name zostanie usunięty. Agenci pozostaną bez zmian.';
  }

  @override
  String get teamHasLeaderTooltip => 'Ma lidera';

  @override
  String get pipelineTemplatesNav => 'Szablony potoków';

  @override
  String get pipelineTemplatesTitle => 'Szablony potoków';

  @override
  String get pipelineTemplatesSubtitle =>
      'Edytor przeciągnij i upuść do potoków orkiestrujących agentów.';

  @override
  String get pipelineTemplatesNew => 'Nowy szablon';

  @override
  String get pipelineTemplatesEmpty =>
      'Nie ma jeszcze szablonów potoków. Utwórz pierwszy, aby zacząć.';

  @override
  String get pipelineTemplateBuiltInBadge => 'Wbudowany';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Usunąć szablon?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Usunąć szablon potoku $name? Tej operacji nie można cofnąć.';
  }

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Przeciągnij typy węzłów z paska bocznego na kanwę i połącz je ze sobą.';

  @override
  String get unsavedChanges => 'Niezapisane zmiany';

  @override
  String get nodeLibraryTitle => 'Biblioteka węzłów';

  @override
  String get nodeLibraryHint =>
      'Przeciągnij dowolny element na kanwę, aby dodać węzeł.';

  @override
  String get editorEmptyCanvas => 'Przeciągnij węzeł z biblioteki, aby zacząć.';

  @override
  String get pipelineWhenThisHappens => 'Gdy to się zdarzy';

  @override
  String get pipelineDoThis => 'Zrób to';

  @override
  String get pipelineAddStep => 'Dodaj krok';

  @override
  String get pipelineTidyUp => 'Uporządkuj układ';

  @override
  String get pipelineEditorHint =>
      'Przeciągnij kroki, aby ułożyć · przeciągnij uchwyt, aby połączyć';

  @override
  String get pipelineRemoveConnection => 'Usuń połączenie';

  @override
  String get pipelineDragToConnect => 'Przeciągnij, aby połączyć';

  @override
  String get pipelineNewDefaultName => 'Nowy potok';

  @override
  String get nodeCategoryTriggers => 'Wyzwalacze';

  @override
  String get triggerEventWebhook => 'Webhook';

  @override
  String get pipelineAddTrigger => 'Dodaj wyzwalacz';

  @override
  String get pipelineOnEvent => 'Przy zdarzeniu';

  @override
  String get nodeConfigTitle => 'Konfiguracja węzła';

  @override
  String get nodeConfigKind => 'Rodzaj';

  @override
  String get nodeConfigLabel => 'Etykieta';

  @override
  String get nodeConfigAgent => 'Agent';

  @override
  String get nodeConfigAgentHint => 'Wybierz agenta…';

  @override
  String get nodeConfigInputKeys => 'Klucze wejściowe (oddzielone przecinkami)';

  @override
  String get nodeConfigInputKeysHelp =>
      'Klucze stanu, które ten węzeł pobiera. Służą do podstawiania placeholderów w prompcie.';

  @override
  String get nodeConfigRepos => 'Repozytoria do sklonowania';

  @override
  String get nodeConfigReposHelp =>
      'Repozytoria klonowane i indeksowane przy starcie rozmowy tego węzła. Zaznaczenie wszystkich klonuje każde z nich (domyślnie).';

  @override
  String get nodeConfigRepoBranchHint => 'Gałąź (domyślna)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'Gałąź, z której wycinany jest każdy checkout. Pozostaw puste, aby użyć domyślnej gałęzi repozytorium — drzewo robocze i tak dostaje własną gałąź, więc commity agenta nie trafiają na tę.';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'Zachowane wpisy dynamiczne: $entries';
  }

  @override
  String get nodeConfigCreateConversation => 'Otwórz w nim rozmowę';

  @override
  String get nodeConfigCreateConversationHelp =>
      'Zostaw wyłączone, gdy dalej idzie kilka węzłów agenta — każdy otwiera własny nazwany strumień. Włącz, gdy dalej jest jeden węzeł agenta, żeby w pokoju nie pojawiła się nienazwana rozmowa obok.';

  @override
  String get nodeConfigConversationTitle => 'Nazwa rozmowy';

  @override
  String get nodeConfigConversationTitleHelp =>
      'Nadaj węzłowi agenta dalej w potoku tę samą nazwę, a oba będą pracować w jednym strumieniu. Domyślnie etykieta węzła.';

  @override
  String get nodeConfigSpaceName => 'Nazwa przestrzeni';

  @override
  String get nodeConfigSpaceNameHelp =>
      'Nazwa pokoju, który otwiera ten węzeł. Obsługuje te same placeholdery stanu co prompt. Zostaw puste, aby użyć etykiety węzła.';

  @override
  String get nodeConfigSpaceNameHint => 'Przegląd pr_number';

  @override
  String get nodeConfigStreamTitle => 'Nazwa rozmowy';

  @override
  String get nodeConfigStreamTitleHelp =>
      'Nazwany strumień, w którym w pokoju pracuje agent tego węzła. Obsługuje te same placeholdery stanu co prompt. Zostaw puste, a tura trafi do stałej rozmowy pokoju, gdzie fan-out przeplata wszystkich agentów.';

  @override
  String get nodeConfigConversationTitleHint => 'Analiza architektury';

  @override
  String get nodeConfigOutputKey => 'Klucz wyjściowy';

  @override
  String get nodeConfigPrompt => 'Szablon promptu';

  @override
  String get nodeConfigPromptHelp =>
      'Użyj placeholderów w podwójnych nawiasach klamrowych, aby w czasie wykonania pobrać wartości ze stanu.';

  @override
  String get nodeConfigScript => 'Skrypt bash';

  @override
  String get nodeConfigScriptHelp =>
      'Uruchamiany przez bash -c. GITHUB_TOKEN jest ustawiony. Placeholdery są podstawiane przed wykonaniem.';

  @override
  String get nodeConfigRouteKeys => 'Klucze routingu';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Klucz routingu z $source';
  }

  @override
  String get conditionSectionTitle => 'Warunek';

  @override
  String get conditionMode => 'Tryb';

  @override
  String get conditionModeFilesAny => 'Plik(i) istnieją — dowolny';

  @override
  String get conditionModeFilesAll => 'Pliki istnieją — wszystkie';

  @override
  String get conditionModeComparison => 'Porównanie';

  @override
  String get conditionModeSwitch => 'Przełącznik';

  @override
  String get conditionFilePaths => 'Ścieżki plików';

  @override
  String get conditionFilePathsAnyHelp =>
      'Jedna ścieżka na wiersz, względem katalogu bazowego. Warunek spełniony, gdy istnieje dowolna.';

  @override
  String get conditionFilePathsAllHelp =>
      'Jedna ścieżka na wiersz, względem katalogu bazowego. Warunek spełniony tylko, gdy istnieją wszystkie.';

  @override
  String get conditionBaseKey => 'Klucz katalogu bazowego';

  @override
  String get conditionBaseKeyHelp =>
      'Klucz stanu z katalogiem, względem którego rozwiązywane są ścieżki (domyślnie repo_local_path).';

  @override
  String get conditionRecursive => 'Przeszukuj podkatalogi';

  @override
  String get conditionNegate => 'Odwróć: kieruj na true, gdy brakuje';

  @override
  String get conditionLeft => 'Lewa wartość';

  @override
  String get conditionOperator => 'Operator';

  @override
  String get conditionRight => 'Prawa wartość';

  @override
  String get conditionSwitchKey => 'Przełącz według klucza stanu';

  @override
  String get conditionCases => 'Przypadki (oddzielone przecinkami)';

  @override
  String get conditionCasesHelp =>
      'Klucze tras do dopasowania do wartości, w kolejności.';

  @override
  String get conditionDefaultCase => 'Przypadek domyślny';

  @override
  String get triggerManualHelp =>
      'Pokaż na stronie uruchomienia i startuj ręcznie.';

  @override
  String get triggerKindSchedule => 'Według harmonogramu';

  @override
  String get triggerScheduleExprLabel => 'Harmonogram (cron lub every:seconds)';

  @override
  String get triggerTimezoneLabel => 'Strefa czasowa (opcjonalnie)';

  @override
  String get triggerCatchUpLabel => 'Przy pominiętych uruchomieniach';

  @override
  String get triggerCatchUpRunOnce => 'Uruchom raz';

  @override
  String get triggerCatchUpSkip => 'Pomiń';

  @override
  String get syncHealthTitle => 'Stan synchronizacji';

  @override
  String get syncHealthNoConfigs => 'Brak połączeń synchronizacji';

  @override
  String get syncHealthNeverSynced => 'Nigdy nie zsynchronizowano';

  @override
  String get syncOutcomeOk => 'Zsynchronizowano';

  @override
  String get syncOutcomeFailed => 'Niepowodzenie';

  @override
  String get syncOutcomeSkipped => 'Pominięto';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count kolejnych niepowodzeń';
  }

  @override
  String get triggerWebhookHelp =>
      'Generowany jest podpisany adres URL webhooka. Systemy zewnętrzne wysyłają do niego POST, aby uruchomić ten potok.';

  @override
  String get triggerWebhookPathLabel => 'Ścieżka webhooka';

  @override
  String get triggerMatchStatusLabel => 'Tylko gdy status to';

  @override
  String get triggerSummaryNone => 'Brak wyzwalaczy';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Co $seconds s';
  }

  @override
  String get triggerEventManual => 'Uruchomienie ręczne';

  @override
  String get triggerEventSchedule => 'Harmonogram';

  @override
  String get triggerEventPrStatusChanged => 'Zmieniono status PR';

  @override
  String get triggerEventExternalPr => 'Otwarto zewnętrzny PR';

  @override
  String get triggerEventPrPublished => 'Opublikowano PR';

  @override
  String get triggerEventPrMerged => 'Scalono PR';

  @override
  String get triggerEventRepoAdded => 'Dodano repozytorium';

  @override
  String get triggerEventCodeGraphWatch => 'Zmiana pliku';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zmienionych plików',
      many: '$count zmienionych plików',
      few: '$count zmienione pliki',
      one: '$count zmieniony plik',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '+$count więcej';
  }

  @override
  String get pipelineRunCauseRescan => 'Zmieniono na dysku';

  @override
  String get pipelineRunCauseInitial => 'Pierwsze indeksowanie tego checkoutu';

  @override
  String get triggerEventMessageReceived => 'Otrzymano wiadomość';

  @override
  String get triggerEventTicketCompleted => 'Zgłoszenie ukończone';

  @override
  String get triggerEventTicketFailed => 'Zgłoszenie nieudane';

  @override
  String get triggerEventTicketCancelled => 'Zgłoszenie anulowane';

  @override
  String get triggerEventBudgetCrossed => 'Przekroczono próg budżetu';

  @override
  String get nodeLibrarySearchHint => 'Szukaj węzłów';

  @override
  String get nodeLibraryNoMatches => 'Brak pasujących węzłów';

  @override
  String get nodeCategoryFlow => 'Przepływ i logika';

  @override
  String get nodeCategoryPr => 'Przegląd PR';

  @override
  String get nodeCategoryAgents => 'Agenci';

  @override
  String get nodeCategoryMessaging => 'Wiadomości';

  @override
  String get nodeCategoryCode => 'Kod';

  @override
  String get triggerDisabledTag => 'wył.';

  @override
  String get pipelineInputTypeRepo => 'Repozytorium';

  @override
  String get pipelineRunNoRepos =>
      'W tym obszarze roboczym nie ma jeszcze repozytoriów.';

  @override
  String get allowTicketingApi => 'Zezwalaj na wywołania API zgłoszeń';

  @override
  String get ticketingApiKey => 'Klucz API zgłoszeń';

  @override
  String get ticketingApiKeySubtitle =>
      'Wstrzykuje klucz API dostawcy zgłoszeń do piaskownicy.';

  @override
  String get ticketingProvider => 'Dostawca zgłoszeń';

  @override
  String get connectGitHubAndTicketing =>
      'Połącz host kodu, aby Control Center mógł odczytywać twoje pull requesty, issues i recenzje. Opcjonalnie połącz dostawcę zgłoszeń. Dane logowania przechowuje serwer, nigdy ta maszyna.';

  @override
  String get triggerEventTicketAssigned => 'Przypisano zgłoszenie';

  @override
  String get triggerEventTicketCreated => 'Utworzono zgłoszenie';

  @override
  String get triggerEventTicketStatusChanged => 'Zmieniono status zgłoszenia';

  @override
  String get triggerEventMeetingRecordingStopped =>
      'Zatrzymano nagranie spotkania';

  @override
  String get triggerEventSkillUpdated => 'Zaktualizowano umiejętność';

  @override
  String get triggerEventSpaceDeleted => 'Przestrzeń usunięta';

  @override
  String get triggerExternalPrHelp =>
      'Pull request otwarty na hoście kodu, nie z Control Center.';

  @override
  String get triggerPrPublishedHelp =>
      'Pull request otwarty z Control Center lub przez agenta.';

  @override
  String get triggerPrStatusChangedHelp =>
      'Scalony, zamknięty, otwarty, ponownie otwarty lub zatwierdzony. Filtruj według statusu w inspektorze.';

  @override
  String get triggerPrMergedHelp =>
      'Tylko gdy pull request zostanie scalony, nie zamknięty ani ponownie otwarty.';

  @override
  String get triggerRepoAddedHelp =>
      'Repozytorium jest łączone z tą przestrzenią roboczą.';

  @override
  String get triggerCodeGraphWatchHelp =>
      'Plik w połączonym repozytorium zmienia się na dysku.';

  @override
  String get triggerMessageReceivedHelp =>
      'Nowa wiadomość pojawia się w przestrzeni.';

  @override
  String get triggerTicketCreatedHelp =>
      'Zgłoszenie jest tworzone w tej przestrzeni roboczej.';

  @override
  String get triggerTicketStatusChangedHelp => 'Zgłoszenie zmienia status.';

  @override
  String get triggerTicketCompletedHelp => 'Zgłoszenie kończy się pomyślnie.';

  @override
  String get triggerTicketFailedHelp =>
      'Uruchomienie agenta nie powiodło się, a zgłoszenie jest oznaczone jako nieudane.';

  @override
  String get triggerTicketCancelledHelp =>
      'Zgłoszenie jest anulowane i nie będzie kontynuowane.';

  @override
  String get triggerBudgetCrossedHelp =>
      'Przekroczono limit wydatków przestrzeni roboczej lub agenta.';

  @override
  String get triggerTicketAssignedHelp =>
      'Zgłoszenie jest przypisywane do osoby, agenta lub zespołu.';

  @override
  String get triggerMeetingRecordingStoppedHelp =>
      'Nagranie spotkania się kończy.';

  @override
  String get triggerSkillUpdatedHelp =>
      'Umiejętność jest instalowana lub aktualizowana.';

  @override
  String get triggerSpaceDeletedHelp => 'Przestrzeń rozmowy jest usuwana.';

  @override
  String get navTickets => 'Zgłoszenia';

  @override
  String get ticketsTitle => 'Zgłoszenia';

  @override
  String get newTicket => 'Nowe zgłoszenie';

  @override
  String get noTicketsYet => 'Brak zgłoszeń';

  @override
  String get addCollaborator => 'Dodaj współpracownika';

  @override
  String get noCollaborators => 'Brak współpracowników';

  @override
  String get linkedPullRequests => 'Powiązane pull requesty';

  @override
  String get noLinkedPullRequests => 'Brak powiązanych pull requestów';

  @override
  String get stopAgent => 'Zatrzymaj agenta';

  @override
  String get ticketProperties => 'Właściwości';

  @override
  String get ticketTabIssue => 'Zgłoszenie';

  @override
  String get ticketSelectPrompt => 'Wybierz zgłoszenie, aby zobaczyć szczegóły';

  @override
  String get unassigned => 'Nieprzypisane';

  @override
  String get ticketStatusBacklog => 'Backlog';

  @override
  String get ticketStatusOpen => 'Do zrobienia';

  @override
  String get ticketStatusInProgress => 'W toku';

  @override
  String get ticketStatusInReview => 'W recenzji';

  @override
  String get ticketStatusDone => 'Gotowe';

  @override
  String get ticketStatusBlocked => 'Zablokowane';

  @override
  String get ticketStatusFailed => 'Nieudane';

  @override
  String get ticketStatusCancelled => 'Anulowane';

  @override
  String get notificationTicketAssigned => 'Przypisano zgłoszenie';

  @override
  String get notificationTicketStatusChanged => 'Zmieniono status zgłoszenia';

  @override
  String get priority => 'Priorytet';

  @override
  String get status => 'Status';

  @override
  String get assignee => 'Osoba przypisana';

  @override
  String get labels => 'Etykiety';

  @override
  String get noLabelsYet => 'Brak etykiet';

  @override
  String get clearLabels => 'Wyczyść etykiety';

  @override
  String get pipelineStepAgentActivity => 'Aktywność agenta';

  @override
  String get runStatusCompleted => 'Ukończono';

  @override
  String get runStatusQueued => 'W kolejce';

  @override
  String get ticketDescription => 'Opis';

  @override
  String get ticketPriorityNone => 'Brak';

  @override
  String get ticketPriorityUrgent => 'Pilny';

  @override
  String get ticketPriorityHigh => 'Wysoki';

  @override
  String get ticketPriorityMedium => 'Średni';

  @override
  String get ticketPriorityLow => 'Niski';

  @override
  String get ticketViewList => 'Lista';

  @override
  String get ticketViewBoard => 'Tablica';

  @override
  String get ticketTitlePlaceholder => 'Tytuł zgłoszenia';

  @override
  String get ticketDescriptionPlaceholder => 'Dodaj opis…';

  @override
  String get createMore => 'Utwórz kolejne';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get clearSelection => 'Wyczyść zaznaczenie';

  @override
  String get bulkDeleteTitle => 'Usuń zgłoszenia';

  @override
  String bulkDeleteMessage(int count) {
    return 'Delete $count selected tickets? This can\'t be undone.';
  }

  @override
  String get assignTo => 'Przypisz do…';

  @override
  String get sectionMembers => 'Członkowie';

  @override
  String get sectionAgents => 'Agenci';

  @override
  String get sidebarGroupWorkspace => 'Obszar roboczy';

  @override
  String get notificationsTitle => 'Powiadomienia';

  @override
  String get notificationsTooltip => 'Powiadomienia';

  @override
  String get notificationsEmpty => 'Jesteś na bieżąco';

  @override
  String notificationsUnreadCount(int count) {
    return '$count nieprzeczytanych';
  }

  @override
  String get notificationsMarkRead => 'Oznacz jako przeczytane';

  @override
  String get notificationsMarkUnread => 'Oznacz jako nieprzeczytane';

  @override
  String get notificationsEntryActions => 'Akcje powiadomienia';

  @override
  String get markAllRead => 'Oznacz wszystkie jako przeczytane';

  @override
  String get teamsNav => 'Zespoły';

  @override
  String get noWorkspace => 'Brak obszaru roboczego';

  @override
  String get selectWorkspace => 'Wybierz obszar roboczy';

  @override
  String get navMemory => 'Pamięć';

  @override
  String get memoryTabFacts => 'Fakty';

  @override
  String get memoryTabPolicies => 'Zasady';

  @override
  String get memoryGraphShowFacts => 'Pokaż fakty';

  @override
  String get memoryGraphHideFacts => 'Ukryj fakty';

  @override
  String get memoryGraphExpandAll => 'Rozwiń wszystkie fakty';

  @override
  String get memoryGraphCollapseAll => 'Zwiń wszystkie fakty';

  @override
  String get memoryTabGraph => 'Graf wiedzy';

  @override
  String get memoryNoWorkspace =>
      'Wybierz obszar roboczy, aby zobaczyć jego pamięć.';

  @override
  String get searchArticles => 'Szukaj artykułów';

  @override
  String get filterAll => 'Wszystkie';

  @override
  String get filterUnread => 'Nieprzeczytane';

  @override
  String get filterSaved => 'Zapisane';

  @override
  String get saveArticle => 'Zapisz artykuł';

  @override
  String get removeFromSaved => 'Usuń z zapisanych';

  @override
  String get filterBySource => 'Filtruj według źródła';

  @override
  String get viewAsList => 'Widok listy';

  @override
  String get viewAsGrid => 'Widok siatki';

  @override
  String get noMatchingArticles => 'Brak pasujących artykułów';

  @override
  String get noMatchingArticlesBody =>
      'Spróbuj innego wyszukiwania lub filtra źródła.';

  @override
  String get allCaughtUp => 'Wszystko na bieżąco';

  @override
  String get allCaughtUpBody =>
      'Brak nieprzeczytanych artykułów — sprawdź później.';

  @override
  String get openArticlesInAppDescription =>
      'Otwieraj linki we wbudowanym czytniku zamiast w domyślnej przeglądarce.';

  @override
  String get blockAdsTrackersDescription =>
      'Usuwaj reklamy, trackery i banery cookies z artykułów otwieranych w czytniku.';

  @override
  String get agentQuestionHeader => 'Pytanie do ciebie';

  @override
  String get agentQuestionAnsweredLabel => 'Odpowiedziano';

  @override
  String get agentQuestionFreeformHint => 'Wpisz odpowiedź…';

  @override
  String agentQuestionProgress(int index, int count) {
    return 'Pytanie $index z $count';
  }

  @override
  String get agentQuestionSkip => 'Pomiń';

  @override
  String get agentQuestionSkippedLabel => 'Pominięto';

  @override
  String get agentQuestionFreeformOptionHint => 'Opisz własnymi słowami…';

  @override
  String get reviewRequested => 'Poproszono o recenzję';

  @override
  String get connectGitHubHint =>
      'Zaloguj się do GitHub lub dodaj token w Ustawienia → Ty → Profil i tożsamość → Hosting kodu';

  @override
  String get connectGitHubToLoadPrs =>
      'Połącz GitHub, aby wczytać pull requesty';

  @override
  String get noRepositoriesConfigured => 'Nie skonfigurowano repozytoriów';

  @override
  String openedAgo(String age) {
    return 'Otwarto $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author otworzył to pull request';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commitami',
      many: '$count commitami',
      few: '$count commitami',
      one: '$count commitem',
    );
    return '$author otworzył to pull request z $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor poprosił $reviewers o recenzję';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor usunął prośbę o recenzję dla $reviewers';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor poprosił $requested o recenzję i usunął prośbę o recenzję dla $removed';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'etykiety',
      one: 'etykietę',
    );
    return '$actor dodał $_temp0 $labels';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'etykiety',
      one: 'etykietę',
    );
    return '$actor usunął $_temp0 $labels';
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
      other: 'etykiety',
      one: 'etykietę',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: 'etykiety',
      one: 'etykietę',
    );
    return '$actor dodał $_temp0 $added i usunął $_temp1 $removed';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author utworzył commit';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commitów',
      many: '$count commitów',
      few: '$count commity',
      one: '$count commit',
    );
    return '$author wypchnął $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author zatwierdził te zmiany';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author poprosił o zmiany';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count komentarzy do kodu',
      many: '$count komentarzy do kodu',
      few: '$count komentarze do kodu',
      one: '$count komentarz do kodu',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author zrecenzował';
  }

  @override
  String get prTimelineSomeone => 'Ktoś';

  @override
  String get prTimelineBotBadge => 'bot';

  @override
  String updatedAgo(String age) {
    return 'Zaktualizowano $age';
  }

  @override
  String get checksPassing => 'Kontrole przechodzą';

  @override
  String get checksRunning => 'Kontrole w toku';

  @override
  String get needsYourReview => 'Wymaga Twojej recenzji';

  @override
  String get checks => 'Kontrole';

  @override
  String get noReviewersAssigned => 'Nie przypisano recenzentów';

  @override
  String get noAssignees => 'Brak przypisanych';

  @override
  String get loadingEllipsis => 'Ładowanie…';

  @override
  String get loadingChecks => 'Ładowanie kontroli…';

  @override
  String get noChecksYet => 'Nie uruchomiono jeszcze kontroli';

  @override
  String get noChangesToReview => 'Brak zmian do przejrzenia';

  @override
  String checksFailingCount(int count) {
    return '$count nieudanych';
  }

  @override
  String get showMore => 'Pokaż więcej';

  @override
  String get showLess => 'Pokaż mniej';

  @override
  String get backToPullRequests => 'Wróć do pull requestów';

  @override
  String get pullRequestNotFound => 'Nie znaleziono pull requestu';

  @override
  String get pullRequestNotFoundBody =>
      'Mógł zostać scalony, zamknięty lub przeniesiony.';

  @override
  String get couldntLoadPullRequest =>
      'Nie udało się wczytać tego pull requestu';

  @override
  String get showDetails => 'Pokaż szczegóły';

  @override
  String get noDescriptionProvided => 'Nie podano opisu.';

  @override
  String get factsHint => 'Fakty pojawią się tutaj, gdy agenci będą się uczyć.';

  @override
  String get noFactsMatch => 'Brak faktów pasujących do wyszukiwania';

  @override
  String get memoryLoadError => 'Nie udało się wczytać pamięci';

  @override
  String get sortRecent => 'Najnowsze';

  @override
  String get sortConfidence => 'Pewność';

  @override
  String get confidenceTooltip =>
      'Jak bardzo agenci są pewni, że ten fakt jest prawdziwy, od 0 do 100%.';

  @override
  String get supersededTooltip => 'Nowszy fakt zastąpił ten.';

  @override
  String get domain => 'Domena';

  @override
  String get fitToView => 'Dopasuj do widoku';

  @override
  String get project => 'Projekt';

  @override
  String get newProject => 'Nowy projekt';

  @override
  String get editProject => 'Edytuj projekt';

  @override
  String get deleteProject => 'Usuń projekt';

  @override
  String get noProject => 'Brak projektu';

  @override
  String get allTickets => 'Wszystkie zgłoszenia';

  @override
  String get projectNamePlaceholder => 'Nazwa projektu';

  @override
  String get projectDescriptionPlaceholder => 'Opis (opcjonalnie)';

  @override
  String get projectColorLabel => 'Kolor';

  @override
  String get noProjectsYet => 'Nie ma jeszcze projektów';

  @override
  String get projectTicketsEmpty => 'W tym projekcie nie ma jeszcze zgłoszeń';

  @override
  String get createProject => 'Utwórz projekt';

  @override
  String projectProgress(int done, int total) {
    return '$done z $total ukończonych';
  }

  @override
  String deleteProjectConfirm(String name) {
    return 'Usunąć „$name”? Zgłoszenia zostaną zachowane i usunięte z projektu.';
  }

  @override
  String get projectStatusActive => 'Aktywny';

  @override
  String get projectStatusCompleted => 'Ukończony';

  @override
  String get projectStatusArchived => 'Zarchiwizowany';

  @override
  String get markProjectCompleted => 'Oznacz jako ukończony';

  @override
  String get markProjectActive => 'Oznacz jako aktywny';

  @override
  String get archiveProject => 'Archiwizuj';

  @override
  String get restoreProject => 'Przywróć';

  @override
  String get relations => 'Powiązania';

  @override
  String get relateTo => 'Powiąż z';

  @override
  String get relationSubIssueOf => 'Podzgłoszenie…';

  @override
  String get relationParentOf => 'Nadrzędne wobec…';

  @override
  String get relationBlockedBy => 'Blokowane przez…';

  @override
  String get relationBlocking => 'Blokuje…';

  @override
  String get relationRelatedTo => 'Powiązane z…';

  @override
  String get relationDuplicateOf => 'Duplikat…';

  @override
  String get relationGroupParent => 'Nadrzędne';

  @override
  String get relationGroupSubIssues => 'Podzgłoszenia';

  @override
  String get relationGroupBlockedBy => 'Blokowane przez';

  @override
  String get relationGroupBlocking => 'Blokujące';

  @override
  String get relationGroupRelated => 'Powiązane';

  @override
  String get relationGroupDuplicateOf => 'Duplikat';

  @override
  String get relationGroupDuplicatedBy => 'Zduplikowane przez';

  @override
  String get copyId => 'Kopiuj ID';

  @override
  String get ticketIdCopied => 'Skopiowano ID zgłoszenia';

  @override
  String get searchTicketsHint => 'Szukaj zgłoszeń…';

  @override
  String get noMatchingTickets => 'Brak pasujących zgłoszeń';

  @override
  String get clearAll => 'Wyczyść wszystko';

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PR oczekuje na Twoją recenzję',
      many: '$prs PR-ów oczekuje na Twoją recenzję',
      few: '$prs PR-y oczekują na Twoją recenzję',
      one: '1 PR oczekuje na Twoją recenzję',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos repozytorium',
      many: '$repos repozytoriach',
      few: '$repos repozytoriach',
      one: '1 repozytorium',
    );
    return '$_temp0 w $_temp1';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'Zmień nazwę obszaru roboczego i jego oznaczenie — wybierz jeden z lewej, aby go edytować.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count obszaru roboczego',
      many: '$count obszarów roboczych',
      few: '$count obszary robocze',
      one: '1 obszar roboczy',
      zero: 'Brak obszarów roboczych',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos repozytorium',
      many: '$repos repozytoriów',
      few: '$repos repozytoria',
      one: '1 repozytorium',
      zero: 'Brak repozytoriów',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents agenta',
      many: '$agents agentów',
      few: '$agents agenty',
      one: '1 agent',
      zero: '0 agentów',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'Tożsamość';

  @override
  String get uploadImage => 'Prześlij obraz';

  @override
  String get failedToSaveLogo =>
      'Nie udało się zapisać obrazu logo. Upewnij się, że aplikacja może odczytać wybrany plik.';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG lub GIF do 2 MB. W przeciwnym razie użyjemy inicjału obszaru roboczego.';

  @override
  String get workspaceNameFieldHelp =>
      'Wyświetlana w przełączniku, ścieżce nawigacji i na każdym ekranie.';

  @override
  String get dangerZone => 'Strefa niebezpieczeństwa';

  @override
  String get deleteThisWorkspace => 'Usuń ten obszar roboczy';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Trwale usuwa $name, połączenia z repozytoriami, agentów i pamięć. Tej operacji nie można cofnąć.';
  }

  @override
  String get discard => 'Odrzuć';

  @override
  String discardChangesQuestion(String name) {
    return 'Odrzucić niezapisane zmiany w $name?';
  }

  @override
  String get workspaceUpdated => 'Zaktualizowano obszar roboczy';

  @override
  String get editTitle => 'Edytuj tytuł';

  @override
  String get editDescription => 'Edytuj opis';

  @override
  String get addDescription => 'Dodaj opis';

  @override
  String get prTitlePlaceholder => 'Tytuł';

  @override
  String get prBodyPlaceholder => 'Zostaw opis';

  @override
  String get write => 'Napisz';

  @override
  String get overview => 'Przegląd';

  @override
  String get noFilesChanged => 'Brak zmienionych plików';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Podgląd';

  @override
  String get outdated => 'Nieaktualne';

  @override
  String get outdatedComments => 'Nieaktualne komentarze';

  @override
  String outdatedCountLabel(int count) {
    return '$count nieaktualne';
  }

  @override
  String get prTemplateLabel => 'Szablon';

  @override
  String get prTemplateDefault => 'Domyślny';

  @override
  String get addReviewers => 'Dodaj recenzentów';

  @override
  String get addAssignees => 'Dodaj osoby przypisane';

  @override
  String get searchUsers => 'Szukaj osób…';

  @override
  String get searchReviewers => 'Szukaj osób i zespołów…';

  @override
  String get usersSectionLabel => 'Osoby';

  @override
  String get userStatusBusy => 'Zajęty';

  @override
  String get teamsSectionLabel => 'Zespoły';

  @override
  String get suggestedReviewers => 'Sugerowani recenzenci';

  @override
  String get noMatchingUsers => 'Brak pasujących osób';

  @override
  String get noMatchingReviewers => 'Brak wyników';

  @override
  String get requiredByCodeOwners => 'Wymagane przez właścicieli kodu';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'przez $login';
  }

  @override
  String get team => 'Zespół';

  @override
  String get markdownBold => 'Pogrubienie';

  @override
  String get markdownItalic => 'Kursywa';

  @override
  String get markdownHeading => 'Nagłówek';

  @override
  String get markdownBulletList => 'Lista punktowana';

  @override
  String get markdownChecklist => 'Lista zadań';

  @override
  String get markdownCode => 'Kod';

  @override
  String get markdownLink => 'Link';

  @override
  String get markdownQuote => 'Cytat';

  @override
  String get markdownSupported => 'Markdown jest obsługiwany';

  @override
  String get markdownAttachImages => 'Kliknij, aby dodać obrazy';

  @override
  String failedToUpdateTitle(String error) {
    return 'Nie udało się zaktualizować tytułu: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Nie udało się zaktualizować opisu: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Nie udało się zaktualizować recenzentów: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Nie udało się zaktualizować osób przypisanych: $error';
  }

  @override
  String get discardChangesConfirm => 'Odrzucić zmiany?';

  @override
  String get newPr => 'Nowy PR';

  @override
  String get openPullRequest => 'Otwórz pull request';

  @override
  String get composePrSubtitle =>
      'Z wypchniętej gałęzi — bez agentów i zgłoszeń';

  @override
  String get createAsDraft => 'Utwórz jako szkic';

  @override
  String get composePrNoRepo => 'Nie wybrano repozytorium GitHub';

  @override
  String get composePrNoRepoHint =>
      'Wybierz obszar roboczy z repozytorium powiązanym z GitHub, aby otworzyć pull request.';

  @override
  String get composePrPickBranches =>
      'Wybierz gałąź bazową i porównywaną, aby zobaczyć podgląd zmian.';

  @override
  String get composePrNothingToCompare => 'Brak zmian między tymi gałęziami.';

  @override
  String get repository => 'Repozytorium';

  @override
  String get baseBranchLabel => 'Baza';

  @override
  String get compareBranchLabel => 'Porównaj';

  @override
  String get selectBranch => 'Wybierz gałąź';

  @override
  String get navMeetings => 'Spotkania';

  @override
  String get meetingsNoWorkspace =>
      'Wybierz obszar roboczy, aby zobaczyć spotkania.';

  @override
  String get meetingsEmpty => 'Brak spotkań';

  @override
  String get meetingsEmptyHint =>
      'Nagraj pierwsze spotkanie — dźwięk zostaje na tym urządzeniu, a agent zamienia je w notatki, decyzje i zadania.';

  @override
  String get meetingNotesHint =>
      'Zapisz szybkie notatki — agent rozwinie je po spotkaniu.';

  @override
  String get meetingSpeakerMe => 'Ty';

  @override
  String get meetingStatusRecording => 'Nagrywanie';

  @override
  String get meetingStatusProcessing => 'Przetwarzanie';

  @override
  String get meetingStatusDone => 'Gotowe';

  @override
  String get meetingStatusFailed => 'Niepowodzenie';

  @override
  String get meetingsSubtitle =>
      'Nagrywane i transkrybowane na tym urządzeniu, potem podsumowywane przez agenta.';

  @override
  String get meetingsRecordMeeting => 'Nagraj spotkanie';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count w trakcie',
      many: '$count w trakcie',
      few: '$count w trakcie',
      one: '1 w trakcie',
    );
    return '$_temp0';
  }

  @override
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spotkań',
      many: '$count spotkań',
      few: '$count spotkania',
      one: '1 spotkanie',
      zero: 'Brak spotkań',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'Otwarte zadania';

  @override
  String get meetingsLedgerDecisions => 'Decyzje';

  @override
  String get meetingsLiveOpen => 'Otwórz nagranie';

  @override
  String get meetingTemplateShort => 'Szablon';

  @override
  String get meetingsStatThisWeek => 'W tym tygodniu';

  @override
  String get meetingsStatRecorded => 'Nagrane';

  @override
  String get meetingsFilterAll => 'Wszystkie';

  @override
  String get meetingsFilterDone => 'Gotowe';

  @override
  String get meetingsFilterProcessing => 'Przetwarzanie';

  @override
  String get meetingsSearchHint => 'Filtruj po tytule, osobie, aplikacji…';

  @override
  String get meetingsBucketToday => 'Dzisiaj';

  @override
  String get meetingsBucketYesterday => 'Wczoraj';

  @override
  String get meetingsBucketEarlierThisWeek => 'Wcześniej w tym tygodniu';

  @override
  String get meetingsBucketLastWeek => 'W zeszłym tygodniu';

  @override
  String get meetingsBucketOlder => 'Starsze';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count decyzji',
      many: '$count decyzji',
      few: '$count decyzje',
      one: '1 decyzja',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total zadań';
  }

  @override
  String get meetingsEnhancedPill => 'ulepszone';

  @override
  String get meetingsTranscribing => 'transkrypcja i podsumowanie…';

  @override
  String get meetingsOpenAction => 'Otwórz';

  @override
  String get meetingsStopProcessing => 'Zatrzymaj';

  @override
  String get meetingsStillTranscribing =>
      'Nadal trwa transkrypcja — podsumowanie pojawi się po jej zakończeniu.';

  @override
  String get meetingsNoMatch => 'Brak pasujących spotkań';

  @override
  String get meetingsNoMatchHint => 'Spróbuj innego filtra lub frazy.';

  @override
  String get meetingBackAllMeetings => 'Wszystkie spotkania';

  @override
  String get meetingReRunSummary => 'Ponów podsumowanie';

  @override
  String get meetingExport => 'Eksportuj';

  @override
  String get meetingAugmentingBanner =>
      'Uzupełniam notatki na podstawie transkryptu — wyodrębniam decyzje i zadania…';

  @override
  String get meetingTabNotes => 'Notatki';

  @override
  String get meetingTabTranscript => 'Transkrypt';

  @override
  String get meetingTabActionItems => 'Zadania';

  @override
  String get meetingTabDecisions => 'Decyzje';

  @override
  String get meetingNotesEnhancedToggle => 'Rozszerzone';

  @override
  String get meetingNotesYoursToggle => 'Twoje notatki';

  @override
  String get meetingEnhancedByAgent =>
      'Rozszerzone przez agenta · z transkryptu';

  @override
  String get meetingEnhancedPending =>
      'Agent nadal pracuje nad tym podsumowaniem.';

  @override
  String get meetingNotesEmpty => 'Nie ma jeszcze rozszerzonych notatek.';

  @override
  String get meetingNotesSavedLocally => 'Zapisano lokalnie';

  @override
  String get meetingNotesSaving => 'Zapisywanie…';

  @override
  String get meetingViewFullTranscript => 'Pokaż pełny transkrypt';

  @override
  String get meetingTranscriptSearchHint => 'Szukaj w transkrypcie…';

  @override
  String get meetingSpeakerEveryone => 'Wszyscy';

  @override
  String get meetingSpeakerOthers => 'Inni';

  @override
  String get meetingTranscriptEmpty => 'Nie ma jeszcze transkryptu.';

  @override
  String get meetingActionItemsEmpty => 'Nie wyodrębniono zadań.';

  @override
  String get meetingActionItemFrom => 'z tego spotkania';

  @override
  String get meetingCreateTicket => 'Utwórz zgłoszenie';

  @override
  String meetingTicketCreated(String key) {
    return 'Utworzono zgłoszenie $key i wysłano je.';
  }

  @override
  String get meetingTicketFailed => 'Nie udało się utworzyć zgłoszenia.';

  @override
  String get meetingDecisionsEmpty => 'Nie zapisano decyzji.';

  @override
  String get meetingEditTitle => 'Edytuj tytuł';

  @override
  String get meetingTitleLabel => 'Tytuł';

  @override
  String get meetingAddActionItem => 'Dodaj zadanie';

  @override
  String get meetingEditActionItem => 'Edytuj zadanie';

  @override
  String get meetingDeleteActionItem => 'Usuń zadanie';

  @override
  String get meetingActionItemContentLabel => 'Zadanie';

  @override
  String get meetingActionItemContentHint => 'Co trzeba zrobić?';

  @override
  String get meetingActionItemOwnerLabel => 'Osoba odpowiedzialna';

  @override
  String get meetingActionItemOwnerHint =>
      'Kto jest odpowiedzialny? (opcjonalnie)';

  @override
  String get meetingAddDecision => 'Dodaj decyzję';

  @override
  String get meetingEditDecision => 'Edytuj decyzję';

  @override
  String get meetingDeleteDecision => 'Usuń decyzję';

  @override
  String get meetingDecisionContentLabel => 'Decyzja';

  @override
  String get meetingDecisionContentHint => 'Co ustalono?';

  @override
  String get meetingReRunStarted => 'Ponownie podsumowuję transkrypt…';

  @override
  String get meetingReRunNoTranscript =>
      'Nie ma jeszcze transkryptu do podsumowania.';

  @override
  String get meetingExportCopied =>
      'Skopiowano notatki do schowka jako Markdown.';

  @override
  String get meetingExportSaved => 'Wyeksportowano spotkanie.';

  @override
  String meetingExportFailed(String error) {
    return 'Eksport nie powiódł się: $error';
  }

  @override
  String get meetingExportNothing => 'Nie ma jeszcze nic do wyeksportowania.';

  @override
  String get meetingPlaybackPlay => 'Odtwórz';

  @override
  String get meetingPlaybackPause => 'Wstrzymaj';

  @override
  String get meetingPlaybackUnavailable =>
      'Odtwarzanie dźwięku jest niedostępne na tym urządzeniu.';

  @override
  String get meetingDetectedTitle => 'Wykryto spotkanie';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'Wygląda na to, że trwa „$label”. Nagrać?';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'Wygląda na to, że trwa spotkanie. Nagrać?';

  @override
  String get meetingDetectedRecord => 'Nagraj';

  @override
  String get meetingDetectedDismiss => 'Odrzuć';

  @override
  String get meetingAutoStopTitle =>
      'To spotkanie wygląda na zakończone. Zatrzymać nagrywanie?';

  @override
  String get meetingAutoStopStop => 'Zatrzymaj';

  @override
  String get meetingAutoStopKeep => 'Kontynuuj nagrywanie';

  @override
  String get meetingAutoDetect => 'Automatycznie wykrywaj spotkania';

  @override
  String get meetingAutoDetectDescription =>
      'Obserwuj kalendarz i aplikacje do wideokonferencji i zaproponuj nagranie, gdy spotkanie się zacznie.';

  @override
  String get meetingsRecordingCrumb => 'Nagrywanie…';

  @override
  String get meetingRecordTitleHint => 'Tytuł spotkania';

  @override
  String get meetingRecordTappingLabel => 'Przechwytywanie:';

  @override
  String get meetingRecordMic => 'Mikrofon';

  @override
  String get meetingRecordSystemAudio => 'Dźwięk systemowy';

  @override
  String get meetingRecordPause => 'Wstrzymaj';

  @override
  String get meetingRecordResume => 'Wznów';

  @override
  String get meetingRecordStop => 'Zatrzymaj i podsumuj';

  @override
  String get meetingRecordYourNotes => 'Twoje notatki';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Pisz w trakcie słuchania. Wystarczy kilka fragmentów — po zatrzymaniu agent rozwinie je na podstawie transkrypcji.';

  @override
  String get meetingRecordLiveTranscript => 'Transkrypcja na żywo';

  @override
  String get meetingRecordDecoding => 'dekodowanie na urządzeniu';

  @override
  String get meetingRecordListening =>
      'Nasłuchiwanie… mowa pojawi się tu w ciągu sekundy lub dwóch, oznaczona jako Ty / Inni.';

  @override
  String get meetingRecordPausedHint =>
      'Wstrzymano — dźwięk jest ignorowany do wznowienia.';

  @override
  String get meetingRecordNotActive => 'Brak aktywnego nagrania.';

  @override
  String get meetingHudRecording => 'nagrywanie';

  @override
  String get meetingHudPaused => 'wstrzymane';

  @override
  String get meetingHudOpen => 'Otwórz';

  @override
  String get meetingHudStop => 'Zatrzymaj';

  @override
  String get meetingToolbarPopOut => 'Odepnij';

  @override
  String get meetingToolbarHoldToStop =>
      'Przytrzymaj, aby zatrzymać nagrywanie';

  @override
  String get meetingToolbarSemanticLabel =>
      'Pasek narzędzi nagrywania spotkania';

  @override
  String get orchestrate => 'Orkiestruj';

  @override
  String get orchestrationUnavailable => 'Orkiestracja niedostępna';

  @override
  String get orchestrationApprove => 'Zatwierdź plan';

  @override
  String get orchestrationReject => 'Odrzuć';

  @override
  String get orchestrationCancel => 'Anuluj orkiestrację';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count ról — $hires nowych zatrudnień';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count zgłoszeń podrzędnych';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Szacowany koszt: \$$amount';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total zgłoszeń podrzędnych ukończonych';
  }

  @override
  String get orchestrationStatusProposed => 'Zaproponowano';

  @override
  String get orchestrationStatusApproved => 'Zatwierdzono';

  @override
  String get orchestrationStatusExecuting => 'Wykonywanie';

  @override
  String get orchestrationStatusSynthesizing => 'Syntezowanie';

  @override
  String get orchestrationStatusCompleted => 'Ukończono';

  @override
  String get orchestrationStatusFailed => 'Niepowodzenie';

  @override
  String get orchestrationStatusCancelled => 'Anulowano';

  @override
  String get messageFailed => 'Uruchomienie nie powiodło się';

  @override
  String get turnLimitReached =>
      'Zatrzymano na limicie tur — odpowiedz, aby kontynuować';

  @override
  String get retried => 'Ponowiono';

  @override
  String replyingTo(String name) {
    return 'odpowiadanie do $name';
  }

  @override
  String get silenceTimeoutLabel => 'Limit ciszy (minuty)';

  @override
  String get silenceTimeoutHint =>
      'np. 15 — zakończ uruchomienie po tak długim braku wyniku';

  @override
  String get capabilityJsonMode => 'Tryb JSON';

  @override
  String get capabilityModelSelection => 'Wybór modelu';

  @override
  String get transcriptThinking => 'Myślenie…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'Myślenie przez $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'Wprowadzanie zmian…';

  @override
  String get transcriptStatusReadingFiles => 'Odczytywanie plików…';

  @override
  String get transcriptStatusSearching => 'Przeszukiwanie kodu…';

  @override
  String get transcriptStatusRunningCommands => 'Wykonywanie poleceń…';

  @override
  String get transcriptStatusResponding => 'Odpowiadanie…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'Uruchamianie $tool…';
  }

  @override
  String get transcriptInput => 'Wejście';

  @override
  String get transcriptOutput => 'Wyjście';

  @override
  String get transcriptErrorLabel => 'Błąd';

  @override
  String get transcriptSandboxBlocked => 'Piaskownica zablokowała działanie';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'Pokaż pełne wyjście (+$kb KB)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'Pokaż wszystkie $count wierszy';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'Pokazano pierwsze $count wierszy';
  }

  @override
  String get transcriptGrepNoMatches => 'Brak dopasowań';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches dopasowań',
      many: '$matches dopasowań',
      few: '$matches dopasowania',
      one: '$matches dopasowanie',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files plików',
      many: '$files plików',
      few: '$files pliki',
      one: '$files plik',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'Osoba $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'Zmień nazwę mówcy';

  @override
  String get meetingRenameSpeakerTitle => 'Zmień nazwę mówcy';

  @override
  String get meetingSpeakerNameLabel => 'Nazwa';

  @override
  String get meetingSpeakerSuggestFromCalendar =>
      'Z zaproszonych na to spotkanie';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'Zastosuj do wszystkich bloków tego mówcy';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'Gdy wyłączone, zmieniana jest tylko zaznaczona linia.';

  @override
  String get meetingLinkEvent => 'Powiąż z wydarzeniem';

  @override
  String get meetingChangeEvent => 'Zmień wydarzenie';

  @override
  String get meetingLinkEventTitle => 'Powiąż z wydarzeniem kalendarza';

  @override
  String get meetingLinkEventSearchHint => 'Szukaj wydarzeń';

  @override
  String get meetingLinkEventEmpty => 'Brak pobliskich wydarzeń kalendarza';

  @override
  String get meetingUnlinkEvent => 'Usuń powiązanie';

  @override
  String get calendarLinkExistingMeeting => 'Powiąż z istniejącym spotkaniem';

  @override
  String get calendarLinkMeetingTitle => 'Powiąż spotkanie';

  @override
  String get calendarLinkMeetingSearchHint => 'Szukaj spotkań';

  @override
  String get calendarLinkMeetingEmpty => 'Brak spotkań do powiązania';

  @override
  String get meetingRenameSpeakerFailed => 'Nie udało się zmienić nazwy mówcy';

  @override
  String get calendarLinkUpdateFailed =>
      'Nie udało się zaktualizować powiązania z kalendarzem';

  @override
  String get rename => 'Zmień nazwę';

  @override
  String get notNow => 'Nie teraz';

  @override
  String get meetingSaveVoiceProfileTitle => 'Zapisać profil głosu?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'Rozpoznawaj $name automatycznie na przyszłych spotkaniach, zapisując odcisk głosu.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'Zapisano profil głosu dla $name';
  }

  @override
  String get meetingVoiceProfileSaveFailed =>
      'Nie udało się zapisać profilu głosu';

  @override
  String get voiceProfilesSection => 'Profile głosu';

  @override
  String get voiceProfilesDescription =>
      'Zapisane głosy są rozpoznawane automatycznie na przyszłych spotkaniach.';

  @override
  String get voiceProfilesEmpty =>
      'Nie zapisano jeszcze żadnych głosów. Nadaj imię mówcy w transkrypcji spotkania, a następnie wybierz „Zapisz profil głosu”.';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count próbek',
      many: '$count próbek',
      few: '$count próbki',
      one: '1 próbka',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'Zmień nazwę profilu głosu';

  @override
  String get deleteVoiceProfileTitle => 'Usunąć profil głosu?';

  @override
  String deleteVoiceProfileBody(String name) {
    return 'Przestać rozpoznawać $name? Zapisany odcisk głosu zostanie usunięty. Nazwy już zastosowane w poprzednich spotkaniach pozostaną.';
  }

  @override
  String get connectedLabel => 'Połączono';

  @override
  String get ideTabGeneral => 'Ogólne';

  @override
  String get ideTabExplorer => 'Eksplorator';

  @override
  String get ideTabSourceControl => 'Kontrola źródła';

  @override
  String get generalSectionTodos => 'Zadania';

  @override
  String get generalSectionGoals => 'Cele';

  @override
  String get goalRunStatusActive => 'Aktywny';

  @override
  String get goalRunStatusPaused => 'Wstrzymany';

  @override
  String get goalRunStatusCompleted => 'Ukończony';

  @override
  String get goalRunStatusFailed => 'Niepowodzenie';

  @override
  String get goalRunStatusCancelled => 'Anulowany';

  @override
  String get goalRunStatusBudgetExhausted => 'Budżet wyczerpany';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'Uruchomienie $run z $max · $cost z $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'Uruchomienie $run · $cost z $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'Termin $deadline';
  }

  @override
  String get goalRunPause => 'Wstrzymaj cel';

  @override
  String get goalRunResume => 'Wznów cel';

  @override
  String goalRunResumeRaise(String cap) {
    return 'Wznów · podnieś limit do $cap';
  }

  @override
  String get goalRunStop => 'Zatrzymaj cel';

  @override
  String get generalSectionAgents => 'Agenci';

  @override
  String get generalSectionTerminals => 'Terminale';

  @override
  String get generalTodosEmpty => 'Brak zadań';

  @override
  String get generalAgentsEmpty => 'Brak działających agentów';

  @override
  String get generalTerminalsEmpty => 'Brak otwartych terminali';

  @override
  String get generalSectionBrowsers => 'Przeglądarki';

  @override
  String get generalSectionComputers => 'Komputery';

  @override
  String get generalBrowsersEmpty => 'Brak otwartych przeglądarek';

  @override
  String get generalComputersEmpty => 'Brak otwartych komputerów';

  @override
  String get generalSectionPhones => 'Telefony';

  @override
  String get generalPhonesEmpty => 'Brak otwartych telefonów';

  @override
  String get pauseAgent => 'Wstrzymaj agenta';

  @override
  String get resumeAgent => 'Wznów agenta';

  @override
  String get agentCannotPause =>
      'Tego agenta nie można wstrzymać — zatrzymaj go.';

  @override
  String get goalClear => 'Wyczyść cel';

  @override
  String get undoLabelGoalClear => 'wyczyść cel';

  @override
  String get todoStatusPending => 'Nie rozpoczęte';

  @override
  String get todoStatusInProgress => 'W toku';

  @override
  String get todoStatusCompleted => 'Gotowe';

  @override
  String get reorderTodo => 'Zmień kolejność todo';

  @override
  String get focusTerminal => 'Przejdź do terminala';

  @override
  String get focusMachine => 'Przejdź do maszyny';

  @override
  String get focusBrowser => 'Przejdź do przeglądarki';

  @override
  String get todoEditorTitle => 'Edytuj todo';

  @override
  String get todoEditorHint =>
      'Jedna pozycja w wierszu. Użyj - [ ] dla nie rozpoczętych, - [~] dla w toku, - [x] dla ukończonych.';

  @override
  String get todoNeedsText => 'Dodaj tekst po poleceniu';

  @override
  String get todoNotFound => 'Brak pasującego todo';

  @override
  String get todoCleared => 'Wyczyszczono listę todo';

  @override
  String get todoNothingToCopy => 'Nie ma nic do skopiowania';

  @override
  String todoAdded(String content) {
    return 'Dodano \"$content\"';
  }

  @override
  String todoStarted(String content) {
    return 'Rozpoczęto \"$content\"';
  }

  @override
  String todoCompleted(String content) {
    return 'Ukończono \"$content\"';
  }

  @override
  String todoRemoved(String content) {
    return 'Usunięto \"$content\"';
  }

  @override
  String todoCopied(int count) {
    return 'Skopiowano $count pozycji';
  }

  @override
  String todoImported(int count) {
    return 'Zaimportowano $count pozycji';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'Nieznane polecenie todo \"$name\"';
  }

  @override
  String get terminal => 'Terminal';

  @override
  String get ideCloseTab => 'Zamknij kartę';

  @override
  String get ideSplitEditor => 'Podziel edytor';

  @override
  String get ideSplitRight => 'Podziel w prawo';

  @override
  String get ideSplitDown => 'Podziel w dół';

  @override
  String get ideSplitLeft => 'Podziel w lewo';

  @override
  String get ideSplitUp => 'Podziel w górę';

  @override
  String get ideCloseGroup => 'Zamknij grupę';

  @override
  String get ideCloseOthers => 'Zamknij pozostałe';

  @override
  String get ideCloseToRight => 'Zamknij po prawej';

  @override
  String get ideCloseSaved => 'Zamknij zapisane';

  @override
  String get ideCloseAll => 'Zamknij wszystkie';

  @override
  String get ideSplit => 'Podziel';

  @override
  String get ideToggleSidebar => 'Przełącz panel boczny';

  @override
  String get ideNewTab => 'Otwórz edytor';

  @override
  String get ideNewTabMenu => 'Nowa karta';

  @override
  String get ideReviewCode => 'Przejrzyj kod';

  @override
  String get ideRevertConfirmTitle => 'Przywróć zmiany';

  @override
  String get ideRevertUntracked => 'Nieśledzonych plików nie można przywrócić';

  @override
  String get ideRevertFailed =>
      'Nie udało się przywrócić plików. Drzewo robocze rozmowy może być niedostępne.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plików nie mogło zostać przywróconych',
      many: '$count plików nie mogło zostać przywróconych',
      few: '$count pliki nie mogły zostać przywrócone',
      one: '1 plik nie mógł zostać przywrócony',
    );
    return '$_temp0 (nieśledzone).';
  }

  @override
  String get ideSearchMatchCase => 'Uwzględnij wielkość liter';

  @override
  String get ideSearchWholeWord => 'Całe słowo';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'Filtry wyszukiwania';

  @override
  String get ideSearchFilesToInclude => 'Pliki do uwzględnienia';

  @override
  String get ideSearchFilesToExclude => 'Pliki do wykluczenia';

  @override
  String get ideNoOpenTabs => 'Brak otwartych kart — użyj + aby otworzyć';

  @override
  String get ideBrowserAddressHint => 'Wpisz adres lub wyszukaj';

  @override
  String get ideSimpleWebBrowser => 'Prosta przeglądarka';

  @override
  String get ideWebBrowser => 'Przeglądarka';

  @override
  String get ideBrowserEnterUrl =>
      'Wpisz adres URL na pasku adresu, aby rozpocząć przeglądanie';

  @override
  String get ideCodeServer => 'Edytor';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'Zapisać zmiany w $fileName?';
  }

  @override
  String get ideUnsavedChangesBody => 'Niezapisane zmiany zostaną utracone.';

  @override
  String get ideDontSave => 'Nie zapisuj';

  @override
  String get editorAutoSave => 'Autozapis';

  @override
  String get editorAutoSaveDescription =>
      'Automatycznie zapisuj zmiany w osadzonym edytorze.';

  @override
  String get editorAutoSaveOff => 'Wyłączony';

  @override
  String get editorAutoSaveAfterDelay => 'Po opóźnieniu';

  @override
  String get editorAutoSaveOnFocusChange => 'Przy zmianie fokusu';

  @override
  String get ideCodeServerUnavailable =>
      'code-server jest niedostępny na tym serwerze';

  @override
  String get ideCodeServerUnavailableHint =>
      'Zainstaluj code-server (coder/code-server) na hoście serwera, a następnie otwórz edytor ponownie.';

  @override
  String get ideCodeServerInstalling => 'Przygotowywanie edytora…';

  @override
  String get ideCodeServerOpenInBrowser => 'Otwórz edytor w przeglądarce';

  @override
  String get ideCodeServerError => 'Nie udało się otworzyć edytora';

  @override
  String get paneSuspendedCaption =>
      'Wstrzymano, aby oszczędzać zasoby — wczyta się ponownie po uaktywnieniu';

  @override
  String get ideFolderLoadFailed => 'Nie udało się wczytać tego folderu';

  @override
  String get ideFileSearchFailed => 'Nie udało się wyszukać plików';

  @override
  String get ideSearchInFiles => 'Szukaj w plikach';

  @override
  String get ideNoContentMatches => 'Brak wyników';

  @override
  String get ideSourceControlCreatePr => 'Utwórz pull request';

  @override
  String ideSourceControlViewPr(int number) {
    return 'Zobacz pull request #$number';
  }

  @override
  String get ideSourceControlNoChanges => 'Brak zmian';

  @override
  String get noReposInConversation => 'Brak repozytoriów w tej rozmowie';

  @override
  String get ideSourceControlNoSpace =>
      'Otwórz rozmowę, aby zobaczyć jej zmiany';

  @override
  String get ideFileLoading => 'Wczytywanie…';

  @override
  String get ideFileBinary => 'Plik binarny';

  @override
  String get mcpExternalServers => 'Zewnętrzne serwery MCP';

  @override
  String get mcpExternalServersDescription =>
      'Połącz się z zewnętrznymi serwerami MCP (GitHub, Sentry, Postgres, automatyzacja przeglądarki). Serwery skonfigurowane w Claude, Cursor, VS Code i innych narzędziach są wykrywane automatycznie.';

  @override
  String get mcpApprovalMode => 'Zatwierdzanie narzędzi';

  @override
  String get mcpApprovalModeDescription =>
      'Które działania narzędzi wykonują się bez pytania. Odczyty są zawsze dozwolone; wyższe poziomy wymagają potwierdzenia.';

  @override
  String get mcpApprovalAlwaysAsk => 'Zawsze pytaj';

  @override
  String get mcpApprovalWrite => 'Automatycznie zatwierdzaj zapisy';

  @override
  String get mcpApprovalYolo => 'Automatycznie zatwierdzaj wszystko';

  @override
  String get mcpNoExternalServers => 'Nie wykryto zewnętrznych serwerów MCP.';

  @override
  String get mcpAuthorize => 'Autoryzuj';

  @override
  String get mcpReconnect => 'Połącz ponownie';

  @override
  String get mcpExternalConnectionsNote =>
      'Zewnętrzne serwery MCP działają na serwerze agenta (wspólnym dla aplikacji desktopowej i webowej). Autoryzacja serwerów OAuth jest dostępna tylko w aplikacji desktopowej.';

  @override
  String get mcpStatusConnected => 'Połączono';

  @override
  String get mcpStatusConnecting => 'Łączenie…';

  @override
  String get mcpStatusNeedsAuth => 'Wymaga autoryzacji';

  @override
  String get mcpStatusFailed => 'Niepowodzenie';

  @override
  String get mcpStatusCircuitOpen => 'Wstrzymano';

  @override
  String get mcpStatusDisabled => 'Wyłączony';

  @override
  String get providersAndModels => 'Dostawcy i modele';

  @override
  String get providersAndModelsDescription =>
      'Lista wszystkich dostawców, z których może korzystać wbudowany agent — ustaw klucz API lub zaloguj się w przeglądarce, zobacz modele i cennik każdego połączonego dostawcy i zdecyduj, których dostawców może używać ten obszar roboczy.';

  @override
  String get syncNow => 'Synchronizuj teraz';

  @override
  String syncNowResult(int applied, int failed) {
    return 'Synchronizacja zakończona — zastosowano: $applied, niepowodzeń: $failed';
  }

  @override
  String syncNowFailed(String error) {
    return 'Synchronizacja nie powiodła się: $error';
  }

  @override
  String get denied => 'Odmówiono';

  @override
  String get allowed => 'Zezwolono';

  @override
  String allowProviderSemantic(String provider) {
    return 'Zezwól na $provider';
  }

  @override
  String enabledViaEnv(String key) {
    return 'Włączono przez $key';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output na 1 mln';
  }

  @override
  String contextTokens(String tokens) {
    return '$tokens kontekstu';
  }

  @override
  String get usageAndCost => 'Użycie i koszt';

  @override
  String get usageAndCostDescription =>
      'Wydatki na agentów z ostatnich 7 dni, na podstawie zaobserwowanych kosztów uruchomień.';

  @override
  String get noUsageYet => 'Brak zarejestrowanego użycia.';

  @override
  String get spentThisWeek => 'wydane w tym tygodniu';

  @override
  String get subscriptionUsage => 'Zużycie subskrypcji';

  @override
  String get subscriptionUsageUnavailable => 'Niedostępne';

  @override
  String get subscriptionUsageExhausted => 'Limit wyczerpany';

  @override
  String get subscriptionUsageSignInRequired => 'Zaloguj się ponownie';

  @override
  String get subscriptionUsageSignInExpired =>
      'Sesja wygasła, odnowi się przy następnym uruchomieniu';

  @override
  String get subscriptionUsagePartiallyAvailable => 'Częściowo dostępne';

  @override
  String resetsIn(String duration) {
    return 'Reset za $duration';
  }

  @override
  String get feedbackHelpful => 'To było pomocne';

  @override
  String get feedbackNotHelpful => 'To nie było pomocne';

  @override
  String get modeChat => 'Czat';

  @override
  String get modePlan => 'Plan';

  @override
  String get modeReview => 'Przegląd';

  @override
  String get modeOrchestrate => 'Orkiestracja';

  @override
  String get editorTheme => 'Motyw edytora';

  @override
  String get editorThemeDescription =>
      'Zaimportuj motyw kolorów VS Code, aby osadzony diff i edytor pasowały do twojego IDE.';

  @override
  String get editorThemePasteHint =>
      'Wklej zawartość pliku JSON motywu kolorów VS Code';

  @override
  String get editorThemeImported => 'Zaimportowano motyw';

  @override
  String get editorThemeInvalid => 'To nie wygląda na prawidłowy motyw VS Code';

  @override
  String get importTheme => 'Importuj motyw';

  @override
  String get clearTheme => 'Wyczyść motyw';

  @override
  String get openInDiffViewer => 'Otwórz w przeglądarce diff';

  @override
  String get shellCommand => 'Polecenie';

  @override
  String get shellOutput => 'Wyjście';

  @override
  String get revertToHere => 'Przywróć do tego miejsca';

  @override
  String get revertConfirmBody =>
      'Ukryć wiadomości po tym punkcie i wycofać zmiany plików agenta do tej tury? Możesz to cofnąć.';

  @override
  String get revert => 'Przywróć';

  @override
  String get revertedToHere => 'Przywrócono do tego miejsca';

  @override
  String get nothingToRevert => 'Nie ma nic do przywrócenia';

  @override
  String get undoRevert => 'Cofnij przywrócenie';

  @override
  String get revertUndone => 'Cofnięto przywrócenie';

  @override
  String get systemBehavior => 'Zachowanie systemu';

  @override
  String get keepAwakeTitle => 'Nie usypiaj komputera, gdy działają agenci';

  @override
  String get keepAwakeOnSubtitle =>
      'Komputer nie przejdzie w sen, gdy pracuje agent';

  @override
  String get keepAwakeOffSubtitle =>
      'Komputer może przejść w sen nawet gdy pracuje agent';

  @override
  String get syncEngineSectionTitle => 'Silnik synchronizacji';

  @override
  String get syncEngineDescription =>
      'Zgłoszenia, wiadomości i notatki aktualizują się na żywo poprzez małe przyrostowe zmiany zamiast pełnych migawek. Wyłączenie przełącznika przywraca ten magazyn do trybu pełnych migawek — przeładuj aplikację, aby zmiana weszła w życie.';

  @override
  String get syncEngineTicketsTitle => 'Zgłoszenia';

  @override
  String get syncEngineMessagingTitle => 'Wiadomości';

  @override
  String get syncEngineNotesTitle => 'Notatki';

  @override
  String get syncEngineOnSubtitle => 'Aktywna synchronizacja delt na żywo';

  @override
  String get syncEngineOffSubtitle => 'Używana synchronizacja pełnych migawek';

  @override
  String get spaces => 'Przestrzenie';

  @override
  String get spacesHomeDescription =>
      'Wybierz przestrzeń z listy albo utwórz nową.';

  @override
  String get noSpacesYet => 'Brak przestrzeni';

  @override
  String get newSpace => 'Nowa przestrzeń';

  @override
  String get spaceName => 'Nazwa przestrzeni';

  @override
  String get spaceReposHint => 'Repozytoria do uwzględnienia';

  @override
  String get ideSourceControl => 'Kontrola źródła';

  @override
  String get stagedChanges => 'Zmiany w poczekalni';

  @override
  String get changes => 'Zmiany';

  @override
  String get stageFile => 'Do poczekalni';

  @override
  String get unstageFile => 'Z poczekalni';

  @override
  String get stageAll => 'Dodaj wszystkie zmiany do poczekalni';

  @override
  String get unstageAll => 'Wycofaj wszystkie z poczekalni';

  @override
  String get stageChangesToCommit => 'Przygotuj zmiany do commita';

  @override
  String get syncToPrHead => 'Pobierz najnowsze commity z PR';

  @override
  String get syncedToPrHead => 'Zsynchronizowano z najnowszymi commitami PR';

  @override
  String get syncPrHeadDirty =>
      'Wykonaj commit lub odrzuć zmiany przed synchronizacją';

  @override
  String get syncPrHeadFailed => 'Nie udało się zsynchronizować z HEAD PR';

  @override
  String get spaceLabel => 'Przestrzeń';

  @override
  String get keybindingNewSpace => 'Nowa przestrzeń';

  @override
  String get keybindingCreateANewSpaceDescription => 'Utwórz nową przestrzeń';

  @override
  String get jumpToLatest => 'Przejdź do najnowszych';

  @override
  String get streaming => 'Strumieniowanie';

  @override
  String get newMessages => 'Nowe';

  @override
  String get copyLink => 'Kopiuj link';

  @override
  String get linkCopied => 'Skopiowano link';

  @override
  String get agentResponding => 'Agent odpowiada';

  @override
  String get agentFinished => 'Agent zakończył';

  @override
  String get harnessConnectProviderForModels =>
      'Połącz dostawcę, aby zobaczyć modele.';

  @override
  String get providerSignOut => 'Wyloguj się';

  @override
  String get providerWaitingForDeviceCode =>
      'Czekam, aż potwierdzisz kod w przeglądarce…';

  @override
  String get providerDeviceCodeHint =>
      'Sprawdź, czy ten kod zgadza się z kodem w przeglądarce, a następnie zatwierdź.';

  @override
  String get providerPlanUsageLoading => 'Sprawdzanie użycia planu…';

  @override
  String get providerPlanUsageUnavailable => 'Ten plan nie zgłosił użycia.';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return 'Usunąć klucz API $provider?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'Zapisany klucz zostanie usunięty i nie będzie można go ponownie wyświetlić. Agenty korzystające z modeli $provider przestaną działać, dopóki nie wkleisz nowego.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return 'Usunąć $provider?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'Dostawca i zapisany klucz zostaną usunięte. Agenty przypięte do jego modeli przestaną działać.';
  }

  @override
  String get providerApiKeyHint => 'Wklej klucz API';

  @override
  String get providerApiKeyStoredHint =>
      'Wklej kolejny klucz API, aby go dodać';

  @override
  String get providerAddAnotherAccount => 'Dodaj kolejne konto';

  @override
  String get providerActiveBadge => 'Aktywny';

  @override
  String get providerOauthAccountFallback => 'Konto OAuth';

  @override
  String get providerApiKeyFallback => 'Klucz API';

  @override
  String get providerRemoveCredentialConfirmTitle =>
      'Usunąć te dane logowania?';

  @override
  String get providerSignOutAccountConfirmTitle => 'Wylogować z tego konta?';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'Agenty korzystające z $provider przełączą się na inne klucze i konta. Gdy nie zostanie żadne, przestaną działać, dopóki nie dodasz nowego.';
  }

  @override
  String get providerBaseUrlHint => 'Bazowy URL (opcjonalnie)';

  @override
  String get addProvider => 'Dodaj dostawcę';

  @override
  String get noCustomProviders => 'Brak niestandardowych dostawców.';

  @override
  String get providerNameLabel => 'Nazwa';

  @override
  String get apiTypeLabel => 'Typ API';

  @override
  String get providerBaseUrlLabel => 'Bazowy URL';

  @override
  String get providerApiKeyOptionalHint => 'Klucz API (opcjonalnie)';

  @override
  String get dialectOpenAiCompatible => 'Zgodny z OpenAI';

  @override
  String get dialectAnthropicCompatible => 'Zgodny z Anthropic';

  @override
  String get removeProviderTooltip => 'Usuń dostawcę';

  @override
  String get providerLogInWithBrowser => 'Zaloguj przez przeglądarkę';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'Zaloguj się do $provider';
  }

  @override
  String get providerLabel => 'Dostawca';

  @override
  String get selectProviderToLogin => 'Wybierz dostawcę do logowania';

  @override
  String providerLoginFailed(String error) {
    return 'Logowanie nie powiodło się: $error';
  }

  @override
  String get providerWaitingForBrowser =>
      'Czekam na autoryzację w przeglądarce…';

  @override
  String get providerPasteCodeHint => 'Lub wklej kod z przeglądarki';

  @override
  String get providerCompleteLogin => 'Dokończ';

  @override
  String get providerConnectedApiKey => 'Połączono przez klucz API';

  @override
  String get providerConnectedOauth => 'Połączono';

  @override
  String providerConnectedAccount(String account) {
    return 'Połączono · $account';
  }

  @override
  String get providerLocalReady => 'Lokalny · gotowy';

  @override
  String get providerNotConnected => 'Nie połączono';

  @override
  String get preparingWorkspace => 'Przygotowywanie obszaru roboczego…';

  @override
  String provisioningRunningSetupScript(String repo) {
    return 'Uruchamianie skryptu konfiguracyjnego dla $repo…';
  }

  @override
  String get repoScriptsTitle => 'Skrypty';

  @override
  String get repoScriptsTooltip => 'Konfiguruj skrypty cyklu życia';

  @override
  String get repoScriptsSetupLabel => 'Skrypt konfiguracyjny';

  @override
  String get repoScriptsSetupHelp =>
      'Uruchamia się w drzewie roboczym przestrzeni zaraz po jej utworzeniu — instalacja zależności, generowanie plików. Niepowodzenie oznacza przestrzeń jako nieudaną; ponowna próba uruchamia skrypt ponownie.';

  @override
  String get repoScriptsArchiveLabel => 'Skrypt archiwizacji';

  @override
  String get repoScriptsArchiveHelp =>
      'Uruchamiany tuż przed usunięciem drzewa roboczego przestrzeni — posprzątaj zasoby poza drzewem roboczym. Błąd nigdy nie blokuje usunięcia.';

  @override
  String get repoScriptsEnvHelp =>
      'Uruchamiany przez bash z drzewa roboczego, z ustawionymi CC_WORKSPACE_PATH (drzewo robocze), CC_ROOT_PATH (katalog główny repozytorium), CC_SPACE_ID, CC_SPACE_NAME i CC_REPO_NAME.';

  @override
  String get repoScriptsSetupPlaceholder => 'np. pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      'np. docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => 'Ostatnie uruchomienia';

  @override
  String get repoScriptsNoRuns => 'Brak uruchomień';

  @override
  String get repoScriptsSaved => 'Zapisano skrypty';

  @override
  String get repoScriptsRunKindSetup => 'Przygotowanie';

  @override
  String get repoScriptsRunKindArchive => 'Archiwizacja';

  @override
  String get repoScriptsRunStatusRunning => 'W toku';

  @override
  String get repoScriptsRunStatusSucceeded => 'Powodzenie';

  @override
  String get repoScriptsRunStatusFailed => 'Niepowodzenie';

  @override
  String get repoScriptsRunStatusTimedOut => 'Przekroczono limit czasu';

  @override
  String repoScriptsExitCode(int code) {
    return 'Kod wyjścia $code';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return 'Klonowanie $repo…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'Przełączanie na pull request w $repo…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'Konfigurowanie agenta $agent…';
  }

  @override
  String get workspacePrepFailed =>
      'Nie udało się przygotować obszaru roboczego';

  @override
  String get workspacePrepStopped =>
      'Zatrzymano przygotowanie obszaru roboczego';

  @override
  String get stopWorkspacePrep => 'Zatrzymaj przygotowanie';

  @override
  String get stopWorkspacePrepTooltip =>
      'Zatrzymaj przygotowanie tego obszaru roboczego';

  @override
  String get stopWorkspacePrepConfirm =>
      'Zatrzymać przygotowanie tego obszaru roboczego? Trwające klonowanie zostanie odrzucone — możesz zacząć od nowa stąd.';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count message(s) will send when ready';
  }

  @override
  String get membersNav => 'Członkowie';

  @override
  String get membersSettingsDescription =>
      'Osoby z dostępem do tego obszaru roboczego: lista, zaproszenia i dziennik audytu';

  @override
  String get memberRosterLabel => 'Lista członków';

  @override
  String get memberRepoAccessAction => 'Dostęp do repozytorium';

  @override
  String memberRepoAccessTitle(String name) {
    return 'Dostęp do repozytorium: $name';
  }

  @override
  String get roleOwner => 'Właściciel';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleMember => 'Członek';

  @override
  String get roleViewer => 'Obserwator';

  @override
  String get roleGuest => 'Gość';

  @override
  String get removeMemberTitle => 'Usuń członka';

  @override
  String removeMemberConfirm(String name) {
    return 'Usunąć $name z tego obszaru roboczego? Natychmiast straci dostęp.';
  }

  @override
  String get transferOwnershipAction => 'Przenieś własność';

  @override
  String get transferOwnershipTitle => 'Przenieś własność';

  @override
  String transferOwnershipConfirm(String name) {
    return 'Ustanowić $name właścicielem tego obszaru roboczego? Zostaniesz administratorem. Tylko właściciel może usunąć obszar roboczy lub zmienić rolę innego administratora.';
  }

  @override
  String get transferOwnershipCta => 'Przenieś';

  @override
  String get auditTrailLabel => 'Dziennik audytu autoryzacji';

  @override
  String get auditTrailDescription =>
      'Każda zgoda i odmowa, spięte łańcuchem skrótów, więc zmiana lub usunięcie wpisu jest wykrywalne.';

  @override
  String get auditVerifyChain => 'Zweryfikuj łańcuch';

  @override
  String auditChainIntact(int count) {
    return 'Chain intact — $count entries verified';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'Łańcuch przerwany przy wpisie $seq: $reason';
  }

  @override
  String get auditEmpty => 'Nie zarejestrowano jeszcze żadnych decyzji.';

  @override
  String get auditDenied => 'Odmowa';

  @override
  String get auditAllowed => 'Zgoda';

  @override
  String auditOnBehalfOf(String user) {
    return 'dla $user';
  }

  @override
  String get policyTemplatesLabel => 'Szablony polityki';

  @override
  String get policyTemplatesDescription =>
      'Zastosuj początkową postawę albo przenieś ją między obszarami roboczymi.';

  @override
  String get policyTemplateStrict => 'Rygorystyczny';

  @override
  String get policyTemplateBalanced => 'Zrównoważony';

  @override
  String get policyTemplatePermissive => 'Liberalny';

  @override
  String get policyTemplateApply => 'Zastosuj';

  @override
  String policyTemplateApplied(int count) {
    return 'Applied $count rules';
  }

  @override
  String get policyExport => 'Kopiuj politykę';

  @override
  String get policyExported => 'Skopiowano politykę do schowka';

  @override
  String get policyImport => 'Wklej politykę';

  @override
  String policyImported(int count) {
    return 'Imported $count rules';
  }

  @override
  String get approveAndRemember => 'Zatwierdź na 8 godzin';

  @override
  String get approveAndRememberTooltip =>
      'Zatwierdza tę akcję i przestaje pytać o podobne w tym obszarze roboczym przez 8 godzin. Wygasa samo.';

  @override
  String get unknownUserLabel => 'Nieznany użytkownik';

  @override
  String get inviteMember => 'Zaproś członka';

  @override
  String get inviteRepoAccessHeader => 'Dostęp do repozytoriów';

  @override
  String get inviteRepoAccessExplainer =>
      'Tylko zaznaczone repozytoria są udostępniane zaproszonej osobie, na wybranym poziomie. Reszta pozostaje ukryta.';

  @override
  String get grantLevelRead => 'Odczyt';

  @override
  String get grantLevelReview => 'Recenzja';

  @override
  String get grantLevelWrite => 'Zapis';

  @override
  String get inviteExpiryLabel => 'Wygasa po';

  @override
  String get expiryOneDay => '1 dzień';

  @override
  String get expirySevenDays => '7 dni';

  @override
  String get expiryThirtyDays => '30 dni';

  @override
  String get createInviteAction => 'Utwórz zaproszenie';

  @override
  String get inviteOneTimeCodeLabel => 'Kod jednorazowy';

  @override
  String get inviteCodeShownOnce =>
      'Ten kod wyświetli się tylko raz — skopiuj go teraz.';

  @override
  String get inviteLinkLabel => 'Link zapraszający';

  @override
  String get inviteRedeemHint =>
      'Przekaż kod zaproszonej osobie; ta użyje go razem z adresem URL Twojego serwera.';

  @override
  String get inviteScanQr => 'Albo zeskanuj, aby użyć';

  @override
  String get inviteLoopbackWarningTitle => 'Zaproszenie wskazuje adres lokalny';

  @override
  String get inviteLoopbackWarningBody =>
      'Współpracownicy na innych maszynach nie dotrą do tego serwera. Uruchom tunel (Ustawienia → Integracje → Udostępnij ten serwer) albo powiąż serwer z siecią, aby użytkownicy spoza tego hosta mogli się łączyć.';

  @override
  String get inviteStatusOpen => 'Otwarte';

  @override
  String get inviteStatusUsed => 'Wykorzystane';

  @override
  String get inviteStatusRevoked => 'Odwołane';

  @override
  String get inviteStatusExpired => 'Wygasłe';

  @override
  String inviteCreatedTime(String time) {
    return 'Utworzono $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'wygasa $date';
  }

  @override
  String get noActivityYet => 'Brak aktywności';

  @override
  String get couldNotLoadMembers => 'Nie udało się wczytać członków';

  @override
  String get couldNotLoadInvites => 'Nie udało się wczytać zaproszeń';

  @override
  String get couldNotLoadActivity => 'Nie udało się wczytać aktywności';

  @override
  String get yourDevices => 'Twoje urządzenia';

  @override
  String get yourDevicesDescription =>
      'Klienci sparowani z Twoim kontem na tym serwerze.';

  @override
  String get noOwnDevices =>
      'Żadne urządzenie nie jest jeszcze sparowane z Twoim kontem';

  @override
  String get renameDeviceTitle => 'Zmień nazwę urządzenia';

  @override
  String get revokeDeviceTitle => 'Odwołaj urządzenie';

  @override
  String revokeDeviceConfirm(String label) {
    return 'Odwołać $label? Zostanie natychmiast rozłączone i straci dostęp do tego serwera.';
  }

  @override
  String devicePairedTime(String time) {
    return 'Sparowano $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'Ostatnio widziane $time';
  }

  @override
  String get deviceNeverSeen => 'Nigdy nie połączone';

  @override
  String get profileSectionLabel => 'Profil';

  @override
  String get profileSectionDescription =>
      'Jak widzą Cię współpracownicy i w autorstwie commitów gita.';

  @override
  String get displayNameLabel => 'Nazwa wyświetlana';

  @override
  String get emailLabel => 'Adres e-mail';

  @override
  String get gitAuthorNameLabel => 'Nazwa autora w gicie';

  @override
  String get gitAuthorEmailLabel => 'E-mail autora w gicie';

  @override
  String get profileSaved => 'Profil zapisany';

  @override
  String get presenceOnline => 'Online';

  @override
  String get presenceIdle => 'Bezczynny';

  @override
  String get presenceTyping => 'Pisze…';

  @override
  String get presenceAgentThinking => 'Myśli';

  @override
  String get presenceAgentRunning => 'Pracuje';

  @override
  String get presenceAgentBlocked => 'Zablokowany';

  @override
  String get presenceAgentDone => 'Gotowe';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
  }

  @override
  String get presenceRailLabel => 'Kto jest online';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'Włącz Nie przeszkadzać';

  @override
  String get dndTooltipOff => 'Wyłącz Nie przeszkadzać';

  @override
  String get startPresenting => 'Rozpocznij prezentację';

  @override
  String get stopPresenting => 'Zakończ prezentację';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name prezentuje';
  }

  @override
  String get spotlightLeave => 'Opuść';

  @override
  String typingIndicator(String name) {
    return '$name pisze…';
  }

  @override
  String get ideTabNotes => 'Notatki';

  @override
  String get ideSidebarAllViews => 'Wszystkie widoki';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'Wszystkie widoki ($count ukryte)';
  }

  @override
  String get ideSidebarPinView => 'Przypnij do paska bocznego';

  @override
  String get ideSidebarUnpinView => 'Odepnij od paska bocznego';

  @override
  String get notesEmptyHint =>
      'Dodaj notatkę dla każdego, kto przejmie tę rozmowę…';

  @override
  String get notesEditTooltip => 'Edytuj notatkę';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'Zaktualizowano przez $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name edytuje';
  }

  @override
  String get notesSaveFailed => 'Nie udało się zapisać notatki';

  @override
  String get reactionAddTooltip => 'Dodaj reakcję';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'Zareaguj: $emoji';
  }

  @override
  String get autonomyDialLabel => 'Autonomia';

  @override
  String get autonomyProposeOnly => 'Tylko propozycje';

  @override
  String get autonomyActWithApproval => 'Działa po zatwierdzeniu';

  @override
  String get autonomyActFreely => 'Działa swobodnie';

  @override
  String get autonomyDefaultOption => 'Domyślnie';

  @override
  String get checkerLabel => 'Kontroler';

  @override
  String get checkerNone => 'Brak';

  @override
  String get checkerCaption =>
      'Kontroler recenzuje ukończone uruchomienia innych agentów.';

  @override
  String get takeoverTooltip => 'Przejmij drzewo robocze';

  @override
  String get takeoverBannerSelf => 'Przejmij drzewo robocze tej rozmowy';

  @override
  String takeoverBannerOther(String name) {
    return 'Drzewo robocze tej rozmowy zostało przejęte przez $name';
  }

  @override
  String get handBackButton => 'Oddaj';

  @override
  String get handBackDialogTitle => 'Oddaj drzewo robocze';

  @override
  String get handBackDialogNoteHint => 'Opcjonalna notatka dla agenta…';

  @override
  String takeoverFailed(String message) {
    return 'Nie udało się przejąć: $message';
  }

  @override
  String handBackFailed(String message) {
    return 'Nie udało się oddać: $message';
  }

  @override
  String get planStudioTitle => 'Plan Studio';

  @override
  String get plansTitle => 'Plany';

  @override
  String get plansSubtitle => 'Aktywne plany, dokumenty planów i playbooki';

  @override
  String get plansActiveSection => 'Aktywne plany';

  @override
  String get plansDocumentsSection => 'Dokumenty planów';

  @override
  String get plansPlaybooksSection => 'Playbooki';

  @override
  String get plansNoActive => 'Nie ma jeszcze aktywnych planów.';

  @override
  String get plansNoDocuments => 'Nie ma jeszcze dokumentów planów.';

  @override
  String get plansNoPlaybooks => 'Nie ma jeszcze playbooków.';

  @override
  String get planNotFound => 'Nie znaleziono planu.';

  @override
  String get planOpenInStudio => 'Otwórz';

  @override
  String get planNodeTitle => 'Tytuł';

  @override
  String get planNodeDescription => 'Opis';

  @override
  String get planNodeDescriptionHint => 'Co ma zrobić ten krok…';

  @override
  String get planNodeApplyDescription => 'Zastosuj';

  @override
  String get planNodeRole => 'Rola';

  @override
  String get planNodeDependencies => 'Zależy od';

  @override
  String get planNodeDependenciesHint => 'Dodaj zależność';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zależności',
      many: '$count zależności',
      few: '$count zależności',
      one: '$count zależność',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'Brak zależności, więc ten krok wykonuje się od razu po starcie planu';

  @override
  String get planNodeOutputSchema => 'Schemat wyjścia (JSON)';

  @override
  String get planNodeEstimate => 'Szacunek';

  @override
  String get planNodeProvenance => 'Pochodzenie';

  @override
  String get planNodeAlreadyExecuted =>
      'Już wykonano — edycja rozgałęzia plan od tego miejsca.';

  @override
  String get planNewNodeTitle => 'Nowy krok';

  @override
  String get planEstimateNoHistory => 'Brak historii';

  @override
  String get planEstimateBlastUnknown => 'Zasięg zmian: nieznany';

  @override
  String get planEstimatePartial => 'częściowy';

  @override
  String get planEstimateAction => 'Oszacuj';

  @override
  String planEstimateDuration(String range) {
    return 'Czas trwania $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'Zasięg zmian: pliki: $files, symbole: $symbols';
  }

  @override
  String get planApprove => 'Zatwierdź plan';

  @override
  String get planApproveSelectedNodes => 'Zatwierdź wybrane';

  @override
  String get planReject => 'Odrzuć';

  @override
  String get planCancel => 'Anuluj uruchomienie';

  @override
  String get planContinueNode => 'Kontynuuj węzeł';

  @override
  String get planTotalNotEstimated => 'Jeszcze nie oszacowano';

  @override
  String get planBudgetExceeded => 'powyżej budżetu';

  @override
  String planBudgetCeiling(String amount) {
    return 'budżet ≤ \$$amount';
  }

  @override
  String get planVersionsTitle => 'Wersje';

  @override
  String get planNoRevisions => 'Nie ma jeszcze wersji.';

  @override
  String get planDiffIdentical => 'Brak zmian.';

  @override
  String get planDiffGoalChanged => 'Zmieniono cel';

  @override
  String get planDiffBudgetChanged => 'Zmieniono budżet';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'Zmiany od v$fromRev do v$toRev';
  }

  @override
  String planDiffAdded(String node) {
    return 'Dodano $node';
  }

  @override
  String planDiffRemoved(String node) {
    return 'Usunięto $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return 'Zmieniono $node: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'Dodano krawędź: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'Usunięto krawędź: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'Dodano rolę: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'Usunięto rolę: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'Ponownie przypisano rolę: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'Plan został przeliczony: zatwierdzono v$approved, teraz jest to v$current. Zrecenzuj diff przed kontynuacją.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'Rzeczywisty koszt: \$$amount';
  }

  @override
  String get planPlaybookRun => 'Uruchom';

  @override
  String get planPlaybookDelete => 'Usuń playbook';

  @override
  String get planPlaybookProposed =>
      'Zaproponowano plan — zatwierdź go w Plan Studio.';

  @override
  String get planPlaybookAnchorTicket => 'Zakotwiczone zgłoszenie';

  @override
  String get planPlaybookPickTicket => 'Wybierz zgłoszenie…';

  @override
  String get planPlaybookProposeRun => 'Zaproponuj plan';

  @override
  String get planPlaybookRepoHint => 'Identyfikator repozytorium';

  @override
  String get planPlaybookAgentHint => 'Identyfikator agenta';

  @override
  String planPlaybookRunTitle(String name) {
    return 'Uruchom $name';
  }

  @override
  String planPlaybookParamCount(int count) {
    return 'Parametry: $count';
  }

  @override
  String get recentLabel => 'Ostatnie';

  @override
  String get cheatSheetTitle => 'Skróty klawiszowe';

  @override
  String get cheatSheetGlobal => 'Globalne';

  @override
  String get cheatSheetThisScreen => 'Ten ekran';

  @override
  String get cheatSheetReservedInBrowser => 'Zarezerwowane w przeglądarce';

  @override
  String get keybindingCheatSheet => 'Skróty klawiszowe';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      'Pokaż ściągę skrótów klawiszowych dla bieżącego ekranu';

  @override
  String get runPlaybookLabel => 'Uruchom playbook';

  @override
  String get playbooksLabel => 'Playbooki';

  @override
  String get keybindingUndo => 'Cofnij';

  @override
  String get keybindingRedo => 'Ponów';

  @override
  String get keybindingUndoLastActionDescription =>
      'Cofnij ostatnią odwracalną czynność';

  @override
  String get keybindingRedoLastActionDescription =>
      'Ponów ostatnią cofniętą czynność';

  @override
  String get undone => 'Cofnięto';

  @override
  String get redone => 'Ponowiono';

  @override
  String get undoFailed => 'Nie udało się cofnąć';

  @override
  String get undoLabelTicketEdit => 'edycja zgłoszenia';

  @override
  String get undoLabelMessageEdit => 'edycja wiadomości';

  @override
  String get undoLabelTodoStatus => 'status todo';

  @override
  String get inboxTitle => 'Skrzynka';

  @override
  String get inboxReview => 'Recenzuj';

  @override
  String get inboxOpen => 'Otwórz';

  @override
  String get inboxAllCaughtUp => 'Jesteś na bieżąco';

  @override
  String get inboxGitHubDownTitle => 'GitHub może mieć awarię';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub zgłasza $status, więc pull requesty mogą tu nie widnieć, choć w rzeczywistości nie są zakończone.';
  }

  @override
  String get inboxGitHubIdentityTitle =>
      'Nie udało się potwierdzić Twojego konta GitHub';

  @override
  String get inboxGitHubIdentityBody =>
      'Skrzynka jest porządkowana według tego, kim jesteś na GitHubie. Dopóki to się nie wczyta, pozostaje pusta, nawet gdy czekają na Ciebie pull requesty.';

  @override
  String get inboxSeverityBlocking => 'Zablokowane';

  @override
  String get inboxSeverityWaiting => 'Oczekujące';

  @override
  String get inboxSeverityInfo => 'Informacje';

  @override
  String get inboxSyncFailed => 'Nie udało się zsynchronizować';

  @override
  String get inboxNeedsYourAttention => 'Wymaga Twojej uwagi';

  @override
  String get inboxSectionNeedsYourReview => 'Czeka na Twoją recenzję';

  @override
  String get inboxSectionReturnedToYou => 'Zwrócone do Ciebie';

  @override
  String get inboxSectionApproved => 'Zatwierdzone';

  @override
  String get inboxSectionDrafts => 'Szkice';

  @override
  String get inboxSectionWaitingForReviewers => 'Oczekujące na recenzentów';

  @override
  String get inboxSectionMergingAndMerged => 'Scalane i ostatnio scalone';

  @override
  String get inboxSectionWaitingForAuthor => 'Oczekujące na autora';

  @override
  String get inboxColumnTitle => 'Tytuł';

  @override
  String get inboxColumnChanges => 'Zmiany';

  @override
  String get inboxColumnUpdated => 'Zaktualizowano';

  @override
  String get inboxReviewApproved => 'Zatwierdzone';

  @override
  String get inboxReviewChangesRequested => 'Zażądano zmian';

  @override
  String get inboxHeroSubtitle =>
      'Każdy pull request z Twoim udziałem, uporządkowany według tego, co dalej.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requestu czeka na Twoją recenzję',
      many: '$count pull requestów czeka na Twoją recenzję',
      few: '$count pull requesty czekają na Twoją recenzję',
      one: '$count pull request czeka na Twoją recenzję',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wróciło do Ciebie',
      many: '$count wróciło do Ciebie',
      few: '$count wróciły do Ciebie',
      one: '$count wrócił do Ciebie',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted =>
      'Ta zmiana nie została zapisana i została wycofana';

  @override
  String get offlinePendingLabel => 'oczekuje';

  @override
  String get offlineSyncingLabel => 'synchronizacja';

  @override
  String get copyLinkLabel => 'Skopiuj link do tej strony';

  @override
  String get agentsSectionLabel => 'Agenci';

  @override
  String get fleetWorkersTitle => 'Workerzy';

  @override
  String get fleetWorkersSubtitle => 'Maszyny dostępne do uruchamiania zadań';

  @override
  String get fleetJobsTitle => 'Zadania';

  @override
  String get fleetJobsSubtitle => 'Praca rozdzielona w ramach floty';

  @override
  String get fleetNoWorkers =>
      'Nie ma jeszcze workerów — druga maszyna uruchamiająca `cc_worker --server <url>` dołącza do floty.';

  @override
  String get fleetNoJobs => 'Brak zadań.';

  @override
  String get fleetError => 'Nie udało się wczytać floty';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rdzenia',
      many: '$count rdzeni',
      few: '$count rdzenie',
      one: '$count rdzeń',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'Puls $time';
  }

  @override
  String get fleetNoHeartbeat => 'Brak pulsu';

  @override
  String fleetLastErrorLabel(String error) {
    return 'Ostatni błąd: $error';
  }

  @override
  String get fleetDrain => 'Opróżnij';

  @override
  String get fleetResume => 'Wznów';

  @override
  String get fleetRevoke => 'Odwołaj';

  @override
  String get fleetRemove => 'Usuń';

  @override
  String get fleetRevokeTitle => 'Odwołać workera?';

  @override
  String fleetRevokeBody(String name) {
    return 'Odwołać $name? Jego sesja zostanie zakończona, a aktywne zadania ponownie przypisane.';
  }

  @override
  String get fleetRemoveTitle => 'Usunąć workera?';

  @override
  String fleetRemoveBody(String name) {
    return 'Usunąć $name z floty? Spowoduje to usunięcie jego rekordu.';
  }

  @override
  String get fleetActionFailed => 'Działanie nie powiodło się';

  @override
  String get fleetJobUnassigned => 'Nieprzypisane';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return 'próby: $attempts/$max';
  }

  @override
  String get fleetPlacementReasons => 'Decyzje umieszczania';

  @override
  String get fleetNoPlacements => 'Nie ma jeszcze decyzji umieszczania.';

  @override
  String get fleetStatusOnline => 'Online';

  @override
  String get fleetStatusDraining => 'Opróżnianie';

  @override
  String get fleetStatusOffline => 'Offline';

  @override
  String get fleetStatusIncompatible => 'Niekompatybilny';

  @override
  String get fleetStatusRevoked => 'Odwołany';

  @override
  String get fleetJobStatusQueued => 'W kolejce';

  @override
  String get fleetJobStatusRunning => 'W trakcie';

  @override
  String get fleetJobStatusSucceeded => 'Zakończone sukcesem';

  @override
  String get fleetJobStatusFailed => 'Niepowodzenie';

  @override
  String get fleetJobStatusCancelled => 'Anulowane';

  @override
  String get evalsNoSuites => 'Nie ma jeszcze zestawów ewaluacyjnych.';

  @override
  String get evalsError => 'Nie udało się wczytać ewaluacji';

  @override
  String get evalsStarterBadge => 'Startowy';

  @override
  String evalsDefaultBatch(int count) {
    return 'Domyślna partia: $count';
  }

  @override
  String get evalsRecentRuns => 'Ostatnie uruchomienia';

  @override
  String get evalsNoRuns => 'Nie ma jeszcze uruchomień.';

  @override
  String get evalsPassRate => 'Skuteczność';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return 'przez: $who';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'Ewaluacja zakończona — zdane: $rate';
  }

  @override
  String get evalsRunFailed => 'Nie udało się uruchomić zestawu';

  @override
  String get evalsRun => 'Uruchom';

  @override
  String get evalsStatusQueued => 'W kolejce';

  @override
  String get evalsStatusRunning => 'W trakcie';

  @override
  String get evalsStatusPassed => 'Zdane';

  @override
  String get evalsStatusFailed => 'Niezdane';

  @override
  String get bannerMeetingJoin => 'Dołącz';

  @override
  String get bannerMeetingRecordAndLink => 'Nagraj i podlinkuj';

  @override
  String get bannerCalendarReconnect => 'Połącz ponownie';

  @override
  String get bannerView => 'Podgląd';

  @override
  String get soundscapeTitle => 'Pejzaże dźwiękowe';

  @override
  String get soundscapePlay => 'Odtwórz';

  @override
  String get soundscapePause => 'Pauza';

  @override
  String get soundscapeMoodLabel => 'Nastrój';

  @override
  String get soundscapeMoodFocus => 'Skupienie';

  @override
  String get soundscapeMoodRelax => 'Relaks';

  @override
  String get soundscapeMoodSleep => 'Sen';

  @override
  String get soundscapeVolumeLabel => 'Głośność';

  @override
  String get soundscapeTuneLabel => 'Strojenie';

  @override
  String get soundscapeTuneMellow => 'Aksamitny';

  @override
  String get soundscapeTuneBright => 'Jasny';

  @override
  String get soundscapeTuneEnergetic => 'Energetyczny';

  @override
  String get soundscapeTuneSpacy => 'Kosmiczny';

  @override
  String get soundscapeTuneResetHint => 'Kliknij dwukrotnie, aby zresetować';

  @override
  String get soundscapeSceneLabel => 'Teraz odtwarzane';

  @override
  String get soundscapeSceneLoading => 'Strojenie tła…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees°C';
  }

  @override
  String get soundscapeLocationLabel => 'Lokalizacja';

  @override
  String get soundscapeLocationDetecting => 'Wykrywanie lokalizacji…';

  @override
  String get soundscapeLocationAutoNote =>
      'Lokalizacja jest wykrywana automatycznie na podstawie tego obszaru roboczego.';

  @override
  String get soundscapeRefreshWeather => 'Odśwież pogodę';

  @override
  String get soundscapeAutoStartLabel => 'Startuj w trybie skupienia';

  @override
  String get soundscapeAutoStartDescription =>
      'Odtwarzaj pejzaż dźwiękowy automatycznie przy rozpoczynaniu sesji skupienia.';

  @override
  String get soundscapeReturnToApp => 'Wróć do aplikacji';

  @override
  String get soundscapePopOut => 'Odtwarzacz w osobnym oknie';

  @override
  String get discussion => 'Dyskusja';

  @override
  String get chat => 'Czat';

  @override
  String get saving => 'Zapisywanie…';

  @override
  String get saved => 'Zapisano';

  @override
  String get saveFailed => 'Nie udało się zapisać';

  @override
  String get commitAndPush => 'Commit i push';

  @override
  String get commit => 'Commit';

  @override
  String get commitAmend => 'Commit (amend)';

  @override
  String get commitAndSync => 'Commit i synchronizacja';

  @override
  String get committed => 'Utworzono commit';

  @override
  String get commitAmended => 'Poprawiono commit';

  @override
  String get commitFailed => 'Nie udało się utworzyć commita';

  @override
  String get moreCommitActions => 'Więcej działań na commitach';

  @override
  String get sourceControl => 'Kontrola wersji';

  @override
  String fixFindingTitle(String location) {
    return 'Naprawa: $location';
  }

  @override
  String get openInEditor => 'Otwórz w edytorze';

  @override
  String get regexTesterTitle => 'Przetestuj wyrażenie regularne';

  @override
  String get regexTesterHint => 'Wpisz przykład';

  @override
  String get regexMatch => 'Dopasowanie';

  @override
  String get regexNoMatch => 'Brak dopasowania';

  @override
  String get regexInvalidPattern => 'Nieprawidłowy wzorzec';

  @override
  String get symbolLookupNone =>
      'Brak definicji w indeksie ani w tym pull requeście';

  @override
  String get symbolLookupInDiff => 'Znaleziono w tym pull requeście';

  @override
  String get symbolLookupFromBase =>
      'Z bazowego checkoutu — worktree tego PR nie jest jeszcze zindeksowane';

  @override
  String get symbolImplementations => 'Implementacje';

  @override
  String symbolCallersCount(int count) {
    return '$count wywołań';
  }

  @override
  String get commitMessageHint => 'Komunikat commita';

  @override
  String get pushedToPr => 'Wypchnięto do PR';

  @override
  String get pushFailed => 'Nie udało się wypchnąć';

  @override
  String get reviewFindings => 'Ustalenia';

  @override
  String get treeLabel => 'Drzewo';

  @override
  String get toggleFileTree => 'Pokaż lub ukryj drzewo plików';

  @override
  String get diffViewSettings => 'Ustawienia widoku diffu';

  @override
  String get splitViewLabel => 'Podzielony';

  @override
  String get unifiedViewLabel => 'Ujednolicony';

  @override
  String get wrapLines => 'Zawijaj wiersze';

  @override
  String get shiftClickSelectRange => 'Kliknij z Shiftem, aby wybrać zakres';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pliku',
      many: '$count plików',
      few: '$count pliki',
      one: '$count plik',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'Mały PR — $files, ok. $minutes min recenzji';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'Średni PR — $files, zarezerwuj ok. $minutes min na recenzję';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'Duży PR — $files, rozważ podział przed recenzją';
  }

  @override
  String get searchInFiles => 'Szukaj w plikach';

  @override
  String get showFileList => 'Pokaż listę plików';

  @override
  String get searchInFilesHintField => 'Szukaj w plikach…';

  @override
  String get searchInFilesHint => 'Przeszukaj pliki pull requesta';

  @override
  String get searchInWholeRepo => 'Szukaj w całym repozytorium';

  @override
  String get searchInThisPullRequest => 'Szukaj w tym pull requeście';

  @override
  String get searchNoResults => 'Brak wyników';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wyniku',
      many: '$count wyników',
      few: '$count wyniki',
      one: '$count wynik',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files pliku',
      many: '$files plikach',
      few: '$files plikach',
      one: '$files pliku',
    );
    return '$_temp0 w $_temp1';
  }

  @override
  String get discardChangesTitle => 'Odrzucić zmiany?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pliku',
      many: '$count plików',
      few: '$count pliki',
      one: '$count plik',
    );
    return 'Odrzucić $_temp0 do HEAD? Tej operacji nie można cofnąć.';
  }

  @override
  String get discardAll => 'Odrzuć wszystko';

  @override
  String get discardFailed => 'Nie udało się odrzucić zmian';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pliku',
      many: '$count plików',
      few: '$count pliki',
      one: '$count plik',
    );
    return 'Odrzucono $_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted pliku',
      many: '$reverted plików',
      few: '$reverted pliki',
      one: '$reverted plik',
    );
    return 'Odrzucono $_temp0; pominięto $skipped (nieśledzone)';
  }

  @override
  String get prWorktreeUnavailable => 'Obszar roboczy nie jest gotowy';

  @override
  String get prWorktreeUnavailableHint =>
      'Przygotowanie plików pull requesta nie powiodło się. Otwórz pull request ponownie, aby spróbować jeszcze raz.';

  @override
  String get timestampRelativeLabel => 'Względny';

  @override
  String get timestampRawLabel => 'Znacznik czasu';

  @override
  String get copyTimestamp => 'Skopiuj znacznik czasu';

  @override
  String get copiedTimestamp => 'Skopiowano znacznik czasu';

  @override
  String get previewDeployment => 'Wdrożenie podglądowe';

  @override
  String previewDeploymentTab(String site) {
    return 'Podgląd: $site';
  }

  @override
  String get askForReview => 'Poproś o recenzję…';

  @override
  String get closePrsConfirmTitle => 'Zamknąć pull requesty?';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zamknąć $count pull requesta?',
      many: 'Zamknąć $count pull requestów?',
      few: 'Zamknąć $count pull requesty?',
      one: 'Zamknąć $count pull request?',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zamknięto $count pull requesta',
      many: 'Zamknięto $count pull requestów',
      few: 'Zamknięto $count pull requesty',
      one: 'Zamknięto $count pull request',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Przypisano $count pull requesta',
      many: 'Przypisano $count pull requestów',
      few: 'Przypisano $count pull requesty',
      one: 'Przypisano $count pull request',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Poproszono o recenzję $count pull requestu',
      many: 'Poproszono o recenzję $count pull requestów',
      few: 'Poproszono o recenzję $count pull requestów',
      one: 'Poproszono o recenzję $count pull requesta',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count działania nie powiodło się',
      many: '$count działań nie powiodło się',
      few: '$count działania nie powiodły się',
      one: '$count działanie nie powiodło się',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'Diagram';

  @override
  String get diagramViewSource => 'Pokaż źródło';

  @override
  String get diagramHideSource => 'Ukryj źródło';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'Podgląd diagramu niedostępny ($reason)';
  }

  @override
  String get planUnavailable => 'Plan niedostępny';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kroku',
      many: '$count kroków',
      few: '$count kroki',
      one: '$count krok',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'Zatwierdź i uruchom';

  @override
  String get planStatusDraft => 'Szkic';

  @override
  String get planStatusProposed => 'Plan';

  @override
  String get planStatusApproved => 'Plan zatwierdzony';

  @override
  String get planStatusRejected => 'Plan odrzucony';

  @override
  String get planStatusSuperseded => 'Plan zastąpiony';

  @override
  String planRevisionLabel(int revision) {
    return 'Wersja $revision';
  }

  @override
  String get adapterEnforcementTitle => 'Co wymusza ten adapter';

  @override
  String get enforcementFiltersToolSurface =>
      'Control Center wybiera narzędzia';

  @override
  String get enforcementInterceptsToolCalls =>
      'Każde wywołanie jest sprawdzane przed uruchomieniem';

  @override
  String get enforcementObservesCompletionContract =>
      'Uruchomienie odpowiada za swój rezultat';

  @override
  String get enforcementNativeToolsInterceptable =>
      'Własne narzędzia runnera są widoczne';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'Narzędzia w procesie działają w piaskownicy';

  @override
  String get enforcementYes => 'Tak';

  @override
  String get enforcementNo => 'Nie';

  @override
  String get adapterEnforcementCaveats => 'Zastrzeżenia';

  @override
  String get enforcementSummaryModesEnforced => 'Tryby wymuszane';

  @override
  String get enforcementSummaryModesNotEnforced => 'Tryby niewymuszane';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zastrzeżenia',
      many: '$count zastrzeżeń',
      few: '$count zastrzeżenia',
      one: '$count zastrzeżenie',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'Tryby tylko do odczytu nie są strukturalne: Control Center nie może usunąć własnych narzędzi tego runnera.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'Brak bramki przed wykonaniem: przez Control Center przechodzą tylko wywołania narzędzi MCP.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'Własne narzędzia plikowe i powłokowe runnera nigdy nie docierają do Control Center; jedynym poziomem bezpieczeństwa pod nimi jest piaskownica systemu.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'Narzędzia plikowe w procesie działają poza piaskownicą, więc powierzchnia narzędzi jest jedyną granicą systemu plików.';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center nie może przycisnąć ani oznaczyć nieudanym uruchomienia, które kończy się bez dostarczenia rezultatu.';

  @override
  String get modeDegraded => 'Ograniczony';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return 'Tryb $mode na $adapter opiera się tylko na piaskownicy; własne narzędzia plikowe agenta nie są przechwytywane.';
  }

  @override
  String get artifactUnavailable => 'Artefakt niedostępny';

  @override
  String artifactRevisionLabel(int count) {
    return 'Wersje: $count';
  }

  @override
  String get artifactShowMore => 'Pokaż więcej';

  @override
  String get artifactShowLess => 'Pokaż mniej';

  @override
  String get artifactCopy => 'Skopiuj';

  @override
  String get artifactCopied => 'Skopiowano artefakt';

  @override
  String get artifactsTabLabel => 'Artefakty';

  @override
  String get artifactsEmptyTitle => 'Nie ma jeszcze artefaktów';

  @override
  String get artifactsEmptyBody =>
      'Gdy agent opublikuje tu tabelę, wykres lub diagram, pojawi się na tej liście.';

  @override
  String get artifactRevisionPickerLabel => 'Wersja';

  @override
  String get artifactRestoreRevision => 'Przywróć tę wersję';

  @override
  String get artifactOpenInTab => 'Otwórz w karcie';

  @override
  String get artifactTitleFallback => 'Artefakt';

  @override
  String get providerGenerationLabel => 'Domyślne parametry generowania';

  @override
  String get providerGenerationHint =>
      'Zostaw pole puste, aby użyć domyślnej wartości punktu końcowego. Modele publikują własne limity wyjścia i przepisy próbkowania; serwowanie ich przy innych wartościach może pogorszyć jakość.';

  @override
  String get providerMaxTokensLabel => 'Maks. tokenów wyjściowych';

  @override
  String get addModel => 'Dodaj model';

  @override
  String get modelListTitle => 'Lista modeli';

  @override
  String get railProvidersGroup => 'Dostawcy';

  @override
  String get railCustomProvidersGroup => 'Dostawcy własni';

  @override
  String get editModelSettings => 'Edytuj ustawienia modelu';

  @override
  String get modelIdLabel => 'Identyfikator modelu';

  @override
  String get modelIdImmutableHint =>
      'Identyfikator serwowany przez punkt końcowy; ustalany raz przy wpisaniu na listę.';

  @override
  String get contextWindowLabel => 'Okno kontekstu';

  @override
  String get inputTypesLabel => 'Typy wejścia';

  @override
  String get outputTypesLabel => 'Typy wyjścia';

  @override
  String get modalityText => 'Tekst';

  @override
  String get modalityImage => 'Obraz';

  @override
  String get modalityAudio => 'Audio';

  @override
  String get modalityVideo => 'Wideo';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'Przywróć automatyczny';

  @override
  String get modelOverrideEdited => 'Zmienione';

  @override
  String get manualModelBadge => 'Dodany ręcznie';

  @override
  String get modelIdRequired => 'Podaj identyfikator modelu.';

  @override
  String get modelTokensInvalid => 'Podaj dodatnią liczbę całkowitą tokenów.';

  @override
  String get removeModelAction => 'Usuń model';

  @override
  String removeModelConfirmTitle(String model) {
    return 'Usunąć $model?';
  }

  @override
  String get removeModelConfirmBody =>
      'Model znika z listy, a agenci przypięci do niego przestają działać. Dostawca nie jest dotknięty.';

  @override
  String get addModelProviderTitle => 'Dodaj dostawcę modeli';

  @override
  String get addModelProviderDescription =>
      'Skonfiguruj własny punkt końcowy API i jego modele.';

  @override
  String get modelListEmptyHint =>
      'Brak skonfigurowanych modeli. Dodaj model, aby używać go na czacie.';

  @override
  String get addProviderModelsHint =>
      'Modele są pobierane na żywo, gdy punkt końcowy odpowie. Dodaj ręcznie tylko wtedy, gdy nie może on wylistować własnych.';

  @override
  String get providerTemperatureLabel => 'Temperatura';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved =>
      'Zapisano domyślne parametry generowania';

  @override
  String get providerGenerationInvalid =>
      'Sprawdź wartości: maks. tokeny wyjściowe i top-k muszą być dodatnie, temperatura 0–2, top-p 0–1.';

  @override
  String get providerGenerationOverridden => 'Nadpisane';

  @override
  String get branchNotPushed => 'niewypchnięty';

  @override
  String branchNotOnRemote(String branch) {
    return '„$branch” istnieje tylko w tej rozmowie';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub nigdy nie widział tej gałęzi, więc pull request nie może jej jeszcze użyć. Opublikowanie wypycha commity już obecne w drzewie roboczym — niezcommitowane zmiany zostają nietknięte.';

  @override
  String get publishBranch => 'Opublikuj gałąź';

  @override
  String branchPublished(String branch) {
    return 'Opublikowano „$branch” do origin';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'Gałąź opublikowana. Nie uwzględniono niezcommitowanych zmian: $count.';
  }

  @override
  String get composePrLoadingBranches => 'Wczytywanie gałęzi z GitHuba…';

  @override
  String get composePrBranchesFailed =>
      'Nie udało się wczytać gałęzi z GitHuba. Wpisz nazwę gałęzi albo sprawdź połączenie z GitHubem.';

  @override
  String get composePrSubtitleFromSpace =>
      'Z gałęzi tej rozmowy — najpierw ją opublikuj, jeśli GitHub jej nie widział';

  @override
  String get obsTabInsights => 'Analizy';

  @override
  String get obsTabLive => 'Na żywo';

  @override
  String get obsTabQuality => 'Jakość';

  @override
  String get obsTabUsage => 'Użycie';

  @override
  String get obsUsageTotalTokens => 'Tokeny łącznie';

  @override
  String get obsUsagePeakTokens => 'Szczyt tokenów';

  @override
  String get obsUsageLongestSession => 'Najdłuższa sesja';

  @override
  String get obsUsageCurrentStreak => 'Obecna seria';

  @override
  String get obsUsageLongestStreak => 'Najdłuższa seria';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dnia',
      many: '$count dni',
      few: '$count dni',
      one: '$count dzień',
      zero: '0 dni',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'Aktywność tokenowa';

  @override
  String get obsUsageActivityModeLabel => 'Tryb aktywności tokenowej';

  @override
  String get obsUsageModeDaily => 'Dziennie';

  @override
  String get obsUsageModeWeekly => 'Tygodniowo';

  @override
  String get obsUsageModeCumulative => 'Narastająco';

  @override
  String get obsUsageTimeRange => 'Zakres czasu';

  @override
  String get obsUsageTrendTitle => 'Dzienny trend tokenów';

  @override
  String get obsUsageModelUsage => 'Użycie modeli';

  @override
  String get obsUsageTokensLabel => 'tokeny';

  @override
  String get obsUsageNoActivity => 'Nie zarejestrowano jeszcze użycia tokenów';

  @override
  String get obsUsageOtherModels => 'Inne';

  @override
  String obsUsageCellReadout(String date, String tokens) {
    return '$date · tokeny: $tokens';
  }

  @override
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  ) {
    return 'Aktywność tokenowa od $start do $end. Aktywne dni: $activeDays. Najbardziej obciążony dzień: $peak tokenów.';
  }

  @override
  String get obsScreenSubtitle =>
      'Kontrola agentów na żywo, rozliczanie kosztów, limity i sygnały jakości';

  @override
  String get obsRangeLast24h => 'Ostatnie 24 godziny';

  @override
  String get obsRangeLast7d => 'Ostatnie 7 dni';

  @override
  String get obsRangeLast30d => 'Ostatnie 30 dni';

  @override
  String get obsRangeAll => 'Cały okres';

  @override
  String get obsAddFilter => 'Dodaj filtr';

  @override
  String get obsFilterAgent => 'Agent';

  @override
  String get obsFilterModel => 'Model';

  @override
  String get obsFilterStatus => 'Status';

  @override
  String get obsFilterRole => 'Rola';

  @override
  String get obsKpiTotalRuns => 'Uruchomienia łącznie';

  @override
  String get obsKpiTotalCost => 'Koszt łącznie';

  @override
  String get obsKpiErrorRate => 'Współczynnik błędów';

  @override
  String get obsKpiCacheRate => 'Trafność cache';

  @override
  String get obsKpiTokensPerSec => 'Tokeny / s';

  @override
  String get obsKpiAvgLatency => 'Średnie opóźnienie';

  @override
  String get obsKpiTtft => 'Czas do pierwszego tokena';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta względem poprzedniego okresu';
  }

  @override
  String get obsChartActivity => 'Aktywność';

  @override
  String get obsChartCost => 'Koszt w czasie';

  @override
  String get obsLegendRuns => 'Uruchomienia';

  @override
  String get obsLegendErrors => 'Błędy';

  @override
  String get obsAgentsTitle => 'Agenci';

  @override
  String obsShowAllAgents(int count) {
    return 'Pokaż wszystkich agentów ($count)';
  }

  @override
  String get obsShowFewerAgents => 'Pokaż mniej';

  @override
  String get obsRunsTitle => 'Uruchomienia';

  @override
  String get obsNoRunsInRange => 'Brak uruchomień w tym zakresie';

  @override
  String get obsColTime => 'Czas';

  @override
  String get obsColAgent => 'Agent';

  @override
  String get obsColStatus => 'Status';

  @override
  String get obsColModel => 'Model';

  @override
  String get obsColDuration => 'Czas trwania';

  @override
  String get obsColTokens => 'Tokeny';

  @override
  String get obsColCost => 'Koszt';

  @override
  String get obsColErrors => 'Błędy';

  @override
  String get obsColRuns => 'Uruchomienia';

  @override
  String get obsColAvgLatency => 'Średnie opóźnienie';

  @override
  String get obsColLastActive => 'Ostatnia aktywność';

  @override
  String get obsStatusPending => 'Oczekuje';

  @override
  String get obsStatusRunning => 'W trakcie';

  @override
  String get obsStatusCompleted => 'Zakończone';

  @override
  String get obsStatusError => 'Błąd';

  @override
  String get obsRosterLoadError => 'Nie udało się wczytać listy agentów.';

  @override
  String get obsRosterEmpty => 'Nie ma jeszcze agentów';

  @override
  String get obsRosterEmptyDescription =>
      'Wyślij agenta, a pojawi się tu na żywo — status, bieżące narzędzie, tokeny, koszt.';

  @override
  String get obsKillAgent => 'Ubij agenta';

  @override
  String get obsRosterTokensLabel => 'tok';

  @override
  String get obsCostByRoleTitle => 'Koszt według roli';

  @override
  String get obsCostByRoleSubtitle =>
      'Na co wydaje ten obszar roboczy, według ról agentów';

  @override
  String get obsRoleMain => 'Główny';

  @override
  String get obsRoleSubagents => 'Podagenci';

  @override
  String get obsRoleAdvisor => 'Doradca';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'Główny: $main · podagenci: $sub · doradca: $advisor';
  }

  @override
  String get obsTotal => 'Łącznie';

  @override
  String get obsTokenModelTitle => 'Model tokenowy (5 osi)';

  @override
  String get obsTokenModelSubtitle =>
      'Każdy token wydany przez ten obszar roboczy, według osi';

  @override
  String get obsAxisInput => 'Wejście';

  @override
  String get obsAxisOutput => 'Wyjście';

  @override
  String get obsAxisReasoning => 'Rozumowanie';

  @override
  String get obsAxisCacheRead => 'Odczyt cache';

  @override
  String get obsAxisCacheWrite => 'Zapis cache';

  @override
  String get obsTotalTokens => 'Tokeny łącznie';

  @override
  String get obsCacheDiscountNote =>
      'Tokeny odczytane z cache są rozliczane ze zniżką, więc kosztują znacznie mniej niż ta sama objętość świeżego wejścia.';

  @override
  String get obsByModelTitle => 'Według modelu';

  @override
  String get obsByModelSubtitle => 'Użycie tokenów i kosztów według modelu';

  @override
  String get obsNoModelUsage => 'Nie zarejestrowano jeszcze użycia modeli.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uruchomienia',
      many: '$count uruchomień',
      few: '$count uruchomienia',
      one: '$count uruchomienie',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => 'Na uruchomienie';

  @override
  String get obsPerRunSubtitle => 'Typowy koszt tokenowy jednego uruchomienia';

  @override
  String get obsMedianRunTokens => 'Mediana tokenów na uruchomienie';

  @override
  String get obsMedianRunTokensSub =>
      'Wartość środkowa ze wszystkich uruchomień';

  @override
  String get obsRunsInWorkspace => 'W tym obszarze roboczym';

  @override
  String get obsCostShare => 'Udział w kosztach';

  @override
  String get obsQuotaConfiguredLimits => 'Skonfigurowane limity';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'Użycie względem ustawionych progów, najgorszy status pierwszy.';

  @override
  String get obsQuotaAddLimit => 'Dodaj limit';

  @override
  String get obsQuotaNoLimits =>
      'Nie skonfigurowano jeszcze limitów — dodaj jeden, aby śledzić użycie względem progu.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'Usuń limit: $title';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'Reset za $duration · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'Okna użycia';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'Zaobserwowane użycie u wszystkich dostawców, bez progu.';

  @override
  String get obsQuotaNoUsage => 'Nie zarejestrowano jeszcze użycia.';

  @override
  String get obsQuotaTokensUsed => 'Użyte tokeny';

  @override
  String get obsQuotaRequests => 'Zapytania';

  @override
  String get obsQuotaUnitTokens => 'tokeny';

  @override
  String get obsQuotaUnitRequests => 'zapytania';

  @override
  String get obsQuotaUnitCost => 'koszt';

  @override
  String get obsQuotaAddLimitTitle => 'Dodaj limit';

  @override
  String get obsQuotaProviderLabel => 'Dostawca';

  @override
  String get obsQuotaWindowLabel => 'Okno';

  @override
  String get obsQuotaUnitLabel => 'Jednostka';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'Limit ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'W centach amerykańskich (500 = 5,00 USD).';

  @override
  String get obsQuotaStatusOk => 'OK';

  @override
  String get obsQuotaStatusWarning => 'Ostrzeżenie';

  @override
  String get obsQuotaStatusExhausted => 'Wyczerpany';

  @override
  String get obsQuotaStatusUnknown => 'Nieznany';

  @override
  String get obsGoalNoActiveTitle => 'Brak aktywnego celu';

  @override
  String get obsGoalNoActiveBody =>
      'Ustaw cel, aby dać agentom zadanie i opcjonalny budżet tokenowy. Gdy uruchomienia się kończą, budżet się wypełnia, a gdy jest prawie wyczerpany, agenci dostają sygnał do domykania.';

  @override
  String get obsGoalSetGoal => 'Ustaw cel';

  @override
  String get obsGoalTokenBudget => 'Budżet tokenowy';

  @override
  String obsGoalTokensLeft(String tokens) {
    return 'Pozostało: $tokens';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (bez ustawionego budżetu)';
  }

  @override
  String get obsGoalTokensUsed => 'Użyte tokeny';

  @override
  String get obsGoalElapsed => 'Upłynęło';

  @override
  String get obsGoalWrapUp => 'Domykaj';

  @override
  String get obsGoalClear => 'Wyczyść cel';

  @override
  String get obsGoalFallbackTitle => 'Cel';

  @override
  String get obsGoalSubtitle => 'Budżet trybu celu';

  @override
  String get obsGoalStatusActive => 'Aktywny';

  @override
  String get obsGoalStatusPaused => 'Wstrzymany';

  @override
  String get obsGoalStatusBudgetLimited => 'Ograniczony budżetem';

  @override
  String get obsGoalStatusComplete => 'Zakończony';

  @override
  String get obsGoalStatusDropped => 'Porzucony';

  @override
  String get obsGoalObjectiveLabel => 'Zadanie';

  @override
  String get obsGoalBudgetLabel => 'Budżet tokenowy (opcjonalnie)';

  @override
  String get obsGoalSetAction => 'Ustaw cel';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => 'Skuteczność %';

  @override
  String get obsBenchmarkPassed => 'Zdane';

  @override
  String get obsBenchmarkFailed => 'Niezdane';

  @override
  String get obsBenchmarkErrors => 'Błędy';

  @override
  String get obsBenchmarkSpend => 'Wydatki';

  @override
  String get obsBenchmarkCostPerTask => 'Koszt / zadanie';

  @override
  String get obsBenchmarkTrials => 'Próby';

  @override
  String get obsBenchmarkNoTrials => 'Brak uruchomień do oceny.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'i jeszcze $count',
      many: 'i jeszcze $count',
      few: 'i jeszcze $count',
      one: 'i jeszcze $count',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'Sukces';

  @override
  String get obsBenchmarkTrialFail => 'Porażka';

  @override
  String get obsBenchmarkTrialError => 'Błąd';

  @override
  String get obsBenchmarkTrialRunning => 'W trakcie';

  @override
  String get obsBenchmarkReward => 'Nagroda';

  @override
  String get obsBenchmarkReport => 'Raport';

  @override
  String get obsBenchmarkCopyMarkdown => 'Skopiuj markdown';

  @override
  String get obsBenchmarkCopied => 'Skopiowano raport do schowka';

  @override
  String get obsBehaviorCaption =>
      'To sygnały frustracji wyłuskane z Twoich własnych wiadomości — odczyt kondycji rozmowy, nie punktacja agentów. Liczone lokalnie; nic nie opuszcza tego urządzenia.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'Przeanalizowane wiadomości';

  @override
  String get obsBehaviorTotalSignals => 'Sygnały łącznie';

  @override
  String get obsBehaviorYelling => 'Krzyczenie';

  @override
  String get obsBehaviorProfanity => 'Wulgaryzmy';

  @override
  String get obsBehaviorAnguish => 'Rozpacz';

  @override
  String get obsBehaviorNegation => 'Negacja';

  @override
  String get obsBehaviorRepetition => 'Powtórzenia';

  @override
  String get obsBehaviorBlame => 'Zrzucanie winy';

  @override
  String get obsBehaviorConversationsTitle =>
      'Najbardziej sfrustrowane rozmowy';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'Uszeregowane według gęstości sygnałów w Twoich wiadomościach.';

  @override
  String get obsBehaviorNoSignals =>
      'Nie wykryto sygnałów frustracji — spokojne wody.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return 'Przeanalizowane wiadomości: $count';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return 'Sygnały: $count';
  }

  @override
  String get obsAgentStatusIdle => 'Bezczynny';

  @override
  String get obsAgentStatusParked => 'Zaparkowany';

  @override
  String get obsAgentStatusAborted => 'Przerwany';

  @override
  String get obsAgentKindSub => 'Pod';

  @override
  String get noChecksOnCommit =>
      'Na tym commicie nie uruchomiono jeszcze żadnych sprawdzeń.';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'W trakcie — $count zadania',
      many: 'W trakcie — $count zadań',
      few: 'W trakcie — $count zadania',
      one: 'W trakcie — $count zadanie',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wszystkie sprawdzenia zakończone — $count zadania',
      many: 'Wszystkie sprawdzenia zakończone — $count zadań',
      few: 'Wszystkie sprawdzenia zakończone — $count zadania',
      one: 'Wszystkie sprawdzenia zakończone — $count zadanie',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zakończono — $count zadania',
      many: 'Zakończono — $count zadań',
      few: 'Zakończono — $count zadania',
      one: 'Zakończono — $count zadanie',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total zadania',
      many: '$total zadań',
      few: '$total zadań',
      one: '$total zadania',
    );
    return 'Niepowodzenia: $failed z $_temp0';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zadania',
      many: '$count zadań',
      few: '$count zadania',
      one: '$count zadanie',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'Macierz: $jobId';
  }

  @override
  String get jobLogsPending => 'Logi pojawią się tu po zakończeniu zadania.';

  @override
  String get jobLogsUnavailable => 'Logi nie są dostępne dla tego zadania.';

  @override
  String get noLogsForStep => 'Nie zarejestrowano logów dla tego kroku.';

  @override
  String get jobLogsTruncated =>
      'Log przycięty — pokazujemy najnowsze dane wyjściowe.';

  @override
  String get fullLog => 'Pełny log';

  @override
  String get copyLogs => 'Skopiuj logi';

  @override
  String get resizeGraph => 'Przeciągnij, aby zmienić rozmiar wykresu';

  @override
  String workflowRunStartedAgo(String time) {
    return 'Rozpoczęto $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'Zakończono $time';
  }

  @override
  String get chatBridgesTitle => 'Mostki czatu';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'Oznacz bota w $provider, aby zlecić agentowi coś do zrobienia, albo twórz zgłoszenia poleceniem $command.';
  }

  @override
  String chatConnectProvider(String provider) {
    return 'Połącz $provider';
  }

  @override
  String get chatDisconnectProvider => 'Rozłącz';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName w $teamName';
  }

  @override
  String get chatStateLive => 'Na żywo';

  @override
  String get chatStateConnecting => 'Łączenie…';

  @override
  String get chatStateError => 'Błąd połączenia';

  @override
  String get chatNotConnected => 'Nie połączono';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'Strumieniowanie na żywo jest wyłączone dla tej aplikacji $provider — odpowiedzi przychodzą jako jedna wiadomość.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'Tylko administrator może połączyć $provider dla tego obszaru roboczego.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'Utwórz aplikację $provider, a następnie wklej tu jej dane uwierzytelniające. Control Center łączy się z $provider samodzielnie, więc ten serwer nie potrzebuje publicznego adresu.';
  }

  @override
  String chatOpenConsole(String provider) {
    return 'Otwórz konsolę $provider';
  }

  @override
  String get chatOpenSetupGuide => 'Przewodnik konfiguracji';

  @override
  String get chatFieldBotToken => 'Token bota';

  @override
  String get chatFieldAppToken => 'Token na poziomie aplikacji';

  @override
  String get chatFieldConfigRefreshToken => 'Token konfiguracji aplikacji';

  @override
  String chatFieldOptional(String label) {
    return '$label (opcjonalnie)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'Połącz moje konto $provider';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'Połącz swoje konto $provider, aby wiadomości wysłane tam były przypisywane do Ciebie.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'Połączono z $externalUserId';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'Połącz swoje konto $provider';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'Wyślij to polecenie do bota w $provider. Działa jednorazowo i wygasa po 15 minutach.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'Twoje konto $provider jest teraz połączone — wiadomości wysyłane tam są przypisywane do Ciebie.';
  }

  @override
  String get chatLinkedAccounts => 'Połączone konta';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'Nikt jeszcze nie połączył swojego konta $provider.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count połączonego konta',
      many: '$count połączonych kont',
      few: '$count połączone konta',
      one: '$count połączone konto',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · dopasowano po e-mailu';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · połączono kodem';
  }

  @override
  String get chatUnlink => 'Odłącz';

  @override
  String get chatCustomizeBot => 'Dostosuj bota';

  @override
  String get chatCustomizeBotDescription =>
      'Zmień nazwę bota, to, co mówi o sobie, albo nazwę polecenia z ukośnikiem.';

  @override
  String get chatCustomizeBotUnavailable =>
      'Do edycji bota Control Center potrzebuje tokenu konfiguracji aplikacji. Połącz się ponownie i dołącz taki token.';

  @override
  String chatCreateAppTitle(String provider) {
    return 'Utwórz aplikację $provider';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center może utworzyć dla Ciebie aplikację $provider z odpowiednimi uprawnieniami i zdarzeniami. Wykończysz proces w $provider, a potem wklejysz tu dane uwierzytelniające.';
  }

  @override
  String get chatCreateApp => 'Utwórz aplikację';

  @override
  String get chatCreateAppCta => 'Utwórz aplikację za mnie';

  @override
  String get chatAppNameLabel => 'Nazwa aplikacji';

  @override
  String get chatBotDisplayNameLabel =>
      'Nazwa bota (co członkowie wpisują po @)';

  @override
  String get chatDescriptionLabel => 'Krótki opis';

  @override
  String get chatAgentDescriptionLabel => 'Co bot mówi, że potrafi';

  @override
  String get chatCommandLabel => 'Polecenie z ukośnikiem';

  @override
  String get chatDirectMessages => 'Wiadomości prywatne';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'Pozwala członkom rozmawiać z botem w prywatnej wiadomości. Może wymagać płatnego planu $provider.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$provider utworzył aplikację $appId.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'Zostało kilka kroków, które potrafi wykonać tylko $provider:';
  }

  @override
  String get chatStepAppToken => 'Wygeneruj token na poziomie aplikacji';

  @override
  String get chatStepInstall => 'Zainstaluj aplikację';

  @override
  String get chatOpenAppSettings => 'Otwórz ustawienia aplikacji';

  @override
  String get chatContinueToCredentials => 'Wklej dane uwierzytelniające';

  @override
  String chatBotUpdated(String provider) {
    return 'Zaktualizowano bota w $provider.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$provider zmienił uprawnienia aplikacji. Zainstaluj ją ponownie, aby zaczęły obowiązywać.';
  }

  @override
  String get chatReinstallApp => 'Zainstaluj ponownie';

  @override
  String chatIconNotEditable(String provider) {
    return 'Ikona bota może być zmieniona tylko w ustawieniach aplikacji $provider.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'Możesz też utworzyć ją samodzielnie w $provider — bez tokenu. Ustawienia powyżej podróżują z linkiem.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'Utwórz w $provider';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '$provider otworzył się w przeglądarce z wypełnioną wcześniej konfiguracją. Utwórz aplikację tam, dokończ te kroki i wróć z tokenami.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider nie zgłasza, którą aplikację utworzył, więc dostosowanie bota stąd będzie później wymagać tokenu konfiguracji aplikacji.';
  }

  @override
  String get chatStepCreateApp =>
      'Utwórz aplikację z przygotowanej konfiguracji';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'Wybierz obszar roboczy w $provider i potwierdź.';
  }

  @override
  String get chatStepAppTokenHint =>
      'Podstawowe informacje → tokeny na poziomie aplikacji, z zakresem connections:write.';

  @override
  String get chatStepInstallHint =>
      'Zainstaluj aplikację → skopiuj token OAuth użytkownika bota.';

  @override
  String get calendarUseBuiltinApp => 'Użyj aplikacji Google od Control Center';

  @override
  String get calendarUseBuiltinAppHint =>
      'Zatwierdź kontem Google. Nic nie trzeba konfigurować w Google Cloud.';

  @override
  String get calendarUseOwnClient =>
      'Użyj mojego własnego klienta Google Cloud';

  @override
  String get calendarUseOwnClientHint =>
      'Wprowadź klienta OAuth z własnego projektu Google Cloud.';

  @override
  String get aboutTitle => 'O aplikacji';

  @override
  String get aboutAppVersion => 'Wersja aplikacji';

  @override
  String get aboutServerVersion => 'Połączony serwer';

  @override
  String get aboutRpcCatalog => 'Katalog RPC';

  @override
  String get aboutServerUnknown => 'Nie zgłoszono';

  @override
  String get serverStaleTitle =>
      'Serwer z pakietu jest starszy niż ta aplikacja';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'Uruchomiony cc_server ma wersję $serverVersion, a ta aplikacja — $appVersion. Uruchom aplikację ponownie, aby podniosła najnowszy serwer z pakietu; w developmencie przebuduj go poleceniem `dart build cli` w apps/cc_server.';
  }

  @override
  String get updateCheckButton => 'Sprawdź aktualizacje';

  @override
  String get updateChecking => 'Sprawdzanie aktualizacji…';

  @override
  String get updateUpToDate => 'Masz najnowszą wersję';

  @override
  String get updateDeferredBusy =>
      'Aktualizacja jest gotowa, ale trwa nagrywanie spotkania — przypomnimy po jego zakończeniu.';

  @override
  String get updateOpenedReleasesPage =>
      'Otwarto stronę wydawanych wersji w przeglądarce.';

  @override
  String get updateCheckFailed => 'Nie udało się sprawdzić aktualizacji';

  @override
  String updateAvailableVersion(String version) {
    return 'Dostępna jest wersja $version.';
  }

  @override
  String get updateBannerTitle => 'Dostępna jest nowa wersja Control Center';

  @override
  String get updateBannerRefresh => 'Odśwież';

  @override
  String get updateBlockedRecording =>
      'Odświeżanie jest wstrzymane podczas nagrywania spotkania — strona przeładuje się po jego zakończeniu.';

  @override
  String get settingsScopeYou => 'Ty';

  @override
  String get settingsScopeWorkspace => 'Obszar roboczy';

  @override
  String get settingsScopeServer => 'Serwer';

  @override
  String get settingsProfile => 'Profil i tożsamość';

  @override
  String get settingsYourDevices => 'Twoje urządzenia';

  @override
  String get settingsWorkspaceGeneral => 'Ogólne';

  @override
  String get settingsServerConnection => 'Połączenie i status';

  @override
  String get settingsModelProviders => 'Dostawcy modeli';

  @override
  String get settingsVoiceModels => 'Modele głosu i spotkań';

  @override
  String get settingsDiagnostics => 'Diagnostyka i prywatność';

  @override
  String get settingsAbout => 'O aplikacji';

  @override
  String get settingsScopeBadgeYou => 'TY';

  @override
  String get settingsScopeBadgeDevice => 'TO URZĄDZENIE';

  @override
  String get settingsScopeBadgeWorkspace => 'OBSZAR ROBOCZY';

  @override
  String get settingsScopeBadgeServer => 'SERWER';

  @override
  String get settingsProfileDescription =>
      'Twoje imię, e-mail i tożsamość gita odbijana na tworzonych dla Ciebie commitach.';

  @override
  String get settingsServerConnectionDescription =>
      'Z jakim serwerem rozmawia ten klient i jak serwer jest udostępniany (mDNS, tunele, relay).';

  @override
  String get settingsAboutDescription => 'Tożsamość builda i aktualizacje.';

  @override
  String get settingsDiagnosticsDescription =>
      'Izolacja, indeksowanie, synchronizacja, logowanie i zgłaszanie awarii dla tej instalacji.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'Tożsamość, zasady i konwencje wspólne dla wszystkich w tym obszarze roboczym.';

  @override
  String get settingsWorkspacePolicyLabel => 'Zasady obszaru roboczego';

  @override
  String get settingsWorkspacePolicyDescription =>
      'Dotyczy każdego członka i każdego agenta w tym obszarze roboczym.';

  @override
  String get settingsSecretGlobsLabel => 'Wykluczenia ścieżek sekretów';

  @override
  String get settingsSecretGlobsHelp =>
      'Jeden wzorzec na wiersz. Te ścieżki są ukrywane przed przeglądającymi i gośćmi na powierzchniach z kodem, ponad wbudowane domyślne wykluczenia.';

  @override
  String get settingsReviewConcurrencyLabel => 'Rozrzut recenzji';

  @override
  String get settingsReviewConcurrencyHelp =>
      'Ilu recenzentów jest wysyłanych równolegle, gdy nie podano jawnej liczby.';

  @override
  String get settingsReviewLevelLabel => 'Poziom recenzji';

  @override
  String get settingsReviewLevelHelp =>
      'Jak głęboko sięga recenzja AI i ile z tego, co znajdzie, jest raportowane od razu. Nic nie jest odrzucane — lżejszy poziom grupuje drobne ustalenia zamiast je gubić.';

  @override
  String get reviewLevelLight => 'Lekki';

  @override
  String get reviewLevelBalanced => 'Zrównoważony';

  @override
  String get reviewLevelThorough => 'Dokładny';

  @override
  String get reviewLevelLightHint =>
      'Jeden recenzent. Od razu raportowane jest tylko to, co ma realne znaczenie.';

  @override
  String get reviewLevelBalancedHint =>
      'Trzej recenzenci obejmujący QA, architekturę i implementację.';

  @override
  String get reviewLevelThoroughHint =>
      'Dodaje specjalistów od bezpieczeństwa i wydajności oraz raportuje wszystko, co znajdzie.';

  @override
  String get askAiReviewAtLevel => 'Recenzuj na innym poziomie';

  @override
  String reviewNitpicksGroup(int count) {
    return 'Drobiazgi ($count)';
  }

  @override
  String get reviewFindingResolve => 'Naprawione';

  @override
  String get reviewFindingResolveHint =>
      'Oznacz to ustalenie jako naprawione. Przestanie liczyć się na niekorzyść recenzji.';

  @override
  String get reviewFindingDismiss => 'Odrzuć';

  @override
  String get reviewFindingDismissHint =>
      'To nie jest prawdziwy problem. Recenzenci przestaną oznaczać ten wzorzec w przyszłych PR-ach.';

  @override
  String get reviewFindingReopen => 'Otwórz ponownie';

  @override
  String get reviewFindingStatusUndoLabel => 'Status ustalenia';

  @override
  String get reviewFindingDismissTitle => 'Odrzuć to ustalenie';

  @override
  String get reviewFindingDismissReasonHint =>
      'Dlaczego to nie pasuje? Recenzenci to przeczytają.';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'Nie udało się zaktualizować ustalenia: $error';
  }

  @override
  String get reviewStaleTitle => 'Ta recenzja jest nieaktualna';

  @override
  String get reviewStaleBody =>
      'Pull request poszedł dalej, odkąd ta recenzja działała. Ustalenia mogą wskazywać kod, którego już nie ma.';

  @override
  String reviewStaleReviewedAt(String sha) {
    return 'Zrecenzowano przy $sha';
  }

  @override
  String get reviewStaleRerun => 'Zrecenzuj ponownie';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return 'Nieaktualna recenzja w #$prNumber';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return '$title ma nowe commity od ostatniej recenzji.';
  }

  @override
  String get reviewCategorySecurity => 'Bezpieczeństwo';

  @override
  String get reviewCategoryStability => 'Stabilność';

  @override
  String get reviewCategoryDataIntegrity => 'Integralność danych';

  @override
  String get reviewCategoryCorrectness => 'Poprawność';

  @override
  String get reviewCategoryPerformance => 'Wydajność';

  @override
  String get reviewCategoryMaintainability => 'Utrzymywalność';

  @override
  String get reviewEffortQuickWin => 'Szybka wygrana';

  @override
  String get reviewEffortModerate => 'Umiarkowany';

  @override
  String get reviewEffortHeavyLift => 'Duża przebudowa';

  @override
  String get reviewProposedFix => 'Proponowana poprawka';

  @override
  String get reviewAiAgentPrompt => 'Prompt dla agentów AI';

  @override
  String get reviewCopyAiPrompt => 'Skopiuj prompt';

  @override
  String get settingsWorkspaceAdminOnly =>
      'Tylko administratorzy obszaru roboczego mogą to zmieniać.';

  @override
  String get chatMyAccountsTitle => 'Połączone konta czatu';

  @override
  String get settingsServerSso => 'Logowanie jednokrotne';

  @override
  String get settingsServerSsoDescription =>
      'Logowanie SAML i OpenID Connect z provisioningiem użytkowników';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription =>
      'Użytkownicy mogą logować się tym dostawcą';

  @override
  String get ssoEnabledDescriptionOn =>
      'Logowanie jest aktywne dla tego dostawcy';

  @override
  String get ssoIdpMetadataLabel => 'XML metadanych IdP';

  @override
  String get ssoIdpMetadataHint =>
      'wklej XML EntityDescriptor dostawcy tożsamości';

  @override
  String get ssoEmailAttributeLabel => 'Atrybut e-maila';

  @override
  String get ssoDisplayNameAttributeLabel => 'Atrybut nazwy wyświetlanej';

  @override
  String get ssoGroupsAttributeLabel => 'Atrybut grup';

  @override
  String get ssoIssuerLabel => 'Adres URL wystawcy';

  @override
  String get ssoClientIdLabel => 'Identyfikator klienta';

  @override
  String get ssoGroupsClaimLabel => 'Claim grup';

  @override
  String get ssoAutoMemberLabel =>
      'Dodawaj użytkowników do każdego obszaru roboczego przy pierwszym logowaniu';

  @override
  String get ssoAutoMemberDescription =>
      'Wyłącz, by każdy obszar roboczy wymagał zaproszenia';

  @override
  String get ssoAllowJitLabel =>
      'Zakładaj konta nieznanym użytkownikom przy pierwszym logowaniu';

  @override
  String get ssoAllowJitDescription =>
      'Wyłącz, aby odrzucać użytkowników bez istniejącego konta';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'Akceptuj niezainicjowane przez nas logowanie (IdP-initiated)';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'Wyłącznie dla portali IdP uruchamiających aplikacje bezpośrednio';

  @override
  String get ssoWantResponseSignedLabel =>
      'Wymagaj podpisanej koperty odpowiedzi';

  @override
  String get ssoWantResponseSignedDescription =>
      'Podpisy asercji są zawsze wymagane';

  @override
  String get ssoTestConnectionButton => 'Przetestuj połączenie';

  @override
  String get ssoTestConnectionOk => 'Połączenie działa:';

  @override
  String get ssoCopySpMetadata => 'Skopiuj metadane SP';

  @override
  String get ssoCopySpMetadataDone => 'Skopiowano metadane SP do schowka';

  @override
  String get ssoSavedToast => 'Zapisano ustawienia logowania jednokrotnego';

  @override
  String get ssoUnavailable =>
      'Ten serwer nie udostępnia ustawień logowania jednokrotnego. Zaktualizuj binarkę serwera i spróbuj ponownie.';

  @override
  String get ssoScimCardTitle => 'Provisioning użytkowników (SCIM)';

  @override
  String get ssoScimDescription =>
      'Skieruj łącznik SCIM swojego dostawcy tożsamości na poniższy punkt końcowy z tokenem bearer. Deprovisioning odwołuje sesje i dostęp do obszarów roboczych w kilka sekund. Serwer musi być osiągalny dla IdP (tunel lub publiczny adres URL).';

  @override
  String get ssoScimEndpoint => 'Punkt końcowy SCIM';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'Najpierw ustaw publiczny adres URL serwera lub włącz tunel';

  @override
  String get ssoScimRegenerate => 'Wygeneruj token ponownie';

  @override
  String get ssoScimRegenerateConfirm =>
      'Wygenerować nowy token bearer SCIM? Poprzedni token natychmiast przestanie działać.';

  @override
  String get ssoScimTokenTitle => 'Token bearer';

  @override
  String get ssoScimTokenPresent => 'Token jest skonfigurowany';

  @override
  String get ssoScimTokenAbsent =>
      'Nie ma jeszcze tokenu — wygeneruj go, aby włączyć SCIM';

  @override
  String get ssoScimTokenOnce => 'Token SCIM (wyświetlany raz)';

  @override
  String ssoSignInWith(String provider) {
    return 'Zaloguj się przez $provider';
  }

  @override
  String get ssoProbeFailed =>
      'Nie udało się dotrzeć do tego serwera w celu logowania jednokrotnego';

  @override
  String get ssoOpensBrowser => 'Otwiera przeglądarkę, aby dokończyć logowanie';

  @override
  String get ssoWaitingForBrowser =>
      'Czekamy, aż przeglądarka dokończy logowanie…';

  @override
  String get ssoBrowserOpenFailed =>
      'Nie udało się otworzyć przeglądarki do logowania jednokrotnego';

  @override
  String get ssoUseManualPairing =>
      'Zaloguj się zaproszeniem albo kluczem parowania';

  @override
  String get ssoHideManualPairing => 'Ukryj parowanie ręczne';

  @override
  String get ssoClientIdHint => 'Klient publiczny (PKCE) — sekret niepotrzebny';

  @override
  String get ssoClientSecretLabel => 'Sekret klienta (opcjonalnie)';

  @override
  String get ssoClientSecretHintUnset =>
      'Potrzebny tylko dla poufnych klientów IdP';

  @override
  String get ssoClientSecretHintSet =>
      'Sekret jest zapisany — zostaw puste, aby go zachować';

  @override
  String get ssoPairingToggle =>
      'Zezwól na parowanie ręczne (kody zaproszeń i klucze parowania)';

  @override
  String get ssoPairingToggleDescription =>
      'Wyłącz, aby dołączenie działało tylko przez logowanie jednokrotne — nowe urządzenia przychodzą przez logowania SSO; istniejące urządzenia działają dalej';

  @override
  String get ssoPairConfirmTitle => 'Połączyć z serwerem?';

  @override
  String ssoPairConfirmBody(String server) {
    return 'Dane logowania dla $server nadeszły, ale żadne logowanie nie zostało rozpoczęte z tej aplikacji. Połączyć się z tym serwerem?';
  }

  @override
  String get ssoPairConfirmConnect => 'Połącz';

  @override
  String get ssoPairConfirmCancel => 'Zignoruj';

  @override
  String get forgeConnections => 'Hosting kodu';

  @override
  String get connect => 'Połącz';

  @override
  String get disconnect => 'Rozłącz';

  @override
  String get notConnected => 'Nie połączono';

  @override
  String get checkingConnection => 'Sprawdzanie połączenia…';

  @override
  String get fromEnvironment => 'ze środowiska';

  @override
  String forgeTokenTitle(String forge) {
    return 'Token $forge';
  }

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAudioDescription =>
      'Mikrofon, dyktowanie, wykrywanie spotkań i wyjście pejzażu dźwiękowego.';

  @override
  String get audioDevicesSection => 'Urządzenia audio';

  @override
  String get voiceInputBehaviorSection => 'Dyktowanie i spotkania';

  @override
  String get audioOutputDeviceTitle => 'Urządzenie wyjściowe';

  @override
  String get audioOutputDefaultHint =>
      'Cały dźwięk aplikacji odtwarzany jest przez systemowe domyślne wyjście.';

  @override
  String get audioOutputGone =>
      'Wybrane urządzenie wyjściowe nie jest już podłączone — do czasu wyboru innego używane jest domyślne systemowe.';

  @override
  String get reviewHubIntroBody =>
      'Agenci analizują diff, mapują obszary zmian i dochodzą do wspólnego werdyktu.';

  @override
  String get reviewHubAlreadyRunning =>
      'Dla tego pull requesta działa już recenzja';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'Od ostatniej recenzji: rozwiązano $resolved · nowych $added · wciąż otwartych $open';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'Poprzednio zrecenzowano przy $sha';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return 'Napraw ustalenia ($count)';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return 'Napraw zaznaczone ($count)';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return 'Skomentuj zaznaczone ($count)';
  }

  @override
  String get webConnectTitle => 'Połącz z Control Center';

  @override
  String get webConnectSubtitle =>
      'Połącz się z działającym cc-serverem przez WebSocket. Twój klucz zostaje na tym urządzeniu.';

  @override
  String get webConnectServerLabel => 'Serwer';

  @override
  String get webConnectDeviceIdLabel => 'Identyfikator urządzenia';

  @override
  String get webConnectPairingKeyLabel => 'Klucz parowania';

  @override
  String get webConnectPairingKeyHint => 'wklej PSK';

  @override
  String get webConnectStayConnected => 'Pozostań połączonym na tym urządzeniu';

  @override
  String get webConnectStayConnectedDetail =>
      'Pozostań połączonym na tym urządzeniu (przechowuje Twój klucz w tej przeglądarce)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'Nie udało się utworzyć obszaru roboczego: $error';
  }

  @override
  String committedRelative(String relative) {
    return 'zcommitowano $relative';
  }

  @override
  String get selectAgents => 'Wybierz agentów';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agenta',
      many: '$count agentów',
      few: '$count agenty',
      one: '$count agent',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => 'Nowa rozmowa';

  @override
  String get untitledConversation => 'Rozmowa bez tytułu';

  @override
  String get conversationTitleOptionalHint =>
      'Opcjonalne — zostaw puste, a model tytułujący nazwie ją automatycznie';

  @override
  String get conversationTitlesSectionTitle => 'Tytuły rozmów';

  @override
  String get conversationTitlesSectionCaption =>
      'Wybierz runnera, który automatycznie nadaje tytuły nowym rozmowom w tym obszarze roboczym. Tytuły pozostają wyłączone, dopóki nie wybierzesz adaptera, i obowiązują każdego członka.';

  @override
  String get conversationTitlesModelLabel => 'Model tytułów';

  @override
  String get conversationTitlesAdapterLabel => 'Adapter';

  @override
  String get conversationTitlesAdapterHint => 'Wyłączone';

  @override
  String get conversationTitlesAdapterOff => 'Wyłączone';

  @override
  String get startThread => 'Rozpocznij wątek';

  @override
  String get deleteSpaceConfirm =>
      'Usunąć tę przestrzeń? Wszystkie wiadomości przepadną.';

  @override
  String threadTabTitle(String title) {
    return 'Wątek: $title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count odpowiedzi',
      many: '$count odpowiedzi',
      few: '$count odpowiedzi',
      one: '$count odpowiedź',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return 'Ostatnia odpowiedź $time';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Zaloguj się przez $provider';
  }

  @override
  String get signInAgain => 'Zaloguj się ponownie';

  @override
  String get signInNotFinished =>
      'Logowanie jeszcze nie wróciło. Dokończ je w przeglądarce i sprawdź ponownie.';

  @override
  String get signedOutTitle => 'Wylogowano Cię';

  @override
  String get signedOutSubtitle =>
      'Twoje połączenie z hostingiem kodu nie jest już ważne — token wygasł albo odebrano mu dostęp. Nic innego się nie zmieniło: zaloguj się ponownie, a wszystko czeka na swoim miejscu.';

  @override
  String get viaServerApp => 'przez aplikację tego serwera';

  @override
  String get ticketing => 'Zgłoszenia';

  @override
  String get ticketingProviderHelp =>
      'Gdzie żyją Twoje zgłoszenia. Opcja lokalna trzyma je w Control Center.';

  @override
  String providerComingSoon(String provider) {
    return '$provider (wkrótce)';
  }

  @override
  String get ticketProviderLocal => 'Lokalnie';

  @override
  String get addKey => 'Dodaj klucz';

  @override
  String get providerApps => 'Aplikacje dostawców';

  @override
  String get providerAppsDescription =>
      'Jak ten serwer uwierzytelnia się jako on sam i przez co loguje się człowiek. Praca w tle — webhooki, odpytywanie, synchronizacja — działa na aplikacji, nigdy na tokenie osoby.';

  @override
  String get providerAppId => 'Identyfikator aplikacji';

  @override
  String get providerPrivateKey => 'Klucz prywatny';

  @override
  String get providerClientId => 'Identyfikator klienta';

  @override
  String get providerClientSecret => 'Sekret klienta';

  @override
  String get providerApiKey => 'Klucz API';

  @override
  String get providerCallbackUrl => 'Adres URL wywołania zwrotnego';

  @override
  String get providerAppFullyConfigured =>
      'Serwer może działać jako on sam, a ludzie mogą się logować.';

  @override
  String get providerAppServerOnly =>
      'Serwer może działać jako on sam. Dodaj identyfikator i sekret klienta, aby ludzie mogli się logować.';

  @override
  String get providerAppSignInOnly =>
      'Ludzie mogą się logować. Praca w tle wraca do ich danych uwierzytelniających.';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'Dane uwierzytelniające działają. Zainstalowano na: $accounts';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return 'Wpisz ten kod na stronie $provider, która właśnie się otworzyła. Został skopiowany do schowka.';
  }

  @override
  String get deviceCodeWaiting => 'Czekamy, aż skończysz w przeglądarce…';

  @override
  String get copyCodeAndOpen => 'Skopiuj kod i otwórz';

  @override
  String get couldNotOpenBrowser =>
      'Nie udało się otworzyć przeglądarki. Skopiuj link i dokończ logowanie samodzielnie.';

  @override
  String get contextUsage => 'Użycie kontekstu';

  @override
  String get contextUsageFull => 'pełne';

  @override
  String get contextUsageTokens => 'tokeny';

  @override
  String get contextSeeMore => 'Zobacz więcej';

  @override
  String get contextSegmentSystemPrompt => 'Prompt systemowy';

  @override
  String get contextSegmentRules => 'Zasady';

  @override
  String get contextSegmentSkills => 'Umiejętności';

  @override
  String get contextSegmentToolDefinitions => 'Definicje narzędzi';

  @override
  String get contextSegmentMcpTools => 'Narzędzia MCP i dynamiczne';

  @override
  String get contextSegmentDeferredTools => 'Narzędzia ładowane na żądanie';

  @override
  String get contextSegmentSubagents => 'Definicje podagentów';

  @override
  String get contextSegmentMemory => 'Pamięć';

  @override
  String get contextSegmentConversation => 'Rozmowa';

  @override
  String get contextExplorerTitle => 'Kontekst';

  @override
  String get contextExplorerEverything => 'Wszystko';

  @override
  String get contextExplorerSelectPart =>
      'Wybierz część, aby obejrzeć jej zawartość';

  @override
  String get contextExplorerUnavailable => 'Rozbicie kontekstu niedostępne';

  @override
  String get contextRetry => 'Spróbuj ponownie';

  @override
  String get settingsFieldOptional => 'Opcjonalne';

  @override
  String get settingsFilterHint => 'Filtruj tę listę';

  @override
  String get settingsValueNotAvailable => 'Jeszcze niedostępne';

  @override
  String get settingsNoEntriesYet => 'Nic tu jeszcze nie ma';

  @override
  String get settingsChangedBadge => 'Zmienione';

  @override
  String get ssoConnectionCardDescription =>
      'Wybierz, jak ludzie logują się do tego serwera, a potem włącz to połączenie.';

  @override
  String get ssoUseSamlForSignIn => 'Użyj SAML do logowania';

  @override
  String get ssoUseOidcForSignIn => 'Użyj OpenID Connect do logowania';

  @override
  String get ssoSaveConnection => 'Zapisz połączenie';

  @override
  String get ssoStateLive => 'Aktywne';

  @override
  String get ssoStateConfiguredOff => 'Skonfigurowane, wyłączone';

  @override
  String get ssoStateOnIncomplete => 'Włączone, niekompletne';

  @override
  String get ssoStateActive => 'Aktywne';

  @override
  String get ssoStateAllowed => 'Dozwolone';

  @override
  String get ssoStateNoToken => 'Brak tokenu';

  @override
  String get ssoSummaryDirectorySync => 'Synchronizacja katalogu';

  @override
  String get ssoSummaryManualPairing => 'Parowanie ręczne';

  @override
  String get ssoNoMethodLiveNote =>
      'Żadna metoda logowania nie jest aktywna. Nowe urządzenia dołączają zaproszeniem albo kluczem parowania, dopóki nie skonfigurujesz połączenia i go nie włączysz.';

  @override
  String get ssoMethodSamlBlurb =>
      'Dla dostawców tożsamości mówiących po SAML 2.0, takich jak Okta, Entra ID czy Google Workspace.';

  @override
  String get ssoMethodOidcBlurb =>
      'Dla dostawców tożsamości mówiących po OpenID Connect. Zwykle prostsze z dwóch do skonfigurowania.';

  @override
  String get ssoGroupIdentityProvider => 'Dostawca tożsamości';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'Skąd pochodzą asercje i jak ten serwer je weryfikuje.';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'Jakemu wystawcy ten serwer ufa i jako jaki klient się uwierzytelnia.';

  @override
  String get ssoSpEntityIdShortLabel => 'Identyfikator encji SP';

  @override
  String get ssoSpEntityIdDescription =>
      'Zostaw puste, a zostanie wygenerowany na podstawie adresu URL serwera.';

  @override
  String get ssoIssuerDescription =>
      'Bazowy adres URL, który serwuje dokument odkrywania dostawcy.';

  @override
  String get ssoSecretStored => 'Zapisany';

  @override
  String get ssoGroupHandoff => 'Czego potrzebuje Twój dostawca tożsamości';

  @override
  String get ssoGroupHandoffDescription =>
      'Wklej to do aplikacji utworzonej u swojego dostawcy.';

  @override
  String get ssoOriginUnknownTitle =>
      'Ten serwer nie zna swojego publicznego adresu URL';

  @override
  String get ssoOriginUnknownBody =>
      'Adresy logowania i wywołania zwrotnego są z niego budowane, więc dostawca nie dotrze do tego serwera, dopóki któryś nie zostanie ustawiony. Dodaj publiczny adres URL lub włącz tunel w Serwer → Połączenie.';

  @override
  String get ssoAcsUrlLabel => 'Adres URL usługi przyjmowania asercji (ACS)';

  @override
  String get ssoAcsUrlDescription =>
      'Gdzie Twój dostawca wysyła podpisaną asercję.';

  @override
  String get ssoSpEntityIdResolvedLabel => 'Identyfikator encji dostawcy usług';

  @override
  String get ssoMetadataUrlLabel => 'Adres URL metadanych SP';

  @override
  String get ssoMetadataUrlDescription =>
      'Dostawcy importujący metadane mogą pobrać je stąd.';

  @override
  String get ssoRedirectUriLabel => 'URI przekierowania';

  @override
  String get ssoRedirectUriDescription =>
      'Dodaj to do dozwolonych URI przekierowań aplikacji Twojego dostawcy.';

  @override
  String get ssoSignInUrlLabel => 'Adres URL logowania';

  @override
  String get ssoSignInUrlDescription =>
      'Wysyłaj ludzi tutaj, aby rozpocząć logowanie jednokrotne.';

  @override
  String get ssoGroupAttributeMapping => 'Mapowanie atrybutów';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'Który claim niesie które pole. Zostaw domyślne, chyba że Twój dostawca zmienia nazwy.';

  @override
  String get ssoGroupAccess => 'Dostęp i role';

  @override
  String get ssoGroupAccessDescription =>
      'Co wolno komuś, kto zaloguje się pomyślnie.';

  @override
  String get ssoDefaultRoleShortLabel => 'Domyślna rola';

  @override
  String get ssoDefaultRoleDescription =>
      'Przypisywana każdemu, czyje grupy nie pasują do żadnego mapowania poniżej.';

  @override
  String get ssoRoleMapShortLabel => 'Mapowanie grup na role';

  @override
  String get ssoRoleMapDescription =>
      'Pierwsza pasująca grupa wygrywa. Roli właściciela nie da się tak przyznać.';

  @override
  String get ssoRoleMapGroupHint => 'Nazwa grupy od Twojego dostawcy';

  @override
  String get ssoRoleMapAdd => 'Dodaj mapowanie';

  @override
  String get ssoRoleMapEmpty => 'Brak mapowań — każdy dostaje domyślną rolę.';

  @override
  String get ssoAdvancedSummary =>
      'Dryf zegara, logowanie inicjowane przez IdP, polityka podpisów';

  @override
  String get ssoClockSkewShortLabel => 'Dryf zegara';

  @override
  String get ssoClockSkewDescription =>
      'Sekundy tolerancji na znacznikach czasu asercji. 90 pasuje większości dostawców.';

  @override
  String get ssoScimGenerate => 'Wygeneruj token';

  @override
  String get ssoScimTokenOnceBody =>
      'Skopiowano do schowka. Wyświetlany jest raz i nie da się go odzyskać, więc wklej go do swojego dostawcy teraz.';

  @override
  String get ssoPairingCardTitle => 'Parowanie ręczne';

  @override
  String get ssoPairingCardDescription =>
      'Inna droga do tego serwera: kody zaproszeń i klucze parowania, dla urządzeń, które nie przechodzą przez logowanie jednokrotne.';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count z $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'Żaden dostawca nie jest połączony, więc wbudowany runtime agentów nie ma na czym działać. Dodaj klucz API albo zaloguj się do jednego z poniższych.';

  @override
  String get providersFilterHint => 'Filtruj dostawców';

  @override
  String get providersNoneMatch => 'Nic nie pasuje do tego filtru';

  @override
  String get providerDeniedHereTitle => 'Zablokowany w tym obszarze roboczym';

  @override
  String get providerDeniedHereBody =>
      'Agenci nie mogą tu używać tego dostawcy, choć jest połączony. Inne obszary robocze nie są dotknięte.';

  @override
  String get providerNeedsSignIn => 'Zaloguj się, aby używać tego dostawcy';

  @override
  String get providerNeedsApiKey => 'Dodaj klucz API, aby używać tego dostawcy';

  @override
  String get providerApiKeyLabel => 'Klucz API';

  @override
  String get providerGenerationDefaults => 'Domyślne ustawienia dostawcy';

  @override
  String get providerNoModelsYet =>
      'Nie zgłoszono jeszcze modeli. Połącz dostawcę, a potem zsynchronizuj.';

  @override
  String get providerModelsFilterHint => 'Filtruj modele';

  @override
  String get adaptersNoneReadyNote =>
      'Na tej maszynie nie znaleziono żadnego skatalogowanego CLI runnera. Zainstaluj jeden, a potem odśwież.';

  @override
  String get adaptersFilterHint => 'Filtruj runnery';

  @override
  String get adaptersLaunchGroup => 'Uruchamianie';

  @override
  String get adaptersLaunchGroupDescription =>
      'Co dostaje ten runner, gdy agent go uruchamia. Możesz ustawić to przed instalacją CLI.';

  @override
  String get adaptersEnvNone => 'Brak';

  @override
  String adaptersEnvCount(int count) {
    return 'Ustawione: $count';
  }

  @override
  String get adapterArgumentsDescription =>
      'Doklejane do wiersza poleceń runnera przy każdym uruchomieniu.';

  @override
  String get defaultChatDescription =>
      'Obsługuje nowe rozmowy i każdego agenta bez własnego runnera.';

  @override
  String get shortTaskDescription =>
      'Obsługuje szybką pracę w tle, jak tytuły i streszczenia. Mniejszy model pasuje tutaj.';

  @override
  String get settingsStateFailed => 'Niepowodzenie';

  @override
  String get providerAppsGroupServer => 'Działanie jako serwer';

  @override
  String get providerAppsGroupServerDescription =>
      'Pozwala pracy w tle sięgać repozytoriów bez człowieka za żądaniem: webhooki, odpytywanie pull requestów, synchronizacja zgłoszeń.';

  @override
  String get providerAppsGroupPrConversations => 'Rozmowy przy pull requestach';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'Jak deweloperzy mogą rozmawiać z tym serwerem wprost na GitHubie. Działa bez webhooka i publicznego adresu URL — serwer odpytuje.';

  @override
  String get providerAppBotLogin => 'Login bota';

  @override
  String get providerAppBotLoginEmpty =>
      'Przetestuj połączenie, aby ustalić login bota.';

  @override
  String get providerAppAskOnGitHub => 'Pytanie na GitHubie';

  @override
  String get providerAppAskOnGitHubHint =>
      'Oznacz powyższy login bota w komentarzu pull requesta — przyrostek [bot] jest opcjonalny — aby poprosić o recenzję lub zadać pytanie, odpowiadaj wewnątrz jego wątków recenzji albo dodaj etykietę `ai-review`, aby poprosić o recenzję.';

  @override
  String get providerAppsGroupSignIn => 'Logowanie ludzi';

  @override
  String get providerAppsGroupSignInDescription =>
      'Pozwala każdemu członkowi połączyć własne konto i dostać własne dane uwierzytelniające.';

  @override
  String get providerAppCapActsAsServer => 'Działa jako serwer';

  @override
  String get providerAppCapSignsIn => 'Loguje ludzi';

  @override
  String get portLabel => 'Port';

  @override
  String get mcpNoTokenWarning =>
      'Bez tokenu wszystko, co dosięgnie tego portu, może wywołać każde narzędzie.';

  @override
  String get mcpBridgedToolsLabel => 'Narzędzia';

  @override
  String get guardrailFamilyFiles => 'Pliki';

  @override
  String get guardrailFamilyGit => 'Git i pull requesty';

  @override
  String get guardrailFamilyMachine => 'Maszyna i sieć';

  @override
  String get guardrailFamilyControl => 'Sekrety i obszar roboczy';

  @override
  String get guardrailScopeFieldLabel => 'Edytowanie reguł dla';

  @override
  String get guardrailScopeFieldDescription =>
      'Węższy zakres wygrywa z szerszym. Reguły ustawione tutaj nakładają się na to, co jest dziedziczone.';

  @override
  String get guardrailSetHere => 'Ustawione tutaj';

  @override
  String get guardrailClearAllHere => 'Wyczyść wszystko';

  @override
  String get sandboxingCardLabel => 'Piaskownica';

  @override
  String get sandboxingCardDescription =>
      'Czy praca agentów działa w izolacji od tego hosta i do czego izolowany agent nadal może sięgnąć.';

  @override
  String get sandboxBackendNoneActive => 'Host, bez izolacji';

  @override
  String get sandboxSummaryHost => 'Host';

  @override
  String get sandboxGroupIsolation => 'Izolacja';

  @override
  String get sandboxGroupIsolationDescription =>
      'Gdzie faktycznie dzieją się procesy agenta i zapisy plików.';

  @override
  String get sandboxBackendFieldDescription =>
      'Tryb auto wybiera najsilniejszy wspierany przez ten host. Przypnij jeden, żeby się pod Tobą nie zmieniał.';

  @override
  String get sandboxCapabilitiesDescription =>
      'Dziury przebite przez granicę. Każda z nich to coś, co izolowany agent nadal może zrobić światu zewnętrznemu.';

  @override
  String get sandboxSummaryInForce => 'Obowiązuje';

  @override
  String get rigsInstallHintLabel => 'Jak to zainstalować';

  @override
  String get rigsStarting => 'Uruchamianie';

  @override
  String get rigsResidentMemory => 'Pamięć rezydentna';

  @override
  String get installedLabel => 'Zainstalowany';

  @override
  String get notInstalledLabel => 'Niezainstalowany';

  @override
  String ssoOtherKindUnsaved(String method) {
    return '$method ma niezapisane zmiany';
  }

  @override
  String get collapseComment => 'Zwiń komentarz';

  @override
  String get expandComment => 'Rozwiń komentarz';

  @override
  String get suggestedChange => 'Proponowana zmiana';

  @override
  String get emptyComment => 'Pusty komentarz';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count odpowiedzi',
      many: '$count odpowiedzi',
      few: '$count odpowiedzi',
      one: '$count odpowiedź',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => 'Recenzja w toku';

  @override
  String failedToResolveConversation(String error) {
    return 'Nie udało się zaktualizować rozmowy: $error';
  }

  @override
  String get addSingleComment => 'Dodaj pojedynczy komentarz';

  @override
  String get addToReview => 'Dodaj do recenzji';

  @override
  String get startAReview => 'Rozpocznij recenzję';

  @override
  String get reviewNeedsABody =>
      'Najpierw napisz podsumowanie albo dodaj do kolejki komentarz w linii';

  @override
  String get reviewSubmitted => 'Recenzja wysłana';

  @override
  String get finishYourReview => 'Zakończ recenzję';

  @override
  String get commentVerdict => 'Komentarz';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oczekującego komentarza',
      many: '$count oczekujących komentarzy',
      few: '$count oczekujące komentarze',
      one: '$count oczekujący komentarz',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 'i jeszcze $count';
  }

  @override
  String get queuedCommentHint =>
      'Ten komentarz wyjdzie, gdy wyślesz recenzję.';

  @override
  String commentOnLinesRange(int start, int end) {
    return 'Wiersze $start do $end';
  }

  @override
  String get claudeAccountsTitle => 'Konta Claude Code';

  @override
  String get claudeAccountsDescription =>
      'Każde konto to osobne logowanie Claude Code. Uruchomienia używają kont podpiętych poniżej, w tej kolejności.';

  @override
  String get claudeAccountsEmpty => 'Nie ma jeszcze kont';

  @override
  String get claudeAccountAdd => 'Dodaj konto';

  @override
  String get claudeAccountSignIn => 'Zaloguj się';

  @override
  String get claudeAccountSignInAgain => 'Zaloguj się ponownie';

  @override
  String get claudeAccountSignInHint =>
      'Uruchom to w terminalu na serwerze. Otwiera przeglądarkę, aby dokończyć logowanie, i zapisuje dane uwierzytelniające w katalogu tego konta.';

  @override
  String get claudeAccountSignedOut => 'Wylogowano';

  @override
  String get claudeAccountExpired => 'Logowanie wygasło';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'Logowanie wygasło $when. Zaloguj się ponownie, aby używać tego konta.';
  }

  @override
  String get claudeAccountMakeDefault => 'Ustaw jako domyślne';

  @override
  String get claudeAccountDefault => 'Domyślne';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return 'Usunąć $label?';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'To wylogowuje konto i usuwa jego katalog na serwerze. Samo logowanie nie jest dotknięte.';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'Nie udało się sprawdzić tego konta: $error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return 'wykorzystano $percent%';
  }

  @override
  String get accountPoolStrategy => 'Rotacja';

  @override
  String get accountPoolPinned => 'Przypięte';

  @override
  String get accountPoolRoundRobin => 'Round robin';

  @override
  String get accountPoolSerial => 'Jedno naraz';

  @override
  String get accountPoolPinnedHint =>
      'Zawsze zaczynaj od pierwszego konta. Pozostałe zostają jako zapas, jeśli ono zawiedzie.';

  @override
  String get accountPoolRoundRobinHint =>
      'Rozkładaj uruchomienia po kontach, za każdym wysłaniem przechodząc do następnego.';

  @override
  String get accountPoolSerialHint =>
      'Wyczerp pierwsze konto, zanim sięgniesz po następne.';

  @override
  String get accountPoolMoveUp => 'Przenieś w górę';

  @override
  String get accountPoolMoveDown => 'Przenieś w dół';

  @override
  String get accountPoolUsingAll =>
      'Nic jeszcze nie podpięto — używane jest każde konto, w tej kolejności.';

  @override
  String get accountPoolInheriting => 'Dziedziczenie kont obszaru roboczego.';

  @override
  String get accountPoolResetToWorkspace => 'Przywróć konta obszaru roboczego';

  @override
  String accountPoolCoolingOff(String when) {
    return 'poza limitem do $when';
  }

  @override
  String get accountPoolSignedOut => 'wylogowane';

  @override
  String get accountPoolExpired => 'logowanie wygasło';

  @override
  String accountPoolLoadFailed(String error) {
    return 'Nie udało się wczytać rotacji: $error';
  }

  @override
  String get providerSignedInAccount => 'zalogowane konto';

  @override
  String get agentAccountsTab => 'Konta';

  @override
  String get agentClaudeAccountsNoticeTitle => 'Wiele kont Claude Code';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return 'Ten runner loguje się jako jedno z $count kont Claude Code na tym hoście. Wybierz jedno albo rotuj między nimi w karcie Konta.';
  }

  @override
  String get agentAccountsDescription =>
      'Jakich kont używają uruchomienia tego agenta. Każdy blok na początku dziedziczy wybór obszaru roboczego.';

  @override
  String get agentAccountsNothingToRotate =>
      'Nie ma czym rotować — najpierw podłącz drugie konto albo klucz.';

  @override
  String failedToPostReply(String error) {
    return 'Nie udało się wysłać odpowiedzi: $error';
  }

  @override
  String commentOnLine(int line) {
    return 'Wiersz $line';
  }

  @override
  String get viewInDiff => 'Zobacz w diffie';

  @override
  String get subscriptionUsagePreviousAccount => 'Poprzednie konto';

  @override
  String get subscriptionUsageNextAccount => 'Następne konto';

  @override
  String inReplyTo(String path) {
    return 'W odpowiedzi do $path';
  }

  @override
  String get subscriptionUsageNoneReported => 'To konto nie zgłasza użycia.';

  @override
  String get subscriptionUsageCredits => 'Kredyty';

  @override
  String get reviewHubStaticRule => 'Reguła statyczna';

  @override
  String get reviewHubStarted => 'Recenzja rozpoczęta';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'Znalezione przez deterministyczną regułę ($rule) w wierszu, który dodaje ten pull request — nie przez agenta recenzenta.';
  }

  @override
  String get prReviewArtifactTab => 'Recenzja PR';

  @override
  String get prReviewRunning => 'Recenzowanie tego pull requesta…';

  @override
  String get prReviewStarting => 'Rozpoczynanie recenzji…';

  @override
  String get prReviewStartingBody =>
      'Przygotowywanie drzewa roboczego pull requesta. Recenzenci wystartują, gdy tylko będzie gotowe.';

  @override
  String get prReviewFailed => 'Recenzja nie powiodła się.';

  @override
  String get prReviewRerunning => 'Ponowne recenzowanie…';

  @override
  String get prReviewNoOpenFindings => 'Brak otwartych ustaleń';

  @override
  String prReviewOpenFindings(int count) {
    return 'Otwarte ustalenia: $count';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used z $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return 'Komentarze opublikowane jako bot: $posted. Pominięte (brak zakotwiczenia w pliku): $skipped. Niepowodzenia: $failed.';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return 'Ustalenia w liczbie $count dotyczą kodu, którego ten pull request nie zmienia ($files). GitHub przyjmuje komentarze inline tylko w diffie.';
  }

  @override
  String get reviewRailReport => 'Raport';

  @override
  String get reviewNoFindingsTitle => 'Nie ma jeszcze ustaleń recenzji';

  @override
  String get reviewNoFindingsHint =>
      'Ustalenia pojawiają się tu, gdy agenci je publikują.';

  @override
  String reviewShowDismissed(int count) {
    return 'Pokaż odrzucone ($count)';
  }

  @override
  String reviewHideDismissed(int count) {
    return 'Ukryj odrzucone ($count)';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wykryto $count rozbieżności recenzentów',
      many: 'Wykryto $count rozbieżności recenzentów',
      few: 'Wykryto $count rozbieżności recenzentów',
      one: 'Wykryto $count rozbieżność recenzentów',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'Rodzaj';

  @override
  String get reviewFilterStatus => 'Status';

  @override
  String get reviewKindBug => 'Błąd';

  @override
  String get reviewKindSuggestion => 'Sugestia';

  @override
  String get reviewKindRecommendation => 'Rekomendacja';

  @override
  String get reviewKindQuestion => 'Pytanie';

  @override
  String get reviewKindTicket => 'Zgłoszenie';

  @override
  String get archiveSpace => 'Archiwizuj przestrzeń';

  @override
  String get archivedSpaces => 'Zarchiwizowane przestrzenie';

  @override
  String get archivedSpacesEmpty => 'Brak zarchiwizowanych przestrzeni';

  @override
  String get restoreSpace => 'Przywróć';

  @override
  String archivedWhen(String time) {
    return 'Zarchiwizowano $time';
  }

  @override
  String get deleteSpacePermanently => 'Usuń trwale';

  @override
  String get renameSpace => 'Zmień nazwę przestrzeni';

  @override
  String get renameConversation => 'Zmień nazwę rozmowy';

  @override
  String get spaceActions => 'Akcje przestrzeni';

  @override
  String get conversationActions => 'Akcje rozmowy';

  @override
  String get editSpaceRepos => 'Edytuj repozytoria';

  @override
  String get editSpaceReposTitle => 'Repozytoria przestrzeni';

  @override
  String get editSpaceReposWarning =>
      'Dodanie repozytorium wycheckowuje je do tej przestrzeni; usunięcie kasuje jego folder.';

  @override
  String get agentSectionIdentity => 'Tożsamość';

  @override
  String get agentSectionRuntime => 'Runtime';

  @override
  String get agentSectionGuardrails => 'Zabezpieczenia';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count podwładnego',
      many: '$count podwładnych',
      few: '$count podwładnych',
      one: '$count podwładny',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'Filtruj zespoły…';

  @override
  String get teamsSummaryWithLeader => 'Z liderem';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zespołu',
      many: '$count zespołów',
      few: '$count zespoły',
      one: '$count zespół',
      zero: 'Brak zespołów',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return 'Usunięcie $name usuwa jego profil, powiązania umiejętności i historię uruchomień. Tego nie da się cofnąć.';
  }

  @override
  String get resetToDefault => 'Przywróć domyślne';

  @override
  String get newAgent => 'Nowy agent';

  @override
  String get newSkill => 'Nowa umiejętność';

  @override
  String get zoomIn => 'Przybliż';

  @override
  String get zoomOut => 'Oddal';

  @override
  String get resetZoom => 'Resetuj zoom';

  @override
  String get imageHostedOnGitHub => 'Obraz hostowany na GitHubie';

  @override
  String get imageOpenExternally => 'Obraz · otwórz zewnętrznie';

  @override
  String get memoryScopeAll => 'Wszystkie zakresy';

  @override
  String get memoryScopeWorkspace => 'Cały obszar roboczy';

  @override
  String get memoryScopeFilterLabel => 'Filtruj według zakresu';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return 'Zakres: repozytorium $repo';
  }

  @override
  String get toolScreenshot => 'Zrzut ekranu od agenta';

  @override
  String get toolImageUnavailable => 'Obraz niedostępny';

  @override
  String toolImagesUnavailable(int count) {
    return 'Niedostępne obrazy: $count';
  }

  @override
  String get shakeUnavailable => 'Trząsanie nie jest dostępne na tym serwerze';

  @override
  String get shakeNothing =>
      'Nie ma czego strząsać — ostatnie tury są chronione';

  @override
  String shakeDone(int tokens) {
    return 'Zwolniono około $tokens tokenów';
  }

  @override
  String get compactionDivider => 'Skompresowano';

  @override
  String compactionDividerCount(int count) {
    return 'Skompresowano · zwinięto wiadomości: $count';
  }

  @override
  String get composerDropToAttach => 'Upuść, aby załączyć';

  @override
  String get attachmentUnavailable => 'Załącznik niedostępny';

  @override
  String get attachmentUnavailableDetail =>
      'Ten załącznik nie jest już trzymany w pamięci. Załącz go ponownie, aby zobaczyć podgląd.';

  @override
  String get attachmentPreviewFailed => 'Nie udało się otworzyć tego pliku';

  @override
  String get attachmentPreviewUnsupported =>
      'Brak podglądu dla tego typu pliku';

  @override
  String get attachmentTooLargeToPreview => 'Za duży na podgląd';

  @override
  String get attachmentOpenExternally => 'Otwórz w domyślnej aplikacji';

  @override
  String get asideUnavailable =>
      'Ustaw model jednorazowy w ustawieniach obszaru roboczego, aby tego używać';

  @override
  String get asideEmpty => 'Nie ma jeszcze na czym pracować';

  @override
  String get asideFailed => 'Nie udało się uzyskać odpowiedzi';

  @override
  String get handoffTitle => 'Przekazanie';

  @override
  String get asideTitle => 'Pytanie poboczne';

  @override
  String get attachFilesOrDrop => 'Załącz pliki — albo upuść je tutaj';

  @override
  String get guidedGoalTitle => 'Ostrzeż zadanie';

  @override
  String get guidedGoalIntro =>
      'Agent pracujący bez nadzoru musi dokładnie wiedzieć, kiedy skończył. Najpierw kilka pytań.';

  @override
  String get guidedGoalAnswerHint => 'Twoja odpowiedź';

  @override
  String get guidedGoalNext => 'Dalej';

  @override
  String get guidedGoalStart => 'Rozpocznij cel';

  @override
  String get guidedGoalSkip => 'Pomiń i uruchom jak napisano';

  @override
  String guidedGoalStillMissing(String items) {
    return 'Nadal nieokreślone: $items';
  }

  @override
  String get conversationTreeTitle => 'Drzewo rozmowy';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gałęzi',
      many: '$count gałęzi',
      few: '$count gałęzie',
      one: '$count gałąź',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'Kontynuuj stąd';

  @override
  String get conversationTreeFork => 'Rozwidlij do nowej rozmowy';

  @override
  String get conversationTreeCurrent => 'Na tej gałęzi';

  @override
  String get conversationTreeEmpty => 'Nic tu jeszcze nie ma';

  @override
  String get conversationTreeForked => 'Rozwidlono do nowej rozmowy';

  @override
  String get conversationTreeSwitched => 'Trwa kontynuacja od tej wiadomości';

  @override
  String exportSaved(String path) {
    return 'Zapisano w $path';
  }

  @override
  String get exportFailed => 'Nie udało się zapisać eksportu';

  @override
  String get contextCommandNoAgent =>
      'W tej rozmowie nie ma agenta, więc nie ma okna kontekstu do otwarcia';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'W tej rozmowie nie ma agenta o nazwie „$name”. Spróbuj: $names';
  }

  @override
  String get dumpCopied => 'Skopiowano transkrypcję do schowka';

  @override
  String get messageQueueHint => 'Pisz dalej, aby kolejkować kolejne zmiany';

  @override
  String get steerNow => 'Kieruj';

  @override
  String get steeringQueueLabel => 'Zakolejkowane wiadomości sterujące';

  @override
  String get steeringDeliverUnavailable =>
      'Żaden działający agent nie może tego teraz przyjąć — zostaje w kolejce.';

  @override
  String get reorderSteeringCard => 'Zmień kolejność zakolejkowanej wiadomości';

  @override
  String get editSteeringCard => 'Edytuj zakolejkowaną wiadomość';

  @override
  String get deleteSteeringCard => 'Usuń zakolejkowaną wiadomość';

  @override
  String get steeringBadge => 'Sterowane';

  @override
  String get settingsSandboxLabel => 'Piaskownica';

  @override
  String get sandboxExecGrantsTitle => 'Zezwolenia na wykonywanie';

  @override
  String get sandboxExecGrantsSubtitle =>
      'Programy, które agenci mogą uruchamiać ze swojej roboczej kopii Twoich repozytoriów. Każdy wpis został zatwierdzony przez Ciebie, gdy piaskownica zapytała.';

  @override
  String get sandboxExecGrantsEmpty =>
      'Nie zarejestrowano jeszcze decyzji. Zapytamy Cię przy pierwszym razem, gdy agent będzie musiał uruchomić program ze swojej roboczej kopii.';

  @override
  String get sandboxExecGrantRevoke => 'Odwołaj';

  @override
  String get sandboxExecGrantAllowed => 'Dozwolone';

  @override
  String get sandboxExecGrantBlocked => 'Zablokowane';

  @override
  String get sandboxExecGrantRevokeConfirmTitle => 'Odwołać tę decyzję?';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'Zapytamy Cię ponownie, gdy agent następnym razem będzie musiał uruchomić program z tej kopii.';

  @override
  String get repoScriptsTest => 'Test';

  @override
  String get repoScriptsTestTooltip =>
      'Uruchom ten szkic w jednorazowym klonie repozytorium';

  @override
  String get repoScriptsRunKindTest => 'Test';

  @override
  String get demoBadgeLabel => 'Demo';

  @override
  String get demoFilePickerTitle => 'Pliki demo';

  @override
  String get demoFilePickerBody =>
      'Demo udaje przesyłanie plików: wybierz dowolny, a zostanie załączony do wiadomości bez dotykania dysku.';

  @override
  String get demoFilePickerAttach => 'Załącz';

  @override
  String get demoReadOnlySave => 'Tylko do odczytu w demo';

  @override
  String get demoBadgeTooltip =>
      'Zwiedzasz demo. Dane są fikcyjne, a agenci działają według scenariusza.';

  @override
  String get demoFirstRunTitle => 'Jesteś w demo na żywo';

  @override
  String demoFirstRunBody(int minutes) {
    return 'To prawdziwa aplikacja działająca na prawdziwym kodzie — wymyślone są tylko dane. Agenci streamują autentyczne uruchomienia ze skryptu, więc nic nie dociera do modelu i nic nie działa na maszynie. Twój obszar roboczy jest tylko Twój i znika po $minutes min.';
  }

  @override
  String get demoFirstRunDismiss => 'Rozumiem';

  @override
  String get demoTourTitle => 'Od czego zacząć';

  @override
  String get demoTourSubtitle =>
      'Cztery miejsca, które pokazują, co aplikacja naprawdę robi.';

  @override
  String get demoTourSkip => 'Pomiń';

  @override
  String get demoTourStarRepo => 'Daj gwiazdkę na GitHubie';

  @override
  String get demoTourOpen => 'Otwórz';

  @override
  String get demoTourSpacesTitle => 'Porozmawiaj z agentem';

  @override
  String get demoTourSpacesBody =>
      'Wyślij wiadomość w przestrzeni i patrz, jak napływa uruchomienie — myślenie, wywołania narzędzi i koszt, dokładnie tak jak renderuje się prawdziwe.';

  @override
  String get demoTourReviewTitle => 'Zrecenzuj pull request';

  @override
  String get demoTourReviewBody =>
      'Otwórz #412. Zostaw komentarz inline albo wyślij recenzję; Twoje słowa wylądują w wątku i tam zostaną.';

  @override
  String get demoTourTicketsTitle => 'Śledź pracę';

  @override
  String get demoTourTicketsBody =>
      'Zgłoszenia, zadania i plany są powiązane z tymi samymi rozmowami, które toczą agenci.';

  @override
  String get demoTourInboxTitle => 'Zobacz całą operację';

  @override
  String get demoTourInboxBody =>
      'Każdy alarm z każdego filaru ląduje w jednej skrzynce — recenzje, zgłoszenia, uruchomienia i spotkania.';

  @override
  String get demoUnavailableTitle => 'Niedostępne w demo';

  @override
  String get demoUnavailableTerminal =>
      'Terminal uruchamia prawdziwą powłokę na hoście serwera. Demo nie ma w ogóle powierzchni wykonania — właśnie dlatego można je bezpiecznie udostępnić publicznie.';

  @override
  String get demoUnavailableRig =>
      'Klatka to jednorazowa maszyna wirtualna, którą prowadzi agent. Demo nie uruchamia żadnej: publiczny punkt końcowy, który potrafi wystartować VM, to nie demo.';

  @override
  String get demoUnavailableEditor =>
      'Edytor w przeglądarce uruchamia proces code-server na prawdziwym checkoucie. Demo nie ma ani jednego, ani drugiego.';

  @override
  String get demoUnavailableFeeds =>
      'Demo czyta prawdziwe kanały, ale jego lista subskrypcji jest sztywna. Dodawanie i usuwanie jest tu wyłączone.';

  @override
  String get demoUnavailableForge =>
      'Demo nie trzyma żadnych danych uwierzytelniających i nigdy nie kontaktuje się z GitHubem, GitLabem ani Linear. Jego pull requesty są fixture\'ami, a Twoje komentarze do nich są zapisywane lokalnie.';

  @override
  String get demoUnavailableModels =>
      'Demo nie odwołuje się do żadnego modelu. Uruchomienia agentów to odtwarzanie ze skryptu, dlatego nic nie kosztują i nie docierają do żadnego dostawcy.';

  @override
  String get demoUnavailableMcp =>
      'Powierzchnia narzędzi MCP nie jest zamontowana w demo, więc żaden zewnętrzny klient nie może się jej podpiąć.';

  @override
  String get demoUnavailableRepos =>
      'Demo nie wycheckowuje żadnego kodu i nie uruchamia gita. Repozytorium, które widzisz, to fixture za pull requestami.';

  @override
  String get demoUnavailableSkills =>
      'Instalacja umiejętności pobiera i skanuje kod. Demo nic nie pobiera.';

  @override
  String get demoUnavailableSso =>
      'Logowanie jednokrotne to konfiguracja serwera. Demo loguje Cię zamiast tego jako tymczasowego gościa.';

  @override
  String get demoUnavailableAudio =>
      'Nagrywanie i dyktowanie wymagają przechwytywania dźwięku i modelu mowy na hoście. Demo nie dostarcza ani jednego, ani drugiego, więc jego spotkania to transkrypcje bez odtwarzania.';

  @override
  String get demoUnavailableServerAdmin =>
      'To administracja serwerem. Demo daje każdemu odwiedzającemu własny jednorazowy obszar roboczy i nic ponadto.';

  @override
  String get settingsBackupRestore => 'Kopia zapasowa i przywracanie';

  @override
  String get settingsBackupRestoreDescription =>
      'Migawki każdej bazy danych na tym serwerze, plus eksport, import i usuwanie pojedynczego obszaru roboczego.';

  @override
  String get backupSnapshotsLabel => 'Migawki instalacji';

  @override
  String get backupSnapshotsExplainer =>
      'Migawka kopiuje każdą bazę danych do foldera ze znacznikiem czasu na hoście serwera. Przywrócenie całej instalacji oznacza skopiowanie tego foldera z powrotem przy zatrzymanym serwerze; pojedynczy obszar roboczy można przywrócić stąd.';

  @override
  String get backupNowAction => 'Wykonaj kopię teraz';

  @override
  String backupSnapshotWritten(String path) {
    return 'Migawkę zapisano w $path';
  }

  @override
  String get backupNoSnapshots =>
      'Nie ma jeszcze migawek. Wykonywana jest tylko na Twoje żądanie — nic nie jest zaplanowane.';

  @override
  String get backupSnapshotComplete => 'Kompletna';

  @override
  String get backupSnapshotIncomplete => 'Niekompletna';

  @override
  String get backupSnapshotIncompleteNote =>
      'Brakuje manifestu albo wymienia pliki, których nie ma, więc ta migawka nie może przywrócić całej instalacji. Pliki obszarów roboczych, które ma, można jednak adoptować po kolei.';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count obszaru roboczego',
      many: '$count obszarów roboczych',
      few: '$count obszary robocze',
      one: '$count obszar roboczy',
      zero: 'Brak obszarów roboczych',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nie uwzględniono $count obszaru roboczego',
      many: 'Nie uwzględniono $count obszarów roboczych',
      few: 'Nie uwzględniono $count obszarów roboczych',
      one: 'Nie uwzględniono $count obszaru roboczego',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'Ścieżka na serwerze';

  @override
  String get backupRestoreAction => 'Przywróć';

  @override
  String get backupRestoreTitle => 'Przywróć obszar roboczy';

  @override
  String backupRestoreBody(String name) {
    return 'To zastępuje wszystko w $name kopią trzymaną w tej migawce. Wszystko, co ten obszar roboczy zrobił od wykonania migawki, przepada i nie da się tego cofnąć.';
  }

  @override
  String backupRestoreDone(String name) {
    return 'Przywrócono $name z migawki.';
  }

  @override
  String get backupWorkspaceUnknown => 'Nie ma go już na tym serwerze';

  @override
  String get backupWorkspaceDataLabel => 'Dane obszaru roboczego';

  @override
  String get backupWorkspaceDataExplainer =>
      'Jeden obszar roboczy to jeden plik bazy danych, więc eksport kopiuje ten plik zamiast zrzucać tabelę po tabeli. Import zastępuje wszystko w docelowym obszarze roboczym plikiem, który wskażesz.';

  @override
  String get backupExportAction => 'Eksportuj';

  @override
  String backupExportDone(String path) {
    return 'Wyeksportowano do $path';
  }

  @override
  String get backupExportedFileLabel => 'Wyeksportowany plik na serwerze';

  @override
  String get backupImportAction => 'Importuj';

  @override
  String backupImportTitle(String name) {
    return 'Importuj do $name';
  }

  @override
  String backupImportBody(String name) {
    return 'To zastępuje wszystko w $name zawartością pliku. Wszystko, co ten obszar roboczy ma teraz, przepada i nie da się tego cofnąć.';
  }

  @override
  String get backupImportSourceLabel => 'Plik bazy danych obszaru roboczego';

  @override
  String get backupImportSourceDescription =>
      'Plik .db, który serwer potrafi odczytać. Ścieżki rozwiązywane są na hoście serwera, nie na tym urządzeniu.';

  @override
  String backupImportDone(String name) {
    return 'Zaimportowano do $name.';
  }

  @override
  String backupDeleteBody(String name) {
    return '$name znika z każdej listy i wyszukiwania. Jego plik bazy danych zostaje na dysku, kopie zapasowe nadal go zawierają, a nic nie odzyskuje tego miejsca automatycznie.';
  }

  @override
  String get backupExportDescription =>
      'Zapisz kopię na serwerze albo pobierz ją na to urządzenie.';

  @override
  String get backupExportOnServerAction => 'Zapisz na serwerze';

  @override
  String get backupDownloadAction => 'Pobierz';

  @override
  String backupDownloadSaved(String path) {
    return 'Zapisano w $path';
  }

  @override
  String get backupDownloadInBrowser =>
      'Twoja przeglądarka właśnie to pobiera.';

  @override
  String get backupRestoreFromDeviceLabel => 'Przywróć z tego urządzenia';

  @override
  String get backupRestoreFromDeviceDescription =>
      'Wybierz tu plik bazy danych obszaru roboczego, a Control Center wyśle go na serwer. To ta opcja, która działa, gdy serwer nie jest tą maszyną.';

  @override
  String get backupUploadAction => 'Wybierz plik i wyślij';

  @override
  String get backupTransferUnavailable =>
      'To połączenie dociera do serwera przez relay, który nie przenosi plików. Połącz się z serwerem bezpośrednio, aby pobrać lub wysłać kopię zapasową.';

  @override
  String get backupTransferForbidden =>
      'Serwer odmówił. Pobieranie obszaru roboczego wymaga roli administratora, przywracanie — właściciela, a całej migawki — operatora instalacji.';

  @override
  String get backupTransferUnsupported =>
      'Ten serwer nie ma powierzchni kopii zapasowych.';

  @override
  String get backupTransferTooLarge =>
      'Plik jest większy, niż serwer akceptuje.';

  @override
  String get credentialGateWaitingTitle => 'Czekanie na dane uwierzytelniające';

  @override
  String credentialGateHarnessTitle(String provider) {
    return '$provider nie ma danych uwierzytelniających';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Code jest wylogowany';

  @override
  String get credentialGateExpiredTitle =>
      'Twoje logowanie Claude Code wygasło';

  @override
  String get credentialGatePlanSpentTitle =>
      'Osiągnięto limit planu Claude Code';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent czeka na kontynuację.';
  }

  @override
  String get credentialGateWaitingRun => 'Uruchomienie czeka na kontynuację.';

  @override
  String get credentialGateWatching =>
      'Czekamy na rozwiązanie — uruchomienie pójdzie dalej samo.';

  @override
  String credentialGateFreesUpAt(String time) {
    return 'Uwolni się o $time';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'Uruchomienie podda się o $time';
  }

  @override
  String get credentialGateCheckAgain => 'Sprawdź ponownie';

  @override
  String get credentialGateCancelRun => 'Anuluj uruchomienie';

  @override
  String get credentialGateAccountsTried => 'Spróbowane konta';

  @override
  String get credentialGateClaudeSignInHint =>
      'Zaloguj się w Ustawienia → Adaptery → Claude Code albo uruchom polecenie logowania w terminalu. Uruchomienie podchwyci je samo.';

  @override
  String get credentialGateOpenSettings => 'Otwórz ustawienia';

  @override
  String get selectModel => 'Wybierz model';

  @override
  String get allModels => 'Wszystkie modele';

  @override
  String get noModelsMatchSearch => 'Żaden model nie pasuje do wyszukiwania';

  @override
  String useCustomModelId(String id) {
    return 'Użyj „$id”';
  }

  @override
  String get modelFree => 'Bezpłatny';

  @override
  String modelOutputTokens(String tokens) {
    return '$tokens wyjścia';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return '$input wejście / $output wyjście na 1M tokenów';
  }

  @override
  String modelEffortLevels(String levels) {
    return 'Wysiłek rozumowania: $levels';
  }

  @override
  String get modelSupportsReasoning => 'Obsługuje wysiłek rozumowania';

  @override
  String get profileDeliveryMetrics => 'Wskaźniki dostarczania';

  @override
  String profileMetricsSample(int count) {
    return 'Przeanalizowane PR-y: $count';
  }

  @override
  String get profileMergeRate => 'Odsetek scaleń';

  @override
  String get profileReviewCoverage => 'Pokrycie przeglądami';

  @override
  String get profilePrSize => 'Rozmiar PR-a';

  @override
  String get profileTimeToMerge => 'Czas do scalenia';

  @override
  String get profileMergeTimeTrend => 'Trend czasu scalania';

  @override
  String get profileWeeklyMedian => 'Mediana tygodniowa, skala logarytmiczna';

  @override
  String get profilePrOpeningPattern =>
      'Dzień tygodnia × godzina, czas lokalny';

  @override
  String get profileFirstReview => 'Czas do pierwszego przeglądu';

  @override
  String get profileMetricsTruncated =>
      'Percentyle są obliczane na podstawie ograniczonej próbki dostępnych pull requestów.';

  @override
  String profileLinesChanged(String count) {
    return 'Liczba wierszy: $count';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count min';
  }

  @override
  String profileDurationHours(int count) {
    return '$count godz.';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '$days d $hours godz.';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return 'Członkowie: $count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return 'Brak pull requestów zespołu $team w tym obszarze roboczym';
  }

  @override
  String get profilePrStateFilterLabel => 'Filtruj pull requesty według stanu';

  @override
  String get noProfilePrsMatchSearchHint =>
      'Spróbuj użyć innego tytułu lub numeru pull requesta';

  @override
  String get rigNetworkUnrestricted => 'Sieć bez ograniczeń';

  @override
  String get rigNetworkAllowAllHosts => 'Zezwól na wszystkie hosty';

  @override
  String get rigNetworkBypassTitle => 'Zezwolić na wszystkie hosty sieciowe?';

  @override
  String get rigNetworkBypassBody =>
      'Spowoduje to ponowne uruchomienie odizolowanego środowiska i odrzucenie niezatwierdzonej pracy w jego wnętrzu. System gościa będzie wtedy mógł łączyć się z dowolnym hostem sieciowym aż do zamknięcia.';

  @override
  String get rigNetworkRestartUnrestricted => 'Uruchom ponownie bez ograniczeń';

  @override
  String get rigNetworkUnrestrictedBody =>
      'To odizolowane środowisko może łączyć się z każdym hostem sieciowym. Zamknij je i otwórz nowe, aby przywrócić domyślne ograniczenia.';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      'Ten emulator Androida już sam zarządza swoją siecią, dlatego Control Center nie może wymusić listy dozwolonych hostów. Ponowne uruchomienie nie jest potrzebne.';

  @override
  String get rigClipboardPermissionHostToRigTitle =>
      'Wkleić schowek do tego środowiska?';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'Control Center odczyta schowek urządzenia i wyśle jego zawartość do środowiska. Zawartość schowka może zawierać hasła lub inne sekrety.';

  @override
  String get rigClipboardPermissionRigToHostTitle =>
      'Skopiować schowek z tego środowiska?';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'Control Center odczyta schowek środowiska i zastąpi schowek urządzenia jego zawartością. Traktuj zawartość ze środowiska jako niezaufaną.';

  @override
  String get rigClipboardAllowTenMinutes => 'Zezwól na 10 minut';

  @override
  String get rigClipboardAlwaysAllow => 'Zawsze zezwalaj';

  @override
  String get rigClipboardSettingsTitle => 'Dostęp do schowka';

  @override
  String get rigClipboardSettingsHint =>
      'Wybierz, które transfery schowka mogą działać bez pytania. Tymczasowe uprawnienia wygasają po 10 minutach.';

  @override
  String get rigClipboardAlwaysPasteTitle =>
      'Zawsze zezwalaj na wklejanie do środowisk';

  @override
  String get rigClipboardAlwaysPasteDescription =>
      'Wysyłaj schowek tego urządzenia do dowolnego środowiska bez pytania.';

  @override
  String get rigClipboardAlwaysCopyTitle =>
      'Zawsze zezwalaj na kopiowanie ze środowisk';

  @override
  String get rigClipboardAlwaysCopyDescription =>
      'Umieszczaj zawartość schowka z dowolnego środowiska na tym urządzeniu bez pytania.';
}
