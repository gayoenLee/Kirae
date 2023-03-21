//
//  WebSocketListener.swift
//  WebRTCapp
//
//  Created by Sergio Paniego Blanco on 01/05/2018.
//  Copyright © 2018 Sergio Paniego Blanco. All rights reserved.
//

import Foundation
import Starscream
import WebRTC

@available(iOS 14.0, *)
class WebSocketListener: WebSocketDelegate {
    let JSON_RPCVERSION = "2.0"
    let useSSL = true
    var socket: WebSocket
    var helloWorldTimer: Timer?
    var id = 0
    var url: String
    var sessionName: String
    var participantName: String
    var localOfferParams: [String: String]?
    var iceCandidatesParams: [[String:String]]?
    var userId: String?
    var remoteParticipantId: String?
    var participants: [String: RemoteParticipant]
    var localPeer: RTCPeerConnection?
    var peersManager: PeersManager
    var token: String
    var views: [UIView]!
    var names: [UILabel]!
    
    init(url: String, sessionName: String, participantName: String, peersManager: PeersManager, token: String, views: [UIView], names: [UILabel]) {
       // self.url = "wss://kirae.tk/"
        self.url = "wss://49.247.211.127/"

        self.sessionName = sessionName
        self.participantName = participantName
        self.peersManager = peersManager
        self.localPeer = self.peersManager.localPeer
        print("로컬 피어 확인: \(localPeer)")
        self.iceCandidatesParams = []
        self.token = token
        self.participants = [String: RemoteParticipant]()
        self.views = views
        self.names = names
        //socket = WebSocket(url: URL(string: "wss://kirae.tk/")!)
        socket = WebSocket(url: URL(string: "wss://49.247.211.127/")!)

        socket.disableSSLCertValidation = useSSL
        socket.delegate = self
        socket.connect()
    }
    
