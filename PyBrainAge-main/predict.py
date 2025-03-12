import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import pickle
import seaborn as sns
from statsmodels.genmod.families import Gaussian
import statsmodels.formula.api as smf
from itertools import combinations 
from scipy.stats import pearsonr


#age_data_path = get_file_path("Enter the path for the 'Your_database.xlsx' file: ")
# make the subject features by grabbing the concatenated results txt file and adding the age of the subjects on the second column and saving it as subject_features.csv

age_data_path = r'C:\Users\kramerlab\Documents\brain_age_data\subject_features.csv'

#model_path = get_file_path("Enter the path for the 'ExtraTreesModel' file: ")
model_path = r'C:\Users\kramerlab\Documents\brain_age_pybrain\PyBrainAge\software\ExtraTreesModel'

#scaler_path = get_file_path("Enter the path for the 'scaler.pkl' file: ")
scaler_path = r'C:\Users\kramerlab\Documents\brain_age_pybrain\PyBrainAge\software\scaler.pkl'
#scaler_path = r'C:\Users\kramerlab\Documents\brain_age_pybrain\PyBrainAge-main\scaler.pkl'



data_test = pd.read_csv(age_data_path)

# Load model and scaler
model = pickle.load(open(model_path, 'rb'))
sc_X = pickle.load(open(scaler_path, 'rb'))

# Prepare data for prediction
#df = data_total
df = data_test

IDs = df.iloc[:, 0]
Ages = df.iloc[:, 1]
data = df.iloc[:, 2:]

# Validate data
if data.isnull().values.any():
    raise ValueError('There is missing data in the dataframe')

if data.isin([np.inf, -np.inf]).values.sum() != 0:
    raise ValueError('There is an infinite value in your dataframe')

for index, row in enumerate(data.iterrows()):
    if any(isinstance(val, str) for val in row[1].values):
        raise ValueError('There is non-numeric data in the dataframe')

# Rename columns if needed
def rename_cols_to_roi_format(data):
    new_columns = []
    for col in data.columns:
        col = col.replace('_and_', '&')
        col = col.replace('Left-Thalamus', 'Left-Thalamus-Proper')
        col = col.replace('Right-Thalamus', 'Right-Thalamus-Proper')
        new_columns.append(col)
    data.columns = new_columns
    return data

# Apply scaler
try:
    data = sc_X.transform(data)
except ValueError as e:
    print("Scaler failed potentially due to feature name mismatch, attempting to rename columns and attempt scaler again.")
    data = rename_cols_to_roi_format(data)
    try:
        data = sc_X.transform(data)
        print('Scaler transformation appears successful')
    except ValueError:
        raise ValueError('Failing to apply scaler to the data. Check if the scaler is loaded correctly and/or if the data is in the correct format.') from e

# Predict
outputs = []
try:
    outputs = model.predict(data)
except:
    print("Applying the model to the data at once failed. Moving to apply the model row-by-row (slower).")
    for row in range(len(data)):
        try:
            outputs.append(model.predict(data[row].reshape(1, -1)))
        except:
            raise ValueError(f'Failed at row {row}')
print(f"Processed all {len(data)} rows successfully. Moving to save the results.")


# Save results
stacked = np.column_stack((IDs, Ages, outputs))
df2 = pd.DataFrame(stacked, columns=['ID', 'Age', 'BrainAge'])

# Calculate Brain-PAD
df2['BrainPAD'] = df2['BrainAge'] - df2['Age']

# Save output
output_path = r'C:\Users\kramerlab\Documents\brain_age_data\predicted_results.csv'
df2.to_csv(output_path, index=False)

