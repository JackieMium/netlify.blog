---
title: 关于源码编译的基础知识：出错原因解析和解决 via LinuxSir
author: Jackie
date: '2017-05-18'
slug: compile-error-via-linuxsir
categories:
  - Linux
tags:
  - Linux
  - 基础
  - 问题
  - Code
disable_comments: no
---


这篇博文的内容来自已经不存在的 LinuxSir.org 社区（RIP，现在的 LinuxSir 论坛虽然还存在，但是已经不是原来的样子和原来的人，所以我也就不放网址了）的 LFS 板块。当时很多东西我并不懂，只是觉得很有趣所以复制粘贴到我的笔记软件里了。几年之后我对 Linux 熟悉一些，也用过 Gentoo 很久并一直认为这是我最喜欢的 Linux 发行版。虽然我对源码编译很感兴趣，但是知之甚少。偶然再看到这篇博客很多东西有种豁然开朗的感觉。但是我当时留下的东西并不完整，再想回去 LinuxSir 社区补充，发现它早已不复存在。

我现在仍然觉得这两篇博文很有用，并且打算还保留它们。如果原作者看到的话请和我联系，因为我当时也只复制了部分内容，已经完全无法得知当时作者是谁了。

以下是原文，有改动。

-----

如果不出意外的话 , 会出现 `say.so not found` 之类的错误提示。 这时的 `./test` 是不能运行的，但至少这也说明了程序运行时是需要这个库的。那为什么找不到这个库呢 ? 那就让我们看看系统是怎样寻找这些库的吧。

首先是 `ld-linux.so.2` 这个不能不说，它太重要了，以至于也决定了后面的搜索方式。

先是程序内部决定的：

```bash
strings test 
```

还好我们这个 test 程序不大 , 不用过滤输出 , 好 , 你看见什么 , `/lib/ld-linux.so.2`, `say.so`, `libc.so.6`, 对 , 用到的库 ! 

但我们发现不同, 有的有路径, 有的没有, 先不管没有路径的怎么寻找, 有路径的肯定是能找到了, 那好, 我们让 `say.so` 也有了路径 . 

```bash
gcc test.c ./say.so -o test2 
strings test2 
```

我们发现原来的输出中的 `say.so` 已经变成了 `./say.so`。运行一下 `./test2`, 可以运行了!。 好 , 找到库了 , 这里用的相对路径 , 无疑 , 我们将 `say.so` 移动到非当前文件夹。那 `test` 就又不能运行了。 这样无疑是把我们用到的库硬编码进了程序里。我不喜欢硬编码，太死板。那不硬编码系统怎么找到我们需要的文件呢。

在程序没有把库地址硬编码经进去的前提下，系统会寻找 `LD_LIBRARY_PATH` 环境变量中的地址。如果系统在这一步也没发现我们需要的库呢。`/etc/ld.so.cache` 这个由 `ldconfig` 生成的文件 , 记载着在 `/etc/ld.so.conf` 文件中指明的所有库路径加上 `/lib`, `/usr/lib` 里的所有库的信息。

其实以上这句话只是在大多数情况下是正确的，是否是这个文件由 `ld-linux.so.2` 决定。如过你的 LFS 中的第一遍工具链 `/tools` 还在的话, 

```bash
strings /tools/lib/ld-linux.so.2 |grep etc 
```

输出很可能是 `/tools/etc/ld.so.cache`。那么它用的哪个文件我们就清楚了吧。
可这个路径前面的 `/tools` 到底和什么有关呢 ? 首先我们可能会想到与 `ld-linux` 所在的位置有关。还好我们有 3 套 `glib`, 感谢 LFS, 现在我们拿第二遍的工具链下手。假设我们的 LFS 在 `/lfsroot` 

```bash
strings /lfsroot/lib/ld-linux.so.2 
```

很奇怪的是输出竟然是 `/etc/ld.so.cache`! 那这到底和什么有关呢, 没错就是我们编译时候的 `--prefix` 有关。

现在再看这个 `/etc/ld.so.conf`, 和 `/lib`, `/usr/lib` 这些默认 `ldconfig` 路径。也都要加上个这个 prefix 了。

