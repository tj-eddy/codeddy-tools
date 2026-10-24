@echo off
setlocal
title Creation VHost XAMPP

rem ===== Configuration =====
set "XAMPP=C:\xampp"
set "VHOSTS=%XAMPP%\apache\conf\extra\httpd-vhosts.conf"
set "HTTPD=%XAMPP%\apache\bin\httpd.exe"
set "HOSTS=%SystemRoot%\System32\drivers\etc\hosts"

rem ===== Relance en administrateur si necessaire =====
net session >nul 2>&1
if errorlevel 1 (
    echo Demande des droits administrateur...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

if not exist "%VHOSTS%" (
    echo [ERREUR] Fichier introuvable : %VHOSTS%
    goto fin
)

echo ==============================================
echo        Creation d'un VirtualHost XAMPP
echo ==============================================
echo.
echo Astuce : tu peux coller le chemin complet, glisser le dossier
echo dans la fenetre, ou taper juste le nom du dossier dans htdocs.
echo.

:askpath
set "PROJ="
set /p "PROJ=Chemin du projet : "
if not defined PROJ goto askpath
set "PROJ=%PROJ:"=%"
for /f "tokens=* delims= " %%a in ("%PROJ%") do set "PROJ=%%a"
if "%PROJ:~-1%"=="\" set "PROJ=%PROJ:~0,-1%"
if not "%PROJ:~1,1%"==":" set "PROJ=%XAMPP%\htdocs\%PROJ%"
if not exist "%PROJ%\" (
    echo [ERREUR] Dossier introuvable : %PROJ%
    goto askpath
)
rem Symfony (ou Laravel) : servir le dossier public\
set "FRAMEWORK="
if exist "%PROJ%\public\index.php" if exist "%PROJ%\bin\console" set "FRAMEWORK=Symfony"
if exist "%PROJ%\public\index.php" if exist "%PROJ%\artisan" set "FRAMEWORK=Laravel"
if defined FRAMEWORK echo [INFO] Projet %FRAMEWORK% detecte : DocumentRoot = public\
if defined FRAMEWORK set "PROJ=%PROJ%\public"
set "DOCROOT=%PROJ:\=/%"

:askname
set "NAME="
set /p "NAME=Nom du vhost (ex: ps91551.local) : "
if not defined NAME goto askname
set "NAME=%NAME: =%"
echo %NAME%| find "." >nul || set "NAME=%NAME%.local"

findstr /i /c:"ServerName %NAME%" "%VHOSTS%" >nul
if not errorlevel 1 (
    echo [ERREUR] Le vhost %NAME% existe deja dans httpd-vhosts.conf
    goto askname
)

rem ===== Version PHP (php = mod_php par defaut, phpXX = FastCGI via mod_fcgid) =====
set "PHPCGI="
set "PHPLIST="
for /d %%d in ("%XAMPP%\php?*") do if /i not "%%~nxd"=="php" if exist "%%d\php-cgi.exe" call set "PHPLIST=%%PHPLIST%% %%~nxd"
if not defined PHPLIST goto phpdone
"%XAMPP%\php\php.exe" -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" > "%TEMP%\xampp_phpver.txt" 2>nul
set "PHPMAIN="
set /p PHPMAIN=<"%TEMP%\xampp_phpver.txt"
del "%TEMP%\xampp_phpver.txt" >nul 2>&1
set "PHPMAINN=%PHPMAIN:.=%"
set "PHPDEF=php"
rem PrestaShop 1.7 / 8 : PHP 8.1 max
set "KERNEL=%PROJ%\app\AppKernel.php"
if exist "%KERNEL%" if exist "%XAMPP%\php81\php-cgi.exe" findstr /r /c:"MAJOR_VERSION = [18];" "%KERNEL%" >nul && set "PHPDEF=php81"
echo.
echo Versions PHP : php (PHP %PHPMAIN%, defaut)%PHPLIST%
:askphp
set "PHPCHOICE="
set /p "PHPCHOICE=Version PHP [%PHPDEF%] : "
if not defined PHPCHOICE set "PHPCHOICE=%PHPDEF%"
set "PHPCHOICE=%PHPCHOICE:.=%"
set "PHPCHOICE=%PHPCHOICE: =%"
if /i not "%PHPCHOICE:~0,3%"=="php" set "PHPCHOICE=php%PHPCHOICE%"
if /i "%PHPCHOICE%"=="php%PHPMAINN%" set "PHPCHOICE=php"
if /i "%PHPCHOICE%"=="php" goto phpdone
if not exist "%XAMPP%\%PHPCHOICE%\php-cgi.exe" (
    echo [ERREUR] %XAMPP%\%PHPCHOICE%\php-cgi.exe introuvable
    goto askphp
)
set "PHPCGI=%XAMPP:\=/%/%PHPCHOICE%"
:phpdone

