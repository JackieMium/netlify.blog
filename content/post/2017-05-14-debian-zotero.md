---
title: 在 Debian 中使用 Zotero 文献管理软件
author: Jackie
date: '2017-05-14'
slug: debian-zotero
categories:
  - Linux
tags:
  - Linux
  - 软件
  - 问题
disable_comments: false
---


我在 Debian 中用 Zotero 管理文献时发现 PDF 导入后获取文件信息获取不到。以下时解决过程记录，主要参考 [Configuring Zotero PDF full text indexing in Debian Jessie](https://vk5tu.livejournal.com/54476.html)。

安装 pdftotext 和 pdfinfo:

```bash
sudo apt-get install poppler-utils
```

查看内核信息和机器架构:

```bash
uname --kernel-name --machine
```

在 Zotero 的数据目录里建立刚刚安装的两个包的命令链接，链接名要包含上面查到的内核和机器架构信息

```bash
cd ~/.zotero
ln -s $(which pdftotext) pdftotext-$(uname -s)-$(uname -m)
ln -s $(which pdfinfo) pdfinfo-$(uname -s)-$(uname -m)
```

最后还需要一个小脚本来改变 `pdfinfo` 命令的参数:

```bash
cd ~/.zotero
wget -O pdfinfo.sh https://raw.githubusercontent.com/zotero/zotero/4.0/resource/redirect.sh
chmod a+x pdfinfo.sh
```

为刚刚安装的两个包新建 `*.version` 文件，文件名要包含版本信息:

```bash
cd ~/.zotero
pdftotext -v 2>&1 | head -1 | cut -d ' ' -f3 > pdftotext-$(uname -s)-$(uname -m).version
pdfinfo -v 2>&1 | head -1 | cut -d ' ' -f3 > pdfinfo-$(uname -s)-$(uname -m).version
```

在 Zotero 的设置 "Preferences" - "Search" 应该会看到类似于:

```bash
PDF indexing
  pdftotext version 0.26.5 is installed
  pdfinfo version 0.26.5 is installed
```

这样的信息，表明刚刚安装的工具已经起效了。不要用这里的 "check for update" 来更新这两个包，现在系统 apt 已经接管了。



## 更多

如果上述完成还不可用，运行这个脚本：

```bash
#!/bin/bash

version=$(dpkg-query -W -f='${Version}' poppler-utils || echo "please_install_poppler-utils")

totextbinary='pdftotext-Linux-x86_64'
infobinary='pdfinfo-Linux-x86_64'
infohack='pdfinfo.sh'

for zoteropath in $(find $HOME/.zotero $HOME/.mozilla -name zotero.sqlite -exec dirname {} \;)
do
	echo $version > $zoteropath/"$totextbinary.version"
	echo $version > $zoteropath/"$infobinary.version"

	ln -s /usr/bin/pdftotext "$zoteropath/$totextbinary"
	ln -s /usr/bin/pdfinfo "$zoteropath/$infobinary"

	cat > $zoteropath/$infohack << EOF

#!/bin/sh
if [ -z "\$1" ] || [ -z "\$2" ] || [ -z "\$3" ]; then
    echo "Usage: $0 cmd source output.txt"
    exit 1
fi
"\$1" "\$2" > "\$3"
EOF

	chmod +x $zoteropath/$infohack

done
```

脚本来自 [bugs.debian.org](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=781009)。