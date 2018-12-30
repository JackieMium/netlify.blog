---
title: 简单的 Conda 入门
author: Jackie
date: '2017-05-10'
slug: conda-intro
categories:
  - Linux
tags:
  - Linux
  - Python
  - Code
  - 基础
---

Conda 的话对于需要 Python 环境但是又没有系统权限，或者想要一个和多个相互隔离的 Python 环境的情况是很好的解决办法。而且使用起来够傻瓜。最受欢迎的应该是 Anaconda，但我选择了 Miniconda，因为不喜欢 Anaconda 那种巨无霸全家桶。

这篇博客简单介绍一下刚刚接触 Conda 时一些简单的概念，如何使用和配置。

官方文档地址：[Managing environments](https://conda.io/docs/using/envs.html)

------

## 基础

安装 Miniconda 时，默认自带一个名为`root`的环境，可以直接使用

```
source activate root
```

即可激活。在环境内执行 `pip install foo` 和 `conda install foo` 一样都将会为当前 `root` 环境装包。

添加 conda 的 TUNA 镜像

```
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/

# 搜索时显示Cheel的地址
conda config --set show_channel_urls yes
```

该命令会生成 `~/.condarc` 文件，记录对 conda 的配置，直接手动创建、编辑该文件是相同的效果。

为某个环境装包：

```
conda install --name bunnies beautiful-soup
```

查看某个环境中已经安装的所有包：

```
conda list -n snowflakes
```

删除某个环境中的某个包：

```
conda remove --name bunnies iopro
```

更新已安装的包（`conda` 和 `python` 本身也可能这样更新）：

```
conda update biopython

# update all pkgs：
conda update --all
```


## conda 环境管理

新建一个环境，使用 `2.7` 版本的 Python 并且命名为 `Python_27`:

```
# create an env
conda create --name Python_27 python=2.7
```

激活/关闭环境：

```
source activate snowflakes
source deactivate snowflakes
```

查看当前已经存在的所有环境：

```
# list all envs
conda info --envs
# or
conda env list
```

此时已经激活的环境前面带有 `*` 标识

克隆一个已存在的环境 `env_org` 为 `env_copy`：

```
# clone an env
conda create --name env_copy --clone org_env
```

删除一个环境：

```
# remove an env
conda remove --name flowers --all
```

导出环境到文件（方便其他人可以获得与你完全相同的环境，可以导出环境到文件）：

1. 激活这一环境：

```
source activate env_name
```

2. 导出环境到文件：

```python
conda env export > environment.yml
```

导出的文件会包含 `pip` 和 `conda` 安装的包。

3. 根据 `environment.yml` 新建环境

```
conda env create -f environment.yml
```


## 使用 Bioconda

### 1. Install conda

Bioconda requires the conda package manager to be installed. If you have an Anaconda Python installation, you already have it. Otherwise, the best way to install it is with the Miniconda package. The Python 3 version is recommended.

### 2. Set up channels

After installing conda you will need to add the bioconda channel as well as the other channels bioconda depends on. **It is important to add them in this order so that the priority is set correctly (that is, bioconda is highest priority)**.

The conda-forge channel contains many general-purpose packages not already found in the defaults channel. The r channel contains common R packages used as dependencies for bioconda packages.

```
conda config --add channels conda-forge
conda config --add channels defaults
conda config --add channels r
conda config --add channels bioconda
```