'''from http.server import BaseHTTPRequestHandler, HTTPServer
import os

# Define the request handler class
class MyRequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # Handle GET requests
        if self.path == '/upload':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            print("get upload")
            self.wfile.write(b"Hello, world! This is the response from your server for the /upload path.")
        else:
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            print("error get")
            self.wfile.write(b"Hello, world! This is the response from your server.")
    def do_POST(self):
        # Handle POST requests (file uploads)
        if self.path == '/upload':
            #print("post upload")
            #content_length = int(self.headers['Content-Length'])
            
            #post_data = self.rfile.read(content_length)
            # Process the uploaded file data
            # You can save the file or perform any other necessary processing here
            
            #self.send_response(200)
            #self.send_header('Content-type', 'text/html')
            #self.end_headers()
            #self.wfile.write(b"File uploaded successfully!") # Confirmation message

            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            print(post_data)
            # Split the request data by the boundary between each image
            boundary = post_data.split(b'\r\n')[0]
            image_data = post_data.split(boundary)[1:-1]  # Exclude the first and last empty elements

            # Iterate over each image data and save it to the server's file system
            for image in image_data:
                # Extract the filename from the content-disposition header
                filename_start = image.find(b'filename="') + len(b'filename="')
                filename_end = image.find(b'"', filename_start)
                filename = image[filename_start:filename_end].decode()

                # Extract the image data
                data_start = image.find(b'\r\n\r\n') + len(b'\r\n\r\n')
                image_data = image[data_start:]

                # Save the image to the server's file system
               # with open(filename, 'wb') as f:
                #    f.write(image_data)
                # Specify the folder path and filename
                folder_path = '/images'
                filename = 'your_file_name.jpg'

                # Combine folder path and filename to create the full file path
                full_file_path = os.path.join(folder_path, filename)

                # Write data to the specified file
                with open(full_file_path, 'wb') as f:
                    f.write(image_data)

            # Send a response to the client indicating success
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(b"Files uploaded successfully!") # Confirmation message
            
        else:
            self.send_response(404)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(b"404 Not Found")
            print("error post")

# Define the server address and port
server_address = ('', 8002)

# Create the HTTP server
httpd = HTTPServer(server_address, MyRequestHandler)

# Start the server
print('Starting server...')
httpd.serve_forever()
'''

import uuid
from flask import Flask, request, jsonify
import os
from werkzeug.utils import secure_filename
import subprocess


app = Flask(__name__)
UPLOAD_FOLDER = 'images'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
OUTPUT_FOLDER = 'output'
app.config['OUTPUT_FOLDER'] = OUTPUT_FOLDER
def create_upload_folder():
    if not os.path.exists(UPLOAD_FOLDER):
        os.makedirs(UPLOAD_FOLDER)

def create_unique_upload_folder():
    unique_id = str(uuid.uuid4())
    upload_folder_path = os.path.join(UPLOAD_FOLDER, unique_id)
    os.makedirs(upload_folder_path)
    return upload_folder_path

def create_unique_output_folder():
    unique_id = str(uuid.uuid4())
    output_folder_path = os.path.join(OUTPUT_FOLDER, unique_id)
    os.makedirs(output_folder_path)
    return output_folder_path



@app.route('/upload', methods=['POST'])
def upload():
    print(request.files)
    senderName = request.form.get('senderName')

    if senderName is None or senderName == '':
        return jsonify({'error': 'No senderName sent.'}), 500

    if 'imageUploads' not in request.files:
        return jsonify({'error': f'{senderName} - Image uploads not found.'}), 500

    image_uploads = request.files.getlist('imageUploads')
    if len(image_uploads) == 0:
        return jsonify({'error': f'{senderName} - No images sent.'}), 500
    
    upload_folder_path = create_unique_upload_folder()
    output_folder_path = create_unique_output_folder()
    saved_files = []
    for img in image_uploads:
        filename = secure_filename(img.filename)
        img.save(os.path.join(upload_folder_path, filename))
        saved_files.append(filename)

    print(output_folder_path)
    #command = 'cd /Users/ace20/dermaphonePython/HelloPhotogrammetry\ 2024-05-13\ 23-05-06/Products/usr/local/bin && ./HelloPhotogrammetry {upload_folder_path} {output_folder_path}'
    command = 'cd /Users/ace20/dermaphonePython/HelloPhotogrammetry 2024-05-13 23-05-06/Products/usr/local/bin && ./HelloPhotogrammetry Users/ace20/Downloads/Skin5 /Users/ace20/dermaphonePython/Dermaphone/test4'
    # Option 1: With `./`
    output_path_variable = '/Users/ace20/dermaphonePython/Dermaphone/' + output_folder_path 
    input_path_variable = '/Users/ace20/dermaphonePython/Dermaphone/' + upload_folder_path

    command = ['./HelloPhotogrammetry', input_path_variable, output_path_variable]
    subprocess.check_call(command, cwd='/Users/ace20/dermaphonePython/HelloPhotogrammetry 2024-05-13 23-05-06/Products/usr/local/bin')
    return jsonify({'success': f'{senderName} - {len(image_uploads)} images saved.'}), 200


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8000)
