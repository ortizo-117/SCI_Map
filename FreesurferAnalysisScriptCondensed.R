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

# Converting to wide format
SCI_Data_wide <- SCI_Data %>%
  mutate(hemisphere_region_measure = paste(Hemisphere, Region, Measure, sep = "_")) %>%
  dplyr::select(-Region, -Hemisphere, -Measure) %>%
  pivot_wider(names_from = hemisphere_region_measure, values_from = Value)

#Subset your master dataframe to smaller ones for individual comparisons

#PvH indicates people with SCI and neuropathic pain vs healthy individuals
SCI_PvH <- data.frame(SCI_Data_wide[SCI_Data_wide$code %in% c("SCI_P","control"), ])

#nNPvH indicates people with SCI but no neuroapthic pain vs healhty individuals
SCI_nNPvH <- data.frame(SCI_Data_wide[SCI_Data_wide$code %in% c("SCI_nNP","control"), ])

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
     Mean_Group1 = mean(*dataframe*[[region]][*dataframe*$code == "*group1*"], na.rm = TRUE),
     Mean_Group2 = mean(*dataframe*[[region]][*dataframe*$code == "*group2*"], na.rm = TRUE),
     t_statistic = t_test$statistic,
     Cohen_d = d_value,
     SE_Cohen_d = se_d,
     CI_lower = ci_lower,
     CI_upper = ci_upper
   )
 })
                    
*summary* <- do.call(rbind, *results*)

write_xlsx(*summary*, "SCI_*code*_results.xlsx")

#################################################
#Summarize Intracranial volume statistics
#################################################

ICV_data <- read.csv(
  "/path/to/ICV_data.csv",
  sep = ","
)
#You can also import through the RStudio GUI too.

#This gets rid of any columns of NA that may have been created. 
ICV_data <- ICV_data[, colSums(is.na(ICV_data)) < nrow(ICV_data)]

#Adding metadata
ICV_data <- cbind(ICV_data, metadata[c("code","sex","age")])

#Group level summary statistics for age and standard deviation
ICV_Summary <- ICV_data %>%
  group_by(code, sex) %>%
  summarize(
    mean_ICV = mean(ICV, na.rm = T),
    sd_ICV = sd(ICV, na.rm = T),
    n = n()
  )

#export summary statistics. 
write_xlsx(ICV_Summary, "ICV_Summary.xlsx")

#################################################
#Summarize cortical thickness statistics
#################################################

CT_data <- read.csv(
  "/path/to/cortical_thickness_test.csv",
  sep = ","
)

#Adding metadata
CT_data <- cbind(CT_data, metadata[c("code","sex","age")])

#Group level summary statistics for age and standard deviation
CT_Summary <- CT_data %>%
  group_by(code, sex) %>%
  summarize(
    mean_rh_CT = mean(rh_thickness, na.rm = T),
    mean_lh_CT = mean(lh_thickness, na.rm = T),
    sd_rh_CT = sd(rh_thickness, na.rm = T),
    sd_lh_CT = sd(lh_thickness, na.rm = T),
    n = n()
  )

#export summary statistics. 
write_xlsx(CT_Summary, "CT_Summary.xlsx")

#################################################
#Subcortical volumes analysis
#################################################

subcortical_volumes <- read.csv(
  "/path/to/subcortical_volumes.csv",
  sep = '\t'
)

#Get rid of any columns that contain only zeros
subcortical_volumes <- subcortical_volumes[ ,colSums(subcortical_volumes != 0) > 0]

#Attach metadata
subcortical_volumes <- cbind(subcortical_volumes[ , 1, drop = F], metadata[c("code","sex","age")],
                             subcortical_volumes[, -1, drop = F])

colnames(subcortical_volumes)[1] <- "SubjectID"

#Subset data frames for specific analyses
SUB_PvH <- data.frame(subcortical_volumes[subcortical_volumes$code %in% c("SCI_P","control"), ])

SUB_nNPvH <- data.frame(subcortical_volumes[subcortical_volumes$code %in% c("SCI_nNP", "control"), ])

SUB_nNPvP <- data.frame(subcortical_volumes[subcortical_volumes$code %in% c("SCI_nNP", "SCI_P"), ])

SUB_IvH <- as.data.frame(subcortical_volumes %>%
                           mutate(code = case_when(
                             code %in% c("SCI_P", "SCI_nNP") ~"SCI",
                             TRUE ~ code
                           )))

#This is an example for the first analysis between healthy individuals, and individuals with SCI and NP. 
#The analysis will have to be done with all FOUR subsets of data created in the previous lines. 
#Change the variables accordingly, (same as above, can refer to it for more detail).

SUB_PvH_results <- lapply(colnames(SUB_PvH)[5:ncol(SUB_PvH)], 
                          function(region) {
                            
  t_test <- t.test(SUB_PvH[[region]] ~ SUB_PvH$code)
  
  d_result <- cohen.d(SUB_PvH[[region]] ~ SUB_PvH$code)
  d_value <- d_result$estimate
  
  n1 <- sum(SUB_PvH$code == "SCI_P")
  n2 <- sum(SUB_PvH$code == "control")
  
  se_d <- sqrt((n1 + n2) / (n1 * n2) + (d_value^2) / (2 * (n1 + n2)))
  ci_lower <- d_value - 1.96 * se_d
  ci_upper <- d_value + 1.96 * se_d
  
  data.frame(
    Region = region,
    p_value = t_test$p.value,
    Mean_Group1 = mean(SUB_PvH[[region]][SUB_PvH$code == "SCI_P"], na.rm = TRUE),
    Mean_Group2 = mean(SUB_PvH[[region]][SUB_PvH$code == "control"], na.rm = TRUE),
    t_statistic = t_test$statistic,
    Cohen_d = d_value,
    SE_Cohen_d = se_d,
    CI_lower = ci_lower,
    CI_upper = ci_upper
  )
})


SUB_PvH_summary <- do.call(rbind, SUB_PvH_results)

SUB_PvH_summary <- SUB_PvH_summary[order(SUB_PvH_summary$p_value),]

write_xlsx(SUB_PvH_summary, "SUB_PvH_results.xlsx")

#Make sure this is ran once with each data subset for subcortical volumes, you will 
#end up with 4 .xlsx files in the end. 

##Conclusion 




