#
# colourtables.R
#
# support for colour maps and other lookup tables
#
# $Revision: 1.34 $ $Date: 2014/11/12 01:21:02 $
#

colourmap <- function(col, ..., range=NULL, breaks=NULL, inputs=NULL) {
  if(nargs() == 0) {
    ## null colour map
    f <- lut()
  } else {
    ## validate colour data 
    col2hex(col)
    ## store without conversion
    f <- lut(col, ..., range=range, breaks=breaks, inputs=inputs)
  }
  class(f) <- c("colourmap", class(f))
  f
}

lut <- function(outputs, ..., range=NULL, breaks=NULL, inputs=NULL) {
  if(nargs() == 0) {
    ## null lookup table
    f <- function(x, what="value"){NULL}
    class(f) <- c("lut", class(f))
    attr(f, "stuff") <- list(n=0)
    return(f)
  }
  n <- length(outputs)
  given <- c(!is.null(range), !is.null(breaks), !is.null(inputs))
  names(given) <- c("range", "breaks", "inputs")
  ngiven <- sum(given)
  if(ngiven == 0)
    stop(paste("One of the arguments",
               sQuote("range"), ",", sQuote("breaks"), "or", sQuote("inputs"),
               "should be given"))
  if(ngiven > 1) {
    offending <- names(breaks)[given]
    stop(paste("The arguments",
               commasep(sQuote(offending)),
               "are incompatible"))
  }
  if(!is.null(inputs)) {
    # discrete set of input values mapped to output values
    stopifnot(length(inputs) == length(outputs))
    stuff <- list(n=n, discrete=TRUE, inputs=inputs, outputs=outputs)
    f <- function(x, what="value") {
      m <- match(x, stuff$inputs)
      if(what == "index")
        return(m)
      cout <- stuff$outputs[m]
      return(cout)
    }
  } else if(!is.null(range) && inherits(range, c("Date", "POSIXt"))) {
    # date/time interval mapped to colours
    timeclass <- if(inherits(range, "Date")) "Date" else "POSIXt"
    if(is.null(breaks)) {
      breaks <- seq(from=range[1], to=range[2], length.out=length(outputs)+1)
    } else {
      if(!inherits(breaks, timeclass))
        stop(paste("breaks should belong to class", dQuote(timeclass)),
             call.=FALSE)
      stopifnot(length(breaks) >= 2)
      stopifnot(length(breaks) == length(outputs) + 1)
      if(!all(diff(breaks) > 0))
        stop("breaks must be increasing")
    }
    stuff <- list(n=n, discrete=FALSE, breaks=breaks, outputs=outputs)
    f <- function(x, what="value") {
      x <- as.vector(as.numeric(x))
      z <- findInterval(x, stuff$breaks,
                        rightmost.closed=TRUE)
      if(what == "index")
        return(z)
      cout <- stuff$outputs[z]
      return(cout)
    }
  } else {
    # interval of real line mapped to colours
    if(is.null(breaks)) {
      breaks <- seq(from=range[1], to=range[2], length.out=length(outputs)+1)
    } else {
      stopifnot(is.numeric(breaks) && length(breaks) >= 2)
      stopifnot(length(breaks) == length(outputs) + 1)
      if(!all(diff(breaks) > 0))
        stop("breaks must be increasing")
    }
    stuff <- list(n=n, discrete=FALSE, breaks=breaks, outputs=outputs)
    f <- function(x, what="value") {
      stopifnot(is.numeric(x))
      x <- as.vector(x)
      z <- findInterval(x, stuff$breaks,
                        rightmost.closed=TRUE)
      if(what == "index")
        return(z)
      cout <- stuff$outputs[z]
      return(cout)
    }
  }
  attr(f, "stuff") <- stuff
  class(f) <- c("lut", class(f))
  f
}

print.lut <- function(x, ...) {
  if(inherits(x, "colourmap")) {
    tablename <- "Colour map"
    outputname <- "colour"
  } else {
    tablename  <- "Lookup table"
    outputname <- "output"
  }
  stuff <- attr(x, "stuff")
  n <- stuff$n
  if(n == 0) {
    ## Null map
    cat(paste("Null", tablename, "\n"))
    return(invisible(NULL))
  }
  if(stuff$discrete) {
    cat(paste(tablename, "for discrete set of input values\n"))
    out <- data.frame(input=stuff$inputs, output=stuff$outputs)
  } else {
    b <- stuff$breaks
    cat(paste(tablename, "for the range", prange(b[c(1,n+1)]), "\n"))
    leftend  <- rep("[", n)
    rightend <- c(rep(")", n-1), "]")
    inames <- paste(leftend, b[-(n+1)], ", ", b[-1], rightend, sep="")
    out <- data.frame(interval=inames, output=stuff$outputs)
  }
  colnames(out)[2] <- outputname
  print(out)
  invisible(NULL)
}

