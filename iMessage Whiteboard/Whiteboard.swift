//
//  Whiteboard.swift
//  iMessage Whiteboard
//
//  Created by Cassidy Johnson on 4/8/21.
//

import Foundation
import Network
import UIKit

class Board: NSObject {
    
    // keep hold of the UUID of the other participant
    var participantID
    
    // Constructor
    init(id: UUID) {
        participantID = id
    }
    
    // UITouch Functions
    /* some of the below is code I'm using from a tutorial at https://www.raywenderlich.com/5895-uikit-drawing-tutorial-how-to-make-a-simple-drawing-app */
    
    func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint) {
        UIGraphicsBeginImageContext(view.frame.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        if typing {
            // don't draw while they're typing, they probably meant for their swipe to be moving a text box, not drawing a line
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
        
        let dummyMessage = "I drew a line".data(using: .utf8)!
        connection.sendDataToServer(message: dummyMessage)
        
        // trigger the update function
        //updateConversationParticipants()
    }

    
    // Delegate functions and helpers
    
    func parseMessage(m: String) -> CGPoint {
        // at this point, messages should be in the format "x20y20" if they were moved 20 right and 20 up
        var message = m
        message.remove(at: message.startIndex) // remove the "x"
        
        // make variables that represent the translation and put them in a CGPoint
        let parts = message.split(separator: "y")
        let x = Float(parts[0])
        let y = Float(parts[1])
        var point = CGPoint()
        point.x = CGFloat(x!)
        point.y = CGFloat(y!)
        
        return point
    }
    
    func printToScreen(m: String) {
        let text = UITextField(frame: CGRect(x:20, y:20, width: 300, height:100))
        text.placeholder = m
        self.view.addSubview(text)
        
    }
    
    func receivedMoveTextBox( m: String )
    {
        print("Will move text box")
        // parse m
        let point = parseMessage(m: m)
        
        // make a gesture
        let g = UIPanGestureRecognizer(target: self, action: #selector(moveTextBox(_ :)))
        g.setTranslation(point, in: view)
        
        // attach that gesture to the textBox
        
        // call moveTextBox and don't send to the server
        moveTextBox(g)
        
    }
    
    func receivedAddTextBox(m: String) {
        print("Will add text box")
        
        // make a gesture
        let g = UITapGestureRecognizer(target: self, action: #selector(moveTextBox(_ :)))
        
        // put the text box at point 0,0 for now
        g.view?.center = CGPoint()
        
        // call moveTextBox and don't send to the server
        let textBox = addTextBox(g)
        let point = parseMessage(m: m)
        
        // put it where it should go
        textBox.center = point
    }
    
    func receivedDrawLine(m: String) {
        print("will draw line")
    }

    // Button functions
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
    
    @objc func moveTextBoxAndSendToServer(_ gesture: UIPanGestureRecognizer){
        moveTextBox(gesture)
        
        // notify the server
        let translation = gesture.translation(in: view) // get the amount moved
        let message = "\(movedTextBoxString)x\(translation.x)y\(translation.y)".data(using:.utf8)!
        print(message)
        print(translation.x)
        print(translation.y)
        /*let message = "I moved a text box horizontally \(translation.x) pixels and vertically \(translation.y) pixels".data(using: .utf8)!*/
        connection.sendDataToServer(message: message)
        
    }
    
    @objc func addTextBox(_ gesture: UITapGestureRecognizer) -> UITextField {
        tempTextBoxLabel.isHidden = true
        
        // make a text box
        let myTextBox = UITextField(frame: CGRect(x:10, y:100, width:view.frame.width/2, height:40))
        myTextBox.borderStyle = UITextField.BorderStyle.line
        myTextBox.text = "Start typing here!"
        myTextBox.font = UIFont.systemFont(ofSize: 15)
        myTextBox.autocorrectionType = UITextAutocorrectionType.yes
        myTextBox.keyboardType = UIKeyboardType.alphabet
        myTextBox.returnKeyType = UIReturnKeyType.done
        myTextBox.clearButtonMode = UITextField.ViewMode.always
        var point = CGPoint()
        point.x = gesture.location(in: view).x
        point.y = gesture.location(in: view).y
        myTextBox.center = point
        self.view.addSubview(myTextBox)
        
        // make a gesture recognizer to let users move the box
        let pan = UIPanGestureRecognizer(target: self, action: #selector(moveTextBoxAndSendToServer(_ :)))
        myTextBox.isUserInteractionEnabled = true
        myTextBox.addGestureRecognizer(pan)
        
        // remove the tap gesture recognizer we assigned in goToTextMode()
        self.view.removeGestureRecognizer(gesture)
        
        return myTextBox
    }
    
    @objc func addTextBoxSendToServer(_ gesture: UITapGestureRecognizer) {
        _ = addTextBox(gesture)
        
        // notify the server
        let x = gesture.location(in: view).x
        let y = gesture.location(in: view).y
        let message = "\(addTextBoxString)x\(x)y\(y)".data(using: .utf8)!
        //let dummyMessage = "I made a text box".data(using: .utf8)!
        connection.sendDataToServer(message: message)
    }
}
