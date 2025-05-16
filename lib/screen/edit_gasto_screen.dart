import 'package:flutter/material.dart';
import 'package:gastosnoteapp/database/db_helper.dart';
import 'package:gastosnoteapp/model/gastos_models.dart';
import 'package:gastosnoteapp/utils/categoria_utils.dart';
import 'package:gastosnoteapp/utils/toast_utils.dart';

class EditGastoScreen extends StatefulWidget {
  final Gasto gasto; // recibe el gasto a editar
  // constructor que requira que se le pase un objeto como parametro
  const EditGastoScreen({super.key, required this.gasto});

  @override
  State<EditGastoScreen> createState() => _EditGastoScreenState();
}
// para gestionar la pantalla
class _EditGastoScreenState extends State<EditGastoScreen> {
  final _formKey = GlobalKey<FormState>(); // llave para validar el formulario

  // controladores para el campo del texto
  // late indica que las variables seran inicializadas mas adelante pero son obligatorias
  late TextEditingController _descripcionController;
  late TextEditingController _montoController;
  // almacena la categoria y fecha
  late String _categoria;
  late DateTime _fecha;

  @override
  // Inicializacion de valores
  void initState() {
    super.initState(); // se ejecuta automaticamente al crear la pantalla
    _descripcionController = TextEditingController(text: widget.gasto.descripcion);
    _montoController = TextEditingController(text: widget.gasto.monto.toString()); // convertimos el valor a string
    _categoria = widget.gasto.categoria;
    _fecha = DateTime.parse(widget.gasto.fecha); // se convierte de string a Datetime
  }

  @override
  // se liberan los controladores para evitar fugas de memoria, es decir cuando la ventana
  // se destruye se libera la memoria de las variables que ocupaban ese espacio
  void dispose() {
    _descripcionController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  // Para seleccionar nueva fecha
  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker( // se abre el calendario
      context: context,
      initialDate: _fecha, // fecha q ya esta seleccionada
      firstDate: DateTime(2025),
      lastDate: DateTime.now(), // no permite elegir fecha futura
    );
    // si se elige una fecha se actualiza el valor fecha
    if (picked != null) {
      setState(() {
        _fecha = picked;
      });
    }
  }

  // Guardaremos los datos modificados
  Future<void> _modificarGasto() async {
    if (_formKey.currentState!.validate()) { // validacion de los campos del formulario
      // crea un nuevo gasto con los datos modificados con el mismo id
      Gasto gastoModificado = Gasto(
        id: widget.gasto.id,
        descripcion: _descripcionController.text,
        monto: double.parse(_montoController.text),
        categoria: _categoria,
        fecha: _fecha.toIso8601String().substring(0, 10), // se guarda en formato YYYY-MM-DD
      );

      // guarda los cambios en la base de datos
      await DatabaseHelper.instance.actualizarGasto(gastoModificado);

      // Mostrar alerta de éxito
      if (mounted) { // verfica que el widget aun esta activo
        mostrarToast(
            context, 'Gasto modificado correctamente',
            Colors.orange, Icons.edit);
        // retorna true para indicar que hubo cambios, y navega a la pantalla principal
        Navigator.pop(context, true);
      }
    }
  }


  @override
  // Crearemos la interfaz del usuario
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // fondo con imagen
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background_image.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
              title: const Text('Editar Gasto'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form( // formulario
              key: _formKey,
              child: Column(
                children: [
                  TextFormField( // descripcion
                    controller: _descripcionController,
                    maxLength: 40,
                    maxLines: 2, // maximo dos lineas
                    decoration: InputDecoration(
                        labelText: 'Descripción',
                      prefixIcon: const Icon(Icons.description),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField( // monto
                    controller: _montoController,
                    decoration: InputDecoration(
                        labelText: 'Monto',
                      prefixIcon: Icon(Icons.attach_money),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Campo requerido';
                      if (double.tryParse(value) == null) return 'Ingrese un número válido';
                      if (double.parse(value) >= 10000) return 'Máximo permitido: 9999.99';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>( // menu de categorias
                    value: _categoria,
                    decoration: InputDecoration(
                        labelText: 'Categoría',
                      prefixIcon: Icon(Icons.category),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    items: categoriaGasto // mostrara las categorias
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                    onChanged: (value) => setState(() => _categoria = value!),
                  ),
                  const SizedBox(height: 16),
                  ListTile( // DatePicker de fecha
                    title: Text('Fecha: ${_fecha.toLocal().toString().substring(0, 10)}'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadiusDirectional.circular(12)),
                    tileColor: Colors.white,
                    trailing: const Icon(Icons.calendar_today, color: Colors.green,),
                    onTap: _seleccionarFecha,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon( // boton
                    onPressed: _modificarGasto,
                    icon: const Icon(Icons.save),
                    label: const Text('Modificar datos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}

