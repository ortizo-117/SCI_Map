##### **Email**: <lokeryan@student.ubc.ca>

##### PhD Student 

###### Department of Anesthesiology, Pharmacology and Therapeutics, University of British Columbia, Vancouver, Canada 

###### International Collaborations on Repair Discoveries (ICORD), Vancouver, Canada

<script>
  addClassKlippyTo("pre.r, pre.markdown");
  addKlippy('left', 'top', '#8B0000', '1', 'Copy code', 'Copied!');
</script>

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

<table>
<colgroup>
<col style="width: 50%" />
<col style="width: 50%" />
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">File Name</th>
<th style="text-align: left;">Contents</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">cortical_stats_long.csv</td>
<td style="text-align: left;">Individual level structural cortical
statistics in long format.</td>
</tr>
<tr class="even">
<td style="text-align: left;">metadata.csv</td>
<td style="text-align: left;">The metadata for your study
population</td>
</tr>
<tr class="odd">
<td style="text-align: left;">subcortical_volumes.csv</td>
<td style="text-align: left;">Individual level volumetric values for
subcortical structures.</td>
</tr>
<tr class="even">
<td style="text-align: left;">ICV_data.csv</td>
<td style="text-align: left;">Individual level intracranial volume (ICV)
values</td>
</tr>
<tr class="odd">
<td style="text-align: left;">cortical_thickness.csv</td>
<td style="text-align: left;">Individual level, cortical thickness in
the left and right hemisphere.</td>
</tr>
</tbody>
</table>

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
language R, a language for statistical computing and graphics. When
first opening RStudio after downloading R, your setup will look
something like this.

![](C:/users/ryanl/OneDrive/Pictures/Screenshots/RSTUDIOoverview.png)

### Creating a new project

------------------------------------------------------------------------

When starting a new analysis for a project, you **always** want to start
a new project. First, hit ‘File’ -&gt; ‘New Project…’ -&gt; ‘New
Directory’ -&gt; ‘New Project’. You should see a window like this, and
name your project whatever you’d like to, and select the location of
where you want the folder to be created. Click ‘Create Project’.

![](C:/users/ryanl/OneDrive/Pictures/Screenshots/Settingup.png)

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

![](C:/users/ryanl/OneDrive/Pictures/Screenshots/workspace.png)

## Installing packages

------------------------------------------------------------------------

To start, we need to download and load some packages (dependencies)
necessary to process and analyze the data. The code
`install.packages("package_name")` installs the packages into your
RStudio system. Installing packages only needs to be done **once** for
every computer. Below are the packages used.

    install.packages("tidyverse")
    install.packages("data.table")
    install.packages("multcomp")
    install.packages("effsize")
    install.packages("writexl")
    install.packages("ggpubr")

### Loading the libraries

------------------------------------------------------------------------

Use `library(package_name)` to load the downloaded libraries, so you may
use their functions in your code. This needs to be done **every time you
close and reopen RStudio**. You can run code by highlighting all the
lines and pressing **Ctrl/Cmd + Enter**, or you may click the top line
of code, then press **Ctrl/Cmd + Enter** 5 times to run each line
separately.

    library(tidyverse)
    library(data.table)
    library(multcomp)
    library(effsize)
    library(writexl)
    library(ggpubr)

## Importing your data

------------------------------------------------------------------------

Next, we need to import the first .csv file for analysis. We will start
with `cortical_stats_long.csv`. Hit ‘File’ -&gt; ‘Import Dataset’ -&gt;
‘From Text (Base)’.

That will bring up a new window, where you can browse for the file on
your computer. Locate the .csv file which should be named
`cortical_stats_long.csv`, and click open. Wait for RStudio to detect
the data format. You may have to click “Yes” under the heading row.
Check the Data Frame window on the bottom right and make sure it matches
the picture below. Then hit ‘Import’.

![](C:/users/ryanl/OneDrive/Pictures/Screenshots/importing_data.png)

A new window will open up, displaying the entire imported data set. It
will also appear in your environment on the top right panel of the
screen.

### An alternative way to import data

------------------------------------------------------------------------

