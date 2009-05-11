package {

import com.whirled.avrg.*;

import aduros.net.RemoteCaller;

public class PlayerEntry
{
    public var roomId :int;

    /** When the player entered this room. */
    public var joinedOn :int;

    /** When they last got a payout from a kill. */
    public var lastKill :int = 0;

    public var playerReceiver :RemoteCaller;

    public var ctrl :PlayerSubControlServer;

    public function PlayerEntry (roomId :int)
    {
        this.roomId = roomId;
    }
}

}
