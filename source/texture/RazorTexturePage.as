package razor.texture
{

import omg.AppBase;
import omg.Console;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.textures.Texture;
import flash.display.DisplayObjectContainer;
import flash.display.DisplayObject;
import flash.geom.Rectangle;
import flash.utils.Dictionary;

import razor.RazorUtils;
import razor.display.RazorStage;

public dynamic class RazorTexturePage
{
	public static const SCALE_ANY:uint = 0;
	public static const SCALE_EVEN:uint = 1;
	public static const SCALE_HALF:uint = 2;
	public static const SCALE_NONE:uint = 3;
	public static const SCALE_PRESCALED:uint = 4;
	
	public var TextureSource:Object;
	public var SourceBounds:Rectangle;
	public var SourceTransparent:Boolean;
	public var SourcePixelDensity:Number;
	public var SourceQuality:String = RazorUtils.DefaultRenderQuality;
	public var PixelScalar:Number;
	public var ScaleMode:uint;
	
	public var Capacity:int=0;
	
	public var BlendSource:String;
	
	public var PixelWidth:uint;
	public var PixelHeight:uint;
	
	public var Bindings:Vector.<RazorTextureBinding>;
	
	protected var NumTextures:uint=0;
	
	public function RazorTexturePage(source:Object, bounds:Rectangle, transparent:Boolean, pixelDensity:Number, subtextures:Object=null, scaleMode:uint = 0, preScaledBy:Number = 1.0)
	{
		if(source == null)
		{
			Console.error("Tried to make texture page from null source");
			return;
		}
		
		TextureSource = source;
		SourceBounds = bounds.clone();
		SourceTransparent = transparent;
		SourcePixelDensity = pixelDensity;
		
		BlendSource = Context3DBlendFactor.ONE;
		ScaleMode = scaleMode;
		
		if(scaleMode == SCALE_ANY)
		{
			PixelScalar = Math.min(RazorUtils.ScreenPixelDensity / SourcePixelDensity, 1.0);
		}
		else if(scaleMode == SCALE_EVEN)
		{
			PixelScalar = Math.min(RazorUtils.ScreenPixelDensity / SourcePixelDensity, 1.0);
			PixelScalar = RazorUtils.evenDivisor(PixelScalar);
		}
		else if(scaleMode == SCALE_HALF)
		{
			PixelScalar = Math.min(RazorUtils.ScreenPixelDensity / SourcePixelDensity, 1.0);
			if(PixelScalar <= 0.5)
				PixelScalar = 0.5;
			else
				PixelScalar = 1.0;
		}
		else if(scaleMode == SCALE_NONE)
		{
			PixelScalar = 1.0;
		}
		else if(scaleMode == SCALE_PRESCALED)
		{
			PixelScalar = preScaledBy;
		}
		
		
		PixelWidth = RazorUtils.getNextPowerOfTwo(SourceBounds.width * PixelScalar);
		PixelHeight = RazorUtils.getNextPowerOfTwo(SourceBounds.height * PixelScalar);
		
		
		Bindings = new Vector.<RazorTextureBinding>(1);
		
		if(subtextures)
		{
			addAll(subtextures);
		}
	}

	public function updateContents(onUpdated:Function=null):void
	{
		var onBitmapLoaded:Function = function(sourceBitmap:BitmapData):void
		{
			if(!sourceBitmap)
			{
				if(onUpdated != null)
					onUpdated(false);
				return;
			}
			
			for each(var binding:RazorTextureBinding in Bindings)
			{
				if(!binding)
					continue;
				
				binding.MyTexture.uploadFromBitmapData(sourceBitmap, 0);
			}
			
			if(sourceBitmap != TextureSource)
				sourceBitmap.dispose();
			
			if(onUpdated != null)
				onUpdated(true);
		}
		
		RazorUtils.anythingToTextureBitmap(TextureSource, SourceBounds, SourceTransparent, PixelScalar, onBitmapLoaded, SourceQuality);
	}
	
	public function updateContentsAndRebind(onUpdated:Function=null):void
	{
		var onBitmapLoaded:Function = function(sourceBitmap:BitmapData):void
		{
			if(!sourceBitmap)
			{
				if(onUpdated != null)
					onUpdated(false);
				return;
			}
			
			for each(var binding:RazorTextureBinding in Bindings)
			{
				if(!binding)
					continue;
				
				binding.MyTexture.uploadFromBitmapData(sourceBitmap, 0);
			}
			
			if(sourceBitmap != TextureSource)
				sourceBitmap.dispose();
			
			if(onUpdated != null)
				onUpdated(true);
		}
		
		var onLoaderComplete:Function = function(loadedTexture:Texture):void
		{
			if(!loadedTexture)
			{
				if(onUpdated != null)
					onUpdated(false);
				return;
			}
			
			binding.MyTexture = loadedTexture;
			if(onUpdated != null)
				onUpdated(true);
		}
		
		var tLoader:TextureLoader = TextureSource as TextureLoader;
		
		if(tLoader)
			tLoader.bind(fstage.Context, onLoaderComplete);
		else
			RazorUtils.anythingToTextureBitmap(TextureSource, SourceBounds, SourceTransparent, PixelScalar, onBitmapLoaded, SourceQuality);
		
		for(var currStageID:int=0; currStageID<Bindings.length; currStageID++)
		{
			var binding:RazorTextureBinding = Bindings[currStageID];
			if(!binding)
				continue;
		
			if(binding.Indexes)
				binding.Indexes.dispose();
			if(binding.Vertexes)
				binding.Vertexes.dispose();
			
			var fstage:RazorStage = RazorStage.Stages[currStageID];
			
			bindBuffers(binding, fstage);
		}
	}
	
	public function setPremultiplied(premultiplied:Boolean):void
	{
		if(premultiplied)
			BlendSource = Context3DBlendFactor.ONE;
		else
			BlendSource = Context3DBlendFactor.SOURCE_ALPHA;
	}
	
	public function bind(fstage:RazorStage, onBound:Function=null):RazorTextureBinding
	{
		var onBitmapLoaded:Function = function(sourceBitmap:BitmapData):void
		{
			if(!sourceBitmap)
			{
				if(onBound != null)
					onBound(false);
				return;
			}
			
			//var bitmapTest:Bitmap = new Bitmap(sourceBitmap);
			//AppBase.TheApp.addChild(bitmapTest);
			
			binding.MyTexture = fstage.Context.createTexture(PixelWidth, PixelHeight, Context3DTextureFormat.BGRA, false);
			binding.MyTexture.uploadFromBitmapData(sourceBitmap, 0);
			if(sourceBitmap != TextureSource)
				sourceBitmap.dispose();
			
			if(onBound != null)
				onBound(true);
			
			//trace("Completed texture bind "+TextureSource);
		}
		
		var onLoaderComplete:Function = function(loadedTexture:Texture):void
		{
			if(!loadedTexture)
			{
				if(onBound != null)
					onBound(false);
				return;
			}
			
			binding.MyTexture = loadedTexture;
			if(onBound != null)
				onBound(true);
		}
		
		var binding:RazorTextureBinding = Bindings[fstage.StageID];
		if(binding == null)
		{
			//trace("Starting texture bind "+TextureSource);
			
			binding = new RazorTextureBinding();
			
			bindBuffers(binding, fstage);
			
			Bindings[fstage.StageID] = binding;
			fstage.AllTextures[this] = true;
			
			var tLoader:TextureLoader = TextureSource as TextureLoader;
			if(tLoader)
				tLoader.bind(fstage.Context, onLoaderComplete);
			else
				RazorUtils.anythingToTextureBitmap(TextureSource, SourceBounds, SourceTransparent, PixelScalar, onBitmapLoaded, SourceQuality);
			
			//trace("Exiting texture bind "+TextureSource);
		}
		
		return binding;
	}
	
	private function bindBuffers(binding:RazorTextureBinding, fstage:RazorStage):void
	{
		
		if(Capacity == 0)
		{
			binding.Vertexes = null;
			binding.Indexes = null;
		}
		binding.Vertexes = fstage.Context.createVertexBuffer(Capacity*4, 4);
		binding.Indexes = fstage.Context.createIndexBuffer(Capacity*6);
		
		var vertData:Vector.<Number> = new Vector.<Number>(Capacity*4*4);
		var indexData:Vector.<uint> = new Vector.<uint>(Capacity*6);
		
		for each(var iter:Object in this)
		{
			var texture:RazorTexture = iter as RazorTexture;
			if(!texture)
				continue;
				
			var v:int = texture.TriangleIndex / 6 * 4;
			var i:int = v * 4;
			vertData[i++] = texture.OffsetX; vertData[i++] = texture.OffsetY;
			vertData[i++] = texture.MinU; vertData[i++] = texture.MinV;

			vertData[i++] = texture.OffsetX+texture.Width; vertData[i++] = texture.OffsetY;
			vertData[i++] = texture.MaxU; vertData[i++] = texture.MinV;

			vertData[i++] = texture.OffsetX+texture.Width; vertData[i++] = texture.OffsetY + texture.Height;
			vertData[i++] = texture.MaxU; vertData[i++] = texture.MaxV;

			vertData[i++] = texture.OffsetX; vertData[i++] = texture.OffsetY + texture.Height;
			vertData[i++] = texture.MinU; vertData[i++] = texture.MaxV;
			
			i = texture.TriangleIndex;
			indexData[i++] = v;
			indexData[i++] = v+1;
			indexData[i++] = v+2;
			indexData[i++] = v;
			indexData[i++] = v+2;
			indexData[i++] = v+3;
		}
		
		binding.Vertexes.uploadFromVector(vertData, 0, 4*Capacity);
		binding.Indexes.uploadFromVector(indexData, 0, 6*Capacity);
		
		//fstage.setSharedQuadIndexSize(Capacity);
	}
	
	public function dispose(stageID:int=-1, rebind:Boolean=false):void
	{
		var currStageID:int = 0;
		for each(var binding:RazorTextureBinding in Bindings)
		{
			if((stageID == -1 || stageID == currStageID) && binding)
			{
				binding.MyTexture.dispose();
				if(binding.Indexes)
					binding.Indexes.dispose();
				if(binding.Vertexes)
					binding.Vertexes.dispose();
				Bindings[currStageID] = null;
				if(!rebind)
					delete RazorStage.Stages[currStageID].AllTextures[this];
			}
			currStageID += 1;
		}
		
	}
	
	public function addAll(subtextures:Object):void
	{
		for(var subimage:String in subtextures)
		{
			var dims:Array = subtextures[subimage];
			add(subimage, dims[0], dims[1], dims[2], dims[3], dims[4], dims[5]);
		}
	}
	
	public function add(name:String, x:uint, y:uint, width:uint, height:uint, offsetX:int=0, offsetY:int=0, sliceRect:Rectangle=null):RazorTexture
	{
		//trace("Adding "+name+" at "+x+","+y+" "+width+"x"+height+" "+sliceRect);
		
		var tex:RazorTexture = new RazorTexture(this, x, y, width, height, offsetX, offsetY, sliceRect);
		
		tex.TriangleIndex = NumTextures * 6;
		NumTextures += 1;
		
		if(sliceRect)
		{
			for(var i:uint=0; i<tex.SliceTextures.length; i++)
			{
				var sliceTex:RazorTexture = tex.SliceTextures[i];
				sliceTex.TriangleIndex = NumTextures * 6;
				NumTextures += 1;
				this[name+"_slice"+i] = sliceTex;
			}
		}
		
		if(NumTextures > Capacity)
			Capacity = NumTextures;
		this[name] = tex;
		return tex;
	}
	
	public function get(name:String):RazorTexture
	{
		var tex:RazorTexture = this[name];
		if(!tex)
			Console.warning("Missing texture: "+name);
		return tex;
	}
	
	public static function fromDisplayObject(source:Object, transparent:Boolean=true, quality:String=null):RazorTexturePage
	{
		if(source == null)
		{
			Console.error("Tried to make texture page from null display object");
			return null;
		}
		
		var obj:DisplayObjectContainer = source as DisplayObjectContainer;
		if(!obj)
		{
			var sourceClass:Class = source as Class;
			if(sourceClass)
				obj = new sourceClass();
			else if(source is Function)
			{
				var srcFunc:Function = source as Function;
				obj = srcFunc();
			}
		}
		
		var bounds:Rectangle = obj.getBounds(obj);
		bounds.left = 0;
		bounds.top = 0;
		
		//trace("page bounds: "+bounds);

		var page:RazorTexturePage = new RazorTexturePage(source, bounds, transparent, 1.0);
		if(quality)
			page.SourceQuality = quality;
		
		var padding:int = 1;
		
		for(var i:int=0; i<obj.numChildren; i++)
		{
			var child:DisplayObject = obj.getChildAt(i);
			var childBounds:Rectangle = child.getBounds(obj);
			//trace("Child "+child.name+" bounds: "+childBounds + " pos: "+child.x+","+child.y);
			page.add(child.name, Math.floor(childBounds.left)-padding, Math.floor(childBounds.top)-padding,
			 				Math.ceil(childBounds.width)+padding*2, Math.ceil(childBounds.height)+padding*2,
			 				Math.floor(childBounds.left)-padding-child.x, Math.floor(childBounds.top)-padding-child.y);
		}
		
		return page;
	}
	
}

}