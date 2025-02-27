###############################################################################
# Analysis of BrainPAD - Brain Predicted Age Difference Analysis Script
###############################################################################

# This script performs comprehensive analysis of brain age predictions across different cohorts.
# It generates statistical summaries and visualizations to help understand brain age differences between control subjects and spinal cord injury (SCI) patients with and without pain.

###############################################################################

# Import required libraries
import pandas as pd  # For data manipulation and analysis
import matplotlib.pyplot as plt  # For creating plots and visualizations
import numpy as np  # For numerical operations
import seaborn as sns  # For statistical data visualization
from scipy import stats  # For statistical tests
from itertools import combinations  # For generating combinations of groups
from cliffs_delta import cliffs_delta  # For calculating Cliff's delta effect size
import statsmodels.api as sm # For regression analysis
import os # For file operations

# Define file paths for input data and output files
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
output_path12 = "/path/to/output/ChronologicalAge_Comparison.csv"   # Statistical results for chronological age comparison
df_pybrain = pd.read_excel(PyB_path)

# Convert relevant columns to numeric format, handling any errors
for col in ["Age", "BrainPAD", "BrainAge"]:
    if col in df_pybrain.columns:
        df_pybrain[col] = pd.to_numeric(df_pybrain[col], errors="coerce")

# Define the order of cohorts for consistent analysis
cohort_order = ["control", "SCI_nNP", "SCI_P"]  # Control, SCI without pain, SCI with pain

# Initialize list to store summary statistics
summary_results = []

# Calculate summary statistics for each cohort
for cohort in cohort_order:
    # Filter data for current cohort
    subset = df_pybrain[df_pybrain["Cohort"] == cohort]

    # Calculate basic demographic and clinical statistics
    num_participants = len(subset)
    mean_age = subset["Age"].mean() if "Age" in subset.columns else np.nan
    std_age = subset["Age"].std() if "Age" in subset.columns else np.nan
    mean_brainpad = subset["BrainPAD"].mean() if "BrainPAD" in subset.columns else np.nan
    std_brainpad = subset["BrainPAD"].std() if "BrainPAD" in subset.columns else np.nan
    mean_brainage = subset["BrainAge"].mean() if "BrainAge" in subset.columns else np.nan
    std_brainage = subset["BrainAge"].std() if "BrainAge" in subset.columns else np.nan

    # Calculate sex distribution
    num_male = sum(subset["Sex"] == "Male") if "Sex" in subset.columns else np.nan
    num_female = sum(subset["Sex"] == "Female") if "Sex" in subset.columns else np.nan

    # Get AIS (ASIA Impairment Scale) distribution for SCI participants
    ais_distribution = subset["AIS"].value_counts().to_dict() if "AIS" in subset.columns else "Not Available"

    # Calculate additional clinical measures
    valid_time_since_sci = subset["Time since SCI (years)"].notna().sum() if "Time since SCI (years)" in subset.columns else 0
    time_since_sci_mean = subset["Time since SCI (years)"].mean() if valid_time_since_sci > 2 else "Not Available"
    
    # Store all calculated statistics for this cohort
    summary_results.append([
        cohort, num_participants, mean_age, std_age, mean_brainpad, std_brainpad,
        mean_brainage, std_brainage, num_male, num_female, ais_distribution,
        time_since_sci_mean
    ])

# Create summary DataFrame with all statistics
df_summary = pd.DataFrame(summary_results, columns=[
    "Cohort", "Participants", "Mean Age", "SD Age", "Mean BrainPAD", "SD BrainPAD",
    "Mean BrainAge", "SD BrainAge", "Num Male", "Num Female", "AIS Distribution",
    "Mean Time Since SCI", 
])

# Save summary statistics to CSV file
df_summary.to_csv(output_path1, index=False)


# Create boxplot comparing BrainPAD across cohorts
# Define colors for each cohort
cohort_palette = {
    "control": "#AEC6E8",  # Light Blue for control group
    "SCI_nNP": "#FFCC99",  # Light Orange for SCI without pain
    "SCI_P": "#99D8A0"     # Light Green for SCI with pain
}

