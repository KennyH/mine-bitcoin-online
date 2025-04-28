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

    // Remove all trailing slashes, except for root
    if (uri !== '/') {
        uri = uri.replace(/\/+$/, '');
    }

    // skip rewrite for static folders
    if (uri.startsWith('/_next/') || uri.startsWith('/static/') || uri.startsWith('/assets/') || uri.startsWith('/media/')) {
        request.uri = uri;
        return request;
    }

    // skip rewrite for static root files
    if (uri.match(/^\/[^\/]+\.(ico|png|jpg|jpeg|svg|gif|txt|xml|json|webmanifest)$/)) {
        request.uri = uri;
        return request;
    }

    // skip rewriting if the path looks like a file (has a file extension)
    if (uri.match(/\.[a-zA-Z0-9]+$/)) {
        request.uri = uri;
        return request;
    }

    // Handle trailingSlash = true correctly:
    // - If path doesn't end in "/", append "/index.html"
    // - If path already ends in "/", append "index.html"
    if (!uri.endsWith('/')) {
        uri += '/';
    }

    request.uri = uri + 'index.html';
    return request;
}
EOT
}
