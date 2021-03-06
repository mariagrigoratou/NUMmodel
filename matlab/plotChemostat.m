%
% Makes a series of plot of a chemostat run.
%
function plotChemostat(sim)

clf
%
% Size spectrum:
%
subplot(4,1,1)
panelSpectrum(sim)
xlabel('')
%
% Rates:
%
subplot(4,1,2)
panelGains(sim.p, sim.rates)

subplot(4,1,3)
panelLosses(sim.p, sim.rates)
%
% Time
%
subplot(4,1,4)
panelTime(sim)
