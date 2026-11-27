
import 'package:flutter/material.dart';

class DifficultySheet extends StatelessWidget {
  final String selectedDifficulty;
  final ValueChanged<String> onDifficultyChanged;

  const DifficultySheet({
    super.key,
    required this.selectedDifficulty,
    required this.onDifficultyChanged,
  });

  static const Color pink = Color(0xFFF06292);

  @override
  Widget build(BuildContext context) {
    const difficulties = [
      {
        'value': 'easy',
        'title': 'Easy',
        'description': 'A relaxed start to test your knowledge.',
        'icon': Icons.sentiment_satisfied_alt,
        'color': Color(0xFF4CAF50),
      },
      {
        'value': 'medium',
        'title': 'Medium',
        'description': 'A balanced challenge for your skills.',
        'icon': Icons.local_fire_department,
        'color': Color(0xFFFF9800),
      },
      {
        'value': 'hard',
        'title': 'Hard',
        'description': 'A tougher challenge for confident players.',
        'icon': Icons.bolt,
        'color': Color(0xFFE53935),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose your difficulty',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...difficulties.map((difficulty) {
          final value = difficulty['value'] as String;
          final title = difficulty['title'] as String;
          final description = difficulty['description'] as String;
          final icon = difficulty['icon'] as IconData;
          final color = difficulty['color'] as Color;
          final isSelected = selectedDifficulty == value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onDifficultyChanged(value),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFCE4EC)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? pink : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected ? pink : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
