--1 Dada la tabla Products de la base de datos stores7 se requiere crear una tabla
--Products_historia_precios y crear un trigger que registre los cambios de precios que se hayan
--producido en la tabla Products.
--Tabla Products_historia_precios
-- Stock_historia_Id Identity (PK)
--Stock_num
-- Manu_code
--fechaHora (grabar fecha y hora del evento)
--usuario (grabar usuario que realiza el cambio de precios)
--unit_price_old
--unit_price_new
--estado char default ‘A’ check (estado IN (‘A’,’I’))

create table products_historia_precios(
stock_historial_id  int IDENTITY(1,1) PRIMARY KEY,
stock_num smallint,
manu_code char(3),
fechaHora datetime2  DEFAULT GETDATE(),
usuario char(30) NOT NULL DEFAULT CURRENT_USER,
unit_price_old decimal(6, 2),
unit_price_new decimal(6, 2),
state char DEFAULT 'A' CHECK (state IN ('A','I')));

CREATE TRIGGER cambios_precios
ON products 
AFTER UPDATE
AS 
BEGIN
INSERT INTO products_historia_precios (stock_num,manu_code,unit_price_old,unit_price_new)
SELECT d.stock_num,d.manu_code,d.unit_price, i.unit_price 
FROM deleted d join inserted i
ON d.stock_num=i.stock_num AND d.manu_code= i.manu_code 
END

--TEST
insert into products (stock_num,manu_code,unit_price,unit_code)
values (113,'HRO',1515,20)

--TEST
update products set unit_price=15
where stock_num=113 and manu_code='HRO'

-------------------------------------------------------------------------------------------
--2 Crear un trigger sobre la tabla Products_historia_precios que ante un delete sobre la misma
--realice en su lugar un update del campo estado de ‘A’ a ‘I’ (inactivo).

CREATE TRIGGER delete_products_historia_precios
ON products_historia_precios
INSTEAD OF DELETE
AS
BEGIN
	update products_historia_precios set state='I'
	where manu_code= (select d.manu_code from deleted d) 
	and stock_num=(select d.stock_num from deleted d) 
END


--TEST
 DELETE FROM products_historia_precios 
 WHERE  stock_historial_id=1


--THERE WAS ANOTHER TRIGGER WITH THE SAME FUNCTIONALITY SO I HAVE TO DROP IT 
 drop trigger hacerInactivoEnHistorico

 ---------------------------------------------------------------------------------

-- 3 Validar que sólo se puedan hacer inserts en la tabla Products en un horario entre las 8:00 AM y
--8:00 PM. En caso contrario enviar un error por pantalla.

CREATE TRIGGER insertEnRangoHorarioValido
ON products
AFTER INSERT
AS 
BEGIN
	IF(DATEPART(HOUR,GETDATE()) NOT BETWEEN 8 AND 20)
	BEGIN
	THROW 50000,'Maestro que hace a esta hora laburando?',1
	END
END
--TEST
insert into products (stock_num,manu_code,unit_price,unit_code)
values (114,'HRO',1515,20)


--4 Crear un trigger que ante un borrado sobre la tabla ORDERS realice un borrado en cascada
--sobre la tabla ITEMS, validando que sólo se borre 1 orden de compra.
--Si detecta que están queriendo borrar más de una orden de compra, informará un error y
--abortará la operación.

CREATE TRIGGER borradoEnCascadaSoloUnaOrder
ON ORDERS
INSTEAD OF DELETE
AS
BEGIN
	IF((select count(*) from deleted d)>1)
	BEGIN
		THROW 50000,'Maestre que hace tratando de borrar mas de una fila?',1 
	END
delete from items 
where order_num = (select order_num from deleted)
delete from orders
where order_num = (select order_num from deleted)
END

--5 Crear un trigger de insert sobre la tabla ítems que al detectar que el código de fabricante
--(manu_code) del producto a comprar no existe en la tabla manufact, inserte una fila en dicha
--tabla con el manu_code ingresado, en el campo manu_name la descripción ‘Manu Orden 999’
--donde 999 corresponde al nro. de la orden de compra a la que pertenece el ítem y en el campo
--lead_time el valor 1.
CREATE TRIGGER sinoExisteElManu_CodeSeCrea
ON items
INSTEAD OF INSERT 
AS
BEGIN
	IF( (select count(*) from inserted i join manufact m on i.manu_code=m.manu_code) < 1)
	BEGIN
		insert into manufact (manu_code,manu_name,lead_time)
		 select i.manu_code,'Manu Orden'+i.order_num,1
		 from inserted i

	END
		 insert into items 
		 select * from inserted

END







--1 CURSOR Dada la tabla Products de la base de datos stores7 se requiere crear una tabla
--Products_historia_precios y crear un trigger que registre los cambios de precios que se hayan
--producido en la tabla Products.
--Tabla Products_historia_precios
 
 CREATE TRIGGER cambiosEnPrecios
 ON Products
 AFTER UPDATE
 AS
 BEGIN
	DECLARE @stock_num smallint, @unit_price_old decimal(8,2), @unit_price_new decimal(8,2),@manu_code char(3); 

	DECLARE productos_con_precios_cambiados CURSOR FOR
	SELECT i.stock_num,d.unit_price,i.unit_price, i.manu_code FROM 
	inserted i join deleted d
	ON  i.manu_code=d.manu_code 
	AND i.stock_num=d.stock_num
	AND i.unit_price != d.unit_price
	
	
	OPEN productos_con_precios_cambiados;
	FETCH NEXT FROM productos_con_precios_cambiados INTO  @stock_num, @unit_price_old , @unit_price_new, @manu_code ;
	WHILE @@FETCH_STATUS=0
		BEGIN
			INSERT INTO products_historia_precios (stock_num,manu_code,unit_price_old,unit_price_new)
			values (@stock_num,@manu_code,@unit_price_old,@unit_price_new)

			FETCH NEXT FROM productos_con_precios_cambiados INTO  @stock_num, @unit_price_old , @unit_price_new, @manu_code ;
		END;		 
	CLOSE productos_con_precios_cambiados;
	DEALLOCATE productos_con_precios_cambiados;
 END

 --2 CURSOR Crear un trigger sobre la tabla Products_historia_precios que ante un delete sobre la misma
