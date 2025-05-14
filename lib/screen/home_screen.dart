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
  void _mostrarOpciones(BuildContext context, Gasto gasto){
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        backgroundColor: Colors.white,
        builder: (BuildContext ctx){
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.green),
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
                const Divider(),
                ListTile(
                  leading: const Icon(
                      Icons.delete,
                      color: Colors.red),
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
  void _confirmarEliminacion(BuildContext context, Gasto gasto) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        //borderradius del modal principal
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Eliminar gasto?', 
          style: TextStyle(fontWeight: FontWeight.bold),),
        content: const Text('Seguro que deseas eliminar este gasto?'),
        actions: [
          TextButton(
              onPressed: () =>  Navigator.of(ctx).pop(),
          child: const Text(
              'Cancelar',
            style: TextStyle(
              color: Colors.red,
            ),
          ), // cancelamos lo de eliminar
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.delete, color: Colors.red,),
            label: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () async {
              await DatabaseHelper.instance.eliminarGasto(gasto.id!);
              Navigator.of(ctx).pop(); // cierra el dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gasto Eliminado')),
              );
              _cargarGastosDelMes(); // refresca la lista
            },
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

  // Funcion para cambiar de color segun la categoria
  Color obtenerColorCategoria (String categoria) {
    switch (categoria.toLowerCase()) {
      case 'alimentación': return Colors.orangeAccent;
      case 'salud': return Colors.blueAccent;
      case 'entretenimiento': return Colors.purpleAccent;
      case 'transporte': return Colors.black;
      case 'otros': return Colors.grey;
      default: return Colors.green;
    }
  }
  // Funcion para obtener codigo segun categoria
  String obtenerCodCategoria(String categoria){
    switch(categoria.toLowerCase()){
      case 'alimentación': return 'AL';
      case 'salud': return 'SA';
      case 'entretenimiento': return 'EN';
      case 'transporte': return 'TR';
      case 'otros': return 'OT';
      default: return 'XX';
    }
  }
  // Funcion de estilo del appBar (Titulo)
  PreferredSizeWidget appBarEstilo(){
    return PreferredSize(
      preferredSize: const Size.fromHeight(65), // altura del appbar
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFB2DFDB),
              Color(0xFF80CBC4),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.red,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 10),
                Text.rich( // para combinar dos textos
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'GASTOS',
                        style: TextStyle(
                          color: Colors.blueAccent,
                         fontWeight: FontWeight.bold,
                          fontSize: 22,
                          letterSpacing: 1.2,
                        ),
                      ),
                      TextSpan(
                        text: 'NOTE',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 22
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }

  // CONTRUCCION DE LA PANTALLA VISUAL
  // Pantalla para el buscador
  Widget _buildFiltroWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          // Dropdown de mes
          Expanded(
            child: DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Mes',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                prefixIcon: const Icon(Icons.calendar_today),
              ),
              dropdownColor: Colors.lightBlueAccent,
              icon: Icon(Icons.arrow_drop_down, color: Colors.green),
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              value: _mesSeleccionado.month,
              items: List.generate(DateTime.now().month, (index) {
                final mes = index + 1;
                return DropdownMenuItem(
                  value: mes,
                  child: Text(obtenerNombreMes(mes)),
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
          // Dropdown de categoría
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
              dropdownColor: Colors.lightBlueAccent,
              value: _categoriaSeleccionada,
              items: ['Todas', ...categoriaGasto].map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (value) {
                setState(() => _categoriaSeleccionada = value!);
                _buscarGastoMesyCategoria();
              },
            ),
          ),
        ],
      ),
    );
  }


  //Pantalla de resumen de gastos y appbar
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarEstilo(),

      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background_image.png'),
            fit: BoxFit.cover, // para que se ajuste la imagen al tamaño de pantalla
          ),
        ),
      child: Column(
        children: [
          const SizedBox(height: 14), // Espacio entre buscador y targeta
          _buildFiltroWidget(), // llamado la funcion del widget creado de los filtros

          // Targeta de total de gastos del mes
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10
            ),
            elevation: 4, // sombra
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  //Icono decorativo
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                      Icons.bar_chart,
                      color: Colors.white,
                    size: 28),
                  ),
                  const SizedBox(width: 16),

                  // Texto del total
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gastos total de ${obtenerNombreMes(_mesSeleccionado.month)}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                          color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\$${_totalGastos.toStringAsFixed((2))}',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                      ],
                    )
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
                      color: Colors.red
                  ),
                  label: const Text(
                    'Restablecer filtros',
                    style: TextStyle(
                      color: Colors.red,
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
             child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8), // espacio a los lados
              // Si no hay gastos muestra este mensaje
              child: _gastos.isEmpty? const Center(
                  child: Text(
                      'No hay gastos este mes',
                  style: TextStyle(
                    fontSize: 16, color: Colors.grey),
                  )) :
                ListView.builder( // Si hay gastos construye la lista
                  itemCount: _gastos.length,
                  itemBuilder: (context, index) {
                    final gasto = _gastos[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)
                      ),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: CircleAvatar(
                          backgroundColor: obtenerColorCategoria(gasto.categoria),
                          child: Text(
                            obtenerCodCategoria(gasto.categoria),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        title: Text(
                          gasto.descripcion,
                          softWrap: true, // El texto se ajusta a varias lineas
                          overflow: TextOverflow.ellipsis, // si es mucha agrega tres puntos (...)
                          maxLines: 2, // solo dos lineas visibles
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                            '${gasto.categoria} •   ${gasto.fecha}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        trailing: Text(
                            '\$${gasto.monto.toStringAsFixed((2))}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green
                          ),
                        ),
                        onLongPress: () { // Para que detecte el toque largo
                          _mostrarOpciones(context, gasto);
                        },
                      ),
                    );
                  },
                ),
             ),
          ),
        ],
      ),
      ),
      // Boton flotante para agregar un nuevo gasto

      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle, // el boton sera redondo
          gradient: LinearGradient( // utilizaremos degradado
            colors: [
              Colors.lightGreen.shade400,
              Colors.greenAccent.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow( // sombre suave debajo del boton
              color: Colors.green,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
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
          child: const Icon(Icons.add, size: 30),
        ),
      )
    );
  }
}