-- ##### Daten-Typen #####

-- Type-Definitionen
/*
	REFERENZ :: https://msdn.microsoft.com/de-de/library/ms187752(v=sql.120).aspx 
*/

-- System-Zeit des SQL-SERVERS , nicht des ausführenden Rechners !!!

SELECT GETDATE();
GO
SELECT CAST(GETDATE() AS date);
GO
SELECT FORMAT( CAST (GETDATE() AS date) , 'd' , 'de-DE' ) ;
GO
SELECT CAST(SYSDATETIME() AS datetime2(0));
GO
SELECT CAST(SYSUTCDATETIME() AS datetime2(0));
GO

-- CAST() ist besser als CONVERT() :: arbeitet Typen-abhängig und ist ggf. inkonsistent
-- IMMER ALS SPALTE DIE UTC-ZEIT VERWENDEN (Zeitumstellung während Auswertung fehlerhaft)

-- #######################

-- Rückmeldung

SELECT 'text' AS Antwort		-- DataSet als Antwort-Box
PRINT 'text'					-- Protokoll im Message-Kanal

-- IF EXISTS

DROP TABLE IF EXISTS dbo.demo;	-- wird nur gelöscht, FALLS sie existiert; ansonsten Fehler-Wert

-- #######################

-- ####################### [TSQL2012] #######################

-- #######################

USE [TSQL2012]
GO

-- ##### Berechnete Spalten #####

-- DEFAULT-Contraint
ALTER TABLE Sales.OrderDetails ADD CONSTRAINT [DFT_unitprice] DEFAULT ((0)) FOR [unitprice]
GO

