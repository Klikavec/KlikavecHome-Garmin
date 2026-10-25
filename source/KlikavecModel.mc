using Toybox.Communications;
using Toybox.Lang;
using Toybox.Time;
using Toybox.System;
using Toybox.WatchUi;
using Toybox.Application.Storage;

class KlikavecModel {
    var config;
    var sections;
    var states={};
    var received={};
    var busy=false;
    var message="Připraveno";
    var offline=true;
    var requested=[];
    var requestTime=0;
    var pending=null;
    var desired=null;
    var actionAccepted=false;
    var refreshAfter=false;
    var stopped=false;
    var service;

    function favoriteItems(items,result) {
        for(var i=0;i<items.size();i++) {
            var item=items[i];
            if("group".equals(item["type"])) {favoriteItems(item["items"],result);}
            else if("toggle".equals(item["type"]) && item["favorite"]==true) {
                var found=false;
                for(var j=0;j<result.size();j++) {if(result[j]["entity"].equals(item["entity"])) {found=true;}}
                if(!found) {result.add(item);}
            }
        }
    }
    function sectionItems(section) {
        if(section["home"]!=true) {return section["items"];}
        var result=[];var favorites=[];
        for(var i=0;i<section["items"].size();i++) {
            var item=section["items"][i];
            if("info".equals(item["type"])) {result.add(item);}
        }
        for(var j=0;j<sections.size();j++) {favoriteItems(sections[j]["items"],favorites);}
        result.addAll(favorites);
        for(var k=0;k<section["items"].size();k++) {
            var link=section["items"][k];
            if("link".equals(link["type"])) {
                for(var s=0;s<sections.size();s++){if(sections[s]["name"].equals(link["target"])){result.add(link);break;}}
            }
        }
        return result;
    }

    function initialize() {
        config=KlikavecConfig.bundled();
        // Split config storage into <=8 KB values; never store a whole HA response.
        var count=Storage.getValue("kh_config_count");
        if (count instanceof Lang.Number && count>0 && count<=6) {
            var cached={"version"=>1,"items"=>[]};
            var theme=Storage.getValue("kh_theme");
            if(theme instanceof Lang.Dictionary){cached["theme"]=theme;}
            for(var i=0;i<count;i++) { cached["items"].add(Storage.getValue("kh_config_"+i)); }
            if (KlikavecConfig.valid(cached)) { config=cached; }
        }
        sections=KlikavecConfig.sections(config);
        var ids=[];collect(config["items"],ids);
        for(var k=0;k<ids.size();k++) {
            var row=Storage.getValue("kh_state_"+ids[k]);
            if(row instanceof Lang.Array && row.size()==4 && row[0] instanceof Lang.String &&
                row[1] instanceof Lang.String && row[2] instanceof Lang.Number && row[3] instanceof Lang.Number) {
                states[ids[k]]=[row[0],row[1],row[2]];received[ids[k]]=row[3];
            }
        }
        service=new HomeAssistantService();
    }

    function configured() {
        var url=Settings.getApiUrl();
        return url.length()>12 && url.find("@") == null && url.find("?") == null && url.find("#") == null && "https://".equals(url.substring(0,8)) &&
            "/api".equals(url.substring(url.length()-4,url.length())) && Settings.getApiKey().length()>0;
    }

    function collect(items,result) {
        for (var i=0;i<items.size();i++) {
            var item=items[i];
            if ("group".equals(item["type"])) { collect(item["items"],result); }
            else if (item.hasKey("entity")) {
                addUnique(result,item["entity"]);
                if (item.hasKey("humidity")) { addUnique(result,item["humidity"]); }
            }
        }
    }
    function addUnique(a,id) {
        for(var i=0;i<a.size();i++) { if(a[i].equals(id)) { return; } }
        a.add(id);
    }

    function refresh(items) {
        if (stopped) { return; }
        if (busy) { refreshAfter=true; return; }
        if (!configured()) { message="Nastav HTTPS a token"; offline=true; WatchUi.requestUpdate(); return; }
        requested=[]; collect(items,requested);
        if (requested.size()==0) { return; }
        // Upstream authenticated POST transport, with a compact HA template response.
        var ids="[";
        for(var i=0;i<requested.size();i++) { if(i>0){ids+=",";} ids+="'"+requested[i]+"'"; }
        ids+="]";
        var template="{% set ns=namespace(rows=[]) %}{% for id in "+ids+" %}"+
            "{% set e=states[id] %}{% set age=-1 %}{% if e is defined and e is not none %}"+
            "{% set age=(as_timestamp(now())-as_timestamp(e.last_reported,as_timestamp(e.last_updated)))|int %}{% endif %}"+
            "{% set ns.rows=ns.rows+[[id,states(id),state_attr(id,'unit_of_measurement') or '',age]] %}"+
            "{% endfor %}{{ns.rows|tojson}}";
        busy=true; requestTime=System.getTimer(); message="Načítání…";
        try {service.callEntity(Settings.getApiUrl()+"/template",{"template"=>template},method(:onStates));}
        catch(e){busy=false;offline=true;message="Požadavek selhal";pending=null;}
        WatchUi.requestUpdate();
    }