# Create main boxplot
plt.figure(figsize=(10, 6))
sns.boxplot(x="Cohort", y="BrainPAD", data=df_pybrain, palette=cohort_palette, showfliers=False, width=0.6, boxprops={'alpha': 0.5})

# Add individual data points
sns.stripplot(x="Cohort", y="BrainPAD", data=df_pybrain, color="black", jitter=True, size=6, alpha=0.7)

# Add mean values as triangular markers
means = df_pybrain.groupby("Cohort")["BrainPAD"].mean()
for i, cohort in enumerate(df_pybrain["Cohort"].unique()):
    plt.scatter(i, means[cohort], color="black", marker="^", s=100, label="Mean" if i == 0 else "")

# Customize plot appearance
plt.title("BrainPAD Comparison Across Cohorts", fontsize=16, fontweight="bold")
plt.xlabel("Cohort", fontsize=14, fontweight="bold")
plt.ylabel("BrainPAD", fontsize=14, fontweight="bold")
plt.xticks(fontsize=12)
plt.yticks(fontsize=12)
plt.legend(title="Statistics", loc="upper right")

# Add grid and save plot
plt.grid(alpha=0.3)
plt.tight_layout()
plt.savefig(output_path2)


# Create scatter plot comparing chronological age vs predicted brain age
plt.figure(figsize=(10, 6))
sns.scatterplot(x="Age", y="BrainAge", hue="Cohort", data=df_pybrain, palette=cohort_palette, alpha=0.7, s=70, edgecolor="black")

# Add reference line (y=x) showing perfect prediction
plt.plot([df_pybrain["Age"].min(), df_pybrain["Age"].max()],
         [df_pybrain["Age"].min(), df_pybrain["Age"].max()],
         'k--', alpha=0.8)

# Customize plot appearance
plt.title("Chronological Age vs. Predicted Brain Age (PyBrain)", fontsize=16, fontweight="bold")
plt.xlabel("Chronological Age", fontsize=14, fontweight="bold")
plt.ylabel("Predicted Brain Age", fontsize=14, fontweight="bold")
plt.xticks(fontsize=12)
plt.yticks(fontsize=12)
plt.legend(title="Cohort", loc="upper left")

# Save plot
plt.savefig(output_path3)


# Create scatter plot showing BrainPAD vs Age relationship for different cohorts
plt.figure(figsize=(10, 6))

# Add trend lines for each cohort
sns.lmplot(data=df_pybrain, x="Age", y="BrainPAD", hue="Cohort", palette=cohort_palette, ci=None, height=6, aspect=1.5)

# Customize plot appearance
plt.xlabel("Age (Years)", fontsize=14, fontweight="bold")
plt.ylabel("BrainPAD", fontsize=14, fontweight="bold")
plt.title("BrainPAD vs Age Across Cohorts", fontsize=16, fontweight="bold")
plt.legend(title="Cohort", loc="upper right")
plt.grid(alpha=0.3)

# Save plot
plt.savefig(output_path4)

# Create sex-specific BrainPAD analysis
# Split data by sex
df_female = df_pybrain[df_pybrain["Sex"] == "Female"]
df_male = df_pybrain[df_pybrain["Sex"] == "Male"]

# Define cohort order and colors
cohort_order = ["control", "SCI_nNP", "SCI_P"]
cohort_palette = {"control": "#AEC6E8", "SCI_nNP": "#FFCC99", "SCI_P": "#99D8A0"}

# Create side-by-side plots for female and male participants
fig, axes = plt.subplots(nrows=1, ncols=2, figsize=(14, 6), sharey=True)

# Plot female data
sns.boxplot(x="Cohort", y="BrainPAD", data=df_female, order=cohort_order, palette=cohort_palette,
            showfliers=False, width=0.6, ax=axes[0], legend=False)
sns.stripplot(x="Cohort", y="BrainPAD", data=df_female, hue="Cohort", order=cohort_order, jitter=True,
              size=8, alpha=0.7, color="black", ax=axes[0])
axes[0].set_title("BrainPAD - Female", fontsize=14, fontweight="bold")
axes[0].set_xlabel("Cohorts", fontsize=12, fontweight="bold")
axes[0].set_ylabel("BrainPAD", fontsize=12, fontweight="bold")

