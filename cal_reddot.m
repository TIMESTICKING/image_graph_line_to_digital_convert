
im = imread('red_dot\IMG_3100.jpeg');
im = imrotate(im, -90);

redim = im(:,:,2);
se=strel('square',4);     %采用半径为4的矩形作为结构元素
redim=imopen(redim,se);         %open操作
im = repmat(redim, [1 1 3]);
% thresh = graythresh(redim);%二值化阈值
% redim=im2bw(redim,thresh);%二值化

[centers,radii] = imfindcircles(im,[110 170],'ObjectPolarity','dark','Sensitivity',0.982);
imshow(im);
viscircles(centers,radii);
