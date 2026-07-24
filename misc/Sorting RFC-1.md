# RFC: AdaptiveOutlierSort - A Cache-Conscious Sorting Hypothesis

**Authors:** Claude AI & Human Collaborator  
**Version:** 2.0 (Revised)  
**Status:** Experimental - Validation Required  
**Date:** January 2025

## ⚠️ Important Notice

This RFC presents a **hypothesis** about a potential performance optimization for sorting data with outliers. The performance benefits are **theoretical and unvalidated**. Rigorous testing with real-world datasets and hardware profiling is required before any production use.

## Quick Start

```python
# Basic usage with statistical outlier detection
from adaptive_outlier_sort import AdaptiveOutlierSort

sorter = AdaptiveOutlierSort()
sorted_data = sorter.sort([1, 2, 3, 1000, 4, 5, -1000, 6, 7, 8])
# Result: [-1000, 1, 2, 3, 4, 5, 6, 7, 8, 1000]

# Compare with simple filtering approach:
# sorted([x for x in data if -100 <= x <= 100] + 
#        [x for x in data if x < -100 or x > 100])
```

## 1. Abstract

This document proposes `AdaptiveOutlierSort`, an experimental sorting approach that segregates outliers before sorting. The hypothesis is that removing outliers might improve cache efficiency during the sort operation, potentially providing performance benefits for specific data patterns.

**This is an unproven hypothesis requiring validation.** The implementation provides a framework for testing whether outlier segregation can improve sort performance through better memory access patterns.

## 2. Hypothesis and Motivation

### The Hypothesis

When sorting data with extreme outliers, segregating these outliers might improve performance by:

1. **Better cache utilization** - Sorting values with similar magnitudes may lead to more predictable memory access patterns
2. **Reduced comparison complexity** - Comparing similar values might be faster than comparing vastly different ones
3. **Improved branch prediction** - More uniform data might lead to fewer branch mispredictions

### Critical Unknowns

- Does outlier segregation actually improve cache performance?
- What is the overhead of the detection and merge phases?
- For what data patterns (if any) does this approach provide benefits?
- How does this compare to simply filtering and sorting?

### Why This Needs Investigation

Modern CPUs are complex, and performance is dominated by:

- Cache misses (100-300 cycles penalty)
- Branch mispredictions (10-20 cycles penalty)
- Memory bandwidth limitations

Without hardware profiling, any performance claims are speculation.

## 3. Design Principles

1. **Experimental Framework** - The code is designed to facilitate testing different outlier detection strategies and measure their impact
2. **Conservative Claims** - No performance claims without data
3. **Configurable Thresholds** - All magic numbers are tunable to find optimal values experimentally
4. **Fallback Safety** - Always falls back to standard sort when detection overhead might exceed benefits

## 4. Implementation

