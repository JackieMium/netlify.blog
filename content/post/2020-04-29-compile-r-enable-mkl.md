---
title: 编译安装 R 并启用 Intel MKL 支持
author: Jackie
date: '2020-04-29'
slug: compile-r-enable-mkl
categories:
  - R
  - Linux
tags:
  - 软件
  - Linux
  - 问题
lastmod: '2020-04-30T21:04:54+08:00'
keywords: []
description: ''
comment: yes
toc: yes
autoCollapseToc: yes
postMetaInFooter: no
hiddenFromHomePage: no
contentCopyright: no
reward: no
mathjax: no
mathjaxEnableSingleDollar: no
mathjaxEnableAutoNumber: no
hideHeaderAndFooter: no
flowchartDiagrams:
  enable: no
  options: ''
sequenceDiagrams:
  enable: no
  options: ''
---

微软似乎放弃 [Microsoft R Open](https://mran.microsoft.com/) 这个项目了，那么以前写的 [Microsoft R Open 的安装和配置](https://jiangjun.link/post/microsoft-r-open/) 也就成了过去式了。我一直是同时用两个版本 R 的，在 Windows 上这个实现起来很简单，因为 Windows 上多个版本 R 本来就是可以共存的。但是在 Linux，至少是 Debian 上，这个就没那么简单了。以前 MRO 和 vanilla R 共存也算很优雅地解决了这个问题。现在要想多个版本就只能自己编译一个 R 了。

<!--more-->


R 源码直接从 r-project.org 下载。然后就是 MKL 的问题了，查了很多资料试了很多办法（看看文末的参考链接就知道了），但是发现大部分资料基本上都是过时的。MKL 以往对于 Linux（至少是 Debian 和 Ubuntu）都是没有很好的支持的，但是可喜的是现在我发现现在 Debian 的官方 non-free 仓库里已经有 MKL 了！所以至少安装 MKL 就很简单了。

## 安装和配置 MKL

Debian 仓库是有 MKL，`apt search intel-mkl` 会发现有 `intel-mkl`、`intel-mkl-cluster` 和 `intel-mkl-full` 三个版本，分别 `apt show` 会发现各个版本的差别：

1. intel-mkl

> This package pulls the basic set of development files and libraries of MKL in the present architecture. Cluster support is not included.

2. intel-mkl-cluster

>  This package pulls the development files and libraries of MKL in the present architecture, including Cluster support.

3. intel-mkl-full:

> This package pulls the full version of MKL, including several i386 packages.

很简单，我个人用用就 intel-mkl 足够了。`sudo apt install intel-mkl` 搞定。我们首先想要把 MKL 设置成提供 BLAS 和 LAPACK 动态库。在 Debian 里安装的时候会有供选择的界面，安装后我们会看到类似于：


```
update-alternatives: using /usr/lib/x86_64-linux-gnu/libmkl_rt.so to provide /usr/lib/x86_64-linux-gnu/libblas64.so.3 (libblas64.so.3-x86_64-linux-gnu) in auto mode
update-alternatives: using /usr/lib/x86_64-linux-gnu/libmkl_rt.so to provide /usr/lib/x86_64-linux-gnu/liblapack64.so.3 (liblapack64.so.3-x86_64-linux-gnu) in auto mode
Setting MKL as default BLAS/LAPACK implementation as requested.
update-alternatives: using /usr/lib/x86_64-linux-gnu/libmkl_rt.so to provide /usr/lib/x86_64-linux-gnu/libblas.so.3 (libblas.so.3-x86_64-linux-gnu) in manual mode
update-alternatives: using /usr/lib/x86_64-linux-gnu/libmkl_rt.so to provide /usr/lib/x86_64-linux-gnu/liblapack.so.3 (liblapack.so.3-x86_64-linux-gnu) in manual mode
...
update-alternatives: using /usr/lib/x86_64-linux-gnu/libmkl_rt.so to provide /usr/lib/x86_64-linux-gnu/libblas64.so (libblas64.so-x86_64-linux-gnu) in auto mode
update-alternatives: using /usr/lib/x86_64-linux-gnu/libmkl_rt.so to provide /usr/lib/x86_64-linux-gnu/liblapack64.so (liblapack64.so-x86_64-linux-gnu) in auto mode
Setting MKL as default BLAS/LAPACK implementation as requested.
update-alternatives: using /usr/lib/x86_64-linux-gnu/libmkl_rt.so to provide /usr/lib/x86_64-linux-gnu/libblas.so (libblas.so-x86_64-linux-gnu) in manual mode
update-alternatives: using /usr/lib/x86_64-linux-gnu/libmkl_rt.so to provide /usr/lib/x86_64-linux-gnu/liblapack.so (liblapack.so-x86_64-linux-gnu) in manual mode
```

的输出。就是 intel-mkl 是会自动接管并成为系统默认的 BLAS 和 LAPACK 库。是不是似曾相识？这不就是 MRO 的时候 Microsoft 的做法么？果然天下的乌鸦一般黑。

但是这里既然我就是要用 MKL，所以它自己接管了倒也不是问题。不过还是要知道，对付这样的行径 `update-alternatives` 是个很好的工具。

这时候运行已系统安装的 R (通过 apt 安装的官方仓库的 vanilla R)，`sessionInfo()` 会显示已经启用 MKL 加速库（后文示例输出）。

## 编译安装 R 并启用 MKL 支持

安装路径定在 `/opt/R/4.0.0`。对的，我直接下载了最新稳定版 4.0.0。

解压 R 源码包之后进入目录，`mkdir build` 然后 `cd build`，先用默认参数编译试试看 `../configure` 有没有缺依赖什么的：

```
R is now configured for x86_64-pc-linux-gnu

  Source directory:            ..
  Installation directory:      /usr/local

  C compiler:                  gcc  -g -O2
  Fortran fixed-form compiler: gfortran -fno-optimize-sibling-calls -g -O2

  Default C++ compiler:        g++ -std=gnu++11  -g -O2
  C++14 compiler:              g++ -std=gnu++14  -g -O2
  C++17 compiler:              g++ -std=gnu++17  -g -O2
  C++20 compiler:              g++ -std=gnu++2a  -g -O2
  Fortran free-form compiler:  gfortran -fno-optimize-sibling-calls -g -O2
  Obj-C compiler:               

  Interfaces supported:        X11, tcltk
  External libraries:          pcre2, readline, curl
  Additional capabilities:     PNG, JPEG, TIFF, NLS, cairo, ICU
  Options enabled:             shared BLAS, R profiling

  Capabilities skipped:        
  Options not enabled:         memory profiling

  Recommended packages:        yes

configure: WARNING: you cannot build info or HTML versions of the R manuals
```

大概没问题的。X11 、tclck 和常用图片格式支持都有。`memory profiling` 虽然不太清楚干嘛的，似乎是内存调试相关，没有默认开启就算了吧。

但是这里其实有个编译选项要自己打开，这就是 `--enable-R-shlib`，这个选项指定需要编译一个名为 `libR` 的库文件(`libR.so` 或 `libR.a`)。由于 RStudio 需要调用这个文件，所以也必须打开这个选项。其他选项可以从 `../configure --help` 来看，BLAS 和 LAPACK 就有一些选项。

现在由于没有指定 `--with-blas` 和 `--with-lapack`，而根据帮助来看默认这两个选项都是关闭的，所以 R 会默认在`buildDIR/lib/` 下编译出 `libRblas.so` 和 `libRlapack.so`（还有我们需要的 `libR.so` 也在这个目录下），以及 `buildDIR/module/` 下的 `lapack.so`，当然这就是默认情况，MKL 没有用到。 

依据 [R Installation and Administration](https://cran.r-project.org/doc/manuals/r-release/R-admin.html)  附录 A3 章节，我们启用 MKL 的话首先要设定两个环境变量：

```bash
export MKL_INTERFACE_LAYER=GNU,LP64
export MKL_THREADING_LAYER=GNU
```

然后 configure 的时候加上 `--with-blas="-lmkl_rt" --with-lapack` 就可以了，这时候我们可能要关掉 R Profiling，那就再加上 `--disable-R-profiling`。

另外附录 A.2.1 章节 tcltk 这里提到 `--with-tcl-config` 和 `--with-tk-config` 我发现我这里似乎也有，指定一下算了。

最后，完整的 configure 指令就成了：

```
../configure --prefix=/opt/R/4.0.0 \
    --enable-R-shlib \
    --disable-R-profiling \
    --with-blas='lmkl_rt' --with-lapack \
    --with-tcltk \
    --with-tcl-config=/usr/lib/tclConfig.sh \
    --with-tk-config=/usr/lib/tkConfig.sh
```

最后结果应该类似于：

```
R is now configured for x86_64-pc-linux-gnu

  Source directory:            ..
  Installation directory:      /opt/R/4.0.0

  C compiler:                  gcc  -g -O2
  Fortran fixed-form compiler: gfortran -fno-optimize-sibling-calls -g -O2

  Default C++ compiler:        g++ -std=gnu++11  -g -O2
  C++14 compiler:              g++ -std=gnu++14  -g -O2
  C++17 compiler:              g++ -std=gnu++17  -g -O2
  C++20 compiler:              g++ -std=gnu++2a  -g -O2
  Fortran free-form compiler:  gfortran -fno-optimize-sibling-calls -g -O2
  Obj-C compiler:               

  Interfaces supported:        X11, tcltk
  External libraries:          pcre2, readline, BLAS(MKL), LAPACK(in blas), curl
  Additional capabilities:     PNG, JPEG, TIFF, NLS, cairo, ICU
  Options enabled:             shared R library

  Capabilities skipped:        
  Options not enabled:         shared BLAS, R profiling, memory profiling

  Recommended packages:        yes

configure: WARNING: you cannot build info or HTML versions of the R manuals
```

然后就可以 `make` 和 `sudo make install` 了，中间也可以 `make check` 和 `make check-all` 一下。

安装好后可以仍然用 `update-alternatives` 来接管这个自己编译安装的 R，不再赘述。

编译安装好后 R 命令在 `/opt/R/4.0.0/bin/R`，同时 `/opt/R/4.0.0/lib/R/lib/` 就只剩下  `libR.so` 了， `/opt/R/4.0.0/lib/R/modules/` 还是有个 `lapack.so`。

这时候我们来检查检查：

## 扫尾

```r
sessionInfo()
# R version 4.0.0 (2020-04-24)
# Platform: x86_64-pc-linux-gnu (64-bit)
# Running under: Debian GNU/Linux bullseye/sid

# Matrix products: default
# BLAS/LAPACK: /usr/lib/x86_64-linux-gnu/libmkl_rt.so

# locale:
#  [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C              
#  [3] LC_TIME=en_US.UTF-8        LC_COLLATE=en_US.UTF-8    
#  [5] LC_MONETARY=en_US.UTF-8    LC_MESSAGES=en_US.UTF-8   
# [7] LC_PAPER=en_US.UTF-8       LC_NAME=C                 
#  [9] LC_ADDRESS=C               LC_TELEPHONE=C            
# [11] LC_MEASUREMENT=en_US.UTF-8 LC_IDENTIFICATION=C       

# attached base packages:
# [1] stats     graphics  grDevices utils     datasets  methods   base     

# loaded via a namespace (and not attached):
# [1] compiler_4.0.0


La_library()
# [1] "/usr/lib/x86_64-linux-gnu/libmkl_rt.so"

La_version()
# [1] "3.8.0"  

extSoftVersion()
#                                      zlib 
#                                 "1.2.11" 
#                                    bzlib 
#                     "1.0.8, 13-Jul-2019" 
#                                       xz 
#                                  "5.2.4" 
#                                     PCRE 
#                       "10.34 2019-11-21" 
#                                      ICU 
#                                   "63.2" 
#                                      TRE 
#                "TRE 0.8.0 R_fixes (BSD)" 
#                                    iconv 
#                             "glibc 2.30" 
#                                 readline 
#                                    "8.0" 
#                                     BLAS 
# "/usr/lib/x86_64-linux-gnu/libmkl_rt.so"
```

如果这时候我们跳出来再终端看看刚刚说的 `libR.so` 和 `lapack.so` 的链接情况可能会有点疑惑：

```
lib/libR.so:
        linux-vdso.so.1 (0x00007ffe6a2a3000)
        libmkl_rt.so => /usr/lib/x86_64-linux-gnu/libmkl_rt.so (0x00007f3ec2b6c000)                       # <<----------   libmkl_rt.so 在这里
        libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007f3ec2a27000)
        libreadline.so.8 => /lib/x86_64-linux-gnu/libreadline.so.8 (0x00007f3ec29d4000)
        libpcre2-8.so.0 => /usr/lib/x86_64-linux-gnu/libpcre2-8.so.0 (0x00007f3ec2944000)
        liblzma.so.5 => /lib/x86_64-linux-gnu/liblzma.so.5 (0x00007f3ec291b000)
        libbz2.so.1.0 => /lib/x86_64-linux-gnu/libbz2.so.1.0 (0x00007f3ec2908000)
        libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007f3ec28e9000)
        libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007f3ec28e4000)
        libicuuc.so.63 => /usr/lib/x86_64-linux-gnu/libicuuc.so.63 (0x00007f3ec2713000)
        libicui18n.so.63 => /usr/lib/x86_64-linux-gnu/libicui18n.so.63 (0x00007f3ec243c000)
        libgomp.so.1 => /usr/lib/x86_64-linux-gnu/libgomp.so.1 (0x00007f3ec23fc000)
        libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007f3ec23db000)
        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f3ec2216000)
        /lib64/ld-linux-x86-64.so.2 (0x00007f3ec3714000)
        libtinfo.so.6 => /lib/x86_64-linux-gnu/libtinfo.so.6 (0x00007f3ec21e7000)
        libicudata.so.63 => /usr/lib/x86_64-linux-gnu/libicudata.so.63 (0x00007f3ec07f6000)
        libstdc++.so.6 => /usr/lib/x86_64-linux-gnu/libstdc++.so.6 (0x00007f3ec0629000)
        libgcc_s.so.1 => /lib/x86_64-linux-gnu/libgcc_s.so.1 (0x00007f3ec060f000)
modules/lapack.so:
        linux-vdso.so.1 (0x00007ffe6ebc8000)
        libR.so => /usr/lib/libR.so (0x00007f24c6489000)                              #  <<---------  libR.so 用了系统的文件？？？
        libmkl_rt.so => /usr/lib/x86_64-linux-gnu/libmkl_rt.so (0x00007f24c5da6000)                   #  <<-------------- libmkl_rt.so 似乎没问题
        libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007f24c5c61000)
        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f24c5a9e000)
        libreadline.so.8 => /lib/x86_64-linux-gnu/libreadline.so.8 (0x00007f24c5a4b000)
        libpcre.so.3 => /lib/x86_64-linux-gnu/libpcre.so.3 (0x00007f24c59d7000)
        liblzma.so.5 => /lib/x86_64-linux-gnu/liblzma.so.5 (0x00007f24c59ac000)
        libbz2.so.1.0 => /lib/x86_64-linux-gnu/libbz2.so.1.0 (0x00007f24c5999000)
        libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007f24c597c000)
        libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007f24c5977000)
        libicuuc.so.63 => /usr/lib/x86_64-linux-gnu/libicuuc.so.63 (0x00007f24c57a6000)
        libicui18n.so.63 => /usr/lib/x86_64-linux-gnu/libicui18n.so.63 (0x00007f24c54cf000)
        libgomp.so.1 => /usr/lib/x86_64-linux-gnu/libgomp.so.1 (0x00007f24c548d000)
        libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007f24c546c000)
        /lib64/ld-linux-x86-64.so.2 (0x00007f24c6953000)
        libtinfo.so.6 => /lib/x86_64-linux-gnu/libtinfo.so.6 (0x00007f24c543d000)
        libicudata.so.63 => /usr/lib/x86_64-linux-gnu/libicudata.so.63 (0x00007f24c3a4c000)
        libstdc++.so.6 => /usr/lib/x86_64-linux-gnu/libstdc++.so.6 (0x00007f24c387f000)
        libgcc_s.so.1 => /lib/x86_64-linux-gnu/libgcc_s.so.1 (0x00007f24c3863000)

```

看到 `lapack.so` 似乎链接到了错误的 `libR.so`（`/usr/lib/libR.so` 是系统里 apt 从官方仓库装的 R 的文件），我赶紧看看 `/opt/R/4.0.0/lib/R/modules/`下其他动态库文件，发现似乎都如此。当时心里一咯噔，反复试了之后最后发现其实很简单。我们在 R 里看看：

```
system("ldd /opt/R/4.0.0/lib/R/lib/libR.so")
#         linux-vdso.so.1 (0x00007ffc967f2000)
#         libmkl_rt.so => /usr/lib/x86_64-linux-gnu/libmkl_rt.so (0x00007f882238b000)
#         libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007f8822228000)
#         libreadline.so.8 => /lib/x86_64-linux-gnu/libreadline.so.8 (0x00007f88221d5000)
#         libpcre2-8.so.0 => /usr/lib/x86_64-linux-gnu/libpcre2-8.so.0 (0x00007f8822145000)
#         liblzma.so.5 => /lib/x86_64-linux-gnu/liblzma.so.5 (0x00007f882211c000)
#         libbz2.so.1.0 => /lib/x86_64-linux-gnu/libbz2.so.1.0 (0x00007f8822109000)
#         libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007f88220ea000)
#         libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007f88220e5000)
#         libicuuc.so.63 => /usr/lib/x86_64-linux-gnu/libicuuc.so.63 (0x00007f8821f14000)
#         libicui18n.so.63 => /usr/lib/x86_64-linux-gnu/libicui18n.so.63 (0x00007f8821c3d000)
#         libgomp.so.1 => /usr/lib/x86_64-linux-gnu/libgomp.so.1 (0x00007f8821bfd000)
#         libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007f8821bdc000)
#         libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f8821a17000)
#         /lib64/ld-linux-x86-64.so.2 (0x00007f8822f15000)
#         libtinfo.so.6 => /lib/x86_64-linux-gnu/libtinfo.so.6 (0x00007f88219e8000)
#         libicudata.so.63 => /usr/lib/x86_64-linux-gnu/libicudata.so.63 (0x00007f881fff7000)
#         libstdc++.so.6 => /usr/lib/x86_64-linux-gnu/libstdc++.so.6 (0x00007f881fe2a000)
#         libgcc_s.so.1 => /lib/x86_64-linux-gnu/libgcc_s.so.1 (0x00007f881fe10000)
system("ldd /opt/R/4.0.0/lib/R/modules/lapack.so")
#         linux-vdso.so.1 (0x00007ffcec19a000)
#         libR.so => /opt/R/4.0.0/lib/R/lib/libR.so (0x00007fb94983e000)                      # <<------- 没有问题！
#         libmkl_rt.so => /usr/lib/x86_64-linux-gnu/libmkl_rt.so (0x00007fb94915b000)
#         libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007fb948ff8000)
#         libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fb948e35000)
#         libreadline.so.8 => /lib/x86_64-linux-gnu/libreadline.so.8 (0x00007fb948de2000)
#         libpcre2-8.so.0 => /usr/lib/x86_64-linux-gnu/libpcre2-8.so.0 (0x00007fb948d52000)
#         liblzma.so.5 => /lib/x86_64-linux-gnu/liblzma.so.5 (0x00007fb948d27000)
#         libbz2.so.1.0 => /lib/x86_64-linux-gnu/libbz2.so.1.0 (0x00007fb948d14000)
#         libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007fb948cf7000)
#         libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007fb948cf2000)
#         libicuuc.so.63 => /usr/lib/x86_64-linux-gnu/libicuuc.so.63 (0x00007fb948b21000)
#         libicui18n.so.63 => /usr/lib/x86_64-linux-gnu/libicui18n.so.63 (0x00007fb94884a000)
#         libgomp.so.1 => /usr/lib/x86_64-linux-gnu/libgomp.so.1 (0x00007fb948808000)
#         libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007fb9487e7000)
#         /lib64/ld-linux-x86-64.so.2 (0x00007fb949cf4000)
#         libtinfo.so.6 => /lib/x86_64-linux-gnu/libtinfo.so.6 (0x00007fb9487b8000)
#         libicudata.so.63 => /usr/lib/x86_64-linux-gnu/libicudata.so.63 (0x00007fb946dc7000)
#         libstdc++.so.6 => /usr/lib/x86_64-linux-gnu/libstdc++.so.6 (0x00007fb946bfa000)
#         libgcc_s.so.1 => /lib/x86_64-linux-gnu/libgcc_s.so.1 (0x00007fb946bde000)

system("echo $LD_LIBRARY_PATH")        # 谜底揭晓
# /opt/R/4.0.0/lib/R/lib:/usr/local/lib:/usr/lib/x86_64-linux-gnu:/usr/lib/jvm/oracle-java8-jdk-amd64/jre/lib/amd64/server:/usr/lib/jvm/oracle-java8-jdk-amd64/jre/lib/amd64:/usr/lib/jvm/oracle-java8-jdk-amd64/jre/lib/amd64/server

Sys.getenv("LD_LIBRARY_PATH")  # R 自己也可以检查环境变量
# [1] "/opt/R/4.0.0/lib/R/lib:/usr/local/lib:/usr/lib/x86_64-linux-gnu:/usr/lib/jvm/oracle-java8-jdk-amd64/jre/lib/amd64/server:/usr/lib/jvm/oracle-java8-jdk-amd64/jre/lib/amd64:/usr/lib/jvm/oracle-java8-jdk-amd64/jre/lib/amd64/server"
```

R 在运行时会把自己的库文件夹加入 `LD_LIBRARY_PATH` 环境变量，这样就能找到正确的库文件了。完结撒花！


- [RStudio Community: Compiling R from source in /opt/R](https://community.rstudio.com/t/compiling-r-from-source-in-opt-r/14666/14)
- [RStudio Support: Building R from source](https://support.rstudio.com/hc/en-us/articles/218004217-Building-R-from-source)
- [R Documents: R-admin](https://cran.r-project.org/doc/manuals/r-release/R-admin.html#Installing-R-under-Unix_002dalikes)
- [stackoverflow: Can't make ./configure find tcltk while building R](https://unix.stackexchange.com/q/222696)
- [intel-MKL: README.Debian](https://salsa.debian.org/science-team/intel-mkl/blob/master/debian/README.Debian)
- [stackoverflow: Compile r with mkl (With mulithreads support)](https://stackoverflow.com/q/14996697)
- [GitHub: eddelbuettel/mkl4deb](https://github.com/eddelbuettel/mkl4deb)
- [Using Intel® MKL with R](https://software.intel.com/en-us/articles/using-intel-mkl-with-r)
- [Build R-3.4.2 with Intel® C++ and Fortran Compilers and Intel® MKL on Linux*](https://software.intel.com/en-us/articles/build-r-301-with-intel-c-compiler-and-intel-mkl-on-linux)
