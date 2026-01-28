package backend;

class Converters {
	// --- CNE CONVERTERS ---
	/* Still in alpha
	public static function parseCodenameChar(xmlData:Dynamic, isPlayer:Bool) {
		var playerOffsets = (getAttribute(rawContent, "isPlayer") == 'true');
		if(playerOffsets == null) playerOffsets = false;
		var scale = getAttribute(rawContent, "scale");
		if(scale == null) scale =" 1";
		var holdTime = getAttribute(rawContent, "holdTime");
		if(holdTime == null) holdTime = "4";
		var camX = getAttribute(rawContent, "camx");
		if(camX == null) camX = "0";
		var camY = getAttribute(rawContent, "camy");
		if(camY == null) camY = "0";
		var icon = getAttribute(rawContent, "icon");
		if(icon == null) icon = "face";
		var gameOverChar = getAttribute(rawContent, "gameOverChar");
	
		var charJson = {
			"animations": [],
			"image": "characters/" + characterName, 
			"scale": Std.parseFloat(scale),
			"sing_duration": Std.parseFloat(holdTime),
			"healthicon": icon,
			"position": [0, 0],
			"camera_position": [Std.parseFloat(camX), Std.parseFloat(camY)],
			
			"flip_x": !isPlayer, 
			
			"no_antialiasing": false,
			"healthbar_colors": [161, 161, 161],
			"dead_character": gameOverChar
		};
	
		var animParts = rawContent.split("<anim");
		animParts.shift();
	
		for (part in animParts) {
			var endIdx = part.indexOf("/>");
			if (endIdx == -1) continue;
			var animData = part.substring(0, endIdx);
			
			var name = getAttribute(animData, "name");
			var animPrefix = getAttribute(animData, "anim");
			var xStr = getAttribute(animData, "x");
			var yStr = getAttribute(animData, "y");
			var fps = getAttribute(animData, "fps");
			var loop = getAttribute(animData, "loop");
	
			var xVal = (xStr != null ? Std.parseFloat(xStr) : 0);
			var yVal = (yStr != null ? Std.parseFloat(yStr) : 0);
			if (isPlayer) {
				xVal = Std.parseInt(xStr) * -1;
			}
	
			if (name != null && animPrefix != null) {
				//yVal = -yVal;
	
				charJson.animations.push({
					"anim": name,
					"name": animPrefix,
					"fps": (fps != null ? Std.parseInt(fps) : 24),
					"loop": (loop == "true"),
					"indices": [],
					"offsets": [xVal, yVal]
				});
			}
		}

		return Json.stringify(charJson, null, "\t");
	}
	*/

	// --- CONVERTION SETTINGS (`32, round, 5` is recommended) ---
	public static var sectionSnapping:Float = 32;
	public static var snappingMethod:String = "round"; 
	public static var sectionThreshold:Float = 5;
	// ----------------

