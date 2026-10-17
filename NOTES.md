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
> Remplacé au chantier 7 : le calcul n'utilise plus `Weather.getSunrise`.

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

## Chantier 5 : mise en page et icônes (17/10/2026)

### Mise en page (écran actif)
Trois groupes : contexte (météo 13 %, date 25 % en `FONT_TINY`), heure au
centre optique (47 %), santé (icônes 66 %, valeurs 73,5 % en gris clair
`FONT_SMALL`) et batterie (87 %). Seule l'heure est en blanc.

### Icônes
- PNG remplacés par des SVG (`resources/images/*.svg`), convertis en images
  par le compilateur : météo 36 px, santé 28 px (attributs `width`/`height`).
- Originaux intacts dans `design/icons-original/` (hors `resources/`).
- Corrections : 7 icônes débordaient du cadre 24×24 (soleil/lune décalés,
  précipitations sous y = 24) ; leur `viewBox` est agrandi (24 minimum) pour
  tout contenir. Nuages remplis de noir quand un soleil/une lune passe derrière.
  Météo en `#B9C4D4` (gris de la température), santé dans ses couleurs.
- Redessinées : neige (points), givre (traits et points), orage (éclair avec
  liseré noir), inconnu (point d'interrogation dans un cercle), pas
  (empreintes). Formes inspirées de Lucide (licence ISC), comme les originaux.
- À vérifier : rendu des SVG par le compilateur Garmin (`transform`, arcs)
  sur la montre.

## Chantier 6 : réglages sur la montre (17/10/2026)

Les réglages Garmin Connect ne sont pas disponibles pour un cadran installé
par USB. `getSettingsView` (NoirWatchFaceApp) fournit un menu `Menu2`
(`source/NoirWatchFaceSettings.mc`) : interrupteurs pour secondes, météo,
% batterie ; lignes à 3 choix (format de l'heure, unité) qui passent au
choix suivant à chaque appui. Mêmes propriétés et libellés que
`resources/settings` ; chaque changement appelle `onSettingsChanged`.

- Montre : maintenir MENU > Cadran de montre > NoirWatchFace > Personnaliser.
- Simulateur : *Trigger App Settings*.
- La doc du SDK ne liste pas la fenix 9 (listes arrêtées à la fenix 8) :
  à confirmer sur la montre.

## Chantier 7 : jour/nuit par les complications lever/coucher (17/10/2026)

- `isNight` lit les complications `COMPLICATION_TYPE_SUNRISE` / `SUNSET` :
  secondes depuis minuit en heure locale, calculées par la montre.
  Comparaison sur l'heure de la journée seulement : plus de décalage de date
  ni de fuseau. Repli sur 7h–19h si indisponibles.
- `Weather.getSunrise`/`getSunset` et la permission `Positioning` retirés.
- Trace temporaire réduite : `DBG now=… rise=… set=…` (secondes), à retirer
  après validation sur la montre.
- Coucher « avant » le lever (coucher après minuit aux hautes latitudes, ou
  valeurs du simulateur) : le jour est l'intervalle lever → coucher en
  passant minuit. Le simulateur 9.2 renvoie des heures décalées (lever 20:29,
  coucher 07:41 pour sa position par défaut) : validation sur la montre seulement.

## Chantier 8 : traduction (17/10/2026)

- Textes en anglais par défaut (`resources/strings`), français dans
  `resources-fre/strings` ; langues déclarées dans le manifest (`eng`, `fre`).
- Garmin utilise ses propres codes de langue : français = `fre` (pas `fra`).
  Un mauvais code ne provoque aucune erreur de compilation : la traduction
  est simplement ignorée. Vérifier dans `bin/NoirWatchFace-settings.json`
  (section `languages`).
- Toute nouvelle chaîne s'ajoute dans les deux fichiers.

## Chantier 9 : indicateurs d'état (17/10/2026)

Affichés seulement quand l'état est actif (réglage `ShowStatusIcons`, oui par défaut) :
- **Téléphone déconnecté** (`phoneConnected`) : téléphone barré à 9 h, à
  hauteur de l'heure (position fixe, `cx - 0.38 × largeur`). Rare, doit se voir.
- **Ne pas déranger** (`doNotDisturb`) : lune mauve pleine (`#B9A2D8`,
  24 px, cadre resserré sur le croissant pour le centrer) à 12 px à gauche de
  la batterie, qui reste centrée (`drawBattery` renvoie sa position gauche).
  Pleine pour se distinguer de la lune météo (contour gris). Dessin propre
  (vrai croissant : disque r=9 moins disque r=8,5 décalé de 4) : la lune météo
  remplie donnait un disque échancré.
- En veille : mêmes icônes en version atténuée (`*_dim`), décalées avec le reste.
- Non retenus : notifications (cloche), alarme réglée (presque toujours active).
  Les modes de concentration ne sont pas accessibles aux cadrans.

## Chantier 10 : icône du lanceur (17/10/2026)

`resources/drawables/launcher_icon.svg` en 65×65 (taille attendue par la
fenix 9) : miniature du cadran (disque noir, date grise, heure 10:08 en
blanc, trois points aux couleurs des indicateurs). Chiffres dessinés en
tracés, sans texte SVG. Ancienne icône du modèle Garmin :
`design/launcher_icon-original.svg`. Plus d'avertissement à la compilation.

## Chantier 11 : écran du mode sommeil (17/10/2026)

- Un cadran Connect IQ ne peut pas être choisi comme cadran du mode Sommeil :
  la montre propose son cadran de sommeil ou « Ne pas changer ». Le SDK
  n'expose pas le mode concentration.
- Noir lit le créneau de sommeil du profil (`UserProfile.sleepTime` /
  `wakeTime`, réglé dans Garmin Connect) et affiche l'écran de veille pendant
  ce créneau, même poignet levé. Créneau passant minuit géré.
- Permission `UserProfile` ajoutée (affichée à l'installation).
- Réglage montre : Focus Modes > Sleep > Watch Face > « Ne pas changer ».
- Note publication : taille de l'icône du lanceur variable selon la montre
  (60–70 px) ; le SVG est redimensionné par le compilateur (avertissement).

## Chantier 12 : veille lisible (17/10/2026)

- Heure épaissie (faux gras : texte redessiné décalé d'1 px, 2 px au total)
  et éclaircie (`#C4C9D0`) ; texte secondaire `#8C939C`. Taille et
  composition inchangées. Constantes `SLEEP_TIME_COLOR`, `SLEEP_TEXT_COLOR`,
  `SLEEP_TIME_WEIGHT` en tête de `drawSleep`.
- Lune « Ne pas déranger » masquée en veille/sommeil (toujours présente la
  nuit, donc sans information) ; conservée sur l'écran actif.
- Pic de luminance mesuré au simulateur : 2,32 % (limite 10 %).

## Chantier 13 : séparation Noir / Noir Pro (17/10/2026)

Un seul code, deux builds :
| | Noir | Noir Pro |
|---|---|---|
| Build | `monkey.jungle` | `monkey-pro.jungle` |
| Manifest | `manifest.xml` (id `9aa262c0-…`) | `manifest-pro.xml` (id `1dcf482e-…`) |
| Nom | `@Strings.AppName` = « Noir » | `@Strings.AppNamePro` = « Noir Pro » |
| Ressources | `resources` | `resources` + `resources-pro` (réglages) |
| Code exclu | marqué `(:pro)` | marqué `(:free)` |

- Marqué `(:pro)` : `getSettingsView`, le menu (`NoirSettingsMenu`,
  `NoirSettingsDelegate`, `choiceLabel`), `loadSettings` qui lit les
  propriétés. `(:free)` : `loadSettings` vide (valeurs par défaut).
- Les deux manifests doivent garder la même liste de montres et de permissions.
- Compilation : `monkeyc -f monkey.jungle -o bin/Noir.prg …` et
  `monkeyc -f monkey-pro.jungle -o bin/NoirPro.prg …`. Les 15 montres
  compilent pour les deux versions.

## Feuille de route (décidée le 17/10/2026)

### Deux versions, un seul code
| | **Noir** (gratuite) | **Noir Pro** (payante) |
|---|---|---|
| Mise en page, veille AMOLED, icônes | ✓ | ✓ |
| 12/24 h, °C/°F | suit la montre | suit la montre ou forcé |
| Météo, % batterie, indicateurs d'état | toujours affichés | affichables ou masqués |
| Secondes | non | en option |
| 3 indicateurs | fixes (FC, Body Battery, pas) | au choix + mode Auto contextuel |
| Réglages (montre, Garmin Connect) | aucun | tous |
| Montres | identiques | identiques |

Deux apps sur le Store (identifiants distincts), réglages compilés seulement
pour la Pro (exclusion de code dans `monkey.jungle`). Prix Pro : à décider
(marché : 2–5 $, achat unique ; paiement Garmin Pay dans le Store).

### Montres
- Vague 1 : AMOLED rond 454/466 px (15 profils dans le manifest, API min. 4.2.0) :
  fenix 9 Pro 47/51, fenix 9, fenix 8 47/51, fenix 8 Pro, epix Pro 51,
  D2 Mach 2 / 2 Pro, MARQ 3, FR 965/970/570 47, Venu 3, Venu 4 45, Approach S72 47.
  Toutes compilent ; affichage à vérifier au simulateur.
- Vague 2 : 416/390 px (~25 montres) : icônes à redimensionner par résolution.
- Écrans MIP : non (design pensé pour l'AMOLED).

### Fonctions phares (étude du 17/10/2026)
- **Veille lisible** (Noir gratuite) : plainte n° 1 des utilisateurs AMOLED,
  l'heure illisible en veille (Garmin assombrit l'écran, « by design »). Un trait
  fin éclaire trop peu de pixels : chiffres pleins, grands, plus clairs, sous la
  limite de 10 % (on est à 2,36 %), avec le décalage anti-marquage.
- **Indicateurs contextuels « Auto »** (Noir Pro) : les 3 emplacements changent
  selon le moment (réveil : sommeil, Body Battery, récupération ; journée : pas,
  stress ; après activité : récupération ; soir : Body Battery). Esprit Smart
  Stack d'Apple ; aucun cadran Connect IQ équivalent trouvé.
- Écartés : thèmes de couleurs, jauges de progression, données en masse
  (déjà partout, contraire à l'identité de Noir).

### Ordre
1. ~~Écran du mode sommeil~~ (fait, chantier 11).
2. ~~Veille lisible~~ (fait, chantier 12).
3. ~~Séparation Noir / Noir Pro~~ (fait, chantier 13) ; retrait de la trace DBG, publication de Noir.
4. Indicateurs configurables, puis mode Auto ; publication de Noir Pro.

## Chantiers suivants
- **Indicateurs configurables** (gros chantier, après la publication) : choisir les trois
  indicateurs (aujourd'hui FC, Body Battery, pas) parmi stress, calories,
  étages, distance, minutes d'intensité… via les complications Garmin.
  Demande une liste de choix par emplacement, une icône et un format de valeur
  pour chaque donnée.
