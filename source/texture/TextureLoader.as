package razor.texture
{

import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.Texture;
import flash.utils.ByteArray;
import flash.utils.CompressionAlgorithm;
import flash.utils.Endian;

public class TextureLoader
{
	public var Width:uint;
	public var Height:uint;
	public var TextureFormat:String;
	
	public function bind(context:Context3D, onComplete:Function):void
	{
		var rawBytes:ByteArray = getBytes();
		
		var texture:Texture = context.createTexture(Width, Height, TextureFormat, false, 0);
		
		if(TextureFormat == Context3DTextureFormat.BGRA)
		{
			rawBytes.endian = Endian.LITTLE_ENDIAN;
			rawBytes.uncompress(CompressionAlgorithm.DEFLATE);
			texture.uploadFromByteArray(rawBytes, 0, 0);
		}
		else
		{
			texture.uploadCompressedTextureFromByteArray(rawBytes, 0, false);
		}
		
		onComplete(texture);
	}
	
	public function getBytes():ByteArray
	{
		return null;
	}
	

}
}