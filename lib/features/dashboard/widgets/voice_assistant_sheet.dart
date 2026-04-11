import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:aifin/core/constants/app_constants.dart';
import 'package:aifin/core/providers/transaction_provider.dart';
import 'package:aifin/core/services/speech_service.dart';
import 'package:aifin/features/ai_insights/providers/ai_provider.dart';
import 'package:aifin/data/models/transaction_model.dart';

class VoiceAssistantSheet extends ConsumerStatefulWidget {
  const VoiceAssistantSheet({super.key});

  @override
  ConsumerState<VoiceAssistantSheet> createState() => _VoiceAssistantSheetState();
}

class _VoiceAssistantSheetState extends ConsumerState<VoiceAssistantSheet> {
  String _text = 'How can I help you today?';
  bool _isListening = false;
  bool _isParsing = false;

  void _listen() async {
    final speech = ref.read(speechServiceProvider);
    
    if (!_isListening) {
      bool available = await speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        await speech.startListening((val) {
          setState(() {
            _text = val;
            if (val.isEmpty) _text = 'Listening...';
          });
        });
      }
    } else {
      setState(() {
        _isListening = false;
        _isParsing = true;
      });
      await speech.stopListening();
      _parseVoiceInput(_text);
    }
  }

  void _parseVoiceInput(String transcribedText) async {
    if (transcribedText.isEmpty || transcribedText == 'Listening...') {
      setState(() {
        _isParsing = false;
        _text = 'No input detected. Try again!';
      });
      return;
    }

    final aiService = ref.read(aiServiceProvider);
    final result = await aiService.parseTransactionFromVoice(transcribedText);

    if (result != null) {
      final transaction = TransactionModel(
        id: const Uuid().v4(),
        title: result['title'] ?? 'Voice Transaction',
        amount: (result['amount'] as num).toDouble(),
        category: result['category'] ?? 'Other',
        date: DateTime.now(),
        type: (result['type'] == 'income') ? TransactionType.income : TransactionType.expense,
      );

      // Add to database
      await ref.read(transactionProvider.notifier).addTransaction(transaction);
      
      if (mounted) {
        setState(() {
          _isParsing = false;
          _text = 'Perfect! Saved "${transaction.title}" for ${AppConstants.currencySymbol}${transaction.amount}.';
        });
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } else {
       setState(() {
          _isParsing = false;
          _text = "I couldn't quite catch the details. Can you try again?";
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 32),
          Text(
            _isParsing ? 'Processing...' : (_isListening ? 'Listening...' : 'AI Voice Assistant'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: _isListening ? Colors.deepPurpleAccent : Colors.black87,
                fontStyle: _isListening ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _listen,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isListening ? Colors.redAccent : Colors.deepPurpleAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? Colors.redAccent : Colors.deepPurpleAccent).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: _isParsing 
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 32,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isListening ? 'Tap to Stop' : 'Tap to Start Speaking',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
