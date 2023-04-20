# Script that generates LaTex tables for the regression analysis and anova.
#
# usage: Rscript anova.R <data_file> <out_dir>
#

# Read file name of the data file and the output directory
args <- commandArgs(trailingOnly = TRUE)
data_file <- args[1]
out_dir <- args[2]

# Check number of arguments
if (length(args)!=2) {
    stop("usage: Rscript anova.R <data_file> <out_dir>")
}

# Collection of helper functions
source("/home/nicolas/GitRepo/jaguar-data-flow-experiments/scripts/score-ranking/result-analysis/util.R")

data <- readCsv(data_file)
both <- subset(data, (Family=="sbfl"|Family=="mlfl") & ScoringScheme!="mean")
both$Family <- droplevels(both$Family)
both$Comb <- as.factor(paste(both$Family))

sbfl <- subset(both, Family=="sbfl")
mlfl <- subset(both, Family=="mlfl")

both_dua <- subset(data, (Family=="sbfl-dua"|Family=="mlfl-dua") & ScoringScheme!="mean")
both_dua$Family <- droplevels(both_dua$Family)
both_dua$Comb <- as.factor(paste(both_dua$Family))

sbfl_dua <- subset(both_dua, Family=="sbfl-dua")
mlfl_dua <- subset(both_dua, Family=="mlfl-dua")

isSigP <- function(p) {
    if(is.na(p)) {
        return("NA")
    } else if(p<0.01) {
        return(paste("\\sigStrong{", "<", 0.01, "}", sep=""))
    } else if(p<0.05) {
        return(paste("\\sigModerate{", "<", 0.05, "}", sep=""))
    } else {
        return(sprintf("\\insig{%.2f}", p))
    }
}

doAnova <- function(family, df, formula, factors) {
  # Perform anova and a post-hoc test for the factor "Formula"
  aov <- aov(formula, data=df)
  
  # Obtain the anova table
  anova <- anova(aov)
  
  # Write the anova table    
  sink(paste(out_dir, paste(family, "anova.tex", sep="_"), sep="/"))
  printAnovaTable(anova, factors)
  sink()
}

#
# Helper function to print anova table in LaTex format
#
printAnovaTable <- function(anova, factors, alpha=0.05) {
  df <- data.frame(factors, anova$Df, anova$"Sum Sq", anova$"F value", anova$"Pr(>F)")
  
  colnames(df) <- c("Factor", "Df", "Sum Sq", "F", "p")
  # Sort factors by sum of squares and remove 'Residuals' row
  df <- df[df$Factor != 'Residuals',]
  df <- df[with(df, order(-df$"Sum Sq")),]
  
  prettyP <- function(p) {prettifyP(p, alpha)}
  roundF  <- function(f) {if(is.na(f)) return("NA") else return(round(f))}
  roundSq <- function(sq) {return(format(sq, digits=3, scientific=FALSE))}
  
  df$p  <- lapply(df$p, prettyP)
  df$F  <- lapply(df$F, roundF)
  df$"Sum Sq"  <- lapply(df$"Sum Sq", roundSq)
  
  rows <- gsub("(\\DebuggingScenario.*)", "\\1\\\\midrule\n",
               gsub("NA", "\\\\defNone", paste(paste(df$Factor,df$Df,df$"Sum Sq",df$F,df$p,sep=" & "), "\\\\ \n")))
  cat(rows)
}

# Write file that defines the macros for the R^2 values
#sink(paste(out_dir, "anova_R2.tex", sep="/"), append=FALSE)

#TODO: Adjust Anova only for SBFL
# facSbfl  <- c("Defect", "Formula", "Total definition", "Residuals")
# formSbfl <- ScoreWRTLoadedClasses ~ ID + FormulaMacro + TotalDefn
# doAnova("sbfl", sbfl, formSbfl, facSbfl)

#TODO: Adjust Anova only for MLFL
# facMlfl  <- c("Defect", "Residuals")
# formMlfl <- ScoreWRTLoadedClasses ~ ID
# doAnova("mlfl", mlfl, formMlfl, facMlfl)

facAll  <- c("Defect", "Family", "Formula", "Total definition", "Residuals")
formAll <- ScoreWRTLoadedClasses ~ ID + Comb + FormulaMacro + TotalDefn
doAnova("sbfl_mlfl", both, formAll, facAll)

# ========================== #

#TODO: Adjust Anova only for SBFL
# facSbfl  <- c("Defect", "Formula", "Total definition", "Residuals")
# formSbfl <- ScoreWRTLoadedClasses ~ ID + FormulaMacro + TotalDefn
# doAnova("sbfl_dua", sbfl_dua, formSbfl, facSbfl)

#TODO: Adjust Anova only for MLFL
# facMlfl  <- c("Defect", "Residuals", "Formula")
# formMlfl <- ScoreWRTLoadedClasses ~ ID + FormulaMacro
# doAnova("mlfl_dua", mlfl_dua, formMlfl, facMlfl)

facAll  <- c("Defect", "Family", "Formula", "Total definition", "Residuals")
formAll <- ScoreWRTLoadedClasses ~ ID + Comb + FormulaMacro + TotalDefn
doAnova("sbfl_mlfl_dua", both_dua, formAll, facAll)

# ========================== #

