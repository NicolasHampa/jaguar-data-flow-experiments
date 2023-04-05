#
# Some useful functions and computations used in several scripts
#
# Code conventions:
# - function names are camel case
# - variable names are lower case (potentially using underscores)
# - names of computed/added data frame columns are all caps
#
require(data.table)
require(effsize)

# Levels for all FL technique features and considered scoring schemes
# formulas       <- c("ochiai", "barinel", "muse", "dstar2", "opt2", "tarantula", "jaccard")
formulas       <- c("ochiai", "barinel", "muse", "dstar2", "opt2", "tarantula", "jaccard",
                    "ochiai2", "opt1", "gp02", "gp03", "gp13", "gp19", "anderberg", "dice",
                    "sorensen_dice", "goodman", "qe", "cbi_inc", "cbi_sqrt", "cbi_log",
                    "wong1", "wong2", "wong3", "hamann", "simple_matching", "sokal",
                    "rogers_tanimoto", "hamming", "euclid", "russell_rao", "binary",
                    "scott", "rogot1", "rogot2", "kulczynski1", "kulczynski2", "m1", "m2",
                    "ample", "ample2", "arithmetic_mean", "geometric_mean", "harmonic_mean",
                    "cohen", "fleiss", "braun_banquet", "mountford", "gower", "michael",
                    "pierce", "baroni_urbani_buser", "zoltar", "overlap")
total_defs     <- c("elements", "tests")
hybrid_schemes <- c("mirror", "constant", "numerator")
kill_defs      <- c("passfail", "exact", "type+message", "type", "all", "type+message+location")
agg_defs       <- c("avg", "max")
#scoring_schemes<- c("first", "last", "median")
scoring_schemes<- c("first")
scoring_metrics<- c("ScoreWRTLoadedClasses", "RANK")
agg_functions  <- c("mean")

#
# Read and return data from csv file. Perform the following post-processing steps:
# 1) Remove data rows for real or artificial faults, depending on whether
#    getReal and/or getArtifical is set to TRUE.
# 2) Replace the empty string with "none" for Formula, TotalDefn, KillDefn and AggregationDefn to be consistent
#    with HybridScheme ("none" essentially indicates NA).
# 3) Add a new column "RANK", which gives for each EXAM score the rank among all FL
#    techniques for a given <Project, Bug, ScoringScheme> tuple.
# 4) Add a new column "ID", which gives a unique identifier across all bugs.
#
readCsv <- function(file_name, getReal=TRUE, getArtificial=TRUE) {
    data <- fread(file_name)
    stopifnot(nrow(data) > 0)
    mask <- if(getReal) data$Bug<1000 else FALSE
    mask <- mask | if (getArtificial) data$Bug>1000 else FALSE
    data <- data[mask,]
    data$RealBugId <- as.integer(lapply(data$Bug, getRealBugId))
    # Add sloc information and recover the absolute score
    sloc <- fread("/home/nicolas/GitRepo/jaguar-data-flow-experiments/scripts/score-ranking/result-analysis/sloc.csv")
    data <- merge(data, sloc, by=c("Project", "RealBugId"))
    data$ScoreAbs <- data$Score*data$slocTotal

    # Consistently use "none" as the NA level for all factors
    data[data$Formula   == ""]$Formula   <- "none"
    data[data$TotalDefn == ""]$TotalDefn <- "none"
    data[data$KillDefn  == ""]$KillDefn  <- "none"
    data[data$AggregationDefn == ""]$AggregationDefn <- "none"

    # Assign technique names
    # Use family name by default
    data$Technique <- data$Family
    
    # Existing SBFL techniques
    ochiai              <- data$Family%like%"sbfl" & data$Formula=="ochiai"              & data$TotalDefn=="tests"
    tarantula           <- data$Family%like%"sbfl" & data$Formula=="tarantula"           & data$TotalDefn=="tests"
    
    # Existing MBFL techniques
    metallaxis <- data$Family=="mbfl" & data$Formula=="ochiai"   & data$TotalDefn=="tests"    & data$KillDefn=="exact"    & data$AggregationDefn=="max"
    muse       <- data$Family=="mbfl" & data$Formula=="muse"     & data$TotalDefn=="elements" & data$KillDefn=="passfail" & data$AggregationDefn=="avg"
    
    # Existing MLFL techniques
    neuralnetwork              <- data$Family%like%"mlfl" & data$Formula=="neural-network"
    
    data[ochiai,]$Technique              <- "ochiai"
    data[tarantula,]$Technique           <- "tarantula"
    
    data[neuralnetwork,]$Technique           <- "neural-network"

    # Prettify names of technique and formulas for tables and graphs
    data$FLT <- prettifyTechniqueName(data$Technique)

    # Add macros for family, formula, technique, and kill definition
    data$FamilyMacro  <- getFamilyMacro(data$Family)
    data$FormulaMacro <- getFormulaMacro(data$Formula)
    data$TechniqueMacro <- getTechniqueMacro(data$Technique)
    #data$KillDefnMacro  <- getKillDefnMacro(data$KillDefn)

    # Explicitly set the type of factor columns to be a factor as some tests don't
    # automatically convert character columns.
    data$TestSuite     <- as.factor(data$TestSuite)
    data$ScoringScheme <- as.factor(data$ScoringScheme)
    data$Family        <- as.factor(data$Family)
    data$FamilyMacro   <- as.factor(data$FamilyMacro)
    data$FormulaMacro  <- as.factor(data$FormulaMacro)
    #data$KillDefnMacro <- as.factor(data$KillDefnMacro)
    data$Formula       <- as.factor(data$Formula)
    data$TotalDefn     <- as.factor(data$TotalDefn)
    #data$KillDefn      <- as.factor(data$KillDefn)
    #data$AggregationDefn <- as.factor(data$AggregationDefn)
    #data$HybridScheme  <- as.factor(data$HybridScheme)

    # Rank the EXAM scores.
    # TODO: which of the following tie breakers makes the most sense:
    # average, min, or max?
    data <- transform(data, RANK=ave(data$Score,
                                     data$TestSuite, data$Project, data$Bug, data$ScoringScheme,
                                     FUN=function(x){rank(x, ties.method="average")}))

    # Add a unique bug ID -> "Project Bug"
    data$ID <- as.factor(paste(data$Project,data$Bug))

    # Indicate whether the fault is a real fault
    #data$IS_REAL <- getReal(data)

    return(data)
}

