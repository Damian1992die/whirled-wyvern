package {

import flash.display.DisplayObject;

public class GraphicsUtil
{
    /** Walk up the scene graph until we get a node of the right type, or null. */
    public static function findParent (node :DisplayObject, parentClass :Class) :DisplayObject
    {
        try {
            while (node != null) {
                if (node is parentClass) {
                    return node;
                }
                node = node.parent;
            }
        } catch (error :SecurityError) { }

        return null;
    }
}

}
