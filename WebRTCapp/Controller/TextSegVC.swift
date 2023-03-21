//
//  TextSegVC.swift
//  WebRTCapp
//
//  Created by 이은호 on 2021/08/31.
//  Copyright © 2021 Sergio Paniego Blanco. All rights reserved.
//

import UIKit
import MaterialComponents

@available(iOS 14.0, *)
class TextSegVC: UIViewController {

    var socket: WebSocketListener?
//    var picker : UIColorPickerViewController!
//
//    //위치
//    var location: String = "up"
//    //색깔 - r, g, b
//    var selectedColorUnit = Array<Any>()
//    //글자 굵기 선택한 값 -> 서버에 보낼 때 사용(기본값2)
//    var selectedWeight : Int = 3
//    //글자 크기 선택한 값 -> 서버에 보낼 때 사용(기본값2)
//    var selectedSize : Int = 2
    
//    @IBOutlet weak var locationSelectView: UISegmentedControl!
//    @IBOutlet weak var textView: UITextField!
//    @IBOutlet weak var colorPickerBtn: UIButton!
//    //글자 크기 조절 관련 ui
//    @IBOutlet weak var fontSizeTF: UITextField!
//
//    @IBOutlet weak var sizePlusMinusBtn: UIStepper!
//    //글자 굵기
//    @IBOutlet weak var weightSelectView: UISegmentedControl!
//    @IBOutlet weak var confirmBtn: UIButton!
    
//    @IBAction func sendTxtDecoData(_ sender: Any) {
//
////        print("보내기 버튼 클릭 글자 크기 : \(self.fontSizeTF.text), 글자 굵기: \(self.selectedWeight)")
//        let red = Int(selectedColorUnit[0] as! CGFloat * CGFloat(255))
//        let green = Int(selectedColorUnit[1] as! CGFloat * CGFloat(255))
//        let blue = Int(selectedColorUnit[2] as! CGFloat * CGFloat(255))
//
//        socket?.sendJson(method: "textOverlay", params: ["text": self.textView.text,"position" : location, "color" : "static","r": red, "g": green, "b" : blue, "fontThick" : self.selectedWeight, "fontSize" : self.selectedSize])
//        print("텍스트 꾸미기 데이터 보내기")
//        dismiss(animated: true, completion: nil)
//
//    }
    
//    //글자 크기 변경 액션
//    @IBAction func sizeChangedAction(_ sender: UIStepper) {
//        print("글자 변경 크기 값: \(Int(sender.value).description)")
//        fontSizeTF.text = Int(sender.value).description
//        self.selectedSize = Int(fontSizeTF.text!) ?? 2
//    }
//
//    @IBAction func weightChangeAction(_ sender:UISegmentedControl) {
//
//        let selectedWeightIdx = sender.selectedSegmentIndex
//        //얇게
//        if selectedWeightIdx == 0{
//
//            self.selectedWeight = 1
//
//        //기본
//        }else if selectedWeightIdx == 1{
//
//            self.selectedWeight = 3
//
//         //굵게
//        }else{
//            self.selectedWeight = 5
//        }
//    }
//
//    @IBAction func selectedLocationResult(_ sender: Any) {
//        switch locationSelectView.selectedSegmentIndex{
//        case 0:
//            print("위 선택")
//            self.location = "up"
//        case 1:
//            print("중간 선택")
//            self.location = "middle"
//        default:
//            break
//        }
//    }
//
//
//    @IBAction func showColorPicker(_ sender: Any) {
//
//        let picker = UIColorPickerViewController()
//        picker.delegate = self
//        self.present(picker, animated: true, completion: nil)
//
//        textView.attributedPlaceholder =
//            NSAttributedString(string: "화면에 넣을 글자를 입력해주세요", attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray])
//        textView.font = UIFont.boldSystemFont(ofSize: 10)
//    }
    
    
    
    override func viewDidLoad() {
        self.view.backgroundColor = .red
        super.viewDidLoad()
        
        //글자 크기 stepper btn 설정 - wraps: 최대값 이상 클릭시 최소값으로 변경시키기, autorepeat: 유저가 stepper를 계속 클릭시 값을 그에 따라서 자동으로 변경시키는 것. maximunvalue: 최대값 설정.
//         sizePlusMinusBtn.wraps = true
//         sizePlusMinusBtn.autorepeat = false
//         sizePlusMinusBtn.maximumValue = 10
//         sizePlusMinusBtn.minimumValue = 1
//
//        confirmBtn.layer.cornerRadius = 4
    }

}

//@available(iOS 14.0, *)
//extension TextSegVC : UIColorPickerViewControllerDelegate{
//    //  Called once you have finished picking the color.
//      func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
//
//      }
//
//      //  Called on every color selection done in the picker.
//      func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
//
//        self.textView.textColor = viewController.selectedColor
//        self.selectedColorUnit = viewController.selectedColor.cgColor.components!
//
//        print("선택한 색깔 rgb: \(self.selectedColorUnit)")
//      }
//}
