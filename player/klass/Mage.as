package klass {

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

    public function handleSpecial (ctrl :AvatarControl, sprite :PlayerSprite) :Boolean
    {
        // TODO: Play a sound here

        if ( ! ctrl.hasControl()) {
            return true;
        }

        var cost :Number = 0.1;
        var mana :Number = sprite.getMana();
        if (mana >= cost) {
            var here :Array = ctrl.getLogicalLocation() as Array;
            var self :Object = WyvernUtil.self(ctrl);
            var damage :Number = WyvernUtil.getAttackDamage(self);
            var orient :Number = ctrl.getOrientation();

            var targets :Array = WyvernUtil.query(ctrl, function (svc :Object, id :String) :Boolean {
                return WyvernUtil.isAttackable(ctrl, svc) &&
                    WyvernUtil.insideArc(here, orient, 180,
                        ctrl.getEntityProperty(EntityControl.PROP_LOCATION_LOGICAL, id) as Array);
            });

            for each (var target :Object in targets) {
                WyvernUtil.attack(ctrl, target);
            }
            ctrl.setMemory("mana", mana-cost);
            sprite.effect({text: "Falcon... PAWNCH!!", event:WyvernConstants.EVENT_ATTACK});
            return true;
        } else {
            return false;
        }
    }
}

}