```bash
strings /tools/sbin/ldconfig |grep etc 
strings /tools/sbin/ldconfig |grep /lib 
```

验证一下吧。

那要是 `ld.so.cache` 里也没有记载这个库的地址怎么办呢。最后在默认路径里找。这个路径一般是 `/lib`, `/usr/lib`, 但也不全是。

```bash
strings /tools/lib/ld-linux.so.2 |grep /lib 
```

还是要加个 prefix。 

现在我们反过来思考，不用程序中硬编码的 `/lib/ld-linux.so.2` 做动态加载器了。这也可以 ? 是的! 虽然不一定成功。

```bash
LD_TRACE_LOADED_OBJECTS=y /tools/lib/ld-linux.so.2 /bin/test 
LD_TRACE_LOADED_OBJECTS=y /lib/ld-linux.so.2 /bin/test 
LD_TRACE_LOADED_OBJECTS=y /lfsroot/lib/ld-linux.so.2 /bin/test 
```

为了说明顺序 , 我们做如下很危险的实验 : 

```bash
ldconfig /lfsroot/lib; 
ldconfig -p 
```

会出现很多内容, 但不要试着过滤, 因为这时的系统应该很多程序不能运行了。先踏下心来观察，你会发现很多库出现两次 `/lfsroot/lib` 和 `/lib`，而且 `/lfsroot/lib` 在前, 说明 `ldconfig` 先处理参数给出的地址, 最后是默认地址。但顺序也不一定, 应该还和编译 `glibc` 时我们的参数 `--enable-kernel`有关 (我根据种种表现猜测)。加上 `export LD_LIBRARY_PATH=/lib` 环境变量在前面， 不能运行的程序又能运行了, 说明 `LD_LIBRARY_PATH` 变量的优先级优于 `ld.so.cache`

```bash
unset LD_LIBRARY_PATH 
echo >/etc/ld.so.cache 
ldconfig -p 
```

应该什么都不出现 , 可大部分程序能运行 . 说明 `ld-linux.so.2` 决定的默认路径起了作用 (注意 , 这里的 `ldconfig` 的默认路径没有作用) 

```bash
ldconfig 
```

恢复系统正常。

----

下面我们首先说下 __`/etc/ld.so.conf`__:

这个文件记录了编译时使用的动态链接库的路径。 
默认情况下，编译器只会使用 `/lib` 和 `/usr/lib` 这两个目录下的库文件。如果你安装了某些库，比如在安装 `gtk+-2.4.13` 时它会需要 `glib-2.0 >= 2.4.0`, 辛苦的安装好 glib 后没有指定 `--prefix=/usr` 这样 `glib` 库就装到了 `/usr/local` 下，而又没有在 `/etc/ld.so.conf` 中添加 `/usr/local/lib`这个搜索路径，所以编译 `gtk+-2.4.13` 就会出错了。 

对于这种情况有两种方法解决： 
1. 在编译 `glib-2.4.x` 时，指定安装到 `/usr` 下，这样库文件就会放在 `/usr/lib` 中，`gtk` 就不会找不到需要的库文件了。对于安装库文件来说，这是个好办法，这样也不用设置 `PKG_CONFIG_PATH` 了 (稍后说明) 
2. 将 `/usr/local/lib` 加入到 `/etc/ld.so.conf` 中，这样安装 `gtk` 时就会去搜索 `/usr/local/lib`, 同样可以找到需要的库。将 `/usr/local/lib` 加入到 `/etc/ld.so.conf` 也是必须的，这样以后安装东西到 `local` 下，就不会出现这样的问题了。将自己可能存放库文件的路径都加入到 `/etc/ld.so.conf` 中是明智的选择。

再来看看 __`ldconfig`__ 吧 ： 

它是一个程序，通常它位于 `/sbin` 下，是 `root` 用户使用的。具体作用及用法可以 `man ldconfig` 查到。

