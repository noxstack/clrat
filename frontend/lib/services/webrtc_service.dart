import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  WebSocketChannel? _signalingChannel;

 Future<void> connectSignaling(String wsUrl) async {
  _signalingChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
  _signalingChannel!.stream.listen((message) {
    final data = jsonDecode(message);
    if (data['type'] == 'answer') {
      _peerConnection!.setRemoteDescription(RTCSessionDescription(
        data['sdp'],
        data['type'],
      ));
    } else if (data['type'] == 'ice_candidate') {
      _peerConnection!.addCandidate(RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      ));
    }
  });
}

Future<void> sendOffer() async {
  final offer = await _peerConnection!.createOffer();
  await _peerConnection!.setLocalDescription(offer);
  _signalingChannel!.sink.add(jsonEncode({
    'type': 'offer',
    'sdp': offer.sdp,
  }));
}
// Add to WebRTCService class
Future<void> handleNegotiation() async {
  _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
    _signalingChannel!.sink.add(jsonEncode({
      'type': 'ice_candidate',
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    }));
  };

  _peerConnection!.onRenegotiationNeeded = () async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    _signalingChannel!.sink.add(jsonEncode({
      'type': 'offer',
      'sdp': offer.sdp,
    }));
  };
}