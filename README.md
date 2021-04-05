# iMessage Whiteboard

#### Author: Cassidy Johnson

#### Email: c\_johnson49@u.pacific.edu

## Description:
iMessage Whiteboard is an in-app iMessage extension for real-time collaboration on a virtual whiteboard. Users can enter their chat session, click on the iMessage Whiteboard extension, and begin to draw, add text, or add images to a whiteboard that updates in real-time. Whiteboards can be saved as PDFs as well.

## Project Components:
This project consists of client-side code written in Swift and a small Python server that saves history.

## Special Notes:
As of April 4, the project's client side code allows users to draw lines and make text boxes, and sends textual updates of the client's activities to the server. I am attempting to use MSSessions to send data, which means using the iMessage session to send and receive data instead of making my own networking setup. I also have my own networking setup ready, but I don't think that it's working as well as the builtin MSSessions library. 
