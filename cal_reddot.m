function scale_time = cal_reddot(im, rotate)
    close all
%     im = imread('red_dot\IMG_3100.jpeg');
    im = imrotate(im, rotate);
    imshow(im);hold on


    sensitive = 0.983;
    [h,w] = size(im);
    redim = im(int64(h/2):end, :);
    while true
        [centers,radii]=find_circle(redim, sensitive);
        if size(centers, 1) > 1
            sensitive = sensitive - 0.005;
        elseif size(centers, 1) < 1
            sensitive = sensitive + 0.005;
        else
            centers(2) = centers(2) + h/2;
            break;
        end
    end
    
    imshow(im);
    viscircles(centers,radii);

    standard_radii = 1.426964514776080e+02 / 3;
    scale_time = standard_radii / radii;
%     im_correct = imresize(im, scale_time);
%     im_correct = im2bw(im_correct,0.4196);%二值化
%     se=strel('square',2);     %采用半径为4的矩形作为结构元素
%     im_correct=imopen(im_correct,se);
end

% template left up point:   x,y=1168 1719   x,y=1265 1766
% template right bottom:    x,y=1752 2304   x,y=1852 2373


function [centers,radii]=find_circle(im, sensitive)
        redim = im;
        se=strel('square',7);     %采用半径为4的矩形作为结构元素
        redim=imopen(redim,se);         %open操作
        im = repmat(redim, [1 1 3]);
        
        [centers,radii] = imfindcircles(im,[35 60 ],'ObjectPolarity','dark','Sensitivity',sensitive); % 0.983

end




