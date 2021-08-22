

/*CREATE DATABASE tAssignment
use tAssignment*/

IF OBJECT_ID('Sale') IS NOT NULL
DROP TABLE SALE;
IF OBJECT_ID('Product') IS NOT NULL
DROP TABLE PRODUCT;
IF OBJECT_ID('Customer') IS NOT NULL
DROP TABLE CUSTOMER;
IF OBJECT_ID('Location') IS NOT NULL
DROP TABLE LOCATION;
GO

CREATE TABLE CUSTOMER
(
    CUSTID INT,
    CUSTNAME NVARCHAR(100),
    SALES_YTD MONEY
,
    STATUS NVARCHAR (7),
    PRIMARY KEY (CUSTID)
)

CREATE TABLE PRODUCT
(
    PRODID INT,
    PRODNAME NVARCHAR(100),
    SELLING_PRICE MONEY,
    SALES_YTD MONEY,
    PRIMARY KEY(PRODID)
);


CREATE TABLE [SALE]
(
    SALEID BIGINT,
    CUSTID INT,
    PRODID INT,
    QTY INT,
    PRICE MONEY,
    SALEDATE DATE,
    PRIMARY KEY (SALEID),
    FOREIGN KEY (CUSTID) REFERENCES CUSTOMER,
    FOREIGN KEY (PRODID) REFERENCES PRODUCT
);
CREATE TABLE LOCATION
(
    LOCID NVARCHAR(5),
    MINQTY INTEGER,
    MAXQTY INTEGER,
    PRIMARY KEY(LOCID),
    CONSTRAINT CHECK_LOCID_LENGTH CHECK(LEN(LOCID) = 5),
    CONSTRAINT CHECK_MINQTY_RANGE CHECK (MINQTY BETWEEN 0 AND 999),
    CONSTRAINT CHECK_MAXQTY_RANGE CHECK(MAXQTY BETWEEN 0 AND 999),
    CONSTRAINT CHECK_MAXQTY_GREATER_MIXQTY CHECK(MAXQTY >= MINQTY)
);

IF OBJECT_ID('SALE_SEQ') IS NOT NULL
        DROP SEQUENCE SALE_SEQ;
CREATE SEQUENCE SALE_SEQ;
GO
---------------------------------------------------------------------
IF OBJECT_ID('ADD_CUSTOMER') IS NOT NULL
DROP PROCEDURE ADD_CUSTOMER;
GO
CREATE PROCEDURE ADD_CUSTOMER
    @pcustname NVARCHAR(100),
    @pcustid INT
AS
BEGIN

    IF @pcustid < 1 OR @pcustid > 499
    THROW 50020, 'Customer ID out of range.', 1
    BEGIN TRY

    INSERT INTO CUSTOMER
        (CUSTID, CUSTNAME, SALES_YTD, [STATUS])
    VALUES
        (@pcustid, @pcustname, 0, 'OK');

    END TRY
    BEGIN CATCH
    IF ERROR_NUMBER() = 2627
    THROW 50010, 'Duplicate customerID', 1

    IF ERROR_NUMBER() = 2601
    THROW 50010, 'Duplicate Customer ID', 1

    IF ERROR_NUMBER() = ERROR_NUMBER()
    THROW 50000,  'Use value of error_message()', 1


    END CATCH;
END;
---------------------------------------------------------------------
GO
IF OBJECT_ID('DELETE_ALL_CUSTOMER') IS NOT NULL
DROP PROCEDURE DELETE_ALL_CUSTOMER;
GO

CREATE PROCEDURE DELETE_ALL_CUSTOMER
AS
BEGIN TRY
    DELETE CUSTOMER
    WHERE CUSTOMER.CUSTID = CUSTID
    RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = ERROR_NUMBER()
    THROW 50000, 'Use value of error_message()', 1
END CATCH;

GO
---------------------------------------------------------------------
IF OBJECT_ID('ADD_PRODUCT') IS NOT NULL
DROP PROCEDURE ADD_PRODUCT;
GO
CREATE PROCEDURE ADD_PRODUCT
    @pprodid INT,
    @pprodname NVARCHAR(100),
    @pprice MONEY,
    @SYTD MONEY
AS

