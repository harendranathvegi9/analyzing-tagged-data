# to get/load necessary packages
pkgTest <- function(x)
{
  if (!require(x,character.only = TRUE))
  {
    install.packages(x,dep=TRUE)
    if(!require(x,character.only = TRUE)) stop("Package not found")
  }
}

longdat <- function(dat,toclassify="object")
  { library(reshape2)
    # to return a df with object, tag and a value(1) column
    objtag <- melt(t(dat))[,c(1,3)]
    colnames(objtag) <- c("object","tag")
    objtag$value <- rep(1,dim(objtag)[1])    # for a later dcast
    objtag <- subset(objtag,objtag$tag!="")
    ifelse(toclassify=="object",            # ordering wrt 'toclassify'   
           objtago <- order(objtag$object,objtag$tag),
           objtago <- order(objtag$tag,objtag$object))
    objtag <- objtag[objtago,]
    return(objtag)  
  }

# get inclusion matrix from longdata
incdat <- function(dat,toclassify="object")
{
  library(reshape2)
  # get inclusion df based on 'toclassify'
  ifelse(toclassify=="object",incd <- dcast(dat,object~tag),incd <- dcast(dat,tag~object))
  incd[is.na(incd)] <- 0         # set NA's to 0
  rownames(incd) <- incd[,1]     # set first column as rownames
  incd <- incd[,-1]              # and delete it
  return(incd)
}

# hcluster takes longdata
hcluster <- function(dat,meth="average")
  { 
    hcobj <- hclust(dist(dat,method="manhattan"),method=meth)
    par(mar=c(0, 2, 2, 0)) # c(bottom, left, top, right)
    plot(hcobj, xlab="", sub="")
  }

# hclusterhm (hierarchial clustering heat map) takes incdata
hclusterhm <- function(dat)
{ 
  heatmap(as.matrix(dat))
}


# kmeans clustering takes incdata
kmcluster <- function(dat,nc=0,ns=50)
{
  require(ggplot2)
  if(nc==0){nc <- round(sqrt(dim(dat)[[1]]/2))}
  kmeansobj <- kmeans(x=as.matrix(dat),centers=nc,nstart=ns)
  return(kmeansobj)
}

# matrix with number of common tags shared by objects
# input: takes inclusion df
sharedtable <- function(dat)
{
  dim(dat)[[2]]-as.matrix(dist(dat,method="manhattan"))
}

# a tiny recommender system based on tagged data

# recommend objects based on objects
oorecommend <- function(dat,visited)
{ 
  objects <- tolower(colnames(dat))
  visited <- objects[objects %in% tolower(visited)]
  # removed visits not in objects
  if(length(visited)==0){stop("Invalid or NULL 'visited' data")}
  if(length(visited)==length(objects)){stop("All objects are 'visited': No recommendations")}
  inc <- incdat(longdat(dat))
  visitedinc <- subset(inc,rownames(inc) %in% visited)
  visitedincvector <- apply(visitedinc,2,mean)
  newinc <- t(t(inc)[,objects[objects %in% visited==F]])
  distfun <- function(row){dist(rbind(visitedincvector,row),method="manhattan")}
  distances <- apply(newinc,1,distfun)
  dsorted <- sort(distances)
  notags <- dim(inc)[2]
  df <- data.frame(object=names(dsorted),percentageMatch=round(((notags-dsorted)/notags)*100))
  rownames(df) <- NULL
  df
}

# recommend tags based on tags
ttrecommend <- function(dat,visited)
{
  tags <- tolower(as.character(unique(longdat(dat)[,2])))
  visited <- tags[tags %in% tolower(visited)] 
  # removed visits not in tags

  # handling special cases
  if(length(visited)==0){stop("Invalid or NULL 'visited' data")}
  if(length(visited)==length(tags)){stop("All tags are 'visited': No recommendations")}
  
  inc <- incdat(longdat(dat),toclassify="tag")
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
otrecommend <- function(dat,visited)
{
  objects <- tolower(colnames(dat))
  tags <- tolower(as.character(unique(longdat(dat)[,2])))
  
  # remove visits not in objects
  visited <- objects[objects %in% tolower(visited)]
  # handling special cases
  if(length(visited)==0){stop("Invalid or NULL 'visited' data")}
  
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

torecommend <- function(dat,visited)
{
  tags <- tolower(as.character(unique(longdat(dat)[,2])))
  visited <- tags[tags %in% tolower(visited)] 
  # removed visits not in tags
  objectsvector <- subset(longdat(dat)$object,longdat(dat)$tag %in% visited)
  
  df <- data.frame(table(objectsvector))
  colnames(df) <- c("object","frequency")
  df <- df[order(df$frequency,df$object,decreasing=T),]
  df$percentageMatch <- round((df$frequency/sum(df$frequency))*100)
  rownames(df) <- NULL
  return(df)
}