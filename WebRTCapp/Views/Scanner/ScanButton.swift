//
//  ScanButton.swift
//  WebRTCapp
//
//  Created by 이은호 on 2021/10/04.
//  Copyright © 2021 Sergio Paniego Blanco. All rights reserved.
//

import UIKit

class ScanButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false
        setTitle("스캔", for: .normal)
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 18.0)
        titleLabel?.textColor = .white
        layer.cornerRadius = 7.0
        backgroundColor = UIColor.systemIndigo
    }

}
