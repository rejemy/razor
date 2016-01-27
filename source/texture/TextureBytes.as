package razor.texture
{

import flash.display.Bitmap;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.events.Event;
import flash.events.IOErrorEvent;

import flash.utils.ByteArray;

import omg.Console;

public class TextureBytes
{
	public var Bytes:ByteArray;
	public var Offset:uint;
	public var Length:uint;
	
	public function loadBitmap(onResult:Function, disposeAfter:Boolean=true):void
	{
		var bytes:ByteArray = Bytes;
		if(Offset != 0 || Length != bytes.length)
		{
			bytes = new ByteArray();
			var pos:uint = Bytes.position;
			Bytes.position = Offset;
			Bytes.readBytes(bytes, 0, Length);
			Bytes.position = pos;
		}
		
		var onImageLoaded:Function = function(e:Event):void
		{
			var loaderInfo:LoaderInfo = e.currentTarget as LoaderInfo;
			loaderInfo.removeEventListener(Event.COMPLETE, onImageLoaded);
			loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onImageLoadError);
			var bitmapSource:Bitmap = loaderInfo.content as Bitmap;
			
			onResult(bitmapSource.bitmapData);
			if(disposeAfter)
				bitmapSource.bitmapData.dispose();
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
		loader.loadBytes(bytes);
	}
	
	public static function bitmapDataFromBytes(bytes:ByteArray, onResult:Function):void
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
		loader.loadBytes(bytes);
	}
}

}