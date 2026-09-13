// fern
NF('fern').set(\lfnFreq, 0.03, \repeats, 9.0, \freqMult, 0.358, \ampStep, 0.804, \stiffness, 0.167, \ampStepB, 1.0, \stiffnessB, 0.047, \harmScale, 0.041, \detuneHi, 0.218, \detuneLo, 0.1278, \amp, 0.857);
NF('fern').set(\lfnFreq, 0.05, \repeats, 9.0, \freqMult, 0.988, \ampStep, 0.602, \stiffness, 0.415, \ampStepB, 0.289, \stiffnessB, 0.985, \harmScale, 0.056, \detuneHi, 2.362, \detuneLo, 0.5291, \amp, 0.612);


// gorse
NF('gorse').set(\a, 0.75, \b, 0.18, \c, 0.97, \sawFreq, 22.01, \feedback, 1.0, \delay, 0.03, \aa, 1.33, \bb, 29.37, \peakFreq, 2416.54, \hpf, 2078.45, \amp, 0.02);
NF('gorse').set(\a, 0.35, \b, 0.87, \c, 0.04, \sawFreq, 20.78, \feedback, 1.0, \delay, 0.0, \aa, 1.63, \bb, 18.32, \peakFreq, 527.95, \hpf, 433.62, \amp, 0.13);
NF('gorse').set(\a, 0.45, \b, 0.54, \c, 0.23, \sawFreq, 113.01, \feedback, 0.99, \delay, 0.03, \aa, 16.04, \bb, 3.33, \peakFreq, 1725.9, \hpf, 5212.67, \amp, 0.54);
NF('gorse').set(\a, 0.21, \b, 0.3, \c, 0.8, \sawFreq, 123.0, \feedback, 1.0, \delay, 0.03, \aa, 8.53, \bb, 2.53, \peakFreq, 1100.46, \hpf, 3215.49, \amp, 0.11);
NF('gorse').set(\a, 0.17, \b, 0.69, \c, 0.13, \sawFreq, 140.28, \feedback, 1.0, \delay, 0.01, \aa, 6.01, \bb, 6.02, \peakFreq, 3583.55, \hpf, 486.62, \amp, 0.7);

// bramble
NF('bramble').set(\sdm, 3.93, \repeats, 2.0, \from, 3.68, \to, 13.86, \mod, 2.58, \rate, 2.66, \trigMin, 13.79, \trigMax, 285.26, \freq, 1204.78, \mf, 0.02, \bw, 1.1, \hpf, 191.38, \amp, 0.7);
NF('bramble').set(\sdm, 1.93, \repeats, 11.0, \from, 14.44, \to, 7.5, \mod, 1.55, \rate, 3.97, \trigMin, 17.16, \trigMax, 796.74, \freq, 464.81, \mf, 0.36, \bw, 3.14, \hpf, 95.53, \amp, 0.7);
NF('bramble').set(\sdm, 6.22, \repeats, 10.0, \from, 10.03, \to, 54.53, \mod, 78.19, \rate, 13.21, \trigMin, 168.56, \trigMax, 722.21, \freq, 563.96, \mf, 0.13, \bw, 10.46, \hpf, 505.92, \amp, 0.7);
NF('bramble').set(\sdm, 3.34, \repeats, 12.0, \from, 1.43, \to, 12.52, \mod, 53.02, \rate, 14.15, \trigMin, 110.85, \trigMax, 1348.17, \freq, 100.0, \mf, 0.39, \bw, 5.67, \hpf, 64.15, \amp, 0.7);
NF('bramble').set(\sdm, 0.28, \repeats, 4.0, \from, 3.0, \to, 7.81, \mod, 8.85, \rate, 0.77, \trigMin, 35.97, \trigMax, 329.53, \freq, 773.75, \mf, 0.14, \bw, 1.27, \hpf, 303.04, \amp, 0.7);


