package mobile.openfl.controls;

class Joystick extends InputHandler {
	public var controlIDs:Array<String> = [];

	private var maxRadius:Float = 50.0;

	public var touchZone:Sprite;

	private var currentTouchID:Int = -999;

	public function new(data:Dynamic) {
		super(data.position != null ? data.position[0] : 0, data.position != null ? data.position[1] : 0, data.showbounds == true);
		jsonName = data.name;
		controlIDs = cast data.id;
		var scale:Float = data.scale != null ? cast data.scale : 1.0;
		maxRadius = (data.radius != null ? data.radius : maxRadius) * scale;
		var subData = parseSubGraphic(data);
		loadElementGraphics(data.texture, subData.subTex, data.spritesheet, [Config.JOYSTICK_PATH, Config.MODDED_JOYSTICK_PATH], data.color, scale,
			subData.subColor);

		var bW = baseGraphic.scrollRect != null ? baseGraphic.scrollRect.width : baseGraphic.bitmapData.width;
		var bH = baseGraphic.scrollRect != null ? baseGraphic.scrollRect.height : baseGraphic.bitmapData.height;
		touchZone = new Sprite();
		if (data.border != null && data.border.length >= 2) {
			var zW = data.border[0] * scale, zH = data.border[1] * scale;
			touchZone.graphics.beginFill(0xFFFFFF, 0.15);
			touchZone.graphics.drawRect(0, 0, zW, zH);
			touchZone.graphics.endFill();
			touchZone.x = ((bW * baseScale) / 2) - (zW / 2);
			touchZone.y = ((bH * baseScale) / 2) - (zH / 2);
		} else {
			touchZone.graphics.beginFill(0xFFFFFF, 0.15);
			touchZone.graphics.drawRect(0, 0, bW * scale, bH * scale);
			touchZone.graphics.endFill();
		}
		if (data.showborder != true)
			touchZone.alpha = 0;
		addChildAt(touchZone, 0);

		if (data.offset != null && data.hitbox != null) {
			for (i in 0...controlIDs.length)
				createBoundHitbox(((bW * baseScale) / 2)
					+ (data.offset[i][0] * scale)
					- ((data.hitbox[i][0] * scale) / 2),
					((bH * baseScale) / 2)
					+ (data.offset[i][1] * scale)
					- ((data.hitbox[i][1] * scale) / 2), data.hitbox[i][0] * scale,
					data.hitbox[i][1] * scale);
		}
	}

	override public function updateInputs() {
		if (disabled)
			return;
		super.updateInputs();
		var bW = baseGraphic.scrollRect != null ? baseGraphic.scrollRect.width : baseGraphic.bitmapData.width;
		var bH = baseGraphic.scrollRect != null ? baseGraphic.scrollRect.height : baseGraphic.bitmapData.height;
		var globalMidX = this.x + (((bW * baseScale) / 2) * this.scaleX);
		var globalMidY = this.y + (((bH * baseScale) / 2) * this.scaleY);
		var isTouching = false,
			touchX = globalMidX,
			touchY = globalMidY,
			blockedByDeadZone = false;

		for (p in InputHandler.activePointers)
			if (p.isDown) {
				for (dz in deadZones)
					if (dz != null && dz.hitTestPoint(p.x, p.y, false)) {
						blockedByDeadZone = true;
						break;
					}
				if (blockedByDeadZone)
					break;
			}

		if (currentTouchID == -999 && !blockedByDeadZone)
			for (p in InputHandler.activePointers)
				if (p.isDown && touchZone.hitTestPoint(p.x, p.y, true)) {
					currentTouchID = p.id;
					break;
				}
		if (currentTouchID != -999 && !blockedByDeadZone) {
			var p = InputHandler.activePointers.get(currentTouchID);
			if (p != null && p.isDown) {
				isTouching = true;
				touchX = p.x;
				touchY = p.y;
			} else
				currentTouchID = -999;
		}
		if (blockedByDeadZone) {
			isTouching = false;
			currentTouchID = -999;
		}

		if (isTouching) {
			var dx = touchX - globalMidX,
				dy = touchY - globalMidY,
				dist = Math.sqrt(dx * dx + dy * dy),
				gRadius = maxRadius * this.scaleX;
			if (dist > gRadius) {
				dx = (dx / dist) * gRadius;
				dy = (dy / dist) * gRadius;
			}
			subGraphic.x = ((bW * baseScale) / 2)
				+ (dx / this.scaleX)
				- (((subGraphic.scrollRect != null ? subGraphic.scrollRect.width : subGraphic.bitmapData.width) * baseScale * subScale) / 2)
				+ subOffsetX;
			subGraphic.y = ((bH * baseScale) / 2)
				+ (dy / this.scaleY)
				- (((subGraphic.scrollRect != null ? subGraphic.scrollRect.height : subGraphic.bitmapData.height) * baseScale * subScale) / 2)
				+ subOffsetY;

			var anyPressed = false;
			for (i in 0...hitboxes.length) {
				var isPressed = hitboxes[i].hitTestPoint(touchX, touchY, true);
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
			for (b in hitboxes)
				updateBoundBrightness(b, false);
		}
	}

	override public function resetInputs() {
		super.resetInputs();
		currentTouchID = -999;
	}
}
