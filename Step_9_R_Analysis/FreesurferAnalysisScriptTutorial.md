---
editor_options:
  markdown:
    wrap: 72
output: pdf_document
---

## SCI MAP Project Strutural Analysis

##### **Email**: [lokeryan\@student.ubc.ca](mailto:lokeryan@student.ubc.ca){.email}

##### PhD Student

###### Department of Anesthesiology, Pharmacology and Therapeutics, University of British Columbia, Vancouver, Canada

###### International Collaborations on Repair Discoveries (ICORD), Vancouver, Canada

```{=html}
<script>
  addClassKlippyTo("pre.r, pre.markdown");
  addKlippy('left', 'top', '#8B0000', '1', 'Copy code', 'Copied!');
</script>
```

## Overview

------------------------------------------------------------------------

Disclaimer: I am writing this tutorial from a Windows based computer, if
you’re using a Macbook, things may look or function slightly different.
To my knowledge, some packages and dependencies may differ, but the ones
used here should be fine. **Please email me if you encounter any
troubles!**

This document will run through the standardized analysis we will use for
our spinal cord injury meta analysis. This analysis will take place
after the MRI images have been processed using the Freesurfer reconall
pipeline, and the statistics have been aggregated into their respective
‘.csv’ files using the provided scripts. Below is a rundown of the files
you should have.

------------------------------------------------------------------------

| File Name | Contents |
|:----------------------------------|:----------------------------------|
| DKStats.csv | Individual level structural cortical measurements and subcortical volumes. |
| metadata.csv | The metadata for your study population |
| ICV_data.csv | Individual level intracranial volume (ICV) values |
| cortical_thickness.csv | Individual level, cortical thickness in the left and right hemisphere. |

------------------------------------------------------------------------

The beginning of this document will assume the user has little to no
experience in R/RStudio. If you are unfamiliar with the
language/interface, Google and ChatGPT are both great debugging tools,
however, feel free to reach out if any issue remains persistent. This
should be easy for everyone to follow. If you know what you’re doing,
please feel free to skip around to the important parts. Code can be
copied to your clipboard using the dark red button on the top left of
each code chunk.

## RStudio Overview

------------------------------------------------------------------------

RStudio is a integrated development environment for the programming
language R, a language for statistical computing and graphics.

### Creating a new project

------------------------------------------------------------------------

When starting a new analysis for a project, you **always** want to start
a new project. First, hit ‘File’ -\> ‘New Project…’ -\> ‘New Directory’
-\> ‘New Project’. Name your project and save it in a location you can
find easily. Click ‘Create Project’.

### RStudio workspace

------------------------------------------------------------------------

This is the default work space. The console will take the entirety of
the left screen, you want to make it smaller by clicking the bar that
says ‘Source’ along the top of the screen. Now you should have four
windows.

The top left is where you should always write your script. You can run
code in the console, but **it will not be saved**. By writing code in
Source pane, you can save and edit your code for future analyses. It
also makes it much easier to track what you have already done. Scripts
can be saved by ‘Ctrl/Cmd’ + ‘s’. Code can be ran by clicking or
highlighting the line(s) of code you want to run, then pressing
**Ctrl/Cmd + Enter**.

The bottom left window is the console, which shows the output of code
you run. You can run code here by typing it into the console, but it is
difficult to keep track of what you’re running as code ran here is not
saved. Please write and run all your code in the Source pane (top left).

The top right window is your environment. Any files imported, or any
variables created will be listed here. The bottom right pane is a
multifunctional pane. It displays files in your current working
directory, and any graphics you choose to make.

## Installing packages

------------------------------------------------------------------------

To start, we need to download and load some packages (dependencies)
necessary to process and analyze the data. The code
`install.packages("package_name")` installs the packages into your
RStudio system. Installing packages only needs to be done **once** for
every computer. Below are the packages used.

```         
install.packages("tidyverse")
install.packages("data.table")
install.packages("multcomp")
install.packages("effsize")
install.packages("writexl")
install.packages("ggpubr")
install.packages("esvis")
```