BEGIN
    DECLARE @PID INT
    SELECT @PID = PRODID
    FROM PRODUCT
    WHERE @pprodid = PRODID

    IF @PID = @pprodid
    THROW 50030, 'Duplicate productID', 1

    IF @pprodid  < 1000 OR @pprodid > 2500
    THROW 50040, 'Product ID out of range', 1

    IF @pprice < 0 or @pprice > 999.99
    THROW 50050, 'Price out of range', 1

    IF ERROR_NUMBER() = 50040
    THROW 50040, 'Product ID out of range', 1

    BEGIN TRY
        INSERT INTO PRODUCT
    VALUES(
            @pprodid, @pprodname, @pprice, @SYTD
        )


    END TRY
    BEGIN CATCH

        IF ERROR_NUMBER() = ERROR_NUMBER()
        THROW 50000, 'Use Value of error_message()', 1


    END CATCH;
END
GO
---------------------------------------------------------------------
IF OBJECT_ID('DELETE_ALL_PRODUCTS') IS NOT NULL
DROP PROCEDURE DELETE_ALL_PRODUCTS;
GO
CREATE PROCEDURE DELETE_ALL_PRODUCTS
AS
BEGIN TRY
    DELETE PRODUCT
    WHERE  PRODID = PRODID
    RETURN @@ROWCOUNT

END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() = ERROR_NUMBER()
    THROW 50000, 'Use value of error_message()', 1
END CATCH;
---------------------------------------------------------------------
GO
IF OBJECT_ID('GET_CUSTOMER_STRING') IS NOT NULL
DROP PROCEDURE GET_CUSTOMER_STRING;
GO
CREATE PROCEDURE GET_CUSTOMER_STRING
    @pcustid INT,
    @pReturnString  NVARCHAR(1000) OUT
AS
BEGIN


    DECLARE @CNAME NVARCHAR(1000)
    DECLARE @STATUS NVARCHAR(7)
    DECLARE @SYTD MONEY

    SELECT @CNAME = CUSTNAME, @STATUS = STATUS, @SYTD = SALES_YTD
    FROM CUSTOMER
    WHERE CUSTID = @pcustid

    IF @@ROWCOUNT = 0
    THROW 50060, 'No matching customer id found', 1

    SET @pReturnString = CONCAT('Cust ID ', @pcustid, ' Name ', @CNAME, ' Status ', @STATUS, ' SYTD ', @SYTD);
    SELECT @pReturnString

END
---------------------------------------------------------------------

GO
IF OBJECT_ID('UPD_CUST_SALESYTD') IS NOT NULL
DROP PROCEDURE UPD_CUST_SALESYTD;
GO
CREATE PROCEDURE UPD_CUST_SALESYTD
    @pcustid INT,
    @pamt MONEY
AS
BEGIN
    BEGIN TRY

    IF @pamt < -999.99 or @pamt > 999.99
    THROW  50080, 'Amount out of range', 1

    UPDATE CUSTOMER SET SALES_YTD = SALES_YTD + @pamt
    WHERE CUSTID = @pcustid

    IF @@ROWCOUNT = 0
    THROW 50070, 'Customer ID not found', 1

  END TRY
 BEGIN CATCH
        IF ERROR_NUMBER() IN (50070, 50080)
        THROW
    END CATCH;
END
---------------------------------------------------------------------
GO

IF OBJECT_ID('GET_PROD_STRING') IS  NOT NULL
DROP PROCEDURE GET_PROD_STRING;
GO
CREATE PROCEDURE GET_PROD_STRING
    @pprodid INT,
    @pReturnString NVARCHAR(1000) OUT
AS
BEGIN


    DECLARE @PNAME NVARCHAR(100)
    DECLARE @PPRICE MONEY
    DECLARE @SYTDP MONEY

    SELECT @PNAME = PRODNAME, @PPRICE = SELLING_PRICE, @SYTDP = SALES_YTD
    FROM PRODUCT
    WHERE PRODUCT.PRODID = @pprodid

    IF @@ROWCOUNT = 0
    THROW 50090, 'Product ID not found', 1


    IF ERROR_MESSAGE() = ERROR_NUMBER()
    THROW 50000,  'Use value of error_message()', 1

    SET @pReturnString = CONCAT('Prodid: ', @pprodid, ' Name: ', @PNAME, ' Price: ', @PPRICE, ' Sales YTD: ', @SYTDP)
    SELECT @pReturnString

