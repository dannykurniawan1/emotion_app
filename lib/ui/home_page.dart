import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/Home.png', fit: BoxFit.cover),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40), 
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFixedButton(
                    label: 'Take Photo',
                    onTap: () => Navigator.pushNamed(context, '/photo'),
                  ),
                  const SizedBox(height: 16),
                  _buildFixedButton(
                    label: 'Real‑Time Detection',
                    onTap: () => Navigator.pushNamed(context, '/realtime'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFixedButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 260, 
      height: 60, 
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4C6FBF), 
          foregroundColor: Colors.white, 
          textStyle: const TextStyle(fontSize: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
