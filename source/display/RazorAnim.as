package razor.display
{

import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.utils.Dictionary;

import omg.Time;
import omg.TimeEvent;

import razor.data.RazorAnimData;
import razor.data.RenderObjectData;
import razor.TouchInfo;
import razor.RazorInternal;



use namespace RazorInternal;

public class RazorAnim extends RazorObjectContainer
{
	public var Insts:Dictionary;
	private var Data:RazorAnimData;
	private var Timer:Time;

	RazorInternal var RenderInstances:Vector.<RazorObject>;
	private var CurrFrame:uint=0;
	private var CurrTime:Number=0;
	private var Playing:Boolean=true;
	
	public function RazorAnim(data:RazorAnimData, timer:Time=null)
	{
		Insts = new Dictionary();
		Data = data;
		RenderInstances = new Vector.<RazorObject>(Data.RenderObjects.length);
		
		Timer = timer ? timer : Time.Singleton;

		for(var r:uint=0; r<RenderInstances.length; r++)
		{
			var renderObjData:RenderObjectData = Data.RenderObjects[r];
			var inst:RazorObject = renderObjData.instantiate(Data.SourceLib);
			inst._parent = this;
			RenderInstances[r] = inst;
			if(renderObjData.Name)
				Insts[renderObjData.Name] = inst;
		
		}
		
		Data.setFrame(CurrFrame, this);
	}
	
	public function getData():RazorAnimData
	{
		return Data;
	}
	
	internal override function setStage(rstage:RazorStage, rebind:Boolean=false):void
	{
		super.setStage(rstage);
		
		for each(var child:RazorObject in RenderInstances)
		{
			child.setStage(rstage, rebind);
		}
	}
	
	protected override function addedToStage():void
	{
		if(Data.FrameLength <= 1)
			return;
		Timer.frameListen(update);
	}
	
	protected override function removedFromStage(stage:RazorStage):void
	{
		if(Data.FrameLength <= 1)
			return;
		Timer.stopFrameListen(update);
	}
	
	public override function render(modelView:Matrix3D, orientation:Number):void
	{
		orientation *= _scaleX * scaleY;
		
		Data.render(modelView, orientation, CurrFrame, RenderInstances, ColorMultVector, ColorAddVector);
	}
	
	public override function getLocalBounds():Rectangle
	{
		return Data.getLocalBounds(CurrFrame, RenderInstances);
	}
	
	public override function touchTest(info:TouchInfo, localX:Number, localY:Number):Boolean
	{
		return Data.touchTest(info, localX, localY, CurrFrame, RenderInstances, _stage);
	}
	
	public function getNumChildren():int
	{
		return RenderInstances.length;
	}
	
	public function getChild(i:int):RazorObject
	{
		return RenderInstances[i];
	}
	
	public function update(e:TimeEvent):void
	{
		if(!Playing)
			return;
			
		CurrTime += e.UpdateDelta;
		while(CurrTime >= Data.FrameTime)
		{
			CurrFrame += 1;
			CurrTime -= Data.FrameTime;
			if(CurrFrame == Data.FrameLength)
				CurrFrame = 0;
			
			Data.setFrame(CurrFrame, this, false);
		}
	}
	
	public function play():void
	{
		Playing = true;
	}
	
	public function stop():void
	{
		Playing = false;
	}
	
	public function stopAll():void
	{
		Playing = false;
		
		for each(var child:RazorObject in RenderInstances)
		{
			var anim:RazorAnim = child as RazorAnim;
			if(anim)
				anim.stopAll();
		}
	}
	
	public function gotoAndPlay(frame:uint):void
	{
		Playing = true;
		
		if(frame >= Data.FrameLength)
			frame = Data.FrameLength-1;
		
		CurrFrame = frame;
		CurrTime = CurrFrame*Data.FrameTime;
		
		Data.setFrame(CurrFrame, this);
	}
	
	public function gotoAndStop(frame:uint):void
	{
		Playing = false;
		
		if(frame >= Data.FrameLength)
			frame = Data.FrameLength-1;
		
		CurrFrame = frame;
		CurrTime = CurrFrame*Data.FrameTime;
		
		Data.setFrame(CurrFrame, this);
	}
	
	public function getAnimLength():Number
	{
		return Data.getAnimLength();
	}
	
	public function setTime(time:Number):void
	{
		CurrTime = time % Data.getAnimLength();
		
		CurrFrame = CurrTime / Data.FrameTime;
		
		if(CurrFrame >= Data.FrameLength)
			CurrFrame = Data.FrameLength-1;
		
		Data.setFrame(CurrFrame, this);
	}

	public override function addChild(child:RazorObject):void
	{
		throw new Error("Not supported on RazorAnim");
	}
	
	public override function addChildAt(child:RazorObject, index:int):void
	{
		throw new Error("Not supported on RazorAnim");
	}

	public override function adoptChild(child:RazorObject, index:int=-1):void
	{
		throw new Error("Not supported on RazorAnim");
	}

	public override function removeChild(child:RazorObject):void
	{
		throw new Error("Not supported on RazorAnim");
	}

	public override function removeChildAt(index:int):void
	{
		throw new Error("Not supported on RazorAnim");
	}
	
	public override function removeChildren():void
	{
		throw new Error("Not supported on RazorAnim");
	}
	
	public override function getChildAt(index:int):RazorObject
	{
		throw new Error("Not supported on RazorAnim");
	}
	
	public override function getChildIndex(child:RazorObject):int
	{
		throw new Error("Not supported on RazorAnim");
	}
	
	public override function setChildIndex(child:RazorObject, index:int):void
	{
		throw new Error("Not supported on RazorAnim");
	}
	
	/** Swaps the indexes of two children. */
	public override function swapChildren(child1:RazorObject, child2:RazorObject):void
	{
		throw new Error("Not supported on RazorAnim");
	}
	
	/** Swaps the indexes of two children. */
	public override function swapChildrenAt(index1:int, index2:int):void
	{
		throw new Error("Not supported on RazorAnim");
	}
	
	public override function findChild(id:String):RazorObject
	{
		throw new Error("Not supported on RazorAnim");
	}
}

}