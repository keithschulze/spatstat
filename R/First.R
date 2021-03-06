#  First.R
#
#  $Revision: 1.44 $ $Date: 2015/08/25 08:14:27 $
#

.onLoad <- function(...) reset.spatstat.options()

.onAttach <- function(libname, pkgname) {
  store.versionstring.spatstat()
  ver <- versionstring.spatstat()
  descfile <- system.file("DESCRIPTION", package="spatstat")
  ni <- as.character(read.dcf(file=descfile, fields="Nickname"))
  msg <- paste("\nspatstat", ver,
               "     ",
               paren(paste("nickname:", sQuote(ni))),
               "\nFor an introduction to spatstat, type",
               sQuote("beginner"))
  packageStartupMessage(msg)
  if(exists("getRversion") && getRversion() >= "3.2.2") {
    ## check versions
    rv <- R.Version()
    rdate <- with(rv, ISOdate(year, month, day))
    if(Sys.Date() - as.Date(rdate) > 270) {
      ## R version is really old; just warn about this
      packageStartupMessage(paste("\nNote:",
                                  rv$version.string,
                                  "is more than 9 months old;",
            "we strongly recommend upgrading to the latest version"))
    } else {
      ## warn if spatstat version is old
      packdate <- as.Date(read.dcf(file=descfile, fields="Date"))
      elapsed <- Sys.Date() - packdate
      if(elapsed > 75) {
        if(elapsed > 365) {
          n <- floor(elapsed/365)
          unit <- "year"
          sowhat <- "we strongly recommend upgrading to the latest version."
        } else if(elapsed > 100) {
          n <- floor(elapsed/30)
          unit <- "month"
          sowhat <- "we recommend upgrading to the latest version."
        } else {
          n <- floor(elapsed/7)
          unit <- "week"
          sowhat <- "a newer version should be available."
        }
        expired <- if(n == 1) paste("a", unit) else paste(n, paste0(unit, "s"))
        packageStartupMessage(paste("\nNote: spatstat version", ver,
                                    "is out of date by more than",
                                    paste0(expired, ";"), 
                                    sowhat))
      }
    }
  }
  invisible(NULL)
}

  
