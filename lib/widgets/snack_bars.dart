import 'dart:async';

import 'package:flutter/material.dart';

void displaySuccess({
  required BuildContext context,
  required String message,
  int? duration,
}) {
  _displayNotification(
    context: context,
    message: message,
    duration: Duration(seconds: duration ?? 5),
    isError: false,
  );
}

void displayError({
  required BuildContext context,
  required String message,
  VoidCallback? retryCallback,
}) {
  _displayNotification(
    context: context,
    message: message,
    duration: const Duration(seconds: 5),
    isError: true,
    retryCallback: retryCallback,
  );
}

void _displayNotification({
  required BuildContext context,
  required String message,
  required Duration duration,
  required bool isError,
  VoidCallback? retryCallback,
}) {
  final colors = Theme.of(context).colorScheme;
  final background = isError ? colors.errorContainer : const Color(0xFFE8F5E9);
  final foreground = isError
      ? colors.onErrorContainer
      : const Color(0xFF164B2B);
  final availableWidth = MediaQuery.sizeOf(context).width - 32;
  final messenger = ScaffoldMessenger.of(context);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        width: availableWidth.clamp(0.0, 560.0).toDouble(),
        backgroundColor: background,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        persist: false,
        showCloseIcon: true,
        closeIconColor: foreground,
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline,
              color: foreground,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: foreground,
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _NotificationCountdown(duration: duration, color: foreground),
          ],
        ),
        action: retryCallback == null
            ? null
            : SnackBarAction(
                label: 'Retry',
                textColor: foreground,
                onPressed: retryCallback,
              ),
      ),
    );
}

class _NotificationCountdown extends StatefulWidget {
  const _NotificationCountdown({required this.duration, required this.color});

  final Duration duration;
  final Color color;

  @override
  State<_NotificationCountdown> createState() => _NotificationCountdownState();
}

class _NotificationCountdownState extends State<_NotificationCountdown> {
  late final Timer _timer;
  late int _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remaining = (widget.duration.inSeconds - timer.tick).clamp(
          0,
          widget.duration.inSeconds,
        );
      });
      if (_remaining == 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Closes in $_remaining seconds',
      child: ExcludeSemantics(
        child: Text(
          '${_remaining}s',
          style: TextStyle(color: widget.color, fontSize: 12),
        ),
      ),
    );
  }
}