```python
"""
adaptive_outlier_sort.py

An experimental sorting approach for testing outlier segregation hypothesis.
Performance benefits are UNPROVEN and require validation.

Version: 2.0 (Experimental)
License: MIT
"""

import logging
import random
import heapq
import math
import concurrent.futures
from typing import List, Callable, Tuple, Optional, TypeVar, Union

logger = logging.getLogger(__name__)
T = TypeVar('T')


class AdaptiveOutlierSort:
    """
    Experimental sorting system that segregates outliers.
    
    WARNING: Performance benefits are hypothetical and unvalidated.
    Use only for experimentation and benchmarking.
    """
    
    def __init__(
        self,
        outlier_detector: Optional[Union[str, Callable]] = "iqr",
        outlier_ratio_threshold: float = 0.1,
        min_size_threshold: int = 10000,  # Raised - small arrays won't benefit
        iqr_sample_size: int = 200,
        iqr_multiplier: float = 3.0,
    ):
        self.outlier_ratio_threshold = outlier_ratio_threshold
        self.min_size_threshold = min_size_threshold
        self.iqr_sample_size = iqr_sample_size
        self.iqr_multiplier = iqr_multiplier
        
        if callable(outlier_detector):
            self.outlier_detector = outlier_detector
        elif outlier_detector == "iqr":
            self.outlier_detector = self._default_iqr_detector
        else:
            raise ValueError("outlier_detector must be 'iqr' or a callable")
    
    def _default_iqr_detector(self, arr: List[T]) -> Tuple[List[T], List[T]]:
        """
        IQR-based outlier detection with proper quantile calculation.
        
        Note: This is still O(n) due to the partitioning pass.
        Whether this overhead is worth it depends on cache effects.
        """
        if not arr:
            return [], []
        
        # Filter out NaN and infinity values first
        arr_clean = []
        arr_invalid = []
        
        for x in arr:
            try:
                if math.isnan(x) or math.isinf(x):
                    arr_invalid.append(x)
                else:
                    arr_clean.append(x)
            except (TypeError, ValueError):
                # Not a numeric type, proceed normally
                arr_clean.append(x)
        
        if not arr_clean:
            return [], arr_invalid
        
        # Sample for IQR calculation
        sample_size = min(len(arr_clean), self.iqr_sample_size)
        if len(arr_clean) <= sample_size:
            sample = sorted(arr_clean)
        else:
            sample = sorted(random.sample(arr_clean, sample_size))
        
        # Proper quantile calculation
        def quantile(data, q):
            n = len(data)
            idx = q * (n - 1)
            lower = int(idx)
            upper = min(lower + 1, n - 1)
            weight = idx - lower
            return data[lower] * (1 - weight) + data[upper] * weight
        
        q1 = quantile(sample, 0.25)
        q3 = quantile(sample, 0.75)
        iqr = q3 - q1
        
        if iqr == 0:
            # All sampled values are identical
            return arr_clean, arr_invalid
        
        lower_bound = q1 - self.iqr_multiplier * iqr
        upper_bound = q3 + self.iqr_multiplier * iqr
        
        # Partition (O(n) pass - this is the overhead we're betting against)
        normal, outliers = [], []
        for x in arr_clean:
            if lower_bound <= x <= upper_bound:
                normal.append(x)
            else:
                outliers.append(x)
        
        # Add invalid values to outliers
        outliers.extend(arr_invalid)
        
        return normal, outliers
    
    def sort(self, arr: List[T]) -> List[T]:
        """
        Sort using outlier segregation.
        
        WARNING: May be SLOWER than standard sort due to overhead.
        Profile before using in production.
        """
        n = len(arr)
        
        if n < self.min_size_threshold:
            return sorted(arr)
        
        normal, outliers = self.outlier_detector(arr)
        outlier_ratio = len(outliers) / n if n > 0 else 0
        
        if outlier_ratio > self.outlier_ratio_threshold:
            # Too many outliers - overhead not worth it
            return sorted(arr)
        
        # The bet: these sorts are more cache-friendly than sorting mixed data
        sorted_normal = sorted(normal)
        sorted_outliers = sorted(outliers)
        
        return self._merge(sorted_normal, sorted_outliers)
    
    def _merge(self, arr1: List[T], arr2: List[T]) -> List[T]:
        """Standard merge - O(n) but with good cache behavior."""
        result = []
        i = j = 0
        
        while i < len(arr1) and j < len(arr2):
            if arr1[i] <= arr2[j]:
                result.append(arr1[i])
                i += 1
            else:
                result.append(arr2[j])
                j += 1
        
        result.extend(arr1[i:])
        result.extend(arr2[j:])
        return result


def simple_filter_sort(arr: List[float], bounds: Tuple[float, float]) -> List[float]:
    """
    Baseline: Simple filtering approach for comparison.
    
    This might be just as fast and simpler!
    """
    lower, upper = bounds
    normal = [x for x in arr if lower <= x <= upper]
    outliers = [x for x in arr if x < lower or x > upper]
    return sorted(normal) + sorted(outliers)
```

## 5. Validation Requirements

Before claiming ANY performance benefits, the following validation is required:

### 5.1 Test Datasets Needed

