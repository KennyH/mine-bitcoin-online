# ADR: 003 - Browser Miner Implementation (Initial Phase: Web Worker + Single-Threaded WASM)

---

**Status:** Proposed / Draft

---

**Context:**

As defined in [ADR-001](./ADR-001-candidate-block-publishing-and-notification.md), the project requires a responsive client-side Bitcoin miner running in a web browser. It must fetch block templates and work assignments, perform SHA256d hashing, submit solutions, support user throttle control, and provide real-time hash rate feedback without blocking the main UI thread. This ADR focuses on the initial implementation using a single-threaded WASM module within a Web Worker, deferring multi-threaded WASM and GPU acceleration to future phases.

---

**Decision:**

The initial browser miner will use Rust compiled to single-threaded WebAssembly (WASM), executed within one or more Web Workers to keep the main UI thread responsive. A JavaScript host on the main thread will manage the user interface and coordination, while the worker handles WASM execution, work unit management (potentially including SQS interaction), and communication of mining progress and results back to the main thread.

---

**Architecture and Workflow (Initial Phase):**

1.  Core Technology: Rust for computation logic compiled to `wasm32-unknown-unknown`. A JavaScript host script for UI and AWS interaction, and a separate Web Worker script to load/run the WASM and manage its work.
2.  Main Thread (JavaScript Host):
    *   Initializes and manages AWS Cognito Identity Pools for temporary credentials.
    *   Handles all UI elements (network selection, start/stop, throttle slider, hash rate display, status messages).
    *   Connects to AWS IoT Core MQTT for template notifications.
    *   Calls an API Gateway to get the block template details, if not notified of a new block template via IoT MQTT.
    *   Creates and manages one or more Web Workers. For this initial phase, a single Web Worker, but the architecture should allow for adding more workers later.
    *   Receives template notifications and fetches template data (via CloudFront fetch call initiated from main thread or worker).
    *   Requests work units from SQS (via AWS SDK calls). This can be managed by the main thread and passed to the worker, or the worker can be granted necessary permissions (via credentials passed from main thread) to interact with SQS directly. Direct worker interaction simplifies work unit fetching logic. Starting with direct worker interaction for now.
    *   Sends work unit data to the worker via `worker.postMessage()`.
    *   Receives hash rate updates and solution findings from the worker via `worker.onmessage`.
    *   Updates the UI based on worker messages.
    *   If a solution is received, formats and submits the solution payload to the API Gateway endpoint.
    *   Utilizes the Screen Wake Lock API (`navigator.wakeLock`) to prevent the device screen from dimming or turning off while the miner is actively running and the page is visible.
    *   Manages the throttle setting from the UI, translating it into instructions sent to the worker.
3.  Web Worker (JavaScript):
    *   Runs in a separate background thread.
    *   Loads the Rust WASM module.
    *   Receives messages from the main thread (e.g., template data URL, SQS queue identifier, throttle level, work unit data).
    *   Fetches the main template JSON (if not passed directly).
    *   Stores the template data and current work unit state (assigned extra nonce range, SQS receipt handle).
    *   Periodically calls the WASM module to perform mining calculations on a portion of the assigned work unit.
    *   Implements the logic to break down the mining work (iterating through `main_nonce` for each `extra_nonce` in the range) into manageable chunks, yielding control within the worker's event loop between chunks (e.g., using `setTimeout(..., 0)` or similar within the worker script) to allow for message processing and avoid blocking the worker thread itself excessively.
    *   Tracks hash count and periodically sends hash rate updates to the main thread via `postMessage()`.
    *   Upon finding a solution from the WASM module, stops further mining on the current unit and sends the solution details to the main thread via `postMessage()`.
    *   If the work unit range is exhausted without a solution, signals completion to the main thread or directly calls SQS `DeleteMessage` and requests a new work unit.
    *   Receives and applies throttle instructions from the main thread, adjusting the size of work chunks or the delay between calls to the WASM module.
    *   If handling SQS directly, uses temporary credentials received from the main thread to call `ReceiveMessage` and `DeleteMessage`.
