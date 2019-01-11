---
title: RNA-Seq 数据处理记录
author: Jackie
date: '2018-12-10'
slug: rna-seq-analysis
categories:
  - Bioinformatics
tags:
  - Bioinformatics
  - RNA-Seq
disable_comments: no
show_toc: yes
---

```
本来是 6 月份的东西，一直没有好好整理拖到年底了，唉 ....
```

毕业答辩过了，最大的坎儿迈过去了。准备开始处理手头拿到的 RNA-Seq 数据。当作是我的第一次实战。

实验设计是干预组和对照组各 4 只大鼠，很简单的 2 * 4 的设计。

首先想到的是看看 [生信菜鸟团](http://www.bio-info-trainee.com/) 有没有实战的 WorkFlow 用来参考，结果刚好就有 [一篇 HISAT2 + HT-Seq 的实战帖](http://www.bio-info-trainee.com/2218.html) ，所以就直接照着来一遍先。

最开始以为整个过程应该会比较顺利，因为生信菜鸟团的帖子已经很详细了，而且我手边还有一份 Nature Protocols 的详细的流程参考：[Transcript-level expression analysis of RNA-seq experiments with HISAT, StringTie and Ballgown](https://www.nature.com/articles/nprot.2016.095)。最后发现我还是 Too young too simple 啊。

所以，最后自己强烈的感受就是。**看教程始终很简单，真正自己做的时候会在意外的地方趟进坑里。** 实践才能出真知。

好吧，下面开始。

首先是原始数据，测序公司已经处理过得到的 clean 的原始数据：

```bash
➜ ls -lh
total 42G
-rwxrwxrwx 1 adam adam 2.6G May 19 18:01 CLP1.R1.clean.fastq.gz
-rwxrwxrwx 1 adam adam 2.8G May 19 17:57 CLP1.R2.clean.fastq.gz
-rwxrwxrwx 1 adam adam 2.4G May 19 17:53 CLP2.R1.clean.fastq.gz
-rwxrwxrwx 1 adam adam 2.6G May 19 18:00 CLP2.R2.clean.fastq.gz
-rwxrwxrwx 1 adam adam 2.8G May 19 16:06 CLP3.R1.clean.fastq.gz
-rwxrwxrwx 1 adam adam 3.1G May 19 18:03 CLP3.R2.clean.fastq.gz
-rwxrwxrwx 1 adam adam 2.6G May 19 21:22 CLP4.R1.clean.fastq.gz
-rwxrwxrwx 1 adam adam 2.8G May 19 21:33 CLP4.R2.clean.fastq.gz
-rwxrwxrwx 1 adam adam 2.6G May 19 16:57 NC1.R1.clean.fastq.gz
-rwxrwxrwx 1 adam adam 2.8G May 19 17:01 NC1.R2.clean.fastq.gz
-rwxrwxrwx 1 adam adam 2.3G May 19 16:55 NC2.R1.clean.fastq.gz
-rwxrwxrwx 1 adam adam 2.5G May 19 16:57 NC2.R2.clean.fastq.gz
-rwxrwxrwx 1 adam adam 2.6G May 19 16:01 NC3.R1.clean.fastq.gz
-rwxrwxrwx 1 adam adam 2.8G May 19 18:02 NC3.R2.clean.fastq.gz
-rwxrwxrwx 1 adam adam 2.4G May 19 21:24 NC5.R1.clean.fastq.gz
-rwxrwxrwx 1 adam adam 2.6G May 19 21:28 NC5.R2.clean.fastq.gz
```
可以看到数据还是蛮大的，没解压的一个数据都是 2~3G。

## 第一个问题

直接比对吧：

```bash
➜ reference=/home/adam/Bioinformatics/References/grcm38_tran/genome_tran
➜ hisat2 -p 3 -x $reference \ 
  -1 /media/adam/DATA/RNA-Seq.20180410/raw/CLP1.R1.clean.fastq.gz \
  -2 /media/adam/DATA/RNA-Seq.20180410/raw/CLP1.R2.clean.fastq.gz \
  -S /media/adam/DATA/RNA-Seq.20180410/sam/CLP1.sam \
  2> /media/adam/DATA/RNA-Seq.20180410/sam/CLP1.log
```

比对结果：

>39332695 reads; of these:
39332695 (100.00%) were paired; of these:  
37598182 (95.59%) aligned concordantly 0 times  
1650296 (4.20%) aligned concordantly exactly 1 time  
84217 (0.21%) aligned concordantly >1 times  

>37598182 pairs aligned concordantly 0 times; of these:  
>23151 (0.06%) aligned discordantly 1 time

>37575031 pairs aligned 0 times concordantly or discordantly; of these:  
75150062 mates make up the pairs; of these:  
71576233 (95.24%) aligned 0 times  
3405235 (4.53%) aligned exactly 1 time  
168594 (0.22%) aligned >1 times  
**9.01% overall alignment rate**  

总共 9.01% 的比对率发觉不对。然后又比对了一个对照组的样本看看：

```
➜ reference=/home/adam/Bioinformatics/References/grcm38_tran/genome_tran
➜ hisat2 -p 3 -x $reference \ 
  -1 /media/adam/DATA/RNA-Seq.20180410/raw/NC1.R1.clean.fastq.gz \
  -2 /media/adam/DATA/RNA-Seq.20180410/raw/NC1.R2.clean.fastq.gz \
  -S /media/adam/DATA/RNA-Seq.20180410/sam/NC1.sam \
  2> /media/adam/DATA/RNA-Seq.20180410/sam/NC1.log
```

再看一波结果：

>38339990 reads; of these: 
38339990 (100.00%) were paired; of these:  
36607018 (95.48%) aligned concordantly 0 times  
1650547 (4.31%) aligned concordantly exactly 1 time  
82425 (0.21%) aligned concordantly >1 times  

>36607018 pairs aligned concordantly 0 times; of these:  
23932 (0.07%) aligned discordantly 1 time

>36583086 pairs aligned 0 times concordantly or discordantly; of these:  
73166172 mates make up the pairs; of these:  
69327494 (94.75%) aligned 0 times  
3644535 (4.98%) aligned exactly 1 time  
194143 (0.27%) aligned >1 times  
**9.59% overall alignment rate** 

总比对率 9.59%。
不对不对，肯定有问题。

首先反复看了 HISAT2 的 Manual 确认我的参数没有用错。

**直接把 “HISAT2  low overall alignment rate” 拿到 Google 一搜，发现一个问题，基本上出这个情况的都是因为参考基因组用错。**

这样我就去看了一下，我在 [HISAT2 官网](https://ccb.jhu.edu/software/hisat2/index.shtml) 下的 `M. musculus, GRCm38` 基因组，我往上下翻着看了一下一堆基因组 `R. norvegicus, UCSC rn6`、`D. melanogaster` 等等我只认识线虫。
然后我就好奇的一个一个查了一下都是代表什么生物，最后发现 **`M. musculus` 是小鼠，而 `R. norvegicus` 是大鼠**。而**我的数据就是大鼠，也就是说我参考基因组真的用错了**。

好吧，我的锅。重新下载大鼠基因组，解压之后再来：

```bash
➜ REF=/home/adam/Bioinformatics/References/Rattus.Norvegicus.6/genome
➜ RAW_DIR=/media/adam/DATA/RNA-Seq.20180410/raw
➜ SAM_DIR=/media/adam/DATA/RNA-Seq.20180410/sam

➜ hisat2 -p 3 -x $REF -1 $RAW_DIR/CLP1.R1.clean.fastq.gz \ 
  -2 $RAW_DIR/CLP1.R2.clean.fastq.gz \ 
  -S $SAM_DIR/CLP_1.SAM 2> $SAM_DIR/CLP_1.LOG 
```

看结果：

>39332695 reads; of these:    
39332695 (100.00%) were paired; of these:  
1514532 (3.85%) aligned concordantly 0 times    
34474411 (87.65%) aligned concordantly exactly 1 time  
3343752 (8.50%) aligned concordantly >1 times  

>1514532 pairs aligned concordantly 0 times; of these:  
181725 (12.00%) aligned discordantly 1 time  

>1332807 pairs aligned 0 times concordantly or discordantly; of these:  
2665614 mates make up the pairs; of these:  
1480066 (55.52%) aligned 0 times 
1020001 (38.27%) aligned exactly 1 time  
165547 (6.21%) aligned >1 times  
**98.12% overall alignment rate**  

嗯，总比对率 98% 以上，果然。
而且发现这一次生成的 `sam` 文件明显是增大的。

然后就是一样的，把其他所有的都做了。

```
# 这里其实应该写个循环
➜ hisat2 -p 3 -x $REF -1 $RAW_DIR/CLP2.R1.clean.fastq.gz \
  -2 $RAW_DIR/CLP2.R2.clean.fastq.gz \
  -S $SAM_DIR/CLP_2.SAM 2> $SAM_DIR/CLP_2.LOG

➜ hisat2 -p 3 -x $REF -1 $RAW_DIR/CLP3.R1.clean.fastq.gz \
  -2 $RAW_DIR/CLP3.R2.clean.fastq.gz \ 
  -S $SAM_DIR/CLP_3.SAM 2> $SAM_DIR/CLP_3.LOG

➜ hisat2 -p 3 -x $REF -1 $RAW_DIR/CLP4.R1.clean.fastq.gz \ 
  -2 $RAW_DIR/CLP4.R2.clean.fastq.gz \ 
  -S $SAM_DIR/CLP_4.SAM 2> $SAM_DIR/CLP_4.LOG

➜ hisat2 -p 3 -x $REF -1 $RAW_DIR/NC1.R1.clean.fastq.gz \ 
  -2 $RAW_DIR/NC1.R2.clean.fastq.gz \ 
  -S $SAM_DIR/NC_1.SAM 2> $SAM_DIR/NC_1.LOG 

➜ hisat2 -p 3 -x $REF -1 $RAW_DIR/NC2.R1.clean.fastq.gz \ 
  -2 $RAW_DIR/NC2.R2.clean.fastq.gz \ 
  -S $SAM_DIR/NC_2.SAM 2> $SAM_DIR/NC_2.LOG

➜ hisat2 -p 3 -x $REF -1 $RAW_DIR/NC3.R1.clean.fastq.gz \ 
  -2 $RAW_DIR/NC3.R2.clean.fastq.gz \ 
  -S $SAM_DIR/NC_3.SAM 2> $SAM_DIR/NC_3.LOG

➜ hisat2 -p 3 -x $REF -1 $RAW_DIR/NC5.R1.clean.fastq.gz \ 
  -2 $RAW_DIR/NC5.R2.clean.fastq.gz \
  -S $SAM_DIR/NC_5.SAM 2> $SAM_DIR/NC_5.LOG
```

然后用 samtools 把 `sam` 文件排序并转成二进制的 `bam` 文件，这样可以大大减少文件占用体积。我的数据 `sam` 文件都是 35\~40G 的样子，但是转成 `bam` 后每个文件大概 7\~9G。

直接用循环一把梭哈（注意 samtools 默认会按照 position 即坐标位置排序，要想根据 name 排序要指定 `-n` 参数）：

```bash
➜ for i in `ls *.SAM`
	samtools sort -@ 3 -o bam/${i%.*}.sorted.BAM $i
```

最后就是用 HT-Seq 进行基因定量了。这一步必须要提供参考基因组的 `GTF` 文件，这里我就趟到了我的整个分析过程的第二个坑了。

## 第二个问题

这一步出错是由于之前不知道这个数据库提供基因组和注释的区别，我开始在 [UCSC](https://genome.ucsc.edu/cgi-bin/hgGateway) 没有找到 `GTF` 下载的地方，就直接跑去下载了 [Ensembl](https://asia.ensembl.org/index.html) 的注释文件。但实际上在比对这一步 HISAT2 官网提供的是 UCSC 的基因组 index，所以后面定量也必须使用 UCSC 的注释文件。由于我两个混用了导致定量这一步始终无法得到结果。花费了一整天去搜资料，定位到是注释文件的问题。最终还是在 [BioStars](https://www.biostars.org/) 上提问 [Question: Help with rat RNA-Seq data with the HISAT-StringTie workflow](https://www.biostars.org/p/317670/#317695) ，最终在热心网友的的帮助下才下载到了 UCSC 的注释文件。

具体来说，UCSC 没有提供现成的 Rat 的基因组 `GTF` 拿来用，我们下载 [ensGene.txt.gz](http://hgdownload.cse.ucsc.edu/goldenPath/rn6/database/ensGene.txt.gz) 这个文件然后借助他们提供的 [genePredToGtf](http://genomewiki.ucsc.edu/index.php/Genes_in_gtf_or_gff_format) 工具就可以自己制作 `GTF` 了：

```bash
cut -f 2- ensGene.txt > Ens.Gene.txt
genePredToGtf file Ens.Gene.txt Rn6.Ensembl.Gene.GTF
```

刚刚提到 samtools 默认以位置排序在这里就要派上用场了。htseq-count 的 help 里写道：

```
-r {pos,name}, --order {pos,name}
               'pos' or 'name'. Sorting order of <alignment_file>
               (default: name). Paired-end sequencing data must be
               sorted either by position or by read name, and the
               sorting order must be specified. Ignored for single-
               end data.
```

就是说对于 paired-end 测序必须显式指定 `bam` 文件的排序情况。 那我们就指定 `-r pos` 就行了：

```bash
➜ for i in `ls *.BAM`
    htseq-count -f bam -s no -r pos -i gene_id $i \
    ~/Bioinformatics/References/Rattus.Norvegicus.6/UCSC.rn6.GTF \
    1> ../counts/${i%%.*}.geneCounts \
    2> ../counts/${i%%.*}.htseq.log
```

这样每个样本会输出一个 xxx.geneCounts 这样的文件，最后得到了一堆的 geneCounts 文件，直接 R 读进去合成一个 data.frame 就可以用 `DESeq2`、`edgeR` 后续分析了。

关于读入多个数据合成一个，一点 hint：

```r
files <- list.files(path = "/path/to/files", pattern = '.geneCounts')
do.call("cbind", lapply(files, read.csv, header = TRUE)) 
```

## 总结

1. 参考基因组很重要
2. 像这样很长的流程要中间步骤多记录，后面好总结和出问题方便排查
3. 流程不熟的时候跑样本可以先只跑一两个试一下，不要一上来就循环一把梭哈
4. 实践！实践！实践！