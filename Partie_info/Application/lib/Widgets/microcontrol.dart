import 'package:flutter/material.dart';

class MicroControlView extends StatefulWidget {
  final bool isStreaming;
  final String statusLogs;
  final VoidCallback onToggleStreaming;
  final Function(double) onVolumeChanged; // Pour envoyer la valeur à l'ESP32

  const MicroControlView({
    super.key,
    required this.isStreaming,
    required this.statusLogs,
    required this.onToggleStreaming,
    required this.onVolumeChanged,
  });

  @override
  State<MicroControlView> createState() => _MicroControlViewState();
}

class _MicroControlViewState extends State<MicroControlView> {
  // La variable est maintenant LOCALE à cette classe
  double _localMicVolume = 50.0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(widget.statusLogs, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          ),

          const SizedBox(height: 10),
          const Text("Volume Micro", style: TextStyle(fontWeight: FontWeight.bold)),

          // Jauge locale
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(children: [const Icon(Icons.mic_none, size: 20), Text("${_localMicVolume.round()}%")]),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: widget.onToggleStreaming,
            icon: Icon(widget.isStreaming ? Icons.stop : Icons.mic, size: 30),
            label: Text(widget.isStreaming ? "STOP" : "PARLER"),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isStreaming ? Colors.red : Colors.deepPurple,
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
