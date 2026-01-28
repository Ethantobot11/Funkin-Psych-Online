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

		if (chartData.stage != null)
			psychJson.stage = chartData.stage;
		else if (metaData.stage != null)
			psychJson.stage = metaData.stage;

		var beatsPerMeasure:Float = (metaData.beatsPerMeasure != null) ? metaData.beatsPerMeasure : 4.0;
		var stepsPerBeat:Float = (metaData.stepsPerBeat != null) ? metaData.stepsPerBeat : 4.0;

		var curSpeed:Float = chartData.scrollSpeed;
		var mustHit:Bool = false;
		var queueBPMChange:Bool = false;
		var curBPM:Float = metaData.bpm;
		var songTime:Float = 0.0;
		var measureTimes:Array<Float> = [0.0];

		var altEvents:Array<Array<Dynamic>> = [];

		if (chartData.strumLines != null)
		{
			var strumLines:Array<Dynamic> = chartData.strumLines;
			for (i in 0...strumLines.length)
			{
				altEvents.push([{time: 0.0, anim: false, idle: false}]);
			}
		}

		// --- SECTION CREATION ---
		var addSections = function(tilTime:Float):Void
		{
			if (songTime + sectionThreshold >= tilTime)
				return;

			var crochet:Float = 60.0 / curBPM * 1000.0;
			var diff:Float = tilTime - measureTimes[measureTimes.length - 1];
			var beats:Float = diff / crochet;

			var targetBeats:Float = beats / (4.0 / sectionSnapping);
			var snappedBeats:Float = (snappingMethod == "round") ? Math.round(targetBeats) : Math.floor(targetBeats);
			beats = snappedBeats * (4.0 / sectionSnapping);

			var totalSections:Int = Math.ceil(beats / beatsPerMeasure);

			for (i in 0...totalSections)
			{
				var secBeats:Float = beatsPerMeasure;
				if (i == 0 && beats % beatsPerMeasure > 0)
					secBeats = beats % beatsPerMeasure;

				var notesArr:Array<Dynamic> = psychJson.notes;
				notesArr.push({
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
		if (chartData.events != null)
		{
			var sortedEvents:Array<Dynamic> = chartData.events;
			sortedEvents.sort(function(ev1, ev2) return Math.floor(ev1.time - ev2.time));

			for (event in sortedEvents)
			{
				switch (event.name)
				{
					case "Camera Movement":
						addSections(event.time);
						var strumId:Int = event.params[0];
						var strumLines:Array<Dynamic> = chartData.strumLines;

						if (strumLines != null && strumLines.length > strumId)
						{
							var charPosName:String = strumLines[strumId].position;
							if (charPosName == null)
							{
								var sType:Int = strumLines[strumId].type;
								if (sType == 0)
									charPosName = "dad";
								else if (sType == 1)
									charPosName = "boyfriend";
								else if (sType == 2)
									charPosName = "girlfriend";
								else
									charPosName = "dad";
							}
							mustHit = (charPosName == "boyfriend");
						}

					case "BPM Change":
						addSections(event.time);
						curBPM = event.params[0];
						queueBPMChange = true;

					case "Add Camera Zoom":
						var psychEvent:Array<Dynamic> = [
							"Add Camera Zoom",
							event.params[0] * (event.params[1] == "camGame" ? 1 : 0),
							event.params[0] * (event.params[1] == "camHUD" ? 1 : 0)
						];

						var eventsArr:Array<Dynamic> = psychJson.events;
						if (eventsArr.length <= 0 || Math.abs(eventsArr[eventsArr.length - 1][0] - event.time) > 0.1)
							eventsArr.push([event.time, [psychEvent]]);
						else
							eventsArr[eventsArr.length - 1][1].push(psychEvent);

					case "Scroll Speed Change":
						if (curSpeed != event.params[1])
						{
							var steps:Float = (metaData.stepsPerBeat != null) ? metaData.stepsPerBeat : 4.0;
							var psychEvent:Array<Dynamic> = [
								"Change Scroll Speed",
								event.params[1] / curSpeed,
								event.params[2] / (60 / curBPM * 1000.0) * steps
							];

							curSpeed = event.params[1];
							var eventsArr:Array<Dynamic> = psychJson.events;

							if (eventsArr.length <= 0 || Math.abs(eventsArr[eventsArr.length - 1][0] - event.time) > 0.1)
								eventsArr.push([event.time, [psychEvent]]);
							else
								eventsArr[eventsArr.length - 1][1].push(psychEvent);
						}

					case "Play Animation":
						var strumType:Int = chartData.strumLines[event.params[0]].type;
						var psychEvent:Array<Dynamic> = ["Play Animation", event.params[1], strumType];
						var eventsArr:Array<Dynamic> = psychJson.events;

						if (eventsArr.length <= 0 || Math.abs(eventsArr[eventsArr.length - 1][0] - event.time) > 0.1)
							eventsArr.push([event.time, [psychEvent]]);
						else
							eventsArr[eventsArr.length - 1][1].push(psychEvent);

					case "Alt Animation Toggle":
						if (event.time == 0)
						{
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

						if (lastState != null && lastState.idle != event.params[1])
						{
							var strumType:Int = chartData.strumLines[event.params[0]].type;
							var psychEvent:Array<Dynamic> = [
								"Alt Idle Animation",
								Std.string(strumType),
								(event.params[1]) ? "-alt" : ""
							];
							var eventsArr:Array<Dynamic> = psychJson.events;

							if (eventsArr.length <= 0 || Math.abs(eventsArr[eventsArr.length - 1][0] - event.time) > 0.1)
								eventsArr.push([event.time, [psychEvent]]);
							else
								eventsArr[eventsArr.length - 1][1].push(psychEvent);
						}

					default:
						var val1:String = "";
						var val2:String = "";
						if (event.params != null)
						{
							var params:Array<Dynamic> = event.params;
							var mid:Int = Math.ceil(params.length * 0.5);
							val1 = [for (i in 0...mid) Std.string(params[i])].join(", ");
							val2 = [for (i in mid...params.length) Std.string(params[i])].join(", ");
						}
						
						var eventsArr:Array<Dynamic> = psychJson.events;
						if (eventsArr.length <= 0 || Math.abs(eventsArr[eventsArr.length - 1][0] - event.time) > 0.1)
							eventsArr.push([event.time, [[event.name, val1, val2]]]);
						else
							eventsArr[eventsArr.length - 1][1].push([event.name, val1, val2]);
				}
			}
		}

		// Last section
		var notesArr:Array<Dynamic> = psychJson.notes;
		notesArr.push({
			sectionNotes: [],
			sectionBeats: beatsPerMeasure,
			mustHitSection: mustHit,
			gfSection: false,
			bpm: curBPM,
			changeBPM: queueBPMChange,
			altAnim: false
		});

		if (chartData.strumLines != null)
		{
			var charDone:Array<Bool> = [false, false, false];
			var numberThing:Int = 2;
			var strumLines:Array<Dynamic> = chartData.strumLines;

			for (s in 0...strumLines.length)
			{
				var strum:Dynamic = strumLines[s];

				if (strum.type <= 2)
				{
					if (charDone[strum.type])
						continue;
					charDone[strum.type] = true;
				}

				if (strum.characters != null && strum.characters.length > 0)
				{
					switch (strum.type)
					{
						case 0:
							psychJson.player2 = strum.characters[0];
						case 1:
							psychJson.player1 = strum.characters[0];
						case 2:
							psychJson.gfVersion = strum.characters[0];
					}
				}

				var strumNotes:Array<Dynamic> = strum.notes;
				strumNotes.sort(function(a, b) return Math.floor(a.time - b.time));

				var measureIndex:Int = 0;
				var altIndex:Int = 0;
				curBPM = metaData.bpm;
				songTime = 0.0;
				measureTimes = [0.0];

				switch (strum.type)
				{
					case 0: // DAD
						for (note in strumNotes)
						{
							while (songTime <= note.time)
							{
								songTime += 60.0 / curBPM * 1000.0 * beatsPerMeasure;
								measureTimes.push(songTime);
							}
							while (measureIndex < measureTimes.length
								&& measureTimes[measureIndex] <= note.time + sectionThreshold)
								measureIndex++;
							while (altEvents[s].length > altIndex
								&& altEvents[s][altIndex].time <= note.time + sectionThreshold)
								altIndex++;

							var targetSecIdx:Int = measureIndex - 1;
							if (targetSecIdx < 0)
								targetSecIdx = 0;
							if (targetSecIdx >= notesArr.length)
								targetSecIdx = notesArr.length - 1;

							var sec:Dynamic = notesArr[targetSecIdx];
							var intFix:Int = sec.mustHitSection ? 1 : 0;
							var psychNote:Array<Dynamic> = [note.time, (note.id % 4) + 4 * intFix, note.sLen];

							if (note.type != null && note.type > 0 && chartData.noteTypes != null)
								psychNote.push(chartData.noteTypes[note.type]);

							if (altIndex > 0 && altEvents[s][altIndex - 1].anim)
							{
								if (psychNote.length < 4)
									psychNote.push("Alt Animation");
								else
									psychNote[3] = "Alt Animation";
							}
							sec.sectionNotes.push(psychNote);
						}

					case 1: // BF
						for (note in strumNotes)
						{
							while (songTime <= note.time)
							{
								songTime += 60.0 / curBPM * 1000.0 * beatsPerMeasure;
								measureTimes.push(songTime);
							}
							while (measureIndex < measureTimes.length
								&& measureTimes[measureIndex] <= note.time + sectionThreshold)
								measureIndex++;
							while (altEvents[s].length > altIndex
								&& altEvents[s][altIndex].time <= note.time + sectionThreshold)
								altIndex++;

							var targetSecIdx:Int = measureIndex - 1;
							if (targetSecIdx < 0)
								targetSecIdx = 0;
							if (targetSecIdx >= notesArr.length)
								targetSecIdx = notesArr.length - 1;

							var sec:Dynamic = notesArr[targetSecIdx];
							var intFix:Int = !sec.mustHitSection ? 1 : 0;
							var psychNote:Array<Dynamic> = [note.time, (note.id % 4) + 4 * intFix, note.sLen];

							if (note.type != null && note.type > 0 && chartData.noteTypes != null)
								psychNote.push(chartData.noteTypes[note.type]);

							if (altIndex > 0 && altEvents[s][altIndex - 1].anim)
							{
								if (psychNote.length < 4)
									psychNote.push("Alt Animation");
								else
									psychNote[3] = "Alt Animation";
							}
							sec.sectionNotes.push(psychNote);
						}

					case 2: // GF
						for (note in strumNotes)
						{
							while (songTime <= note.time)
							{
								songTime += 60.0 / curBPM * 1000.0 * beatsPerMeasure;
								measureTimes.push(songTime);
							}
							while (measureIndex < measureTimes.length
								&& measureTimes[measureIndex] <= note.time + sectionThreshold)
								measureIndex++;
							while (altEvents[s].length > altIndex
								&& altEvents[s][altIndex].time <= note.time + sectionThreshold)
								altIndex++;

							var targetSecIdx:Int = measureIndex - 1;
							if (targetSecIdx < 0)
								targetSecIdx = 0;
							if (targetSecIdx >= notesArr.length)
								targetSecIdx = notesArr.length - 1;

							var sec:Dynamic = notesArr[targetSecIdx];
							var intFix:Int = sec.mustHitSection ? 1 : 0;
							var psychNote:Array<Dynamic> = [note.time, (note.id % 4) + 4 * intFix, note.sLen];

							if (note.type == 0)
								psychNote.push("GF Sing");
							else if (note.type > 0 && chartData.noteTypes != null)
								psychNote.push("GF Sing: " + chartData.noteTypes[note.type]);

							if (altIndex > 0 && altEvents[s][altIndex - 1].anim)
							{
								if (psychNote.length < 4)
									psychNote.push("Alt Animation");
								else
									psychNote[3] = "Alt Animation";
							}
							sec.sectionNotes.push(psychNote);
						}

					default: // EXTRAS (Player 3, 4, etc.)
						numberThing++;

						for (note in strumNotes)
						{
							while (songTime <= note.time)
							{
								songTime += 60.0 / curBPM * 1000.0 * beatsPerMeasure;
								measureTimes.push(songTime);
							}
							while (measureIndex < measureTimes.length
								&& measureTimes[measureIndex] <= note.time + sectionThreshold)
								measureIndex++;
							while (altEvents[s].length > altIndex
								&& altEvents[s][altIndex].time <= note.time + sectionThreshold)
								altIndex++;

							var targetSecIdx:Int = measureIndex - 1;
							if (targetSecIdx < 0)
								targetSecIdx = 0;
							if (targetSecIdx >= notesArr.length)
								targetSecIdx = notesArr.length - 1;

							var sec:Dynamic = notesArr[targetSecIdx];
							var intFix:Int = sec.mustHitSection ? 1 : 0;
							var psychNote:Array<Dynamic> = [note.time, (note.id % 4) + 4 * intFix, note.sLen];

							if (note.type == 0)
								psychNote.push("Player " + numberThing + " Sing");
							else if (note.type > 0 && chartData.noteTypes != null)
								psychNote.push("Player " + numberThing + " Sing: " + chartData.noteTypes[note.type]);

							if (altIndex > 0 && altEvents[s][altIndex - 1].anim)
							{
								var animNote:String = "Player " + numberThing + " Anim: Alt Animation";
								if (psychNote.length < 4)
									psychNote.push(animNote);
								else
									psychNote[3] = animNote;
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
