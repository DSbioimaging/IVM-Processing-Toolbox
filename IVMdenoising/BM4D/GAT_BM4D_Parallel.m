
close all
clear all
warning('off','all')
disp(' ')
addpath('BM4D');
addpath('NoiseEstimationYangTai');
tic


%% DATA LOADING
fileName=('temp.tif');
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
%Noise is estimated on up to 10 slices concatenated to a tiled image to
%provide more data to estimation algorithm

if frames<10
    indexes=1:frames;
else
    indexes=floor(linspace(1,frames,10));
end

estframe=[];

for i=1:length(indexes)
    estframe=horzcat(estframe,z(:,:,i));
end

estframeheight=floor(size(estframe,1)/5);
estframewidth=floor(size(estframe,2)/5);
estframe=estframe(1:estframeheight*5,1:estframewidth*5);
peak=max(estframe(:));
sigma=refinednoiseest(estframe,peak);



%% Apply forward variance stabilizing transformation (Generalized Forward Anscombe)
% Generalized Anscombe VST (J.L. Starck, F. Murtagh, and A. Bijaoui, Image  Processing  and  Data Analysis, Cambridge University Press, Cambridge, 1998)
%F. Murtagh, J.-L. Starck and A. Bijaoui, "Image restoration with noise suppression using a multiresolution support", Astron. Astrophys.
% Supplement Series, vol. 112, pp. 179-189, 1995. https://doi.org/10.1117/12.188035
alpha = 1;
g = 0.0;
scale_range = 1;
scale_shift = (1-scale_range)/2;
fz= 2/alpha * sqrt(max(0,alpha*z + (3/8)*alpha^2 + sigma.^2 - alpha*g));

% Scale the image (BM4D processes inputs in [0,1] range)
maxzans= max(fz(:));
minzans=min(fz(:));
sigma_den=(1/(maxzans-minzans))*scale_range;
fzscaled=(fz-minzans)/(maxzans-minzans);


%% Split stack in chunks and pre-process them
framesperchunk=10; %default 10 frames per chunk, this value should be bigger than the number of overlapping frames between chunks
overlap=5; %number of overlapping frames the default is 5
step=round((frames/framesperchunk)); %number of chunks

if frames>(framesperchunk+overlap*2)

    idx=(1:framesperchunk:frames); %vector containing the frame numbers where chunks are separated
    idx(end)=frames;
    cycles=(numel(idx)-1); %how many parallel chunks will be needed
    %Initialize variables that will contain chunk data
    videoslice=cell(cycles,1);

    for l=1:cycles
        if l==1
            startpoint=1;
            endpoint=idx(l+1)+(overlap*2)-1;
        elseif l==cycles
            startpoint=idx(end)-(overlap*2)-framesperchunk+1;
            endpoint=idx(end);
        else
            startpoint=(idx(l))-overlap;
            endpoint=(idx(l+1))+overlap-1;
        end

        videoslice{l,1}= fzscaled(:,:,startpoint:endpoint);
    end
else
    cycles=1;
    videoslice=cell(1,1);
    videoslice{1,1}= fzscaled;
end

%% Denoise BM4D
%  [1] M. Maggioni, V. Katkovnik, K. Egiazarian, A. Foi, "A Nonlocal
%      Transform-Domain Filter for Volumetric Data Denoising and
%      Reconstruction", IEEE Trans. Image Process., vol. 22, no. 1,
%      pp. 119-133, January 2013.  doi:10.1109/TIP.2012.2210725

parfor g=1 : cycles
    videoslice{g,1}=bm4d(cell2mat(videoslice(g,1)),'Gauss', sigma_den, 'mp');
    %videoslice{g,1}=cell2mat(videoslice(g,1));
end


yhat_cfa=double(zeros(nImage,mImage,frames)); %preallocates the denoised tseries

if frames>(framesperchunk+overlap*2)
    for g=1 : cycles
        if g==1
            tmp=cell2mat(videoslice(g,1));
            tmp=tmp(:,:,1:framesperchunk);
            yhat_cfa(:,:,1:framesperchunk) = tmp;
        elseif g==cycles
            tmp=cell2mat(videoslice(cycles,1));
            diff=idx(end)-idx(end-1);
            tmp=tmp(:,:,end-diff:end);
            yhat_cfa(:,:,end-diff:end) = tmp;
        elseif g>1 & g<cycles
            tmp=cell2mat(videoslice(g,1));
            tmp(:,:,1:overlap)=[];
            tmp=tmp(:,:,1:framesperchunk);
            yhat_cfa(:,:,idx(g):idx(g+1)-1) = tmp;
        end
    end
else
    tmp=cell2mat(videoslice(1,1));
    yhat_cfa=tmp;
end

% Scale back to the initial VST range
yhat_cfa = (yhat_cfa-scale_shift)./scale_range;
yhat_cfa = (yhat_cfa.*(maxzans-minzans))+minzans;

%% Apply the inverse transformation    % closed-form approximation
%Mäkitalo M, Foi A. Optimal inversion of the generalized Anscombe transformation for Poisson-Gaussian noise.
%IEEE Trans Image Process. 2013 Jan;22(1):91-103. doi: 10.1109/TIP.2012.2202675. Epub 2012 Jun 5. PMID: 22692910.

yhat_cfa = (yhat_cfa/2).^2 + 1/4*sqrt(3/2)*yhat_cfa.^-1 - 11/8*yhat_cfa.^-2 + 5/8*sqrt(3/2)*yhat_cfa.^-3 - 1/8 - sigma.^2;
yhat_cfa = max(0,yhat_cfa);


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