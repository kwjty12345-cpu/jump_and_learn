import 'package:flutter/material.dart';

class DevPlaceholderScreen extends StatelessWidget {
  final String ownerLabel;
  final String screenName;
  final String? details;
  final String nextButtonText;
  final VoidCallback onSimulateNext;
  final VoidCallback? onSecondaryAction;
  final String? secondaryButtonText;

  const DevPlaceholderScreen({
    super.key,
    required this.ownerLabel,
    required this.screenName,
    required this.nextButtonText,
    required this.onSimulateNext,
    this.details,
    this.onSecondaryAction,
    this.secondaryButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('$screenName · $ownerLabel')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.layers_outlined,
                  size: 64,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '等待 $ownerLabel 交付\n$screenName',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                if (details != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      details!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: onSimulateNext,
                  child: Text(nextButtonText),
                ),
                if (onSecondaryAction != null && secondaryButtonText != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onSecondaryAction,
                    child: Text(secondaryButtonText!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}