-- #######################

-- ####################### [Northwind] #######################

-- #######################

USE [Northwind]
GO				--> mache NUR dann weiter, wenn ERFOLGREICH, sonst ERROR-Message und STOP

-- Spalten, die mit den Datentypen CHAR, VARCHAR, BINARY und VARBINARY definiert sind, 
-- verf?gen ?ber eine definierte Gr??e (es werden Leerzeichen stets NICHT abgeschnitten).
SET ANSI_PADDING ON 
GO

-- ######################################################

-- ########### Abfrage als variable Procedure ###########

-- ######################################################

-- ##### Auswahl der Tabellen f?r sp?tere Abfragen

-- Customers	[customerid | CompanyName | ContactName | ContactTitle | City | Country ]
-- Orders		[ EmployeeID | OrderDate | freight | shipcity | shipcountry ]
-- OrderDetails	[ prodid | orderid | unitprice | Quantity ]
-- Products		[ ProductName ]
-- Employees	[ LastName | FirstName | BirthDate | city | country ]

-- ######################################################

-- ##### Grund-Tabelle

SELECT  cust.CustomerID
		, cust.CompanyName
		, cust.ContactName
		, cust.ContactTitle
		, cust.City
		, cust.Country
		, ord.EmployeeID
		, ord.OrderDate
		, ord.freight
		, ord.shipcity
		, ord.shipcountry
		, ods.OrderID
		, ods.ProductID
		, ods.UnitPrice
		, ods.Quantity
		, prod.ProductName
		, emp.LastName
		, emp.FirstName
		, emp.birthdate
into dbo.KundeUmsatz
FROM	Customers AS cust
		INNER JOIN Orders AS ord ON cust.CustomerID = ord.CustomerID
		INNER JOIN Employees AS emp ON ord.EmployeeID = emp.EmployeeID
		INNER JOIN [Order Details] AS ods ON ord.orderid = ods.orderid
		INNER JOIN Products AS prod ON ods.productid = prod.productid

-- Multiplikation f?r gro?en Datenbestand
-- solange bis ~ 1.100.000 erreicht sind > ~ 400 MB Gr??e

insert into dbo.KundeUmsatz
select * from dbo.KundeUmsatz
GO 9								-- 9 Wiederholungen

select COUNT(*) from dbo.KundeUmsatz

-- ### Aufgabenstellung #################################
-- ### Erstelle eine Prozedur, die folgendes erledigt ###

	exec uspKDSuche 'ALFKI'							-- alle finden die custID = 'ALFKI'
	exec uspKDSuche 'A'								-- alle mit A beginnend
	exec uspKDSuche NULL oder exec uspKDSuche '%'	-- alle Kunden ausgeben

-- Prozeduren

CREATE PROCEDURE dbo.[uspKDSuche] @kid NCHAR(5) 
AS
SELECT * FROM dbo.KundeUmsatz WHERE CustomerID LIKE @kid + '%'

exec uspKDSuche 'ALFKI'	-- l?uft tadellos
exec uspKDSuche 'A'		-- l?uft nicht, weil die L?nge des Parameters als Variable ZU KURZ

-- ###########################################################################################
-- ### Erkenntnis #1 : Nehme NIEMALS eine Variable so her wie in der Datenbank-Definition ####
-- ###########################################################################################

-- char(5) hat 5 Zeichen --> 'A%   ' als 'A%xxx' mit x als LEERZEICHEN > MUSS 5 Zeichen haben 
-- Variablen m?ssen nicht den gleichen Datentyp haben --> lieber "gr??eren" Typ w?hlen
-- Sie laufen sogar besser, wenn man NICHT den gleichen Datentyp w?hlt, da weniger Einsch?nkung
-- Genauigkeit der Eingabe relevant, NICHT Typ-Konformit?t mit dem ZIEL (Tabelle: NCHAR(5)).

-- ###########################################################################################
-- ###########################################################################################
-- ###########################################################################################

ALTER PROCEDURE dbo.[uspKDSuche] @kid VARCHAR(10) = '%'
AS
SELECT * FROM dbo.KundeUmsatz WHERE CustomerID LIKE @kid + '%'

-- Test

-- CHAR(10)  = 10 BYTE									 'text'
-- NCHAR(10) = 10 BYTE CONTENT + 10 BYTE UTF-8			N'text'

exec uspKDSuche 'A' 
exec uspKDSuche 'ALFKI' 
exec uspKDSuche			

-- ### Aufgabenstellung #################################
-- ### Suche alle Angestellten im Rentenalter (65) ######

SELECT * FROM KundeUmsatz WHERE DATEPART(yy,GETDATE()) - DATEPART(yy,birthdate) >= 65
SELECT * FROM KundeUmsatz WHERE YEAR(GETDATE()) - YEAR(birthdate) >= 65

SELECT * FROM KundeUmsatz WHERE DATEDIFF( YEAR , birthdate , GETDATE() ) >= 65

	' Laufzeitverhalten schlecht bei so einer Abfrage '
	' Alter der Person {int} cumputed column & linearer Vergleich '

-- ######################################################

-- #### Verbesserter logischer Fluss in den Abfragen ####

-- ######################################################

-- ### Grunds?tzliches in Bezug auf Ablaufpl?ne

/*
    FROM  (TABELLE t1) 
--> JOIN (TABELLE t2)	--> WHERE (sieht SQl schon T1 und T2)
--> GROUP BY			--> (Vor-) Gruppierung f?r sp?tere Aggregationen
--> HAVING				--> kann nicht wissen wie die Spalten im SELECT hei?en
--> SELECT				--> keine Ausgabe, sondern Spalten-Alias sowie Berechnungen und FUNCTION()
--> ORDER BY			--> wird immer auf das Ergebnis angewendet)
--> LIMITER				--> TOP | DISTINCT | ...
--> RESULT SET			--> Ausgabe des DATA SETs (also ausgewertete Rohdaten)

*/ 

-- SELECT-Ablaufplan nicht vergessen!
SELECT 	cust.CustomerID		AS [KDNR]
		, cust.CompanyName  AS [Firma]
		, ord.orderid
		, ord.orderdate
FROM  customers			AS [cust] 
	  inner join orders AS [ord]  ON cust.customerid = ord.customerid
WHERE CompanyName LIKE 'A%' -- Firma hier geht nicht als Filter-Eigenschaft
ORDER BY Firma		-- Im Ablaufplan ist erst HIER der ALIAS bekannt

-- ORDER BY bei Aggregationen
SELECT 
		cust.CompanyName AS Firma
		, sum(ord.Freight) AS Frachtmenge
FROM
	  Customers AS cust 
	  inner join Orders AS ord on cust.CustomerID = ord.CustomerID
WHERE 
	CompanyName LIKE 'A%' 
GROUP BY CompanyName	-- auch hier kein ALIAS
ORDER BY Firma -- hier w?rde es gehen > dennoch schlechter Stil!

-- HAVING-Filterung bei GROUP BY / Aggregation
SELECT 
		companyname as Firma
		, sum(freight) AS Frachtmenge
FROM 
	  customers AS cust
	  inner join orders AS ord on cust.CustomerID = ord.CustomerID
WHERE 
	companyname like 'A%' 
GROUP BY companyname	  -- HAVING ben?tigt GroupBy-Ebenen f?r die gruppierte Aggregation
HAVING sum(freight) > 200 
ORDER BY companyname 

-- Unterschied GROUP BY vs. HAVING
select country, companyname , count(*) from customers  -- 1 MIO Datens?tze
where country = 'UK' 
group by country, companyname 
order by companyname

