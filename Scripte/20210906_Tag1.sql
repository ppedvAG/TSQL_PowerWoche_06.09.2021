
/*
	Prosa ; WhiteSpace ist Dein Freund (TAB)
	-- Intellicence : Pfeiltasten + TAB 
	-- ALT + X = ALTernative eXecution == F5 = execution
	-- SHIFT + PFeiltasten = Markierung
*/

-- [0.] SSMS anpassen

Tools / Extra > Optionen > Environment > All Language > LineNumber	-- Zeilennummern 
						 > Environment > International Language		-- en_US f?r Oberfl?che
						 > Text Editor > Fonts & Colours			-- Rot/Gr?n-Blind

-- [1.] Wo lebe ich?

SELECT @@VERSION		-- SQL SVR

SELECT @@LANGUAGE		-- SQL Language

SELECT * FROM sys.syslanguages

SET LANGUAGE Deutsch	-- FORMAT-Sprache der Response (Message)
																		--	<TYPE>
SELECT SYSDATETIME()	-- SystemZeit des SERVERS!							DATETIME2
SELECT GETDATE()		-- Zeit des Servers, auf dem der SQL SVR l?uft!		DATETIME

-- [2.] Wie lebe ich?

-- MASTER
> Config des SVR 'in KOPIE' 
> MetaDaten der STRUKTUR 
> MetaDaten ALLER Datenbanken
> Sicherheit auf SVR Ebene

-- msDB 
> MetaDaten f?r BACKUP :: 1x Woche 
> Config der verteilten Systeme = CLUSTER 
> 'Sicherheit auf jew. DB-Ebene' >> wer darf ... auf DIESER Datenbank
> SCHEMABINDING :: PersonA darf, PersonB nicht, weil das SCHEMA das so will

-- tempDB 
> 'Kopie ALLER in VERWENDUNG sich befindlicher OBJEKTE'
> tempDB 1:1 im RAM gehalten >> ORDER BY findet auf DEINEM PC statt
> SQL SVR ist tendentiell "faul" :: so viel wie n?tig, so wenig wie m?glich

-- DistributionDB
> Config von CLUSTERN 

-- modelDB
> Rohlinge zum Erstellen 'NEUER benamter Objekte'

-- ReportServer / ReportServerTempDB
> SSRS = SQL SVR Reporting Service

