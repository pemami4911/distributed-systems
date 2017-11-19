defmodule Twitter.Sim.Zipf do
@moduledoc """
Rejection-sampler for the discrete Zipf distribution.
Source: https://medium.com/@jasoncrease/rejection-sampling-the-zipf-distribution-6b359792cffa
"""
  
  @doc """
  Return a random sample from the Zipf distribution with parameters
  n, skew where n is 
  """
  def sample(n, skew) do
    t = (:math.pow(n, 1 - skew) - skew) / (1 - skew)
    inv_b = inv_cdf(:rand.uniform(), skew, t)
    sample_x = :math.floor(inv_b + 1)
    y_rand = :rand.uniform()
    ratio_top = :math.pow(sample_x, -skew) # z(x)
    ratio_bottom = # cdf b(x)
      if sample_x <= 1 do
        1 / t
      else
        :math.pow(inv_b, -skew) / t
      end
    ratio = ratio_top / (ratio_bottom * t)

    if y_rand < ratio do
      sample_x
    else
      # recurse until a sample is found
      sample(n, skew)
    end
  end

  defp inv_cdf(p, skew, t) do
    if p * t <= 1 do
      p * t
    else
      :math.pow((p * t) * (1 - skew) + skew, 1 / (1 - skew)) 
    end
  end

end