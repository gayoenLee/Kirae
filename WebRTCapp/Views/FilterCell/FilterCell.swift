//
//  FilterCell.swift
//  WebRTCapp
//
//  Created by 이은호 on 2021/08/25.
//  Copyright © 2021 Sergio Paniego Blanco. All rights reserved.
//

import UIKit

class FilterCell: UICollectionViewCell {

    @IBOutlet weak var filterImage: UIImageView!
    
    @IBOutlet weak var selectedImage: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        

    }
    
    override var isSelected: Bool{
        didSet{
            print("filter cell is selected들어옴")
            if isSelected{
                //backgroundColor = .systemPink
                //selectedImage.isHidden = false
                if #available(iOS 13.0, *) {
                    filterImage.alpha = 0.3
                    
                    backgroundView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                    backgroundView?.contentMode = .center
                                        
                } else {
                    // Fallback on earlier versions
                }
                
            }else{
                backgroundColor = .clear
                //selectedImage.isHidden = true
                backgroundView?.removeFromSuperview()
                filterImage.alpha = 1
            }
        }
    }

}
struct FilterData{
    var title: String?
    var filterImage: UIImage
}


