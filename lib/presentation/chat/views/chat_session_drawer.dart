import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewModels/chat_view_model.dart';
import 'composites_tools.dart';

class ChatDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chatViewModel = Provider.of<ChatViewModel>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Color.fromRGBO(51, 66, 78, 1),
            ),
            child: Text(
              'Chat Sessions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          // New Session comes first
          ListTile(
            leading: Icon(Icons.add),
            title: Text('New Session'),
            onTap: () {
              chatViewModel.addNewSession();
              Navigator.pop(context); // Close the drawer after creating a new session
            },
          ),
          // CompositeAi Tools comes second
          ListTile(
            leading: Icon(Icons.build), // Choose an appropriate icon
            title: Text('Composites Tools'),
            onTap: () {
              Navigator.pop(context); // Close the drawer after selection
              Navigator.push( // Navigate to CompositesAiTool page
                context,
                MaterialPageRoute(builder: (context) => CompositesTools()),
              );
            },
          ),
          // Chat sessions are listed last
          ...chatViewModel.sessions.map((session) {
            return ListTile(
              leading: Icon(Icons.chat),
              title: Text(session.title),
              onTap: () {
                chatViewModel.selectSession(session);
                Navigator.pop(context); // Close the drawer after selecting a session
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}