END
---------------------------------------------------------------------
GO
IF OBJECT_ID('UPD_PROD_SALESYTD') IS  NOT NULL
DROP PROCEDURE UPD_PROD_SALESYTD;
GO
CREATE PROCEDURE UPD_PROD_SALESYTD
    @pprodid INT,
    @pamt MONEY
AS
BEGIN

    IF @pamt < -999.99 OR @pamt > 999.99
    THROW  50110, 'Amount out of range', 1


    UPDATE PRODUCT SET SALES_YTD =  SALES_YTD + @pamt
    WHERE PRODID = @pprodid

    IF @@ROWCOUNT = 0
    THROW 50110, 'Product ID not found', 1

    IF ERROR_MESSAGE() = ERROR_NUMBER()
    THROW 50000, 'Use value of error_message()', 1

END
---------------------------------------------------------------------
GO
IF OBJECT_ID('UPD_CUSTOMER_STATUS') IS NOT NULL
DROP PROCEDURE UPD_CUSTOMER_STATUS;
GO
CREATE PROCEDURE UPD_CUSTOMER_STATUS
    @pcustid INT,
    @pstaus NVARCHAR(7)
AS
BEGIN

    IF NOT (@pstaus = 'OK' OR @pstaus = 'SUSPEND')
    THROW 50130, 'Invalid Status value', 1



    BEGIN TRY

    UPDATE CUSTOMER
    SET STATUS = @pstaus
    WHERE CUSTID = @pcustid

     IF @@ROWCOUNT = 0
    THROW 50120, 'Customer ID not found', 1

END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 50130
    THROW 50130, 'Invalid Status value', 1

     IF ERROR_NUMBER() = ERROR_NUMBER()
    THROW 50000, 'Use of error message()', 1
END CATCH;
END
---------------------------------------------------------------------
GO
IF OBJECT_ID('ADD_SIMPLE_SALE') IS NOT NULL
DROP PROCEDURE ADD_SIMPLE_SALE;
GO
CREATE PROCEDURE ADD_SIMPLE_SALE
    @pcustid INT,
    @pprodid INT,
    @pqty INT

AS
BEGIN

    IF @pqty < 1 OR @pqty > 999
    THROW  50140, 'Sale Quantity outside valid range', 1
    BEGIN TRY

    DECLARE @SP MONEY
    DECLARE @Status NVARCHAR(7);
    DECLARE @CUST INT
    DECLARE @PROD INT

    SELECT @Status = STATUS, @CUST = C.CUSTID
    FROM CUSTOMER C
    WHERE CUSTID = @pcustid;

    IF @CUST != @pcustid OR @CUST IS NULL
    THROW 50150, 'Customer ID is not found', 1

    IF NOT (@Status =  'OK')
    THROW 50160, 'Customer status is not OK', 1

    SELECT @PROD = P.PRODID, @SP = SELLING_PRICE
    FROM PRODUCT P
    WHERE PRODID = @pprodid

    IF @PROD != @pprodid OR @PROD IS NULL
    THROW 50170, 'Product ID not found', 1;

    DECLARE @TOTAL MONEY = @SP * @pqty

    EXEC UPD_CUST_SALESYTD @pcustid, @TOTAL
    EXEC UPD_PROD_SALESYTD @pprodid, @TOTAL

    END TRY
    BEGIN CATCH
    DECLARE @MSG NVARCHAR(100) = ERROR_MESSAGE();
    DECLARE @NUM INT = ERROR_NUMBER()

    IF ERROR_NUMBER() IN (50140, 50150, 50160, 50170)
    THROW @NUM, @MSG, 1;
    
    IF ERROR_NUMBER() = ERROR_NUMBER()
    THROW 50000, @MSG, 1
    END CATCH;
END

---------------------------------------------------------------------
GO
IF OBJECT_ID('SUM_CUSTOMER_SALESYTD') IS NOT NULL
DROP PROCEDURE SUM_CUSTOMER_SALESYTD;
GO
CREATE PROCEDURE SUM_CUSTOMER_SALESYTD
AS
BEGIN
    BEGIN TRY
    SELECT SUM(SALES_YTD)
    FROM CUSTOMER
    END TRY
    BEGIN CATCH
    THROW 50000,  'Use value of error_message()', 1
    END CATCH
