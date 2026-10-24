<# :
@echo off
title Installation PrestaShop en ligne de commande (XAMPP)
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content -LiteralPath '%~f0') -join [char]10)"
echo.
pause
exit /b
#>

# ============================================================
#  Installation PrestaShop 1.7 / 8 / 9 via install\index_cli.php
#  (evite les erreurs HTTP 500 de l'installeur web sous Windows :
#   cache Symfony verrouille par un autre processus PHP)
#  Conseil : cree d'abord le vhost avec creer-vhost-xampp.bat
# ============================================================

function Ask($q, $def) { $r = Read-Host "$q [$def]"; if ([string]::IsNullOrWhiteSpace($r)) { $def } else { $r.Trim().Trim('"') } }
function YesNo($q, $defYes = $false) {
    $r = Read-Host ("$q " + $(if ($defYes) { '(O/n)' } else { '(o/N)' }))
    if ([string]::IsNullOrWhiteSpace($r)) { return $defYes }
    $r -match '^[oOyY]'
}
function Ok($m) { Write-Host "[OK] $m" -ForegroundColor Green }
function Info($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m) { Write-Host "[!] $m" -ForegroundColor Yellow }
function Fail($m) { Write-Host "[ERREUR] $m" -ForegroundColor Red }

Write-Host "=============================================="
Write-Host "   Installation PrestaShop (ligne de commande)"
Write-Host "=============================================="

