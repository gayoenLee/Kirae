//
//  YoutubeCell.swift
//  WebRTCapp
//
//  Created by 이은호 on 2021/09/13.
//  Copyright © 2021 Sergio Paniego Blanco. All rights reserved.
//

import UIKit
import WebKit

class YoutubeCell: UITableViewCell {
    public var title: UILabel!
    public var imgView : UIImageView!
    public var channelName: UILabel!

    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?){
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
        
        self.contentView.addSubview(title)
        self.contentView.addSubview(imgView)
        self.contentView.addSubview(channelName)
        
        title.translatesAutoresizingMaskIntoConstraints = false
        imgView.translatesAutoresizingMaskIntoConstraints = false
        channelName.translatesAutoresizingMaskIntoConstraints = false
     
        //leading anchor로부터 10pt간격
        imgView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10).isActive = true
        //이미지뷰를 y축 가운데에 놓이도록 설정
        imgView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        imgView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        imgView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        imgView?.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
        imgView?.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true

        imgView.layer.cornerRadius = 20
        
        title.leadingAnchor.constraint(equalTo: imgView.trailingAnchor, constant: 10).isActive = true
        //title.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        channelName.topAnchor.constraint(equalTo: title.bottomAnchor).isActive = true
        channelName.leadingAnchor.constraint(equalTo:  imgView.trailingAnchor, constant: 10).isActive = true
        
        }
    
    

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
       }
    
    
    private func setup(){
        title = UILabel()
        title.textColor = .black
        title.font = UIFont.boldSystemFont(ofSize: 15)
        title.textAlignment = .left
        
        channelName = UILabel()
        channelName.textColor = .gray
        channelName.font = UIFont.systemFont(ofSize: 10)
        channelName.textAlignment = .left
        
        imgView = UIImageView()
       // imgView.image = UIImage(systemName: "hare")
    }
    


}
