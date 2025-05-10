import 'package:flutter/material.dart';
import 'package:gastosnoteapp/database/db_helper.dart'; // bd
import 'package:gastosnoteapp/model/gastos_models.dart'; // modelo
import 'package:gastosnoteapp/screen/add_gasto_screen.dart'; // pantallas

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