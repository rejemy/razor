package razor.display
{

import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.geom.Point;
import flash.geom.Rectangle;

import flash.events.IEventDispatcher;
import flash.events.EventDispatcher;
import flash.events.Event;

import razor.TouchInfo;
import razor.RazorUtils;
import razor.RazorInternal;

use namespace RazorInternal;

public class RazorObject implements IEventDispatcher
{
	RazorInternal var _x:Number=0;
	RazorInternal var _y:Number=0;
	RazorInternal var _scaleX:Number=1.0;
	RazorInternal var _scaleY:Number=1.0;
	RazorInternal var _rotation:Number=0;
	RazorInternal var _offsetX:Number=0;
	RazorInternal var _offsetY:Number=0;
	
	public var ID:String;
	protected var LocalTransformDirty:Boolean = false;
	private var LocalTransform:Matrix3D = new Matrix3D();
	public var InverseLocalTransform:Matrix3D = new Matrix3D();
	
	public var visible:Boolean = true;
	
	public var alpha:Number = 1.0;
	public var ColorMultRed:Number = 1.0;
	public var ColorMultGreen:Number = 1.0;
	public var ColorMultBlue:Number = 1.0;
	protected var TintRaw:uint;
	
	public var ColorAddAlpha:Number = 0.0
	public var ColorAddRed:Number = 0.0;
	public var ColorAddGreen:Number = 0.0;
	public var ColorAddBlue:Number = 0.0;
	protected var AddColorRaw:uint;
	
	RazorInternal var ColorMultVector:Vector.<Number> = new Vector.<Number>(4);
	RazorInternal var ColorAddVector:Vector.<Number> = new Vector.<Number>(4);
	
	protected var _stage:RazorStage;
	RazorInternal var _parent:RazorObjectContainer;
	RazorInternal var _waitingMouseUp:Boolean=false;
	
	public var interactive:Boolean = true;
	public var stopClicks:Boolean = false;
	
	private var Dispatcher:EventDispatcher;
	
	private static var IDIncrement:uint = 1;
	
	public var canRender:Boolean = true;
	
	public function RazorObject()
	{
		ID = "Object"+IDIncrement;
		IDIncrement+=1;
		TintRaw = 0xffffff;
	}
	
	internal function setStage(rstage:RazorStage, rebind:Boolean=false):void
	{
		var oldStage:RazorStage = _stage;
		
		if(_stage == rstage && !rebind)
			return;
			
		if(_stage || rebind)
			dispose(rebind);
		
		_stage = rstage;
		
		if(_stage)
			bind();
		
		if(_stage && !oldStage)
			addedToStage();
		else if(oldStage && !rebind)
			removedFromStage(oldStage);
	}
	
	protected function addedToStage():void
	{
		
	}
	
	protected function removedFromStage(stage:RazorStage):void
	{
		
	}
	
	public function bind():void
	{
		
	}
	
	
	public function dispose(rebind:Boolean=false):void
	{
		
	}
	
	public function render(modelView:Matrix3D, orientation:Number):void
	{
		
	}
	
	private function makeLocalTransforms():void
	{
		if(LocalTransformDirty)
		{
			LocalTransform.identity();
			InverseLocalTransform.identity();
			
			if(_x != 0 || _y != 0)
			{
				LocalTransform.prependTranslation(_x, _y, 0);
				InverseLocalTransform.appendTranslation(-_x, -_y, 0);
			}
			
			if(_rotation != 0)
			{
				LocalTransform.prependRotation(_rotation, Vector3D.Z_AXIS);
				InverseLocalTransform.appendRotation(-_rotation, Vector3D.Z_AXIS);
			}
			
			if(_scaleX != 1 || _scaleY != 1)
			{
				LocalTransform.prependScale(_scaleX, _scaleY, 1.0);
				InverseLocalTransform.appendScale(1/_scaleX, 1/_scaleY, 1.0);
			}
			
			if(_offsetX != 0 || _offsetY != 0)
			{
				LocalTransform.prependTranslation(-_offsetX, -_offsetY, 0);
				InverseLocalTransform.appendTranslation(_offsetX, _offsetY, 0);
			}
			
			LocalTransformDirty = false;
		}
	}
	
	public function getLocalTransform():Matrix3D
	{
		if(LocalTransformDirty)
			makeLocalTransforms();
		
		return LocalTransform;
	}
	
	public function getInverseLocalTransform():Matrix3D
	{
		if(LocalTransformDirty)
			makeLocalTransforms();
		
		return InverseLocalTransform;
	}
	
	public function getTransform(modelView:Matrix3D):Matrix3D
	{
		if(LocalTransformDirty)
			makeLocalTransforms();
		
		var tform:Matrix3D = modelView.clone();
		tform.prepend(LocalTransform);
		
		return tform;
	}
	
	public function getLocalToGlobalTransform():Matrix3D
	{
		var tform:Matrix3D = getLocalTransform().clone();
		
		var par:RazorObjectContainer = _parent;
		
		while(par)
		{
			tform.append(par.getLocalTransform());
			par = par.parent;
		}
		
		return tform;
	}
	
	public function getGlobalToLocalTransform():Matrix3D
	{
		var tform:Matrix3D = getInverseLocalTransform().clone();
		
		var par:RazorObjectContainer = _parent;
		
		while(par)
		{
			tform.prepend(par.getInverseLocalTransform());
			par = par.parent;
		}
		
		return tform;
	}
	
	public function get stage():RazorStage
	{
		return _stage;
	}
	
	public function get parent():RazorObjectContainer
	{
		return _parent;
	}
	
	public function get x():Number
	{
		return _x;
	}
	
	public function set x(val:Number):void
	{
		if(val == _x)
			return;
			
		LocalTransformDirty = true;
		_x = val;
	}
	
	public function get y():Number
	{
		return _y;
	}
	
	public function set y(val:Number):void
	{
		if(val == _y)
			return;
			
		LocalTransformDirty = true;
		_y = val;
	}
	
	public function get scaleX():Number
	{
		return _scaleX
	}
	
	public function set scaleX(val:Number):void
	{
		if(val == _scaleX)
			return;
			
		LocalTransformDirty = true;
		_scaleX = val;
		if(_scaleX == 0 || _scaleY == 0)
			canRender = false;
		else
			canRender = true;
	}
	
	public function get scaleY():Number
	{
		return _scaleY;
	}
	
	public function set scaleY(val:Number):void
	{
		if(val == _scaleY)
			return;
			
		LocalTransformDirty = true;
		_scaleY = val;
		if(_scaleX == 0 || _scaleY == 0)
			canRender = false;
		else
			canRender = true;
	}
	
	public function get offsetX():Number
	{
		return _offsetX
	}
	
	public function set offsetX(val:Number):void
	{
		if(val == _offsetX)
			return;
			
		LocalTransformDirty = true;
		_offsetX = val;
	}
	
	public function get offsetY():Number
	{
		return _offsetY;
	}
	
	public function set offsetY(val:Number):void
	{
		if(val == _offsetY)
			return;
			
		LocalTransformDirty = true;
		_offsetY = val;
	}
	
	public function get rotation():Number
	{
		return _rotation;
	}
	
	public function set rotation(val:Number):void
	{
		while(val > 180) val -= 360;
		while(val < -180) val += 360;
		
		if(val == _rotation)
			return;
			
		LocalTransformDirty = true;
		_rotation = val;
	}
	
	public function get tint():uint
	{
		return TintRaw;
	}
	
	public function set tint(val:uint):void
	{
		TintRaw = val;
		ColorMultRed = ((val >> 16) & 0xff) / 255;
		ColorMultGreen = ((val >> 8) & 0xff) / 255;
		ColorMultBlue = (val & 0xff) / 255;
	}
	
	public function set shade(val:Number):void
	{
		if(val < 0) val = 0;
		else if(val > 1.0) val = 1.0;
		
		TintRaw = uint((val * 255) << 16) | uint((val * 255) << 8) | uint(val * 255);
		
		ColorMultRed = val;
		ColorMultGreen = val;
		ColorMultBlue = val;
	}
	
	public function get highlight():uint
	{
		return AddColorRaw;
	}
	
	public function set highlight(val:uint):void
	{
		AddColorRaw = val;
		ColorAddRed = ((val >> 16) & 0xff) / 255;
		ColorAddGreen = ((val >> 8) & 0xff) / 255;
		ColorAddBlue = (val & 0xff) / 255;
	}
	
	public function touchTest(info:TouchInfo, localX:Number, localY:Number):Boolean
	{
		return false;
	}
	
	public function globalToLocal(p:Point):Point
	{
		var pos:Vector3D = new Vector3D(p.x, p.y);
		pos = recursiveGlobalToLocal(pos);
		return new Point(pos.x, pos.y);
	}
	
	private function recursiveGlobalToLocal(pos:Vector3D):Vector3D
	{
		if(parent && parent.parent)
			pos = parent.recursiveGlobalToLocal(pos);
		
		var tform:Matrix3D = getInverseLocalTransform();
		var newpos:Vector3D = tform.transformVector(pos);
		return newpos;
	}
	
	public function localToGlobal(p:Point=null):Point
	{
		var pos:Vector3D;
		if(p)
			pos = new Vector3D(p.x, p.y);
		else
			pos = new Vector3D();
		var tform:Matrix3D = getLocalTransform();
		pos = tform.transformVector(pos);
		var par:RazorObjectContainer = _parent;
		
		while(par && par.parent)
		{
			tform = par.getLocalTransform();
			pos = tform.transformVector(pos);
			par = par.parent;
		}
		
		return new Point(pos.x, pos.y);
	}
	
	public function getLocalBounds():Rectangle
	{
		return null;
	}
	
	public function getBounds(targetSpace:RazorObject):Rectangle
	{
		if(targetSpace == this)
			return getLocalBounds();
			
		var localBounds:Rectangle = getLocalBounds();
		var tform:Matrix3D = getLocalToGlobalTransform();
		tform.append(targetSpace.getGlobalToLocalTransform());
		return RazorUtils.transformRect(tform, localBounds);
	}
	
	public function clearEasers():void
	{
		this.dispatchEvent(new Event("ClearEasers"));
	}
	
	// ------ Events
	
	public function weakListen(type:String, listener:Function):void
	{
		if(!Dispatcher)
			Dispatcher = new EventDispatcher(this);
		Dispatcher.addEventListener(type, listener, false, 0, true);
	}
	
	public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void
	{
		if(!Dispatcher)
			Dispatcher = new EventDispatcher(this);
		Dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
	}
	
	public function dispatchEvent(event:Event):Boolean
	{
		if(!Dispatcher || !_stage)
			return false;
		//trace("Dispatching "+event+" stage "+_stage+" from "+ID);
		return Dispatcher.dispatchEvent(event);
	}
	
	public function hasEventListener(type:String):Boolean
	{
		if(!Dispatcher)
			return false;
			
		return Dispatcher.hasEventListener(type);
	}
	
	public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void
	{
		if(!Dispatcher)
			return;
			
		return Dispatcher.removeEventListener(type, listener, useCapture);
	}
	
	public function willTrigger(type:String):Boolean
	{
		if(!Dispatcher)
			return false;
			
		return Dispatcher.willTrigger(type);
	}
}

}