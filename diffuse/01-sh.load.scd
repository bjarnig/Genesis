////////////////////////////////////////////////////////////////
//
//                         LOAD
//
////////////////////////////////////////////////////////////////


s.meter.window.alwaysOnTop_(true)

s.boot


(

{

	// Global variables / Constants
	// [178.38, 255.19, 884.64, 1748.73, 9043.89, 4473.33, 1257.74];


	~pfreqs = [198.92, 281.32, 1093.24, 1638.00, 8255.03, 4248.46, 1377.39];
	     ~f = [198.92, 281.32, 1093.24, 1638.00, 8255.03, 4248.46, 1377.39];
        ~f2 = [198.92, 281.32, 1093.24, 1638.00, 8255.03, 4248.46, 1377.39];
		~wtfreqs = Ora([198.92, 281.32, 1093.24, 1638.00, 8255.03, 4248.46, 1377.39];).asArray;
		~bpfreqs = Ora([198.92, 281.32, 1093.24, 1638.00, 8255.03, 4248.46, 1377.39]).asArray;
		~pfreqs = Ora([198.92, 281.32, 1093.24, 1638.00, 8255.03, 4248.46, 1377.39]).asArray;

	// Wavetables

	~npath = "/Users/bjarni/Dev/nuPG_1.0/Nu_PG_1.0/TABLES/\*";

	~addWt = { |path, dict, name|
		Buffer.read(s, path, action: { |buffer|
			buffer.loadToFloatArray(action: { |array|
				var signal, wavetable;
				try {
					signal = Signal.newFrom(array);
					wavetable = signal.asWavetable;
					{ dict[name.replace(".wav", "")] = Buffer.loadCollection(s, wavetable); s.sync; }.fork;
					("Wavetable complete for:" + name).postln;
				} { |error|
					error.postln;
				}
			});
		});
	};

	~wtb = Dictionary();

	SoundFile.collect(~npath).do { |sf| ~addWt.(sf.path, ~wtb, sf.path.split($/).last) };

    // Create a pulsaret waveform (10 random sine partials)
    ~pulsaret = Signal.sineFill(1024, { 1.0.rand }.dup(10));
    s.sync;
    ~pulsarbuf = Buffer.sendCollection(s, ~pulsaret, 1);

    // Create an envelope buffer for the grain
    ~env = Env.perc.discretize;
    s.sync;
    ~envbuf = Buffer.sendCollection(s, ~env, 1);

    // Complex inharmonic pulsaret
    ~complexPulsaret = Signal.sineFill(1024,
    	Array.fill(20, { |i| if(i.even, { 0 }, { 1.0 / (i + 1).squared }) }) ++ [0.2, 0.15, 0.1, 0.08, 0.05],
    	Array.fill(25, { 2pi.rand })
    );
    s.sync;

	~complexPulsarBuf = Buffer.sendCollection(s, ~complexPulsaret, 1);

    // Advanced pulsar buffers
    ~advPulsaretBuf = Buffer.alloc(s, 2048, 1);
    ~advEnvelopeBuf = Buffer.alloc(s, 2048, 1);
    s.sync;
    ~advPulsaretBuf.sine1([1.0], asWavetable: false);
    ~advEnvelopeBuf.sine1([1.0], asWavetable: false);

    s.sync;

	Ora.addSynths;

	// ORA extras

	SynthDef(\drcl, { |out=0, freq=440, amp=0.07, dur=0.04, pan=0|
		var env = EnvGen.ar(Env([0.0,1.0,0.25,0.0],[0.008,0.1,0.2]), doneAction: 2);
		var sig = FSinOsc.ar(freq, 0.5pi) * amp * env * SinOsc.ar(5).range(0.0,1.0);
		sig = sig * SinOsc.ar(25).range(0.8,1.0);
		Out.ar(out, sig);
	}).add;

	SynthDef(\drclshort, { |out=0, freq=440, amp=0.07, dur=0.04, pan=0|
		var env = EnvGen.ar(Env([0.0,1.0,0.0],[0.009,0.2]), doneAction: 2);
		var sig = FSinOsc.ar(freq, 0.5pi) * amp * env * SinOsc.ar(10).range(0.5,1.0);
		Out.ar(out, sig);
	}).add;


    // Basic pulsar
    SynthDef(\pulsar, { |out=0, fund=10, form=100, amp=1.0, wavebuf, envbuf|
    	var trig = Impulse.ar(fund);
    	var grdur = form.reciprocal;
    	var rate = form * BufDur.kr(wavebuf);
    	Out.ar(out, GrainBuf.ar(1, trig, grdur, wavebuf, rate, 0, 4, 0, envbuf, mul: amp));
    }).add;

    // Pulsar with comb resonator tuned to an Ora frequency
    SynthDef(\pulsarComb, { |out=0, fund=10, form=100, amp=0.5, wavebuf, envbuf,
    	combFreq=440, combDecay=0.5, combMix=0.5, hpf=30|
    	var trig = Impulse.ar(fund);
    	var grdur = form.reciprocal;
    	var rate = form * BufDur.kr(wavebuf);
    	var sig = GrainBuf.ar(1, trig, grdur, wavebuf, rate, 0, 4, 0, envbuf, mul: amp);
    	var delayTime = (1 / combFreq).clip(0.00005, 0.05);
    	var resonated = CombL.ar(sig, 0.05, delayTime, combDecay);
    	var mix = (sig * (1 - combMix)) + (resonated * combMix);
    	Out.ar(out, LeakDC.ar(HPF.ar(mix, hpf)));
    }).add;

    // Pulsar with Ringz resonator + modulated notch to tame high clicks
    SynthDef(\pulsarRingz, { |out=0, fund=10, form=100, amp=0.3, wavebuf, envbuf,
    	ringFreq=440, ringDecay=0.15, ringMix=0.4,
    	notchFreq=4000, notchBW=4, notchModRate=0.3, notchModDepth=800|
    	var trig = Impulse.ar(fund);
    	var grdur = form.reciprocal;
    	var rate = form * BufDur.kr(wavebuf);
    	var sig = GrainBuf.ar(1, trig, grdur, wavebuf, rate, 0, 4, 0, envbuf, mul: amp);
    	var notchCenter = notchFreq + LFNoise2.ar(notchModRate, notchModDepth);
    	var resonated;
    	// Wandering notch around 4kHz before the resonator
    	sig = BBandStop.ar(sig, notchCenter.clip(200, 12000), notchBW);
    	resonated = Ringz.ar(sig, ringFreq.clip(40, 16000), ringDecay);
    	Out.ar(out, LeakDC.ar((sig * (1 - ringMix)) + (resonated * ringMix)));
    }).add;

	// - SynthDefs -

    // Pulsar with BBandPass filter at Ora frequency
    SynthDef(\pulsarBPF, { |out=0, fund=10, form=100, amp=0.5, wavebuf, envbuf,
    	bpFreq=440, bpRQ=0.1|
    	var trig = Impulse.ar(fund);
    	var grdur = form.reciprocal;
    	var rate = form * BufDur.kr(wavebuf);
    	var sig = GrainBuf.ar(1, trig, grdur, wavebuf, rate, 0, 4, 0, envbuf, mul: amp);
    	Out.ar(out, BBandPass.ar(sig, bpFreq, bpRQ, 4));
    }).add;

    // Pulsar with fold + comb
    SynthDef(\pulsarFoldComb, { |out=0, fund=10, form=100, amp=0.5, wavebuf, envbuf,
    	combFreq=440, combDecay=0.3, combMix=0.4, foldFreq=25|
    	var trig = Impulse.ar(fund);
    	var grdur = form.reciprocal;
    	var rate = form * BufDur.kr(wavebuf);
    	var sig = GrainBuf.ar(1, trig, grdur, wavebuf, rate, 0, 4, 0, envbuf, mul: amp);
    	var delayTime = (1 / combFreq).clip(0.00005, 0.05);
    	var folded, resonated;
    	folded = sig.fold2(SinOsc.ar(foldFreq) * 0.5);
    	resonated = CombL.ar(folded, 0.05, delayTime, combDecay);
    	Out.ar(out, HPF.ar((folded * (1 - combMix)) + (resonated * combMix), 40));
    }).add;

    // Advanced pulsar with multichannel output
    SynthDef(\pulsarAdv, {
    	arg pulBuf, envBuf, out=0,
    	trigFreq = 50.0, grainFreq = 1.0,
    	fmRatio = 1.0, fmAmt = 0.0,
    	fluxAmt = 0.0, fluxRate = 40.0,
    	probability = 1.0, burst = 5, rest = 0,
    	pan = 0, chanMask = 0, centerMask = 1,
    	combFreq = 440, combDecay = 0.3, combMix = 0.0,
    	amp = 0.5;

    	var trig, grain, rate, grainDur, sig, channelMask, delayTime, resonated;

    	grain = trigFreq * grainFreq;
    	grain = grain * LFDNoise3.ar(fluxRate, fluxAmt, 1).lag(0.5);
    	grainDur = grain.reciprocal;

    	trig = Impulse.ar(
    		trigFreq * LFDNoise3.kr(fluxRate, fluxAmt * 0.5, 1).lag(0.5)
    	);

    	trig = trig * CoinGate.ar(probability, trig);
    	trig = trig * Demand.ar(trig, 1, Dseq([Dser([1], burst), Dser([0], rest)], inf));

    	rate = grain * (2048 / SampleRate.ir);
    	rate = rate * (1 + (SinOsc.ar(grain * fmRatio) * fmAmt * 0.1));

    	channelMask = Demand.ar(trig, 0, Dseq([
    		Dser([-1], chanMask),
    		Dser([1], chanMask),
    		Dser([0], centerMask)
    	], inf)).lag(0.01);

    	pan = (pan + channelMask).clip(-1, 1);

    	sig = GrainBuf.ar(
    		numChannels: 1,
    		trigger: trig, dur: grainDur,
    		sndbuf: pulBuf, rate: rate,
    		pos: 0, interp: 4, pan: 0,
    		envbufnum: envBuf, maxGrains: 512, mul: amp
    	);

    	// Optional comb resonator at Ora frequency
    	delayTime = (1 / combFreq).clip(0.00005, 0.05);
    	resonated = CombL.ar(sig, 0.05, delayTime, combDecay);
    	sig = (sig * (1 - combMix)) + (resonated * combMix);

    	Out.ar(out, LeakDC.ar(sig));
    }).add;

	// stereo
	~s1 = Buffer.read(s,"/Users/bjarni/Works/Archive/textures/drones/long/tsl_oboe_tuneb.wav");
	~s2 = Buffer.read(s,"/Users/bjarni/Works/Archive/textures/dust/gestfin.wav");
	~s3 = Buffer.read(s,"/Users/bjarni/Works/Archive/textures/context/Bl08/blb8b.wav");
	~s4 = Buffer.read(s,"/Users/bjarni/Works/Archive/textures/context/Bl03/blb3a.wav");
	~s5 = Buffer.read(s,"/Users/bjarni/Works/Archive/textures/context/Bl01/blb1c.wav");

	// mono
	~s1m = Buffer.readChannel(s, "/Users/bjarni/Works/Archive/textures/drones/long/tsl_oboe_tuneb.wav", channels:[0]);
	~s2m = Buffer.readChannel(s, "/Users/bjarni/Works/Archive/textures/dust/gestfin.wav", channels:[0]);
	~s3m = Buffer.readChannel(s, "/Users/bjarni/Works/Archive/textures/context/Bl08/blb8b.wav", channels:[0]);
	~s4m = Buffer.readChannel(s, "/Users/bjarni/Works/Archive/textures/context/Bl03/blb3a.wav", channels:[0]);
	~s5m = Buffer.readChannel(s, "/Users/bjarni/Works/Archive/textures/context/Bl01/blb1c.wav", channels:[0]);

    "Ora.Shift.Ready!".postln

}.fork;

)

