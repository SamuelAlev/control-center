// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get succeeded => 'Επιτυχής';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'Επανάληψη #$number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'Εκκίνηση · $time';
  }

  @override
  String get agentActivityFollowingLive =>
      'Παρακολούθηση ζωντανής δραστηριότητας';

  @override
  String get agentActivityJumpToLatest => 'Μετάβαση στα πιο πρόσφατα';

  @override
  String get agentActivityLoadFailed =>
      'Δεν ήταν δυνατή η φόρτωση της δραστηριότητας αυτής της εκτέλεσης';

  @override
  String get agentActivityNotRecorded =>
      'Δεν καταγράφηκε δραστηριότητα για αυτή την εκτέλεση';

  @override
  String get agentActivityNotRecordedHint =>
      'Οι εκτελέσεις που ολοκληρώθηκαν πριν ενεργοποιηθεί η καταγραφή δραστηριότητας δεν έχουν χρονολόγιο.';

  @override
  String get agentActivityRunUnavailable =>
      'Αυτή η εκτέλεση δεν είναι πλέον διαθέσιμη';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'Υποπράκτορας του $agent';
  }

  @override
  String get agentActivityUnsupported =>
      'Η καταγραφή δραστηριότητας δεν είναι διαθέσιμη στον συνδεδεμένο διακομιστή';

  @override
  String get agentActivityUnsupportedHint =>
      'Επανεκκινήστε την εφαρμογή ώστε να φορτώσει την τελευταία έκδοση του διακομιστή.';

  @override
  String get agentActivityWaiting => 'Αναμονή δραστηριότητας…';

  @override
  String get created => 'Δημιουργήθηκε';

  @override
  String get dictationStart => 'Έναρξη υπαγόρευσης';

  @override
  String get dictationListening => 'Ακρόαση…';

  @override
  String get dictationUnavailable =>
      'Η υπαγόρευση χρειάζεται μοντέλο φωνής στον υπολογιστή του διακομιστή. Ρυθμίστε το στις ρυθμίσεις φωνής.';

  @override
  String get dictationFailedToStart =>
      'Δεν ήταν δυνατή η έναρξη της υπαγόρευσης';

  @override
  String get dictationHoldToTalkTitle => 'Κρατήστε για ομιλία';

  @override
  String get dictationHoldToTalkDescription =>
      'Κρατήστε το κουμπί μικροφώνου ή τη συντόμευση για υπαγόρευση και αφήστε για διακοπή. Όταν είναι απενεργοποιημένο, πατήστε μία φορά για έναρξη και ξανά για διακοπή.';

  @override
  String get focusConversation => 'Εστίαση στη συνομιλία';

  @override
  String get ideAgentActivity => 'Δραστηριότητα πράκτορα';

  @override
  String get keybindingPushToTalk => 'Πιέστε για ομιλία';

  @override
  String get keybindingPushToTalkDescription =>
      'Κρατήστε ή εναλλάξτε την υπαγόρευση φωνής στον συνθέτη μηνυμάτων';

  @override
  String get agentPermissions => 'Δικαιώματα πρακτόρων';

  @override
  String get agentPermissionsSettingsDescription =>
      'Ορίστε τι μπορούν να κάνουν οι πράκτορες μόνοι τους, τι πρέπει να ρωτήσουν πρώτα και τι δεν επιτρέπεται ποτέ — ανά χώρο εργασίας, πράκτορα ή χώρο.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Ορίστε απόφαση για κάθε είδος ενέργειας. Οι κανόνες διαδέχονται: ο χώρος υπερκαλύπτει τον πράκτορα, ο πράκτορας τον χώρο εργασίας, ο χώρος εργασίας το προκαθορισμένο της λειτουργίας. Ισχύει ο πιο συγκεκριμένος κανόνας.';

  @override
  String get guardrailLoading => 'Φόρτωση κανόνων…';

  @override
  String get guardrailRulesLoadFailed =>
      'Δεν ήταν δυνατή η φόρτωση των κανόνων δικαιωμάτων.';

  @override
  String get guardrailScopeWorkspace => 'Χώρος εργασίας';

  @override
  String get guardrailScopeAgent => 'Πράκτορας';

  @override
  String get guardrailScopeSpace => 'Χώρος';

  @override
  String get guardrailSelectAgent => 'Επιλέξτε πράκτορα';

  @override
  String get guardrailSelectSpace => 'Επιλέξτε χώρο';

  @override
  String get guardrailNoAgents =>
      'Δεν υπάρχουν ακόμη πράκτορες σε αυτόν τον χώρο εργασίας.';

  @override
  String get guardrailNoSpaces =>
      'Δεν υπάρχουν ακόμη χώροι σε αυτόν τον χώρο εργασίας.';

  @override
  String get guardrailClassFileDelete => 'Διαγραφή αρχείου';

  @override
  String get guardrailClassFileWriteOutsideWorktree =>
      'Εγγραφή εκτός του worktree';

  @override
  String get guardrailClassGitCommit => 'Δημιουργία commit';

  @override
  String get guardrailClassGitPush => 'Push σε απομακρυσμένο';

  @override
  String get guardrailClassPrCreate => 'Άνοιγμα pull request';

  @override
  String get guardrailClassPrPublish => 'Δημοσίευση ανασκόπησης ή συγχώνευση';

  @override
  String get guardrailClassVendorSyncWrite => 'Εγγραφή σε εξωτερικό tracker';

  @override
  String get guardrailClassNetworkEgress => 'Πρόσβαση στο δίκτυο';

  @override
  String get guardrailClassSecretAccess => 'Ανάγνωση μυστικού';

  @override
  String get guardrailClassPackageInstall => 'Εγκατάσταση πακέτου';

  @override
  String get guardrailClassProcessSpawn => 'Εκτέλεση διεργασίας';

  @override
  String get guardrailClassWorkspaceMutation => 'Αλλαγή δομής χώρου εργασίας';

  @override
  String get guardrailClassEnclosureControl =>
      'Έλεγχος απομονωμένου περιβάλλοντος (σταθμός)';

  @override
  String get navRigs => 'Σταθμοί';

  @override
  String get rigsUnsupportedServer =>
      'Αυτός ο διακομιστής δεν μπορεί να φιλοξενήσει επιφάνειες rig. Ελέγξτε τις απαιτήσεις κεντρικού υπολογιστή για το μηχάνημα που θέλετε να χρησιμοποιήσετε.';

  @override
  String get rigSurfaceComputer => 'Υπολογιστής';

  @override
  String get rigSurfaceBrowser => 'Περιηγητής';

  @override
  String get rigSurfaceAndroid => 'Android';

  @override
  String get rigSurfaceIosSimulator => 'Προσομοιωτής iOS';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return 'Ένα προσωρινό ⁨$engine⁩, απομονωμένο από το μηχάνημά σας. Ανοίξτε άλλη μηχανή για να συγκρίνετε την ίδια σελίδα δίπλα-δίπλα.';
  }

  @override
  String get rigPhaseReady => 'Έτοιμο';

  @override
  String get rigPhaseStarting => 'Εκκίνηση';

  @override
  String get rigPhaseParked => 'Σε παύση';

  @override
  String get rigPhaseClosing => 'Κλείσιμο';

  @override
  String get rigPhaseClosed => 'Κλειστό';

  @override
  String get rigPhaseFailed => 'Αποτυχία';

  @override
  String get rigPhaseUnknown => 'Άγνωστο';

  @override
  String get rigNotAccelerated => 'Εξομοιωμένο';

  @override
  String get rigAudioListen => 'Ακρόαση της μηχανής';

  @override
  String get rigAudioMute => 'Σίγαση της μηχανής';

  @override
  String get rigYouHaveControl => 'Έχετε τον έλεγχο';

  @override
  String get rigBackendAvailable => 'Διαθέσιμο';

  @override
  String get rigBackendUnavailable => 'Μη διαθέσιμο';

  @override
  String get rigEgressNotEnforced =>
      'Το δίκτυο δεν είναι απομονωμένο σε αυτό το backend — διαχειρίζεται μόνο του τη συνδεσιμότητα.';

  @override
  String get rigStartMachine => 'Εκκίνηση της μηχανής';

  @override
  String get rigStartHint =>
      'Εκκινεί ένα προσωρινό VM που μοιράζεστε με τους πράκτορες σε αυτή τη συνομιλία. Καταστρέφεται όταν κλείσει και τίποτα μέσα του δεν αγγίζει τον υπολογιστή σας.';

  @override
  String get rigStartAndroidHint =>
      'Συνδέεται σε έναν εξομοιωτή Android που εκτελείται ήδη στον διακομιστή. Η πρόσβαση στο δίκτυο δεν είναι απομονωμένη.';

  @override
  String get rigStartIosHint =>
      'Δημιουργεί έναν προσωρινό προσομοιωτή iOS σε διακομιστή macOS. Διαγράφεται όταν κλείσει το περιβάλλον δοκιμών· η πρόσβαση στο δίκτυο δεν είναι απομονωμένη.';

  @override
  String get rigTechnicalDetails => 'Τεχνικές λεπτομέρειες';

  @override
  String get rigStopMachine => 'Διακοπή της μηχανής';

  @override
  String get rigHomeButton => 'Αρχική';

  @override
  String get rigRotateClockwise => 'Περιστροφή δεξιόστροφα';

  @override
  String get rigRotateCounterclockwise => 'Περιστροφή αριστερόστροφα';

  @override
  String get rigTakeScreenshot => 'Λήψη στιγμιότυπου';

  @override
  String get rigScreenshotSaved => 'Το στιγμιότυπο αποθηκεύτηκε';

  @override
  String rigScreenshotSaveFailed(String error) {
    return 'Δεν ήταν δυνατή η αποθήκευση του στιγμιότυπου: ⁨$error⁩';
  }

  @override
  String get rigSurfaceUnavailable =>
      'Αυτός ο διακομιστής δεν μπορεί να φιλοξενήσει αυτό το είδος μηχανής.';

  @override
  String get rigTabNeedsConversation =>
      'Ανοίξτε πρώτα μια συνομιλία — μια μηχανή ανήκει σε μία, ώστε εσείς και οι πράκτορες να βλέπετε την ίδια οθόνη.';

  @override
  String get ideMenuSectionTools => 'Εργαλεία';

  @override
  String get ideMenuSectionMachines => 'Μηχανήματα';

  @override
  String get ideMenuSectionReopen => 'Επανάνοιγμα';

  @override
  String get ideMenuSearchHint => 'Αναζήτηση';

  @override
  String get ideMenuNoMatches => 'Κανένα αποτέλεσμα';

  @override
  String get rigMenuComputer => 'Υπολογιστής';

  @override
  String get rigMenuBrowser => 'Περιηγητής';

  @override
  String get rigMenuAndroid => 'Android';

  @override
  String get rigMenuIosSimulator => 'Προσομοιωτής iOS';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return 'Κλείσιμο του $name;';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'Η μηχανή συνεχίζει στο παρασκήνιο — ανοίξτε την ξανά οποτεδήποτε από την πλαϊνή γραμμή. Τερματίστε την αν θέλετε να ελευθερώσετε τη μνήμη τώρα.';

  @override
  String get ideCloseKeepBodyShell =>
      'Η εντολή συνεχίζει στο παρασκήνιο — ανοίξτε ξανά το κέλυφος οποτεδήποτε από την πλαϊνή γραμμή. Τερματίστε την αν θέλετε να σταματήσει αυτό που κάνει τώρα.';

  @override
  String get ideCloseKeepBodyAgent =>
      'Ο πράκτορας συνεχίζει στο παρασκήνιο — ανοίξτε ξανά τη συνομιλία οποτεδήποτε από την πλαϊνή γραμμή. Διακόψτε τον αν θέλετε να τελειώσει η εκτέλεση τώρα.';

  @override
  String get ideCloseKeepRunning => 'Συνέχεια εκτέλεσης';

  @override
  String get ideCloseShutDownMachine => 'Τερματισμός';

  @override
  String get ideCloseEndShell => 'Τερματισμός κελύφους';

  @override
  String get ideCloseStopAgent => 'Διακοπή πράκτορα';

  @override
  String get rigsSettingsSubtitle =>
      'Τι μπορεί να εκκινήσει αυτός ο διακομιστής, τις βασικές εικόνες που χρειάζεται και τις μηχανές που τρέχουν τώρα';

  @override
  String get rigsCapabilitiesTitle => 'Αυτός ο διακομιστής';

  @override
  String get rigInstallIosAutomation =>
      'Εγκατάσταση γέφυρας αυτοματοποίησης iOS';

  @override
  String get rigInstallingIosAutomation =>
      'Εγκατάσταση γέφυρας αυτοματοποίησης iOS…';

  @override
  String get rigIosAutomationInstalled =>
      'Η γέφυρα αυτοματοποίησης iOS εγκαταστάθηκε';

  @override
  String get rigsImagesTitle => 'Βασικές εικόνες';

  @override
  String get rigsImagesHint =>
      'Κάθε σταθμός εκκινεί μία από αυτές τις εικόνες μόνο για ανάγνωση. Κάθε συνεδρία γράφει σε προσωρινό overlay, ώστε ένας σταθμός να μην αλλάζει ποτέ το σημείο εκκίνησης του επόμενου.';

  @override
  String get rigsRunningTitle => 'Σε λειτουργία τώρα';

  @override
  String get rigsNoneRunning => 'Δεν εκτελείται καμία μηχανή.';

  @override
  String get rigsCustomImagesTitle =>
      'Προσαρμοσμένες εικόνες (αυτός ο χώρος εργασίας)';

  @override
  String get rigsCustomImagesHint =>
      'Δείξτε το τερματικό (VM) ή τον περιηγητή (VM) στη δική σας εικόνα — επεκτείνετε τις προεπιλογές με τα εργαλεία του έργου σας ή χρησιμοποιήστε οποιαδήποτε συμβατή από registry. Οι νέες μηχανές τη χρησιμοποιούν· οι τρέχουσες κρατούν τη δική τους. Δείτε τον οδηγό σταθμών για το τι πρέπει να παρέχει μια εικόνα.';

  @override
  String get rigsCustomTerminalImageLabel => 'Εικόνα τερματικού (VM)';

  @override
  String get rigsCustomBrowserImageLabel => 'Εικόνα περιηγητή (VM)';

  @override
  String get rigsCustomImagePlaceholder =>
      'π.χ. ⁨ghcr.io/acme/dev-shell:1.2⁩ — αφήστε κενό για την προεπιλογή';

  @override
  String get rigsCustomImageInvalid =>
      'Εισαγάγετε αναφορά registry όπως ⁨repo/name:tag⁩. Τοπικές διαδρομές και αρχεία αρχείου δεν επιτρέπονται.';

  @override
  String get rigsCustomImageSaved =>
      'Αποθηκεύτηκε. Οι νέες μηχανές εκκινούν αυτή την εικόνα· οι τρέχουσες κρατούν τη δική τους.';

  @override
  String get rigsEgressTitle => 'Έξοδος περιηγητή (αυτός ο χώρος εργασίας)';

  @override
  String get rigsEgressHint =>
      'Επιπλέον κεντρικοί υπολογιστές που μπορεί να φτάσει ο απομονωμένος περιηγητής — ένας ανά γραμμή: ακριβής κεντρικός (⁨api.example.com⁩) ή μπαλαντέρ για υποτομείς (⁨*.example.com⁩). Ο ιστότοπος του προϊόντος επιτρέπεται και στις δύο περιπτώσεις. Οι νέες μηχανές παίρνουν τη λίστα· οι τρέχουσες κρατούν ό,τι είχαν στην εκκίνηση.';

  @override
  String rigsEgressInvalid(String host) {
    return 'Το «⁨$host⁩» δεν είναι έγκυρη καταχώριση κεντρικού υπολογιστή.';
  }

  @override
  String get rigsEgressSaved =>
      'Αποθηκεύτηκε. Οι νέες μηχανές περιηγητή επιτρέπουν αυτούς τους κεντρικούς· οι τρέχουσες κρατούν τους δικούς τους.';

  @override
  String get rigImageInstalled => 'Εγκατεστημένη';

  @override
  String get rigImageNotDownloaded => 'Δεν έχει ληφθεί';

  @override
  String get rigImageNotPublished => 'Δεν έχει δημοσιευτεί';

  @override
  String get rigImageNotPublishedHint =>
      'Δεν έχει δημοσιευτεί ακόμη εικόνα, επομένως δεν υπάρχει τίποτα για λήψη. Εισαγάγετε συμβατή εικόνα δίσκου για να την ενεργοποιήσετε.';

  @override
  String get rigImageDownload => 'Λήψη';

  @override
  String get rigImageDownloading => 'Λήψη…';

  @override
  String get rigImageImport => 'Εισαγωγή';

  @override
  String get rigImageImportMessage =>
      'Διαδρομή προς εικόνα δίσκου qcow2 στο σύστημα αρχείων του διακομιστή. Αντιγράφεται στην αποθήκη εικόνων, ώστε το αρχείο να μπορεί να μετακινηθεί μετά.';

  @override
  String get rigConnectingStream => 'Σύνδεση στον σταθμό';

  @override
  String get rigStreamNotAllowed => 'Δεν έχετε πρόσβαση σε αυτόν τον σταθμό.';

  @override
  String get rigStreamNotRunning => 'Αυτός ο σταθμός δεν εκτελείται πλέον.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'Η ζωντανή προβολή χρειάζεται ⁨ffmpeg⁩ σε αυτόν τον κεντρικό. Εγκαταστήστε το ⁨ffmpeg⁩ και ανοίξτε ξανά την καρτέλα.';

  @override
  String get rigStreamEnded => 'Η ζωντανή προβολή τερματίστηκε.';

  @override
  String get rigStreamFailed =>
      'Δεν ήταν δυνατό το άνοιγμα της ζωντανής προβολής.';

  @override
  String get rigStreamDisconnected => 'Δεν υπάρχει σύνδεση με διακομιστή.';

  @override
  String rigDropSendingOne(String name) {
    return 'Αντιγραφή του «⁨$name⁩» στη μηχανή…';
  }

  @override
  String rigDropSendingMany(int count) {
    return 'Αντιγραφή $count αρχείων στη μηχανή…';
  }

  @override
  String get rigTerminalDropSending => 'Αντιγραφή στη μηχανή…';

  @override
  String get rigTerminalPasteImage =>
      'Η επικολλημένη εικόνα αποθηκεύτηκε στη μηχανή';

  @override
  String get rigPortsTitle => 'Προωθημένες θύρες';

  @override
  String get rigPortsTooltip => 'Θύρες ανοιχτές μέσα σε αυτή τη μηχανή';

  @override
  String get rigPortsEmpty =>
      'Δεν ακούει τίποτα ακόμη. Ξεκινήστε έναν διακομιστή στο τερματικό — ένας διακομιστής ανάπτυξης στη θύρα 3000 εμφανίζεται εδώ.';

  @override
  String get rigPortsAdd => 'Προσθήκη θύρας';

  @override
  String get rigPortsAddHint => 'Θύρα επισκέπτη προς προώθηση (π.χ. 3000)';

  @override
  String get rigPortsAutoForward => 'Αυτόματη προώθηση θυρών';

  @override
  String get rigPortsCopyUrl => 'Αντιγραφή τοπικού URL';

  @override
  String rigPortsCopiedUrl(String url) {
    return 'Αντιγράφηκε ⁨$url⁩';
  }

  @override
  String get rigPortsStopForward => 'Διακοπή προώθησης';

  @override
  String get rigPortsExposeLan => 'Κοινή χρήση στο τοπικό δίκτυο';

  @override
  String get rigPortsLanPrivate => 'Μόνο τοπικά';

  @override
  String get rigPortsLanShared => 'Στο δίκτυο';

  @override
  String get rigPortsSetDomain => 'Ορισμός τομέα περιηγητή (.test)';

  @override
  String get rigPortsDomainHint =>
      'Τομέας για τον περιηγητή (VM), π.χ. ⁨myapp.test⁩ — προσβάσιμος εκεί, όχι στον κεντρικό';

  @override
  String get rigPortsProcessUnknown => 'άγνωστη διεργασία';

  @override
  String get rigPortsInactive => 'δεν ακούει';

  @override
  String get rigPortsTooltipHost => 'Θύρες ανοιχτές σε αυτό το τερματικό';

  @override
  String get rigPortsEmptyHost =>
      'Τίποτα δεν ακούει ακόμα σε αυτό το τερματικό. Ξεκίνα έναν διακομιστή και εμφανίζεται εδώ.';

  @override
  String get rigPortsAddHintHost => 'Θύρα για αντιστοίχιση (π.χ. 5173)';

  @override
  String get rigPortsLocalPortHint => 'Τοπική θύρα (προαιρετικό)';

  @override
  String rigPortsDestDesktop(int port) {
    return 'localhost:$port';
  }

  @override
  String rigPortsDestBrowser(int port) {
    return 'localhost:$port στο πρόγραμμα περιήγησης (VM)';
  }

  @override
  String get rigPortsDestBrowserUnreachable =>
      'πρόγραμμα περιήγησης (VM) μη συνδεδεμένο';

  @override
  String rigPortsDestAndroid(int port) {
    return 'localhost:$port στο Android';
  }

  @override
  String get rigPortsDestAndroidUnreachable => 'Android μη συνδεδεμένο';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count βασικές εικόνες ακόμη προς λήψη',
      one: '1 βασική εικόνα ακόμη προς λήψη',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'Αποδοχή';

  @override
  String get guardrailDecisionPrompt => 'Ερώτηση πρώτα';

  @override
  String get guardrailDecisionDeny => 'Απόρριψη';

  @override
  String get guardrailSourceThisScope => 'Αυτό το πεδίο';

  @override
  String get guardrailSourceDefault => 'Ενσωματωμένη προεπιλογή';

  @override
  String get guardrailSourcePreset => 'Προκαθορισμένο λειτουργίας';

  @override
  String get guardrailSourceInherited => 'Κληρονομημένο';

  @override
  String get guardrailClearToInherited => 'Επαναφορά στο κληρονομημένο';

  @override
  String get guardrailWhatIf => 'Τι θα γίνει;';

  @override
  String get guardrailWhatIfDescription =>
      'Δείτε πώς οι τρέχοντες κανόνες θα επιλύσουν μια ενέργεια, με την ίδια λογική που εφαρμόζουν οι πράκτορες.';

  @override
  String get guardrailProbeActionLabel => 'Ενέργεια';

  @override
  String get guardrailProbeCommandLabel => 'Εντολή (προαιρετικά)';

  @override
  String get guardrailProbeCommandHint => 'π.χ. ⁨git push origin main⁩';

  @override
  String get guardrailProbeAgentLabel => 'Πράκτορας (προαιρετικά)';

  @override
  String get guardrailProbeSpaceLabel => 'Χώρος (προαιρετικά)';

  @override
  String get guardrailProbeNone => 'Κανένα';

  @override
  String get guardrailProbeModeLabel => 'Λειτουργία';

  @override
  String get guardrailProbeResult => 'Αποτέλεσμα';

  @override
  String get guardrailProbeSource => 'Πηγή:';

  @override
  String get guardrailAdapterMatrix => 'Πού εφαρμόζονται οι κανόνες';

  @override
  String get guardrailAdapterMatrixDescription =>
      'Ειλικρινής αναφορά: πού συλλαμβάνεται πραγματικά κάθε ενέργεια, ανά εκτελεστή πράκτορα. Τεκμηριώνει την πραγματικότητα, όχι εγγύηση — ενέργειες που εκτελεί ο εκτελεστής εκτός ζώνης δεν μπορούν να αναχαιτιστούν.';

  @override
  String get guardrailEffectColumn => 'Ενέργεια';

  @override
  String get guardrailAdapterHarness => 'Ενσωματωμένο harness';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'Κατώφλι sandbox';

  @override
  String get guardrailEnforcementPolicyGate => 'Πύλη πολιτικής';

  @override
  String get guardrailEnforcementSandbox => 'Μόνο sandbox';

  @override
  String get guardrailEnforcementNone => 'Μη εφαρμόσιμο';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'Η απόφαση δικαιώματος ελέγχεται πριν εκτελεστεί η ενέργεια και μπορεί να την αποκλείσει.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'Μόνο το sandbox την περιορίζει· ο κανόνας δικαιώματος δεν συμβουλεύεται.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'Η απόφαση είναι μόνο συμβουλευτική — δεν μπορεί να αναχαιτιστεί εδώ.';

  @override
  String get obsStatCost => 'κόστος';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount ανατεθειμένο';
  }

  @override
  String get obsStatDuration => 'διάρκεια';

  @override
  String get obsStatTokens => 'tokens';

  @override
  String get obsStatTools => 'εργαλεία';

  @override
  String get openAgentActivity => 'Άνοιγμα δραστηριότητας';

  @override
  String get orgChart => 'Οργανόγραμμα';

  @override
  String get orgChartEmpty => 'Δεν υπάρχουν ακόμη πράκτορες';

  @override
  String get navCalendar => 'Ημερολόγιο';

  @override
  String get serverConnection => 'Σύνδεση διακομιστή';

  @override
  String get serverModeLocal => 'Εκτέλεση σε αυτή την εφαρμογή';

  @override
  String get serverModeLocalDescription =>
      'Το Control Center εκτελεί τον δικό του διακομιστή σε αυτό το μηχάνημα και διατηρεί τα δεδομένα σας τοπικά.';

  @override
  String get serverModeRemote => 'Σύνδεση σε απομακρυσμένη παρουσία';

  @override
  String get serverModeRemoteDescription =>
      'Συνδεθείτε σε διακομιστή Control Center που εκτελείται αλλού. Τα δεδομένα σας βρίσκονται σε εκείνον τον διακομιστή.';

  @override
  String get serverRemoteUrl => 'URL διακομιστή';

  @override
  String get serverRemoteDeviceId => 'ID συσκευής';

  @override
  String get serverRemotePairingKey => 'Κλειδί σύζευξης';

  @override
  String get serverRemotePairingKeyHint =>
      'Επικολλήστε το κλειδί σύζευξης από τον απομακρυσμένο διακομιστή';

  @override
  String get serverSetupInviteCode => 'Κωδικός πρόσκλησης';

  @override
  String get serverSetupInviteCodeHint =>
      'Επικολλήστε κωδικό πρόσκλησης μιας χρήσης (αφήστε κενό για κλειδί σύζευξης)';

  @override
  String get serverDiscoveryTooltip => 'Εύρεση διακομιστών στο δίκτυό σας';

  @override
  String get serverDiscoveryTitle => 'Διακομιστές στο δίκτυό σας';

  @override
  String get serverDiscoverySearching => 'Αναζήτηση διακομιστών…';

  @override
  String get serverDiscoveryEmpty =>
      'Δεν βρέθηκαν διακομιστές. Ελέγξτε ότι ο διακομιστής εκτελείται και ότι αυτή η συσκευή μπορεί να τον φτάσει, και αναζητήστε ξανά.';

  @override
  String get serverDiscoveryRefresh => 'Αναζήτηση ξανά';

  @override
  String get serverListActive => 'Ενεργός';

  @override
  String get serverListSwitch => 'Εναλλαγή';

  @override
  String get serverListAddTitle => 'Προσθήκη διακομιστή';

  @override
  String get serverListRemoveActiveHint =>
      'Μεταβείτε σε άλλον διακομιστή πριν αφαιρέσετε αυτόν.';

  @override
  String get serverSwitchFailedTitle => 'Δεν ήταν δυνατή η εναλλαγή διακομιστή';

  @override
  String get serverListInsecureBadge => 'Μη ασφαλές';

  @override
  String get connectionPathLocal => 'Τοπικό';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'Τερματισμός';

  @override
  String get shutdownSubtitle => 'Κλείσιμο του τοπικού διακομιστή';

  @override
  String get shutdownServiceApprovals => 'Εγκρίσεις';

  @override
  String get shutdownServiceBackgroundJobs => 'Εργασίες παρασκηνίου';

  @override
  String get shutdownServiceScheduler => 'Χρονοπρογραμματιστής εργασιών';

  @override
  String get shutdownServiceCalendar => 'Συγχρονισμός ημερολογίου';

  @override
  String get shutdownServiceWeather => 'Καιρός';

  @override
  String get shutdownServiceSoundscape => 'Ηχητικό περιβάλλον';

  @override
  String get shutdownServiceMeetings => 'Συσκέψεις';

  @override
  String get shutdownServiceVoiceModels => 'Μοντέλα φωνής';

  @override
  String get shutdownServiceNetworking => 'Δικτύωση';

  @override
  String get shutdownServicePresence => 'Παρουσία';

  @override
  String get shutdownServiceDataSync => 'Συγχρονισμός δεδομένων';

  @override
  String get shutdownServiceDeviceRelay => 'Αναμετάδοση συσκευής';

  @override
  String get shutdownServiceMcpConnections => 'Συνδέσεις MCP';

  @override
  String get shutdownServiceCodeEditors => 'Επεξεργαστές κώδικα';

  @override
  String get serverSharingTitle => 'Κοινή χρήση αυτού του διακομιστή';

  @override
  String get serverSharingDescription =>
      'Κάντε αυτόν τον διακομιστή προσβάσιμο από τις άλλες συσκευές σας. Τίποτα δεν εκτίθεται δημόσια εκτός αν ενεργοποιήσετε σήραγγα παρακάτω. Οι προσκλήσεις σύζευξης ενσωματώνουν αυτόματα τις τρέχουσες διευθύνσεις του διακομιστή — δημιουργήστε τις στις ρυθμίσεις χώρου εργασίας.';

  @override
  String get serverSharingUnavailable =>
      'Τα στοιχεία κοινής χρήσης δεν είναι διαθέσιμα σε αυτόν τον διακομιστή.';

  @override
  String get serverSharingMdnsLabel => 'Ανακάλυψη LAN';

  @override
  String get serverSharingMdnsOn =>
      'Αυτός ο διακομιστής διαφημίζεται στο τοπικό δίκτυο (mDNS)';

  @override
  String get serverSharingMdnsOff =>
      'Δεν διαφημίζεται στο τοπικό δίκτυο (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'Σήραγγα';

  @override
  String get serverSharingTunnelHelper =>
      'Η ενεργοποίηση σήραγγας καθιστά αυτόν τον διακομιστή προσβάσιμο από το διαδίκτυο. Η δημόσια έκθεση είναι προαιρετική και απενεργοποιημένη από προεπιλογή.';

  @override
  String get serverSharingProviderOff => 'Ανενεργή';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'Δημόσιο URL';

  @override
  String get serverSharingTunnelStarting => 'Εκκίνηση σήραγγας…';

  @override
  String serverSharingTunnelError(String error) {
    return 'Σφάλμα σήραγγας: ⁨$error⁩';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'Η σήραγγα είναι ενεργή. Φτάστε την στο ρυθμισμένο όνομα DNS.';

  @override
  String get serverSharingRelayLabel => 'Αναμετάδοση';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'Αναμετάδοση αυτόν τον μήνα: $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'Ενεργές συνεδρίες αναμετάδοσης: $count';
  }

  @override
  String get serverSharingUpdateFailedTitle =>
      'Δεν ήταν δυνατή η ενημέρωση της κοινής χρήσης';

  @override
  String get pairNewClient => 'Σύζευξη νέου πελάτη';

  @override
  String get pairClientNameHint =>
      'Ονομάστε αυτόν τον πελάτη (π.χ. φορητός εργασίας)';

  @override
  String get pairClientTypeWeb => 'Πρόγραμμα περιήγησης';

  @override
  String get pairClientTypeDesktop => 'Εφαρμογή υπολογιστή';

  @override
  String get pairClientTypePhone => 'Τηλέφωνο';

  @override
  String get pairAction => 'Σύζευξη';

  @override
  String get revoke => 'Ανάκληση';

  @override
  String get pairCredentialsIntro =>
      'Συνδέστε τον νέο πελάτη με αυτά τα στοιχεία ή ανοίξτε τον σύνδεσμο σε αυτόν.';

  @override
  String get pairLinkLabel => 'Σύνδεσμος';

  @override
  String get pairScanQr =>
      'Σαρώστε αυτόν τον κωδικό QR με την κάμερα του τηλεφώνου σας για σύζευξη.';

  @override
  String get pairServerUnreachableTitle => 'Μη προσβάσιμο';

  @override
  String get pairServerUnreachable =>
      'Άλλες συσκευές δεν μπορούν να φτάσουν αυτόν τον διακομιστή απευθείας, επομένως ένας νέος πελάτης δεν μπορεί να συνδεθεί. Ορίστε το δημόσιο URL του διακομιστή για σύζευξη περισσότερων πελατών.';

  @override
  String get serverSetupTitle => 'Πώς να εκτελείται το Control Center;';

  @override
  String get serverSetupSubtitle =>
      'Το Control Center χρειάζεται έναν διακομιστή που κατέχει τα δεδομένα σας. Εκτελέστε έναν μέσα σε αυτή την εφαρμογή ή συνδεθείτε σε παρουσία που εκτελείται αλλού.';

  @override
  String get serverSetupRunLocal => 'Εκτέλεση σε αυτή την εφαρμογή';

  @override
  String get serverSetupConnect => 'Σύνδεση';

  @override
  String get serverSetupInvalidUrl =>
      'Εισαγάγετε έγκυρο URL διακομιστή ⁨ws://⁩ ή ⁨wss://⁩.';

  @override
  String get serverSetupCouldNotConnect => 'Δεν ήταν δυνατή η σύνδεση';

  @override
  String get serverSetupErrorUnreachable =>
      'Δεν ήταν δυνατή η επικοινωνία με τον διακομιστή. Ελέγξτε ότι εκτελείται και ότι αυτή η συσκευή μπορεί να τον φτάσει (ίδιο δίκτυο ή αναμετάδοση).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'Η ταυτότητα του διακομιστή δεν ταιριάζει με αυτή που είναι αποθηκευμένη σε αυτή τη συσκευή. Αν ο διακομιστής επανεγκαταστάθηκε ή επαναφέρθηκε, αφαιρέστε τον αποθηκευμένο διακομιστή και κάντε σύζευξη ξανά.';

  @override
  String get serverSetupErrorAuthRejected =>
      'Ο διακομιστής απέρριψε αυτή τη συσκευή. Ελέγξτε ότι το κλειδί σύζευξης και το ID συσκευής ταιριάζουν με όσα εξέδωσε ο διακομιστής.';

  @override
  String get serverSetupErrorInviteRejected =>
      'Αυτός ο κωδικός πρόσκλησης είναι άκυρος ή έχει λήξει. Ζητήστε έναν νέο.';

  @override
  String get serverSetupErrorGeneric =>
      'Κάτι πήγε στραβά κατά τη σύνδεση. Αναπτύξτε τις τεχνικές λεπτομέρειες παρακάτω για περισσότερες πληροφορίες.';

  @override
  String get serverSetupErrorDetails => 'Τεχνικές λεπτομέρειες';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ακόμη',
      one: '1 ακόμη',
    );
    return '$_temp0';
  }

  @override
  String get calendarAllDayGutter => 'Ολοήμ.';

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count γεγονότα',
      one: '1 γεγονός',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => 'Σύμπτυξη ολοήμερων γεγονότων';

  @override
  String get calendarExpandAllDay => 'Ανάπτυξη ολοήμερων γεγονότων';

  @override
  String get calendarViewMonth => 'Μήνας';

  @override
  String get calendarViewWeek => 'Εβδομάδα';

  @override
  String get calendarViewAgenda => 'Ατζέντα';

  @override
  String get calendarConnectGoogle => 'Σύνδεση Google Calendar';

  @override
  String get calendarConnectDescription =>
      'Συγχρονίστε το Google Calendar για να βλέπετε γεγονότα εδώ και να λαμβάνετε ειδοποιήσεις πριν ξεκινήσουν οι συσκέψεις.';

  @override
  String get calendarDisconnect => 'Αποσύνδεση';

  @override
  String get calendarReconnect => 'Επανασύνδεση';

  @override
  String get calendarEmptyNoEvents => 'Δεν υπάρχουν γεγονότα σε αυτό το εύρος';

  @override
  String get calendarStartRecording => 'Έναρξη εγγραφής';

  @override
  String get calendarStartRecordingAndLink => 'Έναρξη εγγραφής και σύνδεση';

  @override
  String get calendarJoinMeet => 'Συμμετοχή στη σύσκεψη';

  @override
  String get calendarFromCalendar => 'Από το ημερολόγιο';

  @override
  String get calendarLinkedMeeting => 'Συνδεδεμένη σύσκεψη';

  @override
  String get calendarToday => 'Σήμερα';

  @override
  String get calendarAllDay => 'Ολοήμερο';

  @override
  String calendarWeekNumber(int number) {
    return 'Εβδομάδα $number';
  }

  @override
  String get calendarPreviousPeriod => 'Προηγούμενο';

  @override
  String get calendarNextPeriod => 'Επόμενο';

  @override
  String calendarLastSynced(String time) {
    return 'Συγχρονίστηκε $time';
  }

  @override
  String get calendarNeverSynced => 'Δεν έχει συγχρονιστεί ακόμη';

  @override
  String get calendarSyncing => 'Συγχρονισμός…';

  @override
  String get calendarViewDay => 'Ημέρα';

  @override
  String get calendarShow => 'Εμφάνιση';

  @override
  String get calendarHide => 'Απόκρυψη';

  @override
  String get calendarRsvpGoing => 'Θα πάτε;';

  @override
  String get calendarRsvpYes => 'Ναι';

  @override
  String get calendarRsvpNo => 'Όχι';

  @override
  String get calendarRsvpMaybe => 'Ίσως';

  @override
  String get calendarRsvpFailed =>
      'Δεν ήταν δυνατή η ενημέρωση της απάντησής σας';

  @override
  String get calendarAddAccount => 'Προσθήκη λογαριασμού ημερολογίου';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Συνδέστε λογαριασμό Google για συγχρονισμό εκδηλώσεων σε αυτόν τον χώρο. Αυτά τα ημερολόγια είναι δικά σας εδώ.';

  @override
  String get calendarConnecting => 'Σύνδεση…';

  @override
  String get calendarSyncNow => 'Συγχρονισμός τώρα';

  @override
  String get calendarNoWorkspace =>
      'Επιλέξτε χώρο εργασίας για να δείτε το ημερολόγιό του';

  @override
  String get calendarConnectError =>
      'Δεν ήταν δυνατή η σύνδεση του Google Calendar';

  @override
  String get calendarClientIdLabel => 'Client ID';

  @override
  String get calendarClientSecretLabel => 'Client secret';

  @override
  String get calendarConnectCredsHint =>
      'Εισαγάγετε το Google OAuth device-code client ID και το secret του έργου σας. Ο διακομιστής εκτελεί τη σύνδεση και τον συγχρονισμό — το πρόγραμμα περιήγησης δεν κρατά ποτέ τα tokens.';

  @override
  String get calendarConnectApproveInstruction =>
      'Ανοίξτε τη σελίδα επαλήθευσης σε οποιαδήποτε συσκευή, συνδεθείτε και εισαγάγετε αυτόν τον κωδικό:';

  @override
  String get calendarConnectOpenPage => 'Άνοιγμα σελίδας επαλήθευσης';

  @override
  String get calendarConnectWaiting => 'Αναμονή έγκρισης…';

  @override
  String get calendarConnectDenied =>
      'Η εξουσιοδότηση απορρίφθηκε. Δοκιμάστε ξανά.';

  @override
  String get calendarConnectExpired => 'Ο κωδικός έληξε. Δοκιμάστε ξανά.';

  @override
  String get notificationMeetingStartsSoon => 'Η σύσκεψη ξεκινά σύντομα';

  @override
  String get notifyMeetingStartsSoon =>
      'Όταν μια σύσκεψη ημερολογίου πρόκειται να ξεκινήσει';

  @override
  String get notificationCalendarAuthExpiredTitle =>
      'Το ημερολόγιο αποσυνδέθηκε';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Επανασυνδέστε το ⁨$email⁩ για να συνεχιστεί ο συγχρονισμός';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Επανασυνδέστε το ημερολόγιό σας για να συνεχιστεί ο συγχρονισμός';

  @override
  String get notifyCalendarAuthExpired =>
      'Όταν ένας λογαριασμός ημερολογίου χρειάζεται επανασύνδεση';

  @override
  String get notificationRigStatusChanged =>
      'Ενημερώσεις απομονωμένου περιβάλλοντος';

  @override
  String get notifyRigStatusChanged =>
      'Όταν ένα απομονωμένο περιβάλλον αναλαμβάνεται, ανακτάται ή αποτυγχάνει';

  @override
  String get notificationRigTakenOver => 'Ανάληψη απομονωμένου περιβάλλοντος';

  @override
  String get notificationRigTakenOverBody =>
      'Ένα άτομο οδηγεί τη μηχανή· ο πράκτορας μπορεί να παρακολουθεί αλλά όχι να ενεργεί.';

  @override
  String get notificationRigReleased =>
      'Απελευθερώθηκε ο έλεγχος του απομονωμένου περιβάλλοντος';

  @override
  String get notificationRigReleasedBody => 'Ο πράκτορας έχει ξανά τη μηχανή.';

  @override
  String get notificationRigReclaimed => 'Ανάκτηση απομονωμένου περιβάλλοντος';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'Έμεινε αδρανές, οπότε η μηχανή έκλεισε για να ελευθερωθεί μνήμη.';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'Έφτασε στο χρονικό όριο και έκλεισε.';

  @override
  String get notificationRigFailed => 'Αποτυχία απομονωμένου περιβάλλοντος';

  @override
  String get notificationRigFailedBody =>
      'Ο hypervisor σταμάτησε από κάτω. Ανοίξτε ξανά τη μηχανή για να συνεχίσετε.';

  @override
  String get calendarAlertLeadTime => 'Προειδοποίηση πριν';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'Πόσο πριν από μια σύσκεψη να ειδοποιηθείτε';

  @override
  String calendarConnectedAs(String email) {
    return 'Συνδεδεμένο ως ⁨$email⁩';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count παρευρισκόμενοι';
  }

  @override
  String get calendarEventLabel => 'Γεγονός';

  @override
  String get calendarRecurring => 'Επαναλαμβανόμενο γεγονός';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Διοργανωτής';

  @override
  String get calendarYou => 'Εσείς';

  @override
  String get calendarShowFewer => 'Εμφάνιση λιγότερων';

  @override
  String get calendarRsvpAwaiting => 'Αναμονή';

  @override
  String calendarParticipantsCount(int count) {
    return '$count συμμετέχοντες';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'Προβολή και των $count συμμετεχόντων';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count ναι';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count όχι';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count ίσως';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count σε αναμονή';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count λεπτά';
  }

  @override
  String get openInEditorPrompt => 'Άνοιγμα σε ποιον επεξεργαστή;';

  @override
  String get ideNotInstalled => 'Δεν είναι εγκατεστημένο';

  @override
  String openInIde(String editor) {
    return 'Άνοιγμα στο $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'Δεν ήταν δυνατό το άνοιγμα του $editor: ⁨$error⁩';
  }

  @override
  String get profileSearchHint => 'Αναζήτηση pull requests…';

  @override
  String get stopAgentRun => 'Διακοπή εκτέλεσης';

  @override
  String get stopAgentRunConfirm =>
      'Διακοπή αυτής της εκτέλεσης; Η εργασία σε εξέλιξη χάνεται.';

  @override
  String get inProgress => 'Σε εξέλιξη';

  @override
  String get drafts => 'Πρόχειρα';

  @override
  String get sortOldest => 'Παλαιότερα';

  @override
  String get sortLargest => 'Μεγαλύτερα';

  @override
  String get prFilterTooltip => 'Φίλτρο';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ενεργά φίλτρα',
      one: '1 ενεργό φίλτρο',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'Προσθήκη φίλτρου…';

  @override
  String get prFilterFieldHint => 'Φίλτρο…';

  @override
  String get prFilterCategoryStatus => 'Κατάσταση';

  @override
  String get prFilterCategoryAuthor => 'Συντάκτης';

  @override
  String get prFilterCategoryReviewer => 'Κριτές';

  @override
  String get prFilterCategoryContent => 'Περιεχόμενο';

  @override
  String get prFilterCategoryRepoOwner => 'Ιδιοκτήτης αποθετηρίου';

  @override
  String get prFilterCategoryRepoName => 'Όνομα αποθετηρίου';

  @override
  String get prFilterCategoryOpenedDate => 'Ημερομηνία ανοίγματος';

  @override
  String get prFilterCategoryUpdatedDate => 'Ημερομηνία ενημέρωσης';

  @override
  String get prFilterQuickToReview => 'Γρήγορη ανασκόπηση';

  @override
  String get prFilterClearAll => 'Καθαρισμός φίλτρων';

  @override
  String prFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests',
      one: '1 pull request',
    );
    return '$_temp0';
  }

  @override
  String prFilterHiddenOptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count επιλογές χωρίς αντιστοιχία σε pull requests',
      one: '1 επιλογή χωρίς αντιστοιχία σε pull requests',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'Ο τίτλος ή το σώμα περιέχει…';

  @override
  String get prFilterNoOptions => 'Καμία αντίστοιχη επιλογή';

  @override
  String get prFilterChipIs => 'είναι';

  @override
  String get prFilterChipIsAnyOf => 'είναι ένα από';

  @override
  String get prFilterChipContains => 'περιέχει';

  @override
  String get prFilterChipSince => 'από';

  @override
  String get prFilterAddFilterButton => 'Προσθήκη φίλτρου';

  @override
  String prFilterClearCategory(String category) {
    return 'Καθαρισμός φίλτρου $category';
  }

  @override
  String get prFilterCurrentUser => 'Τρέχων χρήστης';

  @override
  String get prStatusDraft => 'Πρόχειρο';

  @override
  String get prStatusOpen => 'Ανοιχτό';

  @override
  String get prStatusInReview => 'Σε ανασκόπηση';

  @override
  String get prStatusChangesRequested => 'Ζητήθηκαν αλλαγές';

  @override
  String get prStatusApproved => 'Εγκρίθηκε';

  @override
  String get prStatusMerged => 'Συγχωνεύθηκε';

  @override
  String get prStatusClosed => 'Κλειστό';

  @override
  String get prDateWindowDay => 'Πριν από 1 ημέρα';

  @override
  String get prDateWindowThreeDays => 'Πριν από 3 ημέρες';

  @override
  String get prDateWindowWeek => 'Πριν από 1 εβδομάδα';

  @override
  String get prDateWindowMonth => 'Πριν από 1 μήνα';

  @override
  String get prDateWindowThreeMonths => 'Πριν από 3 μήνες';

  @override
  String get prDateWindowSixMonths => 'Πριν από 6 μήνες';

  @override
  String get prDateWindowYear => 'Πριν από 1 έτος';

  @override
  String get prDisplayOptions => 'Επιλογές εμφάνισης';

  @override
  String get prDisplayGrouping => 'Ομαδοποίηση';

  @override
  String get prDisplayOrdering => 'Ταξινόμηση';

  @override
  String get prDisplayShowDrafts => 'Εμφάνιση προχείρων';

  @override
  String get prDisplayMergedWindow => 'Παράθυρο συγχώνευσης';

  @override
  String get prDisplayMergedWindowDay => 'Τελευταία ημέρα';

  @override
  String get prDisplayMergedWindowWeek => 'Τελευταία εβδομάδα';

  @override
  String get prDisplayMergedWindowMonth => 'Τελευταίος μήνας';

  @override
  String get prDisplayProperties => 'Ιδιότητες εμφάνισης';

  @override
  String get prGroupingRepository => 'Αποθετήριο';

  @override
  String get prGroupingAuthor => 'Συντάκτης';

  @override
  String get prGroupingStatus => 'Κατάσταση';

  @override
  String get prGroupingNone => 'Χωρίς ομαδοποίηση';

  @override
  String get prPropertyRepository => 'Αποθετήριο';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'Κλάδος';

  @override
  String get prPropertyUpdated => 'Ενημερώθηκε';

  @override
  String get prPropertyAuthor => 'Συντάκτης';

  @override
  String get prPropertyChecks => 'Έλεγχοι';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'Σχόλια';

  @override
  String get keybindingOpenFilterMenu => 'Άνοιγμα μενού φίλτρων';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'Άνοιγμα του μενού φίλτρων pull request';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count επιλεγμένα',
      one: '1 επιλεγμένο',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'Σύνοψη';

  @override
  String get kbMove => 'μετακίνηση';

  @override
  String get kbTabs => 'καρτέλες';

  @override
  String get kbSearch => 'αναζήτηση';

  @override
  String get kbViewed => 'προβλήθηκαν';

  @override
  String get kbCollapse => 'σύμπτυξη';

  @override
  String get appearance => 'Εμφάνιση';

  @override
  String get appearanceSettingsDescription => 'Θέμα, γλώσσα και τυπογραφία.';

  @override
  String get notificationsSettingsDescription =>
      'Επιλέξτε ποια γεγονότα πρακτόρων και χώρου εργασίας σας ειδοποιούν.';

  @override
  String get advanced => 'Για προχωρημένους';

  @override
  String get accounts => 'Λογαριασμοί';

  @override
  String get mcpServers => 'Διακομιστές MCP';

  @override
  String get mcpServersSettingsDescription =>
      'Ενσωματωμένος διακομιστής MCP και εξωτερικοί διακομιστές MCP.';

  @override
  String get remoteControlAndDevices => 'Απομακρυσμένος έλεγχος και συσκευές';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'Σύζευξη τηλεφώνων και ρύθμιση του διακομιστή απομακρυσμένου ελέγχου.';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'Τα μοντέλα ομιλίας και διαχωρισμού ομιλητών που φιλοξενεί αυτός ο διακομιστής.';

  @override
  String get needsSetupLabel => 'Χρειάζεται ρύθμιση';

  @override
  String get collapseSidebar => 'Σύμπτυξη πλαϊνής γραμμής';

  @override
  String get expandSidebar => 'Ανάπτυξη πλαϊνής γραμμής';

  @override
  String get filterSpacesHint => 'Φιλτράρισμα χώρων';

  @override
  String noSpacesMatch(String query) {
    return 'Κανένας χώρος δεν ταιριάζει με «$query»';
  }

  @override
  String get privacy => 'Απόρρητο';

  @override
  String get sendDiffContentTitle =>
      'Αποστολή περιεχομένου diff στον προσαρμογέα AI';

  @override
  String get diffSharingOnSubtitle =>
      'Οι ακατέργαστες γραμμές diff περιλαμβάνονται στις προτροπές των πρακτόρων για βαθύτερη ανασκόπηση.';

  @override
  String get diffSharingOffSubtitle =>
      'Οι πράκτορες χρησιμοποιούν μόνο δομημένα μεταδεδομένα (διαδρομές αρχείων, αριθμοί γραμμών, περιγραφή PR)· κανένας ακατέργαστος κώδικας δεν φεύγει από την εφαρμογή.';

  @override
  String get errorReportingTitle => 'Κοινή χρήση αναφορών σφαλμάτων';

  @override
  String get errorReportingOnSubtitle =>
      'Διαγνωστικά κατάρρευσης, σφαλμάτων και απόδοσης αποστέλλονται για τη διόρθωση σφαλμάτων (μόνο εκδόσεις κυκλοφορίας).';

  @override
  String get errorReportingOffSubtitle =>
      'Τα διαγνωστικά είναι απενεργοποιημένα. Δεν αποστέλλονται αναφορές κατάρρευσης ή σφαλμάτων.';

  @override
  String get onboardingDiagnosticsTitle =>
      'Βοηθήστε στη βελτίωση του Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Στείλτε διαγνωστικά κατάρρευσης, σφαλμάτων και απόδοσης ώστε να διορθώνουμε προβλήματα γρηγορότερα (μόνο εκδόσεις κυκλοφορίας). Μπορείτε να το αλλάξετε οποτεδήποτε στις Ρυθμίσεις → Απόρρητο.';

  @override
  String get blocked => 'Αποκλεισμένος';

  @override
  String get idle => 'Αδρανής';

  @override
  String get noRunsYet => 'Δεν υπάρχουν ακόμη εκτελέσεις';

  @override
  String get copyPath => 'Αντιγραφή διαδρομής';

  @override
  String get copyRelativePath => 'Αντιγραφή σχετικής διαδρομής';

  @override
  String get nameRequired => 'Το όνομα είναι υποχρεωτικό';

  @override
  String get import => 'Εισαγωγή';

  @override
  String get noMatchingAgents => 'Κανένας πράκτορας δεν ταιριάζει με το φίλτρο';

  @override
  String watchVideoOn(String provider) {
    return 'Παρακολούθηση βίντεο στο $provider';
  }

  @override
  String get branchTemplate => 'Πρότυπο ονόματος κλάδου';

  @override
  String get branchTemplateDescription =>
      'Μοτίβο για τον κλάδο που δημιουργείται όταν ξεκινά ένα εισιτήριο σε απομονωμένο worktree.';

  @override
  String branchTemplatePreview(String example) {
    return 'Παράδειγμα: ⁨$example⁩';
  }

  @override
  String get deletePipelineRun => 'Διαγραφή εκτέλεσης pipeline';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Διαγραφή αυτής της εκτέλεσης του «$template»; Αυτή η ενέργεια δεν αναιρείται.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Σφάλμα διαγραφής εκτέλεσης pipeline: ⁨$error⁩';
  }

  @override
  String get deleteTicket => 'Διαγραφή εισιτηρίου';

  @override
  String deleteTicketConfirm(String title) {
    return 'Διαγραφή του «$title»; Αυτή η ενέργεια δεν αναιρείται.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Σφάλμα διαγραφής εισιτηρίου: ⁨$error⁩';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return 'Διαγραφή του «$name»; Τα συνδεδεμένα αποθετήρια στον δίσκο δεν επηρεάζονται.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Σφάλμα διαγραφής χώρου εργασίας: ⁨$error⁩';
  }

  @override
  String get indexCode => 'Ευρετηρίαση κώδικα';

  @override
  String get indexNoGrammars => 'Δεν έχουν εγκατασταθεί γραμματικές κώδικα';

  @override
  String get indexFailed => 'Η ευρετηρίαση απέτυχε';

  @override
  String indexedSymbolsCount(int count) {
    return '$count σύμβολα ευρετηριάστηκαν';
  }

  @override
  String get nodeConfigAdvanced => 'Για προχωρημένους';

  @override
  String get nodeConfigReducer => 'Reducer';

  @override
  String get nodeConfigReducerHelp =>
      'Πώς να συγχωνευτεί όταν αυτό το κλειδί εξόδου έχει ήδη τιμή';

  @override
  String get nodeConfigTimeoutMs => 'Χρονικό όριο (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Προσπάθειες επανάληψης';

  @override
  String get nodeConfigContinueOnFail => 'Συνέχεια αν αποτύχει αυτό το βήμα';

  @override
  String get nodeConfigTeamId => 'ID ομάδας';

  @override
  String get nodeConfigDispatchMode => 'Λειτουργία αποστολής';

  @override
  String get nodeConfigOutputSchema => 'Σχήμα εξόδου (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'JSON Schema που πρέπει να ικανοποιεί η έξοδος του βήματος';

  @override
  String get diffLineDisplay => 'Μεγάλες γραμμές στα diffs';

  @override
  String get diffLineDisplayDescription =>
      'Αναδίπλωση μεγάλων γραμμών ή οριζόντια κύλιση';

  @override
  String get diffLineWrap => 'Αναδίπλωση';

  @override
  String get diffLineScroll => 'Οριζόντια κύλιση';

  @override
  String get actions => 'Ενέργειες';

  @override
  String get activate => 'Ενεργοποίηση';

  @override
  String get activity => 'Δραστηριότητα';

  @override
  String get activityLabel => 'ΔΡΑΣΤΗΡΙΟΤΗΤΑ';

  @override
  String get activitySearchHint => 'Αναζήτηση δραστηριότητας';

  @override
  String get activityNoMatches =>
      'Καμία δραστηριότητα δεν ταιριάζει με τα φίλτρα';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end από $total';
  }

  @override
  String get activityPreviousPage => 'Προηγούμενη σελίδα';

  @override
  String get activityNextPage => 'Επόμενη σελίδα';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'Καθαρισμός φίλτρου';

  @override
  String activityFilterIp(String ip) {
    return 'IP ⁨$ip⁩';
  }

  @override
  String activityFilterCountry(String country) {
    return 'Χώρα $country';
  }

  @override
  String get activitySavedWorkspaceLogo =>
      'Αποθηκεύτηκε το λογότυπο του χώρου εργασίας';

  @override
  String activityVerbCreated(String target) {
    return 'Δημιούργησε $target';
  }

  @override
  String activityVerbUpdated(String target) {
    return 'Ενημέρωσε $target';
  }

  @override
  String activityVerbDeleted(String target) {
    return 'Διέγραψε $target';
  }

  @override
  String activityVerbAdded(String target) {
    return 'Πρόσθεσε $target';
  }

  @override
  String activityVerbRemoved(String target) {
    return 'Αφαίρεσε $target';
  }

  @override
  String activityVerbInvited(String target) {
    return 'Προσκάλεσε $target';
  }

  @override
  String activityVerbChanged(String target) {
    return 'Άλλαξε $target';
  }

  @override
  String activityVerbStarted(String target) {
    return 'Ξεκίνησε $target';
  }

  @override
  String activityVerbStopped(String target) {
    return 'Διέκοψε $target';
  }

  @override
  String activityVerbWrote(String target) {
    return 'Έγραψε $target';
  }

  @override
  String get activityTargetAgent => 'πράκτορα';

  @override
  String get activityTargetTicket => 'εισιτήριο';

  @override
  String get activityTargetWorkspace => 'χώρο εργασίας';

  @override
  String get activityTargetRepository => 'αποθετήριο';

  @override
  String get activityTargetMember => 'μέλος';

  @override
  String get activityTargetInvite => 'πρόσκληση';

  @override
  String get activityTargetSpace => 'χώρο';

  @override
  String get activityTargetMessage => 'μήνυμα';

  @override
  String get activityTargetCache => 'cache';

  @override
  String get activityTargetFile => 'αρχείο';

  @override
  String get activityTargetPipeline => 'pipeline';

  @override
  String get activityTargetTemplate => 'πρότυπο';

  @override
  String get activityTargetProvider => 'πάροχο';

  @override
  String get activityTargetModel => 'μοντέλο';

  @override
  String get activityTargetSkill => 'δεξιότητα';

  @override
  String get activityTargetTodo => 'εκκρεμότητα';

  @override
  String get activityTargetMeeting => 'σύσκεψη';

  @override
  String get activityTargetProject => 'έργο';

  @override
  String get activityTargetTeam => 'ομάδα';

  @override
  String get activityTargetDevice => 'συσκευή';

  @override
  String get activityTargetPreference => 'προτίμηση';

  @override
  String get activityTargetBudget => 'προϋπολογισμό';

  @override
  String activityVerbApproved(String target) {
    return 'Ενέκρινε $target';
  }

  @override
  String activityVerbArchived(String target) {
    return 'Αρχειοθέτησε $target';
  }

  @override
  String activityVerbAssigned(String target) {
    return 'Ανέθεσε $target';
  }

  @override
  String activityVerbBackedUp(String target) {
    return 'Δημιούργησε αντίγραφο ασφαλείας $target';
  }

  @override
  String activityVerbCancelled(String target) {
    return 'Ακύρωσε $target';
  }

  @override
  String activityVerbCleared(String target) {
    return 'Καθάρισε $target';
  }

  @override
  String activityVerbClosed(String target) {
    return 'Έκλεισε $target';
  }

  @override
  String activityVerbCommitted(String target) {
    return 'Έκανε commit $target';
  }

  @override
  String activityVerbCompacted(String target) {
    return 'Συμπύκνωσε $target';
  }

  @override
  String activityVerbCompleted(String target) {
    return 'Ολοκλήρωσε $target';
  }

  @override
  String activityVerbConnected(String target) {
    return 'Σύνδεσε $target';
  }

  @override
  String activityVerbContinued(String target) {
    return 'Συνέχισε $target';
  }

  @override
  String activityVerbDisconnected(String target) {
    return 'Αποσύνδεσε $target';
  }

  @override
  String activityVerbDispatched(String target) {
    return 'Απέστειλε $target';
  }

  @override
  String activityVerbDrained(String target) {
    return 'Άδειασε $target';
  }

  @override
  String activityVerbEnrolled(String target) {
    return 'Εγγράφηκε $target';
  }

  @override
  String activityVerbEstimated(String target) {
    return 'Εκτίμησε $target';
  }

  @override
  String activityVerbImported(String target) {
    return 'Εισήγαγε $target';
  }

  @override
  String activityVerbInstalled(String target) {
    return 'Εγκατέστησε $target';
  }

  @override
  String activityVerbKilled(String target) {
    return 'Τερμάτισε $target';
  }

  @override
  String activityVerbMarked(String target) {
    return 'Σήμανε $target';
  }

  @override
  String activityVerbMerged(String target) {
    return 'Συγχώνευσε $target';
  }

  @override
  String activityVerbOpened(String target) {
    return 'Άνοιξε $target';
  }

  @override
  String activityVerbPaused(String target) {
    return 'Έθεσε σε παύση $target';
  }

  @override
  String activityVerbPolled(String target) {
    return 'Ανέκτησε $target';
  }

  @override
  String activityVerbPrepared(String target) {
    return 'Προετοίμασε $target';
  }

  @override
  String activityVerbProcessed(String target) {
    return 'Επεξεργάστηκε $target';
  }

  @override
  String activityVerbPublished(String target) {
    return 'Δημοσίευσε $target';
  }

  @override
  String activityVerbRefined(String target) {
    return 'Βελτίωσε $target';
  }

  @override
  String activityVerbRefreshed(String target) {
    return 'Ανανέωσε $target';
  }

  @override
  String activityVerbRegistered(String target) {
    return 'Καταχώρισε $target';
  }

  @override
  String activityVerbRenamed(String target) {
    return 'Μετονόμασε $target';
  }

  @override
  String activityVerbReordered(String target) {
    return 'Αναδιάταξε $target';
  }

  @override
  String activityVerbResponded(String target) {
    return 'Απάντησε σε $target';
  }

  @override
  String activityVerbRestored(String target) {
    return 'Επανέφερε $target';
  }

  @override
  String activityVerbResumed(String target) {
    return 'Συνέχισε $target';
  }

  @override
  String activityVerbRetried(String target) {
    return 'Επανέλαβε $target';
  }

  @override
  String activityVerbReverted(String target) {
    return 'Αναίρεσε $target';
  }

  @override
  String activityVerbReviewed(String target) {
    return 'Ανασκόπησε $target';
  }

  @override
  String activityVerbRan(String target) {
    return 'Εκτέλεσε $target';
  }

  @override
  String activityVerbSelected(String target) {
    return 'Επέλεξε $target';
  }

  @override
  String activityVerbSent(String target) {
    return 'Έστειλε $target';
  }

  @override
  String activityVerbStaged(String target) {
    return 'Προετοίμασε $target';
  }

  @override
  String activityVerbSteered(String target) {
    return 'Κατεύθυνε $target';
  }

  @override
  String activityVerbSubmitted(String target) {
    return 'Υπέβαλε $target';
  }

  @override
  String activityVerbSynced(String target) {
    return 'Συγχρόνισε $target';
  }

  @override
  String activityVerbToggled(String target) {
    return 'Εναλλάχθηκε $target';
  }

  @override
  String activityVerbUninstalled(String target) {
    return 'Απεγκατέστησε $target';
  }

  @override
  String activityVerbUnstaged(String target) {
    return 'Αφαίρεσε από την προετοιμασία $target';
  }

  @override
  String get activityTargetActionPolicy => 'πολιτική ενεργειών';

  @override
  String get activityTargetGoalRun => 'εκτέλεση στόχου';

  @override
  String get activityTargetRunLog => 'ημερολόγιο εκτέλεσης';

  @override
  String get activityTargetWorkingMemory => 'μνήμη εργασίας';

  @override
  String get activityTargetRoutingPolicy => 'πολιτική δρομολόγησης';

  @override
  String get activityTargetAutonomy => 'αυτονομία';

  @override
  String get activityTargetCalendar => 'ημερολόγιο';

  @override
  String get activityTargetChecker => 'ελεγκτή';

  @override
  String get activityTargetEditor => 'επεξεργαστή';

  @override
  String get activityTargetConfirmation => 'επιβεβαίωση';

  @override
  String get activityTargetTunnel => 'σήραγγα';

  @override
  String get activityTargetConversation => 'συνομιλία';

  @override
  String get activityTargetCredentials => 'διαπιστευτήρια';

  @override
  String get activityTargetDictation => 'υπαγόρευση';

  @override
  String get activityTargetAgentRun => 'εκτέλεση πράκτορα';

  @override
  String get activityTargetEvalSuite => 'σουίτα αξιολόγησης';

  @override
  String get activityTargetWorker => 'εργάτη';

  @override
  String get activityTargetWorktree => 'worktree';

  @override
  String get activityTargetMcpServer => 'διακομιστή MCP';

  @override
  String get activityTargetMemoryAccessGrant => 'άδεια πρόσβασης μνήμης';

  @override
  String get activityTargetMemoryDomain => 'τομέα μνήμης';

  @override
  String get activityTargetMemoryFact => 'γεγονός μνήμης';

  @override
  String get activityTargetMemoryPolicy => 'πολιτική μνήμης';

  @override
  String get activityTargetFeed => 'ροή';

  @override
  String get activityTargetNote => 'σημείωση';

  @override
  String get activityTargetOrchestration => 'ενορχήστρωση';

  @override
  String get activityTargetPipelineRun => 'εκτέλεση pipeline';

  @override
  String get activityTargetPipelineTrigger => 'έναυσμα pipeline';

  @override
  String get activityTargetPlan => 'σχέδιο';

  @override
  String get activityTargetPlaybook => 'playbook';

  @override
  String get activityTargetPullRequest => 'pull request';

  @override
  String get activityTargetReview => 'ανασκόπηση';

  @override
  String get activityTargetProcess => 'διεργασία';

  @override
  String get activityTargetProviderPolicy => 'πολιτική παρόχου';

  @override
  String get activityTargetReaction => 'αντίδραση';

  @override
  String get activityTargetReviewSpace => 'χώρο ανασκόπησης';

  @override
  String get activityTargetReviewStudio => 'στούντιο ανασκόπησης';

  @override
  String get activityTargetServerData => 'δεδομένα διακομιστή';

  @override
  String get activityTargetSoundscape => 'ηχητικό περιβάλλον';

  @override
  String get activityTargetSession => 'συνεδρία';

  @override
  String get activityTargetTerminal => 'τερματικό';

  @override
  String get activityTargetTicketLink => 'σύνδεσμο εισιτηρίου';

  @override
  String get activityTargetTicketSync => 'συγχρονισμό εισιτηρίου';

  @override
  String get activityTargetProfile => 'προφίλ';

  @override
  String get activityTargetVoiceProfile => 'προφίλ φωνής';

  @override
  String get activityTargetWeather => 'πρόγνωση καιρού';

  @override
  String get activityTargetWorkProduct => 'προϊόν εργασίας';

  @override
  String get activityChangedMemberRole => 'Άλλαξε τον ρόλο ενός μέλους';

  @override
  String get activityChangedMemberRepoAccess =>
      'Άλλαξε την πρόσβαση αποθετηρίου ενός μέλους';

  @override
  String get activityUpdatedGitHubToken => 'Ενημέρωσε το token του GitHub';

  @override
  String get activityRefreshedWeather => 'Ανανέωσε την πρόγνωση καιρού';

  @override
  String get activitySetWeatherLocation => 'Όρισε την τοποθεσία καιρού';

  @override
  String get activityClearedWeatherLocation => 'Καθάρισε την τοποθεσία καιρού';

  @override
  String get activityMarkedAllArticlesRead =>
      'Σήμανε όλα τα άρθρα ως αναγνωσμένα';

  @override
  String get activityMarkedArticleRead => 'Σήμανε ένα άρθρο ως αναγνωσμένο';

  @override
  String get activityUpdatedSavedArticle => 'Ενημέρωσε ένα αποθηκευμένο άρθρο';

  @override
  String get activityTookOverSession => 'Ανέλαβε τη συνεδρία';

  @override
  String get activityHandedBackSession => 'Παρέδωσε πίσω τη συνεδρία';

  @override
  String get activityCommittedAndPushed => 'Έκανε commit και push';

  @override
  String get activityBackedUpServer =>
      'Δημιούργησε αντίγραφο ασφαλείας των δεδομένων του διακομιστή';

  @override
  String get activityMarkedSpaceRead => 'Σήμανε τον χώρο ως αναγνωσμένο';

  @override
  String get activityRespondedToInvitation =>
      'Απάντησε στην πρόσκληση γεγονότος';

  @override
  String get activityStartedCalendarConnect =>
      'Ξεκίνησε τη σύνδεση ημερολογίου';

  @override
  String get activityDisconnectedCalendar => 'Αποσύνδεσε το ημερολόγιο';

  @override
  String get activityMarkedFileViewed => 'Σήμανε ένα αρχείο ως προβλημένο';

  @override
  String get activityRespondedToApproval => 'Απάντησε σε αίτημα έγκρισης';

  @override
  String get activityChangedTunnel => 'Άλλαξε τη ρύθμιση σήραγγας';

  @override
  String get activitySentMessageToAgent => 'Έστειλε μήνυμα στον πράκτορα';

  @override
  String get activityOpenedReviewSpace => 'Άνοιξε τον χώρο ανασκόπησης';

  @override
  String get activityOpenedStandingConversation => 'Άνοιξε τη μόνιμη συνομιλία';

  @override
  String get activityStartedRecording => 'Ξεκίνησε την εγγραφή';

  @override
  String get activityStoppedRecording => 'Διέκοψε την εγγραφή';

  @override
  String get activityToggledMcpServer => 'Εναλλάχθηκε ο διακομιστής MCP';

  @override
  String get activityUpdatedMcpToken => 'Ενημέρωσε το token MCP';

  @override
  String get activitySavedApiKey => 'Αποθήκευσε ένα κλειδί API';

  @override
  String get activityRemovedProviderCredential =>
      'Αφαίρεσε διαπιστευτήρια παρόχου';

  @override
  String get activityUpdatedLinkedRepos =>
      'Ενημέρωσε τα συνδεδεμένα αποθετήρια';

  @override
  String get activityUnlinkedRepo => 'Αποσύνδεσε ένα αποθετήριο';

  @override
  String get activityUpdatedActionItem => 'Ενημέρωσε ένα στοιχείο ενέργειας';

  @override
  String adRulesCount(int count) {
    return '$count κανόνες διαφημίσεων';
  }

  @override
  String get adapter => 'Προσαρμογέας';

  @override
  String get adapterLabel => 'Προσαρμογέας';

  @override
  String get adapters => 'Προσαρμογείς';

  @override
  String get adaptersAutoDetected =>
      'Αυτόματα ανιχνευμένοι εκτελεστές πρακτόρων σε αυτό το μηχάνημα. Εγκαταστήστε τυχόν ελλείποντα εργαλεία CLI για επιπλέον εκτελεστές.';

  @override
  String get add => 'Προσθήκη';

  @override
  String get addAComment => 'Προσθήκη σχολίου';

  @override
  String get addAReaction => 'Προσθήκη αντίδρασης';

  @override
  String get addASuggestion => 'Προσθήκη πρότασης';

  @override
  String get addAgents => 'Προσθήκη πρακτόρων';

  @override
  String get addEmoji => 'Προσθήκη emoji';

  @override
  String get addFeed => 'Προσθήκη ροής';

  @override
  String get addressBarHint => 'Εισαγάγετε URL';

  @override
  String get addFromFile => 'Προσθήκη από αρχείο';

  @override
  String get addGif => 'Προσθήκη GIF';

  @override
  String get addGithubRepoPrompt =>
      'Προσθέστε τουλάχιστον ένα αποθετήριο GitHub για να δείτε pull requests';

  @override
  String get addLocalCheckoutDescription =>
      'Προσθέστε ένα τοπικό checkout για να αρχίσετε να το στοχεύετε από αυτόν τον χώρο εργασίας.';

  @override
  String get addRepository => 'Προσθήκη αποθετηρίου';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Προσθήκη $count αποθετηρίων',
      one: 'Προσθήκη αποθετηρίου',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'Περιηγηθείτε στους φακέλους του μηχανήματος που εκτελεί τον διακομιστή και επιλέξτε τα git checkouts προς καταχώριση.';

  @override
  String get selectThisFolder => 'Επιλογή αυτού του φακέλου';

  @override
  String get deselectThisFolder => 'Αποεπιλογή αυτού του φακέλου';

  @override
  String get goUp => 'Επάνω';

  @override
  String get noSubfoldersHere => 'Δεν υπάρχουν υποφάκελοι εδώ';

  @override
  String get notAGitRepository => 'Αυτός ο φάκελος δεν είναι αποθετήριο git.';

  @override
  String get addToken => 'Προσθήκη token';

  @override
  String get addWorkspace => 'Προσθήκη χώρου εργασίας';

  @override
  String get addWorkspaceEllipsis => 'Προσθήκη χώρου εργασίας…';

  @override
  String get added => 'Προστέθηκε';

  @override
  String get addingEllipsis => 'Προσθήκη…';

  @override
  String get advancedLabel => 'Για προχωρημένους';

  @override
  String get agent => 'Πράκτορας';

  @override
  String conversationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count συνομιλίες',
      one: '$count συνομιλία',
    );
    return '$_temp0';
  }

  @override
  String agentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count πράκτορες',
      one: '$count πράκτορας',
    );
    return '$_temp0';
  }

  @override
  String get agentMdPath => 'Διαδρομή Agent MD';

  @override
  String get agentName => 'Όνομα πράκτορα';

  @override
  String get agentTitle => 'Τίτλος πράκτορα';

  @override
  String get agentUpdated => 'Ο πράκτορας ενημερώθηκε.';

  @override
  String get agents => 'Πράκτορες';

  @override
  String get agentsMentionSection => 'Πράκτορες';

  @override
  String get usersMentionSection => 'Άτομα';

  @override
  String get ticketsMentionSection => 'Εισιτήρια';

  @override
  String get pullRequestsMentionSection => 'Pull requests';

  @override
  String get meetingsMentionSection => 'Συσκέψεις';

  @override
  String get entityRefTicketFallback => 'Εισιτήριο';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'Σύσκεψη';

  @override
  String get aiReview => 'Ανασκόπηση AI';

  @override
  String get all => 'Όλα';

  @override
  String get allAgentsAlreadyInSpace =>
      'Όλοι οι πράκτορες είναι ήδη σε αυτόν τον χώρο.';

  @override
  String get allCommits => 'Όλα τα commits';

  @override
  String get allSources => 'Όλες οι πηγές';

  @override
  String get allow => 'Αποδοχή';

  @override
  String get allowGitPush => 'Να επιτρέπεται git push';

  @override
  String get allowGithubApi => 'Να επιτρέπονται κλήσεις GitHub API';

  @override
  String get allowNetwork => 'Να επιτρέπεται γενική πρόσβαση στο δίκτυο';

  @override
  String get apiKeys => 'Κλειδιά API';

  @override
  String get appFont => 'Γραμματοσειρά εφαρμογής';

  @override
  String get appLogLevelDebugDescription =>
      'Προσθέτει λεπτομερή ίχνη — για ανάπτυξη.';

  @override
  String get appLogLevelDebugLabel => 'Debug';

  @override
  String get appLogLevelErrorDescription =>
      'Μόνο απροσδόκητα σφάλματα και εξαιρέσεις.';

  @override
  String get appLogLevelErrorLabel => 'Σφάλμα';

  @override
  String get appLogLevelInfoDescription =>
      'Προσθέτει μηνύματα κύκλου ζωής και κατάστασης.';

  @override
  String get appLogLevelInfoLabel => 'Πληροφορίες';

  @override
  String get appLogLevelNoneDescription => 'Καμία έξοδος κονσόλας.';

  @override
  String get appLogLevelNoneLabel => 'Καμία';

  @override
  String get appLogLevelVerboseDescription =>
      'Τα πάντα. Εξαιρετικά θορυβώδες — μόνο για αποσφαλμάτωση.';

  @override
  String get appLogLevelVerboseLabel => 'Λεπτομερές';

  @override
  String get appLogLevelWarningDescription =>
      'Προσθέτει προειδοποιήσεις και ανακτήσιμα προβλήματα.';

  @override
  String get appLogLevelWarningLabel => 'Προειδοποίηση';

  @override
  String get appearanceLanguage => 'Εμφάνιση και γλώσσα';

  @override
  String get apply => 'Εφαρμογή';

  @override
  String get approve => 'Έγκριση';

  @override
  String get agentApprovalRequired => 'Απαιτείται έγκριση';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ακόμη σε αναμονή',
      one: '1 ακόμη σε αναμονή',
    );
    return '$_temp0';
  }

  @override
  String get approved => 'Εγκρίθηκε';

  @override
  String get articleNoun => 'Άρθρο';

  @override
  String get articlesSubscribed =>
      'Άρθρα από τις ροές στις οποίες είστε εγγεγραμμένοι.';

  @override
  String get askAi => 'Ερώτηση AI';

  @override
  String get askAiReviewDescription =>
      'Ζητήστε από την AI να ανασκοπήσει αυτό το PR';

  @override
  String get assignees => 'Ανατεθειμένοι';

  @override
  String get attachImage => 'Επισύναψη εικόνας';

  @override
  String get attachedAgents => 'Συνδεδεμένοι πράκτορες';

  @override
  String get audioInput => 'Είσοδος ήχου';

  @override
  String get audioOutput => 'Έξοδος ήχου';

  @override
  String get authenticationToken => 'Token ελέγχου ταυτότητας';

  @override
  String authoredByLabel(String role) {
    return 'Από: $role';
  }

  @override
  String get autoRecommended => 'Αυτόματο (συνιστάται)';

  @override
  String get available => 'Διαθέσιμο';

  @override
  String get awaitingYourReview => 'Αναμονή της ανασκόπησής σας';

  @override
  String get back => 'Πίσω';

  @override
  String get backLabel => 'Πίσω';

  @override
  String get backend => 'Backend';

  @override
  String get blockAdsTrackers =>
      'Αποκλεισμός διαφημίσεων, ιχνηλατών και banner cookies';

  @override
  String get blocking => 'Αποκλεισμός';

  @override
  String get bookmarkLabel => 'Σελιδοδείκτης';

  @override
  String get briefDescription => 'Σύντομη περιγραφή';

  @override
  String get bugLabel => 'ΣΦΑΛΜΑ';

  @override
  String get bundledDefaultsNeverUpdated =>
      'Ενσωματωμένες προεπιλογές — χωρίς ενημέρωση';

  @override
  String get cancel => 'Ακύρωση';

  @override
  String get cancelEdit => 'Ακύρωση επεξεργασίας';

  @override
  String get categoryCreation => 'Δημιουργία';

  @override
  String get categoryEditing => 'Επεξεργασία';

  @override
  String get categoryNavigation => 'Πλοήγηση';

  @override
  String get categorySystem => 'Σύστημα';

  @override
  String get categoryView => 'Προβολή κατηγορίας';

  @override
  String get change => 'Αλλαγή';

  @override
  String get changesRequested => 'Ζητήθηκαν αλλαγές';

  @override
  String get spacesMentionSection => 'Χώροι';

  @override
  String get checkForUpdates => 'Έλεγχος ενημερώσεων';

  @override
  String get checking => 'Έλεγχος';

  @override
  String get checkingEllipsis => 'Έλεγχος…';

  @override
  String get chooseAppFont => 'Επιλογή γραμματοσειράς εφαρμογής';

  @override
  String get chooseCodeFont => 'Επιλογή γραμματοσειράς κώδικα';

  @override
  String get chooseRunner => 'Επιλέξτε τον εκτελεστή πρακτόρων.';

  @override
  String get clear => 'Καθαρισμός';

  @override
  String get clickToRetry => 'Κάντε κλικ για επανάληψη';

  @override
  String get close => 'Κλείσιμο';

  @override
  String get closeEsc => 'Κλείσιμο (Esc)';

  @override
  String get closeReader => 'Κλείσιμο αναγνώστη';

  @override
  String get closed => 'Κλειστό';

  @override
  String get codeFont => 'Γραμματοσειρά κώδικα';

  @override
  String get codeFontLigatures => 'Συμπλέγματα γραμματοσειράς κώδικα';

  @override
  String get codeFontLigaturesDescription =>
      'Απόδοση προγραμματιστικών συμπλεγμάτων (=>, !=, ->) ως ενωμένα γλυφικά στον κώδικα και τα diffs';

  @override
  String get collapse => 'Σύμπτυξη';

  @override
  String get commandPalette => 'Παλέτα εντολών';

  @override
  String get commandPaletteOrgMembers => 'Μέλη οργανισμού';

  @override
  String get commandPaletteBrowseTeam => 'Περιήγηση ομάδας';

  @override
  String get commandPaletteBrowseTeamDesc =>
      'Προβολή όλων των μελών του οργανισμού';

  @override
  String get compactDone =>
      'Η συνομιλία συμπυκνώθηκε. Το παλαιότερο ιστορικό διπλώθηκε σε σύνοψη.';

  @override
  String get compactNothing =>
      'Δεν υπάρχει ακόμη τίποτα για συμπύκνωση. Η συνομιλία είναι ακόμα σύντομη.';

  @override
  String get compactBusy =>
      'Ένας πράκτορας εργάζεται ακόμα. Συμπυκνώστε όταν τελειώσει η σειρά.';

  @override
  String get compactUnavailable =>
      'Η συμπύκνωση δεν είναι διαθέσιμη σε αυτόν τον διακομιστή.';

  @override
  String get commandsMentionSection => 'Εντολές';

  @override
  String get comment => 'Σχόλιο';

  @override
  String get commentOnThisFile => 'Σχόλιο σε αυτό το αρχείο';

  @override
  String get commented => 'Σχολιάστηκε';

  @override
  String get commits => 'Commits';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Εμφάνιση των τελευταίων $loaded από $total commits';
  }

  @override
  String get prCloneProgressCloningTitle => 'Κλωνοποίηση αποθετηρίου';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'Αυτό το PR αλλάζει $fileCount αρχεία, που υπερβαίνει το όριο API του GitHub. Κλωνοποίηση του αποθετηρίου τοπικά…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'Αυτό το PR υπερβαίνει το όριο αρχείων του GitHub API. Κλωνοποίηση του αποθετηρίου τοπικά…';

  @override
  String get prCloneProgressFetchingTitle => 'Ανάκτηση refs του PR';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Ανάκτηση του βασικού κλάδου και του head ref του PR…';

  @override
  String get prCloneProgressComputingTitle => 'Υπολογισμός diff';

  @override
  String get prCloneProgressComputingSubtitle => 'Εκτέλεση git diff τοπικά…';

  @override
  String get prCloneProgressErrorTitle => 'Αποτυχία φόρτωσης diff';

  @override
  String get prCloneProgressErrorSubtitle =>
      'Προέκυψε σφάλμα κατά την κλωνοποίηση ή τον υπολογισμό του diff. Δοκιμάστε ανανέωση.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Ακόμη σε εξέλιξη… πέρασαν $elapsed';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Εμπιστοσύνη: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'Ρυθμίστε ταυτότητες πρακτόρων, προτροπές, δεξιότητες και δείτε εκτελέσεις.';

  @override
  String get configureDefaultRunners =>
      'Ρυθμίστε ποιον προσαρμογέα και μοντέλο χρησιμοποιούν οι νέοι χώροι και η δημιουργία τίτλων.';

  @override
  String get configuredLabel => 'Ρυθμίστηκε.';

  @override
  String get confirmedBy => 'Επιβεβαιώθηκε από';

  @override
  String get consensus => 'Συναίνεση';

  @override
  String get contentHint => 'Τι πρέπει να θυμάται';

  @override
  String get contentLabel => 'Περιεχόμενο';

  @override
  String get contentMarkdown => 'Περιεχόμενο (Markdown)';

  @override
  String get contextWindowSize => 'Μέγεθος παραθύρου πλαισίου';

  @override
  String modelContextChip(String size) {
    return 'Μοντέλο · $size';
  }

  @override
  String get continueLabel => 'Συνέχεια';

  @override
  String get conversationMode => 'Λειτουργία';

  @override
  String cookieRulesCount(int count) {
    return '$count κανόνες cookie';
  }

  @override
  String get copied => 'Αντιγράφηκε!';

  @override
  String get copy => 'Αντιγραφή';

  @override
  String get copyAddress => 'Αντιγραφή διεύθυνσης';

  @override
  String get copyBaseBranchTooltip => 'Αντιγραφή ονόματος βασικού κλάδου';

  @override
  String get copyHeadBranchTooltip => 'Αντιγραφή ονόματος κλάδου head';

  @override
  String couldNotListDevices(String error) {
    return 'Δεν ήταν δυνατή η λίστα συσκευών: ⁨$error⁩';
  }

  @override
  String get create => 'Δημιουργία';

  @override
  String get createOrSelectWorkspace =>
      'Δημιουργήστε ή επιλέξτε χώρο εργασίας πριν προσθέσετε αποθετήρια.';

  @override
  String get createPullRequest => 'Δημιουργία pull request';

  @override
  String get createdByMe => 'Δημιουργήθηκαν από εμένα';

  @override
  String createdLabel(String date) {
    return 'Δημιουργήθηκε: $date';
  }

  @override
  String get currentParticipants => 'Τρέχοντες συμμετέχοντες';

  @override
  String get customCapabilitiesDescription =>
      'Περιγραφή προσαρμοσμένων δυνατοτήτων';

  @override
  String get customSystemPrompt =>
      'Προσαρμοσμένη προτροπή συστήματος για αυτόν τον πράκτορα...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'πριν από $count ημέρες',
      one: 'πριν από 1 ημέρα',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Απενεργοποίηση';

  @override
  String get defaultCapabilities => 'Προεπιλεγμένες δυνατότητες · νέοι χώροι';

  @override
  String get defaultChat => 'Προεπιλεγμένη συνομιλία';

  @override
  String get defaultRunners => 'Προεπιλεγμένοι εκτελεστές';

  @override
  String get delete => 'Διαγραφή';

  @override
  String get deleteAgent => 'Διαγραφή πράκτορα';

  @override
  String deleteAgentConfirm(String name) {
    return 'Διαγραφή του «$name»; Αυτή η ενέργεια δεν αναιρείται.';
  }

  @override
  String get deleteSpace => 'Διαγραφή χώρου';

  @override
  String deleteConfirmName(String name) {
    return 'Διαγραφή του «$name»;';
  }

  @override
  String get archiveConversation => 'Αρχειοθέτηση συνομιλίας';

  @override
  String get deleteFact => 'Διαγραφή γεγονότος';

  @override
  String get deleteFeedBody =>
      'Αυτό αφαιρεί τη ροή και όλα τα αποθηκευμένα άρθρα της. Θα αφαιρεθούν και τα άρθρα με σελιδοδείκτη από αυτή τη ροή.';

  @override
  String deleteFeedConfirm(String name) {
    return 'Διαγραφή του «$name»;';
  }

  @override
  String get deletePolicy => 'Διαγραφή πολιτικής';

  @override
  String get deletePolicyConfirm =>
      'Διαγραφή αυτής της πολιτικής; Αυτή η ενέργεια δεν αναιρείται.';

  @override
  String deleteTopicConfirm(String topic) {
    return 'Διαγραφή του «$topic»; Αυτή η ενέργεια δεν αναιρείται.';
  }

  @override
  String get deleteWorkspace => 'Διαγραφή χώρου εργασίας';

  @override
  String get deny => 'Απόρριψη';

  @override
  String get detailsLabel => 'Λεπτομέρειες';

  @override
  String get descriptionLabel => 'Περιγραφή';

  @override
  String detectedBackend(String label) {
    return 'Ανιχνεύθηκε: $label';
  }

  @override
  String get detectedRunners => 'Ανιχνευμένοι εκτελεστές';

  @override
  String get detectingAdapters => 'Ανίχνευση προσαρμογέων…';

  @override
  String get detectingInputDevices => 'Ανίχνευση συσκευών εισόδου…';

  @override
  String detectionFailed(String error) {
    return 'Η ανίχνευση απέτυχε: ⁨$error⁩';
  }

  @override
  String get disabled => 'Απενεργοποιημένο';

  @override
  String get discover => 'Ανακάλυψη';

  @override
  String get dismissed => 'Απορρίφθηκε';

  @override
  String get domainHint => 'π.χ. ⁨api-performance⁩';

  @override
  String get domainLabel => 'Τομέας';

  @override
  String get download => 'Λήψη';

  @override
  String get downloadingLabel => 'Λήψη';

  @override
  String downloadingModel(int pct) {
    return 'Λήψη μοντέλου… $pct%';
  }

  @override
  String get draft => 'Πρόχειρο';

  @override
  String get draftLabel => 'Πρόχειρο';

  @override
  String get edit => 'Επεξεργασία';

  @override
  String get edited => 'επεξεργάστηκε';

  @override
  String get editMessage => 'Επεξεργασία μηνύματος';

  @override
  String get revertToThere => 'Επαναφορά έως εκεί';

  @override
  String get sendAsNewMessage => 'Αποστολή ως νέο μήνυμα';

  @override
  String get editMessageChoiceBody =>
      'Η επαναφορά κρύβει τα μηνύματα μετά από αυτό και επαναφέρει τα αρχεία του πράκτορα. Μπορείτε να την αναιρέσετε. Η αποστολή ως νέο μήνυμα αφήνει τη συζήτηση ως έχει.';

  @override
  String get deleteMessage => 'Διαγραφή μηνύματος';

  @override
  String get deleteMessageConfirm =>
      'Διαγραφή αυτού του μηνύματος; Αυτή η ενέργεια δεν αναιρείται.';

  @override
  String get messageDeleted => 'Το μήνυμα διαγράφηκε';

  @override
  String get searchInConversation => 'Αναζήτηση στη συνομιλία';

  @override
  String get searchMessagesHint => 'Αναζήτηση μηνυμάτων…';

  @override
  String get noMessagesFound => 'Δεν βρέθηκαν μηνύματα';

  @override
  String get editFact => 'Επεξεργασία γεγονότος';

  @override
  String get editPolicy => 'Επεξεργασία πολιτικής';

  @override
  String get editSuggestedCodeHint => 'Επεξεργασία προτεινόμενου κώδικα…';

  @override
  String get editSuggestion => 'Επεξεργασία πρότασης';

  @override
  String get egArchitect => 'π.χ. architect';

  @override
  String get egControlCenter => 'π.χ. ⁨control-center⁩';

  @override
  String get egPlatform => 'π.χ. Platform';

  @override
  String get egSamuelAlev => 'π.χ. SamuelAlev';

  @override
  String get egSoftwareArchitect => 'π.χ. Software Architect';

  @override
  String get egTheVerge => 'π.χ. The Verge';

  @override
  String get egTokenLimit => 'π.χ. 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Η εγκατάσταση απέτυχε: ⁨$error⁩';
  }

  @override
  String get embeddingInstalled =>
      'Το τοπικό μοντέλο ενσωμάτωσης εγκαταστάθηκε. Η υβριδική αναζήτηση είναι ενεργή.';

  @override
  String get embeddingModel => 'Μοντέλο ενσωμάτωσης (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Δεν είναι εγκατεστημένο. Η αναζήτηση περιορίζεται σε λέξεις-κλειδιά μέχρι να ενεργοποιηθεί.';

  @override
  String get embeddingRedownloadBody =>
      'Τα υπάρχοντα αρχεία μοντέλου θα διαγραφούν και θα ληφθούν ξανά. Η σημασιολογική αναζήτηση δεν θα είναι διαθέσιμη μέχρι να ολοκληρωθεί η λήψη.';

  @override
  String get embeddingRemoveBody =>
      'Η σημασιολογική αναζήτηση θα απενεργοποιηθεί μέχρι να το επανεγκαταστήσετε. Μπορείτε να το εγκαταστήσετε ξανά οποτεδήποτε.';

  @override
  String get speakerDiarization => 'Διαχωρισμός ομιλητών';

  @override
  String get diarizationModel => 'Μοντέλο διαχωρισμού ομιλητών';

  @override
  String get diarizationInstalled =>
      'Εγκατεστημένο — ονομάζει μεμονωμένους ομιλητές στα πρακτικά συσκέψεων';

  @override
  String get diarizationNotInstalled =>
      'Δεν είναι εγκατεστημένο — οι ομιλητές συσκέψεων δεν θα διαχωρίζονται';

  @override
  String diarizationInstallFailed(String error) {
    return 'Η εγκατάσταση απέτυχε: ⁨$error⁩';
  }

  @override
  String get redownloadDiarizationModel =>
      'Επανάληψη λήψης μοντέλου διαχωρισμού';

  @override
  String get diarizationRedownloadBody =>
      'Αυτό αφαιρεί τα τρέχοντα μοντέλα διαχωρισμού και τα κατεβάζει ξανά.';

  @override
  String get removeDiarizationModel => 'Αφαίρεση μοντέλου διαχωρισμού';

  @override
  String get diarizationRemoveBody =>
      'Αυτό διαγράφει τα μοντέλα διαχωρισμού στη συσκευή. Τα πρακτικά συσκέψεων που έχουν ήδη παραχθεί δεν επηρεάζονται.';

  @override
  String get enableNotifications => 'Ενεργοποίηση ειδοποιήσεων';

  @override
  String get enableSandboxing => 'Ενεργοποίηση sandbox';

  @override
  String get enabled => 'Ενεργοποιημένο';

  @override
  String errorCreatingAgent(String error) {
    return 'Σφάλμα δημιουργίας πράκτορα: ⁨$error⁩';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Σφάλμα διαγραφής πράκτορα: ⁨$error⁩';
  }

  @override
  String errorWithDetail(String error) {
    return 'Σφάλμα: ⁨$error⁩';
  }

  @override
  String get expand => 'Ανάπτυξη';

  @override
  String extractingModel(int pct) {
    return 'Εξαγωγή μοντέλου… $pct%';
  }

  @override
  String get fact => 'Γεγονός';

  @override
  String factCount(int count) {
    return '$count γεγονός';
  }

  @override
  String factCountPlural(int count) {
    return '$count γεγονότα';
  }

  @override
  String get facts => 'Γεγονότα';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount γεγονότα · $policyCount πολιτικές';
  }

  @override
  String get failed => 'Αποτυχία';

  @override
  String failedToDispatch(String error) {
    return 'Αποτυχία αποστολής: ⁨$error⁩';
  }

  @override
  String get failedToLoad => 'Αποτυχία φόρτωσης';

  @override
  String failedToLoadAgents(String error) {
    return 'Αποτυχία φόρτωσης πρακτόρων: ⁨$error⁩';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Αποτυχία φόρτωσης ροών: ⁨$error⁩';
  }

  @override
  String get failedToLoadGifs => 'Αποτυχία φόρτωσης GIF';

  @override
  String failedToLoadLogs(String error) {
    return 'Αποτυχία φόρτωσης αρχείων καταγραφής: ⁨$error⁩';
  }

  @override
  String get failedToLoadRepos => 'Αποτυχία φόρτωσης αποθετηρίων';

  @override
  String get failedToLoadWorkspaces => 'Αποτυχία φόρτωσης χώρων εργασίας';

  @override
  String failedToStartAiReview(String error) {
    return 'Αποτυχία έναρξης ανασκόπησης AI: ⁨$error⁩';
  }

  @override
  String get failedToStartMicTest => 'Αποτυχία έναρξης δοκιμής μικροφώνου.';

  @override
  String failedToSubmitReview(String error) {
    return 'Αποτυχία υποβολής ανασκόπησης: ⁨$error⁩';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'Αποτυχία αποστολής του ⁨$name⁩: ⁨$error⁩';
  }

  @override
  String failedWithError(String error) {
    return 'Αποτυχία: ⁨$error⁩';
  }

  @override
  String get failure => 'Αποτυχία';

  @override
  String get feedAlreadyExists => 'Υπάρχει ήδη ροή με αυτό το URL.';

  @override
  String get feedUrlExample => 'π.χ. ⁨https://example.com/feed.xml⁩';

  @override
  String get feedUrlLabel => 'URL ροής';

  @override
  String feedsCount(int count) {
    return 'Ροές ($count)';
  }

  @override
  String get filesChanged => 'Αλλαγμένα αρχεία';

  @override
  String filesCount(int count) {
    return '$count αρχείο(-α)';
  }

  @override
  String get filesMentionSection => 'Αρχεία';

  @override
  String get filterAgents => 'Φιλτράρισμα πρακτόρων...';

  @override
  String get filterFilesHint => 'Φιλτράρισμα αρχείων…';

  @override
  String get filterLists => 'Λίστες φίλτρων';

  @override
  String get filterSkillsPlaceholder => 'Φιλτράρισμα δεξιοτήτων…';

  @override
  String get finish => 'Ολοκλήρωση';

  @override
  String get fix => 'Διόρθωση';

  @override
  String get forward => 'Εμπρός';

  @override
  String get gatesGithubPatPush =>
      'Ελέγχει την εισαγωγή GitHub PAT. Απαιτείται για να κάνει ο πράκτορας push.';

  @override
  String get general => 'Γενικά';

  @override
  String get githubLink => 'Σύνδεσμος GitHub';

  @override
  String get claudeStatusFetchFailed =>
      'Δεν ήταν δυνατή η επικοινωνία με το ⁨status.claude.com⁩';

  @override
  String get claudeStatusOpenInBrowser => 'Άνοιγμα του ⁨status.claude.com⁩';

  @override
  String get githubStatusFetchFailed =>
      'Δεν ήταν δυνατή η επικοινωνία με το ⁨githubstatus.com⁩';

  @override
  String get githubDegradedTitle => 'Το GitHub αναφέρει προβλήματα';

  @override
  String githubDegradedStatusLine(String status) {
    return 'Κατάσταση GitHub: $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'Κατάσταση GitHub: $status. Τα δεδομένα pull request μπορεί να είναι παλιά ή ελλιπή μέχρι να αποκατασταθεί.';
  }

  @override
  String get githubStatusOpenInBrowser => 'Άνοιγμα του ⁨githubstatus.com⁩';

  @override
  String get githubStatusRefresh => 'Ανανέωση';

  @override
  String githubStatusUpdated(String time) {
    return 'Ενημερώθηκε $time';
  }

  @override
  String get kimiStatusFetchFailed =>
      'Δεν ήταν δυνατή η επικοινωνία με το ⁨status.moonshot.cn⁩';

  @override
  String get kimiStatusOpenInBrowser => 'Άνοιγμα του ⁨status.moonshot.cn⁩';

  @override
  String get openaiStatusFetchFailed =>
      'Δεν ήταν δυνατή η επικοινωνία με το ⁨status.openai.com⁩';

  @override
  String get openaiStatusOpenInBrowser => 'Άνοιγμα του ⁨status.openai.com⁩';

  @override
  String get serviceStatusMaintenance => 'Συντήρηση';

  @override
  String get serviceStatusMajorIssues => 'Σοβαρά προβλήματα';

  @override
  String get serviceStatusMinorIssues => 'Μικρά προβλήματα';

  @override
  String get serviceStatusOperational => 'Λειτουργικό';

  @override
  String get serviceStatusOutage => 'Διακοπή';

  @override
  String get serviceStatusTitle => 'Κατάσταση υπηρεσιών';

  @override
  String get serviceStatusUnknown => 'Άγνωστη';

  @override
  String lastChecked(String time) {
    return 'Ελέγχθηκε $time';
  }

  @override
  String get lastCheckedRecently => 'Ελέγχθηκε πρόσφατα';

  @override
  String get giveYourWorkAHome => 'Δώστε στην εργασία σας μια έδρα.';

  @override
  String get goBack => 'Επιστροφή';

  @override
  String get goForward => 'Προώθηση';

  @override
  String get googleFonts => 'Google fonts';

  @override
  String get high => 'Υψηλό';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'πριν από $count ώρες',
      one: 'πριν από 1 ώρα',
    );
    return '$_temp0';
  }

  @override
  String get sidebarAgeNow => 'τώρα';

  @override
  String sidebarAgeMinutes(int count) {
    return '$count λ';
  }

  @override
  String sidebarAgeHours(int count) {
    return '$count ώ';
  }

  @override
  String sidebarAgeDays(int count) {
    return '$count η';
  }

  @override
  String sidebarAgeMonths(int count) {
    return '$count μήν';
  }

  @override
  String sidebarAgeYears(int count) {
    return '$count έ';
  }

  @override
  String get images => 'Εικόνες';

  @override
  String get inactive => 'Ανενεργό';

  @override
  String get install => 'Εγκατάσταση';

  @override
  String get installRequired => 'Απαιτείται εγκατάσταση';

  @override
  String installedVersion(String version) {
    return 'Εγκατεστημένη $version';
  }

  @override
  String get invite => 'Πρόσκληση';

  @override
  String get inviteAgent => 'Πρόσκληση πράκτορα';

  @override
  String get isolateAgentExecution => 'Απομονώστε την εκτέλεση των πρακτόρων.';

  @override
  String get justNow => 'Μόλις τώρα';

  @override
  String get keepSandboxing => 'Διατήρηση sandbox';

  @override
  String get keybindingAddARepositoryDescription => 'Προσθήκη αποθετηρίου';

  @override
  String get keybindingAddRepository => 'Προσθήκη αποθετηρίου';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Προσθήκη ή αφαίρεση σελιδοδείκτη στο επιλεγμένο άρθρο';

  @override
  String get keybindingCommandPalette => 'Παλέτα εντολών';

  @override
  String get keybindingCreateANewAgentDescription => 'Δημιουργία νέου πράκτορα';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Δημιουργία νέου χώρου εργασίας';

  @override
  String get keybindingFocusSearch => 'Εστίαση στην αναζήτηση';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Εστίαση στο πεδίο αναζήτησης pull request';

  @override
  String get keybindingNewAgent => 'Νέος πράκτορας';

  @override
  String get keybindingNewWorkspace => 'Νέος χώρος εργασίας';

  @override
  String get keybindingNextArticle => 'Επόμενο άρθρο';

  @override
  String get keybindingNextSpace => 'Επόμενος χώρος';

  @override
  String get keybindingNextWorkspace => 'Επόμενος χώρος εργασίας';

  @override
  String get keybindingOpenArticle => 'Άνοιγμα άρθρου';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Άνοιγμα ή κλείσιμο του αναδυόμενου εναλλαγής χώρου εργασίας στην πλαϊνή γραμμή';

  @override
  String get keybindingOpenPr => 'Άνοιγμα PR';

  @override
  String get keybindingOpenSettings => 'Άνοιγμα ρυθμίσεων';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Άνοιγμα των ρυθμίσεων της εφαρμογής';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Άνοιγμα της παλέτας εντολών';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Άνοιγμα του επιλεγμένου άρθρου';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Άνοιγμα του επιλεγμένου pull request';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Άνοιγμα του επιλεγμένου χώρου εργασίας';

  @override
  String get keybindingOpenWorkspace => 'Άνοιγμα χώρου εργασίας';

  @override
  String get keybindingPreviousArticle => 'Προηγούμενο άρθρο';

  @override
  String get keybindingPreviousSpace => 'Προηγούμενος χώρος';

  @override
  String get keybindingPreviousWorkspace => 'Προηγούμενος χώρος εργασίας';

  @override
  String get keybindingRefresh => 'Ανανέωση';

  @override
  String get keybindingRefreshAllFeedsDescription => 'Ανανέωση όλων των ροών';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Ανανέωση της λίστας pull request';

  @override
  String get keybindingRescanForAdaptersDescription =>
      'Επανάληψη σάρωσης προσαρμογέων';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Επιλογή του επόμενου άρθρου';

  @override
  String get keybindingSelectTheNextSpaceDescription =>
      'Επιλογή του επόμενου χώρου';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Επιλογή του προηγούμενου άρθρου';

  @override
  String get keybindingSelectThePreviousSpaceDescription =>
      'Επιλογή του προηγούμενου χώρου';

  @override
  String get keybindingSendMessage => 'Αποστολή μηνύματος';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Αποστολή του τρέχοντος μηνύματος';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Εναλλαγή φωτεινής και σκοτεινής λειτουργίας';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Μετάβαση στον όγδοο χώρο εργασίας';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Μετάβαση στον πέμπτο χώρο εργασίας';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Μετάβαση στον πρώτο χώρο εργασίας';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Μετάβαση στον τέταρτο χώρο εργασίας';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Μετάβαση στον επόμενο χώρο εργασίας';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Μετάβαση στον ένατο χώρο εργασίας';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Μετάβαση στον προηγούμενο χώρο εργασίας';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Μετάβαση στον δεύτερο χώρο εργασίας';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Μετάβαση στον έβδομο χώρο εργασίας';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Μετάβαση στον έκτο χώρο εργασίας';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Μετάβαση στον τρίτο χώρο εργασίας';

  @override
  String get keybindingToggleBookmark => 'Εναλλαγή σελιδοδείκτη';

  @override
  String get keybindingToggleTheme => 'Εναλλαγή θέματος';

  @override
  String get keybindingToggleWorkspaceSwitcher =>
      'Εναλλαγή εναλλαγής χώρου εργασίας';

  @override
  String get keybindingWorkspace1 => 'Χώρος εργασίας 1';

  @override
  String get keybindingWorkspace2 => 'Χώρος εργασίας 2';

  @override
  String get keybindingWorkspace3 => 'Χώρος εργασίας 3';

  @override
  String get keybindingWorkspace4 => 'Χώρος εργασίας 4';

  @override
  String get keybindingWorkspace5 => 'Χώρος εργασίας 5';

  @override
  String get keybindingWorkspace6 => 'Χώρος εργασίας 6';

  @override
  String get keybindingWorkspace7 => 'Χώρος εργασίας 7';

  @override
  String get keybindingWorkspace8 => 'Χώρος εργασίας 8';

  @override
  String get keybindingWorkspace9 => 'Χώρος εργασίας 9';

  @override
  String get keybindings => 'Συντομεύσεις πληκτρολογίου';

  @override
  String get keybindingsDescription =>
      'Όλες οι συντομεύσεις πληκτρολογίου. Οι συντομεύσεις είναι σταθερές και δεν μπορούν να επανεκχωρηθούν.';

  @override
  String get killRunning => 'Τερματισμός εκτέλεσης';

  @override
  String get languageSystem => 'Σύστημα';

  @override
  String get leaveACommentEllipsis => 'Αφήστε ένα σχόλιο…';

  @override
  String get legendLabel => 'Υπόμνημα';

  @override
  String get lessLabel => 'Λιγότερα';

  @override
  String get letsPluginTools => 'Ας συνδέσουμε τα εργαλεία σας.';

  @override
  String get level => 'Επίπεδο';

  @override
  String get loadingAgents => 'Φόρτωση πρακτόρων…';

  @override
  String get loadingModels => 'Φόρτωση μοντέλων…';

  @override
  String get loadingProviders => 'Φόρτωση παρόχων…';

  @override
  String get logLevel => 'Επίπεδο καταγραφής';

  @override
  String get logs => 'Αρχεία καταγραφής';

  @override
  String get low => 'Χαμηλό';

  @override
  String get maintenance => 'Συντήρηση';

  @override
  String get manageParticipants => 'Διαχείριση συμμετεχόντων';

  @override
  String get manageWorkspaces => 'Διαχείριση χώρων εργασίας';

  @override
  String get reorderWorkspace => 'Αναδιάταξη χώρου εργασίας';

  @override
  String get matchOsAppearance =>
      'Ακολουθήστε την εμφάνιση του λειτουργικού ή επιλέξτε σταθερή λειτουργία.';

  @override
  String get mcpAuthToken => 'Token ελέγχου ταυτότητας MCP';

  @override
  String get mcpNotAvailableOnServer =>
      'Ο έλεγχος διακομιστή MCP δεν είναι διαθέσιμος στον συνδεδεμένο διακομιστή.';

  @override
  String get modelManagedOnServer =>
      'Αυτό το μοντέλο εκτελείται στον κεντρικό υπολογιστή του διακομιστή και διαχειρίζεται εκεί.';

  @override
  String get mcpServer => 'Διακομιστής MCP';

  @override
  String get medium => 'Μεσαίο';

  @override
  String get memoryDataHint =>
      'Γεγονότα και πολιτικές θα εμφανιστούν εδώ καθώς εργάζονται οι πράκτορες.';

  @override
  String get memoryLabel => 'Μνήμη';

  @override
  String get merge => 'Συγχώνευση';

  @override
  String get merged => 'Συγχωνεύθηκε';

  @override
  String get messagePlaceholder => 'Μήνυμα… (@ για αναφορά, / για εντολές)';

  @override
  String get navConversations => 'Χώροι';

  @override
  String get microphonePermissionDenied => 'Απορρίφθηκε η άδεια μικροφώνου.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'πριν από $count λεπτά',
      one: 'πριν από 1 λεπτό',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Μοντέλο';

  @override
  String get modified => 'Τροποποιήθηκε';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'πριν από $count μήνες',
      one: 'πριν από 1 μήνα',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => 'Περισσότερα';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Όνομα';

  @override
  String get nameAndTitleRequired => 'Το όνομα και ο τίτλος είναι υποχρεωτικά.';

  @override
  String get nameAndUrlRequired => 'Απαιτούνται όνομα και URL';

  @override
  String get nameLabel => 'Όνομα';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Το εγγενές sandbox είναι διαθέσιμο στο $platform.';
  }

  @override
  String get nativeSandboxNeedsInstall =>
      'Απαιτείται εγκατάσταση εγγενούς sandbox';

  @override
  String get navObservability => 'Παρατηρησιμότητα';

  @override
  String get navSettings => 'Ρυθμίσεις';

  @override
  String networkBlockCount(int count) {
    return '$count αποκλεισμοί δικτύου';
  }

  @override
  String get neutral => 'Ουδέτερο';

  @override
  String get newCommitsPushed =>
      'Έγιναν push νέα commits — κάντε κλικ για επαναφόρτωση του diff';

  @override
  String get newFact => 'Νέο γεγονός';

  @override
  String get newPolicy => 'Νέα πολιτική';

  @override
  String get newsfeed => 'Ροή ειδήσεων';

  @override
  String get newsfeedLabel => 'Ροή ειδήσεων';

  @override
  String get newsfeedSettingsDescription =>
      'Διαχειριστείτε τις ροές στις οποίες είστε εγγεγραμμένοι και τις προτιμήσεις ανάγνωσης.';

  @override
  String get newsfeedSettingsTitle => 'Ρυθμίσεις ροής ειδήσεων';

  @override
  String get nextMatch => 'Επόμενη αντιστοιχία (↵)';

  @override
  String get noActiveWorkspace =>
      'Δεν έχει επιλεγεί ενεργός χώρος εργασίας ή αποθετήριο.';

  @override
  String get noActiveWorkspaceCreate => 'Δεν υπάρχει ενεργός χώρος εργασίας';

  @override
  String get noActiveWorkspaceGithub =>
      'Δεν υπάρχει ενεργός χώρος εργασίας με αποθετήριο GitHub.';

  @override
  String get noAgents => 'Κανένας πράκτορας';

  @override
  String get noArticlesYet => 'Δεν υπάρχουν ακόμη άρθρα';

  @override
  String get noArticlesYetBody =>
      'Τα άρθρα από τις ροές σας θα εμφανιστούν εδώ.';

  @override
  String get noExecutionLogsYet =>
      'Δεν υπάρχουν ακόμη αρχεία καταγραφής εκτέλεσης';

  @override
  String get noFacts => 'Δεν υπάρχουν ακόμη γεγονότα';

  @override
  String get noFeedsYet => 'Δεν υπάρχουν ακόμη ροές';

  @override
  String get noFileAnchor =>
      'Δεν υπάρχει άγκυρα αρχείου — δεν είναι δυνατή η δημοσίευση ενσωματωμένου σχολίου.';

  @override
  String get noFileChangesInScope =>
      'Δεν υπάρχουν αλλαγές αρχείων σε αυτό το πεδίο';

  @override
  String get noGifsFound => 'Δεν βρέθηκαν GIF';

  @override
  String get noInputDevicesDetected =>
      'Δεν ανιχνεύθηκαν συσκευές εισόδου — χρήση προεπιλογής συστήματος.';

  @override
  String get noMatchingFiles => 'Κανένα αντίστοιχο αρχείο';

  @override
  String get noMatchingGoogleFonts =>
      'Καμία αντίστοιχη γραμματοσειρά Google Fonts.';

  @override
  String get noMemoryData => 'Δεν υπάρχουν ακόμη δεδομένα μνήμης';

  @override
  String get noMessagesYet => 'Δεν υπάρχουν ακόμη μηνύματα';

  @override
  String get noModelsAdvertised =>
      'Αυτός ο προσαρμογέας δεν διαφημίζει μοντέλα.';

  @override
  String get noOpenPullRequests => 'Δεν υπάρχουν ανοιχτά pull requests';

  @override
  String get noPolicies => 'Δεν υπάρχουν ακόμη πολιτικές';

  @override
  String get noReposInWorkspaceYet =>
      'Δεν υπάρχουν ακόμη αποθετήρια σε αυτόν τον χώρο εργασίας';

  @override
  String get noRunnersDetected =>
      'Δεν ανιχνεύθηκαν ακόμη εκτελεστές. Ανανεώστε για νέα σάρωση.';

  @override
  String get noSavedArticles => 'Δεν υπάρχουν αποθηκευμένα άρθρα';

  @override
  String get noSavedArticlesBody =>
      'Τα άρθρα που αποθηκεύετε θα εμφανιστούν εδώ.';

  @override
  String noShortcutsMatch(String query) {
    return 'Καμία συντόμευση δεν ταιριάζει με «$query»';
  }

  @override
  String get noSystemFonts => 'Δεν ανιχνεύθηκαν γραμματοσειρές συστήματος.';

  @override
  String get noTokenSet =>
      'Δεν έχει οριστεί token — η πρόσβαση είναι απεριόριστη.';

  @override
  String get noWorkingMemory =>
      'Δεν υπάρχουν ακόμη σημειώσεις μνήμης εργασίας.';

  @override
  String get noneAllRoles => 'Κανένας (όλοι οι ρόλοι)';

  @override
  String get notAvailable => 'Μη διαθέσιμο';

  @override
  String get notConfiguredLabel => 'Δεν έχει ρυθμιστεί.';

  @override
  String get notFoundLabel => 'Δεν βρέθηκε';

  @override
  String get notes => 'Σημειώσεις';

  @override
  String get notificationAgentFinished => 'Ο πράκτορας ολοκλήρωσε';

  @override
  String get notificationPrMentioned => 'Αναφορά σε pull request';

  @override
  String get notificationNewMessages => 'Νέα μηνύματα';

  @override
  String get notificationPrMerged => 'Το PR συγχωνεύθηκε';

  @override
  String get notificationPrPublished => 'Το PR δημοσιεύτηκε';

  @override
  String get notificationReviewRequested => 'Ζητήθηκε ανασκόπηση';

  @override
  String get notifications => 'Ειδοποιήσεις';

  @override
  String get notifyAgentRunCompleted =>
      'Ειδοποίηση όταν ένας πράκτορας ολοκληρώνει μια εκτέλεση.';

  @override
  String get notifyPrMentioned =>
      'Ειδοποίηση όταν σας αναφέρουν σε pull request.';

  @override
  String get notifyNewMessages =>
      'Ειδοποίηση για νέα μηνύματα πρακτόρων σε άλλους χώρους.';

  @override
  String get notifyPrMerged => 'Ειδοποίηση όταν συγχωνεύεται ένα pull request.';

  @override
  String get notifyPrPublished =>
      'Ειδοποίηση όταν ένας πράκτορας δημοσιεύει pull request.';

  @override
  String get notifyReviewRequested =>
      'Ειδοποίηση όταν ζητείται η ανασκόπησή σας σε pull request.';

  @override
  String get notificationReviewStale => 'Η ανασκόπηση είναι παλιά';

  @override
  String get notifyReviewStale =>
      'Όταν νέα commits φτάνουν σε pull request που έχετε ήδη ανασκοπήσει';

  @override
  String get notificationPrMergeReadiness => 'Έτοιμο για συγχώνευση';

  @override
  String get notifyPrMergeReadiness =>
      'Ειδοποίηση όταν ένα pull request που συντάξατε γίνεται συγχωνεύσιμο ή παύει να είναι.';

  @override
  String get notificationPrReviewDecision => 'Αποφάσεις ανασκόπησης';

  @override
  String get notifyPrReviewDecision =>
      'Ειδοποίηση όταν ένας κριτής εγκρίνει, ζητά αλλαγές ή απορρίπτεται μια έγκριση.';

  @override
  String get notificationPrChecksStatus => 'Έλεγχοι';

  @override
  String get notifyPrChecksStatus =>
      'Ειδοποίηση όταν αποτυγχάνει το CI σε pull request που συντάξατε και όταν αποκαθίσταται.';

  @override
  String get notificationPrThreadActivity => 'Νήματα ανασκόπησης';

  @override
  String get notifyPrThreadActivity =>
      'Ειδοποίηση όταν κάποιος απαντά ή επιλύει ένα νήμα στο οποίο συμμετέχετε.';

  @override
  String get notificationPrReadyToMerge => 'Έτοιμο για συγχώνευση';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return 'Το $prTitle έχει ό,τι χρειάζεται.';
  }

  @override
  String get notificationPrMergeBlocked => 'Δεν είναι πλέον συγχωνεύσιμο';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return 'Το $prTitle έχει συγκρούσεις με τον βασικό κλάδο.';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return 'Το $prTitle υστερεί του βασικού κλάδου.';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return 'Το $prTitle περιμένει υποχρεωτική ανασκόπηση.';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'Ένας κριτής ζήτησε αλλαγές στο $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return 'Οι έλεγχοι αποτυγχάνουν στο $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return 'Το $prTitle δεν μπορεί πλέον να συγχωνευθεί.';
  }

  @override
  String get notificationPrApproved => 'Το pull request εγκρίθηκε';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return 'Ο/Η ⁨$login⁩ ενέκρινε το $prTitle';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return 'Το $prTitle εγκρίθηκε';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count κριτές ακόμη να απαντήσουν',
      one: '1 κριτής ακόμη να απαντήσει',
      zero: 'δεν απομένουν κριτές',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => 'Ζητήθηκαν αλλαγές';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return 'Ο/Η ⁨$login⁩ ζήτησε αλλαγές στο $prTitle';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return 'Ζητήθηκαν αλλαγές στο $prTitle';
  }

  @override
  String get notificationPrReviewDismissed => 'Η έγκριση απορρίφθηκε';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return 'Το $prTitle χρειάζεται ξανά ανασκόπηση.';
  }

  @override
  String get notificationPrChecksFailed => 'Οι έλεγχοι απέτυχαν';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return 'Το ⁨$checkName⁩ απέτυχε στο $prTitle';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return 'Οι έλεγχοι αποτυγχάνουν στο $prTitle';
  }

  @override
  String get notificationPrChecksRecovered => 'Οι έλεγχοι περνούν';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return 'Το $prTitle είναι ξανά πράσινο.';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return 'Ο/Η ⁨$login⁩ σας ανέφερε στο $location';
  }

  @override
  String get notificationPrThreadReplied => 'Νέα απάντηση';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return 'Ο/Η ⁨$login⁩ απάντησε στο $location';
  }

  @override
  String get notificationPrThreadResolved => 'Το νήμα επιλύθηκε';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return 'Το νήμα σας στο $location επιλύθηκε.';
  }

  @override
  String get notificationGroupAgents => 'Πράκτορες';

  @override
  String get notificationGroupPullRequests => 'Pull requests';

  @override
  String get notificationGroupMessages => 'Μηνύματα';

  @override
  String get notificationGroupTickets => 'Εισιτήρια';

  @override
  String get notificationGroupCalendar => 'Ημερολόγιο';

  @override
  String get notificationGroupMachines => 'Μηχανές';

  @override
  String get notificationsMutedRepos => 'Αποθετήρια σε σίγαση';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count αποθετήρια σε σίγαση',
      one: '1 αποθετήριο σε σίγαση',
      zero: 'Κανένα αποθετήριο σε σίγαση',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'Σίγαση αυτού του αποθετηρίου';

  @override
  String get onboardingLinuxDescription =>
      'Το Control Center μπορεί να χρησιμοποιεί κοντέινερ Linux για απομόνωση της εκτέλεσης πρακτόρων.';

  @override
  String get onboardingMacosDescription =>
      'Το Control Center χρησιμοποιεί εγγενές sandbox στο macOS για απομόνωση της εκτέλεσης πρακτόρων.';

  @override
  String get onboardingUnsupportedDescription =>
      'Το sandbox δεν είναι διαθέσιμο σε αυτή την πλατφόρμα. Η εκτέλεση πρακτόρων θα γίνει χωρίς απομόνωση.';

  @override
  String get openArticlesInApp => 'Άνοιγμα άρθρων στην εφαρμογή';

  @override
  String get openInBrowser => 'Άνοιγμα στο πρόγραμμα περιήγησης';

  @override
  String get openedInYourBrowser => 'Άνοιξε στο πρόγραμμα περιήγησης.';

  @override
  String get openLabel => 'Άνοιγμα';

  @override
  String get openOnGithub => 'Άνοιγμα στο GitHub';

  @override
  String get openStatus => 'Ανοιχτό';

  @override
  String get optionalPersonaDescription => 'Προαιρετική περιγραφή περσόνας';

  @override
  String get otherLabel => 'Άλλο';

  @override
  String get ownerOrganization => 'Ιδιοκτήτης / οργανισμός';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => 'Πέρασε';

  @override
  String get pasteValueHere => 'Επικολλήστε την τιμή εδώ';

  @override
  String get persona => 'Περσόνα';

  @override
  String get policies => 'Πολιτικές';

  @override
  String get policiesHint =>
      'Οι πολιτικές θα εμφανιστούν εδώ όταν οι πράκτορες προάγουν γεγονότα.';

  @override
  String get policy => 'Πολιτική';

  @override
  String get popular => 'Δημοφιλή';

  @override
  String get port => 'Θύρα';

  @override
  String get postingEllipsis => 'Δημοσίευση…';

  @override
  String get prCommits => 'Commits';

  @override
  String get prMergedBody => 'Ένα pull request συγχωνεύθηκε';

  @override
  String get prMoreActions => 'Περισσότερες ενέργειες';

  @override
  String get prTitle => 'Τίτλος PR';

  @override
  String get reviewCommentHint =>
      'Απλώς πατήστε έγκριση ή, αν το κάνετε πικάντικο, προσθέστε σχόλιο ή αντίδραση…';

  @override
  String get nothingToPreview => 'Δεν υπάρχει τίποτα για προεπισκόπηση';

  @override
  String get previousMatch => 'Προηγούμενη αντιστοιχία (⇧↵)';

  @override
  String get priorityReviewsDescription =>
      'Ανασκοπήσεις προτεραιότητας και επισκόπηση αποθετηρίου.';

  @override
  String get prsCreated => 'PR που δημιουργήθηκαν';

  @override
  String get prsMerged => 'PR που συγχωνεύθηκαν';

  @override
  String get publishToGithub => 'Δημοσίευση στο GitHub';

  @override
  String get published => 'Δημοσιεύτηκε';

  @override
  String get pullRequestApproved => 'Το pull request εγκρίθηκε';

  @override
  String get pullRequests => 'Pull requests';

  @override
  String get questionLabel => 'ΕΡΩΤΗΣΗ';

  @override
  String get queued => 'Σε ουρά';

  @override
  String get react => 'Αντίδραση';

  @override
  String get readPrsIssuesMetadata =>
      'Επιτρέπει στον πράκτορα να διαβάζει PR, issues και μεταδεδομένα αποθετηρίου.';

  @override
  String get readerPreferences => 'Προτιμήσεις ανάγνωσης';

  @override
  String get reasoningEffort => 'Προσπάθεια συλλογισμού';

  @override
  String get recommendLabel => 'ΠΡΟΤΑΣΗ';

  @override
  String recordingFromDevice(String device) {
    return 'Εγγραφή από $device.';
  }

  @override
  String get redownload => 'Επανάληψη λήψης';

  @override
  String get redownloadEmbeddingModel =>
      'Επανάληψη λήψης του μοντέλου ενσωμάτωσης;';

  @override
  String get redownloadVoiceModel => 'Επανάληψη λήψης του μοντέλου φωνής;';

  @override
  String get refinePlan => 'Βελτίωση σχεδίου';

  @override
  String get refresh => 'Ανανέωση';

  @override
  String get refreshAll => 'Ανανέωση όλων';

  @override
  String get refreshAllFeeds => 'Ανανέωση όλων των ροών';

  @override
  String get reject => 'Απόρριψη';

  @override
  String get rejected => 'Απορρίφθηκε';

  @override
  String get reload => 'Επαναφόρτωση';

  @override
  String get remove => 'Αφαίρεση';

  @override
  String get removeBookmark => 'Αφαίρεση σελιδοδείκτη';

  @override
  String get removeEmbeddingModel => 'Αφαίρεση του μοντέλου ενσωμάτωσης;';

  @override
  String get removeLogo => 'Αφαίρεση λογότυπου';

  @override
  String get removeRepoFromWorkspace =>
      'Αφαίρεση αποθετηρίου από τον χώρο εργασίας;';

  @override
  String get removeVoiceModel => 'Αφαίρεση του μοντέλου φωνής;';

  @override
  String get removed => 'Αφαιρέθηκε';

  @override
  String get renamed => 'Μετονομάστηκε';

  @override
  String get reopen => 'Επανάνοιγμα';

  @override
  String get resolve => 'Επίλυση';

  @override
  String get replyEllipsis => 'Απάντηση…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return 'Το ⁨$name⁩ θα αφαιρεθεί από αυτόν τον χώρο εργασίας. Τα τοπικά αρχεία στον δίσκο δεν επηρεάζονται.';
  }

  @override
  String repoAccessNoticeBody(String repos) {
    return 'Τα διαπιστευτήρια GitHub του διακομιστή δεν βλέπουν τα ⁨$repos⁩. Αν ένα αποθετήριο ανήκει σε οργανισμό, εγκαταστήστε εκεί το GitHub App ή συνδέστε token με πρόσβαση.';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count αποθετήρια δεν είναι προσβάσιμα',
      one: 'Ένα αποθετήριο δεν είναι προσβάσιμο',
    );
    return '$_temp0';
  }

  @override
  String get repoAccessNoticeSuspendedTitle =>
      'Η εγκατάσταση του GitHub App έχει ανασταλεί';

  @override
  String repoAccessNoticeSuspendedBody(String repos) {
    return 'Εμφανίζονται τα τελευταία γνωστά δεδομένα για τα ⁨$repos⁩. Συνεχίστε την εγκατάσταση στο GitHub ή συνδέστε token με πρόσβαση.';
  }

  @override
  String get repoNoAccessBadge => 'Χωρίς πρόσβαση';

  @override
  String get reportsTo => 'Αναφέρεται σε';

  @override
  String reposCount(int count) {
    return 'Αποθετήρια ($count)';
  }

  @override
  String get reposDescription =>
      'Τα τοπικά checkouts που στοχεύει αυτός ο χώρος εργασίας.';

  @override
  String get repositories => 'Αποθετήρια';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count αποθετηρίων',
      one: '1 αποθετηρίου',
    );
    return 'Δεν ήταν δυνατή η προσθήκη $_temp0: ⁨$error⁩';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count αποθετήρια προστέθηκαν',
      one: 'Το αποθετήριο προστέθηκε',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'Ρυθμίσεις αποθετηρίων';

  @override
  String get repositoryName => 'Όνομα αποθετηρίου';

  @override
  String get requestChanges => 'Αίτημα αλλαγών';

  @override
  String get requested => 'Ζητήθηκε';

  @override
  String get requestedChanges => 'Ζητήθηκαν αλλαγές';

  @override
  String requiredRoleLabel(String role) {
    return 'Απαιτούμενος ρόλος: $role';
  }

  @override
  String get requiredRoleOptional => 'Απαιτούμενος ρόλος (προαιρετικά)';

  @override
  String get requirements => 'Απαιτήσεις';

  @override
  String get reset => 'Επαναφορά';

  @override
  String get resolved => 'Επιλύθηκε';

  @override
  String get enclosedTerminalTitle => 'Απομονωμένο τερματικό';

  @override
  String get enclosedTerminalStart => 'Άνοιγμα του κελύφους';

  @override
  String get enclosedTerminalStartHint =>
      'Αυτό το κέλυφος εκτελείται μέσα στο προσωρινό VM αυτής της συνομιλίας. Εκκινεί όταν το ανοίγετε, όχι όταν ξεκινά η εφαρμογή.';

  @override
  String get terminalStreamReconnecting => 'η ροή διακόπηκε — επανασύνδεση…';

  @override
  String get terminalStreamError => 'σφάλμα ροής:';

  @override
  String get terminalShellExited => 'το κέλυφος τερματίστηκε';

  @override
  String get restartShell => 'Επανεκκίνηση κελύφους';

  @override
  String get retry => 'Επανάληψη';

  @override
  String get review => 'Ανασκόπηση';

  @override
  String get reviewedByMe => 'Ανασκοπήθηκαν από εμένα';

  @override
  String get reviewers => 'Κριτές';

  @override
  String get roleLabel => 'Ρόλος';

  @override
  String get ruleHint => 'Ο κανόνας πολιτικής (υποστηρίζεται markdown)';

  @override
  String get ruleLabel => 'Κανόνας';

  @override
  String get runCompleted => 'Η εκτέλεση ολοκληρώθηκε';

  @override
  String get running => 'Σε εκτέλεση';

  @override
  String get runningLabel => 'σε εκτέλεση';

  @override
  String get runs => 'Εκτελέσεις';

  @override
  String get runsLabel => 'Εκτελέσεις';

  @override
  String get sandboxBackendNativeLabel => 'Εγγενές sandbox';

  @override
  String get sandboxBackendMicrovmLabel => 'Απομονωμένο VM';

  @override
  String get sandboxBackendNoneLabel => 'Χωρίς απομόνωση';

  @override
  String get sandboxLinuxInstall =>
      'Το εγγενές sandbox σε Linux/WSL2 χρησιμοποιεί bubblewrap. Εγκατάσταση με:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'Το εγγενές sandbox είναι ενσωματωμένο στο macOS — χρησιμοποιεί Apple Seatbelt (`sandbox-exec`). Δεν απαιτείται εγκατάσταση.';

  @override
  String get sandboxPermissions => 'Δικαιώματα sandbox';

  @override
  String get sandboxUnsupported =>
      'Το εγγενές sandbox δεν υποστηρίζεται ακόμη σε αυτή την πλατφόρμα. Επιστρέφει σε «Χωρίς απομόνωση».';

  @override
  String get sandboxingDisabledDescription =>
      'Οι πράκτορες εκτελούνται απευθείας στον κεντρικό με πλήρες περιβάλλον — δεν συνιστάται.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Όλες οι κλήσεις πρακτόρων περνούν από $backend.';
  }

  @override
  String get save => 'Αποθήκευση';

  @override
  String get saveChanges => 'Αποθήκευση αλλαγών';

  @override
  String get adapterArguments => 'Επιπλέον ορίσματα';

  @override
  String get adapterArgumentsHint => 'Επιπλέον σημαίες CLI (π.χ. --yolo)';

  @override
  String get addVariable => 'Προσθήκη μεταβλητής';

  @override
  String get environmentVariables => 'Μεταβλητές περιβάλλοντος';

  @override
  String get environmentVariablesDescription =>
      'Προσαρμοσμένες μεταβλητές περιβάλλοντος που περνούν σε αυτόν τον προσαρμογέα (π.χ. κλειδιά API). Αποθηκεύονται στο keychain.';

  @override
  String get variableKey => 'Κλειδί';

  @override
  String get variableValue => 'Τιμή';

  @override
  String get savingEllipsis => 'Αποθήκευση…';

  @override
  String get scopeDiffToCommits =>
      'Περιορισμός diff σε commits — Shift-κλικ για εύρος';

  @override
  String get noPrsMatchSearch => 'Κανένα αντίστοιχο pull request';

  @override
  String get searchFactsHint => 'Αναζήτηση γεγονότων...';

  @override
  String get searchFonts => 'Αναζήτηση γραμματοσειρών…';

  @override
  String get searchGifs => 'Αναζήτηση GIF';

  @override
  String get searchGifsHint => 'Αναζήτηση GIF...';

  @override
  String get searchInDiffHint => 'Αναζήτηση στο diff…';

  @override
  String get searchOrTypeModel =>
      'Αναζήτηση ή πληκτρολόγηση ονόματος μοντέλου…';

  @override
  String get searchPlaceholder => 'Αναζήτηση…';

  @override
  String get searchShortcuts => 'Αναζήτηση συντομεύσεων…';

  @override
  String get shortcutUnavailableInBrowser =>
      'Μη διαθέσιμο στο πρόγραμμα περιήγησης';

  @override
  String get searching => 'Αναζήτηση…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'πριν από $count δευτερόλεπτα',
      one: 'πριν από 1 δευτερόλεπτο',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Επιλογή προσαρμογέα';

  @override
  String get selectAdapterFirst => 'Επιλέξτε πρώτα προσαρμογέα';

  @override
  String get selectAgentToReportTo =>
      'Επιλέξτε πράκτορα στον οποίο αναφέρεται…';

  @override
  String get selectAnAgent => 'Επιλέξτε πράκτορα';

  @override
  String get selectConversation => 'Επιλέξτε συνομιλία';

  @override
  String get selectLabel => 'Επιλογή';

  @override
  String get selectRunner => 'Επιλέξτε εκτελεστή';

  @override
  String get semanticSearch => 'Σημασιολογική αναζήτηση';

  @override
  String get send => 'Αποστολή';

  @override
  String get sendFirstMessage => 'Αποστολή του πρώτου μηνύματος';

  @override
  String get sendMessage => 'Αποστολή μηνύματος';

  @override
  String sentFindingsToAgent(int count) {
    return 'Στάλθηκαν $count εύρημα(-τα) στον πράκτορα.';
  }

  @override
  String setGithubLinkDescription(String name) {
    return 'Ορίστε τον ιδιοκτήτη GitHub και το όνομα αποθετηρίου για το $name. Χρησιμοποιείται για την επίλυση αναφορών PR και issue όπως #123 στο περιεχόμενο markdown.';
  }

  @override
  String get setLabel => 'Ορισμός';

  @override
  String get setToken => 'Ορισμός token';

  @override
  String get settingsLabel => 'Ρυθμίσεις';

  @override
  String get settingsLanguage => 'Γλώσσα';

  @override
  String get settingsLanguageDescription => 'Επιλέξτε τη γλώσσα της εφαρμογής.';

  @override
  String get shortTask => 'Σύντομη εργασία';

  @override
  String get showNativeNotifications =>
      'Εμφάνιση ειδοποιήσεων συστήματος για γεγονότα.';

  @override
  String get showSuperseded => 'Εμφάνιση αντικατασταθέντων';

  @override
  String get signedIn => 'Συνδεθήκατε.';

  @override
  String signedInAs(String username) {
    return 'Συνδεθήκατε ως ⁨$username⁩.';
  }

  @override
  String get skillNameRequired => 'Το όνομα δεξιότητας είναι υποχρεωτικό.';

  @override
  String skillSaved(String name) {
    return 'Η δεξιότητα «$name» αποθηκεύτηκε.';
  }

  @override
  String get skillsSourcesTab => 'Πηγές';

  @override
  String get skillSourcesDisclaimer =>
      'Οι δεξιότητες εγκαθίστανται από αποθετήρια GitHub που προσθέτετε. Τα μεταδεδομένα αποθετηρίου δεν είναι αξιόπιστα — η σάρωση antivirus είναι το πραγματικό σήμα ασφάλειας.';

  @override
  String get skillSourcesEmpty => 'Δεν υπάρχουν αποθετήρια δεξιοτήτων';

  @override
  String get skillSourcesEmptyHint =>
      'Προσθέστε αποθετήριο GitHub για να περιηγηθείτε στις δεξιότητές του.';

  @override
  String get skillSourceAdd => 'Προσθήκη αποθετηρίου';

  @override
  String get skillSourceAddTitle => 'Προσθήκη αποθετηρίου δεξιοτήτων';

  @override
  String get skillSourceAddHint => 'https://github.com/owner/repo';

  @override
  String get skillSourceInvalidUrl =>
      'Εισαγάγετε URL αποθετηρίου GitHub (⁨https://github.com/owner/repo⁩).';

  @override
  String skillSourceAdded(String repo) {
    return 'Το αποθετήριο ⁨$repo⁩ προστέθηκε.';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'Το αποθετήριο ⁨$repo⁩ έχει ήδη προστεθεί.';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'Το αποθετήριο ⁨$repo⁩ αφαιρέθηκε.';
  }

  @override
  String get skillSourceRemove => 'Αφαίρεση';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return 'Αφαίρεση του ⁨$repo⁩;';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'Οι εγκατεστημένες δεξιότητες παραμένουν. Αφαιρείται μόνο ο κατάλογος του αποθετηρίου.';

  @override
  String get skillSourceNoSkills =>
      'Δεν βρέθηκαν δεξιότητες σε αυτό το αποθετήριο (δεξιότητα είναι ένας φάκελος που περιέχει SKILL.md).';

  @override
  String get skillSourceRefresh => 'Ανανέωση';

  @override
  String get skillSourceInstalledBadge => 'Εγκατεστημένη';

  @override
  String get skillSourceUpdateBadge => 'Διαθέσιμη ενημέρωση';

  @override
  String get skillSourceSlugTaken => 'Το όνομα χρησιμοποιείται';

  @override
  String skillSourceFilesCount(num count) {
    return '$count αρχεία';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'Αυτή η δεξιότητα δεν έχει README.';

  @override
  String get skillSourceNoMatches =>
      'Καμία δεξιότητα δεν ταιριάζει με το φίλτρο.';

  @override
  String get skillUpdateAction => 'Ενημέρωση';

  @override
  String get skillUninstallAction => 'Απεγκατάσταση';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return 'Απεγκατάσταση της «⁨$slug⁩»;';
  }

  @override
  String skillUninstalled(String slug) {
    return 'Η δεξιότητα «⁨$slug⁩» απεγκαταστάθηκε.';
  }

  @override
  String get skillFindingLine => 'γραμμή';

  @override
  String get skillInstallAnywayOverride =>
      'Κατανοώ τον κίνδυνο — εγκατάσταση ούτως ή άλλως';

  @override
  String skillInstalled(String slug) {
    return 'Η δεξιότητα «⁨$slug⁩» εγκαταστάθηκε.';
  }

  @override
  String get skillPreviewCapabilities => 'Δυνατότητες';

  @override
  String get skillPreviewFindings => 'Ευρήματα';

  @override
  String get skillPreviewGuardedActions => 'Φυλασσόμενες ενέργειες';

  @override
  String get skillPreviewLlmReviewed => 'Ανασκοπήθηκε από LLM';

  @override
  String get skillPreviewNoCapabilities => 'Δεν δηλώθηκαν δυνατότητες.';

  @override
  String get skillPreviewNoFindings => 'Κανένα εύρημα.';

  @override
  String get skillPreviewScanning => 'Σάρωση δεξιότητας…';

  @override
  String get skillPreviewVerdictLabel => 'Απόφαση σάρωσης';

  @override
  String get skillPreviewVerdictPass => 'Πέρασε';

  @override
  String get skillPreviewVerdictQuarantine => 'Σε καραντίνα';

  @override
  String get skillPreviewVerdictWarn => 'Προειδοποίηση';

  @override
  String get skillQuarantineWarning =>
      'Αυτή η δεξιότητα τέθηκε σε καραντίνα από τον σαρωτή. Η εγκατάστασή της εκτελεί κώδικα στο μηχάνημά σας. Συνεχίστε μόνο αν εμπιστεύεστε την πηγή και έχετε εξετάσει τα ευρήματα.';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'Σε καραντίνα και αποσυνδέθηκε από πράκτορες: $agents';
  }

  @override
  String get skillNotScanned => 'Δεν σαρώθηκε';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'Χειροκίνητα';

  @override
  String get skillOriginRegistry => 'Registry';

  @override
  String get skillOriginRuntimeLocal => 'Τοπικό περιβάλλον εκτέλεσης';

  @override
  String get skillRulesStale => 'Η σάρωση είναι παλιά';

  @override
  String get skillSaveAnywayOverride =>
      'Κατανοώ τον κίνδυνο — αποθήκευση ούτως ή άλλως';

  @override
  String get skillSaveBlockedBody =>
      'Το περιεχόμενο αποκλείστηκε πριν γραφτεί οτιδήποτε.';

  @override
  String get skillSaveBlockedTitle =>
      'Η αποθήκευση αποκλείστηκε από την πύλη σάρωσης';

  @override
  String get skillScanAction => 'Σάρωση';

  @override
  String get skillScanAll => 'Σάρωση όλων';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass πέρασαν · $warn προειδοποιήσεις · $quarantine σε καραντίνα';
  }

  @override
  String get skillStateDrifted => 'Τροποποιήθηκε μετά την εγκατάσταση';

  @override
  String get skillStateUnmanaged => 'Χωρίς διαχείριση';

  @override
  String get skillSeverityBlocked => 'Αποκλείστηκε';

  @override
  String get skillSeverityWarn => 'Προειδοποίηση';

  @override
  String get skillsInstalledTab => 'Εγκατεστημένες';

  @override
  String get skills => 'Δεξιότητες';

  @override
  String get skipAcceptRisk => 'Παράλειψη — αποδέχομαι τον κίνδυνο';

  @override
  String get skipForNow => 'Παράλειψη προς το παρόν';

  @override
  String get skipSandboxing => 'Παράλειψη sandbox';

  @override
  String get skipSandboxingDialogContent =>
      'Θέλετε σίγουρα να παραλείψετε το sandbox; Αυτό επιτρέπει στους πράκτορες να εκτελούν κώδικα στο σύστημά σας χωρίς απομόνωση.';

  @override
  String get somethingWentWrong => 'Κάτι πήγε στραβά';

  @override
  String sourceCount(int count) {
    return '$count πηγή';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count πηγές';
  }

  @override
  String get sourceFacts => 'Γεγονότα προέλευσης:';

  @override
  String get splitDiff => 'Διαχωρισμένο (δίπλα-δίπλα) diff';

  @override
  String get startLabel => 'Έναρξη';

  @override
  String get startOnAppLaunch => 'Έναρξη με την εκκίνηση της εφαρμογής';

  @override
  String get statusLabel => 'Κατάσταση';

  @override
  String get onboardingStepConnect => 'Σύνδεση';

  @override
  String get onboardingStepWorkspace => 'Χώρος εργασίας';

  @override
  String get onboardingStepSandbox => 'Sandbox';

  @override
  String get onboardingStepAdapter => 'Προσαρμογέας';

  @override
  String get onboardingStepVoice => 'Φωνή';

  @override
  String get stop => 'Διακοπή';

  @override
  String get stopped => 'Διακόπηκε';

  @override
  String get strictIdentityCheck => 'Αυστηρός έλεγχος ταυτότητας';

  @override
  String get success => 'Επιτυχία';

  @override
  String get successLabel => 'Επιτυχία';

  @override
  String get suggestAChange => 'Πρόταση αλλαγής';

  @override
  String get suggestion => 'Πρόταση';

  @override
  String get suggestLabel => 'ΠΡΟΤΑΣΗ';

  @override
  String get superseded => 'Αντικαταστάθηκε';

  @override
  String get synced => 'Συγχρονίστηκε';

  @override
  String get systemDefault => 'Προεπιλογή συστήματος';

  @override
  String get systemFonts => 'Γραμματοσειρές συστήματος';

  @override
  String get systemPrompt => 'Προτροπή συστήματος';

  @override
  String get systemPromptLabel => 'Προτροπή συστήματος';

  @override
  String get talkToControlCenter => 'Μιλήστε στο Control Center.';

  @override
  String get taskMentionSection => 'Εργασία';

  @override
  String get testLabel => 'Δοκιμή';

  @override
  String get theme => 'Θέμα';

  @override
  String get themeDark => 'Σκοτεινό';

  @override
  String get themeLight => 'Φωτεινό';

  @override
  String get themeSystem => 'Σύστημα';

  @override
  String get thisCannotBeUndone => 'Αυτή η ενέργεια δεν αναιρείται.';

  @override
  String get ticketLabel => 'ΕΙΣΙΤΗΡΙΟ';

  @override
  String get titleLabel => 'Τίτλος';

  @override
  String get todayLabel => 'Σήμερα';

  @override
  String get toggleTheme => 'Εναλλαγή θέματος';

  @override
  String get tokenConfigured =>
      'Ρυθμίστηκε — οι πελάτες πρέπει να παρουσιάζουν αυτό το token.';

  @override
  String get topic => 'Θέμα';

  @override
  String get topicHint => 'π.χ. Tech Stack, Design System';

  @override
  String get totalRuns => 'Συνολικές εκτελέσεις';

  @override
  String trackingParamsCount(int count) {
    return '$count παράμετροι παρακολούθησης';
  }

  @override
  String get typeCommandOrSearch => 'Πληκτρολογήστε εντολή ή αναζήτηση…';

  @override
  String get typography => 'Τυπογραφία';

  @override
  String get unavailable => 'Μη διαθέσιμο';

  @override
  String get unifiedDiff => 'Ενοποιημένο diff';

  @override
  String get unknownAuthor => 'Άγνωστος';

  @override
  String get unnamedAgent => 'Ανώνυμος πράκτορας';

  @override
  String get updateKey => 'Ενημέρωση κλειδιού';

  @override
  String get updateLabel => 'Ενημέρωση';

  @override
  String get updateToken => 'Ενημέρωση token';

  @override
  String updatedDaysAgo(int count) {
    return 'Ενημερώθηκε πριν από $countη';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'Ενημερώθηκε πριν από $countώ';
  }

  @override
  String get updatedJustNow => 'Ενημερώθηκε μόλις τώρα';

  @override
  String updatedMinutesAgo(int count) {
    return 'Ενημερώθηκε πριν από $countλ';
  }

  @override
  String get useSandbox => 'Χρήση sandbox';

  @override
  String get useWorkspaceDefault => 'Χρήση προεπιλογής χώρου εργασίας';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'Αφήστε κενό για το προεπιλεγμένο User-Agent της εφαρμογής. Ορισμένοι ιστότοποι αποκλείουν User-Agent που δεν είναι προγράμματα περιήγησης.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Χρήση του προεπιλεγμένου μικροφώνου του συστήματος.';

  @override
  String get viewLabel => 'Προβολή';

  @override
  String get viewLogs => 'Προβολή αρχείων καταγραφής';

  @override
  String voiceInstallFailed(String error) {
    return 'Η εγκατάσταση απέτυχε: ⁨$error⁩';
  }

  @override
  String get voiceModelNotInstalled =>
      'Δεν είναι εγκατεστημένο. Λήψη ~200 MB μία φορά· εκτελείται πλήρως στη συσκευή.';

  @override
  String get voiceModelNotInstalledLabel =>
      'Το μοντέλο φωνής δεν είναι εγκατεστημένο.';

  @override
  String get voiceRedownloadBody =>
      'Τα υπάρχοντα αρχεία μοντέλου θα διαγραφούν και το αρχείο ~200 MB θα ληφθεί ξανά. Η μεταγραφή φωνής δεν θα είναι διαθέσιμη μέχρι να ολοκληρωθεί η λήψη.';

  @override
  String get voiceRemoveBody =>
      'Η μεταγραφή φωνής θα απενεργοποιηθεί μέχρι να το επανεγκαταστήσετε. Μπορείτε να το εγκαταστήσετε ξανά οποτεδήποτε.';

  @override
  String get voiceTranscription => 'Μεταγραφή φωνής';

  @override
  String get weakIsolationDescription =>
      'Ασθενής απομόνωση — μόνο όριο χώρου ονομάτων, χωρίς όριο πυρήνα.';

  @override
  String get whenOffNoDefaultRoute =>
      'Όταν είναι απενεργοποιημένο, το sandbox εκκινεί χωρίς προεπιλεγμένη διαδρομή.';

  @override
  String get whenOffServerStaysStopped =>
      'Όταν είναι απενεργοποιημένο, ο διακομιστής μένει σταματημένος μέχρι να τον ξεκινήσετε.';

  @override
  String get speechModel => 'Μοντέλο ομιλίας';

  @override
  String get speechModelHint =>
      'Χρησιμοποιείται για μεταγραφή συσκέψεων και το μικρόφωνο του συνθέτη.';

  @override
  String get voiceModelInstalled =>
      'Εγκατεστημένο. Τροφοδοτεί τη μεταγραφή συσκέψεων και το κουμπί μικροφώνου του συνθέτη.';

  @override
  String get meetingMicSilentWarning =>
      'Το μικρόφωνό σας μπορεί να είναι σε σίγαση — οι άλλοι μιλούν αλλά τίποτα δεν φτάνει στο μικρόφωνό σας.';

  @override
  String get meetingSummaryPrivacyNotice =>
      'Η εγγραφή και η μεταγραφή μένουν σε αυτό το μηχάνημα. Η σύνοψη γράφεται από πράκτορα, οπότε αν χρησιμοποιεί μοντέλο cloud το πρακτικό και οι σημειώσεις σας αποστέλλονται σε εκείνον τον πάροχο.';

  @override
  String get meetingTemplates => 'Πρότυπα σημειώσεων σύσκεψης';

  @override
  String get meetingTemplatesHint =>
      'Διαμορφώστε τη σύνοψη AI για ένα είδος σύσκεψης. Το ενεργό πρότυπο ισχύει για νέες και επανεκτελεσμένες συνόψεις.';

  @override
  String get meetingTemplateActive => 'Ενεργό πρότυπο';

  @override
  String get meetingTemplateAdd => 'Προσθήκη προτύπου';

  @override
  String get meetingTemplateNewTitle => 'Νέο πρότυπο';

  @override
  String get meetingTemplateEditTitle => 'Επεξεργασία προτύπου';

  @override
  String get meetingTemplateNameLabel => 'Όνομα';

  @override
  String get meetingTemplateNameHint => 'π.χ. ανασκόπηση sprint';

  @override
  String get meetingTemplateInstructionsLabel => 'Οδηγίες';

  @override
  String get meetingTemplateInstructionsHint =>
      'Πώς πρέπει η AI να δομεί και να τονίζει αυτές τις σημειώσεις;';

  @override
  String get workingMemory => 'Μνήμη εργασίας';

  @override
  String get workspaceName => 'Όνομα χώρου εργασίας';

  @override
  String get workspaceScopedSkills =>
      'Αρχεία δεξιοτήτων με εύρος χώρου εργασίας συνδεδεμένα σε πράκτορες.';

  @override
  String get workspaces => 'Χώροι εργασίας';

  @override
  String get writePrivateNotes =>
      'Γράψτε ιδιωτικές σημειώσεις, παρατηρήσεις, σχέδια...';

  @override
  String get writeSkillContent =>
      'Γράψτε το περιεχόμενο της δεξιότητας εδώ (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'πριν από $count έτη',
      one: 'πριν από 1 έτος',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Χθες';

  @override
  String get focusModeStart => 'Έναρξη συνεδρίας εστίασης';

  @override
  String get focusModeConfigTitle => 'Έναρξη συνεδρίας εστίασης';

  @override
  String get focusModeGoalLabel => 'Στόχος';

  @override
  String get focusModeGoalHint => 'Σε τι εργάζεστε;';

  @override
  String get focusModeDurationLabel => 'Διάρκεια';

  @override
  String get focusModeBlockNotifications => 'Αποκλεισμός ειδοποιήσεων';

  @override
  String get focusModeStartButton => 'Έναρξη';

  @override
  String get focusModeFloat => 'Ελαχιστοποίηση στη γραμμή';

  @override
  String get focusModeActiveTooltip =>
      'Η λειτουργία εστίασης είναι ενεργή — πατήστε για τερματισμό';

  @override
  String get dismiss => 'Απόρριψη';

  @override
  String get acceptAndResolve => 'Αποδοχή και επίλυση';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'Ανασκοπείτε για $minutesλ — η έρευνα δείχνει ότι η ποιότητα ανασκόπησης μπορεί να πέσει μετά από 60 λεπτά. Σκεφτείτε ένα διάλειμμα.';
  }

  @override
  String get notificationSound => 'Ήχος ειδοποίησης';

  @override
  String get notificationSoundDescription =>
      'Ήχος που παίζει όταν εμφανίζεται ειδοποίηση.';

  @override
  String get notificationSoundNone => 'Κανένας';

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
  String get notificationSoundMigrosSoft => 'Migros (απαλό)';

  @override
  String get notificationSoundMigrosHard => 'Migros (έντονο)';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => 'Δοκιμή';

  @override
  String get notificationVolume => 'Ένταση';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Κανένα PR από τον/την ⁨@$login⁩ σε αυτόν τον χώρο εργασίας';
  }

  @override
  String get usersLabel => 'Χρήστες';

  @override
  String get mergePullRequest => 'Συγχώνευση pull request';

  @override
  String get forceMergePullRequest => 'Αναγκαστική συγχώνευση pull request';

  @override
  String get closePullRequest => 'Κλείσιμο pull request';

  @override
  String get closePullRequestConfirm =>
      'Θέλετε σίγουρα να κλείσετε αυτό το pull request;';

  @override
  String get stackedPullRequests => 'Στοιβαγμένα pull requests';

  @override
  String partOfStack(int position, int total) {
    return 'Μέρος στοίβας ($position από $total)';
  }

  @override
  String get createStack => 'Δημιουργία στοίβας';

  @override
  String get createStackDialogTitle => 'Δημιουργία στοίβας pull request';

  @override
  String createStackDialogBody(int count) {
    return 'Αυτά τα $count pull requests θα στοιβαχτούν, από κάτω προς τα πάνω:';
  }

  @override
  String get createStackInvalidSelection =>
      'Επιλέξτε τουλάχιστον δύο pull requests από το ίδιο αποθετήριο για να δημιουργήσετε στοίβα';

  @override
  String get createStackNotAChain =>
      'Τα επιλεγμένα pull requests δεν σχηματίζουν αλυσίδα: ο βασικός κλάδος κάθε pull request πρέπει να είναι ο κλάδος head του προηγούμενου';

  @override
  String get createStackAlreadyStacked =>
      'Ένα ή περισσότερα επιλεγμένα pull requests ανήκουν ήδη σε στοίβα';

  @override
  String get stackCreated => 'Η στοίβα δημιουργήθηκε';

  @override
  String get stackCreationFailed => 'Δεν ήταν δυνατή η δημιουργία της στοίβας';

  @override
  String get squashAndMerge => 'Squash και συγχώνευση';

  @override
  String get createMergeCommit => 'Δημιουργία commit συγχώνευσης';

  @override
  String get rebaseAndMerge => 'Rebase και συγχώνευση';

  @override
  String get mergeMethod => 'Μέθοδος συγχώνευσης';

  @override
  String get commitTitle => 'Τίτλος commit';

  @override
  String get commitDescription => 'Περιγραφή commit';

  @override
  String get pullRequestMerged => 'Το pull request συγχωνεύθηκε';

  @override
  String get pullRequestClosed => 'Το pull request έκλεισε';

  @override
  String failedToMergePr(String error) {
    return 'Αποτυχία συγχώνευσης: ⁨$error⁩';
  }

  @override
  String failedToClosePr(String error) {
    return 'Αποτυχία κλεισίματος: ⁨$error⁩';
  }

  @override
  String get markReadyForReview => 'Έτοιμο για ανασκόπηση';

  @override
  String get markReadyForReviewConfirm =>
      'Αυτό το pull request θα βγει από το πρόχειρο. Οι κριτές ειδοποιούνται, οι υποχρεωτικοί έλεγχοι αρχίζουν να δεσμεύουν τη συγχώνευση και οποιαδήποτε αυτοματοποίηση που περιμένει έτοιμα pull requests εκτελείται.';

  @override
  String get convertToDraft => 'Μετατροπή σε πρόχειρο';

  @override
  String get convertToDraftConfirm =>
      'Αυτό το pull request θα επιστρέψει σε πρόχειρο. Τα εκκρεμή αιτήματα ανασκόπησης απορρίπτονται και δεν μπορεί να συγχωνευθεί μέχρι να το σημειώσετε ξανά ως έτοιμο.';

  @override
  String get pullRequestMarkedReady =>
      'Το pull request σημειώθηκε ως έτοιμο για ανασκόπηση';

  @override
  String get pullRequestConvertedToDraft =>
      'Το pull request μετατράπηκε σε πρόχειρο';

  @override
  String failedToMarkPrReady(String error) {
    return 'Αποτυχία σήμανσης ως έτοιμου για ανασκόπηση: ⁨$error⁩';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'Αποτυχία μετατροπής σε πρόχειρο: ⁨$error⁩';
  }

  @override
  String get checksFailing => 'Οι έλεγχοι αποτυγχάνουν';

  @override
  String get reviewsPending => 'Ορισμένες ανασκοπήσεις εκκρεμούν';

  @override
  String get mergeConflictsWithBase =>
      'Αυτός ο κλάδος έχει συγκρούσεις που πρέπει να επιλυθούν';

  @override
  String get branchOutOfDateWithBase =>
      'Αυτός ο κλάδος είναι παλιός σε σχέση με τον βασικό κλάδο';

  @override
  String get mergeBlockedByBranchProtection =>
      'Η προστασία κλάδου αποκλείει αυτή τη συγχώνευση';

  @override
  String get confirm => 'Επιβεβαίωση';

  @override
  String get trustedSitesSectionTitle => 'Έμπιστοι ιστότοποι';

  @override
  String get trustedSitesEmpty =>
      'Κανένας έμπιστος ιστότοπος. Προσθέστε τομέα για να απενεργοποιήσετε τον αποκλεισμό σε αυτόν.';

  @override
  String get addTrustedSite => 'Προσθήκη έμπιστου ιστότοπου';

  @override
  String get removeTrustedSite => 'Αφαίρεση';

  @override
  String get disableBlockingForThisSite =>
      'Απενεργοποίηση αποκλεισμού σε αυτόν τον ιστότοπο';

  @override
  String get enableBlockingForThisSite =>
      'Ενεργοποίηση αποκλεισμού σε αυτόν τον ιστότοπο';

  @override
  String get enterDomainHint => 'π.χ. ⁨example.com⁩';

  @override
  String get invalidDomain => 'Εισαγάγετε έγκυρο τομέα (π.χ. ⁨example.com⁩)';

  @override
  String get pageLoadTimedOut =>
      'Η φόρτωση της σελίδας έληξε. Επαναφορτώστε ή ανοίξτε στο πρόγραμμα περιήγησης.';

  @override
  String get pipelinesScreenTitle => 'Pipelines';

  @override
  String get pipelinesScreenSubtitle =>
      'Δηλωτικές ροές εργασίας πρακτόρων πολλαπλών βημάτων';

  @override
  String get pipelinesRunPipeline => 'Εκτέλεση pipeline';

  @override
  String get pipelineRunLauncherTitle => 'Εκτέλεση pipeline';

  @override
  String get pipelineRunSubtitle =>
      'Επιλέξτε pipeline και συμπληρώστε τις εισόδους του για να ξεκινήσει μια εκτέλεση.';

  @override
  String get pipelineRunNoInputsBadge => 'Χωρίς εισόδους';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count είσοδοι',
      one: '1 είσοδος',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'Αυτό το pipeline δεν δέχεται εισόδους.';

  @override
  String get pipelineRunSubmit => 'Εκτέλεση pipeline';

  @override
  String get pipelineRunCouldNotStart =>
      'Δεν ήταν δυνατή η έναρξη της εκτέλεσης.';

  @override
  String pipelineRunStarted(String name) {
    return 'Ξεκίνησε το $name';
  }

  @override
  String get pipelineRunEmptyTitle => 'Κανένα pipeline έτοιμο για εκτέλεση';

  @override
  String get pipelineRunEmptyHint =>
      'Ενεργοποιήστε ένα pipeline και την χειροκίνητη εκτέλεση στον επεξεργαστή του για να το εκκινήσετε εδώ.';

  @override
  String get pipelineRunManageTemplates => 'Διαχείριση pipelines';

  @override
  String get pipelineRunSettingsTitle => 'Χειροκίνητη εκτέλεση';

  @override
  String get pipelineRunSettingsAllow => 'Να επιτρέπεται χειροκίνητη εκτέλεση';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Εμφάνιση αυτού του pipeline στη σελίδα εκτέλεσης ώστε να μπορεί να ξεκινήσει χειροκίνητα.';

  @override
  String get pipelineRunSettingsConcurrencyTitle => 'Ταυτοχρονισμός';

  @override
  String get pipelineRunSettingsMaxParallel => 'Μέγιστες παράλληλες εκτελέσεις';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'Αφήστε κενό για απεριόριστο. Επιπλέον εκτελέσεις περιμένουν σε ουρά και ξεκινούν όταν ελευθερωθούν θέσεις.';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'Απεριόριστο';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      'Εισαγάγετε ακέραιο 1 ή μεγαλύτερο, ή αφήστε κενό για απεριόριστο.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Είσοδοι';

  @override
  String get pipelineRunSettingsAddInput => 'Προσθήκη εισόδου';

  @override
  String get pipelineRunSettingsNoInputs => 'Δεν υπάρχουν ακόμη είσοδοι.';

  @override
  String get pipelineInputEditTitle => 'Πεδίο εισόδου';

  @override
  String get pipelineInputKeyLabel => 'Κλειδί';

  @override
  String get pipelineInputKeyHelp =>
      'Κλειδί κατάστασης κάτω από το οποίο αποθηκεύεται η τιμή (π.χ. ⁨repo_full_name⁩).';

  @override
  String get pipelineInputLabelLabel => 'Ετικέτα';

  @override
  String get pipelineInputTypeLabel => 'Τύπος';

  @override
  String get pipelineInputOptionsLabel => 'Επιλογές (χωρισμένες με κόμμα)';

  @override
  String get pipelineInputDefaultLabel => 'Προεπιλεγμένη τιμή';

  @override
  String get pipelineInputPlaceholderLabel => 'Υπόδειξη';

  @override
  String get pipelineInputHelpLabel => 'Κείμενο βοήθειας';

  @override
  String get pipelineInputRequiredLabel => 'Υποχρεωτικό';

  @override
  String get pipelineInputTypeText => 'Κείμενο';

  @override
  String get pipelineInputTypeMultiline => 'Κείμενο πολλών γραμμών';

  @override
  String get pipelineInputTypeNumber => 'Αριθμός';

  @override
  String get pipelineInputTypeBoolean => 'Διακόπτης';

  @override
  String get pipelineInputTypeSelect => 'Επιλογή';

  @override
  String get pipelinesEmpty => 'Δεν υπάρχουν ακόμη εκτελέσεις pipeline';

  @override
  String get pipelinesEmptyHint =>
      'Κάντε κλικ στο «Εκτέλεση pipeline» για να ξεκινήσετε μία.';

  @override
  String get pipelinesNoSteps => 'Δεν έχουν καταγραφεί ακόμη βήματα';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Επιλέξτε χώρο εργασίας για να δείτε τα pipelines του';

  @override
  String pipelinesLoadError(String error) {
    return 'Αποτυχία φόρτωσης pipelines: ⁨$error⁩';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Αποτυχία έναρξης pipeline: ⁨$error⁩';
  }

  @override
  String get pipelineStatusPending => 'Εκκρεμεί';

  @override
  String get pipelineStatusQueued => 'Σε ουρά';

  @override
  String get pipelineStatusRunning => 'Σε εκτέλεση';

  @override
  String get pipelineStatusSuspended => 'Σε αναστολή';

  @override
  String get pipelineStatusCompleted => 'Ολοκληρώθηκε';

  @override
  String get pipelineStatusFailed => 'Απέτυχε';

  @override
  String get pipelineStatusCancelled => 'Ακυρώθηκε';

  @override
  String get pipelineStatusSkipped => 'Παραλείφθηκε';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed από $total βήματα';
  }

  @override
  String get pipelineWaterfallTimeline => 'Χρονολόγιο';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'Ενεργό $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'αδρανές $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'Χρόνος που εξαιρείται από το ενεργό σύνολο: η εκτέλεση ήταν σταματημένη ή σε αναμονή μεταξύ βημάτων.';

  @override
  String get pipelineStepStarted => 'Ξεκίνησε';

  @override
  String get pipelineStepFinished => 'Ολοκληρώθηκε';

  @override
  String get pipelineStepDurationLabel => 'Διάρκεια';

  @override
  String get pipelineStepBranch => 'Κλάδος';

  @override
  String get pipelineStepViewConversation => 'Προβολή συνομιλίας';

  @override
  String get pipelineStepError => 'Σφάλμα';

  @override
  String get pipelineStepInput => 'Είσοδος';

  @override
  String get pipelineStepOutput => 'Έξοδος';

  @override
  String get pipelineStepNotExecuted => 'Δεν έχει εκτελεστεί ακόμη';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Απέτυχε στο $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Χειροκίνητα';

  @override
  String get pipelineStepSkippedReason => 'Παραλείφθηκε';

  @override
  String get pipelineStepPriorAttempts => 'Προηγούμενες προσπάθειες';

  @override
  String get pipelineStepAttemptLabel => 'Προσπάθεια';

  @override
  String pipelineStepAttemptN(int number) {
    return 'Προσπάθεια $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'Διακόπηκε';

  @override
  String get pipelineRunColumnPipeline => 'Pipeline';

  @override
  String get pipelineRunColumnDuration => 'Διάρκεια';

  @override
  String get pipelineRunQueueNext => 'Επόμενο';

  @override
  String pipelineRunQueuePosition(int position) {
    return '$position στην ουρά';
  }

  @override
  String get pipelineRunColumnStarted => 'Ξεκίνησε';

  @override
  String get pipelineRunHistory => 'Ιστορικό εκτελέσεων';

  @override
  String get pipelineRunHistoryEmpty => 'Δεν υπάρχουν ακόμη άλλες εκτελέσεις';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'Επανεκτέλεση $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return 'Προσπάθεια $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'πρώτη έναρξη $time';
  }

  @override
  String get pipelineRunFilterAll => 'Όλα';

  @override
  String get pipelineRunFilterEmpty =>
      'Καμία εκτέλεση δεν ταιριάζει με αυτό το φίλτρο';

  @override
  String get relativeJustNow => 'μόλις τώρα';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'πριν από $count λεπτά',
      one: 'πριν από 1 λεπτό',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'πριν από $count ώρες',
      one: 'πριν από 1 ώρα',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'πριν από $count ημέρες',
      one: 'πριν από 1 ημέρα',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'Ομάδες';

  @override
  String get teamsAddTeam => 'Προσθήκη ομάδας';

  @override
  String get teamsLoadError => 'Δεν ήταν δυνατή η φόρτωση ομάδων';

  @override
  String get teamsEmptyTitle => 'Δεν υπάρχουν ακόμη ομάδες';

  @override
  String get teamsEmptyDescription =>
      'Ομαδοποιήστε πράκτορες ώστε η εργασία που ανατίθεται σε ομάδα να περνά από έναν ηγέτη που αναθέτει.';

  @override
  String get teamCreateTitle => 'Νέα ομάδα';

  @override
  String get teamEditTitle => 'Επεξεργασία ομάδας';

  @override
  String get teamNameLabel => 'Όνομα ομάδας';

  @override
  String get teamNameHint => 'π.χ. Frontend';

  @override
  String get teamDescriptionLabel => 'Περιγραφή';

  @override
  String get teamDescriptionHint => 'Για τι είναι υπεύθυνη αυτή η ομάδα';

  @override
  String get teamLeaderLabel => 'Ηγέτης';

  @override
  String get teamLeaderHelp =>
      'Ο συντονιστής που λαμβάνει την εργασία της ομάδας και την αναθέτει στο καταλληλότερο μέλος.';

  @override
  String get teamNoLeader => 'Χωρίς ηγέτη';

  @override
  String get teamInstructionsLabel => 'Οδηγίες λειτουργίας';

  @override
  String get teamInstructionsHelp =>
      'Προστίθενται στην ενημέρωση του ηγέτη — συμβάσεις ομάδας, κανόνες κλιμάκωσης, τόνος.';

  @override
  String get teamInstructionsHint => 'Προαιρετικά';

  @override
  String get teamSaved => 'Η ομάδα αποθηκεύτηκε';

  @override
  String get teamMembersError => 'Δεν ήταν δυνατή η φόρτωση μελών';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count μέλη',
      one: '1 μέλος',
      zero: 'Κανένα μέλος',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'Προσθήκη μέλους';

  @override
  String get teamAddMemberTitle => 'Προσθήκη μελών';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Προσθήκη $count',
      one: 'Προσθήκη 1',
      zero: 'Προσθήκη',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd => 'Κάθε πράκτορας είναι ήδη σε αυτή την ομάδα.';

  @override
  String get teamRemoveMember => 'Αφαίρεση από την ομάδα';

  @override
  String get teamLeaderBadge => 'Ηγέτης';

  @override
  String get teamUnknownAgent => 'Άγνωστος πράκτορας';

  @override
  String get teamMembersEmpty => 'Δεν υπάρχουν ακόμη μέλη';

  @override
  String get teamMembersEmptyDescription =>
      'Προσθέστε πράκτορες ώστε ο ηγέτης να έχει άτομα για ανάθεση.';

  @override
  String get teamSelectPrompt => 'Επιλέξτε ομάδα';

  @override
  String get teamSelectPromptDescription =>
      'Επιλέξτε ομάδα από τη λίστα ή δημιουργήστε μια νέα.';

  @override
  String get teamDeleteTitle => 'Διαγραφή ομάδας;';

  @override
  String teamDeleteBody(String name) {
    return 'Η $name θα διαγραφεί. Οι πράκτορές της δεν επηρεάζονται.';
  }

  @override
  String get teamHasLeaderTooltip => 'Έχει ηγέτη';

  @override
  String get pipelineTemplatesNav => 'Πρότυπα pipeline';

  @override
  String get pipelineTemplatesTitle => 'Πρότυπα pipeline';

  @override
  String get pipelineTemplatesSubtitle =>
      'Επεξεργαστής μεταφοράς-και-απόθεσης για τα pipelines που ενορχηστρώνουν τους πράκτορές σας.';

  @override
  String get pipelineTemplatesNew => 'Νέο πρότυπο';

  @override
  String get pipelineTemplatesEmpty =>
      'Δεν υπάρχουν ακόμη πρότυπα pipeline. Δημιουργήστε ένα για να ξεκινήσετε.';

  @override
  String get pipelineTemplateBuiltInBadge => 'Ενσωματωμένο';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Διαγραφή προτύπου;';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Διαγραφή του προτύπου pipeline $name; Αυτή η ενέργεια δεν αναιρείται.';
  }

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Σύρετε τύπους κόμβων από την πλαϊνή γραμμή στον καμβά και συνδέστε τους.';

  @override
  String get unsavedChanges => 'Μη αποθηκευμένες αλλαγές';

  @override
  String get nodeLibraryTitle => 'Βιβλιοθήκη κόμβων';

  @override
  String get nodeLibraryHint =>
      'Σύρετε οποιαδήποτε καταχώριση στον καμβά για να προσθέσετε κόμβο.';

  @override
  String get editorEmptyCanvas =>
      'Σύρετε έναν κόμβο από τη βιβλιοθήκη για να ξεκινήσετε.';

  @override
  String get pipelineWhenThisHappens => 'Όταν συμβεί αυτό';

  @override
  String get pipelineDoThis => 'Κάντε αυτό';

  @override
  String get pipelineAddStep => 'Προσθήκη βήματος';

  @override
  String get pipelineTidyUp => 'Τακτοποίηση διάταξης';

  @override
  String get pipelineEditorHint =>
      'Σύρετε τα βήματα για διάταξη · σύρετε μια λαβή για σύνδεση';

  @override
  String get pipelineRemoveConnection => 'Αφαίρεση σύνδεσης';

  @override
  String get pipelineDragToConnect => 'Σύρετε για σύνδεση';

  @override
  String get pipelineNewDefaultName => 'Νέο pipeline';

  @override
  String get nodeCategoryTriggers => 'Εναύσματα';

  @override
  String get triggerEventWebhook => 'Webhook';

  @override
  String get pipelineAddTrigger => 'Προσθήκη εναύσματος';

  @override
  String get pipelineOnEvent => 'Σε γεγονός';

  @override
  String get nodeConfigTitle => 'Ρύθμιση κόμβου';

  @override
  String get nodeConfigKind => 'Είδος';

  @override
  String get nodeConfigLabel => 'Ετικέτα';

  @override
  String get nodeConfigAgent => 'Πράκτορας';

  @override
  String get nodeConfigAgentHint => 'Επιλέξτε πράκτορα…';

  @override
  String get nodeConfigInputKeys => 'Κλειδιά εισόδου (χωρισμένα με κόμμα)';

  @override
  String get nodeConfigInputKeysHelp =>
      'Κλειδιά κατάστασης που καταναλώνει αυτός ο κόμβος. Χρησιμοποιούνται για αντικατάσταση υποκατάστατων στην προτροπή.';

  @override
  String get nodeConfigRepos => 'Αποθετήρια προς κλωνοποίηση';

  @override
  String get nodeConfigReposHelp =>
      'Αποθετήρια που κλωνοποιούνται και ευρετηριάζονται όταν αυτός ο κόμβος ξεκινά τη συνομιλία του. Η επιλογή όλων κλωνοποιεί όλα (η προεπιλογή).';

  @override
  String get nodeConfigRepoBranchHint => 'Κλάδος (προεπιλογή)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'Ο κλάδος από τον οποίο κόβεται κάθε checkout. Αφήστε κενό για τον προεπιλεγμένο κλάδο του αποθετηρίου — το worktree παίρνει τον δικό του κλάδο, ώστε τίποτα που κάνει commit ο πράκτορας να μην πέφτει σε αυτόν.';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'Δυναμικές καταχωρίσεις που διατηρήθηκαν: ⁨$entries⁩';
  }

  @override
  String get nodeConfigCreateConversation => 'Άνοιγμα συνομιλίας σε αυτόν';

  @override
  String get nodeConfigCreateConversationHelp =>
      'Αφήστε το απενεργοποιημένο όταν ακολουθούν πολλοί κόμβοι πρακτόρων — καθένας ανοίγει τη δική του επώνυμη ροή. Ενεργοποιήστε το όταν ακολουθεί ένας κόμβος πράκτορα, ώστε ο χώρος να μην εμφανίζει ανώνυμη συνομιλία δίπλα του.';

  @override
  String get nodeConfigConversationTitle => 'Όνομα συνομιλίας';

  @override
  String get nodeConfigConversationTitleHelp =>
      'Δώστε στον επόμενο κόμβο πράκτορα το ίδιο όνομα και εργάζονται στην ίδια ροή. Προεπιλογή είναι η ετικέτα του κόμβου.';

  @override
  String get nodeConfigSpaceName => 'Όνομα χώρου';

  @override
  String get nodeConfigSpaceNameHelp =>
      'Πώς ονομάζεται ο χώρος που ανοίγει αυτός ο κόμβος. Υποστηρίζει τα ίδια υποκατάστατα κατάστασης με μια προτροπή. Αφήστε κενό για την ετικέτα του κόμβου.';

  @override
  String get nodeConfigSpaceNameHint => 'Ανασκόπηση του pr_number';

  @override
  String get nodeConfigStreamTitle => 'Όνομα συνομιλίας';

  @override
  String get nodeConfigStreamTitleHelp =>
      'Η επώνυμη ροή στην οποία εργάζεται ο πράκτορας αυτού του κόμβου μέσα στον χώρο. Υποστηρίζει τα ίδια υποκατάστατα κατάστασης με μια προτροπή. Αν μείνει κενό, η σειρά πέφτει στη μόνιμη συνομιλία του χώρου, όπου μια εξάπλωση παρεμβάλλει κάθε πράκτορα.';

  @override
  String get nodeConfigConversationTitleHint => 'Ανάλυση αρχιτεκτονικής';

  @override
  String get nodeConfigOutputKey => 'Κλειδί εξόδου';

  @override
  String get nodeConfigPrompt => 'Πρότυπο προτροπής';

  @override
  String get nodeConfigPromptHelp =>
      'Χρησιμοποιήστε υποκατάστατα διπλών αγκίστρων για να πάρετε τιμές από την κατάσταση κατά την εκτέλεση.';

  @override
  String get nodeConfigScript => 'Σενάριο Bash';

  @override
  String get nodeConfigScriptHelp =>
      'Εκτελείται με bash -c. Το GITHUB_TOKEN ορίζεται. Τα υποκατάστατα αντικαθίστανται πριν την εκτέλεση.';

  @override
  String get nodeConfigRouteKeys => 'Κλειδιά δρομολόγησης';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Κλειδί δρομολόγησης από $source';
  }

  @override
  String get conditionSectionTitle => 'Συνθήκη';

  @override
  String get conditionMode => 'Λειτουργία';

  @override
  String get conditionModeFilesAny => 'Υπάρχει αρχείο(-α) — οποιοδήποτε';

  @override
  String get conditionModeFilesAll => 'Υπάρχουν αρχεία — όλα';

  @override
  String get conditionModeComparison => 'Σύγκριση';

  @override
  String get conditionModeSwitch => 'Διακόπτης';

  @override
  String get conditionFilePaths => 'Διαδρομές αρχείων';

  @override
  String get conditionFilePathsAnyHelp =>
      'Μία διαδρομή ανά γραμμή, σχετική με τον βασικό κατάλογο. Δρομολογεί true όταν υπάρχει οποιαδήποτε.';

  @override
  String get conditionFilePathsAllHelp =>
      'Μία διαδρομή ανά γραμμή, σχετική με τον βασικό κατάλογο. Δρομολογεί true μόνο όταν υπάρχουν όλες.';

  @override
  String get conditionBaseKey => 'Κλειδί βασικού καταλόγου';

  @override
  String get conditionBaseKeyHelp =>
      'Κλειδί κατάστασης που κρατά τον κατάλογο ως προς τον οποίο επιλύονται οι διαδρομές (προεπιλογή ⁨repo_local_path⁩).';

  @override
  String get conditionRecursive => 'Αναζήτηση σε υποκαταλόγους';

  @override
  String get conditionNegate => 'Αντιστροφή: δρομολόγηση true όταν λείπει';

  @override
  String get conditionLeft => 'Αριστερή τιμή';

  @override
  String get conditionOperator => 'Τελεστής';

  @override
  String get conditionRight => 'Δεξιά τιμή';

  @override
  String get conditionSwitchKey => 'Διακόπτης σε κλειδί κατάστασης';

  @override
  String get conditionCases => 'Περιπτώσεις (χωρισμένες με κόμμα)';

  @override
  String get conditionCasesHelp =>
      'Κλειδιά δρομολόγησης για αντιστοίχιση με την τιμή, με τη σειρά.';

  @override
  String get conditionDefaultCase => 'Προεπιλεγμένη περίπτωση';

  @override
  String get triggerManualHelp =>
      'Εμφάνιση στη σελίδα εκτέλεσης και έναρξη χειροκίνητα.';

  @override
  String get triggerKindSchedule => 'Σε χρονοδιάγραμμα';

  @override
  String get triggerScheduleExprLabel =>
      'Χρονοδιάγραμμα (cron ή every:seconds)';

  @override
  String get triggerTimezoneLabel => 'Ζώνη ώρας (προαιρετικά)';

  @override
  String get triggerCatchUpLabel => 'Σε χαμένες εκτελέσεις';

  @override
  String get triggerCatchUpRunOnce => 'Εκτέλεση μία φορά';

  @override
  String get triggerCatchUpSkip => 'Παράλειψη';

  @override
  String get syncHealthTitle => 'Υγεία συγχρονισμού';

  @override
  String get syncHealthNoConfigs => 'Δεν υπάρχουν ακόμη συνδέσεις συγχρονισμού';

  @override
  String get syncHealthNeverSynced => 'Δεν συγχρονίστηκε ποτέ';

  @override
  String get syncOutcomeOk => 'Συγχρονίστηκε';

  @override
  String get syncOutcomeFailed => 'Απέτυχε';

  @override
  String get syncOutcomeSkipped => 'Παραλείφθηκε';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count διαδοχικές αποτυχίες';
  }

  @override
  String get triggerWebhookHelp =>
      'Δημιουργείται υπογεγραμμένο URL webhook. Εξωτερικά συστήματα κάνουν POST σε αυτό για να ξεκινήσουν αυτό το pipeline.';

  @override
  String get triggerWebhookPathLabel => 'Διαδρομή webhook';

  @override
  String get triggerMatchStatusLabel => 'Μόνο όταν η κατάσταση είναι';

  @override
  String get triggerSummaryNone => 'Χωρίς εναύσματα';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Κάθε $secondsδ';
  }

  @override
  String get triggerEventManual => 'Χειροκίνητη εκτέλεση';

  @override
  String get triggerEventSchedule => 'Χρονοδιάγραμμα';

  @override
  String get triggerEventPrStatusChanged => 'Άλλαξε η κατάσταση του PR';

  @override
  String get triggerEventExternalPr => 'Άνοιξε εξωτερικό PR';

  @override
  String get triggerEventPrPublished => 'Δημοσιεύτηκε PR';

  @override
  String get triggerEventPrMerged => 'Συγχωνεύθηκε PR';

  @override
  String get triggerEventRepoAdded => 'Προστέθηκε αποθετήριο';

  @override
  String get triggerEventCodeGraphWatch => 'Αλλαγή αρχείου';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count αλλαγμένα αρχεία',
      one: '1 αλλαγμένο αρχείο',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '+$count ακόμη';
  }

  @override
  String get pipelineRunCauseRescan => 'Άλλαξε στον δίσκο';

  @override
  String get pipelineRunCauseInitial => 'Πρώτο ευρετήριο αυτού του checkout';

  @override
  String get triggerEventMessageReceived => 'Ελήφθη μήνυμα';

  @override
  String get triggerEventTicketCompleted => 'Το εισιτήριο ολοκληρώθηκε';

  @override
  String get triggerEventTicketFailed => 'Το εισιτήριο απέτυχε';

  @override
  String get triggerEventTicketCancelled => 'Το εισιτήριο ακυρώθηκε';

  @override
  String get triggerEventBudgetCrossed => 'Υπερβήθηκε το όριο προϋπολογισμού';

  @override
  String get nodeLibrarySearchHint => 'Αναζήτηση κόμβων';

  @override
  String get nodeLibraryNoMatches => 'Κανένας αντίστοιχος κόμβος';

  @override
  String get nodeCategoryFlow => 'Ροή και λογική';

  @override
  String get nodeCategoryPr => 'Ανασκόπηση PR';

  @override
  String get nodeCategoryAgents => 'Πράκτορες';

  @override
  String get nodeCategoryMessaging => 'Μηνύματα';

  @override
  String get nodeCategoryCode => 'Κώδικας';

  @override
  String get triggerDisabledTag => 'ανεν.';

  @override
  String get pipelineInputTypeRepo => 'Αποθετήριο';

  @override
  String get pipelineRunNoRepos =>
      'Δεν υπάρχουν ακόμη αποθετήρια σε αυτόν τον χώρο εργασίας.';

  @override
  String get allowTicketingApi => 'Να επιτρέπονται κλήσεις API εισιτηρίων';

  @override
  String get ticketingApiKey => 'Κλειδί API εισιτηρίων';

  @override
  String get ticketingApiKeySubtitle =>
      'Εισάγει το κλειδί API του παρόχου εισιτηρίων στο sandbox.';

  @override
  String get ticketingProvider => 'Πάροχος εισιτηρίων';

  @override
  String get connectGitHubAndTicketing =>
      'Συνδέστε έναν κεντρικό κώδικα ώστε το Control Center να διαβάζει τα pull requests, τα issues και τις ανασκοπήσεις σας. Προαιρετικά συνδέστε πάροχο εισιτηρίων. Τα διαπιστευτήρια τα κρατά ο διακομιστής σας, ποτέ αυτό το μηχάνημα.';

  @override
  String get triggerEventTicketAssigned => 'Ανατέθηκε εισιτήριο';

  @override
  String get triggerEventTicketCreated => 'Δημιουργήθηκε εισιτήριο';

  @override
  String get triggerEventTicketStatusChanged => 'Άλλαξε η κατάσταση εισιτηρίου';

  @override
  String get triggerEventMeetingRecordingStopped =>
      'Η εγγραφή συνάντησης σταμάτησε';

  @override
  String get triggerEventSkillUpdated => 'Η δεξιότητα ενημερώθηκε';

  @override
  String get triggerEventSpaceDeleted => 'Ο χώρος διαγράφηκε';

  @override
  String get triggerExternalPrHelp =>
      'Ένα pull request που ανοίχτηκε στον κεντρικό υπολογιστή κώδικα, όχι από το Control Center.';

  @override
  String get triggerPrPublishedHelp =>
      'Ένα pull request που ανοίχτηκε από το Control Center ή από έναν πράκτορα.';

  @override
  String get triggerPrStatusChangedHelp =>
      'Συγχωνεύτηκε, έκλεισε, άνοιξε, ξανάνοιξε ή εγκρίθηκε. Φιλτράρετε κατά κατάσταση στον επιθεωρητή.';

  @override
  String get triggerPrMergedHelp =>
      'Μόνο όταν το pull request συγχωνεύεται, όχι όταν κλείνει ή ξανανοίγει.';

  @override
  String get triggerRepoAddedHelp =>
      'Ένα αποθετήριο συνδέεται με αυτόν τον χώρο εργασίας.';

  @override
  String get triggerCodeGraphWatchHelp =>
      'Ένα αρχείο σε συνδεδεμένο αποθετήριο αλλάζει στο δίσκο.';

  @override
  String get triggerMessageReceivedHelp =>
      'Ένα νέο μήνυμα φτάνει σε έναν χώρο.';

  @override
  String get triggerTicketCreatedHelp =>
      'Δημιουργείται ένα εισιτήριο σε αυτόν τον χώρο εργασίας.';

  @override
  String get triggerTicketStatusChangedHelp =>
      'Ένα εισιτήριο μετακινείται μεταξύ καταστάσεων.';

  @override
  String get triggerTicketCompletedHelp =>
      'Ένα εισιτήριο ολοκληρώνεται με επιτυχία.';

  @override
  String get triggerTicketFailedHelp =>
      'Μια εκτέλεση πράκτορα απέτυχε και το εισιτήριο σημειώνεται ως αποτυχημένο.';

  @override
  String get triggerTicketCancelledHelp =>
      'Ένα εισιτήριο ακυρώνεται και δεν συνεχίζεται.';

  @override
  String get triggerBudgetCrossedHelp =>
      'Υπερβαίνεται ένα όριο δαπανών χώρου εργασίας ή πράκτορα.';

  @override
  String get triggerTicketAssignedHelp =>
      'Ένα εισιτήριο ανατίθεται σε άτομο, πράκτορα ή ομάδα.';

  @override
  String get triggerMeetingRecordingStoppedHelp =>
      'Η εγγραφή μιας σύσκεψης τελειώνει.';

  @override
  String get triggerSkillUpdatedHelp =>
      'Μια δεξιότητα εγκαθίσταται ή ενημερώνεται.';

  @override
  String get triggerSpaceDeletedHelp => 'Ένας χώρος συνομιλίας διαγράφεται.';

  @override
  String get navTickets => 'Εισιτήρια';

  @override
  String get ticketsTitle => 'Εισιτήρια';

  @override
  String get newTicket => 'Νέο εισιτήριο';

  @override
  String get noTicketsYet => 'Δεν υπάρχουν ακόμη εισιτήρια';

  @override
  String get addCollaborator => 'Προσθήκη συνεργάτη';

  @override
  String get noCollaborators => 'Δεν υπάρχουν ακόμη συνεργάτες';

  @override
  String get linkedPullRequests => 'Συνδεδεμένα pull requests';

  @override
  String get noLinkedPullRequests =>
      'Δεν υπάρχουν ακόμη συνδεδεμένα pull requests';

  @override
  String get stopAgent => 'Διακοπή πράκτορα';

  @override
  String get ticketProperties => 'Ιδιότητες';

  @override
  String get ticketTabIssue => 'Issue';

  @override
  String get ticketSelectPrompt =>
      'Επιλέξτε εισιτήριο για να δείτε τις λεπτομέρειές του';

  @override
  String get unassigned => 'Χωρίς ανάθεση';

  @override
  String get ticketStatusBacklog => 'Ανεκτέλεστα';

  @override
  String get ticketStatusOpen => 'Προς εκτέλεση';

  @override
  String get ticketStatusInProgress => 'Σε εξέλιξη';

  @override
  String get ticketStatusInReview => 'Σε ανασκόπηση';

  @override
  String get ticketStatusDone => 'Ολοκληρώθηκε';

  @override
  String get ticketStatusBlocked => 'Αποκλεισμένο';

  @override
  String get ticketStatusFailed => 'Απέτυχε';

  @override
  String get ticketStatusCancelled => 'Ακυρώθηκε';

  @override
  String get notificationTicketAssigned => 'Ανατέθηκε εισιτήριο';

  @override
  String get notificationTicketStatusChanged => 'Άλλαξε η κατάσταση εισιτηρίου';

  @override
  String get priority => 'Προτεραιότητα';

  @override
  String get status => 'Κατάσταση';

  @override
  String get assignee => 'Ανατεθειμένος';

  @override
  String get labels => 'Ετικέτες';

  @override
  String get noLabelsYet => 'Δεν υπάρχουν ακόμη ετικέτες';

  @override
  String get clearLabels => 'Καθαρισμός ετικετών';

  @override
  String get pipelineStepAgentActivity => 'Δραστηριότητα πράκτορα';

  @override
  String get runStatusCompleted => 'Ολοκληρώθηκε';

  @override
  String get runStatusQueued => 'Σε ουρά';

  @override
  String get ticketDescription => 'Περιγραφή';

  @override
  String get ticketPriorityNone => 'Καμία';

  @override
  String get ticketPriorityUrgent => 'Επείγον';

  @override
  String get ticketPriorityHigh => 'Υψηλή';

  @override
  String get ticketPriorityMedium => 'Μεσαία';

  @override
  String get ticketPriorityLow => 'Χαμηλή';

  @override
  String get ticketViewList => 'Λίστα';

  @override
  String get ticketViewBoard => 'Πίνακας';

  @override
  String get ticketTitlePlaceholder => 'Τίτλος ζητήματος';

  @override
  String get ticketDescriptionPlaceholder => 'Προσθήκη περιγραφής…';

  @override
  String get createMore => 'Δημιουργία περισσότερων';

  @override
  String selectedCount(int count) {
    return '$count επιλεγμένα';
  }

  @override
  String get clearSelection => 'Καθαρισμός επιλογής';

  @override
  String get bulkDeleteTitle => 'Διαγραφή εισιτηρίων';

  @override
  String bulkDeleteMessage(int count) {
    return 'Διαγραφή $count επιλεγμένων εισιτηρίων; Αυτή η ενέργεια δεν αναιρείται.';
  }

  @override
  String get assignTo => 'Ανάθεση σε…';

  @override
  String get sectionMembers => 'Μέλη';

  @override
  String get sectionAgents => 'Πράκτορες';

  @override
  String get sidebarGroupWorkspace => 'Χώρος εργασίας';

  @override
  String get notificationsTitle => 'Ειδοποιήσεις';

  @override
  String get notificationsTooltip => 'Ειδοποιήσεις';

  @override
  String get notificationsEmpty => 'Είστε ενήμεροι';

  @override
  String notificationsUnreadCount(int count) {
    return '$count μη αναγνωσμένα';
  }

  @override
  String get notificationsMarkRead => 'Σήμανση ως αναγνωσμένο';

  @override
  String get notificationsMarkUnread => 'Σήμανση ως μη αναγνωσμένο';

  @override
  String get notificationsEntryActions => 'Ενέργειες ειδοποίησης';

  @override
  String get markAllRead => 'Σήμανση όλων ως αναγνωσμένων';

  @override
  String get teamsNav => 'Ομάδες';

  @override
  String get noWorkspace => 'Χωρίς χώρο εργασίας';

  @override
  String get selectWorkspace => 'Επιλέξτε χώρο εργασίας';

  @override
  String get navMemory => 'Μνήμη';

  @override
  String get memoryTabFacts => 'Γεγονότα';

  @override
  String get memoryTabPolicies => 'Πολιτικές';

  @override
  String get memoryGraphShowFacts => 'Εμφάνιση γεγονότων';

  @override
  String get memoryGraphHideFacts => 'Απόκρυψη γεγονότων';

  @override
  String get memoryGraphExpandAll => 'Ανάπτυξη όλων των γεγονότων';

  @override
  String get memoryGraphCollapseAll => 'Σύμπτυξη όλων των γεγονότων';

  @override
  String get memoryTabGraph => 'Γράφος γνώσης';

  @override
  String get memoryNoWorkspace =>
      'Επιλέξτε χώρο εργασίας για να δείτε τη μνήμη του.';

  @override
  String get searchArticles => 'Αναζήτηση άρθρων';

  @override
  String get filterAll => 'Όλα';

  @override
  String get filterUnread => 'Μη αναγνωσμένα';

  @override
  String get filterSaved => 'Αποθηκευμένα';

  @override
  String get saveArticle => 'Αποθήκευση άρθρου';

  @override
  String get removeFromSaved => 'Αφαίρεση από τα αποθηκευμένα';

  @override
  String get filterBySource => 'Φιλτράρισμα κατά πηγή';

  @override
  String get viewAsList => 'Προβολή λίστας';

  @override
  String get viewAsGrid => 'Προβολή πλέγματος';

  @override
  String get noMatchingArticles => 'Κανένα αντίστοιχο άρθρο';

  @override
  String get noMatchingArticlesBody =>
      'Δοκιμάστε διαφορετική αναζήτηση ή φίλτρο πηγής.';

  @override
  String get allCaughtUp => 'Είστε ενήμεροι';

  @override
  String get allCaughtUpBody =>
      'Δεν υπάρχουν μη αναγνωσμένα άρθρα — ελέγξτε αργότερα.';

  @override
  String get openArticlesInAppDescription =>
      'Άνοιγμα συνδέσμων στον ενσωματωμένο αναγνώστη αντί για το προεπιλεγμένο πρόγραμμα περιήγησης.';

  @override
  String get blockAdsTrackersDescription =>
      'Αφαίρεση διαφημίσεων, ιχνηλατών και banner cookies από άρθρα που ανοίγετε στον αναγνώστη.';

  @override
  String get agentQuestionHeader => 'Ερώτηση για εσάς';

  @override
  String get agentQuestionAnsweredLabel => 'Απαντήθηκε';

  @override
  String get agentQuestionFreeformHint => 'Πληκτρολογήστε την απάντησή σας…';

  @override
  String agentQuestionProgress(int index, int count) {
    return 'Ερώτηση $index από $count';
  }

  @override
  String get agentQuestionSkip => 'Παράλειψη';

  @override
  String get agentQuestionSkippedLabel => 'Παραλείφθηκε';

  @override
  String get agentQuestionFreeformOptionHint => 'Περιγράψτε με δικά σας λόγια…';

  @override
  String get reviewRequested => 'Ζητήθηκε ανασκόπηση';

  @override
  String get connectGitHubHint =>
      'Συνδεθείτε στο GitHub ή προσθέστε token στις Ρυθμίσεις → Χώρος εργασίας → Προφίλ και ταυτότητα → Φιλοξενία κώδικα';

  @override
  String get connectGitHubToLoadPrs =>
      'Συνδέστε το GitHub για φόρτωση pull requests';

  @override
  String get noRepositoriesConfigured => 'Δεν έχουν ρυθμιστεί αποθετήρια';

  @override
  String openedAgo(String age) {
    return 'Άνοιξε $age';
  }

  @override
  String prTimelineOpened(String author) {
    return 'Ο/Η $author άνοιξε αυτό το pull request';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return 'Ο/Η $author άνοιξε αυτό το pull request με $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return 'Ο/Η $actor ζήτησε ανασκόπηση από $reviewers';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return 'Ο/Η $actor αφαίρεσε το αίτημα ανασκόπησης για $reviewers';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return 'Ο/Η $actor ζήτησε ανασκόπηση από $requested και αφαίρεσε το αίτημα ανασκόπησης για $removed';
  }

  @override
  String prTimelineAddedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'τις ετικέτες',
      one: 'την ετικέτα',
    );
    return 'Ο/Η $actor πρόσθεσε $_temp0 $labels';
  }

  @override
  String prTimelineRemovedLabels(String actor, String labels, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'τις ετικέτες',
      one: 'την ετικέτα',
    );
    return 'Ο/Η $actor αφαίρεσε $_temp0 $labels';
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
      other: 'τις ετικέτες',
      one: 'την ετικέτα',
    );
    String _temp1 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: 'τις ετικέτες',
      one: 'την ετικέτα',
    );
    return 'Ο/Η $actor πρόσθεσε $_temp0 $added και αφαίρεσε $_temp1 $removed';
  }

  @override
  String prTimelineCommitted(String author) {
    return 'Ο/Η $author έκανε commit';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return 'Ο/Η $author έκανε push $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return 'Ο/Η $author ενέκρινε αυτές τις αλλαγές';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return 'Ο/Η $author ζήτησε αλλαγές';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count σχόλια κώδικα',
      one: '1 σχόλιο κώδικα',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return 'Ο/Η $author ανασκόπησε';
  }

  @override
  String get prTimelineSomeone => 'Κάποιος';

  @override
  String get prTimelineBotBadge => 'bot';

  @override
  String updatedAgo(String age) {
    return 'Ενημερώθηκε $age';
  }

  @override
  String get checksPassing => 'Οι έλεγχοι περνούν';

  @override
  String get checksRunning => 'Οι έλεγχοι εκτελούνται';

  @override
  String get needsYourReview => 'Χρειάζεται την ανασκόπησή σας';

  @override
  String get checks => 'Έλεγχοι';

  @override
  String get noReviewersAssigned => 'Δεν έχουν ανατεθεί κριτές';

  @override
  String get noAssignees => 'Χωρίς ανατεθειμένους';

  @override
  String get loadingEllipsis => 'Φόρτωση…';

  @override
  String get loadingChecks => 'Φόρτωση ελέγχων…';

  @override
  String get noChecksYet => 'Δεν έχουν εκτελεστεί ακόμη έλεγχοι';

  @override
  String get noChangesToReview => 'Δεν υπάρχουν αλλαγές για έλεγχο';

  @override
  String checksFailingCount(int count) {
    return '$count αποτυγχάνουν';
  }

  @override
  String get showMore => 'Εμφάνιση περισσότερων';

  @override
  String get showLess => 'Εμφάνιση λιγότερων';

  @override
  String get backToPullRequests => 'Πίσω στα pull requests';

  @override
  String get pullRequestNotFound => 'Το pull request δεν βρέθηκε';

  @override
  String get pullRequestNotFoundBody =>
      'Μπορεί να συγχωνεύθηκε, να έκλεισε ή να μετακινήθηκε.';

  @override
  String get couldntLoadPullRequest =>
      'Δεν ήταν δυνατή η φόρτωση αυτού του pull request';

  @override
  String get showDetails => 'Εμφάνιση λεπτομερειών';

  @override
  String get noDescriptionProvided => 'Δεν δόθηκε περιγραφή.';

  @override
  String get factsHint =>
      'Τα γεγονότα θα εμφανιστούν εδώ καθώς μαθαίνουν οι πράκτορές σας.';

  @override
  String get noFactsMatch =>
      'Κανένα γεγονός δεν ταιριάζει με την αναζήτησή σας';

  @override
  String get memoryLoadError => 'Δεν ήταν δυνατή η φόρτωση της μνήμης';

  @override
  String get sortRecent => 'Πρόσφατα';

  @override
  String get sortConfidence => 'Εμπιστοσύνη';

  @override
  String get confidenceTooltip =>
      'Πόσο σίγουροι είναι οι πράκτορες ότι αυτό το γεγονός είναι αληθές, από 0 έως 100%.';

  @override
  String get supersededTooltip => 'Ένα νεότερο γεγονός αντικατέστησε αυτό.';

  @override
  String get domain => 'Τομέας';

  @override
  String get fitToView => 'Προσαρμογή στην προβολή';

  @override
  String get project => 'Έργο';

  @override
  String get newProject => 'Νέο έργο';

  @override
  String get editProject => 'Επεξεργασία έργου';

  @override
  String get deleteProject => 'Διαγραφή έργου';

  @override
  String get noProject => 'Χωρίς έργο';

  @override
  String get allTickets => 'Όλα τα εισιτήρια';

  @override
  String get projectNamePlaceholder => 'Όνομα έργου';

  @override
  String get projectDescriptionPlaceholder => 'Περιγραφή (προαιρετικά)';

  @override
  String get projectColorLabel => 'Χρώμα';

  @override
  String get noProjectsYet => 'Δεν υπάρχουν ακόμη έργα';

  @override
  String get projectTicketsEmpty =>
      'Δεν υπάρχουν ακόμη εισιτήρια σε αυτό το έργο';

  @override
  String get createProject => 'Δημιουργία έργου';

  @override
  String projectProgress(int done, int total) {
    return '$done από $total ολοκληρώθηκαν';
  }

  @override
  String deleteProjectConfirm(String name) {
    return 'Διαγραφή του «$name»; Τα εισιτήριά του διατηρούνται και αφαιρούνται από το έργο.';
  }

  @override
  String get projectStatusActive => 'Ενεργό';

  @override
  String get projectStatusCompleted => 'Ολοκληρωμένο';

  @override
  String get projectStatusArchived => 'Αρχειοθετημένο';

  @override
  String get markProjectCompleted => 'Σήμανση ως ολοκληρωμένο';

  @override
  String get markProjectActive => 'Σήμανση ως ενεργό';

  @override
  String get archiveProject => 'Αρχειοθέτηση';

  @override
  String get restoreProject => 'Επαναφορά';

  @override
  String get relations => 'Σχέσεις';

  @override
  String get relateTo => 'Συσχέτιση με';

  @override
  String get relationSubIssueOf => 'Υποζήτημα του…';

  @override
  String get relationParentOf => 'Γονικό του…';

  @override
  String get relationBlockedBy => 'Αποκλείεται από…';

  @override
  String get relationBlocking => 'Αποκλείει…';

  @override
  String get relationRelatedTo => 'Σχετίζεται με…';

  @override
  String get relationDuplicateOf => 'Διπλότυπο του…';

  @override
  String get relationGroupParent => 'Γονικό';

  @override
  String get relationGroupSubIssues => 'Υποζητήματα';

  @override
  String get relationGroupBlockedBy => 'Αποκλείεται από';

  @override
  String get relationGroupBlocking => 'Αποκλείει';

  @override
  String get relationGroupRelated => 'Σχετικά';

  @override
  String get relationGroupDuplicateOf => 'Διπλότυπο του';

  @override
  String get relationGroupDuplicatedBy => 'Διπλότυπα από';

  @override
  String get copyId => 'Αντιγραφή ID';

  @override
  String get ticketIdCopied => 'Αντιγράφηκε το ID εισιτηρίου';

  @override
  String get searchTicketsHint => 'Αναζήτηση εισιτηρίων…';

  @override
  String get noMatchingTickets => 'Κανένα εισιτήριο δεν ταιριάζει';

  @override
  String get clearAll => 'Καθαρισμός όλων';

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
      other: '$repos αποθετήρια',
      one: '1 αποθετήριο',
    );
    return '$_temp0 σε αναμονή της ανασκόπησής σας σε $_temp1';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'Μετονομάστε έναν χώρο εργασίας και αλλάξτε το σήμα του — επιλέξτε έναν αριστερά για επεξεργασία.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count χώροι εργασίας',
      one: '1 χώρος εργασίας',
      zero: 'Κανένας χώρος εργασίας',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos αποθετήρια',
      one: '1 αποθετήριο',
      zero: 'Κανένα αποθετήριο',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents πράκτορες',
      one: '1 πράκτορας',
      zero: '0 πράκτορες',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'Ταυτότητα';

  @override
  String get uploadImage => 'Μεταφόρτωση εικόνας';

  @override
  String get failedToSaveLogo =>
      'Αποτυχία αποθήκευσης της εικόνας λογότυπου. Βεβαιωθείτε ότι η εφαρμογή μπορεί να διαβάσει το επιλεγμένο αρχείο.';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG ή GIF έως 2 MB. Διαφορετικά χρησιμοποιείται το αρχικό του χώρου εργασίας.';

  @override
  String get workspaceNameFieldHelp =>
      'Εμφανίζεται στον εναλλάκτη, στο ψωμί και σε κάθε οθόνη.';

  @override
  String get dangerZone => 'Ζώνη κινδύνου';

  @override
  String get deleteThisWorkspace => 'Διαγραφή αυτού του χώρου εργασίας';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Αφαιρεί οριστικά το $name, τις συνδέσεις αποθετηρίων, τους πράκτορες και τη μνήμη. Αυτή η ενέργεια δεν αναιρείται.';
  }

  @override
  String get discard => 'Απόρριψη';

  @override
  String discardChangesQuestion(String name) {
    return 'Απόρριψη μη αποθηκευμένων αλλαγών στο $name;';
  }

  @override
  String get workspaceUpdated => 'Ο χώρος εργασίας ενημερώθηκε';

  @override
  String get editTitle => 'Επεξεργασία τίτλου';

  @override
  String get editDescription => 'Επεξεργασία περιγραφής';

  @override
  String get addDescription => 'Προσθήκη περιγραφής';

  @override
  String get prTitlePlaceholder => 'Τίτλος';

  @override
  String get prBodyPlaceholder => 'Αφήστε μια περιγραφή';

  @override
  String get write => 'Σύνταξη';

  @override
  String get overview => 'Επισκόπηση';

  @override
  String get noFilesChanged => 'Κανένα αλλαγμένο αρχείο';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Προεπισκόπηση';

  @override
  String get imageDiffBefore => 'Πριν';

  @override
  String get imageDiffAfter => 'Μετά';

  @override
  String get imageDiffModeTwoUp => 'Δίπλα';

  @override
  String get imageDiffModeSwipe => 'Σύρετε';

  @override
  String get imageDiffModeDifference => 'Διαφορά';

  @override
  String imageDiffChangedPercent(String percent) {
    return 'Άλλαξε $percent%';
  }

  @override
  String get imageDiffPictures => 'Εικόνες';

  @override
  String get imageDiffSource => 'Πηγή';

  @override
  String get imageDiffDeleted => 'Διαγράφηκε';

  @override
  String get imageDiffAdded => 'Προστέθηκε';

  @override
  String imageDiffDimensions(int width, int height) {
    return 'Π: ${width}px | Υ: ${height}px';
  }

  @override
  String get outdated => 'Παρωχημένο';

  @override
  String get outdatedComments => 'Παρωχημένα σχόλια';

  @override
  String outdatedCountLabel(int count) {
    return '$count παρωχημένα';
  }

  @override
  String get prTemplateLabel => 'Πρότυπο';

  @override
  String get prTemplateDefault => 'Προεπιλογή';

  @override
  String get addReviewers => 'Προσθήκη κριτών';

  @override
  String get addAssignees => 'Προσθήκη ανατεθειμένων';

  @override
  String get addLabels => 'Προσθήκη ετικετών';

  @override
  String get searchLabels => 'Αναζήτηση ετικετών…';

  @override
  String get noMatchingLabels => 'Δεν υπάρχουν αντίστοιχες ετικέτες';

  @override
  String removeLabel(String label) {
    return 'Αφαίρεση $label';
  }

  @override
  String get searchUsers => 'Αναζήτηση ατόμων…';

  @override
  String get searchReviewers => 'Αναζήτηση ατόμων και ομάδων…';

  @override
  String get usersSectionLabel => 'Άτομα';

  @override
  String get userStatusBusy => 'Απασχολημένος';

  @override
  String get teamsSectionLabel => 'Ομάδες';

  @override
  String get suggestedReviewers => 'Προτεινόμενοι κριτές';

  @override
  String get noMatchingUsers => 'Κανένα αντίστοιχο άτομο';

  @override
  String get noMatchingReviewers => 'Κανένα αποτέλεσμα';

  @override
  String get requiredByCodeOwners => 'Απαιτείται από code owners';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'μέσω ⁨$login⁩';
  }

  @override
  String get team => 'Ομάδα';

  @override
  String get markdownBold => 'Έντονα';

  @override
  String get markdownItalic => 'Πλάγια';

  @override
  String get markdownHeading => 'Επικεφαλίδα';

  @override
  String get markdownBulletList => 'Λίστα με κουκκίδες';

  @override
  String get markdownChecklist => 'Λίστα ελέγχου';

  @override
  String get markdownCode => 'Κώδικας';

  @override
  String get markdownLink => 'Σύνδεσμος';

  @override
  String get markdownQuote => 'Παράθεση';

  @override
  String get markdownSupported => 'Υποστηρίζεται Markdown';

  @override
  String get markdownAttachImages => 'Κάντε κλικ για προσθήκη εικόνων';

  @override
  String failedToUpdateTitle(String error) {
    return 'Δεν ήταν δυνατή η ενημέρωση του τίτλου: ⁨$error⁩';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Δεν ήταν δυνατή η ενημέρωση της περιγραφής: ⁨$error⁩';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Δεν ήταν δυνατή η ενημέρωση των κριτών: ⁨$error⁩';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Δεν ήταν δυνατή η ενημέρωση των ανατεθειμένων: ⁨$error⁩';
  }

  @override
  String failedToUpdateLabels(String error) {
    return 'Δεν ήταν δυνατή η ενημέρωση των ετικετών: $error';
  }

  @override
  String get discardChangesConfirm => 'Απόρριψη των αλλαγών σας;';

  @override
  String get newPr => 'Νέο PR';

  @override
  String get openPullRequest => 'Άνοιγμα pull request';

  @override
  String get composePrSubtitle =>
      'Από κλάδο που έχετε κάνει push — χωρίς πράκτορες ή εισιτήρια';

  @override
  String get createAsDraft => 'Δημιουργία ως πρόχειρο';

  @override
  String get composePrNoRepo => 'Δεν έχει επιλεγεί αποθετήριο GitHub';

  @override
  String get composePrNoRepoHint =>
      'Επιλέξτε χώρο εργασίας με αποθετήριο συνδεδεμένο στο GitHub για να ανοίξετε pull request.';

  @override
  String get composePrPickBranches =>
      'Επιλέξτε βασικό και compare κλάδο για προεπισκόπηση των αλλαγών.';

  @override
  String get composePrNothingToCompare =>
      'Δεν υπάρχουν αλλαγές μεταξύ αυτών των κλάδων.';

  @override
  String get repository => 'Αποθετήριο';

  @override
  String get baseBranchLabel => 'Βάση';

  @override
  String get compareBranchLabel => 'Σύγκριση';

  @override
  String get selectBranch => 'Επιλέξτε κλάδο';

  @override
  String get navMeetings => 'Συσκέψεις';

  @override
  String get meetingsNoWorkspace =>
      'Επιλέξτε χώρο εργασίας για να δείτε συσκέψεις.';

  @override
  String get meetingsEmpty => 'Δεν υπάρχουν ακόμη συσκέψεις';

  @override
  String get meetingsEmptyHint =>
      'Εγγράψτε την πρώτη σας σύσκεψη — ο ήχος μένει σε αυτή τη συσκευή και ο πράκτορας τον μετατρέπει σε σημειώσεις, αποφάσεις και στοιχεία ενέργειας.';

  @override
  String get meetingNotesHint =>
      'Γράψτε γρήγορες σημειώσεις — ο πράκτορας τις επεκτείνει μετά τη σύσκεψη.';

  @override
  String get meetingSpeakerMe => 'Εσείς';

  @override
  String get meetingStatusRecording => 'Εγγραφή';

  @override
  String get meetingStatusProcessing => 'Επεξεργασία';

  @override
  String get meetingStatusDone => 'Ολοκληρώθηκε';

  @override
  String get meetingStatusFailed => 'Απέτυχε';

  @override
  String get meetingsSubtitle =>
      'Καταγραφή και μεταγραφή σε αυτή τη συσκευή, στη συνέχεια σύνοψη από πράκτορα.';

  @override
  String get meetingsRecordMeeting => 'Εγγραφή σύσκεψης';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count σε επεξεργασία τώρα',
      one: '1 σε επεξεργασία τώρα',
    );
    return '$_temp0';
  }

  @override
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count συσκέψεις',
      one: '1 σύσκεψη',
      zero: 'Καμία σύσκεψη',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'Ανοιχτές ενέργειες';

  @override
  String get meetingsLedgerDecisions => 'Αποφάσεις';

  @override
  String get meetingsLiveOpen => 'Άνοιγμα εγγραφής';

  @override
  String get meetingTemplateShort => 'Πρότυπο';

  @override
  String get meetingsStatThisWeek => 'Αυτή την εβδομάδα';

  @override
  String get meetingsStatRecorded => 'Εγγεγραμμένες';

  @override
  String get meetingsFilterAll => 'Όλες';

  @override
  String get meetingsFilterDone => 'Ολοκληρωμένες';

  @override
  String get meetingsFilterProcessing => 'Σε επεξεργασία';

  @override
  String get meetingsSearchHint => 'Φιλτράρισμα κατά τίτλο, άτομο, εφαρμογή…';

  @override
  String get meetingsBucketToday => 'Σήμερα';

  @override
  String get meetingsBucketYesterday => 'Χθες';

  @override
  String get meetingsBucketEarlierThisWeek => 'Νωρίτερα αυτή την εβδομάδα';

  @override
  String get meetingsBucketLastWeek => 'Την περασμένη εβδομάδα';

  @override
  String get meetingsBucketOlder => 'Παλαιότερα';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count αποφάσεις',
      one: '1 απόφαση',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total στοιχεία ενέργειας';
  }

  @override
  String get meetingsEnhancedPill => 'βελτιωμένο';

  @override
  String get meetingsTranscribing => 'μεταγραφή και σύνοψη…';

  @override
  String get meetingsOpenAction => 'Άνοιγμα';

  @override
  String get meetingsStopProcessing => 'Διακοπή';

  @override
  String get meetingsStillTranscribing =>
      'Ακόμη σε μεταγραφή — η σύνοψη εμφανίζεται όταν τελειώσει.';

  @override
  String get meetingsNoMatch => 'Καμία σύσκεψη δεν ταιριάζει';

  @override
  String get meetingsNoMatchHint =>
      'Δοκιμάστε διαφορετικό φίλτρο ή όρο αναζήτησης.';

  @override
  String get meetingBackAllMeetings => 'Όλες οι συσκέψεις';

  @override
  String get meetingReRunSummary => 'Επανεκτέλεση σύνοψης';

  @override
  String get meetingExport => 'Εξαγωγή';

  @override
  String get meetingAugmentingBanner =>
      'Εμπλουτισμός των σημειώσεών σας από το πρακτικό — εξαγωγή αποφάσεων και στοιχείων ενέργειας…';

  @override
  String get meetingTabNotes => 'Σημειώσεις';

  @override
  String get meetingTabTranscript => 'Πρακτικό';

  @override
  String get meetingTabActionItems => 'Στοιχεία ενέργειας';

  @override
  String get meetingTabDecisions => 'Αποφάσεις';

  @override
  String get meetingNotesEnhancedToggle => 'Βελτιωμένες';

  @override
  String get meetingNotesYoursToggle => 'Οι σημειώσεις σας';

  @override
  String get meetingEnhancedByAgent =>
      'Βελτιώθηκε από πράκτορα · από το πρακτικό';

  @override
  String get meetingEnhancedPending =>
      'Ο πράκτορας εργάζεται ακόμη σε αυτή τη σύνοψη.';

  @override
  String get meetingNotesEmpty => 'Δεν υπάρχουν ακόμη βελτιωμένες σημειώσεις.';

  @override
  String get meetingNotesSavedLocally => 'Αποθηκεύτηκε τοπικά';

  @override
  String get meetingNotesSaving => 'Αποθήκευση…';

  @override
  String get meetingViewFullTranscript => 'Προβολή πλήρους πρακτικού';

  @override
  String get meetingTranscriptSearchHint => 'Αναζήτηση στο πρακτικό…';

  @override
  String get meetingSpeakerEveryone => 'Όλοι';

  @override
  String get meetingSpeakerOthers => 'Άλλοι';

  @override
  String get meetingTranscriptEmpty => 'Δεν υπάρχει ακόμη πρακτικό.';

  @override
  String get meetingActionItemsEmpty => 'Δεν εξήχθησαν στοιχεία ενέργειας.';

  @override
  String get meetingActionItemFrom => 'από αυτή τη σύσκεψη';

  @override
  String get meetingCreateTicket => 'Δημιουργία εισιτηρίου';

  @override
  String meetingTicketCreated(String key) {
    return 'Το εισιτήριο $key δημιουργήθηκε και απεστάλη.';
  }

  @override
  String get meetingTicketFailed =>
      'Δεν ήταν δυνατή η δημιουργία του εισιτηρίου.';

  @override
  String get meetingDecisionsEmpty => 'Δεν καταγράφηκαν αποφάσεις.';

  @override
  String get meetingEditTitle => 'Επεξεργασία τίτλου';

  @override
  String get meetingTitleLabel => 'Τίτλος';

  @override
  String get meetingAddActionItem => 'Προσθήκη στοιχείου ενέργειας';

  @override
  String get meetingEditActionItem => 'Επεξεργασία στοιχείου ενέργειας';

  @override
  String get meetingDeleteActionItem => 'Διαγραφή στοιχείου ενέργειας';

  @override
  String get meetingActionItemContentLabel => 'Στοιχείο ενέργειας';

  @override
  String get meetingActionItemContentHint => 'Τι πρέπει να γίνει;';

  @override
  String get meetingActionItemOwnerLabel => 'Υπεύθυνος';

  @override
  String get meetingActionItemOwnerHint =>
      'Ποιος είναι υπεύθυνος; (προαιρετικά)';

  @override
  String get meetingAddDecision => 'Προσθήκη απόφασης';

  @override
  String get meetingEditDecision => 'Επεξεργασία απόφασης';

  @override
  String get meetingDeleteDecision => 'Διαγραφή απόφασης';

  @override
  String get meetingDecisionContentLabel => 'Απόφαση';

  @override
  String get meetingDecisionContentHint => 'Τι αποφασίστηκε;';

  @override
  String get meetingReRunStarted => 'Επανεκτέλεση του συνοψιστή στο πρακτικό…';

  @override
  String get meetingReRunNoTranscript =>
      'Δεν υπάρχει ακόμη πρακτικό για σύνοψη.';

  @override
  String get meetingExportCopied =>
      'Οι σημειώσεις αντιγράφηκαν στο πρόχειρο ως Markdown.';

  @override
  String get meetingExportSaved => 'Η σύσκεψη εξήχθη.';

  @override
  String meetingExportFailed(String error) {
    return 'Η εξαγωγή απέτυχε: ⁨$error⁩';
  }

  @override
  String get meetingExportNothing => 'Δεν υπάρχει ακόμη τίποτα για εξαγωγή.';

  @override
  String get meetingPlaybackPlay => 'Αναπαραγωγή';

  @override
  String get meetingPlaybackPause => 'Παύση';

  @override
  String get meetingPlaybackUnavailable =>
      'Η αναπαραγωγή ήχου δεν είναι διαθέσιμη σε αυτή τη συσκευή.';

  @override
  String get meetingDetectedTitle => 'Ανιχνεύθηκε σύσκεψη';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'Φαίνεται ότι συμβαίνει «$label». Να εγγραφεί;';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'Φαίνεται ότι συμβαίνει σύσκεψη. Να εγγραφεί;';

  @override
  String get meetingDetectedRecord => 'Εγγραφή';

  @override
  String get meetingDetectedDismiss => 'Απόρριψη';

  @override
  String get meetingAutoStopTitle =>
      'Αυτή η σύσκεψη φαίνεται να τελείωσε. Διακοπή εγγραφής;';

  @override
  String get meetingAutoStopStop => 'Διακοπή';

  @override
  String get meetingAutoStopKeep => 'Συνέχεια εγγραφής';

  @override
  String get meetingAutoDetect => 'Αυτόματη ανίχνευση συσκέψεων';

  @override
  String get meetingAutoDetectDescription =>
      'Παρακολούθηση ημερολογίου και εφαρμογών διάσκεψης και προσφορά εγγραφής όταν ξεκινά σύσκεψη.';

  @override
  String get meetingsRecordingCrumb => 'Εγγραφή…';

  @override
  String get meetingRecordTitleHint => 'Τίτλος σύσκεψης';

  @override
  String get meetingRecordTappingLabel => 'Λήψη:';

  @override
  String get meetingRecordMic => 'Μικρόφωνο';

  @override
  String get meetingRecordSystemAudio => 'Ήχος συστήματος';

  @override
  String get meetingRecordPause => 'Παύση';

  @override
  String get meetingRecordResume => 'Συνέχεια';

  @override
  String get meetingRecordStop => 'Διακοπή και σύνοψη';

  @override
  String get meetingRecordYourNotes => 'Οι σημειώσεις σας';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Πληκτρολογήστε καθώς ακούτε. Λίγα αποσπάσματα αρκούν — μετά τη διακοπή, ο πράκτορας τα επεκτείνει με βάση το πρακτικό.';

  @override
  String get meetingRecordLiveTranscript => 'Ζωντανό πρακτικό';

  @override
  String get meetingRecordDecoding => 'αποκωδικοποίηση στη συσκευή';

  @override
  String get meetingRecordListening =>
      'Ακρόαση… η ομιλία εμφανίζεται εδώ σε ένα-δύο δευτερόλεπτα, με ετικέτα Εσείς / Άλλοι.';

  @override
  String get meetingRecordPausedHint =>
      'Σε παύση — ο ήχος αγνοείται μέχρι να συνεχίσετε.';

  @override
  String get meetingRecordNotActive => 'Δεν υπάρχει ενεργή εγγραφή.';

  @override
  String get meetingHudRecording => 'εγγραφή';

  @override
  String get meetingHudPaused => 'σε παύση';

  @override
  String get meetingHudOpen => 'Άνοιγμα';

  @override
  String get meetingHudStop => 'Διακοπή';

  @override
  String get meetingToolbarPopOut => 'Απόσπαση';

  @override
  String get meetingToolbarHoldToStop => 'Κρατήστε για διακοπή εγγραφής';

  @override
  String get meetingToolbarSemanticLabel =>
      'Γραμμή εργαλείων εγγραφής σύσκεψης';

  @override
  String get orchestrate => 'Ενορχήστρωση';

  @override
  String get orchestrationUnavailable => 'Η ενορχήστρωση δεν είναι διαθέσιμη';

  @override
  String get orchestrationApprove => 'Έγκριση σχεδίου';

  @override
  String get orchestrationReject => 'Απόρριψη';

  @override
  String get orchestrationCancel => 'Ακύρωση ενορχήστρωσης';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count ρόλοι — $hires νέες προσλήψεις';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count υποεισιτήρια';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Εκτιμώμενο κόστος: \$$amount';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total υποεισιτήρια ολοκληρώθηκαν';
  }

  @override
  String get orchestrationStatusProposed => 'Προτάθηκε';

  @override
  String get orchestrationStatusApproved => 'Εγκρίθηκε';

  @override
  String get orchestrationStatusExecuting => 'Εκτέλεση';

  @override
  String get orchestrationStatusSynthesizing => 'Σύνθεση';

  @override
  String get orchestrationStatusCompleted => 'Ολοκληρώθηκε';

  @override
  String get orchestrationStatusFailed => 'Απέτυχε';

  @override
  String get orchestrationStatusCancelled => 'Ακυρώθηκε';

  @override
  String get messageFailed => 'Η εκτέλεση απέτυχε';

  @override
  String get turnLimitReached =>
      'Σταμάτησε στο όριο σειρών — απαντήστε για συνέχεια';

  @override
  String get retried => 'Επαναλήφθηκε';

  @override
  String replyingTo(String name) {
    return 'απάντηση στον/στην $name';
  }

  @override
  String get silenceTimeoutLabel => 'Χρονικό όριο σιωπής (λεπτά)';

  @override
  String get silenceTimeoutHint =>
      'π.χ. 15 — τερματισμός εκτέλεσης μετά από τόσο χρόνο χωρίς έξοδο';

  @override
  String get capabilityJsonMode => 'Λειτουργία JSON';

  @override
  String get capabilityModelSelection => 'Επιλογή μοντέλου';

  @override
  String get transcriptThinking => 'Σκέψη…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'Σκέφτηκε για $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'Επεξεργασία…';

  @override
  String get transcriptStatusReadingFiles => 'Ανάγνωση αρχείων…';

  @override
  String get transcriptStatusSearching => 'Αναζήτηση στον κώδικα…';

  @override
  String get transcriptStatusRunningCommands => 'Εκτέλεση εντολών…';

  @override
  String get transcriptStatusResponding => 'Απάντηση…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'Εκτέλεση $tool…';
  }

  @override
  String get transcriptInput => 'Είσοδος';

  @override
  String get transcriptOutput => 'Έξοδος';

  @override
  String get transcriptErrorLabel => 'Σφάλμα';

  @override
  String get transcriptSandboxBlocked => 'Το sandbox απέκλεισε μια ενέργεια';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'Εμφάνιση πλήρους εξόδου (+$kb KB)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'Εμφάνιση και των $count γραμμών';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'Εμφάνιση των πρώτων $count γραμμών';
  }

  @override
  String get transcriptGrepNoMatches => 'Κανένα αποτέλεσμα';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches αντιστοιχίες',
      one: '1 αντιστοιχία',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files αρχεία',
      one: '1 αρχείο',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'Άτομο $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'Μετονομασία ομιλητή';

  @override
  String get meetingRenameSpeakerTitle => 'Μετονομασία ομιλητή';

  @override
  String get meetingSpeakerNameLabel => 'Όνομα';

  @override
  String get meetingSpeakerSuggestFromCalendar =>
      'Από τους προσκεκλημένους αυτής της σύσκεψης';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'Εφαρμογή σε όλα τα μπλοκ αυτού του ομιλητή';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'Όταν είναι απενεργοποιημένο, μετονομάζεται μόνο η επιλεγμένη γραμμή.';

  @override
  String get meetingLinkEvent => 'Σύνδεση με γεγονός';

  @override
  String get meetingChangeEvent => 'Αλλαγή γεγονότος';

  @override
  String get meetingLinkEventTitle => 'Σύνδεση με γεγονός ημερολογίου';

  @override
  String get meetingLinkEventSearchHint => 'Αναζήτηση γεγονότων';

  @override
  String get meetingLinkEventEmpty =>
      'Δεν υπάρχουν κοντινά γεγονότα ημερολογίου';

  @override
  String get meetingUnlinkEvent => 'Αφαίρεση συνδέσμου';

  @override
  String get calendarLinkExistingMeeting => 'Σύνδεση με υπάρχουσα σύσκεψη';

  @override
  String get calendarLinkMeetingTitle => 'Σύνδεση σύσκεψης';

  @override
  String get calendarLinkMeetingSearchHint => 'Αναζήτηση συσκέψεων';

  @override
  String get calendarLinkMeetingEmpty => 'Δεν υπάρχουν συσκέψεις για σύνδεση';

  @override
  String get meetingRenameSpeakerFailed =>
      'Δεν ήταν δυνατή η μετονομασία του ομιλητή';

  @override
  String get calendarLinkUpdateFailed =>
      'Δεν ήταν δυνατή η ενημέρωση του συνδέσμου ημερολογίου';

  @override
  String get rename => 'Μετονομασία';

  @override
  String get notNow => 'Όχι τώρα';

  @override
  String get meetingSaveVoiceProfileTitle => 'Αποθήκευση προφίλ φωνής;';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'Αναγνώριση του/της $name αυτόματα σε μελλοντικές συσκέψεις αποθηκεύοντας το αποτύπωμα φωνής του/της.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'Αποθηκεύτηκε προφίλ φωνής για $name';
  }

  @override
  String get meetingVoiceProfileSaveFailed =>
      'Δεν ήταν δυνατή η αποθήκευση του προφίλ φωνής';

  @override
  String get voiceProfilesSection => 'Προφίλ φωνής';

  @override
  String get voiceProfilesDescription =>
      'Οι αποθηκευμένες φωνές αναγνωρίζονται αυτόματα σε μελλοντικές συσκέψεις.';

  @override
  String get voiceProfilesEmpty =>
      'Δεν υπάρχουν ακόμη αποθηκευμένες φωνές. Ονομάστε έναν ομιλητή σε πρακτικό σύσκεψης και επιλέξτε «Αποθήκευση προφίλ φωνής».';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count δείγματα',
      one: '1 δείγμα',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'Μετονομασία προφίλ φωνής';

  @override
  String get deleteVoiceProfileTitle => 'Διαγραφή προφίλ φωνής;';

  @override
  String deleteVoiceProfileBody(String name) {
    return 'Διακοπή αναγνώρισης του/της $name; Το αποθηκευμένο αποτύπωμα φωνής αφαιρείται. Τα ονόματα που έχουν ήδη εφαρμοστεί σε προηγούμενες συσκέψεις διατηρούνται.';
  }

  @override
  String get connectedLabel => 'Συνδεδεμένο';

  @override
  String get ideTabGeneral => 'Γενικά';

  @override
  String get ideTabExplorer => 'Εξερευνητής';

  @override
  String get ideTabSourceControl => 'Έλεγχος εκδόσεων';

  @override
  String get generalSectionTodos => 'Εκκρεμότητες';

  @override
  String get generalSectionGoals => 'Στόχοι';

  @override
  String get goalRunStatusActive => 'Ενεργός';

  @override
  String get goalRunStatusPaused => 'Σε παύση';

  @override
  String get goalRunStatusCompleted => 'Ολοκληρώθηκε';

  @override
  String get goalRunStatusFailed => 'Απέτυχε';

  @override
  String get goalRunStatusCancelled => 'Ακυρώθηκε';

  @override
  String get goalRunStatusBudgetExhausted => 'Ο προϋπολογισμός εξαντλήθηκε';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'Εκτέλεση $run από $max · $cost από $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'Εκτέλεση $run · $cost από $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'Προθεσμία $deadline';
  }

  @override
  String get goalRunPause => 'Παύση στόχου';

  @override
  String get goalRunResume => 'Συνέχεια στόχου';

  @override
  String goalRunResumeRaise(String cap) {
    return 'Συνέχεια · αύξηση ορίου σε $cap';
  }

  @override
  String get goalRunStop => 'Διακοπή στόχου';

  @override
  String get generalSectionAgents => 'Πράκτορες';

  @override
  String get generalSectionTerminals => 'Τερματικά';

  @override
  String get generalTodosEmpty => 'Δεν υπάρχουν ακόμη εκκρεμότητες';

  @override
  String get generalAgentsEmpty => 'Κανένας πράκτορας σε εκτέλεση';

  @override
  String get generalTerminalsEmpty => 'Κανένα ανοιχτό τερματικό';

  @override
  String get generalSectionBrowsers => 'Περιηγητές';

  @override
  String get generalSectionComputers => 'Υπολογιστές';

  @override
  String get generalBrowsersEmpty => 'Κανένας ανοιχτός περιηγητής';

  @override
  String get generalComputersEmpty => 'Κανένας ανοιχτός υπολογιστής';

  @override
  String get generalSectionPhones => 'Τηλέφωνα';

  @override
  String get generalPhonesEmpty => 'Κανένα ανοιχτό τηλέφωνο';

  @override
  String get pauseAgent => 'Παύση πράκτορα';

  @override
  String get resumeAgent => 'Συνέχεια πράκτορα';

  @override
  String get agentCannotPause =>
      'Αυτός ο πράκτορας δεν μπορεί να τεθεί σε παύση — διακόψτε τον αντί αυτού.';

  @override
  String get goalClear => 'Καθαρισμός στόχου';

  @override
  String get undoLabelGoalClear => 'καθαρισμός στόχου';

  @override
  String get todoStatusPending => 'Δεν ξεκίνησε';

  @override
  String get todoStatusInProgress => 'Σε εξέλιξη';

  @override
  String get todoStatusCompleted => 'Ολοκληρώθηκε';

  @override
  String get reorderTodo => 'Αναδιάταξη εκκρεμότητας';

  @override
  String get focusTerminal => 'Εστίαση στο τερματικό';

  @override
  String get focusMachine => 'Εστίαση στη μηχανή';

  @override
  String get focusBrowser => 'Εστίαση στον περιηγητή';

  @override
  String get todoEditorTitle => 'Επεξεργασία εκκρεμοτήτων';

  @override
  String get todoEditorHint =>
      'Ένα στοιχείο ανά γραμμή. Χρησιμοποιήστε - [ ] για εκκρεμές, - [~] για σε εξέλιξη, - [x] για ολοκληρωμένο.';

  @override
  String get todoNeedsText => 'Προσθέστε κείμενο μετά την εντολή';

  @override
  String get todoNotFound => 'Καμία αντίστοιχη εκκρεμότητα';

  @override
  String get todoCleared => 'Η λίστα εκκρεμοτήτων καθαρίστηκε';

  @override
  String get todoNothingToCopy => 'Δεν υπάρχει τίποτα για αντιγραφή';

  @override
  String todoAdded(String content) {
    return 'Προστέθηκε «$content»';
  }

  @override
  String todoStarted(String content) {
    return 'Ξεκίνησε «$content»';
  }

  @override
  String todoCompleted(String content) {
    return 'Ολοκληρώθηκε «$content»';
  }

  @override
  String todoRemoved(String content) {
    return 'Αφαιρέθηκε «$content»';
  }

  @override
  String todoCopied(int count) {
    return 'Αντιγράφηκαν $count στοιχεία';
  }

  @override
  String todoImported(int count) {
    return 'Εισήχθησαν $count στοιχεία';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'Άγνωστη εντολή εκκρεμότητας «$name»';
  }

  @override
  String get terminal => 'Τερματικό';

  @override
  String get ideCloseTab => 'Κλείσιμο καρτέλας';

  @override
  String get ideSplitEditor => 'Διαχωρισμός επεξεργαστή';

  @override
  String get ideSplitRight => 'Διαχωρισμός δεξιά';

  @override
  String get ideSplitDown => 'Διαχωρισμός κάτω';

  @override
  String get ideSplitLeft => 'Διαχωρισμός αριστερά';

  @override
  String get ideSplitUp => 'Διαχωρισμός επάνω';

  @override
  String get ideCloseGroup => 'Κλείσιμο ομάδας';

  @override
  String get ideCloseOthers => 'Κλείσιμο των άλλων';

  @override
  String get ideCloseToRight => 'Κλείσιμο προς τα δεξιά';

  @override
  String get ideCloseSaved => 'Κλείσιμο αποθηκευμένων';

  @override
  String get ideCloseAll => 'Κλείσιμο όλων';

  @override
  String get ideSplit => 'Διαχωρισμός';

  @override
  String get ideToggleSidebar => 'Εναλλαγή πλαϊνής γραμμής';

  @override
  String get ideNewTab => 'Άνοιγμα επεξεργαστή';

  @override
  String get ideNewTabMenu => 'Νέα καρτέλα';

  @override
  String get ideReviewCode => 'Ανασκόπηση κώδικα';

  @override
  String ideReviewCodeInRepo(String repo) {
    return 'Ανασκόπηση κώδικα ($repo)';
  }

  @override
  String get ideRevertConfirmTitle => 'Επαναφορά αλλαγών';

  @override
  String get ideRevertUntracked =>
      'Τα μη παρακολουθούμενα αρχεία δεν μπορούν να επαναφερθούν';

  @override
  String get ideRevertFailed =>
      'Δεν ήταν δυνατή η επαναφορά των αρχείων. Το worktree της συνομιλίας μπορεί να μην είναι διαθέσιμο.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count αρχεία',
      one: '1 αρχείο',
    );
    return '$_temp0 δεν μπόρεσαν να επαναφερθούν (μη παρακολουθούμενα).';
  }

  @override
  String get ideSearchMatchCase => 'Διάκριση πεζών/κεφαλαίων';

  @override
  String get ideSearchWholeWord => 'Ολόκληρη λέξη';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'Φίλτρα αναζήτησης';

  @override
  String get ideSearchFilesToInclude => 'Αρχεία προς συμπερίληψη';

  @override
  String get ideSearchFilesToExclude => 'Αρχεία προς εξαίρεση';

  @override
  String get ideNoOpenTabs =>
      'Καμία ανοιχτή καρτέλα — χρησιμοποιήστε + για άνοιγμα';

  @override
  String get ideBrowserAddressHint => 'Εισαγάγετε διεύθυνση ή αναζήτηση';

  @override
  String get ideSimpleWebBrowser => 'Απλός περιηγητής ιστού';

  @override
  String get ideWebBrowser => 'Περιηγητής ιστού';

  @override
  String get ideBrowserEnterUrl =>
      'Εισαγάγετε URL στη γραμμή διευθύνσεων για να ξεκινήσετε την περιήγηση';

  @override
  String get ideCodeServer => 'Επεξεργαστής';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'Αποθήκευση αλλαγών στο ⁨$fileName⁩;';
  }

  @override
  String get ideUnsavedChangesBody =>
      'Οι αλλαγές σας θα χαθούν αν δεν τις αποθηκεύσετε.';

  @override
  String get ideDontSave => 'Χωρίς αποθήκευση';

  @override
  String get editorAutoSave => 'Αυτόματη αποθήκευση';

  @override
  String get editorAutoSaveDescription =>
      'Αυτόματη αποθήκευση αλλαγών στον ενσωματωμένο επεξεργαστή.';

  @override
  String get editorAutoSaveOff => 'Ανενεργή';

  @override
  String get editorAutoSaveAfterDelay => 'Μετά από καθυστέρηση';

  @override
  String get editorAutoSaveOnFocusChange => 'Στην αλλαγή εστίασης';

  @override
  String get ideCodeServerUnavailable =>
      'Το code-server δεν είναι διαθέσιμο σε αυτόν τον διακομιστή';

  @override
  String get ideCodeServerUnavailableHint =>
      'Εγκαταστήστε το code-server (coder/code-server) στον κεντρικό του διακομιστή και ανοίξτε ξανά τον επεξεργαστή.';

  @override
  String get ideCodeServerInstalling => 'Προετοιμασία επεξεργαστή…';

  @override
  String get ideCodeServerOpenInBrowser =>
      'Άνοιγμα επεξεργαστή στο πρόγραμμα περιήγησης';

  @override
  String get ideCodeServerError => 'Δεν ήταν δυνατό το άνοιγμα του επεξεργαστή';

  @override
  String get paneSuspendedCaption =>
      'Σε αναστολή για εξοικονόμηση πόρων — επαναφορτώνεται όταν εστιάζεται';

  @override
  String get ideFolderLoadFailed =>
      'Δεν ήταν δυνατή η φόρτωση αυτού του φακέλου';

  @override
  String get ideFileSearchFailed => 'Δεν ήταν δυνατή η αναζήτηση αρχείων';

  @override
  String get ideSearchInFiles => 'Αναζήτηση σε αρχεία';

  @override
  String get ideNoContentMatches => 'Κανένα αποτέλεσμα';

  @override
  String get ideSourceControlCreatePr => 'Δημιουργία pull request';

  @override
  String ideSourceControlViewPr(int number) {
    return 'Προβολή pull request #$number';
  }

  @override
  String get ideSourceControlNoChanges => 'Καμία αλλαγή';

  @override
  String get noReposInConversation =>
      'Δεν υπάρχουν αποθετήρια σε αυτή τη συνομιλία';

  @override
  String get ideSourceControlNoSpace =>
      'Ανοίξτε μια συνομιλία για να δείτε τις αλλαγές της';

  @override
  String get ideFileLoading => 'Φόρτωση…';

  @override
  String get ideFileBinary => 'Δυαδικό αρχείο';

  @override
  String get mcpExternalServers => 'Εξωτερικοί διακομιστές MCP';

  @override
  String get mcpExternalServersDescription =>
      'Συνδεθείτε σε εξωτερικούς διακομιστές MCP (GitHub, Sentry, Postgres, αυτοματοποίηση περιηγητή). Οι διακομιστές που ρυθμίσατε για Claude, Cursor, VS Code και άλλα εργαλεία ανακαλύπτονται αυτόματα.';

  @override
  String get mcpApprovalMode => 'Έγκριση εργαλείων';

  @override
  String get mcpApprovalModeDescription =>
      'Ποιες ενέργειες εργαλείων εκτελούνται χωρίς ερώτηση. Οι αναγνώσεις επιτρέπονται πάντα· υψηλότερα επίπεδα ζητούν επιβεβαίωση.';

  @override
  String get mcpApprovalAlwaysAsk => 'Ερώτηση πάντα';

  @override
  String get mcpApprovalWrite => 'Αυτόματη έγκριση εγγραφών';

  @override
  String get mcpApprovalYolo => 'Αυτόματη έγκριση όλων';

  @override
  String get mcpNoExternalServers =>
      'Δεν ανακαλύφθηκαν εξωτερικοί διακομιστές MCP.';

  @override
  String get mcpAuthorize => 'Εξουσιοδότηση';

  @override
  String get mcpReconnect => 'Επανασύνδεση';

  @override
  String get mcpExternalConnectionsNote =>
      'Οι εξωτερικοί διακομιστές MCP εκτελούνται στον διακομιστή πρακτόρων (κοινόχρηστοι από επιφάνεια εργασίας και ιστό). Η εξουσιοδότηση διακομιστών OAuth είναι διαθέσιμη μόνο στην επιφάνεια εργασίας.';

  @override
  String get mcpStatusConnected => 'Συνδεδεμένο';

  @override
  String get mcpStatusConnecting => 'Σύνδεση…';

  @override
  String get mcpStatusNeedsAuth => 'Χρειάζεται εξουσιοδότηση';

  @override
  String get mcpStatusFailed => 'Απέτυχε';

  @override
  String get mcpStatusCircuitOpen => 'Σε παύση';

  @override
  String get mcpStatusDisabled => 'Απενεργοποιημένο';

  @override
  String get providersAndModels => 'Πάροχοι και μοντέλα';

  @override
  String get providersAndModelsDescription =>
      'Καταγράψτε κάθε πάροχο που μπορεί να χρησιμοποιήσει ο ενσωματωμένος πράκτορας — ορίστε κλειδί API ή συνδεθείτε με το πρόγραμμα περιήγησης, δείτε τα μοντέλα και τις τιμές κάθε συνδεδεμένου παρόχου και ελέγξτε ποιους παρόχους μπορεί να χρησιμοποιεί αυτός ο χώρος εργασίας.';

  @override
  String get syncNow => 'Συγχρονισμός τώρα';

  @override
  String syncNowResult(int applied, int failed) {
    return 'Ο συγχρονισμός ολοκληρώθηκε — $applied εφαρμόστηκαν, $failed απέτυχαν';
  }

  @override
  String syncNowFailed(String error) {
    return 'Ο συγχρονισμός απέτυχε: ⁨$error⁩';
  }

  @override
  String get denied => 'Απορρίφθηκε';

  @override
  String get allowed => 'Επιτρέπεται';

  @override
  String allowProviderSemantic(String provider) {
    return 'Να επιτρέπεται ο $provider';
  }

  @override
  String enabledViaEnv(String key) {
    return 'Ενεργοποιήθηκε μέσω ⁨$key⁩';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output ανά 1M';
  }

  @override
  String contextTokens(String tokens) {
    return '$tokens πλαίσιο';
  }

  @override
  String get usageAndCost => 'Χρήση και κόστος';

  @override
  String get usageAndCostDescription =>
      'Δαπάνη των πρακτόρων σας τις τελευταίες 7 ημέρες, από παρατηρούμενα κόστη εκτελέσεων.';

  @override
  String get noUsageYet => 'Δεν έχει καταγραφεί ακόμη χρήση.';

  @override
  String get spentThisWeek => 'δαπανήθηκαν αυτή την εβδομάδα';

  @override
  String get subscriptionUsage => 'Χρήση συνδρομής';

  @override
  String get subscriptionUsageUnavailable => 'Μη διαθέσιμη';

  @override
  String get subscriptionUsageExhausted => 'Το όριο εξαντλήθηκε';

  @override
  String get subscriptionUsageSignInRequired => 'Συνδεθείτε ξανά';

  @override
  String get subscriptionUsageSignInExpired =>
      'Η σύνδεση έληξε, ανανεώνεται στην επόμενη εκτέλεση';

  @override
  String get subscriptionUsagePartiallyAvailable => 'Μερικώς διαθέσιμη';

  @override
  String resetsIn(String duration) {
    return 'Επαναφορά σε $duration';
  }

  @override
  String get feedbackHelpful => 'Αυτό ήταν χρήσιμο';

  @override
  String get feedbackNotHelpful => 'Αυτό δεν ήταν χρήσιμο';

  @override
  String get modeChat => 'Συνομιλία';

  @override
  String get modePlan => 'Σχέδιο';

  @override
  String get modeReview => 'Ανασκόπηση';

  @override
  String get modeOrchestrate => 'Ενορχήστρωση';

  @override
  String get editorTheme => 'Θέμα επεξεργαστή';

  @override
  String get editorThemeDescription =>
      'Εισαγάγετε θέμα χρωμάτων VS Code ώστε το ενσωματωμένο diff και ο επεξεργαστής να ταιριάζουν με το IDE σας.';

  @override
  String get editorThemePasteHint =>
      'Επικολλήστε τα περιεχόμενα αρχείου JSON θέματος χρωμάτων VS Code';

  @override
  String get editorThemeImported => 'Το θέμα εισήχθη';

  @override
  String get editorThemeInvalid => 'Αυτό δεν μοιάζει με έγκυρο θέμα VS Code';

  @override
  String get importTheme => 'Εισαγωγή θέματος';

  @override
  String get clearTheme => 'Καθαρισμός θέματος';

  @override
  String get openInDiffViewer => 'Άνοιγμα στον προβολέα diff';

  @override
  String get shellCommand => 'Εντολή';

  @override
  String get shellOutput => 'Έξοδος';

  @override
  String get revertToHere => 'Επαναφορά έως εδώ';

  @override
  String get revertConfirmBody =>
      'Απόκρυψη των μηνυμάτων μετά από αυτό το σημείο και επαναφορά των αλλαγών αρχείων του πράκτορα σε αυτή τη σειρά; Μπορείτε να το αναιρέσετε.';

  @override
  String get revert => 'Επαναφορά';

  @override
  String get revertedToHere => 'Επαναφορά έως εδώ';

  @override
  String get nothingToRevert => 'Δεν υπάρχει τίποτα για επαναφορά';

  @override
  String get undoRevert => 'Αναίρεση επαναφοράς';

  @override
  String get revertUndone => 'Η επαναφορά αναιρέθηκε';

  @override
  String get systemBehavior => 'Συμπεριφορά συστήματος';

  @override
  String get keepAwakeTitle =>
      'Διατήρηση του υπολογιστή σε εγρήγορση όσο εκτελούνται πράκτορες';

  @override
  String get keepAwakeOnSubtitle =>
      'Ο υπολογιστής δεν θα κοιμηθεί όσο εργάζεται ένας πράκτορας';

  @override
  String get keepAwakeOffSubtitle =>
      'Ο υπολογιστής μπορεί να κοιμηθεί ακόμη και ενώ εργάζεται ένας πράκτορας';

  @override
  String get syncEngineSectionTitle => 'Μηχανή συγχρονισμού';

  @override
  String get syncEngineDescription =>
      'Εισιτήρια, μηνύματα και σημειώσεις ενημερώνονται ζωντανά μέσω μικρών προσαυξητικών αλλαγών αντί για πλήρη στιγμιότυπα. Η απενεργοποίηση ενός διακόπτη επιστρέφει αυτό το κατάστημα σε λειτουργία πλήρους στιγμιότυπου — επαναφορτώστε την εφαρμογή για να ισχύσει.';

  @override
  String get syncEngineTicketsTitle => 'Εισιτήρια';

  @override
  String get syncEngineMessagingTitle => 'Μηνύματα';

  @override
  String get syncEngineNotesTitle => 'Σημειώσεις';

  @override
  String get syncEngineOnSubtitle =>
      'Ο ζωντανός συγχρονισμός delta είναι ενεργός';

  @override
  String get syncEngineOffSubtitle => 'Χρήση συγχρονισμού πλήρους στιγμιότυπου';

  @override
  String get spaces => 'Χώροι';

  @override
  String get spacesHomeDescription =>
      'Επιλέξτε χώρο από τη λίστα ή ξεκινήστε έναν νέο.';

  @override
  String get noSpacesYet => 'Δεν υπάρχουν ακόμη χώροι';

  @override
  String get newSpace => 'Νέος χώρος';

  @override
  String get spaceName => 'Όνομα χώρου';

  @override
  String get spaceReposHint => 'Αποθετήρια προς συμπερίληψη';

  @override
  String get ideSourceControl => 'Έλεγχος εκδόσεων';

  @override
  String get stagedChanges => 'Προετοιμασμένες αλλαγές';

  @override
  String get changes => 'Αλλαγές';

  @override
  String get stageFile => 'Προετοιμασία';

  @override
  String get unstageFile => 'Αφαίρεση από προετοιμασία';

  @override
  String get stageAll => 'Προετοιμασία όλων των αλλαγών';

  @override
  String get unstageAll => 'Αφαίρεση όλων από προετοιμασία';

  @override
  String get stageChangesToCommit => 'Προετοιμασία αλλαγών για commit';

  @override
  String get syncToPrHead => 'Λήψη των τελευταίων commits του PR';

  @override
  String get syncedToPrHead => 'Συγχρονίστηκε με τα τελευταία commits του PR';

  @override
  String get syncPrHeadDirty =>
      'Κάντε commit ή απορρίψτε τις αλλαγές σας πριν τον συγχρονισμό';

  @override
  String get syncPrHeadFailed =>
      'Δεν ήταν δυνατός ο συγχρονισμός με το head του PR';

  @override
  String get spaceLabel => 'Χώρος';

  @override
  String get keybindingNewSpace => 'Νέος χώρος';

  @override
  String get keybindingCreateANewSpaceDescription => 'Δημιουργία νέου χώρου';

  @override
  String get jumpToLatest => 'Μετάβαση στα πιο πρόσφατα';

  @override
  String get streaming => 'Ροή';

  @override
  String get newMessages => 'Νέα';

  @override
  String get copyLink => 'Αντιγραφή συνδέσμου';

  @override
  String get linkCopied => 'Ο σύνδεσμος αντιγράφηκε';

  @override
  String get agentResponding => 'Ο πράκτορας απαντά';

  @override
  String get agentFinished => 'Ο πράκτορας ολοκλήρωσε';

  @override
  String get harnessConnectProviderForModels =>
      'Συνδέστε έναν πάροχο για να δείτε μοντέλα.';

  @override
  String get providerSignOut => 'Αποσύνδεση';

  @override
  String get providerWaitingForDeviceCode =>
      'Αναμονή να επιβεβαιώσετε τον κωδικό στο πρόγραμμα περιήγησης…';

  @override
  String get providerDeviceCodeHint =>
      'Ελέγξτε ότι αυτός ο κωδικός ταιριάζει με αυτόν στο πρόγραμμα περιήγησης και εγκρίνετε.';

  @override
  String get providerPlanUsageLoading => 'Έλεγχος χρήσης πλάνου…';

  @override
  String get providerPlanUsageUnavailable => 'Αυτό το πλάνο δεν ανέφερε χρήση.';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return 'Αφαίρεση του κλειδιού API του $provider;';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'Το αποθηκευμένο κλειδί διαγράφεται και δεν μπορεί να εμφανιστεί ξανά. Οι πράκτορες που χρησιμοποιούν μοντέλα $provider σταματούν μέχρι να επικολλήσετε ένα νέο.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return 'Αφαίρεση του $provider;';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'Ο πάροχος $provider και το αποθηκευμένο κλειδί του διαγράφονται. Οι πράκτορες δεσμευμένοι στα μοντέλα του σταματούν.';
  }

  @override
  String get providerApiKeyHint => 'Επικολλήστε κλειδί API';

  @override
  String get providerApiKeyStoredHint =>
      'Επικολλήστε άλλο κλειδί API για να το προσθέσετε';

  @override
  String get providerAddAnotherAccount => 'Προσθήκη άλλου λογαριασμού';

  @override
  String get providerActiveBadge => 'Ενεργός';

  @override
  String get providerOauthAccountFallback => 'Λογαριασμός OAuth';

  @override
  String get providerApiKeyFallback => 'Κλειδί API';

  @override
  String get providerRemoveCredentialConfirmTitle =>
      'Αφαίρεση αυτών των διαπιστευτηρίων;';

  @override
  String get providerSignOutAccountConfirmTitle =>
      'Αποσύνδεση από αυτόν τον λογαριασμό;';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'Οι πράκτορες που χρησιμοποιούν $provider επιστρέφουν στα άλλα κλειδιά και λογαριασμούς του. Αν δεν μείνει κανένα, σταματούν μέχρι να προσθέσετε ένα.';
  }

  @override
  String get providerBaseUrlHint => 'Base URL (προαιρετικά)';

  @override
  String get addProvider => 'Προσθήκη παρόχου';

  @override
  String get noCustomProviders => 'Δεν υπάρχουν ακόμη προσαρμοσμένοι πάροχοι.';

  @override
  String get providerNameLabel => 'Όνομα';

  @override
  String get apiTypeLabel => 'Τύπος API';

  @override
  String get providerBaseUrlLabel => 'Base URL';

  @override
  String get providerApiKeyOptionalHint => 'Κλειδί API (προαιρετικά)';

  @override
  String get dialectOpenAiCompatible => 'Συμβατό με OpenAI';

  @override
  String get dialectAnthropicCompatible => 'Συμβατό με Anthropic';

  @override
  String get removeProviderTooltip => 'Αφαίρεση παρόχου';

  @override
  String get providerLogInWithBrowser => 'Σύνδεση με πρόγραμμα περιήγησης';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'Σύνδεση στο $provider';
  }

  @override
  String get providerLabel => 'Πάροχος';

  @override
  String get selectProviderToLogin => 'Επιλέξτε πάροχο για σύνδεση';

  @override
  String providerLoginFailed(String error) {
    return 'Η σύνδεση απέτυχε: ⁨$error⁩';
  }

  @override
  String get providerWaitingForBrowser =>
      'Αναμονή να εξουσιοδοτήσετε στο πρόγραμμα περιήγησης…';

  @override
  String get providerPasteCodeHint =>
      'Ή επικολλήστε τον κωδικό από το πρόγραμμα περιήγησης';

  @override
  String get providerCompleteLogin => 'Ολοκλήρωση';

  @override
  String get providerConnectedApiKey => 'Συνδεδεμένο μέσω κλειδιού API';

  @override
  String get providerConnectedOauth => 'Συνδεδεμένο';

  @override
  String providerConnectedAccount(String account) {
    return 'Συνδεδεμένο · ⁨$account⁩';
  }

  @override
  String get providerLocalReady => 'Τοπικό · έτοιμο';

  @override
  String get providerNotConnected => 'Δεν είναι συνδεδεμένο';

  @override
  String get preparingWorkspace => 'Προετοιμασία χώρου εργασίας…';

  @override
  String provisioningRunningSetupScript(String repo) {
    return 'Εκτέλεση του σεναρίου ρύθμισης για το ⁨$repo⁩…';
  }

  @override
  String get repoScriptsTitle => 'Σενάρια';

  @override
  String get repoScriptsTooltip => 'Ρύθμιση σεναρίων κύκλου ζωής';

  @override
  String get repoScriptsSetupLabel => 'Σενάριο ρύθμισης';

  @override
  String get repoScriptsSetupHelp =>
      'Εκτελείται στο worktree του χώρου αμέσως μετά τη δημιουργία — εγκατάσταση εξαρτήσεων, δημιουργία αρχείων. Η αποτυχία σημειώνει τον χώρο ως αποτυχημένο· η επανάληψη το εκτελεί ξανά.';

  @override
  String get repoScriptsArchiveLabel => 'Σενάριο αρχειοθέτησης';

  @override
  String get repoScriptsArchiveHelp =>
      'Εκτελείται λίγο πριν διαγραφεί το worktree ενός χώρου — καθαρισμός πόρων εκτός του worktree. Η αποτυχία δεν εμποδίζει ποτέ τη διαγραφή.';

  @override
  String get repoScriptsEnvHelp =>
      'Εκτελείται μέσω bash από το worktree, με CC_WORKSPACE_PATH (το worktree), CC_ROOT_PATH (η ρίζα του αποθετηρίου), CC_SPACE_ID, CC_SPACE_NAME και CC_REPO_NAME ορισμένα.';

  @override
  String get repoScriptsSetupPlaceholder => 'π.χ. ⁨pnpm install⁩';

  @override
  String get repoScriptsArchivePlaceholder =>
      'π.χ. ⁨docker compose -p \$CC_SPACE_ID down⁩';

  @override
  String get repoScriptsRecentRuns => 'Πρόσφατες εκτελέσεις';

  @override
  String get repoScriptsNoRuns => 'Δεν υπάρχουν ακόμη εκτελέσεις';

  @override
  String get repoScriptsSaved => 'Τα σενάρια αποθηκεύτηκαν';

  @override
  String get repoScriptsRunKindSetup => 'Ρύθμιση';

  @override
  String get repoScriptsRunKindArchive => 'Αρχειοθέτηση';

  @override
  String get repoScriptsRunStatusRunning => 'Σε εκτέλεση';

  @override
  String get repoScriptsRunStatusSucceeded => 'Επιτυχής';

  @override
  String get repoScriptsRunStatusFailed => 'Απέτυχε';

  @override
  String get repoScriptsRunStatusTimedOut => 'Έληξε';

  @override
  String repoScriptsExitCode(int code) {
    return 'Κωδικός εξόδου $code';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return 'Κλωνοποίηση του ⁨$repo⁩…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'Checkout του pull request στο ⁨$repo⁩…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'Ρύθμιση πράκτορα $agent…';
  }

  @override
  String get workspacePrepFailed => 'Η ρύθμιση του χώρου εργασίας απέτυχε';

  @override
  String get workspacePrepStopped => 'Η ρύθμιση του χώρου εργασίας σταμάτησε';

  @override
  String get stopWorkspacePrep => 'Διακοπή προετοιμασίας';

  @override
  String get stopWorkspacePrepTooltip =>
      'Διακοπή προετοιμασίας αυτού του χώρου εργασίας';

  @override
  String get stopWorkspacePrepConfirm =>
      'Διακοπή προετοιμασίας αυτού του χώρου εργασίας; Η κλωνοποίηση σε εξέλιξη απορρίπτεται — μπορείτε να την ξεκινήσετε ξανά από εδώ.';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count μήνυμα(-τα) θα σταλούν όταν είναι έτοιμο';
  }

  @override
  String get membersNav => 'Μέλη';

  @override
  String get membersSettingsDescription =>
      'Άτομα με πρόσβαση σε αυτόν τον χώρο εργασίας: κατάλογος, προσκλήσεις και ίχνος ελέγχου';

  @override
  String get memberRosterLabel => 'Κατάλογος μελών';

  @override
  String get memberRepoAccessAction => 'Πρόσβαση αποθετηρίου';

  @override
  String memberRepoAccessTitle(String name) {
    return 'Πρόσβαση αποθετηρίου για $name';
  }

  @override
  String get roleOwner => 'Ιδιοκτήτης';

  @override
  String get roleAdmin => 'Διαχειριστής';

  @override
  String get roleMember => 'Μέλος';

  @override
  String get roleViewer => 'Θεατής';

  @override
  String get roleGuest => 'Επισκέπτης';

  @override
  String get removeMemberTitle => 'Αφαίρεση μέλους';

  @override
  String removeMemberConfirm(String name) {
    return 'Αφαίρεση του/της $name από αυτόν τον χώρο εργασίας; Χάνει αμέσως την πρόσβαση.';
  }

  @override
  String get transferOwnershipAction => 'Μεταβίβαση ιδιοκτησίας';

  @override
  String get transferOwnershipTitle => 'Μεταβίβαση ιδιοκτησίας';

  @override
  String transferOwnershipConfirm(String name) {
    return 'Να γίνει ο/η $name ιδιοκτήτης αυτού του χώρου εργασίας; Εσείς γίνεστε διαχειριστής. Μόνο ένας ιδιοκτήτης μπορεί να διαγράψει τον χώρο εργασίας ή να αλλάξει τον ρόλο άλλου διαχειριστή.';
  }

  @override
  String get transferOwnershipCta => 'Μεταβίβαση';

  @override
  String get auditTrailLabel => 'Ίχνος ελέγχου εξουσιοδότησης';

  @override
  String get auditTrailDescription =>
      'Κάθε αποδοχή και άρνηση, αλυσιδωτά με hash ώστε μια τροποποιημένη ή διαγραμμένη καταχώριση να είναι ανιχνεύσιμη.';

  @override
  String get auditVerifyChain => 'Επαλήθευση αλυσίδας';

  @override
  String auditChainIntact(int count) {
    return 'Η αλυσίδα είναι ακέραια — $count καταχωρίσεις επαληθεύτηκαν';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'Η αλυσίδα έσπασε στην καταχώριση $seq: ⁨$reason⁩';
  }

  @override
  String get auditEmpty => 'Δεν έχουν καταγραφεί ακόμη αποφάσεις.';

  @override
  String get auditDenied => 'Απορρίφθηκε';

  @override
  String get auditAllowed => 'Επιτράπηκε';

  @override
  String auditOnBehalfOf(String user) {
    return 'για $user';
  }

  @override
  String get policyTemplatesLabel => 'Πρότυπα πολιτικής';

  @override
  String get policyTemplatesDescription =>
      'Εφαρμόστε μια αρχική στάση ή μετακινήστε μία μεταξύ χώρων εργασίας.';

  @override
  String get policyTemplateStrict => 'Αυστηρό';

  @override
  String get policyTemplateBalanced => 'Ισορροπημένο';

  @override
  String get policyTemplatePermissive => 'Επιτρεπτικό';

  @override
  String get policyTemplateApply => 'Εφαρμογή';

  @override
  String policyTemplateApplied(int count) {
    return 'Εφαρμόστηκαν $count κανόνες';
  }

  @override
  String get policyExport => 'Αντιγραφή πολιτικής';

  @override
  String get policyExported => 'Η πολιτική αντιγράφηκε στο πρόχειρο';

  @override
  String get policyImport => 'Επικόλληση πολιτικής';

  @override
  String policyImported(int count) {
    return 'Εισήχθησαν $count κανόνες';
  }

  @override
  String get approveAndRemember => 'Έγκριση για 8 ώρες';

  @override
  String get approveAndRememberTooltip =>
      'Εγκρίνει αυτή την ενέργεια και σταματά να ρωτά για παρόμοιες σε αυτόν τον χώρο για 8 ώρες. Λήγει από μόνο του.';

  @override
  String get unknownUserLabel => 'Άγνωστος χρήστης';

  @override
  String get inviteMember => 'Πρόσκληση μέλους';

  @override
  String get inviteRepoAccessHeader => 'Πρόσβαση αποθετηρίου';

  @override
  String get inviteRepoAccessExplainer =>
      'Μόνο τα αποθετήρια που επιλέγετε κοινοποιούνται στον προσκεκλημένο, στο επίπεδο που ορίζετε. Όλα τα άλλα μένουν κρυφά.';

  @override
  String get grantLevelRead => 'Ανάγνωση';

  @override
  String get grantLevelReview => 'Ανασκόπηση';

  @override
  String get grantLevelWrite => 'Εγγραφή';

  @override
  String get inviteExpiryLabel => 'Λήγει σε';

  @override
  String get expiryOneDay => '1 ημέρα';

  @override
  String get expirySevenDays => '7 ημέρες';

  @override
  String get expiryThirtyDays => '30 ημέρες';

  @override
  String get createInviteAction => 'Δημιουργία πρόσκλησης';

  @override
  String get inviteOneTimeCodeLabel => 'Κωδικός μίας χρήσης';

  @override
  String get inviteCodeShownOnce =>
      'Αυτός ο κωδικός εμφανίζεται μόνο μία φορά — αντιγράψτε τον τώρα.';

  @override
  String get inviteLinkLabel => 'Σύνδεσμος πρόσκλησης';

  @override
  String get inviteRedeemHint =>
      'Μοιραστείτε τον κωδικό με τον προσκεκλημένο· τον εξαργυρώνει στο URL του διακομιστή σας.';

  @override
  String get inviteScanQr => 'Ή σαρώστε για εξαργύρωση';

  @override
  String get inviteLoopbackWarningTitle =>
      'Η πρόσκληση δείχνει σε τοπική διεύθυνση';

  @override
  String get inviteLoopbackWarningBody =>
      'Συνεργάτες σε άλλα μηχανήματα δεν θα μπορούν να φτάσουν αυτόν τον διακομιστή. Ξεκινήστε σήραγγα (Ρυθμίσεις → Ενσωματώσεις → Κοινή χρήση αυτού του διακομιστή) ή δεσμεύστε στο δίκτυό σας ώστε οι χρήστες εκτός κεντρικού να μπορούν να συνδεθούν.';

  @override
  String get inviteStatusOpen => 'Ανοιχτή';

  @override
  String get inviteStatusUsed => 'Χρησιμοποιήθηκε';

  @override
  String get inviteStatusRevoked => 'Ανακλήθηκε';

  @override
  String get inviteStatusExpired => 'Έληξε';

  @override
  String inviteCreatedTime(String time) {
    return 'Δημιουργήθηκε $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'λήγει $date';
  }

  @override
  String get noActivityYet => 'Δεν υπάρχει ακόμη δραστηριότητα';

  @override
  String get couldNotLoadMembers => 'Δεν ήταν δυνατή η φόρτωση μελών';

  @override
  String get couldNotLoadInvites => 'Δεν ήταν δυνατή η φόρτωση προσκλήσεων';

  @override
  String get couldNotLoadActivity => 'Δεν ήταν δυνατή η φόρτωση δραστηριότητας';

  @override
  String get yourDevices => 'Οι συσκευές σας';

  @override
  String get yourDevicesDescription =>
      'Πελάτες συζευγμένοι με τον λογαριασμό σας σε αυτόν τον διακομιστή.';

  @override
  String get noOwnDevices =>
      'Δεν έχουν συζευχθεί ακόμη συσκευές με τον λογαριασμό σας';

  @override
  String get renameDeviceTitle => 'Μετονομασία συσκευής';

  @override
  String get revokeDeviceTitle => 'Ανάκληση συσκευής';

  @override
  String revokeDeviceConfirm(String label) {
    return 'Ανάκληση του $label; Αποσυνδέεται αμέσως και δεν μπορεί πλέον να φτάσει αυτόν τον διακομιστή.';
  }

  @override
  String devicePairedTime(String time) {
    return 'Σύζευξη $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'Τελευταία εμφάνιση $time';
  }

  @override
  String get deviceNeverSeen => 'Δεν συνδέθηκε ποτέ';

  @override
  String get profileSectionLabel => 'Προφίλ';

  @override
  String get profileSectionDescription =>
      'Πώς εμφανίζεστε στην ομάδα και στη συγγραφή git commit σε αυτόν τον χώρο. Τα κενά κληρονομούν όνομα και email του λογαριασμού.';

  @override
  String get displayNameLabel => 'Εμφανιζόμενο όνομα';

  @override
  String get emailLabel => 'Email';

  @override
  String get gitAuthorNameLabel => 'Όνομα συγγραφέα Git';

  @override
  String get gitAuthorEmailLabel => 'Email συγγραφέα Git';

  @override
  String get profileSaved => 'Το προφίλ αποθηκεύτηκε';

  @override
  String get presenceOnline => 'Σε σύνδεση';

  @override
  String get presenceIdle => 'Αδρανής';

  @override
  String get presenceTyping => 'Πληκτρολογεί…';

  @override
  String get presenceAgentThinking => 'Σκέψη';

  @override
  String get presenceAgentRunning => 'Σε εκτέλεση';

  @override
  String get presenceAgentBlocked => 'Αποκλεισμένος';

  @override
  String get presenceAgentDone => 'Ολοκληρώθηκε';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
  }

  @override
  String get presenceRailLabel => 'Ποιος είναι σε σύνδεση';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'Ενεργοποίηση «μην ενοχλείτε»';

  @override
  String get dndTooltipOff => 'Απενεργοποίηση «μην ενοχλείτε»';

  @override
  String get startPresenting => 'Έναρξη παρουσίασης';

  @override
  String get stopPresenting => 'Διακοπή παρουσίασης';

  @override
  String spotlightPresentingBanner(String name) {
    return 'Ο/Η $name παρουσιάζει';
  }

  @override
  String get spotlightLeave => 'Αποχώρηση';

  @override
  String typingIndicator(String name) {
    return 'Ο/Η $name πληκτρολογεί…';
  }

  @override
  String get ideTabNotes => 'Σημειώσεις';

  @override
  String get ideSidebarAllViews => 'Όλες οι προβολές';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'Όλες οι προβολές ($count κρυφές)';
  }

  @override
  String get ideSidebarPinView => 'Καρφίτσωμα στην πλαϊνή γραμμή';

  @override
  String get ideSidebarUnpinView => 'Ξεκαρφίτσωμα από την πλαϊνή γραμμή';

  @override
  String get notesEmptyHint =>
      'Προσθέστε μια σημείωση για όποιον αναλάβει αυτή τη συνομιλία…';

  @override
  String get notesEditTooltip => 'Επεξεργασία σημείωσης';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'Ενημερώθηκε από $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return 'Ο/Η $name επεξεργάζεται';
  }

  @override
  String get notesSaveFailed => 'Δεν ήταν δυνατή η αποθήκευση της σημείωσης';

  @override
  String get reactionAddTooltip => 'Προσθήκη αντίδρασης';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'Αντίδραση με $emoji';
  }

  @override
  String get reactionThumbsUp => 'Μου αρέσει';

  @override
  String get reactionThumbsDown => 'Δεν μου αρέσει';

  @override
  String get reactionLaugh => 'Γέλιο';

  @override
  String get reactionHooray => 'Ζήτω';

  @override
  String get reactionConfused => 'Σύγχυση';

  @override
  String get reactionHeart => 'Καρδιά';

  @override
  String get reactionRocket => 'Πύραυλος';

  @override
  String get reactionEyes => 'Μάτια';

  @override
  String get commentReact => 'Αντίδραση';

  @override
  String get commentResolveThread => 'Επίλυση νήματος';

  @override
  String get commentReopenThread => 'Επαναφορά νήματος';

  @override
  String get commentCopyLink => 'Αντιγραφή συνδέσμου σχολίου';

  @override
  String get commentCopyMarkdown => 'Αντιγραφή ως Markdown';

  @override
  String get commentCopyThreadMarkdown => 'Αντιγραφή νήματος ως Markdown';

  @override
  String get commentCopyPrompt => 'Αντιγραφή ως προτροπή';

  @override
  String get commentCopyThreadPrompt => 'Αντιγραφή νήματος ως προτροπή';

  @override
  String get commentSendToAgent => 'Αποστολή σε πράκτορα';

  @override
  String get commentDelete => 'Διαγραφή σχολίου';

  @override
  String get commentEdit => 'Επεξεργασία σχολίου';

  @override
  String get commentActions => 'Ενέργειες σχολίου';

  @override
  String get commentDeleteTitle => 'Διαγραφή αυτού του σχολίου;';

  @override
  String get commentDeleteBody => 'Αφαιρείται από το αίτημα έλξης.';

  @override
  String get commentSentToAgent => 'Στάλθηκε στον πράκτορα';

  @override
  String get commentSendFailed =>
      'Δεν ήταν δυνατή η αποστολή του σχολίου σε πράκτορα';

  @override
  String get commentDeleteFailed => 'Δεν ήταν δυνατή η διαγραφή του σχολίου';

  @override
  String get autonomyDialLabel => 'Αυτονομία';

  @override
  String get autonomyProposeOnly => 'Μόνο πρόταση';

  @override
  String get autonomyActWithApproval => 'Ενέργεια με έγκριση';

  @override
  String get autonomyActFreely => 'Ελεύθερη ενέργεια';

  @override
  String get autonomyDefaultOption => 'Προεπιλογή';

  @override
  String get checkerLabel => 'Ελεγκτής';

  @override
  String get checkerNone => 'Κανένας';

  @override
  String get checkerCaption =>
      'Ο ελεγκτής ανασκοπεί τις ολοκληρωμένες εκτελέσεις άλλων πρακτόρων.';

  @override
  String get takeoverTooltip => 'Ανάληψη του worktree';

  @override
  String get takeoverBannerSelf =>
      'Έχετε αναλάβει το worktree αυτής της συνομιλίας';

  @override
  String takeoverBannerOther(String name) {
    return 'Ο/Η $name έχει αναλάβει το worktree αυτής της συνομιλίας';
  }

  @override
  String get handBackButton => 'Επιστροφή';

  @override
  String get handBackDialogTitle => 'Επιστροφή του worktree';

  @override
  String get handBackDialogNoteHint => 'Προαιρετική σημείωση για τον πράκτορα…';

  @override
  String takeoverFailed(String message) {
    return 'Δεν ήταν δυνατή η ανάληψη: ⁨$message⁩';
  }

  @override
  String handBackFailed(String message) {
    return 'Δεν ήταν δυνατή η επιστροφή: ⁨$message⁩';
  }

  @override
  String get planStudioTitle => 'Plan Studio';

  @override
  String get plansTitle => 'Σχέδια';

  @override
  String get plansSubtitle => 'Ενεργά σχέδια, έγγραφα σχεδίων και playbooks';

  @override
  String get plansActiveSection => 'Ενεργά σχέδια';

  @override
  String get plansDocumentsSection => 'Έγγραφα σχεδίων';

  @override
  String get plansPlaybooksSection => 'Playbooks';

  @override
  String get plansNoActive => 'Δεν υπάρχουν ακόμη ενεργά σχέδια.';

  @override
  String get plansNoDocuments => 'Δεν υπάρχουν ακόμη έγγραφα σχεδίων.';

  @override
  String get plansNoPlaybooks => 'Δεν υπάρχουν ακόμη playbooks.';

  @override
  String get planNotFound => 'Το σχέδιο δεν βρέθηκε.';

  @override
  String get planOpenInStudio => 'Άνοιγμα';

  @override
  String get planNodeTitle => 'Τίτλος';

  @override
  String get planNodeDescription => 'Περιγραφή';

  @override
  String get planNodeDescriptionHint => 'Τι πρέπει να κάνει αυτό το βήμα…';

  @override
  String get planNodeApplyDescription => 'Εφαρμογή';

  @override
  String get planNodeRole => 'Ρόλος';

  @override
  String get planNodeDependencies => 'Εξαρτάται από';

  @override
  String get planNodeDependenciesHint => 'Προσθήκη εξάρτησης';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count εξαρτήσεις',
      one: '1 εξάρτηση',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'Χωρίς εξαρτήσεις, οπότε εκτελείται μόλις ξεκινήσει το σχέδιο';

  @override
  String get planNodeOutputSchema => 'Σχήμα εξόδου (JSON)';

  @override
  String get planNodeEstimate => 'Εκτίμηση';

  @override
  String get planNodeProvenance => 'Προέλευση';

  @override
  String get planNodeAlreadyExecuted =>
      'Έχει ήδη εκτελεστεί — η επεξεργασία διακλαδώνει το σχέδιο από εδώ.';

  @override
  String get planNewNodeTitle => 'Νέο βήμα';

  @override
  String get planEstimateNoHistory => 'Δεν υπάρχει ακόμη ιστορικό';

  @override
  String get planEstimateBlastUnknown => 'Ακτίνα επίδρασης: άγνωστη';

  @override
  String get planEstimatePartial => 'μερική';

  @override
  String get planEstimateAction => 'Εκτίμηση';

  @override
  String planEstimateDuration(String range) {
    return 'Διάρκεια $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'Ακτίνα επίδρασης: $files αρχεία, $symbols σύμβολα';
  }

  @override
  String get planApprove => 'Έγκριση σχεδίου';

  @override
  String get planApproveSelectedNodes => 'Έγκριση επιλεγμένων';

  @override
  String get planReject => 'Απόρριψη';

  @override
  String get planCancel => 'Ακύρωση εκτέλεσης';

  @override
  String get planContinueNode => 'Συνέχεια κόμβου';

  @override
  String get planTotalNotEstimated => 'Δεν έχει εκτιμηθεί ακόμη';

  @override
  String get planBudgetExceeded => 'υπέρβαση προϋπολογισμού';

  @override
  String planBudgetCeiling(String amount) {
    return 'προϋπολογισμός ≤ \$$amount';
  }

  @override
  String get planVersionsTitle => 'Εκδόσεις';

  @override
  String get planNoRevisions => 'Δεν υπάρχουν ακόμη αναθεωρήσεις.';

  @override
  String get planDiffIdentical => 'Καμία αλλαγή.';

  @override
  String get planDiffGoalChanged => 'Ο στόχος άλλαξε';

  @override
  String get planDiffBudgetChanged => 'Ο προϋπολογισμός άλλαξε';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'Αλλαγές από v$fromRev σε v$toRev';
  }

  @override
  String planDiffAdded(String node) {
    return 'Προστέθηκε $node';
  }

  @override
  String planDiffRemoved(String node) {
    return 'Αφαιρέθηκε $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return 'Άλλαξε $node: $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'Προστέθηκε ακμή: $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'Αφαιρέθηκε ακμή: $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'Προστέθηκε ρόλος: $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'Αφαιρέθηκε ρόλος: $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'Επανεκχωρήθηκε ρόλος: $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'Το σχέδιο επανασχεδιάστηκε: εγκρίνατε το v$approved, τώρα είναι v$current. Εξετάστε το diff πριν συνεχίσει.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'Πραγματικό κόστος: \$$amount';
  }

  @override
  String get planPlaybookRun => 'Εκτέλεση';

  @override
  String get planPlaybookDelete => 'Διαγραφή playbook';

  @override
  String get planPlaybookProposed =>
      'Προτάθηκε σχέδιο — εγκρίνετέ το στο Plan Studio.';

  @override
  String get planPlaybookAnchorTicket => 'Εισιτήριο άγκυρας';

  @override
  String get planPlaybookPickTicket => 'Επιλέξτε εισιτήριο…';

  @override
  String get planPlaybookProposeRun => 'Πρόταση σχεδίου';

  @override
  String get planPlaybookRepoHint => 'Ένα ID αποθετηρίου';

  @override
  String get planPlaybookAgentHint => 'Ένα ID πράκτορα';

  @override
  String planPlaybookRunTitle(String name) {
    return 'Εκτέλεση $name';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count παράμετροι';
  }

  @override
  String get recentLabel => 'Πρόσφατα';

  @override
  String get cheatSheetTitle => 'Συντομεύσεις πληκτρολογίου';

  @override
  String get cheatSheetGlobal => 'Καθολικές';

  @override
  String get cheatSheetThisScreen => 'Αυτή η οθόνη';

  @override
  String get cheatSheetReservedInBrowser =>
      'Δεσμευμένες από το πρόγραμμα περιήγησης';

  @override
  String get keybindingCheatSheet => 'Συντομεύσεις πληκτρολογίου';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      'Εμφάνιση του φύλλου συντομεύσεων πληκτρολογίου για την τρέχουσα οθόνη';

  @override
  String get runPlaybookLabel => 'Εκτέλεση playbook';

  @override
  String get playbooksLabel => 'Playbooks';

  @override
  String get keybindingUndo => 'Αναίρεση';

  @override
  String get keybindingRedo => 'Επανάληψη';

  @override
  String get keybindingUndoLastActionDescription =>
      'Αναίρεση της τελευταίας αναστρέψιμης ενέργειας';

  @override
  String get keybindingRedoLastActionDescription =>
      'Επανάληψη της τελευταίας αναιρεθείσας ενέργειας';

  @override
  String get undone => 'Αναιρέθηκε';

  @override
  String get redone => 'Επαναλήφθηκε';

  @override
  String get undoFailed => 'Δεν ήταν δυνατή η αναίρεση';

  @override
  String get undoLabelTicketEdit => 'επεξεργασία εισιτηρίου';

  @override
  String get undoLabelMessageEdit => 'επεξεργασία μηνύματος';

  @override
  String get undoLabelTodoStatus => 'κατάσταση εκκρεμότητας';

  @override
  String get inboxTitle => 'Εισερχόμενα';

  @override
  String get inboxReview => 'Ανασκόπηση';

  @override
  String get inboxOpen => 'Άνοιγμα';

  @override
  String get inboxAllCaughtUp => 'Είστε ενήμεροι';

  @override
  String get inboxGitHubDownTitle =>
      'Το GitHub μπορεί να είναι εκτός λειτουργίας';

  @override
  String inboxGitHubDownBody(String status) {
    return 'Το GitHub αναφέρει $status, επομένως τα pull requests μπορεί να λείπουν από αυτή τη λίστα αντί να έχουν ολοκληρωθεί.';
  }

  @override
  String get inboxGitHubIdentityTitle =>
      'Δεν ήταν δυνατή η επιβεβαίωση του λογαριασμού σας GitHub';

  @override
  String get inboxGitHubIdentityBody =>
      'Τα εισερχόμενα ταξινομούνται με βάση το ποιος είστε στο GitHub. Μέχρι να φορτωθεί αυτό μένουν κενά, ακόμη και όταν σας περιμένουν pull requests.';

  @override
  String get inboxSeverityBlocking => 'Αποκλεισμένο';

  @override
  String get inboxSeverityWaiting => 'Αναμονή';

  @override
  String get inboxSeverityInfo => 'Πληροφορία';

  @override
  String get inboxSyncFailed => 'Ο συγχρονισμός απέτυχε';

  @override
  String get inboxNeedsYourAttention => 'Χρειάζεται την προσοχή σας';

  @override
  String get inboxSectionNeedsYourReview => 'Χρειάζεται την ανασκόπησή σας';

  @override
  String get inboxSectionReturnedToYou => 'Επιστράφηκε σε εσάς';

  @override
  String get inboxSectionApproved => 'Εγκρίθηκε';

  @override
  String get inboxSectionDrafts => 'Πρόχειρα';

  @override
  String get inboxSectionWaitingForReviewers => 'Αναμονή κριτών';

  @override
  String get inboxSectionMergingAndMerged =>
      'Συγχώνευση και πρόσφατα συγχωνευμένα';

  @override
  String get inboxSectionWaitingForAuthor => 'Αναμονή συντάκτη';

  @override
  String get inboxColumnTitle => 'Τίτλος';

  @override
  String get inboxColumnChanges => 'Αλλαγές';

  @override
  String get inboxColumnUpdated => 'Ενημερώθηκε';

  @override
  String get inboxReviewApproved => 'Εγκρίθηκε';

  @override
  String get inboxReviewChangesRequested => 'Ζητήθηκαν αλλαγές';

  @override
  String get inboxHeroSubtitle =>
      'Κάθε pull request που σας αφορά, ταξινομημένο κατά το τι ακολουθεί.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests χρειάζονται την ανασκόπησή σας',
      one: '1 pull request χρειάζεται την ανασκόπησή σας',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count επιστράφηκαν σε εσάς',
      one: '1 επιστράφηκε σε εσάς',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted =>
      'Αυτή η αλλαγή δεν αποθηκεύτηκε και αναιρέθηκε';

  @override
  String get offlinePendingLabel => 'εκκρεμεί';

  @override
  String get offlineSyncingLabel => 'συγχρονισμός';

  @override
  String get copyLinkLabel => 'Αντιγραφή συνδέσμου σε αυτή τη σελίδα';

  @override
  String get agentsSectionLabel => 'Πράκτορες';

  @override
  String get fleetWorkersTitle => 'Εργάτες';

  @override
  String get fleetWorkersSubtitle =>
      'Μηχανήματα διαθέσιμα για εκτέλεση εργασιών';

  @override
  String get fleetJobsTitle => 'Εργασίες';

  @override
  String get fleetJobsSubtitle => 'Εργασία κατανεμημένη στον στόλο';

  @override
  String get fleetNoWorkers =>
      'Δεν υπάρχουν ακόμη εργάτες — ένα δεύτερο μηχάνημα που εκτελεί `cc_worker --server <url>` ενώνεται στον στόλο.';

  @override
  String get fleetNoJobs => 'Καμία εργασία.';

  @override
  String get fleetError => 'Δεν ήταν δυνατή η φόρτωση του στόλου';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count πυρήνες',
      one: '1 πυρήνας',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'Heartbeat $time';
  }

  @override
  String get fleetNoHeartbeat => 'Δεν υπάρχει ακόμη heartbeat';

  @override
  String fleetLastErrorLabel(String error) {
    return 'Τελευταίο σφάλμα: ⁨$error⁩';
  }

  @override
  String get fleetDrain => 'Άδειασμα';

  @override
  String get fleetResume => 'Συνέχεια';

  @override
  String get fleetRevoke => 'Ανάκληση';

  @override
  String get fleetRemove => 'Αφαίρεση';

  @override
  String get fleetRevokeTitle => 'Ανάκληση εργάτη;';

  @override
  String fleetRevokeBody(String name) {
    return 'Ανάκληση του $name; Η συνεδρία του τελειώνει και τυχόν ενεργές εργασίες επανεκχωρούνται.';
  }

  @override
  String get fleetRemoveTitle => 'Αφαίρεση εργάτη;';

  @override
  String fleetRemoveBody(String name) {
    return 'Αφαίρεση του $name από τον στόλο; Αυτό διαγράφει την εγγραφή του.';
  }

  @override
  String get fleetActionFailed => 'Η ενέργεια απέτυχε';

  @override
  String get fleetJobUnassigned => 'Χωρίς ανάθεση';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max προσπάθειες';
  }

  @override
  String get fleetPlacementReasons => 'Αποφάσεις τοποθέτησης';

  @override
  String get fleetNoPlacements => 'Δεν υπάρχουν ακόμη αποφάσεις τοποθέτησης.';

  @override
  String get fleetStatusOnline => 'Σε σύνδεση';

  @override
  String get fleetStatusDraining => 'Άδειασμα';

  @override
  String get fleetStatusOffline => 'Εκτός σύνδεσης';

  @override
  String get fleetStatusIncompatible => 'Ασύμβατο';

  @override
  String get fleetStatusRevoked => 'Ανακλήθηκε';

  @override
  String get fleetJobStatusQueued => 'Σε ουρά';

  @override
  String get fleetJobStatusRunning => 'Σε εκτέλεση';

  @override
  String get fleetJobStatusSucceeded => 'Επιτυχής';

  @override
  String get fleetJobStatusFailed => 'Απέτυχε';

  @override
  String get fleetJobStatusCancelled => 'Ακυρώθηκε';

  @override
  String get evalsNoSuites => 'Δεν υπάρχουν ακόμη σουίτες αξιολόγησης.';

  @override
  String get evalsError => 'Δεν ήταν δυνατή η φόρτωση αξιολογήσεων';

  @override
  String get evalsStarterBadge => 'Αρχικό';

  @override
  String evalsDefaultBatch(int count) {
    return 'Προεπιλεγμένη παρτίδα $count';
  }

  @override
  String get evalsRecentRuns => 'Πρόσφατες εκτελέσεις';

  @override
  String get evalsNoRuns => 'Δεν υπάρχουν ακόμη εκτελέσεις.';

  @override
  String get evalsPassRate => 'Ποσοστό επιτυχίας';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return 'από $who';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'Η αξιολόγηση ολοκληρώθηκε — $rate πέρασαν';
  }

  @override
  String get evalsRunFailed => 'Δεν ήταν δυνατή η εκτέλεση της σουίτας';

  @override
  String get evalsRun => 'Εκτέλεση';

  @override
  String get evalsStatusQueued => 'Σε ουρά';

  @override
  String get evalsStatusRunning => 'Σε εκτέλεση';

  @override
  String get evalsStatusPassed => 'Πέρασε';

  @override
  String get evalsStatusFailed => 'Απέτυχε';

  @override
  String get bannerMeetingJoin => 'Συμμετοχή';

  @override
  String get bannerMeetingRecordAndLink => 'Εγγραφή και σύνδεση';

  @override
  String get bannerCalendarReconnect => 'Επανασύνδεση';

  @override
  String get bannerView => 'Προβολή';

  @override
  String get soundscapeTitle => 'Ηχητικά περιβάλλοντα';

  @override
  String get soundscapePlay => 'Αναπαραγωγή';

  @override
  String get soundscapePause => 'Παύση';

  @override
  String get soundscapeMoodLabel => 'Διάθεση';

  @override
  String get soundscapeMoodFocus => 'Εστίαση';

  @override
  String get soundscapeMoodRelax => 'Χαλάρωση';

  @override
  String get soundscapeMoodSleep => 'Ύπνος';

  @override
  String get soundscapeMoodRise => 'Άνοδος';

  @override
  String get soundscapeVolumeLabel => 'Ένταση';

  @override
  String get soundscapeTuneLabel => 'Ρύθμιση';

  @override
  String get soundscapeTuneMellow => 'Ήπιο';

  @override
  String get soundscapeTuneBright => 'Φωτεινό';

  @override
  String get soundscapeTuneEnergetic => 'Ενεργητικό';

  @override
  String get soundscapeTuneSpacy => 'Διαστημικό';

  @override
  String get soundscapeTuneResetHint => 'Διπλό πάτημα για επαναφορά';

  @override
  String get soundscapeSceneLabel => 'Τώρα παίζει';

  @override
  String get soundscapeSceneLoading => 'Ρύθμιση της ατμόσφαιρας…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees°C';
  }

  @override
  String get soundscapeLocationLabel => 'Τοποθεσία';

  @override
  String get soundscapeLocationDetecting => 'Ανίχνευση τοποθεσίας…';

  @override
  String get soundscapeLocationAutoNote =>
      'Η τοποθεσία προέρχεται από αυτήν τη συσκευή.';

  @override
  String get soundscapeRefreshWeather => 'Ανανέωση καιρού';

  @override
  String get soundscapeAutoStartLabel => 'Έναρξη με λειτουργία εστίασης';

  @override
  String get soundscapeAutoStartDescription =>
      'Αυτόματη αναπαραγωγή ηχητικού περιβάλλοντος όταν ξεκινάτε συνεδρία εστίασης.';

  @override
  String get soundscapeReturnToApp => 'Επιστροφή στην εφαρμογή';

  @override
  String get soundscapePopOut => 'Απόσπαση προγράμματος αναπαραγωγής';

  @override
  String get discussion => 'Συζήτηση';

  @override
  String get chat => 'Συνομιλία';

  @override
  String get saving => 'Αποθήκευση…';

  @override
  String get saved => 'Αποθηκεύτηκε';

  @override
  String get saveFailed => 'Δεν ήταν δυνατή η αποθήκευση';

  @override
  String get commitAndPush => 'Commit και push';

  @override
  String get commit => 'Commit';

  @override
  String get commitAmend => 'Commit (amend)';

  @override
  String get commitAndSync => 'Commit και συγχρονισμός';

  @override
  String get scmSyncChanges => 'Συγχρονισμός αλλαγών';

  @override
  String get scmPublishBranch => 'Δημοσίευση κλάδου';

  @override
  String get scmSyncFailed => 'Ο συγχρονισμός απέτυχε';

  @override
  String get scmSyncDirty =>
      'Κάντε commit ή απορρίψτε τις αλλαγές πριν τον συγχρονισμό';

  @override
  String get scmSynced => 'Συγχρονίστηκε';

  @override
  String get scmPushRefused => 'Το push απορρίφθηκε';

  @override
  String get scmPulledPushRefused => 'Έγινε pull, αλλά το push απορρίφθηκε';

  @override
  String get scmPushRefusedHint =>
      'Ο απομακρυσμένος διακομιστής ή ένα hook απέρριψε την ενημέρωση';

  @override
  String get scmSelectBranch => 'Επιλογή κλάδου για εξαγωγή';

  @override
  String get scmCreateBranch => 'Δημιουργία νέου κλάδου…';

  @override
  String get scmCreateBranchFrom => 'Δημιουργία νέου κλάδου από…';

  @override
  String get scmCheckoutDetached => 'Αποσπασμένη εξαγωγή…';

  @override
  String get scmBranchName => 'Όνομα κλάδου';

  @override
  String get scmCreateBranchTitle => 'Δημιουργία κλάδου';

  @override
  String scmFromRef(String ref) {
    return 'Από ⁨$ref⁩';
  }

  @override
  String get scmCheckoutFailed => 'Δεν ήταν δυνατή η αλλαγή κλάδου';

  @override
  String get scmCheckoutDirty =>
      'Κάντε υποβολή ή απορρίψτε τις αλλαγές πριν αλλάξετε κλάδο';

  @override
  String scmSwitchedToBranch(String branch) {
    return 'Αλλαγή σε ⁨$branch⁩';
  }

  @override
  String scmDetachedAt(String ref) {
    return 'Αποσπασμένο στο ⁨$ref⁩';
  }

  @override
  String get scmDetachedHead => 'Αποσπασμένο HEAD';

  @override
  String get scmNoBranches => 'Κανένας κλάδος δεν ταιριάζει';

  @override
  String get scmBranches => 'Κλάδοι';

  @override
  String get scmRemoteBranches => 'Απομακρυσμένοι κλάδοι';

  @override
  String get scmTags => 'Ετικέτες';

  @override
  String get scmPickStartPoint => 'Επιλογή σημείου εκκίνησης';

  @override
  String get scmSwitchBranch => 'Αλλαγή κλάδου';

  @override
  String get scmPullConflictTitle => 'Το pull θα προκαλούσε διένεξη';

  @override
  String scmPullConflictBody(int count, String branch) {
    return 'Η ενσωμάτωση $count commits στο ⁨$branch⁩ θα συγκρουόταν με την εργασία σε αυτό το checkout.';
  }

  @override
  String get scmAskAi => 'Ρώτησε την AI';

  @override
  String scmResolveConflictPrompt(String branch, String repo, int count) {
    return 'Κάνε pull το ⁨$branch⁩ στο ⁨$repo⁩. Είναι $count commits πίσω από το upstream και το pull συγκρούεται με την τοπική εργασία. Επίλυσε τις διενέξεις και ολοκλήρωσε το pull.';
  }

  @override
  String commitMessageOnBranch(String shortcut, String branch) {
    return 'Μήνυμα ($shortcut για commit στο «$branch»)';
  }

  @override
  String get committed => 'Έγινε commit';

  @override
  String get commitAmended => 'Το commit τροποποιήθηκε';

  @override
  String get commitFailed => 'Το commit απέτυχε';

  @override
  String get moreCommitActions => 'Περισσότερες ενέργειες commit';

  @override
  String get sourceControl => 'Έλεγχος εκδόσεων';

  @override
  String fixFindingTitle(String location) {
    return 'Διόρθωση: $location';
  }

  @override
  String get openInEditor => 'Άνοιγμα στον επεξεργαστή';

  @override
  String get regexTesterTitle => 'Δοκιμή κανονικής έκφρασης';

  @override
  String get regexTesterHint => 'Πληκτρολογήστε ένα δείγμα';

  @override
  String get regexMatch => 'Ταίριασμα';

  @override
  String get regexNoMatch => 'Κανένα ταίριασμα';

  @override
  String get regexInvalidPattern => 'Μη έγκυρο μοτίβο';

  @override
  String get symbolLookupNone =>
      'Δεν υπάρχει ορισμός στο ευρετήριο ή σε αυτό το αίτημα έλξης';

  @override
  String get symbolLookupInDiff => 'Βρέθηκε σε αυτό το αίτημα έλξης';

  @override
  String get symbolLookupFromBase =>
      'Από το βασικό checkout — το worktree αυτού του PR δεν έχει ευρετηριαστεί ακόμα';

  @override
  String get symbolImplementations => 'Υλοποιήσεις';

  @override
  String symbolCallersCount(int count) {
    return '$count καλούντες';
  }

  @override
  String get commitMessageHint => 'Μήνυμα commit';

  @override
  String get pushedToPr => 'Έγινε push στο PR';

  @override
  String get pushFailed => 'Το push απέτυχε';

  @override
  String get reviewFindings => 'Ευρήματα';

  @override
  String get treeLabel => 'Δέντρο';

  @override
  String get toggleFileTree => 'Εμφάνιση ή απόκρυψη του δέντρου αρχείων';

  @override
  String get diffViewSettings => 'Ρυθμίσεις προβολής diff';

  @override
  String get splitViewLabel => 'Διαχωρισμένη';

  @override
  String get unifiedViewLabel => 'Ενοποιημένη';

  @override
  String get wrapLines => 'Αναδίπλωση γραμμών';

  @override
  String get shiftClickSelectRange => 'Shift-κλικ για επιλογή εύρους';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count αρχεία',
      one: '1 αρχείο',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'Μικρό PR — $files, ~$minutes λεπτά για ανασκόπηση';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'Μεσαίο PR — $files, δεσμεύστε ~$minutes λεπτά για ανασκόπηση';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'Μεγάλο PR — $files, σκεφτείτε διαχωρισμό πριν την ανασκόπηση';
  }

  @override
  String get searchInFiles => 'Αναζήτηση σε αρχεία';

  @override
  String get showFileList => 'Εμφάνιση λίστας αρχείων';

  @override
  String get searchInFilesHintField => 'Αναζήτηση σε αρχεία…';

  @override
  String get searchInFilesHint => 'Αναζήτηση στα αρχεία του pull request';

  @override
  String get searchInWholeRepo => 'Αναζήτηση σε όλο το αποθετήριο';

  @override
  String get searchInThisPullRequest => 'Αναζήτηση σε αυτό το pull request';

  @override
  String get searchNoResults => 'Δεν βρέθηκαν αποτελέσματα';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count αποτελέσματα',
      one: '1 αποτέλεσμα',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files αρχεία',
      one: '1 αρχείο',
    );
    return '$_temp0 σε $_temp1';
  }

  @override
  String get discardChangesTitle => 'Απόρριψη αλλαγών;';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count αρχείων',
      one: '1 αρχείου',
    );
    return 'Απόρριψη $_temp0 στο HEAD; Αυτή η ενέργεια δεν αναιρείται.';
  }

  @override
  String get discardAll => 'Απόρριψη όλων';

  @override
  String get discardFailed => 'Αποτυχία απόρριψης αλλαγών';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count αρχεία',
      one: '1 αρχείο',
    );
    return 'Απορρίφθηκαν $_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted αρχεία',
      one: '1 αρχείο',
    );
    return 'Απορρίφθηκαν $_temp0· $skipped παραλείφθηκαν (μη παρακολουθούμενα)';
  }

  @override
  String get prWorktreeUnavailable => 'Ο χώρος εργασίας δεν είναι έτοιμος';

  @override
  String get prWorktreeUnavailableHint =>
      'Η προετοιμασία των αρχείων του pull request απέτυχε. Ανοίξτε ξανά το pull request για να δοκιμάσετε πάλι.';

  @override
  String get timestampRelativeLabel => 'Σχετικός';

  @override
  String get timestampRawLabel => 'Χρονική σήμανση';

  @override
  String get copyTimestamp => 'Αντιγραφή χρονικής σήμανσης';

  @override
  String get copiedTimestamp => 'Η χρονική σήμανση αντιγράφηκε';

  @override
  String get previewDeployment => 'Προεπισκόπηση ανάπτυξης';

  @override
  String previewDeploymentTab(String site) {
    return 'Προεπισκόπηση: $site';
  }

  @override
  String get askForReview => 'Αίτημα ανασκόπησης…';

  @override
  String get closePrsConfirmTitle => 'Κλείσιμο pull requests;';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Κλείσιμο $count pull requests;',
      one: 'Κλείσιμο 1 pull request;',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Έκλεισαν $count pull requests',
      one: 'Έκλεισε 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ανατέθηκαν $count pull requests',
      one: 'Ανατέθηκε 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ζητήθηκε ανασκόπηση σε $count pull requests',
      one: 'Ζητήθηκε ανασκόπηση σε 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ενέργειες απέτυχαν',
      one: '1 ενέργεια απέτυχε',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'Διάγραμμα';

  @override
  String get diagramViewSource => 'Προβολή πηγής';

  @override
  String get diagramHideSource => 'Απόκρυψη πηγής';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'Η προεπισκόπηση διαγράμματος δεν είναι διαθέσιμη ($reason)';
  }

  @override
  String get planUnavailable => 'Το σχέδιο δεν είναι διαθέσιμο';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count βήματα',
      one: '1 βήμα',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'Έγκριση και εκτέλεση';

  @override
  String get planStatusDraft => 'Πρόχειρο';

  @override
  String get planStatusProposed => 'Σχέδιο';

  @override
  String get planStatusApproved => 'Το σχέδιο εγκρίθηκε';

  @override
  String get planStatusRejected => 'Το σχέδιο απορρίφθηκε';

  @override
  String get planStatusSuperseded => 'Το σχέδιο αντικαταστάθηκε';

  @override
  String planRevisionLabel(int revision) {
    return 'Αναθεώρηση $revision';
  }

  @override
  String get adapterEnforcementTitle => 'Τι επιβάλλει αυτός ο προσαρμογέας';

  @override
  String get enforcementFiltersToolSurface =>
      'Το Control Center επιλέγει τα εργαλεία';

  @override
  String get enforcementInterceptsToolCalls =>
      'Κάθε κλήση περνά από πύλη πριν εκτελεστεί';

  @override
  String get enforcementObservesCompletionContract =>
      'Η εκτέλεση κρατιέται στο παραδοτέο της';

  @override
  String get enforcementNativeToolsInterceptable =>
      'Τα δικά του εργαλεία του εκτελεστή είναι ορατά';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'Τα εργαλεία εντός διεργασίας είναι σε sandbox';

  @override
  String get enforcementYes => 'Ναι';

  @override
  String get enforcementNo => 'Όχι';

  @override
  String get adapterEnforcementCaveats => 'Επιφυλάξεις';

  @override
  String get enforcementSummaryModesEnforced => 'Οι λειτουργίες επιβάλλονται';

  @override
  String get enforcementSummaryModesNotEnforced =>
      'Οι λειτουργίες δεν επιβάλλονται';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count επιφυλάξεις',
      one: '1 επιφύλαξη',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'Οι λειτουργίες μόνο ανάγνωσης δεν είναι δομικές: το Control Center δεν μπορεί να αφαιρέσει τα δικά του εργαλεία αυτού του εκτελεστή.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'Δεν υπάρχει πύλη προ-εκτέλεσης: μόνο οι κλήσεις εργαλείων MCP περνούν από το Control Center.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'Τα δικά του εργαλεία αρχείων και κελύφους του εκτελεστή δεν φτάνουν ποτέ στο Control Center· το sandbox του λειτουργικού είναι το μόνο κατώφλι κάτω από αυτά.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'Τα εργαλεία αρχείων εντός διεργασίας τρέχουν εκτός sandbox, οπότε η επιφάνεια εργαλείων είναι το μόνο όριο συστήματος αρχείων.';

  @override
  String get caveatCompletionContractUnobservable =>
      'Το Control Center δεν μπορεί να ωθήσει ή να αποτύχει μια εκτέλεση που τελειώνει χωρίς να παράγει το παραδοτέο της.';

  @override
  String get modeDegraded => 'Υποβαθμισμένη';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return 'Η λειτουργία $mode στον $adapter στηρίζεται μόνο στο sandbox· τα δικά του εργαλεία αρχείων του πράκτορα δεν αναχαιτίζονται.';
  }

  @override
  String get artifactUnavailable => 'Το τεχνούργημα δεν είναι διαθέσιμο';

  @override
  String artifactRevisionLabel(int count) {
    return '$count αναθεωρήσεις';
  }

  @override
  String get artifactShowMore => 'Εμφάνιση περισσότερων';

  @override
  String get artifactShowLess => 'Εμφάνιση λιγότερων';

  @override
  String get artifactCopy => 'Αντιγραφή';

  @override
  String get artifactCopied => 'Το τεχνούργημα αντιγράφηκε';

  @override
  String get artifactsTabLabel => 'Τεχνουργήματα';

  @override
  String get artifactsEmptyTitle => 'Δεν υπάρχουν ακόμη τεχνουργήματα';

  @override
  String get artifactsEmptyBody =>
      'Όταν ένας πράκτορας δημοσιεύει πίνακα, γράφημα ή διάγραμμα εδώ, εμφανίζεται σε αυτή τη λίστα.';

  @override
  String get artifactRevisionPickerLabel => 'Αναθεώρηση';

  @override
  String get artifactRestoreRevision => 'Επαναφορά αυτής της αναθεώρησης';

  @override
  String get artifactOpenInTab => 'Άνοιγμα σε καρτέλα';

  @override
  String get artifactTitleFallback => 'Τεχνούργημα';

  @override
  String get providerGenerationLabel => 'Προεπιλογές γενιάς';

  @override
  String get providerGenerationHint =>
      'Αφήστε ένα πεδίο κενό για την προεπιλογή του ίδιου του endpoint. Τα μοντέλα δημοσιεύουν τα δικά τους ανώτατα όρια εξόδου και συνταγές δειγματοληψίας· η εξυπηρέτηση σε άλλες τιμές μπορεί να τα υποβαθμίσει.';

  @override
  String get providerMaxTokensLabel => 'Μέγιστα token εξόδου';

  @override
  String get addModel => 'Προσθήκη μοντέλου';

  @override
  String get modelListTitle => 'Λίστα μοντέλων';

  @override
  String get railProvidersGroup => 'Πάροχοι';

  @override
  String get railCustomProvidersGroup => 'Προσαρμοσμένοι πάροχοι';

  @override
  String get editModelSettings => 'Επεξεργασία ρυθμίσεων μοντέλου';

  @override
  String get modelIdLabel => 'ID μοντέλου';

  @override
  String get modelIdImmutableHint =>
      'Το id που εξυπηρετεί το endpoint· σταθερό μόλις καταχωριστεί.';

  @override
  String get contextWindowLabel => 'Παράθυρο συμφραζομένων';

  @override
  String get inputTypesLabel => 'Τύποι εισόδου';

  @override
  String get outputTypesLabel => 'Τύποι εξόδου';

  @override
  String get modalityText => 'Κείμενο';

  @override
  String get modalityImage => 'Εικόνα';

  @override
  String get modalityAudio => 'Ήχος';

  @override
  String get modalityVideo => 'Βίντεο';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'Επαναφορά σε αυτόματο';

  @override
  String get modelOverrideEdited => 'Επεξεργασμένο';

  @override
  String get manualModelBadge => 'Προστέθηκε χειροκίνητα';

  @override
  String get modelIdRequired => 'Εισαγάγετε ένα id μοντέλου.';

  @override
  String get modelTokensInvalid => 'Εισαγάγετε θετικό ακέραιο αριθμό token.';

  @override
  String get removeModelAction => 'Αφαίρεση μοντέλου';

  @override
  String removeModelConfirmTitle(String model) {
    return 'Αφαίρεση του ⁨$model⁩;';
  }

  @override
  String get removeModelConfirmBody =>
      'Το μοντέλο φεύγει από τη λίστα και οι πράκτορες δεσμευμένοι σε αυτό σταματούν. Ο πάροχος δεν επηρεάζεται.';

  @override
  String get addModelProviderTitle => 'Προσθήκη παρόχου μοντέλων';

  @override
  String get addModelProviderDescription =>
      'Ρυθμίστε ένα προσαρμοσμένο API endpoint και τα μοντέλα του.';

  @override
  String get modelListEmptyHint =>
      'Δεν έχουν ρυθμιστεί μοντέλα. Προσθέστε ένα μοντέλο για να το χρησιμοποιήσετε στη συνομιλία.';

  @override
  String get addProviderModelsHint =>
      'Τα μοντέλα ανακτώνται ζωντανά μόλις απαντήσει το endpoint. Προσθέστε ένα χειροκίνητα μόνο αν δεν μπορεί να απαριθμήσει τα δικά του.';

  @override
  String get providerTemperatureLabel => 'Temperature';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => 'Οι προεπιλογές γενιάς αποθηκεύτηκαν';

  @override
  String get providerGenerationInvalid =>
      'Ελέγξτε τις τιμές: τα μέγιστα token εξόδου και το top-k πρέπει να είναι θετικά, temperature 0–2, top-p 0–1.';

  @override
  String get providerGenerationOverridden => 'Παρακάμφθηκε';

  @override
  String get branchNotPushed => 'δεν έγινε push';

  @override
  String branchNotOnRemote(String branch) {
    return 'Ο «⁨$branch⁩» υπάρχει μόνο σε αυτή τη συνομιλία';
  }

  @override
  String get branchNotOnRemoteHint =>
      'Το GitHub δεν έχει δει ποτέ αυτόν τον κλάδο, οπότε ένα pull request δεν μπορεί να τον χρησιμοποιήσει ακόμη. Η δημοσίευση κάνει push τα commit που είναι ήδη στο worktree — οι μη δεσμευμένες αλλαγές μένουν ανέγγιχτες.';

  @override
  String get publishBranch => 'Δημοσίευση κλάδου';

  @override
  String branchPublished(String branch) {
    return 'Δημοσιεύτηκε ο «⁨$branch⁩» στο origin';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'Ο κλάδος δημοσιεύτηκε. $count μη δεσμευμένη(-ες) αλλαγή(-ές) δεν συμπεριλήφθηκαν.';
  }

  @override
  String get composePrLoadingBranches => 'Φόρτωση κλάδων από το GitHub…';

  @override
  String get composePrBranchesFailed =>
      'Δεν ήταν δυνατή η φόρτωση κλάδων από το GitHub. Πληκτρολογήστε όνομα κλάδου ή ελέγξτε τη σύνδεση GitHub.';

  @override
  String get composePrSubtitleFromSpace =>
      'Από τον κλάδο αυτής της συνομιλίας — δημοσιεύστε τον πρώτα αν το GitHub δεν τον έχει δει';

  @override
  String get obsTabInsights => 'Στοιχεία';

  @override
  String get obsTabLive => 'Ζωντανά';

  @override
  String get obsTabQuality => 'Ποιότητα';

  @override
  String get obsTabUsage => 'Χρήση';

  @override
  String get obsUsageTotalTokens => 'Συνολικά token';

  @override
  String get obsUsagePeakTokens => 'Κορυφαία token';

  @override
  String get obsUsageLongestSession => 'Μεγαλύτερη συνεδρία';

  @override
  String get obsUsageCurrentStreak => 'Τρέχουσα σειρά';

  @override
  String get obsUsageLongestStreak => 'Μεγαλύτερη σειρά';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ημέρες',
      one: '1 ημέρα',
      zero: '0 ημέρες',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'Δραστηριότητα token';

  @override
  String get obsUsageActivityModeLabel => 'Λειτουργία δραστηριότητας token';

  @override
  String get obsUsageModeDaily => 'Ημερήσια';

  @override
  String get obsUsageModeWeekly => 'Εβδομαδιαία';

  @override
  String get obsUsageModeCumulative => 'Σωρευτική';

  @override
  String get obsUsageTimeRange => 'Χρονικό εύρος';

  @override
  String get obsUsageTrendTitle => 'Ημερήσια τάση token';

  @override
  String get obsUsageModelUsage => 'Χρήση μοντέλων';

  @override
  String get obsUsageTokensLabel => 'token';

  @override
  String get obsUsageNoActivity => 'Δεν έχει καταγραφεί ακόμη χρήση token';

  @override
  String get obsUsageOtherModels => 'Άλλα';

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
    return 'Δραστηριότητα token από $start έως $end. $activeDays ενεργές ημέρες. Πιο φορτωμένη ημέρα $peak token.';
  }

  @override
  String get obsScreenSubtitle =>
      'Ζωντανός έλεγχος πρακτόρων, απόδοση κόστους, ποσοστώσεις και σήματα ποιότητας';

  @override
  String get obsRangeLast24h => 'Τελευταίες 24 ώρες';

  @override
  String get obsRangeLast7d => 'Τελευταίες 7 ημέρες';

  @override
  String get obsRangeLast30d => 'Τελευταίες 30 ημέρες';

  @override
  String get obsRangeAll => 'Όλος ο χρόνος';

  @override
  String get obsAddFilter => 'Προσθήκη φίλτρου';

  @override
  String get obsFilterAgent => 'Πράκτορας';

  @override
  String get obsFilterModel => 'Μοντέλο';

  @override
  String get obsFilterStatus => 'Κατάσταση';

  @override
  String get obsFilterRole => 'Ρόλος';

  @override
  String get obsKpiTotalRuns => 'Συνολικές εκτελέσεις';

  @override
  String get obsKpiTotalCost => 'Συνολικό κόστος';

  @override
  String get obsKpiErrorRate => 'Ποσοστό σφαλμάτων';

  @override
  String get obsKpiCacheRate => 'Ποσοστό cache';

  @override
  String get obsKpiTokensPerSec => 'Token / δευτ.';

  @override
  String get obsKpiAvgLatency => 'Μέση καθυστέρηση';

  @override
  String get obsKpiTtft => 'Χρόνος έως το πρώτο token';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta έναντι προηγούμενης περιόδου';
  }

  @override
  String get obsChartActivity => 'Δραστηριότητα';

  @override
  String get obsChartCost => 'Κόστος στον χρόνο';

  @override
  String get obsLegendRuns => 'Εκτελέσεις';

  @override
  String get obsLegendErrors => 'Σφάλματα';

  @override
  String get obsAgentsTitle => 'Πράκτορες';

  @override
  String obsShowAllAgents(int count) {
    return 'Εμφάνιση και των $count πρακτόρων';
  }

  @override
  String get obsShowFewerAgents => 'Εμφάνιση λιγότερων';

  @override
  String get obsRunsTitle => 'Εκτελέσεις';

  @override
  String get obsNoRunsInRange => 'Δεν υπάρχουν εκτελέσεις σε αυτό το εύρος';

  @override
  String get obsColTime => 'Ώρα';

  @override
  String get obsColAgent => 'Πράκτορας';

  @override
  String get obsColStatus => 'Κατάσταση';

  @override
  String get obsColModel => 'Μοντέλο';

  @override
  String get obsColDuration => 'Διάρκεια';

  @override
  String get obsColTokens => 'Token';

  @override
  String get obsColCost => 'Κόστος';

  @override
  String get obsColErrors => 'Σφάλματα';

  @override
  String get obsColRuns => 'Εκτελέσεις';

  @override
  String get obsColAvgLatency => 'Μέση καθυστέρηση';

  @override
  String get obsColLastActive => 'Τελευταία ενεργός';

  @override
  String get obsStatusPending => 'Σε εκκρεμότητα';

  @override
  String get obsStatusRunning => 'Σε εκτέλεση';

  @override
  String get obsStatusCompleted => 'Ολοκληρώθηκε';

  @override
  String get obsStatusError => 'Σφάλμα';

  @override
  String get obsRosterLoadError =>
      'Δεν ήταν δυνατή η φόρτωση του καταλόγου πρακτόρων.';

  @override
  String get obsRosterEmpty => 'Δεν υπάρχουν ακόμη πράκτορες';

  @override
  String get obsRosterEmptyDescription =>
      'Αποστείλετε έναν πράκτορα και θα εμφανιστεί εδώ ζωντανά — κατάσταση, τρέχον εργαλείο, token, κόστος.';

  @override
  String get obsKillAgent => 'Τερματισμός πράκτορα';

  @override
  String get obsRosterTokensLabel => 'tok';

  @override
  String get obsCostByRoleTitle => 'Κόστος ανά ρόλο';

  @override
  String get obsCostByRoleSubtitle =>
      'Πού ξοδεύει αυτός ο χώρος εργασίας, ανά ρόλο πράκτορα';

  @override
  String get obsRoleMain => 'Κύριος';

  @override
  String get obsRoleSubagents => 'Υποπράκτορες';

  @override
  String get obsRoleAdvisor => 'Σύμβουλος';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'Κύριος: $main · υποπράκτορες: $sub · σύμβουλος: $advisor';
  }

  @override
  String get obsTotal => 'Σύνολο';

  @override
  String get obsTokenModelTitle => 'Μοντέλο token (5 άξονες)';

  @override
  String get obsTokenModelSubtitle =>
      'Κάθε token που έχει ξοδέψει αυτός ο χώρος εργασίας, ανά άξονα';

  @override
  String get obsAxisInput => 'Είσοδος';

  @override
  String get obsAxisOutput => 'Έξοδος';

  @override
  String get obsAxisReasoning => 'Συλλογισμός';

  @override
  String get obsAxisCacheRead => 'Ανάγνωση cache';

  @override
  String get obsAxisCacheWrite => 'Εγγραφή cache';

  @override
  String get obsTotalTokens => 'Συνολικά token';

  @override
  String get obsCacheDiscountNote =>
      'Τα token ανάγνωσης cache χρεώνονται με έκπτωση, οπότε κοστίζουν πολύ λιγότερο από τον ίδιο όγκο νέας εισόδου.';

  @override
  String get obsByModelTitle => 'Ανά μοντέλο';

  @override
  String get obsByModelSubtitle => 'Χρήση token και κόστους ανά μοντέλο';

  @override
  String get obsNoModelUsage => 'Δεν έχει καταγραφεί ακόμη χρήση μοντέλων.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count εκτελέσεις',
      one: '1 εκτέλεση',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => 'Ανά εκτέλεση';

  @override
  String get obsPerRunSubtitle =>
      'Τυπικό κόστος token μιας μεμονωμένης εκτέλεσης';

  @override
  String get obsMedianRunTokens => 'Διάμεσο token εκτέλεσης';

  @override
  String get obsMedianRunTokensSub => 'Μέσο σημείο σε όλες τις εκτελέσεις';

  @override
  String get obsRunsInWorkspace => 'Σε αυτόν τον χώρο εργασίας';

  @override
  String get obsCostShare => 'Μερίδιο κόστους';

  @override
  String get obsQuotaConfiguredLimits => 'Ρυθμισμένα όρια';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'Χρήση έναντι των οροφών που ορίσατε, χειρότερη κατάσταση πρώτα.';

  @override
  String get obsQuotaAddLimit => 'Προσθήκη ορίου';

  @override
  String get obsQuotaNoLimits =>
      'Δεν έχουν ρυθμιστεί ακόμη όρια ποσόστωσης — προσθέστε ένα για παρακολούθηση της χρήσης έναντι οροφής.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'Αφαίρεση ορίου $title';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'Επαναφορά σε $duration · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'Παράθυρα χρήσης';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'Παρατηρούμενη χρήση σε όλους τους παρόχους, χωρίς εφαρμοσμένη οροφή.';

  @override
  String get obsQuotaNoUsage => 'Δεν έχει καταγραφεί ακόμη χρήση.';

  @override
  String get obsQuotaTokensUsed => 'Token που χρησιμοποιήθηκαν';

  @override
  String get obsQuotaRequests => 'Αιτήματα';

  @override
  String get obsQuotaUnitTokens => 'token';

  @override
  String get obsQuotaUnitRequests => 'αιτήματα';

  @override
  String get obsQuotaUnitCost => 'κόστος';

  @override
  String get obsQuotaAddLimitTitle => 'Προσθήκη ορίου ποσόστωσης';

  @override
  String get obsQuotaProviderLabel => 'Πάροχος';

  @override
  String get obsQuotaWindowLabel => 'Παράθυρο';

  @override
  String get obsQuotaUnitLabel => 'Μονάδα';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'Όριο ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'Σε αμερικανικά σεντ (500 = \$5.00).';

  @override
  String get obsQuotaStatusOk => 'Εντάξει';

  @override
  String get obsQuotaStatusWarning => 'Προειδοποίηση';

  @override
  String get obsQuotaStatusExhausted => 'Εξαντλήθηκε';

  @override
  String get obsQuotaStatusUnknown => 'Άγνωστο';

  @override
  String get obsGoalNoActiveTitle => 'Δεν υπάρχει ενεργός στόχος';

  @override
  String get obsGoalNoActiveBody =>
      'Ορίστε έναν στόχο για να δώσετε στους πράκτορες έναν αντικειμενικό σκοπό και προαιρετικό προϋπολογισμό token. Καθώς ολοκληρώνονται οι εκτελέσεις, ο προϋπολογισμός γεμίζει και οι πράκτορες ωθούνται να κλείσουν όταν σχεδόν εξαντληθεί.';

  @override
  String get obsGoalSetGoal => 'Ορισμός στόχου';

  @override
  String get obsGoalTokenBudget => 'Προϋπολογισμός token';

  @override
  String obsGoalTokensLeft(String tokens) {
    return '$tokens απομένουν';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (χωρίς προϋπολογισμό)';
  }

  @override
  String get obsGoalTokensUsed => 'Token που χρησιμοποιήθηκαν';

  @override
  String get obsGoalElapsed => 'Παρελθόντα';

  @override
  String get obsGoalWrapUp => 'Ολοκλήρωση';

  @override
  String get obsGoalClear => 'Εκκαθάριση στόχου';

  @override
  String get obsGoalFallbackTitle => 'Στόχος';

  @override
  String get obsGoalSubtitle => 'Προϋπολογισμός λειτουργίας στόχου';

  @override
  String get obsGoalStatusActive => 'Ενεργός';

  @override
  String get obsGoalStatusPaused => 'Σε παύση';

  @override
  String get obsGoalStatusBudgetLimited => 'Περιορισμένος προϋπολογισμός';

  @override
  String get obsGoalStatusComplete => 'Ολοκληρώθηκε';

  @override
  String get obsGoalStatusDropped => 'Εγκαταλείφθηκε';

  @override
  String get obsGoalObjectiveLabel => 'Αντικειμενικός σκοπός';

  @override
  String get obsGoalBudgetLabel => 'Προϋπολογισμός token (προαιρετικό)';

  @override
  String get obsGoalSetAction => 'Ορισμός στόχου';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => 'Επιτυχία %';

  @override
  String get obsBenchmarkPassed => 'Πέρασε';

  @override
  String get obsBenchmarkFailed => 'Απέτυχε';

  @override
  String get obsBenchmarkErrors => 'Σφάλματα';

  @override
  String get obsBenchmarkSpend => 'Δαπάνη';

  @override
  String get obsBenchmarkCostPerTask => 'Κόστος / εργασία';

  @override
  String get obsBenchmarkTrials => 'Δοκιμές';

  @override
  String get obsBenchmarkNoTrials =>
      'Δεν υπάρχουν ακόμη εκτελέσεις για βαθμολόγηση.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Και $count ακόμη',
      one: 'Και 1 ακόμη',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'Επιτυχία';

  @override
  String get obsBenchmarkTrialFail => 'Αποτυχία';

  @override
  String get obsBenchmarkTrialError => 'Σφάλμα';

  @override
  String get obsBenchmarkTrialRunning => 'Σε εκτέλεση';

  @override
  String get obsBenchmarkReward => 'Ανταμοιβή';

  @override
  String get obsBenchmarkReport => 'Αναφορά';

  @override
  String get obsBenchmarkCopyMarkdown => 'Αντιγραφή markdown';

  @override
  String get obsBenchmarkCopied => 'Η αναφορά αντιγράφηκε στο πρόχειρο';

  @override
  String get obsBehaviorCaption =>
      'Αυτά είναι σήματα απογοήτευσης που αναλύονται από τα δικά σας μηνύματα — ένδειξη υγείας συνομιλίας, όχι βαθμολογία για τους πράκτορες. Υπολογίζονται τοπικά· τίποτα δεν φεύγει από αυτή τη συσκευή.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'Μηνύματα που αναλύθηκαν';

  @override
  String get obsBehaviorTotalSignals => 'Συνολικά σήματα';

  @override
  String get obsBehaviorYelling => 'Φωνές';

  @override
  String get obsBehaviorProfanity => 'Βρισιές';

  @override
  String get obsBehaviorAnguish => 'Αγωνία';

  @override
  String get obsBehaviorNegation => 'Άρνηση';

  @override
  String get obsBehaviorRepetition => 'Επανάληψη';

  @override
  String get obsBehaviorBlame => 'Κατηγορία';

  @override
  String get obsBehaviorConversationsTitle => 'Πιο απογοητευμένες συνομιλίες';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'Κατάταξη κατά πυκνότητα σήματος στα μηνύματά σας.';

  @override
  String get obsBehaviorNoSignals =>
      'Δεν εντοπίστηκαν σήματα απογοήτευσης — όλα ήρεμα.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count μηνύματα αναλύθηκαν';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count σήματα';
  }

  @override
  String get obsAgentStatusIdle => 'Αδρανής';

  @override
  String get obsAgentStatusParked => 'Σταθμευμένος';

  @override
  String get obsAgentStatusAborted => 'Ματαιώθηκε';

  @override
  String get obsAgentKindSub => 'Υπο';

  @override
  String get noChecksOnCommit => 'Δεν έχουν τρέξει έλεγχοι σε αυτό το commit.';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Σε εκτέλεση — $count εργασίες',
      one: 'Σε εκτέλεση — 1 εργασία',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Όλοι οι έλεγχοι πέρασαν — $count εργασίες',
      one: 'Όλοι οι έλεγχοι πέρασαν — 1 εργασία',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ολοκληρώθηκε — $count εργασίες',
      one: 'Ολοκληρώθηκε — 1 εργασία',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total εργασίες',
      one: '1 εργασία',
    );
    return '$failed από $_temp0 απέτυχαν';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count εργασίες',
      one: '1 εργασία',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'Matrix: ⁨$jobId⁩';
  }

  @override
  String get jobLogsPending =>
      'Τα αρχεία καταγραφής θα εμφανιστούν εδώ όταν τελειώσει η εργασία.';

  @override
  String get jobLogsUnavailable =>
      'Τα αρχεία καταγραφής δεν είναι διαθέσιμα για αυτή την εργασία.';

  @override
  String get noLogsForStep =>
      'Δεν καταγράφηκαν αρχεία καταγραφής για αυτό το βήμα.';

  @override
  String get jobLogsTruncated =>
      'Το αρχείο καταγραφής περικόπηκε — εμφανίζεται η πιο πρόσφατη έξοδος.';

  @override
  String get fullLog => 'Πλήρες αρχείο καταγραφής';

  @override
  String get copyLogs => 'Αντιγραφή αρχείων καταγραφής';

  @override
  String get resizeGraph => 'Σύρετε για αλλαγή μεγέθους του γραφήματος';

  @override
  String workflowRunStartedAgo(String time) {
    return 'Ξεκίνησε $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'Ολοκληρώθηκε $time';
  }

  @override
  String get chatBridgesTitle => 'Γέφυρες συνομιλίας';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'Αναφέρετε το bot στο $provider για να βάλετε έναν πράκτορα σε κάτι, ή ανοίξτε εισιτήρια με ⁨$command⁩.';
  }

  @override
  String chatConnectProvider(String provider) {
    return 'Σύνδεση $provider';
  }

  @override
  String get chatDisconnectProvider => 'Αποσύνδεση';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName στο $teamName';
  }

  @override
  String get chatStateLive => 'Ζωντανά';

  @override
  String get chatStateConnecting => 'Σύνδεση…';

  @override
  String get chatStateError => 'Σφάλμα σύνδεσης';

  @override
  String get chatNotConnected => 'Δεν έχει συνδεθεί';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'Η ζωντανή ροή είναι απενεργοποιημένη για αυτή την εφαρμογή $provider — οι απαντήσεις φτάνουν ως ένα μήνυμα.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'Μόνο ένας διαχειριστής μπορεί να συνδέσει το $provider για αυτόν τον χώρο εργασίας.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'Δημιουργήστε μια εφαρμογή $provider και επικολλήστε τα διαπιστευτήριά της εδώ. Το Control Center συνδέεται προς τα έξω στο $provider, οπότε αυτός ο διακομιστής δεν χρειάζεται δημόσια διεύθυνση.';
  }

  @override
  String chatOpenConsole(String provider) {
    return 'Άνοιγμα κονσόλας $provider';
  }

  @override
  String get chatOpenSetupGuide => 'Οδηγός ρύθμισης';

  @override
  String get chatFieldBotToken => 'Token bot';

  @override
  String get chatFieldAppToken => 'Token επιπέδου εφαρμογής';

  @override
  String get chatFieldConfigRefreshToken => 'Token ρύθμισης εφαρμογής';

  @override
  String chatFieldOptional(String label) {
    return '$label (προαιρετικό)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'Σύνδεση του λογαριασμού μου $provider';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'Συνδέστε τον λογαριασμό σας $provider ώστε τα μηνύματα που στέλνετε εκεί να αποδίδονται σε εσάς.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'Συνδεδεμένος με ⁨$externalUserId⁩';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'Σύνδεση του λογαριασμού σας $provider';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'Στείλτε αυτή την εντολή στο bot στο $provider. Λειτουργεί μία φορά και λήγει σε 15 λεπτά.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'Ο λογαριασμός σας $provider είναι πλέον συνδεδεμένος — τα μηνύματα που στέλνετε εκεί αποδίδονται σε εσάς.';
  }

  @override
  String get chatLinkedAccounts => 'Συνδεδεμένοι λογαριασμοί';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'Κανείς δεν έχει συνδέσει ακόμη τον λογαριασμό $provider.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count συνδεδεμένοι λογαριασμοί',
      one: '1 συνδεδεμένος λογαριασμός',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '⁨$externalUserId⁩ · αντιστοίχιση με email';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '⁨$externalUserId⁩ · συνδέθηκε με κωδικό';
  }

  @override
  String get chatUnlink => 'Αποσύνδεση';

  @override
  String get chatCustomizeBot => 'Προσαρμογή bot';

  @override
  String get chatCustomizeBotDescription =>
      'Μετονομάστε το bot, αλλάξτε τι λέει για τον εαυτό του ή μετονομάστε την εντολή κάθετου.';

  @override
  String get chatCustomizeBotUnavailable =>
      'Το Control Center χρειάζεται token ρύθμισης εφαρμογής για επεξεργασία του bot. Επανασυνδεθείτε και συμπεριλάβετε ένα.';

  @override
  String chatCreateAppTitle(String provider) {
    return 'Δημιουργία της εφαρμογής $provider';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Το Control Center μπορεί να δημιουργήσει την εφαρμογή $provider για εσάς, με τα σωστά δικαιώματα και συμβάντα ήδη ρυθμισμένα. Θα τελειώσετε στο $provider και μετά θα επικολλήσετε τα διαπιστευτήρια εδώ.';
  }

  @override
  String get chatCreateApp => 'Δημιουργία εφαρμογής';

  @override
  String get chatCreateAppCta => 'Δημιουργία εφαρμογής για μένα';

  @override
  String get chatAppNameLabel => 'Όνομα εφαρμογής';

  @override
  String get chatBotDisplayNameLabel =>
      'Όνομα bot (τι πληκτρολογούν τα μέλη μετά το @)';

  @override
  String get chatDescriptionLabel => 'Σύντομη περιγραφή';

  @override
  String get chatAgentDescriptionLabel => 'Τι λέει το bot ότι μπορεί να κάνει';

  @override
  String get chatCommandLabel => 'Εντολή κάθετου';

  @override
  String get chatDirectMessages => 'Άμεσα μηνύματα';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'Επιτρέπει στα μέλη να συνομιλούν με το bot σε DM. Μπορεί να χρειάζεται επί πληρωμή πλάνο $provider.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return 'Το $provider δημιούργησε την εφαρμογή ⁨$appId⁩.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'Απομένουν μερικά βήματα και μόνο το $provider μπορεί να τα κάνει:';
  }

  @override
  String get chatStepAppToken => 'Δημιουργία token επιπέδου εφαρμογής';

  @override
  String get chatStepInstall => 'Εγκατάσταση της εφαρμογής';

  @override
  String get chatOpenAppSettings => 'Άνοιγμα ρυθμίσεων εφαρμογής';

  @override
  String get chatContinueToCredentials => 'Επικόλληση των διαπιστευτηρίων';

  @override
  String chatBotUpdated(String provider) {
    return 'Το bot ενημερώθηκε στο $provider.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return 'Το $provider άλλαξε τα δικαιώματα της εφαρμογής. Επανεγκαταστήστε την εφαρμογή για να ισχύσουν.';
  }

  @override
  String get chatReinstallApp => 'Επανεγκατάσταση εφαρμογής';

  @override
  String chatIconNotEditable(String provider) {
    return 'Το εικονίδιο του bot μπορεί να αλλάξει μόνο στις ρυθμίσεις εφαρμογής του ίδιου του $provider.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'Μπορείτε επίσης να τη δημιουργήσετε στο $provider μόνοι σας — χωρίς token. Οι ρυθμίσεις παραπάνω ταξιδεύουν με τον σύνδεσμο.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'Δημιουργία στο $provider';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return 'Το $provider άνοιξε στο πρόγραμμα περιήγησής σας με αυτή τη ρύθμιση προ συμπληρωμένη. Δημιουργήστε την εφαρμογή εκεί, ολοκληρώστε αυτά τα βήματα και επιστρέψτε με τα token.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return 'Το $provider δεν αναφέρει ποια εφαρμογή δημιούργησε, οπότε η προσαρμογή του bot από εδώ χρειάζεται αργότερα token ρύθμισης εφαρμογής.';
  }

  @override
  String get chatStepCreateApp =>
      'Δημιουργία της εφαρμογής από την προ συμπληρωμένη ρύθμιση';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'Επιλέξτε χώρο εργασίας στο $provider και επιβεβαιώστε.';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens, με το εύρος connections:write.';

  @override
  String get chatStepInstallHint =>
      'Install app → αντιγράψτε το bot user OAuth token.';

  @override
  String get calendarUseBuiltinApp =>
      'Χρήση της εφαρμογής Google του Control Center';

  @override
  String get calendarUseBuiltinAppHint =>
      'Εγκρίνετε με τον λογαριασμό σας Google. Τίποτα να ρυθμίσετε στο Google Cloud.';

  @override
  String get calendarUseOwnClient => 'Χρήση του δικού μου πελάτη Google Cloud';

  @override
  String get calendarUseOwnClientHint =>
      'Εισαγάγετε έναν πελάτη OAuth από το δικό σας έργο Google Cloud.';

  @override
  String get aboutTitle => 'Πληροφορίες';

  @override
  String get aboutAppVersion => 'Έκδοση εφαρμογής';

  @override
  String get aboutServerVersion => 'Συνδεδεμένος διακομιστής';

  @override
  String get aboutRpcCatalog => 'Κατάλογος RPC';

  @override
  String get aboutServerUnknown => 'Δεν αναφέρθηκε';

  @override
  String get serverStaleTitle =>
      'Ο ενσωματωμένος διακομιστής είναι παλαιότερος από αυτή την εφαρμογή';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'Ο τρέχων cc_server είναι ⁨$serverVersion⁩ ενώ αυτή η εφαρμογή είναι ⁨$appVersion⁩. Επανεκκινήστε την εφαρμογή ώστε να πάρει την πιο πρόσφατη ενσωματωμένη έκδοση διακομιστή· στην ανάπτυξη, ξαναχτίστε την με `dart build cli` στο apps/cc_server.';
  }

  @override
  String get updateCheckButton => 'Έλεγχος ενημερώσεων';

  @override
  String get updateChecking => 'Έλεγχος ενημερώσεων…';

  @override
  String get updateUpToDate => 'Είστε ενημερωμένοι';

  @override
  String get updateDeferredBusy =>
      'Μια ενημέρωση είναι έτοιμη αλλά μια σύσκεψη ηχογραφείται — θα εμφανιστεί μετά το τέλος της.';

  @override
  String get updateOpenedReleasesPage =>
      'Άνοιξε η σελίδα εκδόσεων στο πρόγραμμα περιήγησής σας.';

  @override
  String get updateCheckFailed => 'Ο έλεγχος ενημερώσεων απέτυχε';

  @override
  String updateAvailableVersion(String version) {
    return 'Η έκδοση $version είναι διαθέσιμη.';
  }

  @override
  String get updateBannerTitle => 'Ένα νέο Control Center είναι διαθέσιμο';

  @override
  String get updateBannerRefresh => 'Ανανέωση';

  @override
  String get updateBlockedRecording =>
      'Η ανανέωση είναι σε παύση όσο ηχογραφείται μια σύσκεψη — θα φορτωθεί ξανά όταν τελειώσει.';

  @override
  String get settingsScopeYou => 'Εσείς';

  @override
  String get settingsScopeWorkspace => 'Χώρος εργασίας';

  @override
  String get settingsScopeServer => 'Διακομιστής';

  @override
  String get settingsProfile => 'Προφίλ και ταυτότητα';

  @override
  String get settingsYourDevices => 'Οι συσκευές σας';

  @override
  String get settingsWorkspaceGeneral => 'Γενικά';

  @override
  String get settingsServerConnection => 'Σύνδεση και κατάσταση';

  @override
  String get settingsModelProviders => 'Πάροχοι μοντέλων';

  @override
  String get settingsVoiceModels => 'Μοντέλα φωνής και συσκέψεων';

  @override
  String get settingsDiagnostics => 'Διαγνωστικά και απόρρητο';

  @override
  String get settingsAbout => 'Πληροφορίες';

  @override
  String get settingsScopeBadgeYou => 'ΕΣΕΙΣ';

  @override
  String get settingsScopeBadgeDevice => 'ΑΥΤΗ Η ΣΥΣΚΕΥΗ';

  @override
  String get settingsScopeBadgeWorkspace => 'ΧΩΡΟΣ ΕΡΓΑΣΙΑΣ';

  @override
  String get settingsScopeBadgeServer => 'ΔΙΑΚΟΜΙΣΤΗΣ';

  @override
  String get settingsProfileDescription =>
      'Το όνομα, το email και η ταυτότητα git σας σε αυτόν τον χώρο. Η αλλαγή χώρου αλλάζει αυτή την επικάλυψη· το αναγνωριστικό, η σύνδεση και οι συσκευές μένουν στον λογαριασμό.';

  @override
  String get settingsServerConnectionDescription =>
      'Με ποιον διακομιστή μιλά αυτός ο πελάτης και πώς κοινοποιείται αυτός ο διακομιστής (mDNS, σήραγγες, αναμετάδοση).';

  @override
  String get settingsAboutDescription => 'Ταυτότητα έκδοσης και ενημερώσεις.';

  @override
  String get settingsDiagnosticsDescription =>
      'Απομόνωση, ευρετηρίαση, συγχρονισμός, καταγραφή και αναφορά σφαλμάτων για αυτή την εγκατάσταση.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'Ταυτότητα, πολιτική και συμβάσεις που μοιράζονται όλοι σε αυτόν τον χώρο εργασίας.';

  @override
  String get settingsWorkspaceMeetingsDescription =>
      'Πρότυπα σημειώσεων και αποθηκευμένες φωνές για τις συσκέψεις αυτού του χώρου εργασίας.';

  @override
  String get settingsWorkspacePolicyLabel => 'Πολιτική χώρου εργασίας';

  @override
  String get settingsWorkspacePolicyDescription =>
      'Ισχύει για κάθε μέλος και κάθε πράκτορα σε αυτόν τον χώρο εργασίας.';

  @override
  String get settingsSecretGlobsLabel => 'Εξαιρέσεις διαδρομών μυστικών';

  @override
  String get settingsSecretGlobsHelp =>
      'Ένα glob ανά γραμμή. Αυτές οι διαδρομές κρύβονται από θεατές και επισκέπτες σε επιφάνειες με κώδικα, επιπλέον των ενσωματωμένων προεπιλογών.';

  @override
  String get settingsReviewConcurrencyLabel => 'Διασπορά ανασκόπησης';

  @override
  String get settingsReviewConcurrencyHelp =>
      'Πόσοι αναθεωρητές αποστέλλονται παράλληλα όταν δεν δίνεται ρητός αριθμός.';

  @override
  String get settingsReviewLevelLabel => 'Επίπεδο ανασκόπησης';

  @override
  String get settingsReviewLevelHelp =>
      'Πόσο βαθιά πάει η ανασκόπηση AI και πόσα από όσα βρίσκει αναφέρονται εξαρχής. Τίποτα δεν απορρίπτεται — ένα ελαφρύτερο επίπεδο ομαδοποιεί τα ήσσονα ευρήματα αντί να τα παραλείπει.';

  @override
  String get reviewLevelLight => 'Ελαφρύ';

  @override
  String get reviewLevelBalanced => 'Ισορροπημένο';

  @override
  String get reviewLevelThorough => 'Εξαντλητικό';

  @override
  String get reviewLevelLightHint =>
      'Ένας αναθεωρητής. Μόνο ό,τι έχει ουσιαστική σημασία αναφέρεται εξαρχής.';

  @override
  String get reviewLevelBalancedHint =>
      'Τρεις αναθεωρητές που καλύπτουν QA, αρχιτεκτονική και υλοποίηση.';

  @override
  String get reviewLevelThoroughHint =>
      'Προσθέτει ειδικούς ασφαλείας και απόδοσης και αναφέρει ό,τι βρέθηκε.';

  @override
  String get askAiReviewAtLevel => 'Ανασκόπηση σε διαφορετικό επίπεδο';

  @override
  String reviewNitpicksGroup(int count) {
    return 'Μικροπαρατηρήσεις ($count)';
  }

  @override
  String get reviewFindingResolve => 'Διορθώθηκε';

  @override
  String get reviewFindingResolveHint =>
      'Σημειώστε αυτό το εύρημα ως διορθωμένο. Σταματά να μετράει στην ανασκόπηση.';

  @override
  String get reviewFindingDismiss => 'Απόρριψη';

  @override
  String get reviewFindingDismissHint =>
      'Δεν είναι πραγματικό πρόβλημα. Οι αναθεωρητές σταματούν να επισημαίνουν αυτό το μοτίβο σε μελλοντικά PR.';

  @override
  String get reviewFindingReopen => 'Επανάνοιγμα';

  @override
  String get reviewFindingStatusUndoLabel => 'Κατάσταση ευρήματος';

  @override
  String get reviewFindingDismissTitle => 'Απόρριψη αυτού του ευρήματος';

  @override
  String get reviewFindingDismissReasonHint =>
      'Γιατί δεν ισχύει αυτό; Οι αναθεωρητές θα το διαβάσουν.';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'Δεν ήταν δυνατή η ενημέρωση του ευρήματος: ⁨$error⁩';
  }

  @override
  String get reviewStaleTitle => 'Αυτή η ανασκόπηση είναι παρωχημένη';

  @override
  String get reviewStaleBody =>
      'Το pull request έχει προχωρήσει από τότε που έτρεξε αυτή η ανασκόπηση. Τα ευρήματα μπορεί να δείχνουν σε κώδικα που δεν υπάρχει πλέον.';

  @override
  String reviewStaleReviewedAt(String sha) {
    return 'Ανασκοπήθηκε στο ⁨$sha⁩';
  }

  @override
  String get reviewStaleRerun => 'Ανασκόπηση ξανά';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return 'Παρωχημένη ανασκόπηση στο #$prNumber';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return 'Το $title έχει νέα commit από την τελευταία ανασκόπησή του.';
  }

  @override
  String get reviewCategorySecurity => 'Ασφάλεια';

  @override
  String get reviewCategoryStability => 'Σταθερότητα';

  @override
  String get reviewCategoryDataIntegrity => 'Ακεραιότητα δεδομένων';

  @override
  String get reviewCategoryCorrectness => 'Ορθότητα';

  @override
  String get reviewCategoryPerformance => 'Απόδοση';

  @override
  String get reviewCategoryMaintainability => 'Συντηρησιμότητα';

  @override
  String get reviewEffortQuickWin => 'Γρήγορη νίκη';

  @override
  String get reviewEffortModerate => 'Μέτριο';

  @override
  String get reviewEffortHeavyLift => 'Βαρύ έργο';

  @override
  String get reviewProposedFix => 'Προτεινόμενη διόρθωση';

  @override
  String get reviewAiAgentPrompt => 'Προτροπή για πράκτορες AI';

  @override
  String get reviewCopyAiPrompt => 'Αντιγραφή προτροπής';

  @override
  String get settingsWorkspaceAdminOnly =>
      'Μόνο οι διαχειριστές του χώρου εργασίας μπορούν να τα αλλάξουν.';

  @override
  String get chatMyAccountsTitle => 'Συνδεδεμένοι λογαριασμοί συνομιλίας';

  @override
  String get settingsServerSso => 'Ενιαία σύνδεση';

  @override
  String get settingsServerSsoDescription =>
      'Σύνδεση SAML και OpenID Connect με παροχή χρηστών';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription =>
      'Οι χρήστες μπορούν να συνδεθούν με αυτόν τον πάροχο';

  @override
  String get ssoEnabledDescriptionOn =>
      'Η σύνδεση είναι ζωντανή για αυτόν τον πάροχο';

  @override
  String get ssoIdpMetadataLabel => 'XML μεταδεδομένων IdP';

  @override
  String get ssoIdpMetadataHint =>
      'επικολλήστε το XML EntityDescriptor του IdP';

  @override
  String get ssoEmailAttributeLabel => 'Χαρακτηριστικό email';

  @override
  String get ssoDisplayNameAttributeLabel =>
      'Χαρακτηριστικό εμφανιζόμενου ονόματος';

  @override
  String get ssoGroupsAttributeLabel => 'Χαρακτηριστικό ομάδων';

  @override
  String get ssoIssuerLabel => 'URL εκδότη';

  @override
  String get ssoClientIdLabel => 'Client ID';

  @override
  String get ssoGroupsClaimLabel => 'Διεκδίκηση ομάδων';

  @override
  String get ssoAutoMemberLabel =>
      'Προσθήκη χρηστών σε κάθε χώρο εργασίας στην πρώτη σύνδεση';

  @override
  String get ssoAutoMemberDescription =>
      'Απενεργοποιήστε για να απαιτείται πρόσκληση ανά χώρο εργασίας';

  @override
  String get ssoAllowJitLabel => 'Παροχή άγνωστων χρηστών στην πρώτη σύνδεση';

  @override
  String get ssoAllowJitDescription =>
      'Απενεργοποιήστε για απόρριψη χρηστών χωρίς υπάρχοντα λογαριασμό';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'Αποδοχή μη ζητηθείσας (IdP-initiated) σύνδεσης';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'Αυστηρά για πύλες IdP που εκκινούν εφαρμογές απευθείας';

  @override
  String get ssoWantResponseSignedLabel =>
      'Απαίτηση υπογεγραμμένου φακέλου απάντησης';

  @override
  String get ssoWantResponseSignedDescription =>
      'Οι υπογραφές assertion απαιτούνται πάντα';

  @override
  String get ssoTestConnectionButton => 'Δοκιμή σύνδεσης';

  @override
  String get ssoTestConnectionOk => 'Η σύνδεση λειτουργεί:';

  @override
  String get ssoCopySpMetadata => 'Αντιγραφή μεταδεδομένων SP';

  @override
  String get ssoCopySpMetadataDone =>
      'Τα μεταδεδομένα SP αντιγράφηκαν στο πρόχειρο';

  @override
  String get ssoSavedToast => 'Οι ρυθμίσεις ενιαίας σύνδεσης αποθηκεύτηκαν';

  @override
  String get ssoUnavailable =>
      'Αυτός ο διακομιστής δεν εκθέτει ρυθμίσεις ενιαίας σύνδεσης. Ενημερώστε το δυαδικό του διακομιστή και δοκιμάστε ξανά.';

  @override
  String get ssoScimCardTitle => 'Παροχή χρηστών (SCIM)';

  @override
  String get ssoScimDescription =>
      'Στρέψτε τον σύνδεσμο SCIM του παρόχου ταυτότητας στο παρακάτω endpoint με bearer token. Η αποπαροχή ανακαλεί συνεδρίες και πρόσβαση χώρου εργασίας μέσα σε δευτερόλεπτα. Ο διακομιστής πρέπει να είναι προσβάσιμος από το IdP (σήραγγα ή δημόσιο URL).';

  @override
  String get ssoScimEndpoint => 'Endpoint SCIM';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'Ορίστε πρώτα το δημόσιο URL του διακομιστή ή ενεργοποιήστε σήραγγα';

  @override
  String get ssoScimRegenerate => 'Αναγέννηση token';

  @override
  String get ssoScimRegenerateConfirm =>
      'Δημιουργία νέου bearer token SCIM; Το προηγούμενο token σταματά αμέσως να λειτουργεί.';

  @override
  String get ssoScimTokenTitle => 'Bearer token';

  @override
  String get ssoScimTokenPresent => 'Έχει ρυθμιστεί token';

  @override
  String get ssoScimTokenAbsent =>
      'Δεν υπάρχει ακόμη token — δημιουργήστε ένα για ενεργοποίηση SCIM';

  @override
  String get ssoScimTokenOnce => 'Token SCIM (εμφανίζεται μία φορά)';

  @override
  String ssoSignInWith(String provider) {
    return 'Σύνδεση με $provider';
  }

  @override
  String get ssoProbeFailed =>
      'Δεν ήταν δυνατή η πρόσβαση σε αυτόν τον διακομιστή για ενιαία σύνδεση';

  @override
  String get ssoOpensBrowser =>
      'Ανοίγει το πρόγραμμα περιήγησής σας για ολοκλήρωση της σύνδεσης';

  @override
  String get ssoWaitingForBrowser =>
      'Αναμονή ολοκλήρωσης της σύνδεσης στο πρόγραμμα περιήγησης…';

  @override
  String get ssoBrowserOpenFailed =>
      'Δεν ήταν δυνατό το άνοιγμα του προγράμματος περιήγησης για ενιαία σύνδεση';

  @override
  String get ssoUseManualPairing =>
      'Σύνδεση με πρόσκληση ή κλειδί σύζευξης αντ\' αυτού';

  @override
  String get ssoHideManualPairing => 'Απόκρυψη χειροκίνητης σύζευξης';

  @override
  String get ssoClientIdHint =>
      'Δημόσιος πελάτης (PKCE) — δεν χρειάζεται μυστικό';

  @override
  String get ssoClientSecretLabel => 'Μυστικό πελάτη (προαιρετικό)';

  @override
  String get ssoClientSecretHintUnset =>
      'Χρειάζεται μόνο για εμπιστευτικούς πελάτες IdP';

  @override
  String get ssoClientSecretHintSet =>
      'Έχει αποθηκευτεί μυστικό — αφήστε κενό για να το κρατήσετε';

  @override
  String get ssoPairingToggle =>
      'Να επιτρέπεται χειροκίνητη σύζευξη (κωδικοί πρόσκλησης και κλειδιά σύζευξης)';

  @override
  String get ssoPairingToggleDescription =>
      'Απενεργοποιήστε για να γίνεται η ένταξη μόνο μέσω ενιαίας σύνδεσης — οι νέες συσκευές φτάνουν μέσω συνδέσεων SSO· οι υπάρχουσες συσκευές συνεχίζουν να λειτουργούν';

  @override
  String get ssoPairConfirmTitle => 'Σύνδεση στον διακομιστή;';

  @override
  String ssoPairConfirmBody(String server) {
    return 'Έφτασε διαπιστευτήριο σύνδεσης για το ⁨$server⁩, αλλά δεν ξεκίνησε σύνδεση από αυτή την εφαρμογή. Σύνδεση σε αυτόν τον διακομιστή;';
  }

  @override
  String get ssoPairConfirmConnect => 'Σύνδεση';

  @override
  String get ssoPairConfirmCancel => 'Παράβλεψη';

  @override
  String get forgeConnections => 'Φιλοξενία κώδικα';

  @override
  String get connect => 'Σύνδεση';

  @override
  String get disconnect => 'Αποσύνδεση';

  @override
  String get notConnected => 'Δεν έχει συνδεθεί';

  @override
  String get checkingConnection => 'Έλεγχος σύνδεσης…';

  @override
  String get fromEnvironment => 'από το περιβάλλον';

  @override
  String forgeTokenTitle(String forge) {
    return 'Token $forge';
  }

  @override
  String get settingsAudio => 'Ήχος';

  @override
  String get settingsAudioDescription =>
      'Μικρόφωνο, υπαγόρευση, ανίχνευση συσκέψεων και έξοδος ηχοτοπίου.';

  @override
  String get audioDevicesSection => 'Συσκευές ήχου';

  @override
  String get voiceInputBehaviorSection => 'Υπαγόρευση και συσκέψεις';

  @override
  String get audioOutputDeviceTitle => 'Συσκευή εξόδου';

  @override
  String get audioOutputDefaultHint =>
      'Όλος ο ήχος της εφαρμογής παίζει μέσω της προεπιλεγμένης εξόδου συστήματος.';

  @override
  String get audioOutputGone =>
      'Η επιλεγμένη συσκευή εξόδου δεν είναι πλέον συνδεδεμένη — χρησιμοποιείται η προεπιλογή συστήματος μέχρι να επιλέξετε άλλη.';

  @override
  String get reviewHubIntroBody =>
      'Οι πράκτορες αναλύουν το diff, χαρτογραφούν τις περιοχές αλλαγής και καταλήγουν σε κοινή ετυμηγορία.';

  @override
  String get reviewHubAlreadyRunning =>
      'Μια ανασκόπηση εκτελείται ήδη για αυτό το pull request';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'Από την τελευταία ανασκόπηση: $resolved επιλύθηκαν · $added νέα · $open ακόμη ανοιχτά';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'Προηγουμένως ανασκοπήθηκε στο ⁨$sha⁩';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return 'Διόρθωση $count ευρημάτων';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return 'Διόρθωση $count επιλεγμένων';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return 'Σχόλιο σε $count επιλεγμένα';
  }

  @override
  String get webConnectTitle => 'Σύνδεση στο Control Center';

  @override
  String get webConnectSubtitle =>
      'Κλήση σε τρέχοντα cc-server μέσω WebSocket. Το κλειδί σας μένει σε αυτή τη συσκευή.';

  @override
  String get webConnectServerLabel => 'Διακομιστής';

  @override
  String get webConnectDeviceIdLabel => 'ID συσκευής';

  @override
  String get webConnectPairingKeyLabel => 'Κλειδί σύζευξης';

  @override
  String get webConnectPairingKeyHint => 'επικολλήστε το PSK';

  @override
  String get webConnectStayConnected =>
      'Να παραμένει συνδεδεμένο σε αυτή τη συσκευή';

  @override
  String get webConnectStayConnectedDetail =>
      'Να παραμένει συνδεδεμένο σε αυτή τη συσκευή (αποθηκεύει το κλειδί σε αυτό το πρόγραμμα περιήγησης)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'Αποτυχία δημιουργίας χώρου εργασίας: ⁨$error⁩';
  }

  @override
  String committedRelative(String relative) {
    return 'commit $relative';
  }

  @override
  String get selectAgents => 'Επιλογή πρακτόρων';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count πράκτορες',
      one: '1 πράκτορας',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => 'Νέα συνομιλία';

  @override
  String get untitledConversation => 'Συνομιλία χωρίς τίτλο';

  @override
  String get conversationTitleOptionalHint =>
      'Προαιρετικό — αφήστε κενό και το μοντέλο τίτλων το ονομάζει αυτόματα';

  @override
  String get conversationTitlesSectionTitle => 'Τίτλοι συνομιλιών';

  @override
  String get conversationTitlesSectionCaption =>
      'Επιλέξτε τον εκτελεστή που ονομάζει αυτόματα νέες συνομιλίες σε αυτόν τον χώρο εργασίας. Οι τίτλοι μένουν απενεργοποιημένοι μέχρι να επιλεγεί προσαρμογέας και ισχύουν για κάθε μέλος.';

  @override
  String get conversationTitlesModelLabel => 'Μοντέλο τίτλων';

  @override
  String get conversationTitlesAdapterLabel => 'Προσαρμογέας';

  @override
  String get conversationTitlesAdapterHint => 'Ανενεργό';

  @override
  String get conversationTitlesAdapterOff => 'Ανενεργό';

  @override
  String get startThread => 'Έναρξη νήματος';

  @override
  String get deleteSpaceConfirm =>
      'Διαγραφή αυτού του χώρου; Όλα τα μηνύματα θα χαθούν.';

  @override
  String threadTabTitle(String title) {
    return 'Νήμα: $title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count απαντήσεις',
      one: '1 απάντηση',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return 'Τελευταία απάντηση $time';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Σύνδεση με $provider';
  }

  @override
  String get signInAgain => 'Σύνδεση ξανά';

  @override
  String get signInNotFinished =>
      'Η σύνδεση δεν έχει επιστρέψει ακόμη. Ολοκληρώστε την στο πρόγραμμα περιήγησης και ελέγξτε ξανά.';

  @override
  String get signedOutTitle => 'Έχετε αποσυνδεθεί';

  @override
  String get signedOutSubtitle =>
      'Η σύνδεση φιλοξενίας κώδικα δεν είναι πλέον έγκυρη — ένα token έληξε ή η πρόσβασή του ανακλήθηκε. Τίποτα άλλο δεν άλλαξε: συνδεθείτε ξανά και όλα είναι εκεί που τα αφήσατε.';

  @override
  String get viaServerApp => 'μέσω της εφαρμογής αυτού του διακομιστή';

  @override
  String get ticketing => 'Εισιτήρια';

  @override
  String get ticketingProviderHelp =>
      'Πού ζουν τα εισιτήριά σας. Το τοπικό τα κρατά στο Control Center.';

  @override
  String providerComingSoon(String provider) {
    return '$provider (σύντομα)';
  }

  @override
  String get ticketProviderLocal => 'Τοπικό';

  @override
  String get addKey => 'Προσθήκη κλειδιού';

  @override
  String get providerApps => 'Εφαρμογές παρόχων';

  @override
  String get providerAppsDescription =>
      'Οι χώροι εργασίας κληρονομούν αυτό το GitHub App εκτός αν επιλέξουν άλλο App ή προσωπικό διακριτικό. Η εργασία στο παρασκήνιο — webhooks, polling, sync — τρέχει στην εφαρμογή, ποτέ στο διακριτικό ενός ατόμου.';

  @override
  String get providerAppId => 'ID εφαρμογής';

  @override
  String get providerPrivateKey => 'Ιδιωτικό κλειδί';

  @override
  String get providerClientId => 'Client id';

  @override
  String get providerClientSecret => 'Μυστικό πελάτη';

  @override
  String get providerApiKey => 'Κλειδί API';

  @override
  String get providerCallbackUrl => 'URL επιστροφής';

  @override
  String get providerAppFullyConfigured =>
      'Ο διακομιστής μπορεί να ενεργεί ως ο εαυτός του και οι άνθρωποι μπορούν να συνδεθούν.';

  @override
  String get providerAppServerOnly =>
      'Ο διακομιστής μπορεί να ενεργεί ως ο εαυτός του. Προσθέστε client id και μυστικό για να μπορούν οι άνθρωποι να συνδεθούν.';

  @override
  String get providerAppSignInOnly =>
      'Οι άνθρωποι μπορούν να συνδεθούν. Η εργασία παρασκηνίου πέφτει στα διαπιστευτήριά τους.';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'Τα διαπιστευτήρια λειτουργούν. Εγκατεστημένα σε: ⁨$accounts⁩';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return 'Εισαγάγετε αυτόν τον κωδικό στη σελίδα $provider που μόλις άνοιξε. Έχει αντιγραφεί στο πρόχειρό σας.';
  }

  @override
  String get deviceCodeWaiting =>
      'Αναμονή ολοκλήρωσης στο πρόγραμμα περιήγησης…';

  @override
  String get copyCodeAndOpen => 'Αντιγραφή κωδικού και άνοιγμα';

  @override
  String get couldNotOpenBrowser =>
      'Δεν ήταν δυνατό το άνοιγμα προγράμματος περιήγησης. Αντιγράψτε τον σύνδεσμο και ολοκληρώστε τη σύνδεση μόνοι σας.';

  @override
  String get contextUsage => 'Χρήση συμφραζομένων';

  @override
  String get contextUsageFull => 'γεμάτο';

  @override
  String get contextUsageTokens => 'token';

  @override
  String get contextSeeMore => 'Δείτε περισσότερα';

  @override
  String get contextSegmentSystemPrompt => 'Προτροπή συστήματος';

  @override
  String get contextSegmentRules => 'Κανόνες';

  @override
  String get contextSegmentSkills => 'Δεξιότητες';

  @override
  String get contextSegmentToolDefinitions => 'Ορισμοί εργαλείων';

  @override
  String get contextSegmentMcpTools => 'MCP και δυναμικά εργαλεία';

  @override
  String get contextSegmentDeferredTools => 'Εργαλεία κατ\' απαίτηση';

  @override
  String get contextSegmentSubagents => 'Ορισμοί υποπρακτόρων';

  @override
  String get contextSegmentMemory => 'Μνήμη';

  @override
  String get contextSegmentConversation => 'Συνομιλία';

  @override
  String get contextExplorerTitle => 'Συμφραζόμενα';

  @override
  String get contextExplorerEverything => 'Όλα';

  @override
  String get contextExplorerSelectPart =>
      'Επιλέξτε ένα μέρος για να επιθεωρήσετε το περιεχόμενό του';

  @override
  String get contextExplorerUnavailable =>
      'Η ανάλυση συμφραζομένων δεν είναι διαθέσιμη';

  @override
  String get contextRetry => 'Επανάληψη';

  @override
  String get settingsFieldOptional => 'Προαιρετικό';

  @override
  String get settingsFilterHint => 'Φιλτράρισμα αυτής της λίστας';

  @override
  String get settingsValueNotAvailable => 'Δεν είναι ακόμη διαθέσιμο';

  @override
  String get settingsNoEntriesYet => 'Δεν υπάρχει τίποτα ακόμη';

  @override
  String get settingsChangedBadge => 'Άλλαξε';

  @override
  String get ssoConnectionCardDescription =>
      'Επιλέξτε πώς συνδέονται οι άνθρωποι σε αυτόν τον διακομιστή και ενεργοποιήστε αυτή τη σύνδεση.';

  @override
  String get ssoUseSamlForSignIn => 'Χρήση SAML για σύνδεση';

  @override
  String get ssoUseOidcForSignIn => 'Χρήση OpenID Connect για σύνδεση';

  @override
  String get ssoSaveConnection => 'Αποθήκευση σύνδεσης';

  @override
  String get ssoStateLive => 'Ζωντανά';

  @override
  String get ssoStateConfiguredOff => 'Ρυθμισμένο, ανενεργό';

  @override
  String get ssoStateOnIncomplete => 'Ενεργό, ημιτελές';

  @override
  String get ssoStateActive => 'Ενεργό';

  @override
  String get ssoStateAllowed => 'Επιτρέπεται';

  @override
  String get ssoStateNoToken => 'Χωρίς token';

  @override
  String get ssoSummaryDirectorySync => 'Συγχρονισμός καταλόγου';

  @override
  String get ssoSummaryManualPairing => 'Χειροκίνητη σύζευξη';

  @override
  String get ssoNoMethodLiveNote =>
      'Καμία μέθοδος σύνδεσης δεν είναι ζωντανή. Οι νέες συσκευές εντάσσονται με πρόσκληση ή κλειδί σύζευξης μέχρι να ρυθμίσετε μια σύνδεση και να την ενεργοποιήσετε.';

  @override
  String get ssoMethodSamlBlurb =>
      'Για παρόχους ταυτότητας που μιλούν SAML 2.0, όπως Okta, Entra ID ή Google Workspace.';

  @override
  String get ssoMethodOidcBlurb =>
      'Για παρόχους ταυτότητας που μιλούν OpenID Connect. Συνήθως η απλούστερη από τις δύο στη ρύθμιση.';

  @override
  String get ssoGroupIdentityProvider => 'Πάροχος ταυτότητας';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'Από πού έρχονται τα assertion και πώς τα επαληθεύει αυτός ο διακομιστής.';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'Ποιον εκδότη εμπιστεύεται αυτός ο διακομιστής και ως ποιον πελάτη αυθεντικοποιείται.';

  @override
  String get ssoSpEntityIdShortLabel => 'SP entity ID';

  @override
  String get ssoSpEntityIdDescription =>
      'Αφήστε κενό για να προκύψει από το URL του διακομιστή.';

  @override
  String get ssoIssuerDescription =>
      'Το βασικό URL που εξυπηρετεί το έγγραφο ανακάλυψης του παρόχου.';

  @override
  String get ssoSecretStored => 'Αποθηκευμένο';

  @override
  String get ssoGroupHandoff => 'Τι χρειάζεται ο πάροχος ταυτότητας';

  @override
  String get ssoGroupHandoffDescription =>
      'Επικολλήστε τα στην εφαρμογή που δημιουργήσατε στον πάροχό σας.';

  @override
  String get ssoOriginUnknownTitle =>
      'Αυτός ο διακομιστής δεν γνωρίζει το δημόσιο URL του';

  @override
  String get ssoOriginUnknownBody =>
      'Τα URL σύνδεσης και επιστροφής χτίζονται από αυτό, οπότε ο πάροχός σας δεν μπορεί να φτάσει αυτόν τον διακομιστή μέχρι να οριστεί ένα. Προσθέστε δημόσιο URL ή ενεργοποιήστε σήραγγα στο Διακομιστής → Σύνδεση.';

  @override
  String get ssoAcsUrlLabel => 'URL υπηρεσίας κατανάλωσης assertion (ACS)';

  @override
  String get ssoAcsUrlDescription =>
      'Πού δημοσιεύει ο πάροχός σας το υπογεγραμμένο assertion.';

  @override
  String get ssoSpEntityIdResolvedLabel => 'Entity ID παρόχου υπηρεσίας';

  @override
  String get ssoMetadataUrlLabel => 'URL μεταδεδομένων SP';

  @override
  String get ssoMetadataUrlDescription =>
      'Οι πάροχοι που εισάγουν μεταδεδομένα μπορούν να τα ανακτήσουν από εδώ αντ\' αυτού.';

  @override
  String get ssoRedirectUriLabel => 'URI ανακατεύθυνσης';

  @override
  String get ssoRedirectUriDescription =>
      'Προσθέστε αυτό στα επιτρεπόμενα URI ανακατεύθυνσης της εφαρμογής του παρόχου σας.';

  @override
  String get ssoSignInUrlLabel => 'URL σύνδεσης';

  @override
  String get ssoSignInUrlDescription =>
      'Στείλτε τους ανθρώπους εδώ για έναρξη σύνδεσης ενιαίας σύνδεσης.';

  @override
  String get ssoGroupAttributeMapping => 'Αντιστοίχιση χαρακτηριστικών';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'Ποια διεκδίκηση μεταφέρει κάθε πεδίο. Κρατήστε τις προεπιλογές εκτός αν ο πάροχός σας τις μετονομάζει.';

  @override
  String get ssoGroupAccess => 'Πρόσβαση και ρόλοι';

  @override
  String get ssoGroupAccessDescription =>
      'Τι επιτρέπεται σε κάποιον που συνδέεται επιτυχώς.';

  @override
  String get ssoDefaultRoleShortLabel => 'Προεπιλεγμένος ρόλος';

  @override
  String get ssoDefaultRoleDescription =>
      'Δίνεται σε όποιον οι ομάδες του δεν ταιριάζουν με καμία αντιστοίχιση παρακάτω.';

  @override
  String get ssoRoleMapShortLabel => 'Αντιστοίχιση ομάδας σε ρόλο';

  @override
  String get ssoRoleMapDescription =>
      'Η πρώτη ομάδα που ταιριάζει κερδίζει. Ο ιδιοκτήτης δεν μπορεί να χορηγηθεί με αυτόν τον τρόπο.';

  @override
  String get ssoRoleMapGroupHint => 'Όνομα ομάδας από τον πάροχό σας';

  @override
  String get ssoRoleMapAdd => 'Προσθήκη αντιστοίχισης';

  @override
  String get ssoRoleMapEmpty =>
      'Χωρίς αντιστοιχίσεις — όλοι παίρνουν τον προεπιλεγμένο ρόλο.';

  @override
  String get ssoAdvancedSummary =>
      'Απόκλιση ρολογιού, σύνδεση IdP-initiated, πολιτική υπογραφής';

  @override
  String get ssoClockSkewShortLabel => 'Απόκλιση ρολογιού';

  @override
  String get ssoClockSkewDescription =>
      'Δευτερόλεπτα ανοχής στα χρονοσήματα assertion. Το 90 ταιριάζει στους περισσότερους παρόχους.';

  @override
  String get ssoScimGenerate => 'Δημιουργία token';

  @override
  String get ssoScimTokenOnceBody =>
      'Αντιγράφηκε στο πρόχειρό σας. Εμφανίζεται μία φορά και δεν μπορεί να ανακτηθεί, οπότε επικολλήστε το στον πάροχό σας τώρα.';

  @override
  String get ssoPairingCardTitle => 'Χειροκίνητη σύζευξη';

  @override
  String get ssoPairingCardDescription =>
      'Ο άλλος τρόπος σε αυτόν τον διακομιστή: κωδικοί πρόσκλησης και κλειδιά σύζευξης, για συσκευές που δεν περνούν από ενιαία σύνδεση.';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count από $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'Κανένας πάροχος δεν είναι συνδεδεμένος, οπότε ο ενσωματωμένος χρόνος εκτέλεσης πρακτόρων δεν έχει πού να τρέξει. Προσθέστε ένα κλειδί API ή συνδεθείτε σε έναν παρακάτω.';

  @override
  String get providersFilterHint => 'Φιλτράρισμα παρόχων';

  @override
  String get providersNoneMatch => 'Τίποτα δεν ταιριάζει με αυτό το φίλτρο';

  @override
  String get providerDeniedHereTitle =>
      'Απορρίφθηκε σε αυτόν τον χώρο εργασίας';

  @override
  String get providerDeniedHereBody =>
      'Οι πράκτορες εδώ δεν μπορούν να χρησιμοποιήσουν αυτόν τον πάροχο, παρότι είναι συνδεδεμένος. Οι άλλοι χώροι εργασίας δεν επηρεάζονται.';

  @override
  String get providerNeedsSignIn =>
      'Συνδεθείτε για να χρησιμοποιήσετε αυτόν τον πάροχο';

  @override
  String get providerNeedsApiKey =>
      'Προσθέστε ένα κλειδί API για να χρησιμοποιήσετε αυτόν τον πάροχο';

  @override
  String get providerApiKeyLabel => 'Κλειδί API';

  @override
  String get providerGenerationDefaults => 'Προεπιλογές παρόχου';

  @override
  String get providerNoModelsYet =>
      'Δεν έχουν αναφερθεί ακόμη μοντέλα. Συνδέστε τον πάροχο και μετά συγχρονίστε.';

  @override
  String get providerModelsFilterHint => 'Φιλτράρισμα μοντέλων';

  @override
  String get adaptersNoneReadyNote =>
      'Κανένα από τα καταλογογραφημένα CLI εκτελεστών δεν βρέθηκε σε αυτό το μηχάνημα. Εγκαταστήστε ένα και μετά ανανεώστε.';

  @override
  String get adaptersFilterHint => 'Φιλτράρισμα εκτελεστών';

  @override
  String get adaptersLaunchGroup => 'Εκκίνηση';

  @override
  String get adaptersLaunchGroupDescription =>
      'Τι δίνεται σε αυτόν τον εκτελεστή όταν τον ξεκινά ένας πράκτορας. Ορίστε τα πριν την εγκατάσταση του CLI αν θέλετε.';

  @override
  String get adaptersEnvNone => 'Κανένα ορισμένο';

  @override
  String adaptersEnvCount(int count) {
    return '$count ορισμένα';
  }

  @override
  String get adapterArgumentsDescription =>
      'Προσαρτώνται στη γραμμή εντολών του εκτελεστή σε κάθε εκκίνηση.';

  @override
  String get defaultChatDescription =>
      'Τρέχει νέες συνομιλίες και κάθε πράκτορα χωρίς δικό του εκτελεστή.';

  @override
  String get shortTaskDescription =>
      'Τρέχει γρήγορη εργασία παρασκηνίου όπως τίτλους και περιλήψεις. Ένα μικρότερο μοντέλο ανήκει εδώ.';

  @override
  String get settingsStateFailed => 'Απέτυχε';

  @override
  String get providerAppsGroupServer => 'Ενέργεια ως διακομιστής';

  @override
  String get providerAppsGroupServerDescription =>
      'Για χώρους που κληρονομούν το GitHub App αυτής της εγκατάστασης. Ένας χώρος με δικό του App ή PAT ρυθμίζεται στο Χώρος εργασίας → Γενικά.';

  @override
  String get providerAppsGroupPrConversations => 'Συνομιλίες pull request';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'Πώς μιλούν οι προγραμματιστές σε αυτόν τον διακομιστή στο GitHub σε κληρονομούμενους χώρους. Ένας χώρος με δικό του App έχει bot στο Χώρος εργασίας → Γενικά. Χωρίς webhook ή δημόσιο URL — ο διακομιστής κάνει polling.';

  @override
  String get providerAppBotLogin => 'Σύνδεση bot';

  @override
  String get providerAppBotLoginEmpty =>
      'Δοκιμάστε τη σύνδεση για επίλυση της σύνδεσης bot.';

  @override
  String get providerAppAskOnGitHub => 'Ερώτηση στο GitHub';

  @override
  String get providerAppAskOnGitHubHint =>
      'Αναφέρετε τη σύνδεση bot παραπάνω σε σχόλιο pull request — το επίθημα [bot] είναι προαιρετικό — για αίτημα ανασκόπησης ή ερώτηση, απαντήστε μέσα στα νήματα ανασκόπησής του ή προσθέστε την ετικέτα `ai-review` για αίτημα ανασκόπησης.';

  @override
  String get providerAppsGroupSignIn => 'Σύνδεση ανθρώπων';

  @override
  String get providerAppsGroupSignInDescription =>
      'Επιτρέπει σε κάθε μέλος να συνδέσει τον δικό του λογαριασμό και να πάρει δικό του διαπιστευτήριο.';

  @override
  String get providerAppCapActsAsServer => 'Ενεργεί ως διακομιστής';

  @override
  String get providerAppCapSignsIn => 'Συνδέει ανθρώπους';

  @override
  String get portLabel => 'Θύρα';

  @override
  String get mcpNoTokenWarning =>
      'Χωρίς token, οτιδήποτε φτάνει σε αυτή τη θύρα μπορεί να καλέσει κάθε εργαλείο.';

  @override
  String get mcpBridgedToolsLabel => 'Εργαλεία';

  @override
  String get guardrailFamilyFiles => 'Αρχεία';

  @override
  String get guardrailFamilyGit => 'Git και pull request';

  @override
  String get guardrailFamilyMachine => 'Μηχάνημα και δίκτυο';

  @override
  String get guardrailFamilyControl => 'Μυστικά και χώρος εργασίας';

  @override
  String get guardrailScopeFieldLabel => 'Επεξεργασία κανόνων για';

  @override
  String get guardrailScopeFieldDescription =>
      'Ένα στενότερο εύρος κερδίζει έναντι ενός ευρύτερου. Οι κανόνες που ορίζονται εδώ ισχύουν επιπλέον όσων κληρονομούνται.';

  @override
  String get guardrailSetHere => 'Ορισμός εδώ';

  @override
  String get guardrailClearAllHere => 'Εκκαθάριση όλων';

  @override
  String get sandboxingCardLabel => 'Sandboxing';

  @override
  String get sandboxingCardDescription =>
      'Αν η εργασία του πράκτορα τρέχει απομονωμένη από αυτόν τον κεντρικό υπολογιστή και τι μπορεί ακόμη να φτάσει ένας απομονωμένος πράκτορας.';

  @override
  String get sandboxBackendNoneActive =>
      'Κεντρικός υπολογιστής, χωρίς απομόνωση';

  @override
  String get sandboxSummaryHost => 'Κεντρικός υπολογιστής';

  @override
  String get sandboxGroupIsolation => 'Απομόνωση';

  @override
  String get sandboxGroupIsolationDescription =>
      'Πού συμβαίνουν πραγματικά οι διεργασίες και οι εγγραφές αρχείων ενός πράκτορα.';

  @override
  String get sandboxBackendFieldDescription =>
      'Το αυτόματο επιλέγει το ισχυρότερο που υποστηρίζει αυτός ο κεντρικός υπολογιστής. Καρφιτσώστε ένα για να μην αλλάζει από κάτω σας.';

  @override
  String get sandboxCapabilitiesDescription =>
      'Οι τρύπες που ανοίγονται στο όριο. Καθεμία είναι κάτι που ένας απομονωμένος πράκτορας μπορεί ακόμη να κάνει στον έξω κόσμο.';

  @override
  String get sandboxSummaryInForce => 'Σε ισχύ';

  @override
  String get rigsInstallHintLabel => 'Πώς να το εγκαταστήσετε';

  @override
  String get rigsStarting => 'Εκκίνηση';

  @override
  String get rigsResidentMemory => 'Μνήμη κατοίκου';

  @override
  String get installedLabel => 'Εγκατεστημένο';

  @override
  String get notInstalledLabel => 'Δεν έχει εγκατασταθεί';

  @override
  String ssoOtherKindUnsaved(String method) {
    return 'Το $method έχει μη αποθηκευμένες αλλαγές';
  }

  @override
  String get collapseComment => 'Σύμπτυξη σχολίου';

  @override
  String get expandComment => 'Ανάπτυξη σχολίου';

  @override
  String get suggestedChange => 'Προτεινόμενη αλλαγή';

  @override
  String get emptyComment => 'Κενό σχόλιο';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count απαντήσεις',
      one: '1 απάντηση',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => 'Ανασκόπηση σε εκκρεμότητα';

  @override
  String failedToResolveConversation(String error) {
    return 'Δεν ήταν δυνατή η ενημέρωση της συνομιλίας: ⁨$error⁩';
  }

  @override
  String get addSingleComment => 'Προσθήκη μεμονωμένου σχολίου';

  @override
  String get addToReview => 'Προσθήκη στην ανασκόπηση';

  @override
  String get startAReview => 'Έναρξη ανασκόπησης';

  @override
  String get reviewNeedsABody =>
      'Γράψτε πρώτα μια περίληψη ή ουρά ενός ενσωματωμένου σχολίου';

  @override
  String get reviewSubmitted => 'Η ανασκόπηση υποβλήθηκε';

  @override
  String get finishYourReview => 'Ολοκληρώστε την ανασκόπησή σας';

  @override
  String get commentVerdict => 'Σχόλιο';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count σχόλια σε εκκρεμότητα',
      one: '1 σχόλιο σε εκκρεμότητα',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 'και $count ακόμη';
  }

  @override
  String get queuedCommentHint =>
      'Αυτό το σχόλιο βγαίνει όταν υποβάλετε την ανασκόπησή σας.';

  @override
  String commentOnLinesRange(int start, int end) {
    return 'Γραμμές $start έως $end';
  }

  @override
  String get claudeAccountsTitle => 'Λογαριασμοί Claude Code';

  @override
  String get claudeAccountsDescription =>
      'Κάθε λογαριασμός είναι ξεχωριστή σύνδεση Claude Code. Οι εκτελέσεις χρησιμοποιούν τους λογαριασμούς που επισυνάπτονται παρακάτω, με αυτή τη σειρά.';

  @override
  String get claudeAccountsEmpty => 'Δεν υπάρχουν ακόμη λογαριασμοί';

  @override
  String get claudeAccountAdd => 'Προσθήκη λογαριασμού';

  @override
  String get claudeAccountSignIn => 'Σύνδεση';

  @override
  String get claudeAccountSignInAgain => 'Σύνδεση ξανά';

  @override
  String get claudeAccountSignInHint =>
      'Τρέξτε αυτό σε τερματικό στον διακομιστή. Ανοίγει πρόγραμμα περιήγησης για ολοκλήρωση της σύνδεσης και γράφει το διαπιστευτήριο στον κατάλογο αυτού του λογαριασμού.';

  @override
  String get claudeAccountSignedOut => 'Αποσυνδεδεμένος';

  @override
  String get claudeAccountExpired => 'Η σύνδεση έληξε';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'Η σύνδεση έληξε στις $when. Συνδεθείτε ξανά για να χρησιμοποιήσετε αυτόν τον λογαριασμό.';
  }

  @override
  String get claudeAccountMakeDefault => 'Ορισμός ως προεπιλογή';

  @override
  String get claudeAccountDefault => 'Προεπιλογή';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return 'Αφαίρεση του ⁨$label⁩;';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'Αυτό αποσυνδέει τον λογαριασμό και διαγράφει τον κατάλογό του στον διακομιστή. Η ίδια η σύνδεση δεν επηρεάζεται.';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'Δεν ήταν δυνατός ο έλεγχος αυτού του λογαριασμού: ⁨$error⁩';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return '$percent% χρησιμοποιήθηκε';
  }

  @override
  String get accountPoolStrategy => 'Εναλλαγή';

  @override
  String get accountPoolPinned => 'Καρφιτσωμένο';

  @override
  String get accountPoolRoundRobin => 'Round robin';

  @override
  String get accountPoolSerial => 'Ένας τη φορά';

  @override
  String get accountPoolPinnedHint =>
      'Πάντα έναρξη στον πρώτο λογαριασμό. Οι άλλοι μένουν ως εναλλακτική αν αποτύχει.';

  @override
  String get accountPoolRoundRobinHint =>
      'Διασκορπίστε τις εκτελέσεις στους λογαριασμούς, μεταβαίνοντας στον επόμενο σε κάθε αποστολή.';

  @override
  String get accountPoolSerialHint =>
      'Εξαντλήστε τον πρώτο λογαριασμό πριν αγγίξετε τον επόμενο.';

  @override
  String get accountPoolMoveUp => 'Μετακίνηση πάνω';

  @override
  String get accountPoolMoveDown => 'Μετακίνηση κάτω';

  @override
  String get accountPoolUsingAll =>
      'Δεν έχει επισυναφθεί τίποτα ακόμη — χρησιμοποιούνται όλοι οι λογαριασμοί, με αυτή τη σειρά.';

  @override
  String get accountPoolInheriting =>
      'Κληρονομεί τους λογαριασμούς του χώρου εργασίας.';

  @override
  String get accountPoolResetToWorkspace =>
      'Επαναφορά στους λογαριασμούς του χώρου εργασίας';

  @override
  String accountPoolCoolingOff(String when) {
    return 'εκτός ποσόστωσης έως $when';
  }

  @override
  String get accountPoolSignedOut => 'αποσυνδεδεμένος';

  @override
  String get accountPoolExpired => 'η σύνδεση έληξε';

  @override
  String accountPoolLoadFailed(String error) {
    return 'Δεν ήταν δυνατή η φόρτωση της εναλλαγής: ⁨$error⁩';
  }

  @override
  String get providerSignedInAccount => 'συνδεδεμένος λογαριασμός';

  @override
  String get agentAccountsTab => 'Λογαριασμοί';

  @override
  String get agentClaudeAccountsNoticeTitle =>
      'Πολλαπλοί λογαριασμοί Claude Code';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return 'Αυτός ο εκτελεστής συνδέεται ως ένας από τους $count λογαριασμούς Claude Code σε αυτόν τον κεντρικό υπολογιστή. Επιλέξτε ποιον, ή εναλλάξτε μεταξύ τους, στην καρτέλα Λογαριασμοί.';
  }

  @override
  String get agentAccountsDescription =>
      'Ποιους λογαριασμούς χρησιμοποιούν οι εκτελέσεις αυτού του πράκτορα. Κάθε μπλοκ ξεκινά κληρονομώντας την επιλογή του χώρου εργασίας.';

  @override
  String get agentAccountsNothingToRotate =>
      'Τίποτα για εναλλαγή — συνδέστε πρώτα έναν δεύτερο λογαριασμό ή κλειδί.';

  @override
  String failedToPostReply(String error) {
    return 'Δεν ήταν δυνατή η δημοσίευση της απάντησης: ⁨$error⁩';
  }

  @override
  String commentOnLine(int line) {
    return 'Γραμμή $line';
  }

  @override
  String get viewInDiff => 'Προβολή στο diff';

  @override
  String get subscriptionUsagePreviousAccount => 'Προηγούμενος λογαριασμός';

  @override
  String get subscriptionUsageNextAccount => 'Επόμενος λογαριασμός';

  @override
  String inReplyTo(String path) {
    return 'Σε απάντηση στο ⁨$path⁩';
  }

  @override
  String get subscriptionUsageNoneReported =>
      'Δεν αναφέρθηκε χρήση για αυτόν τον λογαριασμό.';

  @override
  String get subscriptionUsageCredits => 'Πιστώσεις';

  @override
  String get reviewHubStaticRule => 'Στατικός κανόνας';

  @override
  String get reviewHubStarted => 'Η ανασκόπηση ξεκίνησε';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'Βρέθηκε από ντετερμινιστικό κανόνα (⁨$rule⁩) σε γραμμή που προσθέτει αυτό το pull request — όχι από πράκτορα αναθεωρητή.';
  }

  @override
  String get prReviewArtifactTab => 'Ανασκόπηση PR';

  @override
  String get prReviewRunning => 'Ανασκόπηση αυτού του pull request…';

  @override
  String get prReviewStarting => 'Έναρξη ανασκόπησης…';

  @override
  String get prReviewStartingBody =>
      'Προετοιμασία του worktree αυτού του pull request. Οι αναθεωρητές ξεκινούν μόλις είναι έτοιμο.';

  @override
  String get prReviewFailed => 'Η ανασκόπηση απέτυχε.';

  @override
  String get prReviewRerunning => 'Επανάληψη ανασκόπησης…';

  @override
  String get prReviewNoOpenFindings => 'Δεν υπάρχουν ανοιχτά ευρήματα';

  @override
  String prReviewOpenFindings(int count) {
    return '$count ανοιχτά ευρήματα';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used από $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return 'Δημοσιεύτηκαν $posted σχόλιο(-α) ως bot. $skipped παραλείφθηκαν (χωρίς άγκυρα αρχείου), $failed απέτυχαν.';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count εύρημα(-τα) στοχεύουν κώδικα που αυτό το pull request δεν αλλάζει (⁨$files⁩). Το GitHub δέχεται ενσωματωμένα σχόλια μόνο στο diff.';
  }

  @override
  String get reviewRailReport => 'Αναφορά';

  @override
  String get reviewNoFindingsTitle => 'Δεν υπάρχουν ακόμη ευρήματα ανασκόπησης';

  @override
  String get reviewNoFindingsHint =>
      'Τα ευρήματα εμφανίζονται εδώ καθώς τα δημοσιεύουν οι πράκτορες.';

  @override
  String reviewShowDismissed(int count) {
    return 'Εμφάνιση $count απορριφθέντων';
  }

  @override
  String reviewHideDismissed(int count) {
    return 'Απόκρυψη $count απορριφθέντων';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Εντοπίστηκαν $count διαφωνίες αναθεωρητών',
      one: 'Εντοπίστηκε 1 διαφωνία αναθεωρητών',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'Είδος';

  @override
  String get reviewFilterStatus => 'Κατάσταση';

  @override
  String get reviewKindBug => 'Σφάλμα';

  @override
  String get reviewKindSuggestion => 'Πρόταση';

  @override
  String get reviewKindRecommendation => 'Σύσταση';

  @override
  String get reviewKindQuestion => 'Ερώτηση';

  @override
  String get reviewKindTicket => 'Εισιτήριο';

  @override
  String get archiveSpace => 'Αρχειοθέτηση χώρου';

  @override
  String get archivedSpaces => 'Αρχειοθετημένοι χώροι';

  @override
  String get archivedSpacesEmpty => 'Δεν υπάρχουν αρχειοθετημένοι χώροι';

  @override
  String get restoreSpace => 'Επαναφορά';

  @override
  String archivedWhen(String time) {
    return 'Αρχειοθετήθηκε $time';
  }

  @override
  String get deleteSpacePermanently => 'Οριστική διαγραφή';

  @override
  String get renameSpace => 'Μετονομασία χώρου';

  @override
  String get renameConversation => 'Μετονομασία συνομιλίας';

  @override
  String get spaceActions => 'Ενέργειες χώρου';

  @override
  String get conversationActions => 'Ενέργειες συνομιλίας';

  @override
  String get editSpaceRepos => 'Επεξεργασία αποθετηρίων';

  @override
  String get editSpaceReposTitle => 'Αποθετήρια χώρου';

  @override
  String get editSpaceReposWarning =>
      'Η προσθήκη αποθετηρίου το κάνει checkout σε αυτόν τον χώρο· η αφαίρεση ενός διαγράφει τον φάκελό του.';

  @override
  String get agentSectionIdentity => 'Ταυτότητα';

  @override
  String get agentSectionRuntime => 'Χρόνος εκτέλεσης';

  @override
  String get agentSectionGuardrails => 'Προστατευτικά κιγκλιδώματα';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count υφιστάμενοι',
      one: '1 υφιστάμενος',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'Φιλτράρισμα ομάδων…';

  @override
  String get teamsSummaryWithLeader => 'Με επικεφαλής';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ομάδες',
      one: '1 ομάδα',
      zero: 'Καμία ομάδα',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return 'Η διαγραφή του $name αφαιρεί το προφίλ του, τους συνδέσμους δεξιοτήτων και το ιστορικό εκτελέσεων. Αυτό δεν μπορεί να αναιρεθεί.';
  }

  @override
  String get resetToDefault => 'Επαναφορά στην προεπιλογή';

  @override
  String get newAgent => 'Νέος πράκτορας';

  @override
  String get newSkill => 'Νέα δεξιότητα';

  @override
  String get zoomIn => 'Μεγέθυνση';

  @override
  String get zoomOut => 'Σμίκρυνση';

  @override
  String get resetZoom => 'Επαναφορά μεγέθυνσης';

  @override
  String get imageHostedOnGitHub => 'Εικόνα φιλοξενούμενη στο GitHub';

  @override
  String get imageOpenExternally => 'Εικόνα · άνοιγμα εξωτερικά';

  @override
  String get memoryScopeAll => 'Όλα τα εύρη';

  @override
  String get memoryScopeWorkspace => 'Σε όλο τον χώρο εργασίας';

  @override
  String get memoryScopeFilterLabel => 'Φιλτράρισμα κατά εύρος';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return 'Στο εύρος του αποθετηρίου ⁨$repo⁩';
  }

  @override
  String get toolScreenshot => 'Στιγμιότυπο από τον πράκτορα';

  @override
  String get toolImageUnavailable => 'Η εικόνα δεν είναι διαθέσιμη';

  @override
  String toolImagesUnavailable(int count) {
    return '$count εικόνες μη διαθέσιμες';
  }

  @override
  String get shakeUnavailable =>
      'Το shaking δεν είναι διαθέσιμο σε αυτόν τον διακομιστή';

  @override
  String get shakeNothing =>
      'Τίποτα να αποτιναχθεί — οι πρόσφατες στροφές προστατεύονται';

  @override
  String shakeDone(int tokens) {
    return 'Ελευθερώθηκαν περίπου $tokens token';
  }

  @override
  String get compactionDivider => 'Συμπιέστηκε';

  @override
  String compactionDividerCount(int count) {
    return 'Συμπιέστηκε · $count μηνύματα διπλώθηκαν';
  }

  @override
  String get composerDropToAttach => 'Αφήστε για επισύναψη';

  @override
  String get attachmentUnavailable => 'Το συνημμένο δεν είναι διαθέσιμο';

  @override
  String get attachmentUnavailableDetail =>
      'Αυτό το συνημμένο δεν κρατιέται πλέον στη μνήμη. Επισυνάψτε το ξανά για προεπισκόπηση.';

  @override
  String get attachmentPreviewFailed =>
      'Δεν ήταν δυνατό το άνοιγμα αυτού του αρχείου';

  @override
  String get attachmentPreviewUnsupported =>
      'Δεν υπάρχει προεπισκόπηση για αυτόν τον τύπο αρχείου';

  @override
  String get attachmentTooLargeToPreview => 'Πολύ μεγάλο για προεπισκόπηση';

  @override
  String get attachmentOpenExternally => 'Άνοιγμα στην προεπιλεγμένη εφαρμογή';

  @override
  String get asideUnavailable =>
      'Ορίστε ένα μοντέλο μίας βολής στις ρυθμίσεις χώρου εργασίας για να το χρησιμοποιήσετε';

  @override
  String get asideEmpty => 'Δεν υπάρχει ακόμη τίποτα να εργαστείτε';

  @override
  String get asideFailed => 'Δεν ήταν δυνατή η λήψη απάντησης';

  @override
  String get handoffTitle => 'Παράδοση';

  @override
  String get asideTitle => 'Παράπλευρη ερώτηση';

  @override
  String get attachFilesOrDrop => 'Επισύναψη αρχείων — ή αφήστε τα εδώ';

  @override
  String get guidedGoalTitle => 'Όξυνση του αντικειμενικού σκοπού';

  @override
  String get guidedGoalIntro =>
      'Ένας πράκτορας που εργάζεται χωρίς επίβλεψη πρέπει να ξέρει ακριβώς πότε έχει τελειώσει. Μερικές ερωτήσεις πρώτα.';

  @override
  String get guidedGoalAnswerHint => 'Η απάντησή σας';

  @override
  String get guidedGoalNext => 'Επόμενο';

  @override
  String get guidedGoalStart => 'Έναρξη του στόχου';

  @override
  String get guidedGoalSkip => 'Παράλειψη και εκτέλεση όπως γράφτηκε';

  @override
  String guidedGoalStillMissing(String items) {
    return 'Ακόμη απροσδιόριστα: $items';
  }

  @override
  String get conversationTreeTitle => 'Δέντρο συνομιλίας';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count κλάδοι',
      one: '1 κλάδος',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'Συνέχεια από εδώ';

  @override
  String get conversationTreeFork => 'Διακλάδωση σε νέα συνομιλία';

  @override
  String get conversationTreeCurrent => 'Σε αυτόν τον κλάδο';

  @override
  String get conversationTreeEmpty => 'Δεν υπάρχει τίποτα ακόμη';

  @override
  String get conversationTreeForked => 'Διακλαδώθηκε σε νέα συνομιλία';

  @override
  String get conversationTreeSwitched => 'Συνέχεια πλέον από εκείνο το μήνυμα';

  @override
  String exportSaved(String path) {
    return 'Αποθηκεύτηκε στο ⁨$path⁩';
  }

  @override
  String get exportFailed => 'Δεν ήταν δυνατή η εγγραφή της εξαγωγής';

  @override
  String get contextCommandNoAgent =>
      'Κανένας πράκτορας σε αυτή τη συνομιλία, οπότε δεν υπάρχει παράθυρο συμφραζομένων να ανοίξει';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'Κανένας πράκτορας με όνομα «$name» σε αυτή τη συνομιλία. Δοκιμάστε: $names';
  }

  @override
  String get dumpCopied => 'Η απομαγνητοφώνηση αντιγράφηκε στο πρόχειρο';

  @override
  String get messageQueueHint =>
      'Συνεχίστε να πληκτρολογείτε για ουρά επακόλουθων αλλαγών';

  @override
  String get steerNow => 'Καθοδήγηση';

  @override
  String get steeringQueueLabel => 'Μηνύματα καθοδήγησης σε ουρά';

  @override
  String get steeringDeliverUnavailable =>
      'Κανένας πράκτορας σε εκτέλεση δεν μπορεί να το πάρει αυτή τη στιγμή — μένει στην ουρά.';

  @override
  String get reorderSteeringCard => 'Αναδιάταξη μηνύματος ουράς';

  @override
  String get editSteeringCard => 'Επεξεργασία μηνύματος ουράς';

  @override
  String get deleteSteeringCard => 'Διαγραφή μηνύματος ουράς';

  @override
  String get steeringBadge => 'Καθοδηγήθηκε';

  @override
  String get settingsSandboxLabel => 'Sandbox';

  @override
  String get sandboxExecGrantsTitle => 'Χορηγήσεις εκτελέσιμων';

  @override
  String get sandboxExecGrantsSubtitle =>
      'Προγράμματα που οι πράκτορες μπορούν να τρέξουν από το αντίγραφο εργασίας των αποθετηρίων σας. Κάθε καταχώριση εγκρίθηκε από εσάς όταν ρώτησε το sandbox.';

  @override
  String get sandboxExecGrantsEmpty =>
      'Δεν έχουν καταγραφεί ακόμη αποφάσεις. Θα ρωτηθείτε την πρώτη φορά που ένας πράκτορας χρειάζεται να τρέξει πρόγραμμα από το αντίγραφο εργασίας του.';

  @override
  String get sandboxExecGrantRevoke => 'Ανάκληση';

  @override
  String get sandboxExecGrantAllowed => 'Επιτρέπεται';

  @override
  String get sandboxExecGrantBlocked => 'Αποκλείστηκε';

  @override
  String get sandboxExecGrantRevokeConfirmTitle =>
      'Ανάκληση αυτής της απόφασης;';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'Θα ρωτηθείτε ξανά την επόμενη φορά που ένας πράκτορας χρειάζεται να τρέξει πρόγραμμα από αυτό το αντίγραφο.';

  @override
  String get repoScriptsTest => 'Δοκιμή';

  @override
  String get repoScriptsTestTooltip =>
      'Εκτέλεση αυτού του προχείρου σε προσωρινό κλώνο του αποθετηρίου';

  @override
  String get repoScriptsRunKindTest => 'Δοκιμή';

  @override
  String get demoBadgeLabel => 'Demo';

  @override
  String get demoFilePickerTitle => 'Αρχεία demo';

  @override
  String get demoFilePickerBody =>
      'Το demo προσποιείται τις μεταφορτώσεις: επιλέξτε οποιοδήποτε από αυτά και επισυνάπτεται στο μήνυμά σας χωρίς να αγγίξει δίσκο.';

  @override
  String get demoFilePickerAttach => 'Επισύναψη';

  @override
  String get demoReadOnlySave => 'Μόνο ανάγνωση στο demo';

  @override
  String get demoBadgeTooltip =>
      'Εξερευνάτε ένα demo. Τα δεδομένα είναι πλασματικά και οι πράκτορες είναι σεναριογραφημένοι.';

  @override
  String get demoFirstRunTitle => 'Είστε σε ζωντανό demo';

  @override
  String demoFirstRunBody(int minutes) {
    return 'Αυτή είναι η πραγματική εφαρμογή σε πραγματικό κώδικα — μόνο τα δεδομένα είναι επινοημένα. Οι πράκτορες μεταδίδουν γνήσιες εκτελέσεις από σενάριο, οπότε τίποτα δεν φτάνει σε μοντέλο και τίποτα δεν τρέχει σε μηχάνημα. Ο χώρος εργασίας σας είναι μόνο δικός σας και εξαφανίζεται μετά από $minutes λεπτά.';
  }

  @override
  String get demoFirstRunDismiss => 'Το κατάλαβα';

  @override
  String get demoTourTitle => 'Πού να κοιτάξετε πρώτα';

  @override
  String get demoTourSubtitle =>
      'Τέσσερα μέρη που δείχνουν τι κάνει πραγματικά η εφαρμογή.';

  @override
  String get demoTourSkip => 'Παράλειψη';

  @override
  String get demoTourStarRepo => 'Αστέρι στο GitHub';

  @override
  String get demoTourOpen => 'Άνοιγμα';

  @override
  String get demoTourSpacesTitle => 'Μιλήστε σε έναν πράκτορα';

  @override
  String get demoTourSpacesBody =>
      'Στείλτε μήνυμα σε έναν χώρο και παρακολουθήστε μια εκτέλεση να ρέει — σκέψη, κλήσεις εργαλείων και κόστος, ακριβώς όπως αποδίδεται μια πραγματική εκτέλεση.';

  @override
  String get demoTourReviewTitle => 'Ανασκόπηση ενός pull request';

  @override
  String get demoTourReviewBody =>
      'Ανοίξτε το #412. Αφήστε ενσωματωμένο σχόλιο ή υποβάλετε ανασκόπηση· τα λόγια σας μπαίνουν στο νήμα και μένουν εκεί.';

  @override
  String get demoTourTicketsTitle => 'Ακολουθήστε την εργασία';

  @override
  String get demoTourTicketsBody =>
      'Τα εισιτήρια, οι εκκρεμότητες και τα σχέδια συνδέονται με τις ίδιες συνομιλίες που κάνουν οι πράκτορες.';

  @override
  String get demoTourInboxTitle => 'Δείτε όλη τη λειτουργία';

  @override
  String get demoTourInboxBody =>
      'Κάθε ειδοποίηση από κάθε πυλώνα καταλήγει σε ένα εισερχόμενα — ανασκοπήσεις, εισιτήρια, εκτελέσεις και συσκέψεις.';

  @override
  String get demoUnavailableTitle => 'Δεν είναι διαθέσιμο στο demo';

  @override
  String get demoUnavailableTerminal =>
      'Ένα τερματικό τρέχει πραγματικό κέλυφος στον κεντρικό υπολογιστή του διακομιστή. Το demo δεν έχει καθόλου επιφάνεια εκτέλεσης — αυτό το καθιστά ασφαλές να ανοιχτεί στο κοινό.';

  @override
  String get demoUnavailableRig =>
      'Ένα απομονωμένο περιβάλλον είναι μια αναλώσιμη εικονική μηχανή που οδηγεί ένας πράκτορας. Το demo δεν εκκινεί καμία: ένα δημόσιο endpoint που μπορεί να ξεκινήσει VM δεν είναι demo.';

  @override
  String get demoUnavailableEditor =>
      'Ο επεξεργαστής στο πρόγραμμα περιήγησης τρέχει διεργασία code-server σε πραγματικό checkout. Το demo δεν έχει κανένα από τα δύο.';

  @override
  String get demoUnavailableFeeds =>
      'Το demo διαβάζει πραγματικές ροές, αλλά η λίστα συνδρομών του είναι σταθερή. Η προσθήκη ή αφαίρεση μίας είναι απενεργοποιημένη εδώ.';

  @override
  String get demoUnavailableForge =>
      'Το demo δεν κρατά διαπιστευτήρια και δεν επικοινωνεί ποτέ με GitHub, GitLab ή Linear. Τα pull request του είναι σταθερά δείγματα και τα σχόλιά σας σε αυτά αποθηκεύονται τοπικά.';

  @override
  String get demoUnavailableModels =>
      'Το demo δεν καλεί κανένα μοντέλο. Οι εκτελέσεις πρακτόρων είναι σεναριογραφημένη αναπαραγωγή, γι\' αυτό δεν κοστίζουν τίποτα και δεν φτάνουν σε κανέναν πάροχο.';

  @override
  String get demoUnavailableMcp =>
      'Η επιφάνεια εργαλείων MCP δεν είναι προσαρτημένη στο demo, οπότε κανένας εξωτερικός πελάτης δεν μπορεί να συνδεθεί σε αυτήν.';

  @override
  String get demoUnavailableRepos =>
      'Το demo δεν κάνει checkout κώδικα και δεν τρέχει git. Το αποθετήριο που βλέπετε είναι σταθερό δείγμα πίσω από τα pull request.';

  @override
  String get demoUnavailableSkills =>
      'Η εγκατάσταση μιας δεξιότητας κατεβάζει και σαρώνει κώδικα. Το demo δεν ανακτά τίποτα.';

  @override
  String get demoUnavailableSso =>
      'Η ενιαία σύνδεση είναι ρύθμιση διακομιστή. Το demo σας συνδέει ως προσωρινό επισκέπτη αντ\' αυτού.';

  @override
  String get demoUnavailableAudio =>
      'Η ηχογράφηση και η υπαγόρευση χρειάζονται σύλληψη ήχου και μοντέλο ομιλίας στον κεντρικό υπολογιστή. Το demo δεν στέλνει κανένα από τα δύο, οπότε οι συσκέψεις του είναι απομαγνητοφωνήσεις χωρίς αναπαραγωγή.';

  @override
  String get demoUnavailableServerAdmin =>
      'Αυτή είναι διαχείριση διακομιστή. Το demo δίνει σε κάθε επισκέπτη τον δικό του αναλώσιμο χώρο εργασίας και τίποτα πέρα από αυτόν.';

  @override
  String get demoUnavailablePipelines =>
      'Οι διοχετεύσεις δεν μπορούν να εκτελεστούν εδώ. Ένας επισκέπτης που μπορεί να γράψει ένα βήμα bash και να το ξεκινήσει — χειροκίνητα ή μέσω ενεργοποιητή συμβάντος — εκτελεί κώδικα σε αυτόν τον κεντρικό υπολογιστή.';

  @override
  String get settingsBackupRestore => 'Αντίγραφο ασφαλείας και επαναφορά';

  @override
  String get settingsBackupRestoreDescription =>
      'Στιγμιότυπα κάθε βάσης δεδομένων σε αυτόν τον διακομιστή, συν εξαγωγή, εισαγωγή και διαγραφή για έναν χώρο εργασίας.';

  @override
  String get backupSnapshotsLabel => 'Στιγμιότυπα εγκατάστασης';

  @override
  String get backupSnapshotsExplainer =>
      'Ένα στιγμιότυπο αντιγράφει κάθε βάση δεδομένων σε φάκελο με χρονική σήμανση στον κεντρικό υπολογιστή του διακομιστή. Η επαναφορά ολόκληρης εγκατάστασης σημαίνει αντιγραφή αυτού του φακέλου πίσω με τον διακομιστή σταματημένο· ένας μεμονωμένος χώρος εργασίας μπορεί να επαναφερθεί από εδώ.';

  @override
  String get backupNowAction => 'Αντίγραφο ασφαλείας τώρα';

  @override
  String backupSnapshotWritten(String path) {
    return 'Το στιγμιότυπο γράφτηκε στο ⁨$path⁩';
  }

  @override
  String get backupNoSnapshots =>
      'Δεν υπάρχουν ακόμη στιγμιότυπα. Ένα λαμβάνεται μόνο όταν το ζητήσετε — τίποτα δεν είναι προγραμματισμένο.';

  @override
  String get backupSnapshotComplete => 'Πλήρες';

  @override
  String get backupSnapshotIncomplete => 'Ημιτελές';

  @override
  String get backupSnapshotIncompleteNote =>
      'Το μανιφέστο λείπει ή ονομάζει αρχεία που δεν υπάρχουν, οπότε αυτό το στιγμιότυπο δεν μπορεί να επαναφέρει ολόκληρη την εγκατάσταση. Τα αρχεία χώρου εργασίας που έχει μπορούν ακόμη να υιοθετηθούν ένα προς ένα.';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count χώροι εργασίας',
      one: '1 χώρος εργασίας',
      zero: 'Κανένας χώρος εργασίας',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count χώροι εργασίας δεν καταγράφηκαν',
      one: '1 χώρος εργασίας δεν καταγράφηκε',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'Διαδρομή στον διακομιστή';

  @override
  String get backupRestoreAction => 'Επαναφορά';

  @override
  String get backupRestoreTitle => 'Επαναφορά χώρου εργασίας';

  @override
  String backupRestoreBody(String name) {
    return 'Αυτό αντικαθιστά τα πάντα στο $name με το αντίγραφο που κρατιέται σε αυτό το στιγμιότυπο. Ό,τι έχει κάνει αυτός ο χώρος εργασίας από τότε που λήφθηκε το στιγμιότυπο χάνεται και δεν μπορεί να αναιρεθεί.';
  }

  @override
  String backupRestoreDone(String name) {
    return 'Επαναφέρθηκε το $name από το στιγμιότυπο.';
  }

  @override
  String get backupWorkspaceUnknown =>
      'Δεν είναι πλέον σε αυτόν τον διακομιστή';

  @override
  String get backupWorkspaceDataLabel => 'Δεδομένα χώρου εργασίας';

  @override
  String get backupWorkspaceDataExplainer =>
      'Ένας χώρος εργασίας είναι ένα αρχείο βάσης δεδομένων, οπότε η εξαγωγή του αντιγράφει αυτό το αρχείο αντί να κάνει dump πίνακα προς πίνακα. Η εισαγωγή αντικαθιστά τα πάντα στον χώρο εργασίας προορισμού με το αρχείο που ονομάζετε.';

  @override
  String get backupExportAction => 'Εξαγωγή';

  @override
  String backupExportDone(String path) {
    return 'Εξήχθη στο ⁨$path⁩';
  }

  @override
  String get backupExportedFileLabel => 'Εξαγόμενο αρχείο στον διακομιστή';

  @override
  String get backupImportAction => 'Εισαγωγή';

  @override
  String backupImportTitle(String name) {
    return 'Εισαγωγή στο $name';
  }

  @override
  String backupImportBody(String name) {
    return 'Αυτό αντικαθιστά τα πάντα στο $name με τα περιεχόμενα του αρχείου. Ό,τι κρατά τώρα αυτός ο χώρος εργασίας χάνεται και δεν μπορεί να αναιρεθεί.';
  }

  @override
  String get backupImportSourceLabel => 'Αρχείο βάσης δεδομένων χώρου εργασίας';

  @override
  String get backupImportSourceDescription =>
      'Ένα αρχείο .db που μπορεί να διαβάσει ο διακομιστής. Οι διαδρομές επιλύονται στον κεντρικό υπολογιστή του διακομιστή, όχι σε αυτή τη συσκευή.';

  @override
  String backupImportDone(String name) {
    return 'Εισήχθη στο $name.';
  }

  @override
  String backupDeleteBody(String name) {
    return 'Το $name εξαφανίζεται από κάθε λίστα και αναζήτηση. Το αρχείο βάσης δεδομένων του μένει στον δίσκο, τα αντίγραφα ασφαλείας το περιλαμβάνουν ακόμη και τίποτα δεν ανακτά τον χώρο αυτόματα.';
  }

  @override
  String get backupExportDescription =>
      'Γράψτε ένα αντίγραφο στον διακομιστή ή κατεβάστε ένα σε αυτή τη συσκευή.';

  @override
  String get backupExportOnServerAction => 'Αποθήκευση στον διακομιστή';

  @override
  String get backupDownloadAction => 'Λήψη';

  @override
  String backupDownloadSaved(String path) {
    return 'Αποθηκεύτηκε στο ⁨$path⁩';
  }

  @override
  String get backupDownloadInBrowser =>
      'Το πρόγραμμα περιήγησής σας το κατεβάζει.';

  @override
  String get backupRestoreFromDeviceLabel => 'Επαναφορά από αυτή τη συσκευή';

  @override
  String get backupRestoreFromDeviceDescription =>
      'Επιλέξτε ένα αρχείο βάσης δεδομένων χώρου εργασίας εδώ και το Control Center το μεταφορτώνει στον διακομιστή. Αυτό είναι εκείνο που λειτουργεί όταν ο διακομιστής δεν είναι αυτό το μηχάνημα.';

  @override
  String get backupUploadAction => 'Επιλογή αρχείου και μεταφόρτωση';

  @override
  String get backupTransferUnavailable =>
      'Αυτή η σύνδεση φτάνει στον διακομιστή μέσω αναμετάδοσης, που δεν μεταφέρει αρχεία. Συνδεθείτε απευθείας στον διακομιστή για λήψη ή μεταφόρτωση αντιγράφου ασφαλείας.';

  @override
  String get backupTransferForbidden =>
      'Ο διακομιστής αρνήθηκε. Η λήψη χώρου εργασίας χρειάζεται ρόλο διαχειριστή, η επαναφορά χρειάζεται ιδιοκτήτη και ένα ολόκληρο στιγμιότυπο χρειάζεται τον χειριστή της εγκατάστασης.';

  @override
  String get backupTransferUnsupported =>
      'Αυτός ο διακομιστής δεν έχει επιφάνεια αντιγράφων ασφαλείας.';

  @override
  String get backupTransferTooLarge =>
      'Το αρχείο είναι μεγαλύτερο από ό,τι δέχεται ο διακομιστής.';

  @override
  String get credentialGateWaitingTitle => 'Αναμονή διαπιστευτηρίων';

  @override
  String credentialGateHarnessTitle(String provider) {
    return 'Το $provider δεν έχει διαπιστευτήρια';
  }

  @override
  String get credentialGateSignedOutTitle =>
      'Το Claude Code είναι αποσυνδεδεμένο';

  @override
  String get credentialGateExpiredTitle =>
      'Η σύνδεσή σας Claude Code έχει λήξει';

  @override
  String get credentialGatePlanSpentTitle =>
      'Το όριο πλάνου Claude Code εξαντλήθηκε';

  @override
  String credentialGateWaitingAgent(String agent) {
    return 'Ο $agent περιμένει να συνεχίσει.';
  }

  @override
  String get credentialGateWaitingRun => 'Μια εκτέλεση περιμένει να συνεχίσει.';

  @override
  String get credentialGateWatching =>
      'Παρακολούθηση για τη διόρθωση — η εκτέλεση συνεχίζεται μόνη της.';

  @override
  String credentialGateFreesUpAt(String time) {
    return 'Ελευθερώνεται στις $time';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'Η εκτέλεση εγκαταλείπει στις $time';
  }

  @override
  String get credentialGateCheckAgain => 'Έλεγχος ξανά';

  @override
  String get credentialGateCancelRun => 'Ακύρωση εκτέλεσης';

  @override
  String get credentialGateAccountsTried => 'Λογαριασμοί που δοκιμάστηκαν';

  @override
  String get credentialGateClaudeSignInHint =>
      'Συνδεθείτε από Ρυθμίσεις → Προσαρμογείς → Claude Code, ή τρέξτε την εντολή σύνδεσης σε τερματικό. Η εκτέλεση το πιάνει μόνη της.';

  @override
  String get credentialGateOpenSettings => 'Άνοιγμα ρυθμίσεων';

  @override
  String get selectModel => 'Επιλογή μοντέλου';

  @override
  String get allModels => 'Όλα τα μοντέλα';

  @override
  String get noModelsMatchSearch =>
      'Κανένα μοντέλο δεν ταιριάζει με την αναζήτησή σας';

  @override
  String useCustomModelId(String id) {
    return 'Χρήση του “$id”';
  }

  @override
  String get modelFree => 'Δωρεάν';

  @override
  String modelOutputTokens(String tokens) {
    return '$tokens έξοδος';
  }

  @override
  String modelPricePerMTokens(String input, String output) {
    return '$input είσοδος / $output έξοδος ανά 1M tokens';
  }

  @override
  String modelEffortLevels(String levels) {
    return 'Προσπάθεια συλλογισμού: $levels';
  }

  @override
  String get modelSupportsReasoning => 'Υποστηρίζει προσπάθεια συλλογισμού';

  @override
  String get profileDeliveryMetrics => 'Μετρικές παράδοσης';

  @override
  String profileMetricsSample(int count) {
    return 'PR που αναλύθηκαν: $count';
  }

  @override
  String get profileMergeRate => 'Ποσοστό συγχώνευσης';

  @override
  String get profileReviewCoverage => 'Κάλυψη ανασκόπησης';

  @override
  String get profilePrSize => 'Μέγεθος PR';

  @override
  String get profileTimeToMerge => 'Χρόνος έως τη συγχώνευση';

  @override
  String get profileMergeTimeTrend => 'Τάση χρόνου συγχώνευσης';

  @override
  String get profileWeeklyMedian => 'Εβδομαδιαία διάμεσος, λογαριθμική κλίμακα';

  @override
  String get profilePrOpeningPattern => 'Ημέρα εβδομάδας × ώρα, τοπική ώρα';

  @override
  String get profileFirstReview => 'Χρόνος έως την πρώτη ανασκόπηση';

  @override
  String get profileMetricsTruncated =>
      'Τα εκατοστημόρια χρησιμοποιούν ένα περιορισμένο δείγμα από τα διαθέσιμα αιτήματα ενσωμάτωσης.';

  @override
  String profileLinesChanged(String count) {
    return '$count γραμμές';
  }

  @override
  String profileDurationMinutes(int count) {
    return '$count λεπ';
  }

  @override
  String profileDurationHours(int count) {
    return '$count ώρ';
  }

  @override
  String profileDurationDaysHours(int days, int hours) {
    return '$daysη $hoursώρ';
  }

  @override
  String profilePercentiles(String median, String p90) {
    return 'p50 $median · p90 $p90';
  }

  @override
  String profileTeamMembers(int count) {
    return 'Μέλη: $count';
  }

  @override
  String noPrsByTeamInWorkspace(String team) {
    return 'Δεν υπάρχουν pull request από την ομάδα $team σε αυτόν τον χώρο εργασίας';
  }

  @override
  String get profilePrStateFilterLabel =>
      'Φιλτράρισμα pull request κατά κατάσταση';

  @override
  String get noProfilePrsMatchSearchHint =>
      'Δοκιμάστε άλλον τίτλο ή αριθμό pull request';

  @override
  String get rigNetworkUnrestricted => 'Δίκτυο χωρίς περιορισμούς';

  @override
  String get rigNetworkAllowAllHosts =>
      'Να επιτρέπονται όλοι οι κεντρικοί υπολογιστές';

  @override
  String get rigBrowserPermissionsTitle => 'Άδειες ιστότοπου';

  @override
  String get rigBrowserPermissionsTooltip => 'Άδειες ιστότοπου και δίκτυο';

  @override
  String get rigBrowserPermissionEmpty =>
      'Κανένας ιστότοπος δεν έχει ζητήσει άδεια ακόμα';

  @override
  String rigBrowserPermissionPrompt(String origin, String permission) {
    return 'Ο $origin θέλει να χρησιμοποιήσει $permission';
  }

  @override
  String get rigBrowserPermissionBlock => 'Αποκλεισμός';

  @override
  String get rigBrowserPermissionCamera => 'Κάμερα';

  @override
  String get rigBrowserPermissionMicrophone => 'Μικρόφωνο';

  @override
  String get rigBrowserPermissionNotifications => 'Ειδοποιήσεις';

  @override
  String get rigBrowserPermissionGeolocation => 'Τοποθεσία';

  @override
  String get rigBrowserPermissionPersistentStorage => 'Μόνιμη αποθήκευση';

  @override
  String get rigBrowserPermissionClipboard => 'Πρόχειρο';

  @override
  String get rigBrowserPermissionDisplayCapture => 'Καταγραφή οθόνης';

  @override
  String get rigBrowserPermissionMidi => 'MIDI';

  @override
  String get rigNetworkBypassTitle =>
      'Να επιτραπεί κάθε κεντρικός υπολογιστής δικτύου;';

  @override
  String get rigNetworkBypassBody =>
      'Αυτό επανεκκινεί το απομονωμένο περιβάλλον και απορρίπτει τις μη καταχωρισμένες αλλαγές μέσα σε αυτό. Στη συνέχεια, το φιλοξενούμενο σύστημα θα μπορεί να συνδέεται σε κάθε κεντρικό υπολογιστή δικτύου μέχρι να κλείσει.';

  @override
  String get rigNetworkRestartUnrestricted => 'Επανεκκίνηση χωρίς περιορισμούς';

  @override
  String get rigNetworkUnrestrictedBody =>
      'Αυτό το απομονωμένο περιβάλλον μπορεί να συνδέεται σε κάθε κεντρικό υπολογιστή δικτύου. Κλείστε το και ανοίξτε ένα νέο για να επαναφέρετε τους προεπιλεγμένους περιορισμούς.';

  @override
  String get rigNetworkAlreadyUnrestrictedBody =>
      'Αυτός ο εξομοιωτής Android διαχειρίζεται ήδη το δικό του δίκτυο, επομένως το Control Center δεν μπορεί να επιβάλει λίστα επιτρεπόμενων κεντρικών υπολογιστών. Δεν απαιτείται επανεκκίνηση.';

  @override
  String get rigClipboardPermissionHostToRigTitle =>
      'Επικόλληση προχείρου σε αυτό το περιβάλλον;';

  @override
  String get rigClipboardPermissionHostToRigBody =>
      'Το Control Center θα διαβάσει το πρόχειρο της συσκευής σας και θα στείλει το περιεχόμενό του στο περιβάλλον. Το περιεχόμενο του προχείρου μπορεί να περιέχει κωδικούς πρόσβασης ή άλλα μυστικά.';

  @override
  String get rigClipboardPermissionRigToHostTitle =>
      'Αντιγραφή προχείρου από αυτό το περιβάλλον;';

  @override
  String get rigClipboardPermissionRigToHostBody =>
      'Το Control Center θα διαβάσει το πρόχειρο του περιβάλλοντος και θα αντικαταστήσει το πρόχειρο της συσκευής σας με το περιεχόμενό του. Αντιμετωπίστε το περιεχόμενο από το περιβάλλον ως μη αξιόπιστο.';

  @override
  String get rigClipboardAllowTenMinutes => 'Να επιτρέπεται για 10 λεπτά';

  @override
  String get rigClipboardAlwaysAllow => 'Να επιτρέπεται πάντα';

  @override
  String get rigClipboardSettingsTitle => 'Πρόσβαση στο πρόχειρο';

  @override
  String get rigClipboardSettingsHint =>
      'Επιλέξτε ποιες μεταφορές προχείρου μπορούν να εκτελούνται χωρίς ερώτηση. Οι προσωρινές άδειες λήγουν μετά από 10 λεπτά.';

  @override
  String get rigClipboardAlwaysPasteTitle =>
      'Να επιτρέπεται πάντα η επικόλληση σε περιβάλλοντα';

  @override
  String get rigClipboardAlwaysPasteDescription =>
      'Αποστολή του προχείρου αυτής της συσκευής σε οποιοδήποτε περιβάλλον χωρίς ερώτηση.';

  @override
  String get rigClipboardAlwaysCopyTitle =>
      'Να επιτρέπεται πάντα η αντιγραφή από περιβάλλοντα';

  @override
  String get rigClipboardAlwaysCopyDescription =>
      'Τοποθέτηση περιεχομένου προχείρου από οποιοδήποτε περιβάλλον σε αυτήν τη συσκευή χωρίς ερώτηση.';

  @override
  String get workspaceGitHubIdentity => 'Ταυτότητα GitHub';

  @override
  String get workspaceGitHubIdentityDescription =>
      'Πώς πιστοποιείται η εργασία GitHub στο παρασκήνιο σε αυτόν τον χώρο εργασίας. Κληρονομιά του App της εγκατάστασης, άλλο App ή μόνο προσωπικό διακριτικό πρόσβασης.';

  @override
  String get workspaceGitHubModeInherit =>
      'Χρήση του GitHub App αυτής της εγκατάστασης';

  @override
  String get workspaceGitHubModeApp => 'Χρήση διαφορετικού GitHub App';

  @override
  String get workspaceGitHubModePat => 'Μόνο προσωπικό διακριτικό πρόσβασης';

  @override
  String get workspaceGitHubInheritHint =>
      'Χρησιμοποιεί το GitHub App στο Διακομιστής → Εφαρμογές παρόχων.';

  @override
  String get workspaceGitHubAppHint =>
      'Ταυτότητα bot και polling αυτού του χώρου. Τα μέλη συνδέονται στο Εσείς μέσω αυτού του App.';

  @override
  String get workspaceGitHubPatLabel => 'Διακριτικό παρασκηνίου';

  @override
  String get workspaceGitHubPatDescription =>
      'Για polling και πράκτορες σε αυτόν τον χώρο. Όχι το διακριτικό προφίλ ενός μέλους.';

  @override
  String get workspaceGitHubHasPat =>
      'Υπάρχει αποθηκευμένο διακριτικό παρασκηνίου.';

  @override
  String get workspaceGitHubNoPat => 'Δεν υπάρχει διακριτικό παρασκηνίου.';

  @override
  String get profileOverlayHint =>
      'Αυτά τα πεδία είστε εσείς σε αυτόν τον χώρο. Τα κενά κληρονομούν όνομα και email του λογαριασμού. Η αλλαγή χώρου αλλάζει αυτή την επικάλυψη.';

  @override
  String get forgeConnectionsThisWorkspace =>
      'Συνδεθείτε ή επικολλήστε διακριτικό για αυτόν τον χώρο εργασίας.';

  @override
  String get stackStartNextPart => 'Έναρξη επόμενου μέρους';

  @override
  String get stackPartNameTitle => 'Όνομα μέρους';

  @override
  String get stackPartNameHint => 'π.χ. migration';

  @override
  String get stackPublish => 'Δημοσίευση στοίβας';

  @override
  String get stackCurrentPart => 'Τρέχον';

  @override
  String get stackSwitchDirty =>
      'Κάντε commit ή απορρίψτε τις αλλαγές πριν αλλάξετε μέρη';

  @override
  String get stackCutFailed => 'Δεν ήταν δυνατή η έναρξη του επόμενου μέρους';

  @override
  String get stackPublishFailed => 'Δεν ήταν δυνατή η δημοσίευση της στοίβας';

  @override
  String get stackPublished => 'Η στοίβα δημοσιεύτηκε ως πρόχειρα';

  @override
  String get stackOpenPullRequest => 'Άνοιγμα pull request';

  @override
  String get stackSection => 'Στοίβα';

  @override
  String get mergeConflictsButton => 'Συγκρούσεις';

  @override
  String mergeConflictsFileCount(int count, String base) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count αρχεία συγκρούονται με το $base',
      one: '1 αρχείο συγκρούεται με το $base',
    );
    return '$_temp0';
  }

  @override
  String get mergeConflictsLoading => 'Αναζήτηση αρχείων σε σύγκρουση…';

  @override
  String get mergeConflictsLoadFailed =>
      'Δεν ήταν δυνατή η εμφάνιση των αρχείων σε σύγκρουση';

  @override
  String get mergeConflictsNoneFound =>
      'Δεν βρέθηκαν αρχεία σε σύγκρουση. Το GitHub ίσως ενημερώνει ακόμη αυτό το pull request.';

  @override
  String get askAiToFixConflicts =>
      'Ζητήστε από την AI να επιλύσει τις συγκρούσεις';

  @override
  String get fixConflictsStarted =>
      'Ένας πράκτορας επιλύει τις συγκρούσεις στη συνομιλία αυτού του pull request';

  @override
  String failedToStartConflictFix(String error) {
    return 'Δεν ήταν δυνατή η έναρξη επίλυσης: $error';
  }
}
