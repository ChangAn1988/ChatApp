//
//  ViewController.swift
//  ChatApp
//
//  Created by 陳昶安 on 2017/3/25.
//  Copyright © 2017年 ANAN. All rights reserved.
//

import UIKit
import SwiftR

class ChatRoomVC: UIViewController {

    @IBOutlet weak var textFieldMessage: UITextField!
    @IBOutlet weak var textFieldName: UITextField!
    @IBOutlet weak var textViewChatContent: UITextView!
    @IBOutlet weak var btnSendMessage: UIButton!
    
    //For SwiftR
    fileprivate var chatHub:Hub!
    fileprivate var connection:SignalR!
    
    //For keyboard
    fileprivate var isKeyboardShow = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setSwiftR()
        setChatHub()
        setConnectionEvents()
        addTapEvent()
        addObservers()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func btnSendMessageAction(_ sender: UIButton) {
        
        if let hub = chatHub,
           let name = textFieldName.text,
            let message = textFieldMessage.text {
            
            try? hub.invoke("send", arguments: [name, message])
            
//            do {
//                try hub.invoke("send", arguments: [name, message], callback: nil)
//            } catch  {
//                print(error)
//            }
            
            //print("name:\(name)\nmessage:\(message)")
//            self.textViewChatContent.text = self.textViewChatContent.text + "\n\(name) : \(message)\n"
            
        }
        textFieldMessage.text = ""
        view.endEditing(true)
    }
    
    //點擊手勢收鍵盤
    fileprivate func addTapEvent() {
        
        let tap = UITapGestureRecognizer(target: self, action:
            #selector(dissmissKeyboard(tapG:)))
            tap.cancelsTouchesInView = false
            textViewChatContent.addGestureRecognizer(tap)
        
    }
    func dissmissKeyboard(tapG:UITapGestureRecognizer) {
        
        self.view.endEditing(true)
        
    }
    
    //監聽鍵盤響應
    //MARK: 鍵盤響應處理 監聽鍵盤將顯示或者將要隱藏
    fileprivate func addObservers() {
        // will show Keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(note:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        // will hide Keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(note:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

    }
    func keyboardWillShow(note: NSNotification) {
        
        if isKeyboardShow {
            return
        }
        //當點到最底下的文字輸入時就推動畫面
        offsetKeyboard(note: note)
    }
    func offsetKeyboard(note: NSNotification) {
        
        let keyboardAnimationDetail = note.userInfo as! [String: AnyObject]
        let duration = TimeInterval(keyboardAnimationDetail[UIKeyboardAnimationDurationUserInfoKey]! as! NSNumber)
        let keyboardFrameValue = keyboardAnimationDetail[UIKeyboardFrameBeginUserInfoKey]! as! NSValue
        let keyboardFrame = keyboardFrameValue.cgRectValue
        
        UIView.animate(withDuration: duration, animations: { () -> Void in
            
            self.view.frame = self.view.frame.offsetBy(dx: 0, dy: -keyboardFrame.size.height)

        })
        
        isKeyboardShow = true
        
    }
    func keyboardWillHide(note: NSNotification) {
        
        let keyboardAnimationDetail = note.userInfo as! [String: AnyObject]
        let duration = TimeInterval(keyboardAnimationDetail[UIKeyboardAnimationDurationUserInfoKey]! as! NSNumber)
        UIView.animate(withDuration: duration, animations: { () -> Void in
            
            self.view.frame = self.view.frame.offsetBy(dx: 0, dy: -self.view.frame.origin.y)
        })
        
        isKeyboardShow = false
        
    }
    
    
    
    fileprivate func setSwiftR() {
        
        connection = SignalR("https://swiftr.azurewebsites.net")
        connection.useWKWebView = true
        connection.signalRVersion = .v2_2_0
        
    }
    
    fileprivate func setChatHub() {
        
        chatHub = Hub("chatHub")
        chatHub.on("broadcastMessage") { [weak self] args in
            if let name    = args?[0]  as? String,
                let message = args?[1]  as? String,
                let text    = self?.textViewChatContent.text {
                //收到訊息時，將原本已經顯示在textView的內容放在新的訊息前面
                self?.textViewChatContent.text = "\(text)\n\n\(name):\(message)"
                
            }
        }
        connection.addHub(chatHub)
    }
//    open func on(_ method: String, callback: @escaping ([Any]?) -> ()) {
//        let callbackID = UUID().uuidString
//        
//        if handlers[method] == nil {
//            handlers[method] = [:]
//        }
//        
//        handlers[method]?[callbackID] = callback
//    }
    
    fileprivate func setConnectionEvents() {
        //開始連線的處理1
        connection.starting = {
            
            print("開始連線")
            self.textViewChatContent.text = self.textViewChatContent.text + "\n\n開始連線"
            
        }
        //重新連線的處理2
        connection.reconnecting = {
            
            print("重新連線中")
            self.textViewChatContent.text = self.textViewChatContent.text + "\n\n重新連線中！"
            
        }
        //連線成功時的處理3
        connection.connected = {
            
            print("連線成功了")
            self.textViewChatContent.text = self.textViewChatContent.text + "\n\n連線成功了！\n"
            
        }
        //重新連線後的處理4
        connection.reconnected = {
            
            print("重新連線了")
            self.textViewChatContent.text = self.textViewChatContent.text + "\n\n重新連線了！"
            
        }
        //斷線後的處理5
        connection.disconnected = {
            
            print("斷線了")
            self.textViewChatContent.text = self.textViewChatContent.text + "\n\n斷線了！"
            
        }
        //連線緩慢的處理6
        connection.connectionSlow = {
            
            print("連線緩慢")
            
        }
        //連線出現錯誤時的處理7
        connection.error = {
            
            error in print("連線出現錯誤")
            
        }
        connection.start()
    }
    
}