# Plot male data
sns.boxplot(x="Cohort", y="BrainPAD", data=df_male, order=cohort_order, palette=cohort_palette,
            showfliers=False, width=0.6, ax=axes[1])
sns.stripplot(x="Cohort", y="BrainPAD", data=df_male, hue="Cohort", order=cohort_order, jitter=True,
              size=8, alpha=0.7, color="black", ax=axes[1])
axes[1].set_title("BrainPAD - Male", fontsize=14, fontweight="bold")
axes[1].set_xlabel("Cohorts", fontsize=12, fontweight="bold")

# Add overall title and save plot
plt.suptitle("BrainPAD Comparison by Cohort (Separated by Sex)", fontsize=16, fontweight="bold")
plt.tight_layout()
plt.savefig(output_path5)


# Analyze BrainPAD vs Time Since Injury for SCI participants
# Filter the dataset for SCI participants only
df_sci = df_pybrain[df_pybrain["Cohort"].isin(["SCI_nNP", "SCI_P"])].copy()

# Rename column to avoid whitespace issues
df_sci.rename(columns={"Time since SCI (years) ": "Time since SCI (years)"}, inplace=True)

# Drop rows where Time Since SCI or BrainPAD is NaN
df_sci = df_sci[["Time since SCI (years)", "BrainPAD", "Cohort"]].dropna()

# Convert Time Since SCI to numeric
df_sci["Time since SCI (years)"] = pd.to_numeric(df_sci["Time since SCI (years)"], errors="coerce")

# Group Data by Cohort
sci_nnp_tsi = df_sci[df_sci["Cohort"] == "SCI_nNP"]["Time since SCI (years)"].dropna()
sci_p_tsi = df_sci[df_sci["Cohort"] == "SCI_P"]["Time since SCI (years)"].dropna()

# Check Normality
shapiro_nnp = stats.shapiro(sci_nnp_tsi)[1]
shapiro_p = stats.shapiro(sci_p_tsi)[1]

# Choose Statistical Test
if shapiro_nnp > 0.05 and shapiro_p > 0.05:
    tsi_test = "t-test"
    test_stat, p_tsi = stats.ttest_ind(sci_nnp_tsi, sci_p_tsi)
    effect_size_tsi = (sci_nnp_tsi.mean() - sci_p_tsi.mean()) / np.sqrt((sci_nnp_tsi.std()**2 + sci_p_tsi.std()**2) / 2)
else:
    tsi_test = "Mann-Whitney U"
    test_stat, p_tsi = stats.mannwhitneyu(sci_nnp_tsi, sci_p_tsi)
    effect_size_tsi, _ = cliffs_delta(sci_nnp_tsi, sci_p_tsi)

# Perform Linear Regression
X = df_sci["Time since SCI (years)"]
y = df_sci["BrainPAD"]
X = sm.add_constant(X)  # Add intercept

model = sm.OLS(y, X, missing="drop").fit()
regression_p = model.pvalues["Time since SCI (years)"]
regression_r2 = model.rsquared

# Define Colors for SCI Groups
cohort_palette = {"SCI_nNP": "#FFCC99", "SCI_P": "#99D8A0"}

# Create Scatter Plot
plt.figure(figsize=(10, 6))
sns.scatterplot(x="Time since SCI (years)", y="BrainPAD", hue="Cohort",
                data=df_sci, palette=cohort_palette, s=70, alpha=0.8, edgecolor="black")

# Add Trend Lines
sns.regplot(x="Time since SCI (years)", y="BrainPAD", data=df_sci[df_sci["Cohort"] == "SCI_nNP"],
            scatter=False, color="#FFCC99", line_kws={"linestyle": "--", "linewidth": 2})
sns.regplot(x="Time since SCI (years)", y="BrainPAD", data=df_sci[df_sci["Cohort"] == "SCI_P"],
            scatter=False, color="#99D8A0", line_kws={"linestyle": "--", "linewidth": 2})

# Customize Labels & Title
plt.xlabel("Time Since Injury (Years)", fontsize=14, fontweight="bold")
plt.ylabel("BrainPAD", fontsize=14, fontweight="bold")
plt.title("BrainPAD vs Time Since Injury (SCI Participants)", fontsize=16, fontweight="bold")

