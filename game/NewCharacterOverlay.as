package {

import flash.display.*;
import flash.events.*;
import flash.text.*;

import com.threerings.flash.TextFieldUtil;
import com.threerings.util.Command;
import com.threerings.util.ValueEvent;

public class NewCharacterOverlay extends Sprite
{
    public static const EVENT_CHOSEN :String = "chosen";

    // Layout? We don't need no stinkin' layout
    public function NewCharacterOverlay ()
    {
        addChild(TextFieldUtil.createField("Choose your first character",
            { outlineColor: 0xffffff, selectable: false, autoSize: TextFieldAutoSize.LEFT },
            { size: 32 }));
//        addChild(TextFieldUtil.createField("Looks like this is your first time playing, what type of player do you wish to be known as?",
//            { y: 36, outlineColor: 0xffffff, selectable: false, autoSize: TextFieldAutoSize.LEFT },
//            { font: "times", size: 16, bold: true }));

        var choices :Array = [
            createButton(ICON_THUG, "thug",
                "<p>From skilled gladiators to honorable bodyguards. Across the lands, they are" +
                " unrivaled in the fine art of smashing face with a variety of techniques.</p>" +
                "Warrior receive: <ul>" +
                "<li>Great with swords, axes, clubs and spears.</li>" +
                "<li>Best with heavy armor.</li>" +
                "<li>Takes less damage while countering.</li>" +
                "</ul><p><i>\"Don't just stand there, crack some heads!\"</i></p>"),
            createButton(ICON_SNEAK, "sneak",
                "<p>Cunning thieves, assassins, pirates, spies and other rather unsavory types fall" +
                " into this class. While generally friendly, keep your wallet about you when a Bandit is nearby.</p>" +
                "Bandits receive: <ul>" +
                "<li>Great with daggers, bows and clubs.</li>" +
                "<li>More powerful critical hits when striking from behind.</li>" +
                "<li>Best with light armor.</li>" +
                "</ul><p><i>\"Oh, have you seen my wanted poster?\"</i></p>"),
            createButton(ICON_MAGE, "mage",
                "<p>Arcanists represent the epitome of human achievement in the field of magic." +
                " Whether through natural talent, intense study, or pacts with otherworldly powers...</p>" +
                "Arcanists receive: <ul>" +
                "<li>Great with magic, daggers and spears.</li>" +
                "<li>Best with arcane armor.</li>" +
                "<li>Splash damage when attacking with magic. (Coming soon).</li>" +
                "</ul><p><i>\"I am quite busy telling the laws of physics to shut up and sit down.\"</i></p>"),
            createButton(ICON_MEDIC, "medic",
                "<p><font color='#ff0000'>Coming soon. Not yet available.</font></p>" +
                "<p>A courageous fighter and born leader, the Cleric inspires those who follow him.</p>" +
                "<p><i>\"Once more into the breach, my friends!\"</i></p>",
                false),
            createButton(ICON_MUMMY, "mummy",
                "<p><font color='#ff0000'>Coming soon. Not yet available.</font></p>" +
                "<p>The Mummy laughs in the face of death every time it looks in the mirror.</p>" +
                "<p><i>\"What you call the occult, I call a day's work.\"</i></p>",
                false),
        ];

        for (var ii :int = 0; ii < choices.length; ++ii) {
            choices[ii].y = 50 + 70*ii;
            addChild(choices[ii]);
        }

        _description = TextFieldUtil.createField("",
            { textColor: 0xffffff, selectable: false, wordWrap: true,
                multiline: true, x: 220, y: 60, width: 400, height: 400 },
            { font: "times", size: 16, bold: true });
        addChild(_description);
    }

    protected function createButton (
        icon :Class, klass :String, desc :String, enabled :Boolean = true) :Button
    {
        var button :Button = new Button(new icon(), Codes.KLASS_NAME[klass]);

        Command.bind(button, MouseEvent.ROLL_OVER, setDescription, desc);
        Command.bind(button, MouseEvent.ROLL_OUT, setDescription, "");

        if (enabled) {
            Command.bind(button, MouseEvent.CLICK, dispatchEvent, new ValueEvent(EVENT_CHOSEN, klass));
            button.buttonMode = true;
        }

        return button;
    }

    protected function setDescription (text :String) :void
    {
        _description.htmlText = text;
    }

    [Embed(source="rsrc/icon_thug.png")]
    protected static const ICON_THUG :Class;
    [Embed(source="rsrc/icon_mage.png")]
    protected static const ICON_MAGE :Class;
    [Embed(source="rsrc/icon_sneak.png")]
    protected static const ICON_SNEAK :Class;
    [Embed(source="rsrc/icon_medic.png")]
    protected static const ICON_MEDIC :Class;
    [Embed(source="rsrc/icon_mummy.png")]
    protected static const ICON_MUMMY :Class;

//    [Embed(source="rsrc/wyvern.ttf", fontWeight="normal", fontName="wyvern", fontFamily="wyvern")]
//    protected static const FONT :Class;

    protected var _description :TextField;
}

}
