#' Title: Intro: Review a TDM/DTM
#' Author: Ted Kwartler
#' Date: June 11, 2025
#'

# Libraries
library(tm)
library(qdapRegex)

# Custom Functions
tryTolower <- function(x){
  # return NA when there is an error
  y = NA
  # tryCatch error
  try_error = tryCatch(tolower(x), error = function(e) e)
  # if not an error
  if (!inherits(try_error, 'error'))
    y = tolower(x)
  return(y)
}

cleanCorpus<-function(corpus, customStopwords){
  corpus <- tm_map(corpus, content_transformer(qdapRegex::rm_url)) 
  corpus <- tm_map(corpus, content_transformer(tryTolower))
  corpus <- tm_map(corpus, removeWords, customStopwords)
  corpus <- tm_map(corpus, removePunctuation)
  corpus <- tm_map(corpus, removeNumbers)
  corpus <- tm_map(corpus, stripWhitespace)
  return(corpus)
}

# Create custom stop words
stopwords('english')
customStopwords <- c(stopwords('english'), 'bank', 'money', 'account', 'lol')

# Data
text <- read.csv('https://raw.githubusercontent.com/kwartler/teaching-datasets/refs/heads/main/allComplaints.csv')


# Get rid of redaction
text$Consumer.complaint.narrative <- gsub('(X{2}\\/X{2}\\/X{4})|(X{2}\\/X{2}\\/[0-9]{2,4})|([0-9]{2}\\/[0-9]{2}\\/[0-9]{2,4})', '', text$Consumer.complaint.narrative, perl = T)

# Global substitutions for words of any length capital X
text$Consumer.complaint.narrative <- gsub('X+', 
                                          '', 
                                          text$Consumer.complaint.narrative)

# TM workflow
txtCorpus <- VCorpus(VectorSource(text$Consumer.complaint.narrative))
txtCorpus <- cleanCorpus(txtCorpus, customStopwords)

# We've primarily worked with DTM
txtDTM  <- DocumentTermMatrix(txtCorpus)
txtDTMm <- as.matrix(txtDTM)

# Let's examine a portion
txtDTMm[5319:5322,grep('marcus',colnames(txtDTMm))]

# So we have document vectors, we have a row of digits that represent the information of each document

# We can transpose this with T, or with TermDocumentMatrix()
# We've primarily worked with DTM
txtTDM  <- TermDocumentMatrix(txtCorpus)
txtTDMm <- as.matrix(txtTDM)

# See the new shape
txtTDMm[grep('marcus',colnames(txtDTMm)),5319:5322]

# In this shape, we have a row of digits that represent the context the terms are used in.  Here its term contextualized by each document.  However, to learn the language characteristics, we have to build term row values not for documents but for all other words in our corpus.  This is called a Term Co-Occurrence Matrix

# End
