
	' siehe EXCEL > [SELECT] '

USE [TSQL2012]
GO

SELECT * FROM Production.Products

SELECT productname
FROM Production.Products			-- SCHEMA.TABLE

SELECT productname				    -- Filter : Spalten
FROM Production.Products
WHERE unitprice > 20				-- Filter : Datensatz

SELECT SUM(unitprice)				-- Aggregation als GESAMT-Ergebnis
FROM Production.Products

SELECT SUM(unitprice)				-- Aggregation ; aktuell UNBENAMT
FROM Production.Products
GROUP BY supplierid					-- PRO Vertriebsweg [supplierid]

SELECT DISTINCT
	supplierid
FROM Production.Products

SELECT
	supplierid
FROM Production.Products
GROUP BY supplierid							-- DIRTY VERSION of DISTINCT

SELECT
	supplierid
	, discontinued
FROM Production.Products
GROUP BY supplierid, discontinued			-- mehr Gruppierung wegen TRUE / FALSE ( 1 / 0 )

SELECT 
	supplierid						-- Wonach ich aggregiere
	, SUM(unitprice) AS [Umsatz]	-- Spalten-ALIAS 
FROM Production.Products
GROUP BY supplierid					-- PRO Vertriebsweg [supplierid]

SELECT 
	supplierid						-- ERROR > Muss in die GRUPPIERUNG
	, SUM(unitprice) AS [Umsatz]	 
FROM Production.Products

SELECT 
	supplierid						
	, SUM(unitprice) AS [Umsatz]	 -- hier wird [Umsatz] als Spalten-ALIAS festgelegt! 
