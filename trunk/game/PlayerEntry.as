package {

public class PlayerEntry
{
    public var roomId :int;

    /** When the player entered this room. */
    public var joinedOn :int;

    /** When they last got a payout from a kill. */
    public var lastKill :int = 0;

    public function PlayerEntry (roomId :int)
    {
        this.roomId = roomId;
    }
}

}
