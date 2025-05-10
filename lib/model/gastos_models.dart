class Gasto {
  final int? id; // El ID es opcional porque cuando se crea un nuevo gasto aún no tiene ID.
  final String categoria;
  final double monto;
  final String descripcion;
  final String fecha;

  // Constructor
  Gasto({
    this.id,
    required this.categoria,
    required this.monto,
    required this.descripcion,
    required this.fecha,
  });

  // Convertir un Gasto de un Map a un objeto Gasto
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoria': categoria,
      'monto': monto,
      'descripcion': descripcion,
      'fecha': fecha,
    };
  }

  // Convertir un Gasto en un Map para ser insertado en la base de datos
  factory Gasto.fromMap(Map<String, dynamic> map) {
    return Gasto(
      id: map['id'],
      categoria: map['categoria'],
      monto: map['monto'],
      descripcion: map['descripcion'],
      fecha: map['fecha'],
    );
  }
}
