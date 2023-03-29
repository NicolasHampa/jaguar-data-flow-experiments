# Script that computes the ratio of defects that the best mbfl, sbfl, and hybrid
# techniques localize in the top-5, top-10, and top-200 of the suspiciousness ranking.
#
# usage: Rscript top-n.R <data_file_real_exploration> <out_dir>
#

# Read file name of the data file and the output directory
#data_file <- "/home/nicolas/GitRepo/fault-localization-data/data/scores_real_exploration.csv"
data_file <- "/home/nicolas/GitRepo/scores-gzoltar-ochiai-tarantula.csv"
out_dir <- "/home/nicolas/GitRepo/"

source("/home/nicolas/GitRepo/jaguar-data-flow-experiments/scripts/score-ranking/result-analysis/util.R")
library(ggplot2)

# Read data file and add two columns
df <- readCsv(data_file)

df$Real <- getReal(df)
#df$FaultType <- ifelse(df$Real, "Real faults", "Artificial faults")
#df$Scheme <- getScoringSchemes(df)
#df$Type   <- getType(df$Technique)

# New (hybrid) techniques:
#
# "MCBFL", "MCBFL-hybrid-failover", "MCBFL-hybrid-avg", "MCBFL-hybrid-max"
# "MRSBFL", "MRSBFL-hybrid-failover", "MRSBFL-hybrid-avg", "MRSBFL-hybrid-max", "MCBFL-hybrid-avg"

# Show top-n rankings for all existing techniques
flts <- c("DStar", "Ochiai", "Jaccard", "Barinel", "Tarantula", "Op2", "Neural Network")
df <- df[df$FLT %in% flts,]

# ONLY FOR MLFL!!
df$ScoringScheme <- "first"

rank <- rankTopN(df)
for (scheme in c("first", "last", "median")) {
    sorted <- rank[rank$ScoringScheme==scheme & rank$Real==T,]$FLT
    cat("FLTs sorted (", scheme, "): ", sorted, "\n", file=stderr())
}

num_real_bugs <- length(unique(df[df$Real,ID]))

################################################################################
sorted_first <- rank[rank$ScoringScheme=="first" & rank$Real==T,]$FLT
sink(paste(out_dir, "top-n.tex", sep="/"))
for (flt in sorted_first) {
    cat(sprintf("%20s", unique(df[df$FLT==flt,]$TechniqueMacro)))
    for (scheme in c("first", "last", "median")) {
        mask <- df$ScoringScheme==scheme & df$Real & df$FLT==flt
        top5   <- nrow(df[mask & df$ScoreAbs<=5,])/num_real_bugs*100
        top10  <- nrow(df[mask & df$ScoreAbs<=10,])/num_real_bugs*100
        top200 <- nrow(df[mask & df$ScoreAbs<=200,])/num_real_bugs*100
        cat(" & ")
        cat(round(top5, digits=0), "\\%", sep="")
        cat(" & ")
        cat(round(top10, digits=0), "\\%", sep="")
        cat(" & ")
        cat(round(top200, digits=0), "\\%", sep="")
    }
    cat("\\\\ \n")
}
sink()

################################################################################
#for (scheme in c("first", "last", "median")) {
for (scheme in c("first")) {
    sink(paste(out_dir, "/", "top-n", initialCap(scheme), ".tex", sep=""))
    sorted <- rank[rank$ScoringScheme==scheme & rank$Real==T,]$FLT
    for (flt in sorted) {
        cat(sprintf("%20s", unique(df[df$FLT==flt,]$TechniqueMacro)))
        mask <- df$ScoringScheme==scheme & df$Real & df$FLT==flt
        #top5   <- nrow(df[mask & df$ScoreAbs<=5,])/num_real_bugs*100
        #top10  <- nrow(df[mask & df$ScoreAbs<=10,])/num_real_bugs*100
        #top200 <- nrow(df[mask & df$ScoreAbs<=200,])/num_real_bugs*100
        top5   <- nrow(df[mask & df$ScoreAbs<=5,])
        top10  <- nrow(df[mask & df$ScoreAbs<=10,])
        top200 <- nrow(df[mask & df$ScoreAbs<=200,])
        cat(" & ")
        cat(round(top5, digits=0), "\\%", sep="")
        cat(" & ")
        cat(round(top10, digits=0), "\\%", sep="")
        cat(" & ")
        cat(round(top200, digits=0), "\\%", sep="")
        cat("\\\\ \n")
    }
    sink()
}
