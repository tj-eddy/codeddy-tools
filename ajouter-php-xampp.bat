<# :
@echo off
title Ajout de versions PHP dans XAMPP
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content -LiteralPath '%~f0') -join [char]10)"
echo.
pause
exit /b
#>

# ============================================================
#  Ajoute des versions PHP (NTS x64 officielles windows.php.net) dans XAMPP :
#  C:\xampp\phpXY + php.ini dev (extensions PrestaShop, OPcache) + raccourci phpXY
#  Utilisables par vhost via mod_fcgid (creer-vhost-xampp.bat)
#  Non interactif : set PHPADD_VERSIONS=7.3 8.2 avant de lancer le script
# ============================================================

function Ok($m) { Write-Host "[OK] $m" -ForegroundColor Green }
function Info($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m) { Write-Host "[!] $m" -ForegroundColor Yellow }
function Fail($m) { Write-Host "[ERREUR] $m" -ForegroundColor Red }

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'
$X = 'C:\xampp'
$Xf = $X -replace '\\', '/'
$all = '7.0', '7.1', '7.2', '7.3', '7.4', '8.0', '8.1', '8.2', '8.3', '8.4', '8.5'

$mainVer = & "$X\php\php.exe" -r 'echo PHP_MAJOR_VERSION,chr(46),PHP_MINOR_VERSION;'
$missing = $all | Where-Object { $_ -ne $mainVer -and -not (Test-Path ("$X\php" + ($_ -replace '\.', '') + '\php-cgi.exe')) }
Info "PHP par defaut de XAMPP : $mainVer"
Info ("Deja installees : " + ((Get-ChildItem $X -Directory -Filter 'php?*' | Where-Object { Test-Path "$($_.FullName)\php-cgi.exe" } | ForEach-Object Name) -join ', '))

$wanted = $env:PHPADD_VERSIONS
if (-not $wanted) {
    $r = Read-Host "Versions a ajouter (ex: 7.3 8.2) [$($missing -join ' ')]"
    $wanted = if ([string]::IsNullOrWhiteSpace($r)) { $missing -join ' ' } else { $r }
}
$versions = $wanted -split '[\s,;]+' | Where-Object { $_ -match '^\d\.\d$' }
if (-not $versions) { Info 'Rien a installer'; return }

Info 'Recuperation de la liste des builds windows.php.net...'
$pages = ''
foreach ($u in 'https://windows.php.net/downloads/releases/', 'https://windows.php.net/downloads/releases/archives/') {
    $pages += (Invoke-WebRequest $u -UseBasicParsing -TimeoutSec 120).Content
}
$sums = (Invoke-WebRequest 'https://windows.php.net/downloads/releases/sha256sum.txt' -UseBasicParsing -TimeoutSec 120).Content
$dl = Join-Path $env:TEMP 'xampp-php-dl'
New-Item -ItemType Directory -Force $dl | Out-Null

