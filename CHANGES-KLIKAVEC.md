# Změny Klikavec Home

## 25. 10. 2026 — oprava odpovědi přes Garmin Connect

- Po prvním testu fyzických hodinek odstraněn nesoulad očekávaného JSON s `text/plain` odpovědí HA template. Simulátor původní kombinaci přijal, fyzický přenos hlásil chybnou odpověď JSON.
- Šablony se čtou jako validovaný text KH1; konfigurace zůstává JSON. Autorizace, allowlist a serverové potvrzení akcí se nemění.
- Přidané regresní testy textové odpovědi, české jednotky, prázdné jednotky, HTML, chybných čísel, přetečení, řádků navíc a cizích ID.

## První MVP

- Nový vstupní bod, UUID a cílený build `fenix7s`; původní aplikace a MIT licence zachované.
- Šest českých sekcí, stavový přehled, oblíbené akce, detaily vlhkostí, IT semafor a zahrada.
- Komponenty `StatusIndicator`, `MetricTile`, `ActionTile`, `ToggleRow`, `SectionHeader`, `ConfirmationDialog`.
- Ovládání pěti tlačítky s doplňkovým dotykem; úplné dlouhé názvy v detailu a kompaktní patička uvnitř kruhu.
- Read-only BT725, vodárna a NAS; bazén vyžaduje potvrzení s výchozí volbou NE.
- Zachovaný upstream Bearer/JSON transport; kompaktní čtení sekce, ruční obnova, žádné trvalé pollování.
- Ověření stavu po každém zápisu, blokování druhého zápisu během čekání a zákaz odhadnutého úspěchu.
- Offline/stale/unknown/invalid stavy, časovaná cache po entitách, ochrana proti starým callbackům po změně nastavení.
- Konfigurace mimo Monkey C, vlastní schema, validace na PC i hodinkách a soukromé nativní nastavení pro sideload.
- Cache-only Glance, testy v oficiálním simulátoru a dokumentované fyzické předávací testy.

Upstream soubory se mění pouze případným doplněním odkazu na novou dokumentaci v README a ignorováním soukromých vývojových souborů. Původní transport, Settings, licence, příklady a build zůstávají dostupné.