### Loading the libraries

------------------------------------------------------------------------

Use `library(package_name)` to load the downloaded libraries, so you may
use their functions in your code. This needs to be done **every time you
close and reopen RStudio**. You can run code by highlighting all the
lines and pressing **Ctrl/Cmd + Enter**, or you may click the top line
of code, then press **Ctrl/Cmd + Enter** 5 times to run each line
separately.

```         
library(tidyverse)
library(data.table)
library(multcomp)
library(effsize)
library(writexl)
library(ggpubr)
library(esvis)
```

## Importing your data

------------------------------------------------------------------------

Next, we need to import the first .csv file for analysis. We will start
with `DKStats.csv`. Hit ‘File’ -\> ‘Import Dataset’ -\> ‘From Text
(Base)’.

That will bring up a new window, where you can browse for the file on
your computer. Locate the .csv file which should be named `DKStats.csv`,
and click open. Wait for RStudio to detect the data format. You may have
to click “Yes” under the heading row. Check the Data Frame window on the
bottom right and make sure it matches the picture below. Then hit
‘Import’.

A new window will open up, displaying the entire imported data set. It
will also appear in your environment on the top right panel of the
screen.

### An alternative way to import data

------------------------------------------------------------------------

You can also use the following line of code to import the data. You will
need to **change the pathway** to fit your own system

```         
#If you use this method to import your data, make sure to change the file path to match your own machine. 

mastersheet <- read.csv(
  "R:/43_Ryan_Loke/Side Projects/Freesurfer_Analysis/DKStats.csv",
  sep =","
)

#This code allows you to see the first four columns of the dataframe. 
head(mastersheet)

##   subject lh_bankssts_NumVert lh_bankssts_SurfArea lh_bankssts_GrayVol 
## 1 sub-001 1316                 912                   1954
## 2 sub-001 1415                 1045                  2003  
## 3 sub-001 1745                 846                   1875  
## 4 sub-001 1265                 1132                 2113
## 5 sub-001 1965                 985                   1997
## 6 sub-001 1456                 947                   1857
```

## Setting up

------------------------------------------------------------------------

First, we need to create a dataframe that duplicates the data. This is
because we never want to edit the mastersheet, just in case we mess up,
and so we don’t have to import the data again. SCI_Data is now our main
data frame. We are then going to split this dataframe into one containing
only cortical data, and another containing subcortical data.

```         
SCI_Data <- data.frame(mastersheet)

SCI_cortical <- SCI_Data[,1:613]
#Just to check, the column name for 613 should be ...
colnames(SCI_cortical)[613]

## [1] "rh_insula_CurvInd"

SCI_subcortical <- SCI_Data[,614:ncol(SCI_Data)]

#The first column of the subcortical data frame should be ...

colnames(SCI_subcortical)[1] 

## [1] "Left.Lateral.Ventricle"

#If column names are different, change indices as needed.

```

### Freesurfer output rundown

------------------------------------------------------------------------

In case you were curious as to what some of these metrics mean, here is
a quick summary of all of them, and why we are choosing to look at it.

| Variable Name | Meaning | Significance |
|:--------------------|:------------------------|:------------------------|
| SurfArea | Surface area (mm^2^) | Indicates spatial extent of cortex, often changes with neurodegeneration |
| GrayVol | Volume (mm^3^) | Reflects regional cortical mass, often changes with neurodegeneration |
| ThickAvg | Average cortical thickness (mm) | Indicates structural integrity of a region, thinning is associated with a ging/neurodegeneration |
| ThickStd | Standard deviation of thickness | Thickness variability, higher variability can indicate cortical remodeling or disease progression |
| NumVert | Number of vertices in surface mesh | Cortical surface is represented as a triangular mesh made of face and vertices|
| Meancurv | Average mean curvature (extrinsic curvature) | Indicates folding patterns, abnormal gyrification can be associated with neurodegenerative states |
| GausCurv | Average gaussian curvature of region (intrinsic curvature)| highlight convexity or concavity of region, changes might indicate altered morphology |
| FoldInd | Folding index (complexity) | Track gyrification patterns, can change with certain neurological disorders |
| Curvind | Curvature Index, a global measure of curvature | Describes cortical shape, folding abnormalities are tied to certain psychiatric conditions. |