ALTER TABLE HR.Actor ADD [Honorar] AS ([Stundensatz] * [Anzahl] * ( 1 + [MwST] )

-- Berechnete Spalte zur Laufzeit
ALTER TABLE Sales.OrderDetails ADD LineTotal AS (unitprice * qty * (1 - discount)) 
-- Jede NEUE Berechnung führt zu (indizierbaren) Inhalten
ALTER TABLE Sales.OrderDetails ADD LineTotal AS (unitprice * qty * (1 - discount)) PERSISTED

SELECT * FROM Sales.OrderDetails

-- #######################

-- ##### Filterung von Daten #####

-- Jede Abfrage ist eine "Filterung" von Daten

SELECT -- Vertikale Filterung
	companyname		AS [firma]
	, custid		AS [kundennummer]
	, city			AS [stadt]
FROM sales.customers -- Auswahl-Filter
WHERE custid % 2 = 1 -- Horizontale Filterung 
ORDER BY firma, kundennummer, stadt -- nur hier gibt es Alias 
-- BEST PRACTICE : Innerhalb eines SELECT keinen Spalten-ALIAS verwenden !
-- BESSER :: ORDER BY city, companyname, custid 

-- Vor- & Nach-Filter
SELECT 
	country
	, companyname
	, count(*) 
FROM sales.Customers  
WHERE country = 'UK'			-- VOR dem Mini-SELECT >> Gute Laufzeit
GROUP BY country, companyname
ORDER BY companyname

SELECT 
	country
	, companyname
	, count(*) 
FROM sales.Customers  
GROUP BY country, companyname
HAVING country='UK'				-- NACH dem Mini-SELECT >> Schlechte Laufzeit
ORDER BY companyname

-- #######################

-- TOP 3 Filter
SELECT TOP 3
	companyname AS Firma
	, custid AS KundenNummer
	, City AS Stadt
FROM Sales.Customers 
WHERE city >= N'Brazilia' AND city <= N'Düsseldorf' -- custid % 2 = 1 
ORDER BY Firma, KundenNummer, Stadt 

-- #######################

-- TOP 3 Filterung (unterschiedliche Result-Sets > Sortier-Reihenfolge des ResultSets!)
SELECT TOP 3
	companyname
	, contactname
	, country
FROM Sales.Customers
--	 WITH (INDEX = idx_nc_city) -- Mit INDEX-Angabe
WHERE country >= N'Brazil' AND country <= N'USA'
ORDER BY country						-- Sortierung nach country (eigene Sortierung)

-- Abfrage
SELECT TOP 3
	companyname
	, contactname
	, country
FROM sales.Customers
WHERE country >= N'Brazil' and country <= N'USA'
	-- kein ORDER BY > Reihenfolge wie es reingeschrieben wurde (KundenID)

-- Index-Angabe
SELECT TOP 3
	companyname
	, contactname
	, country
FROM sales.Customers
	WITH (INDEX = idx_nc_city)			-- Reihenfolge durch INDEX-Angabe
WHERE country >= N'Brazil' and country <= N'USA'

-- ORDER BY
SELECT TOP 3 
	companyname
	, contactname
	, country
FROM sales.Customers
	WITH (INDEX = idx_nc_city)
WHERE country >= N'Brazil' and country <= N'USA'
ORDER BY country;

-- WITH TIES (Klebrige Enden)
SELECT TOP 3 * WITH TIES FROM ...

-- OFFSET-Statement statt TOP 12
SELECT *
FROM Sales.Customers
ORDER BY custid
OFFSET 12 ROWS FETCH NEXT 12 ROWS ONLY;

-- #######################

-- Nur Position 13 bis 24
SELECT	*										-- 13...24 behalten
FROM	(SELECT	TOP 12 *						-- 01...12 wegnehmen
		FROM	(SELECT	TOP 24 *				-- 01...24 auswählen
				FROM Sales.Customers AS SQ2
				ORDER BY sq2.custid ) AS SQ1	-- 01...24 geordnet
		ORDER BY sq1.custid DESC) as QUERY		-- 01...12 umgekehrt
ORDER BY query.custid							-- 13...24 wohlgeordnet

-- Nur Position x bis y
DECLARE @x INT = 12
DECLARE @y INT = 24
SELECT	TOP (@x) *								-- 13...24 behalten
FROM	(SELECT	TOP (@x) *						-- 01...12 wegnehmen
		FROM	(SELECT	TOP (@y) *				-- 01...24 auswählen
				FROM Sales.Customers AS SQ2
				ORDER BY custid ) AS SQ1		-- 01...24 geordnet
		ORDER BY sq1.custid DESC) as QUERY		-- 01...12 umgekehrt
ORDER BY query.custid							-- 13...24 wohlgeordnet

-- Seiten-weise blättern als PAGE-RANGE
-- SYNTAX-Monster mit rasant wachsendem Speicherzugriff, ABER elegant für die Durchsicht
DECLARE @page INT = 2							-- Seiten-Auswahl treffen
DECLARE @range INT = 12							-- Seitengröße wählen
SELECT	TOP (@range) *							-- Seite behalten
FROM	(SELECT	TOP (@range) *					-- Rest wegnehmen
		FROM	(SELECT	TOP (@page * @range) *	-- Auswahl treffen
				FROM Sales.Customers AS SQ2
				ORDER BY custid ) AS SQ1		-- Auswahl sortieren für DataSet
		ORDER BY sq1.custid DESC) as QUERY		-- Rest durch Umordnung abwählen
ORDER BY query.custid							-- Seiteninhalt wohlgeordnet

-- viel einfacher mit OFFSET-Sytax und auch deutlich günstiger in Speicher und Rechenzeit
-- funktioniert ab SQL 2012 SP1 STANDARD EDITION
DECLARE @page INT = 2, @range  INT = 12
SELECT *
FROM Sales.Customers
ORDER BY custid
OFFSET ((@page - 1) * @range) ROWS FETCH NEXT @range ROWS ONLY;

-- #######################

-- DISTINCT-Filter

SELECT 
	custid
FROM Sales.Orders

SELECT DISTINCT		-- Duplikatfreiheit INNERHALB der SICHTBAREN Spalten, NICHT RAW DATA!! 
	custid
FROM Sales.Orders

-- #######################

-- Filterung von Zeichenketten mit Wildcard und Regular Expression

/*
	SELECT 
		CASE
			WHEN '~' = '~' THEN '1'       <-- ganze Spalten / kompletter Abgleich		[ Skalarwert ]
			WHEN '~' LIKE '_~' THEN '2'   <-- Muster-Erkennung / Regular Expressions	[Zeichenkette]
		END;

	LIKE zwingend bei:
	_		<-- ein Zeichen
	%		<-- beliebig viele Zeichen : 0...n
	[acd]	<-- a oder c oder d				
	[0-7]	<-- 0 bis 7
	[^ac]	<-- NICHT ( a oder c )
	[^1-3]	<-- NICHT ( 1 bis 3 )
*/

-- Beispiele

SELECT *
FROM Sales.Customers
WHERE contactname LIKE '[acd]rn%';

SELECT *
FROM Sales.Customers
-- WHERE contactname LIKE '%[^ø]rn%';
WHERE contactname LIKE '%rn_%';

SELECT *
FROM Sales.Customers
WHERE	contacttitle LIKE 'Sales %'
		AND city LIKE 'l%'
		AND address LIKE '[0-9]%';

DECLARE @contact VARCHAR(10) = 'Ass'
SELECT *
FROM Sales.Customers
WHERE	contacttitle LIKE '%' + @contact + '%'

-- BEST PRACTICE : Stored Procedure zum Generieren eines Antwort-Arrays (Vergleich mit Liste möglicher Ausdrücke)

CREATE PROCEDURE dbo.Kunde @contact VARCHAR(10) 
AS
SELECT *
FROM Sales.Customers
WHERE	contacttitle LIKE '%' + @contact + '%'

EXEC dbo.Kunde 'Sales'

-- VARIABLEN-Alternative
DECLARE @contact VARCHAR(10) = 'Sales'
SELECT *
FROM Sales.Customers
WHERE	contacttitle LIKE '%' + @contact + '%'

-- #######################

-- CASE-SELECT-FILTER mit PATTERN
DECLARE @pattern NVARCHAR(255)
SET @pattern = N'Martin Andreas Reiter'

SELECT
	CASE
		WHEN @pattern LIKE N'_Andreas%' THEN N'true2'
		WHEN @pattern LIKE N'%Andreas%' THEN N'true1' 
		WHEN @pattern LIKE N'%[^B-N]ndreas%' THEN N'true3' --ZeichenListen
		ELSE 'False'
	END

-- #######################

-- NULL-Filter
SELECT
	companyname
	, region 
FROM Sales.Customers
WHERE region is not null;	-- Vor-Filter-Definition; nicht mit LIKE oder = kombinierbar

-- INDEX-SEEK [ggf. Index zuweisen!]
DECLARE @Region NVARCHAR(50) 
SET @Region ='SP'			-- NULL-Marker oder Wert-Marker gleichzeitig setzbar
SELECT
	companyname
	, region 
FROM Sales.Customers
WHERE	region = @Region	-- Region ist oben angegeben
		OR (region is null AND @Region is null); -- Region UND Parameter sind beide NULL

-- INDEX-SCAN [Index mittels isnull() nicht verwendbar]
DECLARE @Region NVARCHAR(50) 
SET @Region ='SP'			-- NULL-Marker oder Wert-Marker gleichzeitig setzbar
SELECT
	companyname
	, region 
FROM Sales.Customers
WHERE	isnull(region, 'X') = isnull(@Region, 'X');					-- 'X' beliebiger Ersatzwert für NULL
-- Sequentiell abgearbeitet, weil Inhalt ungefiltert in DataSet überführt wird mit FunktionsSpalte 'region'
-- DataSet wird vom Index getrennt und wird dann via SCAN abgearbeitet (mehrfaches Anfassen eines Elementes) 

-- #######################

--Filterung mit IN-Operator und unabhängiger Unterabfrage (Array-Suche)
SELECT
	companyname
	, contactname
	, city
	, country
FROM Sales.Customers
WHERE custid NOT IN 
(						-- Unterabfrage als RESULT-Set
	SELECT DISTINCT		-- Temporäre Tabelle des ResultSets)
		custid
	FROM Sales.Orders	-- UNABHÄNGIGE Unterabfrage (Sub-Query)
);						-- schneller & effizienter als LEFT OUTER JOIN

-- #######################

-- Abhängige Unterabfrage (Sub-Query)

SELECT count(*) AS TotalProducts FROM Production.Products		-- 77 Produkte
SELECT count(*) AS TotalCategories FROM Production.Categories	-- 08 Kategorien

-- Ziel: Produktname und zugehöriger Kategoriename

SELECT
	categoryname
FROM Production.Categories
WHERE categoryid = 4

-- Verweis-Struktur

SELECT
	query.ProductName
	, (
		SELECT
			sq1.CategoryName
		FROM Production.Categories AS sq1			-- SubQuery 77-mal
		WHERE sq1.categoryid = query.categoryid		-- LEFT OUTER JOIN
	  ) AS CategoryName
