//
//  VideosViewController.swift
//  WebRTCapp
//
//  Created by Sergio Paniego Blanco on 31/05/2018.
//  Copyright © 2018 Sergio Paniego Blanco. All rights reserved.
//

import Foundation
import UIKit
import WebRTC
import ReplayKit
import MaterialComponents
import SCLAlertView
import Vision
import AVFoundation
import SwiftyJSON
import Alamofire

@available(iOS 14.0, *)
class VideosViewController: UIViewController, UITextFieldDelegate {
    
    var handDetectCount : Int = 0
    var gameOwner : String = ""
        
    
    //1.사람 손 감지에 대한 Request생성
    private let handPoseRequest: VNDetectHumanHandPoseRequest = {
      // 1
      let request = VNDetectHumanHandPoseRequest()
      
      // 감지할 손의 최대 갯수를 설정하는 것.
      request.maximumHandCount = 2
      return request
    }()
    
    
    @IBOutlet weak var openYoutubeListBtn: UIButton!
    //정답판 포함한 uiview
    @IBOutlet weak var quizAnswerBoardView: UIView!
    @IBOutlet weak var quizAnswerBtn: UIButton!
    @IBOutlet weak var quizAnswerTF: UITextField!
    @IBOutlet weak var quizAnswerView: UIView!
    @IBOutlet weak var drawerNameLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var startDrawBtn: UIButton!
    @IBOutlet weak var eraseBtn: UIButton!
    @IBOutlet weak var canvasView: UIImageView!
    //그림 그리기 버튼
    @IBOutlet weak var drawingBtn: UIButton!
    //유명인 인식 하기 버튼
    @IBOutlet weak var findSimilarBtn: UIButton!
    //사진에서 텍스트 추출 버튼
    @IBOutlet weak var findTxtBtn: UIButton!
    
    //유명인 얼굴 찾기 버튼 클릭시 true -> capture delegate에서 프레임 캡쳐
    var startCaptureFace : String = ""
    //캡처한 유저 이미지 데이터
    var userFaceImgData : Data? = nil
    //유저 얼굴 분석 정보 저장해놓을 모델 데이터
    var faceModelData : FaceInfo = FaceInfo(name: "", percent: 0, img: "", emotion: "", age: "", gender: "")
    
    var brushColor = UIColor.black.cgColor
    var brushWidth: CGFloat = 10.0
    
    var lastPoint = CGPoint.zero
    var isDrawing = false
    var isPen = false
    
    //그림 보는 사람인 경우
    var isWatcher : Bool = false
    
    //start(시작됐음), exist(이미 진행중인 게임 있음), end(게임 종료됨)
    var gameState : String = ""
    //그리기에서 되돌리기 기능 위해 이전 화면 image이곳에 저장
    var prevDrawing : [UIImage?] = []
    //drawer의 id값
    var drawerID : String = ""
    var testImg: String = ""
    
    @IBAction func findTxtAction(_ sender: Any) {
        if let alert = self.storyboard?.instantiateViewController(withIdentifier: "ScannerViewController") as? ScannerViewController{

            alert.modalPresentationStyle = .popover
            //애니메이션 효과 적용
            alert.modalTransitionStyle = .crossDissolve

            present(alert, animated: true, completion: nil)
        }
        
        
    }
    //유명인 이미지 찾기, 인식하기 클릭 액션
    @IBAction func startFindSimilar(_ sender: Any) {
      
        if let alert = self.storyboard?.instantiateViewController(withIdentifier: "FaceMatchViewController") as? FaceMatchViewController{

            alert.modalPresentationStyle = .popover
            //애니메이션 효과 적용
            alert.modalTransitionStyle = .crossDissolve
            alert.socket = self.socket
            alert.type = "owner"
            present(alert, animated: true, completion: nil)
        }

        startCaptureFace = "start"
        
    }
    
    @IBAction func openYoutubeList(_ sender: Any) {
        print("유튜브 같이 보기 클릭")
        
        if let alert = self.storyboard?.instantiateViewController(withIdentifier: "YoutubeListViewController") as? YoutubeListViewController{
         
            alert.modalPresentationStyle = .overCurrentContext
            //애니메이션 효과 적용
            alert.modalTransitionStyle = .crossDissolve
            alert.socket = self.socket
            present(alert, animated: true, completion: nil)
        }
        
    }
    //그림 되돌리기 버튼
    @IBOutlet weak var undoDrawingBtn: UIButton!
    
    @IBAction func undoClick(_ sender: Any) {
        
        UIGraphicsBeginImageContext(canvasView.frame.size)
        
        guard var context = UIGraphicsGetCurrentContext() else { return }
        print("돌아가기 클릭시 배열 확인: \(self.prevDrawing)")
        canvasView.image! = (self.prevDrawing.popLast() ?? UIImage()) ?? UIImage()
        
        UIGraphicsEndImageContext()
        let imgString = canvasView.image!.toPngString(image: canvasView.image!)
        print("스트링으로 변환한 되돌리기 화면: \(imgString)")
        socket?.sendJson(method: "catchMind", params: ["behavior" : "erase", "option" : "drawBack", "data" : imgString])
        
    }
    //그리기 시작 이벤트
    @IBAction func selectPencil(_ sender: Any) {
        
        //ispen = true일 때 펜처럼 선이 그려짐
        isPen.toggle()
        
        if isPen{
            view.addSubview(canvasView)
            canvasView.isHidden = false
            //이거ㅓㅓㅓㅓㅓㅓㅓㅓㅓㅓㅓㅓㅓㅓㅓ
//            self.canvasView.bringSubview(toFront: canvasView)
            self.drawingBtn.imageView?.image?.withTintColor(UIColor.blue)
            self.view.addSubview(drawingColorListView)
            self.drawingColorListView.isHidden = false
          
            
        }else{
            
            self.drawingBtn.imageView?.image?.withTintColor(UIColor.systemGray4)
            self.drawingColorListView.isHidden = true
            canvasView.isHidden = true
        }
    }
    
    @IBAction func eraseAll(_ sender: Any) {
        print("지우개 버튼")
        eraseDraw()
        
        socket?.sendJson(method: "catchMind", params: ["behavior" : "erase", "option" : "ALL"])
    }
    
    func eraseDraw(){
        self.isPen = false
        self.drawingColorListView.isHidden = true
        canvasView.image = nil
        UIGraphicsBeginImageContext(canvasView.frame.size)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        canvasView.image?.draw(in: canvasView.bounds)
        context.setBlendMode(.clear)
        canvasView.image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        self.brushColor = UIColor.black.cgColor
    }
    
    func drawLine(from: CGPoint, to: CGPoint) {
        print("draw line 메소드 안")
        UIGraphicsBeginImageContext(canvasView.frame.size)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        canvasView.image?.draw(in: canvasView.bounds)
        
        if isPen {
            context.setBlendMode(.normal)
        } else {
            context.setBlendMode(.clear)
        }
        
        context.setLineCap(.round)
        context.setLineWidth(brushWidth)
        context.setStrokeColor(brushColor)
        context.move(to: from)
        context.addLine(to: to)
        context.strokePath()
        
        canvasView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesBegan 메소드 안")
        
        if isPen{
            if self.prevDrawing.last != canvasView.image{
                print("이전 캔버스 이미지가 nil이 아니고 이전 이미지와 현재 저장하려는 이미지가 같지 않을 때")
                self.prevDrawing.append(canvasView.image)
            }
            isDrawing = false
            
            if let touch = touches.first {
                lastPoint = touch.location(in: canvasView)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesMoved 메소드 안")
        
        isDrawing = true
        
        if isPen{
            if let touch = touches.first {
                let currentPoint = touch.location(in: canvasView)
                print("현재 좌표: \(currentPoint)")
                print("마지막 좌표: \(lastPoint)")
                
                drawLine(from: lastPoint, to: currentPoint)
                
                let colorName = self.colorData.first(where: {
                    $0.colorView?.cgColor == self.brushColor
                })?.colorName!
                print("색깔 이름: \(colorName)")
                self.socket?.sendJson(method: "catchMind", params: ["behavior" : "drawing","pastDotX" : self.lastPoint.x,"pastDotY" : self.lastPoint.y, "currentDotX":currentPoint.x, "currentDotY" : currentPoint.y, "color" : colorName!])
                
                lastPoint = currentPoint
            }else{
                print("터치스의 first가 아닌 경우")
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("---------------------------------touchesEnded 메소드 안")
        if isPen{
            if !isDrawing {
                print("!isdrawing인 경우")
                drawLine(from: lastPoint, to: lastPoint)
            }
        }
        isDrawing = false
    }
    
    func showToast(message : String, font: UIFont) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
                        toastLabel.alpha = 0.0
            
        }, completion: {(isCompleted) in
            
                        toastLabel.removeFromSuperview() }
        ) }

    
    //게임 시작할 때 클릭 - startGameBtn으로 이름 바꾸기
    @IBAction func openColorList(_ sender: Any) {
        //게임 시작하기 클릭시 success, exist에 따라서 알림 띄우거나 게임 시작시킴
        
        socket?.sendJson(method: "catchMind", params: ["behavior" : "gameStart"])
    }
    
    @IBOutlet weak var drawingColorListView: UICollectionView!{
        didSet{
            let flowLayout = UICollectionViewFlowLayout()
            
            flowLayout.sectionInset = UIEdgeInsets.zero
            
            flowLayout.minimumInteritemSpacing = 10
            flowLayout.minimumLineSpacing = 10
            flowLayout.scrollDirection = .horizontal
            let halfWidth = UIScreen.main.bounds.width / 3
            flowLayout.itemSize = CGSize(width: halfWidth, height: halfWidth*0.9 )
            
            self.drawingColorListView.collectionViewLayout = flowLayout
        }
    }
    
    var quizList : Array<String> = []
    
    private var colorData : [ColorData]{
        var data = [ColorData]()
        if #available(iOS 13.0, *) {
            data = [
                ColorData(colorName: "red", colorView: UIColor.red), ColorData(colorName: "green", colorView: UIColor.green), ColorData(colorName: "yellow", colorView: UIColor.yellow), ColorData(colorName: "black", colorView: UIColor.black), ColorData(colorName: "purple", colorView: UIColor.purple), ColorData(colorName: "white", colorView: UIColor.white),ColorData(colorName: "blue", colorView: UIColor.blue), ColorData(colorName: "brown", colorView: UIColor.brown)
            ]
        } else {
        }
        return data
    }
    
