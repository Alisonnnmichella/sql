--Escribir una sentencia SELECT que devuelva el número de orden, fecha de orden y el nombre del
--día de la semana de la orden de todas las órdenes que no han sido pagadas.
--Si el cliente pertenece al estado de California el día de la semana debe devolverse en inglés, caso
--contrario en español. Cree una función para resolver este tema.
--Nota: SET @DIA = datepart(weekday,@fecha)
--Devuelve en la variable @DIA el nro. de día de la semana , comenzando con 1 Domingo hasta 7
--Sábado.

	SELECT o.order_num,o.order_date, dbo.dia_de_la_semana (o.order_date,'') as dia_de_la_semana
	FROM orders o
	WHERE o.paid_date IS NULL

	DROP FUNCTION dia_de_la_semana 
	CREATE FUNCTION dia_de_la_semana (@Fecha DATETIME,@Idioma VARCHAR(20))
	RETURNS VARCHAR(10) AS
	BEGIN
	DECLARE @DIA INT, @RETORNO VARCHAR(10);
		SET @DIA= datepart(WEEKDAY,@fecha);
	
		IF (@IDIOMA='Espaniol')
		BEGIN
		SET @RETORNO=
					CASE WHEN @DIA=1 THEN 'Domingo'
						 WHEN @DIA=2 THEN 'Lunes'
						 WHEN @DIA=3 THEN 'Martes'
						 WHEN @DIA=4 THEN 'Miercoles'
						 WHEN @DIA=5 THEN 'Jueves'
						 WHEN @DIA=6 THEN 'Viernes'
						 WHEN @DIA=7 THEN 'Sabado'
						 END
		END

		ELSE
		BEGIN
		SET @RETORNO=
					CASE WHEN @DIA=1 THEN 'Sunday'
						 WHEN @DIA=2 THEN 'Monday'
						 WHEN @DIA=3 THEN 'Tuesday'
						 WHEN @DIA=4 THEN 'Wednesday'
						 WHEN @DIA=5 THEN 'Thursday'
						 WHEN @DIA=6 THEN 'Friday'
						 WHEN @DIA=7 THEN 'Saturday'
						 END
		END
		return @RETORNO;
	END


-- 2 Escribir una sentencia SELECT para los clientes que han tenido órdenes en al menos 2 meses
--diferentes, los dos meses con las órdenes con el mayor ship_charge.
--Se debe devolver una fila por cada cliente que cumpla esa condición, el formato es:
--Cliente Año y mes mayor carga Segundo año mayor carga
--NNNN YYYY - Total: NNNN.NN YYYY - Total: NNNN.NN
--La primera columna es el id de cliente y las siguientes 2 se refieren a los campos ship_date y ship_charge.
--Se requiere crear una función que devuelva la información de 1er o 2do año mes con la orden con mayor Carga
--(ship_charge).
SELECT DISTINCT o.customer_num, dbo.date_max_ship_charge(1,o.customer_num) AS PRIMERO,dbo.date_max_ship_charge(2,o.customer_num) AS SEGUNDO
FROM orders o
WHERE o.customer_num IN (select  distinct o1.customer_num 
from orders o1 join orders o2
on o1.customer_num=o2.customer_num
and MONTH(o1.order_date)!=MONTH(o2.order_date))


DROP FUNCTION date_max_ship_charge

CREATE FUNCTION date_max_ship_charge (@LUGAR int, @CUSTOMER smallint)
RETURNS VARCHAR(100) AS
BEGIN
	DECLARE @MES VARCHAR(4), @SHIP_CHARGE VARCHAR(50),@RETURNS VARCHAR(100);
	IF (@LUGAR=2)
		BEGIN	
		SELECT TOP 1 @MES= primeros.months, @SHIP_CHARGE=primeros.ship_charge
		FROM (SELECT TOP 2 MONTH(o.order_date) months,MAX(o.ship_charge) ship_charge
		FROM orders o
		WHERE o.customer_num=@CUSTOMER
		GROUP BY MONTH(o.order_date)
		order by MAX(o.ship_charge) desc) as primeros 
		order by   primeros.ship_charge 
		END

	ELSE
		BEGIN
				SELECT  TOP 1 @MES=MONTH(ord.order_date), @SHIP_CHARGE=MAX(ord.ship_charge)
				FROM orders ord
				WHERE ord.customer_num=@CUSTOMER
				group by MONTH(ord.order_date)
				order by MAX(ord.ship_charge) desc
		END
	SET @RETURNS= @MES +' - Total: '+ @SHIP_CHARGE;
	RETURN @RETURNS
END



--clientes que compraron en dos meses diferentes
select  distinct o1.customer_num 
from orders o1 join orders o2
on o1.customer_num=o2.customer_num
and MONTH(o1.order_date)>MONTH(o2.order_date)

-------------------------------------------------------------------------------------------

--Escribir un Select que devuelva para cada producto de la tabla Products que exista en la tabla
--Catalog todos sus fabricantes separados entre sí por el caracter pipe (|). Utilizar una función para
--resolver parte de la consulta. Ejemplo de la salida
--Stock_num Fabricantes
--5 NRG | SMT | ANZ




SELECT distinct p.stock_num ,dbo.fabricantes(p.stock_num) as fabricantes
FROM products p join catalog c
on p.stock_num=c.stock_num AND p.manu_code=c.manu_code

DROP FUNCTION fabricantes
CREATE FUNCTION fabricantes (@STOCK_NUM smallint)
RETURNS VARCHAR(100) AS
BEGIN
	DECLARE @NOMBRE_FABRICANTE char(3),@RETURNS VARCHAR(100);
	DECLARE NOMBRES_FABRICANTES CURSOR FOR
	SELECT DISTINCT p.manu_code
	FROM products p
	WHERE p.stock_num=@STOCK_NUM
	SET @RETURNS=' '
	OPEN NOMBRES_FABRICANTES
	FETCH NEXT FROM NOMBRES_FABRICANTES INTO @NOMBRE_FABRICANTE;
	
	WHILE(@@FETCH_STATUS=0)
		BEGIN
			SET @RETURNS= @RETURNS+@NOMBRE_FABRICANTE+' | '
			FETCH NEXT FROM NOMBRES_FABRICANTES INTO @NOMBRE_FABRICANTE;
		END

	CLOSE NOMBRES_FABRICANTES
	DEALLOCATE NOMBRES_FABRICANTES
	SET @RETURNS = SUBSTRING(@RETURNS, 1, LEN(@RETURNS) - 2)
	RETURN @RETURNS

END


