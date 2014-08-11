#
#  density.ppp.R
#
#  Method for 'density' for point patterns
#
#  $Revision: 1.59 $    $Date: 2013/07/26 09:14:46 $
#

ksmooth.ppp <- function(x, sigma, ..., edge=TRUE) {
  .Deprecated("density.ppp", package="spatstat")
  density.ppp(x, sigma, ..., edge=edge)
}

density.ppp <- local({
  
density.ppp <- function(x, sigma=NULL, ...,
                        weights=NULL, edge=TRUE, varcov=NULL,
                        at="pixels", leaveoneout=TRUE,
                        adjust=1, diggle=FALSE) {
  verifyclass(x, "ppp")

  output <- pickoption("output location type", at,
                       c(pixels="pixels",
                         points="points"))
  
  ker <- resolve.2D.kernel(..., sigma=sigma, varcov=varcov, x=x, adjust=adjust)
  sigma <- ker$sigma
  varcov <- ker$varcov

  if(output == "points") {
    # VALUES AT DATA POINTS ONLY
    result <- densitypointsEngine(x, sigma, varcov=varcov,
                                  weights=weights, edge=edge,
                                  leaveoneout=leaveoneout,
                                  diggle=diggle, ...)
    if(!is.null(uhoh <- attr(result, "warnings"))) {
      switch(uhoh,
             underflow=warning("underflow due to very small bandwidth"),
             warning(uhoh))
    }
    return(result)
  }
  
  # VALUES AT PIXELS
  if(!edge) {
    # no edge correction
    edg <- NULL
    raw <- second.moment.calc(x, sigma, what="smooth", ...,
                              weights=weights, varcov=varcov)
    raw <- divide.by.pixelarea(raw) 
    smo <- raw
  } else if(!diggle) {
    # edge correction e(u)
    both <- second.moment.calc(x, sigma, what="smoothedge", ...,
                              weights=weights, varcov=varcov)
    raw <- divide.by.pixelarea(both$smooth)
    edg <- both$edge
    smo <- if(is.im(raw)) eval.im(raw/edg) else
           lapply(raw, function(a,b) eval.im(a/b), b=edg)
  } else {
    # edge correction e(x_i)
    edg <- second.moment.calc(x, sigma, what="edge", ..., varcov=varcov)
    wi <- 1/safelookup(edg, x, warn=FALSE)
    wi[!is.finite(wi)] <- 0
    # edge correction becomes weight attached to points
    if(is.null(weights)) {
      newweights <- wi
    } else if(is.matrix(weights) || is.data.frame(weights)) {
      stopifnot(nrow(weights) == npoints(x))
      newweights <- weights * wi
    } else {
      stopifnot(length(weights) == npoints(x))
      newweights <- weights * wi
    }
    raw <- second.moment.calc(x, sigma, what="smooth", ...,
                              weights=newweights, varcov=varcov)
    raw <- divide.by.pixelarea(raw)
    smo <- raw
  }

  result <- if(is.im(smo)) smo[x$window, drop=FALSE]
            else as.listof(lapply(smo, "[", i=x$window, drop=FALSE))

  # internal use only
  spill <- list(...)$spill
  if(!is.null(spill)) 
    return(list(sigma=sigma, varcov=varcov, raw = raw, edg=edg))

  # normal return
  attr(result, "sigma") <- sigma
  attr(result, "varcov") <- varcov
  return(result)
}

divide.by.pixelarea <- function(x) {
  if(is.im(x)) {
    x$v <- x$v/(x$xstep * x$ystep)
  } else {
    for(i in seq_along(x))
      x[[i]]$v <- with(x[[i]], v/(xstep * ystep))
  }
  return(x)
}

density.ppp

})

