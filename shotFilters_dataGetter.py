import glob
import os
import threading
import time
import warnings
from argparse import ArgumentParser

import pandas as pd

# from main import *
import scipy.io as sio
import cv2
import easyocr
import matplotlib.pyplot as plt
import numpy as np
import matlab.engine
import matlab

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
    # file = cv2.imread(path)
    one_channel = cv2.imread(path, cv2.CV_8UC1)
    # resize to 1/3 too speeder the matlab data trans
    width = int(one_channel.shape[1] / 3)
    height = int(one_channel.shape[0] / 3)
    dim = (width, height)
    one_channel = cv2.resize(one_channel, dim)

    if args.rotate == -1:
        one_channel = RotateAntiClockWise90(one_channel)
    elif args.rotate == 1:
        one_channel = RotateClockWise90(one_channel)

    result = reader.readtext(one_channel)

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

    return one_channel, numbers[confidences_maxId]

# from Online_breakpoint_debug import *
# myd = Online_breakpoint_debug('pp')
# myd.start()


def get_plot_fromIMG(imgpath, root, eng):
    args = {
        'min_x':340.,
        'max_x':740.,
        'min_y':0.,
        'max_y':100.,
        'step_x' : 40,
        'step_y' : 10,
        'thresh_binary' : 0.55,
        'find_corner' : 0,
        'mark_points' : matlab.double([[0.5,614.5],[618.5,0.5]])
    }
    [x, y, viz] = eng.imgPlot2digital(imgpath, matlab.double(list(range(380, 721))), 'imclose', args, nargout=3)
    eng.saveas(viz, f'{root}/xy.jpg', nargout=0)
    eng.close('all', 'hidden')
    x = np.array(x[0])
    y = np.array(y[0])
    # print(x)
    # print(y)
    # plt.plot(x, y)
    # plt.savefig(f'{root}/xy.jpg')
    tb = pd.DataFrame(np.row_stack([x.T, y.T]))
    tb.to_excel(f'{root}/xy.xlsx', index=False, header=False)



leftup = sio.loadmat('red_dot/leftup.mat')
rightbottom = sio.loadmat('red_dot/rightbottom.mat')
def match_temp(img, temp, smallscale, offset_r, offset_c):
    temp = np.asarray(temp, dtype=np.float32)
    # w, h = temp.shape[::-1]
    # temp = cv2.resize(temp, (int(w/smallscale), int(h/smallscale)))

    res = cv2.matchTemplate(img, temp, cv2.TM_CCOEFF)
    min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(res)
    top_left = max_loc

    # plt.imshow(img)
    # plt.scatter(top_left[0], top_left[1])
    # plt.show()

    return np.array(top_left) + np.array([
        int(offset_r[0][0] / smallscale),
        int(offset_c[0][0] / smallscale)])


def locate_grid(img, filename, eng):
    scale_time = float(eng.cal_reddot(matlab.uint8(img.tolist()), 0))
    newimg = np.asarray(cv2.imread(filename, cv2.CV_8UC1), dtype=np.float32)
    w,h = newimg.shape[::-1]
    newimg = cv2.resize(newimg, (int(w * scale_time), int(h * scale_time)))

    # todo template search
    # leftup
    leftup_p = match_temp(newimg, leftup['leftup'], 1, leftup['offset_row'], leftup['offset_col'])
    # rightbottom
    rightbottom_p = match_temp(newimg, rightbottom['rightbottom'], 1, rightbottom['offset_row'], rightbottom['offset_col'])

    newimg = newimg[leftup_p[1]:rightbottom_p[1], leftup_p[0]:rightbottom_p[0]]

    return newimg[:,:,np.newaxis].repeat(3, axis=2)


def read_thread(args, imgs, reader):
    print('this thread has ', imgs)
    eng = matlab.engine.start_matlab()

    for im in imgs:
        file, number = get_img_id(im, reader)
        print(number)
        if len(number) == 0:
            warnings.warn('no numbers detected!', UserWarning)
            continue

        all_shot_numbers.append(number)

        filepath, tempfilename = os.path.split(im)
        filename, extension = os.path.splitext(tempfilename)

        root = f'{args.output_dir}/num_{number}/'
        newpath = f'{root}/num_{number}{extension}'

        # locate the grid, use red_dot and template search
        girded_img = locate_grid(file, im, eng)
        # shrink the 1 channel img again for preview
        shrinkimg = cv2.resize(file, (200, 200))

        # rewrite the file
        if not os.path.exists(root):
            os.makedirs(root)
        cv2.imwrite(newpath, girded_img)
        cv2.imwrite(f'{root}/prev.jpg', shrinkimg)

        # get line
        get_plot_fromIMG(newpath, root, eng)

    eng.quit()


def mainf(margs, threadsnum=3):
    reader = easyocr.Reader(['en'])
    imgs = glob.glob(f'{margs.imgs_path}/IMG*.jpeg')
    mididx = int(len(imgs) / threadsnum) + 1

    ts = []
    for i in range(threadsnum):
        t1 = threading.Thread(target=read_thread, args=(margs, imgs[i * mididx: (i+1)*mididx],reader,))
        t1.start()
        time.sleep(0.3)
        ts.append(t1)

    # for t in ts:
    #     t.join()




if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('--imgs_path', type=str, default='filter_imgs')
    parser.add_argument('--output_dir', type=str, default='output_t')
    parser.add_argument('--rotate', type=int, default=0,
                        help='-1 for AntiClockWise90; 0 for nothing; 1 for ClockWise90')
    args = parser.parse_args()


    mainf(args, 3)





