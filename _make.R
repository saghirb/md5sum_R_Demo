# Demo for tools::md5sum()

# Render the GitHub and remove the html file
rmarkdown::render("README.Rmd", output_dir = ".", clean = TRUE)
if (file.exists("README.html")){
  file.remove("README.html")
}

# Extract R code from README.Rmd
knitr::purl(input = "README.Rmd",
            output = "Demo_for_tools_md5sum.R",
            documentation = 1L)
