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
import flash.events.MouseEvent;

import razor.display.RazorObject;
import razor.RazorProgram;
import razor.texture.RazorTexture;
import razor.TouchInfo;
import razor.RazorInternal;

use namespace RazorInternal;



public class RazorLine extends RazorObject
{
	// Can be bound directly, since it's not shared between contexts
	private var Program:Program3D;
	private var VertBuffer:VertexBuffer3D;
	private var IndexBuffer:IndexBuffer3D;
	
	private var Bounds:Rectangle;
	
	private var Red:Number;
	private var Green:Number;
	private var Blue:Number;
	public var Width:Number = 1;
	
	private var MaxPoints:uint;
	private var NumPoints:uint;
	
	private var Points:Vector.<Number>;
	private var VertsInitted:Boolean = false;
	
	private var LastX:Number=NaN;
	private var LastY:Number=NaN;
	
	public function RazorLine(maxpoints:uint, width:Number, color:uint)
	{
		this.color = color;
		interactive = false;
		
		MaxPoints = maxpoints;
		Width = width / 2;
		
		if(MaxPoints < 2)
			MaxPoints = 2;
		
		Bounds = new Rectangle();
		Bounds.left = Infinity;
		Bounds.top = Infinity;
		Bounds.right = -Infinity;
		Bounds.bottom = -Infinity;
			
		NumPoints = 0;
		Points = new Vector.<Number>(MaxPoints*2);
	}
	
	public function set color(color:uint):void
	{
		Red = Number(color >> 16 & 0xff) / 255.0;
		Green = Number(color >> 8 & 0xff) / 255.0;
		Blue = Number(color & 0xff) / 255.0;
	}
	
	public override function bind():void
	{
		var context:Context3D = _stage.Context;
		
		Program = RazorProgram.getSolidColor(_stage);
		
		VertBuffer = context.createVertexBuffer(MaxPoints*2, 2);
		
		IndexBuffer = context.createIndexBuffer((MaxPoints-1)*6);
		
		var indexData:Vector.<uint> = new Vector.<uint>((MaxPoints-1)*6);
		var p:uint=0;
		for(var i:int=0; i<MaxPoints-1; i++)
		{
			indexData[p++] = i*2;
			indexData[p++] = i*2+3;
			indexData[p++] = i*2+1;
			indexData[p++] = i*2;
			indexData[p++] = i*2+2;
			indexData[p++] = i*2+3;
		}
		
		IndexBuffer.uploadFromVector(indexData, 0, (MaxPoints-1)*6);
		
		uploadVerts();
	}
	
	private function uploadVerts():void
	{
		if(NumPoints < 2 || !VertBuffer)
			return;
		
		var vertData:Vector.<Number>;
		
		if(VertsInitted)
			vertData = new Vector.<Number>(NumPoints*2*2);
		else
			vertData = new Vector.<Number>(MaxPoints*2*2);
			
		var v:uint=0;
		var lastBodyPoint:uint = NumPoints-1;
		var pIndex:uint;
		
		var dx:Number;
		var dy:Number;
		var len:Number;
		
		dx = Points[0] - Points[2];
		dy = Points[1] - Points[3];
		
		len = Math.sqrt(dx*dx + dy * dy);
		dx = dx / len * Width;
		dy = dy / len * Width;
		
		vertData[v++] = Points[0] - dy;
		vertData[v++] = Points[1] + dx;
		
		vertData[v++] = Points[0] + dy;
		vertData[v++] = Points[1] - dx;
		
		for(var p:uint=1; p<lastBodyPoint; p++)
		{
			pIndex = p*2;
			dx = Points[pIndex-2] - Points[pIndex+2];
			dy = Points[pIndex-1] - Points[pIndex+3];
			
			len = Math.sqrt(dx*dx + dy * dy);
			dx = dx / len * Width;
			dy = dy / len * Width;
			
			vertData[v++] = Points[pIndex] - dy;
			vertData[v++] = Points[pIndex+1] + dx;

			vertData[v++] = Points[pIndex] + dy;
			vertData[v++] = Points[pIndex+1] - dx;
		}
		
		pIndex = p*2;
		dx = Points[pIndex-2] - Points[pIndex];
		dy = Points[pIndex-1] - Points[pIndex+1];
		
		len = Math.sqrt(dx*dx + dy * dy);
		dx = dx / len * Width;
		dy = dy / len * Width;
		
		vertData[v++] = Points[pIndex] - dy;
		vertData[v++] = Points[pIndex+1] + dx;
		
		vertData[v++] = Points[pIndex] + dy;
		vertData[v++] = Points[pIndex+1] - dx;
		
		if(VertsInitted)
		{
			VertBuffer.uploadFromVector(vertData, 0, NumPoints*2);
		}
		else
		{
			while(v < vertData.length)
			{
				vertData[v++] = 0;
			}
		
			VertBuffer.uploadFromVector(vertData, 0, MaxPoints*2);
			VertsInitted = true;
		}
		
		
	}
	
	
	public function clear():void
	{
		Points.length = 0;
		NumPoints = 0;
		Bounds.left = Infinity;
		Bounds.top = Infinity;
		Bounds.right = -Infinity;
		Bounds.bottom = -Infinity;
	}
	
