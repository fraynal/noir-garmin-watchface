import Toybox.Graphics;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.ActivityMonitor;
import Toybox.Weather;
import Toybox.Complications;
import Toybox.Application;

class NoirWatchFaceView extends WatchUi.WatchFace {

    var mHeart;
    var mBolt;
    var mSteps;
    var mWeatherIcons;
    // Indicateurs d'état : normal et atténué (veille).
    var mPhoneOff;
    var mPhoneOffDim;
    var mDnd;
    var mDndDim;

    // Données natives du cadran, rafraîchies lors des notifications Garmin.
    var mHeartRateId;
    var mBodyBatteryId;
    var mHeartRateText = "--";
    var mBodyBatteryText = "--";

    // Vrai pendant la veille (écran toujours allumé, mode basse consommation).
    var mSleeping = false;

    // Réglages (resources/settings), relus par loadSettings().
    var mShowSeconds = false;
    var mTemperatureUnit = 0; // 0 = comme la montre, 1 = °C, 2 = °F
    var mShowWeather = true;
    var mShowBatteryPercent = true;
    var mTimeFormat = 0;      // 0 = comme la montre, 1 = 24 h, 2 = 12 h
    var mShowStatusIcons = true;

    function initialize() {
        WatchFace.initialize();
        loadSettings();
        // Charger une seule fois les ressources (pas dans onUpdate).
        mHeart = WatchUi.loadResource(Rez.Drawables.heart);
        mBolt = WatchUi.loadResource(Rez.Drawables.bolt);
        mSteps = WatchUi.loadResource(Rez.Drawables.steps);
        mPhoneOff = WatchUi.loadResource(Rez.Drawables.phone_off);
        mPhoneOffDim = WatchUi.loadResource(Rez.Drawables.phone_off_dim);
        mDnd = WatchUi.loadResource(Rez.Drawables.dnd);
        mDndDim = WatchUi.loadResource(Rez.Drawables.dnd_dim);
        mWeatherIcons = [
            WatchUi.loadResource(Rez.Drawables.weather_sun),          // 0
            WatchUi.loadResource(Rez.Drawables.weather_moon),         // 1
            WatchUi.loadResource(Rez.Drawables.weather_partly_day),   // 2
            WatchUi.loadResource(Rez.Drawables.weather_partly_night), // 3
            WatchUi.loadResource(Rez.Drawables.weather_cloud),        // 4
            WatchUi.loadResource(Rez.Drawables.weather_rain),         // 5
            WatchUi.loadResource(Rez.Drawables.weather_showers),      // 6
            WatchUi.loadResource(Rez.Drawables.weather_sun_rain),     // 7
            WatchUi.loadResource(Rez.Drawables.weather_moon_rain),    // 8
            WatchUi.loadResource(Rez.Drawables.weather_storm),        // 9
            WatchUi.loadResource(Rez.Drawables.weather_snow),         // 10
            WatchUi.loadResource(Rez.Drawables.weather_fog),          // 11
            WatchUi.loadResource(Rez.Drawables.weather_wind),         // 12
            WatchUi.loadResource(Rez.Drawables.weather_ice),          // 13
            WatchUi.loadResource(Rez.Drawables.weather_unknown)       // 14
        ];
    }

    function loadSettings() as Void {
        mShowSeconds = Properties.getValue("ShowSeconds");
        mTemperatureUnit = Properties.getValue("TemperatureUnit");
        mShowWeather = Properties.getValue("ShowWeather");
        mShowBatteryPercent = Properties.getValue("ShowBatteryPercent");
        mTimeFormat = Properties.getValue("TimeFormat");
        mShowStatusIcons = Properties.getValue("ShowStatusIcons");
    }

    // « Comme la montre » : relu à chaque dessin, la montre peut changer de réglage.
    function use12Hour() {
        return mTimeFormat == 0 ? !System.getDeviceSettings().is24Hour : mTimeFormat == 2;
    }

    function useFahrenheit() {
        return mTemperatureUnit == 0
            ? System.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE
            : mTemperatureUnit == 2;
    }

