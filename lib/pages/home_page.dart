import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];
  StreamSubscription? _streamSubscription;

  ChatUser currentUser = ChatUser(
    id: "0",
    firstName: "Utilisateur",
  );

  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "Gemini",
  );

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

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
      inputOptions: const InputOptions(
        inputTextStyle: TextStyle(fontSize: 16),
        alwaysShowSend: true,
        inputDecoration: InputDecoration(
          hintText: "Écrire un message...",
        ),
      ),
    );
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages.insert(0, chatMessage);
    });

 
    ChatMessage typingMessage = ChatMessage(
      user: geminiUser,
      text: "En train d'écrire...",
      createdAt: DateTime.now(),
    );

    setState(() {
      messages.insert(0, typingMessage);
    });

    String accumulatedResponse = "";

    try {
      _streamSubscription?.cancel();
      
      _streamSubscription = gemini.streamGenerateContent(chatMessage.text).listen(
        (event) {
          final content = event.content?.parts
                  ?.map((p) => (p as dynamic).text ?? "")
                  .join("") ??
              "";

          accumulatedResponse += content;

          final updatedMessage = ChatMessage(
            user: geminiUser,
            text: accumulatedResponse.isEmpty ? "..." : accumulatedResponse,
            createdAt: typingMessage.createdAt,
          );

          setState(() {
            messages.removeAt(0);
            messages.insert(0, updatedMessage);
          });
        },
        onError: (error) {
          print("Erreur Gemini: $error");
          
          setState(() {
            messages.removeAt(0);
            messages.insert(
              0,
              ChatMessage(
                user: geminiUser,
                text: "Erreur API : Vérifiez votre clé API Gemini dans consts.dart",
                createdAt: DateTime.now(),
              ),
            );
          });
        },
        onDone: () {
          print("Réponse complète reçue");
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("Erreur lors de l'envoi: $e");
      
      setState(() {
        if (messages.isNotEmpty && messages.first.user.id == geminiUser.id) {
          messages.removeAt(0);
        }
        messages.insert(
          0,
          ChatMessage(
            user: geminiUser,
            text: "Impossible de se connecter. Vérifiez votre connexion internet.",
            createdAt: DateTime.now(),
          ),
        );
      });
    }
  }
}