function [dig_x, dig_y, viz] = imgPlot2digital(imgpath)
    % 提取图片中的曲线数据
    clc;close all
    %% parameters setting
    global min_x max_x min_y max_y step_x step_y
    min_x=340;%min of x axis
    max_x=740;%max of x axis
    min_y=0;%min of y axis
    max_y=100;%max of y axis
    
    step_x = 40;% step of x axis
    step_y = 10;% step of y axis
    
    windowSize = 9; %smooth filter size
    xwant = [min_x + 20 : max_x - 20]; % the range of x-axis that u want
    
    %% 图片与曲线间的定标
    im=imread(imgpath);%读入图片(替换成需要提取曲线的图片)
    im=rgb2gray(im);%灰度变化
    thresh = graythresh(im);%二值化阈值
    im=im2bw(im,0.01);%二值化
    
    % filter lines
    im=reduceLines(im);
    
    set(0,'defaultfigurecolor','w')
    imshow(im)%显示图片
    [y,x]=find(im==0);%找出图形中的“黑点”的坐标。该坐标是一维数据。
    y=max(y)-y;%将屏幕坐标转换为右手系笛卡尔坐标
    y=fliplr(y);%fliplr()——左右翻转数组
    plot(x,y,'r.','Markersize', 2);
    disp('click to mark 2 points (left-up, right-bottom) in the figure to location the axis');
    [Xx,Yy]=ginput(2);%Xx,Yy——指实际坐标框的两个顶点
    x=(x-Xx(1))*(max_x-min_x)/(Xx(2)-Xx(1))+min_x;
    y=(y-Yy(1))*(min_y-max_y)/(Yy(2)-Yy(1))+max_y;
    oldx = x;oldy = y;
    % reduce xy
    [x,y]=reduce_xy(x, y);
    [x,y]= de_noiser(x,y);
    
    plot(x,y,'r.','Markersize', 2);
    axis([min_x,max_x,min_y,max_y])%根据输入设置坐标范围
    title('由原图片得到的未处理散点图')
    
    %% 将散点转换为可用的曲线
    %需处理的问题与解决思路
    %(1)散点图中可能一个x对应好几个y <---> 保留mean()-std()到mean()+std()之间的y值 并取平均处理
    %(2)曲线的最前端和最后段干扰较大 <---> 去掉曲线整体的前(如5%)和后5%
    %(3)曲线的最顶端和最底段干扰较大 <---> 去掉曲线整体的上10%和下10%
    
    %参数预设
    rate_x=0.01;%曲线的最前端和最后段删除比例
    rate_y=0.01;%曲线的最顶端和最底段删除比例
    
    [x_uni,index_x_uni]=unique(x);%找出有多少个不同的x坐标
    
    x_uni(1:floor(length(x_uni)*rate_x))=[];%除去前rate_x(如5%)的x坐标
    x_uni(floor(length(x_uni)*(1-rate_x)):end)=[];%除去后rate_x的x坐标
    index_x_uni(1:floor(length(index_x_uni)*rate_x))=[];%除去前rate_x的x坐标
    index_x_uni(floor(length(index_x_uni)*(1-rate_x)):end)=[];%除去后rate_x的x坐标
    
    [mxu,~]=size(x_uni);
    [mx,~]=size(x);
    for ii=1:mxu
        if ii==mxu
            ytemp=y(index_x_uni(ii):mx);
        else
            ytemp=y(index_x_uni(ii):index_x_uni(ii+1));
        end
        %删除方差过大的异常点
        threshold1=mean(ytemp)-std(ytemp);
        threshold2=mean(ytemp)+std(ytemp);
        ytemp(find(ytemp<threshold1))=[];%删除同一个x对应的一段y中的异常点
        ytemp(find(ytemp>threshold2))=[];
        %删除距顶端和底端较近的点
        thresholdy=(max_y-min_y)*rate_y;%y坐标向阈值
        ytemp(find(ytemp>max_y-thresholdy))=[];%删除y轴向距离顶端与底端距离小于rate_y的坐标
        ytemp(find(ytemp<min_y+thresholdy))=[];
        %剩下的y求均值
        y_uni(ii)=mean(ytemp);
    end
    %此时很多x_uni点处对应的y_uni为空,即NAN,要进一步删去这些空点
    x_uni(find(isnan(y_uni)))=[];
    y_uni(find(isnan(y_uni)))=[];
    %画图
    figure,plot(x_uni,y_uni),title('经处理后得到的扫描曲线')
    axis([min_x,max_x,min_y,max_y])%根据输入设置坐标范围
    % 将最终提取到的x与y数据保存
    curve_val(1,:)=x_uni';
    curve_val(2,:)=y_uni;
    %% 对提取出的数据进行拟合(按实际情况进行修改)
    % [p,s]=polyfit(curve_val(1,:),curve_val(2,:),6);%多项式拟合(为避免龙格库塔,多项式拟合阶数不宜太高)
    % [y_fit,DELTA]=polyval(p,x_uni,s);%求拟合后多项式在x_uni对应的y_fit值
    % figure,plot(x_uni,y_fit),title('拟合后的曲线')
    % axis([min_x,max_x,min_y,max_y])%根据输入设置坐标范围
    
    %% 插值
    y3=interp1(curve_val(1,:),curve_val(2,:),xwant);  
    % filter smooth
    b = (1/windowSize)*ones(1,windowSize);
    ywant = imfilter(y3,b,'replicate');
    viz = figure(189);
    plot(xwant,ywant),title('filtered拟合后的曲线')

    dig_x = xwant; dig_y = ywant;
end


function im=reduceLines(im)
    % filter lines
    zerosf = [0 0 0 0 0 0 0 0];
    onesf = [1 1 1 1 1 1 1 1];
    hv= [onesf;zerosf;-onesf];
    dx=imfilter(im,hv,'replicate');      %求横边缘fspecial('sobel')
    hh=hv';
    dy=imfilter(im,hh,'replicate');      %求竖边缘
    im=im - dx - dy;   
end

function [x,y]=reduce_xy(x, y)
    global min_x max_x min_y max_y step_x step_y
    
    mxs = [min_x:step_x:max_x];
    idxs = ((mxs(1)-5) > x) | (x > (mxs(end)+5));
    x(idxs) = [];
    y(idxs) = [];
    for mx=mxs
        idxs = ((mx-5) < x) & (x < (mx+5));
        x(idxs) = [];
        y(idxs) = [];
    end

    mys = [min_y:step_y:max_y];
    idxs = ((mys(1)-1.3) > y) | (y > (mys(end)+1.3));
    x(idxs) = [];
    y(idxs) = [];
    for my=mys
        idxs = ((my-1.3) < y) & (y < (my+1.3));
        x(idxs) = [];
        y(idxs) = [];
    end
end

function [x,y]= de_noiser_per(x,y)

    meany = mean(y);
    stdy = std(y);

    idx = (y > (meany + 3*stdy) | y < (meany - 3*stdy));
    x(idx) = [];
    y(idx) = [];

end


function [nx,ny]= de_noiser(x,y)
    step = 80;
    morestep = 55;

    slices = [1:step:size(x,1)];
    nx = [];
    ny = [];
    for slc=slices
        if slc+step + morestep > size(x,1)
            [rx,ry] = de_noiser_per(x(slc:end), y(slc:end));
        else
            [rx,ry] = de_noiser_per(x(slc:slc+step + morestep), y(slc:slc+step + morestep));
        end
        nx = [nx ; rx];
        ny = [ny ; ry];
    end

end


















