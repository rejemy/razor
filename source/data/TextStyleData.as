package razor.data
{

public class TextStyleData
{
	public static const NORMAL:uint = 1;
	public static const BOLD:uint = 2;
	public static const ITALIC:uint = 3;
	public static const BOLD_ITALIC:uint = 4;
	
	public var TextID:String;
	public var Width:Number;
	public var Height:Number;
	public var FontRegistryID:String;
	public var Font:String;
	public var Style:uint;
	public var Size:uint;
	public var Color:uint;
	public var Fit:uint;
	public var Align:uint;
	
	public static function getStyleString(style:uint):String
	{
		switch(style)
		{
			case NORMAL:
				return "-normal";
			case BOLD:
				return "-bold";
			case ITALIC:
				return "-italic";
			case BOLD_ITALIC:
				return "-bolditalic";
		}
		
		return "";
	}
}

}