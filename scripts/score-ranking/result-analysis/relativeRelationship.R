# Script that computes the Spearman's rho correlation coefficient and associated
# p-value for the following ranking metrics in real faults:
# - EXAM score
# - Tournament ranking (EXAM score)
# - FLT rank
# - Top-n rank
#

# Read file names of the data files and the output directory
args <- commandArgs(trailingOnly = TRUE)
if (length(args)!=2) {
    stop("usage: Rscript relativeRelationship.R <data_file> <out_dir>")
}

data_file <- args[1]
out_dir <- args[2]

source("/home/nicolas/GitRepo/jaguar-data-flow-experiments/scripts/score-ranking/result-analysis/util.R")

df <- readCsv(data_file)

df$Technique <- getTechniques(df)

tournamentPointsMean <- function(wide, techniques, metric) {
  result <- rep(0, length(techniques))
  for (i in 1:(length(techniques)-1)) {
    for (j in (i+1):length(techniques)) {
      flt1_col <- paste(metric, techniques[i], sep="_")
      flt2_col <- paste(metric, techniques[j], sep="_")
      # No need to run the t-test if the samples are identical
      if (identical(wide[[flt1_col]], wide[[flt2_col]])) {
        p   <- 1;
        est <- 0;
      } else {
        t_test <- t.test(wide[[flt1_col]], wide[[flt2_col]], paired=TRUE)
        p      <- t_test$p.value
        est    <- t_test$estimate
      }
      # TODO: Check whether we need a correction for multiple comparisons here
      if (p < 0.05) {
        winner = if (est < 0) i else j
        result[winner] = result[winner]+1
      }
    }
  }
  return(result)
}

generateTable <- function(name, header, techniques, valuesCF, valuesDF, suffix = "", decreasing = FALSE, digits = 4, integer=FALSE) {
    if(nchar(suffix) > 0) {
        name = paste(name, suffix, sep="_")
    }
    print(name)
    TABLE = paste(out_dir, "/table_", name, ".tex", sep="")
    unlink(TABLE)
    sink(TABLE, append=TRUE, split=FALSE)
    cat("\\begin{tabular}{lC{20mm}@{\\hspace{2em}}lC{20mm}}\\toprule", "\n")
    cat("\\multicolumn{2}{c}{\\textbf{Data Flow}} & \\multicolumn{2}{c}{\\textbf{Control Flow}} \\\\", "\n")
    cat("\\cmidrule(r){1-2} \n")
    cat("\\cmidrule{3-4} \n")
    cat("Technique & ", header, " & Technique & ", header, "\\\\ \n")
    cat("\\midrule","\n")
    controlFlowSorted = sort.int(valuesCF, index.return=TRUE, decreasing=decreasing)$ix
    dataFlowSorted = sort.int(valuesDF, index.return=TRUE, decreasing=decreasing)$ix
    format_char = ifelse(integer, "d", "f")
    for (i in 1:length(techniques)) {
        indexCF = controlFlowSorted[i]
        indexDF = dataFlowSorted[i]
        cat(
            prettifyTechniqueName(techniques[indexDF]), " & ",
            formatC(valuesDF[indexDF], digits=digits, format=format_char), " & ",
            prettifyTechniqueName(techniques[indexCF]), " & ",
            formatC(valuesCF[indexCF], digits=digits, format=format_char),
            "\\\\ \n")
    }
    cat("\\bottomrule","\n")
    cat("\\end{tabular}","\n")
    sink()
}

generateTableUnified <- function(name, header, techniques, values, suffix = "", decreasing = FALSE, digits = 4, integer=FALSE) {
  if(nchar(suffix) > 0) {
    name = paste(name, suffix, sep="_")
  }
  print(name)
  TABLE = paste(out_dir, "/tableUnified_", name, ".tex", sep="")
  unlink(TABLE)
  sink(TABLE, append=TRUE, split=FALSE)
  cat("\\begin{tabular}{p{50mm}@{\\hspace{2em}}p{20mm}}\\toprule", "\n")
  cat("\\multicolumn{2}{c}{\\textbf{D4J Faults}} \\\\", "\n")
  cat("\\cmidrule(r){1-2} \n")
  cat("Technique & ", header, "\\\\ \n")
  cat("\\midrule","\n")
  sorted = sort.int(values, index.return=TRUE, decreasing=decreasing)$ix
  format_char = ifelse(integer, "d", "f")
  for (i in 1:length(techniques)) {
    index = sorted[i]
    cat(
      techniques[index], " & ",
      formatC(values[index], digits=digits, format=format_char),
      "\\\\ \n")
  }
  cat("\\bottomrule","\n")
  cat("\\end{tabular}","\n")
  sink()
}

