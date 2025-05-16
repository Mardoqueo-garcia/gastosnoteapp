import 'package:sqflite/sqflite.dart';
import 'package:gastosnoteapp/model/gastos_models.dart';
import 'package:gastosnoteapp/database/db_helper.dart';


// Obtiene los gastos desde la base de datos.
Future<List<Gasto>> obtenerGastosDB() async {
  return await DatabaseHelper.instance.obtenerGastos();
}

// Funcion para el buscador
Future<List<Gasto>> buscarPorMesYCategoria({
  required DateTime mesSeleccionado,
  required String categoriaSeleccionada,
}) async {
  final db = await DatabaseHelper.instance.database;
  final primerDia = DateTime(mesSeleccionado.year, mesSeleccionado.month, 1);
  final ultimoDia = DateTime(mesSeleccionado.year, mesSeleccionado.month + 1, 0);

  String where = 'fecha BETWEEN ? AND ?';
  List<String> whereArgs = [
    primerDia.toIso8601String().substring(0, 10),
    ultimoDia.toIso8601String().substring(0, 10),
  ];

  if (categoriaSeleccionada != 'Todas') {
    where += ' AND categoria = ?';
    whereArgs.add(categoriaSeleccionada);
  }

  /// hacemos la consulta en la db
  final maps = await db.query(
    'gastos',
    where: where,
    whereArgs: whereArgs,
    orderBy: 'fecha DESC',
  );
  return maps.map((e) => Gasto.fromMap(e)).toList();
}

// Suma el monto total de los gastos.
double totalDeGastos(List<Gasto> gastos) {
  double total = 0.0;
  for (var g in gastos) {
    total += g.monto;
  }
  return total;
}