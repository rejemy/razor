package razor.display
{

import razor.TouchInfo;
import razor.events.TouchEvent;

import flash.geom.Matrix3D;
import flash.geom.Rectangle;

public class RazorTapTarget extends RazorObject
{
	private var Width:Number;
	private var Height:Number;
	
	public function RazorTapTarget(width:uint, height:uint)
	{
		setDims(width, height);
		stopClicks = true;
	}

	public function setDims(width:uint, height:uint):void
	{
		Width = width;
		Height = height;
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