4.  Rust WASM (Single-Threaded):
    *   Implements the core cryptographic logic: double SHA256.
    *   Exposes functions callable from the Web Worker JS (e.g., `init_template(template_data)`, `mine_hashes(extra_nonce_start, main_nonce_start, num_hashes_to_try)`).
    *   Stores parsed template data in its memory.
    *   The `mine_hashes` function performs the specified number of header hash calculations:
        *   For the given `extra_nonce` (derived from `extra_nonce_start` and iteration count) and `main_nonce` (derived from `main_nonce_start` and iteration count):
            *   Reconstructs the coinbase transaction hash (using template data and the current `extra_nonce`, adhering to the fixed payout structure).
            *   Calculates the Merkle Root.
            *   Constructs the 80-byte block header.
            *   Calculates the double SHA256 hash of the header.
            *   Checks if the hash meets the target difficulty.
    *   Returns the number of hashes computed and the next state (next `extra_nonce`, `main_nonce`) back to the Web Worker JS. Signals if a solution was found, including the winning `main_nonce` and the corresponding `extra_nonce`.
    *   Does *not* manage throttling itself; it simply performs the requested amount of work per call from the worker JS.

---

**Formats & Interfaces:**

*   Main Thread <-> Web Worker: Communication via `postMessage()` and `onmessage` events. Data is serialized/deserialized (or transferred if possible) automatically by the browser. Messages will include structured data for:
    *   Sending: Template URL/data, SQS identifier, throttle level, work unit details (extra nonce range, SQS receipt handle), AWS credentials for SQS.
    *   Receiving: Hash count updates, Solution found (template identifier, winning nonces, signed core data), Work unit completion signal.
*   Web Worker <-> Rust WASM: Function calls defined by `wasm-bindgen`. Data passed as function arguments or results, likely involving structured data represented as Rust structs/enums that `wasm-bindgen` can interface with JavaScript objects.
*   AWS Interactions: Standard AWS SDK for JavaScript V3 calls from the Main Thread (IoT, API Gateway, Cognito). SQS calls are handled by the worker using credentials passed from the main thread.
*   Template Data: Parsed and used internally by the WASM module as per ADR-001 specifications (header fields, Merkle hashes, fixed coinbase structure details).

---

**Dependencies:**

*   Rust compiler (`wasm32-unknown-unknown` target).
*   `wasm-bindgen`, `wasm-pack`.
*   Rust crates: `sha2` ([https://github.com/RustCrypto/hashes/tree/master/sha2](https://github.com/RustCrypto/hashes/tree/master/sha2)), `rust-bitcoin` (core structures/hashing) ([https://github.com/rust-bitcoin/rust-bitcoin](https://github.com/rust-bitcoin/rust-bitcoin)), and JSON parsing (e.g., `serde`, `serde-wasm-bindgen`).
*   AWS SDK for JavaScript V3.
*   Browser supporting WebAssembly and Web Workers.

---

**Future Enhancements (Out of Scope for this ADR):**

*   ADR-XXX: Multi-threaded WASM Mining: Implement parallelism within the WASM module using WASM Threads and `SharedArrayBuffer` to leverage multiple CPU cores. Requires compiling Rust with threading support and careful handling of shared memory and synchronization primitives. Requires specific HTTP headers (`Cross-Origin-Opener-Policy`, `Cross-Origin-Embedder-Policy`).
*   ADR-YYY: GPU Accelerated Mining: Implement the double SHA256 algorithm as a shader program (WebGPU using WGSL or WebGL using GLSL) to offload computation to the graphics card. Requires significant new code, different skill sets (shader programming), and browser/hardware support considerations.
*   Adaptive Work Unit Requesting: Allow the miner worker to dynamically request larger or smaller SQS work unit ranges based on its current hash rate and target difficulty.
*   Enhanced Error Handling & Reporting: Handling of network errors, SQS issues, WASM execution failures, and reporting these to the user and potentially backend monitoring.
*   Improved Worker Management: If using multiple workers, implement load balancing and coordination among them.

---

**Consequences:**

*   Pros:
    *   Responsive user interface due to mining on a background Web Worker thread.
    *   Leverages Rust's performance and memory safety for the core hashing logic.
    *   WASM provides near-native execution speed for the computation.
    *   Clear separation of concerns between UI (Main Thread), worker coordination, and computation (WASM).
    *   Throttle control is achievable by adjusting the worker's processing rate.
    *   Hash rate observability is possible by tracking hashes in the worker.
    *   Direct consumption of work units from SQS by the worker (or main thread) is scalable.
    *   Fits within the AWS architecture defined in [ADR-001](./ADR-001-candidate-block-publishing-and-notification.md).
    *   Foundation laid for future multi-threading and GPU enhancements.

*   Cons:
    *   Increased complexity compared to a single-script approach (managing main thread JS, worker JS, and Rust WASM).
    *   Debugging Web Workers and WASM interaction can be more involved.
    *   Performance is limited to single-core CPU execution per worker in this initial phase.
    *   Communication overhead between main thread and worker via `postMessage` (though typically minor for the data involved here).

---
