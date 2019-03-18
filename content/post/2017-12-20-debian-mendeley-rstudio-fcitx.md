---
title: 解决 Debian 中 Mendeley Desktop 和 RStudio 无法使用 fcitx 输入中文的问题
author: Jackie
date: '2017-12-20'
slug: debian-mendeley-rstudio-fcitx
categories:
  - Linux
tags:
  - Linux
  - 软件
  - 问题
disable_comments: no
show_toc: yes
---

# 0. 写在前面

如果你找到这篇博客是也正在尝试解决 Linux(Debiain) 下 RStudio 和 Mendeley Desktop 里使用 fcitx 输入法输入中文的问题，请先看看我的 [Github 仓库](https://github.com/JackieMium/libfcitxplatforminputcontextplugin.so) 是否已经上传了你所需要的版本，或者另外一篇帖子 [win10 下 Rstudio 切换中文输入法问题](https://d.cosx.org/d/419556-win10-rstudio)。如果还没有解决的话，欢迎提 Issue 我们一起看看，或者你已经解决了给我提 PR 当然更加欢迎 :D

如果你想了解解决这个问题的思路的话，可以继续看下文(我有点啰嗦，所以本文会有点长)。还有另外 3 篇在整个过程中对我帮助极大的博文和帖子作参考：

- [A case study: how to compile a Fcitx platforminputcontext plugin for a proprietary software that uses Qt 5](https://www.csslayer.info/wordpress/fcitx-dev/a-case-study-how-to-compile-a-fcitx-platforminputcontext-plugin-for-a-proprietary-software-that-uses-qt-5/) 。这是 fcitx 开发者在 2017 写的一篇博文。
- [Mendeley Fcitx Problem](http://yinflying.top/2017/09/727) 。最开始我就是看到了这篇博文和博主交流才知道以往自己认为安装一个 Qt5 很容易 “系统搞乱” 的观点是无稽之谈，然后才决定自定编译 Qt5 的。
- [win10 下 Rstudio 切换中文输入法问题](https://d.cosx.org/d/419556-win10-rstudio) 。这是统计之都论坛的谈 Windows 10 下 RStudio 有类似问题的一篇帖子。

# 1. 缘起

这篇博文经历了多次更新，原因很多。这次借着博客的迁移我打算修改完善一下，同时也整理一下前因后果免得看起来逻辑混乱。

最开始我写出来是在 2017-12-20，当时我第一次通过编译 Qt 和 fcitx-qt5 解决了 Mendeley Desktop 和 RStudio 中 fcitx 输入中文的问题。但是写成此文之后，Rstudio 再次更新我按照这个博文里当时的记录编译 fcitx-qt5 发现编译出来的库文件没用。本身其中原理我大概懂，所以不认为这个方法会失效，那既然我编译出来的库文件失效，只能说明是我的做法有问题，也就说当初的记录有问题。这催生了 2018-02-05 这次更新（这也是第一次更新），当时我发现整个过程的核心问题是 Qt 环境的设置包括 `PATH` 和 `LD_LIBRARY_PATH` 这两个部分。只有这两个东西设置对编译出来的库文件才能起效。而具体的，编译 fcitx-qt5 用的 Qt5 是直接安装官方提供的二进制包然后用 Qt Creator 傻瓜操作，还是下载源码包自己编译 Qt5，抑或用软件包自己带的 Qt5 库这都是做法问题了。

再次更新是 2018-08-16，在统计之都论坛看到帖子反映直接删掉 Rstudio 自带的 Qt5 库文件强迫它调用系统库文件可以解决这个问题。我试了确实可以，当然我悲观地认为这个方法肯定迟早会失效。果然，几个月后这个方法也失效，还是得回到自己编译的老路上去。


然后就是 2018-12-08 更新了，Rstudio 的 Qt5 版本再次升级，删除其自带库文件的方法失效，我又一次自己编译库文件。

最后的更新，也就是现在，2018-12 末，我在 Netlify 上托管新的博客，把 Github Issue 里的博文增删顺改迁移过来并决定把这篇博文好好改一下。

相对于 Github Issue 那里的内容，这里增加了上面的废话，把 3 次更新信息放到了末尾（有改动）；以及最重要的，下面的正文部分仔细整理修改了。

现在整个正文的结构为：安装 Qt5，包括编译安装和直接安装官方二进制包；编译 fcitx-qt5，包括命令行编译和使用 Qt Creator；后记。


# 2. 正文

一直以来 Qt-based App 下 fcitx 无法输入中文的问题都让我很恼火，用的比较多的 RStudio 先后两次去 Support 发帖无果，在他们的 GitHub 也发了 [Issue](https://github.com/rstudio/rstudio/issues/1903)，他们标记了 bug 之后就啥也没干。Mendeley 也去发帖过一次，官方回复大概意思是 “知道了，但是目前这个问题优先级很低”.....

其实以前用的是 Zotero 用来管理文献，也写过另一篇博文 [在 Debian 中使用 Zotero 文献管理软件](https://jiangjun.netlify.com/post/2017/05/debian-zotero/) ，后来软件某一次升级之后就打不开了..... 终端打开没有任何提示信息。可惜我整理得好好的文献库也没了。然后我就转到 Mendeley 了，Mendeley 比起来优点有：多终端同步，自带的 PDF 阅读器也支持高亮和注释，手机用 [Research App](https://www.researcher-app.com/) 连接到 Mendeley 后标记文章可以直接同步到 Mendeley。并且 Mendeley 支持导入 Zotero 的文献库，所以最终我的 Zotero 虽然坏了但是文献库还是拯救出来了。


~~~
好的，废话少说，Let's get started！
~~~

## 2.1 Mendeley Desktop 

在解决 Mendeley 的问题时遇到的坑更少，先写这个。

### 2.1.1 编译安装 Qt

先来说 Mendeley Desktop 吧，解决思路反正都一样。首先我们得知道软件用到的 Qt 是哪个版本。我们进入 Mendeley 的安装目录，不出意外的话应该是 `/opt/mendeleydesktop`。然后顺藤摸瓜就能找到 `/opt/mendeleydesktop/lib/qt` 这个路径，下面存了一堆 `libQt5xxx.so` 这样的 Qt5 库文件。随便找一个用来看 Qt 版本（这是更新的时候加的内容，所以 Qt 版本已经不再是 5.5.1）：

```bash
➜ strings libQt5Core.so.5 |grep Qt |grep version
This is the QtCore library version Qt 5.10.1 (x86_64-little_endian-lp64 shared (dynamic) release build; by GCC 5.3.1 20160406 (Red Hat 5.3.1-6))
Cannot mix incompatible Qt library (version 0x%x) with this library (version 0x%x)

```

发现 Mendeley Desktop 使用的 Qt 5.5.1 。然后直接去 qt.io 下载 `qt-everywhere-opensource-src-5.5.1.tar.xz` 源码包，解压，进入目录。

关于编译 Qt，在 BLFS 的 HandBook 中编译 Qt5 有说明：[Qt-5.4.2 ](http://anduin.linuxfromscratch.org/~bdubbs/blfs-book-xsl/x/qt5.html)，深以为然。简单来说，首先在 `/opt` 建立相应文件夹后，再建立一个指向这个文件夹的软链接 `qt5`。

```bash
# 准备安装 QT 的目录
sudo mkdir /opt/qt.5.5.1
sudo ln -s /opt/qt.5.5.1 /opt/qt5
./configure --prefix=/opt/qt5 -no-openssl
```

碰到一大堆报错 `XCB` 啥的，查了下直接加 `-qt-xcb` 就行了，我也不知道 `XCB` 干嘛的，这不是重点。（`configure --help` 可以获得编译 Qt 详尽的选项说明）

```bash
./configure --prefix=/opt/qt5.5.1 -no-openssl -qt-xcb
```

顺利同过。然后三部曲后两步：

```bash
make -j4。
sudo make install
```

Qt5 很大，编译这一步可能会耗时比较久，我的 Intel Core i5-6300HQ @ 4x 3.2GHz 大概用了 20~30 min。
后来我也试过通过简化组建来缩短编译时间：

```bash
../configure -v -prefix /opt/qt5 -shared -largefile -accessibility -no-qml-debug -force-pkg-config \
-release -opensource -confirm-license -optimized-qmake \
-system-zlib -no-mtdev -system-libpng -system-libjpeg -system-freetype -fontconfig -system-harfbuzz \
-no-compile-examples -icu -qt-xcb -qt-xkbcommon -xinput2 -glib \
-no-pulseaudio -no-alsa -gtkstyle -no-openssl \
-nomake examples -nomake tests -no-compile-examples -skip qtdoc
```

缩减时间似乎没那么明显（具体每个参数什么意思 `configure --help` 都有）。

### 2.1.2 编译 fcitx-qt5

接下来是 `fcitx-qt5`。在编译它之前要让刚刚编译好的 Qt 发挥作用，就是要配置好去使用我们自己编译安装的 Qt 工具链，包括 Qt 编译器和库文件。简单方便的做法是临时 `export` 一下。

```bash
export PATH=/opt/qt5/5.11.1/gcc_64/bin:$PATH
export LD_LIBRARY_PATH=/opt/qt5/5.11.1/gcc_64/lib:$LD_LIBRARY_PATH
```

然后就是下载和编译 fcitx-qt5 了：

```bash
git clone https://github.com/fcitx/fcitx-qt5.git
cd fcitx-qt5
cmake .
```

我第一次编译的时候出现报错：

```bash
CMake Error at CMakeLists.txt:8 (find_package):
  Could not find a package configuration file provided by "ECM" (requested
  version 1.4.0) with any of the following names:

    ECMConfig.cmake
    ecm-config.cmake

  Add the installation prefix of "ECM" to CMAKE_PREFIX_PATH or set "ECM_DIR"
  to a directory containing one of the above files.  If "ECM" provides a
  separate development package or SDK, be sure it has been installed.


-- Configuring incomplete, errors occurred!
See also "/path/to/fcitx-qt5/CMakeFiles/CMakeOutput.log".
```

Google 一下，哦，`sudo apt install extra-cmake-modules` 就行了。继续：

```bash
cmake .

........
-- Could NOT find XKBCommon_XKBCommon (missing: XKBCommon_XKBCommon_LIBRARY XKBCommon_XKBCommon_INCLUDE_DIR) 
CMake Error at /usr/share/cmake-3.9/Modules/FindPackageHandleStandardArgs.cmake:137 (message):
  Could NOT find XKBCommon (missing: XKBCommon_LIBRARIES XKBCommon) (Required
  is at least version "0.5.0")
Call Stack (most recent call first):
  /usr/share/cmake-3.9/Modules/FindPackageHandleStandardArgs.cmake:377 (_FPHSA_FAILURE_MESSAGE)
  cmake/FindXKBCommon.cmake:30 (find_package_handle_standard_args)
  CMakeLists.txt:33 (find_package)


-- Configuring incomplete, errors occurred!
See also "/path/to/fcitx-qt5/CMakeFiles/CMakeOutput.log".
.......
```

WTF???.... 不要急不要急，Google 一下，哦，`sudo apt install libxkbcommon-dev`。再继续：

```bash
cmake .

........
-- Found XKBCommon_XKBCommon: /usr/lib/x86_64-linux-gnu/libxkbcommon.so (found version "0.7.1") 
-- Found XKBCommon: /usr/lib/x86_64-linux-gnu/libxkbcommon.so (found suitable version "0.7.1", minimum required is "0.5.0") found components:  XKBCommon 
CMake Error at CMakeLists.txt:36 (find_package):
  By not providing "FindFcitx.cmake" in CMAKE_MODULE_PATH this project has
  asked CMake to find a package configuration file provided by "Fcitx", but
  CMake did not find one.

  Could not find a package configuration file provided by "Fcitx" (requested
  version 4.2.8) with any of the following names:

    FcitxConfig.cmake
    fcitx-config.cmake

  Add the installation prefix of "Fcitx" to CMAKE_PREFIX_PATH or set
  "Fcitx_DIR" to a directory containing one of the above files.  If "Fcitx"
  provides a separate development package or SDK, be sure it has been
  installed.


-- Configuring incomplete, errors occurred!
See also "/path/to/fcitx-qt5/CMakeFiles/CMakeOutput.log".
........
```

哦，知道了，Google。哦，`sudo apt install fcitx-libs-dev`。好，三继续：

```bash
cmake .
# 这次编译过了 ..............

make -j4
```

编译完成之后手别抖，不要惯性 `sudo make install`，不需要。现在 `platforminputcontext/` 目录下应该已经有了新鲜出炉的 `libfcitxplatforminputcontextplugin.so` 了，然后就好了：

```
sudo cp platforminputcontext/libfcitxplatforminputcontextplugin.so /opt/mendeleydesktop/plugins/qt/plugins/platforminputcontexts
```

再**终端**打开 Mendeley 试试 fcitx 已经可以用了。不保险，退出 Mendeley，直接鼠标点点点菜单找到 Mendeley Desktop 再次打开，输入法还没挂，OK。问题解决。


### 2.1.3 干嘛要编译 Qt5？直接二进制梭哈不好么？

再来说说安装 Qt 的问题。qt.io 其实是提供 Qt-binary，在官网注册登录或者各大镜像站一般都可以下载到，文件名类似于 `qt-opensource-linux-x64-5.10.0.run` 的就是二进制包了。直接下载赋予执行权限并执行就可以开始安装 Qt，中间也可以选择安装哪些组件，这时候记得把 Qt 组件和 Qt Creator 选上就行。

安装完了系统菜单里应该就会有 Qt Creator 了，如果没有的话，自己到安装路径里找到，然后启动 Qt Creator。

这时候编译 fcitx-qt5 可以说就相当简单了。直接 Open Project，选择我们 git clone 到本地的 fcitx-qt5 目录下的 `CMakeLists.txt` 就可以导入 fcitx-qt5 项目了。导入后 Qt Creator 会自动 configure，只要我们的 Qt Creator 配置为我们刚刚的工具链的话这一步应该是不会出错的。下一步选择菜单 Build -> Build Project "fcitx-qt5"，然后 Qt Creator 会自动生成一个工程目录并开始编译项目，目录一般在 fcitx-qt5 同级目录下。编译完成后进入目录 `platforminputcontext/` 下就能看到 `libfcitxplatforminputcontextplugin.so` 文件了。然后就和上面一样了，移动到对应路径就完了。


我自己最开始选择编译 Qt5 而不是用二进制包的原因很多。第一，我对 Qt 和  Qt Creator 都不熟，在我之前没有用过 Qt Creator 的时候我连它长什么样子都不知道，所以说让我安装 Qt Creator 然后用来编译 fcitx-qt5 我是连概念都没有的；第二，我自己想通过编译 Qt5 + 编译 fcitx-qt5 这个过程了解一下这个工具链的使用过程，这大概就纯属喜欢“折腾”吧，没办法。我总觉得自己做一遍肯定会比直接鼠标点点点多一点收获，当然花时间是少不了的。



## 2.2 RStudio

接下来一样，在 RStudio 菜单的关于里看了下，基于 Qt-5.4.0，那就下载 ` qt-everywhere-opensource-src-5.4.0.tar.xz` 好了。
以为可以收工了？怎么可能，Naive。

`./configure --prefix=/opt/qt.5.4.0 -no-openssl -qt-xcb` 直接报错：

```
ln -s libQt5Widgets.so.5.4.0 libQt5Widgets.so
ln -s libQt5Widgets.so.5.4.0 libQt5Widgets.so.5
ln -s libQt5Widgets.so.5.4.0 libQt5Widgets.so.5.4
rm -f ../../lib/libQt5Widgets.so.5.4.0
mv -f libQt5Widgets.so.5.4.0  ../../lib/ 
rm -f ../../lib/libQt5Widgets.so
rm -f ../../lib/libQt5Widgets.so.5
rm -f ../../lib/libQt5Widgets.so.5.4
mv -f libQt5Widgets.so ../../lib/ 
mv -f libQt5Widgets.so.5 ../../lib/ 
mv -f libQt5Widgets.so.5.4 ../../lib/ 
make[3]: Leaving directory '/home/adam/Downloads/Persepolis/qt-everywhere-opensource-src-5.4.0/qtbase/src/widgets'
make[2]: Leaving directory '/home/adam/Downloads/Persepolis/qt-everywhere-opensource-src-5.4.0/qtbase/src'
Makefile:45: recipe for target 'sub-src-make_first' failed
make[1]: *** [sub-src-make_first] Error 2
make[1]: Leaving directory '/home/adam/Downloads/Persepolis/qt-everywhere-opensource-src-5.4.0/qtbase'
Makefile:70: recipe for target 'module-qtbase-make_first' failed
make: *** [module-qtbase-make_first] Error 2
```

一头雾水，连报错信息都基本没有。二话不说，Google，靠谱的办法试试看，比如这个帖子：[Build Qt Static Make Error - \[SOLVED\]](https://forum.qt.io/topic/59045/build-qt-static-make-error-solved)， 官方论坛官方回答，看着靠谱。哦：

```
./configure --prefix=/opt/qt.5.4.0 -release -opensource -confirm-license -static -qt-xcb -no-openssl -no-glib -no-pulseaudio -no-alsa -opengl desktop -nomake examples -nomake tests

# 然后真的过了
make -j4
# 燃烧吧 CPU。Winter is Coming!!!!!!


rm -f ../../lib/libQt5Widgets.a
mv -f libQt5Widgets.a ../../lib/ 
make[3]: Leaving directory '/home/adam/Downloads/Persepolis/qt-everywhere-opensource-src-5.4.0/qtbase/src/widgets'
make[2]: Leaving directory '/home/adam/Downloads/Persepolis/qt-everywhere-opensource-src-5.4.0/qtbase/src'
Makefile:45: recipe for target 'sub-src-make_first' failed
make[1]: *** [sub-src-make_first] Error 2
make[1]: Leaving directory '/home/adam/Downloads/Persepolis/qt-everywhere-opensource-src-5.4.0/qtbase'
Makefile:70: recipe for target 'module-qtbase-make_first' failed
make: *** [module-qtbase-make_first] Error 2
```

还是上面那个报错 .... 我也不知道为啥了，好吧老实点先把不知道的选项拿掉，本着对**官方论坛官方回答**的相信，那一堆复制过来的的选项我都没看。重新来过：

```
./configure --prefix=/opt/qt.5.4.0 -release -opensource -confirm-license -no-openssl -qt-xcb -nomake examples -nomake tests

...........

Makefile:45: recipe for target 'sub-src-make_first' failed
make[1]: *** [sub-src-make_first] Error 2
make[1]: Leaving directory '/home/adam/Downloads/Persepolis/qt-everywhere-opensource-src-5.4.0/qtbase'
Makefile:70: recipe for target 'module-qtbase-make_first' failed
make: *** [module-qtbase-make_first] Error 2
```

报错依然，上网一顿查，Google 看了 N 多都是交叉编译的问题，感觉很奇怪而且错误和我不完全一样。百度，各种论坛都是提问题的没有回答的。


N 久无果，中间 2~3 个小时过去了。


我开始思索是不是我哪里做法有问题。

这时我突然记起来之前尝试编译 RStudio 的时候，从 [RStudio 的 GitHub repo](https://github.com/rstudio/rstudio) 里的安装依赖的脚本里看到编译 RStudio 的时候会依照里面的设置从他们自己的 AWS 服务器上下载他们精（魔）简（改）的 Qt binary 的。这洋一想我直接去用他们的 Qt 编译岂不是更好。二话不说去 GitHub 看他们的 Qt 放在哪儿。你看他们的 `rstudio/dependencies/linux/install-qt-sdk` 里写的：

```
# presume 5.4.0
QT_VERSION=5.4.0

# test for libgstreamer
which apt-cache > /dev/null
if [ $? == 0 ]; then
  # debian (currently no test for CentOS based systems)
  apt-cache show libgstreamer1.0 > /dev/null
  if [ $? == 0 ]; then
    QT_VERSION=5.4.2
  fi
fi

QT_SDK_BINARY=QtSDK-${QT_VERSION}-${QT_ARCH}.tar.gz
QT_SDK_URL=https://s3.amazonaws.com/rstudio-buildtools/$QT_SDK_BINARY

# set Qt SDK dir if not already defined
if [ -z "$QT_SDK_DIR" ]; then
  QT_SDK_DIR=~/Qt${QT_VERSION}
fi

if ! test -e $QT_SDK_DIR
then
   # download and install
   wget $QT_SDK_URL -O /tmp/$QT_SDK_BINARY
   cd `dirname $QT_SDK_DIR`
   tar xzf /tmp/$QT_SDK_BINARY
   rm /tmp/$QT_SDK_BINARY
else
   echo "Qt $QT_VERSION SDK already installed"
fi
```

暴力暴力，够社会。

直接自己拼接出 QtSDK-5.4.0 的地址下下来了。由于这个已经是 binary 了就不需要我再编译了，直接用就行。
然后就是跟前面差不多了，十分顺利，没出错。解压他们的 Qt 放到 `/opt/qt.5.4.0`，export 配置临时路径和工具链，然后重新编译 `fictx-qt5`，得到 `libfcitxplatforminputcontextplugin.so`。

刚刚是 Mendeley 所以最后 `libfcitxplatforminputcontextplugin.so` 就拷贝到 `/opt/mendeleydesktop/plugins/qt/plugins/platforminputcontexts/`。同理，RStudio 就应该拷贝到 `/usr/lib/rstudio/bin/plugins/platforminputcontexts/` 了。

然后试了下 RStudio 终于，Fcitx 起来了。


# 放在最后不代表不重要

哦对了，我自己编译的 `libfcitxplatforminputcontextplugin.so` 我建了一个 [repo](https://github.com/JackieMium/libfcitxplatforminputcontextplugin.so)，也许谁要用的话可以试一试，在知乎上碰到一位用 Ubuntu 16.04 的网友用了我编译的文件解决了 ta 的输入法问题，我表示很开心。我会尽量保持 Mendeley 和 Rstudio 更新后 `libfcitxplatforminputcontextplugin.so` 不可用就更新，欢迎提 issue 催更或者 PR。

- 20180113 更新：有人告诉我其实 Fcitx 的一位开发者之前写过类似的东西 :[A case study: how to compile a Fcitx platforminputcontext plugin for a proprietary software that uses Qt 5](https://www.csslayer.info/wordpress/fcitx-dev/a-case-study-how-to-compile-a-fcitx-platforminputcontext-plugin-for-a-proprietary-software-that-uses-qt-5/)。好吧，怪我之前为啥没看到啊 ....

--------

以下是最初的更新记录，在整理后已经在本文的开头简要介绍了。这里仅作为记录用途继续保留。  

- 20180205 更新：详细思考了下整个过程，中间看了一些资料，也再一次尝试编译 Qt，由于这时候 RStudio 已经更新过，Qt 也更新为 Qt-5.4.2。简单记录过程如下：

1. 编译 Qt 的 `configure` ：
  在 `/opt` 建立相应文件夹后，再建立一个指向这个文件夹的软链接 `qt5`。这么做的理由在 BLFS 的 HandBook 中编译 Qt5 有说明：[Qt-5.4.2 ](http://anduin.linuxfromscratch.org/~bdubbs/blfs-book-xsl/x/qt5.html)，深以为然。
```
../configure -v -prefix /opt/qt5 -shared -largefile -accessibility -no-qml-debug -force-pkg-config \
-release -opensource -confirm-license -optimized-qmake \
-system-zlib -no-mtdev -system-libpng -system-libjpeg -system-freetype -fontconfig -system-harfbuzz \
-no-compile-examples -icu -qt-xcb -qt-xkbcommon -xinput2 -glib \
-no-pulseaudio -no-alsa -gtkstyle -no-openssl \
-nomake examples -nomake tests -no-compile-examples -skip qtdoc
```
具体参数的含义还是去看 help 输出。


2. 编译安装完 Qt 后，首先应该把 Qt 的 `bin` 目录加到 `PATH` 里，这里的建议还是 `export` 这样做。
  比较重要的是 `LD_LIBRARY_PATH` 的问题。
  首先看看最终我们需要的 `libfcitxplatforminputcontextplugin.so` 到底需要些什么：
```
➜  ~ ldd /opt/mendeleydesktop/plugins/qt/plugins/platforminputcontexts/libfcitxplatforminputcontextplugin.so
	linux-vdso.so.1 (0x00007ffc89d4a000)
	libQt5Gui.so.5 => /opt/qt.5.5.1/lib/libQt5Gui.so.5 (0x00007faee03c0000)
	libQt5DBus.so.5 => /opt/qt.5.5.1/lib/libQt5DBus.so.5 (0x00007faee0d24000)
	libxkbcommon.so.0 => /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 (0x00007faee0180000)
	libQt5Core.so.5 => /opt/qt.5.5.1/lib/libQt5Core.so.5 (0x00007faedfcc6000)
	libstdc++.so.6 => /usr/lib/x86_64-linux-gnu/libstdc++.so.6 (0x00007faedf941000)
	libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007faedf5ae000)
	libgcc_s.so.1 => /lib/x86_64-linux-gnu/libgcc_s.so.1 (0x00007faedf396000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007faedefdc000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007faededbe000)
	libpng16.so.16 => /usr/lib/x86_64-linux-gnu/libpng16.so.16 (0x00007faedeb8b000)
	libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007faede971000)
	libGL.so.1 => /usr/lib/x86_64-linux-gnu/libGL.so.1 (0x00007faede6e5000)
	libicui18n.so.57 => /usr/lib/x86_64-linux-gnu/libicui18n.so.57 (0x00007faede271000)
	libicuuc.so.57 => /usr/lib/x86_64-linux-gnu/libicuuc.so.57 (0x00007faeddecc000)
	libicudata.so.57 => /usr/lib/x86_64-linux-gnu/libicudata.so.57 (0x00007faedc44f000)
	libpcre16.so.3 => /usr/lib/x86_64-linux-gnu/libpcre16.so.3 (0x00007faedc1e8000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007faedbfe4000)
	libgthread-2.0.so.0 => /usr/lib/x86_64-linux-gnu/libgthread-2.0.so.0 (0x00007faedbde2000)
	libglib-2.0.so.0 => /lib/x86_64-linux-gnu/libglib-2.0.so.0 (0x00007faedbace000)
	librt.so.1 => /lib/x86_64-linux-gnu/librt.so.1 (0x00007faedb8c6000)
	/lib64/ld-linux-x86-64.so.2 (0x00007faee0b79000)
	libGLX.so.0 => /usr/lib/x86_64-linux-gnu/libGLX.so.0 (0x00007faedb695000)
	libGLdispatch.so.0 => /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0 (0x00007faedb3df000)
	libpcre.so.3 => /lib/x86_64-linux-gnu/libpcre.so.3 (0x00007faedb16d000)
	libX11.so.6 => /usr/lib/x86_64-linux-gnu/libX11.so.6 (0x00007faedae2d000)
	libXext.so.6 => /usr/lib/x86_64-linux-gnu/libXext.so.6 (0x00007faedac1b000)
	libxcb.so.1 => /usr/lib/x86_64-linux-gnu/libxcb.so.1 (0x00007faeda9f3000)
	libXau.so.6 => /usr/lib/x86_64-linux-gnu/libXau.so.6 (0x00007faeda7ef000)
	libXdmcp.so.6 => /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 (0x00007faeda5e9000)
	libbsd.so.0 => /lib/x86_64-linux-gnu/libbsd.so.0 (0x00007faeda3d4000)
```
发现对于对应 Qt 的话，需要 `libQt5Gui.so.5`，`libQt5DBus.so.5` 和 `libQt5Core.so.5` 这三个库。
看看系统到底有没有这 3 个库呢：
```
➜  ~ locate libQt5Core.so.5
/home/adam/.aspera/connect/lib/libQt5Core.so.5
/home/adam/Downloads/Persepolis/qt-everywhere-opensource-src-5.5.1/qtbase/lib/libQt5Core.so.5
/home/adam/Downloads/Persepolis/qt-everywhere-opensource-src-5.5.1/qtbase/lib/libQt5Core.so.5.5
/home/adam/Downloads/Persepolis/qt-everywhere-opensource-src-5.5.1/qtbase/lib/libQt5Core.so.5.5.1
/home/adam/Programs/foxitsoftware/lib/libQt5Core.so.5
/home/adam/Programs/foxitsoftware/lib/libQt5Core.so.5.3
/home/adam/Programs/foxitsoftware/lib/libQt5Core.so.5.3.2
/home/adam/miniconda3/envs/Python_27/lib/libQt5Core.so.5
/home/adam/miniconda3/envs/Python_27/lib/libQt5Core.so.5.6
/home/adam/miniconda3/envs/Python_27/lib/libQt5Core.so.5.6.2
/home/adam/miniconda3/lib/libQt5Core.so.5
/home/adam/miniconda3/lib/libQt5Core.so.5.6
/home/adam/miniconda3/lib/libQt5Core.so.5.6.2
/home/adam/miniconda3/pkgs/qt-5.6.2-2/lib/libQt5Core.so.5
/home/adam/miniconda3/pkgs/qt-5.6.2-2/lib/libQt5Core.so.5.6
/home/adam/miniconda3/pkgs/qt-5.6.2-2/lib/libQt5Core.so.5.6.2
/home/adam/miniconda3/pkgs/qt-5.6.2-3/lib/libQt5Core.so.5
/home/adam/miniconda3/pkgs/qt-5.6.2-3/lib/libQt5Core.so.5.6
/home/adam/miniconda3/pkgs/qt-5.6.2-3/lib/libQt5Core.so.5.6.2
/home/adam/miniconda3/pkgs/qt-5.6.2-4/lib/libQt5Core.so.5
/home/adam/miniconda3/pkgs/qt-5.6.2-4/lib/libQt5Core.so.5.6
/home/adam/miniconda3/pkgs/qt-5.6.2-4/lib/libQt5Core.so.5.6.2
/home/adam/miniconda3/pkgs/qt-5.6.2-5/lib/libQt5Core.so.5
/home/adam/miniconda3/pkgs/qt-5.6.2-5/lib/libQt5Core.so.5.6
/home/adam/miniconda3/pkgs/qt-5.6.2-5/lib/libQt5Core.so.5.6.2
/opt/mendeleydesktop/lib/qt/libQt5Core.so.5
/opt/qt.5.5.1/lib/libQt5Core.so.5
/opt/qt.5.5.1/lib/libQt5Core.so.5.5
/opt/qt.5.5.1/lib/libQt5Core.so.5.5.1
/usr/lib/rstudio/bin/libQt5Core.so.5
/usr/lib/rstudio/bin/libQt5Core.so.5.4.2
/usr/lib/x86_64-linux-gnu/libQt5Core.so.5
/usr/lib/x86_64-linux-gnu/libQt5Core.so.5.9
/usr/lib/x86_64-linux-gnu/libQt5Core.so.5.9.2
➜  ~ locate ibQt5DBus.so.5 
/home/adam/.aspera/connect/lib/libQt5DBus.so.5
/home/adam/Downloads/Persepolis/qt-everywhere-opensource-src-5.5.1/qtbase/lib/libQt5DBus.so.5
/home/adam/Downloads/Persepolis/qt-everywhere-opensource-src-5.5.1/qtbase/lib/libQt5DBus.so.5.5
/home/adam/Downloads/Persepolis/qt-everywhere-opensource-src-5.5.1/qtbase/lib/libQt5DBus.so.5.5.1
/home/adam/Programs/foxitsoftware/lib/libQt5DBus.so.5
/home/adam/Programs/foxitsoftware/lib/libQt5DBus.so.5.3
/home/adam/Programs/foxitsoftware/lib/libQt5DBus.so.5.3.2
/home/adam/miniconda3/envs/Python_27/lib/libQt5DBus.so.5
/home/adam/miniconda3/envs/Python_27/lib/libQt5DBus.so.5.6
/home/adam/miniconda3/envs/Python_27/lib/libQt5DBus.so.5.6.2
/home/adam/miniconda3/lib/libQt5DBus.so.5
/home/adam/miniconda3/lib/libQt5DBus.so.5.6
/home/adam/miniconda3/lib/libQt5DBus.so.5.6.2
/home/adam/miniconda3/pkgs/qt-5.6.2-2/lib/libQt5DBus.so.5
/home/adam/miniconda3/pkgs/qt-5.6.2-2/lib/libQt5DBus.so.5.6
/home/adam/miniconda3/pkgs/qt-5.6.2-2/lib/libQt5DBus.so.5.6.2
/home/adam/miniconda3/pkgs/qt-5.6.2-3/lib/libQt5DBus.so.5
/home/adam/miniconda3/pkgs/qt-5.6.2-3/lib/libQt5DBus.so.5.6
/home/adam/miniconda3/pkgs/qt-5.6.2-3/lib/libQt5DBus.so.5.6.2
/home/adam/miniconda3/pkgs/qt-5.6.2-4/lib/libQt5DBus.so.5
/home/adam/miniconda3/pkgs/qt-5.6.2-4/lib/libQt5DBus.so.5.6
/home/adam/miniconda3/pkgs/qt-5.6.2-4/lib/libQt5DBus.so.5.6.2
/home/adam/miniconda3/pkgs/qt-5.6.2-5/lib/libQt5DBus.so.5
/home/adam/miniconda3/pkgs/qt-5.6.2-5/lib/libQt5DBus.so.5.6
/home/adam/miniconda3/pkgs/qt-5.6.2-5/lib/libQt5DBus.so.5.6.2
/opt/mendeleydesktop/lib/qt/libQt5DBus.so.5
/opt/mendeleydesktop/lib/qt/libQt5DBus.so.5.5
/opt/mendeleydesktop/lib/qt/libQt5DBus.so.5.5.1
/opt/qt.5.5.1/lib/libQt5DBus.so.5
/opt/qt.5.5.1/lib/libQt5DBus.so.5.5
/opt/qt.5.5.1/lib/libQt5DBus.so.5.5.1
/usr/lib/rstudio/bin/libQt5DBus.so.5
/usr/lib/rstudio/bin/libQt5DBus.so.5.4.2
/usr/lib/x86_64-linux-gnu/libQt5DBus.so.5
/usr/lib/x86_64-linux-gnu/libQt5DBus.so.5.9
/usr/lib/x86_64-linux-gnu/libQt5DBus.so.5.9.2
➜  ~ locate libQt5Gui.so.5
/home/adam/.aspera/connect/lib/libQt5Gui.so.5
/home/adam/Downloads/Persepolis/qt-everywhere-opensource-src-5.5.1/qtbase/lib/libQt5Gui.so.5
/home/adam/Downloads/Persepolis/qt-everywhere-opensource-src-5.5.1/qtbase/lib/libQt5Gui.so.5.5
/home/adam/Downloads/Persepolis/qt-everywhere-opensource-src-5.5.1/qtbase/lib/libQt5Gui.so.5.5.1
/home/adam/Programs/foxitsoftware/lib/libQt5Gui.so.5
/home/adam/Programs/foxitsoftware/lib/libQt5Gui.so.5.3
/home/adam/Programs/foxitsoftware/lib/libQt5Gui.so.5.3.2
/home/adam/miniconda3/envs/Python_27/lib/libQt5Gui.so.5
/home/adam/miniconda3/envs/Python_27/lib/libQt5Gui.so.5.6
/home/adam/miniconda3/envs/Python_27/lib/libQt5Gui.so.5.6.2
/home/adam/miniconda3/lib/libQt5Gui.so.5
/home/adam/miniconda3/lib/libQt5Gui.so.5.6
/home/adam/miniconda3/lib/libQt5Gui.so.5.6.2
/home/adam/miniconda3/pkgs/qt-5.6.2-2/lib/libQt5Gui.so.5
/home/adam/miniconda3/pkgs/qt-5.6.2-2/lib/libQt5Gui.so.5.6
/home/adam/miniconda3/pkgs/qt-5.6.2-2/lib/libQt5Gui.so.5.6.2
/home/adam/miniconda3/pkgs/qt-5.6.2-3/lib/libQt5Gui.so.5
/home/adam/miniconda3/pkgs/qt-5.6.2-3/lib/libQt5Gui.so.5.6
/home/adam/miniconda3/pkgs/qt-5.6.2-3/lib/libQt5Gui.so.5.6.2
/home/adam/miniconda3/pkgs/qt-5.6.2-4/lib/libQt5Gui.so.5
/home/adam/miniconda3/pkgs/qt-5.6.2-4/lib/libQt5Gui.so.5.6
/home/adam/miniconda3/pkgs/qt-5.6.2-4/lib/libQt5Gui.so.5.6.2
/home/adam/miniconda3/pkgs/qt-5.6.2-5/lib/libQt5Gui.so.5
/home/adam/miniconda3/pkgs/qt-5.6.2-5/lib/libQt5Gui.so.5.6
/home/adam/miniconda3/pkgs/qt-5.6.2-5/lib/libQt5Gui.so.5.6.2
/opt/mendeleydesktop/lib/qt/libQt5Gui.so.5
/opt/qt.5.5.1/lib/libQt5Gui.so.5
/opt/qt.5.5.1/lib/libQt5Gui.so.5.5
/opt/qt.5.5.1/lib/libQt5Gui.so.5.5.1
/usr/lib/rstudio/bin/libQt5Gui.so.5
/usr/lib/rstudio/bin/libQt5Gui.so.5.4.2
/usr/lib/x86_64-linux-gnu/libQt5Gui.so.5
/usr/lib/x86_64-linux-gnu/libQt5Gui.so.5.9
/usr/lib/x86_64-linux-gnu/libQt5Gui.so.5.9.2
```
发现一个很有意思的事情：我们要的库文件系统 `/usr/lib/x86_64-linux-gnu/` 下有一份，Miniconda 有一份，我们编译出的 `/opt/qt.5.5.1/lib/` 有一份，还有哪里呢，`/usr/lib/rstudio/bin/` 和 `/opt/mendeleydesktop/lib/qt/`。这个就有意思了，就是说库其实好多份，好，系统有的和 Miniconda 的不说，版本不对，我们自己编译的不说。软件自己竟然带了一份，那就有个便利了，那就是说理论上我们编译这些库完全是多此一举，因为我们完全可以直接链接到软件自带的库啊，这样的话不用说库版本绝对没问题。

所以我们需要干嘛呢，`export LD_LIBRARY_PATH` 要么使用自己编译出来的 Qt 库，要么使用软件自己带的库。我试验了下，两种办法都可以。

我仔细看了之前的博客，不知道为什么竟然没有提到 `LD_LIBRARY_PATH` 的事情，但是最后 `libfcitxplatforminputcontextplugin.so` 链接到了 `/opt` 下我自己编译的库文件，想来我中间可能 `export` 过但是自己忘了，现在才发现这个才是最重要的步骤啊。惭愧。

-----

- 2018-08-16 重要更新：目前发现一种 **最最最最最最简单的办法**。Debian 下进入 `/usr/lib/rstudio/bin` 目录，直接 ~删掉~ 所有 `libQt5` 开头的文件和 `qt.conf` 即可（测试时不要直接删掉，重命名备份就行了）。
我的做法是：

```bash
cd /usr/lib/rstudio/bin
sudo mkdir Qt
sudo mv libQt5* Qt
sudo mv qt.conf Qt
```

然后再打开 RStudio 测试 Fcitx 输入法是否可用。

这个方法的原理在于，Fcitx 在 RStudio 里不能用是因为 RStudio 使用的 Qt 库版本与系统版本不同，而我们系统的 Fcitx 在编译时是链接到系统的 Qt 库版本的。而我们把 RStudio 自带的 Qt 库删掉之后会迫使 RStudio 调用系统的 Qt 库，即迫使它调用了 Fcitx 一样的版本库，所以这时候 RStudio 和其他 Qt 程序一样就能直接调用 Fcitx 本来的插件了（ `libfcitxplatforminputcontextplugin.so` 这个插件在 Debian 就是 `fcitx-frontend-qt5` 这个包）。

**说明**：  这个方法并不是我想到的，来自**统计之都论坛**的一篇帖子 : [win10 下 Rstudio 切换中文输入法问题](https://d.cosx.org/d/419556-win10-rstudio) 。感谢 @linjinzhen！

----

- 2018-12-08 更新：最新的 RStudio 版本为 1.2.1114 (我使用了 daily build 版)，Qt 版本为 Qt-5.11.1。RStudio 自带的 `libQt5*` 文件保存在 `/usr/lib/rstudio/lib` 下，按照之前的方法移除这些文件的办法又失效了。不得已只能又一次自己编译了。
简单记录如下：
    - 下载 `qt-opensource-linux-x64-5.11.1.run`，安装
    - Terminal 临时 `export` 下 `PATH` 和 `LD_LIBRARY_PATH`
    - 编译 fcitx-qt5
    - 得到的 `platforminputcontexts/libfcitxplatforminputcontextplugin.so` 复制到 `/usr/lib/rstudio/plugins/platforminputcontexts`。

    ```bash
    export PATH=/opt/qt5/5.11.1/gcc_64/bin:$PATH
    export LD_LIBRARY_PATH=/opt/qt5/5.11.1/gcc_64/lib:$LD_LIBRARY_PATH
    
    # double check
    echo $PATH
    echo $LD_LIBRARY_PATH
    
    cd /path/to/fcitx-qt5
    cmake .
    make -j 4
    ```

最新的 `libfcitxplatforminputcontextplugin.so` 也已经同步更新到我的 [repo](https://github.com/JackieMium/libfcitxplatforminputcontextplugin.so/tree/master/lib-fcitx-plugin/debian.sid.20181208)，不会或者懒得编译的人自己去下载吧。

----

- 2019-03-18：修改错别字，修改部分语句，全文结构和内容未作改动。