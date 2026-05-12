import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_connect/app/theme/app_colors.dart';
import 'package:campus_connect/features/explore/explore_screen.dart';
import 'package:campus_connect/features/gigs/gig_listing_screen.dart';
import 'package:campus_connect/features/chat/chat_list_screen.dart';
import 'package:campus_connect/features/dashboard/dashboard_screen.dart';
import 'package:campus_connect/features/profile/profile_screen.dart';
import 'package:campus_connect/core/services/auth_service.dart';

final _selectedIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(_selectedIndexProvider);
    final uid = ref.watch(authServiceProvider).currentUserId ?? '';

    final screens = [
      const ExploreScreen(),
      const GigListingScreen(),
      const ChatListScreen(),
      const DashboardScreen(),
      ProfileScreen(userId: uid),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      floatingActionButton: selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/home/create-gig'),
              icon: const Icon(Icons.add),
              label: const Text('Post Gig',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) =>
            ref.read(_selectedIndexProvider.notifier).state = index,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Gigs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
