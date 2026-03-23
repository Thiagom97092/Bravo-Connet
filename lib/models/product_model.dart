class ProductModel {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String imagen;
  final String uid;
  final String nombreUsuario;

  ProductModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.imagen,
    required this.uid,
    required this.nombreUsuario,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'imagen': imagen,
      'uid': uid,
      'nombreUsuario': nombreUsuario,
      'fecha': DateTime.now(),
    };
  }
}
