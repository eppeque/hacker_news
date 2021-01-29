# Hacker News

Hacker News is a news site for developers and other geeks. The site provides an [API](https://github.com/HackerNews/API/blob/master/README.md) which is used by this application. This app is developed with [Flutter](https://flutter.dev/docs).

## Receiving the API data

The `Article` class is the translation of an article object from the API. The API data is received in the `HackerNewsBloc`. Three streams are accessible from this bloc:

* `articles`: Contains the articles received from the API
* `isLoading`: A boolean which is true if the articles are loading (this is used to display the `CircularProgressIndicator` while it's loading)
* `storiesType`: This stream is modified when the user switch between Top Stories and New Stories in the `BottomNavigationBar`. The articles are retrieved each time the type changes.

### How does the `HackerNewsBloc` work?

The operation of the Bloc can be hard to understand at first glance...

So here are the steps followed by the block to retrieve the articles:

* The default and so the first type is Top Stories
* We get the ids of the Top Stories
* Before proceeding to the recovery of the articles, we set `isLoading` to true
* We get an article for each id. The ID is used in the URL.
* We set `isLoading` to false when the articles are fetched
* We add the list of articles to the stream which is accessible from the entire app with a `StreamBuilder`.

NB: The `HackerNewsBloc` is accessible from the entire app too with the `BlocProvider` InheritedWidget.

## Contributing

You want to contribute to this project? Awesome! The steps to follow to be the best contributor are in the `CONTRIBUTING.md` file. Thank you in advance for your interest!