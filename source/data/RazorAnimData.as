package razor.data
{

import flash.utils.ByteArray;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.geom.Rectangle;

import razor.RazorLibrary;
import razor.display.RazorObject;
import razor.display.RazorStage;
import razor.display.RazorAnim;
import razor.TouchInfo;
import razor.events.TouchEvent;
import razor.RazorInternal;

use namespace RazorInternal;

public class RazorAnimData
{
	public var FrameLength:uint;
	public var FPS:Number;
	public var FrameTime:Number;
	public var RenderObjects:Vector.<RenderObjectData>;
	public var SourceLib:RazorLibrary;
	
	public var Layers:Vector.<LayerData>;
	
	private static var DefaultColorData:ObjectColorData;
	
	public function readFrom(data:ByteArray):void
	{
		if(!DefaultColorData)
			DefaultColorData = new ObjectColorData();
			
		FPS = data.readFloat();
		FrameTime = 1.0 / FPS;
		FrameLength = data.readUnsignedShort();
		var numRenderObjs:int = data.readUnsignedShort();
		RenderObjects = new Vector.<RenderObjectData>(numRenderObjs, true);
		for(var ro:uint=0; ro<numRenderObjs; ro++)
		{
			RenderObjects[ro] = RenderObjectData.readFrom(data);
		}
		var numLayers:uint = data.readUnsignedByte();
		Layers = new Vector.<LayerData>(numLayers, true);
		for(var l:uint=0; l<numLayers; l++)
		{
			var layerData:LayerData = new LayerData();
			Layers[l] = layerData;
			
			layerData.Frames = new Vector.<FrameData>(FrameLength, true);
			
			var lastTween:TweenData = null;
			
			var numKeyframes:uint = data.readUnsignedShort();
			for(var kf:uint=0; kf<numKeyframes; kf++)
			{
				var keyframeData:FrameData = new FrameData();
				
				var frameStart:uint = data.readUnsignedShort();
				var frameDuration:uint = data.readUnsignedShort();
				var frameEnd:uint = frameStart+frameDuration;
				var numFrameObjects:uint = data.readUnsignedByte();
				
				keyframeData.Keyframe = frameStart;
				keyframeData.Objects = new Vector.<ObjectKeyData>(numFrameObjects, true);
				
				for(var fo:uint=0; fo<numFrameObjects; fo++)
				{
					var objectKeyData:ObjectKeyData = new ObjectKeyData();
					objectKeyData.ObjID = data.readUnsignedShort();
					objectKeyData.X = data.readFloat();
					objectKeyData.Y = data.readFloat();
					objectKeyData.OffsetX = data.readFloat();
					objectKeyData.OffsetY = data.readFloat();
					objectKeyData.ScaleX = data.readFloat();
					objectKeyData.ScaleY = data.readFloat();
					objectKeyData.Rotation = data.readFloat();
					objectKeyData.AlphaMult = data.readFloat();
					if(data.readBoolean())
					{
						var cdata:ObjectColorData = new ObjectColorData();
						objectKeyData.ColorData = cdata;
						cdata.AlphaAdd = data.readFloat();
						cdata.RedMult = data.readFloat();
						cdata.RedAdd = data.readFloat();
						cdata.GreenMult = data.readFloat();
						cdata.GreenAdd = data.readFloat();
						cdata.BlueMult = data.readFloat();
						cdata.BlueAdd = data.readFloat();
					}
					else
					{
						objectKeyData.ColorData = DefaultColorData;
					}
					
					keyframeData.Objects[fo] = objectKeyData;
				}
				
				if(lastTween)
					lastTween.NextFrame = keyframeData;
				
				var hasTween:Boolean = data.readBoolean();
				if(hasTween)
				{
					var tween:TweenData = new TweenData();
					tween.Easing = data.readFloat();
					tween.RotationTarget = data.readFloat();
					keyframeData.Tween = tween;
					lastTween = tween;
				}
				else
				{
					lastTween = null;
				}
				
				keyframeData.Actions = RazorAnimAction.decode(data, SourceLib);
				
				for(var f:uint=frameStart; f<frameEnd; f++)
				{
					layerData.Frames[f] = keyframeData;
				}
			}
		}
	}
	
	public function getAnimLength():Number
	{
		return FrameLength * FrameTime;
	}
	
	public function setFrame(frameNumber:uint, anim:RazorAnim, force:Boolean=true):void
	{
		var instances:Vector.<RazorObject> = anim.RenderInstances;
		
		for each(var layer:LayerData in Layers)
		{
			var frameData:FrameData = layer.Frames[frameNumber];
			if(!frameData)
				continue;
			
			var child:RazorObject;
			
			if(frameData.Actions)
			{
				RazorAnimAction.trigger(frameData.Actions, anim);
			}
			
			if(frameData.Tween)
			{
				var tween:TweenData = frameData.Tween;
				var thisFrameData:ObjectKeyData = frameData.Objects[0];
				var nextFrameData:ObjectKeyData = tween.NextFrame.Objects[0];
				
				child = instances[thisFrameData.ObjID];
				
				
				var tweenTime:Number = (frameNumber - frameData.Keyframe) / (tween.NextFrame.Keyframe - frameData.Keyframe);
				var easePower:Number = tween.Easing;
				var easedTime:Number = -easePower*tweenTime*tweenTime + tweenTime*(easePower+1);
				
				//trace("Tween from "+frameData.Keyframe+" to "+tween.NextFrame.Keyframe+" now "+frameNumber+ " eased: "+easedTime)
				
				child.x = (nextFrameData.X - thisFrameData.X) * easedTime + thisFrameData.X;
				child.y = (nextFrameData.Y - thisFrameData.Y) * easedTime + thisFrameData.Y;
				child.offsetX = (nextFrameData.OffsetX - thisFrameData.OffsetX) * easedTime + thisFrameData.OffsetX;
				child.offsetY = (nextFrameData.OffsetY - thisFrameData.OffsetY) * easedTime + thisFrameData.OffsetY;
				child.scaleX = (nextFrameData.ScaleX - thisFrameData.ScaleX) * easedTime + thisFrameData.ScaleX;
				child.scaleY = (nextFrameData.ScaleY - thisFrameData.ScaleY) * easedTime + thisFrameData.ScaleY;
				child.rotation = (tween.RotationTarget - thisFrameData.Rotation) * easedTime + thisFrameData.Rotation;
				child.alpha = (nextFrameData.AlphaMult - thisFrameData.AlphaMult) * easedTime + thisFrameData.AlphaMult;
				
				var thisFrameCdata:ObjectColorData = thisFrameData.ColorData;
				var nextFrameCdata:ObjectColorData = nextFrameData.ColorData;
				
				child.ColorMultRed = (nextFrameCdata.RedMult - thisFrameCdata.RedMult) * easedTime + thisFrameCdata.RedMult;
				child.ColorMultGreen = (nextFrameCdata.GreenMult - thisFrameCdata.GreenMult) * easedTime + thisFrameCdata.GreenMult;
				child.ColorMultBlue = (nextFrameCdata.BlueMult - thisFrameCdata.BlueMult) * easedTime + thisFrameCdata.BlueMult;
				
				child.ColorAddAlpha = (nextFrameCdata.AlphaAdd - thisFrameCdata.AlphaAdd) * easedTime + thisFrameCdata.AlphaAdd;
				child.ColorAddRed = (nextFrameCdata.RedAdd - thisFrameCdata.RedAdd) * easedTime + thisFrameCdata.RedAdd;
				child.ColorAddGreen = (nextFrameCdata.GreenAdd - thisFrameCdata.GreenAdd) * easedTime + thisFrameCdata.GreenAdd;
				child.ColorAddBlue = (nextFrameCdata.BlueAdd - thisFrameCdata.BlueAdd) * easedTime + thisFrameCdata.BlueAdd;
				
				continue;
			}
			
			if(!force && frameData.Keyframe != frameNumber)
				continue;
			
			for each(var objData:ObjectKeyData in frameData.Objects)
			{
				child = instances[objData.ObjID];
				
				//trace("Putting thing at "+objData.X+","+objData.Y+" o "+objData.OffsetX+","+objData.OffsetY);
				child.x = objData.X;
				child.y = objData.Y;
				child.offsetX = objData.OffsetX;
				child.offsetY = objData.OffsetY;
				child.scaleX = objData.ScaleX;
				child.scaleY = objData.ScaleY;
				child.rotation = objData.Rotation;
				child.alpha = objData.AlphaMult;
				
				var cdata:ObjectColorData = objData.ColorData;

				child.ColorMultRed = cdata.RedMult;
				child.ColorMultGreen = cdata.GreenMult;
				child.ColorMultBlue = cdata.BlueMult;
				
				child.ColorAddAlpha = cdata.AlphaAdd;
				child.ColorAddRed = cdata.RedAdd;
				child.ColorAddGreen = cdata.GreenAdd;
				child.ColorAddBlue = cdata.BlueAdd;
				
			}
		}
	}
	
	public function render(modelView:Matrix3D, orientation:Number, frameNumber:uint, instances:Vector.<RazorObject>, colorMultVector:Vector.<Number>, colorAddVector:Vector.<Number>):void
	{
		for each(var layer:LayerData in Layers)
		{
			var frameData:FrameData = layer.Frames[frameNumber];
			if(!frameData)
				continue;
			
			for each(var objData:ObjectKeyData in frameData.Objects)
			{
				var child:RazorObject = instances[objData.ObjID];

				if(child.visible && child.canRender && child.alpha > 0)
				{
					child.ColorMultVector[0] = child.ColorMultRed * colorMultVector[0];
					child.ColorMultVector[1] = child.ColorMultGreen * colorMultVector[1];
					child.ColorMultVector[2] = child.ColorMultBlue * colorMultVector[2];
					child.ColorMultVector[3] = child.alpha * colorMultVector[3];

					child.ColorAddVector[0] = child.ColorAddRed + colorAddVector[0];
					child.ColorAddVector[1] = child.ColorAddGreen + colorAddVector[1];
					child.ColorAddVector[2] = child.ColorAddBlue + colorAddVector[2];
					child.ColorAddVector[3] = child.ColorAddAlpha + colorAddVector[3];
					
					child.render(child.getTransform(modelView), orientation);
				}
			}
		}
		
	}
	
	public function getLocalBounds(frameNumber:uint, instances:Vector.<RazorObject>):Rectangle
	{
		var bounds:Rectangle = new Rectangle();
		
		var tempVect:Vector3D = new Vector3D();
		var point:Vector3D;
		var gotBounds:Boolean = false;
		
		
		for each(var layer:LayerData in Layers)
		{
			var frameData:FrameData = layer.Frames[frameNumber];
			if(!frameData)
				continue;
			
			for each(var objData:ObjectKeyData in frameData.Objects)
			{
				var child:RazorObject = instances[objData.ObjID];
				
				include "../include/GetLocalBounds.as";
				
			}
		}
		
		if(gotBounds)
			return bounds;
			
		return null;
	}
	
	public function touchTest(info:TouchInfo, localX:Number, localY:Number, frameNumber:uint, instances:Vector.<RazorObject>, mystage:RazorStage):Boolean
	{
		var gotHit:Boolean = false;
		
		for each(var layer:LayerData in Layers)
		{
			var frameData:FrameData = layer.Frames[frameNumber];
			if(!frameData)
				continue;
			
			for each(var objData:ObjectKeyData in frameData.Objects)
			{
				var child:RazorObject = instances[objData.ObjID];
				
				include "../include/TouchTest.as";
				
			}
		}
		
		return gotHit;
	}
}

}

class LayerData
{
	public var Frames:Vector.<FrameData>;
}

class FrameData
{
	public var Keyframe:uint;
	public var Objects:Vector.<ObjectKeyData>;
	public var Tween:TweenData;
	public var Actions:Array;
}

class ObjectKeyData
{
	public var ObjID:uint;
	public var X:Number;
	public var Y:Number;
	public var OffsetX:Number;
	public var OffsetY:Number;
	public var ScaleX:Number;
	public var ScaleY:Number;
	public var Rotation:Number;
	public var AlphaMult:Number;
	public var ColorData:ObjectColorData;
}

class ObjectColorData
{
	public var AlphaAdd:Number=0.0;
	public var RedMult:Number=1.0;
	public var RedAdd:Number=0.0;
	public var GreenMult:Number=1.0;
	public var GreenAdd:Number=0.0;
	public var BlueMult:Number=1.0;
	public var BlueAdd:Number=0.0;
	
}

class TweenData
{
	public var Easing:Number;
	public var RotationTarget:Number;
	public var NextFrame:FrameData;
}