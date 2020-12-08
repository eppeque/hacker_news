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

  Sink<StoriesType> get storiesType => _storiesTypeController.sink;
  final _storiesTypeController = StreamController<StoriesType>();

  HackerNewsBloc() {
    Connectivity().checkConnectivity().then((result) {
      if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
        _getArticlesAndUpdate(StoriesType.topStories);

        _storiesTypeController.stream.listen((storiesType) {
          _articlesSubject.add(UnmodifiableListView<Article>([]));
          _getArticlesAndUpdate(storiesType);
        });
      }
    });
  }

  void close() {
    _articlesSubject.close();
    _storiesTypeController.close();
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
    await _getIds(storiesType);
    final futureArticles = _ids.map(_getArticle);
    final articles = await Future.wait(futureArticles);
    _articlesSubject.add(UnmodifiableListView<Article>(articles));
  }
}