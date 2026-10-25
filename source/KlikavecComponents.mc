using Toybox.Graphics;
using Toybox.Lang;

// All text is measured in the actual Garmin font, then shortened to fit the chord.
class SectionHeader {
    static function fit(dc,text,font,width) {
        if(dc.getTextWidthInPixels(text,font)<=width) {return text;}
        while(text.length()>0 && dc.getTextWidthInPixels(text+"…",font)>width) {
            text=text.substring(0,text.length()-1);
        }
        return text+"…";
    }
    static function text(dc,x,y,text,font,color,width,align) {
        dc.setColor(color,Graphics.COLOR_TRANSPARENT);
        dc.drawText(x,y,font,fit(dc,text,font,width),align);
    }
    static function draw(dc,title,subtitle,color) {
        text(dc,120,24,title,Graphics.FONT_SMALL,Graphics.COLOR_WHITE,142,Graphics.TEXT_JUSTIFY_CENTER);
        text(dc,120,48,subtitle,Graphics.FONT_XTINY,color,188,Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(color,Graphics.COLOR_BLACK); dc.drawLine(50,72,190,72);
    }
    static function wrap(dc,value,font,width) {
        var result=[];
        while(value.length()>0) {
            var part=fit(dc,value,font,width);
            if(part.equals(value)) {result.add(value);break;}
            var count=part.length()-1;
            result.add(value.substring(0,count));value=value.substring(count,value.length());
        }
        return result;
    }
}

class StatusIndicator {
    static function color(model,quality) {
        var theme=model.config["theme"];
        var key=quality;
        if("unknown".equals(key) || "stale".equals(key) || "invalid".equals(key)) {return 0xAAAAAA;}
        if(theme!=null && theme.hasKey(key)) {return theme[key];}
        if("ok".equals(key)) {return 0x00FF00;}
        if("error".equals(key)) {return 0xFF0000;}
        if("warning".equals(key)) {return 0xFFAA00;}
        return 0x00AAFF;
    }
    static function draw(dc,x,y,color) {dc.setColor(color,Graphics.COLOR_BLACK);dc.fillCircle(x,y,3);}
}

class MetricTile {
    static function draw(dc,model,item,x,y,width) {
        var q=model.quality(item); var c=StatusIndicator.color(model,q);
        SectionHeader.text(dc,x,y,item["name"],Graphics.FONT_XTINY,0xAAAAAA,width,Graphics.TEXT_JUSTIFY_CENTER);
        SectionHeader.text(dc,x,y+20,model.display(item),Graphics.FONT_MEDIUM,c,width,Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class ActionTile {
    static function draw(dc,name,value,y,selected,color) {
        if(selected) {
            dc.setColor(0x000055,Graphics.COLOR_BLACK);
            dc.fillRoundedRectangle(24,y,192,58,7);
            dc.setColor(color,Graphics.COLOR_BLACK); dc.fillRectangle(24,y+12,3,32);
        }
        SectionHeader.text(dc,36,y+3,name,Graphics.FONT_XTINY,Graphics.COLOR_WHITE,166,Graphics.TEXT_JUSTIFY_LEFT);
        SectionHeader.text(dc,36,y+23,value,Graphics.FONT_SMALL,color,166,Graphics.TEXT_JUSTIFY_LEFT);
    }
}

class ToggleRow {
    static function draw(dc,model,item,y,selected) {
        var q=model.quality(item);
        var value=model.display(item);
        if("stale".equals(q) && !"Stará data".equals(value)) {value="Stará data · "+value;}
        ActionTile.draw(dc,item["name"],value,y,selected,StatusIndicator.color(model,q));
    }
}

// A custom confirmation is keyboard operable and defaults to cancellation.
class ConfirmationDialog {
    static function draw(dc,model,item,yes) {
        SectionHeader.draw(dc,"Potvrdit akci","START vybere · BACK zruší",0xFFAA00);
        SectionHeader.text(dc,120,85,item["name"],Graphics.FONT_SMALL,Graphics.COLOR_WHITE,196,Graphics.TEXT_JUSTIFY_CENTER);
        var r=model.state(item);
        SectionHeader.text(dc,120,116,r!=null && "on".equals(r[0]) ? "Vypnout?" : "Zapnout?",Graphics.FONT_MEDIUM,0xFFAA00,192,Graphics.TEXT_JUSTIFY_CENTER);
        SectionHeader.text(dc,120,159,yes ? "ANO · provést" : "NE · zrušit",Graphics.FONT_SMALL,yes ? 0xFFAA00 : Graphics.COLOR_WHITE,184,Graphics.TEXT_JUSTIFY_CENTER);
    }
}
