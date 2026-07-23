/*
Project Title : Global Retail Sales Performance Analysis using SQL Server

Data Source:
- Retail Sales Dataset collected from Kaggle.
- CSV files imported into Microsoft SQL Server.

Pre-processing Performed:
- Verified data types.
- Checked NULL values.
- Validated duplicate records.
- Verified primary and foreign key relationships.
- Validated date formats.
- Checked exchange rate mappings.
- Resolved data type issues during import (e.g., Zip_Code).

Analysis:
- Performed 50 business scenario-based SQL queries covering:
  1. Customer Analysis
  2. Product Analysis
  3. Store Analysis
  4. Sales Analysis
  5. Profitability Analysis
  6. Time-Series Analysis
  7. Currency Analysis
  8. Executive Dashboard KPIs

*/

-- Step 1: Data Collection
-- Dataset downloaded from Kaggle and imported into SQL Server.

-- Step 2: Data Understanding

SELECT * FROM Customers;
SELECT * FROM Products;
SELECT * FROM Sales;
SELECT * FROM Exchange_Rates;
SELECT * FROM Stores;
SELECT * FROM Data_Dictionary;

/*-------------------------------------------------------
Step 3: Data Validation
Checking NULL Values
-------------------------------------------------------*/

-- Customers Table
SELECT *
FROM Customers
WHERE CustomerKey IS NULL
   OR Name IS NULL
   OR Gender IS NULL
   OR City IS NULL
   OR State_Code IS NULL
   OR State IS NULL
   OR Zip_Code IS NULL
   OR Country IS NULL
   OR Continent IS NULL
   OR Birthday IS NULL;

-- Products Table
SELECT *
FROM Products
WHERE ProductKey IS NULL
   OR Product_Name IS NULL
   OR Brand IS NULL
   OR Color IS NULL
   OR Unit_Cost_USD IS NULL
   OR Unit_Price_USD IS NULL
   OR Category IS NULL
   OR Subcategory IS NULL;

-- Sales Table
SELECT *
FROM Sales
WHERE Order_Number IS NULL
   OR Line_Item IS NULL
   OR Order_Date IS NULL
   OR Delivery_Date IS NULL
   OR CustomerKey IS NULL
   OR StoreKey IS NULL
   OR ProductKey IS NULL
   OR Quantity IS NULL
   OR Currency_Code IS NULL;

-- Stores Table
SELECT *
FROM Stores
WHERE StoreKey IS NULL
   OR Country IS NULL
   OR State IS NULL
   OR Square_Meters IS NULL
   OR Open_Date IS NULL;

-- Exchange_Rates Table
SELECT *
FROM Exchange_Rates
WHERE Date IS NULL
   OR Currency IS NULL
   OR Exchange IS NULL;


-- Step 4: Data Analysis
-- Business Scenario 1

------------------------------------------------------
--Q1. Write a query to display every sales order along with the corresponding customer name, product name, and quantity purchased.
SELECT
    Sales.[Order_Number],
    Customers.[Name],
    Products.[Product_Name],
    Sales.Quantity
FROM Sales
INNER JOIN Customers
    ON Sales.CustomerKey = Customers.CustomerKey
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey;

-----------------------------------------------------------
---Q2. Write a query to display, for every sale, the customer name, customer country, product name, product category, and quantity sold.
SELECT
    Customers.Name,
    Customers.Country,
    Products.[Product_Name],
    Products.Category,
    Sales.Quantity
FROM Sales
INNER JOIN Customers
    ON Sales.CustomerKey = Customers.CustomerKey
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey;

----------------------------------------------------------
---Q3. Write a query to calculate the total quantity sold for each combination of store country and product category.
SELECT
    Stores.Country,
    Products.Category,
    SUM(Sales.Quantity) AS TotalQty
FROM Sales
INNER JOIN Stores
    ON Sales.StoreKey = Stores.StoreKey
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
GROUP BY
    Stores.Country,
    Products.Category

-----------------------------------------------------------------
---Q4. Write a query to calculate the total sales revenue (in USD) generated across all orders.
SELECT
    SUM(Sales.Quantity * Products.[Unit_Price_USD]) AS TotalSalesUSD
FROM Sales
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey;


------------------------------------------------------------------
---Q5. Write a query to calculate total sales converted into each order's local currency, using the exchange rate matched by currency code and order date.
SELECT
    Sales.[Order_Number],
    Sales.[Currency_Code],
    (Sales.Quantity * Products.[Unit_Price_USD] * Exchange_Rates.Exchange) AS LocalSales
