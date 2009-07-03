package {

import flash.display.*;
import flash.filters.*;
import flash.text.*;
import flash.events.MouseEvent;

import caurina.transitions.Tweener;

import com.threerings.flash.TextFieldUtil;
import com.threerings.util.Command;

public class Button extends Sprite
{
    public function Button (icon :DisplayObject, text :String)
    {
        _icon = icon;

        const WIDTH :Number = 200;
//        this.width = 200;
//        this.height = 50;

        this.graphics.beginFill(0x000000, 0.0);
        this.graphics.drawRect(0, 0, WIDTH, 64);
        this.graphics.endFill();

        this.graphics.lineStyle(2, 0);
        this.graphics.beginFill(0xcc7722);
        this.graphics.drawRect(0, 16, WIDTH, 32);
        this.graphics.endFill();

        var label :TextField = TextFieldUtil.createField(text,
            { textColor: 0xffffff, selectable: false, autoSize: TextFieldAutoSize.CENTER,
                y: 16, width: WIDTH },
            { font: "_sans", size: 16, bold: true });
        addChild(label);

        Command.bind(this, MouseEvent.ROLL_OVER, slideIcon, [ 0, WIDTH - _icon.width ]);
        Command.bind(this, MouseEvent.ROLL_OUT, slideIcon, [ WIDTH - _icon.width, 0 ]);

        var glow :GlowFilter = new GlowFilter(0xffffff, 80, 20, 20, 0, BitmapFilterQuality.HIGH);

        var update :Function = function () :void { // Sigh
            filters = [ glow ];
        }
        Command.bind(this, MouseEvent.ROLL_OVER, Tweener.addTween, [
            glow, {strength: 4, time: 2, onUpdate: update} ]);
        Command.bind(this, MouseEvent.ROLL_OUT, Tweener.addTween, [
            glow, {strength: 0, time: 2, onUpdate: update} ]);

        addChild(_icon);
    }

//    protected function fade () :void
//    {
//    }

    protected function slideIcon (from :Number, to :Number) :void
    {
        _icon.x = from;
        Tweener.addTween(_icon, {x: to, time: 1});
    }

    protected var _icon :DisplayObject;
}

}