    func websocketDidConnect(socket: WebSocketClient) {
        print("웹소켓 연결함")
       // pingMessageHandler()
        var joinRoomParams: [String: String] = [:]
        joinRoomParams["recorder"] = "false"
//        joinRoomParams[JSONConstants.Metadata] = "{\"clientData\": \"" + participantName + "\"}"
        joinRoomParams["userName"] = participantName
        joinRoomParams["secret"] = "MY_SECRET"
        joinRoomParams["roomName"] = sessionName
        joinRoomParams["token"] = token
        
        print("조인룸 파라미터 확인: \(joinRoomParams)")
        sendJson(method: "joinRoom", params: joinRoomParams)
    self.sendJson(method: "receiveVideoFrom",params: self.localOfferParams!)
        }
    
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("------------웹소켓 연결 끊어짐----------------: " + error.debugDescription)
    }
    
    //시그널링 서버에게서 메시지를 받았을때.
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("-----------------------웹소켓 메세지 --------------" + text)
        let data = text.data(using: .utf8)!
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String: Any]
            {
                if json[JSONConstants.Result] != nil {
                    
                    print("핸들리절트로 가기")
                    handleResult(json: json)
                    
                } else {
                    
                    print("핸들메소드로 가기")
                    handleMethod(json: json)
                }
            } else {
                print("bad json")
            }
        } catch let error as NSError {
            print(error)
        }
    }
    
    func handleResult(json: [String: Any]) {
        let result: [String: Any] = json[JSONConstants.Result] as! [String: Any]
        
        if result[JSONConstants.SdpAnswer] != nil {
            saveAnwer(json: result)
            
        } else if result[JSONConstants.SessionId] != nil {
            
            if result[JSONConstants.Value] != nil {
                let value = result[JSONConstants.Value]  as! [[String:Any]]
                
                if !value.isEmpty {
                    
                    addParticipantsAlreadyInRoom(result: result)
                }
                self.userId = result[JSONConstants.Id] as? String
                
                //이해못함!!
                for var iceCandidate in iceCandidatesParams! {
                    iceCandidate["endpointName"] = self.userId
                    print("[올리가없어[onIceCandidate]\(iceCandidate)")

                    sendJson(method: "onIceCandidate", params:  iceCandidate)
                }
            }
        } else if result[JSONConstants.Value] != nil {
            print("pong")
        } else {
            print("Unrecognized")
        }
    }
    
    //방에 이미 참여중인 사람 목록
    func addParticipantsAlreadyInRoom(result: [String: Any]) {
        
        let values = result[JSONConstants.Value] as! [[String: Any]]
        print("[addParticipantsAlreadyInRoom] 메소드 안 values \(values) ")
        
        for participant in values {
            
            print(participant[JSONConstants.Id]!)
            
            self.remoteParticipantId = participant[JSONConstants.Id]! as? String
            print("리모트 participant id 저장한 값: \( self.remoteParticipantId)")
            
            let remoteParticipant = RemoteParticipant()
            remoteParticipant.id = participant[JSONConstants.Id] as? String
            remoteParticipant.participantName = participant[JSONConstants.name] as? String

            //이해못함!!
            self.participants[remoteParticipant.id!] = remoteParticipant
            
            //리모트 피어 커넥션 생성
            self.peersManager.createRemotePeerConnection(remoteParticipant: remoteParticipant)
            
            let mandatoryConstraints = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"]
            
            let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
            
            remoteParticipant.peerConnection!.offer(for: sdpConstraints, completionHandler: {(sessionDescription, error) in
                print("Remote Offer: " + error.debugDescription)
                
                //로컬디스크립션 set
                self.participants[remoteParticipant.id!]!.peerConnection!.setLocalDescription(sessionDescription!, completionHandler: {(error) in
                    print("Remote Peer Local Description set " + error.debugDescription)
                })
                var remoteOfferParams: [String:String] = [:]
                remoteOfferParams["sdpOffer"] = sessionDescription!.sdp
                remoteOfferParams["sender"] = self.remoteParticipantId! + "_CAMERA"
                remoteOfferParams["name"] = remoteParticipant.participantName
                print("파라미턴아ㅣㄹ: \(remoteOfferParams)")
                
                //----다름-----icecandidate를 옵션에 안넣었음.
                
                self.sendJson(method: "receiveVideoFrom", params: remoteOfferParams)
            })
            self.peersManager.remotePeer!.delegate = self.peersManager
        }
    }

    func saveAnwer(json: [String:Any]) {
        print("[save Answer] 메소드")
        let sessionDescription = RTCSessionDescription(type: RTCSdpType.answer, sdp: json["sdpAnswer"] as! String)
        remoteParticipantId = json[JSONConstants.Id] as! String
        print("[save Answer]sdp 확인: \(sessionDescription)")
        print("[save Answer] 아이디 확인: \(remoteParticipantId)")
        
        if localPeer == nil {
            
            print("[save Answer]로컬 피어가 널일 때")
            self.localPeer = self.peersManager.localPeer
        }
        if (localPeer!.remoteDescription != nil) {
            print(" [save Answer]localPeer!.remoteDescription != nil 이프문 안")
            print("\(participants[remoteParticipantId!]!.participantName)")
            
            participants[remoteParticipantId!]!.peerConnection!.setRemoteDescription(sessionDescription, completionHandler: {(error) in
                print("[save Answer]Remote Peer Remote Description set: " + error.debugDescription)
                print("[save Answer]\(self.peersManager.remoteStreams.count)")
                print("[save Answer]\(self.participants.count)")

                if self.peersManager.remoteStreams.count >= self.participants.count {

                    DispatchQueue.main.async {
                        print("[save Answer]Count: " + self.participants.count.description)

                        let indexPath = NSIndexPath(item: 0, section: 0)
                        
                        print("인덱스 패스 확인: \(indexPath)")
                        print("리모트 스트림들 확인: \(self.peersManager.remoteStreams)")
                        let stream = self.peersManager.remoteStreams//[self.participants.count-1]
                        print("stream  확인: \(stream)")
                                                
                        #if arch(arm64)
                        // Using metal (arm64 only)
                        let remoteRenderer = RTCMTLVideoView(frame:  CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width/4, height: UIScreen.main.bounds.width/4))
                        print("arch  확인: \(remoteRenderer)")
                        //remoteRenderer.contentMode = .scaleAspectFit

                        #else
                        // Using OpenGLES for the rest
                        let remoteRenderer = RTCEAGLVideoView(frame:  CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width/4, height: UIScreen.main.bounds.width/4))
                        print("else  확인: \(remoteRenderer)")

                        #endif

                         //set stream to cell
                        stream[self.participants.count-1].videoTracks.first?.add(remoteRenderer)
                        
                        print("에드하기: ")

                        NotificationCenter.default.post(name: NSNotification.Name("saveAnswerNoti"), object: nil, userInfo: nil)
    
                    }
                }
            })
        } else {
            localPeer!.setRemoteDescription(sessionDescription, completionHandler: {(error) in
                print("[save Answer]Local Peer Remote Description set: " + error.debugDescription)
            })
        }
    }
    
    func handleMethod(json: Dictionary<String,Any>) {
        if json[JSONConstants.Params] != nil {
            let method = json[JSONConstants.Method] as! String
            let params = json[JSONConstants.Params] as! Dictionary<String, Any>
            print("핸들 메소드의 종류 확인: \(method)")
            
            //let params = json[JSONConstants.Params] as! String
            switch method {
            
            case JSONConstants.imageShare:
                NotificationCenter.default.post(name: NSNotification.Name("imageShare"), object: nil, userInfo: params)
            
            case JSONConstants.youtube:
                NotificationCenter.default.post(name: NSNotification.Name("youtube"), object: nil, userInfo: params)
            
            case JSONConstants.catchMindResponse:
                NotificationCenter.default.post(name: NSNotification.Name("catchMindResponse"), object: nil, userInfo: params)
                
            //그림 받는 사람 이벤트 : 그린 사람 id, 그린 사람 닉네임, 이전 좌표값, 현재 그린 좌표값, 그리는 색
            case JSONConstants.catchMind:
                NotificationCenter.default.post(name: NSNotification.Name("catchMind"), object: nil, userInfo: params)
                
            case JSONConstants.allFilterDeleted:
                NotificationCenter.default.post(name: NSNotification.Name("allFilterDeleted"), object: nil, userInfo: params)
                
            case JSONConstants.imageOverlay:
                print("이미지 오버레이 리스펀스")
                
                NotificationCenter.default.post(name: NSNotification.Name("setDecoImgValue"), object: nil, userInfo: params)
                
                
            case JSONConstants.textOverlay:
                print("텍스트 오버레이 리스펀스")
                
                NotificationCenter.default.post(name: NSNotification.Name("setDecoTxtValue"), object: nil, userInfo: params)
                
            case JSONConstants.onSetMediaStream :
                            /*params {
                         id : 참가자 ID
                         name : 참가자 이름
                         video : true / false
                         audio : true / false
                         }
                            */
                var videoSetting : Bool = false
                var audioSetting : Bool = false

              let video =  params["video"] as! Bool
                if video == true{
                    videoSetting = true
                }else{
                    videoSetting = false
                }
                let mic = params["audio"] as! Bool
                
                if mic == true{
                    audioSetting = true
                }else{
                    audioSetting = false
                }
                let userId = params["id"] as! String
                
                self.participants["\(userId)"]?.videoOff = videoSetting
                self.participants["\(userId)"]?.micOff = audioSetting
                print("오디오, 비디오 세팅 값 이벤트: \(video), \(mic)")
                
                NotificationCenter.default.post(name: NSNotification.Name("setLocalMedia"), object: nil, userInfo: ["id": userId])
                
                            print("[onSetMediaStream]")
                        break
            case JSONConstants.ExistingParticipants :
                if localOfferParams != nil {
                    
                    PeersManager.myId = params["myId"] as! String
                    print("내 아이디값 확인: \(PeersManager.myId)")
                    sendJson(method: "receiveVideoFrom",params: localOfferParams!)
                    //이해못함!!
                    for var iceCandidate in iceCandidatesParams! {
                        var candidateParams: [String:Any] = [:]
                        print("내이름!!!\(self.participantName)")
                        candidateParams["sender"] = self.participantName
                        candidateParams["candidate"] = iceCandidate
                        candidateParams["id"] = self.userId
                        print("[onIceCandidate][ExistingParticipants]\(candidateParams)")
                        sendJson(method: "onIceCandidate", params: candidateParams)
                        
                    }
                }
                
                addParticipantsAlreadyInRoom(result:params )
                
            //candidate
            case JSONConstants.IceCandidate:
                iceCandidateMethod(params: params)
                
                //내가 있던 방에 새로운 사람 등장
            case JSONConstants.ParticipantJoined:
                participantJoinedMethod(params: params)
                for var iceCandidate in iceCandidatesParams! {
                    var candidateParams: [String:Any] = [:]
                    print("내이름!!!\(self.participantName)")
                    candidateParams["sender"] = params["name"] as! String
                    candidateParams["candidate"] = iceCandidate
                    
                    //다시 보기 상대방것인지 내것인지
                    candidateParams["id"] = params["id"] as! String
                    print("[onIceCandidate][ExistingParticipants]\(candidateParams)")
                    sendJson(method: "onIceCandidate", params: candidateParams)
                    
                }
                //새로운 방에 내가 입장
            case JSONConstants.ParticipantPublished:
                participantPublished(params: params)
                
            case JSONConstants.ParticipantLeft:
                participantLeft(params: params)
                
            case JSONConstants.receiveVideoAnswer:
                print("리시브 비디오 앤서 파라미터 : \(params)" )
                saveAnwer(json: params)
            default:
            print("Error")
            }
        }
    }
    func iceCandidateMethod(params: Dictionary<String, Any>) {
        print("[iceCandidateMethod]\(params["info"] as? String)")
        if (params["endpointName"] as? String == userId) {
            print("내 IceCandidate일 때")
            saveIceCandidate(json: params, endPointName: nil)
        } else {
            print("다른 사람 IceCandidate일 때")
                      saveIceCandidate(json: params, endPointName: params["endpointName"] as? String)
        }
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("Received data: " + data.description)
    }
    
    func participantJoinedMethod(params: Dictionary<String, Any>) {
        print("participantJoinedMethod  안\(params)")
        let remoteParticipant = RemoteParticipant()
        remoteParticipant.id = params[JSONConstants.Id] as? String
        remoteParticipant.participantName = params[JSONConstants.name] as? String
        self.participants[params[JSONConstants.Id] as! String] = remoteParticipant
        
        print("새로운 사람이 들어왔을 때 participantJoinedMethod 안\( remoteParticipant.id)")

        self.peersManager.createRemotePeerConnection(remoteParticipant: remoteParticipant)

        let mandatoryConstraints = [
            "OfferToReceiveAudio": "true",
            "OfferToReceiveVideo": "true"
        ]
        let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        
        remoteParticipant.peerConnection!.offer(for: sdpConstraints, completionHandler: { [self](sessionDescription, error) in
            print("Remote Offer: " + error.debugDescription)
            
            //로컬디스크립션 set
            self.participants[remoteParticipant.id!]!.peerConnection!.setLocalDescription(sessionDescription!, completionHandler: {(error) in
                print("Remote Peer Local Description set " + error.debugDescription)
            })
            var remoteOfferParams: [String:String] = [:]
            remoteOfferParams["sdpOffer"] = sessionDescription!.sdp
            remoteOfferParams["sender"] = remoteParticipant.id! + "_CAMERA"
            remoteOfferParams["name"] = remoteParticipant.participantName
            print("파라미턴아ㅣㄹ: \(remoteOfferParams)")
            
            //----다름-----icecandidate를 옵션에 안넣었음.
            
            self.sendJson(method: "receiveVideoFrom", params: remoteOfferParams)
        })
        self.peersManager.remotePeer!.delegate = self.peersManager
    }
    
    func participantPublished(params: Dictionary<String, Any>) {
        print("participantPublished 들ㄹ어옴")
        self.remoteParticipantId = params[JSONConstants.Id] as? String
        print("IDs: " + remoteParticipantId!)
        
        //새로 들어온 사람을 participants에서 찾는 것.
        let remoteParticipantPublished = participants[remoteParticipantId!]!
        
        let mandatoryConstraints = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"]
        
        //찾은 사람의 피어 커넥션에 offer보내기
        remoteParticipantPublished.peerConnection!.offer(for: RTCMediaConstraints.init(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil), completionHandler: { (sessionDescription, error) in
            
            remoteParticipantPublished.peerConnection!.setLocalDescription(sessionDescription!, completionHandler: {(error) in
                print("Remote Peer Local Description set")
            })
            
            var remoteOfferParams:  [String: String] = [:]
            remoteOfferParams["sdpOffer"] = sessionDescription!.description
            remoteOfferParams["sender"] = remoteParticipantPublished.id! + "_webcam"
            remoteOfferParams["name"] = params[JSONConstants.name] as? String
            self.sendJson(method: "receiveVideoFrom", params: remoteOfferParams)
        })
        self.peersManager.remotePeer!.delegate = self.peersManager
    }
    
    func participantLeft(params: Dictionary<String, Any>) {
        let participantId = params["name"] as! String
        participants[participantId]!.peerConnection!.close()

        //REMOVE VIEW
        #if arch(arm64)
            let renderer = RTCMTLVideoView(frame:  self.views[self.participants.count-1].frame)
        #else
            let renderer = RTCEAGLVideoView(frame:  self.views[self.participants.count-1].frame)
        #endif
        
        let videoTrack = self.peersManager.remoteStreams[self.participants.count-1].videoTracks[0]
        videoTrack.remove(renderer)
        self.views[(participants[participantId]?.index)!].willRemoveSubview(renderer)
        self.names[(participants[participantId]?.index)!].text = ""
        self.names[(participants[participantId]?.index)!].backgroundColor = UIColor.clear
        participants.removeValue(forKey: participantId)
    }
    
    func saveIceCandidate(json: Dictionary<String, Any>, endPointName: String?) {
        print("[saveIceCandidate] endPointName \(endPointName) , params \(json) ")
        let iceCandidate = RTCIceCandidate(sdp: json["candidate"] as! String, sdpMLineIndex: json["sdpMLineIndex"] as! Int32, sdpMid: json["sdpMid"] as? String)
        
        //엔드포인트가 없을 경우에는 내가 받을 icecandidate를 의미함
        if (endPointName == nil) {
            self.localPeer = self.peersManager.localPeer
            self.localPeer!.add(iceCandidate)
            
        } else {
            
            participants[endPointName!]!.peerConnection!.add(iceCandidate)
        }
    }
    
    func sendJson(method: String, params: [String: Any]) {
        let json: NSMutableDictionary = NSMutableDictionary()
        json.setValue(method, forKey: JSONConstants.Method)
        json.setValue(id, forKey: JSONConstants.Id)
        id += 1
        json.setValue(params, forKey: JSONConstants.Params)
        json.setValue(JSON_RPCVERSION, forKey: JSONConstants.JsonRPC)
        let jsonData: NSData
        do {
            jsonData = try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions()) as NSData
            let jsonString = NSString(data: jsonData as Data, encoding: String.Encoding.utf8.rawValue)! as String
            //print("Sending = \(jsonString)")
            socket.write(string: jsonString)
        } catch _ {
            print ("JSON Failure")
        }
    }
    
    func addIceCandidate(iceCandidateParams: [String: String]) {
        iceCandidatesParams!.append(iceCandidateParams)
    }
    
    func embedView(_ view: UIView, into containerView: UIView) {
        containerView.addSubview(view)
        containerView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        view.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        view.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
    }
    
}
