package razor
{

import com.adobe.utils.AGALMiniAssembler;

import flash.display3D.Context3DProgramType;
import flash.display3D.Program3D;
import flash.utils.ByteArray;
import razor.display.RazorStage;

public final class RazorProgram
{
	
	private static var Assembler:AGALMiniAssembler;
	
	private static var Bindings:Vector.<ProgramBindings>;
	
	private static var QuadVertCode:ByteArray;
	private static var QuadFragCode:ByteArray;
	private static var TexturedVertCode:ByteArray;
	private static var ParticleVertCode:ByteArray;
	private static var TexturedFragCode:ByteArray;
	private static var TexturedMultFragCode:ByteArray;
	private static var TexturedAddFragCode:ByteArray;
	private static var TexturedMultAddFragCode:ByteArray;
	private static var ParticleFragCode:ByteArray;
	private static var ParticleAddFragCode:ByteArray;
	
	public static function init():void
	{
		if(!Bindings)
		{
			Assembler = new AGALMiniAssembler();
			Bindings = new Vector.<ProgramBindings>(1);
		}
	}
	
	private static function getBinding(stageID:uint):ProgramBindings
	{
		var bindings:ProgramBindings = Bindings[stageID];
		if(bindings)
			return bindings;
	
		bindings = new ProgramBindings();
		Bindings[stageID] = bindings;
		return bindings;
	}
	
	private static function getQuadVertCode():ByteArray
	{
		if(QuadVertCode)
			return QuadVertCode;
		
		var prog:Array = [
			"m44 op, va0, vc0"
		];
		QuadVertCode = Assembler.assemble(Context3DProgramType.VERTEX, prog.join("\n"));
		return QuadVertCode;
	}
	
	private static function getQuadFragCode():ByteArray
	{
		if(QuadFragCode)
			return QuadFragCode;
		
		var prog:Array = [
			"mov oc, fc0"
		];
		
		QuadFragCode = Assembler.assemble(Context3DProgramType.FRAGMENT, prog.join("\n"));
		return QuadFragCode;
	}
	
	private static function getTexturedVertCode():ByteArray
	{
		if(TexturedVertCode)
			return TexturedVertCode;
		
		var prog:Array = [
			"m44 op, va0, vc0",
			"mov v0, va1"
		];
		TexturedVertCode = Assembler.assemble(Context3DProgramType.VERTEX, prog.join("\n"));
		return TexturedVertCode;
	}
	
	private static function getParticleVertexProgramCode():ByteArray
	{
		if(ParticleVertCode)
			return ParticleVertCode;
		
		var prog:Array =
		[
			"sub vt2.x,  vc4.x, va5.x",			// Subtract for relative time
			"mul vt2.y,  vt2.x, vt2.x",			// Mult for time squared
			"mov vt0.zw, vc4.yz",				// Initialize position to default
			"mov vt0.xy, va0.xy",				// Add start position
			"mul vt1.xy, vt2.xx, va4.xy",		// calc velocity
			"add vt0.xy, vt0.xy, vt1.xy",		// Add velocity
			"mul vt1.xy, vt2.yy, va4.zw",		// calc accel
			"add vt0.xy, vt0.xy, vt1.xy",		// Add accel
			"add vt0.xy, vt0.xy, va1.xy",		// Add initial size
			"mul vt1.xy, vt2.xx, va1.zw",		// calc size adjustment
			"add vt0.xy, vt0.xy, vt1.xy",		// Add size adjustment
			"sge vt1.x,  vt2.x,  vc4.y",		// Test if time is greater than or equal 0
			"mul vt0.xy, vt0.xy, vt1.xx",		// Multiply into pos
			"sge vt1.x,  vc4.z,  vt2.x",		// Test if 1 is greater than or equal time
			"mul vt0.xy, vt0.xy, vt1.xx",		// Multiply into pos
			"m44 op, vt0, vc0",					// Set final vert position
			"mul vt1, vt2.xxxx, va3",			// calc end color
			"add vt0, va2, vt1",				// Add end color
			"mul v1, vt0, vc5",					// Multiply by overall tint
			"mov v0.xyzw, va0.zwzw"				// Set UVs
		];
		
		ParticleVertCode = Assembler.assemble(Context3DProgramType.VERTEX, prog.join("\n"));
		return ParticleVertCode;
	}
	
	private static function getTexturedFragCode():ByteArray
	{
		if(TexturedFragCode)
			return TexturedFragCode;
		
		var prog:Array = [
			"tex oc, v0, fs0<2d,linear,clamp>"
		];
		
		TexturedFragCode = Assembler.assemble(Context3DProgramType.FRAGMENT, prog.join("\n"));
		return TexturedFragCode;
	}
	
	
	private static function getTexturedMultFragCode():ByteArray
	{
		if(TexturedMultFragCode)
			return TexturedMultFragCode;
		
		var prog:Array = [
			"tex ft0, v0, fs0<2d,linear,clamp>",
			"mul oc, ft0, fc0"
		];
		
		TexturedMultFragCode = Assembler.assemble(Context3DProgramType.FRAGMENT, prog.join("\n"));
		return TexturedMultFragCode;
	}
	
	private static function getTexturedAddFragCode():ByteArray
	{
		if(TexturedAddFragCode)
			return TexturedAddFragCode;
		
		var prog:Array = [
			"tex ft0, v0, fs0<2d,linear,clamp>",
			"mul ft1.rgba, fc1.rgba ft0.aaaa",
			"add oc, ft0, ft1"
		];
		
		TexturedAddFragCode = Assembler.assemble(Context3DProgramType.FRAGMENT, prog.join("\n"));
		return TexturedAddFragCode;
	}

	private static function getTexturedMultAddFragCode():ByteArray
	{
		if(TexturedMultAddFragCode)
			return TexturedMultAddFragCode;
		
		var prog:Array = [
			"tex ft0, v0, fs0<2d,linear,clamp>",
			"mul ft0, ft0, fc0",
			"mul ft1.rgba, fc1.rgba ft0.aaaa",
			"add oc, ft0, ft1"
		];
		
		TexturedMultAddFragCode = Assembler.assemble(Context3DProgramType.FRAGMENT, prog.join("\n"));
		return TexturedMultAddFragCode;
	}

	private static function getParticleFragCode():ByteArray
	{
		if(ParticleFragCode)
			return ParticleFragCode;
		
		var prog:Array = [
			"tex ft0, v0, fs0<2d,linear,clamp>",
			"mul oc, ft0, v1"
		];
		
		ParticleFragCode = Assembler.assemble(Context3DProgramType.FRAGMENT, prog.join("\n"));
		return ParticleFragCode;
	}

	private static function getParticleAddFragCode():ByteArray
	{
		if(ParticleAddFragCode)
			return ParticleAddFragCode;
		
		var prog:Array = [
			"tex ft0, v0, fs0<2d,linear,clamp>",
			"mul ft0, ft0, v1",
			"add oc, ft0, fc1"
		];
		
		ParticleAddFragCode = Assembler.assemble(Context3DProgramType.FRAGMENT, prog.join("\n"));
		return ParticleAddFragCode;
	}
	
	public static function getSolidColor(fstage:RazorStage):Program3D
	{
		var bindings:ProgramBindings = getBinding(fstage.StageID);
		if(bindings.SolidColor)
			return bindings.SolidColor;
		
		bindings.SolidColor = fstage.Context.createProgram();
		bindings.SolidColor.upload(getQuadVertCode(), getQuadFragCode());
		
		return bindings.SolidColor;
	}
	
	public static function getTextured(fstage:RazorStage):Program3D
	{
		//trace("getTextured");
		var bindings:ProgramBindings = getBinding(fstage.StageID);
		if(bindings.Textured)
			return bindings.Textured;
		
		bindings.Textured = fstage.Context.createProgram();
		bindings.Textured.upload(getTexturedVertCode(), getTexturedFragCode());
		
		return bindings.Textured;
	}
	
	public static function getTexturedMult(fstage:RazorStage):Program3D
	{
		//trace("getTexturedMult");
		var bindings:ProgramBindings = getBinding(fstage.StageID);
		if(bindings.TexturedMult)
			return bindings.TexturedMult;
		
		bindings.TexturedMult = fstage.Context.createProgram();
		bindings.TexturedMult.upload(getTexturedVertCode(), getTexturedMultFragCode());
		
		return bindings.TexturedMult;
	}
	
	public static function getTexturedAdd(fstage:RazorStage):Program3D
	{
		//trace("getTexturedAdd");
		var bindings:ProgramBindings = getBinding(fstage.StageID);
		if(bindings.TexturedAdd)
			return bindings.TexturedAdd;
		
		bindings.TexturedAdd = fstage.Context.createProgram();
		bindings.TexturedAdd.upload(getTexturedVertCode(), getTexturedAddFragCode());
		
		return bindings.TexturedAdd;
	}
	
	public static function getTexturedMultAdd(fstage:RazorStage):Program3D
	{
		//trace("getTexturedMultAdd");
		var bindings:ProgramBindings = getBinding(fstage.StageID);
		if(bindings.TexturedMultAdd)
			return bindings.TexturedMultAdd;
		
		bindings.TexturedMultAdd = fstage.Context.createProgram();
		bindings.TexturedMultAdd.upload(getTexturedVertCode(), getTexturedMultAddFragCode());
		
		return bindings.TexturedMultAdd;
	}

	public static function getParticle(fstage:RazorStage):Program3D
	{
		var bindings:ProgramBindings = getBinding(fstage.StageID);
		if(bindings.Particle)
			return bindings.Particle;
		
		bindings.Particle = fstage.Context.createProgram();
		bindings.Particle.upload(getParticleVertexProgramCode(), getParticleFragCode());
		
		return bindings.Particle;
	}

	public static function getParticleAdd(fstage:RazorStage):Program3D
	{
		var bindings:ProgramBindings = getBinding(fstage.StageID);
		if(bindings.ParticleAdd)
			return bindings.ParticleAdd;
		
		bindings.ParticleAdd = fstage.Context.createProgram();
		bindings.ParticleAdd.upload(getParticleVertexProgramCode(), getParticleFragCode());
		
		return bindings.ParticleAdd;
	}

	public static function dispose(fstage:RazorStage):void
	{
		var bindings:ProgramBindings = getBinding(fstage.StageID);
		if(!bindings)
			return;
		
		if(bindings.SolidColor)
		{
			bindings.SolidColor.dispose();
			bindings.SolidColor = null;
		}
		
		if(bindings.Textured)
		{
			bindings.Textured.dispose();
			bindings.Textured = null;
		}
		
		if(bindings.TexturedMult)
		{
			bindings.TexturedMult.dispose();
			bindings.TexturedMult = null;
		}
		
		if(bindings.TexturedAdd)
		{
			bindings.TexturedAdd.dispose();
			bindings.TexturedAdd = null;
		}
		
		if(bindings.TexturedMultAdd)
		{
			bindings.TexturedMultAdd.dispose();
			bindings.TexturedMultAdd = null;
		}
		
		if(bindings.Particle)
		{
			bindings.Particle.dispose();
			bindings.Particle = null;
		}
		
		if(bindings.ParticleAdd)
		{
			bindings.ParticleAdd.dispose();
			bindings.ParticleAdd = null;
		}
	}
}

}

import flash.display3D.Program3D;

class ProgramBindings
{
	public var SolidColor:Program3D;
	public var Textured:Program3D;
	public var TexturedMult:Program3D;
	public var TexturedAdd:Program3D;
	public var TexturedMultAdd:Program3D;
	public var Particle:Program3D;
	public var ParticleAdd:Program3D;
}