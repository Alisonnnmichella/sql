--Crear una vista que devuelva:
--a) Codigo y Nombre (manu_code,manu_name) de los fabricantes, posean o no productos, 
--cantidad de productos que fabrican (cant_producto) y la fecha de la ultima OC
-- que contenga un producto suyo (ult_fecha_orden)
--De los fabricantes que fabriquen productos solo se podran mostrar 
--los que fabriquen mas de 2 productos.
--No se permite utilizar funciones definidas por usuario, ni tablas temporales, ni UNION


SELECT m.manu_code,m.manu_name, COUNT( DISTINCT p.stock_num) cant_producto,coalesce(cast(MAX(o.order_date) AS varchar(20)),'No posee ordenes')
FROM manufact m LEFT JOIN products p
ON p.manu_code=m.manu_code
LEFT JOIN items i
ON i.manu_code=p.manu_code
LEFT JOIN orders o
ON o.order_num= i.order_num
GROUP BY m.manu_code,m.manu_name,p.manu_code
HAVING  (COUNT( DISTINCT p.stock_num)>2 AND p.manu_code IS NOT NULL) OR p.manu_code IS NULL

--Desarrollar una consulta ABC de fabricante que
--Liste el codigo y nombre del fabricante, la cantidad de ordenes de compra que 
--contenga sus productos y el monto total de los productos vendidos.
--Mostrar solo los fabricantes cuyo codigo comience con A o con N 
--Y posea 3 letras y los productos cuya descripcion posean el string "tenis" o el
-- string "ball" en cualquier parte del nombre y cuyo monto total vendido sea
-- mayor que el total de ventas promedio de todos los fabricantes 
--(Cantidad*precio unitario/ Cantidad de fabricantes que vendieron sus productos)
--Mostrar los registros ordenados por monto total vendido de mayor a menor


-- total de ventas promedio de todos los fabricantes ????
--1. Saca el total de TODAS las ventas realizadas
--2. Lo divide por la cantidad de fabricantes 
SELECT m.manu_code,m.manu_name,count(distinct o.order_num),sum(i.unit_price*i.quantity) 'monto total'
FROM manufact m  
JOIN items i
ON i.manu_code=m.manu_code
JOIN orders o
ON i.order_num=o.order_num
JOIN product_types prt
ON prt.stock_num=i.stock_num
WHERE m.manu_code LIKE '[AN]__' 
AND (prt.description LIKE '%tennis%' OR prt.description  LIKE '%ball%')
GROUP BY m.manu_code,m.manu_name
HAVING sum(i.unit_price*i.quantity) >= (SELECT SUM(i.quantity*i.unit_price)/COUNT(DISTINCT i.manu_code)  FROM items i )
ORDER BY sum(i.unit_price*i.quantity) DESC


--3) Crear una vista que devuelva
--Para cada cliente mostrar (customer_num,lname,company) cantidad de ordenes de compra, fecha de su ultima OC, monto
--total comprado y el total general comprado por todos
--los clientes.
--De los clientes que posean órdenes solo se podrán mostrar
--los clientes que tengan alguna orden que posea productos que son fabricados por mas de dos fabricantes y que tengan al
--menos 3 órdenes de compra

--Ordenar el reporte de tal forma que primero aparezcan los clientes que tengan ordenes por cantidad de órdenes
--descendente y luego los clientes que no tengan ordenes.
--No se permite utilizar funciones, ni tablas temporales

SELECT c.customer_num,c.lname,c.company, COUNT(DISTINCT o.order_num) cantidadDeCompras,MAX(o.order_date) 'ultima OC', sum(i.quantity*i.unit_price) 'total comprado', (select sum(i2.unit_price*i2.quantity) from items i2) TOTAL_COMPRADO_POR_CLIENTES
FROM customer c LEFT JOIN orders o
ON c.customer_num=o.customer_num
LEFT JOIN items i
ON i.order_num=o.order_num
GROUP BY c.customer_num,c.lname,c.company
HAVING count(o.order_num)=0 OR (count(o.order_num)>=3 AND c.customer_num IN (SELECT o.customer_num FROM 
																			orders o join items i 
																			ON o.order_num=i.order_num
																			WHERE i.stock_num IN (SELECT stock_num FROM
																								  products 
																								  group by stock_num
																								  HAVING count(DISTINCT manu_code)>2 )
																			GROUP BY o.order_num,customer_num
																			HAVING COUNT(i.item_num)>0)) 
								
ORDER BY count(o.order_num) desc

--cantidad de fabricantes que producen el producto 
SELECT count(DISTINCT manu_code ) FROM
products 
group by stock_num

-- productos producidos por mas de dos fabricantes
SELECT stock_num FROM
products 
group by stock_num
HAVING count(DISTINCT manu_code)>2


--orden que posea productos que son fabricados por mas de dos fabricantes 
SELECT o.order_num FROM 
orders o join items i 
ON o.order_num=i.order_num
WHERE i.stock_num IN (SELECT stock_num FROM
					  products 
					  group by stock_num
					  HAVING count(DISTINCT manu_code)>2 )
GROUP BY o.order_num
HAVING COUNT(i.item_num)>0


--clientes que tengan alguna orden que posea productos que son fabricados por mas de dos fabricantes 
SELECT o.customer_num FROM 
orders o join items i 
ON o.order_num=i.order_num
WHERE i.stock_num IN (SELECT stock_num FROM
					  products 
					  group by stock_num
					  HAVING count(DISTINCT manu_code)>2 )
GROUP BY o.order_num,customer_num
HAVING COUNT(i.item_num)>0


--------------------------------------------
--Crear una consulta que devuelva los 5 primeros estados y el 
--tipo de producto (description) mas comprado en ese estado (state) segun la cantidad vendida del tipo de producto.
--Ordenarlo por la cantidad vendida en forma descendente.
--Nota: No se permite utilizar funciones, ni tablas temporales






