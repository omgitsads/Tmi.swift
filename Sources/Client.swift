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

public class TmiClient: WebSocketDelegate {
    var username: String
    var password: String
    var channels = Array<String>()
    var webSocket: WebSocket
    
    var pingLoop: Timer?
    var pingTimeout: Timer?
    var latency: Date?
    
    public var onPing: (()->Void)?
    public var onPong: ((_ latency:TimeInterval) -> Void)?
    
    public var onConnect: (()->Void)?
    
    public init(username: String, password: String, channels: Array<String>) {
        self.username = username
        self.password = password
        
        self.channels = channels
        
        self.webSocket = WebSocket(url: URL(string: "ws://irc-ws.chat.twitch.tv")!)
        self.webSocket.delegate = self
    }

    public func connect() {
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
                        self.onPing?()
                    }
                case "PONG":
                    let currentLatency = Date().timeIntervalSince(self.latency!)
                    self.onPong?(currentLatency)
                    
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
                    self.onConnect?()
                    
                    self.pingLoop = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { (timer) in
                        if(socket.isConnected) {
                            socket.write(string: "PING")
                        }
                        
                        self.latency = Date()
                        self.pingTimeout = Timer.scheduledTimer(withTimeInterval: 9.99, repeats: false, block: {[weak self] (timer) in
                            if let strongSelf = self {
                                strongSelf.webSocket.disconnect()
                                
                                strongSelf.pingLoop?.invalidate()
                                strongSelf.pingLoop = nil
                                
                                strongSelf.pingTimeout?.invalidate()
                                strongSelf.pingTimeout = nil
                            }
                        })
                    })
                    break
                case "NOTICE":
                    switch message.tags["msg-id"] {
                    default:
                        debugPrint("TODO: Implement NOTICE")
                        break
                    }
                    break
                case "USERNOTICE":
                    switch message.tags["msg-id"] {
                    default:
                        debugPrint("TODO: Implement USERNOTICE")
                        break
                    }
                    break
                case "HOSTTARGET":
                    debugPrint("TODO: Implement HOSTTARGET")
                    break
                case "CLEARCHAT":
                    switch message.tags["msg-id"] {
                    default:
                        debugPrint("TODO: Implement CLEARCHAT")
                        break
                    }
                    break
                case "RECONNECT":
                    debugPrint("Received RECONNECT request from Twitch..")
                    socket.disconnect()

                    // TODO: Introduce reconnection decay
                    debugPrint("Disconnecting and reconnecting in 1 second")
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: {[weak self] (timer) in
                        if let strongSelf = self {
                            strongSelf.connect()
                        }
                    })
                    break
                case "SERVERCHANGE":
                    break
                case "USERSTATE":
                    debugPrint("TODO: Implement USERSTATE")
                    break
                case "GLOBALUSERSTATE":
                    debugPrint("TODO: Implement GLOBALUSERSTATE")
                    break
                case "ROOMSTATE":
                    debugPrint("TODO: Implement ROOMSTATE")
                    break
                default:
                    debugPrint("Could not parse message from tmi.twitch.tv:\(message.rawMessage)")
                    break
                }
            } else if message.prefix == "jtv" {
                switch message.command {
                case "MODE":
                    debugPrint("TODO: Implement MODE")
                    break
                default:
                    debugPrint("Could not parse message from jtv: \(message.rawMessage)")
                    break
                }
            } else {
                switch message.command {
                case "353":
                    debugPrint("TODO: Implement 353")
                    break
                case "366":
                    debugPrint("TODO: Implement 366")
                case "JOIN":
                    debugPrint("TODO: Implement JOIN")
                    break
                case "PART":
                    debugPrint("TODO: Implement PART")
                    break
                case "WHISPER":
                    debugPrint("TODO: Implement WHISPER")
                    break
                case "PRIVMSG":
                    debugPrint("TODO: Implement PRIVMSG")
                    break
                default:
                    debugPrint("Could not parse message: \(message.rawMessage)")
                }
            }
        }
    }
}
