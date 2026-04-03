import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/user_provider.dart';
import '../../providers/bookmarks_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/freelancer_card.dart';
import '../profile/profile_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBookmarks());
  }

  Future<void> _loadBookmarks() async {
    final userProvider = context.read<UserProvider>();
    final bookmarksProvider = context.read<BookmarksProvider>();
    final bookmarkIds = userProvider.user?.bookmarks ?? [];
    await bookmarksProvider.loadBookmarks(bookmarkIds);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<app_auth.AuthProvider>();
    final bookmarksProvider = context.watch<BookmarksProvider>();
    final currentUserId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: bookmarksProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookmarksProvider.bookmarkedFreelancers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.bookmark_outline,
                        size: 64,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No bookmarks yet',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bookmark freelancers to find them quickly later.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount:
                      bookmarksProvider.bookmarkedFreelancers.length,
                  itemBuilder: (_, i) {
                    final user =
                        bookmarksProvider.bookmarkedFreelancers[i];
                    return FreelancerCard(
                      user: user,
                      isBookmarked: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProfileScreen(userId: user.uid),
                        ),
                      ),
                      onBookmark: () =>
                          bookmarksProvider.toggleBookmark(
                              currentUserId, user.uid),
                    );
                  },
                ),
    );
  }
}
