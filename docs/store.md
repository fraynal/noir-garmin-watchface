# Fiche Connect IQ Store : Noir

Textes à copier dans le developer dashboard. Vérifier sur le portail les limites
de longueur et les champs exacts : ils ne sont pas documentés dans le SDK.

- **Nom** : Noir (vérifier la disponibilité sur le Store)
- **Type** : Watch face
- **Prix** : gratuit
- **Langues de la fiche** : anglais (par défaut), français
- **Code source** : https://github.com/fraynal/noir-garmin-watchface (GPL-3.0), à ajouter en fin de description une fois publié

---

## English

### Description

**Noir: a minimalist AMOLED watch face you can actually read.**

A large, centered time with only what matters around it: weather, date, heart rate, Body Battery, steps and watch battery. Everything else stays black.

**Readable always-on.** When your watch dims the screen, Noir switches to a thicker, brighter time with the date and battery, while staying well below Garmin's 10% luminance limit and shifting a few pixels every minute to protect your AMOLED screen.

**Night screen.** During your sleep hours (set in Garmin Connect), Noir keeps its dim screen even when you raise your wrist. On your watch, set *Focus Modes > Sleep > Watch Face > Don't change* so Noir stays active at night.

**Small details:**
- Weather icon switches to night after the real sunset
- 12/24 h and °C/°F follow your watch settings by default
- Date in your watch's language
- Status icons only when needed: phone disconnected, Do Not Disturb

**Settings** (Garmin Connect app, or on the watch: hold MENU > Watch Face > Noir > Customize):
- Show seconds
- Time format: same as watch, 24 h, or 12 h (AM/PM)
- Show weather
- Temperature unit: same as watch, Celsius, or Fahrenheit
- Battery percentage
- Status icons

Settings are available in English and French.

**Permissions:**
- *Complications*: to read heart rate, Body Battery, sunrise and sunset.
- *User profile*: only to read your sleep hours for the night screen.

Noir collects no data and sends nothing.

### What's new (1.0.0)

First release.

---

## Français

### Description

**Noir : un cadran AMOLED minimaliste que l'on arrive vraiment à lire.**

Une grande heure centrée, et autour seulement l'essentiel : météo, date, fréquence cardiaque, Body Battery, pas et batterie de la montre. Tout le reste reste noir.

**Une veille lisible.** Quand la montre assombrit l'écran, Noir affiche une heure plus épaisse et plus claire, avec la date et la batterie, tout en restant bien sous la limite de luminance de 10 % fixée par Garmin et en se décalant de quelques pixels chaque minute pour protéger l'écran AMOLED.

**Un écran de nuit.** Pendant vos heures de sommeil (réglées dans Garmin Connect), Noir garde son écran atténué même quand vous levez le poignet. Sur la montre, réglez *Modes concentration > Sommeil > Cadran > Ne pas changer* pour que Noir reste actif la nuit.

**Petits détails :**
- L'icône météo passe en mode nuit après le vrai coucher du soleil
- Format 12/24 h et °C/°F selon les réglages de la montre, par défaut
- Date dans la langue de la montre
- Indicateurs seulement quand c'est utile : téléphone déconnecté, Ne pas déranger

**Réglages** (app Garmin Connect, ou sur la montre : maintenir MENU > Cadran > Noir > Personnaliser) :
- Afficher les secondes
- Format de l'heure : comme la montre, 24 h ou 12 h (AM/PM)
- Afficher la météo
- Unité de température : comme la montre, Celsius ou Fahrenheit
- Pourcentage de batterie
- Indicateurs d'état

Réglages disponibles en anglais et en français.

**Permissions :**
- *Complications* : pour lire la fréquence cardiaque, la Body Battery, le lever et le coucher du soleil.
- *Profil utilisateur* : uniquement pour lire vos heures de sommeil pour l'écran de nuit.

Noir ne collecte aucune donnée et n'envoie rien.

### Nouveautés (1.0.0)

Première version.

---

## Captures d'écran à faire (simulateur, fenix 9 Pro 47 mm)

1. **Écran actif, jour** : ciel dégagé (soleil), vers 14:00, valeurs de santé renseignées.
2. **Écran actif, nuit** : ciel dégagé (lune), vers 21:00.
3. **Veille** : *Display Mode > Always-On*, même heure que 2.
4. **Indicateurs d'état** : téléphone déconnecté et Ne pas déranger actifs.
5. **Réglages** : menu sur la montre (*Trigger App Settings* au simulateur).
6. Optionnel : une autre montre (Venu 3 ou Forerunner 965), pour montrer la compatibilité.

Format : captures de l'écran seul, fond noir, sans le boîtier du simulateur si
possible (à confirmer selon ce qu'accepte le portail).

## Avant l'envoi

- [x] Retirer la trace `DBG`
- [ ] Vérifier le nom « Noir » sur le Store
- [ ] Captures d'écran
- [x] Paquet `.iq` : `monkeyc -e -r -f monkey.jungle -o store/Noir.iq -y <clé>`
- [ ] Sauvegarder la clé développeur (hors du dépôt, jamais sur GitHub) :
      toutes les mises à jour devront être signées avec la même clé
