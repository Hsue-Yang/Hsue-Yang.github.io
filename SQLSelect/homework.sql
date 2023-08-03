-- 找出和最貴的產品同類別的所有產品 ProductName,UnitPrice,CategoryName
SELECT
*
FROM Products p
WHERE CategoryID = 1
ORDER BY UnitPrice DESC

-- 找出和最貴的產品同類別最便宜的產品
SELECT TOP 1 
*
FROM Products p
WHERE CategoryID = 1
ORDER BY UnitPrice 

-- 計算出上面類別最貴和最便宜的兩個產品的價差
SELECT
MAX(p.UnitPrice)-MIN(p.Unitprice)AS Price
FROM Products p
WHERE CategoryID = 1

-- 找出沒有訂過任何商品的客戶所在的城市的所有客戶
SELECT 
s.CustomerID,
s.City
FROM Customers s
WHERE City IN(
SELECT DISTINCT
c.City
FROM Customers c
LEFT JOIN Orders cus ON c.CustomerID = cus.CustomerID 
WHERE cus.CustomerID IS NULL)

-- 找出第 5 貴跟第 8 便宜的產品的產品類別 **
SELECT  
CategoryID,
UnitPrice
FROM Products
ORDER BY UnitPrice
OFFSET 7 ROWS
FETCH NEXT 1 ROWS ONLY

SELECT  
CategoryID,
UnitPrice
FROM Products
ORDER BY UnitPrice
OFFSET 72 ROWS
FETCH NEXT 1 ROWS ONLY

SELECT
*
FROM Products
WHERE UnitPrice IN (0.0576,13.75)
-- 找出誰買過第 5 貴跟第 8 便宜的產品
SELECT DISTINCT
o.CustomerID
FROM Products p
INNER JOIN [Order Details] od ON p.ProductID =od.ProductID 
INNER JOIN Orders o ON od.OrderID = o.OrderID
WHERE p.UnitPrice IN (0.0576,13.75)

-- 找出誰賣過第 5 貴跟第 8 便宜的產品
SELECT DISTINCT
p.SupplierID
FROM Products p
WHERE p.UnitPrice IN (0.0576,13.75)
-- 找出 13 號星期五的訂單 (惡魔的訂單)
SELECT DISTINCT
*
FROM Orders
WHERE DAY(OrderDate) = 13 AND DATEPART(WEEKDAY,OrderDate)=5

-- 找出誰訂了惡魔的訂單
SELECT DISTINCT
CustomerID
FROM Orders
WHERE DAY(OrderDate) = 13 AND DATEPART(WEEKDAY,OrderDate)=5
-- 找出惡魔的訂單裡有什麼產品
SELECT DISTINCT
od.ProductID,
p.productName
FROM Orders o
INNER JOIN [Order Details] od ON o.OrderID = od.OrderID 
INNER JOIN Products p ON od.ProductID = p.ProductID
WHERE DAY(OrderDate) = 13 AND DATEPART(WEEKDAY,OrderDate)=5
-- 列出從來沒有打折 (Discount) 出售的產品
SELECT DISTINCT
p.ProductID,
p.ProductName,
od.Discount,
p.UnitsOnOrder
FROM [Order Details] od
INNER JOIN Products p ON od.ProductID = p.ProductID
WHERE Discount = 0 AND UnitsOnOrder = 0

-- 列出購買非本國的產品的客戶
SELECT 
p.ProductID,
c.CustomerID,
c.City,
s.City
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN [Order Details] od ON o.OrderID=od.OrderID
LEFT JOIN Products p ON od.ProductID = p.ProductID
LEFT JOIN Suppliers s ON p.SupplierID = s.SupplierID
WHERE c.City <> s.City
-- 列出在同個城市中有公司員工可以服務的客戶
SELECT DISTINCT
e.EmployeeID,
e.FirstName,
e.LastName,
e.City,
c.City
FROM Employees e
LEFT JOIN Orders o ON e.EmployeeID = o.EmployeeID
LEFT JOIN Customers c ON c.CustomerID = o.CustomerID
WHERE e.City = c.City

-- 列出那些產品沒有人買過
SELECT DISTINCT
*
FROM Products
WHERE UnitsOnOrder =0
-- 列出所有在每個月月底的訂單
SELECT
*
FROM Orders
WHERE DATEADD(DAY,-1,DATEADD(MONTH,DATEDIFF(MONTH,0,OrderDate)+1,0)) = OrderDate
-- 列出每個月月底售出的產品
SELECT DISTINCT
P.ProductID,
p.ProductName,
o.OrderID,
o.OrderDate
FROM Orders o
LEFT JOIN [Order Details] od ON o.OrderID = od.OrderID
LEFT JOIN Products p ON od.ProductID=p.ProductID
WHERE DATEADD(DAY,-1,DATEADD(MONTH,DATEDIFF(MONTH,0,OrderDate)+1,0)) = OrderDate

