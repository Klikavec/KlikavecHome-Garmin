param(
    [string]$Sdk = (Get-Content "$env:APPDATA\Garmin\ConnectIQ\current-sdk.cfg" -Raw).Trim(),
    [string]$JavaHome = $env:JAVA_HOME,
    [string]$Key = "$PSScriptRoot\..\developer_key",
    [switch]$Tests,
    [switch]$Release
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
if($JavaHome) {$env:PATH=(Join-Path $JavaHome 'bin')+';'+$env:PATH}
if(!(Get-Command java -ErrorAction SilentlyContinue)){throw 'Nastav JAVA_HOME na JDK 17 nebo novější.'}
if(!(Test-Path (Join-Path $Sdk 'bin/monkeybrains.jar'))){throw 'Neplatná cesta k SDK.'}
if(!(Test-Path "$env:APPDATA/Garmin/ConnectIQ/Devices/fenix7s/compiler.json")){throw 'Stáhni profil fenix7s v Garmin SDK Manageru.'}
if(!(Test-Path $Key)){throw 'Chybí developer_key. Viz INSTALL-WINDOWS.md.'}
Push-Location $root
try {
    New-Item -ItemType Directory -Force bin | Out-Null
    if(!(Test-Path source/ClientId.mc)){Copy-Item source/ClientId.mc.unpopulated source/ClientId.mc}
    $argsList=@('-f','klikavec.jungle','-d','fenix7s','-y',$Key,'-o','bin/KlikavecHome.prg','-w')
    if($Tests){$argsList+='-t'}
    if($Release){$argsList+='-r'}
    & (Join-Path $Sdk 'bin/monkeyc.bat') @argsList
    if($LASTEXITCODE -ne 0){throw "Monkey C build selhal: $LASTEXITCODE"}
} finally {Pop-Location}
