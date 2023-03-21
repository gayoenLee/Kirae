//
//  YoutubeListViewController.swift
//  WebRTCapp
//
//  Created by 이은호 on 2021/09/13.
//  Copyright © 2021 Sergio Paniego Blanco. All rights reserved.
//

import UIKit
import SwiftyJSON
import Kingfisher
import WebKit
import Alamofire

@available(iOS 11.0, *)
class YoutubeListViewController: UIViewController{
    
    var socket: WebSocketListener?
    //유튜브 동영상 검색 단어
    var searchTxt: String = ""
    var isSearching: Bool = false
    var videoData : [VideoStruct] = []
    var selectedVideoKey : String = ""
    var pageNum : Int = 1
    var prevPageToken : String = ""
    var nextPageToken : String = ""
    // 이미 만들어진 셀들의 높이 값을 저장
    var cellHeights: [IndexPath: CGFloat] = [:]
    
    var myTableView : UITableView!
    var okBtn : UIButton!
    var searchBar : UISearchBar!
    var closeBtn : UIButton!
    
    //페이징 하고 있는지 여부
    var isPaging: Bool = false
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        okBtn = UIButton()
        myTableView = UITableView()
        searchBar = UISearchBar()
        closeBtn = UIButton()
        
        myTableView.delegate = self
        myTableView.dataSource = self
        
        searchBar.delegate = self
        
        view.addSubview(myTableView)
        view.addSubview(okBtn)
        view.addSubview(searchBar)
        view.addSubview(closeBtn)
        
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        closeBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        closeBtn.contentMode = .scaleAspectFit

        let customImg = #imageLiteral(resourceName: "closeBlack")
        let newImg = customImg.resizedImage(Size: CGSize(width: 40, height: 40))
        closeBtn.setImage(newImg, for: .normal)
        closeBtn.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        closeBtn.addTarget(self, action: #selector(closeYoutubeList), for: .touchUpInside)
        
        //커스텀 셀 가져오기
        myTableView.register(YoutubeCell.classForCoder(), forCellReuseIdentifier: "cell")
        //layout
        myTableView.translatesAutoresizingMaskIntoConstraints = false
        myTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor).isActive = true
        myTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        myTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        myTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.topAnchor.constraint(equalTo: closeBtn.bottomAnchor).isActive = true
        searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        searchBar.placeholder = "동영상 검색"
            
        okBtn.setTitle("확인", for: .normal)
        okBtn.backgroundColor = .black
        okBtn.layer.cornerRadius = 25
        okBtn.translatesAutoresizingMaskIntoConstraints = false
        okBtn.widthAnchor.constraint(equalToConstant: 100).isActive = true
        okBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        okBtn.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        okBtn.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor, constant: -10).isActive = true
        okBtn.addTarget(self, action: #selector(okAction), for: .touchUpInside)
        
        getYoutubeList(pageNum: self.pageNum)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func okAction(){
        print("버튼 클릭")
        if self.selectedVideoKey != ""{
         let alert = WebViewController()
            self.navigationController?.pushViewController(alert, animated: true)
            
            alert.modalPresentationStyle = .fullScreen
            //애니메이션 효과 적용
            alert.modalTransitionStyle = .crossDissolve
            alert.videoKey = self.selectedVideoKey
            alert.socket = self.socket
            socket?.sendJson(method: "youtube", params: ["behavior" : "watchVideo","videoKey" : self.selectedVideoKey])
         
                self.present(alert, animated: true, completion: nil)
            
        }
    }
    
    @objc func closeYoutubeList(){
        print("동영상 클로즈 노티 받음")
        self.dismiss(animated: true)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    @objc func keyboardWillShow(noti: Notification) {
         //self.view.frame.origin.y = -150 // Move view 150 points upward
        var height : CGFloat = 0.0
        if let keyboardFrame: NSValue = noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            height = keyboardRectangle.height
            print("keyboardHeight = \(height)")
            
        }

        }

    @objc func keyboardWillHide(_ sender: Notification) {

   // self.view.frame.origin.y = 0 // Move view to original position
    }
    
}