print.colourmap <- function(x, ...) {
  NextMethod("print")
}

summary.lut <- function(object, ...) {
  s <- attr(object, "stuff")
  if(inherits(object, "colourmap")) {
    s$tablename <- "Colour map"
    s$outputname <- "colour"
  } else {
    s$tablename  <- "Lookup table"
    s$outputname <- "output"
  }
  class(s) <- "summary.lut"
  return(s)
}

print.summary.lut <- function(x, ...) {
  n <- x$n
  if(n == 0) {
    cat(paste("Null", x$tablename, "\n"))
    return(invisible(NULL))
  }
  if(x$discrete) {
    cat(paste(x$tablename, "for discrete set of input values\n"))
    out <- data.frame(input=x$inputs, output=x$outputs)
  } else {
    b <- x$breaks
    cat(paste(x$tablename, "for the range", prange(b[c(1,n+1)]), "\n"))
    leftend  <- rep("[", n)
    rightend <- c(rep(")", n-1), "]")
    inames <- paste(leftend, b[-(n+1)], ", ", b[-1], rightend, sep="")
    out <- data.frame(interval=inames, output=x$outputs)
  }
  colnames(out)[2] <- x$outputname
  print(out)  
}

plot.colourmap <- local({

  # recognised additional arguments to image.default() and axis()
  
  imageparams <- c("main", "asp", "sub", "axes", "ann",
                   "cex", "font", 
                   "cex.axis", "cex.lab", "cex.main", "cex.sub",
                   "col.axis", "col.lab", "col.main", "col.sub",
                   "font.axis", "font.lab", "font.main", "font.sub")
  axisparams <- c("cex", 
                  "cex.axis", "cex.lab",
                  "col.axis", "col.lab",
                  "font.axis", "font.lab",
                  "las", "mgp", "xaxp", "yaxp",
                  "tck", "tcl", "xpd")

  linmap <- function(x, from, to) {
    to[1] + diff(to) * (x - from[1])/diff(from)
  }

  # rules to determine the ribbon dimensions when one dimension is given
  widthrule <- function(heightrange, separate, n, gap) {
    if(separate) 1 else diff(heightrange)/10
  }
  heightrule <- function(widthrange, separate, n, gap) {
    (if(separate) (n + (n-1)*gap) else 10) * diff(widthrange) 
  }

  plot.colourmap <- function(x, ..., main,
                             xlim=NULL, ylim=NULL, vertical=FALSE, axis=TRUE,
                             labelmap=NULL, gap=0.25, add=FALSE) {
    if(missing(main))
      main <- short.deparse(substitute(x))
    stuff <- attr(x, "stuff")
    col <- stuff$outputs
    n   <- stuff$n
    if(n == 0) {
      ## Null map
      return(invisible(NULL))
    }
    discrete <- stuff$discrete
    if(discrete) {
      check.1.real(gap, "In plot.colourmap")
      explain.ifnot(gap >= 0, "In plot.colourmap")
    }
    separate <- discrete && (gap > 0)
    if(is.null(labelmap)) {
      labelmap <- function(x) x
    } else if(is.numeric(labelmap) && length(labelmap) == 1 && !discrete) {
      labscal <- labelmap
      labelmap <- function(x) { x * labscal }
    } else stopifnot(is.function(labelmap))

    # determine pixel entries 'v' and colour map breakpoints 'bks'
    # to be passed to 'image.default'
    if(!discrete) {
      # real numbers: continuous ribbon
      bks <- stuff$breaks
      rr <- range(bks)
      v <- seq(from=rr[1], to=rr[2], length.out=max(n+1, 1024))
    } else if(!separate) {
      # discrete values: blocks of colour, run together
      v <- (1:n) - 0.5
      bks <- 0:n
      rr <- c(0,n)
    } else {
      # discrete values: separate blocks of colour
      vleft <- (1+gap) * (0:(n-1))
      vright <- vleft + 1
      v <- vleft + 0.5
      rr <- c(0, n + (n-1)*gap)
    }
    # determine position of ribbon or blocks of colour
    if(is.null(xlim) && is.null(ylim)) {
      u <- widthrule(rr, separate, n, gap)
      if(!vertical) {
        xlim <- rr
        ylim <- c(0,u)
      } else {
        xlim <- c(0,u)
        ylim <- rr
      }
    } else if(is.null(ylim)) {
      if(!vertical) 
        ylim <- c(0, widthrule(xlim, separate, n, gap))
      else 
        ylim <- c(0, heightrule(xlim, separate, n, gap))
    } else if(is.null(xlim)) {
      if(!vertical) 
        xlim <- c(0, heightrule(ylim, separate, n, gap))
      else 
        xlim <- c(0, widthrule(ylim, separate, n, gap))
    } 

    # .......... initialise plot ...............................
    if(!add)
      do.call.matched("plot.default",
                      resolve.defaults(list(x=xlim, y=ylim,
                                            type="n", main=main,
                                            axes=FALSE, xlab="", ylab="",
                                            asp=1.0),
                                       list(...)))
    
    if(separate) {
      # ................ plot separate blocks of colour .................
      if(!vertical) {
        # horizontal arrangement of blocks
        xleft <- linmap(vleft, rr, xlim)
        xright <- linmap(vright, rr, xlim)
        y <- ylim
        z <- matrix(1, 1, 1)
        for(i in 1:n) {
          x <- c(xleft[i], xright[i])
          do.call.matched("image.default",
                      resolve.defaults(list(x=x, y=y, z=z, add=TRUE),
                                       list(...),
                                       list(col=col[i])),
                      extrargs=imageparams)
                          
        }
      } else {
        # vertical arrangement of blocks
        x <- xlim 
        ylow <- linmap(vleft, rr, ylim)
        yupp <- linmap(vright, rr, ylim)
        z <- matrix(1, 1, 1)
        for(i in 1:n) {
          y <- c(ylow[i], yupp[i])
          do.call.matched("image.default",
                      resolve.defaults(list(x=x, y=y, z=z, add=TRUE),
                                       list(...),
                                       list(col=col[i])),
                      extrargs=imageparams)
                          
        }
      }
    } else {
      # ................... plot ribbon image .............................
      if(!vertical) {
        # horizontal colour ribbon
        x <- linmap(v, rr, xlim)
        y <- ylim
        z <- matrix(v, ncol=1)
      } else {
        # vertical colour ribbon
        y <- linmap(v, rr, ylim)
        z <- matrix(v, nrow=1)
        x <- xlim
      }
      do.call.matched("image.default",
                      resolve.defaults(list(x=x, y=y, z=z, add=TRUE),
                                       list(...),
                                       list(breaks=bks, col=col)),
                      extrargs=imageparams)
    }
    if(axis) {
      # ................. draw annotation ..................
      if(!vertical) {
          # add horizontal axis/annotation
        if(discrete) {
          la <- paste(labelmap(stuff$inputs))
          at <- linmap(v, rr, xlim)
        } else {
          la <- prettyinside(rr)
          at <- linmap(la, rr, xlim)
          la <- labelmap(la)
        }
        # default axis position is below the ribbon (side=1)
        sidecode <- resolve.1.default("side", list(...), list(side=1))
        if(!(sidecode %in% c(1,3)))
          warning(paste("side =", sidecode,
                        "is not consistent with horizontal orientation"))
        pos <- c(ylim[1], xlim[1], ylim[2], xlim[2])[sidecode]
        # don't draw axis lines if plotting separate blocks
        lwd0 <- if(separate) 0 else 1
        # draw axis
        do.call.matched("axis",
                        resolve.defaults(list(...),
                                         list(side = 1, pos = pos, at = at),
                                         list(labels=la, lwd=lwd0)),
                        extrargs=axisparams)
      } else {
        # add vertical axis
        if(discrete) {
          la <- paste(labelmap(stuff$inputs))
          at <- linmap(v, rr, ylim)
        } else {
          la <- prettyinside(rr)
          at <- linmap(la, rr, ylim)
          la <- labelmap(la)
        }
        # default axis position is to the right of ribbon (side=4)
        sidecode <- resolve.1.default("side", list(...), list(side=4))
        if(!(sidecode %in% c(2,4)))
          warning(paste("side =", sidecode,
                        "is not consistent with vertical orientation"))
        pos <- c(ylim[1], xlim[1], ylim[2], xlim[2])[sidecode]
        # don't draw axis lines if plotting separate blocks
        lwd0 <- if(separate) 0 else 1
        # draw labels horizontally if plotting separate blocks
        las0 <- if(separate) 1 else 0
        # draw axis
        do.call.matched("axis",
                        resolve.defaults(list(...),
                                         list(side=4, pos=pos, at=at),
                                         list(labels=la, lwd=lwd0, las=las0)),
                        extrargs=axisparams)
      }
    }
    invisible(NULL)
  }

  plot.colourmap
})


