#' Title: Grab Youtube JSON
#' Purpose: Demonstrate f12 in Chrome for API
#' Author: Ted Kwartler
#' email: edwardkwartler@fas.harvard.edu
#' License: GPL>=3
#' Date: Apr 15, 2024
#'

# Libraries
library(jsonlite)
library(stringr)
library(plyr)

# Options; google api returns UTF-8 text
Sys.setlocale("LC_CTYPE", "en_US.UTF-8")

# Youtube URL
# https://www.youtube.com/watch?v=K5Rly83zfuI&ab_channel=TheDailyShowwithTrevorNoah
# https://www.youtube.com/watch?v=sal78ACtGTc&ab_channel=SequoiaCapital
youtubeCaption <- 'https://www.youtube.com/api/timedtext?v=sal78ACtGTc&ei=DzM7aZ30Mr2xp-oPm-vA0A0&caps=asr&opi=112496729&exp=xpe&xoaf=5&xowf=1&hl=en&ip=0.0.0.0&ipbits=0&expire=1765512575&sparams=ip%2Cipbits%2Cexpire%2Cv%2Cei%2Ccaps%2Copi%2Cexp%2Cxoaf&signature=8C0468D276D0DD78D77455CE67610B7F4FF21F1E.35A3FC570DA88CA72BA805CFBBC5CEBE02AE1E&key=yt8&kind=asr&lang=en&potc=1&pot=MlghC9gJpy2-5yFKcfkCf1E3Ir4rbE_C-CgkJuJrrJusAf-DSuhid6qTK6jOmUc72GubkdFNbOKl2J2zUwE1t3sAZAp1cWtYQ37WqO_sNhFgy87qFUzBRWrh&fmt=json3&xorb=2&xobt=3&xovt=3&cbrand=apple&cbr=Chrome&cbrver=142.0.0.0&c=WEB&cver=2.20251210.09.00&cplayer=UNIPLAYER&cos=Macintosh&cosver=10_15_7&cplatform=DESKTOP'

# Go get the data
dat <- fromJSON(youtubeCaption) # you can even pass in a URL to go to a webpage

# closed captioning data
dat$events$tStartMs
dat$events$dDurationMs
dat$events$segs[1:10]

# Get each first column called utf8
rawTxt <- lapply(dat$events$segs, "[", 'utf8') 

# organize just the single column
rawTxt <- do.call(rbind, rawTxt)

# Drop line returns "\n"
rawTxt <- gsub('[\r\n]',' ',rawTxt[,1])

# Sometimes there are entries that are empty so they need to be dropped
head(rawTxt,10)
rawTxt <- rawTxt[nchar(rawTxt) != "0"]

# Sometimes, there is extra spacing from the gsub
rawTxt <- str_squish(rawTxt)

# If you want it as a single chunk
oneChunk <- paste(rawTxt, collapse = ' ')

# If you want to retain the meta data
tmpText <- lapply(dat$events$segs, "[", 'utf8') #grab the UTF text cols
tmpTextList <- lapply(tmpText, function(x) {
  if(is.null(x)){
    'NULL'
  } else {
    tmp <- apply(x, 2, paste0, collapse = ' ')
    tmp <- trimws(tmp)
    }
  })


textDF <- data.frame(startTime = dat$events$tStartMs/1000,
                     duration  = dat$events$dDurationMs/1000,
                     text = gsub(" {2,}", " ", unlist(tmpTextList)))

# Examine to make sure format is ok
head(textDF, 10)

# End
