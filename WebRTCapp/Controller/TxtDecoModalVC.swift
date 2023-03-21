//
//  txtDecoModalVC.swift
//  WebRTCapp
//
//  Created by 이은호 on 2021/08/30.
//  Copyright © 2021 Sergio Paniego Blanco. All rights reserved.
//

import UIKit
import MaterialComponents
import WebRTC

@available(iOS 14.0, *)
class TxtDecoModalVC: UIViewController {
    
    var socket: WebSocketListener?
    var showVoiceMenu: Bool?
    
    @IBAction func voiceConfirmAction(_ sender: Any) {
        
        socket?.sendJson(method: "voiceModulation", params: [ "tone" : self.selectedVoice.first])
        print("텍스트 꾸미기 데이터 보내기")
        dismiss(animated: true, completion: nil)
        
    }
    @IBOutlet weak var voiceConfirmBtn: UIButton!
    @IBOutlet weak var txtMenuContainerView: UIView!
    @IBOutlet weak var voiceMenuContainerView: UIView!
    @IBOutlet weak var locationSelectView: UISegmentedControl!
    @IBOutlet weak var textView: UITextField!
    @IBOutlet weak var colorPickerBtn: UIButton!
    //글자 크기 조절 관련 ui
    @IBOutlet weak var fontSizeTF: UITextField!
    