    @IBOutlet weak var closeStickerViewBtn: UIButton!
    @IBAction func closeStickerView(_ sender: Any) {
        self.stickerContainerView.isHidden = true
    }
    @IBOutlet weak var menuContainerView: UIView!
    @IBOutlet weak var menusBtn: UIButton!
    var showMenus : Bool = false
    @IBAction func showMenus(_ sender: Any) {
        
        showMenus.toggle()
        if showMenus{
            UIView.transition(with: self.menusBtn, duration: 1, options: .transitionFlipFromLeft, animations: nil, completion: {_ in
                self.menusBtn.imageView?.image = UIImage(systemName: "arrowtriangle.down.square.fill")
            })
            
            menuContainerView.addSubview(changeVoiceBtn)
            menuContainerView.addSubview(addTxtBtn)
            menuContainerView.addSubview(addStickerBtn)
            
            UIView.animate(withDuration: 0.3,delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, animations: {
                self.menuContainerView.isHidden = false
            })
        }else{
            
            UIView.transition(with: self.menusBtn, duration: 1, options: .transitionFlipFromLeft, animations: nil, completion: {_ in
                self.menusBtn.imageView?.image = UIImage(systemName: "arrowtriangle.up.square.fill")
            })
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8,animations: {
                self.menuContainerView.isHidden = true
            })
        }
    }
    
    //이미지 스티커 붙이기에서 서버에서 받은 이미지 사이즈
    var imgStickerWidth : CGFloat = 0.0
    var imgStickerHeight : CGFloat = 0.0
    
    @IBOutlet weak var removeAllFilterBtn: UIButton!
    let height: CGFloat = 250
    @IBOutlet weak var addTxtBtn: UIButton!
    @IBOutlet weak var moveImgBtn: UIButton!
    @IBOutlet weak var addStickerConfirmBtn: UIButton!
    @IBOutlet weak var changeVoiceBtn: UIButton!
    var showChangeVoiceMenu: Bool = false
    @IBOutlet weak var ImgResizeBtnView: UIView!
    @IBOutlet weak var plusImgBtn: UIButton!
    @IBOutlet weak var minusImgBtn: UIButton!
    //스티커 이미지 postionx, postiony를 이곳에 저장해야 이미지 크기 조절할 때 이벤트 보낼 때 사용 가능.
    var imgStickerX : CGFloat = 0.0
    var imgStickerY : CGFloat = 0.0
    
    @IBAction func plusImgSizeAction(_ sender: Any) {
        let scale:CGFloat = 0.1
        var newWidth: CGFloat, newHeight: CGFloat
        newWidth = imgStickerWidth+scale
        newHeight = imgStickerHeight+scale
        
        self.socket?.sendJson(method: "imageOverlay", params: ["text": "sfd","positionX" : self.imgStickerX, "positionY": self.imgStickerY, "position": "moveImage", "widthSize" : newWidth, "heightSize" : newHeight])
    }
    
    @IBAction func minusImgSizeAction(_ sender: Any) {
        let scale:CGFloat = 0.1
        var newWidth: CGFloat, newHeight: CGFloat
        newWidth = imgStickerWidth-scale
        newHeight = imgStickerHeight-scale
        
        self.socket?.sendJson(method: "imageOverlay", params: ["text": "sfd","positionX" : self.imgStickerX, "positionY": self.imgStickerY, "position": "moveImage", "widthSize" : newWidth, "heightSize" : newHeight])
    }
    
    //전체 필터 삭제하기 버튼 -> 액션시트에서 필터 삭제하기 시행
    @IBAction func removeAllFilter(_ sender: Any) {
        print("필터 초기화 클릭")
        // 1
        let optionMenu = UIAlertController(title: nil, message: "적용 필터 전체 삭제", preferredStyle: .actionSheet)
        // 2
        let saveAction = UIAlertAction(title: "확인", style: .default, handler: { (action) -> Void in
            //전체삭제
            var filterParams : [String:String] = [:]
            filterParams["removeTarget"] = "ALL"
            self.socket?.sendJson(method: "removeFilter", params: filterParams)
        })
        
        // 3
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        // 4
        optionMenu.addAction(saveAction)
        optionMenu.addAction(cancelAction)
        
        // 5
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    @IBAction func changeVoiceSelected(_ sender: Any) {
        self.showChangeVoiceMenu = true
        
        let contentsVC = storyboard?.instantiateViewController(identifier: "TxtDecoModalVC") as! TxtDecoModalVC
        contentsVC.socket = self.socket
        //음성변조 하기를 선택한 경우 보여질 뷰 case나누기 위함.
        contentsVC.showVoiceMenu = self.showChangeVoiceMenu
        
        let bottomSheet : MDCBottomSheetController = MDCBottomSheetController(contentViewController: contentsVC)
        
        let shapeGenerator = MDCRectangleShapeGenerator()
        
        let cornerTreatment = MDCRoundedCornerTreatment(radius: 8)
        shapeGenerator.topLeftCorner = cornerTreatment
        shapeGenerator.topRightCorner = cornerTreatment
        
        bottomSheet.setShapeGenerator(shapeGenerator, for: .preferred)
        bottomSheet.setShapeGenerator(shapeGenerator, for: .extended)
        bottomSheet.setShapeGenerator(shapeGenerator, for: .closed)
        // 보여지는 높이 조정
        bottomSheet.mdc_bottomSheetPresentationController?.preferredSheetHeight = UIScreen.main.bounds.height*0.45
        bottomSheet.dismissOnBackgroundTap = true
        
        present(bottomSheet, animated: true, completion: nil)
    }
    
    @IBAction func addStickerConfirmAction(_ sender: Any) {
        print("이미지 스티커 추가하기 확인")
        
        var filterParams : [String:Any] = [:]
        //처음 이미지 생성 시 "static"
        //positionx = 왼쪽에서 몇퍼센트에 위치할지 Double(0.0~1.0) 기본값 0.5, y = 위에서 몇퍼센트에 위치할지 Double(0.0~1.0) 기본값
        filterParams["position"] =  "up"
        filterParams["imagePath"] = selectedImg
        
        socket?.sendJson(method: "imageOverlay", params: filterParams)
        print("이미지 꾸미기 데이터 보내기")
        self.stickerContainerView.isHidden = true
        
    }
    
    @IBOutlet weak var stickerCollectionView: UICollectionView!{
        didSet{
            let flowLayout = UICollectionViewFlowLayout()
            
            flowLayout.sectionInset = UIEdgeInsets.zero
            
            flowLayout.minimumInteritemSpacing = 0
            flowLayout.minimumLineSpacing = 0
            flowLayout.scrollDirection = .vertical
            let halfWidth = UIScreen.main.bounds.width*0.2
            flowLayout.itemSize = CGSize(width: halfWidth/3, height: halfWidth/3 )
            
            self.stickerCollectionView.collectionViewLayout = flowLayout
        }
    }
    @IBOutlet weak var addStickerBtn: UIButton!
    @IBAction func addSticker(_ sender: Any) {
        print("이미지 컬렉션뷰 보여주기")
        stickerContainerView.layer.cornerRadius = 10
        stickerContainerView.addSubview(stickerCollectionView)
        stickerContainerView.addSubview(addStickerConfirmBtn)
        stickerContainerView.addSubview(closeStickerViewBtn)
        
        addStickerConfirmBtn.layer.cornerRadius = 5
        closeStickerViewBtn.layer.cornerRadius = 5
        
        stickerContainerView.isHidden = false
        self.stickerCollectionView.isHidden = false
        self.addStickerConfirmBtn.isHidden = false
        self.closeStickerViewBtn.isHidden = false
        
        self.view.bringSubviewToFront(stickerContainerView)
        
    }
    @IBOutlet weak var decoTxtMoveBtn: UIButton!
    @IBAction func showTxtDecoModal(_ sender: Any) {
        self.showChangeVoiceMenu = false
        
        let contentsVC = storyboard?.instantiateViewController(identifier: "TxtDecoModalVC") as! TxtDecoModalVC
        contentsVC.socket = self.socket
        //음성변조 하기를 선택한 경우 보여질 뷰 case나누기 위함.
        contentsVC.showVoiceMenu = self.showChangeVoiceMenu
        
        let bottomSheet : MDCBottomSheetController = MDCBottomSheetController(contentViewController: contentsVC)
        
        let shapeGenerator = MDCRectangleShapeGenerator()
        
        let cornerTreatment = MDCRoundedCornerTreatment(radius: 8)
        shapeGenerator.topLeftCorner = cornerTreatment
        shapeGenerator.topRightCorner = cornerTreatment
        
        bottomSheet.setShapeGenerator(shapeGenerator, for: .preferred)
        bottomSheet.setShapeGenerator(shapeGenerator, for: .extended)
        bottomSheet.setShapeGenerator(shapeGenerator, for: .closed)
        
        bottomSheet.dismissOnBackgroundTap = true
        
        present(bottomSheet, animated: true, completion: nil)
    }
    
    @IBOutlet weak var cameraSwitchBtn: UIButton!
    var mediaSettingChangedId: String? = ""
    
    @IBOutlet weak var localVideoView: UIView!
    
    @IBOutlet weak var filterBtn: UIButton!
    
    @IBAction func switchCamera(_ sender : Any){
        
        self.useBackCamera.toggle()
        
        print("카메라 전환 메소드 안\(useBackCamera)")
        
        switchCam(useBackCamera: useBackCamera)
    }
    
    @IBAction func showFilter(_ sender: Any) {
        print("필터 버튼 클릭")
        
        if filterCollectionView.isHidden{
            filterCollectionView.isHidden = false
            self.view.bringSubviewToFront(filterCollectionView)
        }else{
            filterCollectionView.isHidden = true
            
        }
    }
    //캐치마인드 정답 제출
    @IBAction func sendQuizAnswer(_ sender: Any) {
        print("정답 제출하기 클릭 : \(self.quizAnswerTF.text)")
        socket?.sendJson(method: "catchMind", params: ["behavior" : "questionSubmit", "answer" : self.quizAnswerTF.text])
        self.quizAnswerTF.text = ""
        
    }
    
    var selectedImg : String = ""
    private var stickerData : [StickerData]{
        var data = [StickerData]()
        if #available(iOS 13.0, *) {
            data = [
                StickerData(title: "patric", stickerImg: #imageLiteral(resourceName: "patric")),
                StickerData(title: "cake", stickerImg: #imageLiteral(resourceName: "cake")),
                StickerData(title: "omg", stickerImg: #imageLiteral(resourceName: "omg")),
                StickerData(title: "spongebob", stickerImg: #imageLiteral(resourceName: "spongebob")),
                StickerData(title: "ballon", stickerImg: #imageLiteral(resourceName: "balloon")),
                StickerData(title: "frog", stickerImg: #imageLiteral(resourceName: "frog"))
            ]
        } else {
            // Fallback on earlier versions
        }
        
        return data
    }
    
    @IBOutlet weak var stickerContainerView: UIView!
    
    //참여자 뷰 리스트
    @IBOutlet weak var userCollectionView: UICollectionView!{
        didSet{
            let flowLayout = UICollectionViewFlowLayout()
            
            flowLayout.sectionInset = UIEdgeInsets.zero
            
            flowLayout.minimumInteritemSpacing = 10
            flowLayout.minimumLineSpacing = 10
            flowLayout.scrollDirection = .horizontal
            let halfWidth = UIScreen.main.bounds.width / 3
            flowLayout.itemSize = CGSize(width: halfWidth, height: halfWidth*0.9 )
            
            self.userCollectionView.collectionViewLayout = flowLayout
        }
    }
    
    private var participantList : [String] = []{
        didSet{
        }
    }
    
    private var filterData : [FilterData]{
        var data = [FilterData]()
        if #available(iOS 13.0, *) {
            data = [
                FilterData(title: "원본", filterImage: #imageLiteral(resourceName: "origin_photo")),
                FilterData(title: "bear", filterImage: #imageLiteral(resourceName: "bear")),
                FilterData(title: "bread", filterImage: #imageLiteral(resourceName: "bread")),
                FilterData(title: "eyes", filterImage: #imageLiteral(resourceName: "eye")),
                FilterData(title: "surprise", filterImage: #imageLiteral(resourceName: "surprise")),
                FilterData(title: "pickachu", filterImage: #imageLiteral(resourceName: "pickachu")),
                FilterData(title: "rabbit", filterImage: #imageLiteral(resourceName: "rabbit"))
                
            ]
        } else {
            // Fallback on earlier versions
        }
        
        return data
    }
    
    @IBOutlet weak var filterCollectionView: UICollectionView!{
        didSet{
            let flowLayout = UICollectionViewFlowLayout()
            
            flowLayout.sectionInset = UIEdgeInsets.zero
            
            flowLayout.minimumInteritemSpacing = 10
            flowLayout.minimumLineSpacing = 10
            flowLayout.scrollDirection = .horizontal
            let halfWidth = UIScreen.main.bounds.width*0.2
            flowLayout.itemSize = CGSize(width: halfWidth, height: halfWidth )
            
            self.filterCollectionView.collectionViewLayout = flowLayout
        }
    }
    
    var peersManager: PeersManager?
    var socket: WebSocketListener?
    var localAudioTrack: RTCAudioTrack?
    var localVideoTrack: RTCVideoTrack?
    var videoSource: RTCVideoSource?
    private var videoCapturer: RTCVideoCapturer?
    //var localVideoSource: RTCVideoSource!
    var url: String = ""
    var sessionName: String = ""
    var participantName: String = ""
    
    var remoteViews: [UIView]?
    
    var remoteNames: [UILabel]!
    
    var videoState : Bool = true
    var audioState : Bool = true
    
    @IBOutlet weak var videoBtn: UIButton!
    
    @IBAction func videoSettingBtn(_ sender: Any) {
        print("비디오 on/off 버튼 클릭")
        if videoState{
            print("[VIDEO OFF]")
            let videoTracks = socket?.localPeer?.localStreams[0].videoTracks.forEach({ video in
                video.isEnabled = false
                
                videoBtn.imageView?.image = UIImage(systemName: "video.slash.fill")
            })
        }else{
            print("[VIDEO ON]")
            let videoTracks = socket?.localPeer?.localStreams[0].videoTracks.forEach({ video in
                video.isEnabled = true
                videoBtn.imageView?.image = UIImage(systemName: "video.fill")
            })
        }
        videoState.toggle()
        var params : [String : Any]  = [:]
        params["audio"] = audioState
        params["video"] = videoState
        socket?.sendJson(method: "setMediaStream", params: params)
    }
    
    @IBOutlet weak var micBtn: UIButton!
    
    @IBAction func micSettingBtn(_ sender: Any) {
        print("오디오 on/off 버튼 클릭")
        
        if audioState{
            print("[AUDIO OFF]")
            let audioTracks = socket?.localPeer?.localStreams[0].audioTracks.forEach({ audio in
                audio.isEnabled = false
                micBtn.imageView?.image = UIImage(systemName: "mic.slash.fill")
            })
        }else{
            print("[AUDIO ON]")
            let audioTracks = socket?.localPeer?.localStreams[0].audioTracks.forEach({ audio in
                audio.isEnabled = true
                micBtn.imageView?.image = UIImage(systemName: "mic.fill")
                
            })
        }
        audioState.toggle()
        var params : [String : Any]  = [:]
        params["audio"] = audioState
        params["video"] = videoState
        socket?.sendJson(method: "setMediaStream", params: params)
    }
    
    @IBOutlet weak var cameraView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        remoteViews = [UIView]()
        //remoteViews?.append(collectionView)
        view.addSubview(userCollectionView)
        userCollectionView.delegate = self
        userCollectionView.dataSource = self
        userCollectionView.backgroundColor = .clear
        //        userCollectionView.register(ItemCell.self, forCellWithReuseIdentifier: "ItemCell")
        userCollectionView.register(UINib(nibName: "ItemCell", bundle: nil), forCellWithReuseIdentifier: "ItemCell")
        view.addSubview(filterCollectionView)
        filterCollectionView.delegate = self
        filterCollectionView.dataSource = self
        filterCollectionView.backgroundColor = .clear
        filterCollectionView.register(UINib(nibName: "FilterCell", bundle: nil), forCellWithReuseIdentifier: "FilterCell")
        //filterCollectionView.contentMode = .scaleAspectFit
        remoteNames = [UILabel]()
        // self.view.addSubview(filterBtn)
        
        view.addSubview(stickerContainerView)
        stickerCollectionView.delegate = self
        stickerCollectionView.dataSource = self
        stickerCollectionView.register(UINib(nibName: "StickerCell", bundle: nil), forCellWithReuseIdentifier: "StickerCell")
        
        view.addSubview(drawingColorListView)
        drawingColorListView.delegate = self
        drawingColorListView.dataSource = self
        drawingColorListView.register(UINib(nibName: "ColorCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ColorCollectionViewCell")
        
        view.addSubview(filterBtn)
        view.addSubview(videoBtn)
        view.addSubview(micBtn)
        //view.addSubview(addTxtBtn)
        view.addSubview(cameraSwitchBtn)
        
        view.addSubview(addStickerConfirmBtn)
        view.addSubview(moveImgBtn)
        //view.addSubview(changeVoiceBtn)
        view.addSubview(decoTxtMoveBtn)
        //view.addSubview(addStickerBtn)
        //이미지 스티커 확대, 축소 버튼 포함한 뷰
        view.addSubview(ImgResizeBtnView)
        //필터 전체 초기화
        view.addSubview(removeAllFilterBtn)
        view.addSubview(menuContainerView)
        view.addSubview(menusBtn)
        
        //캐치마인드 전체 지우기 버튼
        view.addSubview(eraseBtn)
        //캐치마인드 연필 버튼
        view.addSubview(startDrawBtn)
        //캐치마인드 이전 돌리기 버튼
        view.addSubview(undoDrawingBtn)
        
        //게임 시간 프로그래스바
        view.addSubview(progressView)
        progressView.isHidden = true
        
        view.addSubview(quizAnswerBoardView)
        quizAnswerBoardView.isHidden = true
        
        view.addSubview(drawerNameLabel)
        view.addSubview(quizAnswerView)
        self.quizAnswerView.round(corners: [.topLeft, .topRight], cornerRadius: 20)
        self.quizAnswerView.addShadow(shadowColor: .black, offSet: CGSize(width: 2.6, height: 2.6), opacity: 0.8, shadowRadius: 5.0, cornerRadius: 20, corners: [.topRight, .topLeft], fillColor: .white)
        
        quizAnswerTF.delegate = self
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:))))
        
        view.addSubview(findSimilarBtn)
        view.addSubview(findTxtBtn)
    }
    
    @objc func keyboardWillShow(noti: Notification) {
         //self.view.frame.origin.y = -150 // Move view 150 points upward
        var height : CGFloat = 0.0
        if let keyboardFrame: NSValue = noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            height = keyboardRectangle.height
            print("keyboardHeight = \(height)")
            
        }
        var testHeight = UIScreen.main.bounds.height

      var answerViewHeight = testHeight*0.49261083743842365
        //var answerViewHeight = testHeight*0.41
        self.quizAnswerView.frame.origin.y = CGFloat(answerViewHeight)
        }

    @objc func keyboardWillHide(_ sender: Notification) {

   // self.view.frame.origin.y = 0 // Move view to original position
        self.quizAnswerView.frame.origin.y = 700
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        print("BUTTTON PRESSED")
        self.socket?.sendJson(method: "leaveRoom", params: [:])
        self.socket?.socket.disconnect()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("View will Appear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("Did Appear")
        print("로컬 비디오 뷰 create")
        //은열수정
        #if arch(arm64)
        let renderer = RTCMTLVideoView(frame: self.localVideoView.frame)
        #else
        let renderer = RTCEAGLVideoView(frame: self.localVideoView.frame)
        #endif
        self.peersManager = PeersManager(view: self.view, renderer: renderer)
        
        start(renderer: renderer)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func start(renderer: RTCVideoRenderer) {
        self.createSocket(token: "")
        print("오픈 비두 url아닐 경우")
        
        DispatchQueue.main.async {
            
            self.createLocalVideoView(renderer: renderer, useBackCamera: self.useBackCamera)
            
            let mandatoryConstraints = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"]
            let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
            
            self.peersManager!.createLocalOffer(mediaConstraints: sdpConstraints,sendername: self.participantName);
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(getParticipantCount(noti:)), name: Notification.Name("add_existing_participant"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(saveAnswerNoti(noti:)), name: Notification.Name("saveAnswerNoti"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(setLocalMedia(noti:)), name: Notification.Name("setLocalMedia"), object: nil)
        
        //텍스트 띄우기에서 위치 이동위한 버튼 만들기 위해 포지션 값 받아서 세팅.
        NotificationCenter.default.addObserver(self, selector: #selector(setDecoTxtValue(noti:)), name: Notification.Name("setDecoTxtValue"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(setDecoImgValue(noti:)), name: Notification.Name("setDecoImgValue"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(allFilterDeleted(noti:)), name: Notification.Name("allFilterDeleted"), object: nil)
        
        //캐치마인드 (그림 받는 사람)이 이벤트 받은 경우
        NotificationCenter.default.addObserver(self, selector: #selector(drawing(noti:)), name: Notification.Name("catchMind"), object: nil)
        
        //캐치 마인드 게임 시작 요청 응답 2가지 유형 - game start, game exist
        NotificationCenter.default.addObserver(self, selector: #selector(gameStartResponse(noti:)), name: Notification.Name("catchMindResponse"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.watchYoutube), name: Notification.Name("youtube"), object: nil)
        
        //닮은 유명인 찾기, 얼굴 분석 상대방이 했다는 결과 받았을 때
        NotificationCenter.default.addObserver(self, selector: #selector(imageShare(noti:)), name: Notification.Name("imageShare"), object: nil)
        
        
        if socket?.participants.count ?? 0 > 0{
            for i in self.socket!.participants{
                
                print("start에서 self.participantList: \(self.participantList)")
                
                if !self.participantList.contains(i.value.id!){
                    
                    print("start에서 participant추가 후: \(self.participantList)")
                    self.participantList.append(i.value.id!)
                }
            }
        }
    }
    
    @IBOutlet weak var quizAnswerImgView: UIImageView!
    
    @objc func imageShare(noti: Notification){
        print("닮은 꼴 상대방이 찾았다는 노티 받음: \(noti.userInfo)")
        let img = noti.userInfo?["imageLink"] as! String
        let userName = noti.userInfo?["userName"] as! String
        let name = noti.userInfo?["name"] as! String
        let userImgStr = noti.userInfo!["userImageStr"] as! String
        
        let userImg = userImgStr.imageFromBase64(imgString: userImgStr)
        
        if let alert = self.storyboard?.instantiateViewController(withIdentifier: "FaceMatchViewController") as? FaceMatchViewController{
         
            
            alert.modalPresentationStyle = .formSheet
            //애니메이션 효과 적용
            alert.modalTransitionStyle = .crossDissolve
            alert.faceInfo.userImg = userImg
            alert.faceInfo.name = name
            alert.faceInfo.img = img
            alert.type = userName
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    func createImageWithLabelOverlay(text: String, isFromCamera: Bool = false) -> UIImage? {
        
        let imageSize = self.quizAnswerImgView.image?.size ?? .zero
            UIGraphicsBeginImageContextWithOptions(CGSize(width: imageSize.width, height: imageSize.height), false, 1.0)
        
            let currentView = UIView(frame: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        
        let currentImage = UIImageView(image: self.quizAnswerImgView.image)
            currentImage.frame = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
            currentView.addSubview(currentImage)

            let label = UILabel()
            label.frame = currentView.frame
            let fontSize: CGFloat = isFromCamera ? 50 : 50
            let font = UIFont(name:"Noteworthy-Light" , size: fontSize)
            let attributedStr = NSMutableAttributedString(string: text)
            attributedStr.addAttribute(NSAttributedString.Key(rawValue: kCTFontAttributeName as String), value: font ?? .init(), range: (text as NSString).range(of: text))
        attributedStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: (text as NSString).range(of: text))

            label.attributedText = attributedStr
            label.numberOfLines = 0
            label.textAlignment = .center
            label.text = text
            label.center = currentView.center
        
            currentView.addSubview(label)

            guard let currentContext = UIGraphicsGetCurrentContext() else {
                return nil
            }
            currentView.layer.render(in: currentContext)
            let img = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return img
        }
    
    @objc func watchYoutube(noti: Notification){

        let behavior = noti.userInfo!["behavior"] as! String
        
        if behavior == "watchVideo"{
            print("유튜브 같이 보기 노티 받음: \(noti.userInfo)")

        let videoKey = noti.userInfo!["videoKey"] as! String
        
        let alert = WebViewController()
           self.navigationController?.pushViewController(alert, animated: true)
           
            alert.modalPresentationStyle = .overCurrentContext
           //애니메이션 효과 적용
           alert.modalTransitionStyle = .crossDissolve
           alert.videoKey = videoKey
            alert.socket = self.socket

           present(alert, animated: true, completion: nil)
        }
        
    }
    
    @IBOutlet weak var answerLabel: UILabel!
    @objc func gameStartResponse(noti: Notification){
        let result = noti.userInfo!["result"] as! String
        print("게임 시작 후 response 받음")
        if result == "success"{
            self.gameState = "start"
//            self.videoSource = peersManager?.peerConnectionFactory?.videoSource()
//            //비디오 트랙은 안해도 되는지
//            self.videoCapturer = RTCCameraVideoCapturer(delegate: self)

            let questions = noti.userInfo!["questions"] as! Array<String>
            self.quizList = questions

            print("출제 문제 배열 확인: \(questions)")

            //첫 출제자 이름
            let drawerName = noti.userInfo!["drawerName"] as! String
            //첫 출제자 id
            let drawerID = noti.userInfo!["drawerId"] as! String
            self.drawerID = drawerID
            self.gameOwner = drawerID
            self.drawerNameLabel.text = "출제자:\(drawerName)"

            //내가 출제자인 경우에만 hidden시키기*************
            if PeersManager.myId == drawerID{

                self.quizAnswerBoardView.isHidden = false
                self.quizAnswerBoardView.addSubview(quizAnswerImgView)
                answerLabel.text = questions[0]
                self.quizAnswerBoardView.addSubview(answerLabel)

            startDrawBtn.isHidden = false
            eraseBtn.isHidden = false
            undoDrawingBtn.isHidden = false

            }
            progressView.isHidden = false
            drawerNameLabel.isHidden = false

            progressView.frame = CGRect(x: 10, y: 114, width: view.frame.size.width-20, height: 5)
            progressView.transform = progressView.transform.scaledBy(x: 1, y: 5)
            progressView.round(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], cornerRadius: 20)

            //타이머가 다시 작동되는 경우 : 첫 게임 시작, 타임아웃, 문제 변경시
            timer = Timer.scheduledTimer(timeInterval: 1.0,target: self, selector: #selector(updateTimer),userInfo: nil, repeats: true)
            RunLoop.current.add(timer, forMode: RunLoop.Mode.common)

        }else if result == "game exist"{
            self.gameState = "game exist"

            self.showToast(message: "이미 게임중입니다.", font: UIFont.boldSystemFont(ofSize: 14.0))
        }
        else if result == "error"{
            self.showToast(message: "다시 시도해주세요", font: UIFont.boldSystemFont(ofSize: 14.0))
        }
    }
    var timer = Timer()
    //몇초가 지났는지의 값
    var secondsPassed = 0
    //300으로 바꿔야 함
    var totalTime = 60
    var questionPassed = 0
    
    @objc func updateTimer(){
        
        DispatchQueue.main.async {
            
            if self.secondsPassed < self.totalTime{
                self.secondsPassed += 1
                self.progressView.progress = Float(self.secondsPassed) / Float(self.totalTime)
        }
        else{
            self.questionPassed += 1
            //타이머 작동 중지
            self.secondsPassed = 0
            self.timer.invalidate()
            print("업데이트 타이머에서 타이머 작동 중지")
                        
            if self.quizList.count > self.questionPassed && self.drawerID == PeersManager.myId{
                print("퀴즈가 남았지만 맞추지 못하고 시")
                self.socket?.sendJson(method: "catchMind", params: ["behavior" : "timeout"])
                
            }else if self.quizList.count-1 < self.questionPassed && self.drawerID == PeersManager.myId{
                print("퀴즈를 다 못풀고 시간초과됨")
                self.socket?.sendJson(method: "catchMind", params: ["behavior" : "timeout"])
            }
        }
        }
    }
    
    //그리기 이벤트 받는 사람
    @objc func drawing(noti: Notification){
        let eventType = noti.userInfo!["behavior"] as! String
        print("캐치마인드 노티 받음: \(eventType)")

        //지우기 이벤트 받았을 때
        if eventType == "erase"{
            
            let eraseOption = noti.userInfo!["option"] as! String
            if eraseOption == "ALL"{
                self.isPen = false
                
                canvasView.image = nil
                UIGraphicsBeginImageContext(canvasView.frame.size)
                
                guard let context = UIGraphicsGetCurrentContext() else { return }
                
                canvasView.image?.draw(in: canvasView.bounds)
                context.setBlendMode(.clear)
                
                canvasView.image = UIGraphicsGetImageFromCurrentImageContext()
                
                UIGraphicsEndImageContext()
                
            }else if eraseOption == "drawBack"{
                
                let data = noti.userInfo!["data"] as! String
                //string->uiimage만들기
                let changedImg = data.imageFromBase64(imgString: data)
                canvasView.image = changedImg
                            }
            //drawing(그림 그리기), gameStart(게임 시작됐다)
        }
        else if eventType == "drawing"{
            print("drawing이벤트 노티로 받았을 때")
            
            view.addSubview(canvasView)
            canvasView.isHidden = false
            
            let lastPointX = noti.userInfo!["pastDotX"] as! CGFloat
            let lastPointY = noti.userInfo!["pastDotY"] as! CGFloat
            let currentPointX = noti.userInfo!["currentDotX"] as! CGFloat
            let currentPointY = noti.userInfo!["currentDotY"] as! CGFloat
            
            let color = noti.userInfo!["color"] as! String
            let drawerId = noti.userInfo!["id"] as! String
            let drawerNick = noti.userInfo!["name"] as! String
            
            self.brushColor = (colorData.first{
                $0.colorName == color
            }?.colorView!.cgColor)!
            
            UIGraphicsBeginImageContext(canvasView.frame.size)
            
            guard let context = UIGraphicsGetCurrentContext() else { return }
            canvasView.image?.draw(in: canvasView.bounds)
            context.setBlendMode(.normal)
            
            let fromPoint = CGPoint(x: lastPointX, y: lastPointY)
            let toPoint =  CGPoint(x: currentPointX, y: currentPointY)
            
            context.setLineCap(.round)
            context.setLineWidth(brushWidth)
            context.setStrokeColor(brushColor)
            context.move(to: fromPoint)
            context.addLine(to: toPoint)
            context.strokePath()
            
            canvasView.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            //정답 제출한 결과
        }else if eventType == "questionSubmit"{
            print("정답 제출 결과 이벤트")
            let result = noti.userInfo!["result"] as! String
            
            //다음 문제로 넘기기, 다른 유저에게 넘기기
            if result == "success"{
                eraseDraw()
                timer.invalidate()
                print("정답임 타이머 작동하는지: \(timer.isValid)")
                secondsPassed = 0
                timer = Timer.scheduledTimer(timeInterval: 1.0,target: self, selector: #selector(updateTimer),userInfo: ["answer": "success"], repeats: true)
                RunLoop.current.add(timer, forMode: RunLoop.Mode.common)

                
                let nextDrawerId = noti.userInfo!["drawerId"] as! String
                let nextDrawerNick = noti.userInfo!["drawerName"] as! String
                let successPersonNick = noti.userInfo!["submiterName"] as! String
                let answer = noti.userInfo!["answer"] as! String
                self.drawerID = nextDrawerId
                
                SCLAlertView().showSuccess("정답 \(answer)", subTitle: "\(successPersonNick)님이 맞추셨습니다!")
                //DispatchQueue.main.async { [self] in
                    self.drawerNameLabel.text = "출제자:\(nextDrawerNick)"
                
                //타이머 시간 지났을 경우만 +1을 해줬었으므로 정답인 경우 여기에서 +1을 추가로 해줘야함
                self.questionPassed += 1
                    if self.drawerID != PeersManager.myId{
                        print("내가 출제자 이제 아님")
                        self.canvasView.isHidden = true
                        
                        self.startDrawBtn.isHidden = true
                        self.eraseBtn.isHidden = true
                        self.undoDrawingBtn.isHidden = true
                        self.quizAnswerBoardView.isHidden = true
                        //self.quizAnswerView.isHidden = false
                        
                    }else{
                        print("내가 출제자님")

                        //출제자인 경우
                        //그리기 버튼들 뷰
                        self.startDrawBtn.isHidden = false
                        self.eraseBtn.isHidden = false
                        self.undoDrawingBtn.isHidden = false

                        //정답판 뷰
                        self.quizAnswerBoardView.isHidden = false
                        self.quizAnswerBoardView.addSubview(self.quizAnswerImgView)
                        self.quizAnswerBoardView.addSubview(self.answerLabel)
                        self.answerLabel.text = self.quizList[questionPassed]
                        self.quizAnswerView.isHidden = true
                        
                        //그림 초기화시키는 것
                        self.canvasView.image = nil
                        UIGraphicsBeginImageContext(self.canvasView.frame.size)
                        
                        guard let context = UIGraphicsGetCurrentContext() else { return }
                        
                        self.canvasView.image?.draw(in: canvasView.bounds)
                        context.setBlendMode(.clear)
                        
                        self.canvasView.image = UIGraphicsGetImageFromCurrentImageContext()
                        
                        UIGraphicsEndImageContext()
                    }
                //}
                self.view.setNeedsDisplay()
             
            }else if result == "fail"{
                
                let failerNick = noti.userInfo!["submiterName"] as! String
                let answer = noti.userInfo!["answer"] as! String

                SCLAlertView().showError("오답 \(answer)", subTitle: "\(failerNick)님 틀렸습니다!")
                
            }else if result == "gameEnd"{
                //모두 시간 내에 정답 못맞춰서 출제자가 timeout보냈을 때 게임 끝 response
                let gameResult = noti.userInfo!["gameResult"] as! Array<Any>
                print("게임 결과: \(gameResult)")
                var sendGameResultData :[GameResult] = []
                
                for user in gameResult{
                 let member = JSON(user)
                    sendGameResultData.append(GameResult(nicckName: member["name"].stringValue, count: member["count"].intValue))
                }
                print("저장한 게임 결과 데이터: \(sendGameResultData)")
                
                //id, name, count
                //정답제출자 정보 & 게임 결과 정보
                timer.invalidate()
                print("타이머 실행 여부: \(timer.isValid)")
                self.gameState = "end"
                
                if let alert = self.storyboard?.instantiateViewController(withIdentifier: "QuizResultViewController") as? QuizResultViewController{
                 
                    alert.modalPresentationStyle = .overCurrentContext
                    //애니메이션 효과 적용
                    alert.modalTransitionStyle = .crossDissolve
                    alert.gameResult = sendGameResultData
                    
                    present(alert, animated: true, completion: nil)
                }
                
                //게임 관련 뷰들 hidden시키기
                self.quizAnswerView.isHidden = true
                //게임 시작 버튼
                self.drawingBtn.isHidden = true
                self.eraseBtn.isHidden = true
                self.quizAnswerBoardView.isHidden = true
                self.undoDrawingBtn.isHidden = true
                self.startDrawBtn.isHidden = true
                self.progressView.isHidden = true
                self.isPen = false
                self.drawingColorListView.isHidden = true
                self.drawerNameLabel.isHidden = true
            }
            
            
        }else if eventType == "timeout"{
            let result = noti.userInfo!["result"] as! String
            print("타임아웃에서 \(result) ")
            eraseDraw()
            //이게 그리는 사람한테만 오는건지?
            if result == "newQuestion"{
                print("questionPassed: \(questionPassed)")
                print("quizList: \(quizList)")

                let drawerId = noti.userInfo!["drawerId"] as! String
                self.drawerID = drawerId
                let drawerName = noti.userInfo!["drawerName"] as! String
                self.drawerNameLabel.text = "출제자:\(drawerName)"
                print("다음 단어 : \(self.quizList[questionPassed])")
                print("내 아이디: \(PeersManager.myId), 그리는 사람: \(drawerID)")
                //정답 입력 텍스트필드, 제출버튼 포함한 뷰
                if drawerID != PeersManager.myId{
                    
                    canvasView.isHidden = true
                    
                //self.quizAnswerView.isHidden = true
                    startDrawBtn.isHidden = true
                    eraseBtn.isHidden = true
                    undoDrawingBtn.isHidden = true
                    quizAnswerBoardView.isHidden = true
                    //quizAnswerView.isHidden = false
                    
                }else{
                    //출제자인 경우
                    //그리기 버튼들 뷰
                    startDrawBtn.isHidden = false
                    eraseBtn.isHidden = false
                    undoDrawingBtn.isHidden = false

                    //정답판 뷰
                    self.quizAnswerBoardView.isHidden = false
                    self.quizAnswerBoardView.addSubview(quizAnswerImgView)
                    self.quizAnswerBoardView.addSubview(answerLabel)
                    answerLabel.text = self.quizList[questionPassed]
                    quizAnswerView.isHidden = true
                    
                    //그림 초기화시키는 것
                    canvasView.image = nil
                    UIGraphicsBeginImageContext(canvasView.frame.size)
                    
                    guard let context = UIGraphicsGetCurrentContext() else { return }
                    
                    canvasView.image?.draw(in: canvasView.bounds)
                    context.setBlendMode(.clear)
                    
                    canvasView.image = UIGraphicsGetImageFromCurrentImageContext()
                    
                    UIGraphicsEndImageContext()
                }
                timer.invalidate()
                timer = Timer.scheduledTimer(timeInterval: 1.0,target: self, selector: #selector(updateTimer),userInfo: nil, repeats: true)
                RunLoop.current.add(timer, forMode: RunLoop.Mode.common)

            }else if result == "gameEnd"{
                
                //모두 시간 내에 정답 못맞춰서 출제자가 timeout보냈을 때 게임 끝 response
                let gameResult = noti.userInfo!["gameResult"] as! Array<Any>
                print("게임 결과: \(gameResult)")
                var sendGameResultData :[GameResult] = []
                
                for user in gameResult{
                 let member = JSON(user)
                    sendGameResultData.append(GameResult(nicckName: member["name"].stringValue, count: member["count"].intValue))
                }
                print("저장한 게임 결과 데이터: \(sendGameResultData)")
                
                //id, name, count
                //정답제출자 정보 & 게임 결과 정보
                timer.invalidate()
                print("타이머 실행 여부: \(timer.isValid)")
                self.gameState = "end"
                
                if let alert = self.storyboard?.instantiateViewController(withIdentifier: "QuizResultViewController") as? QuizResultViewController{
                 
                    alert.modalPresentationStyle = .overCurrentContext
                    //애니메이션 효과 적용
                    alert.modalTransitionStyle = .crossDissolve
                    alert.gameResult = sendGameResultData
                    
                    present(alert, animated: true, completion: nil)
                }
                
                //게임 관련 뷰들 hidden시키기
                self.quizAnswerView.isHidden = true
                //게임 시작 버튼
                self.drawingBtn.isHidden = true
                self.eraseBtn.isHidden = true
                self.quizAnswerBoardView.isHidden = true
                self.undoDrawingBtn.isHidden = true
                self.startDrawBtn.isHidden = true
                self.progressView.isHidden = true
                self.isPen = false
                self.drawingColorListView.isHidden = true
                self.drawerNameLabel.isHidden = true
            }
        }
        else if eventType == "gameStart"{
            self.gameState = "start"
//            self.videoSource = peersManager?.peerConnectionFactory?.videoSource()
//            //비디오 트랙은 안해도 되는지
//            self.videoCapturer = RTCCameraVideoCapturer(delegate: self)

            
            self.drawerID = noti.userInfo!["drawerId"] as! String
            let drawerNick = noti.userInfo!["drawerName"] as! String
            self.drawerNameLabel.text = "출제자:\(drawerNick)"
            self.quizList = noti.userInfo!["questions"] as! Array<String>
            
            drawerNameLabel.isHidden = false
            
            self.view.addSubview(progressView)
            
            progressView.frame = CGRect(x: 10, y: 114, width: view.frame.size.width-20, height: 5)
            progressView.transform = progressView.transform.scaledBy(x: 1, y: 5)
            progressView.round(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], cornerRadius: 20)
            
            timer = Timer.scheduledTimer(timeInterval: 1.0,target: self, selector: #selector(updateTimer),userInfo: nil, repeats: true)
            RunLoop.current.add(timer, forMode: RunLoop.Mode.common)

            progressView.isHidden = false
            
        }
        else if eventType == "submitterPermission"{
            let result = noti.userInfo!["result"] as! String
            if result == "success"{
                print("정답 권한 success")
                let submitterId = noti.userInfo!["submitterId"] as! String
                //정답 입력 텍스트 필드 띄우기
                //답 입력하는 뷰
                if PeersManager.myId == submitterId{
                    self.quizAnswerView.isHidden = false
                quizAnswerView.addSubview(quizAnswerTF)
                quizAnswerView.addSubview(quizAnswerBtn)
                    quizAnswerTF.attributedPlaceholder = NSAttributedString(string: "정답을 입력하세요", attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray])
                    
                    self.view.bringSubviewToFront(quizAnswerView)
                    //키보드에 따라 뷰 올리기 위함.
                    self.quizAnswerView.addGestureRecognizer(UITapGestureRecognizer(target: self.quizAnswerView, action: #selector(UIView.endEditing(_:))))
                
                }
                
            }else if result == "fail"{
                //
                print("정답 권한 fail")
            }
            else if result == "resetPermission"{
                let submitterId = noti.userInfo!["submitterId"] as! String

                //정답 제출 뷰 지우기
                print("정답 권한 resetPermission")
                if PeersManager.myId == submitterId{
                quizAnswerView.isHidden = true
                }
            }
            
        }
    }
    
    @objc func allFilterDeleted(noti: Notification){
        self.moveImgBtn.isHidden = true
        self.decoTxtMoveBtn.isHidden = true
        self.ImgResizeBtnView.isHidden = true
    }
    
    @objc func setDecoImgValue(noti: Notification){
        
        let imagePath = noti.userInfo!["imagePath"] as! String
        
        guard var positionX = noti.userInfo!["positionX"] as? CGFloat else{
            return
        }
        self.imgStickerX = positionX
        guard var positionY = noti.userInfo!["positionY"] as? CGFloat else{
            return
        }
        self.imgStickerY = positionY
        
        guard let imgStickerWidth = noti.userInfo!["widthSize"] as? CGFloat else{
            return
        }
        
        guard let imgStickerHeight = noti.userInfo!["heightSize"] as? CGFloat else{
            return
        }
        
        self.imgStickerWidth = imgStickerWidth
        self.imgStickerHeight = imgStickerHeight
        
        //이미지 옮기기 버튼 위치 설정
        moveImgBtn.center.x = UIScreen.main.bounds.width*positionX
        moveImgBtn.center.y = UIScreen.main.bounds.height*positionY
        moveImgBtn.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(imgHandler)))
        moveImgBtn.isHidden = false
        
        //이미지 확대, 축소 버튼 위치 설정
        ImgResizeBtnView.center.x = UIScreen.main.bounds.width*positionX+50
        ImgResizeBtnView.center.y = UIScreen.main.bounds.height*positionY
        ImgResizeBtnView.addSubview(plusImgBtn)
        ImgResizeBtnView.addSubview(minusImgBtn)
        ImgResizeBtnView.isHidden = false
        
        print("텍스트 위치 확인: \(UIScreen.main.bounds.width*positionX), \(UIScreen.main.bounds.height*positionY), \(positionX), \(positionY)")
        
    }
    
    @objc func setDecoTxtValue(noti: Notification){
        
        let text = noti.userInfo!["text"] as! String
        
        guard var positionX = noti.userInfo!["positionX"] as? CGFloat else{
            return
        }
        
        guard var positionY = noti.userInfo!["positionY"] as? CGFloat else{
            return
        }
        
        //decoTxtMoveBtn.setTitle("\(text)", for: UIControlState.normal)
        decoTxtMoveBtn.center.x = UIScreen.main.bounds.width*positionX
        decoTxtMoveBtn.center.y = UIScreen.main.bounds.height*positionY
        decoTxtMoveBtn.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handler)))
        decoTxtMoveBtn.isHidden = false
        
        print("텍스트 위치 확인: \(UIScreen.main.bounds.width*positionX), \(UIScreen.main.bounds.height*positionY), \(positionX), \(positionY)")
        
    }
    @objc func imgHandler(gesture: UIPanGestureRecognizer){
        print(gesture.location(in: self.view))
        
        let location = gesture.location(in: self.view)
        let draggedView = gesture.view
        draggedView?.center = location
        
        if gesture.state == .ended {
            print("끝났을 때 이벤트")
            
            if self.moveImgBtn.frame.midX >= self.view.layer.frame.width / 2 {
                
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    
                    self.moveImgBtn.center.x = location.x
                    self.moveImgBtn.center.y = location.y
                    
                }, completion: { _ in
                    
                    self.socket?.sendJson(method: "imageOverlay", params: ["text": "sfd","positionX" : self.moveImgBtn.center.x/UIScreen.main.bounds.width, "positionY": self.moveImgBtn.center.y/UIScreen.main.bounds.height, "position": "moveImage"])
                })
                
            }else{
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    
                    self.moveImgBtn.center.x = location.x
                    self.moveImgBtn.center.y = location.y
                    
                }, completion: {_ in
                    self.socket?.sendJson(method: "imageOverlay", params: ["text": "sfd","positionX" : self.moveImgBtn.center.x/UIScreen.main.bounds.width, "positionY": self.moveImgBtn.center.y/UIScreen.main.bounds.height, "position": "moveImage"])
                    
                })
            }
        }
    }
    
    @objc func handler(gesture: UIPanGestureRecognizer){
        print(gesture.location(in: self.view))
        
        let location = gesture.location(in: self.view)
        let draggedView = gesture.view
        draggedView?.center = location
        
        if gesture.state == .ended {
            print("끝났을 때 이벤트")
            
            
            if self.decoTxtMoveBtn.frame.midX >= self.view.layer.frame.width / 2 {
                
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    
                    self.decoTxtMoveBtn.center.x = location.x
                    self.decoTxtMoveBtn.center.y = location.y
                    
                }, completion: { _ in
                    self.socket?.sendJson(method: "textOverlay", params: ["text": "sfd","positionX" : self.decoTxtMoveBtn.center.x/UIScreen.main.bounds.width, "positionY": self.decoTxtMoveBtn.center.y/UIScreen.main.bounds.height, "position": "static","color" : "moveText"])
                })
                
            }else{
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    
                    self.decoTxtMoveBtn.center.x = location.x
                    self.decoTxtMoveBtn.center.y = location.y
                    
                }, completion: {_ in
                    self.socket?.sendJson(method: "textOverlay", params: ["text": "sfd","positionX" : self.decoTxtMoveBtn.center.x/UIScreen.main.bounds.width, "positionY": self.decoTxtMoveBtn.center.y/UIScreen.main.bounds.height, "position": "static","color" : "moveText"])
                    
                })
            }
        }
    }
    
    
    @objc func setLocalMedia(noti: Notification){
        
        self.mediaSettingChangedId = noti.userInfo!["id"] as! String
        print("setLocalMedia 노티피케이션 받음\( self.mediaSettingChangedId)~~~~~~~~~~~~~~~")
        
        self.userCollectionView.reloadData()
        //self.createLocalVideoView()
    }
    
    @objc func getParticipantCount(noti: Notification){
        print("getParticipantCount 노티피케이션 받음~~~~~~~~~~~~~~~")
        guard let number = noti.userInfo!["count"] as? String else{
            return
        }
        
        if socket?.participants.count ?? 0 > 0{
            
            for i in self.socket!.participants{
                
                print("getParticipantCount에서 self.participantList: \(self.participantList)")
                
                if !self.participantList.contains(i.value.id!){
                    print("getParticipantCount에서 participant추가 후: \(self.participantList)")
                    
                    self.participantList.append(i.value.id!)
                }
            }
        }
        self.userCollectionView.reloadData()
        print("받은 숫자: \(number)")
    }
    
    @objc func saveAnswerNoti(noti: Notification){
        print("saveAnswerNoti 노티피케이션 받음~~~~~~~~~~~~~~~")
        
        //self.participantList.removeAll()
        
        if socket?.participants.count ?? 0 > 0{
            print("saveAnswerNoti에서 participant count 0보다 클 때")
            
            for i in self.socket!.participants{
                print("saveAnswerNoti에서 participant index로 꺼내온 것: \(i.value.id)")
                print("saveAnswerNoti에서 self.participantList: \(self.participantList)")
                
                if !self.participantList.contains(i.value.id!){
                    print("saveAnswerNoti에서 participant추가 후: \(self.participantList)")
                    
                    self.participantList.append(i.value.id!)
                }
            }
        }
        self.userCollectionView.reloadData()
    }
    
    
    func createSocket(token: String) {
        print("[createsocket] URL \(self.url)")
        self.socket = WebSocketListener(url: self.url, sessionName: self.sessionName, participantName: self.participantName, peersManager: self.peersManager!, token: token, views: remoteViews!, names: remoteNames!)
        self.peersManager!.webSocketListener = self.socket
        self.peersManager!.start()
    }
    
    func createLocalVideoView(renderer: RTCVideoRenderer, useBackCamera: Bool) {
        print("로컬 비디오 뷰 create")
        
        self.startCapureLocalVideo(renderer: renderer, useBackCamera: self.useBackCamera)
        
        self.embedView(renderer as! UIView, into: self.localVideoView)
        
    }
    
    
    func startCapureLocalVideo(renderer: RTCVideoRenderer, useBackCamera: Bool){
        //오디오, 비디오 트랙과 스트림 생성
        createMediaSenders()
        
        guard let stream = self.peersManager!.localPeer!.localStreams.first ,
              let capturer = self.videoCapturer as? RTCCameraVideoCapturer else {
            return
        }
        
        if useBackCamera == false{
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
            
            
            capturer.startCapture(with: frontCamera,
                                  format: format,
                                  fps: Int(fps.maxFrameRate))
                        
            stream.videoTracks.first?.add(renderer)
            
            
        }else{
            
            guard
                let backCamera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == .back }),
                
                // choose highest res
                let format = (RTCCameraVideoCapturer.supportedFormats(for: backCamera).sorted { (f1, f2) -> Bool in
                    let width1 = CMVideoFormatDescriptionGetDimensions(f1.formatDescription).width
                    let width2 = CMVideoFormatDescriptionGetDimensions(f2.formatDescription).width
                    return width1 < width2
                }).last,
                
                // choose highest fps
                let fps = (format.videoSupportedFrameRateRanges.sorted { return $0.maxFrameRate < $1.maxFrameRate }.last) else {
                return
            }
            
            capturer.startCapture(with: backCamera,
                                  format: format,
                                  fps: Int(fps.maxFrameRate))
            
            stream.videoTracks.first?.add(renderer)
        }
    }
    
    private func createMediaSenders() {
        let streamId = "stream"
        let stream = self.peersManager!.peerConnectionFactory!.mediaStream(withStreamId: streamId)
        
        // Audio
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = self.peersManager!.peerConnectionFactory!.audioSource(with: audioConstrains)
        let audioTrack = self.peersManager!.peerConnectionFactory!.audioTrack(with: audioSource, trackId: "audio0")
        
        //---------------------로컬 오디오 트랙에 데이터 집어넣기
        self.localAudioTrack = audioTrack
        
        self.peersManager!.localAudioTrack = audioTrack
        stream.addAudioTrack(audioTrack)
        
        // Video
        self.videoSource = self.peersManager!.peerConnectionFactory!.videoSource()
        
        //let videoSource = self.peersManager!.peerConnectionFactory!.videoSource()
        
        //self.videoCapturer = RTCCameraVideoCapturer(delegate:videoSource)
        self.videoCapturer = RTCCameraVideoCapturer(delegate: self)
        
        let videoTrack = self.peersManager!.peerConnectionFactory!.videoTrack(with: self.videoSource!, trackId: "video0")
        self.localVideoTrack = videoTrack
        
        //---------------------로컬 비디오 트랙에 데이터 집어넣기
        self.peersManager!.localVideoTrack = videoTrack
        stream.addVideoTrack(videoTrack)
        
        self.peersManager!.localPeer!.add(stream)
        self.peersManager!.localPeer!.delegate = self.peersManager!
    }
    
    func embedView(_ view: UIView, into containerView: UIView) {
        containerView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        let width = (UIScreen.main.bounds.width)
        let height = (UIScreen.main.bounds.height)
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[view(" + width.description + ")]",
                                                                    options: NSLayoutConstraint.FormatOptions(),
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[view(" + height.description + ")]",
                                                                    options:NSLayoutConstraint.FormatOptions(),
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        containerView.layoutIfNeeded()
    }
    
    var useBackCamera : Bool = false
    
    private func getCamera( _ position: AVCaptureDevice.Position) -> ( frontCamera: AVCaptureDevice?, format: AVCaptureDevice.Format?, fps: AVFrameRateRange?) {
        
        guard
            let frontCamera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == position }),
            // choose highest res
            let format = (RTCCameraVideoCapturer.supportedFormats(for: frontCamera).sorted { (f1, f2) -> Bool in
                let width1 = CMVideoFormatDescriptionGetDimensions(f1.formatDescription).width
                let width2 = CMVideoFormatDescriptionGetDimensions(f2.formatDescription).width
        
                return width1 < width2
            }).last,
            
            // choose highest fps
            let fps = (format.videoSupportedFrameRateRanges.sorted { return $0.maxFrameRate < $1.maxFrameRate }.last) else {
            return (nil, nil, nil)
        }
    
        return (frontCamera, format, fps)
    }
    
    private func switchCam(useBackCamera: Bool) -> Void{
        
        #if arch(arm64)
        let renderer = RTCMTLVideoView(frame: self.localVideoView.frame)
        #else
        let renderer = RTCEAGLVideoView(frame: self.localVideoView.frame)
        #endif
        
        let mode: AVCaptureDevice.Position = useBackCamera ? .back : .front
        
        let camera = getCamera(mode)
        guard let device = camera.frontCamera,
              let format = camera.format,
              let fps = camera.fps,
              let capturer = videoCapturer as? RTCCameraVideoCapturer else {
            return
        }
       
        capturer.startCapture(with: device,
                              format: format,
                              fps: Int(fps.maxFrameRate))
    }
    
}

//그림 이전으로 되돌리기에서 다른 사람들한테 되돌리려는 uiimage보내기 위해 string으로 변환
extension UIImage{
    
    func toPngString(image: UIImage) -> String? {
        let data = image.pngData()
        return data?.base64EncodedString(options: .endLineWithLineFeed)
    }
}

//다른 사람이 그림 되돌리기 했을 때 이벤트 받은 사람이 그에 따라서 string->uiimage변환해서 보여주기 위함.
extension String{
    func imageFromBase64(imgString : String) -> UIImage?{
        guard let data = Data(base64Encoded: imgString) else{return nil}
        return UIImage(data: data)
    }
}

@available(iOS 14.0, *)
extension VideosViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if collectionView == self.filterCollectionView || collectionView == self.stickerCollectionView{
            
            return CGSize(width: collectionView.frame.width/3, height: collectionView.frame.width/3)
            
        }else if collectionView == self.drawingColorListView{
            return CGSize(width: collectionView.frame.width/5, height: collectionView.frame.width/5)
        }
        else{
            return CGSize(width: collectionView.frame.width/3, height: collectionView.frame.height)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == self.userCollectionView{
            print("유저 컬렉션뷰일 때 셀 갯수")
            return participantList.count
            
        }else if collectionView == self.stickerCollectionView{
            print("스티커 컬렉션뷰일 때 셀 갯수: \(stickerData.count)")
            return stickerData.count
        }else if collectionView == self.drawingColorListView{
            return colorData.count
        }
        else{
            print("필터 컬렉션뷰일 때 셀 갯수")
            
            return filterData.count
        }
    }

    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == self.userCollectionView{
            print("유저 컬렉션뷰일 때 cell for item at")
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath) as? ItemCell else {
                return UICollectionViewCell()
            }
            if #available(iOS 11.0, *) {
                cell.layer.borderColor = UIColor.init(named: "Kirae")?.cgColor
            } else {
                // Fallback on earlier versions
            }
            cell.layer.borderWidth = 5
            cell.layer.cornerRadius = 15
            cell.addSubview(cell.videoOffImg)
            cell.addSubview(cell.micOffImg)
            cell.micOffImg.isHidden = true
            cell.videoOffImg.isHidden = true
            
            let participantVideo = peersManager?.remoteStreams[indexPath.row]
            DispatchQueue.main.async {
                #if arch(arm64)
                // Using metal (arm64 only)
                let remoteRenderer = RTCMTLVideoView(frame:  CGRect.init(x: 0, y: 0, width: collectionView.frame.width/3, height: collectionView.frame.height))
                remoteRenderer.contentMode = .scaleAspectFit
                
                #else
                // Using OpenGLES for the rest
                let remoteRenderer = RTCEAGLVideoView(frame:  CGRect.init(x: 0, y: 0, width: collectionView.frame.width/3, height: collectionView.frame.height))
                #endif
                
                print("---------------비디오 추가함------------------: \(String(describing: self.socket?.participants.count))--")
                
                participantVideo?.videoTracks.last?.add(remoteRenderer)
                //cell.contentView.addSubview(remoteRenderer)
                cell.VideoView.addSubview(remoteRenderer)
                cell.userId = self.participantList[indexPath.row]
                
                //비디오, 오디오 뷰 세팅
                if self.socket?.participants["\(self.mediaSettingChangedId!)"]?.videoOff == true{
                    print("비디오 오프함 : \(cell.userId)")
                    if cell.userId == self.mediaSettingChangedId{
                    cell.videoOffImg.isHidden = true
                    }
                    
                }else if self.socket?.participants["\(self.mediaSettingChangedId!)"]?.videoOff == false{
                    if cell.userId == self.mediaSettingChangedId{
                    cell.videoOffImg.isHidden = false
                    }
                }
                
                if self.socket?.participants["\(self.mediaSettingChangedId!)"]?.micOff == true{
                    print("마이크 오프함")
                    if cell.userId == self.mediaSettingChangedId{
                    cell.micOffImg.isHidden = true
                    }
                    
                }else if self.socket?.participants["\(self.mediaSettingChangedId!)"]?.micOff == false{
                    if cell.userId == self.mediaSettingChangedId{
                    cell.micOffImg.isHidden = false
                    }
                }
            }
            return cell
            
        }else if collectionView == self.stickerCollectionView{
            print("스티커 컬렉션뷰일 때")
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StickerCell", for: indexPath) as? StickerCell else {
                return UICollectionViewCell()
            }
            
            cell.stickerImgView.image = stickerData[indexPath.row].stickerImg
            //cell.backgroundColor = .red
            return cell
            
        }
        else if collectionView == self.drawingColorListView{
            print("색깔 컬렉션뷰일 때")
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorCollectionViewCell", for: indexPath) as? ColorCollectionViewCell
            else{
                return UICollectionViewCell()
            }
            
            cell.colorView.tintColor = colorData[indexPath.row].colorView
            
            return cell
        }
        else{
            print("필터 컬렉션뷰일 때 cell for item at")
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath) as? FilterCell else {
                return UICollectionViewCell()
            }
            
            cell.filterImage.image = filterData[indexPath.row].filterImage
            cell.filterImage.contentMode = .scaleAspectFit
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("didSelectItemAt 아이템 클릭")
        
        if collectionView == self.stickerCollectionView{
            
            self.selectedImg = stickerData[indexPath.row].title!
            
        }else if collectionView == self.drawingColorListView{
            DispatchQueue.main.async {
                print("컬러 리스트뷰에서 색깔 선택함")
                //선택한 색깔 저장
                self.brushColor = self.colorData[indexPath.row].colorView!.cgColor
                print("색깔 선택: \(self.colorData[indexPath.row].colorName!)")
            }
        }else{
            //if collectionView == self.filterCollectionView{
                print("필터 컬렉션뷰에서 필터 한 개 클릭")
                let selectedImg = filterData[indexPath.row].title
                
                if selectedImg == "원본"{
                    
                    var filterParams : [String:String] = [:]
                    filterParams["removeTarget"] = "faceOverlay"
                    self.socket?.sendJson(method: "removeFilter", params: filterParams)
                    
                }else {
                    
                    var filterParams : [String:String] = [:]
                    filterParams["imagePath"] = selectedImg
                    self.socket?.sendJson(method: "faceOverlay", params: filterParams)
                }
        }
    }
}