select country, companyname , count(*) from customers  -- 1 MIO Datens?tze
-- where country = 'UK' 
		-- h?tte auf 10000 gefiltert, statt komplett alle durchzugehen
		-- bei Verwendung von WHERE h?tte der SQL nicht 1 Mio Datens?tze gruppieren m?ssen
		-- der INDEX verhindert diesen Unsinn und sorgt f?r IDENTISCHEN Ablaufplan 
group by country, companyname having country='UK' 
order by companyname

-- ###########################################################################################
-- ### Erkenntnis #2 : Schreibe NIE etwas in ein HAVING, was ein WHERE gut leisten k?nnte ####
-- ###########################################################################################

-- HAVING ist >NUR< f?r Aggregation des GROUP BY da, um Filterung auf Aggregierung anzuwenden
-- logischer Fluss wird bei einfachen Statements ber?cksichtigt > automatische Korrektur aktiv
-- SQL Server Korrektur bei komplexen Statements nicht mehr m?glich > unn?tiger Rechenaufwand

-- ###########################################################################################
-- ###########################################################################################
-- ###########################################################################################

-- ##### Mess-Techniken und deren Grundlagen ############

-- ######################################################

-- Plan erkl?rt nur, WO der SQL SVR die Daten holt, WIE er das macht und WAS er damit tut
-- JEDER Plan stellt einen AnwendungsBath dar, der jeweils 100% (anteilig verteilt) verbraucht
-- verschiedene Typen : gesch?tzter, tats?chlicher, Echtzeit-Plan
-- gemessen werden FLOPS (I/O) und TIME (Dauer, CPU,...)

-- ######################################################
					
													%	item	RES%		CPU		TIME	LogRead
select * from orders where freight < 1			-- 50%  025 E	0.018 $		0		350		22
select * from orders where freight > 100		-- 50%	200 E	0.018 $		0		350		22

	'dbo.Orders > Indexes > Rechtsklick > Neu > NonClustered [freight] INCLUD [Rest] '

select * from orders where freight < 1			-- 34%  025 E	0.003 $		0		350		2
select * from orders where freight > 100		-- 66%	200 E	0.006 $		0		400		7

	-- Ein Batch sind immer 100% und werden dann RELATIV verteilt.

select * from orders where freight < 1			-- 49%  025 E	0.003 $		0		350		2
select TOP 10 * from orders where freight > 100	-- 51%	010 E	0.003 $		0		300		2

	' l?sche den Index > PK Scan '

select * from orders where freight < 1			-- 82%  025 E	0.018 $		0		300		22
select TOP 10 * from orders where freight > 100	-- 18%	010 E	0.004 $		0		250		4

-- ###########################################################################################
-- #### Erkenntnis #3 : Ablauf-Pl?ne und Ausloben von Indizes gehen optimal Hand in Hand #####
-- ###########################################################################################

-- Verschiedene TSQL-Statements stets ?ber (erwartete) Ablaufpl?ne vergleichen
-- Index SEEK stets besser als Index SCAN --> Erstellen neuer Indizes KANN eine Verbesserung sein
-- LIMITER besonders effektiv beim Index, was die individuellen Kosten im Regelfall reduziert

-- ###########################################################################################
-- ###########################################################################################
-- ###########################################################################################

-- ### Der Batch-Delimiter 'GO' als Verhinderer von Stolpersteinen

-- ######################################################

-- GO ist kein TSQL-Befehl, sondern eine Anweisung f?r den Editor

ALTER proc gpdemo1 
as
select getdate()
GO					--< GO = END
exec gpdemo1

-----------------------------------------------------------------

	#isso #magic #microsoft
	-- Rekursion wird nicht automatisch erkannt (Warnung, Unterbunden)
	-- Grenze der Rekursion = 32 = 0 + 31 Durchl?ufe 

-- ######################################################

-- Variablen-Verhalten innerhalb eines Batch-Aufrufes

-- ######################################################

declare @var1 as int = 1
select @var1
GO				--< RESET Variablen-Definition (DROP!)
select @var1 

-----------------------------------------------------------------

-- GO bedeutet das "Ende" des AnwendungsBatches > Parallelit?t / Infos zum SELECT anbelangt

	CTEs = Common Table Expressions

	WITH [cteTable]
	AS ( Select .. From .. JOINS ... )
	UPDATE ...
	FROM [cteTable] 
	...

	with cteDifference				-- Wesentlich g?nstiger als ZEILENWEISES UPDATE wie gerade oben dr?ber, das SPALTENWEISES Update
	as (							-- Bei FILTERUNG schl?gt es um, da dann ZEILENWEISES Update wesentlich effektiver beim Vergleich
	select
		ORIGINAL.RequiredDate as referenceColumn
		, KOPIE.RequiredDate as differenceColumn
	from Sales.Orders as [ORIGINAL] inner join dbo.myOrders as [KOPIE] on [ORIGINAL].OrderID = [KOPIE].OrderID
	)
	--select * from cteDifference									-- Vergleich
	update cteDifference set referenceColumn = differenceColumn  	-- Korrektur
	
-- ###########################################################################################
-- #### Erkenntnis #4 : Batch-Delimiter 'GO' essentiell f?r Fehler-freie TSQL-Ausf?hrung #####
-- ###########################################################################################

-- Alles, was markiert ist, wird als EIN Batch verstanden und im Ganzen ausgef?hrt
-- GO unterteilt den Batch in SubBatch-Aufrufe, die einzeln (Ergebnis, Message,...) ablaufen
-- Besonders bei allen funktionsartigen Aufrufen ist das ESSENTIELL, um Fehler zu vermeiden
-- Variable gilt nur w?hrend EINES Batches, also ohne GO da und mit GO weg!

-- ###########################################################################################
-- ###########################################################################################
-- ###########################################################################################

-- ##### Fazit :: Ausf?hrungspl?ne

-- ######################################################
/*

	erkl?rt nur, wo SQL die Daten holt, wie er sie holt und was er damit macht
	> jeder Plan stellt einen Batch dar, der 100% Leistung verbraucht
	> die 100% Leistung werden auf die automaren Aktionen verteilt

	ein Plan kann l?gen --> Unterschied zwischen gesch?tztem und tats?chlichem Plan
	> vor allem bei FUNCTION(), denn die werden in tats. Pl?nen oft nicht mehr angezeigt!
	> ein Plan kann durchaus mal sagen, dass Batch^1 g?nstiger w?re als Batch^2 (Heuristik!)
	> die Messung kann das Gegenteil zeigen, also dass Batch^1 g?nstiger als Batch^2 ist
*/

-- ######################################################

-- ##### Messen und Logischer Fluss in den Abfragen #####

-- ######################################################

-- Statistik ?ber das Messen der I/O-Zugriffe und der Zeiten --> nur Aussage ?ber das WIE
-- anhand von Zeiten kann man NICHT sagen, ob er die Daten gut oder schlecht verarbeitet hat
-- Es ist Aufgabe des PLANs, um das WO und WAS zu bewerten also ob Ablauf gut oder schlecht ist

-- ######################################################

-- ### statistische Abfrage zu I/O einschalten

set statistics io, time on -- ZENTRALES Einschalten der Messung

select * from orders where freight < 10		--> SPEICHERSEITEN!! (siehe Beispiele oben ^ )

-----------------------------------------------------------------

	' nur die Statistik ergibt SERVER-?bergreifend objektive Werte '

-- ######################################################

-- ### Speicherverhalten :: Seiten / Bl?cke / RAM-Belastung

-- ######################################################

