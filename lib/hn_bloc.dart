import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';

import 'dart:collection';
import 'dart:async';

import 'article.dart';

enum StoriesType {
  topStories,
  newStories,
}

class HackerNewsBloc {
  Stream<UnmodifiableListView<Article>> get articles => _articlesSubject.stream;
  final _articlesSubject = BehaviorSubject<UnmodifiableListView<Article>>();

  Stream<bool> get isLoading => _isLoadingSubject.stream;
  final _isLoadingSubject = BehaviorSubject<bool>();

  Sink<StoriesType> get storiesType => _storiesTypeController.sink;
  final _storiesTypeController = StreamController<StoriesType>();

  HashMap<int, Article> _cachedArticles;

  HackerNewsBloc() {
    _cachedArticles = HashMap<int, Article>();
    Connectivity().checkConnectivity().then((result) {
      if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
        _getArticlesAndUpdate(StoriesType.topStories);

        _storiesTypeController.stream.listen((storiesType) {
          _getArticlesAndUpdate(storiesType);
        });
      }
    });
  }

  void close() {
    _articlesSubject.close();
    _storiesTypeController.close();
    _isLoadingSubject.close();
  }

  List<int> _ids;

  static const _baseUrl = 'hacker-news.firebaseio.com';

  Future<void> _getIds(StoriesType storiesType) async {
    final type = storiesType == StoriesType.topStories ? 'topstories' : 'newstories';
    final url = Uri.https(_baseUrl, '/v0/$type.json');
    final res = await http.get(url);
    
    if (res.statusCode == 200) {
      final ids = parseIds(res.body).take(10).toList();
      _ids = ids;
    } else {
      throw HackerNewsAPIError("Ids couldn't be fetched.");
    }
  }

  Future<Article> _getArticle(int id) async {
    if (!_cachedArticles.containsKey(id)) {
      final res = await http.get(Uri.https(_baseUrl, '/v0/item/$id.json'));

      if (res.statusCode == 200) {
        final article = parseArticle(res.body);
        _cachedArticles[id] = article;
      } else {
        throw HackerNewsAPIError("Article $id couldn't be fetched.");
      }
    }
    return _cachedArticles[id];
  }

  void _getArticlesAndUpdate(StoriesType storiesType) async {
    // The articles reception has started
    _isLoadingSubject.add(true);

    // Get the articles ids from the Hacker News API
    await _getIds(storiesType);

    // Get the article for each ID.
    final futureArticles = _ids.map(_getArticle);

    // Convert to have a list of articles
    final articles = await Future.wait(futureArticles);

    // Send the articles to the stream
    _articlesSubject.add(UnmodifiableListView<Article>(articles));

    // The process is finished
    _isLoadingSubject.add(false);
  }
}

class HackerNewsAPIError extends Error {
  final String message;

  HackerNewsAPIError(this.message);
}