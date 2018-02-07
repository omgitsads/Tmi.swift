//
//  Client.swift
//  tmi
//
//  Created by Adam Holt on 19/05/2017.
//  Copyright © 2017 tmi. All rights reserved.
//

import Foundation
import Starscream

class TmiChatEvent {
    
}

public class TmiClient: WebSocketDelegate, WebSocketPongDelegate {
    var username: String
    var password: String
    var channels = Array<String>()
    var webSocket: WebSocket
    
    var pingLoop: Timer?
    var pingTimeout: Timer?
    var latency: Date?
    
    init(username: String, password: String, channels: Array<String>) {
        self.username = username
        self.password = password
        
        self.channels = channels
        
        self.webSocket = WebSocket(url: URL(string: "ws://irc-ws.chat.twitch.tv")!)
        self.webSocket.delegate = self
    }

    func connect() {
        self.webSocket.connect()
    }

    func authenticate(username: String, password: String) {
        self.webSocket.write(string: "CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership");
        self.webSocket.write(string: "PASS \(password)")
        self.webSocket.write(string: "NICK \(username)")
        self.webSocket.write(string: "USER \(username) 8 * :\(username)")
    }
    
    public func websocketDidConnect(socket: WebSocketClient) {
        self.authenticate(username: self.username, password: self.password)
    }
    
    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
    }
    
    public func websocketDidReceivePong(socket: WebSocketClient, data: Data?) {
        print("Got pong! Maybe some data: \(data?.count)")
    }

    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        let messages = text.components(separatedBy: "\r\n")
        
        for messageString in messages {
            if messageString == "" { break }
            
            let message = TmiMessage(messageString)
            
            if message.prefix == nil {
                switch message.command {
                case "PING":
                    if(socket.isConnected){
                        socket.write(string: "PONG")
                    }
                case "PONG":
                    self.pingTimeout?.invalidate()
                    self.pingTimeout = nil
                    break
                default:
                    debugPrint("Could not parse message with no prefix")
                }
            } else if message.prefix == "tmi.twitch.tv" {
                switch message.command {
                case "002", "003", "004", "375", "376":
                    break
                case "001":
                    self.username = message.params[0]
                    break
                case "372":
                    debugPrint("Connected to server.")
                    
                    self.pingLoop = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { (timer) in
                        if(socket.isConnected) {
                            socket.write(string: "PING")
                        }
                        
                        self.latency = Date()
                        self.pingTimeout = Timer.scheduledTimer(withTimeInterval: 9.99, repeats: false, block: { (timer) in
                            socket.disconnect()
                            
                            self.pingLoop?.invalidate()
                            self.pingLoop = nil
                            
                            self.pingTimeout?.invalidate()
                            self.pingTimeout = nil
                        })
                    })
                    break
                default:
                    break
                }
            }
        }
    }
}
