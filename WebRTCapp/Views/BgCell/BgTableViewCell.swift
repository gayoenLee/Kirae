//
//  BgTableViewCell.swift
//  WebRTCapp
//
//  Created by 이은호 on 2021/09/08.
//  Copyright © 2021 Sergio Paniego Blanco. All rights reserved.
//

import UIKit

class BgTableViewCell: UITableViewCell {

    @IBOutlet weak var bgImgView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override var isSelected: Bool{
        didSet{
            if isSelected{
               // stickerImgView.alpha = 0.3
                if #available(iOS 13.0, *) {

                    bgImgView.alpha = 0.3

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
                bgImgView.alpha = 1
            }
            
        }
    }
    
}
