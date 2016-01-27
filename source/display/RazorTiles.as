package razor.display
{

import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.geom.Point;
import flash.geom.Rectangle;

import razor.TouchInfo;
import razor.events.TouchEvent;
import razor.RazorInternal;
import razor.texture.RazorTexture;
import razor.texture.RazorTexturePage;

use namespace RazorInternal;


public class RazorTiles extends RazorObject
{
	private var TexturePage:RazorTexturePage;
	private var TextureBinding:RazorTextureBinding;
	private var Program:Program3D;
	
	public var ViewWidth:Number;
	public var ViewHeight:Number;
	
	private var Tilemap:Vector.<RazorTexture>;
	private var TilemapWidth:int;
	private var TilemapHeight:int;
	
	public function RazorTiles(viewWidth:Number, viewHeight:Number, tilemap:Vector.<RazorTexture>, tilemapWidth:int, tilemapHeight:int)
	{
		ViewWidth = viewWidth;
		ViewHeight = viewHeight;
		
		setTilemap(tilemap, tilemapWidth, tilemapHeight);
	}
	
	public function setTilemap(tilemap:Vector.<RazorTexture>, tilemapWidth:int, tilemapHeight:int):void
	{
		TexturePage = tilemap[0].Page;
		Tilemap = tilemap;
		TilemapWidth = tilemapWidth;
		TilemapHeight = tilemapHeight;
	}
	
	public override function bind():void
	{
		var context:Context3D = _stage.Context;
		
		TextureBinding = TexturePage.bind(_stage);
		
		pickProgram();
		
	}
	
	private function pickProgram():void
	{
		if(ColorMultVector[0] == 1.0 && ColorMultVector[1] == 1.0 && ColorMultVector[2] == 1.0 && ColorMultVector[3] == 1.0)
		{
			if(ColorAddVector[0] == 0.0 && ColorAddVector[1] == 0.0 && ColorAddVector[2] == 0.0 && ColorAddVector[3] == 0.0)
				Program = RazorProgram.getTextured(_stage);
			else
				Program = RazorProgram.getTexturedAdd(_stage);
		}
		else
		{
			if(ColorAddVector[0] == 0.0 && ColorAddVector[1] == 0.0 && ColorAddVector[2] == 0.0 && ColorAddVector[3] == 0.0)
				Program = RazorProgram.getTexturedMult(_stage);
			else
				Program = RazorProgram.getTexturedMultAdd(_stage);
		}
	}
	
	
}

}