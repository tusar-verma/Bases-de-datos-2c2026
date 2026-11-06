USE AdventureWorks2017;

SELECT * FROM Person.Address ORDER BY AddressID ;

SELECT AddressID , City , StateProvinceID FROM Person.Address ORDER by AddressID ;

SELECT AddressID , City , StateProvinceID FROM Person.Address ;

SELECT AddressID , City , StateProvinceID FROM Person.Address ORDER by City ;

SELECT AVG ( ListPrice ) FROM Production . Product

SELECT ProductLine , COUNT (*) FROM Production . Product
GROUP BY ProductLine


SELECT SalesOrderID , SUM ( LineTotal ) FROM Sales .
SalesOrderDetail GROUP BY SalesOrderID

SELECT City , COUNT ( City ) AS CityCount
FROM Person . Address
GROUP BY City

select AddressID, City, StateProvinceID, ModifiedDate
from Person.Address
where StateProvinceID = 32


select AddressID, City, StateProvinceID, ModifiedDate
from Person.Address
where StateProvinceID = 20