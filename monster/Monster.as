//
// $Id: Monster.as 6942 2008-12-10 19:36:43Z bruno $

package {

import flash.events.Event;
import flash.events.TimerEvent;

import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.display.Bitmap;

import flash.media.Sound;

import com.threerings.util.Command;

import com.whirled.EntityControl;
import com.whirled.PetControl;
import com.whirled.ControlEvent;

[SWF(width="600", height="400")]
public class Monster_@MONSTER_NAME@ extends Sprite
{
    public static const RESPAWN_TIME :int = 1*60*1000;

    public function Monster_@MONSTER_NAME@ ()
    {
        _ctrl = new PetControl(this);

        _svc = {
            getState: function () :String {
                return (_quest.getHealth() == 0) ? WyvernConstants.STATE_DEAD : _ctrl.getState();
            },

            getIdent: function () :String {
                return _ctrl.getMyEntityId();
            },

            getFaction: function () :String {
                return WyvernConstants.FACTION_MONSTER;
            },

            getPower: function () :Number {
                return @MONSTER_LEVEL@/6 + 1;
            },

            getDefence: function () :Number {
                return @MONSTER_LEVEL@/2 + 1;
            },

            getRange: function () :Number {
                return @RANGE@*400;
            },

            getLevel: function () :int {
                return _quest.getLevel();
            },

            awardRandomItem: function (level :int) :void {
                // Nothing
            },

            awardXP: function (amount :int) :void {
                // We killed something
                switchTarget();
            },

            revive: function () :void {
                //if (_ctrl.hasControl() && _quest.getHealth() <= 0) {
                if (_quest.getHealth() <= 0) {
                    _ctrl.setMemory("health", _quest.getMaxHealth());
                }
            },

            hasTrait: function () :Boolean {
                return false; // TODO?
            },

            damage: function (
                source :Object, amount :Number, cause :Object = null, ignoreArmor :Boolean = false) :void {
                //if (_ctrl.hasControl()) {
                    _quest.damage(source, amount, cause, ignoreArmor);
                //}
            }
        };

        _ctrl.registerPropertyProvider(propertyProvider);

        _ctrl.addEventListener(ControlEvent.MESSAGE_RECEIVED, handleMessage);
        _ctrl.addEventListener(ControlEvent.ENTITY_MOVED, handleMovement);
        Command.bind(_ctrl, ControlEvent.MEMORY_CHANGED, handleMemory);

        _grave = Bitmap(new GRAVE());
        _grave.smoothing = true;

        _image = Bitmap(new IMAGE());
        _image.smoothing = true;

        _quest = new WyvernSprite(_ctrl);
        addChild(_quest);

        _ctrl.addEventListener(TimerEvent.TIMER, tick);
        _ctrl.setTickInterval(9000);

        handleMemory();

        //if (_ctrl.getMyEntityId() == "-1:1") {
            _soundAttack.play();
        //}
        checkRespawn();
        checkNewInstall();
    }

    protected function checkRespawn () :void
    {
        if (_svc.getState() == WyvernConstants.STATE_DEAD) {
            var now :Number = new Date().time;
            var died :Number = _ctrl.getMemory("timeOfDeath", now) as Number;
            var delta :Number = now - died;

            if (delta > RESPAWN_TIME || delta < 0) {
                _svc.revive();
                wander();
            }
        }
    }

    protected function checkNewInstall () :void
    {
        if (_ctrl.getMemory("xp") == null) {
            _ctrl.setMemory("xp", WyvernUtil.getXp(@MONSTER_LEVEL@)+1,
                function (... _) :void {
                    _ctrl.setMemory("health", _quest.getMaxHealth());
                });
        }
    }

    protected function tick (event :TimerEvent) :void
    {
        _ctrl.doBatch(function () :void {
            checkRespawn();

            if (_svc.getState() == WyvernConstants.STATE_DEAD) {
                return;
            }

            if (_quest.getHealth()/_quest.getMaxHealth() < 0.25) {
                _hunting = null;
                _ctrl.setState(WyvernConstants.STATE_HEAL);
                wander(); // Flee!
            } else {
                switchTarget();
                _ctrl.setState(WyvernConstants.STATE_ATTACK);
            }
        });
    }

    protected function wander () :void
    {
        var bounds :Array = _ctrl.getRoomBounds();
        walkTo([ bounds[0]*Math.random(), 0, bounds[2]*Math.random() ]);
    }

    // Pick a victim and charge at it
    protected function switchTarget () :void
    {
        var targets :Array = WyvernUtil.query(_ctrl, function (svc :Object, id :String) :Boolean {
            return svc.getState() != WyvernConstants.STATE_DEAD &&
                svc.getFaction() != _svc.getFaction() && // TODO: Totem?
                WyvernUtil.squareDistance(_ctrl, id) < 1000*1000;
        });

        if (targets.length > 0) {
            _hunting = targets[int(Math.random()*targets.length)].getIdent();
            stalkTo(_ctrl.getEntityProperty(EntityControl.PROP_LOCATION_PIXEL, _hunting) as Array);
        } else {
            _hunting = null;
            wander();
        }
    }


    // Move to some target, but keep a certain distance away
    protected function stalkTo (pixel :Array, distance :Number = NaN) :void
    {
        if (isNaN(distance)) {
            distance = _svc.getRange()/2-1;
        }

        var here :Array = _ctrl.getPixelLocation() as Array;

        var v :Array = [ pixel[0]-here[0], 0, pixel[2]-here[2] ]; // Vector from here->pixel
        var d :Number = Math.sqrt(v[0]*v[0] + v[2]*v[2]); // Magnitude
        var u :Array = [ v[0]/d, 0, v[2]/d ]; // Unit vector

        var to :Array = [ here[0] + v[0]-distance*u[0], 0, here[2] + v[2]-distance*u[2] ];

        // Prevent myself from walking of screen
        var bounds :Array = _ctrl.getRoomBounds();
        to[0] = Math.max(0, Math.min(to[0], bounds[0]));
        to[2] = Math.max(0, Math.min(to[2], bounds[2]));

        walkTo(to, pixel); // Walk there, facing the player
    }

    protected function handleMovement (event :ControlEvent) :void
    {
        if (event.name == _hunting && event.value != null) {
            var bounds :Array = _ctrl.getRoomBounds();
            stalkTo([ event.value[0]*bounds[0], 0, event.value[2]*bounds[2] ]); // Convert to pixel
        }
    }

    protected function walkTo (pixel :Array, facing :Array = null) :void
    {
        if (facing == null) {
            facing = _ctrl.getPixelLocation() as Array;
            facing[0] = 2*pixel[0] - facing[0];
            facing[2] = 2*pixel[2] - facing[2];
        }
        var angle :Number = Math.atan2(facing[2]-pixel[2], facing[0]-pixel[0]); // Radians
        angle = (360 + 90 + Math.round(180/Math.PI * angle)) % 360; // Convert to our degree system

        _ctrl.setPixelLocation(pixel[0], pixel[1], pixel[2], angle);
    }

    protected function handleMemory (... _) :void
    {
        if (_quest.getHealth() == 0) {
            _quest.setActor(_grave);
        } else {
            _quest.setActor(_image);
        }
    }

    protected function handleMessage (event :ControlEvent) :void
    {
        if (event.name == "effect") {
            var effect :Object = event.value;

            if ("event" in effect) {
                switch (effect.event) {
                    case WyvernConstants.EVENT_ATTACK:
                        _soundAttack.play();
                        break;

                    case WyvernConstants.EVENT_COUNTER:
                        _soundAttack.play();
                        //_soundCounter.play();
                        break;

                    case WyvernConstants.EVENT_HEAL:
                        //_soundHeal.play();
                        break;

                    case WyvernConstants.EVENT_DIE:
                        _hunting = null;
                        _soundDeath.play();
                        _ctrl.setMemory("timeOfDeath", new Date().time);
                        break;
                }
            }
        }
    }

    public function propertyProvider (key :String) :Object
    {
        if (key == WyvernConstants.SERVICE_KEY) {
            return _svc;
        } else {
            return null;
        }
    }

    protected var _ctrl :PetControl;

    protected var _quest :WyvernSprite;

    [Embed(source="rsrc/grave.png")]
    protected static const GRAVE :Class;
    protected var _grave :Bitmap;

    [Embed(source="rsrc/@MONSTER_NAME@.png")]
    protected static const IMAGE :Class;
    protected var _image :Bitmap;

    [Embed(source="rsrc/@SOUND_ATTACK@")]
    protected static const SOUND_ATTACK :Class;
    protected var _soundAttack :Sound = new SOUND_ATTACK() as Sound;

    [Embed(source="rsrc/@SOUND_DEATH@")]
    protected static const SOUND_DEATH :Class;
    protected var _soundDeath :Sound = new SOUND_DEATH() as Sound;

    // Who I'm hunting. WARNING: This isn't preserved
    protected var _hunting :String;

    protected var _svc :Object;
}
}
