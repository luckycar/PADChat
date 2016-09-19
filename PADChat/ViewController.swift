//
//  ViewController.swift
//  PADChat
//
//  Created by KuanHaoChen on 2016/9/3.
//  Copyright © 2016年 KuanHaoChen. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

//記錄聊天內容的類別
struct FireData {
    
    var message:String!
    var itemRef:FIRDatabaseReference?
    var isCooper:String = ""
    var roomNumber:String = ""
    var isUrl:Bool = false
    var localTime:String = ""
    
    init (message:String) {
        self.message = message
        self.itemRef = nil
    }
    
    init (snapshot:FIRDataSnapshot) {
        itemRef = snapshot.ref
        
        if let mess = snapshot.value!["message"] as? String {
            message = mess
        } else {
            message = ""
        }
        
        if let cooper = snapshot.value!["isCooper"] as? String {
            isCooper = cooper
        } else {
            isCooper = ""
        }
        
        if let num = snapshot.value!["number"] as? String {
            roomNumber = num
        } else {
            roomNumber = ""
        }
    }
    
    func getData() -> AnyObject {
        return ["message":message]
    }
}

class ViewController: UIViewController , UITextFieldDelegate , UIAlertViewDelegate , UICollectionViewDelegateFlowLayout , UICollectionViewDataSource , GADBannerViewDelegate {
    
    //銀幕尺寸
    var fullScreenSize :CGSize = UIScreen.mainScreen().bounds.size
    
    //狀態欄與導覽列的高度
    let naviHeight = UIApplication.sharedApplication().statusBarFrame.size.height + UINavigationController().navigationBar.frame.height
    
    var isJapan:Bool = true //判斷台日版
    var userDefaults:NSUserDefaults! //存取本機記錄
    var cooperat:CooperationViewController? //協力畫面
    var userName:String = "" //使用者暱稱
    var m_writeText:UITextField! //聊天輸入欄
    var myCollectionView:UICollectionView! //聊天欄滾軸
    var fireData = [FireData]() //記錄訊息
    var url:String = "" //網址
    let databaseRef = FIRDatabase.database().reference().child("PADChat") //FirebaseDatabase連結
    var uid:String! //Firebase帳戶
    var m_GADBannerView:GADBannerView! //廣告
    
