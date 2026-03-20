import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/screens/calls/controller/call_provider.dart';

class ViewProfileScreen extends ConsumerWidget {
  final String receiverUid;
  final String receiverDisplayName;
  final String receiverProfilePic;
  final String? dob; // optional date of birth
  final String? bio; // optional bio

  const ViewProfileScreen({
    super.key,
    required this.receiverUid,
    required this.receiverDisplayName,
    required this.receiverProfilePic,
    this.dob,
    this.bio,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: backgroundColor,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: whiteColor),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: whiteColor),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    height: 180,
                    color: const Color(0xFFD4E8C2),
                  ),

                  Positioned(
                    bottom: 0,
                    left: 20,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: backgroundColor,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 42,
                            backgroundImage: receiverProfilePic.isNotEmpty
                                ? NetworkImage(receiverProfilePic)
                                : null,
                            backgroundColor: Colors.grey.shade800,
                            child: receiverProfilePic.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 42,
                                    color: whiteColor,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: backgroundColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receiverDisplayName,
                    style: const TextStyle(
                      color: whiteColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),

                  if (dob != null && dob!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.cake_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dob!,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.person_add_alt_1,
                              size: 20,
                              color: whiteColor,
                            ),
                            label: const Text(
                              'Add Friend',
                              style: TextStyle(
                                color: whiteColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: uiColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.chat_bubble_outline,
                            color: whiteColor,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Message',
                        ),
                      ),

                      const SizedBox(width: 10),

                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.call_outlined,
                            color: whiteColor,
                            size: 20,
                          ),
                          onPressed: () {
                            ref
                                .read(callControllerProvider.notifier)
                                .startCall(
                                  receiverId: receiverUid,
                                  isVideo: false,
                                  context: context,
                                );
                          },
                          tooltip: 'Voice Call',
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Video call button
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.videocam_outlined,
                            color: whiteColor,
                            size: 20,
                          ),
                          onPressed: () {
                            ref
                                .read(callControllerProvider.notifier)
                                .startCall(
                                  receiverId: receiverUid,
                                  isVideo: true,
                                  context: context,
                                );
                          },
                          tooltip: 'Video Call',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bio card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bio',
                          style: TextStyle(
                            color: whiteColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (bio != null && bio!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            bio!,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Media / Shared files card placeholder
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Media, Links & Docs',
                          style: TextStyle(
                            color: whiteColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Block User',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
