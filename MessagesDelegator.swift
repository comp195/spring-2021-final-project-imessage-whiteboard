//
//  MessagesDelegator.swift
//  iMessage Whiteboard
//
//  Created by Cassidy Johnson on 4/3/21.
//

import Foundation
import UIKit

protocol MessagesDelegator {
    func printToScreen(m: String)
    func receivedMoveTextBox(m: String)
    func receivedAddTextBox(m: String)
    func receivedDrawLine(m: String)
}