    func refreshWithFrame(frame:CGRect) {
        self.view.frame = frame
        self.view.backgroundColor = UIColor.lightGrayColor()
        
        self.navigationItem.title = "聊天頁面"
        
        //導覽列左右按鈕
        let m_leftBtnItem:UIBarButtonItem = UIBarButtonItem(title: "設置版本", style: UIBarButtonItemStyle.Done, target: self, action: #selector(ViewController.onSelectLeftAction(_:)))
        let m_rightBtnItem = UIBarButtonItem(title: "協力招募", style: UIBarButtonItemStyle.Done, target: self, action: #selector(ViewController.onSelectRightAction(_:)))
        self.navigationItem.setLeftBarButtonItem(m_leftBtnItem, animated: false)
        self.navigationItem.setRightBarButtonItem(m_rightBtnItem, animated: false)
        
        //取得記錄在本機的資料
        userDefaults = NSUserDefaults.standardUserDefaults()
        if let japan = userDefaults.objectForKey("bool") as? Bool {
            isJapan = japan
        }
        
        //聊天訊息輸入框
        m_writeText = UITextField()
        m_writeText.frame = CGRectMake(0, naviHeight, self.view.frame.size.width, 35)
        m_writeText.font = UIFont.systemFontOfSize(m_writeText.frame.size.height * 0.6)
        m_writeText.textAlignment = NSTextAlignment.Left
        m_writeText.textColor = UIColor.blackColor()
        m_writeText.backgroundColor = UIColor.whiteColor()
        m_writeText.autocapitalizationType = UITextAutocapitalizationType.None //輸入時首字不大寫
        m_writeText.returnKeyType = UIReturnKeyType.Send
        m_writeText.delegate = self
        m_writeText.layer.borderWidth = 1 //邊框寬度
        //m_writeText.layer.borderColor = UIColor.lightGrayColor().CGColor //邊框顏色
        m_writeText.clearButtonMode = UITextFieldViewMode.WhileEditing //叉號，編輯時出現
        m_writeText.addTarget(self, action: #selector(ViewController.onTextFieldAction(_:)), forControlEvents: UIControlEvents.TouchDown)
        self.view.addSubview(m_writeText)
        
        //偵測手指點擊
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.hideKeyBoard(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        // 建立 UICollectionViewFlowLayout 表格尺寸
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0) // 設置 section 的間距 四個數值分別代表 上、左、下、右 的間距
        layout.minimumLineSpacing = 0 // 設置每一行的間距
        
        // 建立 UICollectionView 聊天表格
        myCollectionView = UICollectionView(frame: CGRect(x: 0, y: naviHeight + m_writeText.frame.size.height, width: fullScreenSize.width, height: fullScreenSize.height - (naviHeight + m_writeText.frame.size.height)), collectionViewLayout: layout)
        myCollectionView.backgroundColor = UIColor.whiteColor()
        // 設置委任對象
        myCollectionView.delegate = self
        myCollectionView.dataSource = self
        self.view.addSubview(myCollectionView)
        
        //Firebase帳戶
        FIRAuth.auth()?.signInAnonymouslyWithCompletion({ (user, error) in
            self.uid = user?.uid
        })
        
        //生成GoogleAd
        m_GADBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        m_GADBannerView.frame = CGRectOffset(m_GADBannerView.frame, 0, self.view.frame.size.height) //預設隱藏
        m_GADBannerView.adUnitID = "ca-app-pub-3375480460538981/3797222554" //廣告單元編號
        m_GADBannerView.rootViewController = self //點擊廣告後彈出全畫面廣告，不加會當
        m_GADBannerView.delegate = self
        self.view.addSubview(m_GADBannerView)
        m_GADBannerView.loadRequest(GADRequest()) //發送ID請求廣告回傳上載
        self.view.bringSubviewToFront(m_GADBannerView)
        
    }
    
    
    
    // MARK: - Override
    //------------------------------------------------------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        startObservingDB()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //畫面不旋轉
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    // MARK: - CallBack & Lestener
    //------------------------------------------------------------------------------------------------------------------------
    
    //導覽列左邊按鈕
    func onSelectLeftAction(sender:UIBarButtonItem){
        let selectLeftAlert = UIAlertController(title: "PAD版本", message: "請選擇協力開啟的版本", preferredStyle: .Alert)
        let taiwan = UIAlertAction(title: "港台版", style: .Cancel) { (UIAlertAction) in
            self.isJapan = false
            self.setData()
        }
        selectLeftAlert.addAction(taiwan)
        let japan = UIAlertAction(title: "日版", style: .Default) { (UIAlertAction) in
            self.isJapan = true
            self.setData()
        }
        selectLeftAlert.addAction(japan)
        self.presentViewController(selectLeftAlert, animated: true, completion: nil)
    }
    
    //導覽列右邊按鈕
    func onSelectRightAction(sender:UIBarButtonItem){
        if userName == "" {
            let nameAlert = UIAlertController(title: "請輸入暱稱", message: "", preferredStyle: .Alert)
            nameAlert.addTextFieldWithConfigurationHandler({ (text:UITextField!) in
                
            })
            let cancelAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
            nameAlert.addAction(cancelAction)
            let okAction = UIAlertAction(title: "確認", style: .Default, handler: { (action:UIAlertAction!) in
                let text = (nameAlert.textFields?.first)! as UITextField
                if text.text != "" {
                    self.userName = text.text! + " : "
                    self.makeCooperate()
                } else {
                    self.view.endEditing(true)
                }
            })
            nameAlert.addAction(okAction)
            self.presentViewController(nameAlert, animated: true, completion: nil)
        }
        
        makeCooperate()
        
    }
    
    //協力畫面
    func makeCooperate() {
        if cooperat == nil {
            cooperat = CooperationViewController()
            cooperat?.refreshWithFrame(self.view.frame)
        }
        cooperat?.userName = self.userName
        cooperat?.uid = self.uid
        cooperat?.databaseRef = self.databaseRef
        self.navigationController?.pushViewController(cooperat!, animated: true)
    }
    
    //將資料記錄於本機
    func setData() {
        userDefaults.setObject(isJapan, forKey: "bool")
        userDefaults.synchronize()
    }
    
    //點擊輸入欄的委任
    func onTextFieldAction(textField:UITextField) {
        if userName == "" {
            let nameAlert = UIAlertController(title: "請輸入暱稱", message: "", preferredStyle: .Alert)
            nameAlert.addTextFieldWithConfigurationHandler({ (text:UITextField!) in
                text.returnKeyType = UIReturnKeyType.Send
            })
            let cancelAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
            nameAlert.addAction(cancelAction)
            let okAction = UIAlertAction(title: "確認", style: .Default, handler: { (action:UIAlertAction!) in
                let text = (nameAlert.textFields?.first)! as UITextField
                if text.text != "" {
                    self.userName = text.text! + " : "
                    self.m_writeText.becomeFirstResponder()
                } else {
                    self.view.endEditing(true)
                }
            })
            nameAlert.addAction(okAction)
            self.presentViewController(nameAlert, animated: true, completion: nil)
        }
    }
    
    //點擊空白，隱藏鍵盤
    func hideKeyBoard(tapG:UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    //生成Label text 一段文字(長短不拘) font 文字大小
    func makeLabel(text:NSString , font:UIFont) -> UILabel {
        let label:UILabel = UILabel()
        label.text = text as String
        label.font = font
        label.textColor = UIColor.blackColor()
        label.backgroundColor = UIColor.clearColor()
        label.textAlignment = .Left
        label.numberOfLines = 0 //標簽行數系統預設為1行，設為0行，可以自動換行
        label.lineBreakMode = .ByWordWrapping
        resizeLabel(label)
        return label
    }
    
    //依照文字大小，動態設定標簽大小
    func resizeLabel(label:UILabel) {
        let text:NSString = label.text!
        let attributes:NSDictionary = [NSFontAttributeName:label.font] //將font包裝成辭典物件供格式化
        let maximumLabelSize:CGSize = CGSizeMake(fullScreenSize.width - 20, CGFloat(MAXFLOAT))
        // MAXFLOAT 最大float = 無限
        let textRect:CGRect = text.boundingRectWithSize(maximumLabelSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: attributes as? [String:AnyObject], context: nil) //產生一個剛好可以裝載全部文字的容量
        label.frame.size = textRect.size
    }
    
    //上傳資料到Firebase
    func addData(sender:String) {
        
        let date = getDate()
        
        let addData = FireData(message: sender)
        databaseRef.child(date + uid).setValue(addData.getData())
    }
    
    //取得日期時間
    func getDate() -> String {
        let nowdate = NSDate() //取得使用者當地時間
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0) //將當地時間轉換成GMT0的時間，並加上秒數，台灣時間要加上8*60*60
        let date = formatter.stringFromDate(nowdate)
        return date
    }
    
    //讀取Firebase資料
    func startObservingDB() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        databaseRef.observeEventType(FIRDataEventType.Value) { (snapshot:FIRDataSnapshot) in
            var newFireData = [FireData]()
            
            for data in snapshot.children {
                let dataObject = FireData(snapshot: data as! FIRDataSnapshot)
                newFireData.append(dataObject)
            }
            
            self.fireData = newFireData
            self.myCollectionView.reloadData()
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
    
    //取得網址
    func getURL(str:String) -> Bool {
        do {
            let dataDetector = try NSDataDetector(types: NSTextCheckingTypes(NSTextCheckingType.Link.rawValue))
            let res = dataDetector.matchesInString(str, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, str.characters.count))
            for checkingRes in res {
                url = (str as NSString).substringWithRange(checkingRes.range)
            }
            return url == "" ? false : true
        }
        catch {
            print(error)
            return false
        }
    }
    
    //清空
    func clean() {
        self.url = ""
    }
    
    //開啟網站
    func openURL(url:String) {
        
        if !(url.lowercaseString.hasPrefix("http://")) {
            self.url = "http://" + url
        }
        
        let targetURL = NSURL(string: self.url)
        
        let application = UIApplication.sharedApplication()
        application.openURL(targetURL!)
    }
    
    //廣告讀取成功或失敗的顯示與否
    func showAdBanner(isShow:Bool) {
        UIView.beginAnimations("", context: nil)
        myCollectionView.frame.size.height = fullScreenSize.height - (naviHeight + m_writeText.frame.size.height) - ( isShow ? m_GADBannerView.frame.size.height : 0 )
        m_GADBannerView.frame.origin.y = self.view.frame.size.height - ( isShow ? m_GADBannerView.frame.size.height : 0 )
        UIView.commitAnimations()
    }
    
    // MARK: - Delegate
    //------------------------------------------------------------------------------------------------------------------------
    
    //按下鍵盤return鍵
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if m_writeText.text == "" {
            self.view.endEditing(true)
            return false
        }
        addData(userName + textField.text!)
        m_writeText.text = ""
        self.view.endEditing(true)
        return true
    }
    
    // 必須實作的方法：每一組有幾個 cell
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    // 必須實作的方法：每個 cell 要顯示的內容
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        if fireData.count > 100 {
            let dataDel = fireData[0]
            dataDel.itemRef?.removeValue()
        }
        
        // 註冊 cell 以供後續重複使用
        myCollectionView.registerClass(MyCollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        // 依據前面註冊設置的識別名稱 "Cell" 取得目前使用的 cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! MyCollectionViewCell
        // 設置 cell 內容 (即自定義元件裡 增加文字元件)
        cell.titleLabel.text = fireData[fireData.count - indexPath.section - 1].message
        
        //判斷網址
        fireData[fireData.count - indexPath.section - 1].isUrl = getURL(fireData[fireData.count - indexPath.section - 1].message)
        
        //清空
        self.clean()
        
        //判斷協力及網址
        if fireData[fireData.count - indexPath.section - 1].isCooper == "yes" {
            cell.titleLabel.textColor = UIColor.blueColor()
        } else if fireData[fireData.count - indexPath.section - 1].isUrl == true {
            cell.titleLabel.textColor = UIColor.orangeColor()
        } else {
            cell.titleLabel.textColor = UIColor.blackColor()
        }
        
        cell.titleLabel.frame.origin.x = 10
        cell.resizeLabel(cell.titleLabel)
        
        return cell
    }
    
    // 設置每個 cell 的尺寸
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let lab:UILabel = makeLabel(fireData[fireData.count - indexPath.section - 1].message, font: UIFont.boldSystemFontOfSize((fullScreenSize.height - naviHeight - 35) * 9 / 200 ))
        return CGSizeMake(fullScreenSize.width, lab.frame.size.height)
    }
    
    // 有幾個 section
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return fireData.count <= 100 ? fireData.count : 100
    }
    
