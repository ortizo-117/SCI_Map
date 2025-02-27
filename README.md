# SCI MAP
## Project Description

SCI_MAP is designed to analyze structural brain differences between individuals with spinal cord injury and healthy age-matched controls. The project has two main objectives:

1. Compare structural brain characteristics between SCI patients and healthy controls
2. Investigate structural brain changes in SCI patients who develop neuropathic pain

![SCI_MAP Study Banner](assets/study_banner.png)



## Prerequisites

To participate in this project, you need:

1. **Neuroimaging Data**
   - 3D T1-weighted MRI scans
   - Data must be organized in BIDS format
   - Both SCI and control cohort scans

2. **Software Requirements**
   - FreeSurfer (installed and operational)
   - Python dependencies (listed in requirements.txt)

3. **Metadata Requirements**
   - Subject ID
   - Age
   - Cohort designation (SCI or Control)
   - Neuropathic pain status for SCI participants

## Data Structure

Your data should be organized following BIDS conventions: 

## Repository Purpose and Processing Pipeline

This repository serves as a centralized location for sharing processing scripts with all participating institutes in the SCI_MAP project. The standardized scripts ensure consistent analysis across different sites and datasets.

![SCI_MAP Workflow](assets/workflow.png)

### Step 1: FreeSurfer Processing (reconall.sh)

**Note:** If you have already run FreeSurfer's recon-all on your data, you can skip this step and proceed directly to Step 2. However, ensure you have a working FreeSurfer installation as it will be required for Step 3.

The initial processing step uses the `reconall.sh` script located in the processing folder. This script can be run on:
- Linux systems
- Windows systems using Windows Subsystem for Linux (WSL)
  - Recommended: Ubuntu on WSL
  - Make sure FreeSurfer is properly installed in your WSL environment

The script:

1. Takes BIDS-formatted T1w images as input
2. Applies FreeSurfer's `recon-all` command to perform:
   - Skull stripping
   - White matter segmentation
   - Surface reconstruction
   - Cortical parcellation
   - Subcortical segmentation
3. Generates structural information for subsequent analysis

**System Requirements:**
- For Windows users: WSL installed with Ubuntu distribution
- FreeSurfer properly configured in your Linux/WSL environment
- Sufficient disk space for FreeSurfer outputs (~1GB per subject)

#### Usage
1. Open the `reconall.sh` script and update the directory paths:
   ```bash
   # Update these paths in reconall.sh
   RAWDATA_DIR="/path/to/your/bids/dataset"      # Directory containing your BIDS-formatted T1w images
   DERIVATIVES_DIR="/path/to/output/derivatives"  # Directory where FreeSurfer outputs will be saved
   ```

2. Make the script executable and run it:
   ```bash
   chmod +x processing/reconall.sh
   ./processing/reconall.sh
   ```

**Error Handling Tip:**
If you encounter script execution errors, especially when running on WSL or after editing on Windows, you may need to fix line endings using dos2unix:
```bash
# Install dos2unix if not already installed
sudo apt-get install dos2unix

# Convert the script to Unix format
dos2unix processing/reconall.sh
```
This fixes the "bad interpreter" or similar errors caused by Windows-style line endings (CRLF).

The script will:
- Process all subjects found in your BIDS directory
- Create a FreeSurfer output directory for each subject
- Generate logs in the derivatives directory

**Example Directory Structure:**
```
study/
├── rawdata/                  # Your RAWDATA_DIR
│   ├── sub-001/
│   │   └── anat/
│   │       └── sub-001_T1w.nii.gz
│   └── sub-002/
│       └── anat/
│           └── sub-002_T1w.nii.gz
└── derivatives/              # Your DERIVATIVES_DIR
    └── freesurfer/
        ├── sub-001/
        └── sub-002/
```

#### Processing Time
- Approximately 20 minutes per subject (benchmarked on NVIDIA 4070Ti)

### Step 2: Quality Assurance

Quality control of the FreeSurfer outputs is performed using the ENIGMA QA pipeline. This step uses the `enigma_fs_wrapper_script.sh` (run from WSL or Linux command terminal) which has been modified from the original ENIGMA-FreeSurfer-protocol-main to work with both Windows and Linux paths. The script must be executed in a WSL or Linux terminal environment, even when working with Windows paths.

#### Prerequisites
1. **MATLAB Requirements:**
   - MATLAB R2023a or older installed
   - Image Processing Toolbox
   - Statistics and Machine Learning Toolbox

