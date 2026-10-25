# Ověření Klikavec Home

Provedeno 24.–25. 10. 2026. Fyzický Garmin ani Samsung nebyly připojené k automatizovanému testu. Níže jsou oddělené důkazy z oficiálního simulátoru, živého HA a kroky zbývající majiteli.

## Oprava po prvním fyzickém testu — 25. 10. 2026

Majitel po instalaci hlásil nejprve timeout a následně `Chybná odpověď JSON`. Živý kontrolní POST `/api/template` vrátil HTTP 200 a platné tělo, ale MIME `text/plain; charset=utf-8`. Původní kód požadoval JSON, což simulátor toleroval; přenos Garmin Connect má samostatnou implementaci. Čtecí transport nyní explicitně očekává text/plain a model validuje kompaktní verzovanou odpověď. Nový živý read-only test potvrdil 7 správných řádků Domova, HTTP 200, 323 B v daném běhu. Nevznikl žádný zápis do HA.

Regresní sada: **21 PASS, 0 FAIL, 0 ERROR**, včetně platných i chybných textových odpovědí; její samostatný raw výstup je `verification/plain-response-tests.log`. SDK monkeydo nadále vrací exit 1 i po všech PASS. Původních 19 testů a jejich historický log níže se zachovávají. Úspěch nové verze na fyzických hodinkách musí potvrdit majitel po novém spuštění; není odvozován ze simulátoru.

## Sestavení a prostředí

Oficiální Connect IQ SDK **9.3.0**, JDK **17**, oficiální profil **`fenix7s`**. Profil potvrzuje `round-240x240`, MIP `ARGB2222` (64 barev), limit watch-app 786432 B a glance 65536 B. Stejný produkt obsahuje upstream manifest. Sapphire Solar je varianta tohoto profilu; cílem není `fenix7spro`.

`tools/build.ps1 -Release` úspěšně vytváří podepsaný `bin/KlikavecHome.prg`. Build ze zdrojů používá původní upstream třídy, nikoli náhradní maketu. Gradual type checker hlásí varování o dynamických přístupech do JSON kontejnerů; není tvrzeno, že prošel Strict typecheck. Nejsou chyby kompilace.

Windows rezervoval TCP porty Garmin debuggeru. Runtime testy proto používají oficiální Linux simulátor stejné verze, tentýž PRG a tentýž profil/fonty, v existujícím Ubuntu/WSL s dočasným síťovým namespace. Globální síť ani firewall Windows se neměnily. Viz `ERRORS.md`.

## Nativní unit testy

**19 testů: 19 PASS, 0 FAIL, 0 ERROR.** Úplný výstup je [verification/unit-tests.log](verification/unit-tests.log). Testy běží jako Run No Evil uvnitř Garmin VM. Síťové callbacky mají v těchto unit testech fake transport; nejde o test živého serveru.

Pokrývají validní a chybný JSON/tvary/typy, entity ID a template injection, zákaz neověřených zápisů, unavailable vs. off, staré a neplatné včelí hodnoty, stáří stabilního connectivity senzoru, odmítnutí zápisu z cache, nutnost skutečného readbacku, zachování cache při chybě, kontrolu pořadí odpovědí, zastavené callbacky, zákaz úspěchu po chybovém POST, dvojí stisk, oblíbené položky a tlačítkovou navigaci.

Pozor na rozdíl mezi výsledkem testů a launcherem: Linux SDK `monkeydo` v tomto prostředí vrací exit **1** i po textovém `PASSED (passed=19, failed=0, errors=0)`. Raw log zachovává obojí. Není to označené za zelený procesní CI gate; pro automatizované CI je nutné tento rozdíl samostatně vyřešit.

## Živý Home Assistant a LED

HA verze **2026.10.2** ověřená konektorem. Znovu ověřeno všech **49** čidel/přepínačů příkladu včetně doplněných vlhkostí; všechna ID existují. Audit obsahuje jednotky, stavy a stáří hlášení: [verification/ha-audit.json](verification/ha-audit.json).

Cloudflared poskytuje funkční HTTPS endpoint s důvěryhodným certifikátem. Garmin aplikace přes něj načetla Domov, Ovládání, Klima, Stav domu a Zahradu. Sekce používají kompaktní odpovědi; zaznamenané živé čtecí požadavky trvaly přibližně **120–500 ms**. Tato hodnota platí pro simulátor/PC, nikoli pro Bluetooth a telefon.