#
# Return a list of unique FL techniques that exist in the provided data frame.
# Each string in this list is a concatenation of the features of the FL
# technique, using '_' as separator.
#
getAllTechniques <- function(df) {
    #techniques <- unique(paste(df$Family,df$Formula,df$TotalDefn,df$KillDefn,df$HybridScheme,df$AggregationDefn,sep="_"))
    techniques <- unique(paste(df$Family,df$Formula,df$TotalDefn,sep="_"))
  
    return(techniques)
}

#
# Return a list of unique <Project,Bug> pairs that exist in the provided data frame.
#
getAllBugs <- function(df) {
    bugs <- unique(df$ID)

    return(bugs)
}

#
# Aggregate "agg_column" (e.g., Score or RANK) in the provided data frame, using
# agg_function (e.g., mean or median).
#
aggColumn <- function(df, agg_column, agg_function) {
    if (! agg_column %in% colnames(df)) {
        stop(paste("Aggregate column", agg_column, "doesn't exist in provided data frame!"))
    }
    # Dynamically generate formula for given agg_column
    #formula <- as.formula(paste(agg_column,
    #                            "TestSuite + ScoringScheme + Family + FamilyMacro +
    #                             Technique + FLT + Formula + TotalDefn + KillDefn +
    #                             HybridScheme + AggregationDefn + FormulaMacro",
    #                            sep=" ~ "))
    
    # Dynamically generate formula for given agg_column
    formula <- as.formula(paste(agg_column,
                                "TestSuite + ScoringScheme + Family +
                                 Technique + FLT + Formula + TotalDefn",
                                sep=" ~ "))

    agg_data <- aggregate(formula,
                          data = df,
                          agg_function
    )

    return(agg_data)
}

#
# Return the top-n FL techniques for the provided scoring scheme (e.g., first or
# last) in the data frame, by aggregating agg_column using agg_function.
#
getTopN <- function(df, n, scoring_scheme, agg_column, agg_function) {
    # Validate arguments
    if (! scoring_scheme %in% scoring_schemes) {
        stop("Scoring scheme invalid!")
    }
    agg <- aggColumn(df, agg_column, agg_function)
    agg <- agg[agg$ScoringScheme==scoring_scheme,]
    sorted <- agg[order(agg[agg_column]),]
    sorted$n <- seq.int(nrow(sorted))

    return(head(sorted, n))
}

#
# Convenience functions to return the top-n FL techniques for the EXAM score or
# ranking.
#
getTopNScores <- function(df, n, scoring_scheme, agg_function) {
    return(getTopN(df, n, scoring_scheme, "Score", agg_function))
}
getTopNRanks <- function(df, n, scoring_scheme, agg_function) {
    return(getTopN(df, n, scoring_scheme, "RANK", agg_function))
}

#
# Convert a formula label into a LaTex macro.
#
getFormulaMacro <- function(formula) {
    return(ifelse(formula=="none",
                  "none",
                  paste("\\formula{", prettifyTechniqueName(formula), "}", sep="")))
}