echo.
echo  Projet : %PROJ%
echo  URL    : http://%NAME%
if defined PHPCGI (echo  PHP    : %PHPCHOICE% ^(FastCGI^)) else (echo  PHP    : PHP %PHPMAIN% ^(defaut^))
echo.

rem ===== Sauvegarde =====
copy /y "%VHOSTS%" "%VHOSTS%.bak" >nul

rem ===== VHost localhost (sinon http://localhost pointe vers le 1er vhost) =====
findstr /i /c:"ServerName localhost" "%VHOSTS%" >nul
if errorlevel 1 (
    >>"%VHOSTS%" echo(
    >>"%VHOSTS%" echo ^<VirtualHost *:80^>
    >>"%VHOSTS%" echo     ServerName localhost
    >>"%VHOSTS%" echo     DocumentRoot "%XAMPP:\=/%/htdocs"
    >>"%VHOSTS%" echo ^</VirtualHost^>
)

rem ===== Ajout du vhost =====
>>"%VHOSTS%" echo(
>>"%VHOSTS%" echo ^<VirtualHost *:80^>
>>"%VHOSTS%" echo     ServerName %NAME%
>>"%VHOSTS%" echo     DocumentRoot "%DOCROOT%"
>>"%VHOSTS%" echo     ^<Directory "%DOCROOT%"^>
set "OPTS=Indexes FollowSymLinks"
if defined PHPCGI set "OPTS=Indexes FollowSymLinks ExecCGI"
>>"%VHOSTS%" echo         Options %OPTS%
>>"%VHOSTS%" echo         AllowOverride All
>>"%VHOSTS%" echo         Require all granted
if defined FRAMEWORK echo         FallbackResource /index.php>>"%VHOSTS%"
if not defined PHPCGI goto vhostphpdone
>>"%VHOSTS%" echo         ^<FilesMatch "\.php$"^>
>>"%VHOSTS%" echo             SetHandler fcgid-script
>>"%VHOSTS%" echo         ^</FilesMatch^>
>>"%VHOSTS%" echo         FcgidWrapper "%PHPCGI%/php-cgi.exe -c %PHPCGI%/php.ini" .php
:vhostphpdone
>>"%VHOSTS%" echo     ^</Directory^>
>>"%VHOSTS%" echo     ErrorLog "logs/%NAME%-error.log"
>>"%VHOSTS%" echo     CustomLog "logs/%NAME%-access.log" common
>>"%VHOSTS%" echo ^</VirtualHost^>
echo [OK] VHost ajoute dans httpd-vhosts.conf

rem ===== Verification de la config Apache =====
"%HTTPD%" -t >nul 2>&1
if errorlevel 1 (
    echo [ERREUR] Configuration Apache invalide, restauration de la sauvegarde.
    "%HTTPD%" -t
    copy /y "%VHOSTS%.bak" "%VHOSTS%" >nul
    goto fin
)

rem ===== Fichier hosts =====
attrib -r "%HOSTS%" >nul 2>&1
findstr /i /c:"127.0.0.1 %NAME%" "%HOSTS%" >nul
if errorlevel 1 (
    >>"%HOSTS%" echo(
    >>"%HOSTS%" echo 127.0.0.1 %NAME%
    echo [OK] %NAME% ajoute dans le fichier hosts
) else (
    echo [INFO] %NAME% deja present dans le fichier hosts
)
ipconfig /flushdns >nul

rem ===== Redemarrage d'Apache =====
sc query Apache2.4 >nul 2>&1
if not errorlevel 1 goto restart_service

tasklist /fi "imagename eq httpd.exe" | find /i "httpd.exe" >nul
if errorlevel 1 (
    echo [INFO] Apache n'est pas lance : demarre-le depuis le XAMPP Control Panel.
    goto ouvrir
)
taskkill /f /im httpd.exe >nul 2>&1
timeout /t 2 /nobreak >nul
powershell -NoProfile -Command "Start-Process -FilePath '%HTTPD%' -WorkingDirectory '%XAMPP%\apache\bin' -WindowStyle Hidden"
echo [OK] Apache redemarre
goto ouvrir

:restart_service
net stop Apache2.4 >nul 2>&1
net start Apache2.4 >nul 2>&1
echo [OK] Service Apache2.4 redemarre

:ouvrir
timeout /t 2 /nobreak >nul
start "" "http://%NAME%"
echo.
echo Termine : http://%NAME%

:fin
echo.
pause
endlocal