2. **Subject List File:**
   Create a text file (e.g., `subject_ids.txt`) containing one subject ID per line:
   ```text
   sub-001
   sub-002
   sub-003
   ```
   **Note:** Subject IDs must match the FreeSurfer output directory names

3. **FreeSurfer Outputs:**
   - Completed FreeSurfer processing for all subjects
   - Standard FreeSurfer directory structure
   - Required files:
     - `mri/orig_nu.mgz`
     - `mri/aparc+aseg.mgz`

**Important Updates:**
- Script has been modified to handle Windows/WSL and Linux paths automatically
- Path conversion has been tested with MATLAB R2023a
- MATLAB functions are compatible with both Windows and Linux environments
- Automatic path conversion between WSL and Windows formats for MATLAB calls

#### Usage Example
```bash
./enigma_fs_wrapper_script.sh \
  --subjects "/mnt/c/Users/kramerlab/Documents/freesurfer_SCI_extra_subjects/results_pybrain/subject_ids.txt" \
  --fsdir "/mnt/c/Users/kramerlab/Documents/freesurfer_SCI_extra_subjects/derivatives" \
  --outdir "/mnt/c/Users/kramerlab/Documents/freesurfer_SCI_extra_subjects/ENIGMA_outputs" \
  --script "/mnt/c/Users/kramerlab/Documents/SCI_Map/ENIGMA-FreeSurfer-protocol-main" \
  --matlab "/mnt/c/Program Files/MATLAB/R2023a/bin/matlab.exe" \
  --fs7 true \
  --step_1 true \
  --step_2 true \
  --step_3 true \
  --step_4 true \
  --step_5 true
```

#### Script Arguments
- `--subjects`: Text file containing list of subject IDs
- `--fsdir`: Directory containing FreeSurfer processed subjects
- `--outdir`: Directory where QA outputs will be saved
- `--script`: Path to the ENIGMA scripts directory (parent folder of ENIGMA_QC)
- `--matlab`: Path to MATLAB executable
- `--fs7`: Set to 'true' if using FreeSurfer 7+, 'false' otherwise
- `--step_1`: Extract subcortical measures (set to true) 
- `--step_2`: Extract cortical measures (set to true)
- `--step_3`: Generate subcortical QC images (set to true)
- `--step_4`: Generate internal cortical QC images (set to true)
- `--step_5`: Generate external cortical QC images (set to true)

#### QA Pipeline Steps
1. **Subcortical Measures (step_1)**
   - Extracts volumes of subcortical structures
   - Generates CSV file with measurements

2. **Cortical Measures (step_2)**
   - Extracts cortical thickness and surface area
   - Creates separate files for thickness and surface metrics

3. **Subcortical QC (step_3)**
   - Generates visualization of subcortical segmentations
   - Creates HTML report for visual inspection

4. **Internal Cortical QC (step_4)**
   - Generates internal view of cortical parcellation
   - Creates HTML report for reviewing internal boundaries

5. **External Cortical QC (step_5)**
   - Generates external surface views
   - Creates HTML report for surface quality review

#### Output Structure
```
ENIGMA_outputs/
├── measures/
│   ├── LandRvolumes.csv
│   ├── CorticalMeasuresENIGMA_ThickAvg.csv
│   └── CorticalMeasuresENIGMA_SurfAvg.csv
└── qc/
    ├── subcortical/
    │   └── ENIGMA_Subcortical_QC.html
    ├── cortical_internal/
    │   └── ENIGMA_Cortical_QC.html
    └── cortical_external/
        └── ENIGMA_External_QC.html
```

**Note:** For Windows/WSL users, make sure to:
1. Use Windows paths for MATLAB executable
2. Use WSL paths for other arguments
3. Ensure MATLAB can access the ENIGMA_QC functions

