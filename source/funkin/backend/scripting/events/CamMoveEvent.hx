package funkin.backend.scripting.events;

import flixel.math.FlxPoint;

final class CamMoveEvent extends CancellableEvent {
	/**
	 * Final camera position.
	 */
	public var position:FlxPoint;

	/**
	 * Number of focused characters
	 */
	public var focusedCharacters:Int;
}