import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:connectivity/connectivity.dart';
import 'package:share/share.dart';

import 'theme_provider.dart';
import 'hn_bloc.dart';
import 'bloc_provider.dart';
import 'article.dart';
import 'webview_page.dart';
import 'no_network.dart';

import 'dart:collection';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      Duration(seconds: 2),
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
        child: Hero(
          tag: 'icon',
          child: Icon(
            FontAwesomeIcons.hackerNewsSquare,
            color: Colors.deepOrange,
            size: 100.0,
          ),
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bloc = BlocProvider.of(context).bloc;
    return Scaffold(
      appBar: AppBar(
        leading: Opacity(
          opacity: .5,
          child: Hero(
            tag: 'icon',
            child: Icon(FontAwesomeIcons.hackerNewsSquare),
          ),
        ),
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
          IconButton(
            icon: Icon(Icons.settings_outlined),
            tooltip: 'Open settings',
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (context) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.brightness_medium_outlined,
                        color: Theme.of(context).accentColor,
                      ),
                      title: const Text('Dark Theme'),
                      trailing: Switch(
                        activeColor: Theme.of(context).accentColor,
                        value: themeProvider.isDarkTheme,
                        onChanged: MediaQuery.of(context).platformBrightness ==
                                Brightness.light
                            ? (val) async {
                                themeProvider.setTheme = val;
                                final prefs =
                                    await SharedPreferences.getInstance();
                                prefs.setBool('isDarkTheme', val);
                              }
                            : null,
                      ),
                    ),
                    AboutListTile(
                      icon: Icon(
                        Icons.info_outline,
                        color: Theme.of(context).accentColor,
                      ),
                      applicationName: 'Hacker News',
                      applicationVersion: '1.0.0',
                      applicationLegalese:
                          'This app is developed by Quentin Eppe. All Rights Reserved.',
                      applicationIcon: Icon(
                        FontAwesomeIcons.hackerNewsSquare,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<bool>(
        stream: bloc.isLoading,
        builder: (context, snapshot) {
          if (snapshot.data)
            return Center(
              child: CircularProgressIndicator(),
            );
          return StreamBuilder<UnmodifiableListView<Article>>(
            stream: bloc.articles,
            initialData: UnmodifiableListView<Article>([]),
            builder: (context, snapshot) {
              if (snapshot.hasData)
                return ListView(
                  children: snapshot.data.map(_buildItem).toList(),
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
            bloc.storiesType.add(
                index == 0 ? StoriesType.topStories : StoriesType.newStories);
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
  }

  Widget _buildItem(Article article) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ExpansionTile(
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