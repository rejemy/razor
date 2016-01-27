package razor.display
{

import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.geom.Point;
import flash.geom.Rectangle;

import razor.TouchInfo;
import razor.events.TouchEvent;
import razor.RazorInternal;

use namespace RazorInternal;


public class RazorObjectContainer extends RazorObject
{
	internal var Children:Vector.<RazorObject>;
	
	
	public function RazorObjectContainer()
	{
		Children = new Vector.<RazorObject>();
	}
	
	internal override function setStage(rstage:RazorStage, rebind:Boolean=false):void
	{
		super.setStage(rstage);
		
		for each(var child:RazorObject in Children)
		{
			child.setStage(rstage, rebind);
		}
	}
	
	public override function render(modelView:Matrix3D, orientation:Number):void
	{
		orientation *= _scaleX * scaleY;
		
		for each(var child:RazorObject in Children)
		{
			if(child.visible && child.canRender && child.alpha > 0)
			{
				child.ColorMultVector[0] = child.ColorMultRed * ColorMultVector[0];
				child.ColorMultVector[1] = child.ColorMultGreen * ColorMultVector[1];
				child.ColorMultVector[2] = child.ColorMultBlue * ColorMultVector[2];
				child.ColorMultVector[3] = child.alpha * ColorMultVector[3];
				
				child.ColorAddVector[0] = child.ColorAddRed + ColorAddVector[0];
				child.ColorAddVector[1] = child.ColorAddGreen + ColorAddVector[1];
				child.ColorAddVector[2] = child.ColorAddBlue + ColorAddVector[2];
				child.ColorAddVector[3] = child.ColorAddAlpha + ColorAddVector[3];
				
				try
				{
					child.render(child.getTransform(modelView), orientation);
				}
				catch(e:Error)
				{
					trace("Excpetion rendering child: "+e.getStackTrace());
					child.canRender = false;
				}
			}
		}
	}
	
	public function get numChildren():int
	{
		return Children.length;
	}
	
	public function addChild(child:RazorObject):void
	{
		Children.push(child);
		child._parent = this;
		child.setStage(_stage);
	}
	
	public function addChildAt(child:RazorObject, index:int):void
	{
		if(child._parent)
			throw new Error("Child already has parent");
		
		if(index < 0)
			index = Children.length;
		
		if (index >= 0 && index <= Children.length)
		{
			Children.splice(index, 0, child);
			child._parent = this;
			child.setStage(_stage);
		}
		else
		{
			throw new RangeError("Invalid child index");
		}
	}

	public function adoptChild(child:RazorObject, index:int=-1):void
	{
		if(!child._parent)
		{
			addChildAt(child, index);
			return;
		}
		if(child._parent == this)
			return;
			
		var globalPos:Point = child.localToGlobal();
		var local:Point = globalToLocal(globalPos);
		child.x = local.x;
		child.y = local.y;
		
		child._parent.removeChild(child);
		
		addChildAt(child, index);
	}

	public function removeChild(child:RazorObject):void
	{
		var childIndex:int = getChildIndex(child);
		if(childIndex != -1)
			removeChildAt(childIndex);
		else
			throw new Error("Not a child of this object");
	}
	

	public function removeChildAt(index:int):void
	{
		if (index >= 0 && index < Children.length)
		{
			var child:RazorObject = Children[index];
			Children.splice(index, 1);
			child._parent = null;
			child.setStage(null);
		}
		else
		{
			throw new RangeError("Invalid child index");
		}
	}
	
	public function removeChildren():void
	{
		for each(var child:RazorObject in Children)
		{
			child._parent = null;
			child.setStage(null);
		}
		
		Children = new Vector.<RazorObject>();
	}
	

	public function getChildAt(index:int):RazorObject
	{
		if (index >= 0 && index < Children.length)
			return Children[index];
		else
			throw new RangeError("Invalid child index");
	}
	
	public function getChildIndex(child:RazorObject):int
	{
		return Children.indexOf(child);
	}
	
	public function setChildIndex(child:RazorObject, index:int):void
	{
		var oldIndex:int = getChildIndex(child);
		if (oldIndex == -1)
			throw new ArgumentError("Not a child of this container");
		Children.splice(oldIndex, 1);
		Children.splice(index, 0, child);
	}
	
	/** Swaps the indexes of two children. */
	public function swapChildren(child1:RazorObject, child2:RazorObject):void
	{
		var index1:int = getChildIndex(child1);
		var index2:int = getChildIndex(child2);
		if (index1 == -1 || index2 == -1)
			throw new ArgumentError("Not a child of this container");
		swapChildrenAt(index1, index2);
	}
	
	/** Swaps the indexes of two children. */
	public function swapChildrenAt(index1:int, index2:int):void
	{
		var child1:RazorObject = getChildAt(index1);
		var child2:RazorObject = getChildAt(index2);
		Children[index1] = child2;
		Children[index2] = child1;
	}
	
	public function findChild(id:String):RazorObject
	{
		if(id == ID)
		{
			return this;
		}
		
		for each(var child:RazorObject in Children)
		{
			var container:RazorObjectContainer = child as RazorObjectContainer;
			if(container)
			{
				var found:RazorObject = container.findChild(id);
				if(found)
				{
					return found;
				}
			}
			else if(child.ID == id)
			{
				return child;
			}
			
		}
		
		return null;
	}
	
	public override function touchTest(info:TouchInfo, localX:Number, localY:Number):Boolean
	{
		
		var gotHit:Boolean = false;
		
		//trace("Touch testing "+this+" at "+localX+","+localY)
		var mystage:RazorStage = _stage;
		
		for(var i:int = Children.length-1; i>=0; i--)
		{
			var child:RazorObject = Children[i];
			
			include "../include/TouchTest.as";
			
		}
		
		return gotHit;
	}
	
	public override function getLocalBounds():Rectangle
	{
		if(Children.length == 0)
			return null;
			
		var bounds:Rectangle = new Rectangle();
		
		var tempVect:Vector3D = new Vector3D();
		var point:Vector3D;
		var gotBounds:Boolean = false;
		
		for each(var child:RazorObject in Children)
		{
			include "../include/GetLocalBounds.as";
		}
		
		if(gotBounds)
			return bounds;
			
		return null;
	}
}

}