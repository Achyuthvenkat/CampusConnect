import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_connect/core/services/auth_service.dart';
import 'package:campus_connect/core/services/firestore_service.dart';
import 'package:campus_connect/features/auth/login_screen.dart';
import 'package:campus_connect/features/auth/signup_screen.dart';
import 'package:campus_connect/features/onboarding/profile_setup_screen.dart';
import 'package:campus_connect/features/home/home_screen.dart';
import 'package:campus_connect/features/gigs/gig_detail_screen.dart';
import 'package:campus_connect/features/gigs/create_gig_screen.dart';
import 'package:campus_connect/features/profile/profile_screen.dart';
import 'package:campus_connect/features/profile/edit_profile_screen.dart';
import 'package:campus_connect/features/chat/chat_list_screen.dart';
import 'package:campus_connect/features/chat/chat_room_screen.dart';
import 'package:campus_connect/features/bookmarks/bookmarks_screen.dart';
import 'package:campus_connect/features/splash/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      final isSplashRoute = state.matchedLocation == '/splash';

      // Allow splash screen to display without intervention
      if (isSplashRoute) return null;

      if (!isLoggedIn && !isAuthRoute) return '/login';

      if (isLoggedIn && isAuthRoute) {
        try {
          final exists = await ref
              .read(firestoreServiceProvider)
              .userExists(user.uid);
          if (!exists) return '/profile-setup';
        } catch (_) {}
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'gig/:gigId',
            name: 'gig-detail',
            builder: (context, state) => GigDetailScreen(
              gigId: state.pathParameters['gigId']!,
            ),
          ),
          GoRoute(
            path: 'create-gig',
            name: 'create-gig',
            builder: (context, state) => const CreateGigScreen(),
          ),
          GoRoute(
            path: 'profile/:userId',
            name: 'user-profile',
            builder: (context, state) => ProfileScreen(
              userId: state.pathParameters['userId']!,
            ),
          ),
          GoRoute(
            path: 'edit-profile',
            name: 'edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: 'chat/:chatId/:recipientId/:recipientName',
            name: 'chat-room',
            builder: (context, state) => ChatRoomScreen(
              chatId: state.pathParameters['chatId']!,
              recipientId: state.pathParameters['recipientId']!,
              recipientName: Uri.decodeComponent(
                  state.pathParameters['recipientName']!),
              recipientAvatarUrl:
                  state.uri.queryParameters['avatar'],
            ),
          ),
          GoRoute(
            path: 'bookmarks',
            name: 'bookmarks',
            builder: (context, state) => const BookmarksScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: Color(0xFFEF5350)),
            const SizedBox(height: 16),
            Text('Page not found',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
