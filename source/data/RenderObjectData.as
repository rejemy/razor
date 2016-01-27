package razor.data
{

import flash.utils.ByteArray;

import omg.L;

import razor.display.RazorObject;
import razor.display.RazorObjectContainer;
import razor.display.RazorImage;
import razor.display.RazorAnim;
import razor.display.RazorEmitter;
import razor.display.RazorBaseText;
import razor.display.RazorDynamicText;
import razor.display.RazorStaticText;
import razor.display.RazorNativeText;
import razor.RazorLibrary;
import razor.texture.RazorTexture;
import razor.text.RazorFont;
import razor.particles.RazorParticles;

public class RenderObjectData
{
	public static const IMAGE:uint=1;
	public static const TEXT_DYNAMIC:uint=2;
	public static const TEXT_STATIC:uint=3;
	public static const TEXT_NATIVE:uint=4;
	public static const ANIM:uint=5;
	public static const SOCKET:uint=6;
	public static const PARTICLES:uint=7;
	
	public static var NativeFontOverride:Boolean = false;
	
	public var Name:String;
	public var Type:uint;
	public var Data:Object;
	
	public static function readFrom(data:ByteArray):RenderObjectData
	{
		var obj:RenderObjectData = new RenderObjectData();
		
		var name:String = data.readUTF();
		if(name.length)
			obj.Name = name;
			
		obj.Type = data.readUnsignedByte();
		switch(obj.Type)
		{
			case IMAGE:
			{
				obj.Data = data.readUTF();
				break;
			}
			case TEXT_DYNAMIC:
			case TEXT_STATIC:
			case TEXT_NATIVE:
			{
				var style:TextStyleData = new TextStyleData();
				obj.Data = style;
				
				var textID:String = data.readUTF();
				if(textID.length)
					style.TextID = textID;
				
				style.Width = data.readFloat();
				style.Height = data.readFloat();
					
				style.Fit = data.readUnsignedByte();
				style.Font = data.readUTF();
				style.Style = data.readUnsignedByte();
				style.Size = data.readUnsignedByte();
				style.Color = data.readUnsignedInt();
				style.Align = data.readUnsignedByte();
				
				style.FontRegistryID = RazorFont.makeRegistryNameStyle(style.Font, style.Size, style.Style);
				
				break;
			}
			case ANIM:
			{
				obj.Data = data.readUTF();
				break;
			}
			case SOCKET:
			{
				break;
			}
			case PARTICLES:
			{
				obj.Data = data.readUTF();
				break;
			}
		}
		
		return obj;
	}
	
	public function instantiate(lib:RazorLibrary):RazorObject
	{
		switch(Type)
		{
			case IMAGE:
			{
				var link:String = Data as String;
				var imgTexture:RazorTexture = lib.getTexture(link);
				var img:RazorImage = new RazorImage(imgTexture);
				return img;
			}
			case TEXT_DYNAMIC:
			case TEXT_STATIC:
			case TEXT_NATIVE:
			{
				var textType:uint = Type;
				//trace("Creating text type "+textType);
				
				var textBase:RazorBaseText;
				var style:TextStyleData = Data as TextStyleData;
				
				//trace("TextID: "+style.TextID);
				var initialText:String = "";
				if(style.TextID && L)
					initialText = L[style.TextID];
				//trace("Making text with initial text "+initialText);
				
				var font:RazorFont;
				var validFonts:Vector.<String>;
				var errorStr:String;
				var fontName:String;

				if(textType == TEXT_DYNAMIC)
				{
					font = RazorFont.Registry[style.FontRegistryID];
					if(!font)
					{
						if(!NativeFontOverride)
						{
							validFonts = RazorFont.getFontList();
							errorStr = "Unknown font! "+style.FontRegistryID+"\nValid fonts are:\n";
							for each(fontName in validFonts)
								errorStr += "    "+fontName+"\n";
							throw new Error(errorStr);
							
						}
						else
							trace("Couldn't find font "+style.FontRegistryID+", falling back on native");
					}
					else
					{
						//trace("Creating dynamic text")
						textBase = new RazorDynamicText(font, initialText);
					}
				}
				else if(textType == TEXT_STATIC)
				{
					font = RazorFont.Registry[style.FontRegistryID];
					if(!font)
					{
						if(!NativeFontOverride)
						{
							validFonts = RazorFont.getFontList();
							errorStr = "Unknown font! "+style.FontRegistryID+"\nValid fonts are:\n";
							for each(fontName in validFonts)
								errorStr += "    "+fontName+"\n";
							throw new Error(errorStr);
						}
						else
							trace("Couldn't find font "+style.FontRegistryID+", falling back on native");
					}
					else
					{
						//trace("Creating static text")
						textBase = new RazorStaticText(font, initialText);
					}
				}
				
				if(!textBase)
				{
					// Fall back to native text
					//trace("Creating native text")
					var bold:Boolean = style.Style == TextStyleData.BOLD || style.Style == TextStyleData.BOLD_ITALIC;
					var italic:Boolean = style.Style == TextStyleData.ITALIC || style.Style == TextStyleData.BOLD_ITALIC;
					textBase = new RazorNativeText(style.Font, style.Size, initialText, true, bold, italic);
				}
				
				textBase.setMaxWidth(style.Width);
				textBase.setMaxHeight(style.Height);
				
				textBase.setFit(style.Fit);
				textBase.setHAlign(style.Align);
				textBase.color = style.Color;
				//textBase.setBackgroundColor(0);

				return textBase;
			}
			case ANIM:
			{
				var animData:RazorAnimData = lib.AnimData[Data as String];
				var anim:RazorAnim = new RazorAnim(animData);
				return anim;
			}
			case SOCKET:
			{
				return new RazorObjectContainer();
			}
			case PARTICLES:
			{
				var particlesRes:Array = lib.resolveResourceName(Data as String);
				var particles:RazorParticles = RazorLibrary.getParticles(particlesRes);
				if(!particles)
				{
					trace("Couldn't find particles! "+Data);
					return new RazorObjectContainer();
				}
				return new RazorEmitter(particles);
			}
		}
		
		return null;
	}
}

}