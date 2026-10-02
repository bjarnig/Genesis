
////////////////////////////////////////////////////////////////
//
//                      DYNMC NOISE
//
////////////////////////////////////////////////////////////////

(

SynthDef(\dynamicNoiseBandpass, {|
	wfMult = 0.2,
	amp = 0.5,
	seqMult = 8,
	envMin = -0.1, envMax = 0.1,
	bpQ = 0.1,
	xlineStart = 0.5, xlineEnd = 8.0,
	xlineTimeMin = 10, xlineTimeMax = 25
|
	var bpFreqs = ~f; // Array.geom(6, rrand(120,170), rrand(1.5,2.5));
	var sd = SampleDur.ir * wfMult;
	var sig, xlineTimes;

	sig = DemandEnvGen.ar(
		Dseq([envMin, envMax], inf),
		Dseq([sd * seqMult, sd * 8 * seqMult, sd * Dwhite(seqMult * 6, seqMult * 9, inf)], inf)
	);

	xlineTimes = { rrand(xlineTimeMin, xlineTimeMax) } ! 6;
	sig = BBandPass.ar(sig, bpFreqs, bpQ) * XLine.ar(xlineStart, xlineEnd, xlineTimes);
	sig = sig * EnvGen.ar(Env([1,1,0], [xlineTimeMax*0.8, 10]), doneAction:2);

	sig = sig * EnvGen.ar(Env([0,1,0], [2,25]),doneAction:2);

	Out.ar(0, sig.scramble * amp);
}).play;

)


( // VAR A with fade-out - Simple dynamic noise

SynthDef(\dynamicNoiseSimpleFade, {|
	wfMult = 0.2,
	amp = 0.2,
	seqMult = 8,
	envMin = -0.1, envMax = 0.1,
	fadeInTime = 20,
	fadeInStart = 0.001, fadeInEnd = 1.0,
	sustainTime = 25, fadeOutTime = 12,
	hpfStart = 20, hpfEnd = 8000
|
	var sd = SampleDur.ir * wfMult;
	var sig, ampEnv, hpfEnv;

	sig = DemandEnvGen.ar(
		Dseq([envMin, envMax], inf),
		Dseq([sd * seqMult, sd * ({ rrand(6, 10) } ! 8) * seqMult, sd * Dwhite(seqMult * 6, seqMult * 9, inf)], inf)
	) * XLine.ar(fadeInStart, fadeInEnd, fadeInTime);

	ampEnv = EnvGen.kr(Env([1, 1, 0], [sustainTime, fadeOutTime], \sin), doneAction: 2);
	hpfEnv = EnvGen.kr(Env([hpfStart, hpfStart, hpfEnd], [sustainTime, fadeOutTime], \exp));

	sig = HPF.ar(sig, hpfEnv);
	Out.ar(0, sig.scramble * amp * ampEnv);
}).play;

SynthDef(\dynamicNoiseBandpassFade, {|
	wfMult = 0.2,
	amp = 0.2,
	seqMult = 8,
	envMin = -0.1, envMax = 0.1,
	bpQ = 0.1,
	xlineStart = 0.5, xlineEnd = 8.0,
	xlineTimeMin = 10, xlineTimeMax = 25,
	sustainTime = 25, fadeOutTime = 12,
	hpfStart = 20, hpfEnd = 8000
|
	var bpFreqs = ~f;// Array.geom(6, rrand(120,170), rrand(1.5,2.5));
	var sd = SampleDur.ir * wfMult;
	var sig, xlineTimes, ampEnv, hpfEnv;

	sig = DemandEnvGen.ar(
		Dseq([envMin, envMax], inf),
		Dseq([sd * seqMult, sd * 8 * seqMult, sd * Dwhite(seqMult * 6, seqMult * 9, inf)], inf)
	);

	xlineTimes = { rrand(xlineTimeMin, xlineTimeMax) } ! 6;
	sig = BBandPass.ar(sig, bpFreqs, bpQ) * XLine.ar(xlineStart, xlineEnd, xlineTimes);

	ampEnv = EnvGen.kr(Env([1, 1, 0], [sustainTime, fadeOutTime], \sin), doneAction: 2);
	hpfEnv = EnvGen.kr(Env([hpfStart, hpfStart, hpfEnd], [sustainTime, fadeOutTime], \exp));

	sig = HPF.ar(sig, hpfEnv);
	Out.ar(8, sig.scramble * amp * ampEnv);
}).play;

)

