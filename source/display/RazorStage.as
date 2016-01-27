package razor.display
{

import razor.RazorProgram;
import razor.texture.RazorTexturePage;
import razor.particles.RazorParticles;
import razor.events.TouchEvent;
import razor.TouchInfo;
import razor.RazorInternal;

import flash.display.BitmapData;
import flash.display.Stage;
import flash.display.Stage3D;
import flash.display3D.Context3D;
import flash.display3D.Context3DTriangleFace;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Context3DRenderMode;
import flash.display3D.Context3DProfile;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.TouchEvent;
import flash.events.MouseEvent;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.geom.Vector3D;
import flash.utils.Dictionary;
import flash.utils.getTimer;
import flash.ui.Multitouch;
import flash.ui.MultitouchInputMode;

import omg.Console;

use namespace RazorInternal;

public class RazorStage extends RazorObjectContainer
{
	public var MainStage:Stage
	public var StageID:uint;
	public var Context:Context3D;
	
	public var ClickTimer:uint = 2000;
	public var ClickDistanceSqr:Number = 40 * 40;
	private var BackgroundRed:Number=0;
	private var BackgroundGreen:Number=0;
	private var BackgroundBlue:Number=0;
	private var BackgroundAlpha:Number=1;
	
	public var ModelView:Matrix3D;
	
	private var ViewPort:Rectangle;
	private var AntiAlias:int;
	private var DepthAndStencil:Boolean;
	
	public var AllTextures:Dictionary;
	public var AllParticles:Dictionary;
	
	private var ErrorChecking:Boolean = false;
	
	//private var SharedQuadIndexSize:uint=0;
	//public var SharedQuadIndex:IndexBuffer3D;
	
	private var AutoResize:Boolean = false;
	
	public static var Stages:Vector.<RazorStage> = new Vector.<RazorStage>(4);
	
	RazorInternal var MouseDown:razor.events.TouchEvent;
	RazorInternal var MouseMove:razor.events.TouchEvent;
	RazorInternal var MouseDrag:razor.events.TouchEvent;
	RazorInternal var MouseOver:razor.events.TouchEvent;
	RazorInternal var MouseOut:razor.events.TouchEvent;
	RazorInternal var MouseUp:razor.events.TouchEvent;
	RazorInternal var MouseClick:razor.events.TouchEvent;
	
	RazorInternal var Touches:Vector.<TouchInfo>;

	private var StageEventContainer:RazorObjectContainer;

	RazorInternal var LastHovered:Dictionary = new Dictionary();
	RazorInternal var CurrentlyHovered:Dictionary = new Dictionary();

	public function RazorStage(stage:Stage, onReady:Function, viewPort:Rectangle=null, antiAlias:int=0, depthAndStencil:Boolean=false, stageID:uint=0)
	{
		var stage3D:Stage3D = stage.stage3Ds[stageID];
		if(stage3D.context3D != null)
		{
			// already initialized
			onReady(stage3D.context3D);
			return;
		}
		
		RazorProgram.init();
		
		MainStage = stage;
		StageID = stageID;
		_stage = this;
		AntiAlias = antiAlias;
		DepthAndStencil = depthAndStencil;
		
		AllTextures = new Dictionary(true);
		AllParticles = new Dictionary(true);
		
		Stages[StageID] = this;

		if(viewPort == null)
			viewPort = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
		
		ViewPort = viewPort;
		
		stage3D.x = viewPort.x;
		stage3D.y = viewPort.y;
		
		ColorMultVector[0] = 1.0;
		ColorMultVector[1] = 1.0;
		ColorMultVector[2] = 1.0;
		ColorMultVector[3] = 1.0;
		
		ColorAddVector[0] = 0.0;
		ColorAddVector[1] = 0.0;
		ColorAddVector[2] = 0.0;
		ColorAddVector[3] = 0.0;
		
		resetModelView();
		
		StageEventContainer = new RazorObjectContainer();
		StageEventContainer.setStage(this);
		StageEventContainer.Children.push(this);
		
		var onCreate:Function = function(e:Event):void
		{

			Context = stage3D.context3D;
			Context.enableErrorChecking = ErrorChecking;
			
			Context.configureBackBuffer(viewPort.width, viewPort.height, antiAlias, depthAndStencil);
			Context.setCulling(Context3DTriangleFace.BACK);
			
			stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onCreate);
			stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextLost);
			
			onReady(Context);
		}
			
		var onError:Function = function(e:ErrorEvent):void
		{
			onReady(null);
		}
		
		MouseDown = new razor.events.TouchEvent(razor.events.TouchEvent.DOWN);
		MouseDown.down = true;
		MouseMove = new razor.events.TouchEvent(razor.events.TouchEvent.MOVE);
		MouseDrag = new razor.events.TouchEvent(razor.events.TouchEvent.DRAG);
		MouseDrag.down = true;
		MouseOver = new razor.events.TouchEvent(razor.events.TouchEvent.OVER);
		MouseOut = new razor.events.TouchEvent(razor.events.TouchEvent.OUT);
		MouseUp = new razor.events.TouchEvent(razor.events.TouchEvent.UP);
		MouseClick = new razor.events.TouchEvent(razor.events.TouchEvent.CLICK);
		
		stage3D.addEventListener(Event.CONTEXT3D_CREATE, onCreate);
		stage3D.addEventListener(ErrorEvent.ERROR, onError);
		stage3D.requestContext3D(Context3DRenderMode.AUTO, Context3DProfile.BASELINE);
		
		stage.addEventListener(Event.ENTER_FRAME, onFrame, false, 1000);
		
		Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
		
		if(Multitouch.maxTouchPoints)
		{
			stage.addEventListener(flash.events.TouchEvent.TOUCH_BEGIN, onTouchEvent);
			stage.addEventListener(flash.events.TouchEvent.TOUCH_END, onTouchEvent);
			stage.addEventListener(flash.events.TouchEvent.TOUCH_MOVE, onTouchEvent);
		}
		else
		{
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseEvent);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseEvent);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseEvent);
		}
		
		setMaxTouches(1);
	}
	
	public function setViewport(viewPort:Rectangle=null):void
	{
		if(viewPort == null)
			viewPort = new Rectangle(0, 0, MainStage.stageWidth, MainStage.stageHeight);
		
		ViewPort = viewPort;
		
		resetModelView();
		
		Context.configureBackBuffer(viewPort.width, viewPort.height, AntiAlias, DepthAndStencil);
	}
	
	public function setAutoResize(autoResize:Boolean):void
	{
		if(AutoResize == autoResize)
			return;
		
		AutoResize = autoResize;
		if(AutoResize)
		{
			MainStage.addEventListener(Event.RESIZE, onStageResize);
		}
		else
		{
			MainStage.removeEventListener(Event.RESIZE, onStageResize);
		}
	}
	
	private function onStageResize(e:Event):void
	{
		setViewport();
	}
	
	public function resetModelView():void
	{
		ModelView = new Matrix3D();
		ModelView.appendTranslation(-ViewPort.width/2, -ViewPort.height/2, 0);
		ModelView.appendScale(2.0/(ViewPort.width), -2.0/ViewPort.height, 1);
	}
	
	public function setMaxTouches(maxTouches:uint):uint
	{
		maxTouches = Math.max(maxTouches, Multitouch.maxTouchPoints);
		if(maxTouches == 0)
			maxTouches = 1;
		Touches = new Vector.<TouchInfo>(maxTouches);
		for(var i:uint=0; i<maxTouches; i++)
		{
			Touches[i] = new TouchInfo();
		}
		return maxTouches;
	}
	
	public function setErrorChecking(errorChecking:Boolean):void
	{
		ErrorChecking = errorChecking;
		Context.enableErrorChecking = ErrorChecking;
	}
	
	public function loseContext():void
	{
		Context.dispose();
	}
	
	private function onContextLost(e:Event):void
	{
		Context = MainStage.stage3Ds[StageID].context3D;
		
		Context.enableErrorChecking = ErrorChecking;
		Context.configureBackBuffer(ViewPort.width, ViewPort.height, AntiAlias, DepthAndStencil);
		Context.setCulling(Context3DTriangleFace.BACK);
		
		RazorProgram.dispose(this);
		
		var iter:Object;
		
		//if(SharedQuadIndex)
		//{
		//	SharedQuadIndex.dispose();
		//	initSharedQuadIndex();
		//}
		
		for(iter in AllTextures)
		{
			var texture:RazorTexturePage = iter as RazorTexturePage;
			texture.dispose(StageID, true);
			texture.bind(this);
		}
		
		for(iter in AllParticles)
		{
			var particles:RazorParticles = iter as RazorParticles;
			particles.dispose(StageID, true);
			particles.bind(this);
		}
		
		setStage(this, true);
	}
	
	/*
	public function setSharedQuadIndexSize(size:uint):void
	{
		if(size <= SharedQuadIndexSize)
			return;
		
		if(SharedQuadIndexSize == 0)
			SharedQuadIndexSize = 8;
		
		while(SharedQuadIndexSize < size)
			SharedQuadIndexSize *= 2;
		
		if(SharedQuadIndex)
			SharedQuadIndex.dispose();
			
		initSharedQuadIndex();
	}
	
	private function initSharedQuadIndex():void
	{
		var size:uint = 6*SharedQuadIndexSize;
		var indexData:Vector.<uint> = new Vector.<uint>(size, true);
		SharedQuadIndex = Context.createIndexBuffer(size);
		
		var v:uint = 0;
		var p:uint = 0;
		while(p<size)
		{
			
			indexData[p++] = v;
			indexData[p++] = v+1;
			indexData[p++] = v+2;
			indexData[p++] = v;
			indexData[p++] = v+2;
			indexData[p++] = v+3;
			v+=4;
		}
		
		SharedQuadIndex.uploadFromVector(indexData, 0, size);
	}
	*/
	

	
	public function onMouseEvent(e:MouseEvent):void
	{
		if(!interactive || !visible)
			return;

		var touchInfo:TouchInfo = Touches[0];
		
		var localX:Number = e.stageX - ViewPort.x;
		var localY:Number = e.stageY - ViewPort.y;
		if(localX < 0 || localX >= ViewPort.width ||
			localY < 0 || localY >= ViewPort.height)
		{
			touchInfo.Active = false;
			return;
		}
		
		touchInfo.Active = true;
		
		touchInfo.StageX = localX;
		touchInfo.StageY = localY;
		
		var pos:Vector3D = InverseLocalTransform.transformVector(new Vector3D(touchInfo.StageX, touchInfo.StageY, 0));
		
		if(e.type == MouseEvent.MOUSE_DOWN)
		{
			touchInfo.setEvent(MouseDown, pos.x, pos.y);
			touchInfo.DownTime = getTimer();
			touchInfo.DownX = pos.x;
			touchInfo.DownY = pos.y;
		}
		else if(e.type == MouseEvent.MOUSE_UP)
		{
			touchInfo.setEvent(MouseUp, pos.x, pos.y);
			if(touchInfo.DownTime > 0 && getTimer() - touchInfo.DownTime < ClickTimer)
			{
				touchInfo.ClickEvent = MouseClick;
				MouseClick.stageX = pos.x;
				MouseClick.stageY = pos.y;
			}
			touchInfo.DownTime = 0;
		}
		else if(e.type == MouseEvent.MOUSE_MOVE)
		{
			if(touchInfo.DownTime > 0)
			{
				var dx:Number = pos.x - touchInfo.DownX;
				var dy:Number = pos.y - touchInfo.DownY;
				if(dx * dx + dy * dy > ClickDistanceSqr)
				{
					touchInfo.DownTime = 0;
				}
				
			}
			
			// Don't overwrite another event with a move
			if(touchInfo.CurrEvent)
			{
				touchInfo.CurrEvent.stageX = pos.x;
				touchInfo.CurrEvent.stageY = pos.y;
			}
			else
			{
				if(e.buttonDown)
					touchInfo.setEvent(MouseDrag, pos.x, pos.y);
				else
					touchInfo.setEvent(MouseMove, pos.x, pos.y);
			}
			
		}
		else
		{
			touchInfo.setEvent(null, pos.x, pos.y);
		}
		
	}

	public function onTouchEvent(e:flash.events.TouchEvent):void
	{
		if(!interactive || !visible)
			return;

		var touchInfo:TouchInfo = Touches[0];
		
		var localX:Number = e.stageX - ViewPort.x;
		var localY:Number = e.stageY - ViewPort.y;
		if(localX < 0 || localX > ViewPort.width ||
			localY < 0 || localY > ViewPort.height)
		{
			return;
		}
		
		touchInfo.Active = true;
		
		touchInfo.StageX = localX;
		touchInfo.StageY = localY;
		
		var pos:Vector3D = InverseLocalTransform.transformVector(new Vector3D(touchInfo.StageX, touchInfo.StageY, 0));
		
		if(e.type == flash.events.TouchEvent.TOUCH_BEGIN)
		{
			touchInfo.setEvent(MouseDown, pos.x, pos.y);
			touchInfo.DownTime = getTimer();
			touchInfo.DownX = pos.x;
			touchInfo.DownY = pos.y;
		}
		else if(e.type == flash.events.TouchEvent.TOUCH_END)
		{
			touchInfo.setEvent(MouseUp, pos.x, pos.y);
			if(touchInfo.DownTime > 0 && getTimer() - touchInfo.DownTime < ClickTimer)
			{
				touchInfo.ClickEvent = MouseClick;
				MouseClick.stageX = pos.x;
				MouseClick.stageY = pos.y;
			}
			touchInfo.Deactivate = true;
			touchInfo.DownTime = 0;
		}
		else if(e.type == flash.events.TouchEvent.TOUCH_MOVE)
		{
			if(touchInfo.DownTime > 0)
			{
				var dx:Number = pos.x - touchInfo.DownX;
				var dy:Number = pos.y - touchInfo.DownY;
				if(dx * dx + dy * dy > ClickDistanceSqr)
				{
					touchInfo.DownTime = 0;
				}
				
			}
			
			// Don't overwrite another event with a move
			if(touchInfo.CurrEvent)
			{
				touchInfo.CurrEvent.stageX = pos.x;
				touchInfo.CurrEvent.stageY = pos.y;
			}
			else
			{
				touchInfo.setEvent(MouseDrag, pos.x, pos.y);
			}
			
		}
		else
		{
			touchInfo.setEvent(null, pos.x, pos.y);
		}

	}
	
	private function onFrame(e:Event):void
	{
		LastHovered = CurrentlyHovered;
		CurrentlyHovered = new Dictionary();
		
		for(var i:int=0; i<Touches.length;i++)
		{
			var touchInfo:TouchInfo = Touches[i];
			if(!touchInfo.Active)
				continue;
			
			//trace("Starting touch test")
				
			StageEventContainer.touchTest(touchInfo, touchInfo.StageX, touchInfo.StageY);
			
			touchInfo.CurrEvent = null;
			touchInfo.ClickEvent = null;
			touchInfo.Stopped = false;
			
			if(touchInfo.Deactivate)
			{
				touchInfo.Active = false;
				touchInfo.Deactivate = false;
			}

		}
		
		// Find objects no longer hovered
		for(var iter:Object in LastHovered)
		{
			// Not hovered anymore
			var child:RazorObject = iter as RazorObject;
			child._waitingMouseUp = false;
			child.dispatchEvent(_stage.MouseOut);
			
			//trace("Out "+child);
		}
		
		
	}
	
	public override function touchTest(info:TouchInfo, localX:Number, localY:Number):Boolean
	{
		super.touchTest(info, localX, localY);

		return true;
	}
	
	public override function getLocalBounds():Rectangle
	{
		return new Rectangle(0, 0, ViewPort.width, ViewPort.height);
	}
	
	public function draw():void
	{
		Context.clear(BackgroundRed, BackgroundGreen, BackgroundBlue, BackgroundAlpha);
		
		render(getTransform(ModelView), 1.0);
		
		Context.present();
	}
	
	public function setBackgroundColor(val:uint):void
	{
		BackgroundRed = ((val >> 16) & 0xff) / 255;
		BackgroundGreen = ((val >> 8) & 0xff) / 255;
		BackgroundBlue = (val & 0xff) / 255;
	}
	
	private function errorHandler(e:ErrorEvent):void
	{
		trace("Error creating context: "+e.errorID);
	}
	
	public function screenCapture():BitmapData
	{
		Context.clear(BackgroundRed, BackgroundGreen, BackgroundBlue, BackgroundAlpha);
		
		render(getTransform(ModelView), 1.0);
		
		var screenCap:BitmapData = new BitmapData(ViewPort.width, ViewPort.height, false);
		Context.drawToBitmapData(screenCap);
		
		return screenCap;
	}
}

}