FROM Production.Products AS query					-- Query 77-mal
ORDER BY query.ProductName

-- #######################

-- "Maximum-Edion" of 'Filtern für Nerdz'
	
DECLARE @prmStart DATETIME2(7)					-- Variablen-Definition
SET @prmStart = SYSDATETIME()					-- Variablen-Intialisierung
DECLARE @prmRegion NVARCHAR(20) = 'SP'			-- Definiton & Intialisierung
IF EXISTS (										-- Überprüfen, ob ResultSet für Array existiert (Fehlerbehandlung!)
	SELECT region								-- DataSet "Region" des initial prüfenden SELECT-Statements
	FROM Sales.Customers
	WHERE	region = @prmRegion					-- Pattern-Überprüfung
			OR (region is null AND @prmRegion is null)
	)
	SELECT *									-- Wird ausgeführt, wenn DataSet Werte beinhaltet (nicht leer)
	FROM	Sales.Customers
	WHERE	region = @prmRegion
			OR (region is null AND @prmRegion is null)									
	ELSE PRINT 'Region existiert nicht';		-- DataSet-Antwort-Box bei Nicht-Vorhanden

-- #######################
	
-- ##### JOIN #####

-- Sub-Query als JOIN

SELECT
	query.ProductName
	, (
		SELECT
			sq1.CategoryName
		FROM Production.Categories AS sq1			-- SubQuery 77-mal
		WHERE sq1.categoryid = query.categoryid		-- LEFT OUTER JOIN
	  ) AS CategoryName
FROM Production.Products AS query					-- Query 77-mal
ORDER BY query.ProductName

SELECT
	p.ProductName
	, c.CategoryName
FROM Production.Categories AS c						-- Tabellen-ALIAS für JOIN
	INNER JOIN Production.Products AS p ON c.CategoryID = p.CategoryID

-- #######################

-- SYNTAX
/*
SELECT	* 
FROM	leftTable AS lt 
		(INNER / LEFT [OUTER] / RIGHT [OUTER] / FULL [OUTER]) JOIN rightTable AS rt ON lt.IDCol = rt.IDCol

> Linke Tabelle und rechte Tabelle werden durch Position um Join-Operator bestimmt
> Tabellenalias kann frei gewählt werden (empfohlen: Kurzform Tabellenname)
> Tabellenreihenfolge:
>>	idealerweise RIGHT JOIN vermeiden
>>> wird solange umgebaut bis LEFT JOIN oder INNER JOIN entsteht
>>	wenn man zwei Tabellen verknüpft mit PRIMARY-KEY-Tabelle beginnen 
>>> (Categories --> Products)
>>	bei Verküpfung von mehreren Tabellen mit HUB-Tabelle beginnen
>>> (OrderDetails --> Orders --> Customers; OrderDetails --> Products)
*/

productname
categoryname

productname
categoryname
companyname

-- #######################

/*
Ziel: Liste Kunde.Firmenname, Bestellte Produkte
1. Schritt: beteiligte Tabellen:
	Customers
	Orders
	Order Details
	Products
*/

select * from Sales.Customers;
select * from Sales.Orders;
select * from Sales.OrderDetails;

-- GUTER STIL
SELECT DISTINCT
		c.companyname
		, p.productname
FROM	Sales.OrderDetails AS od
		INNER JOIN Sales.Orders AS o ON od.orderid = o.orderid
		INNER JOIN Sales.Customers AS c ON o.custid = c.custid
		INNER JOIN Production.Products AS p ON od.productid = p.productid
ORDER BY c.companyname, p.productname

-- SCHLECHTER STIL [Parsing & Compilation]
SELECT DISTINCT
		c.companyname
		, p.productname
FROM	Sales.Customers AS c
		INNER JOIN Sales.Orders AS o ON o.custid = c.custid
		INNER JOIN Sales.OrderDetails AS od ON o.orderid = od.orderid
		INNER JOIN Production.Products AS p ON od.productid = p.productid
ORDER BY c.companyname, p.productname

-- #######################

-- LEFT-JOIN

SELECT DISTINCT
		co.companyname
FROM	Sales.Customers AS co
		LEFT JOIN Sales.Orders AS od ON co.custid = od.custid
ORDER BY co.companyname

-- IN-Variante
SELECT	DISTINCT
		co.companyname
FROM	Sales.Customers AS co
WHERE	custid IN
		( SELECT DISTINCT 
				SQ1.custid
		  FROM Sales.Orders AS SQ1)
GROUP BY co.companyname

-- LEFT OUTER JOIN
SELECT DISTINCT
		co.companyname
FROM	Sales.Customers AS co
		LEFT OUTER JOIN Sales.Orders AS o ON co.custid = o.custid
WHERE	o.custid is null
ORDER BY co.companyname

-- #######################

-- RIGHT JOIN
SELECT	
		c.companyname
FROM	Sales.Orders AS o
		RIGHT JOIN Sales.Customers AS c ON o.custid = c.custid
ORDER BY c.companyname

-- LEFT JOIN
SELECT 
		c.companyname
FROM	Sales.Customers AS c
		LEFT JOIN Sales.Orders AS od ON c.custid = od.custid
ORDER BY c.companyname

-- #######################

-- FULL JOIN
SELECT	c.companyname, o.orderid	
FROM	Sales.Orders AS o
		FULL JOIN Sales.Customers AS c ON o.custid = c.custid
ORDER BY o.orderid		-- NULL : Kunden, die noch keine Bestellung aufgegeben haben

SELECT	c.companyname, o.orderid	
FROM	Sales.Customers AS c
		LEFT JOIN Sales.Orders AS o ON o.custid = c.custid
ORDER BY o.orderid		-- NULL : Kunden, die noch keine Bestellung aufgegeben haben

-- FULL OUTER JOIN
SELECT	c.companyname, o.orderid	
FROM	Sales.Orders AS o
		FULL JOIN Sales.Customers AS c ON o.custid = c.custid
WHERE	o.custid is null -- OR c.custid is null (nicht notwendig, weil es keine Bestellungen ohne Kunden gibt!)
ORDER BY o.orderid

-- #######################

-- VIEW & UNION

CREATE VIEW [Sales].[Product Sales for 2006] AS
SELECT 
		cat.categoryname, prod.productname,
		SUM((od.unitprice*od.qty*(1-od.discount)/100)*100) AS ProductSales
