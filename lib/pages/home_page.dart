import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Gemini gemini = Gemini.instance;

  List<ChatMessage> messages = [];

  ChatUser currentUser = ChatUser(
    id: "0",
    firstName: "User",
  );

  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "Gemini",
    profileImage:
        "https://images.seeklogo.com/logo-png/61/1/gemini-icon-logo-png_seeklogo-611605.png",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Chatbot Gemini"),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat(
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
      inputOptions: InputOptions(
      inputTextStyle: TextStyle(fontSize: 16),
      alwaysShowSend: true,
      inputDecoration: const InputDecoration(
        hintText: "Écrire un message...",
      ),
    ),
    );
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages.insert(0, chatMessage);
    });

    try {
      gemini.streamGenerateContent(chatMessage.text).listen((event) {
        final content = event.content?.parts
                ?.map((p) => (p as dynamic).text ?? "")
                .join("") ??
            "";

        ChatMessage? lastBotMessage =
            messages.isNotEmpty && messages.first.user.id == geminiUser.id
                ? messages.first
                : null;

        if (lastBotMessage != null) {
          final updatedMessage = ChatMessage(
            user: geminiUser,
            text: lastBotMessage.text + content,
            createdAt: lastBotMessage.createdAt,
          );

          setState(() {
            messages.removeAt(0);
            messages.insert(0, updatedMessage);
          });
        } else {
          final newMessage = ChatMessage(
            user: geminiUser,
            text: content,
            createdAt: DateTime.now(),
          );

          setState(() {
            messages.insert(0, newMessage);
          });
        }
      });
    } catch (e) {
      print("Erreur Gemini: $e");
    }
  }
}
