# Converts a text file from ASCII format to Atari Internal and removes line endings (\n).

import os

# Directory with ATASCII files
input_directory = "graphics"

# Conversion from internal codes to ATASCII code
def itoa(b):
    u = b & 128
    l = b & 127
    if l < 96:
        l = (l + 32) % 96
    return u | l

# Conversion from ATASCII/ASCII to internal code
def atoi(b):
    return itoa(itoa(b))

# Convert input string
def process_string(input_str):
    result = ""
    for char in input_str:
        char_code = ord(char)
        transformed_code = atoi(char_code)
        result += chr(transformed_code)
    return result

# Save converted file
def save_to_file(output_str, input_filename, output_directory="graphics"):

    output_filename = os.path.join(output_directory, f"{os.path.splitext(os.path.basename(input_filename))[0]}.dat")
    with open(output_filename, "w") as file:
        file.write(output_str)

# Process all files with asc extension
for filename in os.listdir(input_directory):
    if filename.endswith(".asc"):
        input_filepath = os.path.join(input_directory, filename)

        with open(input_filepath, "r") as input_file:
            input_string = input_file.read().replace("\n", "")

        output_string = process_string(input_string)

        save_to_file(output_string, input_filepath)

        print(f"Processed {filename} and saved result to output directory.")