简单的说，它的作用就是将 `/etc/ld.so.conf` 列出的路径下的库文件缓存到 `/etc/ld.so.cache` 以供使用 。因此当安装完一些库文件，例如刚安装好 `glib`，或者修改 `ld.so.conf` 增加新的库路径后，需要运行一下 `/sbin/ldconfig` 使所有的库文件都被缓存到 `ld.so.cache` 中。如果没做，即使库文件明明就在 `/usr/lib` 下的，也是不会被使用的，结果编译过程中报错，缺少 xxx 库，去查看发现明明就在那放着 。所以切记改动库文件后一定要运行一下 `ldconfig`，在任何目录下运行都可以。 

再来说说 __`PKG_CONFIG_PATH`__ 这个变量吧 : 

经常在论坛上看到有人问 "为什么我已经安装了 `glib-2.4.x`, 但是编译 `gtk+-2.4.x` 还是提示 `glib` 版本太低啊？ 为什么我安装了 `glib-2.4.x`，还是提示找不到阿？...." 都是这个变量搞的鬼。先来看一个编译过程中出现的错误 (编译 `gtk+-2.4.13`):   

```bash
checking for pkg-config... /usr/bin/pkg-config checking for glib-2.0 >= 2.4.0 atk >= 1.0.1 pango >= 1.4.0... Package glib-2.0 was not found in the pkg-config search path. 
Perhaps you should add the directory containing `glib-2.0.pc' to the PKG_CONFIG_PATH environment  variable
No package 'glib-2.0' found 

configure: error: Library requirements (glib-2.0 >= 2.4.0 atk >= 1.0.1 pango >= 1.4.0) not met; consider adjusting the PKG_CONFIG_PATH environment variable if your libraries are in a nonstandard prefix so pkg-config can find them. 
[root@NEWLFS gtk+-2.4.13]# 
```

很明显，上面这段说明，没有找到 `glib-2.4.x`, 并且提示应该将 `glib-2.0.pc` 加入到 `PKG_CONFIG_PATH` 下。 
究竟这个 `pkg-config` 目录、 `PKG_CONFIG_PATH` 变量和 `glib-2.0.pc` 文件都是做什么的呢？
先说说它是哪冒出来的，当安装了 `pkgconfig-x.x.x` 这个包后，就多出了 `pkg-config`，它就是需要 `PKG_CONFIG_PATH` 这个东西。 

来看一段说明： 

>The pkgconfig package contains tools for passing the include path and/or library paths to build tools during the make file execution.  
>pkg-config is a function that returns meta information for the specified library.  
>The default setting for PKG_CONFIG_PATH is /usr/lib/pkgconfig because of the prefix we use to install pkgconfig. You may add to PKG_CONFIG_PATH by exporting additional paths on your system where pkgconfig files are installed. Note that PKG_CONFIG_PATH is only needed when compiling packages, not during run-time.  

我想看过这段说明后，你已经大概了解了它是做什么的吧。 
其实 `pkg-config` 就是向 `configure` 程序提供系统信息的程序，比如软件的版本、库的版本啦、库的路径，等等 
这些信息只是在编译其间使用。你可以 ` ls /usr/lib/pkgconfig` 下，会看到许多的 `*.pc`, 用文本编辑器打开 
会发现类似下面的信息： 

```bash
prefix=/usr 
exec_prefix=${prefix} 
libdir=${exec_prefix}/lib 
includedir=${prefix}/include 

glib_genmarshal=glib-genmarshal 
gobject_query=gobject-query 
glib_mkenums=glib-mkenums 

