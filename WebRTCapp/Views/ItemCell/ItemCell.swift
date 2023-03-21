//
//  ItemCell.swift
//  WebRTCapp
//
//  Created by 이은호 on 2021/08/22.
//  Copyright © 2021 Sergio Paniego Blanco. All rights reserved.
//

import UIKit

class ItemCell: UICollectionViewCell {

    @IBOutlet weak var videoOffImg: UIImageView!
    @IBOutlet weak var micOffImg: UIImageView!
    @IBOutlet weak var VideoView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    var userId: String = ""
    var cornerRadius: CGFloat = 15.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        //라운드 코너 적용
        contentView.layer.cornerRadius = cornerRadius
        contentView.layer.masksToBounds = true
        
        //그림자 없애기
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = false
        
        //그림작 적용
        layer.shadowRadius = 8.0
               layer.shadowOpacity = 0.10
               layer.shadowColor = UIColor.black.cgColor
               layer.shadowOffset = CGSize(width: 0, height: 5)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Improve scrolling performance with an explicit shadowPath
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: cornerRadius
        ).cgPath
    }
    

}
