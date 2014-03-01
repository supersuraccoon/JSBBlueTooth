
#import <GameKit/GameKit.h>

typedef enum {
	ServerStateIdle,
	ServerStateAcceptingConnections,
	ServerStateIgnoringNewConnections,
}
ServerState;

class MatchmakingServerProtocol;
@interface MatchmakingServer : NSObject <GKSessionDelegate>{
@private
    MatchmakingServerProtocol* _delegate;
    ServerState _serverState;
    int _maxClients;
}

@property (nonatomic, retain) NSMutableArray *connectedClients;
@property (nonatomic, retain) GKSession *session;

- (void)setDelegate:(MatchmakingServerProtocol*)delegate;
- (void)endSession;
- (void)startAcceptingConnectionsForSessionID:(NSString *)sessionID displayName:(NSString *)displayName;
- (NSString *)peerIDForConnectedClientAtIndex:(NSUInteger)index;
- (NSString *)displayNameForPeerID:(NSString *)peerID;

@end
