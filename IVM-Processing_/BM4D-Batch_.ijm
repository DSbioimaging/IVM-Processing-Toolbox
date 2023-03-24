/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") rawdatafolder
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix

rootfolder=rawdatafolder+File.separator;
fijifolder=getDirectory("imagej");
BM4Dtemp=fijifolder+"IVMDenoising"+File.separator+"BM4D"+File.separator;
File.delete(BM4Dtemp+"temp.tif");
File.delete(BM4Dtemp+"temp_denoised.tif");
matlabversion=getFileList("C:/Program Files/MATLAB");
matlabversion=matlabversion[matlabversion.length-1];

setBatchMode("hide");


close("*");
print("\\Clear");

processFolder(rawdatafolder);

setBatchMode("exit and display");
showMessage("Batch Processing Complete!");

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			folderpath=input + File.separator + list[i];
			folderpath=replace(folderpath, "/", "");
			startpoint=lengthOf(rawdatafolder);
			
			if (lengthOf(folderpath)>startpoint) {
				folderpath=substring(folderpath, startpoint);
				File.makeDirectory(output+folderpath);
				print("Creating new directory in "+output+folderpath);
				folderpathstring=folderpath;
			}	
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {

print("folderpath is "+folderpath);

	savepath=input + File.separator + file;
	savepath=replace(savepath, "/", "");
	savepath=substring(savepath, lengthOf(rootfolder), lengthOf(savepath)-3);
	savepath=output+File.separator+savepath+"tif";
	

	if (!File.exists(savepath)) {
	print("Denoised file will be saved in "+savepath);	
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	//print("Processing: " + input + File.separator + file);
	
	inputfile=input + File.separator + file;
	inputfile=replace(inputfile, "/", "");
	print("Processing: " + inputfile);
	

	run("Bio-Formats Importer", "open=["+inputfile+"] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	metadata=getMetadata("Info");
	getDimensions(width, height, channels, slices, frames);
	getVoxelSize(width, height, depth, unit);
	stackname = getTitle();



if (slices>1 || frames>1) {
	for (j = 1; j <= channels; j++) {
	selectWindow(stackname);
    run("Duplicate...", "title=C" + j + "-temp duplicate channels=" + j);
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


		print("Saving to: " + savepath);
		save(savepath);




		
}
close("*");
}
}