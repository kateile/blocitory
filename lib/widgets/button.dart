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
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final primary = Theme.of(context).primaryColor == Colors.white
    //     ? Theme.of(context).primaryColor
    //     : Theme.of(context).primaryColor;

    return Padding(
      padding: padding ?? const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              // style: ButtonStyle(
              //   backgroundColor:
              //       MaterialStateProperty.all<Color>(color ?? primary),
              // ),
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
