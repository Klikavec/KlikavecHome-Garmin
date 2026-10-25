# Projektová rozhodnutí

## [CX] 2026-10-25 — Klikavec Home MVP

- Rozhodnutí: vlastní vstupní bod a manifest, zachovaný upstream transport/Settings, historie a MIT licence. Důvod: funkční Garmin aplikace s novým UI bez přepsání již fungující komunikace.
- Odmítnuté alternativy: kompletní přepis, veřejná osobní konfigurace, HTTP výjimky a trvalé pollování. Konfigurace je oddělený Garmin JSON resource se schematem; soukromý vzdálený endpoint je volitelný.
- Bezpečnost: pevný allowlist ověřených přepínačů, potvrzený serverový POST a následný readback, žádný automatický retry zápisu. Vodárna/BT725/NAS pouze čtení, bazén s povinným potvrzením. Klientský allowlist není serverové omezení samotného tokenu; samostatná proxy zatím není nasazená.
- Nativní token patří do Application Properties / soukromého SET, nikdy do zdrojů, JSON příkladu, PRG nebo Git historie. Podpisový klíč se uchovává soukromě pro další buildy.
- Windows má rezervované porty CIQ. Ověření proběhlo v oficiálním simulátoru stejné verze v dočasném izolovaném WSL síťovém namespace, bez změny sítě Windows. Viz ERRORS.md.
- Fyzické hodinky/Android nebyly automatizovaně dostupné. Předávací hardware test je výslovně oddělený od ověřených HA a simulátorových výsledků.
