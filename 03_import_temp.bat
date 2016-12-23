@echo off
set start=%time%
:: ### Phase 3 : importer les données dans la VM y ###

:: user = user systeme standard
:: penser à la copie entre les dossiers + creation des users

:: NB ORacle : "Multiple REMAP_SCHEMA lines can be specified, but the source schema must be different for each one."
:: ici les schémas à répliquer sont les mêmes, pas besoin de remap.

for /f "delims=" %%i in ('date /t') do set output=%%i
:: format : DD/MM/YYYY
set date=%output:~6,4%%output:~3,2%%output:~0,2% REM ou modifier ici si jour différent

set "fichier_log=log_import_BDD_%date%.log"

echo == Import de la base de données == > %fichier_log%
echo date fichiers : %date% >> %fichier_log%
echo. >> %fichier_log%
echo - Début - >> %fichier_log%

:: ### etape 1 : import des schemas applicatifs (DDL + données)
impdp user/passwd@VMy directory=DATAPUMP dumpfile=export_A_%date%.dmp logfile=import_A_%date%.log
CALL :verif_import %ERRORLEVEL% etape1

:: ### etape 2 : import des schemas commerciaux, seulement les méta-données
impdp user/passwd@VMy directory=DATAPUMP dumpfile=export_meta_%date%.dmp logfile=import_meta_%date%.log
CALL :verif_import %ERRORLEVEL% etape2



:: ### etape 3 : import des schemas commerciaux, seulement les données 
:: ### 			 exports séparés entre central et magasin

:: ### ATTENTION - il faut procéder à une désactivation des contraintes sur le schéma avant de copier les données ###


:: #########  CENTRAL  #########
:: step 1 : je désactive mes contraintes
sqlplus usercentral/passwd@VMy @desactive_contraintes_auto.sql	REM genere le fichier desactivate_constraints.sql et le lance

:: step 2 : j'importe mes données
impdp user/passwd@VMy directory=DATAPUMP dumpfile=export_data_central_%date%.dmp logfile=import_data_central_%date%.log
set errlvl=%ERRORLEVEL%

:: step 3 : je réactive mes contraintes
sqlplus usercentral/passwd@VMy @reactive_contraintes_auto.sql	REM genere le fichier reactivate_constraints.sql et le lance

CALL :verif_import %errlvl% etape3


:: #########  MAGASIN  #########
:: step 1 : je désactive mes contraintes
sqlplus usermag/passwd@VMy @desactive_contraintes_auto.sql	REM genere le fichier desactivate_constraints.sql et le lance

:: step 2 : j'importe mes données
impdp user/passwd@VMy directory=DATAPUMP dumpfile=export_data_magasin_%date%.dmp logfile=import_data_magasin_%date%.log
set errlvl=%ERRORLEVEL%

:: step 3 : je réactive mes contraintes
sqlplus usermag/passwd@VMy @reactive_contraintes_auto.sql	REM genere le fichier reactivate_constraints.sql et le lance

CALL :verif_import %errlvl% etape4

GOTO FIN

:: call :verif_import 1arg= errorlevel, 2arg= num d'etape (METI= etape1, data central=etape3, ...)
:verif_import
echo. >> %fichier_log%
echo Niveau d'erreur %2 : %1 >> %fichier_log%

IF %1 NEQ 0 (
	set etape_echec=%2
	GOTO ERROR
)
GOTO:EOF

:ERROR
echo. >> %fichier_log%
echo Echec de l'import : >> %fichier_log%
if "%etape_echec%"=="etape1" echo L'import des schemas applicatifs a échoué; consultez le log import_A_%date%.log >> %fichier_log%
if "%etape_echec%"=="etape2" echo L'import des metadatas des schemas commerciaux a échoué; consultez le log import_meta_%date%.log >> %fichier_log%
if "%etape_echec%"=="etape3" echo L'import des données CENTRAL a échoué; consultez le log import_data_central_%date%.log >> %fichier_log%
if "%etape_echec%"=="etape4" echo L'import des données MAGASIN a échoué; consultez le log import_data_magasin_%date%.log >> %fichier_log%
echo. >> %fichier_log%

:FIN
echo. >> %fichier_log%
set end=%time%
echo Debut du script : %start:~0,8% >> %fichier_log%
echo Fin du script : %end:~0,8% >> %fichier_log%
echo. >> %fichier_log%
echo ======= FIN DU LOG ======= >> %fichier_log%
echo. >> %fichier_log%

pause
exit