	public function get numPoints():uint
	{
		return NumPoints;
	}
	
	public function get maxPoints():uint
	{
		return MaxPoints;
	}
	
	public function addPoint(px:Number, py:Number):Boolean
	{
		if(NumPoints == MaxPoints)
			return false;
		
		if(LastX == px && LastY == py)
			return false;
		
		if(px < Bounds.left)
			Bounds.left = px;
		if(px > Bounds.right)
			Bounds.right = px;
		if(py < Bounds.top)
			Bounds.top = py;
		if(py > Bounds.bottom)
			Bounds.bottom = py;
				
		LastX = px;
		LastY = py;
		
		Points[NumPoints*2] = px;
		Points[NumPoints*2+1] = py;
		
		NumPoints += 1;
		
		//uploadVerts();
		
		if(VertBuffer)
		{
			if(NumPoints <= 2)
			{
				uploadVerts();
				return true;
			}
			
			var vertData:Vector.<Number> = new Vector.<Number>(4*2);
			
			var v:uint=0;
			var pIndex:uint;

			var dx:Number;
			var dy:Number;
			var len:Number;
			
			pIndex = (NumPoints-2)*2;
			dx = Points[pIndex-2] - Points[pIndex+2];
			dy = Points[pIndex-1] - Points[pIndex+3];
			
			len = Math.sqrt(dx*dx + dy * dy);
			dx = dx / len * Width;
			dy = dy / len * Width;
			
			vertData[v++] = Points[pIndex] - dy;
			vertData[v++] = Points[pIndex+1] + dx;

			vertData[v++] = Points[pIndex] + dy;
			vertData[v++] = Points[pIndex+1] - dx;
			
			pIndex = (NumPoints-1)*2;
			dx = Points[pIndex-2] - Points[pIndex];
			dy = Points[pIndex-1] - Points[pIndex+1];

			len = Math.sqrt(dx*dx + dy * dy);
			dx = dx / len * Width;
			dy = dy / len * Width;

			vertData[v++] = Points[pIndex] - dy;
			vertData[v++] = Points[pIndex+1] + dx;

			vertData[v++] = Points[pIndex] + dy;
			vertData[v++] = Points[pIndex+1] - dx;
			
			VertBuffer.uploadFromVector(vertData, (NumPoints-2)*2, 4);
		}
		
		return true;
	}
	
	public override function dispose(rebind:Boolean=false):void
	{
		VertsInitted = false;
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
		if(NumPoints < 2)
			return;
			
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

		context.drawTriangles(IndexBuffer, 0, (NumPoints-1)*2);
	}
	
	public override function getLocalBounds():Rectangle
	{
		if(NumPoints)
			return Bounds.clone();
		return null;
	}
}
	
}