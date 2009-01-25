package {

import flash.utils.Dictionary;
import flash.utils.getTimer;

import com.threerings.util.Log;

import com.whirled.avrg.*;
import com.whirled.net.*;
import com.whirled.*;

public class Server extends ServerObject
{
    public static const log :Log = Log.getLog(Server);

    public function Server ()
    {
        _ctrl = new AVRServerGameControl(this);
        _ctrl.game.addEventListener(AVRGameControlEvent.PLAYER_JOINED_GAME, handlePlayerJoin);
        _ctrl.game.addEventListener(AVRGameControlEvent.PLAYER_QUIT_GAME, handlePlayerQuit);
        _ctrl.game.addEventListener(MessageReceivedEvent.MESSAGE_RECEIVED, handleMessage);
    }

    protected function getPlayer (playerId :int) :PlayerEntry
    {
        return _players[playerId] as PlayerEntry;
    }

    protected function getRoom (playerId :int) :RoomEntry
    {
        return _rooms[playerId] as RoomEntry;
    }

    public function handlePlayerJoin (event :AVRGameControlEvent) :void
    {
        var player :PlayerSubControlServer = _ctrl.getPlayer(event.value as int);

        player.props.addEventListener(PropertyChangedEvent.PROPERTY_CHANGED,
            function (event :PropertyChangedEvent) :void {
                handlePlayerChanged(player, event);
            });
        player.addEventListener(AVRGamePlayerEvent.ENTERED_ROOM, handleRoomEntry);
        player.addEventListener(AVRGamePlayerEvent.LEFT_ROOM, handleRoomExit);
    }

    public function handlePlayerQuit (event :AVRGameControlEvent) :void
    {
        var playerId :int = event.value as int;
        var player :PlayerEntry = getPlayer(playerId);

        var delta :int = getTimer() - player.joinedOn;
        _ctrl.loadOfflinePlayer(playerId,
            function (props :OfflinePlayerPropertyControl) :void {
                props.set(Codes.AGE, int(props.get(Codes.AGE)) + delta);
            },
            log.warning);

        delete _players[playerId];
        //var player :PlayerSubControlServer = _ctrl.getPlayer(event.value as int);
        //player.props.removeEventListener(PropertyChangedEvent.PROPERTY_CHANGED, handlePlayerChanged);
        //player.removeEventListener(AVRGamePlayerEvent.ENTERED_ROOM, handleRoomEntry);
        //player.removeEventListener(AVRGamePlayerEvent.LEFT_ROOM, handleRoomExit);
    }

    protected function handleRoomEntry (event :AVRGamePlayerEvent) :void
    {
        _ctrl.doBatch(function () :void {
            var playerId :int = event.playerId;
            var roomId :int = event.value as int;

            var player :PlayerEntry = getPlayer(playerId);
            if (player == null) {
                // The player is just logging in
                player = new PlayerEntry(roomId);
                player.joinedOn = getTimer();
                _players[playerId] = player;

                broadcast(getPlayerName(playerId) + " has logged into Wyvern.");

                for (var stat :String in Codes.TROPHIES) {
                    checkStat(_ctrl.getPlayer(playerId), stat);
                }
            }

            player.roomId = roomId;

            var room :RoomEntry = getRoom(roomId);
            if (room == null) {
                room = new RoomEntry();
                _rooms[roomId] = room;
                _ctrl.getRoom(roomId).addEventListener(AVRGameRoomEvent.SIGNAL_RECEIVED, handleSignal);
            }

            room.population = room.population + 1;
        });
    }

    protected function handleRoomExit (event :AVRGamePlayerEvent) :void
    {
        var playerId :int = event.playerId;
        var roomId :int = getPlayer(playerId).roomId;
        var room :RoomEntry = getRoom(roomId);

        room.population -= 1;
        if (room.population == 0) {
            _ctrl.getRoom(roomId).removeEventListener(AVRGameRoomEvent.SIGNAL_RECEIVED, handleSignal);
            delete _rooms[roomId];
        }
    }

    protected function handleSignal (event :AVRGameRoomEvent) :void
    {
        _ctrl.doBatch(function () :void {
            if (event.name == WyvernConstants.KILL_SIGNAL) {
                var data :Array = event.value as Array;
                var killerId :int = data[0];
                var victimId :int = data[1];
                var level :int = data[2];
                var mode :int = data[3];

                // TODO: Maybe not allow players to earn credit from killing their own monsters
                try {
                    // A hero should be awarded
                    if (mode == WyvernConstants.PLAYER_KILLED_MONSTER ||
                        mode == WyvernConstants.PLAYER_KILLED_PLAYER) {
                        var player :PlayerSubControlServer = _ctrl.getPlayer(killerId);
                        var heroStat :String = Codes.HERO+mode;

                        player.completeTask("hero_"+heroStat, level/120); // TODO: Tweak
                        player.props.set(heroStat+Codes.LEVELS, int(player.props.get(heroStat+Codes.LEVELS))+level);
                        player.props.set(heroStat+Codes.COUNT, int(player.props.get(heroStat+Codes.COUNT))+1);

                        //echo(player, "Well done, " + heroStat + " = " + player.props.get(heroStat));
                    }

                    // Award the dungeon keeper
                    if (mode == WyvernConstants.PLAYER_KILLED_MONSTER ||
                        mode == WyvernConstants.MONSTER_KILLED_PLAYER) {
                        var keeperId :int =
                            (mode == WyvernConstants.PLAYER_KILLED_MONSTER) ? victimId : killerId;
                        var keeperStat :String = Codes.KEEPER+mode;

                        _ctrl.loadOfflinePlayer(keeperId,
                            function (props :OfflinePlayerPropertyControl) :void {
                                props.set(Codes.CREDITS, int(props.get(Codes.CREDITS))+level);
                                props.set(keeperStat+Codes.LEVELS, int(props.get(keeperStat+Codes.LEVELS))+level);
                                props.set(keeperStat+Codes.COUNT, int(props.get(keeperStat+Codes.COUNT))+1);
                            },
                            function (... _) :void {
                                log.warning("Ruh oh, " + keeperId + " has built a dungeon without playing the game first.");
                            }
                        );
                    }

                    if (mode == WyvernConstants.PLAYER_KILLED_PLAYER) {
                        broadcast(getPlayerName(killerId) + " has slain " + getPlayerName(victimId) + "!");
                    }

                } catch (error :Error) {
                    // It's possible that they're hacking away while not in the AVRG
                    log.warning("Someone is playing outside the AVRG!");
                }
            }
        });
    }

    protected function handlePlayerChanged (
        player :PlayerSubControlServer, event :PropertyChangedEvent) :void
    {
        _ctrl.doBatch(checkStat, player, event.name);
    }

    protected function checkStat (player :PlayerSubControlServer, stat :String) :void
    {
        if (stat in Codes.TROPHIES) {
            var trophy :Array = Codes.TROPHIES[stat];
            var prefix :String = trophy[0];
            var value :int = player.props.get(stat) as int;

            for (var ii :int = 1; ii < trophy.length; ++ii) {
                if (value >= trophy[ii][0]) {
                    awardTrophy(player, prefix+(ii-1), trophy[ii][1]);
                }
            }
        }
    }

    protected function handleMessage (event :MessageReceivedEvent) :void
    {
        if ( ! event.isFromServer()) {
            var player :PlayerSubControlServer = _ctrl.getPlayer(event.senderId);
            _ctrl.doBatch(function () :void {
                _clientHooks[event.name].apply(this, [ player ].concat(event.value));
            });
        }
    }

    protected function getPlayerName (playerId :int) :String
    {
        return _ctrl.getRoom(getPlayer(playerId).roomId).getAvatarInfo(playerId).name;
    }

    /** Award a trophy, with optional broadcasting. */
    protected function awardTrophy (
        player :PlayerSubControlServer, ident :String, name :String = null) :void
    {
        if (player.awardTrophy(ident) && name != null) {
            broadcast(getPlayerName(player.getPlayerId()) + " just earned the " + name + " trophy!");
        }
    }

    protected function broadcast (text :String) :void
    {
        log.info("Broadcast: " + text);
        _ctrl.game.sendMessage("broadcast", text);
    }

    /** Functions on this object are called by client messages. */
    protected const _clientHooks :Object = {
        chosen: function (player :PlayerSubControlServer, klass :String) :void {
            player.awardPrize(klass);
            player.completeTask("chosen", 0.2); // Let them know we mean business
            player.props.set(Codes.HAS_INSTALLED, true);
            broadcast(getPlayerName(player.getPlayerId()) + " has begun a new life as a " +
                Codes.KLASS_NAME[klass] + ".");
        }
    };

    /** Maps player ID to scene ID. */
    protected var _players :Dictionary = new Dictionary();

    protected var _rooms :Dictionary = new Dictionary();

    /** Maps scene ID to occupant count. */
    protected var _roomToPopulation :Dictionary = new Dictionary();

    protected var _ctrl :AVRServerGameControl;
}

}
