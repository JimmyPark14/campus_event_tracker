import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../models/user_profile.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceBright,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .orderBy('points', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final students = docs.map((doc) => UserProfile.fromFirestore(doc)).toList();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220.0,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Campus Leaderboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -40,
                          top: -20,
                          child: Icon(
                            Icons.emoji_events,
                            size: 220,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        Positioned(
                          left: -20,
                          bottom: -20,
                          child: Icon(
                            Icons.workspace_premium,
                            size: 150,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (students.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.leaderboard_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          'No students found yet!',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildLeaderboardCard(context, students[index], index + 1);
                      },
                      childCount: students.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardCard(BuildContext context, UserProfile user, int rank) {
    bool isTop3 = rank <= 3;
    
    List<Color> gradientColors;
    Color textColor;
    IconData? rankIcon;

    if (rank == 1) {
      gradientColors = [const Color(0xFFFFD700), const Color(0xFFFDB931)]; // Gold
      textColor = Colors.black87;
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      gradientColors = [const Color(0xFFE0E0E0), const Color(0xFFBDBDBD)]; // Silver
      textColor = Colors.black87;
      rankIcon = Icons.workspace_premium;
    } else if (rank == 3) {
      gradientColors = [const Color(0xFFCD7F32), const Color(0xFFA0522D)]; // Bronze
      textColor = Colors.white;
      rankIcon = Icons.workspace_premium;
    } else {
      gradientColors = [Theme.of(context).colorScheme.surfaceContainerLowest, Theme.of(context).colorScheme.surfaceContainerLowest];
      textColor = Theme.of(context).colorScheme.onSurface;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isTop3 ? gradientColors[0].withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.05),
            blurRadius: isTop3 ? 12 : 6,
            offset: Offset(0, isTop3 ? 6 : 2),
          ),
        ],
        border: isTop3 ? null : Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isTop3 ? Colors.white.withValues(alpha: 0.25) : Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isTop3 && rankIcon != null
                ? Icon(rankIcon, color: rank == 1 ? Colors.white : (rank == 2 ? Colors.black54 : Colors.white), size: 28)
                : Text(
                    '#$rank',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
          ),
        ),
        title: Text(
          user.name.isEmpty ? 'Student' : user.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          user.major.isNotEmpty ? user.major : 'No major specified',
          style: TextStyle(
            color: isTop3 ? textColor.withValues(alpha: 0.8) : Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${user.points}',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            Text(
              'PTS',
              style: TextStyle(
                color: isTop3 ? textColor.withValues(alpha: 0.8) : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
