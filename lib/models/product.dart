/// Representa un producto, tanto en Odoo como en Sqflite.
/// Usaremos los nombres de Odoo como referencia.
class Product {
  final int id; // ID de Odoo (product.template)
  final String izena;
  final double prezioa;

  Product({
    required this.id,
    required this.izena,
    required this.prezioa,
  });

  // Factory para crear desde el JSON de Odoo RPC
  factory Product.fromOdoo(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      izena: json['name'] as String? ?? 'Sin Nombre',
      prezioa: (json['list_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Factory para crear desde el mapa de Sqflite
  factory Product.fromSqflite(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      izena: map['name'] as String,
      prezioa: map['list_price'] as double,
    );
  }

  // Método para convertir a mapa para Sqflite
  Map<String, dynamic> toSqfliteMap() {
    return {
      'id': id,
      'name': izena,
      'list_price': prezioa,
    };
  }
}
