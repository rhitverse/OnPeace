/*import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/models/call_state.dart';
import 'package:whatsapp_clone/screens/calls/repository/call_repository.dart';
import 'package:whatsapp_clone/screens/calls/controller/call_controller.dart';

final callRepositoryProvider = Provider<CallRepository>((ref) {
  return CallRepository();
});

final callControllerProvider = StateNotifierProvider<CallController, CallState>(
  (ref) {
    final repo = ref.watch(callRepositoryProvider);
    return CallController(repo: repo, ref: ref);
  },
);*/
