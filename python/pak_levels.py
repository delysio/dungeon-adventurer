# Compresses all .cut files using apultra.exe

import os

def process_files(input_dir):

    levels_dir = os.path.join(input_dir, "levels")
    if not os.path.exists(levels_dir) or not os.path.isdir(levels_dir):
        print(f"Error: folder 'levels' does not exist in {input_dir}")
        return

    remove_pak_files(levels_dir)

    for file_name in os.listdir(levels_dir):
        if file_name.endswith(".cut"):
            cut_file_path = os.path.join(levels_dir, file_name)
            pak_file_path = os.path.splitext(cut_file_path)[0] + ".pak"

            execute_apultra(cut_file_path, pak_file_path)

def remove_pak_files(directory):

    for file_name in os.listdir(directory):
        if file_name.endswith(".pak"):
            file_path = os.path.join(directory, file_name)
            os.remove(file_path)
            print(f"Removed: {file_path}")

def execute_apultra(input_file, output_file):
    apultra_exe = "apultra.exe"

    if os.path.exists(apultra_exe):
        command = f"{apultra_exe} {input_file} {output_file}"
        os.system(command)
        print(f"Processed: {input_file}")
    else:
        print("Error: apultra.exe does not exist.")

if __name__ == "__main__":
    input_directory = "."
    process_files(input_directory)