FROM Sales
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
INNER JOIN Exchange_Rates
    ON Sales.[Currency_Code] = Exchange_Rates.Currency
   AND Sales.[Order_Date] = Exchange_Rates.Date

-------------------------------------------------------------------
---Q6. Write a query to display, for each order, the total sales in both USD and the local currency side by side.

SELECT
    Sales.[Order_Number],
    (Sales.Quantity * Products.[Unit_Price_USD]) AS SalesUSD,
    (Sales.Quantity * Products.[Unit_Price_USD] * Exchange_Rates.Exchange) AS LocalSales
FROM Sales
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
INNER JOIN Exchange_Rates
    ON Sales.[Currency_Code] = Exchange_Rates.Currency
   AND Sales.[Order_Date] = Exchange_Rates.Date;

-----------------------------------------------------------------------
---Q7. Assume the Sales table stores the order amount in local currency. Write a query to convert this local currency amount into USD for each order using the applicable exchange rate.

SELECT
    Sales.[Order_Number],
    (
        Sales.Quantity
        * Products.[Unit_Price_USD]
        * Exchange_Rates.Exchange
    ) / Exchange_Rates.Exchange AS USDAmount
FROM Sales
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
INNER JOIN Exchange_Rates
    ON Sales.[Currency_Code] = Exchange_Rates.Currency
   AND Sales.[Order_Date] = Exchange_Rates.Date;

---------------------------------------------------------------------
--Q8. Write a query to identify the top 10 customers ranked by total sales revenue.
SELECT TOP (10)
    Customers.Name,
    SUM(Sales.Quantity * Products.[Unit_Price_USD]) AS Sales
FROM Sales
INNER JOIN Customers
    ON Sales.CustomerKey = Customers.CustomerKey
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
GROUP BY
    Customers.Name
ORDER BY
    Sales DESC;

-----------------------------------------------------------------------
--Q9. Write a query to find the best-selling product (by revenue) within each product category.

WITH ProductRevenue AS
(
  SELECT
        Products.Category,
        Products.[Product_Name],
        SUM(Sales.Quantity * Products.[Unit_Price_USD])
		AS Sales,
        ROW_NUMBER() OVER
        (PARTITION BY Products.Category
        ORDER BY SUM(Sales.Quantity * Products.[Unit_Price_USD]) 
		DESC)AS RN
    FROM Sales
    INNER JOIN Products
        ON Sales.ProductKey = Products.ProductKey
    GROUP BY
        Products.Category,
        Products.[Product_Name]
)
SELECT Category,  [Product_Name], Sales,RN
 FROM ProductRevenue   
   WHERE RN = 1

-------------------------------------------------------------------
--Q10. Write a query to calculate the number of days taken to deliver each order, along with the customer name.
SELECT
    Sales.[Order_Number],
    DATEDIFF(
        DAY,
        Sales.[Order_Date],
        Sales.[Delivery_Date]
    ) AS DeliveryDays,
    Customers.Name
FROM Sales
INNER JOIN Customers
    ON Sales.CustomerKey = Customers.CustomerKey

------------------------------------------------------------------------
--Q11. Write a query to calculate the average order delivery time (in days) for each customer country.
SELECT
    Customers.Country,
    AVG(
        DATEDIFF(
            DAY,
            Sales.[Order_Date],
            Sales.[Delivery_Date]
        )
    ) AS AvgDays
FROM Sales
INNER JOIN Customers
    ON Sales.CustomerKey = Customers.CustomerKey
GROUP BY
    Customers.Country

-------------------------------------------------------------------------
--Q12. Write a query to identify the top 5 product brands ranked by total revenue.
SELECT TOP 5
    Products.Brand,
    SUM(Sales.Quantity * Products.[Unit_Price_USD]) AS Revenue
FROM Sales
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
GROUP BY
    Products.Brand
ORDER BY
    Revenue DESC

---------------------------------------------------------------------------
--Q13. Write a query to identify the single store that has generated the highest total revenue.
SELECT TOP 1
    Sales.StoreKey, 
    SUM(Sales.Quantity * Products.[Unit_Price_USD]) AS Revenue
FROM Sales
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
GROUP BY
    Sales.StoreKey
ORDER BY
    Revenue DESC

