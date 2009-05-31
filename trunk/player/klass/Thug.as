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
    public static const CHARGE_BREADTH :int = 600;
    public static const CHARGE_LENGTH :int = 400;
    public static const CHARGE_COST :Number = 0.4;

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
    
    public function getName () :String
    {
        return "Warrior";
    }

    public function getSpecialName () :String
    {
        return "Whirlwind";
    }

    public function handleSpecial (ctrl :AvatarControl, sprite :PlayerSprite) :Boolean
    {
        var mana :Number = sprite.getMana();
        if (mana >= CHARGE_COST) {
            if (ctrl.hasControl()) {
                var here :Array = ctrl.getPixelLocation() as Array;
                var self :Object = WyvernUtil.self(ctrl);
                var damage :Number = WyvernUtil.getAttackDamage(self);
                var orient :Number = ctrl.getOrientation();
                var bounds :Array = ctrl.getRoomBounds();

                var transform :Matrix = new Matrix();
                transform.translate(-here[0], -here[2]);
                transform.rotate((90-orient)*Math.PI/180);

                var rect :Rectangle = new Rectangle();
                rect.topLeft = new Point(0, -CHARGE_BREADTH/2);
                rect.height = CHARGE_BREADTH;
                rect.width = CHARGE_LENGTH;

                var targets :Array = WyvernUtil.query(ctrl, function (svc :Object, id :String) :Boolean {
                    var there :Array = ctrl.getEntityProperty(EntityControl.PROP_LOCATION_PIXEL, id) as Array;
                    return WyvernUtil.isAttackable(ctrl, svc) &&
                        rect.containsPoint(transform.transformPoint(new Point(there[0], there[2])));
    //                    WyvernUtil.insideArc(here, orient, 180,
    //                        ctrl.getEntityProperty(EntityControl.PROP_LOCATION_PIXEL, id) as Array);
                });

                for each (var target :Object in targets) {
                    WyvernUtil.attack(ctrl, target);
                }
                ctrl.setMemory("mana", mana-CHARGE_COST);
                sprite.effect({text: "WHIRL YOU UP!", event:WyvernConstants.EVENT_ATTACK});

                transform.invert();
                var end :Point = transform.transformPoint(new Point(rect.width, 0));

                // TODO: Weaksauce wall handling, but fine for now
                end.x = Math.max(0, Math.min(end.x, bounds[0]));
                end.y = Math.max(0, Math.min(end.y, bounds[2]));

                ctrl.setPixelLocation(end.x, 0, end.y, ctrl.getOrientation());
            }

            var doll :DisplayObject = sprite.getActor();
            if (doll != _vortex) {
                sprite.setActor(_vortex);
                Tweener.addTween(this, {time:1.5, onComplete: function () :void {
                    sprite.setActor(doll);
                }});
                _vortexSound.play();
            }

            return true;
        } else {
            if (ctrl.hasControl()) {
                sprite.echo("Me too tired!");
            }
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
