import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mystudymate_app/main.dart';
import 'package:mystudymate_app/features/auth/providers/auth_provider.dart';
import 'package:mystudymate_app/features/auth/data/auth_repository.dart';
import 'package:mystudymate_app/features/profile/providers/profile_provider.dart';
import 'package:mystudymate_app/features/profile/data/profile_repository.dart';
import 'package:mystudymate_app/shared/models/user_profile.dart';
import 'package:mystudymate_app/shared/models/workspace.dart';
import 'package:mystudymate_app/features/workspace/providers/workspace_provider.dart';
import 'package:mystudymate_app/features/workspace/presentation/workspace_screen.dart';
import 'package:mystudymate_app/features/workspace/data/workspace_repository.dart';
import 'package:mystudymate_app/shared/models/task.dart';
import 'package:mystudymate_app/features/repository/presentation/study_hub_screen.dart';
import 'package:mystudymate_app/features/repository/presentation/repository_list_screen.dart';
import 'package:mystudymate_app/features/repository/providers/repository_provider.dart';
import 'package:mystudymate_app/shared/models/repository_file.dart';
import 'package:mystudymate_app/features/repository/data/repository_repository.dart';
import 'package:mystudymate_app/features/notes/providers/notes_provider.dart';
import 'package:mystudymate_app/shared/models/note.dart';
import 'package:mystudymate_app/features/notes/data/notes_repository.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Stream<AuthState> get authStateChanges => Stream.value(
        const AuthState(AuthChangeEvent.initialSession, null),
      );

  @override
  User? get currentUser => null;

  @override
  Future<AuthResponse> signIn({required String email, required String password}) async {
    return AuthResponse();
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return AuthResponse();
  }

  @override
  Future<void> signOut() async {}
}

class MockProfileRepository implements ProfileRepository {
  @override
  Future<UserProfile?> getProfile(String userId) async {
    return UserProfile(
      id: userId,
      fullName: 'Test User',
      major: 'TI',
      semester: 4,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> completeProfile({
    required String userId,
    required String major,
    required int semester,
  }) async {}

  @override
  Future<void> updateProfile({
    required String userId,
    required String fullName,
    required String major,
    required int semester,
  }) async {}
}

class MockWorkspaceRepository implements WorkspaceRepository {
  @override
  Future<List<Workspace>> getWorkspaces(String userId) async => [];
  @override
  Future<Workspace> createWorkspace({required String name, required String ownerId}) async => throw UnimplementedError();
  @override
  Future<List<Task>> getTasks(String workspaceId) async => [];
  @override
  Future<Task> createTask(Task task) async => throw UnimplementedError();
  @override
  Future<Task> updateTask(Task task) async => throw UnimplementedError();
  @override
  Future<void> deleteTask(String taskId) async {}
  @override
  Future<List<UserProfile>> getWorkspaceMembers(String workspaceId) async => [];
  @override
  Future<void> inviteMemberByName(String workspaceId, String fullName) async {}
  @override
  Future<void> inviteMemberById(String workspaceId, String userId) async {}
  @override
  Future<void> removeMember(String workspaceId, String userId) async {}
  @override
  Future<void> deleteWorkspace(String workspaceId) async {}
}

class MockWorkspacesNotifier extends WorkspacesNotifier {
  MockWorkspacesNotifier() : super(MockWorkspaceRepository(), 'owner') {
    state = AsyncValue.data([
      Workspace(
        id: '1',
        name: 'PBL Semester 4',
        ownerId: 'owner',
        createdAt: DateTime.now(),
        memberCount: 5,
        activeTaskCount: 8,
      ),
    ]);
  }

  @override
  Future<void> loadWorkspaces() async {}
}

void main() {
  testWidgets('MyStudyMate login screen redirect test', (WidgetTester tester) async {
    // Build our app and trigger a frame with a mocked unauthenticated authRepository
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          profileRepositoryProvider.overrideWithValue(MockProfileRepository()),
          currentUserIdProvider.overrideWithValue(null),
        ],
        child: const MyApp(),
      ),
    );

    // Wait for the redirect and layout rendering to execute
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that the login screen header is displayed
    expect(find.text('Welcome Back!'), findsOneWidget);
    
    // Verify that the input fields and login button are present
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('WorkspaceScreen layout rendering test', (WidgetTester tester) async {
    final notifier = MockWorkspacesNotifier();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          profileRepositoryProvider.overrideWithValue(MockProfileRepository()),
          currentUserIdProvider.overrideWithValue('owner'),
          workspacesProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          home: WorkspaceScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Workspaces'), findsOneWidget);
    expect(find.text('PBL Semester 4'), findsOneWidget);
  });

  testWidgets('WorkspaceScreen empty state layout rendering test', (WidgetTester tester) async {
    final notifier = MockEmptyWorkspacesNotifier();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          profileRepositoryProvider.overrideWithValue(MockProfileRepository()),
          currentUserIdProvider.overrideWithValue('owner'),
          workspacesProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          home: WorkspaceScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('No Workspace Yet'), findsOneWidget);
  });

