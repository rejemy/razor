package razor.display
{

import flash.display.Sprite;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormatAlign;
import flash.text.TextFormat;

import razor.RazorInternal;

use namespace RazorInternal;

public class RazorNativeText extends RazorBaseText
{
	protected var NativeFormat:TextFormat;
	protected var NativeTextField:TextField;
	protected var TextHolder:Sprite;
	protected var TextAdjuster:Sprite;
	
	private var TextImage:RazorImage;
	private var Bold:Boolean;
	private var Italic:Boolean;
	private var FontName:String;
	
	public function RazorNativeText(fontName:String, fontSize:int, text:String=null, smoothing:Boolean=true, bold:Boolean=false, italic:Boolean=false)
	{
		super(null, text, smoothing);
		
		Bold = bold;
		Italic = italic;
		FontName = fontName;
		FontSize = fontSize;
		
		NativeFormat = new TextFormat();
		NativeTextField = new TextField();
		NativeTextField.embedFonts = false;
		
		TextHolder = new Sprite();
		TextAdjuster = new Sprite();
		TextHolder.addChild(TextAdjuster);
		TextAdjuster.addChild(NativeTextField);
		//NativeTextField.x = -2;
		//NativeTextField.y = -2;
		
	}
	
	public override function set fontSize(size:uint):void
	{
		if(size == 0)
			return;
			
		FontSize = size;
		
		NeedsReflow = true;
		dispose();
	}
	
	protected override function flowText():void
	{
		// Do nothing
	}
	
	public override function setMaxWidth(width:Number):void
	{
		if(width == MaxWidth)
			return;
			
		MaxWidth = width;
		
		dispose();
	}
	
	public override function setMaxHeight(height:Number):void
	{
		if(height == MaxHeight)
			return;
		
		MaxHeight = height;
		
		dispose();
	}
	
	public override function setFit(fit:uint):void
	{
		if(fit == Fit)
			return;
		
		Fit = fit;
		
		dispose();
	}
	
	public override function set color(val:uint):void
	{
		TextColor = val;
		
		dispose();
	}
	
	internal override function setStage(rstage:RazorStage, rebind:Boolean=false):void
	{
		super.setStage(rstage);
		
		if(TextImage)
			TextImage.setStage(rstage, rebind);
	}
	
	public override function bind():void
	{
		switch(HAlign)
		{
			case LEFT:
				NativeFormat.align = TextFormatAlign.LEFT;
				break;
			case CENTER:
				NativeFormat.align = TextFormatAlign.CENTER;
				break;
			case RIGHT:
				NativeFormat.align = TextFormatAlign.RIGHT;
				break;
		}
		
		NativeFormat.bold = Bold;
		NativeFormat.color = TextColor;
		NativeFormat.font = FontName;
		NativeFormat.italic = Italic;
		NativeFormat.size = FontSize;
		
		NativeTextField.defaultTextFormat = NativeFormat;
		NativeTextField.text = Text;
		NativeTextField.setTextFormat(NativeFormat);
		NativeTextField.multiline = true;
		//NativeTextField.background = true;
		//NativeTextField.backgroundColor = 0xffffff;
		
		var bounds:Rectangle = new Rectangle();
		var boxWidth:Number;
		
		if(Fit == WRAP && MaxWidth > 0)
		{
			NativeTextField.autoSize = TextFieldAutoSize.NONE;
			NativeTextField.width = MaxWidth;
			NativeTextField.wordWrap = true;
			
			if(MaxHeight > 0)
			{
				NativeTextField.height = MaxHeight;
			}
			else
			{
				NativeTextField.height = NativeTextField.textHeight;
			}
			
			boxWidth = MaxWidth;
		}
		else
		{
			NativeTextField.autoSize = TextFieldAutoSize.LEFT;
			NativeTextField.wordWrap = false;
			
			boxWidth = NativeTextField.textWidth+4;
		}
		
		var textWidth:Number = NativeTextField.textWidth+4;
		var textHeight:Number = NativeTextField.textHeight+4;
		
		
		//trace("Text: "+textWidth+"x"+textHeight);
		//trace("HScroll: "+NativeTextField.maxScrollH)
		if(Fit == SCALE)
		{
			var tscale:Number = 1.0;
			if(MaxWidth > 0 && textWidth > MaxWidth)
				tscale = MaxWidth / textWidth;
			
			if(MaxHeight > 0 && textHeight > MaxHeight)
			{
				tscale = Math.min(tscale, MaxHeight / textHeight);
			}
			
			// We can only scale by a whole point size, so reverse engineer the scale factor
			// from the point size
			var newFontSize:Number = Math.floor(FontSize * tscale);
			tscale = newFontSize / FontSize;
			
			TextAdjuster.scaleX = tscale;
			TextAdjuster.scaleY = tscale;
			
			textWidth *= tscale;
			textHeight *= tscale;
		}
		else
		{
			TextAdjuster.scaleX = 1.0;
			TextAdjuster.scaleY = 1.0;
		}
		
		TextAdjuster.x = 0;
		TextAdjuster.y = 0;
		
		//trace("Container: "+MaxWidth+"x"+MaxHeight);
		//trace("Text: "+textWidth+"x"+textHeight);
		
		if(MaxWidth > 0)
		{
			switch(HAlign)
			{
				case LEFT:
					TextAdjuster.x = 0;
					bounds.x = 0;
					break;
				case CENTER:
					TextAdjuster.x = Math.round((MaxWidth - boxWidth) / 2);
					bounds.x = Math.round((MaxWidth - textWidth) / 2);
					break;
				case RIGHT:
					TextAdjuster.x = MaxWidth - boxWidth;
					bounds.x = MaxWidth - textWidth;
					break;
			}
		}
		
		if(MaxHeight > 0)
		{
			switch(VAlign)
			{
				case TOP:
					TextAdjuster.y = 0;
					break;
				case CENTER:
					TextAdjuster.y = Math.round((MaxHeight - textHeight) / 2);
					break;
				case BOTTOM:
					TextAdjuster.y = MaxHeight - textHeight;
					break;
			}
		}
		
		bounds.y = TextAdjuster.y;
		bounds.width = textWidth;
		bounds.height = textHeight;
		
		if(bounds.left < 0)
			bounds.left = 0;
		if(bounds.top < 0)
			bounds.top = 0;
		if(MaxWidth > 0 && bounds.right > MaxWidth)
			bounds.right = MaxWidth;
		if(MaxHeight > 0 && bounds.bottom > MaxHeight)
			bounds.bottom = MaxHeight;
		
		if(TextImage)
		{
			TextImage.dispose();
			TextImage = null;
		}	
		
		//trace("Text box: "+NativeTextField.width+","+NativeTextField.height);
		//trace("Text dims: "+textWidth+","+textHeight);
		//trace("Text bounds: "+bounds);
		
		TextImage = RazorImage.fromDisplayObject(TextHolder, Smoothing, bounds);
		TextImage._parent = _parent;
		TextImage.setStage(_stage);
		
		TextWidth = textWidth;
		TextHeight = textHeight;
		
	}
	
	public override function dispose(rebind:Boolean=false):void
	{
		if(TextImage && !rebind)
		{
			TextImage.dispose(rebind);
			TextImage = null;
		}
	}
	

	
	public override function render(modelView:Matrix3D, orientation:Number):void
	{
		if(TextImage)
		{
			orientation *= _scaleX * scaleY;

			if(Background)
				drawBackground(modelView, orientation);

			TextImage.ColorMultVector[0] = ColorMultVector[0];
			TextImage.ColorMultVector[1] = ColorMultVector[1];
			TextImage.ColorMultVector[2] = ColorMultVector[2];
			TextImage.ColorMultVector[3] = ColorMultVector[3];
			
			TextImage.ColorAddVector[0] = ColorAddVector[0];
			TextImage.ColorAddVector[1] = ColorAddVector[1];
			TextImage.ColorAddVector[2] = ColorAddVector[2];
			TextImage.ColorAddVector[3] = ColorAddVector[3];
			
			TextImage.render(modelView, orientation);
		}

	}
}

}

