package {

import flash.media.Sound;

public class Mummy implements GuardKlass
{
    public function getBaseSprites () :Array
    {
        return [ 71 ];
    }

    public function getHairSprites () :Array
    {
        return [ ]; // Bald
    }

    public function getTraits () :Array
    {
        return [ ];
    }

    public function getName () :String
    {
        return "Mummy";
    }

    public function getStartingLevel () :int
    {
        return 20;
    }

    public function getStartingItems () :Array
    {
        return [ Items.findBySprite(338), Items.findBySprite(584), Items.findBySprite(607) ];
    }

    public function getWelcomeText () :String
    {
        return "I am reborn";
    }

    public function getMultiplier (itemType :int) :Number
    {
        switch (itemType) {
            case Items.MAGIC: case Items.SPEAR: return 1.5;
            case Items.SWORD: case Items.DAGGER: return 1.2;
            case Items.CLUB: case Items.AXE: return 0.8;
            case Items.ARCANE: return 1.5;
            case Items.HEAVY: return 0.8;
        }
        return 1;
    }

    public function getSoundHeal () :Sound
    {
        return _soundHeal;
    }

    public function getSoundDeath () :Sound
    {
        return _soundDie;
    }

    public function getSoundChatter () :Sound
    {
        return _soundDie;
    }

    public function getChatterCharge () :Array
    {
        return [
            "Can you embalm a {name}? Let's find out.",
            "What you call genocide, I call a days work.",
            "I will not fail.",
            "This will be brief.",
            "I am focused on the {name}.",
            "Defend yourself!"
        ];
    }

    public function getChatterVanquish () :Array
    {
        return [
            "Tell the Reaper I said hello.",
            "He won't be coming back.",
            "Ahh, the screams of the dying.",
            "Excellent, this {item} will come in handy.",
            "A {item}?? You sicken me."
        ];
    }

    public function getChatterDeath () :Array
    {
        return [ "Embalm me!", "I will be reborn." ];
    }

    public function getChatterFlee () :Array
    {
        return [
            "Death is near...",
            "This foe is overpowering!",
            "We must fall back to heal.",
        ];
    }

    public function getChatterAllClear () :Array
    {
        return [
            "And the unwavering silence of death.",
            "All our enemies have been vanquished.",
            "There is nothing left for us here.",
            "Only their graves remain."
        ];
    }

    public function getChatterIdle () :Array
    {
        return [
            "That orphanage had it coming.",
            "Everyone I know is long dead.",
            "Might I suggest we go some place... drier?",
            "I seek the Heart of Soruda... we will not find in this hovel.",
            "This place is a far cry from the underworld.",
            "Do you think I enjoy picnicking here with you?"
        ];
    }

    public function getChatterRevive () :Array
    {
        return [ "I am reborn!", "Death is not enough.", "It will take more than death." ];
    }

    [Embed(source="rsrc/mummy_heal.mp3")]
    protected static const SOUND_HEAL :Class;
    protected var _soundHeal :Sound = new SOUND_HEAL as Sound;

    [Embed(source="rsrc/mummy_die.mp3")]
    protected static const SOUND_DIE :Class;
    protected var _soundDie :Sound = new SOUND_DIE as Sound;
}

}
