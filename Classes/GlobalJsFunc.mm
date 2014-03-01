#include "GlobalJsFunc.h"

jsval jsCallerObject;
AppDelegate *gAppDelegate = NULL;

JSBool beServer(JSContext *cx, uint32_t argc, jsval *vp) {
    CCLOG("SpiderMonkey::beServer");
    jsval *argv = JS_ARGV(cx, vp);
    jsCallerObject = argv[0];
    gAppDelegate->beServer();
    JS_SET_RVAL(cx, vp, JSVAL_NULL);
    return JS_TRUE;
}

JSBool beClient(JSContext *cx, uint32_t argc, jsval *vp) {
    CCLOG("SpiderMonkey::beClient");
    jsval *argv = JS_ARGV(cx, vp);
    jsCallerObject = argv[0];
    gAppDelegate->beClient();
    JS_SET_RVAL(cx, vp, JSVAL_NULL);
    return JS_TRUE;
}

JSBool joinServer(JSContext *cx, uint32_t argc, jsval *vp) {
    CCLOG("SpiderMonkey::joinServer");
    jsval *argv = JS_ARGV(cx, vp);
    jsval peerIDJSV = argv[0];
    jsCallerObject = argv[1];
    string peerID;
    jsval_to_std_string(cx, peerIDJSV, &peerID);
    gAppDelegate->joinServer(peerID.c_str());
    JS_SET_RVAL(cx, vp, JSVAL_NULL);
    return JS_TRUE;
}

JSBool endSession(JSContext *cx, uint32_t argc, jsval *vp) {
    CCLOG("SpiderMonkey::endSession");
    jsval *argv = JS_ARGV(cx, vp);
    jsCallerObject = argv[0];
    gAppDelegate->endSession();
    JS_SET_RVAL(cx, vp, JSVAL_NULL);
    return JS_TRUE;
}

JSBool disconnectFromServer(JSContext *cx, uint32_t argc, jsval *vp) {
    CCLOG("SpiderMonkey::disconnectFromServer");
    jsval *argv = JS_ARGV(cx, vp);
    jsCallerObject = argv[0];
    gAppDelegate->disconnectFromServer();
    JS_SET_RVAL(cx, vp, JSVAL_NULL);
    return JS_TRUE;
}

JSBool sendPacket(JSContext *cx, uint32_t argc, jsval *vp) {
    CCLOG("SpiderMonkey::sendPacket");
    jsval *argv = JS_ARGV(cx, vp);
    jsval roleJSV = argv[0];
    jsval packetTypeJSV = argv[1];
    jsval packetMessageJSV = argv[2];
    jsCallerObject = argv[3];
    int role = JSVAL_TO_INT(roleJSV);
    int packetType = JSVAL_TO_INT(packetTypeJSV);
    string packetMessage;
    jsval_to_std_string(cx, packetMessageJSV, &packetMessage);
    gAppDelegate->sendPacket(role, (PacketType)packetType, packetMessage.c_str());
    JS_SET_RVAL(cx, vp, JSVAL_NULL);
    return JS_TRUE;
}

void tirggerFunc(string funcToTrigger) {
    ScriptingCore* sc = ScriptingCore::getInstance();
	if (sc) {
		sc->executeFunctionWithOwner(jsCallerObject, funcToTrigger.c_str(), 0, NULL, NULL);
	}
}

void tirggerFuncWithString(string funcToTrigger, NSString *message) {
    ScriptingCore* sc = ScriptingCore::getInstance();
	if (sc) {
		JSString *messageJSS = JS_NewStringCopyZ(sc->getGlobalContext(), [message cStringUsingEncoding:[NSString defaultCStringEncoding]]);
		jsval dataVal = STRING_TO_JSVAL(messageJSS);
		sc->executeFunctionWithOwner(jsCallerObject, funcToTrigger.c_str(), 1, &dataVal, NULL);
	}
}

void tirggerFuncWithString(string funcToTrigger, string message) {
    ScriptingCore* sc = ScriptingCore::getInstance();
	if (sc) {
		JSString *messageJSS = JS_NewStringCopyZ(sc->getGlobalContext(), message.c_str());
		jsval dataVal = STRING_TO_JSVAL(messageJSS);
		sc->executeFunctionWithOwner(jsCallerObject, funcToTrigger.c_str(), 1, &dataVal, NULL);
	}
}

JSFunctionSpec js_global_functions[] = {
    JS_FS("beServer", beServer, 1, 0),
    JS_FS("beClient", beClient, 1, 0),
	JS_FS("joinServer", joinServer, 2, 0),
	JS_FS("endSession", endSession, 1, 0),
	JS_FS("disconnectFromServer", disconnectFromServer, 1, 0),
    JS_FS("sendPacket", sendPacket, 4, 0),
    JS_FS_END
};
