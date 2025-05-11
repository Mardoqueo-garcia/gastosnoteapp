import 'package:flutter/material.dart';
import 'package:gastosnoteapp/database/db_helper.dart';
import 'package:gastosnoteapp/model/gastos_models.dart';

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

  // lista que se mostrara en el dropdown
  final List<String> _categorias = [
    'Alimentación',
    'Transporte',
    'Salud',
    'Entretenimiento',
    'Otros',
  ];

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gasto modificado correctamente')),
        );
        // retorna true para indicar que hubo cambios, y navega a la pantalla principal
        Navigator.pop(context, true);
      }
    }
  }


  @override
  // Crearemos la interfaz del usuario
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Gasto')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form( // formulario
          key: _formKey,
          child: ListView(
            children: [
              TextFormField( // descripcion
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField( // monto
                controller: _montoController,
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo requerido';
                  if (double.tryParse(value) == null) return 'Ingrese un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>( // menu de categorias
                value: _categoria,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categorias
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) => setState(() => _categoria = value!),
              ),
              const SizedBox(height: 10),
              ListTile( // DatePicker de fecha
                title: Text('Fecha: ${_fecha.toLocal().toString().substring(0, 10)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _seleccionarFecha,
              ),
              const SizedBox(height: 20),
              ElevatedButton( // boton
                onPressed: _modificarGasto,
                child: const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

