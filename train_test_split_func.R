train_test_valid <-function(df, train_size = .75, validation_size = .20, test_size = .5){

# Input 2. Set the fractions of the dataframe you want to split into training, 
# validation, and test.
#implemented using code from StackOverflow: 
#http://stackoverflow.com/questions/36068963/r-how-to-split-a-data-frame-into-training-validation-and-test-sets
  
fractionTraining   <- train_size
fractionValidation <- validation_size
fractionTest       <- test_size

# Compute sample sizes.
sampleSizeTraining   <- floor(fractionTraining   * nrow(df))
sampleSizeValidation <- floor(fractionValidation * nrow(df))
sampleSizeTest       <- floor(fractionTest       * nrow(df))

# Create the randomly-sampled indices for the dataframe. Use setdiff() to
# avoid overlapping subsets of indices.
indicesTraining    <- sort(sample(seq_len(nrow(df)), size=sampleSizeTraining))
indicesNotTraining <- setdiff(seq_len(nrow(df)), indicesTraining)
indicesValidation  <- sort(sample(indicesNotTraining, size=sampleSizeValidation))
indicesTest        <- setdiff(indicesNotTraining, indicesValidation)

# Finally, output the three dataframes for training, validation and test.
dfTraining   <- df[indicesTraining, ]
dfValidation <- df[indicesValidation, ]
dfTest       <- df[indicesTest, ]

df_list <- list('train' = dfTraining, 'valid' = dfValidation, 'test' = dfTest)

return(df_list)
}