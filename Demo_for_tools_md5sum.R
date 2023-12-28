## ----setup----------------------------------------------------------------------------------------------------------
library(tools) 
library(data.table)


## ----writeFiles-----------------------------------------------------------------------------------------------------
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


## ----listFiles------------------------------------------------------------------------------------------------------
listTmpFiles <- list.files(tmpDir, full.names = FALSE, recursive = TRUE)
listTmpFiles


## ----md5sumDataset, R.options = list(width = 120)-------------------------------------------------------------------
wdOrig <- getwd()
setwd(tmpDir)
MD5.orig <- data.table(fileName = listTmpFiles)[
  , md5Orig := lapply(fileName, md5sum)][
  , md5OrigText := paste0(md5Orig, " ", fileName)][
    , .(md5OrigText)]
MD5.orig


## ----writeMd5File---------------------------------------------------------------------------------------------------
md5Filename <- paste0(tmpDir, "/", "orig.md5")
writeLines(text = MD5.orig$md5OrigText, con = md5Filename)


## ----change Files---------------------------------------------------------------------------------------------------
# Change one file name to get an error when we check the MD5 hashes below.
file.rename(from = paste(tmpDir, "subf1", "subf2", "trees.csv", sep = "/"),
            to = paste(tmpDir, "subf1", "subf2", "TREES.csv", sep = "/"))

# Change the content of another file to get an error when we check the MD5 hashes below.
file.append(paste(tmpDir, "subf1", "ChickWeight.csv", sep = "/"), 
            paste(tmpDir, "PlantGrowth.csv", sep = "/"))
setwd(wdOrig)


## ----listCorruptedFiles---------------------------------------------------------------------------------------------
listTmpCorruptedFiles <- list.files(tmpDir, full.names = FALSE, recursive = TRUE)
listTmpCorruptedFiles


## ----md5sumCheck----------------------------------------------------------------------------------------------------
setwd(tmpDir)
# Check all files except the orig.md5 file. 
checkFiles <- list.files(tmpDir, full.names = FALSE, recursive = TRUE, 
                         pattern = "[^orig.md5]")
checkFiles

MD5.check <- data.table(fileName = checkFiles)
MD5.check[, md5Check := lapply(fileName, md5sum)]
MD5.check


## ----md5sumOrig-----------------------------------------------------------------------------------------------------
origFileMD5 <- fread(md5Filename, header = FALSE, col.names = c("md5Orig", "fileName"))
origFileMD5


## ----md5sumVerify, R.options = list(width = 100)--------------------------------------------------------------------
MD5verify <- merge(origFileMD5, MD5.check, by = "fileName", all = TRUE)
MD5verify[, Result := fifelse(md5Orig == md5Check, "OK", "Error")]

# Print out the results
MD5verify

