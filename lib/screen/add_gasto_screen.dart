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
    return Stack(
      children: [
        // imagen de fondo
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
              title: const Text('Agregar Gasto'),
              backgroundColor: Colors.transparent,
              elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey, // asignacion de clave al formulario
              child: Column(
                children: [
                  //campo de descripcion
                  TextFormField(
                    controller: _descripcionController,
                    maxLength: 40, // maximo 40 caracteres
                    decoration: InputDecoration(
                        labelText: 'Descripción',
                      prefixIcon: Icon(Icons.description),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
                    onSaved: (value) => _descripcion = value!,
                  ),
                  const SizedBox(height: 16),
                  // campo de monto
                  TextFormField(
                    controller: _montoController,
                    decoration: InputDecoration(
                        labelText: 'Monto',
                      prefixIcon: const Icon(Icons.attach_money),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d{0,4}(\.\d{0,2})?$')),
                    ],
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
                    onSaved: (value) => _monto = double.parse(value!),
                  ),
                  const SizedBox(height: 16),
                  // dropdown de categoria
                  DropdownButtonFormField(
                    value: _categoria,
                    decoration: InputDecoration(
                        labelText: 'Categoría',
                      prefixIcon: const Icon(Icons.category),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: categoriaGasto // mostrara la lista de las categorias
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                    onChanged: (value) => setState(() => _categoria = value!),
                  ),
                  const SizedBox(height: 16),
                  // selector de fecha
                  ListTile(
                    title: Text('Fecha: ${_fecha.toLocal().toString().substring(0, 10)}'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    trailing: const Icon(Icons.calendar_today, color: Colors.green),
                    onTap: _seleccionarFecha,
                  ),
                  const SizedBox(height: 30),
                  //boton de guardar el gasto
                  ElevatedButton.icon(
                    onPressed: () async {
                      // verifica que los campos sean validos antes de guardar
                      if (_formKey.currentState!.validate()){
                        await _guardarGasto();
                        Navigator.pop(context, true);
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
