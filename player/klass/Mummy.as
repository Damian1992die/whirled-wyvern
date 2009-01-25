package klass {

import com.whirled.AvatarControl;

public class Mummy
    implements Klass
{
    public function getBaseSprites () :Array
    {
        return [ 71 ];
    }

    public function getHairSprites () :Array
    {
        return null;
    }

    public function getTraits () :Array
    {
        return [ WyvernConstants.TRAIT_PLUS_COUNTER ];
    }

    public function getMultiplier (itemType :int) :Number
    {
        switch (itemType) {
            case Items.HEAVY: return 1.5;
            case Items.CLUB: case Items.AXE: case Items.SWORD: case Items.SPEAR: return 1.7;
            case Items.LIGHT: case Items.BOW: return 1.2;
            case Items.ARCANE: case Items.MAGIC: return 0.8;
        }
        return 1;
    }

    public function handleSpecial (ctrl :AvatarControl, sprite :PlayerSprite) :Boolean
    {
        var mana :Number = sprite.getMana();
        if (mana >= 0.4) {
            ctrl.setMemory("mana", mana-0.4);
            sprite.effect({text: "TODO"});
            return true;
        } else {
            return false;
        }
    }
}

}
