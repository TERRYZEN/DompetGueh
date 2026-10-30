import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];
const expenseCategories = [
  'Makanan',
  'Transportasi',
  'Pendidikan',
  'Hiburan',
  'Kebutuhan',
  'Lainnya',
];
const incomeCategories = ['Gaji', 'Freelance', 'Bonus', 'Investasi', 'Lainnya'];

String groupDigits(String value) => value.replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (m) => '${m[1]}.',
);
String rupiah(num value) =>
    '${value < 0 ? '-' : ''}Rp${groupDigits(value.abs().round().toString())}';
String dateValue(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String displayDate(String d) => d.split('-').reversed.join('/');

class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 16) return oldValue;
    final value = digits.isEmpty
        ? ''
        : groupDigits(digits.replaceFirst(RegExp(r'^0+(?=\d)'), ''));
    return TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}

class FinanceEntry {
  final int id;
  final String name, date, category;
  final int amount;
  final bool income, addedToBudget;
  const FinanceEntry({
    required this.id,
    required this.name,
    required this.date,
    required this.category,
    required this.amount,
    required this.income,
    this.addedToBudget = false,
  });

  factory FinanceEntry.fromJson(Map<String, dynamic> j, bool income) =>
      FinanceEntry(
        id: (j['id'] as num).toInt(),
        name: j['nama'] as String,
        date: j['tanggal'] as String,
        category: j['kategori'] as String,
        amount: (j['jumlah'] as num).toInt(),
        income: income,
        addedToBudget: j['ditambahkan_ke_anggaran'] == true,
      );

  int get year => int.parse(date.substring(0, 4));
  int get month => int.parse(date.substring(5, 7));
}

class FinanceData {
  final int budget;
  final String name;
  final List<FinanceEntry> expenses, incomes;
  const FinanceData({
    this.budget = 0,
    this.name = 'Pengguna',
    this.expenses = const [],
    this.incomes = const [],
  });
  factory FinanceData.fromJson(Map<String, dynamic> j) => FinanceData(
    budget: (j['anggaran'] as num).toInt(),
    name: (j['nama_pengguna'] as String?) ?? 'Pengguna',
    expenses: (j['pengeluaran'] as List)
        .map((e) => FinanceEntry.fromJson(Map<String, dynamic>.from(e), false))
        .toList(),
    incomes: (j['pemasukan'] as List)
        .map((e) => FinanceEntry.fromJson(Map<String, dynamic>.from(e), true))
        .toList(),
  );
  int get totalExpense => expenses.fold(0, (n, e) => n + e.amount);
  int get totalIncome => incomes.fold(0, (n, e) => n + e.amount);
  int get remaining => budget - totalExpense;
  double get percent =>
      budget > 0 ? (totalExpense / budget * 100).clamp(0, 100) : 0;
  List<FinanceEntry> get history => [...expenses, ...incomes]
    ..sort((a, b) {
      final order = b.date.compareTo(a.date);
      return order != 0 ? order : b.id.compareTo(a.id);
    });
}

class CategoryStyle {
  final IconData icon;
  final Color color;
  const CategoryStyle(this.icon, this.color);
}

const categoryStyles = <String, CategoryStyle>{
  'Makanan': CategoryStyle(Icons.ramen_dining_outlined, Color(0xffff9b67)),
  'Transportasi': CategoryStyle(Icons.two_wheeler_outlined, Color(0xff5f9df7)),
  'Pendidikan': CategoryStyle(Icons.menu_book_rounded, Color(0xff8c7cf6)),
  'Hiburan': CategoryStyle(Icons.headphones_outlined, Color(0xffe77bb5)),
  'Kebutuhan': CategoryStyle(Icons.shopping_bag_outlined, Color(0xff31b99a)),
  'Lainnya': CategoryStyle(Icons.auto_awesome_outlined, Color(0xffb1b5c6)),
  'Gaji': CategoryStyle(Icons.work_outline, Color(0xff1caa7b)),
  'Freelance': CategoryStyle(Icons.desktop_windows_outlined, Color(0xff038df7)),
  'Bonus': CategoryStyle(Icons.card_giftcard_rounded, Color(0xfff5b745)),
  'Investasi': CategoryStyle(Icons.trending_up_rounded, Color(0xff8c7cf6)),
};
