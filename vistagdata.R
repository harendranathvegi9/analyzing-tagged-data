# functions for 'Analyzing tagged data'

# a function to load necessary packages
loadpackages <- function()
  {
  loaddata <- lapply(c("dplyr","ggplot2","reshape2","knitr","rmarkdown","mime", "stringi", "magrittr", "evaluate", "digest", "formatR", "highr", "markdown", "stringr", "yaml","rmarkdown","knitr"),suppressPackageStartupMessages(require),character.only=T)
  rm(loaddata)
}
loadpackages()

# pad a integer vector on left or right to get a desired length
pad <- function(integerVector,finalLength,padwith=0,side=1)
  {
  ifelse(finalLength>length(integerVector),
         appendLength <- finalLength-length(integerVector),
         stop('finalLength is not greater than length of integerVector')
  )
  
  ifelse(side==1,
         returnVector <- c(integerVector,rep(padwith,appendLength)),
         returnVector <- c(rep(padwith,appendLength),integerVector)
  )
  returnVector
}

# convert wide data to long data format

longdat <- function(pathtocsv,toclassify="object")
  { 
    
    dat <- read.csv(pathtocsv,fill=T,colClasses="character")
    
    # to return a df with object, tag and a value(1) column
    objtag <- melt(t(dat))[,c(1,3)]
    colnames(objtag) <- c("object","tag")
    objtag$value <- rep(1,dim(objtag)[1])    # for a later dcast
    
    # discard values of empty objects and empty tags
    objtag <- subset(objtag,objtag$tag!="")
    objtag <- subset(objtag,objtag$object!="")
    
    # ordering wrt 'toclassify'
    ifelse(toclassify=="object",               
           objtago <- order(objtag$object,objtag$tag),
           objtago <- order(objtag$tag,objtag$object))
    objtag <- objtag[objtago,]
    return(objtag)  
  }

# get inclusion matrix from longdata
incdat <- function(pathtocsv,toclassify="object",weights=1)
  {
    # sanity check on weights
    # check whether weights are numeric or integer
    if(class(weights)!='numeric' & class(weights)!='integer')
        {stop('class of weights vector should be either numeric or integer')}
    # checks whether the weights are non-negative
    if(any(weights<0))
        {stop('weights should be non-negative')}
  
    dat <- pathtocsv %>% longdat
    # get inclusion df based on 'toclassify'
    ifelse(toclassify=="object",
           incd <- dcast(dat,object~tag),
           incd <- dcast(dat,tag~object)
           )
    incd[is.na(incd)] <- 0         # set NA's to 0
    rowNames <- incd[,1]     
    incd <- incd[,-1]              # and delete it
    
    # set 'num' to length of number of tags/objects
    if(toclassify=='object')
          {
            # set length of tags
            num <- subset(dat[,2],dat[,2]!='') %>% unique %>% length
          }
    else
          {
            # set length of objects
            num <- subset(dat[,1],dat[,1]!='') %>% unique %>% length
          }
    
    # pad the weights
    w <- pad(integerVector=weights,finalLength=num,padwith=1)
    
    # inclusion matrix with weights
    incd <- apply(as.matrix(incd),1,function(x){x*w}) %>% t
    rownames(incd) <- rowNames
    incd
  }

# hcluster takes incdata
hcluster <- function(pathtocsv,toclassify="object",meth="average",weights=1)
  { 
    dat <- pathtocsv %>% incdat(toclassify=toclassify,weights=weights)
  
    hcobj <- hclust(dist(dat,method="manhattan"),method=meth)
    par(mar=c(0, 2, 2, 0)) # c(bottom, left, top, right)
    plot(hcobj, xlab="", sub="")
  }

# clustering using k means
kmcluster <- function(pathtocsv,toclassify="object",nc=0,ns=50,elbow=15,weights=1)
  {
  dat <- pathtocsv %>% incdat(toclassify=toclassify,weights=weights)
  
  ifelse(toclassify=="object",
         maxclusters <- longdat(pathtocsv)[,1] %>% unique %>% length, 
         maxclusters <- longdat(pathtocsv)[,2] %>% unique %>% length)
  
  if(nc==0)
  {
    
    ppchange <- function(vec) # percentage change
    {
      sapply(2:length(vec),function(x){((vec[x]-vec[x-1])/vec[x-1])*100})
    }
    
    variancefun <-  function(noc) # variance explained by kmeans
    {
      out <- tryCatch(
        {
          kmeansobj <- suppressMessages(kmeans(x=as.matrix(dat),centers=noc,nstart=ns))
          (kmeansobj$betweenss/kmeansobj$totss)*100
        },
          error=function(cond){return(NA)}
      ) # end of tryCatch
    return(out)
    } # end of variance fun

varper <- sapply(2:maxclusters,variancefun) %>% ppchange
nc <- ifelse(length(which(!varper>elbow))==0,
             na.omit(varper) %>% as.numeric %>% length,
             which(!varper>elbow)[1])
  } # end of if when nc is 0

suppressMessages(kmeans(x=as.matrix(dat),centers=nc,nstart=10)) %>% return
}

