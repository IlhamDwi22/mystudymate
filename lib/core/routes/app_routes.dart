import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/profile/presentation/complete_profile_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../features/workspace/presentation/workspace_screen.dart';
import '../../features/repository/presentation/study_hub_screen.dart';
import '../../features/notes/presentation/notes_list_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../presentation/main_screen.dart';
import '../../features/matchmaking/presentation/study_mate_search_screen.dart';
import '../../features/matchmaking/presentation/study_mate_results_screen.dart';
import '../../features/matchmaking/presentation/friend_requests_screen.dart';

class GoRouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier();

  // Listen to Auth state changes from Riverpod
  ref.listen(authStateProvider, (previous, next) {
    debugPrint('[Router] AuthStateProvider changed: isLoading=${next.isLoading}');
    refreshNotifier.refresh();
  });

  // Listen to Profile state changes to refresh router
  ref.listen(userProfileProvider, (previous, next) {
    debugPrint('[Router] Profile state changed: isLoading=${next.isLoading}, hasError=${next.hasError}, value=${next.value}');
    refreshNotifier.refresh();
  });

  ref.onDispose(() {
    refreshNotifier.dispose();
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final currentLocation = state.matchedLocation;
      final isGoingToAuth = currentLocation == '/login' ||
          currentLocation == '/register';

      // --- Step 1: Check auth state from stream ---
      final authState = ref.read(authStateProvider);

      debugPrint('[Router] REDIRECT called - location: $currentLocation');
      debugPrint('[Router] authState: isLoading=${authState.isLoading}, hasError=${authState.hasError}');

      // If auth state stream is still loading, stay on splash
      if (authState.isLoading) {
        debugPrint('[Router] -> Auth loading, go to /');
        if (currentLocation != '/') return '/';
        return null;
      }

      // If auth state has error, redirect to login
      if (authState.hasError) {
        debugPrint('[Router] -> Auth error, go to /login');
        if (!isGoingToAuth) return '/login';
        return null;
      }

      // Auth state is resolved - check if there's a session
      final session = authState.value?.session;
      final isLoggedIn = session != null;
      debugPrint('[Router] isLoggedIn: $isLoggedIn');

      // --- Step 2: Handle not logged in ---
      if (!isLoggedIn) {
        if (isGoingToAuth) {
          debugPrint('[Router] -> Not logged in, allowing $currentLocation');
          return null;
        }
        debugPrint('[Router] -> Not logged in, redirecting to /login');
        return '/login';
      }

      // --- Step 3: User IS logged in, check profile ---
      final profileState = ref.read(userProfileProvider);
      debugPrint('[Router] profileState: isLoading=${profileState.isLoading}, hasError=${profileState.hasError}, value=${profileState.value}');

      // If profile is still loading, show splash
      if (profileState.isLoading) {
        debugPrint('[Router] -> Profile loading, go to /');
        if (currentLocation != '/') return '/';
        return null;
      }

      // If profile had an error, treat as incomplete
      if (profileState.hasError) {
        debugPrint('[Router] -> Profile error, go to /complete-profile');
        if (currentLocation != '/complete-profile') return '/complete-profile';
        return null;
      }

      final profile = profileState.value;
      final isProfileIncomplete = profile == null ||
          profile.major.isEmpty ||
          profile.semester == 0;

      debugPrint('[Router] Profile: major="${profile?.major}", semester=${profile?.semester}, isIncomplete=$isProfileIncomplete');

      // --- Step 4: Route based on profile completeness ---
      if (isProfileIncomplete) {
        if (currentLocation != '/complete-profile') {
          debugPrint('[Router] -> Profile incomplete, redirecting to /complete-profile');
          return '/complete-profile';
        }
        debugPrint('[Router] -> Profile incomplete, already on /complete-profile');
        return null;
      } else {
        if (isGoingToAuth || currentLocation == '/' || currentLocation == '/complete-profile') {
          debugPrint('[Router] -> Profile complete, redirecting to /dashboard');
          return '/dashboard';
        }
        debugPrint('[Router] -> Profile complete, staying on $currentLocation');
        return null;
      }
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'matchmaking',
                    builder: (context, state) => const StudyMateSearchScreen(),
                    routes: [
                      GoRoute(
                        path: 'results',
                        builder: (context, state) {
                          final extra = state.extra as Map<String, dynamic>;
                          return StudyMateResultsScreen(
                            selectedMajor: extra['major'] as String?,
                            selectedSemester: extra['semester'] as int?,
                            selectedCourse: extra['course'] as String?,
                          );
                        },
                      ),
                      GoRoute(
                        path: 'friend-requests',
                        builder: (context, state) => const FriendRequestsScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/workspace',
                builder: (context, state) => const WorkspaceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/repository',
                builder: (context, state) => const StudyHubScreen(),
                routes: [
                  GoRoute(
                    path: 'notes',
                    builder: (context, state) => const NotesListScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
