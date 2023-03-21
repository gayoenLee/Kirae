//
//  StickerCell.swift
//  WebRTCapp
//
//  Created by 이은호 on 2021/09/01.
//  Copyright © 2021 Sergio Paniego Blanco. All rights reserved.
//

import UIKit

class StickerCell: UICollectionViewCell {

    @IBOutlet weak var stickerImgView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    

    override var isSelected: Bool{
        
        didSet{
            if isSelected{
               // stickerImgView.alpha = 0.3
                if #available(iOS 13.0, *) {
                    
                    stickerImgView.alpha = 0.3
                    
                    backgroundView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                    backgroundView?.contentMode = .center
                } else {
                    // Fallback on earlier versions
                }
                backgroundView?.contentMode = .center
                
            }else{
                backgroundColor = .clear
                //selectedImage.isHidden = true
                backgroundView?.removeFromSuperview()
                stickerImgView.alpha = 1
            }
            
        }
    }
}

struct StickerData{
    var title: String?
    var stickerImg : UIImage
}
