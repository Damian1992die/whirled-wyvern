package {

import com.whirled.EntityControl;

public class WyvernUtil
{
    public static function query (ctrl :EntityControl, filter :Function = null) :Array
    {
        var arr :Array = [];
        for each (var id :String in ctrl.getEntityIds()) {
            var svc :Object = getService(ctrl, id);
            if (svc != null && (filter == null || filter(svc, id))) {
                arr.push(svc);
            }
        }
        return arr;
    }

    public static function getService (ctrl :EntityControl, otherId :String) :Object
    {
        return ctrl.getEntityProperty(WyvernConstants.SERVICE_KEY, otherId);
    }

    public static function getAttackDamage (source :Object) :Number
    {
        return Math.max(1, source.getPower() + (source.getLevel()*0.2));
    }

    public static function squareDistance (ctrl :EntityControl, otherId :String) :Number
    {
        var me :Array = ctrl.getPixelLocation();
        var other :Array = ctrl.getEntityProperty(EntityControl.PROP_LOCATION_PIXEL, otherId) as Array;
        var d2 :Number = (me[0]-other[0])*(me[0]-other[0]) + (me[2]-other[2])*(me[2]-other[2]);
        return d2;
    }

    public static function fetchClosest (ctrl :EntityControl, filter :Function = null) :String
    {
        var min2 :Number = Number.MAX_VALUE;
        var candidate :String = null;
        var me :Array = ctrl.getPixelLocation();

        var arr :Array = [];
        for each (var id :String in ctrl.getEntityIds()) {
            if (id != ctrl.getMyEntityId()) {
                var svc :Object = getService(ctrl, id);
                if (svc != null && (filter == null || filter(svc, id))) {
                    var d2 :Number = squareDistance(ctrl, id)
                    if (d2 < min2 && (filter == null || filter(svc, id))) {
                        min2 = d2;
                        candidate = id;
                    }
                }
            }
        }

        return candidate;
    }

    public static function fetchAll (ctrl :EntityControl, range :Number, pixelLocation :Array = null) :Array
    {
        var range2 :Number = range*range;
        var me :Array = (pixelLocation != null) ? pixelLocation : ctrl.getPixelLocation();

        return query(ctrl, function (id :String, svc :Object) :Boolean {
            var other :Array = ctrl.getEntityProperty(EntityControl.PROP_LOCATION_PIXEL, id) as Array;
            var d2 :Number = (me[0]-other[0])*(me[0]-other[0]) + (me[2]-other[2])*(me[2]-other[2]);
            return d2 <= range2;
        });
    }

    public static function self (ctrl :EntityControl) :Object
    {
        return ctrl.getEntityProperty(WyvernConstants.SERVICE_KEY);
    }

    public static function svc (ctrl :EntityControl, entity :String) :Object
    {
        return ctrl.getEntityProperty(WyvernConstants.SERVICE_KEY, entity);
    }

    public static function getTotem (ctrl :EntityControl) :int
    {
        for each (var id :String in ctrl.getEntityIds(EntityControl.TYPE_FURNI)) {
            var influence :Object = ctrl.getEntityProperty(WyvernConstants.TOTEM_KEY, id);
            if (influence != null) {
                return Math.abs(int(influence));
            }
        }
        return -1; // No totem found
    }

    public static function deltaText (bonus :int) :String
    {
        if (bonus < 0) {
            return String(bonus);
        } else {
            return "+"+bonus;
        }
    }

    public static function getLevel (xp :int) :int
    {
        return Math.log((M+xp)/M)*K + 1;
        //return Math.pow(xp, K)/M + 1;
    }

    public static function getXp (level :int) :int
    {
        return Math.exp((level-1)/K)*M - M;
    }

    public static function insideArc (from :Array, orient :Number, degrees :Number, to :Array) :Boolean
    {
        var bearing :Number = Math.atan2(to[2]-from[2], to[0]-from[0]); // Radians
        bearing = int(360 + 90 + Math.round(180/Math.PI * bearing)) % 360; // Whirled degrees

        return Math.abs(bearing-orient) <= degrees/2;
    }

    public static function attack (ctrl :EntityControl, defender :Object) :Boolean
    {
        var self :Object = self(ctrl);
        var amount :Number = getAttackDamage(self);
        var orient :Number = ctrl.getEntityProperty(EntityControl.PROP_ORIENTATION) as Number;
        var ident :String = defender.getIdent();

        var d2 :Number = WyvernUtil.squareDistance(ctrl, ident);
        if (d2 <= Math.pow(self.getRange(), 2)) {
            if (Math.abs(int(ctrl.getEntityProperty(EntityControl.PROP_ORIENTATION, ident)) -
                orient) < 90) {
                // Backstab
                var backstab :Number = self.hasTrait(WyvernConstants.TRAIT_BACKSTAB) ? 3 : 2;
                defender.damage(self, amount*backstab, {text:"Critical!"});
            } else if (defender.getState() == WyvernConstants.STATE_COUNTER &&
                d2 <= Math.pow(defender.getRange(), 2)) {
                // Countered!
                self.damage(defender, getAttackDamage(defender), {text:"Countered!"});
                defender.damage(self, amount*0.25, { event: WyvernConstants.EVENT_COUNTER });

            } else {
                // Deal attack damage
                defender.damage(self, amount);
            }
            return true;

        } else {
            return false;
        }
    }

    public static function isAttackable (ctrl :EntityControl, defender :Object) :Boolean
    {
        var attacker :Object = self(ctrl);
        return attacker != defender &&
            defender.getState() != WyvernConstants.STATE_DEAD &&
            (defender.getFaction() != attacker.getFaction() ||
                getTotem(ctrl) >= Math.abs(attacker.getLevel() - defender.getLevel()));
    }

    protected static const K :Number = 10/Math.log(1.2);
    protected static const M :Number = 10000;
}

}
