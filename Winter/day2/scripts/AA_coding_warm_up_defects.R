#' TK
#' Dec 11
#' Hands on coding - build multiple models to predict repair_cost
#' 

# Data
defects <- read.csv('https://raw.githubusercontent.com/kwartler/teaching-datasets/refs/heads/main/defects_data.csv')

# Modeling - since this is a small data set if you're using ranger you can increase the node `min.node.size` parameter so you have larger terminal nodes (not as accurate of a model but we're just doing this for learning)

# End
