package razor.display
{

import flash.geom.Matrix3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.Context3D;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTriangleFace;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.Context3DWrapMode;
import flash.display3D.Context3DMipFilter;
import flash.display3D.Context3DTextureFilter;

import razor.text.RazorFont;
import razor.text.RazorFontPage;
import razor.text.RazorFontCharacter;
import razor.TouchInfo;
import razor.RazorProgram;
import razor.RazorInternal;

use namespace RazorInternal;

public class RazorStaticText extends RazorBaseText
{	
	private var Program:Program3D;
	private var Bindings:Vector.<FontPageBinding>;

	public function RazorStaticText(font:RazorFont, text:String=null, smoothing:Boolean=true)
	{
		super(font, text, smoothing);
		
		Bindings = new Vector.<FontPageBinding>(1);
	}
	
	public override function bind():void
	{
		if(NeedsReflow)
			flowText();
		
		var indexes:Vector.<uint> = new Vector.<uint>();
		var listOfVerts:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(1);
		
		var numPages:uint = Font.getNumPages();
		var p:int;
		for(p=0; p<numPages; p++)
			listOfVerts[p] = new Vector.<Number>();
		
		var xpos:Number = 0;
		var ypos:Number = 0;
		
		var numChars:int = Text.length;
		var mostVertsPerPage:int = 0;
		var v:int;
		var verts:Vector.<Number>;
		var page:RazorFontPage;
		
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
		
		var lastCharTexture:RazorFontCharacter = null;
		for(var c:int=0; c<numChars; c++)
		{
			var char:String = Text.charAt(c);
			var softWarp:Boolean = (Fit == WRAP && (char != " ") && incrementLength > currLineLength);
			if(char == "\n" || softWarp)
			{
				if(softWarp && char != "\n")
					c -= 1;
				
				ypos += Font.LineHeight * FontScale;
				lastCharTexture = null;
				lineNum += 1;
				if(lineNum >= LineLengths.length)
				{
					trace("What the heck? incremental: "+incrementLength+" line: "+currLineLength)
					break;
				}
				
				incrementLength = 0;
				currLineLength = LineLengths[lineNum];
				
				if(HAlign == CENTER)
					xpos = -currLineLength * 0.5;
				else if(HAlign == RIGHT)
					xpos = -currLineLength;
				else
					xpos = 0;
				
				if(MaxHeight > 0 && (ypos + Font.LineHeight * FontScale)*TextScale > MaxHeight)
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
				page = charTexture.Page as RazorFontPage;
				verts = listOfVerts[page.Index];
				v = verts.length;
			
				verts[v++] = xbase+(xpos+charTexture.OffsetX*FontScale)*TextScale;
				verts[v++] = (ypos+charTexture.OffsetY*FontScale)*TextScale;
				verts[v++] = charTexture.MinU; verts[v++] = charTexture.MinV;
			
				verts[v++] = xbase+(xpos+charTexture.OffsetX*FontScale+charTexture.Width*FontScale)*TextScale;
				verts[v++] = (ypos+charTexture.OffsetY*FontScale)*TextScale;
				verts[v++] = charTexture.MaxU; verts[v++] = charTexture.MinV;
			
				verts[v++] = xbase+(xpos+charTexture.OffsetX*FontScale+charTexture.Width*FontScale)*TextScale;
				verts[v++] = (ypos+charTexture.OffsetY*FontScale+charTexture.Height*FontScale)*TextScale;
				verts[v++] = charTexture.MaxU; verts[v++] = charTexture.MaxV;
			
				verts[v++] = xbase+(xpos+charTexture.OffsetX*FontScale)*TextScale;
				verts[v++] = (ypos+charTexture.OffsetY*FontScale+charTexture.Height*FontScale)*TextScale;
				verts[v++] = charTexture.MinU; verts[v++] = charTexture.MaxV;
				if(v > mostVertsPerPage)
					mostVertsPerPage = v;
			}

			
			xpos = nextXpos;
		}
		
		var maxQuads:int = mostVertsPerPage / 16;
		
		var pos:uint=0;
		v = 0;
		for(var i:int = 0; i<maxQuads; i++)
		{
			indexes[pos++] = v;
			indexes[pos++] = v+1;
			indexes[pos++] = v+2;
			indexes[pos++] = v;
			indexes[pos++] = v+2;
			indexes[pos++] = v+3;
			v+=4;
		}
		
		for(p=0; p<numPages; p++)
		{
			verts = listOfVerts[p];
			if(verts.length == 0)
				continue;
			
			var quads:int = verts.length / 16;
			
			var binding:FontPageBinding = new FontPageBinding();
			Bindings[p] = binding;
			page = Font.getPage(p);
			binding.PageTexture = page.bind(_stage).MyTexture;
			
			binding.VertBuffer = _stage.Context.createVertexBuffer(quads * 4, 4);
			binding.VertBuffer.uploadFromVector(verts, 0, quads*4);
			
			binding.IndexBuffer = stage.Context.createIndexBuffer(quads * 6);
			binding.IndexBuffer.uploadFromVector(indexes, 0, quads * 6);
			
			binding.NumTris = quads * 2;
		}
	}
	
	public override function dispose(rebind:Boolean=false):void
	{
		if(!Bindings)
			return;
			
		for each(var binding:FontPageBinding in Bindings)
		{
			if(binding)
			{
				if(binding.VertBuffer)
					binding.VertBuffer.dispose();
				if(binding.IndexBuffer)
					binding.IndexBuffer.dispose();
			}
		}
		
		Bindings.length = 0;
	}
	
	private function pickProgram():void
	{
			
		if(ColorMultVector[0] == 1.0 && ColorMultVector[1] == 1.0 && ColorMultVector[2] == 1.0 && ColorMultVector[3] == 1.0)
		{
			if(ColorAddVector[0] == 0.0 && ColorAddVector[1] == 0.0 && ColorAddVector[2] == 0.0 && ColorAddVector[3] == 0.0)
				Program = RazorProgram.getTextured(_stage);
			else
				Program = RazorProgram.getTexturedAdd(_stage);
		}
		else
		{
			if(ColorAddVector[0] == 0.0 && ColorAddVector[1] == 0.0 && ColorAddVector[2] == 0.0 && ColorAddVector[3] == 0.0)
				Program = RazorProgram.getTexturedMult(_stage);
			else
				Program = RazorProgram.getTexturedMultAdd(_stage);
		}
	}
	
	public override function render(modelView:Matrix3D, orientation:Number):void
	{		
		var context:Context3D = _stage.Context;
		
		var combinedAlpha:Number = ColorMultVector[3] + ColorAddVector[3];
		
		orientation *= _scaleX * _scaleY

		if(Background)
			drawBackground(modelView, orientation);

		context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
		
		if(orientation > 0)
			context.setCulling(Context3DTriangleFace.BACK);
		else
			context.setCulling(Context3DTriangleFace.FRONT);
		
		ColorMultVector[0] *= TextColorRed * combinedAlpha;
		ColorMultVector[1] *= TextColorGreen * combinedAlpha;
		ColorMultVector[2] *= TextColorBlue * combinedAlpha;
		
		ColorAddVector[0] *= combinedAlpha;
		ColorAddVector[1] *= combinedAlpha;
		ColorAddVector[2] *= combinedAlpha;
		
		//trace("Mult: "+ColorMultVector[0]+","+ColorMultVector[1]+","+ColorMultVector[2]+","+ColorMultVector[3]);
		//trace("Add : "+ColorAddVector[0]+","+ColorAddVector[1]+","+ColorAddVector[2]+","+ColorAddVector[3]);
		
		pickProgram();
		
		if(Smoothing)
			context.setSamplerStateAt(0, Context3DWrapMode.CLAMP, Context3DTextureFilter.LINEAR, Context3DMipFilter.MIPNONE);
		else
			context.setSamplerStateAt(0, Context3DWrapMode.CLAMP, Context3DTextureFilter.NEAREST, Context3DMipFilter.MIPNONE);
			
		context.setProgram(Program);
		context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, modelView, true);
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, ColorMultVector, 1);
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, ColorAddVector, 1);
		
		for each(var binding:FontPageBinding in Bindings)
		{
			if(!binding || !binding.PageTexture)
				continue;
				
			context.setTextureAt(0, binding.PageTexture);

			context.setVertexBufferAt(0, binding.VertBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			context.setVertexBufferAt(1, binding.VertBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);

			context.drawTriangles(binding.IndexBuffer, 0, binding.NumTris);
		}
		
		
	}
	
}

}

import flash.display3D.textures.Texture;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;

class FontPageBinding
{
	public var NumTris:int;
	public var PageTexture:Texture;
	public var VertBuffer:VertexBuffer3D;
	public var IndexBuffer:IndexBuffer3D;
}