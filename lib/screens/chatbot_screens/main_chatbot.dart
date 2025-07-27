import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'dart:async';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:legallyai/screens/main_screen.dart';
import 'package:legallyai/services/chat_web_service.dart';
import 'chat_threads.dart';

class ChatbotScreen extends StatefulWidget {
  String? uid;
  String? chat_id;
  ChatbotScreen({super.key, this.uid, this.chat_id});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final StreamController<String> _responseController = StreamController<String>.broadcast();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int messageIndex = 0;
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser assistant = ChatUser(id: "1", firstName: "Legally AI");
  bool isLoading = true;
  String fullResponse = "";
  late StreamSubscription<DocumentSnapshot> _chatSubscription;
  var inputController = TextEditingController();
  Map<String, dynamic>? chatData;
  var question = TextEditingController();
  final chatService = ChatWebService();
  List<ChatMessage> messages = [];
  StreamSubscription? _contentSubscription;
  bool _isConnecting = false;
  bool isWaitingForResponse = false;
  List<ChatUser> get typingUsers => isWaitingForResponse ? [assistant] : [];
 late StreamSubscription<Map<String, dynamic>?> _chatListener;  // Changed type here

  @override
  void initState() {
    super.initState();
    if (!chatService.isConnected) {
      _setupChatService();
    }
    _loadExistingMessages();
    _setupFirebaseListener(); // Add this line
  }
@override
void dispose() {
  _contentSubscription?.cancel();
  if (_chatListener != null) {
    _chatListener.cancel();
  }
  _responseController.close();
  chatService.dispose();
  setState(() {
    isWaitingForResponse = false;
    _isConnecting = false;
  });
  super.dispose();
}


  final List<String> texts = [
    'Review Legal Documents\n(Upload documents to get summaries, key points, and important highlights.)',
    'Answer Your Legal Questions\n(Ask about legal terms, contracts, or clauses — I’ll explain them in simple terms.)',
    'Compare Documents\n(Spot differences between legal documents and identify changes easily.)'
  ];

