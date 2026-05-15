# Pedidos

Los pedidos se realizarán semanalmente en un día específico a partir del ejercicio de planeación de la demanda.
Que es a partir del stock que tengo de cada item, el tiempo de entrega estipulado por cada proveedor, el promedio de venta diaria, el stock de seguridad que se requiere por cada item, picos de demanda establecidos semanalmente, el sistema deberá estar en las condiciones de tomar el pedido necesario de cada item.

Formula propuesta:

- Si (inventario > promedio de venta diario × tiempo de entrega del proveedor): no haga pedido de ese item
- Sino: el pedido de ese item será = promedio de venta diario × tiempo de entrega del proveedor + stock de seguridad + pico de demanda
