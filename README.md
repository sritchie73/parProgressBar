parProgressBar
==============

Utilities for creating a progress bar that renders in when running in parallel.

When running tasks in parallel, one may wish to obtain regular updates about the progress of each tasks. This package extends on the idea of `txtProgressBar`, providing a set of utilities for logging and viewing tasks that are running in parallel.

To use these utilities, 

When registering a parallel backend, 


### Example code:



The workflow is as follows:
 
  - 
  - Break your tasks into chunks, one chunk for each

```R
library(parProgressBar)

nTasks <- 10
# Break down tasks into chunks, i.e. number of registered threads.
foreach(chunk=ichunkTasks(nTasks), .combine=c) %dopar% {
  # Master worker: report progress of other workers. You can just register an
  # extra thread for this, since it requires very little CPU.
  if (length(chunk) == 1) {
    if (chunk == -1) {
      monitorProgress(indent=2)
      NULL
    }
  } else {
    # Setup connection to file to log progress to
    conns <- setupParProgressLogs(chunk, indent=2)
    progressBar <- conns[[1]]
    on.exit(lapply(conns, close))
    
    # Now operate on each task
    foreach(kk = seq_along(chunk)) %do% {
      # Update the progress at the end of the loop.
      on.exit({
        updateParProgress(progressBar, chunk[kk])
        if (getDoParWorkers() == 1) {
          reportProgress(chunk[kk], nTasks, indent=2)
        }
      })
      
      Sys.sleep(2)
      rnorm(1)
    }
  }
}
# Clean up:
closeProgressBars()
```

### Package Installation

To install this package, you will need Hadley Wickham's devtools package to install from github:

```R
library(devtools)
install_github("parProgressBar", "sritchie73")
```
