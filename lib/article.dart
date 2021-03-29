import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import 'serializers.dart';

import 'dart:convert';

part 'article.g.dart';

/// Article class to access the different fields of a Hacker News article
abstract class Article implements Built<Article, ArticleBuilder> {
  static Serializer<Article> get serializer => _$articleSerializer;

  /// The item's unique id.
  int? get id;

  /// `true` if the item is deleted.
  bool? get deleted;

  /// The type of item. One of "job", "story", "comment", "poll", or "pollopt".
  String? get type;

  /// The username of the item's author.
  String? get by;

  /// Creation date of the item, in Unix Time.
  int? get time;

  /// The comment, story or poll text. HTML.
  String? get text;

  /// `true` if the item is dead.
  bool? get dead;

  /// The comment's parent: either another comment or the relevant story.
  int? get parent;

  /// The pollopt's associated poll.
  int? get poll;

  /// The ids of the item's comments, in ranked display order.
  BuiltList<int>? get kids;

  /// The URL of the story.
  String? get url;

  /// The story's score, or the votes for a pollopt.
  int? get score;

  /// The title of the story, poll or job. HTML.
  String? get title;

  /// A list of related pollopts, in display order.
  BuiltList<int>? get parts;

  /// In the case of stories or polls, the total comment count.
  int? get descendants;

  Article._();
  factory Article([void Function(ArticleBuilder)? updates]) = _$Article;
}

/// Parses json list of int in a Dart one
List<int> parseIds(String jsonString) {
  final parsed = jsonDecode(jsonString);
  final ids = List<int>.from(parsed);
  return ids;
}

/// Parses an article json object in the Article Dart class 
Article parseArticle(String jsonString) {
  final parsed = jsonDecode(jsonString);
  final article = standardSerializers.deserializeWith(Article.serializer, parsed);
  return article!;
}