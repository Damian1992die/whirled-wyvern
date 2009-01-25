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

import com.whirled.avrg.*;
import com.whirled.net.*;
import com.whirled.*;

import com.threerings.util.Command;
import com.threerings.util.ValueEvent;

public class Game extends Sprite
{
    //DefaultCheckBoxSkins;

    public function Game ()
    {
        _ctrl = new AVRGameControl(this);

        if ( ! _ctrl.isConnected()) {
            return;
        }

        // TODO: Adapt to screen resizes
        var screen :Rectangle = _ctrl.local.getPaintableArea();

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

            overlay.x = (screen.width - overlay.width)/2;
            overlay.y = (screen.height - overlay.height)/2;

            overlay.addEventListener(NewCharacterOverlay.EVENT_CHOSEN,
                function (event :ValueEvent) :void {
                    _ctrl.agent.sendMessage("chosen", event.value);
                    removeChild(overlay);
                    _ctrl.local.feedback(
                        "Your avatar has been added to your Stuff. Wear it to start playing!");
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

        var padding :int = 5;

        _showBroadcasts = new CheckBox();
        _showBroadcasts.label = "Show Wyvern Feed";
        _showBroadcasts.selected = true;
        _showBroadcasts.x = padding;
        _showBroadcasts.y = 4;

        var toolbox :Sprite = new Sprite();
        toolbox.addChild(_showBroadcasts);

        toolbox.graphics.beginFill(0xf3f3f3);
        toolbox.graphics.drawRect(0, 0, toolbox.width+2*padding, toolbox.height);
        toolbox.graphics.endFill();

        addChild(toolbox);

        // Slide to top right
        toolbox.y = screen.height-toolbox.height;
        Tweener.addTween(toolbox, { x: screen.width-toolbox.width, transition: "linear", time:1.5 });

        // Yes, this is really dumb
        var timer :Timer = new Timer(10000);
        Command.bind(timer, TimerEvent.TIMER, setAvatarEnabled, true);
        Command.bind(root.loaderInfo, Event.UNLOAD, timer.stop);
        timer.start();
        setAvatarEnabled(true);

        //Command.bind(_ctrl.game, AVRGameControlEvent.PLAYER_JOINED_GAME, setAvatarEnabled, true);
        
        // This doesn't work
        // Command.bind(root.loaderInfo, Event.UNLOAD, setAvatarEnabled, false);

//        _ctrl.room.addEventListener(AVRGameRoomEvent.AVATAR_CHANGED, function (event :AVRGameRoomEvent) :void {
//            if (event.value == _ctrl.player.getPlayerId()) {
//                setAvatarEnabled(true);
//            }
//        });

        // Yes, this is fired more than usual
        // Doesn't really seem to work either
//        _ctrl.room.addEventListener(AVRGameRoomEvent.SIGNAL_RECEIVED, function (event :AVRGameRoomEvent) :void {
//            toolbox.y += 100;
//            if (event.name == WyvernConstants.KILL_SIGNAL) {
//                setAvatarEnabled(true);
//            }
//        });

        _ctrl.game.addEventListener(MessageReceivedEvent.MESSAGE_RECEIVED, handleMessage);
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

    protected function handleMessage (event :MessageReceivedEvent) :void
    {
        if (_showBroadcasts.selected && event.name == "broadcast") {
            _ctrl.local.feedback(String(event.value));
        }
    }

    protected var _ctrl :AVRGameControl;

    protected var _showBroadcasts :CheckBox;
}

}
