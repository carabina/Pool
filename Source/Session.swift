//
// Session.swift
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

import MultipeerConnectivity

class Session: NSObject {
    internal var delegate: SessionDelegate?
    
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    private let session: MCSession
    private let peer = MCPeerID(displayName: UIDevice.currentDevice().name)
    
    internal var connectedPeers: [MCPeerID] {
        return self.session.connectedPeers
    }
    
    internal init(name: String) {
        self.advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: name)
        self.browser = MCNearbyServiceBrowser(peer: peer, serviceType: name)
        self.session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .Required)
        
        super.init()
        
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        
        browser.delegate = self
        browser.startBrowsingForPeers()
        
        session.delegate = self
    }
    
    deinit {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
    }
    
    internal func sendRequest(key: Key, toPeers peers: [MCPeerID]) {
        let message: Message = .Request(key)
        sendMessage(message, toPeers: peers)
    }
    
    internal func sendResponse(key: Key, value: Value?, toPeers peers: [MCPeerID]) {
        let message: Message = .Response(key, value)
        sendMessage(message, toPeers: peers)
    }
    
    internal func sendInsert(keys: [Key], toPeers peers: [MCPeerID]) {
        let message: Message = .Insert(keys)
        sendMessage(message, toPeers: peers)
    }
    
    internal func sendDelete(keys: [Key], toPeers peers: [MCPeerID]) {
        let message: Message = .Delete(keys)
        sendMessage(message, toPeers: peers)
    }
    
    private func sendMessage(message: Message, toPeers peers: [MCPeerID]) {
        let data = message.toData()
        try! session.sendData(data, toPeers: peers, withMode: .Reliable)
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension Session: MCNearbyServiceAdvertiserDelegate {
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        invitationHandler(true, session)
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {}
}

// MARK: - MCNearbyServiceBrowserDelegate

extension Session: MCNearbyServiceBrowserDelegate {
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, toSession: session, withContext: nil, timeout: 10)
    }
    
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {}
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}

// MARK: - MCSessionDelegate

extension Session: MCSessionDelegate {
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        switch state {
        case .Connected:
            delegate?.session(self, peerDidConnect: peerID)
        case .NotConnected:
            delegate?.session(self, peerDidDisconnect: peerID)
        default:
            break
        }
    }
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        guard let message = Message(data: data) else { return }
        
        switch message {
        case let .Request(key):
            delegate?.session(self, didReceiveRequestForKey: key, fromPeer: peerID)
        case let .Response(key, value):
            delegate?.session(self, didReceiveResponseWithKey: key, andValue: value, fromPeer: peerID)
        case let .Insert(keys):
            delegate?.session(self, didReceiveInsertForKeys: keys, fromPeer: peerID)
        case let .Delete(keys):
            delegate?.session(self, didReceiveDeleteForKeys: keys, fromPeer: peerID)
        }
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {}
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {}
}