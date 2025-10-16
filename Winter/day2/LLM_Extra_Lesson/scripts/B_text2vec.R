#' Purpose: Make an example word embedding model
#' Author: Ted Kwartler
#' email: edwardkwartler@fas.harvard.edu
#' Date: June 25, 2025
#' https://text2vec.org/glove.html

# Backup way to programmatically download the file
#library(data.table)
#url <- "https://github.com/kwartler/teaching-datasets/raw/refs/heads/main/Airbnb-boston_only.zip"
#temp <- tempfile()
#download.file(url, temp)
#bosReviews <- fread(unzip(temp, exdir = tempdir()))
#unlink(temp)

# Direct import 
library(rio)
library(text2vec)
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

# Stopwords - we actually don't want to many since we're trying to understand semantic structures
stops <- c(stopwords('SMART'), 'boston')

# Data input
bosReviews <- import("https://github.com/kwartler/teaching-datasets/raw/refs/heads/main/Airbnb-boston_only.zip")
head(bosReviews$comments)

# TM Cleaning workflow
bosComments <- VCorpus(VectorSource(bosReviews$comments))
bosComments <- cleanCorpus(bosComments, stops) #maybe 30sec
bosComments <- sapply(bosComments, NLP::content)

# Now we begin the text to vector workflow
iterMaker <- itoken(bosComments)
textVocab <- create_vocabulary(iterMaker,  
                               ngram = c(ngram_min = 1L, 
                                         ngram_max = 1L))
textVocab <- prune_vocabulary(textVocab, term_count_min = 5)

# What did we make?
tail(textVocab)

# Now we make a vectorizing function which has a stopword & pruned vocabulary
vectorizer <- vocab_vectorizer(textVocab)

# This creates term-cooccurrence matrix from the subset of vocabulary words 
# since stopwords and pruning occured
textTCM <- create_tcm(iterMaker, vectorizer, skip_grams_window = 5L)
dim(textTCM)

# Let's find a portion and review
idxCol <- which(textTCM[1, ] != 0)[1]
textTCM[1:5, (idxCol-1):(idxCol+4)]
textTCM["famous", "hidden"]

# Fit the GloVe model
glove      <- GlobalVectors$new(rank = 50,x_max = 10)
gloveModel <- glove$fit_transform(textTCM, n_iter = 15)
# Note that model learns two sets of word vectors - center [main definition] and context
# It usually is a better (idea from GloVe paper) to average or take a sum of main and context vector:
wordVectors <- gloveModel + t(glove$components)


# Look at the resulting vectors
dim(wordVectors)
head(rownames(wordVectors))
wordVectors[1:6,1:10]

# Look at a work
walking <- wordVectors['walk', , drop = F]
walking

# We can try to find a word analogy; drop=F keeps it as a matrix
# New vector values are have the hyperspace location of a walk, removing context values for disappointed and adding in the context values for good, making a new location mixing these three elements
goodWalks <- wordVectors['walk', , drop = F] -
  wordVectors['disappointed', , drop = F] +
  wordVectors['good', , drop = F]
goodWalks

# With these new values we can use cosine similarity to find the closest related vector and its associated term; this fuinction calculates c("cosine", "jaccard") 
# similarities
similarGoodWalk <- sim2(x = wordVectors, 
                        y = goodWalks, 
                        method = "cosine")
head(similarGoodWalk)
similarGoodWalk <- similarGoodWalk[order(similarGoodWalk[,1], decreasing = T),]
head(similarGoodWalk, 20)

# We can explore one more
dirtySink <- wordVectors['sink', , drop = FALSE] -
  wordVectors['condition', , drop = FALSE] +
  wordVectors['dirty', , drop = FALSE]
similarDirtySink <- sim2(x = wordVectors, 
                        y = dirtySink, 
                        method = "cosine",
                        norm = "l2")

similarDirtySink <- similarDirtySink[order(similarDirtySink[,1], decreasing = T),]
head(similarDirtySink, 25)

# End