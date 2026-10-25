# Handoff — Klikavec Home Garmin

## Aktuální stav
[CX] Dokončené české MVP nad upstream GarminHomeAssistant, vlastní `klikavec.jungle` a `fenix7s` manifest. Release se sestavuje, 19 nativních testů prošlo a živé HA/LED byly ověřené v oficiálním simulátoru. Offline po restartu, obnova spojení, soukromé SET a cache-only Glance ověřené. Instalační balíček je v outputs/KlikavecHome-fenix7s.zip nadřazeného pracovního adresáře. Fyzické hodinky a Samsung zbývají k předávacímu testu podle TESTING.md.

## Naposledy dokončeno
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
