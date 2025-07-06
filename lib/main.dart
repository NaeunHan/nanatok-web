import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const NanatokApp());
}

class NanatokApp extends StatelessWidget {
  const NanatokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NANATOK',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Color(0xFFFFF0F5),
      ),
      home: const MarginCalculatorPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MarginCalculatorPage extends StatefulWidget {
  const MarginCalculatorPage({super.key});

  @override
  State<MarginCalculatorPage> createState() => _MarginCalculatorPageState();
}

class _MarginCalculatorPageState extends State<MarginCalculatorPage> {
  final _buyController = TextEditingController();
  final _sellController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _feeRateController = TextEditingController(text: "3.63");
  final _vatRateController = TextEditingController(text: "10");
  final _materialController = TextEditingController();
  final _materialMemoController = TextEditingController();

  double margin = 0.0;
  double profitRate = 0.0;
  double feeAmount = 0.0;

  List<Map<String, dynamic>> savedRecords = [];

  final currencyFormatter = NumberFormat.currency(locale: 'ko_KR', symbol: '₩', decimalDigits: 0);

  void _calculate() {
    final buy = double.tryParse(_buyController.text) ?? 0;
    final sell = double.tryParse(_sellController.text) ?? 0;
    final delivery = double.tryParse(_deliveryController.text) ?? 0;
    final feeRate = double.tryParse(_feeRateController.text) ?? 0;
    final vatRate = double.tryParse(_vatRateController.text) ?? 0;

    final realBuy = buy;
    final feeFromSell = sell * (feeRate / 100);
    final feeFromDelivery = delivery * (feeRate / 100);
    final fee = feeFromSell + feeFromDelivery;
    final vat = sell * (vatRate / 100);
    final material = double.tryParse(_materialController.text) ?? 0;

    feeAmount = fee;

    final m = sell - realBuy - delivery - fee - vat - material;
    final r = realBuy > 0 ? (m / realBuy) * 100 : 0;

    setState(() {
      margin = m;
      profitRate = r.toDouble();
    });
  }

  Future<void> _saveRecord() async {
    final prefs = await SharedPreferences.getInstance();
    final record = {
      "buy": _buyController.text,
      "sell": _sellController.text,
      "delivery": _deliveryController.text,
      "feeRate": _feeRateController.text,
      "vatRate": _vatRateController.text,
      "margin": margin,
      "profitRate": profitRate,
      "feeAmount": feeAmount,
      "timestamp": DateTime.now().toIso8601String(),
      "material": _materialController.text,
      "materialMemo": _materialMemoController.text,
    };
    savedRecords.add(record);
    await prefs.setString("records", jsonEncode(savedRecords));
    setState(() {});
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("records");
    if (data != null) {
      savedRecords = List<Map<String, dynamic>>.from(jsonDecode(data));
      setState(() {});
    }
  }

  Future<void> _deleteRecord(int index) async {
    final prefs = await SharedPreferences.getInstance();
    savedRecords.removeAt(index);
    await prefs.setString("records", jsonEncode(savedRecords));
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
    );
  }

  Widget _buildResult(String label, double value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
       "$label: ${currencyFormatter.format(value)}",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPercentResult(String label, double value) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.pink.shade50,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      "$label: ${value.toStringAsFixed(1)}%",
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🐤 NANATOK 네이버 스마트스토어 마진 계산기")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInput("구매가", _buyController),
            _buildInput("판매가", _sellController),
            _buildInput("택배비", _deliveryController),
            _buildInput("수수료율 (%)", _feeRateController),
            _buildInput("부가세율 (%)", _vatRateController),
            _buildInput("부자재비 (개당)", _materialController),
            _buildInput("부자재 메모", _materialMemoController),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _calculate,
              child: const Text("🧮 계산하기"),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _saveRecord,
              child: const Text("💾 저장하기"),
            ),
            const SizedBox(height: 12),
            _buildResult("💰 마진", margin),
            _buildPercentResult("📈 이익률", profitRate),
            const Divider(height: 32),
            const Text("📑 저장된 기록", style: TextStyle(fontSize: 20)),
            ...savedRecords.asMap().entries.map((entry) {
              int index = entry.key;
              var e = entry.value;
              return ListTile(
        title: Text("${currencyFormatter.format(double.parse(e['buy']))} → ${currencyFormatter.format(double.parse(e['sell']))} | 마진 ${currencyFormatter.format(e['margin'])}"),
        subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Text("수수료 ${currencyFormatter.format(e['feeAmount'])}"),
          if (e['materialMemo'] != null && e['materialMemo'].toString().isNotEmpty)
          Text("📦 부자재 메모: ${e['materialMemo']}"),
          Text(e['timestamp']),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => _deleteRecord(index),
               ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
