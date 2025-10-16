# Libraries
library(httr)      
library(jsonlite)  
library(stringr)  

# Inputs
#prompt <- "Write an R script to calculate the sum of numbers from 1 to 10 and print the result."
#prompt <- "What is the capital of Brazil?"
#prompt <- 'Write ggplot2 code to make a scatter plot of 100 random numbers.  The plot should have a title that says 100 random values.'
prompt <- "Using the following text, write code to make a word cloud.  The text is: I love this course, it has been so hard but fun  I will bring this love of NLP back to my role for more fun."
savePath <- '~/Desktop/GSERM_2025/personalFiles/'

# LLM Names
llmModel <- 'llama-3.2-1b-instruct' #small general purpose
codingLLM <- 'qwen2.5-7b-instruct'  #"slow" but "smarter"     
# According to reddit users, worth testing out: 
# gemma3:1B is good at coding
# gemma3 4B is good at multi0lingual   

# LLM API Endpoint
llmURL <- "http://localhost:1234/v1/chat/completions"

# Since we're making repeated LLM calls its best to have a function.
callLLM <- function(modelName = 'llama-3.2-1b-instruct', 
                     messagesList = "What is the capital of Brazil?",
                     sysPrompt = "You are a helpful, smart, kind, and efficient AI assistant. You always fulfill the user's requests to the best of your ability.",
                     temp = 0.7,
                     maxTokens = 512, 
                     stream = F) {
  
  dataLLM <- list(model = modelName,
                  messages = list(
                    list(role = "system", content = sysPrompt),
                    list(role = "user", content = prompt)),
                  temperature = temp,
                  max_tokens = maxTokens,
                  stream = stream)
  # Request header
  headers <- c(`Content-Type` = "application/json")
  
  # Make the POST request
  res <- httr::POST(url = "http://localhost:1234/v1/chat/completions",
                    httr::add_headers(.headers = headers),
                    body = toJSON(dataLLM, auto_unbox = TRUE))
  
 
  
  # Extract the content of the response as text
  llmResponse <- httr::content(res)$choices[[1]]$message$content
  return(llmResponse)
}

###
# Now we have a simple agentic workflow where one agent is able to answer questions but 
# it can decide to ask a "specialized" LLM for a task.

# Starting system prompt - sometimes this model will still write R code :( but its ignored at this stage
initialSystemPrompt <- "Do not write any code.  Only describe what needs to be done for a developer. You are a helpful, smart, kind, and efficient product manager AI assistant.  You do not know the R programming language and cannot write it.  You can describe what is needed functionally but not write code.  If the user's request is about writing code or programming in R, respond with 'CODE_TASK: ' followed by a precise description of the R coding task.  Do not write the code.  Instead respond with 'CODE_TASK:' followed by a functional specification. For example, if the user asks 'Write an R function to calculate factorial', you should respond\n\n 'CODE_TASK: Write an R function to create a scatter plot of random numbers'. \n\nIf the request is not about coding, answer the user's request directly and concisely."

initialLLMResponse <- callLLM(modelName =llmModel , 
                              messagesList = prompt,
                              sysPrompt = initialSystemPrompt)

# Now we classify the task 
if(grepl('CODE_TASK:', initialLLMResponse)==T){
  cat('This looks like a coding task. I will ask the other LLM\n')
  codingSysPrompt <- "You are an expert R programmer. Your task is to write a complete, runnable R script based on the user's request. Enclose the R code within a markdown code block (``` ... ```). Do not include any explanations or conversational text outside of the code block. Ensure the script is self-contained and complete.  The code will be run with source().  DO NOT USE install.packages(), ONLY call library() when needed. If there is a final output of the code it must be printed, or called to display the output."
  
  # Call the coding LLM. Increase max_tokens as code can be lengthy.
  codingLLMResponse <- callLLM(modelName =codingLLM, 
                                messagesList = initialLLMResponse,
                                sysPrompt = codingSysPrompt,
                                maxTokens = 2048)

  # Now we need to extract the code which should start ```r and end ``` delimiters
  # So I am searching for them and keeping the text between
  tmpCode <- capture.output(cat(codingLLMResponse))
  idx <- grep('```', tmpCode)
  if(length(idx)!=2){stop(paste('code syntax error from the coding LLM:',codingLLMResponse))}
  st <- idx[1]+1
  en <- idx[2]-1
  onlyCode <- paste(tmpCode[st:en], collapse = '\n')
  
  # Now let's save a copy of the automated script
  nam <- paste0('CODE_TASK_', Sys.time(),'.R') # Define the name of the file to save the script
  writeLines(onlyCode, paste0(savePath,nam))
  cat(paste('R script create called:', nam,'\n'))
  
  print('now running the saved R script\n')
  source(paste0(savePath,nam))
} else {
  print(initialLLMResponse)
}
