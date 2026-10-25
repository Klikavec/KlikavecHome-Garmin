# Windows → Fénix 7S

## Připravený instalační soubor

1. Připoj Fénix 7S USB datovým kabelem a otevři úložiště hodinek.
2. Zkopíruj **`KlikavecHome.prg`** do `GARMIN/APPS/`. Název souboru zachovej.
3. Připrav nativní nastavení aplikace podle následující části a zkopíruj `KLIKAVECHOME.SET` do `GARMIN/APPS/SETTINGS/`.
4. Bezpečně odpoj hodinky. V seznamu aplikací spusť **Klikavec Home**.
5. Telefon musí být spárovaný, Garmin Connect musí smět běžet na pozadí a telefon musí mít přístup k zadanému HTTPS endpointu HA. Na Samsungu zkontroluj omezení baterie pro Garmin Connect, pokud se požadavky při zamčeném telefonu zastavují.

Pokud jsou hodinky připojené v režimu MTP, kopíruj soubory přes Průzkumníka. Skript nemusí umět zapisovat přímo do MTP zařízení. Aplikace má vlastní UUID a nenahrazuje původní GarminHomeAssistant. Existující aplikaci ani její data nemaž.

## Token přes nativní nastavení

Pro sideload není nutné publikovat aplikaci do Connect IQ Store. Python 3.10+ umí vytvořit nativní `.SET` soubor offline. Ze zdrojového repozitáře spusť:

```powershell
python tools/create_settings.py --api-url https://HA_HOST/api --output C:\SOUKROMA_SLOZKA\KLIKAVECHOME.SET
```

Složka musí existovat a být **mimo repozitář**. Skript token vyžádá skrytým vstupem, nikam ho nevypíše a nepřepíše existující soubor. Token se nezadává v argumentu příkazové řádky. Připrav si dlouhodobý HA token vyhrazeného uživatele v jeho profilu; nevkládej ho do JSON konfigurace ani Monkey C zdrojů.

Skript nastaví také `User-Agent: KlikavecHome-Garmin/1.0`. Během ověření byl tento identifikovaný klient přijat Cloudflare, zatímco výchozí Python User-Agent dostával chybu 1010. HTTPS ověřování se nevypíná. URL musí končit `/api`, bez koncového lomítka. URL osobního HA zjisti ze svého nastavení; veřejný příklad v tomto návodu záměrně neobsahuje adresu domácnosti.

Soubor zkopíruj do hodinek. Pokud později nativní nastavení aplikace otevřeš v Garmin Connect/Connect IQ nebo v oficiálním Application Settings Editoru, stejné vlastnosti jsou `HA přístupový token`, `Home Assistant HTTPS API` a volitelná soukromá konfigurace. Možnost mobilního editoru u sideloadu závisí na Garminu; `.SET` poskytuje cestu i bez jeho dostupnosti.

`.SET` obsahuje nešifrovaný token. Ulož ho soukromě a nesdílej ani necommituj. Ztracený token odvolej v HA. Při změně nastavení aplikace zahodí staré probíhající callbacky a znovu načte stav; nebude provádět automatické zápisy.

## Sestavení ze zdrojů

Ověřeno s **Connect IQ SDK 9.3.0**, JDK 17 a oficiálním profilem **`fenix7s`**. Sapphire Solar není samostatný produktový ID; `fenix7spro` je jiné zařízení.

1. Nainstaluj JDK 17+ a [Garmin SDK Manager](https://developer.garmin.com/connect-iq/sdk/).
2. V SDK Manageru se přihlas a stáhni aktuální SDK, zařízení fēnix 7S a jeho závislosti/fonty. Nastav aktivní SDK.
3. Ve VS Code lze používat oficiální rozšíření Monkey C. Pro níže uvedený PowerShell build stačí SDK a Java.
4. Jednou vygeneruj soukromý podpisový klíč. V PowerShellu 7:

```powershell
if (Test-Path developer_key) { throw 'Klíč už existuje; nepřepisuj ho.' }
$signingKey = [System.Security.Cryptography.RSA]::Create(4096)
[IO.File]::WriteAllBytes((Join-Path $PWD 'developer_key'), $signingKey.ExportPkcs8PrivateKey())
$signingKey.Dispose()
```

Klíč je ignorovaný Gitem; zálohuj ho soukromě. Alternativa s OpenSSL: `openssl genrsa -out developer_key.pem 4096`, potom `openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key -nocrypt`. Oba soubory jsou tajné.

```powershell
$env:JAVA_HOME = 'C:\CESTA\K\JDK17'
python -m pip install jsonschema
python tools/validate_config.py
python tools/make_default_config.py
.\tools\build.ps1 -Release
```

Výstup je `bin/KlikavecHome.prg`. `-Sdk C:\CESTA\K\SDK` lze použít místo automatické cesty z Garmin SDK Manageru. Testovací build vytvoří `.\tools\build.ps1 -Tests`; v již spuštěném simulátoru spusť `monkeydo.bat bin\KlikavecHome.prg fenix7s /t`. Testovací PRG nahraď před instalací release buildem.

## Simulátor

Spusť `connectiq.bat`, potom `monkeydo.bat bin\KlikavecHome.prg fenix7s`. V **Settings → Glance Launch Mode → Launch in Normal Mode** spustíš celou aplikaci; druhá volba ověří Glance. Importuj nastavení oficiálním Application Settings Editorem nebo použij svůj `.SET` v simulovaném `GARMIN/APPS/SETTINGS/`.

Na tomto PC Windows rezervoval rozsah TCP **1226–1325**, tedy i Garmin porty **1234–1238**. Diagnostika pouze ke čtení:

```powershell
netsh interface ipv4 show excludedportrange protocol=tcp
```

Pokud GUI simulátoru otevře pouze šedé okno a `monkeydo` hlásí `Unable to connect to simulator`, porovnej výpis s tímto rozsahem. Neměň kvůli tomu firewall nebo bezpečnost Windows. Při vývoji byl použit oficiální Linux simulátor stejné verze v existujícím Ubuntu/WSL, s odděleným dočasným síťovým namespace; globální síť Windows zůstala beze změny. Podrobnosti jsou v `ERRORS.md`.

## Ověření na fyzických hodinkách

Otevři Domov a porovnej údaje s HA. Na bezpečném LED pásku ověř vypnutí i zapnutí a hlášení `Stav potvrzen`. Vyzkoušej UP/DOWN/START/BACK bez dotyku a LIGHT jako systémové tlačítko. Při odpojeném telefonu musí zůstat poslední údaje označené offline a přepínače se nesmějí tvářit jako úspěšné. U bazénu pouze zruš potvrzení; vodárna ani BT725 nesmějí nabídnout zápis.

Tyto fyzické kroky jsou předávací test pro majitele; provedené simulátorové a serverové testy jsou samostatně uvedené v `TESTING.md`.
