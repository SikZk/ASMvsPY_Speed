import os
from random import randint
import argparse
import time
import subprocess

def main():
    # Parse the arguments
    parser = argparse.ArgumentParser(description='Process some arguments.')
    parser.add_argument('-number', type=int, help='Number of elements in the data set.')
    args = parser.parse_args()
    number_of_data = args.number

    # Create a data set with n elements
    data = create_data_set(number_of_data)
    write_data_to_file(data, "./test.txt")

    # Measure the time of Python implementation
    python_time = measure_time_of_os_command_execution("python3 python/a.py")

    # Measure the time of Assembly implementation
    assembly_time = measure_time_of_os_command_execution("./assembly/binaryheap")


    print("\n\nPython time for binary heap: %f ms" % python_time)
    print("Assembly time for binary heap: %f ms" % assembly_time)



def create_data_set(n):
    # If n is greater than 1,000,000, create a data set with 1,000,000 elements for safety reasons
    if n>1000000:
        return [randint(0, 1000000) for _ in range(1000000)]
    # If n is less than 1,000, create a data set with 1,000 elements for testing purposes
    elif n<1000:
        return [randint(0, 1000) for _ in range(1000)]
    return [randint(0, n) for _ in range(n)]

def write_data_to_file(data, filename):
    with open(filename, 'w') as f:
        for i in range(len(data)):
            if i == len(data) - 1:
                f.write(str(data[i]))
            else:
                f.write(str(data[i]) + '\n')

def measure_time_of_os_command_execution(command):
    start = time.time()
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    os.system(command)
    end = time.time()
    return (end - start) * 1000

if __name__ == "__main__":
    main()