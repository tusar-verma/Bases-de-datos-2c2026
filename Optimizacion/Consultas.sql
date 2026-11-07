SELECT 
    t.Name, t.Composer, t.UnitPrice 
FROM Track t
INNER JOIN PlaylistTrack pt ON pt.TrackId = t.TrackId
WHERE pt.PlaylistId = 5;


SELECT 
    i.InvoiceId, i.Total, c.FirstName, C.LastName
FROM Invoice i
INNER JOIN Customer c ON c.CustomerId = i.CustomerId
ORDER BY i.Total DESC
OFFSET 0 ROWS FETCH FIRST 5 ROWS ONLY;


SELECT
    t.Name, t.Milliseconds
FROM Track t
INNER JOIN PlaylistTrack pt ON pt.TrackId = t.TrackId
INNER JOIN Playlist p ON p.PlaylistId = pt.PlaylistId
WHERE 
    t.Composer IS NOT NULL AND 
    p.Name = 'Classical'
ORDER BY t.Milliseconds DESC
OFFSET 1 ROWS FETCH FIRST 5 ROWS ONLY;


SELECT
    Composer, count(TrackId) AS Cantidad
FROM Track
GROUP BY Composer
HAVING count(TrackId) >= 20;

SELECT 
    c.LastName, AVG(i.Total) AS avg, count(i.InvoiceId) AS "Cantidad facturas del cliente"
FROM Customer c
INNER JOIN Invoice i on i.CustomerId = c.CustomerId
GROUP BY c.CustomerId, c.LastName
ORDER BY avg DESC
OFFSET 0 ROWS FETCH FIRST 10 ROWS ONLY;


SELECT
    t.Name, count(DISTINCT il.InvoiceId) CantidadFacturasDelTrack
FROM Track t
INNER JOIN InvoiceLine il ON t.TrackId = il.TrackId
GROUP BY t.TrackId, t.Name
HAVING count(il.InvoiceId) >= 2
ORDER BY CantidadFacturasDelTrack DESC;

WITH FacturasMenorImporte AS 
(SELECT InvoiceId FROM Invoice
WHERE Total = (SELECT Min(Total) from Invoice))

SELECT DISTINCT p.Name
FROM Playlist p 
INNER JOIN PlaylistTrack pt ON pt.PlaylistId = p.PlaylistId
INNER JOIN InvoiceLine il ON il.TrackId = pt.TrackId
INNER JOIN FacturasMenorImporte fmi ON fmi.InvoiceId = il.InvoiceId



/*No devuelve nada si la subconsulta tiene algun nulo*/
SELECT
    t.Name, t.Composer
FROM Track t
WHERE t.TrackId NOT IN (
    SELECT 
        il.TrackId
    FROM InvoiceLine il
);

SELECT
    t.Name, t.Composer
FROM Track t
WHERE NOT EXISTS(
    SELECT *
    FROM InvoiceLine il
    WHERE il.TrackId = t.TrackId
);


SELECT
    t.Name
FROM Track t
INNER JOIN PlaylistTrack pt ON pt.TrackId = t.TrackId
INNER JOIN Playlist p ON p.PlaylistId = pt.PlaylistId
WHERE p.Name = 'Classical'
INTERSECT
SELECT
    t.Name
FROM Track t
INNER JOIN PlaylistTrack pt ON pt.TrackId = t.TrackId
INNER JOIN Playlist p ON p.PlaylistId = pt.PlaylistId
WHERE p.Name = 'Classical 101 - The Basics'

SELECT
    t.trackid, t.Name
FROM Track t
INNER JOIN PlaylistTrack pt ON pt.TrackId = t.TrackId
INNER JOIN Playlist p ON p.PlaylistId = pt.PlaylistId
WHERE p.Name = 'Music Videos'
UNION
SELECT
   t.trackid, t.Name
FROM Track t
INNER JOIN PlaylistTrack pt ON pt.TrackId = t.TrackId
INNER JOIN Playlist p ON p.PlaylistId = pt.PlaylistId
WHERE p.Name = 'On-The-Go 1'

( SELECT t.trackid, t.name
FROM Track t, Playlist p, Playlisttrack pt
WHERE p.playlistid = pt.playlistid
AND pt.trackid = t.trackid AND p.name = 'Music Videos' )
UNION
( SELECT t.trackid, t.name
FROM Track t, Playlist p, Playlisttrack pt
WHERE p.playlistid = pt.playlistid
AND pt.trackid = t.trackid AND p.name = 'On-The-Go 1' )



SELECT 
    t.Name, count(il.InvoiceLineId) AS "Cantidad invoice_lines en la que aparece"
FROM Track t
INNER JOIN Genre g ON t.GenreId = g.GenreId
LEFT JOIN InvoiceLine il ON t.TrackId = il.TrackId
WHERE g.Name = 'Rock And Roll'
GROUP BY t.TrackId, t.Name