# matrix with number of common tags shared by objects
sharedtable <- function(pathtocsv,toclassify="object")
{
  dat <- pathtocsv %>% incdat(toclassify=toclassify)
  dim(dat)[2]-as.matrix(dist(dat)) %>% return
}

# a tiny recommender system based on tagged data

# recommend objects based on objects
oorecommend <- function(pathtocsv,visited,weights=1)
{ 
  dat <- read.csv(pathtocsv,fill=T,colClasses="character")
  objects <- longdat(pathtocsv)[,1] %>% unique %>% tolower

  # removed visits not in objects
  visited <- objects[objects %in% tolower(visited)]
  
  # sanity check on 'visited'
  if(length(visited)==0)
    {stop("Invalid or NULL 'visited' data")}
  if(length(visited)==length(objects))
    {stop("All objects are 'visited': No recommendations")}
  
  inc <- incdat(pathtocsv,weights=weights)
  visitedinc <- subset(inc,rownames(inc) %in% visited)
  visitedincvector <- apply(visitedinc,2,mean)
  newinc <- t(inc)[,objects[objects %in% visited==F]] %>% t
  
  distfun <- function(row){dist(rbind(visitedincvector,row),method="manhattan")}
  
  distances <- apply(newinc,1,distfun)
  dsorted <- sort(distances)
  notags <- dim(inc)[2]
  df <- data.frame(object=names(dsorted),percentageMatch=round(((notags-dsorted)/notags)*100))
  rownames(df) <- NULL
  df
}

# recommend tags based on tags
ttrecommend <- function(pathtocsv,visited,weights=1)
{
  dat <- read.csv(pathtocsv,fill=T,colClasses="character")
  tags <- longdat(pathtocsv)[,2] %>% unique %>% tolower
  # remove visits not in tags
  visited <- tags[tags %in% tolower(visited)] 
  
  # handling special cases
  if(length(visited)==0)
    {stop("Invalid or NULL 'visited' data")}
  if(length(visited)==length(tags))
    {stop("All tags/objects are 'visited': No recommendations")}
  
  inc <- incdat(pathtocsv,toclassify="tag",weights=weights)
  visitedinc <- subset(inc,rownames(inc) %in% visited)
  visitedincvector <- apply(visitedinc,2,mean)
  newinc <- t(t(inc)[,tags[tags %in% visited==F]])
  distfun <- function(row){dist(rbind(visitedincvector,row),method="manhattan")}
  distances <- apply(newinc,1,distfun)
  dsorted <- sort(distances)
  noobjects <- dim(inc)[2]
  df <- data.frame(tag=names(dsorted),percentageMatch=round(((noobjects-dsorted)/noobjects)*100))
  rownames(df) <- NULL
  df
}

# recommend tags based on objects
otrecommend <- function(pathtocsv,visited)
{
  dat <- read.csv(pathtocsv,fill=T,colClasses="character")
  objects <- longdat(pathtocsv)[,1] %>% unique %>% tolower
  tags <- longdat(pathtocsv)[,2] %>% unique %>% tolower
  # remove visits not in objects
  visited <- objects[objects %in% tolower(visited)]
  
  # handling special cases
  if(length(visited)==0)
    {stop("Invalid or NULL 'visited' data")}
  if(length(visited)==length(objects))
    {stop("All objects/tags are visited : No recommendations.")}
  
  tagsvector <- as.vector(as.matrix(dat[,visited]))
  df <- data.frame(table(tagsvector))
  colnames(df) <- c("tag","frequency")
  df <- df[order(df$frequency,df$tag,decreasing=T),]
  df$percentageMatch <- round((df$frequency/sum(df$frequency))*100)
  rownames(df) <- NULL
  return(df)
}

torecommend <- function(pathtocsv,visited)
{
  dat <- read.csv(pathtocsv,fill=T,colClasses="character")
  tags <- longdat(pathtocsv)[,2] %>% unique %>% tolower
  # remove visits not in tags
  visited <- tags[tags %in% tolower(visited)]
  
  # handling special cases
  if(length(visited)==0)
    {stop("Invalid or NULL 'visited' data")}
  if(length(visited)==length(tags))
    {stop("All objects/tags are visited: No recommendations")}
  
  objectsvector <- subset(longdat(pathtocsv)$object,longdat(pathtocsv)$tag %in% visited)
  
  df <- data.frame(table(objectsvector))
  colnames(df) <- c("object","frequency")
  df <- df[order(df$frequency,df$object,decreasing=T),]
  df$percentageMatch <- round((df$frequency/sum(df$frequency))*100)
  rownames(df) <- NULL
  return(df)
}
