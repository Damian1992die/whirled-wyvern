package {

import com.whirled.*;

public class PlayerSprite extends WyvernSprite
{
    public function PlayerSprite (ctrl :AvatarControl)
    {
        super(ctrl);

        _ctrl.addEventListener(ControlEvent.MESSAGE_RECEIVED, handlePlayerEvents);

        _manaBar.y = 8;
        _manaBar.x = center(ProgressBar.WIDTH);
        addChild(_manaBar);

        if (_ctrl.getMemory("mana") == null) {
            _ctrl.setMemory("mana", 1); // Full mana
        }
    }

    override protected function setupVisual () :void
    {
        super.setupVisual();

        _manaBar.y = _healthBar.y + _healthBar.height + 4;
    }

    override protected function tick () :void
    {
        super.tick();

        var mana :Number = getMana();
        var state :String = WyvernUtil.self(_ctrl).getState();
        if (state == WyvernConstants.STATE_DEAD) {
            return;

        } else if (state == WyvernConstants.STATE_HEAL &&
            getHealth() < getMaxHealth()) {
            if ( ! spendMana(0.2)) {
                _ctrl.setMemory("mana", 0);
                setState(WyvernConstants.STATE_ATTACK);
            }

        } else if (mana < 1) {
            _ctrl.setMemory("mana", Math.min(mana + 0.05, 1));
        }
    }

    override protected function handleMemory () :void
    {
        super.handleMemory();

        _manaBar.percent = getMana();
        _manaBar.visible = (getHealth() > 0);
    }

    /** Handy function to switch game states by changing avatar states. */
    protected function setState (state :String) :void
    {
        for (var key :String in PlayerCodes.LABEL_TO_STATE) {
            if (PlayerCodes.LABEL_TO_STATE[key] == state) {
                _ctrl.setState(key);
            }
        }
    }

    protected function handlePlayerEvents (event :ControlEvent) :void
    {
        if (_ctrl.hasControl() && event.name == "effect" && "event" in event.value) {
            switch (event.value.event) {
                case WyvernConstants.EVENT_COUNTER:
                    if (WyvernUtil.self(_ctrl).getState() == WyvernConstants.STATE_COUNTER &&
                        !spendMana(0.1)) {
                        setState(WyvernConstants.STATE_ATTACK);
                    }
                    break;
            }
        }
    }

    public function spendMana (cost :Number) :Boolean
    {
        var mana :Number = getMana();
        if (mana < cost) {
            return false;
        } else {
            _ctrl.setMemory("mana", mana - cost);
            return true;
        }
    }

    public function getMana () :Number
    {
        return _ctrl.getMemory("mana") as Number;
    }

    protected var _manaBar :ProgressBar = new ProgressBar(0x0000ff, 0x000000);
}

}
