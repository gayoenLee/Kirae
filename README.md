# Kirae (키레)

> 키레는 WebRTC 및 미디어 서버를 통한 SFU방식으로 친구들과 최대 6명까지 다대다 영상통화를 할 수 있습니다. 인공지능 기술을 활용한 얼굴필터, 손동작 인식을 이용한 게임도 할 수 있습니다.

### Index
- [기능](#기능)
- [설계 및 구현](#설계-및-구현)
- [trouble shooting](#trouble-shooting)
- [학습 내용](#관련-학습-내용)

---

## 기능

- [영상 통화](#영상-통화)
- [얼굴 필터, 이미지와 텍스트 스티커 추가](#얼굴-필터-이미지와-텍스트-스티커-추가)
- [드로잉 퀴즈 게임](#드로잉-퀴즈-게임)
- [유튜브 같이 보기](#유튜브-같이-보기)
  
&nbsp;

### 영상 통화
최대 6명의 사람들과 다대다 영상통화를 즐길 수 있습니다. 웹과 모바일 호환이 가능하며, 시그널링 서버와 WebSocket통신을 이용해 기기간 이벤트를 주고받습니다. 기본적인 비디오&오디오 켜기,끄기도 가능합니다.
![IMG_9346](https://github.com/user-attachments/assets/36be2619-a9f2-46ca-adb4-5b5132ccc6b8)

&nbsp;
### 얼굴 필터, 이미지와 텍스트 스티커 추가
OpenCV를 기반으로 한 Kurento FaceOverlay Filter 모듈로 얼굴에 필터를 씌울 수 있습니다. 
또한 Kurento Image Overlay 모듈과 직접 커스텀한 TextOverlay모듈을 이용했습니다. 텍스트를 입력하거나 이미지를 선택해 화면에 스티커 추가가 됩니다. 또한 스티커들은 사용자가 원하는 위치에 이동시키고 크기를 조정할 수 있습니다. 
| 얼굴 필터 씌우기 | 텍스트, 이미지 스티커 크기&위치 조정 |
| :------: | :--------: |
|<img width="250" alt="IMG_9358" src="https://github.com/user-attachments/assets/9f42f6cc-3cd5-4315-806a-8acfcaa95ca6">|<img width="250" alt="IMG_9360" src="https://github.com/user-attachments/assets/2f342434-4faa-4904-8a54-c5bf61feeba0">|

## 드로잉 퀴즈 게임
참가자당 2문제씩 제시된 단어에 맞춰 그림을 그리고 상대방은 10초 안에 정답을 맞추는 게임입니다. 그림은 게임 참가자 모두에게 공유가 되고 되돌리기, 전체 삭제하기가 가능합니다.
| 주어진 단어에 그림 그리기 | 손을 올려서 정답창 나타나게 하기 |
| :-: | :-: |
| <img src="https://github.com/user-attachments/assets/6d462d91-4b61-4dcd-b719-ed591f3717fa" width="250"> | <img src="https://github.com/user-attachments/assets/9aaf7a66-75bc-414c-859a-1d7d44114cf1" width="250">  |

## 유튜브 같이 보기
Youtube API를 이용해 영상통화중에 친구들과 유튜브 컨텐츠를 공유 or 원하는 영상을 검색해 볼 수 있습니다.
<p float="left">
<img src="https://github.com/user-attachments/assets/c8061efb-de1a-4891-b42d-2fec1cecf0c9" width="250">
</p>


 ---
## trouble Shooting
- WebRTC 이벤트 송수신을 위한 Listener클래스 구현의 샘플 코드가 Javascript로만 되어 있었다.
=> 해결 : Swift로 모두 변환하는 작업 진행해 클래스 구현

- 화상 통화 및 미팅에서 사용자간에 latency를 느끼지 않게 만들 수 있는 프로토콜을 선정해야 했다.
=> 해결 :  프로토콜에는 WebRTC, RTMP등의 프로토콜이 존재.

-P2P방식으로 다자간 화상 통화 구현시 클라이언트의 과부하가 심해질 수 있다.
=> 클라이언트의 부하를 줄이기 위해 WebRTC를 이용한 서버 아키텍처 설계 방법에는 MFU, SFU, 시그널링서버등이 있다.
=> 웹RTC는 기본적으로 일대일(peer to peer, 이하 P2P) 미디어 통신(secured real time media transport) 기술의 세계 표준이지만, 다자간 화상회의나 방송 스트리밍 등에도 이용할 수 있다. 하지만 P2P 방식으로 다수 인원의 데이터 송수신을 지원할 경우 클라이언트 쪽의 과부하가 심해지기 때문에 이때는 미디어 서버를 사용하게 된다.

---
## 관련 학습 내용

### ✅socket을 사용하지 않고 http로만 구현한다면 어떻게 할지?

- 🔹**Socket : 연결 지향형 방식**
    
    Server ↔ client가 **특정 포트**를 통해 실시간으로 **양방향 통신**을 하는 방식.
    
    특정 포트를 통해 **연결을 유지**하고 있어서 ***실시간*** 양방향 통신이 가능한 것.
    
    →**server도** client로 요청을 보낼 수 있음.
    
    ex) 동영상  스트리밍 서비스
    
    http프로그래밍으로 구현하면 동영상이 종료될 때까지 http request를 보내야 함. → 부하 발생 가능.
    

- 🔹**HTTP : 단방향적 통신**
    
    application계층의 연결 방식.
    
    ***client의 요청***이 있을 때에만!! → server가 응답해서 처리 → ***연결 끊음.***
    
    ⇒실시간 연결 x
    
    ⇒필요한 경우에만 server로 접근하는 콘텐츠 위주 데이터를 사용할 때 용이.
  

### ✅ setNeedsLayout, layoutIfNeeded

둘 다 UIView의 메소드. 최종적으로 layoutSubviews를 호출하는 예약메소드.

❓읽어볼 것

[Demystifying iOS Layout](https://tech.gc.com/demystifying-ios-layout/)

🔹main run loop개념을 알아야 함

👉어플리케이션이 실행되면 UIApplication이 메인 스레드에서 main run loop를 실행 → main run  loop는 돌아가면서 터치 이벤트, 위치의 변화, 디바이스의 회전 등 각종 이벤트들을 처리. 
how? 
각 이벤트들에 맞는 핸들러를 찾아서 그들에게 권한을 위임하여 진행.

ex) @IBAction이 버튼의 터치 이벤트를 처리하는 것과 같다.

👉발생한 이벤트들을 모두 처리하고 권한이 다시 main run  loop로 돌아오게 됨. = **update cycle**

🔹update cycle

main run loop에서 버튼을 클릭하면 크기나 위치가 이동하는 애니메이션처럼 layout이나 position을 바꾸는 핸들러가 실행되는 경우 → 즉각 반영x

how?

시스템은 layout이나 position이 변화되는 view들을 체크 → 모든 핸들러가 종료되고 main run loop로 다시 돌아옴 = update cycle 

-이때 view들의 값을 바꿔줘서 Position이나 layout의 변화를 적용.

🔹관련 메소드

- layoutSubViews()
View의 값을 호출한 즉시 변경시켜주는 메소드.
호출되면 해당 View의 모든 SubView들의 layoutSubviews()또한 연달아 호출됨.  
⇒ 비용이 많이 드는 메소드.
⇒ 직접 호출이 지양됨.
⇒ 시스템에 의해서 View의 값이 재계산돼야 하는 적절한 시점에 자동으로 호출됨.
⇒layoutSubviews를 유도할 수 있는 방법 존재. = update cycle에서 layoutSubViews의 호출을 예약하는 행위.

🤔layoutSubViews가 자동으로 호출되는 경우는?
 ☑️View의 크기를 조절할 때
 ☑️SubView를 추가할 때
 ☑️사용자가 UIScrollView를 스크롤할 때
 ☑️디바이스를 회전시켰을 때
 ☑️View의 AutoLayout constraint값을 변경시켰을 때
- **setNeedsLayout()**
layoutSubviews를 위의경우 말고 예약 가능한 메소드.
- 가장 비용이 적게 드는 방법.
- **비동기적**으로 작동 → 호출되고 바로 반환된다.
- **layoutIfNeeded()**
예약을 '바로' 실행시키는 동기적으로 작동하는 메소드.
update cycle이 올때까지 기다려서 layoutSubviews를 호출하는 것이 아니라

그 **즉시** layoutSubViews를 발동시키는 메소드.
ex) 즉시 값이 변경돼야 하는 애니메이션에서 많이 사용됨


다대다 화상통화 로직 정리

### 1. PeersManager

1)WebRTC와 관련된 RTC Media Constraints 설정. & 비디오에 대한 인코더, 디코더 생성하고 이걸로 PeerConnectionFactory 생성 

```swift
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
```

2) 로컬피어커넥션 생성 

```swift
func createLocalPeerConnection(sdpConstraints: RTCMediaConstraints) {
        let config = RTCConfiguration()
        config.bundlePolicy = .maxCompat
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        config.rtcpMuxPolicy = .require
				//위에서 만든 피어커넥션팩토리의 peerconnection메소드를 호출해 RTCConfiguration값과 RTCMedaiConstraints값을 가지고 피어커넥션 생성 
        localPeer = peerConnectionFactory!.peerConnection(with: config, constraints: sdpConstraints, delegate: nil)
    }
```

ICE Configuration 생성.

→구글 스턴 사용.

## 2.로컬비디오뷰 생성, 로컬 오퍼 생성

```swift
DispatchQueue.main.async {
            
            self.createLocalVideoView(renderer: renderer, useBackCamera: self.useBackCamera)
            
            let mandatoryConstraints = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"]
            let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
            
            self.peersManager!.createLocalOffer(mediaConstraints: sdpConstraints,sendername: self.participantName);
        }
```

1)로컬 비디오 뷰 생성

오디오와 비디오의 RTCMediaConstraints설정.

오디오와 비디오 소스 생성.

비디오 Capturer생성만 해놓음.→다음 단계에서 사용.

오디오와 비디오 트랙 생성.(소스를 가지고)

오디오와 비디오 트랙을 peer connection에 추가.

```swift
private func createMediaSenders() {
	let streamId = "stream"
	let stream = self.peersManager!.peerConnectionFactory!.mediaStream(withStreamId: streamId)
...
//비디오
self.videoSource = self.peersManager!.peerConnectionFactory!.videoSource()

self.videoCapturer = RTCCameraVideoCapturer(delegate: self)
        
let videoTrack = self.peersManager!.peerConnectionFactory!.videoTrack(with: self.videoSource!, trackId: "video0")
self.localVideoTrack = videoTrack
        
        //---------------------로컬 비디오 트랙에 데이터 집어넣기
        self.peersManager!.localVideoTrack = videoTrack
        stream.addVideoTrack(videoTrack)

}
```

 

2) Video Capturer 설정.

capture device선택.

```swift
guard let stream = self.peersManager!.localPeer!.localStreams.first ,
              let capturer = self.videoCapturer as? RTCCameraVideoCapturer else {
            return
        }
```

전면/후면 카메라 분기 처리.

```swift
guard
                let frontCamera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == .front }),
                
                // choose highest res
                let format = (RTCCameraVideoCapturer.supportedFormats(for: frontCamera).sorted { (f1, f2) -> Bool in
                    let width1 = CMVideoFormatDescriptionGetDimensions(f1.formatDescription).width
                    let width2 = CMVideoFormatDescriptionGetDimensions(f2.formatDescription).width
                    return width1 < width2
                }).last,
                // choose highest fps
                let fps = (format.videoSupportedFrameRateRanges.sorted { return $0.maxFrameRate < $1.maxFrameRate }.last) else {
                return
            }
            
            //캡쳐 시작하기
            capturer.startCapture(with: frontCamera,
                                  format: format,
                                  fps: Int(fps.maxFrameRate))
                        
//비디오 트랙을 peer Connection에 추가하기.(로컬 비디오 트랙)           
stream.videoTracks.first?.add(renderer)
```

## 2.로컬 오퍼 생성

로컬 sdp를 만든 후

```swift
self.peersManager!.createLocalOffer(mediaConstraints: sdpConstraints,sendername: self.participantName);
```

방에 들어갔을 때 나를 제외한 다른 사람이 있었을 경우 그 사람의 비디오와 오디오 정보를 받기 위해 sendJson보냄.

```swift
self.webSocketListener!.sendJson(method: "receiveVideoFrom", params: localOfferParams)
```

answer를 받으면 sdpAnswer저장.

Participant에 id 저장.

내가 아닌 다른 피어의 saveAnswer는 RTCMTLVideoView를 이용해 뷰 추가&

스트림에 비디오트랙 추가

## 3. 기존 참가자들 정보처리

1)participant들에 대한 id, name정보들 받으면 모델에 저장.

2)리모트 피어 커넥션 생성.(sdp만들고 오퍼 보냄)

3)나와 기존 참가자들과 연결하기 위한 IceCandidate보내기.

