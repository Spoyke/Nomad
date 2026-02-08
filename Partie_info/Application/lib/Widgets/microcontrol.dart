import 'package:flutter/material.dart';

class MicroControlView extends StatelessWidget {
  final bool isStreaming;
  final String statusLogs;
  final VoidCallback onToggleStreaming; // Utilise VoidCallback pour les fonctions sans argument

  const MicroControlView({
    super.key,
    required this.isStreaming,
    required this.statusLogs,
    required this.onToggleStreaming,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(statusLogs, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onToggleStreaming,
            icon: Icon(isStreaming ? Icons.stop : Icons.mic, size: 30),
            label: Text(isStreaming ? "STOP" : "PARLER"),
            style: ElevatedButton.styleFrom(
              backgroundColor: isStreaming ? Colors.red : Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }
}
