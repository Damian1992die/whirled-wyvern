package klass {

import flash.display.*;
import flash.geom.*;
import flash.media.Sound;

import caurina.transitions.Tweener;

import com.whirled.AvatarControl;
import com.whirled.EntityControl;

public class Thug
    implements Klass
{
    public static const CHARGE_BREADTH :int = 200;
    public static const CHARGE_LENGTH :int = 400;
    public static const CHARGE_COST :Number = 0.1;

    public function getBaseSprites () :Array
    {
        return [ 84 ];
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
        var doll :DisplayObject = sprite.getActor();
        sprite.setActor(_vortex);
        Tweener.addTween(this, {time:1.5, onComplete: function () :void {
            sprite.setActor(doll);
        }});
        _vortexSound.play();

        if ( ! ctrl.hasControl()) {
            return true;
        }

        var mana :Number = sprite.getMana();
        if (mana >= CHARGE_COST) {
            var here :Array = ctrl.getPixelLocation() as Array;
            var self :Object = WyvernUtil.self(ctrl);
            var damage :Number = WyvernUtil.getAttackDamage(self);
            var orient :Number = ctrl.getOrientation();

            var rotate :Matrix = new Matrix();
            rotate.translate(-here[0], -here[2]);
            rotate.rotate((90-orient)*Math.PI/180);
            var rect :Rectangle = new Rectangle();
            var start :Point = new Point(here[0], here[2]);
            rect.topLeft = new Point(0, -CHARGE_BREADTH/2);//rotate.transformPoint(new Point);
            //rect.y -= CHARGE_BREADTH/2;
            rect.height = CHARGE_BREADTH;
            rect.width = CHARGE_LENGTH;

            var targets :Array = WyvernUtil.query(ctrl, function (svc :Object, id :String) :Boolean {
                var there :Array = ctrl.getEntityProperty(EntityControl.PROP_LOCATION_PIXEL, id) as Array;
                return WyvernUtil.isAttackable(ctrl, svc) &&
                    rect.containsPoint(rotate.transformPoint(new Point(there[0], there[2])));
//                    WyvernUtil.insideArc(here, orient, 180,
//                        ctrl.getEntityProperty(EntityControl.PROP_LOCATION_PIXEL, id) as Array);
            });

            for each (var target :Object in targets) {
                WyvernUtil.attack(ctrl, target);
            }
            ctrl.setMemory("mana", mana-CHARGE_COST);
            sprite.effect({text: "Falcon kick! " + orient + " Hit: " + targets.length, event:WyvernConstants.EVENT_ATTACK});

//            var end :Point = start.add(new Point(CHARGE_LENGTH, 0));

            rotate.invert();
            var end :Point = rotate.transformPoint(new Point(CHARGE_LENGTH, 0));
            ctrl.setPixelLocation(end.x, 0, end.y, ctrl.getOrientation());
            return true;

        } else {
            return false;
        }
    }

    [Embed(source="../rsrc/vortex.png")]
    protected static const VORTEX :Class;
    protected var _vortex :Bitmap = new VORTEX() as Bitmap;

    [Embed(source="../rsrc/vortex.mp3")]
    protected static const VORTEX_SOUND :Class;
    protected var _vortexSound :Sound = new VORTEX_SOUND as Sound;
}

}