Finální provozní test LED proběhl **tlačítkem START v aplikaci**, oba směry `on → off → on`. Po každé akci aplikace načetla skutečný stav z HA a teprve poté ukázala `Stav potvrzen`. Nezávislý autentizovaný GET potvrdil totéž; původní jas a teplota světla byly zachované. Viz [verification/live-led.json](verification/live-led.json) a screenshoty `02-led-vypnuto.png`, `03-led-zapnuto.png`.

Bazén se v živém HA **nezapínal**. Byl otevřen a zrušen jeho dialog s výchozí volbou NE. Vodárna, termostat ani NAS nebyly zapisované. Neproběhly úpravy HA automatizací, instalace proxy, registrace mobile_app ani upload senzorů hodinek.

## Offline, cache a nastavení

Odpojení bylo vyvolané pouze v dočasné síti simulátoru. Aplikace zachovala původní čísla, označila je šedě `OFFLINE · poslední data` a nespadla. Totéž platilo po ukončení a novém spuštění bez připojení: důkaz perzistentní cache. Po obnovení spojení a ručním obnovení přešla zpět na čerstvá data.

- [17-offline-cache.png](screenshots/17-offline-cache.png): data zachovaná při selhání připojení.
- [18-offline-po-restartu.png](screenshots/18-offline-po-restartu.png): data načtená z cache po restartu.
- [20-online-obnoveno.png](screenshots/20-online-obnoveno.png): obnova po vrácení sítě, HTTP 200.

Nativní `.SET` vytvořený `tools/create_settings.py` byl nezávisle parsovaný a importovaný do simulátoru. S tímto nastavením aplikace úspěšně načítá skutečný HA. Token se nikdy nevkládal do zdrojů nebo PRG. Generátor odmítá výstup uvnitř repozitáře a existující soubor; token přijímá skrytě. Soubor obsahující token není artefaktem vydání.

## Vizuální a výkonnostní kontrola

Screenshoty jsou skutečné obrázky oficiálního simulátoru, bez dokreslení dat. `01-domov.png` je nativní export **240 × 240**. Ostatní obsahují i rámeček zařízení a ukazatel paměti.

Ověřena čitelnost Domova, běžných přepínačů, bazénového potvrzení, read-only vodárny, místností/vlhkosti, BT725, sítě, UPS/NAS, zahrady, experimentálního úlu a nastavení. Texty se měří skutečným Garmin fontem a zkracují s výpustkou; úplný název se čte v detailu, u delšího názvu stránkami UP/DOWN. Patička je zkrácená tak, aby zůstala uvnitř kruhu.

V plné aplikaci byla při procházení sekcí pozorovaná spotřeba přibližně **96–103 KiB** z limitu 768 KiB. Glance má vlastní cache-only renderer; jeho činnost nepoužívá HTTP, časovače ani načítání plné konfigurace. Finální release dokládají `24-release-domov.png` a `23-glance-overeno.png`; Glance využívá přibližně **31,8 KiB** z limitu 64 KiB. Poslední změny po unit testech upravily pouze rozměry Glance a textové indikátory; byly ověřené spuštěním finálního release a screenshoty.

UI je primárně ovládané UP/DOWN/START/BACK, LIGHT zůstává systémové. Standardní MENU událost slouží k ruční obnově. Testovaná navigace nevyžadovala dotyk. Glance se v simulátoru spouští samostatným Launch Mode; přechod z reálného carouselu do aplikace patří mezi fyzické předávací testy.

## Předávací test na zařízení — neprovedeno

Majitel musí ještě ověřit USB instalaci na svém Fénix 7S, zobrazení za běžného světla na fyzickém MIP, systémové LIGHT, přenos přes Garmin Connect na Samsungu S24 FE včetně uzamčeného telefonu, dosah/reálnou odezvu Bluetooth, dostupnost HTTPS mimo domácí Wi-Fi a chování Glance v carouselu.

Tyto kroky nelze zaměňovat za zde provedené simulátorové a serverové testy. HOn pračka, VIGI, Watch History a zapisovatelný BT725/vodárna zůstávají samostatnou druhou fází dle zadání.
