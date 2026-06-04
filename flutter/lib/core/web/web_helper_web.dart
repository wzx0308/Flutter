import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// Read a Blob URL (e.g. from record package) and return its bytes.
Future<Uint8List> readBlobUrl(String blobUrl) async {
  final completer = Completer<Uint8List>();

  // fetch(blobUrl) → response.arrayBuffer() → Uint8List
  final fetchPromise = web.window.fetch(blobUrl.toJS);
  fetchPromise.toDart.then(
    (response) {
      final bufPromise = (response as web.Response).arrayBuffer();
      bufPromise.toDart.then(
        (buffer) {
          if (!completer.isCompleted) {
            completer.complete(Uint8List.view(buffer.toDart));
          }
        },
        onError: (e) {
          if (!completer.isCompleted) {
            completer.completeError(Exception('Failed to read Blob buffer: $e'));
          }
        },
      );
    },
    onError: (e) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Failed to fetch Blob: $e'));
      }
    },
  );

  return completer.future;
}

/// Web 端修复 model-viewer CSS 覆盖 + 资源路径问题
void initWebFixes() {
  // Inject base CSS constraints via JS
  web.window.document.head?.append(
    web.HTMLStyleElement()
      ..textContent = '''
    model-viewer {
      width: 100% !important;
      height: 100% !important;
      position: absolute !important;
      top: 0 !important;
      left: 0 !important;
      border-radius: 50% !important;
      overflow: hidden !important;
      background: transparent !important;
    }
    flt-platform-view-slot {
      overflow: hidden !important;
      position: relative !important;
      display: block !important;
    }
  ''',
  );

  // MutationObserver: auto-fix new model-viewer elements
  web.window.document.head?.append(
    web.HTMLScriptElement()
      ..type = 'text/javascript'
      ..text = '''
    (function() {
      function fixModelViewer(el) {
        el.style.width = '100%';
        el.style.height = '100%';
        el.style.position = 'absolute';
        el.style.top = '0';
        el.style.left = '0';
        el.style.borderRadius = '50%';
        el.style.overflow = 'hidden';
        el.style.background = 'transparent';
      }

      var observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(m) {
          m.addedNodes.forEach(function(node) {
            if (node.tagName === 'MODEL-VIEWER') {
              fixModelViewer(node);
            }
            if (node.querySelectorAll) {
              node.querySelectorAll('model-viewer').forEach(fixModelViewer);
            }
          });
        });
      });

      observer.observe(document.body, {
        childList: true,
        subtree: true
      });

      document.querySelectorAll('model-viewer').forEach(fixModelViewer);
    })();
  ''',
  );
}