/*
	SQL Server speichert Datens?tze in Seiten
	eine Seite hat 8 kiloByte = 8192 Byte  ::  Theoretischer Speicher
							  -  132 Byte  ::  Overhead f?r jew. Seite
							-------------------------------------------
					NENNGR??e   8060 Byte  ::  Check beim Anlegen der Daten
							  -    7 Byte  ::  Overhead pro Datensatz
							-------------------------------------------
					MAXIMAL	    8053 Byte  ::  Nutzlast  f?r Datens?tze
*/

create table t1 (id int identity, SpalteX char(4100), SpalteY char(4100)) 
--					11		+					4100		+		4100 = 8211 > 8060 -- FUCK YOU
	' Grunds?tzlich muss ein Datensatz in eine Speicherseite passen! '

create table t1 (id int identity, SpalteX VARchar(4100), SpalteY char(4100)) 
	' VARCHAR ist flexibel, nimmt so viel Platz ein wie sie braucht > Minimal als 0.00 Byte '

				[Nachname]
CHAR(10)		'Krause....'	10 Byte	 ; 64kByte	+ TRIM() + RIGHT()  + LEFT()  + LEN()
VARCHAR(10)		'Krause'		06 Byte

UPDATE [Nachname] SET 'Bergmann'

CHAR(10)		'Bergmann..'	10 Byte
VARCHAR(10)		'Bergma'		06 Byte  + Appendix_1   (EXTENT)	; 64kByte
...
..
.
Appendix_1		'nn'			02 Byte ; 64 kByte


NCHAR(10)		N'Kr?u?el...'	10 + 10 Byte ; 64 kByte
NVARCHAR(10)	N'Kr?u?el'		07 + 07 Byte ; 64 kByte 

	' Kann man das nachtr?glich ?ndern? Ja, schon... ABER: TABLE RE-CREATION !! '

-- ######################################################

-- ##### Hinzuf?gen neuer Datens?tze #####

-- ######################################################

drop table if exists dbo.person
go

create table dbo.person (personID int identity, fName nvarchar(50), lName nvarchar(50))
go

-- Insert  mit Skalarwerten

set statistics io, time off		-- Messung w?rde Ergebnis verf?lschen
set nocount on					-- Interne Z?hlung von betroffenen Zeilen
go	

-- Single-Line-Insert
declare @starttime datetime2(7)
declare @RunningTime int
set @starttime = sysdatetime()
insert into dbo.person (fName, lName)
	values ('Apu', 'Nahasapeemapetilon')
insert into dbo.person (fName, lName)
	values ('Majula', 'Nahasapeemapetilon')
insert into dbo.person (fName, lName)
	values ('Sanjay', 'Nahasapeemapetilon')
set @RunningTime = DATEDIFF(ms, @starttime, sysdatetime())
print 'Ausf?hrungszeit mehrerer Einzelinserts: ' + cast(@runningtime as nvarchar(5))

-- Multi-Line-Insert
set @starttime = sysdatetime()
insert into dbo.person (fName, lName)
	values ('Homer', 'Simpson'), ('Marge', 'Simpson'), ('Bart', 'Simpson'), ('Lisa', 'Simpson'), ('Maggie', 'Simpson')
set @RunningTime = DATEDIFF(ms, @starttime, sysdatetime())
print 'Ausf?hrungszeit Multi-Insert: ' + cast(@runningtime as nvarchar(5))
go

-- INSERT INTO (Anh?ngen von Zeilen an bestehende Tabelle)

declare @starttime datetime2(7)
declare @RunningTime int
set @starttime = sysdatetime()
insert into dbo.person (fName, lName)
	select firstname, lastname from [AdventureWorksDW2014].dbo.DimEmployee as emp		-- Sub-Query als Derived Table Expression
set @RunningTime = DATEDIFF(ms, @starttime, sysdatetime())
print 'Ausf?hrungszeit Insert-Select: ' + cast(@runningtime as nvarchar(5))
go

select COUNT(*) FROM [AdventureWorksDW2014].dbo.DimEmployee

-- SELECT INTO (Erzeugen einer neuen Tabelle, bereits bef?llt mit Daten)

drop table if exists dbo.[Order Details Revised]
go

select COUNT(*) from AdventureWorksDW2014.dbo.FactInternetSales

declare @starttime datetime2(7)
declare @RunningTime int
set @starttime = sysdatetime()
select
	*
	into dbo.[Order Details Revised]			-- TempTabObj / #Table
from AdventureWorksDW2014.dbo.FactInternetSales
set @RunningTime = DATEDIFF(ms, @starttime, sysdatetime())
print 'Ausf?hrungszeit Select-Into: ' + cast(@runningtime as nvarchar(5))

select * from dbo.[Order Details Revised]

-- ###########################################################################################
-- #### Erkenntnis #5 : Speicher-Adressierung ist fundamental f?r die Optimierungsoption #####
-- ###########################################################################################

-- VARCHAR ist flexibel, nimmt so viel Platz wie sie braucht
	-- Fingerzeig zu sp?ter :: SHIT after UPDATE & SHIT after ALTER  
-- PAGING-Struktur essentiell bereits beim Einlesen / Updaten / ?ndern der Datens?tze
	-- mehrere Seiten am St?ck (8) nennt man Block
	-- eine Seite kann nie mehr als 700 Datens?tze haben
	-- eine Seite sollte immer sehr gut gef?llt sein --> Seiten kommen 1:1 in dem RAM-Speicher
	-- SQL liest IMMER vom RAM Speicher und NIE direkt vom Datentr?ger
-- PAGEs und EXTENTs
	-- SQL liebt blockweise Lesen --> Festplatte 64k formatieren --> Festplatten liest blockweise
	-- logische Lesevorg?nge sind die Seiten, die SQL Server erst noch holen musste
-- OBERSTES ZIEL :: ANZAHL DER SEITEN REDUZIEREN
	-- je weniger Seiten, desto weniger CPU-Einsatz, desto weniger RAM-Verbrauch
	-- ESELSBR?CKE "Einkaufen" :: gro?er Wagen im Supermarkt
		-- > man will vermeiden viele kleine Einkaufswagen zu nehmen
		-- > vorzugsweise keine kleine H?ppchen immer wieder holen
		-- > Einsatz des Wagens weniger aufwendig, auch wenn mehr Daten (-Platz) als gefragt

-- ###########################################################################################
-- ###########################################################################################
-- ###########################################################################################

-- ######################################################

-- ##### DB-Design - Mehr als "nur" Normalisierungen ####

-- ######################################################

/*
-- Normalisierung :: 1.NF bis 3.NF ist OK, dar?ber eher akademisch als allt?glich n?tzlich
-- Generalisierung :: Gleichartige Daten an einem Ort 
	-- > (Lieferanten, Kunden, Angestellte) <~>  Anschrift [ STRASSE | PLZ | ORT ]
-- Extrahierung :: Validiereren von Daten durch [ PLZ | ORT ] , um Fehler zu korrigieren
	-- > Daten die in mehreren Tabellen gleichartig vorkommen, werden extrahiert
	-- > macht keinen Sinn, MasterData Quality Service macht so was, ansonsten nicht extrahieren
-- Redundanz :: Gegenteil von Normalisierung
	-- > Bewusst Daten doppelt vorhalten, da Redundanz sehr schnell f?r die Auswertung
	-- > Deshalb bitte bewusst die 3.NF
*/

-- ######################################################

-- ##### NORMALISIERUNG : GRAD 1 --> automare Werte

	[ A | 1 , 2 , 3 , 1 , ... ]   [ B | 5 , ... ]

	[ A | 1 ] [ A | 2 ] [ A | 3 ] [ A | 1 ]   ...   [ B | 5 ] ...

	-- > zusammengesetzte Attribute schlecht f?r Such-Anfragen

