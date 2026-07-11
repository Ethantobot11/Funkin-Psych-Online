package mobile.flixel.controls;

#if flixel
class InputHandler extends FlxSpriteGroup {
	public var jsonName:String = null;
	public var activeIDs:Array<String> = [];
	public var lastActiveIDs:Array<String> = [];
	public var ignoredPointers:Array<Int> = [];
	public var disabled:Bool = false;
	public var disableBright:Bool = false;
	public var showBounds:Bool = false;
	public var subOffsetX:Float = 0;
	public var subOffsetY:Float = 0;
	public var subScale:Float = 1.0;
	public var deadZones:Array<FlxSprite> = [];
	public var baseGraphic:FlxSprite;
	public var subGraphic:FlxSprite;
	public var hitboxes:Array<FlxSprite> = [];
	public var baseColor:FlxColor = FlxColor.WHITE;
	public var subColor:FlxColor = FlxColor.WHITE;
	public var currentPointerID:Int = -1;
	public var onButtonDown:FlxTypedSignal<(InputHandler, String) -> Void> = new FlxTypedSignal<(InputHandler, String) -> Void>();
	public var onButtonUp:FlxTypedSignal<(InputHandler, String) -> Void> = new FlxTypedSignal<(InputHandler, String) -> Void>();

	public function new(x:Float, y:Float, showBounds:Bool = false) {
		super(x, y);
		this.showBounds = showBounds;
		baseGraphic = new FlxSprite(0, 0).makeGraphic(1, 1, 0x00000000);
		subGraphic = new FlxSprite(0, 0).makeGraphic(1, 1, 0x00000000);
		baseGraphic.antialiasing = subGraphic.antialiasing = true;
		add(baseGraphic);
		add(subGraphic);
		#if FLX_TOUCH
		for (touch in FlxG.touches.list)
			ignoredPointers.push(touch.touchPointID);
		#end
		#if FLX_MOUSE
		if (FlxG.mouse.pressed)
			ignoredPointers.push(-2);
		#end
	}

	public function parseSubGraphic(data:Dynamic):{subTex:String, subColor:String} {
		var res = {subTex: null, subColor: null};
		if (data.subgraphic != null) {
			if (Std.isOfType(data.subgraphic, String))
				res.subTex = cast data.subgraphic;
			else {
				res.subTex = data.subgraphic.texture;
				if (data.subgraphic.color != null)
					res.subColor = data.subgraphic.color;
				if (data.subgraphic.position != null) {
					subOffsetX = data.subgraphic.position[0];
					subOffsetY = data.subgraphic.position[1];
				}
				if (data.subgraphic.scale != null)
					subScale = data.subgraphic.scale;
			}
		}
		return res;
	}

	public function loadElementGraphics(gName:String, sName:String, sheet:String, paths:Array<String>, hex:String, scale:Float, ?sHex:String) {
		if (hex != null && hex != "" && !hex.startsWith("#"))
			hex = "#" + hex;
		if (sHex != null && sHex != "" && !sHex.startsWith("#"))
			sHex = "#" + sHex;

		var loadFrames = function(t:FlxSprite, g:String, s:String, p:Array<String>) {
			var png = FileSystem.exists(p[1] + s + ".png") ? p[1] + s + ".png" : p[0] + s + ".png";
			var xml = FileSystem.exists(p[1] + s + ".xml") ? p[1] + s + ".xml" : p[0] + s + ".xml";
			if (FileSystem.exists(png) && FileSystem.exists(xml)) {
				t.frames = FlxAtlasFrames.fromSparrow(FlxGraphic.fromBitmapData(FileSystem.getBitmapData(png)), File.getContent(xml));

				var lastChar = g.charAt(g.length - 1);
				var isNumber = (lastChar >= '0' && lastChar <= '9');

				if (isNumber)
					t.animation.addByPrefix("idle", g, 24, true);
				else
					t.animation.addByNames("idle", [g], 24, true);

				t.animation.play("idle");
				return true;
			}
			return false;
		};

		var bImg = FileSystem.exists(paths[1] + gName + ".png") ? paths[1] + gName + ".png" : paths[0] + gName + ".png";
		var sImg = FileSystem.exists(paths[1] + sName + ".png") ? paths[1] + sName + ".png" : paths[0] + sName + ".png";

		if (sheet != null && sheet != "") {
			if (!loadFrames(baseGraphic, gName, sheet, paths))
				baseGraphic.loadGraphic(FileSystem.getBitmapData(bImg));
		} else if (gName != null)
			baseGraphic.loadGraphic(FileSystem.getBitmapData(bImg));

		if (sName != null && sName != "") {
			if (sheet != null && sheet != "") {
				if (!loadFrames(subGraphic, sName, sheet, paths))
					subGraphic.loadGraphic(FileSystem.getBitmapData(sImg));
			} else
				subGraphic.loadGraphic(FileSystem.getBitmapData(sImg));
		} else
			subGraphic.visible = false;

		baseGraphic.scale.set(scale, scale);
		subGraphic.scale.set(scale * subScale, scale * subScale);
		baseGraphic.updateHitbox();
		subGraphic.updateHitbox();
		centerSubGraphic();

		baseColor = (hex != null && hex != "") ? FlxColor.fromString(hex) : FlxColor.WHITE;
		baseGraphic.color = baseColor;
		if (sHex != null && sHex != "")
			subColor = FlxColor.fromString(sHex);
		subGraphic.color = subColor;
	}

