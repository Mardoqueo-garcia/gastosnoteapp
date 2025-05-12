import 'package:flutter/material.dart';
import 'package:gastosnoteapp/database/db_helper.dart'; // bd
import 'package:gastosnoteapp/model/gastos_models.dart'; // modelo
import 'package:gastosnoteapp/screen/add_gasto_screen.dart'; // pantalla
import 'package:gastosnoteapp/screen/edit_gasto_screen.dart';
import 'package:gastosnoteapp/utils/fecha_utils.dart'; //
import 'package:gastosnoteapp/utils/categoria_utils.dart';

// clase principal para la pantalla de inicio
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Maneja el estado de la pantalla (dinamica)
class _HomeScreenState extends State<HomeScreen> {
  DateTime _mesSeleccionado = DateTime.now(); // Mes seleccionado por defecto el actual
  DateTime _mesActual = DateTime.now(); // Variable para validacion del refresh
  List<Gasto> _gastos = []; // Lista donde se guardarán los gastos del mes actual
  double _totalGastos = 0.0; // Total de gastos del mes
  String _categoriaSeleccionada = 'Todas'; // por defecto

  // Se ejecutara la funcion al iniciar la pantalla
  @override
  void initState() {
    super.initState();
    _cargarGastosDelMes(); // Cargar datos cuando inicia la pantalla
  }

  // Función para obtener los gastos del mes desde la bd
  Future<void> _cargarGastosDelMes() async {
    final List<Gasto> gastos = await DatabaseHelper.instance.obtenerGastos(); // lista de objeto gasto desde la db

    // Calcula el gasto total sumando uno a uno
    double total = 0.0;
    for (var g in gastos) {
      total += g.monto;
    }
    // Actualiza el estado de la pantalla con los nuevos gastos
    setState(() {
      _gastos = gastos;
      _totalGastos = total;
    });
  }

  // Funcion para mostrar las opciones al presionar un gasto en la lista
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
                // Para lo de eliminar
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

  // Funcion para eliminar en la pagina modal
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

  // Funcion para el buscador
  void _buscarGastoMesyCategoria() async {
    final db = await DatabaseHelper.instance.database;
    final primerDia = DateTime(_mesSeleccionado.year, _mesSeleccionado.month, 1);
    final ultimoDia =  DateTime(_mesSeleccionado.year, _mesSeleccionado.month + 1, 0);
    String where = 'fecha BETWEEN ? AND ?';

    List<String> whereArgs = [
      primerDia.toIso8601String().substring(0,10),
      ultimoDia.toIso8601String().substring(0,10)];
    if (_categoriaSeleccionada != 'Todas') {
      where += ' AND categoria = ?';
      whereArgs.add(_categoriaSeleccionada);
    }
    // Hacemos la consulta a la db
    final maps = await db.query(
      'gastos',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'fecha DESC'
    );

    setState(() {
      _gastos = maps.map((e) => Gasto.fromMap(e)).toList();
      _totalGastos = _gastos.fold(0, (suma, g) => suma + g.monto);
    });
  }

  // Funcion para limpiar los filtros y restablecer pantalla
  void _restablecerFiltros() {
    setState(() {
      _mesSeleccionado = DateTime.now();
      _categoriaSeleccionada = 'Todas';
    });
    _cargarGastosDelMes(); // Cargaremos los datos
  }

  // Funcion para ocultar el boton de limpiar
  bool _esMesActual(DateTime fecha) {
    final ahora = DateTime.now();
    return fecha.month == ahora.month && fecha.year == ahora.year;
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
          // Filtros de busqueda (mes y categoria)
          Padding(padding: const
          EdgeInsets.symmetric(horizontal: 12,
          vertical: 8),
          child: Row(
            children: [
              // Selector de mes
              Expanded(child:
              DropdownButtonFormField<int>(
                decoration: const
                    InputDecoration(labelText: 'Mes'),
                value: _mesSeleccionado.month,
                items: List.generate(DateTime.now().month, (index) {
                  final mes = index + 1;
                  return DropdownMenuItem(
                    value: mes,
                    child:
                    Text(obtenerNombreMes(mes)),
                  );
                }),
                onChanged: (mes) {
                  if (mes != null) {
                    setState(() {
                      _mesSeleccionado = DateTime(DateTime.now().year, mes);
                    });

                    _buscarGastoMesyCategoria();
                  }
                },
              ),
            ),

              const SizedBox(width: 12),
              // Selector de categoria
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const
                      InputDecoration(labelText: 'Categoria'),
                  value: _categoriaSeleccionada,
                  items: ['Todas', ...categoriaGasto].map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState( () =>
                      _categoriaSeleccionada = value!);

                    _buscarGastoMesyCategoria();
                  },
                ),
              )
            ],
          )
        ),

          // Targeta de total de gastos del mes
          Card(
            margin: const EdgeInsets.all(12), // Espacio externo
            elevation: 3, // sombra
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Separa los textos a los extremos
                children: [
                  Text(
                    'Gastos del mes de ${obtenerNombreMes((_mesSeleccionado.month))}', // Muestra el nombre del mes
                    style: const
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${_totalGastos.toStringAsFixed((2))}', // Total de gastos con dos decimales
                    style: const
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Boton para limpiar filtros y mostrar solo si se ha buscado algo
          if (_categoriaSeleccionada != 'Todas' ||
            _mesSeleccionado.month != _mesActual.month ||
            _mesSeleccionado.year != _mesActual.year)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                    onPressed: _restablecerFiltros,
                  icon: const Icon(
                      Icons.refresh,
                      color: Colors.blue
                  ),
                  label: const Text(
                    'Restablecer filtros',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),

          // Lista de gastos del mes
          Expanded(
              // Si no hay gastos muestra este mensaje
              child: _gastos.isEmpty? const Center(child: Text('No hay gastos este mes')) :
                ListView.builder( // Si hay gastos construye la lista
                  itemCount: _gastos.length,
                  itemBuilder: (context, index) {
                    final gasto = _gastos[index];
                    return ListTile(
                      leading: const Icon(Icons.monetization_on), // icono de moneda al inicio
                      title: Text(
                        gasto.descripcion,
                        softWrap: true, // El texto se ajusta a varias lineas
                        overflow: TextOverflow.ellipsis, // si es mucha agrega tres puntos (...)
                        maxLines: 2, // solo dos lineas visibles
                      ),
                      subtitle: Text('${gasto.categoria}  - ${gasto.fecha}'),
                      trailing: Text('\$${gasto.monto.toStringAsFixed((2))}'),
                      onLongPress: () { // Para que detecte el toque largo
                        _mostrarOpciones(context, gasto);
                      },
                    );
                  },
                ),
          ),
        ],
      ),

      // Boton flotante para agregar un nuevo gasto
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final resultado = await Navigator.push(context,
                // Navega a la pantalla de nuevo gasto
                MaterialPageRoute(builder: (context) => const AddGastoScreen()),
            );
            // Si se agrego un gasto recarga la lista
            if (resultado == true) {
              _cargarGastosDelMes();
            }
          },
        // Icono de +
        child: const Icon(Icons.add),
          ),
    );
  }
}