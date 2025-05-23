import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import 'package:flutter/services.dart';

class BalanceScreen extends StatefulWidget {
  @override
  _BalanceScreenState createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen>
    with SingleTickerProviderStateMixin {
  final ApiService apiService = ApiService();
  double currentWeight = 0.0;
  double pricePerKg = 0.0;
  String statusMessage = "Aguardando pesagem...";
  Timer? stabilizationTimer;
  AnimationController? _animationController;
  Animation<double>? _weightAnimation;
  double _previousWeight = 0.0;
  bool _isLoading = true;
  Color _statusColor = Colors.orange;
  bool _isPrinting = false;

  // Cores do tema laranja
  final Color _primaryColor = Color(0xFFF97316);
  final Color _secondaryColor = Color(0xFFFF8C38);
  final Color _accentColor = Color(0xFFEB6C11);
  final Color _backgroundColor = Color(0xFFFFF8F0);

  // Variáveis para resumo da nota impressa
  double? _lastWeight;
  double? _lastPricePerKg;
  double? _lastTotalValue;
  String? _lastTimestamp;

  @override
  void initState() {
    super.initState();

    // Configurando animação
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    // Bloqueando rotação da tela
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _loadPrice();

    // Simulando carregamento inicial
    Future.delayed(Duration(milliseconds: 800), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    stabilizationTimer?.cancel();
    _animationController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<void> _loadPrice() async {
    try {
      double price = await apiService.getPricePerKg();
      setState(() {
        pricePerKg = price;
      });
    } catch (e) {
      print("Erro ao carregar preço por kg: $e");
    }
  }

  Future<void> _generateSimulatedWeight() async {
    setState(() {
      statusMessage = "Aguardando pesagem...";
      _statusColor = Colors.orange;
    });
    try {
      // Feedback tátil
      HapticFeedback.mediumImpact();
      double weight = await apiService.fetchWeight();
      // Configurando animação para transição suave
      _animationController?.reset();
      _weightAnimation = Tween<double>(
        begin: _previousWeight,
        end: weight,
      ).animate(
        CurvedAnimation(
          parent: _animationController!,
          curve: Curves.easeOutCubic,
        ),
      )..addListener(() {
        setState(() {
          currentWeight = _weightAnimation!.value;
        });
      });
      _animationController?.forward();
      _previousWeight = weight;
      setState(() {
        statusMessage = "Peso detectado: " + weight.toStringAsFixed(3) + " kg";
        _statusColor = Color(0xFF22C55E); // Verde
      });
      _startStabilizationTimer();
    } catch (e) {
      setState(() {
        statusMessage = "Erro ao gerar peso";
        _statusColor = Colors.red;
      });
      print("Erro ao gerar peso simulado: $e");
    }
  }

  void _startStabilizationTimer() {
    stabilizationTimer?.cancel();
    setState(() {
      statusMessage = "Estabilizando pesagem...";
      _statusColor = Colors.blue;
    });
    stabilizationTimer = Timer(Duration(seconds: 3), () {
      _printTicket();
    });
  }

  Future<void> _printTicket() async {
    if (currentWeight == null) return;
    setState(() => _isPrinting = true);
    try {
      final timestamp = DateTime.now().toIso8601String();
      final totalValue = currentWeight * pricePerKg;
      final totalValueStr = "R\$ " + totalValue.toStringAsFixed(2);
      await apiService.printTicket(currentWeight, totalValueStr, timestamp);
      setState(() {
        statusMessage = "Nota impressa";
        _statusColor = Colors.green;
        _lastWeight = currentWeight;
        _lastPricePerKg = pricePerKg;
        _lastTotalValue = totalValue;
        _lastTimestamp = timestamp;
      });
      // Exibe o popup de resumo da nota
      _showTicketSummaryDialog();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Nota impressa com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao imprimir nota: " + e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  void _showTicketSummaryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final date = DateTime.tryParse(_lastTimestamp ?? "");
        final formattedDate =
            date != null
                ? "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}"
                : _lastTimestamp ?? "";
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.receipt_long, color: _primaryColor),
              SizedBox(width: 8),
              Text("Resumo da Nota", style: TextStyle(color: _primaryColor)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTicketRow(
                "Peso",
                "${_lastWeight?.toStringAsFixed(3) ?? '-'} kg",
                isBold: true,
              ),
              SizedBox(height: 8),
              _buildTicketRow(
                "Preço/kg",
                "R\$ ${_lastPricePerKg?.toStringAsFixed(2) ?? '-'}",
              ),
              SizedBox(height: 8),
              _buildTicketRow(
                "Valor Total",
                "R\$ ${_lastTotalValue?.toStringAsFixed(2) ?? '-'}",
                isBold: true,
              ),
              SizedBox(height: 8),
              _buildTicketRow("Data/Hora", formattedDate),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  statusMessage = "Aguardando pesagem...";
                  _statusColor = Colors.orange;
                  currentWeight = 0.0;
                });
              },
              child: Text(
                "FECHAR",
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTicketRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.black54, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightDisplay() {
    final calculatedValue = currentWeight * pricePerKg;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PESO ATUAL",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusMessage,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${currentWeight.toStringAsFixed(3)}",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  " kg",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(0.3), thickness: 1),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "PREÇO/KG",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "R\$ ${pricePerKg.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "VALOR TOTAL",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "R\$ ${calculatedValue.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
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
        backgroundColor: _backgroundColor,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.scale, color: _primaryColor),
            SizedBox(width: 8),
            Text(
              "Pesei!",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: _accentColor),
            onPressed: _generateSimulatedWeight,
            tooltip: "Gerar Peso Simulado",
          ),
          Container(
            margin: EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Icon(Icons.admin_panel_settings, color: Colors.black54),
              onPressed: () => Navigator.pushNamed(context, '/admin_login'),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                ),
              )
              : SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    _buildWeightDisplay(),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: _primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.scale_outlined,
                                size: 70,
                                color: _primaryColor.withOpacity(0.7),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Clique em   ",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh, color: _accentColor),
                                Text(
                                  "   para simular uma pesagem",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
