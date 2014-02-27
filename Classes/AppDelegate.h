#ifndef  _APP_DELEGATE_H_
#define  _APP_DELEGATE_H_

#include "CCApplication.h"

#include "MatchmakingClient.h"
#include "MatchmakingServer.h"
#include "MatchmakingProtocol.h"

class  AppDelegate : private cocos2d::CCApplication, public MatchmakingClientProtocol, public MatchmakingServerProtocol
{
public:
    AppDelegate();
    virtual ~AppDelegate();
    virtual bool applicationDidFinishLaunching();
    virtual void applicationDidEnterBackground();
    virtual void applicationWillEnterForeground();
    
    void serverBecameAvailable(MatchmakingClient* client, NSString* peerID);
    void serverBecameUnavailable(MatchmakingClient* client, NSString* peerID);
    void didDisconnectFromServer(MatchmakingClient* client, NSString* peerID);
    void clientNoNetwork(MatchmakingClient* client);
    
    void clientDidConnect(MatchmakingServer* server, NSString* peerID);
    void clientDidDisconnect(MatchmakingServer* server, NSString* peerID);
    void sessionDidEnd(MatchmakingServer* server);
    void serverNoNetwork(MatchmakingServer* server);
	
	MatchmakingServer* matchmakingServer;
	MatchmakingClient* matchmakingClient;
	void beServer();
	void beClient();
    void joinServer(const char* peerID);
    void endSession();
    void disconnectFromServer();
};

#endif // _APP_DELEGATE_H_

