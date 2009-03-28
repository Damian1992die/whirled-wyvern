package {

import flash.display.*;

public class InventoryBag extends Sprite
{
    // Stuff for drag and dropping
    public var container :Sprite = new Sprite();
    public var background :Sprite = new Sprite();

    public var bag :int;

    public function InventoryBag (bag :int)
    {
        this.bag = bag;

        // Bordered background
        background.graphics.lineStyle(2, 0x0000ff);
        background.graphics.beginFill(0, 1);
        background.graphics.drawRect(0, 0, Doll.SIZE, Doll.SIZE);
        background.graphics.endFill();

        addChild(background);
        addChild(container);
    }

    public function setItem (item :int, equipped :Boolean) :void
    {
        reset();

        if (equipped) {
            container.graphics.beginFill(0xff0000, 0.2);
            container.graphics.drawRect(2, 2, 30, 30);
            container.graphics.endFill();
        }

        var doll :Doll = new Doll();
        var data :Array = Items.TABLE[item] as Array;
        doll.layer([data[0]]);

        container.addChild(doll);
    }

    public function reset () :void
    {
        while (container.numChildren > 0) {
            container.removeChildAt(0);
        }
        container.graphics.clear();
    }
}

}