  void deleteEmptyChat() async {
    try {
      var chatDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.uid)
          .collection("chats")
          .doc(widget.chat_id)
          .get();

      if (!chatDoc.exists) return;

      var data = chatDoc.data()!;
      bool hasMessages = false;

      for (String key in data.keys) {
        if ((key.startsWith('user') || key.startsWith('assistant')) &&
            data[key] != null &&
            data[key].toString().trim().isNotEmpty) {
          hasMessages = true;
          break;
        }
      }

      if (!hasMessages) {
        var allChats = await FirebaseFirestore.instance
            .collection("users")
            .doc(widget.uid)
            .collection("chats")
            .orderBy('timestamp', descending: true)
            .get();

        if (allChats.docs.isNotEmpty && allChats.docs.first.id != widget.chat_id) {
          await FirebaseFirestore.instance
              .collection("users")
              .doc(widget.uid)
              .collection("chats")
              .doc(widget.chat_id)
              .delete();
        }
      }
    } catch (e) {
      print('Error deleting empty chat: $e');
    }
  }

  void _navigateToMainScreen() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => MainScreen(uid: widget.uid),
      ),
      (Route<dynamic> route) => false,
    );
    deleteEmptyChat();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _navigateToMainScreen,
          ),
          actions: [
            IconButton(
              onPressed: () async {
                deleteEmptyChat();
                var chat_id = await FirebaseFirestore.instance
                    .collection("users")
                    .doc(widget.uid)
                    .collection("chats")
                    .add({
                  'timestamp': FieldValue.serverTimestamp(),
                });

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatbotScreen(uid: widget.uid, chat_id: chat_id.id)),
                );
              },
              icon: Icon(Icons.add_circle_outline_outlined),
            ),
            IconButton(
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
              icon: Icon(Icons.menu),
            ),
          ],
          elevation: 1,
          backgroundColor: Color(0xFF2A2A3C),
          foregroundColor: Colors.white,
          title: Text(
            "Chatbot",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        endDrawer: ChatThreadsDrawer(
          uid: widget.uid!,
          currentChatId: widget.chat_id!,
          onChatSelected: _onChatSelected,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Expanded(
                  child: buildUIChat(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildUIChat() {
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? chatInfo(texts: texts)
              : Theme(
                  data: Theme.of(context).copyWith(
                    textTheme: Theme.of(context).textTheme.copyWith(
                          bodyMedium: const TextStyle(
                            fontSize: 24,
                            color: Colors.black,
                          ),
                        ),
                  ),
                  child: DashChat(
                    currentUser: currentUser,
                    onSend: (ChatMessage message) {
                    if (!isWaitingForResponse) {
                      sendMessage(message);
                    } else {
                      // Optionally show a snackbar to inform the user
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please wait for the assistant to respond.'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Colors.grey.shade700,
                        ),
                      );
                    }
                  },
                    messages: messages,
                   
                    inputOptions: InputOptions(
                      alwaysShowSend: true,
                      sendButtonBuilder: (Function onSend) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Material(
                            color: isWaitingForResponse 
                              ? Colors.grey.shade300  // Grayed out when waiting
                              : Theme.of(context).primaryColor,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: isWaitingForResponse 
                                ? null 
                                : () => onSend(),  // Disable tap when waiting
                              customBorder: const CircleBorder(),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.send,
                                  color: isWaitingForResponse 
                                    ? Colors.grey.shade500 
                                    : Color(0xFF2A2A3C),
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      sendOnEnter: true,
                      textController: inputController,
                      inputTextStyle: const TextStyle(color: Colors.black87),
                      inputDecoration: InputDecoration(
                        hintText: isWaitingForResponse 
                          ? 'Please wait for the assistant to respond...' 
                          : 'Ask me anything...',
                        hintStyle: TextStyle(
                          color: isWaitingForResponse ? Colors.grey.shade500 : Colors.black54,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        filled: isWaitingForResponse,  // Add background color when waiting
                        fillColor: isWaitingForResponse ? Colors.grey.shade100 : null,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: isWaitingForResponse ? Colors.grey.shade300 : Colors.grey,
                            width: 1
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: isWaitingForResponse 
                              ? Colors.grey.shade300 
                              : Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    messageOptions: MessageOptions(
                      messageTextBuilder: (message, previousMessage, nextMessage) {
                        return Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.black,
                            fontWeight: FontWeight.normal,
                          ),
                        );
                      },
                      showTime: false,
                      borderRadius: 10,
                      currentUserContainerColor: Color(0xFFD6AF38),
                      containerColor: Color(0xFFE7E7E7),
                      currentUserTextColor: Colors.black,
                      textColor: Colors.black,
                    ),
                    typingUsers: typingUsers,
                    messageListOptions: const MessageListOptions(
                      showDateSeparator: true,
                    ),
                  ),
                ),
        ),
          if (messages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: inputController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: isWaitingForResponse 
                          ? 'Please wait for the assistant to respond...' 
                          : 'Ask me anything...',
                        hintStyle: TextStyle(
                          color: isWaitingForResponse ? Colors.grey.shade500 : Colors.black54
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        filled: isWaitingForResponse,
                        fillColor: isWaitingForResponse ? Colors.grey.shade100 : null,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: isWaitingForResponse ? Colors.grey.shade300 : Colors.grey,
                            width: 1
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: isWaitingForResponse 
                              ? Colors.grey.shade300 
                              : Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      onSubmitted: (text) {
                        if (!isWaitingForResponse && text.trim().isNotEmpty) {
                          final message = ChatMessage(
                            text: text,
                            user: currentUser,
                            createdAt: DateTime.now(),
                          );
                          sendMessage(message);
                          inputController.clear();
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Material(
                      color: isWaitingForResponse 
                        ? Colors.grey.shade300 
                        : Theme.of(context).primaryColor,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: isWaitingForResponse
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please wait for the assistant to respond.'),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Colors.grey.shade700,
                                ),
                              );
                            }
                          : () {
                              if (inputController.text.trim().isNotEmpty) {
                                final message = ChatMessage(
                                  text: inputController.text,
                                  user: currentUser,
                                  createdAt: DateTime.now(),
                                );
                                sendMessage(message);
                                inputController.clear();
                              }
                            },
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.send,
                            color: isWaitingForResponse 
                              ? Colors.grey.shade500 
                              : Color(0xFF2A2A3C),
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

 // In the ChatbotScreen class, modify the sendMessage method:
void sendMessage(ChatMessage chatMessage) async {
  if (chatMessage.text.trim().isEmpty || isWaitingForResponse) return;

  final messageText = chatMessage.text.trim();

  setState(() {
    // Add new message to the end of the list
    // messages = [...messages.where((m) => m.user.id == currentUser.id), chatMessage];
    messages = [chatMessage, ...messages];
    isWaitingForResponse = true;
    fullResponse = "";
  });

  try {
    // Only update the timestamp when sending a new message
    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.uid)
        .collection("chats")
        .doc(widget.chat_id)
        .update({
      
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Send message to chat service
    bool messageSent = await chatService.chat(
      messageText,
      widget.chat_id!,
      widget.uid!,
    );

    if (!messageSent) {
      setState(() {
        isWaitingForResponse = false;
        messages = [
          ChatMessage(
            text: "⚠️ Sorry, I couldn't process your request. Please try again.",
            user: assistant,
            createdAt: DateTime.now(),
          ),
          ...messages
        ];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Server is not responding. Please try again.'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              if (!isWaitingForResponse) {
                sendMessage(chatMessage);
              }
            },
          ),
        ),
      );
    }
  } catch (e) {
    print('Error in sendMessage: $e');
    setState(() {
      isWaitingForResponse = false;
      messages = [
        ChatMessage(
          text: "⚠️ An error occurred. Please try again.",
          user: assistant,
          createdAt: DateTime.now(),
        ),
        ...messages
      ];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Failed to send message. Please try again.'),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            if (!isWaitingForResponse) {
              sendMessage(chatMessage);
            }
          },
        ),
      ),
    );
  }
}
void _setupFirebaseListener() {
  _chatListener = FirebaseFirestore.instance
      .collection("users")
      .doc(widget.uid)
      .collection("chats")
      .doc(widget.chat_id)
      .snapshots(includeMetadataChanges: false)
      .map((snapshot) {
        if (!snapshot.exists) return null;
        var data = snapshot.data()!;
        return Map.fromEntries(
          data.entries.where((entry) => entry.key.startsWith('assistant'))
        );
      })
      .listen((filteredData) {
        if (filteredData == null) return;

        if (filteredData.containsKey('assistant$messageIndex')) {
          String assistantMessage = _cleanMessage(filteredData['assistant$messageIndex']);
          
          setState(() {
            isWaitingForResponse = false;  // Make sure this gets set to false
            List<ChatMessage> newMessages = List.from(messages);
            
            // Find the last user message without a response
            int lastUserMessageIndex = -1;
            bool hasResponse = false;
            for (int i = 0; i < newMessages.length; i++) {
              if (newMessages[i].user.id == currentUser.id) {
                if (!hasResponse) {
                  lastUserMessageIndex = i;
                  break;
                }
                hasResponse = false;
              } else if (newMessages[i].user.id == assistant.id) {
                hasResponse = true;
              }
            }

            if (lastUserMessageIndex != -1) {
              // Insert new assistant message after the last user message
              newMessages.insert(lastUserMessageIndex, ChatMessage(
                text: assistantMessage,
                user: assistant,
                createdAt: DateTime.now(),
              ));
            } else {
              // If no user message found, add to the beginning
              newMessages.insert(0, ChatMessage(
                text: assistantMessage,
                user: assistant,
                createdAt: DateTime.now(),
              ));
            }
            
            messages = newMessages;
            messageIndex++;
          });
        }
      }, onError: (error) {
        print('Error in Firebase listener: $error');
        setState(() {
          isWaitingForResponse = false;  // Make sure to reset the waiting state on error
        });
      });
}
void _setupChatService() {
  setState(() => _isConnecting = true);

  try {
    chatService.connect();
    _contentSubscription?.cancel();
    _contentSubscription = chatService.contentSream.listen(
      (data) {
        bool isComplete = data['done'] ?? false;
        if (isComplete) {
          setState(() {
            isWaitingForResponse = false;  // Make sure this gets set to false when done
          });
        }
      },
      onError: (error) {
        print('Error receiving message: $error');
        setState(() {
          _isConnecting = false;
          isWaitingForResponse = false;  // Reset waiting state on error
          messages = [
            ChatMessage(
              text: "⚠️ Connection error. Please try again.",
              user: assistant,
              createdAt: DateTime.now(),
            ),
            ...messages
          ];
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error. Please try again later.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _setupChatService(),
            ),
          ),
        );
      },
    );
  } catch (e) {
    print('Error in _setupChatService: $e');
    setState(() {
      _isConnecting = false;
      isWaitingForResponse = false;
      messages = [
        ChatMessage(
          text: "⚠️ Failed to connect to server. Please try again.",
          user: assistant,
          createdAt: DateTime.now(),
        ),
        ...messages
      ];
    });
  }
}
  void _loadExistingMessages() async {
    try {
      setState(() {
        messages = [];
        isLoading = true;
        messageIndex = 0;
      });

      var chatDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.uid)
          .collection("chats")
          .doc(widget.chat_id)
          .get();

      if (!chatDoc.exists) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      var data = chatDoc.data()!;
      List<MessagePair> messagePairs = [];
      Set<int> userIndices = {};
      Set<int> assistantIndices = {};

      data.forEach((key, value) {
        if (key == 'timestamp') return;
        if (key.startsWith('user')) {
          userIndices.add(int.parse(key.substring(4)));
        } else if (key.startsWith('assistant')) {
          assistantIndices.add(int.parse(key.substring(9)));
        }
      });

      int maxContinuousIndex = -1;
      for (int i = 0; i < 1000; i++) {
        if (!userIndices.contains(i) && !assistantIndices.contains(i)) {
          maxContinuousIndex = i - 1;
          break;
        }
        maxContinuousIndex = i;
      }

      for (int i = 0; i <= maxContinuousIndex; i++) {
        String? userMessage = data['user$i']?.toString();
        String? assistantMessage = data['assistant$i']?.toString();

        if (userMessage != null || assistantMessage != null) {
          var pair = MessagePair(index: i);

          if (userMessage != null) {
            pair.userMessage = ChatMessage(
              text: _cleanMessage(userMessage),
              user: currentUser,
              createdAt: DateTime.now(),
            );
          }

          if (assistantMessage != null) {
            pair.assistantMessage = ChatMessage(
              text: _cleanMessage(assistantMessage),
              user: assistant,
              createdAt: DateTime.now(),
            );
          }

          messagePairs.add(pair);
        }
      }

      List<ChatMessage> sortedMessages = [];
      for (var pair in messagePairs) {
        if (pair.userMessage != null) {
          sortedMessages.add(pair.userMessage!);
        }
        if (pair.assistantMessage != null) {
          sortedMessages.add(pair.assistantMessage!);
        }
      }

      // Set messageIndex to next available index
      messageIndex = maxContinuousIndex + 1;

      setState(() {
        messages = sortedMessages.reversed.toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading messages: $e');
      setState(() {
        isLoading = false;
        messages = [];
      });
    }
  }

void _onChatSelected(String chatId) {
  if (chatId == widget.chat_id) return;

  // Cancel existing listeners
  _chatListener.cancel();
  _contentSubscription?.cancel();

  setState(() {
    widget.chat_id = chatId;
    messages = [];
    isLoading = true;
    messageIndex = 0;
    isWaitingForResponse = false;  // Reset the waiting state
  });

  // Reload messages and set up new listeners
  _loadExistingMessages();
  _setupFirebaseListener();
  _setupChatService();
}
}

