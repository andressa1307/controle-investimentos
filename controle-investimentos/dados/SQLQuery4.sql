CREATE TABLE Parametros_Investimento (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Taxa_Anual DECIMAL(10,4),        -- Ex: 13.4300
    Periodo_Meses INT,               -- Ex: 24
    Data_Inicio DATE                 -- Ex: '2025-07-01'
);
INSERT INTO Parametros_Investimento (Taxa_Anual, Periodo_Meses, Data_Inicio)
VALUES (13.43, 24, '2025-07-01');


WITH Parametros AS (
    SELECT * FROM Parametros_Investimento
),
Meses AS (
    SELECT 1 AS Mes, Data_Inicio AS Data_Aporte
    FROM Parametros
    UNION ALL
    SELECT Mes + 1, DATEADD(MONTH, 1, Data_Aporte)
    FROM Meses
    JOIN Parametros ON 1=1
    WHERE Mes < (SELECT Periodo_Meses FROM Parametros)
),
Aportes AS (
    SELECT 
        Mes,
        Data_Aporte,
        CASE 
            WHEN Mes = 1 THEN 10000.00  -- Primeiro mês = R$10.000
            ELSE 1000.00               -- Demais meses = R$1.000
        END AS Valor_Aporte
    FROM Meses
)
SELECT * INTO Aportes_Investimento FROM Aportes;


CREATE OR ALTER VIEW vw_Resumo_Investimento AS
WITH Parametros AS (
    SELECT Taxa_Anual FROM Parametros_Investimento
),
JurosAcumulados AS (
    SELECT 
        A.Mes,
        A.Data_Aporte,
        A.Valor_Aporte,
        P.Taxa_Anual,
        DATEDIFF(MONTH, A.Data_Aporte, MAX(A.Data_Aporte) OVER()) AS Meses_Restantes
    FROM Aportes_Investimento A
    CROSS JOIN Parametros P
),
Resultado AS (
    SELECT 
        Mes,
        Data_Aporte,
        Valor_Aporte,
        ROUND(SUM(Valor_Aporte * POWER(1 + (Taxa_Anual / 100.0) / 12.0, (SELECT MAX(Mes) FROM Aportes_Investimento) - Mes)) 
              OVER (ORDER BY Mes), 2) AS Valor_Acumulado,
        SUM(Valor_Aporte) OVER (ORDER BY Mes) AS Total_Investido
    FROM JurosAcumulados
)
SELECT 
    Mes,
    Data_Aporte,
    Total_Investido,
    Valor_Acumulado,
    ROUND(Valor_Acumulado - Total_Investido, 2) AS Juros_Acumulados
FROM Resultado;