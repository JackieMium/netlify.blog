---
title: "startx and xinit"
date: 2026-01-24T22:08:43-06:00
lastmod: 2026-01-30T20:53:11-06:00
draft: false
keywords: []
description: ""
tags: []
categories: []
author: ""
---



# 从零开始搭建 Xorg 图形环境

如果在刚接触 Linux 的时候就看到这个系列视频: [An X Window System 
Tutorial](https://www.youtube.com/playlist?list=PLA8E036608C60B7E5) 
 可能会更有意思。当然现在也不晚。

这个系列视频是非常好的 
Xserver/Xorg/X 和窗口管理器（Window Manager，WM），桌面环境（Desktop 
Environment，DE）的入门教程，对于理解在类 Unix 环境下图形界面的工作和配置有很大帮助。 

首先推荐阅读参考下面这些文档:

- [Xorg(1)](https://www.x.org/archive/X11R7.5/doc/man/man1/Xorg.1.html)
- [X(7)](https://www.x.org/archive/X11R7.5/doc/man/man7/X.7.html)
- [xinit(1)](https://www.x.org/archive/X11R7.5/doc/man/man1/xinit.1.html)
- [startx(1)](https://www.x.org/archive/X11R7.5/doc/man/man1/startx.1.html) 

默认情况下，在安装了 Xorg 之后，如果直接在 tty 下执行 `X` 或者 `Xorg` 命令会启动一个图形环境。但是由于这时候既没有任何 
WM 或 DE 运行，也没有任何打开应用，“桌面背景/壁纸”也没有任何设置，所以看到的将是一个纯黑色的屏幕。这里桌面背景/壁纸打上引号，就是为了表明这个时候因为根本也没有“桌面”在运行，所以壁纸的概念其实都是不存在的。这种纯黑屏就导致用户甚至无法轻易分辨到底是命令执行失败屏幕黑屏还是 X 
已经启动了。当然可以切换到其他 tty 通过 `ps` 查看，或者根据日志判断，但这都不是很方便的做法。所以一般至少要借助 `startx` 
或者 `xinit` 来启动图形环境并运行一些程序供使用，也能直接判断图形界面以及输入设备等是否正常工作。

不进行任何配置时，tty 下以 root 用户登录后运行 `startx` 依然和直接运行 `X` 或者 `Xorg` 相同。

不进行任何配置时，tty 下以 root 用户登录后运行 `xinit` 依然会启动纯黑色背景的图形界面，不同的是同时还会默认会启动一个 `xterm` 
窗口。这个时候用户可以立刻知道图形已经正常运行，尝试键盘鼠标等也能知道其他重要设备是否能正常使用。由于 `xinit` 
默认第一个参数是针对客户端程序，这种情况下第一个参数就直接传给 `xterm` 本身。所以运行：

```
xinit -fa 'mono' -fs 11 -g 100x40+50+50
```

相当于在启动 X 环境后再运行 `xterm -fa 'mono' -fs 11 -g 100x40+50+80` 
打开一个终端窗口。退出这个终端可以退出整个图形环境回到之前的 tty。

以这种形式运行的 `xinit` 的参数也可以原封不动地用于 `startx` 命令。因为二者都在默认情况下将第一个参数传递给 
`xterm`。

到这里，已经可以用最简单的形式测试运行图形环境。同时由于在此基础上还可以启动一个终端窗口，所以理论上这时候图形环境已经可以用于很多不同任务，因为在终端里用户可以启动任何需要的程序。比如在这个 xterm 窗口里我们可以依次执行： 


```
/usr/bin/xsetroot -cursor_name left_ptr
/usr/bin/xsetroot -solid 'rgb:00/22/44'
/usr/bin/xclock -digital \
    -strftime '%Y-%m-%d %H:%M' \
    -face "mono:pixelsize=14" \
    -g +10+10 &
/usr/bin/xeyes -g 80x40-50+80 &

/usr/bin/uxterm \
    -title 'login' \
    -fa 'mono' -fs 11 \
    -bc -b 8 \
    -g 60x40-20-20
```


来设置鼠标图标风格，屏幕背景填充色，在左上角显示时钟，在右上角打开 xeyes 程序，最后再打开一个 uxterm 终端窗口。

但是使用起来很快可以发现，这时候的图形环境非常简单，使用时会有很多不便利。比如，在一个 xterm 终端窗口里运行 xterm 
或其他程序再打开一个程序窗口，新打开的窗口如果覆盖了这个已经存在 xterm 
窗口，用户在不关闭当前新启动的程序窗口的情况下，无法再把被遮盖的窗口完整显示出来，因此自然也多半无法继续再使用这个被遮盖的窗口。虽然大多数程序都支持在启动时指定窗口大小和位置，向上面一连串的命令里打开的新窗口都设置了窗口位置和大小，但是用户当然不想每次想要启动新程序都需要精确计算窗口大小和位置。

这就是窗口管理器 WM 要解决的问题。WM 顾名思义，管理图形界面中的窗口。最简单的，它允许用户在程序启动程序后还可以移动窗口、调整窗口大小等等基础操作。有了窗口管理器，用户不需要每次都考虑打开新程序时窗口应该设置多大和放在屏幕上的什么位置才不会遮盖其他窗口，因为用户可以在之后任何时候调整。

以 [evilwm](https://www.6809.org.uk/evilwm/) 这个 WM 为例，tty 运行 `xinit 
/usr/bin/evilwm` 或者 `startx /usr/bin/evilwm` 将图形界面启动 evilwm 会话，键盘按 
Ctrl-Alt-ENTER 快捷键可以启动一个 xterm 终端窗口，再按 Ctrl-Alt-ENTER 启动另一个 
xterm，到这里这个图形环境除了可以使用快捷键启动 xterm 之外看不出和前面有什么差别。然而，按 Ctrl-Alt-H/J/K/L 
就会知道现在可以以类 vim 风格快捷键自由移动当前窗口，Ctrl-Shift-Alt-H/J/K/L 
则可以调整窗口大小。如果有鼠标或者触摸板等设备的话， 也可以用来调整窗口大小和位置。

类似的，如果以同样方式启动 [twm](https://gitlab.freedesktop.org/xorg/app/twm) 
会启动图形界面显示黑色屏幕，单击鼠标左键鼠标图标下方会弹出应用程序菜单，如果启动一个 Shell 
程序或者终端，鼠标图标下方又会出现一个窗口边框，可以移动位置，再次点击在当前位置启动边框大小的 
xterm。这个窗口不仅有标题栏显示窗口名称，而且鼠标左键按住标题栏拖拽可以移动窗口位置，同时标题栏两端还提供了最小化和调整窗口大小的按钮。

这就是 WM 
提供的最基础的功能，可它们可以让用户在图形界面下用图形的方式高效地在整个屏幕空间上使用多个程序窗口。不同的 WM 
的操作方式和窗口放置和排列方式可能非常不同，但是它们都提供类似功能，比如控制窗口大小和位置，窗口显示风格（边框，标题栏，操作按钮等等）等。

这里有一个小问题没提到：在 evilwm 启动后默认可以快捷键启动一个终端，在 twm 里也有右键菜单可以启动终端，但是如果使用的是 
[pekwm](https://www.pekwm.se/pekwm/index) 
就会发现启动后没有任何方式可以打开终端。这时候图形环境和最初介绍的直接在 tty 执行 `X` 或者 `Xorg` 
非常类似，屏幕显示纯黑色，没有任何窗口。

幸好，`xinit` 和 `startx` 推荐用户提供启动配置文件 `xinitrc`。简单地说，用户提供一个 
`$HOME/.xinitrc` 的 Shell 脚本配置文件，不带任何参数执行 `xinit` 或 `startx` 
时它们会根据这个配置文件来启动图形环境。比如上面的例子简单修改一下写入 `$HOME/.xinitrc`:  

```
#!/usr/bin/env sh
USER_RESOURCES=${HOME}/.Xresources
if [ -f $USER_RESOURCES ]; then xrdb -merge $USER_RESOURCES; fi
unset USER_RESOURCES

/usr/bin/xsetroot -cursor_name left_ptr
/usr/bin/xsetroot -solid 'rgb:00/70/90'
/usr/bin/xclock -digital \
    -strftime '%Y-%m-%d %H:%M' \
    -face "mono:pixelsize=14" \
    -g +10+10 &
/usr/bin/xeyes -g 80x40+200+10 &

/usr/bin/uxterm -g 105x44+30-30 &
#/usr/bin/twm &
#/usr/bin/evilwm --bw 2 -term uxterm &
/usr/bin/pekwm &

/usr/bin/uxterm -name 'login' -g 60x40-20-20
```

在这个配置文件里，除了之前一样设置鼠标、屏幕背景等任务外，还分别在屏幕左右两侧启动了一个终端，并且启动了 pekwm 本身。这样，现在在 
tty 执行 `xinit` 或 `startx` 会启动 pekwm 
并且进行执行所有这些指令，用户立刻得到一个设置好背景的屏幕，屏幕上启动了 xeyes 和 xclock，以及两个终端窗口。

注意这里在启动 xclock、xeyes、pekwm 以及第一个 uxterm 终端时都指定了 `&` 
使命令后台执行，这是因为如果不后台执行的话，脚本会停留在目前执行的命令，因为这个命令会一直前台运行，所以无法到达后面的指令。后台执行时，脚本执行到当前命令时会将它放到后台继续运行并开始执行下一条指令，所以最后我们才能一一执行每一条执行得到一个启动了多个程序的图形环境。另外，在这个配置脚本的最后一行启动第二个 uxterm 时不再后台执行。因为这是最后一条指令，如果仍然设置后台执行的话，`startx` 或 `xinit` 执行到这条执行时执行成功并放到后台，到这里所有执行都正确执行，脚本就直接退出了，图形界面会在启动瞬间迅速执行完成退出，用户回到之前的 tty。将最后一条指令放在前台执行使整个脚本运行到这条指令时前台执行而不退出，这样整个图形界面就能维持。也正因为整个图形环境由最后一跳指令维持，这时候用户如果在图形界面停止这条指令，图形界面也会关闭。比如上面的例子里，如果用户在图形界面退出位于屏幕右边的第二个终端，图形环境会立刻结束回到 tty。最后一条指令可以替换成任意其他程序，只要用户退出该程序图形环境都会结束运行。

现在，用户通过 `$HOME/.xinitrc` 
配置文件，可以快速启动一个图形环境，根据该文件启动需要的程序或者在图形环境启动后再启动其他程序，并且还可以通过 WM 
对程序进行各种调整，最后还可以在需要的时候随时退出图形环境。整个使用体验已经非常便利。

和现代化的 DE 相比，这种方式完全通过命令和配置文件完成各种任务，也不需要显示管理器（Display Manager，DM），而是在 tty 
下直接启动到图形环境。当然，这种方式不仅可以启动 WM，也可以以同样的方式启动各种 DE。但是如果用户想在系统启动时直接启动到图形环境不再通过 
tty 执行指令，则需要安装 DM 并配置 DM 自动启动。常用的 DM 包括经典的 XDM 和 Slim，以及更加现代化的 GDM、SDDM 
和 LightDM 等等，已经超过本文范围，这里不再继续展开。

## One More Thing

在本文最开始介绍直接在 tty 运行 `X` 或者 `Xorg` 启动图形界面的场景里，用户进入一个除了 X 本身外没有任何图形程序的环境，此时鼠标和键盘也无法启动任何程序，无法退出当前环境。要退出回到 tty 的方法，要么通过 Ctrl-Alt-[Fn] 切换到已有的 tty，或通过 ssh 等工具从其他设备登录，然后通过 `pkill` 类似的命令结束当前 X 进程。但是这两种方案显然都不够优雅。幸好，Xorg 本身支持通过 Ctrl-Alt-Backspace 快捷键立刻结束当前图形环境，这个图形环境可以是 X/Xorg，也可以是一个 WM 环境。大多数现在的 Linux 发行版都默认禁用了这个快捷键，但是仍然支持通过配置文件启用。比如创建文件 `/etc/X11/xorg.conf.d/90-zap.conf`:

```
Section "InputClass"
    Identifier      "Keyboard Defaults"
    MatchIsKeyboard "yes"
    Option          "XkbOptions" "terminate:ctrl_alt_bksp"
EndSection
```

就可以通过键盘配置启用这个快捷键。很多地方推荐使用 `ServerFlags` 来配置这个选项：

```
Section "ServerFlags"
    Option "DontZap" "false"
EndSection
```

但是[这个配置方法并非在所有情况下都可行](https://unix.stackexchange.com/questions/375/how-to-enable-killing-xorg-with-ctrlaltbackspace)，前一种配置 `InputClass` 选项的方法更加普适。

## More to read

- [An X Window System Tutorial](https://www.youtube.com/playlist?list=PLA8E036608C60B7E5)
- [How to configure X11 in a simple way](https://eugene-andrienko.com/it/2025/07/24/x11-configuration-simple.html)
- [Xorg(1)](https://www.x.org/archive/X11R7.5/doc/man/man1/Xorg.1.html)
- [X(7)](https://www.x.org/archive/X11R7.5/doc/man/man7/X.7.html)
- [xorg.conf(5)](https://www.x.org/archive/X11R6.8.0/doc/xorg.conf.5.html)
- [xinit(1)](https://www.x.org/archive/X11R7.5/doc/man/man1/xinit.1.html)
- [startx(1)](https://www.x.org/archive/X11R7.5/doc/man/man1/startx.1.html)