    // 點選 cell 後執行的動作
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        //判斷協力及網址
        if fireData[fireData.count - indexPath.section - 1].isCooper == "yes" {
            UIPasteboard.generalPasteboard().string = fireData[fireData.count - indexPath.section - 1].roomNumber
            if isJapan {
                UIApplication.sharedApplication().openURL(NSURL(string: "puzzleanddragons://")!)
            } else {
                UIApplication.sharedApplication().openURL(NSURL(string: "puzzleanddragonsht://")!)
            }
        } else if getURL(fireData[fireData.count - indexPath.section - 1].message) {
            openURL(url)
            self.clean()
        } else {
            
        }
    }
    
    //Google廣告
    func adViewDidReceiveAd(bannerView: GADBannerView!) {
        //收到廣告
        print("Google收到廣告")
        self.showAdBanner(true)
    }
    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        //接收廣告發生錯誤
        print("Google接收廣告失敗")
        self.showAdBanner(false)
    }
    func adViewWillPresentScreen(bannerView: GADBannerView!) {
        //點選啟動廣告
        print("點擊廣告")
    }
    func adViewWillDismissScreen(bannerView: GADBannerView!) {
        //關閉廣告視窗
        print("關閉廣告視窗")
    }
    func adViewWillLeaveApplication(bannerView: GADBannerView!) {
        //離開應用程式
        print("廣告點擊造成使用者離開應用程式")
    }
    
    
}

