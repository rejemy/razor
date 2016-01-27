package razor.particles
{

import flash.geom.Matrix;
import flash.geom.Point;
import flash.utils.getTimer;

import omg.Dict;
import omg.OMGUtil;
import omg.SeededRand;

import razor.display.RazorStage;
import razor.texture.RazorTexture;
import razor.RazorUtils;

public class RazorParticles
{
	public var Texture:RazorTexture;
	
	public var ParticlesPerSlice:uint;
	public var NumParticles:uint;
	public var ParticleDuration:Number;
	public var Granularity:int;

	public var SpawnWindow:Number;
	public var SpawnRange:Number;
	public var TotalPeriod:Number;
	
	private var StartSize:Number;
	private var StartSizeVariance:Number;
	
	private var EndSize:Number;
	private var EndSizeVariance:Number;
	
	private var StartColor:uint;
	private var StartColorVariance:uint;
	
	private var EndColor:uint;
	private var EndColorVariance:uint;
	
	private var SourceVarianceX:Number;
	private var SourceVarianceY:Number;

	private var VelocityX:Number;
	private var VelocityY:Number;
	private var VelocityVarianceX:Number;
	private var VelocityVarianceY:Number;

	private var AccelX:Number;
	private var AccelY:Number;
	private var AccelVarianceX:Number;
	private var AccelVarianceY:Number;

	private var PolarCoords:Boolean;
	private var SourceRadius:Number;
	private var SourceRadiusVariance:Number;
	private var SourceAngle:Number;
	private var SourceAngleVariance:Number;
	
	private var Seed:int;
	
	private var MAX_PARTICLES:int = 16000;
	
	public var Bindings:Vector.<RazorParticlesBinding>;
	
	public function RazorParticles(image:RazorTexture, config:Object)
	{
		Texture = image;
		
		var conf:Dict = Dict.fromObject(config);
		
		NumParticles = conf.get("number", 20);
		
		if(NumParticles > MAX_PARTICLES)
			NumParticles = MAX_PARTICLES;
		
		ParticleDuration = conf.get("duration", 2.0);
		Granularity = conf.get("granularity", 4);
		if(Granularity < 2)
			Granularity = 2;
		
		ParticlesPerSlice = Math.floor(NumParticles / Granularity);
		NumParticles = ParticlesPerSlice * Granularity; // Round off num particles to be evenly divisible by granularity
		
		StartSize = conf.get("startsize", 1.0);
		StartSizeVariance = conf.get("startsizevary", 0.0);
		EndSize = conf.get("endsize", 0.0);
		EndSizeVariance = conf.get("endsizevary", 0.0);
		
		SourceVarianceX = conf.get("sourcevaryx", 10.0);
		SourceVarianceY = conf.get("sourcevaryy", 10.0);
		
		StartColor = parseColor(conf.get("startcolor", 0xffffffff));
		StartColorVariance = parseColor(conf.get("startcolorvary", 0x0));
		
		EndColor = parseColor(conf.get("endcolor", 0xffffff00));
		EndColorVariance = parseColor(conf.get("endcolorvary", 0x0));
		
		VelocityX = conf.get("velocityx", 0.0);
		VelocityY = conf.get("velocityy", 10.0);
			
		VelocityVarianceX = conf.get("velocityvaryx", 2.0);
		VelocityVarianceY = conf.get("velocityvaryy", 4.0);
		
		AccelX = conf.get("accelx", 0.0);
		AccelY = conf.get("accely", 0.0);
		
		AccelVarianceX = conf.get("accelvaryx", 0.0);
		AccelVarianceY = conf.get("accelvaryy", 0.0);
		
		PolarCoords = conf.get("polar", false);
		
		SourceRadius = conf.get("sourceradius", 0.0);
		SourceRadiusVariance = conf.get("sourceradiusvary", 0.0);
		
		SourceAngle = conf.get("sourceangle", 0.0);
		SourceAngleVariance = conf.get("sourceanglevary", 180.0);
		
		SpawnWindow = ParticleDuration / (Granularity - 1);
		SpawnRange = conf.get("spawnrange", SpawnWindow);
		if(SpawnRange > SpawnWindow)
			SpawnRange = SpawnWindow;
		else if(SpawnRange < 0)
			SpawnRange = 0;
			
		TotalPeriod = ParticleDuration + SpawnWindow;
		
		Seed = conf.get("seed", 0);
		if(Seed == 0)
			Seed = getTimer();
			
		Bindings = new Vector.<RazorParticlesBinding>(1);
	}
	
	private function parseColor(color:Object):uint
	{
		if(color is String)
			return parseInt(color as String);
		return color as uint;
	}
	
	public function bind(fstage:RazorStage):RazorParticlesBinding
	{
		var binding:RazorParticlesBinding = Bindings[fstage.StageID];
		if(binding == null)
		{
			binding = new RazorParticlesBinding();
			
			binding.Vertexes = fstage.Context.createVertexBuffer(4*NumParticles, 21);
			
			makeVerts(binding);
			
			var numIndexes:uint = NumParticles*6;
			binding.Indexes = fstage.Context.createIndexBuffer(numIndexes);
			var indexes:Vector.<uint> = new Vector.<uint>(numIndexes);
			var vert:uint = 0;
			var i:uint = 0;
			while(i < numIndexes)
			{
				indexes[i++] = vert;
				indexes[i++] = vert+1;
				indexes[i++] = vert+3;
				indexes[i++] = vert+1;
				indexes[i++] = vert+2;
				indexes[i++] = vert+3;
				vert += 4;
			}

			binding.Indexes.uploadFromVector(indexes, 0, numIndexes);
			
			//fstage.setSharedQuadIndexSize(NumParticles);
			
			Bindings[fstage.StageID] = binding;
			fstage.AllParticles[this] = true;
		}
		
		return binding;
	}
	
	
	private function makeVerts(binding:RazorParticlesBinding):void
	{
		var rand:SeededRand = new SeededRand(Seed);
		
		var verts:Vector.<Number> = new Vector.<Number>(4*NumParticles * 21);
		
		var i:uint = 0;
		
		var polarTform:Matrix = new Matrix();
		var polarPoint:Point = new Point();
		
		for(var p:uint=0; p<NumParticles; p++)
		{
			var posX:Number;
			var posY:Number;
			var angle:Number;
			
			
			if(PolarCoords)
			{
				var radius:Number = SourceRadius + rand.randRangeFloat(-SourceRadiusVariance, SourceRadiusVariance);
				angle = SourceAngle + rand.randRangeFloat(-SourceAngleVariance, SourceAngleVariance);
				polarTform.identity();
				polarTform.rotate(angle);
				polarPoint.x = 0;
				polarPoint.y = -radius;
				polarPoint = polarTform.transformPoint(polarPoint);
				posX = polarPoint.x;
				posY = polarPoint.y;
			}
			else
			{
				posX = rand.randRangeFloat(-SourceVarianceX, SourceVarianceX);
				posY = rand.randRangeFloat(-SourceVarianceY, SourceVarianceY);
			}
			
			var startSize:Number = StartSize + rand.randRangeFloat(-StartSizeVariance, StartSizeVariance);
			if(startSize < 0.0)
				startSize = 0.0;
			
			var endSize:Number = EndSize + rand.randRangeFloat(-EndSizeVariance, EndSizeVariance);
			if(endSize < 0.0)
				endSize = 0.0;
			
			endSize -= startSize;
			
			var color:Vector.<Number> = new Vector.<Number>(4);
			RazorUtils.colorToVec(StartColor, color);
		
			var red:Number = color[0];
			var green:Number = color[1];
			var blue:Number = color[2];
			var alpha:Number = color[3];
		
			RazorUtils.colorToVec(StartColorVariance, color);
		
			red += rand.randRangeFloat(-color[0], color[0]);
			if(red < 0) red = 0; else if (red > 1.0) red = 1.0;
			green += rand.randRangeFloat(-color[1], color[1]);
			if(green < 0) green = 0; else if (green > 1.0) green = 1.0;
			blue += rand.randRangeFloat(-color[2], color[2]);
			if(blue < 0) blue = 0; else if (blue > 1.0) blue = 1.0;
			alpha += rand.randRangeFloat(-color[3], color[3]);
			if(alpha < 0) alpha = 0; else if (alpha > 1.0) alpha = 1.0;
			
			// Premultiply alpha
			red *= alpha;
			green *= alpha;
			blue *= alpha;
			
			RazorUtils.colorToVec(EndColor, color);
		
			var endred:Number = color[0];
			var endgreen:Number = color[1];
			var endblue:Number = color[2];
			var endalpha:Number = color[3];
		
			RazorUtils.colorToVec(EndColorVariance, color);
		
			endred += rand.randRangeFloat(-color[0], color[0]);
			if(endred < 0) endred = 0; else if (endred > 1.0) endred = 1.0;
			endgreen += rand.randRangeFloat(-color[1], color[1]);
			if(endgreen < 0) endgreen = 0; else if (endgreen > 1.0) endgreen = 1.0;
			endblue += rand.randRangeFloat(-color[2], color[2]);
			if(endblue < 0) endblue = 0; else if (endblue > 1.0) endblue = 1.0;
			endalpha += rand.randRangeFloat(-color[3], color[3]);
			if(endalpha < 0) endalpha = 0; else if (endalpha > 1.0) endalpha = 1.0;
			
			// Premultiply alpha
			endred *= endalpha;
			endgreen *= endalpha;
			endblue *= endalpha;
			
			endred -= red;
			endgreen -= green;
			endblue -= blue;
			endalpha -= alpha;
			
			var velX:Number = VelocityX + rand.randRangeFloat(-VelocityVarianceX, VelocityVarianceX);
			var velY:Number = VelocityY + rand.randRangeFloat(-VelocityVarianceY, VelocityVarianceY);
			var accelX:Number = AccelX + rand.randRangeFloat(-AccelVarianceX, AccelVarianceX);
			var accelY:Number = AccelY + rand.randRangeFloat(-AccelVarianceY, AccelVarianceY);
			
			velX *= ParticleDuration;
			velY *= ParticleDuration;
			
			if(PolarCoords)
			{
				polarPoint.x = velX;
				polarPoint.y = velY;
				
				polarPoint = polarTform.transformPoint(polarPoint);
				velX = polarPoint.x;
				velY = polarPoint.y;
				
				polarPoint.x = accelX;
				polarPoint.y = accelY;
				
				polarPoint = polarTform.transformPoint(polarPoint);
				accelX = polarPoint.x;
				accelY = polarPoint.y;
			}
			
			accelX *= 0.5 * ParticleDuration * ParticleDuration;
			accelY *= 0.5 * ParticleDuration * ParticleDuration;
			
			var timeShift:Number = rand.randRangeFloat(0, SpawnRange) / ParticleDuration;
			
				// Pos
			verts[i++] = posX;
			verts[i++] = posY;
			// UV
			verts[i++] = Texture.MinU;
			verts[i++] = Texture.MinV;
		
			// Size
			if(PolarCoords)
			{
				polarPoint.x = (Texture.OffsetX)*startSize;
				polarPoint.y = (Texture.OffsetY)*startSize;
				polarPoint = polarTform.transformPoint(polarPoint);
				verts[i++] = polarPoint.x;
				verts[i++] = polarPoint.y;
				polarPoint.x = (Texture.OffsetX)*endSize;
				polarPoint.y = (Texture.OffsetY)*endSize;
				polarPoint = polarTform.transformPoint(polarPoint);
				verts[i++] = polarPoint.x;
				verts[i++] = polarPoint.y;
			}
			else
			{
				verts[i++] = (Texture.OffsetX)*startSize;
				verts[i++] = (Texture.OffsetY)*startSize;
				verts[i++] = (Texture.OffsetX)*endSize;
				verts[i++] = (Texture.OffsetY)*endSize;
			}
			
			// Color
			verts[i++] = red;
			verts[i++] = green;
			verts[i++] = blue;
			verts[i++] = alpha;
			verts[i++] = endred;
			verts[i++] = endgreen;
			verts[i++] = endblue;
			verts[i++] = endalpha;
	
			// Velocity
			verts[i++] = velX;
			verts[i++] = velY;
		
			// Acceleration
			verts[i++] = accelX;
			verts[i++] = accelY;
		
			// Time shift
			verts[i++] = timeShift;
			
			// Pos
			verts[i++] = posX;
			verts[i++] = posY;
			// UV
			verts[i++] = Texture.MaxU;
			verts[i++] = Texture.MinV;
			
			// Size
			if(PolarCoords)
			{
				polarPoint.x = (Texture.Width+Texture.OffsetX)*startSize;
				polarPoint.y = (Texture.OffsetY)*startSize;
				polarPoint = polarTform.transformPoint(polarPoint);
				verts[i++] = polarPoint.x;
				verts[i++] = polarPoint.y;
				polarPoint.x = (Texture.Width+Texture.OffsetX)*endSize;
				polarPoint.y = (Texture.OffsetY)*endSize;
				polarPoint = polarTform.transformPoint(polarPoint);
				verts[i++] = polarPoint.x;
				verts[i++] = polarPoint.y;
			}
			else
			{
				verts[i++] = (Texture.Width+Texture.OffsetX)*startSize;
				verts[i++] = (Texture.OffsetY)*startSize;
				verts[i++] = (Texture.Width+Texture.OffsetX)*endSize;
				verts[i++] = (Texture.OffsetY)*endSize;
			}
			
			// Color
			verts[i++] = red;
			verts[i++] = green;
			verts[i++] = blue;
			verts[i++] = alpha;
			verts[i++] = endred;
			verts[i++] = endgreen;
			verts[i++] = endblue;
			verts[i++] = endalpha;
		
			// Velocity
			verts[i++] = velX;
			verts[i++] = velY;
			
			// Acceleration
			verts[i++] = accelX;
			verts[i++] = accelY;
			
			// Time shift
			verts[i++] = timeShift;
			
		
			// Pos
			verts[i++] = posX;
			verts[i++] = posY;
			// UV
			verts[i++] = Texture.MaxU;
			verts[i++] = Texture.MaxV;
			
			// Size
			if(PolarCoords)
			{
				polarPoint.x = (Texture.Width+Texture.OffsetX)*startSize;
				polarPoint.y = (Texture.Height+Texture.OffsetY)*startSize;
				polarPoint = polarTform.transformPoint(polarPoint);
				verts[i++] = polarPoint.x;
				verts[i++] = polarPoint.y;
				polarPoint.x = (Texture.Width+Texture.OffsetX)*endSize;
				polarPoint.y = (Texture.Height+Texture.OffsetY)*endSize;
				polarPoint = polarTform.transformPoint(polarPoint);
				verts[i++] = polarPoint.x;
				verts[i++] = polarPoint.y;
			}
			else
			{
				verts[i++] = (Texture.Width+Texture.OffsetX)*startSize;
				verts[i++] = (Texture.Height+Texture.OffsetY)*startSize;
				verts[i++] = (Texture.Width+Texture.OffsetX)*endSize;
				verts[i++] = (Texture.Height+Texture.OffsetY)*endSize;
			}
			
			// Color
			verts[i++] = red;
			verts[i++] = green;
			verts[i++] = blue;
			verts[i++] = alpha;
			verts[i++] = endred;
			verts[i++] = endgreen;
			verts[i++] = endblue;
			verts[i++] = endalpha;
		
			// Velocity
			verts[i++] = velX;
			verts[i++] = velY;
			
			// Acceleration
			verts[i++] = accelX;
			verts[i++] = accelY;
			
			// Time shift
			verts[i++] = timeShift;
			
		
			// Pos
			verts[i++] = posX;
			verts[i++] = posY;
			// UV
			verts[i++] = Texture.MinU;
			verts[i++] = Texture.MaxV;
			
			// Size
			if(PolarCoords)
			{
				polarPoint.x = (Texture.OffsetX)*startSize;
				polarPoint.y = (Texture.Height+Texture.OffsetY)*startSize;
				polarPoint = polarTform.transformPoint(polarPoint);
				verts[i++] = polarPoint.x;
				verts[i++] = polarPoint.y;
				polarPoint.x = (Texture.OffsetX)*endSize;
				polarPoint.y = (Texture.Height+Texture.OffsetY)*endSize;
				polarPoint = polarTform.transformPoint(polarPoint);
				verts[i++] = polarPoint.x;
				verts[i++] = polarPoint.y;
			}
			else
			{
				verts[i++] = (Texture.OffsetX)*startSize;
				verts[i++] = (Texture.Height+Texture.OffsetY)*startSize;
				verts[i++] = (Texture.OffsetX)*endSize;
				verts[i++] = (Texture.Height+Texture.OffsetY)*endSize;
			}

			// Color
			verts[i++] = red;
			verts[i++] = green;
			verts[i++] = blue;
			verts[i++] = alpha;
			verts[i++] = endred;
			verts[i++] = endgreen;
			verts[i++] = endblue;
			verts[i++] = endalpha;
			
			// Velocity
			verts[i++] = velX;
			verts[i++] = velY;
			
			// Acceleration
			verts[i++] = accelX;
			verts[i++] = accelY;
			
			// Time shift
			verts[i++] = timeShift;
			
		}
	
		binding.Vertexes.uploadFromVector(verts, 0, NumParticles*4);
	}
	
	public function dispose(stageID:int=-1, rebind:Boolean = true):void
	{
		var currStageID:int = 0;
		for each(var binding:RazorParticlesBinding in Bindings)
		{
			if((stageID == -1 || stageID == currStageID) && binding)
			{
				binding.Indexes.dispose();
				binding.Vertexes.dispose();
				Bindings[currStageID] = null;
				if(!rebind)
					delete RazorStage.Stages[currStageID].AllParticles[this];
			}
			stageID += 1;
		}
		
	}
}

}