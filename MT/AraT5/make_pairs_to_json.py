import argparse
import json
import os


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("src_file", type=str)
    parser.add_argument("src_code", type=str)
    parser.add_argument("tar_file", type=str)
    parser.add_argument("tar_code", type=str)
    parser.add_argument("output_file", type=str)
    args = parser.parse_args()

    assert os.path.exists(args.src_file) and os.path.exists(args.tar_file)
    assert args.src_code is not None and args.tar_code is not None

    res = []
    with open(args.src_file) as src, open(args.tar_file) as tar:
        for line1, line2 in zip(src, tar):
            line1 = line1.rstrip().split(" ", 1)[1]
            line2 = line2.rstrip().split(" ", 1)[1]
            res.append(
                {
                    args.src_code: line1,
                    args.tar_code: line2
                }
            )
    json_res = {
        "translation": res
    }

    with open(args.output_file, mode="w+") as fp:
        json.dump(json_res, fp)
    print("Finished!")


if __name__ == '__main__':
    main()
