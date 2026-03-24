import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/screens/calls/controller/call_controller.dart';

class IncomingCallScreen extends ConsumerWidget {
  const IncomingCallScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callControllerProvider);
    final callNotifier = ref.read(callControllerProvider.notifier);

    final incomingCall = callState.incomingCall;
    if (incomingCall == null) {
      return const SizedBox.shrink();
    }

    // Safely access call properties with null checks
    final callerName = incomingCall.callerName ?? 'Unknown';
    final isVideo = incomingCall.isVideo ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Caller Avatar
            CircleAvatar(
              radius: 80,
              backgroundColor: Colors.grey[800],
              child: const Icon(Icons.person, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 30),

            // Caller Name
            Text(
              callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Call Type
            Text(
              isVideo ? '📹 Video Call' : '📞 Audio Call',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 50),

            // Accept & Reject Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Reject Button
                FloatingActionButton(
                  heroTag: 'reject',
                  onPressed: () => callNotifier.rejectCall(context),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end, color: Colors.white),
                ),

                // Accept Button
                FloatingActionButton(
                  heroTag: 'accept',
                  onPressed: () => callNotifier.acceptCall(context),
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.call, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
