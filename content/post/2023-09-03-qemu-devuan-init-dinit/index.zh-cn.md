---
title: 使用 qemu 安装配置虚拟机 Devuan 系统切换 init 为 dinit
author: Jackie
date: '2023-09-03'
slug: "qemu-devuan-dinit-as-init"
categories:
  - Linux
tags:
  - Linux
  - Unix
  - init
  - Debian
  - VM
  - qemu
lastmod: '2025-07-04T20:40:27-05:00'
draft: no
keywords: []
description: ''
comment: yes
toc: yes
autoCollapseToc: no
postMetaInFooter: yes
hiddenFromHomePage: no
contentCopyright: yes
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

以前都是使用 VirtualBox 安装和管理虚拟机，知道有 `qemu` 但是一直没有试用。这次正好发现一个新的 `init` 叫 [dinit](https://github.com/davmac314/dinit)，开发者的[系列博客](https://davmac.org/blog/)非常值得一看。以前我也知道还有 [runit](http://smarden.org/runit/) 并且在 [Devuan GNU/Linux](https://www.devuan.org/) 试验过。由于 Devuan 本身就是非 [systemd](https://systemd.io/) 系统，所以切换到另一个 `init` 并不需要卸载 `systemd` 这种*危险*操作。

<!--more-->

很自然，我想试试用 `qemu` 安装一个 Devuan 虚拟机，并且尝试安装 `dinit` 作为系统 init。下载的时候我发现最新 Devuan 5.0 stable 系统代号 *Daedalus* 已经提供 `runit` 作为安装系统的时候 init 选择之一，另外提供的两个选择分别是 [SysVinit](https://github.com/slicer69/sysvinit) 和 [OpenRC](https://github.com/OpenRC/openrc)。这样 `dinit` 算是第四个了！然而 `dinit` 目前作为系统 `init` 还没有获得 Devuan 官方支持，也没有提供打包，只有自己下载源码编译安装才可以实现。

## 配置 UEFI 模式 qemu 虚拟机并安装 Devuan Daedalus

安装需要的 `qemu` 相关的包：

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
  -cpu host -smp 2 -m 2g \
  -bios /usr/share/ovmf/OVMF.fd \
  -boot d \
  -drive file=devuan_daedalus_5.0.0_amd64_netinstall.iso,format=raw,if=virtio \
  -drive file=Devuan.qcow2,media=disk,if=virtio
```

这里指定启用 kvm 虚拟化，分配给虚拟机的硬件资源主机支持 CPU 所有特性的双核 CPU 和 2G 内存。 `OVMF.fd` 作为启动固件。启动顺序 `d` 表示光驱启动，因为要使用镜像文件来安装系统。

[OVMF](https://github.com/tianocore/tianocore.github.io/wiki/OVMF) 是 **O**pen **V**irtual **M**achine **F**irmware 的缩写，从名称就能看出来项目就是为了给虚拟机提供固件支持的。关于这些固件的介绍和用法还可以看 [OVMF Wiki](https://github.com/tianocore/tianocore.github.io/wiki/OVMF) 或者说明文档 `ovmf/README.Debian`。

安装完系统之后，这时候就可以去掉光驱直接用刚刚安装了系统的虚拟硬盘来启动虚拟机了：

```
qemu-system-x86_64 -enable-kvm \
  -bios /usr/share/ovmf/OVMF.fd \
  -cpu host -smp 2 -m 2G \
  -boot order=c,menu=on,splash-time=0 \
  -drive file=Devuan.qcow2,media=disk,if=virtio
```

但是这里会出现两个问题：第一虚拟机启动之后会有一个很长时间的尝试网络启动的时间，当然最终每次都会启动失败因为完全没有配置网络启动；第二在网络启动失败之后会进入 UEFI Builtin Shell，因为 UEFI 找不到引导。这时候在 UEFI Shell 里手动加载 grub2：

```
FS0:\EFI\debian\grubx64.efi
```

就可以启动新安装的系统了。系统启动后要检查是否是 UEFI 启动，可以检查 `mount |grep efivarfs` 是否有输出：

```
$ mount |grep efivarfs
efivarfs on /sys/firmware/efi/efivars type efivarfs (rw,nosuid,nodev,noexec,relatime)
```

或者查看 `dmesg |grep 0i efi`，在运行 systemd 的系统上还可以 `journalctl -b -g 'efi'`。

现在可以通过 UEFI Shell 手动指定启动 `grub2` 顺利引导系统了。但是这个启动失败过程会在每次启动的时候出现，下面来解决这个问题。

## 保存虚拟机 UEFI 固件设置

上面提到 `ovmf/README.Debian` 这个文档，它介绍所有文件名里带 *VAR* 的都是模板文件，供读写使用，这个意思就是用这个固件的话就可以改动并且保存 BIOS 设置到这个固件。注意 `ovmf` 这个包会安装不同的文件在 `/usr/share/ovmf` 和 `/usr/share/OVMF` 两个目录。文档对于所有固件文件都有详细说明，具体使用方法互联网上就有很多教程了，简单搜索一下就行。简单地说就是仍然以 `ovmf/OVMF.fd` 作为只读 UEFI 引导固件，同时复制一份 `OVMF/OVMF_VARS.fd` 作为模板读写数据，这样可以把对 BIOS设置的 UEFI 写入这个可读写固件。

参考自 [StackExchange: QEMU doesn't respect the boot order when booting with UEFI (OVMF)](https://unix.stackexchange.com/a/554084)：

```
cp /usr/share/OVMF/OVMF_VARS.fd Devuan.fd

qemu-system-x86_64 -enable-kvm \
  -cpu host -smp 2 -m 2G \
  -drive file=/Devuan.qcow2,media=disk,if=virtio \
  -drive file=/usr/share/OVMF/OVMF_CODE.fd,if=pflash,format=raw,readonly=on \
  -drive file=Devuan.fd,if=pflash,format=raw
```

这里首先复制了一个空固件模板 `OVMF_VARS.fd` ，同时使用 `OVMF_CODE.fd` 来启动虚拟机， `OVMF_CODE.fd` 设置了只读。

现在进入 UEFI Shell 后执行：

```
bcfg boot add 0 FS0:\EFI\debian\grubx64.efi "devuan"
```

就可以把新的 UEFI 引导项写入并保存在 `Devuan.fd` 这个固件里，以后启动虚拟就可以直接启动到 `grub2` 引导了。所以现在启动虚拟机命令变成：

```
qemu-system-x86_64 --enable-kvm \
  -cpu host -smp 2 -m 2G \            
  -drive file=Devuan.qcow2,media=disk,if=virtio \
  -drive "if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd" \
  -drive "if=pflash,format=raw,file=MyUEFI.fd"
```

现在虚拟机每次都会使用 `Devuan.fd` 启动直接进入 `grub2` 。注意，这里还继续使用了 `OVMF_CODE.fd`，因为它负责初始化 BIOS引导。

## 宿主机端口转发

在安装器里我选择了 `runit` 作为系统 `init`、没有选择安装任何桌面环境，现在进入系统的话可以得到一个全新安装的 Devuan 系统，网络是可用的。为了方便这里再添加虚拟机 22 到主机 5679 的[端口映射](https://wiki.qemu.org/Documentation/Networking)，这样可以在主机 ssh 连接虚拟机，所以现在启动虚拟机的命令变成：

```
qemu-system-x86_64 --enable-kvm \
  -cpu host -smp 2 -m 2G \
  -drive file=Devuan.qcow2,media=disk,if=virtio \
  -drive "if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd" \
  -drive "if=pflash,format=raw,file=MyUEFI.fd" \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::5679-:22
```

启动后通过再复制一下公钥：

```
ssh-copy-id -p 5679 -i ~/.ssh/id_rsa.pub  USER@localhost
```

复制公钥之后，以后 `ssh -p 5679 USER@localhost` 就可以直接从主机通过 ssh 登录虚拟机了。

## 快照

在下一步之前，可以为虚拟硬盘[创建一个快照](https://wiki.qemu.org/Documentation/CreateSnapshot)：

```
qemu-img snapshot -c 'Devuan_NewSystem_NoX' Devuan.qcow2
```

现在，通过

```
qemu-img info Devuan.qcow2
qemu-img snapshot -l Devuan.qcow2 
```

都可以看到虚拟硬盘里存在一个名为 `Devuan_NewSystem_NoX` 的快照。还可以通过类似于：

```
qemu-img create -f qcow2 -F qcow2 -b Devuan.qcow2 Devuan_new.qcow2
```

创建新的磁盘文件。这样以新磁盘启动时所有的新更改都会保存到这个新的磁盘，而原始的磁盘文件作为后端磁盘不会改变。但是在这种情况下，原始的后端磁盘不可以再作任何更改，这种使用方法很适合做临时测试。另外 `qemu-system` 也有一个 `-snapshot` 参数可以在启动时就指定所有更改都是临时的，不会保存到启动磁盘文件里。

## 切换系统 init 为 dinit

`dinit` 是开发者 Davin McCall 几年前开始开发的一个项目，现在已经很成熟了，文档也很齐全，工具主要包括 `dinit` 作为系统 `init` ，和 `dinitctl` 作为服务管理工具，另外还有常规的负责开关机重启的命令。目前 [Chimera Linux](https://chimera-linux.org/about/) 这个 Linux 发行版已经把 `dinit` 作为默认的 `init`，而  [Artix Linux](https://artixlinux.org/) 则分别提供使用 `openrc`、 `dinit`、`runit` 和 `s6` 等作为 `init` 的多种系统镜像文件供选择。Debian 肯定没有官方支持，。

在 Devuan 上要将现在使用的 `runit` 切换到 `dinit`，不需要卸载 `runit`，所以理论上是随时可以切换回来的。并且上面已经把初始系统磁盘留了快照，所以虚拟机已经备份好了。

因为 `dinit` 没有提供二进制包需要自己从源码编译，所以首先来安装一些需要的包（这里用 root 用户登录）：

```
apt install -y doas build-essential git vim
```

按照开发的推荐，还可以装上 `eudev` 和 一个日志管理工具，比如 `rsyslog` 。为了方便使用 root 权限可以直接在 `/etc/doas.conf` 里设置：

```
permit nopass :USER
```

这样所有当前用户组的用户都不需要输入密码了，当然只有在虚拟机里才会这么放肆。

从 GitHub 下载 `dinit` 源码后按照文档，设置了 prefix 为 `/usr/local` 以及 `--shutdown-prefix=dinit-` :

```
./configure --bindir=/usr/local/bin --sbindir=/usr/local/sbin --mandir=/usr/local/share/man --shutdown-prefix=dinit-
```

这样编译得到除了 `/usr/local/bin/dinit` 这些作为 init 和 service manager 的组件以外，`/usr/local/sbin/` 还将安装 `dinit-shutdown` 和 `dinit-reboot` 等。这个时候就可以参照 [Getting Started with Dinit](https://github.com/davmac314/dinit/blob/master/doc/getting_started.md) 简单测试 `dinitctl` 单独作为 service manager 的功能 。接下来就是按照 [Dinit as init: using Dinit as your Linux system's init](https://github.com/davmac314/dinit/blob/master/doc/linux/DINIT-AS-INIT.md) 把 `dinit` 设置为系统 `init`。

按照文档的推荐做法，使用 `dinit` 作为系统 init 需要确保 `dinit` 负责系统启动期间初始化文件系统挂载和检查、设备管理、准备登录 console 以及启动其他自定义服务等等。在源码包里 `doc/linux/services` 附带了所以必须上述服务的示例文件。`dinit` 的工作逻辑是，当系统启动后内核将进程传递到 init 时，这里是 dinit，它会自动查找 `/etc/dinit.d` 等目录（具体参考 `man 8 dinit`) 下的 `boot.d` 列出的默认启动服务， `boot.d` 里的服务脚本一般是指向 `/etc/dinit.d` 对应文件的软链接。所以逻辑就是 `/etc/dinit.d` 存放所有安装的服务，需要启动某个服务的时候在 `boot.d` 建立对应服务的软连接就可以了。默认情况下 `boot.d` 里只有 `dhcpcd`，`sshd`，`modules` 和 `late-filesystems`  几个文件。

保守的做法是，移除 `sshd` 和 `dhcpcd`，因为这两个服务完全是应用服务，不关乎系统正常工作，可以等到确保 `dinit` 正常工作后随时启动它们。剩下是 `modules` 和 `late-filesystems` ，为了加载可能需要的内核模块和准备所有文件系统。查看这两个文件内容：

```
$ cat modules
type = scripted
command = /etc/dinit.d/modules.sh start
log-type = buffer
restart = false

depends-on: early-filesystems


$ cat late-filesystems
# Filesystems which can be mounted after login is enabled.

type = scripted
command = /etc/dinit.d/late-filesystems.sh start
restart = false
logfile = /var/log/late-filesystems.log
start-timeout = 0   # unlimited 

options: start-interruptible

depends-on: rcboot
```

这两个服务的正常启动分别依赖 `early-filesystems` 和 `rcboot`。继续查看会发现`early-filesystems` 会执行 `early-filesystems.sh` 这个脚本，`rcboot` 依赖 `filesystems` ，` filesystems` 依赖 `udevd`、`rootrw`、`auxfschec` 和 `udev-settle` 四个服务....这样逐个服务按照依赖关系整理，最确保所有服务和脚本都能正常运行，就确保了 `dinit` 能最终正常启动系统。

这个做法听起来就很繁琐，所以上面说这是“保守”的做法，因为它完全是依照各个服务的依赖关系和启动顺序手动逆向链式整理出来的，这样的做法的好处就是整理一遍之后就能完全理解为什么最后这些服务被启动了，以及它们的相对顺序。

既然有“最保守”的做法，那就有“不保守”的做法。我在实际虚拟机里尝试的时候，就是采取的捷径。简单地说，就是先尝试以 `dinit` 启动，通过查看启动情况，哪里出现服务启动失败就是解决这个错误，最后一步步所有错误都解决了，系统也就正常启动了。最简单的做法是重启虚拟机的时候在 `grub2` 界面按下 `e` 编辑启动项，在 `linux` 内核配置这一行末尾加上 `init=/usr/local/sbin/dinit` 手动指定当前启动使用 `dinit`。不出意外的话系统会出现某个服务启动失败，比如在默认情况下启动出错在：



出错的服务是 ` filesystems`，具体的错误在上面两行，`hwclock` 命令不存在。由于只是设置硬件时钟的命令，完全可以放心禁用。查找一下，具体是 ` filesystems` 依赖 `rootrw`，`rootrw` 又依赖 `hwclock`。所以很简单，在 `rootrw` 服务里把 `waits-for: hwclock` 这一行依赖暂时注释掉。

由于现在系统启动失败，但是 rescue 模式可用，所以在上面这个界面选择选择 `e` 然后输入 root 密码就可以进入 rescue 模式了。在这个模式下，根分区会以只读模式挂载，但是现在需要修改 `/etc/dinit.d/rootrw` 服务文件依赖，所以需要

```
mount -o remount,rw /
```

将根分区重启挂载为可读。修改 `rootrw` 后重启。现在刚刚出现的 `hwclock` 应该就不会再出现了。但是启动仍然在 `filesystems` 服务出现错误，可以看到它的所有依赖服务 `udevd`、`rootrw`、`auxfscheck` 和 `udev-settle` 都已经启动成功，表明现在失败的是 ` filesystems`。查看 ` filesystems` 内容：

```
# Auxillary (non-root) filesystems

type = scripted
command = /etc/dinit.d/filesystems.sh start
restart = false
logfile = /var/log/dinit-filesystems.log
start-timeout = 1200   # 20 minutes

depends-on: udevd
depends-on: rootrw
waits-for: auxfscheck
waits-for: udev-settle
```

表明这个服务运行了同名脚本 `/etc/dinit.d/filesystems.sh start` ，继续查看这个脚本：

```
#!/bin/sh
export PATH=/usr/bin:/usr/sbin:/bin:/sbin

set -e

if [ "$1" != "stop" ]; then

  echo "Mounting auxillary filesystems...."
  swapon /swapfile
  mount -avt noproc,nonfs

fi;
```

发现这个脚本只执行两个命令，并且错误很明显：`swapon` 默认使用一个系统文件作为交换分区，和实际情况不符。比如在这里只需要改正其为 `swapon /dev/vda3` 重启就发现 `filesystems` 不再报错了。当然，会出现新的错误：



`rcboot` 服务出错。同样思路查看 `rcboot.sh` ：

```
  ...
  # empty utmp, create needed directories
  : > /var/run/utmp
  mkdir -m og-w /var/run/dbus

  # Configure random number generator
  if [ -e /var/state/random-seed ]; then
    cat /var/state/random-seed > /dev/urandom;
  fi
  
  # Configure network
  /sbin/ifconfig lo 127.0.0.1

  # You can put other static configuration here:
  #/sbin/ifconfig eth0 192.168.1.38 netmask 255.255.255.0 broadcast 192.168.1.255

  echo "myhost" > /proc/sys/kernel/hostname

  # /usr/sbin/alsactl restore
  ...
```

发现这个脚本里出现 `/sbin/ifconfig lo 127.0.0.1` 这行命令，这里没有安装。改为 `/sbin/ifup lo`。偷懒一下，把 `/sbin/ifup eth0` 也加在这一行下面，同时可以把下面设置主机名也改好，这几行改为：

```
/sbin/ifup lo
/sbin/ifup eth0
echo "MyDevuan.vm.local" > /proc/sys/kernel/hostname
```

再保存重启。在我这里，改到这里系统已经可以完全启动到 tty1，至此，dinit 完全接管 init 正常启动了系统：

```
root@MyDevuan:~# ps -aux |head -n2
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.2  0.1   6500  3560 ?        S    14:06   0:00 /usr/local/bin/dinit
root@MyDevuan:~# dinitctl list
[[+]     ] boot
[{+}     ] tty1 (pid: 370)
[{+}     ] loginready (has console)
[{+}     ] rcboot
[{+}     ] filesystems
[{+}     ] udevd
[{+}     ] early-filesystems
[{+}     ] rootrw
[{+}     ] rootfscheck
[{+}     ] udev-trigger
[{+}     ] auxfscheck
[{+}     ] udev-settle
[     {X}] dbusd
[     {X}] syslogd
[{+}     ] tty2 (pid: 369)
[{+}     ] tty3 (pid: 368)
[{+}     ] tty4 (pid: 367)
[{+}     ] tty5 (pid: 366)
[{+}     ] tty6 (pid: 365)
[{+}     ] modules
[{+}     ] late-filesystems
```

到了这一步，剩下就是根据内容和系统命令路径对每个脚本改动进行改动，让系统可以顺利启动、需要的服务可以开启。比如这里 `dbus` 启动失败了，因为没有安装它。查看发现 `loginready` 依赖它，因为现在虚拟机系统暂时还不涉及图形化登录和桌面环境这些，`dbus` 可以直接注释掉。另一个失败的服务 `syslogd` 也类似，系统只安装了 `rsyslogd`，所以相应改正服务脚本对应内容

```
command = /usr/sbin/syslogd
pid-file = /var/run/syslogd.pid
```
改为：

```
command = /usr/sbin/rsyslogd
pid-file = /var/run/rsyslogd.pid
```

`dinitctl reload syslogd`  之后 `dinitctl start syslogd` 就可以正常启动了！

现在所有需要的系统服务都已经可以正常启动，网络已经连接，可以 `dinitctl enable sshd` 了。所有服务正常启动就可以在 `/etc/default/grub` 里就设置：

```
GRUB_CMDLINE_LINUX_DEFAULT="quiet init=/usr/local/sbin/dinit"
```

把 `dinit` 作为默认启动了。也可以可以把 `/sbin/init` 改为指向 `/usr/local/sbin/dinit` 的软链接，这样不需要更改 `grub2` 的任何配置文件，因为它默认就会使用 `/sbin/init` 启动系统。在此之前可以看到 `/sbin/init`  作为软链接指向 `/lib/runit/runit-init` 。

## 回到 runit

测试体验完 `dinit`，也许厌了，随时想切换回 runit 也很简单：把 `/sbin/init` 改回指向 `/lib/runit/runit-init` 的软链接 ，在`/etc/default/grub` 里去掉 

```
GRUB_CMDLINE_LINUX_DEFAULT="quiet init=/usr/local/sbin/dinit"
```

指定 `init` 参数，重启。

## A few more things

### 完整的命令

多看文档，还有能改进的地方

```
qemu-system-x86_64 -nodefaults -enable-kvm -m 3g -smp 2 
    -global qxl-vga.vgamem_mb=64 -vga qxl \
    -drive "if=virtio,media=disk,file=$HOME/Programs/VMs/vdisks/Devuan.qcow2" \
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
    -drive "if=pflash,format=raw,file=$HOME/Programs/VMs/firmwares/Devuan.fd" \
    -netdev user,id=net0,hostfwd=tcp::5679-:22 \
    -device virtio-net-pci,netdev=net0 \
    -daemonize -no-reboot
```

这里另加的参数和作用：

- `-nodefaults` ：字面意思，默认情况下 QEMU 创建的虚拟机带有软盘和光驱等设备，使用这个参数禁用默认配置

- `-vga qxl` 设置显卡类型为 QXL，也可以使用 `-device qxl-vga` 这种写法，这个参数以及随后的  

- `-global qxl-vga.vgamem_mb=64` 同时设置显存大小为 64Mb。使用 QXL 比默认 `std` 性能更好，比如虚拟机显示器能设置到 2K 分辨率，所以这里才需要增加显存。其他还有很多种显卡类型可以设置，参考文档。需要注意的一点是，使用 QXL 后如果虚拟机安装图形界面则需要安装对应的 QXL 显卡驱动，例如在 Devuan 下需要安装 `xserver-xorg-video-all` 。这两个参数另一种写法是：

    ```
        -vga qxl -device qxl,vram_size_mb=64,ram_size_mb=64,vram64_size_mb=64
    ```

    或者：

    ```
       -vga none -device qxl-vga,vgamem_mb=64
    ```

    

- `-daemonize` 字面意思，把启动的虚拟机放在后台运行，这样就不再占用终端。在 Bash 里相当于 `cmd &` 执行。使用参数的好处在于，不论使用什么 Shell 运行命令参数都可以使虚拟机后台打开，但是如果使用 Bash  的 `cmd &` 形式的话，命令换到 Zsh 执行就不适用，因为 Zsh 后台执行需要形如 `cmd &|` 的命令

- `-no-reboot` 设置禁止虚拟机重启，它的作用是在运行的虚拟机里重启系统时，虚拟机会关机而不会重启

### Rootless Xorg

如果普通用户需要通过 tty 通过 `startx` 或者 `xinit` 直接启动图形界面，还需要安装启动 `dbus` 和 `seatd` 服务：

```
# elogind
type            = process
command         = /usr/libexec/elogind
smooth-recovery = true
depends-on      = dbus

# dbus
type = process
command = /usr/bin/sh -c "install -m755 -g 81 -o 81 -d /run/dbus && dbus-uuidgen --ensure && exec /usr/bin/dbus-daemon --system --nofork --nopidfile --print-pid"
logfile = /var/log/dbus.log
depends-on = loginready

# seatd
type = process
command = /usr/sbin/seatd -g video
logfile = /var/log/seatd.log
depends-on = loginready
```

手动或者通过服务脚本启动这些小服务都很简单，难的地方在于决定依赖关系，谁应该先启动和依赖于谁。这几个小脚本可以参考 [artiX Linux](https://packages.artixlinux.org/packages/system/any/elogind-dinit/) ，[Antix Linux](https://antixlinux.com/) 和 [Chimera Linux](https://chimera-linux.org/docs/configuration/services) 这些发行版的已经打包的服务脚本。`elogind` 服务目前看至少启动到 TTY 和通过 `startx` 或者 `xinit` 启动到图形化界面都并非必须，它和 `seatd` [二选一即可](https://wiki.alpinelinux.org/wiki/Seatd)。

### the init playground

除了 `runit`， `dinit` 和 good old  `sysVinit` + `openRC` 之外，还有 `finit` 和 `s6`，以及很多这些 `init` 的灵感来源：`daemontools` 和 `daemontools-encore`

- Daniel J. Bernstein's **daemontools**: [daemontools: a collection of tools for managing UNIX services](https://cr.yp.to/daemontools.html)
- Bruce Guenter's **daemontools-encore**: [daemontools-encore:  A collection of tools for managing UNIX services](https://untroubled.org/daemontools-encore/), it is derived from the public-domain release of daemontools by D. J. Bernstein
- Laurent Bercot's **s6**: [s6: a small suite of programs for UNIX, designed to allow process supervision as well as various operations on processes and daemons](https://skarnet.org/software/s6/index.html)
- Gerrit Pape's **runit**: [runit - a UNIX init scheme with service supervision](https://smarden.org/runit/)
- Davin McCall's **dinit**: [dinit: service manager and "init" system](https://davmac.org/projects/dinit/)
- Joachim Wiberg' **finit**: [Finit is a sysv init and systemd alternative](https://troglobit.com/projects/finit/)

值得一看/读的还有：

- [monit: a watchdog with a toolbox in your container or server](https://mmonit.com/monit/)

- [runit Linux: Complete Guide to Unix Init Scheme with Service Supervision](https://codelucky.com/runit-linux-init-service-supervision/)

- [Daemon Showdown: Upstart vs. Runit vs. Systemd vs. Circus vs. God](https://centos-vn.blogspot.com/2014/06/daemon-showdown-upstart-vs-runit-vs.html) and [HackerNews post](https://news.ycombinator.com/item?id=5345413)

- [Process Supervision: Solved Problem](https://jtimberman.housepub.org/blog/2012/12/29/process-supervision-solved-problem)

- [No systemd](https://nosystemd.org/)

- [User Specific Runit Supervisor](https://www.troubleshooters.com/linux/init/normal_user_runit.htm)

- [Void Linux Docs: Services and Daemons - runit](https://docs.voidlinux.org/config/services/index.html)

- [Chimera Linux Documentation: Service management](https://chimera-linux.org/docs/configuration/services)
  

最后，在写作这篇博文整个过程中我参考了以下文档/博客：

- [Debian Wiki: SecureBoot VirtualMachine](https://wiki.debian.org/SecureBoot/VirtualMachine)
- [Debian Package: ovmf](https://packages.debian.org/stable/all/ovmf/filelist)
- [Ubuntu Wiki: OVMF](https://wiki.ubuntu.com/UEFI/OVMF)
- [Open Virtual Machine Firmware (OVMF) Status Report](https://www.linux-kvm.org/downloads/lersek/ovmf-whitepaper-c770f8c.txt)
- [Gentoo Wiki: QEMU](https://wiki.gentoo.org/wiki/QEMU)
- [ArchWiki: QEMU](https://wiki.archlinux.org/title/QEMU)
- [Something witty yet insightful: Secure(ish) boot with QEMU](https://www.labbott.name/blog/2016/09/15/secure-ish-boot-with-qemu/)
- [kraxel's news: VGA and other display devices in qemu](https://www.kraxel.org/blog/2019/09/display-devices-in-qemu/)