-- ##### NORMALISIERUNG : GRAD 2 --> Eindeutigkeit durch PRIMARY KEY

		[ A | 1 ] -- l?schen von DS die gleich sind geht nicht
		[ A | 2 ]
		[ A | 3 ]
		[ A | 1 ] -- ERROR-MESSAGE :: zu viele ?nderungen in Datenbank

	
	[ 1 | A | 1 ] -- jetzt geht es da es nicht dopplet vorkommt
	[ 2 | A | 2 ]
	[ 3 | A | 3 ]
	[ 4 | A | 1 ]

	-- > Eindeutigkeit der Werte macht Datenmanipulations erst m?glich

	
-- ##### NORMALISIERUNG : GRAD 3 --> Keine Abh?ngigkeit der Spalten untereinander

	Kunde [ PLZ | ORT ] 
	--> ORT ?ndert PLZ , aber PLZ ?ndert nicht zwingend ORT (M?nchen, Berlin,...)
	--> schnell im schreiben (neuer) Datens?tze, aber Vollst?ndigkeit nur ?ber JOINs

-- ##### NORMALISIERUNG : GRAD 3 sollte man bewusst VERLETZEN durch die REDUNDANZ

	Kunde [ Land ] : 1 MIO Kontakte mit durchschnittlich 2 Bestellungen
	Bestellungen   : 2 MIO Eintr?ge mit durchschnittlich 2 Positionen pro Bestellung
	Positionen     : 4 MIO Bestell-Details [ Menge * Preis ]

	Umsatz pro Land eines Kunden
	--> JOIN ?ber ALLE Tabellen :: Redundanz-freier Ansatz
		7 MIO Datens?tze, die angefasst werden m?ssen, um Auswertung m?glich zu machen
	--> REDUNDANZ :: Bestellung [ BestellSumme ] als zus?tzliche Information
		3 MIO Datens?tze, weil die Tabelle Positionen nicht notwendig f?r Auswertung

-- Data Warehouse macht ganz viel Redundanz, um keine JOINs zu machen --> spart enorme Rechenzeit

-- ###########################################################################################
-- #### Erkenntnis #6 : Verletzte 3.NF ist die Idealform einer Datenbank im REALEN Leben #####
-- ###########################################################################################

-- Gutes Mass ist das Mittelding : Redundanz ist gut, muss aber gepflegt werden (vergiss INDEX nicht!)
	-- > ?nderung der Bestell-Details [ Menge ] forciert keine ?nderung der [ Bestellsumme ]
	-- > Trigger (schlechte Performance) | Softwarel?sung (im Regelfall unsicher, also nur intern)
-- #Temp tabellen sind auch redundant
	-- > Ergebnisse rausziehen als #Temp hat weniger Daten und wird nur (einmal) geladen
	-- > #Temp wird immer wieder abgefragt (reduzierte Datenmenge), diese sind aber doppelt
-- Was ist mit der Physik?!
	-- > vergesst Seiten und Bl?cke nicht!
	-- > KEINER schaut sich bei der Normalisierung Seiten und Bl?cke an!

-- ###########################################################################################
-- ###########################################################################################
-- ###########################################################################################

-- ### DoomsDay-Beispiel :: Seiten wichtiger als Normalform

-- ######################################################

drop table if exists dbo.tab1
go

create table tab1 (id int identity, SpalteX char(4100)) -- sehr breite Tabelle
	-- CRM hat meist sehr breite Tabellen
	-- Spalten wie : fax1, fax2, fax3, Hobby1, Hobby2, Frau1, Frau2, Frau3, Frau4, Religion

	INSERT INTO [Tab1]
	SELECT 'xx'
	GO 20000					-- 20.000 x 8kB = 160 MB

	SELECT * FROM [Tab1]

-- ### Show Contingent : Seiten | Bl?cke | ScanDichte | SeitenDichte | ...

dbcc showcontig('Tab1') 

'- Pages Scanned................................: 20000  >> PAGE-Optimierung'
- Extents Scanned..............................: 2501
- Extent Switches..............................: 2500
- Avg. Pages per Extent........................: 8.0
'- Scan Density [Best Count:Actual Count].......: 99.96% [2500:2501] >> INDEX = effizientes SEEK'
- Extent Scan Fragmentation ...................: 0.16% .... 41.03%
'- Avg. Bytes Free per Page.....................: 3983.0 >> Normalisierung >> Anzahl DS pro PAGE'
'- Avg. Page Density (full).....................: 50.79% >> COLUMN TYPES?!'

set statistics io, time on		

	SELECT * FROM [Tab1]


-- ### SpeicherBericht

DatenBank > Berichte > Standardberichte > Datentr?gerverwendung durch oberste Tabellen
DataBase  > Reports  > Standard Reports > Disc Usage by TOP Tables

-- ### Hochskaliertes Problem

	' Normalisierung sollte das Ergebnis von PAGE-Optimierung sein 
	  > CHAR(10) vielleicht eine bessere Idee ist als NVARCHARMAX
	  > bei sehr breiten Tabellen bitte Unrelevantes z?gig auslagern! '

--- ### ReFactoring : ReDesign durchf?hren

	statt char lieber varchar 
	statt EINER sehr breiter Table lieber zus?tzliche AuslagerungsTabellen 

create table tab1 (id int identity, SpalteX char(4100)) -- sehr breite Tabelle

--> 1 Datensatz braucht ca. 4100 Bytes ; f?r 1 MIO Datens?tze hochskaliert
--> lass uns doch mal 100 Byte "auslagern" in eine zweite Tabelle (2 DS in Prim?rTable Platz haben)
-- 1.000.000 x 8kB = 8.0 GB = 1.000.000 PAGES
	
					'8.0 GB' Speicherbedarf
	[ Tabelle A ]    <<  SPLITTEN  >>       [ Tabelle B ]
	2 DS / Page (8050 / 4000)				80 DS / Page (8050 / 100)
	500.000 Pages							12.500 Pages (1 MIO / 80 )
	4.0 GB									100 MB (12.500 x 8kB)
					'4.1 GB' Speicherbedarf

-- ###########################################################################################
-- ### RoadMap f?r die Planung der Optimierung von Datenbank-Struktur und Abfrageverhalten ###
-- ###########################################################################################

-- Standardbericht > Datentr?gerverwendung
	-- > Tabellen mit gro?er Anzahl an Datens?tze / gro?e Tabellen finden
-- dbcc showcontig() 
	-- > zeigt komplette Statistik f?r alle Tabellen an
	-- > untersuchen DatenDichte sowie Seitenanzahl
	-- > ggf. umstrukturieren (ReDesign)
-- Art des ReDesigns w?hlen > m?gliche FehlerQuellen im Auge behalten
	-- > APP geht nicht mehr :: DatenTyp anpassen, Spalten auslagern,... (ReDesign)
	-- > APP wei? nix davon  :: Komprimierung (SHRINK DATABASE) als Sofort-Ma?nahme besser

-- ###########################################################################################
-- ###########################################################################################
-- ###########################################################################################

-- ### Schlechtes Design eruieren > Diagramm auslesen

-- ######################################################

	Diagramm -> Tabellenansicht -> Modify Custom -> SpaltenName | DatenTyp-Kurz | NULL zulassen | Identit?t
	alles markieren -> rechtsklick -> benutzerdef. anzeigen -> IDENTITY auslesen

-- ######################################################

-- ### Schlechtes Design eruieren > DatenTyp ?ndern

-- ######################################################

	nicht immer ist gesagt, dass es klappt mit Ma?nahmen deutlich viel einzusparen
	Tools -> Options -> Designers -> Table Designer.. -> 'Prevent saving changes..'
	Beispiel: Table [DESIGN] -> date statt datetime -> ?nderungsskript generieren...

