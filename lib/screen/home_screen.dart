import 'package:flutter/material.dart';
import 'package:gastosnoteapp/database/db_helper.dart'; // bd
import 'package:gastosnoteapp/model/gastos_models.dart'; // modelo
import 'package:gastosnoteapp/screen/add_gasto_screen.dart'; // pantalla
import 'package:gastosnoteapp/screen/edit_gasto_screen.dart';

// clase principal para la pantalla de inicio
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// maneja el estado de la pantalla (dinamica)
class _HomeScreenState extends State<HomeScreen> {
  List<Gasto> _gastos = []; // Lista donde se guardarán los gastos del mes actual
  double _totalGastos = 0.0; // Total de gastos del mes

  // se ejecutara la funcion al iniciar la pantalla
  @override
  void initState() {
    super.initState();
    _cargarGastosDelMes(); // Cargar datos cuando inicia la pantalla
  }

  // Función para obtener los gastos del mes desde la bd
  Future<void> _cargarGastosDelMes() async {
    final List<Gasto> gastos = await DatabaseHelper.instance.buscarGastos(); // lista de objeto gasto desde la db

    // calcula el gasto total sumando uno a uno
    double total = 0.0;
    for (var g in gastos) {
      total += g.monto;
    }

    // actualiza el estado de la pantalla con los nuevos gastos
    setState(() {
      _gastos = gastos;
      _totalGastos = total;
    });
  }

  // Funcion para mostrar las opciones
  @override
  void _mostrarOpciones(BuildContext context, Gasto gasto){
    showModalBottomSheet(
        context: context,
        builder: (BuildContext ctx){
          return SafeArea(
            child: Wrap(
              children: [
                // Para lo de modificar
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Modificar'),
                  onTap: () async {
                    Navigator.pop(ctx); // cierra el modal
                    // navega a la pantalla y espera el resultado
                    final resultado = await Navigator.push(context,
                      MaterialPageRoute(
                        builder: (context) => EditGastoScreen(gasto: gasto)),
                    );
                    // si se modifico el resultado se recargara la lista
                    if (resultado == true){
                      _cargarGastosDelMes();
                    }
                  },
                ),
                // para lo de eliminar
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Eliminar'),
                  onTap: () {
                    Navigator.pop(ctx); // cierra el modal
                    _confirmarEliminacion(context, gasto);
                  },
                )
              ],
            ),
          );
        });
  }

  // funcion para eliminar en la pagina modal
  @override
  void _confirmarEliminacion(BuildContext context, Gasto gasto) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar gasto?'),
        content: const Text('Estas seguro que deseas eliminar este gasto?'),
        actions: [
          TextButton(
              onPressed: () =>  Navigator.of(ctx).pop(),
          child: const Text('Cancelar'), // cancelamos lo de eliminar
          ),
          TextButton(
              onPressed: () async {
                await DatabaseHelper.instance.eliminarGasto(gasto.id!);
                Navigator.of(ctx).pop(); // cierra el dialog
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gasto Eliminado')),
                );
                _cargarGastosDelMes(); // refresca la lista
              },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red),),
          ),
        ],
      )
    );
  }


  // Construimos la pantalla visual principal
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GastosNotes'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // targeta que muestra el total de gasto del mes
          Card(
            margin: const EdgeInsets.all(12), // espacio externo
            elevation: 3, // sombra
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // separa los textos a los extremos
                children: [
                  const Text('Total del mes:', style: TextStyle(fontSize: 18)), // muestra el total con dos decimales
                  Text('\$${_totalGastos.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // Lista que mostrara los gastos del mes
          Expanded(
            child: _gastos.isEmpty // si no hay gasto muestra un mensaje
                ? const Center(child: Text('No hay gastos este mes.'))
                : ListView.builder( // si hay gastos construye la lista
              itemCount: _gastos.length,
              itemBuilder: (context, index) {
                final gasto = _gastos[index];
                return ListTile(
                  leading: const Icon(Icons.monetization_on), // icono al inicio
                  title: Text(gasto.descripcion), // descripcion del gasto
                  subtitle: Text('${gasto.categoria} - ${gasto.fecha}'), // categoria y fecha
                  trailing: Text('\$${gasto.monto.toStringAsFixed(2)}'), // monto a la derecha
                  onLongPress: () {
                    _mostrarOpciones(context, gasto); // para que detecte el toque largo
                  },
                );
              },
            ),
          ),
        ],
      ),

      // boton flotante para agregar un nuevo gasto
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // navega a la pantalla de nuevo gasto
          final resultado = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddGastoScreen()),
          );
          // si se agrego un gasto recarga la lista
          if(resultado == true){
            _cargarGastosDelMes();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}