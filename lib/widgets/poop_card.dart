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
                const SizedBox(width: 8),
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
              Container(
                width: MediaQuery.sizeOf(context).width * 0.8,
                child: Text(
                  poop.description,
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor,
                  ),
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
            //SizedBox(width: MediaQuery.sizeOf(context).width * 0.4),
            if (poop.url.isNotEmpty)
              GestureDetector(
                onTap: () => _showImageDialog(context, poop.url),
                child: Image.network(
                  poop.url,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }
}
