\name{intensity.dppmodel}
\alias{intensity.dppmodel}
\title{Intensity of Determinantal Point Process Model}
\description{Extracts the intensity of a determinantal point process model.}
\usage{
  \method{intensity}{dppmodel}(X, \dots)
}
\arguments{
  \item{X}{
    A determinantal point process model (object of class
    \code{dppmodel}).
  }
  \item{\dots}{Ignored.}
}
\value{
  A numeric value (if the model is stationary), a pixel image
  (if the model is non-stationary) or \code{NA} if the intensity is
  unknown for the model.
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
\keyword{spatial}
\keyword{models}


