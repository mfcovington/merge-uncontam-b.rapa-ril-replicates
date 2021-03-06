
# setwd("/Users/mfc/git.repos/vcf-generator/genotyped_contam_scoring")
setwd("/Volumes/Runner_3A/mike/RMDUP.NR_1/genotyped/")
geno.files <- list.files(pattern = "^RIL_")

contam.summary <- data.frame(file.name = character(),
                             het.ratio = numeric(),
                             stringsAsFactors = FALSE)
for (file in geno.files) {
  if (file.info(file)$size == 0) next
  geno <- read.table(file, sep = "\t")
  names(geno) <- c("chr", "pos", "par1", "par2", "tot")
  geno$par1.ratio <- geno$par1 / (geno$par1 + geno$par2)
  threshold <- 0.3
  het.ratio <- sum(geno$par1.ratio < (1 - threshold)
                 & geno$par1.ratio > threshold, na.rm = TRUE) /
                 length(na.omit(geno$par1.ratio))
  contam.summary[nrow(contam.summary) + 1, ] <- c(file, het.ratio)
}

contam.summary$het.ratio <- as.numeric(contam.summary$het.ratio)
contam.summary$id <- sub("^([^.]+\\.[^.]+).+", "\\1", contam.summary$file.name)
# library(ggplot2)
# het.boxplot <- qplot(id, het.ratio, data = contam.summary, geom = 'boxplot')
# ggsave("het.boxplot.png", het.boxplot)

library(plyr)
mean234 <- function (x) mean(arrange(x, desc(x$het.ratio))$het.ratio[2:4])
contam.summary.mean234 <- ddply(contam.summary, .(id), mean234)
names(contam.summary.mean234)[2] <- 'mean234'
mean234.cutoff <- 0.035
rils.uncontam <- contam.summary.mean234$id[contam.summary.mean234$mean234 < mean234.cutoff]
date <- format(Sys.time(), "%Y%m%d")
write.table(rils.uncontam, paste("../reps.uncontam", date, sep = "."),
            quote = F, sep = "\t", row.names = F, col.names = F)