-----------------------------------------------------------------------
--Q14. Write a query to calculate the total profit generated by each product category.
SELECT
    Products.Category,
    SUM(
        (Sales.Quantity * Products.[Unit_Price_USD])
        -
        (Sales.Quantity * Products.[Unit_Cost_USD])
    ) AS Profit
FROM Sales
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
GROUP BY
    Products.Category

--------------------------------------------------------------------------
--Q15. Write a query to calculate the total profit generated by customers in each country.

SELECT
    Customers.Country,
    SUM(
        (Sales.Quantity * Products.[Unit_Price_USD])
        -
        (Sales.Quantity * Products.[Unit_Cost_USD])
    ) AS Profit
FROM Sales
INNER JOIN Customers
    ON Sales.CustomerKey = Customers.CustomerKey
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
GROUP BY
    Customers.Country;

-------------------------------------------------------------------------
--Q16. Write a query to identify the top 3 best-selling products (by revenue) within each product category, using a ranking window function such as ROW_NUMBER(), RANK(), or DENSE_RANK().

WITH ProductRevenue AS
(
    SELECT
        Products.Category,
        Products.[Product_Name],
        SUM(Sales.Quantity * Products.[Unit_Price_USD]) AS Revenue,

        ROW_NUMBER() OVER
        (
            PARTITION BY Products.Category
            ORDER BY SUM(Sales.Quantity * Products.[Unit_Price_USD]) DESC
        ) AS Rank
    FROM Sales
    INNER JOIN Products
        ON Sales.ProductKey = Products.ProductKey
    GROUP BY
        Products.Category,
        Products.[Product_Name]
)
SELECT
    Category,
    [Product_Name],
    Revenue,
    Rank
FROM ProductRevenue
WHERE Rank <= 3;

---------------------------------------------------------------
--Q17. Write a query to calculate each customer's age at the time they placed each order.
SELECT
    Customers.Name,
    DATEDIFF(YEAR, Customers.Birthday, Sales.[Order_Date])
    -
    CASE
        WHEN DATEADD(
                YEAR,
                DATEDIFF(YEAR, Customers.Birthday, Sales.[Order_Date]),
                Customers.Birthday
             ) > Sales.[Order_Date]
        THEN 1
        ELSE 0
    END AS Age
FROM Sales
INNER JOIN Customers
    ON Sales.CustomerKey = Customers.CustomerKey;

--------------------------------------------------------------------
--Q18. Write a query to identify customers who have made purchases from more than one store.
SELECT
    Customers.Name,
    COUNT(DISTINCT Sales.StoreKey) AS StoresVisited
FROM Sales
INNER JOIN Customers
    ON Sales.CustomerKey = Customers.CustomerKey
GROUP BY
    Customers.Name
HAVING
    COUNT(DISTINCT Sales.StoreKey) > 1;

----------------------------------------------------------------------
--Q19. Write a query to calculate total revenue generated by each store, grouped by store country and state.
SELECT
    Stores.Country,
    Stores.State,
    SUM(Sales.Quantity * Products.[Unit_Price_USD]) AS Revenue
FROM Sales
INNER JOIN Stores
    ON Sales.StoreKey = Stores.StoreKey
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
GROUP BY
    Stores.Country,
    Stores.State

--------------------------------------------------------------------------
--Q20. Write a query to calculate total revenue generated on each continent.
SELECT
    Customers.Continent,
    SUM(Sales.Quantity * Products.[Unit_Price_USD]) AS Revenue
FROM Sales
INNER JOIN Customers
    ON Sales.CustomerKey = Customers.CustomerKey
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
GROUP BY
    Customers.Continent

---------------------------------------------------------------------------
--Q21. Write a query to identify repeat customers, i.e., customers who have placed more than one order.
SELECT
    Customers.Name,
    COUNT(Sales.[Order_Number]) AS TotalOrders
FROM Sales
INNER JOIN Customers
    ON Sales.CustomerKey = Customers.CustomerKey
GROUP BY
    Customers.Name
HAVING
    COUNT(Sales.[Order_Number]) > 1

--------------------------------------------------------------------------------
--Q22. Write a query to identify customers who have purchased products from more than one product category.
SELECT
    Customers.Name,
    COUNT(DISTINCT Products.Category) AS CategoriesPurchased
FROM Sales
INNER JOIN Customers
    ON Sales.CustomerKey = Customers.CustomerKey
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
GROUP BY
    Customers.Name
HAVING
    COUNT(DISTINCT Products.Category) > 1

