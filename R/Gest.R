#
#	Gest.S
#
#	Compute estimates of nearest neighbour distance distribution function G
#
#	$Revision: 4.30 $	$Date: 2014/10/24 00:22:30 $
#
################################################################################
#
"Gest" <-
"nearest.neighbour" <-
function(X, r=NULL, breaks=NULL, ..., correction=c("rs", "km", "han"),
         domain=NULL) {
  verifyclass(X, "ppp")
  if(!is.null(domain))
      stopifnot(is.subset.owin(domain, Window(X)))
  
  ##
  W <- X$window
  npts <- npoints(X)
  lambda <- npts/area(W)
  
  ## determine r values 
  rmaxdefault <- rmax.rule("G", W, lambda)
  breaks <- handle.r.b.args(r, breaks, W, rmaxdefault=rmaxdefault)
  rvals <- breaks$r
  rmax  <- breaks$max
  zeroes <- numeric(length(rvals))

  ## choose correction(s)
#  correction.given <- !missing(correction) && !is.null(correction)
  if(is.null(correction)) {
    correction <- c("rs", "km", "han")
  } else correction <- pickoption("correction", correction,
                           c(none="none",
                             border="rs",
                             rs="rs",
                             KM="km",
                             km="km",
                             Kaplan="km",
                             han="han",
                             Hanisch="han",
                             cs="han",
                             ChiuStoyan="han",
                             best="km"),
                           multi=TRUE)

  ##  compute nearest neighbour distances
  nnd <- nndist(X$x, X$y)
  ##  distance to boundary
  bdry <- bdist.points(X)
  ## restrict to subset ?
  if(!is.null(domain)) {
    ok <- inside.owin(X, w=domain)
    nnd <- nnd[ok]
    bdry <- bdry[ok]
  }
  ##  observations
  o <- pmin.int(nnd,bdry)
  ##  censoring indicators
  d <- (nnd <= bdry)

  ## initialise fv object
  df <- data.frame(r=rvals, theo=1-exp(-lambda * pi * rvals^2))
  Z <- fv(df, "r", substitute(G(r), NULL), "theo", . ~ r,
          c(0,rmax),
          c("r", "%s[pois](r)"), 
          c("distance argument r", "theoretical Poisson %s"),
          fname="G")

  if("none" %in% correction) {
    ##  UNCORRECTED e.d.f. of nearest neighbour distances: use with care
    if(npts <= 1)
      edf <- zeroes
    else {
      hh <- hist(nnd[nnd <= rmax],breaks=breaks$val,plot=FALSE)$counts
      edf <- cumsum(hh)/length(nnd)
    }
    Z <- bind.fv(Z, data.frame(raw=edf), "hat(%s)[raw](r)",
                 "uncorrected estimate of %s", "raw")
  }
  if("han" %in% correction) {
    if(npts <= 1)
      G <- zeroes
    else {
      ##  uncensored distances
      x <- nnd[d]
      ##  weights
      a <- eroded.areas(W, rvals, subset=domain)
      ## calculate Hanisch estimator
      h <- hist(x[x <= rmax], breaks=breaks$val, plot=FALSE)$counts
      G <- cumsum(h/a)
      G <- G/max(G[is.finite(G)])
    }
    ## add to fv object
    Z <- bind.fv(Z, data.frame(han=G),
                 "hat(%s)[han](r)", 
                 "Hanisch estimate of %s",
                 "han")
    ## modify recommended plot range
    attr(Z, "alim") <- range(rvals[G <= 0.9])
  }

  if(any(correction %in% c("rs", "km"))) {
    ## calculate Kaplan-Meier and border correction (Reduced Sample) estimators
    if(npts == 0)
      result <- data.frame(rs=zeroes, km=zeroes, hazard=zeroes, theohaz=zeroes)
    else {
      result <- km.rs(o, bdry, d, breaks)
      result$theohaz <- 2 * pi * lambda * rvals
      result <- as.data.frame(result[c("rs", "km", "hazard", "theohaz")])
    }
    ## add to fv object
    Z <- bind.fv(Z, result,
                 c("hat(%s)[bord](r)", "hat(%s)[km](r)",
                   "hat(h)[km](r)", "h[pois](r)"),
                 c("border corrected estimate of %s",
                   "Kaplan-Meier estimate of %s",
                   "Kaplan-Meier estimate of hazard function h(r)",
                   "theoretical Poisson hazard function h(r)"),
                 "km")
    
    ## modify recommended plot range
    attr(Z, "alim") <- range(rvals[result$km <= 0.9])
  }
  nama <- names(Z)
  fvnames(Z, ".") <- rev(setdiff(nama, c("r", "hazard", "theohaz")))
  unitname(Z) <- unitname(X)
  return(Z)
}	

