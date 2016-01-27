package razor.texture
{
	
import flash.filesystem.File;
import flash.filesystem.FileStream;
import flash.filesystem.FileMode;
import flash.display3D.Context3D;
import flash.display3D.textures.Texture;
import flash.display3D.Context3DTextureFormat;
import flash.utils.ByteArray;
import flash.utils.CompressionAlgorithm;

public class FileTextureLoader extends TextureLoader
{
	public var SourceFile:File;
	public var SourceOffset:uint;
	public var SourceLength:uint;
	
	
	public function FileTextureLoader(file:File, offset:uint, length:uint, width:uint, height:uint, format:String)
	{
		SourceFile = file;
		SourceOffset = offset;
		SourceLength = length;
		Width = width;
		Height = height;
		TextureFormat = format;
	}
	
	public override function getBytes():ByteArray
	{
		var rawBytes:ByteArray = new ByteArray();
		
		var fileStream:FileStream = new FileStream();
		fileStream.open(SourceFile, FileMode.READ);
		fileStream.position = SourceOffset;
		fileStream.readBytes(rawBytes, 0, SourceLength);
		fileStream.close();
		
		return rawBytes;
	}
	
}
}