-------------------------------------------------------------------------------
--Q23.Write a query to calculate total monthly sales revenue for each country.
SELECT
    YEAR(Sales.[Order_Date]) AS SalesYear,
    MONTH(Sales.[Order_Date]) AS SalesMonth,
    Customers.Country,
    SUM(Sales.Quantity * Products.[Unit_Price_USD]) AS SalesUSD
FROM Sales
INNER JOIN Customers
    ON Sales.CustomerKey = Customers.CustomerKey
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
GROUP BY
    YEAR(Sales.[Order_Date]),
    MONTH(Sales.[Order_Date]),
    Customers.Country
ORDER BY
    SalesYear,
    SalesMonth,
    Customers.Country

----------------------------------------------------------------------------------
--Q24. Write a query to identify the top-selling product (by quantity) in each country.
WITH ProductSales AS
(
    SELECT
        Customers.Country,
        Products.[Product_Name],
        SUM(Sales.Quantity) AS TotalQty,
        ROW_NUMBER() OVER
        (
            PARTITION BY Customers.Country
            ORDER BY SUM(Sales.Quantity) DESC
        ) AS RN
    FROM Sales
    INNER JOIN Customers
        ON Sales.CustomerKey = Customers.CustomerKey
    INNER JOIN Products
        ON Sales.ProductKey = Products.ProductKey
    GROUP BY
        Customers.Country,
        Products.[Product_Name]
)
SELECT
    Country,
    [Product_Name],
    TotalQty
FROM ProductSales
WHERE RN = 1

-------------------------------------------------------------------
--Q25. Write a query to calculate revenue, cost, profit, profit percentage, and revenue in local currency for each country.
SELECT
    Customers.Country,
    SUM(Sales.Quantity * Products.[Unit_Price_USD]) AS RevenueUSD,
    SUM(Sales.Quantity * Products.[Unit_cost_USD]) AS CostUSD,
    SUM((Sales.Quantity * Products.[Unit_Price_USD])
        -(Sales.Quantity * Products.[Unit_cost_USD])
    ) AS ProfitUSD,
    (
        SUM(
            (Sales.Quantity * Products.[Unit_Price_USD])
            -
            (Sales.Quantity * Products.[Unit_cost_USD])
        )
        /
        NULLIF(
            SUM(Sales.Quantity * Products.[Unit_Price_USD]),
            0
        )
    ) * 100 AS ProfitPercentage,
    SUM(
        Sales.Quantity
        * Products.[Unit_Price_USD]
        * Exchange_Rates.Exchange
    ) AS RevenueLocalCurrency
FROM Sales
INNER JOIN Customers
    ON Sales.CustomerKey = Customers.CustomerKey
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
INNER JOIN Exchange_Rates
    ON Sales.[Currency_Code] = Exchange_Rates.Currency
   AND Sales.[Order_Date] = Exchange_Rates.Date
GROUP BY
    Customers.Country
-------------------------------------------------------------------------
--Q26. The marketing team wants to identify high-value customers for a loyalty program. Write a query to display each customer's name, country, total number of orders, total quantity purchased, and total sales in USD, sorted by highest sales.
SELECT
    Customers.Name,
    Customers.Country,
    COUNT(Sales.[Order_Number]) AS TotalOrders,
    SUM(Sales.Quantity) AS TotalQuantity,
    SUM(Sales.Quantity * Products.[Unit_Price_USD]) AS TotalSalesUSD
FROM Sales
INNER JOIN Customers
    ON Sales.CustomerKey = Customers.CustomerKey
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
GROUP BY
    Customers.Name,
    Customers.Country
ORDER BY
    TotalSalesUSD DESC

----------------------------------------------------------------------------------
---Q27. The procurement department wants to identify products with the highest profit contribution. Write a query to display product name, brand, revenue, cost, and profit, sorted by profit in descending order.
SELECT
    Products.[Product_Name],
    Products.Brand,
    SUM(Sales.Quantity * Products.[Unit_Price_USD]) AS Revenue,
    SUM(Sales.Quantity * Products.[Unit_Price_USD]) AS Cost,
    SUM(
        (Sales.Quantity * Products.[Unit_Price_USD])
        -
        (Sales.Quantity * Products.[Unit_Price_USD])
    ) AS Profit
FROM Sales
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
GROUP BY
    Products.[Product_Name],
    Products.Brand
ORDER BY
    Profit DESC