4)비디오 정보 보여주기 위해 receiveVideoFrom소켓으로 보내기

(그러면 이후에 saveAnswer와서 비디오와 오디오 정보 받음)

## 4.새로운 참가자 입장
 ---

 ## 설계 및 구현

 ### 서버 아키텍처
 
<img width="861" alt="Screenshot 2024-09-04 at 2 40 23 PM" src="https://github.com/user-attachments/assets/2d5a5a68-91af-4679-a3f9-272d7c996eab">

 ### 다대다 화상통화 로직
 1. 서버 실행
시그널링 서버는 3000번 포트를 사용하며 , 프레임워크는 express , 사용자별 고유 키값을 위해 session id를 만들어 사용한다.
앞단 nginx 에 ssl 적용을 하고 시그널링 서버로 프록시 해주는 구조라 시그널링 서버를 http로만 올려도 wss로 들어와야한다.
```
const port = normalizePort(process.env.PORT || '3000');
 app.set('port', port);

const sessionHandler = session({
     secret : 'none',
     rolling : true,
     resave : true,
     saveUninitialized : true
 });
 
 app.use(sessionHandler);

const server = http.createServer(app).listen(port, function() {
   console.log('Kurento Tutorial started by [WEBSOCKET]');
 });

const wss = new ws.Server({
   server : server,
   path : '/'
 });
 ```

 2. 클라이언트에서 웹소켓으로 접속
