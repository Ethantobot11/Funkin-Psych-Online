package mobile.flixel.controls;

#if flixel
class Joystick extends InputHandler {
	public var controlIDs:Array<String> = [];

	private var maxRadius:Float = 50.0;

	public var touchZone:FlxSprite;

	private var currentTouchID:Int = -1;

	public function new(data:Dynamic) {
		super(data.position != null ? data.position[0] : 0, data.position != null ? data.position[1] : 0, data.showbounds == true);
		jsonName = data.name;
		controlIDs = cast data.id;
		var scale:Float = data.scale != null ? cast data.scale : 1.0;
		maxRadius = (data.radius != null ? data.radius : maxRadius) * scale;
		var subData = parseSubGraphic(data);
		loadElementGraphics(data.texture, subData.subTex, data.spritesheet, [Config.JOYSTICK_PATH, Config.MODDED_JOYSTICK_PATH], data.color, scale,
			subData.subColor);

		var relMidX = baseGraphic.width / 2;
		var relMidY = baseGraphic.height / 2;
		if (data.border != null && data.border.length >= 2) {
			var bW:Int = Std.int(data.border[0] * scale);
			var bH:Int = Std.int(data.border[1] * scale);
			touchZone = new FlxSprite(relMidX - bW / 2, relMidY - bH / 2).makeGraphic(bW, bH, 0xFFFFFFFF);
			touchZone.alpha = 0.15;
			touchZone.visible = (data.showborder == true);
			insert(0, touchZone);
		} else
			touchZone = baseGraphic;

		if (data.offset != null && data.hitbox != null) {
			for (i in 0...controlIDs.length)
				createBoundHitbox(relMidX + data.offset[i][0] - (data.hitbox[i][0] / 2), relMidY + data.offset[i][1] - (data.hitbox[i][1] / 2),
					data.hitbox[i][0], data.hitbox[i][1]);
		}
	}

	private function isPointerInZone(px:Float, py:Float):Bool {
		return touchZone == baseGraphic ? (px >= x && px <= x + baseGraphic.width && py >= y && py <= y
			+ baseGraphic.height) : (px >= x + touchZone.x
				&& px <= x + touchZone.x + touchZone.width
				&& py >= y + touchZone.y
				&& py <= y + touchZone.y + touchZone.height);
	}

	override public function updateInputs() {
		var isTouching = false;
		var touchX:Float = baseGraphic.getGraphicMidpoint().x;
		var touchY:Float = baseGraphic.getGraphicMidpoint().y;
		var cams = cameras != null && cameras.length > 0 ? cameras : [camera != null ? camera : FlxG.camera];
		var point = FlxPoint.get();
		var blockedByDeadZone = false;

		for (cam in cams) {
			#if FLX_TOUCH
			for (touch in FlxG.touches.list) {
				var tPos = touch.getWorldPosition(cam, point);
				for (dz in deadZones)
					if (dz != null && tPos.x >= dz.x && tPos.x <= dz.x + dz.width && tPos.y >= dz.y && tPos.y <= dz.y + dz.height) {
						blockedByDeadZone = true;
						break;
					}
				if (blockedByDeadZone)
					break;
			}
			if (currentTouchID == -1 && !blockedByDeadZone) {
				for (touch in FlxG.touches.list) {
					if (ignoredPointers.contains(touch.touchPointID))
						continue;
					var tPos = touch.getWorldPosition(cam, point);
					if (touch.justPressed && (isPointerInZone(tPos.x, tPos.y) || checkHitboxes(tPos, cam))) {
						currentTouchID = touch.touchPointID;
						break;
					}
				}
			}
			if (currentTouchID >= 0 && !blockedByDeadZone) {
				var found = false;
				for (touch in FlxG.touches.list)
					if (touch.touchPointID == currentTouchID) {
						if (touch.pressed) {
							isTouching = true;
							var tPos = touch.getWorldPosition(cam, point);
							touchX = tPos.x;
							touchY = tPos.y;
							found = true;
						}
						break;
					}
				if (!found)
					currentTouchID = -1;
			}
			#end

			#if FLX_MOUSE
			if (!blockedByDeadZone && FlxG.mouse.pressed) {
				var mPos = FlxG.mouse.getWorldPosition(cam, point);
				for (dz in deadZones)
					if (dz != null && mPos.x >= dz.x && mPos.x <= dz.x + dz.width && mPos.y >= dz.y && mPos.y <= dz.y + dz.height) {
						blockedByDeadZone = true;
						break;
					}
			}
			if (!blockedByDeadZone && !ignoredPointers.contains(-2)) {
				var mPos = FlxG.mouse.getWorldPosition(cam, point);
				if (currentTouchID == -1 && FlxG.mouse.justPressed && (isPointerInZone(mPos.x, mPos.y) || checkHitboxes(mPos, cam)))
					currentTouchID = -2;
				if (currentTouchID == -2) {
					if (FlxG.mouse.pressed) {
						isTouching = true;
						touchX = mPos.x;
						touchY = mPos.y;
					} else
						currentTouchID = -1;
				}
			}
			#end
			if (blockedByDeadZone) {
				isTouching = false;
				currentTouchID = -1;
				break;
			}
			if (isTouching || currentTouchID != -1)
				break;
		}
		point.put();

		if (isTouching) {
			var mid = baseGraphic.getGraphicMidpoint();
			var dx = touchX - mid.x;
			var dy = touchY - mid.y;
			var dist = Math.sqrt(dx * dx + dy * dy);
			if (dist > maxRadius) {
				dx = (dx / dist) * maxRadius;
				dy = (dy / dist) * maxRadius;
			}
			subGraphic.x = mid.x + dx - (subGraphic.width / 2) + subOffsetX;
			subGraphic.y = mid.y + dy - (subGraphic.height / 2) + subOffsetY;

			var anyPressed = false;
			for (i in 0...hitboxes.length) {
				var isPressed = checkOverlap(hitboxes[i]);
				if (isPressed) {
					activeIDs.push(controlIDs[i]);
					anyPressed = true;
				}
				updateBoundBrightness(hitboxes[i], isPressed);
			}
			applyBrightness(anyPressed);
		} else {
			centerSubGraphic();
			applyBrightness(false);
			for (box in hitboxes)
				updateBoundBrightness(box, false);
		}
	}

	override public function resetInputs() {
		super.resetInputs();
		currentTouchID = -1;
	}

	private function checkHitboxes(p:FlxPoint, cam:flixel.FlxCamera):Bool {
		for (b in hitboxes)
			if (b.overlapsPoint(p, true, cam))
				return true;
		return false;
	}
}
#end
