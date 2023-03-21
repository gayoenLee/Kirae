//
//  ColorCollectionViewCell.swift
//  WebRTCapp
//
//  Created by 이은호 on 2021/09/05.
//  Copyright © 2021 Sergio Paniego Blanco. All rights reserved.
//

import UIKit

class ColorCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var colorView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    
    override var isSelected: Bool{
        didSet{
            print("color cell is selected들어옴")
            if isSelected{
                print("선택한 색깔")
                //backgroundColor = .systemPink
                //selectedImage.isHidden = false
                if #available(iOS 13.0, *) {
                    colorView.alpha = 0.3
                    
                    backgroundView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                    backgroundView?.contentMode = .center
                                        
                } else {
                    // Fallback on earlier versions
                }
                
            }else{
                backgroundColor = .clear
                //selectedImage.isHidden = true
                backgroundView?.removeFromSuperview()
                colorView.alpha = 1
            }
        }
    }


}

struct ColorData{
    var colorName: String?
    var colorView: UIColor?
}
