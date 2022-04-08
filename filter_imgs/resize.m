
fs = dir('*.jpeg');

for f=fs'
    img = imread(f.name);
    img = imrotate(img, -90);
    img = img(1539:2565, 795:1893, :);

    imwrite(img,f.name);
end



