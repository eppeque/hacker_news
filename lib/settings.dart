import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'theme_provider.dart';

import 'auth.dart';

void showSettingsPage(
    BuildContext context, ThemeProvider themeProvider, User user) {
  final auth = Auth();

  showModalBottomSheet(
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
              onChanged:
                  MediaQuery.of(context).platformBrightness == Brightness.light
                      ? (val) async {
                          themeProvider.setTheme = val;
                          final prefs = await SharedPreferences.getInstance();
                          prefs.setBool('isDarkTheme', val);
                        }
                      : null,
            ),
          ),
          user == null
              ? ListTile(
                  leading: Icon(
                    FontAwesomeIcons.google,
                    color: Theme.of(context).accentColor,
                  ),
                  title: const Text('Sign in with Google'),
                  subtitle: const Text(
                    'By logging in, you can mark the articles as favorites',
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await auth.signIn();

                    final docRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid);
                    final doc = await docRef.get();

                    if (!doc.exists) {
                      docRef.set({
                        'stars': [],
                      });
                    }
                  },
                )
              : ListTile(
                  leading: Icon(
                    Icons.clear,
                    color: Theme.of(context).accentColor,
                  ),
                  title: const Text('Sign out'),
                  onTap: () async {
                    await auth.signOut();
                    Navigator.of(context).pop();
                  },
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
  );
}