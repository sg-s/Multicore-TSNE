# Multicore t-SNE

This is a multicore modification of [Barnes-Hut t-SNE](https://github.com/lvdmaaten/bhtsne) by L. Van der Maaten with python and Torch CFFI-based wrappers. This code also works **faster than sklearn.TSNE** on 1 core.

<center><img src="mnist-tsne.png" width="512"></center>

# What to expect

Barnes-Hut t-SNE is done in two steps.

- First step: an efficient data structure for nearest neighbours search is built and used to compute probabilities. This can be done in parallel for each point in the dataset, this is why we can expect a good speed-up by using more cores.

- Second step: the embedding is optimized using gradient descent. This part is essentially consecutive so we can only optimize within iteration. In fact some parts can be parallelized effectively, but not all of them a parallelized for now. That is why second step speed-up will not be that significant as first step sepeed-up but there is still room for improvement.

So when can you benefit from parallelization? It is almost true, that the second step computation time is constant of `D` and depends mostly on `N`. The first part's time depends on `D` a lot, so for small `D` `time(Step 1) << time(Step 2)`, for large `D` `time(Step 1) >> time(Step 2)`. As we are only good at parallelizing step 1 we will benefit most when `D` is large enough (MNIST's `D = 784` is large, `D = 10` even for `N=1000000` is not so much). I wrote multicore modification originally for [Springleaf competition](https://www.kaggle.com/c/springleaf-marketing-response), where my data table was about `300000 x 3000` and only several days left till the end of the competition so any speed-up was handy.

# Benchmark

### 1 core

Interestingly, that this code beats other implementations. We compare to `sklearn` (Barnes-Hut of course), L. Van der Maaten's [bhtsne](https://github.com/lvdmaaten/bhtsne), [py_bh_tsne repo](https://github.com/danielfrg/tsne) (cython wrapper for bhtsne with QuadTree). `perplexity = 30, theta=0.5` for every run. In fact [py_bh_tsne repo](https://github.com/danielfrg/tsne) works at the same speed as this code when using more optimization flags for compiler.

This is a benchmark for `70000x784` MNIST data:

| Method                       | Step 1 (sec)   | Step 2 (sec)  |
| ---------------------------- |:---------------:| --------------:|
| MulticoreTSNE(n_jobs=1)      | **912**         | **350**        |
| bhtsne                       | 4257            | 1233           |
| py_bh_tsne                   | 1232            | 367            |
| sklearn(0.18)                | ~5400           | ~20920         |

I did my best to find what is wrong with sklearn numbers, but it is the best benchmark I could do (you can find test script in `python/tests` folder).

### Multicore

This table shows a relative to 1 core speed-up when using `n` cores.

| n_jobs        | Step 1    | Step 2   |
| ------------- |:---------:| --------:|
| 1             | 1x        | 1x       |
| 2             | 1.54x     | 1.05x    |
| 4             | 2.6x      | 1.2x     |
| 8             | 5.6x      | 1.65x    |


## Installation (macOS, MATLAB specific)

### Setup

First, get this repository 

```
git clone https://github.com/sg-s/Multicore-TSNE.git
cd Multicore-TSNE/
```

Make sure you have `gcc` installed:

```
brew install gcc --without-multilib
```

The issue with installing this on macOS is that you need a modern version of `gcc`, and the one that ships on your computer by default won't work. The one that ships with XCode probably wont' work. I used `gcc-8`. Use the latest one. Assuming you have `gcc-8`, determine where this is:

```
which gcc-8
```

and modify `setup.py` (line 21) to make sure it points to the right version. 

### Prepare your python environment

I strongly reccomend that you use Anaconda and install this in a `conda` environment. That way, you can segment the dependencies for this and avoid the awful Python dependency hell that people seem to relish so much. 

1. Download Anaconda [here](https://www.anaconda.com/download/)
2. Create a new conda enviornment: `conda create -n mctsne pip`
3. Switch to that environment: `source activate mctsne`
4. Within that environment, install some dependencies manually:

```bash
# the -U matters
pip install -U setuptools
pip install numpy
pip install h5py
pip install cffi
pip install psutil
pip install scipy
```

OK, now you're ready to compile

### Compiling

Then, compile using

```
export CC="/usr/local/bin/gcc-8"; export CXX="/usr/local/bin/gcc-8"; python setup.py install
```

Make sure you modify the paths in the command above to point to where `gcc` is. This command should be run in the main folder (that contains `setup.py`)

## Using this from MATLAB

I hope you've followed all the steps above. For use from within MATLAB,
you'll have to install some helper code. The simplest way to do this is to use my package manager from within your MATLAB prompt
```
% copy and paste this code in your MATLAB prompt
urlwrite('http://srinivas.gs/install.m','install.m'); 
install -f sg-s/srinivas.gs_mtools   
install -f sg-s/Multicore-TSNE % fast t-sne embedding 
install -f sg-s/condalab % switch between python envs
```
That's it! Test using

```matlab
mctsne(randn(1000,500))
```


## Run (within python)

You can use it as a drop-in replacement for [sklearn.manifold.TSNE](http://scikit-learn.org/stable/modules/generated/sklearn.manifold.TSNE.htm).

```
from MulticoreTSNE import MulticoreTSNE as TSNE

tsne = TSNE(n_jobs=4)
Y = tsne.fit_transform(X)
```

Please refer to [sklearn TSNE manual](http://scikit-learn.org/stable/modules/generated/sklearn.manifold.TSNE.html) for parameters explanation.

Only double arrays are supported for now. For this implementation `n_components` is fixed to `2`, which is the most common case (use [Barnes-Hut t-SNE](https://github.com/lvdmaaten/bhtsne) or sklearn otherwise). Also note that some of the parameters will be ignored for sklearn compatibility. Only these parameters are used (and they are the most important ones):

- perplexity
- n_iter
- angle

## Test (using python)

You can test it on MNIST dataset with the following command:

```
python python/tests/test.py <n_jobs>
```

#### Note on jupyter use
To make the computation log visible in jupyter please install `wurlitzer` (`pip install wurlitzer`) and execute this line in any cell beforehand:
```
%load_ext wurlitzer
```
Memory leakages are possible if you interrupt the process. Should be OK if you let it run until the end.

# License

Inherited from [original repo's license](https://github.com/lvdmaaten/bhtsne).

# Future work

- Allow other types than double
- Improve step 2 performance (possible)

# Citation

Please cite this repository if it was useful for your research:

```
@misc{Ulyanov2016,
  author = {Ulyanov, Dmitry},
  title = {Muticore-TSNE},
  year = {2016},
  publisher = {GitHub},
  journal = {GitHub repository},
  howpublished = {\url{https://github.com/DmitryUlyanov/Muticore-TSNE}},
}

@misc{Gorur-Shandilya2018,
  author = {Gorur-Shandilya, Srinivas},
  title = {Muticore-TSNE (MATLAB wrapper)},
  year = {2018},
  publisher = {GitHub},
  journal = {GitHub repository},
  howpublished = {\url{https://github.com/sg-s/Muticore-TSNE}},
}
```

Of course, do not forget to cite [L. Van der Maaten's paper](http://lvdmaaten.github.io/publications/papers/JMLR_2014.pdf)
