
-- ### JOIN

SELECT	* 
FROM	leftTable AS lt		-- benutze Tabellen-ALIAS > JOIN schneller / kompakter zu schreiben!
		(INNER / LEFT [OUTER] / RIGHT [OUTER] / FULL [OUTER]) JOIN rightTable AS rt ON lt.IDCol = rt.IDCol

-- ### Beispiel für INNER JOIN :: Schlachtordnung im Bau von JOINs

USE [TSQL2012]
GO

-- [0.] Wissen ums Terrain

[1.] Database Diagram > TABLE ; ggf. CUSTOM-VIEW oder KEY-VIEW für DIAGRAM
[2.] Tabelle > Rechtsklick > Script > CREATE TO > New Window
[3.] KEY-VIEW für TEILE der Database für ZIEL-Optimierung

-- [1.] ZIEL : gebe mir die Kunden und deren Bestellungen (Produkte) inkl. Bestell-Infos

0091	Customers		Sales			CUS		custid						|	companyname, city, country
0830	Orders			Sales			ORD		custid	orderid				|	orderdate
#2155	OrderDetails	Sales			ODS				orderid	  prodid	|	unitprice, qty
0077	Products		Production		PRO						  prodid	|	prodname, unitprice

GO
SELECT * FROM Production.Products

-- [2.] Wo fange ich an?

[1.] Verknüpfungstabelle > Ort der effektivsten Filterung
[2.] Der maximal Bietende > größte "Haufen" zuerst

-- [3.] Wie geht es von hier weiter?

[3.] Bleibe so lange im jeweiligen SCHEMA wie möglich
[4.] Versuche so viele LEFT JOIN wie möglich, da RIGHT JOIN > LEFT JOIN umgewandelt wird
	
	' ODS > ORD > CUS > PRO '

-- SQL SVR Entscheidung > nicht notwendig für EIGENE Betrachtung

[5.] SVR "darf" davon abweichen, wenn es 'günstiger' ist, es in 'anderer' Reihenfolge zu machen

	' ODS > PRO && ODS > ORD > CUS '

-- [4.] Tue es!

0091	Customers		Sales			CUS		custid						|	companyname, city, country
0830	Orders			Sales			ORD		custid	orderid				|	orderdate
#2155	OrderDetails	Sales			ODS				orderid	  prodid	|	unitprice, qty
0077	Products		Production		PRO						  prodid	|	prodname, unitprice

SELECT 
	CUS.companyname
	, CUS.city
	, CUS.country
	, ORD.orderdate
	, FORMAT(ODS.unitprice, 'C', 'de-DE')	AS [VK]
	, ODS.qty
	, PRO.productname
	, FORMAT(PRO.unitprice, 'C', 'de-DE')	AS [EK]
	, FORMAT(ODS.unitprice - PRO.unitprice, 'C', 'de-DE')	AS [Marge]
FROM Sales.OrderDetails				AS [ODS]
	INNER JOIN Sales.Orders			AS [ORD] ON ODS.orderid = ORD.orderid
	INNER JOIN Sales.Customers		AS [CUS] ON ORD.custid = CUS.custid
	INNER JOIN Production.Products	AS [PRO] ON ODS.productid = PRO.productid

-- BETWEEN / VIEWS / UNIONS

CREATE VIEW Sales.[vTop2007] AS
SELECT 
	PRO.productname
	, SUM(LineTotal)				AS [Umsatz] 
FROM Sales.OrderDetails				AS [ODS]
	INNER JOIN Sales.Orders			AS [ORD] ON ODS.orderid = ORD.orderid
	INNER JOIN Sales.Customers		AS [CUS] ON ORD.custid = CUS.custid
	INNER JOIN Production.Products	AS [PRO] ON ODS.productid = PRO.productid
WHERE orderdate BETWEEN '20070101' AND '20071231' 
GROUP BY PRO.productname

SELECT * FROM Sales.vTop2008
ORDER BY [Umsatz] DESC
GO

-- # UNION = selbe ANZAHL, REIHENFOLGE, TYPE, NAMING
SELECT '2007' AS [Jahr] , * FROM Sales.vTop2007
UNION ALL
SELECT '2008' AS [Jahr] , * FROM Sales.vTop2008

UNION     { A ; B ; A } = { A ; B }	-- = DISTINCT
UNION ALL { A ; B ; A } = { A ; B ; A } 

  -- Das AggregationsTheorem

					' SQL2017 EXP '		'bis SQL2016'		ISNULL
  SUM ( 1 ; 2; NULL ) =		3.0			  3 / NULL			3.0

  AVG ( 1 ; 2; NULL ) =		1.5				NULL			1.0
  MIN ( 1 ; 2; NULL ) =		1.0				NULL			0.0
  MAX ( 1 ; 2; NULL ) =		2.0				NULL			2.0

  SOLUTION :: ISNULL ( [xx] , 0 )

 -- GROUPING und GROUPING_ID

 SELECT 
	CUS.country, CUS.city, CUS.companyname
	, SUM(LineTotal) AS [Umsatz]
 from sales.OrderDetails as od
	inner join sales.Orders as oh on od.OrderID = oh.OrderID
	inner join sales.Customers as [CUS] on oh.custid = cus.custid