extension VideosViewController{
    
    func sendUserFace(){
   
        let findFaceInfoQueue = DispatchQueue(label: "info", attributes: .concurrent)
        let foundInfoTaskGroup = DispatchGroup()
        
        let headers = [
            "X-Naver-Client-Id" : "E92UUnxyDfNF4WOfEM1e", "X-Naver-Client-Secret" : "K0dMXm_VPB"
        ]
        
        foundInfoTaskGroup.enter()
        
        findFaceInfoQueue.async(group: foundInfoTaskGroup){
            
        Alamofire.upload(multipartFormData: {data in
            data.append(self.userFaceImgData!, withName: "image")
      
        }, to: "https://openapi.naver.com/v1/vision/celebrity", method: .post, headers: headers){result in
        
            switch result{
            case .success(let upload, _, _):
                print("데이터 받음")
                upload.responseJSON(completionHandler: {response in
                    let text = response.value!
                    let data = JSON(text).dictionaryValue
                    print("텍스트 제이슨으로\(data)")
                    
                    let faces = data["faces"]!.arrayValue
                    let face = faces[0]
                    let celebrity = face["celebrity"]
                    let confidence = celebrity["confidence"].doubleValue
                    let name = celebrity["value"].stringValue
                    print("얼굴 한개 name: \(name)")
                    
                    self.faceModelData.name = name
                    self.faceModelData.percent = Int(100*confidence)
                    print("얼굴 데이터 저장한 것 확인: \(self.faceModelData)")
                    foundInfoTaskGroup.leave()
                })
            case .failure(let error):
                print("에러: \(error)")
            }
        }
        }
        
        foundInfoTaskGroup.enter()
        findFaceInfoQueue.async(group: foundInfoTaskGroup){
        Alamofire.upload(multipartFormData: {data in
            data.append(self.userFaceImgData!, withName: "image")
        }, to: "https://openapi.naver.com/v1/vision/face", method: .post, headers: headers){result in
        
            switch result{
            case .success(let upload, _, _):
                print("데이터 받음")
                upload.responseJSON(completionHandler: {response in
                    let text = response.value!
                    let data = JSON(text).dictionaryValue
                    print("텍스트 제이슨으로\(data)")
                    let faces = data["faces"]?.arrayValue
                    let face = faces![0].dictionaryValue
                    
                    //얼굴 인식 위해 보낸 사용자 이미지 크기
                    let info = data["info"]?.dictionaryValue
                    let imgSize = info!["size"]?.dictionaryValue
                    let imgWidth = imgSize!["width"]?.intValue
                    let imgHeight = imgSize!["height"]?.intValue
                    
                    //얼굴 영역 사각형 그리기 위한 정보
                    let roiInfo = face["roi"]?.dictionaryValue
                    let roiX = roiInfo!["x"]?.intValue
                    let roiY = roiInfo!["y"]?.intValue
                    let roiWidth = roiInfo!["width"]?.intValue
                    let roiHeight = roiInfo!["height"]?.intValue
                    
                    let userImg = UIImage(data:self.userFaceImgData!)
                    let size = userImg?.size
                    let scale: CGFloat = 0.0
                    
                    UIGraphicsBeginImageContextWithOptions(size!, false, scale)

                    userImg?.draw(at: CGPoint.zero)
                    
                    let ctx = UIGraphicsGetCurrentContext()

                    ctx?.addRect(CGRect(x: roiX!, y: roiY!, width: roiWidth!, height: roiHeight!))
                      ctx?.setStrokeColor(UIColor.systemGreen.cgColor)
                      ctx?.setLineWidth(10.0)
                      ctx?.strokePath()

                       let drawnImage = UIGraphicsGetImageFromCurrentImageContext()
                      UIGraphicsEndImageContext()
                    
                    self.faceModelData.userImg = drawnImage
                    
                   let genderInfo = face["gender"]?.dictionaryValue
                   let genderValue = genderInfo!["value"]?.stringValue
                   
                   let ageInfo = face["age"]?.dictionaryValue
                   let ageValue = ageInfo!["value"]?.stringValue
                   
                   let emotionInfo = face["emotion"]?.dictionaryValue
                    let emotionValue = emotionInfo!["value"]?.stringValue

                   self.faceModelData.age = ageValue!
                   self.faceModelData.emotion = emotionValue!
                   self.faceModelData.gender = genderValue!
                    print("얼굴 데이터 저장한 것 확인: \(self.faceModelData)")

                    foundInfoTaskGroup.leave()

                })
            case .failure(let error):
                print("에러: \(error)")
            }
        }
        }
        
        foundInfoTaskGroup.notify(queue: findFaceInfoQueue){
            
            self.findCelebPhoto(name: self.faceModelData.name, confidence: self.faceModelData.percent/100)
        }
    }
    