    function onStates(code,data) {
        if(stopped){return;}
        System.println("Klikavec states HTTP "+code+"; entities "+requested.size()+"; ms "+(System.getTimer()-requestTime));
        busy=false;
        if (code==200 && validResponse(data)) {
            var now=Time.now().value();
            for(var i=0;i<data.size();i++) {
                var row=data[i]; states[row[0]]=[row[1],row[2],row[3]]; received[row[0]]=now;
            }
            offline=false; message="Aktualizováno";
            if(pending!=null) {
                message=(actionAccepted && states[pending][0].equals(desired)) ? "Stav potvrzen" : "Akce neověřena";
                pending=null; desired=null;
            }
            save();
        } else {
            offline=true;
            if(code==401 || code==403) {message="Ověř token / přístup";}
            else if(code==200 || code==Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE) {message="Chybná odpověď JSON";}
            else { message="Offline · kód "+code; }
            pending=null; desired=null;
        }
        WatchUi.requestUpdate();
        if(refreshAfter) { refreshAfter=false; getKlikavecApp().refreshVisible(); }
    }

    function validResponse(data) {
        if(!(data instanceof Lang.Array) || data.size()!=requested.size()) {return false;}
        for(var i=0;i<data.size();i++) {
            var r=data[i];
            if(!(r instanceof Lang.Array) || r.size()!=4 || !(r[0] instanceof Lang.String) || !r[0].equals(requested[i]) ||
                !(r[1] instanceof Lang.String) || r[1].length()>80 ||
                !(r[2] instanceof Lang.String) || r[2].length()>12 || !(r[3] instanceof Lang.Number)) {return false;}
        }
        return true;
    }

    function save() {
        // Each entity is a separate small value, safely below the 8 KB per-value limit.
        try {
            for(var i=0;i<requested.size();i++) {
                var id=requested[i];var row=states[id];
                Storage.setValue("kh_state_"+id,[row[0],row[1],row[2],received[id]]);
            }
            for(var s=0;s<sections.size();s++) {
                var home=sections[s];
                if(home["home"]==true && home["items"].size()>=2) {
                    var a=home["items"][0];var b=home["items"][1];
                    Storage.setValue("kh_glance",{"time"=>Time.now().value(),
                        "text"=>display(a)+" / "+display(b),
                        "stale"=>stale(a) || stale(b) || "unknown".equals(quality(a)) || "unknown".equals(quality(b))});
                    break;
                }
            }
        }
        catch(e) { message="Data bez uložení cache"; }
    }

    function state(item) { return states[item["entity"]]; }
    function stale(item) {
        var r=state(item); var t=received[item["entity"]];
        if(r==null || t==null || offline) {return true;}
        var elapsed=Time.now().value()-t;
        if(elapsed<0 || elapsed>300) {return true;}
        var maxAge=item["maxAge"];
        return maxAge!=null && maxAge>0 && (r[2]<0 || r[2]+elapsed>maxAge);
    }

    function quality(item) {
        var r=state(item);
        if(r==null || "unknown".equals(r[0]) || "unavailable".equals(r[0]) || "None".equals(r[0])) {return "unknown";}
        if(stale(item)) {return "stale";}
        var value=r[0].toFloat();
        if ((item.hasKey("minValid") && (value==null || value<item["minValid"])) ||
            (item.hasKey("maxValid") && (value==null || value>item["maxValid"]))) {return "invalid";}
        var kind=item["status"];
        if("connectivity".equals(kind)) {return "on".equals(r[0]) ? "ok" : "error";}
        if("heating".equals(kind)) {return "on".equals(r[0]) ? "warning" : "info";}
        if("health".equals(kind)) {
            if("OK".equals(r[0]) || "normal".equals(r[0]) || "Online".equals(r[0]) || "online".equals(r[0])) {return "ok";}
            if("On Battery".equals(r[0]) || "OB".equals(r[0]) || "warning".equals(r[0])) {return "warning";}
            return "error";
        }
        if(value!=null && ((item.hasKey("low") && value<item["low"]) || (item.hasKey("high") && value>item["high"]))) {return "warning";}
        if(value!=null && (item.hasKey("low") || item.hasKey("high"))) {return "ok";}
        if("toggle".equals(item["type"])) {return "on".equals(r[0]) ? "ok" : "info";}
        return "info";
    }

