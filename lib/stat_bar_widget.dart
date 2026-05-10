import 'package:flutter/material.dart';

class StatBar extends StatelessWidget {
  final String emoji;
  final String label;
  final int value;
  final Color color;

  const StatBar({
    super.key,
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  Color get _barColor {
    if (value < 15) return Colors.red[400]!;
    if (value < 30) return Colors.orange[400]!;
    return color;
  }

  @override
  Widget build(BuildContext context) {
    final barColor = _barColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFCC3366),
                      fontSize: 14)),
              if (value < 15) ...[
                const SizedBox(width: 6),
                const Text('위험!',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.bold)),
              ] else if (value < 30) ...[
                const SizedBox(width: 6),
                const Text('부족',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold)),
              ],
            ]),
            Text('$value',
                style: TextStyle(
                    color: barColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value / 100.0,
            backgroundColor: Colors.grey[200],
            color: barColor,
            minHeight: 13,
          ),
        ),
      ],
    );
  }
}
