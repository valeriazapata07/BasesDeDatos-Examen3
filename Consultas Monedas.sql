USE Monedas;
GO

WITH PaisesPorMoneda AS (
    SELECT IdMoneda, COUNT(*) AS CantidadPaises
    FROM Pais
    GROUP BY IdMoneda
),
UltimoCambio AS (
    SELECT c.IdMoneda,
           c.Fecha  AS FechaUltimoCambio,
           c.Cambio AS ValorUltimoCambio
    FROM CambioMoneda c
    WHERE c.Fecha = (SELECT MAX(c2.Fecha)
                     FROM CambioMoneda c2
                     WHERE c2.IdMoneda = c.IdMoneda)
),
Estadisticas30 AS (
    SELECT c.IdMoneda,
           AVG(c.Cambio)   AS Promedio30,
           STDEV(c.Cambio) AS Desviacion30
    FROM CambioMoneda c
    WHERE c.Fecha > DATEADD(DAY, -30, (SELECT MAX(c2.Fecha)
                                       FROM CambioMoneda c2
                                       WHERE c2.IdMoneda = c.IdMoneda))
    GROUP BY c.IdMoneda
),
Resumen AS (
    SELECT m.Id,
           m.Moneda,
           m.Sigla,
           ISNULL(p.CantidadPaises, 0)              AS CantidadPaises,
           u.FechaUltimoCambio,
           u.ValorUltimoCambio,
           e.Promedio30                             AS PromedioCambio30Dias,
           e.Desviacion30 / NULLIF(e.Promedio30, 0) * 100 AS CoefVariacionPct
    FROM Moneda m
    LEFT JOIN PaisesPorMoneda p ON p.IdMoneda = m.Id
    LEFT JOIN UltimoCambio    u ON u.IdMoneda = m.Id
    LEFT JOIN Estadisticas30  e ON e.IdMoneda = m.Id
)
SELECT Id,
       Moneda,
       Sigla,
       CantidadPaises          AS TotalPaises,
       FechaUltimoCambio       AS UltimaFecha,
       ValorUltimoCambio       AS UltimoCambio,
       PromedioCambio30Dias    AS Promedio30Dias,
       CASE
           WHEN CoefVariacionPct IS NULL THEN 'Estable'
           WHEN CoefVariacionPct < 3     THEN 'Estable'
           WHEN CoefVariacionPct < 7     THEN 'Volatilidad moderada'
           ELSE 'Muy volatil'
       END AS Volatilidad,
       RANK() OVER (ORDER BY CantidadPaises DESC) AS RankingUso
FROM Resumen
ORDER BY RankingUso, Moneda;