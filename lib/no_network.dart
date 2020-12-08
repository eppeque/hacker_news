import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class NoNetwork extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hacker News',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0.0,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).errorColor,
              size: 50.0,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'It looks like you\'re offline.',
                style: TextStyle(fontSize: 24.0),
              ),
            ),
            Text('Be online and restart the app!')
          ],
        ),
      ),
    );
  }
}