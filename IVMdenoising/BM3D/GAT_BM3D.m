
close all
clear all
warning('off','all')
disp(' ')
addpath('BM3D');
addpath('NoiseEstimationYangTai');
tic

%% DATA LOADING
fileName=('temp.tif')
InfoImage=imfinfo(fileName);
mImage=InfoImage(1).Width;
nImage=InfoImage(1).Height;
frames=length(InfoImage);
bitdepth=InfoImage(1).BitDepth;
z=zeros(nImage,mImage,frames,'double'); %creates empty matrix with same dimensions as image to be read

tifread= Tiff(fileName, 'r');

for ii = 1 : frames         %concatenate each successive tiff to z
    tifread.setDirectory(ii);
    z(:,:,ii)=tifread.read();
end

tifread.close();


% Preallocate variables for Variance Stabilizing Transform and denoising
sigma=zeros(1,frames);
alpha = 1;
g = 0.0;
scale_range = 1;
scale_shift = (1-scale_range)/2;
fz=zeros(nImage,mImage,frames); %preallocates the GAT scaled data
maxzans=zeros(1,frames);
minzans=zeros(1,frames);
sigma_den=zeros(1,frames);
yhat_cfa=zeros(nImage,mImage,frames); %preallocates the denoised data


for i=1:frames

    %% Estimate Noise
    % An implementation of noise estimation according to
    %
    % S.-M. Yang and S.-C. Tai:
    % "Fast and reliable image-noise estimation using a hybrid approach"
    % Journal of Electronic Imaging 19(3), pp. 033007-1--15, 2010.
    %
    % Chris Schwemmer, Universität Erlangen-Nürnberg
    % chris.schwemmer@cs.fau.de
    % https://www5.cs.fau.de/en/our-team/schwemmer-chris/software/index.html

    estframe=z(:,:,i);
    estframeheight=floor(size(estframe,1)/5);
    estframewidth=floor(size(estframe,2)/5);
    estframe=estframe(1:estframeheight*5,1:estframewidth*5);
    peak=max(estframe(:));
    sigma(1,i)=refinednoiseest(estframe,peak);

    
    %% Apply forward variance stabilizing transformation (Generalized Forward Anscombe)
    % Generalized Anscombe VST (J.L. Starck, F. Murtagh, and A. Bijaoui, Image  Processing  and  Data Analysis, Cambridge University Press, Cambridge, 1998)
    % F. Murtagh, J.-L. Starck and A. Bijaoui, "Image restoration with noise suppression using a multiresolution support", Astron. Astrophys.
    % Supplement Series, vol. 112, pp. 179-189, 1995. https://doi.org/10.1117/12.188035
    fz(:,:,i)= 2/alpha * sqrt(max(0,alpha*z(:,:,i) + (3/8)*alpha^2 + sigma(1,i).^2 - alpha*g));

    % Scale the image (BM4D processes inputs in [0,1] range)
    maxzans(1,i)= max(fz(:,:,i),[],'all');
    minzans(1,i)=min(fz(:,:,i),[],'all');
    sigma_den(1,i)=(1/(maxzans(1,i)-minzans(1,i)))*scale_range;
    fz(:,:,i)=(fz(:,:,i)-minzans(1,i))/(maxzans(1,i)-minzans(1,i));


    %% Denoise BM3D
    % K. Dabov, A. Foi, V. Katkovnik and K. Egiazarian, "Image Denoising by Sparse 3-D Transform-Domain Collaborative Filtering," 
    % IEEE Transactions on Image Processing, vol. 16, no. 8, pp. 2080-2095, Aug. 2007, doi: 10.1109/TIP.2007.901238.
    yhat_cfa(:,:,i)=BM3D(fz(:,:,i),sigma_den(1,i), 'np');

    % Scale back to the initial VST range
    yhat_cfa(:,:,i) = (yhat_cfa(:,:,i)-scale_shift)./scale_range;
    yhat_cfa(:,:,i) = (yhat_cfa(:,:,i)*(maxzans(1,i)-minzans(1,i)))+minzans(1,i);


    %% Apply the inverse transformation    % closed-form approximation
    %Mäkitalo M, Foi A. Optimal inversion of the generalized Anscombe transformation for Poisson-Gaussian noise.
    %IEEE Trans Image Process. 2013 Jan;22(1):91-103. doi: 10.1109/TIP.2012.2202675. Epub 2012 Jun 5. PMID: 22692910.
    yhat_cfa(:,:,i) = (yhat_cfa(:,:,i)/2).^2 + 1/4*sqrt(3/2)*yhat_cfa(:,:,i).^-1 - 11/8*yhat_cfa(:,:,i).^-2 + 5/8*sqrt(3/2)*yhat_cfa(:,:,i).^-3 - 1/8 - sigma(1,i).^2;
    yhat_cfa(:,:,i) = max(0,yhat_cfa(:,:,i));
end






%% Save denoised image
if bitdepth==8
    yhat_cfa=uint8(yhat_cfa);
else
    yhat_cfa=uint16(yhat_cfa);
end

for k=1:size(yhat_cfa,3)
    imwrite(yhat_cfa(:,:,k), 'temp_denoised.tif', 'WriteMode' , 'append') ;
end
toc