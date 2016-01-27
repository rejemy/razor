package razor
{

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.IBitmapDrawable;
import flash.display.StageQuality;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.display.StageQuality;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.net.URLRequest;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

import omg.Console;

import razor.texture.RazorTexture;
import razor.texture.RazorTexturePage;
import razor.texture.TextureBytes;

public final class RazorUtils
{
	public static var ScreenPixelDensity:Number = 1.0;
	
	public static var DefaultRenderQuality:String = StageQuality.HIGH;

	
	public static function anythingToTextureBitmap(source:Object, bounds:Rectangle, transparent:Boolean, scale:Number, onResult:Function, quality:String=null):void
	{
		if(source == null)
		{
			Console.error("Tried to make bitmap from null source");
			onResult(null);
			return;
		}
		
		if(!quality)
			quality = DefaultRenderQuality;
			
		var texWidth:uint = getNextPowerOfTwo(bounds.width * scale);
		var texHeight:uint = getNextPowerOfTwo(bounds.height * scale);
		
		if(source is Function)
		{
			var sourceFunc:Function = source as Function;
			source = sourceFunc();
		}
		
		if(source is Class)
		{
			var sourceClass:Class = source as Class;
			source = new sourceClass();
		}
		
		if(source is Bitmap)
		{
			source = (source as Bitmap).bitmapData;
		}
		
		if(source is BitmapData && scale == 1.0 && texWidth == bounds.width && texHeight == bounds.height)
		{
			onResult(source as BitmapData);
			return;
		}
		
		var tform:Matrix = new Matrix();
		tform.scale(scale, scale);
		tform.translate(-bounds.x* scale, -bounds.y* scale);
		
		var target:BitmapData = new BitmapData(texWidth, texHeight, transparent, 0x00000000);
		
		var scaleBitmap:Function = function(sourceData:IBitmapDrawable):void
		{
			if(sourceData == null)
			{
				target.dispose();
				onResult(null);
				return;
			}
			
			if(sourceData is Bitmap)
			{
				sourceData = (sourceData as Bitmap).bitmapData;
			}
			
			if(sourceData is BitmapData && scale == 1.0 && texWidth == bounds.width && texHeight == bounds.height)
			{
				trace("NOt resizing, it already matches exactly");
				target.dispose();
				onResult(sourceData as BitmapData);
				return;
			}
			
			target.drawWithQuality(sourceData, tform, null, null, null, true, quality);
			var data:BitmapData = sourceData as BitmapData;
			if(data)
			{
				data.dispose();
			}
			
			onResult(target);
		}
		
		if(source is IBitmapDrawable)
		{
			scaleBitmap(source as IBitmapDrawable);
		}
		else if(source is String)
		{
			loadBitmapFromURL(source as String, scaleBitmap);
		}
		else if(source is TextureBytes)
		{
			var byteSource:TextureBytes = source as TextureBytes;
			byteSource.loadBitmap(scaleBitmap);
		}
		else
		{
			Console.error("Texture with unknown source: "+source);
		}
	}
	
	public static function loadBitmapFromURL(url:String, onResult:Function):void
	{

		var onImageLoaded:Function = function(e:Event):void
		{
			var loaderInfo:LoaderInfo = e.currentTarget as LoaderInfo;
			loaderInfo.removeEventListener(Event.COMPLETE, onImageLoaded);
			loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onImageLoadError);
			var bitmapSource:Bitmap = loaderInfo.content as Bitmap;
			
			onResult(bitmapSource.bitmapData);
		}
		
		var onImageLoadError:Function = function(e:IOErrorEvent):void
		{
			Console.error("Error loading texture image: "+e);
			var loaderInfo:LoaderInfo = e.currentTarget as LoaderInfo;
			loaderInfo.removeEventListener(Event.COMPLETE, onImageLoaded);
			loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onImageLoadError);
			
			onResult(null);
		}
		
		var loader:Loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoaded);
		loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onImageLoadError);
		loader.load(new URLRequest(url));
	}
	

	
	public static function textToDisplayObject(text:String, textFormat:TextFormat):DisplayObject
	{
		var textField:TextField = new TextField();
		textField.defaultTextFormat = textFormat;
		textField.autoSize = TextFieldAutoSize.LEFT;
		textField.embedFonts = false;
		textField.multiline = false;
		textField.text = text;
		return textField;
	}
	
	public static function getNextPowerOfTwo(number:uint):uint
	{
		var result:uint = 1;
		while(result < number && result < 2048)
		{
			OMG::debug
			{
				if(result > 32 && (number - result <= 4))
				{
					Console.warning("Just missed a power of two: "+number);
				}
			}
			
			result *= 2;
		}

		return result;   
	}
	
	public static function evenDivisor(number:Number):Number
	{
		if(number <= 0)
			return 0;
		else if(number >= 1.0)
			return 1.0;
			
		var div:Number = 0.5;
		while(number <= div)
		{
			div *= 0.5;
		}
		return div *2;
	}
	
	public static function colorToVec(color:uint, vec:Vector.<Number>):void
	{
		vec[0] = Number(color >> 24 & 0xff) / 255.0;
		vec[1] = Number(color >> 16 & 0xff) / 255.0;
		vec[2] = Number(color >> 8 & 0xff) / 255.0;
		vec[3] = Number(color & 0xff) / 255.0;
	}
	
	public static function transformRect(tform:Matrix3D, rect:Rectangle):Rectangle
	{
		var bounds:Rectangle = new Rectangle();
		
		var tempVect:Vector3D = new Vector3D();
		var point:Vector3D;
		
		tempVect.x = rect.left;
		tempVect.y = rect.top;
		point = tform.transformVector(tempVect);
		bounds.left = point.x;
		bounds.right = point.x;
		bounds.top = point.y;
		bounds.bottom = point.y;
		
		tempVect.x = rect.right;
		tempVect.y = rect.top;
		point = tform.transformVector(tempVect);
		if(point.x < bounds.left)
			bounds.left = point.x;
		if(point.x > bounds.right)
			bounds.right = point.x;
		if(point.y < bounds.top)
			bounds.top = point.y;
		if(point.y > bounds.bottom)
			bounds.bottom = point.y;
			
		tempVect.x = rect.right;
		tempVect.y = rect.bottom;
		point = tform.transformVector(tempVect);
		if(point.x < bounds.left)
			bounds.left = point.x;
		if(point.x > bounds.right)
			bounds.right = point.x;
		if(point.y < bounds.top)
			bounds.top = point.y;
		if(point.y > bounds.bottom)
			bounds.bottom = point.y;
		
		tempVect.x = rect.left;
		tempVect.y = rect.bottom;
		point = tform.transformVector(tempVect);
		if(point.x < bounds.left)
			bounds.left = point.x;
		if(point.x > bounds.right)
			bounds.right = point.x;
		if(point.y < bounds.top)
			bounds.top = point.y;
		if(point.y > bounds.bottom)
			bounds.bottom = point.y;
		
		return bounds;
	}
	
}

}