-- ######################################################

-- ### Schlechtes Design eruieren > DB-Komprimierung

-- ######################################################

-- Voraussetzung f?r Messung:

	drop table tab2
	create table tab2 (id int identity, SpalteX char(4100))
	GO
	insert into tab2
	select '##'
	GO 20000

	set statistics io, time on
	select * from tab3

	< Tab1 > 160 MB	RAW					< Tab 2 > 40% - 60% ROW			< Tab 3 > 80% - 90% PAGE
	logical reads 20000					logical reads 33				logical reads 33
	CPU time = 547 ms					CPU time = 422 ms				CPU time = 422 ms
	elapsed time = 2529 ms				elapsed time = 2478 ms			elapsed time = 2478 ms
	RESULT = 160 MB						RESULT = 160 MB					RESULT = 160 MB
	
	--> in unserem Fall kein weitere Vorteil durch PAGE COMP, da "nur" ## als Datensatz vorhanden
-- Kompression

	KompressionsTypen | ROW <> PAGE
	ROW 
		untersucht zeilen auf Leerzeichen und schmeisst die raus
		zieht alles zusammen, wodurch es werden weniger Seiten werden 
	PAGE
		macht zuerst ROW
		danach Mustererkennung und versucht nach diesem Muster zu ersetzen
		Beispiel: [ Deutschland = D ] und verpackt es dann gem?? 'ZIP'-Muster

--	RAM : ungef?hr gleich geblieben
	-->	Seiten werden 1:1 in RAM, daher werden die komprimierten Seiten (28) in RAM gelegt

--	CPU : stark schwankend
	--> deutlich weniger Seiten --> CPU weniger
	--> Daten m?ssen DEKOMPRIMIERT zum Client kommen (sqlservr.exe) --> hier steigt CPU
	--> im Regelfall wird CPU unterm Strich h?her ausfallen > DeKompilierung durch DeKompression

-- Dauer : ungef?hr gleich
	--> die Dauer w?rde ansatzweise gleich blieben (man spart, aber dann kommt DeKompression)
	--> gro?e Datenmengen m?ssen zum Client gebracht werden (160MB dekomprimiert)

-- ###########################################################################################
-- #### Erkenntnis #7 : Tausche Speicher gegen Rechenzeit, profitiere selbst aber nicht ######
-- ###########################################################################################

-- Kompression bringt mehr RAM, kostet aber CPU
-- die komprimierten Tabellen profitieren nicht davon, da Dekomprimierung notwendig f?r APP
-- der lachende Dritte sind ANDERE Tabellen, die jetzt auch Platz im RAM finden
-- Auswertungshilfe
	--> CPU-Zeit deutlich gr??er als verstrichene Zeit = Parallele Abarbeitung
	--> verstrichene Zeit deutlich gr??er als CPU-Zeit = Lesen dauert l?nger als Verarbeiten

-- Standard-Ansatz f?r Archiv-Tabellen
	--> selten genutzte Tabellen, die sich gut komprimieren lassen
	--> Seiten-Reduktion ist eigentlich gro?er Vorteil der Verkleinerung

-- INDEX zielf?hrender, um TABLE-SCAN zu vermeiden
	--> ALLE Datens?tze m?ssen nach wenigen Daten durchsucht werden
	--> fehlender INDEX erzwingt Daten komplett in RAM zu laden > Komprimierung sehr sinnvoll

-- Komprimierung findet im Regelfall nur einmal statt
	--> neue Datens?tze werden NICHT mit-komprimiert, Alt-Bestand bleibt komprimiert
	--> nur bei CLUSTERED INDEX werden auch neue Datens?tze beim Einlesen mit-komprimiert

-- Ganze Datenbanken lassen sich nicht komprimieren (sonst 100% CPU-Leistung)
	--> SQL Profiler : ALLES f?hrt zu SpeicherVerbrauch (Aufrufen von DB-Eigenschaften)
	--> JEDER Klick mehr w?rde MEHR CPU-Leistung erfordern als vorher (Dekomprimierung)

-- ###########################################################################################
-- ###########################################################################################
-- ###########################################################################################

-- ###### MAXDOP = MAXimum Degree Of Parallelism ########
					'ENTERPRISE FEATURE'
-- ######################################################

USE [Northwind]
GO

select * from dbo.KundeUmsatz

SELECT * INTO demo1 FROM dbo.KundeUmsatz
GO
ALTER TABLE demo1 ADD ID INT IDENTITY
GO
SELECT * INTO demo2 FROM dbo.KundeUmsatz
GO
ALTER TABLE demo2 ADD ID INT IDENTITY
GO

-- Server-Eigenschaft > Schwellenwert f?r Parallelit?t 

set statistics io , time on

SELECT City
	,  SUM(Freight)
FROM dbo.KundeUmsatz
GROUP BY City

SELECT D1.City
	, SUM (D2.Freight)
FROM dbo.demo1 AS D1 INNER JOIN dbo.demo2 AS D2 ON D1.CustomerID = D2.CustomerID
GROUP BY D1.City

	TSQ-$		CTP		MaxDoP		CPU-TIME		TIME
	78 $		005 $	8 CPU		3249 ms			1290 ms
	88 $		100 $	1 CPU		2125 ms			2335 ms
	78 $		50 $	4 CPU		3031 ms			1770 ms

-- ### Maler-Beispiel #########################################################################

	-- Problem: je mehr man Maler holt, desto schwieriger wird es es zu organisieren!!
	-- Irgenwann stehen Maler sinnlos herum oder treten sich auf die F??e
	-- Kein anderer kann einen Maler haben, solange alle nur bei einem sind und das nicht effektiv

-- ### das l?sst sich auch per Befehl einstellen (Zeit-basiertes Umstellen von Server-Einstellungen!)

EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'cost threshold for parallelism', N'25'
GO
EXEC sys.sp_configure N'max degree of parallelism', N'4'

-- ### auch in TSQL MAXDOP einsetzbar

select * from orders
where orderid = 10333

select * from orders 
where orderid = 10333 option (maxdop 4) --nimm nicht mehr als 4 ,

-- ###########################################################################################
-- #### Erkenntnis #8 : Viel hilft viel ist ein Irrglaube, was SQL-Parallelit?t anbelangt ####
-- ###########################################################################################

-- Zun?chst verwendet der SQL Server alle CPUs, die er physisch findet
	-- > SQL SVR hat Aufwand das zu verteilen, weshalb der Overhead gr??er als Nutzen sein kann
	-- > CXPACKET (Class Exchange Package) Ereignis sobald Parallelit?t zustande kommt
	-- > Je mehr Threads man startet, umso aufw?ndiger ist die Organisation der einzelnen Teile
-- Es gibt eine Optimale Einstellung im Zusammenspiel zwischen CTP und MaxDOP
	-- > CTP = Cost Threshold for Parallelism = SQL$-Schwelle, ?ber der er erst parallelisiert
	-- > MaxDOP = Maximum Degree of Parallelism = wie viele CPU-Kerne d?rfen verwendet werden
	-- > Nach ?ndern der Werte IMMER einige Male die Abfrage laufen lassen f?r Kompilierung
-- Aktualisierung der Server-seitigen Einstellungen bzgl. CTP und MaxDOP
	-- > Die Werte lassen sich jederzeit ?ndern und gelten erst ab der N?CHSTEN Abfrage
	-- > Bestehnde Abfragen sind NICHT betroffen und k?nnen zur Laufzeit das nicht ab?ndern
	-- > Deshalb lieber TSQL MaxDOP Options w?hlen, um das "im Kleinen" zu testen