### Cohort labeling

------------------------------------------------------------------------

This walk-through also assumes your data has three cohorts, you may have
less, and thus you'll have less analyses to run. These
are the names I will use in my metadata labeling, you may use your own, just 
make sure you remember which is which. 

| Group | Code | Comment |
|:-------------------------|:---------------|:-------------------------|
| Healthy controls | SCI_H | Individuals without SCI |
| SCI with neuropathic pain | SCI_P | Individuals with SCI and pain |
| SCI without neuropathic pain | SCI_nNP | Individuals with SCI, but no pain |
| SCI combined | SCI | All individuals with an SCI, (SCI_P + SCI_nNP) |

------------------------------------------------------------------------

### Metadata labeling

------------------------------------------------------------------------

Import your metadata .csv or .xlsx into RStudio using either previously
described method. I have displayed the column names of my metadata
sheet, yours may look different so you may have to change some of the
code following.

```         
# Please make sure to change the file pathway if necessary.

metadata_SCI <- read.csv(
  "R:/43_Ryan_Loke/Side Projects/VolBrain/SCI_Metadata_FS.csv",
  sep=","
)

metadata <- data.frame(metadata_SCI)
```
Our metadata looks something like this, you may need to subset your dataframe
if necessary. 

| SubjectID | Cohort | Sex | Age |
|:----------|:---------------|:--------|:------|
| sub-001 | SCI_H | F | 57 |
| sub-002 | SCI_H | F | 35 |
| sub-003 | SCI_P | M | 64 |
| sub-004 | SCI_P | F | 52 |

Next, we have to append the metadata to the datasheets

```
#Append the two dataframes together but leave out the subjectID as it already exists

SCI_cortical <- cbind(metadata, SCI_cortical[,!(names(SCI_cortical) %in% "subject")])

colnames(SCI_cortical)

## [1] "SubjectID" "Cohort" "Sex" "Age" "lh_bankssts_NumVert"

#Append metadata to the subcortical dataframe

SCI_subcortical <- cbind(metadata, SCI_subcortial)

colnames(SCI_subcortical)

## [1] "SubjectID" "Cohort" "Sex" "Age" "Left.Lateral.Ventricle"


```

------------------------------------------------------------------------

## Analysis Preprocessing

------------------------------------------------------------------------

This script goes over 4 main analyses. Below is a table that goes over
the comparisons.If you have less cohorts (i.e. no individuals with SCI and no
neuropathic pain), you can compare your other group to controls. 

| Code | Comparison |
|:-------------|:------------------------------------------|
| PvH | Individuals with SCI and neuropathic pain, versus healthy individuals |
| nNPvH | Individuals with SCI but no neuropathic pain, versus healthy individuals |
| nNPvP | Individuals with SCI but no neuropathic pain, versus individuals with SCI and neuropathic pain |
| IvH | Individuals with SCI (both with neuropathic pain and without) versus healthy individuals |

### Subsetting dataframes for analysis

------------------------------------------------------------------------

We will be generating 4 dataframes, using the schematic `SCI_code` where
code will be one of the four codes referenced in the table above for
their respective analysis. This will subset our master data frame
`SCI_Data_wide` into four smaller datasheets containing only our
subjects of interest.

```         
SCI_PvH <- data.frame(SCI_cortical[SCI_cortical %in% c("SCI_P","SCI_H"), ])

SCI_nNPvH <- data.frame(SCI_cortical[SCI_cortical %in% c("SCI_nNP","SCI_H"), ])

SCI_nNPvP <- data.frame(SCI_cortical[SCI_cortical %in% c("SCI_nNP","SCI_P"), ])

SCI_IvH <- as.data.frame(SCI_cortical %>%
  mutate(Cohort = case_when(
    Cohort %in% c("SCI_P", "SCI_nNP") ~"SCI",
    TRUE ~ Cohort
  )))
```