1번에서 언급했듯, nginx에서 미리 ssl을 적용했기 때문에 wss로 웹소켓 연결한다.
연결하는 시점은 참여하기 버튼을 눌렀을때 닉네임과 방 제목을 가져와 뷰에 세팅하고,
JoinRoom 이벤트를 서버에 보낸다.
```
var ws = new WebSocket('wss://kirae.tk/')

//참여하기 버튼 눌렀을때
function register() {
	name = document.getElementById('name').value;
	let roomName = document.getElementById('roomName').value;

	document.getElementById('room-header').innerText = 'ROOM ' + roomName;
	document.getElementById('join').style.display = 'none';
	document.getElementById('room').style.display = 'block';

	let message = {
		method : 'joinRoom',
		params : {
		userName : name,
		roomName : roomName,
	}
	}
	sendMessage(message);
```
3. 서버 : JOINROOM
서버는 클라이언트에게 joinRoom 이벤트를 받아 해당 사용자를 방에 참여시킨다.
```
데이터 예시 : 
{"method":"joinRoom",
	"params":{
		"userName":"ewqewq",
		"roomName":"228"}
 }

switch (message.method) {
        case 'joinRoom':
            console.log(`[joinRoom]----------START----------`)
							joinRoom(ws,session_obj, message, err => {
                if (err) {
                    console.error(`join Room error ${err}`);
                }
            });
            }

function joinRoom(ws,session, message, callback) {

    // 방을 가져온다.
    getRoom(message.params.roomName, (error, room) => {
        if (error) {
            callback(error);
            return;
        }
        // 방을 가져오면 해당 유저를 방에 참여시킨다.
        join(ws,session, room, message.params.userName, (err, user) => {
            console.log(`[join success] : ${user.name}`);
            if (err) {
                callback(err);
                return;
            }
            callback();
        });
    });
}
```
getRoom 이벤트에선 클라이언트가 참여하려는 방을 확인 후 없으면 새로 만들어준다.
- 방이 없을 때
>- 시그널링 서버가 쿠렌토 미디어 서버를 다룰 수 있는 쿠렌토 클라이언트를 생성한다.
>- 쿠렌토 클라이언트를 이용하여 방을 위한 미디어 파이프라인을 생성한다.
>- 파이프라인이 생성이 완료되면 해당 방에 대한 객체정보를 만들어 "방 목록" 에 저장한다.
- 방이 있을 때
>-방 목록에서 해당하는 방정보를 가져온다 . (해당 방정보에는 이미 미디어파이프라인이 생성되어있음)


