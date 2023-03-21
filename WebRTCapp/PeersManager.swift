//
//  PeersManager.swift
//  WebRTCapp
//
//  Created by Sergio Paniego Blanco on 20/05/2018.
//  Copyright © 2018 Sergio Paniego Blanco. All rights reserved.
//

import Foundation
import WebRTC
import Starscream
import Vision

@available(iOS 14.0, *)
class PeersManager: NSObject {
    static var myId : String = ""
 
    var localPeer: RTCPeerConnection?
    var remotePeer: RTCPeerConnection?
    var peerConnectionFactory: RTCPeerConnectionFactory?
    var connectionConstraints: RTCMediaConstraints?
    var webSocketListener: WebSocketListener?
    var webSocket: WebSocket?
    var localVideoTrack: RTCVideoTrack?
    var localAudioTrack: RTCAudioTrack?
    var peerConnection: RTCPeerConnection?
    var view: UIView!
    var remoteStreams: [RTCMediaStream]
    var remoteParticipant: RemoteParticipant?
    
    
    var localRemoteStreams : [RTCMediaStream]
        var renderer: RTCVideoRenderer
        init(view: UIView,renderer: RTCVideoRenderer) {
            self.view = view
            self.remoteStreams = []
            self.localRemoteStreams = []
            self.renderer = renderer
        }
    func setWebSocketAdapter(webSocketAdapter: WebSocketListener) {
        self.webSocketListener = webSocketAdapter
    }
    
    // Function that start everything related with WebRTC use
    func start() {
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        peerConnectionFactory = RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)

        let mandatoryConstraints = [
            "OfferToReceiveAudio": "true",
            "OfferToReceiveVideo": "true"
        ]
        
        let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
    
        createLocalPeerConnection(sdpConstraints: sdpConstraints)
    }
    
    func createLocalPeerConnection(sdpConstraints: RTCMediaConstraints) {
        let config = RTCConfiguration()
        config.bundlePolicy = .maxCompat
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        config.rtcpMuxPolicy = .require

        localPeer = peerConnectionFactory!.peerConnection(with: config, constraints: sdpConstraints, delegate: nil)
    }
    
    func createLocalOffer(mediaConstraints: RTCMediaConstraints,sendername : String) {
        print("로컬 오퍼 생성 메소드 안 ")
        localPeer!.offer(for: mediaConstraints, completionHandler: { (sessionDescription, error) in
            
            self.localPeer!.setLocalDescription(sessionDescription!, completionHandler: {(error) in
                print("로컬 디스크립션 셋팅: " + error.debugDescription)
            })
            var localOfferParams: [String:String] = [:]
            localOfferParams["audioActive"] = "true"
            localOfferParams["videoActive"] = "true"
            localOfferParams["doLoopback"] = "false"
            localOfferParams["frameRate"] = "30"
            localOfferParams["typeOfVideo"] = "CAMERA"
            localOfferParams["sdpOffer"] = sessionDescription!.sdp
            localOfferParams["name"] = sendername
            
            if (self.webSocketListener!.id) > 1 {
//                self.webSocketListener!.sendJson(method: "publishVideo", params: localOfferParams)
                print("receiveVideoFrom send json")
                self.webSocketListener!.sendJson(method: "receiveVideoFrom", params: localOfferParams)
                
            } else {
                print("로컬 오퍼 생성 후 receive video from 안함!!!!!")
                self.webSocketListener!.localOfferParams = localOfferParams
            }
        })
    }
    
    func createRemotePeerConnection(remoteParticipant: RemoteParticipant) {
        print("리모트 피어 커넥션 만들기")
        let mandatoryConstraints = [
            "OfferToReceiveAudio": "true",
            "OfferToReceiveVideo": "true"
        ]
        let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        
        let config = RTCConfiguration()
        config.bundlePolicy = .maxCompat
        config.iceServers = [RTCIceServer(urlStrings: ["stun:kirae.tk:3478"])]
        config.rtcpMuxPolicy = .require
        
        self.remotePeer = (peerConnectionFactory?.peerConnection(with: config, constraints: sdpConstraints, delegate: nil))!
        
        remoteParticipant.peerConnection = self.remotePeer
        
        self.remoteParticipant = remoteParticipant
        self.remoteParticipant?.peerConnection = self.remotePeer
    }
}

