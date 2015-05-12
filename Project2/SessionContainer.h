//
//  SessionContainer.h
//  Project2
//
//  Created by Sam Turnbull on 05/03/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

@import MultipeerConnectivity;

#import <Foundation/Foundation.h>

@protocol SessionContainerDelegate;

@interface SessionContainer : NSObject <MCSessionDelegate>

@property (readonly, nonatomic) MCSession *session;
@property (assign, nonatomic) id<SessionContainerDelegate> delegate;

- (id)initWithDisplayName:(NSString *)displayName serviceType:(NSString *)serviceType;
- (void)invalidateSessionContainer;

- (void)sendToAllPeersPhoto:(UIImage *)photo withName:(NSString *)name;
- (void)sendToAllPeersPhotoAtURL:(NSURL *)imageUrl withName:(NSString *)name;
- (void)sendToAllPeersPhotoWithData:(NSData *)data withName:(NSString *)name;

- (void)sendPhoto:(UIImage *)photo withName:(NSString *)name toPeer:(MCPeerID *)peer;
- (void)sendPhotoAtURL:(NSURL *)imageUrl withName:(NSString *)name toPeer:(MCPeerID *)peer;
- (void)sendPhotoWithData:(NSData *)data withName:(NSString *)name toPeer:(MCPeerID *)peer;

- (void)sendRequestForPhotoIDsArrayToPeer:(MCPeerID *)peer;
- (void)sendPhotoIDsArray:(NSArray *)photos toPeer:(MCPeerID *)peer;

@end

@protocol SessionContainerDelegate <NSObject>

- (void)receivedPhotoAtURL:(NSURL *)imageUrl withName:(NSString *)name fromPeer:(MCPeerID *)peer;
- (void)connectedToPeer:(MCPeerID *)peer;

- (void)receivedRequestForPhotoIDsArrayFromPeer:(MCPeerID *)peer;
- (void)receivedPhotoIDsArray:(NSArray *)photos fromPeer:(MCPeerID *)peer;

@end
