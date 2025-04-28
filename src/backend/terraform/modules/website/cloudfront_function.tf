resource "aws_cloudfront_function" "add_index_html" {
  name    = "add-index-html-for-mine-bitcoin-online-frontend-${var.environment}"
  runtime = "cloudfront-js-1.0"
  publish = true

  code = <<EOT
function handler(event) {
    var request = event.request;
    var uri = request.uri;

    if (uri.endsWith('/')) {
        request.uri += 'index.html';
    }

    return request;
}
EOT
}
