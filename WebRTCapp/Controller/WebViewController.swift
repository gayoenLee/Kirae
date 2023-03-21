//
//  WebViewController.swift
//  WebRTCapp
//
//  Created by 이은호 on 2021/09/13.
//  Copyright © 2021 Sergio Paniego Blanco. All rights reserved.
//

import UIKit
import WebKit
import Alamofire
import YoutubePlayer_in_WKWebView
import youtube_ios_player_helper_swift

class WebViewController: UIViewController {
    
    var socket : WebSocketListener?

    private var playerView: PlayerView!
    var videoKey : String = ""
     override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        return .portrait
     }
     
     override var shouldAutorotate: Bool{
         return false
     }
     
     override func viewDidLoad() {
         super.viewDidLoad()
         
        DispatchQueue.main.async {
            self.playerView = UINib(nibName: "PlayerView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? PlayerView
            self.playerView.frame =   CGRect(x:  0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height*0.4)
            self.playerView.backgroundColor = .clear
            self.playerView.videoId = self.videoKey
            self.playerView.socket = self.socket
            self.view.addSubview(self.playerView)

            self.playerView.ytPlayerView.backgroundColor = .clear
        }
         
     }
     
     override func viewDidAppear(_ animated: Bool) {
         super.viewDidAppear(animated)
         //addPlayerView()
        NotificationCenter.default.addObserver(self, selector: #selector(closeYoutube), name: Notification.Name("closeYoutube"), object: nil)
     }
    
    @objc func closeYoutube(){
        print("동영상 클로즈 노티 받음")
        self.dismiss(animated: true)

    }
    
     private func addPlayerView(){
         self.view.addSubview(playerView)
         playerView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 240)
         playerView.autoresizingMask = .flexibleWidth
     }
     
}

//class WebViewController: UIViewController, WKUIDelegate {
//
//    var videoKey : String = ""
//    var webView: WKWebView!
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        print("웹뷰 컨트롤러 들어옴")
//        self.webView = WKWebView()
//        self.webView = WKWebView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height*0.4))
//        self.webView.uiDelegate = self
//        self.view.addSubview(self.webView)
//
//        let url = URL(string: "https://www.youtube.com/embed/\(videoKey)")
//        let request : URLRequest = URLRequest(url: url!)
//        self.webView.load(request)
//    }
//}

