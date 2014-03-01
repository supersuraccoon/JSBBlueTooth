#include "AppDelegate.h"

#include "cocos2d.h"
#include "generated/jsb_cocos2dx_auto.hpp"
#include "generated/jsb_cocos2dx_extension_auto.hpp"
#include "generated/jsb_cocos2dx_studio_auto.hpp"
#include "jsb_cocos2dx_extension_manual.h"
#include "cocos2d_specifics.hpp"
#include "js_bindings_system_registration.h"
#include "jsb_opengl_registration.h"
#include "ScriptingCore.h"

#include "GlobalJsFunc.h"

USING_NS_CC;

AppDelegate::AppDelegate() {
}

AppDelegate::~AppDelegate() {
    CCScriptEngineManager::purgeSharedManager();
}

void AppDelegate::beServer() {
	CCLOG("AppDelegate::beServer");
	if (matchmakingServer == NULL) {
		matchmakingServer = [[MatchmakingServer alloc] init];
        [matchmakingServer setDelegate:gAppDelegate];
		[matchmakingServer startAcceptingConnectionsForSessionID:[NSString stringWithFormat:@"%s", "JSBBLUETOOTH"]
                                                     displayName:@""];
	}
}

void AppDelegate::beClient() {
	CCLOG("AppDelegate::beClient");
    if (matchmakingClient == NULL) {
		matchmakingClient = [[MatchmakingClient alloc] init];
        [matchmakingClient setDelegate:gAppDelegate];
		[matchmakingClient startSearchingForServersWithSessionID:[NSString stringWithFormat:@"%s", "JSBBLUETOOTH"]
                                                     displayName:@""];
	}
}

void AppDelegate::joinServer(const char* peerID) {
	CCLOG("AppDelegate::joinServer: %s", peerID);
    if (matchmakingClient) {
		[matchmakingClient connectToServerWithPeerID:[NSString stringWithFormat:@"%s", peerID]];
	}
}

void AppDelegate::endSession() {
    CCLOG("AppDelegate::endSession");
    if (matchmakingServer) {
        [matchmakingServer endSession];
    }
}

void AppDelegate::disconnectFromServer() {
    CCLOG("AppDelegate::disconnectFromServer");
    if (matchmakingClient) {
        [matchmakingClient disconnectFromServer];
    }
}

void AppDelegate::sendPacket(int role, PacketType type, const char* message) {
	CCLOG("AppDelegate::sendPacket");
    CCLOG("role: %d -- type: %d -- message: %s", role, type, message);
	Packet *packet = [Packet packetWithType:type message:[NSString stringWithFormat:@"%s", message]];
	NSData *data = [packet data];
	NSError *error;
	if (role == 0) {
		if (![matchmakingServer.session sendDataToAllPeers:data withDataMode:GKSendDataReliable error:&error]) {
			NSLog(@"Error sending data to clients: %@", error);
		}
	}
	else {
		if (![matchmakingClient.session sendDataToAllPeers:data withDataMode:GKSendDataReliable error:&error]) {
			NSLog(@"Error sending data to clients: %@", error);
		}
	}	
}

/*
    client server delegate
 */
void AppDelegate::clientReceiveData(NSData* data, NSString *peerID) {
	CCLOG("AppDelegate::clientReceiveData");
	Packet *packet = [Packet packetWithData:data];
	if (packet == nil) {
		return;
	}
    tirggerFuncWithString("clientReceiveData", packet.packetMessage);
}

void AppDelegate::serverReceiveData(NSData* data, NSString *peerID) {
	CCLOG("AppDelegate::serverReceiveData");
	Packet *packet = [Packet packetWithData:data];
	if (packet == nil) {
		return;
	}
    tirggerFuncWithString("serverReceiveData", packet.packetMessage);
}

void AppDelegate::serverBecameAvailable(MatchmakingClient* client, NSString* peerID) {
    CCLOG("AppDelegate::serverBecameAvailable");
    tirggerFuncWithString("serverBecameAvailable", peerID);
}
void AppDelegate::serverBecameUnavailable(MatchmakingClient* client, NSString* peerID) {
    CCLOG("AppDelegate::serverBecameUnavailable");
	tirggerFuncWithString("serverBecameUnavailable", peerID);
}
void AppDelegate::didDisconnectFromServer(MatchmakingClient* client, NSString* peerID) {
    CCLOG("AppDelegate::didDisconnectFromServer");
	tirggerFuncWithString("didDisconnectFromServer", peerID);
    //matchmakingClient = NULL;
}
void AppDelegate::clientNoNetwork(MatchmakingClient* client) {
    CCLOG("AppDelegate::clientNoNetwork");
	tirggerFunc("clientNoNetwork");
}

void AppDelegate::clientDidConnect(MatchmakingServer* server, NSString* peerID) {
    CCLOG("AppDelegate::serverBecameAvailable");
    tirggerFuncWithString("clientDidConnect", peerID);
}
void AppDelegate::clientDidDisconnect(MatchmakingServer* server, NSString* peerID) {
    CCLOG("AppDelegate::clientDidDisconnect");
	tirggerFuncWithString("clientDidDisconnect", peerID);
}
void AppDelegate::sessionDidEnd(MatchmakingServer* server) {
    CCLOG("AppDelegate::sessionDidEnd");
	tirggerFuncWithString("sessionDidEnd", "");
    matchmakingServer = NULL;
}
void AppDelegate::serverNoNetwork(MatchmakingServer* server) {
    CCLOG("AppDelegate::serverNoNetwork");
	tirggerFunc("serverNoNetwork");
}

/*
	application delegate
 */
bool AppDelegate::applicationDidFinishLaunching() {
    CCDirector *pDirector = CCDirector::sharedDirector();
    pDirector->setOpenGLView(CCEGLView::sharedOpenGLView());
    pDirector->setDisplayStats(false);
	
	gAppDelegate = this;
    
    ScriptingCore* sc = ScriptingCore::getInstance();
    sc->addRegisterCallback(register_all_cocos2dx);
    sc->addRegisterCallback(register_all_cocos2dx_extension);
    sc->addRegisterCallback(register_all_cocos2dx_extension_manual);
    sc->addRegisterCallback(register_cocos2dx_js_extensions);
    sc->addRegisterCallback(register_all_cocos2dx_studio);
    sc->addRegisterCallback(jsb_register_system);
    sc->addRegisterCallback(JSB_register_opengl);
    sc->start();
    
    if (!JS_DefineFunctions(sc->getGlobalContext(), sc->getGlobalObject(), js_global_functions)) {
        return false;
    }
    CCScriptEngineProtocol *pEngine = ScriptingCore::getInstance();
    CCScriptEngineManager::sharedManager()->setScriptEngine(pEngine);
    ScriptingCore::getInstance()->runScript("cocos2d-jsb.js");  
    return true;
}

void handle_signal(int signal) {
    static int internal_state = 0;
    ScriptingCore* sc = ScriptingCore::getInstance();
    CCDirector* director = CCDirector::sharedDirector();
    if (director->getRunningScene()) {
        director->popToRootScene();
    } else {
        CCPoolManager::sharedPoolManager()->finalize();
        if (internal_state == 0) {
            sc->start();
            internal_state = 1;
        } else {
            sc->runScript("cocos2d-jsb.js");
            internal_state = 0;
        }
    }
}

void AppDelegate::applicationDidEnterBackground() {
    CCDirector::sharedDirector()->stopAnimation();
}

void AppDelegate::applicationWillEnterForeground() {
    CCDirector::sharedDirector()->startAnimation();
}
