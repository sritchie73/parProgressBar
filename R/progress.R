#' Monitor Parallel Process Progress
#' 
#' Update progress of a parallel \code{\link[foreach]{foreach}} process to
#' files.
#' 
#' @details
#'   When running code in parallel using \code{foreach}, new R
#'   instances will be spawned, one for each core as setup by the parallel
#'   backend. As a result no output will be sent back to the main R process
#'   until the \code{foreach} loop has finished running.
#' @param indent an integer corresponding to the level of indentation. Each
#'   indentation level corresponds to two spaces.
#' @seealso \code{\link[utils]{txtProgressBar}}
#' @name parProgress
NULL

#' @param chunk The chunk of indices for the current parallel instance of the 
#'   \code{foreach} loop.
#' @return
#'   \code{setupParProgressLogs}: a list with an object of class 
#'   "\code{txtProgressBar}", along with the connection to the logfile (this is
#'   returned so it can be closed properly later.)
#' @rdname parProgress
#' @importFrom utils txtProgressBar
#' @export
setupParProgressLogs <- function(chunk, indent) {
  nChunks <- numWorkers()
  chunkNum <- ceiling(chunk[1]/length(chunk))
  
  # To log progress, we will write our progress to a file for each chunk
  if(!file.exists("run-progress")) {
    dir.create("run-progress")
  }
  
  # Setup log file
  filename <- file.path("run-progress", paste0("chunk", chunkNum, ".log"))
  file.create(filename)
  logfile <- file(filename, open="wt")
  
  # Define progress bar boundaries
  min <- chunk[1] - 1
  max <- chunk[length(chunk)]
  
  # Set width of the bar based on the predicted level of indentation etc.
  width <- options("width")[[1]]
  barWidth <- 9 # for some reason txtProgressBar is 9 characters too wide.
  if (nChunks > 1) {
    # Multiple worker cores, prepend with "Worker N:"
    progWidth = width - indent*2 - nchar("Worker ") - nchar(nChunks) - 1 - barWidth
  } else {
    # If only one worker core, no need to prepend with "Worker N:"
    progWidth = width - indent*2 - barWidth
  }
  pb <- txtProgressBar(min, max, min, width=progWidth, style=3, file=logfile)
  list(pb, logfile)
}

#' @param pb an object of class "\code{txtProgressBar}"
#' @param i new value for the progress bar.
#' @importFrom utils setTxtProgressBar
#' @rdname parProgress
#' @export
updateParProgress <- function(pb, i) {
  setTxtProgressBar(pb, i)
}

#' @description 
#'  \code{monitorProgress}: Monitor the progress of parallel workers.
#' @rdname parProgress
#' @import foreach
#' @export
monitorProgress <- function(indent) {
  f <- NULL # Definition to turn off R CMD check NOTE
  init <- FALSE
  
  nChunks <- numWorkers()

  while(TRUE) {
    files <- list.files("run-progress")
    if (init & length(files) == 0) {
      break;
    } else {
      init <- TRUE
    }
    # Sort numerically, for aesthetic purposes
    files <- files[order(as.integer(gsub("chunk|.log", "", files)))]
    
    # The use of foreach allows us to make use of on.exit for handling 
    # connection closure.
    foreach (f = files) %do% {
      # Get progress from file
      conn <- file(file.path("run-progress", f), open="rt")
      on.exit(close(conn)) # close regardless of function success
      progress <- tail(readLines(conn, warn=FALSE), 1)
      # This on.exit overwrites previous, so need to close(conn) again.
      # Remove the progress file when we complete, so that monitorProgress
      # doesn't run forever.
      on.exit({ 
        close(conn)
        if (grepl("100%", progress)) {
          file.remove(file.path("run-progress", f))
        } else {
          Sys.sleep(1)
        }
      })
      
      # Output sensibly
      num <- gsub("chunk|.log", "", f)
      spaces <- rep("  ", indent)
      if (nChunks > 1) {
        nSpaces <- nchar(nChunks) - nchar(num)
        cat(sep="", "\r", spaces, "Worker ", rep(" ", nSpaces), num, ":", 
            progress, file=stdout())       
      } else {
        cat(sep="", "\r", spaces, progress, file=stdout())
      }
      
    }
  }
  cat("\n")
  invisible() # Nothing to return
}

#' @description 
#'  \code{reportProgress}: Report the progress of a sequential loop.
#' @rdname parProgress
#' @export
reportProgress <- function(current, nTasks, indent) {
  # Get progress from file
  conn <- file(file.path("run-progress", file="chunk1.log"), open="rt")
  on.exit(close(conn))
  progress <- tail(readLines(conn, warn=FALSE), 1)
  on.exit({ 
    close(conn)
  })
  
  # Output sensibly
  cat(sep="", "\r", rep("  ", indent), progress, file=stdout())
  if (current == nTasks) {
    cat("\n")
  }
}

#' @description
#'  \code{closeProgressBars}: clean up temporary files.
#' @rdname parProgress
#' @export
closeProgressBars <- function() {
  log.files <- file.path("run-progress", list.files("run-progress"))
  unlink(log.files)
  unlink("run-progress", recursive=TRUE)
}