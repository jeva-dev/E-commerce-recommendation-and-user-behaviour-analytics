-- Questions --

use ecommerce;

-- 1. Fetch all orders placed by users who joined before march 2024 --

SELECT o.orderid,o.userid,o.orderdate,o.totalamount,u.joindate FROM orders o INNER JOIN Users u 
ON o.orderid = u.userid WHERE u.joindate < '2024-03-01';

-- 2. List all products under the "Electronics" category with price greater than $100 --

SELECT Productname FROM products WHERE (category = "Electronics") AND (Price > 100);

-- 3. Scalar function to calculate total revenue from all orders [Scalar returns single value]-- 

DELIMITER $$

CREATE FUNCTION GetTotalRevenue() 
RETURNS DECIMAL(10,2) 
DETERMINISTIC  -- It will take the input value specified--
BEGIN 
    DECLARE totalrevenue DECIMAL(10,2);
    SELECT SUM(TotalAmount) INTO totalrevenue FROM Orders;
    RETURN totalrevenue;
END $$

DELIMITER ;

SELECT GetTotalRevenue() AS TotalRevenue;

-- 4.Function to return total products purchased by a specific user --

DELIMITER $$

CREATE FUNCTION GetTotalProducts(userName VARCHAR(255)) 
RETURNS INT 
DETERMINISTIC 
BEGIN
    DECLARE totalProducts INT;

    SELECT COALESCE(SUM(od.quantity), 0) INTO totalProducts
    FROM Users u
    INNER JOIN Orders o ON u.userid = o.userid
    INNER JOIN OrderDetails od ON o.orderid = od.orderid
    WHERE u.Name = userName;

    RETURN totalProducts;  
END $$

DELIMITER ;

SELECT GetTotalProducts('Eve') AS TotalProducts;

-- Transaction 

-- 5. Trasnsaction to place an order ensuring consistency -- 

DELIMITER $$

CREATE PROCEDURE ProcessOrder()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK; -- Used for undo the transaction --
    END;

    START TRANSACTION;

    -- Insert into Orders
    INSERT INTO Orders (OrderID, CustomerID, OrderDate, TotalAmount)
    VALUES (11, 3, '2024-12-01', 750);

    -- Insert into OrderDetails
    INSERT INTO OrderDetails (OrderDetailID, OrderID, ProductID, Quantity, Price)
    VALUES (11, 11, 101, 1, 700);

    -- Update Products
    UPDATE Products
    SET Stock = Stock - 1
    WHERE ProductID = 101;

    COMMIT;
END $$

DELIMITER ;

CALL ProcessOrder();

-- 6. Stored procedure to add a new user and recommend a random product. --

DELIMITER $$

CREATE PROCEDURE AddUserAndRecommendProduct (
    IN p_UserID INT,
    IN p_Name VARCHAR(100),
    IN p_Email VARCHAR(100),
    IN p_JoinDate DATE
)
BEGIN
    DECLARE v_ProductID INT;
    DECLARE v_RecommendationID INT;
    DECLARE userExists INT;

    -- Check if the UserID already exists
    SELECT COUNT(*) INTO userExists FROM Users WHERE UserID = p_UserID;

    IF userExists > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: UserID already exists.';
    ELSE
        -- Generate the next RecommendationID
        SELECT IFNULL(MAX(RecommendationID), 0) + 1 INTO v_RecommendationID FROM ProductRecommendations;

        -- Insert the new user
        INSERT INTO Users (UserID, Name, Email, JoinDate)
        VALUES (p_UserID, p_Name, p_Email, p_JoinDate);

        -- Recommend a random Product
        SELECT ProductID INTO v_ProductID FROM Products ORDER BY RAND() LIMIT 1;

        -- Insert the recommendation
        INSERT INTO ProductRecommendations (RecommendationID, UserID, ProductID, RecommendationDate)
        VALUES (v_RecommendationID, p_UserID, v_ProductID, CURDATE());
    END IF;
END$$

DELIMITER ;

CALL AddUserAndRecommendProduct(401, 'David Clark', 'david.clark@example.com', '2024-12-06');
CALL AddUserAndRecommendProduct(402, 'Emma Taylor', 'emma.taylor@example.com', '2024-12-07');

SELECT * FROM Users WHERE UserID IN (401, 402);

-- 7. Fetch the total revenue grouped by product categories with max to min --

SELECT p.category, SUM(od.subtotal) AS TotalRevenue from orderdetails as OD 
INNER JOIN Products p ON p.productid = od.productid 
GROUP BY p.category  ORDER BY TotalRevenue DESC;

 -- 8.  Identify the top 2 user Name, ID, total with the highest spending. --
 
SELECT  u.name, od.subtotal from Users u
INNER JOIN Orders o ON U.UserID = o.UserID 
INNER JOIN OrderDetails od On o.orderID = od.OrderID ORDER BY od.subtotal DESC LIMIT 2;

-- 9. Suggest products not yet purchased by a specific user. -- 

SELECT ProductID, ProductName, Category
FROM Products WHERE ProductID NOT IN (
    SELECT ProductID
    FROM Orders O 
    INNER JOIN OrderDetails OD 
    ON O.OrderID = OD.OrderID 
    WHERE O.UserID = 1);