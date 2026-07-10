package mobile;

#if android
class KeyboardHelper {
	private static var keyboardShown:Bool = false;

	public static function isKeyboardClosed() {
        if (ScreenUtil.android.isScreenKeyboardShown())
			keyboardShown = true;
        
		if (ScreenUtil.android.isScreenKeyboardShown() == false && keyboardShown) {
            keyboardShown = false;
            return true;
        }

		return false;
	}
}
#end
