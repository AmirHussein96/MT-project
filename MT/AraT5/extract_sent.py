# this is to extract the sentences from the files in the format of
# 132614_20170601_110003_13355_A_0011591-0012140 hello
# to an output file, which will only contain the sentence:
# hello

import argparse
import os


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("in_file", type=str, help="input file path")
    parser.add_argument("out_file", type=str, help="output file path")
    args = parser.parse_args()
    return args


def main():
    args = parse_args()
    in_file = args.in_file
    out_file = args.out_file
    assert in_file and os.path.exists(in_file)
    assert out_file and os.path.exists(out_file)

    with open(in_file, mode="r") as in_f, \
            open(out_file, mode="w+") as out_f:
        for line in in_f:
            # remove audio info
            line = line.rstrip().split(" ", 1)[1]
            out_f.write(f"{line}\n")


if __name__ == '__main__':
    main()
