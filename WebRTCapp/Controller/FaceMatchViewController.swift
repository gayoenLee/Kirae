//
//  FaceMatchViewController.swift
//  WebRTCapp
//
//  Created by 이은호 on 2021/09/27.
//  Copyright © 2021 Sergio Paniego Blanco. All rights reserved.
//

import UIKit

struct FaceInfo{
    var name : String
    var percent : Int
    var img : String
    var emotion: String
    var age: String
    var gender: String
    var userImg : UIImage?
    
}

class FaceMatchViewController: UIViewController {

    
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var modalTitleLabel: UILabel!
    @IBOutlet weak var celebImgView: UIImageView!
    
    @IBOutlet weak var userImg: UIImageView!
    @IBOutlet weak var nameAndPercent: UILabel!
    
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var emotionLabel: UILabel!
    @IBOutlet weak var genderLabel: UILabel!
    
    @IBAction func closeModal(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var infoStackView: UIStackView!
    @IBOutlet weak var shareBtn: UIButton!
    
    var socket :WebSocketListener?
    //닮은 꼴을 찾으려는 사람인지(owner), 결과를 보는 사람인지(상대방 이름)
    var type : String?
    
    var faceInfo = FaceInfo(name: "", percent: 0, img: "", emotion: "", age: "", gender: "")
    
    lazy var activityIndicator: UIActivityIndicatorView = {
            // Create an indicator.
            let activityIndicator = UIActivityIndicatorView()
            activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            activityIndicator.center = self.view.center
            activityIndicator.color = UIColor.red
            // Also show the indicator even when the animation is stopped.
            activityIndicator.hidesWhenStopped = true
            activityIndicator.style = UIActivityIndicatorView.Style.white
            // Start animation.
            activityIndicator.stopAnimating()
            return activityIndicator }()

        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.layer.cornerRadius = 15
        self.view.layer.shadowColor = UIColor.gray.cgColor
        self.view.layer.shadowOpacity = 1.0
        self.view.layer.shadowOffset = CGSize.zero
        self.view.layer.shadowRadius = 6
        
        if type == "owner"{
        self.view.addSubview(self.activityIndicator)
        activityIndicator.startAnimating()
        }else{
            
            self.modalTitleLabel.text = type!+"님 닮은꼴은"
            self.nameAndPercent.isHidden = false
            self.infoStackView.isHidden = false
            
            self.nameAndPercent.text = self.faceInfo.name
            
            self.celebImgView.isHidden = false
            self.userImg.isHidden = false

            let url = URL(string: faceInfo.img)
            DispatchQueue.global().async {
                let imgData =  try! Data(contentsOf: url!)
                
                DispatchQueue.main.async {
                    self.celebImgView.image = UIImage(data: imgData)?.resize(newWidth: 100)
                   // self.celebImgView.center = self.view.center
                    self.celebImgView.clipsToBounds = true
                    self.celebImgView.contentMode = .scaleAspectFit
                    
                    self.userImg.image = self.faceInfo.userImg!.resize(newWidth: 100)
                    self.userImg.clipsToBounds = true
                    self.userImg.contentMode = .scaleAspectFit
                                       
                }
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(foundMatch(noti:)), name: Notification.Name("foundMatch"), object: nil)
    }

    
    @IBAction func shareResult(_ sender: Any) {
        
        let resizedImg = self.faceInfo.userImg!.resize(newWidth: 370)
        let imgData = resizedImg.toPngString(image: resizedImg)
        
        print("공유하기 클릭")

        socket?.sendJson(method: "imageShare", params: ["imageLink" : faceInfo.img, "name": faceInfo.name, "userImage": imgData])
        
        self.shareBtn.backgroundColor = UIColor.systemGreen
        self.shareBtn.titleLabel?.text = "공유 완료"

    }
    
    @objc func foundMatch(noti: Notification){
        print("foundMatch 노티피케이션 받음~~~~~~~~~~~~~~~")
        let data = noti.userInfo!["data"] as! FaceInfo
        self.faceInfo = data
        
        print("데이터 확인: \(data)")
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        self.userImg.isHidden = false
        self.celebImgView.isHidden = false
        self.infoStackView.isHidden = false
        self.ageLabel.isHidden = false
        self.emotionLabel.isHidden = false
        self.genderLabel.isHidden = false
        self.shareBtn.isHidden = false
        
         shareBtn.layer.cornerRadius = 15
        shareBtn.titleLabel?.minimumScaleFactor = 0.5
        shareBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        shareBtn.titleEdgeInsets = UIEdgeInsets(top: 8, left: 15, bottom: 8, right: 15)
  
        let url = URL(string: data.img)
        DispatchQueue.global().async {
            let imgData =  try! Data(contentsOf: url!)
            
            DispatchQueue.main.async {
                self.celebImgView.image = UIImage(data: imgData)?.resize(newWidth: 100)
               // self.celebImgView.center = self.view.center
                self.celebImgView.clipsToBounds = true
                self.celebImgView.contentMode = .scaleAspectFit
                
                self.userImg.image = self.faceInfo.userImg!.resize(newWidth: 100)
                self.userImg.clipsToBounds = true
                self.userImg.contentMode = .scaleAspectFit
                
            }
        }
        
        self.nameAndPercent.text = data.name+" "+String(data.percent)+"%"
        self.ageLabel.text = data.age+"세"
       
        switch data.emotion{
        case "angry":
            self.emotionLabel.text = "감정 : 화남"

        case "disgust":
            self.emotionLabel.text = "감정 : 짜증남"

        case "fear":
            self.emotionLabel.text = "감정 : 두려움"

        case "laugh":
            self.emotionLabel.text = "감정 : 웃김"

        case "neutral":
            self.emotionLabel.text = "감정 : 보통"

        case "sad" :
            self.emotionLabel.text = "감정 : 슬픔"

        case "surprise":
            self.emotionLabel.text = "감정 : 놀람"

        case "smile":
            self.emotionLabel.text = "감정 : 웃음"

        case "talking":
            print("얘기중")
            self.emotionLabel.text = "감정 : 얘기중"
        default:
            print("아무런 상태도 아님")
        }
        
        if data.gender == "male"{
            self.genderLabel.text = "성별 : 남성"
        }else{
            self.genderLabel.text = "성별 : 여성"
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
