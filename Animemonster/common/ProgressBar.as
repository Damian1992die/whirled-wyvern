package {

import flash.events.Event;
import flash.display.Sprite;

public class ProgressBar extends Sprite
{
    public static const WIDTH :int = 80;
    public static const HEIGHT :int = 6;

    public function ProgressBar (color :int, background :int)
    {
        _color = color;
        _background = background;
        // Don't draw until we get a percent
    }

    public function set color (color :int) :void
    {
        _color = color;
        redraw();
    }

    public function set background (background :int) :void
    {
        _background = background;
        redraw();
    }

    public function set percent (p :Number) :void
    {
        _percent = Math.min(Math.max(0, p), 1);
        redraw();
    }

    protected function redraw () :void
    {
        graphics.beginFill(_color);
        graphics.drawRect(0, 0, WIDTH*_percent, HEIGHT);
        graphics.endFill();

        graphics.beginFill(_background);
        graphics.drawRect(WIDTH*_percent, 0, WIDTH*(1-_percent), HEIGHT);
        graphics.endFill();
    }

    protected var _percent :Number;
    protected var _background :int;
    protected var _color :int;
}

}
