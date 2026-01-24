package options;

import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import backend.Controls;
import objects.Alphabet;
import shaders.ColorSwap;
import objects.Note;
import online.substates.SoFunkinSubstate;

using StringTools;

class NotesSubStateOld extends MusicBeatSubstate
{
	private static var curSelected:Int = 0;
	private static var typeSelected:Int = 0;
	private var grpNumbers:FlxTypedGroup<Alphabet>;
	private var grpNotes:FlxTypedGroup<FlxSprite>;
	private var shaderArray:Array<ColorSwap> = [];
	var curValue:Float = 0;
	var holdTime:Float = 0;
	var nextAccept:Int = 5;

	var blackBG:FlxSprite;
	var hsbText:Alphabet;
	var changeKeysText:Alphabet;

	var posX = 230;

	var camY:Float = 0;
	var targetCamY:Float = 0;

	public function new()
	{
		super();

		// Transparent background
		var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		bg.scrollFactor.set();
		bg.alpha = 0.5;
		add(bg);

		var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		add(grid);

		blackBG = new FlxSprite(posX - 25, 0).makeGraphic(850, 200, FlxColor.BLACK);
		blackBG.alpha = 0.4;
		add(blackBG);

		grpNotes = new FlxTypedGroup<FlxSprite>();
		add(grpNotes);
		grpNumbers = new FlxTypedGroup<Alphabet>();
		add(grpNumbers);

		hsbText = new Alphabet(posX + 260, 0, "Hue    Saturation  Brightness", false);
		hsbText.scaleX = 0.6;
		hsbText.scaleY = 0.6;
		add(hsbText);

		var buttonCTRL = #if TOUCH_CONTROLS controls.mobileControls ? 'E' : #end 'CTRL';
		var tipText:FlxText = new FlxText(10, 10, 0, 'Press ${buttonCTRL} to change Key Count', 16);
		tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tipText.scrollFactor.set();
		add(tipText);

		spawnNotes();

		mobileManager.addMobilePad('FULL', 'A_B_C_E');
		//mobileManager.addMobilePadCamera();
	}

	function spawnNotes() {
		grpNotes.clear();
		grpNumbers.clear();
		shaderArray = [];

		camY = 0;
		targetCamY = 0;

		if (ClientPrefs.data.arrowHSV.length < Note.maniaKeys) {
			for (i in ClientPrefs.data.arrowHSV.length...Note.maniaKeys) {
				ClientPrefs.data.arrowHSV.push([0, 0, 0]);
			}
		}

		for (i in 0...Note.maniaKeys) {
			var yPos:Float = (165 * i) + 35;
			
			for (j in 0...3) {
				var optionText:Alphabet = new Alphabet(posX + (225 * j) + 250, yPos + 60, Std.string(ClientPrefs.data.arrowHSV[i][j]), true);
				grpNumbers.add(optionText);
			}

			var note:FlxSprite = new FlxSprite(posX, yPos);
			note.frames = Paths.getSparrowAtlas('NOTE_assets');

			var animName:String = Note.colArray[i % Note.colArray.length] + '0';
			note.animation.addByPrefix('idle', animName);
			
			note.animation.play('idle');
			note.antialiasing = ClientPrefs.data.antialiasing;
			note.ID = i;
			grpNotes.add(note);

			var newShader:ColorSwap = new ColorSwap();
			note.shader = newShader.shader;
			
			if(ClientPrefs.data.arrowHSV[i] != null) {
				newShader.hue = ClientPrefs.data.arrowHSV[i][0] / 360;
				newShader.saturation = ClientPrefs.data.arrowHSV[i][1] / 100;
				newShader.brightness = ClientPrefs.data.arrowHSV[i][2] / 100;
			}
			shaderArray.push(newShader);
		}
		
		changeSelection();
	}

