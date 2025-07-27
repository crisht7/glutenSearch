import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class LoadingSpinner extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingSpinner({super.key, this.message, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(
            color: AppTheme.primaryGreen,
            strokeWidth: 3,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class LoadingSpinnerOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;

  const LoadingSpinnerOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: LoadingSpinner(message: loadingMessage),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
