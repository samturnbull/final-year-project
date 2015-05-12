//
//  SessionContainer.m
//  Project2
//
//  Created by Sam Turnbull on 05/03/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

#import "SessionContainer.h"
#import "Photo.h"

@interface SessionContainer() <MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate>

@property (strong, nonatomic) MCNearbyServiceAdvertiser *advertiser;
@property (strong, nonatomic) MCNearbyServiceBrowser *browser;
@property (strong, nonatomic) NSTimer *timer;
@end

@implementation SessionContainer

- (id)initWithDisplayName:(NSString *)displayName serviceType:(NSString *)serviceType
{
    if (self = [super init]) {
        MCPeerID *peerID = [[MCPeerID alloc] initWithDisplayName:displayName];
        _session = [[MCSession alloc] initWithPeer:peerID securityIdentity:nil encryptionPreference:MCEncryptionRequired];
        _session.delegate = self;
        _advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:peerID discoveryInfo:nil serviceType:serviceType];
        [_advertiser startAdvertisingPeer];
        _advertiser.delegate = self;
        
        _browser = [[MCNearbyServiceBrowser alloc] initWithPeer:peerID serviceType:serviceType];
        [_browser startBrowsingForPeers];
        _browser.delegate = self;
        
        // request connected peers array every 5 seconds. removed due to bugs
        //self.timer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(requestConnectedPeersArrayFromAllPeers) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)invalidateSessionContainer
{
    [_timer invalidate];
    [_advertiser stopAdvertisingPeer];
    [_browser stopBrowsingForPeers];
    [_session disconnect];
}

- (void)dealloc
{
    [self invalidateSessionContainer];
}

- (NSString *)stringForPeerConnectionState:(MCSessionState)state
{
    switch (state) {
        case MCSessionStateConnected:
            return @"Connected";

        case MCSessionStateConnecting:
            return @"Connecting";

        case MCSessionStateNotConnected:
            return @"Not Connected";
    }
}

#pragma mark - Public methods

- (void)sendToAllPeersPhoto:(UIImage *)photo withName:(NSString *)name
{
    for (MCPeerID *peer in self.session.connectedPeers) {
        [self sendPhoto:photo withName:name toPeer:peer];
    }
}

- (void)sendToAllPeersPhotoAtURL:(NSURL *)imageUrl withName:(NSString *)name
{
    for (MCPeerID *peer in self.session.connectedPeers) {
        [self sendPhotoAtURL:imageUrl withName:name toPeer:peer];
    }
}

- (void)sendToAllPeersPhotoWithData:(NSData *)data withName:(NSString *)name
{
    for (MCPeerID *peer in self.session.connectedPeers) {
        [self sendPhotoWithData:data withName:name toPeer:peer];
    }
}

- (void)sendPhoto:(UIImage *)photo withName:(NSString *)name toPeer:(MCPeerID *)peer
{
    NSData *jpegData = UIImageJPEGRepresentation(photo, 0);
    [self sendPhotoWithData:jpegData withName:name toPeer:peer];
}

- (void)sendPhotoWithData:(NSData *)data withName:(NSString *)name toPeer:(MCPeerID *)peer
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:name];
        [data writeToFile:filePath atomically:YES];
        NSURL *photoURL = [NSURL fileURLWithPath:filePath];
        
        [self sendPhotoAtURL:photoURL withName:name toPeer:peer];
    });
}

- (void)sendPhotoAtURL:(NSURL *)imageUrl withName:(NSString *)name toPeer:(MCPeerID *)peer
{
    if(imageUrl){
        [self.session sendResourceAtURL:imageUrl withName:name toPeer:peer withCompletionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"Send resource to peer [%@] completed with Error [%@]", peer.displayName, error);
            }
            else {
                NSLog(@"Transfer complete to peer [%@]", peer.displayName);
            }
        }];
    }
}

- (void)sendRequestForPhotoIDsArrayToPeer:(MCPeerID *)peer
{
    NSLog(@"sending request for array of photos uniques to peer [%@]", peer.displayName);
    NSData *request = [NSKeyedArchiver archivedDataWithRootObject:[NSString stringWithFormat:@"uniques"]];
    [self.session sendData:request toPeers:@[peer] withMode:MCSessionSendDataReliable error:nil];
}


