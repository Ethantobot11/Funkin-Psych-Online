package funkin.backend.scripting.events.character;

import haxe.xml.Access;

final class CharacterXMLEventMerged extends CancellableEvent {
	/**
	 * The character instance
	 */
	public var character:Character;

	/**
	 * The xml
	 */
	public var xml:Access;
}