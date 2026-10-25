using Toybox.Test;
using Toybox.Time;

(:test)
class KlikavecFakeService {
    var calls=0;
    var url;
    var payload;
    function initialize() {}
    function callEntity(u,d,callback) {calls++;url=u;payload=d;}
}

(:test)
class KlikavecTestModel extends KlikavecModel {
    function initialize() {
        KlikavecModel.initialize();
        config=KlikavecConfig.bundled();sections=KlikavecConfig.sections(config);
        states={};received={};offline=false;service=new KlikavecFakeService();
    }
    function configured() {return true;}
    function save() {} // Tests never persist fake readings into the app cache.
}

(:test)
function configAcceptsBundled(logger) {
    return KlikavecConfig.valid(KlikavecConfig.bundled());
}
(:test)
function configRejectsWrongShape(logger) {
    return !KlikavecConfig.valid(null) && !KlikavecConfig.valid([]) &&
        !KlikavecConfig.valid({"version"=>1,"items"=>"bad"});
}
(:test)
function configRejectsInjection(logger) {
    return !KlikavecConfig.entityId("sensor.a'}} malicious") &&
        !KlikavecConfig.entityId("sensor.a.b") && KlikavecConfig.entityId("light.led_pasek");
}
(:test)
function configBlocksDangerousWrites(logger) {
    return !KlikavecConfig.validItem({"type"=>"toggle","name"=>"Water","entity"=>"switch.zasuvka_2"},2) &&
        !KlikavecConfig.writable("button.ds218play_restart") &&
        !KlikavecConfig.writable("climate.bt725") && KlikavecConfig.writable("light.led_pasek");
}
(:test)
function unavailableIsNotErrorOrOff(logger) {
    var m=new KlikavecTestModel();var item={"type"=>"toggle","entity"=>"light.led_pasek"};
    m.states[item["entity"]]=["unavailable","",0];m.received[item["entity"]]=Time.now().value();
    return "unknown".equals(m.quality(item)) && "Nedostupné".equals(m.display(item));
}
(:test)
function staleAndInvalidHiveHidden(logger) {
    var m=new KlikavecTestModel();var item={"entity"=>"input_number.test","maxAge"=>3600,"minValid"=>0,"maxValid"=>60};
    m.states[item["entity"]]=["26.7","°C",90000];m.received[item["entity"]]=Time.now().value();
    var stale="Stará data".equals(m.display(item));
    m.states[item["entity"]]=["-30","°C",0];
    return stale && "invalid".equals(m.quality(item)) && "Neplatné měření".equals(m.display(item));
}
(:test)
function stableConnectivityUsesFetchAge(logger) {
    var m=new KlikavecTestModel();var item={"entity"=>"binary_sensor.internet","status"=>"connectivity"};
    m.states[item["entity"]]=["on","",90000];m.received[item["entity"]]=Time.now().value();
    return !m.stale(item) && "ok".equals(m.quality(item));
}
(:test)
function cachedDataCannotWrite(logger) {
    var m=new KlikavecTestModel();var item={"entity"=>"light.led_pasek","type"=>"toggle"};
    m.states[item["entity"]]=["on","",0];m.received[item["entity"]]=Time.now().value()-600;
    m.toggle(item,true);
    return m.service.calls==0;
}
(:test)
function actionRequiresReadback(logger) {
    var m=new KlikavecTestModel();var item={"entity"=>"light.led_pasek","type"=>"toggle"};
    m.states[item["entity"]]=["on","",0];m.received[item["entity"]]=Time.now().value();
    m.toggle(item,true);
    if(m.service.calls!=1 || !"on".equals(m.states[item["entity"]][0])){return false;}
    m.onAction(200,[]);
    if(m.service.calls!=2 || !"on".equals(m.states[item["entity"]][0]) || m.pending==null){return false;}
    m.onStates(200,[["light.led_pasek","off","",0]]);
    return "off".equals(m.states[item["entity"]][0]) && "Stav potvrzen".equals(m.message) && m.pending==null;
}
(:test)
function malformedJsonPreservesCache(logger) {
    var m=new KlikavecTestModel();m.states["sensor.test"]=["21","°C",0];
    m.requested=["sensor.test"];
    m.onStates(200,{"bad"=>true});
    return m.offline && "21".equals(m.states["sensor.test"][0]) && !m.busy;
}
(:test)
function responseOrderAndShapeChecked(logger) {
    var m=new KlikavecTestModel();m.requested=["sensor.test"];
    return !m.validResponse([["sensor.other","21","°C",0]]) &&
        !m.validResponse([["sensor.test","21","°C","not age"]]) &&
        !m.validResponse([]) && m.validResponse([["sensor.test","21","°C",0]]);
}
(:test)
function callbacksAfterStopIgnored(logger) {
    var m=new KlikavecTestModel();m.stopped=true;m.requested=["sensor.test"];
    m.onStates(200,[["sensor.test","21","°C",0]]);
    return !m.states.hasKey("sensor.test") && m.service.calls==0;
}

