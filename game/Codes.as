package {

import com.whirled.net.NetConstants;

public class Codes
{
    public static const CREDIT_STEP :int = 600;

    public static const CREDITS :String = NetConstants.makePersistent("credits");
    public static const CREDITS_LIFETIME :String = NetConstants.makePersistent("creditsLifetime");
    public static const AGE :String = NetConstants.makePersistent("age");
    public static const HAS_INSTALLED :String = NetConstants.makePersistent("hasInstalled");

    public static const HERO :String = NetConstants.makePersistent("hero");
    public static const KEEPER :String = NetConstants.makePersistent("keeper");
    public static const LEVELS :String = "levels";
    public static const COUNT :String = "count";

    public static const KLASS_NAME :Object = {
        thug: "Warrior",
        sneak: "Bandit",
        mage: "Arcanist",
        medic: "Cleric",
        mummy: "Mummy"
    };

    public static const HOURS :int = 60*60*1000;

    public static const TROPHIES :Object = {
        // stat: [ "trophy prefix",
        //    [ level, "name for broadcast" ]
        (HERO+WyvernConstants.PLAYER_KILLED_MONSTER+LEVELS): [ "pve",
            [ 5, "Boggart Hunter" ],
            [ 50, "Fox Hunter" ],
            [ 500, "Goblin Hunter" ],
            [ 2000, "Beast Hunter" ],
            [ 5000, "Golem Hunter" ],
            [ 15000, "Demon Hunter" ],
        ],
        (HERO+WyvernConstants.PLAYER_KILLED_PLAYER+LEVELS): [ "pvp",
            [ 5, "Gladiator" ],
            [ 50, "Draftee" ],
            [ 500, "Corporal" ],
            [ 2000, "Lieutenant" ],
            [ 5000, "Captain" ],
            [ 15000, "Legionnaire" ],
        ],
        (KEEPER+WyvernConstants.MONSTER_KILLED_PLAYER+COUNT): [ "bastard",
            [ 666, "Evilgasm" ],
        ],
        (CREDITS_LIFETIME+""): [ "builder",
            [ 50, "Dungeon Builder" ],
            [ 500, "Campaign Builder" ],
            [ 5000, "World Builder" ],
        ],
        (AGE+""): [ "age",
            [ 0.5*HOURS, "Thief of Time" ],
            [ 2*HOURS, "Wheel of Time" ],
            [ 6*HOURS, "Hero of Time" ],
        ]
    };
}

}
