--a. Stored Procedures
--Crear la siguiente tabla CustomerStatistics con los siguientes campos
--customer_num (entero y pk), ordersqty (entero), maxdate (date), uniqueProducts
--(entero)
--Crear un procedimiento ‘actualizaEstadisticas’ que reciba dos parámetros
--customer_numDES y customer_numHAS y que en base a los datos de la tabla
--customer cuyo customer_num estén en en rango pasado por parámetro, inserte (si
--no existe) o modifique el registro de la tabla CustomerStatistics con la siguiente
--información:
--Ordersqty contedrá la cantidad de órdenes para cada cliente.
--Maxdate contedrá la fecha máxima de la última órde puesta por cada cliente.
--uniqueProducts contendrá la cantidad única de tipos de productos adquiridos por cada cliente.
CREATE TABLE CustomerStatistics(
customer_num smallint PRIMARY KEY,
ordersqty int,
maxdate date,
uniqueProducts int
)

DELETE FROM CustomerStatistics
DROP PROCEDURE actualizaEstadisticas 

CREATE PROCEDURE [dbo].[actualizaEstadisticas]
@customer_numDES smallint ,@customer_numHAS smallint
AS
BEGIN
	DECLARE @customer_var smallint,@ordersqty int,@maxdatetime datetime,@uniqueProducts int;
	DECLARE customers_cursor CURSOR FOR
	SELECT customer_num FROM customer
	WHERE customer_num BETWEEN @customer_numDES AND @customer_numHAS;
	
	OPEN customers_cursor
	FETCH NEXT FROM customers_cursor INTO @customer_var;

	WHILE(@@FETCH_STATUS=0)
	BEGIN
		IF((SELECT count(*) FROM CustomerStatistics WHERE CustomerStatistics.customer_num = @customer_var)=0)
			BEGIN
			INSERT INTO CustomerStatistics (customer_num) VALUES (@customer_var);
			END
		SELECT @ordersqty= count(*) FROM orders o
		WHERE o.customer_num=@customer_var
	
		SELECT TOP 1 @maxdatetime= o.order_date FROM orders o
		WHERE o.customer_num=@customer_var
		ORDER BY o.order_date DESC;

		SELECT @uniqueProducts= COUNT(DISTINCT i.stock_num)
		FROM orders o JOIN items i
		ON o.customer_num=@customer_var
		AND o.order_num=i.order_num

		UPDATE CustomerStatistics 
		SET ordersqty =@ordersqty,
			maxdate = @maxdatetime,
			uniqueProducts = @uniqueProducts
		WHERE customer_num=@customer_var
		
		FETCH NEXT FROM customers_cursor INTO @customer_var
		 
	END;
	CLOSE customers_cursor
	DEALLOCATE customers_cursor
	
END


SELECT * FROM CustomerStatistics

execute actualizaEstadisticas 101,110



--2 Crear un procedimiento ‘migraClientes’ que reciba dos parámetros
--customer_numDES y customer_numHAS y que dependiendo el tipo de cliente y la
--cantidad de órdenes los inserte en las tablas clientesCalifornia, clientesNoCaBaja,
--clienteNoCAAlta.

--• El procedimiento deberá migrar de la tabla customer todos los
--clientes de California a la tabla clientesCalifornia, los clientes que no
--son de California pero tienen más de 999u$ en OC en
--clientesNoCaAlta y los clientes que tiene menos de 1000u$ en OC en
--la tablas clientesNoCaBaja.
--• Se deberá actualizar un campo status en la tabla customer con valor
--‘P’ Procesado, para todos aquellos clientes migrados.
--• El procedimiento deberá contemplar toda la migración como un lote,
--en el caso que ocurra un error, se deberá informar el error ocurrido y
--abortar y deshacer la operación.

ALTER PROCEDURE migraClientes
@customer_numDES smallint,@customer_numHAS smallint
AS
BEGIN
	DECLARE @customer smallint,@totalenOC decimal(8,2)
	DECLARE customers_cursor CURSOR FOR
	SELECT customer_num FROM customer
	WHERE customer_num BETWEEN @customer_numDES AND @customer_numHAS

	OPEN customers_cursor;
	FETCH NEXT FROM customers_cursor INTO @customer;

	WHILE(@@FETCH_STATUS=0)
		BEGIN
			IF((SELECT COUNT(*) FROM customer c WHERE c.customer_num=@customer AND c.status IS NULL OR c.status != 'P')=1)
			BEGIN
			
			IF((SELECT COUNT(*) FROM customer c WHERE c.customer_num=@customer AND c.state='CA')=1)
			BEGIN
				INSERT INTO clientesCalifornia 
				(customer_num,fname,lname,company, address1,address2,city,state,zipcode,phone,customer_num_referedBy)
				SELECT customer_num,fname,lname,company, address1,address2,city,state,zipcode,phone,customer_num_referedBy 
				FROM customer c
				WHERE c.customer_num=@customer ;
				UPDATE customer SET customer.status='P' WHERE customer.customer_num=@customer;
			END
			
			ELSE 
			BEGIN
				IF( (SELECT SUM(i.quantity*i.unit_price) FROM orders o join items i
								ON o.order_num=i.order_num
								AND o.customer_num=@customer)<1000)
				BEGIN
				INSERT INTO clientesNoCaBaja 
				(customer_num,fname,lname,company, address1,address2,city,state,zipcode,phone,customer_num_referedBy)
				SELECT customer_num,fname,lname,company, address1,address2,city,state,zipcode,phone,customer_num_referedBy 
				FROM customer c
				WHERE c.customer_num=@customer ;
				UPDATE customer SET customer.status='P' WHERE customer.customer_num=@customer;
				END

				ELSE
				BEGIN
				INSERT INTO clientesNoCaAlta 
				(customer_num,fname,lname,company, address1,address2,city,state,zipcode,phone,customer_num_referedBy)
				SELECT customer_num,fname,lname,company, address1,address2,city,state,zipcode,phone,customer_num_referedBy 
				FROM customer c
				WHERE c.customer_num=@customer ;
				UPDATE customer SET customer.status='P' WHERE customer.customer_num=@customer;
				END
			END
			END
			FETCH NEXT FROM customers_cursor INTO @customer

		END
		CLOSE customers_cursor;
		DEALLOCATE customers_cursor;


