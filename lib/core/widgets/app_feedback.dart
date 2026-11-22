import 'package:material_ui/material_ui.dart';

import '../api/api_failure.dart';
import '../app_theme.dart';

/// Turns anything thrown into one line a rep can act on.
///
/// The server already writes its failures for people and marks them with a
/// stable reason, so for an [ApiFailure] this is mostly a pass-through —
/// the value is in catching everything else too, so no screen ever shows a
/// raw exception.
String describeError(Object error) => switch (error) {
      ApiFailure failure => failure.message,
      _ => 'Something went wrong. Please try again.',
    };

/// Standard "it did not load" panel with a retry.
class ErrorPanel extends StatelessWidget {
  const ErrorPanel({required this.error, this.onRetry, super.key});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 44, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(
              describeError(error),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standard "there is nothing here yet" panel.
class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    required this.icon,
    required this.title,
    this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows a message to the rep. Used for both outcomes, so the call site
/// reads the same whether it worked or not.
void showNotice(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.danger : AppTheme.success,
      ),
    );
}
