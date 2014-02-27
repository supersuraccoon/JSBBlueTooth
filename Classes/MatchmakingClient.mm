
#import "MatchmakingClient.h"
#include "MatchmakingProtocol.h"

@implementation MatchmakingClient
@synthesize session;
@synthesize availableServers;
@synthesize serverPeerID;

- (id)init
{
	if ((self = [super init]))
	{
		_clientState = ClientStateIdle;
	}
	return self;
}

- (void)startSearchingForServersWithSessionID:(NSString *)sessionID displayName:(NSString *)displayName
{
	if (_clientState == ClientStateIdle)
	{
		_clientState = ClientStateSearchingForServers;
        self.availableServers = [NSMutableArray arrayWithCapacity:1];
        self.session = [[GKSession alloc] initWithSessionID:sessionID displayName:displayName sessionMode:GKSessionModeClient];
        self.session.delegate = self;
        self.session.available = YES;
	}
}

- (void)setDelegate:(MatchmakingClientProtocol*)delegate
{
    _delegate = delegate;
}

- (void)connectToServerWithPeerID:(NSString *)peerID
{
	NSAssert(_clientState == ClientStateSearchingForServers, @"Wrong state");
	_clientState = ClientStateConnecting;
	self.serverPeerID = peerID;
	[self.session connectToPeer:peerID withTimeout:self.session.disconnectTimeout];
}

#pragma mark - GKSessionDelegate

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
#ifdef DEBUG
	NSLog(@"MatchmakingClient: peer %@ changed state %d", peerID, state);
#endif
	switch (state)
	{
            // The client has discovered a new server.
		case GKPeerStateAvailable:
			if (_clientState == ClientStateSearchingForServers)
			{
				if (![self.availableServers containsObject:peerID])
				{
					[self.availableServers addObject:peerID];
                    _delegate->serverBecameAvailable(self, peerID);
				}
			}
			break;
            
            // The client sees that a server goes away.
		case GKPeerStateUnavailable:
			if (_clientState == ClientStateSearchingForServers)
			{
				if ([self.availableServers containsObject:peerID])
				{
					[self.availableServers removeObject:peerID];
                    _delegate->serverBecameUnavailable(self, peerID);
				}
			}
            // Is this the server we're currently trying to connect with?
			if (_clientState == ClientStateConnecting && [peerID isEqualToString:self.serverPeerID])
			{
				[self disconnectFromServer];
			}
			break;
            
            // You're now connected to the server.
		case GKPeerStateConnected:
			if (_clientState == ClientStateConnecting)
			{
				_clientState = ClientStateConnected;
			}		
			break;
            
            // You're now no longer connected to the server.
		case GKPeerStateDisconnected:
			if (_clientState == ClientStateConnected)
			{
				[self disconnectFromServer];
			}
			break;
            
		case GKPeerStateConnecting:
			break;
	}	
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
#ifdef DEBUG
	NSLog(@"MatchmakingClient: connection request from peer %@", peerID);
#endif
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
#ifdef DEBUG
	NSLog(@"MatchmakingClient: connection with peer %@ failed %@", peerID, error);
#endif
    
	[self disconnectFromServer];
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
#ifdef DEBUG
	NSLog(@"MatchmakingClient: session failed %@", error);
#endif
    
	if ([[error domain] isEqualToString:GKSessionErrorDomain])
	{
		if ([error code] == GKSessionCannotEnableError)
		{
            _delegate->clientNoNetwork(self);
			[self disconnectFromServer];
		}
	}
}

- (NSString *)peerIDForAvailableServerAtIndex:(NSUInteger)index
{
	return [self.availableServers objectAtIndex:index];
}

- (NSString *)displayNameForPeerID:(NSString *)peerID
{
	return [self.session displayNameForPeer:peerID];
}

- (void)disconnectFromServer
{
	NSAssert(_clientState != ClientStateIdle, @"Wrong state");
    
	_clientState = ClientStateIdle;
    
	[self.session disconnectFromAllPeers];
	self.session.available = NO;
	self.session.delegate = nil;
	self.session = nil;
    
	self.availableServers = nil;
    _delegate->didDisconnectFromServer(self, self.serverPeerID);
	self.serverPeerID = nil;
}

- (void)dealloc
{
#ifdef DEBUG
	NSLog(@"dealloc %@", self);
#endif
    [super dealloc];
}

@end
