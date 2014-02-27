
#import "MatchmakingServer.h"
#include "MatchmakingProtocol.h"

@implementation MatchmakingServer
@synthesize session;
@synthesize connectedClients;

- (id)init
{
	if ((self = [super init]))
	{
		_serverState = ServerStateIdle;
	}
	return self;
}

- (void)startAcceptingConnectionsForSessionID:(NSString *)sessionID displayName:(NSString *)displayName
{
    if (_serverState == ServerStateIdle)
	{
        _maxClients = 3;
		_serverState = ServerStateAcceptingConnections;
        self.connectedClients = [NSMutableArray arrayWithCapacity:_maxClients];
        self.session = [[GKSession alloc] initWithSessionID:sessionID displayName:displayName sessionMode:GKSessionModeServer];
        self.session.delegate = self;
        self.session.available = YES;
    }
}

- (void)setDelegate:(MatchmakingServerProtocol*)delegate
{
    _delegate = delegate;
}

#pragma mark - GKSessionDelegate

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
#ifdef DEBUG
	NSLog(@"MatchmakingServer: peer %@ changed state %d", peerID, state);
#endif
    
	switch (state)
	{
		case GKPeerStateAvailable:
			break;
            
		case GKPeerStateUnavailable:
			break;
            
            // A new client has connected to the server.
		case GKPeerStateConnected:
			if (_serverState == ServerStateAcceptingConnections)
			{
				if (![self.connectedClients containsObject:peerID])
				{
					[self.connectedClients addObject:peerID];
                    _delegate->clientDidConnect(self, peerID);
				}
			}
			break;
            
            // A client has disconnected from the server.
		case GKPeerStateDisconnected:
			if (_serverState != ServerStateIdle)
			{
				if ([self.connectedClients containsObject:peerID])
				{
					[self.connectedClients removeObject:peerID];
                    _delegate->clientDidDisconnect(self, peerID);
				}
			}
			break;
            
		case GKPeerStateConnecting:
			break;
	}
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
#ifdef DEBUG
	NSLog(@"MatchmakingServer: connection request from peer %@", peerID);
#endif
	if (_serverState == ServerStateAcceptingConnections && self.connectedClients.count < _maxClients)
	{
		NSError *error;
		if ([self.session acceptConnectionFromPeer:peerID error:&error])
			NSLog(@"MatchmakingServer: Connection accepted from peer %@", peerID);
		else
			NSLog(@"MatchmakingServer: Error accepting connection from peer %@, %@", peerID, error);
	}
	else  // not accepting connections or too many clients
	{
		[self.session denyConnectionFromPeer:peerID];
	}
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
#ifdef DEBUG
	NSLog(@"MatchmakingServer: connection with peer %@ failed %@", peerID, error);
#endif
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
#ifdef DEBUG
	NSLog(@"MatchmakingServer: session failed %@", error);
#endif
    
	if ([[error domain] isEqualToString:GKSessionErrorDomain])
	{
		if ([error code] == GKSessionCannotEnableError)
		{
            _delegate->serverNoNetwork(self);
			[self endSession];
		}
	}
}

- (NSString *)peerIDForConnectedClientAtIndex:(NSUInteger)index
{
	return [self.connectedClients objectAtIndex:index];
}

- (NSString *)displayNameForPeerID:(NSString *)peerID
{
	return [self.session displayNameForPeer:peerID];
}

- (void)endSession
{
	NSAssert(_serverState != ServerStateIdle, @"Wrong state");
	_serverState = ServerStateIdle;
	[self.session disconnectFromAllPeers];
	self.session.available = NO;
	self.session.delegate = nil;
	self.session = nil;
	self.connectedClients = nil;
    _delegate->sessionDidEnd(self);
}

@end
