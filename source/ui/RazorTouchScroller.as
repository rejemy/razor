package razor.ui
{

import flash.geom.Rectangle;
import flash.geom.Point;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

import razor.display.RazorStage;
import razor.display.RazorObjectContainer;
import razor.display.RazorTapTarget;
import razor.events.TouchEvent;

import omg.Time;
import omg.TimeEvent;

public class RazorTouchScroller extends RazorObjectContainer
{
	public var ViewWidth:int;
	public var ViewHeight:int;
	public var Mask:Boolean=true;
	private var TopLeft:Vector3D;
	private var BottomRight:Vector3D;
	private var Viewport:Rectangle;
	
	public var BlockerTarget:RazorTapTarget;
	public var Content:RazorObjectContainer;
	public var EventTarget:RazorTapTarget;
	
	public var ContentWidth:int;
	public var ContentHeight:int;
	
	public var ScrollVertical:Boolean=true;
	public var ScrollHorizontal:Boolean=true;
	
	private var Dragging:Boolean = false;
	private var LastX:Number;
	private var LastY:Number;
	private var LastFrameX:Number;
	private var LastFrameY:Number;
	
	private var VelocityX:Number=0;
	private var VelocityY:Number=0;
	
	public var Drag:Number = 0.8;
	public var EdgeBounce:Number = 0.5;
	
	// viewport is relative to global RazorStage coordinates
	public function RazorTouchScroller(viewWidth:int, viewHeight:int)
	{
		super();
		
		BlockerTarget = new RazorTapTarget(viewWidth, viewHeight);
		addChild(BlockerTarget);
		
		Content = new RazorObjectContainer();
		addChild(Content);
		
		EventTarget = new RazorTapTarget(viewWidth, viewHeight);
		EventTarget.stopClicks = false;
		addChild(EventTarget);
		
		ViewWidth = viewWidth;
		ViewHeight = viewHeight;
		
		TopLeft = new Vector3D(0, 0);
		BottomRight = new Vector3D(ViewWidth, ViewHeight);
		Viewport = new Rectangle();
	}
	
	public function scrollTo(posX:Number, posY:Number):void
	{
		var contentWidth:Number = Math.max(ContentWidth, ViewWidth);
		var contentHeight:Number = Math.max(ContentHeight, ViewHeight);
		
		if(posX < 0)
			posX = 0;
		else if(posX > contentWidth - ViewWidth)
			posX = contentWidth - ViewWidth;
		if(posY < 0)
			posY = 0;
		else if(posY > ContentHeight - ViewHeight)
			posY = ContentHeight - ViewHeight;
		
		if(ScrollHorizontal)
		{
			Content.x = -posX;
			VelocityX = 0;
		}
		
		if(ScrollVertical)
		{
			Content.y = -posY;
			VelocityY = 0;
		}
	}
	
	
	public override function render(modelView:Matrix3D, orientation:Number):void
	{
		if(Mask)
		{
			var topLeft:Vector3D = modelView.transformVector(TopLeft);
			var bottomRight:Vector3D = modelView.transformVector(BottomRight);
			Viewport.left = topLeft.x;
			Viewport.top = topLeft.y;
			Viewport.right = bottomRight.x;
			Viewport.bottom = bottomRight.y;
			_stage.Context.setScissorRectangle(Viewport);
		}
			
		super.render(modelView, orientation);
		
		if(Mask)
			_stage.Context.setScissorRectangle(null);
	}
	
	protected override function addedToStage():void
	{
		EventTarget.addEventListener(TouchEvent.DOWN, onMouseDown);
		EventTarget.addEventListener(TouchEvent.DRAG, onMouseDrag);
		EventTarget.addEventListener(TouchEvent.UP, onMouseUp);
		
		Time.frameListen(onFrameUpdate);
	}
	
	protected override function removedFromStage(stage:RazorStage):void
	{
		EventTarget.removeEventListener(TouchEvent.DOWN, onMouseDown);
		EventTarget.removeEventListener(TouchEvent.DRAG, onMouseDrag);
		EventTarget.removeEventListener(TouchEvent.UP, onMouseUp);
		
		Time.stopFrameListen(onFrameUpdate);
	}
	
	private function onMouseDown(e:TouchEvent):void
	{
		//var local:Point = globalToLocal(new Point(e.stageX, e.stageY));
		
		//if(e.localX < 0 || local.x > ViewWidth || local.y < 0 || local.y > ViewHeight)
		//{
		//	return;
		//}
		
		Dragging = true;
		LastX = e.localX;
		LastY = e.localY;
		//trace("Drag start");
		LastFrameX = Content.x;
		LastFrameY = Content.y;
		
		VelocityX = 0;
		VelocityY = 0;
		//trace("Touched: "+e.localX+","+e.localY);
	}
	
	private function onMouseUp(e:TouchEvent):void
	{
		Dragging = false;
	}
	
	private function onMouseDrag(e:TouchEvent):void
	{
		if(!Dragging)
			return;
		
		var dx:Number = e.localX - LastX;
		var dy:Number = e.localY - LastY;
		
		LastX = e.localX;
		LastY = e.localY;
		
		//trace("Moved: "+e.localX+","+e.localY);
		
		if(ScrollVertical)
		{
			Content.y += dy;
			//trace("Scrolling "+dy);
		}
		
		if(ScrollHorizontal)
		{
			Content.x += dx;
		}
	}
	
	private function onFrameUpdate(e:TimeEvent):void
	{
		if(Dragging)
		{
			if(ScrollHorizontal)
			{
				VelocityX = Content.x - LastFrameX;
				LastFrameX = Content.x;
			}
			
			if(ScrollVertical)
			{
				//trace("Content: "+Content.y+" - "+LastFrameY);
				VelocityY = Content.y - LastFrameY;
				LastFrameY = Content.y;
			}
			return;
		}
		
		//trace("Vel: "+VelocityY);
		
		if(ScrollHorizontal)
		{
			Content.x += VelocityX;
			VelocityX *= Drag;
			
			var contentWidth:Number = Math.max(ContentWidth, ViewWidth);
			
			var dx:Number = 0;
			if(Content.x > 0)
			{
				dx = -Content.x
			}
			else if(Content.x + contentWidth < ViewWidth)
			{
				dx = ViewWidth - (Content.x + contentWidth);
			}
			
			dx = Math.round(dx * EdgeBounce);
		
			if(dx != 0)
				Content.x += dx;
		}
		
		if(ScrollVertical)
		{
			Content.y += VelocityY;
			VelocityY *= Drag;
			
			var contentHeight:Number = Math.max(ContentHeight, ViewHeight);

			var dy:Number = 0;
			if(Content.y > 0)
			{
				dy = -Content.y
			}
			else if(Content.y + contentHeight < ViewHeight)
			{
				dy = ViewHeight - (Content.y + contentHeight);
			}
		
			dy = Math.round(dy * EdgeBounce);
		
			if(dy != 0)
				Content.y += dy;
		}
		
	}
}

}