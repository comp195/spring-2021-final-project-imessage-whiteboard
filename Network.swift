//
//  Network.swift
//  iMessage Whiteboard MessagesExtension
//
//  Created by Cassidy Johnson on 3/15/21.
//

import Foundation
import UIKit

// enum for types of server messages received
enum ServerMessageType: Int {
    case drawLineBeganString = 0
    case drawLineMovedString = 1
    case drawLineEndedString = 2
    case addTextBoxString = 3
    case movedTextBoxString = 4
}


// globals
let server = URL(string: "54.243.90.219:9998")
var usersArray: [String: Int]! // dictionary of IP address as a string and port num as int

// networking class
/* the below is code I'm using from a tutorial at https://www.raywenderlich.com/3437391-real-time-communication-with-streams-tutorial-for-ios */
class networkConnection: NSObject {
    var inputStream: InputStream!
    var outputStream: OutputStream!
    // have to have both input and output streams to make a bidirectional communication channel
    let maxReadLength = 4096
    
    // delegate so that we can signal the MessagesViewController from within this file
    var delegate: MessagesDelegator?
    
    func setUpCommunication() {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        // set up the network connection
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, "54.243.90.219" as CFString, 9998, &readStream, &writeStream)
        
        // init the streams while preventing memory leak
        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()
        
        // I am my own delegate, don't use a default one. I can handle all the messages myself
        inputStream.delegate = self
        
        // set up a loop so they react to events
        inputStream.schedule(in: .current, forMode: .common)
        outputStream.schedule(in: .current, forMode: .common)
        
        // start 'em up!
        inputStream.open()
        outputStream.open()
    }
    
    // write to server
    func sendDataToServer(message: Data)
    {
        // Apply the withUnsafeBytes closure to the dummyMessage string I wrote
        message.withUnsafeBytes {
            // make a pointer from the dummyMessage string
            guard let pointer = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                print("Error sending message to server")
                return
            }
            
            // send the message to the server
            print("writing to server")
            outputStream.write(pointer, maxLength: message.count)
        }
    }

}

extension networkConnection: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasBytesAvailable:
            print("Received a message")
            readBytes(stream: aStream as! InputStream)
        case .endEncountered:
            print("Received the end of a message")
        case .errorOccurred:
            print("Something horrible has happened. Give up.")
        case .hasSpaceAvailable:
            print("The message was short")
        case .openCompleted:
            print("The connection opened")
        default:
            print("What the fuck happened: \(eventCode)")
        }
    }
    
    
    // read from server
    private func readBytes(stream: InputStream) {
        let buff = UnsafeMutablePointer<UInt8>.allocate(capacity: maxReadLength)
        
        while stream.hasBytesAvailable {
            let numBytesRead = inputStream.read(buff, maxLength: maxReadLength)
            
            if numBytesRead < 0, let error = stream.streamError {
                print(error)
                break
            }
            
            if let message = processedMessageString(buff: buff, length: numBytesRead)
            {
                // tell people we got a message here
                //delegate?.received(message: message)
                //print("We've got mail ")
                //print(message)
                
                var m = message
                if(m.count == 0)
                {
                    return
                }
                
                // get first char, which tells us which function to send this message to
                let firstChar = m.prefix(1)
                
                // trim that first char off the string, we won't need it again
                m.remove(at: m.startIndex)
                
                // send the message to the client
                switch firstChar {
                case "\(ServerMessageType.addTextBoxString.rawValue)":
                    delegate?.receivedAddTextBox(m: m)
                case "\(ServerMessageType.movedTextBoxString.rawValue)":
                    delegate?.receivedMoveTextBox(m: m)
                case "\(ServerMessageType.drawLineBeganString.rawValue)":
                    delegate?.receivedTouchesBegan(m: m)
                case "\(ServerMessageType.drawLineMovedString.rawValue)":
                    delegate?.receivedTouchesMoved(m: m)
                case "\(ServerMessageType.drawLineEndedString.rawValue)":
                    delegate?.receivedTouchesEnded(m: m)
                    
                default:
                    print("Bad error, couldn't give message back to client")
                }
                
                // for now, print the message on the screen so I can see it even when a debugger isn't attached
                //delegate?.printToScreen(m: message.messageContents)
            }
        }
    }
    
    private func processedMessageString(buff: UnsafeMutablePointer<UInt8>, length: Int) -> String? {
        guard
            let message = String(
                bytesNoCopy: buff, length: length, encoding: .utf8, freeWhenDone: true)
            // format is as follows [ip: message]
        else {
            return nil
        }
        return message
    }
    
}