-- DW... = DataWareHouse Objects
> Oracle / OLAP / SAP /... ] = Tabular Data Warehouse = [ Table => PowerBI, Tableau,...

-- [3.] Sauberes TSQL = Transact-SQL { SELECT ; INSERT ; UPDATE ; DELETE ; CREATE ; DROP ; ...}

	>> TAB : Einr?ckungen && Kommentare
	>> new Line ! 
	>> saubere [Benamung] sowie TYPE-Setzung

-- [3.1] GO ist Dein Freund

GO					-- beginne hier TSQL neu zu interpretieren
USE [Northwind]		-- Imperatives Anmelden mit R?ckantwort
GO					-- STOPP, falls NICHT erfolgreich 

SELECT 
	CustomerID		-- neue Zeile bringt Lesbarkeit
	, Country		-- Komma am Beginn ist besser f?r sp?tere Auskommentierung
FROM Customers	;	-- Delimiter: Info an Pr?Prozessor, dass Ende erreicht ist 
GO	--< Delimiter (SVR!): mache nur weiter, FALLS erfolgreich gewesen
	--< Falls Security NEIN sagt, dann bekomme AUSF?HRLICHE Error-Message 

SELECT 
	CustomerID		
	, Country		
FROM dbo.Customers	 --< bitte immer VOLLQUALIFIZIERT = SCHEMA.TABLE
GO		-- bei dbo nicht notwendig, aber stets guter Stil, das zu tun!

-- Alternativ-Beispiel

USE [TSQL2012]
GO

SELECT *
FROM Sales.Customers	--< innerhalb SCHEMA "Sales" die TABLE "Customers" aufgerufen 
GO

-- [3.2] Benamung / Nomenklatur / Collation / UTF-8

	MAXIMUM LENGTH << 127 Bytes -- << := deutlich kleiner als...
	
	? ? ? ? / ? * _ % ( ) [ ] . Leerzeichen > ASCII benutzen, nicht UTF-8 
	> K?ufer > K[]ufer 

	Funktionsbezeichnungen 'NICHT' benutzen
	>  ALTER	as FUNCTION
	> [Alter]	as NAME 

	CREATE TABLE demo TABLE 
		versus CREATE TABLE [demo Table]
		versus CREATE TABLE [DemoTable]

	ich bins = [ich bins] = ich%20bins = ich%C3%20bins = ich_x0020_bins

	' DemoTable  txtDocName  :: Nomenklatur ; PascalCase / CamelCase '

Server > Rechtsklick > Properties > Server COLLATION = Latin1_General_CI_AS

	>> Latin1	= Lateinische Schrift (ASCII) && alphanumerische Sortierung
	>> General	= Allgemeine Sortierungs- und Funktionseinstellung (alphanumerisch)
	>> CI		= Case Insensitive = Gro?- / Kleinschreibung ist 'uninteressant'
	>> AS		= Accent Sensitive = a ? ? ? ? ; Akzent 'interssiert' sehr wohl 

	'M[]use' ASCII	<>	  N'M?use'  UTF-8 :: f?r DATENS?TZE prinzipiell OK, falls CULTURE = de-DE

-- [3.3] Stuktur und Organisation (Normalform)

	' siehe [Normalform] in EXCEL-Mappe '

	> was brauche ich wie oft und wie viel wovon? (Normalform)
	> Struktur : wonach frage ich h?ufig? (JOIN)
	> Optimum = 3 NF 'VERLETZT' ; CALCULATED COLUMN = UPDATE ggf. [Bestell-Summe]
-- Trigger > TSQL-HELP (SSMS) 
	> wie granular brauche ich eine Information wirklich / regelm??ig? (Cal. Col.)

-- [3.4] Passender TYPE zur Spalte

				[Nachname]
CHAR(10)		'Krause....'	+ TRIM()  + LEN()  + RIGHT()  + LEFT()  
VARCHAR(10)		'Krause'

UPDATE [Nachname] SET 'Bergmann'

CHAR(10)		'Bergmann..'				-- 10 Byte
VARCHAR(10)		'Bergma'	+ Appendix_1	-- 6 Byte
...
..
.
Appendix_1		'nn'						-- 2 Byte


NCHAR(10)		N'Kr?u?el...'		-- N.. = UTF-8 = 10 Byte CONTENT + 10 Byte FORMAT
NVARCHAR(10)	N'Kr?u?el'

/* ## Spoiler f?r Tuning : Datens?tze werden IMMER in SPEICHERSEITEN abgespeichert.
	Diese sind IMMER 8 kByte gro?, auch wenn nur 'nn' drin steht. WTF! OMG!		*/
	
-- [4.] Tabellen-Definition

	Fu?ball-Spieler > FOREIGN > Person
	HR.Personen { PersonID ; foreName ; surName }
	HR.Player   { PlayerID ; fkPersonID } 

-- In Datenbank anmelden

GO
USE [master]
GO

-- Datenbank-Definition

CREATE DATABASE [Bundesliga]
GO

	' ReFresh von Object-Explorer = MASTER aktualisieren
	  CTRL + SHIFT + R = ReFresh MetaData for Intellicence '

-- Schema-Definition
--> KANN es im MASTER erstellen und dann AUTHORIZATION [HR] erben, muss aber nicht.
--> HR-SCHEMA MUSS aber immer in jew. Datenbank erstellt werden und AUTHORIZATION haben.

USE [Bundesliga]
GO

CREATE SCHEMA [HR] AUTHORIZATION [dbo]	-- = MASTER.[dbo] IS OWNER von Bundesliga.[HR]
GO

-- Tabellen-Definition

	-- INTEGER (0) ... 5.6 * 10^10 ; smallint ; bigint ; number 

CREATE TABLE HR.[Person] (
	PersonID	INTEGER IDENTITY(1,1)		-- selbst?ndig hochz?hlen
		CONSTRAINT [pkPersonID] PRIMARY KEY -- Primary Key Constraint f?r [Naming]
		NONCLUSTERED			-- nicht zwingend auch so in der Reihenfolge auf HDD 
	, foreName  NVARCHAR(50)	-- tendentiell wenig Ver?nderungen
	, surName	NCHAR(20)		-- potentiell h?ufige Ab?nderungen
--	, surName   NCHAR(20) NOT NULL	<-- w?re besser gewesen ; DEFAULT = NULLABLE ;)
) ; 
GO