	public function centerSubGraphic() {
		if (subGraphic != null && baseGraphic != null && subGraphic.visible) {
			subGraphic.x = baseGraphic.x + (baseGraphic.width - subGraphic.width) / 2 + subOffsetX;
			subGraphic.y = baseGraphic.y + (baseGraphic.height - subGraphic.height) / 2 + subOffsetY;
		}
	}

	public function createBoundHitbox(relX:Float, relY:Float, w:Int, h:Int):FlxSprite {
		var box = new FlxSprite(relX, relY).makeGraphic(w, h, FlxColor.WHITE);
		box.visible = showBounds;
		box.alpha = 0.4;
		add(box);
		hitboxes.push(box);
		return box;
	}

	public function updateBoundBrightness(box:FlxSprite, isPressed:Bool) {
		if (!showBounds)
			return;
		box.color = isPressed ? FlxColor.GREEN : FlxColor.WHITE;
		box.alpha = isPressed ? 0.8 : 0.4;
	}

	override public function update(elapsed:Float) {
		if (disabled)
			return;
		#if FLX_TOUCH
		var i = ignoredPointers.length;
		while (i-- > 0) {
			var id = ignoredPointers[i];
			if (id != -2) {
				var active = false;
				for (touch in FlxG.touches.list)
					if (touch.touchPointID == id) {
						active = true;
						break;
					}
				if (!active)
					ignoredPointers.remove(id);
			}
		}
		#end
		#if FLX_MOUSE
		if (!FlxG.mouse.pressed)
			ignoredPointers.remove(-2);
		#end

		lastActiveIDs = activeIDs.copy();
		activeIDs = [];
		updateInputs();

		for (id in activeIDs)
			if (!lastActiveIDs.contains(id) && onButtonDown != null)
				onButtonDown.dispatch(this, id);
		for (id in lastActiveIDs)
			if (!activeIDs.contains(id) && onButtonUp != null)
				onButtonUp.dispatch(this, id);
		super.update(elapsed);
	}

	public dynamic function updateInputs() {}

	public function checkOverlap(rect:FlxSprite):Bool {
		var overlap = false;
		var cams = cameras != null && cameras.length > 0 ? cameras : [camera != null ? camera : FlxG.camera];
		var point = FlxPoint.get();

		for (cam in cams) {
			#if FLX_TOUCH
			for (touch in FlxG.touches.list) {
				if (ignoredPointers.contains(touch.touchPointID))
					continue;
				var worldPos = touch.getWorldPosition(cam, point);
				for (dz in deadZones)
					if (dz != null && worldPos.x >= dz.x && worldPos.x <= dz.x + dz.width && worldPos.y >= dz.y && worldPos.y <= dz.y + dz.height) {
						point.put();
						return false;
					}
				if (rect.overlapsPoint(worldPos, true, cam)) {
					overlap = true;
					currentPointerID = touch.touchPointID;
				}
			}
			#end
			#if FLX_MOUSE
			if (FlxG.mouse.pressed && !ignoredPointers.contains(-2)) {
				var worldPos = FlxG.mouse.getWorldPosition(cam, point);
				for (dz in deadZones)
					if (dz != null && worldPos.x >= dz.x && worldPos.x <= dz.x + dz.width && worldPos.y >= dz.y && worldPos.y <= dz.y + dz.height) {
						point.put();
						return false;
					}
				if (rect.overlapsPoint(worldPos, true, cam)) {
					overlap = true;
					currentPointerID = -2;
				}
			}
			#end
		}
		point.put();
		return overlap;
	}

	public function pressed(id:String):Bool
		return activeIDs.contains(id);

	public function justPressed(id:String):Bool
		return activeIDs.contains(id) && !lastActiveIDs.contains(id);

	public function justReleased(id:String):Bool
		return !activeIDs.contains(id) && lastActiveIDs.contains(id);

	public function released(id:String):Bool
		return !activeIDs.contains(id);

	public function resetInputs() {
		activeIDs = [];
		lastActiveIDs = [];
		currentPointerID = -1;
		centerSubGraphic();
		applyBrightness(false);
		for (box in hitboxes)
			if (box != null)
				updateBoundBrightness(box, false);
	}

	public function applyBrightness(isPressed:Bool) {
		if (disableBright)
			return;
		var mult:Float = isPressed ? 0.7 : 1.0;
		baseGraphic.color = FlxColor.fromRGBFloat(baseColor.redFloat * mult, baseColor.greenFloat * mult, baseColor.blueFloat * mult, baseColor.alphaFloat);
		if (subGraphic.visible)
			subGraphic.color = FlxColor.fromRGBFloat(subColor.redFloat * mult, subColor.greenFloat * mult, subColor.blueFloat * mult, subColor.alphaFloat);
	}
}
#end
