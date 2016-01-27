package razor.text
{

import omg.Console;
import omg.AppBase;
import omg.OMGUtil;

import flash.geom.Rectangle;
import flash.utils.Dictionary;
import flash.utils.ByteArray;

import razor.RazorUtils;
import razor.texture.RazorTexture;
import razor.display.RazorStage;
import razor.data.TextStyleData;
import razor.texture.TextureLoader;
import razor.texture.MemoryTextureLoader;
import razor.texture.RazorTexturePage;
import razor.RazorLibrary;

OMG::air
{
	import flash.filesystem.File;
	import razor.texture.FileTextureLoader;
}

public class RazorFont
{
	public var Name:String;
	public var Size:uint;
	public var Style:uint;
	public var LineHeight:Number;
	public var Base:Number;
	public var RegistryName:String;
	
	private var Pages:Vector.<RazorFontPage>;
	private var CharacterLookup:Dictionary;
	
	public static var Registry:Dictionary = new Dictionary();
	
	public function RazorFont()
	{
		Pages = new Vector.<RazorFontPage>();
		
		CharacterLookup = new Dictionary();
		
	}
	
	public function bind(fstage:RazorStage, onDone:Function = null):void
	{
		var waitingFor:int = Pages.length;
		var overallSuccess:Boolean = true;
		
		var onBound:Function = function(success:Boolean):void
		{
			if(!success)
				overallSuccess = false;
			
			waitingFor -= 1;
			if(waitingFor <= 0 && overallSuccess != null)
				onDone(overallSuccess);
		}
		
		for each(var page:RazorFontPage in Pages)
		{
			page.bind(fstage, onBound);
		}
	}
	
	public function getCharacterTexture(char:String):RazorFontCharacter
	{
		return CharacterLookup[char] as RazorFontCharacter;
	}
	
	public function getNumPages():uint
	{
		return Pages.length;
	}
	
	public function getPage(index:int):RazorFontPage
	{
		return Pages[index];
	}
	
	public function unregister():void
	{
		delete Registry[RegistryName];
	}
	
	public static function makeRegistryName(fontName:String, size:int, bold:Boolean=false, italic:Boolean = false):String
	{
		fontName = fontName.toLowerCase();
		fontName = OMGUtil.replace(fontName, " ", "");
		
		var style:uint;
		if(bold && italic)
			style = TextStyleData.BOLD_ITALIC;
		else if(bold)
			style = TextStyleData.BOLD;
		else if(italic)
			style = TextStyleData.ITALIC;
		else
			style = TextStyleData.NORMAL;
		
		return fontName+TextStyleData.getStyleString(style)+size;
	}
	
	public static function makeRegistryNameStyle(fontName:String, size:int, style:uint):String
	{
		fontName = fontName.toLowerCase();
		fontName = OMGUtil.replace(fontName, " ", "");
		fontName = OMGUtil.replace(fontName, "-", "");
		return fontName+TextStyleData.getStyleString(style)+size;
	}
	
	public static function fromFNT(fnt:Object, imageSource:Object, pixelDensity:Number=2.0):RazorFont
	{
		return fromFNTs([fnt], [imageSource], pixelDensity);
	}
	
	public static function fromFNTs(fnts:Array, imageSources:Array, pixelDensity:Number=2.0):RazorFont
	{
		var font:RazorFont = new RazorFont();
		
		if(fnts.length != imageSources.length)
		{
			throw new Error("Mismatched font arrays");
		}
		
		var textureWidth:uint = 0;
		var textureHeight:uint = 0;
		
		for(var i:uint=0; i<fnts.length; i++)
		{
			var fntSource:Object = fnts[i];
			if(fntSource is Class)
				fntSource = new fntSource();
			
			var fntXML:XML = XML(fntSource);
			var commonXML:XML = fntXML.common[0];
			
			if(i == 0)
			{
				// One time only
				var infoXML:XML = fntXML.info[0];

				var fontInfo:Object = cleanupFontName(infoXML.attribute("face"));
				font.Name = fontInfo.face;

				font.Size = parseInt(infoXML.attribute("size")) / pixelDensity;
				var bold:Boolean = infoXML.attribute("bold") == "1" || fontInfo.bold;
				var italic:Boolean = infoXML.attribute("italic") == "1" || fontInfo.italic;
				if(bold && italic)
					font.Style = TextStyleData.BOLD_ITALIC;
				else if(bold)
					font.Style = TextStyleData.BOLD;
				else if(italic)
					font.Style = TextStyleData.ITALIC;
				else
					font.Style = TextStyleData.NORMAL;
					
				font.LineHeight = parseInt(commonXML.attribute("lineHeight")) / pixelDensity;
				font.Base = parseInt(commonXML.attribute("base")) / pixelDensity;

			}
			
			textureWidth = parseInt(commonXML.attribute("scaleW"));
			textureHeight = parseInt(commonXML.attribute("scaleH"));
			
			var imgSource:Object = imageSources[i];
			
			var bounds:Rectangle = new Rectangle(0, 0, textureWidth, textureHeight);
			var fontPage:RazorFontPage = new RazorFontPage(i, imgSource, bounds, pixelDensity);
			font.Pages.push(fontPage);
			
			var charsXML:XMLList = fntXML.chars[0].char;
			for each(var charXML:XML in charsXML)
			{
				var codePoint:uint = parseInt(charXML.attribute("id"));
				var char:String = String.fromCharCode(codePoint);
				
				var x:uint = parseInt(charXML.attribute("x"));
				var y:uint = parseInt(charXML.attribute("y"));
				var width:uint = parseInt(charXML.attribute("width"));
				var height:uint = parseInt(charXML.attribute("height"));
				var xoffset:uint = parseInt(charXML.attribute("xoffset"));
				var yoffset:uint = parseInt(charXML.attribute("yoffset"));

				var charTex:RazorFontCharacter = fontPage.add(String(codePoint), x, y, width, height, xoffset, yoffset) as RazorFontCharacter;
				
				charTex.Advance = parseInt(charXML.attribute("xadvance")) / pixelDensity;
				
				font.CharacterLookup[char] = charTex;
			}
			
			var kernPairsXML:XMLList = fntXML.kernings[0].kerning;
			for each(var kernPairXML:XML in kernPairsXML)
			{
				var firstCode:uint = parseInt(kernPairXML.attribute("first"));
				var firstChar:String = String.fromCharCode(firstCode);
				var secondCode:uint = parseInt(kernPairXML.attribute("second"));
				var secondChar:String = String.fromCharCode(secondCode);
				
				var firstCharTex:RazorFontCharacter = font.getCharacterTexture(firstChar);
				if(firstCharTex.Kernings == null)
					firstCharTex.Kernings = new Dictionary();
					
				var amount:Number = parseInt(kernPairXML.attribute("amount")) / pixelDensity;
				if(amount != 0)
				{
					firstCharTex.Kernings[secondChar] = amount;
				}
			}
		}
		
		font.RegistryName = makeRegistryNameStyle(font.Name, font.Size, font.Style);
		Registry[font.RegistryName] = font;
		
		return font;
	}
	
	public static function fromBytes(bytes:ByteArray, sourceFileObj:Object=null):RazorFont
	{
		OMG::air
		{
			var sourceFile:File = sourceFileObj as File;
		}
		
		var font:RazorFont = new RazorFont();
		
		var sourceDensity:Number = bytes.readFloat();
		var textureFormat:String = RazorLibrary.translateTextureFormat(bytes.readUnsignedByte());
		
		var numPages:uint = bytes.readUnsignedByte();
		
		//if(numPages != imageSources.length)
		//{
		//	throw new Error("Wrong number of image sources");
		//}
		
		font.Name = bytes.readUTF();
		font.Size = bytes.readUnsignedByte();
		font.Style = bytes.readUnsignedByte();
		font.LineHeight = bytes.readFloat();
		font.Base = bytes.readFloat();
		
		for(var i:uint=0; i<numPages; i++)
		{
			var sourceWidth:uint = bytes.readUnsignedShort();
			var sourceHeight:uint = bytes.readUnsignedShort();
			var numDensities:uint = bytes.readUnsignedByte();
			var textureLoader:TextureLoader = null;
			var bounds:Rectangle = new Rectangle(0, 0, sourceWidth, sourceHeight);
			var textureDensity:Number;
			
			for(var d:uint=0; d<numDensities; d++)
			{
				var density:Number = bytes.readFloat();
				var texwidth:uint = bytes.readUnsignedShort();
				var texheight:uint = bytes.readUnsignedShort();
				var byteLength:uint = bytes.readUnsignedInt();
				var nextPos:uint = bytes.position + byteLength;
				//trace("Font density: "+density+" "+texwidth+"x"+texheight+" "+byteLength);
				
				if(!textureLoader && (density >= RazorUtils.ScreenPixelDensity || d == (numDensities-1)))
				{
					OMG::air
					{
						if(sourceFile)
						{
							textureLoader = new FileTextureLoader(sourceFile, bytes.position, byteLength, texwidth, texheight, textureFormat);
						}
						else
						{
							var texBytes:ByteArray = new ByteArray();
							bytes.readBytes(texBytes, 0, byteLength);
							textureLoader = new MemoryTextureLoader(texBytes, 0, byteLength, texwidth, texheight, textureFormat);
						}
					}
					OMG::flash
					{
						var texBytes:ByteArray = new ByteArray();
						bytes.readBytes(texBytes, 0, byteLength);
						textureLoader = new MemoryTextureLoader(texBytes, 0, byteLength, texwidth, texheight, textureFormat);
					}
					
					textureDensity = density;
				}
				
				bytes.position = nextPos;
			}
			
			var fontPage:RazorFontPage = new RazorFontPage(i, textureLoader, bounds, sourceDensity, RazorTexturePage.SCALE_PRESCALED, (textureDensity/sourceDensity));
			font.Pages.push(fontPage);
			
			var pixelDensity:Number = sourceDensity;
			
			var numChars:uint = bytes.readUnsignedShort();
			for(var c:uint=0; c<numChars; c++)
			{
				var codePoint:uint = bytes.readUnsignedInt();
				var char:String = String.fromCharCode(codePoint);
				
				var x:uint = bytes.readUnsignedShort();
				var y:uint = bytes.readUnsignedShort();
				var width:uint = bytes.readUnsignedShort();
				var height:uint = bytes.readUnsignedShort();
				var xoffset:uint = bytes.readShort();
				var yoffset:uint = bytes.readShort();
				//trace("Adding "+char);
				var charTex:RazorFontCharacter = fontPage.add(String(codePoint), x, y, width, height, xoffset, yoffset) as RazorFontCharacter;
				
				charTex.Advance = bytes.readShort() / pixelDensity;
				
				font.CharacterLookup[char] = charTex;
			}
			
			var numKernPairs:uint = bytes.readUnsignedShort();
			for(var k:uint=0; k<numKernPairs; k++)
			{
				var firstCode:uint = bytes.readUnsignedInt();
				var firstChar:String = String.fromCharCode(firstCode);
				var secondCode:uint = bytes.readUnsignedInt();
				var secondChar:String = String.fromCharCode(secondCode);
				
				//trace("Kerning pair: "+firstCode+", "+secondCode);
				
				var firstCharTex:RazorFontCharacter = font.getCharacterTexture(firstChar);
				if(firstCharTex.Kernings == null)
					firstCharTex.Kernings = new Dictionary();
					
				var amount:Number = bytes.readShort() / pixelDensity;
				if(amount != 0)
				{
					firstCharTex.Kernings[secondChar] = amount;
				}
			}
		}
		
		font.RegistryName = makeRegistryNameStyle(font.Name, font.Size, font.Style);
		Registry[font.RegistryName] = font;
		
		//trace("Registered font "+font.RegistryName);
		
		return font;
	}
	
	public static function getFontList():Vector.<String>
	{
		return OMGUtil.getSortedStrings(Registry);
	}

	public static function cleanupFontName(fontName:String):Object
	{
		if(!fontName || fontName.length == 0)
			return null;

		fontName = fontName.toLowerCase();
		fontName = OMGUtil.replace(fontName, " ", "");
		fontName = OMGUtil.replace(fontName, "_", "");
		fontName = OMGUtil.replace(fontName, "-", "");
		
		var bold:Boolean = false;
		var italic:Boolean = false;

		while(true)
		{
			if(OMGUtil.endsWith(fontName, "regular"))
			{
				fontName = fontName.substring(0, fontName.length - 7);
			}
			else if(OMGUtil.endsWith(fontName, "bold"))
			{
				fontName = fontName.substring(0, fontName.length - 4);
				bold = true;
			}
			else if(OMGUtil.endsWith(fontName, "italic"))
			{
				fontName = fontName.substring(0, fontName.length - 6);
				italic = true;
			}
			else
				break;
		}

		var result:Object = {};

		result.face = fontName;
		result.bold = bold;
		result.italic = italic;


		return result;
	}
}

}