# Interpolate a colourmap or lookup table defined on real numbers

interp.colourmap <- function(m, n=512) {
  if(!inherits(m, "colourmap"))
    stop("m should be a colourmap")
  st <- attr(m, "stuff")
  if(st$discrete) {
    # discrete set of input values mapped to colours
    xknots <- st$inputs
    # Ensure the inputs are real numbers
    if(!is.numeric(xknots))
      stop("Cannot interpolate: inputs are not numerical values")
  } else {
    # interval of real line, chopped into intervals, mapped to colours
    # Find midpoints of intervals
    bks <- st$breaks
    nb <- length(bks)
    xknots <- (bks[-1] + bks[-nb])/2
  }
  # corresponding colours in hsv coordinates
  yknots.hsv <- rgb2hsva(col2rgb(st$outputs, alpha=TRUE))
  # transform 'hue' from polar to cartesian coordinate
  # divide domain into n equal intervals
  xrange <- range(xknots)
  xbreaks <- seq(xrange[1], xrange[2], length=n+1)
  xx <- (xbreaks[-1] + xbreaks[-(n+1)])/2
  # interpolate saturation and value in hsv coordinates
  yy.sat <- approx(x=xknots, y=yknots.hsv["s", ], xout=xx)$y
  yy.val <- approx(x=xknots, y=yknots.hsv["v", ], xout=xx)$y
  # interpolate hue by first transforming polar to cartesian coordinate
  yknots.hue <- 2 * pi * yknots.hsv["h", ]
  yy.huex <- approx(x=xknots, y=cos(yknots.hue), xout=xx)$y
  yy.huey <- approx(x=xknots, y=sin(yknots.hue), xout=xx)$y
  yy.hue <- (atan2(yy.huey, yy.huex)/(2 * pi)) %% 1
  # handle transparency
  yknots.alpha <- yknots.hsv["alpha", ]
  if(all(yknots.alpha == 1)) {
    ## opaque colours: form using hue, sat, val
    yy <- hsv(yy.hue, yy.sat, yy.val)
  } else {
    ## transparent colours: interpolate alpha
    yy.alpha <- approx(x=xknots, y=yknots.alpha, xout=xx)$y
    ## form colours using hue, sat, val, alpha
    yy <- hsv(yy.hue, yy.sat, yy.val, yy.alpha)    
  }
  # done
  f <- colourmap(yy, breaks=xbreaks)
  return(f)
}