( // VAR A - Simple dynamic noise

SynthDef(\dynamicNoiseSimple, {|
	wfMult = 0.2,
	amp = 0.5,
	seqMult = 8,
	envMin = -0.1, envMax = 0.1,
	fadeInTime = 20,
	fadeInStart = 0.001, fadeInEnd = 1.0
|
	var sd = SampleDur.ir * wfMult;
	var sig;

	sig = DemandEnvGen.ar(
		Dseq([envMin, envMax], inf),
		Dseq([sd * seqMult, sd * ({ rrand(6, 10) } ! 8) * seqMult, sd * Dwhite(seqMult * 6, seqMult * 9, inf)], inf)
	) * XLine.ar(fadeInStart, fadeInEnd, fadeInTime);

	Out.ar(0, sig * amp);
}).play;

)



( // VAR B - Bandpassed dynamic noise

	SynthDef(\dynamicNoiseBandpass, {|
		wfMult = 0.2,
		amp = 0.5,
		seqMult = 8,
		envMin = -0.1, envMax = 0.1,
		bpQ = 0.1,
		xlineStart = 0.5, xlineEnd = 8.0,
		xlineTimeMin = 10, xlineTimeMax = 25
	|
		var bpFreqs = [178.38, 255.19, 884.64, 1748.73, 9043.89, 4473.33, 1257.74];// Array.geom(6, rrand(120,170), rrand(1.5,2.5));
		var sd = SampleDur.ir * wfMult;
		var sig, xlineTimes;

		sig = DemandEnvGen.ar(
			Dseq([envMin, envMax], inf),
			Dseq([sd * seqMult, sd * 8 * seqMult, sd * Dwhite(seqMult * 6, seqMult * 9, inf)], inf)
		);

		xlineTimes = { rrand(xlineTimeMin, xlineTimeMax) } ! 6;
		sig = BBandPass.ar(sig, bpFreqs, bpQ) * XLine.ar(xlineStart, xlineEnd, xlineTimes);
		sig = sig * EnvGen.ar(Env([1,1,0], [xlineTimeMax*0.8, 10]), doneAction:2);

		Out.ar(0, sig.scramble * amp);
	}).play;

	)


	( // VAR B with fade-out - Bandpassed dynamic noise

	SynthDef(\dynamicNoiseBandpassFade, {|
		wfMult = 0.2,
		amp = 0.5,
		seqMult = 8,
		envMin = -0.1, envMax = 0.1,
		bpQ = 0.1,
		xlineStart = 0.5, xlineEnd = 8.0,
		xlineTimeMin = 10, xlineTimeMax = 25,
		sustainTime = 25, fadeOutTime = 12,
		hpfStart = 20, hpfEnd = 8000
		|
		var bpFreqs = [178.38, 255.19, 884.64, 1748.73, 9043.89, 4473.33, 1257.74] * 0.125;
		var sd = SampleDur.ir * wfMult;
		var sig, xlineTimes, ampEnv, hpfEnv;

		sig = DemandEnvGen.ar(
			Dseq([envMin, envMax], inf),
			Dseq([sd * seqMult, sd * 8 * seqMult, sd * Dwhite(seqMult * 6, seqMult * 9, inf)], inf)
		);

		xlineTimes = { rrand(xlineTimeMin, xlineTimeMax) } ! 6;
		sig = BBandPass.ar(sig, bpFreqs, bpQ) * XLine.ar(xlineStart, xlineEnd, xlineTimes);

		ampEnv = EnvGen.kr(Env([1, 1, 0], [sustainTime, fadeOutTime], \sin), doneAction: 2);
		hpfEnv = EnvGen.kr(Env([hpfStart, hpfStart, hpfEnd], [sustainTime, fadeOutTime], \exp));

		sig = HPF.ar(sig, hpfEnv);
		Out.ar(0, sig.scramble * amp * ampEnv);
	}).play;

	)
	