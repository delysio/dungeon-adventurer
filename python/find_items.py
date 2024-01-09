# Finds objects in level definition files and writes them to arrays in Pascal format.

import glob

def write_table(name, positions):
    return f"{name}: array[0..MAX_LEVEL-1] of byte = ({', '.join(map(str, positions))});"

def find_items(maska, output_file_name):
    MAP_LOCATION_X = []
    MAP_LOCATION_Y = []
    SWORD_LOCATION_X = []
    SWORD_LOCATION_Y = []
    SHIELD_LOCATION_X = []
    SHIELD_LOCATION_Y = []
    TIMER_LOCATION_X = []
    TIMER_LOCATION_Y = []

    files = glob.glob(maska)

    for file in files:
        with open(file, 'r') as f:
            for i, line in enumerate(f, start=1):
                for j, char in enumerate(line, start=1):
                    if char == 'm':
                        MAP_LOCATION_X.append(j - 1)
                        MAP_LOCATION_Y.append(i - 1)
                    elif char == 'w':
                        SWORD_LOCATION_X.append(j - 1)
                        SWORD_LOCATION_Y.append(i - 1)
                    elif char == 's':
                        SHIELD_LOCATION_X.append(j - 1)
                        SHIELD_LOCATION_Y.append(i - 1)
                    elif char == 't':
                        TIMER_LOCATION_X.append(j - 1)
                        TIMER_LOCATION_Y.append(i - 1)

    results = {
        'MAP_LOCATION_X': MAP_LOCATION_X,
        'MAP_LOCATION_Y': MAP_LOCATION_Y,
        'SHIELD_LOCATION_X': SHIELD_LOCATION_X,
        'SHIELD_LOCATION_Y': SHIELD_LOCATION_Y,
        'SWORD_LOCATION_X': SWORD_LOCATION_X,
        'SWORD_LOCATION_Y': SWORD_LOCATION_Y,
        'TIMER_LOCATION_X': TIMER_LOCATION_X,
        'TIMER_LOCATION_Y': TIMER_LOCATION_Y
    }

    with open(output_file_name, 'w') as output_file:
        for key, value in results.items():
            output_file.write(write_table(key, value) + '\n')

# Przykładowe użycie:
file_mask = 'levels/*.dat'
output_file_name = 'level_tables.inc'
find_items(file_mask, output_file_name)