densitypointsEngine <- function(x, sigma, ...,
                                weights=NULL, edge=TRUE, varcov=NULL,
                                leaveoneout=TRUE, diggle=FALSE,
                                sorted=FALSE) {
  if(is.null(varcov)) {
    const <- 1/(2 * pi * sigma^2)
  } else {
    detSigma <- det(varcov)
    Sinv <- solve(varcov)
    const <- 1/(2 * pi * sqrt(detSigma))
  }
  # Leave-one-out computation
  # cutoff: contributions from pairs of distinct points
  # closer than 8 standard deviations
  sd <- if(is.null(varcov)) sigma else sqrt(sum(diag(varcov)))
  cutoff <- 8 * sd
#  nnd <- nndist(x)
#  nnrange <- range(nnd)
#  if(nnrange[1] > cutoff) {
#    npts <- npoints(x)
#    result <- if(leaveoneout) numeric(npts) else rep.int(const, npts)
#    attr(result, "sigma") <- sigma
#    attr(result, "varcov") <- varcov
#    attr(result, "warnings") <- "underflow"
#    return(result)
#  }
  if(leaveoneout) {
    # ensure each point has its closest neighbours within the cutoff
    nndmax <- max(nndist(x))
    cutoff <- max(2 * nndmax, cutoff)
  }
  # validate weights
  if(is.null(weights)) {
    k <- 1
  } else if(is.matrix(weights) || is.data.frame(weights)) {
    k <- ncol(weights)
    stopifnot(nrow(weights) == npoints(x))
    weights <- as.data.frame(weights)
    weightnames <- colnames(weights)
  } else {
    k <- 1
    stopifnot(length(weights) == npoints(x) || length(weights) == 1)
  }
  # evaluate edge correction weights at points 
  if(edge) {
    win <- x$window
    if(is.null(varcov) && win$type == "rectangle") {
      # evaluate Gaussian probabilities directly
      xr <- win$xrange
      yr <- win$yrange
      xx <- x$x
      yy <- x$y
      xprob <-
        pnorm(xr[2], mean=xx, sd=sigma) - pnorm(xr[1], mean=xx, sd=sigma)
      yprob <-
        pnorm(yr[2], mean=yy, sd=sigma) - pnorm(yr[1], mean=yy, sd=sigma)
      edgeweight <- xprob * yprob
    } else {
      edg <- second.moment.calc(x, sigma=sigma, what="edge", varcov=varcov)
      edgeweight <- safelookup(edg, x, warn=FALSE)
    }
    if(diggle) {
      # Diggle edge correction
      # edgeweight is attached to each point
      if(is.null(weights)) {
        k <- 1
        weights <- 1/edgeweight
      } else {
        weights <- weights/edgeweight
      }
    }
  }
  
  if(spatstat.options("densityC") || k > 1) {
    # .................. new C code ...........................
    npts <- npoints(x)
    result <- if(k == 1) numeric(npts) else matrix(, npts, k)
    # sort into increasing order of x coordinate (required by C code)
    if(sorted) {
      xx <- x$x
      yy <- x$y
    } else {
      oo <- fave.order(x$x)
      xx <- x$x[oo]
      yy <- x$y[oo]
    } 
    if(is.null(varcov)) {
      # isotropic kernel
      if(is.null(weights)) {
        zz <- .C("denspt",
                 nxy     = as.integer(npts),
                 x       = as.double(xx),
                 y       = as.double(yy),
                 rmaxi   = as.double(cutoff),
                 sig     = as.double(sd),
                 result   = as.double(double(npts)),
                 PACKAGE = "spatstat")
        if(sorted) result <- zz$result else result[oo] <- zz$result 
      } else if(k == 1) {
        wtsort <- if(sorted) weights else weights[oo]
        zz <- .C("wtdenspt",
                 nxy     = as.integer(npts),
                 x       = as.double(xx),
                 y       = as.double(yy),
                 rmaxi   = as.double(cutoff),
                 sig     = as.double(sd),
                 weight  = as.double(wtsort),
                 result   = as.double(double(npts)),
                 PACKAGE = "spatstat")
        if(sorted) result <- zz$result else result[oo] <- zz$result 
       } else {
        # matrix of weights
        wtsort <- if(sorted) weights else weights[oo, ]
        for(j in 1:k) {
          zz <- .C("wtdenspt",
                   nxy     = as.integer(npts),
                   x       = as.double(xx),
                   y       = as.double(yy),
                   rmaxi   = as.double(cutoff),
                   sig     = as.double(sd),
                   weight  = as.double(wtsort[,j]),
                   result   = as.double(double(npts)),
                   PACKAGE = "spatstat")
          if(sorted) result[,j] <- zz$result else result[oo,j] <- zz$result
        }
      }
    } else {
      # anisotropic kernel
      flatSinv <- as.vector(t(Sinv))
      if(is.null(weights)) {
        zz <- .C("adenspt",
                 nxy     = as.integer(npts),
                 x       = as.double(xx),
                 y       = as.double(yy),
                 rmaxi   = as.double(cutoff),
                 detsigma = as.double(detSigma),
                 sinv    = as.double(flatSinv),
                 result   = as.double(double(npts)),
                 PACKAGE = "spatstat")
        if(sorted) result <- zz$result else result[oo] <- zz$result 
      } else if(k == 1) {
        # vector of weights
        wtsort <- if(sorted) weights else weights[oo]
        zz <- .C("awtdenspt",
                 nxy     = as.integer(npts),
                 x       = as.double(xx),
                 y       = as.double(yy),
                 rmaxi   = as.double(cutoff),
                 detsigma = as.double(detSigma),
                 sinv    = as.double(flatSinv),
                 weight  = as.double(wtsort),
                 result   = as.double(double(npts)),
                 PACKAGE = "spatstat")
        if(sorted) result <- zz$result else result[oo] <- zz$result 
      } else {
        # matrix of weights
        wtsort <- if(sorted) weights else weights[oo, ]
        for(j in 1:k) {
          zz <- .C("awtdenspt",
                   nxy     = as.integer(npts),
                   x       = as.double(xx),
                   y       = as.double(yy),
                   rmaxi   = as.double(cutoff),
                   detsigma = as.double(detSigma),
                   sinv    = as.double(flatSinv),
                   weight  = as.double(wtsort[,j]),
                   result   = as.double(double(npts)),
                   PACKAGE = "spatstat")
          if(sorted) result[,j] <- zz$result else result[oo,j] <- zz$result 
        }
      }
    }
  } else {
      # ..... interpreted code .........................................
    close <- closepairs(x, cutoff)
    i <- close$i
    j <- close$j
    d <- close$d
    # evaluate contribution from each close pair (i,j)
    if(is.null(varcov)) {
      contrib <- const * exp(-d^2/(2 * sigma^2))
    } else {
      # anisotropic kernel
      dx <- close$dx
      dy <- close$dy
      contrib <- const * exp(-(dx * (dx * Sinv[1,1] + dy * Sinv[1,2])
                               + dy * (dx * Sinv[2,1] + dy * Sinv[2,2]))/2)
    }
    # multiply by weights
    if(!is.null(weights))
      contrib <- contrib * weights[j]
    # sum
    result <- tapply(contrib, factor(i, levels=1:(x$n)), sum)
    result[is.na(result)] <- 0
    #
  }
  # ----- contribution from point itself ----------------
  if(!leaveoneout) {
    # add contribution from point itself
    self <- const
    if(!is.null(weights))
      self <- self * weights
    result <- result + self
  }
  # ........  Edge correction ........................................
  if(edge && !diggle) 
    result <- result/edgeweight

  # ............. validate .................................
  npts <- npoints(x)
  if(k == 1) {
    result <- as.numeric(result)
    if(length(result) != npts) 
      stop(paste("Internal error: incorrect number of lambda values",
                 "in leave-one-out method:",
                 "length(lambda) = ", length(result),
                 "!=", npts, "= npoints"))
    if(any(is.na(result))) {
      nwrong <- sum(is.na(result))
      stop(paste("Internal error:", nwrong, "NA or NaN",
                 ngettext(nwrong, "value", "values"),
                 "generated in leave-one-out method"))
    }
  } else {
    if(ncol(result) != k)
      stop(paste("Internal error: incorrect number of columns returned:",
                 ncol(result), "!=", k))
    colnames(result) <- weightnames
    if(nrow(result) != npts) 
      stop(paste("Internal error: incorrect number of rows of lambda values",
                 "in leave-one-out method:",
                 "nrow(lambda) = ", nrow(result),
                 "!=", npts, "= npoints"))
    if(any(is.na(result))) {
      nwrong <- sum(!complete.cases(result))
      stop(paste("Internal error:", nwrong,
                 ngettext(nwrong, "row", "rows"),
                 "of NA values generated in leave-one-out method"))
    }
  }
  # tack on bandwidth
  attr(result, "sigma") <- sigma
  attr(result, "varcov") <- varcov
  # 
  return(result)
}