#
# Helper function to format a FL technique (to be used in a LaTex table)
#
formatTechnique <- function(df) {
    #return(gsub("none", "\\\\defNone",
    #    (paste(df[["FamilyMacro"]],
    #           df[["FormulaMacro"]],
    #           df[["TotalDefn"]],
    #           getKillDefnMacro(df[["KillDefn"]]),
    #           df[["AggregationDefn"]],
    #           df[["HybridScheme"]], sep=" & "))))
  
    return(gsub("none", "\\\\defNone",
              (paste(df[["TotalDefn"]], sep=" & "))))
}

#
# Helper function to format a complete LaTex row, showing a FL technique
#
formatRow <- function(row, col) {
    # The two techniques used in all hybrid techniques (MBFL + SBFL)
    # TODO: This should not be hard coded but rather inferred.
    #bestMBFL <- c(FamilyMacro=row[["FamilyMacro"]], FormulaMacro=getFormulaMacro("jaccard"),
    #        TotalDefn="tests", KillDefn="type", AggregationDefn="avg", HybridScheme="none")
    #bestSBFL <- c(FamilyMacro=" ", FormulaMacro=getFormulaMacro("dstar2"),
    #        TotalDefn="tests", KillDefn="none", AggregationDefn="none", HybridScheme="none")

    # New hybrid techniques
    #if(isHybridFLT(row)) {
    #    return(cat(
    #        gsub("none", "\\\\defNone",
    #            paste(
    #                row[["n"]],
    #                formatTechnique(bestMBFL),
    #                row[[col]],
    #                sep=" & ")),
    #            "\\\\",
    #            "\n",
    #        gsub("none", "\\\\defNone",
    #            paste(
    #                " ",
    #                formatTechnique(bestSBFL),
    #                " ",
    #                sep=" & ")),
    #            "\\\\",
    #            "\n")
    #    )
    #}
    # Non-hybrid MCBFL and MRSBFL techniques
    #else if(isNewMutationFLT(row)) {
    #    return(cat(
    #        gsub("none", "\\\\defNone",
    #            paste(
    #                row[["n"]],
    #                formatTechnique(bestMBFL),
    #                row[[col]],
    #                sep=" & ")),
    #            "\\\\",
    #            "\n"))
    #}
    # Traditional SBFL and MBFL techniques
    #else {
    return(cat(
        gsub("none", "\\\\defNone",
            paste(
                row[["n"]],
                formatTechnique(row),
                row[[col]],
                sep=" & ")),
            "\\\\",
            "\n"))
    #}
}

#
# Helper function to print a table of FL techniques in LaTex format
#
printTechniqueTable <- function(df, col) {
    row <- apply(df, 1, formatRow, col)
    cat(row)
}

