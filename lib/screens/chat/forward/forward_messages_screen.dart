import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/common/utils/utils.dart';
import 'package:on_peace/screens/chat/Screens/chats_control.dart';
import 'package:on_peace/screens/chat/provider/chat_provider.dart';
import 'package:on_peace/screens/chat/group/controller/group_chat_provider.dart';

class ForwardMessagesScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> messageData;
  final bool isGroupMessage;

  const ForwardMessagesScreen({
    super.key,
    required this.messageData,
    required this.isGroupMessage,
  });

  @override
  ConsumerState<ForwardMessagesScreen> createState() =>
      _ForwardMessagesScreenState();
}

class _ForwardMessagesScreenState extends ConsumerState<ForwardMessagesScreen> {
  late Future<List<ChatItem>> _chatsFuture;
  final Set<String> _selectedChats = <String>{};
  bool _isForwarding = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _chatsFuture = _loadChats();
  }

  Future<List<ChatItem>> _loadChats() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return [];

      final oneOnOneSnapshot = await FirebaseFirestore.instance
          .collection('Chats')
          .where('participants', arrayContains: userId)
          .get();

      final groupSnapshot = await FirebaseFirestore.instance
          .collection('GroupChats')
          .where('members', arrayContains: userId)
          .get();

      final chats = <ChatItem>[];

      for (final doc in oneOnOneSnapshot.docs) {
        final data = doc.data();
        final participants = (data['participants'] as List<dynamic>)
            .cast<String>();
        final receiverUid = participants.firstWhere((id) => id != userId);

        final receiverDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(receiverUid)
            .get();
        final receiverData = receiverDoc.data() ?? {};

        chats.add(
          ChatItem(
            chatId: doc.id,
            chatType: 'oneOnOne',
            name:
                receiverData['displayname'] ??
                receiverData['name'] ??
                'Unknown',
            profilePic: receiverData['profilePic'] ?? '',
            lastMessage: data['lastMessage'] ?? '',
            lastMessageTime:
                (data['lastMessageTime'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            receiverUid: receiverUid,
            members: participants,
            unreadCount: data['unreadCount_$userId'] ?? 0,
          ),
        );
      }

      for (final doc in groupSnapshot.docs) {
        final data = doc.data();
        final members = (data['members'] as List<dynamic>).cast<String>();

        chats.add(
          ChatItem(
            chatId: doc.id,
            chatType: 'group',
            name: data['groupName'] ?? 'Group',
            profilePic: data['groupProfilePic'] ?? '',
            lastMessage: data['lastMessage'] ?? '',
            lastMessageTime:
                (data['lastMessageTime'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            receiverUid: '',
            members: members,
            unreadCount: data['unreadCount_$userId'] ?? 0,
          ),
        );
      }

      return chats;
    } catch (e) {
      debugPrint('Error loading chats: $e');
      return [];
    }
  }

  Future<void> _forwardMessages() async {
    if (_selectedChats.isEmpty) {
      showSnackBar(
        context: context,
        content: 'Please select at least one chat',
      );
      return;
    }

    setState(() => _isForwarding = true);

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) throw Exception('Not authenticated');

      final messageText = widget.messageData['text'] as String? ?? '';
      final mediaUrl = widget.messageData['mediaUrl'] as String?;
      final mediaType = widget.messageData['mediaType'] as String?;
      final fileName = widget.messageData['fileName'] as String?;
      final fileSize = widget.messageData['fileSize'] as int?;

      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      final senderName = currentUserDoc.data()?['displayname'] ?? 'Unknown';
      final senderProfilePic = currentUserDoc.data()?['profilePic'] ?? '';

      final chatController = ref.read(chatControllerProvider);
      final groupChatController = ref.read(groupChatControllerProvider);

      for (final chatId in _selectedChats) {
        final chatItem = await _getChatItem(chatId);
        if (chatItem == null) continue;

        if (chatItem.chatType == 'oneOnOne') {
          if (messageText.isNotEmpty) {
            await chatController.sendMessage(
              chatId: chatId,
              senderId: currentUserId,
              text: messageText,
              receiverId: chatItem.receiverUid,
            );
          }
          if (mediaUrl != null && mediaType != null) {
            // Send media via controller for one-on-one chats
            try {
              await chatController.forwardMedia(
                chatId: chatId,
                senderId: currentUserId,
                receiverId: chatItem.receiverUid,
                mediaUrl: mediaUrl,
                mediaType: mediaType,
                fileName: fileName,
                fileSize: fileSize,
              );
            } catch (e) {
              debugPrint('Error sending media to one-on-one chat: $e');
              // Continue gracefully
            }
          }
        } else {
          // Send media first if it exists
          if (mediaUrl != null && mediaType != null) {
            try {
              await groupChatController.forwardMedia(
                groupId: chatId,
                senderId: currentUserId,
                senderName: senderName,
                senderProfilePic: senderProfilePic,
                mediaUrl: mediaUrl,
                mediaType: mediaType,
                fileName: fileName,
                fileSize: fileSize,
              );
            } catch (e) {
              debugPrint('Error sending media to group: $e');
              // Continue with text message even if media fails
            }
          }

          // Send text if it exists (independently if media also exists)
          if (messageText.isNotEmpty) {
            await groupChatController.sendMessage(
              groupId: chatId,
              senderId: currentUserId,
              senderName: senderName,
              senderProfilePic: senderProfilePic,
              text: messageText,
            );
          }
        }
      }

      if (!mounted) return;
      showSnackBar(
        context: context,
        content: 'Message forwarded successfully!',
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showSnackBar(context: context, content: 'Failed to forward message');
      debugPrint('Error forwarding message: $e');
    } finally {
      if (mounted) {
        setState(() => _isForwarding = false);
      }
    }
  }

  Future<ChatItem?> _getChatItem(String chatId) async {
    try {
      final oneOnOneDoc = await FirebaseFirestore.instance
          .collection('Chats')
          .doc(chatId)
          .get();
      if (oneOnOneDoc.exists) {
        final data = oneOnOneDoc.data() ?? {};
        final userId = FirebaseAuth.instance.currentUser?.uid;
        final participants = (data['participants'] as List<dynamic>)
            .cast<String>();
        final receiverUid = participants.firstWhere((id) => id != userId);

        final receiverDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(receiverUid)
            .get();
        final receiverData = receiverDoc.data() ?? {};

        return ChatItem(
          chatId: chatId,
          chatType: 'oneOnOne',
          name:
              receiverData['displayname'] ?? receiverData['name'] ?? 'Unknown',
          profilePic: receiverData['profilePic'] ?? '',
          lastMessage: data['lastMessage'] ?? '',
          lastMessageTime:
              (data['lastMessageTime'] as Timestamp?)?.toDate() ??
              DateTime.now(),
          receiverUid: receiverUid,
          members: participants,
          unreadCount: 0,
        );
      }

      final groupDoc = await FirebaseFirestore.instance
          .collection('GroupChats')
          .doc(chatId)
          .get();
      if (groupDoc.exists) {
        final data = groupDoc.data() ?? {};
        final members = (data['members'] as List<dynamic>).cast<String>();

        return ChatItem(
          chatId: chatId,
          chatType: 'group',
          name: data['groupName'] ?? 'Group',
          profilePic: data['groupProfilePic'] ?? '',
          lastMessage: data['lastMessage'] ?? '',
          lastMessageTime:
              (data['lastMessageTime'] as Timestamp?)?.toDate() ??
              DateTime.now(),
          receiverUid: '',
          members: members,
          unreadCount: 0,
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error getting chat item: $e');
      return null;
    }
  }

  List<ChatItem> _getFilteredChats(List<ChatItem> chats) {
    if (_searchQuery.isEmpty) return chats;
    return chats
        .where(
          (chat) =>
              chat.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: whiteColor),
        ),
        title: const Text(
          'Forward Message',
          style: TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: FutureBuilder<List<ChatItem>>(
        future: _chatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: whiteColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading chats',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            );
          }

          final chats = snapshot.data ?? [];
          final filteredChats = _getFilteredChats(chats);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: searchBarColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: whiteColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    style: const TextStyle(color: whiteColor),
                    decoration: InputDecoration(
                      hintText: 'Search users and groups',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              if (_selectedChats.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.blue.withOpacity(0.2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedChats.length} selected',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selectedChats.clear()),
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: filteredChats.isEmpty
                    ? Center(
                        child: Text(
                          'No chats found',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredChats.length,
                        separatorBuilder: (_, __) => Divider(
                          color: whiteColor.withOpacity(0.05),
                          height: 1,
                          indent: 76,
                        ),
                        itemBuilder: (context, index) {
                          final chat = filteredChats[index];
                          final isSelected = _selectedChats.contains(
                            chat.chatId,
                          );

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedChats.remove(chat.chatId);
                                  } else {
                                    _selectedChats.add(chat.chatId);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedChats.add(chat.chatId);
                                          } else {
                                            _selectedChats.remove(chat.chatId);
                                          }
                                        });
                                      },
                                      activeColor: Colors.blue,
                                      checkColor: whiteColor,
                                    ),
                                    const SizedBox(width: 8),
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.grey[800],
                                      backgroundImage:
                                          chat.profilePic.isNotEmpty
                                          ? NetworkImage(chat.profilePic)
                                          : null,
                                      child: chat.profilePic.isEmpty
                                          ? Icon(
                                              chat.chatType == 'group'
                                                  ? Icons.group
                                                  : Icons.person,
                                              size: 24,
                                              color: Colors.grey[600],
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            chat.name,
                                            style: const TextStyle(
                                              color: whiteColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            chat.chatType == 'group'
                                                ? 'Group • ${chat.members.length} members'
                                                : 'Direct message',
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (_selectedChats.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isForwarding ? null : _forwardMessages,
                      child: _isForwarding
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  whiteColor,
                                ),
                              ),
                            )
                          : const Text(
                              'Forward',
                              style: TextStyle(
                                color: whiteColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
