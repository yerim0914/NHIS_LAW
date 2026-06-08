import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const ProviderScope(child: NhisLawApp()));

class NhisLawApp extends ConsumerWidget {
  const NhisLawApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: '건강보험법 학습',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        cardTheme: const CardThemeData(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/articles',
            builder: (context, state) => const ArticlesScreen(),
            routes: [
              GoRoute(
                path: ':articleId',
                builder: (context, state) => ArticleDetailScreen(
                  articleId: state.pathParameters['articleId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/quiz/ox',
            builder: (context, state) => QuizScreen(
              type: QuestionType.ox,
              articleId: state.uri.queryParameters['articleId'],
              lawId: state.uri.queryParameters['lawId'],
              chapter: state.uri.queryParameters['chapter'],
            ),
          ),
          GoRoute(
            path: '/quiz/multiple',
            builder: (context, state) => QuizScreen(
              type: QuestionType.multiple,
              articleId: state.uri.queryParameters['articleId'],
              lawId: state.uri.queryParameters['lawId'],
              chapter: state.uri.queryParameters['chapter'],
            ),
          ),
          GoRoute(
            path: '/wrong-notes',
            builder: (context, state) => const WrongNotesScreen(),
          ),
          GoRoute(
            path: '/bookmarks',
            builder: (context, state) => const BookmarksScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

enum QuestionType {
  ox,
  multiple;

  static QuestionType fromJson(String value) =>
      value == 'multiple' ? multiple : ox;
}

class Article {
  const Article({
    required this.id,
    required this.lawId,
    required this.lawName,
    required this.articleNumber,
    required this.title,
    required this.content,
    required this.chapter,
    required this.summary,
  });

  final String id;
  final String lawId;
  final String lawName;
  final String articleNumber;
  final String title;
  final String content;
  final String chapter;
  final String summary;

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as String,
      lawId: json['lawId'] as String? ?? 'national_health_insurance',
      lawName: json['lawName'] as String? ?? '국민건강보험법',
      articleNumber: json['articleNumber'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      chapter: json['chapter'] as String,
      summary: json['summary'] as String,
    );
  }
}

class Question {
  const Question({
    required this.id,
    required this.type,
    required this.articleId,
    required this.question,
    required this.answer,
    required this.options,
    required this.explanation,
  });

  final String id;
  final QuestionType type;
  final String articleId;
  final String question;
  final String answer;
  final List<String> options;
  final String explanation;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      type: QuestionType.fromJson(json['type'] as String),
      articleId: json['articleId'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      options: List<String>.from(json['options'] as List),
      explanation: json['explanation'] as String,
    );
  }
}

class ArticleRepository {
  Future<List<Article>> loadArticles() async {
    final raw = await rootBundle.loadString('assets/data/articles.json');
    return (jsonDecode(raw) as List)
        .map((item) => Article.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

class QuestionRepository {
  Future<List<Question>> loadQuestions() async {
    final raw = await rootBundle.loadString('assets/data/questions.json');
    return (jsonDecode(raw) as List)
        .map((item) => Question.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

class LocalStorageRepository {
  const LocalStorageRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _bookmarkKey = 'bookmarkedArticleIds';
  static const _wrongKey = 'wrongQuestionIds';
  static const _recentKey = 'recentArticleId';
  static const _attemptsKey = 'quizAttemptRecords';
  static const _fontScaleKey = 'fontScale';

  Set<String> getBookmarkedArticleIds() =>
      _prefs.getStringList(_bookmarkKey)?.toSet() ?? <String>{};
  Set<String> getWrongQuestionIds() =>
      _prefs.getStringList(_wrongKey)?.toSet() ?? <String>{};
  String? getRecentArticleId() => _prefs.getString(_recentKey);
  double getFontScale() => _prefs.getDouble(_fontScaleKey) ?? 1;

  Future<void> toggleBookmark(String articleId) async {
    final ids = getBookmarkedArticleIds();
    ids.contains(articleId) ? ids.remove(articleId) : ids.add(articleId);
    await _prefs.setStringList(_bookmarkKey, ids.toList()..sort());
  }

  Future<void> setRecentArticle(String articleId) =>
      _prefs.setString(_recentKey, articleId);

  Future<void> addWrongQuestion(String questionId) async {
    final ids = getWrongQuestionIds()..add(questionId);
    await _prefs.setStringList(_wrongKey, ids.toList()..sort());
  }

  Future<void> removeWrongQuestion(String questionId) async {
    final ids = getWrongQuestionIds()..remove(questionId);
    await _prefs.setStringList(_wrongKey, ids.toList()..sort());
  }

  Future<void> clearWrongQuestions() => _prefs.remove(_wrongKey);
  Future<void> clearBookmarks() => _prefs.remove(_bookmarkKey);
  Future<void> setFontScale(double value) =>
      _prefs.setDouble(_fontScaleKey, value);

  Future<void> addAttemptRecord({
    required String questionId,
    required String selected,
    required bool correct,
  }) async {
    final records = _prefs.getStringList(_attemptsKey) ?? <String>[];
    records.add(
      jsonEncode({
        'questionId': questionId,
        'selected': selected,
        'correct': correct,
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );
    await _prefs.setStringList(_attemptsKey, records);
  }
}

final articleRepositoryProvider = Provider((ref) => ArticleRepository());
final questionRepositoryProvider = Provider((ref) => QuestionRepository());
final sharedPreferencesProvider = FutureProvider(
  (ref) => SharedPreferences.getInstance(),
);
final localStorageRepositoryProvider = FutureProvider(
  (ref) async =>
      LocalStorageRepository(await ref.watch(sharedPreferencesProvider.future)),
);
final articlesProvider = FutureProvider(
  (ref) => ref.watch(articleRepositoryProvider).loadArticles(),
);
final questionsProvider = FutureProvider(
  (ref) => ref.watch(questionRepositoryProvider).loadQuestions(),
);
final bookmarkIdsProvider = FutureProvider(
  (ref) async => (await ref.watch(
    localStorageRepositoryProvider.future,
  )).getBookmarkedArticleIds(),
);
final wrongQuestionIdsProvider = FutureProvider(
  (ref) async => (await ref.watch(
    localStorageRepositoryProvider.future,
  )).getWrongQuestionIds(),
);
final recentArticleIdProvider = FutureProvider(
  (ref) async => (await ref.watch(
    localStorageRepositoryProvider.future,
  )).getRecentArticleId(),
);
final fontScaleProvider = FutureProvider(
  (ref) async =>
      (await ref.watch(localStorageRepositoryProvider.future)).getFontScale(),
);

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final index = switch (path) {
      String p when p.startsWith('/articles') || p.startsWith('/bookmarks') =>
        1,
      String p when p.startsWith('/search') => 2,
      String p when p.startsWith('/wrong-notes') || p.startsWith('/quiz') => 3,
      String p when p.startsWith('/settings') => 4,
      _ => 0,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => context.go(
          ['/', '/articles', '/search', '/wrong-notes', '/settings'][value],
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: '법령',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: '검색'),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: '오답',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}

class ScreenFrame extends StatelessWidget {
  const ScreenFrame({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.leading,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), leading: leading, actions: actions),
      body: Column(
        children: [
          Expanded(child: child),
          const AdPlaceholder(),
        ],
      ),
    );
  }
}

class AdPlaceholder extends StatelessWidget {
  const AdPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: Text(
          '광고 영역',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(articlesProvider);
    final recentId = ref.watch(recentArticleIdProvider).value;

    return ScreenFrame(
      title: '건강보험법 학습',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AsyncValueView(
            value: articles,
            data: (items) {
              final recent = items
                  .where((item) => item.id == recentId)
                  .firstOrNull;
              final today = recent ?? items.first;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '오늘의 학습',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            today.lawName,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${today.articleNumber} ${today.title}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(today.summary),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () =>
                                context.go('/articles/${today.id}'),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('이어 보기'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.3,
                    children: [
                      _HomeButton(
                        '법령 보기',
                        Icons.menu_book,
                        () => context.go('/articles'),
                      ),
                      _HomeButton(
                        '통합 검색',
                        Icons.search,
                        () => context.go('/search'),
                      ),
                      _HomeButton(
                        'OX 퀴즈',
                        Icons.check_circle_outline,
                        () => context.push('/quiz/ox'),
                      ),
                      _HomeButton(
                        '객관식',
                        Icons.format_list_numbered,
                        () => context.push('/quiz/multiple'),
                      ),
                      _HomeButton(
                        '북마크',
                        Icons.bookmark_outline,
                        () => context.go('/bookmarks'),
                      ),
                      _HomeButton(
                        '오답노트',
                        Icons.edit_note,
                        () => context.go('/wrong-notes'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  const _HomeButton(this.label, this.icon, this.onPressed);

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class ArticlesScreen extends ConsumerWidget {
  const ArticlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(articlesProvider);
    final bookmarks = ref.watch(bookmarkIdsProvider).value ?? <String>{};
    final questions = ref.watch(questionsProvider).value ?? <Question>[];

    return ScreenFrame(
      title: '법령 보기',
      actions: [
        IconButton(
          tooltip: '북마크',
          onPressed: () => context.go('/bookmarks'),
          icon: const Icon(Icons.bookmarks_outlined),
        ),
      ],
      child: AsyncValueView(
        value: articles,
        data: (items) {
          final grouped = <String, Map<String, List<Article>>>{};
          for (final article in items) {
            grouped
                .putIfAbsent(article.lawName, () => <String, List<Article>>{})
                .putIfAbsent(article.chapter, () => <Article>[])
                .add(article);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: grouped.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final lawName = grouped.keys.elementAt(index);
              final chapters = grouped[lawName]!;
              final lawArticles = chapters.values
                  .expand((chapterArticles) => chapterArticles)
                  .toList();
              return Card(
                child: ExpansionTile(
                  initiallyExpanded: index == 0,
                  leading: const Icon(Icons.account_balance_outlined),
                  title: Text(lawName),
                  subtitle: Text('${lawArticles.length}개 조문'),
                  children: [
                    const Divider(height: 1),
                    ...chapters.entries.map((entry) {
                      final chapter = entry.key;
                      final chapterArticles = entry.value;
                      final chapterArticleIds = chapterArticles
                          .map((article) => article.id)
                          .toSet();
                      final oxCount = questions
                          .where(
                            (question) =>
                                question.type == QuestionType.ox &&
                                chapterArticleIds.contains(question.articleId),
                          )
                          .length;
                      final multipleCount = questions
                          .where(
                            (question) =>
                                question.type == QuestionType.multiple &&
                                chapterArticleIds.contains(question.articleId),
                          )
                          .length;
                      final lawId = chapterArticles.first.lawId;
                      final encodedLawId = Uri.encodeComponent(lawId);
                      final encodedChapter = Uri.encodeComponent(chapter);

                      return ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 20),
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        leading: const Icon(Icons.folder_open_outlined),
                        title: Text(chapter),
                        subtitle: Text('${chapterArticles.length}개 조문'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: oxCount == 0
                                        ? null
                                        : () => context.push(
                                            '/quiz/ox?lawId=$encodedLawId&chapter=$encodedChapter',
                                          ),
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                    ),
                                    label: Text('OX $oxCount개'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: multipleCount == 0
                                        ? null
                                        : () => context.push(
                                            '/quiz/multiple?lawId=$encodedLawId&chapter=$encodedChapter',
                                          ),
                                    icon: const Icon(
                                      Icons.format_list_numbered,
                                    ),
                                    label: Text('객관식 $multipleCount개'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...chapterArticles.map(
                            (article) => ArticleTile(
                              article: article,
                              bookmarked: bookmarks.contains(article.id),
                              showLawName: false,
                              showCard: false,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ArticleTile extends ConsumerWidget {
  const ArticleTile({
    super.key,
    required this.article,
    required this.bookmarked,
    this.showLawName = true,
    this.showCard = true,
  });

  final Article article;
  final bool bookmarked;
  final bool showLawName;
  final bool showCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tile = ListTile(
      onTap: () => context.go('/articles/${article.id}'),
      title: Text('${article.articleNumber} ${article.title}'),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          '${showLawName ? '${article.lawName} · ' : ''}${article.chapter}\n${article.summary}',
        ),
      ),
      isThreeLine: true,
      trailing: IconButton(
        tooltip: bookmarked ? '북마크 해제' : '북마크',
        icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
        onPressed: () async {
          final repo = await ref.read(localStorageRepositoryProvider.future);
          await repo.toggleBookmark(article.id);
          ref.invalidate(bookmarkIdsProvider);
        },
      ),
    );
    if (!showCard) {
      return tile;
    }
    return Card(child: tile);
  }
}

class ArticleDetailScreen extends ConsumerStatefulWidget {
  const ArticleDetailScreen({super.key, required this.articleId});

  final String articleId;

  @override
  ConsumerState<ArticleDetailScreen> createState() =>
      _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  bool _storedRecent = false;

  @override
  void didUpdateWidget(covariant ArticleDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.articleId != widget.articleId) {
      _storedRecent = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final articles = ref.watch(articlesProvider);
    final bookmarks = ref.watch(bookmarkIdsProvider).value ?? <String>{};
    final fontScale = ref.watch(fontScaleProvider).value ?? 1;
    final questions = ref.watch(questionsProvider).value ?? <Question>[];

    return ScreenFrame(
      title: '조문 상세',
      child: AsyncValueView(
        value: articles,
        data: (items) {
          final article = items.firstWhere(
            (item) => item.id == widget.articleId,
          );
          final lawArticles = items
              .where((item) => item.lawId == article.lawId)
              .toList();
          final articleIndex = lawArticles.indexWhere(
            (item) => item.id == article.id,
          );
          final previousArticle = articleIndex > 0
              ? lawArticles[articleIndex - 1]
              : null;
          final nextArticle =
              articleIndex >= 0 && articleIndex < lawArticles.length - 1
              ? lawArticles[articleIndex + 1]
              : null;
          if (!_storedRecent) {
            _storedRecent = true;
            Future.microtask(() async {
              final repo = await ref.read(
                localStorageRepositoryProvider.future,
              );
              await repo.setRecentArticle(article.id);
              ref.invalidate(recentArticleIdProvider);
            });
          }
          final relatedQuestions = questions
              .where((question) => question.articleId == article.id)
              .toList();
          final relatedOxCount = relatedQuestions
              .where((question) => question.type == QuestionType.ox)
              .length;
          final relatedMultipleCount = relatedQuestions
              .where((question) => question.type == QuestionType.multiple)
              .length;
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.lawName,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          article.chapter,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${article.articleNumber} ${article.title}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: bookmarks.contains(article.id) ? '북마크 해제' : '북마크',
                    icon: Icon(
                      bookmarks.contains(article.id)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                    ),
                    onPressed: () async {
                      final repo = await ref.read(
                        localStorageRepositoryProvider.future,
                      );
                      await repo.toggleBookmark(article.id);
                      ref.invalidate(bookmarkIdsProvider);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                article.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 17 * fontScale,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 24),
              if (relatedQuestions.isEmpty)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.quiz_outlined),
                    title: const Text('관련 퀴즈 없음'),
                    subtitle: const Text('이 조문에 연결된 문제가 아직 없습니다.'),
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: relatedOxCount == 0
                          ? null
                          : () => context.push(
                              '/quiz/ox?articleId=${article.id}',
                            ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text('관련 OX $relatedOxCount개'),
                    ),
                    FilledButton.icon(
                      onPressed: relatedMultipleCount == 0
                          ? null
                          : () => context.push(
                              '/quiz/multiple?articleId=${article.id}',
                            ),
                      icon: const Icon(Icons.format_list_numbered),
                      label: Text('관련 객관식 $relatedMultipleCount개'),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: previousArticle == null
                          ? null
                          : () => context.go('/articles/${previousArticle.id}'),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(
                        previousArticle == null
                            ? '이전 조문 없음'
                            : '이전 ${previousArticle.articleNumber}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: nextArticle == null
                          ? null
                          : () => context.go('/articles/${nextArticle.id}'),
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(
                        nextArticle == null
                            ? '다음 조문 없음'
                            : '다음 ${nextArticle.articleNumber}',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final articles = ref.watch(articlesProvider);
    return ScreenFrame(
      title: '검색',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '조문 번호, 제목, 본문 검색',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: articles,
              data: (items) {
                final results = _query.isEmpty
                    ? <Article>[]
                    : items
                          .where(
                            (item) =>
                                '${item.lawName} ${item.articleNumber} ${item.title} ${item.content}'
                                    .contains(_query),
                          )
                          .toList();
                if (_query.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search,
                    message: '검색어를 입력하세요',
                  );
                }
                if (results.isEmpty) {
                  return const EmptyState(
                    icon: Icons.manage_search,
                    message: '검색 결과가 없습니다',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final article = results[index];
                    return Card(
                      child: ListTile(
                        onTap: () => context.go('/articles/${article.id}'),
                        title: HighlightedText(
                          '${article.lawName} · ${article.articleNumber} ${article.title}',
                          query: _query,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: HighlightedText(
                            article.content,
                            query: _query,
                            maxLines: 3,
                          ),
                        ),
                      ),
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
}

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({
    super.key,
    required this.type,
    this.articleId,
    this.lawId,
    this.chapter,
  });

  final QuestionType type;
  final String? articleId;
  final String? lawId;
  final String? chapter;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _index = 0;
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final questions = ref.watch(questionsProvider);
    final articles = ref.watch(articlesProvider);
    final title = widget.type == QuestionType.ox ? 'OX 퀴즈' : '객관식 퀴즈';
    return ScreenFrame(
      title: title,
      leading: IconButton(
        tooltip: '뒤로가기',
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else if (widget.articleId != null) {
            context.go('/articles/${widget.articleId}');
          } else if (widget.lawId != null && widget.chapter != null) {
            context.go('/articles');
          } else {
            context.go('/');
          }
        },
        icon: const Icon(Icons.arrow_back),
      ),
      child: AsyncValueView(
        value: questions,
        data: (items) {
          final chapterArticleIds =
              articles.value
                  ?.where(
                    (article) =>
                        article.lawId == widget.lawId &&
                        article.chapter == widget.chapter,
                  )
                  .map((article) => article.id)
                  .toSet() ??
              <String>{};
          final filtered = items
              .where(
                (item) =>
                    item.type == widget.type &&
                    (widget.articleId == null ||
                        item.articleId == widget.articleId) &&
                    (widget.lawId == null ||
                        widget.chapter == null ||
                        chapterArticleIds.contains(item.articleId)),
              )
              .toList();
          if (filtered.isEmpty) {
            return const EmptyState(
              icon: Icons.quiz_outlined,
              message: '문제가 없습니다',
            );
          }
          final question = filtered[_index % filtered.length];
          final answered = _selected != null;
          final correct = _selected == question.answer;
          final hasNextQuestion = _index < filtered.length - 1;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${_index + 1} / ${filtered.length}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    question.question,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...question.options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      backgroundColor: option == _selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: answered
                        ? null
                        : () async {
                            setState(() => _selected = option);
                            final isCorrect = option == question.answer;
                            final repo = await ref.read(
                              localStorageRepositoryProvider.future,
                            );
                            await repo.addAttemptRecord(
                              questionId: question.id,
                              selected: option,
                              correct: isCorrect,
                            );
                            if (!isCorrect) {
                              await repo.addWrongQuestion(question.id);
                              ref.invalidate(wrongQuestionIdsProvider);
                            }
                          },
                    child: Text(option),
                  ),
                ),
              ),
              if (answered) ...[
                const SizedBox(height: 8),
                Card(
                  color: correct
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          correct ? '정답입니다' : '오답입니다',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('정답: ${question.answer}'),
                        const SizedBox(height: 8),
                        Text(question.explanation),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () => setState(() {
                        _selected = null;
                      }),
                      icon: const Icon(Icons.refresh),
                      label: const Text('다시 풀기'),
                    ),
                    FilledButton.icon(
                      onPressed: hasNextQuestion
                          ? () => setState(() {
                              _index += 1;
                              _selected = null;
                            })
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('다음 문제'),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class WrongNotesScreen extends ConsumerWidget {
  const WrongNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(questionsProvider);
    final wrongIds = ref.watch(wrongQuestionIdsProvider).value ?? <String>{};
    return ScreenFrame(
      title: '오답노트',
      actions: [
        IconButton(
          tooltip: '전체 삭제',
          onPressed: wrongIds.isEmpty
              ? null
              : () async {
                  final repo = await ref.read(
                    localStorageRepositoryProvider.future,
                  );
                  await repo.clearWrongQuestions();
                  ref.invalidate(wrongQuestionIdsProvider);
                },
          icon: const Icon(Icons.delete_sweep_outlined),
        ),
      ],
      child: AsyncValueView(
        value: questions,
        data: (items) {
          final wrongQuestions = items
              .where((item) => wrongIds.contains(item.id))
              .toList();
          if (wrongQuestions.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline,
              message: '저장된 오답이 없습니다',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: wrongQuestions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final question = wrongQuestions[index];
              return Card(
                child: ListTile(
                  onTap: () => context.push(
                    question.type == QuestionType.ox
                        ? '/quiz/ox?articleId=${question.articleId}'
                        : '/quiz/multiple?articleId=${question.articleId}',
                  ),
                  title: Text(question.question),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '정답: ${question.answer}\n${question.explanation}',
                    ),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: '삭제',
                    onPressed: () async {
                      final repo = await ref.read(
                        localStorageRepositoryProvider.future,
                      );
                      await repo.removeWrongQuestion(question.id);
                      ref.invalidate(wrongQuestionIdsProvider);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(articlesProvider);
    final bookmarkIds = ref.watch(bookmarkIdsProvider).value ?? <String>{};
    return ScreenFrame(
      title: '북마크',
      child: AsyncValueView(
        value: articles,
        data: (items) {
          final bookmarks = items
              .where((item) => bookmarkIds.contains(item.id))
              .toList();
          if (bookmarks.isEmpty) {
            return const EmptyState(
              icon: Icons.bookmark_border,
              message: '북마크한 조문이 없습니다',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: bookmarks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                ArticleTile(article: bookmarks[index], bookmarked: true),
          );
        },
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontScale = ref.watch(fontScaleProvider).value ?? 1;
    return ScreenFrame(
      title: '설정',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('앱 정보'),
                  subtitle: Text('건강보험법 학습 MVP · 데이터 버전 2026.06'),
                ),
                ListTile(
                  leading: const Icon(Icons.format_size),
                  title: const Text('본문 글자 크기'),
                  subtitle: Slider(
                    value: fontScale,
                    min: 0.9,
                    max: 1.3,
                    divisions: 4,
                    label: '${(fontScale * 100).round()}%',
                    onChanged: (value) async {
                      final repo = await ref.read(
                        localStorageRepositoryProvider.future,
                      );
                      await repo.setFontScale(value);
                      ref.invalidate(fontScaleProvider);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: const Text('오답노트 초기화'),
                  onTap: () async {
                    final repo = await ref.read(
                      localStorageRepositoryProvider.future,
                    );
                    await repo.clearWrongQuestions();
                    ref.invalidate(wrongQuestionIdsProvider);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bookmark_remove_outlined),
                  title: const Text('북마크 초기화'),
                  onTap: () async {
                    final repo = await ref.read(
                      localStorageRepositoryProvider.future,
                    );
                    await repo.clearBookmarks();
                    ref.invalidate(bookmarkIdsProvider);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HighlightedText extends StatelessWidget {
  const HighlightedText(
    this.text, {
    super.key,
    required this.query,
    this.maxLines,
  });

  final String text;
  final String query;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    if (query.isEmpty || !text.contains(query)) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
      );
    }
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final index = text.indexOf(query, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      start = index + query.length;
    }
    return RichText(
      maxLines: maxLines,
      overflow: maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
      text: TextSpan(style: style, children: spans),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({super.key, required this.value, required this.data});

  final AsyncValue<T> value;
  final Widget Function(T data) data;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('데이터를 불러오지 못했습니다\n$error', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
