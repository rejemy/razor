package razor
{
	
import razor.display.RazorObject;
import razor.events.TouchEvent;

public class TouchInfo
{
	public var TouchID:int;

	public var StageX:Number=0;
	public var StageY:Number=0;
	public var Active:Boolean=false;
	public var Deactivate:Boolean=false;
	public var Stopped:Boolean=false;
	
	// Click tracking
	public var DownTime:uint;
	public var DownX:Number=0;
	public var DownY:Number=0;
	
	public var CurrEvent:TouchEvent;
	public var ClickEvent:TouchEvent;
	

	
	public function TouchInfo()
	{

	}
	
	public function setEvent(e:TouchEvent, stageX:Number, stageY:Number):void
	{
		CurrEvent = e;
		CurrEvent.stageX = stageX;
		CurrEvent.stageY = stageY;
	}
}

}