interp.colours <- function(x, length.out=512) {
  y <- colourmap(x, range=c(0,1))
  z <- interp.colourmap(y, length.out)
  oo <- attr(z, "stuff")$outputs
  return(oo)
}

tweak.colourmap <- local({

  is.hex <- function(z) {
    is.character(z) &&
    all(nchar(z, keepNA=TRUE) %in% c(7,9)) &&
    identical(substr(z, 1, 7), substr(col2hex(z), 1, 7))
  }

  tweak.colourmap <- function(m, col, ..., inputs=NULL, range=NULL) {
    if(!inherits(m, "colourmap"))
      stop("m should be a colourmap")
    if(is.null(inputs) && is.null(range)) 
      stop("Specify either inputs or range")
    if(!is.null(inputs) && !is.null(range))
      stop("Do not specify both inputs and range")
    ## determine indices of colours to be changed
    if(!is.null(inputs)) {
      ix <- m(inputs, what="index")
    } else {
      if(!(is.numeric(range) && length(range) == 2 && diff(range) > 0))
        stop("range should be a numeric vector of length 2 giving (min, max)")
      if(length(col2hex(col)) != 1)
        stop("When range is given, col should be a single colour value")
      ixr <- m(range, what="index")
      ix <- (ixr[1]):(ixr[2])
    }
    ## reassign colours
    st <- attr(m, "stuff")
    outputs <- st$outputs
    result.hex <- FALSE
    if(is.hex(outputs)) {
      ## convert replacement data to hex
      col <- col2hex(col)
      result.hex <- TRUE
    } else if(is.hex(col)) {
      ## convert existing data to hex
      outputs <- col2hex(outputs)
      result.hex <- TRUE
    } else if(!(is.character(outputs) && is.character(col))) {
      ## unrecognised format - convert both to hex
      outputs <- col2hex(outputs)
      col <- col2hex(col)
      result.hex <- TRUE
    }
    if(result.hex) {
      ## hex codes may be 7 or 9 characters
      outlen <- nchar(outputs)
      collen <- nchar(col)
      if(length(unique(c(outlen, collen))) > 1) {
        ## convert all to 9 characters
        if(any(bad <- (outlen == 7))) 
          outputs[bad] <- paste0(outputs[bad], "FF")
        if(any(bad <- (collen == 7))) 
          col[bad] <- paste0(col[bad], "FF")
      }
    }
    ## Finally, replace
    outputs[ix] <- col
    st$outputs <- outputs
    attr(m, "stuff") <- st
    assign("stuff", st, envir=environment(m))
    return(m)
  }

  tweak.colourmap
})

colouroutputs <- function(x) {
  stopifnot(inherits(x, "colourmap"))
  attr(x, "stuff")$outputs
}

"colouroutputs<-" <- function(x, value) {
  stopifnot(inherits(x, "colourmap"))
  st <- attr(x, "stuff")
  col2hex(value) # validates colours
  st$outputs[] <- value
  attr(x, "stuff") <- st
  assign("stuff", st, envir=environment(x))
  return(x)
}

