package {

import flash.events.*;
import flash.display.*;
import flash.media.*;
import flash.text.*;

import com.whirled.*;

import com.threerings.util.Command;
import com.threerings.text.TextFieldUtil;

public class GuardInventory
{
    public function GuardInventory (ctrl :PetControl, klass :GuardKlass, doll :Doll)
    {
        _ctrl = ctrl;
        _klass = klass;
        _doll = doll;

        _ctrl.addEventListener(ControlEvent.MEMORY_CHANGED, handleMemory);

        _attackSounds = [];
        _attackSounds[Items.BOW] = Sound(new SOUND_BOW());
        _attackSounds[Items.CLUB] = Sound(new SOUND_CLUB());
        _attackSounds[Items.AXE] = Sound(new SOUND_AXE());
        _attackSounds[Items.SWORD] = Sound(new SOUND_SWORD());
        _attackSounds[Items.SPEAR] = Sound(new SOUND_SPEAR());
        _attackSounds[Items.MAGIC] = Sound(new SOUND_MAGIC());
        _attackSounds[Items.DAGGER] = Sound(new SOUND_DAGGER());

        updateDoll();
    }

    public function offer (item :int, bonus :int) :Boolean
    {
        var slot :int = Items.TABLE[item][2];
        var memory :Array = _ctrl.getMemory("#"+slot) as Array;
        if (memory == null
            || (Items.TABLE[memory[0]][4]+memory[1]) * _klass.getMultiplier(Items.TABLE[memory[0]][3])
            <= (Items.TABLE[item][4]+bonus) * _klass.getMultiplier(Items.TABLE[item][3])) {
            _ctrl.setMemory("#"+slot, [item, bonus]);
            return true;
        } else {
            return false;
        }
    }

    protected function handleMemory (event :ControlEvent) :void
    {
        if (event.name.charAt(0) == "#") {
            updateDoll();
        }
    }

    protected function updateDoll () :void
    {
        var sprites :Array = _klass.getBaseSprites();
        for (var slot :int = 0; slot < Items.SLOT_COUNT; ++slot) {
            var memory :Array = _ctrl.getMemory("#"+slot) as Array;
            if (memory != null) {
                var sprite :int = Items.TABLE[memory[0]][0];
                if (slot == Items.BACK) {
                    sprites.unshift(sprite);
                } else {
                    sprites.push(sprite);
                }
            }
        }
        if (_ctrl.getMemory("#"+Items.HEAD) == null) {
            sprites = sprites.concat(_klass.getHairSprites());
        }

        _doll.layer(sprites);
    }

    public function getRange () :Number
    {
        var memory :Array = _ctrl.getMemory("#" + Items.HAND) as Array;
        if (memory != null) {
            switch (Items.TABLE[memory[0]][3]) {
                case Items.BOW: return 1600;
                case Items.MAGIC: return 800;
            }
        }
        return 400;
    }

    protected function getAttackMultiplier (slot :int) :Number
    {
        return (slot == Items.HAND || slot == Items.GLOVES) ? 1 : 0;
    }

    protected function getDefenceMultiplier (slot :int) :Number
    {
        return (getAttackMultiplier(slot) > 0) ? 0 : 1;
    }

    public function getPower () :Number
    {
        var sum :Number = 0;
        for (var slot :int = 0; slot < Items.SLOT_COUNT; ++slot) {
            var memory :Array = _ctrl.getMemory("#"+slot) as Array;
            if (memory != null) {
                var power :int = Items.TABLE[memory[0]][4];
                var type :int = Items.TABLE[memory[0]][3];
                var bonus :int = memory[1];
                sum += getAttackMultiplier(slot) * ((power+bonus) * _klass.getMultiplier(type));
            }
        }

        return sum;
    }

    public function getDefence () :Number
    {
        var sum :Number = 0;
        for (var slot :int = 0; slot < Items.SLOT_COUNT; ++slot) {
            var memory :Array = _ctrl.getMemory("#"+slot) as Array;
            if (memory != null) {
                var power :int = Items.TABLE[memory[0]][4];
                var type :int = Items.TABLE[memory[0]][3];
                var bonus :int = memory[1];
                sum += getDefenceMultiplier(slot) * ((power+bonus) * _klass.getMultiplier(type));
            }
        }

        return sum;
    }

    public function getAttackSound () :Sound
    {
        var memory :Array = _ctrl.getMemory("#"+Items.HAND) as Array;
        if (memory != null) {
            var type :int = Items.TABLE[memory[0]][3];
            return _attackSounds[type];
        } else {
            return _attackSoundDefault;
        }
    }

    [Embed(source="rsrc/fist.mp3")]
    protected static const SOUND_FIST :Class;
    [Embed(source="rsrc/bow.mp3")]
    protected static const SOUND_BOW :Class;
    [Embed(source="rsrc/club.mp3")]
    protected static const SOUND_CLUB :Class;
    [Embed(source="rsrc/axe.mp3")]
    protected static const SOUND_AXE :Class;
    [Embed(source="rsrc/sword.mp3")]
    protected static const SOUND_SWORD :Class;
    [Embed(source="rsrc/spear.mp3")]
    protected static const SOUND_SPEAR :Class;
    [Embed(source="rsrc/magic.mp3")]
    protected static const SOUND_MAGIC :Class;
    [Embed(source="rsrc/dagger.mp3")]
    protected static const SOUND_DAGGER :Class;

    /** Maps item category to Sounds. */
    protected var _attackSounds :Array;

    protected var _attackSoundDefault :Sound = Sound(new SOUND_FIST());

    protected var _ctrl :PetControl;
    protected var _klass :GuardKlass;
    protected var _doll :Doll;
}

}
