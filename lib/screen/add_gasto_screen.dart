import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gastosnoteapp/database/db_helper.dart';
import 'package:gastosnoteapp/model/gastos_models.dart';
import 'package:gastosnoteapp/utils/categoria_utils.dart';
import 'package:gastosnoteapp/utils/toast_utils.dart';

// pantalla para agregar nuevo gasto
class AddGastoScreen extends StatefulWidget {
  const AddGastoScreen({super.key});

  @override
  State<AddGastoScreen> createState() => _AddGastoScreenState();
}

class _AddGastoScreenState extends State<AddGastoScreen> {
  final _formKey = GlobalKey<FormState>(); // llave para validar y guardar el formulario

  // variables para almacenar los valores del nuevo gasto
  String _descripcion = '';
  double _monto = 0.0;
  String _categoria = 'Alimentación'; // valor por defecto
  DateTime _fecha = DateTime.now(); // fecha por defecto (hoy)

  // Controladores para limpiar los campos luego de guardar
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();

  // Función para guardar el gasto en la bd
  Future<void> _guardarGasto() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // guardar los valores del formulario

      // Crear objeto Gasto usando los valores ingresados
      Gasto nuevoGasto = Gasto(
        descripcion: _descripcion,
        monto: _monto,
        categoria: _categoria,
        fecha: _fecha.toIso8601String().substring(0, 10), // yyyy-MM-dd
      );

      await DatabaseHelper.instance.insertarGasto(nuevoGasto); // esperamos que se agregue el gasto a la db

      // Mostrar mensaje de exito
      mostrarToast(
          context, 'Gasto agregado correctamente',
          Colors.green, Icons.check_circle
      );

      // Limpiar los campos del formulario
      _descripcionController.clear();
      _montoController.clear();
      setState(() {
        _categoria = 'Alimentación';
        _fecha = DateTime.now();
      });
    }
  }

  // Selector de fecha
  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2025),// que este desde este año
      lastDate: DateTime.now(), // impide seleccionar fechas futuras
    );
    if (picked != null && picked != _fecha) {
      setState(() {
        _fecha = picked;
      });
    }
  }

  // liberara los controladores cuando ya no se usen
  @override
  void dispose() {
    _descripcionController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  // Construiremos la interfaz
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Gasto')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey, // asignacion de clave al formulario
          child: ListView(
            children: [
              //campo de descripcion
              TextFormField(
                controller: _descripcionController,
                maxLength: 30, // maximo 40 caracteres
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Campo requerido' : null,
                onSaved: (value) => _descripcion = value!,
              ),
              const SizedBox(height: 10),
              // campo de monto
              TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campo requerido';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingrese un número válido';
                  }
                  if (_monto >=10000){
                    return 'Maximo permitido: 9999.99';
                  }
                  return null;
                },
                inputFormatters: [
                  // Esto limita a 4 dígitos enteros y 2 decimales
                  FilteringTextInputFormatter.allow(RegExp(r'^\d{0,4}(\.\d{0,2})?$')),
                ],
                onSaved: (value) => _monto = double.parse(value!),
              ),
              const SizedBox(height: 10),
              // dropdown de categoria
              DropdownButtonFormField(
                value: _categoria,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: categoriaGasto // mostrara la lista de las categorias
                    .map((cat) =>
                    DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) => setState(() => _categoria = value!),
              ),
              const SizedBox(height: 10),
              // selector de fecha
              ListTile(
                title: Text('Fecha: ${_fecha.toLocal().toString().substring(0, 10)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _seleccionarFecha,
              ),
              const SizedBox(height: 20),
              //boton de guardar el gasto
              ElevatedButton(
                onPressed: () async {
                  // verifica que los campos sean validos antes de guardar
                  if (_formKey.currentState!.validate()){
                    await _guardarGasto();
                    Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Guardar'
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
