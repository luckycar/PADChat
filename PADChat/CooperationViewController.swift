//
//  CooperationViewController.swift
//  PADChat
//
//  Created by KuanHaoChen on 2016/8/30.
//  Copyright © 2016年 KuanHaoChen. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class CooperationViewController: UIViewController , UITextFieldDelegate , UITextViewDelegate {
    
    var roomLab:UILabel! //房號
    var roomTextF:UITextField! //房號輸入框
    var roomBtn:UIButton = UIButton(type: UIButtonType.System) //房號貼上按鈕
    var contentLab:UILabel! //內容
    var contentTextV:UITextView! //內容輸入框
    var contentBtn:UIButton = UIButton(type: UIButtonType.System) //訊息發送按鈕
    
    var userName:String? //使用者暱稱
    var date:String! //日期時間
    //Firebase相關
    var databaseRef:FIRDatabaseReference?
    var uid:String?
    
    func refreshWithFrame(frame:CGRect) {
        self.view.frame = frame
        self.view.backgroundColor = UIColor.whiteColor()
        
        let frameW:CGFloat = frame.size.width
        let frameH:CGFloat = frame.size.height
        
        //房號
        roomLab = UILabel(frame: CGRectMake(frameW / 5, frameH * 3 / 20, frameW / 5, frameH / 20))
        roomLab.text = "房間號碼:"
        roomLab.textAlignment = NSTextAlignment.Center
        roomLab.font = UIFont.boldSystemFontOfSize(roomLab.frame.size.height * 0.5)
        self.view.addSubview(roomLab)
        
        //房號輸入框
        roomTextF = UITextField(frame: CGRectMake(frameW * 2 / 5, frameH * 3 / 20, frameW * 2 / 5, frameH / 20))
        roomTextF.font = UIFont.boldSystemFontOfSize(roomTextF.frame.size.height * 0.5)
        roomTextF.textColor = UIColor.blueColor()
        roomTextF.backgroundColor = UIColor.lightGrayColor()
        roomTextF.textAlignment = NSTextAlignment.Left
        roomTextF.layer.borderWidth = 1
        roomTextF.clearButtonMode = UITextFieldViewMode.WhileEditing //叉號，編輯時出現
        roomTextF.keyboardType = UIKeyboardType.NumberPad
        roomTextF.delegate = self
        self.view.addSubview(roomTextF)
        
        //偵測手指點擊
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.hideKeyBoard(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        //貼上按鈕
        roomBtn = UIButton(frame: CGRectMake(0, frameH * 4 / 20, frameW / 5, frameH / 20))
        roomBtn.center.x = frame.size.width / 2
        roomBtn.setTitle("貼上房號", forState: UIControlState.Normal)
        roomBtn.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
        roomBtn.addTarget(self, action: #selector(CooperationViewController.onButtonAction(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(roomBtn)
        
        //內容
        contentLab = UILabel(frame: CGRectMake(frameW / 5, frameH * 5 / 20, frameW / 5, frameH / 20))
        contentLab.text = "招募內容:"
        contentLab.textAlignment = NSTextAlignment.Center
        contentLab.font = UIFont.boldSystemFontOfSize(roomLab.frame.size.height * 0.5)
        self.view.addSubview(contentLab)
        
        //內容輸入欄
        contentTextV = UITextView(frame: CGRectMake(frameW * 1 / 5, frameH * 6 / 20, frameW * 3 / 5, frameH * 5 / 20))
        contentTextV.font = UIFont.boldSystemFontOfSize(contentTextV.frame.size.height * 0.15)
        contentTextV.backgroundColor = UIColor.lightGrayColor()
        contentTextV.autocapitalizationType = UITextAutocapitalizationType.None
        contentTextV.layer.borderWidth = 1
        contentTextV.returnKeyType = UIReturnKeyType.Default
        contentTextV.delegate = self
        self.view.addSubview(contentTextV)
        
        //發送按鈕
        contentBtn = UIButton(frame: CGRectMake(0, frameH * 11 / 20, frameW / 5, frameH / 20))
        contentBtn.center.x = frame.size.width / 2
        contentBtn.setTitle("發送訊息", forState: UIControlState.Normal)
        contentBtn.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
        contentBtn.addTarget(self, action: #selector(CooperationViewController.onButtonAction(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(contentBtn)
        
    }
    
    // MARK: - Override
    //------------------------------------------------------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //畫面不旋轉
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    //畫面返回
    override func willMoveToParentViewController(parent: UIViewController?) {
        if parent == nil {
            self.clean()
        }
    }
    
    // MARK: - CallBack & Lestener
    //------------------------------------------------------------------------------------------------------------------------
    
    //點擊空白，隱藏鍵盤
    func hideKeyBoard(tapG:UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    //按鈕點擊
    func onButtonAction(sender:UIButton) {
        switch sender {
        case roomBtn:
            roomTextF.text = UIPasteboard.generalPasteboard().string //貼上複製的文字
            break
        case contentBtn:
            addData(userName! + contentTextV.text + " " + roomTextF.text!)
            self.clean()
            self.navigationController?.popViewControllerAnimated(true)
            break
        default:
            break
        }
    }
    
    //自定義的文字大小
    func sizeOfString (string: String, constrainedToWidth width: Double, font: UIFont) -> CGSize {
        return (string as NSString).boundingRectWithSize(CGSize(width: width, height: DBL_MAX),options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil).size
    }
    
    //清空文字
    func clean() {
        roomTextF.text = ""
        contentTextV.text = ""
    }
    
    //上傳資料到Firebase
    func addData(sender:String) {
        
        let d:ViewController = ViewController()
        
        date = d.getDate()
        
        let addData = ["message":sender , "isCooper":"yes" , "number":roomTextF.text!]
        databaseRef!.child(date + uid!).setValue(addData)
    }
    
    // MARK: - Delegate
    //------------------------------------------------------------------------------------------------------------------------
    
    //限制輸入最大字數
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else {return true }
        let newLength = text.utf16.count + string.utf16.count - range.length
        return newLength <= 8
    }
    
    //限制行數
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).stringByReplacingCharactersInRange(range, withString: text)
        var textWidth = CGRectGetWidth(UIEdgeInsetsInsetRect(textView.frame, textView.textContainerInset))
        textWidth -= 2.0 * textView.textContainer.lineFragmentPadding;
        
        let boundingRect = sizeOfString(newText, constrainedToWidth: Double(textWidth), font: textView.font!)
        let numberOfLines = boundingRect.height / textView.font!.lineHeight;
        
        return numberOfLines <= 5
    }
    
}
