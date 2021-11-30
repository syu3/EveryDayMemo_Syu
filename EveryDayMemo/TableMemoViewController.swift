//
//  TableMemoViewController.swift
//  EveryDayMemo
//
//  Created by 加藤周 on 2021/08/28.
//

import UIKit
import GoogleMobileAds
import CoreData

class TableMemoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate,UITextFieldDelegate {
    @IBOutlet var tableView : UITableView!
    
    @IBOutlet var editDateLabel : UILabel!
    @IBOutlet var editTextView : UITextView!
    
    @IBOutlet var editView : UIView!
    @IBOutlet var bannerView : GADBannerView!
    
    @IBOutlet weak var editAutoLayout: NSLayoutConstraint!
    @IBOutlet weak var normalAutoLayout: NSLayoutConstraint!
    
    var memoTextArray:[String] = []
    var memoDateArray:[String] = []
    
    var memoSearchTextArray:[String] = []
    var memoSearchDateArray:[String] = []
    
    var selectedDate = ""
    var isFirst = true
    
    @IBOutlet var searchField : UITextField!
    
    var activeTextField : UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        
        bannerView.adUnitID = "ca-app-pub-7890542862997264/1044340661"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
        searchField.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        editTextView.delegate = self
        
        editView.layer.cornerRadius = 30.0
        editView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        //        editView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height, width: editView.frame.width, height: editView.frame.height)
        