1. **Sensor Data**
- Real temperature/pressure readings with equipment failures
- At least 1M data points
- Document outlier percentage and distribution
1. **Financial Time Series**
- Real tick data with flash crashes/spikes
- Various time windows and volatility levels
1. **System Logs**
- Real timestamp data with clock skew issues
- Different scales (seconds, milliseconds, microseconds)
1. **Control Datasets**
- Uniformly random data (should show no benefit)
- Already sorted data (should show overhead only)
- Reverse sorted data

### 5.2 Outlier Definition Scenarios

Test with different outlier definitions to understand when the approach helps:

```python
# Statistical outliers (current approach)
def statistical_outlier(x, median, iqr):
    return abs(x - median) > 3 * iqr

# Magnitude outliers
def magnitude_outlier(x, median):
    return abs(x) > 100 * abs(median)

# Domain-specific outliers
def sensor_outlier(x, valid_range):
    return x < valid_range[0] or x > valid_range[1]

# Temporal outliers (for timestamps)
def temporal_outlier(x, median_time):
    return abs(x - median_time) > 86400  # >1 day from median

# Test scenarios:
outlier_scenarios = {
    'statistical_1%': (statistical_outlier, 0.01),
    'statistical_5%': (statistical_outlier, 0.05),
    'magnitude_sparse': (magnitude_outlier, 0.001),  # 0.1% extreme values
    'magnitude_common': (magnitude_outlier, 0.10),   # 10% extreme values
    'sensor_glitch': (sensor_outlier, 0.02),         # 2% bad readings
    'temporal_skew': (temporal_outlier, 0.005)       # 0.5% time jumps
}
```

### 5.3 Hardware Profiling Required

```bash
# Example using perf on Linux
perf stat -e cache-misses,cache-references,branches,branch-misses,\
page-faults,dTLB-misses,LLC-misses \
    python benchmark_sorts.py

# Key metrics to measure:
# - L1/L2/L3 cache miss rates
# - Instructions per cycle (IPC)
# - Branch prediction accuracy
# - Total CPU cycles
# - Memory bandwidth utilization
# - Page faults (major/minor)
# - TLB (Translation Lookaside Buffer) misses
```

### 5.4 Cost Model

To evaluate if outlier segregation might help, consider this simplified cost model:

```python
def estimate_benefit(n, outlier_ratio, cache_miss_reduction_factor=0.3):
    """
    Rough estimation of whether approach might provide benefit.
    
    Args:
        n: Size of dataset
        outlier_ratio: Fraction of outliers (0.0 to 1.0)
        cache_miss_reduction_factor: Estimated reduction in cache misses
    
    Returns:
        Dictionary with cost breakdown
    """
    # Approximate costs (in CPU cycles)
    CACHE_MISS_COST = 200  # L3 miss to main memory
    COMPARISON_COST = 1    # Basic comparison
    BRANCH_MISS_COST = 15  # Mispredicted branch
    
    # Standard sort costs (simplified model)
    comparisons_standard = n * math.log2(n)
    cache_misses_standard = n * 0.1  # Assume 10% miss rate with mixed data
    standard_cost = (comparisons_standard * COMPARISON_COST + 
                    cache_misses_standard * CACHE_MISS_COST)
    
    # Segregated sort costs
    detection_cost = n * 2  # O(n) partition pass
    
    n_normal = n * (1 - outlier_ratio)
    n_outlier = n * outlier_ratio
    
    # Assume better cache behavior for segregated data
    cache_misses_segregated = (n_normal * 0.05 +  # 5% miss rate for uniform data
                              n_outlier * 0.15)    # 15% for outliers
    
    comparisons_segregated = (n_normal * math.log2(max(n_normal, 1)) + 
                             n_outlier * math.log2(max(n_outlier, 1)))
    
    merge_cost = n * 2  # O(n) merge
    
    segregated_cost = (detection_cost + 
                      comparisons_segregated * COMPARISON_COST +
                      cache_misses_segregated * CACHE_MISS_COST * 
                      (1 - cache_miss_reduction_factor) +
                      merge_cost)
    
    return {
        'standard_cost': standard_cost,
        'segregated_cost': segregated_cost,
        'potential_speedup': standard_cost / segregated_cost,
        'worth_trying': segregated_cost < standard_cost * 0.8  # 20% improvement threshold
    }

# Example usage:
# For 1M elements with 1% outliers:
estimate = estimate_benefit(1_000_000, 0.01)
print(f"Potential speedup: {estimate['potential_speedup']:.2f}x")
print(f"Worth trying: {estimate['worth_trying']}")
```

