package {

import flash.media.Sound;

public class Jester implements GuardKlass
{
    public function getBaseSprites () :Array
    {
        return [ 67 ];
    }

    public function getHairSprites () :Array
    {
        return [ ]; // Bald
    }

    public function getTraits () :Array
    {
        return [ WyvernConstants.TRAIT_BACKSTAB ];
    }

    public function getName () :String
    {
        return "Jester";
    }

    public function getStartingLevel () :int
    {
        return 20;
    }

    public function getStartingItems () :Array
    {
        return [ Items.findBySprite(543), Items.findBySprite(117), Items.findBySprite(357) ];
    }

    public function getWelcomeText () :String
    {
        return "Live... and in person!";
    }

    public function getMultiplier (itemType :int) :Number
    {
        switch (itemType) {
            case Items.CLUB: case Items.BOW: return 1.5;
            case Items.AXE: case Items.DAGGER: return 1.2;
            case Items.SWORD: case Items.SPEAR: case Items.MAGIC: return 0.8;
            case Items.LIGHT: return 1.5;
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
        return _soundHeal;
    }

    public function getChatterCharge () :Array
    {
        return [
            "How many {name}s does it take to screw in a lightbulb?",
            "You would look great in red, let me help!",
            "Don't just stand there, what's wrong with you?",
            "Watch this...",
            "I'm going to jitter my body in that {name}'s general direction.",
            "Come back my lovely wad of XP!",
            "This is getting rather tedious... I mean, uh, Wyvern is awesome!",
            "pwning mobs brb"
        ];
    }

    public function getChatterVanquish () :Array
    {
        return [
            "Did you see the look on his face?",
            "Like taking candy from a baby.",
            "Sniped!",
            "Cracking jokes, cracking heads, life is good.",
            "You kill them, and treasure falls out... this is brilliant!",
            "Thanks for the {item}, chump!",
            "Ewww, a {item}? I'm just going to put this back.",
        ];
    }

    public function getChatterDeath () :Array
    {
        return [ "Oatmeal!", "Zimbabwe!", "Jinkies!", "Gazebo!", "I meant to do that." ];
    }

    public function getChatterFlee () :Array
    {
        return [
            "The armor, it does nothing!",
            "If laughter was the best medicine, I wouldn't be getting my ass kicked now would I?",
            "Not the face!",
            "My spleen!",
            "Medic! The hot nurse kind if possible.",
        ];
    }

    public function getChatterAllClear () :Array
    {
        return [
            "Do you hear that? Me neither.",
            "Who knew bopping critters was such thirsty work?",
            "Well, that's the last of them.",
            "Finally, it's over."
        ];
    }

    public function getChatterIdle () :Array
    {
        return [
            "That secret you've been guarding... isn't.",
            "Are we moving on yet? Hold on, let me get my mittens.",
            "Want to see my Aduros impression?",
            "Will you adopt this poor, lost " + getName() + "?",
            "Boss, wake me up when you're ready to go somewhere fun.",
            "This room needs more stuff to kill."
        ];
    }

    public function getChatterRevive () :Array
    {
        return [
            "It's the miracle of medicine!",
            "It's the miracle of life!",
            "It's the miracle of cloning!",
            "It's the miracle of Jebus!",
            "It's the miracle of caffeine!"
        ];
    }

    [Embed(source="rsrc/jester_heal.mp3")]
    protected static const SOUND_HEAL :Class;
    protected var _soundHeal :Sound = new SOUND_HEAL as Sound;

    [Embed(source="rsrc/jester_die.mp3")]
    protected static const SOUND_DIE :Class;
    protected var _soundDie :Sound = new SOUND_DIE as Sound;
}

}