FROM	Production.Categories AS cat
		INNER JOIN Production.Products AS prod ON cat.categoryid = prod.categoryid
		INNER JOIN ( Sales.Orders AS ord 
					INNER JOIN Sales.OrderDetails AS od ON ord.orderid = od.orderid ) ON prod.productid = od.productid
WHERE ord.shippeddate BETWEEN '20060101' AND '20061231'
GROUP BY cat.categoryname, prod.productname
GO

CREATE VIEW [Sales].[Product Sales for 2007] AS
SELECT 
		cat.categoryname, prod.productname,
		SUM((od.unitprice*od.qty*(1-od.discount)/100)*100) AS ProductSales
FROM	Production.Categories AS cat
		INNER JOIN Production.Products AS prod ON cat.categoryid = prod.categoryid
		INNER JOIN ( Sales.Orders AS ord 
					INNER JOIN Sales.OrderDetails AS od ON ord.orderid = od.orderid ) ON prod.productid = od.productid
WHERE ord.shippeddate BETWEEN '20070101' AND '20071231'
GROUP BY cat.categoryname, prod.productname
GO

CREATE VIEW [Sales].[Product Sales for 2008] AS
SELECT 
		cat.categoryname, prod.productname,
		SUM((od.unitprice*od.qty*(1-od.discount)/100)*100) AS ProductSales
FROM	Production.Categories AS cat
		INNER JOIN Production.Products AS prod ON cat.categoryid = prod.categoryid
		INNER JOIN ( Sales.Orders AS ord 
					INNER JOIN Sales.OrderDetails AS od ON ord.orderid = od.orderid ) ON prod.productid = od.productid
WHERE ord.shippeddate BETWEEN '20080101' AND '20081231'
GROUP BY cat.categoryname, prod.productname
GO

-- UNION All-Operator

-- Funktioniert nur bei den selben Namen, selben Datentypen, selbe Anzahl von Spalten
SELECT *, 2006 AS [Year] FROM Sales.[Product Sales for 2006]
UNION ALL
SELECT *, 2007 AS [Year] FROM Sales.[Product Sales for 2007]
UNION ALL
SELECT *, 2008 AS [Year] FROM Sales.[Product Sales for 2008]

-- #######################

-- Format-Anweisung für Berechnete Spalten [CURRENCY]
SELECT
	c.CompanyName
	, FORMAT((od.UnitPrice * od.qty * (1 - od.Discount)), 'C', 'en-us') AS LineTotal
FROM	Sales.OrderDetails AS od
		INNER JOIN Sales.Orders AS oh ON od.OrderID = oh.OrderID
		INNER JOIN Sales.Customers AS c ON oh.custid = c.custid
-- 'C' : Curreny ; 'N' : Numbers | Schalter muss eine Zeichenkette sein >> kein Language-Code möglich !
-- Durch Formatierung wird das Feld zur ZEICHENKETTE >> keine arithmetische Operationen mehr möglich !!

/*
	SELECT @@LANGID >> en-US ist nicht als interne Resource hinterlegt

	SELECT name, lcid, msglangid, langid FROM sys.syslanguages
	WHERE langid=@@langid

||	ADMIN@POWERSHELL :: 
||	Get-Culture
||	$C = Get-Culture
||	$C | Format-List -property *
||	$c.calendar
||	$c.datetimeformat
||	$c.datetimeformat.firstdayofweek

	SET LANGUAGE us_english
	REFERENZ :: https://docs.microsoft.com/en-us/sql/relational-databases/system-compatibility-views/sys-syslanguages-transact-sql 
*/

-- #######################

-- Sortierung mit offensichtlichem Index
SELECT *
FROM Sales.Customers

-- Sortierung mit erzwungenem Index für Zugriff-Steuerung
SELECT *
FROM Sales.Customers WITH (INDEX = idx_nc_region)
-- INDEX-Auswahl entspricht : ORDER BY region

-- ab einem JOIN ist ohne GROUP BY die Sortierung nicht mehr vorhersagbar!
-- der letzte verwendete INDEX ist verantwortlich für die Sortierung des ResultSets

-- "Natürliche Ordnung"
SELECT * FROM Sales.Customers
SELECT companyname, region FROM Sales.Customers
SELECT companyname, region FROM Sales.Customers ORDER BY custid

-- "Erzwungene Ordnung"
SELECT * FROM Sales.Customers
SELECT * FROM Sales.Customers ORDER BY region

-- #######################

-- ##### Aggregation/Gruppierung #####

-- Aggregation SUMME (alle Umsätze)
SELECT
	FORMAT(SUM(od.UnitPrice * od.qty * (1 - od.Discount)), 'C', 'en-us') AS TotalSalesAmount
FROM Sales.OrderDetails AS od

-- Alle Umsätze PRO Kunde (Gruppierung zwingend!)
SELECT
	c.companyname
	, FORMAT(SUM(od.UnitPrice * od.qty * (1 - od.Discount)), 'C', 'en-us') AS TotalSalesAmount
FROM	Sales.OrderDetails AS od
		INNER JOIN Sales.Orders AS o ON od.orderid = o.orderid
		INNER JOIN Sales.Customers AS c ON  o.custid = c.custid
GROUP BY c.companyname

-- Aggregation ZEILENANZAHL

SELECT
	COUNT(*) as fullRowCount			-- zählt alle Zeilen
	, COUNT(region) as withRegion		-- ignoriert alle Zeilen mit NULL-Marker
	, COUNT(*) - COUNT(region) as withoutRegion		-- zählt NULL-Marker
FROM Sales.Customers

	' ##### WICHTIG #######################################################################################
		
	bis SQL SVR 2016 MIN, MAX, AVG ist NULL, sobald dieser einmal auf ein NULL trifft
	
	ab SQL SVR 2017 EXPRESS : stimmt so nicht mehr > NULL wird IGNORIERT
												   > es gibt Werte OHNE "Grundlage"
		
	#######################################################################################################'

-- Aggregation SUMME mit GRUPPIERUNG
-- Umsatz pro Kunde (Länder-Kunden-Hierarchie) 
select
	isnull(c.Country, 'Land') as Land
	, isnull(c.city, 'Stadt') as Stadt
	, isnull(c.CompanyName, 'Kunde') as KundenName
	, format(sum(od.UnitPrice * od.qty * (1 - od.Discount)), 'C', 'en-us') as CustomerTotal
from sales.OrderDetails as od
	inner join sales.Orders as oh on od.OrderID = oh.OrderID
	inner join sales.Customers as c on oh.custid = c.custid
