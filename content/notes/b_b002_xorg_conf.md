---
title: "Xorg basics"
date: 2026-01-25T21:31:31-06:00
lastmod: 2026-01-30T22:12:42-06:00
draft: false
keywords: []
description: ""
tags: []
categories: []
author: ""
---

# Xorg 图形输出配置

在使用 QEMU 运行虚拟机需要客户（Guest）系统图形界面的时候，有多个图形选项：

```
$ qemu-system-amd64 -vga help

none                 no graphic card
std                  standard VGA (default)
cirrus               Cirrus VGA
vmware               VMWare SVGA
qxl                  QXL VGA
virtio               Virtio VGA
```

默认的 std 运行普通的图形环境已经足够，运行 1080p 显示也足以。但是如果想使用更高分辨率比如 2K 及以上，或者使用多显示器，则推荐使用 qxl。

使用 qxl 时虚拟机系统需要安装单独的 qxl 驱动，通常包名类似于 `xserver-xorg-video-qxl`。安装了这个驱动后再启动图形化环境，查看 `lspci -v` 的 VGA 设备就可以确认驱动已经加载使用。另外还可以查看 `/var/log/Xorg.0.log` 确认，非 root 用户查看 `~/.local/share/xorg/Xorg.0.log`:

```
$ lspci -v |grep -A 10 VGA

00:02.0 VGA compatible controller: Red Hat, Inc. QXL paravirtual graphic card (rev 05) (prog-if 00 [VGA controller])
        Subsystem: Red Hat, Inc. QEMU Virtual Machine
        Flags: bus master, fast devsel, latency 0, IRQ 10
        Memory at 80000000 (32-bit, non-prefetchable) [size=128M]
        Memory at 88000000 (32-bit, non-prefetchable) [size=64M]
        Memory at 8c040000 (32-bit, non-prefetchable) [size=8K]
        I/O ports at c0a0 [size=32]
        Expansion ROM at 000c0000 [disabled] [size=128K]
        Kernel driver in use: qxl
        Kernel modules: qxl

$ grep "Load\|Unload" Xorg.0.log

[    14.484] (II) Loader magic: 0x564db2ff7ea0
[    14.591] (II) LoadModule: "glx"
[    14.592] (II) Loading /usr/lib/xorg/modules/extensions/libglx.so
[    14.597] (II) LoadModule: "qxl"
[    14.597] (II) Loading /usr/lib/xorg/modules/drivers/qxl_drv.so
[    14.598] (II) LoadModule: "modesetting"
[    14.598] (II) Loading /usr/lib/xorg/modules/drivers/modesetting_drv.so
[    14.599] (II) LoadModule: "fbdev"
[    14.599] (II) LoadModule: "vesa"
[    14.599] (II) Loading /usr/lib/xorg/modules/drivers/vesa_drv.so
[    14.600] (II) Loading sub module "fb"
[    14.600] (II) LoadModule: "fb"
[    14.600] (II) Loading sub module "ramdac"
[    14.600] (II) LoadModule: "ramdac"
[    14.602] (II) UnloadModule: "modesetting"
[    14.602] (II) Unloading modesetting
[    14.602] (II) UnloadModule: "vesa"
[    14.602] (II) Unloading vesa
[    14.681] (II) IGLX: Loaded and initialized swrast
[    14.707] (II) LoadModule: "libinput"
[    14.707] (II) Loading /usr/lib/xorg/modules/input/libinput_drv.so
```

这篇笔记就来自于此。看日志的时候可以看到类似于：

```
(II) LoadModule: "qxl"
(II) LoadModule: "modesetting"
(II) LoadModule: "vesa"
(II) UnloadModule: "modesetting"
(II) UnloadModule: "vesa"
```

的输出。表示 Xorg 会尝试加载很多驱动，在确定适合的之后再去载其他不需要的驱动。所以需要一种方式来显式地指定显示驱动，这样 Xorg 在启动时会根据配置直接加载它而不会再去一个个尝试可用的驱动。在日志的最开始就能看到 Xorg 尝试在哪些位置去找配置文件：

```
(==) Using config directory: "/etc/X11/xorg.conf.d"
(==) Using system config directory "/usr/share/X11/xorg.conf.d"
```