// sedge
NF('sedge').set(\sdm, 10.02, \ffrom, 2.44, \fto, 58.65, \noiseRate, 49.28, \bsRate, 4.81, \bsLo, 549.61, \bsHi, 378.65, \frequencyB, 0.224, \surface, 0.416, \lop, 1175.97, \hip, 201.94, \hpf, 445.27, \lopVol, 0.126, \hipVol, 0.393, \amp, 0.794);
NF('sedge').set(\sdm, 2.27, \ffrom, 7.06, \fto, 18.8, \noiseRate, 22.75, \bsRate, 0.119, \bsLo, 795.16, \bsHi, 2299.52, \frequencyB, 0.506, \surface, 0.22, \lop, 12557.65, \hip, 106.52, \hpf, 46.18, \lopVol, 0.457, \hipVol, 0.463, \amp, 0.794);
NF('sedge').set(\sdm, 1.3, \ffrom, 10.78, \fto, 10.28, \noiseRate, 200.0, \bsRate, 0.352, \bsLo, 130.51, \bsHi, 361.24, \frequencyB, 0.135, \surface, 0.196, \lop, 1385.58, \hip, 27.86, \hpf, 75.3, \lopVol, 0.56, \hipVol, 0.816, \amp, 0.794);
NF('sedge').set(\sdm, 8.15, \ffrom, 67.21, \fto, 263.61, \noiseRate, 60.56, \bsRate, 1.284, \bsLo, 304.11, \bsHi, 1159.88, \frequencyB, 0.431, \surface, 0.479, \lop, 12858.62, \hip, 55.25, \hpf, 351.6, \lopVol, 0.105, \hipVol, 0.516, \amp, 0.794);
NF('sedge').set(\sdm, 4.77, \ffrom, 27.62, \fto, 184.22, \noiseRate, 26.04, \bsRate, 3.822, \bsLo, 2894.58, \bsHi, 1426.11, \frequencyB, 0.905, \surface, 0.637, \lop, 4120.74, \hip, 32.55, \hpf, 65.99, \lopVol, 0.725, \hipVol, 0.911, \amp, 0.794);
NF('sedge').set(\sdm, 3.15, \ffrom, 2.74, \fto, 95.98, \noiseRate, 15.66, \bsRate, 0.244, \bsLo, 250.07, \bsHi, 1072.09, \frequencyB, 0.637, \surface, 0.917, \lop, 1727.16, \hip, 26.91, \hpf, 98.45, \lopVol, 0.577, \hipVol, 0.594, \amp, 0.794);
NF('sedge').set(\sdm, 1.09, \ffrom, 13.23, \fto, 295.15, \noiseRate, 18.59, \bsRate, 0.06, \bsLo, 708.56, \bsHi, 201.6, \frequencyB, 0.722, \surface, 0.222, \lop, 1515.35, \hip, 257.0, \hpf, 94.03, \lopVol, 0.153, \hipVol, 0.0, \amp, 1.0);



// nettle
NF('nettle').set(\a, 0.712, \b, 0.0, \c, 0.738, \pmFreq, 30.23, \modFrom, 72.85, \wobLo, 813.99, \wobHi, 3059.0, \filtLo, 7170.86, \filtHi, 16511.64, \hpf, 342.3, \demGain, 1.46, \amp, 0.776);



/*

Not ready

teasel
NF('teasel').set(\modRate, 6.06, \modFrom, 664.29, \modTo, 6694.05, \peakFreq, 937.54, \lpf, 312.22, \hpf, 119.4, \sparkleGain, 0.87, \demGain, 6.65, \amp, 0.52);

yarrow
Ndef('yarrow').set(\fspeed, 7.46, \fcenter, 1105.99, \sdm, 0.2, \mfreq, 0.0, \filtBw, 24.88, \modFreq, 16.94, \harms, 88.42, \drive, 3.0, \bsRate, 1.66, \bsLo, 549.39, \bsHi, 1871.54, \lpf, 6711.87, \hpf, 62.9, \amp, 0.87);

*/