# The fault categories -- suffix for file names
fault_type_suffix <- "all_faults"

# Cast data to wide format
wide <- dcast(setDT(df), "ID ~ Family + Technique", value.var=scoring_metrics)

control_flow_points_mean = tournamentPointsMean(wide, control_flow_techniques, "ScoreWRTLoadedClasses")
control_flow_points_rank = tournamentPointsMean(wide, control_flow_techniques, "RANK")
data_flow_points_mean = tournamentPointsMean(wide, data_flow_techniques, "ScoreWRTLoadedClasses")
data_flow_points_rank = tournamentPointsMean(wide, data_flow_techniques, "RANK")
all_points_mean = tournamentPointsMean(wide, all_techniques, "ScoreWRTLoadedClasses")
all_points_rank = tournamentPointsMean(wide, all_techniques, "RANK")

# Compute all relevant rankings
technique_summaries <- data.frame(
    Technique=techniques,
    Points=control_flow_points_mean,
    Mean=rep(0, length(techniques)),
    RankMean=rep(0, length(techniques)),
    TopN=rep(0, length(techniques))
)

for (i in 1:length(techniques)) {
    control_flow <- df[(df$Technique==techniques[i]) & (!df$Family%like%"dua"),]
    technique_summaries$Mean[i] = mean(control_flow$ScoreWRTLoadedClasses)
    technique_summaries$RankMean[i] = mean(control_flow$RANK)
    num_cf <- length(unique(control_flow$ID))
    technique_summaries$TopN[i] <- nrow(control_flow[control_flow$RANK<=5,])/num_cf
}
    
technique_summaries_df <- data.frame(
    Technique=techniques,
    Points=data_flow_points_mean,
    Mean=rep(0, length(techniques)),
    RankMean=rep(0, length(techniques)),
    TopN=rep(0, length(techniques))
)
    
for (i in 1:length(techniques)) {
    data_flow <- df[(df$Technique==techniques[i]) & (df$Family%like%"dua"),]
    technique_summaries_df$Mean[i] = mean(data_flow$ScoreWRTLoadedClasses)
    technique_summaries_df$RankMean[i] = mean(data_flow$RANK)
    num_df <- length(unique(data_flow$ID))
    technique_summaries_df$TopN[i] <- nrow(data_flow[data_flow$RANK<=5,])/num_df
}

technique_summaries_all <- data.frame(
  Technique=all_techniques,
  Points=all_points_mean,
  Mean=rep(0, length(all_techniques)),
  RankMean=rep(0, length(all_techniques)),
  TopN=rep(0, length(all_techniques))
)

for (i in 1:length(all_techniques)) {
  technique_arr <- strsplit(all_techniques[i], "_")
  technique_data <- df[(df$Technique==technique_arr[[1]][2]) & (df$Family==technique_arr[[1]][1]),]
  technique_summaries_all$Mean[i] = mean(technique_data$ScoreWRTLoadedClasses)
  technique_summaries_all$RankMean[i] = mean(technique_data$RANK)
  num_df <- length(unique(technique_data$ID))
  technique_summaries_all$TopN[i] <- nrow(technique_data[technique_data$RANK<=5,])/num_df
}

generateTable("TournamentScore", "\\# Worse",  techniques, control_flow_points_mean, data_flow_points_mean, suffix = fault_type_suffix, decreasing = TRUE, integer = TRUE)
generateTable("TournamentRank", "\\# Worse",  techniques, control_flow_points_rank, data_flow_points_rank, suffix = fault_type_suffix, decreasing = TRUE, integer = TRUE)

generateTable("ScoreMean", "Exam Score",  techniques, technique_summaries$Mean, technique_summaries_df$Mean, suffix = fault_type_suffix, decreasing = FALSE)
generateTable("RankMean", "Flt Rank",  techniques, technique_summaries$RankMean, technique_summaries_df$RankMean, digits=2, suffix = fault_type_suffix, decreasing = FALSE)

generateTableUnified("TournamentScore", "\\# Worse",  all_techniques, all_points_mean, suffix = fault_type_suffix, decreasing = TRUE, integer = TRUE)
generateTableUnified("TournamentRank", "\\# Worse",  all_techniques, all_points_rank, suffix = fault_type_suffix, decreasing = TRUE, integer = TRUE)

generateTableUnified("ScoreMean", "Exam Score",  all_techniques, technique_summaries_all$Mean, suffix = fault_type_suffix, decreasing = FALSE)
generateTableUnified("RankMean", "Flt Rank",  all_techniques, technique_summaries_all$RankMean, digits=2, suffix = fault_type_suffix, decreasing = FALSE)

