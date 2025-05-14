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
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? "Erro ao imprimir a nota");
      }
    } catch (e) {
      print("Erro ao imprimir a nota: $e");
      rethrow; // Propaga o erro para ser tratado pela UI
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

  // Método para obter o histórico de pesagens
  Future<List<Map<String, dynamic>>> getWeightHistory({
    String? startDate,
    String? endDate,
  }) async {
    try {
      String url = "$baseUrl/weight_records";
      if (startDate != null || endDate != null) {
        final params = <String, String>{};
        if (startDate != null) params['start_date'] = startDate;
        if (endDate != null) params['end_date'] = endDate;
        url += "?" + Uri(queryParameters: params).query;
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['records']);
      } else {
        throw Exception("Erro ao buscar histórico de pesagens");
      }
    } catch (e) {
      print("Erro ao buscar histórico: $e");
      return [];
    }
  }

  // Método para obter estatísticas das pesagens
  Future<Map<String, dynamic>> getWeightStats() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/weight_stats"));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Erro ao buscar estatísticas");
      }
    } catch (e) {
      print("Erro ao buscar estatísticas: $e");
      return {'today_count': 0, 'today_total': 0.0, 'avg_weight': 0.0};
    }
  }
}