group by c.country, c.city, c.CompanyName	-- keine Aggregation ohne Gruppierung
order by c.country, c.city, c.CompanyName	-- Sortierung verhindert "zufällige" Reihenfolge

-- #######################

-- ZWISCHENSUMMEN mit GroupID-Indikator
-- Grouping / Grouping_ID (ab SQL 2012) : Gruppierungssatz definieren
--rollup erzeugt Zwischensummen für die nächste Gruppierungsebene

select
	isnull(c.Country, 'Gesamtumsatz') as Land	-- Überschreibt NULL-Marker in Zwischensummen
	, isnull(c.city, 'LandesUmsatz') as Stadt
	, isnull(c.CompanyName, 'StadtUmsatz') as KundenName	-- HIER Stadtumsatz als Summe der Kunden
	, format(sum(od.UnitPrice * od.qty * (1 - od.Discount)), 'C', 'en-us') as CustomerTotal
from sales.OrderDetails as od
	inner join sales.Orders as oh on od.OrderID = oh.OrderID
	inner join sales.Customers as c on oh.custid = c.custid
group by
	rollup(c.country, c.city, c.CompanyName)

-- GROUPING_ID (Indikator-Level)
select
	GROUPING_ID(c.country, c.city, c.CompanyName) AS GroupLevel	-- Binary Info zu Group-Level
	, ISNULL(c.Country, 'Gesamtumsatz') AS Land, GROUPING(c.country) AS Total	-- 0/1 zu Level
	, ISNULL(c.city, 'Landesumsatz') AS Stadt, GROUPING(c.city) AS SubTotalCountry
	, ISNULL(c.CompanyName, 'Stadtumsatz') AS KundenName, GROUPING(c.companyname) AS SubTotalCity
	, FORMAT(SUM(od.UnitPrice * od.qty * (1 - od.Discount)), 'C', 'en-us') AS CustomerTotal
from Sales.OrderDetails as od
	INNER JOIN Sales.Orders AS oh ON od.OrderID = oh.OrderID
	INNER JOIN Sales.Customers AS c ON oh.custid = c.custid
group by
	rollup(c.country, c.city, c.CompanyName)
having GROUPING(c.city) = 1		-- Umsatz PRO Land aggregiert

-- #######################

/*
Ziel: Übersicht über Bestellungsjahr, Versandfirma, summierte Frachtkosten mit Zwischensummen
*/
select year(getdate()) as CurrentYear

select
	year(oh.OrderDate) as OrderYear
	, sh.CompanyName
	, format(sum(oh.freight), 'C', 'en-US') as FreightTotal
from	Sales.Orders as oh 
		inner join sales.shippers as sh on oh.shipperid = sh.shipperid
group by
	rollup(		-- NULL-Marker stehen immer ganz unten und sind Indikator für Zwischensummen
	year(oh.OrderDate)
	, sh.CompanyName
	)
order by	
	year(oh.OrderDate)		-- falls ORDER BY genutzt wird, sind Zwischensummen oben,
	, sh.CompanyName		-- weil NULL immer der kleinste Wert in der Sortierung ist.

/*
Ziel: Niedrigster Produktpreis pro Kategorie
Kategoriename, Preis
*/

select distinct
	c.CategoryName
	, min(p.UnitPrice) as LowestPrice
from Production.Products as p
	inner join Production.Categories as c on p.CategoryID = c.CategoryID
group by c.CategoryName

--Erweiterung: günstigstes Produkt pro Kategorie
--Kategoriename, Produktname, Preis
--(möglichst aufwandseffizient)

--falscher Ansatz
select
	c.CategoryName
	, p.ProductName
	, format(min(p.UnitPrice), 'C', 'de-de') as ProductPrice
from Production.Products as p
	inner join Production.Categories as c on p.CategoryID = c.CategoryID
group by c.CategoryName
	, p.ProductName
--Gruppierung auf Produkt-Ebene; daher ist jedes Produkt das Günstigste der jeweiligen Gruppe

select
	min(sq1.unitprice)
from Production.Products as sq1
where sq1.CategoryID = 4

select
	c.CategoryName
	, p.ProductName
	, p.UnitPrice
from Production.Products as p
	inner join Production.Categories as c on p.CategoryID = c.CategoryID
where p.UnitPrice = (
	select
		min(sq1.unitprice)
	from Production.Products as sq1
	where sq1.CategoryID = p.CategoryID
)
-- Alternative mit IN-Array zu arbeiten kann zu falschen Result-Sets führen, weil man dann auch noch weitere
-- Elemente bekommt, die $10.00 kosten (mehrere günstige Produkte, Auswahl ggf. zufällig über Ordnung)

-- #######################

-- ##### DatumsKonvertierung #####

SELECT * FROM sys.syslanguages
SELECT CAST(SYSDATETIME() AS datetime2(0))
SELECT CAST(SYSUTCDATETIME() AS datetime2(0))

-- In allen Januar-Datensätzen muss dasselbe Datum drinstehen, um monatsweise Auswertungen fahren zu können!!
SELECT DATEADD(month, DATEDIFF(month, 0, getdate()), 0)		-- Berechnung 1. Tag des Monats aus beliebigem Datum
-- BEST PRACTISE :: wird als MonatsInformation interpretiert
SELECT DATEADD(MONTH, DATEDIFF(month, -1, getdate()), -1)	-- Berechnung letzter Tag des Monats aus beliebigem Datum
-- ISO.Week-Number (Deutschland)
SELECT (DATEPART(dy,DATEADD(dd,DATEDIFF(dd,0,GETDATE())/7*7,0))+6)/7 
-- falls unterstützt
SELECT DATEPART(ISOWK, GETDATE()) 

/*
Summierung der Umsätze Pro Mitarbeiter und Monat
Employees.Name, OrderMonth, Summe Umsatz
Tabellen:
	HR.Employees
	Sales.Orders
	Sales.OrderDetails
*/
select
	e.empid
	, (e.FirstName + ' ' + e.LastName) as FullName
	, DATEADD(month, DATEDIFF(month, 0, oh.OrderDate), 0) as OrderMonth
	, format(sum(od.UnitPrice * od.qty * (1 - od.Discount)), 'C', 'en-us') as EmployeeSalesAmount
from Sales.OrderDetails as od
	inner join sales.Orders as oh on od.OrderID = oh.OrderID
	inner join HR.Employees as e on oh.empid = e.empid