FROM Production.Products
-- WHERE [Umsatz] > 100				; was ist [Umsatz] ? > das ist erst NACH dem SELECT bekannt!!
--									; [Umsatz] existiert NICHT in RAW DATA > WHERE filter aber DATANSÄTZE
-- WHERE SUM(unitprice) > 100		; das wäre die GESAMT-SUMME <OHNE> Gruppierung > 100 = TRUE
GROUP BY supplierid					
-- HAVING [Umsatz > 100				; [Umsatz] existiert NICHT in GROUP BY > erst NACH dem SELECT bekannt!
HAVING SUM(unitprice) > 100		--	; Berechnung stumpf hineinkopieren, da [Umsatz] als Name nicht bekannt

-- korrekte Schreibweise:
SELECT 
	supplierid						
	, SUM(unitprice) AS [Umsatz]	  
FROM Production.Products
GROUP BY supplierid
HAVING SUM(unitprice) > 100

SELECT TOP 3					--	; LIMITER = bekomme WORTWÖRTLICH "die obersten 3 Elemente"
	supplierid						
	, SUM(unitprice) AS [Umsatz]	  
FROM Production.Products
GROUP BY supplierid
HAVING SUM(unitprice) > 100

SELECT TOP 3					--	; LIMITER = bekomme WORTWÖRTLICH "die obersten 3 Elemente"
	supplierid						
	, SUM(unitprice) AS [Umsatz]	  
FROM Production.Products
GROUP BY supplierid
HAVING SUM(unitprice) > 100
ORDER BY [Umsatz] DESC			-- ; [Umsatz] ist bekannt, weil Sortieren NACH dem SELECT stattfindet
								-- ; DESC = absteigend = Z ... A bzw. 1000 ... 1 ; DEFAULT = ASC

-- TOP 13..24 Problem
	> SubQueries 
	> VAR auslagern 
	> OFFSET leichter SQL SVR 2012 SP 1 
	> STORED PROCEDURE ( VAR )

-- TOP Bewertung

SELECT *
FROM	( SELECT TOP 12 *
		FROM	( SELECT TOP 24 *
				FROM Sales.Customers		AS [SQ2]
				ORDER BY SQ2.custid ASC )	AS [SQ1]
		ORDER BY SQ1.custid DESC )			AS [QUERY]
ORDER BY QUERY.custid ASC

-- VARIABLEN Setzung

DECLARE @12 INT = 12
DECLARE @24 INT 
SET @24 = 24
SELECT *
FROM	( SELECT TOP (@12) *
		FROM	( SELECT TOP 24 *
				FROM Sales.Customers		AS [SQ2]
				ORDER BY SQ2.custid ASC )	AS [SQ1]
		ORDER BY SQ1.custid DESC )			AS [QUERY]
ORDER BY QUERY.custid ASC

-- OFFSET Lösung

SELECT *
FROM Sales.Customers
ORDER BY custid ASC
OFFSET (@12) ROWS FETCH NEXT (@12) ROWS ONLY		-- STACKOVERFLOW ist Dein Freund. 

-- Wildwards && Regular Expression

WHERE [Spalte] LIKE '...'

	%		= beliebig viele Elemente   = 0 ... n
	_		= genau 1 bel. Element		= 1 ... 1
	_%		= mindestens 1 bel. Element = 1 ... n
	_____	= genau 5 bel. Elemente		

	x		= an DIESER Stelle steht ein (kleines) x
	[123]	= an DIESER Stelle steht 1 ODER 2 ODER 3 
	[^123]	= an DIESER Stelle steht NICHT 1, 2 oder 3
				-- Version 1 : dafür IRGENDETWAS anderes		<< selten
				-- Version 2 : dafür irgendeine andere ZAHL		<< häufig
	[a-z]	= an dieser Stelle steht ein BUCHSTABE 'SELTEN'

	'IMMER'				'HÄUFIG'			'SELTEN'
	[123]				[1-3]
	[abc]									[a-c]
	[^123]				[^1-3]
	[^abc]									[^a-c]

#1	[Artikelnummer] LIKE '[gfi]_%-12[67][49]-juhu-[^x][abc][6-9][3-7]_'

	gxx-1279-juhu-yb862			-- CORRECT
	georg-1264-juhu-za66a		-- CORRECT
	
#2	[Land] = German, Germany, Germania

	country LIKE 'German%'						-- Maximum-Edition

	country LIKE 'German[iy]%'					-- relatives Muster
			OR country = 'German'				-- exakten Wert

	country IN (German, Germany, Germania)		-- Ideal-Edition

#3	>> siehe Script

	name = 'O''Connor'

-- CASE SELECT SWITCH Typen

SELECT	-- TYPE A ; wesentlich häufiger
		CASE
#1			WHEN '~' = '~' THEN '1'			
#2			WHEN '~' LIKE '_~' THEN '2'		-- wenn [1] NICHT greift, dann teste [2]
			ELSE ....						-- DEFAULT-Zweig, wenn gar nix geht
		END;

SELECT	-- TYPE B ; extrem selten
		CASE
#1			WHEN '~' = '~' THEN '1'			
#2			WHEN '~' LIKE '_~' THEN '2'		-- UNÄBHÄNGIG davon, ob [1] greift, teste ZUSÄTZLICH [2]
		END;								-- ELSE wird NICHT unterstützt

SELECT	-- TYPE B ; extrem selten
		CASE
#1			WHEN '~' = '~' THEN '1'	EXIT	-- falls [1] "erfolgreich", dann teste NICHT weiter... 	
#2			WHEN '~' LIKE '_~' THEN '2'		
		END;


-- Das NULL-Filter-Problem (by STACKOVERFLOW)

DECLARE @region NVARCHAR(10) = NULL
SELECT
	companyname
	, region 
FROM Sales.Customers
WHERE region = @region
	 OR	( @region IS NULL AND region IS NULL )

		IS NULL				<>			ISNULL( value, 'replace-value')
		Filter							Function

DECLARE @region NVARCHAR(10) = NULL
SELECT
	companyname
	, region 
FROM Sales.Customers
WHERE ISNULL(region, 'xxx') = ISNULL(@region, 'xxx')
