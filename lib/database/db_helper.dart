import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:gastosnoteapp/model/gastos_models.dart';

//Singleton para que solo halla una instancia de la clase en toda la app
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal(); // instancia unica de la clase
  static Database? _database; // variable para guardar la base de datos

  factory DatabaseHelper() => instance; // constructor factory que retorna la misma instancia creada antes

  DatabaseHelper._internal(); // constructor interno privado privado

  // Getter asíncrono para obtener la base de datos.
  // Si la base de datos ya está abierta, la devuelve.
  // Si no está abierta, la crea o abre con el nombre 'gastos.db' y la devuelve.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gastos.db'); // si no llama a _initDB para crearla o abrirla
    return _database!; // retorna la bd, el operador ! se usa para asegurar que no es null
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath(); // obtiene la ruta del sistema para guardar bd
    final path = join(dbPath, fileName); // crea la ruta final del archivo

    //abre o crea el archivo de db. si es nuevo se ejecuta el onCreate
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  //esta funcion se ejecuta al crear la bd por primera vez
  //crea una tabla con sus atributos
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE gastos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descripcion TEXT,
        monto REAL,
        categoria TEXT,
        fecha TEXT
      )
    ''');
  }

  // inserta un nuevo gasto en la tabla
  // recibe un map con las claves correspondientes a las columnas
  Future<int> insertarGasto(Gasto gasto) async {
    final db = await database; // se obtiene la conexion con la bd
    return await db.insert(
      'gastos', // el nombre de la tabla
      gasto.toMap(), //convertimos el objeto a map
      conflictAlgorithm: ConflictAlgorithm.replace, // Si ya existe un gasto con el mismo id, lo reemplaza
    );
  }

  // devuelve todos los gastos registrados
  Future<List<Gasto>> obtenerGastos() async {
    final db = await database;
    final ahora = DateTime.now();
    final primerDiaDelMes = DateTime(ahora.year, ahora.month, 1);

    final List<Map<String, dynamic>> maps = await db.query(
        'gastos',
      where: 'fecha >= ?',
      whereArgs: [primerDiaDelMes.toIso8601String().substring(0,10)],
      orderBy: 'fecha DESC', // ordenar por fecha mas reciente
      limit: 10, // mostrara solo los 10 mas recientes
    ); // realiza la consulta

    //convierte cada map a un objeto gasto
    return List.generate(maps.length, (i) {
      return Gasto.fromMap(maps[i]);
    });
  }

  // actualiza un gasto existente, utilizaremos su id
  Future<int> actualizarGasto(Gasto gasto) async {
    final db = await database;
    return await db.update(
      'gastos',
      gasto.toMap(),
      where: 'id = ?', // el simbolo ?: es un placeholder para evitar inyecciones sql
      whereArgs: [gasto.id], // el id que se va actualizar
    );
  }

  // eliminaremos el gasto a traves del id seleccionado
  Future<int> eliminarGasto(int id) async {
    final db = await database;
    return await db.delete(
      'gastos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //para buscar los gastos por categoria o fecha
  Future<List<Gasto>> buscarGastos({String? categoria, String? fecha}) async {
    final db = await database;

    // Verifica si ambos filtros están activos
    if ((categoria != null && categoria.isNotEmpty) &&
        (fecha != null && fecha.isNotEmpty)) {
      throw Exception('Solo se puede buscar por categoría o por fecha, no ambos a la vez.');
    }

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (categoria != null && categoria.isNotEmpty) {
      whereClause = 'categoria = ?';
      whereArgs.add(categoria);
    } else if (fecha != null && fecha.isNotEmpty) {
      whereClause = 'fecha = ?';
      whereArgs.add(fecha);
    } else {
      // Si no se pasó nada, filtrar por el mes actual
      DateTime ahora = DateTime.now();
      String mesActual = '${ahora.year.toString().padLeft(4, '0')}-${ahora.month.toString().padLeft(2, '0')}';
      whereClause = 'fecha LIKE ?'; // esto busca todas las fechas  del mes
      whereArgs.add('$mesActual%'); // "2025-05%"
    }

    // realizamos la consulta en la bd
    final List<Map<String, dynamic>> result = await db.query(
        'gastos',
    where: whereClause,
    whereArgs: whereArgs,
    );

    // convertimos cada map a un objeto gasto
    return result.map((map) => Gasto.fromMap(map)).toList();
  }
}
