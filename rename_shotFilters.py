import glob
import os
import threading
import warnings
from argparse import ArgumentParser
from main import *
import cv2
import easyocr
import matplotlib.pyplot as plt
import numpy as np

all_shot_numbers = []

# 顺时针旋转90度
def RotateClockWise90(img):
    trans_img = cv2.transpose(img)
    new_img = cv2.flip(trans_img, 1)
    return new_img


# 逆时针旋转90度
def RotateAntiClockWise90(img):
    trans_img = cv2.transpose(img)
    new_img = cv2.flip(trans_img, 0)
    return new_img

def get_img_id(path, reader):
    file = cv2.imread(path, cv2.CV_8UC1)
    if args.rotate == -1:
        file = RotateAntiClockWise90(file)
    elif args.rotate == 1:
        file = RotateClockWise90(file)

    result = reader.readtext(file)

    numbers = []
    confidences = []
    cnt = 0
    for r in result:
        if r[1].startswith('#') and len(r[1]) > 1:
            cnt += 1
            numbers.append(r[1][1:])
            confidences.append(r[2])
            print(r)

    print(f'=======found {cnt} results.')
    # print(numbers)

    confidences_maxId = np.array(confidences).argmax()

    return file, numbers[confidences_maxId]


def read_thread(imgs, reader):
    for im in imgs:
        file, number = get_img_id(im, reader)
        print(number)
        if len(number) == 0:
            warnings.warn('no numbers detected!', UserWarning)
            continue

        all_shot_numbers.append(number)

        filepath, tempfilename = os.path.split(im)
        filename, extension = os.path.splitext(tempfilename)

        newpath = f'{filepath}/num_{number}{extension}'
        # rewrite the file
        if args.rotate != 0:
            cv2.imwrite(newpath, file)
            os.remove(im)
        else:
            # rename the file
            os.rename(im, newpath)
            print(f'rename to === {newpath}')


def main(dir, threadsnum=3):
    reader = easyocr.Reader(['en'])
    imgs = glob.glob(f'{dir}/IMG*.jpeg')
    mididx = int(len(imgs) / threadsnum) + 1

    ts = []
    for i in range(threadsnum):
        t1 = threading.Thread(target=read_thread, args=(imgs[i * mididx: (i+1)*mididx],reader,), daemon=True)
        t1.start()
        ts.append(t1)

    for t in ts:
        t.join()

    # get all numbers, download pdfs
    start('.'.join(all_shot_numbers), 'auto_download_pdfs')
    # make a success list  for matlab
    # todo something make a success list  for matlab


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('--imgs_path', type=str, default='filter_imgs')
    parser.add_argument('--rotate', type=int, default=0,
                        help='-1 for AntiClockWise90; 0 for nothing; 1 for ClockWise90')
    args = parser.parse_args()

    main(args.imgs_path)





