//
// $Id$

package {

import flash.display.*;
import flash.text.*;

import com.threerings.flash.TextFieldUtil;

import com.whirled.ToyControl;
import com.whirled.ControlEvent;

[SWF(width="200", height="200")]
public class Bank extends Sprite
{
    public function Bank ()
    {
        _ctrl = new ToyControl(this);

        _ctrl.registerPropertyProvider(propertyProvider);

        _image = Bitmap(new IMAGE());
        addChild(_image);
    }

    public function propertyProvider (name :String) :Object
    {
        if (name == "bank:v1") {
            return _svc;
        } else {
            return null;
        }
    }

    protected const _svc :Object = {
        deposit: function (key :String, mems :Object) :void {
            _ctrl.setMemory(key, mems, function (success :Boolean) :void {
                GraphicsUtil.feedback(_ctrl, success ?
                    "Deposit successful. When you want to restore your backup, use the piggy in this room." :
                    "Deposit FAILED! This bank is full, find a piggy in another room.",
                    0xffffff);
            });
        },
        withdraw: function (key :String) :Object {
            var mems :Object = _ctrl.getMemory(key);
            if (mems == null) {
                GraphicsUtil.feedback(_ctrl, "Your avatar backup wasn't found to be in this piggy.");
            }
            return mems;
        }
    }

    protected var _ctrl :ToyControl;

    [Embed(source="icon.jpg")]
    protected static const IMAGE :Class;
    protected var _image :Bitmap;
}
}