        NSLayoutConstraint.deactivate([editAutoLayout])
        NSLayoutConstraint.activate([normalAutoLayout])
        //        NSLayoutConstraint.deactivate([normalAutoLayout])
        //        NSLayoutConstraint.activate([editAutoLayout])
        
        
        //        panViewをパンジェスチャー（ドラッグ）で動かせるように
        let panGesture = UIPanGestureRecognizer()
        panGesture.addTarget(self, action: #selector(panAction(_:)))
        editView.addGestureRecognizer(panGesture)
        
        // ツールバー生成
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 40))
        // スタイルを設定
        toolBar.barStyle = UIBarStyle.default
        // 画面幅に合わせてサイズを変更
        toolBar.sizeToFit()
        // 閉じるボタンを右に配置するためのスペース?
        let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        // 閉じるボタン
        let commitButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(commitButtonTapped))
        // スペース、閉じるボタンを右側に配置
        toolBar.items = [spacer, commitButton]
        // textViewのキーボードにツールバーを設定
        editTextView.inputAccessoryView = toolBar
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        // Do any additional setup after loading the view.
        
        getAllPlannerDays()
    }
    override func viewDidAppear(_ animated: Bool) {
        isFirst = true
    }
    func textViewDidChange(_ textView: UITextView) {
        if(selectedDate != nil){
            changeData()
        }
    }
    func changeData(){
        var isChange = false
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName:"MemoData")
        //条件指定
        print("memoDate = %@", String(selectedDate))
        fetchRequest.predicate = NSPredicate(format: "memoDate = %@", String(selectedDate))
        print("あ",fetchRequest)
        //        if(fetchRequest.sortDescriptors != nil){
        let context = appDelegate.persistentContainer.viewContext
        do {
            let myResults = try context.fetch(fetchRequest)
            
            for myData in myResults {
                isChange = true
                myData.setValue(editTextView.text, forKeyPath: "memoText")
                
            }
//            if(isChange == false){
//                print("新規なので追加します。")
//                saveData()
//            }
            //                let memoData = MemoData(context: context)
            //
            //                memoData.memoText = textView.text
            //                memoData.memoDate = selectedDate
            
            try context.save()
            
            getAllPlannerDays()
        } catch let error as NSError {
            print("\(error), \(error.userInfo)")
        }
    }
    func getAllPlannerDays(){
        memoTextArray = []
        memoDateArray = []
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let savedPlaceFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "MemoData")
//         ソートを追加
                savedPlaceFetch.sortDescriptors = [
                    NSSortDescriptor(key: "memoDate", ascending: true)
                ]
        do {
            let result = try context.fetch(savedPlaceFetch)
            print("aiu",result)
            for myData in result {
                if((myData as AnyObject).value(forKey: "memoText") as! String == "" && isFirst == true){
                    print("空だから削除します",(myData as AnyObject).value(forKey: "memoDate") as! String)
                    deleteKaraData(deleteDate: (myData as AnyObject).value(forKey: "memoDate") as! String)
                }else{
                    memoTextArray.append((myData as AnyObject).value(forKey: "memoText") as! String)
                    memoDateArray.append((myData as AnyObject).value(forKey: "memoDate") as! String)
                }
            }
//            memoTextArray = ["水族館に行った","今日はお仕事DAY","仕事終わりに映画を見に行った","今日は残業。疲れた","今日は休みをもらって、デート！","美味しいスイーツを食べに行った","好きなドラマを見た！かっこよかった","上司に怒られた(泣)","d","d","d","d","d","d","d","","d","d","d","d","d","d","d","d","d","d","d","d","d","d","d"]
//            memoDateArray = ["2021/09/26","2021/09/27","2021/09/28","2021/09/29","2021/09/30","2021/10/01","2021/10/02","2021/10/03","2021/10/04","2021/10/05","2021/10/06","2021/10/07","2021/10/08","2021/10/09","2021/10/10","2021/10/12","2021/10/13","2021/10/15","2021/10/16","2021/10/17","2021/10/18","2021/10/19","2021/10/20","2021/10/21","2021/10/22","2021/10/23","2021/10/24","2021/10/26","2021/10/27","2021/10/28","2021/10/29","2021/10/30","2021/10/31","2021/11/01","2021/11/02","2021/11/03","2021/11/04","2021/11/05","2021/11/06"]
            print(memoTextArray)
            print(memoDateArray)
            memoSearchDateArray = memoDateArray
            memoSearchTextArray = memoTextArray
            tableView.reloadData()
            if(isFirst == true){
                isFirst = false
            }
//            if(isFirst){
//                print("選択しているのは、",selectedDate)
//                if let firstIndex = memoDateArray.index(of: selectedDate) {
//                    print("インデックス番号: \(firstIndex)") // 2
//            var i = 0
//            for memoTextData in memoTextArray {
//                editDateLabel.text = memoDateArray[i]
//                editTextView.text = memoTextData
//
//                i += 1
//            }
                    

//                }
//                else{
//                    editViewDateLabel.text = selectedDate
//                    textView.text = ""
//                    textView.placeHolder = "メモ"
//                }
//                isFirst = false
//            }
            //            //            print("id:\(String(describing: (result[0] as AnyObject).value(forKey: "memoText")!))")
            //                        if let convertedResult = result as? [MemoData] {
            //                            return convertedResult
            //                        }
//            calendar.reloadData()
        } catch {
            print("aiue")
            
        }
        
    }
    func deleteKaraData(deleteDate:String){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let savedPlaceFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "MemoData")
        savedPlaceFetch.predicate = NSPredicate(format: "memoDate = %@", deleteDate)
        do {
            let myResults = try context.fetch(savedPlaceFetch)
            for myData in myResults {
                context.delete(myData as! NSManagedObject)
            }
            
            try context.save()
            getAllPlannerDays()
        } catch let error as NSError {
            print("\(error), \(error.userInfo)")
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UIView.animate(withDuration: 0.3) { [self] in
            
            //            editView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - editView.frame.height, width: editView.frame.width, height: editView.frame.height)
            NSLayoutConstraint.deactivate([normalAutoLayout])
            NSLayoutConstraint.activate([editAutoLayout])
        }
        
        editDateLabel.text = memoSearchDateArray[indexPath.row]
        editTextView.text = memoSearchTextArray[indexPath.row]
        
        selectedDate = String(memoDateArray[indexPath.row])
    }
    
    //追加③ セルの個数を指定するデリゲートメソッド（必須）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return memoSearchTextArray.count
    }
    
    //追加④ セルに値を設定するデータソースメソッド（必須）
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取得する
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        tableView.rowHeight = 73
        //ラベルオブジェクトを作る
        let memoDateLabel = cell.viewWithTag(1) as! UILabel
        //ラベルに表示する文字列を設定
        memoDateLabel.text = memoSearchDateArray[indexPath.row]
        
        
        //ラベルオブジェクトを作る
        let memoTextTextView = cell.viewWithTag(2) as! UILabel
        //ラベルに表示する文字列を設定
        memoTextTextView.text = memoSearchTextArray[indexPath.row]
        
        
        return cell
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        print(textField.text)
        memoSearchDateArray = []
        memoSearchTextArray = []
        
        if(textField.text == ""){
            memoSearchDateArray = memoDateArray
            memoSearchTextArray = memoTextArray
            tableView.reloadData()
                    return
        }
        var i = 0
        for memoText in memoTextArray {
            print(memoText.contains(textField.text!))
            if(memoText.contains(textField.text!)){
                memoSearchTextArray.append(memoText)
                memoSearchDateArray.append(memoDateArray[i])
            }
            i += 1
        }
        
        tableView.reloadData()
       
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        activeTextField = textField
        return true
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        activeTextField = UITextField()
        return true
    }
    
    @objc func commitButtonTapped() {
        self.view.endEditing(true)
    }
    @objc func keyboardWillShow(notification: NSNotification) {
        if(activeTextField.tag != 99){
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                if self.view.frame.origin.y == 0 {
                    self.view.frame.origin.y -= keyboardSize.height
                } else {
                    let suggestionHeight = self.view.frame.origin.y + keyboardSize.height
                    self.view.frame.origin.y -= suggestionHeight
                }
            }
        }
    }
    
    @objc func keyboardWillHide() {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func panAction(_ gesture: UIPanGestureRecognizer) {
        
        
        // Viewをドラッグした量だけ動かす
        let point: CGPoint = gesture.translation(in: self.editView)
        if(self.editView.center.y < self.editView.center.y + point.y){
            UIView.animate(withDuration: 0.3) { [self] in
                NSLayoutConstraint.deactivate([editAutoLayout])
                NSLayoutConstraint.activate([normalAutoLayout])
                //                    editView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height, width: editView.frame.width, height: editView.frame.height)
            }
        }
        //        let movedPoint = CGPoint(x:self.eventBackView.center.x + point.x, y:self.panView.center.y + point.y)
        //        self.panView.center = movedPoint
        
        // ドラッグで移動した距離をリセット
        gesture.setTranslation(CGPoint.zero, in: self.editView)

        
    }
    
}
