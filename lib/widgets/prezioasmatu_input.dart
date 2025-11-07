import 'package:flutter/material.dart';

class PrezioaInput extends StatefulWidget {
  final void Function(double) onSubmit;
  const PrezioaInput({super.key, required this.onSubmit});

  @override
  State<PrezioaInput> createState() => _PrezioaInputState();
}

class _PrezioaInputState extends State<PrezioaInput> {
  final _ctrl = TextEditingController();

  void _bidali() {
    final testua = _ctrl.text.replaceAll(',', '.').trim();
    final prezioa = double.tryParse(testua);
    if (prezioa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jarri balio egoki bat (€)')),
      );
      return;
    }
    widget.onSubmit(prezioa);
    _ctrl.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zure erantzuna:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sartu prezioa (€)',
                      prefixText: '€ ',
                      border: OutlineInputBorder(),
                      suffixText: 'EUR',
                    ),
                    onSubmitted: (_) => _bidali(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _bidali,
                  icon: const Icon(Icons.check),
                  label: const Text('Bidali'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Idatzi prezioa eurotan (adb: 12.50)',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}