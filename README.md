# Ethernet Menu Bar

Une petite application macOS native qui affiche l’état de la connexion Ethernet dans la barre des menus.

L’icône apparaît lorsqu’un câble Ethernet est connecté et disparaît complètement lorsque le lien est coupé. La vitesse affichée (`1G`, `2.5G`, etc.) est la vitesse négociée entre le Mac, l’adaptateur et le routeur — ce n’est pas le débit Internet instantané.

## Fonctions

- Détection automatique des interfaces Ethernet avec l’API native de macOS
- Apparition et disparition dynamique de l’icône
- Vitesses prises en charge : 10 Mbit/s, 100 Mbit/s, 1, 2.5, 5 et 10 Gbit/s
- Trois styles d’icône : réseau, câble et transfert
- Affichage de la vitesse activable ou désactivable
- Vérification de la connexion toutes les 1, 2 ou 5 secondes
- Mode test pour conserver l’icône visible sans câble
- Lancement automatique à l’ouverture de session
- Aucun élément dans le Dock
- Réglages sauvegardés automatiquement

## Installation

1. Construis l’application avec la commande ci-dessous.
2. Glisse `dist/Ethernet Menu Bar.app` dans le dossier `/Applications`.
3. Ouvre l’application.
4. Clique sur son icône, puis sur **Réglages…** pour la personnaliser.

```sh
./scripts/build-app.sh
open "dist/Ethernet Menu Bar.app"
```

Le script crée une version optimisée dans `dist/Ethernet Menu Bar.app`. Il utilise automatiquement la première identité de signature Apple disponible dans le trousseau, avec une signature ad hoc comme solution de repli.

> Pour que « Ouvrir automatiquement à la connexion » fonctionne correctement, place d’abord l’application dans le dossier Applications.

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

## Confidentialité

Ethernet Menu Bar fonctionne entièrement sur le Mac. Elle n’envoie aucune donnée, n’effectue aucun suivi et ne contacte aucun service externe.

## Licence

Projet personnel. Aucune licence de redistribution n’est accordée pour le moment.