Now we have 4 different data frames which will be used for our analyses.

## Analysis code skeleton

------------------------------------------------------------------------

Below is a skeleton of the analysis loop that will be run for each of
the 4 dataframes created in the previous step. You will need to change some
variables in this skeleton in order for it to work, but they have been
clearly marked by surrounding asterisks. 


```
# Name results to something specific, and replace dataframe with your working
# dataframe (e.g. SCI_PvH)

# The number 5 refers to the column where analyses start, it should be the 
# column index for lh_bankssts_Numvert

*results_PvH* <- lapply(colnames(*dataframe*)[5:ncol(*dataframe*)], 
                      function(region) {
  
  #Conducting t.test                      
  t_test <- t.test(*dataframe*[[region]] ~ *dataframe*$Cohort)
  
  #Creating temporary dataframe
  temp_df <- data.frame(
    value = *dataframe*[[region]],
    group = *dataframe*$Cohort
  )
  
  #Calculating effect size (hedge's g)
  g_result <- hedg_g(value ~ group, data = temp_df)
  g_value <- g_result$hedg_g[g_result$group_ref == "SCI_H" & g_result$group_foc == "SCI_P"]
  
  
  n1 <- sum(*dataframe*$Cohort == "SCI_H")
  n2 <- sum(*dataframe*$Cohort == "SCI_P")
  
  #Calculating standard error and confidence intervals
  se_g <- sqrt((n1 + n2) / (n1 * n2) + (g_value^2) / (2 * (n1 + n2)))
  ci_lower <- g_value - 1.96 * se_g
  ci_upper <- g_value + 1.96 * se_g
  
  #Combining everything together
  data.frame(
    Region = region,
    p_value = t_test$p.value,
    Mean_Group_SCI_H = mean(*dataframe*[[region]][*dataframe*$Cohort == "SCI_H"], na.rm = TRUE),
    SD_Group_SCI_H = sd(*dataframe*[[region]][*dataframe*$Cohort == "SCI_H"], na.rm = TRUE),
    N_Group1 = n1,
    Mean_Group2_SCI_P = mean(*dataframe*[[region]][*dataframe*$Cohort == "SCI_P"], na.rm = TRUE),
    SD_Group2_SCI_P = sd(*dataframe*[[region]][*dataframe*$Cohort == "SCI_P"], na.rm = TRUE),
    N_Group2 = n2,
    t_statistic = t_test$statistic,
    Hedges_g = g_value,
    SE_Hedges_g = se_g,
    CI_lower = ci_lower,
    CI_upper = ci_upper
  )
})

#Combine all elements in the results to a dataframe called summary.

*summary_PvH* <- do.call(rbind, *results*)

#exports the results into an xlsx file to your working directory. 
#please change code to match the analysis. e.g. PvH, nNPvH, etc. 

write_xlsx(*summary_PvH*, "SCI_*code*_results.xlsx")
```

------------------------------------------------------------------------

### Analysis code written out

------------------------------------------------------------------------

This chunk analyzes people with spinal cord injury and neuropathic pain
to people without spinal cord injury.

