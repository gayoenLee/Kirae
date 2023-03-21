//
//  UIView.swift
//  WebRTCapp
//
//  Created by 이은호 on 2021/09/09.
//  Copyright © 2021 Sergio Paniego Blanco. All rights reserved.
//

import UIKit

extension UIView{
    
    func round(corners: UIRectCorner, cornerRadius: Double) {
            
            let size = CGSize(width: cornerRadius, height: cornerRadius)
            let bezierPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: size)
            let shapeLayer = CAShapeLayer()
            shapeLayer.frame = self.bounds
            shapeLayer.path = bezierPath.cgPath
            self.layer.mask = shapeLayer
        }
    
    func addShadow(shadowColor: UIColor, offSet: CGSize, opacity: Float, shadowRadius: CGFloat, cornerRadius: CGFloat, corners: UIRectCorner, fillColor: UIColor = .white) {
          
          let shadowLayer = CAShapeLayer()
          let size = CGSize(width: cornerRadius, height: cornerRadius)
          let cgPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: size).cgPath //1
          shadowLayer.path = cgPath //2
          shadowLayer.fillColor = fillColor.cgColor //3
          shadowLayer.shadowColor = shadowColor.cgColor //4
          shadowLayer.shadowPath = cgPath
          shadowLayer.shadowOffset = offSet //5
          shadowLayer.shadowOpacity = opacity
          shadowLayer.shadowRadius = shadowRadius
          self.layer.addSublayer(shadowLayer)
      
}
}
