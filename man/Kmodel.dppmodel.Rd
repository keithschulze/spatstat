\name{Kmodel.dppmodel}
\alias{Kmodel.dppmodel}
\alias{pcfmodel.dppmodel}
\title{
  K-function or Pair Correlation Function of a
  Determinantal Point Process Model
} 
\description{Returns the theoretical \eqn{K}-function
  or theoretical pair correlation function of a determinantal point
  process model as a function of one argument \eqn{r}.
}
\usage{
   \method{Kmodel}{dppmodel}(model, \dots)

   \method{pcfmodel}{dppmodel}(model, \dots)
}
\arguments{
  \item{model}{Model of class \code{"dppmodel"}.}
  \item{\dots}{Ignored (not true -- there is some undocumented internal use)}
}
\author{
  Adrian Baddeley
  \email{Adrian.Baddeley@uwa.edu.au}
  \url{http://www.maths.uwa.edu.au/~adrian/}
  Rolf Turner
  \email{r.turner@auckland.ac.nz}
  and Ege Rubak
  \email{rubak@math.aau.dk}
}
\examples{
  model <- dppMatern(lambda=100, alpha=.01, nu=1, d=2)
  KMatern <- Kmodel(model)
  pcfMatern <- pcfmodel(model)
  plot(KMatern, xlim = c(0,0.05))
  plot(pcfMatern, xlim = c(0,0.05))
}
