#include <stdlib.h>
#include <vector>
#include "ring.h"

class estimator {
 public:
  virtual bool update(float input) = 0;
  float xe, xdote;
  void reset() { xdote = 0; }
};

class Lowpass : public estimator { // a low pass filter
 protected:
  size_t k, order, outliers, dwindow, window, outlier_sigma;

  Ring<float> x //to calculate sample variance
    , y, z, a, b;/* These variable names follow standard digital filtering notation,
		    a[0]y[k] = a[1]*y[k-1] + ... + a[n]*y[k-n]
		    + b[0]*z[k] + ... + b[m]*z[k-m]
		    where
		    z[i] = measurements
		    y[i] = filter outputs
		    n = filter order
		 */
 public:
 Lowpass(size_t window, size_t order)
   : window(window), order(order)
    , x(window), y(window), z(window), a(order+1), b(order+1)
    {};
  float mean, sigma, period, cutoffhz;
  bool update(float input);
  bool reset(float hz, float sampling_period, unsigned outlier_sigma = 10);
};