-- Faustregeln, da CTP von 005 SQL$ im Standard einfach absurd wenig ist
	-- > OLTP (ShopSystem) 50% der CPUs und setze CTP auf 25
	-- > OLAP (DatenBank)  CTP auf 50 und 25% - 75% CPU

-- ###########################################################################################
-- ###########################################################################################
-- ###########################################################################################

-- ###### INDIZES, INDIZES, INDIZES, INDIZES, ... #######

-- ######################################################

-- ### Typisierung

	HEAP  :: 'unsortierte' Daten 
				-> Sortierung entsteht durch Schreibvorgang

	INDEX :: '8053 Byte' Seite
				-> Entscheidet wie viele Seiten pro Index-Ebene verwendbar sind
				-> Objekt in Datenbank, das Speicher allokiert, um Anzahl der Speicherzugriffe zu verringern
				-> Im Idealfall ausbalancierter k-n?rer Baum wie im Telefonbuch ('vs. Mitarbeiter-Hierarchie')
	
	CLUSTERED INDEX :: physische Umsortierung und auch Abspeicherung / Aktualisierung
	COMBINED CLUSTERED INDEX :: mehrere Spalten als ein gemeinsamer Index (PRIMARY KEY COLUMN) 

	NONCLUSTERED INDEX  :: NON CL IX :: VerzeichnisBaum aus VerweisStruktur auf phyischen Speicher der Daten
	CLUSTERED INDEX		::     CL IX :: Daten werden gem?? der Struktur PHYSISCH neu abgelegt bzw. einsortiert

2.     CL IX immer zuerst vergeben auf "Bereichsspalten"
1. NON CL IX						--> wenn RELATIV WENIG rauskommt (ID Spalten , GUID, PK..etc..) 
--------------------------------------------------------
	   Grouped Columnstore Index
	NonGrouped Columnstore Index	--> je weniger Daten bei Anfrage herauskommen, umso g?nstiger
--------------------------------------------------------

	zusammengesetzter IX					'COMBINED'
	IX mit eingeschlossenen Spalten			'INCLUDING' -- TOP INDEX
	gefilterter IX							'FILTERED'	-- schneller weil kleiner
	partitionierter IX									-- Partionierung
	eindeutiger IX							'UNIQUE'
	abdeckender IX							'COVERED'
	indizierte Sicht									-- INDEX auf VIEW
	real hypothetischer IX								-- macht ein Analyser-Tool

--------------------------------------------------------

select * from sys.indexes		 --< welche Indizes kennt die Datenbank

dbcc IND(0, 'dbo.KundeUmsatz',1) --< welche Index-Struktur hat die Tabelle

--------------------------------------------------------

select newid()					--< Beispiel f?r General Unique ID (GUID)

--------------------------------------------------------

-- ### Verschiedene Indizes einfach mal durchprobiert

select * into kundeumsatz2 from dbo.KundeUmsatz -- Kopie Tabelle in eine neue Tabelle

-- ### SCAN HEAP

SELECT * FROM dbo.KundeUmsatz					-- PAGES: 57.000

	ALTER TABLE dbo.KundeUmsatz ADD [kid] INT IDENTITY(1,1)

SELECT * FROM dbo.KundeUmsatz WHERE kid = 1000	-- PAGES : 57.000

	' NONCLUSTERED INDEX [kid] UNIQUE '

SELECT kid FROM dbo.KundeUmsatz WHERE kid = 1000	-- PAGES : 3

SELECT * FROM dbo.KundeUmsatz WHERE kid < 1000		-- PAGES : 4

-- ### INTERMEZZO 1 -- schreibe KEINE benutzerfreundlichen Prozedures

CREATE PROC demo @kid INT
AS
SELECT * FROM dbo.KundeUmsatz WHERE kid < @kid

EXEC demo 1000000									-- 3.2 $  1.000.000		40sec

SELECT * FROM dbo.KundeUmsatz WHERE kid < 1000000	-- 32  $  57.000 PAGES	40sec

-- ### INTERMEZZO 2 -- Query Store f?r Ablaufpl?ne

 ' wird pro Database aktiviert > muss erst Daten sammeln, dann Auswertung m?glich
   Ablaufpl?ne (ID) f?r Query (ID) nach Aufwand (Waits) und Ressourcen (CPU,...) analysieren'

-- #################################################

SELECT kid,companyname FROM dbo.KundeUmsatz WHERE kid = 1000

	' COMBINED : idx_nc_[kid,cname] '

	' einfach alles in den COMBINED INDEX aufnehmen? Lieber nicht! '
	-- MAXIMAL 16 Spalten sind viel zu viel und w?rden den Index unn?tig aufbl?hen
		-- MAXIMALE Schl?sselL?nge := 900 Byte #isso #microsoft #ibm
	-- in PRAXIS kaum vorstellbar, so viele Infos tats?chlich zu ben?tigen (i.d.R. 4 OK)
		-- DEUTLICH WENIGER berausfiltern, genau 1 ist oft ?BER-OPTIMERUNG
		-- UNIQUE = EINDEUTIGKEIT in Kombination > EFFEKTIV & EFFIZIENT
		-- Bsp. "Lee" hinreichend eindeutig bei Land > Stadt > Adresse 
		-->>>>> RELATIV wenige LOGICAL READS ist das Ziel, nicht COUNT = 1

	' INCLUDING INDEX -- fast das Optimum in puncto Index-Gestaltung '
	-- dieser Index-Typ "belastet" nicht den kompletten Index, sondern macht die Bl?tter "fett"
		-- der Rest kann ?ber TABLE LOOKUP nachgeschlagen werden 2010:1011:705:03 - Dieter (EXCEL)
		-- MAXIMAL 1.000 Spalten hinzuf?gbar in die INCLUDING COLUMNS

	' COVERED INDEX '
	-- akademisches Theorem = kannst Du nicht bewusst, sondern "passiert halt" 
		-- wenn Abfrage = INDEX > SELECT, dann "deckt" der Index die Abfrage ab = COVERED
	
	' UNIQUE COVERED NonClustered Index [kid] INCLUDING [cname] '

SELECT kid,companyname FROM dbo.KundeUmsatz WHERE kid = 1000
	-- man kann Abfragen "an-trainieren" einen bestimmten INDEX zu nutzen
SELECT kid,companyname FROM dbo.KundeUmsatz WITH (INDEX = [INCLUDING]) WHERE kid = 1000

	-- 6 / 7 PAGES sind das theoretische Optimum f?r LOGICAL READS
	-- wenn ich zu oft auf den Standard "zur?ckfalle" = PK-INDEX, dann l?uft was schief hier!

-- ## HowTo INDEX

SELECT						-- Voraussetzung = ich frage REGELM??IG DANACH!! 
	kid
	, companyname			-- nach diesen Infos frage ich ZUS?TZLICH = EINGESCHLOSSEN = INCLUDING
	, city
FROM dbo.KundeUmsatz		-- RAW DATA
WHERE kid = 1000			-- FILTERN > INDEX > Schl?ssel-Spalten 

	' INDEX SEEK = gezieltes Finden INNERHALB des Index-Baumes
	  INDEX SCAN = Suchen innerhalb von BL?TTERN, aber immer noch weniger als RAW DATA
	  TABLE LOOKUP = EINZELNE Datans?tze / Sachverhalte nachschlagen in RAW DATA
	  TABLE SCAN = stumpf Suchen durch ALLE PAGES der RAW DATA '

SELECT
	companyname
	, Productname
FROM dbo.KundeUmsatz
WHERE shipcity = 'Berlin'


SELECT						
	kid
	, companyname			
FROM dbo.KundeUmsatz		
WHERE kid = 1000	
	OR country = 'Germany'

dbcc showcontig ('Kundeumsatz')