# Add Statistical Annotations
stats_text = f"{tsi_test}: p = {p_tsi:.3f}, ES = {effect_size_tsi:.2f}\n" \
             f"Regression: R² = {regression_r2:.3f}, p = {regression_p:.3f}"
plt.annotate(stats_text, xy=(0.025, 0.9), xycoords="axes fraction", fontsize=12, fontweight="bold")

# Adjust Legend & Save Plot
plt.legend(title="Cohort", loc="upper right")
plt.grid(alpha=0.3)
plt.tight_layout()
temp_path = output_path6.replace(".png", "_temp.png")
plt.savefig(temp_path)
os.rename(temp_path, output_path6)


# Perform statistical analysis
# Define function to calculate Cohen's d effect size
def cohen_d(x, y):
    """Calculate Cohen's d for two independent samples."""
    mean_x, mean_y = np.mean(x), np.mean(y)
    pooled_std = np.sqrt(((np.std(x, ddof=1) ** 2) + (np.std(y, ddof=1) ** 2)) / 2)
    return (mean_x - mean_y) / pooled_std

# Define cohorts
cohort_order = ["control", "SCI_nNP", "SCI_P"]

# Test for normality in entire dataset
shapiro_p = stats.shapiro(df_pybrain["BrainPAD"].dropna())[1]
ks_p = stats.kstest(df_pybrain["BrainPAD"].dropna(), 'norm',
                    args=(df_pybrain["BrainPAD"].mean(), df_pybrain["BrainPAD"].std()))[1]

# Determine if data is normally distributed
is_normal = shapiro_p > 0.05 and ks_p > 0.05

# Perform pairwise comparisons between cohorts
comparison_results = []
for group1, group2 in combinations(cohort_order, 2):
    data1 = df_pybrain[df_pybrain["Cohort"] == group1]["BrainPAD"].dropna()
    data2 = df_pybrain[df_pybrain["Cohort"] == group2]["BrainPAD"].dropna()

    n1, n2 = len(data1), len(data2)  # Sample sizes

    # Choose appropriate statistical test based on normality
    if is_normal:
        test_stat, p_value = stats.ttest_ind(data1, data2)
        test_used = f"t-test (t={test_stat:.2f})"
        effect_size = cohen_d(data1, data2)

    else:
        test_stat, p_value = stats.mannwhitneyu(data1, data2)
        test_used = f"Mann-Whitney U (U={test_stat:.2f})"
        effect_size, _ = cliffs_delta(data1, data2)


    # Always format df as n1=XX, n2=XX
    df_value = f"n1={n1}, n2={n2}"

    comparison_results.append([group1, group2, test_used, p_value, effect_size, df_value])

# Create and save results DataFrame
df_comparisons = pd.DataFrame(comparison_results, columns=["Group1", "Group2", "Test Used", "p-value", "Effect Size", "Sample Size"])
df_comparisons.to_csv(output_path7)


# Perform sex-specific statistical analysis
# Split data by sex
df_female = df_pybrain[df_pybrain["Sex"] == "Female"]
df_male = df_pybrain[df_pybrain["Sex"] == "Male"]

# Analyze female cohorts
female_results = []
for group1, group2 in combinations(cohort_order, 2):
    data1 = df_female[df_female["Cohort"] == group1]["BrainPAD"].dropna()
    data2 = df_female[df_female["Cohort"] == group2]["BrainPAD"].dropna()

    n1, n2 = len(data1), len(data2)  # Sample sizes

    # Choose appropriate test based on normality
    if is_normal:
        test_stat, p_value = stats.ttest_ind(data1, data2)
        test_used = f"t-test (t={test_stat:.2f})"
        effect_size = cohen_d(data1, data2)
    else:
        test_stat, p_value = stats.mannwhitneyu(data1, data2)
        test_used = f"Mann-Whitney U (U={test_stat:.2f})"
        effect_size, _ = cliffs_delta(data1, data2)

    # Store results with sample sizes
    df_value = f"n1={n1}, n2={n2}"
    female_results.append(["Female", group1, group2, test_used, p_value, effect_size, df_value])

