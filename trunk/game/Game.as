package {

import flash.display.Bitmap;
import flash.display.Sprite;
import flash.geom.Rectangle;
import flash.text.TextFieldAutoSize;
import flash.events.Event;
import flash.events.TimerEvent;
import flash.utils.Timer;

import caurina.transitions.Tweener;

//import fl.controls.CheckBox;
//import fl.skins.DefaultCheckBoxSkins;
import com.bit101.components.CheckBox;

import com.threerings.util.Command;
import com.threerings.util.MethodQueue;
import com.threerings.util.ValueEvent;

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
    //DefaultCheckBoxSkins;

    public function Game ()
    {
        _ctrl = new AVRGameControl(this);

        if ( ! _ctrl.isConnected()) {
            return;
        }

        new RemoteProvider(_ctrl.game, "c", F.konst(this));
        _gameService = new RemoteProxy(_ctrl.agent, "s");

        // TODO: Adapt to screen resizes
        var screen :Rectangle = _ctrl.local.getPaintableArea();

        var padding :int = 5;

        _showFeed = new CheckBox();
        _showFeed.label = "Show Wyvern Feed";
        _showFeed.selected = true;
        _showFeed.x = padding;
        _showFeed.y = 4;

        var toolbox :Sprite = new Sprite();
        toolbox.addChild(_showFeed);

        toolbox.graphics.beginFill(0xf3f3f3);
        toolbox.graphics.drawRect(0, 0, toolbox.width+2*padding, toolbox.height);
        toolbox.graphics.endFill();

        addChild(toolbox);

        // Slide to top right
        toolbox.y = screen.height-toolbox.height;
        Tweener.addTween(toolbox, { x: screen.width-toolbox.width, transition: "linear", time:1.5 });

        _ctrl.local.addEventListener(AVRGameControlEvent.SIZE_CHANGED, function (... _) :void {
            var screen :Rectangle = _ctrl.local.getPaintableArea();
            if (screen != null) {
                toolbox.x = screen.width - toolbox.width;
                toolbox.y = screen.height - toolbox.height;
            }
        });

        // Yes, this is really dumb
        var timer :Timer = new Timer(10000);
        Command.bind(timer, TimerEvent.TIMER, setAvatarEnabled, true);
        Command.bind(_ctrl, Event.UNLOAD, timer.stop);
        timer.start();
        setAvatarEnabled(true);

        _ctrl.room.addEventListener(ControlEvent.CHAT_RECEIVED, handleChat);
        _ctrl.player.addEventListener(AVRGamePlayerEvent.ENTERED_ROOM, onFirstRoom);
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

        } else {
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
                    _ctrl.local.feedback(
                        "(You have also been given a memory bank toy, place it in your room and use it to properly save your character)");
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

    protected function sendBroadcast (message :String) :void
    {
        var send :Function = function () :void {
            var value :Array = [ message ];
            var svc :Object = getMyAvatar();

            if (svc != null) {
                value.push(("getLevel" in svc) ? svc.getLevel() : 0);
                value.push(("getKlassName" in svc) ? svc.getKlassName() : "??");
            }

            _gameService.broadcast(value);
        };

        if (Codes.isAdmin(_ctrl.player.getPlayerId())) {
            send();

        } else if (hasItemPack(Codes.BROADCAST_PACK)) {
            var used :int = _ctrl.player.props.get(Codes.BROADCASTS_USED) + 1;

            var consume :Function = function () :void {
                send();
                _ctrl.player.props.set(Codes.BROADCASTS_USED, used);
            };

            if (used >= Codes.BROADCAST_USES) {
                if (_ctrl.player.requestConsumeItemPack(Codes.BROADCAST_PACK,
                    "Your Scroll of Announcement is on its last use.")) {

                    used = 0;
                    var onConfirm :Function = function (... _) :void {
                        _ctrl.local.feedback("Your Scroll of Announcement burns to ashes!");
                        consume();
                        _ctrl.player.removeEventListener(GameContentEvent.PLAYER_CONTENT_CONSUMED, onConfirm);
                    };
                    _ctrl.player.addEventListener(GameContentEvent.PLAYER_CONTENT_CONSUMED, onConfirm);
                }

            } else {
                consume();
                _ctrl.local.feedback("Your Scroll of Announcement has " +
                    (Codes.BROADCAST_USES-used) + " uses remaining.");
            }

        } else {
            _ctrl.local.feedback("You are missing the scroll to cast this spell: http://www.whirled.com/#shop-l_12_20");
        }
    }

    protected function handleChat (event :ControlEvent) :void
    {
        // Let the chat show up on the screen first, then feedback after it
        MethodQueue.callLater(function () :void {
            var chatterId :int =
                _ctrl.room.getEntityProperty(EntityControl.PROP_MEMBER_ID, event.name);

            if (chatterId == _ctrl.player.getPlayerId()) {
                var command :Array = event.value.match(/^!(\w*)\s+(.*)/i);
                if (command != null) {
                    switch (command[1]) {
                        case "announce": case "announcement":
                            sendBroadcast(command[2]);
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
        if (_showFeed.selected) {
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

    protected var _ctrl :AVRGameControl;

    protected var _showFeed :CheckBox;

    /** For calling functions on the server. */
    protected var _gameService :RemoteProxy;
}

}
