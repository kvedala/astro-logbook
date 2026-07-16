import 'package:flutter/material.dart';

class AsyncWidget<T> extends StatelessWidget {
  const AsyncWidget({
    super.key,
    required this.future,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loadingWidget;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error!) ??
              Center(child: Text('Error: [${snapshot.error}]'));
        }
        if (snapshot.data == null) {
          return const Center(child: Text('No data available'));
        }
        return builder(context, snapshot.data as T);
      },
    );
  }
}