# Analyze male cohorts
male_results = []
for group1, group2 in combinations(cohort_order, 2):
    data1 = df_male[df_male["Cohort"] == group1]["BrainPAD"].dropna()
    data2 = df_male[df_male["Cohort"] == group2]["BrainPAD"].dropna()
    n1, n2 = len(data1), len(data2)  # Sample sizes
    # Choose appropriate test based on normality
    if is_normal:
        test_stat, p_value = stats.ttest_ind(data1, data2)
        test_used = f"t-test (t={test_stat:.2f})"
        effect_size = cohen_d(data1, data2)
    else:
        test_stat, p_value = stats.mannwhitneyu(data1, data2)
        test_used = f"Mann-Whitney U (U={test_stat:.2f})"
        effect_size, _ = cliffs_delta(data1, data2)

    # Store results with sample sizes
    df_value = f"n1={n1}, n2={n2}"
    male_results.append(["Male", group1, group2, test_used, p_value, effect_size, df_value])

# Create and combine results DataFrames
df_female_comparisons = pd.DataFrame(female_results, columns=["Sex", "Group1", "Group2", "Test Used", "p-value", "Effect Size", "Sample Size"])
df_male_comparisons = pd.DataFrame(male_results, columns=["Sex", "Group1", "Group2", "Test Used", "p-value", "Effect Size", "Sample Size"])
df_sex_comparisons = pd.concat([df_female_comparisons, df_male_comparisons], ignore_index=True)

# Save sex-specific results
df_sex_comparisons.to_csv(output_path8)

# AIS vs BrainPAD
# Filter dataset for relevant groups (SCI + Controls)
df_sci_controls = df_pybrain[df_pybrain["Cohort"].isin(["control", "SCI_nNP", "SCI_P"])].copy()

# Drop rows where AIS, Cohort, or BrainPAD is NaN or inf
df_sci_controls = df_sci_controls[["AIS", "Cohort", "BrainPAD"]].replace([np.inf, -np.inf], np.nan).dropna()

# Ensure AIS & Cohort are treated as categorical variables
df_sci_controls["AIS"] = df_sci_controls["AIS"].astype(str)  # Convert AIS to string for categorical analysis
df_sci_controls["Cohort"] = df_sci_controls["Cohort"].astype(str)

# Define order for groups
ais_order = ["control", "D", "C", "B", "A"]  # Controls first, then AIS order

# Function for Cohen's d
def cohen_d(x, y):
    mean_x, mean_y = np.mean(x), np.mean(y)
    pooled_std = np.sqrt(((np.std(x, ddof=1) ** 2) + (np.std(y, ddof=1) ** 2)) / 2)
    return (mean_x - mean_y) / pooled_std

# Check Normality for Entire Dataset
shapiro_p = stats.shapiro(df_sci_controls["BrainPAD"].dropna())[1]
ks_p = stats.kstest(df_sci_controls["BrainPAD"].dropna(), 'norm',
                    args=(df_sci_controls["BrainPAD"].mean(), df_sci_controls["BrainPAD"].std()))[1]

# Determine Normality
is_normal = shapiro_p > 0.05 and ks_p > 0.05

# Statistical Comparisons (AIS + Controls)
comparison_results = []
for group1, group2 in combinations(ais_order, 2):
    data1 = df_sci_controls[df_sci_controls["AIS"] == group1]["BrainPAD"].dropna() if group1 != "control" else df_sci_controls[df_sci_controls["Cohort"] == "control"]["BrainPAD"].dropna()
    data2 = df_sci_controls[df_sci_controls["AIS"] == group2]["BrainPAD"].dropna() if group2 != "control" else df_sci_controls[df_sci_controls["Cohort"] == "control"]["BrainPAD"].dropna()

    n1, n2 = len(data1), len(data2)  # Sample sizes

    # Choose the statistical test based on normality
    if is_normal:
        test_stat, p_value = stats.ttest_ind(data1, data2)
        test_used = f"t-test (t={test_stat:.2f})"
        effect_size = cohen_d(data1, data2)
    else:
        test_stat, p_value = stats.mannwhitneyu(data1, data2)
        test_used = f"Mann-Whitney U (U={test_stat:.2f})"
        effect_size, _ = cliffs_delta(data1, data2)

    # Store results
    comparison_results.append([group1, group2, test_used, p_value, effect_size, f"n1={n1}, n2={n2}"])