extension UIImage
{
  func resizedImage(Size sizeImage: CGSize) -> UIImage?
  {
      let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: sizeImage.width, height: sizeImage.height))
      UIGraphicsBeginImageContextWithOptions(frame.size, false, 0)
      self.draw(in: frame)
      let resizedImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      self.withRenderingMode(.alwaysOriginal)
      return resizedImage
  }
}
@available(iOS 11.0, *)
extension YoutubeListViewController : UISearchBarDelegate{
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        print("텍스트 입력 시작")
        searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("취소 버튼 클릭")
        searchBar.text = ""
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        print("did end editing: \(searchBar.text)")
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("서치 버튼 클릭: \(searchBar.text)")
        
        if searchBar.text != nil{
          
            self.pageNum += 1
            self.isSearching = true
        self.searchTxt = searchBar.text!
            self.pageNum = 1
        getSearchVideoResults()
        }
        
        
        self.searchBar.endEditing(true)
        
    }
}

@available(iOS 11.0, *)
extension YoutubeListViewController{
    
    func getOneVideo(videoKey: String){
        let url = URL(string: "https://www.youtube.com/embed/\(videoKey)")
        
    }
    
    func getYoutubeList(pageNum: Int){
        self.isPaging = true

        var params : [String: Any] = ["part": "id"]
        
        var request : DataRequest
        if pageNum != 1{
       
            print("----------------------두번째 페이지\(pageNum)--------------------------------------")
            
         request = Alamofire.request("https://www.googleapis.com/youtube/v3/videos?part=snippet&chart=mostPopular&maxResults=10&regionCode=KR&pageToken=\(nextPageToken)&key=AIzaSyDJ5pMG3SybZqZ2G530SuQV8gGi9xP-t1A", method: .get, encoding: JSONEncoding.default, headers: nil)
        
        }else{
            print("----------------------첫번째 페이지\(pageNum)--------------------------------------")
             request =  Alamofire.request("https://www.googleapis.com/youtube/v3/videos?part=snippet&chart=mostPopular&maxResults=10&regionCode=KR&key=AIzaSyDJ5pMG3SybZqZ2G530SuQV8gGi9xP-t1A", method: .get, encoding: JSONEncoding.default, headers: nil)
            
        }
        
        request.responseJSON(completionHandler: {(response) in
        
            print("유튜브 데이터 가져오기 result: \(response)")
            switch response.result {
            case .success(let value):

                let json = JSON(value)
                print("유튭 데이터 제이슨: \(json)")
                let items = json["items"].array
               
                let nextPageTokenValue = json["nextPageToken"].string
                print("nextPageTokenValue:\(nextPageTokenValue)")
                if nextPageTokenValue != nil{
                    self.nextPageToken = nextPageTokenValue!
                }
                print("넥스트 페이지 토큰: \(self.nextPageToken)")
                
                let prevPageTokenValue = json["prevPageToken"].string
                if prevPageTokenValue != nil{
                    self.prevPageToken
                        = prevPageTokenValue!
                }
                
                for index in items!{
                    print("아이템 한개: \(index)")
                    let id = index["id"].stringValue
                    let snippet = index["snippet"].dictionary
                    let title = snippet!["title"]!.stringValue
                    let channel = snippet!["channelTitle"]!.stringValue
                    
                    self.videoData.append(VideoStruct(Key: id, Title: title, channel: channel))
                }
                
                print("저장한 비디오 데이터 확인: \( self.videoData)")
                DispatchQueue.main.async{
                    self.isPaging = false
                    self.myTableView.reloadData()
                               }
                self.pageNum += 1
            default: return
                
            }
        })
    }
    
