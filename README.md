# Analyzing tagged data
**Author**: Srikanth K S (talegari)  
**email**: gmail sri.teach   
**Repository**: [https://github.com/talegari/analyzing-tagged-data](https://github.com/talegari/analyzing-tagged-data)

----

## Objective

We intend to explore the data with tags.

Here is an example of tagged data.



| MS Word | Libreoffice Writer | abiword | notepad++ |
|:---------:|:--------------------:|:---------:|:-----------:|
|         | free               | free    | free      |
| docx    | odt                | abw     | txt       |
| all     | all                |         | limited   | |




* There are four objects: **MS Word**, **Libreoffice Writer**, **abiword**, **notepad++**

* Each object have their respective tags. For example: The object **abiword** as tags 'free' and 'abw'. The order of tags does not matter.

We provide,

* A recommender system to suggest objects or tags based on set of *visited* objects or tags.

* A report generator of different visualizations of the tagged data. See *output.html* or *output.pdf* in the repository for a trial data.

----

## Requirements

* [R](http://www.r-project.org/), version 3.2.1
* [Rstudio](https://www.rstudio.com/products/RStudio/), an IDE for R.  
(if you are a **R** user, you may choose to do without RStudio)
* The following packages: `dplyr`,`reshape2`,`ggplot2`,`knitr`,`downloader` and their dependencies.

----

## Usage

* If you are not familiar with **R**:
	* Download the repository from : [https://github.com/talegari/analyzing-tagged-data](https://github.com/talegari/analyzing-tagged-data)
	* To know your working directory, use the command `getwd()`. Unzip the zip file, as folder `analyzing-tagged-data-master` in the working directory.
	* Run setup by `source("analyzing-tagged-data-master/setup.R")`. In case of problems, see *Troubleshooting SETUP* section of this document.
    
* If you are a **R** user:

    * The functions necessary for the program are in `vistagdata.R`.
    * You may like to setup defaults for *output.Rmd* in the `global options` at the beginning of the file.

----

## Format of input data

Data input format: **csv**

* The first line is considered as the set of objects
* The corresponding columns are considered as their tags.
* All the data is considered as *text*. That is, we do not recognize any data type as say *date*, *number* etc.

For example, see 'taggeddataset.csv' in the repository.

<center>**We do not do any post processing on the CSV file.**</center>

----


## Files in the repository

* **setup.R** -- SETUP script for those who are familiar with **R**

* **vistagdata.R** -- the code used for recommender system and visualization.

* **output.Rmd** -- code used to generate the html or pdf with the visualizations. This will be processed by *knitr*.

* **taggeddataset.csv** -- the example dataset.

Repository contains *output.pdf*, *output.html* which are outputs of the *output.Rmd* on the trial dataset.

----

### Recommender system

* There are four functions.

|   Function  |                     task                     |
|:-----------:|:--------------------------------------------:|
| oorecommend | ... recommends  objects based on visited objects |
| ttrecommend | ... recommends tags based on visited tags |
| otrecommend | ... recommends tags based on visited objects |
| torecommend | ... recommends objects based on visited tags |


* The syntax of the functions are similar. They take the *path to csv* as the first argument and visited character vector as the second argument. They return a dataframe. For example:

`View(oorecommend("taggeddataset.csv",visited=c("bear","monkey")))`


gives the following output

|   |  object  | percentageMatch |
|---|:--------:|:---------------:|
| 1 | tiger    |               62 |
| 2 | elephant |               62 |
| 3 | dog      |               38 |
| 4 | fish     |               38 |
| 5 | cat      |               29 |

----

### Using 'weight'ed versions

**(Added in version 1.1)**:
A new optional argument *weights* is added some functions. We want to emphasize some tags/objects by *weighing* them more as compared to other tags/objects.

Consider 
`kmcluster("taggeddataset.csv",weights=c(3))`

It ends up putting `cat` and `tiger` in the same cluster(as opposed to the default `kmcluster("taggeddataset.csv")` where `cat` and `tiger` were in different clusters). The *weights* are associated with the tags(totally 12 in this example) of the data. We give a weight of 3 to the first tag(which happens to be `claw`) and a default of 1 to the rest of the tags(1 is automatically padded at the end). As only `cat` and `tiger` share the common tag `claw`, the higher *weight* for `claw` over weighs other dissimilarities and puts them in the same cluster.

These functions have the optional `weights` argument (defaults to equal weights): `incdat`, `hcluster`, `kmcluster`, `oorecommend`, `ttrecommend`


----

### Tagged data visualization

* On knitting **output.Rmd**, we can produce pdf or html or docx output. (look for `knit html` or `knit pdf` button after opening *output.Rmd* in RStudio.)

* These visualizations are generated:

    1. Visualizing objects versus tags
    2. Visualizing tags versus objects
    3. Hierarchical object clustering (a dendogram)
    4. Hierarchical tag clustering (a dendogram)
    5. Heatmap of objectwise hierarchical clustering
    6. Heatmap of tagwise hierarchical clustering
    7. Clusters among objects (using kmeans)
    8. Clusters among tags (using kmeans)
    9. Number of tags shared by objects
    10. Number of objects shared by tags

* 7th and 8th visualizations above use kmeans algorithm that requires the input of number of clusters. We currently employ a crude estimate for this, please try different values and decide the best number.

* By default, the report displays the code too. You may want to put it off by setting 'echo=F' in the *global settings* at the beginning of the *output.Rmd*

----

## Troubleshooting SETUP

The following troubleshooting messages help troubleshooting.

* message: `There is a problem with installing the following package`
    * Restart R (command: `ctrl+shift+F10` in RStudio) and run the SETUP again. If the problem persists, check your internet connection. Still, if problem persists,  refer 'Troubleshooting SETUP' in README"

* message: `Cannot find the package`
    * Check your internet connection.
    
* message: `Warning message: In download.file(url, method = method, ...) : downloaded length 637284 != reported length 0`
    * check your internet connection.
    
* message: `package xyz was built inder R <versionnumber>`
    * You are using an older version of R, usually not a problem.
    
Beyond, all of these, if the problem persists, write to me: `gmail sri.teach`

----

## Technical details

Coming soon!

----
