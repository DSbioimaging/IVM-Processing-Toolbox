
fijifolder=getDirectory("imagej");
IJtemp=fijifolder+"IVMDenoising"+File.separator+"ImageJ"+File.separator;
File.delete(IJtemp+"temp.tif");
File.delete(IJtemp+"temp_denoised.tif");

setBatchMode("hide");

metadata=getMetadata("Info");
	getDimensions(width, height, channels, slices, frames);
	getVoxelSize(width, height, depth, unit);
	stackname = getTitle();




	selectWindow(stackname);

	save(IJtemp+"temp.tif");


	exec(IJtemp+"ImageJ.exe -macro \""+IJtemp+"PureDenoiseIJ.ijm\"");

	waiting=0;
	do {
      wait(1500);
      //print("Denoising Image in Matlab...");
      if (File.exists(IJtemp+"temp-denoised.tif")) {
      waiting=1;
      }
   } while (waiting<1);
   

	run("Bio-Formats Importer", "open=["+IJtemp+"temp-denoised.tif] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	File.delete(IJtemp+"temp.tif");
	File.delete(IJtemp+"temp_denoised.tif");
	
	
		setMetadata("Info", metadata);
		setVoxelSize(width, height, depth, unit);
		run("Properties...", "slices="+slices+" frames="+frames);
	rename("Denoised-"+stackname);
	
	setBatchMode("exit and display");