    func findCelebPhoto(name: String, confidence: Int){
        print("이미지 찾기 메소드 안")
        let headers = [
            "Content-Type" : "application/json; charset=utf-8", "X-Naver-Client-Id" : "P9cJ0ibLuSIPNotez2lL", "X-Naver-Client-Secret" : "_v3VSre6Xt"
        ]
        
        let queryName = name
        print("인코딩한 이름: \(queryName)")
        let parameter = ["query" : "\(name)", "sort" : "sim"] as [String : Any]
        let queryString = "https://openapi.naver.com/v1/search/image?query="+queryName
        let encodedQuery : String = queryString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
        
        Alamofire.request(encodedQuery, method: .get, encoding: URLEncoding.default, headers: headers)
            .responseJSON(completionHandler: {response in
                print("이미지 찾기 리스펀스 확인: \(response)")
                let result = response.value!
                let data = JSON(result).dictionaryValue
                print("제이슨 이미지 결과 확인: \(data)")
                let percent = 100*confidence
                let items = data["items"]?.arrayValue
                let img = items![0]["thumbnail"].stringValue
                
                self.faceModelData.img = img
                
                let notiData = self.faceModelData
                NotificationCenter.default.post(name: NSNotification.Name("foundMatch"), object: nil, userInfo: ["data" : notiData])
            })
    }
    
