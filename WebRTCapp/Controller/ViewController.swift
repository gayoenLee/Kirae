//
//  ViewController.swift
//  WebRTCapp
//
//  Created by Sergio Paniego Blanco on 12/03/2018.
//  Copyright © 2018 Sergio Paniego Blanco. All rights reserved.
//

import UIKit
import AVFoundation
import WebRTC

class ViewController: UIViewController {

    @IBOutlet weak var sessionName: UITextField!
    @IBOutlet weak var participantName: UITextField!
    
    @IBOutlet weak var startBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Recognise gesture to hide keyboard
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:))))
        view.addSubview(startBtn)
        NSLayoutConstraint.activate([
            
            self.startBtn.widthAnchor.constraint(equalToConstant: 160),
                      self.startBtn.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        startBtn.layer.shadowColor = UIColor.gray.cgColor
        startBtn.layer.shadowOpacity = 1.0
        startBtn.layer.shadowOffset = CGSize.zero
        startBtn.layer.shadowRadius = 6
        startBtn.layer.cornerRadius = 5
        startBtn.setTitle("시작하기", for: .normal)
        startBtn.titleLabel?.font = UIFont(name: "NanumSquareB", size: 15)
        //Camera
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                print("Camera permission granted!")
            } else {
                
            }
        }
        print("Did Load")
        
        sessionName.attributedPlaceholder = NSAttributedString(string: "방 이름", attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray])
        participantName.attributedPlaceholder = NSAttributedString(string: "닉네임", attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray])
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("View will Appear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("Did Appear")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if #available(iOS 14.0, *) {
            if segue.destination is VideosViewController
            {
                let vc = segue.destination as? VideosViewController
                
                vc?.sessionName = sessionName.text!
                vc?.participantName = participantName.text!
                vc?.modalPresentationStyle = .fullScreen
                
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    @IBAction func startSocket(_ sender: UIButton){
       
        if #available(iOS 14.0, *) {
            guard let vc = storyboard?.instantiateViewController(identifier: "cameraView") as? VideosViewController else {
                return
            }
        
        //화면 전환
        navigationController?.pushViewController(vc, animated: true)
        } else {
            // Fallback on earlier versions
        }
    }
//    @IBAction func startSocket(_ sender: UIButton) {
//        print("Start new View!")
//    }
}

extension UITextField {
    func setPlaceholder(color: UIColor) {
        guard let string = self.placeholder else {
            return
        }
        attributedPlaceholder = NSAttributedString(string: string, attributes: [.foregroundColor: color])
    }
}

