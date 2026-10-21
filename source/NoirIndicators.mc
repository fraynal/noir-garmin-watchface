import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Les trois indicateurs du bas (gauche, centre, droite). Choisis dans l'éditeur
// de cadran de la montre (resources/watchface/watchface_config.xml, emplacements
// 1, 2, 3). Montres sans éditeur (avant la fenix 8) : FC, Body Battery, pas.
class NoirIndicators {

    var mIds as Array<Complications.Id>;
    var mTexts as Array<String> = ["--", "--", "--"];
    var mIcons as Dictionary<Complications.Type, WatchUi.BitmapResource> = {};

    function initialize() {
        mIds = [
            new Complications.Id(Complications.COMPLICATION_TYPE_HEART_RATE),
            new Complications.Id(Complications.COMPLICATION_TYPE_BODY_BATTERY),
            new Complications.Id(Complications.COMPLICATION_TYPE_STEPS)
        ];
        load(null);
    }

    // configId null : configuration active ; sinon celle en cours d'édition.
    function load(configId) as Void {
        if (!(Application has :WatchFaceConfig)) {
            return;
        }
        var settings = WatchFaceConfig.getSettings(configId);
        if (settings == null || settings.complicationSettings == null) {
            return;
        }
        var refs = settings.complicationSettings as Array<WatchFaceConfig.ComplicationRef>;
        for (var i = 0; i < refs.size(); i++) {
            var slot = refs[i].uniqueIdentifier;
            if (slot != null && slot >= 1 && slot <= 3 && refs[i].complicationId != null) {
                mIds[slot - 1] = refs[i].complicationId as Complications.Id;
            }
        }
        refresh();
    }

    // À l'affichage du cadran : abonnement aux trois complications choisies.
    function subscribe() as Void {
        for (var i = 0; i < 3; i++) {
            try {
                Complications.subscribeToUpdates(mIds[i]);
            } catch (e) {
                // Indisponible sur cette montre ou dans le simulateur : "--".
            }
        }
        refresh();
    }

    function refresh() as Void {
        for (var i = 0; i < 3; i++) {
            mTexts[i] = read(i);
        }
    }

    // Notification d'une complication : vrai si elle concerne un indicateur.
    function onChanged(id as Complications.Id) as Boolean {
        var changed = false;
        for (var i = 0; i < 3; i++) {
            if (id.equals(mIds[i])) {
                mTexts[i] = read(i);
                changed = true;
            }
        }
        return changed;
    }

    function text(i as Number) as String {
        var type = mIds[i].getType();
        // Lues en direct : la notification de ces complications est trop espacée.
        if (type == Complications.COMPLICATION_TYPE_HEART_RATE) {
            var hr = liveHeartRate();
            return hr != null ? hr.toString() : mTexts[i];
        }
        if (type == Complications.COMPLICATION_TYPE_STEPS) {
            var info = ActivityMonitor.getInfo();
            return info != null && info.steps != null ? formatThousands(info.steps) : mTexts[i];
        }
        return mTexts[i];
    }

    function icon(i as Number) as WatchUi.BitmapResource or Null {
        var type = mIds[i].getType();
        if (!mIcons.hasKey(type)) {
            var rez = iconResource(type);
            if (rez == null) {
                return null;
            }
            mIcons.put(type, WatchUi.loadResource(rez) as WatchUi.BitmapResource);
        }
        return mIcons[type];
    }

    // Icônes des 13 données de watchface_config.xml (les autres : pas d'icône).
    function iconResource(type as Complications.Type) as ResourceId or Null {
        if (type == Complications.COMPLICATION_TYPE_HEART_RATE) { return Rez.Drawables.heart; }
        if (type == Complications.COMPLICATION_TYPE_BODY_BATTERY) { return Rez.Drawables.bolt; }
        if (type == Complications.COMPLICATION_TYPE_STEPS) { return Rez.Drawables.steps; }
        return null;
    }

    // Fréquence instantanée (poignet, ou ceinture connectée pendant une activité),
    // sinon dernier relevé de l'historique.
    function liveHeartRate() as Number or Null {
        var info = Activity.getActivityInfo();
        if (info != null && info.currentHeartRate != null) {
            return info.currentHeartRate;
        }
        var history = ActivityMonitor.getHeartRateHistory(1, true);
        if (history != null) {
            var sample = history.next();
            if (sample != null && sample.heartRate != null
                    && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                return sample.heartRate;
            }
        }
        return null;
    }

    // En cas d'absence de donnée, "--" sans faire planter le cadran.
    function read(i as Number) as String {
        try {
            var complication = Complications.getComplication(mIds[i]);
            if (complication != null && complication.value != null) {
                return format(mIds[i].getType(), complication.value);
            }
        } catch (e) {
            // Exemple : valeur indisponible dans le simulateur.
        }
        return "--";
    }

    function format(type, value) as String {
        var n = value.toNumber();
        if (type == Complications.COMPLICATION_TYPE_STEPS || type == Complications.COMPLICATION_TYPE_CALORIES) {
            return formatThousands(n);
        }
        if (type == Complications.COMPLICATION_TYPE_PULSE_OX || type == Complications.COMPLICATION_TYPE_SOLAR_INPUT) {
            return n + "%";
        }
        if (type == Complications.COMPLICATION_TYPE_RECOVERY_TIME) {
            // Minutes restantes, affichées en heures arrondies au-dessus.
            return ((n + 59) / 60) + "h";
        }
        if (type == Complications.COMPLICATION_TYPE_ALTITUDE) {
            if (System.getDeviceSettings().elevationUnits == System.UNIT_STATUTE) {
                return (value * 3.28084).toNumber() + "ft";
            }
            return n + "m";
        }
        return n.toString();
    }

    // 8420 → 8.4K, 12000 → 12K.
    function formatThousands(n as Number) as String {
        if (n >= 10000) {
            return (n / 1000) + "K";
        }
        if (n >= 1000) {
            return (n / 1000) + "." + ((n % 1000) / 100) + "K";
        }
        return n.toString();
    }
}
