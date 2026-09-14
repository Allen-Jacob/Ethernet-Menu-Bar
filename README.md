# Ethernet Menu Bar

Une petite application macOS native qui affiche l’état de la connexion Ethernet dans la barre des menus.

L’icône apparaît lorsqu’un câble Ethernet est connecté et disparaît complètement lorsque le lien est coupé. La vitesse affichée (`1G`, `2.5G`, etc.) est la vitesse négociée entre le Mac, l’adaptateur et le routeur — ce n’est pas le débit Internet instantané.

## Fonctions

- Détection automatique des interfaces Ethernet avec l’API native de macOS
- Apparition et disparition dynamique de l’icône
- Vitesses prises en charge : 10 Mbit/s, 100 Mbit/s, 1, 2.5, 5 et 10 Gbit/s
- Quatre styles d’icône : réseau, câble, transfert et Ethernet Windows
- Affichage de la vitesse activable ou désactivable
- Débits réels de téléchargement et d’envoi visibles au clic sur l’icône
- Raccourci direct vers les réglages réseau de macOS
- Vérification de la connexion toutes les 1, 2 ou 5 secondes
- Mode test pour conserver l’icône visible sans câble
- Lancement automatique à l’ouverture de session
- Aucun élément dans le Dock
- Réglages sauvegardés automatiquement
- Assistant de premier lancement pour l’installation et l’ouverture automatique
- Compilation et publication automatiques avec GitHub Actions
- Vérification automatique des nouvelles Releases GitHub
- Désinstallation intégrée depuis les réglages
- Ouverture directe des réglages lorsqu’on relance l’app depuis Spotlight ou Finder
- Liens vers [jacoballen.ca](https://jacoballen.ca) et la [page des projets](https://jacoballen.ca/projects)
- Position de l’indicateur conservée pendant les déconnexions, y compris avec Ice

## Installation

[Télécharger la dernière version (`Ethernet-Menu-Bar.dmg`)](https://github.com/Allen-Jacob/Ethernet-Menu-Bar/releases/latest/download/Ethernet-Menu-Bar.dmg)

### Installation automatique

Le script construit, signe, copie l’app dans `/Applications`, la lance et confirme que son processus fonctionne :

```sh
./scripts/install-app.sh
```

### Image disque

Pour créer un installateur visuel standard avec un raccourci vers Applications :

```sh
./scripts/create-dmg.sh
```

Ouvre ensuite le `.dmg` produit dans `dist`, puis suis la flèche **Glisser vers Applications**.

Le script de construction utilise automatiquement la première identité de signature Apple disponible dans le trousseau, avec une signature ad hoc comme solution de repli.

Les Releases sont signées et notariées par Apple lorsque les secrets Developer ID sont configurés dans GitHub Actions. C’est ce qui supprime l’alerte Gatekeeper « Apple n’a pas pu vérifier… » pour les téléchargements.

> Pour que « Ouvrir automatiquement à la connexion » fonctionne correctement, place d’abord l’application dans le dossier Applications.

### Si Ice masque l’icône

Ice place parfois les nouveaux éléments tout à gauche, dans sa section « Toujours masquée ». Ethernet Menu Bar utilise un identifiant de position macOS persistant et réduit le même élément à une largeur nulle pendant la déconnexion, au lieu de le retirer puis de le recréer. Après cette mise à jour, ouvre une seule fois **Ice → Disposition** et déplace l’indicateur `2.5G` dans **Visible**. Les déconnexions suivantes doivent conserver cette position.

## Développement

Prérequis : macOS 14 ou plus récent et les outils de ligne de commande Xcode.

```sh
swift run EthernetMenuBar
```

Le projet est un package Swift sans dépendance externe. L’interface combine AppKit pour l’élément de barre des menus et SwiftUI pour les réglages.

## Tests

```sh
swift test
```

Les tests couvrent la détection de l’état actif et l’interprétation des vitesses annoncées par l’interface réseau.

## Intégration continue

La GitHub Action exécute les tests et construit automatiquement le `.app` et le `.dmg` à chaque push sur `main`. Les fichiers sont accessibles dans les artefacts du workflow. Un tag comme `v0.3.4` crée également une Release GitHub avec les deux formats téléchargeables.

Chaque Release publie toujours les mêmes noms de fichiers, sans numéro de version : `Ethernet-Menu-Bar.dmg` et `Ethernet-Menu-Bar.zip`. Le lien permanent du DMG est :

```text
https://github.com/Allen-Jacob/Ethernet-Menu-Bar/releases/latest/download/Ethernet-Menu-Bar.dmg
```

L’application utilise Sparkle pour vérifier, télécharger, installer et relancer les nouvelles versions sans ouvrir de DMG. La commande **Rechercher les mises à jour…** lance une vérification manuelle. Les Releases publient aussi des deltas binaires : lorsque la version installée est prise en charge, seuls les changements sont téléchargés; Sparkle retombe automatiquement sur l’archive complète si un delta n’est pas disponible ou applicable.

Pour activer la signature et la notarisation, ajoutez dans **Settings → Secrets and variables → Actions** les secrets `DEVELOPER_ID_APPLICATION_P12` (le `.p12` encodé en base64), `DEVELOPER_ID_APPLICATION_PASSWORD`, `BUILD_KEYCHAIN_PASSWORD`, `APPLE_ID`, `APPLE_APP_PASSWORD`, `APPLE_TEAM_ID` et `SPARKLE_PRIVATE_KEY`. Ce dernier s’exporte avec `generate_keys --account ca.jacoballen.EthernetMenuBar -x private-key` et doit rester secret. Sans les secrets Apple, l’Action produit une signature ad hoc et macOS peut encore afficher l’avertissement Gatekeeper.

## Confidentialité

Ethernet Menu Bar analyse la connexion entièrement sur le Mac et n’effectue aucun suivi. Si la recherche de mises à jour est activée, elle contacte uniquement l’API publique de GitHub pour lire la dernière Release du projet.

## Licence

Projet personnel. Aucune licence de redistribution n’est accordée pour le moment.
