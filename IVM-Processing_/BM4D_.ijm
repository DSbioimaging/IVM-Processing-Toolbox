


fijifolder=getDirectory("imagej");
BM4Dtemp=fijifolder+"IVMDenoising"+File.separator+"BM4D"+File.separator;
File.delete(BM4Dtemp+"temp.tif");
File.delete(BM4Dtemp+"temp_denoised.tif");
matlabversion=getFileList("C:/Program Files/MATLAB");
matlabversion=matlabversion[matlabversion.length-1];

setBatchMode("hide");

	metadata=getMetadata("Info");
	getDimensions(width, height, channels, slices, frames);
	getVoxelSize(width, height, depth, unit);
	stackname = getTitle();



if (slices>1 || frames>1) {
	for (j = 1; j <= channels; j++) {
	selectWindow(stackname);
    run("Duplicate...", "title=C" + j + "-temp-noisy duplicate channels=" + j);
	save(BM4Dtemp+"temp.tif");
	close();
	exec("C:/Program Files/MATLAB/"+matlabversion+"bin/matlab.exe -automation -sd "+BM4Dtemp+" -batch GAT_BM4D_Parallel");
	
	waiting=0;
	do {
      wait(1500);
      //print("Denoising Image in Matlab...");
      if (File.exists(BM4Dtemp+"temp_denoised.tif")) {
      waiting=1;
      }
   } while (waiting<1);
   
   
	print("\\Clear");
	run("Bio-Formats Importer", "open=["+BM4Dtemp+"temp_denoised.tif] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	File.delete(BM4Dtemp+"temp.tif");
	File.delete(BM4Dtemp+"temp_denoised.tif");
	rename("C" + j + "-temp");
	}
	
	
	
	
	
		if (channels==5) {

	run("Merge Channels...", "c1=C1-temp c2=C2-temp c3=C3-temp c4=C4-temp c5=C5-temp create");
			run("Properties...", "slices="+slices+" frames="+frames);
			Stack.setSlice(round(slices/2));
			Stack.setFrame(round(frames/2));

		Stack.setChannel(1);
		run("Red");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
		Stack.setChannel(2);
		run("Yellow");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
		Stack.setChannel(3);
		run("Blue");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
		Stack.setChannel(4);
		run("Green");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
		Stack.setChannel(5);
		run("Cyan");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
	}
	
		if (channels==4) {

	run("Merge Channels...", "c1=C1-temp c2=C2-temp c3=C3-temp c4=C4-temp create");
			run("Properties...", "slices="+slices+" frames="+frames);
			Stack.setSlice(round(slices/2));
			Stack.setFrame(round(frames/2));

		Stack.setChannel(1);
		run("Grays");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
		Stack.setChannel(2);
		run("Red");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
		Stack.setChannel(3);
		run("Green");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
		Stack.setChannel(4);
		run("Blue");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
	}
	
			if (channels==3) {

		run("Merge Channels...", "c1=C1-temp c2=C2-temp c3=C3-temp create");
		run("Properties...", "slices="+slices+" frames="+frames);
		Stack.setSlice(round(slices/2));
		Stack.setFrame(round(frames/2));
			
		Stack.setChannel(1);
		run("Red");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
		Stack.setChannel(2);
		run("Green");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
		Stack.setChannel(3);
		run("Blue");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
	}
	
				if (channels==2) {

		run("Merge Channels...", "c1=C1-temp c2=C2-temp create");
		run("Properties...", "slices="+slices+" frames="+frames);
		Stack.setSlice(round(slices/2));
		Stack.setFrame(round(frames/2));
			
		Stack.setChannel(1);
		run("Red");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
		Stack.setChannel(2);
		run("Green");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
	}
	
		if (channels==1) {
		run("Properties...", "slices="+slices+" frames="+frames);
		Stack.setChannel(1);
		Stack.setSlice(round(slices/2));
		Stack.setFrame(round(frames/2));
		run("Grays");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");

		
	}
	
		setMetadata("Info", metadata);
		setVoxelSize(width, height, depth, unit);
rename("Denoised-"+stackname);


setBatchMode("exit and display");