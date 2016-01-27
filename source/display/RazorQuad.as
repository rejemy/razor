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
import flash.display3D.textures.Texture;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;

import razor.RazorProgram;
import razor.texture.RazorTexture;
import razor.TouchInfo;
import razor.events.TouchEvent;
import razor.RazorInternal;

use namespace RazorInternal;



public class RazorQuad extends RazorObject
{
	// Can be bound directly, since it's not shared between contexts
	private var Program:Program3D;
	private var VertBuffer:VertexBuffer3D;
	private var IndexBuffer:IndexBuffer3D;
	
	private var Red:Number;
	private var Green:Number;
	private var Blue:Number;
	private var Width:Number;
	private var Height:Number;
	
	internal var VertCoords:Vector.<Number>;
	
	public function RazorQuad(width:uint, height:uint, color:uint)
	{
		Width = width;
		Height = height;
		
		VertCoords = new Vector.<Number>(12);
		VertCoords[0] = 0; VertCoords[1] = 0; VertCoords[2] = 0;
		VertCoords[3] = Width; VertCoords[4] = 0; VertCoords[5] = 0;
		VertCoords[6] = Width; VertCoords[7] = Height; VertCoords[8] = 0;
		VertCoords[9] = 0; VertCoords[10] = Height; VertCoords[11] = 0;
		
		this.color = color;
	}
	
	public function set color(color:uint):void
	{
		Red = Number(color >> 16 & 0xff) / 255.0;
		Green = Number(color >> 8 & 0xff) / 255.0;
		Blue = Number(color & 0xff) / 255.0;
	}
	
	public function setSize(width:Number, height:Number):void
	{
		if(Width == width && Height == height)
			return;

		Width = width;
		Height = height;

		dispose();
		if(_stage)
			bind();
	}

	public override function bind():void
	{
		if(VertBuffer)
			return;

		var context:Context3D = _stage.Context;
		
		Program = RazorProgram.getSolidColor(_stage);
		
		VertBuffer = context.createVertexBuffer(4, 2);
		var vertData:Vector.<Number> = new Vector.<Number>(4*2);
		vertData[0] = 0; vertData[1] = 0;
		
		vertData[2] = Width; vertData[3] = 0;
		
		vertData[4] = Width; vertData[5] = Height;
		
		vertData[6] = 0; vertData[7] = Height;
		
		VertBuffer.uploadFromVector(vertData, 0, 4);
		
		IndexBuffer = context.createIndexBuffer(6);
		var indexData:Vector.<uint> = new Vector.<uint>(6);
		indexData[0] = 0;
		indexData[1] = 1;
		indexData[2] = 2;
		indexData[3] = 0;
		indexData[4] = 2;
		indexData[5] = 3;
		IndexBuffer.uploadFromVector(indexData, 0, 6);
		
		//_stage.setSharedQuadIndexSize(1);
	}
	
	public override function dispose(rebind:Boolean=false):void
	{
		if(VertBuffer)
		{
			VertBuffer.dispose();
			VertBuffer = null;
		}
		if(IndexBuffer)
		{
			IndexBuffer.dispose();
			IndexBuffer = null;
		}
	}
	
	public override function render(modelView:Matrix3D, orientation:Number):void
	{
		var context:Context3D = _stage.Context;
		
		var combinedAlpha:Number = ColorMultVector[3] + ColorAddVector[3];
		
		if(combinedAlpha != 1.0)
			context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
		else
			context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
		
		if(orientation * _scaleX * _scaleY > 0)
			context.setCulling(Context3DTriangleFace.BACK);
		else
			context.setCulling(Context3DTriangleFace.FRONT);
		
		ColorMultVector[0] = (ColorMultVector[0] * Red + ColorAddVector[0]) * combinedAlpha;
		ColorMultVector[1] = (ColorMultVector[1] * Green + ColorAddVector[1]) * combinedAlpha;
		ColorMultVector[2] = (ColorMultVector[2] * Blue + ColorAddVector[2]) * combinedAlpha;
		
		context.setTextureAt(0, null);
		context.setProgram(Program);
		context.setVertexBufferAt(0, VertBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
		context.setVertexBufferAt(1, null);
		context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, modelView, true);
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, ColorMultVector, 1);
		
		context.drawTriangles(IndexBuffer, 0, 2);
	}
	
	public override function touchTest(info:TouchInfo, localX:Number, localY:Number):Boolean
	{
		if(localX < 0 || localX >= Width ||
			localY < 0 || localY >= Height)
			return false;
		
		return true;
	}
	
	public override function getLocalBounds():Rectangle
	{
		return new Rectangle(0, 0, Width, Height);
	}
}
	
}