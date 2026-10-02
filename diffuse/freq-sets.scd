// freq-sets.scd
// Frequency sets derived from the Genesis mono material, for the set that
// 01-sh.load.scd hands to ~f / ~wtfreqs / ~bpfreqs.
//
// Method: 3436 spectral peaks were collected from 235 of the 248 mono files
// (peaks per file, pooled afterwards: averaging whole spectra over a corpus
// this mixed flattens them to nothing). The peaks pile up into 33 modes. Each
// set below moves the original seven onto those modes, and the comment gives
// the distance in cents, because that is the only honest way to say near.
//
// Support is modest: the strongest mode appears in 19% of files. This material
// has tendencies, not tonal centres, so none of these is a large change.
//
// Tools/genesis-corpus/freq-sets.py, freq-validate.py, freq-minimal.py

~fset = ();

// as it stands, for comparison
~fset[\original] = [178.38, 255.19, 884.64, 1748.73, 9043.89, 4473.33, 1257.74];

// A. three slots nudged onto modes, four untouched.
//    mean 25 cents, max 67. Drop-in: nothing about the piece changes.
~fset[\tight] = [178.38, 255.19, 919.30, 1686.00, 9043.89, 4473.33, 1227.12];

// B. every slot on a mode of the material, register layout intact.
//    mean 178 cents, max 283 (2.8 semitones). The actual re-tuning.
~fset[\near] = [198.92, 281.32, 751.03, 1502.06, 8255.03, 4127.51, 1227.12];

// C. the whole set transposed bodily by -542 cents, every interval exact.
//    The material sits about a fifth below this set all the way up, so this
//    keeps the shape and moves it to where the material lives.
~fset[\shifted] = [130.43, 186.59, 646.85, 1278.67, 6612.87, 3270.89, 919.66];

// the four-element subset, no middle, following whichever set is in use
~fsub = { |set| [set[0], set[1], set[4], set[5]] };

/*  to use one, in 01-sh.load.scd:

	~f = ~fset[\near];
	~wtfreqs = Ora(~f).asArray;
	~bpfreqs = Ora(~f).asArray;
	~f2 = ~fsub.(~f);

    The 9 kHz slot is the weakest in every set: the material has little up
    there (-28.5 dB relative to its own broadband mean, against -3.6 dB at
    178 Hz). Its nearest supported mode is 6184 Hz, which is the single
    largest per-slot improvement available, +3.8 dB, at -658 cents.
*/
