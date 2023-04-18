# Script that replicates prior studies by comparing existing techniques on real
# faults.
#
# usage: Rscript replication.R <data_file> <out_dir>
#

# Read file name of the data file and the output directory
args <- commandArgs(trailingOnly = TRUE)

# Check number of arguments
if (length(args)!=2) {
  stop("usage: Rscript replication.R <data_file> <out_dir>")
}

data_file <- args[1]
out_dir <- args[2]

source("/home/nicolas/GitRepo/jaguar-data-flow-experiments/scripts/score-ranking/result-analysis/util.R")
library(ggplot2)
library(extrafont)

# Read data file and add two columns
df <- readCsv(data_file, getReal=TRUE, getArtificial=TRUE)
df$FaultType <- "Real faults"
df$FLT <- prettifyTechniqueName(df$Technique)

# Filter rankings only for desired techniques
flts <- c("Ochiai", "Tarantula", "Neural Network")
df <- df[df$FLT %in% flts,]

metric <- "ScoreWRTLoadedClasses"

################################################################################
# Generate plots
#
theme <- theme(axis.title=element_text(size=34),
      legend.text=element_text(size=34),
      legend.title=element_text(size=34),
      legend.position="top",
      legend.box="horizontal",
      legend.margin=unit(12, "pt"),
      axis.text.y = element_text(size=30),
      axis.text.x = element_text(size=30),
      strip.text.x = element_text(size=34, face="bold"),
      strip.text.y = element_text(size=34, face="bold"))

guides <- guides(col = guide_legend(override.aes = list(size = 5), direction="horizontal", ncol=8, byrow=TRUE))

options(scipen=10000)

# Plot the distribution of exam scores (log scale) -- all projects
pdfname <- paste(out_dir, "distributions_ratio.pdf", sep="/")
pdf(file=pdfname, pointsize=20, family="serif", width=30, height=7)
ggplot(df, aes(x=ScoreWRTLoadedClasses, color=FLT, linetype=Family)) + geom_line(stat="density", size=1.5) +
scale_linetype_manual(name="     Family: ", values=c("solid", "twodash", "dotted", "dashed")) +
theme_bw() +
facet_grid(~FaultType) + labs(x="EXAM score (log scale)", y="Density", color="FL technique: ") +
theme + guides + scale_x_log10(breaks = c(1,0.1,0.01,0.001,0.0001))
dev.off()
embed_fonts(pdfname, options="-dSubsetFonts=true -dEmbedAllFonts=true -dCompatibilityLevel=1.4 -dPDFSETTINGS=/prepress -dMaxSubsetPct=100")

# Plot the distribution of exam scores (log scale) -- per project
pdfname <- paste(out_dir, "distributions_ratio_per_project.pdf", sep="/")
pdf(file=pdfname, pointsize=20, family="serif", width=30, height=22)
ggplot(df, aes(x=ScoreWRTLoadedClasses, color=FLT, linetype=Family)) + geom_line(stat="density", size=1.5) +
scale_linetype_manual(name="     Family: ", values=c("solid", "twodash", "dotted", "dashed")) +
theme_bw() +
facet_grid(Project ~FaultType, scales="free") + labs(x="EXAM score (log scale)", y="Density", color="FL technique: ") +
theme + guides + scale_x_log10(breaks = c(1,0.1,0.01,0.001,0.0001))
dev.off()
embed_fonts(pdfname, options="-dSubsetFonts=true -dEmbedAllFonts=true -dCompatibilityLevel=1.4 -dPDFSETTINGS=/prepress -dMaxSubsetPct=100")

