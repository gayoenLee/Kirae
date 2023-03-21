//
//  PlayerView.swift
//  WebRTCapp
//
//  Created by 이은호 on 2021/09/13.
//  Copyright © 2021 Sergio Paniego Blanco. All rights reserved.
//

import UIKit
import youtube_ios_player_helper_swift

class PlayerView: UIView{
    var socket : WebSocketListener?
    var videoId: String = ""{
        didSet{
            if !videoId.isEmpty{
                loadVideo()
            }
        }
    }
    
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var ytPlayerView: YTPlayerView!
    @IBOutlet weak var btnPlayPause: UIButton!
    @IBOutlet weak var btnFullScreen: UIButton!
    
    @IBAction func closeYoutube(_ sender: Any) {
        print("닫기 클릭")
        self.ytPlayerView.stopVideo()
    }
    
    @IBOutlet weak var timeSlider: UISlider!{
        didSet{
            self.timeSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
            self.timeSlider.addTarget(self, action: #selector(startEditingSlider), for: .touchDown)
            self.timeSlider.addTarget(self, action: #selector(stopEditingSlider), for: [.touchUpInside, .touchUpOutside])
            self.timeSlider.value = 0.0
        }
    }
    
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    @IBOutlet weak var controlsView: UIView!
    
    private var isFullScreen = false
    
    private func loadVideo(){
        let playerVars:[String: Any] = [
            //동영상 플레이어 컨트롤 표시 여부 0=안하는 것
            "controls" : "0",
            "showinfo" : "0",
            //자동재생 여부 0=자동재생
            "autoplay": "0",
            //youtube로고 표시 안하는 것 = 1
            "modestbranding": "0",
            //동영상 특수효과 설정 여부 3=안함
            "iv_load_policy" : "3",
            //fs: 전체화면 표시 안하는 것-0
            "fs": "0",
            "playsinline" : "1"
        ]
        ytPlayerView.delegate = self
        _ = ytPlayerView.load(videoId: videoId, playerVars: playerVars)
        ytPlayerView.isUserInteractionEnabled = false
        
        updateTime()
    }
        
    @IBAction func toogleFullScreen(sender: UIButton){
        guard let rootVC = UIApplication.shared.delegate?.window??.rootViewController else {
            return
        }
        isFullScreen = !isFullScreen
        if isFullScreen{
            let landscape = LandscapeViewController()
            landscape.view = self
            
            rootVC.present(landscape, animated: false, completion: nil)
        }else{
            rootVC.presentedViewController?.dismiss(animated: false, completion: nil)
        }
    }
    
    @IBAction func playStop(sender: UIButton){
        if ytPlayerView.playerState == .playing{
            print("비디오 멈춤 playStop:\(ytPlayerView.currentTime)")
            
            socket?.sendJson(method: "youtube", params: ["behavior" : "pause"])
            sender.setImage(#imageLiteral(resourceName: "play"), for: .normal)
            ytPlayerView.pauseVideo()

        }else{
            print("비디오 재생  playStop")
            let duration = Float(ytPlayerView.duration)
            let seconds = self.timeSlider.value * duration
            socket?.sendJson(method: "youtube", params: ["behavior" : "play", "duration" : duration, "seconds" : seconds])
            //비디오 재생 이벤트 보내야함*******************************
            ytPlayerView.playVideo()
//
//            ytPlayerView.seek(seekToSeconds: Float(seconds), allowSeekAhead: true)
            sender.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        }
    }
    
    func secondsToHoursMinutesSeconds (_ seconds : Int) -> (hours : Int, minutes : Int, seconds : Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    func paddedNumber(_ number : Int) -> String{
        print("paddedNumber")

        if(number < 0){
            return "00"
        }else if(number < 10){
            return "0\(number)"
        }else{
            return String(number)
        }
    }
    
    func ytk_secondsToCounter(_ seconds : Int) -> String {
        
        let time = self.secondsToHoursMinutesSeconds(seconds)
        
        let minutesSeconds = "\(self.paddedNumber(time.minutes)):\(self.paddedNumber(time.seconds))"
        
        if(time.hours == 0){
            return minutesSeconds
        }else{
            return "\(self.paddedNumber(time.hours)):\(minutesSeconds)"
        }
        
    }
    
    @objc func sliderValueChanged(){

        let duration = ytPlayerView.duration
        
        let currentTime = Int(Double(self.timeSlider.value) * duration)
        self.currentTimeLabel.text = self.ytk_secondsToCounter(currentTime)
       // print("-----슬라이더 값 변함 !!!!sliderValueChanged: \(currentTime)")

        let timeLeft = Int(duration) - currentTime
        self.remainingTimeLabel.text = "-\(self.ytk_secondsToCounter(timeLeft))"
    }
   
    //***********************값을 변화주는 사람은 여기에서 상대방에게 변화시킨 시간 보내야함
    @objc func stopEditingSlider(){
        let duration = Float(ytPlayerView.duration)
        print("-----stopEditingSlider 슬라이더 멈춤: \(timeSlider.value)")
        print("-----stopEditingSlider 슬라이더 멈춤: \(duration)")
        let seconds = self.timeSlider.value * duration
        
        self.ytPlayerView.playVideo()
        //        self.playerView.seekTo(seconds: seconds, seekAhead: true)
        print("-----stopEditingSlider 슬라이더 멈춤: \(seconds)")
   
        socket?.sendJson(method: "youtube", params: ["behavior" : "editedSlider", "duration" : duration, "seconds" : seconds])
        btnPlayPause.setImage(#imageLiteral(resourceName: "pause"), for: .normal)

        self.ytPlayerView.seek(seekToSeconds: seconds, allowSeekAhead: true)
    }
    
    @objc func startEditingSlider(){
        print("슬라이더 값 변화주기 시작")
        self.ytPlayerView.pauseVideo()
    }
    
    @objc func updateTime(){
        
         let currentTime = ytPlayerView.currentTime
        let duration = Float( ytPlayerView.duration )
        
        let progress = currentTime / duration
        self.timeSlider.value = progress
        self.timeSlider.sendActions(for: .valueChanged)
        
        self.perform(#selector(updateTime), with: nil, afterDelay: 1.0)
    }
    
    //상대방이 영상 재생
    @objc func playVideoNoti(noti: Notification){
        let behavior = noti.userInfo!["behavior"] as! String

        if behavior == "play"{
        print("상대방이 play했다는 노티 들어옴")
            let duration = noti.userInfo?["duration"] as! Float
            let second = noti.userInfo?["seconds"]
            if second != nil{
                let seconds = self.timeSlider.value * duration
                self.ytPlayerView.seek(seekToSeconds: seconds, allowSeekAhead: true)
                btnPlayPause.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
            }else{
                ytPlayerView.playVideo()
                btnPlayPause.setImage(#imageLiteral(resourceName: "pause"), for: .normal)

            }
        }
    }
    
    //상대방이 영상 멈춤
    @objc func pauseVideoNoti(noti: Notification){
        let behavior = noti.userInfo!["behavior"] as! String

        if behavior == "pause"{
            
            print("상대방이 pause했다는 노티 들어옴")
                ytPlayerView.pauseVideo()
            btnPlayPause.setImage(#imageLiteral(resourceName: "play"), for: .normal)

        }
    }
    
    @objc func editedSliderNoti(noti: Notification){
        let behavior = noti.userInfo!["behavior"] as! String

        if behavior == "editedSlider"{
        print("상대방이 editedSlider했다는 노티 들어옴")
            let duration = noti.userInfo?["duration"] as! Float
           
                let seconds = self.timeSlider.value * duration
            print("내가 계산한 seconds: \(seconds)")
            
            let notiSec = noti.userInfo?["seconds"] as! Float
            print("노티에서 받은 Seconds: \(notiSec)")
            
                self.ytPlayerView.seek(seekToSeconds: notiSec, allowSeekAhead: true)
            self.ytPlayerView.playVideo()
            btnPlayPause.setImage(#imageLiteral(resourceName: "pause"), for: .normal)

        }
    }
    
    @objc func closeVideoNoti(noti: Notification){
        let behavior = noti.userInfo!["behavior"] as! String

        if behavior == "close"{
            print("상대방이 유튜브 닫은 이벤트 받음")
            NotificationCenter.default.post(name: NSNotification.Name("closeYoutube"), object: nil, userInfo: nil)
        }
    }
}

class LandscapeViewController: UIViewController {
    
    override var shouldAutorotate: Bool{
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        return .portrait
    }
}

extension PlayerView: YTPlayerViewDelegate{
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
       print("플레이어 준비됨")
        
        NotificationCenter.default.addObserver(self, selector: #selector(playVideoNoti), name: Notification.Name("youtube"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(editedSliderNoti), name: Notification.Name("youtube"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(pauseVideoNoti), name: Notification.Name("youtube"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(closeVideoNoti), name: Notification.Name("youtube"), object: nil)
                
        playerView.pauseVideo()
        btnPlayPause.setImage(#imageLiteral(resourceName: "play"), for: .normal)
    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo quality: YTPlaybackQuality) {
        print("Quality :: ", quality)
        
    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        print("플레이어뷰 didchange: \(state)")
        switch state{
        case YTPlayerState.ended:
            print("플레이어뷰 state ended")
        break
        case .queued:
            print("플레이어뷰 state queued")
            socket?.sendJson(method: "youtube", params: ["behavior" : "close"])
            NotificationCenter.default.post(name: NSNotification.Name("closeYoutube"), object: nil, userInfo: nil)
            
        break
         default:
            print("")
        }
    }
    
    
}
