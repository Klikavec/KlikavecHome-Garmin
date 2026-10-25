using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Time;
using Toybox.System;

class KlikavecView extends WatchUi.View {
    var model;
    var section=0;
    var index=0;
    var level=0;
    var advanced=null;
    var returnIndex=0;
    var detail=null;
    var detailPage=0;
    var confirmation=null;
    var yes=false;

    function initialize(m) {View.initialize();model=m;}
    function items() {return advanced!=null ? advanced["items"] : model.sectionItems(model.sections[section]);}
    function onShow() {model.refresh(items());}
    function move(direction) {
        if(confirmation!=null) {yes=!yes;}
        else if(detail!=null) {detailPage=detailPage+direction;if(detailPage<0){detailPage=0;}}
        else if(level==0) {
            section=(section+direction+model.sections.size())%model.sections.size(); index=0;
            model.refresh(items());
        } else {index=(index+direction+items().size())%items().size();}
        WatchUi.requestUpdate();
    }
    function back() {
        if(confirmation!=null) {confirmation=null;yes=false;}
        else if(detail!=null) {detail=null;}
        else if(advanced!=null) {advanced=null;index=returnIndex;}
        else if(level>0) {level=0;index=0;}
        else {System.exit();}
        WatchUi.requestUpdate();
    }
    function select() {
        if(confirmation!=null) {
            var item=confirmation; var agreed=yes;
            confirmation=null;yes=false;
            if(agreed){model.toggle(item,true);}
        } else if(detail!=null) {model.refresh([detail]);}
        else if(level==0) {
            level=1;index=0;
            if(model.sections[section]["home"]==true) {
                var home=items();
                for(var h=0;h<home.size();h++) {
                    if("toggle".equals(home[h]["type"]) || "link".equals(home[h]["type"])) {index=h;break;}
                }
            }
            model.refresh(items());
        }
        else {
            var item=items()[index]; var type=item["type"];
            if("toggle".equals(type)) {model.toggle(item,false);}
            else if("group".equals(type)) {advanced=item;returnIndex=index;index=0;model.refresh(items());}
            else if("info".equals(type)) {
                // Replace the advanced page, keeping the content stack to three levels.
                if(advanced!=null){advanced=null;index=returnIndex;}
                detail=item;detailPage=0;
            }
            else if("link".equals(type)) {
                for(var i=0;i<model.sections.size();i++) {
                    if(model.sections[i]["name"].equals(item["target"])) {section=i;index=0;model.refresh(items());break;}
                }
            } else if("refresh".equals(type)) {
                // Settings refresh refreshes Domov, and then the next opened section.
                model.refresh(model.sections[0]["items"]);
            } else if("config".equals(type)) {model.loadConfig();}
            else {detail={"type"=>"about","name"=>"Klikavec Home"};}
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);dc.clear();
        if(confirmation!=null) {ConfirmationDialog.draw(dc,model,confirmation,yes);return;}
        var sec=model.sections[section];
        var accent=StatusIndicator.color(model,"info");
        if(detail!=null) {drawDetail(dc,accent);return;}
        var title=advanced!=null ? advanced["name"] : sec["name"];
        var status=!model.configured() ? "Nastav HTTPS a token" : model.message;
        if(model.offline && "Připraveno".equals(model.message)) {status="OFFLINE · poslední data";}
        SectionHeader.draw(dc,title,status,model.offline ? 0xAAAAAA : accent);
        if(level==0 && sec["home"]==true && sec["items"].size()>=5) {drawHome(dc,sec);}
        else if(level==0) {drawSection(dc,sec,accent);}
        else {drawRows(dc);}
        SectionHeader.text(dc,120,208,level==0 ? (section+1)+"/"+model.sections.size()+" · START" : (index+1)+"/"+items().size()+" · BACK",Graphics.FONT_XTINY,0xAAAAAA,108,Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawHome(dc,sec) {
        var a=sec["items"];
        MetricTile.draw(dc,model,a[0],70,78,91);
        MetricTile.draw(dc,model,a[1],170,78,91);
        dc.setColor(0x555555,Graphics.COLOR_BLACK);dc.drawLine(120,81,120,126);
        for(var i=2;i<5;i++) {
            var x=46+(i-2)*74;
            StatusIndicator.draw(dc,x,138,StatusIndicator.color(model,model.quality(a[i])));
            SectionHeader.text(dc,x,146,a[i]["name"],Graphics.FONT_XTINY,Graphics.COLOR_WHITE,70,Graphics.TEXT_JUSTIFY_CENTER);
            var value=model.display(a[i]);
            if(i==2 && "Zapnuto".equals(value)){value="OK";}
            SectionHeader.text(dc,x,166,value,Graphics.FONT_XTINY,StatusIndicator.color(model,model.quality(a[i])),70,Graphics.TEXT_JUSTIFY_CENTER);
        }
        SectionHeader.text(dc,120,190,"LED · zásuvka · klima",Graphics.FONT_XTINY,0x00AAFF,171,Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawSection(dc,sec,accent) {
        // Simple vector icon fits MIP; no large image buffers or animation timer.
        var icon=sec["icon"];
        dc.setColor(accent,Graphics.COLOR_BLACK);
        if("temperature".equals(icon)) {dc.drawRoundedRectangle(112,82,16,40,7);dc.fillCircle(120,127,12);}
        else if("network".equals(icon)) {
            dc.drawRectangle(104,83,32,20);dc.drawLine(120,103,120,122);dc.drawLine(86,122,154,122);
            dc.drawRectangle(77,122,20,16);dc.drawRectangle(110,122,20,16);dc.drawRectangle(143,122,20,16);
        } else if("leaf".equals(icon)) {dc.drawEllipse(100,80,40,56);dc.drawLine(106,139,132,91);}
        else if("settings".equals(icon)) {dc.drawCircle(120,108,26);dc.drawCircle(120,108,9);}
        else {dc.drawCircle(120,111,25);dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);dc.fillRectangle(113,80,14,25);dc.setColor(accent,Graphics.COLOR_BLACK);dc.fillRectangle(117,80,6,31);}
        var subtitle="Klima".equals(sec["name"]) ? "Teploty · vlhkost · BT725" :
            ("Stav domu".equals(sec["name"]) ? "Síť · UPS · NAS" :
            ("Zahrada".equals(sec["name"]) ? "Počasí · bazén · rostliny" :
            ("Nastavení".equals(sec["name"]) ? "Obnova · konfigurace" : "Světla · zásuvky")));
        SectionHeader.text(dc,120,153,subtitle,Graphics.FONT_XTINY,Graphics.COLOR_WHITE,200,Graphics.TEXT_JUSTIFY_CENTER);
        SectionHeader.text(dc,120,179,"UP / DOWN další sekce",Graphics.FONT_XTINY,0xAAAAAA,180,Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawRows(dc) {
        var a=items(); var start=(index/2).toNumber()*2;
        for(var j=0;j<2 && start+j<a.size();j++) {
            var item=a[start+j]; var y=80+j*61;
            if("info".equals(item["type"]) || "toggle".equals(item["type"])) {ToggleRow.draw(dc,model,item,y,start+j==index);}
            else {
                var hint="group".equals(item["type"]) ? "Otevřít >" : ("link".equals(item["type"]) ? "Zobrazit >" : "START vybrat");
                ActionTile.draw(dc,item["name"],hint,y,start+j==index,StatusIndicator.color(model,"info"));
            }
        }
    }

    function drawDetail(dc,accent) {
        SectionHeader.draw(dc,"about".equals(detail["type"]) ? "Klikavec Home" : "Detail","BACK zpět · START obnovit",accent);
        if("about".equals(detail["type"])) {
            var lines=["HTTPS + token v nastavení","UP / DOWN: pohyb","START: výběr / obnova","MENU: ruční obnova","BT725 a vodárna: čtení"];
            for(var i=0;i<lines.size();i++){SectionHeader.text(dc,120,82+i*23,lines[i],Graphics.FONT_XTINY,Graphics.COLOR_WHITE,196,Graphics.TEXT_JUSTIFY_CENTER);}
            return;
        }
        var name=detail["name"];
        var lines=SectionHeader.wrap(dc,name,Graphics.FONT_XTINY,196);
        var pages=((lines.size()+2)/3).toNumber();
        detailPage=detailPage%pages;
        for(var n=0;n<3 && detailPage*3+n<lines.size();n++) {
            SectionHeader.text(dc,120,80+n*20,lines[detailPage*3+n],Graphics.FONT_XTINY,Graphics.COLOR_WHITE,196,Graphics.TEXT_JUSTIFY_CENTER);
        }
        if(pages>1) {SectionHeader.text(dc,120,59,"UP/DOWN: název "+(detailPage+1)+"/"+pages,Graphics.FONT_XTINY,accent,180,Graphics.TEXT_JUSTIFY_CENTER);}
        SectionHeader.text(dc,120,143,model.display(detail),Graphics.FONT_MEDIUM,StatusIndicator.color(model,model.quality(detail)),202,Graphics.TEXT_JUSTIFY_CENTER);
        var q=model.quality(detail); var line="stale".equals(q) ? "NEAKTUÁLNÍ DATA" : ("invalid".equals(q) ? "Mimo platný rozsah" : "Jen pro čtení");
        var t=model.received[detail["entity"]];
        if(t!=null && !"stale".equals(q) && !"invalid".equals(q)) {line="Načteno před "+((Time.now().value()-t)/60).toNumber()+" min";}
        SectionHeader.text(dc,120,179,line,Graphics.FONT_XTINY,0xAAAAAA,180,Graphics.TEXT_JUSTIFY_CENTER);
        if(detail.hasKey("humidity")) {
            var humidity={"entity"=>detail["humidity"],"unit"=>"%","maxAge"=>detail["maxAge"]};
            var value=model.display(humidity);
            if(model.stale(humidity)){value="stará data";}
            SectionHeader.text(dc,120,201,"Vlhkost: "+value,Graphics.FONT_XTINY,Graphics.COLOR_WHITE,132,Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}

class KlikavecDelegate extends WatchUi.BehaviorDelegate {
    var view;
    function initialize(v) {BehaviorDelegate.initialize();view=v;}
    function onNextPage() {view.move(1);return true;}
    function onPreviousPage() {view.move(-1);return true;}
    function onSelect() {view.select();return true;}
    function onBack() {view.back();return true;}
    function onMenu() {view.model.refresh(view.items());return true;}
    function onTap(event) {view.select();return true;}
    function onSwipe(event) {
        if(event.getDirection()==WatchUi.SWIPE_UP){view.move(1);}
        else if(event.getDirection()==WatchUi.SWIPE_DOWN){view.move(-1);}
        else {view.back();}
        return true;
    }
}
