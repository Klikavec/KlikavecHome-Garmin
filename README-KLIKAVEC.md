# Klikavec Home

Česká aplikace pro **Garmin Fénix 7S Sapphire Solar**, profil `fenix7s`, kulatý MIP displej 240 × 240. Vychází z [GarminHomeAssistant](https://github.com/house-of-abbey/GarminHomeAssistant); zachovává historii, MIT licenci a jeho autorizovaný transport. Nový vstupní bod a uživatelské rozhraní jsou v souborech `source/Klikavec*.mc`. Původní aplikace má nadále vlastní `monkey.jungle` a manifest.

## Instalace

Viz [Windows, sestavení, nastavení a instalace do Garminu](INSTALL-WINDOWS.md). Sestavuj **`klikavec.jungle`**, nikoli původní `monkey.jungle`. Instalační aplikace se jmenuje `KlikavecHome.prg`; token do ní není zabudovaný. Pro sideload lze vytvořit soukromé nativní nastavení `.SET` pomocí `tools/create_settings.py`.

## Ovládání

| Tlačítko | Funkce |
|---|---|
| UP / DOWN | Sekce, položky, volba potvrzení; v dlouhém detailu stránky názvu |
| START / STOP | Otevření sekce, detail nebo přepnutí zařízení |
| BACK / LAP | Návrat; na hlavním přehledu ukončení |
| LIGHT | Standardní systémové ovládání Garminu |
| MENU (standardní dlouhé UP) | Ruční obnova aktuální obrazovky |

Dotyk a svislé gesto jsou doplňkové. Dlouhé stisky nezpracovává vlastní časovač. Domov po START vybere první oblíbenou akci; dalším START ji provedeš. Potvrzení citlivých akcí začíná volbou **NE**; BACK ho zruší. Detail z pokročilého přehledu nahrazuje tuto stránku, aby zásobník obsahu nepřekročil tři úrovně.

## Šest sekcí

- **Domov:** venkovní teplota, obývák, internet, UPS a topení; oblíbené LED/zásuvka a odkaz na klima.
- **Ovládání:** pět běžných přepínačů. Oddělené pokročilé položky obsahují bazén s povinným potvrzením, příkony a vodárnu pouze ke čtení.
- **Klima:** šest místností, vlhkosti v detailu a údaje BT725. Termostat nemá ovládání teploty.
- **Stav domu:** síť, UPS a NAS. Restart ani vypnutí NASu nejsou dostupné.
- **Zahrada:** počasí, bazén, půda a experimentální horní čidla úlu. Neaktuální či neplatná experimentální čísla se nezobrazují jako měření.
- **Nastavení:** obnova dat, volitelné načtení soukromého JSON a nápověda. Přístupový token a HTTPS URL se zadávají nativním nastavením aplikace.

## Data a bezpečnost

Po otevření sekce se načtou pouze její entity jedním kompaktním požadavkem. Neprobíhá pravidelné pollování, registrace mobilní aplikace v HA ani odesílání senzorů hodinek. Glance čte pouze malý lokální souhrn; síť nepoužívá.

Akce používá explicitní `turn_on` / `turn_off`. Úspěch se zobrazí teprve po HTTP 200 **a následném ověření skutečného stavu**. Při chybě se zápis automaticky neopakuje. Zastaralá, nedostupná či neznámá hodnota přepínače znemožní zápis. Další stisk během požadavku nevytváří další zápis.

Cache obsahuje stav, stáří údaje a čas načtení, po jednotlivých entitách pod limitem 8 KB na hodnotu. Po spuštění je cache vždy označená jako offline do nového úspěšného načtení. Po pěti minutách od načtení jsou data neaktuální; vybraná čidla mají navíc limit `maxAge` zdrojového hlášení. Stabilní přepínače a stavové senzory se nepovažují za neaktuální jen proto, že se dlouho nezměnily.

Barvy: zelená OK/zapnuto, oranžová varování/topení, červená chyba, modrá informace/navigace, šedá neznámé nebo neaktuální údaje. Stav dostupnosti se nezaměňuje za skutečnou poruchu.

Token se ukládá v nativních Garmin Application Properties. Nativní `.SET` není šifrovaný trezor; zacházej s ním jako s heslem. Není součástí zdrojů, příkladů, screenshotů ani instalačního PRG. HTTPS certifikát se ověřuje standardní cestou, bez výjimek.

## Konfigurace

[Příklad](examples/klikavec-home.json) a [JSON Schema](klikavec.schema.json) rozšiřují upstream strukturu `title` / `items` / `group`. Pořadí sekcí určuje pole `items`, `visible: false` je skryje. Lze upravit české názvy, vazby čidel, ikony sekcí, čtyři barvy, limity stáří/hodnot, oblíbené přepínače (`favorite`) a běžná potvrzení (`confirm`). Pro bazén zůstává potvrzení povinné i při `confirm: false`; vodárna a NAS nemohou být přepínačem. Pokročilé bazénové čerpadlo nelze přidat mezi oblíbené.

Zapisovatelné entity mají pevný allowlist šesti ověřených ID v `KlikavecConfig.writable()`. Vazby čidel jsou konfigurovatelné; přidání dosud neověřeného zapisovatelného zařízení vyžaduje rozšíření allowlistu a ověření jeho bezpečnosti. Konfigurace nemůže přidat libovolnou HA službu.

```powershell
python -m pip install jsonschema
python tools/validate_config.py
python tools/make_default_config.py
```

Poslední příkaz překopíruje příklad do kompilovaného Garmin JSON resource. Potom aplikaci znovu sestav. To je výchozí způsob konfigurace bez veřejného hostování. Nástroj nemění existující příklad podle svých výchozích hodnot.

Volitelná URL konfigurace musí poskytovat přímo JSON na **stejném HTTPS hostu jako HA**, za autentizací. Token se jinému hostu neposílá. `/local/` v běžném Home Assistantu je veřejný: osobní konfiguraci tam neumisťuj. Soukromý endpoint může později dodat HACS konfigurátor nebo vlastní proxy. Chybný JSON zachová předchozí platnou konfiguraci.

Limity: nejvýše šest sekcí, 20 položek v jednom poli, 60 unikátních entit a konzervativní limit velikosti každé sekce. Vestavěný příklad má 49 entit včetně vlhkostí. Názvy mají nejvýše 64 znaků; zkrácený název lze celý přečíst v detailu, u velmi dlouhého názvu pomocí UP/DOWN.

## Ověření a další fáze

Konkrétní výsledky a omezení jsou v [TESTING.md](TESTING.md), technické rozhodnutí v [ARCHITECTURE-KLIKAVEC.md](ARCHITECTURE-KLIKAVEC.md), změny v [CHANGES-KLIKAVEC.md](CHANGES-KLIKAVEC.md). Screenshoty jsou skutečné výstupy Garmin simulátoru, nikoli designové makety.

Fyzické Fénix 7S a přenos přes Samsung/Garmin Connect musí ještě ověřit majitel. Pračka hOn, detekce osob VIGI a Watch History nejsou součástí MVP. Nejsou přidané na úkor jeho funkčnosti. BT725 zůstává ke čtení; ruční vodárna vyžaduje samostatný audit automatizací.

## Licence

Původní [MIT LICENSE](LICENSE) zůstává beze změny; upstream autorství je zachováno ve zdrojích a Git historii. Rozšíření Klikavec Home je rovněž MIT. Nejde o aplikaci vydanou nebo certifikovanou Garminem.
