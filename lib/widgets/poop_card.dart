import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/poop_model.dart';
import '../pages/poops/edit_poop_page.dart';
import '../theme/app_theme.dart';

class PoopCard extends StatelessWidget {
  final PoopModel poop;
  final User user;

  const PoopCard({Key? key, required this.poop, required this.user})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                        poop.userDisplayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat.yMMMd().format(poop.timestamp),
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
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
                    ])),
                Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        DateFormat.Hm().format(poop.timestamp),
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (poop.userDisplayName == user.displayName)
                        FloatingActionButton(
                          backgroundColor: AppTheme.primaryColor,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      EditPoopPage(poop: poop)),
                            );
                          },
                          child: const Icon(Icons.edit),
                        )
                    ])
              ],
            )));
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
