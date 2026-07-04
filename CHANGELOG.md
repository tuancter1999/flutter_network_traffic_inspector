## 1.0.0

- Initial release.
- Draggable floating overlay with HTTP and WebSocket log panels.
- `DebugOverlayHost` — inserts the overlay into the navigator overlay.
- `DraggableDebugOverlay` — floating eye-button with snap-to-edge behaviour.
- `DebugOverlayPanel` — tabbed HTTP / WebSocket log list.
- `DebugLogInterceptor` — Dio interceptor for automatic HTTP capture.
- `NetworkDebugBus` — reactive in-memory log store (ChangeNotifier).
- Filter logs by status (all / success / error) and free-text URL search.
- Copy any body to clipboard.
- Ping/pong WebSocket frames filtered automatically.