    // Enregistrer les complications quand le cadran devient visible.
    function onShow() as Void {
        WatchFace.onShow();

        mHeartRateId = new Complications.Id(
            Complications.COMPLICATION_TYPE_HEART_RATE
        );
        mBodyBatteryId = new Complications.Id(
            Complications.COMPLICATION_TYPE_BODY_BATTERY
        );

        Complications.registerComplicationChangeCallback(
            self.method(:onComplicationChanged)
        );

        // Une complication peut être indisponible dans le simulateur.
        try {
            Complications.subscribeToUpdates(mHeartRateId);
        } catch (e) {
            // Conserver "--" si indisponible.
        }
        try {
            Complications.subscribeToUpdates(mBodyBatteryId);
        } catch (e) {
            // Conserver "--" si indisponible.
        }

        mHeartRateText = readComplicationText(mHeartRateId);
        mBodyBatteryText = readComplicationText(mBodyBatteryId);
    }

    function onHide() as Void {
        Complications.unsubscribeFromAllUpdates();
        Complications.registerComplicationChangeCallback(null);
        WatchFace.onHide();
    }

    // Appelé lors d'un changement de fréquence cardiaque ou Body Battery.
    function onComplicationChanged(id as Complications.Id) as Void {
        if (id.equals(mHeartRateId)) {
            mHeartRateText = readComplicationText(mHeartRateId);
        } else if (id.equals(mBodyBatteryId)) {
            mBodyBatteryText = readComplicationText(mBodyBatteryId);
        }
        // En veille, les mesures de santé ne sont pas affichées : pas de redessin.
        if (!mSleeping) {
            WatchUi.requestUpdate();
        }
    }

    function onEnterSleep() as Void {
        mSleeping = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        mSleeping = false;
        WatchUi.requestUpdate();
    }

