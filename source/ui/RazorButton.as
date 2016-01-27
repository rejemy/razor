package razor.ui
{

import flash.geom.Point;

import razor.display.RazorImage;
import razor.display.RazorObjectContainer;
import razor.texture.RazorTexture;
import razor.events.TouchEvent;

public class RazorButton extends RazorObjectContainer
{
	private var ButtonImage:RazorImage;
	private var NormalState:RazorTexture;
	private var DownState:RazorTexture;
	
	public var DownTint:uint = 0x999999;
	
	public var ClickHandler:Function;
	public var ClickContext:Object;
	
	public var StartedClickIn:Boolean=false;
	//public var PosAtClick:Point;
	
	public function RazorButton(label:RazorTexture, normal:RazorTexture, down:RazorTexture=null, smoothing:Boolean = true)
	{
		ButtonImage = new RazorImage(normal, smoothing);
		addChild(ButtonImage);
		
		if(label)
		{
			var labelImage:RazorImage = new RazorImage(label, smoothing);
			labelImage.x = Math.round((normal.Width - label.Width) / 2);
			labelImage.y = Math.round((normal.Height - label.Height) / 2);
			addChild(labelImage);
		}
		
		NormalState = normal;
		DownState = down;
		
		stopClicks = true;
		
		weakListen(TouchEvent.DOWN, onMouseDown);
		weakListen(TouchEvent.CLICK, onMouseClick);
		weakListen(TouchEvent.OVER, onMouseOver);
		weakListen(TouchEvent.OUT, onMouseOut);
	}
	
	private function setDownVisual(down:Boolean):void
	{
		if(down)
		{
			if(DownState)
				ButtonImage.Texture = DownState;
			else
				ButtonImage.tint = DownTint;
		}
		else
		{
			ButtonImage.Texture = NormalState;
			ButtonImage.tint = 0xffffff;
		}
	}
	
	private function onMouseDown(e:TouchEvent):void
	{
		//StartedClickIn = true
		//stage.addEventListener(TouchEvent.UP, onMouseUp);
		setDownVisual(true);
		
		//PosAtClick = localToGlobal(new Point());
	}
	
	private function onMouseUp(e:TouchEvent):void
	{
		//trace("Mouse up handler: "+stage+" on OBj "+ID);
		//StartedClickIn = false;
		//if(stage)
		//	stage.removeEventListener(TouchEvent.UP, onMouseUp);
		setDownVisual(false);
	}
	
	private function onMouseClick(e:TouchEvent):void
	{
		/*if(PosAtClick)
		{
			var pos:Point = localToGlobal(new Point());
			var dist:Number = Math.abs(pos.x - PosAtClick.x) + Math.abs(pos.y - PosAtClick.y);
			if(dist > 40)
				return;
			PosAtClick = null;
		}*/
		
		if(ClickHandler != null)
		{
			if(ClickContext)
				ClickHandler(ClickContext);
			else
				ClickHandler();
		}
		setDownVisual(false);
	}
	
	private function onMouseOver(e:TouchEvent):void
	{
		//if(StartedClickIn)
		//	setDownVisual(true);
	}
	
	private function onMouseOut(e:TouchEvent):void
	{
		setDownVisual(false);
	}
}

}