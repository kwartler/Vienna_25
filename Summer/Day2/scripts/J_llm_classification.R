#' Author: Ted Kwartler (Modified by Gemini)
#' Date: June 23, 2025
#' Description: An R script to perform text classification using a local LLM
#'              (via lm-studio)

# Libraries
library(httr)
library(jsonlite)
library(pbapply)


# Obtain all the forum posts from the teaching data repo
# You would point this to your corpus 
urlA <- paste0('https://raw.githubusercontent.com/kwartler/teaching-datasets/refs/heads/main/doc_class_examples/',
               101600:101609,
               '.txt')
urlB <- paste0('https://raw.githubusercontent.com/kwartler/teaching-datasets/refs/heads/main/doc_class_examples/', 
               54110:54119,
               '.txt')
allFilesURLS <- c(urlA, urlB)
allFiles <- pblapply(allFilesURLS, readLines)
allFiles[[1]]

# So we must collapse each document from lines to one string but 
# not collapse them into a single document
allFiles <- lapply(allFiles, paste, collapse = '\n')
cat(allFiles[[1]])

# Let's make a custom system instruction
sysPrompt <- 'You are a document classifier.  You review text and assign specific attributes to the document. You must assign one of following tags that best describes the topic of the text.  Here are your options for document classification:\n
- Science & Technology
- Entertainment
- Automotive
- News\n\nYou will only respond with the single classification that BEST describes the text.  You will not add any additional information or commentary.  For example, after reviewing a body of text you would simple state:\n\nEducation\n\nHere is text to review and classify:\n\n'
# Specify the LLM model to use, assuming it's available in lm-studio

# Model name
llmModel <- 'llama-3.2-1b-instruct' #'llama-3.2-1b-instruct' #qwen2.5-7b-instruct

# Organize the request payload for the LLM API
dataLLM <- list(
  model = llmModel,
  messages = list(
    # System message defines the AI's persona
    list(role = "system", content = sysPrompt),
    list(role = "user", content = allFiles[[1]])),
  temperature = 0, # change the temp to see the variability at work
  max_tokens = 256,  
  stream = FALSE)

# Request header specifies the content type as JSON
headers <- c(`Content-Type` = "application/json")

# Make the POST request to the local lm-studio API endpoint
res <- httr::POST(url = "http://localhost:1234/v1/chat/completions",
                  httr::add_headers(.headers = headers),
                  body = toJSON(dataLLM, auto_unbox = TRUE))

# Extract the generated summary from the response
llmResponse <- httr::content(res)$choices[[1]]$message$content
cat(llmResponse)

#  Now we can run it across all documents
docClasses <- list()
for(i in 1:length(allFiles)){
  print(i)
  dataLLM <- list(
    model = llmModel,
    messages = list(
      # System message defines the AI's persona
      list(role = "system", content = sysPrompt),
      list(role = "user", content = allFiles[[i]])),
    temperature = 0, 
    max_tokens = 256,  
    stream = FALSE)
  
  # Request header specifies the content type as JSON
  headers <- c(`Content-Type` = "application/json")
  
  # Make the POST request to the local lm-studio API endpoint
  res <- httr::POST(url = "http://localhost:1234/v1/chat/completions",
                    httr::add_headers(.headers = headers),
                    body = toJSON(dataLLM, auto_unbox = TRUE))
  
  # Extract the generated summary from the response
  llmResponse <- httr::content(res)$choices[[1]]$message$content
  docClasses[[i]] <- data.frame(urlFile = allFilesURLS[i],
                                llmClassification = llmResponse)
}

# Now organize into a data frame
docClassesDF <- do.call(rbind, docClasses)
head(docClassesDF)
table(docClassesDF$llmClassification)

# End