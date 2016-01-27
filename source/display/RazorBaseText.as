package razor.display
{

import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.Context3D;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTriangleFace;
import flash.display3D.Context3DVertexBufferFormat;

import razor.text.RazorFont;
import razor.text.RazorFontPage;
import razor.text.RazorFontCharacter;
import razor.TouchInfo;
import razor.RazorProgram;
import razor.events.TouchEvent;
import razor.RazorInternal;

use namespace RazorInternal;

public class RazorBaseText extends RazorObject
{
	public static const SCALE:uint=0;
	public static const WRAP:uint=1;
	public static const CLIP:uint=2;
	
	public static const LEFT:uint=0;
	public static const RIGHT:uint=1;
	public static const CENTER:uint=2;
	public static const TOP:uint=0;
	public static const BOTTOM:uint=1;
	
	protected var TextWidth:Number=0;
	protected var TextHeight:Number=0;
	
	protected var MaxWidth:Number=0;
	protected var MaxHeight:Number=0;
	protected var Fit:uint=0;
	protected var HAlign:uint=0;
	protected var VAlign:uint=0;
	
	
	protected var LineLengths:Vector.<Number>;
	protected var LongestLine:Number=0;
	protected var NumLines:uint=0;
	protected var TextScale:Number=1.0;
	protected var FontScale:Number=1.0;
	
	protected var Text:String;
	protected var Font:RazorFont;
	protected var Smoothing:Boolean;
	protected var TextColor:uint;
	protected var TextColorRed:Number;
	protected var TextColorGreen:Number;
	protected var TextColorBlue:Number;
	protected var FontSize:uint;
	
	protected var Background:RazorQuad;

	protected var NeedsReflow:Boolean;
	
	public function RazorBaseText(font:RazorFont, text:String=null, smoothing:Boolean=true)
	{
		Font = font;
		if(Font == null)
			throw new Error("Passed in a null font");
			
		Smoothing = smoothing;
		
		LineLengths = new Vector.<Number>();

		NeedsReflow = true;
		setText(text);
		
		if(Font)
			fontSize = Font.Size;
		
		color = 0xffffff;
	}
	
	public function getText():String
	{
		return Text;
	}
	
	public function setText(text:String):void
	{
		if(text == null)
			text = "";
		
		if(text == Text)
			return;
		
		Text = text;
		
		//trace("Setting text to "+text);
		NeedsReflow = true;
		dispose();
	}
	
	public function get fontSize():uint
	{
		return FontSize;
	}
	
	public function set fontSize(size:uint):void
	{
		if(size == 0)
			return;
			
		FontSize = size;
		FontScale = FontSize / Font.Size;
		
		NeedsReflow = true;
		dispose();
	}
	
	protected function flowText():void
	{
		LongestLine = 0;
		LineLengths = new Vector.<Number>();
		
		var lineLen:Number = 0;
		var lastCharTexture:RazorFontCharacter = null;
		
		NumLines = 1;
		
		var lastWasWhitespace:Boolean=false;
		var lastGapBegin:Number=0;
		var lastGapEndChar:int=0;
		
		var numChars:uint = Text.length;
		for(var c:int=0; c<numChars; c++)
		{
			var char:String = Text.charAt(c);
			
			if(char == "\n")
			{
				LineLengths.push(lineLen);
				//trace("Line "+LineLengths.length+" len: "+lineLen);
				
				lastGapBegin = 0;
				lastGapEndChar = 0;
				
				NumLines += 1;
				if(lineLen > LongestLine)
					LongestLine = lineLen;
				lineLen = 0;
				lastCharTexture = null;
				lastWasWhitespace = false;
				continue;
			}
			
			var charTexture:RazorFontCharacter = Font.getCharacterTexture(char);
			if(!charTexture)
				continue;
				
			var isWhitespace:Boolean = (char == " ");
			if(isWhitespace && !lastWasWhitespace)
			{
				lastGapBegin = lineLen;
			}
			else if(!isWhitespace && lastWasWhitespace)
			{
				lastGapEndChar = c;
			}
			
			
			var kern:int = 0;
			if(lastCharTexture && lastCharTexture.Kernings)
				kern = lastCharTexture.Kernings[char];
			lineLen += (kern + charTexture.Advance) * FontScale;
			
			if(Fit == WRAP && !isWhitespace && lineLen >= MaxWidth && lastGapBegin > 0)
			{
				lineLen = lastGapBegin;
				LineLengths.push(lineLen);
				//trace("Line "+LineLengths.length+" len: "+lineLen);
				
				c = lastGapEndChar-1;
				lastGapBegin = 0;
				lastGapEndChar = 0;
				
				NumLines += 1;
				if(lineLen > LongestLine)
					LongestLine = lineLen;
				lineLen = 0;
				lastCharTexture = null;
				lastWasWhitespace = false;
				
				continue;
			}
			
			lastCharTexture = charTexture;
			lastWasWhitespace = isWhitespace;
		}
		
		LineLengths.push(lineLen);
		//trace("Line "+LineLengths.length+" len: "+lineLen);
		
		if(lineLen > LongestLine)
			LongestLine = lineLen;
		
		if((Fit == SCALE) && MaxWidth > 0 && LongestLine > MaxWidth)
			TextScale = MaxWidth / LongestLine;
		else
			TextScale = 1.0;
		
		if(MaxWidth == 0)
			TextWidth = LongestLine;
		
		if(MaxHeight == 0)
			TextHeight = NumLines * Font.LineHeight * TextScale * FontScale;
			
		NeedsReflow = false;
		
		if(Background)
		{
			Background.setSize(TextWidth, TextHeight);
		}
	}
	
	public function getMaxWidth():Number
	{
		return MaxWidth;
	}
	
	public function setMaxWidth(width:Number):void
	{
		if(width == MaxWidth)
			return;
			
		MaxWidth = width;
		
		if(MaxWidth > 0)
			TextWidth = MaxWidth;
		else
			TextWidth = LongestLine;
		
		if((Fit == SCALE) && MaxWidth > 0 && LongestLine > MaxWidth)
			TextScale = MaxWidth / LongestLine;
		else
			TextScale = 1.0;
		
		if(Fit == WRAP)
			NeedsReflow = true;
			
		dispose();
	}
	
	public function getMaxHeight():Number
	{
		return MaxHeight;
	}
	
	public function setMaxHeight(height:Number):void
	{
		if(height == MaxHeight)
			return;
		
		MaxHeight = height;
		
		if(MaxHeight > 0)
			TextHeight = MaxHeight;
		else
			TextHeight = NumLines * Font.LineHeight * TextScale * FontScale;
			
		dispose();
	}
	
	public function getTextWidth():Number
	{
		if(NeedsReflow)
			flowText();
			
		return TextWidth;
	}
	
	public function getTextHeight():Number
	{
		if(NeedsReflow)
			flowText();
			
		return TextHeight;
	}
	
	public function getFit():uint
	{
		return Fit;
	}
	
	public function setFit(fit:uint):void
	{
		if(fit == Fit)
			return;
		
		if(Fit == WRAP && MaxWidth > 0)
			NeedsReflow = true;
		
		Fit = fit;
		
		if(Fit == SCALE && MaxWidth > 0 && LongestLine > MaxWidth)
			TextScale = MaxWidth / LongestLine;
		else
			TextScale = 1.0;
		
		if(Fit == WRAP && MaxWidth > 0)
			NeedsReflow = true;
		
		dispose();
	}
	
	public function getHAlign():uint
	{
		return HAlign;
	}
	
	public function setHAlign(align:uint):void
	{
		HAlign = align;
		
		dispose();
	}
	
	public function getVAlign():uint
	{
		return VAlign;
	}
	
	public function setVAlign(align:uint):void
	{
		VAlign = align;
		
		dispose();
	}
	
	public function get color():uint
	{
		return TextColor;
	}
	
	public function set color(val:uint):void
	{
		TextColor = val;
		TextColorRed = ((val >> 16) & 0xff) / 255;
		TextColorGreen = ((val >> 8) & 0xff) / 255;
		TextColorBlue = (val & 0xff) / 255;
	}

	public function setBackgroundColor(color:uint):void
	{
		if(!Background)
		{
			Background = new RazorQuad(TextWidth, TextHeight, color);
			Background.setStage(_stage);
		}
		else
			Background.color = color;
	}

	public function clearBackgroundColor():void
	{
		if(Background)
			 Background = null;
	}
	
	public override function touchTest(info:TouchInfo, localX:Number, localY:Number):Boolean
	{
		if(localX < 0 || localX >= TextWidth ||
			localY < 0 || localY >= TextHeight)
			return false;

		return true;
	}
	
	public override function getLocalBounds():Rectangle
	{
		if(NeedsReflow)
			flowText();
			
		return new Rectangle(0, 0, TextWidth, TextHeight);
	}

	protected function drawBackground(modelView:Matrix3D, orientation:Number):void
	{
		if(!Background)
			return;
		
		Background.ColorMultVector[0] = ColorMultVector[0];
		Background.ColorMultVector[1] = ColorMultVector[1];
		Background.ColorMultVector[2] = ColorMultVector[2];
		Background.ColorMultVector[3] = ColorMultVector[3];
		
		Background.ColorAddVector[0] = ColorAddVector[0];
		Background.ColorAddVector[1] = ColorAddVector[1];
		Background.ColorAddVector[2] = ColorAddVector[2];
		Background.ColorAddVector[3] = ColorAddVector[3];

		Background.render(Background.getTransform(modelView), orientation);	
	}

	internal override function setStage(rstage:RazorStage, rebind:Boolean=false):void
	{
		super.setStage(rstage);
		
		if(Background)
			Background.setStage(rstage, rebind);
	}
}

}
