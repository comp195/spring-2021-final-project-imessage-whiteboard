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


class MessagesViewController: MSMessagesAppViewController, MessagesDelegator, UITextViewDelegate {
    

    // the variables needed for drawing
    var lastPoint = CGPoint.zero
    var participantLastPoint = CGPoint.zero
    var color = UIColor.black
    var participantColor = UIColor.black
    var brushWidth: CGFloat = 10.0
    var opacity: CGFloat = 1.0
    var fontSize = 15
    var swiped = false
    var participantSwiped = false
    var typing = false
    var participantTyping = false
    let backgroundColor = UIColor.white
    
    // the variables needed for a network connection from client(s) to server
    let connection = networkConnection()
    
    // delegate
    var delegate:MessagesDelegator?
    
    // the variables needed for the imessage session
    var myID: String = ""
    var theirID: String = ""
    
    // the references to the Image Views, Labels, etc. in the storyboard
    @IBOutlet weak var TempImageView: UIImageView!
    @IBOutlet weak var MainImageView: UIImageView!
    @IBOutlet weak var tempTextBoxLabel: UILabel!
    @IBOutlet weak var settingsView: UIView!
    
    //
    // MESSAGE FUNCTIONS
    //
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func willBecomeActive(with conversation: MSConversation) {

        myID = conversation.localParticipantIdentifier.uuidString
        theirID = conversation.remoteParticipantIdentifiers[0].uuidString
        
        print(myID)
    
        // establish the port connection here
        connection.setUpCommunication()
        
        // set up the delegate
        connection.delegate = self
        
        // send a hello message so the server gets the uuids
        connection.sendDataToServer(message: "HELLO\t\(getMyUUID())\t\(getTheirUUID())".data(using: .utf8)!)

    }
    
    override func didResignActive(with conversation: MSConversation) {
        
        // send a "LEAVE" message to the server
        let message = "LEAVE".data(using: .utf8)!
        connection.sendDataToServer(message: message)
                
    }

