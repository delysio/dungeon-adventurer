# Breaks ASCII-formatted text into text in lines of 40 bytes, padded with spaces.

import sys

def break_text(input_file, output_file):
    with open(input_file, 'r') as input_file:
        lines = input_file.readlines()

    output_lines = []
    for line in lines:
        words = line.split()
        current_line = ''
        for word in words:
            if len(current_line) + len(word) + 1 <= 40:
                current_line += word + ' '
            else:
                output_lines.append(current_line.strip().ljust(40))
                current_line = word + ' '

        if current_line:
            output_lines.append(current_line.strip().ljust(40))

    with open(output_file, 'w') as output_file:
        output_file.write('\n'.join(output_lines))

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python break_text.py <input_file> <output file>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    break_text(input_file, output_file)
