// 03-rc.spatial.scd
// The mono material put back into a room. Run 00-rc.load.scd first.
//
// Everything here reads ~gmsmono, because a spatialiser wants a point source.
// The four mono channels of a take are the original four-channel image taken
// apart, so block 5 puts it back together and then starts moving it.
//
// Ambspat / Panspat / Vbspat from the class material are not installed here,
// so these use PanAz, PanB/DecodeB2 and VBAP directly.

( // 1. sixteen outputs, then reboot
s.options.numOutputBusChannels = 16;
s.reboot;
)

( // 2. source
~p = ~rcch.(\clover01, 1);
~take = \yarrow04;

)


///////////////////////// Amplitude panning /////////////////////////

( // 3. PanX runs 0 to 1 around the ring
{ PanX.ar(4, PlayBuf.ar(1, ~p, loop: 1), SinOsc.ar(0.1).range(0, 1)) * 0.5 }.play
)

( // 4. PanAz runs -1 to 1, and has a width: one speaker, then all of them
{ PanAz.ar(4, PlayBuf.ar(1, ~p, loop: 1), SinOsc.ar(0.1).range(-1, 1), 1,
	width: Line.kr(0.5, 4, 30)) * 0.5 }.play.
)

( // 5. the take put back as four points, then turned slowly against the room
{
	var sig = (1..4).collect { |ch| PlayBuf.ar(1, ~rcch.(~take, ch), loop: 1) };
	var spin = LFSaw.kr(0.03).range(-1, 1);
	Mix(sig.collect { |v, i| PanAz.ar(4, v, spin + (i / 2), 1, 1.5) }) * 0.4
}.play
)

( // 6. each channel on its own trajectory: the image comes apart
{
	var sig = (1..4).collect { |ch| PlayBuf.ar(1, ~rcch.(~take, ch), loop: 1) };
	Mix(sig.collect { |v, i|
		PanAz.ar(4, v, LFNoise1.ar(0.05 * (i + 1)).range(-1, 1), 1, 2)
	}) * 0.4
}.play
)

CmdPeriod.run


///////////////////////// Ambisonics /////////////////////////

( // 7. B format, azimuth on a slow oscillator, decoded to four
{
	var w, x, y, z;
	# w, x, y, z = PanB.ar(PlayBuf.ar(1, ~p, loop: 1), SinOsc.ar(0.2).range(-1, 1));
	DecodeB2.ar(4, w, x, y, 0.5) * 0.5
}.play
)

( // 8. to A format and back, filtering each capsule on the way: the colour
  //    changes with the direction
{
	var src = PlayBuf.ar(1, ~p, loop: 1);
	var w, x, y, z, a, b, c, d;
	# w, x, y, z = BFEncode1.ar(src, LFSaw.kr(0.05).range(0, -2pi));
	# a, b, c, d = B2A.ar(w, x, y, z);
	# a, b, c, d = Resonz.ar([a, b, c, d], 440 * [1, 2, 4, 8], 0.1, 5);
	# w, x, y, z = A2B.ar(a, b, c, d);
	DecodeB2.ar(4, w, x, y, 0.5) * 0.4
}.play
)

( // 9. the four channels encoded at four fixed azimuths, the whole field rotated
{
	var azi = LFSaw.kr(0.04) * pi;
	var b = (1..4).collect { |ch|
		PanB.ar(PlayBuf.ar(1, ~rcch.(~take, ch), loop: 1), ((ch - 1) / 2) - 1 + (azi / pi))
	};
	var w = b.collect(_[0]).sum, x = b.collect(_[1]).sum, y = b.collect(_[2]).sum;
	DecodeB2.ar(4, w, x, y, 0.5) * 0.3
}.play
)

CmdPeriod.run


///////////////////////// VBAP /////////////////////////

( // 10. a speaker array, loaded to a buffer once
~speakers = VBAPSpeakerArray(2, [-45, 45, -135, 135]);
~vbuf = ~speakers.loadToBuffer;
)

( // 11. one source around the circle
{
	var src = PlayBuf.ar(1, ~p, loop: 1);
	VBAP.ar(4, src, ~vbuf, LFSaw.kr(0.08).range(-180, 180), 0, 10) * 0.5
}.play
)

