import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final ApiService api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  bool _loading = true;

  // Configurações de impressora
  String? _selectedPrinter;
  bool _isPrinterConnected = false;
  List<String> _availablePrinters = [];
  double _marginTop = 0.0;
  double _marginBottom = 0.0;
  double _marginLeft = 0.0;
  double _marginRight = 0.0;

  // Controle do acordeão
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadCurrentPrice();
    _loadPrinterSettings();
  }

  Future<void> _loadCurrentPrice() async {
    try {
      double price = await api.getPricePerKg();
      _priceController.text = price.toStringAsFixed(2);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar preço: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _savePrice() async {
    if (!_formKey.currentState!.validate()) return;
    double newPrice = double.parse(_priceController.text.replaceAll(',', '.'));
    try {
      await api.setPricePerKg(newPrice);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Preço atualizado com sucesso!")));
      // Aguarda um instante para o usuário ler a mensagem e volta à tela anterior
      await Future.delayed(Duration(milliseconds: 500));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao salvar preço: $e")));
    }
  }

  Future<void> _loadPrinterSettings() async {
    try {
      final printers = await api.getAvailablePrinters();
      final settings = await api.getPrinterSettings();
      final isConnected = await api.checkPrinterStatus();

      setState(() {
        _availablePrinters = printers;
        // Garante que o valor selecionado existe na lista
        if (settings['printer_name'] != null &&
            printers.contains(settings['printer_name'])) {
          _selectedPrinter = settings['printer_name'];
        } else if (printers.isNotEmpty) {
          _selectedPrinter = printers.first;
        } else {
          _selectedPrinter = null;
        }
        _marginTop = settings['margins']['top'] ?? 0.0;
        _marginBottom = settings['margins']['bottom'] ?? 0.0;
        _marginLeft = settings['margins']['left'] ?? 0.0;
        _marginRight = settings['margins']['right'] ?? 0.0;
        _isPrinterConnected = isConnected;
      });
    } catch (e) {
      print("Erro ao carregar configurações da impressora: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao carregar configurações da impressora")),
      );
    }
  }

  Future<void> _testPrint() async {
    try {
      await api.testPrint();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Teste de impressão enviado!")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao testar impressão: $e")));
    }
  }

  Future<void> _savePrinterSettings() async {
    if (_selectedPrinter == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Selecione uma impressora")));
      return;
    }

    try {
      await api.savePrinterSettings(
        printerName: _selectedPrinter!,
        marginTop: _marginTop,
        marginBottom: _marginBottom,
        marginLeft: _marginLeft,
        marginRight: _marginRight,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Configurações salvas com sucesso!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao salvar configurações: $e")),
      );
    }
  }

  Widget _buildAccordionItem({
    required String title,
    required IconData icon,
    required Widget content,
    required int index,
  }) {
    final isExpanded = _expandedIndex == index;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: Colors.orange),
            title: Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.orange,
            ),
            onTap: () {
              setState(() {
                _expandedIndex = isExpanded ? -1 : index;
              });
            },
          ),
          if (isExpanded) Padding(padding: EdgeInsets.all(16), child: content),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Preço por kg (R\$):", style: TextStyle(fontSize: 16)),
          SizedBox(height: 12),
          TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Ex: 25.50",
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return "Informe um valor";
              final n = double.tryParse(val.replaceAll(',', '.'));
              if (n == null) return "Valor inválido";
              return null;
            },
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _savePrice,
            child: Text("Salvar Preço"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status da Impressora
        Row(
          children: [
            Icon(
              _isPrinterConnected ? Icons.check_circle : Icons.error,
              color: _isPrinterConnected ? Colors.green : Colors.red,
            ),
            SizedBox(width: 8),
            Text(
              _isPrinterConnected
                  ? "Impressora Conectada"
                  : "Impressora Desconectada",
              style: TextStyle(
                color: _isPrinterConnected ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Seleção de Impressora
        if (_availablePrinters.isNotEmpty)
          DropdownButtonFormField<String>(
            value: _selectedPrinter,
            decoration: InputDecoration(
              labelText: "Impressora",
              border: OutlineInputBorder(),
            ),
            items: _availablePrinters.map((printer) {
              return DropdownMenuItem(value: printer, child: Text(printer));
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedPrinter = value);
            },
          )
        else
          Text(
            "Nenhuma impressora disponível",
            style: TextStyle(color: Colors.red),
          ),
        SizedBox(height: 16),

        // Ajuste de Margens
        Text(
          "Ajuste de Margens (mm):",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _marginTop.toString(),
                decoration: InputDecoration(
                  labelText: "Superior",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    _marginTop = double.tryParse(value) ?? 0.0,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: _marginBottom.toString(),
                decoration: InputDecoration(
                  labelText: "Inferior",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    _marginBottom = double.tryParse(value) ?? 0.0,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _marginLeft.toString(),
                decoration: InputDecoration(
                  labelText: "Esquerda",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    _marginLeft = double.tryParse(value) ?? 0.0,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: _marginRight.toString(),
                decoration: InputDecoration(
                  labelText: "Direita",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    _marginRight = double.tryParse(value) ?? 0.0,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Botões de Ação
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _testPrint,
              icon: Icon(Icons.print),
              label: Text("Testar Impressão"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _savePrinterSettings,
              icon: Icon(Icons.save),
              label: Text("Salvar Configurações"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pesei! - Painel de Controle"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildAccordionItem(
                    title: "Configuração de Preço",
                    icon: Icons.attach_money,
                    content: _buildPriceSection(),
                    index: 0,
                  ),
                  _buildAccordionItem(
                    title: "Configurações de Impressora",
                    icon: Icons.print,
                    content: _buildPrinterSection(),
                    index: 1,
                  ),
                ],
              ),
            ),
    );
  }
}
