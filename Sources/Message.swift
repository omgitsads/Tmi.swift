//
//  TMIMessage.swift
//  Tmi
//
//  Created by Adam Holt on 23/05/2017.
//  Copyright © 2017 Tmi. All rights reserved.
//

import Foundation

public class TmiMessage {
    let rawMessage: String
    
    public var tags: [String:String] = [:]
    var prefix: String!
    var command: String!
    var params: [String] = []
    
    public var emotes = [Int: [Range<Int>]]()
    
    init(_ rawMessage: String) {
        self.rawMessage = rawMessage
        parse()
    }
    
    func parse() {
        var nextPosition = rawMessage.startIndex
        
        // Parse Tags
        nextPosition = parseTags(position: nextPosition)
        nextPosition = skipWhitespace(position: nextPosition)
        nextPosition = parsePrefix(position: nextPosition)
        nextPosition = skipWhitespace(position: nextPosition)
        nextPosition = parseCommand(position: nextPosition)
        nextPosition = parseParams(position: nextPosition)
        
        parseEmotes()
    }
    
    func parseEmotes() {
        if let rawEmotes = self.tags["emotes"] {
            if rawEmotes == "" {
                return
            }
            
            let emoteIdAndRange = rawEmotes.components(separatedBy: "/").filter { $0 != "" }
            let emotesAndRanges = emoteIdAndRange.map { $0.components(separatedBy: ":") }
            
            emotesAndRanges.forEach({ (idAndEmotes) in
                let id = Int(idAndEmotes[0])!
                let emoteRanges = idAndEmotes[1]
                
                let ranges = emoteRanges.components(separatedBy: ",").map({ (emoteRange) -> Range<Int> in
                    let ranges = emoteRange.components(separatedBy: "-")
                    let start = Int(ranges[0])!
                    let end = Int(ranges[1])!
                    
                    return start..<end
                })
                
                self.emotes[id] = ranges
            })
        }
    }
    
    func parsePrefix(position: String.Index) -> String.Index {
        let firstChar = rawMessage[position]
        let substring = rawMessage[position...]
        
        // Extract the message's prefix if present. Prefixes are prepended with a colon..
        if isAsciiValue(character: firstChar, asciiCode: 58) {
            if let nextSpace = substring.range(of: " ") {
                // Grab the range from the start index + 1, i.e. not including the colon
                let prefixString = substring[Range(substring.index(after: substring.startIndex)..<nextSpace.lowerBound)]
                self.prefix = String(prefixString)
                
                return nextSpace.lowerBound
            } else {
                return position
            }
        } else {
            return position
        }
    }
    
    func parseTags(position: String.Index) -> String.Index {
        let firstChar = rawMessage[position]
        let substring = rawMessage[position...]
        
        // Check for IRCv3.2 messages
        // http://ircv3.atheme.org/specification/message-tags-3.2
        if(isAsciiValue(character: firstChar, asciiCode: 64)){
            let nextSpace = substring.range(of: " ")
            let tagsString = substring[Range(substring.startIndex..<nextSpace!.lowerBound)]
            
            let tagsArray = tagsString.components(separatedBy: ";")
            tagsArray.forEach({ (pair) in
                let kvPair = pair.components(separatedBy: "=")
                self.tags[kvPair[0]] = kvPair[1]
            })
            
            return nextSpace!.upperBound
        } else {
            return position
        }
    }
    
    func parseCommand(position: String.Index) -> String.Index {
        if let nextSpace = nextWhitespace(self.rawMessage, from: position) {
            let command = self.rawMessage[Range(position..<nextSpace)]
            self.command = command.trimmingCharacters(in: CharacterSet.whitespaces)
            
            return nextSpace
        } else {
            if(self.rawMessage.endIndex > position) {
                let command = self.rawMessage[position...]
                self.command = command.trimmingCharacters(in: CharacterSet.whitespaces)
                return self.rawMessage.endIndex
            }
        }
        
        return self.rawMessage.endIndex
    }
    
    func parseParams(position: String.Index) -> String.Index {
        var pos = position
        let lastPos = self.rawMessage.endIndex
        
        while pos < lastPos {
            let firstChar = self.rawMessage[pos]
            
            if isAsciiValue(character: firstChar, asciiCode: 58) {
                let nextPos = self.rawMessage.index(after: pos)
                let param = self.rawMessage[Range(nextPos..<lastPos)]
                
                self.params.append(param.trimmingCharacters(in: CharacterSet.whitespaces))
                break
            }
            
            if let nextSpace = nextWhitespace(self.rawMessage, from: pos) {
                let param = self.rawMessage[Range(pos..<nextSpace)]
                self.params.append(param.trimmingCharacters(in: CharacterSet.whitespaces))
                pos = nextSpace
            } else {
                let param = self.rawMessage[Range(pos..<lastPos)]
                self.params.append(param.trimmingCharacters(in: CharacterSet.whitespaces))
                break
            }
        }
        
        return lastPos
    }
    
    private func asciiValue(character: Character) -> UnicodeScalar? {
        return String(character).unicodeScalars.filter({ $0.isASCII }).first
    }
    
    private func isAsciiValue(character: Character, asciiCode: UInt32) -> Bool {
        if let char = asciiValue(character: character) {
            return (char.value == asciiCode)
        } else {
            return false
        }
    }
    
    private func skipWhitespace(position: String.Index) -> String.Index {
        var nextPosition = position
        
        while isAsciiValue(character: self.rawMessage[nextPosition], asciiCode: 32) {
            nextPosition = self.rawMessage.index(after: nextPosition)
        }
        
        return nextPosition
    }
    
    private func nextWhitespace(_ string: String, from: String.Index) -> String.Index? {
        if let nextSpace = string.range(of: " ", range: Range(from..<string.endIndex)) {
            return nextSpace.upperBound
        }
        
        return nil
    }
}
