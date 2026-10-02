////////////////////////////////////////////////////////////////
//
//                         SOFTNESS
//
////////////////////////////////////////////////////////////////

s.boot
s.meter

NF.clear

(

	NF(\pointsoft).fadeTime = 0.1;
	NF(\poimsoft).fadeTime = 0.1;
	NF(\poibsoft).fadeTime = 0.1;

)

(

// Section A

NF(\pointsoft, {|
	trigfrom = 18, trigto = 25, trigrate = 1,
	freq = 1257.74, freqSpread = 4.47, res = 0.007, amp = 120, amp_scale = 0.2,
	panStart = 4, panEnd = 10, panDur = 25|
	var hiImpulse, loImpulse, mixed, panner;
	var hiFreq = freq / freqSpread, loFreq = freq * freqSpread;

	hiImpulse = BBandPass.ar(
		Impulse.ar(LFNoise1.ar(trigrate).range(trigfrom * 0.5, trigto)) * amp_scale,
		hiFreq, res, amp
	);
	loImpulse = BBandPass.ar(
		Impulse.ar(
			LFNoise1.ar(trigrate).range(trigfrom, trigto * 2)
		) * amp_scale,
		loFreq, res * 0.5, amp
	);
	mixed = hiImpulse + loImpulse;
	panner = LFNoise1.ar(Line.kr(panStart, panEnd, panDur)).range(-1, 1);

	PanAz.ar(8, mixed, panner);
}).play;

NF(\poimsoft, {|
	modFreq = 9, feedb = 0.2, freqFrom = 1748.73, freqTo = 1760,
	freqMult = 2, driftRate = 0.001, amp = 0.005
|
	var modRatios = [1, 1.2, 1.4, 1.18];

	SinOscFB.ar(
		LFNoise1.ar(driftRate).range(freqFrom, freqTo) * freqMult,
		feedb
	).fold2(
		SinOsc.ar(modFreq / modRatios)
	) * amp * SinOsc.ar(10).range(0.001,0.5);
}).play([12,13,14,15]);

NF(\poibsoft, {|
	rela = 6.5, hpf = 80, chaosRate = 10, chaosMin = 2.5,
	chaosMax = 3.5, amp1 = 0.05, amp2 = 0.001
|
	var diff = rela + (rela * 0.5);
	var relb = GbmanL.ar(chaosRate).range(chaosMin, chaosMax);
	var diffb = relb + (relb * 1.75);
	var sig1, sig2;

	sig1 = SinOsc.ar(
		LFCub.kr([rela + (rela * 0.5), rela], 0, diff * 10, rela * rela),
		0, amp1
	);
	sig2 = SinOsc.ar(
		LFCub.kr([relb + (relb * 0.5), relb, rela * 2, relb * 2], 0, diffb * 10, relb * relb),
		0, amp2
	);

	HPF.ar(sig1 + sig2, hpf);
}).play([8, 9, 10, 11]);

)

(

// Section B

NF(\pointsoft, {|
	hitrigfrom = 4, hitrigto = 20, hitrigrate = 1,
	hifreq = 200, hires = 0.01, hiamp = 80, hiamp_scale = 0.01,
	lorate = 20, lofreq = 9043.89, lores = 0.02, loamp = 80, loamp_scale = 0.1,
	panStart = 4, panEnd = 10, panDur = 25
|
	var hiImpulse, loImpulse, mixed, panner;

	hiImpulse = BBandPass.ar(
		Impulse.ar(LFNoise1.ar(hitrigrate).range(hitrigfrom, hitrigto)) * hiamp_scale,
		hifreq, hires, hiamp
	);
	loImpulse = BBandPass.ar(
		Impulse.ar(lorate) * loamp_scale,
		lofreq, lores, loamp
	);
	mixed = hiImpulse + loImpulse;
	panner = LFNoise1.ar(Line.kr(panStart, panEnd, panDur)).range(-1, 1);

	PanAz.ar(8, mixed, panner);
}).play;

NF(\poimsoft, {|
	modFreq = 18, feedb = 0.2, freqFrom = 1748.73, freqTo = 1768.73,
	freqMult = 2, driftRate = 0.001, amp = 0.01
|
	var modRatios = [1, 1.2, 1.4, 1.18];

	SinOscFB.ar(
		LFNoise1.ar(driftRate).range(freqFrom, freqTo) * freqMult,
		feedb
	).fold2(
		SinOsc.ar(modFreq / modRatios)
	) * amp;
}).play([12,13,14,15]);

NF(\poibsoft, {|
	rela = 10, hpf = 100, chaosRate = 10, chaosMin = 2.5,
	chaosMax = 3.5, amp1 = 0.005, amp2 = 0.001
|
	var diff = rela + (rela * 0.5);
	var relb = GbmanL.ar(chaosRate).range(chaosMin, chaosMax);
	var diffb = relb + (relb * 1.75);
	var sig1, sig2;

	sig1 = SinOsc.ar(
		LFCub.kr([rela + (rela * 0.5), rela], 0, diff * 10, rela * rela),
		0, amp1
	);
	sig2 = SinOsc.ar(
		LFCub.kr([relb + (relb * 0.5), relb, rela * 2, relb * 2], 0, diffb * 10, relb * relb),
		0, amp2
	);

	HPF.ar(sig1 + sig2, hpf);
}).play([8, 9, 10, 11]);

)

