import 'package:flutter/material.dart';

import '../../app/app_scope.dart';

class AddMeterDialog extends StatefulWidget {
  const AddMeterDialog({super.key});

  @override
  State<AddMeterDialog> createState() => _AddMeterDialogState();
}

class _AddMeterDialogState extends State<AddMeterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _location = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AppScope.of(context).createMeter(
        name: _name.text,
        meterNumber: _number.text,
        locationLabel: _location.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un compteur'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nom du compteur'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _number,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Numéro du compteur'),
                validator: (value) => value == null || value.trim().length < 4 ? 'Numéro invalide' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _location,
                decoration: const InputDecoration(labelText: 'Localisation (facultatif)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? 'Ajout…' : 'Ajouter')),
      ],
    );
  }
}
