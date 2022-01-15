---
title: "在十年老笔记本上装了 FreeBSD"
date: 2021-11-15T23:15:55+08:00
lastmod: 2022-01-15T11:27:55+08:00
slug: navigating-BSD-world
draft: false
keywords: []
description: ""
tags:   
  - 基础
  - code
  - 实践
  - Unix
categories: [BSD]
author: "Jackie"

# You can also close(false) or open(true) something for this content.
# P.S. comment can only be closed
comment: true
toc: true
autoCollapseToc: false
postMetaInFooter: false
hiddenFromHomePage: false
# You can also define another contentCopyright. e.g. contentCopyright: "This is another copyright."
contentCopyright: false
reward: false
mathjax: false
mathjaxEnableSingleDollar: false
mathjaxEnableAutoNumber: false

# You unlisted posts you might want not want the header or footer to show
hideHeaderAndFooter: false
---

也是一篇 long overdue，拖到跨年了。本来是打算在给老笔记本装系统的时候顺手把一些东西记下来做备忘，最后发现看到的有意思的东西越来越多，反倒是前面的系统安装是最无聊的一部分了。

<!--more-->

## 缘起

之前因为工作用笔记本电脑是用 Debian，所以另一台放在宿舍日常用来影音的低配老旧笔记本也就很方便地装了 Debian。也不是没有考虑过 Arch Linux，但是试用了一下发现要 AUR 的东西真的太多了。首先 AUR 里很多软件更新频繁而编译需要时间不说，本身 AUR 里面的软件质量也很参差不齐。我碰到了问题也没有很懂 Arch 报 bug 是什么流程、AUR 是不是应该单独报。Debian 呢，跟我的工作用电脑保持一致也用了 Debian sid。为了发挥硬件最大价值，而且我也是影音使用多，所以在这台只有 Nvidia 独立显卡的电脑上装了[天杀的闭源驱动](https://www.quora.com/Why-did-Linus-Torvalds-give-a-middle-finger-to-Nvidia-during-a-conference)。问题就在这里，无论是 Debian (sid) 还是 Arch (stable)，只要用上 Nvidia 闭源驱动，电脑在睡眠唤醒之后很大几率出现屏幕无法唤醒，特别是在有外接显示器情况下。我检查了日志也没有发现问题所在，很无奈。无意在网上看到才知道 FreeBSD 也 port 了 Nvidia 的闭源驱动。出于对于 Unix/BSD 的好奇和对以往听说的 BSD 高质量的传说，我打算折腾着装一个 BSD 试试看。在 FreeBSD、NetBSD 和 OpenBSD（当然是按首字母排序没有其他意思）三个之间毫无意外选了 FreeBSD。另外 [GhostBSD](https://www.ghostbsd.org/)、[DragonflyBSD](https://www.dragonflybsd.org/)、 [MidnightBSD](https://www.midnightbsd.org/) 和 [NomadBSD](https://nomadbsd.org/) 等等都是不错的 BSD 系统，但是考虑到用户特别是桌面用户数量，还有和 Wiki 和文档数量和质量，当然对于我这种刚接触 Unix 的人来说还是不要选小众的。

## 安装 FreeBSD 系统

开始当然要在虚拟机里试试系统安装，确实比常见的 Linux 现在都有安装器难一些。但是如果不想要很多自定义设置，全程都接受默认的话很简单就能装好系统。

然而，我肯定不可能全程默认啊那和咸鱼有什么分别！我的笔记本电脑由于太老，只能用 Legacy BIOS 根本不支持 UEFI。其次由于我习惯还是保留一个 Windows 系统备用（没办法，有时候就是要用一下 Office 或者 EndNote）所以一直是单硬盘双系统。最后一点完全出于好奇，我打算用一下被无数人安利的据说很强大的 *ZFS* 并且想要自己调整分区方案和分区大小。最开始我没料到同时满足上面这三点这么难，不然我可能不会尝试或者妥协放弃其中某个想法。

最难的是双系统安装。由于是单硬盘，所以无论是 Windows 还是 FreeBSD 最终都只会占据单块硬盘上的某个分区。在 Windows 系统术语里， *分区*有主分区和扩展分区，主分区最多 4 个，其中最多一个主分区可以作为扩展分区再划分出一个或者多个逻辑分区。在 Linux 语境下上述分区体系基本上没什么冲突。由于主分区最多 4 个，所以逻辑分区一般在 Linux 下从 5 开始编号，比如 `sda5` 表示逻辑分区里的第一个分区。哪怕是只有一个主分区和一个只包含一个逻辑分区的扩展分区同样会被编号为 5。Linux 可以装到逻辑分区也可以装到主分区。在 FreeBSD 里有个术语叫做 *slice*，有点像主分区和拓展分区的概念，一个 *slice* 里面可以划分出多个类似于*逻辑分区*的分区，这些*逻辑分区*可以用来装系统，而 *slice* 本身必须是一个主分区（就像是扩展分区）不能是一个逻辑分区。安装双系统的时候，FreeBSD 所在的 *slice* 必须是 Windows 下看到的主分区或者扩展分区，不可以是逻辑分区。

FreeBSD 使用 MBR 分区模式时，如果一块硬盘 `ada0` 有三个主分区，系统会依次编号为 `ada0s1`，`ada0s2` 和 `ada0s3`。在 UEFI 模式下为  `ada0p1`，`ada0p2` 和 `ada0p3`。这三个分区都是 *slice*。按照我的电脑的情况，前两个分区一个是 Windows 系统分区，一个是用来存东西的，二者都是 NTFS 格式。现在我就是要把 `ada0s3` 用来装 FreeBSD。如果我把 `ada0s3`  这个 *slice* 继续划分三个分区。系统会依次编号 `ada0s3a`，`ada0s3b` 和 `ada0s3d`。Wait, what？？？What happened to `ada0s3c`? Did you eat it? 当然不是....惯例上，FreeBSD编号时认为 *a* 分区用作 FreeBSD 系统分区，*b* 作为 swap 分区，*c* 则代表整个 *slice*，所以第三个分区会从 d 开始编号。[FreeBSD 的文档](https://docs.freebsd.org/doc/5.5-RELEASE/usr/share/doc/handbook/disk-organization.html#BASICS-DISK-SLICE-PART)里还有一张图也反映了这个情况：

![disk-layout](https://docs.freebsd.org/images/books/handbook/basics/disk-layout.png)

虽然说这是“惯例”不是硬性要求，但是还是建议按照这个来。不这样用可能会出一些奇奇怪怪的问题: [I lost bootcode in BSD slice, a lot. Help me found out WHY?](https://forums.freebsd.org/threads/i-lost-bootcode-in-bsd-slice-a-lot-help-me-found-out-why.82277/)。

搞清楚了基本概念，下面安装系统就不难了。步骤我写在 gist 上了：[HowTo: [LegacyBIOS&MBR]Install FreeBSD RootOnZFS in a FreeBSD MBR Slice and Dual Boot Windows](https://gist.github.com/JackieMium/bf8622908bd7e3765b8a7141bb493868)

安装完基础系统重启之后确认网络没有问题，下一步就是安装 Xorg 和 DE 环境了。这一步如果用过 Gentoo 或者 Arch 就很熟悉了，确定合适的显卡驱动，安装驱动和 
`x11/xorg` 之后确认 X 可以跑起来，再安装 DM 和 DE/WM 就好了。我的显卡是 `Nvidia GeForce GT 220M/320M`，查到 FreeBSD 的闭源驱动是 `nvidia-driver-340-xx` 驱动。之后就按照 Handbook 来搭建 DE 环境，我用的依然是 lightDM + Xfce4。全部装完弄好之后大概长这样（系统已经用了一阵子了不是最初的时候的截图）：

![freebsd.png](https://s2.loli.net/2022/01/08/mQXIapDx2NOArYc.png)


## But what are BSDs anyway...

- [The BSD Family Tree | James Howard](https://jameshoward.us/archive/bsd-family-tree/)
- [BSD For Linux Users :: Intro](http://www.over-yonder.net/~fullermd/rants/bsd4linux/01)
- [A very brief history of Unix](https://changelog.com/posts/a-brief-history-of-unix)
- [UNIX Wars – The Battle for Standards | Klara Inc.](https://klarasystems.com/articles/unix-wars-the-battle-for-standards/)
- [What Is OpenBSD? Everything You Need to Know](https://www.makeuseof.com/what-is-openbsd/)
- [What every IT person needs to know about OpenBSD Part 1: How it all started | APNIC Blog](https://blog.apnic.net/2021/10/28/openbsd-part-1-how-it-all-started/)
- [NetBSD Explained: The Unix System That Can Run on Anything](https://www.makeuseof.com/what-is-netbsd/)
- [What Is DragonFly BSD? The Advanced BSD Variant Explained](https://www.makeuseof.com/what-is-dragonfly-bsd/)
- [3 UNIX-Like Operating Systems That Aren't Linux](https://www.makeuseof.com/tag/3-unix-like-operating-systems-arent-linux/)
- [Unix vs. Linux: The Differences Between and Why It Matters](https://www.makeuseof.com/tag/linux-vs-unix-crucial-differences-matter-linux-professionals/)

## 一些用到的 snipets

- [How to mount a zfs partition?](https://forums.freebsd.org/threads/how-to-mount-a-zfs-partition.61112/)
  
  ```
  # run zpool import to get name of zpool (such as zroot)
  zpool import
  # create a mountpoint for zpool:
  mkdir -p /tmp/zroot
  # import zpool:
  zpool import -fR /tmp/zroot zroot
  # create a mountpoint for zfs /:
  mkdir /tmp/root
  # mount /:
  mount -t zfs zroot/ROOT/default /tmp/root
  # the directories will now be available in /tmp/root
  # export zpool:
  zpool export zroot
   ```

- Enable core dumps:

  ```
  mkdir -p /var/coredumps
  chmod 1777 /var/coredumps
  
  # /etc/sysctl.conf
  kern.coredump=1
  kern.corefile=/var/coredumps/%U/%N.core
  kern.sugid_coredump=1
  or:
  sysctl kern.coredump=1
  sysctl kern.corefile=/var/coredumps/%U/%N.core
  sysctl kern.sugid_coredump=1
  ```

- Set screen birghtness from command line:
  
  ```
  # check hw.acpi.video first
  sudo sysctl hw.acpi.video.lcd0.brightness=15  
  ```

- 笔记本合盖睡眠模式：
  ```
  sudo sysctl hw.acpi.lid_switch_state=S3
  ```
  
- Check video driver GLX info:

  ```
  glxinfo | grep vendor
  ```

- Useful stuff in `/etc/rc.conf`:

  ```
  zfs_enable="YES"
  gptboot_enable="NO"
  kld_list="nvidia fusefs acpi_asus acpi_asus_wmi acpi_video"
  hostname="freebsd.asus"
  rc_startmsgs="NO"

  sshd_enable="YES"
  moused_enable="YES"
  syslogd_flags="-ss"

  background_dhclient="YES"
  wlans_ath0="wlan0"
  ifconfig_wlan0="WPA SYNCDHCP"
  dbus_enable="YES"

  dumpdev="AUTO"
  clear_tmp_enable="YES"
  clear_tmp_X="YES"

  sendmail_enable="NO"
  sendmail_submit_enable="NO"
  sendmail_outbound_enable="NO"
  sendmail_msp_queue_enable="NO"

  # for VM
  #vboxguest_enable="YES"
  #vboxservice_enable="YES"
  #ntpd_enable="YES"
  #ntpdate_enable="YES"

  xdm_enable="NO"
  lightdm_enable="YES"
  ```

  And `/boot/loader.conf`:
  
  ```
  zfs_load="YES"
  autoboot_delay="3"
  boot_mute="YES"
  verbose_loading="NO"
  # resolution of boot screen and tty, font size
  vbe_max_resolution="720p"
  screen.font="10x20"
  # Don't wait for USB during boot
  hw.usb.no_boot_wait=1
  ```

## 参考

- [JJBA blog post: FreeBSD Root on ZFS - Partitions](https://averageflow.github.io/2020/11/19/freebsd-root-on-zfs-partitions.html)
- [FreeBSDWiki: Installing FreeBSD Root on ZFS using FreeBSD-ZFS partition in a FreeBSD MBR Slice](https://wiki.freebsd.org/RootOnZFS/ZFSBootPartition)
- [Disk Setup On FreeBSD](http://www.wonkity.com/~wblock/docs/html/disksetup.html)
- [Installing_FreeBSD_Root_on_ZFS_using_FreeBSD-ZFS_partition_in_a_FreeBSD_MBR_Slice.txt](https://hg.sr.ht/~vas/FAQ/browse/FreeBSD/Installing_FreeBSD_Root_on_ZFS_using_FreeBSD-ZFS_partition_in_a_FreeBSD_MBR_Slice.txt?rev=tip)
- [Migrate FreeBSD root on UFS to ZFS](https://imil.net/blog/posts/2016/migrate-freebsd-root-on-ufs-to-zfs/)
- [FreeBSD Handbook](https://docs.freebsd.org/en/books/handbook/)
- [FreeBSD manual: zfsboot](https://www.freebsd.org/cgi/man.cgi?query=zfsboot&sektion=8&manpath=freebsd-release-ports)
- [FreeBSD manual: gpart](https://www.freebsd.org/cgi/man.cgi?query=gpart&sektion=8&apropos=0&manpath=FreeBSD+13.0-RELEASE+and+Ports)
- [**Vermaden: FreeBSD Desktop**](https://vermaden.wordpress.com/freebsd-desktop/)
- [Absolute FreeBSD, 3rd Edition: The Complete Guide to FreeBSD](https://www.amazon.com/Absolute-FreeBSD-3rd-Complete-Guide/dp/1593278926)
- [ZFS Full Disk Encryption with FreeBSD 10 - Part 2](https://www.schmidp.com/2014/01/07/zfs-full-disk-encryption-with-freebsd-10-part-2/)
- [How to setup FreeBSD with a riced desktop - part 1 - Basic setup](https://unixsheikh.com/tutorials/how-to-setup-freebsd-with-a-riced-desktop-part-1-basic-setup.html)
- [Connecting to WPA network in FreeBSD - Unix & Linux Stack Exchange](https://unix.stackexchange.com/questions/260502/connecting-to-wpa-network-in-freebsd)
- [Install FreeBSD from remote SSH session](https://www.tumfatig.net/2012/install-freebsd-from-remote-ssh-session/)
- [FreeBSD 13.0 – Full Desktop Experience – Tubsta](https://www.tubsta.com/2021/03/freebsd-13-0-full-desktop-experience/)

## 其他值得一看的

### \*nix

- [Vermaden: Ghost in the Shell](https://vermaden.wordpress.com/ghost-in-the-shell/)
- [Reasons to consider NOT switching to Linux](https://corn.codeberg.page/notlinux.html)
- [Explaining top(1) on FreeBSD | Klara Inc](https://klarasystems.com/articles/explaining-top1-on-freebsd/)
- [Benchmarks: FreeBSD 13 vs. NetBSD 9.2 vs. OpenBSD 7 vs. DragonFlyBSD 6 vs. Linux](https://www.phoronix.com/scan.php?page=article&item=bsd-linux-eo2021)
- [Adventures in BSD 🐡](https://write.as/adventures-in-bsd/)
- [FreeBSD 与 RISC-V: 开源物联网生态系统的未来](https://feng.si/posts/2019/06/freebsd-and-risc-v-the-future-of-open-source-iot-ecosystem/)
- [What the GNU? - Ariadna Vigo](https://ariadnavigo.xyz/posts/what-the-gnu/)
- [Installing Windows and Linux into the same partition](https://gist.github.com/motorailgun/cc2c573f253d0893f429a165b5f851ee)
- [What desktop Linux needs to succeed in the mainstream](https://drewdevault.com/2021/12/05/What-desktop-Linux-needs.html)
- [How new Linux users can increase their odds of success](https://drewdevault.com/2021/12/05/How-new-Linux-users-succeed.html)
- [How To Set Default Fonts and Font Aliases on Linux](https://jichu4n.com/posts/how-to-set-default-fonts-and-font-aliases-on-linux/)
- [记一次Linux木马清除过程 - FreeBuf网络安全行业门户](https://www.freebuf.com/articles/system/208804.html)
- [Attempting to use GNU Guix, again](https://ruzkuku.com/texts/guix-again.html)
- [5 tips to improve productivity with zsh](https://opensource.com/article/18/9/tips-productivity-zsh)
- [Configuring Zsh Without Dependencies](https://thevaluable.dev/zsh-install-configure-mouseless/)
- [A Guide to the Zsh Completion With Examples](https://thevaluable.dev/zsh-completion-guide-examples/)
- [Some zshrc tricks](https://www.arp242.net/zshrc.html)
- [**StackOverflow: Your problem with  Vim  is that you don't grok  vi**](https://stackoverflow.com/a/1220118/5973949)
- [MODIFYING SYSTEMD UNIT FILES](https://blog.thewatertower.org/2019/04/24/modifying-systemd-unit-files/)

### Misc

- [The Web Is Fucked](https://thewebisfucked.com/)
- [FreeBSD progress on Slimbook Base14](https://euroquis.nl/freebsd/2020/04/16/slimbook.html)
- [Man Loses Will to Live During Gentoo Install](https://www.sudosatirical.com/articles/man-loses-will-to-live-during-gentoo-install/)
- [Local man switches to Arch, tells no one](https://lunduke.substack.com/p/local-man-switches-to-arch-tells)
- [New Linux User Declares Self Safe From Coronavirus](https://www.sudosatirical.com/articles/new-linux-user-declares-self-safe-from-coronavirus/)


## One moRe thing

FreeBSD 二进制 pkg 源里有 `math/R` 可以直接安装，但是默认编译没有链接 OpenBLAS。`ports` 里倒是可以自己自定义编译，但是我还没有搞懂 `ports` 怎么和 pkg 优雅且安全地一起使用。所以还是走老路自己编译吧。

FreeBSD 的 pkg 源是有 R 的，但是当我装好了之后发现(20211220 最新版 R 版本号是 4.1.2)：

```R
> sessionInfo()
R version 4.1.2 (2021-11-01)
Platform: amd64-portbld-freebsd13.0 (64-bit)
Running under: FreeBSD freebsd.asus 13.0-RELEASE-p4 FreeBSD 13.0-RELEASE-p4 #0: Tue Aug 24 07:33:27 UTC 2021     root@amd64-builder.daemonology.net:/usr/obj/usr/src/amd64.amd64/sys/GENERIC  amd64

Matrix products: default
LAPACK: /usr/local/lib/R/lib/libRlapack.so.4.1.2

locale:
[1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

loaded via a namespace (and not attached):
[1] compiler_4.1.2
```

是的，虽然我装了 OpenBLAS 但是 R 也不会调用。

准备过程就没什么好说的了，下载源码包解压，依赖该装的装。

先直接 `configure` 来碰碰运气:

```
configure: error: No Fortran compiler found
```

结果当然是毫不意外地报错了。第一反应当然是 Google 一下。在 FreeBSD 论坛看到这个 [lgfortran not found](https://forums.FreeBSD.org/threads/lgfortran-not-found.1784/) 说其实就是系统装的 Fortran 编译器的可执行文件是带版本号的，比如我的系统是 `/usr/local/bin/gfortran10`，但是根据 R 的文档 [R Installation and Administration: Using Fortran](https://cran.r-project.org/doc/manuals/r-release/R-admin.html#Using-Fortran) 可以看到编译过程中默认只会在 `PATH` 里找 `gfortran`，所以也就会报错了。知道问题所在那么就是用 Linux 很常见的办法了——建立软链接。但是这个方法显然没那么优雅，而文档里其实也提了，自己可以用 `FC=FORTRAN` 在编译时指定。根据我的情况那就是在 `configure` 的时候加上 `FC=gfortran10` 就好了。到这里我忽然灵机一动，以前看系统二进制编译参数的方法怎么忘了啊，那个里面就是这样指定的！好吧，不犟了，还是看看 `pkg` 二进制包怎么编译的吧。

FreeBSD 二进制包管理器 pkg 直接安装 `math/R` 之后查看 `/usr/local/lib/R/etc/Makeconf`:

```
configure  \
  '--disable-java' '--enable-R-shlib' \
  '--with-readline' 'rdocdir=/usr/local/share/doc/R' \
  '--with-cairo' '--with-ICU' \
  '--with-jpeglib' '--enable-long-double' \
  '--disable-memory-profiling' '--enable-openmp' \
  '--with-libpng' \
  '--enable-BLAS-shlib' '--without-blas' '--without-lapack' \
  '--enable-R-profiling' \
  '--with-tcltk' '--with-libtiff' \
  '--with-x' '--x-libraries=/usr/local/lib' \
  '--x-includes=/usr/local/include' \
  '--prefix=/usr/local' \
  '--localstatedir=/var' \
  '--mandir=/usr/local/man' \
  '--infodir=/usr/local/share/info/' \
  '--build=amd64-portbld-freebsd13.0' \
  'build_alias=amd64-portbld-freebsd13.0' \
  'MAKE=gmake' 'PKG_CONFIG=pkgconf' \
  'CC=cc' \
  'CFLAGS=-O2 -pipe  -DLIBICONV_PLUG -fstack-protector-strong -isystem /usr/local/include -fno-strict-aliasing ' \
  'LDFLAGS= -L/usr/local/lib -Wl,-rpath=/usr/local/lib/gcc10  -L/usr/local/lib/gcc10 -B/usr/local/bin -fstack-protector-strong '\
  'LIBS=-L/usr/local/lib' \
  'CPPFLAGS=-DLIBICONV_PLUG -I/usr/local/include -isystem /usr/local/include' \
  'CPP=cpp' \
  'FC=gfortran10' \
  'FCFLAGS=-Wl,-rpath=/usr/local/lib/gcc10' \
  'CXX=c++' \
  'CXXFLAGS=-O2 -pipe -DLIBICONV_PLUG -fstack-protector-strong -isystem /usr/local/include -fno-strict-aliasing  -DLIBICONV_PLUG -isystem /usr/local/include '
```

果然是 `FC=gfortran10` 指定 Fortran 编译器。还可以看到禁用了 BLAS 和 Java。

既然要作弊，干脆一不做二不休也参考一下 Debian 那边怎么编译的：

```
configure \
 '--prefix=/usr' \
 '--with-cairo' '--with-jpeglib' \
 '--with-readline' '--with-tcltk' \
 '--with-system-bzlib' '--with-system-pcre' \
 '--with-system-zlib' \
 '--mandir=/usr/share/man' \
 '--infodir=/usr/share/info' \
 '--datadir=/usr/share/R/share' \
 '--includedir=/usr/share/R/include' \
 '--with-blas' '--with-lapack' \
 '--enable-long-double' '--enable-R-profiling' \
 '--enable-R-shlib' '--enable-memory-profiling' \
 '--without-recommended-packages' \
 '--build' 'x86_64-linux-gnu' \
 'build_alias=x86_64-linux-gnu' \
 'R_PRINTCMD=/usr/bin/lpr' \
 'R_PAPERSIZE=letter' \
 'TAR=/bin/tar' \
 'R_BROWSER=xdg-open' \
 'LIBnn=lib' \
 'JAVA_HOME=/usr/lib/jvm/default-java' \
 'R_SHELL=/bin/bash' \
 'CC=gcc -std=gnu99' \
 'CFLAGS=-g -O2 -ffile-prefix-map=/build/r-base-PT7Nxy/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g' \
 'LDFLAGS=-Wl,-z,relro' \
 'CPPFLAGS=' \
 'FC=gfortran' \
 'FCFLAGS=-g -O2 -ffile-prefix-map=/build/r-base-PT7Nxy/r-base-4.1.2=. -fstack-protector-strong' \
 'CXX=g++' \
 'CXXFLAGS=-g -O2 -ffile-prefix-map=/build/r-base-PT7Nxy/r-base-4.1.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g'
```

那我就来个东拼西凑，把我的编译参数改成:

```
../configure '--prefix=/home/adam/Programs/R/4.1.2' \
  'FC=gfortran10' \
  'FCFLAGS=-g -O2 -fstack-protector-strong' \
  'CC=cc' 'CFLAGS=-O2 -pipe -fstack-protector-strong' \
  'CPP=cpp' 'CXX=c++' 'CXXFLAGS=-O2 -pipe -fstack-protector-strong' \
  --enable-R-shlib --with-blas --with-lapack \
  '--enable-long-double' '--enable-R-profiling' \
  '--enable-memory-profiling' '--without-recommended-packages' \
  '--build=amd64-portbld-freebsd13.0' \
  'build_alias=amd64-portbld-freebsd13.0' \
  'JAVA_HOME=/usr/local/openjdk8' \
  --with-tcltk \
  --with-tcl-config=/usr/local/lib/tcl8.6/tclConfig.sh \
  --with-tk-config=/usr/local/lib/tk8.6/tkConfig.sh
```

然后出乎意料一切 OK:

```
R is now configured for x86_64-portbld-freebsd13.0

  Source directory:            ..
  Installation directory:      /home/adam/Programs/R/4.1.2

  C compiler:                  cc  -O2 -pipe -fstack-protector-strong
  Fortran fixed-form compiler: gfortran10 -fno-optimize-sibling-calls -g -O2 -fstack-protector-strong

  Default C++ compiler:        c++ -std=gnu++14  -O2 -pipe -fstack-protector-strong
  C++11 compiler:              c++ -std=gnu++11  -O2 -pipe -fstack-protector-strong
  C++14 compiler:              c++ -std=gnu++14  -O2 -pipe -fstack-protector-strong
  C++17 compiler:              c++ -std=gnu++17  -O2 -pipe -fstack-protector-strong
  C++20 compiler:              c++ -std=gnu++20  -O2 -pipe -fstack-protector-strong
  Fortran free-form compiler:  gfortran10 -fno-optimize-sibling-calls -g -O2 -fstack-protector-strong
  Obj-C compiler:              cc -g -O2 -fobjc-exceptions

  Interfaces supported:        X11, tcltk
  External libraries:          pcre2, readline, BLAS(OpenBLAS), LAPACK(in blas), curl
  Additional capabilities:     PNG, JPEG, TIFF, NLS, cairo, ICU
  Options enabled:             shared R library, R profiling, memory profiling

  Capabilities skipped:        
  Options not enabled:         shared BLAS

  Recommended packages:        no

configure: WARNING: you cannot build info or HTML versions of the R manuals
configure: WARNING: you cannot build PDF versions of the R manuals
configure: WARNING: you cannot build PDF versions of vignettes and help pages
```

最后我手痒优化一下编译参数，最终改成：

```
../configure \
  '--prefix=/home/adam/Programs/R/4.1.2' \
  'FC=gfortran10' \
  'FCFLAGS=-march=native -mtune=native -g -O2 -fstack-protector-strong' \
  'CC=cc' \
  'CFLAGS=-march=native -mtune=native -O2 -pipe -DLIBICONV_PLUG -fstack-protector-strong' \
  'CPP=cpp' 'CXX=c++' \
  'CXXFLAGS=-march=native -mtune=native -O2 -pipe -DLIBICONV_PLUG -fstack-protector-strong' \
  --enable-R-shlib --with-blas --with-lapack \
  '--enable-long-double' '--enable-R-profiling' \
  '--enable-memory-profiling' '--with-recommended-packages' \
  '--build=amd64-portbld-freebsd13.0' \
  'build_alias=amd64-portbld-freebsd13.0' \
  'JAVA_HOME=/usr/local/openjdk8' \
  --with-tcltk \
  --with-tcl-config=/usr/local/lib/tcl8.6/tclConfig.sh \
  --with-tk-config=/usr/local/lib/tk8.6/tkConfig.sh
```

得到：

```
R is now configured for x86_64-portbld-freebsd13.0

  Source directory:            ..
  Installation directory:      /home/adam/Programs/R/4.1.2

  C compiler:                  cc  -march=native -mtune=native -O2 -pipe -DLIBICONV_PLUG -fstack-protector-strong
  Fortran fixed-form compiler: gfortran10 -fno-optimize-sibling-calls -march=native -mtune=native -g -O2 -fstack-protector-strong

  Default C++ compiler:        c++ -std=gnu++14  -march=native -mtune=native -O2 -pipe -DLIBICONV_PLUG -fstack-protector-strong
  C++11 compiler:              c++ -std=gnu++11  -march=native -mtune=native -O2 -pipe -DLIBICONV_PLUG -fstack-protector-strong
  C++14 compiler:              c++ -std=gnu++14  -march=native -mtune=native -O2 -pipe -DLIBICONV_PLUG -fstack-protector-strong
  C++17 compiler:              c++ -std=gnu++17  -march=native -mtune=native -O2 -pipe -DLIBICONV_PLUG -fstack-protector-strong
  C++20 compiler:              c++ -std=gnu++20  -march=native -mtune=native -O2 -pipe -DLIBICONV_PLUG -fstack-protector-strong
  Fortran free-form compiler:  gfortran10 -fno-optimize-sibling-calls -march=native -mtune=native -g -O2 -fstack-protector-strong
  Obj-C compiler:              cc -g -O2 -fobjc-exceptions

  Interfaces supported:        X11, tcltk
  External libraries:          pcre2, readline, BLAS(OpenBLAS), LAPACK(in blas), curl
  Additional capabilities:     PNG, JPEG, TIFF, NLS, cairo, ICU
  Options enabled:             shared R library, R profiling, memory profiling

  Capabilities skipped:        
  Options not enabled:         shared BLAS

  Recommended packages:        yes

configure: WARNING: you cannot build info or HTML versions of the R manuals
configure: WARNING: you cannot build PDF versions of the R manuals
configure: WARNING: you cannot build PDF versions of vignettes and help pages
```

编译完成后

```
> sessionInfo()
R version 4.1.2 Patched (2021-12-16 r81389)
Platform: x86_64-portbld-freebsd13.0 (64-bit)
Running under: FreeBSD freebsd.asus 13.0-RELEASE-p4 FreeBSD 13.0-RELEASE-p4 #0: Tue Aug 24 07:33:27 UTC 2021     root@amd64-builder.daemonology.net:/usr/obj/usr/src/amd64.amd64/sys/GENERIC  amd64

Matrix products: default
LAPACK: /usr/local/lib/libopenblasp-r0.3.18.so

locale:
[1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

loaded via a namespace (and not attached):
[1] compiler_4.1.2
> capabilities()
       jpeg         png        tiff       tcltk         X11        aqua 
       TRUE        TRUE        TRUE        TRUE        TRUE       FALSE 
   http/ftp     sockets      libxml        fifo      cledit       iconv 
       TRUE        TRUE        TRUE        TRUE        TRUE        TRUE 
        NLS       Rprof     profmem       cairo         ICU long.double 
       TRUE        TRUE        TRUE        TRUE        TRUE        TRUE 
    libcurl 
       TRUE
```

这里强烈建议仔细阅读 R 的安装文档 [R Installation and Administration](https://cran.r-project.org/doc/manuals/r-release/R-admin.html) 。前面也提到过，里面还有关于测试之类的细节，大部分的问题和注意点在这份文档里都能得到满意的解答。