You can also use the following line of code to import the data. You will
need to **change the pathway** to fit your own system

    #If you use this method to import your data, make sure to change the file path to match your own machine. 

    cortical_stats_long <- read.csv(
      "R:/43_Ryan_Loke/Side Projects/Freesurfer_Analysis/cortical_stats_long.csv",
      sep =","
    )

    #This code allows you to see the first four columns of the dataframe. 
    head(cortical_stats_long)

    ##   Subject               Region Hemisphere      Measure    Value
    ## 1     167 G_and_S_frontomargin         lh         area 1055.000
    ## 2     167 G_and_S_frontomargin         lh       volume  744.000
    ## 3     167 G_and_S_frontomargin         lh    thickness 1681.000
    ## 4     167 G_and_S_frontomargin         lh thicknessstd    2.053
    ## 5     167 G_and_S_frontomargin         lh thickness.T1    0.549
    ## 6     167 G_and_S_frontomargin         lh     meancurv    0.127

## Setting up

------------------------------------------------------------------------

First, we need to create a dataframe that duplicates the data. This is
because we never want to edit the mastersheet, just in case we mess up,
and so we don’t have to import the data again. SCI\_Data is now our main
data frame.

    SCI_Data <- data.frame(cortical_stats_long)

### Freesurfer output rundown

------------------------------------------------------------------------

In case you were curious as to what some of these metrics mean, here is
a quick summary of all of them, and why we are choosing to look at it.

<table style="width:100%;">
<colgroup>
<col style="width: 30%" />
<col style="width: 35%" />
<col style="width: 35%" />
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">Variable Name</th>
<th style="text-align: left;">Meaning</th>
<th style="text-align: left;">Significance</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Area</td>
<td style="text-align: left;">Surface area (mm<sup>2</sup>)</td>
<td style="text-align: left;">Indicates spatial extent of cortex, often
changes with neurodegeneration</td>
</tr>
<tr class="even">
<td style="text-align: left;">Volume</td>
<td style="text-align: left;">Volume (mm<sup>3</sup>)</td>
<td style="text-align: left;">Reflects regional cortical mass, often
changes with neurodegeneration</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Thickness</td>
<td style="text-align: left;">Average cortical thickness (mm)</td>
<td style="text-align: left;">Indicates structural integrity of a
region, thinning is associated with aging/neurodegeneration</td>
</tr>
<tr class="even">
<td style="text-align: left;">Thicknessstd</td>
<td style="text-align: left;">Standard deviation of thickness</td>
<td style="text-align: left;">Thickness variability, higher variability
can indicate cortical remodeling or disease progression</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Thickness.T1</td>
<td style="text-align: left;">Cortical thickness measured from
T1-weighted intensities</td>
<td style="text-align: left;">Alternative validation metric for
thickness based on MRI intensity values</td>
</tr>
<tr class="even">
<td style="text-align: left;">Meancurv</td>
<td style="text-align: left;">Average mean curvature</td>
<td style="text-align: left;">Indicates folding patterns, abnormal
gyrification can be associated with neurodegenerative states</td>
</tr>
<tr class="odd">
<td style="text-align: left;">GausCurv</td>
<td style="text-align: left;">Average gaussian curvature of region</td>
<td style="text-align: left;">highlight convexity or concavity of
region, changes might indicate altered morphology</td>
</tr>
<tr class="even">
<td style="text-align: left;">FoldInd</td>
<td style="text-align: left;">Folding index (complexity)</td>
<td style="text-align: left;">Track gyrification patterns, can change
with certain neurological disorders</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Curvind</td>
<td style="text-align: left;">Curvature Index, a global measure of
curvature</td>
<td style="text-align: left;">Describes cortical shape, folding
abnormalities are tied to certain psychiatric conditions.</td>
</tr>
</tbody>
</table>

### Cohort labeling

------------------------------------------------------------------------

This walk-through also assumes your data has three cohorts, you may have
less, and thus may have to adjust what you analyze accordingly. These
are the names I will use in my metadata labeling, you may use your own
labels but please keep track of them!

<table>
<thead>
<tr class="header">
<th style="text-align: left;">Group</th>
<th style="text-align: left;">Code</th>
<th style="text-align: left;">Comment</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Healthy controls</td>
<td style="text-align: left;">SCI_H</td>
<td style="text-align: left;">Individuals without SCI</td>
</tr>
<tr class="even">
<td style="text-align: left;">SCI with neuropathic pain</td>
<td style="text-align: left;">SCI_P</td>
<td style="text-align: left;">Individuals with SCI and pain</td>
</tr>
<tr class="odd">
<td style="text-align: left;">SCI without neuropathic pain</td>
<td style="text-align: left;">SCI_nNP</td>
<td style="text-align: left;">Individuals with SCI, but no pain</td>
</tr>
<tr class="even">
<td style="text-align: left;">SCI combined</td>
<td style="text-align: left;">SCI</td>
<td style="text-align: left;">All individuals with an SCI, (SCI_P +
SCI_nNP)</td>
</tr>
</tbody>
</table>

