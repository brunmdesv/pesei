import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000";

  // Método para obter o peso simulado da balança
  Future<double> fetchWeight() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/weight"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['weight'];
      } else {
        throw Exception("Erro ao obter o peso");
      }
    } catch (e) {
      print("Erro na requisição: $e");
      return 0.0;
    }
  }

  // Método para enviar os dados da nota e "imprimir"
  Future<void> printTicket(
    double weight,
    String value,
    String timestamp,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/print_ticket"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "weight": weight,
          "total_value": value,
          "timestamp": timestamp,
        }),
      );
      if (response.statusCode == 200) {
        print("Nota impressa com sucesso!");
      } else {
        throw Exception("Erro ao imprimir a nota");
      }
    } catch (e) {
      print("Erro ao imprimir a nota: $e");
    }
  }

  // Método para obter o preço atual por kg
  Future<double> getPricePerKg() async {
    final response = await http.get(Uri.parse("$baseUrl/admin/price"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['price_per_kg'];
    } else {
      throw Exception("Erro ao buscar preço por kg");
    }
  }

  // Método para atualizar o preço por kg
  Future<void> setPricePerKg(double price) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/price"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"price_per_kg": price}),
    );
    if (response.statusCode != 200) {
      throw Exception("Erro ao atualizar preço por kg");
    }
  }

  // Métodos para gerenciamento da impressora
  Future<List<String>> getAvailablePrinters() async {
    final response = await http.get(Uri.parse("$baseUrl/admin/printers"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['printers']);
    } else {
      throw Exception("Erro ao buscar impressoras disponíveis");
    }
  }

  Future<Map<String, dynamic>> getPrinterSettings() async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/printer_settings"),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Erro ao buscar configurações da impressora");
    }
  }

  Future<void> savePrinterSettings({
    required String printerName,
    required double marginTop,
    required double marginBottom,
    required double marginLeft,
    required double marginRight,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/printer_settings"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "printer_name": printerName,
        "margins": {
          "top": marginTop,
          "bottom": marginBottom,
          "left": marginLeft,
          "right": marginRight,
        },
      }),
    );
    if (response.statusCode != 200) {
      throw Exception("Erro ao salvar configurações da impressora");
    }
  }

  Future<void> testPrint() async {
    final response = await http.post(Uri.parse("$baseUrl/admin/test_print"));
    if (response.statusCode != 200) {
      throw Exception("Erro ao testar impressão");
    }
  }

  Future<bool> checkPrinterStatus() async {
    final response = await http.get(Uri.parse("$baseUrl/admin/printer_status"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['is_connected'];
    } else {
      throw Exception("Erro ao verificar status da impressora");
    }
  }
}