# Create DataFrame and Save
df_comparisons = pd.DataFrame(comparison_results, columns=["Group 1", "Group 2", "Test Used", "p-value", "Effect Size", "Sample Sizes"])
df_comparisons.to_csv(output_path9, index=False)


# Chi-Square Test for AIS Distribution
# Filter for SCI participants
df_sci = df_pybrain[df_pybrain["Cohort"].isin(["SCI_P", "SCI_nNP"])]

# Create a contingency table for AIS levels
contingency_table = pd.crosstab(df_sci["Cohort"], df_sci["AIS"])

# Perform Chi-Square test
chi2_stat, p_value, dof, expected = stats.chi2_contingency(contingency_table)

# Store results in a DataFrame
df_chi2_results = pd.DataFrame({
    "Chi-Square Statistic": [chi2_stat],
    "Degrees of Freedom": [dof],
    "p-value": [p_value]
})
# Save results to CSV
df_chi2_results.to_csv(output_path10, index=False)

# Define output path for saving results
###Comparison between Time since Injury
# Compare SCI_P and SCI_nNP for "Time since SCI (years)"
df_sci_comparison = df_pybrain[df_pybrain["Cohort"].isin(["SCI_P", "SCI_nNP"])].copy()

# Convert column to numeric and drop NaN values 
df_sci_comparison["Time since SCI (years)"] = pd.to_numeric(df_sci_comparison["Time since SCI (years)"], errors="coerce")
df_sci_comparison = df_sci_comparison.dropna(subset=["Time since SCI (years)"])

# Extract values for both groups
sci_p = df_sci_comparison[df_sci_comparison["Cohort"] == "SCI_P"]["Time since SCI (years)"]
sci_nnp = df_sci_comparison[df_sci_comparison["Cohort"] == "SCI_nNP"]["Time since SCI (years)"]

# Use previously determined normality test result
if is_normal:
    test_stat, p_value = stats.ttest_ind(sci_p, sci_nnp)
    test_used = f"T-Test (t={test_stat:.2f})"
    effect_size = cohen_d(sci_p, sci_nnp)
else:
    test_stat, p_value = stats.mannwhitneyu(sci_p, sci_nnp)
    test_used = f"Mann-Whitney U-Test (U={test_stat:.2f})"
    effect_size, _ = cliffs_delta(sci_p, sci_nnp)

# Store results in a DataFrame
df_time_comparison = pd.DataFrame({
    "Test": [test_used],
    "p-Value": [p_value], 
    "Effect Size": [effect_size],
    "n_SCI_P": [len(sci_p)],
    "n_SCI_nNP": [len(sci_nnp)]
})

# Save results to CSV
df_time_comparison.to_csv(output_path11, index=False)


# Comparison Chronological Age
# Function to Calculate Cohen's d
def cohen_d(x, y):
    mean_x, mean_y = np.mean(x), np.mean(y)
    pooled_std = np.sqrt(((np.std(x, ddof=1) ** 2) + (np.std(y, ddof=1) ** 2)) / 2)
    return (mean_x - mean_y) / pooled_std

# Perform Pairwise Comparisons
comparison_results = []
for group1, group2 in combinations(cohort_order, 2):
    data1 = df_pybrain[df_pybrain["Cohort"] == group1]["Age"].dropna()
    data2 = df_pybrain[df_pybrain["Cohort"] == group2]["Age"].dropna()

    # Choose statistical test
    if is_normal:
        test_stat, p_value = stats.ttest_ind(data1, data2)
        test_used = f"t-test (t={test_stat:.2f})"
        effect_size = cohen_d(data1, data2)
    else:
        test_stat, p_value = stats.mannwhitneyu(data1, data2)
        test_used = f"Mann-Whitney U (U={test_stat:.2f})"
        effect_size, _ = cliffs_delta(data1, data2)

    # Store results
    comparison_results.append([group1, group2, test_used, p_value, effect_size])

# Convert to DataFrame
df_comparisons = pd.DataFrame(comparison_results, columns=["Group1", "Group2", "Test Used", "p-value", "Effect Size"])

# Save results to CSV
df_comparisons.to_csv(output_path12, index=False)