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
        expected_files = ['baked_mesh.usda']
        
    else:
        print("type 2")
        expected_files = ['baked_mesh.usdz'] 
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
    output_path_variable = '/Users/ace20/dermaphonePython/Dermaphone/' + output_folder_path 
    input_path_variable = '/Users/ace20/dermaphonePython/Dermaphone/' + upload_folder_path

    command = ['./HelloPhotogrammetry', input_path_variable, output_path_variable]
    success, error = run_process(command=command, cwd='/Users/ace20/dermaphonePython/HelloPhotogrammetry 2024-05-13 23-05-06/Products/usr/local/bin', output_folder=output_folder_path, type=1)
    if not success:
        print("stopped here")
        return jsonify({'error': 'Failed to process images', 'details': error}), 500
    if success:
        
        outputfile = '/Users/ace20/dermaphonePython/Dermaphone/' + output_folder_path + '/baked_mesh.usda'
        print(outputfile)
        # Define the directory where usd.command is located
        directory = '/Applications/usdpython/'

        # Path for the temporary shell script
        script_path = './temp_script.command'


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
        full_path = "/Applications/usdpython/temp_script.command"
        print(full_path)
        # Write the script to the file
        with open(full_path, 'w') as script_file:
            print("check here for script file")
            script_file.write(script_content)

        # Make the script executable
        os.chmod(full_path, 0o755)

        # Execute the script
        command = ['./temp_script.command']
        try:
            success, error = run_process(command=command,cwd='/Applications/usdpython',output_folder=output_folder_path,type=2)
            if not success:
                print("stopped here")
                return jsonify({'error': 'Failed to convert file', 'details': error}), 500
            if success:
                print("success")
                usdzfile = output_folder_path + '/baked_mesh.usdz'
                return jsonify({'success': 'converted file', 'details': success}), 200
        except Exception as e:
            print(f"An error occurred when trying to run the script: {e}")
        return jsonify({'error': 'Failed to convert file', 'details': error}), 500
        


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8000)