------------------------------------------------------------------------------------
--Q28. Management wants to know which stores are generating the highest sales. Write a query to display total revenue for every store along with store country, state, and store size (square meters).
SELECT
    Stores.Country,
    Stores.State,
    Stores.[Square_Meters],
    SUM(Sales.Quantity * Products.[Unit_Price_USD]) AS Revenue
FROM Sales
INNER JOIN Stores
    ON Sales.StoreKey = Stores.StoreKey
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
GROUP BY
    Stores.Country,
    Stores.State,
    Stores.[Square_Meters]
ORDER BY
    Revenue DESC

-----------------------------------------------------------------------------
--Q29. The CEO wants to identify the best-selling product category in each country. Write a query to display the top-selling category (by revenue) for every customer country.
WITH CategoryRevenue AS
(
    SELECT
        Customers.Country,
        Products.Category,
        SUM(Sales.Quantity * Products.[Unit_Price_USD]) AS Revenue,
        ROW_NUMBER() OVER
        (
            PARTITION BY Customers.Country
            ORDER BY SUM(Sales.Quantity * Products.[Unit_Price_USD]) DESC
        ) AS RN
    FROM Sales
    INNER JOIN Customers
        ON Sales.CustomerKey = Customers.CustomerKey
    INNER JOIN Products
        ON Sales.ProductKey = Products.ProductKey
    GROUP BY
        Customers.Country,
        Products.Category
)
SELECT
    Country,
    Category,
    Revenue
FROM CategoryRevenue
WHERE RN = 1

-------------------------------------------------------------------------------
--Q30. Finance wants to calculate revenue in each customer's local currency. Write a query to display order number, customer name, currency code, revenue in USD, and revenue in local currency.
SELECT
    Sales.[Order_Number],
    Customers.Name,
    Sales.[Currency_Code],
    (Sales.Quantity * Products.[Unit_Price_USD]) AS RevenueUSD,
    (
        Sales.Quantity
        * Products.[Unit_Price_USD]
        * Exchange_Rates.Exchange
    ) AS RevenueLocal
FROM Sales
INNER JOIN Customers
    ON Sales.CustomerKey = Customers.CustomerKey
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
INNER JOIN Exchange_Rates
    ON Sales.[Currency_Code] = Exchange_Rates.Currency
   AND Sales.[Order_Date] = Exchange_Rates.Date

-------------------------------------------------------------------------
--Q31.Write a query to find customers who have purchased products from at least three different brands.
SELECT
    Customers.Name,
    COUNT(DISTINCT Products.Brand) AS BrandsPurchased
FROM Sales
INNER JOIN Customers
    ON Sales.CustomerKey = Customers.CustomerKey
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
GROUP BY
    Customers.Name
HAVING
    COUNT(DISTINCT Products.Brand) >= 3

------------------------------------------------------------------------------------
--Q32. Write a query to calculate the average order value for each country.
SELECT
    Customers.Country,
    AVG(Sales.Quantity * Products.[Unit_Price_USD]) AS AvgOrderValue
FROM Sales
INNER JOIN Customers
    ON Sales.CustomerKey = Customers.CustomerKey
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
GROUP BY
    Customers.Country

-----------------------------------------------------------------------------------
--Q33. Write a query to find the oldest customer (by birthday) who has placed at least one order.
SELECT TOP (1)
    Customers.Name,
    Customers.Country,
    Customers.Birthday
FROM Customers
INNER JOIN Sales
    ON Customers.CustomerKey = Sales.CustomerKey
ORDER BY
    Customers.Birthday ASC
--------------------------------------------------------------------------------
--Q34.Write a query to display yearly revenue for each product category. 
SELECT
    YEAR(Sales.[Order_Date]) AS SalesYear,
    Products.Category,
    SUM(
        Sales.Quantity * Products.[Unit_Price_USD]
    ) AS Revenue
FROM Sales
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
GROUP BY
    YEAR(Sales.[Order_Date]),
    Products.Category
ORDER BY
    SalesYear,
    Products.Category
	
---------------------------------------------------------------------
---Q35. Write a query to identify products that have never been sold.
SELECT
    Products.ProductKey,
    Products.[Product_Name]
FROM Products
LEFT JOIN Sales
    ON Products.ProductKey = Sales.ProductKey
WHERE
    Sales.ProductKey IS NULL

-----------------------------------------------------------------------
--Q36. Write a query to identify stores that have never processed an order.
SELECT
    Stores.StoreKey,
    Stores.Country,
    Stores.State