------------------------------------------------------------------------

### Metadata labeling

------------------------------------------------------------------------

Import your metadata .csv or .xlsx into RStudio using either previously
described method. I have displayed the column names of my metadata
sheet, yours may look different so you may have to change some of the
code following.

    #If you are using this method to import your metadata csv/xlsx, please make sure to change the file pathway.

    metadata_SCI <- read.csv(
      "R:/43_Ryan_Loke/Side Projects/VolBrain/SCI_Metadata_FS.csv",
      sep=","
    )

    metadata <- data.frame(metadata_SCI)

    colnames(metadata)

    ## [1] "ID"   "code" "age"  "sex"

This will match your ID numbers from your `SCI_Data` dataframe to your
metadata labeling. Code in this case refers to the cohort labeling for
each individual subject. We also added sex and age to the `SCI_Data`
dataframe, you may choose to add other variables to your sheet, or omit
them if you don’t have them.

    SCI_Data <- SCI_Data %>%
      left_join(dplyr::select(metadata, ID, code, sex, age), by = c("Subject" = "ID"))

    colnames(SCI_Data)

    ## [1] "Subject"    "Region"     "Hemisphere" "Measure"    "Value"      "code"       "sex"        "age"

### Transforming to wide format

------------------------------------------------------------------------

Last step before processing is a transformation of the data frame from
long to wide format. The naming scheme we will adopt for the region will
go as `hemisphere_region_measure`. For example, the first region
`lh_G_and_S_frontomargin_area`, refers to the left hemisphere,
fronto-marginal gyrus (of Wernicke) and sulcus’ area.