```         
PvH_results <- lapply(colnames(SCI_PvH)[5:ncol(SCI_PvH)], 
                      function(region) {
  
  t_test <- t.test(SCI_PvH[[region]] ~ SCI_PvH)
  
  temp_df <- data.frame(
    value = SCI_PvH[[region]],
    group = SCI_PvH$Cohort
  )
  
  g_result <- hedg_g(value ~ group, data = temp_df)
  g_value <- g_result$hedg_g[g_result$group_ref == "SCI_H" & g_result$group_foc == "SCI_P"]
  
  
  n1 <- sum(SCI_PvH$Cohort == "SCI_H")
  n2 <- sum(SCI_PvH$Cohort == "SCI_P")
  
  se_g <- sqrt((n1 + n2) / (n1 * n2) + (g_value^2) / (2 * (n1 + n2)))
  ci_lower <- g_value - 1.96 * se_g
  ci_upper <- g_value + 1.96 * se_g
  
  data.frame(
    Region = region,
    p_value = t_test$p.value,
    Mean_Group_SCI_H = mean(SCI_PvH[[region]][SCI_PvH$Cohort == "SCI_H"], na.rm = TRUE),
    SD_Group_SCI_H = sd(SCI_PvH[[region]][SCI_PvH$Cohort == "SCI_H"], na.rm = TRUE),
    N_Group1 = n1,
    Mean_Group2_SCI_P = mean(SCI_PvH[[region]][SCI_PvH$Cohort == "SCI_P"], na.rm = TRUE),
    SD_Group2_SCI_P = sd(SCI_PvH[[region]][SCI_PvH$Cohort == "SCI_P"], na.rm = TRUE),
    N_Group2 = n2,
    t_statistic = t_test$statistic,
    Hedges_g = g_value,
    SE_Hedges_g = se_g,
    CI_lower = ci_lower,
    CI_upper = ci_upper
  )
})


PvH_summary <- do.call(rbind, PvH_results)

write_xlsx(PvH_summary, "SCI_PvH_results.xlsx")
```

------------------------------------------------------------------------

This chunk analyzes individuals with spinal cord injury without
neuropathic pain, to controls

```
nnPvH_results <- lapply(colnames(SCI_nNPvH)[5:ncol(SCI_nNPvH)], 
                      function(region) {
  
  t_test <- t.test(SCI_nNPvH[[region]] ~ SCI_nNPvH$Cohort)
  
  temp_df <- data.frame(
    value = SCI_nNPvH[[region]],
    group = SCI_nNPvH$Cohort
  )
  
  g_result <- hedg_g(value ~ group, data = temp_df)
  g_value <- g_result$hedg_g[g_result$group_ref == "SCI_H" & g_result$group_foc == "SCI_nNP"]
  
  
  n1 <- sum(SCI_nNPvH$Cohort == "SCI_H")
  n2 <- sum(SCI_nNPvH$Cohort == "SCI_nNP")
  
  se_g <- sqrt((n1 + n2) / (n1 * n2) + (g_value^2) / (2 * (n1 + n2)))
  ci_lower <- g_value - 1.96 * se_g
  ci_upper <- g_value + 1.96 * se_g
  
  data.frame(
    Region = region,
    p_value = t_test$p.value,
    Mean_Group_SCI_H = mean(SCI_nNPvH[[region]][SCI_nNPvH$Cohort == "SCI_H"], na.rm = TRUE),
    SD_Group_SCI_H = sd(SCI_nNPvH[[region]][SCI_nNPvH$Cohort == "SCI_H"], na.rm = TRUE),
    N_Group1 = n1,
    Mean_Group2_SCI_nNP = mean(SCI_nNPvH[[region]][SCI_nNPvH$Cohort == "SCI_nNP"], na.rm = TRUE),
    SD_Group2_SCI_nNP = sd(SCI_nNPvH[[region]][SCI_nNPvH$Cohort == "SCI_nNP"], na.rm = TRUE),
    N_Group2 = n2,
    t_statistic = t_test$statistic,
    Hedges_g = g_value,
    SE_Hedges_g = se_g,
    CI_lower = ci_lower,
    CI_upper = ci_upper
  )
})


nNPvH_summary <- do.call(rbind, nnPvH_results)

write_xlsx(nNPvH_summary, "SCI_nNPvH_results.xlsx")
```

------------------------------------------------------------------------

This chunk compares individuals with spinal cord injury and neuropathic
pain, to individuals with spinal cord injury but without neuropathic
pain.