**Quality Assessment Process:**
After generating the QC HTML files, visual inspection of the segmentations should be performed following the ENIGMA Cortical Quality Control Guide 2.0 [available here](https://enigma.ini.usc.edu/protocols/imaging-protocols/). 

Common QC Issues to Look For:

1. **Subcortical Segmentation Issues:**
   - Incorrect boundary definitions
   - Missing structures
   - Asymmetrical segmentation between hemispheres
   - Unusual shapes or volumes in subcortical structures

2. **Cortical Surface Problems:**
   - Skull strip failures (remaining dura/skull)
   - White matter segmentation errors
   - Pial surface overestimation
   - Missing gyri or sulci
   - Topological defects

3. **Motion Artifacts:**
   - Blurring or ringing in the original T1
   - Distorted segmentation due to movement
   - Inconsistent tissue boundaries

4. **Intensity Issues:**
   - Poor gray/white matter contrast
   - Intensity normalization failures
   - Bias field artifacts affecting segmentation

Follow the ENIGMA protocol guidelines to:
- Rate each scan's quality (Pass/Fail)
- Document specific issues found
- Make consistent decisions about subject exclusion
- Record QC decisions in a standardized format

Review each subject's QC HTML files thoroughly before proceeding to the next step. When in doubt, consult the detailed examples in the ENIGMA Cortical Quality Control Guide.

#### Example QC Outputs

**Subcortical QC HTML Example (step 3):**
![Example Subcortical QC](assets/example_qa_subcortical_vol.png)

**Internal Cortical QC HTML Example (step 4):**
![Example Cortical QC](assets/example_qa_cortical.png)

**External Cortical QC HTML Example (step 5):**
![Example Cortical QC](assets/example_qa_cortical_external.png)



These HTML files provide interactive views of the segmentation results for detailed quality assessment. Use them in conjunction with the ENIGMA QC guidelines to evaluate segmentation quality.
### Cortical Outlier Detection and Subcortical Histogram Plots

After visual QC, statistical quality control is performed using R scripts to generate histograms and identify potential outliers in the volumetric data.

#### Prerequisites

Before running the outlier detection and histogram analysis scripts, ensure you have:

1. **R and RStudio Installation**
   - A working installation of R (tested with version 4.4.0)
   - RStudio IDE (recommended for easier workflow)
   - The scripts in this repository were specifically tested with R version 4.4.0

2. **Required R Packages**
   - readr
   - dplyr
   These will be automatically installed if missing when running the scripts.

**Subcortical Histogram Analysis:**
The `subcortical_histogram_plots.R` script:

1. **Generates Histograms and Statistics**
   - Creates histograms for each subcortical structure (21 plots)
   - Generates an additional histogram for ICV (1 plot) 
   - Outputs summary statistics for each region in SummaryStats.txt
   - Calculates asymmetry measures between left/right structures

2. **Quality Control Features**
   - Handles missing values marked with 'x' or 'X'
   - Checks for negative volumes that may indicate segmentation errors
   - Reports number of subjects marked as poorly segmented for each structure
   - Helps identify statistical outliers needing additional review

3. **Output Files**
   - PNG histogram plots for each structure and ICV
   - SummaryStats.txt containing:
     - Number of subjects excluded
     - Sample size used
     - Mean volume
     - Standard deviation
   - Asymmetry measures between bilateral structures
   - ENIGMA_Plots.RData storing plot data

4. **Statistical Measures**
   - Calculates basic statistics (mean, SD) for each structure
   - Computes bilateral averages for paired structures
   - Generates asymmetry indices using (L-R)/(L+R) formula
   - Adapts histogram bins based on sample size

The `subcortical_histogram_plots.R` script requires editing the following paths:

Lines 25-26 to your ENIGMA_outputs/measures/LandRvolumes.csv file and the output directory:
```R
input_path <- "C:/Users/kramerlab/Documents/freesurfer_SCI_extra_subjects/ENIGMA_outputs/measures/LandRvolumes.csv"
output_dir <- "C:/Users/kramerlab/Documents/freesurfer_SCI_extra_subjects/ENIGMA_outputs/measures"
```

**Cortical Outlier Detection:**
The `cortical_outliers.R` script performs outlier detection on cortical thickness and surface area measurements.
- Outputs in the R console messages about the structures from subjects marked as outliers.
- Gives you an idea of which areas and which subjects are potentially problematic and could be flagged for exclusion

The `cortical_outliers.R` script requires editing the following paths:

Lines 5 and 37 to point to your ENIGMA_outputs/measures/CorticalMeasuresENIGMA_ThickAvg.csv and CorticalMeasuresENIGMA_SurfAvg.csv files:

```R
dat=read.csv("C:/Users/kramerlab/Documents/freesurfer_SCI_extra_subjects/ENIGMA_outputs/measures/CorticalMeasuresENIGMA_ThickAvg.csv",stringsAsFactors=FALSE)
dat=read.csv("C:/Users/kramerlab/Documents/freesurfer_SCI_extra_subjects/ENIGMA_outputs/measures/CorticalMeasuresENIGMA_SurfAvg.csv",stringsAsFactors=FALSE)
```


### Recording QC Results

The ENIGMA protocol provides a standardized Excel template (ENIGMA_Cortical_QC_Template.xlsx) for recording QC decisions. To use this template:

1. **Open the Template**
   - Make a copy of ENIGMA_Cortical_QC_Template.xlsx for your study
   - Save it with a descriptive name (e.g., "SCI_MAP_QC_Results.xlsx")

2. **Fill in Required Fields**
   - Subject ID: Enter the subject identifier exactly as used in FreeSurfer
   - Pass/Fail: Mark as:
     - PASS (1) - Acceptable quality
     - FAIL (0) - Unusable due to quality issues
   - Notes: Document specific issues observed, such as:
     - "Significant dura inclusion in left temporal lobe"
     - "Motion artifacts affecting subcortical segmentation"
     - "Poor gray/white matter contrast in occipital region"

3. **Additional Columns**
   - Rating Confidence (1-3):
     1. Low confidence
     2. Medium confidence
     3. High confidence
   - Specific Issue Flags:
     - Motion_Artifact (0/1)
     - Skull_Strip_Error (0/1)
     - WM_Segmentation_Error (0/1)
     - Pial_Overestimation (0/1)

4. **Best Practices**
   - Complete the QC spreadsheet while viewing the QC HTML files
   - Be consistent in your rating criteria across subjects
   - When in doubt, consult the ENIGMA QC guide examples
   - Regular backups of the QC spreadsheet are recommended

The completed QC spreadsheet will be essential for:
- Tracking which subjects to include/exclude in analyses
- Documenting quality issues for methods sections
- Sharing QC decisions with collaborators
- Future reference and reproducibility


### Step 3: Data Organization for Brain Age Prediction (aparc_aseg_pybrain.sh)

After FreeSurfer processing and quality assurance, the next step involves organizing the structural data into a format compatible with PyBrain for brain age prediction analysis. 

**Prerequisites:**
- Completed FreeSurfer processing (from Step 1 or pre-existing)
- Working FreeSurfer installation (required for reading FreeSurfer outputs)
- FreeSurfer environment properly configured

This step uses the `aparc_aseg_pybrain.sh` script, which:

1. Extracts relevant metrics from FreeSurfer's aparc and aseg outputs
2. Organizes the data into a standardized format required by PyBrain
3. Generates a consolidated dataset for brain age prediction

#### Usage
1. Open the `aparc_aseg_pybrain.sh` script and update the directory paths:
   ```bash
   # Update these paths in aparc_aseg_pybrain.sh
   ROOT_DIR="/path/to/your/freesurfer/subjects"    # Directory containing FreeSurfer processed subjects
   OUTPUT_DIR="/path/to/save/pybrain/features"     # Directory where the output CSV will be saved
   ```

2. Make the script executable and run it:
   ```bash
   chmod +x processing/aparc_aseg_pybrain.sh
   ./processing/aparc_aseg_pybrain.sh
   ```

**Note:** Like the reconall.sh script, this can be run on:
- Linux systems
- Windows systems using WSL (Ubuntu recommended)

**Error Handling Tip:**
If you encounter script execution errors, fix line endings using dos2unix:
```bash
dos2unix processing/aparc_aseg_pybrain.sh
```

The script will generate a CSV file containing all the required features for brain age prediction.

### Step 4: Age Data Integration

The final preparation step involves manually adding participant age information to your dataset:

1. Open the output file from Step 3
2. Add a new column for age as the second column (right after subject ID)
3. Save the file as 'subject_features.csv' with the following structure:

subject_id,age,feature1,feature2,...

### Step 5: Brain Age Prediction

Use the `predict.py` script to generate brain age predictions for your cohort using the PyBrain model:

#### Required Path Configuration
Before running the prediction script, you need to modify the following paths in `predict.py`:

1. `age_data_path`: Path to your subject_features.csv file
   ```python
   age_data_path = "/path/to/your/subject_features.csv"
   ```

2. `model_path`: Path to the ExtraTreesModel file
   ```python
   model_path = "/path/to/PyBrainAge-main/software/ExtraTreesModel"
   ```

3. `scaler_path`: Path to the scaler.pkl file
   ```python
   scaler_path = "/path/to/PyBrainAge-main/software/scaler.pkl"
   ```

**Important Note:** Due to file size limitations, the ExtraTreesModel and scaler files are not directly stored in this repository. To obtain these files:

1. Download them from the original PyBrain repository:
   - Visit https://github.com/james-cole/PyBrainAge
   - Navigate to the software directory
   - Download ExtraTreesModel and scaler.pkl files

2. Place the files in your local SCI_MAP directory:
   ```
   SCI_MAP/
   └── PyBrainAge-main/
       └── software/
           ├── ExtraTreesModel
           └── scaler.pkl
   ```

3. Update the paths in your predict.py script accordingly

**Python Environment Setup:**
The ExtraTreesModel and scaler.pkl files were built using specific Python dependencies. To ensure compatibility:

1. Create a new conda environment following PyBrain's requirements:
   ```bash
   conda create  --name pybrainage_env python=3.7 scikit-learn=0.24.2 pandas=1.3.4 numpy=1.20.3
   conda activate pybrainage_env 
   ```


2. Install the required dependencies as specified in the PyBrain repository:
   - Follow the installation steps at https://github.com/james-cole/PyBrainAge
   - This ensures correct versions of scikit-learn, pandas, and other dependencies

**Note:** Using different Python versions or package versions may cause compatibility issues when loading the model and scaler files.

If you have trouble accessing these files, please contact:
- The original PyBrain repository maintainers
- The SCI_MAP project coordinators


## Merging the data with the clinical data


To merge your brain age predictions with clinical data, use the provided template file 'Template_Analysis.xlsx'. This template helps organize the data for the analysis.

### Template Structure
The 'Template_Analysis.xlsx' file contains the following columns:

1. **Required Fields:**
   - Subject_ID: Unique identifier for each participant (e.g. "190")
   - Age: Chronological age in years
   - Sex: Male/Female
   - Cohort: control/SCI_nNP/SCI_P (Control, SCI without pain, SCI with pain)
   - BrainAge: Predicted brain age from PyBrain (from predicted_results.csv)
   - BrainPAD: Brain-Predicted Age Difference (from predicted_results.csv)

2. **SCI-Specific Fields:**
   - AIS: ASIA Impairment Scale grade (A/B/C/D)
   - Time since SCI (years): Duration since injury (Numeric)


### Steps to Merge Data

1. Open the Template_Analysis.xlsx file
2. Copy your brain age predictions from PyBrain's output
3. Add corresponding clinical data for each participant
4. Ensure consistent formatting:
   ```
   - Use consistent Subject_ID format
   - Enter numerical values without units
   - Use standardized text for categorical variables
   ```

5. Save the completed template in your analysis directory

**Note:** The Analysis of BrainPAD.py script expects data in this template format. Deviating from the template structure may cause analysis errors.

## Analyzing and Visualizing Brain Age Results

This section explains how to analyze and visualize brain age prediction results. The provided scripts generate statistical summaries and visualizations to help understand brain age differences between cohorts.

The visualization script ('Analysis of BrainPAD.py') creates various plots and statistical comparisons to help interpret your results.

### Setup and Usage
1. Configure the file paths in the script:
   ```python
   # Update these paths in Analysis of BrainPAD.py:
   PyB_path = "/path/to/your/predicted_results.xlsx"  # Excel file containing brain age predictions
   output_path1 = "/path/to/output/summary_statistics.csv"  # CSV file for summary statistics
   output_path2 = "/path/to/output/BrainPAD_comparison.png"  # Plot comparing BrainPAD across cohorts
   output_path3 = "/path/to/output/Chronological_vs_BrainAge.png"  # Plot comparing chronological vs predicted brain age
   output_path4 = "/path/to/output/BrainPAD_vs_Age.png"  # Plot showing BrainPAD vs age relationship
   output_path5 = "/path/to/output/BrainPAD_across_sex.png"  # Plot showing sex-specific BrainPAD comparisons
   output_path6 = "/path/to/output/BrainPAD_vs_TimeSinceInjury.png"  # Plot showing BrainPAD vs injury duration + correlation
   output_path7 = "/path/to/output/BrainPAD_across_cohorts.csv"  # Statistical results for cohort comparisons
   output_path8 = "/path/to/output/BrainPAD_across_sex.csv"  # Statistical results for sex-specific analyses
   output_path9 = "/path/to/output/BrainPAD_acorss_AIS.csv" # Statistical results for AIS-specific comparison
   output_path10 = "/path/to/output/Chi2_AIS.csv" # Statistical results for AIS-specific comparison
   output_path11 = "/path/to/output/TimeSinceInjury_Comparison.csv" # Statistical results for Time since Injury comparison
   output_path12 = "/path/to/output/ChronologicalAge_Comparison.csv" # Statistical results for chronological age comparison
   ```

2. Run the script using the terminal/command prompt:
   
   Using Terminal/Command Prompt:
   ```bash
   python "Analysis of BrainPAD.py"
   # Note: Use quotes around filename since it contains spaces
   ```

   Or using PyCharm IDE:
   - Open Analysis of BrainPAD.py in PyCharm
   - Click the green "Run" button or press Shift+F10
   - The script will execute in PyCharm's integrated terminal

   Note: This script was originally developed and tested in PyCharm IDE, so running it through PyCharm is recommended to ensure consistent behavior.
   ```

### Generated Outputs

#### 1. Summary Statistics
The following statistics are generated based on what variables are included in your dataset:
- Participant counts per cohort
- Age statistics (mean, SD)
- BrainPAD statistics (mean, SD) 
- BrainAge statistics (mean, SD)
- Gender distribution
- AIS distribution (for SCI cohorts)
- Time since injury (for SCI cohorts)


#### 2. Visualizations
The script generates five key visualizations:

**a. BrainPAD Distribution**
- Boxplot comparing Brain-Predicted Age Difference across cohorts
- Individual data points overlay
- Cohort means marked with black triangles
- Color-coded by group (Control: Light Blue, SCI without pain: Light Orange, SCI with pain: Light Green)

**b. Age Comparison Plot**
- Scatter plot of chronological vs. predicted brain age
- Reference line showing perfect prediction
- Color-coded by cohort

**c. Age Trends Analysis**
- BrainPAD plotted against chronological age
- Separate trend lines for each cohort
- Individual data points color-coded by cohort

**d. Sex-Specific Analysis**
- Side-by-side boxplots showing BrainPAD distribution for males and females
- Separate plots for each sex showing cohort comparisons
- Individual data points overlay
- Color-coded by cohort

**e. Time Since Injury Analysis**
- BrainPAD plotted against time since injury for SCI participants
- Separate trend lines for each SCI cohort
- Statistical annotations including test results, p-values and effect sizes
- Regression statistics (R² and p-value)

#### 3. Statistical Analysis

The script performs comprehensive statistical testing:

**a. Distribution Analysis**
- Normality testing using Shapiro-Wilk and Kolmogorov-Smirnov tests
- Automatic selection of parametric (t-test) vs non-parametric (Mann-Whitney U) methods

**b. Group Comparisons**

*Overall Cohort Analysis:*
- Pairwise comparisons between all cohorts (Controls, SCI with/without pain)
- Effect sizes using Cohen's d (for normal distributions) or Cliff's delta (for non-normal)
- Sample sizes reported for each comparison

*Sex-Specific Analysis:* 
- Separate male/female comparisons between all cohorts
- Effect sizes calculated for each comparison
- Sample sizes included

*Injury Analysis:*
- Chi-square test for AIS distribution between SCI cohorts
- Comparison of Time since Injury between SCI cohorts
- Pairwise comparisons across AIS grades including controls

### Output Files
The Analysis of BrainPAD.py script generates eleven files:
1. summary_statistics.csv: Detailed summary statistics for each cohort
2. BrainPAD_comparison.png: Boxplot comparing BrainPAD across cohorts
3. Chronological_vs_BrainAge.png: Scatter plot of chronological vs predicted brain age
4. BrainPAD_vs_Age.png: BrainPAD plotted against chronological age
5. BrainPAD_across_sex.png: Sex-specific BrainPAD comparisons
6. BrainPAD_vs_TimeSinceInjury.png: BrainPAD vs time since injury analysis
7. BrainPAD_across_cohorts.csv: Statistical results for overall cohort comparisons
8. BrainPAD_across_sex.csv: Statistical results for sex-specific cohort comparisons
9. BrainPAD_acorss_AIS.csv: Statistical results for AIS-specific comparisons
10. Chi2_AIS.csv: Chi-square test results for AIS distribution
11. TimeSinceInjury_Comparison.csv: Statistical results for Time since Injury comparison
12. ChronologicalAge_Comparison.csv: Statistical results for age comparisons

## Support and Contact

If you encounter any issues with this pipeline or have questions about its implementation, please contact:

Oscar Ortiz (Project Lead) 
Email: oscar.ortiz.angulo@gmail.com