(

// Section C

NF(\pointsoft, {|
	hitrigfrom = 1, hitrigto = 5, hitrigrate = 1,
	hifreq = 200, hires = 0.01, hiamp = 80, hiamp_scale = 0.01,
	lorate = 20, lofreq = 4473.33, lores = 0.02, loamp = 80, loamp_scale = 0.1,
	panStart = 4, panEnd = 10, panDur = 25
|
	var hiImpulse, loImpulse, mixed, panner;

	hiImpulse = BBandPass.ar(
		Impulse.ar(LFNoise1.ar(hitrigrate).range(hitrigfrom, hitrigto)) * hiamp_scale,
		hifreq, hires, hiamp
	);
	loImpulse = BBandPass.ar(
		Impulse.ar(lorate) * loamp_scale,
		lofreq, lores, loamp
	);
	mixed = hiImpulse + loImpulse;
	panner = LFNoise1.ar(Line.kr(panStart, panEnd, panDur)).range(-1, 1);

	PanAz.ar(8, mixed, panner);
}).play;

NF(\poimsoft, {|
	modFreq = 30, feedb = 0.2, freqFrom = 884.64, freqTo = 884.64,
	freqMult = 2, driftRate = 0.001, amp = 0.0085
|
	var modRatios = [1, 1.2, 1.4, 1.18];

	SinOscFB.ar(
		LFNoise1.ar(driftRate).range(freqFrom, freqTo) * freqMult,
		feedb
	).fold2(
		SinOsc.ar(modFreq / modRatios)
	) * amp;
}).play;

NF(\poibsoft, {|
	rela = 10, hpf = 80, chaosRate = 15, chaosMin = 2.5,
	chaosMax = 3.5, amp1 = 0.005, amp2 = 0.01
|
	var diff = rela + (rela * 0.5);
	var relb = GbmanL.ar(chaosRate).range(chaosMin, chaosMax);
	var diffb = relb + (relb * 1.75);
	var sig1, sig2;

	sig1 = SinOsc.ar(
		LFCub.kr([rela + (rela * 0.5), rela], 0, diff * 10, rela * rela),
		0, amp1
	);
	sig2 = SinOsc.ar(
		LFCub.kr([relb + (relb * 0.5), relb, rela * 2, relb * 2], 0, diffb * 10, relb * relb),
		0, amp2
	);

	HPF.ar(sig1 + sig2, hpf);
}).play;

)

(

// Section D

NF(\pointsoft, {|
	hitrigfrom = 4, hitrigto = 20, hitrigrate = 1,
	hifreq = 200, hires = 0.01, hiamp = 80, hiamp_scale = 0.01,
	lorate = 20, lofreq = 8000, lores = 0.02, loamp = 80, loamp_scale = 0.1,
	panStart = 4, panEnd = 10, panDur = 25,
	fadeInTime = 16, fadeOutTime = 6, sustainTime = 12
|
	var hiImpulse, loImpulse, mixed, panner, env;

	hiImpulse = BBandPass.ar(
		Impulse.ar(LFNoise1.ar(hitrigrate).range(hitrigfrom, hitrigto)) * hiamp_scale,
		hifreq, hires, hiamp
	);
	loImpulse = BBandPass.ar(
		Impulse.ar(lorate) * loamp_scale,
		lofreq, lores, loamp
	);
	mixed = hiImpulse + loImpulse;
	panner = LFNoise1.ar(Line.kr(panStart, panEnd, panDur)).range(-1, 1);

	PanAz.ar(8, mixed, panner);
}).play;


NF(\poimsoft, {|
	modFreq = 22, feedb = 0.2, freqFrom = 2000, freqTo = 2010,
	freqMult = 2, driftRate = 0.001, amp = 0.0025,
	fadeInTime = 10, fadeOutTime = 4, sustainTime = 10
|
	var modRatios = [1, 1.2, 1.4, 1.18];
	var sig, env;

	sig = SinOscFB.ar(
		LFNoise1.ar(driftRate).range(freqFrom, freqTo) * freqMult,
		feedb
	).fold2(
		SinOsc.ar(modFreq / modRatios)
	);

	sig * amp;
}).play;


NF(\poibsoft, {|
	rela = 110, hpf = 100, chaosRate = 10, chaosMin = 2.5,
	chaosMax = 3.5, amp1 = 0.004, amp2 = 0.01,
	fadeInTime = 8, fadeOutTime = 6, sustainTime = 11
	|
	var diff = rela + (rela * 0.5);
	var relb = GbmanL.ar(chaosRate).range(chaosMin, chaosMax);
	var diffb = relb + (relb * 1.75);
	var sig1, sig2, env;

	sig1 = SinOsc.ar(
		LFCub.kr([rela + (rela * 0.5), rela], 0, diff * 10, rela * rela),
		0, amp1
	);
	sig2 = SinOsc.ar(
		LFCub.kr([relb + (relb * 0.5), relb, rela * 2, relb * 2], 0, diffb * 10, relb * relb),
		0, amp2
	);

	HPF.ar(sig1 + sig2, hpf);
}).play([4, 5, 6, 7]);

)