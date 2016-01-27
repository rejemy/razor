package razor.text
{

import flash.utils.Dictionary;

import razor.texture.RazorTexture;
import razor.texture.RazorTexturePage;

public class RazorFontCharacter extends RazorTexture
{
	public var Advance:Number;
	public var Kernings:Dictionary;
	
	// Note coords are all in source pixels
	public function RazorFontCharacter(source:RazorTexturePage, x:int=0, y:int=0, width:int=0, height:int=0, offsetX:int=0, offsetY:int=0)
	{
		super(source, x, y, width, height, offsetX, offsetY);
	}
}

}