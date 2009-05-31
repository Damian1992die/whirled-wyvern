package klass {

import flash.display.*;
import flash.geom.*;
import flash.media.Sound;
import flash.utils.setTimeout;

import com.whirled.AvatarControl;

public class Sneak
    implements Klass
{
    public function getBaseSprites () :Array
    {
        return [ 51 ];
    }

    public function getHairSprites () :Array
    {
        return [ 264 ];
    }

    public function getTraits () :Array
    {
        return [ WyvernConstants.TRAIT_BACKSTAB ];
    }

    public function getName () :String
    {
        return "Bandit";
    }

    public function getSpecialName () :String
    {
        return "Vanish";
    }

    public function getMultiplier (itemType :int) :Number
    {
        switch (itemType) {
            case Items.LIGHT: return 1.5;
            case Items.BOW: case Items.DAGGER: case Items.CLUB: return 1.5;
            case Items.SWORD: case Items.ARCANE: return 1.2;
            case Items.HEAVY: return 0.8;
        }
        return 1;
    }

    public function handleSpecial (ctrl :AvatarControl, sprite :PlayerSprite) :Boolean
    {
        var mana :Number = sprite.getMana();
        if (mana >= 0.4) {
            if (ctrl.hasControl()) {
                ctrl.setMemory("mana", mana-0.4);
            }

            if (!sprite.getHidden()) {
                ctrl.setHotSpot(600/2, 400, 500000);
                sprite.setHidden(true);
                setTimeout(function () :void {
                    sprite.visible = true;
                    _appearSound.play();
                    sprite.setHidden(false);
                }, 10000);
                _vanishSound.play();
            }

            return true;
        } else {
            if (ctrl.hasControl()) {
                sprite.echo("Damn, I need energy!");
            }
            return false;
        }
    }

    [Embed(source="../rsrc/sneak_special.mp3")]
    protected static const VANISH_SOUND :Class;
    protected var _vanishSound :Sound = new VANISH_SOUND as Sound;

    [Embed(source="../rsrc/SneakHeal.mp3")]
    protected static const APPEAR_SOUND :Class;
    protected var _appearSound :Sound = new APPEAR_SOUND as Sound;
}

}
