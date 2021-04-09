//
//  MessagesDelegator.swift
//  iMessage Whiteboard
//
//  Created by Cassidy Johnson on 4/3/21.
//

import Foundation
import UIKit

protocol MessagesDelegator {
    func receivedMoveTextBox(m: String)
    func receivedAddTextBox(m: String)
    func receivedTouchesBegan(m: String)
    func receivedTouchesMoved(m: String)
    func receivedTouchesEnded(m: String)

}
