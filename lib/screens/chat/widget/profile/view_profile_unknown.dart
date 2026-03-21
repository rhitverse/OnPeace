import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/screens/chat/widget/profile/view_profile_screen.dart'
    show receiverProfileProvider;

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

class ViewProfileUnknown extends ConsumerWidget {
  final String receiverUid;
  final String receiverDisplayName;
  final String receiverProfilePic;

  const ViewProfileUnknown({
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
                  Container(height: 180, color: const Color(0xFFD4E8C2)),
                  Positioned(
                    bottom: 0,
                    left: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: backgroundColor, width: 3),
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
                          const SizedBox(width: 19),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: SvgPicture.asset(
                              "assets/svg/chat1.svg",
                              colorFilter: const ColorFilter.mode(
                                whiteColor,
                                BlendMode.srcIn,
                              ),
                              width: 32,
                              height: 32,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),

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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
