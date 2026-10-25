# Opakovatelné vývojové problémy

## [CX] 2026-10-24 — Windows simulátor bez virtuálního zařízení

- Selhalo: GUI se otevřelo, `monkeydo` se nepřipojil. Opakované spuštění SDK nepomohlo; port 42877 byl otevřený, ale 1234–1238 ne.
- Příčina ověřená příkazem `netsh interface ipv4 show excludedportrange protocol=tcp`: Windows rezervuje 1226–1325. Stejná rezervace zasáhla i zrcadlenou síť běžného WSL.
- Fungovalo: oficiální Linux SDK 9.3.0 v existujícím Ubuntu, dočasný samostatný síťový namespace (`unshare --net`, loopback up). Síť pro HTTPS obstarává uživatelský slirp4netns. Není změněný firewall ani rezervace Windows.
- Příště: nejprve zkontrolovat rezervace. Core simulátoru může po restartu vybrat další port 1235 atd.; `monkeydo` rozsah skenuje, ručně spuštěný `shell` potřebuje skutečný port z `ss -ltnp`. Port 42877 je jiné rozhraní a není náhradou debuggeru.

## [CX] 2026-10-24 — Linux knihovny, fonty a headless zobrazení

- Selhalo: Ubuntu 26.04 neobsahuje staré WebKit 4.0 / libsoup 2.4 knihovny vyžadované Garminem. Samotné SDK bez fontů při grafickém běhu spadlo, přestože konzolové testy běžely.
- Fungovalo: chybějící knihovny z oficiálních Ubuntu balíčků Jammy byly rozbalené lokálně v pracovní složce, nikoli nahrazením systémových knihoven. `LD_LIBRARY_PATH` platí pouze pro procesy SDK. Profil Devices a oficiální Fonts jsou stejné jako v SDK Manageru Windows.
- Pro izolovaný Xvfb bylo nutné `GDK_BACKEND=x11`; jinak GTK upřednostnil zděděný WSLg/Wayland a Xvfb screenshot byl černý. X11 nástroje musí běžet ve stejném síťovém namespace. Nativní Save Screenshot poskytuje 240 × 240; snímek X11 okna zahrnuje i hodinky a údaj paměti.
- Příště: pro Linux preferovat prostředí odpovídající podporovaným knihovnám SDK, nekombinovat symlinky WebKit 4.1 se 4.0. Zkontrolovat také Fonts, ne pouze Devices. Žádné SDK binárky se neupravují ani nedistribuují.

## [CX] 2026-10-24 — Monkey C řetězce a callbacky

- Selhalo: porovnávání řetězců operátorem `==` způsobilo 9 neúspěšných testů z prvních 12.
- Fungovalo: obsah se porovnává přes `equals()`, často s konstantním řetězcem jako příjemcem pro bezpečné porovnání s null. Následné testy prošly.
- Typ callbacku `Communications.makeWebRequest` má SDK deklarovanou omezenou union signaturu. Obecné `Object?` nebylo přímo přijato jako callback. Rozhraní `onConfigResponse` zachovává podpis SDK a předává data validátoru `onConfig`, který bezpečně odmítá i pole, číslo nebo null.
- Příště: používat nativní simulátorové testy, nevyvozovat chování Monkey C z JavaScriptu. Gradual type checker stále upozorňuje na dynamické přístupy do JSON kontejnerů; úspěšný build není tvrzením o Strict typecheck.

## [CX] 2026-10-24 — Nativní SET a snímání UI

- Ve veřejném popisu formátu SET byl prostřední typ chybně uvedený jako `0xB0`; skutečný parser i Garmin používají `0x0B`. Nezávislý round-trip test odhalil a opravil serializer před předáním.
- Hlavičky uvnitř skupiny nového settings JSON nejsou plochý seznam. Generátor sideload nastavení proto čte přímo XML Application Properties a neposílá token přes CLI argument.
- První automatizace nativního GTK Save Screenshot neměla dokončený dialog a narušila následné UI kroky. LED byla bezprostředně vrácena do původního stavu. Finální ověřený cyklus je samostatně zaznamenaný v `verification/live-led.json`: on/off/on se zachováním jasu a teploty světla. Zachytávání celého simulátorového okna přes X11 nemění fokus ani stav aplikace.