END
---------------------------------------------------------------------
GO
IF OBJECT_ID('SUM_PRODUCT_SALESYTD') IS NOT NULL
DROP PROCEDURE SUM_PRODUCT_SALESYTD;
GO
CREATE PROCEDURE SUM_PRODUCT_SALESYTD
AS
BEGIN
    BEGIN TRY
    SELECT SUM(SALES_YTD)
    FROM PRODUCT
    END TRY
    BEGIN CATCH
    THROW 50000,  'Use value of error_message()', 1
    END CATCH
END
---------------------------------------------------------------------
GO
IF OBJECT_ID('ADD_LOCATION') IS NOT NULL
DROP PROCEDURE ADD_LOCATION;
GO
CREATE PROCEDURE ADD_LOCATION
    @ploccode NVARCHAR(5),
    @pminqty INT,
    @pmaxqty INT
AS
BEGIN
    BEGIN TRY
    INSERT INTO [Location]
    VALUES(
            @ploccode, @pminqty, @pmaxqty
    )
    END TRY
    BEGIN CATCH

    IF ERROR_MESSAGE() LIKE '%CHECK_LOCID_LENGTH%'
    THROW 50190, 'Location Code length invalid', 1

    IF ERROR_MESSAGE() LIKE '%CHECK_MINQTY_RANGE%'
    THROW 50200, 'Minimum Qty out of range', 1

    IF ERROR_MESSAGE() LIKE '%CHECK_MAXQTY_RANGE%'
    THROW 50210, 'Maximum Qty out of range', 1

    IF ERROR_MESSAGE() LIKE '%CHECK_MAXQTY_GREATER_MIXQTY %'
    THROW 50220, 'Minimum Qty larger than Maximum Qty', 1

    END CATCH
END
---------------------------------------------------------------------
GO
IF OBJECT_ID('ADD_COMPLEX_SALE') IS NOT NULL
DROP PROCEDURE ADD_COMPLEX_SALE;
GO
CREATE PROCEDURE ADD_COMPLEX_SALE
    @pcustid INT,
    @pprodid INT,
    @pqty INT,
    @pdate NVARCHAR(8)
AS
BEGIN
    BEGIN TRY

        DECLARE @CSATUS NVARCHAR(7)
        DECLARE @CUST INT


        IF @pqty < 1 OR @pqty > 999
        THROW 50230, 'Sale Quantity outside valid range', 1

        SELECT @CUST = CUSTID, @CSATUS = [STATUS]
    FROM CUSTOMER
    WHERE @pcustid = CUSTID

        IF @CUST != @pcustid OR @CUST IS NULL 
        THROW 50260, 'Customer ID not found', 1

        IF @CSATUS != 'OK'
        THROW 50240, 'Customer status is not OK', 1

        DECLARE @SP MONEY
        DECLARE @PRODID INT

        SELECT @SP = SELLING_PRICE, @PRODID = PRODID
        FROM PRODUCT
        WHERE PRODID = @pprodid;

        IF @PRODID IS NULL OR @PRODID != @pprodid
        THROW 50270, 'Product ID not found', 1


        BEGIN TRY 
            DECLARE @date DATE =  CONVERT(date, @pdate);
        END TRY 
        BEGIN CATCH 
            THROW 50250, 'Date not valid', 1
        END CATCH 
        
        DECLARE @SALEID BIGINT = NEXT VALUE FOR SALE_SEQ

        DECLARE @TOTAL MONEY

        

        SET @TOTAL = @SP * @pqty
        INSERT INTO SALE
    VALUES(
            @SALEID, @pcustid, @pprodid, @pqty, @TOTAL, @date
        )



    EXEC UPD_CUST_SALESYTD @pcustid, @TOTAL
    EXEC UPD_PROD_SALESYTD @pprodid, @TOTAL
    END TRY
    BEGIN CATCH
    DECLARE @MSG NVARCHAR(100) = ERROR_MESSAGE();
    DECLARE @NUM INT = ERROR_NUMBER()

    IF ERROR_NUMBER() IN (50230, 50260, 50240, 50270, 50250)
    THROW @NUM, @MSG, 1;
    
    IF ERROR_NUMBER() = ERROR_NUMBER()
    THROW 50000, @MSG, 1
    END CATCH
END
---------------------------------------------------------------------
GO
IF OBJECT_ID('COUNT_PRODUCT_SALES') IS NOT NULL
DROP PROCEDURE COUNT_PRODUCT_SALES;
GO
CREATE PROCEDURE COUNT_PRODUCT_SALES
    @pdays INT
