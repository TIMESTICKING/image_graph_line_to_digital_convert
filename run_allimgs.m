
imgsf = dir('filter_imgs\*.jpeg');
output_folder = './outputs/';


if ~exist("output_folder", "dir")
    mkdir(output_folder);
end


args.min_x=360;%min of x axis
args.max_x=760;%max of x axis
args.min_y=0;%min of y axis
args.max_y=100;%max of y axis
args.step_x = 20;% step of x axis
args.step_y = 10;% step of y axis
args.thresh_binary = 0.3;
args.mark_points = [[0;350], [140;0]]; %mark 2 points [[x1;x2], [y1;y2]] or []


for imf=imgsf'
    [x,y,viz]=imgPlot2digital([imf.folder '/' imf.name], [380:1:720], 'imclose', args);

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



