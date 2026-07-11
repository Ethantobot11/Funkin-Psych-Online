package mobile;

typedef SubGraphicDef = {
	@:optional var texture:String;
	@:optional var position:Array<Float>;
	@:optional var scale:Float;
	@:optional var color:String;
}

typedef ControlDef = {
	var name:String;
	@:optional var id:Dynamic;
	@:optional var position:Array<Float>;
	@:optional var scale:Dynamic;
	@:optional var texture:String;
	@:optional var subgraphic:Dynamic;
	@:optional var spritesheet:String;
	@:optional var color:String;
	@:optional var showbounds:Bool;
	@:optional var offset:Array<Array<Float>>;
	@:optional var hitbox:Array<Array<Int>>;
	@:optional var radius:Float;
	@:optional var border:Array<Int>;
	@:optional var showborder:Bool;
}

typedef ControlsJsonDef = {
	@:optional var buttons:Array<ControlDef>;
	@:optional var dpads:Array<ControlDef>;
	@:optional var joysticks:Array<ControlDef>;
	@:optional var hitboxes:Array<ControlDef>;
}