	/**
	 * Converts CNE Chart and Meta Datas to PsychEngine JSON Format.
	 */
	public static function parseCodenameChart(chartData:Dynamic, metaData:Dynamic):Dynamic {
		var psychJson:Dynamic = {
			song: metaData.displayName,
			notes: [],
			events: [],
			bpm: metaData.bpm,
			needsVoices: true,
			speed: chartData.scrollSpeed,
			player1: "bf",
			player2: "pico",
			gfVersion: "gf",
			stage: "stage"
		};

		if (chartData.stage != null) psychJson.stage = chartData.stage;
		else if (metaData.stage != null) psychJson.stage = metaData.stage;

		var beatsPerMeasure:Float = (metaData.beatsPerMeasure != null) ? metaData.beatsPerMeasure : 4;
		var stepsPerBeat:Float = (metaData.stepsPerBeat != null) ? metaData.stepsPerBeat : 4;

		var curSpeed:Float = chartData.scrollSpeed;
		var mustHit:Bool = false;
		var queueBPMChange:Bool = false;
		var curBPM:Float = metaData.bpm;
		var songTime:Float = 0;
		var measureTimes:Array<Float> = [0];

		var altEvents:Array<Dynamic> = [];
		if (chartData.strumLines != null) {
			var lines:Array<Dynamic> = chartData.strumLines;
			for (i in 0...lines.length) {
				altEvents.push([{time: 0.0, anim: false, idle: false}]);
			}
		}

		// --- SECTION CREATION ---
		var addSections = function(tilTime:Float):Void {
			if (songTime + sectionThreshold >= tilTime) return;

			var crochet:Float = 60.0 / curBPM * 1000.0;
			var diff:Float = tilTime - measureTimes[measureTimes.length - 1];
			var beats:Float = diff / crochet;

			var targetBeats:Float = beats / (4 / sectionSnapping);
			var snappedBeats:Float = (snappingMethod == "round") ? Math.round(targetBeats) : Math.floor(targetBeats);
			beats = snappedBeats * (4 / sectionSnapping);

			var totalSections:Int = Math.ceil(beats / beatsPerMeasure);

			for (i in 0...totalSections) {
				var secBeats:Float = beatsPerMeasure;
				if (i == 0 && beats % beatsPerMeasure > 0) secBeats = beats % beatsPerMeasure;

				var notesArray:Array<Dynamic> = psychJson.notes;
				notesArray.push({
					sectionNotes: [],
					sectionBeats: secBeats,
					mustHitSection: mustHit,
					gfSection: false,
					bpm: curBPM,
					changeBPM: queueBPMChange,
					altAnim: false
				});
				queueBPMChange = false;
				songTime += secBeats * crochet;
				measureTimes.push(songTime);
			}
		};

		// --- EVENTS ---
		if (chartData.events != null) {
			var sortedEvents:Array<Dynamic> = chartData.events;
			sortedEvents.sort(function(ev1, ev2) return Math.floor(ev1.time - ev2.time));

			for (event in sortedEvents) {
				var eventName:String = event.name;
				switch (eventName) {
					case "Camera Movement":
						addSections(event.time);
						var strumId:Int = event.params[0];
						if (chartData.strumLines != null && chartData.strumLines.length > strumId) {
							var charPosName:String = chartData.strumLines[strumId].position;
							if (charPosName == null) {
								var sType:Int = chartData.strumLines[strumId].type;
								if (sType == 0) charPosName = "dad";
								else if (sType == 1) charPosName = "boyfriend";
								else if (sType == 2) charPosName = "girlfriend";
								else charPosName = "dad";
							}
							mustHit = (charPosName == "boyfriend");
						}
					case "BPM Change":
						addSections(event.time);
						curBPM = event.params[0];
						queueBPMChange = true;
					case "Add Camera Zoom":
						var psychEvent = ["Add Camera Zoom", event.params[0] * (event.params[1] == "camGame" ? 1 : 0), event.params[0] * (event.params[1] == "camHUD" ? 1 : 0)];
						if (psychJson.events.length <= 0 || Math.abs(psychJson.events[psychJson.events.length - 1][0] - event.time) > 0.1)
							psychJson.events.push([event.time, [psychEvent]]);
						else
							psychJson.events[psychJson.events.length - 1][1].push(psychEvent);
					case "Scroll Speed Change":
						if (curSpeed != event.params[1]) {
							var psychEvent = ["Change Scroll Speed", event.params[1] / curSpeed, event.params[2] / (60 / curBPM * 1000.0) * stepsPerBeat];
							curSpeed = event.params[1];
							if (psychJson.events.length <= 0 || Math.abs(psychJson.events[psychJson.events.length - 1][0] - event.time) > 0.1)
								psychJson.events.push([event.time, [psychEvent]]);
							else
								psychJson.events[psychJson.events.length - 1][1].push(psychEvent);
						}
					case "Play Animation":
						var psychEvent = ["Play Animation", event.params[1], chartData.strumLines[event.params[0]].type];
						if (psychJson.events.length <= 0 || Math.abs(psychJson.events[psychJson.events.length - 1][0] - event.time) > 0.1)
							psychJson.events.push([event.time, [psychEvent]]);
						else
							psychJson.events[psychJson.events.length - 1][1].push(psychEvent);
					case "Alt Animation Toggle":
						var targetAltEvent:Array<Dynamic> = altEvents[event.params[2]];
						
						if (event.time == 0) {
							targetAltEvent[0].anim = event.params[0];
							targetAltEvent[0].idle = event.params[1];
						} else {
							targetAltEvent.push({
								time: event.time,
								anim: event.params[0],
								idle: event.params[1]
							});
							var lastState = targetAltEvent[targetAltEvent.length - 2];
							if (lastState != null && lastState.idle != event.params[1]) {
								var psychEvent = ["Alt Idle Animation", Std.string(chartData.strumLines[event.params[0]].type), (event.params[1]) ? "-alt" : ""];
								if (psychJson.events.length <= 0 || Math.abs(psychJson.events[psychJson.events.length - 1][0] - event.time) > 0.1)
									psychJson.events.push([event.time, [psychEvent]]);
								else
									psychJson.events[psychJson.events.length - 1][1].push(psychEvent);
							}
						}
					default:
						var val1 = "";
						var val2 = "";
						if (event.params != null) {
							var pArr:Array<Dynamic> = event.params;
							var mid = Math.ceil(pArr.length * 0.5);
							val1 = [for (i in 0...mid) Std.string(pArr[i])].join(", ");
							val2 = [for (i in mid...pArr.length) Std.string(pArr[i])].join(", ");
						}
						if (psychJson.events.length <= 0 || Math.abs(psychJson.events[psychJson.events.length - 1][0] - event.time) > 0.1)
							psychJson.events.push([event.time, [[event.name, val1, val2]]]);
						else
							psychJson.events[psychJson.events.length - 1][1].push([event.name, val1, val2]);
				}
			}
		}

		// Last section
		psychJson.notes.push({
			sectionNotes: [],
			sectionBeats: beatsPerMeasure,
			mustHitSection: mustHit,
			gfSection: false,
			bpm: curBPM,
			changeBPM: queueBPMChange,
			altAnim: false
		});

		if (chartData.strumLines != null) {
			var charDone = [false, false, false];
			var numberThing = 2;
			var strumLines:Array<Dynamic> = chartData.strumLines;

			for (s in 0...strumLines.length) {
				var strum = strumLines[s];

				if (strum.type <= 2) {
					if (charDone[strum.type]) continue;
					charDone[strum.type] = true;
				}

				if (strum.characters != null && strum.characters.length > 0) {
					switch (strum.type) {
						case 0: psychJson.player2 = strum.characters[0];
						case 1: psychJson.player1 = strum.characters[0];
						case 2: psychJson.gfVersion = strum.characters[0];
					}
				}

				var strumNotes:Array<Dynamic> = strum.notes;
				strumNotes.sort(function(a, b) return Math.floor(a.time - b.time));

				var measureIndex:Int = 0;
				var altIndex:Int = 0;
				curBPM = metaData.bpm;
				songTime = 0;
				measureTimes = [0];

				var thisAltEvents:Array<Dynamic> = altEvents[s];

				var noteTypesList:Array<Dynamic> = null;
				if (Reflect.hasField(chartData, "noteTypes")) noteTypesList = chartData.noteTypes;

				switch (strum.type) {
					case 0: //DAD
						for (note in strumNotes) {
							while (songTime <= note.time) {
								songTime += 60.0 / curBPM * 1000.0 * beatsPerMeasure;
								measureTimes.push(songTime);
							}
							while (measureIndex < measureTimes.length && measureTimes[measureIndex] <= note.time + sectionThreshold) measureIndex++;
							
							while (thisAltEvents.length > altIndex && thisAltEvents[altIndex].time <= note.time + sectionThreshold) altIndex++;

							var targetSecIdx:Int = measureIndex - 1;
							if (targetSecIdx < 0) targetSecIdx = 0;
							if (targetSecIdx >= Std.int(psychJson.notes.length)) targetSecIdx = Std.int(psychJson.notes.length - 1);
							
							var sec = psychJson.notes[targetSecIdx];

							var intFix = sec.mustHitSection ? 1 : 0;
							var psychNote:Array<Dynamic> = [note.time, (note.id % 4) + 4 * intFix, note.sLen];

							if (note.type != null && note.type > 0 && noteTypesList != null) 
								psychNote.push(noteTypesList[note.type]);

							if (altIndex > 0 && thisAltEvents[altIndex - 1].anim) {
								if(psychNote.length < 4) psychNote.push("Alt Animation");
								else psychNote[3] = "Alt Animation";
							}
							sec.sectionNotes.push(psychNote);
						}

					case 1: // BF
						for (note in strumNotes) {
							while (songTime <= note.time) {
								songTime += 60.0 / curBPM * 1000.0 * beatsPerMeasure;
								measureTimes.push(songTime);
							}
							while (measureIndex < measureTimes.length && measureTimes[measureIndex] <= note.time + sectionThreshold) measureIndex++;
							while (thisAltEvents.length > altIndex && thisAltEvents[altIndex].time <= note.time + sectionThreshold) altIndex++;

							var targetSecIdx:Int = measureIndex - 1;
							if (targetSecIdx < 0) targetSecIdx = 0;
							if (targetSecIdx >= Std.int(psychJson.notes.length)) targetSecIdx = Std.int(psychJson.notes.length - 1);
							var sec = psychJson.notes[targetSecIdx];

							var intFix = !sec.mustHitSection ? 1 : 0;
							var psychNote:Array<Dynamic> = [note.time, (note.id % 4) + 4 * intFix, note.sLen];

							if (note.type != null && note.type > 0 && noteTypesList != null) 
								psychNote.push(noteTypesList[note.type]);
							
							if (altIndex > 0 && thisAltEvents[altIndex - 1].anim) {
								if(psychNote.length < 4) psychNote.push("Alt Animation");
								else psychNote[3] = "Alt Animation";
							}
							sec.sectionNotes.push(psychNote);
						}

					case 2: // GF
						for (note in strumNotes) {
							while (songTime <= note.time) {
							   songTime += 60.0 / curBPM * 1000.0 * beatsPerMeasure;
							   measureTimes.push(songTime);
							}
							while (measureIndex < measureTimes.length && measureTimes[measureIndex] <= note.time + sectionThreshold) measureIndex++;
							while (thisAltEvents.length > altIndex && thisAltEvents[altIndex].time <= note.time + sectionThreshold) altIndex++;

							var targetSecIdx:Int = measureIndex - 1;
							if (targetSecIdx < 0) targetSecIdx = 0;
							if (targetSecIdx >= Std.int(psychJson.notes.length)) targetSecIdx = Std.int(psychJson.notes.length - 1);
							var sec = psychJson.notes[targetSecIdx];

							var intFix = sec.mustHitSection ? 1 : 0; 
							var psychNote:Array<Dynamic> = [note.time, (note.id % 4) + 4 * intFix, note.sLen];

							if (note.type == 0) psychNote.push("GF Sing");
							else if (note.type > 0 && noteTypesList != null) 
								psychNote.push("GF Sing: " + noteTypesList[note.type]);

							if (altIndex > 0 && thisAltEvents[altIndex - 1].anim) {
								if(psychNote.length < 4) psychNote.push("Alt Animation");
								else psychNote[3] = "Alt Animation";
							}
							sec.sectionNotes.push(psychNote);
						}

					default: // EXTRAS
						numberThing++; // Player 3, 4, 5...

						for (note in strumNotes) {
							while (songTime <= note.time) {
							   songTime += 60.0 / curBPM * 1000.0 * beatsPerMeasure;
							   measureTimes.push(songTime);
							}
							while (measureIndex < measureTimes.length && measureTimes[measureIndex] <= note.time + sectionThreshold) measureIndex++;
							while (thisAltEvents.length > altIndex && thisAltEvents[altIndex].time <= note.time + sectionThreshold) altIndex++;

							var targetSecIdx:Int = measureIndex - 1;
							if (targetSecIdx < 0) targetSecIdx = 0;
							if (targetSecIdx >= Std.int(psychJson.notes.length)) targetSecIdx = Std.int(psychJson.notes.length - 1);
							var sec = psychJson.notes[targetSecIdx];

							var intFix = sec.mustHitSection ? 1 : 0;
							var psychNote:Array<Dynamic> = [note.time, (note.id % 4) + 4 * intFix, note.sLen];

							if (note.type == 0) 
								psychNote.push("Player " + numberThing + " Sing");
							else if (note.type > 0 && noteTypesList != null)
								psychNote.push("Player " + numberThing + " Sing: " + noteTypesList[note.type]);

							if (altIndex > 0 && thisAltEvents[altIndex - 1].anim) {
								var animNote = "Player " + numberThing + " Anim: Alt Animation";
								if(psychNote.length < 4) psychNote.push(animNote);
								else psychNote[3] = animNote;
							}
							sec.sectionNotes.push(psychNote);
						}
				}
			}
		}

		var jsonOutput = {
			song: psychJson
		};

		return haxe.Json.stringify(jsonOutput, null, "\t");
	}
}