s.reboot

(

	{
		// Create a pulsaret waveform (10 random sine partials)
		~pulsaret = Signal.sineFill(1024, { 1.0.rand }.dup(10));
		s.sync;
		~pulsarbuf = Buffer.sendCollection(s, ~pulsaret, 1);

		// Create an envelope buffer for the grain
		~env = Env.perc.discretize;
		s.sync;
		~envbuf = Buffer.sendCollection(s, ~env, 1);

		// Complex inharmonic pulsaret
		~complexPulsaret = Signal.sineFill(1024,
			Array.fill(20, { |i| if(i.even, { 0 }, { 1.0 / (i + 1).squared }) }) ++ [0.2, 0.15, 0.1, 0.08, 0.05],
			Array.fill(25, { 2pi.rand })
		);
		s.sync;
		~complexPulsarBuf = Buffer.sendCollection(s, ~complexPulsaret, 1);

		// Advanced pulsar buffers
		~advPulsaretBuf = Buffer.alloc(s, 2048, 1);
		~advEnvelopeBuf = Buffer.alloc(s, 2048, 1);
		s.sync;
		~advPulsaretBuf.sine1([1.0], asWavetable: false);
		~advEnvelopeBuf.sine1([1.0], asWavetable: false);

		s.sync;

		// ---- SynthDefs ----

		// Basic pulsar
		SynthDef(\pulsar, { |out=0, fund=10, form=100, amp=1.0, wavebuf, envbuf|
			var trig = Impulse.ar(fund);
			var grdur = form.reciprocal;
			var rate = form * BufDur.kr(wavebuf);
			Out.ar(out, GrainBuf.ar(1, trig, grdur, wavebuf, rate, 0, 4, 0, envbuf, mul: amp));
		}).add;

		// Pulsar with comb resonator tuned to an Ora frequency
		SynthDef(\pulsarComb, { |out=0, fund=10, form=100, amp=0.5, wavebuf, envbuf,
			combFreq=440, combDecay=0.5, combMix=0.5, hpf=30|
			var trig = Impulse.ar(fund);
			var grdur = form.reciprocal;
			var rate = form * BufDur.kr(wavebuf);
			var sig = GrainBuf.ar(1, trig, grdur, wavebuf, rate, 0, 4, 0, envbuf, mul: amp);
			var delayTime = (1 / combFreq).clip(0.00005, 0.05);
			var resonated = CombL.ar(sig, 0.05, delayTime, combDecay);
			var mix = (sig * (1 - combMix)) + (resonated * combMix);
			Out.ar(out, LeakDC.ar(HPF.ar(mix, hpf)));
		}).add;

		// Pulsar with Ringz resonator + modulated notch to tame high clicks
		SynthDef(\pulsarRingz, { |out=0, fund=10, form=100, amp=0.3, wavebuf, envbuf,
			ringFreq=440, ringDecay=0.15, ringMix=0.4,
			notchFreq=4000, notchBW=4, notchModRate=0.3, notchModDepth=800|
			var trig = Impulse.ar(fund);
			var grdur = form.reciprocal;
			var rate = form * BufDur.kr(wavebuf);
			var sig = GrainBuf.ar(1, trig, grdur, wavebuf, rate, 0, 4, 0, envbuf, mul: amp);
			var notchCenter = notchFreq + LFNoise2.ar(notchModRate, notchModDepth);
			var resonated;
			// Wandering notch around 4kHz before the resonator
			sig = BBandStop.ar(sig, notchCenter.clip(200, 12000), notchBW);
			resonated = Ringz.ar(sig, ringFreq.clip(40, 16000), ringDecay);
			Out.ar(out, LeakDC.ar((sig * (1 - ringMix)) + (resonated * ringMix)));
		}).add;

		// Pulsar with BBandPass filter at Ora frequency
		SynthDef(\pulsarBPF, { |out=0, fund=10, form=100, amp=0.5, wavebuf, envbuf,
			bpFreq=440, bpRQ=0.1|
			var trig = Impulse.ar(fund);
			var grdur = form.reciprocal;
			var rate = form * BufDur.kr(wavebuf);
			var sig = GrainBuf.ar(1, trig, grdur, wavebuf, rate, 0, 4, 0, envbuf, mul: amp);
			Out.ar(out, BBandPass.ar(sig, bpFreq, bpRQ, 4));
		}).add;

		// Pulsar with fold + comb
		SynthDef(\pulsarFoldComb, { |out=0, fund=10, form=100, amp=0.5, wavebuf, envbuf,
			combFreq=440, combDecay=0.3, combMix=0.4, foldFreq=25|
			var trig = Impulse.ar(fund);
			var grdur = form.reciprocal;
			var rate = form * BufDur.kr(wavebuf);
			var sig = GrainBuf.ar(1, trig, grdur, wavebuf, rate, 0, 4, 0, envbuf, mul: amp);
			var delayTime = (1 / combFreq).clip(0.00005, 0.05);
			var folded, resonated;
			folded = sig.fold2(SinOsc.ar(foldFreq) * 0.5);
			resonated = CombL.ar(folded, 0.05, delayTime, combDecay);
			Out.ar(out, HPF.ar((folded * (1 - combMix)) + (resonated * combMix), 40));
		}).add;

		// Advanced pulsar with multichannel output
		SynthDef(\pulsarAdv, {
			arg pulBuf, envBuf, out=0,
			trigFreq = 50.0, grainFreq = 1.0,
			fmRatio = 1.0, fmAmt = 0.0,
			fluxAmt = 0.0, fluxRate = 40.0,
			probability = 1.0, burst = 5, rest = 0,
			pan = 0, chanMask = 0, centerMask = 1,
			combFreq = 440, combDecay = 0.3, combMix = 0.0,
			amp = 0.5;

			var trig, grain, rate, grainDur, sig, channelMask, delayTime, resonated;

			grain = trigFreq * grainFreq;
			grain = grain * LFDNoise3.ar(fluxRate, fluxAmt, 1).lag(0.5);
			grainDur = grain.reciprocal;

			trig = Impulse.ar(
				trigFreq * LFDNoise3.kr(fluxRate, fluxAmt * 0.5, 1).lag(0.5)
			);

			trig = trig * CoinGate.ar(probability, trig);
			trig = trig * Demand.ar(trig, 1, Dseq([Dser([1], burst), Dser([0], rest)], inf));

			rate = grain * (2048 / SampleRate.ir);
			rate = rate * (1 + (SinOsc.ar(grain * fmRatio) * fmAmt * 0.1));

			channelMask = Demand.ar(trig, 0, Dseq([
				Dser([-1], chanMask),
				Dser([1], chanMask),
				Dser([0], centerMask)
			], inf)).lag(0.01);

			pan = (pan + channelMask).clip(-1, 1);

			sig = GrainBuf.ar(
				numChannels: 1,
				trigger: trig, dur: grainDur,
				sndbuf: pulBuf, rate: rate,
				pos: 0, interp: 4, pan: 0,
				envbufnum: envBuf, maxGrains: 512, mul: amp
			);

			// Optional comb resonator at Ora frequency
			delayTime = (1 / combFreq).clip(0.00005, 0.05);
			resonated = CombL.ar(sig, 0.05, delayTime, combDecay);
			sig = (sig * (1 - combMix)) + (resonated * combMix);

			Out.ar(out, LeakDC.ar(sig));
		}).add;

		"Pulsar synthesis (Ora-driven) ready!".postln;
	}.fork;

	)









	0. VERY GOOD! Variations needed, so more examples in the helpfiles would be great.