FROM Stores
LEFT JOIN Sales
    ON Stores.StoreKey = Sales.StoreKey
WHERE
    Sales.StoreKey IS NULL

-------------------------------------------------------------------------
--Q37. Write a query to display monthly revenue for each product brand.
SELECT
    YEAR(Sales.[Order_Date]) AS SalesYear,
    MONTH(Sales.[Order_Date]) AS SalesMonth,
    Products.Brand,
    SUM(
        Sales.Quantity * Products.[Unit_Price_USD]
    ) AS Revenue
FROM Sales
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
GROUP BY
    YEAR(Sales.[Order_Date]),
    MONTH(Sales.[Order_Date]),
    Products.Brand
ORDER BY
    SalesYear,SalesMonth,Brand;
    
---------------------------------------------------------------------------
--Q38. Write a query to identify customers whose total spending exceeds the overall average customer spending.
SELECT Customers.Name,
    SUM(
        Sales.Quantity * Products.[Unit_Price_USD]
    ) AS Sales
FROM Sales
INNER JOIN Customers
    ON Sales.CustomerKey = Customers.CustomerKey
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
GROUP BY
    Customers.CustomerKey,Customers.Name
HAVING
    SUM(Sales.Quantity * Products.[Unit_Price_USD])  >
    (
        SELECT
            AVG(CustomerSales)
        FROM
        (
            SELECT
                Sales.CustomerKey,
                SUM(Sales.Quantity * Products.[Unit_Price_USD]) AS CustomerSales
            FROM Sales
            INNER JOIN Products
                ON Sales.ProductKey = Products.ProductKey
            GROUP BY Sales.CustomerKey
        ) AS AvgCustomerSales
    )

----------------------------------------------------------------------------
--Q39. Write a query to rank all stores based on their total revenue.
SELECT
    Stores.StoreKey,Stores.Country,
    SUM(
        Sales.Quantity * Products.[Unit_Price_USD]
    ) AS Revenue,
    RANK() OVER
    (
        ORDER BY
        SUM(Sales.Quantity * Products.[Unit_Price_USD]) DESC
    ) AS StoreRank
FROM SaleS
INNER JOIN Stores
    ON Sales.StoreKey = Stores.StoreKey
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
GROUP BY
    Stores.StoreKey,Stores.Country;
    
------------------------------------------------------------
----Q40.Write a query to calculate each customer's percentage contribution to total company revenue.
SELECT
    Customers.Name,
    SUM(
        Sales.Quantity * Products.[Unit_Price_USD]
    ) AS Revenue,
    (
        SUM(Sales.Quantity * Products.[Unit_Price_USD]) * 100.0 /
        (
            SELECT
                SUM(S2.Quantity * P2.[Unit_Price_USD])
            FROM Sales S2
            INNER JOIN Products P2
                ON S2.ProductKey = P2.ProductKey
        )
    ) AS ContributionPercent
FROM Sales
INNER JOIN Customers
    ON Sales.CustomerKey = Customers.CustomerKey
INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
GROUP BY Customers.CustomerKey, Customers.Name
ORDER BY ContributionPercent DESC;

------------------------------------------------------------------------
--Q41. The Operations Manager wants to identify which stores consistently deliver orders the fastest. Write a query to display store key, country, state, total orders, and average delivery days, sorted by the fastest delivery time.
SELECT
    Stores.StoreKey,Stores.Country,Stores.State,
    COUNT(Sales.[Order_Number]) AS TotalOrders,
    AVG(
        DATEDIFF
        (
            DAY,
            Sales.[Order_Date],
            Sales.[Delivery_Date]
        )
    ) AS AvgDeliveryDays
FROM Sales
INNER JOIN Stores
ON Sales.StoreKey = Stores.StoreKey
GROUP BY Stores.StoreKey,Stores.Country, Stores.State        
ORDER BY
AvgDeliveryDays asc
    
----------------------------------------------------------------------------
--Q42. Management wants to investigate stores with poor delivery performance. Write a query to display the top 5 stores with the highest average delivery days.
SELECT TOP (5) 
    Stores.StoreKey,Stores.Country, Stores.State,
    AVG
    (
        DATEDIFF
        (
            DAY,
            Sales.[Order_Date],
            Sales.[Delivery_Date]
        )
    ) AS AvgDeliveryDays
FROM SaleS
INNER JOIN Stores
ON Sales.StoreKey = Stores.StoreKey
GROUP BY  Stores.StoreKey,Stores.Country, Stores.State
ORDER BY AvgDeliveryDays DESC;