	var changingNote:Bool = false;
	override function update(elapsed:Float) {

		var lerpVal:Float = Math.max(0, Math.min(1, elapsed * 7.5));
		camY = FlxMath.lerp(camY, targetCamY, lerpVal);

		for (i in 0...grpNotes.length) {
			var note = grpNotes.members[i];
			note.y = (note.ID * 165) + 35 - camY;
		}

		for (i in 0...grpNumbers.length) {
			var text = grpNumbers.members[i];
			var rowIndex = Math.floor(i / 3); 
			text.y = (rowIndex * 165) + 35 + 60 - camY;
		}

		if (grpNotes.members[curSelected] != null) {
			var selectedNote = grpNotes.members[curSelected];
			hsbText.y = selectedNote.y - 70;
			blackBG.y = selectedNote.y - 20;
		}

		if (FlxG.keys.justPressed.CONTROL || mobileButtonJustPressed('E')) {
			openSubState(new online.substates.SoFunkinSubstate(Note.maniaKeysStringList, Note.maniaKeysStringList.indexOf(Note.maniaKeys + 'k'), (i) -> {
				Note.maniaKeys = Std.parseInt(Note.maniaKeysStringList[i].split('k')[0]);
				spawnNotes();
				return true;
			}));
		}

		if(changingNote) {
			if(holdTime < 0.5) {
				if(controls.UI_LEFT_P) {
					updateValue(-1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else if(controls.UI_RIGHT_P) {
					updateValue(1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else if(controls.RESET || mobileButtonJustPressed('C')) {
					resetValue(curSelected, typeSelected);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					holdTime = 0;
				} else if(controls.UI_LEFT || controls.UI_RIGHT) {
					holdTime += elapsed;
				}
			} else {
				var add:Float = 90;
				switch(typeSelected) {
					case 1 | 2: add = 50;
				}
				if(controls.UI_LEFT) {
					updateValue(elapsed * -add);
				} else if(controls.UI_RIGHT) {
					updateValue(elapsed * add);
				}
				if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					FlxG.sound.play(Paths.sound('scrollMenu'));
					holdTime = 0;
				}
			}
		} else {
			if (controls.UI_UP_P) {
				changeSelection(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_DOWN_P) {
				changeSelection(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_LEFT_P) {
				changeSelection(0, -1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_RIGHT_P) {
				changeSelection(0, 1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if(controls.RESET || mobileButtonJustPressed('C')) {
				for (i in 0...3) {
					resetValue(curSelected, i);
				}
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.BACK) {
				ClientPrefs.saveSettings();
				FlxG.sound.play(Paths.sound('cancelMenu'));
				close();
			}
		}

		if(controls.ACCEPT) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
			changingNote = !changingNote;
			var item:Alphabet = grpNumbers.members[(curSelected * 3) + typeSelected];
			if(changingNote) {
				item.alpha = 1;
			} else {
				item.alpha = 0.6;
			}
		}

		super.update(elapsed);
	}

	function changeSelection(change:Int = 0, changeType:Int = 0) {
		curSelected += change;
		typeSelected += changeType;

		if (curSelected < 0)
			curSelected = Note.maniaKeys - 1;
		if (curSelected >= Note.maniaKeys)
			curSelected = 0;

		if (typeSelected < 0)
			typeSelected = 2;
		if (typeSelected > 2)
			typeSelected = 0;

		if (Note.maniaKeys > 4) {
			var rawY:Float = (curSelected * 165) + 35;
			targetCamY = rawY - (FlxG.height / 2) + (165 / 2);
			if (targetCamY < 0) targetCamY = 0;
		} else {
			targetCamY = 0;
		}

		for (i in 0...grpNotes.length) {
			var item = grpNotes.members[i];
			item.alpha = 0.6;
			item.scale.set(0.75, 0.75);

			if (curSelected == i) {
				item.alpha = 1;
				item.scale.set(1, 1);
			}
		}

		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * 3) + typeSelected == i) {
				item.alpha = 1;
			}
		}
	}

	function resetValue(selected:Int, type:Int) {
		curValue = 0;
		ClientPrefs.data.arrowHSV[selected][type] = 0;
		switch(type) {
			case 0: shaderArray[selected].hue = 0;
			case 1: shaderArray[selected].saturation = 0;
			case 2: shaderArray[selected].brightness = 0;
		}

		var item = grpNumbers.members[(selected * 3) + type];
		item.text = '0';

		var add = (40 * (item.letters.length - 1)) / 2;
		for (letter in item.letters)
		{
			letter.offset.x += add;
		}
	}

	function updateValue(change:Float = 0) {
		curValue += change;
		var roundedValue:Int = Math.round(curValue);
		var max:Float = 180;
		switch(typeSelected) {
			case 1 | 2: max = 100;
		}

		if(roundedValue < -max) {
			curValue = -max;
		} else if(roundedValue > max) {
			curValue = max;
		}
		roundedValue = Math.round(curValue);
		ClientPrefs.data.arrowHSV[curSelected][typeSelected] = roundedValue;

		switch(typeSelected) {
			case 0: shaderArray[curSelected].hue = roundedValue / 360;
			case 1: shaderArray[curSelected].saturation = roundedValue / 100;
			case 2: shaderArray[curSelected].brightness = roundedValue / 100;
		}

		var item = grpNumbers.members[(curSelected * 3) + typeSelected];
		item.text = Std.string(roundedValue);

		var add = (40 * (item.letters.length - 1)) / 2;
		for (letter in item.letters)
		{
			letter.offset.x += add;
		}
	}

	public override function closeSubState() {
		super.closeSubState();
		MusicBeatSubstate.instance = this;
		mobileManager.removeMobilePad();
		mobileManager.addMobilePad('FULL', 'A_B_C_E');
		controls.isInSubstate = true;
	}
}
