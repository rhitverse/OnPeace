import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/calls/service/zego_engine_service.dart';

class VoiceCallScreen extends StatefulWidget {
  final String remoteUserId;
  final String remoteUserName;
  final String remoteUserAvtar;
  final String roomId;

  const VoiceCallScreen({
    required this.remoteUserId,
    required this.remoteUserName,
    required this.remoteUserAvtar,
    required this.roomId,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  late ZegoEngineService _zegoService;
  int _callDuration = 0;
  late Future _initCallFuture;

  @override
  void initState() {
    super.initState();
    _zegoService = ZegoEngineService();

    _initCallFuture = _zegoService.startVoiceCall(
      roomId: widget.roomId,
      remoteUserId: widget.remoteUserId,
      remoteUserName: widget.remoteUserName,
    );

    _startCallTimer();
  }

  void _startCallTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
        _startCallTimer();
      }
    });
  }

  String _formatDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        body: FutureBuilder(
          future: _initCallFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blue.shade900, Colors.blue.shade700],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(widget.remoteUserAvtar),
                        backgroundColor: Colors.grey,
                      ),
                      SizedBox(height: 30),
                      Text(
                        widget.remoteUserName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: whiteColor,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Calling...',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      SizedBox(height: 30),
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation(uiColor),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 50),
                    SizedBox(height: 10),
                    Text('Call Failed: ${snapshot.error}'),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Go Back'),
                    ),
                  ],
                ),
              );
            }
            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.blue.shade900, Colors.blue.shade700],
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundImage: NetworkImage(widget.remoteUserAvtar),
                        backgroundColor: Colors.grey,
                      ),
                      SizedBox(height: 30),
                      Text(
                        widget.remoteUserName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: whiteColor,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        _formatDuration(_callDuration),
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _zegoService.toggleMicrophone();
                          setState(() {});
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _zegoService.isMicMuted
                                ? Colors.red
                                : Colors.grey[700],
                          ),
                          child: Icon(
                            _zegoService.isMicMuted ? Icons.mic_off : Icons.mic,
                            color: whiteColor,
                            size: 28,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _zegoService.toggleSpeaker();
                          setState(() {});
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _zegoService.isSpeakerOn
                                ? Colors.blue
                                : Colors.grey[700],
                          ),
                          child: Icon(
                            _zegoService.isSpeakerOn
                                ? Icons.speaker
                                : Icons.speaker_phone,
                            color: whiteColor,
                            size: 28,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await _zegoService.endCall();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                          child: Icon(
                            Icons.call_end,
                            color: whiteColor,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
