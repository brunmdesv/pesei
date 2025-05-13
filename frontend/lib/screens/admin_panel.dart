import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> with SingleTickerProviderStateMixin {
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

  // Cores do tema
  final Color _primaryColor = Color(0xFFF97316);
  final Color _secondaryColor = Color(0xFFFF8C38);
  final Color _backgroundColor = Color(0xFFFFF8F0);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF333333);
  final Color _subtitleColor = Color(0xFF707070);

  // Controle para o TabController
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadCurrentPrice();
    _loadPrinterSettings();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentPrice() async {
    try {
      double price = await api.getPricePerKg();
      _priceController.text = price.toStringAsFixed(2);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao carregar preço: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _savePrice() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    
    double newPrice = double.parse(_priceController.text.replaceAll(',', '.'));
    try {
      await api.setPricePerKg(newPrice);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("Preço atualizado com sucesso!"),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao salvar preço: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
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
        SnackBar(
          content: Text("Erro ao carregar configurações da impressora"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testPrint() async {
    try {
      setState(() => _loading = true);
      
      await api.testPrint();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.print, color: Colors.white),
              SizedBox(width: 10),
              Text("Teste de impressão enviado!"),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao testar impressão: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _savePrinterSettings() async {
    if (_selectedPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Selecione uma impressora"),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    try {
      setState(() => _loading = true);
      
      await api.savePrinterSettings(
        printerName: _selectedPrinter!,
        marginTop: _marginTop,
        marginBottom: _marginBottom,
        marginLeft: _marginLeft,
        marginRight: _marginRight,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("Configurações salvas com sucesso!"),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao salvar configurações: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildPriceSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Configuração de Preço",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Defina o valor cobrado por quilograma",
                style: TextStyle(
                  fontSize: 14,
                  color: _subtitleColor,
                ),
              ),
              SizedBox(height: 32),
              
              _buildInfoCard(
                icon: Icons.info_outline,
                title: "Informações de Preço",
                content: "O preço definido aqui será usado para todos os cálculos de valor total nas pesagens.",
              ),
              
              SizedBox(height: 32),
              
              Text(
                "Preço por kg (R\$):",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _textColor,
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(fontSize: 16, color: _textColor),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red, width: 1),
                  ),
                  prefixIcon: Icon(Icons.attach_money, color: _primaryColor),
                  hintText: "Ex: 25.50",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Informe um valor";
                  final n = double.tryParse(val.replaceAll(',', '.'));
                  if (n == null) return "Valor inválido";
                  return null;
                },
              ),
              SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _savePrice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _loading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 8),
                            Text(
                              "SALVAR PREÇO",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrinterSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Configurações de Impressora",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Configure a impressora térmica para tickets",
              style: TextStyle(
                fontSize: 14,
                color: _subtitleColor,
              ),
            ),
            SizedBox(height: 24),
            
            // Status da Impressora
            _buildPrinterStatusCard(),
            SizedBox(height: 32),
            
            // Seleção de Impressora
            Text(
              "Selecione a Impressora",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
            ),
            SizedBox(height: 12),
            
            if (_availablePrinters.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedPrinter,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.print, color: _primaryColor),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  items: _availablePrinters.map((printer) {
                    return DropdownMenuItem(value: printer, child: Text(printer));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedPrinter = value);
                  },
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 12),
                    Text(
                      "Nenhuma impressora disponível",
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 32),
            
            // Ajuste de Margens
            Text(
              "Ajuste de Margens (mm)",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Defina as margens para impressão dos tickets",
              style: TextStyle(
                fontSize: 14,
                color: _subtitleColor,
              ),
            ),
            SizedBox(height: 16),
            
            // Margens no formato de card com visual melhorado
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Superior",
                              style: TextStyle(
                                fontSize: 12,
                                color: _subtitleColor,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: TextFormField(
                                initialValue: _marginTop.toString(),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) => _marginTop = double.tryParse(value) ?? 0.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Inferior",
                              style: TextStyle(
                                fontSize: 12,
                                color: _subtitleColor,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: TextFormField(
                                initialValue: _marginBottom.toString(),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) => _marginBottom = double.tryParse(value) ?? 0.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Esquerda",
                              style: TextStyle(
                                fontSize: 12,
                                color: _subtitleColor,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: TextFormField(
                                initialValue: _marginLeft.toString(),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) => _marginLeft = double.tryParse(value) ?? 0.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Direita",
                              style: TextStyle(
                                fontSize: 12,
                                color: _subtitleColor,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: TextFormField(
                                initialValue: _marginRight.toString(),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) => _marginRight = double.tryParse(value) ?? 0.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 32),
            
            // Botões de Ação
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _testPrint,
                    icon: Icon(Icons.print),
                    label: Text(
                      "TESTAR IMPRESSÃO",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _secondaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _savePrinterSettings,
                    icon: Icon(Icons.save),
                    label: Text(
                      "SALVAR CONFIGURAÇÕES",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterStatusCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isPrinterConnected ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isPrinterConnected ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _isPrinterConnected ? Colors.green.shade100 : Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPrinterConnected ? Icons.check_circle : Icons.error_outline,
              color: _isPrinterConnected ? Colors.green : Colors.red,
              size: 30,
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPrinterConnected ? "Impressora Conectada" : "Impressora Desconectada",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _isPrinterConnected ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _isPrinterConnected
                      ? "A impressora está pronta para usar"
                      : "Verifique a conexão da impressora",
                  style: TextStyle(
                    fontSize: 14,
                    color: _isPrinterConnected ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryColor,
        title: Row(
          children: [
            Icon(Icons.settings, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Pesei! - Painel de Controle",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.home, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            tooltip: "Voltar para balança",
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(
              icon: Icon(Icons.attach_money),
              text: "Preço",
            ),
            Tab(
              icon: Icon(Icons.print),
              text: "Impressora",
            ),
          ],
        ),
      ),
      body: _loading && _tabController.index == -1
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            )
          : SafeArea(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Aba de Preço
                  SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPriceSection(),
                      ],
                    ),
                  ),
                  
                  // Aba de Impressora
                  SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPrinterSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}