
var TAG_SERVER_LIST_LAYER = 1001;
var TAG_SERVER_LIST_MENU = 1002;
var TAG_CLIENT_LIST_LAYER = 1003;
var TAG_CLIENT_LIST_MENU = 1004;
var TAG_MENU_SERVER_CLIENT = 1005;
var TAG_MENU_ABORT = 1006;
var TAG_MENU_START = 1007;

var MyLayer = cc.Layer.extend({
    ctor:function() {
        this._super();
        cc.associateWithNative( this, cc.Layer );
    },
    init:function () {
        this._super();
        //this.setTouchEnabled(true);
		this.count = 0;
        this.winSize = cc.Director.getInstance().getWinSize();
		this.serverList = [];
		this.clientList = [];
		this.role = 0; // 0 - server; 1 - client
		this.createServerClientMenu();

        this.log = cc.LabelTTF.create("Be Server or Be Client???", "Impact", 32);
        this.log.setPosition(this.winSize.width * 0.5, this.winSize.height * 0.05);
        this.addChild(this.log);

        return true;
    },
	createServerClientMenu:function() {
        cc.MenuItemFont.setFontName("Impact");
        cc.MenuItemFont.setFontSize(32);
        var item1 = cc.MenuItemFont.create("Be Server", this.beServerSelector, this);
        var item2 = cc.MenuItemFont.create("Be Client", this.beClientSelector, this);
        var menu = cc.Menu.create(item1, item2);
        menu.setPosition(cc.p(this.winSize.width * 0.5, this.winSize.height * 0.9));
        menu.alignItemsHorizontallyWithPadding(40);
        this.addChild(menu, 0, TAG_MENU_SERVER_CLIENT);
	},
	createAbortConnectionMenu:function() {
        var item1 = cc.MenuItemFont.create("Abort Connection", this.abortConnectionSelector, this);
        var menu = cc.Menu.create(item1);
        menu.setPosition(cc.p(this.winSize.width * 0.5, this.winSize.height * 0.9));
        menu.alignItemsHorizontallyWithPadding(40);
        this.addChild(menu, 0, TAG_MENU_ABORT);
	},
	createStartPlayMenu:function() {
        var item1 = cc.MenuItemFont.create("Start Play", this.startPlaySelector, this);
        var menu = cc.Menu.create(item1);
        menu.setPosition(cc.p(this.winSize.width * 0.7, this.winSize.height * 0.9));
        menu.alignItemsHorizontallyWithPadding(40);
        this.addChild(menu, 0, TAG_MENU_START);
	},
    updateServerList:function() {
    	this.removeChildByTag(TAG_SERVER_LIST_LAYER, true);
    	this.removeChildByTag(TAG_SERVER_LIST_MENU, true);
		var serverListLayer = cc.LayerColor.create(cc.c4b(200, 200, 200, 200), this.winSize.width * 0.8, this.winSize.height * 0.7);
		serverListLayer.setPosition(cc.p(this.winSize.width * 0.1, this.winSize.height * 0.1));
		this.addChild(serverListLayer, 0, TAG_SERVER_LIST_LAYER);
		
		var serverMenu = cc.Menu.create();
		serverMenu.setPosition(cc.p(this.winSize.width * 0.5, this.winSize.height * 0.5));
		for (var i in this.serverList) {
			var peerID = this.serverList[i];
			var serverItem = cc.MenuItemFont.create("Join " + peerID, this.joinServerSelector, this);
			serverItem.peerID = peerID;
			serverMenu.addChild(serverItem);
		}
		serverMenu.alignItemsVerticallyWithPadding(40);
		this.addChild(serverMenu, 0, TAG_SERVER_LIST_MENU);
	},
	updateClientList:function() {
		this.removeChildByTag(TAG_CLIENT_LIST_LAYER, true);
    	this.removeChildByTag(TAG_CLIENT_LIST_MENU, true);
		var clientListLayer = cc.LayerColor.create(cc.c4b(200, 200, 200, 200), this.winSize.width * 0.8, this.winSize.height * 0.7);
		clientListLayer.setPosition(cc.p(this.winSize.width * 0.1, this.winSize.height * 0.1));
		this.addChild(clientListLayer, 0, TAG_CLIENT_LIST_LAYER);

		var clientMenu = cc.Menu.create();
		clientMenu.setPosition(cc.p(this.winSize.width * 0.5, this.winSize.height * 0.5));
		for (var i in this.clientList) {
			var peerID = this.clientList[i];
			var clientItem = cc.MenuItemFont.create("Client Joined " + peerID, this.clientSelector, this);
			clientItem.peerID = peerID;
			clientMenu.addChild(clientItem);
		}
		clientMenu.alignItemsVerticallyWithPadding(40);
		this.addChild(clientMenu, 0, TAG_CLIENT_LIST_MENU);
	},
	// selector
    beServerSelector:function(sender) {
		cc.log("JS::beServerSelector");
		this.removeChildByTag(TAG_MENU_SERVER_CLIENT, true);
		this.createAbortConnectionMenu();
		this.createStartPlayMenu();
        this.log.setString("You are server waiting for client ...");
        beServer(this);
		this.role = 0;
    },
    beClientSelector:function(sender) {
		cc.log("JS::beClientSelector");
		this.removeChildByTag(TAG_MENU_SERVER_CLIENT, true);
		this.menu = null;
		this.updateServerList();
        this.log.setString("You are client looking for server ...");
        beClient(this);
		this.role = 1;
    },
	joinServerSelector:function(sender) {
		cc.log("JS::joinServerSelector");
		this.removeChildByTag(TAG_SERVER_LIST_LAYER, true);
    	this.removeChildByTag(TAG_SERVER_LIST_MENU, true);
		this.serverList = [];
		this.log.setString("Joined game waiting for server to start");
		joinServer(sender.peerID, this);
		this.createAbortConnectionMenu();
	},
	clientSelector:function(sender) {
		cc.log("JS::clientSelector");
	},
	abortConnectionSelector:function(sender) {
		cc.log("JS::abortConnectionSelector");
		if (this.role == 0)  {
	    	endSession(this);
		}
		else
			disconnectFromServer(this);
	},
	startPlaySelector:function(sender) {
		cc.log("JS::startPlaySelector");
		this.removeChildByTag(TAG_MENU_ABORT, true);
		this.removeChildByTag(TAG_MENU_START, true);
		this.clientListLayer.removeFromParent(true);
		this.log.setString("Start game as Server");
	},
	// triggered from cpp
    serverBecameAvailable:function(peerID) {
		cc.log("JS::serverBecameAvailable");
		this.serverList.push(peerID);
		this.updateServerList();
    },
	serverBecameUnavailable:function(peerID) {
		cc.log("JS::serverBecameUnavailable");
		this.removeChildByTag(TAG_MENU_ABORT, true);
		var index = this.serverList.indexOf(peerID);
		if (index >= 0) 
			this.serverList.splice(index, 1);
		this.updateServerList();
	},
	didDisconnectFromServer:function(peerID) {
		cc.log("JS::didDisconnectFromServer");
		this.removeChildByTag(TAG_MENU_ABORT, true);
		this.createServerClientMenu();
		this.log.setString("Be Server or Be Client???");
	},
	clientNoNetwork:function() {
		cc.log("JS::clientNoNetwork");
	},
	
    clientDidConnect:function(peerID) {
        cc.log("JS::clientDidConnect");
		this.clientList.push(peerID);
		this.updateClientList();
    },
	clientDidDisconnect:function(peerID) {
        cc.log("JS::clientDidDisconnect");
		var index = this.clientList.indexOf(peerID);
		if (index >= 0) 
			this.clientList.splice(index, 1);
		this.updateClientList();
    },
	sessionDidEnd:function(peerID) {
        cc.log("JS::sessionDidEnd");
        this.removeChildByTag(TAG_MENU_ABORT, true);
        this.removeChildByTag(TAG_MENU_START, true);
        this.removeChildByTag(TAG_CLIENT_LIST_LAYER, true);
    	this.removeChildByTag(TAG_CLIENT_LIST_MENU, true);

        this.createServerClientMenu();
        this.log.setString("Be Server or Be Client???");
    },
	serverNoNetwork:function() {
        cc.log("JS::serverNoNetwork");
    },
	
	onTouchesBegan:function(touches, event) {
		this.count += 1;
		if (this.count == 1)
			this.serverBecameAvailable("test");
		else if (this.count == 2)
			this.didDisconnectFromServer("test");
    },
	randomString:function(len) {
		charSet ='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
		var randomString = '';
		for (var i = 0; i < len; i++) {
			var randomPoz = Math.floor(Math.random() * charSet.length);
			randomString += charSet.substring(randomPoz,randomPoz+1);
		}
		return randomString;
	}
});

var MyScene = cc.Scene.extend({
    ctor:function() {
        this._super();
        cc.associateWithNative( this, cc.Scene );
    },
    onEnter:function () {
        this._super();
        var layer = new MyLayer();
        this.addChild(layer);
        layer.init();
    }
});
