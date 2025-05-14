# Changelog

English | [中文](CHANGELOG_zh.md)

## 1.0.3 - Documentation and Examples Enhancement

* **Code Comments Improvement**:
  * Enhanced documentation comments for core classes and methods
  * Added detailed implementation logic explanations
  * Improved parameter and return value descriptions

* **README Documentation Enhancement**:
  * Added more detailed feature descriptions
  * Provided complete usage guides
  * Enriched code examples and best practices

* **Example Code Improvement**:
  * Added more practical application scenarios
  * Included advanced functionality demonstrations
  * Improved example documentation

## 1.0.2 - Optimization and Bug Fixes

* **Memory Leak Fixes**:
  * Fixed Timer memory leak issue in the `takeForDuration` method
  * Improved debounce and throttle implementations to ensure proper resource release

* **Concurrency Handling Improvements**:
  * Used fine-grained locks instead of global locks to increase throughput
  * Separated locks for scheduling, storage, and publishing operations

* **Event Retry Mechanism Enhancement**:
  * Implemented intelligent retry strategies with maximum retry counts based on priority
  * Added exponential backoff algorithm to avoid immediate retries of failed events
  * Optimized retry order, prioritizing new events and events with fewer retry attempts

* **Type Safety**:
  * Unified metadata creation approach using dedicated factory methods
  * Enhanced type safety in event stream conversions

* **Resource Management**:
  * Added stricter resource management and release mechanisms
  * Improved resource release in exception scenarios

* **Other Improvements**:
  * Extended statistics to include permanent failures and retry counts
  * Added more detailed event failure information

## 1.0.1 - Initial Version

* First public release
