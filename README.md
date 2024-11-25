# esp_opentelemetry_sdk

ESP wrapper for SDK of [OpenTelemetry C++ Client](https://github.com/open-telemetry/opentelemetry-cpp).


## What is OpenTelemetry?

[OpenTelemetry](https://opentelemetry.io/) is a collection of APIs, SDKs, and tools.
Use it to instrument, generate, collect, and export telemetry data (metrics,
logs, and traces) to help you analyze your software’s performance and behavior.


## How to use

```
idf.py add-dependency albkharisov/esp_opentelemetry_sdk && \
idf.py add-dependency albkharisov/esp_opentelemetry_api
```

If you go another way and clone git-repo - don't forget to fetch submodules.


## Description

This part provides an SDK for defining your exporters to send collected data.
Data is collected via API-part OpenTelemetry data.


## Operation specifics

Code inside can spawn new threads as it uses `libstdc++`, and
ESP-IDF supports `pthread`. But not much: 1-2 depending on what you use.
Also code uses thread_local storages so it can affect stack size of all threads.
If you have tight byte-to-byte stack size keep this in mind.


## Size consumption

Approximate flash consumption for example-like instrumented
code (1 log/span/metric API + ostream exporters) will take:
 - Compiled for debug(-Og) + exceptions takes **~560** KB
 - Compiled for size (-Os) + exceptions takes **~340** KB
 - Compiled for size (-Os) + no exceptions takes **~250** KB

Of course this should be considered a minimum size, as it
will increase as you instrument your code.


## Examples

Initializing metrics ostream exporter:
```
#include "opentelemetry/sdk/metrics/export/periodic_exporting_metric_reader.h"
#include "opentelemetry/sdk/metrics/meter_provider.h"
#include "opentelemetry/sdk/metrics/metric_reader.h"
#include "opentelemetry/sdk/metrics/push_metric_exporter.h"
#include "opentelemetry/exporters/ostream/metric_exporter.h"
#include "opentelemetry/metrics/meter_provider.h"
#include "opentelemetry/metrics/provider.h"


namespace metrics_api = opentelemetry::metrics;
namespace metric_sdk = opentelemetry::sdk::metrics;


void initMetric() {
    auto options = metric_sdk::PeriodicExportingMetricReaderOptions{
        .export_interval_millis = std::chrono::milliseconds(20000),
        .export_timeout_millis = std::chrono::milliseconds(10000),
    };

    std::unique_ptr<metric_sdk::PushMetricExporter> exporter{
        new opentelemetry::exporter::metrics::OStreamMetricExporter};
    std::unique_ptr<metric_sdk::MetricReader> reader{
        new metric_sdk::PeriodicExportingMetricReader(std::move(exporter), options)};

    auto provider = std::shared_ptr<metrics_api::MeterProvider>(new metric_sdk::MeterProvider());
    auto p = std::static_pointer_cast<metric_sdk::MeterProvider>(provider);
    p->AddMetricReader(std::move(reader));

    std::shared_ptr<opentelemetry::metrics::MeterProvider> api_provider(std::move(provider));
    metrics_api::Provider::SetMeterProvider(api_provider);
}
```

Initializing logs + traces ostream exporters:
```
#include "opentelemetry/exporters/ostream/log_record_exporter.h"
#include "opentelemetry/logs/logger_provider.h"
#include "opentelemetry/logs/provider.h"
#include "opentelemetry/sdk/logs/exporter.h"
#include "opentelemetry/sdk/logs/logger_provider.h"
#include "opentelemetry/sdk/logs/logger_provider_factory.h"
#include "opentelemetry/sdk/logs/simple_log_record_processor_factory.h"

#include "opentelemetry/exporters/ostream/span_exporter_factory.h"
#include "opentelemetry/sdk/trace/simple_processor_factory.h"
#include "opentelemetry/sdk/trace/tracer_provider.h"
#include "opentelemetry/sdk/trace/tracer_provider_factory.h"
#include "opentelemetry/trace/provider.h"
#include "opentelemetry/trace/tracer_provider.h"

namespace logs_api = opentelemetry::logs;
namespace logs_sdk = opentelemetry::sdk::logs;
namespace logs_exporter = opentelemetry::exporter::logs;

namespace trace_api = opentelemetry::trace;
namespace trace_sdk = opentelemetry::sdk::trace;
namespace trace_exporter = opentelemetry::exporter::trace;

void initTracer() {
    // Create ostream span exporter instance
    auto exporter = trace_exporter::OStreamSpanExporterFactory::Create();
    auto processor = trace_sdk::SimpleSpanProcessorFactory::Create(std::move(exporter));

    std::shared_ptr<opentelemetry::sdk::trace::TracerProvider> sdk_provider =
        trace_sdk::TracerProviderFactory::Create(std::move(processor));

    // Set the global trace provider
    const std::shared_ptr<trace_api::TracerProvider> &api_provider = sdk_provider;
    trace_api::Provider::SetTracerProvider(api_provider);
}

void initLogger() {
    // Create ostream log exporter instance
    auto exporter =
        std::unique_ptr<logs_sdk::LogRecordExporter>(new logs_exporter::OStreamLogRecordExporter);
    auto processor = logs_sdk::SimpleLogRecordProcessorFactory::Create(std::move(exporter));

    std::shared_ptr<opentelemetry::sdk::logs::LoggerProvider> sdk_provider(
        logs_sdk::LoggerProviderFactory::Create(std::move(processor)));

    // Set the global logger provider
    const std::shared_ptr<logs_api::LoggerProvider> &api_provider = sdk_provider;
    logs_api::Provider::SetLoggerProvider(api_provider);
}
```


Full original examples are [here](https://github.com/open-telemetry/opentelemetry-cpp/tree/main/examples).



