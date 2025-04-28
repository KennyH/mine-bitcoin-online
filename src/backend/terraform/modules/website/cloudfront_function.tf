resource "aws_cloudfront_function" "redirect_and_add_index_html" {
  name    = "add-index-html-for-mine-bitcoin-online-frontend-${var.environment}"
  runtime = "cloudfront-js-1.0"
  publish = true

  code = <<EOT
function handler(event) {
    var request = event.request;
    var uri = request.uri;
    var querystring = request.querystring;

    if (!uri.endsWith('/')) {
        var location = uri + "/";
        if (querystring && querystring.length > 0) {
            location += "?" + querystring;
        }

        return {
            statusCode: 301,
            statusDescription: 'Moved Permanently',
            headers: {
                "location": { "value": location }
            }
        };
    }

    request.uri += 'index.html';
    return request;
}
EOT
}
