//
//  FaceExtension.swift
//  WebRTCapp
//
//  Created by 이은호 on 2021/09/27.
//  Copyright © 2021 Sergio Paniego Blanco. All rights reserved.
//

import Foundation


protocol FoundFaceProtocol: class{
    func sendData(name: String, percnet: Int) -> FaceInfo
}


