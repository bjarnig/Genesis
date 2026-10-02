// freq-sets-sharp.scd
// Sharper sets than freq-sets.scd, which stays as it is. These are derived
// from one family or one take rather than from all 248 files, because the
// corpus average has nothing sharp in it: the best any corpus-wide set can do
// is +0.4 dB of local contrast, while a family set reaches +1.9 dB on its own
// material.
//
// Local contrast is the band against its own six-semitone neighbourhood, so it
// says "is there a resonance here" rather than "is there energy here", and
// unlike plain band energy it is not fooled by the material's downward tilt.
//
//   set        corpus   gorse   yarrow   sedge  nettle      distance from the original
//   original    -0.07   -0.76    -0.53   -0.15   -0.22      -
//   yarrow      +0.04   -0.37    +1.08   -0.10   -0.05      mean 113 cents, max 283
//   nettle      +0.24   +0.69    -0.14   -0.15   +1.91      mean 177 cents, max 367
//   sedge       +0.11   -0.27    +0.84   +0.34   -0.10      mean 171 cents, max 389
//   harmonic    -0.02   -0.04    -0.47   -0.26   +0.02      mean  46 cents, max 222
//
// Each family set is sharpest on its own material and flat or worse elsewhere.
// That is what makes them sharp, and what makes them a commitment.
//
// Tools/genesis-corpus/freq-sharp.py

~fsharp = ();

// yarrow, 24 files. The closest of the sharp sets, and +1.08 dB on yarrow.
~fsharp[\yarrow] = [167.27, 281.32, 751.03, 1838.60, 9043.89, 4473.33, 1158.24];

// nettle, 24 files. The strongest result anywhere: +1.91 dB on nettle.
~fsharp[\nettle] = [198.92, 281.32, 1093.24, 1638.00, 8255.03, 4248.46, 1377.39];

// sedge, 16 files. The most agreed-on single mode in the whole corpus: 751 Hz
// is a peak in every one of its files, and 1502 Hz in 62%.
~fsharp[\sedge] = [223.28, 255.19, 751.03, 1735.41, 9537.47, 4768.73, 1502.06];

// gorse06 is strongly periodic: 206 of its 211 peaks sit within 60 cents of a
// harmonic of 50.70 Hz, mean error 17 cents. This is that series, taking the
// harmonic nearest each original frequency (4, 5, 17, 34, 178, 88, 25), so the
// set is exactly harmonic and still the closest to the original of any here.
~fsharp[\harmonic] = [202.80, 253.50, 861.90, 1723.80, 9024.60, 4461.60, 1267.50];
~fsharp[\fundamental] = 50.70;

// the corpus, sharpened as far as it goes: +0.40 dB, four slots moved
~fsharp[\corpus] = [178.38, 275.29, 734.94, 1428.03, 8435.79, 4157.42, 1257.74];

/*  Worth knowing before choosing.

    Sharpness in this material lives below about 2 kHz. On gorse06 the harmonic
    set gains 3 dB over the original, but nearly all of it is one frequency:
    202.8 Hz scores +15.8 dB of contrast. Its 88th and 178th harmonics score
    negative, because up there the harmonics are some 20 cents apart and stop
    being resolvable at all. So the top two or three slots of any set here are
    sitting in noise, whatever value they hold, and only the bottom four can be
    locked to anything.

    A harmonic set is the one to reach for if the patches should ring rather
    than filter: it is coherent by construction, not just well placed.

	~f = ~fsharp[\nettle];
	~wtfreqs = Ora(~f).asArray;
	~bpfreqs = Ora(~f).asArray;
	~f2 = [~f[0], ~f[1], ~f[4], ~f[5]];
*/
