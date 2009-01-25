package {

import flash.events.Event;
import flash.display.Sprite;

public class ProgressBar extends Sprite
{
    public var color :int;
    public var background :int;

    public static const WIDTH :int = 80;
    public static const HEIGHT :int = 6;

    public function ProgressBar (color :int, background :int)
    {
        this.color = color;
        this.background = background;
    }

    public function set percent (p :Number) :void
    {
        p = Math.min(Math.max(0, p), 1);

        graphics.beginFill(color);
        graphics.drawRect(0, 0, WIDTH*p, HEIGHT);
        graphics.endFill();

        graphics.beginFill(background);
        graphics.drawRect(WIDTH*p, 0, WIDTH*(1-p), HEIGHT);
        graphics.endFill();
    }
}

}