group by CUS.country, CUS.city, CUS.companyname
order by CUS.country, CUS.city, CUS.companyname

 SELECT 
	CUS.country, CUS.city, CUS.companyname
	, SUM(LineTotal) AS [Umsatz]
 from sales.OrderDetails as od
	inner join sales.Orders as oh on od.OrderID = oh.OrderID
	inner join sales.Customers as [CUS] on oh.custid = cus.custid
group by 
	ROLLUP (CUS.country, CUS.city, CUS.companyname)
HAVING
	GROUPING_ID(CUS.country, CUS.city, CUS.companyname) = 1


 SELECT 
	GROUPING_ID(CUS.country, CUS.city, CUS.companyname)
	, CUS.country			, GROUPING(CUS.country)
	, CUS.city			, GROUPING(CUS.city)
	, CUS.companyname	, GROUPING(CUS.companyname)
	, SUM(LineTotal) AS [Umsatz]
 from sales.OrderDetails as od
	inner join sales.Orders as oh on od.OrderID = oh.OrderID
	inner join sales.Customers as [CUS] on oh.custid = cus.custid
group by 
	ROLLUP (CUS.country, CUS.city, CUS.companyname)
HAVING GROUPING(CUS.city) = 1

 SELECT 
	--GROUPING_ID(CUS.country, CUS.city, CUS.companyname)
	CUS.country			--, GROUPING(CUS.country)
	--, CUS.city		--, GROUPING(CUS.city)
	--, CUS.companyname	--, GROUPING(CUS.companyname)
	, SUM(LineTotal) AS [Umsatz]
 from sales.OrderDetails as od
	inner join sales.Orders as oh on od.OrderID = oh.OrderID
	inner join sales.Customers as [CUS] on oh.custid = cus.custid
group by 
	ROLLUP (CUS.country, CUS.city, CUS.companyname)
HAVING GROUPING(CUS.city) = 1

 SELECT 
	ISNULL(CUS.country	, 'Gesamtumsatz') AS [Land]	
	, FORMAT(SUM(LineTotal), 'C', 'de-DE')  AS [Umsatz]
 from sales.OrderDetails as od
	inner join sales.Orders as oh on od.OrderID = oh.OrderID
	inner join sales.Customers as [CUS] on oh.custid = cus.custid
group by 
	ROLLUP (CUS.country, CUS.city, CUS.companyname)
HAVING GROUPING(CUS.city) = 1

-- DATEADD / DATEDIFF - Theorem

SELECT GETDATE()	= 08.09.2021 14:56:42 +02:00

SELECT DATEDIFF ( Month , 0 , GETDATE() ) :	number	=	1460 

SELECT DATEADD ( Month , 1460 , 0 ) : date = 01.09.2021 00:00:00 +02:00

SELECT DATEADD ( Month , DATEDIFF ( Month , 0 , GETDATE() ) , 0 )

-- PIVOT-TABLE in TSQL

SELECT *
FROM #TEMP PIVOT ( ... )
WHERE ...


-- Daten "auslagern" > Tabellen-Konstrukte

CREATE VIEW AS ...	-- als View = Abfrage wird immer wieder NEU ausgeführt, wenn ich danach frage

SELECT ...			-- kannst nur <DU> sehen, niemand sonst && auch nur in der aktuellen SITZUNG
	INTO #TEMP		-- Temporäre Tabelle > sie wird in diesem Schritt NEU erstellt EINMALIG! 
FROM ...			-- nach Schließen des REITERS = SITZUNG ist #TEMP weg und kommt auch nicht wieder

CREATE TABLE ...	-- eine "echte" (leere) Tabelle erstellen, danach mit Inhalt befüllen

	INSERT INTO [Tab] VALUES (....) -- sehr händisch
	INSERT INTO [Tab] (SELECT.....) -- SELECT generiert Datenauswahl für INSERT

	CREATE PROCEDURE #PROC	-- temporäre Prozedure

SELECT ...			-- Antwort-Tabelle > können von ALLEN (dbo) abgerufen / geändert werden
	INTO RESP		-- Eine NEUE Tabelle OHNE Tabelle-Definition (PRIMARY, FOREIGN, CONSTRAINT,...) 
FROM ...			-- Anwendungsfall: zeitlicher TRIGGER = 1x Tag neu schreiben für Tagesauswertung

WITH [cteTABLE]
AS (select ... from ...)	-- VorTabelle, die im RAM gehalten wird, NICHT in der tempDB
SELECT ...
FROM [cteTABLE]				-- aus dieser Tabelle nutze ich alles und mache damit, was ich will
							'häufig eingesetzt für UPDATE in Größenordnungen!'


select
	e.empid
	, (e.FirstName + ' ' + e.LastName) as FullName
	, DATEADD(month, DATEDIFF(month, 0, oh.OrderDate), 0) as OrderMonth
	, sum(od.UnitPrice * od.qty * (1 - od.Discount)) as EmployeeSalesAmount -- FORMATIERUNG rausnehmen
  INTO RESPONSE
from Sales.OrderDetails as od
	inner join sales.Orders as oh on od.OrderID = oh.OrderID
	inner join HR.Employees as e on oh.empid = e.empid
group by e.empid, (e.FirstName + ' ' + e.LastName)
	, DATEADD(month, DATEDIFF(month, 0, oh.OrderDate), 0)
go

SELECT * FROM #TEMP

SELECT * FROM dbo.vEmpOrders

SELECT * FROM RESPONSE