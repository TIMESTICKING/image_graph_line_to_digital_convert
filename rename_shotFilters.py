import os
import cv2
import easyocr


def get_img_id(path):
    reader = easyocr.Reader(['en'])
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

    return '.'.join(numbers)



if __name__ == '__main__':
    print(get_img_id('./filter_imgs/IMG_3074.jpeg'))





