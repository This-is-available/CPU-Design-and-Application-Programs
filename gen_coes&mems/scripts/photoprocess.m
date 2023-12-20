image=imread('F:\Vivado\mpro.jpg');
%image=image(:,:,1);
%C[:,:,2];
[col, row, color]=size(image);
fid=fopen('F:\Vivado\mpro.mem','w');
for i=1:col
    for j=1:row
        for k=1:color
            fprintf(fid,'%x',floor(double(image(i,j,k))/16));
            %C[:,:,2]=floor(double(image(i,j,k))/16);
        end
        fprintf(fid,'\n');
    end
end
fclose(fid);

%floor(double(image(i,j,k))/16)