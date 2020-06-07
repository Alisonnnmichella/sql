--a. Stored Procedures
--1. Crear la tabla CustomerStatistics con los siguientes campos customer_num
--(entero y pk), ordersQty (entero), maxDate (date), productsQty (entero)
--2. Crear un procedimiento �CustomerStatisticsUpdate� que reciba el par�metro
--fecha_DES (date) y que en base a los datos de la tabla Customer, inserte (si
--no existe) o actualice el registro de la tabla CustomerStatistics con la
--siguiente informaci�n:
--ordersqty: cantidad de �rdenes para cada cliente + las nuevas
--�rdenes con fecha mayor o igual a fecha_DES
--maxDate: fecha de la �ltima �rden del cliente.
--productsQty: cantidad �nica de productos adquiridos por cada
--cliente hist�rica

CREATE TABLE CustomerStatistics(
	customer_num smallint PRIMARY KEY,
	ordersQty INT,
	maxDate DATE,
	productsQty INT
);
DROP PROCEDURE CustomerStatisticsUpdate
ALTER PROCEDURE CustomerStatisticsUpdate
@fecha_DES DATETIME AS
BEGIN
	DECLARE @ordersqty INT,@maxDate DATETIME, @productsQty INT,@customer smallint;
	DECLARE curstomer_cursor CURSOR FOR
	SELECT customer_num  FROM customer;
	OPEN  curstomer_cursor;
	FETCH NEXT FROM curstomer_cursor INTO @customer;
	WHILE @@FETCH_STATUS=0
		BEGIN
			SELECT @ordersqty=COUNT(*),@maxDate=MAX(o.order_date)
			FROM orders o
			WHERE o.customer_num=@customer
			AND o.order_date>=@fecha_DES;

			SELECT @productsQty= COUNT(*) FROM (
			SELECT DISTINCT i.manu_code,i.stock_num
			FROM items i join orders o
			ON i.order_num=o.order_num
			AND o.customer_num=@customer) cantidadDeProductos;
			
			IF((SELECT COUNT(*) FROM CustomerStatistics cs WHERE cs.customer_num=@customer)=0)
			BEGIN
			INSERT INTO CustomerStatistics (customer_num,ordersQty,maxDate,productsQty)
			VALUES(@customer,@ordersQty,@maxDate,@productsQty)
			END
			
			ELSE
			BEGIN
			UPDATE CustomerStatistics SET ordersQty=ordersQty+@ordersQty,maxDate=@maxDate,productsQty=@productsQty
			WHERE customer_num=@customer
			END
			
			FETCH NEXT FROM curstomer_cursor INTO @customer;
		END 
	CLOSE curstomer_cursor;
	DEALLOCATE curstomer_cursor;

END


--Notas: no lo pide el ejercicio, y la solucion concuerda con lo esperado pero cada vez que se ejecute de vuelta
--el storeprocedure va a sumar al ordersqty



--Stored Procedures
--1. Crear la tabla informeStock con los siguientes campos: fechaInforme (date),
--stock_num (entero), manu_code (char(3)), cantOrdenes (entero), UltCompra
--(date), cantClientes (entero), totalVentas (decimal). PK (fechaInforme,
--stock_num, manu_code)

CREATE TABLE informeStock(
fechaInforme DATE,
stock_num smallint,
manu_code char(3),
cantOrdenes int,
ultCompra date,
cantClientes int,
totalVentas decimal(8,2)
CONSTRAINT pk_informeStock
PRIMARY KEY (fechaInforme,stock_num,manu_code));

--2. Crear un procedimiento �generarInformeGerencial� que reciba un par�metro
--fechaInforme y que en base a los datos de la tabla PRODUCTS de todos los
--productos existentes, inserte un registro de la tabla informeStock con la
--siguiente informaci�n:
--fechaInforme: fecha pasada por par�metro
--stock_num: n�mero de stock del producto
--manu_code: c�digo del fabricante
--cantOrdenes: cantidad de �rdenes que contengan el producto.
--UltCompra: fecha de �ltima orden para el producto evaluado.
--cantClientes: cantidad de clientes �nicos que hayan comprado el
--producto.
--totalVentas: Sumatoria de las ventas de ese producto (p x q)
--Validar que no exista en la tabla informeStock un informe con la misma
--fechaInforme recibida por par�metro.

