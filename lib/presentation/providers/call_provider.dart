import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/call_entity.dart';
import '../../data/repositories/call_repository.dart';

class CallProvider extends ChangeNotifier {
  final CallRepository _callRepository = CallRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<CallEntity> _calls = [];
  bool _isLoading = false;
  CallEntity? _activeCall;

  List<CallEntity> get calls => _calls;
  bool get isLoading => _isLoading;
  CallEntity? get activeCall => _activeCall;

  void listenToCalls(String uid) {
    _isLoading = true;
    _callRepository.getCallHistory(uid).listen((calls) {
      _calls = calls;
      _isLoading = false;
      notifyListeners();
    });

    // Listen for incoming WebRTC offers
    _firestore.collection('calls_signaling')
      .where('receiverId', isEqualTo: uid)
      .where('status', isEqualTo: 'offered')
      .snapshots()
      .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data != null) {
              // Trigger incoming call event
              _onIncomingCall?.call(change.doc.id, data['callerId']);
            }
          }
        }
      });
  }

  Function(String roomId, String callerId)? _onIncomingCall;
  void setOnIncomingCall(Function(String, String) callback) {
    _onIncomingCall = callback;
  }

  Future<void> logCall(CallEntity call) async {
    await _callRepository.saveCall(call);
  }

  Future<void> startCall(CallEntity call) async {
    _activeCall = call;
    notifyListeners();
    await logCall(call);
  }

  void endCall() {
    _activeCall = null;
    notifyListeners();
  }
}