$X = (Ask 'Dossier XAMPP' 'C:\xampp').TrimEnd('\')
$vhostsConf = Join-Path $X 'apache\conf\extra\httpd-vhosts.conf'

# ---------- Dossier de la boutique ----------
do {
    $shop = (Ask 'Dossier de la boutique' '').TrimEnd('\')
    if ($shop -and $shop -notmatch '^[a-zA-Z]:') { $shop = Join-Path $X "htdocs\$shop" }
    $okShop = $shop -and (Test-Path $shop)
    if (-not $okShop) { Fail "Dossier introuvable : $shop" }
} until ($okShop)

# Package officiel non decompresse (index.php installeur + prestashop.zip)
$zip = Join-Path $shop 'prestashop.zip'
if ((Test-Path $zip) -and -not (Test-Path (Join-Path $shop 'install\index_cli.php'))) {
    Info 'prestashop.zip trouve : decompression (1 a 3 minutes)...'
    Remove-Item (Join-Path $shop 'index.php'), (Join-Path $shop 'Install_PrestaShop.html') -ErrorAction SilentlyContinue
    tar -xf $zip -C $shop
    if ($LASTEXITCODE -ne 0) { Fail 'Echec de la decompression'; return }
    Remove-Item $zip
    Ok 'Archive decompressee'
}
$cli = Join-Path $shop 'install\index_cli.php'
if (-not (Test-Path $cli)) { Fail "install\index_cli.php introuvable (boutique deja installee ou dossier incorrect)"; return }

# ---------- Version PrestaShop ----------
$psVersion = ''
$iv = Join-Path $shop 'install\install_version.php'
if (Test-Path $iv) { $m = [regex]::Match((Get-Content $iv -Raw), "_PS_INSTALL_VERSION_'\s*,\s*'([\d.]+)'"); if ($m.Success) { $psVersion = $m.Groups[1].Value } }
Info "PrestaShop $psVersion"

# ---------- Vhost existant pour ce dossier ? ----------
$domain = ''; $phpDir = ''
if (Test-Path $vhostsConf) {
    $norm = { param($p) ($p -replace '/', '\').TrimEnd('\').ToLower() }
    foreach ($b in [regex]::Matches((Get-Content $vhostsConf -Raw), '(?is)<VirtualHost[^>]*>(.*?)</VirtualHost>')) {
        $body = $b.Groups[1].Value
        $dr = [regex]::Match($body, '(?im)^\s*DocumentRoot\s+"?([^"\r\n]+)"?')
        if (-not $dr.Success -or (& $norm $dr.Groups[1].Value) -ne (& $norm $shop)) { continue }
        $sn = [regex]::Match($body, '(?im)^\s*ServerName\s+(\S+)'); if ($sn.Success) { $domain = $sn.Groups[1].Value }
        $fw = [regex]::Match($body, '(?im)^\s*FcgidWrapper\s+"?([^"\s]+)[\\/]php-cgi\.exe'); if ($fw.Success) { $phpDir = $fw.Groups[1].Value -replace '/', '\' }
        if (-not $phpDir) { $phpDir = Join-Path $X 'php' }
        Info "Vhost trouve : $domain (PHP : $phpDir)"
        break
    }
}
if (-not $domain) { Warn 'Aucun vhost ne pointe sur ce dossier (lance creer-vhost-xampp.bat si besoin)' }

# ---------- Version PHP ----------
if (-not $phpDir) {
    # PrestaShop 1.7 : PHP 7.4 max / PrestaShop 8 : PHP 8.1 max / PrestaShop 9 : PHP 8.1 a 8.4
    $want = switch -regex ($psVersion) { '^1\.' { 'php74' } '^8\.' { 'php81' } default { 'php' } }
    $phpDir = Join-Path $X $want
}
# Accepte un chemin complet ou un nom court : php81, 81, 8.1, php (= PHP par defaut de XAMPP)
$phpList = Get-ChildItem $X -Directory -Filter 'php*' | Where-Object { Test-Path (Join-Path $_.FullName 'php.exe') } | ForEach-Object Name
Info ("Versions PHP disponibles : " + ($phpList -join ', '))
$defName = if ((Split-Path $phpDir -Parent) -eq $X) { Split-Path $phpDir -Leaf } else { $phpDir }
do {
    $choice = Ask 'Version PHP a utiliser' $defName
    if ($choice -match '^[a-zA-Z]:') { $phpDir = $choice.TrimEnd('\') }
    else {
        $n = ($choice -replace '[.\s]', '').ToLower()
        if ($n -notmatch '^php') { $n = "php$n" }
        $phpDir = Join-Path $X $n
        # "83" alors que 8.3 est le PHP par defaut (dossier php)
        if (-not (Test-Path (Join-Path $phpDir 'php.exe')) -and (Test-Path (Join-Path $X 'php\php.exe'))) {
            $main = & (Join-Path $X 'php\php.exe') -r 'echo PHP_MAJOR_VERSION,PHP_MINOR_VERSION;'
            if ($n -eq "php$main") { $phpDir = Join-Path $X 'php' }
        }
    }
    $php = Join-Path $phpDir 'php.exe'
    $phpIni = Join-Path $phpDir 'php.ini'
    $okPhp = Test-Path $php
    if (-not $okPhp) { Fail "PHP introuvable : $php" }
} until ($okPhp)
$phpVer = & $php -c $phpIni -r 'echo PHP_MAJOR_VERSION,chr(46),PHP_MINOR_VERSION;'
Info "PHP $phpVer"
if (($psVersion -match '^8\.' -and [version]$phpVer -gt [version]'8.1') -or ($psVersion -match '^1\.7' -and [version]$phpVer -gt [version]'7.4')) {
    Warn "PrestaShop $psVersion n'est pas compatible avec PHP $phpVer"
    if (-not (YesNo 'Continuer quand meme ?')) { return }
}

# ---------- Parametres ----------
Write-Host ""
if (-not $domain) { $domain = (Split-Path $shop -Leaf).ToLower() -replace '[^a-z0-9.-]', '' ; $domain = "$domain.local" }
$domain = Ask 'Domaine' $domain
$dbName = Ask 'Base de donnees' (($domain -replace '\.local$', '') -replace '[^a-zA-Z0-9_]', '_')
$dbUser = Ask 'Utilisateur MySQL' 'root'
$dbPass = Read-Host 'Mot de passe MySQL [vide]'
$prefix = Ask 'Prefixe des tables' 'ps_'
$name = Ask 'Nom de la boutique' ($domain -replace '\.local$', '')
$lang = Ask 'Langue (fr, en, ...)' 'fr'
$country = Ask 'Pays (fr, be, ...)' 'fr'
$first = Ask 'Prenom admin' 'Admin'
$last = Ask 'Nom admin' 'Local'
do { $email = Ask 'Email admin' '' } until ($email -match '^[^@\s]+@[^@\s]+\.[^@\s]+$')
do {
    $pass = Read-Host 'Mot de passe admin (8 caracteres min)'
    if ($pass.Length -lt 8) { Warn '8 caracteres minimum' }
} until ($pass.Length -ge 8)
$fixtures = if (YesNo 'Installer les produits de demonstration ?' $true) { '1' } else { '0' }

# index_cli.php coupe silencieusement les valeurs contenant = < > | ou `
$bad = @{ 'Mot de passe MySQL' = $dbPass; 'Nom de la boutique' = $name; 'Mot de passe admin' = $pass; 'Prenom' = $first; 'Nom' = $last }
foreach ($k in $bad.Keys) {
    if ($bad[$k] -match '[=<>|`"'']') { Fail "$k : les caracteres = < > | `` `" ' ne sont pas acceptes par l'installeur CLI"; return }
}

# ---------- Verification MySQL ----------
$tmp = Join-Path $env:TEMP 'ps_cli_dbcheck.php'
Set-Content -Path $tmp -Encoding ascii -Value @'
<?php
mysqli_report(MYSQLI_REPORT_OFF);
$c = @new mysqli('127.0.0.1', getenv('PSCLI_DB_USER'), (string) getenv('PSCLI_DB_PASS'));
if ($c->connect_errno) { echo 'ERR ' . $c->connect_error; exit(1); }
$db = $c->real_escape_string(getenv('PSCLI_DB_NAME'));
$r = $c->query("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$db'");
echo 'OK ' . $r->fetch_row()[0];
'@
# Passage par variables d'environnement : PowerShell 5.1 supprime les arguments vides (mot de passe vide)
$env:PSCLI_DB_USER = $dbUser; $env:PSCLI_DB_PASS = $dbPass; $env:PSCLI_DB_NAME = $dbName
$check = & $php -c $phpIni $tmp
Remove-Item $tmp -ErrorAction SilentlyContinue
Remove-Item Env:PSCLI_DB_PASS -ErrorAction SilentlyContinue
if ($check -notmatch '^OK (\d+)') { Fail "MySQL inaccessible : $check (MySQL est-il demarre ?)"; return }
if ([int]$Matches[1] -gt 0) {
    Warn "La base $dbName contient deja $($Matches[1]) tables : elles seront SUPPRIMEES."
    if (-not (YesNo 'Continuer ?')) { return }
}

# ---------- Installation ----------
Remove-Item (Join-Path $shop 'var\cache\*') -Recurse -Force -ErrorAction SilentlyContinue
$env:OPENSSL_CONF = Join-Path $X 'apache\conf\openssl.cnf'
Write-Host ""
Info 'Installation en cours (2 a 5 minutes)...'
Push-Location (Join-Path $shop 'install')
$cliArgs = @(
    '-c', $phpIni, '-d', 'memory_limit=-1', '-d', 'max_execution_time=0', 'index_cli.php',
    "--domain=$domain", '--db_server=127.0.0.1', "--db_user=$dbUser", "--db_password=$dbPass",
    "--db_name=$dbName", '--db_create=1', '--db_clear=1', "--prefix=$prefix",
    "--name=$name", "--language=$lang", "--country=$country", '--timezone=Europe/Paris',
    "--firstname=$first", "--lastname=$last", "--email=$email", "--password=$pass",
    "--fixtures=$fixtures", '--ssl=0', '--rewrite=1'
)
$out = & $php @cliArgs 2>&1 | ForEach-Object { "$_" }
$code = $LASTEXITCODE
Pop-Location
$out | Select-Object -Last 15 | ForEach-Object { Write-Host "  $_" }
if (-not ($out -match 'Installation successful')) { Fail "L'installation a echoue (code $code)"; return }
# Code 255 apres succes : Tools::clearSf2Cache (shutdown) n'arrive pas a supprimer var\cache\prod (fichier verrouille sous Windows)
if ($code -ne 0) { Warn "Code $code apres l'installation (vidage du cache Symfony en fin de script) : sans consequence" }
Ok 'PrestaShop installe'

# ---------- Reglages dev ----------
# Smarty "recompiler si modifie" : .tpl pris en compte sans vider le cache, sans tout recompiler
$tmp = Join-Path $env:TEMP 'ps_cli_config.php'
Set-Content -Path $tmp -Encoding ascii -Value @'
<?php
$p = (require $argv[1] . '/app/config/parameters.php')['parameters'];
$db = new mysqli('127.0.0.1', $p['database_user'], $p['database_password'], $p['database_name']);
$t = $p['database_prefix'] . 'configuration';
foreach (['PS_SMARTY_FORCE_COMPILE' => '1', 'PS_SMARTY_CACHE' => '0', 'PS_CSS_THEME_CACHE' => '0', 'PS_JS_THEME_CACHE' => '0'] as $k => $v) {
    $n = $db->query("SELECT COUNT(*) FROM `$t` WHERE name='$k'")->fetch_row()[0];
    $db->query($n ? "UPDATE `$t` SET value='$v', date_upd=NOW() WHERE name='$k'"
                  : "INSERT INTO `$t` (name, value, date_add, date_upd) VALUES ('$k', '$v', NOW(), NOW())");
}
'@
& $php -c $phpIni $tmp $shop
Remove-Item $tmp -ErrorAction SilentlyContinue
Ok 'Smarty : recompiler si modifie, cache Smarty et CCC desactives'

# ---------- Nettoyage ----------
$installDir = Join-Path $shop 'install'
if (YesNo 'Supprimer le dossier install\ (obligatoire pour acceder au back-office) ?' $true) {
    Remove-Item $installDir -Recurse -Force
    Ok 'Dossier install supprime'
}
$adminDir = 'admin'
if (Test-Path (Join-Path $shop 'admin')) {
    $chars = 'abcdefghijkmnopqrstuvwxyz0123456789'.ToCharArray()
    $adminDir = 'admin' + (-join (1..12 | ForEach-Object { $chars | Get-Random }))
    Rename-Item (Join-Path $shop 'admin') $adminDir
    Ok "Dossier admin renomme en $adminDir"
} else {
    $found = Get-ChildItem $shop -Directory -Filter 'admin*' | Where-Object { $_.Name -ne 'admin-api' -and (Test-Path (Join-Path $_.FullName 'index.php')) } | Select-Object -First 1
    if ($found) { $adminDir = $found.Name }
}
Remove-Item (Join-Path $shop 'var\cache\*') -Recurse -Force -ErrorAction SilentlyContinue

# ---------- Resume ----------
$hosts = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
if (-not (Select-String -Path $hosts -Pattern ("\s" + [regex]::Escape($domain) + "\s*$") -Quiet)) {
    Warn "$domain absent du fichier hosts : lance creer-vhost-xampp.bat"
}
Write-Host ""
Write-Host "=============================================="
Write-Host "  Front       : http://$domain/"
Write-Host "  Back-office : http://$domain/$adminDir/"
Write-Host "  Login       : $email"
Write-Host "  PHP CLI     : $php"
Write-Host "=============================================="
Write-Host "Vider le cache Symfony : `"$php`" bin/console cache:clear"
