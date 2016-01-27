package razor.texture
{
	
import flash.display3D.Context3D;
import flash.display3D.textures.Texture;
import flash.display3D.Context3DTextureFormat;
import flash.utils.ByteArray;
import flash.utils.CompressionAlgorithm;

import omg.Console;

public class MemoryTextureLoader extends TextureLoader
{
	public var SourceBytes:ByteArray;
	public var SourceOffset:uint;
	public var SourceLength:uint;
	
	public function MemoryTextureLoader(bytes:ByteArray, offset:uint, length:uint, width:uint, height:uint, format:String)
	{
		SourceBytes = bytes;
		SourceOffset = offset;
		SourceLength = length;
		Width = width;
		Height = height;
		TextureFormat = format;
	}
	
	public override function getBytes():ByteArray
	{
		var rawBytes:ByteArray = new ByteArray();
		
		Console.info("Getting "+SourceLength+" bytes from memory array at offset: "+SourceOffset+" total len: "+SourceBytes.length);
		
		SourceBytes.position = SourceOffset;
		SourceBytes.readBytes(rawBytes, 0, SourceLength);
		
		return rawBytes;
	}
	
}
}