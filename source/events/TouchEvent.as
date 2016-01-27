package razor.events
{

import flash.events.Event;

import razor.TouchInfo;

public class TouchEvent extends Event
{
	public static const MOVE:String = "RTEMove";
	public static const DRAG:String = "RTEDrag";
	public static const OVER:String = "RTEOver";
	public static const OUT:String = "RTEOut";
	public static const DOWN:String = "RTEDown";
	public static const UP:String = "RTEUp";
	public static const CLICK:String = "RTEClick";
	
	public var down:Boolean=false;
	public var localX:Number=0;
	public var localY:Number=0;
	public var stageX:Number=0;
	public var stageY:Number=0;
	
	public var CurrTouchInfo:TouchInfo;
	
	public function TouchEvent(type:String)
	{
		super(type, true, false);
	}
	
	public override function clone():Event
	{
		var e:TouchEvent = new TouchEvent(type);
		e.down = down;
		e.localX = localX;
		e.localY = localY;
		e.stageX = stageX;
		e.stageY = stageY;
		return e;
	}
	
	public override function stopPropagation():void
	{
		//if(type == DOWN)
		//	CurrTouchInfo.Down = false;
		//else if(type == DRAG)
		//	CurrTouchInfo.Drag = false;
		//else if(type == UP)
		//	CurrTouchInfo.Up = false;
	}
	
	public function setStage(stagex:Number, stagey:Number, touchInfo:TouchInfo):void
	{
		CurrTouchInfo = touchInfo;
		stageX = stagex;
		stageY = stagey;
	}

}

}