# Script that computes the ratio of defects that the best mlfl and sbfl
# techniques localize in the top-5, top-10, and top-200 of the suspiciousness ranking.
#
# usage: Rscript top-n.R <data_file_real_exploration> <out_dir>
#

# Read file name of the data file and the output directory
args <- commandArgs(trailingOnly = TRUE)

# Check number of arguments
if (length(args)!=2) {
  stop("usage: Rscript top-n.R <data_file> <out_dir>")
}

data_file <- args[1]
out_dir <- args[2]

source("/home/nicolas/GitRepo/jaguar-data-flow-experiments/scripts/score-ranking/result-analysis/util.R")
library(ggplot2)

# Read data file and add two columns
df <- readCsv(data_file)

df$Scheme <- getScoringSchemes(df)

# Show top-n rankings for all existing techniques
flts <- c("Ochiai", "Tarantula", "Neural Network")
df <- df[df$FLT %in% flts,]

# TODO: Fix ScoringScheme for mlfl family
df$ScoringScheme[df$Family%like%"mlfl"] <- "first"

rank <- rankTopN(df)

num_real_bugs <- length(unique(df[,ID]))

################################################################################
# TODO: Use other schemes 
# sorted_first <- rank[rank$ScoringScheme=="first",]$FLT
# sink(paste(out_dir, "top-n.tex", sep="/"))
# for (flt in sorted_first) {
#     cat(sprintf("%20s", unique(df[df$FLT==flt,]$TechniqueMacro)))
#     for (scheme in c("first", "last", "median")) {
#         mask <- df$ScoringScheme==scheme & df$FLT==flt
#         top5   <- nrow(df[mask & df$ScoreAbs<=5,])/num_real_bugs*100
#         top10  <- nrow(df[mask & df$ScoreAbs<=10,])/num_real_bugs*100
#         top200 <- nrow(df[mask & df$ScoreAbs<=200,])/num_real_bugs*100
#         cat(" & ")
#         cat(round(top5, digits=0), "\\%", sep="")
#         cat(" & ")
#         cat(round(top10, digits=0), "\\%", sep="")
#         cat(" & ")
#         cat(round(top200, digits=0), "\\%", sep="")
#     }
#     cat("\\\\ \n")
# }
# sink()

################################################################################
# TODO: Use other schemes 
#for (scheme in c("first", "last", "median")) {
for (scheme in c("first")) {
    sink(paste(out_dir, "/", "top-n-", initialCap(scheme), ".tex", sep=""))
    filtered <- rank[rank$ScoringScheme==scheme, c("FLT", "Family")]
    for (row in 1:nrow(filtered)) {
        flt <- filtered[row, "FLT"]
        family <- filtered[row, "Family"]
      
        mask <- df$ScoringScheme==scheme & df$FLT==flt & df$Family==family
        top5   <- nrow(df[mask & df$ScoreAbs<=5,])/num_real_bugs*100
        top10  <- nrow(df[mask & df$ScoreAbs<=10,])/num_real_bugs*100
        top200 <- nrow(df[mask & df$ScoreAbs<=200,])/num_real_bugs*100
        
        cat(flt, "\\%", sep="")
        cat(" & ")
        cat(levels(family)[family], "\\%", sep="")
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
