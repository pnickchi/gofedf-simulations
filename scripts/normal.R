#
# This script runs the Monte Carlo simulation study for the IID normal
# goodness-of-fit test implemented in `gofedf::testNormal()`. For each sample
# size, data are generated from a standard normal distribution with mean 0 and
# standard deviation 1. The test is applied using the Cramér-von Mises and
# Anderson-Darling methods, with both discretized and non-discretized covariance
# approximations. The resulting p-values are saved and later used to assess
# whether the empirical type-I error rate is close to the nominal level.
#

library(gofedf)
library(parallel)

# Set the possible sample sizes
n <- c(25, 50, 100, 250)

# Number of Monte Carlo repetitions
MC <- 100000

# Number of workers for parallel computation
n_workers <- max(1, detectCores() - 1)

cat("Using", n_workers, "parallel workers.\n")

#
# Helper function to run a Monte Carlo simulation for the IID Normal(0, 1)
# setting. For each repetition, generate a sample of size `sample_size`, apply
# gofedf::testNormal() using both the CvM and AD test statistics, and store the
# resulting p-values. The seed is set using the repetition index so that each
# simulated dataset can be reproduced.
#
run_normal_iid_simulation <- function(sample_size, discretize = FALSE, MC = 10000, n_workers) {
  
  sample_size <- as.integer(sample_size)
  discretize  <- as.logical(discretize)
  MC          <- as.integer(MC)
  n_workers   <- as.integer(n_workers)
  
  cl <- makeCluster(n_workers)
  on.exit(stopCluster(cl), add = TRUE)

  pval <- parLapply(cl, 1:MC, function(i) {
    
    # Set the seed for reproducibility
    set.seed(i)
    
    # Generate sample from Normal(0, 1)
    x <- rnorm(n = sample_size, mean = 0, sd = 1)
    
    # Run CvM test
    tmp_cvm <- gofedf::testNormal(
      x = x,
      method = "cvm",
      discretize = discretize
    )
    
    # Run AD test
    tmp_ad <- gofedf::testNormal(
      x = x,
      method = "ad",
      discretize = discretize
    )
    
    # Store p-values
    c(
      cvm = tmp_cvm$pvalue,
      ad = tmp_ad$pvalue
    )
  })
  
  return(pval)
}


dir.create("results/normal", recursive = TRUE, showWarnings = FALSE)

for(j in n){
  for(disc in c(FALSE, TRUE)){
    
    cat("Simulation for Normal: n =", j, ", discretize =", disc, "\n")
    
    pvalue <- run_normal_iid_simulation(
      sample_size = j,
      discretize = disc,
      MC = MC,
      n_workers = n_workers
    )
    
    saveRDS(
      object = pvalue,
      file = paste0(
        "results/normal/normal_iid_n", j,
        "_discretize_", disc,
        "_pvalues.rds"
      )
    )
  }
}