AS
BEGIN
    BEGIN TRY
    SELECT COUNT(*)
    FROM SALE
    WHERE  SALEDATE BETWEEN  DATEADD(DAY, -@pdays, CONVERT(DATE, GETDATE())) AND CONVERT(DATE, GETDATE())

    END TRY
    BEGIN CATCH
    THROW 50000, 'Use value of error_message()', 1

    END CATCH
END
GO
---------------------------------------------------------------------
IF OBJECT_ID('DELETE_SALE') IS NOT NULL
DROP PROCEDURE DELETE_SALE;
GO
CREATE PROCEDURE DELETE_SALE
AS
BEGIN

    DECLARE @MINSALEID BIGINT, @SCUSTID INT, @TOTAL MONEY, @PPRODID INT
    SELECT @MINSALEID = MIN(SALEID), @SCUSTID = CUSTID, @TOTAL = PRICE * -QTY, @PPRODID = PRODID
    FROM SALE 
    GROUP BY SALEID, CUSTID, PRICE, QTY, PRODID
    
    IF @@ROWCOUNT = 0
    THROW 50280, 'No Sale Rows Found', 1

        BEGIN TRY

        DELETE
        FROM SALE
        WHERE SALEID = @MINSALEID

        EXEC UPD_CUST_SALESYTD @SCUSTID, @TOTAL
        EXEC UPD_PROD_SALESYTD @PPRODID, @TOTAL

        SELECT @MINSALEID
        PRINT @MINSALEID
    END TRY
    BEGIN CATCH
    IF ERROR_NUMBER() = ERROR_NUMBER()
    THROW 50000,  'Use value of error_message()', 1
    END CATCH
END
GO
--------------------------------------------------------------------
IF OBJECT_ID('DELETE_ALL_SALES') IS NOT NULL
DROP PROCEDURE DELETE_ALL_SALES;
GO
CREATE PROCEDURE DELETE_ALL_SALES
AS
BEGIN
    BEGIN TRY
    DELETE
    FROM SALE

    UPDATE CUSTOMER
    SET SALES_YTD = 0

    UPDATE PRODUCT
    SET SALES_YTD = 0

    END TRY
    BEGIN CATCH
    IF ERROR_NUMBER() = ERROR_NUMBER()
    THROW 50000,  'Use value of error_message()', 1
    END CATCH
END
GO
---------------------------------------------------------------------
IF OBJECT_ID('DELETE_CUSTOMER') IS NOT NULL
DROP PROCEDURE DELETE_CUSTOMER;
GO
CREATE PROCEDURE DELETE_CUSTOMER @PCUSTID INT
AS
BEGIN
    BEGIN TRY
        SELECT *
        FROM SALE
        WHERE CUSTID = @PCUSTID 
        
        IF @@ROWCOUNT = 0
        BEGIN
            DELETE
            FROM CUSTOMER
            WHERE CUSTID = @PCUSTID

            IF @@ROWCOUNT = 0
            THROW 50290, 'Customer ID not found', 1
        END
        ELSE
            THROW 50300, 'Customer cannot be deleted as sales exist', 1

    END TRY
    BEGIN CATCH
    DECLARE @MSG NVARCHAR(100) = ERROR_MESSAGE();
    DECLARE @NUM INT = ERROR_NUMBER()

    IF ERROR_NUMBER() IN (50290, 50300)
    THROW @NUM, @MSG, 1;
    
    IF ERROR_NUMBER() = ERROR_NUMBER()
    THROW 50000, @MSG, 1
    END CATCH
END
GO
---------------------------------------------------------------------
IF OBJECT_ID('DELETE_PRODUCT') IS NOT NULL
DROP PROCEDURE DELETE_PRODUCT;
GO
CREATE PROCEDURE DELETE_PRODUCT @PPRODID INT
AS
BEGIN
    BEGIN TRY
        SELECT *
        FROM SALE
        WHERE @PPRODID = PRODID 
        
        IF @@ROWCOUNT = 0
        BEGIN
            DELETE
            FROM PRODUCT
            WHERE @PPRODID = PRODID

            IF @@ROWCOUNT = 0
            THROW 50310, 'Product ID not found', 1
        END
        ELSE
            THROW 50320, 'Product cannot be deleted as sales exist', 1

    END TRY
    BEGIN CATCH
    DECLARE @MSG NVARCHAR(100) = ERROR_MESSAGE();
    DECLARE @NUM INT = ERROR_NUMBER()

    IF ERROR_NUMBER() IN (50310, 50320)
    THROW @NUM, @MSG, 1;
    
    IF ERROR_NUMBER() = ERROR_NUMBER()
    THROW 50000, @MSG, 1
    END CATCH
