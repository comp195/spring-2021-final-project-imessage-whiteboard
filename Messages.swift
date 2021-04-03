//
//  Messages.swift
//  iMessage Whiteboard MessagesExtension
//
//  Created by Cassidy Johnson on 3/15/21.
//

import Foundation

struct Messages {
    var senderIP: CFString
    var senderPort: Int8
    var messageContents: String
    
    init(message: String, ip:CFString, port:Int8){
        self.senderIP = ip
        self.senderPort = port
        self.messageContents = message
    }
}
