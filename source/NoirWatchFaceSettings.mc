import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Réglages sur la montre, en plus de Garmin Connect : mêmes propriétés
// et mêmes libellés que resources/settings.
class NoirSettingsMenu extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({:title => Rez.Strings.AppName});
        addToggle("ShowSeconds", Rez.Strings.ShowSecondsTitle);
        addItem(new WatchUi.MenuItem(Rez.Strings.TimeFormatTitle, choiceLabel("TimeFormat"), "TimeFormat", null));
        addToggle("ShowWeather", Rez.Strings.ShowWeatherTitle);
        addItem(new WatchUi.MenuItem(Rez.Strings.TemperatureUnitTitle, choiceLabel("TemperatureUnit"), "TemperatureUnit", null));
        addToggle("ShowBatteryPercent", Rez.Strings.ShowBatteryPercentTitle);
        addToggle("ShowStatusIcons", Rez.Strings.ShowStatusIconsTitle);
        addToggle("AutoIndicators", Rez.Strings.AutoIndicatorsTitle);
        addItem(new WatchUi.MenuItem(Rez.Strings.AutoWindowTitle, choiceLabel("AutoWindow"), "AutoWindow", null));
    }

    function addToggle(key as String, label as ResourceId) as Void {
        addItem(new WatchUi.ToggleMenuItem(label, null, key, Properties.getValue(key) as Boolean, null));
    }
}

class NoirSettingsDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    // Interrupteur : enregistre son nouvel état. Réglage à 3 choix : passe au suivant.
    function onSelect(item as WatchUi.MenuItem) as Void {
        var key = item.getId() as String;
        if (item instanceof WatchUi.ToggleMenuItem) {
            Properties.setValue(key, item.isEnabled());
        } else {
            Properties.setValue(key, ((Properties.getValue(key) as Number) + 1) % 3);
            item.setSubLabel(choiceLabel(key));
        }
        getApp().onSettingsChanged();
    }
}

// Libellé du choix courant d'un réglage à 3 valeurs.
function choiceLabel(key as String) as ResourceId {
    var labels = [Rez.Strings.FollowWatch, Rez.Strings.Celsius, Rez.Strings.Fahrenheit];
    if (key.equals("TimeFormat")) {
        labels = [Rez.Strings.FollowWatch, Rez.Strings.TimeFormat24, Rez.Strings.TimeFormat12];
    } else if (key.equals("AutoWindow")) {
        labels = [Rez.Strings.Window30, Rez.Strings.Window60, Rez.Strings.Window90];
    }
    return labels[Properties.getValue(key) as Number];
}