END


--TESTING
---------------------------------------------------------------------
-- ADD_CUSTOMER
--OUTSIDE OF RANGE CUSTID
EXEC ADD_CUSTOMER 'TEST1', 0
EXEC ADD_CUSTOMER 'TEST2', 500

-- DUPLICATE CUST ID
EXEC ADD_CUSTOMER 'TEST1', 111
EXEC ADD_CUSTOMER 'TEST2', 111

-- SUCCESSFUL EXEC
EXEC ADD_CUSTOMER 'TEST_PASS', 123

DROP TABLE CUSTOMER
DROP TABLE SALE
---------------------------------------------------------------------
-- DELETE_ALL_CUSTOMERS

EXEC ADD_CUSTOMER 'DELETE_ ME', 123
EXEC DELETE_ALL_CUSTOMER
---------------------------------------------------------------------
-- ADD_PRODUCT
--OUT OF RANGE PRODID
EXEC ADD_PRODUCT 999, 'PRODTEST1', 10, 10
EXEC ADD_PRODUCT 2501, 'PRODTEST2', 10, 10

-- PPRICE OUT OF RANGE
EXEC ADD_PRODUCT 1200, 'PRODTEST1', 1000, 10
EXEC ADD_PRODUCT 1000, 'PRODTEST2', -1, 10

--DUPLICATE ID
EXEC ADD_PRODUCT 1200, 'PRODTEST1', 60, 10
EXEC ADD_PRODUCT 1200, 'PRODTEST2', 50, 10

-- SUCCESSFUL EXEC
EXEC ADD_PRODUCT 1234, 'TEST_PASS', 50, 10
---------------------------------------------------------------------
-- DELETE_ALL_PRODUCTS
EXEC ADD_PRODUCT 1234, 'DELETE_ME', 50, 10
EXEC DELETE_ALL_PRODUCTS
---------------------------------------------------------------------
-- GET_CUSTOMER_STRING

EXEC ADD_CUSTOMER 'CUSTSTRING_TEST', 123

DECLARE @CUSTOUTPUT NVARCHAR(1000)
-- SUCCESSFUL EXEC
EXEC GET_CUSTOMER_STRING 123, @CUSTOUTPUT
-- NO MATCHING CUST ID
EXEC GET_CUSTOMER_STRING 124, @CUSTOUTPUT
PRINT @OUTPUT
---------------------------------------------------------------------
-- UPD_CUST_SALESYTD
-- ADDING CUST
EXEC ADD_CUSTOMER 'SALESYTD_TEST', 124
-- PAMT OUT OF RANGE
EXEC UPD_CUST_SALESYTD 124, -1000
EXEC UPD_CUST_SALESYTD 124, 1000

-- NO ROWS UPDATED(CUST ID NOT FOUND)
EXEC UPD_CUST_SALESYTD 125, 50

-- SUCCESSFUL EXEC
EXEC UPD_CUST_SALESYTD 124, 50
---------------------------------------------------------------------
-- GET_PROD_STRING
--ADDING PRODUCT
EXEC ADD_PRODUCT 1222, 'PRODSTRING_TEST', 20, 10


DECLARE @PRODOUTPUT NVARCHAR(1000)
-- SUCCESSFUL EXEC
EXEC GET_PROD_STRING 1222, @PRODOUTPUT
--NO MATCHING PROD ID
EXEC GET_PROD_STRING 1223, 'TESTFAIL'
PRINT @PRODOUTPUT
---------------------------------------------------------------------
-- UPD_PROD_SALESYTD
EXEC ADD_PRODUCT 1223, 'UPDTEST_PROD', 100, 20

--PAMT OUT OF RANGE
EXEC UPD_PROD_SALESYTD 1223, -1000
EXEC UPD_PROD_SALESYTD 1223, 1000

--PRODUCT ID NOT FOUND
EXEC UPD_PROD_SALESYTD 1224, 888

-- SUCCESSFUL EXEC
EXEC UPD_PROD_SALESYTD 1223, 50
---------------------------------------------------------------------
-- UPD_CUSTOMER_STATUS
EXEC ADD_CUSTOMER 'CUST_STATUS_TEST', 125

