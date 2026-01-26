package funkin.backend.scripting.events.character;

import haxe.xml.Access;

final class CharacterXMLEvent extends CancellableEvent {
	/**
	 * The character instance
	 */
	public var character:Character_CNE;

	/**
	 * The xml
	 */
	public var xml:Access;
}