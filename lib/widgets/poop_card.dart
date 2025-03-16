import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/poop_model.dart';
import '../theme/app_theme.dart';

class PoopCard extends StatelessWidget {
  final PoopModel poop;

  const PoopCard({Key? key, required this.poop}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  poop.userDisplayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  DateFormat.Hm().format(poop.timestamp),
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (poop.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                poop.description,
                style: TextStyle(
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              DateFormat.yMMMd().format(poop.timestamp),
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}