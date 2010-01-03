package {

import flash.display.Bitmap;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.geom.Rectangle;
import flash.text.TextFieldAutoSize;
import flash.utils.Timer;

import caurina.transitions.Tweener;

//import fl.controls.CheckBox;
//import fl.skins.DefaultCheckBoxSkins;
import com.bit101.components.CheckBox;

import com.threerings.util.Command;
import com.threerings.util.MethodQueue;
import com.threerings.util.ValueEvent;

import aduros.display.ToolTipManager;
import aduros.display.ImageButton;
import aduros.game.Metrics;
import aduros.net.REMOTE;
import aduros.net.RemoteProvider;
import aduros.net.RemoteProxy;
import aduros.util.F;

import com.whirled.avrg.*;
import com.whirled.game.GameContentEvent;
import com.whirled.net.*;
import com.whirled.*;

public class Game extends Sprite
{
    public static var metrics :Metrics;
    //DefaultCheckBoxSkins;

    public function Game ()
    {
        _ctrl = new AVRGameControl(this);

        if ( ! _ctrl.isConnected()) {
            return;
        }

        metrics = new Metrics(_ctrl, this, BuildConfig.ANALYTICS_ID);

        new RemoteProvider(_ctrl.game, "c", F.konst(this));
        new RemoteProvider(_ctrl.player, "player", F.konst(this));
        _gameService = new RemoteProxy(_ctrl.agent, "s");

        var bounds :Rectangle = _ctrl.local.getPaintableArea();

        var padding :int = 5;

        var showFeed :CheckBox = new CheckBox();
        showFeed.label = "Show Wyvern Feed";
        showFeed.selected = !_ctrl.player.props.get(Codes.HIDE_FEED);
        showFeed.x = padding;
        showFeed.y = 4;

        showFeed.addEventListener(MouseEvent.CLICK, function (... _) :void {
            _ctrl.player.props.set(Codes.HIDE_FEED, !showFeed.selected);
        });

        var toolbox :Sprite = new Sprite();
        toolbox.addChild(showFeed);

        toolbox.graphics.beginFill(0xf3f3f3);
        toolbox.graphics.drawRect(0, 0, toolbox.width+2*padding, toolbox.height);
        toolbox.graphics.endFill();

        addChild(toolbox);

        // Slide to top right
        toolbox.y = bounds.height-toolbox.height;
        Tweener.addTween(toolbox, { x: bounds.width-toolbox.width, transition: "linear", time:1.5 });

        // Yes, this is really dumb
        var timer :Timer = new Timer(10000);
        Command.bind(timer, TimerEvent.TIMER, setAvatarEnabled, true);
        Command.bind(_ctrl, Event.UNLOAD, timer.stop);
        // Causes error on FP 9
        //Command.bind(loaderInfo.loader, Event.UNLOAD, timer.stop);
        timer.start();
        setAvatarEnabled(true);

        _ctrl.room.addEventListener(ControlEvent.CHAT_RECEIVED, handleChat);
        _ctrl.room.addEventListener(AVRGameRoomEvent.AVATAR_CHANGED, handleAvatarChanged);
        _ctrl.player.addEventListener(AVRGamePlayerEvent.ENTERED_ROOM, onFirstRoom);
        _ctrl.player.addEventListener(GameContentEvent.PLAYER_CONTENT_CONSUMED, onContentConsumed);

        var buttonBar :Sprite = new Sprite();
        
        var inventory :ImageButton = new ImageButton(new INVENTORY_ICON(),
            Messages.en.xlate("t_inventory"));
        inventory.addEventListener(MouseEvent.CLICK,
            F.callback(_ctrl.player.playAvatarAction, "Inventory"));
        inventory.addEventListener(MouseEvent.CLICK,
            F.callback(metrics.trackEvent, "Buttons", "inventory"));
        inventory.x = buttonBar.width;
        buttonBar.addChild(inventory);

        var locator :ImageButton = new ImageButton(new SEARCH_ICON(),
            Messages.en.xlate("t_locate"));
        locator.addEventListener(MouseEvent.CLICK, F.callback(_gameService.locatePeers));
        locator.addEventListener(MouseEvent.CLICK,
            F.callback(metrics.trackEvent, "Buttons", "locator"));
        //GraphicsUtil.throttleClicks(locator);
        locator.x = buttonBar.width;
        buttonBar.addChild(locator);

        var invite :ImageButton = new ImageButton(new INVITE_ICON(),
            Messages.en.xlate("t_invite"));
        invite.addEventListener(MouseEvent.CLICK,
            F.callback(_ctrl.local.showInvitePage, Messages.en.xlate("m_invite")));
        invite.addEventListener(MouseEvent.CLICK,
            F.callback(metrics.trackEvent, "Buttons", "invite"));
        invite.x = buttonBar.width;
        buttonBar.addChild(invite);

//        var quit :ImageButton = new ImageButton(new EXIT_ICON(),
//            Messages.en.xlate("t_quit"));
//        quit.addEventListener(MouseEvent.CLICK, F.callback(exit));
//        quit.addEventListener(MouseEvent.CLICK,
//            F.callback(metrics.trackEvent, "Buttons", "quit"));
//        quit.x = buttonBar.width;
//        buttonBar.addChild(quit);

        buttonBar.x = bounds.width - buttonBar.width;
        buttonBar.y = toolbox.y - buttonBar.height;
        addChild(buttonBar);

        _ctrl.local.addEventListener(AVRGameControlEvent.SIZE_CHANGED, function (... _) :void {
            var bounds :Rectangle = _ctrl.local.getPaintableArea();
            if (bounds != null) {
                toolbox.x = bounds.width - toolbox.width;
                toolbox.y = bounds.height - toolbox.height;
                buttonBar.x = bounds.width - buttonBar.width;
                buttonBar.y = toolbox.y - buttonBar.height;

                ToolTipManager.instance.bounds = bounds;
            }
        });

        _ctrl.player.addEventListener(AVRGamePlayerEvent.TASK_COMPLETED, onTaskCompleted);

        // Set up the ToolTipManager
        ToolTipManager.instance.screen = this;
        ToolTipManager.instance.bounds = bounds;

        updateAvatar();
    }

    protected function exit () :void
    {
        _ctrl.local.feedback(Messages.en.xlate("m_quit"));
        _ctrl.player.deactivateGame();
    }

    protected function handleAvatarChanged (event :AVRGameRoomEvent) :void
    {
        if (event.value == _ctrl.player.getPlayerId()) {
            MethodQueue.callLater(updateAvatar);
        }
    }

    protected function onTaskCompleted (event :AVRGamePlayerEvent) :void
    {
        if (event.name == "kill") {
            new GOLD_SOUND().play();
        }
    }

    protected function updateAvatar () :void
    {
        var avatarId :int = _ctrl.player.getAvatarMasterItemId();
        if (_ctrl.player.props.get("avatarId") != avatarId) {
            _ctrl.player.props.set("avatarId", avatarId);
        }
    }

    protected function onFirstRoom (... _) :void
    {
        if (_ctrl.player.props.get(Codes.HAS_INSTALLED) != null) {
            _ctrl.player.doBatch(function () :void {
                // Cash out their dungeon keeper cred
                var newCredits :int = int(_ctrl.player.props.get(Codes.CREDITS));
                var allCredits :int = int(_ctrl.player.props.get(Codes.CREDITS_LIFETIME)) + newCredits;

                // Persist those credits for trophies
                if (newCredits > 0) {
                    _ctrl.local.feedback("Business is booming! Your dungeons collected " +
                        newCredits + " levels worth of kills while you were gone!");
                    _ctrl.player.props.set(Codes.CREDITS_LIFETIME, allCredits);
                    _ctrl.player.props.set(Codes.CREDITS, 0);
                }
                if (allCredits > 0) {
                    _ctrl.local.feedback("In all time, your dungeons have produced " +
                        allCredits + " levels worth of kills.");
                }

                _ctrl.local.feedback("Welcome back to Wyvern! Join the community at http://www.whirled.com/#groups-d_3464");

                const MAX :int = 30;
                if (newCredits > Codes.CREDIT_STEP*MAX) {
                    _ctrl.local.feedback("Whoa! You hit the maximum of " + MAX + " builder cashouts stored on your account. Try to log in more often to collect your cashouts before your account fills.");
                    newCredits = Codes.CREDIT_STEP*MAX;
                }
                for (var c :int = newCredits; c > 0; c -= Codes.CREDIT_STEP) {
                    _ctrl.player.completeTask("keeper", Math.min(c/Codes.CREDIT_STEP, 1));
                }
            });

        } else if (!Codes.isLandingRoom(_ctrl.player.getRoomId())) {
            // Give them the first character free
            var tint :Sprite = new Sprite();
            tint.graphics.beginFill(0);
            tint.graphics.drawRect(0, 0, 1, 1);
            tint.graphics.endFill();

            var overlay :Sprite = new NewCharacterOverlay();

            var screen :Rectangle = _ctrl.local.getPaintableArea();

            overlay.x = (screen.width - overlay.width)/2;
            overlay.y = (screen.height - overlay.height)/2;

            overlay.addEventListener(NewCharacterOverlay.EVENT_CHOSEN,
                function (event :ValueEvent) :void {
                    _gameService.chosen(event.value);
                    removeChild(overlay);
                    _ctrl.local.feedback(
                        "Your avatar has been added to your Stuff. Wear it to start playing!");
//                    _ctrl.local.feedback(
//                        "(You have also been given a memory bank toy, place it in your room and use it to properly save your character)");
                    //Shortcut: http://www.whirled.com/#stuff-5_0_wyverns");
                });

            Command.bind(overlay, NewCharacterOverlay.EVENT_CHOSEN, Tweener.addTween,
                [ tint, { alpha: 0, time:2, transition: "linear",
                onComplete: function () :void { removeChild(tint); } } ]);

            tint.alpha = 0.8;
            tint.y = screen.height/2;
            tint.width = screen.width;
            Tweener.addTween(tint, { y: 0, height: screen.height, transition: "linear", time:1 });

            addChild(tint);
            addChild(overlay);
        }

        // Only trigger once
        _ctrl.player.removeEventListener(AVRGamePlayerEvent.ENTERED_ROOM, onFirstRoom);
    }

    protected function hasItemPack (ident :String) :Boolean
    {
        for each (var pack :Object in _ctrl.player.getPlayerItemPacks()) {
            if (pack.ident == ident) {
                return true;
            }
        }

        return false;
    }

    public function getMyAvatar () :Object
    {
        return _ctrl.room.getEntityProperty(WyvernConstants.SERVICE_KEY,
            _ctrl.room.getAvatarInfo(_ctrl.player.getPlayerId()).entityId);
    }

    protected function requestBroadcast (message :String) :void
    {
        _scrollMessage = message;

        if (Codes.isAdmin(_ctrl.player.getPlayerId())) {
            sendBroadcast();

        } else if (hasItemPack(Codes.BROADCAST_PACK)) {
            var used :int = _ctrl.player.props.get(Codes.BROADCASTS_USED) + 1;

            var consume :Function = function () :void {
                sendBroadcast();
                _ctrl.player.props.set(Codes.BROADCASTS_USED, used);
            };

            if (used >= Codes.BROADCAST_USES) {
                _ctrl.player.requestConsumeItemPack(Codes.BROADCAST_PACK, "Your Scroll of Announcement is on its last use.");

            } else {
                sendBroadcast();
                _ctrl.player.props.set(Codes.BROADCASTS_USED, used);
                _ctrl.local.feedback("Your Scroll of Announcement has " + (Codes.BROADCAST_USES-used) + " uses remaining.");
            }

        } else {
            _ctrl.local.feedback("You are missing the scroll to cast this spell: http://www.whirled.com/#shop-l_12_20");
        }
    }

    protected function sendBroadcast () :void
    {
        var value :Array = [ _scrollMessage ];
        var svc :Object = getMyAvatar();

        if (svc != null) {
            value.push(("getLevel" in svc) ? svc.getLevel() : 0);
            value.push(("getKlassName" in svc) ? svc.getKlassName() : "??");
        }

        metrics.trackEvent("Broadcast",
            Codes.isAdmin(_ctrl.player.getPlayerId()) ? "admin" : "player");

        _gameService.broadcast(value);
    }

    protected function onContentConsumed (event :GameContentEvent) :void
    {
        if (event.contentIdent == Codes.BROADCAST_PACK && event.contentType == GameContentEvent.ITEM_PACK) {
            sendBroadcast();
            _ctrl.local.feedback("Your Scroll of Announcement burns to ashes!");
            _ctrl.player.props.set(Codes.BROADCASTS_USED, 0);
        }
    }

    protected function handleChat (event :ControlEvent) :void
    {
        // Let the chat show up on the screen first, then feedback after it
        MethodQueue.callLater(function () :void {
            var chatterId :int =
                _ctrl.room.getEntityProperty(EntityControl.PROP_MEMBER_ID, event.name);

            if (chatterId == _ctrl.player.getPlayerId()) {
                var command :Array = event.value.match(/^!(\w*)\s*(.*)/);
                var tokens :Array;
                if (command != null) {
                    switch (command[1].toLowerCase()) {
                        case "announce": case "announcement":
                            requestBroadcast(command[2]);
                            break;

                        case "whatami":
                            _ctrl.local.feedback("Avatar ID: " + _ctrl.player.getAvatarMasterItemId());
                            break;

                        case "add":
                            tokens = command[2].match(/(\w*?)\s+(.*)/);
                            Codes.requireAdmin(chatterId);
                            Codes.requireValidSet(tokens[1]);
                            _gameService.addToSet(tokens[1], int(tokens[2]));
                            break;

                        case "remove":
                            tokens = command[2].match(/(\w*?)\s+(.*)/);
                            Codes.requireAdmin(chatterId);
                            Codes.requireValidSet(tokens[1]);
                            _gameService.removeFromSet(tokens[1], int(tokens[2]));
                            break;

                        case "show":
                            Codes.requireAdmin(chatterId);
                            Codes.requireValidSet(command[2]);
                            _gameService.requestShowSet(command[2]);

                            break;

                        default:
                            _ctrl.local.feedback("Not a command: " + command[1]);
                            break;
                    }
                }
            }
        });
    }

    protected function setAvatarEnabled (open :Boolean) :void
    {
        for each (var ident :String in _ctrl.room.getEntityIds()) {
            // If it's the player
            if (_ctrl.room.getEntityProperty(EntityControl.PROP_TYPE, ident) == EntityControl.TYPE_AVATAR &&
                _ctrl.room.getEntityProperty(EntityControl.PROP_MEMBER_ID, ident) == _ctrl.player.getPlayerId()) {
                var service :Object = _ctrl.room.getEntityProperty(WyvernConstants.SERVICE_KEY, ident);
                if (service != null) {
                    service.gameOpen = open;
                }
                return;
            }
        }
    }

    REMOTE function feed (text :String) :void
    {
        if (!_ctrl.player.props.get(Codes.HIDE_FEED)) {
            _ctrl.local.feedback(text);
        }
    }

    REMOTE function broadcast (message :Array) :void
    {
        // [ name, text, level, klass ]
        var name :String = (message.length > 2) ?
            message[0] + " (Level " + message[2] + " " + message[3] + ")" :
            message[0];

        _ctrl.local.feedback(name + " announces: " + message[1]);
    }

    REMOTE function respondShowSet (setName :String, values :Array) :void
    {
        _ctrl.local.feedback("= Collection: " + setName);
        _ctrl.local.feedback("= " + values.join(", "));
    }

    REMOTE function respondLocatePeers (result :Array) :void
    {
        _ctrl.local.feedback(Messages.en.xlate("m_locatedHeader"));

        for each (var room :Array in result) {
            var roomId :int = room[0];
            var name :String = room[1];
            var pop :int = room[2];
            _ctrl.local.feedback(Messages.en.xlate("m_locatedRoom",
                roomId, name, pop));
        }
    }

    [Embed(source="../rsrc/search.png")]
    protected static const SEARCH_ICON :Class;
    [Embed(source="../rsrc/invite.png")]
    protected static const INVITE_ICON :Class;
//    [Embed(source="../rsrc/exit.png")]
//    protected static const EXIT_ICON :Class;
    [Embed(source="../rsrc/inventory.png")]
    protected static const INVENTORY_ICON :Class;

    [Embed(source="../rsrc/gold.mp3")]
    protected static const GOLD_SOUND :Class;

    protected var _ctrl :AVRGameControl;

    /** Saved !announce message. */
    protected var _scrollMessage :String;

    /** For calling functions on the server. */
    protected var _gameService :RemoteProxy;
}

}
