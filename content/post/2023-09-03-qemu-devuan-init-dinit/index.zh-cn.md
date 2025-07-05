---
title: 使用 qemu 安装配置虚拟机 Devuan 系统切换 init 为 Dinit
author: Jackie
date: '2023-09-03'
slug: []
categories:
  - Linux
tags:
  - Linux
  - Unix
lastmod: '2025-07-04T20:40:27-05:00'
draft: no
keywords: []
description: ''
comment: yes
toc: yes
autoCollapseToc: no
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

以前都是使用 VirtualBox 安装和管理虚拟机，知道有 `qemu` 但是一直没有试用。这次正好发现一个新的 `init` 叫 [dinit](https://github.com/davmac314/dinit)，开发者的[系列博客](https://davmac.org/blog/)很值得一看。以前我也知道还有 [runit](http://smarden.org/runit/) 并且在 [Devuan GNU/Linux](https://www.devuan.org/) 试验过。由于 Devuan 本身就是非 [systemd](https://systemd.io/) 系统，所以其实在 Devuan 上切换到另一个 `init` 并不需要卸载 `systemd` 这种危险操作。

<!--more-->

所以很自然，我想用 `qemu` 安装一个 Devuan 虚拟机，并且尝试安装 `dinit` 作为系统 init。下载的时候我发现最新 Devuan 5.0 stable 系统代号 *Daedalus* 已经提供 `Runit` 作为安装系统的时候 init 选择之一，其他两个选择是 [SysVinit](https://github.com/slicer69/sysvinit) 和 [OpenRC](https://github.com/OpenRC/openrc)。这样 `Dinit` 算是第四个了！

## 配置 UEFI 模式 qemu 虚拟机并安装 Devuan

首先安装需要的包：

```
doas apt install qemu-system-x86 ovmf qemu-utils qemu-system-gui
```

新建一个 20G 的 `qcow2` 格式硬盘镜像用来装系统：

```
qemu-img create -f qcow2 Devuan.qcow2 20G
```

Devuan 启动一个新虚拟机开始装系统：

```
qemu-system-x86_64 -enable-kvm \
  -bios /usr/share/ovmf/OVMF.fd \
  -cpu host -smp 2 -m 2G \
  -boot order=dc,menu=on,splash-time=0 \
  -drive file=devuan_daedalus_5.0.0_amd64_netinstall.iso,format=raw,if=virtio \
  -drive file=Devuan.qcow2,media=disk,if=virtio
```

这里指定虚拟机双核、2G 内存并使用 `OVMF.fd` 作为 UEFI 启动固件，启动顺序 `dc` 表示按顺序尝试从光驱和硬盘启动。

[OVMF](https://github.com/tianocore/tianocore.github.io/wiki/OVMF) 是 **O**pen **V**irtual **M**achine **F**irmware 的缩写，从名称就能看出来项目就是为了给虚拟机提供 UEFI 支持的。关于这些固件的介绍和用法还可以看 [OVMF Wiki](https://github.com/tianocore/tianocore.github.io/wiki/OVMF)。

安装完系统之后，这时候就可以去掉光驱直接用刚刚安装了系统的虚拟硬盘来启动虚拟机了：

```
qemu-system-x86_64 -enable-kvm \
  -bios /usr/share/ovmf/OVMF.fd \
  -cpu host -smp 2 -m 2G \
  -boot order=c,menu=on,splash-time=0 \
  -drive file=Devuan.qcow2,media=disk,if=virtio
```

但是这里会出现两个问题，第一虚拟机启动之后会有一个很长时间的尝试网络启动的时间（当然会启动失败），第二在网络启动失败之后会进入 UEFI Shell 因为系统找不到引导。这时候使用：

```
FS0:\EFI\debian\grubx64.efi
```

就可以启动 `grub2` 顺利引导系统了。但是这个启动失败过程会在每次启动的时候出现，所以必须要解决。

## 修改虚拟机 UEFI 固件

幸好 Google 一下就知道该怎么办了。

这个办法来自 [StackExchange: QEMU doesn't respect the boot order when booting with UEFI (OVMF)](https://unix.stackexchange.com/a/554084)：

```
cp /usr/share/OVMF/OVMF_VARS.fd MyUEFI.fd

qemu-system-x86_64 -enable-kvm \
  -cpu host -smp 2 -m 2G \
  -drive file=/Devuan.qcow2,media=disk,if=virtio \
  -drive file=/usr/share/OVMF/OVMF_CODE.fd,if=pflash,format=raw,readonly=on \
  -drive file=MyUEFI.fd,if=pflash,format=raw \
  -display sdl -vga std -no-reboot &|
```

这里首先复制了一个空固件模板 `OVMF_VARS.fd` 用于后续制作自己的 UEFI 固件，同时使用 `OVMF_CODE.fd` 来启动虚拟机，由于用来启动的 `OVMF_CODE.fd` 只需要用一下来启动虚拟机所以还设置了只读。使用 `OVMF_CODE.fd` 启动和上面 `OVMF.fd` 一样都会启动失败进入 UEFI Shell，然后：

```
bcfg boot add 0 FS0:\EFI\debian\grubx64.efi "devuan"
```

就可以了，现在得到的 `MyUEFI.fd` 以后用于启动虚拟就可以直接启动到 `grub2` 引导了。所以现在启动虚拟机命令变成：

```
qemu-system-x86_64 --enable-kvm \
  -cpu host -smp 2 -m 2G \                                                                
  -drive file=Devuan.qcow2,media=disk,if=virtio \
  -drive "if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd" \
  -drive "if=pflash,format=raw,file=MyUEFI.fd" \
  -display sdl -vga std -no-reboot &|
```

现在虚拟机每次都会直接使用制作好的 `MyUEFI.fd` 启动直接进入 `grub2` 了。注意，这里还继续使用了 `OVMF_CODE.fd`，因为我发现如果去掉这个启动固件的话虚拟机图形界面无法初始化因此也无法启动。

在安装器里我选择了 `Runit` 作为系统 `init`、没有选择安装任何桌面环境，现在进入系统的话可以得到一个全新安装的 Devuan 系统，网络也是可用的。为了方便我还添加了虚拟机 22 到主机 5679 的端口映射，这样可以在主机 ssh 连接虚拟机，所以现在启动虚拟机的命令变成：

```
qemu-system-x86_64 --enable-kvm \
  -cpu host -smp 2 -m 2G \
  -drive file=Devuan.qcow2,media=disk,if=virtio \
  -drive "if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd" \
  -drive "if=pflash,format=raw,file=MyUEFI.fd" \
  -net nic,model=virtio \
  -net user,id=hostnet0,hostfwd=tcp::5679-:22 \
  -display sdl -vga std -no-reboot &|
```

启动后通过

```
ssh-copy-id -p 5679 -i ~/.ssh/id_rsa.pub  USER@localhost
```

复制公钥之后，以后 `ssh -p 5679 USER@localhost` 就可以直接登录虚拟机了。

在下一步之前，我选择首先为虚拟硬盘创建一个快照：

```
qemu-img snapshot -c 'Devuan_NewSystem_NoX' Devuan.qcow2
```

现在，通过

```
qemu-img info Devuan.qcow2
qemu-img snapshot -l Devuan.qcow2 
```

都可以看到虚拟硬盘里存在一个名为 `Devuan_NewSystem_NoX` 的快照。

## 切换系统 init 为 dinit

`Dinit` 是开发者 Davin McCall 几年前开始开发的一个项目，现在已经比较成熟了，文档也比较齐全。目前 [Artix Linux](https://artixlinux.org/) 和 [Chimera Linux](https://chimera-linux.org/about/) 这两个 Linux 发行版已经把 `Dinit` 作为系统默认的 `init`。

在 Devuan 上要将现在使用的 `Runit` 切换到 `Dinit`，不需要卸载 `Runit`，所以理论上是随时可以切换回来的。况且上面我也已经把初始系统留了快照，所以理论上虚拟机已经备份好了。

因为 `dinit` 没有提供二进制包需要自己从源码编译，所以首先来安装一些需要的包（这里用 root 用户从 tty 登录）：

```
apt install doas build-essential git wget vim
```

为了方便安装完后直接用在 `/etc/doas.conf` 里设置：

```
permit nopass :USER
```

这样所有我的用户组的用户都不需要输入密码了，当然只有在虚拟机里才会这么放肆。

从 GitHub 下载 `Dinit` 源码后按照文档，我设置了 prefix 为 `/usr/local` ，这样 `dinit` 、`dinitctl` 这些命令都会安装到 `/usr/local/sbin`。完成 [Getting Started with Dinit](https://github.com/davmac314/dinit/blob/master/doc/getting_started.md) 的测试。接下来就是按照 [Dinit as init: using Dinit as your Linux system's init](https://github.com/davmac314/dinit/blob/master/doc/linux/DINIT-AS-INIT.md) 把 `Dinit` 设置为系统 `init`。

如果直接这时候在启动的时候在 `grub2` 界面按下 `e` 编辑启动项，在 `linux` 内核配置这一行末尾加上 `init=/usr/local/sbin/dinit` 的话系统会启动失败，报错 `early-filesystems.sh` 这个脚本执行失败。尝试加上 `single` 参数启动到单用户模式同样报错。但是在这个报错页面依然可以用 root 密码进入恢复模式（Recovery mode）。这时候可以查看这个脚本所有内容：

```
#!/bin/sh

set -e

if [ "$1" = start ]; then

    PATH=/usr/bin:/usr/sbin:/bin:/sbin

    # Must have sysfs mounted for udevtrigger to function.
    mount -n -t sysfs sysfs /sys
    
    # Ideally devtmpfs will be mounted by kernel, we can mount here anyway:
    mount -n -t devtmpfs tmpfs /dev
    mkdir -p /dev/pts /dev/shm
    mount -n -t tmpfs -o nodev,nosuid tmpfs /dev/shm
    mount -n -t devpts -o gid=5 devpts /dev/pts

    # /run, and various directories within it
    mount -n -t tmpfs -o mode=775 tmpfs /run
    mkdir /run/lock /run/udev /run/sshd
    
    # "hidepid=1" doesn't appear to take effect on first mount of /proc,
    # so we mount it and then remount:
    mount -n -t proc -o hidepid=1 proc /proc
    mount -n -t proc -o remount,hidepid=1 proc /proc

fi
```

这个脚本内容就是在创建一些必要的目录和挂载一些需要的文件系统。在恢复模式 `mount` 命令查看输出发现 `/sys`、`/dev`、`/dev/pts`、`/run` 和 `/proc` 这些目录都已经按照脚本内容挂载了，唯一就是  `/dev/pts` 目录不存在当然也就没有正确挂载。在恢复模式创建这个目录并挂载又发现没有出错。尝试运行这个脚本所有命令都发现可以执行不会报错，但是只要直接启动就会在这个脚本报错。我去掉 `set -e` 这一行竟然发现能正常通过 `early-filesystems.sh` 这个脚本了，最后在 Mastodon 上开发者 Davin McCall 指出系统启动时 `intiramfs` 挂载了这些文件系统，所以再到 `early-filesystems.sh` 这个脚本又一次执行的时候目录已经存在、需要挂载的文件系统已经挂载好了所以就会出错，脚本退出，启动中断。知道原因后，就能解释为什么注释掉 `set -e` 这个脚本不在报错而且可以正常启动。

到了这一步，剩下就是根据内容和系统命令路径对每个脚本改动进行改动，让系统可以顺利启动、需要的服务可以开启。

比如 `sysklogd` 服务的原文件是：

```
# This example service for a syslog daemon is based on the use of Troglobit's sysklogd:
#   https://github.com/troglobit/sysklogd
# Unfortunately it does not support readiness notification, so we use a "bgprocess" service.

type = bgprocess
smooth-recovery = true
command = /usr/sbin/syslogd
pid-file = /var/run/syslogd.pid
options = starts-log

depends-on = rcboot
```

但是实际上要参考 [Gentoo Wiki: Sysklogd](https://wiki.gentoo.org/wiki/Sysklogd)  改为：

```
type = bgprocess
smooth-recovery = true
command = /usr/local/sbin/syslogd -m 0 -s -s -f /etc/syslog.conf -C /var/run/syslogd.cache -P /var/run/syslogd.pid
pid-file = /var/run/syslogd.pid
options = starts-log

depends-on = rcboot
```

并且增加配置 `/etc/syslog.conf`：

```
auth,authpriv.*                  /var/log/auth.log
*.*;auth,authpriv.none          -/var/log/syslog

kern.*                          -/var/log/kern.log
mail.*                          -/var/log/mail.log

mail.err                         /var/log/mail.err

*.=info;*.=notice;*.=warn;\
        auth,authpriv.none;\
        cron,daemon.none;\
        mail,news.none          -/var/log/messages

*.=emerg                        *

include /etc/syslog.d/*.conf
```

服务才可以正常启动。

而 `netdev-enp3s0` 服务因为虚拟机的网卡实际上是 `eth0` 那内容就需要重命名为 `netdev-eth0`并且相应 `/etc/udev/rules.d/81-netdev.rules` 也要改为：

```
ACTION=="add" SUBSYSTEM=="net" NAME=="eth0" RUN{program}="/usr/local/sbin/dinitctl trigger netdev-eth0"
```

尽管如此我的网卡每次开机后设备不会启用，所以我自己增加了服务：

```
type = process
command = /sbin/ifup eth0

depends-on = rcboot
depends-on = loginready
waits-for = sshd
```

更改所有服务确保可以启动后，`/etc/default/grub` 里就可以设置：

```
GRUB_CMDLINE_LINUX_DEFAULT="quiet init=/usr/local/sbin/dinit"
```

了。还可以把 `/sbin/init` 改为指向 `/usr/local/sbin/dinit` 的软链接，因为之前它指向 `/lib/runit/runit-init` 。这样基本上就可以不用干预虚拟机直接启动到 `dinit` 作为 `init` 的系统了。

## 回到 Runit

也许不会用 `Dinit`，也许厌了，随时想切换回 Runit 也很简单：把 `/sbin/init` 改为 `/lib/runit/runit-init` ，在`/etc/default/grub` 里去掉 

```
GRUB_CMDLINE_LINUX_DEFAULT="quiet init=/usr/local/sbin/dinit"
```

指定 `init`，重启。
