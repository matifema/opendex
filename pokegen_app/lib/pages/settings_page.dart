import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  final SettingsService settings;

  const SettingsPage({super.key, required this.settings});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _geminiKeyController;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _geminiKeyController = TextEditingController(text: widget.settings.geminiApiKey);
  }

  @override
  void dispose() {
    _geminiKeyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.settings.setGeminiApiKey(_geminiKeyController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
      Navigator.of(context).pop(true); // Return true to indicate changes
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDC0A2D), // Pokedex Red
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFFDC0A2D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF98CB98), // GameBoy Greenish / LCD
          borderRadius: BorderRadius.circular(8),
          border: Border.all(width: 4, color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Gemini API Key',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your Gemini API key. All AI generation runs directly on your device.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _geminiKeyController,
                decoration: InputDecoration(
                  labelText: 'Gemini API Key',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white70,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                ),
                obscureText: _obscureKey,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Settings'),
                style: FilledButton.styleFrom(
                  shape: const BeveledRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
