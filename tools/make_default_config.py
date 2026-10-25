"""Build the bundled configuration from the reviewable JSON example (no credentials)."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def metric(name, entity, unit="", **extra):
    return dict(type="info", name=name, entity=entity, unit=unit, **extra)

def toggle(name, entity, **extra):
    return dict(type="toggle", name=name, entity=entity, **extra)

def section(name, icon, items, **extra):
    return dict(type="group", name=name, title=name, icon=icon, items=items, **extra)

def build():
    outside="sensor.ws2900_v2_01_18_outdoor_temperature"
    inside="sensor.ws2900_v2_01_18_indoor_temperature"
    heat="binary_sensor.termostat_elektrobock_pozadavek_na_topeni"
    rooms=[("Obývák",inside,"sensor.ws2900_v2_01_18_indoor_humidity"),
           ("Ložnice","sensor.teplomer_loznice_temperature","sensor.teplomer_loznice_humidity"),
           ("Dětský pokoj","sensor.teplomer_ciri_pokojik_temperature","sensor.teplomer_ciri_pokojik_humidity"),
           ("Předsíň","sensor.teplomer_predsin_temperature","sensor.teplomer_predsin_humidity"),
           ("Sklep","sensor.teplomer_sklep_temperature","sensor.teplomer_sklep_humidity"),
           ("Sauna","sensor.0xa4c138b55a957e07_temperature","sensor.0xa4c138b55a957e07_humidity")]
    cfg={"title":"Klikavec Home", "version":1,
         "theme":{"ok":65280,"warning":16755200,"error":16711680,"info":43775},
         "items":[
        section("Domov","home",[
            metric("Venku",outside,"°C",maxAge=3600),metric("Obývák",inside,"°C",maxAge=3600),
            metric("Internet","binary_sensor.internet_pripojeni",status="connectivity"),
            metric("UPS","sensor.eaton_3s_550_ups_nabiti_baterie","%",low=30),
            metric("Topení",heat,status="heating"),
            toggle("LED pásek","light.led_pasek",favorite=True),
            toggle("Zásuvka venku","switch.zasuvka_venku",favorite=True),
            dict(type="link",name="Detail klimatu",target="Klima")],home=True),
        section("Ovládání","power",[
            toggle("LED pásek","light.led_pasek"),
            toggle("Podsvícení zvonku","light.zvonek_panel_podsviceni"),
            toggle("Zásuvka venku","switch.zasuvka_venku"),
            toggle("Zásuvka sklep","switch.0xa4c13800486fffff"),
            toggle("Zigbee zásuvka 2","switch.0xa4c138bb867ffa04"),
            section("Pokročilé","warning",[
                toggle("Bazénové čerpadlo","switch.zasuvka_1",confirm=True),
                metric("Bazén příkon","sensor.bazen_vykon","W"),
                metric("Vodárna · jen čtení","switch.zasuvka_2"),
                metric("Vodárna příkon","sensor.vodarna_vykon","W")])]),
        section("Klima","temperature",[
            metric(n,e,"°C",humidity=h,maxAge=7200) for n,e,h in rooms]+[
            metric("BT725 aktuální","sensor.termostat_elektrobock_aktualni_teplota","°C",maxAge=3600),
            metric("BT725 požadovaná","sensor.termostat_elektrobock_pozadovana_teplota","°C"),
            metric("Požadavek topení",heat,status="heating"),
            metric("Letní režim","binary_sensor.termostat_elektrobock_letni_rezim")]),
        section("Stav domu","network",[
            metric("Síť","sensor.stav_site",status="health"),
            *[metric(n,e,status="connectivity") for n,e in [
                ("Router AX73","binary_sensor.ping_router_ax73"),
                ("ISP gateway","binary_sensor.ping_isp_gateway"),
                ("Internet Google","binary_sensor.ping_internet_google")]],
            metric("Odezva Google","sensor.ping_google_rtt_avg","ms",high=100),
            metric("Výpadky / 7 dní","sensor.vypadky_za_7_dni",high=0),
            metric("UPS stav","sensor.eaton_3s_550_ups_stav",status="health"),
            metric("UPS baterie","sensor.eaton_3s_550_ups_nabiti_baterie","%",low=30),
            metric("UPS výdrž","sensor.ups_odhadovana_vydrz","min",low=10),
            metric("UPS zátěž","sensor.eaton_3s_550_ups_zatez","%",high=80),
            metric("NAS svazek","sensor.ds218play_volume_1_stav",status="health"),
            metric("NAS obsazeno","sensor.ds218play_volume_1_pouzity_objem","%",high=85),
            metric("NAS disk 1","sensor.ds218play_drive_1_stav",status="health"),
            metric("NAS disk 2","sensor.ds218play_drive_2_stav",status="health")]),
        section("Zahrada","leaf",[
            metric("Venku",outside,"°C",maxAge=3600),
            metric("Vítr","sensor.ws2900_v2_01_18_wind_speed","km/h",maxAge=3600),
            metric("Déšť dnes","sensor.ws2900_v2_01_18_daily_rain","mm"),
            metric("Tlak","sensor.ws2900_v2_01_18_relative_pressure","hPa",maxAge=3600),
            metric("Bazén","sensor.meteostanice_temperature_1","°C",maxAge=7200),
            metric("Bambusy / půda 1","sensor.bambusy_1_soil_moisture","%",low=20,maxAge=86400),
            metric("Půda 2","sensor.0xa4c1381b7ac8eef7_soil_moisture","%",low=20,maxAge=86400),
            metric("Úl 1 · experiment","input_number.bzzzt_ul_1_temperature_top","°C",maxAge=3600,minValid=0,maxValid=60),
            metric("Úl 1 vlhkost · exp.","input_number.bzzzt_ul_1_humidity_top","%",maxAge=3600,minValid=1,maxValid=100)]),
        section("Nastavení","settings",[
            dict(type="refresh",name="Obnovit data"),
            dict(type="config",name="Načíst konfiguraci"),
            dict(type="about",name="Připojení a nápověda")])
    ]}
    return cfg

if __name__ == "__main__":
    target=ROOT/"examples"/"klikavec-home.json"
    if not target.exists():
        target.write_text(json.dumps(build(),ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    cfg=json.loads(target.read_text(encoding="utf-8"))
    # jsonData is compiled by Garmin; no bespoke parser on the watch.
    folder=ROOT/"resources"/"klikavec"
    folder.mkdir(exist_ok=True)
    (folder/"default.json").write_text(json.dumps(cfg,ensure_ascii=False,separators=(",",":")),encoding="utf-8")
    (folder/"resources.xml").write_text('<resources><jsonData id="KlikavecConfig" filename="default.json" /></resources>\n',encoding="utf-8")
