// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get succeeded => 'Berhasil';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'Coba lagi #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'Memulai · $time';
  }

  @override
  String get agentActivityFollowingLive => 'Mengikuti aktivitas langsung';

  @override
  String get agentActivityJumpToLatest => 'Lompat ke terbaru';

  @override
  String get agentActivityLoadFailed => 'Tidak dapat memuat aktivitas run ini';

  @override
  String get agentActivityNotRecorded =>
      'Tidak ada aktivitas yang tercatat untuk run ini';

  @override
  String get agentActivityNotRecordedHint =>
      'Run yang selesai sebelum pencatatan aktivitas diaktifkan tidak memiliki linimasa.';

  @override
  String get agentActivityRunUnavailable => 'Run ini tidak lagi tersedia';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'Subagen dari $agent';
  }

  @override
  String get agentActivityUnsupported =>
      'Pencatatan aktivitas tidak tersedia di server yang terhubung';

  @override
  String get agentActivityUnsupportedHint =>
      'Mulai ulang aplikasi agar memuat build server terbaru.';

  @override
  String get agentActivityWaiting => 'Menunggu aktivitas…';

  @override
  String get created => 'Dibuat';

  @override
  String get dictationStart => 'Mulai dikte';

  @override
  String get dictationListening => 'Mendengarkan…';

  @override
  String get dictationUnavailable =>
      'Dikte memerlukan model suara di host server. Atur di pengaturan suara.';

  @override
  String get dictationFailedToStart => 'Tidak dapat memulai dikte';

  @override
  String get dictationHoldToTalkTitle => 'Tahan untuk bicara';

  @override
  String get dictationHoldToTalkDescription =>
      'Tahan tombol mikrofon atau pintasan untuk mendikte, lepas untuk berhenti. Jika nonaktif, tekan sekali untuk mulai dan sekali lagi untuk berhenti.';

  @override
  String get focusConversation => 'Fokus percakapan';

  @override
  String get ideAgentActivity => 'Aktivitas agen';

  @override
  String get keybindingPushToTalk => 'Tekan untuk bicara';

  @override
  String get keybindingPushToTalkDescription =>
      'Tahan atau alihkan dikte suara di penyusun pesan';

  @override
  String get agentPermissions => 'Izin agen';

  @override
  String get agentPermissionsSettingsDescription =>
      'Tentukan apa yang boleh dilakukan agen sendiri, harus ditanyakan dulu, atau tidak boleh sama sekali — per ruang kerja, agen, atau space.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Tetapkan keputusan untuk setiap jenis efek. Aturan berjenjang: space menimpa agen, agen menimpa ruang kerja, ruang kerja menimpa prasetel mode. Aturan paling spesifik yang berlaku.';

  @override
  String get guardrailLoading => 'Memuat aturan…';

  @override
  String get guardrailRulesLoadFailed => 'Tidak dapat memuat aturan izin.';

  @override
  String get guardrailScopeWorkspace => 'Ruang kerja';

  @override
  String get guardrailScopeAgent => 'Agen';

  @override
  String get guardrailScopeSpace => 'Space';

  @override
  String get guardrailSelectAgent => 'Pilih agen';

  @override
  String get guardrailSelectSpace => 'Pilih space';

  @override
  String get guardrailNoAgents => 'Belum ada agen di ruang kerja ini.';

  @override
  String get guardrailNoSpaces => 'Belum ada space di ruang kerja ini.';

  @override
  String get guardrailClassFileDelete => 'Hapus file';

  @override
  String get guardrailClassFileWriteOutsideWorktree =>
      'Tulis di luar pohon kerja';

  @override
  String get guardrailClassGitCommit => 'Buat commit';

  @override
  String get guardrailClassGitPush => 'Push ke remote';

  @override
  String get guardrailClassPrCreate => 'Buka pull request';

  @override
  String get guardrailClassPrPublish => 'Publikasikan review atau merge';

  @override
  String get guardrailClassVendorSyncWrite => 'Tulis ke pelacak eksternal';

  @override
  String get guardrailClassNetworkEgress => 'Akses jaringan';

  @override
  String get guardrailClassSecretAccess => 'Baca secret';

  @override
  String get guardrailClassPackageInstall => 'Instal paket';

  @override
  String get guardrailClassProcessSpawn => 'Jalankan proses';

  @override
  String get guardrailClassWorkspaceMutation => 'Ubah struktur ruang kerja';

  @override
  String get guardrailClassEnclosureControl => 'Kendalikan enclosure (rig)';

  @override
  String get navRigs => 'Rigs';

  @override
  String get rigsUnsupportedServer =>
      'Server ini tidak dapat menghosting permukaan rig apa pun. Periksa persyaratan host untuk mesin yang ingin Anda gunakan.';

  @override
  String get rigSurfaceComputer => 'Komputer';

  @override
  String get rigSurfaceBrowser => 'Browser';

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
    return '$engine sekali pakai, terisolasi dari mesin Anda. Buka engine lain untuk membandingkan halaman yang sama berdampingan.';
  }

  @override
  String get rigPhaseReady => 'Siap';

  @override
  String get rigPhaseStarting => 'Memulai';

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
  String get rigNotAccelerated => 'Diemulasi';

  @override
  String get rigAudioListen => 'Dengarkan mesin';

  @override
  String get rigAudioMute => 'Bisukan mesin';

  @override
  String get rigYouHaveControl => 'Anda memegang kendali';

  @override
  String get rigBackendAvailable => 'Tersedia';

  @override
  String get rigBackendUnavailable => 'Tidak tersedia';

  @override
  String get rigEgressNotEnforced =>
      'Jaringan tidak dikurung di backend ini — konektivitas dikelola sendiri.';

  @override
  String get rigStartMachine => 'Mulai mesin';

  @override
  String get rigStartHint =>
      'Memulai VM sekali pakai yang Anda dan agen bagikan untuk percakapan ini. VM dihancurkan saat ditutup, dan isinya tidak menyentuh komputer Anda.';

  @override
  String get rigStartAndroidHint =>
      'Menghubungkan ke emulator Android yang sudah berjalan di server. Akses jaringan tidak diisolasi.';

  @override
  String get rigStartIosHint =>
      'Membuat Simulator iOS sementara di server macOS. Simulator dihapus saat rig ditutup; akses jaringan tidak diisolasi.';

  @override
  String get rigTechnicalDetails => 'Detail teknis';

  @override
  String get rigStopMachine => 'Hentikan mesin';

  @override
  String get rigHomeButton => 'Beranda';

  @override
  String get rigRotateClockwise => 'Putar searah jarum jam';

  @override
  String get rigRotateCounterclockwise => 'Putar berlawanan jarum jam';

  @override
  String get rigTakeScreenshot => 'Ambil tangkapan layar';

  @override
  String get rigScreenshotSaved => 'Tangkapan layar disimpan';

  @override
  String rigScreenshotSaveFailed(String error) {
    return 'Tidak dapat menyimpan tangkapan layar: $error';
  }

  @override
  String get rigSurfaceUnavailable =>
      'Server ini tidak dapat menampung jenis mesin ini.';

  @override
  String get rigTabNeedsConversation =>
      'Buka percakapan dulu — mesin terikat ke satu percakapan, agar Anda dan agen melihat layar yang sama.';

  @override
  String get ideMenuSectionTools => 'Alat';

  @override
  String get ideMenuSectionMachines => 'Mesin';

  @override
  String get ideMenuSectionReopen => 'Buka lagi';

  @override
  String get ideMenuSearchHint => 'Cari';

  @override
  String get ideMenuNoMatches => 'Tidak ada hasil';

  @override
  String get rigMenuComputer => 'Komputer';

  @override
  String get rigMenuBrowser => 'Browser';

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
      'Mesin tetap berjalan di latar belakang — buka lagi kapan saja dari bilah sisi. Matikan saja untuk membebaskan memorinya sekarang.';

  @override
  String get ideCloseKeepBodyShell =>
      'Perintah tetap berjalan di latar belakang — buka lagi shell kapan saja dari bilah sisi. Akhiri saja untuk menghentikan yang sedang dikerjakan sekarang.';

  @override
  String get ideCloseKeepBodyAgent =>
      'Agen tetap bekerja di latar belakang — buka lagi percakapan kapan saja dari bilah sisi. Hentikan saja untuk mengakhiri jalannya sekarang.';

  @override
  String get ideCloseKeepRunning => 'Biarkan berjalan';

  @override
  String get ideCloseShutDownMachine => 'Matikan';

  @override
  String get ideCloseEndShell => 'Akhiri shell';

  @override
  String get ideCloseStopAgent => 'Hentikan agen';

  @override
  String get rigsSettingsSubtitle =>
      'Apa yang dapat di-boot server ini, image dasar yang dibutuhkannya, dan mesin yang sedang berjalan';

  @override
  String get rigsCapabilitiesTitle => 'Server ini';

  @override
  String get rigInstallIosAutomation => 'Instal bridge otomatisasi iOS';

  @override
  String get rigInstallingIosAutomation => 'Menginstal bridge otomatisasi iOS…';

  @override
  String get rigIosAutomationInstalled =>
      'Bridge otomatisasi iOS telah diinstal';

  @override
  String get rigsImagesTitle => 'Image dasar';

  @override
  String get rigsImagesHint =>
      'Setiap rig di-boot dari salah satu image baca-saja ini. Setiap sesi menulis ke overlay sekali pakai, jadi satu rig tidak pernah mengubah titik awal rig berikutnya.';

  @override
  String get rigsRunningTitle => 'Sedang berjalan';

  @override
  String get rigsNoneRunning => 'Tidak ada mesin yang berjalan.';

  @override
  String get rigsCustomImagesTitle => 'Image kustom (ruang kerja ini)';

  @override
  String get rigsCustomImagesHint =>
      'Arahkan Terminal (VM) atau Browser (VM) ke image Anda sendiri — perluas default dengan alat yang dibutuhkan proyek, atau gunakan image kompatibel dari registry. Mesin baru menggunakannya; yang sedang berjalan tetap memakai miliknya. Lihat panduan rigs untuk persyaratan image.';

  @override
  String get rigsCustomTerminalImageLabel => 'Image Terminal (VM)';

  @override
  String get rigsCustomBrowserImageLabel => 'Image Browser (VM)';

  @override
  String get rigsCustomImagePlaceholder =>
      'mis. ghcr.io/acme/dev-shell:1.2 — kosongkan untuk default';

  @override
  String get rigsCustomImageInvalid =>
      'Masukkan referensi registry seperti repo/name:tag. Path lokal dan arsip tidak diizinkan.';

  @override
  String get rigsCustomImageSaved =>
      'Tersimpan. Mesin baru di-boot dengan image ini; yang sedang berjalan tetap memakai miliknya.';

  @override
  String get rigsEgressTitle => 'Egress browser (ruang kerja ini)';

  @override
  String get rigsEgressHint =>
      'Host tambahan yang boleh dijangkau browser terkunci — satu per baris: host persis (api.example.com) atau wildcard subdomainnya (*.example.com). Situs produk tetap diizinkan. Mesin baru memakai daftar ini; yang sedang berjalan tetap memakai yang dipakai saat boot.';

  @override
  String rigsEgressInvalid(String host) {
    return '\"$host\" bukan entri host yang valid.';
  }

  @override
  String get rigsEgressSaved =>
      'Tersimpan. Mesin browser baru mengizinkan host ini; yang sedang berjalan tetap memakai miliknya.';

  @override
  String get rigImageInstalled => 'Terpasang';

  @override
  String get rigImageNotDownloaded => 'Belum diunduh';

  @override
  String get rigImageNotPublished => 'Belum dipublikasikan';

  @override
  String get rigImageNotPublishedHint =>
      'Belum ada image yang dipublikasikan, jadi tidak ada yang dapat diunduh. Impor image disk yang kompatibel untuk mengaktifkannya.';

  @override
  String get rigImageDownload => 'Unduh';

  @override
  String get rigImageDownloading => 'Mengunduh…';

  @override
  String get rigImageImport => 'Impor';

  @override
  String get rigImageImportMessage =>
      'Path ke image disk qcow2 di sistem berkas server. Disalin ke penyimpanan image, jadi berkasnya boleh dipindah setelahnya.';

  @override
  String get rigConnectingStream => 'Menghubungkan ke rig';

  @override
  String get rigStreamNotAllowed => 'Anda tidak memiliki akses ke rig ini.';

  @override
  String get rigStreamNotRunning => 'Rig ini sudah tidak berjalan.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'Tampilan langsung memerlukan ffmpeg di host ini. Pasang ffmpeg lalu buka ulang tab.';

  @override
  String get rigStreamEnded => 'Tampilan langsung berakhir.';

  @override
  String get rigStreamFailed => 'Tampilan langsung tidak dapat dibuka.';

  @override
  String get rigStreamDisconnected => 'Tidak terhubung ke server.';

  @override
  String rigDropSendingOne(String name) {
    return 'Menyalin \"$name\" ke mesin…';
  }

  @override
  String rigDropSendingMany(int count) {
    return 'Menyalin $count file ke mesin…';
  }

  @override
  String get rigTerminalDropSending => 'Menyalin ke mesin…';

  @override
  String get rigTerminalPasteImage => 'Gambar yang ditempel disimpan di mesin';

  @override
  String get rigPortsTitle => 'Port yang diteruskan';

  @override
  String get rigPortsTooltip => 'Port yang terbuka di dalam mesin ini';

  @override
  String get rigPortsEmpty =>
      'Belum ada yang mendengarkan. Jalankan server di terminal — server pengembangan di port 3000 akan muncul di sini.';

  @override
  String get rigPortsAdd => 'Tambah port';

  @override
  String get rigPortsAddHint => 'Port tamu yang akan diteruskan (mis. 3000)';

  @override
  String get rigPortsAutoForward => 'Teruskan port otomatis';

  @override
  String get rigPortsCopyUrl => 'Salin URL lokal';

  @override
  String rigPortsCopiedUrl(String url) {
    return 'Disalin $url';
  }

  @override
  String get rigPortsStopForward => 'Hentikan penerusan';

  @override
  String get rigPortsExposeLan => 'Bagikan di jaringan lokal';

  @override
  String get rigPortsLanPrivate => 'Hanya lokal';

  @override
  String get rigPortsLanShared => 'Di jaringan';

  @override
  String get rigPortsSetDomain => 'Atur domain browser (.test)';

  @override
  String get rigPortsDomainHint =>
      'Domain untuk Browser (VM), mis. myapp.test — dapat diakses di sana, bukan di host';

  @override
  String get rigPortsProcessUnknown => 'proses tidak dikenal';

  @override
  String get rigPortsInactive => 'tidak mendengarkan';

  @override
  String get rigPortsTooltipHost => 'Port yang terbuka di terminal ini';

  @override
  String get rigPortsEmptyHost =>
      'Belum ada yang mendengarkan di terminal ini. Mulai server dan ia muncul di sini.';

  @override
  String get rigPortsAddHintHost => 'Port yang dipetakan (mis. 5173)';

  @override
  String get rigPortsLocalPortHint => 'Port lokal (opsional)';

  @override
  String rigPortsDestDesktop(int port) {
    return 'localhost:$port';
  }

  @override
  String rigPortsDestBrowser(int port) {
    return 'localhost:$port di browser (VM)';
  }

  @override
  String get rigPortsDestBrowserUnreachable => 'browser (VM) tidak terpasang';

  @override
  String rigPortsDestAndroid(int port) {
    return 'localhost:$port di Android';
  }

  @override
  String get rigPortsDestAndroidUnreachable => 'Android tidak terpasang';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count image dasar masih perlu diunduh',
      one: '1 image dasar masih perlu diunduh',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'Izinkan';

  @override
  String get guardrailDecisionPrompt => 'Tanyakan dulu';

  @override
  String get guardrailDecisionDeny => 'Tolak';

  @override
  String get guardrailSourceThisScope => 'Cakupan ini';

  @override
  String get guardrailSourceDefault => 'Default bawaan';

  @override
  String get guardrailSourcePreset => 'Preset mode';

  @override
  String get guardrailSourceInherited => 'Diwariskan';

  @override
  String get guardrailClearToInherited => 'Kembalikan ke diwariskan';

  @override
  String get guardrailWhatIf => 'Bagaimana jika?';

  @override
  String get guardrailWhatIfDescription =>
      'Lihat bagaimana aturan saat ini akan menyelesaikan suatu aksi, dengan logika yang sama yang dipakai agen.';

  @override
  String get guardrailProbeActionLabel => 'Aksi';

  @override
  String get guardrailProbeCommandLabel => 'Perintah (opsional)';

  @override
  String get guardrailProbeCommandHint => 'mis. git push origin main';

  @override
  String get guardrailProbeAgentLabel => 'Agen (opsional)';

  @override
  String get guardrailProbeSpaceLabel => 'Ruang (opsional)';

  @override
  String get guardrailProbeNone => 'Tidak ada';

  @override
  String get guardrailProbeModeLabel => 'Mode';

  @override
  String get guardrailProbeResult => 'Hasil';

  @override
  String get guardrailProbeSource => 'Sumber:';

  @override
  String get guardrailAdapterMatrix => 'Di mana aturan ditegakkan';

  @override
  String get guardrailAdapterMatrixDescription =>
      'Referensi jujur: di mana setiap efek benar-benar tertangkap, per runner agen. Ini mendokumentasikan kenyataan, bukan jaminan — efek yang runner jalankan di luar jalur tidak dapat dicegat.';

  @override
  String get guardrailEffectColumn => 'Efek';

  @override
  String get guardrailAdapterHarness => 'Harness bawaan';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'Batas bawah sandbox';

  @override
  String get guardrailEnforcementPolicyGate => 'Gerbang kebijakan';

  @override
  String get guardrailEnforcementSandbox => 'Hanya sandbox';

  @override
  String get guardrailEnforcementNone => 'Tidak dapat ditegakkan';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'Keputusan izin diperiksa sebelum efek dijalankan dan dapat memblokirnya.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'Hanya sandbox yang membatasinya; aturan izin tidak dikonsultasikan.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'Keputusan ini hanya bersifat saran — tidak dapat dicegat di sini.';

  @override
  String get obsStatCost => 'biaya';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount didelegasikan';
  }

  @override
  String get obsStatDuration => 'durasi';

  @override
  String get obsStatTokens => 'token';

  @override
  String get obsStatTools => 'alat';

  @override
  String get openAgentActivity => 'Buka aktivitas';

  @override
  String get orgChart => 'Bagan organisasi';

  @override
  String get orgChartEmpty => 'Belum ada agen';

  @override
  String get navCalendar => 'Kalender';

  @override
  String get serverConnection => 'Koneksi server';

  @override
  String get serverModeLocal => 'Jalankan di aplikasi ini';

  @override
  String get serverModeLocalDescription =>
      'Control Center menjalankan servernya sendiri di mesin ini dan mengelola data Anda secara lokal.';

  @override
  String get serverModeRemote => 'Hubungkan ke instans jarak jauh';

  @override
  String get serverModeRemoteDescription =>
      'Hubungkan ke server Control Center yang berjalan di tempat lain. Data Anda berada di server tersebut.';

  @override
  String get serverRemoteUrl => 'URL server';

  @override
  String get serverRemoteDeviceId => 'ID perangkat';

  @override
  String get serverRemotePairingKey => 'Kunci pairing';

  @override
  String get serverRemotePairingKeyHint =>
      'Tempel kunci pairing dari server jarak jauh';

  @override
  String get serverSetupInviteCode => 'Kode undangan';

  @override
  String get serverSetupInviteCodeHint =>
      'Tempel kode undangan sekali pakai (kosongkan untuk memakai kunci pairing)';

  @override
  String get serverDiscoveryTooltip => 'Temukan server di jaringan Anda';

  @override
  String get serverDiscoveryTitle => 'Server di jaringan Anda';

  @override
  String get serverDiscoverySearching => 'Mencari server…';

  @override
  String get serverDiscoveryEmpty =>
      'Tidak ada server ditemukan. Pastikan server sedang berjalan dan perangkat ini dapat menjangkaunya, lalu cari lagi.';

  @override
  String get serverDiscoveryRefresh => 'Cari lagi';

  @override
  String get serverListActive => 'Aktif';

  @override
  String get serverListSwitch => 'Alihkan';

  @override
  String get serverListAddTitle => 'Tambah server';

  @override
  String get serverListRemoveActiveHint =>
      'Alihkan ke server lain sebelum menghapus yang ini.';

  @override
  String get serverSwitchFailedTitle => 'Tidak dapat mengalihkan server';

  @override
  String get serverListInsecureBadge => 'Tidak aman';

  @override
  String get connectionPathLocal => 'Lokal';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'Mematikan';

  @override
  String get shutdownSubtitle => 'Menutup server lokal';

  @override
  String get shutdownServiceApprovals => 'Persetujuan';

  @override
  String get shutdownServiceBackgroundJobs => 'Pekerjaan latar belakang';

  @override
  String get shutdownServiceScheduler => 'Penjadwal pekerjaan';

  @override
  String get shutdownServiceCalendar => 'Sinkronisasi kalender';

  @override
  String get shutdownServiceWeather => 'Cuaca';

  @override
  String get shutdownServiceSoundscape => 'Soundscape';

  @override
  String get shutdownServiceMeetings => 'Rapat';

  @override
  String get shutdownServiceVoiceModels => 'Model suara';

  @override
  String get shutdownServiceNetworking => 'Jaringan';

  @override
  String get shutdownServicePresence => 'Kehadiran';

  @override
  String get shutdownServiceDataSync => 'Sinkronisasi data';

  @override
  String get shutdownServiceDeviceRelay => 'Relay perangkat';

  @override
  String get shutdownServiceMcpConnections => 'Koneksi MCP';

  @override
  String get shutdownServiceCodeEditors => 'Editor kode';

  @override
  String get serverSharingTitle => 'Bagikan server ini';

  @override
  String get serverSharingDescription =>
      'Buat server ini dapat dijangkau dari perangkat Anda yang lain. Tidak ada yang diekspos secara publik kecuali Anda mengaktifkan tunnel di bawah. Undangan pairing menyertakan alamat server saat ini secara otomatis — buat di pengaturan ruang kerja.';

  @override
  String get serverSharingUnavailable =>
      'Kontrol berbagi tidak tersedia di server ini.';

  @override
  String get serverSharingMdnsLabel => 'Penemuan LAN';

  @override
  String get serverSharingMdnsOn =>
      'Mengiklankan server ini di jaringan lokal Anda (mDNS)';

  @override
  String get serverSharingMdnsOff =>
      'Tidak mengiklankan di jaringan lokal Anda (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'Tunnel';

  @override
  String get serverSharingTunnelHelper =>
      'Mengaktifkan tunnel membuat server ini dapat dijangkau dari internet. Paparan publik bersifat opt-in dan nonaktif secara default.';

  @override
  String get serverSharingProviderOff => 'Nonaktif';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'URL publik';

  @override
  String get serverSharingTunnelStarting => 'Memulai tunnel…';

  @override
  String serverSharingTunnelError(String error) {
    return 'Kesalahan tunnel: $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'Tunnel sudah aktif. Akses lewat hostname DNS yang dikonfigurasi.';

  @override
  String get serverSharingRelayLabel => 'Relay';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'Relay bulan ini: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'Sesi relay aktif: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle => 'Gagal memperbarui berbagi';

  @override
  String get pairNewClient => 'Pasangkan klien baru';

  @override
  String get pairClientNameHint => 'Beri label klien ini (mis. Laptop kerja)';

  @override
  String get pairClientTypeWeb => 'Peramban web';

  @override
  String get pairClientTypeDesktop => 'Aplikasi desktop';

  @override
  String get pairClientTypePhone => 'Ponsel';

  @override
  String get pairAction => 'Pasangkan';

  @override
  String get revoke => 'Cabut';

  @override
  String get pairCredentialsIntro =>
      'Hubungkan klien baru dengan detail ini, atau buka tautannya di klien tersebut.';

  @override
  String get pairLinkLabel => 'Tautan';

  @override
  String get pairScanQr =>
      'Pindai kode QR ini dengan kamera ponsel untuk memasangkannya.';

  @override
  String get pairServerUnreachableTitle => 'Tidak dapat dijangkau';

  @override
  String get pairServerUnreachable =>
      'Perangkat lain tidak dapat menjangkau server ini secara langsung, jadi klien baru tidak dapat terhubung. Atur URL publik server untuk memasangkan klien lain.';

  @override
  String get serverSetupTitle => 'Bagaimana Control Center harus dijalankan?';

  @override
  String get serverSetupSubtitle =>
      'Control Center memerlukan server yang menyimpan data Anda. Jalankan di dalam aplikasi ini, atau hubungkan ke instance yang berjalan di tempat lain.';

  @override
  String get serverSetupRunLocal => 'Jalankan di aplikasi ini';

  @override
  String get serverSetupConnect => 'Hubungkan';

  @override
  String get serverSetupInvalidUrl =>
      'Masukkan URL server ws:// atau wss:// yang valid.';

  @override
  String get serverSetupCouldNotConnect => 'Tidak dapat terhubung';

  @override
  String get serverSetupErrorUnreachable =>
      'Tidak dapat menjangkau server. Pastikan server berjalan dan perangkat ini dapat menjangkaunya (jaringan yang sama atau relay).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'Identitas server tidak cocok dengan yang tersimpan di perangkat ini. Jika server diinstal ulang atau direset, hapus server tersimpan lalu pasangkan lagi.';

  @override
  String get serverSetupErrorAuthRejected =>
      'Server menolak perangkat ini. Pastikan kunci pemasangan dan ID perangkat cocok dengan yang dikeluarkan server.';

  @override
  String get serverSetupErrorInviteRejected =>
      'Kode undangan tidak valid atau sudah kedaluwarsa. Minta yang baru.';

  @override
  String get serverSetupErrorGeneric =>
      'Terjadi kesalahan saat menghubungkan. Perluas detail teknis di bawah untuk informasi selengkapnya.';

  @override
  String get serverSetupErrorDetails => 'Detail teknis';

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
  String get calendarCollapseAllDay => 'Ciutkan acara sepanjang hari';

  @override
  String get calendarExpandAllDay => 'Bentangkan acara sepanjang hari';

  @override
  String get calendarViewMonth => 'Bulan';

  @override
  String get calendarViewWeek => 'Minggu';

  @override
  String get calendarViewAgenda => 'Agenda';

  @override
  String get calendarConnectGoogle => 'Hubungkan Google Calendar';

  @override
  String get calendarConnectDescription =>
      'Sinkronkan Google Calendar untuk melihat acara di sini dan mendapat peringatan sebelum rapat dimulai.';

  @override
  String get calendarDisconnect => 'Putuskan';

  @override
  String get calendarReconnect => 'Hubungkan ulang';

  @override
  String get calendarEmptyNoEvents => 'Tidak ada acara di rentang ini';

  @override
  String get calendarStartRecording => 'Mulai rekaman';

  @override
  String get calendarStartRecordingAndLink => 'Mulai rekaman & tautkan';

  @override
  String get calendarJoinMeet => 'Gabung rapat';

  @override
  String get calendarFromCalendar => 'Dari kalender';

  @override
  String get calendarLinkedMeeting => 'Rapat tertaut';

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
  String get calendarNextPeriod => 'Berikutnya';

  @override
  String calendarLastSynced(String time) {
    return 'Disinkronkan $time';
  }

  @override
  String get calendarNeverSynced => 'Belum disinkronkan';

  @override
  String get calendarSyncing => 'Menyinkronkan…';

  @override
  String get calendarViewDay => 'Hari';

  @override
  String get calendarShow => 'Tampilkan';

  @override
  String get calendarHide => 'Sembunyikan';

  @override
  String get calendarRsvpGoing => 'Hadir?';

  @override
  String get calendarRsvpYes => 'Ya';

  @override
  String get calendarRsvpNo => 'Tidak';

  @override
  String get calendarRsvpMaybe => 'Mungkin';

  @override
  String get calendarRsvpFailed => 'Tidak dapat memperbarui respons Anda';

  @override
  String get calendarAddAccount => 'Tambah akun kalender';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Hubungkan akun Google untuk menyinkronkan acara ke ruang kerja ini.';

  @override
  String get calendarConnecting => 'Menghubungkan…';

  @override
  String get calendarSyncNow => 'Sinkronkan sekarang';

  @override
  String get calendarNoWorkspace =>
      'Pilih ruang kerja untuk melihat kalendernya';

  @override
  String get calendarConnectError =>
      'Tidak dapat menghubungkan Google Calendar';

  @override
  String get calendarClientIdLabel => 'Client ID';

  @override
  String get calendarClientSecretLabel => 'Client secret';

  @override
  String get calendarConnectCredsHint =>
      'Masukkan client ID dan secret device-code OAuth Google untuk proyek Anda. Server yang menjalankan koneksi dan sinkronisasi — browser Anda tidak pernah menyimpan token.';

  @override
  String get calendarConnectApproveInstruction =>
      'Buka halaman verifikasi di perangkat apa pun, masuk, lalu masukkan kode ini:';

  @override
  String get calendarConnectOpenPage => 'Buka halaman verifikasi';

  @override
  String get calendarConnectWaiting => 'Menunggu persetujuan…';

  @override
  String get calendarConnectDenied => 'Otorisasi ditolak. Silakan coba lagi.';

  @override
  String get calendarConnectExpired => 'Kode kedaluwarsa. Silakan coba lagi.';

  @override
  String get notificationMeetingStartsSoon => 'Rapat segera dimulai';

  @override
  String get notifyMeetingStartsSoon => 'Saat rapat kalender hampir dimulai';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Kalender terputus';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Hubungkan ulang $email untuk melanjutkan sinkronisasi';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Hubungkan ulang kalender Anda untuk melanjutkan sinkronisasi';

  @override
  String get notifyCalendarAuthExpired =>
      'Saat akun kalender perlu dihubungkan ulang';

  @override
  String get notificationRigStatusChanged => 'Pembaruan enclosure';

  @override
  String get notifyRigStatusChanged =>
      'Saat enclosure diambil alih, diklaim kembali, atau gagal';

  @override
  String get notificationRigTakenOver => 'Enclosure diambil alih';

  @override
  String get notificationRigTakenOverBody =>
      'Seseorang mengendalikan mesin; agen dapat menonton tetapi tidak dapat bertindak.';

  @override
  String get notificationRigReleased => 'Kontrol enclosure dilepas';

  @override
  String get notificationRigReleasedBody => 'Agen kembali mengendalikan mesin.';

  @override
  String get notificationRigReclaimed => 'Enclosure diklaim kembali';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'Mesin menganggur, jadi ditutup untuk membebaskan memori.';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'Batas waktunya tercapai dan ditutup.';

  @override
  String get notificationRigFailed => 'Enclosure gagal';

  @override
  String get notificationRigFailedBody =>
      'Hypervisor di bawahnya mati. Buka kembali mesin untuk melanjutkan.';

  @override
  String get calendarAlertLeadTime => 'Waktu jeda peringatan';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'Berapa lama sebelum rapat Anda diberi peringatan';

  @override
  String calendarConnectedAs(String email) {
    return 'Terhubung sebagai $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count tamu';
  }

  @override
  String get calendarEventLabel => 'Acara';

  @override
  String get calendarRecurring => 'Acara berulang';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Penyelenggara';

  @override
  String get calendarYou => 'Anda';

  @override
  String get calendarShowFewer => 'Tampilkan lebih sedikit';

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
    return '$count menit';
  }

  @override
  String get openInEditorPrompt => 'Buka di editor mana?';

  @override
  String get ideNotInstalled => 'Tidak terpasang';

  @override
  String openInIde(String editor) {
    return 'Buka di $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'Tidak dapat membuka $editor: $error';
  }

  @override
  String get profileSearchHint => 'Cari pull request…';

  @override
  String get stopAgentRun => 'Hentikan run';

  @override
  String get stopAgentRunConfirm =>
      'Hentikan run ini? Pekerjaan yang sedang berjalan akan hilang.';

  @override
  String get inProgress => 'Sedang berjalan';

  @override
  String get drafts => 'Draf';

  @override
  String get sortOldest => 'Terlama';

  @override
  String get sortLargest => 'Terbesar';

  @override
  String get prFilterTooltip => 'Filter';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filter aktif',
      one: '1 filter aktif',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'Tambah filter…';

  @override
  String get prFilterFieldHint => 'Filter…';

  @override
  String get prFilterCategoryStatus => 'Status';

  @override
  String get prFilterCategoryAuthor => 'Penulis';

  @override
  String get prFilterCategoryReviewer => 'Reviewer';

  @override
  String get prFilterCategoryContent => 'Konten';

  @override
  String get prFilterCategoryRepoOwner => 'Pemilik repositori';

  @override
  String get prFilterCategoryRepoName => 'Nama repositori';

  @override
  String get prFilterCategoryOpenedDate => 'Tanggal dibuka';

  @override
  String get prFilterCategoryUpdatedDate => 'Tanggal diperbarui';

  @override
  String get prFilterQuickToReview => 'Cepat ditinjau';

  @override
  String get prFilterClearAll => 'Hapus filter';

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
      other: '$count opsi tidak cocok dengan pull request mana pun',
      one: '1 opsi tidak cocok dengan pull request mana pun',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'Judul atau isi mengandung…';

  @override
  String get prFilterNoOptions => 'Tidak ada opsi yang cocok';

  @override
  String get prFilterChipIs => 'adalah';

  @override
  String get prFilterChipIsAnyOf => 'salah satu dari';

  @override
  String get prFilterChipContains => 'mengandung';

  @override
  String get prFilterChipSince => 'sejak';

  @override
  String get prFilterAddFilterButton => 'Tambah filter';

  @override
  String prFilterClearCategory(String category) {
    return 'Hapus filter $category';
  }

  @override
  String get prFilterCurrentUser => 'Pengguna saat ini';

  @override
  String get prStatusDraft => 'Draf';

  @override
  String get prStatusOpen => 'Terbuka';

  @override
  String get prStatusInReview => 'Sedang ditinjau';

  @override
  String get prStatusChangesRequested => 'Perubahan diminta';

  @override
  String get prStatusApproved => 'Disetujui';

  @override
  String get prStatusMerged => 'Digabung';

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
  String get prDisplayOptions => 'Opsi tampilan';

  @override
  String get prDisplayGrouping => 'Pengelompokan';

  @override
  String get prDisplayOrdering => 'Urutan';

  @override
  String get prDisplayShowDrafts => 'Tampilkan draf';

  @override
  String get prDisplayMergedWindow => 'Jendela digabung';

  @override
  String get prDisplayMergedWindowDay => '1 hari terakhir';

  @override
  String get prDisplayMergedWindowWeek => '1 minggu terakhir';

  @override
  String get prDisplayMergedWindowMonth => '1 bulan terakhir';

  @override
  String get prDisplayProperties => 'Properti tampilan';

  @override
  String get prGroupingRepository => 'Repositori';

  @override
  String get prGroupingAuthor => 'Penulis';

  @override
  String get prGroupingStatus => 'Status';

  @override
  String get prGroupingNone => 'Tanpa pengelompokan';

  @override
  String get prPropertyRepository => 'Repositori';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'Branch';

  @override
  String get prPropertyUpdated => 'Diperbarui';

  @override
  String get prPropertyAuthor => 'Penulis';

  @override
  String get prPropertyChecks => 'Pemeriksaan';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'Komentar';

  @override
  String get keybindingOpenFilterMenu => 'Buka menu filter';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'Buka menu filter pull request';

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
  String get kbMove => 'pindah';

  @override
  String get kbTabs => 'tab';

  @override
  String get kbSearch => 'cari';

  @override
  String get kbViewed => 'dilihat';

  @override
  String get kbCollapse => 'ciutkan';

  @override
  String get appearance => 'Tampilan';

  @override
  String get appearanceSettingsDescription => 'Tema, bahasa, dan tipografi.';

  @override
  String get notificationsSettingsDescription =>
      'Pilih peristiwa agen dan ruang kerja yang memberi notifikasi.';

  @override
  String get advanced => 'Lanjutan';

  @override
  String get accounts => 'Akun';

  @override
  String get mcpServers => 'Server MCP';

  @override
  String get mcpServersSettingsDescription =>
      'Server MCP bawaan dan server MCP eksternal.';

  @override
  String get remoteControlAndDevices => 'Kontrol jarak jauh & perangkat';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'Pasangkan ponsel dan konfigurasi server kontrol jarak jauh.';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'Model ucapan dan diarisasi yang dihosting server ini.';

  @override
  String get needsSetupLabel => 'Perlu disiapkan';

  @override
  String get collapseSidebar => 'Ciutkan bilah sisi';

  @override
  String get expandSidebar => 'Bentangkan bilah sisi';

  @override
  String get filterSpacesHint => 'Filter ruang';

  @override
  String noSpacesMatch(String query) {
    return 'Tidak ada ruang yang cocok dengan \"$query\"';
  }

  @override
  String get privacy => 'Privasi';

  @override
  String get sendDiffContentTitle => 'Kirim konten diff ke adapter AI';

  @override
  String get diffSharingOnSubtitle =>
      'Baris diff mentah disertakan dalam prompt agen untuk tinjauan lebih mendalam.';

  @override
  String get diffSharingOffSubtitle =>
      'Agen hanya memakai metadata terstruktur (jalur file, nomor baris, deskripsi PR); kode mentah tidak keluar dari aplikasi.';

  @override
  String get errorReportingTitle => 'Bagikan laporan crash';

  @override
  String get errorReportingOnSubtitle =>
      'Diagnostik crash, error, dan performa dikirim untuk membantu memperbaiki bug (hanya build rilis).';

  @override
  String get errorReportingOffSubtitle =>
      'Diagnostik nonaktif. Tidak ada laporan crash atau error yang dikirim.';

  @override
  String get onboardingDiagnosticsTitle => 'Bantu tingkatkan Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Kirim diagnostik crash, error, dan performa agar kami bisa memperbaiki masalah lebih cepat (hanya build rilis). Anda dapat mengubah ini kapan saja di Pengaturan → Privasi.';

  @override
  String get blocked => 'Diblokir';

  @override
  String get idle => 'Menganggur';

  @override
  String get noRunsYet => 'Belum ada run';

  @override
  String get copyPath => 'Salin jalur';

  @override
  String get copyRelativePath => 'Salin jalur relatif';

  @override
  String get nameRequired => 'Nama wajib diisi';

  @override
  String get import => 'Impor';

  @override
  String get noMatchingAgents => 'Tidak ada agen yang cocok dengan filter Anda';

  @override
  String watchVideoOn(String provider) {
    return 'Tonton video di $provider';
  }

  @override
  String get branchTemplate => 'Templat nama branch';

  @override
  String get branchTemplateDescription =>
      'Pola untuk branch yang dibuat saat tiket dimulai di pohon kerja terisolasi.';

  @override
  String branchTemplatePreview(String example) {
    return 'Contoh: $example';
  }

  @override
  String get deletePipelineRun => 'Hapus run pipeline';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Hapus run \"$template\" ini? Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Gagal menghapus run pipeline: $error';
  }

  @override
  String get deleteTicket => 'Hapus tiket';

  @override
  String deleteTicketConfirm(String title) {
    return 'Hapus \"$title\"? Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Gagal menghapus tiket: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return 'Hapus \"$name\"? Repositori tertaut di disk tidak diubah.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Gagal menghapus ruang kerja: $error';
  }

  @override
  String get indexCode => 'Indekskan kode';

  @override
  String get indexNoGrammars => 'Grammar kode belum terpasang';

  @override
  String get indexFailed => 'Pengindeksan gagal';

  @override
  String indexedSymbolsCount(int count) {
    return '$count simbol terindeks';
  }

  @override
  String get nodeConfigAdvanced => 'Lanjutan';

  @override
  String get nodeConfigReducer => 'Reducer';

  @override
  String get nodeConfigReducerHelp =>
      'Cara menggabungkan jika kunci output ini sudah memiliki nilai';

  @override
  String get nodeConfigTimeoutMs => 'Batas waktu (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Percobaan ulang';

  @override
  String get nodeConfigContinueOnFail => 'Lanjutkan jika langkah ini gagal';

  @override
  String get nodeConfigTeamId => 'ID tim';

  @override
  String get nodeConfigDispatchMode => 'Mode dispatch';

  @override
  String get nodeConfigOutputSchema => 'Skema output (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'JSON Schema yang harus dipenuhi output langkah';

  @override
  String get diffLineDisplay => 'Baris panjang di diff';

  @override
  String get diffLineDisplayDescription =>
      'Bungkus baris panjang atau geser secara horizontal';

  @override
  String get diffLineWrap => 'Bungkus';

  @override
  String get diffLineScroll => 'Geser horizontal';

  @override
  String get actions => 'Tindakan';

  @override
  String get activate => 'Aktifkan';

  @override
  String get activity => 'Aktivitas';

  @override
  String get activityLabel => 'AKTIVITAS';

  @override
  String get activitySearchHint => 'Cari aktivitas';

  @override
  String get activityNoMatches =>
      'Tidak ada aktivitas yang cocok dengan filter';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end dari $total';
  }

  @override
  String get activityPreviousPage => 'Halaman sebelumnya';

  @override
  String get activityNextPage => 'Halaman berikutnya';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'Hapus filter';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return 'Negara $country';
  }

  @override
  String get activitySavedWorkspaceLogo => 'Menyimpan logo ruang kerja';

  @override
  String activityVerbCreated(String target) {
    return 'Membuat $target';
  }

  @override
  String activityVerbUpdated(String target) {
    return 'Memperbarui $target';
  }

  @override
  String activityVerbDeleted(String target) {
    return 'Menghapus $target';
  }

  @override
  String activityVerbAdded(String target) {
    return 'Menambahkan $target';
  }

  @override
  String activityVerbRemoved(String target) {
    return 'Mengeluarkan $target';
  }

  @override
  String activityVerbInvited(String target) {
    return 'Mengundang $target';
  }

  @override
  String activityVerbChanged(String target) {
    return 'Mengubah $target';
  }

  @override
  String activityVerbStarted(String target) {
    return 'Memulai $target';
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
  String get activityTargetAgent => 'agen';

  @override
  String get activityTargetTicket => 'tiket';

  @override
  String get activityTargetWorkspace => 'ruang kerja';

  @override
  String get activityTargetRepository => 'repositori';

  @override
  String get activityTargetMember => 'anggota';

  @override
  String get activityTargetInvite => 'undangan';

  @override
  String get activityTargetSpace => 'ruang';

  @override
  String get activityTargetMessage => 'pesan';

  @override
  String get activityTargetCache => 'cache';

  @override
  String get activityTargetFile => 'file';

  @override
  String get activityTargetPipeline => 'pipeline';

  @override
  String get activityTargetTemplate => 'templat';

  @override
  String get activityTargetProvider => 'penyedia';

  @override
  String get activityTargetModel => 'model';

  @override
  String get activityTargetSkill => 'skill';

  @override
  String get activityTargetTodo => 'to-do';

  @override
  String get activityTargetMeeting => 'rapat';

  @override
  String get activityTargetProject => 'proyek';

  @override
  String get activityTargetTeam => 'tim';

  @override
  String get activityTargetDevice => 'perangkat';

  @override
  String get activityTargetPreference => 'preferensi';

  @override
  String get activityTargetBudget => 'anggaran';

  @override
  String activityVerbApproved(String target) {
    return 'Menyetujui $target';
  }

  @override
  String activityVerbArchived(String target) {
    return 'Mengarsipkan $target';
  }

  @override
  String activityVerbAssigned(String target) {
    return 'Menugaskan $target';
  }

  @override
  String activityVerbBackedUp(String target) {
    return 'Mencadangkan $target';
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
    return 'Melakukan commit $target';
  }

  @override
  String activityVerbCompacted(String target) {
    return 'Memadatkan $target';
  }

  @override
  String activityVerbCompleted(String target) {
    return 'Menyelesaikan $target';
  }

  @override
  String activityVerbConnected(String target) {
    return 'Menghubungkan $target';
  }

  @override
  String activityVerbContinued(String target) {
    return 'Melanjutkan $target';
  }

  @override
  String activityVerbDisconnected(String target) {
    return 'Memutus $target';
  }

  @override
  String activityVerbDispatched(String target) {
    return 'Mendispatch $target';
  }

  @override
  String activityVerbDrained(String target) {
    return 'Menguras $target';
  }

  @override
  String activityVerbEnrolled(String target) {
    return 'Mendaftarkan $target';
  }

  @override
  String activityVerbEstimated(String target) {
    return 'Mengestimasi $target';
  }

  @override
  String activityVerbImported(String target) {
    return 'Mengimpor $target';
  }

  @override
  String activityVerbInstalled(String target) {
    return 'Menginstal $target';
  }

  @override
  String activityVerbKilled(String target) {
    return 'Menghentikan $target';
  }

  @override
  String activityVerbMarked(String target) {
    return 'Menandai $target';
  }

  @override
  String activityVerbMerged(String target) {
    return 'Menggabungkan $target';
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
    return 'Melakukan poll $target';
  }

  @override
  String activityVerbPrepared(String target) {
    return 'Menyiapkan $target';
  }

  @override
  String activityVerbProcessed(String target) {
    return 'Memproses $target';
  }

  @override
  String activityVerbPublished(String target) {
    return 'Memublikasikan $target';
  }

  @override
  String activityVerbRefined(String target) {
    return 'Menyempurnakan $target';
  }

  @override
  String activityVerbRefreshed(String target) {
    return 'Menyegarkan $target';
  }

  @override
  String activityVerbRegistered(String target) {
    return 'Meregistrasikan $target';
  }

  @override
  String activityVerbRenamed(String target) {
    return 'Mengganti nama $target';
  }

  @override
  String activityVerbReordered(String target) {
    return 'Mengurutkan ulang $target';
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
    return 'Melanjutkan kembali $target';
  }

  @override
  String activityVerbRetried(String target) {
    return 'Mencoba ulang $target';
  }

  @override
  String activityVerbReverted(String target) {
    return 'Mengembalikan $target';
  }

  @override
  String activityVerbReviewed(String target) {
    return 'Meninjau $target';
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
    return 'Mengirim $target';
  }

  @override
  String activityVerbStaged(String target) {
    return 'Men-stage $target';
  }

  @override
  String activityVerbSteered(String target) {
    return 'Mengarahkan $target';
  }

  @override
  String activityVerbSubmitted(String target) {
    return 'Mengajukan $target';
  }

  @override
  String activityVerbSynced(String target) {
    return 'Menyinkronkan $target';
  }

  @override
  String activityVerbToggled(String target) {
    return 'Mengalihkan $target';
  }

  @override
  String activityVerbUninstalled(String target) {
    return 'Mencopot $target';
  }

  @override
  String activityVerbUnstaged(String target) {
    return 'Membatalkan stage $target';
  }

  @override
  String get activityTargetActionPolicy => 'kebijakan tindakan';

  @override
  String get activityTargetGoalRun => 'eksekusi goal';

  @override
  String get activityTargetRunLog => 'log eksekusi';

  @override
  String get activityTargetWorkingMemory => 'memori kerja';

  @override
  String get activityTargetRoutingPolicy => 'kebijakan routing';

  @override
  String get activityTargetAutonomy => 'otonomi';

  @override
  String get activityTargetCalendar => 'kalender';

  @override
  String get activityTargetChecker => 'pemeriksa';

  @override
  String get activityTargetEditor => 'editor';

  @override
  String get activityTargetConfirmation => 'konfirmasi';

  @override
  String get activityTargetTunnel => 'tunnel';

  @override
  String get activityTargetConversation => 'percakapan';

  @override
  String get activityTargetCredentials => 'kredensial';

  @override
  String get activityTargetDictation => 'dikte';

  @override
  String get activityTargetAgentRun => 'eksekusi agen';

  @override
  String get activityTargetEvalSuite => 'suite eval';

  @override
  String get activityTargetWorker => 'worker';

  @override
  String get activityTargetWorktree => 'pohon kerja';

  @override
  String get activityTargetMcpServer => 'server MCP';

  @override
  String get activityTargetMemoryAccessGrant => 'izin akses memori';

  @override
  String get activityTargetMemoryDomain => 'domain memori';

  @override
  String get activityTargetMemoryFact => 'fakta memori';

  @override
  String get activityTargetMemoryPolicy => 'kebijakan memori';

  @override
  String get activityTargetFeed => 'feed';

  @override
  String get activityTargetNote => 'catatan';

  @override
  String get activityTargetOrchestration => 'orkestrasi';

  @override
  String get activityTargetPipelineRun => 'eksekusi pipeline';

  @override
  String get activityTargetPipelineTrigger => 'pemicu pipeline';

  @override
  String get activityTargetPlan => 'rencana';

  @override
  String get activityTargetPlaybook => 'playbook';

  @override
  String get activityTargetPullRequest => 'pull request';

  @override
  String get activityTargetReview => 'review';

  @override
  String get activityTargetProcess => 'proses';

  @override
  String get activityTargetProviderPolicy => 'kebijakan penyedia';

  @override
  String get activityTargetReaction => 'reaksi';

  @override
  String get activityTargetReviewSpace => 'ruang review';

  @override
  String get activityTargetReviewStudio => 'studio review';

  @override
  String get activityTargetServerData => 'data server';

  @override
  String get activityTargetSoundscape => 'soundscape';

  @override
  String get activityTargetSession => 'sesi';

  @override
  String get activityTargetTerminal => 'terminal';

  @override
  String get activityTargetTicketLink => 'tautan tiket';

  @override
  String get activityTargetTicketSync => 'sinkronisasi tiket';

  @override
  String get activityTargetProfile => 'profil';

  @override
  String get activityTargetVoiceProfile => 'profil suara';

  @override
  String get activityTargetWeather => 'prakiraan cuaca';

  @override
  String get activityTargetWorkProduct => 'produk kerja';

  @override
  String get activityChangedMemberRole => 'Mengubah peran anggota';

  @override
  String get activityChangedMemberRepoAccess =>
      'Mengubah akses repositori anggota';

  @override
  String get activityUpdatedGitHubToken => 'Memperbarui token GitHub';

  @override
  String get activityRefreshedWeather => 'Menyegarkan prakiraan cuaca';

  @override
  String get activitySetWeatherLocation => 'Mengatur lokasi cuaca';

  @override
  String get activityClearedWeatherLocation => 'Menghapus lokasi cuaca';

  @override
  String get activityMarkedAllArticlesRead =>
      'Menandai semua artikel sebagai sudah dibaca';

  @override
  String get activityMarkedArticleRead =>
      'Menandai artikel sebagai sudah dibaca';

  @override
  String get activityUpdatedSavedArticle => 'Memperbarui artikel tersimpan';

  @override
  String get activityTookOverSession => 'Mengambil alih sesi';

  @override
  String get activityHandedBackSession => 'Mengembalikan sesi';

  @override
  String get activityCommittedAndPushed => 'Melakukan commit dan push';

  @override
  String get activityBackedUpServer => 'Mencadangkan data server';

  @override
  String get activityMarkedSpaceRead => 'Menandai ruang sebagai sudah dibaca';

  @override
  String get activityRespondedToInvitation => 'Merespons undangan acara';

  @override
  String get activityStartedCalendarConnect => 'Memulai koneksi kalender';

  @override
  String get activityDisconnectedCalendar => 'Memutuskan kalender';

  @override
  String get activityMarkedFileViewed => 'Menandai file sebagai sudah dilihat';

  @override
  String get activityRespondedToApproval => 'Merespons permintaan persetujuan';

  @override
  String get activityChangedTunnel => 'Mengubah pengaturan tunnel';

  @override
  String get activitySentMessageToAgent => 'Mengirim pesan ke agen';

  @override
  String get activityOpenedReviewSpace => 'Membuka ruang tinjauan';

  @override
  String get activityOpenedStandingConversation => 'Membuka percakapan tetap';

  @override
  String get activityStartedRecording => 'Memulai rekaman';

  @override
  String get activityStoppedRecording => 'Menghentikan rekaman';

  @override
  String get activityToggledMcpServer => 'Mengalihkan server MCP';

  @override
  String get activityUpdatedMcpToken => 'Memperbarui token MCP';

  @override
  String get activitySavedApiKey => 'Menyimpan kunci API';

  @override
  String get activityRemovedProviderCredential =>
      'Menghapus kredensial penyedia';

  @override
  String get activityUpdatedLinkedRepos => 'Memperbarui repositori tertaut';

  @override
  String get activityUnlinkedRepo => 'Melepas tautan repositori';

  @override
  String get activityUpdatedActionItem => 'Memperbarui item tindakan';

  @override
  String adRulesCount(int count) {
    return '$count aturan iklan';
  }

  @override
  String get adapter => 'Adapter';

  @override
  String get adapterLabel => 'Adapter';

  @override
  String get adapters => 'Adapter';

  @override
  String get adaptersAutoDetected =>
      'Runner agen yang terdeteksi otomatis di mesin ini. Instal alat CLI yang belum ada untuk mengaktifkan runner tambahan.';

  @override
  String get add => 'Tambah';

  @override
  String get addAComment => 'Tambah komentar';

  @override
  String get addAReaction => 'Tambah reaksi';

  @override
  String get addASuggestion => 'Tambah saran';

  @override
  String get addAgents => 'Tambah agen';

  @override
  String get addEmoji => 'Tambah emoji';

  @override
  String get addFeed => 'Tambah feed';

  @override
  String get addressBarHint => 'Masukkan URL';

  @override
  String get addFromFile => 'Tambah dari file';

  @override
  String get addGif => 'Tambah GIF';

  @override
  String get addGithubRepoPrompt =>
      'Tambahkan setidaknya satu repositori GitHub untuk melihat pull request';

  @override
  String get addLocalCheckoutDescription =>
      'Tambahkan checkout lokal untuk mulai menargetkannya dari ruang kerja ini.';

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
      'Telusuri folder di mesin yang menjalankan server dan pilih checkout git yang akan didaftarkan.';

  @override
  String get selectThisFolder => 'Pilih folder ini';

  @override
  String get deselectThisFolder => 'Batalkan pilihan folder ini';

  @override
  String get goUp => 'Naik';

  @override
  String get noSubfoldersHere => 'Tidak ada subfolder di sini';

  @override
  String get notAGitRepository => 'Folder ini bukan repositori git.';

  @override
  String get addToken => 'Tambah token';

  @override
  String get addWorkspace => 'Tambah ruang kerja';

  @override
  String get addWorkspaceEllipsis => 'Tambah ruang kerja…';

  @override
  String get added => 'Ditambahkan';

  @override
  String get addingEllipsis => 'Menambahkan…';

  @override
  String get advancedLabel => 'Lanjutan';

  @override
  String get agent => 'Agen';

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
  String get agentMdPath => 'Jalur MD agen';

  @override
  String get agentName => 'Nama agen';

  @override
  String get agentTitle => 'Judul agen';

  @override
  String get agentUpdated => 'Agen diperbarui.';

  @override
  String get agents => 'Agen';

  @override
  String get agentsMentionSection => 'Agen';

  @override
  String get usersMentionSection => 'Orang';

  @override
  String get ticketsMentionSection => 'Tiket';

  @override
  String get pullRequestsMentionSection => 'Pull request';

  @override
  String get meetingsMentionSection => 'Rapat';

  @override
  String get entityRefTicketFallback => 'Tiket';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'Rapat';

  @override
  String get aiReview => 'Tinjauan AI';

  @override
  String get all => 'Semua';

  @override
  String get allAgentsAlreadyInSpace => 'Semua agen sudah ada di ruang ini.';

  @override
  String get allCommits => 'Semua commit';

  @override
  String get allSources => 'Semua sumber';

  @override
  String get allow => 'Izinkan';

  @override
  String get allowGitPush => 'Izinkan git push';

  @override
  String get allowGithubApi => 'Izinkan panggilan API GitHub';

  @override
  String get allowNetwork => 'Izinkan akses jaringan umum';

  @override
  String get apiKeys => 'Kunci API';

  @override
  String get appFont => 'Font aplikasi';

  @override
  String get appLogLevelDebugDescription =>
      'Menambahkan jejak terperinci — untuk pengembangan.';

  @override
  String get appLogLevelDebugLabel => 'Debug';

  @override
  String get appLogLevelErrorDescription =>
      'Hanya error dan exception yang tidak terduga.';

  @override
  String get appLogLevelErrorLabel => 'Error';

  @override
  String get appLogLevelInfoDescription =>
      'Menambahkan pesan siklus hidup dan status.';

  @override
  String get appLogLevelInfoLabel => 'Info';

  @override
  String get appLogLevelNoneDescription =>
      'Tidak ada output konsol sama sekali.';

  @override
  String get appLogLevelNoneLabel => 'Tidak ada';

  @override
  String get appLogLevelVerboseDescription =>
      'Semuanya. Sangat ramai — hanya untuk debugging.';

  @override
  String get appLogLevelVerboseLabel => 'Verbose';

  @override
  String get appLogLevelWarningDescription =>
      'Menambahkan peringatan dan masalah yang dapat dipulihkan.';

  @override
  String get appLogLevelWarningLabel => 'Peringatan';

  @override
  String get appearanceLanguage => 'Tampilan & bahasa';

  @override
  String get apply => 'Terapkan';

  @override
  String get approve => 'Setujui';

  @override
  String get agentApprovalRequired => 'Perlu persetujuan';

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
  String get approved => 'Disetujui';

  @override
  String get articleNoun => 'Artikel';

  @override
  String get articlesSubscribed => 'Artikel dari feed yang Anda langgan.';

  @override
  String get askAi => 'Tanya AI';

  @override
  String get askAiReviewDescription => 'Minta AI meninjau PR ini';

  @override
  String get assignees => 'Penerima tugas';

  @override
  String get attachImage => 'Lampirkan gambar';

  @override
  String get attachedAgents => 'Agen terlampir';

  @override
  String get audioInput => 'Input audio';

  @override
  String get audioOutput => 'Output audio';

  @override
  String get authenticationToken => 'Token autentikasi';

  @override
  String authoredByLabel(String role) {
    return 'Oleh: $role';
  }

  @override
  String get autoRecommended => 'Otomatis (disarankan)';

  @override
  String get available => 'Tersedia';

  @override
  String get awaitingYourReview => 'Menunggu tinjauan Anda';

  @override
  String get back => 'Kembali';

  @override
  String get backLabel => 'Kembali';

  @override
  String get backend => 'Backend';

  @override
  String get blockAdsTrackers => 'Blokir iklan, pelacak & banner cookie';

  @override
  String get blocking => 'Memblokir';

  @override
  String get bookmarkLabel => 'Markah';

  @override
  String get briefDescription => 'Deskripsi singkat';

  @override
  String get bugLabel => 'BUG';

  @override
  String get bundledDefaultsNeverUpdated =>
      'Default bawaan — tidak pernah diperbarui';

  @override
  String get cancel => 'Batal';

  @override
  String get cancelEdit => 'Batalkan pengeditan';

  @override
  String get categoryCreation => 'Pembuatan';

  @override
  String get categoryEditing => 'Pengeditan';

  @override
  String get categoryNavigation => 'Navigasi';

  @override
  String get categorySystem => 'Sistem';

  @override
  String get categoryView => 'Tampilan kategori';

  @override
  String get change => 'Ubah';

  @override
  String get changesRequested => 'Perubahan diminta';

  @override
  String get spacesMentionSection => 'Spaces';

  @override
  String get checkForUpdates => 'Periksa pembaruan';

  @override
  String get checking => 'Memeriksa';

  @override
  String get checkingEllipsis => 'Memeriksa…';

  @override
  String get chooseAppFont => 'Pilih font aplikasi';

  @override
  String get chooseCodeFont => 'Pilih font kode';

  @override
  String get chooseRunner => 'Pilih runner agen Anda.';

  @override
  String get clear => 'Hapus';

  @override
  String get clickToRetry => 'Klik untuk mencoba lagi';

  @override
  String get close => 'Tutup';

  @override
  String get closeEsc => 'Tutup (Esc)';

  @override
  String get closeReader => 'Tutup pembaca';

  @override
  String get closed => 'Ditutup';

  @override
  String get codeFont => 'Font kode';

  @override
  String get codeFontLigatures => 'Ligatur font kode';

  @override
  String get codeFontLigaturesDescription =>
      'Render ligatur pemrograman (=>, !=, ->) sebagai glif gabungan di kode dan diff';

  @override
  String get collapse => 'Ciutkan';

  @override
  String get commandPalette => 'Palet perintah';

  @override
  String get commandPaletteOrgMembers => 'Anggota organisasi';

  @override
  String get commandPaletteBrowseTeam => 'Jelajahi tim';

  @override
  String get commandPaletteBrowseTeamDesc => 'Lihat semua anggota organisasi';

  @override
  String get compactDone =>
      'Percakapan dipadatkan. Riwayat sebelumnya digabung ke dalam ringkasan.';

  @override
  String get compactNothing =>
      'Belum ada yang dapat dipadatkan. Percakapan masih singkat.';

  @override
  String get compactBusy =>
      'Agen masih bekerja. Padatkan setelah giliran selesai.';

  @override
  String get compactUnavailable => 'Pemadatan tidak tersedia di server ini.';

  @override
  String get commandsMentionSection => 'Perintah';

  @override
  String get comment => 'Komentar';

  @override
  String get commentOnThisFile => 'Komentari file ini';

  @override
  String get commented => 'Dikomentari';

  @override
  String get commits => 'Commit';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Menampilkan $loaded dari $total commit terbaru';
  }

  @override
  String get prCloneProgressCloningTitle => 'Mengkloning repositori';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'PR ini mengubah $fileCount file, yang melebihi batas API GitHub. Mengkloning repositori secara lokal…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'PR ini melebihi batas file API GitHub. Mengkloning repositori secara lokal…';

  @override
  String get prCloneProgressFetchingTitle => 'Mengambil ref PR';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Mengambil cabang dasar dan ref head PR…';

  @override
  String get prCloneProgressComputingTitle => 'Menghitung diff';

  @override
  String get prCloneProgressComputingSubtitle =>
      'Menjalankan git diff secara lokal…';

  @override
  String get prCloneProgressErrorTitle => 'Gagal memuat diff';

  @override
  String get prCloneProgressErrorSubtitle =>
      'Terjadi error saat mengkloning atau menghitung diff. Coba muat ulang.';

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
      'Konfigurasikan identitas agen, prompt, skill, dan lihat run.';

  @override
  String get configureDefaultRunners =>
      'Konfigurasikan adapter dan model untuk Spaces baru dan pembuatan judul.';

  @override
  String get configuredLabel => 'Terkonfigurasi.';

  @override
  String get confirmedBy => 'Dikonfirmasi oleh';

  @override
  String get consensus => 'Konsensus';

  @override
  String get contentHint => 'Yang harus diingat';

  @override
  String get contentLabel => 'Konten';

  @override
  String get contentMarkdown => 'Konten (Markdown)';

  @override
  String get contextWindowSize => 'Ukuran jendela konteks';

  @override
  String modelContextChip(String size) {
    return 'Model · $size';
  }

  @override
  String get continueLabel => 'Lanjutkan';

  @override
  String get conversationMode => 'Mode';

  @override
  String cookieRulesCount(int count) {
    return '$count aturan cookie';
  }

  @override
  String get copied => 'Disalin!';

  @override
  String get copy => 'Salin';

  @override
  String get copyAddress => 'Salin alamat';

  @override
  String get copyBaseBranchTooltip => 'Salin nama cabang dasar';

  @override
  String get copyHeadBranchTooltip => 'Salin nama cabang head';

  @override
  String couldNotListDevices(String error) {
    return 'Tidak dapat menampilkan daftar perangkat: $error';
  }

  @override
  String get create => 'Buat';

  @override
  String get createOrSelectWorkspace =>
      'Buat atau pilih ruang kerja sebelum menambahkan repositori.';

  @override
  String get createPullRequest => 'Buat pull request';

  @override
  String get createdByMe => 'Dibuat oleh saya';

  @override
  String createdLabel(String date) {
    return 'Dibuat: $date';
  }

  @override
  String get currentParticipants => 'Peserta saat ini';

  @override
  String get customCapabilitiesDescription => 'Deskripsi kemampuan kustom';

  @override
  String get customSystemPrompt => 'Prompt sistem kustom untuk agen ini...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari lalu',
      one: '1 hari lalu',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Nonaktifkan';

  @override
  String get defaultCapabilities => 'Kemampuan default · ruang baru';

  @override
  String get defaultChat => 'Chat default';

  @override
  String get defaultRunners => 'Runner default';

  @override
  String get delete => 'Hapus';

  @override
  String get deleteAgent => 'Hapus agen';

  @override
  String deleteAgentConfirm(String name) {
    return 'Hapus \"$name\"? Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get deleteSpace => 'Hapus ruang';

  @override
  String deleteConfirmName(String name) {
    return 'Hapus \"$name\"?';
  }

  @override
  String get archiveConversation => 'Arsipkan percakapan';

  @override
  String get deleteFact => 'Hapus fakta';

  @override
  String get deleteFeedBody =>
      'Ini menghapus feed dan semua artikel yang di-cache. Artikel yang di-bookmark dari feed ini juga akan dihapus.';

  @override
  String deleteFeedConfirm(String name) {
    return 'Hapus \"$name\"?';
  }

  @override
  String get deletePolicy => 'Hapus kebijakan';

  @override
  String get deletePolicyConfirm =>
      'Hapus kebijakan ini? Tindakan ini tidak dapat dibatalkan.';

  @override
  String deleteTopicConfirm(String topic) {
    return 'Hapus \"$topic\"? Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get deleteWorkspace => 'Hapus ruang kerja';

  @override
  String get deny => 'Tolak';

  @override
  String get detailsLabel => 'Detail';

  @override
  String get descriptionLabel => 'Deskripsi';

  @override
  String detectedBackend(String label) {
    return 'Terdeteksi: $label';
  }

  @override
  String get detectedRunners => 'Runner terdeteksi';

  @override
  String get detectingAdapters => 'Mendeteksi adapter…';

  @override
  String get detectingInputDevices => 'Mendeteksi perangkat input…';

  @override
  String detectionFailed(String error) {
    return 'Deteksi gagal: $error';
  }

  @override
  String get disabled => 'Nonaktif';

  @override
  String get discover => 'Jelajahi';

  @override
  String get dismissed => 'Diabaikan';

  @override
  String get domainHint => 'mis. api-performance';

  @override
  String get domainLabel => 'Domain';

  @override
  String get download => 'Unduh';

  @override
  String get downloadingLabel => 'Mengunduh';

  @override
  String downloadingModel(int pct) {
    return 'Mengunduh model… $pct%';
  }

  @override
  String get draft => 'Draf';

  @override
  String get draftLabel => 'Draf';

  @override
  String get edit => 'Edit';

  @override
  String get edited => 'diedit';

  @override
  String get editMessage => 'Edit pesan';

  @override
  String get deleteMessage => 'Hapus pesan';

  @override
  String get deleteMessageConfirm =>
      'Hapus pesan ini? Tindakan ini tidak dapat dibatalkan.';

  @override
  String get messageDeleted => 'Pesan dihapus';

  @override
  String get searchInConversation => 'Cari dalam percakapan';

  @override
  String get searchMessagesHint => 'Cari pesan…';

  @override
  String get noMessagesFound => 'Tidak ada pesan yang ditemukan';

  @override
  String get editFact => 'Edit fakta';

  @override
  String get editPolicy => 'Edit kebijakan';

  @override
  String get editSuggestedCodeHint => 'Edit kode yang disarankan…';

  @override
  String get editSuggestion => 'Saran edit';

  @override
  String get egArchitect => 'mis. architect';

  @override
  String get egControlCenter => 'mis. control-center';

  @override
  String get egPlatform => 'mis. Platform';

  @override
  String get egSamuelAlev => 'mis. SamuelAlev';

  @override
  String get egSoftwareArchitect => 'mis. Software Architect';

  @override
  String get egTheVerge => 'mis. The Verge';

  @override
  String get egTokenLimit => 'mis. 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Instalasi gagal: $error';
  }

  @override
  String get embeddingInstalled =>
      'Model embedding lokal terpasang. Pencarian hibrid diaktifkan.';

  @override
  String get embeddingModel => 'Model embedding (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Belum terpasang. Pencarian memakai kata kunci saja sampai diaktifkan.';

  @override
  String get embeddingRedownloadBody =>
      'File model yang ada akan dihapus dan diunduh ulang. Pencarian semantik tidak tersedia sampai unduhan selesai.';

  @override
  String get embeddingRemoveBody =>
      'Pencarian semantik akan dinonaktifkan sampai Anda memasangnya lagi. Anda dapat memasangnya kapan saja.';

  @override
  String get speakerDiarization => 'Diarisasi pembicara';

  @override
  String get diarizationModel => 'Model diarisasi';

  @override
  String get diarizationInstalled =>
      'Terpasang — menamai masing-masing pembicara di transkrip rapat';

  @override
  String get diarizationNotInstalled =>
      'Belum terpasang — pembicara rapat tidak akan dipisahkan';

  @override
  String diarizationInstallFailed(String error) {
    return 'Instalasi gagal: $error';
  }

  @override
  String get redownloadDiarizationModel => 'Unduh ulang model diarisasi';

  @override
  String get diarizationRedownloadBody =>
      'Ini menghapus model diarisasi saat ini dan mengunduhnya lagi.';

  @override
  String get removeDiarizationModel => 'Hapus model diarisasi';

  @override
  String get diarizationRemoveBody =>
      'Ini menghapus model diarisasi di perangkat. Transkrip rapat yang sudah dibuat tidak terpengaruh.';

  @override
  String get enableNotifications => 'Aktifkan notifikasi';

  @override
  String get enableSandboxing => 'Aktifkan sandboxing';

  @override
  String get enabled => 'Aktif';

  @override
  String errorCreatingAgent(String error) {
    return 'Gagal membuat agen: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Gagal menghapus agen: $error';
  }

  @override
  String errorWithDetail(String error) {
    return 'Kesalahan: $error';
  }

  @override
  String get expand => 'Perluas';

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
    return '$factCount fakta · $policyCount kebijakan';
  }

  @override
  String get failed => 'Gagal';

  @override
  String failedToDispatch(String error) {
    return 'Gagal mengirim: $error';
  }

  @override
  String get failedToLoad => 'Gagal memuat';

  @override
  String failedToLoadAgents(String error) {
    return 'Gagal memuat agen: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Gagal memuat feed: $error';
  }

  @override
  String get failedToLoadGifs => 'Gagal memuat GIF';

  @override
  String failedToLoadLogs(String error) {
    return 'Gagal memuat log: $error';
  }

  @override
  String get failedToLoadRepos => 'Gagal memuat repositori';

  @override
  String get failedToLoadWorkspaces => 'Gagal memuat ruang kerja';

  @override
  String failedToStartAiReview(String error) {
    return 'Gagal memulai tinjauan AI: $error';
  }

  @override
  String get failedToStartMicTest => 'Gagal memulai tes mikrofon.';

  @override
  String failedToSubmitReview(String error) {
    return 'Gagal mengirim tinjauan: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'Gagal mengunggah $name: $error';
  }

  @override
  String failedWithError(String error) {
    return 'Gagal: $error';
  }

  @override
  String get failure => 'Kegagalan';

  @override
  String get feedAlreadyExists => 'Feed dengan URL ini sudah ada.';

  @override
  String get feedUrlExample => 'mis. https://example.com/feed.xml';

  @override
  String get feedUrlLabel => 'URL feed';

  @override
  String feedsCount(int count) {
    return 'Feed ($count)';
  }

  @override
  String get filesChanged => 'File diubah';

  @override
  String filesCount(int count) {
    return '$count file';
  }

  @override
  String get filesMentionSection => 'File';

  @override
  String get filterAgents => 'Filter agen...';

  @override
  String get filterFilesHint => 'Filter file…';

  @override
  String get filterLists => 'Filter daftar';

  @override
  String get filterSkillsPlaceholder => 'Filter skill…';

  @override
  String get finish => 'Selesai';

  @override
  String get fix => 'Perbaiki';

  @override
  String get forward => 'Maju';

  @override
  String get gatesGithubPatPush =>
      'Membatasi injeksi PAT GitHub. Diperlukan agar agen dapat push.';

  @override
  String get general => 'Umum';

  @override
  String get githubLink => 'Tautan GitHub';

  @override
  String get claudeStatusFetchFailed =>
      'Tidak dapat menjangkau status.claude.com';

  @override
  String get claudeStatusOpenInBrowser => 'Buka status.claude.com';

  @override
  String get githubStatusFetchFailed =>
      'Tidak dapat menjangkau githubstatus.com';

  @override
  String get githubDegradedTitle => 'GitHub melaporkan masalah';

  @override
  String githubDegradedStatusLine(String status) {
    return 'Status GitHub: $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'Status GitHub: $status. Data pull request mungkin kedaluwarsa atau tidak lengkap hingga pulih.';
  }

  @override
  String get githubStatusOpenInBrowser => 'Buka githubstatus.com';

  @override
  String get githubStatusRefresh => 'Segarkan';

  @override
  String githubStatusUpdated(String time) {
    return 'Diperbarui $time';
  }

  @override
  String get kimiStatusFetchFailed =>
      'Tidak dapat menjangkau status.moonshot.cn';

  @override
  String get kimiStatusOpenInBrowser => 'Buka status.moonshot.cn';

  @override
  String get openaiStatusFetchFailed =>
      'Tidak dapat menjangkau status.openai.com';

  @override
  String get openaiStatusOpenInBrowser => 'Buka status.openai.com';

  @override
  String get serviceStatusMaintenance => 'Pemeliharaan';

  @override
  String get serviceStatusMajorIssues => 'Masalah besar';

  @override
  String get serviceStatusMinorIssues => 'Masalah kecil';

  @override
  String get serviceStatusOperational => 'Beroperasi';

  @override
  String get serviceStatusOutage => 'Gangguan';

  @override
  String get serviceStatusTitle => 'Status layanan';

  @override
  String get serviceStatusUnknown => 'Tidak diketahui';

  @override
  String lastChecked(String time) {
    return 'Diperiksa $time';
  }

  @override
  String get lastCheckedRecently => 'Baru saja diperiksa';

  @override
  String get giveYourWorkAHome => 'Berikan rumah untuk pekerjaanmu.';

  @override
  String get goBack => 'Kembali';

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
  String get images => 'Gambar';

  @override
  String get inactive => 'Tidak aktif';

  @override
  String get install => 'Pasang';

  @override
  String get installRequired => 'Instalasi diperlukan';

  @override
  String installedVersion(String version) {
    return 'Terpasang $version';
  }

  @override
  String get invite => 'Undang';

  @override
  String get inviteAgent => 'Undang agen';

  @override
  String get isolateAgentExecution => 'Isolasi eksekusi agen.';

  @override
  String get justNow => 'Baru saja';

  @override
  String get keepSandboxing => 'Pertahankan sandboxing';

  @override
  String get keybindingAddARepositoryDescription => 'Tambah repositori';

  @override
  String get keybindingAddRepository => 'Tambah repositori';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Tandai atau hapus bookmark artikel terpilih';

  @override
  String get keybindingCommandPalette => 'Palet perintah';

  @override
  String get keybindingCreateANewAgentDescription => 'Buat agen baru';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Buat ruang kerja baru';

  @override
  String get keybindingFocusSearch => 'Fokus ke pencarian';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Fokus ke kolom pencarian pull request';

  @override
  String get keybindingNewAgent => 'Agen baru';

  @override
  String get keybindingNewWorkspace => 'Ruang kerja baru';

  @override
  String get keybindingNextArticle => 'Artikel berikutnya';

  @override
  String get keybindingNextSpace => 'Space berikutnya';

  @override
  String get keybindingNextWorkspace => 'Ruang kerja berikutnya';

  @override
  String get keybindingOpenArticle => 'Buka artikel';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Buka atau tutup popup pengalih ruang kerja di bilah samping';

  @override
  String get keybindingOpenPr => 'Buka PR';

  @override
  String get keybindingOpenSettings => 'Buka pengaturan';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Buka pengaturan aplikasi';

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
  String get keybindingPreviousSpace => 'Space sebelumnya';

  @override
  String get keybindingPreviousWorkspace => 'Ruang kerja sebelumnya';

  @override
  String get keybindingRefresh => 'Muat ulang';

  @override
  String get keybindingRefreshAllFeedsDescription => 'Muat ulang semua feed';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Muat ulang daftar pull request';

  @override
  String get keybindingRescanForAdaptersDescription => 'Pindai ulang adapter';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Pilih artikel berikutnya';

  @override
  String get keybindingSelectTheNextSpaceDescription =>
      'Pilih space berikutnya';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Pilih artikel sebelumnya';

  @override
  String get keybindingSelectThePreviousSpaceDescription =>
      'Pilih space sebelumnya';

  @override
  String get keybindingSendMessage => 'Kirim pesan';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Kirim pesan saat ini';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Beralih antara mode terang dan gelap';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Beralih ke ruang kerja kedelapan';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Beralih ke ruang kerja kelima';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Beralih ke ruang kerja pertama';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Beralih ke ruang kerja keempat';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Beralih ke ruang kerja berikutnya';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Beralih ke ruang kerja kesembilan';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Beralih ke ruang kerja sebelumnya';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Beralih ke ruang kerja kedua';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Beralih ke ruang kerja ketujuh';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Beralih ke ruang kerja keenam';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Beralih ke ruang kerja ketiga';

  @override
  String get keybindingToggleBookmark => 'Alihkan bookmark';

  @override
  String get keybindingToggleTheme => 'Alihkan tema';

  @override
  String get keybindingToggleWorkspaceSwitcher =>
      'Alihkan pengalih ruang kerja';

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
  String get keybindings => 'Pintasan keyboard';

  @override
  String get keybindingsDescription =>
      'Semua pintasan keyboard. Pintasan bersifat tetap dan tidak dapat diubah.';

  @override
  String get killRunning => 'Hentikan yang berjalan';

  @override
  String get languageSystem => 'Sistem';

  @override
  String get leaveACommentEllipsis => 'Tulis komentar…';

  @override
  String get legendLabel => 'Legenda';

  @override
  String get lessLabel => 'Lebih sedikit';

  @override
  String get letsPluginTools => 'Ayo hubungkan alat Anda.';

  @override
  String get level => 'Level';

  @override
  String get loadingAgents => 'Memuat agen…';

  @override
  String get loadingModels => 'Memuat model…';

  @override
  String get loadingProviders => 'Memuat penyedia…';

  @override
  String get logLevel => 'Level log';

  @override
  String get logs => 'Log';

  @override
  String get low => 'Rendah';

  @override
  String get maintenance => 'Pemeliharaan';

  @override
  String get manageParticipants => 'Kelola peserta';

  @override
  String get manageWorkspaces => 'Kelola ruang kerja';

  @override
  String get reorderWorkspace => 'Ubah urutan ruang kerja';

  @override
  String get matchOsAppearance =>
      'Ikuti tampilan OS Anda atau pilih mode tetap.';

  @override
  String get mcpAuthToken => 'Token autentikasi MCP';

  @override
  String get mcpNotAvailableOnServer =>
      'Kontrol server MCP tidak tersedia di server yang terhubung.';

  @override
  String get modelManagedOnServer =>
      'Model ini berjalan di host server dan dikelola di sana.';

  @override
  String get mcpServer => 'Server MCP';

  @override
  String get medium => 'Sedang';

  @override
  String get memoryDataHint =>
      'Fakta dan kebijakan akan muncul di sini saat agen bekerja.';

  @override
  String get memoryLabel => 'Memori';

  @override
  String get merge => 'Gabungkan';

  @override
  String get merged => 'Digabungkan';

  @override
  String get messagePlaceholder =>
      'Pesan… (@ untuk menyebut, / untuk perintah)';

  @override
  String get navConversations => 'Ruang';

  @override
  String get microphonePermissionDenied => 'Izin mikrofon ditolak.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count menit yang lalu',
      one: '1 menit yang lalu',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Model';

  @override
  String get modified => 'Diubah';

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
  String get moreLabel => 'Lainnya';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Nama';

  @override
  String get nameAndTitleRequired => 'Nama dan judul wajib diisi.';

  @override
  String get nameAndUrlRequired => 'Nama dan URL wajib diisi';

  @override
  String get nameLabel => 'Nama';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Sandbox native tersedia di $platform.';
  }

  @override
  String get nativeSandboxNeedsInstall => 'Instalasi sandbox native diperlukan';

  @override
  String get navObservability => 'Observabilitas';

  @override
  String get navSettings => 'Pengaturan';

  @override
  String networkBlockCount(int count) {
    return '$count blok jaringan';
  }

  @override
  String get neutral => 'Netral';

  @override
  String get newCommitsPushed =>
      'Commit baru telah di-push — klik untuk memuat ulang diff';

  @override
  String get newFact => 'Fakta baru';

  @override
  String get newPolicy => 'Kebijakan baru';

  @override
  String get newsfeed => 'Umpan berita';

  @override
  String get newsfeedLabel => 'Umpan berita';

  @override
  String get newsfeedSettingsDescription =>
      'Kelola umpan yang Anda ikuti dan preferensi pembaca.';

  @override
  String get newsfeedSettingsTitle => 'Pengaturan umpan berita';

  @override
  String get nextMatch => 'Kecocokan berikutnya (↵)';

  @override
  String get noActiveWorkspace =>
      'Tidak ada ruang kerja atau repo aktif yang dipilih.';

  @override
  String get noActiveWorkspaceCreate => 'Tidak ada ruang kerja aktif';

  @override
  String get noActiveWorkspaceGithub =>
      'Tidak ada ruang kerja aktif dengan repo GitHub.';

  @override
  String get noAgents => 'Tidak ada agen';

  @override
  String get noArticlesYet => 'Belum ada artikel';

  @override
  String get noArticlesYetBody =>
      'Artikel dari umpan Anda akan muncul di sini.';

  @override
  String get noExecutionLogsYet => 'Belum ada log eksekusi';

  @override
  String get noFacts => 'Belum ada fakta';

  @override
  String get noFeedsYet => 'Belum ada umpan';

  @override
  String get noFileAnchor =>
      'Tidak ada jangkar file — tidak dapat mengirim komentar sebaris.';

  @override
  String get noFileChangesInScope =>
      'Tidak ada perubahan file dalam cakupan ini';

  @override
  String get noGifsFound => 'GIF tidak ditemukan';

  @override
  String get noInputDevicesDetected =>
      'Tidak ada perangkat input terdeteksi — menggunakan default sistem.';

  @override
  String get noMatchingFiles => 'Tidak ada file yang cocok';

  @override
  String get noMatchingGoogleFonts => 'Tidak ada Google Fonts yang cocok.';

  @override
  String get noMemoryData => 'Belum ada data memori';

  @override
  String get noMessagesYet => 'Belum ada pesan';

  @override
  String get noModelsAdvertised =>
      'Tidak ada model yang diiklankan oleh adapter ini.';

  @override
  String get noOpenPullRequests => 'Tidak ada pull request yang terbuka';

  @override
  String get noPolicies => 'Belum ada kebijakan';

  @override
  String get noReposInWorkspaceYet => 'Belum ada repositori di ruang kerja ini';

  @override
  String get noRunnersDetected =>
      'Belum ada runner terdeteksi. Segarkan untuk memindai lagi.';

  @override
  String get noSavedArticles => 'Tidak ada artikel tersimpan';

  @override
  String get noSavedArticlesBody =>
      'Artikel yang Anda simpan akan muncul di sini.';

  @override
  String noShortcutsMatch(String query) {
    return 'Tidak ada pintasan yang cocok dengan \"$query\"';
  }

  @override
  String get noSystemFonts => 'Tidak ada font sistem terdeteksi.';

  @override
  String get noTokenSet =>
      'Tidak ada token yang diatur — akses tidak dibatasi.';

  @override
  String get noWorkingMemory => 'Belum ada catatan memori kerja.';

  @override
  String get noneAllRoles => 'Tidak ada (semua peran)';

  @override
  String get notAvailable => 'Tidak tersedia';

  @override
  String get notConfiguredLabel => 'Belum dikonfigurasi.';

  @override
  String get notFoundLabel => 'Tidak ditemukan';

  @override
  String get notes => 'Catatan';

  @override
  String get notificationAgentFinished => 'Agen selesai';

  @override
  String get notificationPrMentioned => 'Disebutkan di pull request';

  @override
  String get notificationNewMessages => 'Pesan baru';

  @override
  String get notificationPrMerged => 'PR digabungkan';

  @override
  String get notificationPrPublished => 'PR dipublikasikan';

  @override
  String get notificationReviewRequested => 'Tinjauan diminta';

  @override
  String get notifications => 'Notifikasi';

  @override
  String get notifyAgentRunCompleted =>
      'Beritahu saat agen menyelesaikan sebuah run.';

  @override
  String get notifyPrMentioned =>
      'Beritahu saat Anda disebutkan di pull request.';

  @override
  String get notifyNewMessages =>
      'Beritahu saat ada pesan agen baru di ruang lain.';

  @override
  String get notifyPrMerged => 'Beritahu saat pull request digabungkan.';

  @override
  String get notifyPrPublished =>
      'Beritahu saat agen memublikasikan pull request.';

  @override
  String get notifyReviewRequested =>
      'Beritahu saat tinjauan Anda diminta pada pull request.';

  @override
  String get notificationReviewStale => 'Tinjauan kedaluwarsa';

  @override
  String get notifyReviewStale =>
      'Saat commit baru masuk ke pull request yang sudah Anda tinjau';

  @override
  String get notificationPrMergeReadiness => 'Siap digabungkan';

  @override
  String get notifyPrMergeReadiness =>
      'Beritahu saat pull request yang Anda buat menjadi bisa digabungkan, atau tidak lagi.';

  @override
  String get notificationPrReviewDecision => 'Keputusan tinjauan';

  @override
  String get notifyPrReviewDecision =>
      'Beritahu saat peninjau menyetujui, meminta perubahan, atau persetujuan dibatalkan.';

  @override
  String get notificationPrChecksStatus => 'Checks';

  @override
  String get notifyPrChecksStatus =>
      'Beritahu saat CI gagal pada pull request yang Anda buat, dan saat pulih.';

  @override
  String get notificationPrThreadActivity => 'Utas tinjauan';

  @override
  String get notifyPrThreadActivity =>
      'Beritahu saat seseorang membalas atau menyelesaikan utas yang Anda ikuti.';

  @override
  String get notificationPrReadyToMerge => 'Siap digabungkan';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '$prTitle sudah memenuhi semua syarat.';
  }

  @override
  String get notificationPrMergeBlocked => 'Tidak lagi bisa digabungkan';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '$prTitle berkonflik dengan cabang dasar.';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '$prTitle tertinggal dari cabang dasar.';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '$prTitle menunggu tinjauan yang wajib.';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'Peninjau meminta perubahan pada $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return 'Pemeriksaan gagal pada $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '$prTitle tidak lagi dapat digabungkan.';
  }

  @override
  String get notificationPrApproved => 'Pull request disetujui';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '$login menyetujui $prTitle';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '$prTitle disetujui';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count peninjau masih harus merespons',
      one: '1 peninjau masih harus merespons',
      zero: 'tidak ada peninjau tersisa',
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
  String get notificationPrReviewDismissed => 'Persetujuan dibatalkan';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '$prTitle perlu ditinjau lagi.';
  }

  @override
  String get notificationPrChecksFailed => 'Pemeriksaan gagal';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '$checkName gagal pada $prTitle';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return 'Pemeriksaan gagal pada $prTitle';
  }

  @override
  String get notificationPrChecksRecovered => 'Pemeriksaan lulus';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '$prTitle sudah hijau lagi.';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '$login menyebut Anda di $location';
  }

  @override
  String get notificationPrThreadReplied => 'Balasan baru';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '$login membalas di $location';
  }

  @override
  String get notificationPrThreadResolved => 'Utas diselesaikan';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return 'Utas Anda di $location telah diselesaikan.';
  }

  @override
  String get notificationGroupAgents => 'Agen';

  @override
  String get notificationGroupPullRequests => 'Pull requests';

  @override
  String get notificationGroupMessages => 'Pesan';

  @override
  String get notificationGroupTickets => 'Tiket';

  @override
  String get notificationGroupCalendar => 'Kalender';

  @override
  String get notificationGroupMachines => 'Mesin';

  @override
  String get notificationsMutedRepos => 'Repositori yang dibisukan';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repositori dibisukan',
      one: '1 repositori dibisukan',
      zero: 'Tidak ada repositori yang dibisukan',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'Bisukan repositori ini';

  @override
  String get onboardingLinuxDescription =>
      'Control Center dapat menggunakan kontainer Linux untuk mengisolasi eksekusi agen.';

  @override
  String get onboardingMacosDescription =>
      'Control Center menggunakan sandbox native di macOS untuk mengisolasi eksekusi agen.';

  @override
  String get onboardingUnsupportedDescription =>
      'Sandbox tidak tersedia di platform ini. Eksekusi agen akan tanpa isolasi.';

  @override
  String get openArticlesInApp => 'Buka artikel di aplikasi';

  @override
  String get openInBrowser => 'Buka di browser';

  @override
  String get openedInYourBrowser => 'Dibuka di browser Anda.';

  @override
  String get openLabel => 'Buka';

  @override
  String get openOnGithub => 'Buka di GitHub';

  @override
  String get openStatus => 'Terbuka';

  @override
  String get optionalPersonaDescription => 'Deskripsi persona opsional';

  @override
  String get otherLabel => 'Lainnya';

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
  String get pasteValueHere => 'Tempel nilai di sini';

  @override
  String get persona => 'Persona';

  @override
  String get policies => 'Kebijakan';

  @override
  String get policiesHint =>
      'Kebijakan akan muncul di sini setelah agen mempromosikan fakta.';

  @override
  String get policy => 'Kebijakan';

  @override
  String get popular => 'Populer';

  @override
  String get port => 'Port';

  @override
  String get postingEllipsis => 'Memposting…';

  @override
  String get prCommits => 'Commit';

  @override
  String get prMergedBody => 'Sebuah pull request telah digabung';

  @override
  String get prMoreActions => 'Tindakan lainnya';

  @override
  String get prTitle => 'Judul PR';

  @override
  String get reviewCommentHint =>
      'Cukup klik setujui, atau kalau lagi semangat tambahkan komentar atau reaksi…';

  @override
  String get nothingToPreview => 'Tidak ada yang bisa dipratinjau';

  @override
  String get previousMatch => 'Kecocokan sebelumnya (⇧↵)';

  @override
  String get priorityReviewsDescription =>
      'Tinjauan prioritas dan ringkasan repositori.';

  @override
  String get prsCreated => 'PR dibuat';

  @override
  String get prsMerged => 'PR digabung';

  @override
  String get publishToGithub => 'Publikasikan ke GitHub';

  @override
  String get published => 'Dipublikasikan';

  @override
  String get pullRequestApproved => 'Pull request disetujui';

  @override
  String get pullRequests => 'Pull requests';

  @override
  String get questionLabel => 'Pertanyaan';

  @override
  String get queued => 'Dalam antrean';

  @override
  String get react => 'React';

  @override
  String get readPrsIssuesMetadata =>
      'Memungkinkan agen membaca PR, issue, dan metadata repositori.';

  @override
  String get readerPreferences => 'Preferensi pembaca';

  @override
  String get reasoningEffort => 'Upaya penalaran';

  @override
  String get recommendLabel => 'REKOMENDASI';

  @override
  String recordingFromDevice(String device) {
    return 'Merekam dari $device.';
  }

  @override
  String get redownload => 'Unduh ulang';

  @override
  String get redownloadEmbeddingModel => 'Unduh ulang model embedding?';

  @override
  String get redownloadVoiceModel => 'Unduh ulang model suara?';

  @override
  String get refinePlan => 'Sempurnakan rencana';

  @override
  String get refresh => 'Segarkan';

  @override
  String get refreshAll => 'Segarkan semua';

  @override
  String get refreshAllFeeds => 'Segarkan semua feed';

  @override
  String get reject => 'Tolak';

  @override
  String get rejected => 'Ditolak';

  @override
  String get reload => 'Muat ulang';

  @override
  String get remove => 'Hapus';

  @override
  String get removeBookmark => 'Hapus bookmark';

  @override
  String get removeEmbeddingModel => 'Hapus model embedding?';

  @override
  String get removeLogo => 'Hapus logo';

  @override
  String get removeRepoFromWorkspace => 'Hapus repositori dari ruang kerja?';

  @override
  String get removeVoiceModel => 'Hapus model suara?';

  @override
  String get removed => 'Dihapus';

  @override
  String get renamed => 'Diganti nama';

  @override
  String get reopen => 'Buka kembali';

  @override
  String get resolve => 'Selesaikan';

  @override
  String get replyEllipsis => 'Balas…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name akan dihapus dari ruang kerja ini. File lokal di disk tidak diubah.';
  }

  @override
  String repoAccessNoticeBody(String repos) {
    return 'Kredensial GitHub server tidak dapat melihat $repos. Jika repositori milik organisasi, instal GitHub App di sana atau hubungkan token yang memiliki akses.';
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
      'Instalasi GitHub App ditangguhkan';

  @override
  String repoAccessNoticeSuspendedBody(String repos) {
    return 'Menampilkan data terakhir yang diketahui untuk $repos. Lanjutkan instalasi di GitHub, atau hubungkan token yang memiliki akses.';
  }

  @override
  String get repoNoAccessBadge => 'Tidak ada akses';

  @override
  String get reportsTo => 'Melapor ke';

  @override
  String reposCount(int count) {
    return 'Repositori ($count)';
  }

  @override
  String get reposDescription =>
      'Checkout lokal yang ditargetkan ruang kerja ini.';

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
    return 'Tidak dapat menambahkan $_temp0: $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repositori ditambahkan',
      one: 'Repositori ditambahkan',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'Setelan repositori';

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
    return 'Peran wajib: $role';
  }

  @override
  String get requiredRoleOptional => 'Peran wajib (opsional)';

  @override
  String get requirements => 'Persyaratan';

  @override
  String get reset => 'Atur ulang';

  @override
  String get resolved => 'Diselesaikan';

  @override
  String get enclosedTerminalTitle => 'Terminal terkurung';

  @override
  String get enclosedTerminalStart => 'Buka shell';

  @override
  String get enclosedTerminalStartHint =>
      'Shell ini berjalan di dalam VM sekali pakai percakapan ini. Shell boot saat Anda membukanya, bukan saat aplikasi dimulai.';

  @override
  String get terminalStreamReconnecting =>
      'aliran terputus — menyambung ulang…';

  @override
  String get terminalStreamError => 'kesalahan aliran:';

  @override
  String get terminalShellExited => 'shell keluar';

  @override
  String get restartShell => 'Mulai ulang shell';

  @override
  String get retry => 'Coba lagi';

  @override
  String get review => 'Tinjau';

  @override
  String get reviewedByMe => 'Ditinjau oleh saya';

  @override
  String get reviewers => 'Peninjau';

  @override
  String get roleLabel => 'Peran';

  @override
  String get ruleHint => 'Aturan kebijakan (markdown didukung)';

  @override
  String get ruleLabel => 'Aturan';

  @override
  String get runCompleted => 'Run selesai';

  @override
  String get running => 'Berjalan';

  @override
  String get runningLabel => 'berjalan';

  @override
  String get runs => 'Run';

  @override
  String get runsLabel => 'Run';

  @override
  String get sandboxBackendNativeLabel => 'Sandbox native';

  @override
  String get sandboxBackendMicrovmLabel => 'VM terisolasi';

  @override
  String get sandboxBackendNoneLabel => 'Tanpa isolasi';

  @override
  String get sandboxLinuxInstall =>
      'Sandbox native di Linux/WSL2 menggunakan bubblewrap. Instal dengan:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'Sandbox native sudah bawaan di macOS - menggunakan Apple Seatbelt (`sandbox-exec`). Tidak perlu instal.';

  @override
  String get sandboxPermissions => 'Izin sandbox';

  @override
  String get sandboxUnsupported =>
      'Sandbox native belum didukung di platform ini. Kembali ke \"Tanpa isolasi\".';

  @override
  String get sandboxingDisabledDescription =>
      'Agen berjalan langsung di host dengan env penuh - tidak disarankan.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Semua pemanggilan agen dialihkan melalui $backend.';
  }

  @override
  String get save => 'Simpan';

  @override
  String get saveChanges => 'Simpan perubahan';

  @override
  String get adapterArguments => 'Argumen tambahan';

  @override
  String get adapterArgumentsHint => 'Flag CLI tambahan (mis. --yolo)';

  @override
  String get addVariable => 'Tambah variabel';

  @override
  String get environmentVariables => 'Variabel lingkungan';

  @override
  String get environmentVariablesDescription =>
      'Variabel lingkungan kustom yang diteruskan ke adapter ini (mis. kunci API). Disimpan di keychain.';

  @override
  String get variableKey => 'Kunci';

  @override
  String get variableValue => 'Nilai';

  @override
  String get savingEllipsis => 'Menyimpan…';

  @override
  String get scopeDiffToCommits =>
      'Batasi diff ke commit — Shift-klik untuk rentang';

  @override
  String get noPrsMatchSearch => 'Tidak ada pull request yang cocok';

  @override
  String get searchFactsHint => 'Cari fakta...';

  @override
  String get searchFonts => 'Cari font…';

  @override
  String get searchGifs => 'Cari GIF';

  @override
  String get searchGifsHint => 'Cari GIF...';

  @override
  String get searchInDiffHint => 'Cari di diff…';

  @override
  String get searchOrTypeModel => 'Cari atau ketik nama model…';

  @override
  String get searchPlaceholder => 'Cari…';

  @override
  String get searchShortcuts => 'Cari pintasan…';

  @override
  String get shortcutUnavailableInBrowser => 'Tidak tersedia di browser';

  @override
  String get searching => 'Mencari…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count detik yang lalu',
      one: '1 detik yang lalu',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Pilih adapter';

  @override
  String get selectAdapterFirst => 'Pilih adapter dulu';

  @override
  String get selectAgentToReportTo => 'Pilih agen tujuan laporan…';

  @override
  String get selectAnAgent => 'Pilih agen';

  @override
  String get selectConversation => 'Pilih percakapan';

  @override
  String get selectLabel => 'Pilih';

  @override
  String get selectRunner => 'Pilih runner';

  @override
  String get semanticSearch => 'Pencarian semantik';

  @override
  String get send => 'Kirim';

  @override
  String get sendFirstMessage => 'Kirim pesan pertama';

  @override
  String get sendMessage => 'Kirim pesan';

  @override
  String sentFindingsToAgent(int count) {
    return '$count temuan dikirim ke agen.';
  }

  @override
  String setGithubLinkDescription(String name) {
    return 'Atur pemilik dan nama repositori GitHub untuk $name. Digunakan untuk meresolusi referensi PR dan issue seperti #123 di konten markdown.';
  }

  @override
  String get setLabel => 'Atur';

  @override
  String get setToken => 'Atur token';

  @override
  String get settingsLabel => 'Pengaturan';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get settingsLanguageDescription => 'Pilih bahasa aplikasi.';

  @override
  String get shortTask => 'Tugas singkat';

  @override
  String get showNativeNotifications =>
      'Tampilkan notifikasi sistem untuk peristiwa.';

  @override
  String get showSuperseded => 'Tampilkan yang digantikan';

  @override
  String get signedIn => 'Sudah masuk.';

  @override
  String signedInAs(String username) {
    return 'Masuk sebagai $username.';
  }

  @override
  String get skillNameRequired => 'Nama skill wajib diisi.';

  @override
  String skillSaved(String name) {
    return 'Skill \"$name\" disimpan.';
  }

  @override
  String get skillsSourcesTab => 'Sumber';

  @override
  String get skillSourcesDisclaimer =>
      'Skill diinstal dari repositori GitHub yang Anda tambahkan. Metadata repositori tidak tepercaya — pemindaian antivirus adalah sinyal keamanan yang sebenarnya.';

  @override
  String get skillSourcesEmpty => 'Tidak ada repositori skill';

  @override
  String get skillSourcesEmptyHint =>
      'Tambahkan repositori GitHub untuk menelusuri skill-nya.';

  @override
  String get skillSourceAdd => 'Tambah repositori';

  @override
  String get skillSourceAddTitle => 'Tambah repositori skill';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      'Masukkan URL repositori GitHub (https://github.com/owner/repo).';

  @override
  String skillSourceAdded(String repo) {
    return 'Repositori $repo ditambahkan.';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'Repositori $repo sudah ditambahkan.';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'Repositori $repo dihapus.';
  }

  @override
  String get skillSourceRemove => 'Hapus';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return 'Hapus $repo?';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'Skill yang terinstal tetap terinstal. Hanya katalog repositori yang dihapus.';

  @override
  String get skillSourceNoSkills =>
      'Tidak ada skill di repositori ini (skill adalah direktori yang berisi SKILL.md).';

  @override
  String get skillSourceRefresh => 'Segarkan';

  @override
  String get skillSourceInstalledBadge => 'Terinstal';

  @override
  String get skillSourceUpdateBadge => 'Pembaruan tersedia';

  @override
  String get skillSourceSlugTaken => 'Nama sudah digunakan';

  @override
  String skillSourceFilesCount(num count) {
    return '$count file';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'Skill ini tidak punya README.';

  @override
  String get skillSourceNoMatches =>
      'Tidak ada skill yang cocok dengan filter Anda.';

  @override
  String get skillUpdateAction => 'Perbarui';

  @override
  String get skillUninstallAction => 'Copot';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return 'Copot \"$slug\"?';
  }

  @override
  String skillUninstalled(String slug) {
    return 'Skill \"$slug\" dicopot.';
  }

  @override
  String get skillFindingLine => 'baris';

  @override
  String get skillInstallAnywayOverride => 'Saya paham risikonya — instal saja';

  @override
  String skillInstalled(String slug) {
    return 'Skill \"$slug\" diinstal.';
  }

  @override
  String get skillPreviewCapabilities => 'Kapabilitas';

  @override
  String get skillPreviewFindings => 'Temuan';

  @override
  String get skillPreviewGuardedActions => 'Tindakan yang dijaga';

  @override
  String get skillPreviewLlmReviewed => 'Ditinjau LLM';

  @override
  String get skillPreviewNoCapabilities =>
      'Tidak ada kapabilitas yang dideklarasikan.';

  @override
  String get skillPreviewNoFindings => 'Tidak ada temuan.';

  @override
  String get skillPreviewScanning => 'Memindai skill…';

  @override
  String get skillPreviewVerdictLabel => 'Putusan pemindaian';

  @override
  String get skillPreviewVerdictPass => 'Lulus';

  @override
  String get skillPreviewVerdictQuarantine => 'Dikarantina';

  @override
  String get skillPreviewVerdictWarn => 'Peringatan';

  @override
  String get skillQuarantineWarning =>
      'Skill ini dikarantina oleh pemindai. Menginstalnya menjalankan kode di mesin Anda. Lanjutkan hanya jika Anda percaya sumbernya dan sudah meninjau temuan.';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'Dikarantina dan dilepas dari agen: $agents';
  }

  @override
  String get skillNotScanned => 'Belum dipindai';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'Manual';

  @override
  String get skillOriginRegistry => 'Registri';

  @override
  String get skillOriginRuntimeLocal => 'Runtime lokal';

  @override
  String get skillRulesStale => 'Pemindaian kedaluwarsa';

  @override
  String get skillSaveAnywayOverride => 'Saya paham risikonya — simpan saja';

  @override
  String get skillSaveBlockedBody => 'Konten diblokir sebelum apa pun ditulis.';

  @override
  String get skillSaveBlockedTitle =>
      'Penyimpanan diblokir oleh gerbang pemindaian';

  @override
  String get skillScanAction => 'Pindai';

  @override
  String get skillScanAll => 'Pindai semua';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass lulus · $warn peringatan · $quarantine dikarantina';
  }

  @override
  String get skillStateDrifted => 'Diubah sejak instalasi';

  @override
  String get skillStateUnmanaged => 'Tidak dikelola';

  @override
  String get skillSeverityBlocked => 'Diblokir';

  @override
  String get skillSeverityWarn => 'Peringatan';

  @override
  String get skillsInstalledTab => 'Terpasang';

  @override
  String get skills => 'Skill';

  @override
  String get skipAcceptRisk => 'Lewati — saya terima risikonya';

  @override
  String get skipForNow => 'Lewati dulu';

  @override
  String get skipSandboxing => 'Lewati sandboxing';

  @override
  String get skipSandboxingDialogContent =>
      'Yakin ingin melewati sandboxing? Ini memungkinkan agen mengeksekusi kode di sistem Anda tanpa isolasi.';

  @override
  String get somethingWentWrong => 'Terjadi kesalahan';

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
  String get splitDiff => 'Diff terpisah (berdampingan)';

  @override
  String get startLabel => 'Mulai';

  @override
  String get startOnAppLaunch => 'Mulai saat aplikasi diluncurkan';

  @override
  String get statusLabel => 'Status';

  @override
  String get onboardingStepConnect => 'Hubungkan';

  @override
  String get onboardingStepWorkspace => 'Ruang kerja';

  @override
  String get onboardingStepSandbox => 'Sandbox';

  @override
  String get onboardingStepAdapter => 'Adapter';

  @override
  String get onboardingStepVoice => 'Suara';

  @override
  String get stop => 'Berhenti';

  @override
  String get stopped => 'Dihentikan';

  @override
  String get strictIdentityCheck => 'Pemeriksaan identitas ketat';

  @override
  String get success => 'Berhasil';

  @override
  String get successLabel => 'Berhasil';

  @override
  String get suggestAChange => 'Usulkan perubahan';

  @override
  String get suggestLabel => 'USULKAN';

  @override
  String get superseded => 'Digantikan';

  @override
  String get synced => 'Disinkronkan';

  @override
  String get systemDefault => 'Default sistem';

  @override
  String get systemFonts => 'Font sistem';

  @override
  String get systemPrompt => 'Prompt sistem';

  @override
  String get systemPromptLabel => 'Prompt sistem';

  @override
  String get talkToControlCenter => 'Bicara dengan Control Center.';

  @override
  String get taskMentionSection => 'Tugas';

  @override
  String get testLabel => 'Tes';

  @override
  String get theme => 'Tema';

  @override
  String get themeDark => 'Gelap';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get thisCannotBeUndone => 'Ini tidak dapat dibatalkan.';

  @override
  String get ticketLabel => 'TIKET';

  @override
  String get titleLabel => 'Judul';

  @override
  String get todayLabel => 'Hari ini';

  @override
  String get toggleTheme => 'Alihkan tema';

  @override
  String get tokenConfigured =>
      'Dikonfigurasi — klien harus menyertakan token ini.';

  @override
  String get topic => 'Topik';

  @override
  String get topicHint => 'mis. Tech Stack, Design System';

  @override
  String get totalRuns => 'Total eksekusi';

  @override
  String trackingParamsCount(int count) {
    return '$count parameter pelacakan';
  }

  @override
  String get typeCommandOrSearch => 'Ketik perintah atau cari…';

  @override
  String get typography => 'Tipografi';

  @override
  String get unavailable => 'Tidak tersedia';

  @override
  String get unifiedDiff => 'Diff terpadu';

  @override
  String get unknownAuthor => 'Tidak diketahui';

  @override
  String get unnamedAgent => 'Agen tanpa nama';

  @override
  String get updateKey => 'Perbarui kunci';

  @override
  String get updateLabel => 'Perbarui';

  @override
  String get updateToken => 'Perbarui token';

  @override
  String updatedDaysAgo(int count) {
    return 'Diperbarui ${count}h lalu';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'Diperbarui ${count}j lalu';
  }

  @override
  String get updatedJustNow => 'Baru saja diperbarui';

  @override
  String updatedMinutesAgo(int count) {
    return 'Diperbarui ${count}mnt lalu';
  }

  @override
  String get useSandbox => 'Gunakan sandbox';

  @override
  String get useWorkspaceDefault => 'Gunakan default ruang kerja';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'Kosongkan untuk memakai User-Agent default aplikasi. Beberapa situs memblokir User-Agent yang bukan browser.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Menggunakan mikrofon default sistem.';

  @override
  String get viewLabel => 'Lihat';

  @override
  String get viewLogs => 'Lihat log';

  @override
  String voiceInstallFailed(String error) {
    return 'Instalasi gagal: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Belum terinstal. Unduh sekali ~200 MB; berjalan sepenuhnya di perangkat.';

  @override
  String get voiceModelNotInstalledLabel => 'Model suara belum terinstal.';

  @override
  String get voiceRedownloadBody =>
      'File model yang ada akan dihapus dan arsip ~200 MB diunduh ulang. Transkripsi suara tidak tersedia hingga unduhan selesai.';

  @override
  String get voiceRemoveBody =>
      'Transkripsi suara akan dinonaktifkan hingga Anda menginstalnya lagi. Anda dapat menginstalnya kapan saja.';

  @override
  String get voiceTranscription => 'Transkripsi suara';

  @override
  String get weakIsolationDescription =>
      'Isolasi lemah — hanya batas namespace, tanpa batas kernel.';

  @override
  String get whenOffNoDefaultRoute =>
      'Jika nonaktif, sandbox boot tanpa rute default.';

  @override
  String get whenOffServerStaysStopped =>
      'Jika nonaktif, server tetap berhenti hingga Anda memulainya.';

  @override
  String get speechModel => 'Model ucapan';

  @override
  String get speechModelHint =>
      'Dipakai untuk transkripsi rapat dan mikrofon composer.';

  @override
  String get voiceModelInstalled =>
      'Terinstal. Menjalankan transkripsi rapat dan tombol mikrofon composer.';

  @override
  String get meetingMicSilentWarning =>
      'Mikrofon Anda mungkin dimatikan — yang lain sedang berbicara, tetapi tidak ada yang sampai ke mikrofon Anda.';

  @override
  String get meetingSummaryPrivacyNotice =>
      'Rekaman dan transkripsi tetap di mesin ini. Ringkasan ditulis oleh agen, jadi jika memakai model cloud, transkrip dan catatan Anda dikirim ke penyedia tersebut.';

  @override
  String get meetingTemplates => 'Templat catatan rapat';

  @override
  String get meetingTemplatesHint =>
      'Bentuk ringkasan AI untuk jenis rapat. Templat aktif berlaku untuk ringkasan baru dan yang dijalankan ulang.';

  @override
  String get meetingTemplateActive => 'Templat aktif';

  @override
  String get meetingTemplateAdd => 'Tambah templat';

  @override
  String get meetingTemplateNewTitle => 'Templat baru';

  @override
  String get meetingTemplateEditTitle => 'Edit templat';

  @override
  String get meetingTemplateNameLabel => 'Nama';

  @override
  String get meetingTemplateNameHint => 'mis. Sprint review';

  @override
  String get meetingTemplateInstructionsLabel => 'Instruksi';

  @override
  String get meetingTemplateInstructionsHint =>
      'Bagaimana AI harus menyusun dan menekankan catatan ini?';

  @override
  String get workingMemory => 'Memori kerja';

  @override
  String get workspaceName => 'Nama ruang kerja';

  @override
  String get workspaceScopedSkills =>
      'File skill berskop ruang kerja yang dilampirkan ke agen.';

  @override
  String get workspaces => 'Ruang kerja';

  @override
  String get writePrivateNotes =>
      'Tulis catatan pribadi, observasi, rencana...';

  @override
  String get writeSkillContent => 'Tulis konten skill di sini (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tahun lalu',
      one: '1 tahun lalu',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Kemarin';

  @override
  String get focusModeStart => 'Mulai sesi fokus';

  @override
  String get focusModeConfigTitle => 'Mulai sesi fokus';

  @override
  String get focusModeGoalLabel => 'Tujuan';

  @override
  String get focusModeGoalHint => 'Apa yang sedang Anda kerjakan?';

  @override
  String get focusModeDurationLabel => 'Durasi';

  @override
  String get focusModeBlockNotifications => 'Blokir notifikasi';

  @override
  String get focusModeStartButton => 'Mulai';

  @override
  String get focusModeFloat => 'Kecilkan ke bar';

  @override
  String get focusModeActiveTooltip =>
      'Mode fokus aktif — ketuk untuk mengakhiri';

  @override
  String get dismiss => 'Tutup';

  @override
  String get acceptAndResolve => 'Terima & selesaikan';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'Anda sudah mereview selama ${minutes}m — riset menunjukkan kualitas review bisa menurun setelah 60 menit. Pertimbangkan istirahat.';
  }

  @override
  String get notificationSound => 'Suara notifikasi';

  @override
  String get notificationSoundDescription =>
      'Suara yang diputar saat notifikasi ditampilkan.';

  @override
  String get notificationSoundNone => 'Tidak ada';

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
  String get notificationSoundMigrosHard => 'Migros (keras)';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => 'Tes';

  @override
  String get notificationVolume => 'Volume';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Tidak ada PR oleh @$login di ruang kerja ini';
  }

  @override
  String get usersLabel => 'Pengguna';

  @override
  String get mergePullRequest => 'Gabungkan pull request';

  @override
  String get forceMergePullRequest => 'Paksa gabungkan pull request';

  @override
  String get closePullRequest => 'Tutup pull request';

  @override
  String get closePullRequestConfirm => 'Yakin ingin menutup pull request ini?';

  @override
  String get stackedPullRequests => 'Pull request bertumpuk';

  @override
  String partOfStack(int position, int total) {
    return 'Bagian dari stack ($position dari $total)';
  }

  @override
  String get createStack => 'Buat stack';

  @override
  String get createStackDialogTitle => 'Buat stack pull request';

  @override
  String createStackDialogBody(int count) {
    return '$count pull request ini akan ditumpuk, dari bawah ke atas:';
  }

  @override
  String get createStackInvalidSelection =>
      'Pilih setidaknya dua pull request dari repositori yang sama untuk membuat stack';

  @override
  String get createStackNotAChain =>
      'Pull request yang dipilih tidak membentuk rantai: branch dasar setiap pull request harus berupa branch head milik yang sebelumnya';

  @override
  String get createStackAlreadyStacked =>
      'Satu atau beberapa pull request yang dipilih sudah ada dalam stack';

  @override
  String get stackCreated => 'Stack dibuat';

  @override
  String get stackCreationFailed => 'Tidak dapat membuat stack';

  @override
  String get squashAndMerge => 'Squash dan gabungkan';

  @override
  String get createMergeCommit => 'Buat commit merge';

  @override
  String get rebaseAndMerge => 'Rebase dan gabungkan';

  @override
  String get commitTitle => 'Judul commit';

  @override
  String get commitDescription => 'Deskripsi commit';

  @override
  String get pullRequestMerged => 'Pull request digabungkan';

  @override
  String get pullRequestClosed => 'Pull request ditutup';

  @override
  String failedToMergePr(String error) {
    return 'Gagal menggabungkan: $error';
  }

  @override
  String failedToClosePr(String error) {
    return 'Gagal menutup: $error';
  }

  @override
  String get markReadyForReview => 'Siap ditinjau';

  @override
  String get markReadyForReviewConfirm =>
      'Pull request ini akan keluar dari draf. Peninjau diberi tahu, pemeriksaan wajib mulai membatasi merge, dan otomatisasi yang memantau pull request siap akan dijalankan.';

  @override
  String get convertToDraft => 'Ubah ke draf';

  @override
  String get convertToDraftConfirm =>
      'Pull request ini akan kembali ke draf. Permintaan tinjauan yang tertunda dibatalkan dan tidak dapat digabungkan sampai Anda menandainya siap lagi.';

  @override
  String get pullRequestMarkedReady => 'Pull request ditandai siap ditinjau';

  @override
  String get pullRequestConvertedToDraft => 'Pull request diubah ke draf';

  @override
  String failedToMarkPrReady(String error) {
    return 'Gagal menandai siap ditinjau: $error';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'Gagal mengubah ke draf: $error';
  }

  @override
  String get checksFailing => 'Pemeriksaan gagal';

  @override
  String get reviewsPending => 'Beberapa tinjauan masih tertunda';

  @override
  String get mergeConflictsWithBase =>
      'Branch ini memiliki konflik yang harus diselesaikan';

  @override
  String get branchOutOfDateWithBase =>
      'Branch ini tertinggal dari branch dasar';

  @override
  String get mergeBlockedByBranchProtection =>
      'Perlindungan branch memblokir merge ini';

  @override
  String get confirm => 'Konfirmasi';

  @override
  String get trustedSitesSectionTitle => 'Situs tepercaya';

  @override
  String get trustedSitesEmpty =>
      'Belum ada situs tepercaya. Tambahkan domain untuk menonaktifkan pemblokiran di situ.';

  @override
  String get addTrustedSite => 'Tambahkan situs tepercaya';

  @override
  String get removeTrustedSite => 'Hapus';

  @override
  String get disableBlockingForThisSite =>
      'Nonaktifkan pemblokiran di situs ini';

  @override
  String get enableBlockingForThisSite => 'Aktifkan pemblokiran di situs ini';

  @override
  String get enterDomainHint => 'mis. example.com';

  @override
  String get invalidDomain => 'Masukkan domain yang valid (mis. example.com)';

  @override
  String get pageLoadTimedOut =>
      'Pemuatan halaman habis waktu. Muat ulang atau buka di browser.';

  @override
  String get pipelinesScreenTitle => 'Pipeline';

  @override
  String get pipelinesScreenSubtitle =>
      'Alur kerja agen deklaratif multi-langkah';

  @override
  String get pipelinesRunPipeline => 'Jalankan pipeline';

  @override
  String get pipelineRunLauncherTitle => 'Jalankan pipeline';

  @override
  String get pipelineRunSubtitle =>
      'Pilih pipeline dan isi inputnya untuk memulai eksekusi.';

  @override
  String get pipelineRunNoInputsBadge => 'Tanpa input';

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
  String get pipelineRunNoInputs => 'Pipeline ini tidak memerlukan input.';

  @override
  String get pipelineRunSubmit => 'Jalankan pipeline';

  @override
  String get pipelineRunCouldNotStart => 'Tidak dapat memulai eksekusi.';

  @override
  String pipelineRunStarted(String name) {
    return 'Memulai $name';
  }

  @override
  String get pipelineRunEmptyTitle => 'Tidak ada pipeline yang siap dijalankan';

  @override
  String get pipelineRunEmptyHint =>
      'Aktifkan pipeline dan nyalakan eksekusi manual di editornya untuk menjalankannya di sini.';

  @override
  String get pipelineRunManageTemplates => 'Kelola pipeline';

  @override
  String get pipelineRunSettingsTitle => 'Eksekusi manual';

  @override
  String get pipelineRunSettingsAllow => 'Izinkan eksekusi manual';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Tampilkan pipeline ini di halaman eksekusi agar dapat dijalankan secara manual.';

  @override
  String get pipelineRunSettingsConcurrencyTitle => 'Konkurensi';

  @override
  String get pipelineRunSettingsMaxParallel => 'Maks. eksekusi paralel';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'Kosongkan untuk tanpa batas. Eksekusi tambahan menunggu di antrean dan dimulai saat slot tersedia.';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'Tanpa batas';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      'Masukkan bilangan bulat 1 atau lebih, atau kosongkan untuk tanpa batas.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Input';

  @override
  String get pipelineRunSettingsAddInput => 'Tambah input';

  @override
  String get pipelineRunSettingsNoInputs => 'Belum ada input.';

  @override
  String get pipelineInputEditTitle => 'Kolom input';

  @override
  String get pipelineInputKeyLabel => 'Kunci';

  @override
  String get pipelineInputKeyHelp =>
      'Kunci state tempat nilai disimpan (mis. repo_full_name).';

  @override
  String get pipelineInputLabelLabel => 'Label';

  @override
  String get pipelineInputTypeLabel => 'Tipe';

  @override
  String get pipelineInputOptionsLabel => 'Opsi (dipisahkan koma)';

  @override
  String get pipelineInputDefaultLabel => 'Nilai default';

  @override
  String get pipelineInputPlaceholderLabel => 'Placeholder';

  @override
  String get pipelineInputHelpLabel => 'Teks bantuan';

  @override
  String get pipelineInputRequiredLabel => 'Wajib';

  @override
  String get pipelineInputTypeText => 'Teks';

  @override
  String get pipelineInputTypeMultiline => 'Teks multi-baris';

  @override
  String get pipelineInputTypeNumber => 'Angka';

  @override
  String get pipelineInputTypeBoolean => 'Sakelar';

  @override
  String get pipelineInputTypeSelect => 'Pilihan';

  @override
  String get pipelinesEmpty => 'Belum ada eksekusi pipeline';

  @override
  String get pipelinesEmptyHint => 'Klik \'Jalankan pipeline\' untuk memulai.';

  @override
  String get pipelinesNoSteps => 'Belum ada langkah yang tercatat';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Pilih ruang kerja untuk melihat pipelinenya';

  @override
  String pipelinesLoadError(String error) {
    return 'Gagal memuat pipeline: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Gagal memulai pipeline: $error';
  }

  @override
  String get pipelineStatusPending => 'Menunggu';

  @override
  String get pipelineStatusQueued => 'Dalam antrean';

  @override
  String get pipelineStatusRunning => 'Berjalan';

  @override
  String get pipelineStatusSuspended => 'Ditangguhkan';

  @override
  String get pipelineStatusCompleted => 'Selesai';

  @override
  String get pipelineStatusFailed => 'Gagal';

  @override
  String get pipelineStatusCancelled => 'Dibatalkan';

  @override
  String get pipelineStatusSkipped => 'Dilewati';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed dari $total langkah';
  }

  @override
  String get pipelineWaterfallTimeline => 'Linimasa';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'Aktif $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'idle $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'Waktu yang tidak dihitung ke total aktif: run dihentikan atau menunggu antar langkah.';

  @override
  String get pipelineStepStarted => 'Dimulai';

  @override
  String get pipelineStepFinished => 'Selesai';

  @override
  String get pipelineStepDurationLabel => 'Durasi';

  @override
  String get pipelineStepBranch => 'Branch';

  @override
  String get pipelineStepViewConversation => 'Lihat percakapan';

  @override
  String get pipelineStepError => 'Error';

  @override
  String get pipelineStepInput => 'Input';

  @override
  String get pipelineStepOutput => 'Output';

  @override
  String get pipelineStepNotExecuted => 'Belum dieksekusi';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Gagal di $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Manual';

  @override
  String get pipelineStepSkippedReason => 'Dilewati';

  @override
  String get pipelineStepPriorAttempts => 'Percobaan sebelumnya';

  @override
  String get pipelineStepAttemptLabel => 'Percobaan';

  @override
  String pipelineStepAttemptN(int number) {
    return 'Percobaan $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'Terputus';

  @override
  String get pipelineRunColumnPipeline => 'Pipeline';

  @override
  String get pipelineRunColumnDuration => 'Durasi';

  @override
  String get pipelineRunQueueNext => 'Berikutnya';

  @override
  String pipelineRunQueuePosition(int position) {
    return '$position dalam antrean';
  }

  @override
  String get pipelineRunColumnStarted => 'Dimulai';

  @override
  String get pipelineRunHistory => 'Riwayat run';

  @override
  String get pipelineRunHistoryEmpty => 'Belum ada run lain';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'Jalankan ulang $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return 'Percobaan $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'pertama dimulai $time';
  }

  @override
  String get pipelineRunFilterAll => 'Semua';

  @override
  String get pipelineRunFilterEmpty =>
      'Tidak ada run yang cocok dengan filter ini';

  @override
  String get relativeJustNow => 'baru saja';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mnt lalu',
      one: '1 mnt lalu',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jam lalu',
      one: '1 jam lalu',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari lalu',
      one: '1 hari lalu',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'Tim';

  @override
  String get teamsAddTeam => 'Tambah tim';

  @override
  String get teamsLoadError => 'Tidak dapat memuat tim';

  @override
  String get teamsEmptyTitle => 'Belum ada tim';

  @override
  String get teamsEmptyDescription =>
      'Kelompokkan agen ke dalam tim agar pekerjaan yang ditugaskan ke tim diteruskan melalui pemimpin yang mendelegasikan.';

  @override
  String get teamCreateTitle => 'Tim baru';

  @override
  String get teamEditTitle => 'Edit tim';

  @override
  String get teamNameLabel => 'Nama tim';

  @override
  String get teamNameHint => 'mis. Frontend';

  @override
  String get teamDescriptionLabel => 'Deskripsi';

  @override
  String get teamDescriptionHint => 'Tanggung jawab tim ini';

  @override
  String get teamLeaderLabel => 'Pemimpin';

  @override
  String get teamLeaderHelp =>
      'Koordinator yang menerima pekerjaan yang ditugaskan ke tim dan mendelegasikannya ke anggota yang paling sesuai.';

  @override
  String get teamNoLeader => 'Tidak ada pemimpin';

  @override
  String get teamInstructionsLabel => 'Instruksi operasional';

  @override
  String get teamInstructionsHelp =>
      'Ditambahkan ke briefing pemimpin — konvensi tim, aturan eskalasi, nada.';

  @override
  String get teamInstructionsHint => 'Opsional';

  @override
  String get teamSaved => 'Tim disimpan';

  @override
  String get teamMembersError => 'Tidak dapat memuat anggota';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count anggota',
      one: '1 anggota',
      zero: 'Tidak ada anggota',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'Tambah anggota';

  @override
  String get teamAddMemberTitle => 'Tambah anggota';

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
  String get teamNoAgentsToAdd => 'Semua agen sudah ada di tim ini.';

  @override
  String get teamRemoveMember => 'Hapus dari tim';

  @override
  String get teamLeaderBadge => 'Pemimpin';

  @override
  String get teamUnknownAgent => 'Agen tidak dikenal';

  @override
  String get teamMembersEmpty => 'Belum ada anggota';

  @override
  String get teamMembersEmptyDescription =>
      'Tambahkan agen agar pemimpin punya orang untuk didelegasikan.';

  @override
  String get teamSelectPrompt => 'Pilih tim';

  @override
  String get teamSelectPromptDescription =>
      'Pilih tim dari daftar, atau buat yang baru.';

  @override
  String get teamDeleteTitle => 'Hapus tim?';

  @override
  String teamDeleteBody(String name) {
    return '$name akan dihapus. Agensinya tidak terpengaruh.';
  }

  @override
  String get teamHasLeaderTooltip => 'Punya pemimpin';

  @override
  String get pipelineTemplatesNav => 'Template pipeline';

  @override
  String get pipelineTemplatesTitle => 'Template pipeline';

  @override
  String get pipelineTemplatesSubtitle =>
      'Editor seret-lepas untuk pipeline yang mengorkestrasi agen Anda.';

  @override
  String get pipelineTemplatesNew => 'Template baru';

  @override
  String get pipelineTemplatesEmpty =>
      'Belum ada template pipeline. Buat satu untuk memulai.';

  @override
  String get pipelineTemplateBuiltInBadge => 'Bawaan';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Hapus template?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Hapus template pipeline $name? Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Seret jenis node dari bilah sisi ke kanvas, lalu hubungkan.';

  @override
  String get unsavedChanges => 'Perubahan belum disimpan';

  @override
  String get nodeLibraryTitle => 'Pustaka node';

  @override
  String get nodeLibraryHint =>
      'Seret entri apa pun ke kanvas untuk menambahkan node.';

  @override
  String get editorEmptyCanvas => 'Seret node dari pustaka untuk memulai.';

  @override
  String get pipelineWhenThisHappens => 'Saat ini terjadi';

  @override
  String get pipelineDoThis => 'Lakukan ini';

  @override
  String get pipelineAddStep => 'Tambah langkah';

  @override
  String get pipelineTidyUp => 'Rapikan tata letak';

  @override
  String get pipelineEditorHint =>
      'Seret langkah untuk menyusun · seret gagang untuk menghubungkan';

  @override
  String get pipelineRemoveConnection => 'Hapus koneksi';

  @override
  String get pipelineDragToConnect => 'Seret untuk menghubungkan';

  @override
  String get pipelineNewDefaultName => 'Pipeline baru';

  @override
  String get nodeCategoryTriggers => 'Trigger';

  @override
  String get triggerEventWebhook => 'Webhook';

  @override
  String get pipelineAddTrigger => 'Tambah trigger';

  @override
  String get pipelineOnEvent => 'Pada event';

  @override
  String get nodeConfigTitle => 'Konfigurasi node';

  @override
  String get nodeConfigKind => 'Jenis';

  @override
  String get nodeConfigLabel => 'Label';

  @override
  String get nodeConfigAgent => 'Agen';

  @override
  String get nodeConfigAgentHint => 'Pilih agen…';

  @override
  String get nodeConfigInputKeys => 'Kunci input (dipisah koma)';

  @override
  String get nodeConfigInputKeysHelp =>
      'Kunci state yang dikonsumsi node ini. Dipakai untuk substitusi placeholder di prompt.';

  @override
  String get nodeConfigRepos => 'Repositori yang akan diklon';

  @override
  String get nodeConfigReposHelp =>
      'Repo diklon dan diindeks kodenya saat node ini memulai percakapan. Memilih setiap repo akan mengkloning semuanya (nilai default).';

  @override
  String get nodeConfigRepoBranchHint => 'Branch (default)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'Branch sumber setiap checkout. Kosongkan untuk memakai branch default repo — pohon kerja tetap mendapat branch sendiri, jadi commit agen tidak masuk ke branch ini.';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'Entri dinamis yang dipertahankan: $entries';
  }

  @override
  String get nodeConfigCreateConversation => 'Buka percakapan di dalamnya';

  @override
  String get nodeConfigCreateConversationHelp =>
      'Matikan opsi ini jika beberapa node agen mengikuti — masing-masing membuka stream bernama sendiri. Nyalakan jika hanya satu node agen yang mengikuti, agar ruang tidak menampilkan percakapan tanpa judul di sampingnya.';

  @override
  String get nodeConfigConversationTitle => 'Nama percakapan';

  @override
  String get nodeConfigConversationTitleHelp =>
      'Beri node agen di downstream nama yang sama agar keduanya bekerja di satu stream. Default-nya label node.';

  @override
  String get nodeConfigSpaceName => 'Nama space';

  @override
  String get nodeConfigSpaceNameHelp =>
      'Nama ruang yang dibuka node ini. Mendukung placeholder state yang sama seperti prompt. Kosongkan untuk memakai label node.';

  @override
  String get nodeConfigSpaceNameHint => 'Tinjauan pr_number';

  @override
  String get nodeConfigStreamTitle => 'Nama percakapan';

  @override
  String get nodeConfigStreamTitleHelp =>
      'Stream bernama tempat agen node ini bekerja di dalam ruang. Mendukung placeholder state yang sama seperti prompt. Kosongkan agar giliran masuk ke percakapan tetap ruang, tempat fan-out menyisipkan setiap agen.';

  @override
  String get nodeConfigConversationTitleHint => 'Analisis arsitektur';

  @override
  String get nodeConfigOutputKey => 'Kunci output';

  @override
  String get nodeConfigPrompt => 'Template prompt';

  @override
  String get nodeConfigPromptHelp =>
      'Gunakan placeholder kurung kurawal ganda untuk mengambil nilai dari state saat runtime.';

  @override
  String get nodeConfigScript => 'Skrip bash';

  @override
  String get nodeConfigScriptHelp =>
      'Dijalankan dengan bash -c. GITHUB_TOKEN disetel. Placeholder disubstitusi sebelum eksekusi.';

  @override
  String get nodeConfigRouteKeys => 'Kunci rute';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Kunci rute dari $source';
  }

  @override
  String get conditionSectionTitle => 'Kondisi';

  @override
  String get conditionMode => 'Mode';

  @override
  String get conditionModeFilesAny => 'File ada — salah satu';

  @override
  String get conditionModeFilesAll => 'File ada — semua';

  @override
  String get conditionModeComparison => 'Perbandingan';

  @override
  String get conditionModeSwitch => 'Alih';

  @override
  String get conditionFilePaths => 'Jalur file';

  @override
  String get conditionFilePathsAnyHelp =>
      'Satu jalur per baris, relatif ke direktori dasar. Benar jika salah satu ada.';

  @override
  String get conditionFilePathsAllHelp =>
      'Satu jalur per baris, relatif ke direktori dasar. Benar hanya jika semua ada.';

  @override
  String get conditionBaseKey => 'Kunci direktori dasar';

  @override
  String get conditionBaseKeyHelp =>
      'Kunci state yang berisi direktori tempat jalur diselesaikan (default repo_local_path).';

  @override
  String get conditionRecursive => 'Cari subdirektori';

  @override
  String get conditionNegate => 'Balik: benar jika tidak ada';

  @override
  String get conditionLeft => 'Nilai kiri';

  @override
  String get conditionOperator => 'Operator';

  @override
  String get conditionRight => 'Nilai kanan';

  @override
  String get conditionSwitchKey => 'Alih berdasarkan kunci state';

  @override
  String get conditionCases => 'Kasus (dipisah koma)';

  @override
  String get conditionCasesHelp =>
      'Kunci rute yang dicocokkan dengan nilai, berurutan.';

  @override
  String get conditionDefaultCase => 'Kasus default';

  @override
  String get triggerManualHelp =>
      'Tampilkan di halaman run dan mulai secara manual.';

  @override
  String get triggerKindSchedule => 'Pada jadwal';

  @override
  String get triggerScheduleExprLabel => 'Jadwal (cron atau every:seconds)';

  @override
  String get triggerTimezoneLabel => 'Zona waktu (opsional)';

  @override
  String get triggerCatchUpLabel => 'Jika run terlewat';

  @override
  String get triggerCatchUpRunOnce => 'Jalankan sekali';

  @override
  String get triggerCatchUpSkip => 'Lewati';

  @override
  String get syncHealthTitle => 'Kesehatan sinkronisasi';

  @override
  String get syncHealthNoConfigs => 'Belum ada koneksi sinkronisasi';

  @override
  String get syncHealthNeverSynced => 'Belum pernah disinkronkan';

  @override
  String get syncOutcomeOk => 'Disinkronkan';

  @override
  String get syncOutcomeFailed => 'Gagal';

  @override
  String get syncOutcomeSkipped => 'Dilewati';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count kegagalan berturut-turut';
  }

  @override
  String get triggerWebhookHelp =>
      'URL webhook bertanda tangan akan dibuat. Sistem eksternal POST ke URL itu untuk memulai pipeline ini.';

  @override
  String get triggerWebhookPathLabel => 'Jalur webhook';

  @override
  String get triggerMatchStatusLabel => 'Hanya jika statusnya';

  @override
  String get triggerSummaryNone => 'Tidak ada trigger';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Setiap ${seconds}d';
  }

  @override
  String get triggerEventManual => 'Run manual';

  @override
  String get triggerEventSchedule => 'Jadwal';

  @override
  String get triggerEventPrStatusChanged => 'Status PR berubah';

  @override
  String get triggerEventExternalPr => 'PR eksternal dibuka';

  @override
  String get triggerEventPrPublished => 'PR dipublikasikan';

  @override
  String get triggerEventPrMerged => 'PR digabung';

  @override
  String get triggerEventRepoAdded => 'Repositori ditambah';

  @override
  String get triggerEventCodeGraphWatch => 'Perubahan file';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file berubah',
      one: '1 file berubah',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '+$count lagi';
  }

  @override
  String get pipelineRunCauseRescan => 'Berubah di disk';

  @override
  String get pipelineRunCauseInitial => 'Indeks pertama checkout ini';

  @override
  String get triggerEventMessageReceived => 'Pesan diterima';

  @override
  String get triggerEventTicketCompleted => 'Tiket selesai';

  @override
  String get triggerEventTicketFailed => 'Tiket gagal';

  @override
  String get triggerEventTicketCancelled => 'Tiket dibatalkan';

  @override
  String get triggerEventBudgetCrossed => 'Ambang anggaran terlampaui';

  @override
  String get nodeLibrarySearchHint => 'Cari node';

  @override
  String get nodeLibraryNoMatches => 'Tidak ada node yang cocok';

  @override
  String get nodeCategoryFlow => 'Alur & logika';

  @override
  String get nodeCategoryPr => 'Tinjauan PR';

  @override
  String get nodeCategoryAgents => 'Agen';

  @override
  String get nodeCategoryMessaging => 'Pesan';

  @override
  String get nodeCategoryCode => 'Kode';

  @override
  String get triggerDisabledTag => 'mati';

  @override
  String get pipelineInputTypeRepo => 'Repository';

  @override
  String get pipelineRunNoRepos => 'Belum ada repository di ruang kerja ini.';

  @override
  String get allowTicketingApi => 'Izinkan panggilan API ticketing';

  @override
  String get ticketingApiKey => 'Kunci API ticketing';

  @override
  String get ticketingApiKeySubtitle =>
      'Menyuntikkan kunci API penyedia ticketing ke sandbox.';

  @override
  String get ticketingProvider => 'Penyedia ticketing';

  @override
  String get connectGitHubAndTicketing =>
      'Hubungkan code host agar Control Center dapat membaca pull request, issue, dan tinjauan Anda. Secara opsional hubungkan penyedia ticketing. Kredensial disimpan di server Anda, bukan di mesin ini.';

  @override
  String get triggerEventTicketAssigned => 'Tiket ditugaskan';

  @override
  String get triggerEventTicketCreated => 'Tiket dibuat';

  @override
  String get triggerEventTicketStatusChanged => 'Status tiket berubah';

  @override
  String get triggerEventMeetingRecordingStopped => 'Rekaman rapat dihentikan';

  @override
  String get triggerEventSkillUpdated => 'Skill diperbarui';

  @override
  String get triggerEventSpaceDeleted => 'Ruang dihapus';

  @override
  String get triggerExternalPrHelp =>
      'Pull request yang dibuka di host kode, bukan dari Control Center.';

  @override
  String get triggerPrPublishedHelp =>
      'Pull request yang dibuka dari Control Center atau oleh agen.';

  @override
  String get triggerPrStatusChangedHelp =>
      'Digabung, ditutup, dibuka, dibuka ulang, atau disetujui. Filter menurut status di inspector.';

  @override
  String get triggerPrMergedHelp =>
      'Hanya saat pull request digabung, bukan ditutup atau dibuka ulang.';

  @override
  String get triggerRepoAddedHelp => 'Repositori ditautkan ke ruang kerja ini.';

  @override
  String get triggerCodeGraphWatchHelp =>
      'File di repositori tertaut berubah di disk.';

  @override
  String get triggerMessageReceivedHelp => 'Pesan baru tiba di sebuah ruang.';

  @override
  String get triggerTicketCreatedHelp => 'Tiket dibuat di ruang kerja ini.';

  @override
  String get triggerTicketStatusChangedHelp => 'Tiket berpindah antar status.';

  @override
  String get triggerTicketCompletedHelp => 'Tiket selesai dengan sukses.';

  @override
  String get triggerTicketFailedHelp =>
      'Jalankan agen gagal dan tiket ditandai gagal.';

  @override
  String get triggerTicketCancelledHelp =>
      'Tiket dibatalkan dan tidak akan dilanjutkan.';

  @override
  String get triggerBudgetCrossedHelp =>
      'Batas belanja ruang kerja atau agen terlampaui.';

  @override
  String get triggerTicketAssignedHelp =>
      'Tiket ditetapkan ke orang, agen, atau tim.';

  @override
  String get triggerMeetingRecordingStoppedHelp => 'Rekaman rapat selesai.';

  @override
  String get triggerSkillUpdatedHelp =>
      'Keterampilan dipasang atau diperbarui.';

  @override
  String get triggerSpaceDeletedHelp => 'Ruang percakapan dihapus.';

  @override
  String get navTickets => 'Tiket';

  @override
  String get ticketsTitle => 'Tiket';

  @override
  String get newTicket => 'Tiket baru';

  @override
  String get noTicketsYet => 'Belum ada tiket';

  @override
  String get addCollaborator => 'Tambah kolaborator';

  @override
  String get noCollaborators => 'Belum ada kolaborator';

  @override
  String get linkedPullRequests => 'Pull request tertaut';

  @override
  String get noLinkedPullRequests => 'Belum ada pull request tertaut';

  @override
  String get stopAgent => 'Hentikan agen';

  @override
  String get ticketProperties => 'Properti';

  @override
  String get ticketTabIssue => 'Issue';

  @override
  String get ticketSelectPrompt => 'Pilih tiket untuk melihat detailnya';

  @override
  String get unassigned => 'Belum ditugaskan';

  @override
  String get ticketStatusBacklog => 'Backlog';

  @override
  String get ticketStatusOpen => 'To do';

  @override
  String get ticketStatusInProgress => 'Sedang dikerjakan';

  @override
  String get ticketStatusInReview => 'Sedang ditinjau';

  @override
  String get ticketStatusDone => 'Selesai';

  @override
  String get ticketStatusBlocked => 'Terblokir';

  @override
  String get ticketStatusFailed => 'Gagal';

  @override
  String get ticketStatusCancelled => 'Dibatalkan';

  @override
  String get notificationTicketAssigned => 'Tiket ditugaskan';

  @override
  String get notificationTicketStatusChanged => 'Status tiket berubah';

  @override
  String get priority => 'Prioritas';

  @override
  String get status => 'Status';

  @override
  String get assignee => 'Penerima tugas';

  @override
  String get labels => 'Label';

  @override
  String get noLabelsYet => 'Belum ada label';

  @override
  String get clearLabels => 'Hapus label';

  @override
  String get pipelineStepAgentActivity => 'Aktivitas agen';

  @override
  String get runStatusCompleted => 'Selesai';

  @override
  String get runStatusQueued => 'Dalam antrean';

  @override
  String get ticketDescription => 'Deskripsi';

  @override
  String get ticketPriorityNone => 'Tidak ada';

  @override
  String get ticketPriorityUrgent => 'Mendesak';

  @override
  String get ticketPriorityHigh => 'Tinggi';

  @override
  String get ticketPriorityMedium => 'Sedang';

  @override
  String get ticketPriorityLow => 'Rendah';

  @override
  String get ticketViewList => 'Daftar';

  @override
  String get ticketViewBoard => 'Papan';

  @override
  String get ticketTitlePlaceholder => 'Judul issue';

  @override
  String get ticketDescriptionPlaceholder => 'Tambahkan deskripsi…';

  @override
  String get createMore => 'Buat lagi';

  @override
  String selectedCount(int count) {
    return '$count dipilih';
  }

  @override
  String get clearSelection => 'Hapus pilihan';

  @override
  String get bulkDeleteTitle => 'Hapus tiket';

  @override
  String bulkDeleteMessage(int count) {
    return 'Hapus $count tiket yang dipilih? Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get assignTo => 'Tugaskan ke…';

  @override
  String get sectionMembers => 'Anggota';

  @override
  String get sectionAgents => 'Agen';

  @override
  String get sidebarGroupWorkspace => 'Ruang kerja';

  @override
  String get notificationsTitle => 'Notifikasi';

  @override
  String get notificationsTooltip => 'Notifikasi';

  @override
  String get notificationsEmpty => 'Semua sudah dibaca';

  @override
  String notificationsUnreadCount(int count) {
    return '$count belum dibaca';
  }

  @override
  String get notificationsMarkRead => 'Tandai sudah dibaca';

  @override
  String get notificationsMarkUnread => 'Tandai belum dibaca';

  @override
  String get notificationsEntryActions => 'Tindakan notifikasi';

  @override
  String get markAllRead => 'Tandai semua sudah dibaca';

  @override
  String get teamsNav => 'Tim';

  @override
  String get noWorkspace => 'Tidak ada ruang kerja';

  @override
  String get selectWorkspace => 'Pilih ruang kerja';

  @override
  String get navMemory => 'Memori';

  @override
  String get memoryTabFacts => 'Fakta';

  @override
  String get memoryTabPolicies => 'Kebijakan';

  @override
  String get memoryGraphShowFacts => 'Tampilkan fakta';

  @override
  String get memoryGraphHideFacts => 'Sembunyikan fakta';

  @override
  String get memoryGraphExpandAll => 'Perluas semua fakta';

  @override
  String get memoryGraphCollapseAll => 'Ciutkan semua fakta';

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
  String get removeFromSaved => 'Hapus dari simpanan';

  @override
  String get filterBySource => 'Filter berdasarkan sumber';

  @override
  String get viewAsList => 'Tampilan daftar';

  @override
  String get viewAsGrid => 'Tampilan kisi';

  @override
  String get noMatchingArticles => 'Tidak ada artikel yang cocok';

  @override
  String get noMatchingArticlesBody =>
      'Coba pencarian atau filter sumber lain.';

  @override
  String get allCaughtUp => 'Semua sudah dibaca';

  @override
  String get allCaughtUpBody =>
      'Tidak ada artikel yang belum dibaca — periksa lagi nanti.';

  @override
  String get openArticlesInAppDescription =>
      'Buka tautan di pembaca bawaan, bukan di browser default.';

  @override
  String get blockAdsTrackersDescription =>
      'Hapus iklan, pelacak, dan spanduk cookie dari artikel yang dibuka di pembaca.';

  @override
  String get agentQuestionHeader => 'Pertanyaan untuk Anda';

  @override
  String get agentQuestionAnsweredLabel => 'Dijawab';

  @override
  String get agentQuestionFreeformHint => 'Ketik jawaban Anda…';

  @override
  String agentQuestionProgress(int index, int count) {
    return 'Pertanyaan $index dari $count';
  }

  @override
  String get agentQuestionSkip => 'Lewati';

  @override
  String get agentQuestionSkippedLabel => 'Dilewati';

  @override
  String get agentQuestionFreeformOptionHint =>
      'Jelaskan dengan kata-kata Anda…';

  @override
  String get reviewRequested => 'Tinjauan diminta';

  @override
  String get connectGitHubHint =>
      'Masuk ke GitHub atau tambahkan token di Settings → You → Profile & identity → Code hosting';

  @override
  String get connectGitHubToLoadPrs =>
      'Hubungkan GitHub untuk memuat pull request';

  @override
  String get noRepositoriesConfigured =>
      'Tidak ada repositori yang dikonfigurasi';

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
    return '$actor meminta tinjauan dari $reviewers';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor menghapus permintaan tinjauan untuk $reviewers';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor meminta tinjauan dari $requested dan menghapus permintaan tinjauan untuk $removed';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'label',
      one: 'label',
    );
    return '$actor menambahkan $_temp0 $labels';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'label',
      one: 'label',
    );
    return '$actor menghapus $_temp0 $labels';
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
    return '$actor menambahkan $_temp0 $added dan menghapus $_temp1 $removed';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author melakukan commit';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commit',
      one: '1 commit',
    );
    return '$author mendorong $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author menyetujui perubahan ini';
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
      other: '$count komentar kode',
      one: '1 komentar kode',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author meninjau';
  }

  @override
  String get prTimelineSomeone => 'Seseorang';

  @override
  String get prTimelineBotBadge => 'bot';

  @override
  String updatedAgo(String age) {
    return 'Diperbarui $age';
  }

  @override
  String get checksPassing => 'Pemeriksaan lulus';

  @override
  String get checksRunning => 'Pemeriksaan berjalan';

  @override
  String get needsYourReview => 'Perlu tinjauan Anda';

  @override
  String get checks => 'Pemeriksaan';

  @override
  String get noReviewersAssigned => 'Tidak ada peninjau';

  @override
  String get noAssignees => 'Tidak ada penerima tugas';

  @override
  String get loadingEllipsis => 'Memuat…';

  @override
  String get loadingChecks => 'Memuat pemeriksaan…';

  @override
  String get noChecksYet => 'Belum ada pemeriksaan yang dijalankan';

  @override
  String get noChangesToReview => 'Tidak ada perubahan untuk ditinjau';

  @override
  String checksFailingCount(int count) {
    return '$count gagal';
  }

  @override
  String get showMore => 'Tampilkan lebih banyak';

  @override
  String get showLess => 'Tampilkan lebih sedikit';

  @override
  String get backToPullRequests => 'Kembali ke pull request';

  @override
  String get pullRequestNotFound => 'Pull request tidak ditemukan';

  @override
  String get pullRequestNotFoundBody =>
      'Mungkin sudah digabungkan, ditutup, atau dipindahkan.';

  @override
  String get couldntLoadPullRequest => 'Tidak dapat memuat pull request ini';

  @override
  String get showDetails => 'Tampilkan detail';

  @override
  String get noDescriptionProvided => 'Tidak ada deskripsi.';

  @override
  String get factsHint =>
      'Fakta akan muncul di sini seiring agen Anda belajar.';

  @override
  String get noFactsMatch => 'Tidak ada fakta yang cocok dengan pencarian Anda';

  @override
  String get memoryLoadError => 'Tidak dapat memuat memori';

  @override
  String get sortRecent => 'Terbaru';

  @override
  String get sortConfidence => 'Keyakinan';

  @override
  String get confidenceTooltip =>
      'Seberapa yakin agen bahwa fakta ini benar, dari 0 hingga 100%.';

  @override
  String get supersededTooltip =>
      'Fakta yang lebih baru telah menggantikan fakta ini.';

  @override
  String get domain => 'Domain';

  @override
  String get fitToView => 'Sesuaikan dengan tampilan';

  @override
  String get project => 'Proyek';

  @override
  String get newProject => 'Proyek baru';

  @override
  String get editProject => 'Edit proyek';

  @override
  String get deleteProject => 'Hapus proyek';

  @override
  String get noProject => 'Tidak ada proyek';

  @override
  String get allTickets => 'Semua tiket';

  @override
  String get projectNamePlaceholder => 'Nama proyek';

  @override
  String get projectDescriptionPlaceholder => 'Deskripsi (opsional)';

  @override
  String get projectColorLabel => 'Warna';

  @override
  String get noProjectsYet => 'Belum ada proyek';

  @override
  String get projectTicketsEmpty => 'Belum ada tiket di proyek ini';

  @override
  String get createProject => 'Buat proyek';

  @override
  String projectProgress(int done, int total) {
    return '$done dari $total selesai';
  }

  @override
  String deleteProjectConfirm(String name) {
    return 'Hapus \"$name\"? Tiketnya tetap ada dan dilepas dari proyek.';
  }

  @override
  String get projectStatusActive => 'Aktif';

  @override
  String get projectStatusCompleted => 'Selesai';

  @override
  String get projectStatusArchived => 'Diarsipkan';

  @override
  String get markProjectCompleted => 'Tandai selesai';

  @override
  String get markProjectActive => 'Tandai aktif';

  @override
  String get archiveProject => 'Arsipkan';

  @override
  String get restoreProject => 'Pulihkan';

  @override
  String get relations => 'Relasi';

  @override
  String get relateTo => 'Hubungkan ke';

  @override
  String get relationSubIssueOf => 'Sub-isu dari…';

  @override
  String get relationParentOf => 'Induk dari…';

  @override
  String get relationBlockedBy => 'Diblokir oleh…';

  @override
  String get relationBlocking => 'Memblokir…';

  @override
  String get relationRelatedTo => 'Terkait dengan…';

  @override
  String get relationDuplicateOf => 'Duplikat dari…';

  @override
  String get relationGroupParent => 'Induk';

  @override
  String get relationGroupSubIssues => 'Sub-tiket';

  @override
  String get relationGroupBlockedBy => 'Diblokir oleh';

  @override
  String get relationGroupBlocking => 'Memblokir';

  @override
  String get relationGroupRelated => 'Terkait';

  @override
  String get relationGroupDuplicateOf => 'Duplikat dari';

  @override
  String get relationGroupDuplicatedBy => 'Diduplikasi oleh';

  @override
  String get copyId => 'Salin ID';

  @override
  String get ticketIdCopied => 'ID tiket disalin';

  @override
  String get searchTicketsHint => 'Cari tiket…';

  @override
  String get noMatchingTickets => 'Tidak ada tiket yang cocok';

  @override
  String get clearAll => 'Hapus semua';

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
    return '$_temp0 menunggu tinjauan Anda di $_temp1';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'Ubah nama ruang kerja dan tandanya — pilih satu di kiri untuk mengedit.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ruang kerja',
      one: '1 ruang kerja',
      zero: 'Tidak ada ruang kerja',
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
      zero: 'Tidak ada repo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents agen',
      one: '1 agen',
      zero: '0 agen',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'Identitas';

  @override
  String get uploadImage => 'Unggah gambar';

  @override
  String get failedToSaveLogo =>
      'Gagal menyimpan gambar logo. Pastikan aplikasi dapat membaca file yang dipilih.';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG, atau GIF hingga 2 MB. Jika tidak, kami memakai inisial ruang kerja.';

  @override
  String get workspaceNameFieldHelp =>
      'Ditampilkan di switcher, breadcrumb, dan setiap layar.';

  @override
  String get dangerZone => 'Zona berbahaya';

  @override
  String get deleteThisWorkspace => 'Hapus ruang kerja ini';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Menghapus $name secara permanen, termasuk koneksi repositori, agen, dan memorinya. Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get discard => 'Buang';

  @override
  String discardChangesQuestion(String name) {
    return 'Buang perubahan yang belum disimpan pada $name?';
  }

  @override
  String get workspaceUpdated => 'Ruang kerja diperbarui';

  @override
  String get editTitle => 'Edit judul';

  @override
  String get editDescription => 'Edit deskripsi';

  @override
  String get addDescription => 'Tambah deskripsi';

  @override
  String get prTitlePlaceholder => 'Judul';

  @override
  String get prBodyPlaceholder => 'Tulis deskripsi';

  @override
  String get write => 'Tulis';

  @override
  String get overview => 'Ikhtisar';

  @override
  String get noFilesChanged => 'Tidak ada file yang diubah';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Pratinjau';

  @override
  String get outdated => 'Usang';

  @override
  String get outdatedComments => 'Komentar usang';

  @override
  String outdatedCountLabel(int count) {
    return '$count usang';
  }

  @override
  String get prTemplateLabel => 'Template';

  @override
  String get prTemplateDefault => 'Default';

  @override
  String get addReviewers => 'Tambah peninjau';

  @override
  String get addAssignees => 'Tambah penerima tugas';

  @override
  String get searchUsers => 'Cari orang…';

  @override
  String get searchReviewers => 'Cari orang dan tim…';

  @override
  String get usersSectionLabel => 'Orang';

  @override
  String get userStatusBusy => 'Sibuk';

  @override
  String get teamsSectionLabel => 'Tim';

  @override
  String get suggestedReviewers => 'Peninjau yang disarankan';

  @override
  String get noMatchingUsers => 'Tidak ada orang yang cocok';

  @override
  String get noMatchingReviewers => 'Tidak ada yang cocok';

  @override
  String get requiredByCodeOwners => 'Wajib menurut code owners';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'via $login';
  }

  @override
  String get team => 'Tim';

  @override
  String get markdownBold => 'Tebal';

  @override
  String get markdownItalic => 'Miring';

  @override
  String get markdownHeading => 'Judul';

  @override
  String get markdownBulletList => 'Daftar berpoin';

  @override
  String get markdownChecklist => 'Daftar centang';

  @override
  String get markdownCode => 'Kode';

  @override
  String get markdownLink => 'Tautan';

  @override
  String get markdownQuote => 'Kutipan';

  @override
  String get markdownSupported => 'Markdown didukung';

  @override
  String get markdownAttachImages => 'Klik untuk menambah gambar';

  @override
  String failedToUpdateTitle(String error) {
    return 'Tidak bisa memperbarui judul: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Tidak bisa memperbarui deskripsi: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Tidak bisa memperbarui reviewer: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Tidak bisa memperbarui assignee: $error';
  }

  @override
  String get discardChangesConfirm => 'Buang perubahan?';

  @override
  String get newPr => 'PR baru';

  @override
  String get openPullRequest => 'Buka pull request';

  @override
  String get composePrSubtitle =>
      'Dari branch yang sudah Anda push — tanpa agen atau tiket';

  @override
  String get createAsDraft => 'Buat sebagai draf';

  @override
  String get composePrNoRepo => 'Belum ada repositori GitHub yang dipilih';

  @override
  String get composePrNoRepoHint =>
      'Pilih ruang kerja dengan repositori tertaut GitHub untuk membuka pull request.';

  @override
  String get composePrPickBranches =>
      'Pilih branch basis dan pembanding untuk melihat pratinjau perubahan.';

  @override
  String get composePrNothingToCompare =>
      'Tidak ada perubahan antara branch ini.';

  @override
  String get repository => 'Repositori';

  @override
  String get baseBranchLabel => 'Basis';

  @override
  String get compareBranchLabel => 'Bandingkan';

  @override
  String get selectBranch => 'Pilih branch';

  @override
  String get navMeetings => 'Rapat';

  @override
  String get meetingsNoWorkspace => 'Pilih ruang kerja untuk melihat rapat.';

  @override
  String get meetingsEmpty => 'Belum ada rapat';

  @override
  String get meetingsEmptyHint =>
      'Rekam rapat pertama Anda — audio tetap di perangkat ini dan agen mengubahnya menjadi catatan, keputusan, dan item tindakan.';

  @override
  String get meetingNotesHint =>
      'Tulis catatan singkat — agen mengembangkannya setelah rapat.';

  @override
  String get meetingSpeakerMe => 'Anda';

  @override
  String get meetingStatusRecording => 'Merekam';

  @override
  String get meetingStatusProcessing => 'Memproses';

  @override
  String get meetingStatusDone => 'Selesai';

  @override
  String get meetingStatusFailed => 'Gagal';

  @override
  String get meetingsSubtitle =>
      'Direkam dan ditranskripsi di perangkat ini, lalu diringkas oleh agen.';

  @override
  String get meetingsRecordMeeting => 'Rekam rapat';

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
      other: '$count rapat',
      one: '1 rapat',
      zero: 'Tidak ada rapat',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'Tindakan terbuka';

  @override
  String get meetingsLedgerDecisions => 'Keputusan';

  @override
  String get meetingsLiveOpen => 'Buka rekaman';

  @override
  String get meetingTemplateShort => 'Templat';

  @override
  String get meetingsStatThisWeek => 'Minggu ini';

  @override
  String get meetingsStatRecorded => 'Direkam';

  @override
  String get meetingsFilterAll => 'Semua';

  @override
  String get meetingsFilterDone => 'Selesai';

  @override
  String get meetingsFilterProcessing => 'Memproses';

  @override
  String get meetingsSearchHint => 'Filter menurut judul, orang, aplikasi…';

  @override
  String get meetingsBucketToday => 'Hari ini';

  @override
  String get meetingsBucketYesterday => 'Kemarin';

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
  String get meetingsEnhancedPill => 'ditingkatkan';

  @override
  String get meetingsTranscribing => 'mentranskripsi & merangkum…';

  @override
  String get meetingsOpenAction => 'Buka';

  @override
  String get meetingsStopProcessing => 'Berhenti';

  @override
  String get meetingsStillTranscribing =>
      'Masih mentranskripsi — ringkasan muncul setelah selesai.';

  @override
  String get meetingsNoMatch => 'Tidak ada rapat yang cocok';

  @override
  String get meetingsNoMatchHint => 'Coba filter atau kata pencarian lain.';

  @override
  String get meetingBackAllMeetings => 'Semua rapat';

  @override
  String get meetingReRunSummary => 'Jalankan ulang ringkasan';

  @override
  String get meetingExport => 'Ekspor';

  @override
  String get meetingAugmentingBanner =>
      'Melengkapi catatan dari transkrip — mengekstrak keputusan dan item tindakan…';

  @override
  String get meetingTabNotes => 'Catatan';

  @override
  String get meetingTabTranscript => 'Transkrip';

  @override
  String get meetingTabActionItems => 'Item tindakan';

  @override
  String get meetingTabDecisions => 'Keputusan';

  @override
  String get meetingNotesEnhancedToggle => 'Disempurnakan';

  @override
  String get meetingNotesYoursToggle => 'Catatan Anda';

  @override
  String get meetingEnhancedByAgent =>
      'Disempurnakan oleh agen · dari transkrip';

  @override
  String get meetingEnhancedPending => 'Agen masih mengerjakan ringkasan ini.';

  @override
  String get meetingNotesEmpty => 'Belum ada catatan yang disempurnakan.';

  @override
  String get meetingNotesSavedLocally => 'Disimpan secara lokal';

  @override
  String get meetingNotesSaving => 'Menyimpan…';

  @override
  String get meetingViewFullTranscript => 'Lihat transkrip lengkap';

  @override
  String get meetingTranscriptSearchHint => 'Cari di transkrip…';

  @override
  String get meetingSpeakerEveryone => 'Semua orang';

  @override
  String get meetingSpeakerOthers => 'Lainnya';

  @override
  String get meetingTranscriptEmpty => 'Belum ada transkrip.';

  @override
  String get meetingActionItemsEmpty =>
      'Tidak ada item tindakan yang diekstrak.';

  @override
  String get meetingActionItemFrom => 'dari rapat ini';

  @override
  String get meetingCreateTicket => 'Buat tiket';

  @override
  String meetingTicketCreated(String key) {
    return 'Tiket $key dibuat dan dikirim.';
  }

  @override
  String get meetingTicketFailed => 'Tidak dapat membuat tiket.';

  @override
  String get meetingDecisionsEmpty => 'Tidak ada keputusan yang dicatat.';

  @override
  String get meetingEditTitle => 'Edit judul';

  @override
  String get meetingTitleLabel => 'Judul';

  @override
  String get meetingAddActionItem => 'Tambah item tindakan';

  @override
  String get meetingEditActionItem => 'Edit item tindakan';

  @override
  String get meetingDeleteActionItem => 'Hapus item tindakan';

  @override
  String get meetingActionItemContentLabel => 'Item tindakan';

  @override
  String get meetingActionItemContentHint => 'Apa yang perlu dilakukan?';

  @override
  String get meetingActionItemOwnerLabel => 'Pemilik';

  @override
  String get meetingActionItemOwnerHint =>
      'Siapa yang bertanggung jawab? (opsional)';

  @override
  String get meetingAddDecision => 'Tambah keputusan';

  @override
  String get meetingEditDecision => 'Edit keputusan';

  @override
  String get meetingDeleteDecision => 'Hapus keputusan';

  @override
  String get meetingDecisionContentLabel => 'Keputusan';

  @override
  String get meetingDecisionContentHint => 'Apa yang diputuskan?';

  @override
  String get meetingReRunStarted =>
      'Menjalankan ulang peringkas pada transkrip…';

  @override
  String get meetingReRunNoTranscript => 'Belum ada transkrip untuk diringkas.';

  @override
  String get meetingExportCopied =>
      'Catatan disalin ke papan klip sebagai Markdown.';

  @override
  String get meetingExportSaved => 'Rapat diekspor.';

  @override
  String meetingExportFailed(String error) {
    return 'Ekspor gagal: $error';
  }

  @override
  String get meetingExportNothing => 'Belum ada yang bisa diekspor.';

  @override
  String get meetingPlaybackPlay => 'Putar';

  @override
  String get meetingPlaybackPause => 'Jeda';

  @override
  String get meetingPlaybackUnavailable =>
      'Pemutaran audio tidak tersedia di perangkat ini.';

  @override
  String get meetingDetectedTitle => 'Rapat terdeteksi';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'Sepertinya \"$label\" sedang berlangsung. Rekam?';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'Sepertinya ada rapat yang sedang berlangsung. Rekam?';

  @override
  String get meetingDetectedRecord => 'Rekam';

  @override
  String get meetingDetectedDismiss => 'Abaikan';

  @override
  String get meetingAutoStopTitle =>
      'Rapat ini sepertinya sudah selesai. Hentikan rekaman?';

  @override
  String get meetingAutoStopStop => 'Berhenti';

  @override
  String get meetingAutoStopKeep => 'Tetap merekam';

  @override
  String get meetingAutoDetect => 'Deteksi rapat otomatis';

  @override
  String get meetingAutoDetectDescription =>
      'Pantau kalender dan aplikasi konferensi, lalu tawarkan merekam saat rapat dimulai.';

  @override
  String get meetingsRecordingCrumb => 'Merekam…';

  @override
  String get meetingRecordTitleHint => 'Judul rapat';

  @override
  String get meetingRecordTappingLabel => 'Menyadap:';

  @override
  String get meetingRecordMic => 'Mik';

  @override
  String get meetingRecordSystemAudio => 'Audio sistem';

  @override
  String get meetingRecordPause => 'Jeda';

  @override
  String get meetingRecordResume => 'Lanjutkan';

  @override
  String get meetingRecordStop => 'Hentikan & rangkum';

  @override
  String get meetingRecordYourNotes => 'Catatan Anda';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Ketik sambil mendengarkan. Beberapa fragmen sudah cukup — setelah dihentikan, agen mengembangkannya memakai transkrip.';

  @override
  String get meetingRecordLiveTranscript => 'Transkrip langsung';

  @override
  String get meetingRecordDecoding => 'dekode di perangkat';

  @override
  String get meetingRecordListening =>
      'Mendengarkan… ucapan muncul di sini dalam satu-dua detik, ditandai Anda / Orang lain.';

  @override
  String get meetingRecordPausedHint =>
      'Dijeda — audio diabaikan sampai Anda lanjutkan.';

  @override
  String get meetingRecordNotActive => 'Tidak ada rekaman aktif.';

  @override
  String get meetingHudRecording => 'merekam';

  @override
  String get meetingHudPaused => 'dijeda';

  @override
  String get meetingHudOpen => 'Buka';

  @override
  String get meetingHudStop => 'Hentikan';

  @override
  String get meetingToolbarPopOut => 'Keluarkan';

  @override
  String get meetingToolbarHoldToStop => 'Tahan untuk menghentikan rekaman';

  @override
  String get meetingToolbarSemanticLabel => 'Bilah alat rekaman rapat';

  @override
  String get orchestrate => 'Orkestrasikan';

  @override
  String get orchestrationUnavailable => 'Orkestrasi tidak tersedia';

  @override
  String get orchestrationApprove => 'Setujui rencana';

  @override
  String get orchestrationReject => 'Tolak';

  @override
  String get orchestrationCancel => 'Batalkan orkestrasi';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count peran — $hires rekrut baru';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count sub-tiket';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Perkiraan biaya: \$$amount';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total sub-tiket selesai';
  }

  @override
  String get orchestrationStatusProposed => 'Diusulkan';

  @override
  String get orchestrationStatusApproved => 'Disetujui';

  @override
  String get orchestrationStatusExecuting => 'Menjalankan';

  @override
  String get orchestrationStatusSynthesizing => 'Mensintesis';

  @override
  String get orchestrationStatusCompleted => 'Selesai';

  @override
  String get orchestrationStatusFailed => 'Gagal';

  @override
  String get orchestrationStatusCancelled => 'Dibatalkan';

  @override
  String get messageFailed => 'Eksekusi gagal';

  @override
  String get turnLimitReached =>
      'Berhenti di batas giliran — balas untuk lanjut';

  @override
  String get retried => 'Dicoba ulang';

  @override
  String replyingTo(String name) {
    return 'membalas $name';
  }

  @override
  String get silenceTimeoutLabel => 'Batas waktu diam (menit)';

  @override
  String get silenceTimeoutHint =>
      'mis. 15 — hentikan proses setelah selama ini tanpa keluaran';

  @override
  String get capabilityJsonMode => 'Mode JSON';

  @override
  String get capabilityModelSelection => 'Pemilihan model';

  @override
  String get transcriptThinking => 'Berpikir…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'Berpikir selama $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'Menyunting…';

  @override
  String get transcriptStatusReadingFiles => 'Membaca file…';

  @override
  String get transcriptStatusSearching => 'Mencari codebase…';

  @override
  String get transcriptStatusRunningCommands => 'Menjalankan perintah…';

  @override
  String get transcriptStatusResponding => 'Menanggapi…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'Menjalankan $tool…';
  }

  @override
  String get transcriptInput => 'Masukan';

  @override
  String get transcriptOutput => 'Keluaran';

  @override
  String get transcriptErrorLabel => 'Galat';

  @override
  String get transcriptSandboxBlocked => 'Sandbox memblokir suatu tindakan';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'Tampilkan output lengkap (+$kb KB)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'Tampilkan semua $count baris';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'Menampilkan $count baris pertama';
  }

  @override
  String get transcriptGrepNoMatches => 'Tidak ada hasil';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches hasil',
      one: '1 hasil',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files file',
      one: '1 file',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'Orang $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'Ganti nama pembicara';

  @override
  String get meetingRenameSpeakerTitle => 'Ganti nama pembicara';

  @override
  String get meetingSpeakerNameLabel => 'Nama';

  @override
  String get meetingSpeakerSuggestFromCalendar => 'Dari undangan rapat ini';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'Terapkan ke semua blok dari pembicara ini';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'Jika nonaktif, hanya baris yang dipilih yang diganti namanya.';

  @override
  String get meetingLinkEvent => 'Tautkan ke acara';

  @override
  String get meetingChangeEvent => 'Ubah acara';

  @override
  String get meetingLinkEventTitle => 'Tautkan ke acara kalender';

  @override
  String get meetingLinkEventSearchHint => 'Cari acara';

  @override
  String get meetingLinkEventEmpty => 'Tidak ada acara kalender terdekat';

  @override
  String get meetingUnlinkEvent => 'Hapus tautan';

  @override
  String get calendarLinkExistingMeeting => 'Tautkan ke rapat yang ada';

  @override
  String get calendarLinkMeetingTitle => 'Tautkan rapat';

  @override
  String get calendarLinkMeetingSearchHint => 'Cari rapat';

  @override
  String get calendarLinkMeetingEmpty => 'Tidak ada rapat untuk ditautkan';

  @override
  String get meetingRenameSpeakerFailed =>
      'Tidak dapat mengganti nama pembicara';

  @override
  String get calendarLinkUpdateFailed =>
      'Tidak dapat memperbarui tautan kalender';

  @override
  String get rename => 'Ganti nama';

  @override
  String get notNow => 'Nanti saja';

  @override
  String get meetingSaveVoiceProfileTitle => 'Simpan profil suara?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'Kenali $name secara otomatis di rapat mendatang dengan menyimpan sidik suaranya.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'Profil suara $name disimpan';
  }

  @override
  String get meetingVoiceProfileSaveFailed =>
      'Tidak dapat menyimpan profil suara';

  @override
  String get voiceProfilesSection => 'Profil suara';

  @override
  String get voiceProfilesDescription =>
      'Suara tersimpan dikenali secara otomatis di rapat mendatang.';

  @override
  String get voiceProfilesEmpty =>
      'Belum ada suara tersimpan. Beri nama pembicara di transkrip rapat, lalu pilih \"Simpan profil suara\".';

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
  String get renameVoiceProfileTitle => 'Ganti nama profil suara';

  @override
  String get deleteVoiceProfileTitle => 'Hapus profil suara?';

  @override
  String deleteVoiceProfileBody(String name) {
    return 'Berhenti mengenali $name? Sidik suara tersimpannya dihapus. Nama yang sudah diterapkan di rapat sebelumnya tetap dipertahankan.';
  }

  @override
  String get connectedLabel => 'Terhubung';

  @override
  String get ideTabGeneral => 'Umum';

  @override
  String get ideTabExplorer => 'Penjelajah';

  @override
  String get ideTabSourceControl => 'Kontrol sumber';

  @override
  String get generalSectionTodos => 'Todo';

  @override
  String get generalSectionGoals => 'Tujuan';

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
  String get goalRunStatusBudgetExhausted => 'Anggaran habis';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'Jalan $run dari $max · $cost dari $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'Jalan $run · $cost dari $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'Tenggat $deadline';
  }

  @override
  String get goalRunPause => 'Jeda tujuan';

  @override
  String get goalRunResume => 'Lanjutkan tujuan';

  @override
  String goalRunResumeRaise(String cap) {
    return 'Lanjutkan · naikkan batas ke $cap';
  }

  @override
  String get goalRunStop => 'Hentikan tujuan';

  @override
  String get generalSectionAgents => 'Agen';

  @override
  String get generalSectionTerminals => 'Terminal';

  @override
  String get generalTodosEmpty => 'Belum ada todo';

  @override
  String get generalAgentsEmpty => 'Tidak ada agen yang berjalan';

  @override
  String get generalTerminalsEmpty => 'Tidak ada terminal yang terbuka';

  @override
  String get generalSectionBrowsers => 'Browser';

  @override
  String get generalSectionComputers => 'Komputer';

  @override
  String get generalBrowsersEmpty => 'Tidak ada browser yang terbuka';

  @override
  String get generalComputersEmpty => 'Tidak ada komputer yang terbuka';

  @override
  String get generalSectionPhones => 'Ponsel';

  @override
  String get generalPhonesEmpty => 'Tidak ada ponsel yang terbuka';

  @override
  String get pauseAgent => 'Jeda agen';

  @override
  String get resumeAgent => 'Lanjutkan agen';

  @override
  String get agentCannotPause => 'Agen ini tidak dapat dijeda — hentikan saja.';

  @override
  String get goalClear => 'Hapus tujuan';

  @override
  String get undoLabelGoalClear => 'hapus tujuan';

  @override
  String get todoStatusPending => 'Belum dimulai';

  @override
  String get todoStatusInProgress => 'Sedang dikerjakan';

  @override
  String get todoStatusCompleted => 'Selesai';

  @override
  String get reorderTodo => 'Ubah urutan todo';

  @override
  String get focusTerminal => 'Fokuskan terminal';

  @override
  String get focusMachine => 'Fokuskan mesin';

  @override
  String get focusBrowser => 'Fokuskan browser';

  @override
  String get todoEditorTitle => 'Edit todo';

  @override
  String get todoEditorHint =>
      'Satu item per baris. Gunakan - [ ] untuk belum dimulai, - [~] untuk sedang dikerjakan, - [x] untuk selesai.';

  @override
  String get todoNeedsText => 'Tambahkan teks setelah perintah';

  @override
  String get todoNotFound => 'Tidak ada todo yang cocok';

  @override
  String get todoCleared => 'Daftar todo dikosongkan';

  @override
  String get todoNothingToCopy => 'Tidak ada yang disalin';

  @override
  String todoAdded(String content) {
    return 'Menambahkan \"$content\"';
  }

  @override
  String todoStarted(String content) {
    return 'Memulai \"$content\"';
  }

  @override
  String todoCompleted(String content) {
    return 'Menyelesaikan \"$content\"';
  }

  @override
  String todoRemoved(String content) {
    return 'Menghapus \"$content\"';
  }

  @override
  String todoCopied(int count) {
    return 'Menyalin $count item';
  }

  @override
  String todoImported(int count) {
    return 'Mengimpor $count item';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'Perintah todo tidak dikenal \"$name\"';
  }

  @override
  String get terminal => 'Terminal';

  @override
  String get ideCloseTab => 'Tutup tab';

  @override
  String get ideSplitEditor => 'Pisahkan editor';

  @override
  String get ideSplitRight => 'Pisahkan ke kanan';

  @override
  String get ideSplitDown => 'Pisahkan ke bawah';

  @override
  String get ideSplitLeft => 'Pisahkan ke kiri';

  @override
  String get ideSplitUp => 'Pisahkan ke atas';

  @override
  String get ideCloseGroup => 'Tutup grup';

  @override
  String get ideCloseOthers => 'Tutup yang lain';

  @override
  String get ideCloseToRight => 'Tutup ke kanan';

  @override
  String get ideCloseSaved => 'Tutup yang tersimpan';

  @override
  String get ideCloseAll => 'Tutup semua';

  @override
  String get ideSplit => 'Pisahkan';

  @override
  String get ideToggleSidebar => 'Alihkan sidebar';

  @override
  String get ideNewTab => 'Buka editor';

  @override
  String get ideNewTabMenu => 'Tab baru';

  @override
  String get ideReviewCode => 'Tinjau kode';

  @override
  String get ideRevertConfirmTitle => 'Kembalikan perubahan';

  @override
  String get ideRevertUntracked =>
      'File yang belum dilacak tidak dapat dikembalikan';

  @override
  String get ideRevertFailed =>
      'File tidak dapat dikembalikan. Pohon kerja percakapan mungkin tidak tersedia.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file',
      one: '1 file',
    );
    return '$_temp0 tidak dapat dikembalikan (belum dilacak).';
  }

  @override
  String get ideSearchMatchCase => 'Cocokkan huruf besar/kecil';

  @override
  String get ideSearchWholeWord => 'Kata utuh';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'Filter pencarian';

  @override
  String get ideSearchFilesToInclude => 'File yang disertakan';

  @override
  String get ideSearchFilesToExclude => 'File yang dikecualikan';

  @override
  String get ideNoOpenTabs => 'Tidak ada tab terbuka — gunakan + untuk membuka';

  @override
  String get ideBrowserAddressHint => 'Masukkan alamat atau cari';

  @override
  String get ideSimpleWebBrowser => 'Browser web sederhana';

  @override
  String get ideWebBrowser => 'Browser web';

  @override
  String get ideBrowserEnterUrl =>
      'Masukkan URL di bilah alamat untuk mulai menelusuri';

  @override
  String get ideCodeServer => 'Editor';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'Simpan perubahan ke $fileName?';
  }

  @override
  String get ideUnsavedChangesBody =>
      'Perubahan Anda akan hilang jika tidak disimpan.';

  @override
  String get ideDontSave => 'Jangan simpan';

  @override
  String get editorAutoSave => 'Simpan otomatis';

  @override
  String get editorAutoSaveDescription =>
      'Simpan perubahan secara otomatis di editor tertanam.';

  @override
  String get editorAutoSaveOff => 'Nonaktif';

  @override
  String get editorAutoSaveAfterDelay => 'Setelah jeda';

  @override
  String get editorAutoSaveOnFocusChange => 'Saat fokus berubah';

  @override
  String get ideCodeServerUnavailable =>
      'code-server tidak tersedia di server ini';

  @override
  String get ideCodeServerUnavailableHint =>
      'Instal code-server (coder/code-server) di host server, lalu buka kembali editor.';

  @override
  String get ideCodeServerInstalling => 'Menyiapkan editor…';

  @override
  String get ideCodeServerOpenInBrowser => 'Buka editor di browser';

  @override
  String get ideCodeServerError => 'Tidak dapat membuka editor';

  @override
  String get paneSuspendedCaption =>
      'Ditangguhkan untuk menghemat sumber daya — dimuat ulang saat difokuskan';

  @override
  String get ideFolderLoadFailed => 'Tidak dapat memuat folder ini';

  @override
  String get ideFileSearchFailed => 'Tidak dapat mencari file';

  @override
  String get ideSearchInFiles => 'Cari dalam file';

  @override
  String get ideNoContentMatches => 'Tidak ada hasil';

  @override
  String get ideSourceControlCreatePr => 'Buat pull request';

  @override
  String ideSourceControlViewPr(int number) {
    return 'Lihat pull request #$number';
  }

  @override
  String get ideSourceControlNoChanges => 'Tidak ada perubahan';

  @override
  String get noReposInConversation => 'Tidak ada repositori di percakapan ini';

  @override
  String get ideSourceControlNoSpace =>
      'Buka percakapan untuk melihat perubahannya';

  @override
  String get ideFileLoading => 'Memuat…';

  @override
  String get ideFileBinary => 'File biner';

  @override
  String get mcpExternalServers => 'Server MCP eksternal';

  @override
  String get mcpExternalServersDescription =>
      'Hubungkan ke server MCP eksternal (GitHub, Sentry, Postgres, otomasi browser). Server yang Anda konfigurasikan untuk Claude, Cursor, VS Code, dan alat lain ditemukan secara otomatis.';

  @override
  String get mcpApprovalMode => 'Persetujuan alat';

  @override
  String get mcpApprovalModeDescription =>
      'Tindakan alat mana yang dijalankan tanpa bertanya. Pembacaan selalu diizinkan; tingkat yang lebih tinggi akan meminta konfirmasi.';

  @override
  String get mcpApprovalAlwaysAsk => 'Selalu tanya';

  @override
  String get mcpApprovalWrite => 'Setujui penulisan otomatis';

  @override
  String get mcpApprovalYolo => 'Setujui semua otomatis';

  @override
  String get mcpNoExternalServers =>
      'Tidak ada server MCP eksternal yang ditemukan.';

  @override
  String get mcpAuthorize => 'Otorisasi';

  @override
  String get mcpReconnect => 'Hubungkan kembali';

  @override
  String get mcpExternalConnectionsNote =>
      'Server MCP eksternal berjalan di server agen (dibagikan oleh desktop dan web). Otorisasi server OAuth hanya tersedia di desktop.';

  @override
  String get mcpStatusConnected => 'Terhubung';

  @override
  String get mcpStatusConnecting => 'Menghubungkan…';

  @override
  String get mcpStatusNeedsAuth => 'Perlu otorisasi';

  @override
  String get mcpStatusFailed => 'Gagal';

  @override
  String get mcpStatusCircuitOpen => 'Dijeda';

  @override
  String get mcpStatusDisabled => 'Nonaktif';

  @override
  String get providersAndModels => 'Penyedia & model';

  @override
  String get providersAndModelsDescription =>
      'Daftar semua penyedia yang dapat digunakan agen bawaan — atur kunci API atau masuk dengan browser, lihat model dan harga setiap penyedia yang terhubung, dan tentukan penyedia mana yang boleh digunakan ruang kerja ini.';

  @override
  String get syncNow => 'Sinkronkan sekarang';

  @override
  String syncNowResult(int applied, int failed) {
    return 'Sinkronisasi selesai — $applied diterapkan, $failed gagal';
  }

  @override
  String syncNowFailed(String error) {
    return 'Sinkronisasi gagal: $error';
  }

  @override
  String get denied => 'Ditolak';

  @override
  String get allowed => 'Diizinkan';

  @override
  String allowProviderSemantic(String provider) {
    return 'Izinkan $provider';
  }

  @override
  String enabledViaEnv(String key) {
    return 'Diaktifkan lewat $key';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output per 1 juta';
  }

  @override
  String contextTokens(String tokens) {
    return '$tokens konteks';
  }

  @override
  String get usageAndCost => 'Pemakaian & biaya';

  @override
  String get usageAndCostDescription =>
      'Pengeluaran semua agen dalam 7 hari terakhir, dari biaya run yang teramati.';

  @override
  String get noUsageYet => 'Belum ada pemakaian tercatat.';

  @override
  String get spentThisWeek => 'terpakai minggu ini';

  @override
  String get subscriptionUsage => 'Pemakaian langganan';

  @override
  String get subscriptionUsageUnavailable => 'Tidak tersedia';

  @override
  String get subscriptionUsageExhausted => 'Kuota habis';

  @override
  String get subscriptionUsageSignInRequired => 'Masuk lagi';

  @override
  String get subscriptionUsageSignInExpired =>
      'Sesi masuk kedaluwarsa, diperbarui pada run berikutnya';

  @override
  String get subscriptionUsagePartiallyAvailable => 'Tersedia sebagian';

  @override
  String resetsIn(String duration) {
    return 'Diatur ulang dalam $duration';
  }

  @override
  String get feedbackHelpful => 'Ini membantu';

  @override
  String get feedbackNotHelpful => 'Ini tidak membantu';

  @override
  String get modeChat => 'Chat';

  @override
  String get modePlan => 'Rencana';

  @override
  String get modeReview => 'Tinjauan';

  @override
  String get modeOrchestrate => 'Orkestrasi';

  @override
  String get editorTheme => 'Tema editor';

  @override
  String get editorThemeDescription =>
      'Impor tema warna VS Code agar diff dan editor tertanam cocok dengan IDE Anda.';

  @override
  String get editorThemePasteHint => 'Tempel isi file JSON tema warna VS Code';

  @override
  String get editorThemeImported => 'Tema diimpor';

  @override
  String get editorThemeInvalid => 'Ini bukan tema VS Code yang valid';

  @override
  String get importTheme => 'Impor tema';

  @override
  String get clearTheme => 'Hapus tema';

  @override
  String get openInDiffViewer => 'Buka di penampil diff';

  @override
  String get shellCommand => 'Perintah';

  @override
  String get shellOutput => 'Keluaran';

  @override
  String get revertToHere => 'Kembalikan ke sini';

  @override
  String get revertConfirmBody =>
      'Sembunyikan pesan setelah titik ini dan batalkan perubahan file agen ke giliran ini? Anda bisa membatalkannya.';

  @override
  String get revert => 'Kembalikan';

  @override
  String get revertedToHere => 'Dikembalikan ke sini';

  @override
  String get nothingToRevert => 'Tidak ada yang dikembalikan';

  @override
  String get undoRevert => 'Batalkan pengembalian';

  @override
  String get revertUndone => 'Pengembalian dibatalkan';

  @override
  String get systemBehavior => 'Perilaku sistem';

  @override
  String get keepAwakeTitle => 'Jaga komputer tetap aktif saat agen berjalan';

  @override
  String get keepAwakeOnSubtitle =>
      'Komputer tidak akan tidur saat agen bekerja';

  @override
  String get keepAwakeOffSubtitle =>
      'Komputer bisa tidur meskipun agen sedang bekerja';

  @override
  String get syncEngineSectionTitle => 'Mesin sinkronisasi';

  @override
  String get syncEngineDescription =>
      'Tiket, pesan, dan catatan diperbarui secara langsung lewat perubahan inkremental kecil, bukan snapshot penuh. Mematikan sakelar mengembalikan penyimpanan itu ke mode snapshot penuh — muat ulang aplikasi agar perubahan berlaku.';

  @override
  String get syncEngineTicketsTitle => 'Tiket';

  @override
  String get syncEngineMessagingTitle => 'Pesan';

  @override
  String get syncEngineNotesTitle => 'Catatan';

  @override
  String get syncEngineOnSubtitle => 'Sinkronisasi delta langsung aktif';

  @override
  String get syncEngineOffSubtitle => 'Menggunakan sinkronisasi snapshot penuh';

  @override
  String get spaces => 'Ruang';

  @override
  String get spacesHomeDescription =>
      'Pilih ruang dari daftar, atau buat yang baru.';

  @override
  String get noSpacesYet => 'Belum ada ruang';

  @override
  String get newSpace => 'Ruang baru';

  @override
  String get spaceName => 'Nama ruang';

  @override
  String get spaceReposHint => 'Repo yang disertakan';

  @override
  String get ideSourceControl => 'Kontrol sumber';

  @override
  String get stagedChanges => 'Perubahan ter-stage';

  @override
  String get changes => 'Perubahan';

  @override
  String get stageFile => 'Stage';

  @override
  String get unstageFile => 'Unstage';

  @override
  String get stageAll => 'Stage semua perubahan';

  @override
  String get unstageAll => 'Unstage semua';

  @override
  String get stageChangesToCommit => 'Stage perubahan untuk di-commit';

  @override
  String get syncToPrHead => 'Tarik commit PR terbaru';

  @override
  String get syncedToPrHead => 'Tersinkron dengan commit PR terbaru';

  @override
  String get syncPrHeadDirty =>
      'Commit atau buang perubahan sebelum menyinkronkan';

  @override
  String get syncPrHeadFailed => 'Tidak dapat menyinkronkan ke head PR';

  @override
  String get spaceLabel => 'Ruang';

  @override
  String get keybindingNewSpace => 'Ruang baru';

  @override
  String get keybindingCreateANewSpaceDescription => 'Buat ruang baru';

  @override
  String get jumpToLatest => 'Lompat ke terbaru';

  @override
  String get streaming => 'Streaming';

  @override
  String get newMessages => 'Baru';

  @override
  String get copyLink => 'Salin tautan';

  @override
  String get linkCopied => 'Tautan disalin';

  @override
  String get agentResponding => 'Agen merespons';

  @override
  String get agentFinished => 'Agen selesai';

  @override
  String get harnessConnectProviderForModels =>
      'Hubungkan penyedia untuk melihat model.';

  @override
  String get providerSignOut => 'Keluar';

  @override
  String get providerWaitingForDeviceCode =>
      'Menunggu Anda mengonfirmasi kode di browser…';

  @override
  String get providerDeviceCodeHint =>
      'Pastikan kode ini sama dengan yang ditampilkan di browser, lalu setujui.';

  @override
  String get providerPlanUsageLoading => 'Memeriksa penggunaan paket…';

  @override
  String get providerPlanUsageUnavailable =>
      'Paket ini tidak melaporkan penggunaan.';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return 'Hapus kunci API $provider?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'Kunci tersimpan dihapus dan tidak dapat ditampilkan lagi. Agen yang memakai model $provider berhenti bekerja sampai Anda menempelkan yang baru.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return 'Hapus $provider?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'Penyedia dan kunci tersimpannya dihapus. Agen yang terikat ke modelnya berhenti bekerja.';
  }

  @override
  String get providerApiKeyHint => 'Tempel kunci API';

  @override
  String get providerApiKeyStoredHint =>
      'Tempel kunci API lain untuk menambahkannya';

  @override
  String get providerAddAnotherAccount => 'Tambah akun lain';

  @override
  String get providerActiveBadge => 'Aktif';

  @override
  String get providerOauthAccountFallback => 'Akun OAuth';

  @override
  String get providerApiKeyFallback => 'Kunci API';

  @override
  String get providerRemoveCredentialConfirmTitle => 'Hapus kredensial ini?';

  @override
  String get providerSignOutAccountConfirmTitle => 'Keluar dari akun ini?';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'Agen yang memakai $provider beralih ke kunci dan akun lainnya. Jika tidak ada yang tersisa, mereka berhenti sampai Anda menambahkan satu.';
  }

  @override
  String get providerBaseUrlHint => 'Base URL (opsional)';

  @override
  String get addProvider => 'Tambah penyedia';

  @override
  String get noCustomProviders => 'Belum ada penyedia kustom.';

  @override
  String get providerNameLabel => 'Nama';

  @override
  String get apiTypeLabel => 'Jenis API';

  @override
  String get providerBaseUrlLabel => 'Base URL';

  @override
  String get providerApiKeyOptionalHint => 'Kunci API (opsional)';

  @override
  String get dialectOpenAiCompatible => 'Kompatibel dengan OpenAI';

  @override
  String get dialectAnthropicCompatible => 'Kompatibel dengan Anthropic';

  @override
  String get removeProviderTooltip => 'Hapus penyedia';

  @override
  String get providerLogInWithBrowser => 'Masuk dengan browser';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'Masuk ke $provider';
  }

  @override
  String get providerLabel => 'Penyedia';

  @override
  String get selectProviderToLogin => 'Pilih penyedia untuk masuk';

  @override
  String providerLoginFailed(String error) {
    return 'Login gagal: $error';
  }

  @override
  String get providerWaitingForBrowser =>
      'Menunggu Anda mengotorisasi di browser…';

  @override
  String get providerPasteCodeHint => 'Atau tempel kode dari browser';

  @override
  String get providerCompleteLogin => 'Selesai';

  @override
  String get providerConnectedApiKey => 'Terhubung lewat kunci API';

  @override
  String get providerConnectedOauth => 'Terhubung';

  @override
  String providerConnectedAccount(String account) {
    return 'Terhubung · $account';
  }

  @override
  String get providerLocalReady => 'Lokal · siap';

  @override
  String get providerNotConnected => 'Tidak terhubung';

  @override
  String get preparingWorkspace => 'Menyiapkan ruang kerja…';

  @override
  String provisioningRunningSetupScript(String repo) {
    return 'Menjalankan skrip setup untuk $repo…';
  }

  @override
  String get repoScriptsTitle => 'Skrip';

  @override
  String get repoScriptsTooltip => 'Konfigurasi skrip siklus hidup';

  @override
  String get repoScriptsSetupLabel => 'Skrip setup';

  @override
  String get repoScriptsSetupHelp =>
      'Dijalankan di pohon kerja space segera setelah dibuat — instal dependensi, hasilkan file. Kegagalan menandai space sebagai gagal; coba lagi akan menjalankannya kembali.';

  @override
  String get repoScriptsArchiveLabel => 'Skrip arsip';

  @override
  String get repoScriptsArchiveHelp =>
      'Dijalankan tepat sebelum pohon kerja space dihapus — bersihkan sumber daya di luar pohon kerja. Kegagalan tidak pernah menghalangi penghapusan.';

  @override
  String get repoScriptsEnvHelp =>
      'Dijalankan via bash dari pohon kerja, dengan CC_WORKSPACE_PATH (pohon kerja), CC_ROOT_PATH (akar repo), CC_SPACE_ID, CC_SPACE_NAME, dan CC_REPO_NAME yang disetel.';

  @override
  String get repoScriptsSetupPlaceholder => 'mis. pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      'mis. docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => 'Eksekusi terbaru';

  @override
  String get repoScriptsNoRuns => 'Belum ada eksekusi';

  @override
  String get repoScriptsSaved => 'Skrip disimpan';

  @override
  String get repoScriptsRunKindSetup => 'Setup';

  @override
  String get repoScriptsRunKindArchive => 'Arsip';

  @override
  String get repoScriptsRunStatusRunning => 'Berjalan';

  @override
  String get repoScriptsRunStatusSucceeded => 'Berhasil';

  @override
  String get repoScriptsRunStatusFailed => 'Gagal';

  @override
  String get repoScriptsRunStatusTimedOut => 'Waktu habis';

  @override
  String repoScriptsExitCode(int code) {
    return 'Kode keluar $code';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return 'Mengkloning $repo…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'Checkout pull request di $repo…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'Menyiapkan agen $agent…';
  }

  @override
  String get workspacePrepFailed => 'Penyiapan ruang kerja gagal';

  @override
  String get workspacePrepStopped => 'Penyiapan ruang kerja dihentikan';

  @override
  String get stopWorkspacePrep => 'Hentikan penyiapan';

  @override
  String get stopWorkspacePrepTooltip => 'Hentikan penyiapan ruang kerja ini';

  @override
  String get stopWorkspacePrepConfirm =>
      'Hentikan penyiapan ruang kerja ini? Klon yang sedang berjalan dibuang — Anda dapat memulainya lagi dari sini.';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count pesan akan dikirim saat siap';
  }

  @override
  String get membersNav => 'Anggota';

  @override
  String get membersSettingsDescription =>
      'Orang dengan akses ke ruang kerja ini: daftar anggota, undangan, dan jejak audit';

  @override
  String get memberRosterLabel => 'Daftar anggota';

  @override
  String get memberRepoAccessAction => 'Akses repo';

  @override
  String memberRepoAccessTitle(String name) {
    return 'Akses repo untuk $name';
  }

  @override
  String get roleOwner => 'Pemilik';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Anggota';

  @override
  String get roleViewer => 'Penampil';

  @override
  String get roleGuest => 'Tamu';

  @override
  String get removeMemberTitle => 'Hapus anggota';

  @override
  String removeMemberConfirm(String name) {
    return 'Hapus $name dari ruang kerja ini? Mereka langsung kehilangan akses.';
  }

  @override
  String get transferOwnershipAction => 'Alihkan kepemilikan';

  @override
  String get transferOwnershipTitle => 'Alihkan kepemilikan';

  @override
  String transferOwnershipConfirm(String name) {
    return 'Jadikan $name pemilik ruang kerja ini? Anda menjadi admin. Hanya pemilik yang dapat menghapus ruang kerja atau mengubah peran admin lain.';
  }

  @override
  String get transferOwnershipCta => 'Alihkan';

  @override
  String get auditTrailLabel => 'Jejak audit otorisasi';

  @override
  String get auditTrailDescription =>
      'Setiap izin dan penolakan, dirantai hash sehingga entri yang diubah atau dihapus dapat terdeteksi.';

  @override
  String get auditVerifyChain => 'Verifikasi rantai';

  @override
  String auditChainIntact(int count) {
    return 'Rantai utuh — $count entri terverifikasi';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'Rantai rusak pada entri $seq: $reason';
  }

  @override
  String get auditEmpty => 'Belum ada keputusan yang tercatat.';

  @override
  String get auditDenied => 'Ditolak';

  @override
  String get auditAllowed => 'Diizinkan';

  @override
  String auditOnBehalfOf(String user) {
    return 'untuk $user';
  }

  @override
  String get policyTemplatesLabel => 'Templat kebijakan';

  @override
  String get policyTemplatesDescription =>
      'Terapkan postur awal, atau pindahkan antar ruang kerja.';

  @override
  String get policyTemplateStrict => 'Ketat';

  @override
  String get policyTemplateBalanced => 'Seimbang';

  @override
  String get policyTemplatePermissive => 'Permisif';

  @override
  String get policyTemplateApply => 'Terapkan';

  @override
  String policyTemplateApplied(int count) {
    return '$count aturan diterapkan';
  }

  @override
  String get policyExport => 'Salin kebijakan';

  @override
  String get policyExported => 'Kebijakan disalin ke papan klip';

  @override
  String get policyImport => 'Tempel kebijakan';

  @override
  String policyImported(int count) {
    return '$count aturan diimpor';
  }

  @override
  String get approveAndRemember => 'Setujui selama 8 jam';

  @override
  String get approveAndRememberTooltip =>
      'Menyetujui tindakan ini dan berhenti menanyakan yang serupa di ruang ini selama 8 jam. Kedaluwarsa dengan sendirinya.';

  @override
  String get unknownUserLabel => 'Pengguna tidak dikenal';

  @override
  String get inviteMember => 'Undang anggota';

  @override
  String get inviteRepoAccessHeader => 'Akses repositori';

  @override
  String get inviteRepoAccessExplainer =>
      'Hanya repositori yang Anda centang yang dibagikan kepada penerima undangan, pada tingkat yang Anda pilih. Yang lain tetap tersembunyi.';

  @override
  String get grantLevelRead => 'Baca';

  @override
  String get grantLevelReview => 'Tinjau';

  @override
  String get grantLevelWrite => 'Tulis';

  @override
  String get inviteExpiryLabel => 'Kedaluwarsa dalam';

  @override
  String get expiryOneDay => '1 hari';

  @override
  String get expirySevenDays => '7 hari';

  @override
  String get expiryThirtyDays => '30 hari';

  @override
  String get createInviteAction => 'Buat undangan';

  @override
  String get inviteOneTimeCodeLabel => 'Kode sekali pakai';

  @override
  String get inviteCodeShownOnce =>
      'Kode ini hanya ditampilkan sekali — salin sekarang.';

  @override
  String get inviteLinkLabel => 'Tautan undangan';

  @override
  String get inviteRedeemHint =>
      'Bagikan kode kepada penerima undangan; mereka menukarkannya di URL server Anda.';

  @override
  String get inviteScanQr => 'Atau pindai untuk menukar';

  @override
  String get inviteLoopbackWarningTitle => 'Undangan mengarah ke alamat lokal';

  @override
  String get inviteLoopbackWarningBody =>
      'Kolaborator di mesin lain tidak dapat menjangkau server ini. Mulai tunnel (Pengaturan → Integrasi → Bagikan server ini) atau bind ke jaringan Anda agar pengguna di luar host dapat terhubung.';

  @override
  String get inviteStatusOpen => 'Terbuka';

  @override
  String get inviteStatusUsed => 'Digunakan';

  @override
  String get inviteStatusRevoked => 'Dicabut';

  @override
  String get inviteStatusExpired => 'Kedaluwarsa';

  @override
  String inviteCreatedTime(String time) {
    return 'Dibuat $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'kedaluwarsa $date';
  }

  @override
  String get noActivityYet => 'Belum ada aktivitas';

  @override
  String get couldNotLoadMembers => 'Tidak dapat memuat anggota';

  @override
  String get couldNotLoadInvites => 'Tidak dapat memuat undangan';

  @override
  String get couldNotLoadActivity => 'Tidak dapat memuat aktivitas';

  @override
  String get yourDevices => 'Perangkat Anda';

  @override
  String get yourDevicesDescription =>
      'Klien yang dipasangkan ke akun Anda di server ini.';

  @override
  String get noOwnDevices =>
      'Belum ada perangkat yang dipasangkan ke akun Anda';

  @override
  String get renameDeviceTitle => 'Ganti nama perangkat';

  @override
  String get revokeDeviceTitle => 'Cabut perangkat';

  @override
  String revokeDeviceConfirm(String label) {
    return 'Cabut $label? Perangkat langsung diputus dan tidak dapat lagi menjangkau server ini.';
  }

  @override
  String devicePairedTime(String time) {
    return 'Dipasangkan $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'Terakhir terlihat $time';
  }

  @override
  String get deviceNeverSeen => 'Belum pernah terhubung';

  @override
  String get profileSectionLabel => 'Profil';

  @override
  String get profileSectionDescription =>
      'Cara Anda tampil kepada rekan tim dan dalam kepenulisan commit git.';

  @override
  String get displayNameLabel => 'Nama tampilan';

  @override
  String get emailLabel => 'Email';

  @override
  String get gitAuthorNameLabel => 'Nama penulis Git';

  @override
  String get gitAuthorEmailLabel => 'Email penulis Git';

  @override
  String get profileSaved => 'Profil disimpan';

  @override
  String get presenceOnline => 'Online';

  @override
  String get presenceIdle => 'Tidak aktif';

  @override
  String get presenceTyping => 'Mengetik…';

  @override
  String get presenceAgentThinking => 'Berpikir';

  @override
  String get presenceAgentRunning => 'Berjalan';

  @override
  String get presenceAgentBlocked => 'Terblokir';

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
  String get presenceRailLabel => 'Siapa yang online';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'Aktifkan jangan ganggu';

  @override
  String get dndTooltipOff => 'Nonaktifkan jangan ganggu';

  @override
  String get startPresenting => 'Mulai presentasi';

  @override
  String get stopPresenting => 'Hentikan presentasi';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name sedang presentasi';
  }

  @override
  String get spotlightLeave => 'Keluar';

  @override
  String typingIndicator(String name) {
    return '$name sedang mengetik…';
  }

  @override
  String get ideTabNotes => 'Catatan';

  @override
  String get ideSidebarAllViews => 'Semua tampilan';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'Semua tampilan ($count tersembunyi)';
  }

  @override
  String get ideSidebarPinView => 'Sematkan ke bilah sisi';

  @override
  String get ideSidebarUnpinView => 'Lepas sematan dari bilah sisi';

  @override
  String get notesEmptyHint =>
      'Tambahkan catatan untuk siapa pun yang mengambil percakapan ini…';

  @override
  String get notesEditTooltip => 'Edit catatan';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'Diperbarui oleh $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name sedang mengedit';
  }

  @override
  String get notesSaveFailed => 'Tidak dapat menyimpan catatan';

  @override
  String get reactionAddTooltip => 'Tambahkan reaksi';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'Beri reaksi $emoji';
  }

  @override
  String get autonomyDialLabel => 'Otonomi';

  @override
  String get autonomyProposeOnly => 'Hanya usulkan';

  @override
  String get autonomyActWithApproval => 'Bertindak dengan persetujuan';

  @override
  String get autonomyActFreely => 'Bertindak bebas';

  @override
  String get autonomyDefaultOption => 'Bawaan';

  @override
  String get checkerLabel => 'Pemeriksa';

  @override
  String get checkerNone => 'Tidak ada';

  @override
  String get checkerCaption =>
      'Pemeriksa meninjau run agen lain yang sudah selesai.';

  @override
  String get takeoverTooltip => 'Ambil alih pohon kerja';

  @override
  String get takeoverBannerSelf =>
      'Anda telah mengambil alih pohon kerja percakapan ini';

  @override
  String takeoverBannerOther(String name) {
    return '$name telah mengambil alih pohon kerja percakapan ini';
  }

  @override
  String get handBackButton => 'Kembalikan';

  @override
  String get handBackDialogTitle => 'Kembalikan pohon kerja';

  @override
  String get handBackDialogNoteHint => 'Catatan opsional untuk agen…';

  @override
  String takeoverFailed(String message) {
    return 'Tidak dapat mengambil alih: $message';
  }

  @override
  String handBackFailed(String message) {
    return 'Tidak dapat mengembalikan: $message';
  }

  @override
  String get planStudioTitle => 'Studio rencana';

  @override
  String get plansTitle => 'Rencana';

  @override
  String get plansSubtitle => 'Rencana aktif, dokumen rencana, dan playbook';

  @override
  String get plansActiveSection => 'Rencana aktif';

  @override
  String get plansDocumentsSection => 'Dokumen rencana';

  @override
  String get plansPlaybooksSection => 'Playbook';

  @override
  String get plansNoActive => 'Belum ada rencana aktif.';

  @override
  String get plansNoDocuments => 'Belum ada dokumen rencana.';

  @override
  String get plansNoPlaybooks => 'Belum ada playbook.';

  @override
  String get planNotFound => 'Rencana tidak ditemukan.';

  @override
  String get planOpenInStudio => 'Buka';

  @override
  String get planNodeTitle => 'Judul';

  @override
  String get planNodeDescription => 'Deskripsi';

  @override
  String get planNodeDescriptionHint => 'Apa yang harus dilakukan langkah ini…';

  @override
  String get planNodeApplyDescription => 'Terapkan';

  @override
  String get planNodeRole => 'Peran';

  @override
  String get planNodeDependencies => 'Bergantung pada';

  @override
  String get planNodeDependenciesHint => 'Tambahkan dependensi';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dependensi',
      one: '1 dependensi',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'Tidak ada dependensi, jadi ini berjalan segera setelah rencana dimulai';

  @override
  String get planNodeOutputSchema => 'Skema output (JSON)';

  @override
  String get planNodeEstimate => 'Estimasi';

  @override
  String get planNodeProvenance => 'Asal-usul';

  @override
  String get planNodeAlreadyExecuted =>
      'Sudah dijalankan — mengedit akan mencabangkan rencana dari sini.';

  @override
  String get planNewNodeTitle => 'Langkah baru';

  @override
  String get planEstimateNoHistory => 'Belum ada riwayat';

  @override
  String get planEstimateBlastUnknown => 'Radius dampak: tidak diketahui';

  @override
  String get planEstimatePartial => 'sebagian';

  @override
  String get planEstimateAction => 'Estimasi';

  @override
  String planEstimateDuration(String range) {
    return 'Durasi $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'Radius dampak: $files file, $symbols simbol';
  }

  @override
  String get planApprove => 'Setujui rencana';

  @override
  String get planApproveSelectedNodes => 'Setujui yang dipilih';

  @override
  String get planReject => 'Tolak';

  @override
  String get planCancel => 'Batalkan eksekusi';

  @override
  String get planContinueNode => 'Lanjutkan node';

  @override
  String get planTotalNotEstimated => 'Belum diestimasi';

  @override
  String get planBudgetExceeded => 'melebihi anggaran';

  @override
  String planBudgetCeiling(String amount) {
    return 'anggaran ≤ \$$amount';
  }

  @override
  String get planVersionsTitle => 'Versi';

  @override
  String get planNoRevisions => 'Belum ada revisi.';

  @override
  String get planDiffIdentical => 'Tidak ada perubahan.';

  @override
  String get planDiffGoalChanged => 'Tujuan diubah';

  @override
  String get planDiffBudgetChanged => 'Anggaran diubah';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'Perubahan dari v$fromRev ke v$toRev';
  }

  @override
  String planDiffAdded(String node) {
    return '$node ditambahkan';
  }

  @override
  String planDiffRemoved(String node) {
    return '$node dihapus';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return '$node diubah: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'Edge ditambahkan: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'Edge dihapus: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'Peran ditambahkan: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'Peran dihapus: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'Peran dialihkan: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'Rencana disusun ulang: Anda menyetujui v$approved, sekarang v$current. Tinjau diff sebelum dilanjutkan.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'Biaya aktual: \$$amount';
  }

  @override
  String get planPlaybookRun => 'Jalankan';

  @override
  String get planPlaybookDelete => 'Hapus playbook';

  @override
  String get planPlaybookProposed =>
      'Rencana diusulkan — setujui di Plan Studio.';

  @override
  String get planPlaybookAnchorTicket => 'Tiket jangkar';

  @override
  String get planPlaybookPickTicket => 'Pilih tiket…';

  @override
  String get planPlaybookProposeRun => 'Usulkan rencana';

  @override
  String get planPlaybookRepoHint => 'Id repositori';

  @override
  String get planPlaybookAgentHint => 'Id agen';

  @override
  String planPlaybookRunTitle(String name) {
    return 'Jalankan $name';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count parameter';
  }

  @override
  String get recentLabel => 'Terbaru';

  @override
  String get cheatSheetTitle => 'Pintasan keyboard';

  @override
  String get cheatSheetGlobal => 'Global';

  @override
  String get cheatSheetThisScreen => 'Layar ini';

  @override
  String get cheatSheetReservedInBrowser => 'Dicadangkan browser';

  @override
  String get keybindingCheatSheet => 'Pintasan keyboard';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      'Tampilkan lembar pintasan keyboard untuk layar saat ini';

  @override
  String get runPlaybookLabel => 'Jalankan playbook';

  @override
  String get playbooksLabel => 'Playbook';

  @override
  String get keybindingUndo => 'Urungkan';

  @override
  String get keybindingRedo => 'Ulangi';

  @override
  String get keybindingUndoLastActionDescription =>
      'Urungkan tindakan terakhir yang dapat diurungkan';

  @override
  String get keybindingRedoLastActionDescription =>
      'Ulangi tindakan yang baru diurungkan';

  @override
  String get undone => 'Diurungkan';

  @override
  String get redone => 'Diulangi';

  @override
  String get undoFailed => 'Tidak bisa membatalkan';

  @override
  String get undoLabelTicketEdit => 'edit tiket';

  @override
  String get undoLabelMessageEdit => 'edit pesan';

  @override
  String get undoLabelTodoStatus => 'status todo';

  @override
  String get inboxTitle => 'Kotak masuk';

  @override
  String get inboxReview => 'Tinjau';

  @override
  String get inboxOpen => 'Terbuka';

  @override
  String get inboxAllCaughtUp => 'Semua sudah tertangani';

  @override
  String get inboxGitHubDownTitle => 'GitHub mungkin sedang down';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub melaporkan $status, jadi pull request mungkin tidak muncul di daftar ini, bukan karena sudah selesai.';
  }

  @override
  String get inboxGitHubIdentityTitle =>
      'Tidak bisa mengonfirmasi akun GitHub Anda';

  @override
  String get inboxGitHubIdentityBody =>
      'Kotak masuk diurutkan berdasarkan identitas GitHub Anda. Sebelum data itu dimuat, daftar tetap kosong meskipun ada pull request yang menunggu Anda.';

  @override
  String get inboxSeverityBlocking => 'Terblokir';

  @override
  String get inboxSeverityWaiting => 'Menunggu';

  @override
  String get inboxSeverityInfo => 'Info';

  @override
  String get inboxSyncFailed => 'Sinkronisasi gagal';

  @override
  String get inboxNeedsYourAttention => 'Perlu perhatian Anda';

  @override
  String get inboxSectionNeedsYourReview => 'Perlu tinjauan Anda';

  @override
  String get inboxSectionReturnedToYou => 'Dikembalikan ke Anda';

  @override
  String get inboxSectionApproved => 'Disetujui';

  @override
  String get inboxSectionDrafts => 'Draf';

  @override
  String get inboxSectionWaitingForReviewers => 'Menunggu peninjau';

  @override
  String get inboxSectionMergingAndMerged =>
      'Sedang digabung dan baru saja digabung';

  @override
  String get inboxSectionWaitingForAuthor => 'Menunggu penulis';

  @override
  String get inboxColumnTitle => 'Judul';

  @override
  String get inboxColumnChanges => 'Perubahan';

  @override
  String get inboxColumnUpdated => 'Diperbarui';

  @override
  String get inboxReviewApproved => 'Disetujui';

  @override
  String get inboxReviewChangesRequested => 'Perubahan diminta';

  @override
  String get inboxHeroSubtitle =>
      'Setiap pull request yang melibatkan Anda, diurutkan berdasarkan langkah berikutnya.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull request perlu tinjauan Anda',
      one: '1 pull request perlu tinjauan Anda',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dikembalikan ke Anda',
      one: '1 dikembalikan ke Anda',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted =>
      'Perubahan itu tidak tersimpan dan dibatalkan';

  @override
  String get offlinePendingLabel => 'tertunda';

  @override
  String get offlineSyncingLabel => 'menyinkronkan';

  @override
  String get copyLinkLabel => 'Salin tautan halaman ini';

  @override
  String get agentsSectionLabel => 'Agen';

  @override
  String get fleetWorkersTitle => 'Pekerja';

  @override
  String get fleetWorkersSubtitle =>
      'Mesin yang tersedia untuk menjalankan job';

  @override
  String get fleetJobsTitle => 'Job';

  @override
  String get fleetJobsSubtitle =>
      'Pekerjaan yang didistribusikan ke seluruh fleet';

  @override
  String get fleetNoWorkers =>
      'Belum ada pekerja — mesin kedua yang menjalankan `cc_worker --server <url>` akan bergabung ke fleet.';

  @override
  String get fleetNoJobs => 'Tidak ada job.';

  @override
  String get fleetError => 'Tidak bisa memuat fleet';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count core',
      one: '1 core',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'Heartbeat $time';
  }

  @override
  String get fleetNoHeartbeat => 'Belum ada heartbeat';

  @override
  String fleetLastErrorLabel(String error) {
    return 'Error terakhir: $error';
  }

  @override
  String get fleetDrain => 'Kosongkan';

  @override
  String get fleetResume => 'Lanjutkan';

  @override
  String get fleetRevoke => 'Cabut';

  @override
  String get fleetRemove => 'Hapus';

  @override
  String get fleetRevokeTitle => 'Cabut pekerja?';

  @override
  String fleetRevokeBody(String name) {
    return 'Cabut $name? Sesi akan berakhir dan job aktif akan dialihkan.';
  }

  @override
  String get fleetRemoveTitle => 'Hapus pekerja?';

  @override
  String fleetRemoveBody(String name) {
    return 'Hapus $name dari fleet? Catatannya akan dihapus.';
  }

  @override
  String get fleetActionFailed => 'Tindakan gagal';

  @override
  String get fleetJobUnassigned => 'Belum ditetapkan';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max percobaan';
  }

  @override
  String get fleetPlacementReasons => 'Keputusan penempatan';

  @override
  String get fleetNoPlacements => 'Belum ada keputusan penempatan.';

  @override
  String get fleetStatusOnline => 'Online';

  @override
  String get fleetStatusDraining => 'Mengosongkan';

  @override
  String get fleetStatusOffline => 'Offline';

  @override
  String get fleetStatusIncompatible => 'Tidak kompatibel';

  @override
  String get fleetStatusRevoked => 'Dicabut';

  @override
  String get fleetJobStatusQueued => 'Dalam antrean';

  @override
  String get fleetJobStatusRunning => 'Berjalan';

  @override
  String get fleetJobStatusSucceeded => 'Berhasil';

  @override
  String get fleetJobStatusFailed => 'Gagal';

  @override
  String get fleetJobStatusCancelled => 'Dibatalkan';

  @override
  String get evalsNoSuites => 'Belum ada suite eval.';

  @override
  String get evalsError => 'Evals tidak dapat dimuat';

  @override
  String get evalsStarterBadge => 'Pemula';

  @override
  String evalsDefaultBatch(int count) {
    return 'Batch default $count';
  }

  @override
  String get evalsRecentRuns => 'Run terbaru';

  @override
  String get evalsNoRuns => 'Belum ada run.';

  @override
  String get evalsPassRate => 'Tingkat lulus';

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
  String get evalsRunFailed => 'Suite tidak dapat dijalankan';

  @override
  String get evalsRun => 'Jalankan';

  @override
  String get evalsStatusQueued => 'Dalam antrean';

  @override
  String get evalsStatusRunning => 'Berjalan';

  @override
  String get evalsStatusPassed => 'Lulus';

  @override
  String get evalsStatusFailed => 'Gagal';

  @override
  String get bannerMeetingJoin => 'Gabung';

  @override
  String get bannerMeetingRecordAndLink => 'Rekam & tautkan';

  @override
  String get bannerCalendarReconnect => 'Hubungkan ulang';

  @override
  String get bannerView => 'Lihat';

  @override
  String get soundscapeTitle => 'Soundscape';

  @override
  String get soundscapePlay => 'Putar';

  @override
  String get soundscapePause => 'Jeda';

  @override
  String get soundscapeMoodLabel => 'Suasana';

  @override
  String get soundscapeMoodFocus => 'Fokus';

  @override
  String get soundscapeMoodRelax => 'Santai';

  @override
  String get soundscapeMoodSleep => 'Tidur';

  @override
  String get soundscapeVolumeLabel => 'Volume';

  @override
  String get soundscapeTuneLabel => 'Penyetelan';

  @override
  String get soundscapeTuneMellow => 'Lembut';

  @override
  String get soundscapeTuneBright => 'Cerah';

  @override
  String get soundscapeTuneEnergetic => 'Enerjik';

  @override
  String get soundscapeTuneSpacy => 'Angkasa';

  @override
  String get soundscapeTuneResetHint => 'Ketuk dua kali untuk reset';

  @override
  String get soundscapeSceneLabel => 'Sedang diputar';

  @override
  String get soundscapeSceneLoading => 'Menyetel ambiens…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees°C';
  }

  @override
  String get soundscapeLocationLabel => 'Lokasi';

  @override
  String get soundscapeLocationDetecting => 'Mendeteksi lokasi…';

  @override
  String get soundscapeLocationAutoNote =>
      'Lokasi dideteksi otomatis dari ruang kerja ini.';

  @override
  String get soundscapeRefreshWeather => 'Segarkan cuaca';

  @override
  String get soundscapeAutoStartLabel => 'Mulai dengan mode fokus';

  @override
  String get soundscapeAutoStartDescription =>
      'Putar soundscape otomatis saat Anda memulai sesi fokus.';

  @override
  String get soundscapeReturnToApp => 'Kembali ke aplikasi';

  @override
  String get soundscapePopOut => 'Keluarkan pemutar';

  @override
  String get discussion => 'Diskusi';

  @override
  String get chat => 'Chat';

  @override
  String get saving => 'Menyimpan…';

  @override
  String get saved => 'Tersimpan';

  @override
  String get saveFailed => 'Gagal menyimpan';

  @override
  String get commitAndPush => 'Commit & push';

  @override
  String get commit => 'Commit';

  @override
  String get commitAmend => 'Commit (amend)';

  @override
  String get commitAndSync => 'Commit & sinkronkan';

  @override
  String get committed => 'Berhasil commit';

  @override
  String get commitAmended => 'Commit di-amend';

  @override
  String get commitFailed => 'Commit gagal';

  @override
  String get moreCommitActions => 'Tindakan commit lainnya';

  @override
  String get sourceControl => 'Kontrol sumber';

  @override
  String fixFindingTitle(String location) {
    return 'Perbaiki: $location';
  }

  @override
  String get openInEditor => 'Buka di editor';

  @override
  String get regexTesterTitle => 'Uji ekspresi reguler';

  @override
  String get regexTesterHint => 'Ketik contoh';

  @override
  String get regexMatch => 'Cocok';

  @override
  String get regexNoMatch => 'Tidak cocok';

  @override
  String get regexInvalidPattern => 'Pola tidak valid';

  @override
  String get symbolLookupNone =>
      'Tidak ada definisi di indeks atau pull request ini';

  @override
  String get symbolLookupInDiff => 'Ditemukan di pull request ini';

  @override
  String get symbolLookupFromBase =>
      'Dari checkout dasar — worktree PR ini belum diindeks';

  @override
  String get symbolImplementations => 'Implementasi';

  @override
  String symbolCallersCount(int count) {
    return '$count pemanggil';
  }

  @override
  String get commitMessageHint => 'Pesan commit';

  @override
  String get pushedToPr => 'Di-push ke PR';

  @override
  String get pushFailed => 'Push gagal';

  @override
  String get reviewFindings => 'Temuan';

  @override
  String get treeLabel => 'Pohon';

  @override
  String get toggleFileTree => 'Tampilkan atau sembunyikan pohon file';

  @override
  String get diffViewSettings => 'Pengaturan tampilan diff';

  @override
  String get splitViewLabel => 'Terpisah';

  @override
  String get unifiedViewLabel => 'Terpadu';

  @override
  String get wrapLines => 'Bungkus baris';

  @override
  String get shiftClickSelectRange => 'Shift-klik untuk memilih rentang';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'PR kecil — $files, ~$minutes mnt untuk ditinjau';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'PR sedang — $files, sisihkan ~$minutes mnt untuk ditinjau';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'PR besar — $files, pertimbangkan memecah sebelum meninjau';
  }

  @override
  String get searchInFiles => 'Cari di file';

  @override
  String get showFileList => 'Tampilkan daftar file';

  @override
  String get searchInFilesHintField => 'Cari di file…';

  @override
  String get searchInFilesHint => 'Cari di seluruh file pull request';

  @override
  String get searchInWholeRepo => 'Cari di seluruh repositori';

  @override
  String get searchInThisPullRequest => 'Cari di pull request ini';

  @override
  String get searchNoResults => 'Tidak ada hasil';

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
      other: '$files file',
      one: '1 file',
    );
    return '$_temp0 di $_temp1';
  }

  @override
  String get discardChangesTitle => 'Buang perubahan?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file',
      one: '1 file',
    );
    return 'Buang $_temp0 ke HEAD? Tindakan ini tidak dapat dibatalkan.';
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
      other: '$count file',
      one: '1 file',
    );
    return 'Membuang $_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted file',
      one: '1 file',
    );
    return 'Membuang $_temp0; $skipped dilewati (untracked)';
  }

  @override
  String get prWorktreeUnavailable => 'Ruang kerja belum siap';

  @override
  String get prWorktreeUnavailableHint =>
      'Gagal menyiapkan file pull request. Buka ulang pull request untuk mencoba lagi.';

  @override
  String get timestampRelativeLabel => 'Relatif';

  @override
  String get timestampRawLabel => 'Stempel waktu';

  @override
  String get copyTimestamp => 'Salin stempel waktu';

  @override
  String get copiedTimestamp => 'Stempel waktu disalin';

  @override
  String get previewDeployment => 'Pratinjau deployment';

  @override
  String previewDeploymentTab(String site) {
    return 'Pratinjau: $site';
  }

  @override
  String get askForReview => 'Minta tinjauan…';

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
      other: 'Meminta tinjauan pada $count pull request',
      one: 'Meminta tinjauan pada 1 pull request',
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
  String get diagram => 'Diagram';

  @override
  String get diagramViewSource => 'Lihat sumber';

  @override
  String get diagramHideSource => 'Sembunyikan sumber';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'Pratinjau diagram tidak tersedia ($reason)';
  }

  @override
  String get planUnavailable => 'Rencana tidak tersedia';

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
  String get planApproveAndRun => 'Setujui dan jalankan';

  @override
  String get planStatusDraft => 'Draf';

  @override
  String get planStatusProposed => 'Rencana';

  @override
  String get planStatusApproved => 'Rencana disetujui';

  @override
  String get planStatusRejected => 'Rencana ditolak';

  @override
  String get planStatusSuperseded => 'Rencana digantikan';

  @override
  String planRevisionLabel(int revision) {
    return 'Revisi $revision';
  }

  @override
  String get adapterEnforcementTitle => 'Yang ditegakkan adapter ini';

  @override
  String get enforcementFiltersToolSurface =>
      'Control Center yang memilih tool';

  @override
  String get enforcementInterceptsToolCalls =>
      'Setiap panggilan dicegat sebelum dijalankan';

  @override
  String get enforcementObservesCompletionContract =>
      'Proses diikat pada hasil yang harus dihasilkan';

  @override
  String get enforcementNativeToolsInterceptable =>
      'Tool milik runner terlihat';

  @override
  String get enforcementInProcessToolsSandboxed => 'Tool in-process di-sandbox';

  @override
  String get enforcementYes => 'Ya';

  @override
  String get enforcementNo => 'Tidak';

  @override
  String get adapterEnforcementCaveats => 'Catatan';

  @override
  String get enforcementSummaryModesEnforced => 'Mode yang ditegakkan';

  @override
  String get enforcementSummaryModesNotEnforced => 'Mode yang tidak ditegakkan';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count catatan',
      one: '1 catatan',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'Mode baca-saja bukan struktural: Control Center tidak dapat menghapus tool milik runner ini.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'Tidak ada gerbang pra-eksekusi: hanya panggilan tool MCP yang melewati Control Center.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'Tool file dan shell milik runner tidak pernah sampai ke Control Center; sandbox OS adalah satu-satunya batas di bawahnya.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'Tool file in-process berjalan di luar sandbox, jadi permukaan tool adalah satu-satunya batas sistem file.';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center tidak dapat mendorong atau menggagalkan proses yang berakhir tanpa menghasilkan hasilnya.';

  @override
  String get modeDegraded => 'Terdegradasi';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return 'Mode $mode pada $adapter hanya mengandalkan sandbox; tool file milik agen tidak dicegat.';
  }

  @override
  String get artifactUnavailable => 'Artefak tidak tersedia';

  @override
  String artifactRevisionLabel(int count) {
    return '$count revisi';
  }

  @override
  String get artifactShowMore => 'Tampilkan lebih banyak';

  @override
  String get artifactShowLess => 'Tampilkan lebih sedikit';

  @override
  String get artifactCopy => 'Salin';

  @override
  String get artifactCopied => 'Artefak disalin';

  @override
  String get artifactsTabLabel => 'Artefak';

  @override
  String get artifactsEmptyTitle => 'Belum ada artefak';

  @override
  String get artifactsEmptyBody =>
      'Saat agen menerbitkan tabel, bagan, atau diagram di sini, hasilnya muncul di daftar ini.';

  @override
  String get artifactRevisionPickerLabel => 'Revisi';

  @override
  String get artifactRestoreRevision => 'Pulihkan revisi ini';

  @override
  String get artifactOpenInTab => 'Buka di tab';

  @override
  String get artifactTitleFallback => 'Artefak';

  @override
  String get providerGenerationLabel => 'Default generasi';

  @override
  String get providerGenerationHint =>
      'Biarkan kolom kosong untuk memakai default endpoint. Model memublikasikan batas keluaran dan resep sampling-nya sendiri; menjalankannya pada nilai lain dapat menurunkannya.';

  @override
  String get providerMaxTokensLabel => 'Maks. token keluaran';

  @override
  String get addModel => 'Tambah model';

  @override
  String get modelListTitle => 'Daftar model';

  @override
  String get railProvidersGroup => 'Penyedia';

  @override
  String get railCustomProvidersGroup => 'Penyedia kustom';

  @override
  String get editModelSettings => 'Edit pengaturan model';

  @override
  String get modelIdLabel => 'ID model';

  @override
  String get modelIdImmutableHint =>
      'ID yang disajikan endpoint; tetap setelah terdaftar.';

  @override
  String get contextWindowLabel => 'Jendela konteks';

  @override
  String get inputTypesLabel => 'Jenis input';

  @override
  String get outputTypesLabel => 'Jenis output';

  @override
  String get modalityText => 'Teks';

  @override
  String get modalityImage => 'Gambar';

  @override
  String get modalityAudio => 'Audio';

  @override
  String get modalityVideo => 'Video';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'Reset ke otomatis';

  @override
  String get modelOverrideEdited => 'Diedit';

  @override
  String get manualModelBadge => 'Ditambahkan manual';

  @override
  String get modelIdRequired => 'Masukkan ID model.';

  @override
  String get modelTokensInvalid =>
      'Masukkan jumlah token berupa bilangan bulat positif.';

  @override
  String get removeModelAction => 'Hapus model';

  @override
  String removeModelConfirmTitle(String model) {
    return 'Hapus $model?';
  }

  @override
  String get removeModelConfirmBody =>
      'Model keluar dari daftar dan agen yang terpasang padanya berhenti bekerja. Penyedia tidak terpengaruh.';

  @override
  String get addModelProviderTitle => 'Tambah penyedia model';

  @override
  String get addModelProviderDescription =>
      'Konfigurasikan endpoint API kustom beserta modelnya.';

  @override
  String get modelListEmptyHint =>
      'Belum ada model. Tambahkan model untuk menggunakannya di chat.';

  @override
  String get addProviderModelsHint =>
      'Model diambil secara langsung setelah endpoint merespons. Tambahkan manual hanya jika endpoint tidak dapat menampilkan daftarnya sendiri.';

  @override
  String get providerTemperatureLabel => 'Temperature';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => 'Default generasi disimpan';

  @override
  String get providerGenerationInvalid =>
      'Periksa nilainya: token keluaran maks dan top-k harus positif, temperature 0–2, top-p 0–1.';

  @override
  String get providerGenerationOverridden => 'Ditimpa';

  @override
  String get branchNotPushed => 'belum dipush';

  @override
  String branchNotOnRemote(String branch) {
    return '“$branch” hanya ada di percakapan ini';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub belum pernah melihat cabang ini, jadi pull request belum dapat menggunakannya. Memublikasikan akan mem-push commit yang sudah ada di pohon kerja — perubahan yang belum di-commit dibiarkan.';

  @override
  String get publishBranch => 'Publikasikan cabang';

  @override
  String branchPublished(String branch) {
    return '“$branch” dipublikasikan ke origin';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'Cabang dipublikasikan. $count perubahan yang belum di-commit tidak disertakan.';
  }

  @override
  String get composePrLoadingBranches => 'Memuat cabang dari GitHub…';

  @override
  String get composePrBranchesFailed =>
      'Tidak dapat memuat cabang dari GitHub. Ketik nama cabang, atau periksa koneksi GitHub.';

  @override
  String get composePrSubtitleFromSpace =>
      'Dari cabang percakapan ini — publikasikan dulu jika GitHub belum melihatnya';

  @override
  String get obsTabInsights => 'Wawasan';

  @override
  String get obsTabLive => 'Langsung';

  @override
  String get obsTabQuality => 'Kualitas';

  @override
  String get obsTabUsage => 'Penggunaan';

  @override
  String get obsUsageTotalTokens => 'Total token';

  @override
  String get obsUsagePeakTokens => 'Puncak token';

  @override
  String get obsUsageLongestSession => 'Sesi terpanjang';

  @override
  String get obsUsageCurrentStreak => 'Rentetan saat ini';

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
  String get obsUsageTokenActivity => 'Aktivitas token';

  @override
  String get obsUsageActivityModeLabel => 'Mode aktivitas token';

  @override
  String get obsUsageModeDaily => 'Harian';

  @override
  String get obsUsageModeWeekly => 'Mingguan';

  @override
  String get obsUsageModeCumulative => 'Kumulatif';

  @override
  String get obsUsageTimeRange => 'Rentang waktu';

  @override
  String get obsUsageTrendTitle => 'Tren token harian';

  @override
  String get obsUsageModelUsage => 'Penggunaan model';

  @override
  String get obsUsageTokensLabel => 'token';

  @override
  String get obsUsageNoActivity => 'Belum ada penggunaan token yang tercatat';

  @override
  String get obsUsageOtherModels => 'Lainnya';

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
    return 'Aktivitas token dari $start hingga $end. $activeDays hari aktif. Hari tersibuk $peak token.';
  }

  @override
  String get obsScreenSubtitle =>
      'Kontrol agen langsung, atribusi biaya, kuota, dan sinyal kualitas';

  @override
  String get obsRangeLast24h => '24 jam terakhir';

  @override
  String get obsRangeLast7d => '7 hari terakhir';

  @override
  String get obsRangeLast30d => '30 hari terakhir';

  @override
  String get obsRangeAll => 'Semua waktu';

  @override
  String get obsAddFilter => 'Tambah filter';

  @override
  String get obsFilterAgent => 'Agen';

  @override
  String get obsFilterModel => 'Model';

  @override
  String get obsFilterStatus => 'Status';

  @override
  String get obsFilterRole => 'Peran';

  @override
  String get obsKpiTotalRuns => 'Total run';

  @override
  String get obsKpiTotalCost => 'Total biaya';

  @override
  String get obsKpiErrorRate => 'Tingkat error';

  @override
  String get obsKpiCacheRate => 'Tingkat cache';

  @override
  String get obsKpiTokensPerSec => 'Token / dtk';

  @override
  String get obsKpiAvgLatency => 'Latensi rata-rata';

  @override
  String get obsKpiTtft => 'Waktu ke token pertama';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta vs periode sebelumnya';
  }

  @override
  String get obsChartActivity => 'Aktivitas';

  @override
  String get obsChartCost => 'Biaya dari waktu ke waktu';

  @override
  String get obsLegendRuns => 'Run';

  @override
  String get obsLegendErrors => 'Error';

  @override
  String get obsAgentsTitle => 'Agen';

  @override
  String obsShowAllAgents(int count) {
    return 'Tampilkan semua $count agen';
  }

  @override
  String get obsShowFewerAgents => 'Tampilkan lebih sedikit';

  @override
  String get obsRunsTitle => 'Run';

  @override
  String get obsNoRunsInRange => 'Tidak ada run di rentang ini';

  @override
  String get obsColTime => 'Waktu';

  @override
  String get obsColAgent => 'Agen';

  @override
  String get obsColStatus => 'Status';

  @override
  String get obsColModel => 'Model';

  @override
  String get obsColDuration => 'Durasi';

  @override
  String get obsColTokens => 'Token';

  @override
  String get obsColCost => 'Biaya';

  @override
  String get obsColErrors => 'Error';

  @override
  String get obsColRuns => 'Run';

  @override
  String get obsColAvgLatency => 'Latensi rata-rata';

  @override
  String get obsColLastActive => 'Terakhir aktif';

  @override
  String get obsStatusPending => 'Menunggu';

  @override
  String get obsStatusRunning => 'Berjalan';

  @override
  String get obsStatusCompleted => 'Selesai';

  @override
  String get obsStatusError => 'Error';

  @override
  String get obsRosterLoadError => 'Roster agen tidak dapat dimuat.';

  @override
  String get obsRosterEmpty => 'Belum ada agen';

  @override
  String get obsRosterEmptyDescription =>
      'Jalankan agen, lalu agen itu akan muncul di sini secara langsung — status, tool saat ini, token, biaya.';

  @override
  String get obsKillAgent => 'Hentikan agen';

  @override
  String get obsRosterTokensLabel => 'tok';

  @override
  String get obsCostByRoleTitle => 'Biaya menurut peran';

  @override
  String get obsCostByRoleSubtitle =>
      'Pengeluaran ruang kerja ini, menurut peran agen';

  @override
  String get obsRoleMain => 'Utama';

  @override
  String get obsRoleSubagents => 'Subagen';

  @override
  String get obsRoleAdvisor => 'Penasihat';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'Utama: $main · subagen: $sub · penasihat: $advisor';
  }

  @override
  String get obsTotal => 'Total';

  @override
  String get obsTokenModelTitle => 'Model token (5 sumbu)';

  @override
  String get obsTokenModelSubtitle =>
      'Semua token yang dipakai ruang kerja ini, menurut sumbu';

  @override
  String get obsAxisInput => 'Input';

  @override
  String get obsAxisOutput => 'Output';

  @override
  String get obsAxisReasoning => 'Penalaran';

  @override
  String get obsAxisCacheRead => 'Baca cache';

  @override
  String get obsAxisCacheWrite => 'Tulis cache';

  @override
  String get obsTotalTokens => 'Total token';

  @override
  String get obsCacheDiscountNote =>
      'Token baca-cache ditagih dengan diskon, jadi biayanya jauh lebih rendah daripada volume input baru yang sama.';

  @override
  String get obsByModelTitle => 'Menurut model';

  @override
  String get obsByModelSubtitle => 'Pemakaian token dan biaya per model';

  @override
  String get obsNoModelUsage => 'Belum ada penggunaan model yang tercatat.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count run',
      one: '1 run',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => 'Per run';

  @override
  String get obsPerRunSubtitle => 'Biaya token tipikal untuk satu run';

  @override
  String get obsMedianRunTokens => 'Median token run';

  @override
  String get obsMedianRunTokensSub => 'Titik tengah dari semua run';

  @override
  String get obsRunsInWorkspace => 'Di ruang kerja ini';

  @override
  String get obsCostShare => 'Porsi biaya';

  @override
  String get obsQuotaConfiguredLimits => 'Batas terkonfigurasi';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'Pemakaian terhadap batas yang Anda tetapkan, status terburuk dulu.';

  @override
  String get obsQuotaAddLimit => 'Tambah batas';

  @override
  String get obsQuotaNoLimits =>
      'Belum ada batas kuota — tambahkan satu untuk melacak pemakaian terhadap batas.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'Hapus batas $title';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'Reset dalam $duration · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'Jendela pemakaian';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'Pemakaian teramati di semua provider, tanpa batas.';

  @override
  String get obsQuotaNoUsage => 'Belum ada pemakaian yang tercatat.';

  @override
  String get obsQuotaTokensUsed => 'Token terpakai';

  @override
  String get obsQuotaRequests => 'Request';

  @override
  String get obsQuotaUnitTokens => 'token';

  @override
  String get obsQuotaUnitRequests => 'request';

  @override
  String get obsQuotaUnitCost => 'biaya';

  @override
  String get obsQuotaAddLimitTitle => 'Tambah batas kuota';

  @override
  String get obsQuotaProviderLabel => 'Provider';

  @override
  String get obsQuotaWindowLabel => 'Jendela';

  @override
  String get obsQuotaUnitLabel => 'Satuan';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'Batas ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'Dalam sen AS (500 = \$5.00).';

  @override
  String get obsQuotaStatusOk => 'Ok';

  @override
  String get obsQuotaStatusWarning => 'Peringatan';

  @override
  String get obsQuotaStatusExhausted => 'Habis';

  @override
  String get obsQuotaStatusUnknown => 'Tidak diketahui';

  @override
  String get obsGoalNoActiveTitle => 'Tidak ada tujuan aktif';

  @override
  String get obsGoalNoActiveBody =>
      'Tetapkan tujuan agar agen punya objektif dan anggaran token opsional. Seiring run selesai, anggaran terisi dan agen didorong merampungkan ketika hampir habis.';

  @override
  String get obsGoalSetGoal => 'Tetapkan tujuan';

  @override
  String get obsGoalTokenBudget => 'Anggaran token';

  @override
  String obsGoalTokensLeft(String tokens) {
    return '$tokens tersisa';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (anggaran belum ditetapkan)';
  }

  @override
  String get obsGoalTokensUsed => 'Token terpakai';

  @override
  String get obsGoalElapsed => 'Berlalu';

  @override
  String get obsGoalWrapUp => 'Rampungkan';

  @override
  String get obsGoalClear => 'Hapus tujuan';

  @override
  String get obsGoalFallbackTitle => 'Tujuan';

  @override
  String get obsGoalSubtitle => 'Anggaran Goal Mode';

  @override
  String get obsGoalStatusActive => 'Aktif';

  @override
  String get obsGoalStatusPaused => 'Dijeda';

  @override
  String get obsGoalStatusBudgetLimited => 'Dibatasi anggaran';

  @override
  String get obsGoalStatusComplete => 'Selesai';

  @override
  String get obsGoalStatusDropped => 'Dilepas';

  @override
  String get obsGoalObjectiveLabel => 'Objektif';

  @override
  String get obsGoalBudgetLabel => 'Anggaran token (opsional)';

  @override
  String get obsGoalSetAction => 'Tetapkan tujuan';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => 'Keberhasilan %';

  @override
  String get obsBenchmarkPassed => 'Lulus';

  @override
  String get obsBenchmarkFailed => 'Gagal';

  @override
  String get obsBenchmarkErrors => 'Error';

  @override
  String get obsBenchmarkSpend => 'Pengeluaran';

  @override
  String get obsBenchmarkCostPerTask => 'Biaya / tugas';

  @override
  String get obsBenchmarkTrials => 'Percobaan';

  @override
  String get obsBenchmarkNoTrials => 'Belum ada run untuk dinilai.';

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
  String get obsBenchmarkTrialError => 'Kesalahan';

  @override
  String get obsBenchmarkTrialRunning => 'Berjalan';

  @override
  String get obsBenchmarkReward => 'Imbalan';

  @override
  String get obsBenchmarkReport => 'Laporan';

  @override
  String get obsBenchmarkCopyMarkdown => 'Salin markdown';

  @override
  String get obsBenchmarkCopied => 'Laporan disalin ke papan klip';

  @override
  String get obsBehaviorCaption =>
      'Ini sinyal frustrasi yang diurai dari pesan Anda sendiri — gambaran kesehatan percakapan, bukan skor untuk agen. Dihitung secara lokal; tidak ada yang keluar dari perangkat ini.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'Pesan dianalisis';

  @override
  String get obsBehaviorTotalSignals => 'Total sinyal';

  @override
  String get obsBehaviorYelling => 'Teriakan';

  @override
  String get obsBehaviorProfanity => 'Umpatan';

  @override
  String get obsBehaviorAnguish => 'Kesedihan';

  @override
  String get obsBehaviorNegation => 'Negasi';

  @override
  String get obsBehaviorRepetition => 'Pengulangan';

  @override
  String get obsBehaviorBlame => 'Menyalahkan';

  @override
  String get obsBehaviorConversationsTitle => 'Percakapan paling frustrasi';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'Diurutkan berdasarkan kepadatan sinyal di pesan Anda.';

  @override
  String get obsBehaviorNoSignals =>
      'Tidak ada sinyal frustrasi terdeteksi — semuanya lancar.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count pesan dianalisis';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count sinyal';
  }

  @override
  String get obsAgentStatusIdle => 'Menganggur';

  @override
  String get obsAgentStatusParked => 'Diparkir';

  @override
  String get obsAgentStatusAborted => 'Dibatalkan';

  @override
  String get obsAgentKindSub => 'Sub';

  @override
  String get noChecksOnCommit =>
      'Belum ada check yang dijalankan pada commit ini.';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Berjalan — $count job',
      one: 'Berjalan — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Semua check lulus — $count job',
      one: 'Semua check lulus — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Selesai — $count job',
      one: 'Selesai — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total job',
      one: '1 job',
    );
    return '$failed dari $_temp0 gagal';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count job',
      one: '1 job',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'Matrix: $jobId';
  }

  @override
  String get jobLogsPending => 'Log akan muncul di sini saat job selesai.';

  @override
  String get jobLogsUnavailable => 'Log tidak tersedia untuk job ini.';

  @override
  String get noLogsForStep => 'Tidak ada log yang terekam untuk langkah ini.';

  @override
  String get jobLogsTruncated => 'Log dipotong — menampilkan keluaran terbaru.';

  @override
  String get fullLog => 'Log lengkap';

  @override
  String get copyLogs => 'Salin log';

  @override
  String get resizeGraph => 'Seret untuk mengubah ukuran grafik';

  @override
  String workflowRunStartedAgo(String time) {
    return 'Dimulai $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'Selesai $time';
  }

  @override
  String get chatBridgesTitle => 'Jembatan chat';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'Sebut bot di $provider untuk menugaskan agen, atau buat tiket dengan $command.';
  }

  @override
  String chatConnectProvider(String provider) {
    return 'Hubungkan $provider';
  }

  @override
  String get chatDisconnectProvider => 'Putuskan';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName di $teamName';
  }

  @override
  String get chatStateLive => 'Aktif';

  @override
  String get chatStateConnecting => 'Menghubungkan…';

  @override
  String get chatStateError => 'Kesalahan koneksi';

  @override
  String get chatNotConnected => 'Tidak terhubung';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'Streaming langsung nonaktif untuk aplikasi $provider ini — balasan tiba sebagai satu pesan.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'Hanya admin yang dapat menghubungkan $provider untuk ruang kerja ini.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'Buat aplikasi $provider, lalu tempel kredensialnya di sini. Control Center terhubung keluar ke $provider, jadi server ini tidak perlu alamat publik.';
  }

  @override
  String chatOpenConsole(String provider) {
    return 'Buka konsol $provider';
  }

  @override
  String get chatOpenSetupGuide => 'Panduan penyiapan';

  @override
  String get chatFieldBotToken => 'Token bot';

  @override
  String get chatFieldAppToken => 'Token tingkat aplikasi';

  @override
  String get chatFieldConfigRefreshToken => 'Token konfigurasi aplikasi';

  @override
  String chatFieldOptional(String label) {
    return '$label (opsional)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'Hubungkan akun $provider saya';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'Hubungkan akun $provider Anda agar pesan yang Anda kirim di sana dikaitkan dengan Anda.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'Terhubung ke $externalUserId';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'Hubungkan akun $provider Anda';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'Kirim perintah ini ke bot di $provider. Berlaku sekali dan kedaluwarsa dalam 15 menit.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'Akun $provider Anda sudah terhubung — pesan yang Anda kirim di sana dikaitkan dengan Anda.';
  }

  @override
  String get chatLinkedAccounts => 'Akun terhubung';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'Belum ada yang menghubungkan akun $provider mereka.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count akun terhubung',
      one: '1 akun terhubung',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · dicocokkan lewat email';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · terhubung dengan kode';
  }

  @override
  String get chatUnlink => 'Batalkan tautan';

  @override
  String get chatCustomizeBot => 'Sesuaikan bot';

  @override
  String get chatCustomizeBotDescription =>
      'Ubah nama bot, ubah apa yang dikatakannya tentang dirinya, atau ubah nama perintah slash.';

  @override
  String get chatCustomizeBotUnavailable =>
      'Control Center memerlukan token konfigurasi aplikasi untuk mengedit bot. Hubungkan ulang dan sertakan token.';

  @override
  String chatCreateAppTitle(String provider) {
    return 'Buat aplikasi $provider';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center dapat membuat aplikasi $provider untuk Anda, dengan izin dan event yang sudah diatur. Anda menyelesaikan di $provider, lalu tempel kredensial di sini.';
  }

  @override
  String get chatCreateApp => 'Buat aplikasi';

  @override
  String get chatCreateAppCta => 'Buatkan aplikasi';

  @override
  String get chatAppNameLabel => 'Nama aplikasi';

  @override
  String get chatBotDisplayNameLabel =>
      'Nama bot (yang diketik anggota setelah @)';

  @override
  String get chatDescriptionLabel => 'Deskripsi singkat';

  @override
  String get chatAgentDescriptionLabel =>
      'Yang dikatakan bot dapat dilakukannya';

  @override
  String get chatCommandLabel => 'Perintah slash';

  @override
  String get chatDirectMessages => 'Pesan langsung';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'Memungkinkan anggota mengobrol dengan bot lewat DM. Mungkin memerlukan paket berbayar $provider.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$provider membuat aplikasi $appId.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'Beberapa langkah tersisa dan hanya $provider yang dapat melakukannya:';
  }

  @override
  String get chatStepAppToken => 'Buat token tingkat aplikasi';

  @override
  String get chatStepInstall => 'Instal aplikasi';

  @override
  String get chatOpenAppSettings => 'Buka pengaturan aplikasi';

  @override
  String get chatContinueToCredentials => 'Tempel kredensial';

  @override
  String chatBotUpdated(String provider) {
    return 'Bot diperbarui di $provider.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$provider mengubah izin aplikasi. Instal ulang aplikasi agar berlaku.';
  }

  @override
  String get chatReinstallApp => 'Instal ulang aplikasi';

  @override
  String chatIconNotEditable(String provider) {
    return 'Ikon bot hanya dapat diubah di pengaturan aplikasi $provider sendiri.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'Anda juga dapat membuatnya sendiri di $provider — token tidak diperlukan. Pengaturan di atas ikut bersama tautan.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'Buat di $provider';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '$provider dibuka di browser Anda dengan konfigurasi ini sudah terisi. Buat aplikasinya di sana, lalu selesaikan langkah-langkah ini dan kembali dengan token.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider tidak melaporkan aplikasi mana yang dibuat, jadi menyesuaikan bot dari sini memerlukan token konfigurasi aplikasi nanti.';
  }

  @override
  String get chatStepCreateApp =>
      'Buat aplikasi dari konfigurasi yang sudah terisi';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'Pilih ruang kerja di $provider lalu konfirmasi.';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens, dengan cakupan connections:write.';

  @override
  String get chatStepInstallHint => 'Install app → salin bot user OAuth token.';

  @override
  String get calendarUseBuiltinApp => 'Gunakan aplikasi Google Control Center';

  @override
  String get calendarUseBuiltinAppHint =>
      'Setujui dengan akun Google Anda. Tidak ada yang perlu diatur di Google Cloud.';

  @override
  String get calendarUseOwnClient => 'Gunakan klien Google Cloud saya sendiri';

  @override
  String get calendarUseOwnClientHint =>
      'Masukkan klien OAuth dari proyek Google Cloud Anda sendiri.';

  @override
  String get aboutTitle => 'Tentang';

  @override
  String get aboutAppVersion => 'Versi aplikasi';

  @override
  String get aboutServerVersion => 'Server terhubung';

  @override
  String get aboutRpcCatalog => 'Katalog RPC';

  @override
  String get aboutServerUnknown => 'Tidak dilaporkan';

  @override
  String get serverStaleTitle =>
      'Server terbundel lebih lama dari aplikasi ini';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'cc_server yang berjalan adalah $serverVersion sedangkan aplikasi ini $appVersion. Mulai ulang aplikasi agar memakai build server terbundel terbaru; saat pengembangan, bangun ulang dengan `dart build cli` di apps/cc_server.';
  }

  @override
  String get updateCheckButton => 'Periksa pembaruan';

  @override
  String get updateChecking => 'Memeriksa pembaruan…';

  @override
  String get updateUpToDate => 'Anda sudah yang terbaru';

  @override
  String get updateDeferredBusy =>
      'Pembaruan siap, tetapi rapat sedang direkam — akan diminta setelah rapat berakhir.';

  @override
  String get updateOpenedReleasesPage =>
      'Halaman rilis dibuka di browser Anda.';

  @override
  String get updateCheckFailed => 'Pemeriksaan pembaruan gagal';

  @override
  String updateAvailableVersion(String version) {
    return 'Versi $version tersedia.';
  }

  @override
  String get updateBannerTitle => 'Control Center baru tersedia';

  @override
  String get updateBannerRefresh => 'Muat ulang';

  @override
  String get updateBlockedRecording =>
      'Muat ulang dijeda saat rapat sedang direkam — akan dimuat ulang setelah rapat berakhir.';

  @override
  String get settingsScopeYou => 'Anda';

  @override
  String get settingsScopeWorkspace => 'Ruang kerja';

  @override
  String get settingsScopeServer => 'Server';

  @override
  String get settingsProfile => 'Profil & identitas';

  @override
  String get settingsYourDevices => 'Perangkat Anda';

  @override
  String get settingsWorkspaceGeneral => 'Umum';

  @override
  String get settingsServerConnection => 'Koneksi & status';

  @override
  String get settingsModelProviders => 'Penyedia model';

  @override
  String get settingsVoiceModels => 'Model suara & rapat';

  @override
  String get settingsDiagnostics => 'Diagnostik & privasi';

  @override
  String get settingsAbout => 'Tentang';

  @override
  String get settingsScopeBadgeYou => 'ANDA';

  @override
  String get settingsScopeBadgeDevice => 'PERANGKAT INI';

  @override
  String get settingsScopeBadgeWorkspace => 'RUANG KERJA';

  @override
  String get settingsScopeBadgeServer => 'SERVER';

  @override
  String get settingsProfileDescription =>
      'Nama, email, dan identitas git yang dicap pada commit yang dibuat untuk Anda.';

  @override
  String get settingsServerConnectionDescription =>
      'Server yang dihubungi klien ini, dan cara server ini dibagikan (mDNS, tunnel, relay).';

  @override
  String get settingsAboutDescription => 'Identitas build dan pembaruan.';

  @override
  String get settingsDiagnosticsDescription =>
      'Isolasi, pengindeksan, sinkronisasi, logging, dan pelaporan crash untuk instalasi ini.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'Identitas, kebijakan, dan konvensi yang dibagikan semua orang di ruang kerja ini.';

  @override
  String get settingsWorkspacePolicyLabel => 'Kebijakan ruang kerja';

  @override
  String get settingsWorkspacePolicyDescription =>
      'Berlaku untuk setiap anggota dan setiap agen di ruang kerja ini.';

  @override
  String get settingsSecretGlobsLabel => 'Pengecualian jalur rahasia';

  @override
  String get settingsSecretGlobsHelp =>
      'Satu glob per baris. Jalur ini disembunyikan dari viewer dan tamu pada permukaan yang menampilkan kode, di atas default bawaan.';

  @override
  String get settingsReviewConcurrencyLabel => 'Fan-out tinjauan';

  @override
  String get settingsReviewConcurrencyHelp =>
      'Berapa banyak peninjau yang dikirim secara paralel jika jumlahnya tidak ditentukan.';

  @override
  String get settingsReviewLevelLabel => 'Tingkat tinjauan';

  @override
  String get settingsReviewLevelHelp =>
      'Seberapa dalam tinjauan AI, dan seberapa banyak temuan yang dilaporkan di awal. Tidak ada yang dibuang — tingkat yang lebih ringan mengelompokkan temuan minor alih-alih menghapusnya.';

  @override
  String get reviewLevelLight => 'Ringan';

  @override
  String get reviewLevelBalanced => 'Seimbang';

  @override
  String get reviewLevelThorough => 'Menyeluruh';

  @override
  String get reviewLevelLightHint =>
      'Satu peninjau. Hanya yang benar-benar penting yang dilaporkan di awal.';

  @override
  String get reviewLevelBalancedHint =>
      'Tiga peninjau yang mencakup QA, arsitektur, dan implementasi.';

  @override
  String get reviewLevelThoroughHint =>
      'Menambah spesialis keamanan dan performa, dan melaporkan semua temuan.';

  @override
  String get askAiReviewAtLevel => 'Tinjau pada tingkat lain';

  @override
  String reviewNitpicksGroup(int count) {
    return 'Nitpick ($count)';
  }

  @override
  String get reviewFindingResolve => 'Diperbaiki';

  @override
  String get reviewFindingResolveHint =>
      'Tandai temuan ini sebagai diperbaiki. Tidak lagi dihitung dalam tinjauan.';

  @override
  String get reviewFindingDismiss => 'Abaikan';

  @override
  String get reviewFindingDismissHint =>
      'Bukan masalah nyata. Peninjau tidak akan menandai pola ini lagi pada PR berikutnya.';

  @override
  String get reviewFindingReopen => 'Buka kembali';

  @override
  String get reviewFindingStatusUndoLabel => 'Status temuan';

  @override
  String get reviewFindingDismissTitle => 'Abaikan temuan ini';

  @override
  String get reviewFindingDismissReasonHint =>
      'Mengapa ini tidak berlaku? Peninjau akan membacanya.';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'Tidak dapat memperbarui temuan: $error';
  }

  @override
  String get reviewStaleTitle => 'Tinjauan ini sudah usang';

  @override
  String get reviewStaleBody =>
      'Pull request sudah berubah sejak tinjauan ini dijalankan. Temuan mungkin merujuk ke kode yang sudah tidak ada.';

  @override
  String reviewStaleReviewedAt(String sha) {
    return 'Ditinjau pada $sha';
  }

  @override
  String get reviewStaleRerun => 'Tinjau lagi';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return 'Tinjauan usang pada #$prNumber';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return '$title memiliki commit baru sejak tinjauan terakhir.';
  }

  @override
  String get reviewCategorySecurity => 'Keamanan';

  @override
  String get reviewCategoryStability => 'Stabilitas';

  @override
  String get reviewCategoryDataIntegrity => 'Integritas data';

  @override
  String get reviewCategoryCorrectness => 'Kebenaran';

  @override
  String get reviewCategoryPerformance => 'Performa';

  @override
  String get reviewCategoryMaintainability => 'Keterpeliharaan';

  @override
  String get reviewEffortQuickWin => 'Cepat selesai';

  @override
  String get reviewEffortModerate => 'Sedang';

  @override
  String get reviewEffortHeavyLift => 'Pekerjaan besar';

  @override
  String get reviewProposedFix => 'Perbaikan yang diusulkan';

  @override
  String get reviewAiAgentPrompt => 'Prompt untuk agen AI';

  @override
  String get reviewCopyAiPrompt => 'Salin prompt';

  @override
  String get settingsWorkspaceAdminOnly =>
      'Hanya admin ruang kerja yang dapat mengubah ini.';

  @override
  String get chatMyAccountsTitle => 'Akun chat tertaut';

  @override
  String get settingsServerSso => 'Single sign-on';

  @override
  String get settingsServerSsoDescription =>
      'Login SAML dan OpenID Connect dengan penyediaan pengguna';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription =>
      'Pengguna dapat masuk dengan penyedia ini';

  @override
  String get ssoEnabledDescriptionOn => 'Masuk sudah aktif untuk penyedia ini';

  @override
  String get ssoIdpMetadataLabel => 'XML metadata IdP';

  @override
  String get ssoIdpMetadataHint => 'tempel XML EntityDescriptor IdP';

  @override
  String get ssoEmailAttributeLabel => 'Atribut email';

  @override
  String get ssoDisplayNameAttributeLabel => 'Atribut nama tampilan';

  @override
  String get ssoGroupsAttributeLabel => 'Atribut grup';

  @override
  String get ssoIssuerLabel => 'URL issuer';

  @override
  String get ssoClientIdLabel => 'Client ID';

  @override
  String get ssoGroupsClaimLabel => 'Claim grup';

  @override
  String get ssoAutoMemberLabel =>
      'Tambahkan pengguna ke setiap ruang kerja pada login pertama';

  @override
  String get ssoAutoMemberDescription =>
      'Matikan untuk mewajibkan undangan per ruang kerja';

  @override
  String get ssoAllowJitLabel =>
      'Sediakan pengguna yang belum dikenal pada login pertama';

  @override
  String get ssoAllowJitDescription =>
      'Matikan untuk menolak pengguna tanpa akun yang sudah ada';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'Terima masuk tidak diminta (dipicu IdP)';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'Khusus untuk portal IdP yang membuka aplikasi secara langsung';

  @override
  String get ssoWantResponseSignedLabel =>
      'Wajibkan amplop respons yang ditandatangani';

  @override
  String get ssoWantResponseSignedDescription =>
      'Tanda tangan assertion selalu wajib';

  @override
  String get ssoTestConnectionButton => 'Uji koneksi';

  @override
  String get ssoTestConnectionOk => 'Koneksi berhasil:';

  @override
  String get ssoCopySpMetadata => 'Salin metadata SP';

  @override
  String get ssoCopySpMetadataDone => 'Metadata SP disalin ke papan klip';

  @override
  String get ssoSavedToast => 'Pengaturan single sign-on disimpan';

  @override
  String get ssoUnavailable =>
      'Server ini tidak mengekspos pengaturan single sign-on. Perbarui binary server lalu coba lagi.';

  @override
  String get ssoScimCardTitle => 'Penyediaan pengguna (SCIM)';

  @override
  String get ssoScimDescription =>
      'Arahkan konektor SCIM penyedia identitas ke endpoint di bawah dengan bearer token. Deprovisioning mencabut sesi dan akses ruang kerja dalam hitungan detik. Server harus dapat dijangkau oleh IdP (tunnel atau URL publik).';

  @override
  String get ssoScimEndpoint => 'Endpoint SCIM';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'Atur URL publik server atau aktifkan tunnel terlebih dahulu';

  @override
  String get ssoScimRegenerate => 'Buat ulang token';

  @override
  String get ssoScimRegenerateConfirm =>
      'Buat bearer token SCIM baru? Token sebelumnya langsung berhenti berfungsi.';

  @override
  String get ssoScimTokenTitle => 'Bearer token';

  @override
  String get ssoScimTokenPresent => 'Token sudah dikonfigurasi';

  @override
  String get ssoScimTokenAbsent =>
      'Belum ada token — buat satu untuk mengaktifkan SCIM';

  @override
  String get ssoScimTokenOnce => 'Token SCIM (ditampilkan sekali)';

  @override
  String ssoSignInWith(String provider) {
    return 'Masuk dengan $provider';
  }

  @override
  String get ssoProbeFailed =>
      'Tidak dapat menjangkau server itu untuk single sign-on';

  @override
  String get ssoOpensBrowser => 'Membuka browser untuk menyelesaikan masuk';

  @override
  String get ssoWaitingForBrowser => 'Menunggu browser menyelesaikan masuk…';

  @override
  String get ssoBrowserOpenFailed =>
      'Tidak dapat membuka browser untuk single sign-on';

  @override
  String get ssoUseManualPairing =>
      'Masuk dengan undangan atau kunci pairing sebagai gantinya';

  @override
  String get ssoHideManualPairing => 'Sembunyikan pairing manual';

  @override
  String get ssoClientIdHint =>
      'Klien publik (PKCE) — rahasia tidak diperlukan';

  @override
  String get ssoClientSecretLabel => 'Client secret (opsional)';

  @override
  String get ssoClientSecretHintUnset =>
      'Hanya diperlukan untuk klien IdP rahasia';

  @override
  String get ssoClientSecretHintSet =>
      'Rahasia sudah tersimpan — biarkan kosong untuk mempertahankannya';

  @override
  String get ssoPairingToggle =>
      'Izinkan pairing manual (kode undangan dan kunci pairing)';

  @override
  String get ssoPairingToggleDescription =>
      'Matikan agar bergabung hanya lewat single sign-on — perangkat baru datang melalui login SSO; perangkat yang sudah ada tetap berfungsi';

  @override
  String get ssoPairConfirmTitle => 'Hubungkan ke server?';

  @override
  String ssoPairConfirmBody(String server) {
    return 'Kredensial masuk untuk $server tiba, tetapi tidak ada proses masuk yang dimulai dari aplikasi ini. Hubungkan ke server ini?';
  }

  @override
  String get ssoPairConfirmConnect => 'Hubungkan';

  @override
  String get ssoPairConfirmCancel => 'Abaikan';

  @override
  String get forgeConnections => 'Hosting kode';

  @override
  String get connect => 'Hubungkan';

  @override
  String get disconnect => 'Putuskan';

  @override
  String get notConnected => 'Tidak terhubung';

  @override
  String get checkingConnection => 'Memeriksa koneksi…';

  @override
  String get fromEnvironment => 'dari environment';

  @override
  String forgeTokenTitle(String forge) {
    return 'Token $forge';
  }

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAudioDescription =>
      'Mikrofon, dikte, deteksi rapat, dan keluaran soundscape.';

  @override
  String get audioDevicesSection => 'Perangkat audio';

  @override
  String get voiceInputBehaviorSection => 'Dikte dan rapat';

  @override
  String get audioOutputDeviceTitle => 'Perangkat keluaran';

  @override
  String get audioOutputDefaultHint =>
      'Semua suara aplikasi diputar lewat keluaran default sistem.';

  @override
  String get audioOutputGone =>
      'Perangkat keluaran yang dipilih tidak lagi terhubung — default sistem digunakan sampai Anda memilih yang lain.';

  @override
  String get reviewHubIntroBody =>
      'Agen menganalisis diff, memetakan area perubahan, dan mencapai putusan konsensus.';

  @override
  String get reviewHubAlreadyRunning =>
      'Review sudah berjalan untuk pull request ini';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'Sejak review terakhir: $resolved terselesaikan · $added baru · $open masih terbuka';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'Terakhir direview di $sha';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return 'Perbaiki $count temuan';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return 'Perbaiki $count yang dipilih';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return 'Komentari $count yang dipilih';
  }

  @override
  String get webConnectTitle => 'Hubungkan ke Control Center';

  @override
  String get webConnectSubtitle =>
      'Hubungi cc-server yang sedang berjalan lewat WebSocket. Kunci Anda tetap di perangkat ini.';

  @override
  String get webConnectServerLabel => 'Server';

  @override
  String get webConnectDeviceIdLabel => 'Id perangkat';

  @override
  String get webConnectPairingKeyLabel => 'Kunci pairing';

  @override
  String get webConnectPairingKeyHint => 'tempel PSK';

  @override
  String get webConnectStayConnected => 'Tetap terhubung di perangkat ini';

  @override
  String get webConnectStayConnectedDetail =>
      'Tetap terhubung di perangkat ini (menyimpan kunci Anda di browser ini)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'Gagal membuat ruang kerja: $error';
  }

  @override
  String committedRelative(String relative) {
    return 'di-commit $relative';
  }

  @override
  String get selectAgents => 'Pilih agen';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agen',
      one: '1 agen',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => 'Percakapan baru';

  @override
  String get untitledConversation => 'Percakapan tanpa judul';

  @override
  String get conversationTitleOptionalHint =>
      'Opsional — biarkan kosong dan model judul akan menamainya otomatis';

  @override
  String get conversationTitlesSectionTitle => 'Judul percakapan';

  @override
  String get conversationTitlesSectionCaption =>
      'Pilih runner yang menamai percakapan baru di ruang kerja ini secara otomatis. Judul tetap nonaktif sampai adapter dipilih, dan berlaku untuk setiap anggota.';

  @override
  String get conversationTitlesModelLabel => 'Model judul';

  @override
  String get conversationTitlesAdapterLabel => 'Adapter';

  @override
  String get conversationTitlesAdapterHint => 'Nonaktif';

  @override
  String get conversationTitlesAdapterOff => 'Nonaktif';

  @override
  String get startThread => 'Mulai thread';

  @override
  String get deleteSpaceConfirm => 'Hapus space ini? Semua pesan akan hilang.';

  @override
  String threadTabTitle(String title) {
    return 'Thread: $title';
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
    return 'Masuk dengan $provider';
  }

  @override
  String get signInAgain => 'Masuk lagi';

  @override
  String get signInNotFinished =>
      'Proses masuk belum kembali. Selesaikan di browser, lalu periksa lagi.';

  @override
  String get signedOutTitle => 'Anda sudah keluar';

  @override
  String get signedOutSubtitle =>
      'Koneksi hosting kode Anda tidak lagi valid — token kedaluwarsa, atau aksesnya dicabut. Tidak ada yang berubah: masuk lagi dan semuanya tetap seperti semula.';

  @override
  String get viaServerApp => 'lewat aplikasi server ini';

  @override
  String get ticketing => 'Tiket';

  @override
  String get ticketingProviderHelp =>
      'Tempat tiket Anda disimpan. Lokal menyimpannya di Control Center.';

  @override
  String providerComingSoon(String provider) {
    return '$provider (segera)';
  }

  @override
  String get ticketProviderLocal => 'Lokal';

  @override
  String get addKey => 'Tambah kunci';

  @override
  String get providerApps => 'Aplikasi penyedia';

  @override
  String get providerAppsDescription =>
      'Cara server ini mengautentikasi sebagai dirinya sendiri, dan lewat apa orang masuk. Pekerjaan latar belakang — webhook, polling, sinkronisasi — berjalan di aplikasi, bukan di token seseorang.';

  @override
  String get providerAppId => 'Id aplikasi';

  @override
  String get providerPrivateKey => 'Kunci privat';

  @override
  String get providerClientId => 'Id klien';

  @override
  String get providerClientSecret => 'Rahasia klien';

  @override
  String get providerApiKey => 'Kunci API';

  @override
  String get providerCallbackUrl => 'URL callback';

  @override
  String get providerAppFullyConfigured =>
      'Server dapat bertindak sebagai dirinya sendiri, dan orang dapat masuk.';

  @override
  String get providerAppServerOnly =>
      'Server dapat bertindak sebagai dirinya sendiri. Tambahkan id klien dan rahasia agar orang dapat masuk.';

  @override
  String get providerAppSignInOnly =>
      'Orang dapat masuk. Pekerjaan latar belakang memakai kredensial mereka.';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'Kredensial berfungsi. Dipasang di: $accounts';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return 'Masukkan kode ini di halaman $provider yang baru dibuka. Kode sudah disalin ke papan klip Anda.';
  }

  @override
  String get deviceCodeWaiting => 'Menunggu Anda menyelesaikan di browser…';

  @override
  String get copyCodeAndOpen => 'Salin kode dan buka';

  @override
  String get couldNotOpenBrowser =>
      'Browser tidak dapat dibuka. Salin tautan dan selesaikan masuk sendiri.';

  @override
  String get contextUsage => 'Penggunaan konteks';

  @override
  String get contextUsageFull => 'penuh';

  @override
  String get contextUsageTokens => 'token';

  @override
  String get contextSeeMore => 'Lihat selengkapnya';

  @override
  String get contextSegmentSystemPrompt => 'Prompt sistem';

  @override
  String get contextSegmentRules => 'Aturan';

  @override
  String get contextSegmentSkills => 'Skill';

  @override
  String get contextSegmentToolDefinitions => 'Definisi alat';

  @override
  String get contextSegmentMcpTools => 'MCP & alat dinamis';

  @override
  String get contextSegmentDeferredTools =>
      'Alat yang dimuat sesuai permintaan';

  @override
  String get contextSegmentSubagents => 'Definisi subagen';

  @override
  String get contextSegmentMemory => 'Memori';

  @override
  String get contextSegmentConversation => 'Percakapan';

  @override
  String get contextExplorerTitle => 'Konteks';

  @override
  String get contextExplorerEverything => 'Semua';

  @override
  String get contextExplorerSelectPart => 'Pilih bagian untuk memeriksa isinya';

  @override
  String get contextExplorerUnavailable => 'Rincian konteks tidak tersedia';

  @override
  String get contextRetry => 'Coba lagi';

  @override
  String get settingsFieldOptional => 'Opsional';

  @override
  String get settingsFilterHint => 'Saring daftar ini';

  @override
  String get settingsValueNotAvailable => 'Belum tersedia';

  @override
  String get settingsNoEntriesYet => 'Belum ada apa-apa di sini';

  @override
  String get settingsChangedBadge => 'Diubah';

  @override
  String get ssoConnectionCardDescription =>
      'Pilih cara orang masuk ke server ini, lalu aktifkan koneksi itu.';

  @override
  String get ssoUseSamlForSignIn => 'Gunakan SAML untuk masuk';

  @override
  String get ssoUseOidcForSignIn => 'Gunakan OpenID Connect untuk masuk';

  @override
  String get ssoSaveConnection => 'Simpan koneksi';

  @override
  String get ssoStateLive => 'Berjalan';

  @override
  String get ssoStateConfiguredOff => 'Dikonfigurasi, nonaktif';

  @override
  String get ssoStateOnIncomplete => 'Nyala, belum lengkap';

  @override
  String get ssoStateActive => 'Aktif';

  @override
  String get ssoStateAllowed => 'Diizinkan';

  @override
  String get ssoStateNoToken => 'Tidak ada token';

  @override
  String get ssoSummaryDirectorySync => 'Sinkronisasi direktori';

  @override
  String get ssoSummaryManualPairing => 'Pemadanan manual';

  @override
  String get ssoNoMethodLiveNote =>
      'Belum ada metode masuk yang berjalan. Perangkat baru bergabung dengan undangan atau kunci pemadanan sampai Anda mengonfigurasi koneksi dan mengaktifkannya.';

  @override
  String get ssoMethodSamlBlurb =>
      'Untuk penyedia identitas yang mendukung SAML 2.0, seperti Okta, Entra ID, atau Google Workspace.';

  @override
  String get ssoMethodOidcBlurb =>
      'Untuk penyedia identitas yang mendukung OpenID Connect. Biasanya lebih sederhana dari keduanya untuk disiapkan.';

  @override
  String get ssoGroupIdentityProvider => 'Penyedia identitas';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'Dari mana assertion berasal, dan cara server ini memverifikasinya.';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'Issuer yang dipercaya server ini, dan klien yang digunakan untuk autentikasi.';

  @override
  String get ssoSpEntityIdShortLabel => 'ID entitas SP';

  @override
  String get ssoSpEntityIdDescription =>
      'Kosongkan untuk menurunkannya dari URL server.';

  @override
  String get ssoIssuerDescription =>
      'URL dasar yang menyajikan dokumen discovery penyedia.';

  @override
  String get ssoSecretStored => 'Tersimpan';

  @override
  String get ssoGroupHandoff => 'Yang dibutuhkan identity provider Anda';

  @override
  String get ssoGroupHandoffDescription =>
      'Tempelkan ini ke aplikasi yang Anda buat di penyedia.';

  @override
  String get ssoOriginUnknownTitle =>
      'Server ini tidak mengetahui URL publiknya';

  @override
  String get ssoOriginUnknownBody =>
      'URL masuk dan callback dibuat dari URL tersebut, jadi penyedia tidak dapat menjangkau server ini sampai salah satunya diatur. Tambahkan URL publik atau aktifkan tunnel di Server → Koneksi.';

  @override
  String get ssoAcsUrlLabel => 'URL assertion consumer service (ACS)';

  @override
  String get ssoAcsUrlDescription =>
      'Tempat penyedia mengirim assertion yang ditandatangani.';

  @override
  String get ssoSpEntityIdResolvedLabel => 'ID entitas service provider';

  @override
  String get ssoMetadataUrlLabel => 'URL metadata SP';

  @override
  String get ssoMetadataUrlDescription =>
      'Penyedia yang mengimpor metadata dapat mengambilnya dari sini.';

  @override
  String get ssoRedirectUriLabel => 'URI pengalihan';

  @override
  String get ssoRedirectUriDescription =>
      'Tambahkan ini ke URI pengalihan yang diizinkan pada aplikasi penyedia.';

  @override
  String get ssoSignInUrlLabel => 'URL masuk';

  @override
  String get ssoSignInUrlDescription =>
      'Arahkan orang ke sini untuk memulai masuk dengan single sign-on.';

  @override
  String get ssoGroupAttributeMapping => 'Pemetaan atribut';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'Klaim mana yang membawa setiap bidang. Pertahankan default kecuali penyedia Anda mengubah namanya.';

  @override
  String get ssoGroupAccess => 'Akses dan peran';

  @override
  String get ssoGroupAccessDescription =>
      'Apa yang boleh dilakukan orang yang berhasil masuk.';

  @override
  String get ssoDefaultRoleShortLabel => 'Peran default';

  @override
  String get ssoDefaultRoleDescription =>
      'Diberikan kepada siapa pun yang grupnya tidak cocok dengan pemetaan di bawah.';

  @override
  String get ssoRoleMapShortLabel => 'Pemetaan grup ke peran';

  @override
  String get ssoRoleMapDescription =>
      'Grup yang cocok pertama yang berlaku. Owner tidak dapat diberikan dengan cara ini.';

  @override
  String get ssoRoleMapGroupHint => 'Nama grup dari penyedia Anda';

  @override
  String get ssoRoleMapAdd => 'Tambah pemetaan';

  @override
  String get ssoRoleMapEmpty =>
      'Tidak ada pemetaan — semua orang mendapat peran default.';

  @override
  String get ssoAdvancedSummary =>
      'Selisih jam, masuk yang dimulai IdP, kebijakan tanda tangan';

  @override
  String get ssoClockSkewShortLabel => 'Selisih jam';

  @override
  String get ssoClockSkewDescription =>
      'Detik toleransi pada stempel waktu assertion. 90 cocok untuk sebagian besar penyedia.';

  @override
  String get ssoScimGenerate => 'Buat token';

  @override
  String get ssoScimTokenOnceBody =>
      'Disalin ke papan klip. Ditampilkan sekali dan tidak dapat dipulihkan, jadi tempelkan ke penyedia sekarang.';

  @override
  String get ssoPairingCardTitle => 'Pemasangan manual';

  @override
  String get ssoPairingCardDescription =>
      'Cara lain masuk ke server ini: kode undangan dan kunci pemasangan, untuk perangkat yang tidak melalui single sign-on.';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count dari $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'Tidak ada penyedia yang terhubung, jadi runtime agen bawaan tidak punya tempat untuk berjalan. Tambahkan kunci API atau masuk ke salah satunya di bawah.';

  @override
  String get providersFilterHint => 'Filter penyedia';

  @override
  String get providersNoneMatch => 'Tidak ada yang cocok dengan filter ini';

  @override
  String get providerDeniedHereTitle => 'Ditolak di ruang kerja ini';

  @override
  String get providerDeniedHereBody =>
      'Agen di sini tidak dapat menggunakan penyedia ini, meskipun sudah terhubung. Ruang kerja lain tidak terpengaruh.';

  @override
  String get providerNeedsSignIn => 'Masuk untuk menggunakan penyedia ini';

  @override
  String get providerNeedsApiKey =>
      'Tambahkan kunci API untuk menggunakan penyedia ini';

  @override
  String get providerApiKeyLabel => 'Kunci API';

  @override
  String get providerGenerationDefaults => 'Default penyedia';

  @override
  String get providerNoModelsYet =>
      'Belum ada model yang dilaporkan. Hubungkan penyedia, lalu sinkronkan.';

  @override
  String get providerModelsFilterHint => 'Filter model';

  @override
  String get adaptersNoneReadyNote =>
      'Tidak ada CLI runner dalam katalog yang ditemukan di mesin ini. Instal salah satu, lalu segarkan.';

  @override
  String get adaptersFilterHint => 'Filter runner';

  @override
  String get adaptersLaunchGroup => 'Peluncuran';

  @override
  String get adaptersLaunchGroupDescription =>
      'Yang diberikan ke runner ini saat agen memulainya. Atur ini sebelum menginstal CLI jika Anda mau.';

  @override
  String get adaptersEnvNone => 'Tidak ada yang diatur';

  @override
  String adaptersEnvCount(int count) {
    return '$count diatur';
  }

  @override
  String get adapterArgumentsDescription =>
      'Ditambahkan ke baris perintah runner pada setiap peluncuran.';

  @override
  String get defaultChatDescription =>
      'Menjalankan percakapan baru dan agen tanpa runner sendiri.';

  @override
  String get shortTaskDescription =>
      'Menjalankan pekerjaan latar belakang cepat seperti judul dan ringkasan. Model yang lebih kecil cocok di sini.';

  @override
  String get settingsStateFailed => 'Gagal';

  @override
  String get providerAppsGroupServer => 'Bertindak sebagai server';

  @override
  String get providerAppsGroupServerDescription =>
      'Memungkinkan pekerjaan latar belakang menjangkau repositori tanpa manusia di balik permintaan: webhook, polling pull request, sinkronisasi tiket.';

  @override
  String get providerAppsGroupPrConversations => 'Percakapan pull request';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'Cara pengembang berbicara dengan server ini langsung di GitHub. Berfungsi tanpa webhook atau URL publik — server melakukan polling.';

  @override
  String get providerAppBotLogin => 'Login bot';

  @override
  String get providerAppBotLoginEmpty =>
      'Uji koneksi untuk menentukan login bot.';

  @override
  String get providerAppAskOnGitHub => 'Bertanya di GitHub';

  @override
  String get providerAppAskOnGitHubHint =>
      'Sebut login bot di atas dalam komentar pull request — akhiran [bot] bersifat opsional — untuk meminta tinjauan atau mengajukan pertanyaan, membalas di dalam thread tinjauannya, atau menambahkan label `ai-review` untuk meminta tinjauan.';

  @override
  String get providerAppsGroupSignIn => 'Masukkan anggota';

  @override
  String get providerAppsGroupSignInDescription =>
      'Memungkinkan setiap anggota menghubungkan akunnya sendiri dan mendapat kredensial sendiri.';

  @override
  String get providerAppCapActsAsServer => 'Bertindak sebagai server';

  @override
  String get providerAppCapSignsIn => 'Memasukkan anggota';

  @override
  String get portLabel => 'Port';

  @override
  String get mcpNoTokenWarning =>
      'Tanpa token, apa pun yang dapat menjangkau port ini dapat memanggil setiap tool.';

  @override
  String get mcpBridgedToolsLabel => 'Tool';

  @override
  String get guardrailFamilyFiles => 'File';

  @override
  String get guardrailFamilyGit => 'Git dan pull request';

  @override
  String get guardrailFamilyMachine => 'Mesin dan jaringan';

  @override
  String get guardrailFamilyControl => 'Rahasia dan ruang kerja';

  @override
  String get guardrailScopeFieldLabel => 'Mengedit aturan untuk';

  @override
  String get guardrailScopeFieldDescription =>
      'Cakupan yang lebih sempit mengalahkan yang lebih luas. Aturan yang ditetapkan di sini berlaku di atas yang diwarisi.';

  @override
  String get guardrailSetHere => 'Ditetapkan di sini';

  @override
  String get guardrailClearAllHere => 'Hapus semua';

  @override
  String get sandboxingCardLabel => 'Sandboxing';

  @override
  String get sandboxingCardDescription =>
      'Apakah pekerjaan agen berjalan terisolasi dari host ini, dan apa yang masih dapat dijangkau agen terisolasi.';

  @override
  String get sandboxBackendNoneActive => 'Host, tanpa isolasi';

  @override
  String get sandboxSummaryHost => 'Host';

  @override
  String get sandboxGroupIsolation => 'Isolasi';

  @override
  String get sandboxGroupIsolationDescription =>
      'Tempat proses dan penulisan file agen benar-benar terjadi.';

  @override
  String get sandboxBackendFieldDescription =>
      'Otomatis memilih yang terkuat yang didukung host ini. Sematkan satu agar tidak berubah di luar kendali Anda.';

  @override
  String get sandboxCapabilitiesDescription =>
      'Lubang yang menembus batas. Masing-masing adalah hal yang masih dapat dilakukan agen terisolasi terhadap dunia luar.';

  @override
  String get sandboxSummaryInForce => 'Berlaku';

  @override
  String get rigsInstallHintLabel => 'Cara menginstalnya';

  @override
  String get rigsStarting => 'Memulai';

  @override
  String get rigsResidentMemory => 'Memori residen';

  @override
  String get installedLabel => 'Terinstal';

  @override
  String get notInstalledLabel => 'Tidak terinstal';

  @override
  String ssoOtherKindUnsaved(String method) {
    return '$method memiliki perubahan yang belum disimpan';
  }

  @override
  String get collapseComment => 'Ciutkan komentar';

  @override
  String get expandComment => 'Bentangkan komentar';

  @override
  String get suggestedChange => 'Perubahan yang disarankan';

  @override
  String get emptyComment => 'Komentar kosong';

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
  String get pendingReview => 'Menunggu tinjauan';

  @override
  String failedToResolveConversation(String error) {
    return 'Tidak dapat memperbarui percakapan: $error';
  }

  @override
  String get addSingleComment => 'Tambahkan komentar tunggal';

  @override
  String get addToReview => 'Tambahkan ke tinjauan';

  @override
  String get startAReview => 'Mulai tinjauan';

  @override
  String get reviewNeedsABody =>
      'Tulis ringkasan atau antrekan komentar sebaris dulu';

  @override
  String get reviewSubmitted => 'Tinjauan dikirim';

  @override
  String get finishYourReview => 'Selesaikan tinjauan Anda';

  @override
  String get commentVerdict => 'Komentar';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count komentar tertunda',
      one: '1 komentar tertunda',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 'dan $count lainnya';
  }

  @override
  String get queuedCommentHint =>
      'Komentar ini dikirim saat Anda mengirimkan tinjauan.';

  @override
  String commentOnLinesRange(int start, int end) {
    return 'Baris $start sampai $end';
  }

  @override
  String get claudeAccountsTitle => 'Akun Claude Code';

  @override
  String get claudeAccountsDescription =>
      'Setiap akun adalah login Claude Code terpisah. Run memakai akun yang terlampir di bawah, dalam urutan ini.';

  @override
  String get claudeAccountsEmpty => 'Belum ada akun';

  @override
  String get claudeAccountAdd => 'Tambah akun';

  @override
  String get claudeAccountSignIn => 'Masuk';

  @override
  String get claudeAccountSignInAgain => 'Masuk lagi';

  @override
  String get claudeAccountSignInHint =>
      'Jalankan ini di terminal di server. Perintah ini membuka browser untuk menyelesaikan login, lalu menulis kredensial ke direktori akun ini.';

  @override
  String get claudeAccountSignedOut => 'Keluar';

  @override
  String get claudeAccountExpired => 'Login kedaluwarsa';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'Login kedaluwarsa pada $when. Masuk lagi untuk memakai akun ini.';
  }

  @override
  String get claudeAccountMakeDefault => 'Jadikan default';

  @override
  String get claudeAccountDefault => 'Default';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return 'Hapus $label?';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'Ini mengeluarkan akun dan menghapus direktorinya di server. Login-nya sendiri tidak terpengaruh.';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'Tidak dapat memeriksa akun ini: $error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return '$percent% terpakai';
  }

  @override
  String get accountPoolStrategy => 'Rotasi';

  @override
  String get accountPoolPinned => 'Disematkan';

  @override
  String get accountPoolRoundRobin => 'Round robin';

  @override
  String get accountPoolSerial => 'Satu per satu';

  @override
  String get accountPoolPinnedHint =>
      'Selalu mulai dari akun pertama. Yang lain tetap sebagai cadangan jika gagal.';

  @override
  String get accountPoolRoundRobinHint =>
      'Sebar run ke semua akun, pindah ke yang berikutnya setiap dispatch.';

  @override
  String get accountPoolSerialHint =>
      'Habiskan akun pertama sebelum memakai yang berikutnya.';

  @override
  String get accountPoolMoveUp => 'Naikkan';

  @override
  String get accountPoolMoveDown => 'Turunkan';

  @override
  String get accountPoolUsingAll =>
      'Belum ada yang terlampir — semua akun dipakai, dalam urutan ini.';

  @override
  String get accountPoolInheriting => 'Mewarisi akun ruang kerja.';

  @override
  String get accountPoolResetToWorkspace => 'Reset ke akun ruang kerja';

  @override
  String accountPoolCoolingOff(String when) {
    return 'kuota habis sampai $when';
  }

  @override
  String get accountPoolSignedOut => 'keluar';

  @override
  String get accountPoolExpired => 'login kedaluwarsa';

  @override
  String accountPoolLoadFailed(String error) {
    return 'Tidak dapat memuat rotasi: $error';
  }

  @override
  String get providerSignedInAccount => 'akun yang masuk';

  @override
  String get agentAccountsTab => 'Akun';

  @override
  String get agentClaudeAccountsNoticeTitle => 'Beberapa akun Claude Code';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return 'Runner ini masuk sebagai salah satu dari $count akun Claude Code di host ini. Pilih yang mana, atau rotasi di antaranya, di tab Akun.';
  }

  @override
  String get agentAccountsDescription =>
      'Akun mana yang dipakai run agen ini. Setiap blok awalnya mewarisi pilihan ruang kerja.';

  @override
  String get agentAccountsNothingToRotate =>
      'Tidak ada yang dirotasi — sambungkan akun atau kunci kedua dulu.';

  @override
  String failedToPostReply(String error) {
    return 'Tidak dapat mengirim balasan: $error';
  }

  @override
  String commentOnLine(int line) {
    return 'Baris $line';
  }

  @override
  String get viewInDiff => 'Lihat di diff';

  @override
  String get subscriptionUsagePreviousAccount => 'Akun sebelumnya';

  @override
  String get subscriptionUsageNextAccount => 'Akun berikutnya';

  @override
  String inReplyTo(String path) {
    return 'Membalas $path';
  }

  @override
  String get subscriptionUsageNoneReported =>
      'Tidak ada pemakaian yang dilaporkan untuk akun ini.';

  @override
  String get subscriptionUsageCredits => 'Kredit';

  @override
  String get reviewHubStaticRule => 'Aturan statis';

  @override
  String get reviewHubStarted => 'Review dimulai';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'Ditemukan oleh aturan deterministik ($rule) pada baris yang ditambahkan pull request ini — bukan oleh agen reviewer.';
  }

  @override
  String get prReviewArtifactTab => 'PR review';

  @override
  String get prReviewRunning => 'Mereview pull request ini…';

  @override
  String get prReviewStarting => 'Memulai review…';

  @override
  String get prReviewStartingBody =>
      'Menyiapkan pohon kerja pull request ini. Reviewer mulai segera setelah siap.';

  @override
  String get prReviewFailed => 'Review gagal.';

  @override
  String get prReviewRerunning => 'Mereview ulang…';

  @override
  String get prReviewNoOpenFindings => 'Tidak ada temuan terbuka';

  @override
  String prReviewOpenFindings(int count) {
    return '$count temuan terbuka';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used dari $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return 'Mengirim $posted komentar sebagai bot. $skipped dilewati (tanpa jangkar file), $failed gagal.';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count temuan menarget kode yang tidak diubah pull request ini ($files). GitHub hanya menerima komentar sebaris pada diff.';
  }

  @override
  String get reviewRailReport => 'Laporan';

  @override
  String get reviewNoFindingsTitle => 'Belum ada temuan review';

  @override
  String get reviewNoFindingsHint =>
      'Temuan muncul di sini saat agen mengirimkannya.';

  @override
  String reviewShowDismissed(int count) {
    return 'Tampilkan $count yang diabaikan';
  }

  @override
  String reviewHideDismissed(int count) {
    return 'Sembunyikan $count yang diabaikan';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ketidaksetujuan reviewer terdeteksi',
      one: '1 ketidaksetujuan reviewer terdeteksi',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'Jenis';

  @override
  String get reviewFilterStatus => 'Status';

  @override
  String get reviewKindBug => 'Bug';

  @override
  String get reviewKindSuggestion => 'Saran';

  @override
  String get reviewKindRecommendation => 'Rekomendasi';

  @override
  String get reviewKindQuestion => 'Pertanyaan';

  @override
  String get reviewKindTicket => 'Tiket';

  @override
  String get archiveSpace => 'Arsipkan ruang';

  @override
  String get archivedSpaces => 'Ruang terarsip';

  @override
  String get archivedSpacesEmpty => 'Tidak ada ruang terarsip';

  @override
  String get restoreSpace => 'Pulihkan';

  @override
  String archivedWhen(String time) {
    return 'Diarsipkan $time';
  }

  @override
  String get deleteSpacePermanently => 'Hapus permanen';

  @override
  String get renameSpace => 'Ubah nama ruang';

  @override
  String get renameConversation => 'Ubah nama percakapan';

  @override
  String get spaceActions => 'Tindakan ruang';

  @override
  String get conversationActions => 'Tindakan percakapan';

  @override
  String get editSpaceRepos => 'Edit repositori';

  @override
  String get editSpaceReposTitle => 'Repositori ruang';

  @override
  String get editSpaceReposWarning =>
      'Menambah repositori akan checkout ke ruang ini; menghapusnya akan menghapus foldernya.';

  @override
  String get agentSectionIdentity => 'Identitas';

  @override
  String get agentSectionRuntime => 'Runtime';

  @override
  String get agentSectionGuardrails => 'Pagar pengaman';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bawahan',
      one: '1 bawahan',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'Filter tim…';

  @override
  String get teamsSummaryWithLeader => 'Dengan pemimpin';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tim',
      one: '1 tim',
      zero: 'Tidak ada tim',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return 'Menghapus $name akan menghapus profil, tautan skill, dan riwayat jalannya. Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get resetToDefault => 'Reset ke default';

  @override
  String get newAgent => 'Agen baru';

  @override
  String get newSkill => 'Skill baru';

  @override
  String get zoomIn => 'Perbesar';

  @override
  String get zoomOut => 'Perkecil';

  @override
  String get resetZoom => 'Reset zoom';

  @override
  String get imageHostedOnGitHub => 'Gambar di-host di GitHub';

  @override
  String get imageOpenExternally => 'Gambar · buka secara eksternal';

  @override
  String get memoryScopeAll => 'Semua cakupan';

  @override
  String get memoryScopeWorkspace => 'Seluruh ruang kerja';

  @override
  String get memoryScopeFilterLabel => 'Filter menurut cakupan';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return 'Dibatasi ke repositori $repo';
  }

  @override
  String get toolScreenshot => 'Tangkapan layar dari agen';

  @override
  String get toolImageUnavailable => 'Gambar tidak tersedia';

  @override
  String toolImagesUnavailable(int count) {
    return '$count gambar tidak tersedia';
  }

  @override
  String get shakeUnavailable => 'Shake tidak tersedia di server ini';

  @override
  String get shakeNothing =>
      'Tidak ada yang bisa di-shake — giliran terbaru dilindungi';

  @override
  String shakeDone(int tokens) {
    return 'Membebaskan sekitar $tokens token';
  }

  @override
  String get compactionDivider => 'Dipadatkan';

  @override
  String compactionDividerCount(int count) {
    return 'Dipadatkan · $count pesan dilipat';
  }

  @override
  String get composerDropToAttach => 'Lepas untuk lampirkan';

  @override
  String get attachmentUnavailable => 'Lampiran tidak tersedia';

  @override
  String get attachmentUnavailableDetail =>
      'Lampiran ini tidak lagi disimpan di memori. Lampirkan lagi untuk melihat pratinjaunya.';

  @override
  String get attachmentPreviewFailed => 'Tidak dapat membuka file ini';

  @override
  String get attachmentPreviewUnsupported =>
      'Tidak ada pratinjau untuk jenis file ini';

  @override
  String get attachmentTooLargeToPreview => 'Terlalu besar untuk dipratinjau';

  @override
  String get attachmentOpenExternally => 'Buka di aplikasi default';

  @override
  String get asideUnavailable =>
      'Atur model one-shot di pengaturan ruang kerja untuk menggunakan ini';

  @override
  String get asideEmpty => 'Belum ada yang bisa dikerjakan';

  @override
  String get asideFailed => 'Tidak bisa mendapatkan jawaban';

  @override
  String get handoffTitle => 'Serah terima';

  @override
  String get asideTitle => 'Pertanyaan sampingan';

  @override
  String get attachFilesOrDrop => 'Lampirkan file — atau jatuhkan di sini';

  @override
  String get guidedGoalTitle => 'Perjelas tujuan';

  @override
  String get guidedGoalIntro =>
      'Agen yang bekerja tanpa pengawasan perlu tahu persis kapan pekerjaannya selesai. Beberapa pertanyaan dulu.';

  @override
  String get guidedGoalAnswerHint => 'Jawaban Anda';

  @override
  String get guidedGoalNext => 'Lanjut';

  @override
  String get guidedGoalStart => 'Mulai tujuan';

  @override
  String get guidedGoalSkip => 'Lewati dan jalankan apa adanya';

  @override
  String guidedGoalStillMissing(String items) {
    return 'Masih belum ditentukan: $items';
  }

  @override
  String get conversationTreeTitle => 'Pohon percakapan';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cabang',
      one: '1 cabang',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'Lanjutkan dari sini';

  @override
  String get conversationTreeFork => 'Cabangkan ke percakapan baru';

  @override
  String get conversationTreeCurrent => 'Di cabang ini';

  @override
  String get conversationTreeEmpty => 'Belum ada apa pun di sini';

  @override
  String get conversationTreeForked => 'Dibuat percakapan baru dari sini';

  @override
  String get conversationTreeSwitched => 'Sekarang dilanjutkan dari pesan itu';

  @override
  String exportSaved(String path) {
    return 'Disimpan ke $path';
  }

  @override
  String get exportFailed => 'Tidak bisa menulis ekspor';

  @override
  String get contextCommandNoAgent =>
      'Tidak ada agen di percakapan ini, jadi tidak ada jendela konteks yang bisa dibuka';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'Tidak ada agen bernama “$name” di percakapan ini. Coba: $names';
  }

  @override
  String get dumpCopied => 'Transkrip disalin ke papan klip';

  @override
  String get messageQueueHint =>
      'Terus ketik untuk mengantrekan perubahan lanjutan';

  @override
  String get steerNow => 'Arahkan';

  @override
  String get steeringQueueLabel => 'Pesan pengarahan dalam antrean';

  @override
  String get steeringDeliverUnavailable =>
      'Tidak ada agen yang sedang berjalan yang bisa menerimanya sekarang — tetap dalam antrean.';

  @override
  String get reorderSteeringCard => 'Ubah urutan pesan dalam antrean';

  @override
  String get editSteeringCard => 'Edit pesan dalam antrean';

  @override
  String get deleteSteeringCard => 'Hapus pesan dalam antrean';

  @override
  String get steeringBadge => 'Diarahkan';

  @override
  String get settingsSandboxLabel => 'Sandbox';

  @override
  String get sandboxExecGrantsTitle => 'Izin program';

  @override
  String get sandboxExecGrantsSubtitle =>
      'Program yang boleh dijalankan agen dari salinan kerja repositori Anda. Setiap entri Anda setujui saat sandbox menanyakan.';

  @override
  String get sandboxExecGrantsEmpty =>
      'Belum ada keputusan tercatat. Anda akan ditanya saat pertama kali agen perlu menjalankan program dari salinan kerjanya.';

  @override
  String get sandboxExecGrantRevoke => 'Cabut';

  @override
  String get sandboxExecGrantAllowed => 'Diizinkan';

  @override
  String get sandboxExecGrantBlocked => 'Diblokir';

  @override
  String get sandboxExecGrantRevokeConfirmTitle => 'Cabut keputusan ini?';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'Anda akan ditanya lagi saat agen perlu menjalankan program dari salinan ini.';

  @override
  String get repoScriptsTest => 'Tes';

  @override
  String get repoScriptsTestTooltip =>
      'Jalankan draf ini di klon repo yang sekali pakai';

  @override
  String get repoScriptsRunKindTest => 'Tes';

  @override
  String get demoBadgeLabel => 'Demo';

  @override
  String get demoFilePickerTitle => 'File demo';

  @override
  String get demoFilePickerBody =>
      'Demo mensimulasikan unggahan: pilih salah satu dan dilampirkan ke pesan tanpa menyentuh disk.';

  @override
  String get demoFilePickerAttach => 'Lampirkan';

  @override
  String get demoReadOnlySave => 'Hanya baca di demo';

  @override
  String get demoBadgeTooltip =>
      'Anda sedang menjelajahi demo. Datanya fiktif dan agen-agennya mengikuti skrip.';

  @override
  String get demoFirstRunTitle => 'Anda sedang dalam demo langsung';

  @override
  String demoFirstRunBody(int minutes) {
    return 'Ini aplikasi sungguhan yang berjalan di kode sungguhan — hanya datanya yang fiktif. Agen menayangkan jalankan sungguhan dari skrip, jadi tidak ada yang sampai ke model dan tidak ada yang dijalankan di mesin. Ruang kerja ini milik Anda sendiri dan hilang setelah $minutes menit.';
  }

  @override
  String get demoFirstRunDismiss => 'Mengerti';

  @override
  String get demoTourTitle => 'Yang perlu dilihat dulu';

  @override
  String get demoTourSubtitle =>
      'Empat tempat yang menunjukkan apa yang benar-benar dilakukan aplikasi.';

  @override
  String get demoTourSkip => 'Lewati';

  @override
  String get demoTourStarRepo => 'Beri bintang di GitHub';

  @override
  String get demoTourOpen => 'Buka';

  @override
  String get demoTourSpacesTitle => 'Bicara dengan agen';

  @override
  String get demoTourSpacesBody =>
      'Kirim pesan di space dan saksikan run streaming masuk — alur berpikir, pemanggilan tool, dan biaya, persis seperti run sungguhan.';

  @override
  String get demoTourReviewTitle => 'Tinjau pull request';

  @override
  String get demoTourReviewBody =>
      'Buka #412. Tinggalkan komentar sebaris atau kirim review; kata Anda masuk ke thread dan tetap di sana.';

  @override
  String get demoTourTicketsTitle => 'Ikuti pekerjaannya';

  @override
  String get demoTourTicketsBody =>
      'Tiket, todo, dan rencana tertaut ke percakapan yang sama yang sedang dijalani agen.';

  @override
  String get demoTourInboxTitle => 'Lihat seluruh operasi';

  @override
  String get demoTourInboxBody =>
      'Setiap peringatan dari setiap pilar masuk ke satu kotak masuk — review, tiket, run, dan rapat.';

  @override
  String get demoUnavailableTitle => 'Tidak tersedia di demo';

  @override
  String get demoUnavailableTerminal =>
      'Terminal menjalankan shell sungguhan di host server. Demo tidak punya permukaan eksekusi sama sekali — itulah yang membuatnya aman dibuka ke publik.';

  @override
  String get demoUnavailableRig =>
      'Enclosure adalah mesin virtual sekali pakai yang dikendalikan agen. Demo tidak menyalakan satu pun: endpoint publik yang bisa menyalakan VM bukanlah demo.';

  @override
  String get demoUnavailableEditor =>
      'Editor di browser menjalankan proses code-server terhadap checkout sungguhan. Demo tidak punya keduanya.';

  @override
  String get demoUnavailableFeeds =>
      'Demo membaca feed sungguhan, tetapi daftar langganannya tetap. Menambah atau menghapus langganan dinonaktifkan di sini.';

  @override
  String get demoUnavailableForge =>
      'Demo tidak menyimpan kredensial dan tidak pernah menghubungi GitHub, GitLab, atau Linear. Pull request-nya adalah fixture, dan komentar Anda disimpan secara lokal.';

  @override
  String get demoUnavailableModels =>
      'Demo tidak memanggil model. Run agen adalah pemutaran terskrip, jadi tidak berbiaya dan tidak menyentuh provider mana pun.';

  @override
  String get demoUnavailableMcp =>
      'Permukaan tool MCP tidak dipasang di demo, jadi klien eksternal tidak bisa terhubung.';

  @override
  String get demoUnavailableRepos =>
      'Demo tidak melakukan checkout kode dan tidak menjalankan git. Repositori yang Anda lihat adalah fixture di balik pull request.';

  @override
  String get demoUnavailableSkills =>
      'Menginstal skill mengunduh dan memindai kode. Demo tidak mengambil apa pun.';

  @override
  String get demoUnavailableSso =>
      'Single sign-on adalah konfigurasi server. Demo malah memasukkan Anda sebagai tamu sementara.';

  @override
  String get demoUnavailableAudio =>
      'Perekaman dan dikte membutuhkan penangkapan audio dan model ucapan di host. Demo tidak menyertakan keduanya, jadi rapatnya berupa transkrip tanpa pemutaran.';

  @override
  String get demoUnavailableServerAdmin =>
      'Ini administrasi server. Demo memberi setiap pengunjung ruang kerja sekali pakai sendiri, dan tidak lebih dari itu.';

  @override
  String get demoUnavailablePipelines =>
      'Pipeline tidak dapat dijalankan di sini. Pengunjung yang dapat menulis langkah bash dan menjalankannya — secara manual atau melalui pemicu peristiwa — sedang mengeksekusi kode di host ini.';

  @override
  String get settingsBackupRestore => 'Cadangan & pemulihan';

  @override
  String get settingsBackupRestoreDescription =>
      'Snapshot setiap basis data di server ini, plus ekspor, impor, dan hapus untuk satu ruang kerja.';

  @override
  String get backupSnapshotsLabel => 'Snapshot instalasi';

  @override
  String get backupSnapshotsExplainer =>
      'Snapshot menyalin setiap basis data ke folder bertanda waktu di host server. Memulihkan seluruh instalasi berarti menyalin folder itu kembali dengan server dihentikan; satu ruang kerja bisa dipulihkan dari sini.';

  @override
  String get backupNowAction => 'Cadangkan sekarang';

  @override
  String backupSnapshotWritten(String path) {
    return 'Snapshot ditulis ke $path';
  }

  @override
  String get backupNoSnapshots =>
      'Belum ada snapshot. Snapshot hanya diambil saat Anda memintanya — tidak ada yang dijadwalkan.';

  @override
  String get backupSnapshotComplete => 'Lengkap';

  @override
  String get backupSnapshotIncomplete => 'Tidak lengkap';

  @override
  String get backupSnapshotIncompleteNote =>
      'Manifest hilang atau merujuk file yang tidak ada, jadi snapshot ini tidak bisa memulihkan seluruh instalasi. File ruang kerja yang ada masih bisa diadopsi satu per satu.';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ruang kerja',
      one: '1 ruang kerja',
      zero: 'Tidak ada ruang kerja',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ruang kerja tidak terekam',
      one: '1 ruang kerja tidak terekam',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'Path di server';

  @override
  String get backupRestoreAction => 'Pulihkan';

  @override
  String get backupRestoreTitle => 'Pulihkan ruang kerja';

  @override
  String backupRestoreBody(String name) {
    return 'Ini mengganti semua isi $name dengan salinan di snapshot ini. Apa pun yang dilakukan ruang kerja itu sejak snapshot diambil akan hilang, dan tidak bisa dibatalkan.';
  }

  @override
  String backupRestoreDone(String name) {
    return '$name dipulihkan dari snapshot.';
  }

  @override
  String get backupWorkspaceUnknown => 'Sudah tidak ada di server ini';

  @override
  String get backupWorkspaceDataLabel => 'Data ruang kerja';

  @override
  String get backupWorkspaceDataExplainer =>
      'Satu ruang kerja adalah satu file basis data, jadi mengekspornya menyalin file itu, bukan dump per tabel. Mengimpor mengganti semua isi ruang kerja tujuan dengan file yang Anda tentukan.';

  @override
  String get backupExportAction => 'Ekspor';

  @override
  String backupExportDone(String path) {
    return 'Diekspor ke $path';
  }

  @override
  String get backupExportedFileLabel => 'File ekspor di server';

  @override
  String get backupImportAction => 'Impor';

  @override
  String backupImportTitle(String name) {
    return 'Impor ke $name';
  }

  @override
  String backupImportBody(String name) {
    return 'Ini mengganti semua isi $name dengan isi file. Apa pun yang ada di ruang kerja itu sekarang akan hilang, dan tidak bisa dibatalkan.';
  }

  @override
  String get backupImportSourceLabel => 'File basis data ruang kerja';

  @override
  String get backupImportSourceDescription =>
      'File .db yang bisa dibaca server. Path diselesaikan di host server, bukan di perangkat ini.';

  @override
  String backupImportDone(String name) {
    return 'Diimpor ke $name.';
  }

  @override
  String backupDeleteBody(String name) {
    return '$name hilang dari setiap daftar dan pencarian. File basis datanya tetap di disk, cadangan masih menyertakannya, dan ruang tidak diklaim kembali secara otomatis.';
  }

  @override
  String get backupExportDescription =>
      'Tulis salinan di server, atau unduh ke perangkat ini.';

  @override
  String get backupExportOnServerAction => 'Simpan di server';

  @override
  String get backupDownloadAction => 'Unduh';

  @override
  String backupDownloadSaved(String path) {
    return 'Disimpan ke $path';
  }

  @override
  String get backupDownloadInBrowser => 'Browser Anda sedang mengunduhnya.';

  @override
  String get backupRestoreFromDeviceLabel => 'Pulihkan dari perangkat ini';

  @override
  String get backupRestoreFromDeviceDescription =>
      'Pilih file basis data ruang kerja di sini dan Control Center mengunggahnya ke server. Ini yang berfungsi jika server bukan mesin ini.';

  @override
  String get backupUploadAction => 'Pilih file lalu unggah';

  @override
  String get backupTransferUnavailable =>
      'Koneksi ini mencapai server lewat relay, yang tidak membawa transfer file. Hubungkan ke server secara langsung untuk mengunduh atau mengunggah cadangan.';

  @override
  String get backupTransferForbidden =>
      'Server menolak. Mengunduh ruang kerja memerlukan peran admin, memulihkan memerlukan owner, dan snapshot utuh memerlukan operator instalasi.';

  @override
  String get backupTransferUnsupported =>
      'Server ini tidak punya permukaan cadangan.';

  @override
  String get backupTransferTooLarge =>
      'File lebih besar dari yang diterima server.';

  @override
  String get credentialGateWaitingTitle => 'Menunggu kredensial';

  @override
  String credentialGateHarnessTitle(String provider) {
    return '$provider tidak punya kredensial';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Code sudah keluar';

  @override
  String get credentialGateExpiredTitle =>
      'Masuk Claude Code Anda sudah kedaluwarsa';

  @override
  String get credentialGatePlanSpentTitle => 'Batas paket Claude Code tercapai';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent menunggu untuk lanjut.';
  }

  @override
  String get credentialGateWaitingRun => 'Run menunggu untuk lanjut.';

  @override
  String get credentialGateWatching =>
      'Memantau perbaikan — run berlanjut sendiri.';

  @override
  String credentialGateFreesUpAt(String time) {
    return 'Tersedia lagi pada $time';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'Run menyerah pada $time';
  }

  @override
  String get credentialGateCheckAgain => 'Periksa lagi';

  @override
  String get credentialGateCancelRun => 'Batalkan run';

  @override
  String get credentialGateAccountsTried => 'Akun yang dicoba';

  @override
  String get credentialGateClaudeSignInHint =>
      'Masuk dari Pengaturan → Adapters → Claude Code, atau jalankan perintah login di terminal. Run mengambilnya sendiri.';

  @override
  String get credentialGateOpenSettings => 'Buka pengaturan';

  @override
  String get selectModel => 'Pilih model';

  @override
  String get allModels => 'Semua model';

  @override
  String get noModelsMatchSearch =>
      'Tidak ada model yang cocok dengan pencarian Anda';

  @override
  String useCustomModelId(String id) {
    return 'Gunakan “$id”';
  }

  @override
  String get modelFree => 'Gratis';

  @override
  String modelOutputTokens(String tokens) {
    return '$tokens keluaran';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return '$input masukan / $output keluaran per 1M token';
  }

  @override
  String modelEffortLevels(String levels) {
    return 'Upaya penalaran: $levels';
  }

  @override
  String get modelSupportsReasoning => 'Mendukung upaya penalaran';

  @override
  String get profileDeliveryMetrics => 'Metrik pengiriman';

  @override
  String profileMetricsSample(int count) {
    return 'PR yang dianalisis: $count';
  }

  @override
  String get profileMergeRate => 'Tingkat penggabungan';

  @override
  String get profileReviewCoverage => 'Cakupan tinjauan';

  @override
  String get profilePrSize => 'Ukuran PR';

  @override
  String get profileTimeToMerge => 'Waktu hingga digabungkan';

  @override
  String get profileMergeTimeTrend => 'Tren waktu penggabungan';

  @override
  String get profileWeeklyMedian => 'Median mingguan, skala logaritmik';

  @override
  String get profilePrOpeningPattern =>
      'Hari dalam seminggu × jam, waktu lokal';

  @override
  String get profileFirstReview => 'Waktu hingga tinjauan pertama';

  @override
  String get profileMetricsTruncated =>
      'Persentil menggunakan sampel terbatas dari pull request yang tersedia.';

  @override
  String profileLinesChanged(String count) {
    return '$count baris';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count mnt';
  }

  @override
  String profileDurationHours(int count) {
    return '$count jam';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '$days hr $hours jam';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return 'Anggota: $count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return 'Tidak ada pull request oleh $team di ruang kerja ini';
  }

  @override
  String get profilePrStateFilterLabel =>
      'Filter pull request berdasarkan status';

  @override
  String get noProfilePrsMatchSearchHint =>
      'Coba judul atau nomor pull request lain';

  @override
  String get rigNetworkUnrestricted => 'Jaringan tanpa batasan';

  @override
  String get rigNetworkAllowAllHosts => 'Izinkan semua host';

  @override
  String get rigBrowserPermissionsTitle => 'Izin situs';

  @override
  String get rigBrowserPermissionsTooltip => 'Izin situs dan jaringan';

  @override
  String get rigBrowserPermissionEmpty => 'Belum ada situs yang meminta izin';

  @override
  String rigBrowserPermissionPrompt(String origin, String permission) {
    return '$origin ingin menggunakan $permission';
  }

  @override
  String get rigBrowserPermissionBlock => 'Blokir';

  @override
  String get rigBrowserPermissionCamera => 'Kamera';

  @override
  String get rigBrowserPermissionMicrophone => 'Mikrofon';

  @override
  String get rigBrowserPermissionNotifications => 'Notifikasi';

  @override
  String get rigBrowserPermissionGeolocation => 'Lokasi';

  @override
  String get rigBrowserPermissionPersistentStorage => 'Penyimpanan persisten';

  @override
  String get rigBrowserPermissionClipboard => 'Papan klip';

  @override
  String get rigBrowserPermissionDisplayCapture => 'Tangkapan layar';

  @override
  String get rigBrowserPermissionMidi => 'MIDI';

  @override
  String get rigNetworkBypassTitle => 'Izinkan setiap host jaringan?';

  @override
  String get rigNetworkBypassBody =>
      'Tindakan ini memulai ulang lingkungan terisolasi dan membuang pekerjaan yang belum di-commit di dalamnya. Setelah itu, sistem tamu dapat menjangkau host jaringan mana pun hingga ditutup.';

  @override
  String get rigNetworkRestartUnrestricted => 'Mulai ulang tanpa batasan';

  @override
  String get rigNetworkUnrestrictedBody =>
      'Lingkungan terisolasi ini dapat menjangkau setiap host jaringan. Tutup dan buka yang baru untuk memulihkan batasan default.';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      'Emulator Android ini sudah mengelola jaringannya sendiri, sehingga Control Center tidak dapat menerapkan daftar host yang diizinkan. Tidak perlu memulai ulang.';

  @override
  String get rigClipboardPermissionHostToRigTitle =>
      'Tempel papan klip ke lingkungan ini?';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'Control Center akan membaca papan klip perangkat Anda dan mengirim isinya ke lingkungan. Isi papan klip dapat berisi kata sandi atau rahasia lain.';

  @override
  String get rigClipboardPermissionRigToHostTitle =>
      'Salin papan klip dari lingkungan ini?';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'Control Center akan membaca papan klip lingkungan dan mengganti papan klip perangkat Anda dengan isinya. Perlakukan konten dari lingkungan sebagai tidak tepercaya.';

  @override
  String get rigClipboardAllowTenMinutes => 'Izinkan selama 10 menit';

  @override
  String get rigClipboardAlwaysAllow => 'Selalu izinkan';

  @override
  String get rigClipboardSettingsTitle => 'Akses papan klip';

  @override
  String get rigClipboardSettingsHint =>
      'Pilih transfer papan klip mana yang dapat berjalan tanpa bertanya. Izin sementara kedaluwarsa setelah 10 menit.';

  @override
  String get rigClipboardAlwaysPasteTitle =>
      'Selalu izinkan tempel ke lingkungan';

  @override
  String get rigClipboardAlwaysPasteDescription =>
      'Kirim papan klip perangkat ini ke lingkungan mana pun tanpa bertanya.';

  @override
  String get rigClipboardAlwaysCopyTitle =>
      'Selalu izinkan salin dari lingkungan';

  @override
  String get rigClipboardAlwaysCopyDescription =>
      'Letakkan konten papan klip dari lingkungan mana pun di perangkat ini tanpa bertanya.';
}
