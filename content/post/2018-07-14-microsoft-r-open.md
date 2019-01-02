---
title: Microsoft R Open 的安装和配置
author: Jackie
date: '2018-07-14'
slug: microsoft-r-open
categories:
  - R
tags:
  - Linux
  - R
  - 软件
  - 问题
disable_comments: no
---


昨天偶然在网上看到看到关于不同版本 R 的速度对比的文章 [R, R with Atlas, R with OpenBLAS and Revolution R Open: which is fastest?](http://www.brodrigues.co/blog/2014-11-11-benchmarks-r-blas-atlas-rro/)，被结果惊到了，最快的 Revolution R Open 碾压 Vanilla R，而且相比 OPENBLAS 和 ATLAS R 都有优势，简直是孤独求败。然后我搜了一下，发现 Revolution R Open 已经变成 [Microsoft R Open](https://mran.microsoft.com/) 了。虽然是开源，但是对于微软家的东西还是有点不是很喜欢吧。看了一下还和 Intel 搞的 MKL 直接一起下下来了，这简直就是搞黑科技垄断啊。


算了，吐槽到此为止，安装上看一下。

## 下载安装

首先我是 Debian sid，没什么好说的，直接用提供的 Ubuntu 版本就行了，2018-07-14 最新版本为 `3.5.0`。

安装呢没啥好说的，[文档](https://mran.microsoft.com/documents/rro/installation) 简单得很，解压，运行 shell 脚本就完了。

值得一提的是，微软始终还是那个微软，看到这个提示：

> **Important!**
> After installing, the default R path is updated to point to R installed with Microsoft R Open 3.5.0, which is under lib64/R/bin/R.
> The CRAN repository points to a snapshot from Jan 01, 2018. This means that every user of Microsoft R Open has access to the same set of CRAN package versions. To get packages from another date, use the checkpoint package, installed with Microsoft R Open.

我就知道微软出品的本色，霸道。还记得重装系统时会被 Windows 覆盖掉的大名湖畔的 grub2 吗哈哈哈哈？

## 启动和配置

按照官方文档的说法，装完后 MRO 会自动设置为默认，所以 Terminal 直接 `R` 启动就好：

```r
➜ R

R version 3.5.0 (2018-04-23) -- "Joy in Playing"
Copyright (C) 2018 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under certain conditions.
Type 'license()' or 'licence()' for distribution details.

  Natural language support but running in an English locale

R is a collaborative project with many contributors.
Type 'contributors()' for more information and
'citation()' on how to cite R or R packages in publications.

Type 'demo()' for some demos, 'help()' for on-line help, or
'help.start()' for an HTML browser interface to help.
Type 'q()' to quit R.


 *** caught segfault ***
address 0x50, cause 'memory not mapped'

Traceback:
 1: dyn.load(libPath)
 2: doTryCatch(return(expr), name, parentenv, handler)
 3: tryCatchOne(expr, names, parentenv, handlers[[1L]])
 4: tryCatchList(expr, classes, parentenv, handlers)
 5: tryCatch(expr, error = function(e) {    call <- conditionCall(e)    if (!is.null(call)) {        if (identical(call[[1L]], quote(doTryCatch)))             call <- sys.call(-4L)        dcall <- deparse(call)[1L]        prefix <- paste("Error in", dcall, ": ")        LONG <- 75L        sm <- strsplit(conditionMessage(e), "\n")[[1L]]        w <- 14L + nchar(dcall, type = "w") + nchar(sm[1L], type = "w")        if (is.na(w))             w <- 14L + nchar(dcall, type = "b") + nchar(sm[1L],                 type = "b")        if (w > LONG)             prefix <- paste0(prefix, "\n  ")    }    else prefix <- "Error : "    msg <- paste0(prefix, conditionMessage(e), "\n")    .Internal(seterrmessage(msg[1L]))    if (!silent && isTRUE(getOption("show.error.messages"))) {        cat(msg, file = outFile)        .Internal(printDeferredWarnings())    }    invisible(structure(msg, class = "try-error", condition = e))})

....


Possible actions:
1: abort (with core dump, if enabled)
2: normal R exit
3: exit R without saving workspace
4: exit R saving workspace
Selection: 
```

Great！：(


我不知道啥错误，反正看着挺严重。选 `3` 吧，退出不保存。然后就发现了一条算是比较熟悉的报错：

```r
Warning message:
In doTryCatch(return(expr), name, parentenv, handler) :
  unable to load shared object '/opt/microsoft/ropen/3.5.0/lib64/R/modules//R_X11.so':
  libpng12.so.0: cannot open shared object file: No such file or directory
```

这个用 Linux 久了都知道，缺 `libpng12.so.0` 这个库文件嘛。第一反应是看看系统到底有没有这个呢？

```bash
➜ locate libpng12.so.0
/home/adam/.aspera/connect/lib/libpng12.so.0
/opt/kingsoft/wps-office/office6/libpng12.so.0
/opt/kingsoft/wps-office/office6/libpng12.so.0.46.0
```

有点意思，WPS 带了一个，后续就简单了：

```bash
➜ ls -l /opt/kingsoft/wps-office/office6/libpng12.so.0 
lrwxrwxrwx 1 root root 18 Jun  5 03:22 /opt/kingsoft/wps-office/office6/libpng12.so.0 -> libpng12.so.0.46.0
➜ sudo ln -s /opt/kingsoft/wps-office/office6/libpng12.so.0.46.0 /opt/microsoft/ropen/3.5.0/lib64/R/lib/libpng12.so.0
```

然后再 `R` 启动看看发现没问题了。RStudio 打开看了一下，也是 MRO 了。`library("limma")` 没问题。

当然，如果没有你的系统没有 `libpng12.so.0` 那也可以装，[DebianCN 源](http://mirrors.ustc.edu.cn/help/debiancn.html) 里有 `libpng12` 了，直接 `sudo apt install libpng12` 就行了，测试了一下发现是可以的。其他发行版的话可能得自己编译了。

嗯，这些基本没问题了

吗？


## 还没完

我为什么上面说__基本没问题了__呢？

因为 MRO 自动变成我的默认 R 了，这太不没问题了好吗！这是 Linux，充满自由，选择的 Linux 世界。凭什么装上就设置默认，我的选择呢？官方说法十分轻描淡写：

> **Tip**: You can also manage multiple side-by-side installations of any application using the alternatives command (or update-alternatives on Ubuntu). This command allows you create and manage symbolic links to the different installations, and thus easily refer to the installation of your choice.

里面还假惺惺地给了 `alternatives` 命令的帮助页面链接而不是直接提供具体做法，可以这很微软。
正确的做法不应该是安装时候不设置默认，然后下面给出如果想设置默认要怎么办然后给 `alternatives` 帮助链接吗？

吐槽再次完毕，我们下面来自己掌控怎么设置到底谁才是系统默认的 R 版本。

- 我之前装的是 `R 3.5.1 (2018-07-02) -- "Feather Spray"`，`R` 可执行文件路径为 `/usr/lib/R/bin/R`
- 而 MRO 刚刚看到了，装在 `/op/` 下，具体可执行文件路径 `/opt/microsoft/ropen/3.5.0/lib64/R/bin/R`
- 我们在终端直接 `R` 其实执行是我们 `PATH` 里存在 `R` 命令，而上述两个路径显然都不在 `PATH` 里
- `whereis R` 看一下，发现其实执行的是 `/usr/bin/R` 这个命令，而这个命令本身是一个软链接：`/usr/bin/R -> /opt/microsoft/ropen/3.5.0/lib64/R/bin/R`

所以基本上真相大白了，系统默认用哪个 R 就是通过 `/usr/bin/R` 这个软链接来控制的。那我们想要哪个默认直接改这个软链接的指向就行了。

这当然是最直观的办法，而 Debian 里呢，我们可以通过 `update-alternatives` 来配置，参考博文 [Alternative Versions of R](http://spartanideas.msu.edu/2015/06/19/alternative-versions-of-r/) 。我们要做的就是让 update-alternatives 知道我们这两个 R 都在哪里，然后用 `update-alternatives --install <link> <name> <path> <priority>` 设置它们各自的优先级就行了，priority 大的就是默认。

```bash
➜ sudo rm /usr/bin/R
➜ sudo update-alternatives --install /usr/bin/R R /usr/lib/R/bin/R 200
➜ sudo update-alternatives --install /usr/bin/R R /opt/microsoft/ropen/3.5.0/lib64/R/bin/R 100
```

这样我们就重新把原来的 R 设置为默认了。终端打开或者 RStudio 都没问题。而且现在由系统 update-alternatives 接管了版本管理，以后我们要更改也十分简单：

```bash
➜ update-alternatives --list R  
/opt/microsoft/ropen/3.5.0/lib64/R/bin/R
/usr/lib/R/bin/R
➜ sudo update-alternatives --config R
There are 2 choices for the alternative R (providing /usr/bin/R).

  Selection    Path                                      Priority   Status
------------------------------------------------------------
* 0            /usr/lib/R/bin/R                           200       auto mode
  1            /opt/microsoft/ropen/3.5.0/lib64/R/bin/R   100       manual mode
  2            /usr/lib/R/bin/R                           200       manual mode

Press <enter> to keep the current choice[*], or type selection number: 
```

list 能看到可选的 R 版本，而 config 就能自己选择哪个作为默认了。


THE END.

------------

__2018-11-10 更新__：

今天发现 MRO-3.5.1 已经出来了，下下来解压直接安装会报错：

```r
(Reading database ... 188397 files and directories currently installed.)
Preparing to unpack .../microsoft-r-open-mro-3.5.1.deb ...
dpkg-divert: error: 'diversion of /usr/bin/R to /usr/bin/R.distrib by microsoft-r-open-mro-3.5.1' clashes with 'diversion of /usr/bin/R to /usr/bin/R.distrib by microsoft-r-open-mro-3.5.0'
dpkg-divert: error: 'diversion of /usr/bin/Rscript to /usr/bin/Rscript.distrib by microsoft-r-open-mro-3.5.1' clashes with 'diversion of /usr/bin/Rscript to /usr/bin/Rscript.distrib by microsoft-r-open-mro-3.5.0'
dpkg: error processing archive /home/adam/Downloads/microsoft-r-open/deb/microsoft-r-open-mro-3.5.1.deb (--install):
 new microsoft-r-open-mro-3.5.1 package pre-installation script subprocess returned error exit status 2
Errors were encountered while processing:
 /home/adam/Downloads/microsoft-r-open/deb/microsoft-r-open-mro-3.5.1.deb
```

好像是和已经安装的 MRO-3.5.0 有冲突，所以就直接先 `sudo apt purge microsoft-r-open-mro-3.5.0`，然后再安装就 OK 了。之后启动 R 一样会报错 `libpng12.so.0 not found`，解决办法同前。然后 MRO 依然会自动成为系统默认，解决办法依然同前。