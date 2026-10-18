import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/first_aid_bloc.dart';

/// Symptom text input with mic button for Speech-to-Text
class SymptomInputWidget extends StatefulWidget {
  const SymptomInputWidget({super.key});

  @override
  State<SymptomInputWidget> createState() => _SymptomInputWidgetState();
}

class _SymptomInputWidgetState extends State<SymptomInputWidget> {
  final _controller = TextEditingController();
  bool _isListening = false;

  void _onSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<FirstAidBloc>().add(
      PredictFromSymptomsEvent(symptomText: text),
    );
  }

  void _toggleSpeech() {
    // TODO: Implement Speech-to-Text via speech_to_text package
    setState(() => _isListening = !_isListening);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mô tả triệu chứng',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: bị rắn cắn vào chân, sưng đỏ...',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isListening
                            ? Icons.mic_rounded
                            : Icons.mic_none_rounded,
                        color: _isListening
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                      onPressed: _toggleSpeech,
                    ),
                  ),
                  onSubmitted: (_) => _onSubmit(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _onSubmit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 20,
                  ),
                ),
                child: const Icon(Icons.search_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