**Key insight**: The approach is most likely to help when:

- Dataset is large (>100K elements)
- Outlier percentage is small (<5%)
- Cache miss cost is high (large data structures)
- Data shows poor cache locality when mixed

### 5.5 Comparison Methodology

```python
def benchmark_sort_approaches(data, runs=10):
    """Compare different sorting approaches with proper methodology."""
    
    results = {
        'standard_sort': [],
        'adaptive_sort': [],
        'simple_filter': [],
        'numpy_sort': []
    }
    
    # Warm up caches
    _ = sorted(data[:1000])
    
    for _ in range(runs):
        # Randomize order to avoid cache effects between runs
        random.shuffle(data)
        data_copy = data.copy()
        
        # Standard sort
        start = time.perf_counter()
        result1 = sorted(data_copy)
        results['standard_sort'].append(time.perf_counter() - start)
        
        # Adaptive sort
        data_copy = data.copy()
        sorter = AdaptiveOutlierSort()
        start = time.perf_counter()
        result2 = sorter.sort(data_copy)
        results['adaptive_sort'].append(time.perf_counter() - start)
        
        # Verify correctness
        assert result1 == result2, "Results don't match!"
        
        # Simple filter (if bounds are known)
        if known_bounds:
            data_copy = data.copy()
            start = time.perf_counter()
            result3 = simple_filter_sort(data_copy, known_bounds)
            results['simple_filter'].append(time.perf_counter() - start)
    
    return results
```

### 5.6 Success Criteria

The approach is only valuable if:

1. **Consistent speedup** on target data patterns (>20% improvement)
2. **Hardware metrics** show improved cache behavior
3. **Overhead is acceptable** for the detection phase
4. **Benefits scale** with data size
5. **Simpler alternatives** don’t provide same benefits

## 6. Critical Analysis

### What We Don’t Know

1. **Cache Effects** - Do segregated values actually have better cache locality?
2. **Comparison Costs** - Are comparisons between similar values meaningfully faster?
3. **Modern CPU Behavior** - Do features like prefetching eliminate potential benefits?
4. **Timsort Internals** - Does Timsort already handle this pattern efficiently?

### Potential Failure Modes

1. **Detection overhead exceeds benefits** - The O(n) partition pass might cost more than any savings
2. **No cache improvement** - Modern CPUs might prefetch effectively regardless
3. **Simpler is better** - A basic filter+sort might be just as fast
4. **Wrong hypothesis** - The performance bottleneck might be elsewhere entirely

### Alternative Approaches to Test

```python
# Approach 1: In-place partitioning (less memory usage)
def partition_sort(arr, predicate):
    # Partition in-place like quicksort
    # Then sort each partition
    pass

# Approach 2: Bucketing by magnitude
def magnitude_bucket_sort(arr):
    # Group by power of 10
    # Sort each bucket
    # Merge buckets
    pass

# Approach 3: Just use NumPy
def numpy_sort(arr):
    # NumPy's sort is highly optimized
    # Might beat any custom approach
    return np.sort(arr)
```

## 7. Honest Conclusions

1. **This is a hypothesis, not a proven optimization**
2. **Performance benefits are speculative without hardware profiling**
3. **The approach adds complexity that may not be justified**
4. **Simpler alternatives should be tested first**
5. **Real-world validation is essential before any production use**

The value of this work may not be the algorithm itself, but rather:

- The methodology for testing cache-conscious optimizations
- The framework for experimenting with preprocessing strategies
- The reminder that performance claims need empirical validation

## Next Steps

1. **Gather real datasets** from target domains
2. **Run hardware profiling** to measure cache behavior
3. **Test simpler alternatives** (filtering, numpy, etc.)
4. **Document failure cases** where the approach doesn’t help
5. **Only then consider production use** if benefits are proven

Remember: In performance optimization, measurement beats intuition every time.