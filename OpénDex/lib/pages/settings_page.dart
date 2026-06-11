import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/settings_service.dart';

const _kPokedexRed = Color(0xFFDC0A2D);
const _kPokedexDarkRed = Color(0xFFB80828);
const _kLcdGreen = Color(0xFF98CB98);
const _kLcdDarkGreen = Color(0xFF78A878);
const _kPanelBorder = Color(0xFF5A6E5A);
const _kLcdTextDark = Color(0xFF2A3A2A);

class SettingsPage extends StatefulWidget {
  final SettingsService settings;

  const SettingsPage({super.key, required this.settings});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _geminiKeyController;
  bool _obscureKey = true;
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _geminiKeyController = TextEditingController(
      text: widget.settings.geminiApiKey,
    );
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _geminiKeyController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.settings.setGeminiApiKey(_geminiKeyController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _kLcdDarkGreen,
          content: Text(
            'Settings saved!',
            style: GoogleFonts.vt323(
              fontSize: 18,
              color: _kLcdTextDark,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: _kPanelBorder, width: 2),
          ),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPokedexRed,
      appBar: AppBar(
        title: Text(
          'SETTINGS',
          style: GoogleFonts.vt323(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(1, 2),
              ),
            ],
          ),
        ),
        backgroundColor: _kPokedexRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            color: _kPokedexDarkRed,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - _animController.value) * 20),
          child: Opacity(
            opacity: _animController.value,
            child: child,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main LCD Panel
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kLcdGreen, Color(0xFF88B888)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(width: 4, color: _kPanelBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Column(
                    children: [
                      // Header bar
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _kLcdDarkGreen,
                          border: Border(
                            bottom: BorderSide(
                              color: _kPanelBorder.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _kPokedexRed,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _kPanelBorder,
                                  width: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'SYSTEM CONFIGURATION',
                              style: GoogleFonts.vt323(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _kLcdTextDark,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              icon: Icons.vpn_key,
                              label: 'API CONFIGURATION',
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _kLcdDarkGreen.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _kPanelBorder.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Enter your Gemini API key below. All AI generation runs directly on your device - no data is sent to external servers.',
                                style: GoogleFonts.vt323(
                                  fontSize: 16,
                                  color: _kLcdTextDark.withValues(alpha: 0.8),
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(),
                            const SizedBox(height: 24),
                            _buildSaveButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Info panel
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF333333),
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF33FF33),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SYSTEM STATUS: OPERATIONAL',
                        style: GoogleFonts.vt323(
                          fontSize: 14,
                          color: const Color(0xFF33FF33),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: _kLcdTextDark,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.vt323(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _kLcdTextDark,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _geminiKeyController,
        style: GoogleFonts.vt323(
          fontSize: 18,
          color: _kLcdTextDark,
          letterSpacing: 0.5,
        ),
        decoration: InputDecoration(
          labelText: 'GEMINI API KEY',
          labelStyle: GoogleFonts.vt323(
            fontSize: 16,
            color: _kLcdTextDark.withValues(alpha: 0.7),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: _kPanelBorder, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: _kPanelBorder.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: _kPokedexRed, width: 2.5),
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.8),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureKey ? Icons.visibility : Icons.visibility_off,
              color: _kLcdTextDark,
              size: 20,
            ),
            onPressed: () => setState(() => _obscureKey = !_obscureKey),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
        obscureText: _obscureKey,
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _save,
      icon: const Icon(Icons.save, size: 22),
      label: Text(
        'SAVE SETTINGS',
        style: GoogleFonts.vt323(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _kPokedexRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: _kPokedexDarkRed, width: 2),
        ),
      ),
    );
  }
}
