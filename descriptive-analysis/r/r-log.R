#!/usr/bin/Rscript
args        <- commandArgs(trailingOnly = TRUE)
srcFile     <- args[1]
outFileName <- paste0(basename(args[1]),".log")
outFile     <- file(outFileName)

sink(outFile)
sink(outFile, type="message")
source(srcFile, echo=TRUE, max.deparse.length=10000, keep.source=TRUE)
sink()
sink(type="message")
