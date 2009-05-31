//
// $Id: WyvernSprite.as 6942 2008-12-10 19:36:43Z bruno $

package {

import flash.events.Event;
import flash.events.TimerEvent;

import flash.display.DisplayObject;
import flash.display.Sprite;

import flash.geom.Matrix;

import flash.text.TextField;
import flash.text.TextFieldAutoSize;

import flash.utils.getTimer; // function import
import flash.utils.Timer;

import com.threerings.flash.TextFieldUtil;
import com.threerings.util.Command;

import com.whirled.EntityControl;
import com.whirled.ActorControl;
import com.whirled.ControlEvent;

import caurina.transitions.Tweener;

public class WyvernSprite extends Sprite
{
    public static const MAX_HEIGHT :int = 350; // Not 400, xpField height not included
    public static const MAX_WIDTH :int = 600;

    public var bounciness :Number = 20;
    public var bounceFreq :Number = 200;
    public var right :Boolean = false;
    
    public function WyvernSprite (ctrl :ActorControl)
    {
        _ctrl = ctrl;

        _ui = new Sprite();
        addChild(_ui);

        _container = new Sprite();
        //_container.width = 32;
        //_container.height = 32;
        //_container.scaleX = 2;
        //_container.scaleY = 2;

        _ui.addChild(_container);

        _xpField = TextFieldUtil.createField("",
            { textColor: 0xffffff, selectable: false,
                autoSize: TextFieldAutoSize.LEFT, outlineColor: 0x00000 },
            { font: "_sans", size: 10, bold: true });
        _xpField.y = MAX_HEIGHT;
        makeNonScaling(_xpField);
        _ui.addChild(_xpField);

        _healthBar.x = center(ProgressBar.WIDTH);
        _ui.addChild(_healthBar);

        Command.bind(_ctrl, ControlEvent.APPEARANCE_CHANGED, setupVisual);
        Command.bind(_ctrl, ControlEvent.MEMORY_CHANGED, handleMemory);

        _ctrl.addEventListener(ControlEvent.MESSAGE_RECEIVED, handleMessage);

        _ctrl.setTickInterval(4000);
        Command.bind(_ctrl, TimerEvent.TIMER, _ctrl.doBatch, tick);

        // TODO: Add this to _ctrl, or loaderinfo or what?
        Command.bind(this, Event.UNLOAD, stopBouncing);

        //_ticker = new Ticker(_ctrl, 4000, tick);
//        var timer :Timer = new Timer(4000);
//        /*root.loaderInfo.addEventListener(Event.UNLOAD, function (..._) :void {
//            timer.stop();
//        });*/
//        timer.start();

        handleMemory();
    }

    public function setActor (actor :DisplayObject) :void
    {
        if (actor != _actor) {
            if (_actor != null) {
                _container.removeChild(_actor);
            }
            _actor = actor;
            _container.addChild(_actor);

            // Center horizontally
            _container.scaleX = 4;
            _container.scaleY = 4;
            _container.x = center(_container.width);

            stopBouncing();
            setupVisual();
        }
    }

    public function getActor () :DisplayObject
    {
        return _actor;
    }

    // Handy func for centering a sprite
    protected static function center (width :Number) :Number
    {
        return MAX_WIDTH/2 - width/2;
    }

    protected function tick () :void
    {
        var self :Object = WyvernUtil.self(_ctrl);

        if (self.hasTrait(WyvernConstants.TRAIT_REGEN)) {
            if (getHealth() < getMaxHealth()) {
                var regen :Number = Math.max(0, Math.min(0.02*getMaxHealth(), 5));
                self.damage(null, -regen, {text: "Regen"}, true);
            }
        }

        switch (self.getState()) {
            case WyvernConstants.STATE_ATTACK:
                attack();
                break;

            case WyvernConstants.STATE_HEAL:
                if (getHealth() < getMaxHealth()) {
                    var heal :Number = self.hasTrait(WyvernConstants.TRAIT_PLUS_HEALING) ? 0.2 : 0.15;
                    self.damage(null, -heal*getMaxHealth(), {
                        text: "Heal",
                        event: WyvernConstants.EVENT_HEAL
                    }, true);
                }
                break;

              // Focus damage disabled
//            case WyvernConstants.STATE_COUNTER:
//                var focus :Number = self.hasTrait(WyvernConstants.TRAIT_PLUS_COUNTER) ? 0.05 : 0.1;
//                self.damage(null, focus*getMaxHealth(), {
//                    text: "Focus",
//                    event: WyvernConstants.EVENT_COUNTER
//                }, true);
//                break;
        }
    }

    protected function attack () :void
    {
//        var self :Object = WyvernUtil.self(_ctrl);
//        var amount :Number = WyvernUtil.getAttackDamage(self);
//        var influence :int = WyvernUtil.getTotem(_ctrl);
        var here :Array = _ctrl.getLogicalLocation() as Array;
        var orient :Number = _ctrl.getOrientation() as Number;

        var id :String = WyvernUtil.fetchClosest(_ctrl, function (svc :Object, id :String) :Boolean {
            return WyvernUtil.isAttackable(_ctrl, svc) &&
                WyvernUtil.insideArc(here, orient, 180,
                    _ctrl.getEntityProperty(EntityControl.PROP_LOCATION_LOGICAL, id) as Array);
        });
//            if ( ! WyvernUtil.insideArc(here, orient, 180,
//                _ctrl.getEntityProperty(EntityControl.PROP_LOCATION_LOGICAL, id)) {
//                return false;
//            }
//            // Are they dead?
//            if (svc.getState() == WyvernConstants.STATE_DEAD) {
//                return false;
//            }
//            // Are they the same faction with a level range outside the totem influence?
//            if (svc.getFaction() == self.getFaction() &&
//                influence < Math.abs(self.getLevel() - svc.getLevel())) {
//                return false;
//            }
//
//            return true;

        if (id != null) {
            var defender :Object = WyvernUtil.getService(_ctrl, id);
            if (defender != null && WyvernUtil.attack(_ctrl, defender)) {
                effect({event:WyvernConstants.EVENT_ATTACK}); // TODO: Use triggerAction instead of this wacky stuff
            }
        }
//        if (id != null) {
//            var d2 :Number = WyvernUtil.squareDistanceTo(_ctrl, id);
//
//            if (d2 <= self.getRange()*self.getRange()) {
//                var target :Object = WyvernUtil.getService(_ctrl, id);
//
//                if (Math.abs(int(_ctrl.getEntityProperty(EntityControl.PROP_ORIENTATION, id)) -
//                    orient) < 90) {
//                    // Backstab
//                    var backstab :Number = self.hasTrait(WyvernConstants.TRAIT_BACKSTAB) ? 3 : 2;
//                    target.damage(self, amount*backstab, {text:"Critical!"});
//                } else if (target.getState() == WyvernConstants.STATE_COUNTER &&
//                    d2 <= target.getRange()*target.getRange()) {
//                    // Counter
//                    self.damage(target, WyvernUtil.getAttackDamage(target), {text:"Countered!"});
//                    target.damage(self, amount*0.25, { event: WyvernConstants.EVENT_COUNTER });
//
//                } else {
//                    // Normal attack
//                    target.damage(self, amount);
//                }
//
//                effect({event:WyvernConstants.EVENT_ATTACK}); // TODO: Use triggerAction instead of this wacky stuff
//            }
//        }
    }

    public function damage (source :Object, amount :Number, fx :Object, ignoreArmor :Boolean) :void
    {
        var health :Number = getHealth();
        if (health == 0) {
            return; // Don't revive
        }

        var level :int = getLevel();

        if (!ignoreArmor) {
            var defence :int = WyvernUtil.self(_ctrl).getDefence();
            //amount *= Math.max(0.1, 1 - (0.75+level*0.05)*defence/100); // TODO: Tweak
            amount *= Math.max(0.2, 1 - (level+defence)/200); // TODO: Tweak
        }

        if (amount > 0 && WyvernUtil.self(_ctrl).getState() == WyvernConstants.STATE_HEAL) {
            amount *= 2;
        }

        amount = Math.ceil(amount);

        var hit :String = WyvernUtil.deltaText(-amount);
        if (fx != null) {
            if ("text" in fx) {
                // Add the damage string to it
                fx.text = hit + " (" + fx.text + ")";
            } else {
                fx.text = hit;
            }
            // If the color isn't specified and it's a heal
            if (!("color" in fx) && amount < 0) {
                // Make it green
                fx.color = 0x00ff00;
            }
        } else {
            fx = {text: hit};
        }

        effect(fx);

        if (health <= amount) {
            _ctrl.setMemory("health", 0);
            if (source != null) {
                // Goodies
                source.awardXP(level*8);
                source.awardRandomItem(10*level/120);
            }

            var us :String = WyvernUtil.self(_ctrl).getFaction();
            var them :String = source.getFaction();
            var mode :int = -1;
            if (them == WyvernConstants.FACTION_PLAYER && us == WyvernConstants.FACTION_MONSTER) {
                mode = WyvernConstants.PLAYER_KILLED_MONSTER;
            } else if (them == WyvernConstants.FACTION_PLAYER && us == WyvernConstants.FACTION_PLAYER) {
                mode = WyvernConstants.PLAYER_KILLED_PLAYER;
            } else if (them == WyvernConstants.FACTION_MONSTER && us == WyvernConstants.FACTION_PLAYER) {
                mode = WyvernConstants.MONSTER_KILLED_PLAYER;
            }

            _ctrl.sendSignal(WyvernConstants.KILL_SIGNAL, [
                _ctrl.getEntityProperty(EntityControl.PROP_MEMBER_ID, source.getIdent()),
                _ctrl.getEntityProperty(EntityControl.PROP_MEMBER_ID),
                level, mode
            ]);

            effect({text:"Death", event:WyvernConstants.EVENT_DIE});
        } else {
            _ctrl.setMemory("health", Math.min(health-amount, getMaxHealth()));
        }
    }

    protected function handleMemory () :void
    {
        _xpField.text = "Level " + getLevel();

        var health :int = getHealth();
        _healthBar.percent = health/getMaxHealth();
        _healthBar.visible = (health > 0); // TODO: Hide on max health too?
    }

    protected function makeNonScaling (node :DisplayObject) :void
    {
        var onFrame :Function = function (... _) :void {
            var matrix :Matrix = transform.concatenatedMatrix;
            node.scaleX = 1 / matrix.a;
            node.scaleY = 1 / matrix.d;
            node.x = center(node.width); // It's got to be centered
        }
        onFrame();

        node.addEventListener(Event.ENTER_FRAME, onFrame);
        Command.bind(node, Event.REMOVED, node.removeEventListener, [Event.ENTER_FRAME, onFrame]);
    }

    protected function handleMessage (event :ControlEvent) :void
    {
        if (event.name == "effect") {
            var effect :Object = event.value;

            // Show floaty text as part of this effect
            if ("text" in effect) {
                var field :TextField = TextFieldUtil.createField(effect.text,
                    { textColor: ("color" in effect) ? effect.color : 0xFF4400, selectable: false,
                        autoSize: TextFieldAutoSize.LEFT, outlineColor: 0x00000 },
                    { font: "_sans", size: 12, bold: true });

                makeNonScaling(field);

                //field.y = MAX_HEIGHT - _container.scaleY*_actor.height/2;
                field.y = _container.y + _container.height/2;

                var complete :Function = function () :void {
                    removeChild(this);
                };
                Tweener.addTween(field, {y: 50, time:2, onComplete:complete, transition:"linear"});

                addChild(field);
            }

            if ("event" in effect && effect.event == WyvernConstants.EVENT_ATTACK) {
                if (_actor != null) {
                    var originalX :Number = _actor.x;
                    Tweener.addTween(_actor, {
                        time: 0.1,
                        x: _actor.x - _actor.scaleX*10,
                        y: -4,
                        onComplete: function () :void {
                            Tweener.addTween(_actor, {
                                time: 0.5,
                                x: originalX,
                                y: 0
                            });
                        }
                    });
                }
            }
        }
    }

    public function getXP () :int
    {
        return _ctrl.getMemory("xp") as Number;
    }

    public function getLevel () :int
    {
        return WyvernUtil.getLevel(getXP());
    }

    public function getHealth () :int
    {
        return _ctrl.getMemory("health", 1) as int;
    }

    public function getMaxHealth () :int
    {
        return 10 + 2*getLevel();
    }

    public function effect (data :Object) :void
    {
        _ctrl.sendMessage("effect", data);
    }

    public function echo (text :String, color :int = -1) :void
    {
        effect({text: text});
    }

    protected function setupVisual () :void
    {
        var orient :Number = _ctrl.getOrientation();
        var isMoving :Boolean = _ctrl.isMoving();

        _healthBar.y = MAX_HEIGHT - _container.height - bounciness - _healthBar.height;
        if (_ui.visible) {
            _ctrl.setHotSpot(MAX_WIDTH/2, MAX_HEIGHT, _container.height+bounciness+_healthBar.height+20);
        }

        // make sure we're oriented correctly
        // (We discard nearly all the orientation information and only care if we're
        // facing left or right.)
        if (right == (orient > 180)) {
            _actor.x = _actor.width;
            _actor.scaleX = -1;

        } else {
            _actor.x = 0;
            _actor.scaleX = 1;
        }

        // if we're moving, make us bounce.
        if (bounciness > 0 && _bouncing != isMoving) {
            _bouncing = isMoving;
            if (_bouncing) {
                _bounceBase = getTimer(); // note that time at which we start bouncing
                addEventListener(Event.ENTER_FRAME, handleEnterFrame);

            } else {
                stopBouncing();
            }
        }
    }

    protected function handleEnterFrame (... ignored) :void
    {
        var now :Number = getTimer();
        var elapsed :Number = now - _bounceBase;
        while (elapsed > bounceFreq) {
            elapsed -= bounceFreq;
            _bounceBase += bounceFreq; // give us less math to do next time..
        }

        var val :Number = elapsed * Math.PI / bounceFreq;
        //_container.y = MAX_HEIGHT - _container.height - (Math.sin(val) * bounciness);
        _container.y = MAX_HEIGHT - _container.height - (Math.sin(val) * bounciness);
    }

    protected function stopBouncing () :void
    {
        removeEventListener(Event.ENTER_FRAME, handleEnterFrame);
        _container.y = MAX_HEIGHT - _container.height;
    }

    protected var _ctrl :ActorControl;

    protected var _container :Sprite;

    protected var _ui :Sprite; // Holds everything but text messages

    protected var _actor :DisplayObject;

//    protected var _ticker :Ticker;

    /** Are we currently bouncing? */
    protected var _bouncing :Boolean = false;

    /** The time at which the current bounce started. */
    protected var _bounceBase :Number;

    protected var _xpField :TextField;

    protected var _healthBar :ProgressBar = new ProgressBar(0x00ff00, 0xff0000);
}
}