[A full list of the parcellations analyzed can be found here with their
complete
names](https://pmc.ncbi.nlm.nih.gov/articles/PMC2937159/table/T1/)

    SCI_Data_wide <- SCI_Data %>%
      mutate(hemisphere_region_measure = paste(Hemisphere, Region, Measure, sep = "_")) %>%
      dplyr::select(-Region, -Hemisphere, -Measure) %>%
      pivot_wider(names_from = hemisphere_region_measure, values_from = Value)

The output in wide format should look something like this… (data is made
up). Data frame should also contain contain ~1336 columns (74 regions \*
2 hemispheres \* 9 measurements + 4 identifying columns). You can check
by using this line `ncol(SCI_Data_wide)` to check.

------------------------------------------------------------------------

<table>
<colgroup>
<col style="width: 13%" />
<col style="width: 17%" />
<col style="width: 17%" />
<col style="width: 17%" />
<col style="width: 17%" />
<col style="width: 17%" />
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">Subject</th>
<th style="text-align: left;">code</th>
<th style="text-align: left;">sex</th>
<th style="text-align: left;">age</th>
<th style="text-align: left;">lh_G_and_S_frontomargin_area</th>
<th style="text-align: left;">lh_G_and_s_frontomargin_volume</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">15</td>
<td style="text-align: left;">SCI_P</td>
<td style="text-align: left;">Male</td>
<td style="text-align: left;">24</td>
<td style="text-align: left;">1024</td>
<td style="text-align: left;">800</td>
</tr>
<tr class="even">
<td style="text-align: left;">16</td>
<td style="text-align: left;">SCI_P</td>
<td style="text-align: left;">Female</td>
<td style="text-align: left;">32</td>
<td style="text-align: left;">980</td>
<td style="text-align: left;">834</td>
</tr>
</tbody>
</table>

------------------------------------------------------------------------

## Analysis Preprocessing

------------------------------------------------------------------------

This script goes over 4 main analyses. Below is a table that goes over
the comparisons.

<table class="table" style="color: black; margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:left;">
Code
</th>
<th style="text-align:left;">
Comparison
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
PvH
</td>
<td style="text-align:left;width: 45em; ">
Individuals with SCI and neuropathic pain, versus healthy individuals
</td>
</tr>
<tr>
<td style="text-align:left;">
nNPvH
</td>
<td style="text-align:left;width: 45em; ">
Individuals with SCI but no neuropathic pain, versus healthy individuals
</td>
</tr>
<tr>
<td style="text-align:left;">
nNPvP
</td>
<td style="text-align:left;width: 45em; ">
Individuals with SCI but no neuropathic pain, versus individuals with
SCI and neuropathic pain
</td>
</tr>
<tr>
<td style="text-align:left;">
IvH
</td>
<td style="text-align:left;width: 45em; ">
Individuals with SCI (both with neuropathic pain and without) versus
healthy individuals
</td>
</tr>
</tbody>
</table>

### Subsetting dataframes for analysis

------------------------------------------------------------------------

We will be generating 4 dataframes, using the schematic `SCI_code` where
code will be one of the four codes referenced in the table above for
their respective analysis. This will subset our master data frame
`SCI_Data_wide` into four smaller datasheets containing only our
subjects of interest.

    SCI_PvH <- data.frame(SCI_Data_wide[SCI_Data_wide$code %in% c("SCI_P","SCI_H"), ])

    SCI_nNPvH <- data.frame(SCI_Data_wide[SCI_Data_wide$code %in% c("SCI_nNP","SCI_H"), ])

    SCI_nNPvP <- data.frame(SCI_Data_wide[SCI_Data_wide$code %in% c("SCI_nNP","SCI_P"), ])

    SCI_IvH <- as.data.frame(SCI_Data_wide %>%
      mutate(code = case_when(
        code %in% c("SCI_P", "SCI_nNP") ~"SCI",
        TRUE ~ code
      )))

Now we have 4 different data frames which will be used for our analyses.

## Analysis code skeleton

------------------------------------------------------------------------

Below is a skeleton of the analysis loop that will be run for each of
the 4 dataframes. You will need to change some variables in this
skeleton in order for it to work, but they have been clearly marked by
surrounding asterisks. Under the skeleton will be a table for what you
need to replace the variable with. Included are also comments in the
body of code showing exactly what each chunk is doing. Below this chunk
of code, I have also fully written out all analyses.

    #We will be storing results into a dataframe called *results*. 
    #Please change this name for every analysis conducted. 
    #The '5' in the first line of code means analyses will start on column 5.
    #Change this number if your data doesn't start on column 5. 

    *results* <- lapply(colnames(*dataframe*[5:ncol(*dataframe*)], 
                                    function(region) {
          
      #Conducting a t-test between groups (code), for each region. 
      t_test <- t.test(*dataframe*[[region]] ~ *dataframe*$code)
      
      #Conducting an effect size analysis between groups for each region. 
      d_result <- cohen.d(*dataframe*[[region]] ~ *dataframe*$code)
      d_value <- d_result$estimate
      
      #Finding the total number of individuals in each group. 
      #Group refers to the code from the cohort labeling such as, SCI_H, SCI_P and SCI_nNP. 
      #Please follow the example when labeling the groups. The letter before v is group 1. 
      #e.g. SCI_PvH -> group 1 = SCI_P, group 2 = SCI_H.    
      n1 <- sum(*dataframe*$code == "*group1*")
      n2 <- sum(*dataframe*$code == "*group2*")
      
      #Calculating standard error and confidence intervals of our effect size analysis. 
      #Nothing needs to be changed in these three lines. 
      se_d <- sqrt((n1 + n2) / (n1 * n2) + (d_value^2) / (2 * (n1 + n2)))
      ci_lower <- d_value - 1.96 * se_d
      ci_upper <- d_value + 1.96 * se_d
      
      #This is piecing all of the data together into one data frame.
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

    #Combine all elements in the results to a dataframe called summary.
    *summary* <- do.call(rbind, *results*)

    #reorder the summary by decreasing p value, this step is not necessary. 
    *summary* <- *summary*[order(*summary*$p_value),]

    #exports the results into an xlsx file to your working directory. 
    #please change code to match the analysis. e.g. PvH, nNPvH, etc. 
    write_xlsx(*summary*, "SCI_*code*_results.xlsx")

Here is a table of what you should change each variable to in the code
skeleton.

------------------------------------------------------------------------

<table>
<colgroup>
<col style="width: 35%" />
<col style="width: 35%" />
<col style="width: 28%" />
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">What it appears as in the skeleton</th>
<th style="text-align: left;">What you should change it to</th>
<th style="text-align: left;">example</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">results</td>
<td style="text-align: left;">code_results, where code is the particular
analysis you are conducting</td>
<td style="text-align: left;">PvH_results, nNPvH_results</td>
</tr>
<tr class="even">
<td style="text-align: left;">dataframe</td>
<td style="text-align: left;">The generated dataframe for a particular
analysis.</td>
<td style="text-align: left;">SCI_PvH, SCI_nNPvH</td>
</tr>
<tr class="odd">
<td style="text-align: left;">group1</td>
<td style="text-align: left;">The first group before the versus</td>
<td style="text-align: left;">SCI_PvH, group1 = SCI_P</td>
</tr>
<tr class="even">
<td style="text-align: left;">group2</td>
<td style="text-align: left;">The second group after the versus</td>
<td style="text-align: left;">SCI_PvH, group2 = SCI_H</td>
</tr>
<tr class="odd">
<td style="text-align: left;">summary</td>
<td style="text-align: left;">code_summary, where code is the analysis
you are conducting.</td>
<td style="text-align: left;">PvH_summary, nNPvH_summary</td>
</tr>
</tbody>
</table>

------------------------------------------------------------------------

### Analysis code written out

------------------------------------------------------------------------

This chunk analyzes people with spinal cord injury and neuropathic pain
to people without spinal cord injury.

    PvH_results <- lapply(colnames(SCI_PvH)[5:ncol(SCI_PvH)], 
                                    function(region) {
          
      t_test <- t.test(SCI_PvH[[region]] ~ SCI_PvH$code)
      
      d_result <- cohen.d(SCI_PvH[[region]] ~ SCI_PvH$code)
      d_value <- d_result$estimate
          
      n1 <- sum(SCI_PvH$code == "SCI_P")
      n2 <- sum(SCI_PvH$code == "SCI_H")
      
      se_d <- sqrt((n1 + n2) / (n1 * n2) + (d_value^2) / (2 * (n1 + n2)))
      ci_lower <- d_value - 1.96 * se_d
      ci_upper <- d_value + 1.96 * se_d
      
      data.frame(
        Region = region,
        p_value = t_test$p.value,
        Mean_Group1 = mean(SCI_PvH[SCI_PvH$code == "SCI_P", 
                                            region], na.rm = TRUE),
        Mean_Group2 = mean(SCI_PvH[SCI_PvH$code == "SCI_H", 
                                            region], na.rm = TRUE),
        t_statistic = t_test$statistic,
        Cohen_d = d_value,
        SE_Cohen_d = se_d,
        CI_lower = ci_lower,
        CI_upper = ci_upper
        )
    })


    PvH_summary <- do.call(rbind, PvH_results)

    PvH_summary <- PvH_summary[order(PvH_summary$p_value),]

    write_xlsx(PvH_summary, "SCI_PvH_results.xlsx")

------------------------------------------------------------------------

This chunk analyzes individuals with spinal cord injury without
neuropathic pain, to controls

    nNPvH_results <- lapply(colnames(SCI_nNPvH)[5:ncol(SCI_nNPvH)], 
                                    function(region) {
          
      t_test <- t.test(SCI_nNPvH[[region]] ~ SCI_nNPvH$code)
      
      d_result <- cohen.d(SCI_nNPvH[[region]] ~ SCI_nNPvH$code)
      d_value <- d_result$estimate
          
      n1 <- sum(SCI_nNPvH$code == "SCI_nNP")
      n2 <- sum(SCI_nNPvH$code == "SCI_H")
      
      se_d <- sqrt((n1 + n2) / (n1 * n2) + (d_value^2) / (2 * (n1 + n2)))
      ci_lower <- d_value - 1.96 * se_d
      ci_upper <- d_value + 1.96 * se_d
      
      data.frame(
        Region = region,
        p_value = t_test$p.value,
        Mean_Group1 = mean(SCI_nNPvH[SCI_nNPvH$code == "SCI_nNP", 
                                            region], na.rm = TRUE),
        Mean_Group2 = mean(SCI_nNPvH[SCI_nNPvH$code == "SCI_H", 
                                            region], na.rm = TRUE),
        t_statistic = t_test$statistic,
        Cohen_d = d_value,
        SE_Cohen_d = se_d,
        CI_lower = ci_lower,
        CI_upper = ci_upper
        )
    })

    nNPvH_summary <- do.call(rbind, nNPvH_results)

    nNPvH_summary <- nNPvH_summary[order(nNPvH_summary$p_value),]

    write_xlsx(nNPvH_summary, "SCI_nNPvH_results.xlsx")

------------------------------------------------------------------------

This chunk compares individuals with spinal cord injury and neuropathic
pain, to individuals with spinal cord injury but without neuropathic
pain.

    nNPvP_results <- lapply(colnames(SCI_nNPvP)[5:ncol(SCI_nNPvP)], 
                                    function(region) {
          
      t_test <- t.test(SCI_nNPvP[[region]] ~ SCI_nNPvP$code)
      
      d_result <- cohen.d(SCI_nNPvP[[region]] ~ SCI_nNPvP$code)
      d_value <- d_result$estimate
          
      n1 <- sum(SCI_nNPvP$code == "SCI_nNP")
      n2 <- sum(SCI_nNPvP$code == "SCI_P")
      
      se_d <- sqrt((n1 + n2) / (n1 * n2) + (d_value^2) / (2 * (n1 + n2)))
      ci_lower <- d_value - 1.96 * se_d
      ci_upper <- d_value + 1.96 * se_d
      
      data.frame(
        Region = region,
        p_value = t_test$p.value,
        Mean_Group1 = mean(SCI_nNPvP[SCI_nNPvP$code == "SCI_nNP", 
                                            region], na.rm = TRUE),
        Mean_Group2 = mean(SCI_nNPvP[SCI_nNPvP$code == "SCI_P", 
                                            region], na.rm = TRUE),
        t_statistic = t_test$statistic,
        Cohen_d = d_value,
        SE_Cohen_d = se_d,
        CI_lower = ci_lower,
        CI_upper = ci_upper
        )
    })

    nNPvP_summary <- do.call(rbind, nNPvP_results)

    nNPvP_summary <- nNPvP_summary[order(nNPvP_summary$p_value),]

    write_xlsx(nNPvP_summary, "SCI_nNPvP_results.xlsx")

------------------------------------------------------------------------

This last chunk compares all individuals with spinal cord injury (with
and without neuropathic pain) to individuals without spinal cord injury.

    IvH_results <- lapply(colnames(SCI_IvH)[5:ncol(SCI_IvH)], 
                                    function(region) {
          
      t_test <- t.test(SCI_IvH[[region]] ~ SCI_IvH$code)
      
      d_result <- cohen.d(SCI_IvH[[region]] ~ SCI_IvH$code)
      d_value <- d_result$estimate
          
      n1 <- sum(SCI_IvH$code == "SCI")
      n2 <- sum(SCI_IvH$code == "SCI_H")
      
      se_d <- sqrt((n1 + n2) / (n1 * n2) + (d_value^2) / (2 * (n1 + n2)))
      ci_lower <- d_value - 1.96 * se_d
      ci_upper <- d_value + 1.96 * se_d
      
      data.frame(
        Region = region,
        p_value = t_test$p.value,
        Mean_Group1 = mean(SCI_IvH[SCI_IvH$code == "SCI", 
                                            region], na.rm = TRUE),
        Mean_Group2 = mean(SCI_IvH[SCI_IvH$code == "SCI_H", 
                                            region], na.rm = TRUE),
        t_statistic = t_test$statistic,
        Cohen_d = d_value,
        SE_Cohen_d = se_d,
        CI_lower = ci_lower,
        CI_upper = ci_upper
        )
    })

    IvH_summary <- do.call(rbind, IvH_results)

    IvH_summary <- IvH_summary[order(IvH_summary$p_value),]

    write_xlsx(IvH_summary, "SCI_IvH_results.xlsx")

## Subcortical Volumes Analysis

------------------------------------------------------------------------

This analysis is going to be largely similar to the previous analysis,
so I won’t be going as in depth into the preparation and details of the
code, and will just write out the code with some comments. It follows
pretty much the exact same process as the previous analysis. I’d be
happy to answer any questions through email.

### Importing and Preprocessing

------------------------------------------------------------------------

Import the data and get rid of any columns that only contain zeros
(should just be a few).

    subcortical_volumes <- read.csv(
      "R:/43_Ryan_Loke/Side Projects/Freesurfer_Analysis/subcortical_volumes.csv",
      sep = '\t'
    )

    #Get rid of any columns that contain only zeros
    subcortical_volumes <- subcortical_volumes[ ,colSums(subcortical_volumes != 0) > 0]

Add the metadata after the first column and change the column name of
the first column.

    subcortical_volumes <- cbind(subcortical_volumes[ , 1, drop = F], metadata[c("code","sex","age")],
                                 subcortical_volumes[, -1, drop = F])

    colnames(subcortical_volumes)[1] <- "SubjectID"

We will be conducting the same four analyses for this dataset as well,
so we will be subsetting the data the same way again. The naming scheme
will remain the same (PvH, nNPvH, etc. for the comparisons), but the
first three letters will change to SUB to indicate we are doing a
subcortical analysis.

    SUB_PvH <- data.frame(subcortical_volumes[subcortical_volumes$code %in% c("SCI_P","SCI_H"), ])

    SUB_nNPvH <- data.frame(subcortical_volumes[subcortical_volumes$code %in% c("SCI_nNP", "SCI_H"), ])

    SUB_nNPvP <- data.frame(subcortical_volumes[subcortical_volumes$code %in% c("SCI_nNP", "SCI_P"), ])

    SUB_IvH <- as.data.frame(subcortical_volumes %>%
      mutate(code = case_when(
       code %in% c("SCI_P", "SCI_nNP") ~"SCI",
       TRUE ~ code
     )))

### Analysis

------------------------------------------------------------------------

This is the exact same skeleton code as before, just changing the
dataframe being used. The naming scheme is the same, just adding SUB in
front to indicated subcortical analysis. Here we are starting with
individuals with spinal cord injury and neuropathic pain versus
controls.

    SUB_PvH_results <- lapply(colnames(SUB_PvH)[5:ncol(SUB_PvH)], 
                                    function(region) {
          
      t_test <- t.test(SUB_PvH[[region]] ~ SUB_PvH$code)
      
      d_result <- cohen.d(SUB_PvH[[region]] ~ SUB_PvH$code)
      d_value <- d_result$estimate
          
      n1 <- sum(SUB_PvH$code == "SCI_P")
      n2 <- sum(SUB_PvH$code == "SCI_H")
      
      se_d <- sqrt((n1 + n2) / (n1 * n2) + (d_value^2) / (2 * (n1 + n2)))
      ci_lower <- d_value - 1.96 * se_d
      ci_upper <- d_value + 1.96 * se_d
      
      data.frame(
        Region = region,
        p_value = t_test$p.value,
        Mean_Group1 = mean(SUB_PvH[SUB_PvH$code == "SCI_P", 
                                            region], na.rm = TRUE),
        Mean_Group2 = mean(SUB_PvH[SUB_PvH$code == "SCI_H", 
                                            region], na.rm = TRUE),
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

------------------------------------------------------------------------

This chunk analyzes individuals with spinal cord injury without
neuropathic pain, to controls.

    SUB_nNPvH_results <- lapply(colnames(SUB_nNPvH)[5:ncol(SUB_nNPvH)], 
                                    function(region) {
          
      t_test <- t.test(SUB_nNPvH[[region]] ~ SUB_nNPvH$code)
      
      d_result <- cohen.d(SUB_nNPvH[[region]] ~ SUB_nNPvH$code)
      d_value <- d_result$estimate
          
      n1 <- sum(SUB_nNPvH$code == "SCI_nNP")
      n2 <- sum(SUB_nNPvH$code == "SCI_H")
      
      se_d <- sqrt((n1 + n2) / (n1 * n2) + (d_value^2) / (2 * (n1 + n2)))
      ci_lower <- d_value - 1.96 * se_d
      ci_upper <- d_value + 1.96 * se_d
      
      data.frame(
        Region = region,
        p_value = t_test$p.value,
        Mean_Group1 = mean(SUB_nNPvH[SUB_nNPvH$code == "SCI_nNP", 
                                            region], na.rm = TRUE),
        Mean_Group2 = mean(SUB_nNPvH[SUB_nNPvH$code == "SCI_H", 
                                            region], na.rm = TRUE),
        t_statistic = t_test$statistic,
        Cohen_d = d_value,
        SE_Cohen_d = se_d,
        CI_lower = ci_lower,
        CI_upper = ci_upper
        )
    })

    SUB_nNPvH_summary <- do.call(rbind, SUB_nNPvH_results)

    SUB_nNPvH_summary <- SUB_nNPvH_summary[order(SUB_nNPvH_summary$p_value),]

    write_xlsx(SUB_nNPvH_summary, "SUB_nNPvH_results.xlsx")

------------------------------------------------------------------------

This comparison is for individuals with spinal cord injury, without
neuropathic pain versus individuals with spinal cord injury with
neuropathic pain.

    SUB_nNPvP_results <- lapply(colnames(SUB_nNPvP)[5:ncol(SUB_nNPvP)], 
                                    function(region) {
          
      t_test <- t.test(SUB_nNPvP[[region]] ~ SUB_nNPvP$code)
      
      d_result <- cohen.d(SUB_nNPvP[[region]] ~ SUB_nNPvP$code)
      d_value <- d_result$estimate
          
      n1 <- sum(SUB_nNPvP$code == "SCI_nNP")
      n2 <- sum(SUB_nNPvP$code == "SCI_P")
      
      se_d <- sqrt((n1 + n2) / (n1 * n2) + (d_value^2) / (2 * (n1 + n2)))
      ci_lower <- d_value - 1.96 * se_d
      ci_upper <- d_value + 1.96 * se_d
      
      data.frame(
        Region = region,
        p_value = t_test$p.value,
        Mean_Group1 = mean(SUB_nNPvP[SUB_nNPvP$code == "SCI_nNP", 
                                            region], na.rm = TRUE),
        Mean_Group2 = mean(SUB_nNPvP[SUB_nNPvP$code == "SCI_P", 
                                            region], na.rm = TRUE),
        t_statistic = t_test$statistic,
        Cohen_d = d_value,
        SE_Cohen_d = se_d,
        CI_lower = ci_lower,
        CI_upper = ci_upper
        )
    })

    SUB_nNPvP_summary <- do.call(rbind, SUB_nNPvP_results)

    SUB_nNPvP_summary <- SUB_nNPvP_summary[order(SUB_nNPvP_summary$p_value),]

    write_xlsx(SUB_nNPvP_summary, "SUB_nNPvP_results.xlsx")

------------------------------------------------------------------------

Lastly, here we are comparing all individuals with spinal cord injury to
controls.

    SUB_IvH_results <- lapply(colnames(SUB_IvH)[5:ncol(SUB_IvH)], 
                                    function(region) {
          
      t_test <- t.test(SUB_IvH[[region]] ~ SUB_IvH$code)
      
      d_result <- cohen.d(SUB_IvH[[region]] ~ SUB_IvH$code)
      d_value <- d_result$estimate
          
      n1 <- sum(SUB_IvH$code == "SCI")
      n2 <- sum(SUB_IvH$code == "SCI_H")
      
      se_d <- sqrt((n1 + n2) / (n1 * n2) + (d_value^2) / (2 * (n1 + n2)))
      ci_lower <- d_value - 1.96 * se_d
      ci_upper <- d_value + 1.96 * se_d
      
      data.frame(
        Region = region,
        p_value = t_test$p.value,
        Mean_Group1 = mean(SUB_IvH[SUB_IvH$code == "SCI", 
                                            region], na.rm = TRUE),
        Mean_Group2 = mean(SUB_IvH[SUB_IvH$code == "SCI_H", 
                                            region], na.rm = TRUE),
        t_statistic = t_test$statistic,
        Cohen_d = d_value,
        SE_Cohen_d = se_d,
        CI_lower = ci_lower,
        CI_upper = ci_upper
        )
    })

    SUB_IvH_summary <- do.call(rbind, SUB_IvH_results)

    SUB_IvH_summary <- SUB_IvH_summary[order(SUB_IvH_summary$p_value),]

    write_xlsx(SUB_IvH_summary, "SUB_IvH_results.xlsx")

## Quick ICV Summary

------------------------------------------------------------------------

For this analysis, we are just going to examine ICV differences between
groups. This section will be much quicker. Since I have gone over most
of the functions beforehand, I will just include the entire code below
with some comments. We are not conducting any comparative analyses here,
just summarizing group ICV values, along with their standard deviation,
and exporting those statistics into a .xslx file.

    #Import the data. You will have to change the path to your own file.

    ICV_data <- read.csv(
      "R:/43_Ryan_Loke/Side Projects/Freesurfer_Analysis/ICV_data.csv",
      sep = ","
    )

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

## Quick Cortical Thickness Summary

------------------------------------------------------------------------

Last quick summary analysis, this one looks to aggergate cortical
thickness data and export the data into a .xlsx file. This is the exact
same as the previous code chunk, but with a few extra lines to
compensate for left and right hemisphere.

    #Import the data. You will have to change the path to your own file.

    CT_data <- read.csv(
      "R:/43_Ryan_Loke/Side Projects/Freesurfer_Analysis/cortical_thickness_test.csv",
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

------------------------------------------------------------------------

## Conclusion

------------------------------------------------------------------------

That ends the first analysis for our big project! You can find all the
results within your project directory/folder that you created when you
first opened RStudio and began a new project. There should be 9 total
files if you had 3 cohorts to compare. Please email the results over to
<lokeryan@student.ubc.ca> and <john.kramer@ubc.ca>. Thanks for your help
and we look forward to sending over the next steps of analyses once
finalized!
