#' Purpose: Using a local embedding model and llm create a simple RAG workflow
#' Author: Ted Kwartler
#' email: edwardkwartler@fas.harvard.edu
#' Date: June 25, 2025
#' 


# Library
library(jsonlite)
library(httr)

# Inputs
embeddingModel <- 'text-embedding-granite-embedding-278m-multilingual'
savePath <- '~/Desktop/GSERM_2025/personalFiles/'
headers  <- c('Content-Type' = 'application/json')

# Get data contemporary information
movieDB <- fromJSON('https://raw.githubusercontent.com/kwartler/teaching-datasets/refs/heads/main/finalMovie.json')

# Review 
head(movieDB)

# Make embeddings
docVectors <- list()
for(i in 1:nrow(movieDB)){
  print(i)
  oneDoc <- toJSON(movieDB[i,], pretty = T)
  dataObj <- list(input = oneDoc, model = embeddingModel)
  
  # Convert the list to JSON
  data <- toJSON(dataObj, auto_unbox = TRUE)
  

  res <- httr::POST(
    url = "http://localhost:1234/v1/embeddings", 
    httr::add_headers(.headers = headers), 
    body = data,
    encode = "json"
  )
  
  vectorEmbeddings <- httr::content(res)$data
  vectorEmbeddings <- unlist(vectorEmbeddings[[1]]$embedding)
  docVectors[[i]]<- vectorEmbeddings
}

# Resulting vectors
docVectors<- do.call(rbind, docVectors)
dim(docVectors)
docVectors[1:10,1:50]

# Save embeddings making a "vector database"
write.csv(docVectors, paste0(savePath,'vectorEmbeddings.csv'), row.names = F)

# Save the actual documents too
write.csv(movieDB, paste0(savePath,'movieDB.csv'), row.names = F)

# End
