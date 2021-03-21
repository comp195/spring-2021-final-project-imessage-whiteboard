//
//  MessagesViewController.swift
//  iMessage Whiteboard MessagesExtension
//
//  Created by Cassidy Johnson on 1/30/21.
//
//  Making my first swift comment!

import UIKit
import Messages
import Network

class MessagesViewController: MSMessagesAppViewController {
    
    // the variables needed for drawing
    var lastPoint = CGPoint.zero
    var color = UIColor.black
    var brushWidth: CGFloat = 10.0
    var opacity: CGFloat = 1.0
    var swiped = false
    var typing = false
    
    // the variables needed for a network connection from client(s) to server
    let connection = networkConnection()
    
    // the references to the Image Views in the storyboard
    @IBOutlet weak var TempImageView: UIImageView!
    @IBOutlet weak var MainImageView: UIImageView!
    
    // Messages functions
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.willTransition(to: MSMessagesAppPresentationStyle.expanded)
        
        // establish the port connection here
        connection.setUpCommunication()

        // put the user in drawing mode automatically
    }
    
    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the inactive to active state.
        // This will happen when the extension is about to present UI.
        // Use this method to configure the extension and restore previously stored state.
    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dismisses the extension, changes to a different
        // conversation or quits Messages.
        
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
    }
   
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.
        
        // Use this method to trigger UI updates in response to the message.
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.
    
        // Use this to clean up state related to the deleted message.
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
    
        // Use this method to prepare for the change in presentation style.
        self.requestPresentationStyle(presentationStyle)
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
    
        // Use this method to finalize any behaviors associated with the change in presentation style.
    }
    
    
    // UITouch Functions
    /* the below is code I'm using from a tutorial at https://www.raywenderlich.com/5895-uikit-drawing-tutorial-how-to-make-a-simple-drawing-app */
    
    func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint) {
        UIGraphicsBeginImageContext(view.frame.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        if typing { // don't draw while they're typing, they probably meant for their swipe to be moving a text box, not drawing a line
            // they need to go back into drawing mode by pressing the squiggly button before they can draw more lines
            return
        }
        
        // add lines to that view
        TempImageView.image?.draw(in: view.bounds)
        context.move(to: fromPoint)
        context.addLine(to: toPoint)
        context.setLineCap(.round)
        context.setBlendMode(.normal)
        context.setLineWidth(brushWidth)
        context.setStrokeColor(color.cgColor)
        context.strokePath()
        TempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        TempImageView.alpha = opacity
        UIGraphicsEndImageContext()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            // if this isn't the first touch, then we shouldn't be calling the touchesBegan method, so return
            return
        }
        
        swiped = false
        lastPoint = touch.location(in: view)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        swiped = true
        let currentPoint = touch.location(in: view)
        drawLine(from: lastPoint, to: currentPoint)
        
        lastPoint = currentPoint
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if typing {
            return
        }
        if !swiped { // if nothing was swiped, then just a single point was drawn
            drawLine(from: lastPoint, to: lastPoint)
        }
        
        UIGraphicsBeginImageContext(MainImageView.frame.size)
        MainImageView.image?.draw(in: view.bounds, blendMode: .normal, alpha: 1.0)
        TempImageView?.image?.draw(in: view.bounds, blendMode: .normal, alpha: opacity)
        MainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        TempImageView.image = nil
        
        // Send the input to the other device(s) in this iMessage session
        
    }
    
    
    // Buttons Functions
    @IBAction func goBack(_ sender: UIButton) {
        // Go back to compact view when the user presses the back button
        self.willTransition(to: MSMessagesAppPresentationStyle.compact)
    }
    
    @objc func moveTextBox(_ gesture: UIPanGestureRecognizer){
        let translation = gesture.translation(in: view) // get the amount moved
        
        guard let g = gesture.view else {
            return
        }
        
        g.center = CGPoint(x: g.center.x + translation.x,
                           y: g.center.y + translation.y) // move that amount
        
        // set the amount moved to 0 for next time
        gesture.setTranslation(.zero, in: view)
    }
    
    @IBAction func goToTextMode(_ sender: UIButton) {
        // take them out of drawing mode and into typing mode
        typing = true
        
        // make a text box
        let myTextBox = UITextField(frame: CGRect(x:100, y:100, width:500, height:40))
        myTextBox.placeholder = "Start typing here!"
        myTextBox.font = UIFont.systemFont(ofSize: 15)
        myTextBox.autocorrectionType = UITextAutocorrectionType.yes
        myTextBox.keyboardType = UIKeyboardType.default
        myTextBox.returnKeyType = UIReturnKeyType.done
        myTextBox.clearButtonMode = UITextField.ViewMode.always
        
        // make a gesture recognizer to let users move the box
        let pan = UIPanGestureRecognizer(target: self, action: #selector(moveTextBox(_ :)))
        myTextBox.isUserInteractionEnabled = true
        myTextBox.addGestureRecognizer(pan)
        
        self.view.addSubview(myTextBox)
        
        
    }
    
    @IBAction func goToDrawingMode(_ sender: UIButton) {
        typing = false
    }
}