-- 找出有敗過最貴的三個產品中的任何一個的前三個大客戶
SELECT TOP 3 
o.CustomerID,
od.UnitPrice
FROM [Order Details] od
INNER JOIN Orders o ON od.OrderID = o.OrderID
WHERE od.ProductID = 38
ORDER BY UnitPrice DESC

-- 找出有敗過銷售金額前三高個產品的前三個大客戶
WITH CTE AS(
SELECT
od.ProductID,
od.UnitPrice*od.Quantity*(1-od.Discount) AS TotalPrice,
o.CustomerID
FROM [Order Details] od
INNER JOIN Orders o ON od.OrderID=o.OrderID
),
CTE1 AS(
SELECT 
ProductID,
TotalPrice,
CustomerID,
ROW_NUMBER () OVER (PARTITION BY ProductID ORDER BY TotalPrice DESC) AS RowNUMBER
FROM CTE
GROUP BY ProductID,TotalPrice,CustomerID
),CTE2 AS(
SELECT TOP 3 
ProductID,
TotalPrice,
CustomerID
FROM CTE1 
WHERE RowNUMBER=1 
ORDER BY TotalPrice DESC
)SELECT * FROM CTE2

-- 找出有敗過銷售金額前三高個產品所屬類別的前三個大客戶
WITH t1 AS(
SELECT
od.ProductID,
od.UnitPrice*od.Quantity*(1-od.Discount) AS TotalPrice,
o.CustomerID
FROM [Order Details] od
INNER JOIN Orders o ON od.OrderID=o.OrderID
),t2 AS(
SELECT 
ProductID,
TotalPrice,
CustomerID,
ROW_NUMBER () OVER (PARTITION BY ProductID ORDER BY TotalPrice DESC) AS RowNUMBER
FROM t1
GROUP BY ProductID,TotalPrice,CustomerID
)SELECT 
ProductID,
TotalPrice,
CustomerID
FROM t2
WHERE RowNUMBER IN (1,2,3) AND ProductID IN (38,29,59)
ORDER BY TotalPrice DESC

-- 列出消費總金額高於所有客戶平均消費總金額的客戶的名字，以及客戶的消費總金額
WITH c1 AS(
SELECT 
AVG(UnitPrice*Quantity*(1-Discount)) AS AveragePrice,
o.CustomerID
FROM [Order Details] od
INNER JOIN Orders o ON od.OrderID=o.OrderID
GROUP BY o.CustomerID
),c2 AS(
SELECT
AVG(AveragePrice) AS AvGP
FROM c1
)
SELECT  * FROM c2,c1
WHERE AveragePrice>AvGP

-- 列出最熱銷的產品，以及被購買的總金額
with g1 AS(
SELECT 
od.ProductID,
SUM(od.UnitPrice*od.Quantity*(1-od.Discount)) AS Price,
Count(ProductID) AS countNum
FROM [Order Details] od
GROUP BY ProductID
)
SELECT TOP 1
ProductID,
countNum,
SUM(Price) AS SumPrice
FROM g1
GROUP BY ProductID,countNum
ORDER BY countNum DESC

-- 列出最少人買的產品
with g1 AS(
SELECT 
od.ProductID,
Count(ProductID) AS countNum
FROM [Order Details] od
GROUP BY ProductID
)
SELECT TOP 1
ProductID,
countNum
FROM g1
ORDER BY countNum 

-- 列出最沒人要買的產品類別 (Categories)
with g1 AS(
SELECT 
od.ProductID,
Count(od.ProductID) AS countNum,
p.CategoryID
FROM [Order Details] od
INNER JOIN Products p ON od.ProductID = p.ProductID
GROUP BY od.ProductID,p.CategoryID
)
SELECT TOP 1
ProductID,
CategoryID,
countNum
FROM g1
ORDER BY countNum 

-- 列出跟銷售最好的供應商買最多金額的客戶與購買金額 (含購買其它供應商的產品)

-- 列出跟銷售最好的供應商買最多金額的客戶與購買金額 (不含購買其它供應商的產品)

-- 列出那些產品沒有人買過
SELECT od.OrderID,o.OrderID FROM [Order Details] od
RIGHT JOIN Orders o ON od.OrderID = o.OrderID
WHERE od.OrderID is NULL

-- 列出沒有傳真 (Fax) 的客戶和它的消費總金額
SELECT 
SUM(od.UnitPrice*od.Quantity*(1-od.Discount)) AS SalesPrice,
c.CustomerID,
c.Fax
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN [Order Details] od ON o.OrderID=od.OrderID
WHERE Fax IS NULL
GROUP BY c.CustomerID,c.Fax