group by e.empid, (e.FirstName + ' ' + e.LastName)
	, DATEADD(month, DATEDIFF(month, 0, oh.OrderDate), 0)
order by e.empid
	, DATEADD(month, DATEDIFF(month, 0, oh.OrderDate), 0)
go

--Erweiterung RunningTotal/Fortlaufende Summierung
-- [I] View erzeugen
create view dbo.vEmpOrders
as
select
	e.empid
	, (e.FirstName + ' ' + e.LastName) as FullName
	, DATEADD(month, DATEDIFF(month, 0, oh.OrderDate), 0) as OrderMonth
	, sum(od.UnitPrice * od.qty * (1 - od.Discount)) as EmployeeSalesAmount -- FORMATIERUNG rausnehmen
from Sales.OrderDetails as od
	inner join sales.Orders as oh on od.OrderID = oh.OrderID
	inner join HR.Employees as e on oh.empid = e.empid
group by e.empid, (e.FirstName + ' ' + e.LastName)
	, DATEADD(month, DATEDIFF(month, 0, oh.OrderDate), 0)
go

-- [II] View (4 Resourcen-Einheiten notwendig > Tabellen mehrfach anfassen)
-- Schritt notwendig, weil alternative GruppierungsAnweisung notwendig für Auswertung
select
	FullName
	, OrderMonth
	, format(EmployeeSalesAmount, 'C', 'en-us') as EmployeeSalesAmount
	, (
		select 
			format(sum(sq1od.UnitPrice * sq1od.qty * (1 - sq1od.Discount)), 'C', 'en-us')
		from Sales.OrderDetails as sq1od 
			inner join Sales.Orders as sq1oh on sq1od.OrderID = sq1oh.OrderID
		where sq1oh.empid = ve.empid and
			DATEADD(month, DATEDIFF(month, 0, sq1oh.OrderDate), 0)
				between (select min(DATEADD(month, DATEDIFF(month, 0, sq2oh.OrderDate), 0)) 
							from Sales.orders as sq2oh)
				and ve.OrderMonth
	) as EmployeeTotal
from dbo.vEmpOrders as ve

-- Alternative ab SQL2012 (bis zu Faktor 40 kleiner)
/* WINDOWED FUNCTION :: 
	- Partition des Result-Set auf Basis der Spalte employeeid 
	- Sortierung innerhalb der Partitionen nach Monat
	- unbounded : kompletter Bereich ; Eingabe "3" = 3 Zeilen
	- FrameGröße : 1. Zeile der Partition bis zur aktuellen Zeile der Partition
	- Dynamisches Gruppieren über stetig wachsendes Data-Set
	- VorAggregierte Werte können mit WHERE und HAVING gefiltert werden
*/	 
select
	FullName
	, OrderMonth
	, format(EmployeeSalesAmount, 'C', 'en-us') as EmployeeSalesAmount
	, format(
		(avg(EmployeeSalesAmount) over
		(partition by empid order by ordermonth rows between 2 preceding and current row))
		, 'C', 'en-us')
	as EmployeeRunningTotal
from dbo.vEmpOrders

-- #######################

-- Filterung auf Aggregationsergebnisse
select
	GROUPING_ID(c.country, c.CompanyName) as GroupLevel
	, isnull(c.Country, 'Gesamtumsatz') as Land, grouping(c.country) as SumAllCountries
	, isnull(c.CompanyName, 'Landesumsatz') as KundenName, grouping(c.companyname) as SumCustomersPerCountry
	, format(sum(od.UnitPrice * od.qty * (1 - od.Discount)), 'C', 'en-us') as CustomerTotal
from Sales.OrderDetails as od
	inner join Sales.Orders as oh on od.OrderID = oh.OrderID
	inner join Sales.Customers as c on oh.custid = c.custid
group by
	rollup(c.country, c.CompanyName)
having sum(od.UnitPrice * od.qty * (1 - od.Discount)) > 4000

-- #######################

-- ##### Pivotierung von Daten #####

