import os
import numpy as np
import nibabel as nib
import matplotlib.pyplot as plt
import pandas as pd
from nilearn import plotting, surface



## where the data is 

file_path = "Effect_Size_Structural_PyBrain.xlsx" 
df = pd.read_excel(file_path)
print(df.columns)

# Paths to FreeSurfer subjects directory and fsaverage
FREESURFER_DIR = "/usr/local/freesurfer/7.4.1"
FSAVERAGE_DIR ="/usr/local/freesurfer/7.4.1/subjects/fsaverage"



# Load cortical surface geometry for visualization
lh_pial = FSAVERAGE_DIR+"/surf"+"/lh.pial"
rh_pial = FSAVERAGE_DIR+"/surf"+"/rh.pial"

lh_inflated = FSAVERAGE_DIR+"/surf"+"/lh.inflated"
rh_inflated = FSAVERAGE_DIR+"/surf"+"/rh.inflated"

lh_sulc = FSAVERAGE_DIR +"/surf"+"/lh.sulc"
rh_sulc = FSAVERAGE_DIR +"/surf"+"/rh.sulc"


# Load aparc.a2009s annotation file
lh_annotation = FSAVERAGE_DIR + "/label" + "/lh.aparc.a2009s.annot"
rh_annotation = FSAVERAGE_DIR + "/label" + "/rh.aparc.a2009s.annot"


# Read FreeSurfer annotation files
lh_labels, _, lh_names = nib.freesurfer.read_annot(lh_annotation)
rh_labels, _, rh_names = nib.freesurfer.read_annot(rh_annotation)

# Decode byte strings to normal strings
lh_names = [name.decode("utf-8") for name in lh_names]
rh_names = [name.decode("utf-8") for name in rh_names]

# Create a mapping from region name to Cohen's d (effect size)
effect_size_dict = dict(zip(df["BrainRegion"], df["Cohen_d"]))

# Initialize arrays for storing mapped effect sizes
lh_data = np.zeros_like(lh_labels, dtype=np.float32)
rh_data = np.zeros_like(rh_labels, dtype=np.float32)

# Assign effect sizes to the corresponding regions
for i, name in enumerate(lh_names):
    region = f"lh_{name}_thickness"
    if region in effect_size_dict:
        lh_data[lh_labels == i] = effect_size_dict[region]

for i, name in enumerate(rh_names):
    region = f"rh_{name}_thickness"
    if region in effect_size_dict:
        rh_data[rh_labels == i] = effect_size_dict[region]

# Ensure no NaN values
lh_data[np.isnan(lh_data)] = 0
rh_data[np.isnan(rh_data)] = 0

# === Plot Brain Surface Maps Using plot_surf() ===

# Define the color limits (adjust these values as needed)
vmin = -0.8  # Minimum value in color scale
vmax = 0.8   # Maximum value in color scale

# let's create a figure with all the views for both hemispheres
views = [
    "lateral",
    "anterior",
    "posterior",
]
hemispheres = [
    "left",
    "right",
]



fig, axes = plt.subplots(
    nrows=len(views),
    ncols=len(hemispheres),
    subplot_kw={"projection": "3d"},
    figsize=(4 * len(hemispheres), 4),
)

for view, ax_row in zip(views, axes):
    for ax, hemi in zip(ax_row, hemispheres):
        if hemi == "left":
            plotting.plot_surf(
                lh_inflated,
                surf_map=lh_data,
                bg_map=lh_sulc,
                hemi="left",
                view=view,
                figure=fig,
                axes=ax,
                title=f"Cohen's D - {hemi} - {view}",
                cmap="coolwarm",
                colorbar=True,
                vmin=vmin,
                vmax=vmax
            )
        else:
            plotting.plot_surf(
                rh_inflated,
                surf_map=rh_data,
                bg_map=rh_sulc,
                hemi="right",
                view=view,
                figure=fig,
                axes=ax,
                title=f"Cohen's D - {hemi} - {view}",
                cmap="coolwarm",
                colorbar=True,
                vmin=vmin,
                vmax=vmax
            )
fig.set_size_inches(6, 9)

plotting.show()