-- 列出每一個城市消費的產品種類數量
SELECT 
c.City,
od.ProductID,
od.Quantity,
p.CategoryID
FROM Customers c
INNER JOIN Orders o ON o.CustomerID = c.CustomerID
INNER JOIN [Order Details] od ON o.OrderID=od.OrderID
INNER JOIN Products p ON od.ProductID=p.ProductID

-- 列出目前沒有庫存的產品在過去總共被訂購的數量
SELECT
od.ProductID,
p.ProductName,
SUM(od.Quantity)AS CountNum,
UnitsInStock
FROM Products p
INNER JOIN [Order Details] od ON p.ProductID = od.ProductID
WHERE UnitsInStock = 0
GROUP BY od.ProductID,p.ProductName,UnitsInStock

-- 列出目前沒有庫存的產品在過去曾經被那些客戶訂購過
SELECT DISTINCT
od.ProductID,
p.UnitsInStock,
o.CustomerID
FROM Products p
INNER JOIN [Order Details] od ON p.ProductID = od.ProductID
INNER JOIN Orders o ON od.OrderID=o.OrderID
WHERE UnitsInStock = 0

-- 列出每位員工的下屬的業績總金額
SELECT 
e.EmployeeID,
SUM(od.UnitPrice*od.Quantity*(1-od.Discount))AS SalesPrice
FROM Employees e
INNER JOIN Orders o ON e.EmployeeID=o.EmployeeID
INNER JOIN [Order Details] od ON o.OrderID=od.OrderID
WHERE e.ReportsTo=5
GROUP BY e.EmployeeID

-- 列出每家貨運公司運送最多的那一種產品類別與總數量
SELECT TOP 2
s.ShipperID,
o.ShipName,
od.Quantity,
p.CategoryID,
c.CategoryName
FROM Shippers s
INNER JOIN Orders o ON s.ShipperID=o.ShipVia
INNER JOIN [Order Details]od ON o.OrderID=od.OrderID
INNER JOIN Products p ON p.ProductID=od.ProductID
INNER JOIN Categories c ON p.CategoryID=c.CategoryID
GROUP BY s.ShipperID,o.ShipName,p.CategoryID,od.Quantity,c.CategoryName
ORDER BY od.Quantity DESC

-- 列出每一個客戶買最多的產品類別與金額**
WITH CTE1 AS(
SELECT
SUM(od.UnitPrice*od.Quantity*(1-od.Discount))AS SalesPrice,
ca.CategoryID,
ca.CategoryName,
ROW_NUMBER () OVER (PARTITION BY c.ContactName ORDER BY ca.CategoryID DESC) AS RowNUMBER
FROM Customers c
INNER JOIN Orders o ON c.CustomerID=o.CustomerID
INNER JOIN [Order Details] od ON o.OrderID=od.OrderID
INNER JOIN Products p ON od.ProductID=p.ProductID
INNER JOIN Categories ca ON p.CategoryID=ca.CategoryID
GROUP BY ca.CategoryID,ca.CategoryName, c.ContactName

)
SELECT
*
FROM　CTE1
WHERE RowNUMBER=1

-- 列出每一個客戶買最多的那一個產品與購買數量
WITH CC AS(
SELECT
c.CustomerID,
p.ProductName,
od.Quantity,
ROW_NUMBER () OVER (PARTITION BY c.CustomerID ORDER BY od.Quantity DESC) AS RowNUMBER
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN [Order Details]od ON o.OrderID=od.OrderID
INNER JOIN Products p ON od.ProductID=p.ProductID
)
SELECT * FROM CC
WHERE RowNUMBER=1

-- 按照城市分類，找出每一個城市最近一筆訂單的送貨時間
WITH CTE1 AS(
SELECT OrderID,ShippedDate,ShipCity ,
ROW_NUMBER () OVER (PARTITION BY ShipCity ORDER BY ShippedDate DESC) AS RowNUMBER
FROM Shippers s
INNER JOIN Orders o ON s.ShipperID=o.ShipVia
GROUP BY ShipCity,OrderID,ShippedDate
)
SELECT * FROM CTE1
WHERE RowNUMBER =1

-- 列出購買金額第五名與第十名的客戶，以及兩個客戶的金額差距
WITH CT AS(
SELECT
SUM(od.UnitPrice*od.Quantity*(1-od.Discount)) AS SalesPrice,
c.CustomerID,
ROW_NUMBER () OVER ( ORDER BY SUM(od.UnitPrice*od.Quantity*(1-od.Discount)) DESC) AS RowNUMBER
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY c.CustomerID
)
SELECT * FROM CT
WHERE RowNUMBER IN (5,10)