-- CUST ID NOT FOUND
EXEC UPD_CUSTOMER_STATUS 124, 'SUSPEND'

-- INVALID STATUS (NOT 'OK' OR 'SUSPEND')
EXEC UPD_CUSTOMER_STATUS 123, 'NO'
EXEC UPD_CUSTOMER_STATUS 123, 'THIS WILL NOT WORK'

-- SUCCESSFUL EXEC
EXEC ADD_CUSTOMER 'TEST_PASS', 250
EXEC UPD_CUSTOMER_STATUS 250, 'SUSPEND'
EXEC UPD_CUSTOMER_STATUS 250, 'OK'
---------------------------------------------------------------------
-- ADD_SIMPLE_SALE
--ADDING CUSTOMER AND PRODUCT DATA
EXEC ADD_CUSTOMER 'SIMPLSALE_TEST', 135
EXEC ADD_PRODUCT 1246, 'SIMPLESALE_TESTPROD', 5, 10

--SALE QTY OUT OF RANGE
EXEC ADD_SIMPLE_SALE 135, 1244, 1000
EXEC ADD_SIMPLE_SALE 135, 1244, 0

--INVALID CUSTOMER STATUS
--UPDATE CUSTOMER STATUS = 'SUSPEND'
EXEC UPD_CUSTOMER_STATUS 135, 'SUSPEND'
--EXECUTE CUSTOMER WITH INCORRECT STATUS
EXEC ADD_SIMPLE_SALE 135, 1244, 50


--CANNOT FIND CUSTOMER ID
EXEC ADD_SIMPLE_SALE 134, 1244, 50
EXEC ADD_SIMPLE_SALE 135, 1243, 5

--SUCCESSFUL EXEC
EXEC ADD_SIMPLE_SALE 135, 1246, 5
---------------------------------------------------------------------
--SUM_CUSTOMER_SALESYTD
-- CREATE CUSTOMER
EXEC ADD_CUSTOMER 'TEST1', 112
EXEC ADD_CUSTOMER 'TEST2', 113
--ADD SALES TO CUSTOMER 
EXEC UPD_CUST_SALESYTD 112, 5
EXEC UPD_CUST_SALESYTD 113, 6
--------------------------
EXEC SUM_CUSTOMER_SALESYTD
---------------------------------------------------------------------
--SUM_PRODUCT_SALESYTD
EXEC ADD_PRODUCT 1111, 'TEST1', 10, 10
EXEC ADD_PRODUCT 1112, 'TEST2', 10, 10

EXEC SUM_PRODUCT_SALESYTD
---------------------------------------------------------------------
-- ADD_LOCATION
--CHECK LOCID LENGTH
EXEC ADD_LOCATION 'JFHDHHHH', 20, 20

--CHECK MIN QTY
EXEC ADD_LOCATION 'TEST1', 1000, 20

--CHECK MAX QTY
EXEC ADD_LOCATION 'TEST2', 20, 1000

--SUCCESSFUL EXEC
EXEC ADD_LOCATION 'PASS1', 20, 30 
---------------------------------------------------------------------
--ADD_COMPLEX_SALE
--DATE NOT VALID
EXEC ADD_COMPLEX_SALE 123, 1234, 5, 'SFGGVUSV'
--NO VALID CUSTOMER ID + PRODUCT ID
EXEC ADD_COMPLEX_SALE 127, 1234, 5, '20210822'
EXEC ADD_COMPLEX_SALE 123, 1249, 5, '20210822'
--SUCCESSFUL EXEC
EXEC ADD_COMPLEX_SALE 123, 1234, 5, '20210821'
--SALE QTY OUT OF RANGE
EXEC ADD_COMPLEX_SALE 123, 1234, 1000, '20210821'
EXEC ADD_COMPLEX_SALE 123, 1234, 0, '20210821'
---------------------------------------------------------------------
--COUNT_PRODUCT_SALES
EXEC COUNT_PRODUCT_SALES 07
---------------------------------------------------------------------
--DELETE_SALE
EXEC DELETE_SALE 
---------------------------------------------------------------------
--DELETE_ALL_SALES
EXEC DELETE_ALL_SALES
---------------------------------------------------------------------
EXEC DELETE_CUSTOMER 1235
---------------------------------------------------------------------
EXEC DELETE_PRODUCT 1234
---------------------------------------------------------------------




