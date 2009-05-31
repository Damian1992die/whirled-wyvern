package klass {

import flash.media.Sound;

import com.whirled.AvatarControl;
import com.whirled.EntityControl;

public class Mage
    implements Klass
{
    public function getBaseSprites () :Array
    {
        return [ 58 ];
    }

    public function getHairSprites () :Array
    {
        return [ 275 ];
    }

    public function getTraits () :Array
    {
        return [ ]; // TODO
    }

    public function getMultiplier (itemType :int) :Number
    {
        switch (itemType) {
            case Items.ARCANE: return 1.6;
            case Items.MAGIC: case Items.DAGGER: return 1.5;
            case Items.SWORD: case Items.SPEAR: return 1.2;
            case Items.HEAVY: return 0.8;
        }
        return 1;
    }

    public function getName () :String
    {
        return "Arcanist";
    }

    public function getSpecialName () :String
    {
        return "Static Burst";
    }

    public function handleSpecial (ctrl :AvatarControl, sprite :PlayerSprite) :Boolean
    {
        var cost :Number = 0.4;
        var mana :Number = sprite.getMana();
        if (mana >= cost) {
            if (ctrl.hasControl()) {
                var here :Array = ctrl.getLogicalLocation() as Array;
                var self :Object = WyvernUtil.self(ctrl);
                var damage :Number = WyvernUtil.getAttackDamage(self);
                var orient :Number = ctrl.getOrientation();

                var targets :Array = WyvernUtil.query(ctrl, function (svc :Object, id :String) :Boolean {
                    return WyvernUtil.isAttackable(ctrl, svc);
                });

                for each (var target :Object in targets) {
                    for each (var splash :Object in targets) {
                        if (target != splash && 
                            WyvernUtil.squareDistanceBetween(ctrl, target.getIdent(), splash.getIdent()) < 250*250) {

                            splash.damage(self, WyvernUtil.getAttackDamage(self), {text: "ZAP!"});
                        }
                    }
                }

                ctrl.setMemory("mana", mana-cost);
                sprite.effect({text: "Static... BURST!", event:WyvernConstants.EVENT_ATTACK});
            }
            _specialSound.play();
            return true;
        } else {
            if (ctrl.hasControl()) {
                sprite.echo("I require more mana");
            }
            return false;
        }
    }

    [Embed(source="../rsrc/mage_special.mp3")]
    protected static const SPECIAL_SOUND :Class;
    protected var _specialSound :Sound = new SPECIAL_SOUND as Sound;
}

}
