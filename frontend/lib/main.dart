import 'package:flutter/material.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat with Backend',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class Message {
  final String text;
  final bool isUser;
  Message(this.text, this.isUser);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // Replace this URL with your actual backend endpoint
  final String _backendUrl = 'http://127.0.0.1:5000/predict';

  @override
  void initState() {
    super.initState();
    // Optional: Add a welcome message from the bot
    _messages.add(Message('Hello! Enter a subject and body, then press Send.', false));
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();

    if (subject.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both subject and body')),
      );
      return;
    }

    if (_isLoading) return;

    // Create the user's message text
    final userMessageText = 'Subject: $subject\nMessage: $body';

    // Add user message to chat
    setState(() {
        _messages.add(Message(userMessageText, true));
        _subjectController.clear();
        _bodyController.clear();
        _isLoading = true;
    });
    _scrollToBottom();

    // Prepare JSON payload
    final Map<String, String> payload = {
      'subject': subject,
      'body': body,
    };

    try {
      // Send POST request to backend
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Parse the echoed data from httpbin (or adapt to your backend's response)
        String replyText;
        if (responseData.containsKey('json')) {
          final echoedData = responseData['json'] as Map<String, dynamic>;
          replyText = '✅ Backend received:\n'
          'Subject: ${echoedData['subject']}\n'
          'Body: ${echoedData['body']}';
        } else {
          // Fallback in case response format is different
          final Map<String, dynamic> responseDecodedData = jsonDecode(response.body);
          String replySubject = responseDecodedData['subject']?.toString() ?? '(no subject)';
          String replyBody = responseDecodedData['body']?.toString() ?? '(no response)';

          replyText= '📩 Response from server\n\n'
          'Subject: $replySubject\n\n'
          'Prediction: $replyBody';
          // replyText = '✅ Response from server:\n${response.body}';
        }

        setState(() {
            _messages.add(Message(replyText, false));
        });
      } else {
        setState(() {
            _messages.add(Message('❌ Server error: ${response.statusCode}', false));
        });
      }
    } catch (e) {
      setState(() {
          _messages.add(Message('❌ Failed to connect: $e', false));
      });
    } finally {
      setState(() {
          _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Backend'),
        elevation: 2,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat messages area (app-like interface at top)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: BubbleNormal(
                      text: message.text,
                      isSender: message.isUser,
                      color: message.isUser
                      ? Colors.blue.shade400
                      : Colors.grey.shade300,
                      textStyle: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                      tail: true,
                    ),
                  );
                },
              ),
            ),
            // Input fields and button at bottom
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                    color: Colors.black.withOpacity(0.05),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bodyController,
                      decoration: const InputDecoration(
                        labelText: 'Body',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      maxLines: 3,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendMessage,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                        ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Sending...'),
                          ],
                        )
                        : const Text('Send Message'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