(:test)
function errorCannotBecomeSuccess(logger) {
    var m=new KlikavecTestModel();var item={"entity"=>"light.led_pasek","type"=>"toggle"};
    m.states[item["entity"]]=["on","",0];m.received[item["entity"]]=Time.now().value();
    m.toggle(item,true);m.onAction(401,null);
    m.onStates(200,[["light.led_pasek","off","",0]]);
    return "Akce neověřena".equals(m.message) && "off".equals(m.states[item["entity"]][0]);
}
(:test)
function doubleTapDoesNotDuplicateWrite(logger) {
    var m=new KlikavecTestModel();var item={"entity"=>"light.led_pasek","type"=>"toggle"};
    m.states[item["entity"]]=["on","",0];m.received[item["entity"]]=Time.now().value();
    m.toggle(item,true);m.toggle(item,true);
    return m.service.calls==1;
}
(:test)
function malformedConfigExtensionsRejected(logger) {
    return !KlikavecConfig.validItem({"type"=>"info","name"=>"test","entity"=>"sensor.test","status"=>{}},2) &&
        !KlikavecConfig.validItem({"type"=>"toggle","name"=>"pool","entity"=>"switch.zasuvka_1","favorite"=>true},2) &&
        !KlikavecConfig.validItem({"type"=>"info","name"=>"test","entity"=>"sensor.test","token"=>"never-allowed"},2);
}
(:test)
function homeFavoritesAreConfigurable(logger) {
    var m=new KlikavecTestModel();var home=m.sections[0];
    var before=m.sectionItems(home).size();home["items"][5]["favorite"]=false;
    return before==8 && m.sectionItems(home).size()==7;
}
(:test)
function buttonsReachSectionsAndBack(logger) {
    var m=new KlikavecTestModel();m.stopped=true;
    var v=new KlikavecView(m);var d=new KlikavecDelegate(v);
    d.onNextPage();d.onSelect();d.onNextPage();
    if(v.section!=1 || v.level!=1 || v.index!=1){return false;}
    d.onBack();d.onPreviousPage();
    return v.section==0 && v.level==0;
}
(:test)
function remoteConfigPrimitivesDoNotCrash(logger) {
    var m=new KlikavecTestModel();var original=m.config;
    m.onConfig(200,[]);m.onConfig(200,"bad");m.onConfig(200,12);m.onConfig(200,null);
    return m.config==original && !m.busy && "Neplatná konfigurace".equals(m.message);
}
(:test)
function offlineResponsePreservesReading(logger) {
    var m=new KlikavecTestModel();m.states["sensor.test"]=["21","°C",0];m.requested=["sensor.test"];
    m.onStates(-1,null);
    return m.offline && !m.busy && "21".equals(m.states["sensor.test"][0]);
}