```
function getRoom(roomName, callback) {
    let room = rooms[roomName];
		//방이 없을때
    if (room == null) {
        console.log(`[create new room] : ${roomName}`);
        	//시그널링서버 <-->쿠렌토 미디어 서버와 연결객체
        getKurentoClient((error, kurentoClient) => {
            if (error) {
                return callback(error);
            }
            console.log(`[get Kurento client] : ${roomName}`);
			//미디어서버에 파이프라인 생성 요청
            kurentoClient.create('MediaPipeline', (error, pipeline) => {
                if (error) {
                    return callback(error);
                }
                console.log(`[create media pipeline for the room] : ${roomName}`);
                //파이프라인이 성공적으로 만들어지면 파이프라인 정보를 room객체에 넣음
                room = {
                    name: roomName,
                    pipeline: pipeline,
                    participants: {},
                    kurentoClient: kurentoClient
                };
                //rooms 배열에 저장
                rooms[roomName] = room;
                callback(null, room);
            });
        });
    } else {
        console.log(`get existing room : ${roomName}`);
        callback(null, room);
    }
}
```

getRoom 메소드에서 방을 가져왔으니 join 메소드에선 유저를 방에 참여시킨다. 하는게 많으니 잘 보아야 함.

**참여자의 미디어 데이터를 보낼 엔드포인트 생성**

