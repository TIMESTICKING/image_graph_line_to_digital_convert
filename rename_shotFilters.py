import glob
import os
import threading

import cv2
import easyocr
import numpy as np


def get_img_id(path, reader):
    file = cv2.imread(path,cv2.CV_8UC1)

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
    print(numbers)

    confidences_maxId = np.array(confidences).argmax()

    return numbers[confidences_maxId]


def read_thread(imgs, reader):
    reader = easyocr.Reader(['en'])
    for im in imgs:
        number = get_img_id(im, reader)
        print(number)


def main(dir):
    imgs = glob.glob(f'{dir}/*.jpeg')
    mididx = int(len(imgs) / 2)

    t1 = threading.Thread(target=read_thread, args=(imgs[:mididx],))
    t1.start()
    t2 = threading.Thread(target=read_thread, args=(imgs[mididx:],))
    t2.start()

    t1.join()
    t2.join()

if __name__ == '__main__':
    main('filter_imgs')





