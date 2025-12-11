#' Build a model and test for bias
#' TK
#' Dec 11
#' Original: https://raw.githubusercontent.com/Opensourcefordatascience/Data-sets/refs/heads/master/admission.csv

# Library 
library(dplyr)
library(fairness)
library(ggplot2)
library(ggthemes)
library(rpart)
library(randomForest)
library(MLmetrics)

# Data
admissions <- read.csv('https://raw.githubusercontent.com/kwartler/teaching-datasets/refs/heads/main/syntheticBias_admission.csv')

# Sample - just do 80/20 split since the data is small and clean





# Explore - 
# At a minimum do 
# head
# table of Y by gender
# ggplot*2 








# Modify - not needed bc the data is already cleaned up

# Model - create a RF
# Ask yourself 
# is Y a factor or numeric?
# Should we use all variables?



# Assess the random forest
# rf - in sample prediction  - train
# with  type="response"


# rf - out of sample prediction - validation
# with  type="response"



# Random Forest - accuracy - train



# Random Forest - accuracy - validation



# Append the predicted classes to the original data so we can examine the sensitive feature




# Now check for demographic parity- Train





# Now check for demographic parity - validation





# End