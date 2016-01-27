package razor.display
{

import flash.geom.Matrix3D;
import flash.events.MouseEvent;
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
import razor.RazorInternal;

use namespace RazorInternal;

public class RazorDynamicText extends RazorBaseText
{
	protected var Glyphs:Vector.<RazorImage>;
	
	public function RazorDynamicText(font:RazorFont, text:String=null, smoothing:Boolean=true)
	{
		Glyphs = new Vector.<RazorImage>();
		super(font, text, smoothing);
		
	}
	
	public override function bind():void
	{
		if(NeedsReflow)
			flowText();
		
		Glyphs.length = Text.length;
		
		var xpos:Number = 0;
		var ypos:Number = 0;
		
		var numChars:int = Text.length;
		
		var lineNum:uint = 0;
		
		var combinedScale:Number = TextScale * FontScale;
		
		if(MaxHeight > 0)
		{
			var totalLineHeight:Number = LineLengths.length * Font.LineHeight * combinedScale;
			if(VAlign == CENTER)
				ypos = (MaxHeight - totalLineHeight)*0.5;
			else if(VAlign == BOTTOM)
				ypos = MaxHeight - totalLineHeight;
		}
		
		var incrementLength:Number=  0;
		var currLineLength:Number = LineLengths[lineNum];
		var xbase:Number = 0;
		if(HAlign == CENTER)
		{
			xbase = TextWidth * 0.5;
			xpos = -currLineLength * 0.5;
		}
		else if(HAlign == RIGHT)
		{
			xbase = TextWidth-1;
			xpos = -currLineLength;
		}
		
		var glyphsAdded:uint=0;
		
		var lastCharTexture:RazorFontCharacter = null;
		for(var c:int=0; c<numChars; c++)
		{
			var char:String = Text.charAt(c);
			var softWarp:Boolean = (Fit == WRAP && (char != " ") && incrementLength > currLineLength);
			if(char == "\n" || softWarp)
			{
				if(softWarp && char != "\n")
					c -= 1;
				
				incrementLength = 0;
					
				ypos += Font.LineHeight * FontScale;
				lastCharTexture = null;
				lineNum += 1;
				currLineLength = LineLengths[lineNum];
				
				if(HAlign == CENTER)
					xpos = -currLineLength * 0.5;
				else if(HAlign == RIGHT)
					xpos = -currLineLength;
				else
					xpos = 0;
				
				if(MaxHeight > 0 && (ypos + Font.LineHeight*FontScale)*TextScale > MaxHeight)
					break;
					
				continue;
			}
			
			var charTexture:RazorFontCharacter = Font.getCharacterTexture(char);
			if(!charTexture)
				continue;
			
			if(lastCharTexture && lastCharTexture.Kernings)
			{
				var kern:int = lastCharTexture.Kernings[char];
				xpos += kern * FontScale;
			}
			incrementLength += charTexture.Advance * FontScale;
			
			var nextXpos:Number = xpos+charTexture.Advance * FontScale;
			lastCharTexture = charTexture;
			
			if(ypos * TextScale < 0)
			{
				xpos = nextXpos;
				continue;
			}
			
			if(MaxWidth == 0 || (Fit == SCALE) || ((xbase+nextXpos) < MaxWidth && (xbase+xpos) >= 0))
			{
				var glyphImg:RazorImage = new RazorImage(charTexture, Smoothing);
				glyphImg.scaleX = combinedScale;
				glyphImg.scaleY = combinedScale;
				glyphImg.x = xbase+xpos*TextScale;
				glyphImg.y = ypos*TextScale;
				
				Glyphs[glyphsAdded] = glyphImg;
				glyphsAdded += 1;
				
				if(_stage)
					glyphImg.setStage(_stage, false);
			}
			
			xpos = nextXpos;
		}
		
		Glyphs.length = glyphsAdded;
	}
	
	public override function dispose(rebind:Boolean=false):void
	{
		Glyphs.length = 0;
		bind();
	}
	
	internal override function setStage(rstage:RazorStage, rebind:Boolean=false):void
	{
		super.setStage(rstage);
		
		for each(var child:RazorImage in Glyphs)
		{
			child.setStage(rstage, rebind);
		}
	}
	
	public override function render(modelView:Matrix3D, orientation:Number):void
	{
		orientation *= _scaleX * scaleY;

		if(Background)
			drawBackground(modelView, orientation);

		var cm0:Number = ColorMultVector[0] * TextColorRed;
		var cm1:Number = ColorMultVector[1] * TextColorGreen;
		var cm2:Number = ColorMultVector[2] * TextColorBlue;
		var cm3:Number = ColorMultVector[3];
		
		for each(var child:RazorImage in Glyphs)
		{
			child.ColorMultVector[0] = cm0;
			child.ColorMultVector[1] = cm1;
			child.ColorMultVector[2] = cm2;
			child.ColorMultVector[3] = cm3;
			
			child.ColorAddVector[0] = ColorAddVector[0];
			child.ColorAddVector[1] = ColorAddVector[1];
			child.ColorAddVector[2] = ColorAddVector[2];
			child.ColorAddVector[3] = ColorAddVector[3];
			
			child.render(child.getTransform(modelView), orientation);
		}
	}
}

}

