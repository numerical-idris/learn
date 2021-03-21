module GaussianProcess

import Tensor
import Data.Vect
import Kernel
import MeanFunction
import Optimize

public export
data GaussianProcess : (features : Shape) -> Type where
  MkGP : MeanFunction features -> Kernel features -> GaussianProcess features

public export
data Gaussian : (dim : Nat) -> Type where
  MkGaussian : (mean : Tensor [dim] Double) -> (cov : Tensor [dim, dim] Double) -> Gaussian dim

-- NOTE: since we can't do matrix multiplication with empty vectors, we can't do bayes without any training data
-- todo i think this is missing the contribution from the GP mean (assumes it's zero)
export
posterior : {samples : Nat}
 -> (prior : GaussianProcess features)
 -> (likelihood : Gaussian (S samples))
 -> (training_data : (Tensor ((S samples) :: features) Double, Tensor [S samples] Double))
 -> Maybe $ GaussianProcess features
-- todo replace case and tmp with `with` as
-- posterior (MkGP _ kernel) (MkGaussian _ cov) (x_train, y_train) with (inverse (kernel x_train x_train + cov))
--   | Nothing = Nothing
--   | Just inv = Just $ MkGP posterior_mean_function posterior_kernel where
posterior (MkGP _ kernel) (MkGaussian _ cov) (x_train, y_train) = case inverse {leading=[]} (kernel x_train x_train + cov) of
  Nothing => Nothing
  Just inv' => tmp inv' where
    tmp : Tensor [S samples, S samples] Double -> Maybe $ GaussianProcess features
    tmp inv = Just $ MkGP posterior_mean_function posterior_kernel where
      posterior_mean_function : MeanFunction features
      -- todo can we use rewrite to avoid the use of implicits here and for posterior_kernel?
      posterior_mean_function {samples} x = (@@) {leading=[]} {head=[samples]} ((@@) {leading=[]} {head=[samples]} (kernel x x_train) inv) y_train

      posterior_kernel : Kernel features
      posterior_kernel {samples} x x' = kernel x x' - (@@) {leading=[]} {head=[samples]} ((@@) {leading=[]} {head=[samples]} (kernel x x_train) inv) (kernel x_train x')

export
marginalise : {samples : Nat} -> GaussianProcess features -> Tensor (samples :: features) Double -> Gaussian samples
marginalise (MkGP mean_function kernel) x = MkGaussian (mean_function x) (kernel x x)

PI : Double

log_marginal_likelihood : {samples : Nat}
 -> GaussianProcess features
 -> Gaussian (S samples)
 -> (Tensor ((S samples) :: features) Double, Tensor [S samples] Double)
 -> Maybe $ Tensor [] Double
log_marginal_likelihood (MkGP _ kernel) (MkGaussian _ cov) (x, y) = let kc = kernel x x + cov in map foo (inverse {leading=[]} kc) where
  foo : Tensor [S samples, S samples] Double -> Tensor [] Double
  foo inv = (MkTensor (-1.0 / 2)) * ((@@) {leading=[]} {head=[]} ((@@) {leading=[]} {head=[]} y inv) y - (log $ det inv) + (MkTensor $ the Double $ cast samples) * (log $ MkTensor $ 2.0 * PI))

export
optimize : {samples : Nat}
 -> Optimizer hp
 -> (hp -> GaussianProcess features)
 -> Gaussian (S samples)
 -> (Tensor ((S samples) :: features) Double, Tensor [S samples] Double)
 -> Maybe hp
optimize optimizer gp_from_hyperparameters likelihood training_data = optimizer $ \h => log_marginal_likelihood (gp_from_hyperparameters h) likelihood training_data
