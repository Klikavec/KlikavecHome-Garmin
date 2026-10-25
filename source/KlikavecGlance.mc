using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application.Storage;
using Toybox.Time;
using Toybox.Lang;

// No network, timers, tokens or configuration loading in the 64 KB glance process.
(:glance)
class KlikavecGlanceView extends WatchUi.GlanceView {
    function initialize() {GlanceView.initialize();}
    function text(dc,y,value,color) {
        // Garmin places the glance to the right of its launcher icon, on a curved chord.
        var font=Graphics.FONT_XTINY;var width=dc.getWidth()-20;
        while(value.length()>0 && dc.getTextWidthInPixels(value,font)>width) {value=value.substring(0,value.length()-1);}
        dc.setColor(color,Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2-22,y,font,value,Graphics.TEXT_JUSTIFY_CENTER);
    }
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);dc.clear();
        text(dc,1,"Klikavec Home",Graphics.COLOR_WHITE);
        var cached=Storage.getValue("kh_glance");
        if(!(cached instanceof Lang.Dictionary) || !(cached["time"] instanceof Lang.Number) ||
            !(cached["text"] instanceof Lang.String) || !(cached["stale"] instanceof Lang.Boolean)) {
            text(dc,23,"Otevři aplikaci",0x00AAFF);return;
        }
        var age=Time.now().value()-cached["time"];
        var stale=cached["stale"] || age<0 || age>300;
        text(dc,23,cached["text"],stale ? 0xAAAAAA : 0x00AAFF);
        text(dc,45,stale ? "Stará data" : "Cache · otevřít",stale ? 0xAAAAAA : 0x00FF00);
    }
}
