//
//  Connection.swift
//  tmi
//
//  Created by Adam Holt on 19/05/2017.
//  Copyright © 2017 tmi. All rights reserved.
//

import Foundation

import Starscream

import ReactiveSwift
import Result

protocol TMIConnectionDelegate {
    func didConnect()
    func didDisconnect()
}

class TMIConnection: WebSocketDelegate {
    var delegate: TMIConnectionDelegate;
    var webSocket: WebSocket
    
    init(delegate: TMIConnectionDelegate) {
        self.delegate = delegate
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
    
    func websocketDidConnect(socket: WebSocket) {
        self.delegate.didConnect()
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        self.delegate.didDisconnect()
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        print(text)
    }
}
