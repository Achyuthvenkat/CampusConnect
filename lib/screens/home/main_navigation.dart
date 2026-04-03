import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/user_provider.dart';
import '../../providers/jobs_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/bookmarks_provider.dart';
import '../../services/notification_service.dart';
import '../home/home_screen.dart';
import '../jobs/jobs_list_screen.dart';
import '../chat/chat_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../../utils/theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    JobsListScreen(),
    ChatListScreen(),
    DashboardScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initProviders();
  }

  Future<void> _initProviders() async {
    final authProvider =
        context.read<app_auth.AuthProvider>();
    final uid = authProvider.currentUser?.uid;
    if (uid == null) return;

    final userProvider = context.read<UserProvider>();
    final jobsProvider = context.read<JobsProvider>();
    final chatProvider = context.read<ChatProvider>();
    final bookmarksProvider = context.read<BookmarksProvider>();

    await userProvider.loadUser(uid);
    userProvider.listenToUser(uid);
    userProvider.loadReviews(uid);

    jobsProvider.listenToJobs();
    jobsProvider.listenToUserJobs(uid);

    chatProvider.listenToChatRooms(uid);

    final user = userProvider.user;
    if (user != null && user.bookmarks.isNotEmpty) {
      await bookmarksProvider.loadBookmarks(user.bookmarks);
    }

    await NotificationService().initialize(uid);
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final authProvider = context.read<app_auth.AuthProvider>();
    final unread = chatProvider.getTotalUnreadCount(
        authProvider.currentUser?.uid ?? '');

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primaryColor.withOpacity(0.15),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.chat_bubble),
            ),
            label: 'Chat',
          ),
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
