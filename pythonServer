from http.server import BaseHTTPRequestHandler, HTTPServer

# Define the request handler class
class MyRequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # Handle GET requests
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(b"Hello, world! This is the response from your server.")

# Define the server address and port
server_address = ('', 8002)

# Create the HTTP server
httpd = HTTPServer(server_address, MyRequestHandler)

# Start the server
print('Starting server...')
httpd.serve_forever()
