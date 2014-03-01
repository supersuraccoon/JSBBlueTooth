
var TAG_SERVER_LIST_LAYER = 1001;
var TAG_SERVER_LIST_MENU = 1002;
var TAG_CLIENT_LIST_LAYER = 1003;
var TAG_CLIENT_LIST_MENU = 1004;
var TAG_MENU_SERVER_CLIENT = 1005;
var TAG_MENU_ABORT = 1006;
var TAG_MENU_START = 1007;
var TAG_EDIT_BOX = 1008;

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
		this.gameStart = false;
		this.createServerClientMenu();

        this.log = cc.LabelTTF.create("Be Server or Be Client???", "Impact", 36);
        this.log.setPosition(this.winSize.width * 0.5, this.winSize.height * 0.05);
        this.addChild(this.log);

        return true;
    },
	createServerClientMenu:function() {
        cc.MenuItemFont.setFontName("Impact");
        cc.MenuItemFont.setFontSize(36);
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
	createStartGameMenu:function() {
        var item1 = cc.MenuItemFont.create("Start Game", this.startGameSelector, this);
        var menu = cc.Menu.create(item1);
        menu.setPosition(cc.p(this.winSize.width * 0.5, this.winSize.height * 0.2));
        menu.alignItemsHorizontallyWithPadding(40);
        this.addChild(menu, 1, TAG_MENU_START);
	},
	createEditBox:function() {
        var editBoxSprite = cc.Scale9Sprite.create(s_Editbox);
        var editBox = cc.EditBox.create(cc.size(this.winSize.width * 0.4, 50), editBoxSprite);
        editBox.setPosition(cc.p(this.winSize.width * 0.5, this.winSize.height * 0.5));
        editBox.setFont("Impact", 36);
        editBox.setPlaceholderFontColor(cc.BLACK);
        editBox.setPlaceHolder("Input Message");
        editBox.setFontColor(cc.BLACK);
        editBox.setDelegate(this);
        this.addChild(editBox, 0, TAG_EDIT_BOX);
	},
    updateServerList:function() {
    	this.removeChildByTag(TAG_SERVER_LIST_LAYER, true);
    	this.removeChildByTag(TAG_SERVER_LIST_MENU, true);
		var serverListLayer = cc.LayerColor.create(cc.c4b(50, 50, 50, 255), this.winSize.width * 0.8, this.winSize.height * 0.7);
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
		var clientListLayer = cc.LayerColor.create(cc.c4b(50, 50, 50, 255), this.winSize.width * 0.8, this.winSize.height * 0.7);
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
		this.removeChildByTag(TAG_MENU_START, true);
		if (this.clientList.length > 0) {
			this.createStartGameMenu();
		}
	},
	// editbox delegate
	editBoxReturn:function(editBox) {
        sendPacket(this.role, 1, editBox.getText(), this);
    },
	// selector
    beServerSelector:function(sender) {
		cc.log("JS::beServerSelector");
		this.removeChildByTag(TAG_MENU_SERVER_CLIENT, true);
		this.createAbortConnectionMenu();
		this.updateClientList();
        this.log.setString("You are server waiting for clients ...");
        beServer(this);
		this.role = 0;
    },
    beClientSelector:function(sender) {
		cc.log("JS::beClientSelector");
		this.removeChildByTag(TAG_MENU_SERVER_CLIENT, true);
		this.menu = null;
		this.updateServerList();
        this.log.setString("You are client looking for servers ...");
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
		this.removeChildByTag(TAG_EDIT_BOX, true);
		if (this.role == 0)  {
	    	endSession(this);
	    	this.removeChildByTag(TAG_SERVER_LIST_LAYER, true);
		}
		else {
			disconnectFromServer(this);
			this.removeChildByTag(TAG_CLIENT_LIST_LAYER, true);
		}
		this.gameStart = false;
	},
	startGameSelector:function(sender) {
		cc.log("JS::startGameSelector");
		this.removeChildByTag(TAG_CLIENT_LIST_LAYER, true);
		this.removeChildByTag(TAG_MENU_ABORT, true);
		this.removeChildByTag(TAG_MENU_START, true);
		this.removeChildByTag(TAG_CLIENT_LIST_MENU, true);
		this.removeChildByTag(TAG_CLIENT_LIST_LAYER, true);
		this.log.setString("Start game as Server");
		sendPacket(0, 1, "Game Start", this);
		this.gameStart = true;
		this.createAbortConnectionMenu();
		this.createEditBox();
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
		this.removeChildByTag(TAG_EDIT_BOX, true);
		this.removeChildByTag(TAG_MENU_ABORT, true);
		this.createServerClientMenu();
		this.log.setString("Be Server or Be Client???");
		this.gameStart = false;
	},
	serverReceiveData:function(message) {
		cc.log("JS::serverReceiveData: " + message);
		this.log.setString("Received Message: " + message);
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
		if (!this.gameStart)
			this.updateClientList();
		this.gameStart = false;
    },
	sessionDidEnd:function(peerID) {
        cc.log("JS::sessionDidEnd");
        this.removeChildByTag(TAG_MENU_ABORT, true);
        this.removeChildByTag(TAG_MENU_START, true);
        this.removeChildByTag(TAG_CLIENT_LIST_LAYER, true);
    	this.removeChildByTag(TAG_CLIENT_LIST_MENU, true);
        this.createServerClientMenu();
        this.log.setString("Be Server or Be Client???");
        this.gameStart = false;
    },
	serverNoNetwork:function() {
        cc.log("JS::serverNoNetwork");
    },
    clientReceiveData:function(message) {
		cc.log("JS::clientReceiveData: " + message);
		this.log.setString("Received Message: " + message);
		if (message == "Game Start") {
			this.gameStart = true;
			this.createEditBox();
		}
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
