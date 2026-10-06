import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/auth/mocks/user_use_case_mock.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat.dart';
import 'package:domain/chat/entities/chat_folder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/chat_list.dart';
import 'package:swiftcomp/util/app_theme.dart';

class _ChatUseCase extends Fake implements ChatUseCase {
  @override
  Future<List<Chat>> fetchChatsByFolder(String folderId) async => [];
}

Future<void> _pumpChatList(
  WidgetTester tester,
  ChatViewModel viewModel,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<ChatViewModel>.value(
      value: viewModel,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: ChatList()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _searchText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  late ChatViewModel viewModel;

  setUp(() {
    viewModel = ChatViewModel(
      chatUseCase: _ChatUseCase(),
      authUseCase: MockAuthUseCase(),
      userUserCase: MockUserUseCase(),
    )..chats = [
        Chat(id: 'carbon', title: 'Carbon laminate design'),
        Chat(id: 'glass', title: 'Glass laminate design'),
      ];
  });

  tearDown(() => viewModel.dispose());

  testWidgets('search preserves typed draft until the debounce applies it',
      (tester) async {
    await _pumpChatList(tester, viewModel);

    await tester.enterText(find.byType(TextField), 'car');
    await tester.pump(const Duration(milliseconds: 100));
    expect(_searchText(tester), 'car');
    expect(viewModel.chatSearchQuery, isEmpty);

    await tester.enterText(find.byType(TextField), 'carbon ');
    await tester.pump(const Duration(milliseconds: 300));
    expect(_searchText(tester), 'carbon ');
    expect(viewModel.chatSearchQuery, isEmpty);

    await tester.pump(const Duration(milliseconds: 50));
    expect(viewModel.chatSearchQuery, 'carbon');
    expect(viewModel.filteredChats.map((chat) => chat.id), ['carbon']);
    expect(_searchText(tester), 'carbon ');
    expect(find.text('Glass laminate design'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('external query changes replace the draft and cancel its search',
      (tester) async {
    await viewModel.searchChatHistory('carbon');
    await _pumpChatList(tester, viewModel);
    expect(_searchText(tester), 'carbon');

    await tester.enterText(find.byType(TextField), 'carbon layup');
    await tester.pump(const Duration(milliseconds: 100));

    await viewModel.searchChatHistory('glass');
    await tester.pump();
    await tester.pump();
    expect(_searchText(tester), 'glass');

    await tester.pump(const Duration(milliseconds: 400));
    expect(viewModel.chatSearchQuery, 'glass');
    expect(viewModel.filteredChats.map((chat) => chat.id), ['glass']);
    expect(find.byTooltip('Clear search'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting a folder clears an unapplied search draft',
      (tester) async {
    const folder = ChatFolder(id: 'folder', name: 'Projects');
    viewModel.chatFolders = [folder];
    await _pumpChatList(tester, viewModel);

    await tester.enterText(find.byType(TextField), 'carbon');
    await tester.pump(const Duration(milliseconds: 100));
    expect(viewModel.chatSearchQuery, isEmpty);

    await viewModel.filterChatsByFolder(folder);
    await tester.pump();
    await tester.pump();
    expect(_searchText(tester), isEmpty);

    await tester.pump(const Duration(milliseconds: 400));
    expect(viewModel.chatSearchQuery, isEmpty);
    expect(viewModel.selectedChatFolder?.id, 'folder');
    expect(find.byTooltip('Clear search'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clear search also cancels an edited draft', (tester) async {
    await viewModel.searchChatHistory('carbon');
    await _pumpChatList(tester, viewModel);

    await tester.enterText(find.byType(TextField), 'carbon layup');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(_searchText(tester), isEmpty);
    expect(viewModel.chatSearchQuery, isEmpty);
    expect(viewModel.hasActiveChatFilter, isFalse);
    expect(find.byTooltip('Clear search'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
