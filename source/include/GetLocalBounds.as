if(!child.visible || !child.canRender)
{
	continue;
}

var childBounds:Rectangle = child.getLocalBounds();
if(!childBounds)
	continue;

var tform:Matrix3D = child.getLocalTransform();

tempVect.x = childBounds.left;
tempVect.y = childBounds.top;
point = tform.transformVector(tempVect);

if(gotBounds)
{
	if(point.x < bounds.left)
		bounds.left = point.x;
	if(point.x > bounds.right)
		bounds.right = point.x;
	if(point.y < bounds.top)
		bounds.top = point.y;
	if(point.y > bounds.bottom)
		bounds.bottom = point.y;
}
else
{
	bounds.x = point.x;
	bounds.y = point.y;
	gotBounds = true;
}

tempVect.x = childBounds.right;
tempVect.y = childBounds.top;
point = tform.transformVector(tempVect);
if(point.x < bounds.left)
	bounds.left = point.x;
if(point.x > bounds.right)
	bounds.right = point.x;
if(point.y < bounds.top)
	bounds.top = point.y;
if(point.y > bounds.bottom)
	bounds.bottom = point.y;

tempVect.x = childBounds.right;
tempVect.y = childBounds.bottom;
point = tform.transformVector(tempVect);
if(point.x < bounds.left)
	bounds.left = point.x;
if(point.x > bounds.right)
	bounds.right = point.x;
if(point.y < bounds.top)
	bounds.top = point.y;
if(point.y > bounds.bottom)
	bounds.bottom = point.y;

tempVect.x = childBounds.left;
tempVect.y = childBounds.bottom;
point = tform.transformVector(tempVect);
if(point.x < bounds.left)
	bounds.left = point.x;
if(point.x > bounds.right)
	bounds.right = point.x;
if(point.y < bounds.top)
	bounds.top = point.y;
if(point.y > bounds.bottom)
	bounds.bottom = point.y;
