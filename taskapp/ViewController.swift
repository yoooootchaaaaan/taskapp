//
//  ViewController.swift
//  taskapp
//
//  Created by 高橋伊希 on 2016/08/20.
//  Copyright © 2016年 yoshiki.takahashi. All rights reserved.
//

import UIKit
import RealmSwift

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    // Realmインスタンスを取得する
    let realm = try! Realm()
    
    // DB内のタスクが格納されるリスト。
    // 日付近い順\順でソート：降順
    // 以降内容をアップデートするとリスト内は自動的に更新される。
    var taskArray = try! Realm().objects(Task).sorted("date", ascending: false)
    
    var inputText:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //サーチバーに関する記述
        searchBar.delegate = self
        searchBar.frame = CGRectMake(0, 0, 300, 70)
        searchBar.layer.position = CGPoint(x: self.view.bounds.width/2, y: 100)
        searchBar.showsCancelButton = false
        searchBar.showsBookmarkButton = false
        searchBar.prompt = "カテゴリを検索する"
        searchBar.placeholder = "ここに入力してください"
        searchBar.showsSearchResultsButton = false
        
        // 入力が無い状態でも検索できるようにする
        searchBar.enablesReturnKeyAutomatically = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // segue で画面遷移するに呼ばれる
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?){
        let inputViewController:InputViewController = segue.destinationViewController as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            let task = Task()
            task.date = NSDate()
            
            if taskArray.count != 0 {
                task.id = taskArray.max("id")! + 1
            }
            
            inputViewController.task = task
        }
    }
    
    // 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // MARK: UITableViewDataSourceプロトコルのメソッド
    // データの数（＝セルの数）を返すメソッド
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }
    
    // 各セルの内容を返すメソッド
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "カテゴリ:\(task.category)" + " " + "yyyy-MM-dd HH:mm"
        
        let dateString:String = formatter.stringFromDate(task.date)
        cell.detailTextLabel?.text = dateString
        
        return cell
    }
    
    // MARK: UITableViewDelegateプロトコルのメソッド
    // 各セルを選択した時に実行されるメソッド
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("cellSegue",sender: nil)
    }
    
    // セルが削除が可能なことを伝えるメソッド
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath)-> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            
            // ローカル通知をキャンセルする
            let task = taskArray[indexPath.row]
            
            for notification in UIApplication.sharedApplication().scheduledLocalNotifications! {
                if notification.userInfo!["id"] as! Int == task.id {
                    UIApplication.sharedApplication().cancelLocalNotification(notification)
                    break
                }
            }
            
            // データベースから削除する
            try! realm.write {
                self.realm.delete(self.taskArray[indexPath.row])
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            }
        }
    }
    
    //Cancelボタンが押された時に呼ばれる//
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.text = ""
    }
    
    //Searchボタンが押された時に呼ばれる//
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        inputText = searchBar.text!
        if(inputText==nil || inputText!.isEmpty){
            taskArray = try! Realm().objects(Task).sorted("date", ascending: false)
            tableView.reloadData()
            searchBar.text = ""
            self.view.endEditing(true)
        } else {
            taskArray = try! Realm().objects(Task).filter("category CONTAINS[c] %@", inputText!)
            tableView.reloadData()
            searchBar.text = ""
            self.view.endEditing(true)
        }
    }


}

