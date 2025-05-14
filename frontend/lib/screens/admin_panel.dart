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

  // Cores do tema consistentes com o app
  final Color _primaryColor = Color(0xFFF97316);
  final Color _secondaryColor = Color(0xFFFF8C38);
  final Color _accentColor = Color(0xFFEB6C11);
  final Color _backgroundColor = Color(0xFFFFF8F0);

  // Estado para controle de navegação e carregamento
  int _selectedIndex = 0;
  bool _loading = true;

  // Configurações de impressora
  String? _selectedPrinter;
  bool _isPrinterConnected = false;
  List<String> _availablePrinters = [];
  double _marginTop = 0.0;
  double _marginBottom = 0.0;
  double _marginLeft = 0.0;
  double _marginRight = 0.0;

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
      _showErrorSnackbar("Erro ao carregar preço: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _savePrice() async {
    if (!_formKey.currentState!.validate()) return;

    double newPrice = double.parse(_priceController.text.replaceAll(',', '.'));
    try {
      await api.setPricePerKg(newPrice);
      _showSuccessSnackbar("Preço atualizado com sucesso!");
    } catch (e) {
      _showErrorSnackbar("Erro ao salvar preço: $e");
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
      _showErrorSnackbar("Erro ao carregar configurações da impressora");
    }
  }

  Future<void> _testPrint() async {
    try {
      await api.testPrint();
      _showSuccessSnackbar("Teste de impressão enviado!");
    } catch (e) {
      _showErrorSnackbar("Erro ao testar impressão: $e");
    }
  }

  Future<void> _savePrinterSettings() async {
    if (_selectedPrinter == null) {
      _showErrorSnackbar("Selecione uma impressora");
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

      _showSuccessSnackbar("Configurações salvas com sucesso!");
    } catch (e) {
      _showErrorSnackbar("Erro ao salvar configurações: $e");
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Lista de itens do menu lateral
  List<Map<String, dynamic>> get _menuItems => [
    {'title': 'Dashboard', 'icon': Icons.dashboard_rounded},
    {'title': 'Configuração de Preço', 'icon': Icons.attach_money},
    {'title': 'Configurações de Impressora', 'icon': Icons.print},
    {'title': 'Histórico de Pesagens', 'icon': Icons.history},
    {'title': 'Ajustes', 'icon': Icons.settings},
  ];

  Widget _buildPriceSection() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Configuração de Preço",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Defina o valor por quilograma para cálculo automático",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              SizedBox(height: 24),

              Text(
                "Preço por kg (R\$):",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),

              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.monetization_on, color: _primaryColor),
                  hintText: "Ex: 25.50",
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Informe um valor";
                  final n = double.tryParse(val.replaceAll(',', '.'));
                  if (n == null) return "Valor inválido";
                  return null;
                },
              ),

              SizedBox(height: 24),

              Center(
                child: ElevatedButton.icon(
                  onPressed: _savePrice,
                  icon: Icon(Icons.save),
                  label: Text("SALVAR PREÇO"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Configurações de Impressora",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Configure sua impressora térmica para emissão de tickets",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            SizedBox(height: 24),

            // Status da Impressora
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    _isPrinterConnected
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      _isPrinterConnected
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isPrinterConnected ? Icons.check_circle : Icons.error,
                    color: _isPrinterConnected ? Colors.green : Colors.red,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isPrinterConnected
                              ? "Impressora Conectada"
                              : "Impressora Desconectada",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                _isPrinterConnected
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                            fontSize: 16,
                          ),
                        ),
                        if (!_isPrinterConnected)
                          Text(
                            "Verifique a conexão e as configurações",
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Seleção de Impressora
            Text(
              "Selecione a Impressora:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),

            if (_availablePrinters.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedPrinter,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.print, color: _primaryColor),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items:
                    _availablePrinters.map((printer) {
                      return DropdownMenuItem(
                        value: printer,
                        child: Text(printer),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPrinter = value);
                },
              )
            else
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      "Nenhuma impressora disponível",
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 24),

            // Ajuste de Margens
            Text(
              "Ajuste de Margens (mm):",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),

            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _marginTop.toString(),
                          decoration: InputDecoration(
                            labelText: "Superior",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged:
                              (value) =>
                                  _marginTop = double.tryParse(value) ?? 0.0,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: _marginBottom.toString(),
                          decoration: InputDecoration(
                            labelText: "Inferior",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged:
                              (value) =>
                                  _marginBottom = double.tryParse(value) ?? 0.0,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _marginLeft.toString(),
                          decoration: InputDecoration(
                            labelText: "Esquerda",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged:
                              (value) =>
                                  _marginLeft = double.tryParse(value) ?? 0.0,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: _marginRight.toString(),
                          decoration: InputDecoration(
                            labelText: "Direita",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged:
                              (value) =>
                                  _marginRight = double.tryParse(value) ?? 0.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Botões de Ação
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testPrint,
                    icon: Icon(Icons.print),
                    label: Text("TESTAR IMPRESSÃO"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _savePrinterSettings,
                    icon: Icon(Icons.save),
                    label: Text("SALVAR CONFIGURAÇÕES"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Dashboard",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Visão geral do sistema",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          SizedBox(height: 24),

          // Cards de informações rápidas
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.shopping_cart,
                  title: "Pesagens Hoje",
                  value: "27",
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.attach_money,
                  title: "Valor Total",
                  value: "R\$ 1.342,50",
                  color: _primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.scale,
                  title: "Peso Médio",
                  value: "2.73 kg",
                  color: Colors.green,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.price_change,
                  title: "Preço por kg",
                  value: "R\$ ${_priceController.text}",
                  color: Colors.purple,
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Seção de dicas rápidas
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        "Dicas Rápidas",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildTipItem(
                    "Para alterar o preço por kg, acesse a seção 'Configuração de Preço'.",
                  ),
                  _buildTipItem(
                    "Certifique-se que a impressora está conectada antes de realizar pesagens.",
                  ),
                  _buildTipItem(
                    "Verifique periodicamente o histórico de pesagens para fins de controle.",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.arrow_right, color: _primaryColor),
          SizedBox(width: 4),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Histórico de Pesagens",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Registro de todas as pesagens realizadas",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          SizedBox(height: 24),

          // Filtros
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Filtros",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: "Data Inicial",
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: "Data Final",
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.search),
                      label: Text("BUSCAR"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          // Lista de pesagens (demo)
          for (int i = 0; i < 5; i++)
            _buildHistoryItem(
              date: "13/05/2025 ${14 - i}:${30 - i * 5}",
              weight: (3.5 - i * 0.25).toStringAsFixed(3),
              value: (87.5 - i * 6.25).toStringAsFixed(2),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required String date,
    required String weight,
    required String value,
  }) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.receipt, color: _primaryColor),
        ),
        title: Text(
          "Peso: $weight kg",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("Data: $date"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "R\$ $value",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _primaryColor,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Impresso",
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ajustes",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Configurações gerais do sistema",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          SizedBox(height: 24),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Aparência",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    title: Text("Tema Escuro"),
                    leading: Icon(Icons.dark_mode, color: _primaryColor),
                    trailing: Switch(
                      value: false,
                      onChanged: (value) {},
                      activeColor: _primaryColor,
                    ),
                  ),
                  Divider(),
                  ListTile(
                    title: Text("Mostrar Valor em Tempo Real"),
                    leading: Icon(Icons.attach_money, color: _primaryColor),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {},
                      activeColor: _primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Segurança",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    title: Text("Alterar Senha de Administrador"),
                    leading: Icon(Icons.lock, color: _primaryColor),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  Divider(),
                  ListTile(
                    title: Text("Tempo para Bloqueio Automático"),
                    leading: Icon(Icons.timer, color: _primaryColor),
                    trailing: DropdownButton<String>(
                      value: "10 min",
                      items:
                          ["5 min", "10 min", "30 min", "Nunca"]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (value) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: _backgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: _primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.scale, color: Colors.white, size: 48),
                  SizedBox(height: 8),
                  Text(
                    "Pesei!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Painel de Controle",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ..._menuItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return ListTile(
                leading: Icon(
                  item['icon'],
                  color:
                      _selectedIndex == index ? _primaryColor : Colors.black54,
                ),
                title: Text(
                  item['title'],
                  style: TextStyle(
                    color:
                        _selectedIndex == index
                            ? _primaryColor
                            : Colors.black87,
                    fontWeight:
                        _selectedIndex == index
                            ? FontWeight.bold
                            : FontWeight.normal,
                  ),
                ),
                selected: _selectedIndex == index,
                onTap: () {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                },
              );
            }).toList(),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text("Sair", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildPriceSection();
      case 2:
        return _buildPrinterSection();
      case 3:
        return _buildHistorySection();
      case 4:
        return _buildSettingsSection();
      default:
        return _buildDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_menuItems[_selectedIndex]['title']),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      drawer: _buildDrawer(),
      body:
          _loading ? Center(child: CircularProgressIndicator()) : _buildBody(),
    );
  }
}
