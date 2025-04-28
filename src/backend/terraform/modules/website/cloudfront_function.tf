resource "aws_cloudfront_function" "redirect_and_add_index_html" {
  name    = "redirect-and-add-index-html-for-mine-bitcoin-online-frontend-${var.environment}"
  runtime = "cloudfront-js-1.0"
  publish = true

  code = <<EOT
function handler(event) {
    var request = event.request;
    var uri = request.uri;

    // Normalize multiple slashes
    uri = uri.replace(/\/{2,}/g, '/');

    // Remove all trailing slashes
    uri = uri.replace(/\/+$/, '');

    // If URI is empty, set it to "/"
    if (uri === '') {
        uri = '/';
    }

    // skip rewrite for known static folders
    if (uri.startsWith('/_next/') || uri.startsWith('/static/') || uri.startsWith('/assets/') || uri.startsWith('/media/')) {
        request.uri = uri;
        return request;
    }

    // skip rewriting if the path looks like a file (has a file extension)
    if (uri.match(/\.[a-zA-Z0-9]+$/)) {
        request.uri = uri;
        return request;
    }

    // else it is a page, so put an ending slash on it
    if (!uri.endsWith('/')) {
        uri += '/';
    }

    request.uri = uri + 'index.html';
    return request;
}
EOT
}
