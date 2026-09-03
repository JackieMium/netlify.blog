---
title: "R snippets for a Seurat-based pipeline"
slug: r-seurat-snippets
date: 2026-06-1T20:31:42-06:00
lastmod: 2026-06-19T22:31:42-06:00
draft: false
author: "Jackie"
toc: true
autoCollapseToc: true
postMetaInFooter: false
hiddenFromHomePage: true
unlisted: true
contentCopyright: true
reward: false
contentCopyright: "CC BY-NC-SA 4.0"
---

## Add QC metrics and then plot

```
seurat_obj <- PercentageFeatureSet(seurat_obj, '^MT\\-', col.name = 'pct_mito')
seurat_obj <- PercentageFeatureSet(seurat_obj, 'RP[SL]', col.name = 'pct_ribo')
seurat_obj <- PercentageFeatureSet(seurat_obj, 'HB[AB]', col.name = 'pct_hemo')
seurat_obj = PercentageFeatureSet(seurat_obj, '^Gm|Rik$|^A[CL][[:digit:]]', col.name = 'pct_pred')
seurat_obj$log10GenesPerUMI <- log10(seurat_obj$nFeature_RNA) / log10(seurat_obj$nCount_RNA)

VlnPlot(seurat_obj, group.by = 'orig.ident', 
        ncol = 4, pt.size = 0,
        features = c('nCount_RNA', 'nFeature_RNA', 'pct_mito', 'pct_pred',
                      'pct_ribo', 'pct_hemo', 'log10GenesPerUMI'), 
        raster = FALSE) &
  theme(axis.title.x = element_blank(), axis.text.x.bottom = element_text(size = 6))
```


## Another way to plot QC metrics

```
par(mfrow = c(2,2), mar = c(5, 4, 1, 1), bty = "n")
smoothScatter(log10(seurat_obj$nCount_RNA), log10(seurat_obj$nFeature_RNA),
              xlab = "log10(Library sizes)", ylab = "log10(# of expressed genes)",
              nrpoints = 500, cex = 0.5)
smoothScatter(log10(seurat_obj$nCount_RNA), seurat_obj$pct_ribo,
              xlab = "log10(Library sizes)", ylab = "Ribosome prop. (%)",
              nrpoints = 500, cex = 0.5)
abline(h = 10, lty = 1)

smoothScatter(log10(seurat_obj$nCount_RNA), seurat_obj$pct_mito,
              xlab = "log10(Library sizes)", ylab = "Mitochondrial prop. (%)",
              nrpoints = 500, cex = 0.5)
abline(h = 5, lty = 1)

smoothScatter(seurat_obj$pct_ribo, seurat_obj$pct_mito,
              xlab = "Ribosome prop. (%)", ylab = "Mitochondrial prop. (%)",
              nrpoints = 500, cex = 0.5)
abline(h = 5, lty = 1)
abline(v = 10, lty = 1)
```

## Tricks to really DietSeurat

```
seurat_obj@assays$RNA@layers$data <- NULL
seurat_obj@assays$RNA@layers$scale.data <- NULL
seurat_obj@assays$RNA@meta.data[, grep('vf|var|vst', colnames(seurat_obj@assays$RNA@meta.data))] <- NULL

seurat_obj@assays$integrated <- NULL
seurat_obj@assays$mnn.reconstructed <- NULL
```

## Convert between Seurat v3 and v5 object

```
# convert a v5 assay to a v3 assay
seurat_obj[['RNA3']] <- as(object = seurat_obj[['RNA']], Class = 'Assay')

# convert a v3 assay to a v5 assay
seurat_obj[['RNA5']] <- as(object = seurat_obj[['RNA3']], Class = 'Assay5')
```

## Import another UMAP into a Seurat Object

```
umap <- read.table(file_umap_coords)  |> as.matrix()
# make sure the new coords matrix has the same cell barcodes
identical(rownames(umap), colnames(seurat_obj))

seurat_obj[['umap_new']] <- CreateDimReducObject(
    embeddings = umap,
    key = 'umap_',
    global = TRUE,
    assay = 'RNA'
)
```

## Seurat quick pre-processing

```
seurat_obj[['RNA']] <- split(seurat_obj[['RNA']], f = seurat_obj$orig.ident)
seurat_obj <- seurat_obj |> 
    NormalizeData(verbose = FALSE) |>
    FindVariableFeatures(verbose = FALSE) |> 
    ScaleData(verbose = FALSE) |> 
    RunPCA(verbose = FALSE)

seurat_obj <- IntegrateLayers(
  object = seurat_obj, method = HarmonyIntegration,
  orig.reduction = 'pca', new.reduction = 'harmony',
  verbose = FALSE
)
```

## Highlight a subset of cells in a Seurat Object

```
scCustomize::Cell_Highlight_Plot(seurat_obj, highlight_color = 'orange', cells_highlight = list(
    Cells = colnames(seurat_obj)[ seurat_obj$cHarmony %in% c(20) ]
)) & NoAxes()

scCustomize::Cell_Highlight_Plot(seurat_obj, highlight_color = 'firebrick1', cells_highlight = list(
    Cells = colnames(seurat_obj)[ seurat_obj$pct_mito > 6 ]
)) & NoAxes()
```


## Get a gene list from MSigDB

```r
getGSEAGeneList <- function(name = 'HALLMARK_OXIDATIVE_PHOSPHORYLATION', sp = 'Human') {
    url = paste0('https://www.gsea-msigdb.org/gsea/msigdb/', sp, '/download_geneset.jsp?geneSetName=', name, '&fileType=gmt')
    brk = strsplit(name, '\\_') |> sapply(stringr::str_to_title)
    brk = brk[-1]
    name2 = paste(brk, collapse = '')
    gene = invisible(gson::read.gmt(url)$gene)
    # TODO
    # this manual conversion is NEITHER correct NOR necessary
    # and should be improved
    if (sp %in% c('hs', 'h', 'human', 'Human')) {
        gene = gene |> toupper() 
    } else if (sp %in% c('mm', 'm', 'mouse', 'Mouse')) gene  = gene |> stringr::str_to_title()
      else { stop('Wrong species! Please check!') }
    lst = list(l = gene)
    names(lst) = name2
    return(lst) 
}
```

## A refined Seurat DotPlot

```
DotPlot(seurat_obj, group.by = 'cHarmony', features = c('Gapdh')) &
    RotatedAxis()  &
    scale_color_gradientn(colours = c('#f7fbff', '#6baed6', '#08306b')) &
    scale_size(range = c(0, 6)) &
    theme(axis.title = element_blank(),
          axis.line.x = element_blank(), 
          axis.line.y = element_blank(),
          axis.ticks = element_line(linewidth = 1/4),
          panel.border = element_rect(linewidth = 1/4, color = "black", fill = NA),
          axis.text.y = element_text(size = 16),
          axis.text.x = element_text(angle = 90, size = 6, 
                                     vjust = 1/2, hjust = 1, colour = 'black')) &
    guides(y.sec = guide_axis_label_trans(~paste0(levels(seurat_obj$cHarmony)))) &
    guides(color = guide_colorbar(title = 'Avg\nExpression', barwidth = 1, barheight = 5), 
           size = guide_legend(title = 'Pct\nExpression')) &
    NoLegend()
```


