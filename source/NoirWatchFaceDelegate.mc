import Toybox.Lang;
import Toybox.WatchUi;

// Dialogue avec l'éditeur de cadran natif (fenix 8 et plus récentes).
class NoirWatchFaceDelegate extends WatchUi.WatchFaceDelegate {

    var mView as NoirWatchFaceView;

    function initialize(view as NoirWatchFaceView) {
        WatchFaceDelegate.initialize();
        mView = view;
    }

    // En édition : un appui sur un indicateur le sélectionne.
    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var xy = clickEvent.getCoordinates();
        var slot = mView.indicatorAt(xy[0], xy[1]);
        if (slot == null) {
            return false;
        }
        setSelectedComplication(slot);
        return true;
    }

    // En édition : un indicateur a changé, on relit la configuration éditée.
    function onWatchFaceConfigEdited(options) as Void {
        mView.mIndicators.load(options[:configId]);
        WatchUi.requestUpdate();
    }
}
