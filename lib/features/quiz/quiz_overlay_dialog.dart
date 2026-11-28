import 'package:flutter/material.dart';
import 'package:jump_and_learn/core/models/app_models.dart';

class QuizOverlayDialog extends StatefulWidget {
  final List<QuestionModel> questions;
  final bool isPenaltyReanswer;
  final VoidCallback onQuizCompleted;
  final VoidCallback? onReviveFailed;

  const QuizOverlayDialog({
    super.key,
    required this.questions,
    this.isPenaltyReanswer = false,
    required this.onQuizCompleted,
    this.onReviveFailed,
  });

  @override
  State<QuizOverlayDialog> createState() => _QuizOverlayDialogState();
}

class _QuizOverlayDialogState extends State<QuizOverlayDialog> {
  int _currentIndex = 0;
  int? _selectedIndex;
  bool _hasSubmitted = false;
  bool _isCorrect = false;

  QuestionModel get _currentQuestion => widget.questions[_currentIndex];
  bool get _isLastQuestion => _currentIndex >= widget.questions.length - 1;

  void _onSelectOption(int index) {
    if (_hasSubmitted) return;

    setState(() {
      _selectedIndex = index;
      _hasSubmitted = true;
      _isCorrect = index == _currentQuestion.correctIndex;
    });
  }

  void _onActionPressed() {
    if (widget.isPenaltyReanswer) {
      if (_isCorrect) {
        widget.onQuizCompleted();
      } else {
        widget.onReviveFailed?.call();
      }
      return;
    }

    if (!_isLastQuestion) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _hasSubmitted = false;
        _isCorrect = false;
      });
    } else {
      widget.onQuizCompleted();
    }
  }

  String _getButtonText() {
    if (widget.isPenaltyReanswer) {
      return _isCorrect ? 'Revive & Continue' : 'Restart from Beginning';
    }
    return _isLastQuestion
        ? 'Complete Quiz & Continue'
        : 'Next Question (${_currentIndex + 2}/${widget.questions.length})';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.black54,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            margin: const EdgeInsets.all(20),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.isPenaltyReanswer)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Fall Revive Challenge! Answer correctly to revive, or restart from the beginning.',
                                style: TextStyle(
                                  color: Colors.red.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Checkpoint Quiz',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Chip(
                              label: Text(
                                'Question ${_currentIndex + 1} / ${widget.questions.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      _currentQuestion.prompt,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_currentQuestion.options.length, (index) {
                      final optionText = _currentQuestion.options[index];
                      final isSelected = _selectedIndex == index;
                      final isCorrectOption =
                          index == _currentQuestion.correctIndex;

                      Color? bgColor;
                      Color borderColor = Colors.grey.shade300;
                      if (_hasSubmitted) {
                        if (isCorrectOption) {
                          bgColor = Colors.green.shade50;
                          borderColor = Colors.green;
                        } else if (isSelected && !_isCorrect) {
                          bgColor = Colors.red.shade50;
                          borderColor = Colors.red;
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: OutlinedButton(
                          onPressed: () => _onSelectOption(index),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: bgColor,
                            side: BorderSide(color: borderColor, width: 1.5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            alignment: Alignment.centerLeft,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            '${String.fromCharCode(65 + index)}. $optionText',
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                      );
                    }),
                    if (_hasSubmitted) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isCorrect
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isCorrect
                                  ? 'Correct!'
                                  : widget.isPenaltyReanswer
                                      ? 'Revive failed! Returning to the starting platform.'
                                      : 'Incorrect!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isCorrect
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                              ),
                            ),
                            if (_currentQuestion.explanation.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(_currentQuestion.explanation),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _onActionPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              (widget.isPenaltyReanswer && !_isCorrect)
                                  ? Colors.red.shade600
                                  : null,
                          foregroundColor:
                              (widget.isPenaltyReanswer && !_isCorrect)
                                  ? Colors.white
                                  : null,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(_getButtonText()),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}