- (void)sendPhotoIDsArray:(NSArray *)photoIDs toPeer:(MCPeerID *)peer
{
    NSLog(@"sending array of [%d] photo IDs to peer [%@]", (int)[photoIDs count], peer.displayName);
    NSData *request = [NSKeyedArchiver archivedDataWithRootObject:photoIDs];
    [self.session sendData:request toPeers:@[peer] withMode:MCSessionSendDataReliable error:nil];
}

#pragma mark - Maintain connection methods

- (void)requestConnectedPeersArrayFromAllPeers
{
    //send request in data form
    NSData *request = [NSKeyedArchiver archivedDataWithRootObject:[NSString stringWithFormat:@"peers"]];
    [self.session sendData:request toPeers:self.session.connectedPeers withMode:MCSessionSendDataReliable error:nil];
}

- (void)receivedRequestForConnectedPeersArrayFromPeer:(MCPeerID *)peer
{
    NSLog(@"received request for connected peers from %@", peer.displayName);
    
    //send connected peers to peer
    NSData *connectedPeers = [NSKeyedArchiver archivedDataWithRootObject:self.session.connectedPeers];
    [self.session sendData:connectedPeers toPeers:self.session.connectedPeers withMode:MCSessionSendDataReliable error:nil];
}

- (void)receivedConnectedPeersArray:(NSArray *)array FromPeer:(MCPeerID *)peer
{
    NSLog(@"received connected peers array %@ from peer %@", array, peer.displayName);
    
    //check if there's any peers i'm not connected to, and send them an invite
    for (MCPeerID *peerID in array) {
        //check that the peer isn't myself
        if (![peerID.displayName isEqualToString:self.session.myPeerID.displayName]) {
            if (![self.session.connectedPeers containsObject:peerID]) {
                NSLog(@"peer %@ is connected to peer %@ and I am not, so I will send an invite", peer, peerID);
                [self.browser invitePeer:peerID toSession:self.session withContext:nil timeout:30];
            }
        }
    }
}

#pragma mark - MCSessionDelegate methods

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSLog(@"Peer [%@] changed state to %@", peerID.displayName, [self stringForPeerConnectionState:state]);
    
    if (state == MCSessionStateConnected) {
        [self.delegate connectedToPeer:peerID];
    }
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    //check if data is the connected peers array or a request for connected peers array
    
    //if it's an array
    if ([[NSKeyedUnarchiver unarchiveObjectWithData:data] isKindOfClass:[NSArray class]]) {
        NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        //if contains MCPeerIDs
//        if ([[array firstObject] isKindOfClass:[MCPeerID class]]) {
//            [self receivedConnectedPeersArray:array FromPeer:peerID];
//        }
        //if it contains strings
        [self.delegate receivedPhotoIDsArray:array fromPeer:peerID];
        
    }
    //if it's a string
    else if ([[NSKeyedUnarchiver unarchiveObjectWithData:data] isKindOfClass:[NSString class]]) {
        NSString *string = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        //if the request is for the connected peers array
        if ([string isEqualToString:@"peers"]) {
            [self receivedRequestForConnectedPeersArrayFromPeer:peerID];
        }
        //if the request is for the array of photo uniques
        else if ([string isEqualToString:@"uniques"]) {
            [self.delegate receivedRequestForPhotoIDsArrayFromPeer:peerID];
        }
        
    }
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    NSLog(@"Start receiving resource [%@] from peer %@ with progress [%@]", resourceName, peerID.displayName, progress);
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error [%@] receiving resource from peer %@ ", [error localizedDescription], peerID.displayName);
    }
    else
    {
        [self.delegate receivedPhotoAtURL:localURL withName:resourceName fromPeer:peerID];
    }
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    NSLog(@"Received data over stream with name %@ from peer %@", streamName, peerID.displayName);
}

#pragma mark - MCNearbyServiceAdvertiser delegate

-(void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler
{
    NSLog(@"Received invitation from peer %@", peerID.displayName);
    if ([self.session.connectedPeers containsObject:peerID]) {
        NSLog(@"received invite from peer already in connected peers");
    }
    invitationHandler(YES, self.session);
}

#pragma mark - MCNearbyServiceBrowser delegate

-(void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    NSLog(@"Found a peer with display name %@", peerID.displayName);
    [self.browser invitePeer:peerID toSession:self.session withContext:nil timeout:30];
}

-(void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"Lost peer: %@", peerID.displayName);
    if ([self.session.connectedPeers containsObject:peerID]) {
        NSLog(@"Lost peer %@ but peer still in connectedPeers", peerID.displayName);
    }
}

@end