{ Cyclegen.ar(120, ampStep: 0.38, stiffness: 0.05, templateType: 1, seqMode: 2, freqs: [110, 147, 165, 220]* LFNoise0.kr(0.1).range(0.5, 1.5)) * 0.2 ! 2 }.play;

{ Ecostoch.ar(8, 1, 1, MouseX.kr(0.3, 4), 1600, 5)[0] * 0.2 ! 2 }.play;

1. MORE work needed:

// a bit useless, needs more chaos
{ Limcycle.ar(80, 5, 0, 0, MouseX.kr(0, 8000), 120, 0, 2, 12)[0] * 0.2 ! 2 }.play;

// to much gendy, let's ditch the randomwalk for something more chaotic
{ Gendreve.ar(100, 400, 12, MouseX.kr(0,1), MouseY.kr(0,1), 0.3, 0.3)[0] * 0.2 ! 2 }.play;

// to much gendy, let's ditch the randomwalk for something more chaotic
{ Diststoch.ar(80, 200, 14, ampDist: 1, ampStep: 0.25, ampLo: -0.6, barrierHi: 2) * 0.2 ! 2 }.play;


2. Please remove the comments from the helpfiles.


3. Update the README, use the following

Limcycle : relaxation with stochastic forcing.


Cyclegen : a frequency sequence sets pitch per cycle.
Chaosgen : breakpoint values driven by a logistic map.
Varperiod : live control-point count for timbral density.
Fracflight : mean-reverting walk with fractional motion.
Grainstoch : an emission pitch carrying walking grains.
Probstoch : sparse grains on a fixed-pitch waveform.

Oscnet : coupled-oscillator network with selectable topology and nonlinear feedback.
Ecostoch : predator-prey population synthesis.
Scangen : scanned synthesis on a dynamic mass-spring lattice.
Lifestoch : ALife birth-death breakpoint population.

Please keep all comments in the helpfiles super minimal and even none since we are still in development and experimenting