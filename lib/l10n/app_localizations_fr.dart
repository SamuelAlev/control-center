// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get succeeded => 'Réussi';

  @override
  String agentRunRetryLabel(int number, String time) {
    return 'Nouvelle tentative n° $number · $time';
  }

  @override
  String agentRunStarting(String time) {
    return 'Démarrage · $time';
  }

  @override
  String get agentActivityFollowingLive => 'Suivi de l\'activité en direct';

  @override
  String get agentActivityJumpToLatest => 'Aller au plus récent';

  @override
  String get agentActivityLoadFailed =>
      'Impossible de charger l\'activité de cette exécution';

  @override
  String get agentActivityNotRecorded =>
      'Aucune activité n\'a été enregistrée pour cette exécution';

  @override
  String get agentActivityNotRecordedHint =>
      'Les exécutions terminées avant l\'activation de la capture d\'activité n\'ont pas de chronologie.';

  @override
  String get agentActivityRunUnavailable =>
      'Cette exécution n\'est plus disponible';

  @override
  String agentActivitySubagentOf(String agent) {
    return 'Sous-agent de $agent';
  }

  @override
  String get agentActivityUnsupported =>
      'La capture d\'activité est indisponible sur le serveur connecté';

  @override
  String get agentActivityUnsupportedHint =>
      'Redémarrez l\'application pour qu\'elle utilise la dernière version du serveur.';

  @override
  String get agentActivityWaiting => 'En attente d\'activité…';

  @override
  String get created => 'Créé';

  @override
  String get dictationStart => 'Démarrer la dictée';

  @override
  String get dictationListening => 'Écoute…';

  @override
  String get dictationUnavailable =>
      'La dictée nécessite un modèle vocal sur le serveur hôte. Configurez-en un dans les paramètres vocaux.';

  @override
  String get dictationFailedToStart => 'Impossible de démarrer la dictée';

  @override
  String get dictationHoldToTalkTitle => 'Maintenir pour parler';

  @override
  String get dictationHoldToTalkDescription =>
      'Maintenez le bouton du micro ou le raccourci pour dicter, puis relâchez pour arrêter. Sinon, appuyez une fois pour démarrer et de nouveau pour arrêter.';

  @override
  String get focusConversation => 'Afficher la conversation';

  @override
  String get ideAgentActivity => 'Activité de l\'agent';

  @override
  String get keybindingPushToTalk => 'Appuyer pour parler';

  @override
  String get keybindingPushToTalkDescription =>
      'Maintenir ou basculer la dictée vocale dans le compositeur de messages';

  @override
  String get agentPermissions => 'Autorisations des agents';

  @override
  String get agentPermissionsSettingsDescription =>
      'Décidez ce que les agents peuvent faire seuls, doivent d’abord demander ou ne peuvent jamais faire — par espace de travail, agent ou espace.';

  @override
  String get agentPermissionsMatrixDescription =>
      'Définissez une décision pour chaque type d\'effet. Les règles se cascadent : le espace prime sur l\'agent, qui prime sur l\'espace de travail.';

  @override
  String get guardrailLoading => 'Chargement des règles…';

  @override
  String get guardrailRulesLoadFailed =>
      'Impossible de charger les règles d\'autorisation.';

  @override
  String get guardrailScopeWorkspace => 'Espace de travail';

  @override
  String get guardrailScopeAgent => 'Agent';

  @override
  String get guardrailScopeSpace => 'Espace';

  @override
  String get guardrailSelectAgent => 'Sélectionner un agent';

  @override
  String get guardrailSelectSpace => 'Sélectionner un espace';

  @override
  String get guardrailNoAgents =>
      'Aucun agent dans cet espace de travail pour l\'instant.';

  @override
  String get guardrailNoSpaces =>
      'Aucun espace dans cet espace de travail pour l\'instant.';

  @override
  String get guardrailClassFileDelete => 'Supprimer un fichier';

  @override
  String get guardrailClassFileWriteOutsideWorktree =>
      'Écrire hors de l\'arbre de travail';

  @override
  String get guardrailClassGitCommit => 'Créer un commit';

  @override
  String get guardrailClassGitPush => 'Pousser vers un dépôt distant';

  @override
  String get guardrailClassPrCreate => 'Ouvrir une pull request';

  @override
  String get guardrailClassPrPublish => 'Publier une revue ou fusionner';

  @override
  String get guardrailClassVendorSyncWrite =>
      'Écrire dans un outil de suivi externe';

  @override
  String get guardrailClassNetworkEgress => 'Accéder au réseau';

  @override
  String get guardrailClassSecretAccess => 'Lire un secret';

  @override
  String get guardrailClassPackageInstall => 'Installer un paquet';

  @override
  String get guardrailClassProcessSpawn => 'Exécuter un processus';

  @override
  String get guardrailClassWorkspaceMutation =>
      'Modifier la structure de l\'espace de travail';

  @override
  String get guardrailClassEnclosureControl => 'Piloter une enceinte (rig)';

  @override
  String get navRigs => 'Rigs';

  @override
  String get rigsUnsupportedServer =>
      'Ce serveur ne peut pas héberger de VM cloisonnées. Les rigs nécessitent un hyperviseur sur la machine qui exécute cc_server.';

  @override
  String get rigSurfaceComputer => 'Ordinateur';

  @override
  String get rigSurfaceBrowser => 'Navigateur';

  @override
  String get rigSurfaceMobile => 'Mobile';

  @override
  String rigSurfaceBrowserEngine(String engine) {
    return '$engine';
  }

  @override
  String rigBrowserEngineHint(String engine) {
    return 'Un $engine jetable, isolé de votre machine. Ouvrez un autre moteur pour comparer la même page côte à côte.';
  }

  @override
  String get rigPhaseReady => 'Prêt';

  @override
  String get rigPhaseStarting => 'Démarrage';

  @override
  String get rigPhaseParked => 'En veille';

  @override
  String get rigPhaseClosing => 'Fermeture';

  @override
  String get rigPhaseClosed => 'Fermé';

  @override
  String get rigPhaseFailed => 'Échec';

  @override
  String get rigPhaseUnknown => 'Inconnu';

  @override
  String get rigNotAccelerated => 'Émulé';

  @override
  String get rigAudioListen => 'Écouter la machine';

  @override
  String get rigAudioMute => 'Couper le son de la machine';

  @override
  String get rigYouHaveControl => 'Vous avez le contrôle';

  @override
  String get rigBackendAvailable => 'Disponible';

  @override
  String get rigBackendUnavailable => 'Indisponible';

  @override
  String get rigEgressNotEnforced =>
      'Le réseau n\'est pas cloisonné sur ce backend — il gère sa propre connectivité.';

  @override
  String get rigStartMachine => 'Démarrer la machine';

  @override
  String get rigStartHint =>
      'Démarre une VM jetable partagée avec vos agents pour cette conversation. Elle est détruite à sa fermeture et rien de ce qui s\'y passe ne touche votre ordinateur.';

  @override
  String get rigStopMachine => 'Arrêter la machine';

  @override
  String get rigSurfaceUnavailable =>
      'Ce serveur ne peut pas héberger ce type de machine.';

  @override
  String get rigTabNeedsConversation =>
      'Ouvrez d\'abord une conversation — une machine appartient à l\'une d\'elles, pour que vos agents et vous regardiez le même écran.';

  @override
  String get ideMenuSectionTools => 'Outils';

  @override
  String get ideMenuSectionVirtualMachine => 'Machine virtuelle';

  @override
  String get ideMenuSectionReopen => 'Rouvrir';

  @override
  String get ideMenuSearchHint => 'Rechercher';

  @override
  String get ideMenuNoMatches => 'Aucun résultat';

  @override
  String get rigMenuComputer => 'Ordinateur';

  @override
  String get rigMenuBrowser => 'Navigateur';

  @override
  String get rigMenuMobile => 'Téléphone';

  @override
  String rigLabelNumbered(String label, String suffix) {
    return '$label $suffix';
  }

  @override
  String ideCloseKeepTitle(String name) {
    return 'Fermer $name ?';
  }

  @override
  String get ideCloseKeepBodyMachine =>
      'La machine continue de tourner en arrière-plan : rouvrez-la quand vous voulez depuis la barre latérale. Éteignez-la pour libérer sa mémoire tout de suite.';

  @override
  String get ideCloseKeepBodyShell =>
      'La commande continue en arrière-plan : rouvrez le shell quand vous voulez depuis la barre latérale. Terminez-le pour arrêter ce qu\'il fait.';

  @override
  String get ideCloseKeepBodyAgent =>
      'L\'agent continue de travailler en arrière-plan : rouvrez la conversation quand vous voulez depuis la barre latérale. Arrêtez-le pour terminer l\'exécution.';

  @override
  String get ideCloseKeepRunning => 'Laisser tourner';

  @override
  String get ideCloseShutDownMachine => 'Éteindre';

  @override
  String get ideCloseEndShell => 'Terminer le shell';

  @override
  String get ideCloseStopAgent => 'Arrêter l\'agent';

  @override
  String get rigsSettingsSubtitle =>
      'Ce que ce serveur peut démarrer, les images de base nécessaires et les machines en cours';

  @override
  String get rigsCapabilitiesTitle => 'Ce serveur';

  @override
  String get rigsImagesTitle => 'Images de base';

  @override
  String get rigsImagesHint =>
      'Chaque rig démarre depuis l\'une de ces images en lecture seule. Chaque session écrit dans une surcouche jetable, donc un rig ne peut jamais modifier ce dont part le suivant.';

  @override
  String get rigsRunningTitle => 'En cours';

  @override
  String get rigsNoneRunning => 'Aucune machine en cours.';

  @override
  String get rigsCustomImagesTitle =>
      'Images personnalisées (cet espace de travail)';

  @override
  String get rigsCustomImagesHint =>
      'Pointez le Terminal (VM) ou le Navigateur (VM) vers votre propre image — étendez celles par défaut avec les outils de votre projet, ou utilisez-en une compatible depuis un registre. Les nouvelles machines l\'utilisent ; celles en cours gardent la leur. Voir le guide des rigs pour ce qu\'une image doit fournir.';

  @override
  String get rigsCustomTerminalImageLabel => 'Image du Terminal (VM)';

  @override
  String get rigsCustomBrowserImageLabel => 'Image du Navigateur (VM)';

  @override
  String get rigsCustomImagePlaceholder =>
      'par ex. ghcr.io/acme/dev-shell:1.2 — vide pour la valeur par défaut';

  @override
  String get rigsCustomImageInvalid =>
      'Saisissez une référence de registre comme repo/nom:tag. Les chemins locaux et archives ne sont pas autorisés.';

  @override
  String get rigsCustomImageSaved =>
      'Enregistré. Les nouvelles machines démarrent cette image ; celles en cours gardent la leur.';

  @override
  String get rigsEgressTitle =>
      'Sortie réseau du navigateur (cet espace de travail)';

  @override
  String get rigsEgressHint =>
      'Hôtes supplémentaires accessibles au navigateur enfermé — un par ligne : un hôte exact (api.example.com) ou un joker pour ses sous-domaines (*.example.com). Le site du produit reste autorisé dans tous les cas. Les nouvelles machines utilisent la liste ; celles en cours gardent celle de leur démarrage.';

  @override
  String rigsEgressInvalid(String host) {
    return '« $host » n\'est pas un hôte valide.';
  }

  @override
  String get rigsEgressSaved =>
      'Enregistré. Les nouvelles machines navigateur autorisent ces hôtes ; celles en cours gardent les leurs.';

  @override
  String get rigImageInstalled => 'Installée';

  @override
  String get rigImageNotDownloaded => 'Non téléchargée';

  @override
  String get rigImageNotPublished => 'Non publiée';

  @override
  String get rigImageNotPublishedHint =>
      'Aucune image n\'a encore été publiée pour ceci, il n\'y a donc rien à télécharger. Importez une image disque compatible pour l\'activer.';

  @override
  String get rigImageDownload => 'Télécharger';

  @override
  String get rigImageDownloading => 'Téléchargement…';

  @override
  String get rigImageImport => 'Importer';

  @override
  String get rigImageImportMessage =>
      'Chemin vers une image disque qcow2 sur le système de fichiers du serveur. Elle est copiée dans le magasin d\'images, le fichier peut donc être déplacé ensuite.';

  @override
  String get rigConnectingStream => 'Connexion au rig';

  @override
  String get rigStreamNotAllowed => 'Vous n\'avez pas accès à ce rig.';

  @override
  String get rigStreamNotRunning => 'Ce rig n\'est plus en cours d\'exécution.';

  @override
  String get rigStreamNeedsFfmpeg =>
      'La vue en direct nécessite ffmpeg sur cet hôte. Installez ffmpeg puis rouvrez l\'onglet.';

  @override
  String get rigStreamEnded => 'La vue en direct s\'est terminée.';

  @override
  String get rigStreamFailed => 'Impossible d\'ouvrir la vue en direct.';

  @override
  String get rigStreamDisconnected => 'Non connecté à un serveur.';

  @override
  String rigDropSendingOne(String name) {
    return 'Copie de « $name » dans la machine…';
  }

  @override
  String rigDropSendingMany(int count) {
    return 'Copie de $count fichiers dans la machine…';
  }

  @override
  String get rigTerminalDropSending => 'Copie dans la machine…';

  @override
  String get rigTerminalPasteImage =>
      'Image collée enregistrée dans la machine';

  @override
  String get rigPortsTitle => 'Ports transférés';

  @override
  String get rigPortsTooltip => 'Ports ouverts dans cette machine';

  @override
  String get rigPortsEmpty =>
      'Rien n\'écoute encore. Démarrez un serveur dans le terminal — un serveur de dev sur le port 3000 apparaît ici.';

  @override
  String get rigPortsAdd => 'Ajouter un port';

  @override
  String get rigPortsAddHint => 'Port invité à transférer (par ex. 3000)';

  @override
  String get rigPortsAutoForward => 'Transfert automatique des ports';

  @override
  String get rigPortsCopyUrl => 'Copier l\'URL locale';

  @override
  String rigPortsCopiedUrl(String url) {
    return '$url copié';
  }

  @override
  String get rigPortsStopForward => 'Arrêter le transfert';

  @override
  String get rigPortsExposeLan => 'Partager sur le réseau local';

  @override
  String get rigPortsLanPrivate => 'Local uniquement';

  @override
  String get rigPortsLanShared => 'Sur le réseau';

  @override
  String get rigPortsSetDomain => 'Définir un domaine navigateur (.test)';

  @override
  String get rigPortsDomainHint =>
      'Domaine pour le Navigateur (VM), par ex. myapp.test — accessible là, pas sur l\'hôte';

  @override
  String get rigPortsProcessUnknown => 'processus inconnu';

  @override
  String get rigPortsInactive => 'n\'écoute pas';

  @override
  String rigImagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images de base à télécharger',
      one: '1 image de base à télécharger',
    );
    return '$_temp0';
  }

  @override
  String get guardrailDecisionAllow => 'Autoriser';

  @override
  String get guardrailDecisionPrompt => 'Demander d\'abord';

  @override
  String get guardrailDecisionDeny => 'Refuser';

  @override
  String get guardrailSourceThisScope => 'Cette portée';

  @override
  String get guardrailSourceDefault => 'Valeur par défaut';

  @override
  String get guardrailSourcePreset => 'Préréglage du mode';

  @override
  String get guardrailSourceInherited => 'Hérité';

  @override
  String get guardrailClearToInherited => 'Revenir à la valeur héritée';

  @override
  String get guardrailWhatIf => 'Et si ?';

  @override
  String get guardrailWhatIfDescription =>
      'Voyez comment les règles actuelles trancheraient une action, avec la même logique que celle appliquée aux agents.';

  @override
  String get guardrailProbeActionLabel => 'Action';

  @override
  String get guardrailProbeCommandLabel => 'Commande (facultatif)';

  @override
  String get guardrailProbeCommandHint => 'ex. git push origin main';

  @override
  String get guardrailProbeAgentLabel => 'Agent (facultatif)';

  @override
  String get guardrailProbeSpaceLabel => 'Espace (facultatif)';

  @override
  String get guardrailProbeNone => 'Aucun';

  @override
  String get guardrailProbeModeLabel => 'Mode';

  @override
  String get guardrailProbeResult => 'Résultat';

  @override
  String get guardrailProbeSource => 'Source :';

  @override
  String get guardrailAdapterMatrix => 'Où les règles sont appliquées';

  @override
  String get guardrailAdapterMatrixDescription =>
      'Référence honnête : où chaque effet est réellement intercepté, selon l\'exécuteur d\'agent. Ceci décrit la réalité, pas une garantie — les effets qu\'un exécuteur produit hors circuit ne peuvent pas être interceptés.';

  @override
  String get guardrailEffectColumn => 'Effet';

  @override
  String get guardrailAdapterHarness => 'Harnais intégré';

  @override
  String get guardrailAdapterClaudeCli => 'Claude CLI';

  @override
  String get guardrailAdapterMcpHttp => 'MCP (HTTP)';

  @override
  String get guardrailAdapterSandbox => 'Socle du bac à sable';

  @override
  String get guardrailEnforcementPolicyGate => 'Contrôle par règle';

  @override
  String get guardrailEnforcementSandbox => 'Bac à sable uniquement';

  @override
  String get guardrailEnforcementNone => 'Non applicable';

  @override
  String get guardrailEnforcementPolicyGateHelp =>
      'La décision d\'autorisation est vérifiée avant l\'exécution de l\'effet et peut le bloquer.';

  @override
  String get guardrailEnforcementSandboxHelp =>
      'Seul le bac à sable le limite ; la règle d\'autorisation n\'est pas consultée.';

  @override
  String get guardrailEnforcementNoneHelp =>
      'La décision est purement indicative — elle ne peut pas être interceptée ici.';

  @override
  String get obsStatCost => 'coût';

  @override
  String obsStatDelegatedCost(String amount) {
    return '+$amount délégué';
  }

  @override
  String get obsStatDuration => 'durée';

  @override
  String get obsStatTokens => 'jetons';

  @override
  String get obsStatTools => 'outils';

  @override
  String get openAgentActivity => 'Ouvrir l\'activité';

  @override
  String get orgChart => 'Organigramme';

  @override
  String get orgChartEmpty => 'Aucun agent pour le moment';

  @override
  String get navCalendar => 'Calendrier';

  @override
  String get serverConnection => 'Connexion au serveur';

  @override
  String get serverModeLocal => 'Exécuter dans cette application';

  @override
  String get serverModeLocalDescription =>
      'Control Center exécute son propre serveur sur cet ordinateur et conserve vos données en local.';

  @override
  String get serverModeRemote => 'Se connecter à une instance distante';

  @override
  String get serverModeRemoteDescription =>
      'Connectez-vous à un serveur Control Center exécuté ailleurs. Vos données résident sur ce serveur.';

  @override
  String get serverRemoteUrl => 'URL du serveur';

  @override
  String get serverRemoteDeviceId => 'Identifiant de l\'appareil';

  @override
  String get serverRemotePairingKey => 'Clé d\'appairage';

  @override
  String get serverRemotePairingKeyHint =>
      'Collez la clé d\'appairage du serveur distant';

  @override
  String get serverSetupInviteCode => 'Code d\'invitation';

  @override
  String get serverSetupInviteCodeHint =>
      'Collez un code d\'invitation à usage unique (laissez vide pour utiliser une clé d\'appairage)';

  @override
  String get serverDiscoveryTooltip =>
      'Rechercher des serveurs sur votre réseau';

  @override
  String get serverDiscoveryTitle => 'Serveurs sur votre réseau';

  @override
  String get serverDiscoverySearching => 'Recherche de serveurs…';

  @override
  String get serverDiscoveryEmpty =>
      'Aucun serveur trouvé. Vérifiez que le serveur est en cours d\'exécution et que cet appareil peut l\'atteindre, puis relancez la recherche.';

  @override
  String get serverDiscoveryRefresh => 'Relancer la recherche';

  @override
  String get serverListActive => 'Actif';

  @override
  String get serverListSwitch => 'Basculer';

  @override
  String get serverListAddTitle => 'Ajouter un serveur';

  @override
  String get serverListRemoveActiveHint =>
      'Basculez vers un autre serveur avant de supprimer celui-ci.';

  @override
  String get serverSwitchFailedTitle => 'Impossible de changer de serveur';

  @override
  String get serverListInsecureBadge => 'Non sécurisé';

  @override
  String get connectionPathLocal => 'Local';

  @override
  String get connectionPathLan => 'LAN';

  @override
  String get connectionPathTailnet => 'Tailnet';

  @override
  String get shutdownTitle => 'Arrêt en cours';

  @override
  String get shutdownSubtitle => 'Fermeture du serveur local';

  @override
  String get shutdownServiceApprovals => 'Approbations';

  @override
  String get shutdownServiceBackgroundJobs => 'Tâches en arrière-plan';

  @override
  String get shutdownServiceScheduler => 'Planificateur de tâches';

  @override
  String get shutdownServiceCalendar => 'Synchro du calendrier';

  @override
  String get shutdownServiceWeather => 'Météo';

  @override
  String get shutdownServiceSoundscape => 'Paysage sonore';

  @override
  String get shutdownServiceMeetings => 'Réunions';

  @override
  String get shutdownServiceVoiceModels => 'Modèles vocaux';

  @override
  String get shutdownServiceNetworking => 'Réseau';

  @override
  String get shutdownServicePresence => 'Présence';

  @override
  String get shutdownServiceDataSync => 'Synchro des données';

  @override
  String get shutdownServiceDeviceRelay => 'Relais d’appareils';

  @override
  String get shutdownServiceMcpConnections => 'Connexions MCP';

  @override
  String get shutdownServiceCodeEditors => 'Éditeurs de code';

  @override
  String get serverSharingTitle => 'Partager ce serveur';

  @override
  String get serverSharingDescription =>
      'Rendez ce serveur accessible depuis vos autres appareils. Rien n\'est exposé publiquement tant que vous n\'activez pas de tunnel ci-dessous. Les invitations d\'appairage intègrent automatiquement les adresses actuelles du serveur — créez-les dans les paramètres de l\'espace de travail.';

  @override
  String get serverSharingUnavailable =>
      'Les contrôles de partage ne sont pas disponibles sur ce serveur.';

  @override
  String get serverSharingMdnsLabel => 'Découverte LAN';

  @override
  String get serverSharingMdnsOn =>
      'Ce serveur est annoncé sur votre réseau local (mDNS)';

  @override
  String get serverSharingMdnsOff =>
      'Ce serveur n\'est pas annoncé sur votre réseau local (mDNS)';

  @override
  String get serverSharingTunnelLabel => 'Tunnel';

  @override
  String get serverSharingTunnelHelper =>
      'Activer un tunnel rend ce serveur accessible depuis Internet. L\'exposition publique est facultative et désactivée par défaut.';

  @override
  String get serverSharingProviderOff => 'Désactivé';

  @override
  String get serverSharingProviderCloudflared => 'Cloudflared';

  @override
  String get serverSharingProviderNgrok => 'ngrok';

  @override
  String get serverSharingProviderTailscale => 'Tailscale';

  @override
  String get serverSharingPublicUrlLabel => 'URL publique';

  @override
  String get serverSharingTunnelStarting => 'Démarrage du tunnel…';

  @override
  String serverSharingTunnelError(String error) {
    return 'Erreur du tunnel : $error';
  }

  @override
  String get serverSharingTunnelUpNoUrl =>
      'Le tunnel est actif. Accédez-y via votre nom d\'hôte DNS configuré.';

  @override
  String get serverSharingRelayLabel => 'Relais';

  @override
  String serverSharingRelayUsage(String amount) {
    return 'Relayé ce mois-ci : $amount';
  }

  @override
  String serverSharingRelaySessions(int count) {
    return 'Sessions relais actives : $count';
  }

  @override
  String get serverSharingUpdateFailedTitle =>
      'Impossible de mettre à jour le partage';

  @override
  String get pairNewClient => 'Associer un nouveau client';

  @override
  String get pairClientNameHint => 'Nommez ce client (ex. PC portable)';

  @override
  String get pairClientTypeWeb => 'Navigateur web';

  @override
  String get pairClientTypeDesktop => 'Application de bureau';

  @override
  String get pairClientTypePhone => 'Téléphone';

  @override
  String get pairAction => 'Associer';

  @override
  String get revoke => 'Révoquer';

  @override
  String get pairCredentialsIntro =>
      'Connectez le nouveau client avec ces informations, ou ouvrez le lien dessus.';

  @override
  String get pairLinkLabel => 'Lien';

  @override
  String get pairScanQr =>
      'Scannez ce QR code avec l\'appareil photo de votre téléphone pour l\'associer.';

  @override
  String get pairServerUnreachableTitle => 'Inaccessible';

  @override
  String get pairServerUnreachable =>
      'Les autres appareils ne peuvent pas joindre ce serveur directement, donc un nouveau client ne peut pas se connecter. Définissez l\'URL publique du serveur pour associer d\'autres clients.';

  @override
  String get serverSetupTitle => 'Comment exécuter Control Center ?';

  @override
  String get serverSetupSubtitle =>
      'Control Center a besoin d\'un serveur qui détient vos données. Exécutez-en un dans cette application ou connectez-vous à une instance exécutée ailleurs.';

  @override
  String get serverSetupRunLocal => 'Exécuter dans cette application';

  @override
  String get serverSetupConnect => 'Se connecter';

  @override
  String get serverSetupInvalidUrl =>
      'Saisissez une URL de serveur ws:// ou wss:// valide.';

  @override
  String get serverSetupCouldNotConnect => 'Connexion impossible';

  @override
  String get serverSetupErrorUnreachable =>
      'Nous n\'avons pas pu joindre le serveur. Vérifiez qu\'il est en cours d\'exécution et que cet appareil peut l\'atteindre (même réseau ou relais).';

  @override
  String get serverSetupErrorIdentityMismatch =>
      'L\'identité du serveur ne correspond pas à celle enregistrée sur cet appareil. Si le serveur a été réinstallé ou réinitialisé, supprimez le serveur enregistré et recommencez l\'appairage.';

  @override
  String get serverSetupErrorAuthRejected =>
      'Le serveur a rejeté cet appareil. Vérifiez que la clé d\'appairage et l\'identifiant de l\'appareil correspondent à ceux fournis par le serveur.';

  @override
  String get serverSetupErrorInviteRejected =>
      'Ce code d\'invitation est invalide ou a expiré. Demandez-en un nouveau.';

  @override
  String get serverSetupErrorGeneric =>
      'Une erreur est survenue lors de la connexion. Dépliez les détails techniques ci-dessous pour plus d\'informations.';

  @override
  String get serverSetupErrorDetails => 'Détails techniques';

  @override
  String calendarMoreEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de plus',
      one: '1 de plus',
    );
    return '$_temp0';
  }

  @override
  String get calendarAllDayGutter => 'Journée';

  @override
  String calendarAllDayEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count événements',
      one: '1 événement',
    );
    return '$_temp0';
  }

  @override
  String get calendarCollapseAllDay => 'Réduire les événements sur la journée';

  @override
  String get calendarExpandAllDay => 'Développer les événements sur la journée';

  @override
  String get calendarViewMonth => 'Mois';

  @override
  String get calendarViewWeek => 'Semaine';

  @override
  String get calendarViewAgenda => 'Agenda';

  @override
  String get calendarConnectGoogle => 'Connecter Google Calendar';

  @override
  String get calendarConnectDescription =>
      'Synchronisez votre Google Calendar pour voir vos événements ici et être averti avant le début des réunions.';

  @override
  String get calendarDisconnect => 'Déconnecter';

  @override
  String get calendarReconnect => 'Reconnecter';

  @override
  String get calendarEmptyNoEvents => 'Aucun événement dans cette période';

  @override
  String get calendarStartRecording => 'Démarrer l\'enregistrement';

  @override
  String get calendarStartRecordingAndLink => 'Enregistrer et lier';

  @override
  String get calendarJoinMeet => 'Rejoindre la réunion';

  @override
  String get calendarFromCalendar => 'Depuis le calendrier';

  @override
  String get calendarLinkedMeeting => 'Réunion liée';

  @override
  String get calendarToday => 'Aujourd\'hui';

  @override
  String get calendarAllDay => 'Toute la journée';

  @override
  String calendarWeekNumber(int number) {
    return 'Semaine $number';
  }

  @override
  String get calendarPreviousPeriod => 'Précédent';

  @override
  String get calendarNextPeriod => 'Suivant';

  @override
  String calendarLastSynced(String time) {
    return 'Synchronisé $time';
  }

  @override
  String get calendarNeverSynced => 'Pas encore synchronisé';

  @override
  String get calendarSyncing => 'Synchronisation…';

  @override
  String get calendarViewDay => 'Jour';

  @override
  String get calendarShow => 'Afficher';

  @override
  String get calendarHide => 'Masquer';

  @override
  String get calendarRsvpGoing => 'Présent ?';

  @override
  String get calendarRsvpYes => 'Oui';

  @override
  String get calendarRsvpNo => 'Non';

  @override
  String get calendarRsvpMaybe => 'Peut-être';

  @override
  String get calendarRsvpFailed => 'Impossible de mettre à jour votre réponse';

  @override
  String get calendarAddAccount => 'Ajouter un compte de calendrier';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Connectez un compte Google pour synchroniser les événements dans cet espace de travail.';

  @override
  String get calendarConnecting => 'Connexion…';

  @override
  String get calendarSyncNow => 'Synchroniser';

  @override
  String get calendarNoWorkspace =>
      'Sélectionnez un espace de travail pour voir son calendrier';

  @override
  String get calendarConnectError => 'Impossible de connecter Google Calendar';

  @override
  String get calendarClientIdLabel => 'ID client';

  @override
  String get calendarClientSecretLabel => 'Secret client';

  @override
  String get calendarConnectCredsHint =>
      'Saisissez l\'ID client et le secret OAuth (device-code) de votre projet Google. Le serveur gère la connexion et la synchronisation — votre navigateur ne détient jamais les jetons.';

  @override
  String get calendarConnectApproveInstruction =>
      'Ouvrez la page de vérification sur n\'importe quel appareil, connectez-vous et saisissez ce code :';

  @override
  String get calendarConnectOpenPage => 'Ouvrir la page de vérification';

  @override
  String get calendarConnectWaiting => 'En attente d\'approbation…';

  @override
  String get calendarConnectDenied =>
      'L\'autorisation a été refusée. Veuillez réessayer.';

  @override
  String get calendarConnectExpired => 'Le code a expiré. Veuillez réessayer.';

  @override
  String get notificationMeetingStartsSoon => 'Réunion imminente';

  @override
  String get notifyMeetingStartsSoon =>
      'Lorsqu\'une réunion du calendrier est sur le point de commencer';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Agenda déconnecté';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Reconnectez $email pour reprendre la synchronisation';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Reconnectez votre agenda pour reprendre la synchronisation';

  @override
  String get notifyCalendarAuthExpired =>
      'Lorsqu\'un compte d\'agenda doit être reconnecté';

  @override
  String get notificationRigStatusChanged => 'Mises à jour des enclos';

  @override
  String get notifyRigStatusChanged =>
      'Lorsqu\'un enclos est repris, récupéré ou échoue';

  @override
  String get notificationRigTakenOver => 'Enclos repris';

  @override
  String get notificationRigTakenOverBody =>
      'Une personne pilote la machine ; l\'agent peut observer mais pas agir.';

  @override
  String get notificationRigReleased => 'Contrôle de l\'enclos rendu';

  @override
  String get notificationRigReleasedBody => 'L\'agent a récupéré la machine.';

  @override
  String get notificationRigReclaimed => 'Enclos récupéré';

  @override
  String get notificationRigReclaimedBodyIdle =>
      'Elle est restée inactive, la machine a donc été fermée pour libérer de la mémoire.';

  @override
  String get notificationRigReclaimedBodyTtl =>
      'Elle a atteint sa limite de temps et a été fermée.';

  @override
  String get notificationRigFailed => 'Échec de l\'enclos';

  @override
  String get notificationRigFailedBody =>
      'L\'hyperviseur est mort en dessous. Rouvrez la machine pour continuer.';

  @override
  String get calendarAlertLeadTime => 'Délai d\'alerte';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'Combien de temps avant une réunion vous prévenir';

  @override
  String calendarConnectedAs(String email) {
    return 'Connecté en tant que $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count participants';
  }

  @override
  String get calendarEventLabel => 'Événement';

  @override
  String get calendarRecurring => 'Événement récurrent';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Organisateur';

  @override
  String get calendarYou => 'Vous';

  @override
  String get calendarShowFewer => 'Afficher moins';

  @override
  String get calendarRsvpAwaiting => 'En attente';

  @override
  String calendarParticipantsCount(int count) {
    return '$count participants';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'Voir les $count participants';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count oui';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count non';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count peut-être';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count en attente';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count minutes';
  }

  @override
  String get openInEditorPrompt => 'Ouvrir dans quel éditeur ?';

  @override
  String get ideNotInstalled => 'Non installé';

  @override
  String openInIde(String editor) {
    return 'Ouvrir dans $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'Impossible d\'ouvrir $editor : $error';
  }

  @override
  String get profileSearchHint => 'Rechercher des pull requests…';

  @override
  String get stopAgentRun => 'Arrêter l\'exécution';

  @override
  String get stopAgentRunConfirm =>
      'Arrêter cette exécution ? Le travail en cours sera perdu.';

  @override
  String get inProgress => 'En cours';

  @override
  String get drafts => 'Brouillons';

  @override
  String get sortOldest => 'Plus anciennes';

  @override
  String get sortLargest => 'Plus grandes';

  @override
  String get prFilterTooltip => 'Filtrer';

  @override
  String prFilterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filtres actifs',
      one: '1 filtre actif',
    );
    return '$_temp0';
  }

  @override
  String get prFilterAddFilter => 'Ajouter un filtre…';

  @override
  String get prFilterFieldHint => 'Filtrer…';

  @override
  String get prFilterCategoryStatus => 'Statut';

  @override
  String get prFilterCategoryAuthor => 'Auteur';

  @override
  String get prFilterCategoryReviewer => 'Relecteurs';

  @override
  String get prFilterCategoryContent => 'Contenu';

  @override
  String get prFilterCategoryRepoOwner => 'Propriétaire du dépôt';

  @override
  String get prFilterCategoryRepoName => 'Nom du dépôt';

  @override
  String get prFilterCategoryOpenedDate => 'Date d\'ouverture';

  @override
  String get prFilterCategoryUpdatedDate => 'Date de mise à jour';

  @override
  String get prFilterQuickToReview => 'Rapide à relire';

  @override
  String get prFilterClearAll => 'Effacer les filtres';

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
      other: '$count options ne correspondant à aucune pull request',
      one: '1 option ne correspondant à aucune pull request',
    );
    return '$_temp0';
  }

  @override
  String get prFilterContentHint => 'Le titre ou le corps contient…';

  @override
  String get prFilterNoOptions => 'Aucune option correspondante';

  @override
  String get prFilterChipIs => 'est';

  @override
  String get prFilterChipIsAnyOf => 'est l\'un de';

  @override
  String get prFilterChipContains => 'contient';

  @override
  String get prFilterChipSince => 'depuis';

  @override
  String get prFilterAddFilterButton => 'Ajouter un filtre';

  @override
  String prFilterClearCategory(String category) {
    return 'Effacer le filtre $category';
  }

  @override
  String get prFilterCurrentUser => 'Utilisateur actuel';

  @override
  String get prStatusDraft => 'Brouillon';

  @override
  String get prStatusOpen => 'Ouvert';

  @override
  String get prStatusInReview => 'En révision';

  @override
  String get prStatusChangesRequested => 'Modifications demandées';

  @override
  String get prStatusApproved => 'Approuvé';

  @override
  String get prStatusMerged => 'Fusionné';

  @override
  String get prStatusClosed => 'Fermé';

  @override
  String get prDateWindowDay => 'il y a 1 jour';

  @override
  String get prDateWindowThreeDays => 'il y a 3 jours';

  @override
  String get prDateWindowWeek => 'il y a 1 semaine';

  @override
  String get prDateWindowMonth => 'il y a 1 mois';

  @override
  String get prDateWindowThreeMonths => 'il y a 3 mois';

  @override
  String get prDateWindowSixMonths => 'il y a 6 mois';

  @override
  String get prDateWindowYear => 'il y a 1 an';

  @override
  String get prDisplayOptions => 'Options d\'affichage';

  @override
  String get prDisplayGrouping => 'Regroupement';

  @override
  String get prDisplayOrdering => 'Tri';

  @override
  String get prDisplayShowDrafts => 'Afficher les brouillons';

  @override
  String get prDisplayMergedWindow => 'Fenêtre de fusion';

  @override
  String get prDisplayMergedWindowDay => 'Dernier jour';

  @override
  String get prDisplayMergedWindowWeek => 'Dernière semaine';

  @override
  String get prDisplayMergedWindowMonth => 'Dernier mois';

  @override
  String get prDisplayProperties => 'Propriétés d\'affichage';

  @override
  String get prGroupingRepository => 'Dépôt';

  @override
  String get prGroupingAuthor => 'Auteur';

  @override
  String get prGroupingStatus => 'Statut';

  @override
  String get prGroupingNone => 'Aucun regroupement';

  @override
  String get prPropertyRepository => 'Dépôt';

  @override
  String get prPropertyId => 'ID';

  @override
  String get prPropertyBranch => 'Branche';

  @override
  String get prPropertyUpdated => 'Mis à jour';

  @override
  String get prPropertyAuthor => 'Auteur';

  @override
  String get prPropertyChecks => 'Vérifications';

  @override
  String get prPropertyDiff => 'Diff';

  @override
  String get prPropertyComments => 'Commentaires';

  @override
  String get keybindingOpenFilterMenu => 'Ouvrir le menu de filtres';

  @override
  String get keybindingOpenThePullRequestFilterMenuDescription =>
      'Ouvrir le menu de filtres des PR';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnées',
      one: '1 sélectionnée',
    );
    return '$_temp0';
  }

  @override
  String get summary => 'Résumé';

  @override
  String get kbMove => 'déplacer';

  @override
  String get kbTabs => 'onglets';

  @override
  String get kbSearch => 'rechercher';

  @override
  String get kbViewed => 'vu';

  @override
  String get kbCollapse => 'réduire';

  @override
  String get appearance => 'Apparence';

  @override
  String get appearanceSettingsDescription => 'Thème, langue et typographie.';

  @override
  String get notificationsSettingsDescription =>
      'Choisissez les événements d\'agent et d\'espace de travail qui vous notifient.';

  @override
  String get advanced => 'Avancé';

  @override
  String get accounts => 'Comptes';

  @override
  String get mcpServers => 'Serveurs MCP';

  @override
  String get mcpServersSettingsDescription =>
      'Serveur MCP intégré et serveurs MCP externes.';

  @override
  String get remoteControlAndDevices => 'Contrôle à distance & appareils';

  @override
  String get remoteControlAndDevicesSettingsDescription =>
      'Apparier les téléphones et configurer le serveur de contrôle à distance.';

  @override
  String get voiceAndMeetingsSettingsDescription =>
      'Les modèles de reconnaissance vocale et de diarisation hébergés par ce serveur.';

  @override
  String get filterSettingsHint => 'Filtrer les paramètres';

  @override
  String get needsSetupLabel => 'Configuration requise';

  @override
  String noSettingsMatch(String query) {
    return 'Aucun paramètre ne correspond à « $query »';
  }

  @override
  String get collapseSidebar => 'Réduire la barre latérale';

  @override
  String get expandSidebar => 'Développer la barre latérale';

  @override
  String get filterSpacesHint => 'Filtrer les espaces';

  @override
  String noSpacesMatch(String query) {
    return 'Aucun espace ne correspond à « $query »';
  }

  @override
  String get privacy => 'Confidentialité';

  @override
  String get sendDiffContentTitle =>
      'Envoyer le contenu du diff à l\'adaptateur IA';

  @override
  String get diffSharingOnSubtitle =>
      'Les lignes de diff brutes sont incluses dans les invites des agents pour une revue approfondie.';

  @override
  String get diffSharingOffSubtitle =>
      'Les agents utilisent uniquement des métadonnées structurées (chemins de fichiers, numéros de ligne, description de la PR) ; aucun code brut ne quitte l\'application.';

  @override
  String get errorReportingTitle => 'Partager les rapports de plantage';

  @override
  String get errorReportingOnSubtitle =>
      'Les diagnostics de plantage, d\'erreur et de performance sont envoyés pour aider à corriger les bugs (versions de production uniquement).';

  @override
  String get errorReportingOffSubtitle =>
      'Les diagnostics sont désactivés. Aucun rapport de plantage ou d\'erreur n\'est envoyé.';

  @override
  String get onboardingDiagnosticsTitle => 'Aidez à améliorer Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Envoyez des diagnostics de plantage, d\'erreur et de performance pour nous aider à corriger les problèmes plus vite (versions de production uniquement). Vous pouvez modifier ce choix à tout moment dans Réglages → Confidentialité.';

  @override
  String get blocked => 'Bloqué';

  @override
  String get idle => 'Inactif';

  @override
  String get noRunsYet => 'Aucune exécution';

  @override
  String lastActiveAgo(String duration) {
    return 'Actif il y a $duration';
  }

  @override
  String get copyPath => 'Copier le chemin';

  @override
  String get copyRelativePath => 'Copier le chemin relatif';

  @override
  String get nameRequired => 'Le nom est requis';

  @override
  String get import => 'Importer';

  @override
  String get sortByStatus => 'Statut';

  @override
  String get sortByName => 'Nom';

  @override
  String get noMatchingAgents => 'Aucun agent ne correspond à votre filtre';

  @override
  String watchVideoOn(String provider) {
    return 'Regarder la vidéo sur $provider';
  }

  @override
  String get branchTemplate => 'Modèle de nom de branche';

  @override
  String get branchTemplateDescription =>
      'Modèle de la branche créée au démarrage d\'un ticket dans un worktree isolé.';

  @override
  String branchTemplatePreview(String example) {
    return 'Exemple : $example';
  }

  @override
  String get deletePipelineRun => 'Supprimer l\'exécution du pipeline';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Supprimer cette exécution de « $template » ? Cette action est irréversible.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Erreur lors de la suppression de l\'exécution du pipeline : $error';
  }

  @override
  String get deleteTicket => 'Supprimer le ticket';

  @override
  String deleteTicketConfirm(String title) {
    return 'Supprimer « $title » ? Cette action est irréversible.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Erreur lors de la suppression du ticket : $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return 'Supprimer « $name » ? Les dépôts liés sur le disque ne sont pas affectés.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Erreur lors de la suppression de l\'espace de travail : $error';
  }

  @override
  String get indexCode => 'Indexer le code';

  @override
  String get indexNoGrammars => 'Grammaires de code non installées';

  @override
  String get indexFailed => 'Échec de l\'indexation';

  @override
  String indexedSymbolsCount(int count) {
    return '$count symboles indexés';
  }

  @override
  String get nodeConfigAdvanced => 'Avancé';

  @override
  String get nodeConfigReducer => 'Réducteur';

  @override
  String get nodeConfigReducerHelp =>
      'Comment fusionner lorsque cette clé de sortie a déjà une valeur';

  @override
  String get nodeConfigTimeoutMs => 'Délai d\'expiration (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Tentatives de réessai';

  @override
  String get nodeConfigContinueOnFail => 'Continuer si cette étape échoue';

  @override
  String get nodeConfigTeamId => 'ID d\'équipe';

  @override
  String get nodeConfigDispatchMode => 'Mode de répartition';

  @override
  String get nodeConfigOutputSchema => 'Schéma de sortie (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'Schéma JSON que la sortie de l\'étape doit respecter';

  @override
  String get diffLineDisplay => 'Lignes longues dans les diffs';

  @override
  String get diffLineDisplayDescription =>
      'Renvoyer les lignes longues à la ligne ou les faire défiler horizontalement';

  @override
  String get diffLineWrap => 'Renvoi à la ligne';

  @override
  String get diffLineScroll => 'Défilement horizontal';

  @override
  String get actions => 'Actions';

  @override
  String get activate => 'Activer';

  @override
  String get activity => 'Activité';

  @override
  String get activityLabel => 'ACTIVITÉ';

  @override
  String get activitySearchHint => 'Rechercher dans l\'activité';

  @override
  String get activityNoMatches => 'Aucune activité ne correspond à vos filtres';

  @override
  String activityPageRange(int start, int end, int total) {
    return '$start–$end sur $total';
  }

  @override
  String get activityPreviousPage => 'Page précédente';

  @override
  String get activityNextPage => 'Page suivante';

  @override
  String get activityNetworkLocal => 'Localhost';

  @override
  String get activityClearFilter => 'Effacer le filtre';

  @override
  String activityFilterIp(String ip) {
    return 'IP $ip';
  }

  @override
  String activityFilterCountry(String country) {
    return 'Pays $country';
  }

  @override
  String get activitySavedWorkspaceLogo =>
      'A enregistré le logo de l\'espace de travail';

  @override
  String activityVerbCreated(String target) {
    return 'A créé $target';
  }

  @override
  String activityVerbUpdated(String target) {
    return 'A mis à jour $target';
  }

  @override
  String activityVerbDeleted(String target) {
    return 'A supprimé $target';
  }

  @override
  String activityVerbAdded(String target) {
    return 'A ajouté $target';
  }

  @override
  String activityVerbRemoved(String target) {
    return 'A retiré $target';
  }

  @override
  String activityVerbInvited(String target) {
    return 'A invité $target';
  }

  @override
  String activityVerbChanged(String target) {
    return 'A modifié $target';
  }

  @override
  String activityVerbStarted(String target) {
    return 'A démarré $target';
  }

  @override
  String activityVerbStopped(String target) {
    return 'A arrêté $target';
  }

  @override
  String activityVerbWrote(String target) {
    return 'A écrit $target';
  }

  @override
  String get activityTargetAgent => 'un agent';

  @override
  String get activityTargetTicket => 'un ticket';

  @override
  String get activityTargetWorkspace => 'un espace de travail';

  @override
  String get activityTargetRepository => 'un dépôt';

  @override
  String get activityTargetMember => 'un membre';

  @override
  String get activityTargetInvite => 'une invitation';

  @override
  String get activityTargetSpace => 'un espace';

  @override
  String get activityTargetMessage => 'un message';

  @override
  String get activityTargetCache => 'un cache';

  @override
  String get activityTargetFile => 'un fichier';

  @override
  String get activityTargetPipeline => 'un pipeline';

  @override
  String get activityTargetTemplate => 'un template';

  @override
  String get activityTargetProvider => 'un fournisseur';

  @override
  String get activityTargetModel => 'un modèle';

  @override
  String get activityTargetSkill => 'une compétence';

  @override
  String get activityTargetTodo => 'une tâche';

  @override
  String get activityTargetMeeting => 'une réunion';

  @override
  String get activityTargetProject => 'un projet';

  @override
  String get activityTargetTeam => 'une équipe';

  @override
  String get activityTargetDevice => 'un appareil';

  @override
  String get activityTargetPreference => 'une préférence';

  @override
  String get activityTargetBudget => 'un budget';

  @override
  String activityVerbApproved(String target) {
    return 'A approuvé $target';
  }

  @override
  String activityVerbArchived(String target) {
    return 'A archivé $target';
  }

  @override
  String activityVerbAssigned(String target) {
    return 'A assigné $target';
  }

  @override
  String activityVerbBackedUp(String target) {
    return 'A sauvegardé $target';
  }

  @override
  String activityVerbCancelled(String target) {
    return 'A annulé $target';
  }

  @override
  String activityVerbCleared(String target) {
    return 'A effacé $target';
  }

  @override
  String activityVerbClosed(String target) {
    return 'A fermé $target';
  }

  @override
  String activityVerbCommitted(String target) {
    return 'A commité $target';
  }

  @override
  String activityVerbCompacted(String target) {
    return 'A compacté $target';
  }

  @override
  String activityVerbCompleted(String target) {
    return 'A terminé $target';
  }

  @override
  String activityVerbConnected(String target) {
    return 'A connecté $target';
  }

  @override
  String activityVerbContinued(String target) {
    return 'A continué $target';
  }

  @override
  String activityVerbDisconnected(String target) {
    return 'A déconnecté $target';
  }

  @override
  String activityVerbDispatched(String target) {
    return 'A distribué $target';
  }

  @override
  String activityVerbDrained(String target) {
    return 'A vidé $target';
  }

  @override
  String activityVerbEnrolled(String target) {
    return 'A inscrit $target';
  }

  @override
  String activityVerbEstimated(String target) {
    return 'A estimé $target';
  }

  @override
  String activityVerbImported(String target) {
    return 'A importé $target';
  }

  @override
  String activityVerbInstalled(String target) {
    return 'A installé $target';
  }

  @override
  String activityVerbKilled(String target) {
    return 'A tué $target';
  }

  @override
  String activityVerbMarked(String target) {
    return 'A marqué $target';
  }

  @override
  String activityVerbMerged(String target) {
    return 'A fusionné $target';
  }

  @override
  String activityVerbOpened(String target) {
    return 'A ouvert $target';
  }

  @override
  String activityVerbPaused(String target) {
    return 'A mis en pause $target';
  }

  @override
  String activityVerbPolled(String target) {
    return 'A interrogé $target';
  }

  @override
  String activityVerbPrepared(String target) {
    return 'A préparé $target';
  }

  @override
  String activityVerbProcessed(String target) {
    return 'A traité $target';
  }

  @override
  String activityVerbPublished(String target) {
    return 'A publié $target';
  }

  @override
  String activityVerbRefined(String target) {
    return 'A affiné $target';
  }

  @override
  String activityVerbRefreshed(String target) {
    return 'A actualisé $target';
  }

  @override
  String activityVerbRegistered(String target) {
    return 'A enregistré $target';
  }

  @override
  String activityVerbRenamed(String target) {
    return 'A renommé $target';
  }

  @override
  String activityVerbReordered(String target) {
    return 'A réordonné $target';
  }

  @override
  String activityVerbResponded(String target) {
    return 'A répondu à $target';
  }

  @override
  String activityVerbRestored(String target) {
    return 'A restauré $target';
  }

  @override
  String activityVerbResumed(String target) {
    return 'A repris $target';
  }

  @override
  String activityVerbRetried(String target) {
    return 'A relancé $target';
  }

  @override
  String activityVerbReverted(String target) {
    return 'A rétabli $target';
  }

  @override
  String activityVerbReviewed(String target) {
    return 'A examiné $target';
  }

  @override
  String activityVerbRan(String target) {
    return 'A exécuté $target';
  }

  @override
  String activityVerbSelected(String target) {
    return 'A sélectionné $target';
  }

  @override
  String activityVerbSent(String target) {
    return 'A envoyé $target';
  }

  @override
  String activityVerbStaged(String target) {
    return 'A stagé $target';
  }

  @override
  String activityVerbSteered(String target) {
    return 'A orienté $target';
  }

  @override
  String activityVerbSubmitted(String target) {
    return 'A soumis $target';
  }

  @override
  String activityVerbSynced(String target) {
    return 'A synchronisé $target';
  }

  @override
  String activityVerbToggled(String target) {
    return 'A basculé $target';
  }

  @override
  String activityVerbUninstalled(String target) {
    return 'A désinstallé $target';
  }

  @override
  String activityVerbUnstaged(String target) {
    return 'A destagé $target';
  }

  @override
  String get activityTargetActionPolicy => 'une politique d\'action';

  @override
  String get activityTargetGoalRun => 'une exécution d\'objectif';

  @override
  String get activityTargetRunLog => 'un journal d\'exécution';

  @override
  String get activityTargetWorkingMemory => 'une mémoire de travail';

  @override
  String get activityTargetRoutingPolicy => 'une politique de routage';

  @override
  String get activityTargetAutonomy => 'une autonomie';

  @override
  String get activityTargetCalendar => 'un calendrier';

  @override
  String get activityTargetChecker => 'un vérificateur';

  @override
  String get activityTargetEditor => 'un éditeur';

  @override
  String get activityTargetConfirmation => 'une confirmation';

  @override
  String get activityTargetTunnel => 'un tunnel';

  @override
  String get activityTargetConversation => 'une conversation';

  @override
  String get activityTargetCredentials => 'des identifiants';

  @override
  String get activityTargetDictation => 'une dictée';

  @override
  String get activityTargetAgentRun => 'une exécution d\'agent';

  @override
  String get activityTargetEvalSuite => 'une suite d\'évaluation';

  @override
  String get activityTargetWorker => 'un worker';

  @override
  String get activityTargetWorktree => 'un worktree';

  @override
  String get activityTargetMcpServer => 'un serveur MCP';

  @override
  String get activityTargetMemoryAccessGrant =>
      'une autorisation d\'accès à la mémoire';

  @override
  String get activityTargetMemoryDomain => 'un domaine de mémoire';

  @override
  String get activityTargetMemoryFact => 'un fait de mémoire';

  @override
  String get activityTargetMemoryPolicy => 'une politique de mémoire';

  @override
  String get activityTargetFeed => 'un flux';

  @override
  String get activityTargetNote => 'une note';

  @override
  String get activityTargetOrchestration => 'une orchestration';

  @override
  String get activityTargetPipelineRun => 'une exécution de pipeline';

  @override
  String get activityTargetPipelineTrigger => 'un déclencheur de pipeline';

  @override
  String get activityTargetPlan => 'un plan';

  @override
  String get activityTargetPlaybook => 'un playbook';

  @override
  String get activityTargetPullRequest => 'une pull request';

  @override
  String get activityTargetReview => 'une review';

  @override
  String get activityTargetProcess => 'un processus';

  @override
  String get activityTargetProviderPolicy => 'une politique de fournisseur';

  @override
  String get activityTargetReaction => 'une réaction';

  @override
  String get activityTargetReviewSpace => 'un espace de review';

  @override
  String get activityTargetReviewStudio => 'un studio de review';

  @override
  String get activityTargetServerData => 'des données du serveur';

  @override
  String get activityTargetSoundscape => 'un paysage sonore';

  @override
  String get activityTargetSession => 'une session';

  @override
  String get activityTargetTerminal => 'un terminal';

  @override
  String get activityTargetTicketLink => 'un lien de ticket';

  @override
  String get activityTargetTicketSync => 'une synchronisation de tickets';

  @override
  String get activityTargetProfile => 'un profil';

  @override
  String get activityTargetVoiceProfile => 'un profil vocal';

  @override
  String get activityTargetWeather => 'une prévision météo';

  @override
  String get activityTargetWorkProduct => 'un livrable';

  @override
  String get activityChangedMemberRole => 'A modifié le rôle d\'un membre';

  @override
  String get activityChangedMemberRepoAccess =>
      'A modifié l\'accès d\'un membre aux dépôts';

  @override
  String get activityUpdatedGitHubToken => 'A mis à jour le token GitHub';

  @override
  String get activityRefreshedWeather => 'A actualisé la prévision météo';

  @override
  String get activitySetWeatherLocation => 'A défini la localisation météo';

  @override
  String get activityClearedWeatherLocation => 'A effacé la localisation météo';

  @override
  String get activityMarkedAllArticlesRead =>
      'A marqué tous les articles comme lus';

  @override
  String get activityMarkedArticleRead => 'A marqué un article comme lu';

  @override
  String get activityUpdatedSavedArticle =>
      'A mis à jour un article enregistré';

  @override
  String get activityTookOverSession => 'A pris en charge la session';

  @override
  String get activityHandedBackSession => 'A rendu la session';

  @override
  String get activityCommittedAndPushed => 'A commité et pushé';

  @override
  String get activityBackedUpServer => 'A sauvegardé les données du serveur';

  @override
  String get activityMarkedSpaceRead => 'A marqué le espace comme lu';

  @override
  String get activityRespondedToInvitation =>
      'A répondu à l\'invitation à l\'événement';

  @override
  String get activityStartedCalendarConnect =>
      'A démarré la connexion du calendrier';

  @override
  String get activityDisconnectedCalendar => 'A déconnecté le calendrier';

  @override
  String get activityMarkedFileViewed => 'A marqué un fichier comme vu';

  @override
  String get activityRespondedToApproval =>
      'A répondu à une demande d\'approbation';

  @override
  String get activityChangedTunnel => 'A modifié le paramètre du tunnel';

  @override
  String get activitySentMessageToAgent => 'A envoyé un message à l\'agent';

  @override
  String get activityOpenedReviewSpace => 'A ouvert l’espace de review';

  @override
  String get activityOpenedStandingConversation =>
      'A ouvert la conversation principale';

  @override
  String get activityStartedRecording => 'A démarré l\'enregistrement';

  @override
  String get activityStoppedRecording => 'A arrêté l\'enregistrement';

  @override
  String get activityToggledMcpServer => 'A basculé le serveur MCP';

  @override
  String get activityUpdatedMcpToken => 'A mis à jour le token MCP';

  @override
  String get activitySavedApiKey => 'A enregistré une clé API';

  @override
  String get activityRemovedProviderCredential =>
      'A retiré un identifiant de fournisseur';

  @override
  String get activityUpdatedLinkedRepos => 'A mis à jour les dépôts liés';

  @override
  String get activityUnlinkedRepo => 'A délié un dépôt';

  @override
  String get activityUpdatedActionItem => 'A mis à jour une action';

  @override
  String adRulesCount(int count) {
    return '$count règles de publicités';
  }

  @override
  String get adapter => 'Adaptateur';

  @override
  String get adapterLabel => 'Adaptateur';

  @override
  String get adapters => 'Adaptateurs';

  @override
  String get adaptersAutoDetected =>
      'Exécuteurs d\'agent auto-détectés disponibles sur cette machine. Installez les outils CLI manquants pour activer des exécuteurs supplémentaires.';

  @override
  String get add => 'Ajouter';

  @override
  String get addAComment => 'Ajouter un commentaire';

  @override
  String get addAReaction => 'Ajouter une réaction';

  @override
  String get addASuggestion => 'Ajouter une suggestion';

  @override
  String get addAgents => 'Ajouter des agents';

  @override
  String get addEmoji => 'Ajouter un émoji';

  @override
  String get addFeed => 'Ajouter un flux';

  @override
  String get addressBarHint => 'Saisir une URL';

  @override
  String get addFromFile => 'Ajouter depuis un fichier';

  @override
  String get addGif => 'Ajouter un GIF';

  @override
  String get addGithubRepoPrompt =>
      'Ajoutez au moins un dépôt GitHub pour voir les demandes de tirage';

  @override
  String get addLocalCheckoutDescription =>
      'Ajoutez un checkout local pour commencer à le cibler depuis cet espace de travail.';

  @override
  String get addRepository => 'Ajouter un dépôt';

  @override
  String addSelectedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ajouter $count dépôts',
      one: 'Ajouter le dépôt',
    );
    return '$_temp0';
  }

  @override
  String get addRepoBrowseIntro =>
      'Parcourez les dossiers de la machine qui exécute le serveur et sélectionnez les dépôts git à enregistrer.';

  @override
  String get selectThisFolder => 'Sélectionner ce dossier';

  @override
  String get deselectThisFolder => 'Désélectionner ce dossier';

  @override
  String get goUp => 'Remonter';

  @override
  String get noSubfoldersHere => 'Aucun sous-dossier ici';

  @override
  String get notAGitRepository => 'Ce dossier n\'est pas un dépôt git.';

  @override
  String get addToken => 'Ajouter un jeton';

  @override
  String get addWorkspace => 'Ajouter un espace de travail';

  @override
  String get addWorkspaceEllipsis => 'Ajouter un espace de travail…';

  @override
  String get added => 'Ajouté';

  @override
  String get addingEllipsis => 'Ajout en cours...';

  @override
  String get advancedLabel => 'Avancé';

  @override
  String get agent => 'Agent';

  @override
  String agentCount(int count, int plural) {
    String _temp0 = intl.Intl.pluralLogic(
      plural,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count agent$_temp0';
  }

  @override
  String get agentMdPath => 'Chemin MD de l\'agent';

  @override
  String get agentName => 'Nom de l\'agent';

  @override
  String get agentTitle => 'Titre de l\'agent';

  @override
  String get agentUpdated => 'Agent mis à jour.';

  @override
  String get agents => 'Agents';

  @override
  String get agentsMentionSection => 'Agents';

  @override
  String get usersMentionSection => 'Personnes';

  @override
  String get ticketsMentionSection => 'Tickets';

  @override
  String get pullRequestsMentionSection => 'Pull requests';

  @override
  String get meetingsMentionSection => 'Réunions';

  @override
  String get entityRefTicketFallback => 'Ticket';

  @override
  String get entityRefPrFallback => 'Pull request';

  @override
  String get entityRefMeetingFallback => 'Réunion';

  @override
  String get aiReview => 'Revue IA';

  @override
  String get all => 'Tout';

  @override
  String get allAgentsAlreadyInSpace =>
      'Tous les agents sont déjà dans cet espace.';

  @override
  String get allCommits => 'Tous les commits';

  @override
  String get allSources => 'Toutes les sources';

  @override
  String get allow => 'Autoriser';

  @override
  String get allowGitPush => 'Autoriser git push';

  @override
  String get allowGithubApi => 'Autoriser les appels API GitHub';

  @override
  String get allowNetwork => 'Autoriser l\'accès réseau général';

  @override
  String get apiKeys => 'Clés API';

  @override
  String get appFont => 'Police de l\'app';

  @override
  String get appLogLevelDebugDescription =>
      'Ajoute les traces détaillées - pour le développement.';

  @override
  String get appLogLevelDebugLabel => 'Débogage';

  @override
  String get appLogLevelErrorDescription =>
      'Seulement les erreurs et exceptions inattendues.';

  @override
  String get appLogLevelErrorLabel => 'Erreur';

  @override
  String get appLogLevelInfoDescription =>
      'Ajoute les messages de cycle de vie et d\'état.';

  @override
  String get appLogLevelInfoLabel => 'Info';

  @override
  String get appLogLevelNoneDescription => 'Aucune sortie console.';

  @override
  String get appLogLevelNoneLabel => 'Aucun';

  @override
  String get appLogLevelVerboseDescription =>
      'Tout. Extrêmement verbeux - à utiliser uniquement pour le débogage.';

  @override
  String get appLogLevelVerboseLabel => 'Verbeux';

  @override
  String get appLogLevelWarningDescription =>
      'Ajoute les avertissements et problèmes récupérables.';

  @override
  String get appLogLevelWarningLabel => 'Avertissement';

  @override
  String get appearanceLanguage => 'Apparence et langue';

  @override
  String get apply => 'Appliquer';

  @override
  String get approve => 'Approuver';

  @override
  String get agentApprovalRequired => 'Approbation requise';

  @override
  String agentApprovalsMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count autres en attente',
      one: '1 autre en attente',
    );
    return '$_temp0';
  }

  @override
  String get approved => 'Approuvé';

  @override
  String get articlesSubscribed => 'Articles de vos flux abonnés.';

  @override
  String get askAi => 'Ask AI';

  @override
  String get askAiReviewDescription => 'Demander à l\'IA de relire cette PR';

  @override
  String get assignees => 'ASSIGNÉS';

  @override
  String get attachFiles => 'Joindre des fichiers';

  @override
  String get attachImage => 'Joindre une image';

  @override
  String get attachedAgents => 'Agents attachés';

  @override
  String get audioInput => 'Entrée audio';

  @override
  String get audioOutput => 'Sortie audio';

  @override
  String get authenticationToken => 'Jeton d\'authentification';

  @override
  String authoredByLabel(String role) {
    return 'Par : $role';
  }

  @override
  String get autoRecommended => 'Auto (recommandé)';

  @override
  String get available => 'Disponible';

  @override
  String get awaitingYourReview => 'En attente de votre revue';

  @override
  String get back => 'Retour';

  @override
  String get backLabel => 'Retour';

  @override
  String get backend => 'Back-end';

  @override
  String get blockAdsTrackers =>
      'Bloquer les publicités, traqueurs et bannières de cookies';

  @override
  String get blocking => 'Bloquant';

  @override
  String get bookmarkLabel => 'Signet';

  @override
  String get briefDescription => 'Brève description';

  @override
  String get bugLabel => 'BUG';

  @override
  String get bundledDefaultsNeverUpdated => 'Préchargé - jamais mis à jour';

  @override
  String get cancel => 'Annuler';

  @override
  String get cancelEdit => 'Annuler l\'édition';

  @override
  String get categoryCreation => 'Création';

  @override
  String get categoryEditing => 'Édition';

  @override
  String get categoryNavigation => 'Navigation';

  @override
  String get categorySystem => 'Système';

  @override
  String get categoryView => 'Vue';

  @override
  String get change => 'Modifier';

  @override
  String get changesRequested => 'Modifications demandées';

  @override
  String get spacesMentionSection => 'Espaces';

  @override
  String get checkForUpdates => 'Vérifier les mises à jour';

  @override
  String get checking => 'Vérification';

  @override
  String get checkingEllipsis => 'Vérification…';

  @override
  String get chooseAppFont => 'Choisir la police de l\'application';

  @override
  String get chooseCodeFont => 'Choisir la police de code';

  @override
  String get chooseRunner => 'Choisissez votre exécuteur d\'agent.';

  @override
  String get clear => 'Effacer';

  @override
  String get clickToRetry => 'Cliquer pour réessayer';

  @override
  String get close => 'Fermer';

  @override
  String get closeEsc => 'Fermer (Échap)';

  @override
  String get closeKeyboardHint => 'Fermer les raccourcis clavier';

  @override
  String get closeReader => 'Fermer le lecteur';

  @override
  String get closed => 'Fermé';

  @override
  String get codeFont => 'Police de code';

  @override
  String get codeFontLigatures => 'Ligatures de la police de code';

  @override
  String get codeFontLigaturesDescription =>
      'Afficher les ligatures de programmation (=>, !=, ->) sous forme de glyphes combinés dans le code et les diffs';

  @override
  String get collapse => 'Réduire';

  @override
  String get commandPalette => 'Palette de commandes';

  @override
  String get commandPaletteOrgMembers => 'Organization members';

  @override
  String get commandPaletteBrowseTeam => 'Browse team';

  @override
  String get commandPaletteBrowseTeamDesc => 'View all organization members';

  @override
  String get compactDone =>
      'Conversation compactée. L\'historique ancien a été résumé.';

  @override
  String get compactNothing =>
      'Rien à compacter pour l\'instant. La conversation est encore courte.';

  @override
  String get compactBusy =>
      'Un agent travaille encore. Compactez quand le tour sera terminé.';

  @override
  String get compactUnavailable =>
      'Le compactage n\'est pas disponible sur ce serveur.';

  @override
  String get commandsMentionSection => 'Commandes';

  @override
  String get comment => 'Commentaire';

  @override
  String get commentOnThisFile => 'Commenter ce fichier';

  @override
  String get commented => 'Commenté';

  @override
  String get commits => 'Commits';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Affichage des $loaded derniers commits sur $total';
  }

  @override
  String get prCloneProgressCloningTitle => 'Clonage du dépôt';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'Cette PR modifie $fileCount fichiers, dépassant la limite de l\'API GitHub. Clonage du dépôt en local…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'Cette PR dépasse la limite de fichiers de l\'API GitHub. Clonage du dépôt en local…';

  @override
  String get prCloneProgressFetchingTitle => 'Récupération des refs';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Récupération de la branche de base et de la PR…';

  @override
  String get prCloneProgressComputingTitle => 'Calcul du diff';

  @override
  String get prCloneProgressComputingSubtitle =>
      'Exécution de git diff en local…';

  @override
  String get prCloneProgressErrorTitle => 'Échec du chargement';

  @override
  String get prCloneProgressErrorSubtitle =>
      'Une erreur est survenue lors du clonage ou du calcul du diff.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Toujours en cours… $elapsed écoulées';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Confiance : $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'Configurer les identités, prompts, compétences des agents et voir les exécutions.';

  @override
  String get configureDefaultRunners =>
      'Configurez l\'adaptateur et le modèle utilisés pour les nouvelles conversations et la génération de titres.';

  @override
  String get configuredLabel => 'Configuré.';

  @override
  String get confirmedBy => 'Confirmé par';

  @override
  String get consensus => 'Consensus';

  @override
  String get contentHint => 'Ce qui doit être mémorisé';

  @override
  String get contentLabel => 'Contenu';

  @override
  String get contentMarkdown => 'Contenu (Markdown)';

  @override
  String get contextWindowSize => 'Taille de la fenêtre de contexte';

  @override
  String modelContextChip(String size) {
    return 'Modèle · $size';
  }

  @override
  String get continueLabel => 'Continuer';

  @override
  String get conversationMode => 'Mode';

  @override
  String cookieRulesCount(int count) {
    return '$count règles de cookies';
  }

  @override
  String get copied => 'Copié !';

  @override
  String get copy => 'Copier';

  @override
  String get copyAddress => 'Copier l\'adresse';

  @override
  String get copyBaseBranchTooltip => 'Copier le nom de la branche cible';

  @override
  String get copyHeadBranchTooltip => 'Copier le nom de la branche source';

  @override
  String couldNotListDevices(String error) {
    return 'Impossible de lister les périphériques : $error';
  }

  @override
  String get create => 'Créer';

  @override
  String get createOrSelectWorkspace =>
      'Créez ou sélectionnez un espace de travail avant d\'ajouter des dépôts.';

  @override
  String get createPullRequest => 'Créer la pull request';

  @override
  String get createdByMe => 'Créées par moi';

  @override
  String createdLabel(String date) {
    return 'Créé : $date';
  }

  @override
  String get currentParticipants => 'Participants actuels';

  @override
  String get customCapabilitiesDescription =>
      'Capacités personnalisées pour cet agent';

  @override
  String get customSystemPrompt =>
      'Prompt système personnalisé pour cet agent...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Désactiver';

  @override
  String get defaultCapabilities =>
      'Capacités par défaut · nouvelles conversations';

  @override
  String get defaultChat => 'Chat par défaut';

  @override
  String get defaultRunners => 'Exécuteurs par défaut';

  @override
  String get delete => 'Supprimer';

  @override
  String get deleteAgent => 'Supprimer l\'agent';

  @override
  String deleteAgentConfirm(String name) {
    return 'Supprimer « $name » ? Cette action est irréversible.';
  }

  @override
  String get deleteSpace => 'Supprimer le espace';

  @override
  String deleteConfirmName(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get archiveConversation => 'Archiver la conversation';

  @override
  String get deleteFact => 'Supprimer le fait';

  @override
  String get deleteFeedBody =>
      'Cela supprime le flux et tous ses articles en cache. Les articles mis en signet de ce flux seront également supprimés.';

  @override
  String deleteFeedConfirm(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get deletePolicy => 'Supprimer la politique';

  @override
  String get deletePolicyConfirm =>
      'Supprimer cette politique ? Cette action est irréversible.';

  @override
  String deleteTopicConfirm(String topic) {
    return 'Supprimer \"$topic\" ? Cette action est irréversible.';
  }

  @override
  String get deleteWorkspace => 'Supprimer l\'espace de travail';

  @override
  String get deny => 'Refuser';

  @override
  String get descriptionLabel => 'Description';

  @override
  String detectedBackend(String label) {
    return 'Détecté : $label';
  }

  @override
  String get detectedRunners => 'Exécuteurs détectés';

  @override
  String get detectingAdapters => 'Détection des adaptateurs…';

  @override
  String get detectingInputDevices => 'Détection des périphériques d\'entrée…';

  @override
  String detectionFailed(String error) {
    return 'Échec de la détection : $error';
  }

  @override
  String get disabled => 'Désactivé';

  @override
  String get discover => 'Découvrir';

  @override
  String get dismissed => 'Rejeté';

  @override
  String get domainHint => 'ex : api-performance';

  @override
  String get domainLabel => 'Domaine';

  @override
  String get download => 'Télécharger';

  @override
  String get downloadingLabel => 'Téléchargement';

  @override
  String downloadingModel(int pct) {
    return 'Téléchargement du modèle… $pct %';
  }

  @override
  String get draft => 'Brouillon';

  @override
  String get draftLabel => 'Brouillon';

  @override
  String get edit => 'Modifier';

  @override
  String get edited => 'modifié';

  @override
  String get editMessage => 'Modifier le message';

  @override
  String get deleteMessage => 'Supprimer le message';

  @override
  String get deleteMessageConfirm =>
      'Supprimer ce message ? Cette action est irréversible.';

  @override
  String get messageDeleted => 'Message supprimé';

  @override
  String get searchInConversation => 'Rechercher dans la conversation';

  @override
  String get searchMessagesHint => 'Rechercher des messages…';

  @override
  String get noMessagesFound => 'Aucun message trouvé';

  @override
  String get editFact => 'Modifier le fait';

  @override
  String get editPolicy => 'Modifier la politique';

  @override
  String get editSuggestedCodeHint => 'Modifier le code suggéré...';

  @override
  String get editSuggestion => 'Modifier la suggestion';

  @override
  String get egArchitect => 'ex. architecte';

  @override
  String get egControlCenter => 'ex : control-center';

  @override
  String get egPlatform => 'ex : macOS';

  @override
  String get egSamuelAlev => 'ex : SamuelAlev';

  @override
  String get egSoftwareArchitect => 'ex. Architecte logiciel';

  @override
  String get egTheVerge => 'ex. The Verge';

  @override
  String get egTokenLimit => 'ex : 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Échec de l\'installation : $error';
  }

  @override
  String get embeddingInstalled =>
      'Modèle d\'embedding local installé. La recherche hybride est activée.';

  @override
  String get embeddingModel => 'Modèle d\'embedding (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Non installé. La recherche revient au mode mots-clés uniquement jusqu\'à l\'activation.';

  @override
  String get embeddingRedownloadBody =>
      'Les fichiers du modèle existant seront supprimés et téléchargés à nouveau. La recherche sémantique sera indisponible jusqu\'à la fin du téléchargement.';

  @override
  String get embeddingRemoveBody =>
      'La recherche sémantique sera désactivée jusqu\'à ce que vous la réinstalliez. Vous pouvez l\'installer à nouveau à tout moment.';

  @override
  String get speakerDiarization => 'Diarisation des locuteurs';

  @override
  String get diarizationModel => 'Modèle de diarisation';

  @override
  String get diarizationInstalled =>
      'Installé — nomme chaque locuteur dans les transcriptions de réunions';

  @override
  String get diarizationNotInstalled =>
      'Non installé — les locuteurs des réunions ne seront pas séparés';

  @override
  String diarizationInstallFailed(String error) {
    return 'Échec de l\'installation : $error';
  }

  @override
  String get redownloadDiarizationModel =>
      'Re-télécharger le modèle de diarisation';

  @override
  String get diarizationRedownloadBody =>
      'Cela supprime les modèles de diarisation actuels et les télécharge à nouveau.';

  @override
  String get removeDiarizationModel => 'Supprimer le modèle de diarisation';

  @override
  String get diarizationRemoveBody =>
      'Cela supprime les modèles de diarisation sur l\'appareil. Les transcriptions de réunions déjà produites ne sont pas affectées.';

  @override
  String get enableNotifications => 'Activer les notifications';

  @override
  String get enableSandboxing => 'Activer le bac à sable';

  @override
  String get enabled => 'Activé';

  @override
  String errorCreatingAgent(String error) {
    return 'Erreur lors de la création de l\'agent : $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Erreur lors de la suppression de l\'agent : $error';
  }

  @override
  String errorWithDetail(String error) {
    return 'Erreur : $error';
  }

  @override
  String get expand => 'Développer';

  @override
  String extractingModel(int pct) {
    return 'Extraction du modèle… $pct %';
  }

  @override
  String get fact => 'Fait';

  @override
  String factCount(int count) {
    return '$count fait';
  }

  @override
  String factCountPlural(int count) {
    return '$count faits';
  }

  @override
  String get facts => 'Faits';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount faits · $policyCount politiques';
  }

  @override
  String get failed => 'Échoué';

  @override
  String failedToDispatch(String error) {
    return 'Échec de l\'envoi : $error';
  }

  @override
  String get failedToLoad => 'Échec du chargement';

  @override
  String failedToLoadAgents(String error) {
    return 'Échec du chargement des agents : $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Échec du chargement des flux : $error';
  }

  @override
  String get failedToLoadGifs => 'Échec du chargement des GIFs';

  @override
  String failedToLoadLogs(String error) {
    return 'Échec du chargement des journaux : $error';
  }

  @override
  String get failedToLoadRepos => 'Échec du chargement des dépôts';

  @override
  String get failedToLoadWorkspaces =>
      'Échec du chargement des espaces de travail';

  @override
  String failedToStartAiReview(String error) {
    return 'Échec du démarrage de la revue IA : $error';
  }

  @override
  String get failedToStartMicTest =>
      'Échec du démarrage du test du microphone.';

  @override
  String failedToSubmitReview(String error) {
    return 'Échec de la soumission de la revue : $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'Échec du téléversement de $name : $error';
  }

  @override
  String failedWithError(String error) {
    return 'Échec : $error';
  }

  @override
  String get failure => 'Échec';

  @override
  String get feedAlreadyExists => 'Un flux avec cette URL existe déjà.';

  @override
  String get feedUrlExample => 'ex : https://example.com/feed.xml';

  @override
  String get feedUrlLabel => 'URL du flux';

  @override
  String feedsCount(int count) {
    return 'Flux ($count)';
  }

  @override
  String get filesChanged => 'Fichiers modifiés';

  @override
  String filesCount(int count) {
    return '$count fichier(s)';
  }

  @override
  String get filesMentionSection => 'Fichiers';

  @override
  String get filterAgents => 'Filtrer les agents...';

  @override
  String get filterFilesHint => 'Filtrer les fichiers...';

  @override
  String get filterLists => 'Listes de filtrage';

  @override
  String get filterSkillsPlaceholder => 'Filtrer les compétences…';

  @override
  String get finish => 'Terminer';

  @override
  String get fix => 'Corriger';

  @override
  String get forward => 'Transférer';

  @override
  String get gatesGithubPatPush =>
      'Contrôle l\'injection du PAT GitHub. Requis pour que l\'agent puisse pousser.';

  @override
  String get general => 'Général';

  @override
  String get githubLink => 'Lien GitHub';

  @override
  String get claudeStatusFetchFailed =>
      'Impossible de joindre status.claude.com';

  @override
  String get claudeStatusOpenInBrowser => 'Ouvrir status.claude.com';

  @override
  String get githubStatusFetchFailed =>
      'Impossible de joindre githubstatus.com';

  @override
  String get githubDegradedTitle => 'GitHub signale des problèmes';

  @override
  String githubDegradedStatusLine(String status) {
    return 'État de GitHub : $status.';
  }

  @override
  String githubDegradedBody(String status) {
    return 'État de GitHub : $status. Les données des pull requests peuvent être obsolètes ou incomplètes jusqu\'au rétablissement.';
  }

  @override
  String get githubStatusOpenInBrowser => 'Ouvrir githubstatus.com';

  @override
  String get githubStatusRefresh => 'Actualiser';

  @override
  String githubStatusUpdated(String time) {
    return 'Mis à jour $time';
  }

  @override
  String get kimiStatusFetchFailed =>
      'Impossible de joindre status.moonshot.cn';

  @override
  String get kimiStatusOpenInBrowser => 'Ouvrir status.moonshot.cn';

  @override
  String get openaiStatusFetchFailed =>
      'Impossible de joindre status.openai.com';

  @override
  String get openaiStatusOpenInBrowser => 'Ouvrir status.openai.com';

  @override
  String get serviceStatusMaintenance => 'Maintenance';

  @override
  String get serviceStatusMajorIssues => 'Problèmes majeurs';

  @override
  String get serviceStatusMinorIssues => 'Problèmes mineurs';

  @override
  String get serviceStatusOperational => 'Opérationnel';

  @override
  String get serviceStatusOutage => 'Panne';

  @override
  String get serviceStatusTitle => 'État des services';

  @override
  String get serviceStatusUnknown => 'Inconnu';

  @override
  String lastChecked(String time) {
    return 'Vérifié $time';
  }

  @override
  String get lastCheckedRecently => 'Vérifié récemment';

  @override
  String get giveYourWorkAHome => 'Donnez un foyer à votre travail.';

  @override
  String get goBack => 'Retourner en arrière';

  @override
  String get goForward => 'Avancer';

  @override
  String get googleFonts => 'Google Fonts';

  @override
  String get high => 'Élevé';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count heures',
      one: 'il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String get images => 'Images';

  @override
  String get inactive => 'Inactif';

  @override
  String get install => 'Installer';

  @override
  String get installRequired => 'Installation requise';

  @override
  String installedVersion(String version) {
    return 'Installé $version';
  }

  @override
  String get invite => 'Inviter';

  @override
  String get inviteAgent => 'Inviter un agent';

  @override
  String get isolateAgentExecution => 'Isoler l\'exécution des agents.';

  @override
  String get justNow => 'à l\'instant';

  @override
  String get keepSandboxing => 'Conserver le bac à sable';

  @override
  String get keybindingAddARepositoryDescription => 'Ajouter un dépôt';

  @override
  String get keybindingAddRepository => 'Ajouter un dépôt';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Signet ou supprimer le signet de l\'article sélectionné';

  @override
  String get keybindingCommandPalette => 'Palette de commandes';

  @override
  String get keybindingCreateANewAgentDescription => 'Créer un nouvel agent';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Créer un nouvel espace de travail';

  @override
  String get keybindingFocusSearch => 'Aller à la recherche';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Activer le champ de recherche des pull requests';

  @override
  String get keybindingNewAgent => 'Nouvel agent';

  @override
  String get keybindingNewWorkspace => 'Nouvel espace de travail';

  @override
  String get keybindingNextArticle => 'Article suivant';

  @override
  String get keybindingNextSpace => 'Espace suivant';

  @override
  String get keybindingNextWorkspace => 'Espace de travail suivant';

  @override
  String get keybindingOpenArticle => 'Ouvrir l\'article';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Ouvrir ou fermer le popup du sélecteur d\'espace dans la barre latérale';

  @override
  String get keybindingOpenPr => 'Ouvrir la PR';

  @override
  String get keybindingOpenSettings => 'Ouvrir les paramètres';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Ouvrir les paramètres de l\'application';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Ouvrir la palette de commandes';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Ouvrir l\'article sélectionné';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Ouvrir la demande de tirage sélectionnée';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Ouvrir l\'espace de travail sélectionné';

  @override
  String get keybindingOpenWorkspace => 'Ouvrir l\'espace de travail';

  @override
  String get keybindingPreviousArticle => 'Article précédent';

  @override
  String get keybindingPreviousSpace => 'Espace précédent';

  @override
  String get keybindingPreviousWorkspace => 'Espace de travail précédent';

  @override
  String get keybindingRefresh => 'Actualiser';

  @override
  String get keybindingRefreshAllFeedsDescription => 'Actualiser tous les flux';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Actualiser la liste des demandes de tirage';

  @override
  String get keybindingRescanForAdaptersDescription =>
      'Rescanner les adaptateurs';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Sélectionner l\'article suivant';

  @override
  String get keybindingSelectTheNextSpaceDescription =>
      'Sélectionner le espace suivant';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Sélectionner l\'article précédent';

  @override
  String get keybindingSelectThePreviousSpaceDescription =>
      'Sélectionner le espace précédent';

  @override
  String get keybindingSendMessage => 'Envoyer le message';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Envoyer le message actuel';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Basculer entre le mode clair et sombre';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Passer au huitième espace de travail';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Passer au cinquième espace de travail';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Passer au premier espace de travail';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Passer au quatrième espace de travail';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Passer à l\'espace de travail suivant';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Passer au neuvième espace de travail';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Passer à l\'espace de travail précédent';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Passer au deuxième espace de travail';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Passer au septième espace de travail';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Passer au sixième espace de travail';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Passer au troisième espace de travail';

  @override
  String get keybindingToggleBookmark => 'Basculer le signet';

  @override
  String get keybindingToggleTheme => 'Basculer le thème';

  @override
  String get keybindingToggleWorkspaceSwitcher =>
      'Basculer le sélecteur d\'espace';

  @override
  String get keybindingWorkspace1 => 'Workspace1';

  @override
  String get keybindingWorkspace2 => 'Workspace2';

  @override
  String get keybindingWorkspace3 => 'Workspace3';

  @override
  String get keybindingWorkspace4 => 'Workspace4';

  @override
  String get keybindingWorkspace5 => 'Workspace5';

  @override
  String get keybindingWorkspace6 => 'Workspace6';

  @override
  String get keybindingWorkspace7 => 'Workspace7';

  @override
  String get keybindingWorkspace8 => 'Workspace8';

  @override
  String get keybindingWorkspace9 => 'Workspace9';

  @override
  String get keybindings => 'Raccourcis clavier';

  @override
  String get keybindingsDescription =>
      'Tous les raccourcis clavier. Les raccourcis sont fixes et ne peuvent pas être réassignés.';

  @override
  String get killRunning => 'Arrêter l\'exécution';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageSystem => 'Système';

  @override
  String get leaveACommentEllipsis => 'Laisser un commentaire...';

  @override
  String get legendLabel => 'Légende';

  @override
  String get lessLabel => 'Moins';

  @override
  String get letsPluginTools => 'Connectons vos outils.';

  @override
  String get level => 'Niveau';

  @override
  String get loadingAgents => 'Chargement des agents…';

  @override
  String get loadingModels => 'Chargement des modèles…';

  @override
  String get loadingProviders => 'Chargement des fournisseurs…';

  @override
  String get logLevel => 'Niveau de journalisation';

  @override
  String get logs => 'Journaux';

  @override
  String get low => 'Faible';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get manageParticipants => 'Gérer les participants';

  @override
  String get manageWorkspaces => 'Gérer les espaces de travail';

  @override
  String get reorderWorkspace => 'Réordonner l\'espace de travail';

  @override
  String get matchOsAppearance =>
      'Adapter l\'apparence au système d\'exploitation ou choisir un mode fixe.';

  @override
  String get mcpAuthToken => 'Jeton d\'authentification MCP';

  @override
  String get mcpNotAvailableOnServer =>
      'Le contrôle du serveur MCP n\'est pas disponible sur le serveur connecté.';

  @override
  String get modelManagedOnServer =>
      'Ce modèle s\'exécute sur l\'hôte du serveur et y est géré.';

  @override
  String get mcpServer => 'Serveur MCP';

  @override
  String get medium => 'Moyen';

  @override
  String get memoryDataHint =>
      'Les faits et les politiques apparaîtront ici au fur et à mesure que les agents travaillent.';

  @override
  String get memoryLabel => 'Mémoire';

  @override
  String get merge => 'Merge';

  @override
  String get merged => 'Fusionné';

  @override
  String get messagePlaceholder =>
      'Message… (@ pour mentionner, / pour les commandes)';

  @override
  String get navConversations => 'Espaces';

  @override
  String get microphonePermissionDenied =>
      'Autorisation du microphone refusée.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count minutes',
      one: 'il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Modèle';

  @override
  String get modified => 'Modifié';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count mois',
      one: 'il y a 1 mois',
    );
    return '$_temp0';
  }

  @override
  String get moreLabel => 'Plus';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Nom';

  @override
  String get nameAndTitleRequired => 'Le nom et le titre sont requis.';

  @override
  String get nameAndUrlRequired => 'Le nom et l\'URL sont requis';

  @override
  String get nameLabel => 'Nom';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Sandbox natif disponible sur $platform.';
  }

  @override
  String get nativeSandboxNeedsInstall =>
      'Installation nécessaire pour le sandbox natif';

  @override
  String get navObservability => 'Observabilité';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get navigateLabel => 'Naviguer';

  @override
  String networkBlockCount(int count) {
    return '$count blocages réseau';
  }

  @override
  String get neutral => 'Neutre';

  @override
  String get newCommitsPushed =>
      'De nouveaux commits ont été poussés — cliquez pour recharger le diff';

  @override
  String get newFact => 'Nouveau fait';

  @override
  String get newLabel => 'Nouveau';

  @override
  String get newPolicy => 'Nouvelle politique';

  @override
  String get newsfeed => 'Fil d\'actualités';

  @override
  String get newsfeedLabel => 'Fil d\'actualités';

  @override
  String get newsfeedSettingsDescription =>
      'Gérez vos flux abonnés et vos préférences de lecteur.';

  @override
  String get newsfeedSettingsTitle => 'Paramètres du fil d\'actualités';

  @override
  String get nextMatch => 'Correspondance suivante (↵)';

  @override
  String get noActiveWorkspace =>
      'Aucun espace de travail ou dépôt actif sélectionné.';

  @override
  String get noActiveWorkspaceCreate => 'Aucun espace de travail actif';

  @override
  String get noActiveWorkspaceGithub =>
      'Aucun espace de travail actif avec un dépôt GitHub.';

  @override
  String get noAgents => 'Aucun agent';

  @override
  String get noArticlesYet => 'Aucun article pour l\'instant';

  @override
  String get noArticlesYetBody => 'Les articles de vos flux apparaîtront ici.';

  @override
  String get noExecutionLogsYet => 'Aucun journal d\'exécution pour l\'instant';

  @override
  String get noFacts => 'Aucun fait pour l\'instant';

  @override
  String get noFeedsYet => 'Aucun flux pour l\'instant';

  @override
  String get noFileAnchor =>
      'Aucune ancre de fichier — impossible de publier un commentaire en ligne.';

  @override
  String get noFileChangesInScope =>
      'Aucune modification de fichier dans cette portée';

  @override
  String get noGifsFound => 'Aucun GIF trouvé';

  @override
  String get noInputDevicesDetected =>
      'Aucun périphérique d\'entrée détecté — utilisation de la valeur par défaut du système.';

  @override
  String get noMatchingFiles => 'Aucun fichier correspondant';

  @override
  String get noMatchingGoogleFonts =>
      'Aucune correspondance dans Google Fonts.';

  @override
  String get noMemoryData => 'Aucune donnée de mémoire pour l\'instant';

  @override
  String get noMessagesYet => 'Aucun message pour l\'instant';

  @override
  String get noModelsAdvertised => 'Aucun modèle annoncé par cet adaptateur.';

  @override
  String get noOpenPullRequests => 'Aucune pull request ouverte';

  @override
  String get noPolicies => 'Aucune politique pour l\'instant';

  @override
  String get noReposInWorkspaceYet =>
      'Aucun dépôt dans cet espace de travail pour l\'instant';

  @override
  String get noRunnersDetected =>
      'Aucun exécuteur détecté pour l\'instant. Actualisez pour scanner à nouveau.';

  @override
  String get noSavedArticles => 'Aucun article enregistré';

  @override
  String get noSavedArticlesBody =>
      'Les articles que vous enregistrez apparaîtront ici.';

  @override
  String noShortcutsMatch(String query) {
    return 'Aucun raccourci ne correspond à « $query »';
  }

  @override
  String get noSystemFonts => 'Aucune police système détectée.';

  @override
  String get noTokenSet => 'Aucun jeton défini — l\'accès est illimité.';

  @override
  String get noWorkingMemory =>
      'Aucune note de mémoire de travail pour l\'instant.';

  @override
  String get noneAllRoles => 'Aucun (tous les rôles)';

  @override
  String get notAvailable => 'Non disponible';

  @override
  String get notConfiguredLabel => 'Non configuré.';

  @override
  String get notDetected => 'Non détecté';

  @override
  String get notFoundLabel => 'Non trouvé';

  @override
  String get notes => 'Notes';

  @override
  String get notificationAgentFinished => 'Agent terminé';

  @override
  String get notificationPrMentioned => 'Mentionné dans une pull request';

  @override
  String get notificationNewMessages => 'Nouveaux messages';

  @override
  String get notificationPrMerged => 'PR fusionnée';

  @override
  String get notificationPrPublished => 'PR publiée';

  @override
  String get notificationReviewRequested => 'Revue demandée';

  @override
  String get notifications => 'Notifications';

  @override
  String get notifyAgentRunCompleted =>
      'Notifier lorsqu\'un agent termine une exécution.';

  @override
  String get notifyPrMentioned =>
      'Notifier lorsque vous êtes mentionné dans une pull request.';

  @override
  String get notifyNewMessages =>
      'Notifier pour les nouveaux messages d\'agent dans d\'autres espaces.';

  @override
  String get notifyPrMerged =>
      'Notifier lorsqu\'une demande de tirage est fusionnée.';

  @override
  String get notifyPrPublished =>
      'Notifier lorsqu\'un agent publie une demande de tirage.';

  @override
  String get notifyReviewRequested =>
      'Notifier lorsqu\'une revue vous est demandée sur une pull request.';

  @override
  String get notificationReviewStale => 'Revue obsolète';

  @override
  String get notifyReviewStale =>
      'Quand de nouveaux commits arrivent sur une pull request déjà relue';

  @override
  String get notificationPrMergeReadiness => 'Prêt à fusionner';

  @override
  String get notifyPrMergeReadiness =>
      'Notifier quand une pull request que vous avez créée devient fusionnable, ou cesse de l\'être.';

  @override
  String get notificationPrReviewDecision => 'Décisions de revue';

  @override
  String get notifyPrReviewDecision =>
      'Notifier quand un relecteur approuve, demande des modifications ou voit une approbation rejetée.';

  @override
  String get notificationPrChecksStatus => 'Vérifications';

  @override
  String get notifyPrChecksStatus =>
      'Notifier quand la CI échoue sur une de vos pull requests, et quand elle repasse au vert.';

  @override
  String get notificationPrThreadActivity => 'Fils de revue';

  @override
  String get notifyPrThreadActivity =>
      'Notifier quand quelqu\'un répond dans un fil où vous êtes, ou le résout.';

  @override
  String get notificationPrReadyToMerge => 'Prêt à fusionner';

  @override
  String notificationPrReadyToMergeBody(String prTitle) {
    return '$prTitle remplit toutes les conditions.';
  }

  @override
  String get notificationPrMergeBlocked => 'Plus fusionnable';

  @override
  String notificationPrMergeBlockedBodyConflicts(String prTitle) {
    return '$prTitle est en conflit avec la branche de base.';
  }

  @override
  String notificationPrMergeBlockedBodyBehind(String prTitle) {
    return '$prTitle est en retard sur la branche de base.';
  }

  @override
  String notificationPrMergeBlockedBodyReviews(String prTitle) {
    return '$prTitle attend une revue obligatoire.';
  }

  @override
  String notificationPrMergeBlockedBodyChanges(String prTitle) {
    return 'Un relecteur a demandé des modifications sur $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyChecks(String prTitle) {
    return 'Les vérifications échouent sur $prTitle.';
  }

  @override
  String notificationPrMergeBlockedBodyOther(String prTitle) {
    return '$prTitle ne peut plus être fusionnée.';
  }

  @override
  String get notificationPrApproved => 'Pull request approuvée';

  @override
  String notificationPrApprovedBodyBy(String login, String prTitle) {
    return '$login a approuvé $prTitle';
  }

  @override
  String notificationPrApprovedBody(String prTitle) {
    return '$prTitle a été approuvée';
  }

  @override
  String notificationPrReviewersRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count relecteurs doivent encore répondre',
      one: '1 relecteur doit encore répondre',
      zero: 'plus aucun relecteur',
    );
    return '$_temp0';
  }

  @override
  String get notificationPrChangesRequested => 'Modifications demandées';

  @override
  String notificationPrChangesRequestedBodyBy(String login, String prTitle) {
    return '$login a demandé des modifications sur $prTitle';
  }

  @override
  String notificationPrChangesRequestedBody(String prTitle) {
    return 'Des modifications ont été demandées sur $prTitle';
  }

  @override
  String get notificationPrReviewDismissed => 'Approbation rejetée';

  @override
  String notificationPrReviewDismissedBody(String prTitle) {
    return '$prTitle doit être relue à nouveau.';
  }

  @override
  String get notificationPrChecksFailed => 'Vérifications en échec';

  @override
  String notificationPrChecksFailedBody(String checkName, String prTitle) {
    return '$checkName a échoué sur $prTitle';
  }

  @override
  String notificationPrChecksFailedBodyUnnamed(String prTitle) {
    return 'Les vérifications échouent sur $prTitle';
  }

  @override
  String get notificationPrChecksRecovered => 'Vérifications au vert';

  @override
  String notificationPrChecksRecoveredBody(String prTitle) {
    return '$prTitle est de nouveau au vert.';
  }

  @override
  String notificationPrMentionedInCommentBody(String login, String location) {
    return '$login vous a mentionné dans $location';
  }

  @override
  String get notificationPrThreadReplied => 'Nouvelle réponse';

  @override
  String notificationPrThreadRepliedBody(String login, String location) {
    return '$login a répondu dans $location';
  }

  @override
  String get notificationPrThreadResolved => 'Fil résolu';

  @override
  String notificationPrThreadResolvedBody(String location) {
    return 'Votre fil dans $location a été résolu.';
  }

  @override
  String get notificationGroupAgents => 'Agents';

  @override
  String get notificationGroupPullRequests => 'Pull requests';

  @override
  String get notificationGroupMessages => 'Messages';

  @override
  String get notificationGroupTickets => 'Tickets';

  @override
  String get notificationGroupCalendar => 'Agenda';

  @override
  String get notificationGroupMachines => 'Machines';

  @override
  String get notificationsMutedRepos => 'Dépôts en sourdine';

  @override
  String notificationsMutedReposCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dépôts en sourdine',
      one: '1 dépôt en sourdine',
      zero: 'Aucun dépôt en sourdine',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMuteRepo => 'Mettre ce dépôt en sourdine';

  @override
  String get notificationsUnmuteRepo => 'Réactiver ce dépôt';

  @override
  String get onboardingLinuxDescription =>
      'Control Center peut utiliser des conteneurs Linux pour isoler l\'exécution des agents.';

  @override
  String get onboardingMacosDescription =>
      'Control Center utilise le sandbox natif sur macOS pour isoler l\'exécution des agents.';

  @override
  String get onboardingUnsupportedDescription =>
      'Sandbox non disponible sur cette plateforme. L\'exécution des agents se fera sans isolation.';

  @override
  String get openApplicationSettings =>
      'Ouvrir les paramètres de l\'application';

  @override
  String get openArticlesInApp => 'Ouvrir les articles dans l\'application';

  @override
  String get openInBrowser => 'Ouvrir dans le navigateur';

  @override
  String get openLabel => 'Ouvert';

  @override
  String get openOnGithub => 'Ouvrir sur GitHub';

  @override
  String get openStatus => 'Ouvert';

  @override
  String get optionalPersonaDescription =>
      'Description de personnalité optionnelle';

  @override
  String get otherLabel => 'Autre';

  @override
  String get ownerOrganization => 'Propriétaire / Organisation';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get passed => 'Réussi';

  @override
  String get pasteValueHere => 'Coller la valeur ici';

  @override
  String get persona => 'Persona';

  @override
  String get policies => 'Politiques';

  @override
  String get policiesHint =>
      'Les politiques apparaîtront ici une fois que les agents auront promu des faits.';

  @override
  String get policy => 'Politique';

  @override
  String get popular => 'Populaire';

  @override
  String get port => 'Port';

  @override
  String get postingEllipsis => 'Publication...';

  @override
  String get prCommits => 'Commits';

  @override
  String get prMergedBody => 'Une demande de tirage a été fusionnée';

  @override
  String get prMoreActions => 'More actions';

  @override
  String get prTitle => 'Titre de la PR';

  @override
  String get reviewCommentHint =>
      'Cliquez simplement sur approuver, ou si vous vous sentez d\'humeur, ajoutez un commentaire ou une réaction…';

  @override
  String get nothingToPreview => 'Rien à prévisualiser';

  @override
  String get previousMatch => 'Correspondance précédente (⇧↵)';

  @override
  String get priorityReviewsDescription =>
      'Revues prioritaires et aperçu du dépôt.';

  @override
  String get prsCreated => 'PRs créées';

  @override
  String get prsMerged => 'PRs fusionnées';

  @override
  String get publishToGithub => 'Publier sur GitHub';

  @override
  String get published => 'Publié';

  @override
  String get pullRequestApproved => 'Demande de tirage approuvée';

  @override
  String get pullRequests => 'Demandes de tirage';

  @override
  String get questionLabel => 'QUESTION';

  @override
  String get queued => 'En file d\'attente';

  @override
  String get react => 'Réagir';

  @override
  String get readPrsIssuesMetadata =>
      'Permet à l\'agent de lire les PR, les incidents et les métadonnées du dépôt.';

  @override
  String get readerPreferences => 'Préférences du lecteur';

  @override
  String get reasoningEffort => 'Effort de raisonnement';

  @override
  String get recommendLabel => 'RECOMMANDATION';

  @override
  String recordingFromDevice(String device) {
    return 'Enregistrement depuis $device.';
  }

  @override
  String get redownload => 'Retélécharger';

  @override
  String get redownloadEmbeddingModel =>
      'Télécharger à nouveau le modèle d\'intégration ?';

  @override
  String get redownloadVoiceModel => 'Télécharger à nouveau le modèle vocal ?';

  @override
  String get refinePlan => 'Affiner le plan';

  @override
  String get refresh => 'Actualiser';

  @override
  String get refreshAll => 'Tout actualiser';

  @override
  String get refreshAllFeeds => 'Actualiser tous les flux';

  @override
  String get reject => 'Rejeter';

  @override
  String get rejected => 'Rejeté';

  @override
  String get reload => 'Recharger';

  @override
  String get remove => 'Retirer';

  @override
  String get removeBookmark => 'Retirer le signet';

  @override
  String get removeEmbeddingModel => 'Supprimer le modèle d\'intégration ?';

  @override
  String get removeLogo => 'Supprimer le logo';

  @override
  String get removeRepoFromWorkspace =>
      'Retirer le dépôt de l\'espace de travail ?';

  @override
  String get removeVoiceModel => 'Supprimer le modèle vocal ?';

  @override
  String get removed => 'Supprimé';

  @override
  String get renamed => 'Renommé';

  @override
  String get reopen => 'Rouvrir';

  @override
  String get resolve => 'Résoudre';

  @override
  String get replyEllipsis => 'Répondre…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name sera retiré de cet espace de travail. Les fichiers locaux sur le disque ne sont pas modifiés.';
  }

  @override
  String repoAccessNoticeBody(String repos) {
    return 'Les identifiants GitHub du serveur ne peuvent pas voir $repos. Si un dépôt appartient à une organisation, installez-y la GitHub App ou connectez un jeton qui y a accès.';
  }

  @override
  String repoAccessNoticeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dépôts ne sont pas accessibles',
      one: 'Un dépôt n\'est pas accessible',
    );
    return '$_temp0';
  }

  @override
  String get repoNoAccessBadge => 'Pas d\'accès';

  @override
  String get reportsTo => 'Rapporte à';

  @override
  String reposCount(int count) {
    return 'Dépôts ($count)';
  }

  @override
  String get reposDescription =>
      'Les checkouts locaux ciblés par cet espace de travail.';

  @override
  String get repositories => 'Dépôts';

  @override
  String repositoriesAddFailed(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dépôts',
      one: '1 dépôt',
    );
    return 'Impossible d\'ajouter $_temp0 : $error';
  }

  @override
  String repositoriesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dépôts ajoutés',
      one: 'Dépôt ajouté',
    );
    return '$_temp0';
  }

  @override
  String get repositoriesSettings => 'Paramètres des dépôts';

  @override
  String get repositoryName => 'Nom du dépôt';

  @override
  String get requestChanges => 'Demander des modifications';

  @override
  String get requested => 'Demandé';

  @override
  String get requestedChanges => 'Modifications demandées';

  @override
  String requiredRoleLabel(String role) {
    return 'Rôle requis : $role';
  }

  @override
  String get requiredRoleOptional => 'Rôle requis (facultatif)';

  @override
  String get requirements => 'Exigences';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get resolved => 'Résolu';

  @override
  String get enclosedTerminalTitle => 'Terminal isolé';

  @override
  String get enclosedTerminalStart => 'Ouvrir le shell';

  @override
  String get enclosedTerminalStartHint =>
      'Ce shell s’exécute dans la VM jetable de cette conversation. Elle démarre quand vous l’ouvrez, pas au lancement de l’application.';

  @override
  String get terminalStreamReconnecting => 'flux interrompu — reconnexion…';

  @override
  String get terminalStreamError => 'erreur de flux :';

  @override
  String get terminalShellExited => 'shell terminé';

  @override
  String get restartShell => 'Redémarrer le shell';

  @override
  String get retry => 'Réessayer';

  @override
  String get review => 'Revue';

  @override
  String get reviewedByMe => 'Revues par moi';

  @override
  String get reviewers => 'RELECTEURS';

  @override
  String get roleLabel => 'Rôle';

  @override
  String get ruleHint => 'La règle de la politique (markdown pris en charge)';

  @override
  String get ruleLabel => 'Règle';

  @override
  String get runCompleted => 'Exécution terminée';

  @override
  String get running => 'En cours';

  @override
  String get runningLabel => 'en cours';

  @override
  String get runs => 'Exécutions';

  @override
  String get runsLabel => 'Exécutions';

  @override
  String get sandboxBackendNativeLabel => 'Native sandbox';

  @override
  String get sandboxBackendMicrovmLabel => 'VM cloisonnée';

  @override
  String get sandboxBackendNoneLabel => 'No isolation';

  @override
  String get sandboxLinuxInstall =>
      'Le sandbox natif sur Linux/WSL2 utilise bubblewrap. Installez avec :\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'Le sandbox natif est intégré à macOS — utilise Apple Seatbelt (`sandbox-exec`). Aucune installation requise.';

  @override
  String get sandboxPermissions => 'Permissions du sandbox';

  @override
  String get sandboxUnsupported =>
      'Le sandbox natif n\'est pas encore pris en charge sur cette plateforme. Revient à \"Pas d\'isolation\".';

  @override
  String get sandboxingDisabledDescription =>
      'Les agents s\'exécutent directement sur l\'hôte avec un environnement complet — non recommandé.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Toutes les invocations d\'agents sont acheminées via $backend.';
  }

  @override
  String get save => 'Enregistrer';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get adapterArguments => 'Arguments supplémentaires';

  @override
  String get adapterArgumentsHint =>
      'Indicateurs CLI supplémentaires (ex. --yolo)';

  @override
  String get addVariable => 'Ajouter une variable';

  @override
  String get environmentVariables => 'Variables d\'environnement';

  @override
  String get environmentVariablesDescription =>
      'Variables d\'environnement personnalisées passées à cet adaptateur (ex. clés API). Stockées dans le trousseau.';

  @override
  String get variableKey => 'Clé';

  @override
  String get variableValue => 'Valeur';

  @override
  String get savingChanges => 'Enregistrement des modifications...';

  @override
  String get savingEllipsis => 'Enregistrement…';

  @override
  String get scopeDiffToCommits =>
      'Limiter le diff aux commits — Shift+clic pour une plage';

  @override
  String get noPrsMatchSearch => 'Aucune pull request correspondante';

  @override
  String get noPrsMatchSearchHint =>
      'Aucune PR ouverte ne correspond à votre recherche. Essayez d\'autres termes ou effacez la recherche.';

  @override
  String get searchFactsHint => 'Rechercher des faits...';

  @override
  String get searchFonts => 'Rechercher des polices…';

  @override
  String get searchGifs => 'Rechercher des GIFs';

  @override
  String get searchGifsHint => 'Rechercher des GIFs...';

  @override
  String get searchInDiffHint => 'Rechercher dans le diff...';

  @override
  String get searchOrTypeModel => 'Rechercher ou saisir un nom de modèle…';

  @override
  String get searchPlaceholder => 'Rechercher...';

  @override
  String get searchShortcuts => 'Rechercher des raccourcis…';

  @override
  String get shortcutUnavailableInBrowser => 'Indisponible dans le navigateur';

  @override
  String get searching => 'Recherche en cours...';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count secondes',
      one: 'il y a 1 seconde',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Sélectionner un adaptateur';

  @override
  String get selectAdapterFirst => 'Sélectionnez d\'abord un adaptateur';

  @override
  String get selectAgentToReportTo => 'Sélectionner l\'agent auquel rapporter…';

  @override
  String get selectAnAgent => 'Sélectionner un agent';

  @override
  String get selectConversation => 'Sélectionner une conversation';

  @override
  String get selectEffortLevel => 'Sélectionner le niveau d\'effort';

  @override
  String get selectLabel => 'Sélectionner';

  @override
  String get selectRunner => 'Sélectionner un exécuteur';

  @override
  String get semanticSearch => 'Recherche sémantique';

  @override
  String get send => 'Envoyer';

  @override
  String get sendFirstMessage => 'Envoyer le premier message';

  @override
  String get sendMessage => 'Envoyer un message';

  @override
  String sentFindingsToAgent(int count) {
    return '$count résultat(s) envoyé(s) à l\'agent.';
  }

  @override
  String setGithubLinkDescription(String name) {
    return 'Définissez le propriétaire GitHub et le nom du dépôt pour $name. Cela est utilisé pour résoudre les références de PR et d\'issues comme #123 dans le contenu markdown.';
  }

  @override
  String get setLabel => 'Définir';

  @override
  String get setToken => 'Définir le jeton';

  @override
  String get settingsLabel => 'Paramètres';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageDescription =>
      'Choisir la langue de l\'application.';

  @override
  String get shortTask => 'Tâche courte';

  @override
  String get showNativeNotifications =>
      'Afficher les notifications macOS natives pour les événements.';

  @override
  String get showSuperseded => 'Afficher remplacés';

  @override
  String get signedIn => 'Connecté.';

  @override
  String signedInAs(String username) {
    return 'Connecté en tant que $username.';
  }

  @override
  String get skillEditor => 'Éditeur de compétences';

  @override
  String get skillNameRequired => 'Le nom de la compétence est requis.';

  @override
  String skillSaved(String name) {
    return 'Compétence « $name » enregistrée.';
  }

  @override
  String get skillsSourcesTab => 'Sources';

  @override
  String get skillSourcesDisclaimer =>
      'Les skills sont installés depuis des dépôts GitHub que vous ajoutez. Les métadonnées du dépôt ne sont pas fiables — le scan antivirus est le véritable signal de sécurité.';

  @override
  String get skillSourcesEmpty => 'Aucun dépôt de skills';

  @override
  String get skillSourcesEmptyHint =>
      'Ajoutez un dépôt GitHub pour parcourir ses skills.';

  @override
  String get skillSourceAdd => 'Ajouter un dépôt';

  @override
  String get skillSourceAddTitle => 'Ajouter un dépôt de skills';

  @override
  String get skillSourceAddHint => 'https://github.com/proprietaire/depot';

  @override
  String get skillSourceInvalidUrl =>
      'Saisissez une URL de dépôt GitHub (https://github.com/proprietaire/depot).';

  @override
  String skillSourceAdded(String repo) {
    return 'Dépôt $repo ajouté.';
  }

  @override
  String skillSourceAlreadyAdded(String repo) {
    return 'Le dépôt $repo est déjà ajouté.';
  }

  @override
  String skillSourceRemoved(String repo) {
    return 'Dépôt $repo supprimé.';
  }

  @override
  String get skillSourceRemove => 'Supprimer';

  @override
  String skillSourceRemoveConfirmTitle(String repo) {
    return 'Supprimer $repo ?';
  }

  @override
  String get skillSourceRemoveConfirmBody =>
      'Les skills installés restent installés. Seul le catalogue du dépôt est supprimé.';

  @override
  String get skillSourceNoSkills =>
      'Aucun skill trouvé dans ce dépôt (un skill est un répertoire contenant un SKILL.md).';

  @override
  String get skillSourceRefresh => 'Actualiser';

  @override
  String get skillSourceInstalledBadge => 'Installé';

  @override
  String get skillSourceUpdateBadge => 'Mise à jour disponible';

  @override
  String get skillSourceSlugTaken => 'Nom déjà utilisé';

  @override
  String skillSourceFilesCount(num count) {
    return '$count fichiers';
  }

  @override
  String get skillSourceReadme => 'README';

  @override
  String get skillSourceNoReadme => 'Ce skill n\'a pas de README.';

  @override
  String get skillSourceNoMatches =>
      'Aucun skill ne correspond à votre filtre.';

  @override
  String get skillUpdateAction => 'Mettre à jour';

  @override
  String get skillUninstallAction => 'Désinstaller';

  @override
  String skillUninstallConfirmTitle(String slug) {
    return 'Désinstaller « $slug » ?';
  }

  @override
  String skillUninstalled(String slug) {
    return 'Skill « $slug » désinstallé.';
  }

  @override
  String get skillFindingLine => 'ligne';

  @override
  String get skillInstallAnywayOverride =>
      'Je comprends le risque — installer quand même';

  @override
  String skillInstalled(String slug) {
    return 'Compétence « $slug » installée.';
  }

  @override
  String get skillPreviewCapabilities => 'Capacités';

  @override
  String get skillPreviewFindings => 'Constats';

  @override
  String get skillPreviewGuardedActions => 'Actions protégées';

  @override
  String get skillPreviewLlmReviewed => 'Vérifié par LLM';

  @override
  String get skillPreviewNoCapabilities => 'Aucune capacité déclarée.';

  @override
  String get skillPreviewNoFindings => 'Aucun constat.';

  @override
  String get skillPreviewScanning => 'Analyse de la compétence…';

  @override
  String get skillPreviewVerdictLabel => 'Verdict d\'analyse';

  @override
  String get skillPreviewVerdictPass => 'Réussi';

  @override
  String get skillPreviewVerdictQuarantine => 'En quarantaine';

  @override
  String get skillPreviewVerdictWarn => 'Avertissement';

  @override
  String get skillQuarantineWarning =>
      'Cette compétence a été mise en quarantaine par l\'analyseur. L\'installer exécute du code sur votre machine. Ne continuez que si vous faites confiance à la source et avez revu les constats.';

  @override
  String skillDetachedFromAgents(String agents) {
    return 'Mis en quarantaine et détaché des agents : $agents';
  }

  @override
  String get skillNotScanned => 'Non analysé';

  @override
  String get skillOriginGithub => 'GitHub';

  @override
  String get skillOriginManual => 'Manuel';

  @override
  String get skillOriginRegistry => 'Registre';

  @override
  String get skillOriginRuntimeLocal => 'Runtime local';

  @override
  String get skillRulesStale => 'Analyse obsolète';

  @override
  String get skillSaveAnywayOverride =>
      'Je comprends le risque — enregistrer quand même';

  @override
  String get skillSaveBlockedBody =>
      'Le contenu a été bloqué avant toute écriture.';

  @override
  String get skillSaveBlockedTitle => 'Enregistrement bloqué par le scan';

  @override
  String get skillScanAction => 'Analyser';

  @override
  String get skillScanAll => 'Tout analyser';

  @override
  String skillScanAllSummary(int pass, int warn, int quarantine) {
    return '$pass réussis · $warn avertissements · $quarantine mis en quarantaine';
  }

  @override
  String get skillStateDrifted => 'Modifié depuis l\'installation';

  @override
  String get skillStateUnmanaged => 'Non géré';

  @override
  String get skillSeverityBlocked => 'Bloqué';

  @override
  String get skillSeverityWarn => 'Avertissement';

  @override
  String get skillsInstalledTab => 'Installées';

  @override
  String get skills => 'Compétences';

  @override
  String get skipAcceptRisk => 'Passer — J\'accepte le risque';

  @override
  String get skipForNow => 'Passer pour l\'instant';

  @override
  String get skipSandboxing => 'Passer le bac à sable';

  @override
  String get skipSandboxingDialogContent =>
      'Êtes-vous sûr de vouloir ignorer le sandbox ? Cela permet aux agents d\'exécuter du code sur votre système sans isolation.';

  @override
  String get somethingWentWrong => 'Une erreur est survenue';

  @override
  String sourceCount(int count) {
    return '$count source';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count sources';
  }

  @override
  String get sourceFacts => 'Faits source :';

  @override
  String get splitDiff => 'Diff côte à côte';

  @override
  String get startLabel => 'Démarrer';

  @override
  String get startOnAppLaunch => 'Démarrer au lancement de l\'app';

  @override
  String get statusLabel => 'Statut';

  @override
  String get onboardingStepConnect => 'Connexion';

  @override
  String get onboardingStepWorkspace => 'Espace de travail';

  @override
  String get onboardingStepSandbox => 'Bac à sable';

  @override
  String get onboardingStepAdapter => 'Adaptateur';

  @override
  String get onboardingStepVoice => 'Voix';

  @override
  String get stop => 'Arrêter';

  @override
  String get stopped => 'Arrêté';

  @override
  String get strictIdentityCheck => 'Vérification stricte d\'identité';

  @override
  String get success => 'Succès';

  @override
  String get successLabel => 'Succès';

  @override
  String get suggestAChange => 'Suggérer une modification';

  @override
  String get suggestLabel => 'SUGGESTION';

  @override
  String get superseded => 'Remplacé';

  @override
  String get synced => 'Synchronisé';

  @override
  String get systemDefault => 'Valeur par défaut du système';

  @override
  String get systemFonts => 'Polices système';

  @override
  String get systemPrompt => 'Prompt système';

  @override
  String get systemPromptLabel => 'Prompt système';

  @override
  String get talkToControlCenter => 'Parlez à Control Center.';

  @override
  String get taskMentionSection => 'Tâche';

  @override
  String get testLabel => 'Tester';

  @override
  String get theme => 'Thème';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeSystem => 'Système';

  @override
  String get thisCannotBeUndone => 'Cette action est irréversible.';

  @override
  String get ticketLabel => 'TICKET';

  @override
  String get titleLabel => 'Titre';

  @override
  String get todayLabel => 'Aujourd\'hui';

  @override
  String get toggleTheme => 'Basculer le thème';

  @override
  String get tokenConfigured =>
      'Configuré — les clients doivent présenter ce jeton.';

  @override
  String get topic => 'Sujet';

  @override
  String get topicHint => 'ex : Tech Stack, Design System';

  @override
  String get totalRuns => 'Exécutions totales';

  @override
  String trackingParamsCount(int count) {
    return '$count paramètres de suivi';
  }

  @override
  String get typeCommandOrSearch => 'Tapez une commande ou recherchez…';

  @override
  String get typography => 'Typographie';

  @override
  String get unavailable => 'Indisponible';

  @override
  String get unifiedDiff => 'Diff unifié';

  @override
  String get unknownAuthor => 'Inconnu';

  @override
  String get unnamedAgent => 'Agent sans nom';

  @override
  String get updateKey => 'Mettre à jour la clé';

  @override
  String get updateLabel => 'Mettre à jour';

  @override
  String get updateToken => 'Mettre à jour le jeton';

  @override
  String updatedDaysAgo(int count) {
    return 'Mis à jour il y a $count j';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'Mis à jour il y a $count h';
  }

  @override
  String get updatedJustNow => 'Mis à jour à l\'instant';

  @override
  String updatedMinutesAgo(int count) {
    return 'Mis à jour il y a $count min';
  }

  @override
  String get useSandbox => 'Utiliser le sandbox';

  @override
  String get useWorkspaceDefault =>
      'Utiliser la valeur par défaut de l\'espace de travail';

  @override
  String get userAgent => 'Agent utilisateur';

  @override
  String get userAgentDescription =>
      'Laissez vide pour utiliser l\'agent utilisateur par défaut de l\'application. Certains sites bloquent les agents utilisateurs non-navigateurs.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Utilisation du microphone par défaut du système.';

  @override
  String get viewLabel => 'Vue';

  @override
  String get viewLogs => 'Voir les journaux';

  @override
  String voiceInstallFailed(String error) {
    return 'Échec de l\'installation : $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Non installé. Télécharge ~200 Mo une seule fois ; fonctionne entièrement sur l\'appareil.';

  @override
  String get voiceModelNotInstalledLabel => 'Modèle vocal non installé.';

  @override
  String get voiceRedownloadBody =>
      'Les fichiers du modèle existant seront supprimés et l\'archive de ~200 Mo sera téléchargée à nouveau. La transcription vocale sera indisponible jusqu\'à la fin du téléchargement.';

  @override
  String get voiceRemoveBody =>
      'La transcription vocale sera désactivée jusqu\'à ce que vous la réinstalliez. Vous pouvez la réinstaller à tout moment.';

  @override
  String get voiceTranscription => 'Transcription vocale';

  @override
  String get weakIsolationDescription =>
      'Isolation faible — limite de namespace uniquement, pas de limite de kernel.';

  @override
  String get whenOffNoDefaultRoute =>
      'Si désactivé, le bac à sable démarre sans route par défaut.';

  @override
  String get whenOffServerStaysStopped =>
      'Si désactivé, le serveur reste arrêté jusqu\'à ce que vous le démarriez.';

  @override
  String get speechModel => 'Modèle de reconnaissance vocale';

  @override
  String get speechModelHint =>
      'Utilisé pour la transcription des réunions et le micro du composeur.';

  @override
  String get voiceModelInstalled =>
      'Installé. Alimente la transcription des réunions et le bouton micro du composeur.';

  @override
  String get meetingMicSilentWarning =>
      'Votre micro est peut-être coupé — les autres parlent mais rien n\'arrive à votre microphone.';

  @override
  String get meetingSummaryPrivacyNotice =>
      'L\'enregistrement et la transcription restent sur cette machine. Le résumé est rédigé par un agent : s\'il utilise un modèle cloud, votre transcription et vos notes sont envoyées à ce fournisseur.';

  @override
  String get meetingTemplates => 'Modèles de notes de réunion';

  @override
  String get meetingTemplatesHint =>
      'Adaptez le résumé IA à un type de réunion. Le modèle actif s’applique aux nouveaux résumés et aux relances.';

  @override
  String get meetingTemplateActive => 'Modèle actif';

  @override
  String get meetingTemplateAdd => 'Ajouter un modèle';

  @override
  String get meetingTemplateNewTitle => 'Nouveau modèle';

  @override
  String get meetingTemplateEditTitle => 'Modifier le modèle';

  @override
  String get meetingTemplateNameLabel => 'Nom';

  @override
  String get meetingTemplateNameHint => 'p. ex. Revue de sprint';

  @override
  String get meetingTemplateInstructionsLabel => 'Instructions';

  @override
  String get meetingTemplateInstructionsHint =>
      'Comment l’IA doit-elle structurer et accentuer ces notes ?';

  @override
  String get workingMemory => 'Mémoire de travail';

  @override
  String get workspaceName => 'Nom de l\'espace de travail';

  @override
  String get workspaceScopedSkills =>
      'Fichiers de compétences limités à l\'espace de travail, attachés aux agents.';

  @override
  String get workspaces => 'Espaces de travail';

  @override
  String get writePrivateNotes =>
      'Écrire des notes privées, observations, plans...';

  @override
  String get writeSkillContent =>
      'Écrivez le contenu de votre compétence ici (Markdown)…';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count ans',
      one: 'il y a 1 an',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'hier';

  @override
  String get focusModeStart => 'Démarrer une session de concentration';

  @override
  String get focusModeConfigTitle => 'Démarrer une session de concentration';

  @override
  String get focusModeGoalLabel => 'Objectif';

  @override
  String get focusModeGoalHint => 'Sur quoi travaillez-vous ?';

  @override
  String get focusModeDurationLabel => 'Durée';

  @override
  String get focusModeBlockNotifications => 'Bloquer les notifications';

  @override
  String get focusModeStartButton => 'Démarrer';

  @override
  String get focusModeFloat => 'Réduire dans la barre';

  @override
  String get focusModeActiveTooltip =>
      'Mode concentration actif — appuyez pour terminer';

  @override
  String get dismiss => 'Ignorer';

  @override
  String get acceptAndResolve => 'Accepter et résoudre';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'Il semble que vous fassiez beaucoup de révisions d\'affilée. Prenez une pause !';
  }

  @override
  String get notificationSound => 'Son de notification';

  @override
  String get notificationSoundDescription =>
      'Son joué quand une notification est affichée.';

  @override
  String get notificationSoundNone => 'Aucun';

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
  String get notificationSoundMigrosSoft => 'Migros (soft)';

  @override
  String get notificationSoundMigrosHard => 'Migros (hard)';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => 'Tester';

  @override
  String get notificationVolume => 'Volume';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Aucune PR de @$login dans cet espace de travail';
  }

  @override
  String get usersLabel => 'Utilisateurs';

  @override
  String get mergePullRequest => 'Merge pull request';

  @override
  String get forceMergePullRequest => 'Force merge pull request';

  @override
  String get closePullRequest => 'Close pull request';

  @override
  String get closePullRequestConfirm =>
      'Are you sure you want to close this pull request?';

  @override
  String get stackedPullRequests => 'Pull requests empilées';

  @override
  String partOfStack(int position, int total) {
    return 'Partie d\'une pile ($position sur $total)';
  }

  @override
  String get createStack => 'Créer une pile';

  @override
  String get createStackDialogTitle => 'Créer une pile de pull requests';

  @override
  String createStackDialogBody(int count) {
    return 'Ces $count pull requests seront empilées, de la base vers le sommet :';
  }

  @override
  String get createStackInvalidSelection =>
      'Sélectionnez au moins deux pull requests du même dépôt pour créer une pile';

  @override
  String get createStackNotAChain =>
      'Les pull requests sélectionnées ne forment pas une chaîne : la branche de base de chacune doit être la branche head de la précédente';

  @override
  String get createStackAlreadyStacked =>
      'Une ou plusieurs pull requests sélectionnées sont déjà dans une pile';

  @override
  String get stackCreated => 'Pile créée';

  @override
  String get stackCreationFailed => 'Impossible de créer la pile';

  @override
  String get squashAndMerge => 'Squash and merge';

  @override
  String get createMergeCommit => 'Create a merge commit';

  @override
  String get rebaseAndMerge => 'Rebase and merge';

  @override
  String get commitTitle => 'Commit title';

  @override
  String get commitDescription => 'Commit description';

  @override
  String get pullRequestMerged => 'Pull request merged';

  @override
  String get pullRequestClosed => 'Pull request closed';

  @override
  String failedToMergePr(String error) {
    return 'Failed to merge: $error';
  }

  @override
  String failedToClosePr(String error) {
    return 'Failed to close: $error';
  }

  @override
  String get markReadyForReview => 'Prête pour la revue';

  @override
  String get markReadyForReviewConfirm =>
      'Cette pull request ne sera plus un brouillon. Les relecteurs sont notifiés, les vérifications requises conditionnent la fusion et toute automatisation guettant les pull requests prêtes se déclenche.';

  @override
  String get convertToDraft => 'Convertir en brouillon';

  @override
  String get convertToDraftConfirm =>
      'Cette pull request repassera en brouillon. Ses demandes de revue en attente seront annulées et elle ne pourra plus être fusionnée tant que vous ne l\'aurez pas remarquée comme prête.';

  @override
  String get pullRequestMarkedReady =>
      'Pull request marquée comme prête pour la revue';

  @override
  String get pullRequestConvertedToDraft =>
      'Pull request convertie en brouillon';

  @override
  String failedToMarkPrReady(String error) {
    return 'Échec du passage en prête pour la revue : $error';
  }

  @override
  String failedToConvertPrToDraft(String error) {
    return 'Échec de la conversion en brouillon : $error';
  }

  @override
  String get checksFailing => 'Échec des vérifications';

  @override
  String get reviewsPending => 'Some reviews are pending';

  @override
  String get mergeConflictsWithBase =>
      'Cette branche a des conflits qui doivent être résolus';

  @override
  String get branchOutOfDateWithBase =>
      'Cette branche n\'est pas à jour avec la branche de base';

  @override
  String get mergeBlockedByBranchProtection =>
      'La protection de branche bloque cette fusion';

  @override
  String get confirm => 'Confirm';

  @override
  String get trustedSitesSectionTitle => 'Sites de confiance';

  @override
  String get trustedSitesEmpty =>
      'Aucun site de confiance. Ajoutez un domaine pour y désactiver le blocage.';

  @override
  String get addTrustedSite => 'Ajouter un site de confiance';

  @override
  String get removeTrustedSite => 'Supprimer';

  @override
  String get disableBlockingForThisSite => 'Désactiver le blocage sur ce site';

  @override
  String get enableBlockingForThisSite => 'Activer le blocage sur ce site';

  @override
  String get enterDomainHint => 'ex. exemple.com';

  @override
  String get invalidDomain => 'Saisissez un domaine valide (ex. exemple.com)';

  @override
  String get pageLoadTimedOut =>
      'Chargement de la page expiré. Rechargez ou ouvrez dans le navigateur.';

  @override
  String get pipelinesScreenTitle => 'Pipelines';

  @override
  String get pipelinesScreenSubtitle =>
      'Declarative multi-step agent workflows';

  @override
  String get pipelinesRunPipeline => 'Exécuter le pipeline';

  @override
  String get pipelineRunLauncherTitle => 'Exécuter le pipeline';

  @override
  String get pipelineRunSubtitle =>
      'Choisissez un pipeline et renseignez ses entrées pour lancer une exécution.';

  @override
  String get pipelineRunNoInputsBadge => 'Aucune entrée';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrées',
      one: '1 entrée',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'Ce pipeline ne nécessite aucune entrée.';

  @override
  String get pipelineRunSubmit => 'Exécuter le pipeline';

  @override
  String get pipelineRunCouldNotStart => 'Impossible de démarrer l\'exécution.';

  @override
  String pipelineRunStarted(String name) {
    return '$name démarré';
  }

  @override
  String get pipelineRunEmptyTitle => 'Aucun pipeline prêt à être lancé';

  @override
  String get pipelineRunEmptyHint =>
      'Activez un pipeline et activez l\'exécution manuelle dans son éditeur pour le lancer ici.';

  @override
  String get pipelineRunManageTemplates => 'Gérer les pipelines';

  @override
  String get pipelineRunSettingsTitle => 'Exécution manuelle';

  @override
  String get pipelineRunSettingsAllow => 'Autoriser l\'exécution manuelle';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Afficher ce pipeline sur la page d\'exécution pour pouvoir le lancer manuellement.';

  @override
  String get pipelineRunSettingsConcurrencyTitle => 'Simultanéité';

  @override
  String get pipelineRunSettingsMaxParallel => 'Exécutions parallèles max';

  @override
  String get pipelineRunSettingsMaxParallelHelp =>
      'Laissez vide pour illimité. Les exécutions supplémentaires attendent dans une file et démarrent dès qu\'une place se libère.';

  @override
  String get pipelineRunSettingsMaxParallelHint => 'Illimité';

  @override
  String get pipelineRunSettingsMaxParallelInvalid =>
      'Saisissez un nombre entier supérieur ou égal à 1, ou laissez vide pour illimité.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Entrées';

  @override
  String get pipelineRunSettingsAddInput => 'Ajouter une entrée';

  @override
  String get pipelineRunSettingsNoInputs => 'Aucune entrée pour l\'instant.';

  @override
  String get pipelineInputEditTitle => 'Champ d\'entrée';

  @override
  String get pipelineInputKeyLabel => 'Clé';

  @override
  String get pipelineInputKeyHelp =>
      'Clé d\'état sous laquelle la valeur est stockée (par ex. repo_full_name).';

  @override
  String get pipelineInputLabelLabel => 'Libellé';

  @override
  String get pipelineInputTypeLabel => 'Type';

  @override
  String get pipelineInputOptionsLabel => 'Options (séparées par des virgules)';

  @override
  String get pipelineInputDefaultLabel => 'Valeur par défaut';

  @override
  String get pipelineInputPlaceholderLabel => 'Texte indicatif';

  @override
  String get pipelineInputHelpLabel => 'Texte d\'aide';

  @override
  String get pipelineInputRequiredLabel => 'Obligatoire';

  @override
  String get pipelineInputTypeText => 'Texte';

  @override
  String get pipelineInputTypeMultiline => 'Texte multiligne';

  @override
  String get pipelineInputTypeNumber => 'Nombre';

  @override
  String get pipelineInputTypeBoolean => 'Bascule';

  @override
  String get pipelineInputTypeSelect => 'Liste déroulante';

  @override
  String get pipelinesEmpty => 'No pipeline runs yet';

  @override
  String get pipelinesEmptyHint =>
      'Cliquez sur « Exécuter le pipeline » pour en lancer un.';

  @override
  String get pipelinesNoSteps => 'No steps recorded yet';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Sélectionnez un espace de travail pour voir ses pipelines';

  @override
  String pipelinesLoadError(String error) {
    return 'Échec du chargement des pipelines : $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Échec du démarrage du pipeline : $error';
  }

  @override
  String get pipelineStatusPending => 'Pending';

  @override
  String get pipelineStatusQueued => 'En file d\'attente';

  @override
  String get pipelineStatusRunning => 'Running';

  @override
  String get pipelineStatusSuspended => 'Suspended';

  @override
  String get pipelineStatusCompleted => 'Completed';

  @override
  String get pipelineStatusFailed => 'Failed';

  @override
  String get pipelineStatusCancelled => 'Cancelled';

  @override
  String get pipelineStatusSkipped => 'Skipped';

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed sur $total étapes';
  }

  @override
  String get pipelineWaterfallTimeline => 'Chronologie';

  @override
  String pipelineWaterfallActive(String duration) {
    return 'Actif $duration';
  }

  @override
  String pipelineWaterfallIdle(String duration) {
    return 'inactif $duration';
  }

  @override
  String get pipelineWaterfallIdleTooltip =>
      'Temps exclu du total actif : l\'exécution était arrêtée ou en attente entre les étapes.';

  @override
  String get pipelineStepStarted => 'Démarré';

  @override
  String get pipelineStepFinished => 'Terminé';

  @override
  String get pipelineStepDurationLabel => 'Durée';

  @override
  String get pipelineStepBranch => 'Branche';

  @override
  String get pipelineStepViewConversation => 'Voir la conversation';

  @override
  String get pipelineStepError => 'Erreur';

  @override
  String get pipelineStepInput => 'Entrée';

  @override
  String get pipelineStepOutput => 'Sortie';

  @override
  String get pipelineStepNotExecuted => 'Pas encore exécuté';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Échec à $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Manuel';

  @override
  String get pipelineStepSkippedReason => 'Ignoré';

  @override
  String get pipelineStepPriorAttempts => 'Tentatives précédentes';

  @override
  String get pipelineStepAttemptLabel => 'Tentative';

  @override
  String pipelineStepAttemptN(int number) {
    return 'Tentative $number';
  }

  @override
  String get pipelineStepAttemptInterrupted => 'Interrompue';

  @override
  String get pipelineRunColumnPipeline => 'Pipeline';

  @override
  String get pipelineRunColumnDuration => 'Durée';

  @override
  String get pipelineRunQueueNext => 'Suivant';

  @override
  String pipelineRunQueuePosition(int position) {
    return '${position}e en file';
  }

  @override
  String get pipelineRunColumnStarted => 'Démarré';

  @override
  String get pipelineRunHistory => 'Historique des exécutions';

  @override
  String get pipelineRunHistoryEmpty =>
      'Aucune autre exécution pour l\'instant';

  @override
  String pipelineRunRerunAgo(String time) {
    return 'Relancé $time';
  }

  @override
  String pipelineRunAttempt(int number) {
    return 'Tentative $number';
  }

  @override
  String pipelineRunFirstStarted(String time) {
    return 'premier démarrage $time';
  }

  @override
  String get pipelineRunFilterAll => 'Tous';

  @override
  String get pipelineRunFilterEmpty =>
      'Aucune exécution ne correspond à ce filtre';

  @override
  String get relativeJustNow => 'à l\'instant';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count min',
      one: 'il y a 1 min',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count heures',
      one: 'il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get teamsTitle => 'Teams';

  @override
  String get teamsAddTeam => 'Add team';

  @override
  String get teamsLoadError => 'Impossible de charger les équipes';

  @override
  String get teamsEmptyTitle => 'Aucune équipe pour le moment';

  @override
  String get teamsEmptyDescription =>
      'Regroupez des agents en équipes afin que le travail assigné à une équipe soit acheminé via un responsable qui le délègue.';

  @override
  String get teamCreateTitle => 'Nouvelle équipe';

  @override
  String get teamEditTitle => 'Modifier l\'équipe';

  @override
  String get teamNameLabel => 'Nom de l\'équipe';

  @override
  String get teamNameHint => 'ex. Frontend';

  @override
  String get teamDescriptionLabel => 'Description';

  @override
  String get teamDescriptionHint => 'Ce dont cette équipe est responsable';

  @override
  String get teamLeaderLabel => 'Responsable';

  @override
  String get teamLeaderHelp =>
      'Le coordinateur qui reçoit le travail assigné à l\'équipe et le délègue au membre le plus adapté.';

  @override
  String get teamNoLeader => 'Aucun responsable';

  @override
  String get teamInstructionsLabel => 'Instructions de fonctionnement';

  @override
  String get teamInstructionsHelp =>
      'Ajoutées au briefing du responsable — conventions de l\'équipe, règles d\'escalade, ton.';

  @override
  String get teamInstructionsHint => 'Facultatif';

  @override
  String get teamSaved => 'Équipe enregistrée';

  @override
  String get teamMembersError => 'Impossible de charger les membres';

  @override
  String teamMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
      zero: 'Aucun membre',
    );
    return '$_temp0';
  }

  @override
  String get teamAddMember => 'Ajouter un membre';

  @override
  String get teamAddMemberTitle => 'Ajouter des membres';

  @override
  String teamAddMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ajouter $count',
      one: 'Ajouter 1',
      zero: 'Ajouter',
    );
    return '$_temp0';
  }

  @override
  String get teamNoAgentsToAdd =>
      'Tous les agents font déjà partie de cette équipe.';

  @override
  String get teamRemoveMember => 'Retirer de l\'équipe';

  @override
  String get teamLeaderBadge => 'Responsable';

  @override
  String get teamUnknownAgent => 'Agent inconnu';

  @override
  String get teamMembersEmpty => 'Aucun membre pour le moment';

  @override
  String get teamMembersEmptyDescription =>
      'Ajoutez des agents pour que le responsable ait des personnes à qui déléguer.';

  @override
  String get teamSelectPrompt => 'Sélectionnez une équipe';

  @override
  String get teamSelectPromptDescription =>
      'Choisissez une équipe dans la liste ou créez-en une nouvelle.';

  @override
  String get teamDeleteTitle => 'Supprimer l\'équipe ?';

  @override
  String teamDeleteBody(String name) {
    return '$name sera supprimée. Ses agents ne sont pas affectés.';
  }

  @override
  String get teamHasLeaderTooltip => 'A un responsable';

  @override
  String get pipelineTemplatesNav => 'Modèles de pipeline';

  @override
  String get pipelineTemplatesTitle => 'Modèles de pipeline';

  @override
  String get pipelineTemplatesSubtitle =>
      'Éditeur glisser-déposer pour les pipelines qui orchestrent vos agents.';

  @override
  String get pipelineTemplatesNew => 'Nouveau modèle';

  @override
  String get pipelineTemplatesEmpty =>
      'Aucun modèle de pipeline. Créez-en un pour commencer.';

  @override
  String get pipelineTemplateIdLabel => 'ID du modèle';

  @override
  String get pipelineTemplateBuiltInBadge => 'Intégré';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Supprimer le modèle ?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Supprimer le modèle de pipeline $name ? Cette action est irréversible.';
  }

  @override
  String get pipelineTemplateEditorTitle => 'Modifier le pipeline';

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Faites glisser des types de nœuds depuis la barre latérale, puis connectez-les.';

  @override
  String get unsavedChanges => 'Modifications non enregistrées';

  @override
  String get nodeLibraryTitle => 'Bibliothèque de nœuds';

  @override
  String get nodeLibraryHint =>
      'Glissez un élément sur le canevas pour ajouter un nœud.';

  @override
  String get editorDragHint =>
      'Glissez depuis la bibliothèque, cliquez sur un nœud pour le modifier';

  @override
  String get editorEmptyCanvas =>
      'Glissez un nœud depuis la bibliothèque pour commencer.';

  @override
  String get nodeConfigTitle => 'Configuration du nœud';

  @override
  String get nodeConfigKind => 'Type';

  @override
  String get nodeConfigLabel => 'Libellé';

  @override
  String get nodeConfigAgent => 'Agent';

  @override
  String get nodeConfigAgentHint => 'Choisir un agent…';

  @override
  String get nodeConfigInputKeys =>
      'Clés d\'entrée (séparées par des virgules)';

  @override
  String get nodeConfigInputKeysHelp =>
      'Clés d\'état consommées par ce nœud. Utilisées pour la substitution dans le prompt.';

  @override
  String get nodeConfigRepos => 'Dépôts à cloner';

  @override
  String get nodeConfigReposHelp =>
      'Dépôts clonés et indexés lorsque ce nœud démarre sa conversation. Tout sélectionner clone l\'ensemble des dépôts (comportement par défaut).';

  @override
  String get nodeConfigRepoBranchHint => 'Branche (par défaut)';

  @override
  String get nodeConfigRepoBranchHelp =>
      'La branche depuis laquelle chaque copie est créée. Laissez vide pour la branche par défaut du dépôt — la copie de travail reçoit sa propre branche, donc rien de ce qu\'un agent valide n\'atterrit sur celle-ci.';

  @override
  String nodeConfigReposDynamic(String entries) {
    return 'Entrées dynamiques conservées : $entries';
  }

  @override
  String get nodeConfigCreateConversation => 'Y ouvrir une conversation';

  @override
  String get nodeConfigCreateConversationHelp =>
      'Laissez décoché quand plusieurs nœuds d\'agent suivent : chacun ouvre son propre fil nommé. Cochez quand un seul nœud d\'agent suit, pour que le salon n\'affiche jamais une conversation sans titre à côté.';

  @override
  String get nodeConfigConversationTitle => 'Nom de la conversation';

  @override
  String get nodeConfigConversationTitleHelp =>
      'Donnez le même nom au nœud d\'agent en aval et les deux travaillent dans un seul fil. Par défaut, le libellé du nœud.';

  @override
  String get nodeConfigSpaceName => 'Nom de l\'espace';

  @override
  String get nodeConfigSpaceNameHelp =>
      'Le nom du salon ouvert par ce nœud. Accepte les mêmes variables d\'état qu\'une invite. Laissez vide pour utiliser le libellé du nœud.';

  @override
  String get nodeConfigSpaceNameHint => 'Revue de pr_number';

  @override
  String get nodeConfigStreamTitle => 'Nom de la conversation';

  @override
  String get nodeConfigStreamTitleHelp =>
      'Le fil nommé dans lequel l\'agent de ce nœud travaille au sein du salon. Accepte les mêmes variables d\'état qu\'une invite. Laissez vide et le tour arrive dans la conversation permanente du salon, où un éventail d\'agents s\'entremêle.';

  @override
  String get nodeConfigConversationTitleHint => 'Analyse d\'architecture';

  @override
  String get nodeConfigOutputKey => 'Clé de sortie';

  @override
  String get nodeConfigPrompt => 'Modèle de prompt';

  @override
  String get nodeConfigPromptHelp =>
      'Utilisez des placeholders à double accolade pour insérer des valeurs depuis l\'état à l\'exécution.';

  @override
  String get nodeConfigScript => 'Script bash';

  @override
  String get nodeConfigScriptHelp =>
      'Exécuté avec bash -c. GITHUB_TOKEN est défini. Les placeholders sont substitués avant exécution.';

  @override
  String get nodeConfigTriggers => 'Déclenché par';

  @override
  String get nodeConfigNoUpstream => 'Aucun autre nœud à connecter en amont.';

  @override
  String get nodeConfigRouteKeys => 'Clés de route';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Clé de route depuis $source';
  }

  @override
  String get conditionSectionTitle => 'Condition';

  @override
  String get conditionMode => 'Mode';

  @override
  String get conditionModeFilesAny => 'Fichier(s) présent(s) — au moins un';

  @override
  String get conditionModeFilesAll => 'Fichiers présents — tous';

  @override
  String get conditionModeComparison => 'Comparaison';

  @override
  String get conditionModeSwitch => 'Aiguillage';

  @override
  String get conditionFilePaths => 'Chemins de fichiers';

  @override
  String get conditionFilePathsAnyHelp =>
      'Un chemin par ligne, relatif au répertoire de base. Renvoie true si au moins un existe.';

  @override
  String get conditionFilePathsAllHelp =>
      'Un chemin par ligne, relatif au répertoire de base. Renvoie true seulement si tous existent.';

  @override
  String get conditionBaseKey => 'Clé du répertoire de base';

  @override
  String get conditionBaseKeyHelp =>
      'Clé d\'état contenant le répertoire de résolution des chemins (par défaut repo_local_path).';

  @override
  String get conditionRecursive => 'Chercher dans les sous-dossiers';

  @override
  String get conditionNegate => 'Inverser : route true si absent';

  @override
  String get conditionLeft => 'Valeur de gauche';

  @override
  String get conditionOperator => 'Opérateur';

  @override
  String get conditionRight => 'Valeur de droite';

  @override
  String get conditionSwitchKey => 'Aiguiller sur la clé d\'état';

  @override
  String get conditionCases => 'Cas (séparés par des virgules)';

  @override
  String get conditionCasesHelp =>
      'Clés de route à comparer à la valeur, dans l\'ordre.';

  @override
  String get conditionDefaultCase => 'Cas par défaut';

  @override
  String get triggerPanelTitle => 'Déclencheurs';

  @override
  String get triggerPanelHelp => 'Ce qui démarre ce pipeline.';

  @override
  String get triggerManualHelp =>
      'Afficher sur la page d\'exécution et lancer à la main.';

  @override
  String get triggerSectionAutomatic => 'Déclencheurs automatiques';

  @override
  String get triggerAddButton => 'Ajouter un déclencheur';

  @override
  String get triggerNoneYet => 'Aucun déclencheur automatique pour l\'instant.';

  @override
  String get triggerAddDialogTitle => 'Ajouter un déclencheur';

  @override
  String get triggerKindLabel => 'Type de déclencheur';

  @override
  String get triggerKindEvent => 'Sur un évènement';

  @override
  String get triggerKindSchedule => 'Selon un calendrier';

  @override
  String get triggerKindWebhook => 'Via un webhook';

  @override
  String get triggerScheduleExprLabel =>
      'Planification (cron ou every:secondes)';

  @override
  String get triggerTimezoneLabel => 'Fuseau horaire (facultatif)';

  @override
  String get triggerCatchUpLabel => 'En cas d\'exécutions manquées';

  @override
  String get triggerCatchUpRunOnce => 'Exécuter une fois';

  @override
  String get triggerCatchUpSkip => 'Ignorer';

  @override
  String get syncHealthTitle => 'État de la synchronisation';

  @override
  String get syncHealthNoConfigs => 'Aucune connexion de synchronisation';

  @override
  String get syncHealthNeverSynced => 'Jamais synchronisé';

  @override
  String get syncOutcomeOk => 'Synchronisé';

  @override
  String get syncOutcomeFailed => 'Échec';

  @override
  String get syncOutcomeSkipped => 'Ignoré';

  @override
  String syncHealthFailedStreak(int count) {
    return '$count échecs consécutifs';
  }

  @override
  String get triggerWebhookHelp =>
      'Une URL de webhook signée est générée. Les systèmes externes y envoient une requête POST pour lancer ce pipeline.';

  @override
  String get triggerEventFieldLabel => 'Évènement';

  @override
  String get triggerNoMoreEvents =>
      'Tous les évènements disponibles sont déjà configurés.';

  @override
  String get triggerMatchStatusLabel => 'Uniquement quand le statut est';

  @override
  String get triggerSummaryNone => 'Aucun déclencheur';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Toutes les ${seconds}s';
  }

  @override
  String get triggerEventManual => 'Exécution manuelle';

  @override
  String get triggerEventSchedule => 'Calendrier';

  @override
  String get triggerEventPrStatusChanged => 'Statut de la PR modifié';

  @override
  String get triggerEventExternalPr => 'PR externe ouverte';

  @override
  String get triggerEventPrPublished => 'PR publiée';

  @override
  String get triggerEventPrMerged => 'PR fusionnée';

  @override
  String get triggerEventRepoAdded => 'Dépôt ajouté';

  @override
  String get triggerEventCodeGraphWatch => 'Modification de fichier';

  @override
  String pipelineRunCauseChangedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers modifiés',
      one: '1 fichier modifié',
    );
    return '$_temp0';
  }

  @override
  String pipelineRunCauseMorePaths(int count) {
    return '+$count de plus';
  }

  @override
  String get pipelineRunCauseRescan => 'Modifié sur le disque';

  @override
  String get pipelineRunCauseInitial => 'Première indexation de cette copie';

  @override
  String get triggerEventMessageReceived => 'Message reçu';

  @override
  String get triggerEventTicketCompleted => 'Tâche terminée';

  @override
  String get triggerEventTicketFailed => 'Tâche échouée';

  @override
  String get triggerEventTicketCancelled => 'Tâche annulée';

  @override
  String get triggerEventBudgetCrossed => 'Seuil de budget dépassé';

  @override
  String get nodeLibrarySearchHint => 'Rechercher des nœuds';

  @override
  String get nodeLibraryNoMatches => 'Aucun nœud correspondant';

  @override
  String get nodeCategoryFlow => 'Flux et logique';

  @override
  String get nodeCategoryPr => 'Revue de PR';

  @override
  String get nodeCategoryAgents => 'Agents';

  @override
  String get nodeCategoryMessaging => 'Messagerie';

  @override
  String get nodeCategoryCode => 'Code';

  @override
  String get triggerDisabledTag => 'désactivé';

  @override
  String get pipelineInputTypeRepo => 'Dépôt';

  @override
  String get pipelineRunNoRepos => 'Aucun dépôt dans cet espace de travail.';

  @override
  String get allowTicketingApi => 'Autoriser les appels API de tickets';

  @override
  String get ticketingApiKey => 'Clé API de ticketing';

  @override
  String get ticketingApiKeySubtitle =>
      'Injecte la clé API du fournisseur de tickets dans le bac à sable.';

  @override
  String get ticketingProvider => 'Fournisseur de tickets';

  @override
  String get connectGitHubAndTicketing =>
      'Connectez un hébergeur de code pour que Control Center puisse lire vos pull requests, tickets et revues. Connectez éventuellement un fournisseur de tickets. Les identifiants sont conservés par votre serveur, jamais par cette machine.';

  @override
  String get triggerEventTicketAssigned => 'Ticket assigné';

  @override
  String get navTickets => 'Tickets';

  @override
  String get ticketsTitle => 'Tickets';

  @override
  String get newTicket => 'Nouveau ticket';

  @override
  String get noTicketsYet => 'Aucun ticket pour le moment';

  @override
  String get addCollaborator => 'Ajouter un collaborateur';

  @override
  String get noCollaborators => 'Aucun collaborateur pour l\'instant';

  @override
  String get linkedPullRequests => 'Pull requests liées';

  @override
  String get noLinkedPullRequests => 'Aucune pull request liée';

  @override
  String get stopAgent => 'Arrêter l\'agent';

  @override
  String get ticketProperties => 'Propriétés';

  @override
  String get ticketTabIssue => 'Ticket';

  @override
  String get ticketSelectPrompt =>
      'Sélectionnez un ticket pour afficher ses détails';

  @override
  String get unassigned => 'Non assigné';

  @override
  String get ticketStatusBacklog => 'Backlog';

  @override
  String get ticketStatusOpen => 'À faire';

  @override
  String get ticketStatusInProgress => 'En cours';

  @override
  String get ticketStatusInReview => 'En revue';

  @override
  String get ticketStatusDone => 'Terminé';

  @override
  String get ticketStatusBlocked => 'Bloqué';

  @override
  String get ticketStatusFailed => 'Échoué';

  @override
  String get ticketStatusCancelled => 'Annulé';

  @override
  String get notificationTicketAssigned => 'Ticket assigné';

  @override
  String get notificationTicketStatusChanged => 'Statut du ticket modifié';

  @override
  String get priority => 'Priorité';

  @override
  String get status => 'Statut';

  @override
  String get assignee => 'Assigné à';

  @override
  String get labels => 'Étiquettes';

  @override
  String get noLabelsYet => 'Aucune étiquette';

  @override
  String get clearLabels => 'Effacer les étiquettes';

  @override
  String get pipelineStepAgentActivity => 'Activité de l\'agent';

  @override
  String get runStatusCompleted => 'Terminé';

  @override
  String get runStatusQueued => 'En file d\'attente';

  @override
  String get ticketDescription => 'Description';

  @override
  String get ticketPriorityNone => 'Aucune';

  @override
  String get ticketPriorityUrgent => 'Urgent';

  @override
  String get ticketPriorityHigh => 'Élevée';

  @override
  String get ticketPriorityMedium => 'Moyenne';

  @override
  String get ticketPriorityLow => 'Basse';

  @override
  String get ticketViewList => 'Liste';

  @override
  String get ticketViewBoard => 'Tableau';

  @override
  String get ticketTitlePlaceholder => 'Titre du ticket';

  @override
  String get ticketDescriptionPlaceholder => 'Ajouter une description…';

  @override
  String get createMore => 'En créer d\'autres';

  @override
  String selectedCount(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get clearSelection => 'Effacer la sélection';

  @override
  String get bulkDeleteTitle => 'Supprimer les tickets';

  @override
  String bulkDeleteMessage(int count) {
    return 'Supprimer $count tickets sélectionnés ? Action irréversible.';
  }

  @override
  String get assignTo => 'Assigner à…';

  @override
  String get sectionMembers => 'Membres';

  @override
  String get sectionAgents => 'Agents';

  @override
  String get sidebarGroupWorkspace => 'Espace de travail';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsTooltip => 'Notifications';

  @override
  String get notificationsEmpty => 'Vous êtes à jour';

  @override
  String notificationsUnreadCount(int count) {
    return '$count non lues';
  }

  @override
  String get notificationsMarkRead => 'Marquer comme lu';

  @override
  String get notificationsMarkUnread => 'Marquer comme non lu';

  @override
  String get notificationsEntryActions => 'Actions de notification';

  @override
  String get markAllRead => 'Tout marquer comme lu';

  @override
  String get teamsNav => 'Équipes';

  @override
  String get noWorkspace => 'Aucun espace de travail';

  @override
  String get selectWorkspace => 'Sélectionner un espace de travail';

  @override
  String get navMemory => 'Mémoire';

  @override
  String get memoryTabFacts => 'Faits';

  @override
  String get memoryTabPolicies => 'Politiques';

  @override
  String get memoryGraphShowFacts => 'Afficher les faits';

  @override
  String get memoryGraphHideFacts => 'Masquer les faits';

  @override
  String get memoryGraphExpandAll => 'Afficher tous les faits';

  @override
  String get memoryGraphCollapseAll => 'Masquer tous les faits';

  @override
  String get memoryTabGraph => 'Graphe de connaissances';

  @override
  String get memoryNoWorkspace =>
      'Sélectionnez un espace de travail pour voir sa mémoire.';

  @override
  String get searchArticles => 'Rechercher des articles';

  @override
  String get filterAll => 'Tout';

  @override
  String get filterUnread => 'Non lus';

  @override
  String get filterSaved => 'Enregistrés';

  @override
  String get saveArticle => 'Enregistrer l\'article';

  @override
  String get removeFromSaved => 'Retirer des enregistrés';

  @override
  String get filterBySource => 'Filtrer par source';

  @override
  String get viewAsList => 'Vue liste';

  @override
  String get viewAsGrid => 'Vue grille';

  @override
  String get noMatchingArticles => 'Aucun article correspondant';

  @override
  String get noMatchingArticlesBody =>
      'Essayez une autre recherche ou un autre filtre de source.';

  @override
  String get allCaughtUp => 'Tout est à jour';

  @override
  String get allCaughtUpBody => 'Aucun article non lu — revenez plus tard.';

  @override
  String get openArticlesInAppDescription =>
      'Ouvrir les liens dans le lecteur intégré plutôt que dans votre navigateur par défaut.';

  @override
  String get blockAdsTrackersDescription =>
      'Supprimer les publicités, les traqueurs et les bannières de cookies des articles ouverts dans le lecteur.';

  @override
  String get agentQuestionHeader => 'Question pour vous';

  @override
  String get agentQuestionAnsweredLabel => 'Répondu';

  @override
  String get agentQuestionSubmit => 'Envoyer la réponse';

  @override
  String get agentQuestionFreeformHint => 'Saisissez votre réponse…';

  @override
  String get agentQuestionAnswerLabel => 'Votre réponse';

  @override
  String get reviewRequested => 'Révision demandée';

  @override
  String get connectGitHubHint =>
      'Connectez-vous à GitHub ou ajoutez un jeton dans Paramètres → Vous → Profil et identité → Hébergement de code';

  @override
  String get connectGitHubToLoadPrs =>
      'Connectez GitHub pour charger les pull requests';

  @override
  String get noRepositoriesConfigured => 'Aucun dépôt configuré';

  @override
  String openedAgo(String age) {
    return 'Ouvert $age';
  }

  @override
  String prTimelineOpened(String author) {
    return '$author a ouvert cette pull request';
  }

  @override
  String prTimelineOpenedWithCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$author a ouvert cette pull request avec $_temp0';
  }

  @override
  String prTimelineRequestedReview(String actor, String reviewers) {
    return '$actor a demandé une revue à $reviewers';
  }

  @override
  String prTimelineRemovedReviewRequest(String actor, String reviewers) {
    return '$actor a retiré la demande de revue pour $reviewers';
  }

  @override
  String prTimelineRequestedAndRemovedReview(
    String actor,
    String requested,
    String removed,
  ) {
    return '$actor a demandé une revue à $requested et a retiré la demande de revue pour $removed';
  }

  @override
  String prTimelineCommitted(String author) {
    return '$author a commité';
  }

  @override
  String prTimelinePushedCommits(String author, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$author a poussé $_temp0';
  }

  @override
  String prTimelineApproved(String author) {
    return '$author a approuvé ces modifications';
  }

  @override
  String prTimelineChangesRequested(String author) {
    return '$author a demandé des modifications';
  }

  @override
  String prTimelineCodeComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commentaires de code',
      one: '1 commentaire de code',
    );
    return '$_temp0';
  }

  @override
  String prTimelineReviewed(String author) {
    return '$author a laissé une revue';
  }

  @override
  String get prTimelineSomeone => 'Quelqu\'un';

  @override
  String get prTimelineBotBadge => 'bot';

  @override
  String updatedAgo(String age) {
    return 'Mis à jour $age';
  }

  @override
  String get checksPassing => 'Vérifications réussies';

  @override
  String get checksRunning => 'Vérifications en cours';

  @override
  String get needsYourReview => 'Nécessite votre révision';

  @override
  String get checks => 'Vérifications';

  @override
  String get noReviewersAssigned => 'Aucun relecteur assigné';

  @override
  String get noAssignees => 'Aucun responsable';

  @override
  String get loadingEllipsis => 'Chargement…';

  @override
  String get loadingChecks => 'Chargement des vérifications…';

  @override
  String get noChecksYet => 'Aucune vérification exécutée';

  @override
  String checksFailingCount(int count) {
    return '$count en échec';
  }

  @override
  String get showMore => 'Afficher plus';

  @override
  String get showLess => 'Afficher moins';

  @override
  String get backToPullRequests => 'Retour aux pull requests';

  @override
  String get pullRequestNotFound => 'Pull request introuvable';

  @override
  String get pullRequestNotFoundBody =>
      'Elle a peut-être été fusionnée, fermée ou déplacée.';

  @override
  String get couldntLoadPullRequest =>
      'Impossible de charger cette pull request';

  @override
  String get showDetails => 'Afficher les détails';

  @override
  String get noDescriptionProvided => 'Aucune description fournie.';

  @override
  String get factsHint =>
      'Les faits apparaîtront ici à mesure que vos agents apprennent.';

  @override
  String get noFactsMatch => 'Aucun fait ne correspond à votre recherche';

  @override
  String get memoryLoadError => 'Impossible de charger la mémoire';

  @override
  String get sortRecent => 'Récent';

  @override
  String get sortConfidence => 'Confiance';

  @override
  String get confidenceTooltip =>
      'À quel point les agents sont sûrs que ce fait est vrai, de 0 à 100 %.';

  @override
  String get supersededTooltip => 'Un fait plus récent a remplacé celui-ci.';

  @override
  String get domain => 'Domaine';

  @override
  String get fitToView => 'Ajuster à l\'écran';

  @override
  String get project => 'Projet';

  @override
  String get newProject => 'Nouveau projet';

  @override
  String get editProject => 'Modifier le projet';

  @override
  String get deleteProject => 'Supprimer le projet';

  @override
  String get noProject => 'Aucun projet';

  @override
  String get allTickets => 'Tous les tickets';

  @override
  String get projectNamePlaceholder => 'Nom du projet';

  @override
  String get projectDescriptionPlaceholder => 'Description (facultative)';

  @override
  String get projectColorLabel => 'Couleur';

  @override
  String get noProjectsYet => 'Aucun projet pour l\'instant';

  @override
  String get projectTicketsEmpty =>
      'Aucun ticket dans ce projet pour l\'instant';

  @override
  String get createProject => 'Créer le projet';

  @override
  String projectProgress(int done, int total) {
    return '$done sur $total terminés';
  }

  @override
  String deleteProjectConfirm(String name) {
    return 'Supprimer « $name » ? Ses tickets sont conservés et retirés du projet.';
  }

  @override
  String get projectStatusActive => 'Actif';

  @override
  String get projectStatusCompleted => 'Terminé';

  @override
  String get projectStatusArchived => 'Archivé';

  @override
  String get markProjectCompleted => 'Marquer comme terminé';

  @override
  String get markProjectActive => 'Marquer comme actif';

  @override
  String get archiveProject => 'Archiver';

  @override
  String get restoreProject => 'Restaurer';

  @override
  String get relations => 'Relations';

  @override
  String get relateTo => 'Lier à';

  @override
  String get relationSubIssueOf => 'Sous-tâche de…';

  @override
  String get relationParentOf => 'Parent de…';

  @override
  String get relationBlockedBy => 'Bloqué par…';

  @override
  String get relationBlocking => 'Bloque…';

  @override
  String get relationRelatedTo => 'Lié à…';

  @override
  String get relationDuplicateOf => 'Doublon de…';

  @override
  String get relationGroupParent => 'Parent';

  @override
  String get relationGroupSubIssues => 'Sous-tâches';

  @override
  String get relationGroupBlockedBy => 'Bloqué par';

  @override
  String get relationGroupBlocking => 'Bloque';

  @override
  String get relationGroupRelated => 'Lié';

  @override
  String get relationGroupDuplicateOf => 'Doublon de';

  @override
  String get relationGroupDuplicatedBy => 'Dupliqué par';

  @override
  String get copyId => 'Copier l\'ID';

  @override
  String get ticketIdCopied => 'ID du ticket copié';

  @override
  String get searchTicketsHint => 'Rechercher des tickets…';

  @override
  String get noMatchingTickets => 'Aucun ticket correspondant';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String agentsRunningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agents en cours',
      one: '1 agent en cours',
    );
    return '$_temp0';
  }

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PR en attente',
      one: '1 PR en attente',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos dépôts',
      one: '1 dépôt',
    );
    return '$_temp0 de votre revue sur $_temp1';
  }

  @override
  String get manageWorkspacesSubtitle =>
      'Renommez un espace de travail et changez sa marque — sélectionnez-en un à gauche pour le modifier.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count espaces de travail',
      one: '1 espace de travail',
      zero: 'Aucun espace de travail',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos dépôts',
      one: '1 dépôt',
      zero: 'Aucun dépôt',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents agents',
      one: '1 agent',
      zero: '0 agent',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'Identité';

  @override
  String get uploadImage => 'Téléverser une image';

  @override
  String get failedToSaveLogo =>
      'Échec de l\'enregistrement du logo. Vérifiez que l\'application peut lire le fichier sélectionné.';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG ou GIF jusqu\'à 2 Mo. Sinon, nous utiliserons l\'initiale de l\'espace de travail.';

  @override
  String get workspaceNameFieldHelp =>
      'Affiché dans le sélecteur, le fil d\'Ariane et sur chaque écran.';

  @override
  String get dangerZone => 'Zone sensible';

  @override
  String get deleteThisWorkspace => 'Supprimer cet espace de travail';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Supprime définitivement $name, ses connexions de dépôts, ses agents et sa mémoire. Cette action est irréversible.';
  }

  @override
  String get discard => 'Abandonner';

  @override
  String discardChangesQuestion(String name) {
    return 'Abandonner les modifications non enregistrées de $name ?';
  }

  @override
  String get workspaceUpdated => 'Espace de travail mis à jour';

  @override
  String get editTitle => 'Modifier le titre';

  @override
  String get editDescription => 'Modifier la description';

  @override
  String get addDescription => 'Ajouter une description';

  @override
  String get prTitlePlaceholder => 'Titre';

  @override
  String get prBodyPlaceholder => 'Ajoutez une description';

  @override
  String get write => 'Écrire';

  @override
  String get overview => 'Aperçu';

  @override
  String get noFilesChanged => 'Aucun fichier modifié';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Aperçu';

  @override
  String get outdated => 'Obsolète';

  @override
  String get outdatedComments => 'Commentaires obsolètes';

  @override
  String outdatedCountLabel(int count) {
    return '$count obsolète(s)';
  }

  @override
  String get prTemplateLabel => 'Modèle';

  @override
  String get prTemplateDefault => 'Par défaut';

  @override
  String get addReviewers => 'Ajouter des relecteurs';

  @override
  String get addAssignees => 'Ajouter des assignés';

  @override
  String get searchUsers => 'Rechercher des personnes…';

  @override
  String get searchReviewers => 'Rechercher des personnes et des équipes…';

  @override
  String get usersSectionLabel => 'Personnes';

  @override
  String get userStatusBusy => 'Occupé';

  @override
  String get teamsSectionLabel => 'Équipes';

  @override
  String get suggestedReviewers => 'Réviseurs suggérés';

  @override
  String get noMatchingUsers => 'Aucune personne correspondante';

  @override
  String get noMatchingReviewers => 'Aucun résultat';

  @override
  String get requiredByCodeOwners => 'Requis par les propriétaires de code';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'via $login';
  }

  @override
  String get team => 'Équipe';

  @override
  String get markdownBold => 'Gras';

  @override
  String get markdownItalic => 'Italique';

  @override
  String get markdownHeading => 'Titre';

  @override
  String get markdownBulletList => 'Liste à puces';

  @override
  String get markdownChecklist => 'Liste de tâches';

  @override
  String get markdownCode => 'Code';

  @override
  String get markdownLink => 'Lien';

  @override
  String get markdownQuote => 'Citation';

  @override
  String get markdownSupported => 'Markdown est pris en charge';

  @override
  String get markdownAttachImages => 'Cliquez pour ajouter des images';

  @override
  String failedToUpdateTitle(String error) {
    return 'Échec de la mise à jour du titre : $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Échec de la mise à jour de la description : $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Échec de la mise à jour des relecteurs : $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Échec de la mise à jour des assignés : $error';
  }

  @override
  String get discardChangesConfirm => 'Abandonner vos modifications ?';

  @override
  String get newPr => 'Nouvelle PR';

  @override
  String get openPullRequest => 'Ouvrir une pull request';

  @override
  String get composePrSubtitle =>
      'Depuis une branche que vous avez poussée — sans agents ni tickets';

  @override
  String get createAsDraft => 'Créer en brouillon';

  @override
  String get composePrNoRepo => 'Aucun dépôt GitHub sélectionné';

  @override
  String get composePrNoRepoHint =>
      'Sélectionnez un espace de travail avec un dépôt lié à GitHub pour ouvrir une pull request.';

  @override
  String get composePrPickBranches =>
      'Choisissez une branche de base et une branche à comparer pour prévisualiser les modifications.';

  @override
  String get composePrNothingToCompare =>
      'Il n\'y a aucune différence entre ces branches.';

  @override
  String get repository => 'Dépôt';

  @override
  String get baseBranchLabel => 'Base';

  @override
  String get compareBranchLabel => 'Comparer';

  @override
  String get selectBranch => 'Sélectionner une branche';

  @override
  String get navMeetings => 'Réunions';

  @override
  String get meetingsNoWorkspace =>
      'Sélectionnez un espace de travail pour voir les réunions.';

  @override
  String get meetingsEmpty => 'Aucune réunion pour l\'instant';

  @override
  String get meetingsEmptyHint =>
      'Enregistrez votre première réunion — l\'audio reste sur cet appareil et l\'agent la transforme en notes, décisions et actions à suivre.';

  @override
  String get meetingNotesHint =>
      'Prenez des notes rapides — l\'agent les développera après la réunion.';

  @override
  String get meetingSpeakerMe => 'Vous';

  @override
  String get meetingStatusRecording => 'Enregistrement';

  @override
  String get meetingStatusProcessing => 'Traitement';

  @override
  String get meetingStatusDone => 'Terminé';

  @override
  String get meetingStatusFailed => 'Échec';

  @override
  String get meetingsSubtitle =>
      'Capturé et transcrit sur cet appareil, puis résumé par un agent.';

  @override
  String get meetingsRecordMeeting => 'Enregistrer la réunion';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count en cours de traitement',
      one: '1 en cours de traitement',
    );
    return '$_temp0';
  }

  @override
  String meetingsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count réunions',
      one: '1 réunion',
      zero: 'Aucune réunion',
    );
    return '$_temp0';
  }

  @override
  String get meetingsLedgerOpenActions => 'Actions ouvertes';

  @override
  String get meetingsLedgerDecisions => 'Décisions';

  @override
  String get meetingsLiveOpen => 'Ouvrir l\'enregistrement';

  @override
  String get meetingTemplateShort => 'Modèle';

  @override
  String get meetingsStatThisWeek => 'Cette semaine';

  @override
  String get meetingsStatRecorded => 'Enregistré';

  @override
  String get meetingsFilterAll => 'Toutes';

  @override
  String get meetingsFilterDone => 'Terminées';

  @override
  String get meetingsFilterProcessing => 'En cours';

  @override
  String get meetingsSearchHint => 'Filtrer par titre, personne, application…';

  @override
  String get meetingsBucketToday => 'Aujourd\'hui';

  @override
  String get meetingsBucketYesterday => 'Hier';

  @override
  String get meetingsBucketEarlierThisWeek => 'Plus tôt cette semaine';

  @override
  String get meetingsBucketLastWeek => 'La semaine dernière';

  @override
  String get meetingsBucketOlder => 'Plus ancien';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count décisions',
      one: '1 décision',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total tâches';
  }

  @override
  String get meetingsEnhancedPill => 'enrichi';

  @override
  String get meetingsTranscribing => 'transcription et synthèse…';

  @override
  String get meetingsOpenAction => 'Ouvrir';

  @override
  String get meetingsStopProcessing => 'Arrêter';

  @override
  String get meetingsStillTranscribing =>
      'Transcription en cours — le résumé apparaîtra une fois terminé.';

  @override
  String get meetingsNoMatch => 'Aucune réunion ne correspond';

  @override
  String get meetingsNoMatchHint =>
      'Essayez un autre filtre ou terme de recherche.';

  @override
  String get meetingBackAllMeetings => 'Toutes les réunions';

  @override
  String get meetingReRunSummary => 'Relancer le résumé';

  @override
  String get meetingExport => 'Exporter';

  @override
  String get meetingAugmentingBanner =>
      'Enrichissement de vos notes à partir de la transcription — extraction des décisions et des tâches…';

  @override
  String get meetingTabNotes => 'Notes';

  @override
  String get meetingTabTranscript => 'Transcription';

  @override
  String get meetingTabActionItems => 'Tâches';

  @override
  String get meetingTabDecisions => 'Décisions';

  @override
  String get meetingNotesEnhancedToggle => 'Enrichies';

  @override
  String get meetingNotesYoursToggle => 'Vos notes';

  @override
  String get meetingEnhancedByAgent =>
      'Enrichi par l\'agent · à partir de la transcription';

  @override
  String get meetingEnhancedPending =>
      'L\'agent travaille encore sur ce résumé.';

  @override
  String get meetingNotesEmpty => 'Pas encore de notes enrichies.';

  @override
  String get meetingNotesSavedLocally => 'Enregistré localement';

  @override
  String get meetingNotesSaving => 'Enregistrement…';

  @override
  String get meetingViewFullTranscript => 'Voir la transcription complète';

  @override
  String get meetingTranscriptSearchHint => 'Rechercher dans la transcription…';

  @override
  String get meetingSpeakerEveryone => 'Tout le monde';

  @override
  String get meetingSpeakerOthers => 'Autres';

  @override
  String get meetingTranscriptEmpty => 'Pas encore de transcription.';

  @override
  String get meetingActionItemsEmpty => 'Aucune tâche extraite.';

  @override
  String get meetingActionItemFrom => 'de cette réunion';

  @override
  String get meetingCreateTicket => 'Créer un ticket';

  @override
  String meetingTicketCreated(String key) {
    return 'Ticket $key créé et envoyé.';
  }

  @override
  String get meetingTicketFailed => 'Impossible de créer le ticket.';

  @override
  String get meetingDecisionsEmpty => 'Aucune décision consignée.';

  @override
  String get meetingEditTitle => 'Modifier le titre';

  @override
  String get meetingTitleLabel => 'Titre';

  @override
  String get meetingAddActionItem => 'Ajouter une action';

  @override
  String get meetingEditActionItem => 'Modifier l\'action';

  @override
  String get meetingDeleteActionItem => 'Supprimer l\'action';

  @override
  String get meetingActionItemContentLabel => 'Action';

  @override
  String get meetingActionItemContentHint => 'Que faut-il faire ?';

  @override
  String get meetingActionItemOwnerLabel => 'Responsable';

  @override
  String get meetingActionItemOwnerHint => 'Qui s\'en charge ? (facultatif)';

  @override
  String get meetingAddDecision => 'Ajouter une décision';

  @override
  String get meetingEditDecision => 'Modifier la décision';

  @override
  String get meetingDeleteDecision => 'Supprimer la décision';

  @override
  String get meetingDecisionContentLabel => 'Décision';

  @override
  String get meetingDecisionContentHint => 'Qu\'a-t-on décidé ?';

  @override
  String get meetingReRunStarted =>
      'Relance de la synthèse sur la transcription…';

  @override
  String get meetingReRunNoTranscript =>
      'Aucune transcription à résumer pour l\'instant.';

  @override
  String get meetingExportCopied =>
      'Notes copiées dans le presse-papiers au format Markdown.';

  @override
  String get meetingExportSaved => 'Réunion exportée.';

  @override
  String meetingExportFailed(String error) {
    return 'Échec de l\'export : $error';
  }

  @override
  String get meetingExportNothing => 'Rien à exporter pour l\'instant.';

  @override
  String get meetingPlaybackPlay => 'Lire';

  @override
  String get meetingPlaybackPause => 'Pause';

  @override
  String get meetingPlaybackUnavailable =>
      'La lecture audio est indisponible sur cet appareil.';

  @override
  String get meetingDetectedTitle => 'Réunion détectée';

  @override
  String meetingDetectedSubtitle(String label) {
    return 'Il semble que « $label » soit en cours. L\'enregistrer ?';
  }

  @override
  String get meetingDetectedSubtitleGeneric =>
      'Il semble qu\'une réunion soit en cours. L\'enregistrer ?';

  @override
  String get meetingDetectedRecord => 'Enregistrer';

  @override
  String get meetingDetectedDismiss => 'Ignorer';

  @override
  String get meetingAutoStopTitle =>
      'Cette réunion semble terminée. Arrêter l\'enregistrement ?';

  @override
  String get meetingAutoStopStop => 'Arrêter';

  @override
  String get meetingAutoStopKeep => 'Continuer l\'enregistrement';

  @override
  String get meetingAutoDetect => 'Détection automatique des réunions';

  @override
  String get meetingAutoDetectDescription =>
      'Surveille l\'agenda et les applis de visioconférence, et propose d\'enregistrer au début d\'une réunion.';

  @override
  String get meetingsRecordingCrumb => 'Enregistrement…';

  @override
  String get meetingRecordTitleHint => 'Titre de la réunion';

  @override
  String get meetingRecordTappingLabel => 'Captation :';

  @override
  String get meetingRecordMic => 'Micro';

  @override
  String get meetingRecordSystemAudio => 'Audio système';

  @override
  String get meetingRecordPause => 'Pause';

  @override
  String get meetingRecordResume => 'Reprendre';

  @override
  String get meetingRecordStop => 'Arrêter et résumer';

  @override
  String get meetingRecordYourNotes => 'Vos notes';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Écrivez pendant que vous écoutez. Quelques fragments suffisent — après l\'arrêt, l\'agent les développe à partir de la transcription.';

  @override
  String get meetingRecordLiveTranscript => 'Transcription en direct';

  @override
  String get meetingRecordDecoding => 'décodage sur l\'appareil';

  @override
  String get meetingRecordListening =>
      'Écoute… la parole apparaîtra ici dans une seconde ou deux, étiquetée Vous / Autres.';

  @override
  String get meetingRecordPausedHint =>
      'En pause — l\'audio est ignoré jusqu\'à la reprise.';

  @override
  String get meetingRecordNotActive => 'Aucun enregistrement actif.';

  @override
  String get meetingHudRecording => 'enregistrement';

  @override
  String get meetingHudPaused => 'en pause';

  @override
  String get meetingHudOpen => 'Ouvrir';

  @override
  String get meetingHudStop => 'Arrêter';

  @override
  String get meetingToolbarPopOut => 'Détacher';

  @override
  String get meetingToolbarHoldToStop =>
      'Maintenez pour arrêter l\'enregistrement';

  @override
  String get meetingToolbarSemanticLabel =>
      'Barre d\'enregistrement de réunion';

  @override
  String get orchestrate => 'Orchestrer';

  @override
  String get orchestrationUnavailable => 'Orchestration indisponible';

  @override
  String get orchestrationApprove => 'Approuver le plan';

  @override
  String get orchestrationReject => 'Rejeter';

  @override
  String get orchestrationCancel => 'Annuler l\'orchestration';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count rôles — $hires nouvelles recrues';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count sous-tickets';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Coût estimé : $amount \$';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total sous-tickets terminés';
  }

  @override
  String get orchestrationStatusProposed => 'Proposé';

  @override
  String get orchestrationStatusApproved => 'Approuvé';

  @override
  String get orchestrationStatusExecuting => 'En cours';

  @override
  String get orchestrationStatusSynthesizing => 'Synthèse';

  @override
  String get orchestrationStatusCompleted => 'Terminé';

  @override
  String get orchestrationStatusFailed => 'Échoué';

  @override
  String get orchestrationStatusCancelled => 'Annulé';

  @override
  String get messageFailed => 'Échec du run';

  @override
  String get turnLimitReached =>
      'Limite de tours atteinte — répondez pour continuer';

  @override
  String get retried => 'Relancé';

  @override
  String replyingTo(String name) {
    return 'en réponse à $name';
  }

  @override
  String get silenceTimeoutLabel => 'Délai de silence (minutes)';

  @override
  String get silenceTimeoutHint =>
      'p. ex. 15 — arrête un run après ce délai sans sortie';

  @override
  String get capabilityJsonMode => 'Mode JSON';

  @override
  String get capabilityModelSelection => 'Choix du modèle';

  @override
  String get transcriptThinking => 'Réflexion…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'A réfléchi pendant $duration';
  }

  @override
  String get transcriptStatusMakingEdits => 'Modifications en cours…';

  @override
  String get transcriptStatusReadingFiles => 'Lecture des fichiers…';

  @override
  String get transcriptStatusSearching => 'Recherche dans le code…';

  @override
  String get transcriptStatusRunningCommands => 'Exécution de commandes…';

  @override
  String get transcriptStatusResponding => 'Réponse…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return 'Exécution de $tool…';
  }

  @override
  String get transcriptInput => 'Entrée';

  @override
  String get transcriptOutput => 'Sortie';

  @override
  String get transcriptErrorLabel => 'Erreur';

  @override
  String get transcriptSandboxBlocked => 'Le bac à sable a bloqué une action';

  @override
  String transcriptShowFullOutput(int kb) {
    return 'Afficher toute la sortie (+$kb Ko)';
  }

  @override
  String transcriptShowAllLines(int count) {
    return 'Afficher les $count lignes';
  }

  @override
  String transcriptShowingFirstLines(int count) {
    return 'Affichage des $count premières lignes';
  }

  @override
  String get transcriptGrepNoMatches => 'Aucune correspondance';

  @override
  String transcriptGrepStats(int matches, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      matches,
      locale: localeName,
      other: '$matches correspondances',
      one: '1 correspondance',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files fichiers',
      one: '1 fichier',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'Personne $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'Renommer l\'\'intervenant';

  @override
  String get meetingRenameSpeakerTitle => 'Renommer l\'\'intervenant';

  @override
  String get meetingSpeakerNameLabel => 'Nom';

  @override
  String get meetingSpeakerSuggestFromCalendar =>
      'Parmi les invités de cette réunion';

  @override
  String get meetingRenameSpeakerApplyAll =>
      'Appliquer à tous les blocs de cet interlocuteur';

  @override
  String get meetingRenameSpeakerScopeHint =>
      'Désactivé, seule la ligne sélectionnée est renommée.';

  @override
  String get meetingLinkEvent => 'Associer à un événement';

  @override
  String get meetingChangeEvent => 'Changer d\'\'événement';

  @override
  String get meetingLinkEventTitle => 'Associer à un événement du calendrier';

  @override
  String get meetingLinkEventSearchHint => 'Rechercher des événements';

  @override
  String get meetingLinkEventEmpty =>
      'Aucun événement de calendrier à proximité';

  @override
  String get meetingUnlinkEvent => 'Supprimer l\'\'association';

  @override
  String get calendarLinkExistingMeeting => 'Associer à une réunion existante';

  @override
  String get calendarLinkMeetingTitle => 'Associer une réunion';

  @override
  String get calendarLinkMeetingSearchHint => 'Rechercher des réunions';

  @override
  String get calendarLinkMeetingEmpty => 'Aucune réunion à associer';

  @override
  String get meetingRenameSpeakerFailed =>
      'Impossible de renommer l\'intervenant';

  @override
  String get calendarLinkUpdateFailed =>
      'Impossible de mettre à jour le lien avec le calendrier';

  @override
  String get rename => 'Renommer';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get meetingSaveVoiceProfileTitle => 'Enregistrer le profil vocal ?';

  @override
  String meetingSaveVoiceProfileBody(String name) {
    return 'Reconnaître $name automatiquement lors des prochaines réunions en enregistrant son empreinte vocale.';
  }

  @override
  String meetingVoiceProfileSaved(String name) {
    return 'Profil vocal enregistré pour $name';
  }

  @override
  String get meetingVoiceProfileSaveFailed =>
      'Impossible d\'enregistrer le profil vocal';

  @override
  String get voiceProfilesSection => 'Profils vocaux';

  @override
  String get voiceProfilesDescription =>
      'Les voix enregistrées sont reconnues automatiquement lors des prochaines réunions.';

  @override
  String get voiceProfilesEmpty =>
      'Aucune voix enregistrée pour le moment. Nommez un intervenant dans une transcription de réunion, puis choisissez « Enregistrer le profil vocal ».';

  @override
  String voiceProfileSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count échantillons',
      one: '1 échantillon',
    );
    return '$_temp0';
  }

  @override
  String get renameVoiceProfileTitle => 'Renommer le profil vocal';

  @override
  String get deleteVoiceProfileTitle => 'Supprimer le profil vocal ?';

  @override
  String deleteVoiceProfileBody(String name) {
    return 'Ne plus reconnaître $name ? Son empreinte vocale enregistrée sera supprimée. Les noms déjà appliqués dans les réunions passées sont conservés.';
  }

  @override
  String get connectedLabel => 'Connecté';

  @override
  String get ideTabGeneral => 'Général';

  @override
  String get ideTabExplorer => 'Explorateur';

  @override
  String get ideTabSourceControl => 'Contrôle de source';

  @override
  String get generalSectionTodos => 'Tâches';

  @override
  String get generalSectionGoals => 'Objectifs';

  @override
  String get goalRunStatusActive => 'Actif';

  @override
  String get goalRunStatusPaused => 'En pause';

  @override
  String get goalRunStatusCompleted => 'Terminé';

  @override
  String get goalRunStatusFailed => 'Échoué';

  @override
  String get goalRunStatusCancelled => 'Annulé';

  @override
  String get goalRunStatusBudgetExhausted => 'Budget épuisé';

  @override
  String goalRunProgress(int run, int max, String cost, String cap) {
    return 'Exécution $run sur $max · $cost sur $cap';
  }

  @override
  String goalRunProgressNoCap(int run, String cost, String cap) {
    return 'Exécution $run · $cost sur $cap';
  }

  @override
  String goalRunDeadline(String deadline) {
    return 'Échéance : $deadline';
  }

  @override
  String get goalRunPause => 'Mettre l\'objectif en pause';

  @override
  String get goalRunResume => 'Reprendre l\'objectif';

  @override
  String goalRunResumeRaise(String cap) {
    return 'Reprendre · plafond à $cap';
  }

  @override
  String get goalRunStop => 'Arrêter l\'objectif';

  @override
  String get generalSectionAgents => 'Agents';

  @override
  String get generalSectionTerminals => 'Terminaux';

  @override
  String get generalTodosEmpty => 'Aucune tâche';

  @override
  String get generalAgentsEmpty => 'Aucun agent en cours';

  @override
  String get generalTerminalsEmpty => 'Aucun terminal ouvert';

  @override
  String get generalSectionBrowsers => 'Navigateurs';

  @override
  String get generalSectionComputers => 'Ordinateurs';

  @override
  String get generalBrowsersEmpty => 'Aucun navigateur ouvert';

  @override
  String get generalComputersEmpty => 'Aucun ordinateur ouvert';

  @override
  String get generalSectionPhones => 'Téléphones';

  @override
  String get generalPhonesEmpty => 'Aucun téléphone ouvert';

  @override
  String get pauseAgent => 'Mettre l\'agent en pause';

  @override
  String get resumeAgent => 'Reprendre l\'agent';

  @override
  String get agentCannotPause =>
      'Cet agent ne peut pas être mis en pause — arrêtez-le à la place.';

  @override
  String get goalClear => 'Effacer l\'objectif';

  @override
  String get undoLabelGoalClear => 'effacer l\'objectif';

  @override
  String get todoStatusPending => 'Non commencé';

  @override
  String get todoStatusInProgress => 'En cours';

  @override
  String get todoStatusCompleted => 'Terminé';

  @override
  String get reorderTodo => 'Réorganiser la tâche';

  @override
  String get focusTerminal => 'Afficher le terminal';

  @override
  String get focusMachine => 'Afficher la machine';

  @override
  String get focusBrowser => 'Afficher le navigateur';

  @override
  String get todoEditorTitle => 'Modifier les tâches';

  @override
  String get todoEditorHint =>
      'Un élément par ligne. Utilisez - [ ] pour à faire, - [~] pour en cours, - [x] pour terminé.';

  @override
  String get todoNeedsText => 'Ajoutez du texte après la commande';

  @override
  String get todoNotFound => 'Aucune tâche correspondante';

  @override
  String get todoCleared => 'Liste des tâches vidée';

  @override
  String get todoNothingToCopy => 'Rien à copier';

  @override
  String todoAdded(String content) {
    return 'Ajouté « $content »';
  }

  @override
  String todoStarted(String content) {
    return 'Démarré « $content »';
  }

  @override
  String todoCompleted(String content) {
    return 'Terminé « $content »';
  }

  @override
  String todoRemoved(String content) {
    return 'Supprimé « $content »';
  }

  @override
  String todoCopied(int count) {
    return '$count éléments copiés';
  }

  @override
  String todoImported(int count) {
    return '$count éléments importés';
  }

  @override
  String todoUnknownSubcommand(String name) {
    return 'Commande de tâche inconnue « $name »';
  }

  @override
  String get terminal => 'Terminal';

  @override
  String get ideCloseTab => 'Fermer l\'onglet';

  @override
  String get ideSplitEditor => 'Diviser l\'éditeur';

  @override
  String get ideSplitRight => 'Diviser à droite';

  @override
  String get ideSplitDown => 'Diviser vers le bas';

  @override
  String get ideSplitLeft => 'Diviser à gauche';

  @override
  String get ideSplitUp => 'Diviser vers le haut';

  @override
  String get ideCloseGroup => 'Fermer le groupe';

  @override
  String get ideCloseOthers => 'Fermer les autres';

  @override
  String get ideCloseToRight => 'Fermer à droite';

  @override
  String get ideCloseSaved => 'Fermer les enregistrés';

  @override
  String get ideCloseAll => 'Tout fermer';

  @override
  String get ideSplit => 'Diviser';

  @override
  String get ideToggleSidebar => 'Afficher/Masquer la barre latérale';

  @override
  String get ideNewTab => 'Ouvrir l\'éditeur';

  @override
  String get ideNewTabMenu => 'Nouvel onglet';

  @override
  String get ideReviewCode => 'Réviser le code';

  @override
  String get ideRevert => 'Rétablir';

  @override
  String get ideRevertConfirmTitle => 'Rétablir les modifications';

  @override
  String ideRevertConfirmMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers',
      one: '1 fichier',
    );
    return 'Rétablir $_temp0 vers HEAD ? Cela annule les modifications de l\'arbre de travail.';
  }

  @override
  String get ideRevertConfirmAction => 'Rétablir';

  @override
  String get ideRevertConfirmCancel => 'Annuler';

  @override
  String get ideRevertUntracked =>
      'Les fichiers non suivis ne peuvent pas être rétablis';

  @override
  String get ideRevertFailed =>
      'Impossible de rétablir les fichiers. L\'arbre de travail de la conversation est peut-être indisponible.';

  @override
  String ideRevertSomeSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers',
      one: '1 fichier',
    );
    return '$_temp0 n\'ont pas pu être rétablis (non suivis).';
  }

  @override
  String get ideViewSource => 'Voir la source';

  @override
  String get ideSearchMatchCase => 'Respecter la casse';

  @override
  String get ideSearchWholeWord => 'Mot entier';

  @override
  String get ideSearchRegex => 'Regex';

  @override
  String get ideSearchFilters => 'Filtres de recherche';

  @override
  String get ideSearchFilesToInclude => 'Fichiers à inclure';

  @override
  String get ideSearchFilesToExclude => 'Fichiers à exclure';

  @override
  String get ideNoOpenTabs => 'Aucun onglet ouvert — utilisez + pour ouvrir';

  @override
  String get ideBrowserAddressHint => 'Saisissez une adresse ou recherchez';

  @override
  String get ideSimpleWebBrowser => 'Navigateur web simple';

  @override
  String get ideWebBrowser => 'Navigateur web';

  @override
  String get ideBrowserEnterUrl =>
      'Saisissez une URL dans la barre d\'adresse pour commencer à naviguer';

  @override
  String get ideCodeServer => 'Éditeur';

  @override
  String ideUnsavedChangesTitle(String fileName) {
    return 'Enregistrer les modifications de $fileName ?';
  }

  @override
  String get ideUnsavedChangesBody =>
      'Vos modifications seront perdues si vous ne les enregistrez pas.';

  @override
  String get ideDontSave => 'Ne pas enregistrer';

  @override
  String get editorAutoSave => 'Enregistrement automatique';

  @override
  String get editorAutoSaveDescription =>
      'Enregistrer automatiquement les modifications dans l\'éditeur intégré.';

  @override
  String get editorAutoSaveOff => 'Désactivé';

  @override
  String get editorAutoSaveAfterDelay => 'Après un délai';

  @override
  String get editorAutoSaveOnFocusChange => 'Au changement de focus';

  @override
  String get ideCodeServerUnavailable =>
      'Code-server n\'est pas disponible sur ce serveur';

  @override
  String get ideCodeServerUnavailableHint =>
      'Installez code-server (coder/code-server) sur l\'hôte du serveur, puis rouvrez l\'éditeur.';

  @override
  String get ideCodeServerInstalling => 'Préparation de l\'éditeur…';

  @override
  String get ideCodeServerOpenInBrowser =>
      'Ouvrir l\'éditeur dans le navigateur';

  @override
  String get ideCodeServerError => 'Impossible d\'ouvrir l\'éditeur';

  @override
  String get paneSuspendedCaption =>
      'Suspendu pour économiser les ressources — il se recharge lorsqu\'il est affiché';

  @override
  String get ideFolderLoadFailed => 'Impossible de charger ce dossier';

  @override
  String get ideFileSearchFailed => 'Impossible de rechercher des fichiers';

  @override
  String get ideSearchInFiles => 'Rechercher dans les fichiers';

  @override
  String get ideNoContentMatches => 'Aucune correspondance';

  @override
  String get ideSourceControlCreatePr => 'Créer une demande de tirage';

  @override
  String ideSourceControlViewPr(int number) {
    return 'Voir la pull request #$number';
  }

  @override
  String get ideSourceControlNoChanges => 'Aucune modification';

  @override
  String get noReposInConversation => 'Aucun dépôt dans cette conversation';

  @override
  String get ideSourceControlNoSpace =>
      'Ouvrez une conversation pour voir ses modifications';

  @override
  String get ideFileLoading => 'Chargement…';

  @override
  String get ideFileBinary => 'Fichier binaire';

  @override
  String get mcpExternalServers => 'Serveurs MCP externes';

  @override
  String get mcpExternalServersDescription =>
      'Connectez-vous à des serveurs MCP externes (GitHub, Sentry, Postgres, automatisation du navigateur). Les serveurs configurés pour Claude, Cursor, VS Code et d\'autres outils sont détectés automatiquement.';

  @override
  String get mcpApprovalMode => 'Approbation des outils';

  @override
  String get mcpApprovalModeDescription =>
      'Quelles actions s\'exécutent sans demander. Les lectures sont toujours autorisées ; les niveaux supérieurs demandent confirmation.';

  @override
  String get mcpApprovalAlwaysAsk => 'Toujours demander';

  @override
  String get mcpApprovalWrite => 'Approuver les écritures';

  @override
  String get mcpApprovalYolo => 'Tout approuver';

  @override
  String get mcpNoExternalServers => 'Aucun serveur MCP externe détecté.';

  @override
  String get mcpAuthorize => 'Autoriser';

  @override
  String get mcpReconnect => 'Reconnecter';

  @override
  String get mcpExternalConnectionsNote =>
      'Les serveurs MCP externes s\'exécutent sur le serveur d\'agents (partagé entre le bureau et le web). L\'autorisation des serveurs OAuth n\'est disponible que sur le bureau.';

  @override
  String get mcpStatusConnected => 'Connecté';

  @override
  String get mcpStatusConnecting => 'Connexion…';

  @override
  String get mcpStatusNeedsAuth => 'Autorisation requise';

  @override
  String get mcpStatusFailed => 'Échec';

  @override
  String get mcpStatusCircuitOpen => 'En pause';

  @override
  String get mcpStatusDisabled => 'Désactivé';

  @override
  String get providersAndModels => 'Fournisseurs et modèles';

  @override
  String get providersAndModelsDescription =>
      'Listez chaque fournisseur que l\'agent intégré peut utiliser — définissez une clé API ou connectez-vous via le navigateur, consultez les modèles et les tarifs de chaque fournisseur connecté, et contrôlez quels fournisseurs cet espace de travail peut utiliser.';

  @override
  String get syncNow => 'Synchroniser';

  @override
  String syncNowResult(int applied, int failed) {
    return 'Synchronisation terminée — $applied appliqué(s), $failed échec(s)';
  }

  @override
  String syncNowFailed(String error) {
    return 'Échec de la synchronisation : $error';
  }

  @override
  String get denied => 'Refusé';

  @override
  String get allowed => 'Autorisé';

  @override
  String allowProviderSemantic(String provider) {
    return 'Autoriser $provider';
  }

  @override
  String enabledViaEnv(String key) {
    return 'Activé via $key';
  }

  @override
  String costPerMillion(String input, String output) {
    return '$input / $output par 1M';
  }

  @override
  String contextTokens(String tokens) {
    return 'contexte $tokens';
  }

  @override
  String get usageAndCost => 'Utilisation et coût';

  @override
  String get usageAndCostDescription =>
      'Dépenses de vos agents sur les 7 derniers jours, d\'après les coûts d\'exécution observés.';

  @override
  String get noUsageYet => 'Aucune utilisation enregistrée pour l\'instant.';

  @override
  String get spentThisWeek => 'dépensés cette semaine';

  @override
  String get subscriptionUsage => 'Utilisation de l\'abonnement';

  @override
  String get subscriptionUsageUnavailable => 'Indisponible';

  @override
  String get subscriptionUsageExhausted => 'Quota épuisé';

  @override
  String get subscriptionUsageSignInRequired => 'Reconnectez-vous';

  @override
  String get subscriptionUsageSignInExpired =>
      'Connexion expirée, renouvelée à la prochaine exécution';

  @override
  String get subscriptionUsagePartiallyAvailable => 'Partiellement disponible';

  @override
  String resetsIn(String duration) {
    return 'Réinitialisation dans $duration';
  }

  @override
  String get feedbackHelpful => 'C\'était utile';

  @override
  String get feedbackNotHelpful => 'Ce n\'était pas utile';

  @override
  String get modeChat => 'Discussion';

  @override
  String get modePlan => 'Plan';

  @override
  String get modeReview => 'Revue';

  @override
  String get modeOrchestrate => 'Orchestration';

  @override
  String get editorTheme => 'Thème de l\'éditeur';

  @override
  String get editorThemeDescription =>
      'Importez un thème de couleurs VS Code pour que le diff et l\'éditeur intégrés correspondent à votre IDE.';

  @override
  String get editorThemePasteHint =>
      'Collez le contenu d\'un fichier de thème de couleurs VS Code';

  @override
  String get editorThemeImported => 'Thème importé';

  @override
  String get editorThemeInvalid =>
      'Cela ne ressemble pas à un thème VS Code valide';

  @override
  String get importTheme => 'Importer le thème';

  @override
  String get clearTheme => 'Effacer le thème';

  @override
  String get openInDiffViewer => 'Ouvrir dans la visionneuse de diff';

  @override
  String get shellCommand => 'Commande';

  @override
  String get shellOutput => 'Sortie';

  @override
  String get revertToHere => 'Revenir ici';

  @override
  String get revertConfirmBody =>
      'Masquer les messages après ce point et annuler les modifications de fichiers de l\'agent jusqu\'à ce tour ? Vous pourrez annuler cette action.';

  @override
  String get revert => 'Revenir';

  @override
  String get revertedToHere => 'Revenu à ce point';

  @override
  String get nothingToRevert => 'Rien à annuler';

  @override
  String get undoRevert => 'Annuler le retour';

  @override
  String get revertUndone => 'Retour annulé';

  @override
  String get systemBehavior => 'Comportement du système';

  @override
  String get keepAwakeTitle =>
      'Garder l\'ordinateur éveillé pendant l\'exécution des agents';

  @override
  String get keepAwakeOnSubtitle =>
      'L\'ordinateur ne se met pas en veille pendant qu\'un agent travaille';

  @override
  String get keepAwakeOffSubtitle =>
      'L\'ordinateur peut se mettre en veille même pendant qu\'un agent travaille';

  @override
  String get syncEngineSectionTitle => 'Moteur de synchronisation';

  @override
  String get syncEngineDescription =>
      'Les tickets, la messagerie et les notes se mettent à jour en direct via de petites modifications incrémentielles plutôt que des instantanés complets. Désactiver un interrupteur fait repasser ce magasin en mode instantané complet — rechargez l\'application pour que le changement prenne effet.';

  @override
  String get syncEngineTicketsTitle => 'Tickets';

  @override
  String get syncEngineMessagingTitle => 'Messagerie';

  @override
  String get syncEngineNotesTitle => 'Notes';

  @override
  String get syncEngineOnSubtitle => 'La synchronisation en direct est active';

  @override
  String get syncEngineOffSubtitle => 'Synchronisation par instantané complet';

  @override
  String get spaces => 'Espaces';

  @override
  String get spacesHomeDescription =>
      'Choisissez un espace dans la liste, ou démarrez-en un nouveau.';

  @override
  String get noSpacesYet => 'Aucun espace pour l\'instant';

  @override
  String get newSpace => 'Nouveau espace';

  @override
  String get spaceName => 'Nom du espace';

  @override
  String get spaceReposHint => 'Dépôts à inclure';

  @override
  String get ideSourceControl => 'Contrôle de code source';

  @override
  String get stagedChanges => 'Modifications indexées';

  @override
  String get changes => 'Modifications';

  @override
  String get stageFile => 'Indexer';

  @override
  String get unstageFile => 'Désindexer';

  @override
  String get stageAll => 'Tout indexer';

  @override
  String get unstageAll => 'Tout désindexer';

  @override
  String get stageChangesToCommit => 'Indexez des modifications à valider';

  @override
  String get syncToPrHead => 'Récupérer les derniers commits de la PR';

  @override
  String get syncedToPrHead => 'Synchronisé avec les derniers commits de la PR';

  @override
  String get syncPrHeadDirty =>
      'Validez ou abandonnez vos modifications avant de synchroniser';

  @override
  String get syncPrHeadFailed => 'Échec de la synchronisation avec la PR';

  @override
  String get spaceLabel => 'Espace';

  @override
  String get keybindingNewSpace => 'Nouveau espace';

  @override
  String get keybindingCreateANewSpaceDescription => 'Créer un nouveau espace';

  @override
  String get jumpToLatest => 'Aller au plus récent';

  @override
  String get streaming => 'En cours';

  @override
  String get newMessages => 'Nouveaux';

  @override
  String get copyLink => 'Copier le lien';

  @override
  String get linkCopied => 'Lien copié';

  @override
  String get agentResponding => 'Agent en cours';

  @override
  String get agentFinished => 'Agent terminé';

  @override
  String get harnessConnectProviderForModels =>
      'Connectez un fournisseur pour voir les modèles.';

  @override
  String get providerSignOut => 'Se déconnecter';

  @override
  String get providerWaitingForDeviceCode =>
      'En attente de la confirmation du code dans votre navigateur…';

  @override
  String get providerDeviceCodeHint =>
      'Vérifiez que ce code correspond à celui affiché dans votre navigateur, puis approuvez.';

  @override
  String get providerPlanUsageLoading =>
      'Vérification de l\'utilisation du forfait…';

  @override
  String get providerPlanUsageUnavailable =>
      'Ce forfait n\'a pas communiqué d\'utilisation.';

  @override
  String providerRemoveKeyConfirmTitle(String provider) {
    return 'Supprimer la clé API $provider ?';
  }

  @override
  String providerRemoveKeyConfirmBody(String provider) {
    return 'La clé enregistrée est supprimée et ne pourra plus être affichée. Les agents utilisant les modèles $provider cesseront de fonctionner jusqu’à ce que vous en colliez une nouvelle.';
  }

  @override
  String providerRemoveConfirmTitle(String provider) {
    return 'Supprimer $provider ?';
  }

  @override
  String providerRemoveConfirmBody(String provider) {
    return 'Le fournisseur et sa clé enregistrée sont supprimés. Les agents liés à ses modèles cesseront de fonctionner.';
  }

  @override
  String get providerApiKeyHint => 'Collez une clé API';

  @override
  String get providerApiKeyStoredHint =>
      'Collez une autre clé API pour l\'ajouter';

  @override
  String get providerAddAnotherAccount => 'Ajouter un autre compte';

  @override
  String get providerActiveBadge => 'Actif';

  @override
  String get providerOauthAccountFallback => 'Compte OAuth';

  @override
  String get providerApiKeyFallback => 'Clé API';

  @override
  String get providerRemoveCredentialConfirmTitle =>
      'Supprimer cet identifiant ?';

  @override
  String get providerSignOutAccountConfirmTitle =>
      'Se déconnecter de ce compte ?';

  @override
  String providerCredentialRemoveConfirmBody(String provider) {
    return 'Les agents utilisant $provider basculent sur ses autres clés et comptes. S\'il n\'en reste aucun, ils s\'arrêtent jusqu\'à ce que vous en ajoutiez un.';
  }

  @override
  String get providerBaseUrlHint => 'URL de base (facultatif)';

  @override
  String get customProvidersDescription =>
      'Tout point de terminaison compatible OpenAI ou Anthropic — Ollama, LM Studio, vLLM ou un déploiement privé — avec une clé API facultative.';

  @override
  String get addProvider => 'Ajouter un fournisseur';

  @override
  String get noCustomProviders =>
      'Aucun fournisseur personnalisé pour l\'instant.';

  @override
  String get providerNameLabel => 'Nom';

  @override
  String get apiTypeLabel => 'Type d\'API';

  @override
  String get providerBaseUrlLabel => 'URL de base';

  @override
  String get providerApiKeyOptionalHint => 'Clé API (facultative)';

  @override
  String get dialectOpenAiCompatible => 'Compatible OpenAI';

  @override
  String get dialectAnthropicCompatible => 'Compatible Anthropic';

  @override
  String get removeProviderTooltip => 'Supprimer le fournisseur';

  @override
  String get providerLogInWithBrowser => 'Se connecter via le navigateur';

  @override
  String providerLoginDialogTitle(String provider) {
    return 'Se connecter à $provider';
  }

  @override
  String get providerLabel => 'Fournisseur';

  @override
  String get selectProviderToLogin =>
      'Sélectionnez un fournisseur pour vous connecter';

  @override
  String providerLoginFailed(String error) {
    return 'Échec de la connexion : $error';
  }

  @override
  String get providerWaitingForBrowser =>
      'En attente de votre autorisation dans le navigateur…';

  @override
  String get providerPasteCodeHint =>
      'Ou collez le code depuis votre navigateur';

  @override
  String get providerCompleteLogin => 'Terminer';

  @override
  String get providerConnectedApiKey => 'Connecté via une clé API';

  @override
  String get providerConnectedOauth => 'Connecté';

  @override
  String providerConnectedAccount(String account) {
    return 'Connecté · $account';
  }

  @override
  String get providerLocalReady => 'Local · prêt';

  @override
  String get providerNotConnected => 'Non connecté';

  @override
  String get preparingWorkspace => 'Préparation de l espace de travail…';

  @override
  String provisioningRunningSetupScript(String repo) {
    return 'Exécution du script de configuration pour $repo…';
  }

  @override
  String get repoScriptsTitle => 'Scripts';

  @override
  String get repoScriptsTooltip => 'Configurer les scripts de cycle de vie';

  @override
  String get repoScriptsSetupLabel => 'Script de configuration';

  @override
  String get repoScriptsSetupHelp =>
      'S\'exécute dans le worktree de l\'espace juste après sa création — installation des dépendances, génération de fichiers. Un échec marque l\'espace comme échoué ; une nouvelle tentative le relance.';

  @override
  String get repoScriptsArchiveLabel => 'Script d\'archivage';

  @override
  String get repoScriptsArchiveHelp =>
      'S\'exécute juste avant la suppression du worktree d\'un espace — nettoie les ressources externes au worktree. Un échec ne bloque jamais la suppression.';

  @override
  String get repoScriptsEnvHelp =>
      'S\'exécute via bash depuis le worktree, avec CC_WORKSPACE_PATH (le worktree), CC_ROOT_PATH (la racine du dépôt), CC_SPACE_ID, CC_SPACE_NAME et CC_REPO_NAME définis.';

  @override
  String get repoScriptsSetupPlaceholder => 'ex. pnpm install';

  @override
  String get repoScriptsArchivePlaceholder =>
      'ex. docker compose -p \$CC_SPACE_ID down';

  @override
  String get repoScriptsRecentRuns => 'Exécutions récentes';

  @override
  String get repoScriptsNoRuns => 'Aucune exécution';

  @override
  String get repoScriptsOutput => 'Sortie';

  @override
  String get repoScriptsSaved => 'Scripts enregistrés';

  @override
  String get repoScriptsRunKindSetup => 'Configuration';

  @override
  String get repoScriptsRunKindArchive => 'Archivage';

  @override
  String get repoScriptsRunStatusRunning => 'En cours';

  @override
  String get repoScriptsRunStatusSucceeded => 'Réussi';

  @override
  String get repoScriptsRunStatusFailed => 'Échoué';

  @override
  String get repoScriptsRunStatusTimedOut => 'Expiré';

  @override
  String repoScriptsExitCode(int code) {
    return 'Code de sortie $code';
  }

  @override
  String provisioningCloningRepo(String repo) {
    return 'Clonage de $repo…';
  }

  @override
  String provisioningCheckingOutPr(String repo) {
    return 'Récupération de la pull request dans $repo…';
  }

  @override
  String provisioningSettingUpAgent(String agent) {
    return 'Configuration de l agent $agent…';
  }

  @override
  String get workspacePrepFailed => 'Échec de la préparation';

  @override
  String get workspacePrepStopped => 'Préparation arrêtée';

  @override
  String get stopWorkspacePrep => 'Arrêter la préparation';

  @override
  String get stopWorkspacePrepTooltip =>
      'Arrêter la préparation de cet espace de travail';

  @override
  String get stopWorkspacePrepConfirm =>
      'Arrêter la préparation de cet espace de travail ? Le clonage en cours est abandonné — vous pourrez le relancer ici.';

  @override
  String messageWillSendWhenReady(int count) {
    return '$count message(s) envoyé(s) une fois prêt';
  }

  @override
  String get membersNav => 'Membres';

  @override
  String get membersSettingsDescription =>
      'Personnes ayant accès à cet espace de travail : liste, invitations et journal d\'audit';

  @override
  String get memberRosterLabel => 'Liste des membres';

  @override
  String get memberRepoAccessAction => 'Accès aux dépôts';

  @override
  String memberRepoAccessTitle(String name) {
    return 'Accès aux dépôts de $name';
  }

  @override
  String get roleOwner => 'Propriétaire';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Membre';

  @override
  String get roleViewer => 'Lecteur';

  @override
  String get roleGuest => 'Invité';

  @override
  String get removeMemberTitle => 'Retirer le membre';

  @override
  String removeMemberConfirm(String name) {
    return 'Retirer $name de cet espace de travail ? L\'accès est perdu immédiatement.';
  }

  @override
  String get transferOwnershipAction => 'Transférer la propriété';

  @override
  String get transferOwnershipTitle => 'Transférer la propriété';

  @override
  String transferOwnershipConfirm(String name) {
    return 'Faire de $name le propriétaire de cet espace de travail ? Vous devenez administrateur. Seul un propriétaire peut supprimer l\'espace de travail ou changer le rôle d\'un autre administrateur.';
  }

  @override
  String get transferOwnershipCta => 'Transférer';

  @override
  String get auditTrailLabel => 'Journal d\'audit des autorisations';

  @override
  String get auditTrailDescription =>
      'Chaque autorisation et chaque refus, chaînés par hachage : une entrée modifiée ou supprimée est détectable.';

  @override
  String get auditVerifyChain => 'Vérifier la chaîne';

  @override
  String auditChainIntact(int count) {
    return 'Chaîne intacte — $count entrées vérifiées';
  }

  @override
  String auditChainBroken(int seq, String reason) {
    return 'Chaîne rompue à l\'entrée $seq : $reason';
  }

  @override
  String get auditEmpty => 'Aucune décision enregistrée pour le moment.';

  @override
  String get auditDenied => 'Refusé';

  @override
  String get auditAllowed => 'Autorisé';

  @override
  String auditOnBehalfOf(String user) {
    return 'pour $user';
  }

  @override
  String get policyTemplatesLabel => 'Modèles de politique';

  @override
  String get policyTemplatesDescription =>
      'Appliquez une posture de départ ou transférez-la d\'un espace de travail à un autre.';

  @override
  String get policyTemplateStrict => 'Stricte';

  @override
  String get policyTemplateBalanced => 'Équilibrée';

  @override
  String get policyTemplatePermissive => 'Permissive';

  @override
  String get policyTemplateApply => 'Appliquer';

  @override
  String policyTemplateApplied(int count) {
    return '$count règles appliquées';
  }

  @override
  String get policyExport => 'Copier la politique';

  @override
  String get policyExported => 'Politique copiée dans le presse-papiers';

  @override
  String get policyImport => 'Coller la politique';

  @override
  String policyImported(int count) {
    return '$count règles importées';
  }

  @override
  String get approveAndRemember => 'Approuver pour 8 heures';

  @override
  String get approveAndRememberTooltip =>
      'Approuve cette action et cesse de demander pour des actions similaires dans cet espace pendant 8 heures. L\'autorisation expire d\'elle-même.';

  @override
  String get unknownUserLabel => 'Utilisateur inconnu';

  @override
  String get inviteMember => 'Inviter un membre';

  @override
  String get inviteRepoAccessHeader => 'Accès aux dépôts';

  @override
  String get inviteRepoAccessExplainer =>
      'Seuls les dépôts cochés sont partagés avec la personne invitée, au niveau choisi. Tout le reste reste masqué.';

  @override
  String get grantLevelRead => 'Lecture';

  @override
  String get grantLevelReview => 'Relecture';

  @override
  String get grantLevelWrite => 'Écriture';

  @override
  String get inviteExpiryLabel => 'Expire dans';

  @override
  String get expiryOneDay => '1 jour';

  @override
  String get expirySevenDays => '7 jours';

  @override
  String get expiryThirtyDays => '30 jours';

  @override
  String get createInviteAction => 'Créer l\'invitation';

  @override
  String get inviteOneTimeCodeLabel => 'Code à usage unique';

  @override
  String get inviteCodeShownOnce =>
      'Ce code n\'est affiché qu\'une seule fois — copiez-le maintenant.';

  @override
  String get inviteLinkLabel => 'Lien d\'invitation';

  @override
  String get inviteRedeemHint =>
      'Partagez le code avec la personne invitée ; elle l\'utilisera avec l\'URL de votre serveur.';

  @override
  String get inviteScanQr => 'Ou scannez pour utiliser l\'invitation';

  @override
  String get inviteLoopbackWarningTitle =>
      'L\'invitation pointe vers une adresse locale';

  @override
  String get inviteLoopbackWarningBody =>
      'Les collaborateurs sur d\'autres machines ne pourront pas atteindre ce serveur. Démarrez un tunnel (Paramètres → Intégrations → Partager ce serveur) ou connectez-vous à votre réseau pour que les utilisateurs distants puissent se connecter.';

  @override
  String get inviteStatusOpen => 'Ouverte';

  @override
  String get inviteStatusUsed => 'Utilisée';

  @override
  String get inviteStatusRevoked => 'Révoquée';

  @override
  String get inviteStatusExpired => 'Expirée';

  @override
  String inviteCreatedTime(String time) {
    return 'Créée $time';
  }

  @override
  String inviteExpiresOn(String date) {
    return 'expire le $date';
  }

  @override
  String get noActivityYet => 'Aucune activité pour le moment';

  @override
  String get couldNotLoadMembers => 'Impossible de charger les membres';

  @override
  String get couldNotLoadInvites => 'Impossible de charger les invitations';

  @override
  String get couldNotLoadActivity => 'Impossible de charger l\'activité';

  @override
  String get yourDevices => 'Vos appareils';

  @override
  String get yourDevicesDescription =>
      'Clients associés à votre compte sur ce serveur.';

  @override
  String get noOwnDevices =>
      'Aucun appareil n\'est encore associé à votre compte';

  @override
  String get renameDeviceTitle => 'Renommer l\'appareil';

  @override
  String get revokeDeviceTitle => 'Révoquer l\'appareil';

  @override
  String revokeDeviceConfirm(String label) {
    return 'Révoquer $label ? L\'appareil est déconnecté immédiatement et ne peut plus joindre ce serveur.';
  }

  @override
  String devicePairedTime(String time) {
    return 'Associé $time';
  }

  @override
  String deviceLastSeenTime(String time) {
    return 'Vu pour la dernière fois $time';
  }

  @override
  String get deviceNeverSeen => 'Jamais connecté';

  @override
  String get profileSectionLabel => 'Profil';

  @override
  String get profileSectionDescription =>
      'Votre apparence pour vos coéquipiers et dans les commits git.';

  @override
  String get displayNameLabel => 'Nom affiché';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get gitAuthorNameLabel => 'Nom d\'auteur git';

  @override
  String get gitAuthorEmailLabel => 'E-mail d\'auteur git';

  @override
  String get profileSaved => 'Profil enregistré';

  @override
  String get presenceOnline => 'En ligne';

  @override
  String get presenceIdle => 'Inactif';

  @override
  String get presenceTyping => 'Écrit…';

  @override
  String get presenceAgentThinking => 'Réflexion';

  @override
  String get presenceAgentRunning => 'En cours';

  @override
  String get presenceAgentBlocked => 'Bloqué';

  @override
  String get presenceAgentDone => 'Terminé';

  @override
  String presenceNameStatus(String name, String status) {
    return '$name — $status';
  }

  @override
  String presenceNameStatusCost(String name, String status, String cost) {
    return '$name — $status ($cost)';
  }

  @override
  String get presenceRailLabel => 'Qui est en ligne';

  @override
  String presencePlusCount(int count) {
    return '+$count';
  }

  @override
  String get dndTooltipOn => 'Activer le mode ne pas déranger';

  @override
  String get dndTooltipOff => 'Désactiver le mode ne pas déranger';

  @override
  String get startPresenting => 'Commencer la présentation';

  @override
  String get stopPresenting => 'Arrêter la présentation';

  @override
  String spotlightPresentingBanner(String name) {
    return '$name présente';
  }

  @override
  String get spotlightLeave => 'Quitter';

  @override
  String typingIndicator(String name) {
    return '$name est en train d\'écrire…';
  }

  @override
  String get ideTabNotes => 'Notes';

  @override
  String get ideSidebarAllViews => 'Toutes les vues';

  @override
  String ideSidebarAllViewsHidden(int count) {
    return 'Toutes les vues ($count masquées)';
  }

  @override
  String get ideSidebarPinView => 'Épingler à la barre latérale';

  @override
  String get ideSidebarUnpinView => 'Détacher de la barre latérale';

  @override
  String get notesEmptyHint =>
      'Ajoutez une note pour toute personne qui reprendra cette conversation…';

  @override
  String get notesEditTooltip => 'Modifier la note';

  @override
  String notesUpdatedBy(String name, String time) {
    return 'Mis à jour par $name · $time';
  }

  @override
  String notesEditingHint(String name) {
    return '$name est en train de modifier';
  }

  @override
  String get notesSaveFailed => 'Impossible d\'enregistrer la note';

  @override
  String get reactionAddTooltip => 'Ajouter une réaction';

  @override
  String reactionToggleTooltip(String emoji) {
    return 'Réagir avec $emoji';
  }

  @override
  String get autonomyDialLabel => 'Autonomie';

  @override
  String get autonomyProposeOnly => 'Proposer uniquement';

  @override
  String get autonomyActWithApproval => 'Agir avec approbation';

  @override
  String get autonomyActFreely => 'Agir librement';

  @override
  String get autonomyDefaultOption => 'Par défaut';

  @override
  String get checkerLabel => 'Vérificateur';

  @override
  String get checkerNone => 'Aucun';

  @override
  String get checkerCaption =>
      'Le vérificateur relit les exécutions terminées des autres agents.';

  @override
  String get takeoverTooltip =>
      'Prendre le contrôle de l\'arborescence de travail';

  @override
  String get takeoverBannerSelf =>
      'Vous avez pris le contrôle de l\'arborescence de travail de cette conversation';

  @override
  String takeoverBannerOther(String name) {
    return '$name a pris le contrôle de l\'arborescence de travail de cette conversation';
  }

  @override
  String get handBackButton => 'Rendre la main';

  @override
  String get handBackDialogTitle =>
      'Rendre la main sur l\'arborescence de travail';

  @override
  String get handBackDialogNoteHint => 'Note facultative pour l\'agent…';

  @override
  String takeoverFailed(String message) {
    return 'Impossible de prendre le contrôle : $message';
  }

  @override
  String handBackFailed(String message) {
    return 'Impossible de rendre la main : $message';
  }

  @override
  String get planStudioTitle => 'Studio de plan';

  @override
  String get plansTitle => 'Plans';

  @override
  String get plansSubtitle => 'Plans actifs, documents de plan et playbooks';

  @override
  String get plansActiveSection => 'Plans actifs';

  @override
  String get plansDocumentsSection => 'Documents de plan';

  @override
  String get plansPlaybooksSection => 'Playbooks';

  @override
  String get plansNoActive => 'Aucun plan actif pour l’instant.';

  @override
  String get plansNoDocuments => 'Aucun document de plan pour l’instant.';

  @override
  String get plansNoPlaybooks => 'Aucun playbook pour l’instant.';

  @override
  String get planNotFound => 'Plan introuvable.';

  @override
  String get planOpenInStudio => 'Ouvrir';

  @override
  String get planNodeTitle => 'Titre';

  @override
  String get planNodeDescription => 'Description';

  @override
  String get planNodeDescriptionHint => 'Ce que cette étape doit faire…';

  @override
  String get planNodeApplyDescription => 'Appliquer';

  @override
  String get planNodeRole => 'Rôle';

  @override
  String get planNodeDependencies => 'Dépend de';

  @override
  String get planNodeDependenciesHint => 'Ajouter une dépendance';

  @override
  String planNodeDependencyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dépendances',
      one: '1 dépendance',
    );
    return '$_temp0';
  }

  @override
  String get planNodeNoDependencies =>
      'Aucune dépendance, cette étape démarre dès le lancement du plan';

  @override
  String get planNodeOutputSchema => 'Schéma de sortie (JSON)';

  @override
  String get planNodeEstimate => 'Estimation';

  @override
  String get planNodeProvenance => 'Provenance';

  @override
  String get planNodeAlreadyExecuted =>
      'Déjà exécuté — la modification bifurque le plan à partir d’ici.';

  @override
  String get planNewNodeTitle => 'Nouvelle étape';

  @override
  String get planEstimateNoHistory => 'Pas encore d’historique';

  @override
  String get planEstimateBlastUnknown => 'Rayon d’impact : inconnu';

  @override
  String get planEstimatePartial => 'partiel';

  @override
  String get planEstimateAction => 'Estimer';

  @override
  String planEstimateDuration(String range) {
    return 'Durée $range';
  }

  @override
  String planEstimateBlastRadius(int files, int symbols) {
    return 'Rayon d’impact : $files fichiers, $symbols symboles';
  }

  @override
  String get planApprove => 'Approuver le plan';

  @override
  String get planApproveSelectedNodes => 'Approuver la sélection';

  @override
  String get planReject => 'Rejeter';

  @override
  String get planCancel => 'Annuler l’exécution';

  @override
  String get planContinueNode => 'Continuer le nœud';

  @override
  String get planTotalNotEstimated => 'Pas encore estimé';

  @override
  String get planBudgetExceeded => 'dépassement de budget';

  @override
  String planBudgetCeiling(String amount) {
    return 'budget ≤ $amount \$';
  }

  @override
  String get planVersionsTitle => 'Versions';

  @override
  String get planNoRevisions => 'Aucune révision pour l’instant.';

  @override
  String get planDiffIdentical => 'Aucun changement.';

  @override
  String get planDiffGoalChanged => 'Objectif modifié';

  @override
  String get planDiffBudgetChanged => 'Budget modifié';

  @override
  String planDiffHeader(int fromRev, int toRev) {
    return 'Changements de v$fromRev à v$toRev';
  }

  @override
  String planDiffAdded(String node) {
    return 'Ajouté $node';
  }

  @override
  String planDiffRemoved(String node) {
    return 'Supprimé $node';
  }

  @override
  String planDiffChanged(String node, String fields) {
    return 'Modifié $node : $fields';
  }

  @override
  String planDiffEdgeAdded(String edge) {
    return 'Arête ajoutée : $edge';
  }

  @override
  String planDiffEdgeRemoved(String edge) {
    return 'Arête supprimée : $edge';
  }

  @override
  String planDiffRoleAdded(String role) {
    return 'Rôle ajouté : $role';
  }

  @override
  String planDiffRoleRemoved(String role) {
    return 'Rôle supprimé : $role';
  }

  @override
  String planDiffRoleReassigned(String role) {
    return 'Rôle réassigné : $role';
  }

  @override
  String planReplanBanner(int approved, int current) {
    return 'Plan replanifié : vous avez approuvé v$approved, il est maintenant v$current. Vérifiez les différences.';
  }

  @override
  String planLiveActualCost(String amount) {
    return 'Coût réel : $amount \$';
  }

  @override
  String get planPlaybookRun => 'Exécuter';

  @override
  String get planPlaybookDelete => 'Supprimer le playbook';

  @override
  String get planPlaybookProposed =>
      'Plan proposé — approuvez-le dans le studio de plan.';

  @override
  String get planPlaybookAnchorTicket => 'Ticket d’ancrage';

  @override
  String get planPlaybookPickTicket => 'Choisir un ticket…';

  @override
  String get planPlaybookProposeRun => 'Proposer le plan';

  @override
  String get planPlaybookRepoHint => 'Un identifiant de dépôt';

  @override
  String get planPlaybookAgentHint => 'Un identifiant d’agent';

  @override
  String planPlaybookRunTitle(String name) {
    return 'Exécuter $name';
  }

  @override
  String planPlaybookParamCount(int count) {
    return '$count paramètres';
  }

  @override
  String get recentLabel => 'Récent';

  @override
  String get cheatSheetTitle => 'Raccourcis clavier';

  @override
  String get cheatSheetGlobal => 'Global';

  @override
  String get cheatSheetThisScreen => 'Cet écran';

  @override
  String get cheatSheetReservedInBrowser => 'Réservé au navigateur';

  @override
  String get keybindingCheatSheet => 'Raccourcis clavier';

  @override
  String get keybindingShowKeyboardShortcutsDescription =>
      'Afficher l\'aide-mémoire des raccourcis clavier pour l\'écran actuel';

  @override
  String get runPlaybookLabel => 'Exécuter le playbook';

  @override
  String get playbooksLabel => 'Playbooks';

  @override
  String get keybindingUndo => 'Annuler';

  @override
  String get keybindingRedo => 'Rétablir';

  @override
  String get keybindingUndoLastActionDescription =>
      'Annuler votre dernière action réversible';

  @override
  String get keybindingRedoLastActionDescription =>
      'Rétablir la dernière action annulée';

  @override
  String get undone => 'Annulé';

  @override
  String get redone => 'Rétabli';

  @override
  String get undoFailed => 'Impossible d\'annuler';

  @override
  String get undoLabelTicketEdit => 'modification de ticket';

  @override
  String get undoLabelMessageEdit => 'modification de message';

  @override
  String get undoLabelTodoStatus => 'statut de tâche';

  @override
  String get inboxTitle => 'Boîte de réception';

  @override
  String get inboxReview => 'Examiner';

  @override
  String get inboxOpen => 'Ouvrir';

  @override
  String get inboxAllCaughtUp => 'Vous êtes à jour';

  @override
  String get inboxGitHubDownTitle => 'GitHub est peut-être hors service';

  @override
  String inboxGitHubDownBody(String status) {
    return 'GitHub signale : $status. Des pull requests peuvent donc manquer dans cette liste au lieu d\'être réellement terminées.';
  }

  @override
  String get inboxGitHubIdentityTitle =>
      'Impossible de confirmer votre compte GitHub';

  @override
  String get inboxGitHubIdentityBody =>
      'La boîte de réception est triée selon votre identité GitHub. Tant qu\'elle n\'est pas chargée, la liste reste vide, même si des pull requests vous attendent.';

  @override
  String get inboxSeverityBlocking => 'Bloqué';

  @override
  String get inboxSeverityWaiting => 'En attente';

  @override
  String get inboxSeverityInfo => 'Info';

  @override
  String get inboxSyncFailed => 'Échec de la synchronisation';

  @override
  String get inboxNeedsYourAttention => 'Requiert votre attention';

  @override
  String get inboxSectionNeedsYourReview => 'En attente de votre revue';

  @override
  String get inboxSectionReturnedToYou => 'Renvoyées vers vous';

  @override
  String get inboxSectionApproved => 'Approuvées';

  @override
  String get inboxSectionDrafts => 'Brouillons';

  @override
  String get inboxSectionWaitingForReviewers => 'En attente de relecteurs';

  @override
  String get inboxSectionMergingAndMerged =>
      'En cours de fusion et récemment fusionnées';

  @override
  String get inboxSectionWaitingForAuthor => 'En attente de l\'auteur';

  @override
  String get inboxColumnTitle => 'Titre';

  @override
  String get inboxColumnChanges => 'Modifications';

  @override
  String get inboxColumnUpdated => 'Mise à jour';

  @override
  String get inboxReviewApproved => 'Approuvée';

  @override
  String get inboxReviewChangesRequested => 'Modifications demandées';

  @override
  String get inboxHeroSubtitle =>
      'Chaque pull request qui vous concerne, triée par prochaine étape.';

  @override
  String inboxHeroNeedsReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests attendent votre revue',
      one: '1 pull request attend votre revue',
    );
    return '$_temp0';
  }

  @override
  String inboxHeroReturnedToYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vous sont revenues',
      one: '1 vous est revenue',
    );
    return '$_temp0';
  }

  @override
  String get optimisticChangeReverted =>
      'Cette modification n\'a pas été enregistrée et a été annulée';

  @override
  String get offlinePendingLabel => 'en attente';

  @override
  String get offlineSyncingLabel => 'synchronisation';

  @override
  String get copyLinkLabel => 'Copier le lien de cette page';

  @override
  String get agentsSectionLabel => 'Agents';

  @override
  String get fleetWorkersTitle => 'Exécuteurs';

  @override
  String get fleetWorkersSubtitle =>
      'Machines disponibles pour exécuter des travaux';

  @override
  String get fleetJobsTitle => 'Travaux';

  @override
  String get fleetJobsSubtitle => 'Travail réparti sur la flotte';

  @override
  String get fleetNoWorkers =>
      'Aucun exécuteur pour l\'instant — une deuxième machine exécutant `cc_worker --server <url>` rejoint la flotte.';

  @override
  String get fleetNoJobs => 'Aucun travail.';

  @override
  String get fleetError => 'Impossible de charger la flotte';

  @override
  String fleetCores(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cœurs',
      one: '1 cœur',
    );
    return '$_temp0';
  }

  @override
  String fleetHeartbeat(String time) {
    return 'Signal $time';
  }

  @override
  String get fleetNoHeartbeat => 'Aucun signal pour l\'instant';

  @override
  String fleetLastErrorLabel(String error) {
    return 'Dernière erreur : $error';
  }

  @override
  String get fleetDrain => 'Drainer';

  @override
  String get fleetResume => 'Reprendre';

  @override
  String get fleetRevoke => 'Révoquer';

  @override
  String get fleetRemove => 'Supprimer';

  @override
  String get fleetRevokeTitle => 'Révoquer l\'exécuteur ?';

  @override
  String fleetRevokeBody(String name) {
    return 'Révoquer $name ? Sa session prend fin et les travaux actifs sont réattribués.';
  }

  @override
  String get fleetRemoveTitle => 'Supprimer l\'exécuteur ?';

  @override
  String fleetRemoveBody(String name) {
    return 'Supprimer $name de la flotte ? Cela supprime son enregistrement.';
  }

  @override
  String get fleetActionFailed => 'Échec de l\'action';

  @override
  String get fleetJobUnassigned => 'Non attribué';

  @override
  String fleetJobAttempts(int attempts, int max) {
    return '$attempts/$max tentatives';
  }

  @override
  String get fleetPlacementReasons => 'Décisions de placement';

  @override
  String get fleetNoPlacements =>
      'Aucune décision de placement pour l\'instant.';

  @override
  String get fleetStatusOnline => 'En ligne';

  @override
  String get fleetStatusDraining => 'Drainage';

  @override
  String get fleetStatusOffline => 'Hors ligne';

  @override
  String get fleetStatusIncompatible => 'Incompatible';

  @override
  String get fleetStatusRevoked => 'Révoqué';

  @override
  String get fleetJobStatusQueued => 'En file d\'attente';

  @override
  String get fleetJobStatusRunning => 'En cours';

  @override
  String get fleetJobStatusSucceeded => 'Réussi';

  @override
  String get fleetJobStatusFailed => 'Échoué';

  @override
  String get fleetJobStatusCancelled => 'Annulé';

  @override
  String get evalsNoSuites => 'Aucune suite d\'évaluation pour l\'instant.';

  @override
  String get evalsError => 'Impossible de charger les évaluations';

  @override
  String get evalsStarterBadge => 'De base';

  @override
  String evalsDefaultBatch(int count) {
    return 'Lot par défaut de $count';
  }

  @override
  String get evalsRecentRuns => 'Exécutions récentes';

  @override
  String get evalsNoRuns => 'Aucune exécution pour l\'instant.';

  @override
  String get evalsPassRate => 'Taux de réussite';

  @override
  String evalsBatchTimes(int count) {
    return '× $count';
  }

  @override
  String evalsTriggeredBy(String who) {
    return 'par $who';
  }

  @override
  String evalsRunFinished(String rate) {
    return 'Évaluation terminée — $rate réussis';
  }

  @override
  String get evalsRunFailed => 'Impossible d\'exécuter la suite';

  @override
  String get evalsRun => 'Exécuter';

  @override
  String get evalsStatusQueued => 'En file d\'attente';

  @override
  String get evalsStatusRunning => 'En cours';

  @override
  String get evalsStatusPassed => 'Réussi';

  @override
  String get evalsStatusFailed => 'Échoué';

  @override
  String get bannerMeetingJoin => 'Rejoindre';

  @override
  String get bannerMeetingRecordAndLink => 'Enregistrer et lier';

  @override
  String get bannerCalendarReconnect => 'Reconnecter';

  @override
  String get bannerView => 'Afficher';

  @override
  String get soundscapeTitle => 'Ambiances sonores';

  @override
  String get soundscapePlay => 'Lire';

  @override
  String get soundscapePause => 'Pause';

  @override
  String get soundscapeMoodLabel => 'Ambiance';

  @override
  String get soundscapeMoodFocus => 'Concentration';

  @override
  String get soundscapeMoodRelax => 'Détente';

  @override
  String get soundscapeMoodSleep => 'Sommeil';

  @override
  String get soundscapeVolumeLabel => 'Volume';

  @override
  String get soundscapeTuneLabel => 'Réglage';

  @override
  String get soundscapeTuneMellow => 'Doux';

  @override
  String get soundscapeTuneBright => 'Brillant';

  @override
  String get soundscapeTuneEnergetic => 'Énergique';

  @override
  String get soundscapeTuneSpacy => 'Planant';

  @override
  String get soundscapeTuneResetHint => 'Touchez deux fois pour réinitialiser';

  @override
  String get soundscapeSceneLabel => 'En cours de lecture';

  @override
  String get soundscapeSceneLoading => 'Réglage de l\'ambiance…';

  @override
  String soundscapeTemperature(int degrees) {
    return '$degrees °C';
  }

  @override
  String get soundscapeLocationLabel => 'Emplacement';

  @override
  String get soundscapeLocationDetecting => 'Détection de l\'emplacement…';

  @override
  String get soundscapeLocationAutoNote =>
      'L\'emplacement est détecté automatiquement à partir de cet espace de travail.';

  @override
  String get soundscapeRefreshWeather => 'Actualiser la météo';

  @override
  String get soundscapeAutoStartLabel => 'Démarrer avec le mode concentration';

  @override
  String get soundscapeAutoStartDescription =>
      'Lire une ambiance sonore automatiquement au démarrage d\'une session de concentration.';

  @override
  String get soundscapeReturnToApp => 'Revenir à l\'application';

  @override
  String get soundscapePopOut => 'Détacher le lecteur';

  @override
  String get discussion => 'Discussion';

  @override
  String get chat => 'Discussion';

  @override
  String get saving => 'Enregistrement…';

  @override
  String get saved => 'Enregistré';

  @override
  String get saveFailed => 'Échec de l\'enregistrement';

  @override
  String get commitAndPush => 'Valider et pousser';

  @override
  String get commit => 'Valider';

  @override
  String get commitAmend => 'Valider (modifier)';

  @override
  String get commitAndSync => 'Valider et synchroniser';

  @override
  String get committed => 'Validé';

  @override
  String get commitAmended => 'Validation modifiée';

  @override
  String get commitFailed => 'Échec de la validation';

  @override
  String get moreCommitActions => 'Plus d\'actions de validation';

  @override
  String get sourceControl => 'Contrôle de source';

  @override
  String fixFindingTitle(String location) {
    return 'Corriger : $location';
  }

  @override
  String get openInEditor => 'Ouvrir dans l\'éditeur';

  @override
  String get commitMessageHint => 'Message de validation';

  @override
  String get pushedToPr => 'Poussé vers la PR';

  @override
  String get pushFailed => 'Échec du push';

  @override
  String get reviewFindings => 'Constats';

  @override
  String get treeLabel => 'Arborescence';

  @override
  String get toggleFileTree =>
      'Afficher ou masquer l\'arborescence des fichiers';

  @override
  String get diffViewSettings => 'Paramètres d\'affichage du diff';

  @override
  String get splitViewLabel => 'Scindé';

  @override
  String get unifiedViewLabel => 'Unifié';

  @override
  String get wrapLines => 'Retour à la ligne';

  @override
  String get shiftClickSelectRange => 'Maj+clic pour sélectionner une plage';

  @override
  String diffFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers',
      one: '1 fichier',
    );
    return '$_temp0';
  }

  @override
  String prComplexityLoc(String loc) {
    return '$loc LOC';
  }

  @override
  String prComplexityTooltipSmall(String files, int minutes) {
    return 'Petite PR — $files, ~$minutes min de relecture';
  }

  @override
  String prComplexityTooltipMedium(String files, int minutes) {
    return 'PR moyenne — $files, prévoyez ~$minutes min de relecture';
  }

  @override
  String prComplexityTooltipLarge(String files) {
    return 'Grosse PR — $files, envisagez de la découper avant la relecture';
  }

  @override
  String get searchInFiles => 'Rechercher dans les fichiers';

  @override
  String get showFileList => 'Afficher la liste des fichiers';

  @override
  String get searchInFilesHintField => 'Rechercher dans les fichiers…';

  @override
  String get searchInFilesHint =>
      'Rechercher dans les fichiers de la pull request';

  @override
  String get searchNoResults => 'Aucun résultat';

  @override
  String searchResultsCount(int count, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '1 résultat',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files fichiers',
      one: '1 fichier',
    );
    return '$_temp0 dans $_temp1';
  }

  @override
  String get discardChangesTitle => 'Annuler les modifications ?';

  @override
  String discardChangesMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers',
      one: '1 fichier',
    );
    return 'Rétablir $_temp0 à HEAD ? Cette action est irréversible.';
  }

  @override
  String get discardAll => 'Tout annuler';

  @override
  String get discardFailed => 'Échec de l\'annulation des modifications';

  @override
  String discardedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers annulés',
      one: '1 fichier annulé',
    );
    return '$_temp0';
  }

  @override
  String discardedWithSkipped(int reverted, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      reverted,
      locale: localeName,
      other: '$reverted fichiers annulés',
      one: '1 fichier annulé',
    );
    return '$_temp0 ; $skipped ignoré(s) (non suivi(s))';
  }

  @override
  String get prWorktreeUnavailable => 'Espace de travail non prêt';

  @override
  String get prWorktreeUnavailableHint =>
      'La préparation des fichiers de la pull request a échoué. Rouvrez la pull request pour réessayer.';

  @override
  String get timestampRelativeLabel => 'Relatif';

  @override
  String get timestampRawLabel => 'Horodatage';

  @override
  String get copyTimestamp => 'Copier l\'horodatage';

  @override
  String get copiedTimestamp => 'Horodatage copié';

  @override
  String get previewDeployment => 'Déploiement de prévisualisation';

  @override
  String previewDeploymentTab(String site) {
    return 'Aperçu : $site';
  }

  @override
  String get askForReview => 'Demander une revue…';

  @override
  String get closePrsConfirmTitle => 'Fermer les pull requests ?';

  @override
  String closePrsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fermer $count pull requests ?',
      one: 'Fermer 1 pull request ?',
    );
    return '$_temp0';
  }

  @override
  String closedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests fermées',
      one: '1 pull request fermée',
    );
    return '$_temp0';
  }

  @override
  String assignedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pull requests assignées',
      one: '1 pull request assignée',
    );
    return '$_temp0';
  }

  @override
  String requestedReviewCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Revue demandée sur $count pull requests',
      one: 'Revue demandée sur 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String bulkActionPartialFailure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actions ont échoué',
      one: '1 action a échoué',
    );
    return '$_temp0';
  }

  @override
  String get diagram => 'Diagramme';

  @override
  String get diagramViewSource => 'Afficher la source';

  @override
  String get diagramHideSource => 'Masquer la source';

  @override
  String diagramPreviewUnavailable(String reason) {
    return 'Aperçu du diagramme indisponible ($reason)';
  }

  @override
  String get planUnavailable => 'Plan indisponible';

  @override
  String planStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étapes',
      one: '1 étape',
    );
    return '$_temp0';
  }

  @override
  String get planApproveAndRun => 'Approuver et lancer';

  @override
  String get planStatusDraft => 'Brouillon';

  @override
  String get planStatusProposed => 'Plan';

  @override
  String get planStatusApproved => 'Plan approuvé';

  @override
  String get planStatusRejected => 'Plan rejeté';

  @override
  String get planStatusSuperseded => 'Plan remplacé';

  @override
  String planRevisionLabel(int revision) {
    return 'Révision $revision';
  }

  @override
  String get adapterEnforcementTitle => 'Ce que cet adaptateur applique';

  @override
  String get enforcementFiltersToolSurface =>
      'Control Center choisit les outils';

  @override
  String get enforcementInterceptsToolCalls =>
      'Chaque appel est contrôlé avant son exécution';

  @override
  String get enforcementObservesCompletionContract =>
      'L\'exécution est tenue à son livrable';

  @override
  String get enforcementNativeToolsInterceptable =>
      'Les outils propres au moteur sont visibles';

  @override
  String get enforcementInProcessToolsSandboxed =>
      'Les outils exécutés dans le processus sont isolés';

  @override
  String get enforcementYes => 'Oui';

  @override
  String get enforcementNo => 'Non';

  @override
  String get adapterEnforcementCaveats => 'Réserves';

  @override
  String get enforcementSummaryModesEnforced => 'Modes appliqués';

  @override
  String get enforcementSummaryModesNotEnforced => 'Modes non appliqués';

  @override
  String enforcementCaveatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count réserves',
      one: '1 réserve',
    );
    return '$_temp0';
  }

  @override
  String get caveatToolSurfaceNotFiltered =>
      'Les modes en lecture seule ne sont pas structurels : Control Center ne peut pas retirer les outils propres à ce moteur.';

  @override
  String get caveatToolCallsNotIntercepted =>
      'Aucun contrôle avant exécution : seuls les appels d\'outils MCP passent par Control Center.';

  @override
  String get caveatNativeToolsBypassControlCenter =>
      'Les outils de fichiers et de shell propres au moteur n\'atteignent jamais Control Center ; le bac à sable du système est leur seule barrière.';

  @override
  String get caveatInProcessToolsUnsandboxed =>
      'Les outils de fichiers exécutés dans le processus sortent du bac à sable, donc la surface d\'outils est la seule limite du système de fichiers.';

  @override
  String get caveatCompletionContractUnobservable =>
      'Control Center ne peut ni relancer ni faire échouer une exécution qui se termine sans produire son livrable.';

  @override
  String get modeDegraded => 'Dégradé';

  @override
  String modeDegradedTooltip(String mode, String adapter) {
    return 'Le mode $mode sur $adapter repose uniquement sur le bac à sable ; les outils de fichiers de l\'agent ne sont pas interceptés.';
  }

  @override
  String get artifactUnavailable => 'Artéfact indisponible';

  @override
  String artifactRevisionLabel(int count) {
    return '$count révisions';
  }

  @override
  String get artifactShowMore => 'Afficher plus';

  @override
  String get artifactShowLess => 'Afficher moins';

  @override
  String get artifactCopy => 'Copier';

  @override
  String get artifactCopied => 'Artéfact copié';

  @override
  String get artifactsTabLabel => 'Artéfacts';

  @override
  String get artifactsEmptyTitle => 'Aucun artéfact';

  @override
  String get artifactsEmptyBody =>
      'Lorsqu\'un agent publie un tableau, un graphique ou un diagramme ici, il apparaît dans cette liste.';

  @override
  String get artifactRevisionPickerLabel => 'Révision';

  @override
  String get artifactRestoreRevision => 'Restaurer cette révision';

  @override
  String get artifactOpenInTab => 'Ouvrir dans un onglet';

  @override
  String get artifactTitleFallback => 'Artéfact';

  @override
  String get providerGenerationLabel => 'Valeurs de génération par défaut';

  @override
  String get providerGenerationHint =>
      'Laissez un champ vide pour utiliser la valeur par défaut du point de terminaison. Chaque modèle publie ses propres limites de sortie et recettes d\'échantillonnage ; d\'autres valeurs peuvent le dégrader.';

  @override
  String get providerMaxTokensLabel => 'Jetons de sortie max';

  @override
  String get addModel => 'Ajouter un modèle';

  @override
  String get modelListTitle => 'Liste des modèles';

  @override
  String get railProvidersGroup => 'Fournisseurs';

  @override
  String get railCustomProvidersGroup => 'Fournisseurs personnalisés';

  @override
  String get editModelSettings => 'Modifier le modèle';

  @override
  String get modelIdLabel => 'ID du modèle';

  @override
  String get modelIdImmutableHint =>
      'L\'identifiant servi par le point de terminaison ; figé une fois listé.';

  @override
  String get contextWindowLabel => 'Fenêtre de contexte';

  @override
  String get inputTypesLabel => 'Types d\'entrée';

  @override
  String get outputTypesLabel => 'Types de sortie';

  @override
  String get modalityText => 'Texte';

  @override
  String get modalityImage => 'Image';

  @override
  String get modalityAudio => 'Audio';

  @override
  String get modalityVideo => 'Vidéo';

  @override
  String get modalityPdf => 'PDF';

  @override
  String get modelOverrideReset => 'Rétablir la détection automatique';

  @override
  String get modelOverrideEdited => 'Modifié';

  @override
  String get manualModelBadge => 'Ajouté à la main';

  @override
  String get modelIdRequired => 'Saisissez un identifiant de modèle.';

  @override
  String get modelTokensInvalid =>
      'Saisissez un nombre entier positif de jetons.';

  @override
  String get removeModelAction => 'Supprimer le modèle';

  @override
  String removeModelConfirmTitle(String model) {
    return 'Supprimer $model ?';
  }

  @override
  String get removeModelConfirmBody =>
      'Le modèle quitte la liste et les agents qui y sont épinglés cessent de fonctionner. Le fournisseur n\'est pas affecté.';

  @override
  String get addModelProviderTitle => 'Ajouter un fournisseur de modèles';

  @override
  String get addModelProviderDescription =>
      'Configurez un point de terminaison d\'API personnalisé et ses modèles.';

  @override
  String get modelListEmptyHint =>
      'Aucun modèle configuré. Ajoutez un modèle pour l\'utiliser dans le chat.';

  @override
  String get addProviderModelsHint =>
      'Les modèles sont récupérés en direct dès que le point de terminaison répond. N\'en ajoutez un à la main que s\'il ne peut pas lister les siens.';

  @override
  String get providerTemperatureLabel => 'Température';

  @override
  String get providerTopPLabel => 'Top-p';

  @override
  String get providerTopKLabel => 'Top-k';

  @override
  String get providerGenerationSaved => 'Valeurs de génération enregistrées';

  @override
  String get providerGenerationInvalid =>
      'Vérifiez les valeurs : les jetons de sortie max et le top-k doivent être positifs, la température 0–2, le top-p 0–1.';

  @override
  String get providerGenerationOverridden => 'Personnalisé';

  @override
  String get spaceFlyoutNeedsInput => 'Réponse attendue';

  @override
  String get spaceFlyoutPreparing => 'Préparation';

  @override
  String get spaceFlyoutSetupFailed => 'Échec de la configuration';

  @override
  String get spaceFlyoutSetupStopped => 'Configuration arrêtée';

  @override
  String get spaceFlyoutNeverRun => 'Aucun agent n\'a encore travaillé ici';

  @override
  String spaceFlyoutContextUsage(String used, String percent) {
    return 'Fenêtre de contexte : $used utilisés, remplie à $percent';
  }

  @override
  String subagentsRunningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sous-agents',
      one: '1 sous-agent',
    );
    return '$_temp0';
  }

  @override
  String get branchNotPushed => 'non poussée';

  @override
  String branchNotOnRemote(String branch) {
    return '« $branch » n’existe que dans cette conversation';
  }

  @override
  String get branchNotOnRemoteHint =>
      'GitHub n’a jamais vu cette branche, une pull request ne peut donc pas encore l’utiliser. La publication pousse les commits déjà présents dans le worktree — les modifications non validées ne sont pas touchées.';

  @override
  String get publishBranch => 'Publier la branche';

  @override
  String branchPublished(String branch) {
    return '« $branch » publiée sur origin';
  }

  @override
  String branchPublishedWithUncommitted(int count) {
    return 'Branche publiée. $count modification(s) non validée(s) n’ont pas été incluses.';
  }

  @override
  String get composePrLoadingBranches =>
      'Chargement des branches depuis GitHub…';

  @override
  String get composePrBranchesFailed =>
      'Impossible de charger les branches depuis GitHub. Saisissez un nom de branche ou vérifiez la connexion GitHub.';

  @override
  String get composePrSubtitleFromSpace =>
      'Depuis la branche de cette conversation — publiez-la d’abord si GitHub ne la connaît pas';

  @override
  String get obsTabInsights => 'Aperçu';

  @override
  String get obsTabLive => 'En direct';

  @override
  String get obsTabQuality => 'Qualité';

  @override
  String get obsTabUsage => 'Utilisation';

  @override
  String get obsUsageTotalTokens => 'Jetons au total';

  @override
  String get obsUsagePeakTokens => 'Pic de jetons';

  @override
  String get obsUsageLongestSession => 'Session la plus longue';

  @override
  String get obsUsageCurrentStreak => 'Série en cours';

  @override
  String get obsUsageLongestStreak => 'Plus longue série';

  @override
  String obsUsageDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
      zero: '0 jour',
    );
    return '$_temp0';
  }

  @override
  String get obsUsageTokenActivity => 'Activité des jetons';

  @override
  String get obsUsageActivityModeLabel => 'Mode d’activité des jetons';

  @override
  String get obsUsageModeDaily => 'Quotidien';

  @override
  String get obsUsageModeWeekly => 'Hebdomadaire';

  @override
  String get obsUsageModeCumulative => 'Cumulé';

  @override
  String get obsUsageTimeRange => 'Période';

  @override
  String get obsUsageTrendTitle => 'Tendance quotidienne des jetons';

  @override
  String get obsUsageModelUsage => 'Utilisation par modèle';

  @override
  String get obsUsageTokensLabel => 'jetons';

  @override
  String get obsUsageNoActivity => 'Aucune utilisation de jetons enregistrée';

  @override
  String get obsUsageOtherModels => 'Autres';

  @override
  String obsUsageCellReadout(String date, String tokens) {
    return '$date · $tokens jetons';
  }

  @override
  String obsUsageActivitySummary(
    String start,
    String end,
    int activeDays,
    String peak,
  ) {
    return 'Activité des jetons du $start au $end. $activeDays jours actifs. Journée la plus chargée : $peak jetons.';
  }

  @override
  String get obsScreenSubtitle =>
      'Contrôle des agents en direct, attribution des coûts, quotas et signaux de qualité';

  @override
  String get obsRangeLast24h => 'Dernières 24 heures';

  @override
  String get obsRangeLast7d => '7 derniers jours';

  @override
  String get obsRangeLast30d => '30 derniers jours';

  @override
  String get obsRangeAll => 'Tout';

  @override
  String get obsAddFilter => 'Ajouter un filtre';

  @override
  String get obsFilterAgent => 'Agent';

  @override
  String get obsFilterModel => 'Modèle';

  @override
  String get obsFilterStatus => 'Statut';

  @override
  String get obsFilterRole => 'Rôle';

  @override
  String get obsKpiTotalRuns => 'Exécutions totales';

  @override
  String get obsKpiTotalCost => 'Coût total';

  @override
  String get obsKpiErrorRate => 'Taux d\'erreur';

  @override
  String get obsKpiCacheRate => 'Taux de cache';

  @override
  String get obsKpiTokensPerSec => 'Jetons / s';

  @override
  String get obsKpiAvgLatency => 'Latence moy.';

  @override
  String get obsKpiTtft => 'Délai avant premier jeton';

  @override
  String obsDeltaVsPrevious(String delta) {
    return '$delta vs période précédente';
  }

  @override
  String get obsChartActivity => 'Activité';

  @override
  String get obsChartCost => 'Coût au fil du temps';

  @override
  String get obsLegendRuns => 'Exécutions';

  @override
  String get obsLegendErrors => 'Erreurs';

  @override
  String get obsAgentsTitle => 'Agents';

  @override
  String obsShowAllAgents(int count) {
    return 'Afficher les $count agents';
  }

  @override
  String get obsShowFewerAgents => 'Afficher moins';

  @override
  String get obsRunsTitle => 'Exécutions';

  @override
  String get obsNoRunsInRange => 'Aucune exécution sur cette période';

  @override
  String get obsColTime => 'Heure';

  @override
  String get obsColAgent => 'Agent';

  @override
  String get obsColStatus => 'Statut';

  @override
  String get obsColModel => 'Modèle';

  @override
  String get obsColDuration => 'Durée';

  @override
  String get obsColTokens => 'Jetons';

  @override
  String get obsColCost => 'Coût';

  @override
  String get obsColErrors => 'Erreurs';

  @override
  String get obsColRuns => 'Exécutions';

  @override
  String get obsColAvgLatency => 'Latence moy.';

  @override
  String get obsColLastActive => 'Dernière activité';

  @override
  String get obsStatusPending => 'En attente';

  @override
  String get obsStatusRunning => 'En cours';

  @override
  String get obsStatusCompleted => 'Terminé';

  @override
  String get obsStatusError => 'Erreur';

  @override
  String get obsRosterLoadError => 'Impossible de charger la liste des agents.';

  @override
  String get obsRosterEmpty => 'Aucun agent pour le moment';

  @override
  String get obsRosterEmptyDescription =>
      'Lancez un agent et il apparaîtra ici en direct — statut, outil en cours, jetons, coût.';

  @override
  String get obsKillAgent => 'Arrêter l\'agent';

  @override
  String get obsRosterTokensLabel => 'jetons';

  @override
  String get obsCostByRoleTitle => 'Coût par rôle';

  @override
  String get obsCostByRoleSubtitle =>
      'Répartition des dépenses de cet espace par rôle d\'agent';

  @override
  String get obsRoleMain => 'Principal';

  @override
  String get obsRoleSubagents => 'Sous-agents';

  @override
  String get obsRoleAdvisor => 'Conseiller';

  @override
  String obsRoleCaption(String main, String sub, String advisor) {
    return 'Principal : $main · sous-agents : $sub · conseiller : $advisor';
  }

  @override
  String get obsTotal => 'Total';

  @override
  String get obsTokenModelTitle => 'Modèle de jetons (5 axes)';

  @override
  String get obsTokenModelSubtitle =>
      'Tous les jetons dépensés par cet espace, par axe';

  @override
  String get obsAxisInput => 'Entrée';

  @override
  String get obsAxisOutput => 'Sortie';

  @override
  String get obsAxisReasoning => 'Raisonnement';

  @override
  String get obsAxisCacheRead => 'Lecture cache';

  @override
  String get obsAxisCacheWrite => 'Écriture cache';

  @override
  String get obsTotalTokens => 'Jetons totaux';

  @override
  String get obsCacheDiscountNote =>
      'Les jetons lus en cache sont facturés au tarif réduit : ils coûtent bien moins cher que le même volume de nouvelle entrée.';

  @override
  String get obsByModelTitle => 'Par modèle';

  @override
  String get obsByModelSubtitle =>
      'Utilisation des jetons et des coûts par modèle';

  @override
  String get obsNoModelUsage =>
      'Aucune utilisation de modèle enregistrée pour le moment.';

  @override
  String obsRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exécutions',
      one: '1 exécution',
    );
    return '$_temp0';
  }

  @override
  String get obsPerRunTitle => 'Par exécution';

  @override
  String get obsPerRunSubtitle => 'Coût en jetons typique d\'une exécution';

  @override
  String get obsMedianRunTokens => 'Jetons médians par exécution';

  @override
  String get obsMedianRunTokensSub => 'Médiane sur toutes les exécutions';

  @override
  String get obsRunsInWorkspace => 'Dans cet espace';

  @override
  String get obsCostShare => 'Part du coût';

  @override
  String get obsQuotaConfiguredLimits => 'Limites configurées';

  @override
  String get obsQuotaConfiguredLimitsSubtitle =>
      'Utilisation par rapport aux plafonds définis, pire statut en premier.';

  @override
  String get obsQuotaAddLimit => 'Ajouter une limite';

  @override
  String get obsQuotaNoLimits =>
      'Aucune limite de quota configurée — ajoutez-en une pour suivre l\'utilisation par rapport à un plafond.';

  @override
  String obsQuotaRemoveSemantic(String title) {
    return 'Supprimer la limite $title';
  }

  @override
  String obsQuotaResetDetail(String duration, String status) {
    return 'Réinitialisation dans $duration · $status';
  }

  @override
  String get obsQuotaUsageWindows => 'Fenêtres d\'utilisation';

  @override
  String get obsQuotaUsageWindowsSubtitle =>
      'Utilisation observée pour tous les fournisseurs, sans plafond appliqué.';

  @override
  String get obsQuotaNoUsage =>
      'Aucune utilisation enregistrée pour le moment.';

  @override
  String get obsQuotaTokensUsed => 'Jetons utilisés';

  @override
  String get obsQuotaRequests => 'Requêtes';

  @override
  String get obsQuotaUnitTokens => 'jetons';

  @override
  String get obsQuotaUnitRequests => 'requêtes';

  @override
  String get obsQuotaUnitCost => 'coût';

  @override
  String get obsQuotaAddLimitTitle => 'Ajouter une limite de quota';

  @override
  String get obsQuotaProviderLabel => 'Fournisseur';

  @override
  String get obsQuotaWindowLabel => 'Fenêtre';

  @override
  String get obsQuotaUnitLabel => 'Unité';

  @override
  String obsQuotaLimitLabel(String unit) {
    return 'Limite ($unit)';
  }

  @override
  String get obsQuotaCentsHint => 'En cents américains (500 = 5,00 \$).';

  @override
  String get obsQuotaStatusOk => 'Ok';

  @override
  String get obsQuotaStatusWarning => 'Avertissement';

  @override
  String get obsQuotaStatusExhausted => 'Épuisé';

  @override
  String get obsQuotaStatusUnknown => 'Inconnu';

  @override
  String get obsGoalNoActiveTitle => 'Aucun objectif actif';

  @override
  String get obsGoalNoActiveBody =>
      'Définissez un objectif pour donner aux agents un but et un budget de jetons optionnel. À mesure que les exécutions aboutissent, le budget se remplit et les agents sont invités à conclure quand il est presque épuisé.';

  @override
  String get obsGoalSetGoal => 'Définir un objectif';

  @override
  String get obsGoalTokenBudget => 'Budget de jetons';

  @override
  String obsGoalTokensLeft(String tokens) {
    return '$tokens restants';
  }

  @override
  String obsGoalTokensUsedNoBudget(String tokens) {
    return '$tokens (aucun budget défini)';
  }

  @override
  String get obsGoalTokensUsed => 'Jetons utilisés';

  @override
  String get obsGoalElapsed => 'Temps écoulé';

  @override
  String get obsGoalWrapUp => 'Conclure';

  @override
  String get obsGoalClear => 'Effacer l\'objectif';

  @override
  String get obsGoalFallbackTitle => 'Objectif';

  @override
  String get obsGoalSubtitle => 'Budget du mode objectif';

  @override
  String get obsGoalStatusActive => 'Actif';

  @override
  String get obsGoalStatusPaused => 'En pause';

  @override
  String get obsGoalStatusBudgetLimited => 'Budget limité';

  @override
  String get obsGoalStatusComplete => 'Terminé';

  @override
  String get obsGoalStatusDropped => 'Abandonné';

  @override
  String get obsGoalObjectiveLabel => 'Objectif';

  @override
  String get obsGoalBudgetLabel => 'Budget de jetons (optionnel)';

  @override
  String get obsGoalSetAction => 'Définir l\'objectif';

  @override
  String get obsBenchmarkPassAt1 => 'pass@1';

  @override
  String get obsBenchmarkSuccessPct => 'Réussite %';

  @override
  String get obsBenchmarkPassed => 'Réussis';

  @override
  String get obsBenchmarkFailed => 'Échoués';

  @override
  String get obsBenchmarkErrors => 'Erreurs';

  @override
  String get obsBenchmarkSpend => 'Dépense';

  @override
  String get obsBenchmarkCostPerTask => 'Coût / tâche';

  @override
  String get obsBenchmarkTrials => 'Essais';

  @override
  String get obsBenchmarkNoTrials => 'Aucune exécution à noter pour le moment.';

  @override
  String obsBenchmarkAndMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'et $count de plus',
      one: 'et 1 de plus',
    );
    return '$_temp0';
  }

  @override
  String get obsBenchmarkTrialPass => 'Réussi';

  @override
  String get obsBenchmarkTrialFail => 'Échoué';

  @override
  String get obsBenchmarkTrialError => 'Erreur';

  @override
  String get obsBenchmarkTrialRunning => 'En cours';

  @override
  String get obsBenchmarkReward => 'Récompense';

  @override
  String get obsBenchmarkReport => 'Rapport';

  @override
  String get obsBenchmarkCopyMarkdown => 'Copier le markdown';

  @override
  String get obsBenchmarkCopied => 'Rapport copié dans le presse-papiers';

  @override
  String get obsBehaviorCaption =>
      'Ce sont des signaux de frustration extraits de vos propres messages — une lecture de la santé des conversations, pas une note pour les agents. Calculé localement ; rien ne quitte cet appareil.';

  @override
  String get obsBehaviorMessagesAnalyzed => 'Messages analysés';

  @override
  String get obsBehaviorTotalSignals => 'Signaux totaux';

  @override
  String get obsBehaviorYelling => 'Cris';

  @override
  String get obsBehaviorProfanity => 'Grossièretés';

  @override
  String get obsBehaviorAnguish => 'Détresse';

  @override
  String get obsBehaviorNegation => 'Négation';

  @override
  String get obsBehaviorRepetition => 'Répétition';

  @override
  String get obsBehaviorBlame => 'Reproche';

  @override
  String get obsBehaviorConversationsTitle =>
      'Conversations les plus frustrées';

  @override
  String get obsBehaviorConversationsSubtitle =>
      'Classées par densité de signaux dans vos messages.';

  @override
  String get obsBehaviorNoSignals =>
      'Aucun signal de frustration détecté — tout roule.';

  @override
  String obsBehaviorMessagesCount(String count) {
    return '$count messages analysés';
  }

  @override
  String obsBehaviorSignalsCount(String count) {
    return '$count signaux';
  }

  @override
  String get obsAgentStatusIdle => 'Inactif';

  @override
  String get obsAgentStatusParked => 'En veille';

  @override
  String get obsAgentStatusAborted => 'Interrompu';

  @override
  String get obsAgentKindSub => 'Sous-agent';

  @override
  String get noChecksOnCommit => 'Aucun check n\'a été exécuté sur ce commit.';

  @override
  String checksSummaryRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Exécution — $count jobs',
      one: 'Exécution — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummarySuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tous les checks ont réussi — $count jobs',
      one: 'Tous les checks ont réussi — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryNeutral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Terminé — $count jobs',
      one: 'Terminé — 1 job',
    );
    return '$_temp0';
  }

  @override
  String checksSummaryFailure(int failed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total jobs',
      one: '1 job',
    );
    return '$failed sur $_temp0 en échec';
  }

  @override
  String graphJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jobs',
      one: '1 job',
    );
    return '$_temp0';
  }

  @override
  String matrixJobLabel(String jobId) {
    return 'Matrice : $jobId';
  }

  @override
  String get jobLogsPending => 'Les logs apparaîtront ici à la fin du job.';

  @override
  String get jobLogsUnavailable =>
      'Les logs ne sont pas disponibles pour ce job.';

  @override
  String get noLogsForStep => 'Aucun log capturé pour cette étape.';

  @override
  String get jobLogsTruncated =>
      'Log tronqué — affichage de la sortie la plus récente.';

  @override
  String get fullLog => 'Log complet';

  @override
  String get copyLogs => 'Copier les logs';

  @override
  String get resizeGraph => 'Glisser pour redimensionner le graphe';

  @override
  String workflowRunStartedAgo(String time) {
    return 'Démarré $time';
  }

  @override
  String workflowRunCompletedAgo(String time) {
    return 'Terminé $time';
  }

  @override
  String get chatBridgesTitle => 'Ponts de messagerie';

  @override
  String chatProviderDescription(String provider, String command) {
    return 'Mentionnez le bot dans $provider pour confier une tâche à un agent, ou créez des tickets avec $command.';
  }

  @override
  String chatConnectProvider(String provider) {
    return 'Connecter $provider';
  }

  @override
  String get chatDisconnectProvider => 'Déconnecter';

  @override
  String chatConnectedTo(String botName, String teamName) {
    return '$botName dans $teamName';
  }

  @override
  String get chatStateLive => 'En ligne';

  @override
  String get chatStateConnecting => 'Connexion…';

  @override
  String get chatStateError => 'Erreur de connexion';

  @override
  String get chatNotConnected => 'Non connecté';

  @override
  String chatStreamingUnavailable(String provider) {
    return 'Le streaming en direct est désactivé pour cette app $provider — les réponses arrivent en un seul message.';
  }

  @override
  String chatAdminOnly(String provider) {
    return 'Seul un administrateur peut connecter $provider pour cet espace de travail.';
  }

  @override
  String chatConnectHint(String provider) {
    return 'Créez une app $provider, puis collez ses identifiants ici. Control Center se connecte vers $provider, ce serveur n\'a donc besoin d\'aucune adresse publique.';
  }

  @override
  String chatOpenConsole(String provider) {
    return 'Ouvrir la console $provider';
  }

  @override
  String get chatOpenSetupGuide => 'Guide de configuration';

  @override
  String get chatFieldBotToken => 'Jeton du bot';

  @override
  String get chatFieldAppToken => 'Jeton d\'application';

  @override
  String get chatFieldConfigRefreshToken => 'Jeton de configuration d\'app';

  @override
  String chatFieldOptional(String label) {
    return '$label (facultatif)';
  }

  @override
  String chatLinkMyAccount(String provider) {
    return 'Lier mon compte $provider';
  }

  @override
  String chatLinkMyAccountDescription(String provider) {
    return 'Liez votre compte $provider pour que les messages que vous y envoyez vous soient attribués.';
  }

  @override
  String chatLinkedAs(String externalUserId) {
    return 'Lié à $externalUserId';
  }

  @override
  String chatLinkCodeTitle(String provider) {
    return 'Lier votre compte $provider';
  }

  @override
  String chatLinkCodeInstruction(String provider) {
    return 'Envoyez cette commande au bot dans $provider. Elle ne fonctionne qu\'une fois et expire dans 15 minutes.';
  }

  @override
  String chatLinkCodeLinked(String provider) {
    return 'Votre compte $provider est maintenant lié — les messages que vous y envoyez vous sont attribués.';
  }

  @override
  String get chatLinkedAccounts => 'Comptes liés';

  @override
  String chatNoLinkedAccounts(String provider) {
    return 'Personne n\'a encore lié son compte $provider.';
  }

  @override
  String chatLinkedMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comptes liés',
      one: '1 compte lié',
    );
    return '$_temp0';
  }

  @override
  String chatLinkMethodEmail(String externalUserId) {
    return '$externalUserId · associé par e-mail';
  }

  @override
  String chatLinkMethodCode(String externalUserId) {
    return '$externalUserId · lié avec un code';
  }

  @override
  String get chatUnlink => 'Délier';

  @override
  String get chatCustomizeBot => 'Personnaliser le bot';

  @override
  String get chatCustomizeBotDescription =>
      'Renommez le bot, changez ce qu\'il dit de lui-même ou renommez la commande.';

  @override
  String get chatCustomizeBotUnavailable =>
      'Control Center a besoin d\'un jeton de configuration d\'app pour modifier le bot. Reconnectez-vous en en fournissant un.';

  @override
  String chatCreateAppTitle(String provider) {
    return 'Créer l\'app $provider';
  }

  @override
  String chatCreateAppHint(String provider) {
    return 'Control Center peut créer l\'app $provider pour vous, avec les bonnes permissions et les bons événements déjà en place. Vous terminerez dans $provider, puis collerez les identifiants ici.';
  }

  @override
  String get chatCreateApp => 'Créer l\'app';

  @override
  String get chatCreateAppCta => 'Créer l\'app pour moi';

  @override
  String get chatAppNameLabel => 'Nom de l\'app';

  @override
  String get chatBotDisplayNameLabel =>
      'Nom du bot (ce que l\'on tape après @)';

  @override
  String get chatDescriptionLabel => 'Description courte';

  @override
  String get chatAgentDescriptionLabel => 'Ce que le bot dit savoir faire';

  @override
  String get chatCommandLabel => 'Commande';

  @override
  String get chatDirectMessages => 'Messages directs';

  @override
  String chatDirectMessagesHint(String provider) {
    return 'Permet de discuter avec le bot en message direct. Peut nécessiter un forfait $provider payant.';
  }

  @override
  String chatAppCreated(String provider, String appId) {
    return '$provider a créé l\'app $appId.';
  }

  @override
  String chatRemainingSteps(String provider) {
    return 'Il reste quelques étapes, que seul $provider peut faire :';
  }

  @override
  String get chatStepAppToken => 'Générer un jeton au niveau de l\'app';

  @override
  String get chatStepInstall => 'Installer l\'app';

  @override
  String get chatOpenAppSettings => 'Ouvrir les réglages de l\'app';

  @override
  String get chatContinueToCredentials => 'Coller les identifiants';

  @override
  String chatBotUpdated(String provider) {
    return 'Bot mis à jour dans $provider.';
  }

  @override
  String chatScopesChangedReinstall(String provider) {
    return '$provider a modifié les permissions de l\'app. Réinstallez-la pour qu\'elles prennent effet.';
  }

  @override
  String get chatReinstallApp => 'Réinstaller l\'app';

  @override
  String chatIconNotEditable(String provider) {
    return 'L\'icône du bot ne peut être changée que dans les réglages d\'app de $provider.';
  }

  @override
  String chatCreateAppLinkHint(String provider) {
    return 'Vous pouvez aussi la créer vous-même dans $provider — sans jeton. Les réglages ci-dessus accompagnent le lien.';
  }

  @override
  String chatCreateAppWithLink(String provider) {
    return 'Créer dans $provider';
  }

  @override
  String chatSetupLinkBody(String provider) {
    return '$provider s\'est ouvert dans votre navigateur avec cette configuration pré-remplie. Créez l\'app, terminez ces étapes, puis revenez avec les jetons.';
  }

  @override
  String chatSetupLinkNotManageable(String provider) {
    return '$provider n\'indique pas quelle app a été créée : personnaliser le bot depuis ici nécessitera plus tard un jeton de configuration d\'app.';
  }

  @override
  String get chatStepCreateApp =>
      'Créer l\'app depuis la configuration pré-remplie';

  @override
  String chatStepCreateAppHint(String provider) {
    return 'Choisissez un espace de travail dans $provider et confirmez.';
  }

  @override
  String get chatStepAppTokenHint =>
      'Basic information → app-level tokens, avec la portée connections:write.';

  @override
  String get chatStepInstallHint =>
      'Install app → copiez le jeton OAuth de l\'utilisateur bot.';

  @override
  String get calendarUseBuiltinApp =>
      'Utiliser l\'app Google de Control Center';

  @override
  String get calendarUseBuiltinAppHint =>
      'Autorisez avec votre compte Google. Rien à configurer dans Google Cloud.';

  @override
  String get calendarUseOwnClient => 'Utiliser mon propre client Google Cloud';

  @override
  String get calendarUseOwnClientHint =>
      'Saisissez un client OAuth de votre propre projet Google Cloud.';

  @override
  String get aboutTitle => 'À propos';

  @override
  String get aboutAppVersion => 'Version de l\'application';

  @override
  String get aboutServerVersion => 'Serveur connecté';

  @override
  String get aboutRpcCatalog => 'Catalogue RPC';

  @override
  String get aboutServerUnknown => 'Non signalé';

  @override
  String get serverStaleTitle =>
      'Le serveur intégré est plus ancien que cette application';

  @override
  String serverStaleBody(String serverVersion, String appVersion) {
    return 'Le cc_server en cours d\'exécution est en $serverVersion alors que cette application est en $appVersion. Redémarrez l\'application pour qu\'elle utilise la dernière version du serveur intégré ; en développement, recompilez-la avec `dart build cli` dans apps/cc_server.';
  }

  @override
  String get updateCheckButton => 'Rechercher des mises à jour';

  @override
  String get updateChecking => 'Recherche de mises à jour…';

  @override
  String get updateUpToDate => 'Vous êtes à jour';

  @override
  String get updateDeferredBusy =>
      'Une mise à jour est prête mais une réunion est en cours d\'enregistrement — elle sera proposée après sa fin.';

  @override
  String get updateOpenedReleasesPage =>
      'Page des versions ouverte dans votre navigateur.';

  @override
  String get updateCheckFailed => 'Échec de la recherche de mise à jour';

  @override
  String updateAvailableVersion(String version) {
    return 'La version $version est disponible.';
  }

  @override
  String get updateBannerTitle =>
      'Une nouvelle version de Control Center est disponible';

  @override
  String get updateBannerRefresh => 'Actualiser';

  @override
  String get updateBlockedRecording =>
      'L\'actualisation est suspendue pendant l\'enregistrement d\'une réunion — la page se rechargera à la fin.';

  @override
  String get settingsScopeYou => 'Vous';

  @override
  String get settingsScopeWorkspace => 'Espace de travail';

  @override
  String get settingsScopeServer => 'Serveur';

  @override
  String get settingsProfile => 'Profil et identité';

  @override
  String get settingsYourDevices => 'Vos appareils';

  @override
  String get settingsWorkspaceGeneral => 'Général';

  @override
  String get settingsServerConnection => 'Connexion et état';

  @override
  String get settingsModelProviders => 'Fournisseurs de modèles';

  @override
  String get settingsVoiceModels => 'Modèles vocaux et de réunion';

  @override
  String get settingsDiagnostics => 'Diagnostics et confidentialité';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsScopeBadgeYou => 'VOUS';

  @override
  String get settingsScopeBadgeDevice => 'CET APPAREIL';

  @override
  String get settingsScopeBadgeWorkspace => 'ESPACE DE TRAVAIL';

  @override
  String get settingsScopeBadgeServer => 'SERVEUR';

  @override
  String get settingsProfileDescription =>
      'Votre nom, votre e-mail et l\'identité git apposée sur les commits faits en votre nom.';

  @override
  String get settingsServerConnectionDescription =>
      'Le serveur auquel ce client se connecte, et comment ce serveur est partagé (mDNS, tunnels, relais).';

  @override
  String get settingsAboutDescription =>
      'Identité de la version et mises à jour.';

  @override
  String get settingsDiagnosticsDescription =>
      'Isolation, indexation, synchronisation, journalisation et rapports d\'erreur de cette installation.';

  @override
  String get settingsWorkspaceGeneralDescription =>
      'Identité, règles et conventions partagées par tous les membres de cet espace de travail.';

  @override
  String get settingsWorkspacePolicyLabel => 'Règles de l\'espace de travail';

  @override
  String get settingsWorkspacePolicyDescription =>
      'S\'applique à chaque membre et à chaque agent de cet espace de travail.';

  @override
  String get settingsSecretGlobsLabel => 'Chemins secrets exclus';

  @override
  String get settingsSecretGlobsHelp =>
      'Un motif par ligne. Ces chemins sont masqués aux lecteurs et invités sur les surfaces de code, en plus des valeurs par défaut.';

  @override
  String get settingsReviewConcurrencyLabel => 'Relecteurs en parallèle';

  @override
  String get settingsReviewConcurrencyHelp =>
      'Nombre de relecteurs lancés en parallèle lorsqu\'aucun nombre explicite n\'est fourni.';

  @override
  String get settingsReviewLevelLabel => 'Niveau de revue';

  @override
  String get settingsReviewLevelHelp =>
      'La profondeur de la revue IA, et la part de ses résultats mise en avant. Rien n\'est supprimé : un niveau plus léger regroupe les remarques mineures au lieu de les écarter.';

  @override
  String get reviewLevelLight => 'Légère';

  @override
  String get reviewLevelBalanced => 'Équilibrée';

  @override
  String get reviewLevelThorough => 'Approfondie';

  @override
  String get reviewLevelLightHint =>
      'Un seul relecteur. Seul ce qui compte vraiment est mis en avant.';

  @override
  String get reviewLevelBalancedHint =>
      'Trois relecteurs : qualité, architecture et implémentation.';

  @override
  String get reviewLevelThoroughHint =>
      'Ajoute les spécialistes sécurité et performance, et signale tout ce qui est trouvé.';

  @override
  String get askAiReviewAtLevel => 'Lancer une revue à un autre niveau';

  @override
  String reviewNitpicksGroup(int count) {
    return 'Remarques mineures ($count)';
  }

  @override
  String get reviewFindingResolve => 'Corrigé';

  @override
  String get reviewFindingResolveHint =>
      'Marquer cette remarque comme corrigée. Elle cesse de compter dans la revue.';

  @override
  String get reviewFindingDismiss => 'Écarter';

  @override
  String get reviewFindingDismissHint =>
      'Pas un vrai problème. Les relecteurs cesseront de signaler ce motif.';

  @override
  String get reviewFindingReopen => 'Rouvrir';

  @override
  String get reviewFindingStatusUndoLabel => 'Statut de la remarque';

  @override
  String get reviewFindingDismissTitle => 'Écarter cette remarque';

  @override
  String get reviewFindingDismissReasonHint =>
      'Pourquoi cela ne s\'applique-t-il pas ? Les relecteurs le liront.';

  @override
  String reviewFindingStatusFailed(String error) {
    return 'Impossible de mettre à jour la remarque : $error';
  }

  @override
  String get reviewStaleTitle => 'Cette revue n\'est plus à jour';

  @override
  String get reviewStaleBody =>
      'La pull request a évolué depuis cette revue. Les remarques peuvent viser du code qui n\'existe plus.';

  @override
  String reviewStaleReviewedAt(String sha) {
    return 'Revue au commit $sha';
  }

  @override
  String get reviewStaleRerun => 'Relancer la revue';

  @override
  String reviewStaleNotificationTitle(int prNumber) {
    return 'Revue obsolète sur #$prNumber';
  }

  @override
  String reviewStaleNotificationBody(String title) {
    return '$title a de nouveaux commits depuis sa dernière revue.';
  }

  @override
  String get reviewCategorySecurity => 'Sécurité';

  @override
  String get reviewCategoryStability => 'Stabilité';

  @override
  String get reviewCategoryDataIntegrity => 'Intégrité des données';

  @override
  String get reviewCategoryCorrectness => 'Exactitude';

  @override
  String get reviewCategoryPerformance => 'Performance';

  @override
  String get reviewCategoryMaintainability => 'Maintenabilité';

  @override
  String get reviewEffortQuickWin => 'Gain rapide';

  @override
  String get reviewEffortModerate => 'Modéré';

  @override
  String get reviewEffortHeavyLift => 'Chantier lourd';

  @override
  String get reviewProposedFix => 'Correctif proposé';

  @override
  String get reviewAiAgentPrompt => 'Instruction pour agents IA';

  @override
  String get reviewCopyAiPrompt => 'Copier l\'instruction';

  @override
  String get settingsWorkspaceAdminOnly =>
      'Seuls les administrateurs de l\'espace de travail peuvent modifier ces réglages.';

  @override
  String get chatMyAccountsTitle => 'Comptes de messagerie liés';

  @override
  String get settingsServerSso => 'Authentification unique';

  @override
  String get settingsServerSsoDescription =>
      'Connexion SAML et OpenID Connect avec provisionnement des utilisateurs';

  @override
  String get ssoProviderSaml => 'SAML';

  @override
  String get ssoProviderOidc => 'OpenID Connect';

  @override
  String get ssoEnabledDescription =>
      'Les utilisateurs peuvent se connecter avec ce fournisseur';

  @override
  String get ssoEnabledDescriptionOn =>
      'La connexion est active pour ce fournisseur';

  @override
  String get ssoIdpMetadataLabel => 'XML de métadonnées de l\'IdP';

  @override
  String get ssoIdpMetadataHint => 'collez le XML EntityDescriptor de l\'IdP';

  @override
  String get ssoEmailAttributeLabel => 'Attribut e-mail';

  @override
  String get ssoDisplayNameAttributeLabel => 'Attribut nom d\'affichage';

  @override
  String get ssoGroupsAttributeLabel => 'Attribut groupes';

  @override
  String get ssoIssuerLabel => 'URL de l\'émetteur';

  @override
  String get ssoClientIdLabel => 'ID client';

  @override
  String get ssoGroupsClaimLabel => 'Claim des groupes';

  @override
  String get ssoAutoMemberLabel =>
      'Ajouter les utilisateurs à tous les espaces à la première connexion';

  @override
  String get ssoAutoMemberDescription =>
      'Désactivez pour exiger une invitation par espace';

  @override
  String get ssoAllowJitLabel =>
      'Provisionner les utilisateurs inconnus à la première connexion';

  @override
  String get ssoAllowJitDescription =>
      'Désactivez pour refuser les utilisateurs sans compte existant';

  @override
  String get ssoAllowIdpInitiatedLabel =>
      'Accepter les connexions initiées par l\'IdP';

  @override
  String get ssoAllowIdpInitiatedDescription =>
      'Strictement pour les portails IdP qui lancent les applis directement';

  @override
  String get ssoWantResponseSignedLabel =>
      'Exiger une enveloppe de réponse signée';

  @override
  String get ssoWantResponseSignedDescription =>
      'Les signatures d\'assertion sont toujours exigées';

  @override
  String get ssoTestConnectionButton => 'Tester la connexion';

  @override
  String get ssoTestConnectionOk => 'La connexion fonctionne :';

  @override
  String get ssoCopySpMetadata => 'Copier les métadonnées SP';

  @override
  String get ssoCopySpMetadataDone =>
      'Métadonnées SP copiées dans le presse-papiers';

  @override
  String get ssoSavedToast =>
      'Paramètres d\'authentification unique enregistrés';

  @override
  String get ssoUnavailable =>
      'Ce serveur n\'expose pas les paramètres d\'authentification unique. Mettez à jour le binaire du serveur et réessayez.';

  @override
  String get ssoScimCardTitle => 'Provisionnement des utilisateurs (SCIM)';

  @override
  String get ssoScimDescription =>
      'Pointez le connecteur SCIM de votre fournisseur d\'identité vers l\'endpoint ci-dessous avec un jeton bearer. Le déprovisionnement révoque sessions et accès aux espaces en quelques secondes. Le serveur doit être joignable par l\'IdP (tunnel ou URL publique).';

  @override
  String get ssoScimEndpoint => 'Endpoint SCIM';

  @override
  String get ssoScimEndpointUnknownOrigin =>
      'Définissez d\'abord l\'URL publique du serveur ou activez un tunnel';

  @override
  String get ssoScimRegenerate => 'Régénérer le jeton';

  @override
  String get ssoScimRegenerateConfirm =>
      'Générer un nouveau jeton bearer SCIM ? Le jeton précédent cessera immédiatement de fonctionner.';

  @override
  String get ssoScimTokenTitle => 'Jeton bearer';

  @override
  String get ssoScimTokenPresent => 'Un jeton est configuré';

  @override
  String get ssoScimTokenAbsent =>
      'Aucun jeton — générez-en un pour activer SCIM';

  @override
  String get ssoScimTokenOnce => 'Jeton SCIM (affiché une seule fois)';

  @override
  String ssoSignInWith(String provider) {
    return 'Se connecter avec $provider';
  }

  @override
  String get ssoProbeFailed =>
      'Impossible de joindre ce serveur pour l\'authentification unique';

  @override
  String get ssoOpensBrowser =>
      'Ouvre votre navigateur pour terminer la connexion';

  @override
  String get ssoWaitingForBrowser =>
      'En attente de votre navigateur pour terminer la connexion…';

  @override
  String get ssoBrowserOpenFailed =>
      'Impossible d\'ouvrir votre navigateur pour l\'authentification unique';

  @override
  String get ssoUseManualPairing =>
      'Se connecter avec un code d\'invitation ou une clé d\'appairage';

  @override
  String get ssoHideManualPairing => 'Masquer l\'appairage manuel';

  @override
  String get ssoClientIdHint =>
      'Client public (PKCE) — aucun secret nécessaire';

  @override
  String get ssoClientSecretLabel => 'Secret client (facultatif)';

  @override
  String get ssoClientSecretHintUnset =>
      'Uniquement nécessaire pour les clients confidentiels de l\'IdP';

  @override
  String get ssoClientSecretHintSet =>
      'Un secret est enregistré — laissez vide pour le conserver';

  @override
  String get ssoPairingToggle =>
      'Autoriser l\'appairage manuel (codes d\'invitation et clés d\'appairage)';

  @override
  String get ssoPairingToggleDescription =>
      'Désactivez pour réserver l\'adhésion à l\'authentification unique — les nouveaux appareils arrivent par connexion SSO ; les appareils existants continuent de fonctionner';

  @override
  String get ssoPairConfirmTitle => 'Se connecter au serveur ?';

  @override
  String ssoPairConfirmBody(String server) {
    return 'Un identifiant de connexion pour $server est arrivé, mais aucune connexion n\'a été démarrée depuis cette application. Se connecter à ce serveur ?';
  }

  @override
  String get ssoPairConfirmConnect => 'Se connecter';

  @override
  String get ssoPairConfirmCancel => 'Ignorer';

  @override
  String get forgeConnections => 'Hébergement de code';

  @override
  String get connect => 'Connecter';

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get notConnected => 'Non connecté';

  @override
  String get checkingConnection => 'Vérification de la connexion…';

  @override
  String get fromEnvironment => 'depuis l\'environnement';

  @override
  String forgeTokenTitle(String forge) {
    return 'Jeton $forge';
  }

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAudioDescription =>
      'Micro, dictée, détection des réunions et sortie des ambiances sonores.';

  @override
  String get audioDevicesSection => 'Périphériques audio';

  @override
  String get voiceInputBehaviorSection => 'Dictée et réunions';

  @override
  String get audioOutputDeviceTitle => 'Périphérique de sortie';

  @override
  String get audioOutputDefaultHint =>
      'Tout le son de l\'application passe par la sortie par défaut du système.';

  @override
  String get audioOutputGone =>
      'Le périphérique de sortie sélectionné n\'est plus connecté — la sortie par défaut du système est utilisée jusqu\'à ce que vous en choisissiez un autre.';

  @override
  String get reviewHubIntroBody =>
      'Les agents analysent le diff, cartographient les zones de changement et parviennent à un verdict de consensus.';

  @override
  String get reviewHubAlreadyRunning =>
      'Une revue est déjà en cours pour cette pull request';

  @override
  String reviewHubDeltaSummary(int resolved, int added, int open) {
    return 'Depuis la dernière revue : $resolved résolus · $added nouveaux · $open encore ouverts';
  }

  @override
  String reviewHubDeltaPreviousSha(String sha) {
    return 'Précédemment revu à $sha';
  }

  @override
  String reviewArtifactFixAll(int count) {
    return 'Corriger $count remarques';
  }

  @override
  String reviewArtifactFixSelected(int count) {
    return 'Corriger $count sélectionnés';
  }

  @override
  String reviewArtifactCommentSelected(int count) {
    return 'Commenter $count sélectionnés';
  }

  @override
  String get webConnectTitle => 'Se connecter à Control Center';

  @override
  String get webConnectSubtitle =>
      'Contactez un cc-server en cours d\'exécution via WebSocket. Votre clé reste sur cet appareil.';

  @override
  String get webConnectServerLabel => 'Serveur';

  @override
  String get webConnectDeviceIdLabel => 'Identifiant de l\'appareil';

  @override
  String get webConnectPairingKeyLabel => 'Clé d\'appairage';

  @override
  String get webConnectPairingKeyHint => 'collez la PSK';

  @override
  String get webConnectStayConnected => 'Rester connecté sur cet appareil';

  @override
  String get webConnectStayConnectedDetail =>
      'Rester connecté sur cet appareil (votre clé est stockée dans ce navigateur)';

  @override
  String failedToCreateWorkspace(String error) {
    return 'Échec de la création de l\'espace de travail : $error';
  }

  @override
  String committedRelative(String relative) {
    return 'validé $relative';
  }

  @override
  String get selectAgents => 'Sélectionner des agents';

  @override
  String agentCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agents',
      one: '1 agent',
    );
    return '$_temp0';
  }

  @override
  String get newConversation => 'Nouvelle conversation';

  @override
  String get untitledConversation => 'Conversation sans titre';

  @override
  String get conversationTitleOptionalHint =>
      'Facultatif — laissez vide et le modèle de titres le nomme automatiquement';

  @override
  String get conversationTitlesSectionTitle => 'Titres de conversation';

  @override
  String get conversationTitlesSectionCaption =>
      'Choisissez le moteur qui nomme automatiquement les nouvelles conversations de cet espace de travail. Les titres restent désactivés tant qu\'aucun adaptateur n\'est choisi et s\'appliquent à chaque membre.';

  @override
  String get conversationTitlesModelLabel => 'Modèle de titres';

  @override
  String get conversationTitlesAdapterLabel => 'Adaptateur';

  @override
  String get conversationTitlesAdapterHint => 'Désactivé';

  @override
  String get conversationTitlesAdapterOff => 'Désactivé';

  @override
  String get startThread => 'Démarrer un fil';

  @override
  String get deleteSpaceConfirm =>
      'Supprimer cet espace ? Tous les messages seront perdus.';

  @override
  String threadTabTitle(String title) {
    return 'Fil : $title';
  }

  @override
  String threadReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count réponses',
      one: '1 réponse',
    );
    return '$_temp0';
  }

  @override
  String threadLastReply(String time) {
    return 'Dernière réponse $time';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Se connecter avec $provider';
  }

  @override
  String get signInAgain => 'Se reconnecter';

  @override
  String get signInNotFinished =>
      'La connexion n\'est pas encore revenue. Terminez-la dans votre navigateur, puis vérifiez à nouveau.';

  @override
  String get signedOutTitle => 'Vous êtes déconnecté';

  @override
  String get signedOutSubtitle =>
      'Votre connexion à l\'hébergeur de code n\'est plus valide — un jeton a expiré, ou son accès a été révoqué. Rien d\'autre n\'a changé : reconnectez-vous et tout sera là où vous l\'aviez laissé.';

  @override
  String get viaServerApp => 'via l\'application de ce serveur';

  @override
  String get ticketing => 'Tickets';

  @override
  String get ticketingProviderHelp =>
      'Où vivent vos tickets. Local les garde dans Control Center.';

  @override
  String providerComingSoon(String provider) {
    return '$provider (bientôt)';
  }

  @override
  String get ticketProviderLocal => 'Local';

  @override
  String get addKey => 'Ajouter une clé';

  @override
  String get providerApps => 'Applications fournisseur';

  @override
  String get providerAppsDescription =>
      'Comment ce serveur s\'authentifie lui-même, et par quoi une personne se connecte. Les tâches de fond — webhooks, sondages, synchronisation — passent par l\'application, jamais par le jeton d\'une personne.';

  @override
  String get providerAppId => 'Identifiant d\'application';

  @override
  String get providerPrivateKey => 'Clé privée';

  @override
  String get providerClientId => 'Identifiant client';

  @override
  String get providerClientSecret => 'Secret client';

  @override
  String get providerApiKey => 'Clé d\'API';

  @override
  String get providerCallbackUrl => 'URL de rappel';

  @override
  String get providerAppFullyConfigured =>
      'Le serveur peut agir en son nom, et les personnes peuvent se connecter.';

  @override
  String get providerAppServerOnly =>
      'Le serveur peut agir en son nom. Ajoutez un identifiant et un secret client pour permettre les connexions.';

  @override
  String get providerAppSignInOnly =>
      'Les personnes peuvent se connecter. Les tâches de fond utilisent leurs identifiants.';

  @override
  String providerAppInstalledOn(String accounts) {
    return 'Les identifiants fonctionnent. Installée sur : $accounts';
  }

  @override
  String deviceCodeInstructions(String provider) {
    return 'Saisissez ce code sur la page $provider qui vient de s\'ouvrir. Il a été copié dans votre presse-papiers.';
  }

  @override
  String get deviceCodeWaiting => 'En attente de la fin dans le navigateur…';

  @override
  String get copyCodeAndOpen => 'Copier le code et ouvrir';

  @override
  String get couldNotOpenBrowser =>
      'Aucun navigateur n\'a pu être ouvert. Copiez le lien et terminez la connexion vous-même.';

  @override
  String get contextUsage => 'Utilisation du contexte';

  @override
  String get contextUsageFull => 'plein';

  @override
  String get contextUsageTokens => 'jetons';

  @override
  String get contextSeeMore => 'Voir plus';

  @override
  String get contextSegmentSystemPrompt => 'Prompt système';

  @override
  String get contextSegmentRules => 'Règles';

  @override
  String get contextSegmentSkills => 'Compétences';

  @override
  String get contextSegmentToolDefinitions => 'Définitions d\'outils';

  @override
  String get contextSegmentMcpTools => 'MCP et outils dynamiques';

  @override
  String get contextSegmentDeferredTools => 'Outils chargés à la demande';

  @override
  String get contextSegmentSubagents => 'Définitions de sous-agents';

  @override
  String get contextSegmentMemory => 'Mémoire';

  @override
  String get contextSegmentConversation => 'Conversation';

  @override
  String get contextExplorerTitle => 'Contexte';

  @override
  String get contextExplorerEverything => 'Tout';

  @override
  String get contextExplorerSelectPart =>
      'Sélectionnez un élément pour inspecter son contenu';

  @override
  String get contextExplorerUnavailable =>
      'Répartition du contexte indisponible';

  @override
  String get contextRetry => 'Réessayer';

  @override
  String get settingsFieldOptional => 'Facultatif';

  @override
  String get settingsFilterHint => 'Filtrer cette liste';

  @override
  String get settingsValueNotAvailable => 'Pas encore disponible';

  @override
  String get settingsNoEntriesYet => 'Rien ici pour l’instant';

  @override
  String get settingsChangedBadge => 'Modifié';

  @override
  String get ssoConnectionCardDescription =>
      'Choisissez comment les utilisateurs se connectent à ce serveur, puis activez cette connexion.';

  @override
  String get ssoUseSamlForSignIn => 'Utiliser SAML pour la connexion';

  @override
  String get ssoUseOidcForSignIn => 'Utiliser OpenID Connect pour la connexion';

  @override
  String get ssoSaveConnection => 'Enregistrer la connexion';

  @override
  String get ssoStateLive => 'Actif';

  @override
  String get ssoStateConfiguredOff => 'Configuré, désactivé';

  @override
  String get ssoStateOnIncomplete => 'Activé, incomplet';

  @override
  String get ssoStateActive => 'Actif';

  @override
  String get ssoStateAllowed => 'Autorisé';

  @override
  String get ssoStateNoToken => 'Aucun jeton';

  @override
  String get ssoSummaryDirectorySync => 'Synchronisation de l’annuaire';

  @override
  String get ssoSummaryManualPairing => 'Appairage manuel';

  @override
  String get ssoNoMethodLiveNote =>
      'Aucune méthode de connexion n’est active. Les nouveaux appareils rejoignent le serveur avec une invitation ou une clé d’appairage tant qu’aucune connexion n’est configurée et activée.';

  @override
  String get ssoMethodSamlBlurb =>
      'Pour les fournisseurs d’identité qui parlent SAML 2.0, comme Okta, Entra ID ou Google Workspace.';

  @override
  String get ssoMethodOidcBlurb =>
      'Pour les fournisseurs d’identité qui parlent OpenID Connect. En général, le plus simple des deux à configurer.';

  @override
  String get ssoGroupIdentityProvider => 'Fournisseur d’identité';

  @override
  String get ssoGroupIdentityProviderSamlDescription =>
      'D’où viennent les assertions et comment ce serveur les vérifie.';

  @override
  String get ssoGroupIdentityProviderOidcDescription =>
      'Quel émetteur ce serveur approuve et le client sous lequel il s’authentifie.';

  @override
  String get ssoSpEntityIdShortLabel => 'ID d’entité du SP';

  @override
  String get ssoSpEntityIdDescription =>
      'Laissez vide pour le déduire de l’URL du serveur.';

  @override
  String get ssoIssuerDescription =>
      'L’URL de base qui sert le document de découverte du fournisseur.';

  @override
  String get ssoSecretStored => 'Enregistré';

  @override
  String get ssoGroupHandoff => 'Ce dont votre fournisseur d’identité a besoin';

  @override
  String get ssoGroupHandoffDescription =>
      'Collez ces valeurs dans l’application créée chez votre fournisseur.';

  @override
  String get ssoOriginUnknownTitle =>
      'Ce serveur ne connaît pas son URL publique';

  @override
  String get ssoOriginUnknownBody =>
      'Les URL de connexion et de rappel en sont dérivées : votre fournisseur ne peut donc pas joindre ce serveur tant qu’aucune n’est définie. Ajoutez une URL publique ou activez un tunnel dans Serveur → Connexion.';

  @override
  String get ssoAcsUrlLabel => 'URL du service consommateur d’assertions (ACS)';

  @override
  String get ssoAcsUrlDescription =>
      'L’endroit où votre fournisseur publie l’assertion signée.';

  @override
  String get ssoSpEntityIdResolvedLabel =>
      'ID d’entité du fournisseur de service';

  @override
  String get ssoMetadataUrlLabel => 'URL des métadonnées du SP';

  @override
  String get ssoMetadataUrlDescription =>
      'Les fournisseurs qui importent des métadonnées peuvent les récupérer ici.';

  @override
  String get ssoRedirectUriLabel => 'URI de redirection';

  @override
  String get ssoRedirectUriDescription =>
      'Ajoutez-la aux URI de redirection autorisés de l’application de votre fournisseur.';

  @override
  String get ssoSignInUrlLabel => 'URL de connexion';

  @override
  String get ssoSignInUrlDescription =>
      'Envoyez les utilisateurs ici pour démarrer une connexion par authentification unique.';

  @override
  String get ssoGroupAttributeMapping => 'Correspondance des attributs';

  @override
  String get ssoGroupAttributeMappingDescription =>
      'Quel claim porte chaque champ. Conservez les valeurs par défaut sauf si votre fournisseur les renomme.';

  @override
  String get ssoGroupAccess => 'Accès et rôles';

  @override
  String get ssoGroupAccessDescription =>
      'Ce qu’une personne qui se connecte avec succès est autorisée à faire.';

  @override
  String get ssoDefaultRoleShortLabel => 'Rôle par défaut';

  @override
  String get ssoDefaultRoleDescription =>
      'Attribué à toute personne dont les groupes ne correspondent à aucune règle ci-dessous.';

  @override
  String get ssoRoleMapShortLabel => 'Correspondance groupe / rôle';

  @override
  String get ssoRoleMapDescription =>
      'Le premier groupe correspondant l’emporte. Le rôle propriétaire ne peut pas être accordé ainsi.';

  @override
  String get ssoRoleMapGroupHint => 'Nom du groupe chez votre fournisseur';

  @override
  String get ssoRoleMapAdd => 'Ajouter une correspondance';

  @override
  String get ssoRoleMapEmpty =>
      'Aucune correspondance : tout le monde reçoit le rôle par défaut.';

  @override
  String get ssoAdvancedSummary =>
      'Décalage d’horloge, connexion initiée par l’IdP, politique de signature';

  @override
  String get ssoClockSkewShortLabel => 'Décalage d’horloge';

  @override
  String get ssoClockSkewDescription =>
      'Secondes de tolérance sur les horodatages des assertions. 90 convient à la plupart des fournisseurs.';

  @override
  String get ssoScimGenerate => 'Générer un jeton';

  @override
  String get ssoScimTokenOnceBody =>
      'Copié dans votre presse-papiers. Il n’est affiché qu’une fois et ne peut pas être récupéré : collez-le chez votre fournisseur maintenant.';

  @override
  String get ssoPairingCardTitle => 'Appairage manuel';

  @override
  String get ssoPairingCardDescription =>
      'L’autre porte d’entrée de ce serveur : codes d’invitation et clés d’appairage, pour les appareils qui ne passent pas par l’authentification unique.';

  @override
  String settingsCountOfTotal(int count, int total) {
    return '$count sur $total';
  }

  @override
  String get providersNoneConnectedNote =>
      'Aucun fournisseur n’est connecté : le moteur d’agents intégré n’a donc rien pour s’exécuter. Ajoutez une clé d’API ou connectez-vous à l’un d’eux ci-dessous.';

  @override
  String get providersFilterHint => 'Filtrer les fournisseurs';

  @override
  String get providersFacetNeedsSetup => 'À configurer';

  @override
  String get providersFacetCustom => 'Personnalisés';

  @override
  String get providersNoneMatch => 'Aucun résultat pour ce filtre';

  @override
  String get providerDeniedHereTitle => 'Refusé dans cet espace de travail';

  @override
  String get providerDeniedHereBody =>
      'Les agents de cet espace ne peuvent pas utiliser ce fournisseur, même s’il est connecté. Les autres espaces ne sont pas concernés.';

  @override
  String get providerNeedsSignIn =>
      'Connectez-vous pour utiliser ce fournisseur';

  @override
  String get providerNeedsApiKey =>
      'Ajoutez une clé d’API pour utiliser ce fournisseur';

  @override
  String get providerApiKeyLabel => 'Clé d’API';

  @override
  String get providerGenerationDefaults => 'Valeurs par défaut du fournisseur';

  @override
  String get providerNoModelsYet =>
      'Aucun modèle signalé pour l’instant. Connectez le fournisseur, puis synchronisez.';

  @override
  String get providerModelsFilterHint => 'Filtrer les modèles';

  @override
  String get adaptersNoneReadyNote =>
      'Aucun des CLI de runners du catalogue n’a été trouvé sur cette machine. Installez-en un, puis actualisez.';

  @override
  String get adaptersFilterHint => 'Filtrer les runners';

  @override
  String get adaptersFacetReady => 'Prêts';

  @override
  String get adaptersFacetMissing => 'Absents';

  @override
  String get adaptersLaunchGroup => 'Lancement';

  @override
  String get adaptersLaunchGroupDescription =>
      'Ce qui est transmis à ce runner quand un agent le démarre. Vous pouvez le configurer avant même d’installer le CLI.';

  @override
  String get adaptersEnvNone => 'Aucune définie';

  @override
  String adaptersEnvCount(int count) {
    return '$count définies';
  }

  @override
  String get adapterArgumentsDescription =>
      'Ajoutés à la ligne de commande du runner à chaque lancement.';

  @override
  String get defaultChatDescription =>
      'Exécute les nouvelles conversations et tout agent sans runner propre.';

  @override
  String get shortTaskDescription =>
      'Exécute les petites tâches d’arrière-plan comme les titres et les résumés. Un modèle plus léger a sa place ici.';

  @override
  String get settingsStateFailed => 'Échec';

  @override
  String get providerAppsGroupServer => 'Agir en tant que serveur';

  @override
  String get providerAppsGroupServerDescription =>
      'Permet aux tâches d’arrière-plan d’accéder aux dépôts sans intervention humaine : webhooks, interrogation des pull requests, synchronisation des tickets.';

  @override
  String get providerAppsGroupPrConversations =>
      'Conversations de pull request';

  @override
  String get providerAppsGroupPrConversationsDescription =>
      'Comment les développeurs peuvent parler à ce serveur directement sur GitHub. Fonctionne sans webhook ni URL publique — le serveur interroge GitHub périodiquement.';

  @override
  String get providerAppBotLogin => 'Login du bot';

  @override
  String get providerAppBotLoginEmpty =>
      'Testez la connexion pour résoudre le login du bot.';

  @override
  String get providerAppAskOnGitHub => 'Interroger sur GitHub';

  @override
  String get providerAppAskOnGitHubHint =>
      'Mentionnez le login du bot ci-dessus dans un commentaire de pull request — le suffixe [bot] est facultatif — pour demander une revue ou poser une question, répondez dans ses fils de revue, ou ajoutez le label `ai-review` pour demander une revue.';

  @override
  String get providerAppsGroupSignIn => 'Connexion des utilisateurs';

  @override
  String get providerAppsGroupSignInDescription =>
      'Permet à chaque membre de connecter son propre compte et d’obtenir ses propres identifiants.';

  @override
  String get providerAppCapActsAsServer => 'Agit comme le serveur';

  @override
  String get providerAppCapSignsIn => 'Connecte les utilisateurs';

  @override
  String get portLabel => 'Port';

  @override
  String get mcpNoTokenWarning =>
      'Sans jeton, tout ce qui peut atteindre ce port peut appeler chaque outil.';

  @override
  String get mcpBridgedToolsLabel => 'Outils';

  @override
  String get guardrailFamilyFiles => 'Fichiers';

  @override
  String get guardrailFamilyGit => 'Git et pull requests';

  @override
  String get guardrailFamilyMachine => 'Machine et réseau';

  @override
  String get guardrailFamilyControl => 'Secrets et espace de travail';

  @override
  String get guardrailScopeFieldLabel => 'Règles modifiées pour';

  @override
  String get guardrailScopeFieldDescription =>
      'Une portée plus étroite l’emporte sur une portée plus large. Les règles définies ici s’appliquent par-dessus ce qui est hérité.';

  @override
  String get guardrailSetHere => 'Définies ici';

  @override
  String get guardrailClearAllHere => 'Tout effacer';

  @override
  String get sandboxingCardLabel => 'Bac à sable';

  @override
  String get sandboxingCardDescription =>
      'Indique si le travail des agents s’exécute isolé de cet hôte, et ce qu’un agent isolé peut encore atteindre.';

  @override
  String get sandboxBackendNoneActive => 'Hôte, sans isolation';

  @override
  String get sandboxSummaryHost => 'Hôte';

  @override
  String get sandboxGroupIsolation => 'Isolation';

  @override
  String get sandboxGroupIsolationDescription =>
      'L’endroit où s’exécutent réellement les processus et les écritures de fichiers d’un agent.';

  @override
  String get sandboxBackendFieldDescription =>
      'Le mode auto choisit le plus robuste pris en charge par cet hôte. Épinglez-en un pour éviter qu’il change tout seul.';

  @override
  String get sandboxCapabilitiesDescription =>
      'Les ouvertures pratiquées dans la frontière. Chacune est une chose qu’un agent isolé peut encore faire au monde extérieur.';

  @override
  String get sandboxSummaryInForce => 'En vigueur';

  @override
  String get rigsInstallHintLabel => 'Comment l’installer';

  @override
  String get rigsStarting => 'Démarrage';

  @override
  String get rigsResidentMemory => 'Mémoire résidente';

  @override
  String get installedLabel => 'Installé';

  @override
  String get notInstalledLabel => 'Non installé';

  @override
  String ssoOtherKindUnsaved(String method) {
    return '$method a des modifications non enregistrées';
  }

  @override
  String get collapseComment => 'Réduire le commentaire';

  @override
  String get expandComment => 'Développer le commentaire';

  @override
  String get suggestedChange => 'Modification suggérée';

  @override
  String get emptyComment => 'Commentaire vide';

  @override
  String repliesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count réponses',
      one: '1 réponse',
    );
    return '$_temp0';
  }

  @override
  String get pendingReview => 'Revue en attente';

  @override
  String failedToResolveConversation(String error) {
    return 'Impossible de mettre à jour la conversation : $error';
  }

  @override
  String get addSingleComment => 'Ajouter un seul commentaire';

  @override
  String get addToReview => 'Ajouter à la revue';

  @override
  String get startAReview => 'Démarrer une revue';

  @override
  String get reviewNeedsABody =>
      'Écrivez un résumé ou ajoutez d\'abord un commentaire en ligne';

  @override
  String get reviewSubmitted => 'Revue envoyée';

  @override
  String get finishYourReview => 'Terminer votre revue';

  @override
  String get commentVerdict => 'Commenter';

  @override
  String pendingCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commentaires en attente',
      one: '1 commentaire en attente',
    );
    return '$_temp0';
  }

  @override
  String andNMore(int count) {
    return 'et $count de plus';
  }

  @override
  String get queuedCommentHint =>
      'Ce commentaire partira lors de l\'envoi de votre revue.';

  @override
  String commentOnLinesRange(int start, int end) {
    return 'Lignes $start à $end';
  }

  @override
  String get claudeAccountsTitle => 'Comptes Claude Code';

  @override
  String get claudeAccountsDescription =>
      'Chaque compte est une connexion Claude Code distincte. Les exécutions utilisent les comptes attachés ci-dessous, dans cet ordre.';

  @override
  String get claudeAccountsEmpty => 'Aucun compte pour l\'instant';

  @override
  String get claudeAccountAdd => 'Ajouter un compte';

  @override
  String get claudeAccountSignIn => 'Se connecter';

  @override
  String get claudeAccountSignInAgain => 'Se reconnecter';

  @override
  String get claudeAccountSignInHint =>
      'Exécutez ceci dans un terminal sur le serveur. Un navigateur s\'ouvre pour terminer la connexion, et l\'identifiant est écrit dans le dossier de ce compte.';

  @override
  String get claudeAccountSignedOut => 'Déconnecté';

  @override
  String get claudeAccountExpired => 'Connexion expirée';

  @override
  String claudeAccountExpiredDetail(String when) {
    return 'La connexion a expiré à $when. Reconnectez-vous pour utiliser ce compte.';
  }

  @override
  String get claudeAccountMakeDefault => 'Définir par défaut';

  @override
  String get claudeAccountDefault => 'Par défaut';

  @override
  String claudeAccountRemoveConfirm(String label) {
    return 'Supprimer $label ?';
  }

  @override
  String get claudeAccountRemoveDetail =>
      'Le compte est déconnecté et son dossier est supprimé du serveur. La connexion elle-même n\'est pas affectée.';

  @override
  String claudeAccountStatusUnknown(String error) {
    return 'Impossible de vérifier ce compte : $error';
  }

  @override
  String claudeAccountUsedPercent(String percent) {
    return '$percent % utilisé';
  }

  @override
  String get accountPoolStrategy => 'Rotation';

  @override
  String get accountPoolPinned => 'Fixe';

  @override
  String get accountPoolRoundRobin => 'Tour à tour';

  @override
  String get accountPoolSerial => 'Un par un';

  @override
  String get accountPoolPinnedHint =>
      'Toujours commencer par le premier compte. Les autres restent en secours en cas d\'échec.';

  @override
  String get accountPoolRoundRobinHint =>
      'Répartir les exécutions entre les comptes, en passant au suivant à chaque envoi.';

  @override
  String get accountPoolSerialHint =>
      'Épuiser le premier compte avant de passer au suivant.';

  @override
  String get accountPoolMoveUp => 'Monter';

  @override
  String get accountPoolMoveDown => 'Descendre';

  @override
  String get accountPoolUsingAll =>
      'Aucun compte attaché — tous sont utilisés, dans cet ordre.';

  @override
  String get accountPoolInheriting =>
      'Hérite des comptes de l\'espace de travail.';

  @override
  String get accountPoolResetToWorkspace =>
      'Revenir aux comptes de l\'espace de travail';

  @override
  String accountPoolCoolingOff(String when) {
    return 'quota épuisé jusqu\'à $when';
  }

  @override
  String get accountPoolSignedOut => 'déconnecté';

  @override
  String get accountPoolExpired => 'connexion expirée';

  @override
  String accountPoolLoadFailed(String error) {
    return 'Impossible de charger la rotation : $error';
  }

  @override
  String get providerSignedInAccount => 'compte connecté';

  @override
  String get agentAccountsTab => 'Comptes';

  @override
  String get agentClaudeAccountsNoticeTitle => 'Plusieurs comptes Claude Code';

  @override
  String agentClaudeAccountsNoticeBody(int count) {
    return 'Ce lanceur se connecte avec l\'un des $count comptes Claude Code de cet hôte. Choisissez lequel, ou alternez entre eux, dans l\'onglet Comptes.';
  }

  @override
  String get agentAccountsDescription =>
      'Les comptes utilisés par les exécutions de cet agent. Chaque bloc hérite d\'abord du choix de l\'espace de travail.';

  @override
  String get agentAccountsNothingToRotate =>
      'Rien à faire tourner — connectez d\'abord un deuxième compte ou une deuxième clé.';

  @override
  String failedToPostReply(String error) {
    return 'Impossible de publier la réponse : $error';
  }

  @override
  String commentOnLine(int line) {
    return 'Ligne $line';
  }

  @override
  String get viewInDiff => 'Voir dans le diff';

  @override
  String get subscriptionUsagePreviousAccount => 'Compte précédent';

  @override
  String get subscriptionUsageNextAccount => 'Compte suivant';

  @override
  String inReplyTo(String path) {
    return 'En réponse à $path';
  }

  @override
  String get subscriptionUsageNoneReported =>
      'Aucune utilisation signalée pour ce compte.';

  @override
  String get subscriptionUsageCredits => 'Crédits';

  @override
  String get reviewHubStaticRule => 'Règle statique';

  @override
  String get reviewHubStarted => 'Revue démarrée';

  @override
  String reviewHubStaticRuleTooltip(String rule) {
    return 'Trouvé par une règle déterministe ($rule) sur une ligne ajoutée par cette pull request — pas par un agent réviseur.';
  }

  @override
  String get prReviewArtifactTab => 'Revue de PR';

  @override
  String get prReviewRunning => 'Revue de cette pull request…';

  @override
  String get prReviewStarting => 'Démarrage de la revue…';

  @override
  String get prReviewStartingBody =>
      'Préparation du worktree de cette pull request. Les relecteurs démarrent dès qu\'il est prêt.';

  @override
  String get prReviewFailed => 'Échec de la revue.';

  @override
  String get prReviewRerunning => 'Nouvelle revue…';

  @override
  String get prReviewNoOpenFindings => 'Aucune remarque ouverte';

  @override
  String prReviewOpenFindings(int count) {
    return '$count remarques ouvertes';
  }

  @override
  String subscriptionUsageSpend(String used, String limit) {
    return '$used sur $limit';
  }

  @override
  String reviewCommentsPosted(int posted, int skipped, int failed) {
    return '$posted commentaire(s) publié(s) par le bot. $skipped ignoré(s) (sans ancre de fichier), $failed en échec.';
  }

  @override
  String reviewFindingsOutOfDiff(int count, String files) {
    return '$count constatation(s) portent sur du code que cette pull request ne modifie pas ($files). GitHub n\'accepte les commentaires en ligne que sur le diff.';
  }

  @override
  String get reviewRailReport => 'Rapport';

  @override
  String get reviewNoFindingsTitle => 'Aucun constat pour l\'instant';

  @override
  String get reviewNoFindingsHint =>
      'Les constats apparaîtront ici au fur et à mesure que les agents les publient.';

  @override
  String reviewShowDismissed(int count) {
    return 'Afficher $count rejeté(s)';
  }

  @override
  String reviewHideDismissed(int count) {
    return 'Masquer $count rejeté(s)';
  }

  @override
  String reviewDisagreementsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count désaccords entre relecteurs détectés',
      one: '1 désaccord entre relecteurs détecté',
    );
    return '$_temp0';
  }

  @override
  String get reviewFilterKind => 'Type';

  @override
  String get reviewFilterStatus => 'Statut';

  @override
  String get reviewKindBug => 'Bogue';

  @override
  String get reviewKindSuggestion => 'Suggestion';

  @override
  String get reviewKindRecommendation => 'Recommandation';

  @override
  String get reviewKindQuestion => 'Question';

  @override
  String get reviewKindTicket => 'Ticket';

  @override
  String get archiveSpace => 'Archiver l\'espace';

  @override
  String get archivedSpaces => 'Espaces archivés';

  @override
  String get archivedSpacesEmpty => 'Aucun espace archivé';

  @override
  String get restoreSpace => 'Restaurer';

  @override
  String archivedWhen(String time) {
    return 'Archivé $time';
  }

  @override
  String get deleteSpacePermanently => 'Supprimer définitivement';

  @override
  String get renameSpace => 'Renommer l\'espace';

  @override
  String get renameConversation => 'Renommer la conversation';

  @override
  String get editSpaceRepos => 'Modifier les dépôts';

  @override
  String get editSpaceReposTitle => 'Dépôts de l\'espace';

  @override
  String get editSpaceReposWarning =>
      'Ajouter un dépôt le récupère dans cet espace ; en retirer un supprime son dossier.';

  @override
  String get agentSectionIdentity => 'Identité';

  @override
  String get agentSectionRuntime => 'Exécution';

  @override
  String get agentSectionGuardrails => 'Garde-fous';

  @override
  String orgChartReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subordonnés',
      one: '1 subordonné',
    );
    return '$_temp0';
  }

  @override
  String get teamsFilterHint => 'Filtrer les équipes…';

  @override
  String get teamsSummaryWithLeader => 'Avec un responsable';

  @override
  String teamCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count équipes',
      one: '1 équipe',
      zero: 'Aucune équipe',
    );
    return '$_temp0';
  }

  @override
  String agentDeleteLongDescription(String name) {
    return 'Supprimer $name efface son profil, ses liens de compétences et son historique d’exécution. Cette action est irréversible.';
  }

  @override
  String get resetToDefault => 'Rétablir par défaut';

  @override
  String get newAgent => 'Nouvel agent';

  @override
  String get newSkill => 'Nouvelle compétence';

  @override
  String get zoomIn => 'Zoom avant';

  @override
  String get zoomOut => 'Zoom arrière';

  @override
  String get resetZoom => 'Réinitialiser le zoom';

  @override
  String get imageHostedOnGitHub => 'Image hébergée sur GitHub';

  @override
  String get imageOpenExternally => 'Image · ouvrir en externe';

  @override
  String get memoryScopeAll => 'Toutes les portées';

  @override
  String get memoryScopeWorkspace => 'À l\'échelle de l\'espace de travail';

  @override
  String get memoryScopeFilterLabel => 'Filtrer par portée';

  @override
  String memoryScopeRepoTooltip(String repo) {
    return 'Limité au dépôt $repo';
  }

  @override
  String get toolScreenshot => 'Capture d\'écran de l\'agent';

  @override
  String get toolImageUnavailable => 'Image indisponible';

  @override
  String toolImagesUnavailable(int count) {
    return '$count images indisponibles';
  }

  @override
  String get shakeUnavailable =>
      'Le délestage n\'est pas disponible sur ce serveur';

  @override
  String get shakeNothing =>
      'Rien à délester — les tours récents sont protégés';

  @override
  String shakeDone(int tokens) {
    return 'Environ $tokens jetons libérés';
  }

  @override
  String get compactionDivider => 'Compacté';

  @override
  String compactionDividerCount(int count) {
    return 'Compacté · $count messages repliés';
  }

  @override
  String get composerDropToAttach => 'Déposer pour joindre';

  @override
  String get attachmentUnavailable => 'Pièce jointe indisponible';

  @override
  String get attachmentUnavailableDetail =>
      'Cette pièce jointe n\'est plus en mémoire. Joignez-la à nouveau pour l\'aperçu.';

  @override
  String get attachmentPreviewFailed => 'Impossible d\'ouvrir ce fichier';

  @override
  String get attachmentPreviewUnsupported =>
      'Aucun aperçu pour ce type de fichier';

  @override
  String get attachmentTooLargeToPreview => 'Trop volumineux pour l\'aperçu';

  @override
  String get attachmentOpenExternally =>
      'Ouvrir dans l\'application par défaut';

  @override
  String get asideUnavailable =>
      'Définissez un modèle ponctuel dans les paramètres pour l\'utiliser';

  @override
  String get asideEmpty => 'Rien à exploiter pour l\'instant';

  @override
  String get asideFailed => 'Impossible d\'obtenir une réponse';

  @override
  String get handoffTitle => 'Transmission';

  @override
  String get asideTitle => 'Question annexe';

  @override
  String get attachFilesOrDrop => 'Joindre des fichiers — ou déposez-les ici';

  @override
  String get guidedGoalTitle => 'Affiner l\'objectif';

  @override
  String get guidedGoalIntro =>
      'Un agent qui travaille sans supervision doit savoir précisément quand il a terminé. Quelques questions d\'abord.';

  @override
  String get guidedGoalAnswerHint => 'Votre réponse';

  @override
  String get guidedGoalNext => 'Suivant';

  @override
  String get guidedGoalStart => 'Lancer l\'objectif';

  @override
  String get guidedGoalSkip => 'Ignorer et lancer tel quel';

  @override
  String guidedGoalStillMissing(String items) {
    return 'Toujours non spécifié : $items';
  }

  @override
  String get conversationTreeTitle => 'Arborescence de la conversation';

  @override
  String conversationTreeBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count branches',
      one: '1 branche',
    );
    return '$_temp0';
  }

  @override
  String get conversationTreeSwitch => 'Continuer d\'ici';

  @override
  String get conversationTreeFork => 'Dupliquer dans une nouvelle conversation';

  @override
  String get conversationTreeCurrent => 'Sur cette branche';

  @override
  String get conversationTreeEmpty => 'Rien pour l\'instant';

  @override
  String get conversationTreeForked =>
      'Dupliquée dans une nouvelle conversation';

  @override
  String get conversationTreeSwitched => 'La suite partira de ce message';

  @override
  String exportSaved(String path) {
    return 'Enregistré dans $path';
  }

  @override
  String get exportFailed => 'Impossible d\'écrire l\'export';

  @override
  String get contextCommandNoAgent =>
      'Aucun agent dans cette conversation, il n’y a donc aucune fenêtre de contexte à ouvrir';

  @override
  String contextCommandNoSuchAgent(String name, String names) {
    return 'Aucun agent nommé « $name » dans cette conversation. Essayez : $names';
  }

  @override
  String get dumpCopied => 'Transcription copiée dans le presse-papiers';

  @override
  String get messageQueueHint =>
      'Continuez à taper pour mettre les ajustements en file d’attente';

  @override
  String get steerNow => 'Guider';

  @override
  String get steeringQueueLabel => 'Messages de pilotage en attente';

  @override
  String get steeringDeliverUnavailable =>
      'Aucun agent en cours ne peut le prendre pour l’instant — il reste en attente.';

  @override
  String get reorderSteeringCard => 'Réordonner le message en attente';

  @override
  String get editSteeringCard => 'Modifier le message en attente';

  @override
  String get deleteSteeringCard => 'Supprimer le message en attente';

  @override
  String get steeringBadge => 'Piloté';

  @override
  String get settingsSandboxLabel => 'Bac à sable';

  @override
  String get sandboxExecGrantsTitle => 'Autorisations d\'exécution';

  @override
  String get sandboxExecGrantsSubtitle =>
      'Programmes que les agents peuvent exécuter depuis leur copie de travail de vos dépôts. Chaque entrée a été approuvée par vous lorsque le bac à sable l\'a demandé.';

  @override
  String get sandboxExecGrantsEmpty =>
      'Aucune décision enregistrée. Vous serez sollicité la première fois qu\'un agent devra exécuter un programme depuis sa copie de travail.';

  @override
  String get sandboxExecGrantRevoke => 'Révoquer';

  @override
  String get sandboxExecGrantAllowed => 'Autorisé';

  @override
  String get sandboxExecGrantBlocked => 'Bloqué';

  @override
  String get sandboxExecGrantRevokeConfirmTitle => 'Révoquer cette décision ?';

  @override
  String get sandboxExecGrantRevokeConfirmBody =>
      'Vous serez sollicité à nouveau la prochaine fois qu\'un agent devra exécuter un programme depuis cette copie.';

  @override
  String get repoScriptsTest => 'Tester';

  @override
  String get repoScriptsTestTooltip =>
      'Exécuter ce brouillon dans un clone jetable du dépôt';

  @override
  String get repoScriptsRunKindTest => 'Test';

  @override
  String get demoBadgeLabel => 'Démo';

  @override
  String get demoFilePickerTitle => 'Fichiers de démo';

  @override
  String get demoFilePickerBody =>
      'La démo simule les envois : choisissez-en un et il s\'attache à votre message sans toucher à un disque.';

  @override
  String get demoFilePickerAttach => 'Joindre';

  @override
  String get demoReadOnlySave => 'Lecture seule dans la démo';

  @override
  String get demoBadgeTooltip =>
      'Vous explorez une démo. Les données sont fictives et les agents sont scriptés.';

  @override
  String get demoFirstRunTitle => 'Vous êtes dans une démo en direct';

  @override
  String demoFirstRunBody(int minutes) {
    return 'C\'est la vraie application, sur du vrai code — seules les données sont inventées. Les agents diffusent de véritables exécutions à partir d\'un script : rien n\'atteint un modèle et rien ne s\'exécute sur une machine. Votre espace de travail n\'appartient qu\'à vous et disparaît après $minutes minutes.';
  }

  @override
  String get demoFirstRunDismiss => 'J\'ai compris';

  @override
  String get demoTourTitle => 'Par où commencer';

  @override
  String get demoTourSubtitle =>
      'Quatre endroits qui montrent ce que fait vraiment l\'application.';

  @override
  String get demoTourSkip => 'Passer';

  @override
  String get demoTourStarRepo => 'Mettre une étoile sur GitHub';

  @override
  String get demoTourDone => 'Terminé';

  @override
  String get demoTourOpen => 'Ouvrir';

  @override
  String get demoTourSpacesTitle => 'Parler à un agent';

  @override
  String get demoTourSpacesBody =>
      'Envoyez un message dans un espace et regardez une exécution arriver en direct — raisonnement, appels d\'outils et coût, exactement comme une vraie exécution.';

  @override
  String get demoTourReviewTitle => 'Réviser une pull request';

  @override
  String get demoTourReviewBody =>
      'Ouvrez la #412. Laissez un commentaire en ligne ou soumettez une revue : vos mots apparaissent dans le fil et y restent.';

  @override
  String get demoTourTicketsTitle => 'Suivre le travail';

  @override
  String get demoTourTicketsBody =>
      'Les tickets, les tâches et les plans sont liés aux conversations que les agents mènent.';

  @override
  String get demoTourInboxTitle => 'Voir toute l\'opération';

  @override
  String get demoTourInboxBody =>
      'Chaque alerte de chaque pilier arrive dans une seule boîte de réception — revues, tickets, exécutions et réunions.';

  @override
  String demoSessionEndingSoon(int minutes) {
    return 'Cette session de démo se termine dans $minutes minutes.';
  }

  @override
  String get demoSessionEnded =>
      'Cette session de démo est terminée. Rechargez la page pour en démarrer une nouvelle.';

  @override
  String get demoUnavailableTitle => 'Indisponible dans la démo';

  @override
  String get demoUnavailableTerminal =>
      'Un terminal exécute un vrai shell sur le serveur. La démo n\'a aucune surface d\'exécution — c\'est ce qui permet de l\'ouvrir au public en toute sécurité.';

  @override
  String get demoUnavailableRig =>
      'Une enceinte est une machine virtuelle jetable pilotée par un agent. La démo n\'en démarre aucune : un point d\'accès public capable de lancer une VM n\'est pas une démo.';

  @override
  String get demoUnavailableEditor =>
      'L\'éditeur dans le navigateur exécute un processus code-server sur une vraie copie de travail. La démo n\'a ni l\'un ni l\'autre.';

  @override
  String get demoUnavailableFeeds =>
      'La démo lit de vrais flux, mais sa liste d\'abonnements est figée. Ajouter ou retirer un flux est désactivé ici.';

  @override
  String get demoUnavailableForge =>
      'La démo ne détient aucun identifiant et ne contacte jamais GitHub, GitLab ni Linear. Ses pull requests sont des fixtures et vos commentaires restent locaux.';

  @override
  String get demoUnavailableModels =>
      'La démo n\'appelle aucun modèle. Les exécutions d\'agents sont des rejeux scriptés, d\'où leur coût nul et l\'absence de tout fournisseur.';

  @override
  String get demoUnavailableMcp =>
      'La surface d\'outils MCP n\'est pas montée sur la démo ; aucun client externe ne peut s\'y connecter.';

  @override
  String get demoUnavailableRepos =>
      'La démo ne récupère aucun code et n\'exécute aucune commande git. Le dépôt affiché est une fixture derrière les pull requests.';

  @override
  String get demoUnavailableSkills =>
      'Installer une compétence télécharge et analyse du code. La démo ne récupère rien.';

  @override
  String get demoUnavailableSso =>
      'L\'authentification unique relève de la configuration serveur. La démo vous connecte plutôt en tant qu\'invité temporaire.';

  @override
  String get demoUnavailableAudio =>
      'L\'enregistrement et la dictée nécessitent une capture audio et un modèle vocal sur l\'hôte. La démo n\'embarque ni l\'un ni l\'autre : ses réunions sont des transcriptions sans lecture.';

  @override
  String get demoUnavailableServerAdmin =>
      'Il s\'agit d\'administration serveur. La démo vous donne un espace de travail jetable et rien de plus.';

  @override
  String get settingsBackupRestore => 'Sauvegarde et restauration';

  @override
  String get settingsBackupRestoreDescription =>
      'Instantanés de toutes les bases de données de ce serveur, ainsi que l\'export, l\'import et la suppression d\'un espace de travail.';

  @override
  String get backupSnapshotsLabel => 'Instantanés de l\'installation';

  @override
  String get backupSnapshotsExplainer =>
      'Un instantané copie chaque base de données dans un dossier horodaté sur l\'hôte du serveur. Restaurer toute l\'installation revient à recopier ce dossier avec le serveur arrêté ; un espace de travail seul peut être restauré ici.';

  @override
  String get backupNowAction => 'Sauvegarder maintenant';

  @override
  String backupSnapshotWritten(String path) {
    return 'Instantané écrit dans $path';
  }

  @override
  String get backupNoSnapshots =>
      'Aucun instantané pour l\'instant. Il n\'en est pris que si vous le demandez — rien n\'est planifié.';

  @override
  String get backupSnapshotComplete => 'Complet';

  @override
  String get backupSnapshotIncomplete => 'Incomplet';

  @override
  String get backupSnapshotIncompleteNote =>
      'Le manifeste est absent ou désigne des fichiers manquants : cet instantané ne peut pas restaurer toute l\'installation. Les fichiers d\'espace de travail qu\'il contient restent adoptables un par un.';

  @override
  String backupSnapshotWorkspaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count espaces de travail',
      one: '1 espace de travail',
      zero: 'Aucun espace de travail',
    );
    return '$_temp0';
  }

  @override
  String backupSnapshotSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count espaces de travail non capturés',
      one: '1 espace de travail non capturé',
    );
    return '$_temp0';
  }

  @override
  String get backupServerPathLabel => 'Chemin sur le serveur';

  @override
  String get backupRestoreAction => 'Restaurer';

  @override
  String get backupRestoreTitle => 'Restaurer l\'espace de travail';

  @override
  String backupRestoreBody(String name) {
    return 'Cela remplace tout le contenu de $name par la copie conservée dans cet instantané. Tout ce que cet espace de travail a fait depuis est perdu, et c\'est irréversible.';
  }

  @override
  String backupRestoreDone(String name) {
    return '$name restauré depuis l\'instantané.';
  }

  @override
  String get backupWorkspaceUnknown => 'N\'existe plus sur ce serveur';

  @override
  String get backupWorkspaceDataLabel => 'Données des espaces de travail';

  @override
  String get backupWorkspaceDataExplainer =>
      'Un espace de travail tient dans un seul fichier de base de données : l\'export copie ce fichier au lieu de vider table par table. L\'import remplace tout le contenu de l\'espace de travail cible par le fichier indiqué.';

  @override
  String get backupExportAction => 'Exporter';

  @override
  String backupExportDone(String path) {
    return 'Exporté vers $path';
  }

  @override
  String get backupExportedFileLabel => 'Fichier exporté sur le serveur';

  @override
  String get backupImportAction => 'Importer';

  @override
  String backupImportTitle(String name) {
    return 'Importer dans $name';
  }

  @override
  String backupImportBody(String name) {
    return 'Cela remplace tout le contenu de $name par celui du fichier. Ce que contient cet espace de travail est perdu, et c\'est irréversible.';
  }

  @override
  String get backupImportSourceLabel =>
      'Fichier de base de données d\'espace de travail';

  @override
  String get backupImportSourceDescription =>
      'Un fichier .db lisible par le serveur. Les chemins sont résolus sur l\'hôte du serveur, pas sur cet appareil.';

  @override
  String get backupImportChooseFile => 'Choisir un fichier';

  @override
  String backupImportDone(String name) {
    return 'Importé dans $name.';
  }

  @override
  String backupDeleteBody(String name) {
    return '$name disparaît de toutes les listes et recherches. Son fichier de base de données reste sur le disque, les sauvegardes continuent de l\'inclure, et rien ne récupère cet espace automatiquement.';
  }

  @override
  String get backupExportDescription =>
      'Écrire une copie sur le serveur, ou en télécharger une sur cet appareil.';

  @override
  String get backupExportOnServerAction => 'Enregistrer sur le serveur';

  @override
  String get backupDownloadAction => 'Télécharger';

  @override
  String backupDownloadSaved(String path) {
    return 'Enregistré dans $path';
  }

  @override
  String get backupDownloadInBrowser => 'Votre navigateur s\'en charge.';

  @override
  String get backupRestoreFromDeviceLabel => 'Restaurer depuis cet appareil';

  @override
  String get backupRestoreFromDeviceDescription =>
      'Choisissez ici un fichier de base de données d\'espace de travail et Control Center l\'envoie au serveur. C\'est la méthode qui fonctionne quand le serveur n\'est pas cette machine.';

  @override
  String get backupUploadAction => 'Choisir un fichier et l\'envoyer';

  @override
  String get backupTransferUnavailable =>
      'Cette connexion passe par un relais, qui ne transporte aucun fichier. Connectez-vous directement au serveur pour télécharger ou envoyer une sauvegarde.';

  @override
  String get backupTransferForbidden =>
      'Le serveur a refusé. Télécharger un espace de travail demande le rôle admin, en restaurer un demande owner, et un instantané complet demande l\'opérateur de l\'installation.';

  @override
  String get backupTransferUnsupported =>
      'Ce serveur n\'expose aucune surface de sauvegarde.';

  @override
  String get backupTransferTooLarge =>
      'Le fichier dépasse la taille acceptée par le serveur.';

  @override
  String get credentialGateWaitingTitle => 'En attente d\'un identifiant';

  @override
  String credentialGateHarnessTitle(String provider) {
    return '$provider n\'a aucun identifiant';
  }

  @override
  String get credentialGateSignedOutTitle => 'Claude Code est déconnecté';

  @override
  String get credentialGateExpiredTitle =>
      'Votre connexion Claude Code a expiré';

  @override
  String get credentialGatePlanSpentTitle =>
      'Limite du forfait Claude Code atteinte';

  @override
  String credentialGateWaitingAgent(String agent) {
    return '$agent attend pour continuer.';
  }

  @override
  String get credentialGateWaitingRun => 'Une exécution attend pour continuer.';

  @override
  String get credentialGateWatching =>
      'Surveillance en cours — l\'exécution reprend d\'elle-même.';

  @override
  String credentialGateFreesUpAt(String time) {
    return 'Se libère à $time';
  }

  @override
  String credentialGateGivesUpAt(String time) {
    return 'L\'exécution abandonne à $time';
  }

  @override
  String get credentialGateCheckAgain => 'Vérifier à nouveau';

  @override
  String get credentialGateCancelRun => 'Annuler l\'exécution';

  @override
  String get credentialGateAccountsTried => 'Comptes essayés';

  @override
  String get credentialGateClaudeSignInHint =>
      'Connectez-vous depuis Paramètres → Adaptateurs → Claude Code, ou lancez la commande de connexion dans un terminal. L\'exécution la détecte d\'elle-même.';

  @override
  String get credentialGateOpenSettings => 'Ouvrir les paramètres';
}
