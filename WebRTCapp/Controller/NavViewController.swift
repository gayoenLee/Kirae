//
//  NavViewController.swift
//  WebRTCapp
//
//  Created by 이은호 on 2021/08/22.
//  Copyright © 2021 Sergio Paniego Blanco. All rights reserved.
//

import UIKit

class NavViewController: UIViewController, UICollectionViewDataSource{
    
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    let dataArray = ["AA", "BB", "CC", "DD", "EE", "FF"]
    var estimateWidth = 160.0
    var cellMarginSize = 16.0
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set delegates
       // self.collectionView.delegate = self
        self.collectionView.dataSource = self
        //register cells
        self.collectionView.register(UINib(nibName: "ItemCell", bundle: nil), forCellWithReuseIdentifier: "ItemCell")
        
        //setupgrid view
        self.setupGridView()
    }
    
    func setupGridView(){
        let flow = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flow.minimumInteritemSpacing = CGFloat(self.cellMarginSize)
        flow.minimumLineSpacing = CGFloat(self.cellMarginSize)
    }
}

extension NavViewController: UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath) as! ItemCell
//        cell.setData(text: self.dataArray[indexPath.row])
        
        return cell
    }
}

extension NavViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.caculateWith()
        return CGSize(width: width, height: width)
    }
    
    func caculateWith() -> CGFloat{
        let estimatedWidth = CGFloat(estimateWidth)
        let cellCount = floor(CGFloat(self.view.frame.size.width / estimatedWidth))
        
        let margin = CGFloat(cellMarginSize * 2)
        let width = (self.view.frame.size.width - CGFloat(cellMarginSize) * (cellCount - 1) - margin) / cellCount
        
        return width
    }
}
