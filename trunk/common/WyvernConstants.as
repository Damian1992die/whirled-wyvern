package {

public class WyvernConstants
{
    public static const SERVICE_KEY :String = "quest:svc";
    public static const TOTEM_KEY :String = "quest:totem";
    public static const KILL_SIGNAL :String = "quest:kill";

    public static const PLAYER_KILLED_MONSTER :int = 0;
    public static const PLAYER_KILLED_PLAYER :int = 1;
    public static const MONSTER_KILLED_PLAYER :int = 2;

    public static const FACTION_PLAYER :String = "player";
    public static const FACTION_MONSTER :String = "monster";

    public static const STATE_ATTACK :String = "attack";
    public static const STATE_COUNTER :String = "counter";
    public static const STATE_HEAL :String = "heal";
    public static const STATE_DEAD :String = "dead";

    public static const TRAIT_BACKSTAB :int = 0;
    public static const TRAIT_PLUS_HEALING :int = 1;
    public static const TRAIT_PLUS_COUNTER :int = 2;
    public static const TRAIT_REGEN :int = 3;
    public static const TRAIT_BLOODTHIRST :int = 4;
    public static const TRAIT_ASSASSIN :int = 5;
    public static const TRAIT_BOOTY :int = 6;
    public static const TRAIT_DECAY :int = 7;
    public static const TRAIT_MUSIC :int = 8;
    public static const TRAIT_PARRY :int = 9;

    // "Events" piggybacked on effects messages
    // Eventually maybe WyvernSprite could listen for these and dispatch an AS3 Event, but for
    // now, just have listeners scoop the effects messages directly
    // TODO: Just make these actions
    // However: A distributed event system is still needed
    public static const EVENT_ATTACK :int = 0;
    public static const EVENT_COUNTER :int = 1;
    public static const EVENT_HEAL :int = 2;
    public static const EVENT_DIE :int = 3;
    public static const EVENT_REVIVE :int = 4;
    public static const EVENT_LEVELUP :int = 5;
    public static const EVENT_COUNTERING :int = 6;
}

}
