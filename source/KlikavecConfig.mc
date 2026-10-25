// Klikavec Home extensions. MIT; original transport remains in HomeAssistantService.
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Application.Storage;

class KlikavecConfig {
    static function onlyKeys(item,allowed) {
        var keys=item.keys();
        for(var i=0;i<keys.size();i++) {
            var found=false;
            for(var j=0;j<allowed.size();j++){if(allowed[j].equals(keys[i])){found=true;}}
            if(!found){return false;}
        }
        return true;
    }
    static function sizeBudget(item) {
        var total=120+item["name"].length()*3;
        if(item.hasKey("entity")){total+=item["entity"].length()+150;}
        if(item.hasKey("humidity")){total+=item["humidity"].length();}
        if("group".equals(item["type"])) {
            for(var i=0;i<item["items"].size();i++){total+=sizeBudget(item["items"][i]);}
        }
        return total;
    }
    static function writable(id) {
        return "light.led_pasek".equals(id) || "light.zvonek_panel_podsviceni".equals(id) ||
            "switch.zasuvka_venku".equals(id) || "switch.0xa4c13800486fffff".equals(id) ||
            "switch.0xa4c138bb867ffa04".equals(id) || "switch.zasuvka_1".equals(id);
    }

    static function entityId(id) {
        if (!(id instanceof Lang.String) || id.length() < 3 || id.length() > 100) { return false; }
        var dot = false;
        for (var i=0; i<id.length(); i++) {
            var c=id.substring(i,i+1);
            if (".".equals(c)) { if (dot || i==0 || i==id.length()-1) { return false; } dot=true; }
            else if ("abcdefghijklmnopqrstuvwxyz0123456789_".find(c) == null) { return false; }
        }
        return dot;
    }

    static function validItem(item, depth) {
        if (!(item instanceof Lang.Dictionary) || depth>3) { return false; }
        var name=item["name"];
        var type=item["type"];
        if (!(name instanceof Lang.String) || name.length()==0 || name.length()>64) { return false; }
        if ("group".equals(type)) {
            if(!onlyKeys(item,["type","name","title","icon","home","visible","items"])) {return false;}
            if(item.hasKey("title") && (!(item["title"] instanceof Lang.String) || item["title"].length()>64)) {return false;}
            if(item.hasKey("home") && !(item["home"] instanceof Lang.Boolean)) {return false;}
            if(item.hasKey("visible") && !(item["visible"] instanceof Lang.Boolean)) {return false;}
            if(item.hasKey("icon") && (!(item["icon"] instanceof Lang.String) || item["icon"].length()>20)) {return false;}
            return validItems(item["items"],depth+1);
        }
        if ("info".equals(type) || "toggle".equals(type)) {
            if(!onlyKeys(item,["type","name","entity","humidity","unit","confirm","favorite","status","maxAge","low","high","minValid","maxValid"])) {return false;}
            if (!entityId(item["entity"])) { return false; }
            if ("toggle".equals(type) && !writable(item["entity"])) { return false; }
            if (item.hasKey("humidity") && !entityId(item["humidity"])) { return false; }
            if (item.hasKey("unit") && (!(item["unit"] instanceof Lang.String) || item["unit"].length()>8)) { return false; }
            var numbers=["maxAge","low","high","minValid","maxValid"];
            for (var i=0;i<numbers.size();i++) {
                if (item.hasKey(numbers[i]) && !(item[numbers[i]] instanceof Lang.Number) && !(item[numbers[i]] instanceof Lang.Float)) { return false; }
            }
            if (item.hasKey("maxAge") && (item["maxAge"]<0 || item["maxAge"]>604800)) { return false; }
            if (item.hasKey("confirm") && !(item["confirm"] instanceof Lang.Boolean)) { return false; }
            if (item.hasKey("favorite") && !(item["favorite"] instanceof Lang.Boolean)) { return false; }
            if(item.hasKey("status") && (! (item["status"] instanceof Lang.String) ||
                !("connectivity".equals(item["status"]) || "heating".equals(item["status"]) || "health".equals(item["status"])))) {return false;}
            if ("switch.zasuvka_1".equals(item["entity"]) && item["favorite"]==true) { return false; }
            if(item.hasKey("minValid") && item.hasKey("maxValid") && item["minValid"]>item["maxValid"]) {return false;}
            return true;
        }
        if ("link".equals(type)) { return onlyKeys(item,["type","name","target"]) && item["target"] instanceof Lang.String && item["target"].length()<=64; }
        return onlyKeys(item,["type","name"]) && ("refresh".equals(type) || "config".equals(type) || "about".equals(type));
    }

    static function validItems(items,depth) {
        if (!(items instanceof Lang.Array) || items.size()==0 || items.size()>20) { return false; }
        for (var i=0;i<items.size();i++) { if (!validItem(items[i],depth)) { return false; } }
        return true;
    }

    static function valid(config) {
        if (!(config instanceof Lang.Dictionary) || config["version"]!=1 || !validItems(config["items"],1) || config["items"].size()>6) { return false; }
        if(!onlyKeys(config,["version","title","$schema","theme","items"])) {return false;}
        if(config.hasKey("title") && (!(config["title"] instanceof Lang.String) || config["title"].length()>64)){return false;}
        if(config.hasKey("$schema") && (!(config["$schema"] instanceof Lang.String) || config["$schema"].length()>512)){return false;}
        var visible=0;var homes=0;
        for (var i=0;i<config["items"].size();i++) {
            var s=config["items"][i];
            if(sizeBudget(s)>6000) {return false;}
            if(s["home"]==true){homes++;}
            for(var k=0;k<i;k++) {if(config["items"][k]["name"].equals(s["name"])) {return false;}}
            if (!"group".equals(s["type"])) { return false; }
            if (s.hasKey("visible") && !(s["visible"] instanceof Lang.Boolean)) { return false; }
            if (s["visible"]!=false) { visible++; }
        }
        if (config.hasKey("theme")) {
            var t=config["theme"];
            if (!(t instanceof Lang.Dictionary)) { return false; }
            var keys=["ok","warning","error","info"];
            if(!onlyKeys(t,keys)) {return false;}
            for (var j=0;j<keys.size();j++) {
                if (t.hasKey(keys[j]) && (!(t[keys[j]] instanceof Lang.Number) || t[keys[j]]<0 || t[keys[j]]>16777215)) { return false; }
            }
        }
        return visible>0 && homes<=1;
    }

    static function bundled() { return WatchUi.loadResource(Rez.JsonData.KlikavecConfig); }
    static function sections(config) {
        var result=[];
        for (var i=0;i<config["items"].size();i++) {
            if (config["items"][i]["visible"]!=false) { result.add(config["items"][i]); }
        }
        return result;
    }
}
