import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifin/features/ai_insights/providers/ai_provider.dart';
import 'package:aifin/core/constants/app_constants.dart';

class AiInsightsScreen extends ConsumerWidget {
  const AiInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiInsights = ref.watch(aiInsightsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('AI Financial Advisor', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryGradientStart),
            onPressed: () => ref.refresh(aiInsightsProvider),
          ),
        ],
      ),
      body: aiInsights.when(
        data: (advice) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium AI Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF5E35B1).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 10)),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Your Personal AI Advisor',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'AI is analyzing your patterns...',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Financial Recommendations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              
              // Advice Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: SelectableText(
                  advice,
                  style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primaryGradientStart),
              SizedBox(height: 16),
              Text('Consulting with AI Advisor...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('AI is unavailable right now. Try checking your API key!\n\nDetails: $err', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
