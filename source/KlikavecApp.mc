using Toybox.Application;
using Toybox.WatchUi;

// Preserve the upstream App/Settings/Service contracts. This entry point replaces
// only the UI orchestration and the old continuous polling/webhook registration.
(:glance)
class KlikavecApp extends HomeAssistantApp {
    var model;
    var view;
    function initialize() {HomeAssistantApp.initialize();}
    function getInitialView() {
        Settings.update();
        model=new KlikavecModel(); view=new KlikavecView(model);
        return [view,new KlikavecDelegate(view)];
    }
    function getIsApp() {return true;}
    function getGlanceView() {return [new KlikavecGlanceView()];}
    function onStop(state) {
        if(model!=null){model.stopped=true;}
        HomeAssistantApp.onStop(state);
    }
    function onSettingsChanged() {
        Settings.update();
        if(model!=null) {
            model.stopped=true;
            model=new KlikavecModel();view.model=model;
            resetNavigation();refreshVisible();
        }
    }
    function refreshVisible() {if(view!=null){model.refresh(view.items());}}
    function confirmAction(item) {view.confirmation=item;view.yes=false;WatchUi.requestUpdate();}
    function resetNavigation() {
        view.section=0;view.index=0;view.level=0;view.advanced=null;view.detail=null;
        WatchUi.requestUpdate();
    }
}

function getKlikavecApp() {return Application.getApp() as KlikavecApp;}
