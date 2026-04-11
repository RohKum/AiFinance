import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  Future<bool> initialize() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return false;
    
    return await _speech.initialize(
      onError: (val) => print('Speech Error: $val'),
      onStatus: (val) => print('Speech Status: $val'),
    );
  }

  Future<void> startListening(Function(String) onResult) async {
    await _speech.listen(
      onResult: (val) => onResult(val.recognizedWords),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}

final speechServiceProvider = Provider((ref) => SpeechService());
