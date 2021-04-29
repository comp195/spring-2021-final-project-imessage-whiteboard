//
//  TextBoxViewController.swift
//  iMessage Whiteboard
//
//  Created by Cassidy Johnson on 4/29/21.
//

import Foundation
import UIKit

class TextBoxViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        
    }
}