-- Statistics: 56990 Pages ; 3628 ms TIME ; 19 DS / Page ; 300-400 Byte / DS
-- FULL 56990 Pages insgesamt ; 41901 PAGES mit Content ; 98.18% DENSITY Page ; 0.02% Appendix
-- 32 TSQL-$ -- das ist ineffizient ; CPU time = 484 ms,  elapsed time = 3640 ms

SELECT						
	kid
	, companyname			
FROM dbo.KundeUmsatz		
WHERE kid = 1000			-- INDEX SEEK > wir sind fertig

SELECT						
	kid
	, companyname			
FROM dbo.KundeUmsatz		
WHERE country = 'Germany'   -- INDEX SEEK > wir sind chic (neuer Index!)

c
-- Statistics: 9756 Pages ; 3796 ms TIME ; 19 DS / Page ; 300-400 Byte / DS
-- FULL 56990 Pages insgesamt ; 41901 PAGES mit Content ; 98.18% DENSITY Page ; 0.02% Appendix
-- 8.4 TSQL-$ -- das ist ineffizient ; CPU time = 375 ms,  elapsed time = 3796 ms

>> Theoretisches Optimum erreicht? 'COVERED INDEX SEEK' >> 2. Platz, aber auch OK

>> Wie w?rde Theoretische Optimum aussehen? SEEK + MERGE JOIN + SEEK 'nicht erreichbar'. Warum?
-- wir fragen nach mehr als 10% aller Daten in der Tabelle --> sei gl?cklich ?ber INDEX SCAN!!

SELECT						
	kid
	, companyname			
FROM dbo.KundeUmsatz		
WHERE kid = 1000	
	OR country = 'Germany'

	' OR >> einzeln optimieren und auf das Beste hoffen (ausprobieren!) '
	-- wenige Daens?tze im INDEX > gute Laufzeit
	-- INDEX muss auch mal ERNEUERT werden, sonst "alte" Optimierung = REBUILD >> 0.02 TSQL-$

SELECT
	companyname
	, city
FROM dbo.KundeUmsatz
WHERE customerid LIKE 'W%'
	AND country = 'Finland'

	' AND >> welcher Aspekt ist relevanter? '
	
SELECT * FROM dbo.KundeUmsatz WHERE customerid LIKE 'W%'			-- 80.000
SELECT * FROM dbo.KundeUmsatz WHERE country = 'Finland'				-- 27.500

	' NON CL IDX [custid] INCL [cname, city] FILTERED [country = 'Finland'] '

-- ### DER HIGHLANDER = CLUSTERED INDEX >> wie schreibe ich die Daten in die HDD 
					
	'CL ist gut f?r Bereichsabfragen, aber PK ist eindeutig; ID ; aber wir verlieren durch PK als CL IX 
	auf ID Spalten, die M?glichkeit	den CL IX auf Spalten zu vergeben, die h?ufig mit Bereichsabfragen
	untersucht werden >>> PK muss NICHT ein CUSTERED INDEX sein!!

	DESIGNER der Tabelle -> Rechtsklick -> Indizes/Schl?ssel --> Als Clustered erstellen - Nein --> Ersetzen

	Regel: versuche zu erst den CL IX zu vergeben und dann setzte den PK, da immer gut f?r Bereichsabfragen! 
	ODER erstelle Tabellen von Hand und schreibe beim PRIMARY KEY gleich NONCLUSTERED hinein'

	-- ###########################################################################################

-- ### Praktische Umsetzung : Gute Idee / Schlechte Idee bez?glich der Abfragen

-- FRAGE | Wie l?uft die Abfrage? Gut oder schlecht? Warum? Was k?nnte man verbessern?
-- IDEE  | Ablaufplan > Index 

USE [Northwind]
GO

SELECT CompanyName, Freight, Country
FROM Customers AS C
	INNER JOIN Orders AS O ON C.CustomerID = O.CustomerID
WHERE C.ContactTitle LIKE '&manager%'
		OR 
		O.Freight < 10
		AND
		EmployeeID in (1,3,5)


-- ###########################################################################################
-- ##### Erkenntnis #9 : Alles steht und f?llt mit INDEX-Pflege und dem CLUSTERED INDEX ######
-- ###########################################################################################
/*
-- SQL SVR erstellt keine nutzbaren Indizes automatisch, aber AZURE macht das im Hintergrund
-- INDEX ist kein Allheilmittel, aber ohne ist SEEK nicht m?glich und SCAN zwingend
	--> man kann nicht f?r jede denkbare Abfrage eine Indizierung vorhalten
	--> ohne INDEX ist Abfrage gezwungen, ALLE Daten einzulesen f?r ggf. nur EINEN Datensatz
-- F?r alles einen INDEX bauen oder alle Spalten in den Index aufnehmen ist keine gute Idee
	--> geht nicht, weil nur max 16 Spalten m?glich sind (max 900byte Schl?ssell?nge)
	--> in der Praxis kaum vorstellbar, dass man mehr als 4 Spalten ben?tigt f?r ix_NC Infos
	--> f?r jede Abfrage den idealen Index zu bauen, ist auf Dauer schlecht [INS / UPD / DEL]
-- Index-Typen
	--> CLUSTERED : immer zuerst vergeben auf "Bereichspalten"
	--> NONCLUSTERED : h?ufige (kombinierte) Filter f?r Abfragen
	--> COMBINED : nur f?r WHERE Spalten, alles andere macht keinen Sinn, in JEDER Ebene 
				   wenn im SELECT die Spalte gesucht wird, verhindert dieser einen LOOKUP
	--> INCLUDING : Informationen stehen erst in der untersten Ebene beim VerzeichnisBaum
					Der Baum bleibt klein, damit auch der Aufruf und die Info ist aber da
	--> COVERED : Sonderform des INDCLUDING > Abfrage kann mit SEEK und ohne einen einzigen
				  LOOKUP oder SCAN ; dieser IX ergibt sich, man kann ihn nicht "machen"
*/
-- ###########################################################################################
-- ###########################################################################################
-- ###########################################################################################

-- ######################################################

-- ###### Statistiken und Heuristik des Ablaufplans #####

-- ######################################################

	Statistiken: SQL Server macht bei jeder Abfrage Gebrauch von Statistiken (automatisch erstellt)
	SQL braucht eine Sch?tzung wieviele Datens?tze rauskommen > Entscheidung IX SEEK oder IX SCAN

-- Statistik-Tabelle : ESTIMATED vs ACTUAL Execution Plan

select * into o1 from orders

select * from o1 where orderid = 10250 

select * from o1 where shipcountry = 'UK' 

select * from o1 where shipcity = 'berlin' 

select * from o1 where freight < 1 

-- ### Automatische Index-Erstellung durch Statistik (gr?ner Text im Ablauffenster)

select contactname , sum(freight) from kundeumsatz2
where employeeid = 5 or customerid = 'ALFKI'	--< Kein INDEX bei OR-Verbindung
group by contactname

dbcc showcontig('kundeumsatz2')

-- ######################################################

-- ###### COLUMNSTORE INDEX als "Traum-Index", oder?! ###

-- ######################################################

set statistics io, time off
select		productname, count(*) 
from		kundeumsatz
where		unitprice > 30
group by	productname

select		productname, count(*) 
from		kundeumsatz2				-- NEU ERSTELLEN!
where		unitprice > 30
group by	productname

	'GROUPED COLUMNSTORE INDEX'

	-- ARCHIVE COMPRESSION for COLUMNSTORE
	-- PAGE & ROW COMPRESSION for TABLE DESIGN

-- Spalten lassen sich deutlich besser komprimieren als Zeilen
-- bei Zeilen holt der SQL alles und es ist alles in Spalten hochkomprimiert!

