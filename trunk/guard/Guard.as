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
public class Guard_@KLASS@ extends Sprite
{
    public static const RESPAWN_TIME :int = 1*60*1000;
    public static const MAX_LEVEL :int = 250;
    public static const MAX_XP :Number = WyvernUtil.getXp(MAX_LEVEL);

    public function Guard_@KLASS@ ()
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
                return WyvernConstants.FACTION_PLAYER;
            },

            getPower: function () :Number {
                return _inventory.getPower() || 1;
            },

            getDefence: function () :Number {
                return _inventory.getDefence();
            },

            getRange: function () :Number {
                return _inventory.getRange();
            },

            getLevel: function () :int {
                return _quest.getLevel();
            },

            awardRandomItem: function (level :int) :void {
                var item :int = Items.randomLoot(level, 5);
                var bonus :int = Math.random() > 0.5 ? Math.random()*3+1 : 0;
                _inventory.offer(item, bonus);
                _quest.effect({text: Items.TABLE[item][1], color: 0xffcc00});
                chatter(_klass.getChatterVanquish, {item: Items.TABLE[item][1]});
            },

            awardXP: function (amount :int) :void {
                amount *= 2; // TODO: Migrate to WyvernSprite on next batch upload

                if (amount > 0) {
                    var oldXp :Number = Number(_ctrl.getMemory("xp"));
                    var oldLevel :int = WyvernUtil.getLevel(oldXp);
                    var nowXp :Number = Math.min(oldXp+amount, MAX_XP+1);

                    _ctrl.setMemory("xp", nowXp);
                    if (oldLevel < WyvernUtil.getLevel(nowXp)) {
                        _quest.effect({event: WyvernConstants.EVENT_LEVELUP});
                   }
                }

                // We killed something
                switchTarget();
            },

            revive: function () :void {
                //if (_ctrl.hasControl() && _quest.getHealth() <= 0) {
                if (_quest.getHealth() <= 0) {
                    _ctrl.setMemory("health", _quest.getMaxHealth());
                    chatter(_klass.getChatterRevive, null, 0.8);
                }
            },

            hasTrait: function (trait :int) :Boolean {
                return _klass.getTraits().indexOf(trait) != -1;
            },

            getKlassName: function () :String {
                return _klass.getName();
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
        _ctrl.addEventListener(ControlEvent.CHAT_RECEIVED, handleChat);
        _ctrl.addEventListener(ControlEvent.ENTITY_MOVED, handleMovement);
        Command.bind(_ctrl, ControlEvent.MEMORY_CHANGED, handleMemory);

        _grave = Bitmap(new GRAVE());
        _grave.smoothing = true;

        _doll = new Doll();
        _doll.layer([200]);

        _inventory = new GuardInventory(_ctrl, _klass, _doll);

        _quest = new WyvernSprite(_ctrl);
        _quest.bounciness = 20;
        _quest.bounceFreq = 200;
        addChild(_quest);

        _ctrl.setMoveSpeed(500);

        _ctrl.addEventListener(TimerEvent.TIMER, tick);
        _ctrl.setTickInterval(6000);

        handleMemory();

        _klass.getSoundChatter().play();

        _ctrl.doBatch(function () :void {
            checkRespawn();
            checkNewInstall();
        });
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
            _quest.effect({text: _klass.getWelcomeText(), color: 0xffcc00});
            _levelupSound.play();
            for each (var item :int in _klass.getStartingItems()) {
                _inventory.offer(item, 0);
            }
            _ctrl.setMemory("xp", WyvernUtil.getXp(_klass.getStartingLevel())+1,
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
                chatter(_klass.getChatterFlee);
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
            var newTarget :String = targets[int(Math.random()*targets.length)].getIdent();
            stalkTo(_ctrl.getEntityProperty(EntityControl.PROP_LOCATION_PIXEL, newTarget) as Array);
            if (newTarget != _hunting) {
                _hunting = newTarget;
                chatter(_klass.getChatterCharge, {name: _ctrl.getEntityProperty(EntityControl.PROP_NAME, newTarget)});
            }
        } else {
            if (_hunting != null) {
                chatter(_klass.getChatterAllClear, null, 1);
            } else {
                chatter(_klass.getChatterIdle, null, 0.05);
            }
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
            _quest.setActor(_doll);
        }
    }

    protected function handleMessage (event :ControlEvent) :void
    {
        if (event.name == "effect") {
            var effect :Object = event.value;

            if ("event" in effect) {
                switch (effect.event) {
                    case WyvernConstants.EVENT_ATTACK:
                    case WyvernConstants.EVENT_COUNTER:
                        _inventory.getAttackSound().play();
                        break;

                    case WyvernConstants.EVENT_HEAL:
                        _klass.getSoundHeal().play();
                        break;

                    case WyvernConstants.EVENT_DIE:
                        _hunting = null;
                        _ctrl.setMemory("timeOfDeath", new Date().time);
                        _klass.getSoundHeal().play();
                        chatter(_klass.getChatterDeath, null, 0.8);
                        break;
                }
            }
        }
    }

    protected function handleChat (event :ControlEvent) :void
    {
        if (event.name == _ctrl.getMyEntityId()) {
            _klass.getSoundChatter().play();
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

    protected function chatter (factory :Function, ctx :Object = null, chance :Number = 0.25) :void
    {
        if (Math.random() < chance) {
            var chatter :Array = factory();
            if (chatter != null && chatter.length > 0) {
                var text :String = chatter[int(Math.random()*chatter.length)];
                if (ctx != null) {
                    for (var key :String in ctx) {
                        text = text.replace("{"+key+"}", ctx[key]);
                    }
                }
                _ctrl.sendChat(text);
            }
        }
    }

    protected var _ctrl :PetControl;

    protected var _quest :WyvernSprite;

    protected var _inventory :GuardInventory;

    [Embed(source="rsrc/levelup.mp3")]
    protected static const SOUND_LEVELUP :Class;
    protected var _levelupSound :Sound = new SOUND_LEVELUP as Sound;

    [Embed(source="rsrc/grave.png")]
    protected static const GRAVE :Class;
    protected var _grave :Bitmap;

    protected var _doll :Doll;

    protected const _klass :GuardKlass = new @KLASS@();

    // Who I'm hunting. WARNING: This isn't preserved
    protected var _hunting :String;

    protected var _svc :Object;
}
}
