**R Analysis**
### Step 9: Statistical Analysis for Structural Data 

Following compiling all the data necessary for analysis, we can then conduct analysis in R for all data. Below will be a rundown of the analyses, along with the necessary statistical outputs needed for the meta analysis. There is an attached R script that will take some modification to work. Below is a breakdown on how 

1. Working version of R and RStudio (same as above), with the following packages
   - tidyverse
   - data.table
   - multcomp
   - effsize
   - writexl
   - ggpubr
   - esvis
2. Freesurfer outputs compiled
   - Cortical measurments taken from the Desikan-Killiany atlas (different atlas as before)
   - Subcortical measurements from the aseg file (same as before)
   - Cortical thickness
   - Intracranial volume
   - WM Volumes

Once everything is order, you may refer to the RMarkdownScript for further details on how to run the analysis.The RMarkdown file `FreesurferAnalysisScript.Rmd` contains a full tutorial on how to get this running if you are unfamiliar with R/RStudio. If you are familiar with R/Rstudio, please feel free to skip around as you wish. Please feel free to contact us if there are any questions/comments/issues that you encounter. 

**Outputs**   

Following analysis you should end up with 14 .csv files which will be sent back to us for meta-analysis.

1. 4 .csv files comparing strucutral measurements between individuals with spinal cord injury (with and without neuropahtic pain) and healthy individuals.
2. 4 .csv files comparing subcortical volumes between individuals with spinal cord injury (with and without neuropathic pain) and healthy individuals.
3. 1 .csv summary file containing information on cortical thickness.
4. 1 .csv summary file containing information on intracranial volume.
5. 4 .csv files comparing white matter structure volumes between individuals with spinal cord injury (with and without neuropathic pain) and healthy individuals. 

These output files should be shared with the primary investigating group for the meta analysis of the data. 