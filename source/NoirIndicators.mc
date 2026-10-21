import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.UserProfile;
import Toybox.WatchUi;

// Les trois indicateurs du bas (gauche, centre, droite). Choisis dans l'éditeur
// de cadran de la montre (resources/watchface/watchface_config.xml, emplacements
// 1, 2, 3). Montres sans éditeur (avant la fenix 8) : FC, Body Battery, pas.
class NoirIndicators {

    // Données affichées (mode Auto ou choix de l'éditeur) et choix de l'éditeur.
    var mIds as Array<Complications.Id>;
    var mConfigIds as Array<Complications.Id>;
    // Mode Auto (réglage AutoIndicators), durée des moments en secondes, et
    // minute du dernier calcul du moment (recalcul une fois par minute).
    var mAuto = false;
    var mWindow = 3600;
    var mLastMinute = -1;
    var mTexts as Array<String> = ["--", "--", "--"];
    var mIcons as Dictionary<Complications.Type, WatchUi.BitmapResource> = {};

    function initialize() {
        mConfigIds = ids([
            Complications.COMPLICATION_TYPE_HEART_RATE,
            Complications.COMPLICATION_TYPE_BODY_BATTERY,
            Complications.COMPLICATION_TYPE_STEPS
        ]);
        mIds = mConfigIds;
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
                mConfigIds[slot - 1] = refs[i].complicationId as Complications.Id;
            }
        }
        if (!mAuto) {
            mIds = mConfigIds;
            refresh();
        }
    }

    // Réglages AutoIndicators et AutoWindow (0 = 30 min, 1 = 1 h, 2 = 1 h 30).
    function setAuto(enabled as Boolean, window as Number) as Void {
        mAuto = enabled;
        mWindow = [1800, 3600, 5400][window];
        mLastMinute = -1;
        if (!mAuto) {
            show(mConfigIds);
        }
    }

    // Mode Auto : à chaque minute, données du moment de la journée.
    function update(clock as System.ClockTime) as Void {
        var minute = clock.hour * 60 + clock.min;
        if (!mAuto || minute == mLastMinute) {
            return;
        }
        mLastMinute = minute;
        show(ids(autoTypes(clock)));
    }

    // Gauche = état instantané du corps, centre = énergie, droite = bilan du moment.
    function autoTypes(clock as System.ClockTime) as Array<Complications.Type> {
        var hr = Complications.COMPLICATION_TYPE_HEART_RATE;
        var bb = Complications.COMPLICATION_TYPE_BODY_BATTERY;
        var intensity = Complications.COMPLICATION_TYPE_INTENSITY_MINUTES;
        if (afterActivity()) {
            return [hr, bb, intensity];
        }
        var profile = UserProfile.getProfile();
        var now = clock.hour * 3600 + clock.min * 60 + clock.sec;
        if (profile != null && profile.wakeTime != null
                && within(now, profile.wakeTime.value(), mWindow)) {
            // Score de sommeil absent des montres en API 5.2 : minutes d'intensité.
            var sleep = Complications.COMPLICATION_TYPE_SLEEP_SCORE;
            return [hr, bb, hasValue(sleep) ? sleep : intensity];
        }
        if (profile != null && profile.sleepTime != null
                && within(now, profile.sleepTime.value() - mWindow, mWindow)) {
            return [Complications.COMPLICATION_TYPE_STRESS, bb, Complications.COMPLICATION_TYPE_STEPS];
        }
        return [hr, bb, Complications.COMPLICATION_TYPE_STEPS];
    }

    // now dans [start, start + length[, en secondes depuis minuit (passe minuit).
    function within(now as Number, start as Number, length as Number) as Boolean {
        return ((now - start) % 86400 + 86400) % 86400 < length;
    }

    // Une activité de l'historique s'est terminée il y a moins de mWindow.
    function afterActivity() as Boolean {
        var history = UserProfile.getUserActivityHistory();
        var now = Time.now().value();
        var activity = history.next();
        while (activity != null) {
            if (activity.startTime != null && activity.duration != null) {
                var ago = now - activity.startTime.value() - activity.duration.value();
                if (ago >= 0 && ago < mWindow) {
                    return true;
                }
            }
            activity = history.next();
        }
        return false;
    }

    function hasValue(type as Complications.Type) as Boolean {
        try {
            var complication = Complications.getComplication(new Complications.Id(type));
            return complication != null && complication.value != null;
        } catch (e) {
            return false;
        }
    }

    function ids(types as Array<Complications.Type>) as Array<Complications.Id> {
        return [
            new Complications.Id(types[0]),
            new Complications.Id(types[1]),
            new Complications.Id(types[2])
        ];
    }

    // Affiche ces données ; réabonnement seulement si elles changent.
    function show(newIds as Array<Complications.Id>) as Void {
        var same = true;
        for (var i = 0; i < 3; i++) {
            if (!newIds[i].equals(mIds[i])) {
                same = false;
            }
        }
        if (same) {
            return;
        }
        mIds = newIds;
        Complications.unsubscribeFromAllUpdates();
        subscribe();
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
        if (type == Complications.COMPLICATION_TYPE_STRESS) { return Rez.Drawables.stress; }
        if (type == Complications.COMPLICATION_TYPE_CALORIES) { return Rez.Drawables.calories; }
        if (type == Complications.COMPLICATION_TYPE_FLOORS_CLIMBED) { return Rez.Drawables.floors; }
        if (type == Complications.COMPLICATION_TYPE_INTENSITY_MINUTES) { return Rez.Drawables.intensity; }
        if (type == Complications.COMPLICATION_TYPE_RESPIRATION_RATE) { return Rez.Drawables.respiration; }
        if (type == Complications.COMPLICATION_TYPE_PULSE_OX) { return Rez.Drawables.pulse_ox; }
        if (type == Complications.COMPLICATION_TYPE_RECOVERY_TIME) { return Rez.Drawables.recovery; }
        if (type == Complications.COMPLICATION_TYPE_SLEEP_SCORE) { return Rez.Drawables.sleep_score; }
        if (type == Complications.COMPLICATION_TYPE_ALTITUDE) { return Rez.Drawables.altitude; }
        if (type == Complications.COMPLICATION_TYPE_SOLAR_INPUT) { return Rez.Drawables.solar; }
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
