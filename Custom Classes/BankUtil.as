package {

import com.whirled.AvatarControl;
import com.whirled.EntityControl;

public class BankUtil
{
    public static function replaceMemories (ctrl :AvatarControl, mems :Object) :void
    {
        if (mems == null) {
            return;
        }

        ctrl.doBatch(function () :void {
            // No set theory here, just make it work
            for (var key :String in ctrl.getMemories()) {
                ctrl.setMemory(key, null);
            }
            for (key in mems) {
                ctrl.setMemory(key, mems[key]);
            }
        });
    }

    public static function getBank (ctrl :EntityControl, id :String) :Object
    {
        return ctrl.getEntityProperty("bank:v1", id);
    }

    public static function find (ctrl :EntityControl) :Object
    {
        for each (var id :String in ctrl.getEntityIds(EntityControl.TYPE_FURNI)) {
            var bank :Object = getBank(ctrl, id);
            if (bank != null) {
                return bank;
            }
        }
        return null;
    }
}

}
