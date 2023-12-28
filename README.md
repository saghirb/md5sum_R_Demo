
<!-- README.md is generated from README.Rmd. Please edit that file    -->

## Demo for `tools::md5sum()`

The `tools::md5sum()` function computes the 32-byte MD5 hashes of one or
more files.

From the `md5sum` help page:

> A MD5 ‘hash’ or ‘checksum’ or ‘message digest’ is a 128-bit summary of
> the file contents represented by 32 hexadecimal digits. Files with
> different MD5 sums are different: only very exceptionally (and usually
> with the intent to deceive) are those with the same sums different.

> On Windows all files are read in binary mode (as the md5sum utilities
> there do): on other OSes the files are read in the default mode
> (almost always text mode where there is more than one).

> MD5 sums are used as a check that R packages have been unpacked
> correctly and not subsequently accidentally modified.

### Step 0: Load packages

The `md5sum()` function is in the `tools` package.

``` r
library(tools) 
library(data.table)
```

### Step 1: Create some source files

Write some source test files to a temporary directory. These are the
files for which we will create the source (reference) md5 hashes.

``` r
# Create a temporary directory for the source files. 
tmpDir <- paste0(tempdir(), "/testArea")

# Create a directory structure with subfolders
dir.create(paste(tmpDir, "subf1", "subf2", sep = "/"), recursive = TRUE)

# Write some text and binary files
write.csv(PlantGrowth, file = paste(tmpDir, "PlantGrowth.csv", sep = "/"))
write.csv(ChickWeight, file = paste(tmpDir, "subf1", "ChickWeight.csv", sep = "/"))
write.csv(trees, file = paste(tmpDir, "subf1", "subf2", "trees.csv", sep = "/"))
write.csv(volcano, file = paste(tmpDir, "subf1", "subf2", "volcano.csv", sep = "/"))
saveRDS(ChickWeight, file = paste(tmpDir, "subf1", "ChickWeight.Rdata", sep = "/"))
saveRDS(trees, file = paste(tmpDir, "subf1", "subf2", "trees.Rdata", sep = "/"))
```

List the source files.

``` r
listTmpFiles <- list.files(tmpDir, full.names = FALSE, recursive = TRUE)
listTmpFiles
```

    ## [1] "PlantGrowth.csv"         "subf1/ChickWeight.csv"  
    ## [3] "subf1/ChickWeight.Rdata" "subf1/subf2/trees.csv"  
    ## [5] "subf1/subf2/trees.Rdata" "subf1/subf2/volcano.csv"

### Step 2: Create source MD5 hashes dataset

Create a dataset with MD5 check sums for the source files.

``` r
wdOrig <- getwd()
setwd(tmpDir)
MD5.orig <- data.table(fileName = listTmpFiles)[
  , md5Orig := lapply(fileName, md5sum)][
  , md5OrigText := paste0(md5Orig, " ", fileName)][
    , .(md5OrigText)]
MD5.orig
```

    ##                                                 md5OrigText
    ## 1:         e6064331c76ef3defb9eff852f877da4 PlantGrowth.csv
    ## 2:   cc7feea5a98cabc13f282007155a0f69 subf1/ChickWeight.csv
    ## 3: 4a04111b96586fe4f55a3ab113301c2d subf1/ChickWeight.Rdata
    ## 4:   eda0aee4b42aa6853f11051174de41af subf1/subf2/trees.csv
    ## 5: dae508a52417a808b2d0e8ff1d6f2da8 subf1/subf2/trees.Rdata
    ## 6: 7f75c2935f5b95e138ab62bf28bc7e32 subf1/subf2/volcano.csv

Write source MD5 hashes followed by the respective file name to a `.md5`
file.

``` r
md5Filename <- paste0(tmpDir, "/", "orig.md5")
writeLines(text = MD5.orig$md5OrigText, con = md5Filename)
```

> Note: On \*nix systems the file `orig.md5` can be check using
> `md5sum -c orig.md5`.

### Step 3: Create a corrupted version of source files to check

To simulate a user receiving a corrupted version of the source files,
let’s intentionally make some changes to the source files to get MD5
hash errors during the checks below.

Change a file name to get an error when we check the MD5 hashes below.

``` r
file.rename(from = paste(tmpDir, "subf1", "subf2", "trees.csv", sep = "/"),
            to = paste(tmpDir, "subf1", "subf2", "TREES.csv", sep = "/"))
```

    ## [1] TRUE

Change the content of another file to get an error when we check the MD5
hashes below.

``` r
file.append(paste(tmpDir, "subf1", "ChickWeight.csv", sep = "/"), 
            paste(tmpDir, "PlantGrowth.csv", sep = "/"))
```

    ## [1] TRUE

``` r
setwd(wdOrig)
```