    func processPoints(fingerTips: [CGPoint]) {
         var pointsPath = UIBezierPath()
         var overlayLayer = CAShapeLayer()

        for point in fingerTips{
            pointsPath.move(to: point)
            pointsPath.addArc(withCenter: point, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        }
        overlayLayer.fillColor = UIColor.green.cgColor
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        overlayLayer.path = pointsPath.cgPath
        CATransaction.commit()
        
        
    }
}

@available(iOS 14.0, *)
extension VideosViewController : RTCVideoCapturerDelegate{
    
    public func capturer(_ capturer: RTCVideoCapturer, didCapture frame: RTCVideoFrame) {
                self.videoSource?.capturer(capturer, didCapture: frame)
               
        if self.gameState == "start"{
            if self.handDetectCount % 20 == 0{

                startHandDetection(didCapture: frame)
            }
            self.handDetectCount += 1
            }
        
//        if startCaptureFace == "start"{
//            print("유명인 얼굴 찾기 capture")
//            captureUserFace(didCapture: frame)
//            }
        }
    
    func captureUserFace(didCapture frame: RTCVideoFrame){
        let sampleBuffer = frame.buffer as! RTCCVPixelBuffer
        let pixelBuffer = sampleBuffer.pixelBuffer
        let ciImg = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        let cgImg = context.createCGImage(ciImg, from: ciImg.extent)
        let uiImg = UIImage(cgImage: cgImg!)
        let resizedImg = uiImg.resize(newWidth: 370)
        
        let rotatedImg = resizedImg.rotate(radians: .pi/2)
        let data = rotatedImg!.pngData()
       
        self.userFaceImgData = data
        //분석 결과 보여주는 페이지에서 캡쳐한 유저 사진 보여주기 위해 저장.(단순히 뷰에 전달)
        //self.faceModelData.userImg = data
        //print("유명인 얼굴 찾기 메소드 안 들어옴:\(data)")
             
        sendUserFace()
        startCaptureFace = ""
    }
    

    
    
