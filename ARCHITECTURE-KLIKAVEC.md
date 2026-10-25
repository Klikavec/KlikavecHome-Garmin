# Technické rozhodnutí — 2026-10-24 [CX]

## Zachovaný upstream

Výchozí commit `35d7adf` z `house-of-abbey/GarminHomeAssistant`, celá Git historie a původní MIT licence. `HomeAssistantService.callEntity()` zůstává autorizovaným POST transportem (Bearer token, JSON, vlastní HTTP hlavičky, Garmin Communications). `Settings` zůstává zdrojem nativních Application Properties. Původní zdroje a původní build se nepřepisují; nová aplikace má vlastní manifest, UUID a jungle soubor.

## Nová vrstva

- `KlikavecApp`: životní cyklus a napojení na upstream App/Settings. Při změně nastavení odstaví starý model, takže jeho opožděná odpověď neovlivní nový.
- `KlikavecModel`: agregovaný read-only HA template pro aktuální obrazovku, cache po jednotlivých entitách a ověřené akce přes původní transport. Service HTTP 200 samo nestačí; následuje nový dotaz na skutečný stav. Chybějící/prázdná odpověď se nepřekládá na odhadnutý úspěch. Neúspěšný zápis se neopakuje.
- `KlikavecService`: dědí původní transport akcí; pro `/api/template` výslovně žádá `text/plain`, jak ho HA vrací. Čtení používá verzovaný kompaktní text KH1 s řádky `entity|stav|jednotka|stáří`. Oddělovače a nové řádky ve zdrojové hodnotě vedou k `unknown`, nikoli k vložení dalšího řádku. Model kontroluje délku, počet/přesné pořadí ID, počet polí a celé nezáporné stáří nebo -1. Neplatná odpověď zachová cache. JSON konfigurace a nativní nastavení se nemění.
- `KlikavecConfig`: kontrola tvaru a limitů JSON na hodinkách, ochrana proti vložení template kódu přes entity ID a allowlist šesti ověřených přepínačů. Neobsahuje tajné hodnoty.
- `KlikavecView` + `KlikavecComponents`: čitelné komponenty pro 240 × 240, měření skutečné šířky textu, stránkovaný úplný název a navigace Garmin BehaviorDelegate.
- `KlikavecGlanceView`: malý cache-only proces, bez sítě, tokenu, konfigurace nebo časovače.

Konfigurace vychází z upstream `title/items/group/info/toggle`, ale nepřebírá neomezené služby, libovolné zanoření ani opakované pollování. Nové validované atributy mají vlastní `klikavec.schema.json`. Vestavěný JSON resource generuje `tools/make_default_config.py` z reviewovatelného příkladu. Budoucí HACS konfigurátor může vydávat tentýž formát přes soukromý endpoint bez změny rendereru.

## HA a přístupové cesty

Audit potvrdil běžící Cloudflared i Tailscale. Cloudflared HTTPS cesta má důvěryhodný certifikát a byla ověřena autentizovanými čteními i oběma směry LED z Garmin simulátoru. Tailscale má nakonfigurované sdílení `funnel` na 443, ale konkrétní DNS jméno a dostupnost z telefonu nebyly nezávisle ověřeny; tato cesta není nutná pro MVP.

Nový zápisový proxy endpoint není nasazený. Existující připojený MCP administrační tunel není Garmin REST proxy a jeho přístupové údaje aplikace nepřebírá. Aplikace proto používá funkční HTTPS HA REST cestu s klientským allowlistem. Tento allowlist neomezuje oprávnění samotného HA tokenu na serveru. Pro budoucí proxy je třeba zachovat `/api/template` pro čtení, povolit jen uvedené entity + `light/switch.turn_on/turn_off`, odmítat ostatní cíle a znovu auditovat oprávnění. Nasazení proxy a změny HA automatizací nejsou součástí této úpravy.

Bylo odmítnuto: veřejné osobní JSON v `/local/`, HTTP výjimka, opakované automatické zápisy po timeoutu, optimistické překlápění přepínače, převzetí mobile_app registrací/senzorových uploadů a spuštění vodárny bez auditu. Výchozí data se obnovují při otevření a ručně. Nativní Background/Positioning oprávnění jsou zatím vyžadovaná přeloženými upstream anotovanými třídami; nový vstupní bod nevolá jejich registrace ani sběr polohy.

## Paměť

Profil SDK: `fenix7s`, `round-240x240`, MIP, `ARGB2222`, watch-app 786432 B, glance 65536 B. U zdrojů a fontů jde o oficiální profil, nikoli upravený obraz jiného zařízení. Zátěž se měří v simulátoru; skutečný firmware a spotřebu baterie ověří majitel.

## Druhá fáze

Pračka hOn, VIGI person detection a Watch History čekají na konkrétní ověřená entity ID. BT725 zapisovací mechanismus není ověřený, a proto nejsou tlačítka teploty. Vodárna je nepřepnutelná i při chybném návrhu JSON. Pro její budoucí ovládání je nutný audit ochrany proti suchoběhu a všech návazných automatizací.