-- Table mit FOREIGN KEY 

CREATE TABLE HR.[Player] (
	PlayerID	INTEGER IDENTITY(1,1)		-- selbst?ndig hochz?hlen
		CONSTRAINT [pkPlayerID] PRIMARY KEY -- Primary Key Constraint f?r [Naming]
		NONCLUSTERED			-- nicht zwingend auch so in der Reihenfolge auf HDD 
	, PersonID INTEGER		-- TYPE identisch w?hlen > weniger zus?tzlicher Aufwand
		CONSTRAINT [fkPlayerPerson] FOREIGN KEY -- FOREIGN Key Constraint f?r [Naming]
		REFERENCES HR.Person(PersonID)		-- FK-Referenz
) ; 
GO

-- das ist supi > warum?!

	' Diagram-Design besonders hilfreich bei guter Benamung! ' = SCHEME / DB-DIAGRAM
	[+] > Funktion bereitgestellt && Rechtsklick > New Diagram

-- kann man so etwas NACHTR?GLICH ?ndern?!

	Tabelle > Rechsklick > DESIGNER : ?nderungen umsetzen
		Freier Bereich > Rechtsklick > ?nderungsScript >> 'ERROR-Message'
		Tools > Options > Designer > [] Prevent changes.... re-creation of table
		Freier Bereich > Rechtsklick > ?nderungsScript >> -- Change SCRIPT

	' Ja, schon... ABER: es muss eine NEUE Tabelle erstellt und CONTENT verschoben werden!
	  Au?erdem: ALLE Tabellen "drum herum" (z.B. FOREIGN KEY) sind GESPERRT gegen I/O-Zugriffe.
	  ?nderung findet in DEINER Sitzung auf DEINEM Rechner statt... viel Gl?ck mit dem INTERNET. '

-- CONSTRAINT = einschr?nkende Eigenschaft

	> CREATE TABLE
		> TYPE CONSTRAINT 
		> PRIMARY KEY / FOREIGN KEY CONSTRAINT
		> ggf. DEFAULT / CHECK ; geht auch sp?ter, ABER '## : siehe unten'
		
	> ALTER TABLE
		> ADD : f?ge nachtr?glich eine neue (berechnete) Spalte hinzu
			' OHNE eine NEU-ERSTELLUNG der Tabelle zu erzwingen! '

ALTER TABLE HR.Player ADD [Honorar] INTEGER NULL	-- muss NULLABLE sein
GO

		> DEFAULT : setze Standardwert, falls User keine Ansage macht = NULL

ALTER TABLE HR.Player ADD			-- nachtr?glich hinzuf?gen
	CONSTRAINT [DFT_Honorar]		-- Name des DEFAULT Constraints
	DEFAULT ( ( 1000 ) )			-- Wunsch nach DEFAULT && der WERT des Default
	FOR [Honorar]					-- Spalte f?r DEFAULT CONSTRAINT
	GO

		> '## : BEIDES -- bitte in EINEM SCHRITT, sonst geht das nicht! '

ALTER TABLE HR.Player ADD [Honorar] INTEGER NOT NULL			
	CONSTRAINT [DFT_Honorar]		
	DEFAULT ( ( 1000 ) )			
	GO
				
		> '## : BEIDES -- CREATE TABLE w?re besser gewesen! '

