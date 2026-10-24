<# :
@echo off
title Optimisation PrestaShop local (XAMPP)
net session >nul 2>&1
if errorlevel 1 (
    echo Demande des droits administrateur...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content -LiteralPath '%~f0') -join [char]10)"
echo.
pause
exit /b
#>

# ============================================================
#  Optimisation XAMPP + PrestaShop pour le developpement local
#  1. XAMPP (une seule fois) : php.ini, httpd-xampp.conf, my.ini, OpenSSL, PATH
#  2. Boutique (a chaque projet) : Smarty, CCC, cache, modules (optionnel)
# ============================================================

function Ask($q, $def) { $r = Read-Host "$q [$def]"; if ([string]::IsNullOrWhiteSpace($r)) { $def } else { $r.Trim().Trim('"').TrimEnd('\') } }
function YesNo($q) { (Read-Host "$q (o/N)") -match '^[oOyY]' }
function Ok($m) { Write-Host "[OK] $m" -ForegroundColor Green }
function Info($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m) { Write-Host "[!] $m" -ForegroundColor Yellow }
function Title($m) { Write-Host ""; Write-Host "===== $m =====" -ForegroundColor White }

function Read-List($path) {
    $l = New-Object 'System.Collections.Generic.List[string]'
    $l.AddRange([string[]]([IO.File]::ReadAllText($path) -split "\r?\n"))
    , $l
}
function Save-List($path, $list) {
    [IO.File]::WriteAllText($path, ($list -join "`r`n"), (New-Object Text.UTF8Encoding $false))
}
function Backup($path) { $b = "$path.bak-optim"; if (-not (Test-Path $b)) { Copy-Item $path $b; Info "Sauvegarde : $b" } }
function Find-Line($list, $pattern, $from = 0, $to = -1) {
    if ($to -lt 0) { $to = $list.Count - 1 }
    for ($i = $from; $i -le $to; $i++) { if ($list[$i] -match $pattern) { return $i } }
    return -1
}

# --- php.ini : directive "cle=valeur" (decommente si besoin, sinon ajoute)
function Set-PhpIni($list, $key, $value) {
    $k = [regex]::Escape($key)
    $i = Find-Line $list "^\s*$k\s*="
    if ($i -lt 0) { $i = Find-Line $list "^\s*;\s*$k\s*=" }
    if ($i -ge 0) { $list[$i] = "$key=$value" } else { $list.Add("$key=$value") }
}
# --- php.ini : extension=nom / zend_extension=nom
function Enable-PhpExt($list, $name, $directive = 'extension') {
    $n = [regex]::Escape($name)
    if ((Find-Line $list "^\s*$directive\s*=\s*`"?(php_)?$n(\.dll)?`"?\s*$") -ge 0) { return }
    $i = Find-Line $list "^\s*;\s*$directive\s*=\s*`"?(php_)?$n(\.dll)?`"?\s*$"
    if ($i -ge 0) { $list[$i] = "$directive=$name" } else { $list.Add("$directive=$name") }
}
# --- my.ini : cle=valeur dans la section [mysqld]
function Set-MyIni($list, $key, $value) {
    $s = Find-Line $list '^\s*\[mysqld\]\s*$'
    if ($s -lt 0) { throw '[mysqld] introuvable dans my.ini' }
    $e = Find-Line $list '^\s*\[' ($s + 1); if ($e -lt 0) { $e = $list.Count }
    $k = [regex]::Escape($key)
    $i = -1
    if ($e - 1 -ge $s + 1) {
        $i = Find-Line $list "^\s*$k\s*=" ($s + 1) ($e - 1)
        if ($i -lt 0) { $i = Find-Line $list "^\s*#\s*$k\s*=" ($s + 1) ($e - 1) }
    }
    if ($i -ge 0) { $list[$i] = "$key=$value" } else { $list.Insert($e, "$key=$value") }
}

Write-Host "=============================================="
Write-Host "    Optimisation PrestaShop local (XAMPP)"
Write-Host "=============================================="

$X = Ask 'Dossier XAMPP' 'C:\xampp'
$Xf = $X -replace '\\', '/'
$phpIni = Join-Path $X 'php\php.ini'
$phpExe = Join-Path $X 'php\php.exe'
$httpd = Join-Path $X 'apache\bin\httpd.exe'
$xamppConf = Join-Path $X 'apache\conf\extra\httpd-xampp.conf'
$myIni = Join-Path $X 'mysql\bin\my.ini'
foreach ($f in $phpIni, $phpExe, $httpd, $xamppConf, $myIni) {
    if (-not (Test-Path $f)) { Warn "Fichier introuvable : $f"; return }
}

# ============================================================
Title 'PHP (php.ini)'
Backup $phpIni
$ini = Read-List $phpIni
foreach ($e in 'curl', 'fileinfo', 'gd', 'intl', 'mbstring', 'openssl', 'pdo_mysql', 'soap', 'zip') { Enable-PhpExt $ini $e }
Enable-PhpExt $ini 'opcache' 'zend_extension'
$settings = [ordered]@{
    'memory_limit'                    = '512M'
    'max_execution_time'              = '300'
    'max_input_vars'                  = '10000'
    'post_max_size'                   = '64M'
    'upload_max_filesize'             = '64M'
    'realpath_cache_size'             = '5M'
    'realpath_cache_ttl'              = '600'
    'opcache.enable'                  = '1'
    'opcache.memory_consumption'      = '512'
    'opcache.interned_strings_buffer' = '64'
    'opcache.max_accelerated_files'   = '100000'
    'opcache.validate_timestamps'     = '1'
    'opcache.revalidate_freq'         = '0'
}
foreach ($k in $settings.Keys) { Set-PhpIni $ini $k $settings[$k] }
Save-List $phpIni $ini
Ok 'Extensions zip, gd, intl, curl, soap... + OPcache (revalidation immediate pour le dev)'

# ============================================================
Title 'Apache (httpd-xampp.conf)'
Backup $xamppConf
$conf = Read-List $xamppConf
# DLL dont php_curl a besoin sous Apache (sinon "cURL extension is not enabled")
$mod = Find-Line $conf '^\s*LoadModule\s+php_module'
if ($mod -ge 0) {
    foreach ($dll in 'nghttp2.dll', 'libssh2.dll', 'brotlicommon.dll', 'brotlidec.dll') {
        if (-not (Test-Path (Join-Path $X "php\$dll"))) { continue }
        $p = "$Xf/php/$dll"
        if ((Find-Line $conf ('^\s*LoadFile\s+"?' + [regex]::Escape($p))) -lt 0) {
            $conf.Insert($mod, "LoadFile `"$p`""); $mod++
        }
    }
}
# OPENSSL_CONF pointe par defaut vers apache\bin\openssl.cnf qui n'existe pas
if (Test-Path (Join-Path $X 'apache\conf\openssl.cnf')) {
    $i = Find-Line $conf '^\s*SetEnv\s+OPENSSL_CONF\s'
    if ($i -ge 0) { $conf[$i] = "    SetEnv OPENSSL_CONF `"$Xf/apache/conf/openssl.cnf`"" }
}
Save-List $xamppConf $conf
$test = & $httpd -t 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    Warn "Config Apache invalide, restauration :`n$test"
    Copy-Item "$xamppConf.bak-optim" $xamppConf -Force
} else { Ok 'DLL cURL chargees + OPENSSL_CONF corrige (httpd -t : Syntax OK)' }

# OpenSSL d'Apache cherche sa config dans C:\Apache24\conf (chemin compile en dur)
# sinon openssl_pkey_new echoue dans l'installeur PrestaShop
$src = Join-Path $X 'apache\conf\openssl.cnf'
if ((Test-Path $src) -and -not (Test-Path 'C:\Apache24\conf\openssl.cnf')) {
    New-Item -ItemType Directory -Force 'C:\Apache24\conf' | Out-Null
    Copy-Item $src 'C:\Apache24\conf\openssl.cnf'
    Ok 'openssl.cnf copie dans C:\Apache24\conf (openssl_pkey_new)'
} else { Info 'openssl.cnf deja present dans C:\Apache24\conf' }

# ============================================================
Title 'MySQL / MariaDB (my.ini)'
Backup $myIni
$ram = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
$bp = [math]::Min(2048, [math]::Max(256, [math]::Floor($ram / 1MB / 4 / 128) * 128))
$my = Read-List $myIni
$mysql = [ordered]@{
    'innodb_buffer_pool_size'        = "${bp}M"
    'innodb_log_file_size'           = '512M'
    'innodb_log_buffer_size'         = '64M'
    'innodb_flush_log_at_trx_commit' = '2'
    'max_allowed_packet'             = '64M'
    'sort_buffer_size'               = '2M'
    'tmp_table_size'                 = '64M'
    'max_heap_table_size'            = '64M'
    'table_open_cache'               = '4000'
    'table_definition_cache'         = '4000'
}
foreach ($k in $mysql.Keys) { Set-MyIni $my $k $mysql[$k] }
Save-List $myIni $my
Ok "innodb_buffer_pool_size=${bp}M (25% de la RAM, max 2G), flush_log=2, caches tables"

# ============================================================
Title 'PATH'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$phpDir = Join-Path $X 'php'
if (($userPath -split ';') -notcontains $phpDir) {
    [Environment]::SetEnvironmentVariable('Path', ($userPath.TrimEnd(';') + ";$phpDir"), 'User')
    Ok "$phpDir ajoute au PATH (ouvre un nouveau terminal pour 'php -v')"
} else { Info "$phpDir deja dans le PATH" }

# ============================================================
Title 'Boutique PrestaShop'
$shop = Ask 'Dossier de la boutique (vide = ignorer)' ''
if ($shop -and -not ($shop -match '^[a-zA-Z]:')) { $shop = Join-Path $X "htdocs\$shop" }
if ($shop -and -not (Test-Path (Join-Path $shop 'app\config\parameters.php'))) {
    Warn "app\config\parameters.php introuvable dans $shop (boutique pas encore installee ?)"
    $shop = ''
}
if ($shop) {
    # Smarty "recompiler si modifie" : les .tpl modifies sont pris en compte sans vider le cache,
    # sans recompiler tous les templates a chaque page ("forcer la compilation" = ~10s/page)
    $tmp = Join-Path $env:TEMP 'ps_optim_config.php'
    Set-Content -Path $tmp -Encoding ascii -Value @'
<?php
$p = (require $argv[1] . '/app/config/parameters.php')['parameters'];
$host = $p['database_host']; $port = (int) ($p['database_port'] ?: 3306);
if (strpos($host, ':') !== false) { [$host, $port] = explode(':', $host); }
$db = new mysqli($host, $p['database_user'], $p['database_password'], $p['database_name'], (int) $port);
$t = $p['database_prefix'] . 'configuration';
$values = [
    'PS_SMARTY_FORCE_COMPILE' => '1', // recompiler si fichiers modifies
    'PS_SMARTY_CACHE' => '0',         // cache Smarty desactive
    'PS_CSS_THEME_CACHE' => '0',      // CCC CSS desactive
    'PS_JS_THEME_CACHE' => '0',       // CCC JS desactive
];
foreach ($values as $k => $v) {
    $n = $db->query("SELECT COUNT(*) FROM `$t` WHERE name='$k'")->fetch_row()[0];
    $sql = $n ? "UPDATE `$t` SET value='$v', date_upd=NOW() WHERE name='$k'"
              : "INSERT INTO `$t` (name, value, date_add, date_upd) VALUES ('$k', '$v', NOW(), NOW())";
    $db->query($sql);
    echo "  $k = $v\n";
}
'@
    & $phpExe $tmp $shop
    if ($LASTEXITCODE -eq 0) { Ok 'Smarty : recompiler si modifie, cache Smarty et CCC desactives' }
    else { Warn 'Echec de la mise a jour de la configuration (MySQL demarre ?)' }
    Remove-Item $tmp -ErrorAction SilentlyContinue

    $defines = Get-Content (Join-Path $shop 'config\defines.inc.php') -Raw
    if ($defines -match "define\('_PS_MODE_DEV_',\s*true\)") { Warn '_PS_MODE_DEV_ est a true : le site est 3 a 5x plus lent' }
    if ($defines -match "define\('_PS_DEBUG_PROFILING_',\s*true\)") { Warn '_PS_DEBUG_PROFILING_ est a true : a repasser a false' }
    if (Test-Path (Join-Path $shop 'install')) { Warn 'Le dossier install\ existe encore' }

    Write-Host ""
    Write-Host "Modules inutiles en dev (appels API externes, tableau de bord) :"
    $mods = 'ps_checkout', 'ps_facebook', 'psxmarketingwithgoogle', 'ps_eventbus', 'ps_mbo',
            'dashactivity', 'dashgoals', 'dashproducts', 'dashtrends', 'ps_accounts'
    Write-Host ("  " + ($mods -join ', '))
    if (YesNo 'Desactiver ces modules ?') {
        Push-Location $shop
        foreach ($m in $mods) {
            if (-not (Test-Path (Join-Path $shop "modules\$m"))) { continue }
            & $phpExe bin/console prestashop:module disable $m --no-interaction 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { Ok "$m desactive" } else { Warn "$m : echec (deja desactive ?)" }
        }
        Pop-Location
    }

    Remove-Item (Join-Path $shop 'var\cache\*') -Recurse -Force -ErrorAction SilentlyContinue
    Ok 'Cache var\cache vide (le 1er chargement sera un peu plus long)'
}

# ============================================================
Title 'Windows Defender'
Write-Host "Defender analyse chaque fichier PHP lu : c'est souvent le plus gros ralentissement."
if (YesNo "Exclure $X$(if ($shop) { " et $shop" }) de l'analyse ?") {
    $paths = @($X); if ($shop) { $paths += $shop }
    Add-MpPreference -ExclusionPath $paths
    Add-MpPreference -ExclusionProcess (Join-Path $X 'apache\bin\httpd.exe'), (Join-Path $X 'mysql\bin\mysqld.exe')
    Ok 'Exclusions Defender ajoutees'
}

# ============================================================
if ($shop) {
    Title 'Git'
    $gi = Join-Path $shop '.gitignore'
    if (-not (Test-Path $gi) -or (YesNo '.gitignore existe deja : le remplacer ?')) {
        # ascii : un BOM UTF-8 casserait la 1ere regle
        Set-Content -Path $gi -Encoding ascii -Value @'
# Configuration locale (identifiants BDD, cles)
/app/config/parameters.php
/app/config/parameters.yml
/config/settings.inc.php
/.env.local

# Cache, logs, sessions
/var/cache/
/var/logs/
/var/sessions/
/themes/*/cache/
/themes/*/assets/cache/
/config/xml/

# Images generees et fichiers clients
/img/p/*
/img/c/*
/img/m/*
/img/su/*
/img/st/*
/img/tmp/*
/upload/*
/download/*
!/img/*/index.php
!/upload/index.php
!/download/index.php

# Back-office (dossier admin renomme)
/admin*/autoupgrade/
/admin*/backups/
/admin*/import/
/admin*/export/

# Installation
/install/
/install-dev/

# Dependances front
node_modules/

# Systeme / IDE
.DS_Store
Thumbs.db
desktop.ini
.idea/
.vscode/
*.log
/*.zip
'@
        Ok ".gitignore cree dans $shop"
        Write-Host "  cd `"$shop`"; git init; git add .; git commit -m `"init`""
    }
}

# ============================================================
Title 'Termine'
Write-Host "Redemarre Apache ET MySQL depuis le XAMPP Control Panel (Stop puis Start)" -ForegroundColor Yellow
Write-Host "pour appliquer les changements de php.ini, httpd-xampp.conf et my.ini."
Write-Host ""
Write-Host "Pense a vider le cache uniquement apres une modif de services.yml, routes, hooks :"
Write-Host "  php bin/console cache:clear"