    //
    // UITOUCH FUNCTIONS
    //
    
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
            return
        }
        
        swiped = false
        lastPoint = touch.location(in: view)
        
        // just send lastPoint
        // send MyID\tTheirID\tServerTypexValyVal\n
        myID = self.activeConversation!.localParticipantIdentifier.uuidString
        theirID = self.activeConversation!.remoteParticipantIdentifiers[0].uuidString
        let message = "\(myID)\t\(theirID)\t\(ServerMessageType.drawLineBeganString.rawValue)x\(lastPoint.x)y\(lastPoint.y)\n".data(using: .utf8)!
        connection.sendDataToServer(message: message)
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        swiped = true
        let currentPoint = touch.location(in: view)
        drawLine(from: lastPoint, to: currentPoint)
        
        lastPoint = currentPoint
        
        // just send lastPoint
        myID = self.activeConversation!.localParticipantIdentifier.uuidString
        theirID = self.activeConversation!.remoteParticipantIdentifiers[0].uuidString
        let message = "\(myID)\t\(theirID)\t\(ServerMessageType.drawLineMovedString.rawValue)x\(lastPoint.x)y\(lastPoint.y)\n".data(using: .utf8)!
        connection.sendDataToServer(message: message)
        
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
        // just send lastPoint
        myID = self.activeConversation!.localParticipantIdentifier.uuidString
        theirID = self.activeConversation!.remoteParticipantIdentifiers[0].uuidString
        let message = "\(myID)\t\(theirID)\t\(ServerMessageType.drawLineEndedString.rawValue)x\(lastPoint.x)y\(lastPoint.y)\n".data(using: .utf8)!
        connection.sendDataToServer(message: message)
        
        // trigger the update function
        //updateConversationParticipants()
    }
    
    func updateConversationParticipants() {
        
        // get the conversation and the session
        let conversation = activeConversation
        let session = conversation?.selectedMessage?.session
        let mySession = session ?? MSSession() // unwrap
        
        // update the session layout using the picture we took
        let layout = MSMessageTemplateLayout()
        layout.image = MainImageView.image
        
        do {
            // turn the UIView into data
            let data = try NSKeyedArchiver.archivedData(withRootObject: view!, requiringSecureCoding: false)
            
            // convert data to a string
            let imageString = data.base64EncodedString(options: .endLineWithLineFeed)
            let whiteboardImage = URLQueryItem(name: "board", value:imageString)
            
            
            // make a url that includes the data of the current whiteboard
            var url = URLComponents()
            
            // put the whiteboard into the url string
            url.queryItems = [whiteboardImage]
            
            // send important info to the other client using a URL
            let newMessage = MSMessage(session: mySession)
            newMessage.layout = layout
            newMessage.url = url.url! // idk why I named it like this, I know it's gross, sue me
            newMessage.summaryText = "I updated our shared whiteboard!"
            
            // put the message in the conversation, like "publishing" our whiteboard
            conversation?.insert(newMessage)
            
        } catch {
            print("ERROR: couldn't make a message to udpate participants")
            return
        }
        
    }
    
    //
    // DELEGATE FUNCTIONS + HELPERS
    //
    
    func getMyUUID() -> String {
        return myID
    }
    
    func getTheirUUID() -> String {
        return theirID
    }
    
    func parseMessage(m: String) -> CGPoint? {
        // at this point, messages should be in the format "x20y20" if they were moved 20 right and 20 up
        var message = m
        message.remove(at: message.startIndex) // remove the "x"
        message = String(message.dropLast(2)) // remove the "\n"
        
        // make variables that represent the translation and put them in a CGPoint
        let parts = message.split(separator: "y")
        if let x = Float(parts[0]), let y = Float(parts[1]){
            var point = CGPoint()
            point.x = CGFloat(x)
            point.y = CGFloat(y)
            return point
        }
        
        return nil
    }
    
    func receivedMoveTextBox( m: String )
    {
        print("Will move text box")
        // parse m
        if let point = parseMessage(m: m){
        
            // make a gesture
            let g = UIPanGestureRecognizer(target: self, action: #selector(moveTextBox(_ :)))
            g.setTranslation(point, in: view)
        
            // attach that gesture to the textBox
        
            // call moveTextBox and don't send to the server
            moveTextBox(g)
        }
        else{
            print("error moving text box")
        }
    }
    
    func receivedAddTextBox(m: String) {
        print("Will add text box")
        
        // make a gesture
        let g = UITapGestureRecognizer(target: self, action: #selector(moveTextBox(_ :)))
        
        // put the text box at point 0,0 for now
        g.view?.center = CGPoint()
        
        // call moveTextBox and don't send to the server
        let textBox = addTextBox(g)
        if let point = parseMessage(m: m){
            textBox.center = point
        }
        else{
            print("error moving text box after adding it")
        }
    }
    
    func receivedTouchesBegan(m: String) {
        // string should be in format "x20y20" if touches began at point 20, 20
        let previousVal = participantLastPoint
        swiped = false
        participantLastPoint = parseMessage(m: m) ?? previousVal
    }
    
    func receivedTouchesMoved(m: String) {
        swiped = true
        
        // m isn't the same format as it is in receivedTouchesEnded or receivedTouchesBegan
        print("before:")
        print(m)
        let parts = m.split(separator: "\n")
        print("after")
        for part in parts {
            var myString = String(part) // copy the substring to a string
            print(myString)
            
            // is the first char a "1" or a "2"?
            let firstChar = myString.prefix(1)
            if(firstChar == "1"){
                print("1")
                // add the "\n" back in, parseMessages expects it
                myString.append("\n")
                myString.remove(at: myString.startIndex)
                if let point = parseMessage(m: myString){
                    drawLine(from: participantLastPoint, to: point)
                    participantLastPoint = point
                }
                else{
                    print("error parsing message")
                }
                
            }
            else if (firstChar == "2"){
                print("2")
                myString.remove(at: myString.startIndex)
                receivedTouchesEnded(m: myString)
            }
            else {
                print("uh oh!")
                print(firstChar)
            }
        }
    }
    
    func receivedTouchesEnded(m: String) {
        print("Will draw line")
        if typing {
            return
        }
        if !swiped { // if nothing was swiped, then just a single point was drawn
            drawLine(from: participantLastPoint, to: participantLastPoint)
        }
        
        UIGraphicsBeginImageContext(MainImageView.frame.size)
        MainImageView.image?.draw(in: view.bounds, blendMode: .normal, alpha: 1.0)
        TempImageView?.image?.draw(in: view.bounds, blendMode: .normal, alpha: opacity)
        MainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        TempImageView.image = nil
        
    }
    
    func receivedUpdatedText(m: String){
        let myTextBox = UITextView(frame: CGRect(x:10, y:100, width:view.frame.width/2, height:100))
        myTextBox.backgroundColor = UIColor.lightGray
        myTextBox.font = UIFont.systemFont(ofSize: CGFloat(fontSize))
        myTextBox.text = m
        myTextBox.autocorrectionType = UITextAutocorrectionType.yes
        myTextBox.keyboardType = UIKeyboardType.alphabet
        myTextBox.returnKeyType = UIReturnKeyType.done
        self.view.addSubview(myTextBox)
    }

    
    func textViewDidChange(_ textView: UITextView) {
        myID = self.activeConversation!.localParticipantIdentifier.uuidString
        theirID = self.activeConversation!.remoteParticipantIdentifiers[0].uuidString
        let message = "\(myID)\t\(theirID)\(ServerMessageType.updatedTextBoxText.rawValue)x\(textView.text)".data(using:.utf8)!
        connection.sendDataToServer(message: message)
        
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
    
    @objc func moveTextBoxAndSendToServer(_ gesture: UIPanGestureRecognizer){
        moveTextBox(gesture)
        
        // notify the server
        let translation = gesture.translation(in: view) // get the amount moved
        myID = self.activeConversation!.localParticipantIdentifier.uuidString
        theirID = self.activeConversation!.remoteParticipantIdentifiers[0].uuidString
        let message = "\(myID)\t\(theirID)\(ServerMessageType.movedTextBoxString.rawValue)x\(translation.x)y\(translation.y)".data(using:.utf8)!
        print(message)
        print(translation.x)
        print(translation.y)
        /*let message = "I moved a text box horizontally \(translation.x) pixels and vertically \(translation.y) pixels".data(using: .utf8)!*/
        connection.sendDataToServer(message: message)
        
    }
    
    @objc func addTextBox(_ gesture: UITapGestureRecognizer) -> UITextView {
        tempTextBoxLabel.isHidden = true
        
        // make a text box
        let myTextBox = UITextView(frame: CGRect(x:10, y:100, width:view.frame.width/2, height:100))
        myTextBox.backgroundColor = UIColor.lightGray
        myTextBox.text = "Start typing here!"
        myTextBox.font = UIFont.systemFont(ofSize: CGFloat(fontSize))
        myTextBox.autocorrectionType = UITextAutocorrectionType.yes
        myTextBox.keyboardType = UIKeyboardType.alphabet
        myTextBox.returnKeyType = UIReturnKeyType.done
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
        myID = self.activeConversation!.localParticipantIdentifier.uuidString
        theirID = self.activeConversation!.remoteParticipantIdentifiers[0].uuidString
        let message = "\(myID)\t\(theirID)\t\(ServerMessageType.addTextBoxString.rawValue)x\(x)y\(y)".data(using: .utf8)!
        
        //let dummyMessage = "I made a text box".data(using: .utf8)!
        connection.sendDataToServer(message: message)
    }
    
    //
    // BUTTON FUNCTIONS
    //
    
    @IBAction func goToTextMode(_ sender: UIButton) {
        // take them out of drawing mode and into typing mode
        typing = true
        
        // tell them to point to where they want the text box to land
        tempTextBoxLabel.isHidden = false
        
        // wait for them to click
        let tap = UITapGestureRecognizer(target: self, action: #selector(addTextBoxSendToServer(_:)))
        self.view.addGestureRecognizer(tap)
        
    }
    
    @IBAction func goToDrawingMode(_ sender: UIButton) {
        typing = false
    }
    
    @IBAction func goToErasingMode(_ sender: UIButton) {
        typing = false
        color = backgroundColor
    }
    
    @IBAction func makeFontRed(_ sender: UIButton) {
        color = UIColor.red
    }
    
    @IBAction func makeFontOrange(_ sender: Any) {
        color = UIColor.orange
    }
    
    @IBAction func makeFontYellow(_ sender: UIButton) {
        color = UIColor.yellow
    }
    
    @IBAction func makeFontGreen(_ sender: UIButton) {
        color = UIColor.green
    }
    
    @IBAction func makeFontBlue(_ sender: UIButton) {
        color = UIColor.blue
    }
    
    @IBAction func makeFontPurple(_ sender: UIButton) {
        color = UIColor.purple
    }
    
    @IBAction func makeFontBlack(_ sender: UIButton) {
        color = UIColor.black
    }
    
    @IBAction func makeFontGray(_ sender: UIButton) {
        color = UIColor.gray
    }
    
    @IBAction func makeFontPink(_ sender: UIButton) {
        color = UIColor.systemPink
    }
  
    @IBAction func makeFontSizeSmall(_ sender: UIButton) {
        fontSize = 10
    }
 
    
    @IBAction func makeFontSizeMedium(_ sender: UIButton) {
        fontSize = 20
    }
    
    @IBAction func makeFontSizeLarge(_ sender: UIButton) {
        fontSize = 30
    }
    
    @IBAction func showSettings(_ sender: UIButton) {
        typing = true
        settingsView.isHidden = false
    }
    
    @IBAction func closeSettings(_ sender: UIButton) {
        typing = false
        settingsView.isHidden = true
    }
    
}
