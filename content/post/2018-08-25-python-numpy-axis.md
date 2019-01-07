---
title: Python 里 NumPy 的 axis 参数的理解
author: Jackie
date: '2018-08-25'
slug: python-numpy-axis
categories:
  - Python
tags:
  - Python
  - 基础
disable_comments: no
show_toc: no
---

<img src="/post/2018-08-25-python-numpy-axis_files/0.BingWallpaper-2018-08-25.jpg" alt="0.BingWallpaper-2018-08-25.jpg" width="100%" height="100%"/>


最近学学 Python 做数据分析，主要就是 Python 基本语法 + NumPy + pandas 咯。

发现很好的一些教程：

- [python_for_data_analysis_2nd_chinese_version](https://github.com/iamseancheney/python_for_data_analysis_2nd_chinese_version)

- [Numpy & Pandas (莫烦 Python 数据处理教程)](https://morvanzhou.github.io)

- [Data analysis in Python with pandas](https://www.youtube.com/playlist?list=PL5-da3qGB5ICCsgW1MxlZ0Hq8LL5U3u9y)

果然人生苦短，大家都在用 Python。好教程都一搜一大把。然后今天在 B 站看莫烦的视频，前面都是讲 NumPy 的，array 这个东西其实对于我来说没那么重要，所以我就 1.5x 倍速的看。然后一边刷酷安和饭否啥的，基本没怎么操作，想着泛泛地听一听得了，后面 pandas 再认真听跟着操作。印象中 Python 里对于二维数据就是 0 是行 1 是列。因为我记忆的方法一直是我们平时都会说行列行列，那 0101 不就是行列行列。看到对 array 讲求均数、最大最小值以及后面 `np.split()` 发现一直有人在弹幕刷什么 axis = 0 是行有没有错或者怎么理解之类的。然后我就决定试一下看一看 (我都是在 conda 环境 IPython3 下面操作，所以前面都有 `IN` 和 `OUT`)：

```python
In [1]: import numpy as np

In [2]: a = np.arange(12).reshape(3,4)
In [3]: b = np.arange(12).reshape(4,3)
```

这样 a、b 分别是 3 行 4 列和 4 行 3 列的两个 array。print 看一下心里有底：

```python
In [4]: print(a)
[[ 0  1  2  3]
 [ 4  5  6  7]
 [ 8  9 10 11]]

In [5]: print(b)
[[ 0  1  2]
 [ 3  4  5]
 [ 6  7  8]
 [ 9 10 11]]
```

我们来看看求均数的时候 `axis` 参数怎么工作：

```python
# axis = 0 是行
In [6]: np.mean(a, axis=0)
Out[6]: array([4., 5., 6., 7.])

In [7]: np.mean(b, axis=0)
Out[7]: array([4.5, 5.5, 6.5])

# axis = 1 是列
In [8]: np.mean(a, axis=1)
Out[8]: array([1.5, 5.5, 9.5])

In [9]: np.mean(b, axis=1)
Out[9]: array([ 1.,  4.,  7., 10.])
```

对 a 进行 " 行求平均 " 得到 4 个值，b 同样进行 " 行求平均 " 得到 3 个值。这不是列平均数吗？
对 a 进行”列求平均“得到 3 个值，b 同样进行“列求平均”得到 4 个值。这不是列求平均吗？


然后我就开始查了，“Python numpy axis” 拿去 Google 一下，果然问这个问题的不少：

我们看一个 StackOverflow 上的问题：[Ambiguity in Pandas Dataframe / Numpy Array “axis” definition](https://stackoverflow.com/questions/25773245/ambiguity-in-pandas-dataframe-numpy-array-axis-definition/25774395#25774395):

![1.question](/post/2018-08-25-python-numpy-axis_files/1.question.png)

这个人几乎问了和我一模一样的问题，NumPy 的 axis 到底咋回事？

下面的回答解释得很详细：

>It's perhaps simplest to remember it as *0=down* and *1=across*.
>
>This means:
>
>- Use `axis=0` to apply a method down each column, or to the row labels (the index).
>- Use `axis=1` to apply a method across each row, or to the column labels.
>
>It's also useful to remember that Pandas follows NumPy's use of the word `axis`. The usage is explained in NumPy's [glossary of terms](http://docs.scipy.org/doc/numpy/glossary.html):
>
>> Axes are defined for arrays with more than one dimension. A 2-dimensional array has two corresponding axes: the first running vertically **downwards across rows (axis 0)**, and the second running **horizontally across columns (axis 1)**. [*my emphasis*]
>
>So, concerning the method in the question, `df.mean(axis=1)`, seems to be correctly defined. It takes the mean of entries *horizontally across columns*, that is, along each individual row. On the other hand, `df.mean(axis=0)` would be an operation acting vertically *downwards across rows*.
>
>Similarly, `df.drop(name, axis=1)` refers to an action on column labels, because they intuitively go across the horizontal axis. Specifying `axis=0` would make the method act on rows instead.

什么意思呢？其实简单的理解办法就是：`axis = 0` 就是在列上上下方向应用一个方法，或者说是对 row index 作用；而 `axis = 1` 就是在行上左右方向作用，或者说是对列名。

在 NumPy 的文档里也说了，`axis = 0` 是垂直方向上对行在上下合并操作，`axis = 1` 在水平方向上在对列左右合并操作。所以呢，这就能理解了，我们说行列其实是说在哪个维度上来操作，0 在行上操作，那么列不动，行上下压缩没了；反之，1 在列上左右方向操作，那行不动，列一压缩都没了。

再回头看开头的例子：

```python
In [10]: print(a)
[[ 0  1  2  3]
 [ 4  5  6  7]
 [ 8  9 10 11]]

In [11]: np.mean(a,axis=0)
Out[11]: array([4., 5., 6., 7.])
# 在 0 也就是行上上下操作，行全部压缩没了，上下求均数，所以剩下每一列一个均数

In [12]: np.mean(a,axis=1)
Out[12]: array([1.5, 5.5, 9.5])
# 在 1 也就列上所有操作，所以列压缩没了，左右求均数，所以剩下每一行一个均数
```

能理解了吧。

再来看开头提到的 `np.split` 。这个函数接受 3 个参数，对谁做切割操作，分成几块，以及 `axis` 即怎么切。

现在 a 三行四列，b 四行三列。所以考虑切两块的话，a 左右切，在列上左右操作，axis 是 1。b 就是上下切两块，行上上下操作，所以 axis 是 0 。验证一下：

```python
In [13]: np.split(a, 2, axis=1)
Out[13]: 
[array([[0, 1],
        [4, 5],
        [8, 9]]), 
 array([[ 2,  3],
        [ 6,  7],
        [10, 11]])]

In [14]: np.split(b, 2, axis=0)
Out[14]: 
[array([[0, 1, 2],
        [3, 4, 5]]), 
 array([[ 6,  7,  8],
        [ 9, 10, 11]])]
# 为了排版便于阅读我在结果部分加了换行，但是内容没有改动
```

可以看到，代码确实如我们所想的那样工作。


最后，我们再看 StackOverflow 上那个问题里提到的 ` df.drop("col4", axis=1)` 也就能理解了，我们指定 `axis = 1` 即在列上左右操作，所以被 drop 掉的肯定是列，然后有参数指定哪些列就行了。

嗯，收工。图书馆刚好关门，晚安。
