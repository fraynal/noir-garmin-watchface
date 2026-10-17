# NoirWatchFace — notes de chantier

## Chantier 1 : jour/nuit météo, complications, dépôt (17/10/2026)

### Fait
- **`.gitignore`** : `bin/` (sorties de compilation) n'est plus versionné.
- **Complications** : `onComplicationChanged` compare les `Complications.Id`
  avec `equals()` au lieu de `==` (égalité de références en Monkey C).
  À valider sur la montre : FC et Body Battery doivent se mettre à jour.
- **Jour/nuit de l'icône météo** : au lieu de la plage fixe 7h–19h, le cadran
  utilise `Weather.getSunrise` / `getSunset` à la position du relevé météo
  (`CurrentConditions.observationLocationPosition`).
  Repli sur 7h–19h si position, lever ou coucher indisponibles.
  Seules 3 familles d'icônes ont une variante jour/nuit : dégagé, éclaircies,
  averses légères.
- **Permission `Positioning`** ajoutée au manifest : sans elle,
  `observationLocationPosition` vaut toujours `null` (le cadran restait en repli).
  La montre affiche cette permission à l'installation.

### Bug possible restant : heures de lever/coucher
Dans le simulateur (SDK 9.2.0, fenix9pro47mm), `getSunrise` / `getSunset`
renvoient des heures décalées d'environ **+6 h** et un coucher daté de la
**veille** (coucher avant le lever) :

| Position | Lever attendu (heure de Paris) | Renvoyé | Coucher attendu | Renvoyé |
|---|---|---|---|---|
| Paris (48.85, 2.35) | 17/10 08:20 | 17/10 14:11 | 17/10 18:58 | 17/10 01:00 |
| Olathe, Kansas (38.85, -94.80) | 17/10 ~14:30 | 17/10 20:28 | 18/10 ~01:40 | 17/10 07:41 |

Conséquence : avec Paris, la lune s'affiche à 13h. Le décalage d'environ 6 h
correspond au fuseau du Kansas (siège de Garmin) en heure d'hiver : bug
probable du simulateur, **non confirmé sur la montre**.

À faire :
1. Tester sur la montre par ciel dégagé, avant le lever et après le coucher.
2. Si c'est faux aussi sur la montre : remplacer l'API par un calcul local
   du lever et du coucher (position + date), et tolérer un coucher daté de la veille.
3. Une fois validé : retirer la trace `DEBUG temporaire` (`System.println`
   « DBG » et `debugTime`) de `source/NoirWatchFaceView.mc`.

### Tester dans le simulateur
- *Set Weather* : condition *Clear*, champ **Observation Location Position**
  (`lat, lon` en degrés). L'heure de *Set Weather* est l'heure du relevé,
  pas celle de la montre.
- *Time Simulation* : règle l'heure de la montre.
- La console de débogage affiche une ligne `DBG cond=… loc=… now=… rise=… set=… night=…`.
- La position du simulateur revient parfois à sa valeur par défaut (Kansas).

## Chantier 2 : positions fixes (17/10/2026)

### Fait
- Taille des icônes lue sur les images (`getWidth()` / `getHeight()`) au lieu
  de valeurs en dur. Ça corrige deux erreurs : cœur, éclair et pas (24 px)
  étaient centrés comme des images de 30 px (décalés de 3 px), et l'icône
  météo comptait 29 px au lieu de 30.
- Marges et batterie dessinée multipliées par un facteur d'échelle
  `s = largeur / 454` (fenix 9 Pro 47 mm = 1.0, donc rendu inchangé à part
  le centrage corrigé).
- Positions verticales et horizontales : déjà en proportion de l'écran.

### Reste à faire à l'ajout d'une autre montre
- Les images gardent leur taille en pixels : les adapter dans le fichier de
  ressources (`scaleX` / `scaleY` avec `scaleRelativeTo="screen"`) ou fournir
  des images par résolution.
- Les polices sont propres à chaque montre : vérifier les chevauchements.

## Chantier 3 : écran de veille (17/10/2026)

Définition : `veille.png` (maquette sur fond noir : seuls les rapports de
taille et d'écart entre les éléments comptent, pas leur place à l'écran).

### Fait
- `onEnterSleep` / `onExitSleep` basculent `mSleeping` ; en veille,
  `onUpdate` appelle `drawSleep` : date, heure, batterie uniquement
  (ni météo ni mesures de santé). Le système redessine une fois par minute ;
  un changement de FC / Body Battery ne déclenche plus de redessin en veille.
- Deux gris : heure `#9A9FA7`, date et batterie `#71787F`.
  Polices : heure `FONT_NUMBER_MILD`, date et batterie `FONT_XTINY`.
- Heure au centre du cadran ; date au-dessus et batterie en dessous,
  centrées sur l'heure. Écarts en hauteurs de police de l'heure :
  `SLEEP_DATE_OFFSET = 1.0`, `SLEEP_BATTERY_OFFSET = 1.15`
  (calés sur la maquette d'après une capture du simulateur).
- Anti-marquage AMOLED : le bloc se décale chaque minute sur une grille 5×5,
  pas de 2 px (±4 px), horizontalement chaque minute, verticalement toutes
  les 5 minutes.
- Luminance mesurée dans le simulateur (Screen Heat Map) : **2,36 %**
  (limite Garmin : 10 %).

### Tester
- Simulateur : *Display Mode* > *Always-On* (ou *Sleep Event*) ;
  *File > View Screen Heat Map* > *Start* pour la luminance sur 24 h.
- Montre : activer l'écran toujours allumé, baisser le poignet.

## Chantier 4 : options (17/10/2026)

Réglages dans l'app Garmin Connect (cadran > réglages).
Fichiers : `resources/settings/properties.xml` (valeurs par défaut) et
`settings.xml` (interface) ; `NoirWatchFaceApp.onSettingsChanged` fait relire
les réglages à la vue (`loadSettings`).

| Réglage | Valeurs | Défaut |
|---|---|---|
| `ShowSeconds` | oui / non | non |
| `TimeFormat` | comme la montre / 24 h / 12 h (AM/PM) | comme la montre |
| `ShowWeather` | oui / non | oui |
| `TemperatureUnit` | comme la montre / °C / °F | comme la montre |
| `ShowBatteryPercent` | oui / non | oui |

- « Comme la montre » relit `System.getDeviceSettings()` (`is24Hour`,
  `temperatureUnits`) à chaque dessin.
- Secondes : jamais en veille (redessin une fois par minute). Police
  `FONT_TINY`, sans police de chiffres plus petite que `FONT_NUMBER_MILD`.
- `HH:MM` reste centré ; secondes alignées sur le bas des chiffres, AM/PM sur
  leur haut. La hauteur des chiffres est estimée (`ascent - descent`) :
  à revérifier sur une autre montre.
- En 12 h : pas de zéro devant l'heure (`1:05`).
- AM/PM et batterie sans % s'appliquent aussi en veille.

## Chantiers suivants
- **Indicateurs configurables** (gros chantier) : choisir les trois
  indicateurs (aujourd'hui FC, Body Battery, pas) parmi stress, calories,
  étages, distance, minutes d'intensité… via les complications Garmin.
  Demande une liste de choix par emplacement, une icône et un format de valeur
  pour chaque donnée.
- **Icône du lanceur** : 24×24 alors que la fenix 9 attend 65×65
  (agrandie automatiquement, avertissement du compilateur).
