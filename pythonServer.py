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

def run_process(command, cwd, output_folder, type):
    # Start the subprocess
    process = subprocess.Popen(command, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    # Monitor the output
    while True:
        output = process.stdout.readline()
        if output == '' and process.poll() is not None:
            break
        if output:
            print(output.strip())
    process.wait()  # Ensure the process has finished

    # Check for errors
    if process.returncode != 0:
        errors = process.stderr.read()
        print("Errors:", errors.strip())
        return False, errors

    # Verify output files
    files_created = verify_output_files(output_folder,type)
    return files_created, None

def verify_output_files(output_folder, type):
    if type == 1:
        print("check here")
        expected_files = ['baked_mesh.usda']
        
    else:
        print("type 2")
        expected_files = ['baked_mesh.usdz']  # List expected filenames or patterns
    files = os.listdir(output_folder)
    return all(file in files for file in expected_files)


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
    #command = 'cd /Users/ace20/dermaphonePython/HelloPhotogrammetry 2024-05-13 23-05-06/Products/usr/local/bin && ./HelloPhotogrammetry Users/ace20/Downloads/Skin5 /Users/ace20/dermaphonePython/Dermaphone/test4'
    # Option 1: With `./`
    output_path_variable = '/Users/ace20/dermaphonePython/Dermaphone/' + output_folder_path 
    input_path_variable = '/Users/ace20/dermaphonePython/Dermaphone/' + upload_folder_path

    command = ['./HelloPhotogrammetry', input_path_variable, output_path_variable]
    success, error = run_process(command=command, cwd='/Users/ace20/dermaphonePython/HelloPhotogrammetry 2024-05-13 23-05-06/Products/usr/local/bin', output_folder=output_folder_path, type=1)
    #subprocess.check_call(command, cwd='/Users/ace20/dermaphonePython/HelloPhotogrammetry 2024-05-13 23-05-06/Products/usr/local/bin')
  #  return jsonify({'success': f'{senderName} - {len(image_uploads)} images saved.'}), 200
    if not success:
        print("stopped here")
        return jsonify({'error': 'Failed to process images', 'details': error}), 500
    if success:
        
        outputfile = '/Users/ace20/dermaphonePython/Dermaphone/' + output_folder_path + '/baked_mesh.usda'
        print(outputfile)
        # Define the directory where usd.command is located
        directory = '/Applications/usdpython/'

        # Path for the temporary shell script
        #script_path = '.' + os.path.join(directory, 'temp_script.sh')
        script_path = './temp_script.command'# + os.path.join(directory, 'temp_script.sh')


        # Script content that uses usd.command
        script_content = f"""
        #!/bin/sh
        echo "hi"
        """
        base_path = '/Applications/usdpython'
        script_content = f"""#!/bin/sh
        BASEPATH="{base_path}"
        export PATH=$PATH:$BASEPATH/USD:$PATH:$BASEPATH/usdzconvert
        export PYTHONPATH=$PYTHONPATH:$BASEPATH/USD/lib/python

        # uncomment to set the PYTHONPATH to FBX Bindings here:
        export PYTHONPATH=$PYTHONPATH:"/Applications/Autodesk/FBX Python SDK/2020.2.1/lib/Python37_x64"

        if [[ $PYTHONPATH == *"FBX"* ]]; then
            :
        else 
            echo "For FBX support, edit PYTHONPATH in this file (usd.command) or your shell configuration file"
        fi

        #$SHELL
        usdzconvert {outputfile} -copytextures
        exit
        """
        print(f"Script path: {script_path}")

       # print(f"Permissions: {oct(os.stat(script_path).st_mode)}")

        directory1 = os.path.dirname(script_path)
        full_path = "/Applications/usdpython/temp_script.command"
        print(directory1)
        print(full_path)
        # Ensure directory exists
        if not os.path.exists(directory1):
            print("hey")
            os.makedirs(directory1)
        # Write the script to the file
        with open(full_path, 'w') as script_file:
            print("check here for script file")
            script_file.write(script_content)

        # Make the script executable
        os.chmod(full_path, 0o755)

        # Execute the script
        print("check here")
        command = ['./temp_script.command']
       # command = ['./USD.Command']
        try:
           # subprocess.run(['./temp_script.sh'],cwd='/Applications/usdpython/')
            success, error = run_process(command=command,cwd='/Applications/usdpython',output_folder=output_folder_path,type=2)
           # result = subprocess.run([script_path], cwd=directory, text=True, capture_output=True)
           # if result.returncode != 0:
            if not success:
                print("stopped here")
                return jsonify({'error': 'Failed to convert file', 'details': error}), 500
            if success:
                print("success")
                return jsonify({'success': 'converted file', 'details': success}), 200
            #    print("Error running script:", result.stderr)
            #else:
             #   print("Script output:", result.stdout)
        except Exception as e:
            print(f"An error occurred when trying to run the script: {e}")
        
        #command = ['./usdzconvert', outputfile, '-copytextures']
        
        #success, error = run_process([script_path], cwd='/Applications/usdpython', output_folder=output_folder_path, type=2)
        # Optionally, clean up the script file after execution
        # os.remove(script_path)
        usdzfile = output_folder_path + '/baked_mesh.usdz'
        # Output results
  #      if result.returncode == 0:
  #          print("Success:", result.stdout)
   #         return jsonify({'success': 'successfully converted file'}), 200
    #    else:
     #       print("Error:", result.stderr)
      #      return jsonify({'error': 'Failed to process images', 'details': result.stderr}), 700


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8000)
