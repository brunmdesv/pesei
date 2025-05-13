import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TicketPreview extends StatelessWidget {
  final double weight;
  final double pricePerKg;
  final double totalValue;
  final DateTime timestamp;

  TicketPreview({
    required this.weight,
    required this.pricePerKg,
    required this.totalValue,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final ApiService api = ApiService();
    final formattedTime =
        timestamp.toString().substring(0, 19); // YYYY-MM-DD HH:MM:SS

    return Scaffold(
      appBar: AppBar(title: Text("Pré-visualizar Nota")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Data/Hora: $formattedTime", style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text("Peso: ${weight.toStringAsFixed(3)} kg",
                style: TextStyle(fontSize: 20)),
            SizedBox(height: 8),
            Text("Preço/kg: R\$ ${pricePerKg.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 20)),
            SizedBox(height: 8),
            Divider(),
            Text(
              "Total: R\$ ${totalValue.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.print),
                label: Text("Confirmar e Imprimir"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                onPressed: () async {
                  await api.printTicket(
                    weight,
                    "R\$ ${totalValue.toStringAsFixed(2)}",
                    formattedTime,
                  );
                  // Após imprimir, voltamos para a tela inicial
                  Navigator.popUntil(context, ModalRoute.withName('/'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Nota impressa com sucesso!")),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
