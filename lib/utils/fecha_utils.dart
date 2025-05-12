import 'package:flutter/material.dart';

// funcion para obtener nombre del mes y mostrarlo en la card
String obtenerNombreMes(int numeroMes) {
  const meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];
  return meses[numeroMes - 1];
}