```         
nNPvP_results <- lapply(colnames(SCI_nNPvP)[5:ncol(SCI_nNPvP)], 
                      function(region) {
  
  t_test <- t.test(SCI_nNPvP[[region]] ~ SCI_nNPvP$Cohort)
  
  temp_df <- data.frame(
    value = SCI_nNPvP[[region]],
    group = SCI_nNPvP$Cohort
  )
  
  g_result <- hedg_g(value ~ group, data = temp_df)
  g_value <- g_result$hedg_g[g_result$group_ref == "SCI_P" & g_result$group_foc == "SCI_nNP"]
  
  
  n1 <- sum(SCI_nNPvP$Cohort == "SCI_P")
  n2 <- sum(SCI_nNPvP$Cohort == "SCI_nNP")
  
  se_g <- sqrt((n1 + n2) / (n1 * n2) + (g_value^2) / (2 * (n1 + n2)))
  ci_lower <- g_value - 1.96 * se_g
  ci_upper <- g_value + 1.96 * se_g
  
  data.frame(
    Region = region,
    p_value = t_test$p.value,
    Mean_Group_SCI_P = mean(SCI_nNPvP[[region]][SCI_nNPvP$Cohort == "SCI_P"], na.rm = TRUE),
    SD_Group_SCI_P = sd(SCI_nNPvP[[region]][SCI_nNPvP$Cohort == "SCI_P"], na.rm = TRUE),
    N_Group1 = n1,
    Mean_Group2_SCI_nNP = mean(SCI_nNPvP[[region]][SCI_nNPvP$Cohort == "SCI_nNP"], na.rm = TRUE),
    SD_Group2_SCI_nNP = sd(SCI_nNPvP[[region]][SCI_nNPvP$Cohort == "SCI_nNP"], na.rm = TRUE),
    N_Group2 = n2,
    t_statistic = t_test$statistic,
    Hedges_g = g_value,
    SE_Hedges_g = se_g,
    CI_lower = ci_lower,
    CI_upper = ci_upper
  )
})


nNPvP_summary <- do.call(rbind, nNPvP_results)

write_xlsx(nNPvP_summary, "SCI_nNPvP_results.xlsx")
```

------------------------------------------------------------------------

This last chunk compares all individuals with spinal cord injury (with
and without neuropathic pain) to individuals without spinal cord injury.

```         
IvH_results <- lapply(colnames(SCI_IvH)[5:ncol(SCI_IvH)], 
                      function(region) {
  
  t_test <- t.test(SCI_IvH[[region]] ~ SCI_IvH)
  
  temp_df <- data.frame(
    value = SCI_IvH[[region]],
    group = SCI_IvH$Cohort
  )
  
  g_result <- hedg_g(value ~ group, data = temp_df)
  g_value <- g_result$hedg_g[g_result$group_ref == "SCI_H" & g_result$group_foc == "SCI"]
  
  
  n1 <- sum(SCI_IvH$Cohort == "SCI_H")
  n2 <- sum(SCI_IvH$Cohort == "SCI")
  
  se_g <- sqrt((n1 + n2) / (n1 * n2) + (g_value^2) / (2 * (n1 + n2)))
  ci_lower <- g_value - 1.96 * se_g
  ci_upper <- g_value + 1.96 * se_g
  
  data.frame(
    Region = region,
    p_value = t_test$p.value,
    Mean_Group_SCI_H = mean(SCI_IvH[[region]][SCI_IvH$Cohort == "SCI_H"], na.rm = TRUE),
    SD_Group_SCI_H = sd(SCI_IvH[[region]][SCI_IvH$Cohort == "SCI_H"], na.rm = TRUE),
    N_Group1 = n1,
    Mean_Group2_SCI = mean(SCI_IvH[[region]][SCI_IvH$Cohort == "SCI"], na.rm = TRUE),
    SD_Group2_SCI = sd(SCI_IvH[[region]][SCI_IvH$Cohort == "SCI"], na.rm = TRUE),
    N_Group2 = n2,
    t_statistic = t_test$statistic,
    Hedges_g = g_value,
    SE_Hedges_g = se_g,
    CI_lower = ci_lower,
    CI_upper = ci_upper
  )
})


IvH_summary <- do.call(rbind, IvH_results)

write_xlsx(IvH_summary, "SCI_IvH_results.xlsx")
```

