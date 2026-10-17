import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class NoirWatchFaceApp extends Application.AppBase {

    var mView;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        mView = new NoirWatchFaceView();
        return [ mView ];
    }

    // Réglages modifiés depuis Garmin Connect sur le téléphone.
    function onSettingsChanged() as Void {
        if (mView != null) {
            mView.loadSettings();
        }
        WatchUi.requestUpdate();
    }

}

function getApp() as NoirWatchFaceApp {
    return Application.getApp() as NoirWatchFaceApp;
}