-- Temporäre Tabellen (CREATE TABLE #temp mal anders)
drop table if exists #FreightData			
go
select
	year(oh.OrderDate) as OrderYear			-- Gruppierungsspalte 1 (Jahr)
	, month(oh.OrderDate) as OrderMonth		-- Gruppierungsspalte 2 (Monat)
	, sh.CompanyName as Company				-- Gruppierungsspalte 3 wird als Pivot-Spalte verwendet 
	, oh.Freight as Freight					-- da geringe Anzahl distinkter Werte
into #FreightData
from sales.Orders as oh inner join sales.shippers as sh on oh.shipperid = sh.shipperid
go
select * from #FreightData
order by OrderYear, OrderMonth
go

-- #######################

-- einfache Pivotierung
select
	pivotsum.OrderYear, OrderMonth, [Shipper ZHISN],[Shipper GVSUA],[Shipper ETYNR]
from #FreightData
	pivot(sum(Freight) for Company in ([Shipper ZHISN],[Shipper GVSUA],[Shipper ETYNR]))	
	-- PivotSpalte wird im Pivotoperator referenziert; Einzelwerte als Spaltenbezeichnungen
as pivotsum	-- Benennung der Pivotierung ist verpflichtend, Name ist irrelevant
order by OrderYear, OrderMonth

-- Multiple Pivotierung mit Union All und Typ-Indikator
select
	'SUM' as [Type], OrderYear, OrderMonth, [Shipper ZHISN],[Shipper GVSUA],[Shipper ETYNR]
from #FreightData
	pivot(sum(Freight) for Company in ([Shipper ZHISN],[Shipper GVSUA],[Shipper ETYNR])) as pivotsum
union all
select
	'AVG' as [Type], OrderYear, OrderMonth, [Shipper ZHISN],[Shipper GVSUA],[Shipper ETYNR]
from #FreightData
	pivot(avg(Freight) for Company in ([Shipper ZHISN],[Shipper GVSUA],[Shipper ETYNR])) as pivotsum
order by OrderYear, OrderMonth, Type desc

-- Multiple Pivotierung mit Join (funktioniert nur unter Verwendung abgeleiteter Tabellen)
select
	DT1.OrderYear
	, DT1.OrderMonth
	, Format(isnull(DT1.[Shipper ZHISN], 0), 'C', 'de-de') as [Shipper ZHISN SUM]
	, Format(isnull(DT2.[Shipper ZHISN], 0), 'C', 'de-de') as [Shipper ZHISN AVG]
	, Format(isnull(DT1.[Shipper GVSUA], 0), 'C', 'de-de') as [Shipper GVSUA SUM]
	, Format(isnull(DT2.[Shipper GVSUA], 0), 'C', 'de-de') as [Shipper GVSUA AVG]
	, Format(isnull(DT1.[Shipper ETYNR], 0), 'C', 'de-de') as [Shipper ETYNR SUM]
	, Format(isnull(DT2.[Shipper ETYNR], 0), 'C', 'de-de') as [Shipper ETYNR AVG]
from(
	select
		pivotSum.OrderYear, pivotSum.OrderMonth, pivotsum.[Shipper ZHISN],pivotsum.[Shipper GVSUA],pivotsum.[Shipper ETYNR]
	from #FreightData
		pivot (sum(Freight) for Company in ([Shipper ZHISN],[Shipper GVSUA],[Shipper ETYNR])) 
		as pivotSum) as DT1
inner join (
	select
		pivotAVG.OrderYear, pivotavg.OrderMonth, pivotavg.[Shipper ZHISN],pivotavg.[Shipper GVSUA],pivotavg.[Shipper ETYNR]
	from #FreightData
		pivot (avg(Freight) for Company in ([Shipper ZHISN],[Shipper GVSUA],[Shipper ETYNR])) 
		as pivotAvg) as DT2
on DT1.OrderYear = DT2.OrderYear and DT1.OrderMonth = DT2.OrderMonth
order by DT1.OrderYear, DT1.OrderMonth

-- #######################

-- ##### Tabellenwertausdrücke #####

-- Dauerhafte Tabellenwertausdrücke
/*
Temporäre Tabellen
wird immer mit einer oder zwei '#' als Namenspräfix gekennzeichnet
verwenden automatischen Garbage-Collector --> werden bei Sitzungsende automatisch gelöscht
*/

create table #Temp1 (rowID int identity constraint pkTemp primary key, content nvarchar(100)) --erzeugt temporäre Tabelle in aktueller Datenbank

--Nutzung für Vorbereitung der Daten zur Pivotierung
drop table if exists #FreightData
go
select
	year(oh.OrderDate) as OrderYear
	, month(oh.OrderDate) as OrderMonth
	, sh.CompanyName as Company
	, oh.Freight as Freight
into #FreightData		--Sonderform der Tabellenerzeugung mit gleichzeitiger Auffüllung
from Sales.Orders as oh inner join Sales.Shippers as sh on oh.shipperid = sh.shipperid
go
select * from #FreightData
order by OrderYear, OrderMonth
go

-- #######################

--Alternative: Sicht
/*
Sichten sind benannte SELECT-Statements
IMMER NUR EIN Resultset
	ENTWEDER EIN SELECT-Statement mit beliebig vielen Join-Operatoren
	ODER mehrere SELECT-Statements verbunden über 'UNION ALL'-Operatoren
	ODER mehrere SELECT-Statements, die JOINS verwenden, über 'UNION ALL' verbinden
*/

drop view if exists vfreightData
go
create view vfreightData
as
select
	year(oh.OrderDate) as OrderYear
	, month(oh.OrderDate) as OrderMonth
	, sh.CompanyName as Company
	, oh.Freight as Freight
from sales.Orders as oh inner join sales.shippers as sh on oh.shipperid = sh.ShipperID
go

--Vergleich Temp-Table <-> Sicht
select * from #FreightData
order by OrderYear, OrderMonth
select * from vFreightData
order by OrderYear, OrderMonth
go		-- DELIMITER WICHTIG!!

-- #######################

-- ##### CommonTableExpression :: Gewöhnliche Tabellenwertige Methode #####

/* analog zu abgeleiteter Tabelle ein benanntes Resultset
	- werden dem Statement vorangestellt
	- IMMER mit 'with' initiiert
	- können NICHT verschachtelt werden (DTEs dürfen CTEs und DTEs beinhalten)
	- definition ansonsten analog zu Sichten
	- können für Datenänderungen verwendet werden (Abgleich grösserer Datenmengen)
	- existiert nur während der Ausführung des nachfolgenden TSQL-Statements
*/

with cteFreightData
as
(	select
		year(oh.OrderDate) as OrderYear, month(oh.OrderDate) as orderMonth, sh.CompanyName as Company, oh.Freight
	from Sales.Orders as oh inner join Sales.Shippers as sh on oh.shipperid = sh.shipperid
)
select
	OrderYear
	, orderMonth
	, format(isnull([Shipper ZHISN], 0), 'C', 'de-de') as [Shipper ZHISN]
	, format(isnull([Shipper GVSUA], 0), 'C', 'de-de') as [Shipper GVSUA]
	, format(isnull([Shipper ETYNR], 0), 'C', 'de-de') as [Shipper ETYNR]
from cteFreightData
	pivot (sum(freight) for company in ([Shipper ZHISN],[Shipper GVSUA],[Shipper ETYNR])) as pivotsum
order by OrderYear, OrderMonth;

-- ##### Datenmanipulation #####

-- ##### Hinzufügen neuer Datensätze #####

drop table if exists dbo.person
go

create table dbo.person (personID int identity, fName nvarchar(50), lName nvarchar(50))
go

-- Insert  mmit Skalarwerten

set nocount on
go

-- Single-Line-Insert
insert into dbo.person (fName, lName)
	values ('Apu', 'Nahasapeemapetilon')
insert into dbo.person (fName, lName)
	values ('Majula', 'Nahasapeemapetilon')
insert into dbo.person (fName, lName)
	values ('Sanjay', 'Nahasapeemapetilon')

-- Multi-Line-Insert
insert into dbo.person (fName, lName)
	values ('Homer', 'Simpson'), ('Marge', 'Simpson'), ('Bart', 'Simpson'), ('Lisa', 'Simpson'), ('Maggie', 'Simpson')

-- Insert Select (anhängen von Zeilen an bestehende Tabelle)
insert into dbo.person (fName, lName)
	select firstname, lastname from [AdventureWorksDW2014].dbo.DimEmployee as emp		-- Sub-Query als Derived Table Expression

select COUNT(*) FROM [AdventureWorksDW2014].dbo.DimEmployee

-- Select Into
	-- erzeugt neue Tabelle mit Spaltendefinitionen aus Ergebnis des SELECT-Statements
	-- WICHTIG: Ziel-Tabelle darf noch nicht existieren <<<<<<<<<<<
drop table if exists dbo.[Order Details Revised]
go

select
	*
	into dbo.[Order Details Revised]			-- Temporary Table Object ; auch #Table möglich > schneller als Sicht
from Sales.OrderDetails
go
select * from dbo.[Order Details Revised]

-- #######################

-- ##### Hinzufügen neuer Datensätze #####

-- Update ändert Inhalt einer oder mehrerer Spalten in einer oder mehreren Zeilen
-- FALLS die betreffende Spalte KEINE berechneten Werte beinhaltet (ADD COLUMN) 

-- kann Skalarwerte verwenden
update dbo.[Order Details Revised] set Linetotal = 1		--> ist eine KOPIE und keine berechnete Spalte
update Sales.OrderDetails set Linetotal = 1					--> ist im Original berechnet und sperrt sich

	' ##### WICHTIG #######################################################################################
		
		In der Original-Table nur änderbar durch Löschen und Neu-Erstellen der betreffenden Spalte
		
		ALTER TABLE dbo.MyTable DROP COLUMN OldComputedColumn

		ALTER TABLE dbo.MyTable ADD NewComputedColumn AS ...
		
	#######################################################################################################'

select * from dbo.[Order Details Revised]

-- kann Berechnungen verwenden gff. mit Selbstreferenz der Tabelle
update dbo.[Order Details Revised] set Linetotal = (unitprice * qty *(1 - Discount))

select * from dbo.[Order Details Revised]

-- zusätzlich kann auch ein SELECT-Statement verwendet werden, wenn dieses ein Skalar zurückgibt
-- Zahl in Text-Spalte : OK ; Text in Zahl-Spalte : FEHLER (kein Type-Cast!)

-- Filterung bei Updates

update dbo.[Order Details Revised] set Linetotal = (UnitPrice * qty *(1 - Discount))
	where qty >= 10

select * from dbo.[Order Details Revised]

-- Mehrfach-Update
update dbo.[Order Details Revised] set Linetotal = (UnitPrice * qty *(1 - Discount)), ProductID = ProductID

-- Update mittels CTEs
drop table if exists dbo.myOrders
go
select * into dbo.myOrders from Sales.Orders order by OrderID
go
select * from dbo.myOrders order by OrderID

update dbo.myOrders set RequiredDate = 0 WHERE orderid % 2 = 1

update dbo.myOrders
	set RequiredDate = (select oh.RequiredDate from Sales.Orders as oh where oh.OrderID = dbo.MyOrders.OrderID);

with cteDifference				-- Wesentlich günstiger als ZEILENWEISES UPDATE wie gerade oben drüber, das SPALTENWEISES Update
as (							-- Bei FILTERUNG schlägt es um, da dann ZEILENWEISES Update wesentlich effektiver beim Vergleich
	select
		ORIGINAL.RequiredDate as referenceColumn
		, KOPIE.RequiredDate as differenceColumn
	from Sales.Orders as [ORIGINAL] inner join dbo.myOrders as [KOPIE] on [ORIGINAL].OrderID = [KOPIE].OrderID
)
--select * from cteDifference									-- Vergleich
update cteDifference set differenceColumn = referenceColumn 	-- Korrektur

-- #######################

-- ##### TRANSACTION >> DELETE #####
-- ROLLBACK rollt immer ALLE Transaktionen zurück

-- Delete entfernt Zeilenweise Inhalte aus Tabellen

begin transaction
delete from dbo.myorders
select * from dbo.myOrders
rollback

-- einzelne Spalten können NICHT enfernt werden
delete requireddate from dbo.myOrders

-- Löschen einzelner Spalten in einer Zeile
begin transaction
update dbo.myOrders set RequiredDate = 0 where (OrderID % 2 = 1)
select * from dbo.myorders
rollback
select * from dbo.myorders

--delete kann mit Filterung arbeiten
begin transaction
delete from dbo.myorders where (OrderID % 2 = 1)
select * from dbo.myOrders
rollback
select * from dbo.myOrders

-- Erweiterung: Filterung über andere verknüpfte Tabellen
begin transaction
	select count(*) as CountTotal from Sales.OrderDetails
	delete od from Sales.OrderDetails as od	--Alias der Zieltabelle MUSS nach DELETE angegeben werden
		inner join Sales.Orders as oh on od.OrderID = oh.OrderID
		inner join Sales.Customers as c on oh.custid = c.custid
	where c.Country = 'Austria'
	select count(*) as CountFiltered from Sales.OrderDetails
rollback

-- Alternative zu DELETE ohne Filterung: TRUNCATE TABLE 

-- TRUNCATE TABLE ist erst ab SQL Server 2016 transaktionell gebunden >> kann mit rollback rückgängig gemacht werden
-- Ältere SQL Server Versionen (ab SQL2008R1) : Daten sind weg!!

begin transaction
truncate table dbo.myorders
select * from dbo.myOrders
rollback
go

--Vergleich Delete <-> truncate
drop table if exists dbo.myorders2
go
select * into dbo.myorders2 from AdventureWorksDW2014.dbo.FactInternetSales

declare @starttime datetime2(7), @runtime int
begin transaction
set @starttime = SYSDATETIME()
delete from dbo.myorders2								
set @runtime = DATEDIFF(ms, @starttime, sysdatetime())
print @runtime
rollback
begin transaction
set @starttime = SYSDATETIME()
truncate table dbo.myorders2
set @runtime = DATEDIFF(ms, @starttime, sysdatetime())	
print @runtime
rollback

/*
	DELETE schreibt NULL-Marker ZEILENWEISE hinein > Speicherplatz wird frei für neue Daten / Speicherseiten
	TRUNCATE TABLE de-referenziert die Speicherseiten > Daten werden nicht angefasst und bleiben erhalten
	Defragmentierung für White-Spaces zwingend notwendig (SHRINK TABLE) > sonst kein Überschreiben der Räume
	### EINSCHRÄNKUNGEN BEIM LÖSCHEN ###
	Dort, wo DELETE zeilenweise nach Filterung ausgeführt werden kann, erlaubt TRUNCATE TABLE keine Filterung
	Dort, wo DELETE nur bestimmte Zeilen nicht löschen kann wegen FOREIGN KEY, verhindert TRUNCATE TABLE das komplett
	--> TRUNCATE TABLE ist eigentlich sehr viel restriktiver bei den Vorbedingungen zum anstehenden Löschvorgang!
*/

-- ####################### ENDE DER GRUNDLAGEN