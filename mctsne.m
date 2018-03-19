% mctsne.m
% MATLAB wrapper for Dmitry Ulyanov's Multicore t-SNE 
% implementation
% this wrapper assumes you have the python wrapper set up
% and calls that.  

function R = mctsne(Vs,n_iter,perplexity)

if nargin < 2
	n_iter = 1000;
	perplexity = 30;
elseif nargin < 3
	perplexity = 30;
end

assert(~any(isnan(Vs(:))),'Input cannot contain NaN values')
assert(~any(isinf(Vs(:))),'Input cannot contain Inf values')


% check cache
temp.Vs = Vs;
temp.perplexity = perplexity;
temp.n_iter = n_iter;
h = dataHash(temp);


if exist(joinPath(fileparts(which(mfilename)),[h '.cache']),'file') == 2
	load(joinPath(fileparts(which(mfilename)),[h '.cache']),'-mat')
	return
end

save('Vs.mat','Vs','-v7.3')

perplexity = floor(perplexity);
n_iter = floor(n_iter);
assert(n_iter > 10,'n_iter too low')
assert(perplexity > 2,'perplexity too low')

p1 = ['python "' fileparts(which('mctsne'))];

% first check if the environment is right using the test script
eval_str =  [p1 filesep 'mctsne_test.py" '];
[e,o] = system(eval_str);
if e ~=0
	warning('MulticoreTSNE test failed...attempting to fix path')
	conda.setenv('mctsne')
end

p1 = ['"' fileparts(which('mctsne'))];
eval_str =  [p1 filesep 'mctsne.py" ' oval(perplexity) ' ' oval(n_iter)];

system(eval_str)

% read the solution
R = h5read('data.h5','/R');

% clean up
delete('data.h5')
delete('Vs.mat')

save(joinPath(fileparts(which(mfilename)),[h '.cache']),'R');