        func startHandDetection(didCapture frame: RTCVideoFrame)  {
            
                    print("프레임 캡쳐\(self.handDetectCount)")
                    var fingerTips: [CGPoint] = []
                    let sampleBuffer = frame.buffer as! RTCCVPixelBuffer
                    let pixelBuffer = sampleBuffer.pixelBuffer
            
//            defer {
//                DispatchQueue.main.sync {
//                    self.processPoints(fingerTips: fingerTips)
//                }
//            }
            
                    let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
                    do {
                      // Perform VNDetectHumanHandPoseRequest
                      try handler.perform([handPoseRequest])

                      // Continue only when at least a hand was detected in the frame. We're interested in maximum of two hands.
                      guard
                        let results = handPoseRequest.results?.prefix(2),
                        !results.isEmpty
                      else {
                        return
                      }
                    print("결과: \(results)")
                        
                      var recognizedPoints: [VNRecognizedPoint] = []

                      try results.forEach { observation in
                        // Get points for all fingers.
                        let fingers = try observation.recognizedPoints(.all)

                        // Look for tip points.
                        if let thumbTipPoint = fingers[.thumbTip] {
                          recognizedPoints.append(thumbTipPoint)
                        }
                        if let indexTipPoint = fingers[.indexTip] {
                          recognizedPoints.append(indexTipPoint)
                        }
                        if let middleTipPoint = fingers[.middleTip] {
                          recognizedPoints.append(middleTipPoint)
                        }
                        if let ringTipPoint = fingers[.ringTip] {
                          recognizedPoints.append(ringTipPoint)
                        }
                        if let littleTipPoint = fingers[.littleTip] {
                          recognizedPoints.append(littleTipPoint)
                        }
                        print("손가락 갯수 확인: \(fingers)")

                      }

                      fingerTips = recognizedPoints.filter {
                        // Ignore low confidence points.
                        $0.confidence > 0.9
                      }
                      .map {
                        // Convert points from Vision coordinates to AVFoundation coordinates.
                        CGPoint(x: $0.location.x, y: 1 - $0.location.y)
                      }
                        print("핑거팁스 확인: \(fingerTips)")
                        if fingerTips.count == 5{
                            print("------------------손가락 5개--------------------")
                            socket?.sendJson(method: "catchMind", params: ["behavior" : "submitterPermission"])
                        }
                        
                        DispatchQueue.main.async {
                            self.processPoints(fingerTips: fingerTips)
                        }
                        
                    } catch {
                      print(error.localizedDescription)
                    }
                }
}

extension UIImage {
    func resize(newWidth: CGFloat) -> UIImage {
    let scale = newWidth / self.size.width
    let newHeight = self.size.height * scale
    let size = CGSize(width: newWidth, height: newHeight)
    let render = UIGraphicsImageRenderer(size: size)
    let renderImage = render.image { context in
        
        self.draw(in: CGRect(origin: .zero, size: size))
        
    }
    print("화면 배율: \(UIScreen.main.scale)")// 배수
    print("origin: \(self), resize: \(renderImage)")

    return renderImage
}
    
    func rotate(radians: Float) -> UIImage? {
            var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
            // Trim off the extremely small float value to prevent core graphics from rounding it up
            newSize.width = floor(newSize.width)
            newSize.height = floor(newSize.height)

            UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
            let context = UIGraphicsGetCurrentContext()!

            // Move origin to middle
            context.translateBy(x: newSize.width/2, y: newSize.height/2)
            // Rotate around middle
            context.rotate(by: CGFloat(radians))
            // Draw the image at its center
            self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return newImage
        }
}

