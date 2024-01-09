# Removes newline characters (\n) from all level files (ending in .dat) and saves them with a .cut extension.

import os

source_dir = 'levels'
target_dir = 'levels'
extension = '.dat'
new_extension = '.cut'

for filename in os.listdir(target_dir):
    if filename.endswith(new_extension):
        file_path = os.path.join(target_dir, filename)
        os.remove(file_path)
        print(f"Removed: {file_path}")

for filename in os.listdir(source_dir):
    if filename.endswith(extension):
        input_file_path = os.path.join(source_dir, filename)
        output_file_path = os.path.join(target_dir, filename.replace(extension, new_extension))

        print(f"Processing: {input_file_path}")

        with open(input_file_path, 'r') as input_file, open(output_file_path, 'w') as output_file:
            for line in input_file:

                output_file.write(line.rstrip('\n'))

        print(f"File processed: {output_file_path}")
