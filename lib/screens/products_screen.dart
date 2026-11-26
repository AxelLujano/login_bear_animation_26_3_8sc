
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  // 6.1 URL base de la API de Spring Boot (puerto 8090)
  // - Web (Chrome): http://localhost:8090
  // - Celular físico Android (misma red Wi-Fi): http://192.168.1.80:8090
  static String get baseUrl =>
      kIsWeb ? 'http://localhost:8090' : 'http://192.168.1.80:8090';

  // 6.2 Función para pedir la lista de productos al endpoint GET /products
  Future<List<dynamic>> fetchProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar productos de la API');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos de Spring Boot')),
      // 6.3 FutureBuilder: espera la respuesta de la API y dibuja el resultado
      body: FutureBuilder<List<dynamic>>(
        future: fetchProducts(),
        builder: (context, snapshot) {
          // Mientras responde el servidor, mostrar indicador de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Si hubo un error de conexión
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];

          // 6.4 Mostrar los elementos de la base de datos en una lista sencilla
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                title: Text(product['name'].toString()),
                subtitle: Text('Stock: ${product['stock']}'),
                trailing: Text('\$${product['price']}'),
              );
            },
          );
        },
      ),
    );
  }
}