    function display(item) {
        var r=state(item); var q=quality(item);
        if("unknown".equals(q)) {return "Nedostupné";}
        if("invalid".equals(q)) {return "Neplatné měření";}
        // Experimental stale readings must not look like valid measurements.
        if("stale".equals(q) && item.hasKey("minValid")) {return "Stará data";}
        var s=r[0];
        if("on".equals(s)) {s="heating".equals(item["status"]) ? "Topí" : "Zapnuto";}
        else if("off".equals(s)) {s="heating".equals(item["status"]) ? "Netopí" : "Vypnuto";}
        var unit=item["unit"]; if(unit==null){unit=r[1];}
        var n=r[0].toFloat();
        if(n!=null && !"".equals(unit)) {s=n.format("°C".equals(unit) || "ms".equals(unit) || "hPa".equals(unit) ? "%.1f" : "%.0f");}
        return s+("".equals(unit) ? "" : " "+unit);
    }

    function toggle(item,confirmed) {
        if(stopped || busy || !configured() || !KlikavecConfig.writable(item["entity"])) {return;}
        var r=state(item);
        if(stale(item) || r==null || (!"on".equals(r[0]) && !"off".equals(r[0]))) {
            message="Nejdřív obnov data"; WatchUi.requestUpdate(); return;
        }
        if ((item["confirm"]==true || "switch.zasuvka_1".equals(item["entity"])) && !confirmed) {
            getKlikavecApp().confirmAction(item); return;
        }
        pending=item["entity"]; desired="on".equals(r[0]) ? "off" : "on";actionAccepted=false;
        busy=true; message="Odesílání…";
        var domain=pending.substring(0,pending.find("."));
        try {
            service.callEntity(Settings.getApiUrl()+"/services/"+domain+"/turn_"+desired,
                {"entity_id"=>pending},method(:onAction));
        } catch(e){busy=false;pending=null;message="Akce neodeslána";}
        WatchUi.requestUpdate();
    }

    function onAction(code,data) {
        if(stopped){return;}
        busy=false;
        actionAccepted=code==200;
        // A timeout is ambiguous: read back once; never repeat the write.
        if(code!=200) {message="Akce neověřena · "+code;}
        else {message="Ověřování stavu…";}
        var id=pending;
        if(id!=null) {refresh([{"entity"=>id,"type"=>"info"}]);}
    }

    function loadConfig() {
        if(stopped || busy){return;}
        var url=Settings.getConfigUrl();
        // Only fetch config from the authenticated HA origin, never arbitrary public hosting.
        var api=Settings.getApiUrl();
        if(!configured() || url.length()==0 || api.length()<4) {message="Zadej URL konfigurace"; WatchUi.requestUpdate();return;}
        var origin=api.substring(0,api.length()-4)+"/";
        if(url.length()<=origin.length() || !url.substring(0,origin.length()).equals(origin)) {
            message="Konfigurace: stejný HA host"; WatchUi.requestUpdate();return;
        }
        busy=true; message="Načítám konfiguraci…";
        try { Communications.makeWebRequest(url,null,{
            :method=>Communications.HTTP_REQUEST_METHOD_GET,
            :responseType=>Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            :headers=>Settings.augmentHttpHeaders({"Authorization"=>"Bearer "+Settings.getApiKey()})
        },method(:onConfigResponse)); }
        catch(e){busy=false;message="Konfiguraci nelze načíst";}
        WatchUi.requestUpdate();
    }

    // The SDK callback declaration excludes Array even though parsed JSON may be an array.
    // Keep the SDK signature at the boundary, and validate every JSON shape separately.
    function onConfigResponse(code as Lang.Number,data as Null or Lang.Dictionary or Lang.String) as Void {
        onConfig(code,data);
    }
    function onConfig(code as Lang.Number,data as Lang.Object?) as Void {
        if(stopped){return;}
        busy=false;
        if(code==200 && KlikavecConfig.valid(data)) {
            // Validate and limit unique IDs before accepting remote JSON.
            var ids=[]; collect(data["items"],ids);
            if(ids.size()>60) {message="Příliš mnoho entit"; WatchUi.requestUpdate();return;}
            config=data; sections=KlikavecConfig.sections(config);
            try {
                Storage.setValue("kh_config_count",0);
                for(var i=0;i<config["items"].size();i++){Storage.setValue("kh_config_"+i,config["items"][i]);}
                Storage.setValue("kh_theme",config["theme"]);
                Storage.setValue("kh_config_count",config["items"].size());
                message="Konfigurace načtena";
            } catch(e) {message="Konfigurace bez cache";}
            getKlikavecApp().resetNavigation();
        } else {message=code==200 ? "Neplatná konfigurace" : "Konfigurace · kód "+code;}
        WatchUi.requestUpdate();
    }
}
