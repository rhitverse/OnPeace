import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/screens/calls/controller/call_provider.dart';

class IncomingCallOverlay extends ConsumerWidget {
  final Widget child;
  const IncomingCallOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callControllerProvider);
    final incomingCall = callState.incomingCall;

    return Stack(
      children: [
        child,

        if (incomingCall != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.only(top: 40, left: 12, right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2C34),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // ── Avatar ──
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),

                    // ── Caller Info ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            incomingCall.callerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                incomingCall.isVideo
                                    ? Icons.videocam
                                    : Icons.call,
                                color: Colors.green,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                incomingCall.isVideo
                                    ? 'Incoming Video Call'
                                    : 'Incoming Voice Call',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── DECLINE BUTTON (Red) ──
                    GestureDetector(
                      onTap: () {
                        ref.read(callControllerProvider.notifier).rejectCall();
                      },
                      child: const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.red,
                        child: Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ── ACCEPT BUTTON (Green) ──
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(callControllerProvider.notifier)
                            .acceptCall(context);
                      },
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.green.shade600,
                        child: Icon(
                          incomingCall.isVideo ? Icons.videocam : Icons.call,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
