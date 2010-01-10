package {

import flash.media.Sound;

/**
 * Instead of customizing via the .properties file, create your own klass .as file and fill out all
 * these methods. See the included examples for usage.
 */
public interface GuardKlass
{
    /** A list of sprites to use as the base layers of the paper doll. */
    function getBaseSprites () :Array;

    /** Fiddly. They have to be hidden when a helm is worn. */
    function getHairSprites () :Array;

    function getName () :String;

    function getTraits () :Array;

    function getMultiplier (itemType :int) :Number;

    function getStartingLevel () :int;
    function getStartingItems () :Array;

    function getSoundHeal () :Sound;
    function getSoundDeath () :Sound;
    function getSoundChatter () :Sound;

    function getWelcomeText () :String;

    function getChatterCharge () :Array;
    function getChatterVanquish () :Array;
    function getChatterDeath () :Array;
    function getChatterFlee () :Array;
    function getChatterAllClear () :Array;
    function getChatterIdle () :Array;
    function getChatterRevive () :Array;
}

}