    // En cas d'absence de donnée, afficher "--" sans faire planter le cadran.
    function readComplicationText(id) {
        try {
            var complication = Complications.getComplication(id);
            if (complication != null && complication.value != null) {
                return complication.value.toString();
            }
        } catch (e) {
            // Exemple : valeur indisponible dans le simulateur.
        }
        return "--";
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = (w / 2).toNumber();
        // Échelle des tailles en pixels : 1.0 sur l'écran de référence 454 px (fenix 9 Pro 47 mm).
        var s = w / 454.0;
        var white = 0xF2F4F7;
        var gray = 0xB9C4D4;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var clock = System.getClockTime();

        if (mSleeping) {
            drawSleep(dc, w, h, s, clock);
            return;
        }

        // MÉTÉO (réglage ShowWeather) : icône + température, centrées au-dessus de la date.
        if (mShowWeather) {
            drawWeather(dc, cx, h, s, clock, gray);
        }

        // Mise en page en trois groupes : contexte (météo, date), heure au centre
        // optique (47 %), santé et batterie. Seule l'heure est en blanc.

        // DATE
        dc.setColor(gray, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.25).toNumber(), Graphics.FONT_TINY, dateText(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // HEURE (secondes seulement hors veille : redessin chaque seconde)
        var timeY = (h * 0.47).toNumber();
        drawTime(dc, cx, timeY, s, Graphics.FONT_NUMBER_HOT, white, clock, mShowSeconds);

        // PAS
        var stepsText = "--";
        var info = ActivityMonitor.getInfo();
        if (info != null && info.steps != null) {
            stepsText = formatSteps(info.steps);
        }

        // INDICATEURS
        var spacing = (w * 0.255).toNumber();
        var iconY = (h * 0.66).toNumber();
        var valueY = (h * 0.735).toNumber();
        drawCenteredIcon(dc, cx - spacing, iconY, mHeart);
        drawValue(dc, cx - spacing, valueY, mHeartRateText, gray);
        drawCenteredIcon(dc, cx, iconY, mBolt);
        drawValue(dc, cx, valueY, mBodyBatteryText, gray);
        drawCenteredIcon(dc, cx + spacing, iconY, mSteps);
        drawValue(dc, cx + spacing, valueY, stepsText, gray);

        // BATTERIE MONTRE
        var batteryY = (h * 0.87).toNumber();
        var batteryX = drawBattery(dc, cx, batteryY, System.getSystemStats().battery, s,
            gray, Graphics.FONT_SMALL);

        drawStatusIcons(dc, cx - (w * 0.38).toNumber(), timeY, batteryX, batteryY, s, mPhoneOff, mDnd);
    }

    // INDICATEURS D'ÉTAT (réglage ShowStatusIcons), affichés seulement si actifs :
    // téléphone déconnecté à 9 h, à hauteur de l'heure (rare, doit se voir) ;
    // « Ne pas déranger » à gauche de la batterie, qui reste centrée.
    function drawStatusIcons(dc, phoneX, phoneY, batteryX, batteryY, s, phoneOff, dnd) {
        if (!mShowStatusIcons) {
            return;
        }
        var settings = System.getDeviceSettings();
        if (!settings.phoneConnected) {
            drawCenteredIcon(dc, phoneX, phoneY, phoneOff);
        }
        if (settings.doNotDisturb) {
            drawCenteredIcon(dc, batteryX - (12 * s).toNumber() - dnd.getWidth() / 2, batteryY, dnd);
        }
    }

    // Jour/nuit selon le lever/coucher du soleil calculés par la montre
    // (complications, secondes depuis minuit en heure locale) ;
    // repli sur 7h-19h si indisponibles.
    function isNight(clock) {
        var sunrise = readComplicationValue(Complications.COMPLICATION_TYPE_SUNRISE);
        var sunset = readComplicationValue(Complications.COMPLICATION_TYPE_SUNSET);
        var now = clock.hour * 3600 + clock.min * 60 + clock.sec;
        // DEBUG temporaire : validation jour/nuit sur la montre.
        System.println("DBG now=" + now + " rise=" + sunrise + " set=" + sunset);
        if (sunrise == null || sunset == null) {
            return clock.hour < 7 || clock.hour >= 19;
        }
        return now < sunrise || now >= sunset;
    }

    function readComplicationValue(type) {
        try {
            var complication = Complications.getComplication(new Complications.Id(type));
            if (complication != null) {
                return complication.value;
            }
        } catch (e) {
            // Complication indisponible (simulateur, montre sans GPS récent…).
        }
        return null;
    }

    function drawWeather(dc, cx, h, s, clock, gray) {
        var weatherIcons = mWeatherIcons as Toybox.Lang.Array;
        var weatherIcon = weatherIcons[14];
        var weatherText = "--°";
        var conditions = Weather.getCurrentConditions();
        if (conditions != null) {
            if (conditions.condition != null) {
                weatherIcon = weatherIcons[weatherIconIndex(conditions.condition, isNight(clock))];
            }
            if (conditions.temperature != null) {
                // Garmin fournit la température en °C.
                var t = conditions.temperature;
                if (useFahrenheit()) {
                    t = t * 9 / 5.0 + 32;
                }
                weatherText = t.format("%.0f") + "°";
            }
        }
        var weatherY = (h * 0.13).toNumber();
        var weatherFont = Graphics.FONT_SMALL;
        var textW = dc.getTextWidthInPixels(weatherText, weatherFont);
        var iconW = weatherIcon.getWidth();
        var gap = (7 * s).toNumber();
        var groupW = iconW + gap + textW;
        var startX = (cx - groupW / 2).toNumber();
        // Calage visuel : le centre de l'icône est 1/6 de sa hauteur sous le centre du texte.
        dc.drawBitmap(startX, weatherY - weatherIcon.getHeight() / 3, weatherIcon);
        dc.setColor(gray, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + iconW + gap, weatherY, weatherFont, weatherText,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // HH:MM centré en (cx, y). À droite, sans décaler HH:MM : les secondes
    // alignées sur le bas des chiffres, AM/PM aligné sur leur haut.
    // Hauteur des chiffres estimée par ascent - descent de la police.
    function drawTime(dc, cx, y, s, font, color, clock, withSeconds) {
        var hour = clock.hour;
        var suffix = null;
        var is12Hour = use12Hour();
        if (is12Hour) {
            suffix = hour < 12 ? "AM" : "PM";
            hour = hour % 12 == 0 ? 12 : hour % 12;
        }
        var main = (is12Hour ? hour.format("%d") : hour.format("%02d")) + ":" + clock.min.format("%02d");
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, font, main, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Ligne de base des chiffres (texte centré sur la hauteur de police).
        var baseline = y - dc.getFontHeight(font) / 2 + Graphics.getFontAscent(font);
        var x = cx + dc.getTextWidthInPixels(main, font) / 2 + (6 * s).toNumber();
        if (withSeconds) {
            // Pas de police de chiffres plus petite que FONT_NUMBER_MILD : police de texte.
            // Chiffres de FONT_TINY ≈ moitié de ceux de FONT_NUMBER_MILD sur la fenix 9 (mesuré sur capture).
            var secFont = Graphics.FONT_TINY;
            dc.drawText(x, baseline - Graphics.getFontAscent(secFont), secFont,
                clock.sec.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT);
        }
        if (suffix != null) {
            var digitsTop = baseline - (Graphics.getFontAscent(font) - Graphics.getFontDescent(font));
            // Même estimation pour AM/PM : ses majuscules commencent à « descent » sous le haut du texte.
            var smallFont = Graphics.FONT_XTINY;
            dc.drawText(x, digitsTop - Graphics.getFontDescent(smallFont), smallFont, suffix,
                Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    // VEILLE : date, heure et batterie en gris, sans météo ni mesures de santé.
    // Le système ne redessine qu'une fois par minute. Tout l'affichage se décale
    // chaque minute sur une grille 5×5 (±2 pas de 2 px, soit ±4 px) pour limiter le marquage AMOLED.
    // L'heure est au centre du cadran ; date au-dessus et batterie en dessous,
    // placées par rapport à l'heure, en hauteurs de sa police (les chiffres
    // n'occupent qu'environ la moitié de cette hauteur sur la fenix 9).
    // Réglage visuel : SLEEP_DATE_OFFSET / SLEEP_BATTERY_OFFSET.
    const SLEEP_DATE_OFFSET = 1.0;
    const SLEEP_BATTERY_OFFSET = 1.15;

    function drawSleep(dc, w, h, s, clock) {
        var step = (2 * s).toNumber();
        var cx = w / 2 + (clock.min % 5 - 2) * step;
        var timeY = h / 2 + (clock.min / 5 % 5 - 2) * step;
        var timeFont = Graphics.FONT_NUMBER_MILD;
        var timeH = dc.getFontHeight(timeFont);
        dc.setColor(0x71787F, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (timeY - timeH * SLEEP_DATE_OFFSET).toNumber(), Graphics.FONT_XTINY, dateText(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        drawTime(dc, cx, timeY, s, timeFont, 0x9A9FA7, clock, false);
        var batteryY = (timeY + timeH * SLEEP_BATTERY_OFFSET).toNumber();
        var batteryX = drawBattery(dc, cx, batteryY,
            System.getSystemStats().battery, s, 0x71787F, Graphics.FONT_XTINY);
        drawStatusIcons(dc, cx - (w * 0.38).toNumber(), timeY, batteryX, batteryY, s, mPhoneOffDim, mDndDim);
    }

    // Garmin renvoie directement les abréviations dans
    // la langue configurée sur la montre (FORMAT_MEDIUM).
    function dateText() {
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        return today.day_of_week.toString().toUpper()
            + " " + today.day.toString()
            + " " + today.month.toString().toUpper();
    }

    function drawCenteredIcon(dc, x, y, bitmap) {
        dc.drawBitmap(x - bitmap.getWidth() / 2, y - bitmap.getHeight() / 2, bitmap);
    }

    function drawValue(dc, x, y, value, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, Graphics.FONT_SMALL, value,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Correspondance des codes Garmin Weather.CONDITION_* (0 à 53).
    // 0 soleil, 1 lune, 2 éclaircies jour, 3 éclaircies nuit,
    // 4 nuages, 5 pluie, 6 averses, 7 averses jour, 8 averses nuit,
    // 9 orages, 10 neige, 11 brouillard, 12 vent, 13 glace, 14 inconnu.
    function weatherIconIndex(condition, isNight) {
        if (condition == Weather.CONDITION_CLEAR || condition == Weather.CONDITION_FAIR
                || condition == Weather.CONDITION_MOSTLY_CLEAR) {
            return isNight ? 1 : 0;
        }
        if (condition == Weather.CONDITION_PARTLY_CLOUDY || condition == Weather.CONDITION_PARTLY_CLEAR
                || condition == Weather.CONDITION_THIN_CLOUDS) {
            return isNight ? 3 : 2;
        }
        if (condition == Weather.CONDITION_MOSTLY_CLOUDY || condition == Weather.CONDITION_CLOUDY) {
            return 4;
        }
        if (condition == Weather.CONDITION_THUNDERSTORMS
                || condition == Weather.CONDITION_SCATTERED_THUNDERSTORMS
                || condition == Weather.CONDITION_CHANCE_OF_THUNDERSTORMS
                || condition == Weather.CONDITION_TORNADO
                || condition == Weather.CONDITION_SQUALL
                || condition == Weather.CONDITION_HURRICANE
                || condition == Weather.CONDITION_TROPICAL_STORM) {
            return 9;
        }
        if (condition == Weather.CONDITION_SNOW || condition == Weather.CONDITION_LIGHT_SNOW
                || condition == Weather.CONDITION_HEAVY_SNOW
                || condition == Weather.CONDITION_CHANCE_OF_SNOW
                || condition == Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW
                || condition == Weather.CONDITION_FLURRIES) {
            return 10;
        }
        if (condition == Weather.CONDITION_WINTRY_MIX || condition == Weather.CONDITION_HAIL
                || condition == Weather.CONDITION_LIGHT_RAIN_SNOW
                || condition == Weather.CONDITION_HEAVY_RAIN_SNOW
                || condition == Weather.CONDITION_RAIN_SNOW
                || condition == Weather.CONDITION_CHANCE_OF_RAIN_SNOW
                || condition == Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW
                || condition == Weather.CONDITION_FREEZING_RAIN
                || condition == Weather.CONDITION_SLEET
                || condition == Weather.CONDITION_ICE_SNOW
                || condition == Weather.CONDITION_ICE) {
            return 13;
        }
        if (condition == Weather.CONDITION_FOG || condition == Weather.CONDITION_HAZY
                || condition == Weather.CONDITION_MIST || condition == Weather.CONDITION_DUST
                || condition == Weather.CONDITION_SMOKE || condition == Weather.CONDITION_SAND
                || condition == Weather.CONDITION_SANDSTORM
                || condition == Weather.CONDITION_VOLCANIC_ASH
                || condition == Weather.CONDITION_HAZE) {
            return 11;
        }
        if (condition == Weather.CONDITION_WINDY) {
            return 12;
        }
        if (condition == Weather.CONDITION_SCATTERED_SHOWERS
                || condition == Weather.CONDITION_LIGHT_SHOWERS
                || condition == Weather.CONDITION_CHANCE_OF_SHOWERS
                || condition == Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN) {
            return isNight ? 8 : 7;
        }
        if (condition == Weather.CONDITION_HEAVY_RAIN || condition == Weather.CONDITION_HEAVY_SHOWERS
                || condition == Weather.CONDITION_SHOWERS) {
            return 6;
        }
        if (condition == Weather.CONDITION_RAIN || condition == Weather.CONDITION_LIGHT_RAIN
                || condition == Weather.CONDITION_DRIZZLE
                || condition == Weather.CONDITION_UNKNOWN_PRECIPITATION) {
            return 5;
        }
        return 14;
    }

    // Icône batterie dessinée : corps + ergot, tailles à l'échelle s de l'écran.
    function drawBattery(dc, cx, y, percent, s, color, font) {
        var bodyW = (25 * s).toNumber();
        var iconH = (14 * s).toNumber();
        var pad = (3 * s).toNumber();
        var nubW = (2 * s).toNumber();
        var nubH = (4 * s).toNumber();
        var iconW = bodyW + pad / 3 + nubW;
        // Réglage ShowBatteryPercent : icône seule, centrée, si désactivé.
        var label = mShowBatteryPercent ? percent.format("%.0f") + "%" : "";
        var gap = mShowBatteryPercent ? (7 * s).toNumber() : 0;
        var textW = mShowBatteryPercent ? dc.getTextWidthInPixels(label, font) : 0;
        var totalW = iconW + gap + textW;
        var x = (cx - totalW / 2).toNumber();
        var top = (y - iconH / 2).toNumber();
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(x, top, bodyW, iconH, pad);
        dc.fillRectangle(x + bodyW + pad / 3, top + (iconH - nubH) / 2, nubW, nubH);
        var fillW = ((bodyW - 2 * pad) * percent / 100.0).toNumber();
        if (fillW > 0) {
            dc.fillRectangle(x + pad, top + pad, fillW, iconH - 2 * pad);
        }
        dc.drawText(x + iconW + gap, y, font, label,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        return x;
    }

    function formatSteps(steps) {
        if (steps >= 10000) {
            return (steps / 1000).toNumber().toString() + "K";
        }
        if (steps >= 1000) {
            var thousands = (steps / 1000).toNumber();
            var hundreds = ((steps % 1000) / 100).toNumber();
            return thousands.toString() + "." + hundreds.toString() + "K";
        }
        return steps.toString();
    }
}
