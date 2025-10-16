#' Purpose: Using a local embedding model and llm create a simple RAG workflow
#' Author: Ted Kwartler
#' email: edwardkwartler@fas.harvard.edu
#' Date: June 25, 2025
#' 


# Library
library(jsonlite)
library(httr)
library(lsa) #calculate numeric cosine similarity

# Inputs
llmModel <- 'llama-3.2-1b-instruct'
embeddingModel <- 'text-embedding-granite-embedding-278m-multilingual'
sysPromptRAG <- 'You are a helpful, knowledgeable AI assistant. Answer the user\'s question accurately and concisely.  Answer the user\'s question using only the information provided below:\n\n'
userPrompt <- 'Tell me about the movie Wicked from 2024.  Who directed it?'
savePath <- '~/Desktop/GSERM_2025/personalFiles/'
headers  <- c('Content-Type' = 'application/json')
topN <- 3
maxTokens <- 512
temp <- 0.7

# Read in our "vector database"
docVectors <- read.csv(paste0(savePath,'vectorEmbeddings.csv'))

# Now let's make a user request, turn it into embeddings first
dataObj <- list(input = userPrompt, model = embeddingModel)

# Convert the list to JSON
dataLLM <- toJSON(dataObj, auto_unbox = TRUE)

# Make the embedding request
res <- httr::POST(
  url = "http://localhost:1234/v1/embeddings", 
  httr::add_headers(.headers = headers), 
  body = dataLLM,
  encode = "json"
)

userEmbeddings <- httr::content(res)$data
userEmbeddings <- unlist(userEmbeddings[[1]]$embedding)

# Now we have the user prompt as a vector and a "database" of document vectors
# We can use cosine similarity to find the document vector closest to our user vector
allSimilarities <- apply(docVectors, 1, lsa::cosine,userEmbeddings)

# Reorder and grab the stop N document rows; we dont need the cosine sim scores
# just the row positions
idx <- order(allSimilarities, decreasing = TRUE)[1:topN]

# Get the appropriate documents; if we were using SQL or an actual DB we could make this more efficient
movies <- read.csv(paste0(savePath,'movieDB.csv'))
relevantMovies <- movies[idx,]

# Some data manipulation to organize the data 
# and keeping column names for all chunks so we dont confuse the llm
relevantMovies <- toJSON(relevantMovies, pretty = T)
relevantMovies

# Now we integrate the user prompt and the documents back into a single prompt
ragPrompt <- paste(userPrompt, '\n\n',relevantMovies)

# Pass this augmented prompt into the LLM
dataLLM <- list(model = llmModel,
                messages = list(
                  list(role = "system", content = sysPromptRAG),
                  list(role = "user", content = ragPrompt)),
                temperature = temp,
                max_tokens = maxTokens,
                stream = FALSE)

# Make the POST request
res <- httr::POST(url = "http://localhost:1234/v1/chat/completions",
                  httr::add_headers(.headers = headers),
                  body = toJSON(dataLLM, auto_unbox = TRUE))

# Extract the response
llmResponse <- httr::content(res)$choices[[1]]$message$content
cat(llmResponse)

# End