class chatInfo extends StatelessWidget {
  const chatInfo({
    super.key,
    required this.texts,
  });

  final List<String> texts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Gap(30),
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).primaryColor.withOpacity(0.1),
          ),
          child: Icon(Icons.document_scanner_rounded,
              size: 64, color: Theme.of(context).primaryColor),
        ),
        const Gap(30),
        Text(
          "Capabilities",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
        const Gap(20),
        Expanded(
          child: ListView.separated(
            itemCount: texts.length,
            separatorBuilder: (_, __) => const Gap(16),
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  texts[index],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                        height: 1.4,
                      ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
        const Gap(12),
        Text(
          "These are just a few examples of what I can do.",
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const Gap(20),
      ],
    );
  }
}

class MessagePair {
  final int index;
  ChatMessage? userMessage;
  ChatMessage? assistantMessage;

  MessagePair({
    required this.index,
    this.userMessage,
    this.assistantMessage,
  });
}

String _cleanMessage(String message) {
  return message
      .replaceAll(RegExp(r'Current Date and Time.*?\n', multiLine: true), '')
      .replaceAll(RegExp(r"Current User\'s Login:.*?\n", multiLine: true), '')
      .replaceAll(RegExp(r'Instructions for Response:.*?Response:', dotAll: true), '')
      .replaceAll(RegExp(r'Previous conversation:.*?\n', multiLine: true), '')
      .replaceAll(RegExp(r'Context from knowledge base:.*?\n', multiLine: true), '')
      .replaceAll(RegExp(r'Current query:.*?\n', multiLine: true), '')
      .trim();
}