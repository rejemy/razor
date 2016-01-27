package razor
{

import flash.geom.Rectangle;
import flash.utils.ByteArray;
import flash.utils.Dictionary;
import flash.media.Sound;
import flash.display3D.Context3DTextureFormat;

import razor.display.RazorStage;
import razor.texture.RazorTexture;
import razor.texture.RazorTexturePage;
import razor.texture.TextureLoader;
import razor.texture.MemoryTextureLoader;
import razor.text.RazorFont;
import razor.data.RazorAnimData;
import razor.particles.RazorParticles;

import omg.OMGUtil;
import omg.Localize;
import omg.L;
import omg.Console;

OMG::air
{
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	import flash.desktop.NativeApplication;
	
	import razor.texture.FileTextureLoader;
}

public class RazorLibrary
{
	public static const FILETAG:String = "SWG";
	public static const VERSION:uint = 1;
	
	public static const TEXTURE_BGRA:uint = 1;
	public static const TEXTURE_COMPRESSED:uint = 2;
	public static const TEXTURE_COMPRESSED_ALPHA:uint = 3;
	
	public var Name:String;
	public var TexturePages:Dictionary;
	public var AnimData:Dictionary;
	public var Sounds:Dictionary;
	public var Fonts:Dictionary;
	public var Particles:Dictionary;
	public var Data:Dictionary;
	public var Strings:Dictionary;
	
	private var NumTotalTextures:int = 0;
	
	public static var LoadedLibaries:Dictionary = new Dictionary();
	
	
	public function RazorLibrary(name:String)
	{
		Name = name.toLowerCase();
		TexturePages = new Dictionary();
		AnimData = new Dictionary();
		Sounds = new Dictionary();
		Fonts = new Dictionary();
		Particles = new Dictionary();
		Data = new Dictionary();
		Strings = new Dictionary();
	}
 
	public static function loadAppLibrary(libname:String, filename:String, embeddedObject:Class):RazorLibrary
	{
		OMG::air
		{
			if(filename)
			{
				return loadSWGFile(libname, File.applicationDirectory.resolvePath(filename));
			}
		}
		
		if(!embeddedObject)
			throw new Error("No filename or embedded object given");
		
		return loadSWGBytes(libname, new embeddedObject());
	}

	OMG::air
	{
		public static function loadSWGFile(libname:String, swgfile:File):RazorLibrary
		{
			var bytes:ByteArray = new ByteArray();
			var swgStream:FileStream = new FileStream();
			swgStream.open(swgfile, FileMode.READ);
			swgStream.readBytes(bytes);
			swgStream.close();
			
			return loadSWGBytes(libname, bytes, swgfile)
		}
	}
	

	public static function loadSWGBytes(swgname:String, bytes:ByteArray, sourceFileObj:Object=null):RazorLibrary
	{
		
		
		if(LoadedLibaries[swgname])
			return LoadedLibaries[swgname];
			
		var lib:RazorLibrary = new RazorLibrary(swgname);
		LoadedLibaries[lib.Name] = lib;
		
		var tag:String = bytes.readUTFBytes(FILETAG.length);
		if(tag != FILETAG)
			throw new Error("Bytes not a SWG file");
		
		var version:uint = bytes.readUnsignedShort();
		if(version > VERSION)
			throw new Error("SWG is a version we can't read");
		
		
		loadTexturePages(lib, bytes, sourceFileObj);
		loadFonts(lib, bytes, sourceFileObj);
		
		var numSymbols:uint = bytes.readUnsignedShort();
		//trace("Reading "+numSymbols+" symbols");
		
		var symbolList:Vector.<RazorAnimData> = new Vector.<RazorAnimData>(numSymbols);
		var s:uint;
		for(s = 0; s< numSymbols; s++)
		{
			var symName:String = bytes.readUTF();
			//trace("Reading "+symName);
			var symData:RazorAnimData = new RazorAnimData();
			symData.SourceLib = lib;
			lib.AnimData[symName] = symData;
			symbolList[s] = symData;
		}
		
		for(s = 0; s< numSymbols; s++)
		{
			symbolList[s].readFrom(bytes);
		}
		
		var numSounds:uint = bytes.readUnsignedShort();
		for(s = 0; s< numSounds; s++)
		{
			var soundName:String = bytes.readUTF();
			var compressed:Boolean = bytes.readBoolean();
			var sound:Sound = new Sound();
			if(compressed)
			{
				var soundLen:uint = bytes.readUnsignedInt();
				//trace("Loading a sound of length "+soundLen);
				sound.loadCompressedDataFromByteArray(bytes, soundLen);
			}
			else
			{
				var numSamples:uint = bytes.readUnsignedInt();
				var stereo:Boolean = bytes.readBoolean();
				var sampleRate:Number = bytes.readFloat();
				sound.loadPCMFromByteArray(bytes, numSamples, "float", stereo, sampleRate);
			}
			//trace("Adding sound "+soundName);
			lib.Sounds[soundName] = sound;
		}
		
		var numParticles:uint = bytes.readUnsignedShort();
		
		for(var p:uint = 0; p<numParticles; p++)
		{
			var particlesID:String = bytes.readUTF();
			var particlesTextureID:String = bytes.readUTF();
			var particlesConfigSource:String = bytes.readUTF();
			var particlesConfig:Object = JSON.parse(particlesConfigSource);
			
			var particlesTextureRes:Array = lib.resolveResourceName(particlesTextureID);
			var particlesTexture:RazorTexture = RazorLibrary.getTexture(particlesTextureRes);
			
			var particles:RazorParticles = new RazorParticles(particlesTexture, particlesConfig);
			lib.Particles[particlesID] = particles;
			
		}
		
		var numDatas:uint = bytes.readUnsignedShort();
		for(var d:uint = 0; d<numDatas; d++)
		{
			var dataID:String = bytes.readUTF();
			var dataLen:uint = bytes.readUnsignedInt();
			
			var dataBytes:ByteArray = new ByteArray();
			bytes.readBytes(dataBytes, 0, dataLen);
			lib.Data[dataID] = dataBytes;
		}
		
		loadStrings(lib, bytes);
		
		return lib;
	}
	
	public static function translateTextureFormat(format:uint):String
	{
		switch(format)
		{
			case TEXTURE_BGRA:
				return Context3DTextureFormat.BGRA;
			case TEXTURE_COMPRESSED:
				return Context3DTextureFormat.COMPRESSED;
			case TEXTURE_COMPRESSED_ALPHA:
				return Context3DTextureFormat.COMPRESSED_ALPHA;
		}
		return null;
	}
	
	private static function loadTexturePages(lib:RazorLibrary, bytes:ByteArray, sourceFileObj:Object):void
	{
		OMG::air
		{
			var sourceFile:File = sourceFileObj as File;
		}
			
		var numTexturePages:uint = bytes.readUnsignedShort();
		lib.NumTotalTextures += numTexturePages;
		
		//trace("Loading "+numTexturePages+" texture pages")
		
		var tp:int;
		var pageName:String;
		
		for(tp=0; tp<numTexturePages; tp++)
		{
			pageName = bytes.readUTF();
			var textureFormat:String = translateTextureFormat(bytes.readUnsignedByte());
			var transparent:Boolean = bytes.readBoolean();
			var sourceDensity:Number = bytes.readFloat();
			var sourceWidth:uint = bytes.readUnsignedShort();
			var sourceHeight:uint = bytes.readUnsignedShort();
			var numDensities:uint = bytes.readUnsignedByte();
			
			var textureDensity:Number;
			var textureLoader:TextureLoader=null;
			var bounds:Rectangle = new Rectangle(0, 0, sourceWidth, sourceHeight);
			
			//trace("Loading "+numDensities+" densities");
			for(var d:uint=0; d<numDensities; d++)
			{
				var density:Number = bytes.readFloat();
				var width:uint = bytes.readUnsignedShort();
				var height:uint = bytes.readUnsignedShort();
				var byteLength:uint = bytes.readUnsignedInt();
				var nextPos:uint = bytes.position + byteLength;
				
				//trace("Checking "+density);
				
				if(!textureLoader && (density >= RazorUtils.ScreenPixelDensity || d == (numDensities-1)))
				{
					OMG::air
					{
						if(sourceFile)
						{
							textureLoader = new FileTextureLoader(sourceFile, bytes.position, byteLength, width, height, textureFormat);
						}
						else
						{
							var texBytes:ByteArray = new ByteArray();
							bytes.readBytes(texBytes, 0, byteLength);
							textureLoader = new MemoryTextureLoader(texBytes, 0, byteLength, width, height, textureFormat);
						}
					}
					OMG::flash
					{
						var texBytes:ByteArray = new ByteArray();
						bytes.readBytes(texBytes, 0, byteLength);
						textureLoader = new MemoryTextureLoader(texBytes, 0, byteLength, width, height, textureFormat);
					}
					
					textureDensity = density;
				}
				
				bytes.position = nextPos;
			}
			
			var page:RazorTexturePage = new RazorTexturePage(textureLoader, bounds, transparent, sourceDensity, null, RazorTexturePage.SCALE_PRESCALED, (textureDensity / sourceDensity));
			lib.TexturePages[pageName] = page;
			
			var numTextures:uint = bytes.readUnsignedShort();
			
			//trace("Adding texture page "+pageName+" with "+numTextures)
			
			for(var t:uint=0; t<numTextures; t++)
			{
				var textureName:String = bytes.readUTF();
				var tx:uint = bytes.readUnsignedShort();
				var ty:uint = bytes.readUnsignedShort();
				var twidth:uint = bytes.readUnsignedShort();
				var theight:uint = bytes.readUnsignedShort();
				var toffsetx:int = bytes.readShort();
				var toffsety:int = bytes.readShort();
				
				var sliceRect:Rectangle = null;
				if(bytes.readBoolean())
				{
					sliceRect = new Rectangle();
					sliceRect.left = bytes.readUnsignedShort();
					sliceRect.top = bytes.readUnsignedShort();
					sliceRect.right = bytes.readUnsignedShort();
					sliceRect.bottom = bytes.readUnsignedShort();
				}
				//trace("Adding texture "+textureName+","+tx+","+ty+","+twidth+","+theight+","+toffsetx+","+toffsety+","+sliceRect);
				page.add(textureName, tx, ty, twidth, theight, toffsetx, toffsety, sliceRect);
			}
			
		}
	}
	
	private static function loadFonts(lib:RazorLibrary, bytes:ByteArray, sourceFileObj:Object):void
	{
		var numFonts:uint = bytes.readUnsignedShort();
		lib.NumTotalTextures += numFonts;
		
		for(var f:uint = 0; f<numFonts; f++)
		{
			var font:RazorFont = RazorFont.fromBytes(bytes, sourceFileObj);
			lib.Fonts[font.RegistryName] = font;
			//trace("Added font "+font.RegistryName);
		}
		
		
	}
	
	private static function loadStrings(lib:RazorLibrary, bytes:ByteArray):void
	{
		var basePos:uint = bytes.position;
		
		var numLocales:uint = bytes.readUnsignedShort();
		
		if(!numLocales)
			return;
		
		var endPos:uint = basePos + bytes.readUnsignedInt();
		
		Localize.init();
	
		var localeName:String;
		var localeInfo:StringsLocale;
		var locales:Dictionary = new Dictionary();
		for(var l:uint = 0; l<numLocales; l++)
		{
			localeInfo = new StringsLocale();
			localeName = bytes.readUTF();
			localeInfo.Pos = basePos + bytes.readUnsignedInt();
			localeInfo.Parent = bytes.readUTF();
			locales[localeName] = localeInfo;
			Console.info("Loaded strings for locale "+localeName);
		}
		
		for(localeName in locales)
		{
			localeInfo = locales[localeName];
			var dashIndex:int = localeName.indexOf("-");
			if(dashIndex >= 0)
			{
				var baseLang:String = localeName.substring(0, dashIndex);
				if(!locales[baseLang])
				{
					locales[baseLang] = localeInfo;
				}
			}
		}
		
		for each(var language:String in Localize.PreferredLocales)
		{
			//Console.info("Matching against "+language);
			localeInfo = locales[language];
			if(localeInfo == null)
				continue;
				
			addStrings(lib, bytes, localeInfo, locales);
			break;
		}
		
		bytes.position = endPos;
	}
	
	private static function addStrings(lib:RazorLibrary, bytes:ByteArray, localeInfo:StringsLocale, locales:Dictionary):void
	{
		if(localeInfo.Parent)
		{
			addStrings(lib, bytes, locales[localeInfo.Parent], locales);
		}
		
		bytes.position = localeInfo.Pos;
		
		var stringID:String = bytes.readUTF();
		while(stringID)
		{
			var string:String = bytes.readUTF();
			lib.Strings[stringID] = string;
			L[stringID] = string;
			//trace("added "+stringID+" "+string);
			stringID = bytes.readUTF();
		}
	}
	
	public function unload():void
	{
		for each(var texturePage:RazorTexturePage in TexturePages)
		{
			texturePage.dispose();
			texturePage.Source = null;
			texturePage.Bindings = null;
		}
		
		for each(var font:RazorFont in Fonts)
		{
			font.unregister();
		}
		
		for(var stringID:String in Strings)
		{
			delete L[stringID];
		}
		
		TexturePages = null;
		AnimData = null;
		Sounds = null;
		Fonts = null;
		Strings = null;
		Data = null;
		
		delete LoadedLibaries[Name];
	}
	
	
	public function resolveResourceName(resourceName:String):Array
	{
		var libSep:int = resourceName.indexOf(":");
		if(libSep >= 0)
		{
			return [resourceName.substring(0, libSep), resourceName.substring(libSep+1)];
		}
		return [Name, resourceName];
	}
	
	public function bind(fstage:RazorStage, onBound:Function=null):void
	{
		var numWaiting:int = NumTotalTextures;
		var overallSuccess:Boolean = true;
		
		var onTextureBound:Function = function(success:Boolean):void
		{
			numWaiting -= 1;
			if(!success)
				overallSuccess = false;
			
			if(numWaiting <= 0 && onBound != null)
				onBound(overallSuccess);
		}
		
		for each(var texturePage:RazorTexturePage in TexturePages)
		{
			texturePage.bind(fstage, onTextureBound);
		}
		
		for each(var font:RazorFont in Fonts)
		{
			font.bind(fstage, onTextureBound);
		}
	}
	
	public function getTexture(textureID:String):RazorTexture
	{
		var split:uint = textureID.indexOf(".");
		if(split < 0)
			throw new Error("Invalid texture ID");
		
		var pageID:String = textureID.substring(0, split);
		var textureName:String = textureID.substring(split+1);
		
		var page:RazorTexturePage = TexturePages[pageID] as RazorTexturePage;
		if(!page)
			throw new Error("Unknown texture page ID");
		
		var texture:RazorTexture = page[textureName];
		
		if(!texture)
			throw new Error("Unknown texture ID");
		
		return texture;
	}
	
	public static function getTexture(resCouplet:Array):RazorTexture
	{
		var lib:RazorLibrary = LoadedLibaries[resCouplet[0]];
		if(!lib)
			return null;
		
		var textureID:String = resCouplet[1];
		
		var split:uint = textureID.indexOf(".");
		if(split < 0)
			throw new Error("Invalid texture ID");
		
		var pageID:String = textureID.substring(0, split);
		var textureName:String = textureID.substring(split+1);
		
		var page:RazorTexturePage = lib.TexturePages[pageID] as RazorTexturePage;
		if(!page)
			throw new Error("Unknown texture page ID");
		
		var texture:RazorTexture = page[textureName];
		
		if(!texture)
			throw new Error("Unknown texture ID");
		
		return texture;
	}
	
	public function getAnimData(animID:String):RazorAnimData
	{
		return AnimData[animID];
	}
	
	public static function getAnimData(resCouplet:Array):RazorAnimData
	{
		var lib:RazorLibrary = LoadedLibaries[resCouplet[0]];
		if(!lib)
			return null;
			
		return lib.AnimData[resCouplet[1]];
	}
	
	public static function getSound(resCouplet:Array):Sound
	{
		var lib:RazorLibrary = LoadedLibaries[resCouplet[0]];
		if(!lib)
			return null;
			
		return lib.Sounds[resCouplet[1]];
	}
	
	public static function getParticles(resCouplet:Array):RazorParticles
	{
		var lib:RazorLibrary = LoadedLibaries[resCouplet[0]];
		if(!lib)
			return null;
			
		return lib.Particles[resCouplet[1]];
	}
	
	public function getParticles(particlesID:String):RazorParticles
	{
		return Particles[particlesID];
	}
	
	public static function getData(resCouplet:Array):ByteArray
	{
		var lib:RazorLibrary = LoadedLibaries[resCouplet[0]];
		if(!lib)
			return null;
			
		return lib.Data[resCouplet[1]];
	}
}

}

class StringsLocale
{
	public var Pos:uint;
	public var Parent:String;
	
}