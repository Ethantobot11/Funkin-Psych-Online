package mobile;

class Config {
	public static var DPAD_PATH:String = "mobile/DPad/images/";
	public static var BUTTON_PATH:String = "mobile/Button/images/";
	public static var JOYSTICK_PATH:String = "mobile/JoyStick/images/";

	public static var DPAD_JSON:String = "mobile/DPad/";
	public static var BUTTON_JSON:String = "mobile/Button/";
	public static var JOYSTICK_JSON:String = "mobile/JoyStick/";
	public static var HITBOX_JSON:String = "mobile/Hitbox/";

	/* RECOMMEND TO CHANGING THESE FOR THE GAMES USING MODDING SYSTEM */
	public static var MODDED_DPAD_PATH(get, default):String = "";
	public static var MODDED_BUTTON_PATH(get, default):String = "";
	public static var MODDED_JOYSTICK_PATH(get, default):String = "";

	public static var MODDED_DPAD_JSON(get, default):String = "";
	public static var MODDED_BUTTON_JSON(get, default):String = "";
	public static var MODDED_JOYSTICK_JSON(get, default):String = "";
	public static var MODDED_HITBOX_JSON(get, default):String = "";

    private static function get_MODDED_DPAD_PATH() {
        return Paths.mods(Mods.currentModDirectory + "/mobile/DPad/images/");
    }

    private static function get_MODDED_BUTTON_PATH() {
        return Paths.mods(Mods.currentModDirectory + "/mobile/Button/images/");
    }

    private static function get_MODDED_JOYSTICK_PATH() {
        return Paths.mods(Mods.currentModDirectory + "/mobile/JoyStick/images/");
    }

    private static function get_MODDED_DPAD_JSON() {
        return Paths.mods(Mods.currentModDirectory + "/mobile/DPad/");
    }

    private static function get_MODDED_BUTTON_JSON() {
        return Paths.mods(Mods.currentModDirectory + "/mobile/Button/");
    }

    private static function get_MODDED_JOYSTICK_JSON() {
        return Paths.mods(Mods.currentModDirectory + "/mobile/JoyStick/");
    }

    private static function get_MODDED_HITBOX_JSON() {
        return Paths.mods(Mods.currentModDirectory + "/mobile/Hitbox/");
    }
}