//UICollectionViewCell的類別

class MyCollectionViewCell: UICollectionViewCell {
    
    //狀態欄與導覽列的高度
    let naviHeight = UIApplication.sharedApplication().statusBarFrame.size.height + UINavigationController().navigationBar.frame.height
    
    // 取得螢幕尺寸
    let size = UIScreen.mainScreen().bounds.size
    
    var titleLabel:UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // 建立一個 UILabel
        titleLabel = makeLabel("", font: UIFont.boldSystemFontOfSize((size.height - naviHeight - 35) * 9 / 200 ))
        titleLabel.frame.origin.y = 0
        self.addSubview(titleLabel)
    }
    
    //生成Label text 一段文字(長短不拘) font 文字大小
    func makeLabel(text:NSString , font:UIFont) -> UILabel {
        let label:UILabel = UILabel()
        label.text = text as String
        label.font = font
        label.textColor = UIColor.blackColor()
        label.backgroundColor = UIColor.clearColor()
        label.textAlignment = .Left
        label.numberOfLines = 0 //標簽行數系統預設為1行，設為0行，可以自動換行
        label.lineBreakMode = .ByWordWrapping
        resizeLabel(label)
        return label
    }
    
    //依照文字大小，動態設定標簽大小
    func resizeLabel(label:UILabel) {
        let text:NSString = label.text!
        let attributes:NSDictionary = [NSFontAttributeName:label.font] //將font包裝成辭典物件供格式化
        let maximumLabelSize:CGSize = CGSizeMake(size.width - 20, CGFloat(MAXFLOAT))
        // MAXFLOAT 最大float = 無限
        let textRect:CGRect = text.boundingRectWithSize(maximumLabelSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: attributes as? [String:AnyObject], context: nil) //產生一個剛好可以裝載全部文字的容量
        label.frame.size = textRect.size
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
