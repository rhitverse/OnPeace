import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/models/call_model.dart';
import 'package:on_peace/screens/calls/controller/call_provider.dart';

class CallDetailsScreen extends ConsumerWidget {
  const CallDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Calls",
          style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert_outlined,
              size: 27,
              color: whiteColor,
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Keep query index-free; filter and sort in app.
        stream: FirebaseFirestore.instance
            .collection('calls')
            .limit(300)
            .snapshots(),
        builder: (context, snapshot) {
          // ── Loading ──
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: uiColor),
            );
          }

          // ── Error ──
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white60),
              ),
            );
          }

          // ── Empty ──
          final allDocs = snapshot.data?.docs ?? [];
          final calls =
              allDocs
                  .map(
                    (d) => CallModel.fromMap(d.data() as Map<String, dynamic>),
                  )
                  .where(
                    (call) =>
                        call.callerId == currentUserId ||
                        call.receiverId == currentUserId,
                  )
                  .toList()
                ..sort((a, b) {
                  final aTime =
                      a.startTime ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final bTime =
                      b.startTime ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return bTime.compareTo(aTime);
                });

          if (calls.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.call, color: Colors.white30, size: 60),
                  SizedBox(height: 12),
                  Text(
                    'Koi call history nahi',
                    style: TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // ── Call List ──
          return ListView.builder(
            itemCount: calls.length,
            itemBuilder: (context, index) {
              final call = calls[index];

              final bool isMissed =
                  call.status == 'rejected' ||
                  call.status == 'missed' ||
                  call.status == 'ringing';

              final bool isOutgoing = call.callerId == currentUserId;
              final String displayName = isOutgoing
                  ? call.receiverId
                  : call.callerName;

              String timeText = '';
              if (call.startTime != null) {
                final now = DateTime.now();
                final diff = now.difference(call.startTime!);
                if (diff.inDays == 0) {
                  timeText =
                      '${call.startTime!.hour.toString().padLeft(2, '0')}:${call.startTime!.minute.toString().padLeft(2, '0')}';
                } else if (diff.inDays == 1) {
                  timeText = 'Yesterday';
                } else {
                  timeText =
                      '${call.startTime!.day}/${call.startTime!.month}/${call.startTime!.year}';
                }
              }

              return ListTile(
                contentPadding: const EdgeInsets.only(left: 16, right: 6),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey.shade700,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14.5,
                    color: isMissed ? Colors.red : whiteColor,
                  ),
                ),
                subtitle: Row(
                  children: [
                    // ── Call Direction Icon ──
                    Icon(
                      isMissed
                          ? Icons.call_missed
                          : isOutgoing
                          ? Icons.call_made
                          : Icons.call_received,
                      size: 16,
                      color: isMissed ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isMissed
                          ? 'Missed'
                          : isOutgoing
                          ? 'Outgoing'
                          : 'Incoming',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    // ── Video/Voice indicator ──
                    if (call.isVideo) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.videocam, size: 14, color: Colors.grey),
                    ],
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeText,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    // ── Call Back Button ──
                    IconButton(
                      icon: Icon(
                        call.isVideo ? Icons.videocam : Icons.call,
                        color: uiColor,
                        size: 22,
                      ),
                      onPressed: () {
                        // Call back karo
                        ref
                            .read(callControllerProvider.notifier)
                            .startCall(
                              receiverId: isOutgoing
                                  ? call.receiverId
                                  : call.callerId,
                              isVideo: call.isVideo,
                              context: context,
                            );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
