
imgsf = dir('filter_imgs\*.jpeg');
output_folder = './outputs_t/';


if ~exist("output_folder", "dir")
    mkdir(output_folder);
end


for imf=imgsf'
    [x,y,viz]=imgPlot2digital([imf.folder '/' imf.name], [380:1:720], 'imclose', 1);

    tt = split(imf.name, '.');
    imgname = tt{1};
    im_out_dir = [output_folder imgname '/'];
    if ~exist("im_out_dir", "dir")
        mkdir(im_out_dir);
    end
%     save([im_out_dir 'xy.mat'], "x", "y");
    xlswrite([im_out_dir 'xy.xlsx'], [x' y']);
    saveas(viz, [im_out_dir 'viz.jpg']);
end