END


SELECT * FROM clientesCalifornia

SELECT * FROM clientesNoCaAlta
SELECT * FROM clientesNoCaBaja
SELECT * FROM customer
execute migraClientes 101,123
DELETE FROM clientesCalifornia


UPDATE customer  
SET status=NULL
WHERE customer.customer_num BETWEEN 101 AND 123

DROP TABLE clientesCalifornia
CREATE TABLE clientesCalifornia(
	customer_num smallint PRIMARY KEY,
	fname varchar(15) NULL,
	lname varchar(15) NULL,
	company varchar(20) NULL,
	address1 varchar(20) NULL,
	address2 varchar(20) NULL,
	city varchar(15) NULL,
	state char(2) NULL,
	zipcode char(5) NULL,
	phone varchar(18) NULL,
	customer_num_referedBy smallint NULL)

DROP TABLE clientesNoCaAlta
CREATE TABLE clientesNoCaAlta(
	customer_num smallint PRIMARY KEY,
	fname varchar(15) NULL,
	lname varchar(15) NULL,
	company varchar(20) NULL,
	address1 varchar(20) NULL,
	address2 varchar(20) NULL,
	city varchar(15) NULL,
	state char(2) NULL,
	zipcode char(5) NULL,
	phone varchar(18) NULL,
	customer_num_referedBy smallint NULL)

DROP TABLE clientesNoCaBaja
CREATE TABLE clientesNoCaBaja(
	customer_num smallint PRIMARY KEY,
	fname varchar(15) NULL,
	lname varchar(15) NULL,
	company varchar(20) NULL,
	address1 varchar(20) NULL,
	address2 varchar(20) NULL,
	city varchar(15) NULL,
	state char(2) NULL,
	zipcode char(5) NULL,
	phone varchar(18) NULL,
	customer_num_referedBy smallint NULL)




--Crear un procedimiento ‘actualizaPrecios’ que reciba como parámetros
--manu_codeDES, manu_codeHAS y porcActualizacion que  genere las siguientes tablas listaPrecioMayor y
--listaPreciosMenor. Ambas tienen las misma estructura que la tabla Productos.
--El procedimiento deberá tomar de la tabla stock todos los productos que
--correspondan al rango de fabricantes asignados por parámetro.
--Por cada producto del fabricante se evaluará la cantidad (quantity) que le fue comprada.
--Si la misma es mayor o igual a 500 se grabará el producto en la tabla
--listaPrecioMayor y el unit_price deberá ser actualizado con (unit_price *
--(porcActualización *0,80)),
--Si la cantidad comprada del producto es menor a 500 se actualizará (o insertará)
--en la tabla listaPrecioMenor y el unit_price se actualizará con (unit_price *
--porcActualizacion)
--Asimismo, se deberá actualizar un campo status de la tabla stock con valor ‘A’
--Actualizado, para todos aquellos productos con cambio de precio actualizado.
--El procedimiento deberá contemplar todas las operaciones de cada fabricante
--como un lote, en el caso que ocurra un error, se deberá informar el error ocurrido
--y deshacer la operación de ese fabricante.


ALTER TABLE products 
ADD status char(1);
ALTER PROCEDURE actualizarPrecios 
@manu_codeDES char(3),@manu_codeHAS char(3),@porcActualizacion decimal(8,3)
AS
BEGIN
	DECLARE @stock_num smallint,@manu_code char(3),@unit_price decimal(6,2),@unit_code smallint;
	DECLARE products_cursor CURSOR FOR
	SELECT stock_num,manu_code,unit_price,unit_code
	FROM products p
	WHERE p.manu_code BETWEEN @manu_codeDES AND @manu_codeHAS;
	OPEN products_cursor;
	FETCH NEXT FROM products_cursor INTO @stock_num,@manu_code,@unit_price,@unit_code
	WHILE(@@FETCH_STATUS=0)
		BEGIN
			IF((SELECT SUM(i.quantity) FROM items i WHERE i.manu_code=@manu_code AND i.stock_num=@stock_num )>=0)
			BEGIN
				INSERT INTO listaPrecioMayor (stock_num ,manu_code,unit_price,unit_code)
				VALUES (@stock_num,@manu_code,@unit_price*@porcActualizacion *0.80,@unit_code);
				
				
			END
			ELSE
			BEGIN
				INSERT INTO listaPreciosMenor(stock_num ,manu_code,unit_price,unit_code)
				VALUES (@stock_num,@manu_code,@unit_price*@porcActualizacion,@unit_code);
			END
			UPDATE products SET status='A' WHERE stock_num= @stock_num AND manu_code=@manu_code;
			FETCH NEXT FROM products_cursor INTO @stock_num,@manu_code,@unit_price,@unit_code;
		END
	CLOSE products_cursor;
	DEALLOCATE products_cursor;

			
END

