# Handoff — Klikavec Home Garmin

## Aktuální stav
[CX] Majitel potvrdil fungující čtení dat verze r2 na fyzických hodinkách přes Samsung. Z jeho fotografií opravena překrývající ikona Zahrady: drawEllipse bere střed a poloměry, nikoli bounding box. Release r3 má pouze tuto vizuální změnu; soukromé nastavení se nemění. Při vzniku r3 hodinky nejsou připojené, nahrání čeká na nové USB připojení.
[CX] Aktualizace 25. 10.: první fyzický test majitele hlásil timeout a následně chybný JSON. Opraven MIME nesoulad HA text/plain versus JSON očekávaný Garmin Connect; nový KlikavecService a validovaný KH1 text. 21/21 nativních testů, živá odpověď a release v simulátoru ověřené. Opravený release nahrán do připojeného fenix 7S a zpětně ověřen SHA256; token/SET beze změny. Čeká se na potvrzení majitele po odpojení a spuštění přes Samsung.
[CX] Dokončené české MVP nad upstream GarminHomeAssistant, vlastní `klikavec.jungle` a `fenix7s` manifest. Release se sestavuje, 19 nativních testů prošlo a živé HA/LED byly ověřené v oficiálním simulátoru. Offline po restartu, obnova spojení, soukromé SET a cache-only Glance ověřené. Instalační balíček je v outputs/KlikavecHome-fenix7s.zip nadřazeného pracovního adresáře. Fyzické hodinky a Samsung zbývají k předávacímu testu podle TESTING.md.

## Naposledy dokončeno
- [CX] 2026-10-25 — r3: správné souřadnice listu Zahrady, sestavení pro fenix7s a vizuální kontrola v nativním simulátoru. Nové výstupy KlikavecHome-fenix7s-r3, historické balíčky zachované. R2 čtení skutečných dat fyzicky potvrdil majitel.
- [CX] 2026-10-25 — Oprava text/plain template transportu, 21 PASS, živý Domov HTTP 200/213 ms a screenshot 25-plain-response-domov.png. Release 96428 B nahrán přes MTP; shodný hash zpětně načteného PRG. Nové výstupy mají příponu r2; původní balíček se zachovává jako historický.
- [CX] 2026-10-25 — V outputs/Nastavit-token.cmd a .ps1 je lokalni launcher pro majitele: skryty vstup tokenu, existujici create_settings.py, HTTPS URL predvyplnena, soukromy SET ve work/user-watch-settings, upload pres MTP do SETTINGS. Odmita prepsat existujici nastaveni. Overena syntaxe, nikoli provedeni s tokenem; to spousti majitel. Neni soucasti verejneho repozitare ani ZIP vydani.
- [CX] 2026-10-25 — Na výslovný pokyn majitele nahrán release KlikavecHome.prg přes MTP do fyzického fenix 7S, Internal Storage/GARMIN/APPS. Zpětně stažený soubor má shodný SHA256 s release. Token ani SET se do hodinek nekopírovaly; majitel chce token zadat sám. Spuštění na hodinkách a telefonní přenos zatím neověřené. MTP Shell skrývá příponu v Name a Size vrací 0; skutečnou velikost poskytuje ExtendedProperty System.Size, jméno staženého souboru obsahuje .prg.
- [CX] 2026-10-25 — Finální release a nativní screenshoty Domov/Glance; přibližně 102/32 KiB paměti. Akceptační audit v verification/acceptance.md, kontrola tajných údajů a ZIP s PRG, návody, konfigurací a důkazy testů. Zdrojové změny v origin/main existujícího forku, s celou upstream historií.
- [CX] 2026-10-24 — Fork Klikavec/KlikavecHome-Garmin s celou historií a MIT licencí; šest sekcí a ověřené čtení 49 existujících HA entit.
- [CX] 2026-10-24 — 19/19 Run No Evil testů; LED on/off/on přes tlačítka simulátoru, readback a obnova původního jasu/teploty. `verification/live-led.json`.
- [CX] 2026-10-24 — README-KLIKAVEC, instalační návod, architektura, změny, schema, příklad, nástroje pro build/validaci a soukromé nativní SET.

## Příští priority
1. Majitel: USB instalace do fyzického Fénix 7S a test Samsung/Garmin Connect, zamčený telefon, Bluetooth, MIP a Glance carousel.
2. Případné CI: vyřešit rozdíl SDK monkeydo exit 1 versus 19 PASS; neskrývat procesní selhání.
3. Druhá fáze jen na nové zadání: hOn/VIGI/Watch History, serverová proxy; vodárna až po samostatném auditu automatizací.

## Kontext pro druhého agenta
- Repozitář: `work/KlikavecHome-Garmin`, větev `klikavec-home`; origin Klikavec/KlikavecHome-Garmin, upstream house-of-abbey/GarminHomeAssistant. Základ 35d7adf.
- Windows SDK Manager aktivuje SDK 9.3.0, profil fenix7s/Fonts stažené. Přenosný JDK17: sousední `work/toolchain/java/jdk-17.0.20.1+1`. Oficiální VS Code garmin.monkey-c 1.1.3 je nainstalovaný.
- Windows rezervuje porty debuggeru. Linux simulátor běží v samostatném síťovém namespace; PID správce v sousedním `work/ciq-netns.pid`. Síť obstarává slirp4netns. Všechny příkazy native shell / xdotool / capture musí přes `wsl -d Ubuntu -- nsenter --target <PID> --net -- ...`. Žádné globální změny sítě Windows.
- Pracovní shell skripty `work/linux-run.sh`, `linux-ui.sh`, `linux-shot.sh`, `linux-shell.sh` nejsou součástí produktu. Native shell nyní port 1235, monkeydo ho hledá automaticky. Xvfb :99, autorita se hledá podle živého souboru.
- Token je pouze v soukromých souborech sousedního work/ mimo repo; nikdy nevypisovat jejich obsah ani ho commitovat. HA endpoint a User-Agent byly ověřené. Soubor SET s tokenem ani developer_key nejsou výstupy.
- Aktuální runtime capture bez zásahu do UI: linux-shot.sh jmeno uloží skutečné okno simulátoru do screenshots/jmeno.png (soubor nesmí existovat). 01-domov.png je nativní 240x240 export; další screenshoty obsahují chrome a paměť.
- Cache po entitách, žádné pollování/registrace mobile_app. Vodárna, BT725 a NAS pouze čtení; bazén povinné potvrzení a zákaz favorite. Další HA zápisy kromě LED se netestují.
- Fyzické hodinky/Samsung nejsou dostupné k automatizovanému testu; dokumentovat odděleně, neoznačovat jako provedené.
- Viz ERRORS.md pro opakované problémy a jejich ověřené řešení.