CREATE TABLE HR.[Player] (
	[PlayerID]	INTEGER IDENTITY(1,1)		
		CONSTRAINT [pkPlayerID] PRIMARY KEY 
		NONCLUSTERED			 
	, [PersonID] INTEGER		
		CONSTRAINT [fkPlayerPerson] FOREIGN KEY 
		REFERENCES HR.Person(PersonID)
	, [Honorar] INTEGER NOT NULL			
		CONSTRAINT [DFT_Honorar] DEFAULT ((1000))	 
) ; 
GO

		> CHECK : falls User Ansage macht, ?berpr?fe auf Sinnhaftigkeit

ALTER TABLE HR.Player ADD			-- nachtr?glich hinzuf?gen
	CONSTRAINT [CHK_Honorar]		-- Name des CHECK Constraints
	CHECK ( ( [Honorar] >= 1000 ) )	-- Wunsch nach CHECK && der VERGLEICH f?r den CHECK
	GO

		> '## : BEIDES -- CREATE TABLE ist eine Option = MAXIMUM-EDITION '

CREATE TABLE HR.[Player] (
	[PlayerID]	INTEGER IDENTITY(1,1)		
		CONSTRAINT [pkPlayerID] PRIMARY KEY 
		NONCLUSTERED			 
	, [PersonID] INTEGER		
		CONSTRAINT [fkPlayerPerson] FOREIGN KEY 
		REFERENCES HR.Person(PersonID)
	, [Honorar] INTEGER NOT NULL			
		CONSTRAINT [DFT_Honorar] DEFAULT ((1000))
		CONSTRAINT [CHK_Honorar] CHECK   (( [Honorar] >= 1000 ))
) ; 
GO

-- Datensatz "low tech" hizuf?gen

INSERT INTO SCHEMA.TABLE (COLUMN) VALUES ( CONTENT )

INSERT INTO HR.Player ( PlayerID , PersonID ) VALUES ( 1 , 1)
GO		-- geht nicht, weil IDENTITY(1,1)

INSERT INTO HR.Player ( PersonID ) VALUES ( 1 )
GO		-- geht nicht, Person NOT EXISTS

INSERT INTO HR.Person ( foreName, surName ) VALUES ( 'Pink' , 'Floyd' )
GO		-- geht, aber nur semi-geil; ein paar msec mehr

INSERT INTO HR.Person ( foreName, surName ) VALUES ( N'Pink' , N'M?ller' )
GO		-- geht, wesentlich besser, weil TYPE-konform

SELECT * FROM HR.Person

	' vor SQL SVR 2016 > ID = 2 ; nach SQL SVR 2017 > ID = 1 '

INSERT INTO HR.Player ( PersonID ) VALUES ( 1 )
GO		-- geht, weil FOREIGN KEY keinen ?rger macht

SELECT * FROM HR.Player
	
	' mit FOREIGN KEY kann man immer noch IDs "verbrennen" ; PlayerID = 2 '

-- ab hier HONORAR mit DEFAULT und CHECK

ALTER TABLE HR.Player ADD [Honorar] INTEGER NOT NULL			
	CONSTRAINT [DFT_Honorar]		
	DEFAULT ( ( 1000 ) )		-- WITH CHECK = DS which EXISTS	
	GO

INSERT INTO HR.Player ( PersonID ) VALUES ( 1 )
GO		-- geht ; Honorar = 1000 DEFAULT

INSERT INTO HR.Player ( PersonID, Honorar ) VALUES ( 1 , 500 )
GO		-- CHECK >= 1000

INSERT INTO HR.Player ( PersonID, Honorar ) VALUES ( 1 , 1500 )
GO		-- CHECK >= 1000

	' mit FOREIGN KEY kann man immer noch IDs "verbrennen" ; PlayerID = 5 '

-- FORMAT ( value , format [, culture] )

SELECT 
	PlayerID
	, PersonID
	, FORMAT ( Honorar , 'C' , 'de-DE' ) AS [Honorar]  -- TYPE = STRING !!
FROM HR.Player

-- DELETE Struktur

DROP TABLE IF EXISTS HR.Player ;	-- immer zuerst FOREIGN KEY

DROP DATABASE IF EXISTS Bundesliga ; -- oft Scheiss, was ist besser?

IF DB_ID('Bundesliga') NOT NULL DROP DATABASE ; -- besser, weil auf ID-Ebene
