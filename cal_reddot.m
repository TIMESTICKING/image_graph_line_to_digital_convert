function im_correct = cal_reddot(im, rotate)

%     im = imread('red_dot\IMG_3100.jpeg');
    im = imrotate(im, rotate);
    sensitive = 0.983;
    while true
        [centers,radii]=find_circle(im, sensitive);
        if size(centers, 1) > 1
            sensitive = sensitive - 0.005;
        elseif size(centers, 1) < 1
            sensitive = sensitive + 0.005;
        else
            break;
        end
    end
    
    imshow(im);
    viscircles(centers,radii);
end


function [centers,radii]=find_circle(im, sensitive)
        redim = im(:,:,2);
        se=strel('square',7);     %采用半径为4的矩形作为结构元素
        redim=imopen(redim,se);         %open操作
        im = repmat(redim, [1 1 3]);
        
        [centers,radii] = imfindcircles(im,[110 170],'ObjectPolarity','dark','Sensitivity',sensitive); % 0.983

end




