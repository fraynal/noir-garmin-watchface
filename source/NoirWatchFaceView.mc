import Toybox.Graphics;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.ActivityMonitor;
import Toybox.Weather;
import Toybox.Complications;

class NoirWatchFaceView extends WatchUi.WatchFace {

    var mHeart;
    var mBolt;
    var mSteps;
    var mWeatherIcons;

    // Données natives du cadran, rafraîchies lors des notifications Garmin.
    var mHeartRateId;
    var mBodyBatteryId;
    var mHeartRateText = "--";
    var mBodyBatteryText = "--";

    function initialize() {
        WatchFace.initialize();
        // Charger une seule fois les ressources (pas dans onUpdate).
        mHeart = WatchUi.loadResource(Rez.Drawables.heart);
        mBolt = WatchUi.loadResource(Rez.Drawables.bolt);
        mSteps = WatchUi.loadResource(Rez.Drawables.steps);
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
        if (id == mHeartRateId) {
            mHeartRateText = readComplicationText(mHeartRateId);
        } else if (id == mBodyBatteryId) {
            mBodyBatteryText = readComplicationText(mBodyBatteryId);
        }
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
        var white = 0xF2F4F7;
        var gray = 0xB9C4D4;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var clock = System.getClockTime();

        // MÉTÉO : icône + température, centrées au-dessus de la date.
        // Le choix jour/nuit utilise ici l'heure locale (7h-19h),
        // pas les heures réelles de lever/coucher du soleil.
        var isNight = (clock.hour < 7 || clock.hour >= 19);
        var weatherIcons = mWeatherIcons as Toybox.Lang.Array;
        var weatherIcon = weatherIcons[14];
        var weatherText = "--°";
        var conditions = Weather.getCurrentConditions();
        if (conditions != null) {
            if (conditions.condition != null) {
                weatherIcon = weatherIcons[weatherIconIndex(conditions.condition, isNight)];
            }
            if (conditions.temperature != null) {
                weatherText = conditions.temperature.format("%.0f") + "°";
            }
        }
        var weatherY = (h * 0.105).toNumber();
        var weatherFont = Graphics.FONT_SMALL;
        var textW = dc.getTextWidthInPixels(weatherText, weatherFont);
        var iconW = 29;
        var gap = 7;
        var groupW = iconW + gap + textW;
        var startX = (cx - groupW / 2).toNumber();
        dc.drawBitmap(startX, weatherY - 10, weatherIcon);
        dc.setColor(gray, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + iconW + gap, weatherY, weatherFont, weatherText,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // DATE : Garmin renvoie directement les abréviations dans
        // la langue configurée sur la montre (FORMAT_MEDIUM).
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dateText = today.day_of_week.toString().toUpper()
            + " " + today.day.toString()
            + " " + today.month.toString().toUpper();
        dc.setColor(gray, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.23).toNumber(), Graphics.FONT_SMALL, dateText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // HEURE
        var hh = clock.hour.format("%02d");
        var mm = clock.min.format("%02d");
        dc.setColor(white, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.435).toNumber(), Graphics.FONT_NUMBER_HOT, hh + ":" + mm,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // PAS
        var stepsText = "--";
        var info = ActivityMonitor.getInfo();
        if (info != null && info.steps != null) {
            stepsText = formatSteps(info.steps);
        }

        // INDICATEURS
        var spacing = (w * 0.255).toNumber();
        var iconY = (h * 0.61).toNumber();
        var valueY = (h * 0.70).toNumber();
        drawCenteredIcon(dc, cx - spacing, iconY, mHeart, 30);
        drawValue(dc, cx - spacing, valueY, mHeartRateText, white);
        drawCenteredIcon(dc, cx, iconY, mBolt, 30);
        drawValue(dc, cx, valueY, mBodyBatteryText, white);
        drawCenteredIcon(dc, cx + spacing, iconY, mSteps, 30);
        drawValue(dc, cx + spacing, valueY, stepsText, white);

        // BATTERIE MONTRE
        drawBattery(dc, cx, (h * 0.85).toNumber(), System.getSystemStats().battery);
    }

    function drawCenteredIcon(dc, x, y, bitmap, size) {
        dc.drawBitmap((x - size / 2).toNumber(), (y - size / 2).toNumber(), bitmap);
    }

    function drawValue(dc, x, y, value, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, Graphics.FONT_MEDIUM, value,
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

    function drawBattery(dc, cx, y, percent) {
        var color = 0xB9C4D4;
        var iconW = 28;
        var iconH = 14;
        var gap = 7;
        var label = percent.format("%.0f") + "%";
        var textW = dc.getTextWidthInPixels(label, Graphics.FONT_SMALL);
        var totalW = iconW + gap + textW;
        var x = (cx - totalW / 2).toNumber();
        var top = (y - iconH / 2).toNumber();
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(x, top, 25, iconH, 3);
        dc.fillRectangle(x + 26, top + 5, 2, 4);
        var fillW = (19 * percent / 100.0).toNumber();
        if (fillW > 0) {
            dc.fillRectangle(x + 3, top + 3, fillW, 8);
        }
        dc.drawText(x + iconW + gap, y, Graphics.FONT_SMALL, label,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
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