resolve.2D.kernel <- function(..., sigma=NULL, varcov=NULL, x, mindist=NULL,
                              adjust=1, bwfun=NULL, allow.zero=FALSE) {
  if(is.function(sigma)) {
    bwfun <- sigma
    sigma <- NULL
  }
  if(is.null(sigma) && is.null(varcov) && !is.null(bwfun)) {
    # call bandwidth selection function
    bw <- do.call.matched(bwfun, resolve.defaults(list(X=x), list(...)))
    # interpret the result as either sigma or varcov
    if(!is.numeric(bw))
      stop("bandwidth selector returned a non-numeric result")
    if(length(bw) %in% c(1,2)) {
      sigma <- as.numeric(bw)
      if(!all(sigma > 0)) {
        gripe <- "bandwidth selector returned negative value(s)"
        if(allow.zero) warning(gripe) else stop(gripe)
      }
    } else if(is.matrix(bw) && nrow(bw) == 2 && ncol(bw) == 2) {
      varcov <- bw
      if(!all(eigen(varcov)$values > 0))
        stop("bandwidth selector returned matrix with negative eigenvalues")
    } else stop("bandwidth selector did not return a matrix or numeric value")
  }
  sigma.given <- !is.null(sigma)
  varcov.given <- !is.null(varcov)
  if(sigma.given) {
    stopifnot(is.numeric(sigma))
    stopifnot(length(sigma) %in% c(1,2))
    if(!allow.zero)
      stopifnot(all(sigma > 0))
  }
  if(varcov.given)
    stopifnot(is.matrix(varcov) && nrow(varcov) == 2 && ncol(varcov)==2 )
  # reconcile
  ngiven <- varcov.given + sigma.given
  switch(ngiven+1,
         {
           # default
           w <- x$window
           sigma <- (1/8) * shortside(as.rectangle(w))
         },
         {
           if(sigma.given && length(sigma) == 2) 
             varcov <- diag(sigma^2)
           if(!is.null(varcov))
             sigma <- NULL
         },
         {
           stop(paste("Give only one of the arguments",
                      sQuote("sigma"), "and", sQuote("varcov")))
         })
  # apply adjustments
  if(!is.null(sigma))  sigma <- adjust * sigma
  if(!is.null(varcov)) varcov <- (adjust^2) * varcov
  #
  sd <- if(is.null(varcov)) sigma else sqrt(sum(diag(varcov)))
  cutoff <- 8 * sd
  uhoh <- if(!is.null(mindist) && cutoff < mindist) "underflow" else NULL
  result <- list(sigma=sigma, varcov=varcov, cutoff=cutoff, warnings=uhoh)
  return(result)
}

