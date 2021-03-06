%
% Save the results of a simulation to be used for initial conditions
%
function saveGlobal(sim)

savesim.N = sim.N(:,:,:,end);
savesim.DOC = sim.DOC(:,:,:,end);
sim.B(sim.B<0) = 0;
savesim.B = sim.B(:,:,:,:,end);
savesim.t = 0;
savesim.p = sim.p;
sim = savesim;

save(sim.p.pathInit,'sim');

    