-- Warum ist das so? Welche Nachteile ergeben sich?
-- was ist f?r jeden IX schlecht: Pflege (UPD / INS / DEL)

-- ###########################################################################################
-- ## Erkenntnis #10 : GROUP COLUMNSTORE INDEX ist ein Wunder-Index, aber mit Einschr?nkung ##
-- ###########################################################################################
/*
-- neue DS kommen nicht in den CS, sondern bleiben eine Zeit im delta_Store
	-- erwartet eine gewisse Zeit, und komprimiert nicht jeden neuen DS
	-- es sei denn, es sind 1 MIO DS in der Summe oder 140000 DS am St?ck; erst dann wird der
		Tupplemover (aus dem DeltaStor in Segmente ?berf?hren) die Kompression einleiten.
		Bis dahin ist delta_store = HEAP. Auch CS_IX wird komprimiert in den RAM geladen.
	-- F?r Archiv-Tabellen erster Kandidat (f?r RAM und CUP optimierter Index)'
-- Grenzen der Optimierung
	-- Index wird nicht genommen > Statistik versch?tzt sich oder es existiert anderen Index
	-- Indizierte Sicht ist kaum wirklich nutzbar (zu viele Einschr?nkungen)

-- erst ab SQL 2012 (Non-Grouped COLUMNSTORE INDEX) -> nicht updatebar mittels INS / UPD / DEL
-- ab SQL 2014 Grouped Grouped COLUMNSTORE INDEX -> automatisch updatebar
-- ab SQL 2016 SP1 sind viele Features von ENT in STANDARD und in EXPRESS gewandert
*/
-- ###########################################################################################
-- ###########################################################################################
-- ###########################################################################################

-- ######################################################

-- ###### Interne Auswertung aller verwendeter INDEX ####

-- ######################################################

select * from sys.partition_schemes
select * from sys.partition_functions
select * from sys.schemas
select * from sys.indexes

SELECT * FROM sys.dm_db_index_Usage_Stats		-- Statistische Auswertung der Indizes
WHERE database_id > 4							-- dies sind User-DBs (darunter Sys-DBs)

	-- index_id 0 = HEAP
	-- index id 1 = CL ID
	-- alle h?heren sind Nonclustered
	-- die schlechten ohne Seeks am besten l?schen!
	-- wenig lookups ist immer gut, werden mit der Hand erstellt

-- ### Tabelle-Index-Name SEIT SQL-SVR-Neustart!!

select * from sys.indexes --< Liste bekannter Indizes (unten Beachten VERWENDETER Indizes!) 

SELECT object_name ( i.object_id ) AS TableName
	, I.type_desc, I.name
	, US.user_seeks , US.user_scans, US.user_lookups, US.user_updates
	, US.last_user_scan, US.last_user_update
FROM sys.hash_indexes AS I
	LEFT OUTER JOIN sys.dm_db_index_usage_stats AS US
		ON I.index_id = US.index_id
		AND I.object_id = US.object_id
WHERE OBJECTPROPERTY ( i.object_id, 'IsUserTable' ) = 1
GO

dbcc showcontig ('kundeumsatz') 

-- ###### forwarded_record_count ####

-- Systemfunktion, die mehr Infos als DBCC liefert.

select * from sys.dm_db_index_physical_stats
	(db_id(),						-- aktuelle DB
	 object_id('kundenumsatz'),		-- von welcher TAB
	 NULL,							-- zus?tzl. Schalter
	 NULL,							-- zus?tzl. Schalter
	 'detailed'						-- VERBOSE MODE
	)

-- ##### Beispiel

set statistics io, time off

create table demoxy (id int identity, spx char(7500), spy varchar(1000))  -- 8.500 > 8.060 

insert into demoxy values ('xx', 'x')									  -- 7.500 + 1 = 7.501 < 8.060
GO 1000

dbcc showcontig ('demoxy')

select * from sys.dm_db_index_physical_stats
	(db_id(),
	 object_id('demoxy'),
	 NULL,
	 NULL,
	 'detailed'															  -- forward_record_count = 0
	)

select * from demoxy where id = 1										  -- 1.000 Seiten (kein Index!)

update demoxy set spy = replicate('x', 1000)							  -- 1.000 Seiten MIT ?BERL?NGE

				--(spx = 7500) + (spy = 1000 ) = 8500 > 8060   (Seite hat nur 8192 Bytes grunds?tzlich)

dbcc showcontig ('demoxy')												  -- Seiten zu ca. 93% voll

select * from sys.dm_db_index_physical_stats
	(db_id(),
	 object_id('demoxy2'),
	 NULL,
	 NULL,
	 'detailed'									-- [ROW_OVERFLOW_DATA] = 150 zus?tzliche Seiten
	)

-- ######################################################

-- ###### L?sungen aus den Aufgaben von Kurstag No 1 ####

-- ######################################################

-- L?sung 1

drop proc IF EXISTS uspKDSuche

create proc uspKDSuche @kdid varcahr(10) ='%'
AS
SELECT * FROM KundeUmsatz WHERE CustomerID LIKE @kdid + '%'

-- Idealer Index : idx_NCL_customID mit INCLUDING-Spalten aus dem SELECT

-- Vorteil der Prozedur? Er merkt sich genau den Plan!

exec uspKDSuche 'ALFKI'  -- idealer Plan w?rde einen SEEK beinhalten
exec uspKDSuche '%'
exec uspKDSuche          -- Ablaufplan immer identisch, auch wenn TABLE SCAN g?nstiger w?re

set statistics io, time on

SELECT * FROM KundeUMsatz WHERE customerid = 'ALFKI'		-- SEEK

SELECT * FROM KundeUMsatz WHERE customerid like '%' + '%'	-- SCAN : 55.000 Seiten

exec uspKDSuche						-- Faust-Formal : 25% f?r Index extra > 70.000 gesch?tzt
									-- Fakt-Auswertung : 1.100.000 LeseVorg?nge

	'Der PLAN wird vorkompiliert beim ersten Ausf?hren der PROCEDURE. Aber PROC sollte immer gleiches
	 leisten, also einen DS mehr oder weniger. Fazit : NIE benutzerfreundliches TSQL in PROC!

	Besser mit 2 PROCEDURES : SucheWenigProc und SucheAlleProc > ist optimiert f?r den einzelnen Aufruf!'

	alter PROC uspKDSuche @kdid varchar(5)
	AS
	IF %
		exec proc alle
	ELSE
		exec proc wenige

--------------------------------------------------------------

-- L?sung Aufgabe 2

SELECT * FROM employees

SELECT * from employees WHERE year(getdate()) - year(birthdate) >=65

SELECT * FROM employees WHERE datediff(yy, birthdate, getdate()) >=65

	'Beide schlecht! Das wird immer zu einem SCAN f?hren! Schlecht ist die FUNCTION() um die Spalte im WHERE.'

	suche so: famname like 'K%'		-- schneller Muster-Vergleich
	suche so: left(famname,1) ='K'	-- JEDER Datensatz muss ?berpr?ft werden
									-- Mit der FUNCTION() wird stets ALLES ?berpr?ft!!

	'Daher bei DB Design sehr sinnvoll : Daten explizit splitten.
	 Bestelldatum (Date) + weitere Spalten: Quartal, Jahr, Tag, Monat'


-- im Falle employees besser abzufragen

SELECT * FROM employees 
WHERE birthdate <= dateadd(yy,  -65, getdate()) -- kann SEEK werden

-- so muss die Spalte nicht zerlegt werden, es werden direkt Werte verglichen (nur ?ber INDEX erkl?rbar!).

--------------------------------------------------------------------------