- 참여자 객체를 만들고 레지스터에 저장 (서버의 유저목록에 저장)
- 참여하려는 방의 미디어 파이프라인에 **outgoing 엔드포인트**를 만든다.
- outgoing 엔드포인트(**내가 보내는 미디어 데이터 통로**)에 대한 기본설정 후 참여자 객체에 저장한다.
- 중요!! ICEcandidate queue
  join 이벤트 도중 **즉** **outgoing 엔트포인트가 생성되기 이전**에
    
     클라이언트에게 onICEcandidate 이벤트를 전달받게되어 icecandidate를 저장해야 되는 경우가 생긴다. 이때는 , **outgoing 엔드포인트가** 생성되기 전이라 icecandidate를 저장할수 없기 때문에 임시공간인 ICEcandidate queue 에 담아두고 **outgoing 엔드포인트가 생성되면 큐에 임시저장되어있던** icecandidate를 꺼내 저장한다.
    
    ```
    /**session.js
         * ice candidate for this user
         * @param {object} data 
         * @param {object} candidate 
         */
        addIceCandidate(data, candidate) {
            // self
            console.log(`[addIceCandidate] 보내는 사람 ${data.sender} 받는사람 ${this.name} `)
            if (data.sender === this.name) {
                // have outgoing media.
                if (this.outgoingMedia) {
                    console.log(` add candidate to self : %s`, data.sender);
                    this.outgoingMedia.addIceCandidate(candidate);
                } else {
                    // save candidate to ice queue.
                    console.log(` still does not have outgoing endpoint for ${data.sender}`);
                    this.iceCandidateQueue[data.sender].push({
                        data: data,
                        candidate: candidate
                    });
                }
            } else {
                // others
                let webRtc = this.incomingMedia[data.sender];
                if (webRtc) {
                    console.log(`%s add candidate to from %s`, this.name, data.sender);
                    webRtc.addIceCandidate(candidate);
                } else {
                    console.log(`${this.name} still does not have endpoint for ${data.sender}`);
                    if (!this.iceCandidateQueue[data.sender]) {
                        this.iceCandidateQueue[data.sender] = [];
                    }
                    this.iceCandidateQueue[data.sender].push({
                        data: data,
                        candidate: candidate
                    });
                }
            }
        }
    ```
    
