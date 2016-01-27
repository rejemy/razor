package razor.display
{

import flash.display3D.Context3D;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTriangleFace;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.Context3DWrapMode;
import flash.display3D.Context3DMipFilter;
import flash.display3D.Context3DTextureFilter;
import flash.display3D.textures.Texture;
import flash.display.DisplayObject;	
import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.text.TextFormat;

import razor.RazorProgram;
import razor.texture.RazorTexture;
import razor.texture.RazorTextureBinding;
import razor.TouchInfo;
import razor.events.TouchEvent;
import razor.RazorInternal;

use namespace RazorInternal;



public class RazorImage extends RazorObject
{
	public var Texture:RazorTexture;
	public var TextureOwner:Boolean = false;
	public var Smoothing:Boolean;
	public var Use9Slice:Boolean = false;
	
	private var TextureBinding:RazorTextureBinding;
	private var Program:Program3D;
	
	public function RazorImage(tex:RazorTexture, smoothing:Boolean=true)
	{
		Texture = tex;
		Smoothing = smoothing;
		if(Texture.SliceRect)
			Use9Slice = true;
	}
	
	public function get texture():RazorTexture
	{
		return Texture;
	}
	
	public function set texture(texture:RazorTexture):void
	{
		Texture = texture;
		if(TextureBinding)
			bind();
		if(Texture.SliceRect)
			Use9Slice = true;
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
	
	public override function bind():void
	{
		var context:Context3D = _stage.Context;
		
		TextureBinding = Texture.Page.bind(_stage);
		
		pickProgram();
		
	}
	
	public override function dispose(rebind:Boolean=false):void
	{
		if(TextureOwner && Texture && !rebind)
		{
			Texture.Page.dispose();
			Texture = null;
			TextureOwner = false;
		}
		
		TextureBinding = null;
	}
	
	public override function render(modelView:Matrix3D, orientation:Number):void
	{
		if(!TextureBinding.MyTexture)
			return;
		
		var context:Context3D = _stage.Context;
		
		var combinedAlpha:Number = ColorMultVector[3] + ColorAddVector[3];
		
		if(Texture.Page.SourceTransparent || combinedAlpha != 1.0)
			context.setBlendFactors(Texture.Page.BlendSource, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
		else
			context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
		
		if(orientation * _scaleX * _scaleY > 0)
			context.setCulling(Context3DTriangleFace.BACK);
		else
			context.setCulling(Context3DTriangleFace.FRONT);
			
		ColorMultVector[0] *= combinedAlpha;
		ColorMultVector[1] *= combinedAlpha;
		ColorMultVector[2] *= combinedAlpha;
		
		ColorAddVector[0] *= combinedAlpha;
		ColorAddVector[1] *= combinedAlpha;
		ColorAddVector[2] *= combinedAlpha;
		
		pickProgram();
		
		if(Smoothing)
			context.setSamplerStateAt(0, Context3DWrapMode.CLAMP, Context3DTextureFilter.LINEAR, Context3DMipFilter.MIPNONE);
		else
			context.setSamplerStateAt(0, Context3DWrapMode.CLAMP, Context3DTextureFilter.NEAREST, Context3DMipFilter.MIPNONE);
		
		context.setTextureAt(0, TextureBinding.MyTexture);
		context.setProgram(Program);
		context.setVertexBufferAt(0, TextureBinding.Vertexes, 0, Context3DVertexBufferFormat.FLOAT_2);
		context.setVertexBufferAt(1, TextureBinding.Vertexes, 2, Context3DVertexBufferFormat.FLOAT_2);
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, ColorMultVector, 1);
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, ColorAddVector, 1);
		
		if(Use9Slice)
		{
			// Nullify object scale
			modelView.prependScale(1/_scaleX, 1/_scaleY, 1.0);
			
			var centerWidth:Number = Texture.Width * _scaleX - (Texture.Width - Texture.SliceRect.width);
			if(centerWidth <= 0)
			{
				centerWidth = 0;
			}
			var centerScaleX:Number = centerWidth / Texture.SliceRect.width;
			
			//trace("TextureWidth / SliceWidth / centerWidth / scaleX: "+Texture.Width+" / "+Texture.SliceRect.width+" / "+centerWidth+" / "+centerScaleX);

			var centerHeight:Number = Texture.Height * _scaleY - (Texture.Height - Texture.SliceRect.height);
			if(centerHeight <= 0)
			{
				centerHeight = 0;
			}
			var centerScaleY:Number = centerHeight / Texture.SliceRect.height;
			
			//trace("TextureHeight / SliceHeight/ centerHeight / scaleY: "+Texture.Height+" / "+Texture.SliceRect.height+" / "+centerHeight+" / "+centerScaleY);

			// Top left corner
			var tempMatrix:Matrix3D = modelView.clone();
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, tempMatrix, true);
			context.drawTriangles(TextureBinding.Indexes, Texture.SliceTextures[0].TriangleIndex, 2);
			
			// Top center
			if(centerWidth > 0)
			{
				tempMatrix = modelView.clone();
				tempMatrix.prependTranslation(Texture.SliceRect.x, 0, 0);
				tempMatrix.prependScale(centerScaleX, 1.0, 1.0);
				context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, tempMatrix, true);
				context.drawTriangles(TextureBinding.Indexes, Texture.SliceTextures[1].TriangleIndex, 2);
			}
			
			// Top right corner
			tempMatrix = modelView.clone();
			tempMatrix.prependTranslation(Texture.SliceRect.x+centerWidth, 0, 0);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, tempMatrix, true);
			context.drawTriangles(TextureBinding.Indexes, Texture.SliceTextures[2].TriangleIndex, 2);
			
			
			if(centerHeight > 0)
			{
				// Left center
				tempMatrix = modelView.clone();
				tempMatrix.prependTranslation(0, Texture.SliceRect.y, 0);
				tempMatrix.prependScale(1.0, centerScaleY, 1.0);
				context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, tempMatrix, true);
				context.drawTriangles(TextureBinding.Indexes, Texture.SliceTextures[3].TriangleIndex, 2);
			
				// Middle
				if(centerWidth > 0)
				{
					tempMatrix = modelView.clone();
					tempMatrix.prependTranslation(Texture.SliceRect.x, Texture.SliceRect.y, 0);
					tempMatrix.prependScale(centerScaleX, centerScaleY, 1.0);
					context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, tempMatrix, true);
					context.drawTriangles(TextureBinding.Indexes, Texture.SliceTextures[4].TriangleIndex, 2);
				}
		
				// right center
				tempMatrix = modelView.clone();
				tempMatrix.prependTranslation(Texture.SliceRect.x+centerWidth, Texture.SliceRect.y, 0);
				tempMatrix.prependScale(1.0, centerScaleY, 1.0);
				context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, tempMatrix, true);
				context.drawTriangles(TextureBinding.Indexes, Texture.SliceTextures[5].TriangleIndex, 2);
			}
			
			// Bottom left corner
			tempMatrix = modelView.clone();
			tempMatrix.prependTranslation(0, Texture.SliceRect.y+centerHeight, 0);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, tempMatrix, true);
			context.drawTriangles(TextureBinding.Indexes, Texture.SliceTextures[6].TriangleIndex, 2);
			
			// bottom center
			if(centerWidth > 0)
			{
				tempMatrix = modelView.clone();
				tempMatrix.prependTranslation(Texture.SliceRect.x, Texture.SliceRect.y+centerHeight, 0);
				tempMatrix.prependScale(centerScaleX, 1.0, 1.0);
				context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, tempMatrix, true);
				context.drawTriangles(TextureBinding.Indexes, Texture.SliceTextures[7].TriangleIndex, 2);
			}
			
			// bottom right corner
			tempMatrix = modelView.clone();
			tempMatrix.prependTranslation(Texture.SliceRect.x+centerWidth, Texture.SliceRect.y+centerHeight, 0);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, tempMatrix, true);
			context.drawTriangles(TextureBinding.Indexes, Texture.SliceTextures[8].TriangleIndex, 2);
		}
		else
		{
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, modelView, true);
			context.drawTriangles(TextureBinding.Indexes, Texture.TriangleIndex, 2);
		}
	}
	
	public override function touchTest(info:TouchInfo, localX:Number, localY:Number):Boolean
	{
		if(localX < Texture.OffsetX || localX >= Texture.Width + Texture.OffsetX ||
			localY < Texture.OffsetY || localY >= Texture.Height + Texture.OffsetY)
			return false;
		
		return true;
	}
	
	public static function fromDisplayObject(obj:DisplayObject, smoothing:Boolean=true, bounds:Rectangle=null, padding:Number=0, quality:String=null):RazorImage
	{
		var tex:RazorTexture = RazorTexture.fromDisplayObject(obj, bounds, padding, quality);
		var img:RazorImage = new RazorImage(tex, smoothing);
		img.TextureOwner = true;
		return img;
	}
	
	public static function fromText(text:String, textFormat:TextFormat, smoothing:Boolean=false):RazorImage
	{
		var tex:RazorTexture = RazorTexture.fromText(text, textFormat);
		var img:RazorImage = new RazorImage(tex, smoothing);
		img.TextureOwner = true;
		return img;
	}
	
	public override function getLocalBounds():Rectangle
	{
		return new Rectangle(Texture.OffsetX, Texture.OffsetY, Texture.Width, Texture.Height);
	}
	
	public function get width():Number
	{
		return Texture.Width * scaleX;
	}
	
	public function set width(w:Number):void
	{
		scaleX = w / Texture.Width;
	}
	
	public function get height():Number
	{
		return Texture.Height * scaleY;
	}
	
	public function set height(h:Number):void
	{
		scaleY = h / Texture.Height;
	}
}
	
}