    @IBOutlet weak var sizePlusMinusBtn: UIStepper!
    //글자 굵기
    @IBOutlet weak var weightSelectView: UISegmentedControl!
    @IBOutlet weak var confirmBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    
    @IBAction func closeTxtDecoView(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)

    }
    @IBOutlet weak var locationGuideLabel: UITextView!
    
    @IBOutlet weak var sizeGuideDetailLabel: UILabel!
    @IBOutlet weak var sizeGuideLabel: UILabel!
    @IBOutlet weak var weightGuideLable: UILabel!
    //위치
    var location: String = "up"
    //색깔 - r, g, b
    var selectedColorUnit = Array<Any>()
    //글자 굵기 선택한 값 -> 서버에 보낼 때 사용(기본값2)
    var selectedWeight : Int = 3
    //글자 크기 선택한 값 -> 서버에 보낼 때 사용(기본값2)
    var selectedSize : Int = 2
    var showTxtValue: String = ""
    var showImgValue: String = ""
    
    var picker : UIColorPickerViewController!
 
    
    @IBOutlet weak var voiceJerryBtn: UIButton!
    @IBOutlet weak var voiceTomBtn: UIButton!

    @IBOutlet weak var voiceMicBtn: UIButton!
    @IBOutlet weak var voiceSquirrelBtn: UIButton!
    
    var selectedVoice = Set<String>()
    
    @IBAction func squirrelSelected(_ sender: Any) {
     
        //선택한 후 다시 클릭했을 때 = 취소하는 경우
        if self.selectedVoice.contains("speedy"){
            voiceSquirrelBtn.isSelected = false
            self.selectedVoice.removeAll()
            voiceSquirrelBtn.backgroundColor = .clear
            //톰을 선택한 후 제리를 선택했을 때 톰을 무효화시키고 제리를 선택한 값으로 넣어야 함.
        }else{
            print("햄스터 선택함")
            voiceSquirrelBtn.isSelected = true
            self.selectedVoice.removeAll()
            self.selectedVoice.insert("speedy")
            voiceSquirrelBtn.backgroundColor = UIColor(named: "brightGreen")
            voiceMicBtn.backgroundColor = .clear
            voiceJerryBtn.backgroundColor = .clear
            voiceTomBtn.backgroundColor = .clear

        }
    }
    @IBAction func micSelected(_ sender: Any) {
        //선택한 후 다시 클릭했을 때 = 취소하는 경우
        if self.selectedVoice.contains("mic"){
            voiceMicBtn.isSelected = false
            self.selectedVoice.removeAll()
            voiceMicBtn.backgroundColor = .clear
            //톰을 선택한 후 제리를 선택했을 때 톰을 무효화시키고 제리를 선택한 값으로 넣어야 함.
        }else{
            print("마이크 선택함")
            voiceMicBtn.isSelected = true

            self.selectedVoice.removeAll()
            self.selectedVoice.insert("mic")
            voiceMicBtn.backgroundColor = UIColor(named: "brightGreen")
            voiceTomBtn.backgroundColor = .clear
            voiceJerryBtn.backgroundColor = .clear
            voiceSquirrelBtn.backgroundColor = .clear
        }
    }
    
    //개 아이콘 = low
    @IBAction func jerrySelected(_ sender: Any)
    {
        //선택한 후 다시 클릭했을 때 = 취소하는 경우
        if self.selectedVoice.contains("low"){
            voiceJerryBtn.isSelected = false

            self.selectedVoice.removeAll()
            voiceJerryBtn.backgroundColor = .clear

            //톰을 선택한 후 제리를 선택했을 때 톰을 무효화시키고 제리를 선택한 값으로 넣어야 함.
        }else{
            print("개 선택함")
            voiceJerryBtn.isSelected = true

            self.selectedVoice.removeAll()
            self.selectedVoice.insert("low")
            voiceJerryBtn.backgroundColor = UIColor(named: "brightGreen")
            voiceTomBtn.backgroundColor = .clear
            voiceMicBtn.backgroundColor = .clear
            voiceSquirrelBtn.backgroundColor = .clear
        }
    }
    
    //고양이 아이콘 = high
    @IBAction func tomSelected(_ sender: Any) {
        
        //선택한 후 다시 클릭했을 때 = 취소하는 경우
        if self.selectedVoice.contains("high"){
            voiceTomBtn.isSelected = false

            self.selectedVoice.removeAll()
            voiceTomBtn.backgroundColor = .clear
            //톰을 선택한 후 제리를 선택했을 때 톰을 무효화시키고 제리를 선택한 값으로 넣어야 함.
        }else{
            print("고양이 선택함")
            voiceTomBtn.isSelected = true

            self.selectedVoice.removeAll()
            self.selectedVoice.insert("high")
            voiceTomBtn.backgroundColor = UIColor(named: "brightGreen")
            voiceJerryBtn.backgroundColor = .clear
            voiceMicBtn.backgroundColor = .clear
            voiceSquirrelBtn.backgroundColor = .clear
        }
    }

    
    @IBAction func sendTxtDecoData(_ sender: Any) {
            
        let red = Int(selectedColorUnit[0] as! CGFloat * CGFloat(255))
        let green = Int(selectedColorUnit[1] as! CGFloat * CGFloat(255))
        let blue = Int(selectedColorUnit[2] as! CGFloat * CGFloat(255))
        
        socket?.sendJson(method: "textOverlay", params: ["text": self.textView.text,"position" : location, "color" : "static","r": red, "g": green, "b" : blue, "fontThick" : self.selectedWeight, "fontSize" : self.selectedSize])
        print("텍스트 꾸미기 데이터 보내기")
        dismiss(animated: true, completion: nil)

    }
    
    //글자 크기 변경 액션
    @IBAction func sizeChangedAction(_ sender: UIStepper) {
        print("글자 변경 크기 값: \(Int(sender.value).description)")
        fontSizeTF.text = Int(sender.value).description
        self.selectedSize = Int(fontSizeTF.text!) ?? 2
    }
    
    @IBAction func weightChangeAction(_ sender:UISegmentedControl) {
        
        let selectedWeightIdx = sender.selectedSegmentIndex
        //얇게
        if selectedWeightIdx == 0{
          
            self.selectedWeight = 1
            
        //기본
        }else if selectedWeightIdx == 1{
        
            self.selectedWeight = 3
            
         //굵게
        }else{
            self.selectedWeight = 5
        }
    }
    
    @IBAction func selectedLocationResult(_ sender: Any) {
        switch locationSelectView.selectedSegmentIndex{
        case 0:
            print("위 선택")
            self.location = "up"
        case 1:
            print("중간 선택")
            self.location = "middle"
        default:
            break
        }
    }

    @IBAction func showColorPicker(_ sender: Any) {
        
        let picker = UIColorPickerViewController()
        picker.delegate = self
        
        self.present(picker, animated: true, completion: nil)

       // textView.font = UIFont.boldSystemFont(ofSize: 10)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(txtMenuContainerView)
        view.addSubview(voiceMenuContainerView)
        
        if showVoiceMenu == true{
            
            voiceMenuContainerView.addSubview(voiceJerryBtn)
            voiceMenuContainerView.addSubview(voiceTomBtn)
            voiceMenuContainerView.addSubview(voiceMicBtn)
            voiceMenuContainerView.addSubview(voiceSquirrelBtn)
            voiceMenuContainerView.addSubview(voiceConfirmBtn)
            
            voiceTomBtn.layer.borderColor = UIColor.lightGray.cgColor
            voiceTomBtn.layer.borderWidth = 5
            voiceTomBtn.layer.cornerRadius = 5
            
            voiceJerryBtn.layer.borderColor = UIColor.lightGray.cgColor
            voiceJerryBtn.layer.borderWidth = 5
            voiceJerryBtn.layer.cornerRadius = 5
            
            voiceSquirrelBtn.layer.borderColor = UIColor.lightGray.cgColor
            voiceSquirrelBtn.layer.borderWidth = 5
            voiceSquirrelBtn.layer.cornerRadius = 5
            
            voiceMicBtn.layer.borderColor = UIColor.lightGray.cgColor
            voiceMicBtn.layer.borderWidth = 5
            voiceMicBtn.layer.cornerRadius = 5
            
            voiceConfirmBtn.layer.cornerRadius = 5
            voiceMenuContainerView.isHidden = false
            txtMenuContainerView.isHidden = true
            
            
        }else{
            
            txtMenuContainerView.addSubview(cancelBtn)
            txtMenuContainerView.addSubview(confirmBtn)
            txtMenuContainerView.addSubview(colorPickerBtn)
            txtMenuContainerView.addSubview(locationSelectView)
            txtMenuContainerView.addSubview(locationGuideLabel)
            txtMenuContainerView.addSubview(weightSelectView)
            txtMenuContainerView.addSubview(weightGuideLable)
            txtMenuContainerView.addSubview(sizeGuideLabel)
            txtMenuContainerView.addSubview(sizePlusMinusBtn)
            txtMenuContainerView.addSubview(fontSizeTF)
            
            textView.attributedPlaceholder =
                NSAttributedString(string: "화면에 넣을 글자", attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray])
            
            txtMenuContainerView.isHidden = false
            voiceMenuContainerView.isHidden = true
        }
        
        //글자 크기 stepper btn 설정 - wraps: 최대값 이상 클릭시 최소값으로 변경시키기, autorepeat: 유저가 stepper를 계속 클릭시 값을 그에 따라서 자동으로 변경시키는 것. maximunvalue: 최대값 설정.
        sizePlusMinusBtn.wraps = true
        sizePlusMinusBtn.autorepeat = false
        sizePlusMinusBtn.maximumValue = 10
        sizePlusMinusBtn.minimumValue = 1
       confirmBtn.layer.cornerRadius = 5
        cancelBtn.layer.cornerRadius = 5
        
    }
}

@available(iOS 14.0, *)
extension TxtDecoModalVC: UIColorPickerViewControllerDelegate{
    //  Called once you have finished picking the color.
      func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        
      }
      
      //  Called on every color selection done in the picker.
      func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        
        self.textView.textColor = viewController.selectedColor
        self.selectedColorUnit = viewController.selectedColor.cgColor.components!
        
        print("선택한 색깔 rgb: \(self.selectedColorUnit)")
      }
}
