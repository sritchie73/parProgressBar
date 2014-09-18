#' Iterator with master worker
#' 
#' Create an iterator of chunks of indices from 1 to \code{n}, along with an 
#' initial element that designates the master worker. You can specify either the
#' number of pieces, using the \code{chunks} argument, or the maximum size of
#' the pieces, using the \code{chunkSize} argument.
#' 
#' @details
#'  If \code{verbose} is \code{FALSE}, the returned iterator is exactly the 
#'  same as if calling \code{\link[itertools]{isplitIndices}}. If \code{TRUE},
#'  then the iterator is prepended with a -1. This allows for a 
#'  \code{\link[foreach]{foreach}} loop to easily operate on chunks of tasks, 
#'  while also designating one worker thread as the master of reporting 
#'  progress (see \code{\link[=parProgress]{monitorProgress}}).
#' 
#' @seealso 
#'  \code{\link[itertools]{isplitIndices}} \code{\link[iterators]{idiv}}
#'  \code{\link[=parProgress]{monitorProgress}}
#' @param verbose logical. Controls the type of iterator returned, see details.
#' @param n Maximum index to generate.
#' @param cores the number of cores to divide \code{n} across. If \code{verbose}
#'  is \code{TRUE}, \code{n} is distributed over \code{cores - 1}, while 1 core
#'  is reserved as the task monitor.
#' @return
#'  An iterator that returns -1 (for the master worker), and vectors of indices 
#'  from 1 to \code{n} for the other worker threads.
#' @importFrom iterators idiv
#' @importFrom iterators nextElem
#' @importFrom itertools isplitIndices
ichunkTasks <- function(verbose, n, cores) {
  if (verbose & (cores > 1)) {
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