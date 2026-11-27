
import 'package:flutter/material.dart';

class LobbyTopic {
  final String id;
  final String title;
  final String description;

  const LobbyTopic({
    required this.id,
    required this.title,
    required this.description,
  });
}

class LobbyDiscipline {
  final String name;
  final List<LobbyTopic> topics;

  const LobbyDiscipline({
    required this.name,
    required this.topics,
  });
}

class LobbyCatalog {
  static const List<LobbyDiscipline> disciplines = [
    LobbyDiscipline(
      name: 'Computer Science',
      topics: [
        LobbyTopic(
          id: 'cs_algo_01',
          title: 'Algorithms & Data Structures',
          description: 'Explore algorithms, sorting and data structures.',
        ),
        LobbyTopic(
          id: 'cs_programming_01',
          title: 'Programming Fundamentals',
          description: 'Learn the basics of programming.',
        ),
        LobbyTopic(
          id: 'cs_database_01',
          title: 'Database Systems',
          description: 'Understand databases and SQL.',
        ),
      ],
    ),
    LobbyDiscipline(
      name: 'Business',
      topics: [
        LobbyTopic(
          id: 'business_management_01',
          title: 'Business Management',
          description: 'Learn about managing organisations.',
        ),
        LobbyTopic(
          id: 'business_marketing_01',
          title: 'Marketing',
          description: 'Explore marketing principles and strategies.',
        ),
        LobbyTopic(
          id: 'business_accounting_01',
          title: 'Accounting',
          description: 'Understand basic accounting concepts.',
        ),
      ],
    ),
    LobbyDiscipline(
      name: 'Engineering',
      topics: [
        LobbyTopic(
          id: 'engineering_electrical_01',
          title: 'Electrical Engineering',
          description: 'Explore electrical systems and circuits.',
        ),
        LobbyTopic(
          id: 'engineering_mechanical_01',
          title: 'Mechanical Engineering',
          description: 'Learn about mechanics and machines.',
        ),
      ],
    ),
    LobbyDiscipline(
      name: 'Mathematics',
      topics: [
        LobbyTopic(
          id: 'math_algebra_01',
          title: 'Algebra',
          description: 'Practise equations and algebraic expressions.',
        ),
        LobbyTopic(
          id: 'math_calculus_01',
          title: 'Calculus',
          description: 'Explore limits, derivatives and integrals.',
        ),
      ],
    ),
  ];
}

class SubjectSelector extends StatelessWidget {
  final String selectedDiscipline;
  final String selectedTopicId;
  final ValueChanged<String> onDisciplineChanged;
  final ValueChanged<String> onTopicChanged;

  const SubjectSelector({
    super.key,
    required this.selectedDiscipline,
    required this.selectedTopicId,
    required this.onDisciplineChanged,
    required this.onTopicChanged,
  });

  @override
  Widget build(BuildContext context) {
    final discipline = LobbyCatalog.disciplines.firstWhere(
      (item) => item.name == selectedDiscipline,
      orElse: () => LobbyCatalog.disciplines.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose your discipline',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: discipline.name,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.school_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: LobbyCatalog.disciplines.map((item) {
            return DropdownMenuItem<String>(
              value: item.name,
              child: Text(item.name),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onDisciplineChanged(value);
            }
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Select a topic',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...discipline.topics.map((topic) {
          final isSelected = topic.id == selectedTopicId;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onTopicChanged(topic.id),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFCE4EC)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFF06292)
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected
                          ? const Color(0xFFF06292)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            topic.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
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
        }),
      ],
    );
  }
}
