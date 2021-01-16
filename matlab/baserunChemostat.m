%
% Make a basic run of the chemostat model
%
function sim = baserunChemostat(mAdult, bUseFortran)
if (nargin==0)
    mAdult = [];
end
if (nargin < 2)
    bUseFortran = false;
end
%
% Set parameters:
%
p = parameters(mAdult);
p = parametersChemostat(p);
p.tEnd = 365;
p.bUseLibrary = bUseFortran;
%s
% Setup fortran library:
%
if bUseFortran
    if libisloaded('NUMmodel')
        unloadlibrary('NUMmodel')
    end
    loadNUMmodelLibrary();
    calllib(loadNUMmodelLibrary(), 'f_setupgeneric', int32(length(mAdult)), mAdult);
end
%
% Simulate
%
tic
sim = simulateChemostat(p, 100);
toc
%
% Plot
%
plotSimulation(sim)