------------------------------------------------------------------------------
--Q43. Finance wants to know which product categories generate the highest profit margin. Write a query to display category, revenue, cost, profit, and profit percentage, sorted by profit percentage in descending order.
SELECT   Products.Category,
    SUM(Sales.Quantity * Products.[Unit_Price_USD]) AS Revenue,
    SUM(Sales.Quantity * Products.[Unit_Cost_USD]) AS Cost,
    SUM((Sales.Quantity * Products.[Unit_Cost_USD])   -(Sales.Quantity * Products.[Unit_Cost_USD])) AS Profit,
    (
        SUM(
            (Sales.Quantity * Products.[Unit_Cost_USD])
            -
            (Sales.Quantity * Products.[Unit_Cost_USD])
        )
        *100.0 
		/ 
        NULLIF
        (
            SUM(
                Sales.Quantity * Products.[Unit_Price_USD]
            ),
            0
        )
    ) AS ProfitPercentage
FROM Sales
INNER JOIN Products
ON Sales.ProductKey = Products.ProductKey
GROUP BY Products.Category
ORDER BY ProfitPercentage DESC;

-------------------------------------------------------------------------
--Q44. Marketing wants to know which brands dominate each country. Write a query to display the top 5 brands (by revenue) within each country, along with their rank.
WITH BrandRevenue AS
(
    SELECT  Customers.Country,Products.Brand,
        SUM(
            Sales.Quantity * Products.[Unit_Price_USD]
        ) AS Revenue,
        ROW_NUMBER() OVER ( PARTITION BY Customers.Country ORDER BY                       
            SUM(Sales.Quantity * Products.[Unit_Price_USD])
             DESC) AS RN       
    FROM Sales
    INNER JOIN Customers
    ON Sales.CustomerKey = Customers.CustomerKey
    INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey
    GROUP BY
        Customers.Country, Products.Brand
)
SELECT COUNTRY, BRAND, REVENUE, RN
FROM BrandRevenue
WHERE RN <=5
ORDER BY Country, RN;

----------------------------------------------------------------------------------
--Q45.The CEO wants to track cumulative revenue throughout the year. Write a query to display year, month, monthly revenue, and running (cumulative) revenue.
WITH MonthlyRevenue AS
(
    SELECT
        YEAR(Sales.[Order_Date]) AS SalesYear,
        MONTH(Sales.[Order_Date]) AS SalesMonth,
        SUM
        (
            Sales.Quantity * Products.[Unit_Price_USD]
        ) AS Revenue
    FROM Sales
    INNER JOIN Products
        ON Sales.ProductKey = Products.ProductKey
    GROUP BY YEAR(Sales.[Order_Date]),MONTH(Sales.[Order_Date])      
)
SELECT  SalesYear, SalesMonth,Revenue, 
    SUM(Revenue)OVER (ORDER BY  SalesYear, SalesMonth) AS RunningRevenue    
FROM MonthlyRevenue
ORDER BY SalesYear,SalesMonth;

-----------------------------------------------------------------------------------
--Q46. Management wants to compare each month's revenue with the previous month. Write a query to display year, month, current month revenue, previous month revenue, and month-over-month growth.
WITH MonthlyRevenue AS
(
    SELECT YEAR(Sales.[Order_Date]) AS SalesYear,
        MONTH(Sales.[Order_Date]) AS SalesMonth,
        SUM
        (Sales.Quantity * Products.[Unit_Price_USD]) AS Revenue
    FROM Sales
    INNER JOIN Products
        ON Sales.ProductKey = Products.ProductKey
    GROUP BY  YEAR(Sales.[Order_Date]),
        MONTH(Sales.[Order_Date])
)
SELECT  SalesYear,  SalesMonth,  Revenue,
    LAG(Revenue)
    OVER(ORDER BY SalesYear,SalesMonth) AS PreviousMonthRevenue,
    Revenue
    -
    LAG(Revenue)
    OVER ( ORDER BY  SalesYear,  SalesMonth ) AS MoMGrowth
FROM MonthlyRevenue
ORDER BY  SalesYear,  SalesMonth

