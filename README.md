
# Datasciencebowl 2017 Code Repository
## Neural network detection of cancerous tissue using ct scans of the chest cavity

### Python version

Very basic preprocessing and 3D Convolutional Neural Network based off of tutorial from: https://pythonprogramming.net/3d-convolutional-neural-network-machine-learning-tutorial/

### R version

More advanced preprocessing resizing slices and transforming pixels into Hiensfeld Units.  Rdicom-autosave function creates one complete dataframe of flattened, transformed images for use in the kaggle competition.

### Functions

#### rdicomecode_autosave

Primary preprocessing function used to develop final submission.

#### final_covnet

Primary model used to create predictions for final submission.

#### stage2_preproc

Preprocessing function used to convert the test set.

### Utility Functions

#### Resume

#### Train_test_split_func
