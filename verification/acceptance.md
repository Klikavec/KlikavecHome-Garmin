# Akceptační audit — 25. 10. 2026

| Požadavek | Výsledek / důkaz |
|---|---|
| Fork, historie a MIT | Klikavec/KlikavecHome-Garmin; změny navazují na upstream 35d7adf, LICENSE beze změny. |
| Skutečný PRG pro Fénix 7S | Release SDK 9.3.0, produkt fenix7s; tentýž soubor spuštěn v oficiálním simulátoru. |
| Živá data | 49 existujících entit, audit ha-audit.json; načtené sekce na screenshotech. |
| LED oběma směry a readback | START v aplikaci, on/off/on, nezávislý GET; live-led.json a screenshoty 02/03. |
| Bezpečné zápisy | Šest pevných ID, vodárna/BT725/NAS read-only; bazén vyžaduje potvrzení NE. Živě zapisována jen LED. |
| Šest sekcí a komponenty | Domov, Ovládání, Klima, Stav domu, Zahrada, Nastavení; source/KlikavecComponents.mc. |
| Tlačítka a čitelnost | Navigace bez dotyku; UP/DOWN/START/BACK, systémové LIGHT; reálné screenshoty 240px profilu v screenshots/. |
| Offline, chyby a cache | Nativní odpojení a restart se zachovanými údaji, následná obnova; screenshoty 17/18/20. 19 unit testů v unit-tests.log. |
| Konfigurace | JSON Schema, příklad, validátor i runtime validace; neplatný JSON zachová platnou konfiguraci. |
| HTTPS, tajné údaje, výkon | Živě ověřený Cloudflared HTTPS; soukromé nativní SET mimo repo. Bez pollování; přibližně 102 KiB aplikace / 32 KiB Glance. |
| Glance | Cache-only renderer; finální screenshot 23-glance-overeno.png. |
| Dokumentace a instalace | README-KLIKAVEC.md, INSTALL-WINDOWS.md, ARCHITECTURE-KLIKAVEC.md, CHANGES-KLIKAVEC.md, TESTING.md. |

Závěrečná kontrola distribuovaných souborů a Git indexu porovnává obsah se skutečným lokálním tokenem a soukromým podpisovým klíčem; jejich obsah se nevypisuje. Výstupní SHA256SUMS.txt váže balíček na přesný PRG.

Fyzické hodinky, Samsung/Garmin Connect, Bluetooth, reálný MIP a přechod z Glance carouselu nebyly dostupné k testu. Jsou výslovným předávacím testem v TESTING.md, nikoli tvrzeným úspěchem. SDK monkeydo vrací exit 1 přes 19 PASS; podrobnosti v TESTING.md. hOn, VIGI, Watch History a zapisovatelný termostat/vodárna jsou odložená druhá fáze podle zadání. Serverový omezený proxy endpoint nebyl nasazen; klientský allowlist neomezuje práva HA tokenu na serveru.