# Plot the distribution of absolute scores (log scale) -- all projects
pdfname <- paste(out_dir, "distributions_abs.pdf", sep="/")
pdf(file=pdfname, pointsize=20, family="serif", width=30, height=7)
ggplot(df, aes(x=ScoreAbs, color=FLT, linetype=Family)) + geom_line(stat="density", size=1.5) +
scale_linetype_manual(name="     Family: ", values=c("solid", "twodash", "dotted", "dashed")) +
theme_bw() +
facet_grid(~FaultType) + labs(x="Absolute score (log scale)", y="Density", color="FL technique: ") +
theme + guides + scale_x_log10(breaks = c(1,10,100,1000,10000))
dev.off()
embed_fonts(pdfname, options="-dSubsetFonts=true -dEmbedAllFonts=true -dCompatibilityLevel=1.4 -dPDFSETTINGS=/prepress -dMaxSubsetPct=100")

# Plot the distribution of absolute scores (log scale) -- per project
pdfname <- paste(out_dir, "distributions_abs_per_project.pdf", sep="/")
pdf(file=pdfname, pointsize=20, family="serif", width=30, height=22)
ggplot(df, aes(x=ScoreAbs, color=FLT, linetype=Family)) + geom_line(stat="density", size=1.5) +
scale_linetype_manual(name="     Family: ", values=c("solid", "twodash", "dotted", "dashed")) +
theme_bw() +
facet_grid(Project~FaultType, scales="free") + labs(x="Absolute score (log scale)", y="Density", color="FL technique: ") +
theme + guides + scale_x_log10(breaks = c(1,10,100,1000,10000))
dev.off()
embed_fonts(pdfname, options="-dSubsetFonts=true -dEmbedAllFonts=true -dCompatibilityLevel=1.4 -dPDFSETTINGS=/prepress -dMaxSubsetPct=100")


################################################################################
# Generate table
#
# Cast all scoring metrics to wide format at once
wide <- dcast(setDT(df), "ID ~ Technique", value.var=scoring_metrics)

#
# Comparisons
#
comparisons <- data.frame(
  Better=   c("ochiai",    "neural_network", "neural_network"),
  Worse=    c("tarantula", "ochiai",  "tarantula"))

# Output file for the generated table
sink(paste(out_dir, "table_replication.tex", sep="/"))

for (i in 1:length(comparisons$Better)) {
  prior_winner = comparisons$Better[i]
  prior_loser  = comparisons$Worse[i]
  
  # Print the compared techniques
  cat(sprintf("%12s > %12s",
              prettifyTechniqueName(prior_winner),
              prettifyTechniqueName(prior_loser)))
  
  # Perform the same test for real faults
  flt1_score <- paste(metric, prior_winner, sep="_")
  flt2_score <- paste(metric, prior_loser, sep="_")
    
  # Perform a paired, two-tailed t-test
  t_test <- t.test((wide[[flt1_score]]), (wide[[flt2_score]]), paired=TRUE)
  p      <- t_test$p.value
  # Determine the confidence interval (lower, upper)
  est    <- t_test$estimate
  lwr    <- t_test$conf.int[1]
  upr    <- t_test$conf.int[2]
  # Compute Cohen's d effect size
  d      <- cohen.d((wide[[flt1_score]]), (wide[[flt2_score]]), paired=TRUE)$estimate
    
  # Formatted text for: do we agree, based on p value and effect size?
  sig_text    <- significanceText(p, est)
  effect_text <- dText(round(d, 2))
  
  # Format the output
  cat(sprintf("& %3s & %s & %s", sig_text, effect_text, typesetCI(lwr, upr)))
  
  # Determine simple counts: how often is one techqniue better than the other?
  better <- sum(wide[[flt1_score]] < wide[[flt2_score]])
  worse  <- sum(wide[[flt1_score]] > wide[[flt2_score]])
  equal  <- sum(wide[[flt1_score]] == wide[[flt2_score]])
  
  # Format the output
  cat(sprintf("& (%d--%d--%d)", better, equal, worse))
  
  # Just to visually inspect the distribution of the exam score differences
  #plot(density(((wide[[flt1_score]]) - (wide[[flt2_score]]))),
  #     main=sprintf("ScoreRatio difference: %s vs. %s (%s)", prior_winner, prior_loser, "real faults"))
  
  cat("\\\\ \n")
}
sink()