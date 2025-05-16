import 'package:flutter/material.dart';

// lista de las categorias
const List<String> categoriaGasto = [
  'Alimentación',
  'Transporte',
  'Salud',
  'Entretenimiento',
  'Otros',
];

// obtener color dependiendo de la categoria elegida
Color obtenerColorCategoria(String categoria) {
  switch (categoria.toLowerCase()) {
    case 'alimentación':
      return Colors.orangeAccent;
    case 'salud':
      return Colors.blueAccent;
    case 'entretenimiento':
      return Colors.purpleAccent;
    case 'transporte':
      return Colors.black;
    case 'otros':
      return Colors.grey;
    default:
      return Colors.green;
  }
}

// obtener codigo segun la categoria elegida
String obtenerCodCategoria(String categoria) {
  switch (categoria.toLowerCase()) {
    case 'alimentación':
      return 'AL';
    case 'salud':
      return 'SA';
    case 'entretenimiento':
      return 'EN';
    case 'transporte':
      return 'TR';
    case 'otros':
      return 'OT';
    default:
      return 'XX';
  }
}