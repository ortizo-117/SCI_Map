#################################################
#################################################
#This R script is the condensed version for the Freesurfer analysis comparison 
#Outputs *10 csv files from analyses, which could vary depending on your study cohort.
#
#
#################################################
#
#A detailed RMarkdown file is included for a very detailed rundown of this code if necessary 
#
#  Written by Ryan Loke (PhD Student)
#  Department of Anesthesiology, Pharmacology, and Therapeutics, University of British Columbia
#  International Collaborations on Repair Discoveries (ICORD)
#
#################################################

if (!require("tidyverse")) install.packages("tidyverse")
if (!require("data.table")) install.packages("data.table")
if (!require("multcomp")) install.packages("multcomp")
if (!require("effsize")) install.packages("effsize")
if (!require("writexl")) install.packages("writexl")
if (!require("ggpubr")) install.packages("ggpubr")

library(tidyverse)
library(data.table)
library(multcomp)
library(effsize)
library(writexl)
library(ggpubr)


#Import the data, properly define your path 
cortical_stats_long <- read.csv(
  "R:/43_Ryan_Loke/Side Projects/Freesurfer_Analysis/cortical_stats_long.csv",
  sep =","
)

SCI_Data <- data.frame(cortical_stats_long)

#Import your metadata
metadata <- read.csv(
  "R:/43_Ryan_Loke/Side Projects/VolBrain/SCI_Metadata_FS.csv",
  sep=","
)

#Merge your metadata to your data
SCI_Data <- SCI_Data %>%
  left_join(dplyr::select(metadata, ID, code, sex, age), by = c("Subject" = "ID"))

#Subset your master dataframe to smaller ones for individual comparisons

#PvH indicates people with SCI and neuropathic pain vs healthy individuals
SCI_PvH <- data.frame(SCI_Data_wide[SCI_Data_wide$code %in% c("SCI_P","SCI_H"), ])

#nNPvH indicates people with SCI but no neuroapthic pain vs healhty individuals
SCI_nNPvH <- data.frame(SCI_Data_wide[SCI_Data_wide$code %in% c("SCI_nNP","SCI_H"), ])

#nNPvP indicates people with SCI but no neuropathic pain vs people with SCI and neuropathic pain
SCI_nNPvP <- data.frame(SCI_Data_wide[SCI_Data_wide$code %in% c("SCI_nNP","SCI_P"), ])

#IvH indicates all people with SCI vs healthy individuals
SCI_IvH <- as.data.frame(SCI_Data_wide %>%
                           mutate(code = case_when(
                             code %in% c("SCI_P", "SCI_nNP") ~"SCI",
                             TRUE ~ code
                           )))

#################################################
#ANALYSIS CODE SKELETON
#################################################

#You will need to run this loop for each of the 4 data frames above while changing just a few things
#Refer to the rmarkdown for the fully written out code if needed
#Every variable that needs changing is surrounded in "*" below. 
#Refer to Analysis_skeleton_variables.txt for what you should change them to.

*results* <- lapply(colnames(*dataframe*[5:ncol(*dataframe*)], 
                             function(region) {
                               
   t_test <- t.test(*dataframe*[[region]] ~ *dataframe*$code)
   
   d_result <- cohen.d(*dataframe*[[region]] ~ *dataframe*$code)
   d_value <- d_result$estimate
   
   n1 <- sum(*dataframe*$code == "*group1*")
   n2 <- sum(*dataframe*$code == "*group2*")
   
   se_d <- sqrt((n1 + n2) / (n1 * n2) + (d_value^2) / (2 * (n1 + n2)))
   ci_lower <- d_value - 1.96 * se_d
   ci_upper <- d_value + 1.96 * se_d
   
   data.frame(
     Region = region,
     p_value = t_test$p.value,
     Mean_Group1 = mean(*dataframe*[*dataframe*$code == "*group1", 
                                    region], na.rm = TRUE),
     Mean_Group2 = mean(*dataframe*[*dataframe*$code == "*group2*", 
                                    region], na.rm = TRUE),
     t_statistic = t_test$statistic,
     Cohen_d = d_value,
     SE_Cohen_d = se_d,
     CI_lower = ci_lower,
     CI_upper = ci_upper
   )
 })
                    
*summary* <- do.call(rbind, *results*)

write_xlsx(*summary*, "SCI_*code*_results.xlsx")
