#
# Helper function to print anova table in LaTex format
#
printAnovaTable <- function(anova, factors, alpha=0.05) {
    #browser()
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

#
# Helper function to print the results of a Tukey test in LaTex format
#
printTukeyResultsTable <- function(tukeyTab, alpha=0.05) {
    df <- data.frame(tukeyTab)
    # Convert data frame -> add column for row names, which indicate the compared pair
    df <- setDT(df, keep.rownames = TRUE)[]
    colnames(df) <- c("Pair", "Difference", "Lower", "Upper", "p")

    prettyP <- function(p) {prettifyP(p, alpha)}
    df$p  <- lapply(df$p, prettyP)

    row <- paste(paste(gsub("-", " & ", df$Pair), df$p, sep=" & "), "\\\\ \n")
    cat(row)
}

#
# Helper function to print the results of a Tukey test as a matrix in LaTex format
#
printTukeyResultsMatrix <- function(tukeyTab, factors, alpha=0.05) {
    df <- data.frame(tukeyTab)
    # Convert data frame -> add column for row names, which indicate the compared pair
    df <- setDT(df, keep.rownames = TRUE)[]
    colnames(df) <- c("Pair", "Difference", "Lower", "Upper", "p")

    prettyP <- function(p) {prettifyP(p, alpha)}
    df$p  <- lapply(df$p, prettyP)

    # Print header row
    cat("& ", paste(factors, collapse=" & "), "\\\\ \n")
    # Print the matrix
    for(f1 in factors) {
        cat(f1)
        for(f2 in factors) {
            if (f1==f2) {
                cat(" & ", "\\symTukeyMatrixDiagonal", sep="")
            } else {
                mask <- df$Pair==paste(f1, f2, sep="-") | df$Pair==paste(f2, f1, sep="-")
                p <- paste(unlist(df[mask,p]), collapse='')
                cat(" & ", p, sep="")
            }
        }
        cat("\\\\ \n")
    }
}


#
# Cast data representation from long to wide, i.e., one column per technique.
#
castAll <- function(df, agg_column) {
    #casted <- dcast(setDT(df), Project + Bug ~ TestSuite + ScoringScheme + Family + Formula + TotalDefn + KillDefn + HybridScheme + AggregationDefn, value.var=agg_column)
    casted <- dcast(setDT(df), Project + Bug ~ TestSuite + ScoringScheme + Family + Formula + TotalDefn, value.var=agg_column)  
    return(casted)
}

#
# Convert a string to initial cap.
#
initialCap <- function(s) {
    s <- gsub("[-]", "", s)
    s <- paste(toupper(substring(s, 1,1)), tolower(substring(s, 2)),
               sep="", collapse=" ")

    return(s)
}

#
# Prettify a p value given an alpha level; keep NAs.
#
# Use LaTex macros for hightlighting the prettified p value:
# \sig{p}   -> significant p value
# \insig{p} -> insignificant p value
#
prettifyP <- function(p, alpha) {
    if(is.na(p)) {
        return("NA")
    } else if(p<alpha) {
        return(paste("\\sig{", "<", alpha, "}", sep=""))
    } else {
        return(sprintf("\\insig{%.2f}", p))
    }
}

#
# Get the real bug id from an artificial bug id
#
getRealBugId <- function(bugId) {
    if (bugId < 1000) {
        return(bugId)
    } else {
        return(floor(bugId/100000))
    }
}

#
# Determine whether one FLT is statistically significantly better than another.
#
significanceText <- function(p, effect) {
  basically <- if (effect<0) "yes" else "no"
  return(
    if (p < 0.01) paste("\\sigStrong{", basically, "}", sep="")
    else if (p < 0.05) paste("\\sigModerate{", basically, "}", sep="")
    else if (p < 0.1) paste("\\sigWeak{", basically, "}", sep="")
    else "\\sigNone")

}

#
# Determine whether one FLT is statistically significantly better than another.
#
significanceNumber <- function(p) {
  return(
    if (p < 0.01) paste("\\sigStrong{<0.01}", sep="")
    else if (p < 0.05) paste("\\sigModerate{<0.05}", sep="")
    else if (p < 0.1) paste("\\sigWeak{<0.1}", sep="")
    else "\\sigNone")
}

#
# Determine magnitude of Cohen's d effect size
#
dText <- function(d) {
  abs <- abs(d)
  dPrefix <- ifelse(d >= 0, "\\m", "")
  dPretty <- sprintf("%.2f", d)

  return(
    if (abs == 0) paste(dPrefix, "\\effectNone{0.00}", sep="")
    else if (abs < 0.2) paste(dPrefix, "\\effectNone{", dPretty, "}", sep="")
    else if (abs < 0.5) paste(dPrefix, "\\effectSmall{", dPretty, "}", sep="")
    else if (abs < 0.8) paste(dPrefix, "\\effectMedium{", dPretty, "}", sep="")
    else paste(dPrefix, "\\effectLarge{", dPretty, "}", sep=""))
}

#
# Determine magnitude of A12 effect size
#
a12Text <- function(a12) {
  abs <- abs(a12 - 0.5)
  return(
    if (abs < 0.06) paste("\\effectNone{", a12, "}", sep="")
    else if (abs < 0.14) paste("\\effectSmall{", a12, "}", sep="")
    else if (abs < 0.21) paste("\\effectMedium{", a12, "}", sep="")
    else paste("\\effectLarge{", a12, "}", sep=""))
}

#
# Typeset a confidence interval
#
typesetCI <- function(lwr, upr) {
    lwrPrefix <- ifelse(lwr>=0, "\\m", "")
    uprPrefix <- ifelse(upr>=0, "\\m", "")
    return(sprintf("[%s%.3f, %s%.3f]", lwrPrefix, lwr, uprPrefix, upr))
}

#
# Retain only artificial and real faults that can be paired on a real fault.
#
getPairedRealBugIds <- function(df) {
    tmp <- df
    tmp$REAL_ID <- paste(tmp$Project, tmp$RealBugId, sep="-")
    paired <- intersect(unique(tmp[tmp$IS_REAL,]$REAL_ID),
                        unique(tmp[!tmp$IS_REAL,]$REAL_ID))
    return(paired)
}

#
# Returns descriptive names for the three scoring schemes (first, median, last)
#
getScoringSchemes <- function(df) {
    schemes <- ifelse(df$ScoringScheme=="first",  "Best-case",
               ifelse(df$ScoringScheme=="last",   "Worst-case",
               ifelse(df$ScoringScheme=="median", "Average-case", "N/A")))

    schemes <- factor(schemes, levels=c("Best-case", "Worst-case", "Average-case"))
    return(schemes)
}

#######################################################################
## Less well-documented stuff from the replication using artificial faults
#######################################################################

# TODO should we consider all of them or only these ones
#techniques <- c("ochiai", "barinel", "muse", "dstar2", "opt2", "tarantula", "metallaxis", "jaccard")
techniques <- c("ochiai", "tarantula", "neural-network")

getReal <- function(df) {
  return(df$Bug < 1000)
}

getCorrespondingArtificial <- function(df, project, real_bug) {
  return((df$Project==project)
         & (df$Bug > real_bug*1e5)
         & (df$Bug < (real_bug+1)*1e5))
}

getTechniques <- function(df) {
  #return(as.factor(ifelse(df$KillDefn=="exact", "metallaxis", ifelse(df$KillDefn=="passfail", "muse", levels(df$Formula)[df$Formula]))))
  return(as.factor(levels(df$Formula)[df$Formula]))
}

prettifyTechniqueName <- function(techniques) {
  return(unlist(lapply(X=techniques, FUN=prettifyTechniqueNameX)))
}
prettifyTechniqueNameX <- function(technique) {
  if (technique=="ochiai") { # SBFL
    return ("Ochiai")
  } else if (technique=="barinel") {
    return ("Barinel")
  } else if (technique=="dstar2") {
    return ("DStar")
  } else if (technique=="opt2") {
    return ("Op2")
  } else if (technique=="tarantula") {
    return ("Tarantula")
  } else if (technique=="jaccard") {
    return ("Jaccard")
  } else if (technique=="ochiai2") {
    return ("Ochiai2")
  } else if (technique=="opt1") {
    return ("Op1")
  } else if (technique=="gp02") {
    return ("GP02")
  } else if (technique=="gp03") {
    return ("GP03")
  } else if (technique=="gp13") {
    return ("GP13")
  } else if (technique=="gp19") {
    return ("GP19")
  } else if (technique=="anderberg") {
    return ("Anderberg")
  } else if (technique=="dice") {
    return ("Dice")
  } else if (technique=="sorensen_dice") {
    return ("Sorensen-Dice")
  } else if (technique=="goodman") {
    return ("Goodman")
  } else if (technique=="qe") {
    return ("Qe")
  } else if (technique=="cbi_inc") {
    return ("CBIInc.")
  } else if (technique=="cbi_sqrt") {
    return ("CBISqrt")
  } else if (technique=="cbi_log") {
    return ("CBILog")
  } else if (technique=="wong1") {
    return ("Wong1")
  } else if (technique=="wong2") {
    return ("Wong2")
  } else if (technique=="wong3") {
    return ("Wong3")
  } else if (technique=="hamann") {
    return ("Hamann")
  } else if (technique=="simple_matching") {
    return ("SimpleMatching")
  } else if (technique=="sokal") {
    return ("Sokal")
  } else if (technique=="rogers_tanimoto") {
    return ("Rogers-Tanimoto")
  } else if (technique=="hamming") {
    return ("Hamming")
  } else if (technique=="euclid") {
    return ("Euclid")
  } else if (technique=="russell_rao") {
    return ("Russell-Rao")
  } else if (technique=="binary") {
    return ("Binary")
  } else if (technique=="scott") {
    return ("Scott")
  } else if (technique=="rogot1") {
    return ("Rogot1")
  } else if (technique=="rogot2") {
    return ("Rogot2")
  } else if (technique=="kulczynski1") {
    return ("Kulczynski1")
  } else if (technique=="kulczynski2") {
    return ("Kulczynski2")
  } else if (technique=="m1") {
    return ("M1")
  } else if (technique=="m2") {
    return ("M2")
  } else if (technique=="ample") {
    return ("Ample")
  } else if (technique=="ample2") {
    return ("Ample2")
  } else if (technique=="arithmetic_mean") {
    return ("ArithmeticMean")
  } else if (technique=="geometric_mean") {
    return ("GeometricMean")
  } else if (technique=="harmonic_mean") {
    return ("HarmonicMean")
  } else if (technique=="cohen") {
    return ("Cohen")
  } else if (technique=="fleiss") {
    return ("Fleiss")
  } else if (technique=="braun_banquet") {
    return ("Braun-Banquet")
  } else if (technique=="mountford") {
    return ("Mountford")
  } else if (technique=="gower") {
    return ("Gower")
  } else if (technique=="michael") {
    return ("Michael")
  } else if (technique=="pierce") {
    return ("Pierce")
  } else if (technique=="baroni_urbani_buser") {
    return ("Baroni-Urbani-Buser")
  } else if (technique=="zoltar") {
    return ("Zoltar")
  } else if (technique=="overlap") {
    return ("Overlap")
  } else if (technique=="metallaxis") { # MBFL
    return ("Metallaxis")
  } else if (technique=="muse") {
    return ("MUSE")
  } else if (technique=="mcbfl") { # MCBFL (MKill + MCov)
    return ("MCBFL")
  } else if (technique=="failover") { # MCBFL-hybrid (MKill + MCov + SCov)
    return ("MCBFL-hybrid-failover")
  } else if (technique=="susp-maxing") {
    return ("MCBFL-hybrid-max")
  } else if (technique=="susp-averaging") {
    return ("MCBFL-hybrid-avg")
  } else if (technique=="mbfl-coverage-only") { # MRSBFL (MCov)
    return ("MRSBFL")
  } else if (technique=="mrsbfl-failover") { # MRSBFL-hybrid (MCov + SCov)
    return ("MRSBFL-hybrid-failover")
  } else if (technique=="mrsbfl-susp-maxing") {
    return ("MRSBFL-hybrid-max")
  } else if (technique=="mrsbfl-susp-averaging") {
    return ("MRSBFL-hybrid-avg")
  } else if (technique=="neural-network") { # MLFL
    return ("Neural Network")
  } else {
    return ("NA")
  }
}

getTechniqueMacro <- function(techniques) {
  return(unlist(lapply(X=techniques, FUN=getTechniqueMacroX)))
}
getTechniqueMacroX <- function(technique) {
  if (technique=="ochiai") { # SBFL
    return ("Ochiai")
  } else if (technique=="barinel") {
    return ("Barinel")
  } else if (technique=="dstar2") {
    return ("DStar")
  } else if (technique=="opt2") {
    return ("Op2")
  } else if (technique=="tarantula") {
    return ("Tarantula")
  } else if (technique=="jaccard") {
    return ("Jaccard")
  } else if (technique=="ochiai2") {
    return ("Ochiai2")
  } else if (technique=="opt1") {
    return ("Op1")
  } else if (technique=="gp02") {
    return ("GP02")
  } else if (technique=="gp03") {
    return ("GP03")
  } else if (technique=="gp13") {
    return ("GP13")
  } else if (technique=="gp19") {
    return ("GP19")
  } else if (technique=="anderberg") {
    return ("Anderberg")
  } else if (technique=="dice") {
    return ("Dice")
  } else if (technique=="sorensen_dice") {
    return ("SorensenDice")
  } else if (technique=="goodman") {
    return ("Goodman")
  } else if (technique=="qe") {
    return ("Qe")
  } else if (technique=="cbi_inc") {
    return ("CBIInc")
  } else if (technique=="cbi_sqrt") {
    return ("CBISqrt")
  } else if (technique=="cbi_log") {
    return ("CBILog")
  } else if (technique=="wong1") {
    return ("Wong1")
  } else if (technique=="wong2") {
    return ("Wong2")
  } else if (technique=="wong3") {
    return ("Wong3")
  } else if (technique=="hamann") {
    return ("Hamann")
  } else if (technique=="simple_matching") {
    return ("SimpleMatching")
  } else if (technique=="sokal") {
    return ("Sokal")
  } else if (technique=="rogers_tanimoto") {
    return ("RogersTanimoto")
  } else if (technique=="hamming") {
    return ("Hamming")
  } else if (technique=="euclid") {
    return ("Euclid")
  } else if (technique=="russell_rao") {
    return ("RussellRao")
  } else if (technique=="binary") {
    return ("Binary")
  } else if (technique=="scott") {
    return ("Scott")
  } else if (technique=="rogot1") {
    return ("Rogot1")
  } else if (technique=="rogot2") {
    return ("Rogot2")
  } else if (technique=="kulczynski1") {
    return ("Kulczynski1")
  } else if (technique=="kulczynski2") {
    return ("Kulczynski2")
  } else if (technique=="m1") {
    return ("M1")
  } else if (technique=="m2") {
    return ("M2")
  } else if (technique=="ample") {
    return ("Ample")
  } else if (technique=="ample2") {
    return ("Ample2")
  } else if (technique=="arithmetic_mean") {
    return ("ArithmeticMean")
  } else if (technique=="geometric_mean") {
    return ("GeometricMean")
  } else if (technique=="harmonic_mean") {
    return ("HarmonicMean")
  } else if (technique=="cohen") {
    return ("Cohen")
  } else if (technique=="fleiss") {
    return ("Fleiss")
  } else if (technique=="braun_banquet") {
    return ("BraunBanquet")
  } else if (technique=="mountford") {
    return ("Mountford")
  } else if (technique=="gower") {
    return ("Gower")
  } else if (technique=="michael") {
    return ("Michael")
  } else if (technique=="pierce") {
    return ("Pierce")
  } else if (technique=="baroni_urbani_buser") {
    return ("BaroniUrbaniBuser")
  } else if (technique=="zoltar") {
    return ("Zoltar")
  } else if (technique=="overlap") {
    return ("Overlap")
  } else if (technique=="metallaxis") { # MBFL
    return ("Metallaxis")
  } else if (technique=="muse") {
    return ("MUSE")
  } else if (technique=="mcbfl") { # MCBFL (mbfl + mutation coverage)
    return ("\\mcbfl")
  } else if (technique=="failover") { # MCBFL-hybrid (mcbfl + sbfl)
    return ("\\failover")
  } else if (technique=="susp-maxing") {
    return ("\\suspmaxing")
  } else if (technique=="susp-averaging") {
    return ("\\suspaveraging")
  } else if (technique=="mbfl-coverage-only") { # MRSBFL (mutation coverage)
    return ("\\mrsbfl")
  } else if (technique=="mrsbfl-failover") { # MRSBFL-hybrid (mutation coverage + sbfl)
    return ("\\mrsbflfailover")
  } else if (technique=="mrsbfl-susp-maxing") {
    return ("\\mrsbflsuspmaxing")
  } else if (technique=="mrsbfl-susp-averaging") {
    return ("\\mrsbflsuspaveraging")
  } else {
    return ("NA")
  }
}

getFamilyMacro <- function(family) {
  return(
         # SBFL
         ifelse(family=="sbfl",  "\\sbfl",
         # MBFL
         ifelse(family=="mbfl", "\\mbfl",
         # MCBFL (mbfl + mutation coverage)
         ifelse(family=="mcbfl",          "\\mcbfl",
         # MCBFL-hybrid (mcbfl + sbfl)
         ifelse(family=="failover",       "\\failover",
         ifelse(family=="susp-maxing",    "\\suspmaxing",
         ifelse(family=="susp-averaging", "\\suspaveraging",
         # MRSBFL (mutation coverage)
         ifelse(family=="mbfl-coverage-only",      "\\mrsbfl",
         # MRSBFL-hybrid (mutation coverage + sbfl)
         ifelse(family=="mrsbfl-failover",         "\\mrsbflfailover",
         ifelse(family=="mrsbfl-susp-maxing",      "\\mrsbflsuspmaxing",
         ifelse(family=="mrsbfl-susp-averaging",   "\\mrsbflsuspaveraging",
    "NA")))))))))))
}

getKillDefnMacro <- function(killDefn) {
  return(ifelse(killDefn=="none", "\\defNone",
        paste("\\", "killDefn", initialCap(gsub("[+]", "", killDefn)), sep="")))
}

getType <- function(techniques) {
  return(unlist(lapply(X=techniques, FUN=getTypeX)))
}
getTypeX <- function(technique) {
  if (technique=="sbfl") { # SBFL
    return ("SBFL")
  } else if (technique=="ochiai") {
    return ("SBFL")
  } else if (technique=="barinel") {
    return ("SBFL")
  } else if (technique=="dstar2") {
    return ("SBFL")
  } else if (technique=="opt2") {
    return ("SBFL")
  } else if (technique=="tarantula") {
    return ("SBFL")
  } else if (technique=="jaccard") {
    return ("SBFL")
  } else if (technique=="ochiai2") {
    return ("SBFL")
  } else if (technique=="opt1") {
    return ("SBFL")
  } else if (technique=="gp02") {
    return ("SBFL")
  } else if (technique=="gp03") {
    return ("SBFL")
  } else if (technique=="gp13") {
    return ("SBFL")
  } else if (technique=="gp19") {
    return ("SBFL")
  } else if (technique=="anderberg") {
    return ("SBFL")
  } else if (technique=="dice") {
    return ("SBFL")
  } else if (technique=="sorensen_dice") {
    return ("SBFL")
  } else if (technique=="goodman") {
    return ("SBFL")
  } else if (technique=="qe") {
    return ("SBFL")
  } else if (technique=="cbi_inc") {
    return ("SBFL")
  } else if (technique=="cbi_sqrt") {
    return ("SBFL")
  } else if (technique=="cbi_log") {
    return ("SBFL")
  } else if (technique=="wong1") {
    return ("SBFL")
  } else if (technique=="wong2") {
    return ("SBFL")
  } else if (technique=="wong3") {
    return ("SBFL")
  } else if (technique=="hamann") {
    return ("SBFL")
  } else if (technique=="simple_matching") {
    return ("SBFL")
  } else if (technique=="sokal") {
    return ("SBFL")
  } else if (technique=="rogers_tanimoto") {
    return ("SBFL")
  } else if (technique=="hamming") {
    return ("SBFL")
  } else if (technique=="euclid") {
    return ("SBFL")
  } else if (technique=="russell_rao") {
    return ("SBFL")
  } else if (technique=="binary") {
    return ("SBFL")
  } else if (technique=="scott") {
    return ("SBFL")
  } else if (technique=="rogot1") {
    return ("SBFL")
  } else if (technique=="rogot2") {
    return ("SBFL")
  } else if (technique=="kulczynski1") {
    return ("SBFL")
  } else if (technique=="kulczynski2") {
    return ("SBFL")
  } else if (technique=="m1") {
    return ("SBFL")
  } else if (technique=="m2") {
    return ("SBFL")
  } else if (technique=="ample") {
    return ("SBFL")
  } else if (technique=="ample2") {
    return ("SBFL")
  } else if (technique=="arithmetic_mean") {
    return ("SBFL")
  } else if (technique=="geometric_mean") {
    return ("SBFL")
  } else if (technique=="harmonic_mean") {
    return ("SBFL")
  } else if (technique=="cohen") {
    return ("SBFL")
  } else if (technique=="fleiss") {
    return ("SBFL")
  } else if (technique=="braun_banquet") {
    return ("SBFL")
  } else if (technique=="mountford") {
    return ("SBFL")
  } else if (technique=="gower") {
    return ("SBFL")
  } else if (technique=="michael") {
    return ("SBFL")
  } else if (technique=="pierce") {
    return ("SBFL")
  } else if (technique=="baroni_urbani_buser") {
    return ("SBFL")
  } else if (technique=="zoltar") {
    return ("SBFL")
  } else if (technique=="overlap") {
    return ("SBFL")
  } else if (technique=="mbfl") { # MBFL
    return ("MBFL")
  } else if (technique=="metallaxis") {
    return ("MBFL")
  } else if (technique=="muse") {
    return ("MBFL")
  } else if (technique=="mcbfl") { # MCBFL (mbfl + mutation coverage)
    return ("MCBFL")
  } else if (technique=="failover") { # MCBFL-hybrid (mcbfl + sbfl)
    return ("MCBFL")
  } else if (technique=="susp-maxing") {
    return ("MCBFL")
  } else if (technique=="susp-averaging") {
    return ("MCBFL")
  } else if (technique=="mbfl-coverage-only") { # MRSBFL (mutation coverage)
    return ("MRSBFL")
  } else if (technique=="mrsbfl-failover") { # MRSBFL-hybrid (mutation coverage + sbfl)
    return ("MRSBFL")
  } else if (technique=="mrsbfl-susp-maxing") {
    return ("MRSBFL")
  } else if (technique=="mrsbfl-susp-averaging") {
    return ("MRSBFL")
  } else {
    return ("NA")
  }
}
prettifyPValue <- function(p) {
  if (p < 0.01) {
    return("<0.01")
  }
  return(sprintf("%.2f", p))
}

#
# For each FLT in df, is the FLT a hybrid technique or a traditional technique.
# Traditional techniques are sbfl and mbfl techniques.
#
isHybridFLT <- function(df) {
    return(df[["Technique"]] %in% c("failover", "susp-maxing", "susp-averaging",
            "mrsbfl-failover", "mrsbfl-susp-maxing", "mrsbfl-susp-averaging"))
}

#
# For each FLT in df, is the FLT a new mutation-based technique.
#
isNewMutationFLT <- function(df) {
    return(df[["Technique"]] %in% c("mcbfl", "mbfl-coverage-only"))
}

#
# Compute top-5, top-10, and top-200, and average the results.
#
averageTopN <- function(ScoreAbs) {
    num_bugs <- length(ScoreAbs)
    top5   <- sum(ScoreAbs<=5) / num_bugs
    top10  <- sum(ScoreAbs<=10) / num_bugs
    top200 <- sum(ScoreAbs<=200) / num_bugs

    return(mean(c(top5,top10,top200)))
}

#
# Rank FLTs in the given data frame according to top-n performance.  This
# function returns an aggregated and sorted data frame with the following
# columns: ScoringScheme, Real, FLT, AvgTopN
#
rankTopN <- function(df) {
    agg <- aggregate(ScoreAbs ~ ScoringScheme + Real + Family + FLT, data=df, FUN=function(x) averageTopN(x))
    agg <- agg[with(agg, order(Real, Family, ScoringScheme, -ScoreAbs)),]
    names(agg)[names(agg) == "ScoreAbs"] <- "AvgTopN"

    return(agg)
}

##########################################################################
#
# Taken from http://doofussoftware.blogspot.com
#
##########################################################################
#
# Computes the Vargha-Delaney A measure for two populations a and b.
#
# Equation numbers below refer to the paper:
# @article{vargha2000critique,
#  title={A critique and improvement of the CL common language effect size
#               statistics of McGraw and Wong},
#  author={Vargha, A. and Delaney, H.D.},
#  journal={Journal of Educational and Behavioral Statistics},
#  volume={25},
#  number={2},
#  pages={101--132},
#  year={2000},
#  publisher={Sage Publications}
# }
#
# a: a vector of real numbers
# b: a vector of real numbers
# Returns: A real number between 0 and 1
A12 <- function(a,b){

    # Compute the rank sum (Eqn 13)
    r = rank(c(a,b))
    r1 = sum(r[seq_along(a)])

    # Compute the measure (Eqn 14)
    m = length(a)
    n = length(b)
    A = (r1/m - (m+1)/2)/n

    A
}
