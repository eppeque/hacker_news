import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:connectivity/connectivity.dart';
import 'package:share/share.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'theme_provider.dart';
import 'hn_bloc.dart';
import 'bloc_provider.dart';
import 'article.dart';
import 'webview_page.dart';
import 'no_network.dart';
import 'auth.dart';
import 'stars.dart';
import 'settings.dart';

import 'dart:collection';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  final prefs = await SharedPreferences.getInstance();
  final isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
  final hnBloc = HackerNewsBloc();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(isDarkTheme: isDarkTheme),
      child: BlocProvider(
        child: HackerNewsApp(),
        bloc: hnBloc,
      ),
    ),
  );
}

class HackerNewsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Hacker News',
      home: SplashScreen(),
      theme: themeProvider.theme,
      darkTheme: darkTheme,
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    var connectivityResult;
    Connectivity()
        .checkConnectivity()
        .then((result) => connectivityResult = result);
    Timer(
      Duration(seconds: 3),
      () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              connectivityResult == ConnectivityResult.mobile ||
                      connectivityResult == ConnectivityResult.wifi
                  ? Home()
                  : NoNetwork(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Icon(
          FontAwesomeIcons.hackerNewsSquare,
          color: Colors.deepOrange,
          size: 100.0,
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  final auth = Auth();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bloc = BlocProvider.of(context).bloc;
    return StreamBuilder<User>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, userSnapshot) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0.0,
            title: const Text(
              'Hacker News',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.search),
                tooltip: 'Search an article',
                onPressed: () async {
                  final article = await showSearch(
                    context: context,
                    delegate: SearchPage(articles: bloc.articles),
                  );

                  if (article != null) {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => WebviewPage(
                          by: article.by,
                          url: article.url,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          drawer: Drawer(
            child: ListView(
              children: [
                SizedBox(height: 16.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.hackerNewsSquare,
                        size: 30.0,
                        color: Colors.deepOrange,
                      ),
                      SizedBox(width: 10.0),
                      Text(
                        'Hacker News',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.0),
                userSnapshot != null
                    ? ListTile(
                        leading: const Icon(Icons.star_border),
                        title: const Text('Your Stars'),
                        onTap: () => Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => StarsPage(),
                          ),
                        ),
                      )
                    : Container(),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  onTap: () => showSettingsPage(context, themeProvider, userSnapshot.data),
                ),
              ],
            ),
          ),
          body: StreamBuilder<bool>(
            stream: bloc.isLoading,
            initialData: true,
            builder: (context, loadingSnapshot) {
              if (loadingSnapshot.data)
                return Center(
                  child: CircularProgressIndicator(),
                );
              return StreamBuilder<UnmodifiableListView<Article>>(
                stream: bloc.articles,
                initialData: UnmodifiableListView<Article>([]),
                builder: (context, snapshot) {
                  if (snapshot.hasData)
                    return ListView(
                      children: snapshot.data
                          .map((article) =>
                              _buildItem(article, userSnapshot.data))
                          .toList(),
                    );
                  return Container();
                },
              );
            },
          ),
          bottomNavigationBar: BottomNavigationBar(
            elevation: 0.0,
            selectedItemColor: Theme.of(context).accentColor,
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index != _currentIndex) {
                bloc.storiesType.add(index == 0
                    ? StoriesType.topStories
                    : StoriesType.newStories);
              }
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.arrow_drop_up),
                label: 'Top Stories',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.new_releases_outlined),
                label: 'New Stories',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItem(Article article, User user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: user != null
          ? FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots()
          : null,
      builder: (context, snapshot) {
        bool isStar = false;
        if (snapshot.hasData) {
          final List<int> stars = List<int>.from(snapshot.data['stars']);
          isStar = stars.contains(article.id);
        }
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ExpansionTile(
            leading: user != null
                ? IconButton(
                    icon: Icon(isStar ? Icons.star : Icons.star_border),
                    color: isStar ? Colors.yellow : null,
                    onPressed: () {
                      final docRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid);
                      if (isStar) {
                        docRef.update({
                          'stars': FieldValue.arrayRemove([article.id]),
                        });
                      } else {
                        docRef.update({
                          'stars': FieldValue.arrayUnion([article.id]),
                        });
                      }
                    },
                  )
                : null,
            title: Text(
              article.title ?? 'This article has no title',
              style: TextStyle(fontSize: 24.0),
            ),
            subtitle: Text(article.by ?? 'No author provided'),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  article.url != null
                      ? IconButton(
                          tooltip: 'Read full article',
                          icon: Icon(Icons.launch),
                          color: Theme.of(context).accentColor,
                          onPressed: () => Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => WebviewPage(
                                by: article.by,
                                url: article.url,
                              ),
                            ),
                          ),
                        )
                      : Container(),
                  article.url != null
                      ? IconButton(
                          tooltip: 'Share the article',
                          icon: Icon(Icons.share_outlined),
                          color: Theme.of(context).accentColor,
                          onPressed: () => Share.share(
                              'Check out this article from ${article.by} : ${article.url}'),
                        )
                      : Container(),
                  Padding(
                    padding: article.url != null
                        ? const EdgeInsets.all(0.0)
                        : const EdgeInsets.all(16.0),
                    child: article.descendants != null
                        ? Text(article.descendants > 1
                            ? '${article.descendants} comments'
                            : '${article.descendants} comment')
                        : Text('No comments'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class SearchPage extends SearchDelegate {
  final Stream<UnmodifiableListView<Article>> articles;

  SearchPage({this.articles});

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context);
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return StreamBuilder<UnmodifiableListView<Article>>(
      stream: articles,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(
            child: CircularProgressIndicator(),
          );
        final searchedArticles = snapshot.data
            .where((article) =>
                article.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
        return ListView(
          children: searchedArticles
              .map(
                (article) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListTile(
                    leading: Icon(
                      Icons.article_outlined,
                      color: Theme.of(context).accentColor,
                    ),
                    title: Text(
                      article.title,
                      style: TextStyle(fontSize: 24.0),
                    ),
                    onTap: () => close(context, article),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return StreamBuilder<UnmodifiableListView<Article>>(
      stream: articles,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(
            child: CircularProgressIndicator(),
          );
        final searchedArticles = snapshot.data
            .where((article) =>
                article.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
        return ListView(
          children: searchedArticles
              .map(
                (article) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListTile(
                    title: Text(
                      article.title,
                      style: TextStyle(color: Colors.blue),
                    ),
                    onTap: () => query = article.title,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
