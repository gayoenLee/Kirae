//
//  QuizUserTableViewCell.swift
//  WebRTCapp
//
//  Created by 이은호 on 2021/09/07.
//  Copyright © 2021 Sergio Paniego Blanco. All rights reserved.
//

import UIKit

class QuizUserTableViewCell: UITableViewCell {

    @IBOutlet weak var pointNum: UILabel!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var rankingNum: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