bw.diggle <- function(X) {
  stopifnot(is.ppp(X))
  lambda <- npoints(X)/area.owin(as.owin(X))
  K <- Kest(X, correction="best")
  yname <- fvnames(K, ".y")
  K <- K[, c("r", yname)]
  rvals <- K$r
  # evaluation of M(r) requires K(2r)
  rmax2 <- max(rvals)/2
  if(!is.null(alim <- attr(K, "alim"))) rmax2 <- min(alim[2], rmax2)
  ok <- (rvals <= rmax2)
  rvals <- rvals[ok]
  #
  nr <- length(rvals)
  J <- numeric(nr)
  phi <- function(x,h) { 
    if(h <= 0) return(numeric(length(x)))
    y <- pmax.int(0, pmin.int(1, x/(2 * h)))
    4 * pi * h^2 * (acos(y) - y * sqrt(1 - y^2))
  }
  for(i in 1:nr) 
    J[i] <- stieltjes(phi, K, h=rvals[i])[[yname]]/(2 * pi)
  pir2 <- pi * rvals^2
  M <- (1/lambda - 2 * K[[yname]][ok])/pir2 + J/pir2^2
  # This calculation was for the uniform kernel on B(0,h)
  # Convert to standard deviation of (one-dimensional marginal) kernel
  sigma <- rvals/2
  result <- bw.optim(M, sigma,
                     creator="bw.diggle",
                     criterion="Berman-Diggle Cross-Validation",
                     J=J,
                     lambda=lambda)
  return(result)
}

bw.scott <- function(X) {
  stopifnot(is.ppp(X))
  n <- npoints(X)
  sdx <- sqrt(var(X$x))
  sdy <- sqrt(var(X$y))
  return(c(sdx, sdy) * n^(-1/6))
}

