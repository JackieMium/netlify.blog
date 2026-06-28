---
title: "R Notes"
slug: general-r-notes
date: 2026-01-22T22:31:42-06:00
lastmod: 2026-01-22T22:31:42-06:00
draft: false
author: "Jackie"
toc: true
description: ""
tags: []
categories: []
comment: false
toc: true
autoCollapseToc: false
postMetaInFooter: false
hiddenFromHomePage: true
unlisted: true
# You can also define another contentCopyright. e.g. contentCopyright: "This is another copyright."
contentCopyright: false
reward: false
---

## JupyterNotebook R startup 

```
cat('\n#########################################\n')
cat(paste0('#### Last run time: ', format(Sys.time(), '%Y-%m-%d %H:%M'), ' ####'))
cat('\n#########################################\n')
cat('\n#############################################################\n')
cat(paste0(R.home(), '\n'))
print(R.version)
cat('#############################################################\n\n')
cat('#############################################################\n')
sessionInfo()
cat('#############################################################\n\n')
```


## JupyterNotebook R snippet for inline figure displaying size

```
base_len <- 6
#options(repr.plot.width = base_len, repr.plot.height = base_len)
#options(repr.function.highlight = TRUE)
mySetFigSize <- function(width = 1, height = 1) {
    options(repr.plot.width = base_len * width, repr.plot.height = base_len * height)
}
mySetFigSize(1, 1)
```

## Setup s project directory

```
prj_home <- '~/Projects'
prj_dir <- 'ProjectName'
setwd(file.path(prj_home, prj_dir))
dir_in <- file.path(getwd(), 'raw_data')
dir_out <- file.path(getwd(), 'res_data')
dir_fig <- file.path(getwd(), 'output_plots')
dir_log <- file.path(getwd(), 'logs')
if(!(dir.exists(dir_in))) { dir.create(dir_in) }
if(!(dir.exists(dir_out))) { dir.create(dir_out) }
if(!(dir.exists(dir_fig))) { dir.create(dir_fig) }
if(!(dir.exists(dir_log))) { dir.create(dir_log) }
```

## Batch loading packages

```
pkgs <- c(
    'ggplot2', 'RColorBrewer',
    'dplyr',
    'repr', 'highr'
)
 
invisible(lapply(pkgs,  \(.) { 
    suppressPackageStartupMessages(library(., character.only = TRUE)))
  }
)
```

## A lightweight and sane ggplot2 theme

```r
theme_barebone <- function(bssz = 18){
    base_size = bssz
    ggthemes::theme_foundation(base_size = bssz) +
    theme(
        plot.background = element_blank(),
        panel.background = element_blank(), 
        panel.border = element_blank(),
        panel.grid = element_blank(), 
        axis.line.x = element_line(colour = 'black', linewidth = 0.5, linetype = 'solid'), 
        axis.line.y = element_line(colour = 'black', linewidth = 0.5, linetype = 'solid'), 
        axis.ticks = element_line(colour = 'black', linewidth = 0.5, linetype = 'solid'),
        axis.ticks.length = unit(2, 'mm'),
        axis.text = element_text(colour = 'black', size = ceiling(base_size * 0.66), face = 'plain'), 
        axis.title = element_text(colour = 'black', size = ceiling(base_size * 0.75), face = 'plain'),
        strip.background = element_blank(), 
        strip.text = element_text(),
        strip.text.x = element_text(colour = 'black', vjust = 0.5, face = 'plain'), 
        strip.text.y = element_text(colour = 'black', angle = -90, face = 'plain'),
        legend.text = element_text(colour = 'black', size = ceiling(base_size * 0.66), face = 'plain'), 
        legend.title = element_text(colour = 'black', size = ceiling(base_size * .8), face = 'plain'),
        legend.position = 'right', 
        legend.key = element_blank(),
        legend.background = element_blank(), 
        legend.box.background = element_blank(),
        #plot.margin = unit(c(1, 1, 1, 0), 'mm'),
        plot.margin = margin(t = 5, r = 2, b = 2, l = 2), 
        plot.title = element_text(colour = 'black', size = ceiling(base_size), face = 'plain'),
        plot.subtitle = element_text(colour = 'black', size = ceiling(base_size * .8))
    )   
}
```

## Pre-process data for heatmap visualization:

  - [SEQanswers: RNA-seq data and HEATMAP](https://www.seqanswers.com/forum/applications-forums/rna-sequencing/52165-rna-seq-data-and-heatmap)
  - [Biostars: heatmap using FPKM values](https://www.biostars.org/p/238128/)
  - [Biostars: which data is more suitable for Heatmap?](https://www.biostars.org/p/385059/)
  - [StatQuest: RPKM, FPKM and TPM, clearly explained](https://statquest.org/rpkm-fpkm-and-tpm-clearly-explained/) 
  - [What the FPKM? A review of RNA-Seq expression units](https://haroldpimentel.wordpress.com/2014/05/08/what-the-fpkm-a-review-rna-seq-expression-units/) and [Gene expression analysis using high-throughput sequencing technologies](https://haroldpimentel.wordpress.com/2014/05/08/what-the-fpkm-a-review-rna-seq-expression-units/)

## ChIP-seq data formats: BigWig, Wig and Bed files

- [Any Method Of Converting Bigwig File Format Into Bed Format?](https://www.biostars.org/p/71692/)


## R/Bioconductor: Genome and Annoation

  - [GenomicFeatures: Obtaining and Utilizing TxDb Objects](https://bioconductor.org/packages/release/bioc/vignettes/GenomicFeatures/inst/doc/GenomicFeatures.html)
  - [ensembldb: Generating and using Ensembl based annotation packages](https://www.bioconductor.org/packages/devel/bioc/vignettes/ensembldb/inst/doc/ensembldb.html)
  - [BSgenome: Software infrastructure for efficient representation of full genomes and their SNPs](https://bioconductor.org/packages/release/bioc/html/BSgenome.html)
  - [org.Mm.eg.db:  Genome wide annotation for Mouse, primarily based on mapping using Entrez Gene identifiers.](https://bioconductor.org/packages/release/data/annotation/html/org.Mm.eg.db.html)
  - [Ensembl: Table of Assemblies](https://useast.ensembl.org/info/website/archives/assembly.html)

- [Biostars: RSEM uses different gene lengths for each sample](https://www.biostars.org/p/9571576/)

- [Bioconductor: Choosing an svalue threshold from apeglm shrunken results in DESeq2](https://support.bioconductor.org/p/9139420/)

- [Biostars: where to find mouse genome GRCm38/mm10 for biomart R](https://www.biostars.org/p/9550266/)

  ```r
  ensembl102 <- useEnsembl(biomart = 'genes',
                           dataset = 'mmusculus_gene_ensembl',
                           version = 102)  # latest mm10
   
  # biomaRt::getLDS
  human = useMart("ensembl", dataset = "hsapiens_gene_ensembl")
  mouse = useMart("ensembl", dataset = "mmusculus_gene_ensembl") 
  getLDS(attributes = c("hgnc_symbol","chromosome_name", "start_position"), 
      filters = "hgnc_symbol", values = "TP53", mart = human, 
      attributesL = c("chromosome_name","start_position"), martL = mouse)
  ```