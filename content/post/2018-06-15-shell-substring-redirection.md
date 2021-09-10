---
title: Shell 字符串取子集和输出重定向
author: Jackie
date: '2018-06-15'
slug: shell-substring-redirection
categories:
  - Linux
tags:
  - Code
  - Linux
  - 基础
disable_comments: no
---

![string subset and ouput redirection](/post/2018-06-15-shell-substring-redirection_files/screenshot_2018-06-15_10-22-22.png)


最近处理数据经常需要取某个字符串一部分用来重命名结果生成的新文件的情况，比如 `sample1.fastq.gz` 比对到基因组想要取出其中的 `sample1` 用来命名生成的 `sam` 文件，或者想看跑的时候输出的 log，PC 跑起来太慢不能盯着看  log 又要求 log 得重定向。每次都要查一下取子集和输出和错误怎么重定向，自己都烦了，干脆写在这儿了。这两个虽然不是一个东西，但是用起来经常是一起用的，而且也不长我就直接写在一起了。

## 字符串取子集

Shell 里字符串取子集用 `${}` 这样的命令形式。下面直接通过具体例子来说明。

我们假定变量用来存放一个文件和它的路径( Shell 的等号两边不要加空格)： `file=/path/to/file/my.file.txt`

下面就用 `${ }` 分別获得不同的值：

左边：

- `${file#*/}`：去掉第一个 `/` 及其左边的字串：`path/to/file/my.file.txt`
- `${file##*/}`：去掉最后一个 `/` 及其左边的字串：`my.file.txt`

右边：

- `${file%/*}`：去掉最后一个 `/` 及其右边的字串：`/path/to/file`
- `${file%%/*}`：去掉第一个 `/` 及其右边的字串：(空)

__关于 `%` 和 `#` 谁是左谁是右，简单的记法就是看这两个键位在普通 QWERTY 键盘上的位置__：

- `#`  是去掉左边 (在键盘上 `#` 在 `%` 的左边)
- `%` 是去掉右边 (在键盘上 `%` 在 `#` 的右边)
- 符号用一次是最小匹配﹔两个连用就是最大匹配

截取和替换：

- `${file:0:5}`：提取起始 1-5 个字节：`/path`
- `${file:5:5}`：提取第 5 个字节右边的连续 5 个字节：`/to/f`
- `${file/path/dir}`：把第一个 `path` 替换为 `dir`：`/dir/to/file/my.file.txt`
- `${file//f/F}`：把全部 `f` 替换为 `F`：`/path/to/File/my.File.txt`


## 输出重定向

Linux 中有三种标准输入输出，它们分别是 `STDIN`，`STDOUT`，`STDERR`，分别对应的数字是 `0`，`1`，`2`。

- `STDIN` 是标准输入，默认从键盘读取信息
- `STDOUT` 是标准输出，默认将输出结果输出至终端打印出来
- `STDERR` 是标准错误，默认将输出结果输出至终端打印出来

由于 `STDOUT` 与 `STDERR` 都会默认显示在终端上，为了区分二者的信息，于是就规定编号 `1` 表示 `STDOUT`，`2` 表示 `STDERR`。

搞清楚标准输入输出和错误输出再来看具体的命令形式就简单多了：

- 终端执行 `command` 后，默认情况下，执行结果 `STDOUT` 作为标准输出和 `STDERR` 错误输出（如果有的话）都直接被在终端打印出来，或者说终端直接显示出来。

- 终端执行 `command 1> out.txt 2> err.txt` 后，会将 `STDOUT` 与 `STDERR` 分别输出到 `out.txt` 和 `err.txt` 中。该命令也可以写成下面三种形式:
    ```bash
    command > out.txt 2> err.txt
    command 2> err.txt >out.txt
    command 2> err.txt 1> out.txt
    ```
即顺序谁前谁后无所谓，而且默认输出就是 `1`，所以它是可以直接省略掉的。

再有，在 `command > file 2>&1` 这个命令里， `&` 并不是后台或者 AND 的意思。放在 `>` 后面的 `&`，表示重定向的目标不是一个普通文件，而是一个 `文件描述符`(file descriptor, `fd`)，是标准输入输出这些。所以 `2> 1` 代表将 `STDERR` 即错误输出重定向到当前路径下文件名为 `1` 的 `普通文件` 中，而 `2> &1` 却是代表将重定向到`文件描述符`为 `1` 代表的那个输入输出设备（这里是标准输出）。而由于标准输出已经被重定向到 `file` 中，因此最终的结果为标准输出和错误输出都被重定向到 `file` 中。

`&> file` 是一种特殊的用法，也可以写成 `>& file`，二者的意思完全相同，都等价于 `>file 2> &1`，这里 `&>` 或者 `>&` 都应该视作整体，分开没有单独的含义。


## **顺序***

在重定向命令中，命令的顺序很重要。比如

```bash
ls > dirlist 2>&1
```

会把标准输出 `1` 和标准错误 `2` 都重定向到文件 `dirlist` 里。调换重定向顺序为

```bash
ls 2>&1 > dirlist
```

却只会把标准输出 `1` 重定向到 `dirlist`, 而标准错误 `2` 会被重定向到标准输出 `1` 从而直接打印到屏幕上。原因在于第一个命令里，首先 `1` 已经被重定向到了 `dirlist`，然后 `2` 再被重定向到 `1`，所以二者都被定向到了 `dirlist`；而在第二个命令里，`2` 首先被重定向到了 `1`，但是这个时候 `1` 还没有重定向到 `dirlist`，所以 `2` 会被打印出来而 `1` 被重定向到了 `dirlist`。（试验这个现象要在 Bash 里来做，zsh 会得到不一样的结果）


- [GNU Bash Manual: Redirections](https://www.gnu.org/software/bash/manual/html_node/Redirections.html)