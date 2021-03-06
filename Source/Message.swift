//
// Message.swift
//
// Copyright (c) 2016 Damien (http://delba.io)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

internal enum Message {
    case Request(Key)
    case Response(Key, Value?)
    case Insert([Key])
    case Delete([Key])
    
    private var type: String {
        switch self {
        case Request:  return "request"
        case Response: return "response"
        case Insert:   return "insert"
        case Delete:   return "delete"
        }
    }
    
    private var values: [AnyObject] {
        switch self {
        case let Request(key):   return [key]
        case let Response(k, v): return [k, v].flatMap{$0}
        case let Insert(keys):   return [keys]
        case let Delete(keys):   return [keys]
        }
    }
    
    internal init?(data: NSData) {
        guard let
            dictionary = KeyArchiver.unarchive(data) as? [String: AnyObject],
            type = dictionary["type"] as? String,
            values = dictionary["values"] as? [AnyObject]
        else {
            return nil
        }
        
        // ["type": "request", "values": ["key"]]
        if type == "request", let key = values[safe: 0] as? Key {
            self = Request(key)
        }
        
        // ["type": "response", "values": ["key", "value"]]
        else if type == "response", let key = values[safe: 0] as? Key {
            self = Response(key, values[safe: 1])
        }
        
        // ["type": "insert", "values": [["key1", "key2"]]]
        else if type == "insert", let keys = values[safe: 0] as? [Key] {
            self = Insert(keys)
        }
        
        // ["type": "delete", "values": [["key1", "key2"]]]
        else if type == "delete", let keys = values[safe: 0] as? [Key] {
            self = Delete(keys)
        }
        
        else {
            return nil
        }
    }
    
    internal func toData() -> NSData {
        return KeyArchiver.archive([
            "type": type,
            "values": values
        ])
    }
}