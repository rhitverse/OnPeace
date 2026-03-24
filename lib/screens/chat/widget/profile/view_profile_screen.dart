import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final receiverProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, uid) async {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return doc.data();
    });

String _formatDob(String raw, bool showYear) {
  try {
    final dt = DateTime.parse(raw);
    return showYear
        ? DateFormat('dd MMMM yyyy').format(dt)
        : DateFormat('dd MMMM').format(dt);
  } catch (_) {
    return raw;
  }
}

class ViewProfileScreen extends ConsumerWidget {
  final String receiverUid;
  final String receiverDisplayName;
  final String receiverProfilePic;

  const ViewProfileScreen({
    super.key,
    required this.receiverUid,
    required this.receiverDisplayName,
    required this.receiverProfilePic,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(receiverProfileProvider(receiverUid));
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.188,
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
                    child: Container(
                      decoration: BoxDecoration(shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundImage: receiverProfilePic.isNotEmpty
                            ? NetworkImage(receiverProfilePic)
                            : null,
                        backgroundColor: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: profileAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  e.toString(),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              data: (data) {
                final bio = (data?['bio'] as String?)?.trim() ?? '';
                final rawDob = (data?['birthday'] as String?)?.trim() ?? '';

                final showBirthday = data?['showBirthday'] ?? true;
                final showBirthYear = data?['showBirthYear'] ?? true;

                final shouldShowDob = showBirthday && rawDob.isNotEmpty;

                final dobText = shouldShowDob
                    ? _formatDob(rawDob, showBirthYear)
                    : '';
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
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
                      if (shouldShowDob)
                        Row(
                          children: [
                            const Icon(
                              Icons.cake_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dobText,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            height: 42,
                            width: MediaQuery.of(context).size.width * 0.6,
                            decoration: BoxDecoration(
                              color: uiColor,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: () => Navigator.pop(context),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      "assets/svg/chat3.svg",
                                      colorFilter: const ColorFilter.mode(
                                        whiteColor,
                                        BlendMode.srcIn,
                                      ),
                                      width: 38,
                                      height: 38,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Chat',
                                      style: TextStyle(
                                        color: whiteColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          _buildCircularIcon(
                            child: SvgPicture.asset(
                              'assets/svg/call1.svg',
                              colorFilter: const ColorFilter.mode(
                                whiteColor,
                                BlendMode.srcIn,
                              ),
                              width: 32,
                              height: 32,
                            ),
                            onTap: () {
                              /*  ref
                                  .read(callControllerProvider.notifier)
                                  .startCall(
                                    receiverId: receiverUid,
                                    isVideo: false,
                                    context: context,
                                  );*/
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildCircularIcon(
                            onTap: () {
                              /* ref
                                  .read(callControllerProvider.notifier)
                                  .startCall(
                                    receiverId: receiverUid,
                                    isVideo: true,
                                    context: context,
                                  );*/
                            },
                            child: SvgPicture.asset(
                              'assets/svg/videocall.svg',
                              colorFilter: const ColorFilter.mode(
                                whiteColor,
                                BlendMode.srcIn,
                              ),
                              width: 32,
                              height: 32,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (bio.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: attacment,
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
                                  const SizedBox(height: 6),
                                  Text(
                                    bio,
                                    style: const TextStyle(
                                      color: whiteColor,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularIcon({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: container, shape: BoxShape.circle),
        child: child,
      ),
    );
  }
}
