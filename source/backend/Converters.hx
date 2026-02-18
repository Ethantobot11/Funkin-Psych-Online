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
	public static var sectionSnapping:Int = 32;
	public static var snappingMethod:String = "round"; 
	public static var sectionThreshold:Float = 5;
	// ----------------

	/**
	 * Converts CNE Chart and Meta Datas to PsychEngine JSON Format.
	 */
	public static function parseCodenameChart(chartData:Dynamic, metaData:Dynamic):Dynamic
	{
		var curCamera:Dynamic = 0;
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
		if (metaData.displayName == null) psychJson.song = metaData.name;

		if (chartData.stage != null) psychJson.stage = chartData.stage;
		else if (metaData.stage != null) psychJson.stage = metaData.stage;

		var beatsPerMeasure:Dynamic = (metaData.beatsPerMeasure != null) ? metaData.beatsPerMeasure : 4;
		var stepsPerBeat:Dynamic = (metaData.stepsPerBeat != null) ? metaData.stepsPerBeat : 4;

		var curSpeed:Dynamic = chartData.scrollSpeed;
		var mustHit:Dynamic = false;
		var queueBPMChange:Dynamic = false;
		var curBPM:Dynamic = metaData.bpm;
		var songTime:Dynamic = 0;
		var measureTimes:Dynamic = [0];

		var altEvents:Dynamic = [];
		if (chartData.strumLines != null) {
			for (i in 0...chartData.strumLines.length) {
				altEvents.push([{time: 0, anim: false, idle: false}]);
			}
		}

		// --- SECTION CREATION ---
		var addSections:Dynamic = function(tilTime) {
			if (songTime + sectionThreshold >= tilTime) return;

			var crochet:Dynamic = 60.0 / curBPM * 1000.0;
			var diff:Dynamic = tilTime - measureTimes[measureTimes.length - 1];
			var beats:Dynamic = diff / crochet;

			var targetBeats:Dynamic = beats / (4 / sectionSnapping);
			var snappedBeats:Dynamic = (snappingMethod == "round") ? Math.round(targetBeats) : Math.floor(targetBeats);
			beats = snappedBeats * (4 / sectionSnapping);

			var totalSections:Dynamic = Math.ceil(beats / beatsPerMeasure);

			for (i in 0...totalSections) {
				var secBeats:Dynamic = beatsPerMeasure;
				if (i == 0 && beats % beatsPerMeasure > 0) secBeats = beats % beatsPerMeasure;

				psychJson.notes.push({
					sectionNotes: [],
					sectionBeats: secBeats,
					mustHitSection: mustHit,
					targetCamera: curCamera,
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
			var sortedEvents:Dynamic = chartData.events;
			sortedEvents.sort(function(ev1, ev2) return Math.floor(ev1.time - ev2.time));

			for (event in sortedEvents) {
				switch (event.name) {
					case "Camera Movement":
						addSections(event.time);
						var strumId:Dynamic = event.params[0];
						if (chartData.strumLines != null && chartData.strumLines.length > strumId) {
							var charPosName:Dynamic = chartData.strumLines[strumId].position;
							if (charPosName == null) {
								var sType:Dynamic = chartData.strumLines[strumId].type;
								if (sType == 0) charPosName = "dad";
								else if (sType == 1) charPosName = "boyfriend";
								else if (sType == 2) charPosName = "girlfriend";
								else charPosName = "dad";
							}
							mustHit = (charPosName == "boyfriend");
						}
						curCamera = strumId;
					case "BPM Change":
						addSections(event.time);
						curBPM = event.params[0];
						queueBPMChange = true;
					case "Add Camera Zoom":
						var psychEvent:Dynamic = ["Add Camera Zoom", event.params[0] * (event.params[1] == "camGame" ? 1 : 0), event.params[0] * (event.params[1] == "camHUD" ? 1 : 0)];
						if (psychJson.events.length <= 0 || Math.abs(psychJson.events[psychJson.events.length - 1][0] - event.time) > 0.1)
							psychJson.events.push([event.time, [psychEvent]]);
						else
							psychJson.events[psychJson.events.length - 1][1].push(psychEvent);
					case "Scroll Speed Change":
						if (curSpeed != event.params[1]) {
							var psychEvent:Dynamic = ["Change Scroll Speed", event.params[1] / curSpeed, event.params[2] / (60 / curBPM * 1000.0) * json.meta.stepsPerBeat];
							curSpeed = event.params[1];
							if (psychJson.events.length <= 0 || Math.abs(psychJson.events[psychJson.events.length - 1][0] - event.time) > 0.1)
								psychJson.events.push([event.time, [psychEvent]]);
							else
								psychJson.events[psychJson.events.length - 1][1].push(psychEvent);
						}
					case "Play Animation":
						var psychEvent:Dynamic = ["Play Animation", event.params[1], json.strumLines[event.params[0]].type];
						if (psychJson.events.length <= 0 || Math.abs(psychJson.events[psychJson.events.length - 1][0] - event.time) > 0.1)
							psychJson.events.push([event.time, [psychEvent]]);
						else
							psychJson.events[psychJson.events.length - 1][1].push(psychEvent);
					case "Alt Animation Toggle":
						if (event.time == 0) {
							altEvents[event.params[2]][0].anim = event.params[0];
							altEvents[event.params[2]][1].idle = event.params[1];
							continue;
						}
						altEvents[event.params[2]].push({
							time: event.time,
							anim: event.params[0],
							idle: event.params[1]
						});
						var lastState:Dynamic = altEvents[event.params[2]][altEvents[event.params[2]].length - 2];
						if (lastState != null && lastState.idle != event.params[1]) {
							var psychEvent:Dynamic = ["Alt Idle Animation", Std.string(json.strumLines[event.params[0]].type), (event.params[1]) ? "-alt" : ""];
							if (psychJson.events.length <= 0 || Math.abs(psychJson.events[psychJson.events.length - 1][0] - event.time) > 0.1)
								psychJson.events.push([event.time, [psychEvent]]);
							else
								psychJson.events[psychJson.events.length - 1][1].push(psychEvent);
						}
					default:
						var val1:Dynamic = "";
						var val2:Dynamic = "";
						if (event.params != null) {
							var mid:Dynamic = Math.ceil(event.params.length * 0.5);
							val1 = [for (i in 0...mid) Std.string(event.params[i])].join(", ");
							val2 = [for (i in mid...event.params.length) Std.string(event.params[i])].join(", ");
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
			targetCamera: curCamera,
			gfSection: false,
			bpm: curBPM,
			changeBPM: queueBPMChange,
			altAnim: false
		});

			if (chartData.strumLines != null) {
			var numberThing:Dynamic = 2; // Counter for extra players (starts at 2 so first extra becomes 3)

			for (s in 0...chartData.strumLines.length) {
				var strum:Dynamic = chartData.strumLines[s];

				// --- Character Name Assignment based on Index ---
				if (strum.characters != null && strum.characters.length > 0) {
					switch (s) {
						case 0: psychJson.player2 = strum.characters[0];   // Index 0 -> Dad (Player 2)
						case 1: psychJson.player1 = strum.characters[0];   // Index 1 -> BF (Player 1)
						case 2: psychJson.gfVersion = strum.characters[0]; // Index 2 -> GF
						// Extras (s > 2) names are not assigned to standard json fields
					}
				}

				var strumNotes:Dynamic = strum.notes;
				strumNotes.sort(function(a, b) return Math.floor(a.time - b.time));

				var measureIndex:Dynamic = 0;
				var altIndex:Dynamic = 0;
				curBPM = metaData.bpm;
				songTime = 0;
				measureTimes = [0];

				switch (s) {
					case 0: // DAD (Opponent)
						for (note in strumNotes) {
							while (songTime <= note.time) {
								songTime += 60.0 / curBPM * 1000.0 * beatsPerMeasure;
								measureTimes.push(songTime);
							}
							while (measureIndex < measureTimes.length && measureTimes[measureIndex] <= note.time + sectionThreshold) measureIndex++;
							while (altEvents[s].length > altIndex && altEvents[s][altIndex].time <= note.time + sectionThreshold) altIndex++;

							var targetSecIdx:Dynamic = measureIndex - 1;
							if (targetSecIdx < 0) targetSecIdx = 0;
							if (targetSecIdx >= psychJson.notes.length) targetSecIdx = psychJson.notes.length - 1;
							var sec:Dynamic = psychJson.notes[targetSecIdx];

							var intFix:Dynamic = sec.mustHitSection ? 1 : 0;
							var psychNote:Dynamic = [note.time, (note.id % 4) + 4 * intFix, note.sLen];

							if (note.type != null && note.type > 0 && chartData.noteTypes != null) 
								psychNote.push(chartData.noteTypes[note.type]);

							if (altIndex > 0 && altEvents[s][altIndex - 1].anim) {
								if(psychNote.length < 4) psychNote.push("Alt Animation");
								else psychNote[3] = "Alt Animation";
							}
							sec.sectionNotes.push(psychNote);
						}

					case 1: // BF (Player)
						for (note in strumNotes) {
							while (songTime <= note.time) {
								songTime += 60.0 / curBPM * 1000.0 * beatsPerMeasure;
								measureTimes.push(songTime);
							}
							while (measureIndex < measureTimes.length && measureTimes[measureIndex] <= note.time + sectionThreshold) measureIndex++;
							while (altEvents[s].length > altIndex && altEvents[s][altIndex].time <= note.time + sectionThreshold) altIndex++;

							var targetSecIdx:Dynamic = measureIndex - 1;
							if (targetSecIdx < 0) targetSecIdx = 0;
							if (targetSecIdx >= psychJson.notes.length) targetSecIdx = psychJson.notes.length - 1;
							var sec:Dynamic = psychJson.notes[targetSecIdx];

							var intFix:Dynamic = !sec.mustHitSection ? 1 : 0;
							var psychNote:Dynamic = [note.time, (note.id % 4) + (4 * intFix), note.sLen];

							if (note.type != null && note.type > 0 && chartData.noteTypes != null) 
								psychNote.push(chartData.noteTypes[note.type]);

							if (altIndex > 0 && altEvents[s][altIndex - 1].anim) {
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
							while (altEvents[s].length > altIndex && altEvents[s][altIndex].time <= note.time + sectionThreshold) altIndex++;

							var targetSecIdx:Dynamic = measureIndex - 1;
							if (targetSecIdx < 0) targetSecIdx = 0;
							if (targetSecIdx >= psychJson.notes.length) targetSecIdx = psychJson.notes.length - 1;
							var sec:Dynamic = psychJson.notes[targetSecIdx];

							// GF is usually mapped to 8-11 or handled separately, here we map to 8-11
							var psychNote:Dynamic = [note.time, (note.id % 4) + (4 * 2), note.sLen];

							if (note.type == 0) {
								// Added GF Sing for 0 type if desired, otherwise remove logic below to be pure ID
								psychNote.push("GF Sing");
							} else if (note.type > 0 && chartData.noteTypes != null) {
								psychNote.push("GF Sing: " + chartData.noteTypes[note.type]);
							}

							if (altIndex > 0 && altEvents[s][altIndex - 1].anim) {
								if(psychNote.length < 4) psychNote.push("Alt Animation");
								else psychNote[3] = "Alt Animation";
							}
							sec.sectionNotes.push(psychNote);
						}

					default: // EXTRAS (Player 3, 4, 5...)
						numberThing++; 

						for (note in strumNotes) {
							while (songTime <= note.time) {
							   songTime += 60.0 / curBPM * 1000.0 * beatsPerMeasure;
								measureTimes.push(songTime);
							}
							while (measureIndex < measureTimes.length && measureTimes[measureIndex] <= note.time + sectionThreshold) measureIndex++;
							while (altEvents[s].length > altIndex && altEvents[s][altIndex].time <= note.time + sectionThreshold) altIndex++;

							var targetSecIdx:Dynamic = measureIndex - 1;
							if (targetSecIdx < 0) targetSecIdx = 0;
							if (targetSecIdx >= psychJson.notes.length) targetSecIdx = psychJson.notes.length - 1;
							var sec:Dynamic = psychJson.notes[targetSecIdx];

							// Map to strums 12+, 16+, etc.
							var psychNote:Dynamic = [note.time, (note.id % 4) + (4 * numberThing), note.sLen];

							// Only add note types if strictly necessary (from chart data), no generic "Player X Sing" bc multiple strums exists
							if (note.type != null && note.type > 0 && chartData.noteTypes != null) 
								psychNote.push(chartData.noteTypes[note.type]);

							if (altIndex > 0 && altEvents[s][altIndex - 1].anim) {
								if(psychNote.length < 4) psychNote.push("Alt Animation");
								else psychNote[3] = "Alt Animation";
							}
							sec.sectionNotes.push(psychNote);
							}
				}
			}
		}

		var jsonOutput:Dynamic = {
			song: psychJson
		};

		return haxe.Json.stringify(jsonOutput, null, "\t");
	}
}