These are the corrupted files that the user will actually receive.

``` r
listTmpCorruptedFiles <- list.files(tmpDir, full.names = FALSE, recursive = TRUE)
listTmpCorruptedFiles
```

    ## [1] "orig.md5"                "PlantGrowth.csv"        
    ## [3] "subf1/ChickWeight.csv"   "subf1/ChickWeight.Rdata"
    ## [5] "subf1/subf2/TREES.csv"   "subf1/subf2/trees.Rdata"
    ## [7] "subf1/subf2/volcano.csv"

### Step 4: Generate the MD5 hashes for the corrupted files

``` r
setwd(tmpDir)
# Check all files except the orig.md5 file. 
checkFiles <- list.files(tmpDir, full.names = FALSE, recursive = TRUE, 
                         pattern = "[^orig.md5]")
checkFiles
```

    ## [1] "PlantGrowth.csv"         "subf1/ChickWeight.csv"  
    ## [3] "subf1/ChickWeight.Rdata" "subf1/subf2/TREES.csv"  
    ## [5] "subf1/subf2/trees.Rdata" "subf1/subf2/volcano.csv"

``` r
MD5.check <- data.table(fileName = checkFiles)
MD5.check[, md5Check := lapply(fileName, md5sum)]
MD5.check
```

    ##                   fileName                         md5Check
    ## 1:         PlantGrowth.csv e6064331c76ef3defb9eff852f877da4
    ## 2:   subf1/ChickWeight.csv dc5251152bf9dc84d85694c3c7a8c8fb
    ## 3: subf1/ChickWeight.Rdata 4a04111b96586fe4f55a3ab113301c2d
    ## 4:   subf1/subf2/TREES.csv eda0aee4b42aa6853f11051174de41af
    ## 5: subf1/subf2/trees.Rdata dae508a52417a808b2d0e8ff1d6f2da8
    ## 6: subf1/subf2/volcano.csv 7f75c2935f5b95e138ab62bf28bc7e32

### Step 5: Read in source MD5 check sums text file

Reading in the MD5 hashes for the source files from `orig.md5` that we
created above.

``` r
origFileMD5 <- fread(md5Filename, header = FALSE, col.names = c("md5Orig", "fileName"))
origFileMD5
```

    ##                             md5Orig                fileName
    ## 1: e6064331c76ef3defb9eff852f877da4         PlantGrowth.csv
    ## 2: cc7feea5a98cabc13f282007155a0f69   subf1/ChickWeight.csv
    ## 3: 4a04111b96586fe4f55a3ab113301c2d subf1/ChickWeight.Rdata
    ## 4: eda0aee4b42aa6853f11051174de41af   subf1/subf2/trees.csv
    ## 5: dae508a52417a808b2d0e8ff1d6f2da8 subf1/subf2/trees.Rdata
    ## 6: 7f75c2935f5b95e138ab62bf28bc7e32 subf1/subf2/volcano.csv

### Step 6: Check the MD5 hashes

Verify the hashes from the `orig.md5` with the hashes from the “check”
MD5 sums.

``` r
MD5verify <- merge(origFileMD5, MD5.check, by = "fileName", all = TRUE)
MD5verify[, Result := fifelse(md5Orig == md5Check, "OK", "Error")]

# Print out the results
MD5verify
```

    ##                   fileName                          md5Orig                         md5Check Result
    ## 1:         PlantGrowth.csv e6064331c76ef3defb9eff852f877da4 e6064331c76ef3defb9eff852f877da4     OK
    ## 2: subf1/ChickWeight.Rdata 4a04111b96586fe4f55a3ab113301c2d 4a04111b96586fe4f55a3ab113301c2d     OK
    ## 3:   subf1/ChickWeight.csv cc7feea5a98cabc13f282007155a0f69 dc5251152bf9dc84d85694c3c7a8c8fb  Error
    ## 4:   subf1/subf2/TREES.csv                             <NA> eda0aee4b42aa6853f11051174de41af   <NA>
    ## 5: subf1/subf2/trees.Rdata dae508a52417a808b2d0e8ff1d6f2da8 dae508a52417a808b2d0e8ff1d6f2da8     OK
    ## 6:   subf1/subf2/trees.csv eda0aee4b42aa6853f11051174de41af                                   Error
    ## 7: subf1/subf2/volcano.csv 7f75c2935f5b95e138ab62bf28bc7e32 7f75c2935f5b95e138ab62bf28bc7e32     OK

- `OK`: Source and received files match.
- `Error`: Corrupted file or file not found.
- `NA`: File received but it is not in the source files.

------------------------------------------------------------------------

The R code for this README file is available at:
[Demo_for_tools_md5sum.R](https://github.com/saghirb/md5sum_R_Demo/Demo_for_tools_md5sum.R)
