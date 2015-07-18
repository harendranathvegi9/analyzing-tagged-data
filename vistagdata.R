# functions for 'Analyzing tagged data'

# a function to load necessary packages
loadpackages <- function()
{
  loaddata <- lapply(c("dplyr","ggplot2","reshape2","knitr","rmarkdown","mime", "stringi", "magrittr", "evaluate", "digest", "formatR", "highr", "markdown", "stringr", "yaml","rmarkdown","knitr"),suppressPackageStartupMessages(require),character.only=T)
  rm(loaddata)
}
loadpackages()

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
incdat <- function(pathtocsv,toclassify="object")
  {
    
    dat <- pathtocsv %>% longdat
    # get inclusion df based on 'toclassify'
    ifelse(toclassify=="object",incd <- dcast(dat,object~tag),incd <- dcast(dat,tag~object))
    incd[is.na(incd)] <- 0         # set NA's to 0
    rownames(incd) <- incd[,1]     # set first column as rownames
    incd <- incd[,-1]              # and delete it
    return(incd)
  }

# hcluster takes incdata
hcluster <- function(pathtocsv,toclassify="object",meth="average")
  { 
    dat <- pathtocsv %>% incdat(toclassify=toclassify)
  
    hcobj <- hclust(dist(dat,method="manhattan"),method=meth)
    par(mar=c(0, 2, 2, 0)) # c(bottom, left, top, right)
    plot(hcobj, xlab="", sub="")
  }


# kmeans clustering takes incdata
kmcluster <- function(pathtocsv,toclassify="object",nc=0,ns=50,elbow=15)
{
  dat <- pathtocsv %>% incdat(toclassify=toclassify)
  
  ifelse(toclassify=="object",
         maxclusters <- read.csv(pathtocsv,fill=T,colClasses="character") %>% colnames %>% length, 
         maxclusters <- longdat(pathtocsv)[,2] %>% unique %>% length)
  
  if(nc==0)
  {
    
    ppchange <- function(vec) # pairwise percentage change
    {
      sapply(2:length(vec),function(x){((vec[x]-vec[x-1])/vec[x-1])*100})
    }
    
    variancefun <-  function(noc) # variance explained by kmeans
    {
      kmeansobj <- suppressMessages(kmeans(x=as.matrix(dat),centers=noc,nstart=ns))
      (kmeansobj$betweenss/kmeansobj$totss)*100
    }
    
    varper <- sapply(2:(maxclusters-1),variancefun) %>% ppchange
    nc <- which(!varper>elbow)[1]
  }
  
  suppressMessages(kmeans(x=as.matrix(dat),centers=nc,nstart=ns)) %>% return
}

# matrix with number of common tags shared by objects
# input: takes inclusion df
sharedtable <- function(pathtocsv,toclassify="object")
{
  dat <- pathtocsv %>% incdat(toclassify=toclassify)
  
  dim(dat)[2]-as.matrix(dist(dat,method="manhattan")) %>% return
}

# a tiny recommender system based on tagged data

# recommend objects based on objects
oorecommend <- function(pathtocsv,visited)
{ 
  dat <- read.csv(pathtocsv,fill=T,colClasses="character")
  objects <- tolower(colnames(dat))
  visited <- objects[objects %in% tolower(visited)]
  # removed visits not in objects
  
  if(length(visited)==0){stop("Invalid or NULL 'visited' data")}
  if(length(visited)==length(objects)){stop("All objects are 'visited': No recommendations")}
  
  inc <- incdat(pathtocsv)
  
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
ttrecommend <- function(pathtocsv,visited)
{
  dat <- read.csv(pathtocsv,fill=T,colClasses="character")
  tags <- tolower(as.character(unique(longdat(pathtocsv)[,2])))
  visited <- tags[tags %in% tolower(visited)] 
  # removed visits not in tags

  # handling special cases
  if(length(visited)==0){stop("Invalid or NULL 'visited' data")}
  if(length(visited)==length(tags)){stop("All tags/objects are 'visited': No recommendations")}
  
  inc <- incdat(pathtocsv,toclassify="tag")
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
  objects <- tolower(colnames(dat))
  tags <- tolower(as.character(unique(longdat(pathtocsv)[,2])))
  
  # remove visits not in objects
  visited <- objects[objects %in% tolower(visited)]
  
  # handling special cases
  if(length(visited)==0){stop("Invalid or NULL 'visited' data")}
  if(length(visited)==length(tags)){stop("All objects/tags are visited : No recommendations.")}
  
  tagsvector <- as.vector(as.matrix(dat[,visited]))
  # remove "" from tagsvector
  tagsvector <- tagsvector[tagsvector!=""]
  
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
  tags <- tolower(as.character(unique(longdat(pathtocsv)[,2])))
  visited <- tags[tags %in% tolower(visited)] 
  # removed visits not in tags
  
  
  # handling special cases
  if(length(visited)==0){stop("Invalid or NULL 'visited' data")}
  if(length(visited)==length(tags)){stop("All objects/tags are visited: No recommendations")}
  
  objectsvector <- subset(longdat(pathtocsv)$object,longdat(pathtocsv)$tag %in% visited)
  
  df <- data.frame(table(objectsvector))
  colnames(df) <- c("object","frequency")
  df <- df[order(df$frequency,df$object,decreasing=T),]
  df$percentageMatch <- round((df$frequency/sum(df$frequency))*100)
  rownames(df) <- NULL
  return(df)
}
