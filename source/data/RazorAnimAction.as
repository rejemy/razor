package razor.data
{

import flash.media.Sound;
import flash.utils.ByteArray;

import razor.RazorLibrary;
import razor.display.RazorAnim;

public class RazorAnimAction
{
	public static const NOOP:uint = 0;
	public static const STOP:uint = 1;
	public static const GOTO_AND_PLAY:uint = 2;
	public static const GOTO_AND_STOP:uint = 3;
	public static const PLAY_SOUND:uint = 4;
	
	public static function decode(input:ByteArray, sourceLib:RazorLibrary):Array
	{
		var len:uint = input.readUnsignedShort();
		if(len == 0)
			return null;
			
		var actions:Array = new Array(len);
		
		for(var a:uint=0; a<actions.length; )
		{
			var action:uint = input.readUnsignedShort();
			actions[a++] = action;
			
			switch(action)
			{
				case GOTO_AND_PLAY:
				case GOTO_AND_STOP:
					actions[a++] = input.readUnsignedShort();
				break;
				case PLAY_SOUND:
					actions[a++] = sourceLib.resolveResourceName(input.readUTF());
				break;
			}
			
		}
		
		return actions;
	}
	
	public static function trigger(actions:Array, anim:RazorAnim):void
	{
		for(var a:uint=0; a<actions.length; )
		{
			var action:uint = actions[a++];
			
			switch(action)
			{
				case NOOP:
				{
					break;
				}
				case STOP:
				{
					anim.stop();
					break;
				}
				case GOTO_AND_PLAY:
				{
					anim.gotoAndPlay(actions[a++]);
					break;
				}
				case GOTO_AND_STOP:
				{
					anim.gotoAndStop(actions[a++]);
					break;
				}
				case PLAY_SOUND:
				{
					var soundID:Array = actions[a++];
					var sound:Sound = RazorLibrary.getSound(soundID);
					if(sound)
						sound.play();
					break;
				}
			}
		}
	}
}

}