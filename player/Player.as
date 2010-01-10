//
// $Id: Player.as 6942 2008-12-10 19:36:43Z bruno $

package {

import flash.events.Event;

import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.display.Bitmap;
import flash.filters.GlowFilter;
import flash.media.Sound;
import flash.utils.setTimeout;

import caurina.transitions.Tweener;

import com.threerings.text.TextFieldUtil;

import com.threerings.util.Command;

import com.whirled.AvatarControl;
import com.whirled.ControlEvent;
import com.whirled.EntityControl;

import klass.Klass;
import klass.@KLASS@;

[SWF(width="600", height="400")]
public class Player_@KLASS@ extends Sprite
{
    public function Player_@KLASS@ ()
    {
        _ctrl = new AvatarControl(this);

        _svc = {
            getState: function () :String {
                return (_quest.getHealth() == 0) ?
                    WyvernConstants.STATE_DEAD : PlayerCodes.LABEL_TO_STATE[_ctrl.getState()];
            },

            getIdent: function () :String {
                return _ctrl.getMyEntityId();
            },

            getFaction: function () :String {
                return WyvernConstants.FACTION_PLAYER;
            },

            hasTrait: function (trait :int) :Boolean {
                return _klass.getTraits().indexOf(trait) != -1;
            },

            getPower: function () :Number {
                return _inventory.getPower() || 1;
            },

            getDefence: function () :Number {
                return _inventory.getDefence();
            },

            getRange: function () :Number {
                return _inventory.getRange(); // Use the range of the equipped weapon
            },

            getLevel: function () :int {
                return _quest.getLevel();
            },

            getKlassName: function () :String {
                return _klass.getName();
            },

            // Avatar field only. Poked periodically by the AVRG: "Hey, the game is open, stop nagging the user now"
            gameOpen: false
        };

        registerControllerFunctions({
            awardRandomItem: function (level :int) :void {
                var item :int = Items.randomLoot(level, 5);
                var bonus :int = Math.random() > 0.5 ? Math.random()*3+1 : 0;
                if (_inventory.deposit(item, bonus)) {
                    _quest.effect({text: Items.TABLE[item][1], color: 0xffcc00});
                } else {
                    _quest.effect({text: "Inventory FULL!"});
                }

                if (_svc.hasTrait(WyvernConstants.TRAIT_BLOODTHIRST)) {
                    if (_quest.getHealth() < _quest.getMaxHealth()) {
                        setTimeout(function () :void {
                            _svc.damage(null, -Math.max(1,0.1*_quest.getMaxHealth()),
                                { text: "Bloodthirst" }, true);
                        }, 500);
                    }
                }
            },

            awardXP: function (amount :int) :void {
                amount *= 2; // TODO: Migrate to WyvernSprite on next batch upload

                if (amount > 0) {
                    var oldXp :Number = Number(_ctrl.getMemory("xp"));
                    var oldLevel :int = WyvernUtil.getLevel(oldXp);
                    var nowXp :Number = Math.min(oldXp+amount, PlayerCodes.MAX_XP+1);

                    _ctrl.setMemory("xp", nowXp);
                    if (oldLevel < WyvernUtil.getLevel(nowXp)) {
                        _quest.effect({event: WyvernConstants.EVENT_LEVELUP});
                   }
                }
            },

            revive: function () :void {
                if (_quest.getHealth() <= 0) {
                    _ctrl.setMemory("health", _quest.getMaxHealth());
                    _quest.effect({text: "Revived!", color: 0x00ff00, event: WyvernConstants.EVENT_REVIVE});
                }
            },

            damage: function (
                source :Object, amount :Number, cause :Object = null, ignoreArmor :Boolean = false) :void {

                // The horror, the horror!
                if (source is String) {
                    source = WyvernUtil.getService(_ctrl, source as String);
                }

                // TODO: Uber kludge of hackery +12. Remove this when monsters are updated
                if (_svc.getState() == WyvernConstants.STATE_COUNTER && source != null && cause == null) {
                    cause = {event: WyvernConstants.EVENT_COUNTER};
                }
                _quest.damage(source, amount, cause, ignoreArmor);
            }
        });

        _doll = new Doll();
        _doll.layer([200]);

        _quest = new PlayerSprite(_ctrl);
        addChild(_quest);

        _ctrl.registerPropertyProvider(propertyProvider);

        var states :Array = [];
        for (var state :String in PlayerCodes.LABEL_TO_STATE) {
            states.push(state);
        }
        _ctrl.registerStates(states.sort());
        _ctrl.registerActions("Inventory", _klass.getSpecialName());

        _ctrl.addEventListener(ControlEvent.ACTION_TRIGGERED, handleAction);
        Command.bind(_ctrl, ControlEvent.MEMORY_CHANGED, handleMemory);
        _ctrl.addEventListener(ControlEvent.MESSAGE_RECEIVED, handleMessage);

        _ctrl.addEventListener(ControlEvent.SIGNAL_RECEIVED, handleSignal);

        _inventory = new Inventory(_ctrl, _klass, _doll);
        _ghost = Bitmap(new GHOST());
        _ghost.smoothing = true;

        handleMemory();

        // If this is their first boot
        if (_ctrl.getMemory("health") == null && _ctrl.hasControl()) {
            _ctrl.doBatch(function () :void {
                _quest.effect({text: "Welcome to Wyvern!", color: 0xffcc00});
                _levelupSound.play();
                _inventory.depositGroup([
                    156, // Sword
                    158, // Shortbow
                    173, // Crystal ball
                    12, // Apprentice robe
                    16, // Chain mail
                ], [
                    +1, +1, +1, +2, +2,
                ]);
                _ctrl.setMemory("health", _quest.getMaxHealth());
            });
        }
    }

    public function handleMemory () :void
    {
        if (_quest.getHealth() == 0) {
            _quest.bounciness = 10;
            _quest.bounceFreq = 1000;
            _quest.setActor(_ghost);
            _ctrl.setMoveSpeed(200);
        } else if (_quest.getActor() == _ghost || _quest.getActor() == null) {
            _quest.bounciness = 20;
            _quest.bounceFreq = 200;
            _quest.setActor((_body != null) ? _body : _doll);
            _ctrl.setMoveSpeed(500);
        }
    }

//    protected function registerActions (bankHere :Boolean) :void
//    {
//        var actions :Array = [ "Inventory" ];
//        if (bankHere) {
//            _ctrl.registerActions(actions.concat("Memory deposit", "Memory withdraw"));
//        } else {
//            _ctrl.registerActions(actions);
//        }
//    }

    // Only called on the controller (wearer)
    public function handleSignal (event :ControlEvent) :void
    {
        if (event.name == WyvernConstants.KILL_SIGNAL &&
            !_svc.gameOpen &&
            event.value[0] == _ctrl.getEntityProperty(EntityControl.PROP_MEMBER_ID)) {

            GraphicsUtil.feedback(_ctrl, "Oh snap! You would have got Whirled coins for that kill, but you weren't logged into Wyvern. Login by clicking Wyvern on the Games tab to start earning coins and trophies for playing!");
        }
    }

    public function handleMessage (event :ControlEvent) :void // TODO: Convert to actions
    {
        if (event.name == "effect") {
            var effect :Object = event.value;

            if ("event" in effect) {
                switch (effect.event) {
                    case WyvernConstants.EVENT_ATTACK:
                        _inventory.getAttackSound().play();
                        break;

                    case WyvernConstants.EVENT_COUNTER:
                        _soundCounter.play();
                        break;

                    case WyvernConstants.EVENT_HEAL:
                        _soundHeal.play();
                        break;

                    case WyvernConstants.EVENT_DIE:
                        _soundDie.play();
                        if (_ctrl.hasControl() && _ctrl.getMemory("hasDied") == null) {
                            GraphicsUtil.feedback(_ctrl, "Oh the humanity! Luckily, death in Wyvern is only a minor set back. You can get back on your feet by walking next to a resurrection shrine!");
                            _ctrl.setMemory("hasDied", true);
                        }
                        break;

                    case WyvernConstants.EVENT_REVIVE:
                        glow(0xffffff);
                        break;

                    case WyvernConstants.EVENT_LEVELUP:
                        glow(0xffcc00);
                        _levelupSound.play();
                        break;
                }
            }

        } else if (event.name == "call" && _ctrl.hasControl()) {
            var args :Array = event.value as Array;
            var name :String = args.shift() as String;
            _ctrl.doBatch(function () :void {
                _svc[name].apply(null, args);
            });
        }
    }

    public function glow (color :int) :void
    {
        var glow :GlowFilter = new GlowFilter(color, 80, 20, 20, 4);
        var update :Function = function () :void {
            filters = [ glow ];
        }
        var complete :Function = function () :void {
            filters = null;
        }
        Tweener.addTween(glow, {strength: 0, time: 2, transition: "easeInQuad",
            onUpdate: update, onComplete: complete });
    }

    public function handleAction (event :ControlEvent) :void
    {
        if (_ctrl.hasControl()) {
            switch (event.name) {
                case "Inventory":
                    GraphicsUtil.showPopup(_ctrl, "Inventory", _inventory);
                    break;
            }
        }

        if (_svc.getState() != WyvernConstants.STATE_DEAD) {
            switch (event.name) {
                case _klass.getSpecialName():
                    _klass.handleSpecial(_ctrl, _quest);
                    break;
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

//    protected function bankDeposit (bank :Object) :void
//    {
//        bank.deposit(_ctrl.getMemories());
//    }
//
//    protected function bankWithdraw (bank :Object) :void
//    {
//        BankUtil.replaceMemories(_ctrl, bank.withdraw());
//    }
    protected function registerControllerFunction (name :String, func :Function) :void
    {
        // Wrap it another function which handles delegation to controller
        _svc[name] = function (... args) :void {
            if (_ctrl.hasControl()) {
//                _ctrl.doBatch(func, args);
                _ctrl.doBatch(function () :void {
                    func.apply(null, args);
                });
            } else {
                args = args.map(function (o :*) :* {
                    return (o != null && "getIdent" in o) ? o.getIdent() : o;
                });
                _ctrl.sendMessage("call", [name].concat(args));
            }
        };
    }

    protected function registerControllerFunctions (funcs :Object) :void
    {
        for (var name :String in funcs) {
            registerControllerFunction(name, funcs[name] as Function);
        }
    }

    protected var _ctrl :AvatarControl;

    protected var _quest :PlayerSprite;

    protected var _doll :Doll;

    [Embed(source="rsrc/ghost.png")]
    protected static const GHOST :Class;
    protected var _ghost :Bitmap;

    protected var _inventory :Inventory;

    [Embed(source="rsrc/@KLASS@Counter.mp3")]
    protected static const SOUND_COUNTER :Class;
    protected var _soundCounter :Sound = new SOUND_COUNTER as Sound;

    [Embed(source="rsrc/@KLASS@Heal.mp3")]
    protected static const SOUND_HEAL :Class;
    protected var _soundHeal :Sound = new SOUND_HEAL as Sound;

    [Embed(source="rsrc/@KLASS@Die.mp3")]
    protected static const SOUND_DIE :Class;
    protected var _soundDie :Sound = new SOUND_DIE as Sound;

    [Embed(source="rsrc/levelup.mp3")]
    protected static const SOUND_LEVELUP :Class;
    protected var _levelupSound :Sound = new SOUND_LEVELUP as Sound;

    /**
     * EZ modder: To replace the equippable avatar sprite with a static image, put your image
     * in rsrc/body.png and uncomment the following line.
     */
    //[Embed(source="rsrc/body.png")]
    protected var BODY :Class;
    protected var _body :Bitmap = (BODY == null) ? null : new BODY();

    protected const _klass :Klass = new @KLASS@();

    protected var _svc :Object;
}

}
