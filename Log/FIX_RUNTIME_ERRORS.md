# Runtime fixes

- Replaced deprecated DropdownButtonFormField.value with initialValue.
- Added isExpanded and ellipsis to prevent long ward/type text from overflowing.
- Deferred property detail loading until after the first frame to avoid markNeedsBuild during build.
- Added WebHtmlElementStrategy.prefer for public network images on Flutter Web.
