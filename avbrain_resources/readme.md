# AV Brain Pattern
Author: 

The AVBrainPattern provides a simple rate model of neural activity within the brain, with real structural connectivity values and plausible time delay values between sources in the brain. Sources are mapped to the Brainlove surface using an EEG forward model. Audio input is applied to random sources in the brain (in a rather unsophisticated way).

UI Parameters:
* S: Noise in the model
* SPD: How many time steps to simulate during each run() call. Increase at the cost of FPS
* VOL: weighting of auditory input
* K: overall connectivity of brain regions
* HSS: speed at which the hue dimension moves

Flaws:
Tends to get stuck in a stable state. Play with the noise level.

