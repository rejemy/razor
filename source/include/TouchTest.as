// Filter out inelligable children
if(!child.interactive || !child.visible || !child.canRender)
{
	continue;
}

// Get into child local space
var pos:Vector3D = child.InverseLocalTransform.transformVector(new Vector3D(localX, localY, 0));
var childX:Number = pos.x;
var childY:Number = pos.y;

var hit:Boolean = child.touchTest(info, childX, childY);
//trace("Child "+child+" hit: "+hit);

if(!mystage || info.Stopped)
	return gotHit;
	
if(hit)
{
	gotHit = true;
	
	mystage.CurrentlyHovered[child] = true;
	if(!mystage.LastHovered[child] && child.visible && child.stage)
	{
		// Newly hovered object
		//trace("Over "+child);
		child.dispatchEvent(mystage.MouseOver);
	}
	else
	{
		// Delete any currently hovered object from last hovered
		// so that only non-hovered objects will be left in it
		delete mystage.LastHovered[child];
	}
	
	if(info.CurrEvent && child.visible && child.stage)
	{
		info.CurrEvent.localX = childX;
		info.CurrEvent.localY = childY;
		child.dispatchEvent(info.CurrEvent);
		
		//trace(""+child+" dispatching "+info.CurrEvent.type);
		
		if(info.CurrEvent == mystage.MouseDown)
		{
			child._waitingMouseUp = true;
		}
		
		if(info.ClickEvent && child._waitingMouseUp && child.visible && child.stage)
		{
			info.ClickEvent.localX = childX;
			info.ClickEvent.localY = childY;
			child.dispatchEvent(info.ClickEvent);
			child._waitingMouseUp = false;
			
			//trace(""+child+" dispatching "+info.ClickEvent.type);
		}
	}
	

	if(child.stopClicks)
	{
		info.Stopped = true;
		break;
	}

}