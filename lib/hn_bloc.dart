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

  HackerNewsBloc() {
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

  static const _baseUrl = 'https://hacker-news.firebaseio.com/v0';

  Future<void> _getIds(StoriesType storiesType) async {
    final type = storiesType == StoriesType.topStories ? 'topstories' : 'newstories';
    final url = '$_baseUrl/$type.json';
    final res = await http.get(url);
    
    if (res.statusCode == 200) {
      final ids = parseIds(res.body).take(10).toList();
      _ids = ids;
    }
  }

  Future<Article> _getArticle(int id) async {
    final res = await http.get('https://hacker-news.firebaseio.com/v0/item/$id.json');

    if (res.statusCode == 200) {
      final article = parseArticle(res.body);
      return article;
    }

    return null;
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