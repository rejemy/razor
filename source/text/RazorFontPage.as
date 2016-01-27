package razor.text
{

import flash.geom.Rectangle;

import razor.texture.RazorTexturePage
import razor.texture.RazorTexture;

public dynamic class RazorFontPage extends RazorTexturePage
{
	public var Index:uint;
	
	
	public function RazorFontPage(index:uint, source:Object, bounds:Rectangle, pixelDensity:Number, scaleMode:uint = 2, preScaledBy:Number = 1.0)
	{
		super(source, bounds, true, pixelDensity, null, scaleMode, preScaledBy);
		Index = index;
	}
	
	public override function add(name:String, x:uint, y:uint, width:uint, height:uint, offsetX:int=0, offsetY:int=0, sliceRect:Rectangle=null):RazorTexture
	{
		var tex:RazorFontCharacter = new RazorFontCharacter(this, x, y, width, height, offsetX, offsetY);
		tex.TriangleIndex = NumTextures * 6;
		NumTextures += 1;
		if(NumTextures > Capacity)
			Capacity = NumTextures;
		this[name] = tex;
		return tex;
	}
}

}