--realice en su lugar un update del campo estado de ‘A’ a ‘I’ (inactivo).

CREATE TRIGGER inactivar_historial
ON products_historia_precios
INSTEAD OF DELETE
AS
BEGIN
	DECLARE @stock_historial int;
	DECLARE historial_inactivo CURSOR FOR
	SELECT d.stock_historial_id 
	FROM deleted d;

	OPEN historial_inactivo
	FETCH NEXT FROM inactivar_historial INTO @stock_historial
		WHILE @@FETCH_STATUS=0
		BEGIN 
			UPDATE products_historia_precios SET state='I' WHERE stock_historial_id=@stock_historial
 		
			FETCH NEXT FROM inactivar_historial INTO @stock_historial
		END
		CLOSE historial_inactivo
		DEALLOCATE historial_inactivo
END


--5 CURSOR Crear un trigger de insert sobre la tabla ítems que al detectar que el código de fabricante
--(manu_code) del producto a comprar no existe en la tabla manufact, inserte una fila en dicha
--tabla con el manu_code ingresado, en el campo manu_name la descripción ‘Manu Orden 999’
--donde 999 corresponde al nro. de la orden de compra a la que pertenece el ítem y en el campo
--lead_time el valor 1.

CREATE TRIGGER nuevo_manu_fact
ON items
INSTEAD OF INSERT
AS
BEGIN
	DECLARE @order_num smallint,@manu_code char(3);
	DECLARE items_cursor CURSOR FOR
	SELECT i.order_num,i.manu_code from inserted i
	WHERE i.manu_code NOT IN (select m.manu_code from manufact m);
	
	OPEN items_cursor
	FETCH NEXT FROM items_cursor INTO @order_num ,@manu_code 
	
	WHILE(@@FETCH_STATUS=0)
				BEGIN
					INSERT INTO manufact (manu_code,manu_name,lead_time) values (@manu_code,'Manu Orden'+@order_num,1)
					FETCH NEXT FROM items_cursor INTO @order_num ,@manu_code 
				END
	CLOSE items_cursor
	DEALLOCATE items_cursor
	insert into items (item_num,order_num,stock_num,manu_code,quantity,unit_price) 
	select i.item_num,i.order_num,i.stock_num,i.manu_code,i.quantity,i.unit_price from inserted i;

END;


--Crear tres triggers (Insert, Update y Delete) sobre la tabla Products para replicar todas las
--operaciones en la tabla Products _replica, la misma deberá tener la misma estructura de la tabla
--Products.

	CREATE TABLE Products_replica(
	stock_num SMALLINT FOREIGN KEY REFERENCES product_types(stock_num),
	manu_code char(3) FOREIGN KEY REFERENCES manufact(manu_code),
	unit_price decimal(6,2),
	unit_code smallint FOREIGN KEY REFERENCES units(unit_code)
	CONSTRAINT pk_products_replica
	PRIMARY KEY (stock_num,manu_code)
	);

	CREATE TRIGGER insertarEnDuplicado
	ON products
	after insert
	AS
	BEGIN
		insert into Products_replica (stock_num,manu_code,unit_price,unit_code) 
		select stock_num,manu_code,unit_price,unit_code from inserted
	END


	CREATE TRIGGER deleteEnDuplicado
	ON products
	after delete
	AS
	BEGIN
		delete from Products_replica pr join deleted d
		on pr.manu_code=d.manu_code and pr.stock_num=d.stock_num
	END

	CREATE TRIGGER updateEnDuplicado
	ON products
	after update
	AS
	BEGIN
	UPDATE pr set pr.unit_price= i.unit_price, pr.unit_code=i.unit_code
		from products_replica pr join inserted i
		on pr.manu_code=i.manu_code and pr.stock_num=i.stock_num
	END


--Crear la vista Productos_x_fabricante que tenga los siguientes atributos:
--Stock_num, description, manu_code, manu_name, unit_price
--Crear un trigger de Insert sobre la vista anterior que ante un insert, inserte una fila en la tabla
--Products, pero si el manu_code no existe en la tabla manufact, inserte además una fila en dicha
--tabla con el campo lead_time en 1.
CREATE VIEW Productos_x_fabricante
AS
select p.stock_num, description, p.manu_code, m.manu_name, unit_price
from products p join product_types tp
on p.stock_num=tp.stock_num
join manufact m
on p.manu_code= m.manu_code

CREATE TRIGGER actualizarProductos
ON productos_x_fabricante
AFTER insert
AS
BEGIN
	INSERT INTO manufact (manu_code,lead_time)
	SELECT i.manu_code,1 from inserted i
	where i.manu_code  not in (SELECT m.manu_code FROM manufact m)

	insert into products (stock_num,manu_code,unit_price)
	select i.stock_num,i.manu_code,i.unit_price
	from inserted i

END
