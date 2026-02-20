package objects;

import objects.StrumNote;
import objects.Character;
import flixel.util.FlxSignal;

class StrumLine extends FlxTypedGroup<StrumNote> {
	/**
	 * Array containing all of the characters "attached" to those strums.
	 */
	public var characters:Array<Character>;
	/**
	 * Strum controlling by cpu or not.
	 */
	public var cpu:Bool;

	/**
	 * Targetted Note Data for this strumline.
	 */
	public var targetNoteData:Int;

	/**
	 * The note count this strumline.
	 */
	public var noteCount:Int;

	/**
	 * Signal that triggers whenever a note is being updated. Similar to onNoteUpdate, except strumline specific.
	 * To add a listener, do
	 * `strumLine.onNoteUpdate.add(function(e:NoteUpdateEvent) {});`
	 */
	public var onNoteUpdate:FlxTypedSignal<NoteUpdateEvent->Void> = new FlxTypedSignal<NoteUpdateEvent->Void>();

	public function new(?cpu:Bool, ?characters:Array<Character>, ?noteCount:Int, ?targetNoteData:Int) {
		super();
		this.cpu = cpu;
		this.noteCount = noteCount;
		this.characters = characters;
		this.targetNoteData = targetNoteData;
	}
}