- outgoing 엔드포인트 에서 candidate를 받게되면 클라이언트에게  **ICE Candidate 이벤트를 보낸다.**
    
    outgoing 엔드포인트도 **시그널링 서버 입장에서**  **하나의 클라이언트(피어2)이다.** 
    
    IOS클라이언트(피어1)에서 candidate를 받으면 바로 시그널링 서버로 보내듯이   outgoing 엔드포인트도 candidate가 만들어지면 바로 시그널링서버에게 알리고, 클라이언트에게 보낼수 있도록 한다.
    

**기존 참여자들에게 참여를 알리고 (클라이언트에게  participantJoined 이벤트를 보낸다)**

**새 참여자에게는 기존참여자 목록을 전달한다.(클라이언트에게  existingParticipants 이벤트를 보낸다)**

마지막으로 해당 방에 참여자를 저장 한다(서버의 방에 유저 저장)

## 4. 클라이언트 : onExistingParticipants

현재 웹 클라이언트의 경우 register를 보내고 난 이후 **existingParticipants 이벤트** 를 받을때까지 기다린다.

이벤트를 받으면 순서대로

- 나의 비디오, 오디오정보를 설정한다
- 참여자객체(나) 를 생성하고 참여자 목록에 참여자객체(나)를 저장한다.(클라이언트의 유저목록에 저장)
- options 와 WebRtcPeerSendonly 설정
- 참여자 리스트를 받고 참여자 별 receiveVideo 메소드 실행
```
  ws.onmessage = function(message) {
	
	var parsedMessage = JSON.parse(message.data);
	console.info('Received message: ' + parsedMessage.method);
	switch (parsedMessage.method) {
	case 'existingParticipants':
		onExistingParticipants(parsedMessage);
		break;

function onExistingParticipants(msg) {
//나의 비디오, 오디오정보를 설정하고 참여자객체(나) 를 생성한다
	var constraints = {
		audio : true,
		video : {
			mandatory : {
				maxWidth : 320,
				maxFrameRate : 15,
				minFrameRate : 15
			}
		}
	};
	console.log(name + " registered in room " + room);

//참여자객체(나) 를 생성하고 참여자 목록에 참여자객체(나)를 저장한다.
	var participant = new Participant(name);
	participants[name] = participant;
	var video = participant.getVideoElement();
//options 와 WebRtcPeerSendonly
	var options = {
	      localVideo: video,
	      mediaConstraints: constraints,
	      onicecandidate: participant.onIceCandidate.bind(participant)
	}
	participant.rtcPeer = new kurentoUtils.WebRtcPeer.WebRtcPeerSendonly(options,
		function (error) {
		  if(error) {
			  return console.error(error);
		  }
		  this.generateOffer(participant.offerToReceiveVideo.bind(participant));
	});

//참여자 리스트를 받고 참여자 별 receiveVideo 메소드 실행
	msg.data.forEach(receiveVideo);
}
```
## 5. 서버 : onIceCandidate

위의 onExistingParticipants 이벤트의 **WebRtcPeerSendonly , WebRtcPeerRecvonly 에서 kurento util을 통해** onIceCandidate 이벤트를 보내는 것을 알 수 있다. 

다시말해 웹 클라이언트의 candidate 정보를 시그널링 서버로 보내고 있다. 

이벤트를 받은 서버는 

- session을 이용해 레지스터에 등록 해놓았던  보낸 참여자 객체를 찾는다.

## 6. 서버 : receiveVideoFrom

메소드 정의 : 비디오를 받기위해 서로의 sdp 를 교환하는 작업

무조건 내 sdp를  보내고 answer로 엔드포인트의 sdp를 받는다.
