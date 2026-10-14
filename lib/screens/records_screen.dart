import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen(
      {super.key,
      required this.storage,
      required this.userId,
      required this.isExpense,
      required this.currency,
      required this.onChanged});
  final StorageService storage;
  final String userId;
  final bool isExpense;
  final String currency;
  final VoidCallback onChanged;
  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final _search = TextEditingController();
  String _category = 'All', _sort = 'Newest first';
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _edit(
      {String? id,
      String? description,
      double? amount,
      DateTime? date,
      String? category}) async {
    final key = GlobalKey<FormState>();
    final amountC =
        TextEditingController(text: amount?.toStringAsFixed(2) ?? '');
    final descC = TextEditingController(text: description ?? '');
    DateTime pickedDate = date ?? DateTime.now();
    String pickedCategory = category ?? categories.first;
    final saved = await showDialog<bool>(
        context: context,
        builder: (dc) => StatefulBuilder(
            builder: (context, ss) => AlertDialog(
                    title: Text(
                        '${id == null ? 'Add' : 'Edit'} ${widget.isExpense ? 'expense' : 'allowance'}'),
                    content: Form(
                        key: key,
                        child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              TextFormField(
                                  controller: amountC,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*')),
                                  ],
                                  decoration: const InputDecoration(
                                      labelText: 'Amount'),
                                  validator: (v) {
                                    final n = double.tryParse(v?.trim() ?? '');
                                    return n == null || n <= 0
                                        ? 'Enter an amount greater than zero.'
                                        : null;
                                  }),
                              const SizedBox(height: 10),
                              TextFormField(
                                  controller: descC,
                                  decoration: InputDecoration(
                                      labelText: widget.isExpense
                                          ? 'What did you buy?'
                                          : 'Source / description'),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Enter a description.'
                                          : null),
                              if (widget.isExpense) ...[
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                    initialValue: pickedCategory,
                                    decoration: const InputDecoration(
                                        labelText: 'Category'),
                                    items: categories
                                        .map((c) => DropdownMenuItem(
                                            value: c, child: Text(c)))
                                        .toList(),
                                    onChanged: (v) => ss(() =>
                                        pickedCategory = v ?? categories.first))
                              ],
                              ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.calendar_month),
                                  title: Text(dateText(pickedDate)),
                                  onTap: () async {
                                    final d = await showDatePicker(
                                        context: context,
                                        initialDate: pickedDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100));
                                    if (d != null) ss(() => pickedDate = d);
                                  })
                            ]))),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dc, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () async {
                            if (!key.currentState!.validate()) return;
                            final n = double.parse(amountC.text.trim());
                            final rid = id ?? uniqueId();
                            if (widget.isExpense) {
                              await widget.storage.saveExpense(Expense(
                                  id: rid,
                                  userId: widget.userId,
                                  amount: n,
                                  date: pickedDate,
                                  description: descC.text.trim(),
                                  category: pickedCategory));
                            } else {
                              await widget.storage.saveAllowance(Allowance(
                                  id: rid,
                                  userId: widget.userId,
                                  amount: n,
                                  date: pickedDate,
                                  description: descC.text.trim()));
                            }
                            if (dc.mounted) Navigator.pop(dc, true);
                          },
                          child: const Text('Save'))
])));
        // Defer disposal until after the dialog's exit animation completes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            amountC.dispose();
            descC.dispose();
          }
        });
        if (saved == true && mounted) {
      setState(() {});
      widget.onChanged();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('${widget.isExpense ? 'Expense' : 'Allowance'} saved.')));
    }
  }

  Future<void> _delete(String id, String description) async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Delete record?'),
                content: Text('Delete "$description"? This cannot be undone.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Delete'))
                ]));
    if (yes != true) return;
    if (widget.isExpense) {
      await widget.storage.deleteExpense(id);
    } else {
      await widget.storage.deleteAllowance(id);
    }
    if (!mounted) return;
    setState(() {});
    widget.onChanged();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Record deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    final allE = widget.storage.expenses(widget.userId);
    final allA = widget.storage.allowances(widget.userId);
    final list = widget.isExpense ? allE : allA;
    final filtered = list.where((x) {
      final d = x is Expense ? x.description : (x as Allowance).description;
      final c = x is Expense ? x.category : 'Allowance';
      return d.toLowerCase().contains(_search.text.trim().toLowerCase()) &&
          (!widget.isExpense || _category == 'All' || c == _category);
    }).toList();
    filtered.sort((a, b) {
      final da = a is Expense ? a.date : (a as Allowance).date;
      final db = b is Expense ? b.date : (b as Allowance).date;
      return _sort == 'Newest first' ? db.compareTo(da) : da.compareTo(db);
    });
    final total = list.fold<double>(
        0, (s, x) => s + (x is Expense ? x.amount : (x as Allowance).amount));
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text(widget.isExpense ? 'Expenses' : 'Allowances',
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.ink)),
      const SizedBox(height: 5),
      Text(
          widget.isExpense
              ? 'Record purchases and review spending.'
              : 'Keep track of money you receive.',
          style: const TextStyle(color: AppTheme.muted)),
      const SizedBox(height: 18),
      Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: widget.isExpense
                  ? const Color(0xFFFFF1EB)
                  : const Color(0xFFE9F8F1),
              borderRadius: BorderRadius.circular(18)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                widget.isExpense
                    ? 'Total recorded expenses'
                    : 'Total recorded allowance',
                style: const TextStyle(color: AppTheme.muted)),
            const SizedBox(height: 6),
            Text(money(total, widget.currency),
                style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: widget.isExpense ? AppTheme.orange : AppTheme.green))
          ])),
      const SizedBox(height: 14),
      FilledButton.icon(
          onPressed: () => _edit(),
          icon: const Icon(Icons.add),
          label: Text('Add ${widget.isExpense ? 'expense' : 'allowance'}')),
      const SizedBox(height: 14),
      TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search), hintText: 'Search records...')),
      if (widget.isExpense) ...[
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category filter'),
            items: ['All', ...categories]
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? 'All'))
      ],
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
          initialValue: _sort,
          decoration: const InputDecoration(labelText: 'Sort by date'),
          items: const ['Newest first', 'Oldest first']
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _sort = v ?? 'Newest first')),
      const SizedBox(height: 12),
      if (filtered.isEmpty)
        EmptyState(
            icon: widget.isExpense
                ? Icons.receipt_long_outlined
                : Icons.savings_outlined,
            title: list.isEmpty ? 'No records yet' : 'No matching records',
            message: list.isEmpty
                ? 'Tap Add to create your first record.'
                : 'Try changing your search or filter.')
      else
        ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final x = filtered[i];
              final bool isExpense = widget.isExpense;
              late String desc, cat, rid;
              late double amt;
              late DateTime dt;
              IconData leadIcon;
              if (isExpense) {
                final e = x as Expense;
                desc = e.description;
                cat = e.category;
                rid = e.id;
                amt = e.amount;
                dt = e.date;
                leadIcon = Icons.receipt_long_outlined;
              } else {
                final a = x as Allowance;
                desc = a.description;
                cat = 'Allowance';
                rid = a.id;
                amt = a.amount;
                dt = a.date;
                leadIcon = Icons.savings_outlined;
              }
              return Card(
                  child: ListTile(
                leading: CircleAvatar(
                    backgroundColor: AppTheme.purple.withValues(alpha: .12),
                    child: Icon(leadIcon, color: AppTheme.purple)),
                title: Text(desc,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('$cat • ${dateText(dt)}'),
                trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') {
                        _edit(
                            id: rid,
                            description: desc,
                            amount: amt,
                            date: dt,
                            category: isExpense ? cat : null);
                      } else {
                        _delete(rid, desc);
                      }
                    },
                    itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete'))
                        ]),
                isThreeLine: false,
                dense: false,
              ));
            })
    ]);
  }
}
