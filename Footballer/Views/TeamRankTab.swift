//
//  TeamRankTab.swift
//  Footballer
//
//  Created by Ethan Zhai on 2017/10/18.
//  Copyright © 2017年 Ethan Zhai. All rights reserved.
//

import UIKit
import MJRefresh
typealias StringCompletion = (_ success: Bool, _ url: String) -> Void

class TeamRankTab: UIView {
    let delegate = UIApplication.shared.delegate as! AppDelegate
    var league:String!
    var season:String!
    var numbers:Int!
    var champ: Int!
    var jsonPath: String = NSHomeDirectory() + "/Library/Caches/csl.json"
    let header = MJRefreshNormalHeader()
    let layout = UICollectionViewFlowLayout()
    var collectionView: UICollectionView!
    //    var results:Results.Team
    override init(frame: CGRect) {

        super.init(frame: frame)
        league = delegate.league
        season = delegate.season
        numbers = delegate.numbers
        champ = delegate.champ
        header.setRefreshingTarget(self, refreshingAction: #selector(TeamRankTab.headerRefresh))

        jsonPath = NSHomeDirectory() + "/Library/Caches/" + self.league! + ".json"

        
        let itemSizeWidth = frame.size.width
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 10
        layout.itemSize = CGSize(width: itemSizeWidth, height: 40)
        layout.headerReferenceSize = CGSize(width:itemSizeWidth, height: 30)
        collectionView = UICollectionView(frame: self.frame, collectionViewLayout: layout)

        if league == "CSL"{
            self.initial()
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initial(){
        self.sessionSimpleDownload(){(success, url) in
            if success {
                DispatchQueue.main.async{ self.collectionView.reloadData() }
            }else{
                let alertView = UIAlertView(title: "网络错误", message: "请检查网络连接", delegate: self, cancelButtonTitle: "确定")
                alertView.show()
            }
        }
        collectionView.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
        collectionView.register(TeamRankCell.self, forCellWithReuseIdentifier: "cellIdentifier")
        collectionView.register(TeamRankHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader ,withReuseIdentifier: "collectionReusableView")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top:0,left:0,bottom:40,right:0)
        self.collectionView!.mj_header = header
        self.addSubview(collectionView)
    }
    
    @objc func headerRefresh(){
        print("下拉刷新.")
        sleep(2)
        //重现生成数据
//        refreshItemData()
        //重现加载表格数据
        self.sessionSimpleDownload(){(success, url) in
            if success {
                DispatchQueue.main.async{ self.collectionView.reloadData() }
                
            }else{
                let alertView = UIAlertView(title: "网络错误", message: "请检查网络连接", delegate: self, cancelButtonTitle: "确定")
                alertView.show()
            }
            
        }
        //结束刷新
        self.collectionView!.mj_header.endRefreshing()
    }
    
    func sessionSimpleDownload(completion: @escaping StringCompletion){
        //下载地址
        let url = URL(string: ("https://odets.net/python?league=" + self.league! + "&season=" + self.season!))
        //请求
        let request = URLRequest(url: url!)
        let session = URLSession.shared
        //下载任务
        let downloadTask = session.downloadTask(with: request,completionHandler: { (location:URL?, response:URLResponse?, error:Error?) -> Void in
            //输出下载文件原来的存放目录
            //            print("location:\(location)")
            //location位置转换
            if location == nil {
                completion(false, "error")
//                downloadTask.resume()
            }else{
            let locationPath = location!.path
            let caches:String = NSHomeDirectory() + "/Library/Caches/" + self.league! + ".json"
            //创建文件管理器
            let fileManager = FileManager.default
            try? fileManager.removeItem(atPath: caches)
            try! fileManager.moveItem(atPath: locationPath, toPath: caches)
            print("new location:\(caches)")
            completion(true, caches)
            }
        })
        
        //使用resume方法启动任务
        downloadTask.resume()
    }
}
extension TeamRankTab: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return numbers
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        //        var team1:[Results.Team] = []
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellIdentifier", for: indexPath) as! TeamRankCell
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: jsonPath) {
            var str = try?String(contentsOfFile: jsonPath, encoding: String.Encoding.utf8)
            var data = str?.data(using: String.Encoding.utf8)
            let decoder = JSONDecoder()
            cell.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
            
            
            if let teamResults = try?decoder.decode(Results.self, from: data!)
            {
                //                    var number = 0
                //                    for team in teamResults.results {
                //                        team1[number] = team
                //                        number = number + 1
                //                    }
                //team1 = teamResults.results
                //                    cell.label.text = teamResults.results[indexPath.section].team_name
                cell.name.text = teamResults.results[indexPath.item].team_name
                cell.rank.text = teamResults.results[indexPath.item].rank
                cell.points.text = teamResults.results[indexPath.item].points
                cell.goals.text = teamResults.results[indexPath.item].goals_pro + "/" + teamResults.results[indexPath.item].goals_against
                cell.matches_lost.text = teamResults.results[indexPath.item].matches_lost
                cell.matches_draw.text = teamResults.results[indexPath.item].matches_draw
                cell.matches_won.text = teamResults.results[indexPath.item].matches_won
                cell.matches_total.text = teamResults.results[indexPath.item].matches_total
                if Int(cell.rank.text!)! <= self.champ {
                    print("rank:\(cell.rank.text) name:\(cell.name.text)")
                    cell.backgroundColor = UIColor(red: 0/255, green: 244/255, blue: 0/255, alpha: 1)
                }
                
                
                
                
            }
        }
//        print(jsonPath)

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize{
        return CGSize(width: 100, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionElementKindSectionHeader:
            let reusableview = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "collectionReusableView", for: indexPath) as! TeamRankHeader
            
            //            reusableview.frame = CGRect(0 , 0, 100, 50)
            //do other header related calls or settups
            return reusableview
            
        //
        default:  fatalError("Unexpected element kind")
        }
    }
}


