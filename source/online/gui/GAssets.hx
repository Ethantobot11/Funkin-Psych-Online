package online.gui;

class GAssets {
	public static function image(path:String) {
		var img = Paths.image(path, null, false);
		if (img == null)
			return null;

		Paths.excludeAsset('assets/images/' + path + ".png") ;
		Paths.excludeAsset('assets/images/' + path + ".astc") ;
		Paths.excludeAsset('assets/images/' + path + ".dds") ;
		return img.bitmap.clone();
	}
}