  testWidgets('WorkspaceScreen open bottom sheet test', (WidgetTester tester) async {
    final notifier = MockEmptyWorkspacesNotifier();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          profileRepositoryProvider.overrideWithValue(MockProfileRepository()),
          currentUserIdProvider.overrideWithValue('owner'),
          workspacesProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          home: WorkspaceScreen(),
        ),
      ),
    );

    await tester.pump();
    
    // Tap the Create Workspace button
    await tester.tap(find.text('Create Workspace'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // wait for sheet animation
    
    // Check if bottom sheet is shown
    expect(find.text('Workspace Name'), findsOneWidget);
  });

  testWidgets('StudyHubScreen layout rendering test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: StudyHubScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Study Hub'), findsOneWidget);
    expect(find.text('Academic Repository'), findsOneWidget);
    expect(find.text('My Notes'), findsOneWidget);
  });

  testWidgets('RepositoryListScreen layout rendering test', (WidgetTester tester) async {
    final notifier = MockRepositoryFilesNotifier();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryFilesProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          home: RepositoryListScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Academic Repository'), findsOneWidget);
    expect(find.text('Modul Sistem Database'), findsOneWidget);
  });
}

class MockEmptyWorkspacesNotifier extends WorkspacesNotifier {
  MockEmptyWorkspacesNotifier() : super(MockWorkspaceRepository(), 'owner') {
    state = const AsyncValue.data([]);
  }

  @override
  Future<void> loadWorkspaces() async {}
}

class MockRepositoryRepository implements RepositoryRepository {
  @override
  Future<List<RepositoryFile>> getRepositoryFiles() async => [];
  
  @override
  Future<RepositoryFile> uploadRepositoryFile({
    required String title,
    required String courseName,
    required String localPath,
    required Uint8List? fileBytes,
    required String fileName,
    required String userId,
  }) async => throw UnimplementedError();

  @override
  Future<void> deleteRepositoryFile(String id, String storagePath) async {}

  @override
  Future<String> getDownloadUrl(String storagePath) async => 'http://mock-url.com';
}

class MockRepositoryFilesNotifier extends RepositoryFilesNotifier {
  MockRepositoryFilesNotifier() : super(MockRepositoryRepository(), 'owner') {
    state = AsyncValue.data([
      RepositoryFile(
        id: '1',
        userId: 'owner',
        title: 'Modul Sistem Database',
        courseName: 'Database System',
        filePath: 'owner/file.pdf',
        uploadedAt: DateTime.now(),
        uploaderName: 'Alex',
      ),
    ]);
  }

  @override
  Future<void> loadRepositoryFiles() async {}
}

class MockNotesRepository implements NotesRepository {
  @override
  Future<List<Note>> getNotes(String userId) async => [];

  @override
  Future<Note> createNote(Note note) async => throw UnimplementedError();

  @override
  Future<Note> updateNote(Note note) async => throw UnimplementedError();

  @override
  Future<void> deleteNote(String userId, String id) async {}
}

class MockNotesNotifier extends NotesNotifier {
  MockNotesNotifier() : super(MockNotesRepository(), 'owner') {
    state = AsyncValue.data([
      Note(
        id: '1',
        userId: 'owner',
        courseName: 'Artificial Intelligence',
        title: 'AI Search Notes',
        content: 'Mock contents...',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ]);
  }

  @override
  Future<void> loadNotes() async {}
}