## Subcortical Volumes Analysis

------------------------------------------------------------------------

This analysis is going to be exactly the same as the previous one, just with
different dataframe names. You can copy paste the same data analysis loop
and replace the dataframe names, as well as choose different names for the 
summary and results dataframes. Include subcortical somewhere in the name
to better track subcortical vs cortical files.

------------------------------------------------------------------------

We will subset the data the same way again. The naming scheme
will remain the same (PvH, nNPvH, etc. for the comparisons), but the
first three letters will change to SUB to indicate we are doing a
subcortical analysis.

```         
SUB_PvH <- data.frame(SCI_subcortical[SCI_subcortical %in% c("SCI_P","SCI_H"), ])

SUB_nNPvH <- data.frame(SCI_subcortical[SCI_subcortical %in% c("SCI_nNP", "SCI_H"), ])

SUB_nNPvP <- data.frame(SCI_subcortical[SCI_subcortical %in% c("SCI_nNP", "SCI_P"), ])

SUB_IvH <- as.data.frame(SCI_subcortical %>%
  mutate(Cohort = case_when(
   Cohort %in% c("SCI_P", "SCI_nNP") ~"SCI",
   TRUE ~ Cohort
 )))
```

### Analysis

------------------------------------------------------------------------

You can refer to the skeleton or code above, and replace names as necessary. 
Make sure the naming scheme is clear as to what the results are referring to.
(e.g. Sub_PvH_summary, Sub_nNPvH_summary, Sub_nNPvP_summary, etc.). The same
loop will be run on these four dataframes, producing 4 csvs of results. 

------------------------------------------------------------------------

## White Matter Volumes Analysis

------------------------------------------------------------------------

Very similarly, we are going to run the same analysis with regional white
matter volumes. It will look very similar to before. We still start with 
importing the files. 


```
wm_mastersheet <- read.csv("R:/43_Ryan_Loke/Side Projects/Freesurfer_Analysis/wm_volumes.csv",
                        sep = ',')

#Then we append it to the metadata.

wm_volumes <- cbind(metadata, wm_mastersheet[,!(names(SCI_cortical) %in% "subjectID")])


```

Then using this mastersheet wm_volumes, we can subset it again into different
subgroups and rerun the same analysis pipeline again on these 4 datasets. 

```
wm_PvH <- data.frame(wm_volumes[wm_volumes %in% c("SCI_P","SCI_H"), ])

wm_nNPvH <- data.frame(wm_volumes[wm_volumes %in% c("SCI_nNP", "SCI_H"), ])

wm_nNPvP <- data.frame(wm_volumes[wm_volumes %in% c("SCI_nNP", "SCI_P"), ])

wm_IvH <- as.data.frame(wm_volumes %>%
  mutate(Cohort = case_when(
   Cohort %in% c("SCI_P", "SCI_nNP") ~"SCI",
   TRUE ~ Cohort
 )))

```

You may copy paste the same code as above and replace the names as necessary. 
Make sure to name the outputs something unique and identifiable for 
grouping purposes. These 4 analyses will produce 4 csvs for further analysis.

------------------------------------------------------------------------

## Conclusion

------------------------------------------------------------------------

That ends the first analysis for our big project. You can find all the
results within your project directory/folder that you created when you
first opened RStudio and began a new project. There should be 8 total
files if you had 3 cohorts to compare. Please email the results over to
[lokeryan\@student.ubc.ca](mailto:lokeryan@student.ubc.ca){.email} and
[john.kramer\@ubc.ca](mailto:john.kramer@ubc.ca){.email}. Thanks for
your help and we look forward to sending over the next steps of analyses
once finalized!
