
/*************************************
 * Recalcul des statistiques Oracle
 *************************************/
-- Sur les schema commerce, pour voir la date de la dernière analyse : 
select TABLE_NAME,LAST_ANALYZED from user_tables;

-- Sur le schéma SYSTEM ou ETUDES
-- Voici une requête pour vérifier si les stats du schéma en question sont vérrouillés
select distinct(owner) from dba_tab_statistics where stattype_locked='ALL' and owner not in ('SYS','SYSMAN','WMSYS','SYSTEM') order by owner;
-- Sinon pour déverrouiller :
exec dbms_stats.unlock_schema_stats('NomSchema');

-- Puis : 
exec dbms_stats.delete_schema_stats('NomSchema');
exec dbms_stats.gather_schema_stats('NomSchema');


/*************************************
 * Infos sur les tables par script
 *************************************/

tables : select table_name, comments from user_tab_comments;
champs : select table_name, column_name, comments from user_col_comments;
 
 

/***********************************************************
 * Palmarès des tables les plus 'garnies' sur le dossier
 ***********************************************************/
SELECT table_name, num_rows from dba_tables
WHERE owner IN ('NomSchema')
ORDER BY num_rows DESC;


/***********************************************************
 * Créer un script sql a partir d'une requete SQL 
 ***********************************************************/
 -- headers
set serveroutput on size 1000000
set echo off
set termout off
set verify off
SET FEEDBACK OFF

-- spool nom du fichier
spool desactivate_constraints.sql
BEGIN				--requete specifique
		for rec in (select 'ALTER TABLE '||table_name||' DISABLE CONSTRAINT '||constraint_name||' CASCADE;' as ligne
					FROM user_constraints
					WHERE constraint_type = 'R')
		loop
			dbms_output.put_line(rec.ligne);
		end loop;
END;
/
--fin d'ecriture
spool off

--lancement d'un script sql
@file_test.sql

SET FEEDBACK ON
EXIT
