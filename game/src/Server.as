package {

import flash.utils.Dictionary;
import flash.utils.getTimer;

import com.threerings.util.Log;
import com.threerings.util.MethodQueue;

import aduros.net.BatchInvoker;
import aduros.net.REMOTE;
import aduros.net.RemoteCaller;
import aduros.net.RemoteProvider;
import aduros.util.F;

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

        new RemoteProvider(_ctrl.game, "s", F.konst(this));
        _gameReceiver = new RemoteCaller(_ctrl.game, "c");

        _invoker = new BatchInvoker(_ctrl);
        _invoker.start(500);
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
        var playerId :int = int(event.value);
        var player :PlayerEntry = getPlayer(playerId);

        var delta :int = getTimer() - player.joinedOn;
        _ctrl.loadOfflinePlayer(playerId,
            function (props :OfflinePlayerPropertyControl) :void {
                props.set(Codes.AGE, int(props.get(Codes.AGE)) + delta);
            },
            log.warning);

        delete _players[playerId];
    }

    protected function contains (setName :String, value :int) :Boolean
    {
        return value in _ctrl.props.get("@set:" + setName);
    }

    protected function handleRoomEntry (event :AVRGamePlayerEvent) :void
    {
        _ctrl.doBatch(function () :void {
            var playerId :int = event.playerId;
            var roomId :int = int(event.value);

            var player :PlayerEntry = getPlayer(playerId);
            if (player == null) {
                // The player is just logging in
                player = new PlayerEntry(roomId);
                player.joinedOn = getTimer();
                player.ctrl = _ctrl.getPlayer(playerId);
                player.playerReceiver = new RemoteCaller(player.ctrl, "player");

                _players[playerId] = player;

                if (contains("ban", playerId) && !Codes.isAdmin(playerId)) {
                    player.ctrl.deactivateGame();

                } else {
                    feed(getPlayerName(playerId) + " has logged into Wyvern.");

                    for (var stat :String in Codes.TROPHIES) {
                        checkStat(player.ctrl, stat);
                    }
                }
            }
            player.roomId = roomId;

            var room :RoomEntry = getRoom(roomId);
            if (room == null) {
                room = new RoomEntry();
                room.ctrl = _ctrl.getRoom(roomId);
                room.ctrl.addEventListener(AVRGameRoomEvent.SIGNAL_RECEIVED, handleSignal);
                _rooms[roomId] = room;
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
            room.ctrl.removeEventListener(AVRGameRoomEvent.SIGNAL_RECEIVED, handleSignal);
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
                var level :int = Math.min(data[2], 120); // Capped at 120
                var mode :int = data[3];
                var room :RoomSubControlServer = _ctrl.getRoom(event.roomId);

                // A hero should be awarded
                if (mode == WyvernConstants.PLAYER_KILLED_MONSTER ||
                    mode == WyvernConstants.PLAYER_KILLED_PLAYER) {

                    if (killerId in _players) {
                        var player :PlayerSubControlServer = _ctrl.getPlayer(killerId);

                        if (room.getAvatarInfo(killerId).isIdle) {
                            return; // AFK, ignore
                        }

                        if (!contains("avatar", player.props.get("avatarId") as int)) {
                            return; // Unapproved avatar, ignore
                        }

                        var heroStat :String = Codes.HERO+mode;
                        var entry :PlayerEntry = _players[killerId];
                        var now :int = flash.utils.getTimer();

                        if (now - entry.lastKill > level*1000/3) {
                            player.completeTask("kill", level/120); // TODO: Tweak
                            player.props.set(heroStat+Codes.LEVELS, int(player.props.get(heroStat+Codes.LEVELS))+level);
                            player.props.set(heroStat+Codes.COUNT, int(player.props.get(heroStat+Codes.COUNT))+1);

                            entry.lastKill = now;

                            if (mode == WyvernConstants.PLAYER_KILLED_MONSTER && int(Math.random()*1000) == 0) {
                                // It's your lucky day
                                player.awardPrize("broadcast_prize");
                            }

                            if (mode == WyvernConstants.PLAYER_KILLED_PLAYER) {
                                if (victimId in _players) {
                                    feed(getPlayerName(killerId) + " has slain " + getPlayerName(victimId) + "!");
                                } else {
                                    log.warning("A player died in PvP, but he wasn't in the AVRG");
                                }
                            }
                        } else {
                            // You just killed something way too fast. No credit for you!
                        }
                    } else {
                        log.warning("A player killed something, but he wasn't in the AVRG");
                    }
                }

                // Award the dungeon keeper
                if (killerId != victimId && (
                    mode == WyvernConstants.PLAYER_KILLED_MONSTER ||
                    mode == WyvernConstants.MONSTER_KILLED_PLAYER)) {

                    var keeperId :int =
                        (mode == WyvernConstants.PLAYER_KILLED_MONSTER) ? victimId : killerId;
                    var keeperStat :String = Codes.KEEPER+mode;

                    _ctrl.loadOfflinePlayer(keeperId,
                        function (props :OfflinePlayerPropertyControl) :void {
                            props.set(Codes.CREDITS, int(props.get(Codes.CREDITS))+level);
                            props.set(keeperStat+Codes.LEVELS, int(props.get(keeperStat+Codes.LEVELS))+level);
                            props.set(keeperStat+Codes.COUNT, int(props.get(keeperStat+Codes.COUNT))+1);
                        },
                        function (cause :String) :void {
                            log.warning("Couldn't award dungeon keeper", "cause", cause);
                        }
                    );
                }
            }
        });
    }

    protected function handlePlayerChanged (
        player :PlayerSubControlServer, event :PropertyChangedEvent) :void
    {
        _invoker.push(F.callback(checkStat, player, event.name));
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

    protected function getPlayerName (playerId :int) :String
    {
        return _ctrl.getPlayer(playerId).getPlayerName();
    }

    /** Award a trophy, with optional feed. */
    protected function awardTrophy (
        player :PlayerSubControlServer, ident :String, name :String = null) :void
    {
        if (player.awardTrophy(ident) && name != null) {
            feed(getPlayerName(player.getPlayerId()) + " just earned the " + name + " trophy!");
        }
    }

    protected function feed (text :String) :void
    {
        _gameReceiver.apply("feed", text);
    }

    REMOTE function chosen (playerId :int, klass :String) :void
    {
        var player :PlayerSubControlServer = _ctrl.getPlayer(playerId);

        _ctrl.doBatch(function () :void {
            player.awardPrize(klass);
            player.completeTask("chosen", 0.2); // Let them know we mean business
            player.props.set(Codes.HAS_INSTALLED, true);
            feed(getPlayerName(playerId) + " has begun a new life as a " +
                Codes.KLASS_NAME[klass] + ".");
//            player.awardPrize("bank");
        });
    }

    REMOTE function broadcast (playerId :int, message :Array) :void
    {
        _invoker.push(F.callback(_gameReceiver.apply, "broadcast", [ getPlayerName(playerId) ].concat(message)));
    }

    REMOTE function addToSet (playerId :int, setName :String, value :int) :void
    {
        Codes.requireAdmin(playerId);
        Codes.requireValidSet(setName);

        _ctrl.props.setIn("@set:"+setName, value, true, true);

        // Also kick
        if (setName == "ban" && !Codes.isAdmin(value)) {
            var player :PlayerEntry = getPlayer(value);
            if (player != null) {
                player.ctrl.deactivateGame();
            }
        }

        log.info("Added value to collection", "adminId", playerId, "setName", setName, "value", value);
        REMOTE::requestShowSet(playerId, setName);
    }

    REMOTE function removeFromSet (playerId :int, setName :String, value :int) :void
    {
        Codes.requireAdmin(playerId);
        Codes.requireValidSet(setName);

        _ctrl.props.setIn("@set:"+setName, value, null, true);

        log.info("Removed value from collection", "adminId", playerId, "setName", setName, "value", value);
        REMOTE::requestShowSet(playerId, setName);
    }

    REMOTE function requestShowSet (playerId :int, setName :String) :void
    {
        Codes.requireAdmin(playerId);
        Codes.requireValidSet(setName);

        var player :PlayerEntry = getPlayer(playerId);

        var set :Object = _ctrl.props.get("@set:"+setName);
        var result :Array = [];
        for (var entry :String in set) {
            result.push(entry);
        }

        player.playerReceiver.apply("respondShowSet", setName, result);
    }

    REMOTE function locatePeers (playerId :int) :void
    {
        var rooms :Array = []; // of loose Object
        for each (var room :RoomEntry in _rooms) {
            rooms.push({
                roomId: room.ctrl.getRoomId(),
                name: room.ctrl.getRoomName(),
                pop: room.population
            });
        }

        var top5 :Array = rooms.sortOn("pop", Array.NUMERIC | Array.DESCENDING).splice(0, 5);

        var result :Array = [];
        for each (var o :Object in top5) {
            result.push([ o.roomId, o.name, o.pop ]);
        }

        _invoker.push(F.callback(
            getPlayer(playerId).playerReceiver.apply, "respondLocatePeers", result));
    }

    /** Maps player ID to scene ID. */
    protected var _players :Dictionary = new Dictionary();

    protected var _rooms :Dictionary = new Dictionary();

    protected var _ctrl :AVRServerGameControl;

    /** For calling functions on the client. */
    protected var _gameReceiver :RemoteCaller;

    protected var _invoker :BatchInvoker;
}

}