----------------------------------------------------------------------------------
--Q47. Write a query to find the highest-selling product color (by quantity) within each product category.
WITH ColorSales AS
(
    SELECT
        Products.Category,
        Products.Color,
        SUM(Sales.Quantity) AS Qty,
        ROW_NUMBER()
        OVER
        (
            PARTITION BY Products.Category
            ORDER BY
            SUM(Sales.Quantity) DESC
        ) AS RN
    FROM Sales
    INNER JOIN Products
        ON Sales.ProductKey = Products.ProductKey
    GROUP BY
        Products.Category, Products.Color      
)
SELECT CATEGORY, COLOR, QTY, RN FROM COLORSALES WHERE RN =1

--------------------------------------------------------------------------------------------
--Q48.  Write a query to identify customers who have made purchases in more than one store country (e.g., customers who travel and shop internationally).
    SELECT 
    Customers.Name,
    COUNT(DISTINCT Stores.Country) AS CountriesPurchased
FROM Sales
INNER JOIN Customers
ON Sales.CustomerKey = Customers.CustomerKey
INNER JOIN Stores
ON Sales.StoreKey = Stores.StoreKey
GROUP BY
Customers.CustomerKey,
Customers.Name
HAVING COUNT(DISTINCT Stores.Country) > 1;

------------------------------------------------------------------------------------------------
--Q49. Marketing wants age-wise revenue insights. Write a query to calculate total revenue by customer age group (18–25, 26–35, 36–45, 46–60, 60+) at the time of purchase.
WITH CustomerAge AS
(
    SELECT
        CASE
            WHEN Age BETWEEN 18 AND 25 THEN '18-25'
            WHEN Age BETWEEN 26 AND 35 THEN '26-35'
            WHEN Age BETWEEN 36 AND 45 THEN '36-45'
            WHEN Age BETWEEN 46 AND 60 THEN '46-60'
            ELSE '60+'
        END AS AgeGroup,
        Sales.Quantity,
        Products.[Unit_Price_USD]
    FROM
    (
        SELECT Sales.*, Customers.Birthday,
             DATEDIFF(YEAR, Customers.Birthday, Sales.[Order_Date])      
            -
            CASE
                WHEN DATEADD
                ( YEAR,DATEDIFF(YEAR,Customers.Birthday, Sales.[Order_Date]), Customers.Birthday
                )
                > Sales.[Order_Date]
                THEN 1
                ELSE 0
            END AS Age
        FROM Sales
        INNER JOIN Customers
            ON Sales.CustomerKey = Customers.CustomerKey
    ) AS Sales
    INNER JOIN Products
        ON Sales.ProductKey = Products.ProductKey
)
SELECT
    AgeGroup,
    SUM(Quantity * [Unit_Price_USD]) AS Revenue
FROM CustomerAge
GROUP BY AgeGroup;

-------------------------------------------------------------------------------------
--Q50. The CEO requires a single query to power an executive dashboard. Write a query to return total revenue (USD), total cost (USD), total profit (USD), profit percentage, total orders, total customers, total products sold, average order value, and total revenue in local currency.
SELECT
    SUM(
        Sales.Quantity * Products.[Unit_Price_USD]
    ) AS TotalRevenueUSD,
    SUM(
        Sales.Quantity * Products.[Unit_Price_USD]
    ) AS TotalCostUSD,
    SUM(
        (Sales.Quantity * Products.[Unit_Price_USD])
        -
        (Sales.Quantity * Products.[Unit_Price_USD])
    ) AS TotalProfitUSD,
    (
        SUM(
            (Sales.Quantity * Products.[Unit_Price_USD])
            -
            (Sales.Quantity * Products.[Unit_Price_USD])
        )
        *100.0
        /
        NULLIF
        (
            SUM(
                Sales.Quantity * Products.[Unit_Price_USD]
            ),
            0
        )
    ) AS ProfitPercentage,
    COUNT(Sales.[Order_Number]) AS TotalOrders,

    COUNT(DISTINCT Sales.CustomerKey) AS TotalCustomers,

    SUM(Sales.Quantity) AS TotalProductsSold,

    AVG(
        Sales.Quantity * Products.[Unit_Price_USD]
    ) AS AverageOrderValueUSD,

    SUM
    (
        Sales.Quantity
        *
        Products.[Unit_Price_USD]
        *
        Exchange_Rates.Exchange
    ) AS TotalRevenueLocalCurrency
FROM Sales

INNER JOIN Products
    ON Sales.ProductKey = Products.ProductKey

INNER JOIN Exchange_Rates
    ON Sales.[Currency_Code] = Exchange_Rates.Currency
   AND Sales.[Order_Date] = Exchange_Rates.Date;