Name: GLib 
Description: C Utility Library 
Version: 2.4.7 
Libs: -L${libdir} -lglib-2.0 
Cflags: -I${includedir}/glib-2.0 -I${libdir}/glib-2.0/include 
```

明白了吧，编译期间 `configure` 就是靠这些信息判断你的软件版本是否符合要求。并且得到这些东东所在的位置，要不去哪里找呀。 
不用我说你也知道为什么会出现上面那些问题了吧。 解决的办法很简单，设定正确的 `PKG_CONFIG_PATH`，假如将
 `glib-2.x.x` 装到了 `/usr/local/` 下，那么 `glib-2.0.pc`就会在 `/usr/local/lib/pkgconfig` 下， 将这个路径添加到 `PKG_CONFIG_PATH` 下就可以了。并且确保 `configure` 找到的是正确的 `glib-2.0.pc`， 将其他的 `lib/pkgconfig` 目录 `glib-2.0.pc` 干掉就是啦 (如果有的话 ) 。
设定好后可以加入到 `~/.bashrc` 中，例如： 

```bash
PKG_CONFIG_PATH=/opt/kde-3.3.0/lib/pkgconfig:/usr/lib/pkgconfig:/usr/local/pkgconfig: /usr/X11R6/lib/pkgconfig 
[root@NEWLFS ~]# echo $PKG_CONFIG_PATH 
/opt/kde-3.3.0/lib/pkgconfig:/usr/lib/pkgconfig:/usr/local/pkgconfig:/usr/X11R6/lib/pkgconfig 
```

另外 `./configure` 通过，`make` 出错，遇到这样的问题比较难办，只能凭经验查找原因，比如某个头文件没有找到， 
这时候要顺着出错的位置一行的一行往上找错，比如显示 `xxxx.h no such file or directory` 说明缺少头文件 
然后去 Google。 或者找到感觉有价值的错误信息，拿到 Google 去搜，往往会找到解决的办法。还是开始的那句话，要仔细看README, INSTALL 

1. 编译完成后，输入`echo $?` 如果返回结果为0, 则表示正常结束，否则就出错了 :(  。 `echo $?` 表示检查上一条命令的退出状态.程序正常退出返回 0, 错误退出返回非 0。 
2. 编译时，可以用 `&&` 连接命令， `&&` 表示 "当前一条命令正常结束，后面的命令才会执行"，就是"与"啦。这个办法很好，即节省时间，又可防止出错。例： 

```bash
./configure --prefix=/usr && make && make install 
```

实例：
编译 `DOSBOX` 时出现 `cdrom.h:20:23: SDL_sound.h: No such file or directory`。于是下载，安装，很顺利，没有指定安装路径，于是默认的安装到了`/usr/local/ `
当编译 DOSBOX `make` 时，出现如下错误： 

```bash
if g++ -DHAVE_CONFIG_H -I. -I. -I../.. -I../../include -I/usr/include/SDL -D_REENTRANT -march=pentium4 -O3 -pipe -fomit-frame-pointer -MT dos_programs.o -MD -MP -MF ".deps/dos_programs.Tpo" -c -o dos_programs.o dos_programs.cpp; \ 
then mv -f ".deps/dos_programs.Tpo" ".deps/dos_programs.Po"; else rm -f ".deps/dos_programs.Tpo"; exit 1; fi 
In file included from dos_programs.cpp:30: 
cdrom.h:20:23: SDL_sound.h: No such file or directory <------错误的原因在这里 
In file included from dos_programs.cpp:30: 
cdrom.h:137: error: ISO C++ forbids declaration of `Sound_Sample' with no type 
cdrom.h:137: error: expected `;' before '*' token 
make[3]: *** [dos_programs.o] Error 1 
make[3]: Leaving directory `/root/software/dosbox-0.63/src/dos' 
make[2]: *** [all-recursive] Error 1 
make[2]: Leaving directory `/root/software/dosbox-0.63/src' 
make[1]: *** [all-recursive] Error 1 
make[1]: Leaving directory `/root/software/dosbox-0.63' 
make: *** [all] Error 2 
[root@NEWLFS dosbox-0.63]# 
```

看来是因为 `cdrom.h` 没有找到 `SDL_sound.h` 这个头文件所以出现了下面的错误，但是我明明已经安装好了 `SDL_sound` 啊？ 

经过查找，在 `/usr/local/include/SDL/` 下找到了 `SDL_sound.h`。看来 `dosbox` 没有去查找 `/usr/local/include/SDL` 下的头文件，既然找到了原因，就容易解决啦 

```bash
[root@NEWLFS dosbox-0.63]# ln -s /usr/local/include/SDL/SDL_sound.h /usr/include 
```

做个链接到 `/usr/include` 下，这样 `DOSBOX` 就可以找到了，顺利编译成功。