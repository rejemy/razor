package razor.texture
{

import flash.display.DisplayObject;	
import flash.display.BitmapData;
import flash.display.IBitmapDrawable;
import flash.geom.Matrix;
import flash.geom.ColorTransform;
import flash.geom.Rectangle;
import flash.text.TextFormat;

import omg.Console;

import razor.RazorUtils;

public class RazorTexture
{
	public var Page:RazorTexturePage;
	public var TriangleIndex:int;
	
	// Real pixel coordinates
	public var PixelX:int = 0;
	public var PixelY:int = 0;
	public var PixelWidth:int = 0;
	public var PixelHeight:int = 0;
	
	// Logical coordinates
	public var Width:uint = 0;
	public var Height:uint = 0;
	public var OffsetX:int = 0;
	public var OffsetY:int = 0;
	
	public var MinU:Number=0;
	public var MinV:Number=0;
	public var MaxU:Number=1;
	public var MaxV:Number=1;
	
	public var VertCoords:Vector.<Number>;
	
	public var SliceRect:Rectangle;
	public var SliceTextures:Vector.<RazorTexture>;
	
	// Note coords are all in source pixels
	public function RazorTexture(source:RazorTexturePage, x:int=0, y:int=0, width:int=0, height:int=0, offsetX:int=0, offsetY:int=0, sliceRect:Rectangle=null)
	{
		Page = source;

		SliceRect = sliceRect;
		
		//trace("Input dims: "+x+","+y+" "+width+","+height+" "+offsetX+","+offsetY);
		
		PixelX = Math.floor(x * source.PixelScalar);
		PixelY = Math.floor(y * source.PixelScalar);
		PixelWidth = Math.ceil((x+width) * source.PixelScalar) - PixelX;
		PixelHeight = Math.ceil((y+height) * source.PixelScalar) - PixelY;

		Width = PixelWidth / source.PixelScalar / source.SourcePixelDensity;
		Height = PixelHeight / source.PixelScalar / source.SourcePixelDensity;
		
		OffsetX = offsetX / source.SourcePixelDensity;
		OffsetY = offsetY / source.SourcePixelDensity;
		
		//trace("Adjusted dims: "+PixelX+","+PixelY+" "+PixelWidth+","+PixelHeight+" "+OffsetX+","+OffsetY);
		
		VertCoords = new Vector.<Number>(12);
		
		updateUVs();
		
		if(SliceRect)
		{
			SliceTextures = new Vector.<RazorTexture>(9, true);
			
			SliceTextures[0] = new RazorTexture(source, x,					y,					sliceRect.x,			sliceRect.y);
			SliceTextures[1] = new RazorTexture(source, x+sliceRect.x,		y,					sliceRect.width,		sliceRect.y);
			SliceTextures[2] = new RazorTexture(source, x+sliceRect.right,	y,					width-sliceRect.right,	sliceRect.y);
			
			SliceTextures[3] = new RazorTexture(source, x,					y+sliceRect.y,		sliceRect.x,			sliceRect.height);
			SliceTextures[4] = new RazorTexture(source, x+sliceRect.x,		y+sliceRect.y,		sliceRect.width,		sliceRect.height);
			SliceTextures[5] = new RazorTexture(source, x+sliceRect.right,	y+sliceRect.y,		width-sliceRect.right,	sliceRect.height);
			
			SliceTextures[6] = new RazorTexture(source, x,					y+sliceRect.bottom,	sliceRect.x,			height-sliceRect.bottom);
			SliceTextures[7] = new RazorTexture(source, x+sliceRect.x,		y+sliceRect.bottom,	sliceRect.width,		height-sliceRect.bottom);
			SliceTextures[8] = new RazorTexture(source, x+sliceRect.right,	y+sliceRect.bottom,	width-sliceRect.right,	height-sliceRect.bottom);
			var rectScalar:Number = 1.0 / source.SourcePixelDensity;
			
			//trace("Setting up slicerect with pixel scaler: "+rectScalar);
			SliceRect.x = Math.floor(SliceRect.x * rectScalar);
			SliceRect.y = Math.floor(SliceRect.y * rectScalar);

			SliceRect.width = Math.floor(SliceRect.width * rectScalar);
			SliceRect.height = Math.floor(SliceRect.height * rectScalar);
	
			//trace("Scaled slicerect: "+SliceRect);
		}
	}
	
	internal function updateUVs():void
	{
		MinU = PixelX / Page.PixelWidth;
		MinV = PixelY / Page.PixelHeight;
		MaxU = (PixelX+PixelWidth) / Page.PixelWidth;
		MaxV = (PixelY+PixelHeight) / Page.PixelHeight;
		
		VertCoords[0] = OffsetX; VertCoords[1] = OffsetY; VertCoords[2] = 0;
		VertCoords[3] = OffsetX+Width; VertCoords[4] = OffsetY; VertCoords[5] = 0;
		VertCoords[6] = OffsetX+Width; VertCoords[7] = OffsetY+Height; VertCoords[8] = 0;
		VertCoords[9] = OffsetX; VertCoords[10] = OffsetY+Height; VertCoords[11] = 0;
	}
	
	public static function fromAnything(source:Object, bounds:Rectangle, transparent:Boolean=true, pixelDensity:Number=1.0, offsetX:int=0, offsetY:int=0, quality:String=null):RazorTexture
	{
		if(source == null)
		{
			Console.error("Tried to make texture from null source");
			return null;
		}
		
		var page:RazorTexturePage = new RazorTexturePage(source, bounds, transparent, pixelDensity, null, RazorTexturePage.SCALE_ANY);
		
		if(!quality)
			quality = RazorUtils.DefaultRenderQuality;
		page.SourceQuality = quality;
		
		return page.add("texture", 0, 0, bounds.width, bounds.height, bounds.left + offsetX, bounds.top + offsetY);
	}
	

	public static function fromDisplayObject(obj:DisplayObject, bounds:Rectangle=null, padding:Number=0, quality:String=null):RazorTexture
	{
		if(obj == null)
		{
			Console.error("Tried to make texture from null display object");
			return null;
		}
		
		if(!bounds)
			bounds = obj.getBounds(obj);
		else
			bounds = bounds.clone();
		bounds.left -= padding;
		bounds.right += padding;
		bounds.top -= padding;
		bounds.bottom += padding;
		
		var texture:RazorTexture = RazorTexture.fromAnything(obj, bounds, true, 1.0, 0, 0, quality);
		texture.Page.setPremultiplied(true);
		return texture;
	}
	
	public static function fromText(text:String, textFormat:TextFormat):RazorTexture
	{
		var obj:DisplayObject = RazorUtils.textToDisplayObject(text, textFormat);
		return fromDisplayObject(obj);
	}
}

}