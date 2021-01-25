import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share/share.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'auth.dart';
import 'webview_page.dart';
import 'article.dart';

class StarsPage extends StatefulWidget {
  @override
  _StarsPageState createState() => _StarsPageState();
}

class _StarsPageState extends State<StarsPage> {
  final auth = Auth();
  final user = FirebaseAuth.instance.currentUser;

  Future<List<Article>> _getArticles(List<int> ids) async {
    final futureArticles = ids.map((id) async {
      final res =
          await http.get('https://hacker-news.firebaseio.com/v0/item/$id.json');

      if (res.statusCode == 200) {
        final article = parseArticle(res.body);
        return article;
      }
      return null;
    });
    final articles = await Future.wait(futureArticles);
    return articles;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: const Text(
          'Your Stars',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(
              child: CircularProgressIndicator(),
            );
          return FutureBuilder<List<Article>>(
            future: _getArticles(List<int>.from(snapshot.data['stars'])),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(
                  child: CircularProgressIndicator(),
                );
              if (snapshot.data.isEmpty)
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.yellow,
                        size: 50.0,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'You have no stars yet',
                          style: TextStyle(fontSize: 24.0),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              return ListView.builder(
                itemCount: snapshot.data.length,
                itemBuilder: (context, index) {
                  final article = snapshot.data[index];
                  return StreamBuilder<User>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, userSnapshot) {
                      return StreamBuilder<DocumentSnapshot>(
                        stream: userSnapshot.data != null
                            ? FirebaseFirestore.instance
                                .collection('users')
                                .doc(userSnapshot.data.uid)
                                .snapshots()
                            : null,
                        builder: (context, starsSnapshot) {
                          bool isStar = false;
                          if (starsSnapshot.hasData) {
                            final List<int> stars =
                                List<int>.from(starsSnapshot.data['stars']);
                            isStar = stars.contains(article.id);
                          }
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ExpansionTile(
                              leading: userSnapshot.data != null
                                  ? IconButton(
                                      icon: Icon(isStar
                                          ? Icons.star
                                          : Icons.star_border),
                                      color: isStar ? Colors.yellow : null,
                                      onPressed: () {
                                        final docRef = FirebaseFirestore
                                            .instance
                                            .collection('users')
                                            .doc(userSnapshot.data.uid);
                                        if (isStar) {
                                          docRef.update({
                                            'stars': FieldValue.arrayRemove(
                                                [article.id]),
                                          });
                                        } else {
                                          docRef.update({
                                            'stars': FieldValue.arrayUnion(
                                                [article.id]),
                                          });
                                        }
                                      },
                                    )
                                  : null,
                              title: Text(
                                article.title ?? 'This article has no title',
                                style: TextStyle(fontSize: 24.0),
                              ),
                              subtitle:
                                  Text(article.by ?? 'No author provided'),
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    article.url != null
                                        ? IconButton(
                                            tooltip: 'Read full article',
                                            icon: Icon(Icons.launch),
                                            color:
                                                Theme.of(context).accentColor,
                                            onPressed: () =>
                                                Navigator.of(context).push(
                                              CupertinoPageRoute(
                                                builder: (context) =>
                                                    WebviewPage(
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
                                            color:
                                                Theme.of(context).accentColor,
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
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}