package razor.display
{

import flash.display3D.Context3D;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTriangleFace;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.Context3DWrapMode;
import flash.display3D.Context3DMipFilter;
import flash.display3D.Context3DTextureFilter;
import flash.display3D.textures.Texture;
import flash.geom.Matrix3D;
import flash.events.MouseEvent;

import omg.Time;
import omg.TimeEvent;

import razor.RazorProgram;
import razor.texture.RazorTexture;
import razor.texture.RazorTextureBinding;
import razor.particles.RazorParticles;
import razor.particles.RazorParticlesBinding;
import razor.TouchInfo;
import razor.RazorInternal;

use namespace RazorInternal;



public class RazorEmitter extends RazorObject
{
	public var Particles:RazorParticles;

	private var TextureBinding:RazorTextureBinding;
	private var ParticleBinding:RazorParticlesBinding;
	private var Program:Program3D;

	private var CurrTime:Number = 0;
	private var BaseTime:Number = 0;
	
	private var WindingDown:Boolean=false;
	public var Lifetime:Number = 0;
	
	private var Timer:Time;

	private static var WorkingVect:Vector.<Number> = new Vector.<Number>(4,true);

	public function RazorEmitter(data:RazorParticles, lifetime:Number=0, timer:Time=null)
	{
		Particles = data;
		Lifetime = lifetime;
		interactive = false;
		
		Timer = timer ? timer : Time.Singleton;

		WorkingVect[0] = 0;
		WorkingVect[1] = 0;
		WorkingVect[2] = 1;
		WorkingVect[3] = 0;
	}
	

	public override function bind():void
	{
		var context:Context3D = _stage.Context;
		
		TextureBinding = Particles.Texture.Page.bind(_stage);
		ParticleBinding = Particles.bind(_stage);

		pickProgram();
	}
	
	protected override function addedToStage():void
	{
		Timer.frameListen(update);
	}
	
	protected override function removedFromStage(stage:RazorStage):void
	{
		Timer.stopFrameListen(update);
	}
	
	public function update(e:TimeEvent):void
	{
		var deltaTime:Number = e.UpdateDelta;
		CurrTime += deltaTime;
		BaseTime += deltaTime;
		while(BaseTime >= Particles.TotalPeriod && !WindingDown)
			BaseTime -= Particles.TotalPeriod;
		
		if(Lifetime > 0 && CurrTime >= Lifetime)
		{
			stop();
		}
	}
	
	public function stop():void
	{
		WindingDown = true;
	}
	
	public function start(lifetime:Number=0):void
	{
		WindingDown = false;
		Lifetime = lifetime;
		CurrTime = 0;
		BaseTime = 0;
	}
	
	private function removeSelf():void
	{
		WindingDown = false;
		if(parent)
		{
			parent.removeChild(this);
		}
	}
	
	private function pickProgram():void
	{
		if(ColorAddVector[0] == 0.0 && ColorAddVector[1] == 0.0 && ColorAddVector[2] == 0.0 && ColorAddVector[3] == 0.0)
			Program = RazorProgram.getParticle(_stage);
		else
			Program = RazorProgram.getParticleAdd(_stage);
	}
	
	public override function render(modelView:Matrix3D, orientation:Number):void
	{
		if(!TextureBinding.MyTexture || !_stage)
			return;
			
		var context:Context3D = _stage.Context;
		
		var combinedAlpha:Number = ColorMultVector[3] + ColorAddVector[3];
		
		if(Particles.Texture.Page.SourceTransparent || combinedAlpha != 1.0)
			context.setBlendFactors(Particles.Texture.Page.BlendSource, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
		else
			context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
		
		if(orientation * _scaleX * _scaleY > 0)
			context.setCulling(Context3DTriangleFace.BACK);
		else
			context.setCulling(Context3DTriangleFace.FRONT);

		ColorMultVector[0] *= combinedAlpha;
		ColorMultVector[1] *= combinedAlpha;
		ColorMultVector[2] *= combinedAlpha;
		
		ColorAddVector[0] *= combinedAlpha;
		ColorAddVector[1] *= combinedAlpha;
		ColorAddVector[2] *= combinedAlpha;
		ColorAddVector[3] = 0;
		
		var timeWindow:Number = BaseTime;
		
		pickProgram();
		
		context.setProgram(Program);
		context.setTextureAt(0, TextureBinding.MyTexture);
		context.setSamplerStateAt(0, Context3DWrapMode.CLAMP, Context3DTextureFilter.LINEAR, Context3DMipFilter.MIPNONE);
		
		context.setVertexBufferAt(0, ParticleBinding.Vertexes, 0, Context3DVertexBufferFormat.FLOAT_4); //xy / uv
		context.setVertexBufferAt(1, ParticleBinding.Vertexes, 4, Context3DVertexBufferFormat.FLOAT_4); //start / end size
		context.setVertexBufferAt(2, ParticleBinding.Vertexes, 8, Context3DVertexBufferFormat.FLOAT_4); //start color
		context.setVertexBufferAt(3, ParticleBinding.Vertexes, 12, Context3DVertexBufferFormat.FLOAT_4); //end color
		context.setVertexBufferAt(4, ParticleBinding.Vertexes, 16, Context3DVertexBufferFormat.FLOAT_4); //velocity / accel
		context.setVertexBufferAt(5, ParticleBinding.Vertexes, 20, Context3DVertexBufferFormat.FLOAT_1); //time shift
		
		context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, modelView, true);
		context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 5, ColorMultVector, 1);
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, ColorAddVector, 1);
		
		var numDraws:int = Math.floor(CurrTime / Particles.SpawnWindow) + 1;
		if(numDraws > Particles.Granularity)
			numDraws = Particles.Granularity;
		
		for(var d:int=0; d<numDraws; d++)
		{
			var timeScalar:Number = timeWindow / Particles.ParticleDuration;

			WorkingVect[0] = timeScalar;
			
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, WorkingVect);
			
			context.drawTriangles(ParticleBinding.Indexes, Particles.ParticlesPerSlice*6*d, 2*Particles.ParticlesPerSlice);
			
			timeWindow -= Particles.SpawnWindow;
			if(timeWindow < 0)
				timeWindow += Particles.TotalPeriod;
		}
		
		context.setVertexBufferAt(2, null);
		context.setVertexBufferAt(3, null);
		context.setVertexBufferAt(4, null);
		context.setVertexBufferAt(5, null);
		
		if(WindingDown && BaseTime > Particles.TotalPeriod * numDraws)
		{
			Timer.callInNextFrame(removeSelf);
		}
	}
	

}
	
}