用过 Gentoo Linux 当桌面系统的人应该会对这一步无比熟悉，因为在[配置 `Xorg` ](https://wiki.gentoo.org/wiki/Xorg/Guide)的时候经常需要这些配置文件。所以首先我们按照文件格式配置 `qxl` 显示驱动。在 `/etc/X11/xorg.conf.d` 目录下新建文件 `10.qxl.conf` 写入以下内容：

```
Section "Device"                                                                                                      
        Identifier "QXL0"
        BusID       "PCI:0:2:0"
        Driver "qxl"
EndSection
```

这里就直接按照 `lspci` 的输出确定显卡地址，给它一个命名 `QXL0`，最后指定驱动为 `qxl`。这个时候如果在查看 `Xorg.0.log` 的话就会发现只有 `qxl` 显示驱动会被加载使用。简单看一下日志输出直接少了很多行：

```
$ wc -l Xorg.0.log
282 Xorg.0.log

$ wc -l Xorg.0.log.no_qxl_config 
308 Xorg.0.log.no_qxl_config
```

其实到这里很明显，系统如果安装了其他的显示驱动应该都是可以卸载的，因为已经知道只需要 qxl 就已经足够。

现在再看日志开头很早的地方会看到类似这样的输出：

```
(==) Using config directory: "/etc/X11/xorg.conf.d"                                                                                                      
(==) Using system config directory "/usr/share/X11/xorg.conf.d"                                                                                          
(==) No Layout section.  Using the first Screen section.                                                                                                 
(==) No screen section available. Using defaults.                                                                                                        
(**) |-->Screen "Default Screen Section" (0)                                                                                                             
(**) |   |-->Monitor "<default monitor>"                                                                                                                 
(==) No device specified for screen "Default Screen Section".                                                                                            
 the first device section listed.                                                                                                                        
(**) |   |-->Device "QXL0"                                                                                                                               
(==) No monitor specified for screen "Default Screen Section".                                                                                           
        Using a default monitor configuration.
```

表明 Xorg 这个时候会在配置文件里查找 `Monitor` 和 `Screen` 的定义。依照 Xorg 文档来写一个加给 QXL0：


```
Section "ServerLayout"
  Identifier   "SLayout"
  Screen       "Screen0"
EndSection

Section "Monitor"
    Identifier  "Monitor0"
EndSection

Section "Screen"
    Identifier  "Screen0"                                                                                                                                 
    Device      "QXL0"
    Monitor     "Monitor0"                                                   
EndSection
```

这里按照逻辑顺序先定义一个顶层的 `ServerLayout` 命名为 `SLayout`，往下层定义一个 `Monitor` 命名为 `Virtual-1`，这个输出设备来自 `xrandr` 的显示的系统输出设备：

```
Virtual-1 connected primary 1024x768+0+0 0mm x 0mm
   1024x768      60.00*+
   4096x2160     60.00    59.94  
   ...
   640x480       59.94  
Virtual-2 disconnected
Virtual-3 disconnected
Virtual-4 disconnected
```

这里因为是虚拟机所以使用的输出设备的名称是 `Virtual-1`，在配置文件里就是把这个设备和 `Monitor` 对应起来。接着再往下最后定义 `Screen` 命名为 `Screen0` 并且把它和前面已有的 `QXL0` 和 `Virtual-1` 结合起来。再看日志就可以确认配置生效：

```
(==) Using config directory: "/etc/X11/xorg.conf.d"
(==) Using system config directory "/usr/share/X11/xorg.conf.d"
(==) ServerLayout "SLayout"
(**) |-->Screen "Screen0" (0)
(**) |   |-->Monitor "Virtual-1"
(**) |   |-->Device "QXL0"
```

这里从 `xrandr` 输出还可以看到这个虚拟机会默认把输出设备分辨率设置为 1024x768，但是设备支持从 4096x2160 到 640x480 多种分辨率。如果想把分辨率改为 1600x900，最简单的就是直接 `xrandr --output 'Virtual-1' --mode 1600x900`。但是这个方法需要每次都手动设置，或者自己把它添加到启动配置比如 `~/.xinitrc`，这当然不够*优雅*。既然已经在通过配置文件设置各种输入输出设备选项了，不如就在文件里设置好需要的分辨率：

```
Section "Monitor"
    Identifier "Virtual-1"
    Option "PreferredMode" "1600x900"
EndSection
```

非常简洁，在已有的输出设备里加上一个 `PreferredMode` 的选项，就可以设置默认分辨率。现在每次启动图形界面的时候，分辨率设置都会读取这个选项。

到这里，已经完全依赖配置文件，把 Xorg 设置为使用 qxl 驱动，并且启动时读取文件得到预先设置的分辨率。


最后，还有一个小小的设置可以改进。由于 qxl 支持多输出设备，从上面的 xrandr 输出和日志都可以发现，现在虚拟机默认配置了 Virtual-1 ~ Virtual-4 多个图形输出设备。这个虚拟机当然没有这么多输出设备可用，不如直接从配置文件里把它们关掉。在 ： 

```
Section "Monitor"
    Identifier "Virtual-2"
    Option "Ignore" "true"
EndSection
Section "Monitor"
    Identifier "Virtual-3"
    Option "Ignore" "true"
EndSection
Section "Monitor"
    Identifier "Virtual-4"
    Option "Ignore" "true"
EndSection
```

然后启动图形界面查看日志里面会出现类似以下内容：

```
(II) qxl(0): Output Virtual-1 using monitor section Virtual-1
(II) qxl(0): Output Virtual-2 has no monitor section
(II) qxl(0): Output Virtual-3 has no monitor section
(II) qxl(0): Output Virtual-4 has no monitor section
(II) qxl(0): Output Virtual-1 connected
(II) qxl(0): Output Virtual-2 disconnected 
(II) qxl(0): Output Virtual-3 disconnected 
(II) qxl(0): Output Virtual-4 disconnected 
(II) qxl(0): Output Virtual-1 using initial mode 1600x900 +0+0
```

可以看到其他的输出设备断开连接，现在再查看 `xrandr` 也不再也这些不需要的设备了。

最后，现在配置文件 `/etc/X11/xorg.conf.d/10.qxl.conf` 全部内容：

```
Section "Device"
        Identifier "QXL0"
        BusID       "PCI:0:2:0"
        Driver "qxl"
        Option     "Virtual-1" "M1"
EndSection

Section "ServerLayout"
  Identifier   "SLayout"
  Screen       "Screen0"
EndSection

Section "Monitor"
    Identifier "M1"
    Option "PreferredMode" "1600x900"
EndSection

Section "Screen"
    Identifier "Screen0"
    Device "QXL0"
    Monitor "M1"
    #SubSection "Display"
    #    Modes "1600x900" "1440x900" "1280x960"
    #EndSubSection
EndSection

#Section "ServerFlags"
#    Option "DontZap" "false"
#EndSection
#
Section "InputClass"
    Identifier      "Keyboard Defaults"
    MatchIsKeyboard "yes"
    Option          "XkbOptions" "terminate:ctrl_alt_bksp"
EndSection

Section "Monitor"
    Identifier "Virtual-2"
    Option "Ignore" "true"
EndSection
Section "Monitor"
    Identifier "Virtual-3"
    Option "Ignore" "true"
EndSection
Section "Monitor"
    Identifier "Virtual-4"
    Option "Ignore" "true"
EndSection
```

## 参考

- [QEMU User Documentation](https://www.qemu.org/docs/master/system/qemu-manpage.html)
- [VGA and other display devices in qemu](https://www.kraxel.org/blog/2019/09/display-devices-in-qemu/)
- [Xorg(1)](https://www.x.org/archive/X11R7.5/doc/man/man1/Xorg.1.html)
- [X(7)](https://www.x.org/archive/X11R7.5/doc/man/man7/X.7.html)
- [xorg.conf(5)](https://www.x.org/archive/X11R6.8.0/doc/xorg.conf.5.html)
- [Gentoo Wiki: Xorg/Guide](https://wiki.gentoo.org/wiki/Xorg/Guide)
- [ArchWiki: Xorg](https://wiki.archlinux.org/title/Xorg)