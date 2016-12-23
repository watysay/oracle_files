@echo off
set start=%time%
:: ### Phase 1 : exporter les données depuis la VM x ###
exit
:: ### PARFILES DANS LE MEME DOSSIER
:: TODO : ajouter une déclaration des parfiles en début de fichier

for /f "delims=" %%i in ('date /t') do set output=%%i
:: format : DD/MM/YYYY
set date=%output:~6,4%%output:~3,2%%output:~0,2%

set "fichier_log=log_export_BDD_%date%.log"

echo == Export de la base de données == > %fichier_log%
echo date fichiers : %date% >> %fichier_log%
echo. >> %fichier_log%
echo - Début - >> %fichier_log%

:: ### etape 1 : export des schemas applicatifs (DDL + données)
expdp user/passwd@VMx directory=DATAPUMP schemas=a,b,c,d dumpfile=export_A_%date%.dmp logfile=export_A_%date%.log parfile=A_parfile.par
CALL :verif_export %ERRORLEVEL% etape1

:: ### etape 2 : export des schemas commerciaux, seulement les méta-données
expdp user/passwd@VMx directory=DATAPUMP schemas=e,f,g content=metadata_only dumpfile=export_meta_%date%.dmp logfile=export_meta_%date%.log parfile=metadata_exclude_parfile.par
CALL :verif_export %ERRORLEVEL% etape2

:: ### etape 3 : export des schemas commerciaux, seulement les données 
:: ### 			 exports séparés entre central et magasin

:: ### CENTRAL - les données des tables incluses : data_central_parfile.par
expdp user/passwd@VMx directory=DATAPUMP schemas=e content=data_only dumpfile=export_data_central_%date%.dmp logfile=export_data_central_%date%.log parfile=data_central_parfile.par
CALL :verif_export %ERRORLEVEL% etape3
   
:: ### MAGASIN - les données des tables incluses : data_mag_parfile.par
expdp user/passwd@VMx directory=DATAPUMP schemas=f content=data_only dumpfile=export_data_magasin_%date%.dmp logfile=export_data_magasin_%date%.log parfile=data_mag_parfile.par
CALL :verif_export %ERRORLEVEL% etape4
 
GOTO FIN

:: call :verif_export 1arg= errorlevel, 2arg= num d'etape (A= etape1, data central=etape3, ...)
:verif_export
echo. >> %fichier_log%
echo Niveau d'erreur %2 : %1 >> %fichier_log%

IF %1 NEQ 0 (
	set etape_echec=%2
	GOTO ERROR
)
GOTO:EOF

:ERROR
echo. >> %fichier_log%
echo Echec de l'export : >> %fichier_log%
if "%etape_echec%"=="etape1" echo L'export des schemas applicatifs a échoué; consultez le log export_A_%date%.log >> %fichier_log%
if "%etape_echec%"=="etape2" echo L'export des metadatas des schemas commerciaux a échoué; consultez le log export_meta_%date%.log >> %fichier_log%
if "%etape_echec%"=="etape3" echo L'export des données CENTRAL a échoué; consultez le log export_data_central_%date%.log >> %fichier_log%
if "%etape_echec%"=="etape4" echo L'export des données MAGASIN a échoué; consultez le log export_data_magasin_%date%.log >> %fichier_log%
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