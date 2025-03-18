import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/database.dart';
import '../../models/user_model.dart';
import '../../widgets/user_ranking_tile.dart';
import '../../theme/app_theme.dart';

class RankingsPage extends StatefulWidget {
  static const String routeName = '/rankings';

  RankingsPage({Key? key}) : super(key: key);

  @override
  _RankingsPageState createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage> {
  RankingType _rankingType = RankingType.today;

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);
    final today = DateTime.now();
    final dateFormat = DateFormat.yMMMMd();

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getRankingTitle(_rankingType),
                      style:
                      Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'For ${dateFormat.format(today)}',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: () => _showRankingTypeOverlay(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<UserModel, int>>>(
              stream: databaseService.getTopUsers(rankingType: _rankingType),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                  );
                }

                final users = snapshot.data ?? [];

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.leaderboard_outlined,
                          size: 72,
                          color: AppTheme.textSecondaryColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No shit!',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Become the first shitter!',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    return UserRankingTile(
                      user: users[index].keys.first,
                      count: users[index].values.first,
                      rank: index + 1,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRankingTypeOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: RankingType.values.map((rankingType) {
              return ListTile(
                title: Text(getRankingTitle(rankingType)),
                onTap: () {
                  Navigator.pop(context);
                  _updateRankingType(rankingType);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _updateRankingType(RankingType rankingType) {
    setState(() {
      _rankingType = rankingType;
    });
  }
}

String getRankingTitle(RankingType rankingType) {
  switch (rankingType) {
    case RankingType.today:
      return 'Today\'s Top Shitters';
    case RankingType.week:
      return 'This Week\'s Top Shitters';
    case RankingType.month:
      return 'This Month\'s Top Shitters';
    case RankingType.allTime:
      return 'All Time Top Shitters';
  }

}

