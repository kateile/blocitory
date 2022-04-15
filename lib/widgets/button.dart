import 'package:flutter/material.dart';

/// Reusable button.
///
class Button extends StatelessWidget {
  final VoidCallback? callback;
  final String title;
  final MaterialColor? color;
  final EdgeInsetsGeometry? padding;

  const Button({
    Key? key,
    required this.callback,
    required this.title,
    this.color,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              // color: color ?? Theme.of(context).primaryColor == Colors.white
              //     ? Theme.of(context).primaryColor
              //     : Theme.of(context).primaryColor,
              //textColor: Colors.white,
              onPressed: callback,
              child: Text(
                title,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
