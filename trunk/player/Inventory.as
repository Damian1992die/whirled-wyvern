package {

import flash.events.*;
import flash.display.*;
import flash.media.*;
import flash.text.*;

import com.whirled.*;

import com.threerings.util.Command;
import com.threerings.flash.TextFieldUtil;

import klass.Klass;

public class Inventory extends Sprite
{
    public static const MAX_BAGS :int = 50;

    public static const ARMOR_LABELS :Array = [
        "Arcane",
        "Light",
        "Heavy",
    ]

    public function Inventory (ctrl :EntityControl, klass :Klass, doll :Doll)
    {
        _ctrl = ctrl;
        _klass = klass;
        _doll = doll;

        _ctrl.addEventListener(ControlEvent.MEMORY_CHANGED, handleMemory);
        Command.bind(_ctrl, ControlEvent.MEMORY_CHANGED, updateStatus);

        Command.bind(this, MouseEvent.ROLL_OUT, endDrag);
        Command.bind(this, MouseEvent.ROLL_OUT, function () :void {
            _trashCan.visible = false;
        });

        addChild(_itemPreview);
        _itemText.x = (Doll.SIZE+8);
        addChild(_itemText);

        addChild(_statusText);

        _bags = new Array(MAX_BAGS);
        graphics.lineStyle(2, 0x0000ff);
        for (var i :int = 0; i < MAX_BAGS; ++i) {
            var bag :InventoryBag = new InventoryBag(i);
            bag.x = Doll.SIZE*(i%10);
            bag.y = Doll.SIZE*int(i/10) + (Doll.SIZE+8);

            graphics.drawRect(bag.x, bag.y, Doll.SIZE, Doll.SIZE);

            bag.container.addEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown);
            bag.container.addEventListener(MouseEvent.MOUSE_UP, handleMouseUp);
            Command.bind(bag, MouseEvent.ROLL_OVER, preview, i);
            Command.bind(bag, MouseEvent.ROLL_OUT, clearPreview);

            _bags[i] = bag;
            addChild(bag);
        }


        addEventListener(MouseEvent.MOUSE_MOVE, function (event :MouseEvent) :void {
            if (_dragged != null) {
                _trashCan.bitmapData = (_dragged.container.dropTarget == _trashCan) ?
                    _iconTrashFull : _iconTrashEmpty;
            }
        });

        _trashCan.bitmapData = _iconTrashEmpty;
        _trashCan.x = this.width - 32;
        _trashCan.visible = false;
        addChild(_trashCan);

        _helpText.y = _bags[MAX_BAGS-1].y + Doll.SIZE + 8;
        addChild(_helpText);

        _attackSounds = [];
        _attackSounds[Items.BOW] = Sound(new SOUND_BOW());
        _attackSounds[Items.CLUB] = Sound(new SOUND_CLUB());
        _attackSounds[Items.AXE] = Sound(new SOUND_AXE());
        _attackSounds[Items.SWORD] = Sound(new SOUND_SWORD());
        _attackSounds[Items.SPEAR] = Sound(new SOUND_SPEAR());
        _attackSounds[Items.MAGIC] = Sound(new SOUND_MAGIC());
        _attackSounds[Items.DAGGER] = Sound(new SOUND_DAGGER());

        updateBags();
        updateDoll();
        updateStatus();
    }

    public function deposit (item :int, bonus :int) :Boolean
    {
        for (var i :int = 0; i < MAX_BAGS; ++i) {
            var memory :Array = _ctrl.getMemory("#"+i) as Array;
            if (memory == null) {
                _ctrl.setMemory("#"+i, [item, bonus]);
                return true;
            }
        }

        return false;
    }

    /** Like deposit(), but for a bunch of items. */
    public function depositGroup (items :Array, bonuses :Array) :Boolean
    {
        for (var i :int = 0, x :int = 0; i < MAX_BAGS && x < items.length; ++i) {
            var memory :Array = _ctrl.getMemory("#"+i) as Array;
            if (memory == null) {
                _ctrl.setMemory("#"+i, [items[x], bonuses[x]]);
                x += 1;
            }
        }

        return x == items.length;
    }

    protected function handleClick (event :MouseEvent) :void
    {
        _ctrl.doBatch(function () :void {
            var bag :int = InventoryBag(event.currentTarget).bag;
            if (event.ctrlKey) {
                destroy(bag);
            } else {
                equip(bag);
            }
        });
    }

    protected function handleMouseDown (event :MouseEvent) :void
    {
        _dragged = InventoryBag(event.currentTarget.parent);

        _dragged.container.startDrag();
        setChildIndex(_dragged, numChildren-1); // Bring to front
    }

    protected function handleMouseUp (event :MouseEvent) :void
    {
        if (_dragged == null) {
            return;
        }

        if (_dragged.container.dropTarget == _trashCan) {
            destroy(_dragged.bag);
            _trashCan.bitmapData = _iconTrashEmpty;

        } else {
            var target :InventoryBag =
                GraphicsUtil.findParent(_dragged.container.dropTarget, InventoryBag) as InventoryBag;

            if (_dragged == target) {
                _ctrl.doBatch(function () :void {
                    equip(_dragged.bag);
                });

            } else if (target != null) {
                _ctrl.doBatch(function () :void {
                    var from :int = _dragged.bag;
                    var to :int = target.bag;
                    swap(to, from);
                });

            } else {
                _trashCan.visible = false;
            }
        }

        endDrag();
    }

    protected function endDrag () :void
    {
        _dragged.container.stopDrag();
        _dragged.container.x = 0;
        _dragged.container.y = 0;
        _dragged = null;
    }

    protected function destroy (bag :int) :void
    {
        _ctrl.setMemory("#" + bag, null);
    }

    protected function equip (bag :int) :void
    {
        var memory :Array = _ctrl.getMemory("#" + bag) as Array;
        if (memory != null) {
            if (memory[2] == true) {
                delete memory[2];

            } else {
                // Unequip other items in this slot
                var mySlot :int = Items.TABLE[memory[0]][2];
                for (var i :int = 0; i < MAX_BAGS; ++i) {
                    var other :Array = _ctrl.getMemory("#"+i) as Array;
                    if (other != null && Items.TABLE[other[0]][2] == mySlot && other[2] == true) {
                        delete other[2];
                        _ctrl.setMemory("#"+i, other);
                    }
                }
                memory[2] = true;
            }
            _ctrl.setMemory("#" + bag, memory);
        }
    }

    /** Swap two bag contents. */
    protected function swap (firstBag :int, secondBag :int) :void
    {
        var first :Array = _ctrl.getMemory("#" + firstBag) as Array;
        var second :Array = _ctrl.getMemory("#" + secondBag) as Array;

        _ctrl.setMemory("#" + firstBag, second);
        _ctrl.setMemory("#" + secondBag, first);
    }

    protected function preview (bag :int) :void
    {
        var memory :Array = _ctrl.getMemory("#" + bag) as Array;
        if (memory != null) {
            var item :Array = Items.TABLE[memory[0]];
            _itemPreview.layer([ item[0] ]);
            _itemText.text = item[1] + " [" + item[4] + "]";
            if (memory[1] != 0) {
                _itemText.appendText(" " + WyvernUtil.deltaText(memory[1]));
            }
            // If not a weapon and not typeless
            if (item[2] != Items.HAND && item[3] != -1) {
                _itemText.appendText("\n(" + ARMOR_LABELS[item[3]] + ")");
            }

            _itemText.visible = true;
            _statusText.visible = false;

            _trashCan.visible = true;
        }
    }

    protected function clearPreview () :void
    {
        _itemPreview.layer([]);
        _itemText.visible = false;
        _statusText.visible = true;

        _trashCan.visible = (_dragged != null);
    }

    protected function handleMemory (event :ControlEvent) :void
    {
//        // These are only relevant to the avatar wearer
//        if ( ! _ctrl.hasControl()) {
//            return;
//        }

        if (event.name.charAt(0) == "#") {
            var bag :int = int(event.name.substr(1));
            if (event.value != null) {
                var item :int = event.value[0] as int;
                var bonus :int = event.value[1] as int;
                var equipped :Boolean = event.value[2] as Boolean;

                // Update the inventory bag
                _bags[bag].setItem(item, equipped);
            } else {
                _bags[bag].reset();
            }

            updateDoll();
        }
    }

    protected function updateStatus () :void
    {
        var xp :int = _ctrl.getMemory("xp") as int;
        var level :int = WyvernUtil.getLevel(xp);
        var start :int = WyvernUtil.getXp(level);

        var text :String = "Attack: " + Math.round(getPower()) +
            ", Defence: " + Math.round(getDefence()) + "\n" +
            "Level " + level + " (";

        if (level < PlayerCodes.MAX_LEVEL) {
            text += (int(100*((xp-start) / (WyvernUtil.getXp(level+1)-start)))) + "% to next)"
        } else {
            text += "GODLIKE";
        }

        _statusText.text = text + ")";
    }

    protected function updateBags () :void
    {
        for (var i :int = 0; i < MAX_BAGS; ++i) {
            var memory :Array = _ctrl.getMemory("#"+i) as Array;
            if (memory != null) {
                _bags[i].setItem(memory[0], memory[2]);
            }
        }
    }

    protected function updateDoll () :void
    {
        var base :Array = _klass.getBaseSprites();

        var sprites :Array = [];
        _equipment = [];
        for (var i :int = 0; i < MAX_BAGS; ++i) {
            var memory :Array = _ctrl.getMemory("#"+i) as Array;
            if (memory != null && memory[2] == true) {
                var item :Array = Items.TABLE[memory[0]];

                //_equipment[item[2]] = item;
                _equipment[item[2]] = memory;

                if (item[2] == Items.BACK) {
                    base.unshift(item[0]);
                } else {
                    sprites[item[2]] = item[0];
                }
            }
        }

        if ( ! (Items.HEAD in _equipment) && _klass.getHairSprites() != null) {
            sprites.splice(Items.HAND, 0, _klass.getHairSprites());
        }

        _doll.layer(base.concat(sprites));
    }

    public function getRange () :Number
    {
        //return (Items.HAND in _equipment) ? _equipment[Items.HAND][5] : 100;
        if (Items.HAND in _equipment) {
            switch (Items.TABLE[_equipment[Items.HAND][0]][3]) {
                case Items.BOW: return 1600;
                case Items.MAGIC: return 800;
            }
        }
        return 400;
    }

    public function getPower () :Number
    {
        if (Items.HAND in _equipment) {
            return (Items.TABLE[_equipment[Items.HAND][0]][4] + _equipment[Items.HAND][1]) *
                _klass.getMultiplier(Items.TABLE[_equipment[Items.HAND][0]][3]);
        } else {
            return 0;
        }
    }

    public function getDefence () :Number
    {
        var defence :int = 0;
        for each (var memory :Array in _equipment) {
            // If it's not a weapon
            if (Items.TABLE[memory[0]][2] != Items.HAND) {
                defence += (Items.TABLE[memory[0]][4] + memory[1]) *
                    _klass.getMultiplier(Items.TABLE[memory[0]][3]);
            }
        }
        return defence;
    }

    public function getAttackSound () :Sound
    {
        return (Items.HAND in _equipment) ?
            _attackSounds[Items.TABLE[_equipment[Items.HAND][0]][3]] :
            _attackSoundDefault;
    }

    [Embed(source="rsrc/fist.mp3")]
    protected static const SOUND_FIST :Class;
    [Embed(source="rsrc/bow.mp3")]
    protected static const SOUND_BOW :Class;
    [Embed(source="rsrc/club.mp3")]
    protected static const SOUND_CLUB :Class;
    [Embed(source="rsrc/axe.mp3")]
    protected static const SOUND_AXE :Class;
    [Embed(source="rsrc/sword.mp3")]
    protected static const SOUND_SWORD :Class;
    [Embed(source="rsrc/spear.mp3")]
    protected static const SOUND_SPEAR :Class;
    [Embed(source="rsrc/magic.mp3")]
    protected static const SOUND_MAGIC :Class;
    [Embed(source="rsrc/dagger.mp3")]
    protected static const SOUND_DAGGER :Class;

    protected var _itemPreview :Doll = new Doll();;
    protected var _itemText :TextField = TextFieldUtil.createField("",
        { textColor: 0xffffff, selectable: false,
            autoSize: TextFieldAutoSize.LEFT, outlineColor: 0x00000 },
        { font: "_sans", size: 12, bold: true });

    protected var _statusText :TextField = TextFieldUtil.createField("",
        { textColor: 0xffffff, selectable: false,
            autoSize: TextFieldAutoSize.LEFT, outlineColor: 0x00000 },
        { font: "_sans", size: 12, bold: true });

    protected var _helpText :TextField = TextFieldUtil.createField(
        "Click to wear an item, ctrl+click to permanently delete it.", {
            textColor: 0xc0c0c0, selectable: false,
            autoSize: TextFieldAutoSize.LEFT, outlineColor: 0x00000 },
        { font: "_sans", size: 8 });

    protected var _statusLine :String;

    [Embed(source="rsrc/trashcan_empty.png")]
    protected static const ICON_TRASH_EMPTY :Class;
    protected var _iconTrashEmpty :BitmapData = BitmapData(new ICON_TRASH_EMPTY().bitmapData);
    [Embed(source="rsrc/trashcan_full.png")]
    protected static const ICON_TRASH_FULL :Class;
    protected var _iconTrashFull :BitmapData = BitmapData(new ICON_TRASH_FULL().bitmapData);

    protected var _trashCan :Bitmap = new Bitmap();

    /** Maps item category to Sounds. */
    protected var _attackSounds :Array;

    protected var _attackSoundDefault :Sound = Sound(new SOUND_FIST());

    protected var _bags :Array;
    protected var _equipment :Array = []; // Maps slots to memory bags
    protected var _dragged :InventoryBag; // The bag currently being dragged

    protected var _ctrl :EntityControl;
    protected var _klass :Klass;
    protected var _doll :Doll;
}

}
