// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get succeeded => 'Berjaya';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'Cuba semula #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'Memulakan · $time';
  }

  @override
  String get agentActivityFollowingLive => 'Mengikuti aktiviti langsung';

  @override
  String get agentActivityJumpToLatest => 'Lompat ke terkini';

  @override
  String get agentActivityLoadFailed =>
      'Tidak dapat memuatkan aktiviti larian ini';

  @override
  String get agentActivityNotRecorded =>
      'Tiada aktiviti direkodkan untuk larian ini';

  @override
  String get agentActivityNotRecordedHint =>
      'Larian yang selesai sebelum penangkapan aktiviti didayakan tiada garis masa.';

  @override
  String get agentActivityRunUnavailable => 'Larian ini tidak lagi tersedia';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'Subejen bagi $agent';
  }

  @override
  String get agentActivityUnsupported =>
      'Penangkapan aktiviti tidak tersedia pada pelayan yang disambungkan';

  @override
  String get agentActivityUnsupportedHint =>
      'Mulakan semula apl supaya ia mengambil binaan pelayan terkini.';

  @override
  String get agentActivityWaiting => 'Menunggu aktiviti…';

  @override
  String get created => 'Dicipta';

  @override
  String get dictationStart => 'Mula dikte';

  @override
  String get dictationListening => 'Mendengar…';

  @override
  String get dictationUnavailable =>
      'Dikte memerlukan model suara pada hos pelayan. Sediakannya dalam tetapan suara.';

  @override
  String get dictationFailedToStart => 'Tidak dapat memulakan dikte';

  @override
  String get dictationHoldToTalkTitle => 'Tekan untuk bercakap';

  @override
  String get dictationHoldToTalkDescription =>
      'Tekan butang mikrofon atau pintasan untuk berdikte dan lepaskan untuk berhenti. Apabila dimatikan, tekan sekali untuk mula dan sekali lagi untuk berhenti.';

  @override
  String get focusConversation => 'Fokus perbualan';

  @override
  String get ideAgentActivity => 'Aktiviti ejen';

  @override
  String get keybindingPushToTalk => 'Tekan untuk bercakap';

  @override
  String get keybindingPushToTalkDescription =>
      'Tahan atau togol dikte suara dalam penggubah mesej';

  @override
  String get agentPermissions => 'Kebenaran ejen';

  @override
  String get agentPermissionsSettingsDescription =>
      'Tentukan apa yang ejen boleh lakukan sendiri, mesti tanya dahulu, atau tidak boleh langsung — mengikut ruang kerja, ejen atau ruang.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Tetapkan keputusan untuk setiap jenis kesan. Peraturan berlapis: ruang mengatasi ejen, ejen mengatasi ruang kerja, ruang kerja mengatasi praset modus. Peraturan paling khusus menang.';

  @override
  String get guardrailLoading => 'Memuatkan peraturan…';

  @override
  String get guardrailRulesLoadFailed =>
      'Tidak dapat memuatkan peraturan kebenaran.';

  @override
  String get guardrailScopeWorkspace => 'Ruang kerja';

  @override
  String get guardrailScopeAgent => 'Ejen';

  @override
  String get guardrailScopeSpace => 'Ruang';

  @override
  String get guardrailSelectAgent => 'Pilih ejen';

  @override
  String get guardrailSelectSpace => 'Pilih ruang';

  @override
  String get guardrailNoAgents => 'Belum ada ejen dalam ruang kerja ini.';

  @override
  String get guardrailNoSpaces => 'Belum ada ruang dalam ruang kerja ini.';

  @override
  String get guardrailClassFileDelete => 'Padam fail';

  @override
  String get guardrailClassFileWriteOutsideWorktree => 'Tulis di luar worktree';

  @override
  String get guardrailClassGitCommit => 'Cipta commit';

  @override
  String get guardrailClassGitPush => 'Push ke remote';

  @override
  String get guardrailClassPrCreate => 'Buka pull request';

  @override
  String get guardrailClassPrPublish => 'Terbitkan semakan atau cantuman';

  @override
  String get guardrailClassVendorSyncWrite => 'Tulis ke penjejak luaran';

  @override
  String get guardrailClassNetworkEgress => 'Akses rangkaian';

  @override
  String get guardrailClassSecretAccess => 'Baca rahsia';

  @override
  String get guardrailClassPackageInstall => 'Pasang pakej';

  @override
  String get guardrailClassProcessSpawn => 'Jalankan proses';

  @override
  String get guardrailClassWorkspaceMutation => 'Ubah struktur ruang kerja';

  @override
  String get guardrailClassEnclosureControl =>
      'Kawal persekitaran terasing (stesen)';

  @override
  String get navRigs => 'Stesen';

  @override
  String get rigsUnsupportedServer =>
      'Pelayan ini tidak boleh mengehos sebarang permukaan rig. Semak keperluan hos untuk mesin yang ingin anda gunakan.';

  @override
  String get rigSurfaceComputer => 'Komputer';

  @override
  String get rigSurfaceBrowser => 'Penyemak imbas';

  @override
  String get rigSurfaceAndroid => 'Android';

  @override
  String get rigSurfaceIosSimulator => 'Simulator iOS';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return '$engine pakai buang, terasing daripada mesin anda. Buka enjin lain untuk membandingkan halaman yang sama bersebelahan.';
  }

  @override
  String get rigPhaseReady => 'Sedia';

  @override
  String get rigPhaseStarting => 'Memulakan';

  @override
  String get rigPhaseParked => 'Diparkir';

  @override
  String get rigPhaseClosing => 'Menutup';

  @override
  String get rigPhaseClosed => 'Ditutup';

  @override
  String get rigPhaseFailed => 'Gagal';

  @override
  String get rigPhaseUnknown => 'Tidak diketahui';

  @override
  String get rigNotAccelerated => 'Diedulasikan';

  @override
  String get rigAudioListen => 'Dengar mesin';

  @override
  String get rigAudioMute => 'Senyapkan mesin';

  @override
  String get rigYouHaveControl => 'Anda mempunyai kawalan';

  @override
  String get rigBackendAvailable => 'Tersedia';

  @override
  String get rigBackendUnavailable => 'Tidak tersedia';

  @override
  String get rigEgressNotEnforced =>
      'Rangkaian tidak dikurung pada bahagian belakang ini — ia mengurus sambungan sendiri.';

  @override
  String get rigStartMachine => 'Mulakan mesin';

  @override
  String get rigStartHint =>
      'Memulakan VM pakai buang yang anda dan ejen kongsikan untuk perbualan ini. Ia dimusnahkan apabila ditutup, dan tiada apa-apa di dalamnya menyentuh komputer anda.';

  @override
  String get rigStartAndroidHint =>
      'Menyambung kepada emulator Android yang sudah berjalan pada pelayan. Akses rangkaian tidak diasingkan.';

  @override
  String get rigStartIosHint =>
      'Mencipta Simulator iOS sementara pada Mac pelayan. Simulator dipadamkan apabila rig ditutup; akses rangkaian tidak diasingkan.';

  @override
  String get rigStopMachine => 'Hentikan mesin';

  @override
  String get rigSurfaceUnavailable =>
      'Pelayan ini tidak dapat mengehos jenis mesin ini.';

  @override
  String get rigTabNeedsConversation =>
      'Buka perbualan dahulu — mesin milik satu perbualan, supaya anda dan ejen melihat skrin yang sama.';

  @override
  String get ideMenuSectionTools => 'Alat';

  @override
  String get ideMenuSectionMachines => 'Mesin';

  @override
  String get ideMenuSectionReopen => 'Buka semula';

  @override
  String get ideMenuSearchHint => 'Cari';

  @override
  String get ideMenuNoMatches => 'Tiada padanan';

  @override
  String get rigMenuComputer => 'Komputer';

  @override
  String get rigMenuBrowser => 'Penyemak imbas';

  @override
  String get rigMenuAndroid => 'Android';

  @override
  String get rigMenuIosSimulator => 'Simulator iOS';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return 'Tutup $name?';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'Mesin terus berjalan di latar belakang — buka semula pada bila-bila masa dari bar sisi. Matikan sebaliknya untuk membebaskan memorinya sekarang.';

  @override
  String get ideCloseKeepBodyShell =>
      'Perintah terus berjalan di latar belakang — buka semula shell pada bila-bila masa dari bar sisi. Tamatkan sebaliknya untuk menghentikan apa yang sedang dilakukannya sekarang.';

  @override
  String get ideCloseKeepBodyAgent =>
      'Ejen terus bekerja di latar belakang — buka semula perbualan pada bila-bila masa dari bar sisi. Hentikan sebaliknya untuk menamatkan larian sekarang.';

  @override
  String get ideCloseKeepRunning => 'Teruskan berjalan';

  @override
  String get ideCloseShutDownMachine => 'Matikan';

  @override
  String get ideCloseEndShell => 'Tamatkan shell';

  @override
  String get ideCloseStopAgent => 'Henti ejen';

  @override
  String get rigsSettingsSubtitle =>
      'Apa yang pelayan ini boleh but, imej asas yang diperlukannya, dan mesin yang sedang berjalan';

  @override
  String get rigsCapabilitiesTitle => 'Pelayan ini';

  @override
  String get rigInstallIosAutomation => 'Pasang jambatan automasi iOS';

  @override
  String get rigInstallingIosAutomation => 'Memasang jambatan automasi iOS…';

  @override
  String get rigIosAutomationInstalled =>
      'Jambatan automasi iOS telah dipasang';

  @override
  String get rigsImagesTitle => 'Imej asas';

  @override
  String get rigsImagesHint =>
      'Setiap stesen but salah satu imej baca sahaja ini. Setiap sesi menulis ke tindanan pakai buang, jadi satu stesen tidak pernah mengubah apa yang stesen seterusnya bermula daripadanya.';

  @override
  String get rigsRunningTitle => 'Sedang berjalan';

  @override
  String get rigsNoneRunning => 'Tiada mesin sedang berjalan.';

  @override
  String get rigsCustomImagesTitle => 'Imej tersuai (ruang kerja ini)';

  @override
  String get rigsCustomImagesHint =>
      'Arahkan Terminal (VM) atau Penyemak imbas (VM) ke imej anda sendiri — kembangkan lalai dengan alat yang projek anda perlukan, atau gunakan mana-mana yang serasi dari daftar. Mesin baharu menggunakannya; yang sedang berjalan mengekalkan miliknya. Lihat panduan stesen untuk apa yang imej mesti sediakan.';

  @override
  String get rigsCustomTerminalImageLabel => 'Imej Terminal (VM)';

  @override
  String get rigsCustomBrowserImageLabel => 'Imej Penyemak imbas (VM)';

  @override
  String get rigsCustomImagePlaceholder =>
      'cth. ghcr.io/acme/dev-shell:1.2 — biarkan kosong untuk lalai';

  @override
  String get rigsCustomImageInvalid =>
      'Masukkan rujukan daftar seperti repo/name:tag. Laluan setempat dan arkib tidak dibenarkan.';

  @override
  String get rigsCustomImageSaved =>
      'Disimpan. Mesin baharu but imej ini; yang sedang berjalan mengekalkan miliknya.';

  @override
  String get rigsEgressTitle => 'Keluar penyemak imbas (ruang kerja ini)';

  @override
  String get rigsEgressHint =>
      'Hos tambahan yang penyemak imbas terasing boleh capai — satu setiap baris: hos tepat (api.example.com) atau kad liar untuk subdomainnya (*.example.com). Tapak produk kekal dibenarkan sama ada cara. Mesin baharu mendapat senarai; yang sedang berjalan mengekalkan apa yang mereka but dengannya.';

  @override
  String rigsEgressInvalid(String host) {
    return '\"$host\" bukan entri hos yang sah.';
  }

  @override
  String get rigsEgressSaved =>
      'Disimpan. Mesin penyemak imbas baharu membenarkan hos ini; yang sedang berjalan mengekalkan miliknya.';

  @override
  String get rigImageInstalled => 'Dipasang';

  @override
  String get rigImageNotDownloaded => 'Belum dimuat turun';

  @override
  String get rigImageNotPublished => 'Belum diterbitkan';

  @override
  String get rigImageNotPublishedHint =>
      'Tiada imej telah diterbitkan untuk ini lagi, jadi tiada apa untuk dimuat turun. Import imej cakera yang serasi untuk dayakannya.';

  @override
  String get rigImageDownload => 'Muat turun';

  @override
  String get rigImageDownloading => 'Memuat turun…';

  @override
  String get rigImageImport => 'Import';

  @override
  String get rigImageImportMessage =>
      'Laluan ke imej cakera qcow2 pada sistem fail pelayan. Ia disalin ke stor imej, jadi fail itu boleh dipindah kemudian.';

  @override
  String get rigConnectingStream => 'Menyambung ke stesen';

  @override
  String get rigStreamNotAllowed => 'Anda tidak mempunyai akses ke stesen ini.';

  @override
  String get rigStreamNotRunning => 'Stesen ini tidak lagi berjalan.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'Paparan langsung memerlukan ffmpeg pada hos ini. Pasang ffmpeg dan buka semula tab.';

  @override
  String get rigStreamEnded => 'Paparan langsung telah tamat.';

  @override
  String get rigStreamFailed => 'Paparan langsung tidak dapat dibuka.';

  @override
  String get rigStreamDisconnected => 'Tidak disambungkan ke pelayan.';

  @override
  String rigDropSendingOne(String name) {
    return 'Menyalin \"$name\" ke dalam mesin…';
  }

  @override
  String rigDropSendingMany(int count) {
    return 'Menyalin $count fail ke dalam mesin…';
  }

  @override
  String get rigTerminalDropSending => 'Menyalin ke dalam mesin…';

  @override
  String get rigTerminalPasteImage => 'Imej yang ditampal disimpan dalam mesin';

  @override
  String get rigPortsTitle => 'Port yang dihantar';

  @override
  String get rigPortsTooltip => 'Port yang terbuka dalam mesin ini';

  @override
  String get rigPortsEmpty =>
      'Belum ada yang mendengar. Mulakan pelayan dalam terminal — pelayan dev pada port 3000 muncul di sini.';

  @override
  String get rigPortsAdd => 'Tambah port';

  @override
  String get rigPortsAddHint => 'Port tetamu untuk dihantar (cth. 3000)';

  @override
  String get rigPortsAutoForward => 'Hantar port secara automatik';

  @override
  String get rigPortsCopyUrl => 'Salin URL setempat';

  @override
  String rigPortsCopiedUrl(String url) {
    return '$url disalin';
  }

  @override
  String get rigPortsStopForward => 'Henti hantar';

  @override
  String get rigPortsExposeLan => 'Kongsi pada rangkaian setempat';

  @override
  String get rigPortsLanPrivate => 'Setempat sahaja';

  @override
  String get rigPortsLanShared => 'Pada rangkaian';

  @override
  String get rigPortsSetDomain => 'Tetapkan domain penyemak imbas (.test)';

  @override
  String get rigPortsDomainHint =>
      'Domain untuk Penyemak imbas (VM), cth. myapp.test — boleh dicapai di sana, bukan pada hos';

  @override
  String get rigPortsProcessUnknown => 'proses tidak diketahui';

  @override
  String get rigPortsInactive => 'tidak mendengar';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count imej asas masih perlu dimuat turun',
      one: '1 imej asas masih perlu dimuat turun',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'Benarkan';

  @override
  String get guardrailDecisionPrompt => 'Tanya dahulu';

  @override
  String get guardrailDecisionDeny => 'Tolak';

  @override
  String get guardrailSourceThisScope => 'Skop ini';

  @override
  String get guardrailSourceDefault => 'Lalai terbina';

  @override
  String get guardrailSourcePreset => 'Praset modus';

  @override
  String get guardrailSourceInherited => 'Diwarisi';

  @override
  String get guardrailClearToInherited => 'Kosongkan ke diwarisi';

  @override
  String get guardrailWhatIf => 'Bagaimana jika?';

  @override
  String get guardrailWhatIfDescription =>
      'Lihat bagaimana peraturan semasa akan menyelesaikan tindakan, menggunakan logik yang sama yang ejen jalankan.';

  @override
  String get guardrailProbeActionLabel => 'Tindakan';

  @override
  String get guardrailProbeCommandLabel => 'Perintah (pilihan)';

  @override
  String get guardrailProbeCommandHint => 'cth. git push origin main';

  @override
  String get guardrailProbeAgentLabel => 'Ejen (pilihan)';

  @override
  String get guardrailProbeSpaceLabel => 'Ruang (pilihan)';

  @override
  String get guardrailProbeNone => 'Tiada';

  @override
  String get guardrailProbeModeLabel => 'Modus';

  @override
  String get guardrailProbeResult => 'Hasil';

  @override
  String get guardrailProbeSource => 'Sumber:';

  @override
  String get guardrailAdapterMatrix => 'Di mana peraturan dikuatkuasakan';

  @override
  String get guardrailAdapterMatrixDescription =>
      'Rujukan jujur: di mana setiap kesan sebenarnya ditangkap, mengikut pelari ejen. Ini mendokumentasikan realiti, bukan jaminan — kesan yang pelari lakukan di luar jalur tidak dapat dipintas.';

  @override
  String get guardrailEffectColumn => 'Kesan';

  @override
  String get guardrailAdapterHarness => 'Harness terbina';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'Lantai kotak pasir';

  @override
  String get guardrailEnforcementPolicyGate => 'Pintu polisi';

  @override
  String get guardrailEnforcementSandbox => 'Kotak pasir sahaja';

  @override
  String get guardrailEnforcementNone => 'Tidak boleh dikuatkuasakan';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'Keputusan kebenaran diperiksa sebelum kesan dijalankan dan boleh menyekatnya.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'Hanya kotak pasir yang menyekatnya; peraturan kebenaran tidak dirujuk.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'Keputusan ini nasihat sahaja — ia tidak dapat dipintas di sini.';

  @override
  String get obsStatCost => 'kos';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount dilimpahkan';
  }

  @override
  String get obsStatDuration => 'tempoh';

  @override
  String get obsStatTokens => 'token';

  @override
  String get obsStatTools => 'alat';

  @override
  String get openAgentActivity => 'Buka aktiviti';

  @override
  String get orgChart => 'Carta organisasi';

  @override
  String get orgChartEmpty => 'Belum ada ejen';

  @override
  String get navCalendar => 'Kalendar';

  @override
  String get serverConnection => 'Sambungan pelayan';

  @override
  String get serverModeLocal => 'Jalankan dalam apl ini';

  @override
  String get serverModeLocalDescription =>
      'Control Center menjalankan pelayan sendiri pada mesin ini dan memiliki data anda secara setempat.';

  @override
  String get serverModeRemote => 'Sambung ke tika jauh';

  @override
  String get serverModeRemoteDescription =>
      'Sambung ke pelayan Control Center yang berjalan di tempat lain. Data anda tinggal pada pelayan itu.';

  @override
  String get serverRemoteUrl => 'URL pelayan';

  @override
  String get serverRemoteDeviceId => 'ID peranti';

  @override
  String get serverRemotePairingKey => 'Kunci pasangan';

  @override
  String get serverRemotePairingKeyHint =>
      'Tampal kunci pasangan dari pelayan jauh';

  @override
  String get serverSetupInviteCode => 'Kod jemputan';

  @override
  String get serverSetupInviteCodeHint =>
      'Tampal kod jemputan sekali guna (biarkan kosong untuk menggunakan kunci pasangan)';

  @override
  String get serverDiscoveryTooltip => 'Cari pelayan pada rangkaian anda';

  @override
  String get serverDiscoveryTitle => 'Pelayan pada rangkaian anda';

  @override
  String get serverDiscoverySearching => 'Mencari pelayan…';

  @override
  String get serverDiscoveryEmpty =>
      'Tiada pelayan dijumpai. Pastikan pelayan sedang berjalan dan peranti ini boleh mencapainya, kemudian cari lagi.';

  @override
  String get serverDiscoveryRefresh => 'Cari lagi';

  @override
  String get serverListActive => 'Aktif';

  @override
  String get serverListSwitch => 'Tukar';

  @override
  String get serverListAddTitle => 'Tambah pelayan';

  @override
  String get serverListRemoveActiveHint =>
      'Tukar ke pelayan lain sebelum membuang yang ini.';

  @override
  String get serverSwitchFailedTitle => 'Tidak dapat menukar pelayan';

  @override
  String get serverListInsecureBadge => 'Tidak selamat';

  @override
  String get connectionPathLocal => 'Setempat';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'Sedang dimatikan';

  @override
  String get shutdownSubtitle => 'Menutup pelayan setempat';

  @override
  String get shutdownServiceApprovals => 'Kelulusan';

  @override
  String get shutdownServiceBackgroundJobs => 'Tugas latar belakang';

  @override
  String get shutdownServiceScheduler => 'Penjadual tugas';

  @override
  String get shutdownServiceCalendar => 'Segerak kalendar';

  @override
  String get shutdownServiceWeather => 'Cuaca';

  @override
  String get shutdownServiceSoundscape => 'Landskap bunyi';

  @override
  String get shutdownServiceMeetings => 'Mesyuarat';

  @override
  String get shutdownServiceVoiceModels => 'Model suara';

  @override
  String get shutdownServiceNetworking => 'Rangkaian';

  @override
  String get shutdownServicePresence => 'Kehadiran';

  @override
  String get shutdownServiceDataSync => 'Segerak data';

  @override
  String get shutdownServiceDeviceRelay => 'Geganti peranti';

  @override
  String get shutdownServiceMcpConnections => 'Sambungan MCP';

  @override
  String get shutdownServiceCodeEditors => 'Editor kod';

  @override
  String get serverSharingTitle => 'Kongsi pelayan ini';

  @override
  String get serverSharingDescription =>
      'Jadikan pelayan ini boleh dicapai dari peranti anda yang lain. Tiada apa yang didedahkan secara awam melainkan anda menghidupkan terowong di bawah. Jemputan pasangan menyemat alamat semasa pelayan secara automatik — ciptanya di bawah tetapan ruang kerja.';

  @override
  String get serverSharingUnavailable =>
      'Kawalan perkongsian tidak tersedia pada pelayan ini.';

  @override
  String get serverSharingMdnsLabel => 'Penemuan LAN';

  @override
  String get serverSharingMdnsOn =>
      'Mengiklankan pelayan ini pada rangkaian setempat anda (mDNS)';

  @override
  String get serverSharingMdnsOff =>
      'Tidak mengiklankan pada rangkaian setempat anda (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'Terowong';

  @override
  String get serverSharingTunnelHelper =>
      'Menghidupkan terowong menjadikan pelayan ini boleh dicapai dari internet. Pendedahan awam adalah pilihan dan dimatikan secara lalai.';

  @override
  String get serverSharingProviderOff => 'Mati';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'URL awam';

  @override
  String get serverSharingTunnelStarting => 'Memulakan terowong…';

  @override
  String serverSharingTunnelError(String error) {
    return 'Ralat terowong: $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'Terowong sudah naik. Capainya pada nama hos DNS yang dikonfigurasikan.';

  @override
  String get serverSharingRelayLabel => 'Geganti';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'Digeanti bulan ini: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'Sesi geganti aktif: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle =>
      'Tidak dapat mengemas kini perkongsian';

  @override
  String get pairNewClient => 'Pasangkan klien baharu';

  @override
  String get pairClientNameHint =>
      'Labelkan klien ini (cth. Komputer riba kerja)';

  @override
  String get pairClientTypeWeb => 'Penyemak imbas web';

  @override
  String get pairClientTypeDesktop => 'Apl desktop';

  @override
  String get pairClientTypePhone => 'Telefon';

  @override
  String get pairAction => 'Pasangkan';

  @override
  String get revoke => 'Tarik balik';

  @override
  String get pairCredentialsIntro =>
      'Sambungkan klien baharu dengan butiran ini, atau buka pautan di dalamnya.';

  @override
  String get pairLinkLabel => 'Pautan';

  @override
  String get pairScanQr =>
      'Imbas kod QR ini dengan kamera telefon anda untuk memasangkannya.';

  @override
  String get pairServerUnreachableTitle => 'Tidak boleh dicapai';

  @override
  String get pairServerUnreachable =>
      'Peranti lain tidak dapat mencapai pelayan ini secara langsung, jadi klien baharu tidak dapat menyambung. Tetapkan URL awam pelayan untuk memasangkan lebih banyak klien.';

  @override
  String get serverSetupTitle => 'Bagaimana Control Center patut berjalan?';

  @override
  String get serverSetupSubtitle =>
      'Control Center memerlukan pelayan yang memiliki data anda. Jalankan satu dalam apl ini, atau sambung ke tika yang berjalan di tempat lain.';

  @override
  String get serverSetupRunLocal => 'Jalankan dalam apl ini';

  @override
  String get serverSetupConnect => 'Sambung';

  @override
  String get serverSetupInvalidUrl =>
      'Masukkan URL pelayan ws:// atau wss:// yang sah.';

  @override
  String get serverSetupCouldNotConnect => 'Tidak dapat menyambung';

  @override
  String get serverSetupErrorUnreachable =>
      'Kami tidak dapat mencapai pelayan. Pastikan ia sedang berjalan dan peranti ini boleh mencapainya (rangkaian yang sama atau geganti).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'Identiti pelayan tidak sepadan dengan yang disimpan pada peranti ini. Jika pelayan dipasang semula atau ditetapkan semula, buang pelayan yang disimpan dan pasangkan lagi.';

  @override
  String get serverSetupErrorAuthRejected =>
      'Pelayan menolak peranti ini. Pastikan kunci pasangan dan ID peranti sepadan dengan apa yang pelayan keluarkan.';

  @override
  String get serverSetupErrorInviteRejected =>
      'Kod jemputan itu tidak sah atau telah luput. Minta yang baharu.';

  @override
  String get serverSetupErrorGeneric =>
      'Sesuatu tidak kena semasa menyambung. Kembangkan butiran teknikal di bawah untuk maklumat lanjut.';

  @override
  String get serverSetupErrorDetails => 'Butiran teknikal';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lagi',
      one: '1 lagi',
    );
    return '$_temp0';
  }

  @override
  String get calendarAllDayGutter => 'Sepanjang hari';

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count acara',
      one: '1 acara',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => 'Runtuhkan acara sepanjang hari';

  @override
  String get calendarExpandAllDay => 'Kembangkan acara sepanjang hari';

  @override
  String get calendarViewMonth => 'Bulan';

  @override
  String get calendarViewWeek => 'Minggu';

  @override
  String get calendarViewAgenda => 'Agenda';

  @override
  String get calendarConnectGoogle => 'Sambung Google Calendar';

  @override
  String get calendarConnectDescription =>
      'Segerakkan Google Calendar anda untuk melihat acara di sini dan mendapat amaran sebelum mesyuarat bermula.';

  @override
  String get calendarDisconnect => 'Putuskan';

  @override
  String get calendarReconnect => 'Sambung semula';

  @override
  String get calendarEmptyNoEvents => 'Tiada acara dalam julat ini';

  @override
  String get calendarStartRecording => 'Mula rakaman';

  @override
  String get calendarStartRecordingAndLink => 'Mula rakaman & pautkan';

  @override
  String get calendarJoinMeet => 'Sertai mesyuarat';

  @override
  String get calendarFromCalendar => 'Dari kalendar';

  @override
  String get calendarLinkedMeeting => 'Mesyuarat dipautkan';

  @override
  String get calendarToday => 'Hari ini';

  @override
  String get calendarAllDay => 'Sepanjang hari';

  @override
  String calendarWeekNumber(int number) {
    return 'Minggu $number';
  }

  @override
  String get calendarPreviousPeriod => 'Sebelumnya';

  @override
  String get calendarNextPeriod => 'Seterusnya';

  @override
  String calendarLastSynced(String time) {
    return 'Disegerakkan $time';
  }

  @override
  String get calendarNeverSynced => 'Belum disegerakkan';

  @override
  String get calendarSyncing => 'Menyegerakkan…';

  @override
  String get calendarViewDay => 'Hari';

  @override
  String get calendarShow => 'Tunjuk';

  @override
  String get calendarHide => 'Sembunyi';

  @override
  String get calendarRsvpGoing => 'Hadir?';

  @override
  String get calendarRsvpYes => 'Ya';

  @override
  String get calendarRsvpNo => 'Tidak';

  @override
  String get calendarRsvpMaybe => 'Mungkin';

  @override
  String get calendarRsvpFailed => 'Tidak dapat mengemas kini jawapan anda';

  @override
  String get calendarAddAccount => 'Tambah akaun kalendar';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Sambungkan akaun Google untuk menyegerakkan acara ke ruang kerja ini.';

  @override
  String get calendarConnecting => 'Menyambung…';

  @override
  String get calendarSyncNow => 'Segerak sekarang';

  @override
  String get calendarNoWorkspace =>
      'Pilih ruang kerja untuk melihat kalendarnya';

  @override
  String get calendarConnectError => 'Tidak dapat menyambung Google Calendar';

  @override
  String get calendarClientIdLabel => 'Client ID';

  @override
  String get calendarClientSecretLabel => 'Rahsia klien';

  @override
  String get calendarConnectCredsHint =>
      'Masukkan ID klien kod peranti OAuth Google dan rahsia untuk projek anda. Pelayan menjalankan sambungan dan segerak — penyemak imbas anda tidak pernah memegang token.';

  @override
  String get calendarConnectApproveInstruction =>
      'Buka halaman pengesahan pada mana-mana peranti, log masuk dan masukkan kod ini:';

  @override
  String get calendarConnectOpenPage => 'Buka halaman pengesahan';

  @override
  String get calendarConnectWaiting => 'Menunggu kelulusan…';

  @override
  String get calendarConnectDenied => 'Kebenaran ditolak. Sila cuba lagi.';

  @override
  String get calendarConnectExpired => 'Kod telah luput. Sila cuba lagi.';

  @override
  String get notificationMeetingStartsSoon =>
      'Mesyuarat akan bermula tidak lama lagi';

  @override
  String get notifyMeetingStartsSoon =>
      'Apabila mesyuarat kalendar hampir bermula';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Kalendar terputus';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Sambung semula $email untuk menyambung segerak';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Sambung semula kalendar anda untuk menyambung segerak';

  @override
  String get notifyCalendarAuthExpired =>
      'Apabila akaun kalendar perlu disambung semula';

  @override
  String get notificationRigStatusChanged => 'Kemas kini persekitaran terasing';

  @override
  String get notifyRigStatusChanged =>
      'Apabila persekitaran terasing diambil alih, dituntut semula atau gagal';

  @override
  String get notificationRigTakenOver => 'Persekitaran terasing diambil alih';

  @override
  String get notificationRigTakenOverBody =>
      'Seseorang sedang memandu mesin; ejen boleh menonton tetapi tidak bertindak.';

  @override
  String get notificationRigReleased =>
      'Kawalan persekitaran terasing dilepaskan';

  @override
  String get notificationRigReleasedBody => 'Ejen mempunyai mesin kembali.';

  @override
  String get notificationRigReclaimed =>
      'Persekitaran terasing dituntut semula';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'Ia terbiar, jadi mesin ditutup untuk membebaskan memori.';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'Ia mencapai had masanya dan ditutup.';

  @override
  String get notificationRigFailed => 'Persekitaran terasing gagal';

  @override
  String get notificationRigFailedBody =>
      'Hipervisor mati di bawahnya. Buka semula mesin untuk meneruskan.';

  @override
  String get calendarAlertLeadTime => 'Masa amaran awal';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'Berapa lama sebelum mesyuarat untuk memberi amaran kepada anda';

  @override
  String calendarConnectedAs(String email) {
    return 'Disambungkan sebagai $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count hadirin';
  }

  @override
  String get calendarEventLabel => 'Acara';

  @override
  String get calendarRecurring => 'Acara berulang';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Penganjur';

  @override
  String get calendarYou => 'Anda';

  @override
  String get calendarShowFewer => 'Tunjuk lebih sedikit';

  @override
  String get calendarRsvpAwaiting => 'Menunggu';

  @override
  String calendarParticipantsCount(int count) {
    return '$count peserta';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'Lihat semua $count peserta';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count ya';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count tidak';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count mungkin';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count menunggu';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count minit';
  }

  @override
  String get openInEditorPrompt => 'Buka dalam editor yang mana?';

  @override
  String get ideNotInstalled => 'Tidak dipasang';

  @override
  String openInIde(String editor) {
    return 'Buka dalam $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'Tidak dapat membuka $editor: $error';
  }

  @override
  String get profileSearchHint => 'Cari pull request…';

  @override
  String get stopAgentRun => 'Henti larian';

  @override
  String get stopAgentRunConfirm =>
      'Hentikan larian ini? Kerja yang sedang berjalan akan hilang.';

  @override
  String get inProgress => 'Sedang berjalan';

  @override
  String get drafts => 'Draf';

  @override
  String get sortOldest => 'Tertua';

  @override
  String get sortLargest => 'Terbesar';

  @override
  String get prFilterTooltip => 'Tapis';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count penapis aktif',
      one: '1 penapis aktif',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'Tambah penapis…';

  @override
  String get prFilterFieldHint => 'Tapis…';

  @override
  String get prFilterCategoryStatus => 'Status';

  @override
  String get prFilterCategoryAuthor => 'Pengarang';

  @override
  String get prFilterCategoryReviewer => 'Penyemak';

  @override
  String get prFilterCategoryContent => 'Kandungan';

  @override
  String get prFilterCategoryRepoOwner => 'Pemilik repositori';

  @override
  String get prFilterCategoryRepoName => 'Nama repositori';

  @override
  String get prFilterCategoryOpenedDate => 'Tarikh dibuka';

  @override
  String get prFilterCategoryUpdatedDate => 'Tarikh dikemas kini';

  @override
  String get prFilterQuickToReview => 'Cepat untuk disemak';

  @override
  String get prFilterClearAll => 'Kosongkan penapis';

  @override
  String prFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request',
      one: '1 pull request',
    );
    return '$_temp0';
  }

  @override
  String prFilterHiddenOptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pilihan tidak sepadan dengan mana-mana pull request',
      one: '1 pilihan tidak sepadan dengan mana-mana pull request',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'Tajuk atau badan mengandungi…';

  @override
  String get prFilterNoOptions => 'Tiada pilihan yang sepadan';

  @override
  String get prFilterChipIs => 'ialah';

  @override
  String get prFilterChipIsAnyOf => 'ialah mana-mana';

  @override
  String get prFilterChipContains => 'mengandungi';

  @override
  String get prFilterChipSince => 'sejak';

  @override
  String get prFilterAddFilterButton => 'Tambah penapis';

  @override
  String prFilterClearCategory(String category) {
    return 'Kosongkan penapis $category';
  }

  @override
  String get prFilterCurrentUser => 'Pengguna semasa';

  @override
  String get prStatusDraft => 'Draf';

  @override
  String get prStatusOpen => 'Terbuka';

  @override
  String get prStatusInReview => 'Dalam semakan';

  @override
  String get prStatusChangesRequested => 'Perubahan diminta';

  @override
  String get prStatusApproved => 'Diluluskan';

  @override
  String get prStatusMerged => 'Dicantum';

  @override
  String get prStatusClosed => 'Ditutup';

  @override
  String get prDateWindowDay => '1 hari yang lalu';

  @override
  String get prDateWindowThreeDays => '3 hari yang lalu';

  @override
  String get prDateWindowWeek => '1 minggu yang lalu';

  @override
  String get prDateWindowMonth => '1 bulan yang lalu';

  @override
  String get prDateWindowThreeMonths => '3 bulan yang lalu';

  @override
  String get prDateWindowSixMonths => '6 bulan yang lalu';

  @override
  String get prDateWindowYear => '1 tahun yang lalu';

  @override
  String get prDisplayOptions => 'Pilihan paparan';

  @override
  String get prDisplayGrouping => 'Pengumpulan';

  @override
  String get prDisplayOrdering => 'Penyusunan';

  @override
  String get prDisplayShowDrafts => 'Tunjuk draf';

  @override
  String get prDisplayMergedWindow => 'Tetingkap dicantum';

  @override
  String get prDisplayMergedWindowDay => 'Hari lalu';

  @override
  String get prDisplayMergedWindowWeek => 'Minggu lalu';

  @override
  String get prDisplayMergedWindowMonth => 'Bulan lalu';

  @override
  String get prDisplayProperties => 'Sifat paparan';

  @override
  String get prGroupingRepository => 'Repositori';

  @override
  String get prGroupingAuthor => 'Pengarang';

  @override
  String get prGroupingStatus => 'Status';

  @override
  String get prGroupingNone => 'Tiada pengumpulan';

  @override
  String get prPropertyRepository => 'Repositori';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'Cawangan';

  @override
  String get prPropertyUpdated => 'Dikemas kini';

  @override
  String get prPropertyAuthor => 'Pengarang';

  @override
  String get prPropertyChecks => 'Semakan';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'Komen';

  @override
  String get keybindingOpenFilterMenu => 'Buka menu penapis';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'Buka menu penapis pull request';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dipilih',
      one: '1 dipilih',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'Ringkasan';

  @override
  String get kbMove => 'alih';

  @override
  String get kbTabs => 'tab';

  @override
  String get kbSearch => 'cari';

  @override
  String get kbViewed => 'dilihat';

  @override
  String get kbCollapse => 'runtuh';

  @override
  String get appearance => 'Penampilan';

  @override
  String get appearanceSettingsDescription => 'Tema, bahasa dan tipografi.';

  @override
  String get notificationsSettingsDescription =>
      'Pilih peristiwa ejen dan ruang kerja mana yang memberitahu anda.';

  @override
  String get advanced => 'Lanjutan';

  @override
  String get accounts => 'Akaun';

  @override
  String get mcpServers => 'Pelayan MCP';

  @override
  String get mcpServersSettingsDescription =>
      'Pelayan MCP terbina dan pelayan MCP luaran.';

  @override
  String get remoteControlAndDevices => 'Kawalan jauh & peranti';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'Pasangkan telefon dan konfigurasikan pelayan kawalan jauh.';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'Model pertuturan dan diarisasi yang pelayan ini hoskan.';

  @override
  String get needsSetupLabel => 'Perlu persediaan';

  @override
  String get collapseSidebar => 'Runtuhkan bar sisi';

  @override
  String get expandSidebar => 'Kembangkan bar sisi';

  @override
  String get filterSpacesHint => 'Tapis ruang';

  @override
  String noSpacesMatch(String query) {
    return 'Tiada ruang sepadan dengan \"$query\"';
  }

  @override
  String get privacy => 'Privasi';

  @override
  String get sendDiffContentTitle => 'Hantar kandungan diff ke penyesuai AI';

  @override
  String get diffSharingOnSubtitle =>
      'Baris diff mentah disertakan dalam prompt ejen untuk semakan lebih mendalam.';

  @override
  String get diffSharingOffSubtitle =>
      'Ejen menggunakan metadata berstruktur sahaja (laluan fail, nombor baris, perihalan PR); tiada kod mentah meninggalkan apl.';

  @override
  String get errorReportingTitle => 'Kongsi laporan ranap';

  @override
  String get errorReportingOnSubtitle =>
      'Diagnostik ranap, ralat dan prestasi dihantar untuk membantu membetulkan pepijat (binaan keluaran sahaja).';

  @override
  String get errorReportingOffSubtitle =>
      'Diagnostik dimatikan. Tiada laporan ranap atau ralat dihantar.';

  @override
  String get onboardingDiagnosticsTitle => 'Bantu perbaiki Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Hantar diagnostik ranap, ralat dan prestasi supaya kami dapat membetulkan masalah lebih cepat (binaan keluaran sahaja). Anda boleh mengubah ini pada bila-bila masa dalam Tetapan → Privasi.';

  @override
  String get blocked => 'Disekat';

  @override
  String get idle => 'Terlengah';

  @override
  String get noRunsYet => 'Belum ada larian';

  @override
  String get copyPath => 'Salin laluan';

  @override
  String get copyRelativePath => 'Salin laluan relatif';

  @override
  String get nameRequired => 'Nama diperlukan';

  @override
  String get import => 'Import';

  @override
  String get noMatchingAgents => 'Tiada ejen sepadan dengan penapis anda';

  @override
  String watchVideoOn(String provider) {
    return 'Tonton video di $provider';
  }

  @override
  String get branchTemplate => 'Templat nama cawangan';

  @override
  String get branchTemplateDescription =>
      'Corak untuk cawangan yang dicipta apabila tiket dimulakan dalam worktree terasing.';

  @override
  String branchTemplatePreview(String example) {
    return 'Contoh: $example';
  }

  @override
  String get deletePipelineRun => 'Padam larian pipeline';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Padam larian \"$template\" ini? Ini tidak boleh dibuat asal.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Ralat memadam larian pipeline: $error';
  }

  @override
  String get deleteTicket => 'Padam tiket';

  @override
  String deleteTicketConfirm(String title) {
    return 'Padam \"$title\"? Ini tidak boleh dibuat asal.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Ralat memadam tiket: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return 'Padam \"$name\"? Repositori terpaut pada cakera tidak disentuh.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Ralat memadam ruang kerja: $error';
  }

  @override
  String get indexCode => 'Indeks kod';

  @override
  String get indexNoGrammars => 'Tatabahasa kod tidak dipasang';

  @override
  String get indexFailed => 'Pengindeksan gagal';

  @override
  String indexedSymbolsCount(int count) {
    return '$count simbol diindeks';
  }

  @override
  String get nodeConfigAdvanced => 'Lanjutan';

  @override
  String get nodeConfigReducer => 'Pengurang';

  @override
  String get nodeConfigReducerHelp =>
      'Cara mencantum apabila kunci output ini sudah mempunyai nilai';

  @override
  String get nodeConfigTimeoutMs => 'Tamat masa (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Percubaan semula';

  @override
  String get nodeConfigContinueOnFail => 'Teruskan jika langkah ini gagal';

  @override
  String get nodeConfigTeamId => 'ID pasukan';

  @override
  String get nodeConfigDispatchMode => 'Modus penghantaran';

  @override
  String get nodeConfigOutputSchema => 'Skema output (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'JSON Schema yang output langkah mesti penuhi';

  @override
  String get diffLineDisplay => 'Baris panjang dalam diff';

  @override
  String get diffLineDisplayDescription =>
      'Balut baris panjang atau tatalnya secara mendatar';

  @override
  String get diffLineWrap => 'Balut';

  @override
  String get diffLineScroll => 'Tatal mendatar';

  @override
  String get actions => 'Tindakan';

  @override
  String get activate => 'Aktifkan';

  @override
  String get activity => 'Aktiviti';

  @override
  String get activityLabel => 'AKTIVITI';

  @override
  String get activitySearchHint => 'Cari aktiviti';

  @override
  String get activityNoMatches => 'Tiada aktiviti sepadan dengan penapis anda';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end daripada $total';
  }

  @override
  String get activityPreviousPage => 'Halaman sebelumnya';

  @override
  String get activityNextPage => 'Halaman seterusnya';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'Kosongkan penapis';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return 'Negara $country';
  }

  @override
  String get activitySavedWorkspaceLogo => 'Logo ruang kerja disimpan';

  @override
  String activityVerbCreated(String target) {
    return 'Mencipta $target';
  }

  @override
  String activityVerbUpdated(String target) {
    return 'Mengemas kini $target';
  }

  @override
  String activityVerbDeleted(String target) {
    return 'Memadam $target';
  }

  @override
  String activityVerbAdded(String target) {
    return 'Menambah $target';
  }

  @override
  String activityVerbRemoved(String target) {
    return 'Membuang $target';
  }

  @override
  String activityVerbInvited(String target) {
    return 'Menjemput $target';
  }

  @override
  String activityVerbChanged(String target) {
    return 'Mengubah $target';
  }

  @override
  String activityVerbStarted(String target) {
    return 'Memulakan $target';
  }

  @override
  String activityVerbStopped(String target) {
    return 'Menghentikan $target';
  }

  @override
  String activityVerbWrote(String target) {
    return 'Menulis $target';
  }

  @override
  String get activityTargetAgent => 'ejen';

  @override
  String get activityTargetTicket => 'tiket';

  @override
  String get activityTargetWorkspace => 'ruang kerja';

  @override
  String get activityTargetRepository => 'repositori';

  @override
  String get activityTargetMember => 'ahli';

  @override
  String get activityTargetInvite => 'jemputan';

  @override
  String get activityTargetSpace => 'ruang';

  @override
  String get activityTargetMessage => 'mesej';

  @override
  String get activityTargetCache => 'cache';

  @override
  String get activityTargetFile => 'fail';

  @override
  String get activityTargetPipeline => 'pipeline';

  @override
  String get activityTargetTemplate => 'templat';

  @override
  String get activityTargetProvider => 'penyedia';

  @override
  String get activityTargetModel => 'model';

  @override
  String get activityTargetSkill => 'kemahiran';

  @override
  String get activityTargetTodo => 'tugasan';

  @override
  String get activityTargetMeeting => 'mesyuarat';

  @override
  String get activityTargetProject => 'projek';

  @override
  String get activityTargetTeam => 'pasukan';

  @override
  String get activityTargetDevice => 'peranti';

  @override
  String get activityTargetPreference => 'keutamaan';

  @override
  String get activityTargetBudget => 'bajet';

  @override
  String activityVerbApproved(String target) {
    return 'Meluluskan $target';
  }

  @override
  String activityVerbArchived(String target) {
    return 'Mengarkibkan $target';
  }

  @override
  String activityVerbAssigned(String target) {
    return 'Menugaskan $target';
  }

  @override
  String activityVerbBackedUp(String target) {
    return 'Menyandarkan $target';
  }

  @override
  String activityVerbCancelled(String target) {
    return 'Membatalkan $target';
  }

  @override
  String activityVerbCleared(String target) {
    return 'Mengosongkan $target';
  }

  @override
  String activityVerbClosed(String target) {
    return 'Menutup $target';
  }

  @override
  String activityVerbCommitted(String target) {
    return 'Commit $target';
  }

  @override
  String activityVerbCompacted(String target) {
    return 'Memampatkan $target';
  }

  @override
  String activityVerbCompleted(String target) {
    return 'Menyelesaikan $target';
  }

  @override
  String activityVerbConnected(String target) {
    return 'Menyambungkan $target';
  }

  @override
  String activityVerbContinued(String target) {
    return 'Meneruskan $target';
  }

  @override
  String activityVerbDisconnected(String target) {
    return 'Memutuskan $target';
  }

  @override
  String activityVerbDispatched(String target) {
    return 'Menghantar $target';
  }

  @override
  String activityVerbDrained(String target) {
    return 'Mengosongkan $target';
  }

  @override
  String activityVerbEnrolled(String target) {
    return 'Mendaftarkan $target';
  }

  @override
  String activityVerbEstimated(String target) {
    return 'Menganggar $target';
  }

  @override
  String activityVerbImported(String target) {
    return 'Mengimport $target';
  }

  @override
  String activityVerbInstalled(String target) {
    return 'Memasang $target';
  }

  @override
  String activityVerbKilled(String target) {
    return 'Menghentikan $target';
  }

  @override
  String activityVerbMarked(String target) {
    return 'Menandakan $target';
  }

  @override
  String activityVerbMerged(String target) {
    return 'Mencantumkan $target';
  }

  @override
  String activityVerbOpened(String target) {
    return 'Membuka $target';
  }

  @override
  String activityVerbPaused(String target) {
    return 'Menjeda $target';
  }

  @override
  String activityVerbPolled(String target) {
    return 'Mengundi $target';
  }

  @override
  String activityVerbPrepared(String target) {
    return 'Menyediakan $target';
  }

  @override
  String activityVerbProcessed(String target) {
    return 'Memproses $target';
  }

  @override
  String activityVerbPublished(String target) {
    return 'Menerbitkan $target';
  }

  @override
  String activityVerbRefined(String target) {
    return 'Memperhalusi $target';
  }

  @override
  String activityVerbRefreshed(String target) {
    return 'Memuat semula $target';
  }

  @override
  String activityVerbRegistered(String target) {
    return 'Mendaftarkan $target';
  }

  @override
  String activityVerbRenamed(String target) {
    return 'Menamakan semula $target';
  }

  @override
  String activityVerbReordered(String target) {
    return 'Menyusun semula $target';
  }

  @override
  String activityVerbResponded(String target) {
    return 'Membalas $target';
  }

  @override
  String activityVerbRestored(String target) {
    return 'Memulihkan $target';
  }

  @override
  String activityVerbResumed(String target) {
    return 'Menyambung $target';
  }

  @override
  String activityVerbRetried(String target) {
    return 'Mencuba semula $target';
  }

  @override
  String activityVerbReverted(String target) {
    return 'Mengembalikan $target';
  }

  @override
  String activityVerbReviewed(String target) {
    return 'Menyemak $target';
  }

  @override
  String activityVerbRan(String target) {
    return 'Menjalankan $target';
  }

  @override
  String activityVerbSelected(String target) {
    return 'Memilih $target';
  }

  @override
  String activityVerbSent(String target) {
    return 'Menghantar $target';
  }

  @override
  String activityVerbStaged(String target) {
    return 'Menyediakan $target';
  }

  @override
  String activityVerbSteered(String target) {
    return 'Mengemudi $target';
  }

  @override
  String activityVerbSubmitted(String target) {
    return 'Menyerahkan $target';
  }

  @override
  String activityVerbSynced(String target) {
    return 'Menyegerakkan $target';
  }

  @override
  String activityVerbToggled(String target) {
    return 'Menogol $target';
  }

  @override
  String activityVerbUninstalled(String target) {
    return 'Menyahpasang $target';
  }

  @override
  String activityVerbUnstaged(String target) {
    return 'Menyahsediakan $target';
  }

  @override
  String get activityTargetActionPolicy => 'polisi tindakan';

  @override
  String get activityTargetGoalRun => 'larian matlamat';

  @override
  String get activityTargetRunLog => 'log larian';

  @override
  String get activityTargetWorkingMemory => 'memori kerja';

  @override
  String get activityTargetRoutingPolicy => 'polisi penghalaan';

  @override
  String get activityTargetAutonomy => 'autonomi';

  @override
  String get activityTargetCalendar => 'kalendar';

  @override
  String get activityTargetChecker => 'penyemak';

  @override
  String get activityTargetEditor => 'editor';

  @override
  String get activityTargetConfirmation => 'pengesahan';

  @override
  String get activityTargetTunnel => 'terowong';

  @override
  String get activityTargetConversation => 'perbualan';

  @override
  String get activityTargetCredentials => 'kelayakan';

  @override
  String get activityTargetDictation => 'dikte';

  @override
  String get activityTargetAgentRun => 'larian ejen';

  @override
  String get activityTargetEvalSuite => 'suite eval';

  @override
  String get activityTargetWorker => 'pekerja';

  @override
  String get activityTargetWorktree => 'worktree';

  @override
  String get activityTargetMcpServer => 'pelayan MCP';

  @override
  String get activityTargetMemoryAccessGrant => 'geran akses memori';

  @override
  String get activityTargetMemoryDomain => 'domain memori';

  @override
  String get activityTargetMemoryFact => 'fakta memori';

  @override
  String get activityTargetMemoryPolicy => 'polisi memori';

  @override
  String get activityTargetFeed => 'suapan';

  @override
  String get activityTargetNote => 'nota';

  @override
  String get activityTargetOrchestration => 'orkestrasi';

  @override
  String get activityTargetPipelineRun => 'larian pipeline';

  @override
  String get activityTargetPipelineTrigger => 'pencetus pipeline';

  @override
  String get activityTargetPlan => 'rancangan';

  @override
  String get activityTargetPlaybook => 'buku panduan';

  @override
  String get activityTargetPullRequest => 'pull request';

  @override
  String get activityTargetReview => 'semakan';

  @override
  String get activityTargetProcess => 'proses';

  @override
  String get activityTargetProviderPolicy => 'polisi penyedia';

  @override
  String get activityTargetReaction => 'tindak balas';

  @override
  String get activityTargetReviewSpace => 'ruang semakan';

  @override
  String get activityTargetReviewStudio => 'studio semakan';

  @override
  String get activityTargetServerData => 'data pelayan';

  @override
  String get activityTargetSoundscape => 'landskap bunyi';

  @override
  String get activityTargetSession => 'sesi';

  @override
  String get activityTargetTerminal => 'terminal';

  @override
  String get activityTargetTicketLink => 'pautan tiket';

  @override
  String get activityTargetTicketSync => 'segerak tiket';

  @override
  String get activityTargetProfile => 'profil';

  @override
  String get activityTargetVoiceProfile => 'profil suara';

  @override
  String get activityTargetWeather => 'ramalan cuaca';

  @override
  String get activityTargetWorkProduct => 'hasil kerja';

  @override
  String get activityChangedMemberRole => 'Mengubah peranan ahli';

  @override
  String get activityChangedMemberRepoAccess =>
      'Mengubah akses repositori ahli';

  @override
  String get activityUpdatedGitHubToken => 'Mengemas kini token GitHub';

  @override
  String get activityRefreshedWeather => 'Memuat semula ramalan cuaca';

  @override
  String get activitySetWeatherLocation => 'Menetapkan lokasi cuaca';

  @override
  String get activityClearedWeatherLocation => 'Mengosongkan lokasi cuaca';

  @override
  String get activityMarkedAllArticlesRead =>
      'Menandakan semua artikel sebagai dibaca';

  @override
  String get activityMarkedArticleRead => 'Menandakan artikel sebagai dibaca';

  @override
  String get activityUpdatedSavedArticle => 'Mengemas kini artikel tersimpan';

  @override
  String get activityTookOverSession => 'Mengambil alih sesi';

  @override
  String get activityHandedBackSession => 'Menyerahkan semula sesi';

  @override
  String get activityCommittedAndPushed => 'Commit dan push';

  @override
  String get activityBackedUpServer => 'Menyandarkan data pelayan';

  @override
  String get activityMarkedSpaceRead => 'Menandakan ruang sebagai dibaca';

  @override
  String get activityRespondedToInvitation => 'Membalas jemputan acara';

  @override
  String get activityStartedCalendarConnect => 'Memulakan sambungan kalendar';

  @override
  String get activityDisconnectedCalendar => 'Memutuskan kalendar';

  @override
  String get activityMarkedFileViewed => 'Menandakan fail sebagai dilihat';

  @override
  String get activityRespondedToApproval => 'Membalas permintaan kelulusan';

  @override
  String get activityChangedTunnel => 'Mengubah tetapan terowong';

  @override
  String get activitySentMessageToAgent => 'Menghantar mesej kepada ejen';

  @override
  String get activityOpenedReviewSpace => 'Membuka ruang semakan';

  @override
  String get activityOpenedStandingConversation => 'Membuka perbualan tetap';

  @override
  String get activityStartedRecording => 'Memulakan rakaman';

  @override
  String get activityStoppedRecording => 'Menghentikan rakaman';

  @override
  String get activityToggledMcpServer => 'Menogol pelayan MCP';

  @override
  String get activityUpdatedMcpToken => 'Mengemas kini token MCP';

  @override
  String get activitySavedApiKey => 'Menyimpan kunci API';

  @override
  String get activityRemovedProviderCredential => 'Membuang kelayakan penyedia';

  @override
  String get activityUpdatedLinkedRepos => 'Mengemas kini repositori terpaut';

  @override
  String get activityUnlinkedRepo => 'Menyahpaut repositori';

  @override
  String get activityUpdatedActionItem => 'Mengemas kini item tindakan';

  @override
  String adRulesCount(int count) {
    return '$count peraturan iklan';
  }

  @override
  String get adapter => 'Penyesuai';

  @override
  String get adapterLabel => 'Penyesuai';

  @override
  String get adapters => 'Penyesuai';

  @override
  String get adaptersAutoDetected =>
      'Pelari ejen yang dikesan secara automatik pada mesin ini. Pasang alat CLI yang hilang untuk mendayakan pelari tambahan.';

  @override
  String get add => 'Tambah';

  @override
  String get addAComment => 'Tambah komen';

  @override
  String get addAReaction => 'Tambah tindak balas';

  @override
  String get addASuggestion => 'Tambah cadangan';

  @override
  String get addAgents => 'Tambah ejen';

  @override
  String get addEmoji => 'Tambah emoji';

  @override
  String get addFeed => 'Tambah suapan';

  @override
  String get addressBarHint => 'Masukkan URL';

  @override
  String get addFromFile => 'Tambah dari fail';

  @override
  String get addGif => 'Tambah GIF';

  @override
  String get addGithubRepoPrompt =>
      'Tambah sekurang-kurangnya satu repositori GitHub untuk melihat pull request';

  @override
  String get addLocalCheckoutDescription =>
      'Tambah checkout setempat untuk mula menyasarinya dari ruang kerja ini.';

  @override
  String get addRepository => 'Tambah repositori';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tambah $count repositori',
      one: 'Tambah repositori',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'Semak imbas folder pada mesin yang menjalankan pelayan dan pilih checkout git untuk didaftarkan.';

  @override
  String get selectThisFolder => 'Pilih folder ini';

  @override
  String get deselectThisFolder => 'Nyahpilih folder ini';

  @override
  String get goUp => 'Naik';

  @override
  String get noSubfoldersHere => 'Tiada subfolder di sini';

  @override
  String get notAGitRepository => 'Folder ini bukan repositori git.';

  @override
  String get addToken => 'Tambah token';

  @override
  String get addWorkspace => 'Tambah ruang kerja';

  @override
  String get addWorkspaceEllipsis => 'Tambah ruang kerja…';

  @override
  String get added => 'Ditambah';

  @override
  String get addingEllipsis => 'Menambah…';

  @override
  String get advancedLabel => 'Lanjutan';

  @override
  String get agent => 'Ejen';

  @override
  String agentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ejen',
      one: '1 ejen',
    );
    return '$_temp0';
  }

  @override
  String get agentMdPath => 'Laluan Agent MD';

  @override
  String get agentName => 'Nama ejen';

  @override
  String get agentTitle => 'Tajuk ejen';

  @override
  String get agentUpdated => 'Ejen dikemas kini.';

  @override
  String get agents => 'Ejen';

  @override
  String get agentsMentionSection => 'Ejen';

  @override
  String get usersMentionSection => 'Orang';

  @override
  String get ticketsMentionSection => 'Tiket';

  @override
  String get pullRequestsMentionSection => 'Pull request';

  @override
  String get meetingsMentionSection => 'Mesyuarat';

  @override
  String get entityRefTicketFallback => 'Tiket';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'Mesyuarat';

  @override
  String get aiReview => 'Semakan AI';

  @override
  String get all => 'Semua';

  @override
  String get allAgentsAlreadyInSpace => 'Semua ejen sudah ada dalam ruang ini.';

  @override
  String get allCommits => 'Semua commit';

  @override
  String get allSources => 'Semua sumber';

  @override
  String get allow => 'Benarkan';

  @override
  String get allowGitPush => 'Benarkan git push';

  @override
  String get allowGithubApi => 'Benarkan panggilan API GitHub';

  @override
  String get allowNetwork => 'Benarkan akses rangkaian am';

  @override
  String get apiKeys => 'Kunci API';

  @override
  String get appFont => 'Fon apl';

  @override
  String get appLogLevelDebugDescription =>
      'Menambah jejak terperinci - untuk pembangunan.';

  @override
  String get appLogLevelDebugLabel => 'Nyahpepijat';

  @override
  String get appLogLevelErrorDescription =>
      'Hanya ralat dan pengecualian yang tidak dijangka.';

  @override
  String get appLogLevelErrorLabel => 'Ralat';

  @override
  String get appLogLevelInfoDescription =>
      'Menambah mesej kitaran hayat dan status.';

  @override
  String get appLogLevelInfoLabel => 'Maklumat';

  @override
  String get appLogLevelNoneDescription => 'Tiada output konsol langsung.';

  @override
  String get appLogLevelNoneLabel => 'Tiada';

  @override
  String get appLogLevelVerboseDescription =>
      'Semuanya. Sangat bising - gunakan untuk nyahpepijat sahaja.';

  @override
  String get appLogLevelVerboseLabel => 'Terperinci';

  @override
  String get appLogLevelWarningDescription =>
      'Menambah amaran dan isu yang boleh dipulihkan.';

  @override
  String get appLogLevelWarningLabel => 'Amaran';

  @override
  String get appearanceLanguage => 'Penampilan & bahasa';

  @override
  String get apply => 'Terapkan';

  @override
  String get approve => 'Luluskan';

  @override
  String get agentApprovalRequired => 'Kelulusan diperlukan';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lagi menunggu',
      one: '1 lagi menunggu',
    );
    return '$_temp0';
  }

  @override
  String get approved => 'Diluluskan';

  @override
  String get articleNoun => 'Artikel';

  @override
  String get articlesSubscribed => 'Artikel merentasi suapan langganan anda.';

  @override
  String get askAi => 'Tanya AI';

  @override
  String get askAiReviewDescription => 'Minta AI menyemak PR ini';

  @override
  String get assignees => 'Penerima tugasan';

  @override
  String get attachImage => 'Lampirkan imej';

  @override
  String get attachedAgents => 'Ejen dilampirkan';

  @override
  String get audioInput => 'Input audio';

  @override
  String get audioOutput => 'Output audio';

  @override
  String get authenticationToken => 'Token pengesahan';

  @override
  String authoredByLabel(String role) {
    return 'Oleh: $role';
  }

  @override
  String get autoRecommended => 'Auto (disyorkan)';

  @override
  String get available => 'Tersedia';

  @override
  String get awaitingYourReview => 'Menunggu semakan anda';

  @override
  String get back => 'Kembali';

  @override
  String get backLabel => 'Kembali';

  @override
  String get backend => 'Bahagian belakang';

  @override
  String get blockAdsTrackers => 'Sekat iklan, penjejak & sepanduk kuki';

  @override
  String get blocking => 'Menyekat';

  @override
  String get bookmarkLabel => 'Penanda halaman';

  @override
  String get briefDescription => 'Perihalan ringkas';

  @override
  String get bugLabel => 'PEPIJAT';

  @override
  String get bundledDefaultsNeverUpdated =>
      'Lalai dibungkus — tidak pernah dikemas kini';

  @override
  String get cancel => 'Batal';

  @override
  String get cancelEdit => 'Batal suntingan';

  @override
  String get categoryCreation => 'Penciptaan';

  @override
  String get categoryEditing => 'Penyuntingan';

  @override
  String get categoryNavigation => 'Navigasi';

  @override
  String get categorySystem => 'Sistem';

  @override
  String get categoryView => 'Paparan kategori';

  @override
  String get change => 'Tukar';

  @override
  String get changesRequested => 'Perubahan diminta';

  @override
  String get spacesMentionSection => 'Ruang';

  @override
  String get checkForUpdates => 'Semak kemas kini';

  @override
  String get checking => 'Menyemak';

  @override
  String get checkingEllipsis => 'Menyemak…';

  @override
  String get chooseAppFont => 'Pilih fon apl';

  @override
  String get chooseCodeFont => 'Pilih fon kod';

  @override
  String get chooseRunner => 'Pilih pelari ejen anda.';

  @override
  String get clear => 'Kosongkan';

  @override
  String get clickToRetry => 'Klik untuk cuba semula';

  @override
  String get close => 'Tutup';

  @override
  String get closeEsc => 'Tutup (Esc)';

  @override
  String get closeReader => 'Tutup pembaca';

  @override
  String get closed => 'Ditutup';

  @override
  String get codeFont => 'Fon kod';

  @override
  String get codeFontLigatures => 'Ligatur fon kod';

  @override
  String get codeFontLigaturesDescription =>
      'Paparkan ligatur pengaturcaraan (=>, !=, ->) sebagai glif gabungan dalam kod dan diff';

  @override
  String get collapse => 'Runtuhkan';

  @override
  String get commandPalette => 'Palet perintah';

  @override
  String get commandPaletteOrgMembers => 'Ahli organisasi';

  @override
  String get commandPaletteBrowseTeam => 'Semak imbas pasukan';

  @override
  String get commandPaletteBrowseTeamDesc => 'Lihat semua ahli organisasi';

  @override
  String get compactDone =>
      'Perbualan dimampatkan. Sejarah terdahulu dilipat ke dalam ringkasan.';

  @override
  String get compactNothing =>
      'Tiada apa untuk dimampatkan lagi. Perbualan masih pendek.';

  @override
  String get compactBusy =>
      'Ejen masih bekerja. Mampatkan apabila giliran selesai.';

  @override
  String get compactUnavailable =>
      'Pemampatan tidak tersedia pada pelayan ini.';

  @override
  String get commandsMentionSection => 'Perintah';

  @override
  String get comment => 'Komen';

  @override
  String get commentOnThisFile => 'Komen pada fail ini';

  @override
  String get commented => 'Dikomen';

  @override
  String get commits => 'Commit';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Menunjukkan $loaded terkini daripada $total commit';
  }

  @override
  String get prCloneProgressCloningTitle => 'Mengklon repositori';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'PR ini mengubah $fileCount fail, yang melebihi had API GitHub. Mengklon repositori secara setempat…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'PR ini melebihi had fail API GitHub. Mengklon repositori secara setempat…';

  @override
  String get prCloneProgressFetchingTitle => 'Mengambil ref PR';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Mengambil cawangan asas dan ref kepala PR…';

  @override
  String get prCloneProgressComputingTitle => 'Mengira diff';

  @override
  String get prCloneProgressComputingSubtitle =>
      'Menjalankan git diff secara setempat…';

  @override
  String get prCloneProgressErrorTitle => 'Gagal memuatkan diff';

  @override
  String get prCloneProgressErrorSubtitle =>
      'Ralat berlaku semasa mengklon atau mengira diff. Sila cuba muat semula.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Masih bekerja… $elapsed berlalu';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Keyakinan: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'Konfigurasikan identiti ejen, prompt, kemahiran dan lihat larian.';

  @override
  String get configureDefaultRunners =>
      'Konfigurasikan penyesuai dan model mana yang digunakan untuk ruang baharu dan penjanaan tajuk.';

  @override
  String get configuredLabel => 'Dikonfigurasikan.';

  @override
  String get confirmedBy => 'Disahkan oleh';

  @override
  String get consensus => 'Konsensus';

  @override
  String get contentHint => 'Apa yang patut diingat';

  @override
  String get contentLabel => 'Kandungan';

  @override
  String get contentMarkdown => 'Kandungan (Markdown)';

  @override
  String get contextWindowSize => 'Saiz tetingkap konteks';

  @override
  String modelContextChip(String size) {
    return 'Model · $size';
  }

  @override
  String get continueLabel => 'Teruskan';

  @override
  String get conversationMode => 'Modus';

  @override
  String cookieRulesCount(int count) {
    return '$count peraturan kuki';
  }

  @override
  String get copied => 'Disalin!';

  @override
  String get copy => 'Salin';

  @override
  String get copyAddress => 'Salin alamat';

  @override
  String get copyBaseBranchTooltip => 'Salin nama cawangan asas';

  @override
  String get copyHeadBranchTooltip => 'Salin nama cawangan kepala';

  @override
  String couldNotListDevices(String error) {
    return 'Tidak dapat menyenaraikan peranti: $error';
  }

  @override
  String get create => 'Cipta';

  @override
  String get createOrSelectWorkspace =>
      'Cipta atau pilih ruang kerja sebelum menambah repositori.';

  @override
  String get createPullRequest => 'Cipta pull request';

  @override
  String get createdByMe => 'Dicipta oleh saya';

  @override
  String createdLabel(String date) {
    return 'Dicipta: $date';
  }

  @override
  String get currentParticipants => 'Peserta semasa';

  @override
  String get customCapabilitiesDescription => 'Perihalan keupayaan tersuai';

  @override
  String get customSystemPrompt => 'Prompt sistem tersuai untuk ejen ini...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari yang lalu',
      one: '1 hari yang lalu',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Nyahaktifkan';

  @override
  String get defaultCapabilities => 'Keupayaan lalai · ruang baharu';

  @override
  String get defaultChat => 'Sembang lalai';

  @override
  String get defaultRunners => 'Pelari lalai';

  @override
  String get delete => 'Padam';

  @override
  String get deleteAgent => 'Padam ejen';

  @override
  String deleteAgentConfirm(String name) {
    return 'Padam \"$name\"? Ini tidak boleh dibuat asal.';
  }

  @override
  String get deleteSpace => 'Padam ruang';

  @override
  String deleteConfirmName(String name) {
    return 'Padam \"$name\"?';
  }

  @override
  String get archiveConversation => 'Arkibkan perbualan';

  @override
  String get deleteFact => 'Padam fakta';

  @override
  String get deleteFeedBody =>
      'Ini membuang suapan dan semua artikel cache-nya. Artikel yang ditanda halaman dari suapan ini juga akan dibuang.';

  @override
  String deleteFeedConfirm(String name) {
    return 'Padam \"$name\"?';
  }

  @override
  String get deletePolicy => 'Padam polisi';

  @override
  String get deletePolicyConfirm =>
      'Padam polisi ini? Ini tidak boleh dibuat asal.';

  @override
  String deleteTopicConfirm(String topic) {
    return 'Padam \"$topic\"? Ini tidak boleh dibuat asal.';
  }

  @override
  String get deleteWorkspace => 'Padam ruang kerja';

  @override
  String get deny => 'Tolak';

  @override
  String get detailsLabel => 'Butiran';

  @override
  String get descriptionLabel => 'Perihalan';

  @override
  String detectedBackend(String label) {
    return 'Dikesan: $label';
  }

  @override
  String get detectedRunners => 'Pelari dikesan';

  @override
  String get detectingAdapters => 'Mengesan penyesuai…';

  @override
  String get detectingInputDevices => 'Mengesan peranti input…';

  @override
  String detectionFailed(String error) {
    return 'Pengesanan gagal: $error';
  }

  @override
  String get disabled => 'Dilumpuhkan';

  @override
  String get discover => 'Temui';

  @override
  String get dismissed => 'Ditolak';

  @override
  String get domainHint => 'e.g. api-performance';

  @override
  String get domainLabel => 'Domain';

  @override
  String get download => 'Muat turun';

  @override
  String get downloadingLabel => 'Memuat turun';

  @override
  String downloadingModel(int pct) {
    return 'Memuat turun model… $pct%';
  }

  @override
  String get draft => 'Draf';

  @override
  String get draftLabel => 'Draf';

  @override
  String get edit => 'Sunting';

  @override
  String get edited => 'disunting';

  @override
  String get editMessage => 'Sunting mesej';

  @override
  String get deleteMessage => 'Padam mesej';

  @override
  String get deleteMessageConfirm =>
      'Padam mesej ini? Ini tidak boleh dibuat asal.';

  @override
  String get messageDeleted => 'Mesej dipadam';

  @override
  String get searchInConversation => 'Cari dalam perbualan';

  @override
  String get searchMessagesHint => 'Cari mesej…';

  @override
  String get noMessagesFound => 'Tiada mesej dijumpai';

  @override
  String get editFact => 'Sunting fakta';

  @override
  String get editPolicy => 'Sunting polisi';

  @override
  String get editSuggestedCodeHint => 'Sunting kod yang dicadangkan…';

  @override
  String get editSuggestion => 'Sunting cadangan';

  @override
  String get egArchitect => 'e.g. architect';

  @override
  String get egControlCenter => 'e.g. control-center';

  @override
  String get egPlatform => 'e.g. macOS';

  @override
  String get egSamuelAlev => 'e.g. SamuelAlev';

  @override
  String get egSoftwareArchitect => 'e.g. Software Architect';

  @override
  String get egTheVerge => 'e.g. The Verge';

  @override
  String get egTokenLimit => 'e.g. 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Pemasangan gagal: $error';
  }

  @override
  String get embeddingInstalled =>
      'Model embedding setempat dipasang. Carian hibrid didayakan.';

  @override
  String get embeddingModel => 'Model embedding (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Tidak dipasang. Carian jatuh kepada kata kunci sahaja sehingga didayakan.';

  @override
  String get embeddingRedownloadBody =>
      'Fail model sedia ada akan dipadam dan dimuat turun semula. Carian semantik tidak tersedia sehingga muat turun selesai.';

  @override
  String get embeddingRemoveBody =>
      'Carian semantik akan dilumpuhkan sehingga anda memasangnya semula. Anda boleh memasangnya lagi pada bila-bila masa.';

  @override
  String get speakerDiarization => 'Diarisasi penutur';

  @override
  String get diarizationModel => 'Model diarisasi';

  @override
  String get diarizationInstalled =>
      'Dipasang — menamakan penutur individu dalam transkrip mesyuarat';

  @override
  String get diarizationNotInstalled =>
      'Tidak dipasang — penutur mesyuarat tidak akan dipisahkan';

  @override
  String diarizationInstallFailed(String error) {
    return 'Pemasangan gagal: $error';
  }

  @override
  String get redownloadDiarizationModel => 'Muat turun semula model diarisasi';

  @override
  String get diarizationRedownloadBody =>
      'Ini membuang model diarisasi semasa dan memuat turunnya semula.';

  @override
  String get removeDiarizationModel => 'Buang model diarisasi';

  @override
  String get diarizationRemoveBody =>
      'Ini memadam model diarisasi pada peranti. Transkrip mesyuarat yang sudah dihasilkan tidak terjejas.';

  @override
  String get enableNotifications => 'Dayakan pemberitahuan';

  @override
  String get enableSandboxing => 'Dayakan kotak pasir';

  @override
  String get enabled => 'Didayakan';

  @override
  String errorCreatingAgent(String error) {
    return 'Ralat mencipta ejen: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Ralat memadam ejen: $error';
  }

  @override
  String errorWithDetail(String error) {
    return 'Ralat: $error';
  }

  @override
  String get expand => 'Kembangkan';

  @override
  String extractingModel(int pct) {
    return 'Mengekstrak model… $pct%';
  }

  @override
  String get fact => 'Fakta';

  @override
  String factCount(int count) {
    return '$count fakta';
  }

  @override
  String factCountPlural(int count) {
    return '$count fakta';
  }

  @override
  String get facts => 'Fakta';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount fakta · $policyCount polisi';
  }

  @override
  String get failed => 'Gagal';

  @override
  String failedToDispatch(String error) {
    return 'Gagal menghantar: $error';
  }

  @override
  String get failedToLoad => 'Gagal memuatkan';

  @override
  String failedToLoadAgents(String error) {
    return 'Gagal memuatkan ejen: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Gagal memuatkan suapan: $error';
  }

  @override
  String get failedToLoadGifs => 'Gagal memuatkan GIF';

  @override
  String failedToLoadLogs(String error) {
    return 'Gagal memuatkan log: $error';
  }

  @override
  String get failedToLoadRepos => 'Gagal memuatkan repositori';

  @override
  String get failedToLoadWorkspaces => 'Gagal memuatkan ruang kerja';

  @override
  String failedToStartAiReview(String error) {
    return 'Gagal memulakan semakan AI: $error';
  }

  @override
  String get failedToStartMicTest => 'Gagal memulakan ujian mikrofon.';

  @override
  String failedToSubmitReview(String error) {
    return 'Gagal menyerahkan semakan: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'Gagal memuat naik $name: $error';
  }

  @override
  String failedWithError(String error) {
    return 'Gagal: $error';
  }

  @override
  String get failure => 'Kegagalan';

  @override
  String get feedAlreadyExists => 'Suapan dengan URL ini sudah wujud.';

  @override
  String get feedUrlExample => 'e.g. https://example.com/feed.xml';

  @override
  String get feedUrlLabel => 'URL suapan';

  @override
  String feedsCount(int count) {
    return 'Suapan ($count)';
  }

  @override
  String get filesChanged => 'Fail diubah';

  @override
  String filesCount(int count) {
    return '$count fail';
  }

  @override
  String get filesMentionSection => 'Fail';

  @override
  String get filterAgents => 'Tapis ejen...';

  @override
  String get filterFilesHint => 'Tapis fail…';

  @override
  String get filterLists => 'Senarai penapis';

  @override
  String get filterSkillsPlaceholder => 'Tapis kemahiran…';

  @override
  String get finish => 'Selesai';

  @override
  String get fix => 'Betulkan';

  @override
  String get forward => 'Maju';

  @override
  String get gatesGithubPatPush =>
      'Mengawal suntikan PAT GitHub. Diperlukan supaya ejen boleh push.';

  @override
  String get general => 'Umum';

  @override
  String get githubLink => 'Pautan GitHub';

  @override
  String get claudeStatusFetchFailed =>
      'Tidak dapat mencapai status.claude.com';

  @override
  String get claudeStatusOpenInBrowser => 'Buka status.claude.com';

  @override
  String get githubStatusFetchFailed => 'Tidak dapat mencapai githubstatus.com';

  @override
  String get githubDegradedTitle => 'GitHub melaporkan masalah';

  @override
  String githubDegradedStatusLine(String status) {
    return 'Status GitHub: $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'Status GitHub: $status. Data pull request mungkin lapuk atau tidak lengkap sehingga ia pulih.';
  }

  @override
  String get githubStatusOpenInBrowser => 'Buka githubstatus.com';

  @override
  String get githubStatusRefresh => 'Muat semula';

  @override
  String githubStatusUpdated(String time) {
    return 'Dikemas kini $time';
  }

  @override
  String get kimiStatusFetchFailed => 'Tidak dapat mencapai status.moonshot.cn';

  @override
  String get kimiStatusOpenInBrowser => 'Buka status.moonshot.cn';

  @override
  String get openaiStatusFetchFailed =>
      'Tidak dapat mencapai status.openai.com';

  @override
  String get openaiStatusOpenInBrowser => 'Buka status.openai.com';

  @override
  String get serviceStatusMaintenance => 'Penyelenggaraan';

  @override
  String get serviceStatusMajorIssues => 'Isu besar';

  @override
  String get serviceStatusMinorIssues => 'Isu kecil';

  @override
  String get serviceStatusOperational => 'Beroperasi';

  @override
  String get serviceStatusOutage => 'Gangguan';

  @override
  String get serviceStatusTitle => 'Status perkhidmatan';

  @override
  String get serviceStatusUnknown => 'Tidak diketahui';

  @override
  String lastChecked(String time) {
    return 'Disemak $time';
  }

  @override
  String get lastCheckedRecently => 'Disemak baru-baru ini';

  @override
  String get giveYourWorkAHome => 'Berikan kerja anda sebuah rumah.';

  @override
  String get goBack => 'Undur';

  @override
  String get goForward => 'Maju';

  @override
  String get googleFonts => 'Google fonts';

  @override
  String get high => 'Tinggi';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jam yang lalu',
      one: '1 jam yang lalu',
    );
    return '$_temp0';
  }

  @override
  String get images => 'Imej';

  @override
  String get inactive => 'Tidak aktif';

  @override
  String get install => 'Pasang';

  @override
  String get installRequired => 'Pemasangan diperlukan';

  @override
  String installedVersion(String version) {
    return '$version dipasang';
  }

  @override
  String get invite => 'Jemput';

  @override
  String get inviteAgent => 'Jemput ejen';

  @override
  String get isolateAgentExecution => 'asingkan pelaksanaan ejen.';

  @override
  String get justNow => 'Baru sahaja';

  @override
  String get keepSandboxing => 'Kekalkan kotak pasir';

  @override
  String get keybindingAddARepositoryDescription => 'Tambah repositori';

  @override
  String get keybindingAddRepository => 'Tambah repositori';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Tanda atau nyahpenanda artikel yang dipilih';

  @override
  String get keybindingCommandPalette => 'Palet perintah';

  @override
  String get keybindingCreateANewAgentDescription => 'Cipta ejen baharu';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Cipta ruang kerja baharu';

  @override
  String get keybindingFocusSearch => 'Fokus carian';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Fokus medan carian pull request';

  @override
  String get keybindingNewAgent => 'Ejen baharu';

  @override
  String get keybindingNewWorkspace => 'Ruang kerja baharu';

  @override
  String get keybindingNextArticle => 'Artikel seterusnya';

  @override
  String get keybindingNextSpace => 'Ruang seterusnya';

  @override
  String get keybindingNextWorkspace => 'Ruang kerja seterusnya';

  @override
  String get keybindingOpenArticle => 'Buka artikel';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Buka atau tutup pop timbul penukar ruang kerja dalam bar sisi';

  @override
  String get keybindingOpenPr => 'Buka PR';

  @override
  String get keybindingOpenSettings => 'Buka tetapan';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Buka tetapan aplikasi';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Buka palet perintah';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Buka artikel yang dipilih';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Buka pull request yang dipilih';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Buka ruang kerja yang dipilih';

  @override
  String get keybindingOpenWorkspace => 'Buka ruang kerja';

  @override
  String get keybindingPreviousArticle => 'Artikel sebelumnya';

  @override
  String get keybindingPreviousSpace => 'Ruang sebelumnya';

  @override
  String get keybindingPreviousWorkspace => 'Ruang kerja sebelumnya';

  @override
  String get keybindingRefresh => 'Muat semula';

  @override
  String get keybindingRefreshAllFeedsDescription => 'Muat semula semua suapan';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Muat semula senarai pull request';

  @override
  String get keybindingRescanForAdaptersDescription => 'Imbas semula penyesuai';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Pilih artikel seterusnya';

  @override
  String get keybindingSelectTheNextSpaceDescription =>
      'Pilih ruang seterusnya';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Pilih artikel sebelumnya';

  @override
  String get keybindingSelectThePreviousSpaceDescription =>
      'Pilih ruang sebelumnya';

  @override
  String get keybindingSendMessage => 'Hantar mesej';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Hantar mesej semasa';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Tukar antara modus cerah dan gelap';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Tukar ke ruang kerja kelapan';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Tukar ke ruang kerja kelima';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Tukar ke ruang kerja pertama';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Tukar ke ruang kerja keempat';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Tukar ke ruang kerja seterusnya';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Tukar ke ruang kerja kesembilan';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Tukar ke ruang kerja sebelumnya';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Tukar ke ruang kerja kedua';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Tukar ke ruang kerja ketujuh';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Tukar ke ruang kerja keenam';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Tukar ke ruang kerja ketiga';

  @override
  String get keybindingToggleBookmark => 'Togol penanda halaman';

  @override
  String get keybindingToggleTheme => 'Togol tema';

  @override
  String get keybindingToggleWorkspaceSwitcher => 'Togol penukar ruang kerja';

  @override
  String get keybindingWorkspace1 => 'Ruang kerja 1';

  @override
  String get keybindingWorkspace2 => 'Ruang kerja 2';

  @override
  String get keybindingWorkspace3 => 'Ruang kerja 3';

  @override
  String get keybindingWorkspace4 => 'Ruang kerja 4';

  @override
  String get keybindingWorkspace5 => 'Ruang kerja 5';

  @override
  String get keybindingWorkspace6 => 'Ruang kerja 6';

  @override
  String get keybindingWorkspace7 => 'Ruang kerja 7';

  @override
  String get keybindingWorkspace8 => 'Ruang kerja 8';

  @override
  String get keybindingWorkspace9 => 'Ruang kerja 9';

  @override
  String get keybindings => 'Ikatan kekunci';

  @override
  String get keybindingsDescription =>
      'Semua pintasan papan kekunci. Pintasan adalah tetap dan tidak dapat ditetapkan semula.';

  @override
  String get killRunning => 'Henti paksa yang berjalan';

  @override
  String get languageSystem => 'Sistem';

  @override
  String get leaveACommentEllipsis => 'Tinggalkan komen…';

  @override
  String get legendLabel => 'Legenda';

  @override
  String get lessLabel => 'Kurang';

  @override
  String get letsPluginTools => 'Mari pasangkan alat anda.';

  @override
  String get level => 'Tahap';

  @override
  String get loadingAgents => 'Memuatkan ejen…';

  @override
  String get loadingModels => 'Memuatkan model…';

  @override
  String get loadingProviders => 'Memuatkan penyedia…';

  @override
  String get logLevel => 'Tahap log';

  @override
  String get logs => 'Log';

  @override
  String get low => 'Rendah';

  @override
  String get maintenance => 'Penyelenggaraan';

  @override
  String get manageParticipants => 'Urus peserta';

  @override
  String get manageWorkspaces => 'Urus ruang kerja';

  @override
  String get reorderWorkspace => 'Susun semula ruang kerja';

  @override
  String get matchOsAppearance =>
      'Padankan penampilan OS anda atau pilih modus tetap.';

  @override
  String get mcpAuthToken => 'Token pengesahan MCP';

  @override
  String get mcpNotAvailableOnServer =>
      'Kawalan pelayan MCP tidak tersedia pada pelayan yang disambungkan.';

  @override
  String get modelManagedOnServer =>
      'Model ini berjalan pada hos pelayan dan diuruskan di sana.';

  @override
  String get mcpServer => 'Pelayan MCP';

  @override
  String get medium => 'Sederhana';

  @override
  String get memoryDataHint =>
      'Fakta dan polisi akan muncul di sini semasa ejen bekerja.';

  @override
  String get memoryLabel => 'Memori';

  @override
  String get merge => 'Cantum';

  @override
  String get merged => 'Dicantum';

  @override
  String get messagePlaceholder => 'Mesej… (@ untuk sebut, / untuk perintah)';

  @override
  String get navConversations => 'Ruang';

  @override
  String get microphonePermissionDenied => 'Kebenaran mikrofon ditolak.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minit yang lalu',
      one: '1 minit yang lalu',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Model';

  @override
  String get modified => 'Diubah suai';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bulan yang lalu',
      one: '1 bulan yang lalu',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => 'Lagi';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Nama';

  @override
  String get nameAndTitleRequired => 'Nama dan tajuk diperlukan.';

  @override
  String get nameAndUrlRequired => 'Nama dan URL diperlukan';

  @override
  String get nameLabel => 'Nama';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Kotak pasir natif tersedia pada $platform.';
  }

  @override
  String get nativeSandboxNeedsInstall =>
      'Pemasangan kotak pasir natif diperlukan';

  @override
  String get navObservability => 'Kebolehcerapan';

  @override
  String get navSettings => 'Tetapan';

  @override
  String networkBlockCount(int count) {
    return '$count sekatan rangkaian';
  }

  @override
  String get neutral => 'Neutral';

  @override
  String get newCommitsPushed =>
      'Commit baharu telah di-push — klik untuk memuat semula diff';

  @override
  String get newFact => 'Fakta baharu';

  @override
  String get newPolicy => 'Polisi baharu';

  @override
  String get newsfeed => 'Suapan berita';

  @override
  String get newsfeedLabel => 'Suapan berita';

  @override
  String get newsfeedSettingsDescription =>
      'Urus suapan langganan dan keutamaan pembaca anda.';

  @override
  String get newsfeedSettingsTitle => 'Tetapan suapan berita';

  @override
  String get nextMatch => 'Padanan seterusnya (↵)';

  @override
  String get noActiveWorkspace => 'Tiada ruang kerja aktif atau repo dipilih.';

  @override
  String get noActiveWorkspaceCreate => 'Tiada ruang kerja aktif';

  @override
  String get noActiveWorkspaceGithub =>
      'Tiada ruang kerja aktif dengan repo GitHub.';

  @override
  String get noAgents => 'Tiada ejen';

  @override
  String get noArticlesYet => 'Belum ada artikel';

  @override
  String get noArticlesYetBody =>
      'Artikel dari suapan anda akan muncul di sini.';

  @override
  String get noExecutionLogsYet => 'Belum ada log pelaksanaan';

  @override
  String get noFacts => 'Belum ada fakta';

  @override
  String get noFeedsYet => 'Belum ada suapan';

  @override
  String get noFileAnchor =>
      'Tiada sauh fail — tidak dapat menyiarkan komen sebaris.';

  @override
  String get noFileChangesInScope => 'Tiada perubahan fail dalam skop ini';

  @override
  String get noGifsFound => 'Tiada GIF dijumpai';

  @override
  String get noInputDevicesDetected =>
      'Tiada peranti input dikesan — menggunakan lalai sistem.';

  @override
  String get noMatchingFiles => 'Tiada fail yang sepadan';

  @override
  String get noMatchingGoogleFonts => 'Tiada Google Fonts yang sepadan.';

  @override
  String get noMemoryData => 'Belum ada data memori';

  @override
  String get noMessagesYet => 'Belum ada mesej';

  @override
  String get noModelsAdvertised => 'Tiada model diiklankan oleh penyesuai ini.';

  @override
  String get noOpenPullRequests => 'Tiada pull request terbuka';

  @override
  String get noPolicies => 'Belum ada polisi';

  @override
  String get noReposInWorkspaceYet =>
      'Belum ada repositori dalam ruang kerja ini';

  @override
  String get noRunnersDetected =>
      'Belum ada pelari dikesan. Muat semula untuk mengimbas lagi.';

  @override
  String get noSavedArticles => 'Tiada artikel tersimpan';

  @override
  String get noSavedArticlesBody =>
      'Artikel yang anda simpan akan muncul di sini.';

  @override
  String noShortcutsMatch(String query) {
    return 'Tiada pintasan sepadan dengan \"$query\"';
  }

  @override
  String get noSystemFonts => 'Tiada fon sistem dikesan.';

  @override
  String get noTokenSet => 'Tiada token ditetapkan — akses tidak terhad.';

  @override
  String get noWorkingMemory => 'Belum ada nota memori kerja.';

  @override
  String get noneAllRoles => 'Tiada (semua peranan)';

  @override
  String get notAvailable => 'Tidak tersedia';

  @override
  String get notConfiguredLabel => 'Tidak dikonfigurasikan.';

  @override
  String get notFoundLabel => 'Tidak dijumpai';

  @override
  String get notes => 'Nota';

  @override
  String get notificationAgentFinished => 'Ejen selesai';

  @override
  String get notificationPrMentioned => 'Disebut dalam pull request';

  @override
  String get notificationNewMessages => 'Mesej baharu';

  @override
  String get notificationPrMerged => 'PR dicantum';

  @override
  String get notificationPrPublished => 'PR diterbitkan';

  @override
  String get notificationReviewRequested => 'Semakan diminta';

  @override
  String get notifications => 'Pemberitahuan';

  @override
  String get notifyAgentRunCompleted =>
      'Beritahu apabila ejen menyelesaikan larian.';

  @override
  String get notifyPrMentioned =>
      'Beritahu apabila anda disebut dalam pull request.';

  @override
  String get notifyNewMessages =>
      'Beritahu tentang mesej ejen baharu dalam ruang lain.';

  @override
  String get notifyPrMerged => 'Beritahu apabila pull request dicantum.';

  @override
  String get notifyPrPublished =>
      'Beritahu apabila ejen menerbitkan pull request.';

  @override
  String get notifyReviewRequested =>
      'Beritahu apabila semakan anda diminta pada pull request.';

  @override
  String get notificationReviewStale => 'Semakan lapuk';

  @override
  String get notifyReviewStale =>
      'Apabila commit baharu mendarat pada pull request yang sudah anda semak';

  @override
  String get notificationPrMergeReadiness => 'Sedia untuk dicantum';

  @override
  String get notifyPrMergeReadiness =>
      'Beritahu apabila pull request yang anda karang menjadi boleh dicantum, atau berhenti.';

  @override
  String get notificationPrReviewDecision => 'Keputusan semakan';

  @override
  String get notifyPrReviewDecision =>
      'Beritahu apabila penyemak meluluskan, meminta perubahan atau kelulusan ditolak.';

  @override
  String get notificationPrChecksStatus => 'Semakan';

  @override
  String get notifyPrChecksStatus =>
      'Beritahu apabila CI gagal pada pull request yang anda karang, dan apabila ia pulih.';

  @override
  String get notificationPrThreadActivity => 'Benang semakan';

  @override
  String get notifyPrThreadActivity =>
      'Beritahu apabila seseorang membalas atau menyelesaikan benang yang anda berada di dalamnya.';

  @override
  String get notificationPrReadyToMerge => 'Sedia untuk dicantum';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '$prTitle mempunyai segala yang diperlukan.';
  }

  @override
  String get notificationPrMergeBlocked => 'Tidak lagi boleh dicantum';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '$prTitle bercanggah dengan cawangan asas.';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '$prTitle ketinggalan daripada cawangan asas.';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '$prTitle menunggu semakan yang diperlukan.';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'Penyemak meminta perubahan pada $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return 'Semakan gagal pada $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '$prTitle tidak lagi boleh dicantum.';
  }

  @override
  String get notificationPrApproved => 'Pull request diluluskan';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '$login meluluskan $prTitle';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '$prTitle diluluskan';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count penyemak masih perlu membalas',
      one: '1 penyemak masih perlu membalas',
      zero: 'tiada penyemak tinggal',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => 'Perubahan diminta';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '$login meminta perubahan pada $prTitle';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return 'Perubahan diminta pada $prTitle';
  }

  @override
  String get notificationPrReviewDismissed => 'Kelulusan ditolak';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '$prTitle perlu disemak lagi.';
  }

  @override
  String get notificationPrChecksFailed => 'Semakan gagal';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '$checkName gagal pada $prTitle';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return 'Semakan gagal pada $prTitle';
  }

  @override
  String get notificationPrChecksRecovered => 'Semakan lulus';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '$prTitle hijau semula.';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '$login menyebut anda dalam $location';
  }

  @override
  String get notificationPrThreadReplied => 'Balasan baharu';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '$login membalas dalam $location';
  }

  @override
  String get notificationPrThreadResolved => 'Benang diselesaikan';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return 'Benang anda dalam $location telah diselesaikan.';
  }

  @override
  String get notificationGroupAgents => 'Ejen';

  @override
  String get notificationGroupPullRequests => 'Pull request';

  @override
  String get notificationGroupMessages => 'Mesej';

  @override
  String get notificationGroupTickets => 'Tiket';

  @override
  String get notificationGroupCalendar => 'Kalendar';

  @override
  String get notificationGroupMachines => 'Mesin';

  @override
  String get notificationsMutedRepos => 'Repositori disenyapkan';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repositori disenyapkan',
      one: '1 repositori disenyapkan',
      zero: 'Tiada repositori disenyapkan',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'Senyapkan repositori ini';

  @override
  String get onboardingLinuxDescription =>
      'Control Center boleh menggunakan bekas Linux untuk mengasingkan pelaksanaan ejen.';

  @override
  String get onboardingMacosDescription =>
      'Control Center menggunakan kotak pasir natif pada macOS untuk mengasingkan pelaksanaan ejen.';

  @override
  String get onboardingUnsupportedDescription =>
      'Kotak pasir tidak tersedia pada platform ini. Pelaksanaan ejen akan tanpa pengasingan.';

  @override
  String get openArticlesInApp => 'Buka artikel dalam apl';

  @override
  String get openInBrowser => 'Buka dalam penyemak imbas';

  @override
  String get openedInYourBrowser => 'Dibuka dalam pelayar anda.';

  @override
  String get openLabel => 'Buka';

  @override
  String get openOnGithub => 'Buka di GitHub';

  @override
  String get openStatus => 'Terbuka';

  @override
  String get optionalPersonaDescription => 'Perihalan persona pilihan';

  @override
  String get otherLabel => 'Lain';

  @override
  String get ownerOrganization => 'Pemilik / Organisasi';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => 'Lulus';

  @override
  String get pasteValueHere => 'Tampal nilai di sini';

  @override
  String get persona => 'Persona';

  @override
  String get policies => 'Polisi';

  @override
  String get policiesHint =>
      'Polisi akan muncul di sini setelah ejen menaikkan fakta.';

  @override
  String get policy => 'Polisi';

  @override
  String get popular => 'Popular';

  @override
  String get port => 'Port';

  @override
  String get postingEllipsis => 'Menyiarkan…';

  @override
  String get prCommits => 'Commit';

  @override
  String get prMergedBody => 'Pull request telah dicantum';

  @override
  String get prMoreActions => 'Tindakan lanjut';

  @override
  String get prTitle => 'Tajuk PR';

  @override
  String get reviewCommentHint =>
      'Klik luluskan sahaja, atau jika anda mahu tambah komen atau tindak balas…';

  @override
  String get nothingToPreview => 'Tiada apa untuk pratonton';

  @override
  String get previousMatch => 'Padanan sebelumnya (⇧↵)';

  @override
  String get priorityReviewsDescription =>
      'Semakan keutamaan dan gambaran keseluruhan repositori.';

  @override
  String get prsCreated => 'PR dicipta';

  @override
  String get prsMerged => 'PR dicantum';

  @override
  String get publishToGithub => 'Terbitkan ke GitHub';

  @override
  String get published => 'Diterbitkan';

  @override
  String get pullRequestApproved => 'Pull request diluluskan';

  @override
  String get pullRequests => 'Pull request';

  @override
  String get questionLabel => 'SOALAN';

  @override
  String get queued => 'Dalam barisan';

  @override
  String get react => 'Tindak balas';

  @override
  String get readPrsIssuesMetadata =>
      'Membolehkan ejen membaca PR, isu dan metadata repo.';

  @override
  String get readerPreferences => 'Keutamaan pembaca';

  @override
  String get reasoningEffort => 'Usaha penaakulan';

  @override
  String get recommendLabel => 'SYORKAN';

  @override
  String recordingFromDevice(String device) {
    return 'Merakam dari $device.';
  }

  @override
  String get redownload => 'Muat turun semula';

  @override
  String get redownloadEmbeddingModel => 'Muat turun semula model embedding?';

  @override
  String get redownloadVoiceModel => 'Muat turun semula model suara?';

  @override
  String get refinePlan => 'Perhalusi rancangan';

  @override
  String get refresh => 'Muat semula';

  @override
  String get refreshAll => 'Muat semula semua';

  @override
  String get refreshAllFeeds => 'Muat semula semua suapan';

  @override
  String get reject => 'Tolak';

  @override
  String get rejected => 'Ditolak';

  @override
  String get reload => 'Muat semula';

  @override
  String get remove => 'Buang';

  @override
  String get removeBookmark => 'Buang penanda halaman';

  @override
  String get removeEmbeddingModel => 'Buang model embedding?';

  @override
  String get removeLogo => 'Buang logo';

  @override
  String get removeRepoFromWorkspace => 'Buang repositori dari ruang kerja?';

  @override
  String get removeVoiceModel => 'Buang model suara?';

  @override
  String get removed => 'Dibuang';

  @override
  String get renamed => 'Dinamakan semula';

  @override
  String get reopen => 'Buka semula';

  @override
  String get resolve => 'Selesaikan';

  @override
  String get replyEllipsis => 'Balas…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name akan dibuang dari ruang kerja ini. Fail setempat pada cakera tidak disentuh.';
  }

  @override
  String repoAccessNoticeBody(String repos) {
    return 'Kelayakan GitHub pelayan tidak dapat melihat $repos. Jika repositori milik organisasi, pasang GitHub App di sana atau sambungkan token yang mempunyai akses.';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repositori tidak dapat diakses',
      one: 'Repositori tidak dapat diakses',
    );
    return '$_temp0';
  }

  @override
  String get repoAccessNoticeSuspendedTitle =>
      'Pemasangan GitHub App digantung';

  @override
  String repoAccessNoticeSuspendedBody(String repos) {
    return 'Memaparkan data terakhir diketahui untuk $repos. Sambung semula pemasangan di GitHub, atau sambungkan token yang mempunyai akses.';
  }

  @override
  String get repoNoAccessBadge => 'Tiada akses';

  @override
  String get reportsTo => 'Melapor kepada';

  @override
  String reposCount(int count) {
    return 'Repositori ($count)';
  }

  @override
  String get reposDescription =>
      'Checkout setempat yang ruang kerja ini sasar.';

  @override
  String get repositories => 'Repositori';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repositori',
      one: '1 repositori',
    );
    return 'Tidak dapat menambah $_temp0: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repositori ditambah',
      one: 'Repositori ditambah',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'Tetapan repositori';

  @override
  String get repositoryName => 'Nama repositori';

  @override
  String get requestChanges => 'Minta perubahan';

  @override
  String get requested => 'Diminta';

  @override
  String get requestedChanges => 'Perubahan diminta';

  @override
  String requiredRoleLabel(String role) {
    return 'Peranan diperlukan: $role';
  }

  @override
  String get requiredRoleOptional => 'Peranan diperlukan (pilihan)';

  @override
  String get requirements => 'Keperluan';

  @override
  String get reset => 'Tetapkan semula';

  @override
  String get resolved => 'Diselesaikan';

  @override
  String get enclosedTerminalTitle => 'Terminal terasing';

  @override
  String get enclosedTerminalStart => 'Buka shell';

  @override
  String get enclosedTerminalStartHint =>
      'Shell ini berjalan dalam VM pakai buang perbualan ini. Ia but apabila anda membukanya, bukan apabila apl bermula.';

  @override
  String get terminalStreamReconnecting =>
      'strim terganggu — menyambung semula…';

  @override
  String get terminalStreamError => 'ralat strim:';

  @override
  String get terminalShellExited => 'shell keluar';

  @override
  String get restartShell => 'Mulakan semula shell';

  @override
  String get retry => 'Cuba semula';

  @override
  String get review => 'Semakan';

  @override
  String get reviewedByMe => 'Disemak oleh saya';

  @override
  String get reviewers => 'Penyemak';

  @override
  String get roleLabel => 'Peranan';

  @override
  String get ruleHint => 'Peraturan polisi (markdown disokong)';

  @override
  String get ruleLabel => 'Peraturan';

  @override
  String get runCompleted => 'Larian selesai';

  @override
  String get running => 'Berjalan';

  @override
  String get runningLabel => 'berjalan';

  @override
  String get runs => 'Larian';

  @override
  String get runsLabel => 'Larian';

  @override
  String get sandboxBackendNativeLabel => 'Kotak pasir natif';

  @override
  String get sandboxBackendMicrovmLabel => 'VM terasing';

  @override
  String get sandboxBackendNoneLabel => 'Tiada pengasingan';

  @override
  String get sandboxLinuxInstall =>
      'Kotak pasir natif pada Linux/WSL2 menggunakan bubblewrap. Pasang dengan:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'Kotak pasir natif terbina pada macOS - menggunakan Apple Seatbelt (`sandbox-exec`). Tiada pemasangan diperlukan.';

  @override
  String get sandboxPermissions => 'Kebenaran kotak pasir';

  @override
  String get sandboxUnsupported =>
      'Kotak pasir natif belum disokong pada platform ini. Jatuh kepada \"Tiada pengasingan\".';

  @override
  String get sandboxingDisabledDescription =>
      'Ejen berjalan terus pada hos dengan env penuh - tidak disyorkan.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Semua seruan ejen dihalakan melalui $backend.';
  }

  @override
  String get save => 'Simpan';

  @override
  String get saveChanges => 'Simpan perubahan';

  @override
  String get adapterArguments => 'Argumen tambahan';

  @override
  String get adapterArgumentsHint => 'Bendera CLI tambahan (e.g. --yolo)';

  @override
  String get addVariable => 'Tambah pemboleh ubah';

  @override
  String get environmentVariables => 'Pemboleh ubah persekitaran';

  @override
  String get environmentVariablesDescription =>
      'Pemboleh ubah persekitaran tersuai yang dihantar ke penyesuai ini (e.g. kunci API). Disimpan dalam keychain.';

  @override
  String get variableKey => 'Kunci';

  @override
  String get variableValue => 'Nilai';

  @override
  String get savingEllipsis => 'Menyimpan…';

  @override
  String get scopeDiffToCommits =>
      'Skopkan diff ke commit — Shift-klik untuk julat';

  @override
  String get noPrsMatchSearch => 'Tiada pull request yang sepadan';

  @override
  String get searchFactsHint => 'Cari fakta...';

  @override
  String get searchFonts => 'Cari fon…';

  @override
  String get searchGifs => 'Cari GIF';

  @override
  String get searchGifsHint => 'Cari GIF...';

  @override
  String get searchInDiffHint => 'Cari dalam diff…';

  @override
  String get searchOrTypeModel => 'Cari atau taip nama model…';

  @override
  String get searchPlaceholder => 'Cari…';

  @override
  String get searchShortcuts => 'Cari pintasan…';

  @override
  String get shortcutUnavailableInBrowser =>
      'Tidak tersedia dalam penyemak imbas';

  @override
  String get searching => 'Mencari…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saat yang lalu',
      one: '1 saat yang lalu',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Pilih penyesuai';

  @override
  String get selectAdapterFirst => 'Pilih penyesuai dahulu';

  @override
  String get selectAgentToReportTo => 'Pilih ejen untuk dilaporkan…';

  @override
  String get selectAnAgent => 'Pilih ejen';

  @override
  String get selectConversation => 'Pilih perbualan';

  @override
  String get selectLabel => 'Pilih';

  @override
  String get selectRunner => 'Pilih pelari';

  @override
  String get semanticSearch => 'Carian semantik';

  @override
  String get send => 'Hantar';

  @override
  String get sendFirstMessage => 'Hantar mesej pertama';

  @override
  String get sendMessage => 'Hantar mesej';

  @override
  String sentFindingsToAgent(int count) {
    return '$count penemuan dihantar kepada ejen.';
  }

  @override
  String setGithubLinkDescription(String name) {
    return 'Tetapkan pemilik GitHub dan nama repositori untuk $name. Ini digunakan untuk menyelesaikan rujukan PR dan isu seperti #123 dalam kandungan markdown.';
  }

  @override
  String get setLabel => 'Tetapkan';

  @override
  String get setToken => 'Tetapkan token';

  @override
  String get settingsLabel => 'Tetapan';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get settingsLanguageDescription => 'Pilih bahasa apl.';

  @override
  String get shortTask => 'Tugasan pendek';

  @override
  String get showNativeNotifications =>
      'Tunjukkan pemberitahuan natif macOS untuk peristiwa.';

  @override
  String get showSuperseded => 'Tunjuk yang diganti';

  @override
  String get signedIn => 'Telah log masuk.';

  @override
  String signedInAs(String username) {
    return 'Log masuk sebagai $username.';
  }

  @override
  String get skillNameRequired => 'Nama kemahiran diperlukan.';

  @override
  String skillSaved(String name) {
    return 'Kemahiran \"$name\" disimpan.';
  }

  @override
  String get skillsSourcesTab => 'Sumber';

  @override
  String get skillSourcesDisclaimer =>
      'Kemahiran dipasang dari repositori GitHub yang anda tambah. Metadata repositori tidak dipercayai — imbasan antivirus adalah isyarat keselamatan sebenar.';

  @override
  String get skillSourcesEmpty => 'Tiada repositori kemahiran';

  @override
  String get skillSourcesEmptyHint =>
      'Tambah repositori GitHub untuk menyemak imbas kemahirannya.';

  @override
  String get skillSourceAdd => 'Tambah repositori';

  @override
  String get skillSourceAddTitle => 'Tambah repositori kemahiran';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      'Masukkan URL repositori GitHub (https://github.com/owner/repo).';

  @override
  String skillSourceAdded(String repo) {
    return 'Repositori $repo ditambah.';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'Repositori $repo sudah ditambah.';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'Repositori $repo dibuang.';
  }

  @override
  String get skillSourceRemove => 'Buang';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return 'Buang $repo?';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'Kemahiran yang dipasang kekal dipasang. Hanya katalog repositori dibuang.';

  @override
  String get skillSourceNoSkills =>
      'Tiada kemahiran dijumpai dalam repositori ini (kemahiran ialah direktori yang mengandungi SKILL.md).';

  @override
  String get skillSourceRefresh => 'Muat semula';

  @override
  String get skillSourceInstalledBadge => 'Dipasang';

  @override
  String get skillSourceUpdateBadge => 'Kemas kini tersedia';

  @override
  String get skillSourceSlugTaken => 'Nama sedang digunakan';

  @override
  String skillSourceFilesCount(num count) {
    return '$count fail';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'Kemahiran ini tiada README.';

  @override
  String get skillSourceNoMatches =>
      'Tiada kemahiran sepadan dengan penapis anda.';

  @override
  String get skillUpdateAction => 'Kemas kini';

  @override
  String get skillUninstallAction => 'Nyahpasang';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return 'Nyahpasang \"$slug\"?';
  }

  @override
  String skillUninstalled(String slug) {
    return 'Kemahiran \"$slug\" dinyahpasang.';
  }

  @override
  String get skillFindingLine => 'baris';

  @override
  String get skillInstallAnywayOverride => 'Saya faham risikonya — pasang juga';

  @override
  String skillInstalled(String slug) {
    return 'Kemahiran \"$slug\" dipasang.';
  }

  @override
  String get skillPreviewCapabilities => 'Keupayaan';

  @override
  String get skillPreviewFindings => 'Penemuan';

  @override
  String get skillPreviewGuardedActions => 'Tindakan terlindung';

  @override
  String get skillPreviewLlmReviewed => 'Disemak LLM';

  @override
  String get skillPreviewNoCapabilities => 'Tiada keupayaan diisytiharkan.';

  @override
  String get skillPreviewNoFindings => 'Tiada penemuan.';

  @override
  String get skillPreviewScanning => 'Mengimbas kemahiran…';

  @override
  String get skillPreviewVerdictLabel => 'Keputusan imbasan';

  @override
  String get skillPreviewVerdictPass => 'Lulus';

  @override
  String get skillPreviewVerdictQuarantine => 'Dikuarantin';

  @override
  String get skillPreviewVerdictWarn => 'Amaran';

  @override
  String get skillQuarantineWarning =>
      'Kemahiran ini dikuarantin oleh pengimbas. Memasangnya menjalankan kod pada mesin anda. Teruskan hanya jika anda mempercayai sumber dan telah menyemak penemuan.';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'Dikuarantin dan dilepaskan daripada ejen: $agents';
  }

  @override
  String get skillNotScanned => 'Tidak diimbas';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'Manual';

  @override
  String get skillOriginRegistry => 'Daftar';

  @override
  String get skillOriginRuntimeLocal => 'Runtime setempat';

  @override
  String get skillRulesStale => 'Imbasan lapuk';

  @override
  String get skillSaveAnywayOverride => 'Saya faham risikonya — simpan juga';

  @override
  String get skillSaveBlockedBody =>
      'Kandungan disekat sebelum apa-apa ditulis.';

  @override
  String get skillSaveBlockedTitle => 'Simpan disekat oleh pintu imbasan';

  @override
  String get skillScanAction => 'Imbas';

  @override
  String get skillScanAll => 'Imbas semua';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass lulus · $warn amaran · $quarantine dikuarantin';
  }

  @override
  String get skillStateDrifted => 'Diubah suai sejak pemasangan';

  @override
  String get skillStateUnmanaged => 'Tidak diurus';

  @override
  String get skillSeverityBlocked => 'Disekat';

  @override
  String get skillSeverityWarn => 'Amaran';

  @override
  String get skillsInstalledTab => 'Dipasang';

  @override
  String get skills => 'Kemahiran';

  @override
  String get skipAcceptRisk => 'Langkau — saya terima risikonya';

  @override
  String get skipForNow => 'Langkau buat masa ini';

  @override
  String get skipSandboxing => 'Langkau kotak pasir';

  @override
  String get skipSandboxingDialogContent =>
      'Adakah anda pasti mahu melangkau kotak pasir? Ini membenarkan ejen melaksanakan kod pada sistem anda tanpa pengasingan.';

  @override
  String get somethingWentWrong => 'Sesuatu tidak kena';

  @override
  String sourceCount(int count) {
    return '$count sumber';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count sumber';
  }

  @override
  String get sourceFacts => 'Fakta sumber:';

  @override
  String get splitDiff => 'Diff belah (sebelah-menyebelah)';

  @override
  String get startLabel => 'Mula';

  @override
  String get startOnAppLaunch => 'Mula pada pelancaran apl';

  @override
  String get statusLabel => 'Status';

  @override
  String get onboardingStepConnect => 'Sambung';

  @override
  String get onboardingStepWorkspace => 'Ruang kerja';

  @override
  String get onboardingStepSandbox => 'Kotak pasir';

  @override
  String get onboardingStepAdapter => 'Penyesuai';

  @override
  String get onboardingStepVoice => 'Suara';

  @override
  String get stop => 'Henti';

  @override
  String get stopped => 'Dihentikan';

  @override
  String get strictIdentityCheck => 'Semakan identiti ketat';

  @override
  String get success => 'Berjaya';

  @override
  String get successLabel => 'Berjaya';

  @override
  String get suggestAChange => 'Cadangkan perubahan';

  @override
  String get suggestLabel => 'CADANGKAN';

  @override
  String get superseded => 'Diganti';

  @override
  String get synced => 'Disegerakkan';

  @override
  String get systemDefault => 'Lalai sistem';

  @override
  String get systemFonts => 'Fon sistem';

  @override
  String get systemPrompt => 'Prompt sistem';

  @override
  String get systemPromptLabel => 'Prompt sistem';

  @override
  String get talkToControlCenter => 'Bercakap dengan Control Center.';

  @override
  String get taskMentionSection => 'Tugasan';

  @override
  String get testLabel => 'Uji';

  @override
  String get theme => 'Tema';

  @override
  String get themeDark => 'Gelap';

  @override
  String get themeLight => 'Cerah';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get thisCannotBeUndone => 'Ini tidak boleh dibuat asal.';

  @override
  String get ticketLabel => 'TIKET';

  @override
  String get titleLabel => 'Tajuk';

  @override
  String get todayLabel => 'Hari ini';

  @override
  String get toggleTheme => 'Togol tema';

  @override
  String get tokenConfigured =>
      'Dikonfigurasikan — klien mesti menunjukkan token ini.';

  @override
  String get topic => 'Topik';

  @override
  String get topicHint => 'e.g. Tech Stack, Design System';

  @override
  String get totalRuns => 'Jumlah larian';

  @override
  String trackingParamsCount(int count) {
    return '$count parameter penjejakan';
  }

  @override
  String get typeCommandOrSearch => 'Taip perintah atau cari…';

  @override
  String get typography => 'Tipografi';

  @override
  String get unavailable => 'Tidak tersedia';

  @override
  String get unifiedDiff => 'Diff bersatu';

  @override
  String get unknownAuthor => 'Tidak diketahui';

  @override
  String get unnamedAgent => 'Ejen tanpa nama';

  @override
  String get updateKey => 'Kemas kini kunci';

  @override
  String get updateLabel => 'Kemas kini';

  @override
  String get updateToken => 'Kemas kini token';

  @override
  String updatedDaysAgo(int count) {
    return 'Dikemas kini ${count}h yang lalu';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'Dikemas kini ${count}j yang lalu';
  }

  @override
  String get updatedJustNow => 'Dikemas kini baru sahaja';

  @override
  String updatedMinutesAgo(int count) {
    return 'Dikemas kini ${count}min yang lalu';
  }

  @override
  String get useSandbox => 'Gunakan kotak pasir';

  @override
  String get useWorkspaceDefault => 'Gunakan lalai ruang kerja';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'Biarkan kosong untuk menggunakan User-Agent apl lalai. Sesetengah tapak menyekat User-Agent bukan penyemak imbas.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Menggunakan mikrofon lalai sistem.';

  @override
  String get viewLabel => 'Lihat';

  @override
  String get viewLogs => 'Lihat log';

  @override
  String voiceInstallFailed(String error) {
    return 'Pemasangan gagal: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Tidak dipasang. Muat turun ~200 MB sekali; berjalan sepenuhnya pada peranti.';

  @override
  String get voiceModelNotInstalledLabel => 'Model suara tidak dipasang.';

  @override
  String get voiceRedownloadBody =>
      'Fail model sedia ada akan dipadam dan arkib ~200 MB dimuat turun semula. Transkripsi suara tidak tersedia sehingga muat turun selesai.';

  @override
  String get voiceRemoveBody =>
      'Transkripsi suara akan dilumpuhkan sehingga anda memasangnya semula. Anda boleh memasangnya lagi pada bila-bila masa.';

  @override
  String get voiceTranscription => 'Transkripsi suara';

  @override
  String get weakIsolationDescription =>
      'Pengasingan lemah - sempadan ruang nama sahaja, tiada sempadan kernel.';

  @override
  String get whenOffNoDefaultRoute =>
      'Apabila dimatikan, kotak pasir but tanpa laluan lalai.';

  @override
  String get whenOffServerStaysStopped =>
      'Apabila dimatikan, pelayan kekal dihentikan sehingga anda memulakannya.';

  @override
  String get speechModel => 'Model pertuturan';

  @override
  String get speechModelHint =>
      'Digunakan untuk transkripsi mesyuarat dan mikrofon penggubah.';

  @override
  String get voiceModelInstalled =>
      'Dipasang. Menggerakkan transkripsi mesyuarat dan butang mikrofon penggubah.';

  @override
  String get meetingMicSilentWarning =>
      'Mikrofon anda mungkin disenyapkan — yang lain sedang bercakap tetapi tiada apa yang sampai ke mikrofon anda.';

  @override
  String get meetingSummaryPrivacyNotice =>
      'Rakaman dan transkripsi kekal pada mesin ini. Ringkasan ditulis oleh ejen, jadi jika ia menggunakan model awan, transkrip dan nota anda dihantar kepada penyedia itu.';

  @override
  String get meetingTemplates => 'Templat nota mesyuarat';

  @override
  String get meetingTemplatesHint =>
      'Bentuk ringkasan AI untuk jenis mesyuarat. Templat aktif digunakan pada ringkasan baharu dan yang dijalankan semula.';

  @override
  String get meetingTemplateActive => 'Templat aktif';

  @override
  String get meetingTemplateAdd => 'Tambah templat';

  @override
  String get meetingTemplateNewTitle => 'Templat baharu';

  @override
  String get meetingTemplateEditTitle => 'Sunting templat';

  @override
  String get meetingTemplateNameLabel => 'Nama';

  @override
  String get meetingTemplateNameHint => 'e.g. Sprint review';

  @override
  String get meetingTemplateInstructionsLabel => 'Arahan';

  @override
  String get meetingTemplateInstructionsHint =>
      'Bagaimana AI patut menyusun dan menekankan nota ini?';

  @override
  String get workingMemory => 'Memori kerja';

  @override
  String get workspaceName => 'Nama ruang kerja';

  @override
  String get workspaceScopedSkills =>
      'Fail kemahiran berskop ruang kerja yang dilampirkan kepada ejen.';

  @override
  String get workspaces => 'Ruang kerja';

  @override
  String get writePrivateNotes =>
      'Tulis nota peribadi, pemerhatian, rancangan...';

  @override
  String get writeSkillContent =>
      'Tulis kandungan kemahiran anda di sini (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tahun yang lalu',
      one: '1 tahun yang lalu',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Semalam';

  @override
  String get focusModeStart => 'Mula sesi fokus';

  @override
  String get focusModeConfigTitle => 'Mula sesi fokus';

  @override
  String get focusModeGoalLabel => 'Matlamat';

  @override
  String get focusModeGoalHint => 'Apa yang anda sedang kerjakan?';

  @override
  String get focusModeDurationLabel => 'Tempoh';

  @override
  String get focusModeBlockNotifications => 'Sekat pemberitahuan';

  @override
  String get focusModeStartButton => 'Mula';

  @override
  String get focusModeFloat => 'Minimumkan ke bar';

  @override
  String get focusModeActiveTooltip =>
      'Modus fokus aktif — ketik untuk tamatkan';

  @override
  String get dismiss => 'Tolak';

  @override
  String get acceptAndResolve => 'Terima & selesaikan';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'Anda telah menyemak selama ${minutes}m — penyelidikan mencadangkan kualiti semakan boleh merosot selepas 60 min. Pertimbangkan rehat.';
  }

  @override
  String get notificationSound => 'Bunyi pemberitahuan';

  @override
  String get notificationSoundDescription =>
      'Bunyi yang dimainkan apabila pemberitahuan ditunjukkan.';

  @override
  String get notificationSoundNone => 'Tiada';

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
  String get notificationSoundMigrosSoft => 'Migros (lembut)';

  @override
  String get notificationSoundMigrosHard => 'Migros (kuat)';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => 'Uji';

  @override
  String get notificationVolume => 'Volum';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Tiada PR oleh @$login dalam ruang kerja ini';
  }

  @override
  String get usersLabel => 'Pengguna';

  @override
  String get mergePullRequest => 'Cantum pull request';

  @override
  String get forceMergePullRequest => 'Paksa cantum pull request';

  @override
  String get closePullRequest => 'Tutup pull request';

  @override
  String get closePullRequestConfirm =>
      'Adakah anda pasti mahu menutup pull request ini?';

  @override
  String get stackedPullRequests => 'Pull request bertindan';

  @override
  String partOfStack(int position, int total) {
    return 'Sebahagian daripada tindanan ($position daripada $total)';
  }

  @override
  String get createStack => 'Cipta tindanan';

  @override
  String get createStackDialogTitle => 'Cipta tindanan pull request';

  @override
  String createStackDialogBody(int count) {
    return '$count pull request ini akan ditindan, dari bawah ke atas:';
  }

  @override
  String get createStackInvalidSelection =>
      'Pilih sekurang-kurangnya dua pull request dari repositori yang sama untuk mencipta tindanan';

  @override
  String get createStackNotAChain =>
      'Pull request yang dipilih tidak membentuk rantai: cawangan asas setiap pull request mesti menjadi cawangan kepala yang sebelumnya';

  @override
  String get createStackAlreadyStacked =>
      'Satu atau lebih pull request yang dipilih sudah dalam tindanan';

  @override
  String get stackCreated => 'Tindanan dicipta';

  @override
  String get stackCreationFailed => 'Tidak dapat mencipta tindanan';

  @override
  String get squashAndMerge => 'Squash dan cantum';

  @override
  String get createMergeCommit => 'Cipta commit cantuman';

  @override
  String get rebaseAndMerge => 'Rebase dan cantum';

  @override
  String get commitTitle => 'Tajuk commit';

  @override
  String get commitDescription => 'Perihalan commit';

  @override
  String get pullRequestMerged => 'Pull request dicantum';

  @override
  String get pullRequestClosed => 'Pull request ditutup';

  @override
  String failedToMergePr(String error) {
    return 'Gagal mencantum: $error';
  }

  @override
  String failedToClosePr(String error) {
    return 'Gagal menutup: $error';
  }

  @override
  String get markReadyForReview => 'Sedia untuk semakan';

  @override
  String get markReadyForReviewConfirm =>
      'Pull request ini akan meninggalkan draf. Penyemak dimaklumkan, semakan yang diperlukan mula mengawal cantuman dan sebarang automasi yang menunggu pull request sedia akan berjalan.';

  @override
  String get convertToDraft => 'Tukar kepada draf';

  @override
  String get convertToDraftConfirm =>
      'Pull request ini akan kembali kepada draf. Permintaan semakan yang tertunda ditolak dan ia tidak lagi dapat dicantum sehingga anda menandakannya sedia lagi.';

  @override
  String get pullRequestMarkedReady =>
      'Pull request ditandakan sedia untuk semakan';

  @override
  String get pullRequestConvertedToDraft => 'Pull request ditukar kepada draf';

  @override
  String failedToMarkPrReady(String error) {
    return 'Gagal menandakan sedia untuk semakan: $error';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'Gagal menukar kepada draf: $error';
  }

  @override
  String get checksFailing => 'Semakan gagal';

  @override
  String get reviewsPending => 'Beberapa semakan masih tertunda';

  @override
  String get mergeConflictsWithBase =>
      'Cawangan ini mempunyai konflik yang mesti diselesaikan';

  @override
  String get branchOutOfDateWithBase =>
      'Cawangan ini lapuk berbanding cawangan asas';

  @override
  String get mergeBlockedByBranchProtection =>
      'Perlindungan cawangan menyekat cantuman ini';

  @override
  String get confirm => 'Sahkan';

  @override
  String get trustedSitesSectionTitle => 'Tapak dipercayai';

  @override
  String get trustedSitesEmpty =>
      'Tiada tapak dipercayai. Tambah domain untuk melumpuhkan sekatan padanya.';

  @override
  String get addTrustedSite => 'Tambah tapak dipercayai';

  @override
  String get removeTrustedSite => 'Buang';

  @override
  String get disableBlockingForThisSite => 'Lumpuhkan sekatan pada tapak ini';

  @override
  String get enableBlockingForThisSite => 'Dayakan sekatan pada tapak ini';

  @override
  String get enterDomainHint => 'e.g. example.com';

  @override
  String get invalidDomain => 'Masukkan domain yang sah (e.g. example.com)';

  @override
  String get pageLoadTimedOut =>
      'Muat halaman tamat masa. Muat semula atau buka dalam penyemak imbas.';

  @override
  String get pipelinesScreenTitle => 'Pipeline';

  @override
  String get pipelinesScreenSubtitle =>
      'Aliran kerja ejen berbilang langkah deklaratif';

  @override
  String get pipelinesRunPipeline => 'Jalankan pipeline';

  @override
  String get pipelineRunLauncherTitle => 'Jalankan pipeline';

  @override
  String get pipelineRunSubtitle =>
      'Pilih pipeline dan isikan inputnya untuk memulakan larian.';

  @override
  String get pipelineRunNoInputsBadge => 'Tiada input';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count input',
      one: '1 input',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'Pipeline ini tidak mengambil input.';

  @override
  String get pipelineRunSubmit => 'Jalankan pipeline';

  @override
  String get pipelineRunCouldNotStart => 'Tidak dapat memulakan larian.';

  @override
  String pipelineRunStarted(String name) {
    return 'Memulakan $name';
  }

  @override
  String get pipelineRunEmptyTitle => 'Tiada pipeline sedia untuk dijalankan';

  @override
  String get pipelineRunEmptyHint =>
      'Dayakan pipeline dan hidupkan larian manual dalam editornya untuk melancarkannya di sini.';

  @override
  String get pipelineRunManageTemplates => 'Urus pipeline';

  @override
  String get pipelineRunSettingsTitle => 'Larian manual';

  @override
  String get pipelineRunSettingsAllow => 'Benarkan larian manual';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Tunjukkan pipeline ini pada halaman larian supaya ia boleh dimulakan secara manual.';

  @override
  String get pipelineRunSettingsConcurrencyTitle => 'Keserentakan';

  @override
  String get pipelineRunSettingsMaxParallel => 'Maksimum larian selari';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'Biarkan kosong untuk tanpa had. Larian tambahan menunggu dalam barisan dan bermula apabila slot kosong.';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'Tanpa had';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      'Masukkan nombor bulat 1 atau lebih, atau biarkan kosong untuk tanpa had.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Input';

  @override
  String get pipelineRunSettingsAddInput => 'Tambah input';

  @override
  String get pipelineRunSettingsNoInputs => 'Belum ada input.';

  @override
  String get pipelineInputEditTitle => 'Medan input';

  @override
  String get pipelineInputKeyLabel => 'Kunci';

  @override
  String get pipelineInputKeyHelp =>
      'Kunci keadaan nilai disimpan di bawahnya (e.g. repo_full_name).';

  @override
  String get pipelineInputLabelLabel => 'Label';

  @override
  String get pipelineInputTypeLabel => 'Jenis';

  @override
  String get pipelineInputOptionsLabel => 'Pilihan (dipisahkan koma)';

  @override
  String get pipelineInputDefaultLabel => 'Nilai lalai';

  @override
  String get pipelineInputPlaceholderLabel => 'Pemegang tempat';

  @override
  String get pipelineInputHelpLabel => 'Teks bantuan';

  @override
  String get pipelineInputRequiredLabel => 'Diperlukan';

  @override
  String get pipelineInputTypeText => 'Teks';

  @override
  String get pipelineInputTypeMultiline => 'Teks berbilang baris';

  @override
  String get pipelineInputTypeNumber => 'Nombor';

  @override
  String get pipelineInputTypeBoolean => 'Togol';

  @override
  String get pipelineInputTypeSelect => 'Pilih';

  @override
  String get pipelinesEmpty => 'Belum ada larian pipeline';

  @override
  String get pipelinesEmptyHint =>
      'Klik \'Jalankan pipeline\' untuk memulakan satu.';

  @override
  String get pipelinesNoSteps => 'Belum ada langkah direkodkan';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Pilih ruang kerja untuk melihat pipelinenya';

  @override
  String pipelinesLoadError(String error) {
    return 'Gagal memuatkan pipeline: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Gagal memulakan pipeline: $error';
  }

  @override
  String get pipelineStatusPending => 'Tertunda';

  @override
  String get pipelineStatusQueued => 'Dalam barisan';

  @override
  String get pipelineStatusRunning => 'Berjalan';

  @override
  String get pipelineStatusSuspended => 'Digantung';

  @override
  String get pipelineStatusCompleted => 'Selesai';

  @override
  String get pipelineStatusFailed => 'Gagal';

  @override
  String get pipelineStatusCancelled => 'Dibatalkan';

  @override
  String get pipelineStatusSkipped => 'Dilangkau';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed daripada $total langkah';
  }

  @override
  String get pipelineWaterfallTimeline => 'Garis masa';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'Aktif $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'terlengah $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'Masa dikecualikan daripada jumlah aktif: larian dihentikan atau menunggu antara langkah.';

  @override
  String get pipelineStepStarted => 'Dimulakan';

  @override
  String get pipelineStepFinished => 'Selesai';

  @override
  String get pipelineStepDurationLabel => 'Tempoh';

  @override
  String get pipelineStepBranch => 'Cawangan';

  @override
  String get pipelineStepViewConversation => 'Lihat perbualan';

  @override
  String get pipelineStepError => 'Ralat';

  @override
  String get pipelineStepInput => 'Input';

  @override
  String get pipelineStepOutput => 'Output';

  @override
  String get pipelineStepNotExecuted => 'Belum dilaksanakan';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Gagal pada $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Manual';

  @override
  String get pipelineStepSkippedReason => 'Dilangkau';

  @override
  String get pipelineStepPriorAttempts => 'Percubaan sebelumnya';

  @override
  String get pipelineStepAttemptLabel => 'Percubaan';

  @override
  String pipelineStepAttemptN(int number) {
    return 'Percubaan $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'Terganggu';

  @override
  String get pipelineRunColumnPipeline => 'Pipeline';

  @override
  String get pipelineRunColumnDuration => 'Tempoh';

  @override
  String get pipelineRunQueueNext => 'Seterusnya';

  @override
  String pipelineRunQueuePosition(int position) {
    return '$position dalam barisan';
  }

  @override
  String get pipelineRunColumnStarted => 'Dimulakan';

  @override
  String get pipelineRunHistory => 'Sejarah larian';

  @override
  String get pipelineRunHistoryEmpty => 'Belum ada larian lain';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'Jalankan semula $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return 'Percubaan $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'pertama dimulakan $time';
  }

  @override
  String get pipelineRunFilterAll => 'Semua';

  @override
  String get pipelineRunFilterEmpty =>
      'Tiada larian sepadan dengan penapis ini';

  @override
  String get relativeJustNow => 'baru sahaja';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min yang lalu',
      one: '1 min yang lalu',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jam yang lalu',
      one: '1 jam yang lalu',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari yang lalu',
      one: '1 hari yang lalu',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'Pasukan';

  @override
  String get teamsAddTeam => 'Tambah pasukan';

  @override
  String get teamsLoadError => 'Tidak dapat memuatkan pasukan';

  @override
  String get teamsEmptyTitle => 'Belum ada pasukan';

  @override
  String get teamsEmptyDescription =>
      'Kumpulkan ejen ke dalam pasukan supaya kerja yang ditugaskan kepada pasukan dihalakan melalui ketua yang melimpahkan.';

  @override
  String get teamCreateTitle => 'Pasukan baharu';

  @override
  String get teamEditTitle => 'Sunting pasukan';

  @override
  String get teamNameLabel => 'Nama pasukan';

  @override
  String get teamNameHint => 'e.g. Frontend';

  @override
  String get teamDescriptionLabel => 'Perihalan';

  @override
  String get teamDescriptionHint => 'Apa yang pasukan ini bertanggungjawab';

  @override
  String get teamLeaderLabel => 'Ketua';

  @override
  String get teamLeaderHelp =>
      'Penyelaras yang menerima kerja yang ditugaskan kepada pasukan dan melimpahkan kepada ahli yang paling sesuai.';

  @override
  String get teamNoLeader => 'Tiada ketua';

  @override
  String get teamInstructionsLabel => 'Arahan operasi';

  @override
  String get teamInstructionsHelp =>
      'Ditambah pada taklimat ketua — konvensyen pasukan, peraturan eskalasi, nada.';

  @override
  String get teamInstructionsHint => 'Pilihan';

  @override
  String get teamSaved => 'Pasukan disimpan';

  @override
  String get teamMembersError => 'Tidak dapat memuatkan ahli';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ahli',
      one: '1 ahli',
      zero: 'Tiada ahli',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'Tambah ahli';

  @override
  String get teamAddMemberTitle => 'Tambah ahli';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tambah $count',
      one: 'Tambah 1',
      zero: 'Tambah',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => 'Setiap ejen sudah ada dalam pasukan ini.';

  @override
  String get teamRemoveMember => 'Buang dari pasukan';

  @override
  String get teamLeaderBadge => 'Ketua';

  @override
  String get teamUnknownAgent => 'Ejen tidak diketahui';

  @override
  String get teamMembersEmpty => 'Belum ada ahli';

  @override
  String get teamMembersEmptyDescription =>
      'Tambah ejen supaya ketua mempunyai orang untuk dilimpahkan.';

  @override
  String get teamSelectPrompt => 'Pilih pasukan';

  @override
  String get teamSelectPromptDescription =>
      'Pilih pasukan dari senarai, atau cipta yang baharu.';

  @override
  String get teamDeleteTitle => 'Padam pasukan?';

  @override
  String teamDeleteBody(String name) {
    return '$name akan dipadam. Ejennya tidak terjejas.';
  }

  @override
  String get teamHasLeaderTooltip => 'Ada ketua';

  @override
  String get pipelineTemplatesNav => 'Templat pipeline';

  @override
  String get pipelineTemplatesTitle => 'Templat pipeline';

  @override
  String get pipelineTemplatesSubtitle =>
      'Editor seret-dan-lepas untuk pipeline yang mengorkestra ejen anda.';

  @override
  String get pipelineTemplatesNew => 'Templat baharu';

  @override
  String get pipelineTemplatesEmpty =>
      'Belum ada templat pipeline. Cipta satu untuk bermula.';

  @override
  String get pipelineTemplateBuiltInBadge => 'Terbina';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Padam templat?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Padam templat pipeline $name? Ini tidak boleh dibuat asal.';
  }

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Seret jenis nod dari bar sisi ke kanvas, kemudian sambungkannya.';

  @override
  String get unsavedChanges => 'Perubahan belum disimpan';

  @override
  String get nodeLibraryTitle => 'Pustaka nod';

  @override
  String get nodeLibraryHint =>
      'Seret mana-mana entri ke kanvas untuk menambah nod.';

  @override
  String get editorEmptyCanvas => 'Seret nod dari pustaka untuk bermula.';

  @override
  String get pipelineWhenThisHappens => 'Apabila ini berlaku';

  @override
  String get pipelineDoThis => 'Lakukan ini';

  @override
  String get pipelineAddStep => 'Tambah langkah';

  @override
  String get pipelineTidyUp => 'Kemas susun atur';

  @override
  String get pipelineEditorHint =>
      'Seret langkah untuk menyusun · seret pemegang untuk sambung';

  @override
  String get pipelineRemoveConnection => 'Buang sambungan';

  @override
  String get pipelineDragToConnect => 'Seret untuk sambung';

  @override
  String get pipelineNewDefaultName => 'Pipeline baharu';

  @override
  String get nodeCategoryTriggers => 'Pencetus';

  @override
  String get triggerEventWebhook => 'Webhook';

  @override
  String get pipelineAddTrigger => 'Tambah pencetus';

  @override
  String get pipelineOnEvent => 'Pada peristiwa';

  @override
  String get nodeConfigTitle => 'Konfigurasi nod';

  @override
  String get nodeConfigKind => 'Jenis';

  @override
  String get nodeConfigLabel => 'Label';

  @override
  String get nodeConfigAgent => 'Ejen';

  @override
  String get nodeConfigAgentHint => 'Pilih ejen…';

  @override
  String get nodeConfigInputKeys => 'Kunci input (dipisahkan koma)';

  @override
  String get nodeConfigInputKeysHelp =>
      'Kunci keadaan yang nod ini gunakan. Digunakan untuk penggantian pemegang tempat dalam prompt.';

  @override
  String get nodeConfigRepos => 'Repositori untuk diklon';

  @override
  String get nodeConfigReposHelp =>
      'Repo diklon dan diindeks kod apabila nod ini memulakan perbualannya. Memilih setiap repo mengklonkannya semua (lalai).';

  @override
  String get nodeConfigRepoBranchHint => 'Cawangan (lalai)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'Cawangan setiap checkout dipotong daripadanya. Biarkan kosong untuk cawangan lalai repo sendiri — worktree masih mendapat cawangan sendiri, jadi tiada apa yang ejen commit mendarat pada yang ini.';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'Entri dinamik dikekalkan: $entries';
  }

  @override
  String get nodeConfigCreateConversation => 'Buka perbualan di dalamnya';

  @override
  String get nodeConfigCreateConversationHelp =>
      'Biarkan ini dimatikan apabila beberapa nod ejen mengikuti — setiap satu membuka strim bernama sendiri. Hidupkannya apabila satu nod ejen mengikuti, supaya bilik tidak pernah menunjukkan perbualan tanpa tajuk di sisinya.';

  @override
  String get nodeConfigConversationTitle => 'Nama perbualan';

  @override
  String get nodeConfigConversationTitleHelp =>
      'Berikan nod ejen di hilir nama yang sama dan kedua-duanya bekerja dalam satu strim. Lalai kepada label nod.';

  @override
  String get nodeConfigSpaceName => 'Nama ruang';

  @override
  String get nodeConfigSpaceNameHelp =>
      'Apa yang bilik yang nod ini buka dipanggil. Menyokong pemegang tempat keadaan yang sama seperti prompt. Biarkan kosong untuk menggunakan label nod.';

  @override
  String get nodeConfigSpaceNameHint => 'Review of pr_number';

  @override
  String get nodeConfigStreamTitle => 'Nama perbualan';

  @override
  String get nodeConfigStreamTitleHelp =>
      'Strim bernama yang ejen nod ini bekerja di dalamnya dalam bilik. Menyokong pemegang tempat keadaan yang sama seperti prompt. Biarkan kosong dan giliran mendarat dalam perbualan tetap bilik, di mana fan-out menyelang setiap ejen.';

  @override
  String get nodeConfigConversationTitleHint => 'Architecture analysis';

  @override
  String get nodeConfigOutputKey => 'Kunci output';

  @override
  String get nodeConfigPrompt => 'Templat prompt';

  @override
  String get nodeConfigPromptHelp =>
      'Gunakan pemegang tempat kurungan berganda untuk menarik nilai dari keadaan pada masa larian.';

  @override
  String get nodeConfigScript => 'Skrip Bash';

  @override
  String get nodeConfigScriptHelp =>
      'Berjalan dengan bash -c. GITHUB_TOKEN ditetapkan. Pemegang tempat diganti sebelum pelaksanaan.';

  @override
  String get nodeConfigRouteKeys => 'Kunci laluan';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Kunci laluan dari $source';
  }

  @override
  String get conditionSectionTitle => 'Syarat';

  @override
  String get conditionMode => 'Modus';

  @override
  String get conditionModeFilesAny => 'Fail wujud — mana-mana';

  @override
  String get conditionModeFilesAll => 'Fail wujud — semua';

  @override
  String get conditionModeComparison => 'Perbandingan';

  @override
  String get conditionModeSwitch => 'Suis';

  @override
  String get conditionFilePaths => 'Laluan fail';

  @override
  String get conditionFilePathsAnyHelp =>
      'Satu laluan setiap baris, relatif kepada direktori asas. Laluan benar apabila mana-mana wujud.';

  @override
  String get conditionFilePathsAllHelp =>
      'Satu laluan setiap baris, relatif kepada direktori asas. Laluan benar hanya apabila semua wujud.';

  @override
  String get conditionBaseKey => 'Kunci direktori asas';

  @override
  String get conditionBaseKeyHelp =>
      'Kunci keadaan yang memegang direktori laluan diselesaikan terhadapnya (lalai repo_local_path).';

  @override
  String get conditionRecursive => 'Cari subdirektori';

  @override
  String get conditionNegate => 'Songsangkan: laluan benar apabila tiada';

  @override
  String get conditionLeft => 'Nilai kiri';

  @override
  String get conditionOperator => 'Pengendali';

  @override
  String get conditionRight => 'Nilai kanan';

  @override
  String get conditionSwitchKey => 'Suis pada kunci keadaan';

  @override
  String get conditionCases => 'Kes (dipisahkan koma)';

  @override
  String get conditionCasesHelp =>
      'Kunci laluan untuk dipadankan dengan nilai, mengikut urutan.';

  @override
  String get conditionDefaultCase => 'Kes lalai';

  @override
  String get triggerManualHelp =>
      'Tunjukkan pada halaman larian dan mulakan secara manual.';

  @override
  String get triggerKindSchedule => 'Pada jadual';

  @override
  String get triggerScheduleExprLabel => 'Jadual (cron atau every:seconds)';

  @override
  String get triggerTimezoneLabel => 'Zon waktu (pilihan)';

  @override
  String get triggerCatchUpLabel => 'Pada larian terlepas';

  @override
  String get triggerCatchUpRunOnce => 'Jalankan sekali';

  @override
  String get triggerCatchUpSkip => 'Langkau';

  @override
  String get syncHealthTitle => 'Kesihatan segerak';

  @override
  String get syncHealthNoConfigs => 'Belum ada sambungan segerak';

  @override
  String get syncHealthNeverSynced => 'Tidak pernah disegerakkan';

  @override
  String get syncOutcomeOk => 'Disegerakkan';

  @override
  String get syncOutcomeFailed => 'Gagal';

  @override
  String get syncOutcomeSkipped => 'Dilangkau';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count kegagalan berturut-turut';
  }

  @override
  String get triggerWebhookHelp =>
      'URL webhook yang ditandatangani dijana. Sistem luaran POST kepadanya untuk memulakan pipeline ini.';

  @override
  String get triggerWebhookPathLabel => 'Laluan webhook';

  @override
  String get triggerMatchStatusLabel => 'Hanya apabila status ialah';

  @override
  String get triggerSummaryNone => 'Tiada pencetus';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Setiap ${seconds}s';
  }

  @override
  String get triggerEventManual => 'Larian manual';

  @override
  String get triggerEventSchedule => 'Jadual';

  @override
  String get triggerEventPrStatusChanged => 'Status PR berubah';

  @override
  String get triggerEventExternalPr => 'PR luaran dibuka';

  @override
  String get triggerEventPrPublished => 'PR diterbitkan';

  @override
  String get triggerEventPrMerged => 'PR dicantum';

  @override
  String get triggerEventRepoAdded => 'Repositori ditambah';

  @override
  String get triggerEventCodeGraphWatch => 'Perubahan fail';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fail diubah',
      one: '1 fail diubah',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '+$count lagi';
  }

  @override
  String get pipelineRunCauseRescan => 'Berubah pada cakera';

  @override
  String get pipelineRunCauseInitial => 'Indeks pertama checkout ini';

  @override
  String get triggerEventMessageReceived => 'Mesej diterima';

  @override
  String get triggerEventTicketCompleted => 'Tiket selesai';

  @override
  String get triggerEventTicketFailed => 'Tiket gagal';

  @override
  String get triggerEventTicketCancelled => 'Tiket dibatalkan';

  @override
  String get triggerEventBudgetCrossed => 'Ambang bajet dilampaui';

  @override
  String get nodeLibrarySearchHint => 'Cari nod';

  @override
  String get nodeLibraryNoMatches => 'Tiada nod yang sepadan';

  @override
  String get nodeCategoryFlow => 'Aliran & logik';

  @override
  String get nodeCategoryPr => 'Semakan PR';

  @override
  String get nodeCategoryAgents => 'Ejen';

  @override
  String get nodeCategoryMessaging => 'Pemesejan';

  @override
  String get nodeCategoryCode => 'Kod';

  @override
  String get triggerDisabledTag => 'mati';

  @override
  String get pipelineInputTypeRepo => 'Repositori';

  @override
  String get pipelineRunNoRepos =>
      'Belum ada repositori dalam ruang kerja ini.';

  @override
  String get allowTicketingApi => 'Benarkan panggilan API tiket';

  @override
  String get ticketingApiKey => 'Kunci API tiket';

  @override
  String get ticketingApiKeySubtitle =>
      'Menyuntik kunci API penyedia tiket ke dalam kotak pasir.';

  @override
  String get ticketingProvider => 'Penyedia tiket';

  @override
  String get connectGitHubAndTicketing =>
      'Sambungkan hos kod supaya Control Center boleh membaca pull request, isu dan semakan anda. Secara pilihan sambungkan penyedia tiket. Kelayakan dipegang oleh pelayan anda, bukan oleh mesin ini.';

  @override
  String get triggerEventTicketAssigned => 'Tiket ditugaskan';

  @override
  String get triggerEventTicketCreated => 'Tiket dicipta';

  @override
  String get triggerEventTicketStatusChanged => 'Status tiket berubah';

  @override
  String get triggerEventMeetingRecordingStopped =>
      'Rakaman mesyuarat dihentikan';

  @override
  String get triggerEventSkillUpdated => 'Kemahiran dikemas kini';

  @override
  String get triggerEventSpaceDeleted => 'Ruang dipadam';

  @override
  String get triggerExternalPrHelp =>
      'Permintaan tarik yang dibuka pada hos kod, bukan dari Control Center.';

  @override
  String get triggerPrPublishedHelp =>
      'Permintaan tarik yang dibuka dari Control Center atau oleh ejen.';

  @override
  String get triggerPrStatusChangedHelp =>
      'Digabungkan, ditutup, dibuka, dibuka semula atau diluluskan. Tapiskan mengikut status dalam pemeriksa.';

  @override
  String get triggerPrMergedHelp =>
      'Hanya apabila permintaan tarik digabungkan, bukan ditutup atau dibuka semula.';

  @override
  String get triggerRepoAddedHelp => 'Repositori dipautkan ke ruang kerja ini.';

  @override
  String get triggerCodeGraphWatchHelp =>
      'Fail dalam repositori dipaut berubah pada cakera.';

  @override
  String get triggerMessageReceivedHelp => 'Mesej baharu tiba dalam ruang.';

  @override
  String get triggerTicketCreatedHelp => 'Tiket dicipta dalam ruang kerja ini.';

  @override
  String get triggerTicketStatusChangedHelp => 'Tiket beralih antara status.';

  @override
  String get triggerTicketCompletedHelp => 'Tiket selesai dengan jayanya.';

  @override
  String get triggerTicketFailedHelp =>
      'Jalan ejen gagal dan tiket ditanda gagal.';

  @override
  String get triggerTicketCancelledHelp =>
      'Tiket dibatalkan dan tidak akan diteruskan.';

  @override
  String get triggerBudgetCrossedHelp =>
      'Had perbelanjaan ruang kerja atau ejen dilampaui.';

  @override
  String get triggerTicketAssignedHelp =>
      'Tiket ditugaskan kepada orang, ejen atau pasukan.';

  @override
  String get triggerMeetingRecordingStoppedHelp => 'Rakaman mesyuarat tamat.';

  @override
  String get triggerSkillUpdatedHelp => 'Kemahiran dipasang atau dikemas kini.';

  @override
  String get triggerSpaceDeletedHelp => 'Ruang perbualan dipadam.';

  @override
  String get navTickets => 'Tiket';

  @override
  String get ticketsTitle => 'Tiket';

  @override
  String get newTicket => 'Tiket baharu';

  @override
  String get noTicketsYet => 'Belum ada tiket';

  @override
  String get addCollaborator => 'Tambah rakan kolaborasi';

  @override
  String get noCollaborators => 'Belum ada rakan kolaborasi';

  @override
  String get linkedPullRequests => 'Pull request terpaut';

  @override
  String get noLinkedPullRequests => 'Belum ada pull request terpaut';

  @override
  String get stopAgent => 'Henti ejen';

  @override
  String get ticketProperties => 'Sifat';

  @override
  String get ticketTabIssue => 'Isu';

  @override
  String get ticketSelectPrompt => 'Pilih tiket untuk melihat butirannya';

  @override
  String get unassigned => 'Tidak ditugaskan';

  @override
  String get ticketStatusBacklog => 'Backlog';

  @override
  String get ticketStatusOpen => 'Untuk dilakukan';

  @override
  String get ticketStatusInProgress => 'Sedang berjalan';

  @override
  String get ticketStatusInReview => 'Dalam semakan';

  @override
  String get ticketStatusDone => 'Selesai';

  @override
  String get ticketStatusBlocked => 'Disekat';

  @override
  String get ticketStatusFailed => 'Gagal';

  @override
  String get ticketStatusCancelled => 'Dibatalkan';

  @override
  String get notificationTicketAssigned => 'Tiket ditugaskan';

  @override
  String get notificationTicketStatusChanged => 'Status tiket berubah';

  @override
  String get priority => 'Keutamaan';

  @override
  String get status => 'Status';

  @override
  String get assignee => 'Penerima tugasan';

  @override
  String get labels => 'Label';

  @override
  String get noLabelsYet => 'Belum ada label';

  @override
  String get clearLabels => 'Kosongkan label';

  @override
  String get pipelineStepAgentActivity => 'Aktiviti ejen';

  @override
  String get runStatusCompleted => 'Selesai';

  @override
  String get runStatusQueued => 'Dalam barisan';

  @override
  String get ticketDescription => 'Perihalan';

  @override
  String get ticketPriorityNone => 'Tiada';

  @override
  String get ticketPriorityUrgent => 'Mendesak';

  @override
  String get ticketPriorityHigh => 'Tinggi';

  @override
  String get ticketPriorityMedium => 'Sederhana';

  @override
  String get ticketPriorityLow => 'Rendah';

  @override
  String get ticketViewList => 'Senarai';

  @override
  String get ticketViewBoard => 'Papan';

  @override
  String get ticketTitlePlaceholder => 'Tajuk isu';

  @override
  String get ticketDescriptionPlaceholder => 'Tambah perihalan…';

  @override
  String get createMore => 'Cipta lagi';

  @override
  String selectedCount(int count) {
    return '$count dipilih';
  }

  @override
  String get clearSelection => 'Kosongkan pilihan';

  @override
  String get bulkDeleteTitle => 'Padam tiket';

  @override
  String bulkDeleteMessage(int count) {
    return 'Padam $count tiket yang dipilih? Ini tidak boleh dibuat asal.';
  }

  @override
  String get assignTo => 'Tugaskan kepada…';

  @override
  String get sectionMembers => 'Ahli';

  @override
  String get sectionAgents => 'Ejen';

  @override
  String get sidebarGroupWorkspace => 'Ruang kerja';

  @override
  String get notificationsTitle => 'Pemberitahuan';

  @override
  String get notificationsTooltip => 'Pemberitahuan';

  @override
  String get notificationsEmpty => 'Anda sudah mengejar semuanya';

  @override
  String notificationsUnreadCount(int count) {
    return '$count belum dibaca';
  }

  @override
  String get notificationsMarkRead => 'Tanda sebagai dibaca';

  @override
  String get notificationsMarkUnread => 'Tanda sebagai belum dibaca';

  @override
  String get notificationsEntryActions => 'Tindakan pemberitahuan';

  @override
  String get markAllRead => 'Tanda semua sebagai dibaca';

  @override
  String get teamsNav => 'Pasukan';

  @override
  String get noWorkspace => 'Tiada ruang kerja';

  @override
  String get selectWorkspace => 'Pilih ruang kerja';

  @override
  String get navMemory => 'Memori';

  @override
  String get memoryTabFacts => 'Fakta';

  @override
  String get memoryTabPolicies => 'Polisi';

  @override
  String get memoryGraphShowFacts => 'Tunjuk fakta';

  @override
  String get memoryGraphHideFacts => 'Sembunyi fakta';

  @override
  String get memoryGraphExpandAll => 'Kembangkan semua fakta';

  @override
  String get memoryGraphCollapseAll => 'Runtuhkan semua fakta';

  @override
  String get memoryTabGraph => 'Graf pengetahuan';

  @override
  String get memoryNoWorkspace => 'Pilih ruang kerja untuk melihat memorinya.';

  @override
  String get searchArticles => 'Cari artikel';

  @override
  String get filterAll => 'Semua';

  @override
  String get filterUnread => 'Belum dibaca';

  @override
  String get filterSaved => 'Disimpan';

  @override
  String get saveArticle => 'Simpan artikel';

  @override
  String get removeFromSaved => 'Buang dari disimpan';

  @override
  String get filterBySource => 'Tapis mengikut sumber';

  @override
  String get viewAsList => 'Paparan senarai';

  @override
  String get viewAsGrid => 'Paparan grid';

  @override
  String get noMatchingArticles => 'Tiada artikel yang sepadan';

  @override
  String get noMatchingArticlesBody =>
      'Cuba carian atau penapis sumber yang berbeza.';

  @override
  String get allCaughtUp => 'Sudah mengejar semuanya';

  @override
  String get allCaughtUpBody =>
      'Tiada artikel belum dibaca — semak semula kemudian.';

  @override
  String get openArticlesInAppDescription =>
      'Buka pautan dalam pembaca terbina dan bukan penyemak imbas lalai anda.';

  @override
  String get blockAdsTrackersDescription =>
      'Buang iklan, penjejak dan sepanduk kuki dari artikel yang anda buka dalam pembaca.';

  @override
  String get agentQuestionHeader => 'Soalan untuk anda';

  @override
  String get agentQuestionAnsweredLabel => 'Dijawab';

  @override
  String get agentQuestionFreeformHint => 'Taip jawapan anda…';

  @override
  String agentQuestionProgress(int index, int count) {
    return 'Soalan $index daripada $count';
  }

  @override
  String get agentQuestionSkip => 'Langkau';

  @override
  String get agentQuestionSkippedLabel => 'Dilangkau';

  @override
  String get agentQuestionFreeformOptionHint =>
      'Terangkan dengan kata-kata anda…';

  @override
  String get reviewRequested => 'Semakan diminta';

  @override
  String get connectGitHubHint =>
      'Log masuk ke GitHub atau tambah token dalam Tetapan → Anda → Profil & identiti → Hos kod';

  @override
  String get connectGitHubToLoadPrs =>
      'Sambung GitHub untuk memuatkan pull request';

  @override
  String get noRepositoriesConfigured => 'Tiada repositori dikonfigurasikan';

  @override
  String openedAgo(String age) {
    return 'Dibuka $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author membuka pull request ini';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commit',
      one: '1 commit',
    );
    return '$author membuka pull request ini dengan $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor meminta semakan dari $reviewers';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor membuang permintaan semakan untuk $reviewers';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor meminta semakan dari $requested dan membuang permintaan semakan untuk $removed';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'label',
      one: 'label',
    );
    return '$actor menambah $_temp0 $labels';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'label',
      one: 'label',
    );
    return '$actor membuang $_temp0 $labels';
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
      other: 'label',
      one: 'label',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: 'label',
      one: 'label',
    );
    return '$actor menambah $_temp0 $added dan membuang $_temp1 $removed';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author commit';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commit',
      one: '1 commit',
    );
    return '$author push $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author meluluskan perubahan ini';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author meminta perubahan';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count komen kod',
      one: '1 komen kod',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author menyemak';
  }

  @override
  String get prTimelineSomeone => 'Seseorang';

  @override
  String get prTimelineBotBadge => 'bot';

  @override
  String updatedAgo(String age) {
    return 'Dikemas kini $age';
  }

  @override
  String get checksPassing => 'Semakan lulus';

  @override
  String get checksRunning => 'Semakan berjalan';

  @override
  String get needsYourReview => 'Memerlukan semakan anda';

  @override
  String get checks => 'Semakan';

  @override
  String get noReviewersAssigned => 'Tiada penyemak ditugaskan';

  @override
  String get noAssignees => 'Tiada penerima tugasan';

  @override
  String get loadingEllipsis => 'Memuatkan…';

  @override
  String get loadingChecks => 'Memuatkan semakan…';

  @override
  String get noChecksYet => 'Belum ada semakan dijalankan';

  @override
  String get noChangesToReview => 'Tiada perubahan untuk disemak';

  @override
  String checksFailingCount(int count) {
    return '$count gagal';
  }

  @override
  String get showMore => 'Tunjuk lagi';

  @override
  String get showLess => 'Tunjuk kurang';

  @override
  String get backToPullRequests => 'Kembali ke pull request';

  @override
  String get pullRequestNotFound => 'Pull request tidak dijumpai';

  @override
  String get pullRequestNotFoundBody =>
      'Ia mungkin telah dicantum, ditutup atau dipindah.';

  @override
  String get couldntLoadPullRequest => 'Tidak dapat memuatkan pull request ini';

  @override
  String get showDetails => 'Tunjuk butiran';

  @override
  String get noDescriptionProvided => 'Tiada perihalan diberikan.';

  @override
  String get factsHint => 'Fakta akan muncul di sini semasa ejen anda belajar.';

  @override
  String get noFactsMatch => 'Tiada fakta sepadan dengan carian anda';

  @override
  String get memoryLoadError => 'Tidak dapat memuatkan memori';

  @override
  String get sortRecent => 'Terkini';

  @override
  String get sortConfidence => 'Keyakinan';

  @override
  String get confidenceTooltip =>
      'Seberapa pasti ejen bahawa fakta ini benar, dari 0 hingga 100%.';

  @override
  String get supersededTooltip =>
      'Fakta yang lebih baharu telah menggantikan yang ini.';

  @override
  String get domain => 'Domain';

  @override
  String get fitToView => 'Muatkan ke paparan';

  @override
  String get project => 'Projek';

  @override
  String get newProject => 'Projek baharu';

  @override
  String get editProject => 'Sunting projek';

  @override
  String get deleteProject => 'Padam projek';

  @override
  String get noProject => 'Tiada projek';

  @override
  String get allTickets => 'Semua tiket';

  @override
  String get projectNamePlaceholder => 'Nama projek';

  @override
  String get projectDescriptionPlaceholder => 'Perihalan (pilihan)';

  @override
  String get projectColorLabel => 'Warna';

  @override
  String get noProjectsYet => 'Belum ada projek';

  @override
  String get projectTicketsEmpty => 'Belum ada tiket dalam projek ini';

  @override
  String get createProject => 'Cipta projek';

  @override
  String projectProgress(int done, int total) {
    return '$done daripada $total selesai';
  }

  @override
  String deleteProjectConfirm(String name) {
    return 'Padam \"$name\"? Tiketnya dikekalkan dan dibuang dari projek.';
  }

  @override
  String get projectStatusActive => 'Aktif';

  @override
  String get projectStatusCompleted => 'Selesai';

  @override
  String get projectStatusArchived => 'Diarkibkan';

  @override
  String get markProjectCompleted => 'Tanda selesai';

  @override
  String get markProjectActive => 'Tanda aktif';

  @override
  String get archiveProject => 'Arkibkan';

  @override
  String get restoreProject => 'Pulihkan';

  @override
  String get relations => 'Hubungan';

  @override
  String get relateTo => 'Kaitkan dengan';

  @override
  String get relationSubIssueOf => 'Sub-isu bagi…';

  @override
  String get relationParentOf => 'Induk bagi…';

  @override
  String get relationBlockedBy => 'Disekat oleh…';

  @override
  String get relationBlocking => 'Menyekat…';

  @override
  String get relationRelatedTo => 'Berkaitan dengan…';

  @override
  String get relationDuplicateOf => 'Pendua bagi…';

  @override
  String get relationGroupParent => 'Induk';

  @override
  String get relationGroupSubIssues => 'Sub-isu';

  @override
  String get relationGroupBlockedBy => 'Disekat oleh';

  @override
  String get relationGroupBlocking => 'Menyekat';

  @override
  String get relationGroupRelated => 'Berkaitan';

  @override
  String get relationGroupDuplicateOf => 'Pendua bagi';

  @override
  String get relationGroupDuplicatedBy => 'Diduakan oleh';

  @override
  String get copyId => 'Salin ID';

  @override
  String get ticketIdCopied => 'ID tiket disalin';

  @override
  String get searchTicketsHint => 'Cari tiket…';

  @override
  String get noMatchingTickets => 'Tiada tiket sepadan';

  @override
  String get clearAll => 'Kosongkan semua';

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PR',
      one: '1 PR',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos repo',
      one: '1 repo',
    );
    return '$_temp0 menunggu semakan anda merentasi $_temp1';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'Namakan semula ruang kerja dan ubah tandanya — pilih satu di kiri untuk menyuntingnya.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ruang kerja',
      one: '1 ruang kerja',
      zero: 'Tiada ruang kerja',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos repo',
      one: '1 repo',
      zero: 'Tiada repo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents ejen',
      one: '1 ejen',
      zero: '0 ejen',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'Identiti';

  @override
  String get uploadImage => 'Muat naik imej';

  @override
  String get failedToSaveLogo =>
      'Gagal menyimpan imej logo. Pastikan apl boleh membaca fail yang dipilih.';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG atau GIF sehingga 2 MB. Jika tidak, kami akan menggunakan inisial ruang kerja.';

  @override
  String get workspaceNameFieldHelp =>
      'Ditunjukkan dalam penukar, jejak roti dan pada setiap skrin.';

  @override
  String get dangerZone => 'Zon bahaya';

  @override
  String get deleteThisWorkspace => 'Padam ruang kerja ini';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Membuang $name secara kekal, sambungan repositorinya, ejen dan memori. Ini tidak boleh dibuat asal.';
  }

  @override
  String get discard => 'Buang';

  @override
  String discardChangesQuestion(String name) {
    return 'Buang perubahan yang belum disimpan pada $name?';
  }

  @override
  String get workspaceUpdated => 'Ruang kerja dikemas kini';

  @override
  String get editTitle => 'Sunting tajuk';

  @override
  String get editDescription => 'Sunting perihalan';

  @override
  String get addDescription => 'Tambah perihalan';

  @override
  String get prTitlePlaceholder => 'Tajuk';

  @override
  String get prBodyPlaceholder => 'Tinggalkan perihalan';

  @override
  String get write => 'Tulis';

  @override
  String get overview => 'Gambaran keseluruhan';

  @override
  String get noFilesChanged => 'Tiada fail diubah';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Pratonton';

  @override
  String get outdated => 'Lapuk';

  @override
  String get outdatedComments => 'Komen lapuk';

  @override
  String outdatedCountLabel(int count) {
    return '$count lapuk';
  }

  @override
  String get prTemplateLabel => 'Templat';

  @override
  String get prTemplateDefault => 'Lalai';

  @override
  String get addReviewers => 'Tambah penyemak';

  @override
  String get addAssignees => 'Tambah penerima tugasan';

  @override
  String get searchUsers => 'Cari orang…';

  @override
  String get searchReviewers => 'Cari orang dan pasukan…';

  @override
  String get usersSectionLabel => 'Orang';

  @override
  String get userStatusBusy => 'Sibuk';

  @override
  String get teamsSectionLabel => 'Pasukan';

  @override
  String get suggestedReviewers => 'Penyemak dicadangkan';

  @override
  String get noMatchingUsers => 'Tiada orang yang sepadan';

  @override
  String get noMatchingReviewers => 'Tiada padanan';

  @override
  String get requiredByCodeOwners => 'Diperlukan oleh pemilik kod';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'melalui $login';
  }

  @override
  String get team => 'Pasukan';

  @override
  String get markdownBold => 'Tebal';

  @override
  String get markdownItalic => 'Italik';

  @override
  String get markdownHeading => 'Tajuk';

  @override
  String get markdownBulletList => 'Senarai berbulet';

  @override
  String get markdownChecklist => 'Senarai semak';

  @override
  String get markdownCode => 'Kod';

  @override
  String get markdownLink => 'Pautan';

  @override
  String get markdownQuote => 'Petikan';

  @override
  String get markdownSupported => 'Markdown disokong';

  @override
  String get markdownAttachImages => 'Klik untuk menambah imej';

  @override
  String failedToUpdateTitle(String error) {
    return 'Tidak dapat mengemas kini tajuk: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Tidak dapat mengemas kini perihalan: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Tidak dapat mengemas kini penyemak: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Tidak dapat mengemas kini penerima tugasan: $error';
  }

  @override
  String get discardChangesConfirm => 'Buang perubahan anda?';

  @override
  String get newPr => 'PR baharu';

  @override
  String get openPullRequest => 'Buka pull request';

  @override
  String get composePrSubtitle =>
      'Dari cawangan yang anda push — tiada ejen atau tiket terlibat';

  @override
  String get createAsDraft => 'Cipta sebagai draf';

  @override
  String get composePrNoRepo => 'Tiada repositori GitHub dipilih';

  @override
  String get composePrNoRepoHint =>
      'Pilih ruang kerja dengan repositori terpaut GitHub untuk membuka pull request.';

  @override
  String get composePrPickBranches =>
      'Pilih cawangan asas dan banding untuk pratonton perubahan.';

  @override
  String get composePrNothingToCompare =>
      'Tiada perubahan antara cawangan ini.';

  @override
  String get repository => 'Repositori';

  @override
  String get baseBranchLabel => 'Asas';

  @override
  String get compareBranchLabel => 'Banding';

  @override
  String get selectBranch => 'Pilih cawangan';

  @override
  String get navMeetings => 'Mesyuarat';

  @override
  String get meetingsNoWorkspace =>
      'Pilih ruang kerja untuk melihat mesyuarat.';

  @override
  String get meetingsEmpty => 'Belum ada mesyuarat';

  @override
  String get meetingsEmptyHint =>
      'Rakam mesyuarat pertama anda — audio kekal pada peranti ini dan ejen menukarnya kepada nota, keputusan dan item tindakan.';

  @override
  String get meetingNotesHint =>
      'Catat nota pantas — ejen mengembangkannya selepas mesyuarat.';

  @override
  String get meetingSpeakerMe => 'Anda';

  @override
  String get meetingStatusRecording => 'Merakam';

  @override
  String get meetingStatusProcessing => 'Memproses';

  @override
  String get meetingStatusDone => 'Selesai';

  @override
  String get meetingStatusFailed => 'Gagal';

  @override
  String get meetingsSubtitle =>
      'Ditangkap dan ditranskrip pada peranti ini, kemudian diringkaskan oleh ejen.';

  @override
  String get meetingsRecordMeeting => 'Rakam mesyuarat';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sedang diproses',
      one: '1 sedang diproses',
    );
    return '$_temp0';
  }

  @override
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mesyuarat',
      one: '1 mesyuarat',
      zero: 'Tiada mesyuarat',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'Tindakan terbuka';

  @override
  String get meetingsLedgerDecisions => 'Keputusan';

  @override
  String get meetingsLiveOpen => 'Buka rakaman';

  @override
  String get meetingTemplateShort => 'Templat';

  @override
  String get meetingsStatThisWeek => 'Minggu ini';

  @override
  String get meetingsStatRecorded => 'Dirakam';

  @override
  String get meetingsFilterAll => 'Semua';

  @override
  String get meetingsFilterDone => 'Selesai';

  @override
  String get meetingsFilterProcessing => 'Memproses';

  @override
  String get meetingsSearchHint => 'Tapis mengikut tajuk, orang, apl…';

  @override
  String get meetingsBucketToday => 'Hari ini';

  @override
  String get meetingsBucketYesterday => 'Semalam';

  @override
  String get meetingsBucketEarlierThisWeek => 'Awal minggu ini';

  @override
  String get meetingsBucketLastWeek => 'Minggu lalu';

  @override
  String get meetingsBucketOlder => 'Lebih lama';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keputusan',
      one: '1 keputusan',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total item tindakan';
  }

  @override
  String get meetingsEnhancedPill => 'diperkaya';

  @override
  String get meetingsTranscribing => 'mentranskrip & meringkaskan…';

  @override
  String get meetingsOpenAction => 'Buka';

  @override
  String get meetingsStopProcessing => 'Henti';

  @override
  String get meetingsStillTranscribing =>
      'Masih mentranskrip — ringkasan muncul apabila ia selesai.';

  @override
  String get meetingsNoMatch => 'Tiada mesyuarat sepadan';

  @override
  String get meetingsNoMatchHint =>
      'Cuba penapis atau terma carian yang berbeza.';

  @override
  String get meetingBackAllMeetings => 'Semua mesyuarat';

  @override
  String get meetingReRunSummary => 'Jalankan semula ringkasan';

  @override
  String get meetingExport => 'Eksport';

  @override
  String get meetingAugmentingBanner =>
      'Memperkaya nota anda dari transkrip — mengekstrak keputusan dan item tindakan…';

  @override
  String get meetingTabNotes => 'Nota';

  @override
  String get meetingTabTranscript => 'Transkrip';

  @override
  String get meetingTabActionItems => 'Item tindakan';

  @override
  String get meetingTabDecisions => 'Keputusan';

  @override
  String get meetingNotesEnhancedToggle => 'Diperkaya';

  @override
  String get meetingNotesYoursToggle => 'Nota anda';

  @override
  String get meetingEnhancedByAgent => 'Diperkaya oleh ejen · dari transkrip';

  @override
  String get meetingEnhancedPending => 'Ejen masih mengerjakan ringkasan ini.';

  @override
  String get meetingNotesEmpty => 'Belum ada nota diperkaya.';

  @override
  String get meetingNotesSavedLocally => 'Disimpan secara setempat';

  @override
  String get meetingNotesSaving => 'Menyimpan…';

  @override
  String get meetingViewFullTranscript => 'Lihat transkrip penuh';

  @override
  String get meetingTranscriptSearchHint => 'Cari transkrip…';

  @override
  String get meetingSpeakerEveryone => 'Semua orang';

  @override
  String get meetingSpeakerOthers => 'Lain-lain';

  @override
  String get meetingTranscriptEmpty => 'Belum ada transkrip.';

  @override
  String get meetingActionItemsEmpty => 'Tiada item tindakan diekstrak.';

  @override
  String get meetingActionItemFrom => 'dari mesyuarat ini';

  @override
  String get meetingCreateTicket => 'Cipta tiket';

  @override
  String meetingTicketCreated(String key) {
    return 'Tiket $key dicipta dan dihantar.';
  }

  @override
  String get meetingTicketFailed => 'Tidak dapat mencipta tiket.';

  @override
  String get meetingDecisionsEmpty => 'Tiada keputusan dilog.';

  @override
  String get meetingEditTitle => 'Sunting tajuk';

  @override
  String get meetingTitleLabel => 'Tajuk';

  @override
  String get meetingAddActionItem => 'Tambah item tindakan';

  @override
  String get meetingEditActionItem => 'Sunting item tindakan';

  @override
  String get meetingDeleteActionItem => 'Padam item tindakan';

  @override
  String get meetingActionItemContentLabel => 'Item tindakan';

  @override
  String get meetingActionItemContentHint => 'Apa yang perlu berlaku?';

  @override
  String get meetingActionItemOwnerLabel => 'Pemilik';

  @override
  String get meetingActionItemOwnerHint =>
      'Siapa yang bertanggungjawab? (pilihan)';

  @override
  String get meetingAddDecision => 'Tambah keputusan';

  @override
  String get meetingEditDecision => 'Sunting keputusan';

  @override
  String get meetingDeleteDecision => 'Padam keputusan';

  @override
  String get meetingDecisionContentLabel => 'Keputusan';

  @override
  String get meetingDecisionContentHint => 'Apa yang diputuskan?';

  @override
  String get meetingReRunStarted =>
      'Menjalankan semula peringkas pada transkrip…';

  @override
  String get meetingReRunNoTranscript =>
      'Belum ada transkrip untuk diringkaskan.';

  @override
  String get meetingExportCopied =>
      'Nota disalin ke papan keratan sebagai Markdown.';

  @override
  String get meetingExportSaved => 'Mesyuarat dieksport.';

  @override
  String meetingExportFailed(String error) {
    return 'Eksport gagal: $error';
  }

  @override
  String get meetingExportNothing => 'Belum ada apa untuk dieksport.';

  @override
  String get meetingPlaybackPlay => 'Main';

  @override
  String get meetingPlaybackPause => 'Jeda';

  @override
  String get meetingPlaybackUnavailable =>
      'Main balik audio tidak tersedia pada peranti ini.';

  @override
  String get meetingDetectedTitle => 'Mesyuarat dikesan';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'Nampaknya \"$label\" sedang berlangsung. Rakamnya?';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'Nampaknya mesyuarat sedang berlangsung. Rakamnya?';

  @override
  String get meetingDetectedRecord => 'Rakam';

  @override
  String get meetingDetectedDismiss => 'Tolak';

  @override
  String get meetingAutoStopTitle =>
      'Mesyuarat ini nampaknya sudah tamat. Henti rakaman?';

  @override
  String get meetingAutoStopStop => 'Henti';

  @override
  String get meetingAutoStopKeep => 'Teruskan merakam';

  @override
  String get meetingAutoDetect => 'Kesan mesyuarat secara automatik';

  @override
  String get meetingAutoDetectDescription =>
      'Pantau kalendar dan apl persidangan dan tawarkan untuk merakam apabila mesyuarat bermula.';

  @override
  String get meetingsRecordingCrumb => 'Merakam…';

  @override
  String get meetingRecordTitleHint => 'Tajuk mesyuarat';

  @override
  String get meetingRecordTappingLabel => 'Mengetuk:';

  @override
  String get meetingRecordMic => 'Mikrofon';

  @override
  String get meetingRecordSystemAudio => 'Audio sistem';

  @override
  String get meetingRecordPause => 'Jeda';

  @override
  String get meetingRecordResume => 'Sambung';

  @override
  String get meetingRecordStop => 'Henti & ringkaskan';

  @override
  String get meetingRecordYourNotes => 'Nota anda';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Taip semasa anda mendengar. Beberapa serpihan sudah cukup — selepas anda berhenti, ejen mengembangkannya menggunakan transkrip.';

  @override
  String get meetingRecordLiveTranscript => 'Transkrip langsung';

  @override
  String get meetingRecordDecoding => 'menyahkod pada peranti';

  @override
  String get meetingRecordListening =>
      'Mendengar… pertuturan muncul di sini dalam satu atau dua saat, ditandai Anda / Lain-lain.';

  @override
  String get meetingRecordPausedHint =>
      'Dijeda — audio diabaikan sehingga anda sambung semula.';

  @override
  String get meetingRecordNotActive => 'Tiada rakaman aktif.';

  @override
  String get meetingHudRecording => 'merakam';

  @override
  String get meetingHudPaused => 'dijeda';

  @override
  String get meetingHudOpen => 'Buka';

  @override
  String get meetingHudStop => 'Henti';

  @override
  String get meetingToolbarPopOut => 'Keluarkan';

  @override
  String get meetingToolbarHoldToStop => 'Tahan untuk henti rakaman';

  @override
  String get meetingToolbarSemanticLabel => 'Bar alat rakaman mesyuarat';

  @override
  String get orchestrate => 'Orkestrakan';

  @override
  String get orchestrationUnavailable => 'Orkestrasi tidak tersedia';

  @override
  String get orchestrationApprove => 'Luluskan rancangan';

  @override
  String get orchestrationReject => 'Tolak';

  @override
  String get orchestrationCancel => 'Batal orkestrasi';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count peranan — $hires pengambilan baharu';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count sub-tiket';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Anggaran kos: \$$amount';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total sub-tiket selesai';
  }

  @override
  String get orchestrationStatusProposed => 'Dicadangkan';

  @override
  String get orchestrationStatusApproved => 'Diluluskan';

  @override
  String get orchestrationStatusExecuting => 'Melaksanakan';

  @override
  String get orchestrationStatusSynthesizing => 'Mensintesis';

  @override
  String get orchestrationStatusCompleted => 'Selesai';

  @override
  String get orchestrationStatusFailed => 'Gagal';

  @override
  String get orchestrationStatusCancelled => 'Dibatalkan';

  @override
  String get messageFailed => 'Larian gagal';

  @override
  String get turnLimitReached =>
      'Berhenti pada had giliran — balas untuk meneruskan';

  @override
  String get retried => 'Dicuba semula';

  @override
  String replyingTo(String name) {
    return 'membalas $name';
  }

  @override
  String get silenceTimeoutLabel => 'Tamat masa senyap (minit)';

  @override
  String get silenceTimeoutHint =>
      'e.g. 15 — tamatkan larian selepas tempoh ini tanpa output';

  @override
  String get capabilityJsonMode => 'Modus JSON';

  @override
  String get capabilityModelSelection => 'Pemilihan model';

  @override
  String get transcriptThinking => 'Berfikir…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'Berfikir selama $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'Membuat suntingan…';

  @override
  String get transcriptStatusReadingFiles => 'Membaca fail…';

  @override
  String get transcriptStatusSearching => 'Mencari pangkalan kod…';

  @override
  String get transcriptStatusRunningCommands => 'Menjalankan perintah…';

  @override
  String get transcriptStatusResponding => 'Membalas…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'Menjalankan $tool…';
  }

  @override
  String get transcriptInput => 'Input';

  @override
  String get transcriptOutput => 'Output';

  @override
  String get transcriptErrorLabel => 'Ralat';

  @override
  String get transcriptSandboxBlocked => 'Kotak pasir menyekat tindakan';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'Tunjuk output penuh (+$kb KB)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'Tunjuk semua $count baris';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'Menunjukkan $count baris pertama';
  }

  @override
  String get transcriptGrepNoMatches => 'Tiada padanan';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches padanan',
      one: '1 padanan',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files fail',
      one: '1 fail',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'Orang $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'Namakan semula penutur';

  @override
  String get meetingRenameSpeakerTitle => 'Namakan semula penutur';

  @override
  String get meetingSpeakerNameLabel => 'Nama';

  @override
  String get meetingSpeakerSuggestFromCalendar =>
      'Dari tetamu jemputan mesyuarat ini';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'Terapkan pada semua blok dari penutur ini';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'Apabila dimatikan, hanya baris yang dipilih dinamakan semula.';

  @override
  String get meetingLinkEvent => 'Pautkan ke acara';

  @override
  String get meetingChangeEvent => 'Tukar acara';

  @override
  String get meetingLinkEventTitle => 'Pautkan ke acara kalendar';

  @override
  String get meetingLinkEventSearchHint => 'Cari acara';

  @override
  String get meetingLinkEventEmpty => 'Tiada acara kalendar berdekatan';

  @override
  String get meetingUnlinkEvent => 'Buang pautan';

  @override
  String get calendarLinkExistingMeeting => 'Pautkan ke mesyuarat sedia ada';

  @override
  String get calendarLinkMeetingTitle => 'Pautkan mesyuarat';

  @override
  String get calendarLinkMeetingSearchHint => 'Cari mesyuarat';

  @override
  String get calendarLinkMeetingEmpty => 'Tiada mesyuarat untuk dipautkan';

  @override
  String get meetingRenameSpeakerFailed =>
      'Tidak dapat menamakan semula penutur';

  @override
  String get calendarLinkUpdateFailed =>
      'Tidak dapat mengemas kini pautan kalendar';

  @override
  String get rename => 'Namakan semula';

  @override
  String get notNow => 'Bukan sekarang';

  @override
  String get meetingSaveVoiceProfileTitle => 'Simpan profil suara?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'Kenali $name secara automatik dalam mesyuarat akan datang dengan menyimpan cap suara mereka.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'Profil suara disimpan untuk $name';
  }

  @override
  String get meetingVoiceProfileSaveFailed =>
      'Tidak dapat menyimpan profil suara';

  @override
  String get voiceProfilesSection => 'Profil suara';

  @override
  String get voiceProfilesDescription =>
      'Suara yang disimpan dikenali secara automatik dalam mesyuarat akan datang.';

  @override
  String get voiceProfilesEmpty =>
      'Belum ada suara disimpan. Namakan penutur dalam transkrip mesyuarat, kemudian pilih \"Simpan profil suara\".';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sampel',
      one: '1 sampel',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'Namakan semula profil suara';

  @override
  String get deleteVoiceProfileTitle => 'Padam profil suara?';

  @override
  String deleteVoiceProfileBody(String name) {
    return 'Berhenti mengenali $name? Cap suara yang disimpan dibuang. Nama yang sudah digunakan dalam mesyuarat lalu dikekalkan.';
  }

  @override
  String get connectedLabel => 'Disambungkan';

  @override
  String get ideTabGeneral => 'Umum';

  @override
  String get ideTabExplorer => 'Penjelajah';

  @override
  String get ideTabSourceControl => 'Kawalan sumber';

  @override
  String get generalSectionTodos => 'Tugasan';

  @override
  String get generalSectionGoals => 'Matlamat';

  @override
  String get goalRunStatusActive => 'Aktif';

  @override
  String get goalRunStatusPaused => 'Dijeda';

  @override
  String get goalRunStatusCompleted => 'Selesai';

  @override
  String get goalRunStatusFailed => 'Gagal';

  @override
  String get goalRunStatusCancelled => 'Dibatalkan';

  @override
  String get goalRunStatusBudgetExhausted => 'Bajet habis';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'Larian $run daripada $max · $cost daripada $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'Larian $run · $cost daripada $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'Tamat $deadline';
  }

  @override
  String get goalRunPause => 'Jeda matlamat';

  @override
  String get goalRunResume => 'Sambung matlamat';

  @override
  String goalRunResumeRaise(String cap) {
    return 'Sambung · naikkan had kepada $cap';
  }

  @override
  String get goalRunStop => 'Henti matlamat';

  @override
  String get generalSectionAgents => 'Ejen';

  @override
  String get generalSectionTerminals => 'Terminal';

  @override
  String get generalTodosEmpty => 'Belum ada tugasan';

  @override
  String get generalAgentsEmpty => 'Tiada ejen berjalan';

  @override
  String get generalTerminalsEmpty => 'Tiada terminal terbuka';

  @override
  String get generalSectionBrowsers => 'Penyemak imbas';

  @override
  String get generalSectionComputers => 'Komputer';

  @override
  String get generalBrowsersEmpty => 'Tiada penyemak imbas terbuka';

  @override
  String get generalComputersEmpty => 'Tiada komputer terbuka';

  @override
  String get generalSectionPhones => 'Telefon';

  @override
  String get generalPhonesEmpty => 'Tiada telefon terbuka';

  @override
  String get pauseAgent => 'Jeda ejen';

  @override
  String get resumeAgent => 'Sambung ejen';

  @override
  String get agentCannotPause =>
      'Ejen ini tidak dapat dijeda — hentikannya sebaliknya.';

  @override
  String get goalClear => 'Kosongkan matlamat';

  @override
  String get undoLabelGoalClear => 'kosongkan matlamat';

  @override
  String get todoStatusPending => 'Belum dimulakan';

  @override
  String get todoStatusInProgress => 'Sedang berjalan';

  @override
  String get todoStatusCompleted => 'Selesai';

  @override
  String get reorderTodo => 'Susun semula tugasan';

  @override
  String get focusTerminal => 'Fokus terminal';

  @override
  String get focusMachine => 'Fokus mesin';

  @override
  String get focusBrowser => 'Fokus penyemak imbas';

  @override
  String get todoEditorTitle => 'Sunting tugasan';

  @override
  String get todoEditorHint =>
      'Satu item setiap baris. Gunakan - [ ] untuk tertunda, - [~] untuk sedang berjalan, - [x] untuk selesai.';

  @override
  String get todoNeedsText => 'Tambah teks selepas perintah';

  @override
  String get todoNotFound => 'Tiada tugasan yang sepadan';

  @override
  String get todoCleared => 'Senarai tugasan dikosongkan';

  @override
  String get todoNothingToCopy => 'Tiada apa untuk disalin';

  @override
  String todoAdded(String content) {
    return 'Ditambah \"$content\"';
  }

  @override
  String todoStarted(String content) {
    return 'Dimulakan \"$content\"';
  }

  @override
  String todoCompleted(String content) {
    return 'Diselesaikan \"$content\"';
  }

  @override
  String todoRemoved(String content) {
    return 'Dibuang \"$content\"';
  }

  @override
  String todoCopied(int count) {
    return '$count item disalin';
  }

  @override
  String todoImported(int count) {
    return '$count item diimport';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'Perintah tugasan tidak diketahui \"$name\"';
  }

  @override
  String get terminal => 'Terminal';

  @override
  String get ideCloseTab => 'Tutup tab';

  @override
  String get ideSplitEditor => 'Pisahkan editor';

  @override
  String get ideSplitRight => 'Pisah ke kanan';

  @override
  String get ideSplitDown => 'Pisah ke bawah';

  @override
  String get ideSplitLeft => 'Pisah ke kiri';

  @override
  String get ideSplitUp => 'Pisah ke atas';

  @override
  String get ideCloseGroup => 'Tutup kumpulan';

  @override
  String get ideCloseOthers => 'Tutup yang lain';

  @override
  String get ideCloseToRight => 'Tutup ke kanan';

  @override
  String get ideCloseSaved => 'Tutup yang disimpan';

  @override
  String get ideCloseAll => 'Tutup semua';

  @override
  String get ideSplit => 'Pisah';

  @override
  String get ideToggleSidebar => 'Togol bar sisi';

  @override
  String get ideNewTab => 'Buka editor';

  @override
  String get ideNewTabMenu => 'Tab baharu';

  @override
  String get ideReviewCode => 'Semak kod';

  @override
  String get ideRevertConfirmTitle => 'Kembalikan perubahan';

  @override
  String get ideRevertUntracked =>
      'Fail tidak dijejak tidak dapat dikembalikan';

  @override
  String get ideRevertFailed =>
      'Tidak dapat mengembalikan fail. Worktree perbualan mungkin tidak tersedia.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fail',
      one: '1 fail',
    );
    return '$_temp0 tidak dapat dikembalikan (tidak dijejak).';
  }

  @override
  String get ideSearchMatchCase => 'Padankan huruf';

  @override
  String get ideSearchWholeWord => 'Perkataan penuh';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'Penapis carian';

  @override
  String get ideSearchFilesToInclude => 'Fail untuk disertakan';

  @override
  String get ideSearchFilesToExclude => 'Fail untuk dikecualikan';

  @override
  String get ideNoOpenTabs => 'Tiada tab terbuka — gunakan + untuk membuka';

  @override
  String get ideBrowserAddressHint => 'Masukkan alamat atau cari';

  @override
  String get ideSimpleWebBrowser => 'Penyemak imbas web ringkas';

  @override
  String get ideWebBrowser => 'Penyemak imbas web';

  @override
  String get ideBrowserEnterUrl =>
      'Masukkan URL dalam bar alamat untuk mula menyemak imbas';

  @override
  String get ideCodeServer => 'Editor';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'Simpan perubahan pada $fileName?';
  }

  @override
  String get ideUnsavedChangesBody =>
      'Perubahan anda akan hilang jika anda tidak menyimpannya.';

  @override
  String get ideDontSave => 'Jangan simpan';

  @override
  String get editorAutoSave => 'Simpan automatik';

  @override
  String get editorAutoSaveDescription =>
      'Simpan perubahan secara automatik dalam editor terbenam.';

  @override
  String get editorAutoSaveOff => 'Mati';

  @override
  String get editorAutoSaveAfterDelay => 'Selepas kelewatan';

  @override
  String get editorAutoSaveOnFocusChange => 'Apabila fokus berubah';

  @override
  String get ideCodeServerUnavailable =>
      'Code-server tidak tersedia pada pelayan ini';

  @override
  String get ideCodeServerUnavailableHint =>
      'Pasang code-server (coder/code-server) pada hos pelayan, kemudian buka semula editor.';

  @override
  String get ideCodeServerInstalling => 'Menyediakan editor…';

  @override
  String get ideCodeServerOpenInBrowser => 'Buka editor dalam penyemak imbas';

  @override
  String get ideCodeServerError => 'Tidak dapat membuka editor';

  @override
  String get paneSuspendedCaption =>
      'Digantung untuk menjimatkan sumber — ia dimuat semula apabila difokuskan';

  @override
  String get ideFolderLoadFailed => 'Tidak dapat memuatkan folder ini';

  @override
  String get ideFileSearchFailed => 'Tidak dapat mencari fail';

  @override
  String get ideSearchInFiles => 'Cari dalam fail';

  @override
  String get ideNoContentMatches => 'Tiada padanan';

  @override
  String get ideSourceControlCreatePr => 'Cipta pull request';

  @override
  String ideSourceControlViewPr(int number) {
    return 'Lihat pull request #$number';
  }

  @override
  String get ideSourceControlNoChanges => 'Tiada perubahan';

  @override
  String get noReposInConversation => 'Tiada repositori dalam perbualan ini';

  @override
  String get ideSourceControlNoSpace =>
      'Buka perbualan untuk melihat perubahannya';

  @override
  String get ideFileLoading => 'Memuatkan…';

  @override
  String get ideFileBinary => 'Fail binari';

  @override
  String get mcpExternalServers => 'Pelayan MCP luaran';

  @override
  String get mcpExternalServersDescription =>
      'Sambung ke pelayan MCP luaran (GitHub, Sentry, Postgres, automasi penyemak imbas). Pelayan yang anda konfigurasikan untuk Claude, Cursor, VS Code dan alat lain dikesan secara automatik.';

  @override
  String get mcpApprovalMode => 'Kelulusan alat';

  @override
  String get mcpApprovalModeDescription =>
      'Tindakan alat mana yang berjalan tanpa bertanya. Bacaan sentiasa dibenarkan; peringkat lebih tinggi meminta.';

  @override
  String get mcpApprovalAlwaysAsk => 'Sentiasa tanya';

  @override
  String get mcpApprovalWrite => 'Luluskan tulis secara automatik';

  @override
  String get mcpApprovalYolo => 'Luluskan semua secara automatik';

  @override
  String get mcpNoExternalServers => 'Tiada pelayan MCP luaran dikesan.';

  @override
  String get mcpAuthorize => 'Berikan kebenaran';

  @override
  String get mcpReconnect => 'Sambung semula';

  @override
  String get mcpExternalConnectionsNote =>
      'Pelayan MCP luaran berjalan pada pelayan ejen (dikongsi oleh desktop dan web). Memberi kebenaran pelayan OAuth hanya tersedia pada desktop.';

  @override
  String get mcpStatusConnected => 'Disambungkan';

  @override
  String get mcpStatusConnecting => 'Menyambung…';

  @override
  String get mcpStatusNeedsAuth => 'Memerlukan kebenaran';

  @override
  String get mcpStatusFailed => 'Gagal';

  @override
  String get mcpStatusCircuitOpen => 'Dijeda';

  @override
  String get mcpStatusDisabled => 'Dilumpuhkan';

  @override
  String get providersAndModels => 'Penyedia & model';

  @override
  String get providersAndModelsDescription =>
      'Senaraikan setiap penyedia yang ejen terbina boleh gunakan — tetapkan kunci API atau log masuk dengan penyemak imbas anda, lihat model dan harga setiap penyedia yang disambungkan dan kawal penyedia mana yang ruang kerja ini boleh gunakan.';

  @override
  String get syncNow => 'Segerak sekarang';

  @override
  String syncNowResult(int applied, int failed) {
    return 'Segerak selesai — $applied diterapkan, $failed gagal';
  }

  @override
  String syncNowFailed(String error) {
    return 'Segerak gagal: $error';
  }

  @override
  String get denied => 'Ditolak';

  @override
  String get allowed => 'Dibenarkan';

  @override
  String allowProviderSemantic(String provider) {
    return 'Benarkan $provider';
  }

  @override
  String enabledViaEnv(String key) {
    return 'Didayakan melalui $key';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output setiap 1M';
  }

  @override
  String contextTokens(String tokens) {
    return '$tokens konteks';
  }

  @override
  String get usageAndCost => 'Penggunaan & kos';

  @override
  String get usageAndCostDescription =>
      'Perbelanjaan merentasi ejen anda sepanjang 7 hari lalu, dari kos larian yang diperhatikan.';

  @override
  String get noUsageYet => 'Belum ada penggunaan direkodkan.';

  @override
  String get spentThisWeek => 'dibelanjakan minggu ini';

  @override
  String get subscriptionUsage => 'Penggunaan langganan';

  @override
  String get subscriptionUsageUnavailable => 'Tidak tersedia';

  @override
  String get subscriptionUsageExhausted => 'Kuota habis';

  @override
  String get subscriptionUsageSignInRequired => 'Log masuk semula';

  @override
  String get subscriptionUsageSignInExpired =>
      'Log masuk luput, diperbaharui pada larian seterusnya';

  @override
  String get subscriptionUsagePartiallyAvailable => 'Tersedia sebahagian';

  @override
  String resetsIn(String duration) {
    return 'Ditetapkan semula dalam $duration';
  }

  @override
  String get feedbackHelpful => 'Ini membantu';

  @override
  String get feedbackNotHelpful => 'Ini tidak membantu';

  @override
  String get modeChat => 'Sembang';

  @override
  String get modePlan => 'Rancang';

  @override
  String get modeReview => 'Semak';

  @override
  String get modeOrchestrate => 'Orkestrakan';

  @override
  String get editorTheme => 'Tema editor';

  @override
  String get editorThemeDescription =>
      'Import tema warna VS Code supaya diff dan editor terbenam sepadan dengan IDE anda.';

  @override
  String get editorThemePasteHint =>
      'Tampal kandungan fail JSON tema warna VS Code';

  @override
  String get editorThemeImported => 'Tema diimport';

  @override
  String get editorThemeInvalid =>
      'Itu tidak kelihatan seperti tema VS Code yang sah';

  @override
  String get importTheme => 'Import tema';

  @override
  String get clearTheme => 'Kosongkan tema';

  @override
  String get openInDiffViewer => 'Buka dalam pemapar diff';

  @override
  String get shellCommand => 'Perintah';

  @override
  String get shellOutput => 'Output';

  @override
  String get revertToHere => 'Kembalikan ke sini';

  @override
  String get revertConfirmBody =>
      'Sembunyikan mesej selepas titik ini dan undurkan perubahan fail ejen ke giliran ini? Anda boleh buat asal ini.';

  @override
  String get revert => 'Kembalikan';

  @override
  String get revertedToHere => 'Dikembalikan ke sini';

  @override
  String get nothingToRevert => 'Tiada apa untuk dikembalikan';

  @override
  String get undoRevert => 'Buat asal pengembalian';

  @override
  String get revertUndone => 'Pengembalian dibuat asal';

  @override
  String get systemBehavior => 'Tingkah laku sistem';

  @override
  String get keepAwakeTitle => 'Kekalkan komputer terjaga semasa ejen berjalan';

  @override
  String get keepAwakeOnSubtitle =>
      'Komputer tidak akan tidur semasa ejen sedang bekerja';

  @override
  String get keepAwakeOffSubtitle =>
      'Komputer mungkin tidur walaupun ejen sedang bekerja';

  @override
  String get syncEngineSectionTitle => 'Enjin segerak';

  @override
  String get syncEngineDescription =>
      'Tiket, pemesejan dan nota dikemas kini secara langsung melalui perubahan tambahan kecil dan bukan snapshot penuh. Mematikan togol menjatuhkan stor itu kembali ke modus snapshot penuh — muat semula apl supaya perubahan berkuat kuasa.';

  @override
  String get syncEngineTicketsTitle => 'Tiket';

  @override
  String get syncEngineMessagingTitle => 'Pemesejan';

  @override
  String get syncEngineNotesTitle => 'Nota';

  @override
  String get syncEngineOnSubtitle => 'Segerak delta langsung aktif';

  @override
  String get syncEngineOffSubtitle => 'Menggunakan segerak snapshot penuh';

  @override
  String get spaces => 'Ruang';

  @override
  String get spacesHomeDescription =>
      'Pilih ruang dari senarai, atau mulakan yang baharu.';

  @override
  String get noSpacesYet => 'Belum ada ruang';

  @override
  String get newSpace => 'Ruang baharu';

  @override
  String get spaceName => 'Nama ruang';

  @override
  String get spaceReposHint => 'Repo untuk disertakan';

  @override
  String get ideSourceControl => 'Kawalan sumber';

  @override
  String get stagedChanges => 'Perubahan disediakan';

  @override
  String get changes => 'Perubahan';

  @override
  String get stageFile => 'Sediakan';

  @override
  String get unstageFile => 'Nyahsediakan';

  @override
  String get stageAll => 'Sediakan semua perubahan';

  @override
  String get unstageAll => 'Nyahsediakan semua';

  @override
  String get stageChangesToCommit => 'Sediakan perubahan untuk commit';

  @override
  String get syncToPrHead => 'Pull commit PR terkini';

  @override
  String get syncedToPrHead => 'Disegerakkan ke commit PR terkini';

  @override
  String get syncPrHeadDirty =>
      'Commit atau buang perubahan anda sebelum menyegerakkan';

  @override
  String get syncPrHeadFailed => 'Tidak dapat menyegerakkan ke kepala PR';

  @override
  String get spaceLabel => 'Ruang';

  @override
  String get keybindingNewSpace => 'Ruang baharu';

  @override
  String get keybindingCreateANewSpaceDescription => 'Cipta ruang baharu';

  @override
  String get jumpToLatest => 'Lompat ke terkini';

  @override
  String get streaming => 'Menstrim';

  @override
  String get newMessages => 'Baharu';

  @override
  String get copyLink => 'Salin pautan';

  @override
  String get linkCopied => 'Pautan disalin';

  @override
  String get agentResponding => 'Ejen membalas';

  @override
  String get agentFinished => 'Ejen selesai';

  @override
  String get harnessConnectProviderForModels =>
      'Sambungkan penyedia untuk melihat model.';

  @override
  String get providerSignOut => 'Log keluar';

  @override
  String get providerWaitingForDeviceCode =>
      'Menunggu anda mengesahkan kod dalam penyemak imbas…';

  @override
  String get providerDeviceCodeHint =>
      'Pastikan kod ini sepadan dengan yang ditunjukkan dalam penyemak imbas, kemudian luluskan.';

  @override
  String get providerPlanUsageLoading => 'Menyemak penggunaan pelan…';

  @override
  String get providerPlanUsageUnavailable =>
      'Pelan ini tidak melaporkan penggunaan.';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return 'Buang kunci API $provider?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'Kunci yang disimpan dipadam dan tidak dapat ditunjukkan lagi. Ejen yang menggunakan model $provider berhenti bekerja sehingga anda menampal yang baharu.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return 'Buang $provider?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'Penyedia $provider dan kunci yang disimpan dipadam. Ejen yang dipinkan kepada modelnya berhenti bekerja.';
  }

  @override
  String get providerApiKeyHint => 'Tampal kunci API';

  @override
  String get providerApiKeyStoredHint =>
      'Tampal kunci API lain untuk menambahnya';

  @override
  String get providerAddAnotherAccount => 'Tambah akaun lain';

  @override
  String get providerActiveBadge => 'Aktif';

  @override
  String get providerOauthAccountFallback => 'Akaun OAuth';

  @override
  String get providerApiKeyFallback => 'Kunci API';

  @override
  String get providerRemoveCredentialConfirmTitle => 'Buang kelayakan ini?';

  @override
  String get providerSignOutAccountConfirmTitle =>
      'Log keluar daripada akaun ini?';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'Ejen yang menggunakan $provider jatuh kepada kunci dan akaun lain. Jika tiada yang tinggal, mereka berhenti sehingga anda menambah satu.';
  }

  @override
  String get providerBaseUrlHint => 'URL asas (pilihan)';

  @override
  String get addProvider => 'Tambah penyedia';

  @override
  String get noCustomProviders => 'Belum ada penyedia tersuai.';

  @override
  String get providerNameLabel => 'Nama';

  @override
  String get apiTypeLabel => 'Jenis API';

  @override
  String get providerBaseUrlLabel => 'URL asas';

  @override
  String get providerApiKeyOptionalHint => 'Kunci API (pilihan)';

  @override
  String get dialectOpenAiCompatible => 'Serasi OpenAI';

  @override
  String get dialectAnthropicCompatible => 'Serasi Anthropic';

  @override
  String get removeProviderTooltip => 'Buang penyedia';

  @override
  String get providerLogInWithBrowser => 'Log masuk dengan penyemak imbas';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'Log masuk ke $provider';
  }

  @override
  String get providerLabel => 'Penyedia';

  @override
  String get selectProviderToLogin => 'Pilih penyedia untuk log masuk';

  @override
  String providerLoginFailed(String error) {
    return 'Log masuk gagal: $error';
  }

  @override
  String get providerWaitingForBrowser =>
      'Menunggu anda memberikan kebenaran dalam penyemak imbas…';

  @override
  String get providerPasteCodeHint =>
      'Atau tampal kod dari penyemak imbas anda';

  @override
  String get providerCompleteLogin => 'Selesai';

  @override
  String get providerConnectedApiKey => 'Disambungkan melalui kunci API';

  @override
  String get providerConnectedOauth => 'Disambungkan';

  @override
  String providerConnectedAccount(String account) {
    return 'Disambungkan · $account';
  }

  @override
  String get providerLocalReady => 'Setempat · sedia';

  @override
  String get providerNotConnected => 'Tidak disambungkan';

  @override
  String get preparingWorkspace => 'Menyediakan ruang kerja…';

  @override
  String provisioningRunningSetupScript(String repo) {
    return 'Menjalankan skrip persediaan untuk $repo…';
  }

  @override
  String get repoScriptsTitle => 'Skrip';

  @override
  String get repoScriptsTooltip => 'Konfigurasikan skrip kitaran hayat';

  @override
  String get repoScriptsSetupLabel => 'Skrip persediaan';

  @override
  String get repoScriptsSetupHelp =>
      'Berjalan dalam worktree ruang sejurus selepas ia dicipta — pasang kebergantungan, jana fail. Kegagalan menandakan ruang sebagai gagal; cuba semula menjalankannya lagi.';

  @override
  String get repoScriptsArchiveLabel => 'Skrip arkib';

  @override
  String get repoScriptsArchiveHelp =>
      'Berjalan sebelum worktree ruang dipadam — bersihkan sumber di luar worktree. Kegagalan tidak pernah menyekat pemadaman.';

  @override
  String get repoScriptsEnvHelp =>
      'Berjalan melalui bash dari worktree, dengan CC_WORKSPACE_PATH (worktree), CC_ROOT_PATH (akar repo), CC_SPACE_ID, CC_SPACE_NAME dan CC_REPO_NAME ditetapkan.';

  @override
  String get repoScriptsSetupPlaceholder => 'e.g. pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      'e.g. docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => 'Larian terkini';

  @override
  String get repoScriptsNoRuns => 'Belum ada larian';

  @override
  String get repoScriptsSaved => 'Skrip disimpan';

  @override
  String get repoScriptsRunKindSetup => 'Persediaan';

  @override
  String get repoScriptsRunKindArchive => 'Arkib';

  @override
  String get repoScriptsRunStatusRunning => 'Berjalan';

  @override
  String get repoScriptsRunStatusSucceeded => 'Berjaya';

  @override
  String get repoScriptsRunStatusFailed => 'Gagal';

  @override
  String get repoScriptsRunStatusTimedOut => 'Tamat masa';

  @override
  String repoScriptsExitCode(int code) {
    return 'Kod keluar $code';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return 'Mengklon $repo…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'Menyemak keluar pull request dalam $repo…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'Menyediakan ejen $agent…';
  }

  @override
  String get workspacePrepFailed => 'Persediaan ruang kerja gagal';

  @override
  String get workspacePrepStopped => 'Persediaan ruang kerja dihentikan';

  @override
  String get stopWorkspacePrep => 'Henti menyediakan';

  @override
  String get stopWorkspacePrepTooltip => 'Henti menyediakan ruang kerja ini';

  @override
  String get stopWorkspacePrepConfirm =>
      'Henti menyediakan ruang kerja ini? Klon yang sedang berjalan dibuang — anda boleh memulakannya lagi dari sini.';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count mesej akan dihantar apabila sedia';
  }

  @override
  String get membersNav => 'Ahli';

  @override
  String get membersSettingsDescription =>
      'Orang dengan akses ke ruang kerja ini: senarai, jemputan dan jejak audit';

  @override
  String get memberRosterLabel => 'Senarai ahli';

  @override
  String get memberRepoAccessAction => 'Akses repo';

  @override
  String memberRepoAccessTitle(String name) {
    return 'Akses repo untuk $name';
  }

  @override
  String get roleOwner => 'Pemilik';

  @override
  String get roleAdmin => 'Pentadbir';

  @override
  String get roleMember => 'Ahli';

  @override
  String get roleViewer => 'Pemapar';

  @override
  String get roleGuest => 'Tetamu';

  @override
  String get removeMemberTitle => 'Buang ahli';

  @override
  String removeMemberConfirm(String name) {
    return 'Buang $name dari ruang kerja ini? Mereka segera kehilangan akses.';
  }

  @override
  String get transferOwnershipAction => 'Pindahkan pemilikan';

  @override
  String get transferOwnershipTitle => 'Pindahkan pemilikan';

  @override
  String transferOwnershipConfirm(String name) {
    return 'Jadikan $name pemilik ruang kerja ini? Anda menjadi pentadbir. Hanya pemilik boleh memadam ruang kerja atau mengubah peranan pentadbir lain.';
  }

  @override
  String get transferOwnershipCta => 'Pindahkan';

  @override
  String get auditTrailLabel => 'Jejak audit kebenaran';

  @override
  String get auditTrailDescription =>
      'Setiap kebenaran dan penolakan, dirantai hash supaya entri yang diubah atau dipadam dapat dikesan.';

  @override
  String get auditVerifyChain => 'Sahkan rantai';

  @override
  String auditChainIntact(int count) {
    return 'Rantai utuh — $count entri disahkan';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'Rantai pecah pada entri $seq: $reason';
  }

  @override
  String get auditEmpty => 'Belum ada keputusan direkodkan.';

  @override
  String get auditDenied => 'Ditolak';

  @override
  String get auditAllowed => 'Dibenarkan';

  @override
  String auditOnBehalfOf(String user) {
    return 'untuk $user';
  }

  @override
  String get policyTemplatesLabel => 'Templat polisi';

  @override
  String get policyTemplatesDescription =>
      'Terapkan postur permulaan, atau pindahkan satu antara ruang kerja.';

  @override
  String get policyTemplateStrict => 'Ketat';

  @override
  String get policyTemplateBalanced => 'Seimbang';

  @override
  String get policyTemplatePermissive => 'Longgar';

  @override
  String get policyTemplateApply => 'Terapkan';

  @override
  String policyTemplateApplied(int count) {
    return '$count peraturan diterapkan';
  }

  @override
  String get policyExport => 'Salin polisi';

  @override
  String get policyExported => 'Polisi disalin ke papan keratan';

  @override
  String get policyImport => 'Tampal polisi';

  @override
  String policyImported(int count) {
    return '$count peraturan diimport';
  }

  @override
  String get approveAndRemember => 'Luluskan selama 8 jam';

  @override
  String get approveAndRememberTooltip =>
      'Meluluskan tindakan ini dan berhenti bertanya untuk yang serupa dalam ruang ini selama 8 jam. Ia luput sendiri.';

  @override
  String get unknownUserLabel => 'Pengguna tidak diketahui';

  @override
  String get inviteMember => 'Jemput ahli';

  @override
  String get inviteRepoAccessHeader => 'Akses repositori';

  @override
  String get inviteRepoAccessExplainer =>
      'Hanya repositori yang anda semak dikongsi dengan yang dijemput, pada tahap yang anda pilih. Segala yang lain kekal tersembunyi.';

  @override
  String get grantLevelRead => 'Baca';

  @override
  String get grantLevelReview => 'Semak';

  @override
  String get grantLevelWrite => 'Tulis';

  @override
  String get inviteExpiryLabel => 'Luput dalam';

  @override
  String get expiryOneDay => '1 hari';

  @override
  String get expirySevenDays => '7 hari';

  @override
  String get expiryThirtyDays => '30 hari';

  @override
  String get createInviteAction => 'Cipta jemputan';

  @override
  String get inviteOneTimeCodeLabel => 'Kod sekali guna';

  @override
  String get inviteCodeShownOnce =>
      'Kod ini ditunjukkan sekali sahaja — salinnya sekarang.';

  @override
  String get inviteLinkLabel => 'Pautan jemputan';

  @override
  String get inviteRedeemHint =>
      'Kongsi kod dengan yang dijemput; mereka menebusnya terhadap URL pelayan anda.';

  @override
  String get inviteScanQr => 'Atau imbas untuk menebus';

  @override
  String get inviteLoopbackWarningTitle =>
      'Jemputan menunjuk ke alamat setempat';

  @override
  String get inviteLoopbackWarningBody =>
      'Rakan kolaborasi pada mesin lain tidak akan dapat mencapai pelayan ini. Mulakan terowong (Tetapan → Integrasi → Kongsi pelayan ini) atau ikat ke rangkaian anda supaya pengguna luar hos dapat menyambung.';

  @override
  String get inviteStatusOpen => 'Terbuka';

  @override
  String get inviteStatusUsed => 'Digunakan';

  @override
  String get inviteStatusRevoked => 'Ditarik balik';

  @override
  String get inviteStatusExpired => 'Luput';

  @override
  String inviteCreatedTime(String time) {
    return 'Dicipta $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'luput $date';
  }

  @override
  String get noActivityYet => 'Belum ada aktiviti';

  @override
  String get couldNotLoadMembers => 'Tidak dapat memuatkan ahli';

  @override
  String get couldNotLoadInvites => 'Tidak dapat memuatkan jemputan';

  @override
  String get couldNotLoadActivity => 'Tidak dapat memuatkan aktiviti';

  @override
  String get yourDevices => 'Peranti anda';

  @override
  String get yourDevicesDescription =>
      'Klien yang dipasangkan ke akaun anda pada pelayan ini.';

  @override
  String get noOwnDevices => 'Belum ada peranti dipasangkan ke akaun anda';

  @override
  String get renameDeviceTitle => 'Namakan semula peranti';

  @override
  String get revokeDeviceTitle => 'Tarik balik peranti';

  @override
  String revokeDeviceConfirm(String label) {
    return 'Tarik balik $label? Ia diputuskan dengan segera dan tidak lagi dapat mencapai pelayan ini.';
  }

  @override
  String devicePairedTime(String time) {
    return 'Dipasangkan $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'Terakhir dilihat $time';
  }

  @override
  String get deviceNeverSeen => 'Tidak pernah disambungkan';

  @override
  String get profileSectionLabel => 'Profil';

  @override
  String get profileSectionDescription =>
      'Bagaimana anda kelihatan kepada rakan sepasukan dan dalam kepengarangan commit git.';

  @override
  String get displayNameLabel => 'Nama paparan';

  @override
  String get emailLabel => 'E-mel';

  @override
  String get gitAuthorNameLabel => 'Nama pengarang Git';

  @override
  String get gitAuthorEmailLabel => 'E-mel pengarang Git';

  @override
  String get profileSaved => 'Profil disimpan';

  @override
  String get presenceOnline => 'Dalam talian';

  @override
  String get presenceIdle => 'Terlengah';

  @override
  String get presenceTyping => 'Menaip…';

  @override
  String get presenceAgentThinking => 'Berfikir';

  @override
  String get presenceAgentRunning => 'Berjalan';

  @override
  String get presenceAgentBlocked => 'Disekat';

  @override
  String get presenceAgentDone => 'Selesai';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
  }

  @override
  String get presenceRailLabel => 'Siapa dalam talian';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'Hidupkan jangan ganggu';

  @override
  String get dndTooltipOff => 'Matikan jangan ganggu';

  @override
  String get startPresenting => 'Mula membentang';

  @override
  String get stopPresenting => 'Henti membentang';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name sedang membentang';
  }

  @override
  String get spotlightLeave => 'Tinggalkan';

  @override
  String typingIndicator(String name) {
    return '$name sedang menaip…';
  }

  @override
  String get ideTabNotes => 'Nota';

  @override
  String get ideSidebarAllViews => 'Semua paparan';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'Semua paparan ($count tersembunyi)';
  }

  @override
  String get ideSidebarPinView => 'Pin ke bar sisi';

  @override
  String get ideSidebarUnpinView => 'Nyahpin dari bar sisi';

  @override
  String get notesEmptyHint =>
      'Tambah nota untuk sesiapa yang mengambil perbualan ini…';

  @override
  String get notesEditTooltip => 'Sunting nota';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'Dikemas kini oleh $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name sedang menyunting';
  }

  @override
  String get notesSaveFailed => 'Tidak dapat menyimpan nota';

  @override
  String get reactionAddTooltip => 'Tambah tindak balas';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'Tindak balas dengan $emoji';
  }

  @override
  String get autonomyDialLabel => 'Autonomi';

  @override
  String get autonomyProposeOnly => 'Cadang sahaja';

  @override
  String get autonomyActWithApproval => 'Bertindak dengan kelulusan';

  @override
  String get autonomyActFreely => 'Bertindak bebas';

  @override
  String get autonomyDefaultOption => 'Lalai';

  @override
  String get checkerLabel => 'Penyemak';

  @override
  String get checkerNone => 'Tiada';

  @override
  String get checkerCaption =>
      'Penyemak menyemak larian ejen lain yang selesai.';

  @override
  String get takeoverTooltip => 'Ambil alih worktree';

  @override
  String get takeoverBannerSelf =>
      'Anda telah mengambil alih worktree perbualan ini';

  @override
  String takeoverBannerOther(String name) {
    return '$name telah mengambil alih worktree perbualan ini';
  }

  @override
  String get handBackButton => 'Serahkan semula';

  @override
  String get handBackDialogTitle => 'Serahkan semula worktree';

  @override
  String get handBackDialogNoteHint => 'Nota pilihan untuk ejen…';

  @override
  String takeoverFailed(String message) {
    return 'Tidak dapat mengambil alih: $message';
  }

  @override
  String handBackFailed(String message) {
    return 'Tidak dapat menyerahkan semula: $message';
  }

  @override
  String get planStudioTitle => 'Plan Studio';

  @override
  String get plansTitle => 'Rancangan';

  @override
  String get plansSubtitle =>
      'Rancangan aktif, dokumen rancangan dan buku panduan';

  @override
  String get plansActiveSection => 'Rancangan aktif';

  @override
  String get plansDocumentsSection => 'Dokumen rancangan';

  @override
  String get plansPlaybooksSection => 'Buku panduan';

  @override
  String get plansNoActive => 'Belum ada rancangan aktif.';

  @override
  String get plansNoDocuments => 'Belum ada dokumen rancangan.';

  @override
  String get plansNoPlaybooks => 'Belum ada buku panduan.';

  @override
  String get planNotFound => 'Rancangan tidak dijumpai.';

  @override
  String get planOpenInStudio => 'Buka';

  @override
  String get planNodeTitle => 'Tajuk';

  @override
  String get planNodeDescription => 'Perihalan';

  @override
  String get planNodeDescriptionHint => 'Apa yang langkah ini patut lakukan…';

  @override
  String get planNodeApplyDescription => 'Terapkan';

  @override
  String get planNodeRole => 'Peranan';

  @override
  String get planNodeDependencies => 'Bergantung pada';

  @override
  String get planNodeDependenciesHint => 'Tambah kebergantungan';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kebergantungan',
      one: '1 kebergantungan',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'Tiada kebergantungan, jadi ini berjalan sebaik rancangan bermula';

  @override
  String get planNodeOutputSchema => 'Skema output (JSON)';

  @override
  String get planNodeEstimate => 'Anggaran';

  @override
  String get planNodeProvenance => 'Asal usul';

  @override
  String get planNodeAlreadyExecuted =>
      'Sudah dilaksanakan — menyunting mencabangkan rancangan dari sini.';

  @override
  String get planNewNodeTitle => 'Langkah baharu';

  @override
  String get planEstimateNoHistory => 'Belum ada sejarah';

  @override
  String get planEstimateBlastUnknown => 'Jejari letupan: tidak diketahui';

  @override
  String get planEstimatePartial => 'sebahagian';

  @override
  String get planEstimateAction => 'Anggar';

  @override
  String planEstimateDuration(String range) {
    return 'Tempoh $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'Jejari letupan: $files fail, $symbols simbol';
  }

  @override
  String get planApprove => 'Luluskan rancangan';

  @override
  String get planApproveSelectedNodes => 'Luluskan yang dipilih';

  @override
  String get planReject => 'Tolak';

  @override
  String get planCancel => 'Batal larian';

  @override
  String get planContinueNode => 'Teruskan nod';

  @override
  String get planTotalNotEstimated => 'Belum dianggarkan';

  @override
  String get planBudgetExceeded => 'melebihi bajet';

  @override
  String planBudgetCeiling(String amount) {
    return 'bajet ≤ \$$amount';
  }

  @override
  String get planVersionsTitle => 'Versi';

  @override
  String get planNoRevisions => 'Belum ada semakan.';

  @override
  String get planDiffIdentical => 'Tiada perubahan.';

  @override
  String get planDiffGoalChanged => 'Matlamat berubah';

  @override
  String get planDiffBudgetChanged => 'Bajet berubah';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'Perubahan dari v$fromRev ke v$toRev';
  }

  @override
  String planDiffAdded(String node) {
    return 'Ditambah $node';
  }

  @override
  String planDiffRemoved(String node) {
    return 'Dibuang $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return 'Diubah $node: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'Tepi ditambah: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'Tepi dibuang: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'Peranan ditambah: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'Peranan dibuang: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'Peranan ditugaskan semula: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'Rancangan dirancang semula: anda meluluskan v$approved, kini ia v$current. Semak diff sebelum ia diteruskan.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'Kos sebenar: \$$amount';
  }

  @override
  String get planPlaybookRun => 'Jalankan';

  @override
  String get planPlaybookDelete => 'Padam buku panduan';

  @override
  String get planPlaybookProposed =>
      'Rancangan dicadangkan — luluskannya dalam Plan Studio.';

  @override
  String get planPlaybookAnchorTicket => 'Tiket sauh';

  @override
  String get planPlaybookPickTicket => 'Pilih tiket…';

  @override
  String get planPlaybookProposeRun => 'Cadangkan rancangan';

  @override
  String get planPlaybookRepoHint => 'ID repositori';

  @override
  String get planPlaybookAgentHint => 'ID ejen';

  @override
  String planPlaybookRunTitle(String name) {
    return 'Jalankan $name';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count param';
  }

  @override
  String get recentLabel => 'Terkini';

  @override
  String get cheatSheetTitle => 'Pintasan papan kekunci';

  @override
  String get cheatSheetGlobal => 'Global';

  @override
  String get cheatSheetThisScreen => 'Skrin ini';

  @override
  String get cheatSheetReservedInBrowser => 'Ditempah penyemak imbas';

  @override
  String get keybindingCheatSheet => 'Pintasan papan kekunci';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      'Tunjukkan helaian pintasan papan kekunci untuk skrin semasa';

  @override
  String get runPlaybookLabel => 'Jalankan buku panduan';

  @override
  String get playbooksLabel => 'Buku panduan';

  @override
  String get keybindingUndo => 'Buat asal';

  @override
  String get keybindingRedo => 'Buat semula';

  @override
  String get keybindingUndoLastActionDescription =>
      'Buat asal tindakan boleh balik terakhir anda';

  @override
  String get keybindingRedoLastActionDescription =>
      'Buat semula tindakan yang dibuat asal terakhir';

  @override
  String get undone => 'Dibuat asal';

  @override
  String get redone => 'Dibuat semula';

  @override
  String get undoFailed => 'Tidak dapat membuat asal';

  @override
  String get undoLabelTicketEdit => 'suntingan tiket';

  @override
  String get undoLabelMessageEdit => 'suntingan mesej';

  @override
  String get undoLabelTodoStatus => 'status tugasan';

  @override
  String get inboxTitle => 'Peti masuk';

  @override
  String get inboxReview => 'Semak';

  @override
  String get inboxOpen => 'Buka';

  @override
  String get inboxAllCaughtUp => 'Anda sudah mengejar semuanya';

  @override
  String get inboxGitHubDownTitle => 'GitHub mungkin tergendala';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub melaporkan $status, jadi pull request mungkin hilang dari senarai ini dan bukan benar-benar selesai.';
  }

  @override
  String get inboxGitHubIdentityTitle =>
      'Tidak dapat mengesahkan akaun GitHub anda';

  @override
  String get inboxGitHubIdentityBody =>
      'Peti masuk disusun mengikut siapa anda di GitHub. Sehingga itu dimuatkan ia kekal kosong, walaupun pull request menunggu anda.';

  @override
  String get inboxSeverityBlocking => 'Disekat';

  @override
  String get inboxSeverityWaiting => 'Menunggu';

  @override
  String get inboxSeverityInfo => 'Maklumat';

  @override
  String get inboxSyncFailed => 'Segerak gagal';

  @override
  String get inboxNeedsYourAttention => 'Memerlukan perhatian anda';

  @override
  String get inboxSectionNeedsYourReview => 'Memerlukan semakan anda';

  @override
  String get inboxSectionReturnedToYou => 'Dipulangkan kepada anda';

  @override
  String get inboxSectionApproved => 'Diluluskan';

  @override
  String get inboxSectionDrafts => 'Draf';

  @override
  String get inboxSectionWaitingForReviewers => 'Menunggu penyemak';

  @override
  String get inboxSectionMergingAndMerged => 'Mencantum dan baru dicantum';

  @override
  String get inboxSectionWaitingForAuthor => 'Menunggu pengarang';

  @override
  String get inboxColumnTitle => 'Tajuk';

  @override
  String get inboxColumnChanges => 'Perubahan';

  @override
  String get inboxColumnUpdated => 'Dikemas kini';

  @override
  String get inboxReviewApproved => 'Diluluskan';

  @override
  String get inboxReviewChangesRequested => 'Perubahan diminta';

  @override
  String get inboxHeroSubtitle =>
      'Setiap pull request yang melibatkan anda, disusun mengikut apa yang berlaku seterusnya.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request memerlukan semakan anda',
      one: '1 pull request memerlukan semakan anda',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dipulangkan kepada anda',
      one: '1 dipulangkan kepada anda',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted =>
      'Perubahan itu tidak disimpan dan dikembalikan';

  @override
  String get offlinePendingLabel => 'tertunda';

  @override
  String get offlineSyncingLabel => 'menyegerakkan';

  @override
  String get copyLinkLabel => 'Salin pautan ke halaman ini';

  @override
  String get agentsSectionLabel => 'Ejen';

  @override
  String get fleetWorkersTitle => 'Pekerja';

  @override
  String get fleetWorkersSubtitle => 'Mesin tersedia untuk menjalankan tugas';

  @override
  String get fleetJobsTitle => 'Tugas';

  @override
  String get fleetJobsSubtitle => 'Kerja diedarkan merentasi armada';

  @override
  String get fleetNoWorkers =>
      'Belum ada pekerja — mesin kedua yang menjalankan `cc_worker --server <url>` menyertai armada.';

  @override
  String get fleetNoJobs => 'Tiada tugas.';

  @override
  String get fleetError => 'Tidak dapat memuatkan armada';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count teras',
      one: '1 teras',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'Denyutan $time';
  }

  @override
  String get fleetNoHeartbeat => 'Belum ada denyutan';

  @override
  String fleetLastErrorLabel(String error) {
    return 'Ralat terakhir: $error';
  }

  @override
  String get fleetDrain => 'Salirkan';

  @override
  String get fleetResume => 'Sambung';

  @override
  String get fleetRevoke => 'Tarik balik';

  @override
  String get fleetRemove => 'Buang';

  @override
  String get fleetRevokeTitle => 'Tarik balik pekerja?';

  @override
  String fleetRevokeBody(String name) {
    return 'Tarik balik $name? Sesinya tamat dan sebarang tugas aktif ditugaskan semula.';
  }

  @override
  String get fleetRemoveTitle => 'Buang pekerja?';

  @override
  String fleetRemoveBody(String name) {
    return 'Buang $name dari armada? Ini memadam rekodnya.';
  }

  @override
  String get fleetActionFailed => 'Tindakan gagal';

  @override
  String get fleetJobUnassigned => 'Tidak ditugaskan';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max percubaan';
  }

  @override
  String get fleetPlacementReasons => 'Keputusan penempatan';

  @override
  String get fleetNoPlacements => 'Belum ada keputusan penempatan.';

  @override
  String get fleetStatusOnline => 'Dalam talian';

  @override
  String get fleetStatusDraining => 'Menyalir';

  @override
  String get fleetStatusOffline => 'Luar talian';

  @override
  String get fleetStatusIncompatible => 'Tidak serasi';

  @override
  String get fleetStatusRevoked => 'Ditarik balik';

  @override
  String get fleetJobStatusQueued => 'Dalam barisan';

  @override
  String get fleetJobStatusRunning => 'Berjalan';

  @override
  String get fleetJobStatusSucceeded => 'Berjaya';

  @override
  String get fleetJobStatusFailed => 'Gagal';

  @override
  String get fleetJobStatusCancelled => 'Dibatalkan';

  @override
  String get evalsNoSuites => 'Belum ada suite eval.';

  @override
  String get evalsError => 'Tidak dapat memuatkan eval';

  @override
  String get evalsStarterBadge => 'Permulaan';

  @override
  String evalsDefaultBatch(int count) {
    return 'Kumpulan lalai sebanyak $count';
  }

  @override
  String get evalsRecentRuns => 'Larian terkini';

  @override
  String get evalsNoRuns => 'Belum ada larian.';

  @override
  String get evalsPassRate => 'Kadar lulus';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return 'oleh $who';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'Eval selesai — $rate lulus';
  }

  @override
  String get evalsRunFailed => 'Tidak dapat menjalankan suite';

  @override
  String get evalsRun => 'Jalankan';

  @override
  String get evalsStatusQueued => 'Dalam barisan';

  @override
  String get evalsStatusRunning => 'Berjalan';

  @override
  String get evalsStatusPassed => 'Lulus';

  @override
  String get evalsStatusFailed => 'Gagal';

  @override
  String get bannerMeetingJoin => 'Sertai';

  @override
  String get bannerMeetingRecordAndLink => 'Rakam & pautkan';

  @override
  String get bannerCalendarReconnect => 'Sambung semula';

  @override
  String get bannerView => 'Lihat';

  @override
  String get soundscapeTitle => 'Landskap bunyi';

  @override
  String get soundscapePlay => 'Main';

  @override
  String get soundscapePause => 'Jeda';

  @override
  String get soundscapeMoodLabel => 'Mood';

  @override
  String get soundscapeMoodFocus => 'Fokus';

  @override
  String get soundscapeMoodRelax => 'Rehat';

  @override
  String get soundscapeMoodSleep => 'Tidur';

  @override
  String get soundscapeVolumeLabel => 'Volum';

  @override
  String get soundscapeTuneLabel => 'Laraskan';

  @override
  String get soundscapeTuneMellow => 'Lembut';

  @override
  String get soundscapeTuneBright => 'Cerah';

  @override
  String get soundscapeTuneEnergetic => 'Bertenaga';

  @override
  String get soundscapeTuneSpacy => 'Luas';

  @override
  String get soundscapeTuneResetHint => 'Ketik dua kali untuk tetapkan semula';

  @override
  String get soundscapeSceneLabel => 'Sedang dimainkan';

  @override
  String get soundscapeSceneLoading => 'Melaraskan suasana…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees°C';
  }

  @override
  String get soundscapeLocationLabel => 'Lokasi';

  @override
  String get soundscapeLocationDetecting => 'Mengesan lokasi…';

  @override
  String get soundscapeLocationAutoNote =>
      'Lokasi dikesan secara automatik dari ruang kerja ini.';

  @override
  String get soundscapeRefreshWeather => 'Muat semula cuaca';

  @override
  String get soundscapeAutoStartLabel => 'Mula dengan modus fokus';

  @override
  String get soundscapeAutoStartDescription =>
      'Mainkan landskap bunyi secara automatik apabila anda memulakan sesi fokus.';

  @override
  String get soundscapeReturnToApp => 'Kembali ke apl';

  @override
  String get soundscapePopOut => 'Keluarkan pemain';

  @override
  String get discussion => 'Perbincangan';

  @override
  String get chat => 'Sembang';

  @override
  String get saving => 'Menyimpan…';

  @override
  String get saved => 'Disimpan';

  @override
  String get saveFailed => 'Tidak dapat menyimpan';

  @override
  String get commitAndPush => 'Commit & push';

  @override
  String get commit => 'Commit';

  @override
  String get commitAmend => 'Commit (pinda)';

  @override
  String get commitAndSync => 'Commit & segerak';

  @override
  String get committed => 'Di-commit';

  @override
  String get commitAmended => 'Commit dipinda';

  @override
  String get commitFailed => 'Commit gagal';

  @override
  String get moreCommitActions => 'Tindakan commit lanjut';

  @override
  String get sourceControl => 'Kawalan sumber';

  @override
  String fixFindingTitle(String location) {
    return 'Betulkan: $location';
  }

  @override
  String get openInEditor => 'Buka dalam editor';

  @override
  String get regexTesterTitle => 'Uji ungkapan nalar';

  @override
  String get regexTesterHint => 'Taip contoh';

  @override
  String get regexMatch => 'Padanan';

  @override
  String get regexNoMatch => 'Tiada padanan';

  @override
  String get regexInvalidPattern => 'Corak tidak sah';

  @override
  String get symbolLookupNone =>
      'Tiada definisi dalam indeks atau permintaan tarik ini';

  @override
  String get symbolLookupInDiff => 'Dijumpai dalam permintaan tarik ini';

  @override
  String get symbolLookupFromBase =>
      'Dari checkout asas — worktree PR ini belum diindeks lagi';

  @override
  String get symbolImplementations => 'Pelaksanaan';

  @override
  String symbolCallersCount(int count) {
    return '$count pemanggil';
  }

  @override
  String get commitMessageHint => 'Mesej commit';

  @override
  String get pushedToPr => 'Di-push ke PR';

  @override
  String get pushFailed => 'Push gagal';

  @override
  String get reviewFindings => 'Penemuan';

  @override
  String get treeLabel => 'Pokok';

  @override
  String get toggleFileTree => 'Tunjuk atau sembunyi pokok fail';

  @override
  String get diffViewSettings => 'Tetapan paparan diff';

  @override
  String get splitViewLabel => 'Belah';

  @override
  String get unifiedViewLabel => 'Bersatu';

  @override
  String get wrapLines => 'Balut baris';

  @override
  String get shiftClickSelectRange => 'Shift-klik untuk memilih julat';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fail',
      one: '1 fail',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'PR kecil — $files, ~$minutes min untuk disemak';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'PR sederhana — $files, blok ~$minutes min untuk disemak';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'PR besar — $files, pertimbangkan membelah sebelum semakan';
  }

  @override
  String get searchInFiles => 'Cari dalam fail';

  @override
  String get showFileList => 'Tunjuk senarai fail';

  @override
  String get searchInFilesHintField => 'Cari dalam fail…';

  @override
  String get searchInFilesHint => 'Cari merentasi fail pull request';

  @override
  String get searchInWholeRepo => 'Cari dalam seluruh repositori';

  @override
  String get searchInThisPullRequest => 'Cari dalam pull request ini';

  @override
  String get searchNoResults => 'Tiada hasil dijumpai';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hasil',
      one: '1 hasil',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files fail',
      one: '1 fail',
    );
    return '$_temp0 dalam $_temp1';
  }

  @override
  String get discardChangesTitle => 'Buang perubahan?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fail',
      one: '1 fail',
    );
    return 'Buang $_temp0 kepada HEAD? Ini tidak boleh dibuat asal.';
  }

  @override
  String get discardAll => 'Buang semua';

  @override
  String get discardFailed => 'Gagal membuang perubahan';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fail',
      one: '1 fail',
    );
    return 'Dibuang $_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted fail',
      one: '1 fail',
    );
    return 'Dibuang $_temp0; $skipped dilangkau (tidak dijejak)';
  }

  @override
  String get prWorktreeUnavailable => 'Ruang kerja belum sedia';

  @override
  String get prWorktreeUnavailableHint =>
      'Menyediakan fail pull request gagal. Buka semula pull request untuk cuba lagi.';

  @override
  String get timestampRelativeLabel => 'Relatif';

  @override
  String get timestampRawLabel => 'Cap masa';

  @override
  String get copyTimestamp => 'Salin cap masa';

  @override
  String get copiedTimestamp => 'Cap masa disalin';

  @override
  String get previewDeployment => 'Pratonton penempatan';

  @override
  String previewDeploymentTab(String site) {
    return 'Pratonton: $site';
  }

  @override
  String get askForReview => 'Minta semakan…';

  @override
  String get closePrsConfirmTitle => 'Tutup pull request?';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tutup $count pull request?',
      one: 'Tutup 1 pull request?',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Menutup $count pull request',
      one: 'Menutup 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Menugaskan $count pull request',
      one: 'Menugaskan 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Meminta semakan pada $count pull request',
      one: 'Meminta semakan pada 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tindakan gagal',
      one: '1 tindakan gagal',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'Rajah';

  @override
  String get diagramViewSource => 'Lihat sumber';

  @override
  String get diagramHideSource => 'Sembunyi sumber';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'Pratonton rajah tidak tersedia ($reason)';
  }

  @override
  String get planUnavailable => 'Rancangan tidak tersedia';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count langkah',
      one: '1 langkah',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'Luluskan dan jalankan';

  @override
  String get planStatusDraft => 'Draf';

  @override
  String get planStatusProposed => 'Rancangan';

  @override
  String get planStatusApproved => 'Rancangan diluluskan';

  @override
  String get planStatusRejected => 'Rancangan ditolak';

  @override
  String get planStatusSuperseded => 'Rancangan diganti';

  @override
  String planRevisionLabel(int revision) {
    return 'Semakan $revision';
  }

  @override
  String get adapterEnforcementTitle => 'Apa yang penyesuai ini kuatkan';

  @override
  String get enforcementFiltersToolSurface => 'Control Center memilih alat';

  @override
  String get enforcementInterceptsToolCalls =>
      'Setiap panggilan dikawal sebelum dijalankan';

  @override
  String get enforcementObservesCompletionContract =>
      'Larian dipegang pada hasilnya';

  @override
  String get enforcementNativeToolsInterceptable =>
      'Alat pelari sendiri kelihatan';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'Alat dalam proses dikotak pasirkan';

  @override
  String get enforcementYes => 'Ya';

  @override
  String get enforcementNo => 'Tidak';

  @override
  String get adapterEnforcementCaveats => 'Kaveat';

  @override
  String get enforcementSummaryModesEnforced => 'Modus dikuatkuasakan';

  @override
  String get enforcementSummaryModesNotEnforced => 'Modus tidak dikuatkuasakan';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kaveat',
      one: '1 kaveat',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'Modus baca sahaja tidak struktural: Control Center tidak dapat membuang alat pelari ini sendiri.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'Tiada pintu pra-pelaksanaan: hanya panggilan alat MCP melalui Control Center.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'Alat fail dan shell pelari sendiri tidak pernah sampai ke Control Center; kotak pasir OS ialah satu-satunya lantai di bawahnya.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'Alat fail dalam proses berjalan di luar kotak pasir, jadi permukaan alat ialah satu-satunya sempadan sistem fail.';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center tidak dapat mendorong atau gagalkan larian yang tamat tanpa menghasilkan hasilnya.';

  @override
  String get modeDegraded => 'Diturunkan';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return 'Modus $mode pada $adapter bergantung pada kotak pasir sahaja; alat fail ejen sendiri tidak dipintas.';
  }

  @override
  String get artifactUnavailable => 'Artifak tidak tersedia';

  @override
  String artifactRevisionLabel(int count) {
    return '$count semakan';
  }

  @override
  String get artifactShowMore => 'Tunjuk lagi';

  @override
  String get artifactShowLess => 'Tunjuk kurang';

  @override
  String get artifactCopy => 'Salin';

  @override
  String get artifactCopied => 'Artifak disalin';

  @override
  String get artifactsTabLabel => 'Artifak';

  @override
  String get artifactsEmptyTitle => 'Belum ada artifak';

  @override
  String get artifactsEmptyBody =>
      'Apabila ejen menerbitkan jadual, carta atau rajah di sini, ia muncul dalam senarai ini.';

  @override
  String get artifactRevisionPickerLabel => 'Semakan';

  @override
  String get artifactRestoreRevision => 'Pulihkan semakan ini';

  @override
  String get artifactOpenInTab => 'Buka dalam tab';

  @override
  String get artifactTitleFallback => 'Artifak';

  @override
  String get providerGenerationLabel => 'Lalai penjanaan';

  @override
  String get providerGenerationHint =>
      'Biarkan medan kosong untuk menggunakan lalai titik akhir sendiri. Model menerbitkan siling output dan resipi pensampelan sendiri; menyajikannya pada nilai lain boleh merosotkannya.';

  @override
  String get providerMaxTokensLabel => 'Maksimum token output';

  @override
  String get addModel => 'Tambah model';

  @override
  String get modelListTitle => 'Senarai model';

  @override
  String get railProvidersGroup => 'Penyedia';

  @override
  String get railCustomProvidersGroup => 'Penyedia tersuai';

  @override
  String get editModelSettings => 'Sunting tetapan model';

  @override
  String get modelIdLabel => 'ID model';

  @override
  String get modelIdImmutableHint =>
      'ID yang titik akhir sajikan; tetap setelah disenaraikan.';

  @override
  String get contextWindowLabel => 'Tetingkap konteks';

  @override
  String get inputTypesLabel => 'Jenis input';

  @override
  String get outputTypesLabel => 'Jenis output';

  @override
  String get modalityText => 'Teks';

  @override
  String get modalityImage => 'Imej';

  @override
  String get modalityAudio => 'Audio';

  @override
  String get modalityVideo => 'Video';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'Tetapkan semula ke automatik';

  @override
  String get modelOverrideEdited => 'Disunting';

  @override
  String get manualModelBadge => 'Ditambah secara manual';

  @override
  String get modelIdRequired => 'Masukkan ID model.';

  @override
  String get modelTokensInvalid => 'Masukkan nombor bulat token yang positif.';

  @override
  String get removeModelAction => 'Buang model';

  @override
  String removeModelConfirmTitle(String model) {
    return 'Buang $model?';
  }

  @override
  String get removeModelConfirmBody =>
      'Model meninggalkan senarai dan ejen yang dipinkan kepadanya berhenti bekerja. Penyedia tidak terjejas.';

  @override
  String get addModelProviderTitle => 'Tambah penyedia model';

  @override
  String get addModelProviderDescription =>
      'Konfigurasikan titik akhir API tersuai dan modelnya.';

  @override
  String get modelListEmptyHint =>
      'Tiada model dikonfigurasikan. Tambah model untuk menggunakannya dalam sembang.';

  @override
  String get addProviderModelsHint =>
      'Model diambil secara langsung setelah titik akhir menjawab. Tambah secara manual hanya jika ia tidak dapat menyenaraikan sendiri.';

  @override
  String get providerTemperatureLabel => 'Temperature';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => 'Lalai penjanaan disimpan';

  @override
  String get providerGenerationInvalid =>
      'Semak nilai: token output maksimum dan top-k mesti positif, temperature 0–2, top-p 0–1.';

  @override
  String get providerGenerationOverridden => 'Ditimpa';

  @override
  String get branchNotPushed => 'belum di-push';

  @override
  String branchNotOnRemote(String branch) {
    return '“$branch” hanya wujud dalam perbualan ini';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub tidak pernah melihat cawangan ini, jadi pull request belum dapat menggunakannya. Menerbitkan menolak commit yang sudah ada dalam worktree — perubahan yang belum di-commit dibiarkan.';

  @override
  String get publishBranch => 'Terbitkan cawangan';

  @override
  String branchPublished(String branch) {
    return '“$branch” diterbitkan ke origin';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'Cawangan diterbitkan. $count perubahan yang belum di-commit tidak disertakan.';
  }

  @override
  String get composePrLoadingBranches => 'Memuatkan cawangan dari GitHub…';

  @override
  String get composePrBranchesFailed =>
      'Tidak dapat memuatkan cawangan dari GitHub. Taip nama cawangan, atau semak sambungan GitHub.';

  @override
  String get composePrSubtitleFromSpace =>
      'Dari cawangan perbualan ini — terbitkannya dahulu jika GitHub belum melihatnya';

  @override
  String get obsTabInsights => 'Wawasan';

  @override
  String get obsTabLive => 'Langsung';

  @override
  String get obsTabQuality => 'Kualiti';

  @override
  String get obsTabUsage => 'Penggunaan';

  @override
  String get obsUsageTotalTokens => 'Jumlah token';

  @override
  String get obsUsagePeakTokens => 'Token puncak';

  @override
  String get obsUsageLongestSession => 'Sesi terpanjang';

  @override
  String get obsUsageCurrentStreak => 'Rentetan semasa';

  @override
  String get obsUsageLongestStreak => 'Rentetan terpanjang';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari',
      one: '1 hari',
      zero: '0 hari',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'Aktiviti token';

  @override
  String get obsUsageActivityModeLabel => 'Modus aktiviti token';

  @override
  String get obsUsageModeDaily => 'Harian';

  @override
  String get obsUsageModeWeekly => 'Mingguan';

  @override
  String get obsUsageModeCumulative => 'Kumulatif';

  @override
  String get obsUsageTimeRange => 'Julat masa';

  @override
  String get obsUsageTrendTitle => 'Aliran token harian';

  @override
  String get obsUsageModelUsage => 'Penggunaan model';

  @override
  String get obsUsageTokensLabel => 'token';

  @override
  String get obsUsageNoActivity => 'Belum ada penggunaan token direkodkan';

  @override
  String get obsUsageOtherModels => 'Lain';

  @override
  String obsUsageCellReadout(String date, String tokens) {
    return '$date · $tokens token';
  }

  @override
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  ) {
    return 'Aktiviti token dari $start hingga $end. $activeDays hari aktif. Hari tersibuk $peak token.';
  }

  @override
  String get obsScreenSubtitle =>
      'Kawalan ejen langsung, atribusi kos, kuota dan isyarat kualiti';

  @override
  String get obsRangeLast24h => '24 jam lalu';

  @override
  String get obsRangeLast7d => '7 hari lalu';

  @override
  String get obsRangeLast30d => '30 hari lalu';

  @override
  String get obsRangeAll => 'Sepanjang masa';

  @override
  String get obsAddFilter => 'Tambah penapis';

  @override
  String get obsFilterAgent => 'Ejen';

  @override
  String get obsFilterModel => 'Model';

  @override
  String get obsFilterStatus => 'Status';

  @override
  String get obsFilterRole => 'Peranan';

  @override
  String get obsKpiTotalRuns => 'Jumlah larian';

  @override
  String get obsKpiTotalCost => 'Jumlah kos';

  @override
  String get obsKpiErrorRate => 'Kadar ralat';

  @override
  String get obsKpiCacheRate => 'Kadar cache';

  @override
  String get obsKpiTokensPerSec => 'Token / saat';

  @override
  String get obsKpiAvgLatency => 'Purata kependaman';

  @override
  String get obsKpiTtft => 'Masa ke token pertama';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta berbanding tempoh sebelumnya';
  }

  @override
  String get obsChartActivity => 'Aktiviti';

  @override
  String get obsChartCost => 'Kos mengikut masa';

  @override
  String get obsLegendRuns => 'Larian';

  @override
  String get obsLegendErrors => 'Ralat';

  @override
  String get obsAgentsTitle => 'Ejen';

  @override
  String obsShowAllAgents(int count) {
    return 'Tunjuk semua $count ejen';
  }

  @override
  String get obsShowFewerAgents => 'Tunjuk lebih sedikit';

  @override
  String get obsRunsTitle => 'Larian';

  @override
  String get obsNoRunsInRange => 'Tiada larian dalam julat ini';

  @override
  String get obsColTime => 'Masa';

  @override
  String get obsColAgent => 'Ejen';

  @override
  String get obsColStatus => 'Status';

  @override
  String get obsColModel => 'Model';

  @override
  String get obsColDuration => 'Tempoh';

  @override
  String get obsColTokens => 'Token';

  @override
  String get obsColCost => 'Kos';

  @override
  String get obsColErrors => 'Ralat';

  @override
  String get obsColRuns => 'Larian';

  @override
  String get obsColAvgLatency => 'Purata kependaman';

  @override
  String get obsColLastActive => 'Terakhir aktif';

  @override
  String get obsStatusPending => 'Tertunda';

  @override
  String get obsStatusRunning => 'Berjalan';

  @override
  String get obsStatusCompleted => 'Selesai';

  @override
  String get obsStatusError => 'Ralat';

  @override
  String get obsRosterLoadError => 'Tidak dapat memuatkan senarai ejen.';

  @override
  String get obsRosterEmpty => 'Belum ada ejen';

  @override
  String get obsRosterEmptyDescription =>
      'Hantar ejen dan ia akan muncul di sini secara langsung — status, alat semasa, token, kos.';

  @override
  String get obsKillAgent => 'Henti paksa ejen';

  @override
  String get obsRosterTokensLabel => 'tok';

  @override
  String get obsCostByRoleTitle => 'Kos mengikut peranan';

  @override
  String get obsCostByRoleSubtitle =>
      'Di mana ruang kerja ini berbelanja, mengikut peranan ejen';

  @override
  String get obsRoleMain => 'Utama';

  @override
  String get obsRoleSubagents => 'Subejen';

  @override
  String get obsRoleAdvisor => 'Penasihat';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'Utama: $main · subejen: $sub · penasihat: $advisor';
  }

  @override
  String get obsTotal => 'Jumlah';

  @override
  String get obsTokenModelTitle => 'Model token (5 paksi)';

  @override
  String get obsTokenModelSubtitle =>
      'Setiap token yang ruang kerja ini belanjakan, mengikut paksi';

  @override
  String get obsAxisInput => 'Input';

  @override
  String get obsAxisOutput => 'Output';

  @override
  String get obsAxisReasoning => 'Penaakulan';

  @override
  String get obsAxisCacheRead => 'Baca cache';

  @override
  String get obsAxisCacheWrite => 'Tulis cache';

  @override
  String get obsTotalTokens => 'Jumlah token';

  @override
  String get obsCacheDiscountNote =>
      'Token baca cache dibilkan pada diskaun, jadi kosnya jauh lebih rendah daripada isipadu input baharu yang sama.';

  @override
  String get obsByModelTitle => 'Mengikut model';

  @override
  String get obsByModelSubtitle => 'Penggunaan token dan kos setiap model';

  @override
  String get obsNoModelUsage => 'Belum ada penggunaan model direkodkan.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count larian',
      one: '1 larian',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => 'Setiap larian';

  @override
  String get obsPerRunSubtitle => 'Kos token lazim satu larian';

  @override
  String get obsMedianRunTokens => 'Median token larian';

  @override
  String get obsMedianRunTokensSub => 'Titik tengah merentasi semua larian';

  @override
  String get obsRunsInWorkspace => 'Dalam ruang kerja ini';

  @override
  String get obsCostShare => 'Bahagian kos';

  @override
  String get obsQuotaConfiguredLimits => 'Had dikonfigurasikan';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'Penggunaan terhadap siling yang anda tetapkan, status terburuk dahulu.';

  @override
  String get obsQuotaAddLimit => 'Tambah had';

  @override
  String get obsQuotaNoLimits =>
      'Belum ada had kuota dikonfigurasikan — tambah satu untuk menjejak penggunaan terhadap siling.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'Buang had $title';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'Ditetapkan semula dalam $duration · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'Tetingkap penggunaan';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'Penggunaan diperhatikan merentasi semua penyedia, tiada siling diterapkan.';

  @override
  String get obsQuotaNoUsage => 'Belum ada penggunaan direkodkan.';

  @override
  String get obsQuotaTokensUsed => 'Token digunakan';

  @override
  String get obsQuotaRequests => 'Permintaan';

  @override
  String get obsQuotaUnitTokens => 'token';

  @override
  String get obsQuotaUnitRequests => 'permintaan';

  @override
  String get obsQuotaUnitCost => 'kos';

  @override
  String get obsQuotaAddLimitTitle => 'Tambah had kuota';

  @override
  String get obsQuotaProviderLabel => 'Penyedia';

  @override
  String get obsQuotaWindowLabel => 'Tetingkap';

  @override
  String get obsQuotaUnitLabel => 'Unit';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'Had ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'Dalam sen AS (500 = \$5.00).';

  @override
  String get obsQuotaStatusOk => 'Ok';

  @override
  String get obsQuotaStatusWarning => 'Amaran';

  @override
  String get obsQuotaStatusExhausted => 'Habis';

  @override
  String get obsQuotaStatusUnknown => 'Tidak diketahui';

  @override
  String get obsGoalNoActiveTitle => 'Tiada matlamat aktif';

  @override
  String get obsGoalNoActiveBody =>
      'Tetapkan matlamat untuk memberi ejen objektif dan bajet token pilihan. Semasa larian selesai, bajet terisi dan ejen didorong untuk merumuskan setelah hampir habis.';

  @override
  String get obsGoalSetGoal => 'Tetapkan matlamat';

  @override
  String get obsGoalTokenBudget => 'Bajet token';

  @override
  String obsGoalTokensLeft(String tokens) {
    return '$tokens tinggal';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (tiada bajet ditetapkan)';
  }

  @override
  String get obsGoalTokensUsed => 'Token digunakan';

  @override
  String get obsGoalElapsed => 'Berlalu';

  @override
  String get obsGoalWrapUp => 'Rumuskan';

  @override
  String get obsGoalClear => 'Kosongkan matlamat';

  @override
  String get obsGoalFallbackTitle => 'Matlamat';

  @override
  String get obsGoalSubtitle => 'Bajet modus matlamat';

  @override
  String get obsGoalStatusActive => 'Aktif';

  @override
  String get obsGoalStatusPaused => 'Dijeda';

  @override
  String get obsGoalStatusBudgetLimited => 'Bajet terhad';

  @override
  String get obsGoalStatusComplete => 'Lengkap';

  @override
  String get obsGoalStatusDropped => 'Digugurkan';

  @override
  String get obsGoalObjectiveLabel => 'Objektif';

  @override
  String get obsGoalBudgetLabel => 'Bajet token (pilihan)';

  @override
  String get obsGoalSetAction => 'Tetapkan matlamat';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => 'Kejayaan %';

  @override
  String get obsBenchmarkPassed => 'Lulus';

  @override
  String get obsBenchmarkFailed => 'Gagal';

  @override
  String get obsBenchmarkErrors => 'Ralat';

  @override
  String get obsBenchmarkSpend => 'Perbelanjaan';

  @override
  String get obsBenchmarkCostPerTask => 'Kos / tugasan';

  @override
  String get obsBenchmarkTrials => 'Percubaan';

  @override
  String get obsBenchmarkNoTrials => 'Belum ada larian untuk dinilai.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dan $count lagi',
      one: 'Dan 1 lagi',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'Lulus';

  @override
  String get obsBenchmarkTrialFail => 'Gagal';

  @override
  String get obsBenchmarkTrialError => 'Ralat';

  @override
  String get obsBenchmarkTrialRunning => 'Berjalan';

  @override
  String get obsBenchmarkReward => 'Ganjaran';

  @override
  String get obsBenchmarkReport => 'Laporan';

  @override
  String get obsBenchmarkCopyMarkdown => 'Salin markdown';

  @override
  String get obsBenchmarkCopied => 'Laporan disalin ke papan keratan';

  @override
  String get obsBehaviorCaption =>
      'Ini ialah isyarat kekecewaan yang dihuraikan dari mesej anda sendiri — bacaan kesihatan perbualan, bukan skor untuk ejen. Dikira secara setempat; tiada apa yang meninggalkan peranti ini.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'Mesej dianalisis';

  @override
  String get obsBehaviorTotalSignals => 'Jumlah isyarat';

  @override
  String get obsBehaviorYelling => 'Menjerit';

  @override
  String get obsBehaviorProfanity => 'Kesat';

  @override
  String get obsBehaviorAnguish => 'Kesakitan';

  @override
  String get obsBehaviorNegation => 'Penafian';

  @override
  String get obsBehaviorRepetition => 'Pengulangan';

  @override
  String get obsBehaviorBlame => 'Menyalahkan';

  @override
  String get obsBehaviorConversationsTitle => 'Perbualan paling kecewa';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'Disusun mengikut ketumpatan isyarat merentasi mesej anda.';

  @override
  String get obsBehaviorNoSignals =>
      'Tiada isyarat kekecewaan dikesan — lancar.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count mesej dianalisis';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count isyarat';
  }

  @override
  String get obsAgentStatusIdle => 'Terlengah';

  @override
  String get obsAgentStatusParked => 'Diparkir';

  @override
  String get obsAgentStatusAborted => 'Digugurkan';

  @override
  String get obsAgentKindSub => 'Sub';

  @override
  String get noChecksOnCommit =>
      'Belum ada semakan dijalankan pada commit ini.';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Berjalan — $count tugas',
      one: 'Berjalan — 1 tugas',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Semua semakan lulus — $count tugas',
      one: 'Semua semakan lulus — 1 tugas',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Selesai — $count tugas',
      one: 'Selesai — 1 tugas',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total tugas',
      one: '1 tugas',
    );
    return '$failed daripada $_temp0 gagal';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tugas',
      one: '1 tugas',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'Matriks: $jobId';
  }

  @override
  String get jobLogsPending => 'Log akan muncul di sini apabila tugas selesai.';

  @override
  String get jobLogsUnavailable => 'Log tidak tersedia untuk tugas ini.';

  @override
  String get noLogsForStep => 'Tiada log ditangkap untuk langkah ini.';

  @override
  String get jobLogsTruncated => 'Log dipotong — menunjukkan output terkini.';

  @override
  String get fullLog => 'Log penuh';

  @override
  String get copyLogs => 'Salin log';

  @override
  String get resizeGraph => 'Seret untuk mengubah saiz graf';

  @override
  String workflowRunStartedAgo(String time) {
    return 'Dimulakan $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'Selesai $time';
  }

  @override
  String get chatBridgesTitle => 'Jambatan sembang';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'Sebut bot dalam $provider untuk meletakkan ejen pada sesuatu, atau failkan tiket dengan $command.';
  }

  @override
  String chatConnectProvider(String provider) {
    return 'Sambung $provider';
  }

  @override
  String get chatDisconnectProvider => 'Putuskan';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName dalam $teamName';
  }

  @override
  String get chatStateLive => 'Langsung';

  @override
  String get chatStateConnecting => 'Menyambung…';

  @override
  String get chatStateError => 'Ralat sambungan';

  @override
  String get chatNotConnected => 'Tidak disambungkan';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'Penstriman langsung dimatikan untuk apl $provider ini — balasan tiba sebagai satu mesej.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'Hanya pentadbir boleh menyambungkan $provider untuk ruang kerja ini.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'Cipta apl $provider, kemudian tampal kelayakannya di sini. Control Center menyambung keluar ke $provider, jadi pelayan ini tidak memerlukan alamat awam.';
  }

  @override
  String chatOpenConsole(String provider) {
    return 'Buka konsol $provider';
  }

  @override
  String get chatOpenSetupGuide => 'Panduan persediaan';

  @override
  String get chatFieldBotToken => 'Token bot';

  @override
  String get chatFieldAppToken => 'Token peringkat apl';

  @override
  String get chatFieldConfigRefreshToken => 'Token konfigurasi apl';

  @override
  String chatFieldOptional(String label) {
    return '$label (pilihan)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'Pautkan akaun $provider saya';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'Pautkan akaun $provider anda supaya mesej yang anda hantar di sana diatribusikan kepada anda.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'Dipautkan ke $externalUserId';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'Pautkan akaun $provider anda';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'Hantar perintah ini kepada bot dalam $provider. Ia berfungsi sekali dan luput dalam 15 minit.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'Akaun $provider anda kini dipautkan — mesej yang anda hantar di sana diatribusikan kepada anda.';
  }

  @override
  String get chatLinkedAccounts => 'Akaun dipautkan';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'Belum ada yang memautkan akaun $provider mereka.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count akaun dipautkan',
      one: '1 akaun dipautkan',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · dipadankan mengikut e-mel';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · dipautkan dengan kod';
  }

  @override
  String get chatUnlink => 'Nyahpaut';

  @override
  String get chatCustomizeBot => 'Sesuaikan bot';

  @override
  String get chatCustomizeBotDescription =>
      'Namakan semula bot, ubah apa yang dikatakannya tentang dirinya, atau namakan semula perintah slash.';

  @override
  String get chatCustomizeBotUnavailable =>
      'Control Center memerlukan token konfigurasi apl untuk menyunting bot. Sambung semula dan sertakan satu.';

  @override
  String chatCreateAppTitle(String provider) {
    return 'Cipta apl $provider';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center boleh mencipta apl $provider untuk anda, dengan kebenaran dan peristiwa yang betul sudah ditetapkan. Anda akan selesai dalam $provider, kemudian tampal kelayakan di sini.';
  }

  @override
  String get chatCreateApp => 'Cipta apl';

  @override
  String get chatCreateAppCta => 'Cipta apl untuk saya';

  @override
  String get chatAppNameLabel => 'Nama apl';

  @override
  String get chatBotDisplayNameLabel =>
      'Nama bot (apa yang ahli taip selepas @)';

  @override
  String get chatDescriptionLabel => 'Perihalan ringkas';

  @override
  String get chatAgentDescriptionLabel => 'Apa yang bot kata ia boleh lakukan';

  @override
  String get chatCommandLabel => 'Perintah slash';

  @override
  String get chatDirectMessages => 'Mesej terus';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'Membolehkan ahli bersembang dengan bot dalam DM. Mungkin memerlukan pelan $provider berbayar.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$provider mencipta apl $appId.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'Beberapa langkah tinggal dan hanya $provider yang boleh melakukannya:';
  }

  @override
  String get chatStepAppToken => 'Jana token peringkat apl';

  @override
  String get chatStepInstall => 'Pasang apl';

  @override
  String get chatOpenAppSettings => 'Buka tetapan apl';

  @override
  String get chatContinueToCredentials => 'Tampal kelayakan';

  @override
  String chatBotUpdated(String provider) {
    return 'Bot dikemas kini dalam $provider.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$provider mengubah kebenaran apl. Pasang semula apl supaya ia berkuat kuasa.';
  }

  @override
  String get chatReinstallApp => 'Pasang semula apl';

  @override
  String chatIconNotEditable(String provider) {
    return 'Ikon bot hanya boleh diubah dalam tetapan apl $provider sendiri.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'Anda juga boleh menciptanya dalam $provider sendiri — tiada token diperlukan. Tetapan di atas ikut bersama pautan.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'Cipta dalam $provider';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '$provider dibuka dalam penyemak imbas anda dengan konfigurasi ini telah diisi. Cipta apl di sana, kemudian selesaikan langkah ini dan kembali dengan token.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider tidak melaporkan apl mana yang diciptanya, jadi menyesuaikan bot dari sini memerlukan token konfigurasi apl kemudian.';
  }

  @override
  String get chatStepCreateApp => 'Cipta apl dari konfigurasi yang telah diisi';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'Pilih ruang kerja dalam $provider dan sahkan.';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens, dengan skop connections:write.';

  @override
  String get chatStepInstallHint =>
      'Install app → salin token OAuth pengguna bot.';

  @override
  String get calendarUseBuiltinApp => 'Gunakan apl Google Control Center';

  @override
  String get calendarUseBuiltinAppHint =>
      'Luluskan dengan akaun Google anda. Tiada apa untuk disediakan dalam Google Cloud.';

  @override
  String get calendarUseOwnClient => 'Gunakan klien Google Cloud saya sendiri';

  @override
  String get calendarUseOwnClientHint =>
      'Masukkan klien OAuth dari projek Google Cloud anda sendiri.';

  @override
  String get aboutTitle => 'Perihal';

  @override
  String get aboutAppVersion => 'Versi apl';

  @override
  String get aboutServerVersion => 'Pelayan disambungkan';

  @override
  String get aboutRpcCatalog => 'Katalog RPC';

  @override
  String get aboutServerUnknown => 'Tidak dilaporkan';

  @override
  String get serverStaleTitle =>
      'Pelayan yang dibungkus lebih lama daripada apl ini';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'cc_server yang berjalan ialah $serverVersion manakala apl ini ialah $appVersion. Mulakan semula apl supaya ia mengambil binaan pelayan dibungkus terkini; dalam pembangunan, bina semula dengan `dart build cli` dalam apps/cc_server.';
  }

  @override
  String get updateCheckButton => 'Semak kemas kini';

  @override
  String get updateChecking => 'Menyemak kemas kini…';

  @override
  String get updateUpToDate => 'Anda sudah terkini';

  @override
  String get updateDeferredBusy =>
      'Kemas kini sedia tetapi mesyuarat sedang merakam — ia akan meminta selepas tamat.';

  @override
  String get updateOpenedReleasesPage =>
      'Membuka halaman keluaran dalam penyemak imbas anda.';

  @override
  String get updateCheckFailed => 'Semakan kemas kini gagal';

  @override
  String updateAvailableVersion(String version) {
    return 'Versi $version tersedia.';
  }

  @override
  String get updateBannerTitle => 'Control Center baharu tersedia';

  @override
  String get updateBannerRefresh => 'Muat semula';

  @override
  String get updateBlockedRecording =>
      'Muat semula dijeda semasa mesyuarat merakam — ia akan dimuat semula apabila tamat.';

  @override
  String get settingsScopeYou => 'Anda';

  @override
  String get settingsScopeWorkspace => 'Ruang kerja';

  @override
  String get settingsScopeServer => 'Pelayan';

  @override
  String get settingsProfile => 'Profil & identiti';

  @override
  String get settingsYourDevices => 'Peranti anda';

  @override
  String get settingsWorkspaceGeneral => 'Umum';

  @override
  String get settingsServerConnection => 'Sambungan & status';

  @override
  String get settingsModelProviders => 'Penyedia model';

  @override
  String get settingsVoiceModels => 'Model suara & mesyuarat';

  @override
  String get settingsDiagnostics => 'Diagnostik & privasi';

  @override
  String get settingsAbout => 'Perihal';

  @override
  String get settingsScopeBadgeYou => 'ANDA';

  @override
  String get settingsScopeBadgeDevice => 'PERANTI INI';

  @override
  String get settingsScopeBadgeWorkspace => 'RUANG KERJA';

  @override
  String get settingsScopeBadgeServer => 'PELAYAN';

  @override
  String get settingsProfileDescription =>
      'Nama, e-mel anda dan identiti git yang distem pada commit yang dibuat untuk anda.';

  @override
  String get settingsServerConnectionDescription =>
      'Pelayan mana yang klien ini bercakap dengannya, dan bagaimana pelayan ini dikongsi (mDNS, terowong, geganti).';

  @override
  String get settingsAboutDescription => 'Identiti binaan dan kemas kini.';

  @override
  String get settingsDiagnosticsDescription =>
      'Pengasingan, pengindeksan, penyegerakan, pengelogan dan pelaporan ranap untuk pemasangan ini.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'Identiti, polisi dan konvensyen yang dikongsi oleh semua orang dalam ruang kerja ini.';

  @override
  String get settingsWorkspacePolicyLabel => 'Polisi ruang kerja';

  @override
  String get settingsWorkspacePolicyDescription =>
      'Digunakan pada setiap ahli dan setiap ejen dalam ruang kerja ini.';

  @override
  String get settingsSecretGlobsLabel => 'Pengecualian laluan rahsia';

  @override
  String get settingsSecretGlobsHelp =>
      'Satu glob setiap baris. Laluan ini disembunyikan daripada pemapar dan tetamu pada permukaan yang membawa kod, di atas lalai terbina.';

  @override
  String get settingsReviewConcurrencyLabel => 'Fan-out semakan';

  @override
  String get settingsReviewConcurrencyHelp =>
      'Berapa ramai penyemak dihantar secara selari apabila tiada kiraan eksplisit diberikan.';

  @override
  String get settingsReviewLevelLabel => 'Tahap semakan';

  @override
  String get settingsReviewLevelHelp =>
      'Seberapa mendalam semakan AI, dan berapa banyak yang dijumpainya dilaporkan di hadapan. Tiada apa yang dibuang — tahap lebih ringan mengumpulkan penemuan kecil dan bukan menggugurkannya.';

  @override
  String get reviewLevelLight => 'Ringan';

  @override
  String get reviewLevelBalanced => 'Seimbang';

  @override
  String get reviewLevelThorough => 'Menyeluruh';

  @override
  String get reviewLevelLightHint =>
      'Satu penyemak. Hanya apa yang penting dilaporkan di hadapan.';

  @override
  String get reviewLevelBalancedHint =>
      'Tiga penyemak meliputi QA, seni bina dan pelaksanaan.';

  @override
  String get reviewLevelThoroughHint =>
      'Menambah pakar keselamatan dan prestasi, dan melaporkan segala yang dijumpai.';

  @override
  String get askAiReviewAtLevel => 'Semak pada tahap berbeza';

  @override
  String reviewNitpicksGroup(int count) {
    return 'Nitpick ($count)';
  }

  @override
  String get reviewFindingResolve => 'Diperbaiki';

  @override
  String get reviewFindingResolveHint =>
      'Tandakan penemuan ini sebagai diperbaiki. Ia berhenti dikira terhadap semakan.';

  @override
  String get reviewFindingDismiss => 'Tolak';

  @override
  String get reviewFindingDismissHint =>
      'Bukan masalah sebenar. Penyemak berhenti menandakan corak ini pada PR akan datang.';

  @override
  String get reviewFindingReopen => 'Buka semula';

  @override
  String get reviewFindingStatusUndoLabel => 'Status penemuan';

  @override
  String get reviewFindingDismissTitle => 'Tolak penemuan ini';

  @override
  String get reviewFindingDismissReasonHint =>
      'Mengapa ini tidak terpakai? Penyemak akan membacanya.';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'Tidak dapat mengemas kini penemuan: $error';
  }

  @override
  String get reviewStaleTitle => 'Semakan ini lapuk';

  @override
  String get reviewStaleBody =>
      'Pull request telah bergerak sejak semakan ini dijalankan. Penemuan mungkin menunjuk pada kod yang tidak lagi wujud.';

  @override
  String reviewStaleReviewedAt(String sha) {
    return 'Disemak pada $sha';
  }

  @override
  String get reviewStaleRerun => 'Semak lagi';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return 'Semakan lapuk pada #$prNumber';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return '$title mempunyai commit baharu sejak semakan terakhirnya.';
  }

  @override
  String get reviewCategorySecurity => 'Keselamatan';

  @override
  String get reviewCategoryStability => 'Kestabilan';

  @override
  String get reviewCategoryDataIntegrity => 'Integriti data';

  @override
  String get reviewCategoryCorrectness => 'Ketepatan';

  @override
  String get reviewCategoryPerformance => 'Prestasi';

  @override
  String get reviewCategoryMaintainability => 'Kebolehselenggaraan';

  @override
  String get reviewEffortQuickWin => 'Kemenangan pantas';

  @override
  String get reviewEffortModerate => 'Sederhana';

  @override
  String get reviewEffortHeavyLift => 'Angkatan berat';

  @override
  String get reviewProposedFix => 'Pembetulan dicadangkan';

  @override
  String get reviewAiAgentPrompt => 'Prompt untuk ejen AI';

  @override
  String get reviewCopyAiPrompt => 'Salin prompt';

  @override
  String get settingsWorkspaceAdminOnly =>
      'Hanya pentadbir ruang kerja boleh mengubah ini.';

  @override
  String get chatMyAccountsTitle => 'Akaun sembang dipautkan';

  @override
  String get settingsServerSso => 'Daftar masuk tunggal';

  @override
  String get settingsServerSsoDescription =>
      'Log masuk SAML dan OpenID Connect dengan peruntukan pengguna';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription =>
      'Pengguna boleh log masuk dengan penyedia ini';

  @override
  String get ssoEnabledDescriptionOn => 'Log masuk langsung untuk penyedia ini';

  @override
  String get ssoIdpMetadataLabel => 'XML metadata IdP';

  @override
  String get ssoIdpMetadataHint => 'tampal XML EntityDescriptor IdP';

  @override
  String get ssoEmailAttributeLabel => 'Atribut e-mel';

  @override
  String get ssoDisplayNameAttributeLabel => 'Atribut nama paparan';

  @override
  String get ssoGroupsAttributeLabel => 'Atribut kumpulan';

  @override
  String get ssoIssuerLabel => 'URL penerbit';

  @override
  String get ssoClientIdLabel => 'Client ID';

  @override
  String get ssoGroupsClaimLabel => 'Tuntutan kumpulan';

  @override
  String get ssoAutoMemberLabel =>
      'Tambah pengguna ke setiap ruang kerja pada log masuk pertama';

  @override
  String get ssoAutoMemberDescription =>
      'Matikan untuk memerlukan jemputan setiap ruang kerja';

  @override
  String get ssoAllowJitLabel =>
      'Peruntukkan pengguna tidak diketahui pada log masuk pertama';

  @override
  String get ssoAllowJitDescription =>
      'Matikan untuk menolak pengguna tanpa akaun sedia ada';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'Terima log masuk tidak diminta (dimulakan IdP)';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'Ketat untuk portal IdP yang melancarkan apl secara langsung';

  @override
  String get ssoWantResponseSignedLabel =>
      'Memerlukan sampul jawapan yang ditandatangani';

  @override
  String get ssoWantResponseSignedDescription =>
      'Tandatangan penegasan sentiasa diperlukan';

  @override
  String get ssoTestConnectionButton => 'Uji sambungan';

  @override
  String get ssoTestConnectionOk => 'Sambungan berfungsi:';

  @override
  String get ssoCopySpMetadata => 'Salin metadata SP';

  @override
  String get ssoCopySpMetadataDone => 'Metadata SP disalin ke papan keratan';

  @override
  String get ssoSavedToast => 'Tetapan daftar masuk tunggal disimpan';

  @override
  String get ssoUnavailable =>
      'Pelayan ini tidak mendedahkan tetapan daftar masuk tunggal. Kemas kini binari pelayan dan cuba lagi.';

  @override
  String get ssoScimCardTitle => 'Peruntukan pengguna (SCIM)';

  @override
  String get ssoScimDescription =>
      'Arahkan penyambung SCIM penyedia identiti anda ke titik akhir di bawah dengan token pembawa. Nyahperuntukan menarik balik sesi dan akses ruang kerja dalam beberapa saat. Pelayan mesti boleh dicapai oleh IdP (terowong atau URL awam).';

  @override
  String get ssoScimEndpoint => 'Titik akhir SCIM';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'Tetapkan URL awam pelayan atau dayakan terowong dahulu';

  @override
  String get ssoScimRegenerate => 'Jana semula token';

  @override
  String get ssoScimRegenerateConfirm =>
      'Jana token pembawa SCIM baharu? Token sebelumnya berhenti berfungsi dengan segera.';

  @override
  String get ssoScimTokenTitle => 'Token pembawa';

  @override
  String get ssoScimTokenPresent => 'Token dikonfigurasikan';

  @override
  String get ssoScimTokenAbsent =>
      'Belum ada token — jana satu untuk mendayakan SCIM';

  @override
  String get ssoScimTokenOnce => 'Token SCIM (ditunjukkan sekali)';

  @override
  String ssoSignInWith(String provider) {
    return 'Log masuk dengan $provider';
  }

  @override
  String get ssoProbeFailed =>
      'Tidak dapat mencapai pelayan itu untuk daftar masuk tunggal';

  @override
  String get ssoOpensBrowser =>
      'Membuka penyemak imbas anda untuk menyelesaikan log masuk';

  @override
  String get ssoWaitingForBrowser =>
      'Menunggu penyemak imbas anda menyelesaikan log masuk…';

  @override
  String get ssoBrowserOpenFailed =>
      'Tidak dapat membuka penyemak imbas anda untuk daftar masuk tunggal';

  @override
  String get ssoUseManualPairing =>
      'Log masuk dengan jemputan atau kunci pasangan sebaliknya';

  @override
  String get ssoHideManualPairing => 'Sembunyi pasangan manual';

  @override
  String get ssoClientIdHint => 'Klien awam (PKCE) — tiada rahsia diperlukan';

  @override
  String get ssoClientSecretLabel => 'Rahsia klien (pilihan)';

  @override
  String get ssoClientSecretHintUnset =>
      'Hanya diperlukan untuk klien IdP sulit';

  @override
  String get ssoClientSecretHintSet =>
      'Rahsia disimpan — biarkan kosong untuk mengekalkannya';

  @override
  String get ssoPairingToggle =>
      'Benarkan pasangan manual (kod jemputan dan kunci pasangan)';

  @override
  String get ssoPairingToggleDescription =>
      'Matikan untuk menjadikan penyertaan daftar masuk tunggal sahaja — peranti baharu tiba melalui log masuk SSO; peranti sedia ada kekal berfungsi';

  @override
  String get ssoPairConfirmTitle => 'Sambung ke pelayan?';

  @override
  String ssoPairConfirmBody(String server) {
    return 'Kelayakan log masuk untuk $server tiba, tetapi tiada log masuk dimulakan dari apl ini. Sambung ke pelayan ini?';
  }

  @override
  String get ssoPairConfirmConnect => 'Sambung';

  @override
  String get ssoPairConfirmCancel => 'Abaikan';

  @override
  String get forgeConnections => 'Hos kod';

  @override
  String get connect => 'Sambung';

  @override
  String get disconnect => 'Putuskan';

  @override
  String get notConnected => 'Tidak disambungkan';

  @override
  String get checkingConnection => 'Menyemak sambungan…';

  @override
  String get fromEnvironment => 'dari persekitaran';

  @override
  String forgeTokenTitle(String forge) {
    return 'Token $forge';
  }

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAudioDescription =>
      'Mikrofon, dikte, pengesanan mesyuarat dan output landskap bunyi.';

  @override
  String get audioDevicesSection => 'Peranti audio';

  @override
  String get voiceInputBehaviorSection => 'Dikte dan mesyuarat';

  @override
  String get audioOutputDeviceTitle => 'Peranti output';

  @override
  String get audioOutputDefaultHint =>
      'Semua bunyi apl dimainkan melalui output lalai sistem.';

  @override
  String get audioOutputGone =>
      'Peranti output yang dipilih tidak lagi disambungkan — lalai sistem digunakan sehingga anda memilih yang lain.';

  @override
  String get reviewHubIntroBody =>
      'Ejen menganalisis diff, memetakan kawasan perubahan dan mencapai keputusan konsensus.';

  @override
  String get reviewHubAlreadyRunning =>
      'Semakan sudah berjalan untuk pull request ini';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'Sejak semakan terakhir: $resolved diselesaikan · $added baharu · $open masih terbuka';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'Sebelumnya disemak pada $sha';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return 'Betulkan $count penemuan';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return 'Betulkan $count yang dipilih';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return 'Komen $count yang dipilih';
  }

  @override
  String get webConnectTitle => 'Sambung ke Control Center';

  @override
  String get webConnectSubtitle =>
      'Dail cc-server yang berjalan melalui WebSocket. Kunci anda kekal pada peranti ini.';

  @override
  String get webConnectServerLabel => 'Pelayan';

  @override
  String get webConnectDeviceIdLabel => 'ID peranti';

  @override
  String get webConnectPairingKeyLabel => 'Kunci pasangan';

  @override
  String get webConnectPairingKeyHint => 'tampal PSK';

  @override
  String get webConnectStayConnected => 'Kekal disambungkan pada peranti ini';

  @override
  String get webConnectStayConnectedDetail =>
      'Kekal disambungkan pada peranti ini (menyimpan kunci anda dalam penyemak imbas ini)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'Gagal mencipta ruang kerja: $error';
  }

  @override
  String committedRelative(String relative) {
    return 'di-commit $relative';
  }

  @override
  String get selectAgents => 'Pilih ejen';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ejen',
      one: '1 ejen',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => 'Perbualan baharu';

  @override
  String get untitledConversation => 'Perbualan tanpa tajuk';

  @override
  String get conversationTitleOptionalHint =>
      'Pilihan — biarkan kosong dan model tajuk menamakannya secara automatik';

  @override
  String get conversationTitlesSectionTitle => 'Tajuk perbualan';

  @override
  String get conversationTitlesSectionCaption =>
      'Pilih pelari yang menamakan perbualan baharu dalam ruang kerja ini secara automatik. Tajuk kekal dimatikan sehingga penyesuai dipilih, dan digunakan pada setiap ahli.';

  @override
  String get conversationTitlesModelLabel => 'Model tajuk';

  @override
  String get conversationTitlesAdapterLabel => 'Penyesuai';

  @override
  String get conversationTitlesAdapterHint => 'Mati';

  @override
  String get conversationTitlesAdapterOff => 'Mati';

  @override
  String get startThread => 'Mula benang';

  @override
  String get deleteSpaceConfirm => 'Padam ruang ini? Semua mesej akan hilang.';

  @override
  String threadTabTitle(String title) {
    return 'Benang: $title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count balasan',
      one: '1 balasan',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return 'Balasan terakhir $time';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Log masuk dengan $provider';
  }

  @override
  String get signInAgain => 'Log masuk semula';

  @override
  String get signInNotFinished =>
      'Log masuk belum kembali lagi. Selesaikannya dalam penyemak imbas, kemudian semak lagi.';

  @override
  String get signedOutTitle => 'Anda telah log keluar';

  @override
  String get signedOutSubtitle =>
      'Sambungan hos kod anda tidak lagi sah — token luput, atau aksesnya ditarik balik. Tiada yang lain berubah: log masuk semula dan semuanya ada di mana anda meninggalkannya.';

  @override
  String get viaServerApp => 'melalui apl pelayan ini';

  @override
  String get ticketing => 'Tiket';

  @override
  String get ticketingProviderHelp =>
      'Di mana tiket anda tinggal. Setempat mengekalkannya dalam Control Center.';

  @override
  String providerComingSoon(String provider) {
    return '$provider (tidak lama lagi)';
  }

  @override
  String get ticketProviderLocal => 'Setempat';

  @override
  String get addKey => 'Tambah kunci';

  @override
  String get providerApps => 'Apl penyedia';

  @override
  String get providerAppsDescription =>
      'Bagaimana pelayan ini mengesahkan sebagai dirinya, dan apa yang seseorang log masuk melaluinya. Kerja latar belakang — webhook, pengundian, segerak — berjalan pada apl, tidak pernah pada token seseorang.';

  @override
  String get providerAppId => 'ID apl';

  @override
  String get providerPrivateKey => 'Kunci peribadi';

  @override
  String get providerClientId => 'ID klien';

  @override
  String get providerClientSecret => 'Rahsia klien';

  @override
  String get providerApiKey => 'Kunci API';

  @override
  String get providerCallbackUrl => 'URL panggil balik';

  @override
  String get providerAppFullyConfigured =>
      'Pelayan boleh bertindak sebagai dirinya, dan orang boleh log masuk.';

  @override
  String get providerAppServerOnly =>
      'Pelayan boleh bertindak sebagai dirinya. Tambah ID klien dan rahsia untuk membenarkan orang log masuk.';

  @override
  String get providerAppSignInOnly =>
      'Orang boleh log masuk. Kerja latar belakang jatuh kepada kelayakan mereka.';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'Kelayakan berfungsi. Dipasang pada: $accounts';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return 'Masukkan kod ini pada halaman $provider yang baru dibuka. Ia telah disalin ke papan keratan anda.';
  }

  @override
  String get deviceCodeWaiting => 'Menunggu anda selesai dalam penyemak imbas…';

  @override
  String get copyCodeAndOpen => 'Salin kod dan buka';

  @override
  String get couldNotOpenBrowser =>
      'Tiada penyemak imbas dapat dibuka. Salin pautan dan selesaikan log masuk sendiri.';

  @override
  String get contextUsage => 'Penggunaan konteks';

  @override
  String get contextUsageFull => 'penuh';

  @override
  String get contextUsageTokens => 'token';

  @override
  String get contextSeeMore => 'Lihat lagi';

  @override
  String get contextSegmentSystemPrompt => 'Prompt sistem';

  @override
  String get contextSegmentRules => 'Peraturan';

  @override
  String get contextSegmentSkills => 'Kemahiran';

  @override
  String get contextSegmentToolDefinitions => 'Takrifan alat';

  @override
  String get contextSegmentMcpTools => 'Alat MCP & dinamik';

  @override
  String get contextSegmentDeferredTools => 'Alat dimuatkan atas permintaan';

  @override
  String get contextSegmentSubagents => 'Takrifan subejen';

  @override
  String get contextSegmentMemory => 'Memori';

  @override
  String get contextSegmentConversation => 'Perbualan';

  @override
  String get contextExplorerTitle => 'Konteks';

  @override
  String get contextExplorerEverything => 'Semua';

  @override
  String get contextExplorerSelectPart =>
      'Pilih bahagian untuk memeriksa kandungannya';

  @override
  String get contextExplorerUnavailable => 'Pecahan konteks tidak tersedia';

  @override
  String get contextRetry => 'Cuba semula';

  @override
  String get settingsFieldOptional => 'Pilihan';

  @override
  String get settingsFilterHint => 'Tapis senarai ini';

  @override
  String get settingsValueNotAvailable => 'Belum tersedia';

  @override
  String get settingsNoEntriesYet => 'Belum ada apa di sini';

  @override
  String get settingsChangedBadge => 'Berubah';

  @override
  String get ssoConnectionCardDescription =>
      'Pilih bagaimana orang log masuk ke pelayan ini, kemudian hidupkan sambungan itu.';

  @override
  String get ssoUseSamlForSignIn => 'Gunakan SAML untuk log masuk';

  @override
  String get ssoUseOidcForSignIn => 'Gunakan OpenID Connect untuk log masuk';

  @override
  String get ssoSaveConnection => 'Simpan sambungan';

  @override
  String get ssoStateLive => 'Langsung';

  @override
  String get ssoStateConfiguredOff => 'Dikonfigurasikan, mati';

  @override
  String get ssoStateOnIncomplete => 'Hidup, tidak lengkap';

  @override
  String get ssoStateActive => 'Aktif';

  @override
  String get ssoStateAllowed => 'Dibenarkan';

  @override
  String get ssoStateNoToken => 'Tiada token';

  @override
  String get ssoSummaryDirectorySync => 'Segerak direktori';

  @override
  String get ssoSummaryManualPairing => 'Pasangan manual';

  @override
  String get ssoNoMethodLiveNote =>
      'Tiada kaedah log masuk langsung. Peranti baharu menyertai dengan jemputan atau kunci pasangan sehingga anda mengkonfigurasikan sambungan dan menghidupkannya.';

  @override
  String get ssoMethodSamlBlurb =>
      'Untuk penyedia identiti yang bercakap SAML 2.0, seperti Okta, Entra ID atau Google Workspace.';

  @override
  String get ssoMethodOidcBlurb =>
      'Untuk penyedia identiti yang bercakap OpenID Connect. Biasanya yang lebih mudah daripada dua untuk disediakan.';

  @override
  String get ssoGroupIdentityProvider => 'Penyedia identiti';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'Dari mana penegasan datang, dan bagaimana pelayan ini mengesahkannya.';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'Penerbit mana yang pelayan ini percayai, dan klien yang ia sahkan sebagai.';

  @override
  String get ssoSpEntityIdShortLabel => 'ID entiti SP';

  @override
  String get ssoSpEntityIdDescription =>
      'Biarkan kosong untuk memperolehnya dari URL pelayan.';

  @override
  String get ssoIssuerDescription =>
      'URL asas yang menyajikan dokumen penemuan penyedia.';

  @override
  String get ssoSecretStored => 'Disimpan';

  @override
  String get ssoGroupHandoff => 'Apa yang penyedia identiti anda perlukan';

  @override
  String get ssoGroupHandoffDescription =>
      'Tampal ini ke dalam aplikasi yang anda cipta di penyedia anda.';

  @override
  String get ssoOriginUnknownTitle =>
      'Pelayan ini tidak mengetahui URL awamnya';

  @override
  String get ssoOriginUnknownBody =>
      'URL log masuk dan panggil balik dibina daripadanya, jadi penyedia anda tidak dapat mencapai pelayan ini sehingga satu ditetapkan. Tambah URL awam atau dayakan terowong di bawah Pelayan → Sambungan.';

  @override
  String get ssoAcsUrlLabel => 'URL perkhidmatan pengguna penegasan (ACS)';

  @override
  String get ssoAcsUrlDescription =>
      'Di mana penyedia anda menyiarkan penegasan yang ditandatangani.';

  @override
  String get ssoSpEntityIdResolvedLabel => 'ID entiti penyedia perkhidmatan';

  @override
  String get ssoMetadataUrlLabel => 'URL metadata SP';

  @override
  String get ssoMetadataUrlDescription =>
      'Penyedia yang mengimport metadata boleh mengambilnya dari sini sebaliknya.';

  @override
  String get ssoRedirectUriLabel => 'URI ubah hala';

  @override
  String get ssoRedirectUriDescription =>
      'Tambah ini ke URI ubah hala yang dibenarkan pada aplikasi penyedia anda.';

  @override
  String get ssoSignInUrlLabel => 'URL log masuk';

  @override
  String get ssoSignInUrlDescription =>
      'Hantar orang ke sini untuk memulakan log masuk daftar masuk tunggal.';

  @override
  String get ssoGroupAttributeMapping => 'Pemetaan atribut';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'Tuntutan mana yang membawa setiap medan. Kekalkan lalai melainkan penyedia anda menamakannya semula.';

  @override
  String get ssoGroupAccess => 'Akses dan peranan';

  @override
  String get ssoGroupAccessDescription =>
      'Apa yang seseorang yang log masuk berjaya dibenarkan lakukan.';

  @override
  String get ssoDefaultRoleShortLabel => 'Peranan lalai';

  @override
  String get ssoDefaultRoleDescription =>
      'Diberikan kepada sesiapa yang kumpulannya tidak sepadan dengan pemetaan di bawah.';

  @override
  String get ssoRoleMapShortLabel => 'Pemetaan kumpulan ke peranan';

  @override
  String get ssoRoleMapDescription =>
      'Kumpulan yang sepadan pertama menang. Pemilik tidak boleh diberikan dengan cara ini.';

  @override
  String get ssoRoleMapGroupHint => 'Nama kumpulan dari penyedia anda';

  @override
  String get ssoRoleMapAdd => 'Tambah pemetaan';

  @override
  String get ssoRoleMapEmpty =>
      'Tiada pemetaan — semua orang mendapat peranan lalai.';

  @override
  String get ssoAdvancedSummary =>
      'Penyimpangan jam, log masuk dimulakan IdP, polisi tandatangan';

  @override
  String get ssoClockSkewShortLabel => 'Penyimpangan jam';

  @override
  String get ssoClockSkewDescription =>
      'Saat toleransi pada cap masa penegasan. 90 sesuai kebanyakan penyedia.';

  @override
  String get ssoScimGenerate => 'Jana token';

  @override
  String get ssoScimTokenOnceBody =>
      'Disalin ke papan keratan anda. Ia ditunjukkan sekali dan tidak dapat dipulihkan, jadi tampalkannya ke penyedia anda sekarang.';

  @override
  String get ssoPairingCardTitle => 'Pasangan manual';

  @override
  String get ssoPairingCardDescription =>
      'Cara lain ke pelayan ini: kod jemputan dan kunci pasangan, untuk peranti yang tidak melalui daftar masuk tunggal.';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count daripada $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'Tiada penyedia disambungkan, jadi masa larian ejen terbina tiada apa untuk dijalankan. Tambah kunci API atau log masuk ke satu di bawah.';

  @override
  String get providersFilterHint => 'Tapis penyedia';

  @override
  String get providersNoneMatch => 'Tiada yang sepadan dengan penapis ini';

  @override
  String get providerDeniedHereTitle => 'Ditolak dalam ruang kerja ini';

  @override
  String get providerDeniedHereBody =>
      'Ejen di sini tidak dapat menggunakan penyedia ini, walaupun ia disambungkan. Ruang kerja lain tidak terjejas.';

  @override
  String get providerNeedsSignIn => 'Log masuk untuk menggunakan penyedia ini';

  @override
  String get providerNeedsApiKey =>
      'Tambah kunci API untuk menggunakan penyedia ini';

  @override
  String get providerApiKeyLabel => 'Kunci API';

  @override
  String get providerGenerationDefaults => 'Lalai penyedia';

  @override
  String get providerNoModelsYet =>
      'Belum ada model dilaporkan. Sambungkan penyedia, kemudian segerak.';

  @override
  String get providerModelsFilterHint => 'Tapis model';

  @override
  String get adaptersNoneReadyNote =>
      'Tiada CLI pelari yang dikatalog dijumpai pada mesin ini. Pasang satu, kemudian muat semula.';

  @override
  String get adaptersFilterHint => 'Tapis pelari';

  @override
  String get adaptersLaunchGroup => 'Lancarkan';

  @override
  String get adaptersLaunchGroupDescription =>
      'Apa yang pelari ini diberikan apabila ejen memulakannya. Tetapkan ini sebelum memasang CLI jika anda mahu.';

  @override
  String get adaptersEnvNone => 'Tiada ditetapkan';

  @override
  String adaptersEnvCount(int count) {
    return '$count ditetapkan';
  }

  @override
  String get adapterArgumentsDescription =>
      'Ditambah pada baris perintah pelari pada setiap pelancaran.';

  @override
  String get defaultChatDescription =>
      'Menjalankan perbualan baharu dan sebarang ejen tanpa pelari sendiri.';

  @override
  String get shortTaskDescription =>
      'Menjalankan kerja latar belakang pantas seperti tajuk dan ringkasan. Model yang lebih kecil sesuai di sini.';

  @override
  String get settingsStateFailed => 'Gagal';

  @override
  String get providerAppsGroupServer => 'Bertindak sebagai pelayan';

  @override
  String get providerAppsGroupServerDescription =>
      'Membolehkan kerja latar belakang mencapai repositori tanpa manusia di sebalik permintaan: webhook, pengundian pull request, segerak tiket.';

  @override
  String get providerAppsGroupPrConversations => 'Perbualan pull request';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'Bagaimana pembangun boleh bercakap dengan pelayan ini secara langsung di GitHub. Berfungsi tanpa webhook atau URL awam — pelayan mengundi.';

  @override
  String get providerAppBotLogin => 'Log masuk bot';

  @override
  String get providerAppBotLoginEmpty =>
      'Uji sambungan untuk menyelesaikan log masuk bot.';

  @override
  String get providerAppAskOnGitHub => 'Bertanya di GitHub';

  @override
  String get providerAppAskOnGitHubHint =>
      'Sebut log masuk bot di atas dalam komen pull request — akhiran [bot] adalah pilihan — untuk meminta semakan atau bertanya soalan, balas dalam benang semakannya, atau tambah label `ai-review` untuk meminta semakan.';

  @override
  String get providerAppsGroupSignIn => 'Melog masuk orang';

  @override
  String get providerAppsGroupSignInDescription =>
      'Membolehkan setiap ahli menyambungkan akaun sendiri dan mendapat kelayakan sendiri.';

  @override
  String get providerAppCapActsAsServer => 'Bertindak sebagai pelayan';

  @override
  String get providerAppCapSignsIn => 'Melog masuk orang';

  @override
  String get portLabel => 'Port';

  @override
  String get mcpNoTokenWarning =>
      'Tanpa token, apa-apa yang dapat mencapai port ini boleh memanggil setiap alat.';

  @override
  String get mcpBridgedToolsLabel => 'Alat';

  @override
  String get guardrailFamilyFiles => 'Fail';

  @override
  String get guardrailFamilyGit => 'Git dan pull request';

  @override
  String get guardrailFamilyMachine => 'Mesin dan rangkaian';

  @override
  String get guardrailFamilyControl => 'Rahsia dan ruang kerja';

  @override
  String get guardrailScopeFieldLabel => 'Menyunting peraturan untuk';

  @override
  String get guardrailScopeFieldDescription =>
      'Skop yang lebih sempit menang atas yang lebih luas. Peraturan yang ditetapkan di sini digunakan di atas apa yang diwarisi.';

  @override
  String get guardrailSetHere => 'Tetapkan di sini';

  @override
  String get guardrailClearAllHere => 'Kosongkan semua';

  @override
  String get sandboxingCardLabel => 'Kotak pasir';

  @override
  String get sandboxingCardDescription =>
      'Sama ada kerja ejen berjalan terasing daripada hos ini, dan apa yang ejen terasing masih boleh capai.';

  @override
  String get sandboxBackendNoneActive => 'Hos, tiada pengasingan';

  @override
  String get sandboxSummaryHost => 'Hos';

  @override
  String get sandboxGroupIsolation => 'Pengasingan';

  @override
  String get sandboxGroupIsolationDescription =>
      'Di mana proses ejen dan tulisan fail sebenarnya berlaku.';

  @override
  String get sandboxBackendFieldDescription =>
      'Auto memilih yang paling kuat yang hos ini sokong. Pinkan satu supaya ia tidak berubah di bawah anda.';

  @override
  String get sandboxCapabilitiesDescription =>
      'Lubang yang ditumbuk melalui sempadan. Setiap satu ialah sesuatu yang ejen terasing masih boleh lakukan kepada dunia luar.';

  @override
  String get sandboxSummaryInForce => 'Berkuat kuasa';

  @override
  String get rigsInstallHintLabel => 'Cara memasangnya';

  @override
  String get rigsStarting => 'Memulakan';

  @override
  String get rigsResidentMemory => 'Memori residen';

  @override
  String get installedLabel => 'Dipasang';

  @override
  String get notInstalledLabel => 'Tidak dipasang';

  @override
  String ssoOtherKindUnsaved(String method) {
    return '$method mempunyai perubahan yang belum disimpan';
  }

  @override
  String get collapseComment => 'Runtuhkan komen';

  @override
  String get expandComment => 'Kembangkan komen';

  @override
  String get suggestedChange => 'Perubahan dicadangkan';

  @override
  String get emptyComment => 'Komen kosong';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count balasan',
      one: '1 balasan',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => 'Semakan tertunda';

  @override
  String failedToResolveConversation(String error) {
    return 'Tidak dapat mengemas kini perbualan: $error';
  }

  @override
  String get addSingleComment => 'Tambah komen tunggal';

  @override
  String get addToReview => 'Tambah ke semakan';

  @override
  String get startAReview => 'Mula semakan';

  @override
  String get reviewNeedsABody =>
      'Tulis ringkasan atau bariskan komen sebaris dahulu';

  @override
  String get reviewSubmitted => 'Semakan diserahkan';

  @override
  String get finishYourReview => 'Selesaikan semakan anda';

  @override
  String get commentVerdict => 'Komen';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count komen tertunda',
      one: '1 komen tertunda',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 'dan $count lagi';
  }

  @override
  String get queuedCommentHint =>
      'Komen ini keluar apabila anda menyerahkan semakan anda.';

  @override
  String commentOnLinesRange(int start, int end) {
    return 'Baris $start hingga $end';
  }

  @override
  String get claudeAccountsTitle => 'Akaun Claude Code';

  @override
  String get claudeAccountsDescription =>
      'Setiap akaun ialah log masuk Claude Code yang berasingan. Larian menggunakan akaun yang dilampirkan di bawah, mengikut urutan ini.';

  @override
  String get claudeAccountsEmpty => 'Belum ada akaun';

  @override
  String get claudeAccountAdd => 'Tambah akaun';

  @override
  String get claudeAccountSignIn => 'Log masuk';

  @override
  String get claudeAccountSignInAgain => 'Log masuk semula';

  @override
  String get claudeAccountSignInHint =>
      'Jalankan ini dalam terminal pada pelayan. Ia membuka penyemak imbas untuk menyelesaikan log masuk, dan menulis kelayakan ke dalam direktori akaun ini.';

  @override
  String get claudeAccountSignedOut => 'Telah log keluar';

  @override
  String get claudeAccountExpired => 'Log masuk luput';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'Log masuk luput pada $when. Log masuk semula untuk menggunakan akaun ini.';
  }

  @override
  String get claudeAccountMakeDefault => 'Jadikan lalai';

  @override
  String get claudeAccountDefault => 'Lalai';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return 'Buang $label?';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'Ini mengeluarkan akaun dan memadam direktorinya pada pelayan. Log masuk itu sendiri tidak terjejas.';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'Tidak dapat menyemak akaun ini: $error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return '$percent% digunakan';
  }

  @override
  String get accountPoolStrategy => 'Putaran';

  @override
  String get accountPoolPinned => 'Dipinkan';

  @override
  String get accountPoolRoundRobin => 'Pusingan giliran';

  @override
  String get accountPoolSerial => 'Satu pada satu masa';

  @override
  String get accountPoolPinnedHint =>
      'Sentiasa bermula pada akaun pertama. Yang lain kekal sebagai sandaran jika ia gagal.';

  @override
  String get accountPoolRoundRobinHint =>
      'Sebarkan larian merentasi akaun, beralih ke yang seterusnya setiap penghantaran.';

  @override
  String get accountPoolSerialHint =>
      'Habiskan akaun pertama sebelum menyentuh yang seterusnya.';

  @override
  String get accountPoolMoveUp => 'Alih ke atas';

  @override
  String get accountPoolMoveDown => 'Alih ke bawah';

  @override
  String get accountPoolUsingAll =>
      'Belum ada yang dilampirkan — setiap akaun digunakan, mengikut urutan ini.';

  @override
  String get accountPoolInheriting => 'Mewarisi akaun ruang kerja.';

  @override
  String get accountPoolResetToWorkspace =>
      'Tetapkan semula ke akaun ruang kerja';

  @override
  String accountPoolCoolingOff(String when) {
    return 'kehabisan kuota sehingga $when';
  }

  @override
  String get accountPoolSignedOut => 'telah log keluar';

  @override
  String get accountPoolExpired => 'log masuk luput';

  @override
  String accountPoolLoadFailed(String error) {
    return 'Tidak dapat memuatkan putaran: $error';
  }

  @override
  String get providerSignedInAccount => 'akaun yang log masuk';

  @override
  String get agentAccountsTab => 'Akaun';

  @override
  String get agentClaudeAccountsNoticeTitle => 'Berbilang akaun Claude Code';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return 'Pelari ini log masuk sebagai salah satu daripada $count akaun Claude Code pada hos ini. Pilih yang mana, atau putar antara mereka, dalam tab Akaun.';
  }

  @override
  String get agentAccountsDescription =>
      'Akaun mana yang larian ejen ini gunakan. Setiap blok bermula dengan mewarisi pilihan ruang kerja.';

  @override
  String get agentAccountsNothingToRotate =>
      'Tiada apa untuk diputar — sambungkan akaun atau kunci kedua dahulu.';

  @override
  String failedToPostReply(String error) {
    return 'Tidak dapat menyiarkan balasan: $error';
  }

  @override
  String commentOnLine(int line) {
    return 'Baris $line';
  }

  @override
  String get viewInDiff => 'Lihat dalam diff';

  @override
  String get subscriptionUsagePreviousAccount => 'Akaun sebelumnya';

  @override
  String get subscriptionUsageNextAccount => 'Akaun seterusnya';

  @override
  String inReplyTo(String path) {
    return 'Sebagai balasan kepada $path';
  }

  @override
  String get subscriptionUsageNoneReported =>
      'Tiada penggunaan dilaporkan untuk akaun ini.';

  @override
  String get subscriptionUsageCredits => 'Kredit';

  @override
  String get reviewHubStaticRule => 'Peraturan statik';

  @override
  String get reviewHubStarted => 'Semakan dimulakan';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'Dijumpai oleh peraturan deterministik ($rule) pada baris yang pull request ini tambah — bukan oleh ejen penyemak.';
  }

  @override
  String get prReviewArtifactTab => 'Semakan PR';

  @override
  String get prReviewRunning => 'Menyemak pull request ini…';

  @override
  String get prReviewStarting => 'Memulakan semakan…';

  @override
  String get prReviewStartingBody =>
      'Menyediakan worktree pull request ini. Penyemak bermula sebaik ia sedia.';

  @override
  String get prReviewFailed => 'Semakan gagal.';

  @override
  String get prReviewRerunning => 'Menyemak semula…';

  @override
  String get prReviewNoOpenFindings => 'Tiada penemuan terbuka';

  @override
  String prReviewOpenFindings(int count) {
    return '$count penemuan terbuka';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used daripada $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return 'Menyiarkan $posted komen sebagai bot. $skipped dilangkau (tiada sauh fail), $failed gagal.';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count penemuan menyasar kod yang pull request ini tidak ubah ($files). GitHub hanya menerima komen sebaris pada diff.';
  }

  @override
  String get reviewRailReport => 'Laporan';

  @override
  String get reviewNoFindingsTitle => 'Belum ada penemuan semakan';

  @override
  String get reviewNoFindingsHint =>
      'Penemuan muncul di sini semasa ejen menyiarkannya.';

  @override
  String reviewShowDismissed(int count) {
    return 'Tunjuk $count ditolak';
  }

  @override
  String reviewHideDismissed(int count) {
    return 'Sembunyi $count ditolak';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perselisihan penyemak dikesan',
      one: '1 perselisihan penyemak dikesan',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'Jenis';

  @override
  String get reviewFilterStatus => 'Status';

  @override
  String get reviewKindBug => 'Pepijat';

  @override
  String get reviewKindSuggestion => 'Cadangan';

  @override
  String get reviewKindRecommendation => 'Syor';

  @override
  String get reviewKindQuestion => 'Soalan';

  @override
  String get reviewKindTicket => 'Tiket';

  @override
  String get archiveSpace => 'Arkibkan ruang';

  @override
  String get archivedSpaces => 'Ruang diarkibkan';

  @override
  String get archivedSpacesEmpty => 'Tiada ruang diarkibkan';

  @override
  String get restoreSpace => 'Pulihkan';

  @override
  String archivedWhen(String time) {
    return 'Diarkibkan $time';
  }

  @override
  String get deleteSpacePermanently => 'Padam secara kekal';

  @override
  String get renameSpace => 'Namakan semula ruang';

  @override
  String get renameConversation => 'Namakan semula perbualan';

  @override
  String get spaceActions => 'Tindakan ruang';

  @override
  String get conversationActions => 'Tindakan perbualan';

  @override
  String get editSpaceRepos => 'Sunting repositori';

  @override
  String get editSpaceReposTitle => 'Repositori ruang';

  @override
  String get editSpaceReposWarning =>
      'Menambah repositori menyemak keluarnya ke dalam ruang ini; membuang satu memadam foldernya.';

  @override
  String get agentSectionIdentity => 'Identiti';

  @override
  String get agentSectionRuntime => 'Masa larian';

  @override
  String get agentSectionGuardrails => 'Pagar pengawal';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count laporan',
      one: '1 laporan',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'Tapis pasukan…';

  @override
  String get teamsSummaryWithLeader => 'Dengan ketua';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pasukan',
      one: '1 pasukan',
      zero: 'Tiada pasukan',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return 'Memadam $name membuang profilnya, pautan kemahirannya dan sejarah larian. Ini tidak boleh dibuat asal.';
  }

  @override
  String get resetToDefault => 'Tetapkan semula ke lalai';

  @override
  String get newAgent => 'Ejen baharu';

  @override
  String get newSkill => 'Kemahiran baharu';

  @override
  String get zoomIn => 'Zum masuk';

  @override
  String get zoomOut => 'Zum keluar';

  @override
  String get resetZoom => 'Tetapkan semula zum';

  @override
  String get imageHostedOnGitHub => 'Imej dihoskan di GitHub';

  @override
  String get imageOpenExternally => 'Imej · buka secara luaran';

  @override
  String get memoryScopeAll => 'Semua skop';

  @override
  String get memoryScopeWorkspace => 'Seluruh ruang kerja';

  @override
  String get memoryScopeFilterLabel => 'Tapis mengikut skop';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return 'Dibataskan kepada repositori $repo';
  }

  @override
  String get toolScreenshot => 'Tangkapan skrin dari ejen';

  @override
  String get toolImageUnavailable => 'Imej tidak tersedia';

  @override
  String toolImagesUnavailable(int count) {
    return '$count imej tidak tersedia';
  }

  @override
  String get shakeUnavailable => 'Goncangan tidak tersedia pada pelayan ini';

  @override
  String get shakeNothing =>
      'Tiada apa untuk digoncang — giliran terkini dilindungi';

  @override
  String shakeDone(int tokens) {
    return 'Membebaskan kira-kira $tokens token';
  }

  @override
  String get compactionDivider => 'Dimampatkan';

  @override
  String compactionDividerCount(int count) {
    return 'Dimampatkan · $count mesej dilipat';
  }

  @override
  String get composerDropToAttach => 'Lepaskan untuk lampirkan';

  @override
  String get attachmentUnavailable => 'Lampiran tidak tersedia';

  @override
  String get attachmentUnavailableDetail =>
      'Lampiran ini tidak lagi dipegang dalam memori. Lampirkan lagi untuk pratontonnya.';

  @override
  String get attachmentPreviewFailed => 'Tidak dapat membuka fail ini';

  @override
  String get attachmentPreviewUnsupported =>
      'Tiada pratonton untuk jenis fail ini';

  @override
  String get attachmentTooLargeToPreview => 'Terlalu besar untuk pratonton';

  @override
  String get attachmentOpenExternally => 'Buka dalam apl lalai';

  @override
  String get asideUnavailable =>
      'Tetapkan model sekali guna dalam tetapan ruang kerja untuk menggunakan ini';

  @override
  String get asideEmpty => 'Belum ada apa untuk dikerjakan';

  @override
  String get asideFailed => 'Tidak dapat mendapat jawapan';

  @override
  String get handoffTitle => 'Penyerahan';

  @override
  String get asideTitle => 'Soalan sampingan';

  @override
  String get attachFilesOrDrop => 'Lampirkan fail — atau lepaskannya di sini';

  @override
  String get guidedGoalTitle => 'Pertajamkan objektif';

  @override
  String get guidedGoalIntro =>
      'Ejen yang bekerja tanpa pengawasan perlu tahu dengan tepat bila ia selesai. Beberapa soalan dahulu.';

  @override
  String get guidedGoalAnswerHint => 'Jawapan anda';

  @override
  String get guidedGoalNext => 'Seterusnya';

  @override
  String get guidedGoalStart => 'Mulakan matlamat';

  @override
  String get guidedGoalSkip => 'Langkau dan jalankan seperti ditulis';

  @override
  String guidedGoalStillMissing(String items) {
    return 'Masih tidak dinyatakan: $items';
  }

  @override
  String get conversationTreeTitle => 'Pokok perbualan';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cawangan',
      one: '1 cawangan',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'Teruskan dari sini';

  @override
  String get conversationTreeFork => 'Cabangkan ke perbualan baharu';

  @override
  String get conversationTreeCurrent => 'Pada cawangan ini';

  @override
  String get conversationTreeEmpty => 'Belum ada apa di sini';

  @override
  String get conversationTreeForked => 'Dicabangkan ke perbualan baharu';

  @override
  String get conversationTreeSwitched => 'Kini meneruskan dari mesej itu';

  @override
  String exportSaved(String path) {
    return 'Disimpan ke $path';
  }

  @override
  String get exportFailed => 'Tidak dapat menulis eksport';

  @override
  String get contextCommandNoAgent =>
      'Tiada ejen dalam perbualan ini, jadi tiada tetingkap konteks untuk dibuka';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'Tiada ejen bernama “$name” dalam perbualan ini. Cuba: $names';
  }

  @override
  String get dumpCopied => 'Transkrip disalin ke papan keratan';

  @override
  String get messageQueueHint =>
      'Teruskan menaip untuk bariskan perubahan susulan';

  @override
  String get steerNow => 'Kemudi';

  @override
  String get steeringQueueLabel => 'Mesej pemanduan dalam barisan';

  @override
  String get steeringDeliverUnavailable =>
      'Tiada ejen yang berjalan dapat mengambil itu sekarang — ia kekal dalam barisan.';

  @override
  String get reorderSteeringCard => 'Susun semula mesej dalam barisan';

  @override
  String get editSteeringCard => 'Sunting mesej dalam barisan';

  @override
  String get deleteSteeringCard => 'Padam mesej dalam barisan';

  @override
  String get steeringBadge => 'Dikemudi';

  @override
  String get settingsSandboxLabel => 'Kotak pasir';

  @override
  String get sandboxExecGrantsTitle => 'Geran boleh laksana';

  @override
  String get sandboxExecGrantsSubtitle =>
      'Program yang ejen boleh jalankan dari salinan kerja repositori anda. Setiap entri diluluskan oleh anda apabila kotak pasir bertanya.';

  @override
  String get sandboxExecGrantsEmpty =>
      'Belum ada keputusan direkodkan. Anda akan ditanya kali pertama ejen perlu menjalankan program dari salinan kerjanya.';

  @override
  String get sandboxExecGrantRevoke => 'Tarik balik';

  @override
  String get sandboxExecGrantAllowed => 'Dibenarkan';

  @override
  String get sandboxExecGrantBlocked => 'Disekat';

  @override
  String get sandboxExecGrantRevokeConfirmTitle => 'Tarik balik keputusan ini?';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'Anda akan ditanya lagi kali seterusnya ejen perlu menjalankan program dari salinan ini.';

  @override
  String get repoScriptsTest => 'Uji';

  @override
  String get repoScriptsTestTooltip =>
      'Jalankan draf ini dalam klon pakai buang repo';

  @override
  String get repoScriptsRunKindTest => 'Uji';

  @override
  String get demoBadgeLabel => 'Demo';

  @override
  String get demoFilePickerTitle => 'Fail demo';

  @override
  String get demoFilePickerBody =>
      'Demo memalsukan muat naik: pilih mana-mana ini dan ia dilampirkan pada mesej anda tanpa menyentuh cakera.';

  @override
  String get demoFilePickerAttach => 'Lampirkan';

  @override
  String get demoReadOnlySave => 'Baca sahaja dalam demo';

  @override
  String get demoBadgeTooltip =>
      'Anda sedang meneroka demo. Data adalah fiksyen dan ejen adalah skrip.';

  @override
  String get demoFirstRunTitle => 'Anda dalam demo langsung';

  @override
  String demoFirstRunBody(int minutes) {
    return 'Ini ialah apl sebenar yang berjalan pada kod sebenar — hanya data yang dicipta. Ejen menstrim larian tulen dari skrip, jadi tiada apa yang sampai ke model dan tiada apa yang berjalan pada mesin. Ruang kerja anda milik anda sahaja dan hilang selepas $minutes minit.';
  }

  @override
  String get demoFirstRunDismiss => 'Faham';

  @override
  String get demoTourTitle => 'Di mana untuk melihat dahulu';

  @override
  String get demoTourSubtitle =>
      'Empat tempat yang menunjukkan apa yang apl sebenarnya lakukan.';

  @override
  String get demoTourSkip => 'Langkau';

  @override
  String get demoTourStarRepo => 'Bintang di GitHub';

  @override
  String get demoTourOpen => 'Buka';

  @override
  String get demoTourSpacesTitle => 'Bercakap dengan ejen';

  @override
  String get demoTourSpacesBody =>
      'Hantar mesej dalam ruang dan tonton larian menstrim masuk — pemikiran, panggilan alat dan kos, tepat seperti larian sebenar dipaparkan.';

  @override
  String get demoTourReviewTitle => 'Semak pull request';

  @override
  String get demoTourReviewBody =>
      'Buka #412. Tinggalkan komen sebaris atau serahkan semakan; kata-kata anda mendarat dalam benang dan kekal di sana.';

  @override
  String get demoTourTicketsTitle => 'Ikuti kerja';

  @override
  String get demoTourTicketsBody =>
      'Tiket, tugasan dan rancangan dipautkan kepada perbualan yang sama yang ejen sedang adakan.';

  @override
  String get demoTourInboxTitle => 'Lihat seluruh operasi';

  @override
  String get demoTourInboxBody =>
      'Setiap amaran dari setiap tiang mendarat dalam satu peti masuk — semakan, tiket, larian dan mesyuarat.';

  @override
  String get demoUnavailableTitle => 'Tidak tersedia dalam demo';

  @override
  String get demoUnavailableTerminal =>
      'Terminal menjalankan shell sebenar pada hos pelayan. Demo tiada permukaan pelaksanaan langsung — itulah yang menjadikannya selamat untuk dibuka kepada umum.';

  @override
  String get demoUnavailableRig =>
      'Persekitaran terasing ialah mesin maya pakai buang yang ejen kawal. Demo tidak but mana-mana: titik akhir awam yang boleh memulakan VM bukan demo.';

  @override
  String get demoUnavailableEditor =>
      'Editor dalam penyemak imbas menjalankan proses code-server terhadap checkout sebenar. Demo tiada keduanya.';

  @override
  String get demoUnavailableFeeds =>
      'Demo membaca suapan sebenar, tetapi senarai langganannya tetap. Menambah atau membuang satu dilumpuhkan di sini.';

  @override
  String get demoUnavailableForge =>
      'Demo tidak memegang kelayakan dan tidak pernah menghubungi GitHub, GitLab atau Linear. Pull requestnya ialah lekapan, dan komen anda padanya disimpan secara setempat.';

  @override
  String get demoUnavailableModels =>
      'Demo tidak memanggil model. Larian ejen ialah main balik skrip, itulah sebabnya ia tidak berharga dan tidak sampai ke penyedia.';

  @override
  String get demoUnavailableMcp =>
      'Permukaan alat MCP tidak dipasang pada demo, jadi tiada klien luaran dapat melekat padanya.';

  @override
  String get demoUnavailableRepos =>
      'Demo tidak menyemak keluar kod dan tidak menjalankan git. Repositori yang anda lihat ialah lekapan di sebalik pull request.';

  @override
  String get demoUnavailableSkills =>
      'Memasang kemahiran memuat turun dan mengimbas kod. Demo tidak mengambil apa-apa.';

  @override
  String get demoUnavailableSso =>
      'Daftar masuk tunggal ialah konfigurasi pelayan. Demo log masuk anda sebagai tetamu sementara sebaliknya.';

  @override
  String get demoUnavailableAudio =>
      'Rakaman dan dikte memerlukan tangkapan audio dan model pertuturan pada hos. Demo tidak menghantar keduanya, jadi mesyuaratnya ialah transkrip tanpa main balik.';

  @override
  String get demoUnavailableServerAdmin =>
      'Ini ialah pentadbiran pelayan. Demo memberi setiap pelawat ruang kerja pakai buang sendiri dan tiada apa di luarnya.';

  @override
  String get settingsBackupRestore => 'Sandaran & pulih';

  @override
  String get settingsBackupRestoreDescription =>
      'Snapshot setiap pangkalan data pada pelayan ini, serta eksport, import dan padam untuk satu ruang kerja.';

  @override
  String get backupSnapshotsLabel => 'Snapshot pemasangan';

  @override
  String get backupSnapshotsExplainer =>
      'Snapshot menyalin setiap pangkalan data ke folder bertarikh pada hos pelayan. Memulihkan seluruh pemasangan bermaksud menyalin folder itu kembali dengan pelayan dihentikan; satu ruang kerja boleh dipulihkan dari sini.';

  @override
  String get backupNowAction => 'Sandarkan sekarang';

  @override
  String backupSnapshotWritten(String path) {
    return 'Snapshot ditulis ke $path';
  }

  @override
  String get backupNoSnapshots =>
      'Belum ada snapshot. Satu diambil hanya apabila anda memintanya — tiada yang dijadualkan.';

  @override
  String get backupSnapshotComplete => 'Lengkap';

  @override
  String get backupSnapshotIncomplete => 'Tidak lengkap';

  @override
  String get backupSnapshotIncompleteNote =>
      'Manifes hilang atau menamakan fail yang tidak ada, jadi snapshot ini tidak dapat memulihkan seluruh pemasangan. Fail ruang kerja yang ada masih boleh diambil satu demi satu.';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ruang kerja',
      one: '1 ruang kerja',
      zero: 'Tiada ruang kerja',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ruang kerja tidak ditangkap',
      one: '1 ruang kerja tidak ditangkap',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'Laluan pada pelayan';

  @override
  String get backupRestoreAction => 'Pulihkan';

  @override
  String get backupRestoreTitle => 'Pulihkan ruang kerja';

  @override
  String backupRestoreBody(String name) {
    return 'Ini menggantikan segala dalam $name dengan salinan yang dipegang dalam snapshot ini. Apa yang ruang kerja itu lakukan sejak snapshot diambil hilang, dan ia tidak boleh dibuat asal.';
  }

  @override
  String backupRestoreDone(String name) {
    return 'Memulihkan $name dari snapshot.';
  }

  @override
  String get backupWorkspaceUnknown => 'Tidak lagi pada pelayan ini';

  @override
  String get backupWorkspaceDataLabel => 'Data ruang kerja';

  @override
  String get backupWorkspaceDataExplainer =>
      'Satu ruang kerja ialah satu fail pangkalan data, jadi mengeksportnya menyalin fail itu dan bukan membuang jadual demi jadual. Mengimport menggantikan segala dalam ruang kerja sasaran dengan fail yang anda namakan.';

  @override
  String get backupExportAction => 'Eksport';

  @override
  String backupExportDone(String path) {
    return 'Dieksport ke $path';
  }

  @override
  String get backupExportedFileLabel => 'Fail dieksport pada pelayan';

  @override
  String get backupImportAction => 'Import';

  @override
  String backupImportTitle(String name) {
    return 'Import ke $name';
  }

  @override
  String backupImportBody(String name) {
    return 'Ini menggantikan segala dalam $name dengan kandungan fail. Apa yang ruang kerja itu pegang sekarang hilang, dan ia tidak boleh dibuat asal.';
  }

  @override
  String get backupImportSourceLabel => 'Fail pangkalan data ruang kerja';

  @override
  String get backupImportSourceDescription =>
      'Fail .db yang pelayan boleh baca. Laluan diselesaikan pada hos pelayan, bukan pada peranti ini.';

  @override
  String backupImportDone(String name) {
    return 'Diimport ke $name.';
  }

  @override
  String backupDeleteBody(String name) {
    return '$name hilang dari setiap senarai dan carian. Fail pangkalan datanya kekal pada cakera, sandaran masih menyertakannya, dan tiada apa yang menuntut semula ruang secara automatik.';
  }

  @override
  String get backupExportDescription =>
      'Tulis salinan pada pelayan, atau muat turun satu ke peranti ini.';

  @override
  String get backupExportOnServerAction => 'Simpan pada pelayan';

  @override
  String get backupDownloadAction => 'Muat turun';

  @override
  String backupDownloadSaved(String path) {
    return 'Disimpan ke $path';
  }

  @override
  String get backupDownloadInBrowser =>
      'Penyemak imbas anda sedang memuat turunnya.';

  @override
  String get backupRestoreFromDeviceLabel => 'Pulihkan dari peranti ini';

  @override
  String get backupRestoreFromDeviceDescription =>
      'Pilih fail pangkalan data ruang kerja di sini dan Control Center memuat naiknya ke pelayan. Inilah yang berfungsi apabila pelayan bukan mesin ini.';

  @override
  String get backupUploadAction => 'Pilih fail dan muat naik';

  @override
  String get backupTransferUnavailable =>
      'Sambungan ini mencapai pelayan melalui geganti, yang tidak membawa pemindahan fail. Sambung ke pelayan secara langsung untuk memuat turun atau memuat naik sandaran.';

  @override
  String get backupTransferForbidden =>
      'Pelayan menolak. Memuat turun ruang kerja memerlukan peranan pentadbir, memulihkan satu memerlukan pemilik, dan snapshot keseluruhan memerlukan pengendali pemasangan.';

  @override
  String get backupTransferUnsupported =>
      'Pelayan ini tiada permukaan sandaran.';

  @override
  String get backupTransferTooLarge =>
      'Fail lebih besar daripada yang pelayan terima.';

  @override
  String get credentialGateWaitingTitle => 'Menunggu kelayakan';

  @override
  String credentialGateHarnessTitle(String provider) {
    return '$provider tiada kelayakan';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Code telah log keluar';

  @override
  String get credentialGateExpiredTitle =>
      'Log masuk Claude Code anda telah luput';

  @override
  String get credentialGatePlanSpentTitle => 'Had pelan Claude Code dicapai';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent menunggu untuk meneruskan.';
  }

  @override
  String get credentialGateWaitingRun => 'Larian menunggu untuk meneruskan.';

  @override
  String get credentialGateWatching =>
      'Memantau pembetulan — larian diteruskan sendiri.';

  @override
  String credentialGateFreesUpAt(String time) {
    return 'Dibebaskan pada $time';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'Larian menyerah pada $time';
  }

  @override
  String get credentialGateCheckAgain => 'Semak lagi';

  @override
  String get credentialGateCancelRun => 'Batal larian';

  @override
  String get credentialGateAccountsTried => 'Akaun dicuba';

  @override
  String get credentialGateClaudeSignInHint =>
      'Log masuk dari Tetapan → Penyesuai → Claude Code, atau jalankan perintah log masuk dalam terminal. Larian mengambilnya sendiri.';

  @override
  String get credentialGateOpenSettings => 'Buka tetapan';

  @override
  String get selectModel => 'Pilih model';

  @override
  String get allModels => 'Semua model';

  @override
  String get noModelsMatchSearch => 'Tiada model sepadan dengan carian anda';

  @override
  String useCustomModelId(String id) {
    return 'Guna “$id”';
  }

  @override
  String get modelFree => 'Percuma';

  @override
  String modelOutputTokens(String tokens) {
    return '$tokens output';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return '$input input / $output output setiap 1M token';
  }

  @override
  String modelEffortLevels(String levels) {
    return 'Usaha penaakulan: $levels';
  }

  @override
  String get modelSupportsReasoning => 'Menyokong usaha penaakulan';

  @override
  String get profileDeliveryMetrics => 'Metrik penghantaran';

  @override
  String profileMetricsSample(int count) {
    return 'PR dianalisis: $count';
  }

  @override
  String get profileMergeRate => 'Kadar penggabungan';

  @override
  String get profileReviewCoverage => 'Liputan semakan';

  @override
  String get profilePrSize => 'Saiz PR';

  @override
  String get profileTimeToMerge => 'Masa untuk digabungkan';

  @override
  String get profileMergeTimeTrend => 'Trend masa penggabungan';

  @override
  String get profileWeeklyMedian => 'Median mingguan, skala logaritma';

  @override
  String get profilePrOpeningPattern =>
      'Hari dalam minggu × jam, waktu tempatan';

  @override
  String get profileFirstReview => 'Masa hingga semakan pertama';

  @override
  String get profileMetricsTruncated =>
      'Persentil menggunakan sampel terhad daripada permintaan tarik yang tersedia.';

  @override
  String profileLinesChanged(String count) {
    return '$count baris';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count min';
  }

  @override
  String profileDurationHours(int count) {
    return '$count jam';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '${days}h ${hours}j';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return 'Ahli: $count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return 'Tiada permintaan tarik oleh $team dalam ruang kerja ini';
  }

  @override
  String get profilePrStateFilterLabel =>
      'Tapis permintaan tarik mengikut status';

  @override
  String get noProfilePrsMatchSearchHint =>
      'Cuba tajuk atau nombor permintaan tarik yang lain';

  @override
  String get rigNetworkUnrestricted => 'Rangkaian tanpa sekatan';

  @override
  String get rigNetworkAllowAllHosts => 'Benarkan semua hos';

  @override
  String get rigNetworkBypassTitle => 'Benarkan setiap hos rangkaian?';

  @override
  String get rigNetworkBypassBody =>
      'Tindakan ini memulakan semula persekitaran terasing dan membuang kerja yang belum dikomit di dalamnya. Selepas itu, sistem tetamu boleh mencapai mana-mana hos rangkaian sehingga ia ditutup.';

  @override
  String get rigNetworkRestartUnrestricted => 'Mulakan semula tanpa sekatan';

  @override
  String get rigNetworkUnrestrictedBody =>
      'Persekitaran terasing ini boleh mencapai setiap hos rangkaian. Tutup dan buka yang baharu untuk memulihkan sekatan lalai.';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      'Emulator Android ini sudah mengurus rangkaiannya sendiri, jadi Control Center tidak dapat menguatkuasakan senarai hos yang dibenarkan. Mulakan semula tidak diperlukan.';

  @override
  String get rigClipboardPermissionHostToRigTitle =>
      'Tampal papan klip ke persekitaran ini?';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'Control Center akan membaca papan klip peranti anda dan menghantar kandungannya ke persekitaran. Kandungan papan klip mungkin mengandungi kata laluan atau rahsia lain.';

  @override
  String get rigClipboardPermissionRigToHostTitle =>
      'Salin papan klip daripada persekitaran ini?';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'Control Center akan membaca papan klip persekitaran dan menggantikan papan klip peranti anda dengan kandungannya. Anggap kandungan daripada persekitaran sebagai tidak dipercayai.';

  @override
  String get rigClipboardAllowTenMinutes => 'Benarkan selama 10 minit';

  @override
  String get rigClipboardAlwaysAllow => 'Sentiasa benarkan';

  @override
  String get rigClipboardSettingsTitle => 'Akses papan klip';

  @override
  String get rigClipboardSettingsHint =>
      'Pilih pemindahan papan klip yang boleh dijalankan tanpa bertanya. Kebenaran sementara tamat selepas 10 minit.';

  @override
  String get rigClipboardAlwaysPasteTitle =>
      'Sentiasa benarkan tampal ke persekitaran';

  @override
  String get rigClipboardAlwaysPasteDescription =>
      'Hantar papan klip peranti ini ke mana-mana persekitaran tanpa bertanya.';

  @override
  String get rigClipboardAlwaysCopyTitle =>
      'Sentiasa benarkan salin daripada persekitaran';

  @override
  String get rigClipboardAlwaysCopyDescription =>
      'Letakkan kandungan papan klip daripada mana-mana persekitaran pada peranti ini tanpa bertanya.';
}