    func getSearchVideoResults(){
        self.isPaging = true
        var url : String
        if pageNum == 1{
            self.videoData.removeAll()
         url = "https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=10&order=relevance&q=\(self.searchTxt)&regionCode=KR&key=AIzaSyDJ5pMG3SybZqZ2G530SuQV8gGi9xP-t1A"
        }else{
            url = "https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=10&order=relevance&q=\(self.searchTxt)&regionCode=KR&pageToken=\(nextPageToken)&key=AIzaSyDJ5pMG3SybZqZ2G530SuQV8gGi9xP-t1A"
            
        }
        
        let encoded = url.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        let encodedUrl = URL(string: encoded!)
        let request = Alamofire.request(encodedUrl as! URLConvertible, method: .get, encoding: JSONEncoding.default, headers: nil)
        
        request.responseJSON(completionHandler: {response in
            print("------\(response)")
            switch response.result{
            case .success(let value):
                
                //self.videoData.removeAll()
                print("검색 결과 데이터 가져오기 결과:\(value)")
                let json = JSON(value)
                print("검색 결과 유튭 데이터 제이슨: \(json)")
                let items = json["items"].array
                
                let nextPageTokenValue = json["nextPageToken"].string
                print("검색 결과 nextPageTokenValue:\(nextPageTokenValue)")
                if nextPageTokenValue != nil{
                    self.nextPageToken = nextPageTokenValue!
                }
                print("검색 결과 넥스트 페이지 토큰: \(self.nextPageToken)")
                
                let prevPageTokenValue = json["prevPageToken"].string
                if prevPageTokenValue != nil{
                    self.prevPageToken
                        = prevPageTokenValue!
                }
                
                for index in items!{
                    //print("검색 결과 아이템 한개: \(index)")
                    let id = index["id"].dictionary
                    var videoKey : String = ""
                    videoKey = id!["videoId"]?.string ?? ""
                    if videoKey == ""{
                        videoKey = id!["channelId"]!.stringValue
                    }
                    
                    let snippet = index["snippet"].dictionary
                    let title = snippet!["title"]!.stringValue
                    let channel = snippet!["channelTitle"]!.stringValue
                    
                    self.videoData.append(VideoStruct(Key: videoKey, Title: title, channel: channel))
                }
                print("저장한 비디오 데이터 확인: \( self.videoData)")
                DispatchQueue.main.async{
                    self.isPaging = false
                  self.myTableView.reloadData()
                               }
                
                self.pageNum += 1
            case .failure(let error):
                print("검색 결과 데이터 가져오기 결과 에러:\(error)")

            }
            
        })
    }
}

extension YoutubeListViewController :UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return  videoData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //as로 커스텀한 cell클래스를 캐스팅
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! YoutubeCell
        
        //웹뷰 셀
//        let webViewCell = cell.setWebView(rootVC: self, frame: self.view.frame)
//        webViewCell.uiDelegate = self
//        webViewCell.navigationDelegate = self
        //cell.addSubview(webViewCell)
        
        let urlString = "https://img.youtube.com/vi/\(videoData[indexPath.row].Key)/0.jpg"
               let fileURL = URL(string: urlString)
        cell.imgView.kf.setImage(with: fileURL)
        cell.imgView.contentMode = .scaleAspectFill
        cell.imgView.layer.cornerRadius = 20
        
        cell.title.text = videoData[indexPath.row].Title
        cell.channelName.text = videoData[indexPath.row].channel
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.frame.height / 6
       
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("아이템 한 개 클릭")
        
        self.selectedVideoKey = videoData[indexPath.row].Key
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
    
        //bounds의 origin point(x, y)를 말함.따라서 스크롤을 하면 변할 수 밖에 없음.
        let contentYOffset: CGFloat = scrollView.contentOffset.y
        let tableViewContentSize = myTableView.contentSize.height
       // let scrollviewHeight: CGFloat = scrollView.contentSize.height
        //let distanceFromBottom: CGFloat = scrollviewHeight - contentYOffset
        let paginationY = tableViewContentSize*0.5
        print("스크롤뷰: \(self.isPaging), \(contentYOffset), \(tableViewContentSize - paginationY)")
        if self.isPaging == false&&contentYOffset > tableViewContentSize - paginationY{
            print("스크롤뷰 did scroll")

            print("스크롤뷰의 y좌표의 위치: \(contentYOffset)")
            print("테이블뷰 컨텐츠 사이즈: \(tableViewContentSize)")
            
            if isSearching{
                self.getSearchVideoResults()
            }else{
            self.getYoutubeList(pageNum: self.pageNum)
        }
        }
    }
}

struct VideoStruct {
    var Key: String = ""
    var Title:String = ""
    var channel: String = ""
}


