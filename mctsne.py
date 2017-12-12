#!/usr/bin/env python
# from __future__ import print_function

# small wrapper to run multicore tsne, bridge between matlab and python
# usage
# python mctsne.py perplexity n_iter

from MulticoreTSNE import MulticoreTSNE as TSNE
import scipy.io
import numpy as np
import h5py
import multiprocessing
import sys

a = []
for arg in sys.argv: 
    a.append(arg)

perplexity = int(a[1])
n_iter = int(a[2])

# read the V_snippets data from whatever matlab dumped out
hf = h5py.File('Vs.mat','r')
Vs = np.array(hf.get('Vs'));

# embed
tsne = TSNE(n_jobs=multiprocessing.cpu_count(),n_iter=n_iter,perplexity=perplexity)
R = tsne.fit_transform(Vs)

with h5py.File('data.h5', 'w') as hf:
    hf.create_dataset('R', data=R)