ALTER PROCEDURE generarInformeGerencial
@fechaInforme DATE AS
BEGIN
	IF((SELECT COUNT(*) FROM informeStock i WHERE i.fechaInforme=@fechaInforme)=0)
	BEGIN
	DECLARE @stock_num smallint,@manu_code char(3),@cantOrdenes int,
	@ultCompra date,@cantClientes int,@totalVentas decimal(8,2);
	DECLARE products_cursor CURSOR FOR
	SELECT p.stock_num ,p.manu_code FROM products p;
	OPEN products_cursor;
	FETCH NEXT FROM products_cursor INTO @stock_num,@manu_code;
	WHILE(@@FETCH_STATUS=0)
		BEGIN 
		SELECT @cantOrdenes=COUNT(DISTINCT o.order_num), @ultCompra=max(o.order_date),@cantClientes=COUNT(DISTINCT o.customer_num),@totalVentas=SUM(i.quantity*i.unit_price)  
		FROM  orders o join items i
		ON i.order_num= o.order_num
		AND i.manu_code=@manu_code AND i.stock_num=@stock_num;

		INSERT INTO informeStock (fechaInforme,stock_num,manu_code,cantOrdenes,ultCompra,cantClientes,totalVentas)
		VALUES  (@fechaInforme,@stock_num,@manu_code,@cantOrdenes,@ultCompra,@cantClientes,@totalVentas);
	
		FETCH NEXT FROM products_cursor INTO @stock_num,@manu_code;
		END
		CLOSE products_cursor;
		DEALLOCATE products_cursor;
	END

END

--Crear un procedimiento �generarInformeVentas� que reciba como par�metros
--fechaInforme y codEstado y que en base a los datos de la tabla customer de todos
--los clientes que vivan en el estado pasado por par�metro, inserte un registro de la
--tabla informeVentas con la siguiente informaci�n:
CREATE TABLE informeVentas(
fechaInforme date,
codEstado char(1),
customer_num smallint,
cantOrdenes int,
primerVenta date,
ultVenta date,
cantProductos int,
totalVentas decimal(8,2));


fechaInforme,codEstado,customer_num,cantOrdenes,primerVenta,ultVenta,cantProductos,totalVentas


--fechaInforme: fecha pasada por par�metro
--codEstado: c�digo de estado recibido por par�metro
--customer_num: n�mero de cliente
--cantOrdenes: cantidad de �rdenes del cliente.
--primerVenta: fecha de la primer orden al cliente.
--UltVenta: fecha de �ltima orden al cliente.
--cantProductos: cantidad de tipos de productos �nicos que haya
--comprado el cliente.
--totalVentas: Sumatoria de las ventas de ese cliente (p x q)
--Validar que no exista en la tabla informeVentas un informe con la misma
--fechaInforme y estado recibido por par�metro.
--fechaInforme,codEstado,customer_num,cantOrdenes,primerVenta,ultVenta,cantProductos,totalVentas
CREATE PROCEDURE generarInformeVentas 
@fechaInforme DATE, @codEstado char(1)
AS
BEGIN
IF((SELECT COUNT(*) FROM informeVentas i WHERE i.fechaInforme=@fechaInforme AND i.codEstado=@codEstado)=0)
BEGIN
		DECLARE @customer smallint,@cantOrdenes int,@primerVenta date,
		@ultVenta date,@cantProductos int,@totalVentas decimal(8,2);
		DECLARE customer_cursor CURSOR FOR
		SELECT customer_num FROM customers;
		OPEN customer_cursor;
		FETCH NEXT FROM customer_cursor INTO @customer;
		WHILE (@@FETCH_STATUS=0)
		BEGIN

		SELECT @cantOrdenes=COUNT(DISTINCT o.order_num),@primerVenta=MIN(o.order_date),@ultVenta=MAX(o.order_date),
		@totalVentas=SUM(i.quantity*i.unit_price)
		FROM orders o JOIN items i
		ON o.order_num =i.order_num
		WHERE o.customer_num=@customer;

		SELECT  @cantProductos=COUNT(*) FROM(
		SELECT DISTINCT i.manu_code,i.stock_num FROM orders o join items i
		ON o.order_num=i.order_num
		AND o.customer_num= @customer) productosCliente;
		
		INSERT INTO informeVentas 
		VALUES (@fechaInforme,@codEstado,@customer,@cantOrdenes,@primerVenta,@ultVenta,@cantProductos,@totalVentas)
	
		FETCH NEXT FROM customer_cursor INTO @customer;
		END
		CLOSE customer_cursor;
		DEALLOCATE customer_cursor;
		
END
END
