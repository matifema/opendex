import 'package:flutter/material.dart';

class ControlPanel extends StatelessWidget {
  final VoidCallback onCapturePressed;
  final VoidCallback onDPadUp;
  final VoidCallback onDPadDown;
  final VoidCallback onDPadLeft;
  final VoidCallback onDPadRight;
  final VoidCallback onAPressed;

  const ControlPanel({
    super.key,
    required this.onCapturePressed,
    required this.onDPadUp,
    required this.onDPadDown,
    required this.onDPadLeft,
    required this.onDPadRight,
    required this.onAPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDC0A2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // D-pad on left
          _buildDPad(),
          // Red capture button in center
          _buildCaptureButton(),
          // A button on right
          _buildAButton(),
        ],
      ),
    );
  }

  Widget _buildDPad() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          // Up
          Positioned(
            top: 0,
            left: 40,
            child: _buildDPadButton(Icons.arrow_drop_up, onDPadUp),
          ),
          // Down
          Positioned(
            bottom: 0,
            left: 40,
            child: _buildDPadButton(Icons.arrow_drop_down, onDPadDown),
          ),
          // Left
          Positioned(
            left: 0,
            top: 40,
            child: _buildDPadButton(Icons.arrow_left, onDPadLeft),
          ),
          // Right
          Positioned(
            right: 0,
            top: 40,
            child: _buildDPadButton(Icons.arrow_right, onDPadRight),
          ),
          // Center
          Positioned(
            left: 40,
            top: 40,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDPadButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Icon(icon, color: Colors.white70, size: 28),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: onCapturePressed,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.shade700,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.catching_pokemon,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildAButton() {
    return GestureDetector(
      onTap: onAPressed,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black87,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.info_outline,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
