package {

import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.TextEvent;
import flash.text.StyleSheet;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;

import com.threerings.text.TextFieldUtil;

import com.whirled.EntityControl;

public class GraphicsUtil
{
    /** Walk up the scene graph until we get a node of the right type, or null. */
    public static function findParent (node :DisplayObject, parentClass :Class) :DisplayObject
    {
        try {
            while (node != null) {
                if (node is parentClass) {
                    return node;
                }
                node = node.parent;
            }
        } catch (error :SecurityError) { }

        return null;
    }

    /** Whirled removed the built-in padding in popups, but I liked it... */
    public static function showPopup (
        ctrl :EntityControl, title :String, node :DisplayObject, width :int = -1, height :int = -1) :void
    {
        if (width < 0) {
            width = node.width;
        }
        if (height < 0) {
            height = node.height;
        }

        var panel :Sprite = new Sprite();
        panel.addChild(node);
        panel.x = POPUP_PADDING;
        panel.y = POPUP_PADDING;

        ctrl.showPopup(title, panel, width+2*POPUP_PADDING, height+2*POPUP_PADDING, 0, 0.8);
    }

    public static function feedback (ctrl :EntityControl, message :String, color :int = 0xff0000) :void
    {
        var tf :TextField = TextFieldUtil.createField("",
            { textColor: color, selectable: false,
                outlineColor: 0x00000, wordWrap: true, multiline: true, width: 250, height: 400 },
            { font: "_sans", size: 14, bold: true, align: "justify" });

        tf.htmlText = message;
//        tf.addEventListener(TextEvent.LINK, function (event :TextEvent) :void {
//            ctrl.showPage(event.text);
//        });

        var css :StyleSheet = new StyleSheet();
        css.setStyle("a", {
            color: "#0000ff",
            textDecoration: "underline"
        });
        tf.styleSheet = css;

        showPopup(ctrl, "Feedback", tf, tf.width, tf.textHeight);
    }

    public static const POPUP_PADDING :int = 10;
}

}
