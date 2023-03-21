//
//  QuizResultViewController.swift
//  WebRTCapp
//
//  Created by 이은호 on 2021/09/07.
//  Copyright © 2021 Sergio Paniego Blanco. All rights reserved.
//

import UIKit


class QuizResultViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var dismissBtn: UIButton!
    @IBOutlet weak var quizResultTableView: UITableView!
    var gameResult :[GameResult] = [GameResult(nicckName: "asjdk", count: 0), GameResult(nicckName: "wsdg", count: 3)]
    
    @IBAction func clickDismissBtn(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gameResult.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
 
         let cell = tableView.dequeueReusableCell(withIdentifier: "QuizTableViewCell", for: indexPath) as! QuizTableViewCell
        cell.nameLabel.text = gameResult[indexPath.row].nicckName
        cell.rankingLabel.text = String(indexPath.row+1)
        cell.pointLabel.text = String(gameResult[indexPath.row].count)
        
        return cell
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        quizResultTableView.delegate = self
        quizResultTableView.dataSource = self

        self.dismissBtn.round(corners: [.allCorners], cornerRadius: 20)
        self.dismissBtn.backgroundColor = UIColor.systemPink
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

struct GameResult{
    var nicckName: String?
    var count : Int
}
