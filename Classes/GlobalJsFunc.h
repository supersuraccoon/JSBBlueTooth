#ifndef  _GLOBAL_JS_FUNC_H_
#define  _GLOBAL_JS_FUNC_H_

#include "ScriptingCore.h"
#include "AppDelegate.h"

extern jsval jsCallerObject;
extern AppDelegate *gAppDelegate;
extern JSFunctionSpec js_global_functions[];

JSBool beServer(JSContext *cx, uint32_t argc, jsval *vp);
JSBool beClient(JSContext *cx, uint32_t argc, jsval *vp);
JSBool joinServer(JSContext *cx, uint32_t argc, jsval *vp);
JSBool endSession(JSContext *cx, uint32_t argc, jsval *vp);
JSBool disconnectFromServer(JSContext *cx, uint32_t argc, jsval *vp);

void tirggerFunc(string funcToTrigger);
void tirggerFuncWithString(string funcToTrigger, NSString *message);
void tirggerFuncWithString(string funcToTrigger, string message);

#endif // _GLOBAL_JS_FUNC_H_

