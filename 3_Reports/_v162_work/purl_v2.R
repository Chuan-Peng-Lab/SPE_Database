# purl the v2 Rmd sources into executable R scripts next to each Rmd
setwd("D:/GitHub_programe/GitHub/SPE_Database/3_Reports")
files <- c("1_Identity_Analysis/Figure3_Ridges_Pairwise_v2.Rmd",
           "2_Mismatch_Analysis/Figure_Bootstrap_Mismatch_v2.Rmd",
           "3_Exploratory_Analysis/Figure_Exploratory_Moderators_v2.Rmd")
for (f in files) {
  out <- sub("\\.Rmd$", ".R", f)
  knitr::purl(f, output = out, quiet = TRUE)
  cat("purl ->", out, file.exists(out), "\n")
}
cat("done\n")
