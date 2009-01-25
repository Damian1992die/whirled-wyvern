package {

public class PlayerEntry
{
    public var roomId :int;

    /** When the player entered this room. */
    public var joinedOn :int;

    public function PlayerEntry (roomId :int)
    {
        this.roomId = roomId;
    }
}

}