foreach ($v in $versions) {
    $dir = "$X\php" + ($v -replace '\.', '')
    $name = Split-Path $dir -Leaf
    Write-Host ""
    Write-Host "===== PHP $v ($dir) =====" -ForegroundColor White
    if (Test-Path "$dir\php-cgi.exe") { Info 'Deja installe, ignore'; continue }

    # Derniere version du patch (vc14 = 7.0/7.1, vc15 = 7.2-7.4, vs16 = 8.0-8.3, vs17 = 8.4+)
    $best = [regex]::Matches($pages, "(?i)php-$([regex]::Escape($v))\.(\d+)-nts-Win32-(vc14|vc15|vs16|vs17)-x64\.zip") |
        Sort-Object { [int]$_.Groups[1].Value } | Select-Object -Last 1
    if (-not $best) { Fail "Aucun build NTS x64 trouve pour PHP $v"; continue }
    $file = $best.Value
    $zip = Join-Path $dl $file
    $ok = $false
    foreach ($base in 'https://windows.php.net/downloads/releases/', 'https://windows.php.net/downloads/releases/archives/') {
        try { Invoke-WebRequest ($base + $file) -OutFile $zip -UseBasicParsing -TimeoutSec 600; $ok = $true; break } catch { }
    }
    if (-not $ok) { Fail "Telechargement impossible : $file"; continue }

    $exp = ([regex]::Match($sums, "(?i)([0-9a-f]{64})\s+\*?$([regex]::Escape($file))")).Groups[1].Value
    $got = (Get-FileHash $zip -Algorithm SHA256).Hash
    if (-not $exp) { Warn "Empreinte SHA-256 non publiee pour $file (non verifiee)" }
    elseif ($exp -ne $got) { Fail "Empreinte SHA-256 incorrecte pour $file : fichier ignore"; Remove-Item $zip; continue }
    else { Ok "$file (SHA-256 verifie)" }

    New-Item -ItemType Directory -Force $dir | Out-Null
    tar -xf $zip -C $dir
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path "$dir\php-cgi.exe")) { Fail 'Decompression echouee'; continue }
    Remove-Item $zip

    # ---------- php.ini ----------
    Copy-Item "$dir\php.ini-development" "$dir\php.ini"
    $lines = New-Object 'System.Collections.Generic.List[string]'
    $lines.AddRange([string[]]([IO.File]::ReadAllText("$dir\php.ini") -split "\r?\n"))
    function Set-Line($pattern, $value) {
        for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match $pattern) { $lines[$i] = $value; return } }
        $lines.Add($value)
    }
    function Set-Ini($key, $value) {
        $k = [regex]::Escape($key)
        for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match "^\s*$k\s*=") { $lines[$i] = "$key=$value"; return } }
        Set-Line "^\s*;\s*$k\s*=" "$key=$value"
    }
    # Extensions : uniquement celles livrees en DLL (zip/opcache sont integrees dans certaines versions)
    # mbstring avant exif (dependance en PHP 7)
    foreach ($e in 'curl', 'fileinfo', 'gd2', 'gd', 'intl', 'mbstring', 'exif', 'mysqli', 'openssl', 'pdo_mysql', 'soap', 'sodium', 'zip') {
        if (-not (Test-Path "$dir\ext\php_$e.dll")) { continue }
        Set-Line "^\s*;?\s*extension\s*=\s*`"?(php_)?$e(\.dll)?`"?\s*$" "extension=php_$e.dll"
    }
    if (Test-Path "$dir\ext\php_opcache.dll") { Set-Line '^\s*;?\s*zend_extension\s*=\s*"?(php_)?opcache(\.dll)?"?\s*$' 'zend_extension=php_opcache.dll' }
    $set = [ordered]@{
        'extension_dir' = "`"$Xf/$name/ext`""; 'date.timezone' = 'Europe/Paris'
        'memory_limit' = '512M'; 'max_execution_time' = '300'; 'max_input_vars' = '10000'
        'post_max_size' = '64M'; 'upload_max_filesize' = '64M'
        'realpath_cache_size' = '5M'; 'realpath_cache_ttl' = '600'
        'session.save_path' = "`"$X\tmp`""; 'upload_tmp_dir' = "`"$X\tmp`""
        'curl.cainfo' = "`"$X\apache\bin\curl-ca-bundle.crt`""; 'openssl.cafile' = "`"$X\apache\bin\curl-ca-bundle.crt`""
        'opcache.enable' = '1'; 'opcache.enable_cli' = '0'; 'opcache.memory_consumption' = '256'
        'opcache.interned_strings_buffer' = '32'; 'opcache.max_accelerated_files' = '100000'
        'opcache.validate_timestamps' = '1'; 'opcache.revalidate_freq' = '0'
    }
    foreach ($k in $set.Keys) { Set-Ini $k $set[$k] }
    [IO.File]::WriteAllText("$dir\php.ini", ($lines -join "`r`n"), (New-Object Text.UTF8Encoding $false))

    # ---------- Verification ----------
    $mods = & "$dir\php-cgi.exe" -c "$dir\php.ini" -m 2>&1 | ForEach-Object { "$_" }
    $warn = $mods | Where-Object { $_ -match 'Warning|Unable to load' } | Select-Object -Unique
    $need = 'curl', 'gd', 'intl', 'mbstring', 'openssl', 'pdo_mysql', 'zip', 'Zend OPcache'
    $miss = $need | Where-Object { $mods -notcontains $_ }
    $ver = (& "$dir\php.exe" -c "$dir\php.ini" -v 2>$null | Select-Object -First 1)
    if ($warn) { $warn | ForEach-Object { Warn $_ } }
    if ($miss) { Warn ("Extensions manquantes : " + ($miss -join ', ')) } else { Ok "$ver" }

    # Raccourci en ligne de commande : php73 -v, php73 bin/console ...
    [IO.File]::WriteAllText("$X\php\$name.bat", "@`"$dir\php.exe`" %*`r`n", [Text.Encoding]::ASCII)
    Ok "Commande $name disponible"
}

Write-Host ""
Info 'Choisis la version par vhost avec creer-vhost-xampp.bat (question "Version PHP")'
