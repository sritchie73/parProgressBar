#' Iterator with master worker
#' 
#' Create an iterator of chunks of indices from 1 to \code{n}, along with an 
#' initial element that designates the master worker. You can specify either the
#' number of pieces, using the \code{chunks} argument, or the maximum size of
#' the pieces, using the \code{chunkSize} argument.
#' 
#' @details
#'  Creates an iterator is prepended with a -1 if there are more than 1 threads.
#'  This allows for a \code{\link[foreach]{foreach}} loop to easily operate on
#'  chunks of tasks, while also designating one worker thread as the master of
#'  reporting progress (see \code{\link[=parProgress]{monitorProgress}}).
#' 
#' @seealso 
#'  \code{\link[itertools]{isplitIndices}} \code{\link[iterators]{idiv}}
#'  \code{\link[=parProgress]{monitorProgress}}
#' @param n Maximum index to generate.
#' @return
#'  An iterator that returns -1 (for the master worker), and vectors of indices 
#'  from 1 to \code{n} for the other worker threads.
#' @importFrom iterators idiv
#' @importFrom iterators nextElem
#' @importFrom itertools isplitIndices
#' @importFrom foreach getDoParWorkers
ichunkTasks <- function(n) {
  cores <- getDoParWorkers()
  if (cores > 1) {
    it <- idiv(n, chunks=cores-1)
    i <- 1L
    first = TRUE
    nextEl <- function() {
      if (first) {
        first <<- FALSE
        -1L
      } else {
        m <- as.integer(nextElem(it))
        j <- i
        i <<- i + m
        seq(j, length=m)
      }
    }
    object <- list(nextElem = nextEl)
    class(object) <- c("abstractiter", "iter")
    object
  } else {
    isplitIndices(n, chunks=cores)
  }
}