@available(iOS 14.0, *)
extension PeersManager: RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("peerConnection new signaling state: \(stateChanged)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
            if peerConnection == self.localPeer {
                print("local peerConnection did add stream\(stream)")
            
                localRemoteStreams.append(stream)
              
                //은열수정
                let localvideo = self.localRemoteStreams[0]
                let stream = self.localPeer?.localStreams.first
                DispatchQueue.main.asyncAfter(deadline: .now()+3){
                    
                    stream?.videoTracks.first?.remove(self.renderer)
                }
                localvideo.videoTracks.first?.add(self.renderer)
                
                                
            } else {
                print("remote peerConnection did add stream\(stream)")
                
                if (stream.audioTracks.count > 1 || stream.videoTracks.count > 1) {
                    print("Weird looking stream")
                }
                remoteStreams.append(stream)
            }
        }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("peerConnection did remote stream")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        if peerConnection == self.localPeer {
            print("local peerConnection should negotiate")
        } else {
            print("remote peerConnection should negotiate")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("peerConnection new connection state: \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("peerConnection new gathering state: \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        
        if peerConnection == self.localPeer {
            
            var iceCandidateParams: [String: String] = [:]
            iceCandidateParams["sdpMid"] = candidate.sdpMid
            iceCandidateParams["sdpMLineIndex"] = String(candidate.sdpMLineIndex)
            iceCandidateParams["candidate"] = String(candidate.sdp)
            
            if self.webSocketListener!.userId != nil {
                
                iceCandidateParams["endpointName"] =  self.webSocketListener!.userId
                print("[onIceCandidate][절대안옴]\(iceCandidateParams)")
                self.webSocketListener!.sendJson(method: "onIceCandidate", params: iceCandidateParams)
                
            } else {
                print("userId = nil ice candidate보내기 안 ")
                print("")
                self.webSocketListener!.addIceCandidate(iceCandidateParams: iceCandidateParams)
            }
            print("NEW local ice candidate")
            
        } else {
            var iceCandidateParams: [String: String] = [:]
            
            iceCandidateParams["sdpMid"] = candidate.sdpMid
            iceCandidateParams["sdpMLineIndex"] = String(candidate.sdpMLineIndex)
            iceCandidateParams["candidate"] = String(candidate.sdp)
            var candidateParams: [String:Any] = [:]
            candidateParams["endpointName"] =  self.remoteParticipant!.id
            candidateParams["candidate"] = iceCandidateParams
            candidateParams["sender"] = self.remoteParticipant!.participantName
            print("[onIceCandidate][여기는 옴]\(candidateParams)")
            self.webSocketListener!.sendJson(method: "onIceCandidate", params: candidateParams)
            print("NEW remote ice candidate")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("peerConnection did open data channel")
    }
}

//@available(iOS 14.0, *)
//extension PeersManager : RTCVideoCapturerDelegate{
//
//    public func capturer(_ capturer: RTCVideoCapturer, didCapture frame: RTCVideoFrame) {
//        print("캡쳐러 안")
//
//        var fingerTips: [CGPoint] = []
//
//        let sampleBuffer = frame.buffer as! RTCCVPixelBuffer
//        let pixelBuffer = sampleBuffer.pixelBuffer
//
//        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
//        do {
//          // Perform VNDetectHumanHandPoseRequest
//          try handler.perform([handPoseRequest])
//
//          // Continue only when at least a hand was detected in the frame. We're interested in maximum of two hands.
//          guard
//            let results = handPoseRequest.results?.prefix(2),
//            !results.isEmpty
//          else {
//            return
//          }
//        print("결과: \(results)")
//
//          var recognizedPoints: [VNRecognizedPoint] = []
//
//          try results.forEach { observation in
//            // Get points for all fingers.
//            let fingers = try observation.recognizedPoints(.all)
//
//            // Look for tip points.
//            if let thumbTipPoint = fingers[.thumbTip] {
//              recognizedPoints.append(thumbTipPoint)
//            }
//            if let indexTipPoint = fingers[.indexTip] {
//              recognizedPoints.append(indexTipPoint)
//            }
//            if let middleTipPoint = fingers[.middleTip] {
//              recognizedPoints.append(middleTipPoint)
//            }
//            if let ringTipPoint = fingers[.ringTip] {
//              recognizedPoints.append(ringTipPoint)
//            }
//            if let littleTipPoint = fingers[.littleTip] {
//              recognizedPoints.append(littleTipPoint)
//            }
//          }
//
//          fingerTips = recognizedPoints.filter {
//            // Ignore low confidence points.
//            $0.confidence > 0.9
//          }
//          .map {
//            // Convert points from Vision coordinates to AVFoundation coordinates.
//            CGPoint(x: $0.location.x, y: 1 - $0.location.y)
//          }
//        } catch {
//          print(error.localizedDescription)
//        }
//    }
//}

