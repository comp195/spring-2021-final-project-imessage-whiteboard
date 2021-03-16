//
//  Network.swift
//  iMessage Whiteboard MessagesExtension
//
//  Created by Cassidy Johnson on 3/15/21.
//

import Foundation


// globals
let server = URL(string: "localhost:9000")
var usersArray: [String: Int]! // dictionary of IP address as a string and port num as int

// networking class
/* the below is code I'm using from a tutorial at https://www.raywenderlich.com/3437391-real-time-communication-with-streams-tutorial-for-ios */
class networkConnection: NSObject {
    var inputStream: InputStream!
    var outputStream: OutputStream!
    // have to have both input and output streams to make a bidirectional communication channel
    let maxReadLength = 4096
    
    func setUpCommunication() {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        // set up the network connection
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, "localhost" as CFString, 9000, &readStream, &writeStream)
        
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
        default:
            print("What the fuck happened")
        }
    }
    
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
                print("We've got mail")
            }
        }
    }
    
    private func processedMessageString(buff: UnsafeMutablePointer<UInt8>, length: Int) -> Messages? {
        guard
            let stringArray = String(
                bytesNoCopy: buff, length: length, encoding: .utf8, freeWhenDone: true)?.components(separatedBy: ","),
            // format is as follows [ip: message]
            let addr = stringArray.first,
            let message = stringArray.last
        else {
            return nil
        }
        
        return Messages(senderIP: addr, senderPort: 0, messageContents: message)
        
    }
}
