//
//  ViewController.swift
//  EveryDayMemo
//
//  Created by 加藤周 on 2021/08/28.
//



//通知の文章を工夫する
//セリフ風に



import UIKit
import FSCalendar
import CoreData
import GoogleMobileAds
import UserNotifications

class ViewController: UIViewController, FSCalendarDataSource, FSCalendarDelegate, FSCalendarDelegateAppearance, UITextViewDelegate {
    // storyboardから繋いであるFSCalendar
    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet var eventBackView :UIView!
    @IBOutlet var editViewDateLabel : UILabel!
    @IBOutlet var textView : PlaceHolderTextView!
    
    var memoTextArray:[String] = []
    var memoDateArray:[String] = []
    
    var selectedDate : String!
    
    var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier:  "Asia/Tokyo")
        return formatter
    }()
    @IBOutlet var bannerView : GADBannerView!
    
    var isFirst = true
    var startDate : String!
    //    var memoDateArray = ["2021/08/03","2021/08/13"]
    override func viewDidLoad() {
        super.viewDidLoad()
        //        let center = UNUserNotificationCenter.current()
        //        center.getPendingNotificationRequests(completionHandler: { requests in
        //            for request in requests {
        //                print("通知だ",request)
        //            }
        //        })
        
        
        
        //        UserDefaults.standard.set("2021/08/05", forKey: "StartDate")
        if UserDefaults.standard.string(forKey: "StartDate") != nil {
            startDate = UserDefaults.standard.string(forKey: "StartDate")
        }else{
            //初めての起動
            UserDefaults.standard.set(formatter.string(from: Date()), forKey: "StartDate")
            startDate = formatter.string(from: Date())
        }
        
        isFirst = true
        
        bannerView.adUnitID = "ca-app-pub-7890542862997264/1044340661"
        bannerView.rootViewController = self
//        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = ["2b322f01a7f7bb8922a509a2840726a1"]
        bannerView.load(GADRequest())
        
        
        
        //        eventBackView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height, width: eventBackView.frame.width, height: eventBackView.frame.height)
        //panViewをパンジェスチャー（ドラッグ）で動かせるように
        //        let panGesture = UIPanGestureRecognizer()
        //        panGesture.addTarget(self, action: #selector(panAction(_:)))
        //        eventBackView.addGestureRecognizer(panGesture)
        //                deleteAllData()
        selectedDate = formatter.string(from: Date())
        
        
        
        print("今日は、",formatter.string(from: Date()))
        // calendarの色の設定
        calendar.dataSource = self
        calendar.delegate = self
        //        calendar.placeholderType = .none
        
        
        textView.delegate = self
        //        // ツールバー生成
        //        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 40))
        //        // スタイルを設定
        //        toolBar.barStyle = UIBarStyle.default
        //        // 画面幅に合わせてサイズを変更
        //        toolBar.sizeToFit()
        //        // 閉じるボタンを右に配置するためのスペース?
        //        let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        //        // 閉じるボタン
        //        let commitButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(commitButtonTapped))
        //        // スペース、閉じるボタンを右側に配置
        //        toolBar.items = [spacer, commitButton]
        //        // textViewのキーボードにツールバーを設定
        //        textView.inputAccessoryView = toolBar
        let custombar = UIView(frame: CGRect(x:0, y:0,width:(UIScreen.main.bounds.size.width),height:40))
        custombar.backgroundColor = UIColor.groupTableViewBackground
        let commitBtn = UIButton(frame: CGRect(x:(UIScreen.main.bounds.size.width)-100,y:0,width:100,height:40))
        commitBtn.setTitle("保存", for: .normal)
        commitBtn.setTitleColor(UIColor.blue, for:.normal)
        commitBtn.addTarget(self, action:#selector(ViewController.commitButtonTapped), for: .touchUpInside)
        custombar.addSubview(commitBtn)
        textView.inputAccessoryView = custombar
        textView.placeHolder = "メモ"
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        
        
        
        
        
        eventBackView.layer.cornerRadius = 30.0
        eventBackView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        
        getAllPlannerDays()
        
        
        //
    }
    func createNotification(){
        
        print("２回呼ばれてるやろ")
        UNUserNotificationCenter.current().removeAllDeliveredNotifications() // For removing all delivered notification
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests() // For removing all pending notifications which are not delivered yet but scheduled.
        
        for i in 0..<14 {
            print("forは、",i)
            //今日(0日)〜13日後までをセットする
            let nitigoDay = Calendar.current.date(byAdding: .day, value: i, to: Date())!
            
            if let firstIndex = memoDateArray.firstIndex(of: formatter.string(from: nitigoDay)) {
                //既にメモが書かれている
                print("\(i)日後の\(nitigoDay)は、既にメモが書かれています☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆")
            }else{
                //まだメモが書かれていないから通知を設定
                print("\(i)日後は、\(nitigoDay)")
                for o in 19..<22 {
                    //19時、20時、21時にセット
                    
                    let current = Calendar.current
                    var month = current.component(.month, from: nitigoDay)
                    var day = current.component(.day, from: nitigoDay)
                    
                    var id = formatter.string(from: nitigoDay) + "/\(o):00"
                    
                    setNotification(notificationID:id, monthInt:month, dayInt:day, hourInt: o)
                }
            }
            
        }
    }
    func setNotification(notificationID:String,monthInt:Int,dayInt:Int,hourInt:Int){
        var bodyContent = ["寝る前にメモを入力してって言ったでしょ！","毎日欠かさずメモすることが大事なのよ","今日はいい天気だった？メモ書いてから寝てね！","私の目は誤魔化せないわよ！ちゃんとメモ書いてから寝なさい！","え、私の口癖？「メモ書きなさい」かな。","私に言われなくてもメモ書けるでしょ？？","メモ書かないとお小遣い減らすからね！","「You have to write a Memo.」意味わかる？メモを書きなさいってことよ。","メモを今すぐ書くって約束できる？","メモを書いたら、お菓子食べていいわよ。","お仕事お疲れ様！メモ書いてね！","メモを毎日続けると、将来役に立つわよ！","何で私がこんなにうるさいのかって？メモを書いて欲しいからよ。","メモを書いていない人は明日遊びに連れて行きません！すぐに書きなさい！"]
        let content = UNMutableNotificationContent()
        content.title = ""
        content.body = bodyContent.randomElement()!
        
        content.sound = UNNotificationSound.default
        if let path = Bundle.main.path(forResource: "mam", ofType: "png") {
            content.attachments = [try! UNNotificationAttachment(identifier: notificationID + "Image", url: URL(fileURLWithPath: path), options: nil)]
        }
        
        // 直接日時を設定
        let triggerDate = DateComponents(month:monthInt, day:dayInt, hour:hourInt, minute:00, second: 00)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
//        print(content.body)
        print("通知をセットしました。ID：\(notificationID)　　日付：\(triggerDate)")
        // 直ぐに通知を表示
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        print("calendar did select date \(self.formatter.string(from: date))")
        
        selectedDate = formatter.string(from: date)
        print("選択しているのは、",selectedDate)
        if let firstIndex = memoDateArray.index(of: selectedDate) {
            print("インデックス番号: \(firstIndex)") // 2
            editViewDateLabel.text = selectedDate
            textView.text = memoTextArray[firstIndex]
            textView.placeHolder = ""
        }else{
            editViewDateLabel.text = selectedDate
            textView.text = ""
            textView.placeHolder = "メモ"
        }
        
        
        if monthPosition == .previous || monthPosition == .next {
            calendar.setCurrentPage(date, animated: true)
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if(selectedDate != nil){
            //                        saveData()
            changeData()
            
            
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("呼ばれた")
    }
    
    
    func saveData(){
        
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "MemoData", in: context)!
        let ent_name = NSManagedObject(entity: entity, insertInto: context)
        
        ent_name.setValue(textView.text, forKeyPath: "memoText")
        ent_name.setValue(selectedDate, forKeyPath: "memoDate")
        
        do {
            try context.save()
            getAllPlannerDays()
        } catch let error as NSError {
            print("\(error), \(error.userInfo)")
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
                myData.setValue(textView.text, forKeyPath: "memoText")
                
            }
            if(isChange == false){
                print("新規なので追加します。")
                saveData()
            }
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
    func deleteAllData(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let savedPlaceFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "MemoData")
        do {
            let myResults = try context.fetch(savedPlaceFetch)
            for myData in myResults {
                context.delete(myData as! NSManagedObject)
            }
            
            try context.save()
        } catch let error as NSError {
            print("\(error), \(error.userInfo)")
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
    func getAllPlannerDays(){
        memoTextArray = []
        memoDateArray = []
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let savedPlaceFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "MemoData")
        // ソートを追加
        //        savedPlaceFetch.sortDescriptors = [
        //            NSSortDescriptor(key: "memoDate", ascending: true)
        //        ]
        do {
            let result = try context.fetch(savedPlaceFetch)
            print("aiu",result)
            for myData in result {
                if((myData as AnyObject).value(forKey: "memoText") as! String == ""){
                    print("空だから削除します",(myData as AnyObject).value(forKey: "memoDate") as! String)
                    deleteKaraData(deleteDate: (myData as AnyObject).value(forKey: "memoDate") as! String)
                }else{
                    memoTextArray.append((myData as AnyObject).value(forKey: "memoText") as! String)
                    memoDateArray.append((myData as AnyObject).value(forKey: "memoDate") as! String)
                }
            }
            
            print(memoTextArray)
            print(memoDateArray)
            if(isFirst){
                print("選択しているのは、",selectedDate)
                if let firstIndex = memoDateArray.index(of: selectedDate) {
                    print("インデックス番号: \(firstIndex)") // 2
                    editViewDateLabel.text = selectedDate
                    textView.text = memoTextArray[firstIndex]
                    textView.placeHolder = ""
                }else{
                    editViewDateLabel.text = selectedDate
                    textView.text = ""
                    textView.placeHolder = "メモ"
                }
                isFirst = false
            }
            //            //            print("id:\(String(describing: (result[0] as AnyObject).value(forKey: "memoText")!))")
            //                        if let convertedResult = result as? [MemoData] {
            //                            return convertedResult
            //                        }
            
            calendar.reloadData()
            createNotification()
        } catch {
            print("aiue")
            
        }
        
    }
    
    //    @objc func panAction(_ gesture: UIPanGestureRecognizer) {
    //
    //
    //        // Viewをドラッグした量だけ動かす
    //        let point: CGPoint = gesture.translation(in: self.eventBackView)
    //        if(self.eventBackView.center.y < self.eventBackView.center.y + point.y){
    //            UIView.animate(withDuration: 0.3) { [self] in
    //
    //                eventBackView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height, width: eventBackView.frame.width, height: eventBackView.frame.height)
    //            }
    //        }
    ////        let movedPoint = CGPoint(x:self.eventBackView.center.x + point.x, y:self.panView.center.y + point.y)
    ////        self.panView.center = movedPoint
    //
    //        // ドラッグで移動した距離をリセット
    //        gesture.setTranslation(CGPoint.zero, in: self.eventBackView)
    //
    //    }
    @objc func commitButtonTapped() {
        self.view.endEditing(true)
    }
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            } else {
                let suggestionHeight = self.view.frame.origin.y + keyboardSize.height
                self.view.frame.origin.y -= suggestionHeight
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
    //    背景色をつける
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor? {
        let key = self.formatter.string(from: date)
        //            print(key)
        
        if self.memoDateArray.contains(key){
            //            return UIColor(red: 89/255, green: 149/255, blue: 139/255, alpha: 1.0)
            return nil
        }else{
            if(key < startDate || key > self.formatter.string(from: Date())){//
                return nil
            }else{
                return UIColor(red: 253/255, green: 120/255, blue: 88/255, alpha: 1.0)
            }
        }
        
    }
    
    //画像をつける関数
    func calendar(_ calendar: FSCalendar, imageFor date: Date) -> UIImage? {
        let key = self.formatter.string(from: date)
        
        var context = ""
        if let firstIndex = memoDateArray.index(of: key) {
            context = memoTextArray[firstIndex]
        }
        if self.memoDateArray.contains(key) && context != ""{
            let perfect = UIImage(named: "check.png")
            let Resize:CGSize = CGSize.init(width: 30, height: 30) // サイズ指定
            let perfectResize = perfect?.resize(size: Resize)
            return perfectResize
        }
        return nil
    }
    
    //文字色
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        let key = self.formatter.string(from: date)
        if(key < startDate){
            return UIColor.lightGray
        }else if(key == self.formatter.string(from: Date())){
            return UIColor.white
        }else{
            return UIColor.black
        }
        
    }
    
    
    //            func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
    //                let dateString = formatter.string(from: date)
    //                if self.memoDateArray.contains(dateString){
    //                    return 1
    //                }
    //                return 0
    //            }
    
    //        点をつける
    //                    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, eventDefaultColorsFor date: Date) -> [UIColor]? {
    //                        let key = self.formatter.string(from: date)
    //                        if self.memoDateArray.contains(key){
    //                            return [UIColor.blue]
    //                        }
    //                        return nil
    //                    }
    
}

// UIImageのリサイズ
extension UIImage {
    func resize(size _size: CGSize) -> UIImage? {
        let widthRatio = _size.width / size.width
        let heightRatio = _size.height / size.height
        let ratio = widthRatio < heightRatio ? widthRatio : heightRatio
        
        let resizedSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(resizedSize, false, 0.0) // 変更
        draw(in: CGRect(origin: .zero, size: resizedSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
}