( // 12. four sources, spread widening as they separate
{
	var sig = (1..4).collect { |ch| PlayBuf.ar(1, ~rcch.(~take, ch), loop: 1) };
	Mix(sig.collect { |v, i|
		VBAP.ar(4, v, ~vbuf, LFNoise1.kr(0.05 + (i * 0.02)).range(-180, 180), 0,
			Line.kr(5, 60, 40))
	}) * 0.3
}.play
)


///////////////////////// Grains in the room /////////////////////////

( // 13. one grain, one output bus
SynthDef(\rcspatgrain, { |out = 0, buf = 0, dur = 0.05, start = 0, amp = 0.3|
	var env = EnvGen.ar(Env.sine(dur), doneAction: 2);
	OffsetOut.ar(out, PlayBuf.ar(1, buf, BufRateScale.ir(buf), 1, start * BufFrames.ir(buf), 1)
		* env * amp);
}).add;
)

( // 14. the grain stream scattered over four speakers, pointer following clock
Tdef(\rcscatter, {
	var buf = ~p, grains = 10, dur = 0.5, start = Main.elapsedTime;

	loop {
		var now = (Main.elapsedTime - start) / buf.duration;
		var thisDur = dur + 0.1.rand;
		s.bind({
			Synth(\rcspatgrain, [\out, 4.rand, \buf, buf, \dur, thisDur,
				\start, now.wrap(0, 1), \amp, grains.reciprocal * 3]);
		});
		(thisDur * grains.reciprocal).wait;
	};
}).play;
)

( // 15. grain cloud in B format: a new azimuth for every grain
{
	var trig = Impulse.ar(30);
	var grain = GrainBuf.ar(1, trig, 0.12, ~p, 1, TRand.ar(0, 1, trig), 2);
	var w, x, y, z;
	# w, x, y, z = PanB.ar(grain, Demand.ar(trig, 0, Dwhite(-1.0, 1.0)));
	DecodeB2.ar(4, w, x, y, 0.5) * 0.5
}.play
)

CmdPeriod.run


///////////////////////// Spectral space /////////////////////////

( // 16. one band per speaker: the sound is taken apart by frequency, not by
  //     position, and the bands drift against each other
{
	var src = PlayBuf.ar(1, ~p, loop: 1);
	var freqs = [100, 500, 1500, 4000];
	var bw = 0.2;
	freqs.collect { |f, i|
		BBandPass.ar(src, f, bw, SinOsc.ar(0.01 * (i + 1)).range(0, 1))
	} * 6
}.play
)

( // 17. spectral diffusion: two complementary magnitude masks, one per pair
~fftn = 512;
~anal = Buffer.alloc(s, ~fftn, 1);
~analb = Buffer.alloc(s, ~fftn, 1);
~mask1 = Buffer.loadCollection(s, Array.fill(~fftn, { 1.0.linrand }));
~mask2 = Buffer.loadCollection(s, Array.fill(~fftn, { 1.0.linrand }));

SynthDef(\rcdiffuse, { |out = 0, buf = 0, anal, analb, mask1, mask2, amp = 0.5|
	var c1 = FFT(anal, PlayBuf.ar(1, buf, BufRateScale.kr(buf), loop: 1));
	var c2 = PV_Copy(c1, analb);
	Out.ar(out, IFFT([PV_MagMul(c1, mask1), PV_MagMul(c2, mask2)]) * amp);
}).add;
)

( // 18. the same take through two different masks, into two pairs
Synth(\rcdiffuse, [\out, 0, \buf, ~p, \anal, ~anal, \analb, ~analb, \mask1, ~mask1, \mask2, ~mask2]);
Synth(\rcdiffuse, [\out, 2, \buf, ~rcch.(~take, 3), \anal, ~anal, \analb, ~analb,
	\mask1, ~mask2, \mask2, ~mask1]);
)

// redraw the masks while it runs
~mask1.loadCollection(Array.fill(~fftn, { 1.0.linrand }));

CmdPeriod.run
