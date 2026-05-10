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

  @override
  Widget build(BuildContext context) {
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
            ]),
            Text('$value',
                style: TextStyle(
                    color: color,
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
            color: color,
            minHeight: 13,
          ),
        ),
      ],
    );
  }
}
