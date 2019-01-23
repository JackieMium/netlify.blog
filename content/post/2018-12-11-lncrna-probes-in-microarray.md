---
title: 从芯片数据提取 lncRNA 探针
author: Jackie
date: '2018-12-11'
slug: lncrna-probes-in-microarray
categories:
  - Bioinformatics
tags:
  - Bioinformatics
  - RNA-Seq
disable_comments: no
show_toc: yes
---

```
又是一篇放了好久好久，没有好好整理的东西。
```

## 1.  准备数据

需要数据有：芯片序列信息、基因组 lncRNA 参考基因组：

所用软件：[SeqMap](http://www-personal.umich.edu/~jianghui/seqmap/)、R

芯片是 Affymetrix 的 Human Genome U133 Plus 2.0 Array， 序列数据来自官网提供：[HG-U133_Plus_2 Consensus Sequences, FASTA (22 MB, 8/20/08)](https://www.affymetrix.com/support/technical/byproduct.affx?product=hg-u133-plus)。

参考基因组数据用 [Ensembl genome browser 88](http://www.ensembl.org/index.html) 提供的人 ncRNA 基因组，版本号 CRCh38： [Homo_sapiens.GRCh38.ncrna.fa.gz](ftp://ftp.ensembl.org/pub/release-88/fasta/homo_sapiens/ncrna/)。

注意：`SeqMap` 只接受 fasta 格式的输入和对比基因组序列文件。同时，SeqMap 默认只会返回 unique map 的结果。

> Currrently SeqMap supports two input formats for input probe file: FASTA format
> and raw DNA sequence format with one sequence per line. The reference genome file
> has to be in FASTA format. The FASTA format has two parts for each sequence: a tag 
> line and a sequence line. Sequences can take mutiple lines.
>
> **Does SeqMap throw away non-unique mapped targets like Eland?**
>
> No, it doesn't. In output_all_matches mode, all targets will be output. In   /output_statistics or /eland:3 mode, you can set parameter /output_top_matches:N   to keep the top N targets. In /eland:1 or /eland:2 modes, only unique targets   will be output.

参考：

- [SeqMap FAQ](http://www-personal.umich.edu/~jianghui/seqmap/FAQ.html)
- [SeqMap Doc](http://www-personal.umich.edu/~jianghui/seqmap/Docs.txt)

## 2. 序列对比

用 `SeqMap` 将芯片的探针序列 map 到参考 ncRNA 基因组中去，设定参数 0 表示 mismatch=0, 即不允许比对时有 mismatch 存在。

```bash
➜ /path/tp/seqmap 0 HG-U133_Plus_2.probe_fasta gencode.v26.lncRNA_transcripts.fa result.txt /eland:3 /available_memory:8192 /output_all_matches
Command line:SeqMap 0 HG-U133_Plus_2.probe_fasta gencode.v26.lncRNA_transcripts.fa result.txt /eland:3 /available_memory:8192 /output_all_matches 
Loading fasta file HG-U133_Plus_2.probe_fasta.
604258 sequences read, total length is 15106450.
analysing probes...totally 604258 probes, minimum length = 25, maximum length = 25, set internal key length = 25
importing probes.......604258 probes imported. 604258 are valid.
checking resources...64-bit version.
available memory: 8192MB.
generating reversed probes for searching reverse strand
now 1208516 probes. 1208516 are valid.
Split probe into 1 parts.
total 1 copies of probes.
estimated memory usage: 202MB.
Building 1 probe lists.1 probe lists created.
estimated search speed is 1.753e+06 bps/sec.
detecting probes

average search steps:1.52896 maximum search steps:5
28394694 base pairs processed. average search speed: 3.72435e+06 bps/sec.
time used: 10.8749 seconds

➜ head -n 10 result.txt  
trans_id	trans_coord	target_seq	probe_id	probe_seq	num_mismatch	strand
ENST00000417324.1|ENSG00000237613.2|OTTHUMG00000000960.1|OTTHUMT00000002842.1|FAM138A-001|FAM138A|1187|	592	TTATGTACGTAAAACACCAGGTGCC	probe:HG-U133_Plus_2:1555822_at:345:1113; Interrogation_Position=607; Antisense;	TTATGTACGTAAAACACCAGGTGCC	0	+
ENST00000417324.1|ENSG00000237613.2|OTTHUMG00000000960.1|OTTHUMT00000002842.1|FAM138A-001|FAM138A|1187|	614	GCCTAACCCGGCACAGAGCAGGAGG	probe:HG-U133_Plus_2:1555822_at:196:479; Interrogation_Position=629; Antisense;	GCCTAACCCGGCACAGAGCAGGAGG	0	+
ENST00000417324.1|ENSG00000237613.2|OTTHUMG00000000960.1|OTTHUMT00000002842.1|FAM138A-001|FAM138A|1187|	635	GAGGGCTAAGCGTGACATCCAGCAC	probe:HG-U133_Plus_2:1555822_at:1160:653; Interrogation_Position=650; Antisense;	GAGGGCTAAGCGTGACATCCAGCAC	0	+
ENST00000417324.1|ENSG00000237613.2|OTTHUMG00000000960.1|OTTHUMT00000002842.1|FAM138A-001|FAM138A|1187|	648	GACATCCAGCACGTGGTCAGTGGAA	probe:HG-U133_Plus_2:1555822_at:750:605; Interrogation_Position=663; Antisense;	GACATCCAGCACGTGGTCAGTGGAA	0	+
ENST00000417324.1|ENSG00000237613.2|OTTHUMG00000000960.1|OTTHUMT00000002842.1|FAM138A-001|FAM138A|1187|	721	TTCAGAGGCACCAAGCTGCTTGTGG	probe:HG-U133_Plus_2:1555822_at:460:1129; Interrogation_Position=736; Antisense;	TTCAGAGGCACCAAGCTGCTTGTGG	0	+
ENST00000417324.1|ENSG00000237613.2|OTTHUMG00000000960.1|OTTHUMT00000002842.1|FAM138A-001|FAM138A|1187|	734	AGCTGCTTGTGGTCTTGTCTATTCC	probe:HG-U133_Plus_2:1555822_at:1084:139; Interrogation_Position=749; Antisense;	AGCTGCTTGTGGTCTTGTCTATTCC	0	+
ENST00000417324.1|ENSG00000237613.2|OTTHUMG00000000960.1|OTTHUMT00000002842.1|FAM138A-001|FAM138A|1187|	765	CTGCCTGACTGAACATTTTCTCCAC	probe:HG-U133_Plus_2:1555822_at:535:389; Interrogation_Position=780; Antisense;	CTGCCTGACTGAACATTTTCTCCAC	0	+
ENST00000417324.1|ENSG00000237613.2|OTTHUMG00000000960.1|OTTHUMT00000002842.1|FAM138A-001|FAM138A|1187|	872	GAGATGTGGCCATCGGAGCCAGCAT	probe:HG-U133_Plus_2:1555822_at:271:643; Interrogation_Position=887; Antisense;	GAGATGTGGCCATCGGAGCCAGCAT	0	+
ENST00000417324.1|ENSG00000237613.2|OTTHUMG00000000960.1|OTTHUMT00000002842.1|FAM138A-001|FAM138A|1187|	886	GGAGCCAGCATTGGCCAATGGACTC	probe:HG-U133_Plus_2:1555822_at:429:853; Interrogation_Position=901; Antisense;	GGAGCCAGCATTGGCCAATGGACTC	0	+0	+
ENST00000391295.1 ncrna chromosome:GRCh38:11:128993237:128993340:-1 gene:ENSG00000212597.1 gene_biotype:snRNA transcript_biotype:snRNA gene_symbol:RNU6-876P description:RNA, U6 small nuclear 876, pseudogene [Source:HGNC Symbol;Acc:HGNC:47839]	73	ACACACAAATTCGTGAAGCATTCCA	probe:HG-U133_Plus_2:216112_at:408:193; Interrogation_Position=1742; Antisense;	ACACACAAATTCGTGAAGCATTCCA	0	+
ENST00000411352.1 ncrna chromosome:GRCh38:19:40708055:40708163:-1 gene:ENSG00000223284.1 gene_biotype:snRNA transcript_biotype:snRNA gene_symbol:RNU6-195P description:RNA, U6 small nuclear 195, pseudogene [Source:HGNC Symbol;Acc:HGNC:47158]	5	TTGCTTCAGCATCACATATAAATAA	probe:HG-U133_Plus_2:242609_x_at:63:1149; Interrogation_Position=256; Antisense;	TTGCTTCAGCATCACATATAAATAA	0	+
```

得到的结果分为 7 列， 官方文档解释为(文档只有 6 列):

>| trans_id | trans_coord |                target_seq | probe_id |                 probe_seq | num_mismatch |
>| -------: | ----------: | ------------------------: | -------: | ------------------------: | -----------: |
>|        1 |      313902 | AACTCCGGGAGGGCCGCTTTGTATG |   509644 | AACTCCGGGAGTGCCGCTTTGTAGG |            2 |
>|        1 |      423680 | TTTCACAATCAATGGATCAGGCCGC |   129326 | TTTCACAATCATTGGATCAGGCCAC |            2 |
>|        1 |      537816 | CTTGAATTCAGTAAATAGTTTAACG |   330515 | CTTGAATTTAGTAAATAGTTTACCG |            2 |
>|        2 |      297292 | CGTCAAATTTCGTCCTTTTCGCTGT |   636826 | CGTCAATTTTCGTCCTTTTCGGTGT |            2 |
>|        2 |      326279 | CGTAGGACCATTCAGGCCGTTAAGC |   986424 | CGTAGGAGCATTCAGGCCGTTATGC |            2 |
>|        2 |      870729 | GTTAACCTGTGGTAAGTAACGTAGT |   433048 | GTTAACCTGGGGTAAGTAACGTATT |            2 |
>|        3 |      204747 | TAGCTCATTAACAGGGGATCTTAGG |   917614 | TAGCTCATTAATAGCGGATCTTAGG |            2 |
>|        3 |      601827 | GTCGTTTTATTCCGCCTGGAGAGGT |   321632 | GTCGTCTGATTCCGCCTGGAGAGGT |            2 |
>|        3 |      674797 | TCGCACTTGGGGCTAAATGGGCATC |   336321 | TCGCACTTCGGGCTAAATGGGAATC |            2 |
>|        3 |      927627 | CAGCCAAAGATACGCAGCTCAGTCT |   619563 | GAGGCAAAGATACGCAGCTCAGTCT |            2 |
>|        4 |      305440 | GACGGAAATCCATATAAGGTAGGGA |    80583 | GACGGAAATCGAGATAAGGTAGGGA |            2 |
>
> There are six columns in the output file. Their meaning are:
>
> |field       |        meaning                                         |
> |:-----------|:-------------------------------------------------------|
> |trans_id      |  ID of the transcript of the mapped target| 
> |trans_coord   | coordinate of the mapped target in the transcript |
> |target_seq    |  mapped sequence of the mapped target in the transcript |
> |probe_id      |  ID of the mapped probe |
> |probe_seq     |  sequence of the mapped probe |
> |num_mismatch  |  total number of mutations (including insertions and deletions also if permitted) occurred in the mapping |


## 3. 提取探针 ID 和基因

将 SeqMap 输出结果直接读入 R 继续处理：

```R
seqmap.result <- read.csv("result.txt", header = TRUE, sep = "\t")

targets <- seqmap.result$trans_id
probes <- seqmap.result$probe_id

targets[1:10]
 [1] "ENST00000417324.1|ENSG00000237613.2|OTTHUMG00000000960.1|OTTHUMT00000002842.1|FAM138A-001|FAM138A|1187|"
 [2] "ENST00000417324.1|ENSG00000237613.2|OTTHUMG00000000960.1|OTTHUMT00000002842.1|FAM138A-001|FAM138A|1187|"
 [3] "ENST00000417324.1|ENSG00000237613.2|OTTHUMG00000000960.1|OTTHUMT00000002842.1|FAM138A-001|FAM138A|1187|"
 [4] "ENST00000417324.1|ENSG00000237613.2|OTTHUMG00000000960.1|OTTHUMT00000002842.1|FAM138A-001|FAM138A|1187|"
 [5] "ENST00000417324.1|ENSG00000237613.2|OTTHUMG00000000960.1|OTTHUMT00000002842.1|FAM138A-001|FAM138A|1187|"
 [6] "ENST00000417324.1|ENSG00000237613.2|OTTHUMG00000000960.1|OTTHUMT00000002842.1|FAM138A-001|FAM138A|1187|"
 [7] "ENST00000417324.1|ENSG00000237613.2|OTTHUMG00000000960.1|OTTHUMT00000002842.1|FAM138A-001|FAM138A|1187|"
 [8] "ENST00000417324.1|ENSG00000237613.2|OTTHUMG00000000960.1|OTTHUMT00000002842.1|FAM138A-001|FAM138A|1187|"
 [9] "ENST00000417324.1|ENSG00000237613.2|OTTHUMG00000000960.1|OTTHUMT00000002842.1|FAM138A-001|FAM138A|1187|"
 [10] "ENST00000417324.1|ENSG00000237613.2|OTTHUMG00000000960.1|OTTHUMT00000002842.1|FAM138A-001|FAM138A|1187|"
unlist(strsplit(targets[1], "\\|"))[1:2]
 [1] "ENST00000417324.1" "ENSG00000237613.2"

probes[1:10]
 [1] "probe:HG-U133_Plus_2:1555822_at:345:1113; Interrogation_Position=607; Antisense;"
 [2] "probe:HG-U133_Plus_2:1555822_at:196:479; Interrogation_Position=629; Antisense;" 
 [3] "probe:HG-U133_Plus_2:1555822_at:1160:653; Interrogation_Position=650; Antisense;"
 [4] "probe:HG-U133_Plus_2:1555822_at:750:605; Interrogation_Position=663; Antisense;" 
 [5] "probe:HG-U133_Plus_2:1555822_at:460:1129; Interrogation_Position=736; Antisense;"
 [6] "probe:HG-U133_Plus_2:1555822_at:1084:139; Interrogation_Position=749; Antisense;"
 [7] "probe:HG-U133_Plus_2:1555822_at:535:389; Interrogation_Position=780; Antisense;" 
 [8] "probe:HG-U133_Plus_2:1555822_at:271:643; Interrogation_Position=887; Antisense;" 
 [9] "probe:HG-U133_Plus_2:1555822_at:429:853; Interrogation_Position=901; Antisense;" 
[10] "probe:HG-U133_Plus_2:1555822_at:994:67; Interrogation_Position=929; Antisense;"  

unlist(strsplit(probes[1], ":"))[3]
[1] "1555822_at"
```

可以看到 targets 中基因 ID 和转录本 ID，probes 中为探针 id，知道了这个就可以直接用循环来提取信息了：

```R
probe2geneANDtranscripts <- function(probe, target){
	transcripts <- c()
	genes <- c()
	probeID <- c()
  
	for(i in 1:length(target)){
    probeID[i] <- unlist(strsplit(probes[i], ":"))[3]
    genes[i] <- unlist(strsplit(target[i], "\\|"))[2]
    transcripts[i] <- unlist(strsplit(target[i], "\\|"))[1]
	}
	
	mapDF <- data.frame(probeID = probeID,
                      gene = genes,
                      transcript = transcripts)
  	return(mapDF)
}

mapDF <- probe2geneANDtranscripts(probes, targets)

dim(mapDF)
[1] 119071      3

mapDF[1:10,]
      probeID              gene        transcript
1  1555822_at ENSG00000237613.2 ENST00000417324.1
2  1555822_at ENSG00000237613.2 ENST00000417324.1
3  1555822_at ENSG00000237613.2 ENST00000417324.1
4  1555822_at ENSG00000237613.2 ENST00000417324.1
5  1555822_at ENSG00000237613.2 ENST00000417324.1
6  1555822_at ENSG00000237613.2 ENST00000417324.1
7  1555822_at ENSG00000237613.2 ENST00000417324.1
8  1555822_at ENSG00000237613.2 ENST00000417324.1
9  1555822_at ENSG00000237613.2 ENST00000417324.1
10 1555822_at ENSG00000237613.2 ENST00000417324.1
```

(这里这个循环和重复代码现在来看完全是可以避免的，但是我也懒得改了...)

这样就得到**基本**的仅含lncRNA 的探针 - 基因数据框了。

后续还要对数据框进行去重合并等操作，不再赘述。

## 总结

这个方法其实我感觉也不是那么特别靠谱，SeqMap 本身也是好多年都不更新的工具了。但是好像挺多文献里就是用的这种办法，我只是简单重复试一试。仅供参考吧。